extends ScreenBase
## Turn-based combat on a 3D stage with an over-the-shoulder camera.
## Elemental weaknesses, qi costs, party support, boss heavy attacks.

const VIEW := Vector2(1280, 720)

var party: Array = []
var foes: Array = []
var ctx: Dictionary = {}
## the Living Land release (havoc.gd): this battle's scorch marks and thrown-up floor
var scar_root: Node3D = null
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
var theme := "bamboo"
var level_before := 0
## Part XII: once-a-battle powers of the woken root (the Sword Bone's first blow, the Vajra Body's
## last breath) and the realm suppression the battle opened with
var first_blow := true
var vajra_used := false
var tide_used := false
var suppress_note := ""
## Many roads (trials.gd): what the path taken through a trial does in this battle (its boon), and
## whether the trial's boss has been brought low enough to be enraged
var boon := {}
var enraged := false
## Fates and Faces (lore.gd): the story of a species met for the first time, on a card over the
## battle's opening ({"n", "text"}, or empty)
var lore_card := {}
const LORE_INTRO := 4.6

# 3D stage
var stages := {}
var stage: Node3D = null
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var cam_shake := 0.0
var storm_t := 0.0
var ring_cur: MeshInstance3D
var arrow_tgt: MeshInstance3D
var flash_mat: StandardMaterial3D
const INTRO_BOSS := 2.2
var cam_base := Vector3(-13.0, 5.4, 5.0)
var cam_look := Vector3(2.5, 0.6, 0.0)

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(55.0)
	sun = Look.sun("bamboo")
	scene3d.add_child(sun)
	fill = Look.fill("bamboo")
	scene3d.add_child(fill)
	var rb := MB.new()
	rb.torus(Vector3.ZERO, 0.9, 0.04, Color(1.0, 0.85, 0.35, 0.95))
	rb.torus(Vector3.ZERO, 0.7, 0.03, Color(1.0, 0.95, 0.7, 0.6))
	ring_cur = MB.mesh_node(scene3d, rb.build(MB.mat_glow()))
	ring_cur.visible = false
	var ab := MB.new()
	ab.cone(Vector3.ZERO, 0.3, 0.7, Color(1.0, 0.85, 0.3, 0.95), Vector3(PI, 0, 0), 4)
	arrow_tgt = MB.mesh_node(scene3d, ab.build(MB.mat_glow()))
	arrow_tgt.visible = false
	flash_mat = StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = Color(1, 1, 1, 0.65)
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _on_show(v: bool) -> void:
	if not v:
		return

func _stage_for(th: String) -> Dictionary:
	if stages.has(th):
		return stages[th]
	var n := Node3D.new()
	var look := Look.theme(th)
	# arena floor: textured ground with a cobbled ring path, all drawn by the terrain shader
	var gb := MB.new()
	var g1: Color = Color(look.g1).darkened(0.05)
	var g2: Color = Color(look.g2)
	var pc: Color = Color(look.path)
	var coords: Array = [-150.0, -100.0, -64.0, -44.0, -32.0, -25.0]
	for k in 41:
		coords.append(-20.0 + k)
	coords.append_array([25.0, 32.0, 44.0, 64.0, 100.0, 150.0])
	var cols := {}
	for zi in coords.size():
		for xi in coords.size():
			var r: float = Vector2(coords[xi], coords[zi]).length()
			var c: Color
			if r < 13.4:
				c = Color(g2.r, g2.g, g2.b, 1.0)
			elif r < 16.0:
				c = Color(pc.r, pc.g, pc.b, 0.0)
			else:
				c = Color(g1.r, g1.g, g1.b, 1.0)
			cols[Vector2i(xi, zi)] = c
	for zi in coords.size() - 1:
		for xi in coords.size() - 1:
			var x0: float = coords[xi]
			var x1: float = coords[xi + 1]
			var z0: float = coords[zi]
			var z1: float = coords[zi + 1]
			gb.quad_n([Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1)], [Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP],
				[cols[Vector2i(xi, zi)], cols[Vector2i(xi + 1, zi)], cols[Vector2i(xi + 1, zi + 1)], cols[Vector2i(xi, zi + 1)]])
	var gi := MB.mesh_node(n, gb.build(Terrain3D.ground_mat(th)))
	gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a ring of standing stones with braziers around the arena
	var sb := MB.new()
	var stone := MB.tag(Color(look.wall).lerp(Color(0.6, 0.6, 0.65), 0.55), MB.STONE)
	var sg := MB.new()
	for i in 10:
		var a := TAU * (i + 0.5) / 10.0
		var p := Vector3(cos(a) * 17.0, 0, sin(a) * 17.0)
		if p.x < -6.0 and absf(p.z) < 9.0:
			continue  # keep the camera's view clear
		sb.box(p + Vector3(0, 0.2, 0), Vector3(1.2, 0.4, 1.2), stone, Vector3(0, -a, 0))
		sb.prim("cyl6", MB._xf(p + Vector3(0, 1.8, 0), Vector3(0.8, 2.8, 0.8), Vector3(0, a, 0)), stone)
		sb.lathe(p + Vector3(0, 3.2, 0), [Vector2(0.2, 0.0), Vector2(0.55, 0.2), Vector2(0.6, 0.35)], MB.tag(Color("3a3038"), MB.METAL), 10)
		sg.ball(p + Vector3(0, 3.65, 0), 0.5, Color(1.0, 0.6, 0.25, 0.75), true)
		sg.ball(p + Vector3(0, 3.65, 0), 1.0, Color(1.0, 0.5, 0.2, 0.2), true)
	MB.mesh_node(n, sb.build())
	MB.mesh_node(n, sg.build(MB.mat_glow()))
	# arena rune circle
	var rg := MB.new()
	rg.arc(Vector3(0, 0.06, 0), 13.4, 0.12, 0.0, TAU, Color(1, 1, 1, 0.3), 64)
	rg.arc(Vector3(0, 0.06, 0), 9.0, 0.08, 0.0, TAU, Color(1, 1, 1, 0.2), 56)
	for i in 24:
		var a2 := TAU * i / 24.0
		rg.box(Vector3(cos(a2) * 11.2, 0.06, sin(a2) * 11.2), Vector3(0.5, 0.01, 0.1), Color(1, 1, 1, 0.22), Vector3(0, -a2, 0))
	MB.mesh_node(n, rg.build(MB.mat_glow()))
	# scenery: two rings of the region's own vegetation, rocks and landmarks (see Scatter)
	var rng := RandomNumberGenerator.new()
	rng.seed = th.hash()
	Scatter.arena_ring(n, th, 22.0, 24, th.hash() & 0xffff)
	Scatter.arena_ring(n, th, 33.0, 34, (th.hash() >> 8) & 0xffff)
	# grass tufts scattered inside the arena
	var tuft := Terrain3D._proto("tuft:" + th, th)
	var grassy := float(Scatter.eco(th).grass) > 0.0 and str(look.get("tuft", "grass")) in ["grass", "deadgrass", "dunegrass", "snow", "moss", "flowers", "reed"]
	var tm := MultiMesh.new()
	tm.transform_format = MultiMesh.TRANSFORM_3D
	tm.use_colors = true
	tm.mesh = Scatter.grass_mesh(th, 0) if grassy else tuft
	var n_tufts := 900 if grassy else 260
	tm.instance_count = n_tufts
	for i in n_tufts:
		var a4 := rng.randf() * TAU
		var r2 := rng.randf_range(4.0, 30.0)
		var ts := rng.randf_range(0.8, 1.6)
		tm.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(ts, ts, ts)), Vector3(cos(a4) * r2, 0.0, sin(a4) * r2)))
		tm.set_instance_color(i, Color(1, 1, 1, 1))
	var ti := MultiMeshInstance3D.new()
	ti.multimesh = tm
	ti.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(ti)
	# far horizon silhouettes and a big celestial body
	var hz := Node3D.new()
	hz.position = Vector3(-40.0, 0, -40.0)
	n.add_child(hz)
	Terrain3D._horizon(hz, 40, 40, th, th.hash())
	var orb := MB.new()
	orb.ball(Vector3(30, 22, -48), 7.0, Color(look.sky_hor).lightened(0.4))
	var om := MB.mesh_node(n, orb.build(MB.mat_glow()))
	om.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.visible = false
	scene3d.add_child(n)
	stages[th] = {"node": n, "env": Look.environment(th, 0.8)}
	return stages[th]

func _build_fighters() -> void:
	for f in party + foes:
		var boss: bool = f.boss
		var m := Models.monster(f.shape, f.col, boss, f.get("id", "") if f.side == "foe" else "")
		var sc := 1.0
		if f.side == "foe":
			sc = 2.6 if boss else 1.35
			# (a person met on the road, fate.gd, stands a little taller than life, not as a giant)
			if str(f.shape).begins_with("person:"):
				sc = 1.25
		m.scale = Vector3.ONE * sc
		var holder := Node3D.new()
		holder.add_child(m)
		holder.add_child(Models.shadow_disc(1.0 * sc if f.side == "foe" else 0.7, 0.45))
		if f.side == "party":
			holder.add_child(_lotus())
		scene3d.add_child(holder)
		holder.position = pos3(f)
		holder.rotation.y = PI / 2.0 if f.side == "party" else -PI / 2.0
		f["node"] = holder
		f["model"] = m
		f["base_scale"] = sc
		f["lunge"] = 0.0
		f["meshes"] = _collect_meshes(m)

func _lotus() -> Node3D:
	var l := Models.lotus(Color(0.5, 0.85, 1.0), 0.8)
	l.position.y = 0.02
	return l

func _collect_meshes(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out.append_array(_collect_meshes(c))
	return out

func _clear_fighters() -> void:
	for f in party + foes:
		if f.has("node") and is_instance_valid(f.node):
			f.node.queue_free()

func pos3(f: Dictionary) -> Vector3:
	if f.side == "party":
		return Vector3(-5.5 - f.idx * 1.3, 0, 1.4 - f.idx * 3.6)
	return Data.foe_pos(f.get("slot", 0), foes.size(), f.boss)

func head3(f: Dictionary) -> Vector3:
	var hgt := 2.5
	if f.side == "foe":
		hgt = 6.2 if f.boss else 3.2
	return pos3(f) + Vector3(0, hgt, 0)

func start(foe_list: Array, c: Dictionary) -> void:
	ctx = c
	theme = c.get("theme", "bamboo")
	_clear_fighters()
	party.clear()
	foes.clear()
	for i in Game.party_size():
		party.append(Game.fighter(i))
	foes = Data.make_foes(foe_list)
	# the path taken through a trial shapes the battle: a talisman, allies, a bought advantage
	boon = c.get("boon", {})
	enraged = false
	if not c.get("tribulation", false):
		for f in foes:
			if f.boss:
				f.hp = float(f.maxhp) * float(boon.get("foe_hp", 1.0))
				f.atk = float(f.atk) * float(boon.get("foe_atk", 1.0))
	first_blow = true
	vajra_used = false
	tide_used = false
	state = "intro"
	timer = INTRO_BOSS if c.get("boss", false) else 1.4
	# the bestiary (lore.gd): every species met is remembered, and the first meeting with an ordinary
	# one tells its story over the opening (there is time to read it)
	lore_card = {}
	var met := {}
	for f in foes:
		var fid: String = str(f.id)
		if not Game.bestiary.has(fid) and not f.boss and lore_card.is_empty() and Lore.BEAST.has(fid):
			lore_card = {"n": str(f.name), "text": str(Lore.BEAST[fid])}
		# (battles, not heads: a pack of three wolves is one battle with wolves)
		if not met.has(fid):
			met[fid] = true
			Game.bestiary[fid] = int(Game.bestiary.get(fid, 0)) + 1
	if not lore_card.is_empty():
		timer = maxf(timer, LORE_INTRO)
	order.clear()
	round_no = 0
	outcome = ""
	fx.clear()
	log_lines.clear()
	level_before = Game.level
	Game.battles += 1
	if not headless():
		# the scars of the last battle's arena are swept away
		if scar_root != null and is_instance_valid(scar_root):
			scar_root.queue_free()
		scar_root = Node3D.new()
		scar_root.name = "scars"
		scene3d.add_child(scar_root)
		for k in stages:
			stages[k].node.visible = false
		var st: Dictionary = _stage_for(theme)
		st.node.visible = true
		cam.environment = st.env
		Look.apply_lights(theme, sun, fill)
		# the Living Land release: a battle is fought at the hour it was met (a tribulation brings its
		# own storm, whatever the hour: its sky is the stage's own, as at one in the afternoon)
		var bh := 13.0 if ctx.get("tribulation", false) else Clock.hour(Game)
		MB.set_night(float(Look.apply_hour(st.env, sun, fill, theme, bh, 0.8).night))
		main.fx_theme(theme)
		_build_fighters()
		cam.position = cam_base
		cam.look_at(cam_look, Vector3.UP)
	if ctx.get("boss", false):
		say("%s blocks your path!" % foes[0].name)
	else:
		say("Enemies appear!  %s" % ", ".join(foes.map(func(f): return f.name)))
	# realm suppression (Part XII): a whole realm between the fighters is felt before the first blow
	suppress_note = ""
	if not ctx.get("tribulation", false):
		var top := 0
		for f in foes:
			top = maxi(top, int(f.lv))
		var dr := Game.realm() - Data.realm_of(top)
		if dr >= 1:
			suppress_note = "Realm suppression: your %s weighs on them (x%.1f)" % [Data.REALMS[Game.realm()], Data.suppression(Game.level, top)]
		elif dr <= -1:
			suppress_note = "Realm suppression: their %s weighs on you (x%.2f)" % [Data.REALMS[Data.realm_of(top)], Data.suppression(Game.level, top)]
		if suppress_note != "":
			say(suppress_note)
	if str(c.get("path_n", "")) != "":
		say("%s: %s" % [str(c.get("path_kind", "")), str(c.path_n)])

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
			# a model with a death clip collapses first and then fades; a fallen ally stays on the
			# field, lying where they fell, until revived
			var dies: bool = f.has("model") and Assets.has_clip(f.model, "die")
			if not (dies and f.side == "party"):
				f.fade = maxf(0.0, f.fade - d * (0.6 if dies else 2.0))
	for p in fx:
		p.t -= d
	fx = fx.filter(func(p): return p.t > 0.0)
	if main.top_name() != "battle":
		return
	match state:
		"intro", "acting":
			timer -= d
			if timer <= 0.0:
				_next_turn()
	if not headless():
		_update_view(d)
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
			# the crown of Spirit Sense: Lin Feng moves first in the first round
			if round_no == 1 and (Game.talent_crown("spirit_sense") or boon.get("first", false)):
				for k in all.size():
					if all[k].side == "party" and all[k].idx == 0:
						all.push_front(all.pop_at(k))
						break
			order = all
			# allies a trial's path brought strike at the start of every round
			if _assist():
				continue
		cur = order.pop_front()
		if not cur.dead:
			break
	cur.turns += 1
	if cur.side == "party":
		# a Sea of Qi gathers more every turn
		cur.qi = minf(cur.maxqi, cur.qi + cur.maxqi * (0.04 + (Game.talent_mod("regen") if cur.idx == 0 else 0.0)))
		# the crown of the Sea of Qi: once a battle, when it runs low, the tide comes back in
		if cur.idx == 0 and not tide_used and cur.qi < cur.maxqi * 0.2 and Game.talent_crown("qi_sea"):
			tide_used = true
			cur.qi = minf(cur.maxqi, cur.qi + cur.maxqi / 3.0)
			say("The tide comes in: Lin Feng's qi floods back.")
		# the Compassionate Heart: Lin Feng's wounds close by themselves
		var regen := Game.dao_mod("regen", 0.0)
		if cur.idx == 0 and regen > 0.0 and cur.hp < cur.maxhp:
			cur.hp = minf(cur.maxhp, cur.hp + cur.maxhp * regen)
		_open_main()
		state = "menu"
	else:
		_foe_act(cur)
		state = "acting"

## The allies a trial's path brought (the sect's elders, a people's warriors) strike every boss at the
## start of a round for a share of its health.  Returns whether the battle is over because of it.
func _assist() -> bool:
	var share := float(boon.get("assist", 0.0))
	if share <= 0.0:
		return false
	for f in alive(foes):
		if not f.boss:
			continue
		var dmg := maxi(1, int(float(f.maxhp) * share))
		f.hp = maxf(0.0, f.hp - dmg)
		f.flash = 0.35
		fx.append({"text": str(dmg), "p": head3(f), "t": 1.0, "col": Color("8ae0c0"), "slash": ""})
		# (an old bond, fate.gd, names who came)
		var who := str(ctx.get("path_n", "Your allies")) if str(ctx.get("path_kind", "")) == str(Trials.KINDS.bond.n) else "Your allies"
		if who.begins_with("By "):
			who = "The friends you made"
		say("%s strike %s for %d." % [who, f.name, dmg])
		if f.hp <= 0.0:
			f.dead = true
			Game.kills += 1
			if f.has("model"):
				Models.act(f.model, "die", t)
			say("%s is defeated." % f.name)
	return alive(foes).is_empty()

func _foe_act(f: Dictionary) -> void:
	var tg: Array = alive(party)
	if f.boss and f.turns % 3 == 0:
		# a talisman or a ward (a trial's path) blunts the worst of it
		var heavy := 1.45
		if boon.get("no_heavy", false):
			heavy = 1.1
			say("%s unleashes a devastating attack, but it is blunted!" % f.name)
		else:
			say("%s unleashes a devastating attack!" % f.name)
		for p in tg:
			_hit(f, p, heavy, f.elem, true)
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

## One blow; returns the harm it did (0 if it missed).
func _hit(a: Dictionary, tgt: Dictionary, mult: float, elem: String, quiet: bool) -> int:
	# the Daos (Part XI): a party member may slip the blow (Free Wandering, and Lin Feng's Spirit Sense)
	# or the foe may strike a reflection (the Mirror, and the celestial foxes' friendship)
	if tgt.side == "party" and a.side == "foe":
		var slip := Game.dao_mod("evade", 0.0) + (Game.talent_mod("evade") if tgt.idx == 0 else 0.0)
		var miss := Game.dao_mod("miss", 0.0) + Game.boon("miss", 0.0) + (0.04 if Game.talent_crown("spirit_sense") else 0.0)
		if slip > 0.0 and randf() < slip:
			fx.append({"text": "slips it", "p": head3(tgt), "t": 1.0, "col": Color("b8f0d0"), "slash": ""})
			say("%s slips the blow." % tgt.name)
			return 0
		if miss > 0.0 and randf() < miss:
			fx.append({"text": "a reflection", "p": head3(tgt), "t": 1.0, "col": Color("c8a8ff"), "slash": ""})
			say("%s strikes at a reflection." % a.name)
			return 0
	var weak_k := Game.dao_mod("weak", 1.5) if a.side == "party" else 1.5
	# a trial's path can show where a foe is weakest (a lens, a Dao)
	if a.side == "party" and boon.has("weak_k"):
		weak_k = maxf(weak_k, float(boon.weak_k))
	var em := weak_k if tgt.weak == elem and elem != "phys" else 1.0
	var raw: float = a.atk * mult * randf_range(0.9, 1.1) * em - tgt.def * 0.5
	# realm suppression (Part XII): a realm above weighs on a realm below; a tribulation is heaven
	# itself and weighs on everyone the same
	if not ctx.get("tribulation", false):
		raw *= Data.suppression(int(a.lv), int(tgt.lv))
	if tgt.side == "party":
		# Formations and the Heart (and the shades' friendship) soften every blow; so does a Vajra Body
		raw *= Game.dao_mod("taken", 1.0) * Game.boon("taken", 1.0) * (1.0 - (Game.talent_mod("taken") if tgt.idx == 0 else 0.0))
		# and a formation or allies a trial's path brought
		raw *= float(boon.get("taken", 1.0))
	var lf: bool = a.side == "party" and a.idx == 0
	var crit := randf() < 0.08 + (Game.talent_mod("crit") if lf else 0.0)
	# the crown of the Sword Bone: Lin Feng's first blow of the battle always lands true
	if lf and first_blow:
		first_blow = false
		if Game.talent_crown("sword_bone"):
			crit = true
	if crit:
		raw *= 1.5
	var dmg := maxi(1, int(round(raw)))
	# the crown of the Vajra Body: once a battle, a blow that would fell Lin Feng leaves him a breath
	if tgt.side == "party" and tgt.idx == 0 and tgt.hp - dmg <= 0.0 and not vajra_used and Game.talent_crown("vajra"):
		vajra_used = true
		dmg = maxi(0, int(tgt.hp) - 1)
		say("Lin Feng's Vajra Body holds!")
	tgt.hp = maxf(0.0, tgt.hp - dmg)
	tgt.flash = 0.35
	tgt.shake = 0.3
	var col: Color = Data.ELEM_COLORS.get(elem, Color.WHITE)
	var txt := str(dmg) + ("!" if crit else "") + (" weak" if em > 1.0 else "")
	a["lunge"] = 0.5
	a["lunge_to"] = pos3(tgt)
	fx.append({"text": txt, "p": head3(tgt) + Vector3(randf_range(-0.4, 0.4), 0, 0), "t": 1.0, "col": col if tgt.side == "foe" else UI.C_RED.lightened(0.3), "slash": elem})
	if not headless() and tgt.has("node"):
		var big := quiet or mult >= 2.5 or crit
		var hp3 := pos3(tgt) + Vector3(0, 1.4 if not tgt.boss else 2.8, 0)
		Fx3D.hit(scene3d, hp3, elem, big)
		if mult <= 1.0 or elem == "phys":
			var yaw := atan2(hp3.x - cam.position.x, hp3.z - cam.position.z)
			Fx3D.slash(scene3d, hp3, col.lerp(Color.WHITE, 0.4), yaw, 3.2 if tgt.boss else 2.2)
		if a.has("model"):
			Models.act(a.model, "attack", t)
		if tgt.has("model"):
			Models.act(tgt.model, "hurt", t)
		if big:
			cam_shake = 0.35
			main.fx_flash(col.lerp(Color.WHITE, 0.5), 0.22 if tgt.side == "foe" else 0.3)
			# the Living Land release (havoc.gd): a heavy blow throws up the arena floor and scorches it
			var fl := pos3(tgt)
			fl.y = 0.0
			# (the pieces fly out from the middle of the arena, past the one who was hit)
			var from: Vector3 = fl if fl.length() > 0.5 else Vector3(0, 0, 1)
			if scar_root != null:
				Havoc.burst(scar_root, "rubble", fl, from, null, 0.85 if not tgt.boss else 1.1, Color(Look.theme(theme).path).darkened(0.25))
				if scar_root.get_child_count() < 40:
					scar_root.add_child(Havoc.scar(fl, 1.0 if not tgt.boss else 1.7, null))
	# a trial's boss brought low is enraged, once (trials.gd): it is harder than the bosses before it
	if tgt.side == "foe" and tgt.boss and str(ctx.get("trial", "")) != "" and not enraged and tgt.hp > 0.0 and tgt.hp < tgt.maxhp * Trials.ENRAGE_AT:
		enraged = true
		tgt.atk = float(tgt.atk) * Trials.ENRAGE
		say("%s is enraged!" % tgt.name)
	if tgt.hp <= 0.0:
		tgt.dead = true
		if tgt.has("model"):
			Models.act(tgt.model, "die", t)
		say("%s is defeated." % tgt.name if tgt.side == "foe" else "%s collapses!" % tgt.name)
		if tgt.side == "foe":
			Game.kills += 1
	return dmg

func _heal(tgt: Dictionary, amount: float) -> void:
	# the Compassionate Heart and the Pearl-Weepers' friendship strengthen every heal
	amount *= Game.dao_mod("heal", 1.0) * Game.boon("heal", 1.0)
	tgt.hp = minf(tgt.maxhp, tgt.hp + amount)
	fx.append({"text": "+%d" % int(amount), "p": head3(tgt), "t": 1.0, "col": UI.C_JADE, "slash": ""})
	if not headless() and tgt.has("node"):
		Fx3D.heal(scene3d, pos3(tgt) + Vector3(0, 1.0, 0))

func _perform(actor: Dictionary, skill_id: String, tgts: Array) -> void:
	var s: Dictionary = Data.SKILLS[skill_id]
	actor.qi -= Game.skill_cost(skill_id)
	if s.has("heal"):
		say("%s casts %s." % [actor.name, s.n])
		if not headless() and actor.has("model"):
			Models.act(actor.model, "cast", t)
			Fx3D.technique(scene3d, skill_id, pos3(actor), tgts.map(func(f): return pos3(f)))
		for tg in tgts:
			if tg.dead and s.get("revive", false):
				tg.dead = false
				tg.fade = 1.0
				if tg.has("model"):
					Models.act(tg.model, "", t)
				say("%s is raised by %s!" % [tg.name, s.n])
			_heal(tg, tg.maxhp * s.heal)
	else:
		say("%s uses %s." % [actor.name, s.n])
		if not headless() and actor.has("model"):
			Fx3D.charge(scene3d, pos3(actor) + Vector3(0, 1.2, 0), Data.ELEM_COLORS.get(s.elem, Color.WHITE))
			for tg in tgts:
				Fx3D.projectile(scene3d, pos3(actor) + Vector3(0, 1.4, 0), pos3(tg) + Vector3(0, 1.4 if not tg.boss else 2.8, 0), Data.ELEM_COLORS.get(s.elem, Color.WHITE))
			Fx3D.technique(scene3d, skill_id, pos3(actor), tgts.map(func(f): return pos3(f)), atan2(cam_look.x - cam.position.x, cam_look.z - cam.position.z))
		# the Sword's Dao: Lin Feng's single strikes cut deeper, his plain sword strike deepest; and the
		# branches of his root he has woken strengthen the techniques of their element (Part XII)
		var dm := 1.0
		var lf: bool = actor.side == "party" and actor.idx == 0
		if lf:
			if skill_id == "strike":
				dm = Game.dao_mod("strike", 1.0)
			elif s.tgt == "one":
				dm = Game.dao_mod("one", 1.0)
			dm *= Game.talent_power(skill_id)
		for tg in tgts:
			var done := _hit(actor, tg, s.mult * dm, s.elem, false)
			if not lf or done <= 0:
				continue
			# the crown of the Thunder Root: lightning answers lightning on a weakness
			if s.elem == "thunder" and tg.weak == "thunder" and not tg.dead and Game.talent_crown("thunder_root"):
				say("Thunder answers thunder!")
				_hit(actor, tg, s.mult * dm * 0.5, s.elem, true)
			# the crown of the Yin Root: the dark keeps a tenth of what it takes
			if s.elem == "dark" and Game.talent_crown("yin_root"):
				actor.hp = minf(actor.maxhp, actor.hp + done * 0.1)
		if not headless() and actor.has("model"):
			Models.act(actor.model, "cast", t)
	_end_action()

func _use_item(actor: Dictionary, item: String, tgt: Dictionary) -> void:
	Game.inv[item] -= 1
	# the Cauldron's Dao: pills do far more good
	var pk := Game.dao_mod("pill", 1.0)
	if item == "hp_pill":
		say("%s feeds %s a healing pill." % [actor.name, tgt.name])
		_heal(tgt, tgt.maxhp * 0.4 * pk)
	else:
		say("%s restores %s's qi." % [actor.name, tgt.name])
		tgt.qi = minf(tgt.maxqi, tgt.qi + tgt.maxqi * 0.5 * pk)
		fx.append({"text": "+qi", "p": head3(tgt), "t": 1.0, "col": UI.C_BLUE, "slash": ""})
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
	# the Cauldron's Dao pays better, and so does Heaven's Favour; every victory deepens the Dao Lin
	# Feng walks (twice over with the crown of an Enlightened Mind), and an Enlightened Mind learns more
	stones = int(stones * Game.dao_mod("stones", 1.0) * (1.0 + Game.talent_mod("stones")) * Game.boon("stones", 1.0))
	xp = int(xp * (1.0 + Game.talent_mod("exp")) * Game.boon("exp", 1.0))
	if not ctx.get("tribulation", false):
		Game.dao_battle_won(boss)
		if Game.talent_crown("insight"):
			Game.dao_battle_won(boss)
	result_lines = ["VICTORY", "+%d cultivation   +%d spirit stones" % [xp, stones]]
	if ctx.get("tribulation", false):
		xp = 0
		stones = 0
		result_lines = ["The tribulation is endured!"]
	else:
		# essences (trials.gd): what the foes leave behind, for the cauldron, the forge and the townsfolk
		var ess := {}
		for f in foes:
			var ek := Trials.essence_of(str(f.elem))
			if ek == "":
				continue
			var n: int = Trials.ESS_BOSS if f.boss else (1 if randf() < Trials.ESS_DROP + Game.talent_mod("drop") else 0)
			if n > 0:
				ess[ek] = int(ess.get(ek, 0)) + n
		var got: Array = []
		for ek in ess:
			Game.add_item(ek, ess[ek])
			got.append("%d %s" % [ess[ek], Data.ITEMS[ek].n])
		if not got.is_empty():
			result_lines.append("Essences: " + ", ".join(got))
	Game.stones += stones
	if boss and not ctx.get("tribulation", false):
		var fav := 3 if Game.talent_crown("fortune") else 2
		Game.add_item("hp_pill", fav)
		Game.add_item("qi_pill", 1)
		result_lines.append("Found: %d Healing Pills, 1 Spirit Qi Pill" % fav)
	elif randf() < 0.25 + Game.talent_mod("drop"):
		Game.add_item("hp_pill", 1)
		result_lines.append("Found: Healing Pill")
	Game.add_exp(xp)
	if Game.level > level_before:
		result_lines.append("Cultivation advanced: %s" % Data.level_name(Game.level))
	if not headless():
		for p in alive(party):
			if p.has("model"):
				Models.act(p.model, "victory", t)
				p.model.set_meta("act_t", t + 0.3)
			if Game.level > level_before:
				Fx3D.ascend(scene3d, pos3(p))

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
		labels.append("%s\t%d qi" % [s.n, Game.skill_cost(sid)])
		ids.append(sid)
		enabled.append(cur.qi >= Game.skill_cost(sid))
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
				# basic attacks (Lin Feng's strike, Yue Ling's needle) go back to the main menu
				if pending.skill != "" and not pending.skill in ["strike", "needle"]:
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
					# a reviving heal reaches the fallen too (the Lotus of Rebirth used to skip them)
					_perform(cur, sid, party if s.get("revive", false) else alive(party))
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

# ---------------------------------------------------------------- 3D view
func _update_view(d: float) -> void:
	# slow camera drift
	var sway := Vector3(sin(t * 0.25) * 0.9, sin(t * 0.4) * 0.25, cos(t * 0.25) * 0.5)
	var focus := cam_look
	if state == "menu" and menu_kind == "target" and not targets.is_empty():
		focus = cam_look.lerp(pos3(targets[ids[cursor]]), 0.25)
	if state == "intro" and ctx.get("boss", false) and not foes.is_empty():
		# boss intro: start on a low close-up of the boss and sweep back to the battle view
		var k := clampf(1.0 - timer / INTRO_BOSS, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		var bp := pos3(foes[0]) + Vector3(0, 3.4, 0)
		var close := bp + Vector3(-7.5, -1.6, -4.0 + 8.0 * e)
		cam.position = close.lerp(cam_base + sway, e)
		focus = bp.lerp(cam_look, e)
	else:
		cam.position = cam.position.lerp(cam_base + sway, 1.0 - exp(-d * 4.0))
	if cam_shake > 0.0:
		cam_shake = maxf(0.0, cam_shake - d)
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * cam_shake * 0.6
	cam.look_at(focus, Vector3.UP)
	# the heavens rumble during a tribulation
	if ctx.get("tribulation", false):
		storm_t -= d
		if storm_t <= 0.0:
			storm_t = randf_range(1.2, 3.0)
			var ang := randf_range(-1.2, 1.2)
			Fx3D.lightning(scene3d, Vector3(18.0 * cos(ang) + 6.0, 0, 18.0 * sin(ang)), Color(0.75, 0.85, 1.0), 26.0, 0.3)
			main.fx_flash(Color(0.8, 0.85, 1.0), 0.35)
	for f in party + foes:
		if not f.has("node"):
			continue
		var node: Node3D = f.node
		var base := pos3(f)
		var off := Vector3.ZERO
		if f.lunge > 0.0:
			f.lunge = maxf(0.0, f.lunge - d)
			var k := sin(PI * (1.0 - f.lunge / 0.5))
			off = (f.lunge_to - base).limit_length(4.0) * 0.55 * k
		if f.shake > 0.0:
			off += Vector3(0, 0, sin(t * 80.0) * 0.25)
		node.position = base + off
		var fade: float = f.fade
		var dies2: bool = Assets.has_clip(f.model, "die") if f.has("model") else false
		node.visible = fade > 0.01
		node.scale = Vector3.ONE * (maxf(0.01, fade / 0.35) if dies2 and fade < 0.35 else (1.0 if dies2 else maxf(0.01, fade)))
		var m: Node3D = f.model
		var slot: float = float(f.idx if f.side == "party" else f.get("slot", 0))
		Models.anim_monster(m, t, slot)
		m.position.y = sin(t * 2.4 + slot) * 0.07 if f.side == "foe" else 0.0
		if f.dead and not Assets.has_clip(m, "die"):
			node.rotation.z = (1.0 - fade) * 1.2
		elif not f.dead:
			node.rotation.z = 0.0
		# hit flash overlay
		var ov: Material = flash_mat if f.flash > 0.0 else null
		for mi in f.meshes:
			mi.material_overlay = ov
	# markers
	ring_cur.visible = state == "menu" and not cur.is_empty() and cur.side == "party" and not cur.dead
	if ring_cur.visible:
		ring_cur.position = pos3(cur) + Vector3(0, 0.1, 0)
		ring_cur.rotation.y = t * 1.5
	arrow_tgt.visible = state == "menu" and menu_kind == "target" and not targets.is_empty()
	if arrow_tgt.visible:
		var tg: Dictionary = targets[ids[cursor]]
		arrow_tgt.position = pos3(tg) + Vector3(0, (7.2 if tg.boss else 3.9) + sin(t * 6.0) * 0.2, 0)
		arrow_tgt.rotation.y = t * 2.0

func _screen(p: Vector3) -> Vector2:
	if cam == null or not cam.is_inside_tree() or cam.is_position_behind(p):
		return Vector2(-999, -999)
	return cam.unproject_position(p)

# ---------------------------------------------------------------- 2D overlay
func _draw() -> void:
	# overhead bars / names
	# foes only: the party stands under the command panels and has its own status panel
	var placed: Array = []
	for f in foes:
		if f.dead or f.fade <= 0.5 or not f.has("node"):
			continue
		var sp := _screen(pos3(f) + Vector3(0, 0.0, 0))
		var bw := 100.0 if not f.boss else 190.0
		var by := sp.y + (14.0 if not f.boss else 22.0)
		UI.bar(self, Rect2(sp.x - bw / 2, by, bw, 8), f.hp / f.maxhp, UI.C_RED)
		var nw := 360.0 if f.boss else 200.0
		var fs := UI.fit(f.name, 14, nw, 11)
		var tw := minf(UI.font().get_string_size(f.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, nw)
		# a name that would run into one already drawn (two long names side by side) moves down a row
		var lr := Rect2(sp.x - tw / 2, by + 24 - fs, tw, fs + 4)
		var guard := 0
		while guard < 4 and placed.any(func(q): return (q as Rect2).intersects(lr)):
			lr.position.y += 15
			guard += 1
		placed.append(lr)
		UI.text(self, Vector2(sp.x - nw / 2, lr.position.y + fs), f.name, fs, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, nw)
	for p in fx:
		var a := clampf(p.t, 0.0, 1.0)
		var sp2 := _screen(p.p) + Vector2(0, -(1.0 - p.t) * 40.0)
		UI.text(self, sp2 + Vector2(-100, 0), p.text, 30, Color(p.col.r, p.col.g, p.col.b, a), HORIZONTAL_ALIGNMENT_CENTER, 340)
	_draw_ui()

func _draw_ui() -> void:
	# log
	UI.panel(self, Rect2(300, 556, 470, 150))
	# the newest messages, wrapped to the panel (three long names take two rows)
	var rows: Array = []
	for l in log_lines:
		rows.append_array(UI.wrap_lines(l, 16, 440))
	var y := 584.0
	for row in rows.slice(maxi(0, rows.size() - 5)):
		UI.text(self, Vector2(316, y), row, 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 440)
		y += 25
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
	# boss title card during the intro sweep
	if state == "intro" and ctx.get("boss", false) and not foes.is_empty():
		var f0: Dictionary = foes[0]
		var a := clampf(minf(INTRO_BOSS - timer, timer) * 2.5, 0.0, 1.0)
		var ec: Color = Data.ELEM_COLORS.get(f0.elem, Color.WHITE)
		UI.panel(self, Rect2(VIEW.x * 0.5 - 330, 70, 660, 92), Color(0.03, 0.03, 0.08, 0.8 * a), Color(ec.r, ec.g, ec.b, a))
		UI.text(self, Vector2(VIEW.x * 0.5 - 330, 116), f0.name, UI.fit(f0.name, 34, 660, 24), Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, a), HORIZONTAL_ALIGNMENT_CENTER, 660)
		var sub := "Heavenly Tribulation" if ctx.get("tribulation", false) else "%s  -  weak to %s" % [str(f0.elem).capitalize(), str(f0.weak).capitalize()]
		UI.text(self, Vector2(VIEW.x * 0.5 - 330, 146), sub, 16, Color(ec.r, ec.g, ec.b, a), HORIZONTAL_ALIGNMENT_CENTER, 660)
	# a species met for the first time: its story (lore.gd), over the opening
	if state == "intro" and not lore_card.is_empty():
		var la := clampf(minf(LORE_INTRO - timer, timer) * 2.0, 0.0, 1.0)
		var lr := Rect2(VIEW.x * 0.5 - 380, 64, 760, 150)
		UI.panel(self, lr, Color(0.03, 0.03, 0.08, 0.85 * la), Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, la))
		UI.text(self, lr.position + Vector2(20, 30), "First meeting: " + str(lore_card.n), 18, Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, la))
		UI.wrapped(self, lr.position + Vector2(20, 58), str(lore_card.text), 16, Color(UI.C_TEXT.r, UI.C_TEXT.g, UI.C_TEXT.b, la), lr.size.x - 40)
	# command menu
	if state == "menu":
		UI.menu_list(self, Rect2(16, 556, 270, 150), labels, cursor, enabled, 20 if labels.size() < 5 else 16)
		UI.text(self, Vector2(20, 548), "%s's turn" % cur.name, 15, UI.C_GOLD)
	elif state == "result":
		UI.panel(self, Rect2(320, 150, 640, 254))
		var yy2 := 205.0
		for i in result_lines.size():
			UI.text(self, Vector2(320, yy2), result_lines[i], 32 if i == 0 else 20, UI.C_GOLD if i == 0 else UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 640)
			yy2 += 50 if i == 0 else 34
		UI.text(self, Vector2(320, 390), "Press Enter", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 640)
