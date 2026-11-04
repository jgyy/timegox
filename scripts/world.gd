extends ScreenBase
## Third-person 3D world: grid-based movement with a chase camera, entity models and the 2D HUD overlay.
## The logic (tiles, movement, interaction) is identical to the original top-down game; only the view is 3D.

const TS := Terrain3D.T
const STEP_T := 0.16
const VIEW := Vector2(1280, 720)
const CAM_DIST := 8.5
const CAM_H := 7.0
const FWD := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const RIGHT := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const HERO_OPTS := {"asset": "lin_feng", "sword": true, "glow": Color(0.4, 0.7, 1.0), "hair": "topknot", "trim": Color("e8f0ff"), "cape": Color("2a5aa8")}
const YUE_OPTS := {"asset": "yue_ling", "ribbon": Color("ffb0cc"), "glow": Color(1.0, 0.6, 0.8), "hair": "long", "eyes": Color("c04080")}

var area_id := ""
var w := 0
var h := 0
var grid := PackedByteArray()
var ents: Array = []
var theme_name := ""
var area_name := ""
var ptile := Vector2i(1, 1)
var target := Vector2i(1, 1)
var move_t := -1.0
var facing := Vector2i(1, 0)
var move_dir := Vector2i.ZERO
var banner_t := 0.0
var cache := {}
var mini_tex: ImageTexture = null

# 3D state
var views := {}
var cur_view := {}
var player: Node3D
var comp: Node3D
var comp_pos := Vector3.ZERO
var weather: CPUParticles3D
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var hero_light: OmniLight3D
var hm := PackedFloat32Array()
var step_side := 0
var last_step_phase := 0.0
var cam_q := 0
var cam_a := 0.0
var cam_pos := Vector3.ZERO

func _build3d() -> void:
	opaque = false
	new_scene3d()
	new_camera(62.0)
	sun = Look.sun("sect")
	scene3d.add_child(sun)
	fill = Look.fill("sect")
	scene3d.add_child(fill)
	player = Models.person(Color("3a8ae8"), Color("1a1a2a"), HERO_OPTS)
	player.add_child(Models.shadow_disc(0.55))
	scene3d.add_child(player)
	hero_light = OmniLight3D.new()
	hero_light.light_color = Color(0.7, 0.85, 1.0)
	hero_light.light_energy = 0.6
	hero_light.omni_range = 9.0
	hero_light.position = Vector3(0, 2.2, 0)
	player.add_child(hero_light)
	comp = Models.person(Color("e86a9a"), Color("402030"), YUE_OPTS)
	comp.add_child(Models.shadow_disc(0.5))
	comp.visible = false
	scene3d.add_child(comp)
	weather = Fx3D.make_weather()
	scene3d.add_child(weather)

func clear_cache() -> void:
	cache.clear()
	for k in views:
		views[k].root.queue_free()
		for n in views[k].nodes:
			n.queue_free()
	views.clear()
	cur_view = {}

func load_area(id: String, at: Vector2i) -> void:
	area_id = id
	if not cache.has(id):
		cache[id] = MapGen.build(id)
	var m: Dictionary = cache[id]
	w = m.w
	h = m.h
	grid = m.grid
	ents = m.ents
	theme_name = m.theme
	area_name = m.name
	ptile = at
	target = at
	move_t = -1.0
	Game.area = id
	Game.tile = at
	banner_t = 3.0
	if not headless():
		mini_tex = Gfx.minimap_image(grid, w, h, Look.theme(theme_name))
		_show_view(id, m)
		_snap_cam()

func _show_view(id: String, m: Dictionary) -> void:
	if not cur_view.is_empty():
		cur_view.root.visible = false
		for n in cur_view.nodes:
			n.visible = false
	if not views.has(id):
		var root := Terrain3D.build(m.grid, m.w, m.h, m.theme, Data.AREAS[id].seed)
		scene3d.add_child(root)
		hm = root.get_meta("hm", PackedFloat32Array())
		var nodes: Array = []
		for e in m.ents:
			var n := _make_ent(e)
			n.position.y = ground_y(n.position)
			scene3d.add_child(n)
			nodes.append(n)
		views[id] = {"root": root, "nodes": nodes, "env": Look.environment(m.theme)}
	cur_view = views[id]
	cur_view.root.visible = true
	hm = cur_view.root.get_meta("hm", PackedFloat32Array())
	cam.environment = cur_view.env
	var th := Look.theme(theme_name)
	main.fx_theme(theme_name)
	Look.apply_lights(theme_name, sun, fill)
	Fx3D.configure_weather(weather, th.weather)

# ---------------------------------------------------------------- entities
func ent_visible(e: Dictionary) -> bool:
	match e.kind:
		"enemy":
			var k: String = area_id + ":" + e.id
			if Game.defeated.has(k):
				return false
			return true
		"boss":
			return not Game.boss_done.has(e.enemy)
		"pickup":
			if Game.taken.has(e.id):
				return false
		"portal":
			return true
	var v = e.get("vis", ["", ""])
	if v[0] != "" and not Game.reached(v[0]):
		return false
	if v[1] != "" and Game.done(v[1]):
		return false
	return true

func ent_at(tile: Vector2i):
	for e in ents:
		if e.pos == tile and e.kind != "spring" and ent_visible(e):
			return e
	return null

func tile_free(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= w or tile.y >= h:
		return false
	return MapGen.is_walkable_tile(grid[tile.y * w + tile.x])

func near_spring() -> bool:
	for e in ents:
		if e.kind == "spring":
			if maxi(absi(e.pos.x - ptile.x), absi(e.pos.y - ptile.y)) <= 3:
				return true
	return false

func find_ent(id: String):
	for e in ents:
		if e.id == id:
			return e
	return null

# ---------------------------------------------------------------- 3D models for entities
static func _label(parent: Node3D, text: String, y: float, col: Color, size: int = 34) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.0085
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = col
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.position = Vector3(0, y, 0)
	l.shaded = false
	l.no_depth_test = false
	parent.add_child(l)
	return l

func _npc_opts(id: String) -> Dictionary:
	match id:
		"elder":
			return {"asset": "elder_qing", "beard": true, "staff": true, "hair": "bald", "trim": Color("c8a850")}
		"alchemist":
			return {"asset": "alchemist", "hat": true, "hair": "bun"}
		"smith":
			return {"asset": "smith", "sash": false, "hair": "bun", "armor": true, "metal": Color("8a6a4a")}
		"yue_ling":
			return {"asset": "yue_ling", "ribbon": Color("ff9ac0"), "hair": "long", "eyes": Color("c04080")}
		"sword_ghost":
			return {"sword": true, "beard": true, "glow": Color(0.6, 0.85, 1.0), "hair": "topknot"}
		"dragon_envoy", "gate_keeper", "lake_keeper", "grave_keeper", "time_ferryman", "origin_keeper", "cloud_warden", "court_scribe":
			return {"staff": true, "glow": Color(1.0, 0.95, 0.7), "hair": "long" if id in ["lake_keeper", "court_scribe"] else "bun"}
		"forge_master":
			return {"sash": false, "hair": "wild", "armor": true, "metal": Color("b07a40"), "beard": true}
		"peach_keeper":
			return {"ribbon": Color("ffd0e0"), "hair": "long", "crown": true, "glow": Color(1.0, 0.8, 0.9)}
		"nomad", "spore_witch", "steppe_shaman", "nuwa_echo":
			return {"asset": id, "staff": true, "hair": "long", "glow": Color(1.0, 0.95, 0.8)}
		"fire_sage", "void_hermit":
			return {"beard": true, "hat": true, "hair": "bald"}
	return {}

func _make_ent(e: Dictionary) -> Node3D:
	var n := Node3D.new()
	n.position = Terrain3D.world_pos(e.pos)
	n.visible = false
	match e.kind:
		"npc":
			var m := Models.person(e.col, Color("2a2a3a"), _npc_opts(e.id))
			n.add_child(m)
			n.add_child(Models.shadow_disc(0.6))
			_label(n, e.n, 2.45, UI.C_GOLD)
			var mark := _label(n, "!", 3.1, Color("ffdc50"), 72)
			n.set_meta("model", m)
			n.set_meta("mark", mark)
		"enemy":
			var g: Array = e.group
			var d: Dictionary = Data.ENEMIES[g[0].id]
			var m0 := Models.monster(d.shape, d.col)
			n.add_child(m0)
			var models := [m0]
			for k in range(1, mini(g.size(), 3)):
				var d2: Dictionary = Data.ENEMIES[g[k].id]
				var mk := Models.monster(d2.shape, d2.col)
				mk.scale = Vector3.ONE * 0.6
				mk.position = Vector3(1.0 if k % 2 == 1 else -1.0, 0, -0.6)
				n.add_child(mk)
				models.append(mk)
			n.add_child(Models.shadow_disc(0.8))
			_label(n, "%s x%d" % [d.n, g.size()], 2.5, UI.C_RED.lightened(0.3), 30)
			n.rotation.y = Terrain3D.hash2(e.pos.x, e.pos.y) * TAU
			n.set_meta("models", models)
		"boss":
			var d3: Dictionary = Data.ENEMIES[e.enemy]
			var mb := Models.monster(d3.shape, d3.col, true)
			mb.scale = Vector3.ONE * 1.9
			n.add_child(mb)
			n.add_child(Models.shadow_disc(2.0, 0.5))
			_label(n, d3.n, 5.2, UI.C_GOLD, 44)
			n.rotation.y = PI
			n.set_meta("models", [mb])
		"pickup":
			var col: Color = Look.PICKUP_COLORS.get(e.item, Color.WHITE)
			var gm := Models.gem(col)
			gm.position.y = 1.0
			n.add_child(gm)
			_label(n, Data.ITEMS[e.item].n, 2.0, col, 28)
			n.set_meta("gem", gm)
		"portal":
			var open: bool = e.open == "" or Game.done(e.open)
			var pc := UI.C_JADE if open else Color("8a4a4a")
			var pm := Models.portal(pc, open)
			# gates on the west/east edge face along x, gates on the north/south edge along z
			if e.pos.x < 4 or e.pos.x > w - 5:
				pm.rotation.y = PI / 2
			n.add_child(pm)
			var lbl := _label(n, "", 4.1, pc, 32)
			n.set_meta("label", lbl)
			n.set_meta("model", pm)
		"spring":
			n.add_child(Models.spring_basin())
	return n

# ---------------------------------------------------------------- update
func _process(d: float) -> void:
	t += d
	if banner_t > 0.0:
		banner_t -= d
	# respawn defeated enemies after a while (only when away from them)
	for k in Game.defeated.keys():
		if Game.playtime - Game.defeated[k] > 150.0 and k.begins_with(area_id + ":"):
			var e = find_ent(k.get_slice(":", 1))
			if e != null and maxi(absi(e.pos.x - ptile.x), absi(e.pos.y - ptile.y)) > 6:
				Game.defeated.erase(k)
	var active: bool = main.top_name() == "world"
	if active:
		if not main.bot_active:
			move_dir = _read_keys()
		_move(minf(d, 0.1))
	if not headless() and visible:
		_update_view(d)
		queue_redraw()

func rotate_cam(dir: int) -> void:
	cam_q = (cam_q + dir + 4) % 4

func _read_keys() -> Vector2i:
	var f: Vector2i = FWD[cam_q]
	var r: Vector2i = RIGHT[cam_q]
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		return -r
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		return r
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		return f
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		return -f
	return Vector2i.ZERO

func _move(d: float) -> void:
	var budget := d
	while budget > 0.0001:
		if move_t < 0.0:
			if move_dir == Vector2i.ZERO:
				return
			facing = move_dir
			var nt := ptile + move_dir
			var e = ent_at(nt)
			if e != null and e.kind != "portal":
				move_dir = Vector2i.ZERO
				main.interact(e)
				return
			if not tile_free(nt):
				return
			target = nt
			move_t = 0.0
		var need := (1.0 - move_t) * STEP_T
		if budget >= need:
			budget -= need
			ptile = target
			move_t = -1.0
			Game.tile = ptile
			var pe = ent_at(ptile)
			if pe != null and pe.kind == "portal":
				main.use_portal(pe)
				return
		else:
			move_t += budget / STEP_T
			budget = 0.0

func face_entity():
	return ent_at(ptile + facing)

# ---------------------------------------------------------------- 3D view update
func ground_y(p: Vector3) -> float:
	return Terrain3D.sample(hm, w, h, p.x, p.z)

func _player_pos() -> Vector3:
	var pp := Terrain3D.world_pos(ptile)
	if move_t >= 0.0:
		pp = pp.lerp(Terrain3D.world_pos(target), move_t)
	pp.y = ground_y(pp)
	return pp

func _cam_goal(pp: Vector3, a: float) -> Array:
	var fwd := Vector3(sin(a), 0, -cos(a))
	var cp := pp - fwd * CAM_DIST + Vector3(0, CAM_H, 0)
	# keep the camera above hills behind the hero
	cp.y = maxf(cp.y, ground_y(cp) + 2.5)
	return [cp, pp + Vector3(0, 1.2, 0) + fwd * 1.8]

func _snap_cam() -> void:
	cam_a = cam_q * PI / 2.0
	var pp := _player_pos()
	var g := _cam_goal(pp, cam_a)
	cam_pos = g[0]
	cam.position = cam_pos
	if cam.is_inside_tree():
		cam.look_at(g[1], Vector3.UP)
	player.position = pp
	comp_pos = pp - Vector3(facing.x, 0, facing.y) * 1.5
	comp.position = comp_pos

func _update_view(d: float) -> void:
	var pp := _player_pos()
	player.position = pp
	var want_yaw := atan2(float(facing.x), float(facing.y))
	player.rotation.y = lerp_angle(player.rotation.y, want_yaw, 1.0 - exp(-d * 14.0))
	var walking := move_t >= 0.0
	Models.anim_person(player, t, walking)
	# a puff of dust at each footfall
	var sp := fmod(t * 9.0 / PI, 2.0)
	if walking and int(sp) != step_side:
		step_side = int(sp)
		Fx3D.dust(scene3d, pp, Color(Look.theme(theme_name).path))
	# companion trails the hero
	comp.visible = Game.companion
	if Game.companion:
		var back := pp - Vector3(facing.x, 0, facing.y) * 1.6 + Vector3(-facing.y, 0, facing.x) * 0.5
		comp_pos = comp_pos.lerp(back, 1.0 - exp(-d * 5.0))
		comp_pos.y = ground_y(comp_pos)
		comp.position = comp_pos
		var dv := pp - comp_pos
		if dv.length() > 0.3:
			comp.rotation.y = lerp_angle(comp.rotation.y, atan2(dv.x, dv.z), 1.0 - exp(-d * 8.0))
		Models.anim_person(comp, t + 1.0, dv.length() > 0.5)
	# entities
	var nodes: Array = cur_view.nodes
	for i in ents.size():
		var e: Dictionary = ents[i]
		var n: Node3D = nodes[i]
		var vis := ent_visible(e)
		n.visible = vis
		if not vis:
			continue
		var dist := n.position.distance_to(pp)
		if dist > 46.0:
			continue
		_animate_ent(e, n, pp, dist, d)
	weather.global_position = Vector3(pp.x, pp.y + weather_y(), pp.z)
	# chase camera
	cam_a = lerp_angle(cam_a, cam_q * PI / 2.0, 1.0 - exp(-d * 7.0))
	var g := _cam_goal(pp, cam_a)
	cam_pos = cam_pos.lerp(g[0], 1.0 - exp(-d * 9.0))
	cam.position = cam_pos
	cam.look_at(g[1], Vector3.UP)

func weather_y() -> float:
	match Look.theme(theme_name).weather:
		"snow", "rain", "petals", "leaves", "aurora_snow":
			return 12.0
		"bubbles", "bubbles_up", "embers", "sparks", "spores":
			return 0.3
		"sandstorm":
			return 1.5
		"clouds":
			return 1.0
		"lanterns":
			return 2.0
		_:
			return 3.5

func _animate_ent(e: Dictionary, n: Node3D, pp: Vector3, dist: float, d: float) -> void:
	match e.kind:
		"npc":
			var m: Node3D = n.get_meta("model")
			Models.anim_person(m, t + e.pos.x, false)
			if dist < 9.0:
				var dv := pp - n.position
				m.rotation.y = lerp_angle(m.rotation.y, atan2(dv.x, dv.z), 1.0 - exp(-d * 5.0))
			var s := Game.cur_step()
			var mark: Label3D = n.get_meta("mark")
			var quest: bool = not s.is_empty() and s.kind == "talk" and s.npc == e.id
			mark.visible = quest
			if quest:
				mark.position.y = 3.1 + sin(t * 4.0) * 0.15
		"enemy", "boss":
			var ms: Array = n.get_meta("models")
			for i in ms.size():
				Models.anim_monster(ms[i], t, i * 1.7 + e.pos.x)
			if dist < 10.0:
				var dv2 := pp - n.position
				n.rotation.y = lerp_angle(n.rotation.y, atan2(dv2.x, dv2.z), 1.0 - exp(-d * 2.0))
			var base_y := ground_y(n.position)
			n.position.y = base_y + sin(t * 2.2 + e.pos.x) * 0.06 + (0.35 if e.kind == "enemy" and Data.ENEMIES[e.group[0].id].shape in ["wisp", "jelly", "bird", "storm", "ray"] else 0.0)
		"pickup":
			var gm: Node3D = n.get_meta("gem")
			gm.position.y = 1.0 + sin(t * 2.0 + e.pos.y) * 0.18
			gm.rotation.y = t * 1.5
		"portal":
			var open: bool = e.open == "" or Game.done(e.open)
			var lbl: Label3D = n.get_meta("label")
			lbl.text = ("To " + Data.AREAS[e.to].n) if open else "Sealed"
			lbl.modulate = UI.C_JADE if open else Color("c06a6a")
			var pm: Node3D = n.get_meta("model")
			(pm.get_meta("ring") as Node3D).rotation.z = t * 0.8
			(pm.get_meta("swirl") as Node3D).rotation.z = -t * 1.6

# ---------------------------------------------------------------- 2D HUD overlay
func _draw() -> void:
	if grid.is_empty():
		return
	_draw_hud()

func _draw_hud() -> void:
	UI.panel(self, Rect2(12, 12, 330, 128))
	UI.text(self, Vector2(26, 38), "Lin Feng", 20, UI.C_GOLD)
	UI.text(self, Vector2(26, 58), Data.level_name(Game.level), 15, UI.C_TEXT)
	var need := Game.exp_need()
	if Game.level < Data.MAX_LEVEL:
		UI.bar(self, Rect2(26, 66, 300, 8), Game.exp / float(need), UI.C_GOLD)
	# the numbers get four digits late in the game: keep the bars clear of them
	UI.text(self, Vector2(26, 92), "HP %d/%d" % [Game.hp[0], Game.max_hp(0)], 14)
	UI.bar(self, Rect2(140, 80, 186, 10), Game.hp[0] / float(Game.max_hp(0)), UI.C_RED)
	UI.text(self, Vector2(26, 112), "QI %d/%d" % [Game.qi[0], Game.max_qi(0)], 14)
	UI.bar(self, Rect2(140, 100, 186, 10), Game.qi[0] / float(Game.max_qi(0)), UI.C_BLUE)
	UI.text(self, Vector2(26, 126), "Stones: %d" % Game.stones, 13, UI.C_DIM)
	# objective
	UI.panel(self, Rect2(VIEW.x - 520, 12, 508, 58))
	UI.text(self, Vector2(VIEW.x - 506, 34), "Objective", 13, UI.C_DIM)
	UI.text(self, Vector2(VIEW.x - 506, 56), Game.objective_text(), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 480)
	UI.text(self, Vector2(VIEW.x - 330, VIEW.y - 14), "Arrows/WASD move   Q/E camera   Z/Enter act   Esc menu", 13, UI.C_DIM)
	_draw_minimap()
	if banner_t > 0.0:
		var a := clampf(banner_t, 0.0, 1.0)
		UI.panel(self, Rect2(VIEW.x * 0.5 - 220, 96, 440, 52), Color(0.04, 0.06, 0.13, 0.85 * a), Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, a))
		UI.text(self, Vector2(VIEW.x * 0.5 - 220, 130), area_name, 26, Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, a), HORIZONTAL_ALIGNMENT_CENTER, 440)
	# interaction hint
	var fe = face_entity()
	if fe != null and move_t < 0.0 and fe.kind in ["npc", "boss"]:
		UI.text(self, Vector2(VIEW.x * 0.5 - 150, VIEW.y - 60), "Enter: " + ("Talk" if fe.kind == "npc" else "Challenge"), 20, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 300)
	# toasts
	var y := 170.0
	var i := 0
	for s in main.toast_list:
		UI.text(self, Vector2(VIEW.x * 0.5 - 300, y + i * 26), s.text, 18, Color(UI.C_JADE.r, UI.C_JADE.g, UI.C_JADE.b, clampf(s.t, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, 600)
		i += 1

func _draw_minimap() -> void:
	if mini_tex == null:
		return
	var mw := 190.0
	var r := Rect2(VIEW.x - mw - 16, 88, mw, mw * h / float(w))
	var marks: Array = []
	for e in ents:
		if not ent_visible(e):
			continue
		match e.kind:
			"portal":
				marks.append({"pos": e.pos, "col": UI.C_JADE})
			"npc":
				marks.append({"pos": e.pos, "col": UI.C_GOLD})
			"boss":
				marks.append({"pos": e.pos, "col": Color("ff3030")})
			"pickup":
				marks.append({"pos": e.pos, "col": Color("ffffff")})
	Gfx.draw_minimap(self, mini_tex, r, w, h, ptile, marks, t)
	UI.text(self, r.position + Vector2(0, r.size.y + 20), area_name, 12, UI.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, mw)
