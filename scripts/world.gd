extends ScreenBase
## Third-person 3D world: grid-based movement with a chase camera, entity models and the 2D HUD overlay.
## The whole game is one open world (see atlas.gd): the player walks from region to region along
## roads, and the 3D view streams each region's terrain in as the player nears it and drops it
## again far behind.  Buildings with doors can be walked into; the roof lifts away inside.
##
## Part XI stacks realms on the land: the Nine Heavens float 96 m above it and the Nine Springs lie
## 64 m below it, each a world of its own (Atlas.world_of) laid at its own offset (`off`), joined to
## the land by the Jianmu; upper storeys and cellars are small worlds too, joined by stairs.  The
## hero is always in exactly one of them (`layer`): `wd`, `grid`, `ents` and the rest point at its
## data (`bundles`), the 3D view shows its regions (or, upstairs, the land round the building; in a
## cellar, only the cellar), and a ladder or a flight of stairs is a short trip between two of them.

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
var comp_run := false  # is Yue Ling running to keep up (rather than standing beside the hero)?
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
## the realm (or floor) the hero is in, every realm's data and 3D offset, and a trip between two of
## them while one is under way ({t, dur, to_layer, to_tile, dir, climb, swapped})
var layer := "surface"
var bundles := {}
var off := Vector3.ZERO
var trip := {}
var banner_text := ""
var cellar_env: Environment = null
## Part XII cutscenes: the line of dialogue last acted out, the last person who spoke to Lin Feng, and
## the conversation camera (how far it has blended in from the chase camera, where it is, its slow
## drift during narration)
var cue_lines: Array = []
var cue_idx := -1
var cue_npc := ""
var cine_k := 0.0
var cine_pos := Vector3.ZERO
var cine_a := 0.0

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
	trip = {}

func _free_view(k: String) -> void:
	var v: Dictionary = views[k]
	v.root.queue_free()
	for i in v.nodes:
		v.nodes[i].queue_free()

## (Re)load the open world, if needed (the land first; the realms above and below and the floors of
## buildings are built the first time they are needed).
func open_world() -> void:
	if not wd.is_empty():
		return
	_use("surface")

## A realm's data, built the first time it is asked for: its world, its entities by tile and by id,
## where it is drawn, its height field and its minimap, and the dressing that goes round it (the sea
## round the land, the sea of clouds under the Nine Heavens, the abyss and the cavern roof of the
## Nine Springs).
func _bundle(lid: String) -> Dictionary:
	if bundles.has(lid):
		return bundles[lid]
	var lw: Dictionary = Atlas.world_of(lid)
	var b := {"wd": lw, "tile_ents": {}, "ent_by_id": {}, "off": Vector3.ZERO, "hm": PackedFloat32Array(), "mini": null, "root": null, "placed": false}
	for e in lw.ents:
		b.ent_by_id[e.id] = e
		if e.kind == "seal":
			for t2 in e.tiles:
				b.tile_ents[t2] = e
		elif e.kind != "spring":
			b.tile_ents[e.pos] = e
	var floor: bool = lw.get("kind", "") == "floor"
	if floor:
		var pb := _bundle(str(lw.parent))
		b.off = pb.off + Vector3(lw.origin.x * TS, 0.0, lw.origin.y * TS)
	else:
		var o: Vector2i = lw.get("origin", Vector2i.ZERO)
		b.off = Vector3(o.x * TS, float(lw.get("y", 0.0)), o.y * TS)
	bundles[lid] = b
	if not headless():
		b.hm.resize((lw.w + 1) * (lw.h + 1))
		if not floor:
			lw["hm"] = b.hm
			b.mini = Gfx.world_minimap(lw)
			var root := Node3D.new()
			root.name = "realm_" + lid
			root.position = b.off
			match lid:
				"surface":
					Terrain3D.world_sea(root, lw)
				"heaven":
					Terrain3D.sky_world(root, lw)
				"under":
					Terrain3D.deep_world(root, lw)
				"sea":
					# the Eastern Sea (Part XII): real sea round the isles, the same ocean as the land's
					Terrain3D.world_sea(root, lw)
			root.visible = false
			scene3d.add_child(root)
			b.root = root
			if lid == "surface":
				world_root = root
	return b

## Make realm `lid` the one the hero is in.
func _use(lid: String) -> void:
	var b := _bundle(lid)
	layer = lid
	wd = b.wd
	w = wd.w
	h = wd.h
	grid = wd.grid
	ents = wd.ents
	tile_ents = b.tile_ents
	ent_by_id = b.ent_by_id
	hm = b.hm
	off = b.off
	mini_tex = b.mini
	if is_floor():
		mini_tex = _bundle(str(wd.parent)).mini
		_place_floor(b)
	Game.layer = lid

func is_floor() -> bool:
	return wd.get("kind", "") == "floor"

## Switch to realm (or floor) `lid` without moving the hero (the screenshot tour looks for a free tile
## in it before teleporting there).
func enter_layer(lid: String) -> void:
	open_world()
	_use(lid)

## The minimap of a realm (built the first time it is asked for; null when headless).
func realm_minimap(lid: String) -> Texture2D:
	return _bundle(lid).mini

## An upper storey stands on the building's walls, a cellar lies under its floor: set the floor's
## height from the ground under the building (once the land round it has been built).
func _place_floor(b: Dictionary) -> void:
	var fw: Dictionary = b.wd
	var pb := _bundle(str(fw.parent))
	var po: Vector3 = pb.off
	var c := po + Vector3((fw.origin.x + fw.w * 0.5) * TS, 0.0, (fw.origin.y + fw.h * 0.5) * TS)
	var gy := _ground(pb, c)
	b.off.y = gy + (Arch.STOREY_Y if int(fw.level) > 0 else Arch.CELLAR_Y)
	off = b.off
	b.placed = true

## The realm whose regions the 3D view shows: upstairs, the land round the building; in a cellar,
## none (only the cellar itself).
func _view_layer() -> String:
	if is_floor():
		return str(wd.parent) if int(wd.level) > 0 else ""
	return layer

## The hero's tile in the tiles of the realm whose regions are on show.
func view_tile() -> Vector2i:
	if is_floor():
		return wd.origin + ptile
	return ptile

## The realm a region lies in, and whether a ladder or flight of stairs can be used yet.
func ladder_open(e: Dictionary) -> bool:
	return Game.done(str(e.get("open", "")))

## Teleport to a region-local tile (as written in Data.AREAS), in whichever realm the region lies.
func load_area(id: String, at: Vector2i) -> void:
	teleport(Atlas.to_world(id, at), Data.layer_of(id))

func teleport(at: Vector2i, lid: String = "") -> void:
	open_world()
	if lid == "":
		lid = layer
	_use(lid)
	ptile = at
	target = at
	move_t = -1.0
	Game.tile = at
	_enter_region(Atlas.owner_id(wd, at), true)
	if not headless():
		_show_layer()
		_stream(true)
		_snap_cam()

## Take a ladder or a flight of stairs: a short trip (the hero rises or sinks out of view, the screen
## fades, and he comes down into the other realm or floor).
func use_ladder(e: Dictionary) -> void:
	if not trip.is_empty():
		return
	var climb: bool = str(e.get("style", "")) == "climb"
	# Mazu's boat (Part XII): a long trip like the Jianmu's, but over the water, not up or down it
	var sail: bool = str(e.get("style", "")) == "sail"
	trip = {"t": 0.0, "dur": 2.6 if climb or sail else 0.7, "to_layer": str(e.to_layer), "to_tile": e.to_tile, "dir": int(e.get("dir", 1)), "climb": climb or sail, "sail": sail, "swapped": false}
	move_dir = Vector2i.ZERO
	if sail:
		Game.note("Sailed with Mazu to " + ("the Isles of the Eastern Sea" if str(e.to_layer) == "sea" else "Fusang"))
	elif climb:
		var verb := "Climbed the Jianmu into " if int(e.get("dir", 1)) > 0 else "Went down the Jianmu into "
		Game.note(verb + str(Atlas.LAYER_NAMES.get(str(e.to_layer), str(e.to_layer))).replace("The ", "the "))

func traveling() -> bool:
	return not trip.is_empty()

func _trip_step(d: float) -> void:
	trip.t += d
	if not trip.swapped and trip.t >= trip.dur * 0.5:
		trip.swapped = true
		var fc := facing
		teleport(trip.to_tile, trip.to_layer)
		facing = fc
		if is_floor():
			banner_text = "%s: %s" % [wd.bld_n, wd.floor_n] if str(wd.floor_n) != "" else str(wd.bld_n)
			banner_t = 2.5
		elif trip.climb:
			banner_text = "%s - %s" % [Atlas.LAYER_NAMES.get(layer, ""), area_name]
			banner_t = 3.0
	if trip.t >= trip.dur:
		trip = {}

## How far the hero has risen (or sunk) on a trip: away from the floor he left in the first half, then
## down onto the new one from above in the second.
func _trip_lift() -> float:
	if trip.is_empty():
		return 0.0
	var k: float = trip.t / trip.dur
	if trip.get("sail", false):
		return 0.0
	var amp := 26.0 if trip.climb else 1.2
	if k < 0.5:
		return float(trip.dir) * amp * smoothstep(0.0, 0.5, k)
	return amp * (1.0 - smoothstep(0.5, 1.0, k))

## How much of the screen the trip's fade covers (it peaks as the realms change over).
func trip_fade() -> float:
	if trip.is_empty():
		return 0.0
	var k: float = trip.t / trip.dur
	return pow(clampf(1.0 - absf(k - 0.5) * 2.2, 0.0, 1.0), 0.6)

## An entity by id in any realm or floor (building the realm if need be): [layer, entity] or [].
func locate_ent(id: String) -> Array:
	var e = ent_by_id.get(id)
	if e != null:
		return [layer, e]
	for lid in ["surface", "heaven", "under", "sea"]:
		var lw: Dictionary = Atlas.world_of(lid)
		for e2 in lw.ents:
			if e2.id == id:
				return [lid, e2]
		for fid in lw.floors:
			for e3 in lw.floors[fid].ents:
				if e3.id == id:
					return [fid, e3]
	return []

func _enter_region(id: String, quiet: bool = false) -> void:
	if id == area_id:
		return
	area_id = id
	var spec: Dictionary = Data.AREAS[id]
	theme_name = spec.theme
	area_name = spec.n
	Game.area = id
	Game.seen[id] = true
	banner_t = 3.0
	if not quiet:
		Game.note("Entered " + area_name)
	if headless():
		return
	_apply_look()

## The region's sky, fog, light and weather (a cellar has its own dark air, see _show_layer).
func _apply_look() -> void:
	if headless():
		return
	if is_floor() and int(wd.level) < 0:
		if cellar_env == null:
			cellar_env = Look.cellar_environment()
		cam.environment = cellar_env
		Fx3D.configure_weather(weather, "none")
		return
	if not envs.has(theme_name):
		envs[theme_name] = Look.environment(theme_name)
	cam.environment = envs[theme_name]
	var th := Look.theme(theme_name)
	main.fx_theme(theme_name)
	Look.apply_lights(theme_name, sun, fill)
	# upstairs is indoors: no rain, snow or drifting cloud in the room
	Fx3D.configure_weather(weather, "none" if is_floor() else th.weather)

## Show the realm the hero is in and hide the others; build the floor's own view when on a floor.
func _show_layer() -> void:
	var vl := _view_layer()
	for lid in bundles:
		var bb: Dictionary = bundles[lid]
		if bb.root != null:
			(bb.root as Node3D).visible = lid == vl
	if is_floor() and not views.has(layer):
		_floor_view(layer)
	for k in views:
		var v: Dictionary = views[k]
		var on: bool = v.layer == vl or k == layer
		(v.root as Node3D).visible = on
		v.shown = on
		if not on:
			for i in v.nodes:
				v.nodes[i].visible = false
	_apply_look()

## Build the regions near the player and hide (eventually free) the ones far behind.  Only the regions
## of the realm on show are streamed; a floor's own view is built when it is entered.
func _stream(all_now: bool) -> void:
	var near: Array = []
	var vl := _view_layer()
	var vt := view_tile()
	var ids: Array = []
	if vl != "":
		ids = _bundle(vl).wd.ids
	for k0 in views:
		if views[k0].layer != vl and k0 != layer and views[k0].shown:
			views[k0].root.visible = false
			for i0 in views[k0].nodes:
				views[k0].nodes[i0].visible = false
			views[k0].shown = false
	for id in ids:
		var c: Rect2i = Atlas.layout()[id].cell
		var dx := maxi(maxi(c.position.x - vt.x, vt.x - c.end.x), 0)
		var dy := maxi(maxi(c.position.y - vt.y, vt.y - c.end.y), 0)
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
	if views.size() > 10:
		var far: Array = []
		for k in views:
			if not views[k].shown and not str(k).begins_with("f:"):
				var c2: Rect2i = Atlas.layout()[k].cell
				far.append([-absf(c2.get_center().x - vt.x) - absf(c2.get_center().y - vt.y), k])
			elif not views[k].shown:
				far.append([-1e9, k])
		far.sort()
		while views.size() > 10 and not far.is_empty():
			var k2: String = far.pop_front()[1]
			_free_view(k2)
			views.erase(k2)

## Ground height at a point of realm bundle `bb` (world coordinates).
func _ground(bb: Dictionary, p: Vector3) -> float:
	var bw: Dictionary = bb.wd
	return Terrain3D.sample(bb.hm, bw.w, bw.h, p.x - bb.off.x, p.z - bb.off.z) + bb.off.y

## The height of the floorboards under a tile inside a building of realm bundle `bb` (or -INF if the
## tile is not indoors).  A building's floor is a plank platform on the ground under its middle
## (Arch.house): everyone indoors stands on the planks, not on the ground under them (they used to
## stand 0.3 m deep in the floor).
func _indoor_y(tile: Vector2i, bb: Dictionary) -> float:
	var bw: Dictionary = bb.wd
	if bw.get("kind", "") == "floor" or tile.x < 0 or tile.y < 0 or tile.x >= bw.w or tile.y >= bw.h:
		return -INF
	if bw.grid[tile.y * bw.w + tile.x] != MapGen.INTERIOR:
		return -INF
	for bd in bw.buildings:
		var r: Rect2i = bd.rect
		if r.has_point(tile):
			var o: Vector3 = bb.off
			var c := o + Vector3((r.position.x + r.size.x * 0.5) * TS, 0.0, (r.position.y + r.size.y * 0.5) * TS)
			return _ground(bb, c) + Arch.FLOOR_Y
	return -INF

## Where someone stands at a point of realm bundle `bb`: on the floorboards indoors, else the ground.
func _stand_y(bb: Dictionary, p: Vector3) -> float:
	var o: Vector3 = bb.off
	var iy := _indoor_y(Vector2i(int(floor((p.x - o.x) / TS)), int(floor((p.z - o.z) / TS))), bb)
	return iy if iy > -INF else _ground(bb, p)

## The centre of a tile of the realm the hero is in, in the 3D world.
func wpos(tile: Vector2i) -> Vector3:
	return Terrain3D.world_pos(tile) + off

func _build_view(id: String) -> void:
	var lid := Data.layer_of(id)
	var bb := _bundle(lid)
	var lw: Dictionary = bb.wd
	var sl := Atlas.slice(lw, id)
	var r: Rect2i = sl.rect
	var shore := {}
	var shm := Terrain3D.world_heights(lw, r, shore)
	var bl: Array = []
	for bd in lw.buildings:
		if bd.area == id:
			var lb: Dictionary = bd.duplicate(true)
			lb.rect = Rect2i(bd.rect.position - r.position, bd.rect.size)
			lb.door = bd.door - r.position
			var props: Array = []
			for pr in bd.props:
				props.append([pr[0], pr[1] - r.position, pr[2]])
			# the stairs up and down are drawn with the building
			if bd.has("up"):
				lb.up = bd.up - r.position
				props.append(["stairs_up", lb.up, false])
				var uprops: Array = []
				for pr2 in bd.upper.props:
					uprops.append([pr2[0], pr2[1] - r.position, pr2[2]])
				uprops.append(["stairs_hole", lb.up, false])
				lb.upper = {"n": bd.upper.n, "props": uprops}
			if bd.has("down"):
				lb.down = bd.down - r.position
				props.append(["stairs_down", lb.down, false])
			lb.props = props
			bl.append(lb)
	var spec: Dictionary = Data.AREAS[id]
	var root := Terrain3D.build(sl.grid, r.size.x, r.size.y, spec.theme, spec.seed, {"hm": shm, "shore": shore, "open": true, "buildings": bl, "area": id})
	root.position = Vector3(r.position.x * TS, 0.0, r.position.y * TS) + bb.off
	scene3d.add_child(root)
	var nodes := {}
	for i in lw.ents.size():
		var e: Dictionary = lw.ents[i]
		if e.area != id:
			continue
		var n := _make_ent(e, bb.off)
		n.position.y = _stand_y(bb, n.position)
		scene3d.add_child(n)
		nodes[i] = n
	if id == "sect":
		var pg := Atlas.to_world("sect", Vector2i(-5, 3))
		var pp := Terrain3D.world_pos(pg)
		Terrain3D.pagoda(root, Vector3(pp.x, _ground(bb, pp) - 0.3, pp.z) - root.position)
	if spec.has("landmark"):
		# the Fusang mulberry (Part IX); the Dragon Gate, the great cauldron and the broken pillar of
		# Buzhou (Part X); the Jianmu, its crown and its roots, the Gate of Heaven and the gate of
		# Youdu (Part XI)
		var boff: Vector3 = bb.off
		var fp := Terrain3D.world_pos(Atlas.to_world(id, spec.landmark.pos)) + boff
		var ax := Atlas.dir_to_world(id, Vector2i(1, 0))
		Terrain3D.landmark(root, spec.landmark.kind, Vector3(fp.x, _ground(bb, fp), fp.z) - root.position, Vector3(ax.x, 0, ax.y))
	views[id] = {"root": root, "nodes": nodes, "shown": true, "roofs": root.get_meta("roofs", {}), "uppers": root.get_meta("uppers", {}), "layer": lid, "ents": lw.ents, "bundle": lid}

## A floor's own view: its people and things (an upper storey is drawn with its building; a cellar
## is built here, under the building).
func _floor_view(fid: String) -> void:
	var bb := _bundle(fid)
	var fw: Dictionary = bb.wd
	var root := Node3D.new()
	root.name = "floor_" + fid
	root.position = bb.off
	scene3d.add_child(root)
	if int(fw.level) < 0:
		Terrain3D.cellar(root, fw)
	var nodes := {}
	for i in fw.ents.size():
		var n := _make_ent(fw.ents[i], bb.off)
		n.position.y = bb.off.y
		scene3d.add_child(n)
		nodes[i] = n
	views[fid] = {"root": root, "nodes": nodes, "shown": true, "roofs": {}, "uppers": {}, "layer": fid, "ents": fw.ents, "bundle": fid}

# ---------------------------------------------------------------- entities
func ent_visible(e: Dictionary) -> bool:
	match e.kind:
		"enemy":
			return not Game.defeated.has(e.id)
		"seal", "ladder", "abode":
			return true
		"boss":
			return not Game.boss_done.has(e.enemy)
		"pickup":
			if Game.taken.has(e.id):
				return false
			# a cache only Spirit Sense can feel (Part XII)
			if e.get("sense", false) and Game.talent("spirit_sense") < 1:
				return false
		"portal":
			return true
	var v = e.get("vis", ["", ""])
	if v[0] != "" and not Game.reached(v[0]):
		return false
	if v[1] != "" and Game.done(v[1]):
		return false
	# someone who is away for a while (Archivist Lan, down in the Sealed Archive)
	var hd = e.get("hide", [])
	if not hd.is_empty() and Game.reached(hd[0]) and not Game.done(hd[1]):
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

## The tile a pickup, ladder or anyone else stands on, as a 3D position in its own realm.
func ent_pos(e: Dictionary) -> Vector3:
	return Terrain3D.world_pos(e.pos) + off

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
		# Part VIII's people had no entry here, so the world drew them with the procedural stand-in
		"niu_lang", "que_lao", "zhi_nu", "dong_shuang":
			return {"asset": id, "hair": "long" if id in ["zhi_nu", "dong_shuang"] else "bun", "beard": id == "que_lao", "staff": id == "que_lao", "hat": id == "niu_lang"}
		# ---- Part IX
		"ah_mei", "chang_e":
			return {"asset": id, "hair": "long", "ribbon": Color("ffd0a0") if id == "ah_mei" else Color("e8f0ff"), "glow": Color(0.85, 0.9, 1.0) if id == "chang_e" else Color(1.0, 0.75, 0.4)}
		"farmer_tian", "feng_meng":
			return {"asset": id, "beard": true, "hat": id == "farmer_tian", "hair": "bun"}
	if Assets.PEOPLE.has(id):
		return {"asset": id}
	return {}

func _make_ent(e: Dictionary, at: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = Terrain3D.world_pos(e.pos) + at
	n.visible = false
	match e.kind:
		"npc":
			# (someone who appears in two places shares one model: "asset")
			var m := Models.person(e.col, Color("2a2a3a"), _npc_opts(str(e.get("asset", e.id))))
			n.add_child(m)
			n.add_child(Models.shadow_disc(0.6))
			_label(n, e.n, 2.45, UI.C_GOLD)
			var mark := _label(n, "!", 3.1, Color("ffdc50"), 72)
			n.set_meta("model", m)
			n.set_meta("mark", mark)
		"enemy":
			var g: Array = e.group
			var d: Dictionary = Data.ENEMIES[g[0].id]
			var m0 := Models.monster(d.shape, d.col, false, g[0].id)
			n.add_child(m0)
			var models := [m0]
			for k in range(1, mini(g.size(), 3)):
				var d2: Dictionary = Data.ENEMIES[g[k].id]
				var mk := Models.monster(d2.shape, d2.col, false, g[k].id)
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
			var mb := Models.monster(d3.shape, d3.col, true, e.enemy)
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
			# the barrier stands across the road: turned a quarter when the road runs east-west
			var ax: Vector2i = e.get("axis", Vector2i(0, 1))
			if absi(ax.x) > absi(ax.y):
				pm.rotation.y = PI / 2
			var ts: Array = e.tiles
			if not ts.is_empty():
				var mid := Vector3.ZERO
				for tt in ts:
					mid += Terrain3D.world_pos(tt)
				mid /= float(ts.size())
				n.position = Vector3(mid.x, 0, mid.z) + at
				pm.scale = Vector3(1.6, 1.6, 1.6)
			n.set_meta("open", open)
			n.add_child(pm)
			var lbl := _label(n, "", 4.1, pc, 32)
			n.set_meta("label", lbl)
			n.set_meta("model", pm)
		"spring":
			n.add_child(Models.spring_basin())
		"ladder":
			# the way up or down the Jianmu, or a flight of stairs (the building draws the stairs; a
			# glowing mark on the floor shows where they are)
			var lm := Models.ladder(str(e.get("style", "")), int(e.get("dir", 1)))
			n.add_child(lm)
			n.set_meta("model", lm)
			var ll := _label(n, str(e.get("n", "")), 2.6 if str(e.get("style", "")) == "climb" else 1.6, Color("a8e0ff") if int(e.get("dir", 1)) < 0 else UI.C_GOLD, 30 if str(e.get("style", "")) == "climb" else 24)
			n.set_meta("label", ll)
		"stele":
			var sm := Models.dao_stele()
			n.add_child(sm)
			n.add_child(Models.shadow_disc(0.7))
			_label(n, "Dao Stele", 3.0, UI.C_JADE, 30)
			n.set_meta("model", sm)
		"abode":
			# one of the Founder's sealed caves (Part XII): the realm that opens it is on the label
			var opened: bool = Game.abodes.has(e.id)
			var cm := Models.sealed_cave(opened)
			n.add_child(cm)
			n.set_meta("model", cm)
			n.set_meta("open", opened)
			_label(n, "%s (%s)" % [e.n, Data.REALMS[Data.realm_of(int(e.req))]], 3.4, UI.C_GOLD, 28)
			n.rotation.y = PI
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
	if not trip.is_empty():
		# on a ladder or the stairs: no walking until the trip is over
		_trip_step(d)
	elif active:
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
	return Terrain3D.sample(hm, w, h, p.x - off.x, p.z - off.z) + off.y

func _player_pos() -> Vector3:
	var pp := wpos(ptile)
	if move_t >= 0.0:
		pp = pp.lerp(wpos(target), move_t)
	# indoors on the floorboards (a step up over the threshold), else on the ground
	var bb: Dictionary = bundles[layer]
	var iy0 := _indoor_y(ptile, bb)
	var iy1 := _indoor_y(target, bb) if move_t >= 0.0 else iy0
	var gy := ground_y(pp)
	pp.y = lerpf(maxf(iy0, gy) if iy0 > -INF else gy, maxf(iy1, gy) if iy1 > -INF else gy, clampf(move_t, 0.0, 1.0)) + _trip_lift()
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
	comp.rotation.y = atan2(float(facing.x), float(facing.y))
	comp_run = false

func _update_view(d: float) -> void:
	var pp := _player_pos()
	player.position = pp
	var want_yaw := atan2(float(facing.x), float(facing.y))
	player.rotation.y = lerp_angle(player.rotation.y, want_yaw, 1.0 - exp(-d * 14.0))
	var walking := move_t >= 0.0
	# on the road the hero runs (the light-body dash; the old walk cycle slid along at 12 m/s); in a
	# conversation whoever is speaking talks with their hands and mouth
	Models.anim_person(player, t, walking, false, "run" if walking else ("talk" if speaker() == "Lin Feng" else ""))
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
		var cs: Array = Models.companion_step(comp_pos, pp, facing, want_yaw, comp_run, speaker() != "", d)
		comp_pos = cs[0]
		comp_pos.y = _stand_y(bundles[layer], comp_pos)
		comp.position = comp_pos
		comp_run = cs[2]
		comp.rotation.y = lerp_angle(comp.rotation.y, cs[1], 1.0 - exp(-d * 10.0))
		Models.anim_person(comp, t + 1.0, comp_run, false, "run" if comp_run else ("talk" if speaker() == "Yue Ling" else ""))
	# entities of the regions on show
	for k in views:
		var v: Dictionary = views[k]
		if not v.shown:
			continue
		var vb: Dictionary = bundles[v.bundle]
		for i in v.nodes:
			var e: Dictionary = v.ents[i]
			var n: Node3D = v.nodes[i]
			var vis := ent_visible(e)
			n.visible = vis
			if not vis:
				continue
			var dist := n.position.distance_to(pp)
			if dist > 46.0:
				continue
			_animate_ent(e, n, pp, dist, d, vb)
	# inside a building the roof lifts away so the follow camera can look in; on the ground floor of a
	# building with an upper storey the storey lifts away too, and upstairs only the roof does
	var key := ""
	if is_floor():
		key = "%s#%d" % [wd.bld, int(wd.level)]
	else:
		var bd := building_at(ptile if move_t < 0.0 or move_t > 0.5 else target)
		key = (str(bd.id) + "#0") if not bd.is_empty() else ""
	if key != inside:
		var bid := key.get_slice("#", 0)
		var lv := int(key.get_slice("#", 1)) if key != "" else 0
		for k2 in views:
			var roofs: Dictionary = views[k2].roofs
			for rid in roofs:
				for rn in roofs[rid]:
					(rn as Node3D).visible = rid != bid
			var ups: Dictionary = views[k2].get("uppers", {})
			for uid in ups:
				for un in ups[uid]:
					(un as Node3D).visible = not (uid == bid and lv == 0)
		inside = key
	weather.global_position = Vector3(pp.x, pp.y + weather_y(), pp.z)
	# chase camera
	cam_a = lerp_angle(cam_a, cam_q * PI / 2.0, 1.0 - exp(-d * 4.5))
	var g := _cam_goal(pp, cam_a)
	cam_pos = cam_pos.lerp(g[0], 1.0 - exp(-d * 9.0))
	cam.position = cam_pos
	cam.look_at(g[1], Vector3.UP)
	_cutscene(d, pp)
	if cam_override != null:
		cam.global_transform = cam_override

func weather_y() -> float:
	match Look.theme(theme_name).weather:
		"snow", "rain", "petals", "leaves", "aurora_snow", "osmanthus":
			return 12.0
		"bubbles", "bubbles_up", "embers", "sparks", "spores", "steam", "heat_haze":
			return 0.3
		"sandstorm":
			return 1.5
		"clouds":
			return 1.0
		"lanterns":
			return 2.0
		_:
			return 3.5

# ---------------------------------------------------------------- cutscenes (Part XII)
## The model of somebody taking part in a conversation by name, and the clock it is animated on:
## [model, clock offset] or [] if they are not here.
func _actor(who: String) -> Array:
	if who == "Lin Feng":
		return [player, 0.0]
	if who == "Yue Ling":
		return [comp, 1.0] if Game.companion else []
	var pp := _player_pos()
	for k in views:
		var v: Dictionary = views[k]
		if not v.shown:
			continue
		for i in v.nodes:
			var e: Dictionary = v.ents[i]
			if e.kind == "npc" and str(e.n) == who:
				var n: Node3D = v.nodes[i]
				if n.visible and n.position.distance_to(pp) < 16.0:
					return [n.get_meta("model"), float(e.pos.x)]
	return []

## A new line of dialogue begins: whoever it belongs to plays the gesture it calls for (Data.emote_for),
## and whoever is listening answers it (a bow for a gift, a wave for a wave, a nod for grief or a joke).
func _cue_line(line: Array) -> void:
	var ec: Array = Data.emote_for(line)
	var who: String = ec[0]
	var g: String = ec[1]
	if who != "Lin Feng" and who != "Yue Ling" and who != "Narrator":
		cue_npc = who
	if g == "":
		return
	var a := _actor(who)
	if not a.is_empty() and Assets.has_clip(a[0], g):
		Models.act(a[0], g, t + float(a[1]))
	var reply: String = Data.EMOTE_REPLY.get(g, "")
	if reply == "":
		return
	var listener := "Lin Feng" if who != "Lin Feng" else cue_npc
	var b := _actor(listener)
	if not b.is_empty() and b[0] != (a[0] if not a.is_empty() else null) and Assets.has_clip(b[0], reply):
		Models.act(b[0], reply, t + float(b[1]) + 0.35)

## The conversation camera: while somebody is speaking over the world the chase camera eases round
## into a two-shot from the side, framing Lin Feng and whoever he is talking to at head height (higher
## indoors, to look in over the walls); during narration it drifts slowly round him.  It eases back
## when the conversation ends.
func _cutscene(d: float, pp: Vector3) -> void:
	var dl = main.dialogue if main != null else null
	var on: bool = main != null and main.top_name() == "dialogue" and not dl.lines.is_empty() and trip.is_empty()
	if on and (not is_same(dl.lines, cue_lines) or dl.idx != cue_idx):
		cue_lines = dl.lines
		cue_idx = dl.idx
		_cue_line(dl.lines[dl.idx])
	if not on:
		cue_idx = -1
		cue_lines = []
	cine_k = clampf(cine_k + d * (1.6 if on else -2.2), 0.0, 1.0)
	if cine_k <= 0.0:
		cine_pos = cam.position
		return
	var sp := speaker()
	var other: Array = []
	if sp != "" and sp != "Lin Feng" and sp != "Narrator":
		other = _actor(sp)
	if other.is_empty() and cue_npc != "":
		other = _actor(cue_npc)
	var a3 := pp + Vector3(0, 1.45, 0)
	var b3 := a3 + Vector3(facing.x, 0, facing.y) * 2.2
	if not other.is_empty() and other[0] != player:
		b3 = (other[0] as Node3D).global_position + Vector3(0, 1.45, 0)
	var mid := (a3 + b3) * 0.5
	var ax := b3 - a3
	ax.y = 0.0
	if ax.length() < 0.4:
		ax = Vector3(facing.x, 0, facing.y)
	ax = ax.normalized()
	var side := Vector3(-ax.z, 0, ax.x)
	if side.dot(cam.position - mid) < 0.0:
		side = -side
	var indoor: bool = inside != "" or is_floor()
	var dist := clampf(a3.distance_to(b3) * 0.9 + 3.4, 4.2, 8.5)
	var goal := mid + side * dist + Vector3(0, 0.5 + (3.2 if indoor else 0.4), 0)
	if sp == "Narrator" or sp == "":
		# narration: a slow drift round the scene
		cine_a += d * 0.12
		goal = mid + (side.rotated(Vector3.UP, sin(cine_a) * 0.5)) * (dist + 1.5) + Vector3(0, 1.4 + (3.0 if indoor else 0.6), 0)
	elif sp == "Lin Feng":
		goal += ax * 0.9
	else:
		goal -= ax * 0.9
	goal.y = maxf(goal.y, ground_y(goal) + 1.1)
	cine_pos = cine_pos.lerp(goal, 1.0 - exp(-d * 3.0))
	var k := smoothstep(0.0, 1.0, cine_k)
	var at := mid + Vector3(0, -0.15, 0)
	var chase_look := cam.global_transform.basis.z
	cam.position = cam.position.lerp(cine_pos, k)
	if cam.position.distance_to(at) > 0.5:
		var look_from := cam.position - chase_look
		cam.look_at(look_from.lerp(at, k) if k < 1.0 else at, Vector3.UP)

## The name of whoever is speaking in the dialogue box, or "".
func speaker() -> String:
	if main == null or main.top_name() != "dialogue":
		return ""
	var dl = main.dialogue
	if dl.lines.is_empty() or dl.idx >= dl.lines.size():
		return ""
	return str(dl.lines[dl.idx][0])

## Monsters amble about their spot in a slow figure of eight, pausing now and then, and stop to
## face the hero when he comes close.  Purely visual: the encounter itself never moves.
func _wander(ms: Array, e: Dictionary, n: Node3D, dist: float, d: float) -> void:
	var seed_ := Terrain3D.hash2(e.pos.x, e.pos.y, 3.0) * 17.0
	var cyc := fmod(t * 0.11 + seed_, 1.0)
	var walking := dist > 9.0 and cyc < 0.62
	for i in ms.size():
		var mk: Node3D = ms[i]
		if not mk.has_meta("home"):
			mk.set_meta("home", mk.position)
			mk.set_meta("prog", seed_ + i * 1.3)
		var prog: float = mk.get_meta("prog")
		var shape: String = mk.get_meta("shape", "")
		var r := 1.6 if i == 0 else 1.0
		if walking:
			prog += d * 0.32 / r
			mk.set_meta("prog", prog)
		var home: Vector3 = mk.get_meta("home")
		var off := Vector3(sin(prog) * r, 0.0, sin(prog * 2.0) * r * 0.45)
		var vel := Vector3(cos(prog), 0.0, cos(prog * 2.0) * 0.9)
		mk.position = home + off
		if walking:
			mk.rotation.y = lerp_angle(mk.rotation.y, atan2(vel.x, vel.z), 1.0 - exp(-d * 4.0))
		else:
			mk.rotation.y = lerp_angle(mk.rotation.y, 0.0, 1.0 - exp(-d * 3.0))
		Models.anim_monster(mk, t, i * 1.7 + e.pos.x, "walk" if walking and Assets.has_clip(mk, "walk") else "idle")
		if shape in ["wisp", "jelly", "storm", "ray"]:
			mk.position.y = home.y + 0.15 * sin(t * 1.6 + i)

func _animate_ent(e: Dictionary, n: Node3D, pp: Vector3, dist: float, d: float, vb: Dictionary = {}) -> void:
	match e.kind:
		"npc":
			var m: Node3D = n.get_meta("model")
			var talking: bool = speaker() == e.n
			# a courteous bow (the cupped-fist salute) when the hero walks up
			var near: bool = dist < 5.0
			if near and not n.get_meta("near", false) and t - float(n.get_meta("bowed", -99.0)) > 25.0 and Assets.has_clip(m, "bow") and not talking:
				# on the model's own clock (it is animated at t + e.pos.x below): on the world clock the bow
				# started hundreds of seconds in the past and was dropped unplayed, so nobody ever bowed
				Models.act(m, "bow", t + e.pos.x)
				n.set_meta("bowed", t)
			n.set_meta("near", near)
			Models.anim_person(m, t + e.pos.x, false, false, "talk" if talking else "")
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
			if e.kind == "enemy":
				_wander(ms, e, n, dist, d)
			else:
				for i in ms.size():
					Models.anim_monster(ms[i], t, i * 1.7 + e.pos.x)
			if dist < 10.0:
				var dv2 := pp - n.position
				n.rotation.y = lerp_angle(n.rotation.y, atan2(dv2.x, dv2.z), 1.0 - exp(-d * 2.0))
			var base_y := _ground(vb, n.position) if not vb.is_empty() else ground_y(n.position)
			n.position.y = base_y + sin(t * 2.2 + e.pos.x) * 0.06 + (0.35 if e.kind == "enemy" and Data.ENEMIES[e.group[0].id].shape in ["wisp", "jelly", "bird", "storm", "ray"] else 0.0)
		"abode":
			var opened: bool = Game.abodes.has(e.id)
			if opened != bool(n.get_meta("open", false)):
				var old: Node3D = n.get_meta("model")
				var nm := Models.sealed_cave(opened)
				old.queue_free()
				n.add_child(nm)
				n.set_meta("model", nm)
				n.set_meta("open", opened)
			var gl: Node3D = (n.get_meta("model") as Node3D).get_meta("glow")
			gl.rotation.z = t * 0.4
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
		"ladder":
			var lm: Node3D = n.get_meta("model")
			var lopen := ladder_open(e)
			var lbl2: Label3D = n.get_meta("label")
			lbl2.text = str(e.get("n", "")) if lopen else "The way is closed"
			lbl2.visible = dist < 14.0
			if lm.has_meta("spin"):
				(lm.get_meta("spin") as Node3D).rotation.y = t * (0.6 if int(e.get("dir", 1)) > 0 else -0.6)
			if lm.has_meta("glow"):
				(lm.get_meta("glow") as Node3D).visible = lopen
		"stele":
			var smd: Node3D = n.get_meta("model")
			if smd.has_meta("spin"):
				(smd.get_meta("spin") as Node3D).rotation.y = t * 0.4

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
	# objective: long quest titles (one in eight runs past the panel, up to 770 px of text) used to be
	# cut off mid-sentence; they now wrap onto a second line in place of the heading
	UI.panel(self, Rect2(VIEW.x - 520, 12, 508, 58))
	var obj := Game.objective_text()
	if UI.font().get_string_size(obj, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x <= 480.0:
		UI.text(self, Vector2(VIEW.x - 506, 34), "Objective", 13, UI.C_DIM)
		UI.text(self, Vector2(VIEW.x - 506, 56), obj, 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 480)
	else:
		UI.wrapped(self, Vector2(VIEW.x - 506, 35), obj, 15, UI.C_TEXT, 486)
	UI.text(self, Vector2(VIEW.x - 330, VIEW.y - 14), "Arrows/WASD move   Q/E camera   Z/Enter act   Esc menu", 13, UI.C_DIM)
	_draw_minimap()
	if banner_t > 0.0:
		var a := clampf(banner_t, 0.0, 1.0)
		var btxt := banner_text if banner_text != "" else area_name
		var bw := maxf(440.0, UI.font().get_string_size(btxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 60.0)
		UI.panel(self, Rect2(VIEW.x * 0.5 - bw * 0.5, 96, bw, 52), Color(0.04, 0.06, 0.13, 0.85 * a), Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, a))
		UI.text(self, Vector2(VIEW.x * 0.5 - bw * 0.5, 130), btxt, 26, Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, a), HORIZONTAL_ALIGNMENT_CENTER, bw)
	elif banner_text != "":
		banner_text = ""
	# interaction hint
	var fe = face_entity()
	if fe != null and move_t < 0.0 and trip.is_empty() and fe.kind in ["npc", "boss", "ladder", "stele", "abode"]:
		var hint := "Talk"
		match fe.kind:
			"boss":
				hint = "Challenge"
			"ladder":
				var lst := str(fe.get("style", ""))
				hint = ("Climb" if lst == "climb" else ("Board the boat" if lst == "sail" else "Take the stairs")) if ladder_open(fe) else "Look"
			"abode":
				hint = "Open the sealed cave" if Game.level >= int(fe.req) and not Game.abodes.has(fe.id) else "Look"
			"stele":
				hint = "Choose your Dao"
		UI.text(self, Vector2(VIEW.x * 0.5 - 150, VIEW.y - 60), "Enter: " + hint, 20, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 300)
	# a trip up or down the Jianmu (or the stairs) fades through white going up, dark going down
	var fade := trip_fade()
	if fade > 0.0:
		var fc := Color(0.96, 0.97, 1.0) if int(trip.dir) > 0 and trip.climb else Color(0.02, 0.02, 0.05)
		if trip.get("sail", false):
			fc = Color(0.55, 0.75, 0.86)
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(fc.r, fc.g, fc.b, fade * (1.0 if trip.climb else 0.85)))
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
	# a window of the world map centred on the player (upstairs or in a cellar: the map of the realm
	# outside, centred on the building)
	var vb: Dictionary = bundles[_view_layer() if _view_layer() != "" else str(wd.get("parent", layer))]
	var mw_t: int = vb.wd.w
	var mh_t: int = vb.wd.h
	var vt := view_tile()
	var span := Vector2(96, 96 * mh / mw)
	var o := Vector2(vt) - span * 0.5
	o.x = clampf(o.x, 0.0, mw_t - span.x)
	o.y = clampf(o.y, 0.0, mh_t - span.y)
	var src := Rect2(o, span)
	draw_rect(r.grow(4), Color(0.02, 0.03, 0.08, 0.85))
	draw_rect(r.grow(4), UI.C_BORDER, false, 2.0)
	draw_texture_rect_region(mini_tex, r, src, Color(1, 1, 1, 0.92))
	var sc := r.size / span
	for e in vb.wd.ents:
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
			"ladder":
				col = Color("a8e0ff") if str(e.get("style", "")) == "climb" else Color(0, 0, 0, 0)
			"stele":
				col = UI.C_JADE
			"abode":
				col = Color("ffc860") if not Game.abodes.has(e.id) else Color(0, 0, 0, 0)
		if col.a > 0.0:
			draw_circle(r.position + (Vector2(e.pos) - o + Vector2(0.5, 0.5)) * sc, 2.4, col)
	var pp := r.position + (Vector2(vt) - o + Vector2(0.5, 0.5)) * sc
	draw_circle(pp, 4.5 + sin(t * 5.0), Color(1, 1, 1, 0.35))
	draw_circle(pp, 2.6, Color("5aa9ff"))
	var here := area_name
	if is_floor():
		here = "%s, %s" % [wd.bld_n, "upstairs" if int(wd.level) > 0 else "below"]
	elif inside != "":
		here = building_at(ptile).get("n", area_name)
	UI.text(self, r.position + Vector2(0, r.size.y + 20), here, 12, UI.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, mw)
	if layer != "surface":
		var realm: String = Atlas.LAYER_NAMES.get(str(wd.get("parent", layer)) if is_floor() else layer, "")
		if realm != "" and realm != Atlas.LAYER_NAMES.surface:
			UI.text(self, r.position + Vector2(0, r.size.y + 36), realm, 12, Color("a8d0ff"), HORIZONTAL_ALIGNMENT_RIGHT, mw)
