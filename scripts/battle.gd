extends Node2D
## Turn-based combat.  Elemental weaknesses, qi costs, party support, boss heavy attacks.

const VIEW := Vector2(1280, 720)
const SKY := {
	"sect": [Color("1c2a5a"), Color("7a6aa8")], "bamboo": [Color("14301e"), Color("6ab07a")],
	"marsh": [Color("1e1226"), Color("7a4a5a")], "frost": [Color("12203a"), Color("a8d0f0")],
	"thunder": [Color("0e0e1e"), Color("5a5a8a")], "palace": [Color("1a0408"), Color("8a2030")],
}

var main
var opaque := true
var party: Array = []
var foes: Array = []
var ctx: Dictionary = {}
var state := "intro"
var timer := 0.0
var order: Array = []
var cur: Dictionary = {}
var round_no := 0
var menu_kind := "main"
var labels: Array = []
var ids: Array = []
var enabled: Array = []
var cursor := 0
var pending := {"skill": "", "item": ""}
var targets: Array = []
var log_lines: Array = []
var fx: Array = []
var outcome := ""
var result_lines: Array = []
var t := 0.0
var theme := "bamboo"
var level_before := 0

func setup(m) -> void:
	main = m

func start(foe_list: Array, c: Dictionary) -> void:
	ctx = c
	theme = c.get("theme", "bamboo")
	party.clear()
	foes.clear()
	for i in Game.party_size():
		party.append(Game.fighter(i))
	for f in foe_list:
		foes.append(Data.make_enemy(f.id, f.lv, f.get("mult", 1.0)))
	state = "intro"
	timer = 1.4
	order.clear()
	round_no = 0
	outcome = ""
	fx.clear()
	log_lines.clear()
	level_before = Game.level
	Game.battles += 1
	if ctx.get("boss", false):
		say("%s blocks your path!" % foes[0].name)
	else:
		say("Enemies appear!  %s" % ", ".join(foes.map(func(f): return f.name)))

func say(s: String) -> void:
	log_lines.append(s)
	if log_lines.size() > 4:
		log_lines.pop_front()

func alive(arr: Array) -> Array:
	return arr.filter(func(f): return not f.dead)

# ---------------------------------------------------------------- flow
func _process(d: float) -> void:
	t += d
	for f in party + foes:
		f.flash = maxf(0.0, f.flash - d)
		f.shake = maxf(0.0, f.shake - d)
		if f.dead:
			f.fade = maxf(0.0, f.fade - d * 2.0)
	for p in fx:
		p.t -= d
	fx = fx.filter(func(p): return p.t > 0.0)
	if main.top_name() != "battle":
		queue_redraw()
		return
	match state:
		"intro", "acting":
			timer -= d
			if timer <= 0.0:
				_next_turn()
	queue_redraw()

func _next_turn() -> void:
	while true:
		if alive(foes).is_empty():
			_win()
			return
		if alive(party).is_empty():
			_lose()
			return
		if order.is_empty():
			round_no += 1
			var all := alive(party) + alive(foes)
			all.shuffle()
			all.sort_custom(func(a, b): return a.spd > b.spd)
			order = all
		cur = order.pop_front()
		if not cur.dead:
			break
	cur.turns += 1
	if cur.side == "party":
		cur.qi = minf(cur.maxqi, cur.qi + cur.maxqi * 0.04)
		_open_main()
		state = "menu"
	else:
		_foe_act(cur)
		state = "acting"

func _foe_act(f: Dictionary) -> void:
	var tg: Array = alive(party)
	if f.boss and f.turns % 3 == 0:
		say("%s unleashes a devastating attack!" % f.name)
		for p in tg:
			_hit(f, p, 1.45, f.elem, true)
		timer = 1.3
		return
	var victim: Dictionary = tg[randi() % tg.size()]
	if randf() < 0.4:
		for p in tg:
			if p.hp / p.maxhp < victim.hp / victim.maxhp:
				victim = p
	say("%s attacks %s." % [f.name, victim.name])
	_hit(f, victim, 1.0, f.elem, false)
	timer = 0.85

func _hit(a: Dictionary, tgt: Dictionary, mult: float, elem: String, quiet: bool) -> void:
	var em := 1.5 if tgt.weak == elem and elem != "phys" else 1.0
	var raw: float = a.atk * mult * randf_range(0.9, 1.1) * em - tgt.def * 0.5
	var crit := randf() < 0.08
	if crit:
		raw *= 1.5
	var dmg := maxi(1, int(round(raw)))
	tgt.hp = maxf(0.0, tgt.hp - dmg)
	tgt.flash = 0.35
	tgt.shake = 0.3
	var col: Color = Data.ELEM_COLORS.get(elem, Color.WHITE)
	var txt := str(dmg) + ("!" if crit else "") + (" weak" if em > 1.0 else "")
	fx.append({"text": txt, "p": _pos(tgt) + Vector2(randf_range(-10, 10), -50), "t": 1.0, "col": col if tgt.side == "foe" else UI.C_RED.lightened(0.3), "slash": elem})
	if tgt.hp <= 0.0:
		tgt.dead = true
		if not quiet or true:
			say("%s is defeated." % tgt.name if tgt.side == "foe" else "%s collapses!" % tgt.name)
		if tgt.side == "foe":
			Game.kills += 1

func _heal(tgt: Dictionary, amount: float) -> void:
	tgt.hp = minf(tgt.maxhp, tgt.hp + amount)
	fx.append({"text": "+%d" % int(amount), "p": _pos(tgt) + Vector2(0, -50), "t": 1.0, "col": UI.C_JADE, "slash": ""})

func _perform(actor: Dictionary, skill_id: String, tgts: Array) -> void:
	var s: Dictionary = Data.SKILLS[skill_id]
	actor.qi -= s.cost
	if s.has("heal"):
		say("%s casts %s." % [actor.name, s.n])
		for tg in tgts:
			_heal(tg, tg.maxhp * s.heal)
	else:
		say("%s uses %s." % [actor.name, s.n])
		for tg in tgts:
			_hit(actor, tg, s.mult, s.elem, false)
	_end_action()

func _use_item(actor: Dictionary, item: String, tgt: Dictionary) -> void:
	Game.inv[item] -= 1
	if item == "hp_pill":
		say("%s feeds %s a healing pill." % [actor.name, tgt.name])
		_heal(tgt, tgt.maxhp * 0.4)
	else:
		say("%s restores %s's qi." % [actor.name, tgt.name])
		tgt.qi = minf(tgt.maxqi, tgt.qi + tgt.maxqi * 0.5)
		fx.append({"text": "+qi", "p": _pos(tgt) + Vector2(0, -50), "t": 1.0, "col": UI.C_BLUE, "slash": ""})
	_end_action()

func _end_action() -> void:
	state = "acting"
	timer = 0.95
	labels.clear()

func _win() -> void:
	outcome = "win"
	state = "result"
	var xp := 0
	var stones := 0
	var boss: bool = ctx.get("boss", false)
	for f in foes:
		xp += Data.enemy_exp(f.lv, f.boss)
		stones += Data.enemy_stones(f.lv, f.boss)
	_writeback()
	result_lines = ["VICTORY", "+%d cultivation   +%d spirit stones" % [xp, stones]]
	if ctx.get("tribulation", false):
		xp = 0
		stones = 0
		result_lines = ["The tribulation is endured!"]
	Game.stones += stones
	if boss and not ctx.get("tribulation", false):
		Game.add_item("hp_pill", 2)
		Game.add_item("qi_pill", 1)
		result_lines.append("Found: 2 Healing Pills, 1 Spirit Qi Pill")
	elif randf() < 0.25:
		Game.add_item("hp_pill", 1)
		result_lines.append("Found: Healing Pill")
	Game.add_exp(xp)
	if Game.level > level_before:
		result_lines.append("Cultivation advanced: %s" % Data.level_name(Game.level))

func _lose() -> void:
	outcome = "lose"
	state = "result"
	result_lines = ["DEFEAT", "Your vision fades... You will be carried back to the sect."]

func _writeback() -> void:
	for p in party:
		Game.hp[p.idx] = maxf(1.0, p.hp)
		Game.qi[p.idx] = p.qi

func finish() -> void:
	if outcome == "win":
		pass
	elif outcome == "fled":
		_writeback()
	main.battle_done(outcome, ctx)

# ---------------------------------------------------------------- menus
func _open_main() -> void:
	menu_kind = "main"
	labels = ["Attack", "Skills", "Items", "Flee"]
	ids = ["attack", "skills", "items", "flee"]
	enabled = [true, true, true, not ctx.get("boss", false)]
	cursor = 0

func _open_skills() -> void:
	menu_kind = "skills"
	labels = []
	ids = []
	enabled = []
	for sid in cur.skills:
		var s: Dictionary = Data.SKILLS[sid]
		if sid == "strike" or sid == "needle":
			continue
		labels.append("%s  [%d qi]" % [s.n, s.cost])
		ids.append(sid)
		enabled.append(cur.qi >= s.cost)
	if ids.is_empty():
		labels.append("(no techniques)")
		ids.append("")
		enabled.append(false)
	cursor = 0

func _open_items() -> void:
	menu_kind = "items"
	labels = []
	ids = []
	enabled = []
	for iid in ["hp_pill", "qi_pill"]:
		var n: int = Game.inv.get(iid, 0)
		labels.append("%s x%d" % [Data.ITEMS[iid].n, n])
		ids.append(iid)
		enabled.append(n > 0)
	cursor = 0

func _open_targets(side: Array) -> void:
	menu_kind = "target"
	targets = alive(side)
	labels = []
	ids = []
	enabled = []
	for i in targets.size():
		var f: Dictionary = targets[i]
		labels.append("%s  %d/%d" % [f.name, f.hp, f.maxhp])
		ids.append(i)
		enabled.append(true)
	cursor = 0

func press(act: String) -> void:
	if state == "result":
		if act == "confirm":
			finish()
		return
	if state != "menu":
		return
	match act:
		"up":
			cursor = (cursor - 1 + labels.size()) % labels.size()
		"down":
			cursor = (cursor + 1) % labels.size()
		"cancel":
			if menu_kind == "target":
				if pending.skill != "" and pending.skill != "strike":
					_open_skills()
				elif pending.item != "":
					_open_items()
				else:
					_open_main()
			elif menu_kind != "main":
				_open_main()
		"confirm":
			if not enabled[cursor]:
				return
			_select()

func _select() -> void:
	match menu_kind:
		"main":
			match ids[cursor]:
				"attack":
					pending = {"skill": "strike" if cur.idx == 0 else "needle", "item": ""}
					_open_targets(foes)
				"skills":
					_open_skills()
				"items":
					_open_items()
				"flee":
					say("%s tries to flee..." % cur.name)
					if randf() < 0.6:
						outcome = "fled"
						say("Got away safely!")
						state = "result"
						result_lines = ["Escaped!"]
					else:
						say("Couldn't escape!")
						_end_action()
		"skills":
			var sid: String = ids[cursor]
			var s: Dictionary = Data.SKILLS[sid]
			pending = {"skill": sid, "item": ""}
			match s.tgt:
				"one":
					_open_targets(foes)
				"all":
					_perform(cur, sid, alive(foes))
				"allies":
					_perform(cur, sid, alive(party))
				"ally":
					_open_targets(party)
		"items":
			pending = {"skill": "", "item": ids[cursor]}
			_open_targets(party)
		"target":
			var tg: Dictionary = targets[ids[cursor]]
			if pending.item != "":
				_use_item(cur, pending.item, tg)
			else:
				_perform(cur, pending.skill, [tg])

# ---------------------------------------------------------------- drawing
func _pos(f: Dictionary) -> Vector2:
	if f.side == "party":
		return Vector2(250 + f.idx * 130, 400 + f.idx * 75)
	var i := foes.find(f)
	if f.boss:
		return Vector2(900, 380)
	var n := foes.size()
	if n == 1:
		return Vector2(900, 400)
	return Vector2(820 + (i % 2) * 150, 300 + i * 85)

func _draw() -> void:
	var sky: Array = SKY.get(theme, SKY.bamboo)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(VIEW.x, 0), Vector2(VIEW.x, 480), Vector2(0, 480)]), PackedColorArray([sky[0], sky[0], sky[1], sky[1]]))
	# parallax mountains
	for layer in 3:
		var col: Color = sky[1].darkened(0.25 + layer * 0.18)
		var pts := PackedVector2Array([Vector2(0, 480)])
		for i in 17:
			var x := i * 85.0
			pts.append(Vector2(x, 330 + layer * 40 - absf(sin(i * 1.3 + layer * 2.0)) * (90 - layer * 20)))
		pts.append(Vector2(VIEW.x, 480))
		draw_colored_polygon(pts, col)
	draw_rect(Rect2(0, 470, VIEW.x, 250), sky[0].darkened(0.5))
	draw_rect(Rect2(0, 470, VIEW.x, 6), Color(1, 1, 1, 0.12))
	for i in 18:
		var qx := fposmod(i * 83.0 + t * 12.0, VIEW.x)
		var qy := 420.0 - fposmod(i * 37.0 + t * 20.0, 330.0)
		draw_circle(Vector2(qx, qy), 2.0, Color(1, 1, 0.8, 0.3))
	# fighters
	for f in foes:
		_draw_fighter(f)
	for f in party:
		_draw_fighter(f)
	# target arrow
	if state == "menu" and menu_kind == "target" and not targets.is_empty():
		var tg: Dictionary = targets[ids[cursor]]
		var p := _pos(tg) + Vector2(0, -90 if not tg.boss else -150)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(-12, -18), p + Vector2(12, -18)]), UI.C_GOLD)
	if state == "menu" or state == "acting":
		if not cur.is_empty() and cur.side == "party" and not cur.dead and state == "menu":
			var cp := _pos(cur)
			draw_arc(cp + Vector2(0, 30), 46, 0, TAU, 28, UI.C_GOLD, 2.0)
	for p in fx:
		var a := clampf(p.t, 0.0, 1.0)
		var pp: Vector2 = p.p + Vector2(0, -(1.0 - p.t) * 40.0)
		if p.slash != "":
			var sc: Color = Data.ELEM_COLORS.get(p.slash, Color.WHITE)
			draw_line(pp + Vector2(-34, 40) * (1.0 - a * 0.2), pp + Vector2(34, 80), Color(sc.r, sc.g, sc.b, a), 5.0)
		UI.text(self, pp, p.text, 30, Color(p.col.r, p.col.g, p.col.b, a), HORIZONTAL_ALIGNMENT_CENTER, 140)
		pass
	_draw_ui()

func _draw_fighter(f: Dictionary) -> void:
	if f.fade <= 0.01:
		return
	var p := _pos(f)
	if f.shake > 0.0:
		p += Vector2(sin(t * 80.0) * 6.0, 0)
	var s := 1.5 if not f.boss else 2.6
	if f.side == "party":
		s = 1.55
	var col: Color = f.col
	if f.flash > 0.0:
		col = col.lerp(Color.WHITE, 0.7)
	UI.monster(self, f.shape, p, s * f.fade, col, t, f.boss and not f.dead)
	if not f.dead:
		var bw := 100.0 if not f.boss else 180.0
		var by: float = p.y + (62.0 if not f.boss else 86.0)
		UI.bar(self, Rect2(p.x - bw / 2, by, bw, 8), f.hp / f.maxhp, UI.C_RED if f.side == "foe" else UI.C_JADE)
		UI.text(self, Vector2(p.x - 90, by + 24), f.name, 14, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 180)

func _draw_ui() -> void:
	# log
	UI.panel(self, Rect2(300, 556, 470, 150))
	var y := 584.0
	for l in log_lines:
		UI.text(self, Vector2(316, y), l, 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 440)
		y += 26
	# party status
	UI.panel(self, Rect2(786, 556, 480, 150))
	for p in party:
		var i: int = p.idx
		var yy := 580.0 + i * 62.0
		UI.text(self, Vector2(802, yy + 14), p.name, 18, UI.C_GOLD if p == cur else UI.C_TEXT)
		UI.text(self, Vector2(802, yy + 36), "HP %d/%d" % [p.hp, p.maxhp], 13)
		UI.bar(self, Rect2(900, yy + 4, 340, 12), p.hp / p.maxhp, UI.C_RED)
		UI.text(self, Vector2(802, yy + 54), "QI %d/%d" % [p.qi, p.maxqi], 13)
		UI.bar(self, Rect2(900, yy + 42, 340, 10), p.qi / p.maxqi, UI.C_BLUE)
	# command menu
	if state == "menu":
		UI.menu_list(self, Rect2(16, 556, 270, 150), labels, cursor, enabled, 20 if labels.size() < 5 else 16)
		UI.text(self, Vector2(20, 548), "%s's turn" % cur.name, 15, UI.C_GOLD)
	elif state == "result":
		UI.panel(self, Rect2(320, 150, 640, 230))
		var yy2 := 205.0
		for i in result_lines.size():
			UI.text(self, Vector2(320, yy2), result_lines[i], 32 if i == 0 else 20, UI.C_GOLD if i == 0 else UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 640)
			yy2 += 50 if i == 0 else 34
		UI.text(self, Vector2(320, 360), "Press Enter", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 640)
