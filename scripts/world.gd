extends ScreenBase
## Third-person 3D world: grid-based movement with a chase camera, entity models and the 2D HUD overlay.
## The whole game is one open world (see atlas.gd): the player walks from region to region along
## roads, and the 3D view streams each region's terrain in as the player nears it and drops it
## again far behind.  Buildings with doors can be walked into; the roof lifts away inside.

const TS := Terrain3D.T
const STEP_T := 0.16
const VIEW := Vector2(1280, 720)
## follow camera: behind and a little above the hero, looking past him down the road
const CAM_DIST := 6.8
const CAM_H := 4.3
const FWD := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const RIGHT := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const HERO_OPTS := {"asset": "lin_feng", "sword": true, "glow": Color(0.4, 0.7, 1.0), "hair": "topknot", "trim": Color("e8f0ff"), "cape": Color("2a5aa8")}
const YUE_OPTS := {"asset": "yue_ling", "ribbon": Color("ffb0cc"), "glow": Color(1.0, 0.6, 0.8), "hair": "long", "eyes": Color("c04080")}

var area_id := ""
var wd := {}
var tile_ents := {}
var ent_by_id := {}
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

# 3D state: one view per streamed region
var views := {}
var cur_view := {}
var stream_t := 0.0
var world_root: Node3D = null
var envs := {}
var inside := ""
var mini_rect := Rect2i()
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
## the movement key being held and the world direction it was given when first pressed: the
## direction stays fixed while the key is held, so the camera can swing round behind the hero
## without turning the walk with it
var held_key := -1
var held_dir := Vector2i.ZERO
## screenshot tour: a fixed wide establishing shot replaces the chase camera while set
var cam_override: Variant = null
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
	for k in views:
		_free_view(k)
	views.clear()
	cur_view = {}
	area_id = ""
	inside = ""

func _free_view(k: String) -> void:
	var v: Dictionary = views[k]
	v.root.queue_free()
	for i in v.nodes:
		v.nodes[i].queue_free()

## (Re)load the open world, if needed, and place the player on world tile `at`.
func open_world() -> void:
	if not wd.is_empty():
		return
	wd = Atlas.world()
	w = wd.w
	h = wd.h
	grid = wd.grid
	ents = wd.ents
	tile_ents.clear()
	ent_by_id.clear()
	for e in ents:
		ent_by_id[e.id] = e
		if e.kind == "seal":
			for t2 in e.tiles:
				tile_ents[t2] = e
		elif e.kind != "spring":
			tile_ents[e.pos] = e
	if not headless():
		hm = PackedFloat32Array()
		hm.resize((w + 1) * (h + 1))
		wd["hm"] = hm
		mini_tex = Gfx.world_minimap(wd)
		world_root = Node3D.new()
		world_root.name = "world_edge"
		Terrain3D.world_edge(world_root, w, h)
		scene3d.add_child(world_root)

## Teleport to a region-local tile (as written in Data.AREAS).
func load_area(id: String, at: Vector2i) -> void:
	teleport(Atlas.to_world(id, at))

func teleport(at: Vector2i) -> void:
	open_world()
	ptile = at
	target = at
	move_t = -1.0
	Game.tile = at
	_enter_region(Atlas.owner_id(wd, at), true)
	if not headless():
		_stream(true)
		_snap_cam()

func _enter_region(id: String, quiet: bool = false) -> void:
	if id == area_id:
		return
	area_id = id
	var spec: Dictionary = Data.AREAS[id]
	theme_name = spec.theme
	area_name = spec.n
	Game.area = id
	banner_t = 3.0
	if not quiet:
		Game.note("Entered " + area_name)
	if headless():
		return
	if not envs.has(theme_name):
		envs[theme_name] = Look.environment(theme_name)
	cam.environment = envs[theme_name]
	var th := Look.theme(theme_name)
	main.fx_theme(theme_name)
	Look.apply_lights(theme_name, sun, fill)
	Fx3D.configure_weather(weather, th.weather)

## Build the regions near the player and hide (eventually free) the ones far behind.
func _stream(all_now: bool) -> void:
	var near: Array = []
	for id in wd.ids:
		var c: Rect2i = wd.layout[id].cell
		var dx := maxi(maxi(c.position.x - ptile.x, ptile.x - c.end.x), 0)
		var dy := maxi(maxi(c.position.y - ptile.y, ptile.y - c.end.y), 0)
		var dd := maxi(dx, dy)
		if dd <= 46:
			near.append([dd, id])
		elif views.has(id):
			views[id].root.visible = false
			for i in views[id].nodes:
				views[id].nodes[i].visible = false
			views[id].shown = false
	near.sort()
	var built := 0
	for pr in near:
		var id: String = pr[1]
		if not views.has(id):
			if built > 0 and not all_now:
				continue
			_build_view(id)
			built += 1
		views[id].root.visible = true
		views[id].shown = true
	# keep memory bounded: drop the hidden regions furthest away
	if views.size() > 9:
		var far: Array = []
		for k in views:
			if not views[k].shown:
				var c2: Rect2i = wd.layout[k].cell
				far.append([-absf(c2.get_center().x - ptile.x) - absf(c2.get_center().y - ptile.y), k])
		far.sort()
		while views.size() > 9 and not far.is_empty():
			var k2: String = far.pop_front()[1]
			_free_view(k2)
			views.erase(k2)

func _build_view(id: String) -> void:
	var sl := Atlas.slice(wd, id)
	var r: Rect2i = sl.rect
	var shm := Terrain3D.world_heights(wd, r)
	var bl: Array = []
	for bd in wd.buildings:
		if bd.area == id:
			var lb: Dictionary = bd.duplicate(true)
			lb.rect = Rect2i(bd.rect.position - r.position, bd.rect.size)
			lb.door = bd.door - r.position
			var props: Array = []
			for pr in bd.props:
				props.append([pr[0], pr[1] - r.position, pr[2]])
			lb.props = props
			bl.append(lb)
	var spec: Dictionary = Data.AREAS[id]
	var root := Terrain3D.build(sl.grid, r.size.x, r.size.y, spec.theme, spec.seed, {"hm": shm, "open": true, "buildings": bl, "area": id})
	root.position = Vector3(r.position.x * TS, 0.0, r.position.y * TS)
	scene3d.add_child(root)
	var nodes := {}
	for i in ents.size():
		var e: Dictionary = ents[i]
		if e.area != id:
			continue
		var n := _make_ent(e)
		n.position.y = ground_y(n.position)
		scene3d.add_child(n)
		nodes[i] = n
	if id == "sect":
		var pg := Atlas.to_world("sect", Vector2i(-5, 3))
		var pp := Terrain3D.world_pos(pg)
		Terrain3D.pagoda(root, Vector3(pp.x, ground_y(pp) - 0.3, pp.z) - root.position)
	views[id] = {"root": root, "nodes": nodes, "shown": true, "roofs": root.get_meta("roofs", {})}

# ---------------------------------------------------------------- entities
func ent_visible(e: Dictionary) -> bool:
	match e.kind:
		"enemy":
			return not Game.defeated.has(e.id)
		"seal":
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
	var e = tile_ents.get(tile)
	if e == null or not ent_visible(e):
		return null
	if e.kind == "seal" and seal_open(e):
		return null
	return e

func seal_open(e: Dictionary) -> bool:
	return Game.done(e.open)

func tile_free(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= w or tile.y >= h:
		return false
	return MapGen.is_walkable_tile(grid[tile.y * w + tile.x])

## the building whose floor this tile is on ("" outdoors)
func building_at(tile: Vector2i) -> Dictionary:
	if grid.is_empty() or grid[tile.y * w + tile.x] != MapGen.INTERIOR:
		return {}
	for bd in wd.buildings:
		if bd.rect.has_point(tile):
			return bd
	return {}

func near_spring() -> bool:
	for e in ents:
		if e.kind == "spring" and e.area == area_id:
			if maxi(absi(e.pos.x - ptile.x), absi(e.pos.y - ptile.y)) <= 3:
				return true
	return false

func find_ent(id: String):
	return ent_by_id.get(id)

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
			return {"asset": id, "sword": true, "beard": true, "glow": Color(0.6, 0.85, 1.0), "hair": "topknot"}
		"dragon_envoy", "gate_keeper", "lake_keeper", "grave_keeper", "time_ferryman", "origin_keeper", "cloud_warden", "court_scribe":
			return {"asset": id, "staff": true, "glow": Color(1.0, 0.95, 0.7), "hair": "long" if id in ["lake_keeper", "court_scribe"] else "bun"}
		"forge_master":
			return {"asset": id, "sash": false, "hair": "wild", "armor": true, "metal": Color("b07a40"), "beard": true}
		"peach_keeper":
			return {"asset": id, "ribbon": Color("ffd0e0"), "hair": "long", "crown": true, "glow": Color(1.0, 0.8, 0.9)}
		"nomad", "spore_witch", "steppe_shaman", "nuwa_echo", "lantern_monk", "fisher", "meng_po", "judge_cui":
			return {"asset": id, "staff": true, "hair": "long", "glow": Color(1.0, 0.95, 0.8)}
		"archivist", "innkeeper":
			return {"asset": id, "beard": true, "hat": true, "hair": "bun"}
		"granny_wen", "weaver_liu", "can_niang":
			return {"asset": id, "hair": "long" if id != "granny_wen" else "bun", "staff": id == "granny_wen"}
		"tea_master":
			return {"asset": id, "beard": true, "hat": true, "staff": true, "hair": "bun"}
		"apprentice_zhi":
			return {"asset": id, "hair": "long", "crown": true, "glow": Color(1.0, 0.85, 0.95)}
		"fire_sage", "void_hermit":
			return {"asset": id, "beard": true, "hat": true, "hair": "bald"}
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
		"seal":
			var open: bool = seal_open(e)
			var pc := UI.C_JADE if open else Color("8a4a4a")
			var pm := Models.portal(pc, open)
			# a barrier across a north-south road faces along x
			var ts: Array = e.tiles
			if ts.size() > 1 and ts[0].x == ts[1].x:
				pm.rotation.y = PI / 2
			if not ts.is_empty():
				var mid := Vector3.ZERO
				for tt in ts:
					mid += Terrain3D.world_pos(tt)
				mid /= float(ts.size())
				n.position = Vector3(mid.x, 0, mid.z)
				pm.scale = Vector3(1.0, 1.0, 1.0) * maxf(1.0, ts.size() * 0.55)
			n.set_meta("open", open)
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
		if Game.playtime - Game.defeated[k] > 150.0:
			var e = find_ent(k)
			if e == null or maxi(absi(e.pos.x - ptile.x), absi(e.pos.y - ptile.y)) > 6:
				Game.defeated.erase(k)
	var active: bool = main.top_name() == "world"
	if active:
		if not main.bot_active:
			move_dir = _read_keys()
		_move(minf(d, 0.1))
	if not headless() and visible and not wd.is_empty():
		stream_t -= d
		if stream_t <= 0.0:
			stream_t = 0.35
			_stream(false)
		_update_view(d)
		queue_redraw()
	# scenery between the camera and the hero turns see-through (shader global, see mb.gd);
	# parked far away whenever the world is not the screen being shown
	if not headless():
		var hp := Vector3(0, -1000, 0)
		if active and visible and cam_override == null:
			hp = _player_pos() + Vector3(0, 1.0, 0)
		RenderingServer.global_shader_parameter_set("hero_pos", hp)

func rotate_cam(dir: int) -> void:
	cam_q = (cam_q + dir + 4) % 4

func _read_keys() -> Vector2i:
	var k := -1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		k = 0
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		k = 1
	elif Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		k = 2
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		k = 3
	if k < 0:
		held_key = -1
		return Vector2i.ZERO
	if k != held_key:
		# a new press is read relative to where the camera looks now
		var f: Vector2i = FWD[cam_q]
		var r: Vector2i = RIGHT[cam_q]
		held_key = k
		held_dir = [-r, r, f, -f][k]
	return held_dir

func _move(d: float) -> void:
	var budget := d
	while budget > 0.0001:
		if move_t < 0.0:
			if move_dir == Vector2i.ZERO:
				return
			facing = move_dir
			var nt := ptile + move_dir
			var e = ent_at(nt)
			if e != null:
				move_dir = Vector2i.ZERO
				main.interact(e)
				return
			if not tile_free(nt):
				return
			target = nt
			move_t = 0.0
			# third-person follow: the camera swings round behind the direction of travel
			var q := FWD.find(facing)
			if q >= 0:
				cam_q = q
		var need := (1.0 - move_t) * STEP_T
		if budget >= need:
			budget -= need
			ptile = target
			move_t = -1.0
			Game.tile = ptile
			var rid := Atlas.owner_id(wd, ptile)
			if rid != area_id:
				_enter_region(rid)
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
	return [cp, pp + Vector3(0, 1.4, 0) + fwd * 2.6]

func _snap_cam() -> void:
	cam_a = cam_q * PI / 2.0
	var pp := _player_pos()
	var g := _cam_goal(pp, cam_a)
	cam_pos = g[0]
	cam.position = cam_pos
	if cam.is_inside_tree():
		cam.look_at(g[1], Vector3.UP)
	player.position = pp
	comp_pos = pp - Vector3(facing.x, 0, facing.y) * 0.7 + Vector3(-facing.y, 0, facing.x) * 1.4
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
		# off the hero's shoulder rather than straight behind, so she never stands between the
		# follow camera and him
		var back := pp - Vector3(facing.x, 0, facing.y) * 0.7 + Vector3(-facing.y, 0, facing.x) * 1.4
		comp_pos = comp_pos.lerp(back, 1.0 - exp(-d * 5.0))
		comp_pos.y = ground_y(comp_pos)
		comp.position = comp_pos
		var dv := pp - comp_pos
		if dv.length() > 0.3:
			comp.rotation.y = lerp_angle(comp.rotation.y, atan2(dv.x, dv.z), 1.0 - exp(-d * 8.0))
		Models.anim_person(comp, t + 1.0, dv.length() > 0.5)
	# entities of the regions on show
	for k in views:
		var v: Dictionary = views[k]
		if not v.shown:
			continue
		for i in v.nodes:
			var e: Dictionary = ents[i]
			var n: Node3D = v.nodes[i]
			var vis := ent_visible(e)
			n.visible = vis
			if not vis:
				continue
			var dist := n.position.distance_to(pp)
			if dist > 46.0:
				continue
			_animate_ent(e, n, pp, dist, d)
	# inside a building the roof lifts away so the follow camera can look in
	var bd := building_at(ptile if move_t < 0.0 or move_t > 0.5 else target)
	var now_in: String = bd.get("id", "") if not bd.is_empty() else ""
	if now_in != inside:
		for k2 in views:
			var roofs: Dictionary = views[k2].roofs
			for rid in roofs:
				for rn in roofs[rid]:
					(rn as Node3D).visible = rid != now_in
		inside = now_in
	weather.global_position = Vector3(pp.x, pp.y + weather_y(), pp.z)
	# chase camera
	cam_a = lerp_angle(cam_a, cam_q * PI / 2.0, 1.0 - exp(-d * 4.5))
	var g := _cam_goal(pp, cam_a)
	cam_pos = cam_pos.lerp(g[0], 1.0 - exp(-d * 9.0))
	cam.position = cam_pos
	cam.look_at(g[1], Vector3.UP)
	if cam_override != null:
		cam.global_transform = cam_override

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
		"seal":
			var open: bool = seal_open(e)
			var lbl: Label3D = n.get_meta("label")
			lbl.text = Data.AREAS[e.to].n if open else "Lotus Seal"
			lbl.modulate = UI.C_JADE if open else Color("c06a6a")
			if open != n.get_meta("open"):
				# the barrier dissolves into an open gateway once the story opens the road
				var old: Node3D = n.get_meta("model")
				var pm2 := Models.portal(UI.C_JADE if open else Color("8a4a4a"), open)
				pm2.transform = old.transform
				old.queue_free()
				n.add_child(pm2)
				n.set_meta("model", pm2)
				n.set_meta("open", open)
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
	var mh := 120.0
	var r := Rect2(VIEW.x - mw - 16, 88, mw, mh)
	# a window of the world map centred on the player
	var span := Vector2(96, 96 * mh / mw)
	var o := Vector2(ptile) - span * 0.5
	o.x = clampf(o.x, 0.0, w - span.x)
	o.y = clampf(o.y, 0.0, h - span.y)
	var src := Rect2(o, span)
	draw_rect(r.grow(4), Color(0.02, 0.03, 0.08, 0.85))
	draw_rect(r.grow(4), UI.C_BORDER, false, 2.0)
	draw_texture_rect_region(mini_tex, r, src, Color(1, 1, 1, 0.92))
	var sc := r.size / span
	for e in ents:
		if not src.has_point(Vector2(e.pos)) or not ent_visible(e):
			continue
		var col := Color.TRANSPARENT
		match e.kind:
			"seal":
				col = UI.C_JADE if seal_open(e) else Color("ff6060")
			"npc":
				col = UI.C_GOLD
			"boss":
				col = Color("ff3030")
			"pickup":
				col = Color("ffffff")
		if col.a > 0.0:
			draw_circle(r.position + (Vector2(e.pos) - o + Vector2(0.5, 0.5)) * sc, 2.4, col)
	var pp := r.position + (Vector2(ptile) - o + Vector2(0.5, 0.5)) * sc
	draw_circle(pp, 4.5 + sin(t * 5.0), Color(1, 1, 1, 0.35))
	draw_circle(pp, 2.6, Color("5aa9ff"))
	var here := area_name
	if inside != "":
		here = building_at(ptile).get("n", area_name)
	UI.text(self, r.position + Vector2(0, r.size.y + 20), here, 12, UI.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, mw)
