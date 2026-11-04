extends Node
## End-to-end playthrough bot.
##
## The bot plays through the same input surface as a human: it presses
## up/down/confirm/cancel on whichever screen is on top and holds a movement
## direction in the world.  Every key press has a human-like delay, and dialogue is
## "read" for a time proportional to its length, so the elapsed *game clock* is a fair
## estimate of how long a person would need.  Run it with Godot's --fixed-fps so a
## full hour of game time is simulated in minutes of wall clock:
##
##   godot --headless --fixed-fps 30 --path . -- --bot --report=build/bot_report.json

var main
var world
var cool := 0.5
var wall_start := Time.get_ticks_msec()
var finished := false
var report_path := "build/bot_report.json"
var shots_dir := ""
var min_time := 3600.0
var max_time := 8.0 * 3600.0
var shots_taken := {}
var logged := 0

# navigation
var path: Array = []
var path_key := ""
var last_tile := Vector2i(-1, -1)
var stuck_t := 0.0
var grind_target := ""

# state
var read_done := false
var med_goal := "rest"
var menu_goal := ""
var result_wait := false
var shop_done := {}
var last_area := ""
var last_top := ""
var last_step := -1
var last_progress := 0.0
var dwell := 0.0
var time_by_screen := {}
var time_by_area := {}
var gave_up := ""

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const HEALS := ["mending", "seal_bloom", "dawn", "starlight", "rain"]

func _ready() -> void:
	world = main.world
	if main.args.has("report"):
		report_path = main.args.report
	if main.args.has("shots") and DisplayServer.get_name() != "headless":
		shots_dir = main.args.shots
		DirAccess.make_dir_recursive_absolute(shots_dir)
	if main.args.has("min-time"):
		min_time = float(main.args["min-time"])
	if main.args.has("max-time"):
		max_time = float(main.args["max-time"])

# ---------------------------------------------------------------- main loop
func _process(d: float) -> void:
	if finished:
		return
	var top: String = main.top_name()
	if Game.started:
		time_by_screen[top] = time_by_screen.get(top, 0.0) + d
		time_by_area[Game.area] = time_by_area.get(Game.area, 0.0) + d
		_log_new_events()
		if Game.step != last_step:
			last_step = Game.step
			last_progress = Game.playtime
		if Game.playtime > max_time:
			_finish("timeout: exceeded max game time")
			return
		if Game.playtime - last_progress > 2700.0:
			_finish("stuck: no quest progress for 45 game-minutes at step %d (%s)" % [Game.step, Game.cur_step().get("id", "?")])
			return
	if Game.area != last_area:
		last_area = Game.area
		shop_done = {}
		path = []
		dwell = 0.0
		grind_target = ""
	if top != last_top:
		if last_top == "shop":
			shop_done[main.shop.kind] = true
		last_top = top
		path = []
	if top != "world":
		world.move_dir = Vector2i.ZERO
	cool -= d
	if cool > 0.0:
		return
	_shots(top, d)
	match top:
		"title":
			if shots_dir != "" and not shots_taken.has("01_title"):
				_shot("01_title")
				cool = 0.6
			else:
				_press("confirm", 1.0)
		"dialogue":
			_dialogue()
		"world":
			_world(d)
		"battle":
			_battle()
		"menu":
			_menu()
		"shop":
			_shop()
		"meditate":
			_meditate()
		"ending":
			cool = 2.0
			await _shot("ending")
			_finish("")

func _press(a: String, delay: float = 0.28) -> void:
	main.press(a)
	cool = delay

func _log_new_events() -> void:
	while logged < Game.timeline.size():
		var e: Dictionary = Game.timeline[logged]
		print("[bot] %s  %s" % [Fmt.clock(e.t), e.text])
		logged += 1

# ---------------------------------------------------------------- dialogue
func _dialogue() -> void:
	var dlg = main.dialogue
	if dlg.lines.is_empty():
		_press("confirm", 0.2)
		return
	if not dlg.typed_done():
		cool = 0.15
		return
	if not read_done:
		read_done = true
		cool = maxf(0.7, dlg.line_len() / 40.0)
		return
	read_done = false
	_press("confirm", 0.3)

# ---------------------------------------------------------------- world planning
func _hp_ratio() -> float:
	var r := 2.0
	for i in Game.party_size():
		r = minf(r, Game.hp[i] / float(Game.max_hp(i)))
	return r

func _qi_ratio() -> float:
	var r := 2.0
	for i in Game.party_size():
		r = minf(r, Game.qi[i] / float(Game.max_qi(i)))
	return r

func _cult_target() -> Dictionary:
	var s := Game.cur_step()
	if s.is_empty():
		return {}
	match s.kind:
		"level":
			return {"lv": s.lv, "full": false}
		"kill":
			for b in Data.AREAS[s.area].bosses:
				if b.id == s.boss:
					return {"lv": b.req, "full": false}
		"breakthrough":
			return {"lv": s.to - 1, "full": true}
	return {}

func _cult_met() -> bool:
	var tg := _cult_target()
	if tg.is_empty():
		return true
	if Game.level > tg.lv:
		return true
	if Game.level == tg.lv:
		return (not tg.full) or Game.exp >= Game.exp_need() - 0.5
	return false

func _want_shop() -> String:
	if Game.area != "sect":
		return ""
	var price := Data.pill_price("hp_pill", Game.level)
	if not shop_done.get("smith", false) and Game.temper < Data.TEMPER_COST.size() and Game.stones >= Data.TEMPER_COST[Game.temper] + price * 2:
		return "smith"
	if not shop_done.get("alchemist", false) and Game.stones >= price * 2 and (Game.inv.get("hp_pill", 0) < 8 or Game.inv.get("qi_pill", 0) < 3):
		return "alchemist"
	return ""

func _world(d: float) -> void:
	dwell += d
	# stuck watchdog
	if world.ptile == last_tile and world.move_dir != Vector2i.ZERO:
		stuck_t += d
		if stuck_t > 6.0:
			path = []
			stuck_t = 0.0
			grind_target = ""
	else:
		stuck_t = 0.0
	last_tile = world.ptile
	var s := Game.cur_step()
	if s.is_empty():
		return
	# 1) rest when hurt or out of qi
	if _hp_ratio() < 0.5 or _qi_ratio() < 0.15:
		_start_meditate("rest")
		return
	# 2) shopping while in the sect
	var shop := _want_shop()
	if shop != "":
		_goto_entity("sect", shop)
		return
	# 3) quest objective
	match s.kind:
		"talk":
			_goto_entity(s.area, s.npc)
		"level":
			if not _cult_met():
				_grind()
		"collect":
			if Game.area != s.area:
				_travel(s.area)
			else:
				_goto_nearest("pickup", s.item)
		"hunt":
			if Game.area != s.area:
				_travel(s.area)
			elif _hp_ratio() < 0.6:
				_start_meditate("rest")
			else:
				var e = _nearest_enemy()
				if e != null:
					_walk_to(e.pos, "enemy:" + e.id)
				else:
					_start_meditate("respawn")
		"kill":
			if not _cult_met():
				_grind()
			elif _hp_ratio() < 0.85 or _qi_ratio() < 0.6:
				_start_meditate("rest")
			else:
				_goto_entity(s.area, "boss_" + s.boss)
		"breakthrough":
			if not _cult_met():
				_grind()
			elif _hp_ratio() < 0.9 or _qi_ratio() < 0.8:
				_start_meditate("rest")
			else:
				menu_goal = "breakthrough"
				_press("cancel", 0.4)

func _start_meditate(goal: String) -> void:
	med_goal = goal
	menu_goal = "meditate"
	world.move_dir = Vector2i.ZERO
	_press("cancel", 0.4)

func _grind() -> void:
	# fight a nearby enemy if one is safe, otherwise meditate
	if Game.area != "sect" and _hp_ratio() > 0.55:
		var e = _nearest_enemy()
		if e != null:
			_walk_to(e.pos, "enemy:" + e.id)
			return
	_start_meditate("grind")

func _nearest_enemy():
	var dist := _bfs_dist(world.ptile, false)
	var best = null
	var bd := 9999
	for e in world.ents:
		if e.kind != "enemy" or not world.ent_visible(e):
			continue
		var mx := 0
		for g in e.group:
			mx = maxi(mx, g.lv)
		if mx > Game.level + 2:
			continue
		for dd in DIRS:
			var n: Vector2i = e.pos + dd
			if dist.has(n) and dist[n] < bd:
				bd = dist[n]
				best = e
	if bd > 60:
		return null
	return best

func _goto_nearest(kind: String, item: String) -> void:
	var dist := _bfs_dist(world.ptile, true)
	var best = null
	var bd := 9999
	for e in world.ents:
		if e.kind == kind and e.get("item", "") == item and world.ent_visible(e):
			for dd in DIRS:
				var n: Vector2i = e.pos + dd
				if dist.has(n) and dist[n] < bd:
					bd = dist[n]
					best = e
	if best != null:
		_walk_to(best.pos, "pickup:" + best.id)

func _goto_entity(area: String, id: String) -> void:
	if Game.area != area:
		_travel(area)
		return
	var e = world.find_ent(id)
	if e == null:
		return
	_walk_to(e.pos, "ent:" + id)

func _travel(dest: String) -> void:
	var nxt: String = Data.next_hop(Game.area, dest)
	var p = world.find_ent("p_" + nxt)
	if p != null:
		_walk_to(p.pos, "portal:" + nxt)

# ---------------------------------------------------------------- pathing
func _blocked_set(avoid_enemies: bool, goal: Vector2i) -> Dictionary:
	var b := {}
	for e in world.ents:
		if e.kind == "spring" or not world.ent_visible(e):
			continue
		if e.pos == goal:
			continue
		# stepping on any other gate teleports: route around it (the south-east road in the
		# sect passes right by the east gate)
		if e.kind == "enemy" and not avoid_enemies:
			continue
		b[e.pos] = true
	return b

func _bfs_dist(start: Vector2i, avoid_enemies: bool) -> Dictionary:
	var blocked := _blocked_set(true, Vector2i(-9, -9)) if avoid_enemies or true else {}
	var dist := {start: 0}
	var q: Array = [start]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		for dd in DIRS:
			var n: Vector2i = c + dd
			if dist.has(n) or not world.tile_free(n) or blocked.has(n):
				continue
			dist[n] = dist[c] + 1
			q.append(n)
	return dist

func _bfs_path(start: Vector2i, goal: Vector2i, avoid_enemies: bool) -> Array:
	var blocked := _blocked_set(avoid_enemies, goal)
	var prev := {start: start}
	var q: Array = [start]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		if c == goal:
			break
		for dd in DIRS:
			var n: Vector2i = c + dd
			if prev.has(n):
				continue
			if n != goal and (not world.tile_free(n) or blocked.has(n)):
				continue
			if n == goal and world.ent_at(n) == null and not world.tile_free(n):
				continue
			prev[n] = c
			q.append(n)
	if not prev.has(goal):
		return []
	var out: Array = [goal]
	var cur: Vector2i = goal
	while cur != start:
		cur = prev[cur]
		out.push_front(cur)
	return out

func _walk_to(goal: Vector2i, key: String) -> void:
	var here: Vector2i = world.target if world.move_t >= 0.0 else world.ptile
	if key != path_key or path.is_empty() or not path.has(here):
		path = _bfs_path(here, goal, true)
		if path.is_empty():
			path = _bfs_path(here, goal, false)
		path_key = key
		if path.is_empty():
			world.move_dir = Vector2i.ZERO
			return
	var i := path.find(here)
	if i < 0 or i >= path.size() - 1:
		world.move_dir = Vector2i.ZERO
		path = []
		return
	world.move_dir = path[i + 1] - here
	cool = 0.0

# ---------------------------------------------------------------- menus
func _nav(labels_n: int, cursor: int, want: int) -> void:
	if want < 0:
		_press("cancel", 0.3)
		return
	if cursor == want:
		_press("confirm", 0.35)
	else:
		var fwd := (want - cursor + labels_n) % labels_n
		_press("down" if fwd <= labels_n / 2 else "up", 0.22)

func _menu() -> void:
	var m = main.menu
	if menu_goal == "":
		_press("cancel", 0.3)
		return
	if m.mode != "root":
		_press("cancel", 0.3)
		return
	var want: int = m.ids.find(menu_goal)
	if want < 0 or not m.enabled[want]:
		menu_goal = ""
		_press("cancel", 0.3)
		return
	if m.cursor == want:
		menu_goal = ""
	_nav(m.labels.size(), m.cursor, want)

func _shop() -> void:
	var s = main.shop
	var want := "leave"
	if s.kind == "smith":
		if s.ids.has("temper") and s.enabled[s.ids.find("temper")]:
			want = "temper"
	else:
		var hp_price := Data.pill_price("hp_pill", Game.level)
		var qi_price := Data.pill_price("qi_pill", Game.level)
		if Game.inv.get("hp_pill", 0) < 8 and Game.stones >= hp_price:
			want = "hp_pill"
		elif Game.inv.get("qi_pill", 0) < 4 and Game.stones >= qi_price:
			want = "qi_pill"
	_nav(s.labels.size(), s.cursor, s.ids.find(want))

func _meditate() -> void:
	var done := false
	match med_goal:
		"rest":
			done = _hp_ratio() > 0.97 and _qi_ratio() > 0.9
		"grind":
			done = _cult_met() and _hp_ratio() > 0.6
		"respawn":
			done = _nearest_enemy() != null
	if done:
		_press("cancel", 0.4)
	else:
		cool = 0.4

# ---------------------------------------------------------------- battle
func _battle() -> void:
	var b = main.battle
	match b.state:
		"intro", "acting":
			cool = 0.2
		"result":
			if not result_wait:
				result_wait = true
				cool = 1.6
			else:
				result_wait = false
				_press("confirm", 0.5)
		"menu":
			_battle_menu(b)

func _battle_menu(b) -> void:
	var plan := _plan(b)
	var want := -1
	match b.menu_kind:
		"main":
			want = b.ids.find(plan.top)
		"skills":
			want = b.ids.find(plan.get("skill", ""))
		"items":
			want = b.ids.find(plan.get("item", ""))
		"target":
			for i in b.targets.size():
				if is_same(b.targets[i], plan.target):
					want = i
	if want < 0 or (b.menu_kind != "target" and not b.enabled[want]):
		_press("cancel", 0.3)
		return
	_nav(b.labels.size(), b.cursor, want)

func _plan(b) -> Dictionary:
	var me: Dictionary = b.cur
	var allies: Array = b.alive(b.party)
	var foes: Array = b.alive(b.foes)
	var low: Dictionary = allies[0]
	for a in allies:
		if a.hp / a.maxhp < low.hp / low.maxhp:
			low = a
	var low_r: float = low.hp / low.maxhp
	# healing
	# strongest heal Yue Ling knows (Seal Bloom and Nuwa's Mending used to be skipped)
	var heal_id := "rain"
	for hid in HEALS:
		if me.skills.has(hid):
			heal_id = hid
			break
	var heal_cost: float = Data.SKILLS[heal_id].cost
	if me.skills.has(heal_id) and me.qi >= heal_cost and low_r < 0.55:
		return {"top": "skills", "skill": heal_id}
	if low_r < 0.3 and Game.inv.get("hp_pill", 0) > 0 and not (me.skills.has(heal_id) and me.qi >= heal_cost):
		return {"top": "items", "item": "hp_pill", "target": low}
	if me.idx == 0 and me.qi < 12 and Game.inv.get("qi_pill", 0) > 0 and b.ctx.get("boss", false):
		return {"top": "items", "item": "qi_pill", "target": me}
	# offense
	var best_score := 0.0
	var best: Dictionary = {"top": "attack", "target": _weakest(foes, "phys")}
	if me.idx == 1:
		best = {"top": "attack", "target": _weakest(foes, "wood")}
	best_score = 1.0
	for sid in me.skills:
		var sk: Dictionary = Data.SKILLS[sid]
		if sk.has("heal") or me.qi < sk.cost or sk.cost == 0:
			continue
		var tgt: Dictionary = _weakest(foes, sk.elem)
		var score: float = sk.mult * (1.5 if tgt.weak == sk.elem else 1.0)
		if sk.tgt == "all":
			var tot := 0.0
			for f in foes:
				tot += sk.mult * (1.5 if f.weak == sk.elem else 1.0)
			score = tot
		# don't burn the biggest techniques on trash when few enemies remain
		if not b.ctx.get("boss", false) and foes.size() == 1 and tgt.hp < me.atk * 1.2:
			continue
		if score > best_score:
			best_score = score
			best = {"top": "skills", "skill": sid, "target": tgt}
	return best

func _weakest(foes: Array, elem: String) -> Dictionary:
	var best: Dictionary = foes[0]
	for f in foes:
		var fw: bool = f.weak == elem
		var bw: bool = best.weak == elem
		if fw and not bw:
			best = f
		elif fw == bw and f.hp < best.hp:
			best = f
	return best

# ---------------------------------------------------------------- screenshots
func _shots(top: String, d: float) -> void:
	if shots_dir == "":
		return
	match top:
		"title":
			_shot("01_title")
		"dialogue":
			if Game.step == 0 and main.dialogue.idx == 1 and main.dialogue.typed_done():
				_shot("02_dialogue")
		"world":
			if dwell > 2.5 and Game.step > 0:
				_shot("world_" + Game.area)
		"meditate":
			if med_goal != "" and main.meditate.t > 4.0:
				_shot("meditate")
		"menu":
			if Game.level >= 2:
				_shot("menu")
		"shop":
			_shot("shop")
		"battle":
			var b = main.battle
			if b.state == "menu" and b.menu_kind == "main":
				if b.ctx.get("tribulation", false):
					_shot("battle_tribulation")
				elif b.ctx.get("boss", false):
					_shot("battle_boss_" + b.ctx.enemy)
				elif b.foes.size() >= 2:
					_shot("battle_" + Game.area)

func _shot(n: String) -> void:
	if shots_dir == "" or shots_taken.has(n):
		return
	shots_taken[n] = true
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [shots_dir, n])

# ---------------------------------------------------------------- report
func _finish(reason: String) -> void:
	if finished:
		return
	finished = true
	var wall := (Time.get_ticks_msec() - wall_start) / 1000.0
	var ok := Game.finished and Game.playtime >= min_time and reason == ""
	var breakdown := {}
	for k in time_by_screen:
		breakdown[k] = snappedf(time_by_screen[k], 0.1)
	var areas := {}
	for k in time_by_area:
		areas[k] = snappedf(time_by_area[k], 0.1)
	var rep := {
		"completed": Game.finished,
		"passed": ok,
		"failure_reason": reason,
		"game_time_seconds": snappedf(Game.playtime, 0.1),
		"game_time": Fmt.clock(Game.playtime),
		"wall_clock_seconds": snappedf(wall, 0.1),
		"final_realm": Data.level_name(Game.level),
		"battles": Game.battles,
		"foes_defeated": Game.kills,
		"deaths": Game.deaths,
		"spirit_stones": Game.stones,
		"sword_tempering": Game.temper,
		"time_by_screen_seconds": breakdown,
		"time_by_area_seconds": areas,
		"timeline": Game.timeline,
	}
	var dir := report_path.get_base_dir()
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir if dir.is_absolute_path() else ProjectSettings.globalize_path("res://" + dir))
	var path_abs := report_path if report_path.is_absolute_path() else ProjectSettings.globalize_path("res://" + report_path)
	var f := FileAccess.open(path_abs, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(rep, "  "))
		f.close()
	print("")
	print("================ BOT REPORT ================")
	print("completed       : %s" % Game.finished)
	print("game play time  : %s (%.0f s)" % [Fmt.clock(Game.playtime), Game.playtime])
	print("wall clock      : %.1f s" % wall)
	print("final realm     : %s" % Data.level_name(Game.level))
	print("battles / kills : %d / %d   deaths: %d" % [Game.battles, Game.kills, Game.deaths])
	print("time by screen  : %s" % JSON.stringify(breakdown))
	print("time by area    : %s" % JSON.stringify(areas))
	if reason != "":
		print("FAILED          : %s" % reason)
	print("result          : %s (needs >= %.0f s)" % ["PASS" if ok else "FAIL", min_time])
	print("============================================")
	get_tree().quit(0 if ok else 1)
