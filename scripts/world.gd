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
const CAVE_CAM_DIST := 5.0
const CAVE_CAM_H := 2.7
const FWD := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const RIGHT := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const HERO_OPTS := {"asset": "lin_feng", "sword": true, "glow": Color(0.4, 0.7, 1.0), "hair": "topknot", "trim": Color("e8f0ff"), "cape": Color("2a5aa8")}
const YUE_OPTS := {"asset": "yue_ling", "ribbon": Color("ffb0cc"), "glow": Color(1.0, 0.6, 0.8), "hair": "long", "eyes": Color("c04080")}

var area_id := ""
var wd := {}
var tile_ents := {}
var ent_by_id := {}
## the things to do that stand where anyone may walk (props.gd: a cushion, a stool, a hanging scroll),
## by tile: used by facing them, never in anyone's way
var walk_props := {}
## the thing Lin Feng is using (props.gd) while he steps up to it, does it and steps back: the thing
## and its kind ("e", "k"), when it began and how long he does it ("t0", "dur"), where he stands and
## faces ("from", "to", "yaw", "yaw0", "c", "dir", "side"), how far along it is ("started", "ended",
## "fx_n"), what he holds and sits on ("held", "stool") and Yue Ling's part ("comp_sit", "comp_from")
var using := {}
## the 3D node of each entity on show, by id (the bell that swings, the lantern that is lit)
var ent_nodes := {}
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
## after the stairs, a ladder or a boat: the movement keys are ignored until they are let go
var key_lock := false
var held_dir := Vector2i.ZERO
## screenshot tour: a fixed wide establishing shot replaces the chase camera while set
var cam_override: Variant = null
var cam_a := 0.0
var cam_pos := Vector3.ZERO
## the realm (or floor) the hero is in, every realm's data and 3D offset, and a trip between two of
## them while one is under way ({t, dur, to_layer, to_tile, dir, climb, swapped})
var layer := "surface"
## the beginning (cultures.gd): the tile the hero's last morning at the hearth starts on; until the
## farewell is said nobody can walk further than LEASH tiles from it ((-1, -1): no leash)
var leash := Vector2i(-1, -1)
const LEASH := 16
var bundles := {}
var off := Vector3.ZERO
var trip := {}
var banner_text := ""
var cellar_env: Environment = null
## the air of the caves, by the look of the region over them (caves.gd)
var cave_envs := {}
## the hero's feet in a cave: the floor is steps of half a metre, taken smoothly
var cave_y := 0.0
var cave_goal := 0.0
var cave_snap := true
## Part XII cutscenes: the line of dialogue last acted out, the last person who spoke to Lin Feng, and
## the conversation camera (how far it has blended in from the chase camera, where it is, its slow
## drift during narration)
var cue_lines: Array = []
var cue_idx := -1
var cue_npc := ""
var cine_k := 0.0
var cine_pos := Vector3.ZERO
var cine_a := 0.0
## Fates and Faces (fashion.gd): the ride under the party (rebuilt when another is summoned), its own
## clock (a gallop runs faster than the world's), and how far the hero's model is behind the outfit
## and the look he has now (`hero_sig`: the model is rebuilt when they change)
## the Living Land release (havoc.gd): the body that kicks the pieces of broken things about, the last
## swing of the sword, and the marks battles left on the ground ([node, the minute it was made])
var kick: AnimatableBody3D = null
var strike_t := -9.0
var scars: Array = []
## the Sword's Wake (impact.gd, the Spring Thunder release): the pack struck first and when (its
## battle begins once it has been seen to fly back), the last throw of the sword qi, and the stumps of
## felled trees and the things felled in the views on show ([key, node or null, view id, kind, mmi,
## instance index, transform]) until they grow back
var ambush_t := -1.0
var ambush_e := {}
var wave_t := -9.0
var downed: Array = []
var mount: Node3D = null
var mount_id := ""
var ride_clk := 0.0
var hero_sig := ""
## the High Roads release (peaks.gd): climbing and gliding.  A step that rises more than a stride is
## climbed, hand over hand (`climb`: +1 up, -1 down, 0 walking); V opens the glider, and `glide` is
## the flight: {alt (metres above the plain at the tile he is over), from, n (tiles flown), fold}.
## seconds a climbed step takes: so much, and more for every metre it rises, between these (and three
## quarters of it coming down)
const CLIMB_T := [0.25, 0.16, 0.4, 1.2]
var climb_t := 0.4
const GLIDE_T := 0.13
## metres lost for each tile flown, and when the glider is folded in the air
const GLIDE_SINK := 0.8
const GLIDE_DIVE := 3.0
## the leap a flight begins with, and how far above a thing, a wood or a roof one must be to pass over it
const GLIDE_LEAP := 1.7
const GLIDE_OVER := {"ent": 2.6, "wood": 4.5, "roof": 8.0}
var climb := 0
var climb_clk := 0.0
var scale_in := 0.0
var glide := {}
var glide_want := false
var air_y := 0.0
var kites := {}

func _build3d() -> void:
	opaque = false
	new_scene3d()
	new_camera(62.0)
	sun = Look.sun("sect")
	scene3d.add_child(sun)
	fill = Look.fill("sect")
	scene3d.add_child(fill)
	player = Models.hero({"glow": HERO_OPTS.glow})
	player.add_child(Models.shadow_disc(0.55))
	scene3d.add_child(player)
	hero_light = OmniLight3D.new()
	hero_light.light_color = Color(0.7, 0.85, 1.0)
	hero_light.light_energy = 0.6
	hero_light.omni_range = 9.0
	hero_light.position = Vector3(0, 2.2, 0)
	player.add_child(hero_light)
	comp = Models.yue_ling({"glow": YUE_OPTS.glow})
	comp.add_child(Models.shadow_disc(0.5))
	comp.visible = false
	scene3d.add_child(comp)
	weather = Fx3D.make_weather()
	scene3d.add_child(weather)
	# the Living Land release (havoc.gd): the party's bodies push the pieces of broken things about
	kick = AnimatableBody3D.new()
	var kcs := CollisionShape3D.new()
	var kcap := CapsuleShape3D.new()
	kcap.radius = 0.38
	kcap.height = 1.6
	kcs.shape = kcap
	kick.add_child(kcs)
	kick.position = Vector3(0, -500, 0)
	scene3d.add_child(kick)

func clear_cache() -> void:
	for k in views:
		_free_view(k)
	views.clear()
	cur_view = {}
	area_id = ""
	announced = ""
	inside = ""
	trip = {}
	using = {}
	ambush_t = -1.0
	ambush_e = {}
	ent_nodes.clear()

func _free_view_brk(v: Dictionary) -> void:
	for bid in v.get("brk", {}):
		var bn: Node3D = v.brk[bid]
		if is_instance_valid(bn):
			bn.queue_free()

func _free_view(k: String) -> void:
	var v: Dictionary = views[k]
	v.root.queue_free()
	for i in v.nodes:
		v.nodes[i].queue_free()
	_free_view_brk(v)
	# (the Sword's Wake: the stumps and felled things of the region go with it; _keep_down hides them
	# again if it is built anew before they grow back)
	for i2 in range(downed.size() - 1, -1, -1):
		if str(downed[i2][2]) == k:
			if downed[i2][1] != null and is_instance_valid(downed[i2][1]):
				(downed[i2][1] as Node).queue_free()
			downed.remove_at(i2)

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
	var pb0 := Time.get_ticks_usec()
	var lw: Dictionary = Atlas.world_of(lid)
	if OS.has_environment("AZ_PROFILE"):
		print("[profile] realm %s generated in %d ms" % [lid, (Time.get_ticks_usec() - pb0) / 1000])
	var b := {"wd": lw, "tile_ents": {}, "walk_props": {}, "ent_by_id": {}, "off": Vector3.ZERO, "hm": PackedFloat32Array(), "mini": null, "root": null, "placed": false}
	for e in lw.ents:
		b.ent_by_id[e.id] = e
		if e.kind == "seal":
			for t2 in e.tiles:
				b.tile_ents[t2] = e
		elif e.kind == "prop" and e.get("walk", false):
			# a cushion, a stool, a hanging scroll: used by facing it, walked over freely
			b.walk_props[e.pos] = e
		elif e.kind != "spring":
			b.tile_ents[e.pos] = e
	var floor: bool = lw.get("kind", "") == "floor"
	if floor:
		var pb := _bundle(str(lw.parent))
		b.off = pb.off + Vector3(lw.origin.x * TS, 0.0, lw.origin.y * TS)
		if Caves.is_cave(lw) and not headless():
			# a cave has a map of its own (caves.gd)
			b.mini = Caves.minimap(lw)
	else:
		var o: Vector2i = lw.get("origin", Vector2i.ZERO)
		b.off = Vector3(o.x * TS, float(lw.get("y", 0.0)), o.y * TS)
	bundles[lid] = b
	if not headless():
		b.hm.resize((lw.w + 1) * (lw.h + 1))
		if not floor:
			lw["hm"] = b.hm
			var pb1 := Time.get_ticks_usec()
			b.mini = Gfx.world_minimap(lw)
			if OS.has_environment("AZ_PROFILE"):
				print("[profile] realm %s minimap in %d ms" % [lid, (Time.get_ticks_usec() - pb1) / 1000])
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
			if OS.has_environment("AZ_PROFILE"):
				print("[profile] realm %s dressed (sea, sky) by %d ms" % [lid, (Time.get_ticks_usec() - pb0) / 1000])
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
	walk_props = b.walk_props
	ent_by_id = b.ent_by_id
	hm = b.hm
	off = b.off
	mini_tex = b.mini
	if is_floor():
		mini_tex = b.mini if is_cave() else _bundle(str(wd.parent)).mini
		_place_floor(b)
	Game.layer = lid

func is_floor() -> bool:
	return wd.get("kind", "") == "floor"

## In one of the caves under the land (caves.gd: a floor of its own, made of voxels)?
func is_cave() -> bool:
	return wd.get("cave", false)

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
	if Caves.is_cave(fw):
		# a cave lies under its mouth: its volume hangs below the ground there (and a lower gallery
		# below the cave above it)
		var m: Vector2i = fw.realm_mouth
		var gm := _ground(pb, po + Terrain3D.world_pos(m))
		b.off.y = gm - Caves.NY * Caves.V * float(-int(fw.level)) - 3.0
		off = b.off
		b.placed = true
		return
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
	glide = {}
	glide_want = false
	climb = 0
	air_y = 0.0
	open_world()
	if lid == "":
		lid = layer
	_use(lid)
	cave_snap = true
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
		# the hero arrives facing the way back (the stairs down are beside the stairs up): a key still
		# held from before the trip must be let go first, or he walks straight back in, for ever
		key_lock = true

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

## the region last announced (its banner, a line in the timeline, its sky, fog and weather) and how
## long the hero has been in another one.  Walking along a border used to flip the banner, the sky and
## the weather back and forth with every step (four times in two seconds on the road past the Magpie
## Bridge), and wrote "Entered ..." into the timeline every time; the game's own idea of where he is
## (Game.area) still changes at once.
var announced := ""
var pending_t := 0.0
const ANNOUNCE_AFTER := 0.8

func _enter_region(id: String, quiet: bool = false) -> void:
	if id == area_id:
		return
	area_id = id
	var spec: Dictionary = Data.AREAS[id]
	theme_name = spec.theme
	area_name = spec.n
	Game.area = id
	Game.seen[id] = true
	pending_t = 0.0
	if quiet or announced == "":
		_announce(quiet)

## Tell of the region he is in now: the banner, the timeline and the look of the sky.
func _announce(quiet: bool) -> void:
	announced = area_id
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
	if is_cave():
		if not cave_envs.has(theme_name):
			cave_envs[theme_name] = Caves.environment(theme_name)
		cam.environment = cave_envs[theme_name]
		Fx3D.configure_weather(weather, "none")
		# no sun comes down here: the cave's own lamps and crystals, and the light the hero carries
		sun.visible = false
		fill.visible = false
		hero_light.light_energy = 3.0
		hero_light.omni_range = 15.0
		MB.set_night(0.75)
		return
	sun.visible = true
	fill.visible = true
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
	_apply_hour()

## The Living Land release (clock.gd): the sky, the sun or the moon, the fog and the lanterns follow
## the hour.  Called every frame the world is on screen (a handful of parameters on shared resources).
var night_k := 0.0
func _apply_hour() -> void:
	if headless() or cam == null or cam.environment == null:
		return
	if is_floor() and int(wd.level) < 0:
		# a cellar has no sky: only its lanterns know what hour it is
		MB.set_night(0.6)
		return
	var lk := Look.apply_hour(cam.environment, sun, fill, theme_name, Clock.hour(Game))
	night_k = float(lk.night)
	MB.set_night(night_k)
	RenderingServer.global_shader_parameter_set("night_k", night_k)
	# the hero carries a little light of his own after dark
	hero_light.light_energy = 0.6 + 1.2 * night_k
	hero_light.omni_range = 9.0 + 5.0 * night_k

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
	if bw.get("cave", false):
		# the floor of a cave is the top of the voxels under the point (caves.gd)
		return Caves.floor_y(Caves.layout(str(bw.area), int(bw.level)), p.x - bb.off.x, p.z - bb.off.z) + bb.off.y
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
		if Rooms.inside(bd, tile):
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

## Whether the ground at world point `p` can be walked on (no trees, wall or water there).
func _open_at(p: Vector3) -> bool:
	return tile_free(Vector2i(floori((p.x - off.x) / Terrain3D.T), floori((p.z - off.z) / Terrain3D.T)))

## How far out from `mid` along `dir` a conversation camera can stand outdoors, up to `want` metres:
## with open ground under it and a metre beyond, so that it is never up in the roof of a hall (or a
## tree) beside the scene, as it was by the sect's bell at the first dawn of the year.
func _cam_reach(mid: Vector3, dir: Vector3, want: float) -> float:
	var r := want
	while r > 2.6 and not (_out_at(mid + dir * r) and _out_at(mid + dir * (r + 1.0))):
		r -= 0.5
	return r

## Whether world point `p` is over open ground out of doors (walkable, and not a building's floor).
func _out_at(p: Vector3) -> bool:
	var t := Vector2i(floori((p.x - off.x) / Terrain3D.T), floori((p.z - off.z) / Terrain3D.T))
	return tile_free(t) and grid[t.y * w + t.x] != MapGen.INTERIOR

func _build_view(id: String) -> void:
	var prof_tv := Time.get_ticks_usec()
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
			# (the wings built out from it, rooms.gd, in the slice's own tiles too)
			if bd.has("wings"):
				var lws: Array = []
				for wg in bd.wings:
					lws.append({"rect": Rect2i((wg.rect as Rect2i).position - r.position, (wg.rect as Rect2i).size), "side": int(wg.side)})
				lb["wings"] = lws
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
	# the things to do on the forest edge stand in little clearings of their own (only the look of the
	# ground changes: the tile is as closed as ever)
	var vg: PackedByteArray = sl.grid
	var clear := {}
	for e0 in lw.ents:
		if e0.kind == "prop" and e0.area == id and not e0.has("furn"):
			var lt: Vector2i = e0.pos - r.position
			# the bigger things (a pavilion, a watchtower, a stage) stand in a wider clearing
			var cr: int = int(Props.KINDS.get(str(e0.prop), {}).get("clear", 0))
			for cy in range(-cr, cr + 1):
				for cx in range(-cr, cr + 1):
					var ct := lt + Vector2i(cx, cy)
					if ct.x >= 0 and ct.y >= 0 and ct.x < r.size.x and ct.y < r.size.y and vg[ct.y * r.size.x + ct.x] == MapGen.WALL:
						vg[ct.y * r.size.x + ct.x] = MapGen.FLOOR
						clear[ct] = true
	# (and no house or pavilion of the wilds is built beside one, facing it)
	Scatter.clearings = clear
	var prof_t0 := Time.get_ticks_usec()
	var root := Terrain3D.build(vg, r.size.x, r.size.y, spec.theme, spec.seed, {"hm": shm, "shore": shore, "open": true, "buildings": bl, "area": id})
	var prof_t1 := Time.get_ticks_usec()
	Scatter.clearings = {}
	root.position = Vector3(r.position.x * TS, 0.0, r.position.y * TS) + bb.off
	scene3d.add_child(root)
	var nodes := {}
	for i in lw.ents.size():
		var e: Dictionary = lw.ents[i]
		if e.area != id:
			continue
		var n := _make_ent(e, bb.off)
		n.position.y = _stand_y(bb, n.position)
		if e.kind == "prop" and Props.WATER_KINDS.has(str(e.prop)):
			n.position.y = bb.off.y
		scene3d.add_child(n)
		nodes[i] = n
	# the High Roads (peaks.gd): a cairn and a line of flags on every summit, and its name over it
	for pk in Peaks.of_area(lw, id):
		var kp: Vector3 = Terrain3D.world_pos(pk.c) + bb.off
		var cn := Peaks.cairn(int(pk.i) * 31 + 7, Color("c83a3a"))
		cn.position = Vector3(kp.x + 0.75, _ground(bb, kp + Vector3(0.75, 0, 0.75)) - 0.05, kp.z + 0.75) - root.position
		root.add_child(cn)
		_label(cn, "%s  %d m" % [str(pk.n), int(round(float(pk.h)))], 3.3, Color("f4ecd8"), 26).visibility_range_end = 60.0
	# a junk at her mooring in every harbour (ships.gd): drawn with the region, standing on no tile
	for hid in Ships.ORDER:
		if str(Ships.HARBOURS[hid].area) == id:
			var mo := Ships.mooring(lw, hid)
			if mo.x >= 0:
				var jk := Models.junk()
				var jp: Vector3 = Terrain3D.world_pos(mo) + bb.off
				jk.position = Vector3(jp.x, bb.off.y + Terrain3D.WATER_Y, jp.z) - root.position
				jk.rotation.y = Terrain3D.hash2(mo.x, mo.y, 5.0) * TAU
				root.add_child(jk)
	# the high road between the towns (roads.gd), paved where it crosses this region
	var rdm := Roads.mesh(lid, r, func(x: float, z: float) -> float: return _ground(bb, Vector3(x, 0.0, z) + Vector3(bb.off.x, 0.0, bb.off.z)) - bb.off.y)
	if rdm != null:
		root.add_child(rdm)
	# ... and the camp of the people of the road at the foot of the highest (folk.gd)
	if (lw.get("camps", {}) as Dictionary).has(id):
		var cp: Vector3 = Terrain3D.world_pos(lw.camps[id]) + bb.off
		var cm := Structures.camp(int(spec.seed))
		cm.position = Vector3(cp.x, _ground(bb, cp), cp.z) - root.position
		root.add_child(cm)
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
	# the Living Land release: the things people leave about their towns (havoc.gd)
	var brk := {}
	for b in Havoc.of_area(lw, id):
		var bn := Havoc.model(str(b.kind))
		var bp: Vector3 = Terrain3D.world_pos(b.tile) + bb.off
		bp.y = _stand_y(bb, bp)
		bn.position = bp
		bn.rotation.y = float(b.yaw)
		bn.set_meta("b", b)
		scene3d.add_child(bn)
		brk[b.id] = bn
	if OS.has_environment("AZ_PROFILE"):
		print("[profile] view %-10s heights+prep %5d ms, terrain %5d ms, things %5d ms (%d)" % [id, (prof_t0 - prof_tv) / 1000, (prof_t1 - prof_t0) / 1000, (Time.get_ticks_usec() - prof_t1) / 1000, nodes.size()])
	views[id] = {"root": root, "nodes": nodes, "shown": true, "roofs": root.get_meta("roofs", {}), "uppers": root.get_meta("uppers", {}), "layer": lid, "ents": lw.ents, "bundle": lid, "brk": brk, "origin": r.position}
	# the Sword's Wake (impact.gd): what was felled here and has not yet grown back stays down
	_keep_down(id)

## A floor's own view: its people and things (an upper storey is drawn with its building; a cellar
## is built here, under the building).
func _floor_view(fid: String) -> void:
	var bb := _bundle(fid)
	var fw: Dictionary = bb.wd
	var root := Node3D.new()
	root.name = "floor_" + fid
	root.position = bb.off
	scene3d.add_child(root)
	if Caves.is_cave(fw):
		Caves.build(root, fw)
	elif int(fw.level) < 0:
		Terrain3D.cellar(root, fw)
	var nodes := {}
	for i in fw.ents.size():
		var n := _make_ent(fw.ents[i], bb.off)
		n.position.y = _ground(bb, n.position) if Caves.is_cave(fw) else bb.off.y
		scene3d.add_child(n)
		nodes[i] = n
	views[fid] = {"root": root, "nodes": nodes, "shown": true, "roofs": {}, "uppers": {}, "layer": fid, "ents": fw.ents, "bundle": fid}

# ---------------------------------------------------------------- entities
func ent_visible(e: Dictionary) -> bool:
	# the beginning (cultures.gd): the last morning at the hearth is three years before the story: its
	# keeper is at home, nothing prowls, and nothing of the chapters to come is lying about
	if Game.prologue != "":
		if e.kind == "npc" and str(e.id) == str(Cultures.HEARTHS[Game.prologue].keeper):
			return true
		if e.kind in ["enemy", "boss", "pickup", "obstacle", "portal", "abode", "machine", "mark", "hold"] or e.get("fate", false) or e.has("pick") or e.has("hold"):
			return false
	match e.kind:
		"enemy":
			if Game.defeated.has(e.id):
				return false
			# the war-bands of the Eight Gates (Part XIII) only march once the formation wakes
			var ev = e.get("vis", ["", ""])
			# (Part XXIV: a band may stop marching when a step is done: the bore of the eighth month)
			if ev.size() > 1 and str(ev[1]) != "" and Game.done(str(ev[1])):
				return false
			return ev[0] == "" or Game.reached(ev[0])
		"seal", "ladder", "abode":
			return true
		"boss":
			if Game.boss_done.has(e.enemy):
				return false
			# a boss who only appears later in the story (the Gate Generals and Chiyou, Part XIII)
			# (the reckoning, reckon.gd: only the lords this journey's choices made stand on the mountain)
			if Reckon.is_lord(str(e.enemy)):
				return Reckon.stands(Game, str(e.enemy))
			var bv = e.get("vis", ["", ""])
			# (Part XXIV: a lord that cannot be beaten is gone from the land when the losing is done)
			if bv.size() > 1 and str(bv[1]) != "" and Game.done(str(bv[1])):
				return false
			return bv[0] == "" or Game.reached(bv[0])
		"pickup":
			if Game.taken.has(e.id):
				return false
			# a cache only Spirit Sense can feel (Part XII)
			if e.get("sense", false) and Game.talent("spirit_sense") < 1:
				return false
		"portal":
			return true
		"obstacle":
			# Part XVII (impact.gd): an obstacle of the story stays cleared
			if Game.cleared.has(e.id):
				return false
		"machine":
			# the Hundred Works (works.gd): a machine stands once it has been built
			return Works.stands(Game, str(e.work))
		"mark":
			# the Lost Horse release (marks.gd): what a crossroads answer left standing, or a leaning scale
			return Marks.stands(Game, e)
		"hold":
			# the Three Burrows release (hold.gd): a plot of the hero's own town, once it is built
			return Hold.stands(Game, e)
	# (and whoever has come to live there, once it has that many households)
	if e.has("hold") and not Hold.stands(Game, e):
		return false
	# somebody who is only in the world of whoever chose that way (marks.gd)
	if e.has("pick") and not Marks.who_stands(Game, e):
		return false
	# somebody met on the road (fate.gd): there while the story has them there
	if e.get("fate", false) and not Fate.present(Game, str(e.id)):
		return false
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

## The Lost Horse release (marks.gd): build what stands at mark `e` for the answer given (or the way the
## scale leans now), in place of whatever stood there before.
func _mark_model(e: Dictionary, n: Node3D) -> void:
	if n.has_meta("model"):
		(n.get_meta("model") as Node3D).queue_free()
	var mm := Marks.model(Marks.spec(Game, e), int(e.get("i", 0)))
	# (one thing alone stands any way round; the things of a row stand along it, and a road is laid end to end)
	var msp := Marks.spec(Game, e)
	var mline: Vector2i = e.get("line", Vector2i.ZERO)
	if int(msp.get("k", 1)) == 1 or mline == Vector2i.ZERO:
		mm.rotation.y = Terrain3D.hash2(e.pos.x, e.pos.y, 11.0) * TAU
	else:
		mm.rotation.y = 0.0 if mline.x != 0 else PI * 0.5
		if str(msp.m[0]) == "road":
			mm.rotation.y += PI * 0.5
			mm.scale.z = 2.0
	n.add_child(mm)
	n.set_meta("model", mm)
	n.set_meta("key", Marks.key(Game, e))
	(n.get_meta("label") as Label3D).text = Marks.name_of(Game, e) if int(e.get("i", 0)) == 0 else ""

## The Three Burrows release (hold.gd): build what stands on plot `e` of the hero's own town as the town
## is now (its rank changes the roofs, its sect the banner), in place of whatever stood there before.
func _hold_model(e: Dictionary, n: Node3D) -> void:
	if n.has_meta("model"):
		(n.get_meta("model") as Node3D).queue_free()
	var hm := Hold.model_of(e, Hold.rank(Game), Hold.sect(Game))
	n.add_child(hm)
	n.set_meta("model", hm)
	n.set_meta("key", Hold.key(Game, e))
	(n.get_meta("label") as Label3D).text = Hold.name_of(e)

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
		if Rooms.inside(bd, tile):
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
		"nomad", "spore_witch", "steppe_shaman", "nuwa_echo", "lantern_monk", "fisher", "meng_po", "judge_cui", "qing_lian_echo":
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
	ent_nodes[e.id] = n
	match e.kind:
		"prop":
			# a thing to do (props.gd): outdoors its own model, turned to face the open ground it is
			# used from; furniture is drawn by its building, and the node only carries what it does
			if e.has("furn") and str(e.id) == Bonds.LOOM or Bonds.spot_is(Bonds.FEAST, e):
				# (Part XV: the loom she was woven on gets the lotus-pink mark too)
				var lm := _label(n, "!", 2.6, Color("ff9ac0"), 72)
				lm.visible = false
				n.set_meta("mark", lm)
			if not e.has("furn"):
				var pm := Props.model(str(e.prop), str(Data.AREAS[e.area].theme))
				var fd: Vector2i = e.get("face", Vector2i(0, 1))
				pm.rotation.y = atan2(float(fd.x), float(fd.y))
				n.add_child(pm)
				n.set_meta("model", pm)
				var pl := _label(n, Props.name_of(e), 2.5 if not Props.is_structure(str(e.prop)) else 3.6, Color("f0e6c8") if not e.has("memory") else Color("ffb0d0"), 24)
				pl.visible = false
				n.set_meta("label", pl)
				if e.has("memory"):
					# Part XV: a lotus-pink mark over a memory waiting to be given back (bonds.gd)
					var pm2 := _label(n, "!", 4.6, Color("ff9ac0"), 72)
					pm2.visible = false
					n.set_meta("mark", pm2)
		"npc":
			# (someone who appears in two places shares one model: "asset")
			var m := Models.person(e.col, Color("2a2a3a"), _npc_opts(str(e.get("asset", e.id))))
			# the Felt Hearth (cultures.gd): the keeper of the tents sits by her fire, the three stones and
			# the kettle, with a felt windbreak at her back
			if str(e.id) == "sarnai":
				n.add_child(Cultures.camp())
			# the Living Land release: the people with names work at their place all day (folk.gd POSTS)
			if Folk.POSTS.has(str(e.get("asset", e.id))):
				Assets.lend_clips(m)
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
			# the hours of the wild (habits.gd): what the pack is doing, when it is worth knowing
			n.set_meta("hab", _label(n, "", 3.0, Color.WHITE, 26))
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
		"obstacle":
			# Part XVII (impact.gd): a fallen trunk, a rockfall, an ice jam, the clay Spring Ox...
			var om := Impact.obstacle_model(str(e.what), str(Data.AREAS.get(str(e.get("area", "")), {}).get("theme", "")))
			om.rotation.y = Terrain3D.hash2(e.pos.x, e.pos.y, 5.0) * TAU
			n.add_child(om)
			n.add_child(Models.shadow_disc(1.0, 0.35))
			_label(n, str(Impact.OBSTACLES.get(str(e.what), {}).get("n", "")).capitalize(), 2.2 if str(e.what) != "spring_ox" else 2.6, Color("e8dcc0"), 26)
			n.set_meta("model", om)
		"machine":
			# the Hundred Works (works.gd, machines.gd): something Lin Feng built, or Gongshu Ban did
			var mm := Machines.model(str(Works.STORY_SITES[e.work].model) if Works.STORY_SITES.has(str(e.work)) else str(e.work))
			mm.rotation.y = Terrain3D.hash2(e.pos.x, e.pos.y, 9.0) * TAU
			n.add_child(mm)
			n.add_child(Models.shadow_disc(1.2, 0.35))
			var ml := _label(n, Works.site_name(str(e.work)), 3.0, Color("e8d090"), 26)
			n.set_meta("label", ml)
			n.set_meta("model", mm)
		"mark":
			# the Lost Horse release (marks.gd): built when it first stands (_mark_model), so that the
			# answers never given are never built
			n.add_child(Models.shadow_disc(1.2, 0.3))
			var kl := _label(n, "", 3.2, Color("f0c8a0"), 26)
			n.set_meta("label", kl)
			n.set_meta("key", "")
		"hold":
			# the Three Burrows release (hold.gd): a plot of the town, built when it first stands (_hold_model)
			if not e.has("seg"):
				n.add_child(Models.shadow_disc(1.6, 0.3))
			var hl := _label(n, "", 4.4 if not e.has("seg") else 5.6, Color("f0e0b0"), 26)
			n.set_meta("label", hl)
			n.set_meta("key", "")
		"spring":
			n.add_child(Models.spring_basin())
		"ladder":
			# the way up or down the Jianmu, or a flight of stairs (the building draws the stairs; a
			# glowing mark on the floor shows where they are)
			var lm: Node3D = Caves.mouth_model(str(e.get("theme", ""))) if str(e.get("style", "")) == "cave" else Models.ladder(str(e.get("style", "")), int(e.get("dir", 1)))
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
			# the door faces the sect, the way a disciple comes to it
			var to_sect: Vector2i = Atlas.to_world("sect", Vector2i(20, 13)) - e.pos
			cm.rotation.y = atan2(float(to_sect.x), float(to_sect.y))
	return n

# ---------------------------------------------------------------- doing things (props.gd)
## seconds to step up to a thing (and back from it afterwards)
const USE_STEP := 0.45
## when a thing answers, seconds into the clip (by clip), and how often a long one answers again (by
## what it does)
const FX_AT := {"strike": 0.95, "toss": 0.62, "drink": 0.9, "gather": 1.0, "lift": 1.45, "touch": 0.8, "bow": 0.6, "attack": 0.3, "hammer": 0.82,
	"archery": 1.68, "release": 2.0, "float_lantern": 1.45, "sword_dance": 0.4, "kite": 0.3, "stargaze": 0.8, "write": 0.6, "push": 0.5, "dance": 0.3}
const FX_EVERY := {"notes": 1.1, "steam": 1.3, "smoke": 1.5, "sparks": 1.2, "embers": 0.9, "ripple": 1.7, "leaves": 1.8, "qi": 1.6, "chime": 1.4, "koi": 1.5, "zzz": 2.0,
	"blade": 0.8, "flour": 1.1, "petals": 1.0, "stars": 1.4, "ink": 1.2}
## Yue Ling's part, by what she does: the ones she keeps doing for as long as he does
const COMP_LOOP := ["pray", "warm", "read", "meditate", "sit_bench", "gather", "play_flute", "dance", "soak", "stargaze"]
## the Lotus release: how long the watchtower's ladder takes, each way (seconds of the time it takes)
const CLIMB_S := 1.6

## Lin Feng and Yue Ling do thing `e` for as long as a scene goes on over it (a memory given back, the
## lotus pond, bonds.gd): end_use() lets them step back.
func start_scene_use(e: Dictionary) -> void:
	start_use(e)
	if not using.is_empty():
		using.scene = true
		using.dur = 3600.0

## The scene is over: they finish what they are doing and step back (what comes of it still comes).
func end_use() -> void:
	if using.is_empty():
		return
	using.scene = false
	if not bool(using.started):
		using.dur = 0.6
	else:
		using.dur = maxf(0.6, t - float(using.t0) - USE_STEP)

## Lin Feng uses thing `e`: he steps up to it (or onto it, to sit), does it, and steps back; what comes
## of it is shown when he is done.
func start_use(e: Dictionary) -> void:
	if not using.is_empty() or not trip.is_empty():
		return
	var k := Props.kind_of(e)
	if k.is_empty():
		return
	var from := _player_pos()
	var nd = ent_nodes.get(e.id)
	var c := ent_pos(e)
	var dir := Vector3(c.x - from.x, 0.0, c.z - from.z)
	if dir.length() < 0.05:
		dir = Vector3(facing.x, 0.0, facing.y)
	dir = dir.normalized()
	var side := Vector3(dir.z, 0.0, -dir.x)
	var at := str(k.get("at", "face"))
	var to := from + dir * 0.55
	var yaw := atan2(dir.x, dir.z)
	# (a thing for two, Lin Feng and Yue Ling side by side: a bench, a pavilion, a hot spring, the
	# lantern green, the grass under the stars)
	var comp_sit: bool = Game.companion and ((str(k.get("comp", "")) == "sit_bench" and at == "seat") or bool(k.get("pair", false)))
	match at:
		"seat":
			to = c - dir * float(k.get("off", 0.0))
			yaw = atan2(-dir.x, -dir.z)
		"before":
			to = c - dir * float(k.get("off", 0.0))
		"on":
			to = c
		"stage":
			# up the steps and onto the boards, turned to face whoever is watching
			to = c + dir * 0.05
			yaw = atan2(-dir.x, -dir.z)
		"climb":
			# the foot of the watchtower's ladder
			to = c - dir * 0.95
		"circle":
			# the end of the millstone's bar
			to = c + side * Structures.MILL_R
	if comp_sit:
		# room for two: he takes one end of the bench and she the other
		to -= side * 0.4
	# on the thing's own ground outdoors (a bench on the forest edge stands a little higher), on the
	# floorboards he stands on indoors
	var base_y: float = from.y
	if at != "face" and not e.has("furn") and nd != null and is_instance_valid(nd):
		base_y = (nd as Node3D).position.y
	using = {"e": e, "k": k, "t0": t, "dur": float(k.dur), "from": from, "to": Vector3(to.x, base_y + float(k.get("rise", 0.0)), to.z), "yaw": yaw, "yaw0": player.rotation.y,
		"c": c, "dir": dir, "side": side, "started": false, "ended": false, "fx_n": 0, "held": null, "stool": null, "comp_sit": comp_sit,
		"comp_from": comp_pos, "comp_held": null, "base_y": base_y}
	move_dir = Vector2i.ZERO
	if nd != null and is_instance_valid(nd):
		(nd as Node3D).set_meta("used_t", t + USE_STEP)

## Enter or Esc while doing something long: finish now (what comes of it still comes).
func press_use(_act: String) -> void:
	if using.is_empty() or not bool(using.started) or bool(using.ended):
		return
	if Props.ONCE.has(str(using.k.clip)):
		return
	using.dur = maxf(0.6, t - float(using.t0) - USE_STEP)

## The clock of doing something (also when headless): begin, finish, step back.
func _use_step() -> void:
	var el := t - float(using.t0)
	var dur := float(using.dur)
	if not bool(using.started) and el >= USE_STEP:
		using.started = true
		_use_begin()
	if bool(using.started) and not bool(using.ended) and el >= USE_STEP + dur:
		using.ended = true
		_use_finish()
	if el >= USE_STEP * 2.0 + dur:
		_use_clear()

func _use_begin() -> void:
	var k: Dictionary = using.k
	var clip := str(k.clip)
	# (a gesture still going from before, his or hers, would play over the clip: it ends here)
	player.set_meta("act", "")
	comp.set_meta("act", "")
	if Props.ONCE.has(clip):
		Models.act(player, clip, t)
	if headless():
		return
	# what he holds for it, in his right hand (a bow in his left)
	var hold := str(k.get("hold", ""))
	if hold != "":
		var hn := _hold_in_hand(player, hold, "hand.L" if Props.LEFT_HAND.has(hold) else "hand.R")
		if hn != null:
			using.held = hn
	# and what she holds for her part (her flute to his qin, a sky lantern of her own)
	var chold := str(k.get("comp_hold", ""))
	if chold != "" and Game.companion:
		var ch := _hold_in_hand(comp, chold)
		if ch != null:
			using.comp_held = ch
	# a stool for a loom that has none
	if str(using.e.get("furn", "")) == "loom":
		var sb := MB.new()
		sb.cyl(Vector3(0, 0.2, 0), 0.2, 0.4, MB.tag(Props.WOOD, MB.WOOD), Vector3.ZERO, 10)
		var sn := MB.mesh_node(scene3d, sb.build(MB.mat_plain()), Vector3(using.to.x, float(using.to.y), using.to.z) - Vector3(using.dir.x, 0, using.dir.z) * 0.1)
		using.stool = sn
	# (the Underclothes release: nobody gets into a hot spring or a bath in their robes)
	if clip == "soak":
		Models.undress(player, true)
		if Game.companion and str(k.get("comp", "")) == "soak":
			Models.undress(comp, true)
	# Yue Ling joins in or reacts
	if Game.companion:
		var cc := str(k.get("comp", "watch"))
		if cc != "watch" and not COMP_LOOP.has(cc):
			Models.act(comp, cc, t + 1.0)

func _use_finish() -> void:
	var lines := Props.use(using.e, Game)
	for ln in lines:
		Game.toast(str(ln))
	var hn = using.held
	if hn != null and is_instance_valid(hn):
		(hn as Node).queue_free()
	using.held = null
	var ch = using.get("comp_held")
	if ch != null and is_instance_valid(ch):
		(ch as Node).queue_free()
	using.comp_held = null

func _use_clear() -> void:
	var sn = using.get("stool")
	if sn != null and is_instance_valid(sn):
		(sn as Node).queue_free()
	for key in ["held", "comp_held"]:
		var hn2 = using.get(key)
		if hn2 != null and is_instance_valid(hn2):
			(hn2 as Node).queue_free()
	comp_pos = player.position if not Game.companion else comp.position
	player.rotation.x = 0.0
	# (out of the water and dressed again: as dressed as the wardrobe says)
	if str(using.k.get("clip", "")) == "soak" and not headless():
		Models.undress(player, Game.underclothes)
		if comp != null:
			Models.undress(comp, false)
	# and a gesture for it that is still going ends with it (only when he is hurried on)
	player.set_meta("act", "")
	using = {}

## The thing in the hero's hand (Props.held), on his right hand bone (or `bone`); null if the model
## has no skeleton to hold it.
func _hold_in_hand(m: Node3D, what: String, bone: String = "hand.R") -> Node3D:
	var sks := m.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return null
	var sk := sks[0] as Skeleton3D
	if sk.find_bone(bone) < 0:
		return null
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	sk.add_child(ba)
	ba.add_child(Props.held(what))
	return ba

## Where the hero and Yue Ling are and what they do while he does something.
func _use_pose(d: float) -> void:
	var el := t - float(using.t0)
	var dur := float(using.dur)
	var k: Dictionary = using.k
	var in_k := smoothstep(0.0, USE_STEP, el)
	var out_k := smoothstep(USE_STEP + dur, USE_STEP * 2.0 + dur, el)
	var at_k := in_k * (1.0 - out_k)
	var from: Vector3 = using.from
	var to: Vector3 = using.to
	var pos := from.lerp(to, at_k)
	var doing: bool = bool(using.started) and not bool(using.ended)
	var yaw := lerp_angle(float(using.yaw0), float(using.yaw), smoothstep(0.0, USE_STEP * 0.8, el))
	if el > USE_STEP + dur:
		yaw = lerp_angle(float(using.yaw), atan2(float(facing.x), float(facing.y)), smoothstep(USE_STEP + dur, USE_STEP * 2.0 + dur, el))
	var tilt := 0.0
	if str(k.get("fx", "")) == "swing":
		# the swing goes, with him on it: higher and higher, then dying away
		var nd = ent_nodes.get(using.e.id)
		var sw := 0.0
		if doing:
			var ph := el - USE_STEP
			sw = sin(ph * 2.2) * 0.42 * smoothstep(0.0, 1.5, ph) * (1.0 - smoothstep(dur - 1.2, dur, ph))
		if nd != null and is_instance_valid(nd) and (nd as Node3D).has_meta("model"):
			var pmod := (nd as Node3D).get_meta("model") as Node3D
			if pmod.has_meta("mover"):
				(pmod.get_meta("mover") as Node3D).rotation.x = sw
		var r := 2.12
		var dz := -r * sin(sw)
		var dy := r * (1.0 - cos(sw))
		# (the seat swings about the beam: back and up on one side of the arc, forward and up on the other)
		pos += Vector3(-using.dir.x, 0, -using.dir.z) * dz + Vector3(0, dy, 0)
		tilt = sw
	var clip := str(k.clip)
	var at := str(k.get("at", "face"))
	if at == "circle" and doing:
		# round the millstone with the bar: the stone turns with him (three turns in the time it takes)
		var ph2 := (el - USE_STEP) / maxf(dur, 0.1) * TAU * 3.0
		var cc: Vector3 = using.c
		var s0: Vector3 = using.side
		var d0: Vector3 = using.dir
		var rad := Structures.MILL_R
		var off2 := s0 * cos(ph2) + d0 * sin(ph2)
		# walking round behind the bar with his hands on its end: facing along the circle
		var tang := -s0 * sin(ph2) + d0 * cos(ph2)
		pos = Vector3(cc.x, float(using.to.y), cc.z) + off2 * rad - tang * 0.45
		yaw = atan2(tang.x, tang.z)
		var nd2 = ent_nodes.get(using.e.id)
		if nd2 != null and is_instance_valid(nd2) and (nd2 as Node3D).has_meta("model"):
			var pm2 := (nd2 as Node3D).get_meta("model") as Node3D
			if pm2.has_meta("mover"):
				# the bar points where he pushes it: in the model's own space (turned to face the open
				# ground), from its +x
				var local := Basis(Vector3.UP, -pm2.rotation.y) * off2
				(pm2.get_meta("mover") as Node3D).rotation.y = atan2(-local.z, local.x)
	elif at == "climb" and doing:
		# up the ladder, a long look from the top, and down again
		var ph3 := el - USE_STEP
		var top: Vector3 = Vector3(using.c.x, float(using.base_y) + Structures.TOWER_TOP, using.c.z) - Vector3(using.dir.x, 0, using.dir.z) * 0.1
		var foot: Vector3 = using.to
		var up_k := smoothstep(0.0, CLIMB_S, ph3) * (1.0 - smoothstep(dur - CLIMB_S, dur, ph3))
		pos = foot.lerp(top, up_k)
		if ph3 < CLIMB_S or ph3 > dur - CLIMB_S:
			clip = "climb"
		else:
			# from the top he looks out over the land, away from the ladder
			yaw = atan2(-using.dir.x, -using.dir.z)
	player.position = pos
	player.rotation = Vector3(tilt, yaw, 0.0)
	if not doing:
		Models.anim_person(player, t, at_k > 0.02 and at_k < 0.98, false, "")
	elif Props.ONCE.has(clip):
		Models.anim_person(player, t, false, false, "")
	else:
		Models.anim_person(player, t, false, false, clip)
	if doing:
		_use_fx_tick(el - USE_STEP)
	comp.visible = Game.companion
	if Game.companion:
		_comp_use(d, el, doing)

func _comp_use(d: float, el: float, doing: bool) -> void:
	var k: Dictionary = using.k
	var cc := str(k.get("comp", "watch"))
	var c: Vector3 = using.c
	if bool(using.comp_sit):
		# beside him on the bench (in the pavilion, in the hot spring, on the lantern green, in the
		# grass under the stars), doing her part there
		var seat: Vector3 = using.to + using.side * 0.8
		var dur := float(using.dur)
		var a := smoothstep(0.0, USE_STEP, el) * (1.0 - smoothstep(USE_STEP + dur, USE_STEP * 2.0 + dur, el))
		var cf: Vector3 = using.comp_from
		comp.position = cf.lerp(seat, a)
		comp.rotation.y = lerp_angle(comp.rotation.y, float(using.yaw), 1.0 - exp(-d * 8.0))
		var pc := cc if cc != "watch" else "sit_bench"
		Models.anim_person(comp, t + 1.0, a > 0.02 and a < 0.98 and not doing, false, pc if doing else "")
		return
	comp.position = comp_pos
	var want := atan2(c.x - comp_pos.x, c.z - comp_pos.z)
	comp.rotation.y = lerp_angle(comp.rotation.y, want, 1.0 - exp(-d * 6.0))
	Models.anim_person(comp, t + 1.0, false, false, cc if doing and COMP_LOOP.has(cc) else "")

func _use_fx_tick(el: float) -> void:
	var k: Dictionary = using.k
	var fx := str(k.get("fx", ""))
	if fx == "" or fx == "swing":
		return
	var at0: float = float(FX_AT.get(str(k.clip), 0.35))
	var every: float = float(FX_EVERY.get(fx, 0.0))
	var n := int(using.fx_n)
	if n > 0 and every <= 0.0:
		return
	if el >= at0 + n * every:
		using.fx_n = n + 1
		_prop_fx(fx, using.e)

## How a thing answers being used (the effects are the battle's, made small).
func _prop_fx(fx: String, e: Dictionary) -> void:
	var nd = ent_nodes.get(e.id)
	var c: Vector3 = (nd as Node3D).position if nd != null and is_instance_valid(nd) else ent_pos(e)
	var to_hero := -Vector3(using.dir.x, 0, using.dir.z) if using.has("dir") else Vector3.ZERO
	match fx:
		"splash":
			# the bucket breaking the water down in the well
			Fx3D.splash(scene3d, c + Vector3(0, 0.55, 0), Color(0.6, 0.82, 1.0), 0.5, 0.3)
		"smoke":
			# incense, from the censer on the near side
			Fx3D.drift(scene3d, c + Vector3(0, 0.75, 0) + to_hero * 0.4, Color(0.92, 0.9, 0.95, 0.22), "glow", 4, 0.5, 0.35, 2.6, 0.06)
		"ring":
			Fx3D.shockwave(scene3d, c + Vector3(0, 1.8, 0), Color(1.0, 0.88, 0.55), 9.0, 1.4)
			Fx3D.shockwave(scene3d, c + Vector3(0, 1.8, 0), Color(1.0, 0.95, 0.8), 5.0, 1.0)
		"boom":
			Fx3D.shockwave(scene3d, c + Vector3(0, 1.1, 0), Color(1.0, 0.7, 0.5), 6.0, 0.9)
		"notes":
			Fx3D.drift(scene3d, c + Vector3(0, 0.75, 0), Color(1.0, 0.88, 0.5), "note", 3, 0.34, 0.5, 2.2, 0.45)
		"ripple":
			Fx3D.shockwave(scene3d, Vector3(c.x, c.y + Terrain3D.WATER_Y + 0.05, c.z) - to_hero * 1.2, Color(0.8, 0.92, 1.0), 2.2, 1.2)
		"ribbon":
			Fx3D.leaf_spiral(scene3d, c + Vector3(0, 1.6, 0), Color(0.9, 0.12, 0.15), 1.4)
		"glow":
			Fx3D.glimmer(scene3d, c + Vector3(0, 0.9, 0), Color(1.0, 0.9, 0.6))
		"sparkle":
			Fx3D.glimmer(scene3d, c + Vector3(0, 0.3, 0), Color(0.55, 1.0, 0.7))
		"sparks":
			Fx3D.sparks(scene3d, c + Vector3(0, 0.85, 0) + to_hero * 0.3)
		"embers":
			Fx3D.drift(scene3d, c + Vector3(0, 0.45, 0), Color(1.0, 0.62, 0.25), "glow", 6, 0.12, 1.1, 1.5, 0.3)
		"dust":
			Fx3D.dust(scene3d, player.position, Color(0.75, 0.68, 0.55))
		"leaves":
			Fx3D.leaf_spiral(scene3d, player.position - to_hero * 0.8, Color(0.85, 0.45, 0.2), 1.2)
		"steam":
			Fx3D.drift(scene3d, c + Vector3(0, 0.9, 0), Color(0.95, 0.95, 1.0, 0.2), "glow", 4, 0.8, 0.45, 2.2, 0.15)
		"chime":
			Fx3D.shockwave(scene3d, c + Vector3(0, 2.0, 0), Color(0.95, 0.9, 0.7), 2.5, 0.9)
		"light":
			Fx3D.glimmer(scene3d, c + Vector3(0, 1.4, 0), Color(1.0, 0.8, 0.45))
		"koi":
			Fx3D.splash(scene3d, Vector3(c.x, c.y + Terrain3D.WATER_Y + 0.1, c.z), Color(1.0, 0.75, 0.4), 0.6, 0.45)
		"qi":
			Fx3D.drift(scene3d, player.position + Vector3(0, 0.5, 0), Color(0.6, 0.9, 1.0), "glow", 8, 0.16, 0.45, 1.8, 0.7)
		"zzz":
			Fx3D.drift(scene3d, player.position + Vector3(0, 0.9, 0), Color(0.8, 0.85, 1.0), "zed", 1, 0.28, 0.35, 2.4, 0.05)
		# ---- the Lotus release
		"blade":
			# the sword's path in the air, a pale arc left behind each figure
			Fx3D.shockwave(scene3d, player.position + Vector3(0, 1.2, 0), Color(0.75, 0.9, 1.0), 1.6, 0.5)
			Fx3D.drift(scene3d, player.position + Vector3(0, 1.1, 0), Color(0.8, 0.92, 1.0), "glow", 6, 0.12, 0.6, 0.9, 0.6)
		"flour":
			Fx3D.dust(scene3d, c + Vector3(0, 0.55, 0), Color(0.95, 0.93, 0.88))
		"arrow":
			# the thock of the arrow going home: a few splinters of straw off the face of the target
			Fx3D.drift(scene3d, c + _model_point(e, Structures.TARGET + Vector3(0, 0, 0.16)), Color(1.0, 0.88, 0.55), "glow", 5, 0.06, 0.3, 0.6, 0.15)
		"petals":
			Fx3D.leaf_spiral(scene3d, player.position + Vector3(0, 0.4, 0), Color(1.0, 0.55, 0.65), 1.3)
		"kite":
			Fx3D.leaf_spiral(scene3d, player.position + Vector3(0, 1.2, 0) + to_hero * -0.6, Color(0.9, 0.85, 0.75), 0.8)
		"stars":
			# a few stars coming out over their heads, one by one
			Fx3D.drift(scene3d, player.position + Vector3(0, 2.6, 0), Color(0.85, 0.9, 1.0), "glow", 6, 0.07, 0.3, 2.6, 1.2)
		"sky_lantern", "float":
			# (the lantern itself rises or drifts away: _animate_prop); the ones in their hands are let go
			for key in ["held", "comp_held"]:
				var hn = using.get(key)
				if fx == "sky_lantern" and hn != null and is_instance_valid(hn):
					(hn as Node).queue_free()
					using[key] = null
			# (small warm sparks where the lantern leaves the hands: a flash the size of a door washed
			# the two of them out)
			Fx3D.drift(scene3d, player.position + Vector3(0, 2.0 if fx == "sky_lantern" else 0.25, 0) - to_hero * 0.4, Color(1.0, 0.75, 0.4), "glow", 6, 0.08, 0.9, 1.6, 0.3)
		"ink":
			Fx3D.drift(scene3d, c + Vector3(0, 0.8, 0), Color(0.25, 0.25, 0.35, 0.8), "glow", 3, 0.25, 0.4, 1.8, 0.2)

## A point of a thing's model (its own space, front towards +z) as an offset from where it stands.
func _model_point(e: Dictionary, p: Vector3) -> Vector3:
	var fd: Vector2i = e.get("face", Vector2i(0, 1))
	return Basis(Vector3.UP, atan2(float(fd.x), float(fd.y))) * p

## What the things do on their own, and when they have just been used: the bell swings, the drum
## shivers, the bucket comes up, the fire flickers, the chimes and the swing sway, the float bobs, the
## fish circle (and rush up when fed), a lantern once lit stays lit; the name shows close by.
func _animate_prop(e: Dictionary, n: Node3D, dist: float) -> void:
	if n.has_meta("label"):
		(n.get_meta("label") as Label3D).visible = dist < 7.0 and using.is_empty()
	if n.has_meta("mark"):
		var s := Game.cur_step()
		var mk := n.get_meta("mark") as Label3D
		mk.visible = using.is_empty() and (e.has("memory") and Bonds.memory_ready(Game, str(e.memory)) or not s.is_empty() and str(s.kind) == "share" and Bonds.spot_is(str(s.get("spot", "")), e))
		if mk.visible:
			mk.position.y = 4.6 + sin(t * 4.0) * 0.15
	if not n.has_meta("model"):
		return
	var m := n.get_meta("model") as Node3D
	if not m.has_meta("mover"):
		return
	var mo := m.get_meta("mover") as Node3D
	var since := t - float(n.get_meta("used_t", -1e9))
	match str(e.prop):
		"bell":
			var hit := since - 0.95
			mo.rotation.x = 0.0 if hit < 0.0 or hit > 12.0 else sin(hit * 4.5) * 0.14 * exp(-hit * 0.5)
		"drum":
			var hit2 := since - 0.95
			var pulse := 0.0 if hit2 < 0.0 or hit2 > 2.0 else exp(-hit2 * 7.0) * 0.07
			mo.scale = Vector3(1.0 + pulse, 1.0 + pulse, 1.0 - pulse)
		"campfire":
			mo.scale = Vector3(1.0, 1.0 + 0.15 * sin(t * 9.0 + e.pos.x) + 0.08 * sin(t * 13.0), 1.0)
		"chimes":
			var amp := 0.04 + (0.0 if since < 0.8 or since > 8.0 else 0.3 * exp(-(since - 0.8) * 0.6))
			mo.rotation.x = sin(t * 3.0 + e.pos.x) * amp
			mo.rotation.z = sin(t * 2.3) * amp * 0.5
		"fishing":
			var cyc := fmod(t, 3.2)
			var tug := 0.05 if since > 0.0 and since < 7.0 and cyc > 2.3 and cyc < 2.6 else 0.0
			mo.position.y = Terrain3D.WATER_Y + 0.02 + sin(t * 2.0 + e.pos.y) * 0.02 - tug
		"koi":
			mo.rotation.y = t * (0.3 + (1.4 if since > 0.0 and since < 4.0 else 0.0))
			mo.position.y = Terrain3D.WATER_Y - 0.12 + (0.08 if since > 0.0 and since < 4.0 else 0.0)
		"well":
			var lift := 0.0 if since < 0.0 or since > 3.0 else sin(clampf(since / 2.4, 0.0, 1.0) * PI)
			mo.position.y = 0.55 + 0.45 * lift
		"swing":
			if using.is_empty() or str(using.e.id) != str(e.id):
				mo.rotation.x = sin(t * 1.1 + e.pos.x) * 0.03
		"lantern_st":
			mo.visible = Game.prop_uses.has(e.id) or (since > 0.8 and since < 60.0)
		# ---- the Hollow Hills release (cavethings.gd)
		"miner_niche":
			# the lamp burns once somebody has hung one there
			mo.visible = Game.prop_uses.has(e.id) or (since > 1.6 and since < 60.0)
			mo.scale = Vector3(1.0, 1.0 + 0.12 * sin(t * 11.0 + e.pos.x), 1.0)
		"drip_pool":
			# one drop, falling from the stalactite into the pool, again and again
			var fall := fmod(t * 0.45 + e.pos.x * 0.37, 1.0)
			mo.visible = fall < 0.5
			mo.position.y = 2.4 - fall * fall * 8.2
		"stream_bank":
			mo.visible = since > 0.6 and since < 5.4
			var rk := 1.0 + fmod(t * 1.4, 1.0) * 1.6
			mo.scale = Vector3(rk, 1.0, rk)
		# ---- the Lotus release (structures.gd)
		"armillary":
			mo.rotation.y = t * (0.08 + (0.6 if since > 0.0 and since < 9.0 else 0.0))
		"lantern_green":
			mo.rotation.z = sin(t * 1.3 + e.pos.x) * 0.02
			mo.rotation.x = sin(t * 0.9) * 0.015
		"millstone":
			pass
		"archery":
			# the arrow, in the target once he has shot
			mo.visible = Game.prop_uses.has(e.id) or since > float(FX_AT.archery)
		"sky_lantern":
			# the lantern he let go, rising and drifting east until it is a spark
			var up := since - float(FX_AT.release)
			mo.visible = up > 0.0 and up < 30.0
			if mo.visible:
				var at0: Vector3 = m.get_meta("mover_at", Vector3.ZERO)
				mo.position = at0 + Vector3(sin(up * 0.4) * 0.3 + up * 0.15, up * 0.9, up * 0.05)
		"river_lantern":
			# the lotus lantern he set out, drifting off over the water
			var fl := since - float(FX_AT.float_lantern)
			mo.visible = fl > 0.0 and fl < 40.0
			if mo.visible:
				var at1: Vector3 = m.get_meta("mover_at", Vector3.ZERO)
				mo.position = at1 + Vector3(sin(fl * 0.5) * 0.25, sin(fl * 2.0) * 0.015, -fl * 0.22)
				mo.rotation.y = fl * 0.3
		"kite":
			# the kite goes up while he flies it and comes down after
			# (the clock of a thing starts when he starts doing it: start_use)
			var fly := clampf(since, 0.0, 99.0)
			var dur_k := float(Props.KINDS.kite.dur)
			var hgt := 0.0
			if since > 0.0 and since < dur_k + 2.0:
				hgt = 7.0 * smoothstep(0.0, 2.5, fly) * (1.0 - smoothstep(dur_k - 0.5, dur_k + 2.0, fly))
			mo.visible = hgt > 0.2
			var at2: Vector3 = m.get_meta("mover_at", Vector3.ZERO)
			mo.position = at2 + Vector3(sin(t * 0.7) * 0.6 * hgt / 7.0, hgt, -hgt * 0.8)
			mo.rotation = Vector3(0.3, 0.0, sin(t * 1.9) * 0.25)
			if m.has_meta("string"):
				var sn := m.get_meta("string") as Node3D
				sn.visible = mo.visible
				if sn.visible:
					# from the kite down to the hero's hand (or the post)
					var hand := m.to_local(player.global_position + Vector3(0, 1.3, 0)) if m.is_inside_tree() and not using.is_empty() and str(using.e.id) == str(e.id) else at2
					var v: Vector3 = hand - mo.position
					var ln := v.length()
					if ln > 0.05:
						var yv := -v / ln
						var xv := yv.cross(Vector3.FORWARD).normalized()
						if xv.length() < 0.5:
							xv = Vector3.RIGHT
						var zv := xv.cross(yv).normalized()
						sn.transform = Transform3D(Basis(xv, yv * ln, zv), mo.position)

# ---------------------------------------------------------------- update
## The people who walk up to him in a town (fame.gd): drawn, not stood in the land.  They come along the
## way he came (so through no wall), fall in behind him, stop when he stops, and say what people say.
var fans: Array = []           # {n: Node3D, pos: Vector3, k: int}
var fan_trail: Array = []      # where he has been (Vector3), the newest last
var fan_say_t := 3.0
var fan_said := 0
var fan_label: Label3D = null
const FAN_BODIES := ["folk_youth", "folk_maiden", "folk_scholar", "folk_merchant", "folk_shopwife", "folk_porter", "folk_farmwife"]

func fan_near() -> bool:
	for f in fans:
		if (f.pos as Vector3).distance_to(player.position) < 3.2 and float(f.get("fade", 1.0)) > 0.8:
			return true
	return false

func _fans_tick(d: float) -> void:
	var pp: Vector3 = player.position
	var here := "" if is_floor() or main.top_name() != "world" else Fame.town_near(str(layer), ptile)
	var want := Fame.crowd(Game) if here != "" and building_at(ptile).is_empty() and glide.is_empty() else 0
	if fan_trail.is_empty() or (fan_trail[fan_trail.size() - 1] as Vector3).distance_to(pp) > 0.7:
		fan_trail.append(pp)
		if fan_trail.size() > 80:
			fan_trail.pop_front()
	# somebody new notices him: from as far back along his own way as is remembered
	if fans.size() < want and fan_trail.size() >= 14 and (fans.is_empty() or float(fans[fans.size() - 1].get("fade", 1.0)) > 0.6):
		var bodies: Array = Rooms.INDOOR_BODIES.get(area_id, FAN_BODIES)
		var k := fans.size() + int(Game.day) * 3
		var body := str(bodies[k % bodies.size()])
		if Assets.PEOPLE.has(body) and Assets.has(Assets.PEOPLE[body]):
			var fnode: Node3D = Assets.person(body)
			scene3d.add_child(fnode)
			fans.append({"n": fnode, "pos": fan_trail[0], "k": k, "fade": 0.0, "gone": false})
	for i in range(fans.size() - 1, -1, -1):
		var f: Dictionary = fans[i]
		var fn: Node3D = f.n
		if i >= want:
			f.gone = true
		f.fade = clampf(float(f.fade) + (-d * 1.5 if f.gone else d * 1.2), 0.0, 1.0)
		if f.gone and float(f.fade) <= 0.0:
			fn.queue_free()
			fans.remove_at(i)
			continue
		# his place: a few paces back along the way, a little to one side
		var back := mini(fan_trail.size() - 1, 4 + i * 2)
		var goal: Vector3 = fan_trail[fan_trail.size() - 1 - back]
		var side := Vector3(-float(facing.y), 0, float(facing.x)) * (0.55 if i % 2 == 0 else -0.55)
		goal += side
		var to := goal - (f.pos as Vector3)
		to.y = 0.0
		var dist := to.length()
		var walking := dist > 0.25
		if walking:
			var sp := (TS / STEP_T) * (1.25 if dist > 3.0 else 0.9)
			f.pos = (f.pos as Vector3) + to.normalized() * minf(dist, sp * d)
			fn.rotation.y = lerp_angle(fn.rotation.y, atan2(to.x, to.z), 1.0 - exp(-d * 10.0))
		else:
			var look := pp - (f.pos as Vector3)
			fn.rotation.y = lerp_angle(fn.rotation.y, atan2(look.x, look.z), 1.0 - exp(-d * 6.0))
		f.pos.y = ground_y(f.pos)
		fn.position = f.pos
		fn.scale = Vector3.ONE * (0.92 + 0.08 * float(i % 3)) * float(f.fade)
		Models.anim_person(fn, t + i * 0.37, walking)
	# what is said behind him
	fan_say_t -= d
	if fan_label != null and fan_say_t < 3.5:
		fan_label.queue_free()
		fan_label = null
	if fan_say_t <= 0.0 and not fans.is_empty():
		fan_say_t = 6.5
		fan_said += 1
		var sf: Dictionary = fans[fan_said % fans.size()]
		var ln := Fame.line(Game, fan_said + int(Game.day))
		# (the Underclothes release: what a heroine's crowd says is said of her, voice.gd)
		if Fashion.fem(Game.hero):
			ln = Voice.her(ln)
		if Fame.gift_due(Game, here) and fan_near() and fan_said % 2 == 0:
			ln = "For you. Please. (Enter)"
		if ln != "" and float(sf.fade) > 0.8:
			fan_label = _label(sf.n, ln, 2.15, Color("f4ecd8"), 26)

func _process(d: float) -> void:
	t += d
	if not headless() and player != null:
		_fans_tick(d)
	if banner_t > 0.0:
		banner_t -= d
	# a region is announced once he has stayed in it a moment (see _enter_region)
	if announced != area_id and area_id != "":
		pending_t += d
		if pending_t >= ANNOUNCE_AFTER:
			_announce(false)
	# respawn defeated enemies after a while (only when away from them)
	for k in Game.defeated.keys():
		if Game.playtime - Game.defeated[k] > 150.0:
			var e = find_ent(k)
			if e == null or maxi(absi(e.pos.x - ptile.x), absi(e.pos.y - ptile.y)) > 6:
				Game.defeated.erase(k)
	var active: bool = main.top_name() == "world"
	if ambush_t >= 0.0 and t - ambush_t >= Impact.AMBUSH_SHOW:
		# (the Sword's Wake: the pack struck first has been seen to fly back; now it fights, reeling)
		var ae := ambush_e
		ambush_t = -1.0
		ambush_e = {}
		var an: Node3D = ent_nodes.get(ae.get("id", ""))
		if an != null:
			an.position = Vector3(Terrain3D.world_pos(ae.pos).x + off.x, an.position.y, Terrain3D.world_pos(ae.pos).z + off.z)
			an.rotation.z = 0.0
			an.remove_meta("knock")
		if active:
			main.start_encounter(ae, true)
	if not trip.is_empty():
		# on a ladder or the stairs: no walking until the trip is over
		_trip_step(d)
	elif not using.is_empty() and (active or bool(using.get("scene", false))):
		# doing something (props.gd): no walking until it is done (and a thing done through a scene,
		# a memory of Yue Ling's, goes on under the conversation)
		_use_step()
	elif active and ambush_t < 0.0:
		if not main.bot_active:
			move_dir = _read_keys()
		_move(minf(d, 0.1))
	if not headless() and visible and not wd.is_empty():
		stream_t -= d
		if stream_t <= 0.0:
			stream_t = 0.35
			_stream(false)
		_update_view(d)
		_apply_hour()
		queue_redraw()
	# scenery between the camera and the hero turns see-through (shader global, see mb.gd);
	# parked far away whenever the world is not the screen being shown
	if not headless():
		var hp := Vector3(0, -1000, 0)
		if active and visible and cam_override == null:
			hp = _player_pos() + Vector3(0, 1.0, 0)
		RenderingServer.global_shader_parameter_set("hero_pos", hp)
		# (the Sword's Wake: the clock the mown grass grows back by, impact.gd)
		RenderingServer.global_shader_parameter_set("mow_now", t)

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
		key_lock = false
		return Vector2i.ZERO
	if key_lock:
		return Vector2i.ZERO
	if k != held_key:
		# a new press is read relative to where the camera looks now
		var f: Vector2i = FWD[cam_q]
		var r: Vector2i = RIGHT[cam_q]
		held_key = k
		held_dir = [-r, r, f, -f][k]
	return held_dir

## Whether the party is in the saddle here: riding, with a ride, out of doors (never inside a building,
## upstairs or in a cellar), not on the stairs or the Jianmu and not busy with something.
func riding_here() -> bool:
	if not Game.riding or Game.ride == "" or is_floor() or not trip.is_empty() or not using.is_empty():
		return false
	# (nothing with hooves goes up a crag, and nobody glides in the saddle: the ride waits at the foot)
	if not glide.is_empty() or air_y > 0.3 or Peaks.at(wd, ptile) > 1.2 or (move_t >= 0.0 and Peaks.at(wd, target) > 1.2):
		return false
	return building_at(ptile).is_empty() and (move_t < 0.0 or building_at(target).is_empty())

## Seconds to cross one tile: running, or faster in the saddle (Fashion.RIDES speed).
func step_time() -> float:
	if not glide.is_empty():
		return GLIDE_T * float(glide.get("span", 1.0))
	if climb != 0:
		return climb_t
	if riding_here():
		# (roads.gd: a thing on wheels is quicker on a road or a path, and slower off one)
		var rd: Dictionary = Fashion.RIDES[Game.ride]
		return STEP_T / (float(rd.speed) * Roads.pace(wd, str(rd.kind), target if move_t >= 0.0 else ptile))
	return STEP_T

## R (or the bot's "ride"): whistle up the ride and get on, or get off and send it away.
func toggle_ride() -> void:
	if Game.ride == "" or Game.rides.is_empty():
		Game.toast("You have no ride yet.")
		return
	Game.riding = not Game.riding
	if Game.riding:
		Game.toast("You ride the %s" % Fashion.RIDES[Game.ride].n)
		if is_floor() or not building_at(ptile).is_empty():
			Game.toast("(once you are out of doors)")
	else:
		Game.toast("You get down from the %s" % Fashion.RIDES[Game.ride].n)
	if not headless():
		Fx3D.dust(scene3d, _player_pos(), Color("f0f0ff"))

## The hero's model again, when the look or the outfit has changed (the wardrobe, character creation).
## `preview_id` shows another outfit for a moment (the wardrobe's cursor); "" goes back to his own.
var preview_id := ""

## the wardrobe's line for going down to the underclothes, or dressing again (main.open_wardrobe)
const UNDER_ID := "underclothes"

func preview_outfit(id: String) -> void:
	preview_id = id
	refresh_hero()

## The arms rack (Esc > Arms) shows the weapon under the cursor in his hand before it is chosen.
var preview_arm := ""

func preview_weapon(id: String) -> void:
	preview_arm = id if Game.arms.has(id) else ""
	refresh_hero()

## The Thundering Pots release: Yue Ling in the dress she wears, or the one under the wardrobe's cursor.
var preview_yue := ""
var yue_sig := "lotus"

func preview_yue_outfit(id: String) -> void:
	preview_yue = id if Game.yue_outfits.has(id) else ""
	refresh_yue()

func refresh_yue() -> void:
	var oid: String = preview_yue if preview_yue != "" else Game.yue_outfit
	if oid == yue_sig or comp == null:
		return
	yue_sig = oid
	var at := comp.transform
	var vis := comp.visible
	var old := comp
	comp = Models.yue_ling({"glow": YUE_OPTS.glow, "outfit": oid})
	comp.add_child(Models.shadow_disc(0.5))
	scene3d.add_child(comp)
	comp.transform = at
	comp.visible = vis
	old.queue_free()

func refresh_hero() -> void:
	refresh_yue()
	# (the wardrobe's "underclothes" line previews the other way of being dressed)
	var under: bool = Game.underclothes != (preview_id == UNDER_ID)
	var oid := preview_id if preview_id != "" and preview_id != UNDER_ID else Game.outfit
	var keep: String = Game.outfit
	Game.outfit = oid
	var cols := Fashion.hero_colors(Game)
	Game.outfit = keep
	var aid := preview_arm if preview_arm != "" else Arms.held(Game)
	var sig := "%s|%s|%s|%s|%s" % [str(Game.hero), oid, str(cols), aid, str(under)]
	if sig == hero_sig or player == null:
		return
	hero_sig = sig
	var at := player.transform
	var old := player
	player = Models.hero({"glow": HERO_OPTS.glow, "outfit": oid, "cols": cols, "arm": aid, "underclothes": under})
	player.add_child(Models.shadow_disc(0.55))
	scene3d.add_child(player)
	player.transform = at
	old.remove_child(hero_light)
	player.add_child(hero_light)
	old.queue_free()

func _move(d: float) -> void:
	var budget := d
	while budget > 0.0001:
		if move_t < 0.0:
			if glide_want:
				glide_want = false
				_glide_start()
			if not glide.is_empty():
				if not _glide_pick():
					return
			else:
				if move_dir == Vector2i.ZERO:
					return
				facing = move_dir
				var nt := ptile + move_dir
				var e = ent_at(nt)
				if e != null:
					move_dir = Vector2i.ZERO
					main.interact(e)
					# the key still held must be let go first, or the conversation opens again the moment
					# it closes, for ever (as on the stairs)
					key_lock = true
					return
				if not tile_free(nt):
					return
				# the beginning (cultures.gd): nobody leaves before the farewell is said
				if Game.prologue != "" and leash.x >= 0 and maxi(absi(nt.x - leash.x), absi(nt.y - leash.y)) > LEASH:
					move_dir = Vector2i.ZERO
					key_lock = true
					Game.toast("Not yet. There is a goodbye to say first.")
					return
				target = nt
				move_t = 0.0
				# the High Roads (peaks.gd): a step up or down a crag is climbed
				climb = 0 if is_floor() else Peaks.climb(wd, ptile, nt)
				if climb != 0:
					var dz := absf(Peaks.at(wd, nt) - Peaks.at(wd, ptile))
					Game.climbed += dz
					climb_t = clampf(float(CLIMB_T[0]) + float(CLIMB_T[1]) * dz, float(CLIMB_T[2]), float(CLIMB_T[3])) * (1.0 if climb > 0 else 0.75)
				# third-person follow: the camera swings round behind the direction of travel
				var q := FWD.find(facing)
				if q >= 0:
					cam_q = q
		var st := step_time()
		var need := (1.0 - move_t) * st
		if budget >= need:
			budget -= need
			ptile = target
			move_t = -1.0
			Game.tile = ptile
			if not glide.is_empty():
				_glide_arrive()
			else:
				_trample(ptile)
				_summit_check()
			var rid := Atlas.owner_id(wd, ptile)
			if rid != area_id:
				_enter_region(rid)
		else:
			move_t += budget / st
			budget = 0.0

# ---------------------------------------------------------------- the High Roads: summits and the glider
## He has come to the very top of a peak: the first time, it is told.
func _summit_check() -> void:
	if is_floor():
		return
	var pk := Peaks.summit_at(wd, ptile)
	if not pk.is_empty():
		Game.summit(str(pk.id), str(pk.n), float(pk.h))

## V: open the glider (at the next footfall, if he is running), or fold it in the air and come down.
func toggle_glide() -> void:
	if not glide.is_empty():
		glide.fold = true
		return
	if is_floor():
		Game.toast("There is no sky to glide in under a roof.")
		return
	if not trip.is_empty() or not using.is_empty() or Game.prologue != "":
		return
	glide_want = true

func gliding() -> bool:
	return not glide.is_empty()

## How many tiles a flight from where he stands would go in direction `dir` if nothing were steered
## (0 if it could not begin, or would end where nobody can stand): what somebody on a summit judges
## by eye before he leaps, and the bot by counting.
func glide_reach(dir: Vector2i) -> int:
	if is_floor():
		return 0
	var at := ptile
	var alt := Peaks.at(wd, ptile) + GLIDE_LEAP
	var n := 0
	while n < 400:
		var nt := at + dir
		var nalt := alt - GLIDE_SINK
		if not _glide_over(nt, nalt):
			return n if _landable(at) else 0
		if nalt <= Peaks.at(wd, nt) + 0.25:
			return (n + 1) if _landable(nt) else (n if _landable(at) else 0)
		at = nt
		alt = nalt
		n += 1
	return n

func _glide_start() -> void:
	if is_floor() or not trip.is_empty() or not using.is_empty():
		return
	var base := Peaks.at(wd, ptile)
	glide = {"alt": base + GLIDE_LEAP, "from": ptile, "n": 0, "fold": false, "top": base}
	climb = 0
	Game.glides += 1

## Whether the glider can pass over tile `nt` at height `alt` (above the plain): never out over the
## open sea or off the map, never into a region he has not walked into (the seals keep what they
## kept), never through a closed seal, and over a wood, a roof or anybody standing only with air to spare.
func _glide_over(nt: Vector2i, alt: float) -> bool:
	if nt.x < 1 or nt.y < 1 or nt.x >= w - 1 or nt.y >= h - 1:
		return false
	var g := grid[nt.y * w + nt.x]
	if g == MapGen.VOID or Atlas.is_sea(wd, nt) or not Game.seen.has(Atlas.owner_id(wd, nt)):
		return false
	var clear := alt - Peaks.at(wd, nt)
	var e = tile_ents.get(nt)
	if e != null and ent_visible(e):
		if e.kind == "seal":
			if not seal_open(e):
				return false
		elif clear < float(GLIDE_OVER.ent):
			return false
	if g == MapGen.WALL and clear < float(GLIDE_OVER.wood):
		return false
	if (g == MapGen.BUILDING or g == MapGen.INTERIOR) and clear < float(GLIDE_OVER.roof):
		return false
	return true

## Whether a flight can end on tile `tl`: open ground nobody stands on, out of doors, with room to
## walk away from (never a pocket shut in by trees).
func _landable(tl: Vector2i) -> bool:
	if not tile_free(tl) or grid[tl.y * w + tl.x] == MapGen.INTERIOR or ent_at(tl) != null or not Game.seen.has(Atlas.owner_id(wd, tl)):
		return false
	var seen := {tl: true}
	var q: Array = [tl]
	var i := 0
	while i < q.size() and q.size() < 140:
		var c: Vector2i = q[i]
		i += 1
		for dd in FWD:
			var n: Vector2i = c + dd
			if not seen.has(n) and tile_free(n) and ent_at(n) == null:
				seen[n] = true
				q.append(n)
	return q.size() >= 140

## The next tile of a flight (true), or its end (false).  The arrow keys turn it; back folds it.
func _glide_pick() -> bool:
	if move_dir != Vector2i.ZERO:
		if move_dir == -facing:
			glide.fold = true
		elif move_dir != facing:
			facing = move_dir
			var q := FWD.find(facing)
			if q >= 0:
				cam_q = q
	glide.erase("span")
	var nt := ptile + facing
	var nalt := float(glide.alt) - GLIDE_SINK
	if bool(glide.fold) or not _glide_over(nt, nalt):
		_glide_down()
		return false
	if nalt <= Peaks.at(wd, nt) + 0.25:
		# the ground comes up to meet him: he lands on it, if anybody could stand there
		if not _landable(nt):
			_glide_down()
			return false
		glide.touch = true
	target = nt
	move_t = 0.0
	return true

func _glide_arrive() -> void:
	glide.alt = float(glide.alt) - GLIDE_SINK * float(glide.get("span", 1.0))
	glide.n = int(glide.n) + 1
	Game.glided += 1
	if glide.get("touch", false):
		_glide_end()

## The flight can go no further: he comes down where he is, or on the nearest ground that will have
## him (and if there is none, the wind takes him back where he leapt from).
func _glide_down() -> void:
	if _landable(ptile):
		_glide_end()
		return
	var best := Vector2i(-1, -1)
	for r in range(1, 9):
		var bd := 1 << 30
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := ptile + Vector2i(dx, dy)
				if dx * dx + dy * dy < bd and _landable(c):
					bd = dx * dx + dy * dy
					best = c
		if best.x >= 0:
			break
	if best.x < 0:
		best = glide.from
	if best == ptile:
		_glide_end()
		return
	glide.span = clampf(Vector2(best - ptile).length(), 1.0, 8.0)
	glide.alt = maxf(float(glide.alt), Peaks.at(wd, best) + GLIDE_SINK * float(glide.span))
	glide.touch = true
	glide.fold = false
	target = best
	move_t = 0.0

func _glide_end() -> void:
	var n := int(glide.n)
	air_y = maxf(float(glide.alt) - Peaks.at(wd, ptile), 0.0)
	var fell := float(glide.top) - Peaks.at(wd, ptile)
	glide = {}
	move_dir = Vector2i.ZERO
	key_lock = true
	Game.glide_done(n, fell)
	_summit_check()
	if not headless():
		Fx3D.dust(scene3d, wpos(ptile) + Vector3(0, ground_y(wpos(ptile)) - off.y, 0), Color(Look.theme(theme_name).path))

func face_entity():
	var e = ent_at(ptile + facing)
	if e == null:
		e = walk_props.get(ptile + facing)
	if e == null and not is_floor() and not wd.is_empty():
		# one of the people of the towns standing (or walking) there (folk.gd)
		var fs := Game.cur_step()
		var want := Callable()
		if not fs.is_empty() and str(fs.kind) == "folk":
			want = func(q: Dictionary) -> bool: return Folk.is_role(q, str(fs.role)) and not Game.folk_has(fs, str(q.id))
		var fp := Folk.at_tile(wd, ptile + facing, Game.clock, want)
		if not fp.is_empty():
			e = {"kind": "folk", "id": fp.id, "n": fp.n, "p": fp, "pos": ptile + facing, "area": fp.area}
	return e

# ---------------------------------------------------------------- 3D view update
func ground_y(p: Vector3) -> float:
	if is_cave():
		return _ground(bundles[layer], p)
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
	if is_cave():
		# up and down the half-metre steps of a cave's floor: the feet follow them a moment behind
		cave_goal = gy
		if cave_snap:
			cave_y = gy
			cave_snap = false
		pp.y = cave_y + _trip_lift()
		return pp
	pp.y = lerpf(maxf(iy0, gy) if iy0 > -INF else gy, maxf(iy1, gy) if iy1 > -INF else gy, clampf(move_t, 0.0, 1.0)) + _trip_lift()
	if not glide.is_empty():
		# in the air (peaks.gd): as far above the ground as the flight is above the rock under it, the
		# leap it began with eased in over its first tile
		var k := clampf(move_t, 0.0, 1.0) if move_t >= 0.0 else 0.0
		var a := float(glide.alt) - GLIDE_SINK * float(glide.get("span", 1.0)) * k
		a -= GLIDE_LEAP * clampf(1.0 - (float(glide.n) + k) * 1.5, 0.0, 1.0)
		pp.y += maxf(a - Peaks.rise(wd, (pp.x - off.x) / TS, (pp.z - off.z) / TS), 0.0)
	else:
		pp.y += air_y
	return pp

func _cam_goal(pp: Vector3, a: float) -> Array:
	var fwd := Vector3(sin(a), 0, -cos(a))
	if is_cave():
		# under a roof the camera comes in close and low behind the hero, and looks along the cave
		return [pp - fwd * CAVE_CAM_DIST + Vector3(0, CAVE_CAM_H, 0), pp + Vector3(0, 1.3, 0) + fwd * 3.4]
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

## how far off the people, packs and things of the land are drawn (metres), and the big ones
const ENT_SHOW := 92.0
const ENT_SHOW_BIG := 150.0
const ENT_BIG := ["boss", "prop", "machine", "mark", "hold", "seal", "ladder", "abode", "stele", "portal"]
var frame_n := 0

func _update_view(d: float) -> void:
	if is_cave():
		cave_y = lerpf(cave_y, cave_goal, 1.0 - exp(-d * 18.0))
	var pp := _player_pos()
	if not using.is_empty():
		# doing something (props.gd): the hero and Yue Ling are placed and moved by it
		_use_pose(d)
	elif riding_here():
		_ride_view(d, pp)
	else:
		if mount != null:
			mount.visible = false
		player.position = pp
		# the High Roads (peaks.gd): in the air under the kite, or on a rock face hand over hand
		var flying := not glide.is_empty() or air_y > 0.45
		if glide.is_empty():
			air_y = lerpf(air_y, 0.0, 1.0 - exp(-d * 13.0))
		var walking := move_t >= 0.0
		var scaling := not flying and climb != 0 and (walking or _steep_here())
		if not scaling:
			scale_in = 0.0
		# (a climber faces the rock, on the way down as on the way up)
		var face_dir := -facing if scaling and climb < 0 else facing
		var want_yaw := atan2(float(face_dir.x), float(face_dir.y))
		player.rotation.y = lerp_angle(player.rotation.y, want_yaw, 1.0 - exp(-d * 14.0))
		player.rotation.x = lerpf(player.rotation.x, 0.24 if scaling else 0.0, 1.0 - exp(-d * 10.0))
		# on the road the hero runs (the light-body dash; the old walk cycle slid along at 12 m/s); in a
		# conversation whoever is speaking talks with their hands and mouth
		# (and under a low roof, in a cave, bent double with a hand up before the brow: caves.gd)
		var gait := "run"
		if walking and is_cave() and mini(Caves.headroom(Caves.layout(area_id, int(wd.level)), ptile), Caves.headroom(Caves.layout(area_id, int(wd.level)), target)) <= Caves.LOW:
			gait = "duck"
		if flying:
			Models.anim_person(player, t, true, false, "glide")
		elif scaling:
			# (hand over hand while he moves; hanging still, he only shifts his weight)
			scale_in += d
			climb_clk += d * (1.0 if walking or scale_in < 0.25 else 0.08)
			Models.anim_person(player, climb_clk, true, false, "scale")
		else:
			Models.anim_person(player, t, walking, false, gait if walking else ("talk" if speaker() == "Lin Feng" else ""))
		_kite(player, "hero", not glide.is_empty(), d, Color(HERO_OPTS.cape), Color(HERO_OPTS.trim))
		# a puff of dust at each footfall
		var sp := fmod(t * 9.0 / PI, 2.0)
		if walking and not flying and not scaling and int(sp) != step_side:
			step_side = int(sp)
			Fx3D.dust(scene3d, pp, Color(Look.theme(theme_name).path))
		# companion trails the hero
		comp.visible = Game.companion
		if Game.companion:
			if flying:
				# she flies off his wing, a little behind and a little above
				var fw := Vector3(facing.x, 0, facing.y)
				var wing := pp - fw * 1.5 + Vector3(-facing.y, 0, facing.x) * 2.3 + Vector3(0, 0.35 + sin(t * 1.3) * 0.15, 0)
				comp_pos = comp_pos.lerp(wing, 1.0 - exp(-d * 6.0))
				comp_pos.y = maxf(comp_pos.y, _stand_y(bundles[layer], comp_pos))
				comp.position = comp_pos
				comp.rotation.y = lerp_angle(comp.rotation.y, want_yaw, 1.0 - exp(-d * 10.0))
				comp.rotation.x = 0.0
				comp_run = true
				Models.anim_person(comp, t + 1.0, true, false, "glide")
			else:
				# off the hero's shoulder rather than straight behind, so she never stands between the
				# follow camera and him
				var cs: Array = Models.companion_step(comp_pos, pp, facing, want_yaw, comp_run, speaker() != "", d)
				comp_pos = cs[0]
				var cy := _stand_y(bundles[layer], comp_pos)
				# (she comes down out of the air as he does, and never hangs in it)
				comp_pos.y = cy if comp.position.y - cy < 0.3 else lerpf(comp.position.y, cy, 1.0 - exp(-d * 13.0))
				comp.position = comp_pos
				comp_run = cs[2]
				var c_scale := (comp_run or scaling) and _steep_at(comp_pos)
				comp.rotation.y = lerp_angle(comp.rotation.y, want_yaw if c_scale else cs[1], 1.0 - exp(-d * 10.0))
				comp.rotation.x = lerpf(comp.rotation.x, 0.24 if c_scale else 0.0, 1.0 - exp(-d * 10.0))
				if c_scale:
					Models.anim_person(comp, (t if comp_run else climb_clk) + 0.65, true, false, "scale")
				else:
					Models.anim_person(comp, t + 1.0, comp_run, false, gait if comp_run else ("talk" if speaker() == "Yue Ling" else ""))
			_kite(comp, "comp", not glide.is_empty(), d, Color("e86a9a"), Color(YUE_OPTS.ribbon))
	# entities of the regions on show
	frame_n += 1
	var seen_from: Vector3 = pp if cam_override == null else cam.global_position
	for k in views:
		var v: Dictionary = views[k]
		if not v.shown:
			continue
		var vb: Dictionary = bundles[v.bundle]
		for i in v.nodes:
			var e: Dictionary = v.ents[i]
			var n: Node3D = v.nodes[i]
			# nobody and nothing is drawn from further off than it can be made out (ENT_SHOW; the big
			# things, a lord, a building's furniture, a ladder between realms, from further): every model
			# of every region on show used to be handed to the renderer every frame, forty thousand
			# triangles a head, and the story asked whether each of them should be there
			var dist := n.position.distance_to(seen_from)
			if dist > (ENT_SHOW_BIG if e.kind in ENT_BIG else ENT_SHOW):
				if n.visible:
					n.visible = false
				continue
			# (beyond the reach of anything that could change it this frame, the story is asked now and then)
			if dist > 46.0 and n.visible and (frame_n + i) % 8 != 0:
				continue
			var vis := ent_visible(e)
			n.visible = vis
			if not vis:
				continue
			if e.kind == "mark" and str(n.get_meta("key", "")) != Marks.key(Game, e):
				_mark_model(e, n)
			if e.kind == "hold" and str(n.get_meta("key", "")) != Hold.key(Game, e):
				_hold_model(e, n)
			dist = n.position.distance_to(pp)
			if dist > 46.0:
				continue
			_animate_ent(e, n, pp, dist, d, vb)
	_update_folk(d, pp)
	_update_havoc(d, pp)
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
		# (the Lost Horse release: coming in at a door says what the house is, storey by storey: rooms.gd)
		if key != "" and lv == 0 and not is_floor() and not key.begins_with(str(inside).get_slice("#", 0) + "#"):
			var bd9 := building_at(ptile if move_t < 0.0 or move_t > 0.5 else target)
			if not bd9.is_empty() and Rooms.uses_text(bd9) != "":
				Game.toast("%s: %s" % [str(bd9.n), Rooms.uses_text(bd9)])
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

## Whether the rock under the hero is too steep to stand on (so that he hangs on it, not stands).
func _steep_here() -> bool:
	return _steep_tile(ptile)

func _steep_tile(tl: Vector2i) -> bool:
	if is_floor():
		return false
	var a := Peaks.at(wd, tl)
	if a < 0.5:
		return false
	for dd in FWD:
		if absf(Peaks.at(wd, tl + dd) - a) > Peaks.STEEP * 1.7:
			return true
	return false

func _steep_at(p: Vector3) -> bool:
	return _steep_tile(Vector2i(floori((p.x - off.x) / TS), floori((p.z - off.z) / TS)))

## The cloud-kite over the head of model `m` (glider.gd): made the first time it is opened, and
## opened and folded by growing and shrinking, as paper and bamboo do in the stories.
func _kite(m: Node3D, key: String, on: bool, d: float, col: Color, trim: Color) -> void:
	var k: Node3D = kites.get(key)
	if k == null or not is_instance_valid(k) or k.get_parent() != m:
		if not on:
			return
		k = Glider.build(col, trim)
		k.scale = Vector3.ONE * 0.05
		m.add_child(k)
		kites[key] = k
	var sc := lerpf(k.scale.x, 1.0 if on else 0.0, 1.0 - exp(-d * (9.0 if on else 16.0)))
	k.visible = sc > 0.04
	k.scale = Vector3.ONE * maxf(sc, 0.01)
	k.position = Vector3(0.0, 2.04, 0.1)
	k.rotation = Vector3(-0.1 + sin(t * 2.3) * 0.03, 0.0, sin(t * 1.7) * 0.05)

## In the saddle: the ride stands where the hero would, turned the way he goes, galloping or standing;
## he sits on it (astride a beast, standing on a vehicle) and Yue Ling behind him, both moving with it.
func _ride_view(d: float, pp: Vector3) -> void:
	if mount == null or mount_id != Game.ride:
		if mount != null:
			mount.queue_free()
		mount = Models.ride(Game.ride)
		mount_id = Game.ride
		scene3d.add_child(mount)
		Fx3D.dust(scene3d, pp, Color("f0f0ff"))
	var r: Dictionary = Fashion.RIDES[Game.ride]
	mount.visible = true
	var moving := move_t >= 0.0
	ride_clk += d * (1.0 if not moving else float(r.speed))
	var want_yaw := atan2(float(facing.x), float(facing.y))
	mount.position = pp
	mount.rotation.y = lerp_angle(mount.rotation.y, want_yaw, 1.0 - exp(-d * 10.0))
	var rise := Models.anim_ride(mount, ride_clk, moving)
	var basis := Basis(Vector3.UP, mount.rotation.y)
	if str(r.kind) == "carriage":
		# (the Lost Horse release: a carriage is sat in: the hero and Yue Ling on its first two seats, and
		# whoever is being carried on the rest; a seated clip lowers the hips itself, so each stands
		# where their feet would be under the seat)
		_carriage_view(r, pp, basis)
		return
	_drop_passengers()
	var standing := str(r.kind) == "vehicle"
	var clip := "ride_stand" if standing else ("ride" if moving else "ride_idle")
	# the hips go to the seat (astride, the clip keeps them 0.88 m over the model's feet); standing on
	# a deck, the feet do
	var lift := 0.9 if not standing else 0.0
	player.position = pp + basis * (Vector3(r.seat) + rise) - Vector3(0, lift, 0)
	player.rotation = Vector3(0, mount.rotation.y, 0)
	Models.anim_person(player, t, false, false, clip if Assets.has_clip(player, clip) else "sit")
	comp.visible = Game.companion
	if Game.companion:
		comp.position = pp + basis * (Vector3(r.pillion) + rise) - Vector3(0, lift, 0)
		comp.rotation = Vector3(0, mount.rotation.y, 0)
		comp_pos = comp.position
		comp_run = false
		Models.anim_person(comp, t + 1.0, false, false, clip if Assets.has_clip(comp, clip) else "sit")
	# a little dust from the hooves, or the wake of a vehicle
	var sp := fmod(t * 6.0, 2.0)
	if moving and int(sp) != step_side:
		step_side = int(sp)
		Fx3D.dust(scene3d, pp, Color(Look.theme(theme_name).path) if not standing else Color("e8f0ff"))

## Who sits where in a carriage (fashion.gd `seats`): the hero, Yue Ling, and the passengers being
## carried for a fare (offices.gd), each a model of their own that rides with it.
var pass_nodes: Array = []
var pass_key := ""
const SEAT_DROP := 0.46

func _carriage_view(r: Dictionary, pp: Vector3, basis: Basis) -> void:
	var seats: Array = r.seats
	player.position = pp + basis * (seats[0] as Vector3) - Vector3(0, SEAT_DROP, 0)
	player.rotation = Vector3(0, mount.rotation.y, 0)
	Models.anim_person(player, t, false, false, "sit_bench")
	comp.visible = Game.companion
	if Game.companion:
		Assets.lend_clips(comp)
		comp.position = pp + basis * (seats[1] as Vector3) - Vector3(0, SEAT_DROP, 0)
		comp.rotation = Vector3(0, mount.rotation.y, 0)
		comp_pos = comp.position
		comp_run = false
		Models.anim_person(comp, t + 1.0, false, false, "sit_bench")
	var key := ",".join(Game.passengers.map(func(p): return str(p.id)))
	if key != pass_key:
		_drop_passengers()
		pass_key = key
		for p in Game.passengers:
			var pn: Node3D = Assets.person(str(p.asset)) if Assets.PEOPLE.has(str(p.asset)) and Assets.has(Assets.PEOPLE[str(p.asset)]) else Models.person(Color("8a7a6a"), Color("2a2a3a"), {})
			Assets.lend_clips(pn)
			scene3d.add_child(pn)
			pass_nodes.append(pn)
	for i in pass_nodes.size():
		if i + 2 >= seats.size():
			(pass_nodes[i] as Node3D).visible = false
			continue
		var pn2: Node3D = pass_nodes[i]
		pn2.visible = true
		pn2.position = pp + basis * (seats[i + 2] as Vector3) - Vector3(0, SEAT_DROP, 0)
		pn2.rotation = Vector3(0, mount.rotation.y, 0)
		Models.anim_person(pn2, t + 2.0 + i, false, false, "sit_bench")

func _drop_passengers() -> void:
	for pn in pass_nodes:
		(pn as Node3D).queue_free()
	pass_nodes = []
	pass_key = ""

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
	# one of the people of the towns (folk.gd), the one Lin Feng is talking to
	if folk_talking != "" and folk_nodes.has(folk_talking):
		var fn: Node3D = folk_nodes[folk_talking]
		if fn.visible and str(fn.get_meta("name", "")) == who:
			return [fn.get_meta("model"), float(fn.get_meta("seed", 0))]
	return []

## A new line of dialogue begins: whoever it belongs to plays the gesture it calls for (Data.emote_for),
## and whoever is listening answers it (a bow for a gift, a wave for a wave, a nod for grief or a joke).
func _cue_line(line: Array) -> void:
	var ec: Array = Data.emote_for(line)
	var who: String = ec[0]
	var g: String = ec[1]
	if who != "Lin Feng" and who != "Yue Ling" and who != "Narrator":
		cue_npc = who
	var a := _actor(who)
	if g != "" and not a.is_empty() and Assets.has_clip(a[0], g):
		Models.act(a[0], g, t + float(a[1]))
	# the face the line is said with (faces.gd): its own cue or what its words sound like, worn for as
	# long as a line is usually read; a gesture's own face otherwise
	var fc := Faces.for_line(line)
	if fc != "" and not a.is_empty():
		Faces.wear(a[0], fc, 4.5)
	if g == "":
		return
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
	# a scene the two of them play out together (a memory given back, the lotus pond): narration and
	# his lines frame the pair of them, as hers do, not him and the air ahead of him (side by side
	# across that line, she stood hidden behind him)
	var pair := false
	if other.is_empty() and Game.companion and bool(using.get("scene", false)):
		other = [comp, 1.0]
		pair = true
	var a3 := pp + Vector3(0, 1.45, 0)
	if pair:
		# (where he is, on the thing they share, not the tile he stepped onto it from)
		a3 = player.global_position + Vector3(0, 1.45, 0)
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
	# (the side the camera is on already; for the two of them, the side he came in by: he walked over
	# that ground to get there)
	var lean: Vector3 = -(using.dir as Vector3) if pair else cam.position - mid
	if side.dot(lean) < 0.0:
		side = -side
	var indoor: bool = inside != "" or is_floor()
	var dist := clampf(a3.distance_to(b3) * 0.9 + 3.4, 4.2, 8.5)
	# not into a wood: if the ground on that side is trees (or a wall, or water) and the other side
	# is open, the camera goes round to the other side
	if not indoor and not _open_at(mid + side * dist) and _open_at(mid - side * dist):
		side = -side
	var goal := mid + side * (dist if indoor else _cam_reach(mid, side, dist)) + Vector3(0, 0.5 + (3.2 if indoor else 0.4), 0)
	if sp == "Narrator" or sp == "":
		# narration: a slow drift round the scene
		cine_a += d * 0.12
		var drift := side.rotated(Vector3.UP, sin(cine_a) * 0.5)
		goal = mid + drift * ((dist + 1.5) if indoor else _cam_reach(mid, drift, dist + 1.5)) + Vector3(0, 1.4 + (3.0 if indoor else 0.6), 0)
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
	# the hours of the wild (habits.gd): what the pack is doing this hour decides how far it ranges, how
	# fast, how much of the time it is on the move, and whether it is lying asleep or circling together
	var act := Habits.act_of_group(Game, e.group)
	var hi: Dictionary = Habits.info(act)
	var rg: Array = hi.range
	var lie: bool = hi.get("lie", false)
	var ring: bool = hi.get("ring", false)
	var run: bool = hi.get("run", false)
	var walking := (dist > 9.0 or run) and cyc < float(rg[2])
	if str(n.get_meta("act", "")) != act:
		n.set_meta("act", act)
		var hl: Label3D = n.get_meta("hab", null)
		if hl != null:
			hl.text = "" if act in ["watch", "forage"] else ("z z z" if lie else str(hi.word))
			hl.modulate = hi.col
	var k := 1.0 - exp(-d * 3.0)
	for i in ms.size():
		var mk: Node3D = ms[i]
		if not mk.has_meta("home"):
			mk.set_meta("home", mk.position)
			mk.set_meta("prog", seed_ + i * 1.3)
		var prog: float = mk.get_meta("prog")
		var shape: String = mk.get_meta("shape", "")
		var r := (1.6 if i == 0 else 1.0) * float(rg[0])
		if walking:
			prog += d * 0.32 * float(rg[1]) / maxf(r, 0.6)
			mk.set_meta("prog", prog)
		var home: Vector3 = mk.get_meta("home")
		var floats := shape in ["wisp", "jelly", "storm", "ray"]
		if lie:
			# asleep: down where it stood, on its side (a thing that floats sinks to the ground and dims its bob)
			mk.position = mk.position.lerp(home + Vector3(0.0, 0.0 if floats else 0.18, 0.0), k)
			mk.rotation.z = lerp_angle(mk.rotation.z, 0.0 if floats else (1.25 if i % 2 == 0 else -1.25), k)
			mk.rotation.y = lerp_angle(mk.rotation.y, seed_ + i * 2.1, k)
			# (breathing: the idle clip at a third of its pace)
			Models.anim_monster(mk, t * 0.3, i * 1.7 + e.pos.x, "idle")
			continue
		mk.rotation.z = lerp_angle(mk.rotation.z, 0.0, k)
		if ring:
			# gathered: round and round a common centre, a flock settling to roost, a revel of ghosts
			var a := prog * 0.8 + TAU * float(i) / float(ms.size())
			var c := Vector3(0.0, home.y, -0.2)
			mk.position = mk.position.lerp(c + Vector3(cos(a), 0.0, sin(a)) * 1.25, k)
			mk.rotation.y = lerp_angle(mk.rotation.y, atan2(-sin(a), cos(a)) + PI * 0.5, k)
			Models.anim_monster(mk, t, i * 1.7 + e.pos.x, "walk" if Assets.has_clip(mk, "walk") else "idle")
		else:
			var off2 := Vector3(sin(prog) * r, 0.0, sin(prog * 2.0) * r * 0.45)
			var vel := Vector3(cos(prog), 0.0, cos(prog * 2.0) * 0.9)
			mk.position = mk.position.lerp(home + off2, clampf(k * 3.0, 0.0, 1.0))
			if walking:
				mk.rotation.y = lerp_angle(mk.rotation.y, atan2(vel.x, vel.z), 1.0 - exp(-d * 4.0))
			else:
				mk.rotation.y = lerp_angle(mk.rotation.y, 0.0, k)
			var clip := "idle"
			if walking:
				clip = "run" if run and Assets.has_clip(mk, "run") else ("walk" if Assets.has_clip(mk, "walk") else "idle")
			Models.anim_monster(mk, t * (1.5 if run and walking and clip == "walk" else 1.0), i * 1.7 + e.pos.x, clip)
		if floats:
			mk.position.y = home.y + 0.15 * sin(t * 1.6 + i)

func _animate_ent(e: Dictionary, n: Node3D, pp: Vector3, dist: float, d: float, vb: Dictionary = {}) -> void:
	match e.kind:
		"prop":
			_animate_prop(e, n, dist)
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
			# the Living Land release: at work at their place by day, asleep at it late at night, until the
			# hero comes close (folk.gd POSTS); the thing in their hands goes with the work
			var job: Array = [] if talking or dist < 4.5 else Folk.post(str(e.get("asset", e.id)), Clock.hour(Game))
			if not job.is_empty() and not Assets.has_clip(m, str(job[0])):
				job = []
			_post_hold(n, m, "" if job.is_empty() else str(job[1]))
			if not job.is_empty():
				Models.anim_person(m, t + e.pos.x, false, false, str(job[0]))
				m.rotation.y = lerp_angle(m.rotation.y, 0.0, 1.0 - exp(-d * 3.0))
			else:
				Models.anim_person(m, t + e.pos.x, false, false, "talk" if talking else "")
			if dist < 9.0 and job.is_empty():
				var dv := pp - n.position
				m.rotation.y = lerp_angle(m.rotation.y, atan2(dv.x, dv.z), 1.0 - exp(-d * 5.0))
			var s := Game.cur_step()
			var mark: Label3D = n.get_meta("mark")
			# (a fated encounter's chapter, fate.gd, and the Part XIII and XIV steps of people in any order)
			# (and Part XV: the people who can still tie a thread for Yue Ling)
			var quest: bool = not s.is_empty() and ((s.kind == "talk" or s.kind == "fate") and s.npc == e.id
				or (s.kind == "visits" or s.kind == "fates") and str(e.id) in s.npcs and not Game.visited.has(str(e.id))
				or s.kind == "threads" and str(e.id) in s.npcs and not Game.threads.has(str(e.id))
				or s.kind == "rally" and str(e.id) in s.npcs and not Game.rallied.has(str(e.id)))
			mark.visible = quest
			if quest and e.get("fate", false):
				mark.modulate = Fate.THREADS[Fate.thread_of_npc(str(e.id))].col
			if quest:
				mark.position.y = 3.1 + sin(t * 4.0) * 0.15
		"enemy", "boss":
			if n.has_meta("knock"):
				# (struck first, impact.gd: flying back under its own tween)
				return
			var ms: Array = n.get_meta("models")
			if e.kind == "enemy":
				_wander(ms, e, n, dist, d)
			else:
				for i in ms.size():
					Models.anim_monster(ms[i], t, i * 1.7 + e.pos.x)
			if dist < 10.0 and not (e.kind == "enemy" and str(n.get_meta("act", "")) == "sleep"):
				var dv2 := pp - n.position
				n.rotation.y = lerp_angle(n.rotation.y, atan2(dv2.x, dv2.z), 1.0 - exp(-d * 2.0))
			var base_y := _ground(vb, n.position) if not vb.is_empty() else ground_y(n.position)
			# (a pack asleep, habits.gd, neither bobs nor hovers)
			var asleep: bool = e.kind == "enemy" and str(n.get_meta("act", "")) == "sleep"
			n.position.y = base_y + (0.0 if asleep else sin(t * 2.2 + e.pos.x) * 0.06 + (0.35 if e.kind == "enemy" and Data.ENEMIES[e.group[0].id].shape in ["wisp", "jelly", "bird", "storm", "ray"] else 0.0))
		"machine":
			Machines.animate(n.get_meta("model"), t + float(e.pos.x))
			(n.get_meta("label") as Label3D).visible = dist < 12.0
		"mark", "hold":
			if n.has_meta("model"):
				Machines.animate(n.get_meta("model"), t + float(e.pos.x))
			(n.get_meta("label") as Label3D).visible = dist < 12.0
		"abode":
			var opened: bool = Game.abodes.has(e.id)
			if opened != bool(n.get_meta("open", false)):
				var old: Node3D = n.get_meta("model")
				var nm := Models.sealed_cave(opened)
				nm.rotation.y = old.rotation.y
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

## What a named townsperson holds at work (folk.gd POSTS), swapped as the work changes.
func _post_hold(n: Node3D, m: Node3D, what: String) -> void:
	if str(n.get_meta("hold", "")) == what:
		return
	if n.has_meta("hold_node"):
		var old = n.get_meta("hold_node")
		if old != null and is_instance_valid(old):
			(old as Node).queue_free()
		n.remove_meta("hold_node")
	n.set_meta("hold", what)
	if what != "":
		var hn := _hold_in_hand(m, what, Folk.hand_of(what))
		if hn != null:
			n.set_meta("hold_node", hn)

# ---------------------------------------------------------------- things that break (havoc.gd)
## Walking onto a tile with something on it: at the gallop it is smashed, on foot it is only jostled.
func _trample(tile: Vector2i) -> void:
	if is_floor() or wd.is_empty():
		return
	var b := Havoc.at_tile(wd, tile)
	if b.is_empty() or Havoc.is_broken(Game, b):
		return
	if riding_here():
		_smash(b, Vector3(facing.x, 0, facing.y), "ride")
	else:
		var bn := _brk_node(str(b.id))
		if bn != null:
			bn.set_meta("jostle", t)

func _brk_node(id: String) -> Node3D:
	for k in views:
		var bn = views[k].get("brk", {}).get(id)
		if bn != null:
			return bn
	return null

## F: Lin Feng swings his sword at what is in front of him, and whatever it meets answers it
## (impact.gd): a pack of monsters is struck first (knocked back, and the battle opens with it
## reeling), an obstacle of the story takes a blow, the things people leave about break (havoc.gd),
## trees fall, rocks shatter, the grass is mown and the water splashes; and the townsfolk nearby start
## and stare.
func strike() -> void:
	if t - strike_t < 0.5 or not using.is_empty() or not trip.is_empty() or ambush_t >= 0.0:
		return
	strike_t = t
	Game.strikes += 1
	# (each of the Eight Arms is struck with in its own way: arms.gd)
	Models.act(player, Arms.strike_clip(player), t)
	var fwd := Vector3(facing.x, 0, facing.y)
	if not is_floor() and not wd.is_empty():
		var tiles: Array = []
		for dt in Impact.reach(facing):
			tiles.append(ptile + dt)
		if _blow(tiles, fwd):
			return
	if headless():
		return
	var pp := _player_pos()
	Fx3D.slash(scene3d, pp + fwd * 1.1 + Vector3(0, 1.0, 0), Color(0.78, 0.9, 1.0), atan2(fwd.x, fwd.z), 2.6)
	if not is_floor():
		# the cut goes through the grass: it is mown in an arc in front of the blade, the clippings fly
		Impact.mow(pp + fwd * 1.6, 1.9, t)
		Fx3D.leaf_spiral(scene3d, pp + fwd * 1.6 + Vector3(0, 0.3, 0), Color(Look.theme(theme_name).g2).lightened(0.15), 0.7)
	_folk_start(pp, 7.0)

## G: the sword qi (impact.gd).  A crescent of qi thrown from the blade flies seven tiles ahead and
## everything along its way feels it, as if struck: the first pack it reaches is struck first, the
## obstacles and the things people leave about take a blow, trees fall, rocks shatter, grass is mown.
## It costs an eighth of Lin Feng's qi.
func qi_wave() -> void:
	if t - wave_t < Impact.WAVE_COOL or not using.is_empty() or not trip.is_empty() or ambush_t >= 0.0 or is_floor() or wd.is_empty():
		return
	var cost := float(Game.max_qi(0)) * Impact.WAVE_QI
	if float(Game.qi[0]) < cost:
		Game.toast("Not enough qi for the sword qi (G)")
		return
	Game.qi[0] = float(Game.qi[0]) - cost
	wave_t = t
	Game.waves += 1
	Models.act(player, "cast", t)
	var fwd := Vector3(facing.x, 0, facing.y)
	var path: Array = []
	for dt in Impact.wave_path(facing):
		var tl: Vector2i = ptile + dt
		# the qi flies over open ground and water; a wall of the land (the forest's deep, a cliff, a
		# building) stops it, though the tree at the forest's edge it hits still falls
		if tl.x < 0 or tl.y < 0 or tl.x >= w or tl.y >= h:
			break
		path.append(tl)
		if not tile_free(tl) and grid[tl.y * w + tl.x] != MapGen.WATER:
			break
	var reach: Array = []
	# (how many tiles of the path it crosses before a pack in the way stops it)
	var span := path.size()
	for k0 in path.size():
		var tl2: Vector2i = path[k0]
		reach.append(tl2)
		var side := Vector2i(-facing.y, facing.x)
		reach.append(tl2 + side)
		reach.append(tl2 - side)
		var e = ent_at(tl2)
		if e != null and e.kind == "enemy":
			span = k0 + 1
			break
	if _blow(reach, fwd):
		if not headless():
			Impact.wave(scene3d, _player_pos() + Vector3(0, 1.0, 0) + fwd * 0.8, fwd, maxf(2.0, (span - 1) * TS))
		return
	if headless():
		return
	var pp := _player_pos()
	Impact.wave(scene3d, pp + Vector3(0, 1.0, 0) + fwd * 0.8, fwd, path.size() * TS)
	for k in path.size():
		if k % 2 == 1:
			Impact.mow(wpos(path[k]), 2.2, t)
	_folk_start(pp, 9.0)

## A blow (the sword's, or the qi's as it flies) reaches `tiles`.  Returns whether it struck a pack
## first (whose battle then begins).
func _blow(tiles: Array, dir: Vector3) -> bool:
	for tl in tiles:
		var e = ent_at(tl)
		if e != null and e.kind == "enemy":
			if _ambush(e, dir):
				return true
			break
	for tl in tiles:
		var e2 = ent_at(tl)
		if e2 != null and e2.kind == "obstacle":
			_hit_obstacle(e2, dir)
		var b := Havoc.at_tile(wd, tl)
		if not b.is_empty() and not Havoc.is_broken(Game, b):
			_smash(b, dir, "strike")
	if not headless():
		for tl2 in tiles:
			_nature_blow(tl2, dir)
	return false

## A pack struck first in the land (impact.gd): it flies back off its feet, and once it has been seen to
## land the battle begins with every one of them reeling.  A pack two realms below scatters instead, as
## it would before Lin Feng's aura (and the swing goes on through the grass).  Returns whether a battle
## follows.
func _ambush(e: Dictionary, dir: Vector3) -> bool:
	if Game.scatters(e.group):
		main.scatter_pack(e)
		return false
	Game.ambushes += 1
	move_dir = Vector2i.ZERO
	if headless():
		main.start_encounter(e, true)
		return true
	ambush_t = t
	ambush_e = e
	var n: Node3D = ent_nodes.get(e.id)
	if n != null:
		n.set_meta("knock", t)
		Impact.knock(n, dir)
		Fx3D.hit(scene3d, n.position + Vector3(0, 1.0, 0), "phys", true)
		for m in n.get_meta("models", []):
			Models.act(m, "hurt", t)
	main.fx_flash(Color(1, 1, 1), 0.25)
	return true

## A blow on an obstacle of the story (Part XVII): so many blows clear it, and then it comes apart.
func _hit_obstacle(e: Dictionary, dir: Vector3) -> void:
	var r := Impact.hit_obstacle(Game, e)
	if r == "":
		return
	var spec: Dictionary = Impact.OBSTACLES.get(str(e.what), {})
	if r == "cleared":
		Game.toast("Cleared the %s" % str(spec.get("n", "obstacle")))
		Game.poll_steps()
	if headless():
		return
	var n: Node3D = ent_nodes.get(e.id)
	var at := Terrain3D.world_pos(e.pos) + off
	if n != null:
		at = n.position
		if r == "hit" and n.has_meta("model"):
			# (it shakes under the blow)
			var om: Node3D = n.get_meta("model")
			var tw := om.create_tween()
			tw.tween_property(om, "position", dir * 0.12, 0.06)
			tw.tween_property(om, "position", Vector3.ZERO, 0.14)
	var bb: Dictionary = bundles[layer]
	Impact.obstacle_burst(scene3d, str(e.what), at, dir, func(q: Vector3) -> float: return _stand_y(bb, q), r == "cleared")
	_folk_start(at, 9.0)

## The land answers a blow on tile `tl` (on screen only): the tree there falls, the bush is cut, the rock
## shatters (impact.gd; they grow back by the next dawn), and water splashes.
func _nature_blow(tl: Vector2i, dir: Vector3) -> void:
	if tl.x < 0 or tl.y < 0 or tl.x >= w or tl.y >= h:
		return
	var rid := Atlas.owner_id(wd, tl)
	if not views.has(rid) or not bool(views[rid].shown):
		return
	var v: Dictionary = views[rid]
	var root: Node3D = v.root
	var reg: Dictionary = root.get_meta("nature", {})
	var r0: Vector2i = v.get("origin", Vector2i.ZERO)
	var local := tl - r0
	var bb: Dictionary = bundles[layer]
	var gfn := func(q: Vector3) -> float: return _stand_y(bb, q)
	for en in reg.get(local, []):
		var mmi = en.get("mmi")
		if mmi == null or not is_instance_valid(mmi):
			continue
		var k := Impact.key(layer, rid, local, int(en.i) * 1000 + str(en.key).hash() % 1000)
		if Impact.is_down(Game, k):
			continue
		Impact.fell(Game, k)
		var xf0: Transform3D = (mmi as MultiMeshInstance3D).multimesh.get_instance_transform(int(en.i))
		var stump: Node3D = null
		match str(en.kind):
			"tree":
				stump = Impact.topple(scene3d, mmi, int(en.i), dir, gfn)
			"plant":
				Impact.cut_plant(scene3d, mmi, int(en.i), dir)
			"rock":
				Impact.shatter(scene3d, mmi, int(en.i), dir, gfn)
		downed.append([k, stump, rid, str(en.kind), mmi, int(en.i), xf0])
	var gi := tl.y * w + tl.x
	if tl.x >= 0 and tl.y >= 0 and tl.x < w and tl.y < h and grid[gi] == MapGen.WATER:
		Impact.splash(scene3d, Vector3(wpos(tl).x, Terrain3D.WATER_Y + off.y, wpos(tl).z), dir)

## Thing `b` breaks: game state (what the owner says, a price paid), and on screen its pieces fly.
func _smash(b: Dictionary, dir: Vector3, why: String) -> void:
	for ln in Havoc.smash(Game, wd, b, why):
		Game.toast(str(ln))
	if headless():
		return
	var bn := _brk_node(str(b.id))
	var at := Terrain3D.world_pos(b.tile) + off
	if bn != null:
		at = bn.position
		bn.visible = false
	var bb: Dictionary = bundles[layer]
	Havoc.burst(scene3d, str(b.kind), at, dir, func(q: Vector3) -> float: return _stand_y(bb, q), 1.0 if why != "ride" else 1.4)
	_folk_start(at, 9.0)

## The townsfolk within `r` metres of `at` start at a crash.
func _folk_start(at: Vector3, r: float) -> void:
	for id in folk_nodes:
		var fn: Node3D = folk_nodes[id]
		if fn.visible and fn.position.distance_to(at) < r:
			Models.act(fn.get_meta("model"), "shock", t + float(fn.get_meta("seed", 0)))

## A battle won in the land leaves its mark where it was fought: scorched ground with cracks, and
## the things standing next to it broken (a boss's mark is bigger).
func battle_mark(e: Dictionary, boss: bool) -> void:
	if e.is_empty() or not e.has("pos") or is_floor() or wd.is_empty():
		return
	var tile: Vector2i = e.pos
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var b := Havoc.at_tile(wd, tile + Vector2i(dx, dy))
			if not b.is_empty() and not Havoc.is_broken(Game, b):
				_smash(b, Vector3(dx, 0, dy), "battle")
	if headless():
		return
	var bb: Dictionary = bundles[layer]
	var at := Terrain3D.world_pos(tile) + off
	var sc := Havoc.scar(at, 2.4 if boss else 1.5, func(q: Vector3) -> float: return _ground(bb, q))
	scene3d.add_child(sc)
	scars.append([sc, Havoc.now(Game), layer])
	while scars.size() > 24:
		var old: Array = scars.pop_front()
		if is_instance_valid(old[0]):
			(old[0] as Node).queue_free()

## Every frame: the things of the regions on show stand where they stand (unless broken), shake a
## moment when jostled; the scars of old battles fade and go; the kick body follows the hero.
func _update_havoc(d: float, pp: Vector3) -> void:
	for k in views:
		var v: Dictionary = views[k]
		var brk: Dictionary = v.get("brk", {})
		for bid in brk:
			var bn: Node3D = brk[bid]
			var vis: bool = v.shown and (not Game.broken.has(bid) or not Havoc.is_broken(Game, bn.get_meta("b")))
			bn.visible = vis
			if vis and bn.has_meta("jostle"):
				var e := t - float(bn.get_meta("jostle"))
				if e < 0.8:
					bn.rotation.z = sin(e * 26.0) * 0.12 * (1.0 - e / 0.8)
				else:
					bn.rotation.z = 0.0
					bn.remove_meta("jostle")
	var now := Havoc.now(Game)
	for i in range(scars.size() - 1, -1, -1):
		var sc: Array = scars[i]
		if not is_instance_valid(sc[0]):
			scars.remove_at(i)
			continue
		var age := now - float(sc[1])
		var mi: MeshInstance3D = sc[0]
		mi.visible = str(sc[2]) == layer
		if age > Havoc.SCAR_MINUTES:
			mi.queue_free()
			scars.remove_at(i)
		else:
			mi.transparency = clampf((age - Havoc.SCAR_MINUTES * 0.6) / (Havoc.SCAR_MINUTES * 0.4), 0.0, 1.0)
	if kick != null:
		kick.global_position = pp + Vector3(0, 0.85, 0)
	# the Sword's Wake (impact.gd): what was felled grows back at dawn (a tree where its stump was)
	for i2 in range(downed.size() - 1, -1, -1):
		var dn: Array = downed[i2]
		if Impact.is_down(Game, str(dn[0])) and views.has(str(dn[2])):
			continue
		if dn[1] != null and is_instance_valid(dn[1]):
			(dn[1] as Node).queue_free()
		if is_instance_valid(dn[4]) and views.has(str(dn[2])):
			Impact.show_instance(dn[4], int(dn[5]), dn[6])
		downed.remove_at(i2)

## A region's view was (re)built: the trees, plants and rocks of it felled and not yet grown back are
## hidden again (their stumps are not redrawn: a stump is only left the day the tree falls).
func _keep_down(id: String) -> void:
	var v: Dictionary = views[id]
	var reg: Dictionary = (v.root as Node3D).get_meta("nature", {})
	var pre := "%s|%s|" % [str(v.layer), id]
	for k in Game.felled.keys():
		if not str(k).begins_with(pre) or not Impact.is_down(Game, str(k)):
			continue
		var parts := str(k).split("|")
		var local := Vector2i(int(parts[2]), int(parts[3]))
		for en in reg.get(local, []):
			var mmi = en.get("mmi")
			if mmi != null and int(en.i) * 1000 + str(en.key).hash() % 1000 == int(parts[4]):
				var xf0: Transform3D = (mmi as MultiMeshInstance3D).multimesh.get_instance_transform(int(en.i))
				Impact.hide_instance(mmi, int(en.i))
				downed.append([str(k), null, id, str(en.kind), mmi, int(en.i), xf0])

# ---------------------------------------------------------------- the people of the towns (folk.gd)
## the 3D node of each townsperson in sight (by id), and the one Lin Feng is talking to
var folk_nodes := {}
var folk_talking := ""
## lines called out over the street (a hawker's wares, the watch) while a townsperson calls
const FOLK_CALLS := {"pedlar": ["Needles! Thread! Salt!", "Combs and mirrors!", "News from the next valley, free with a needle!"], "merchant": ["Silk! Tea! Needles!", "Fresh today!", "Two for one!"], "fisher": ["Fish! Fresh fish!", "Carp from the river!"],
	"cook": ["Hot buns!", "Noodles! Hot noodles!", "Dumplings!"], "watchman": ["Mind your fires!", "All is well!", "Lock your doors!"],
	"porter": ["Make way!", "Coming through!"], "lamplighter": ["Lamps lit!"], "monk": ["Amituofo."], "fishwife": ["Fish!"]}

## Part XVI: a town reminded of the old ways comes out at once and practises: everybody banging a pot.
var drill_area := ""
var drill_t := -99.0
func drill(area: String) -> void:
	drill_area = area
	drill_t = t

## The people of the towns of the regions on show: where the clock puts them, doing what it says,
## made as they come within sight (two a frame at most), hidden indoors or out of sight, freed when
## their town is far behind.  They step aside for the hero, turn to him when he stops beside them,
## carry a lantern after dark and call their wares or the watch.
func _update_folk(d: float, pp: Vector3) -> void:
	var near := {}
	if not is_floor() and not wd.is_empty():
		var bb: Dictionary = bundles[layer]
		var made := 0
		var m: float = Game.clock
		var dark := night_k > 0.35
		for k in views:
			var v: Dictionary = views[k]
			if not v.shown or str(v.layer) != layer:
				continue
			for tid in Folk.homes_in(wd, str(k)):
				var hc := wpos(Folk.heart(tid))
				if Vector2(hc.x - pp.x, hc.z - pp.z).length() > Folk.RADIUS * TS + Folk.SEE:
					continue
				near[tid] = true
				# Part XVI: a town practising the old ways, or out all the long last night of the year
				var noise: bool = not Folk.is_camp(tid) and ((str(Folk.TOWNS[tid].area) == drill_area and t - drill_t < 30.0) or Folk.noisy(Game, tid))
				for fp in Folk.people(wd, tid):
					var st := Folk.state(wd, fp, m)
					if noise:
						st = st.duplicate()
						st.vis = true
						st.walk = false
						st.clip = "bang" if int(fp.seed) % 4 != 0 else "clap"
						st.hold = "gong" if st.clip == "bang" else ""
					var at: Vector2 = st.at
					var goal := Vector3(at.x * TS, 0.0, at.y * TS) + off
					var id: String = fp.id
					var fn: Node3D = folk_nodes.get(id)
					var flat := Vector2(goal.x - pp.x, goal.z - pp.z)
					if not st.vis or flat.length() > Folk.SEE:
						if fn != null:
							fn.visible = false
						continue
					if fn == null:
						if made >= 2:
							continue
						fn = _make_folk(fp)
						made += 1
						fn.position = goal
						fn.position.y = _stand_y(bb, goal)
					_place_folk(fn, fp, st, goal, pp, d, bb, dark)
	for id2 in folk_nodes.keys():
		var nd: Node3D = folk_nodes[id2]
		if not near.has(str(nd.get_meta("town", ""))):
			nd.queue_free()
			folk_nodes.erase(id2)

func _make_folk(fp: Dictionary) -> Node3D:
	var n := Node3D.new()
	var m := Folk.model(fp)
	n.add_child(m)
	n.add_child(Models.shadow_disc(0.45 if not fp.kid else 0.32))
	n.set_meta("model", m)
	n.set_meta("town", fp.town)
	n.set_meta("name", fp.n)
	n.set_meta("seed", int(fp.seed))
	scene3d.add_child(n)
	folk_nodes[fp.id] = n
	return n

func _place_folk(fn: Node3D, fp: Dictionary, st: Dictionary, goal: Vector3, pp: Vector3, d: float, bb: Dictionary, dark: bool) -> void:
	fn.visible = true
	var m: Node3D = fn.get_meta("model")
	var talking: bool = folk_talking == str(fp.id) and main.top_name() == "dialogue"
	# make way: nobody stands where the hero is (they step aside, the way people do)
	var hp := Vector2(pp.x, pp.z)
	var g2 := Vector2(goal.x, goal.z)
	var away := g2 - hp
	if away.length() < 1.15:
		var side := away.normalized() if away.length() > 0.05 else Vector2(cos(float(fp.seed)), sin(float(fp.seed)))
		g2 = hp + side * 1.15
	var want := Vector3(g2.x, 0.0, g2.y)
	want.y = _stand_y(bb, want)
	fn.position = fn.position.lerp(want, 1.0 - exp(-d * 9.0))
	var yaw: float = st.yaw
	var dist := Vector2(fn.position.x - pp.x, fn.position.z - pp.z).length()
	var clip: String = st.clip
	if clip in ["idle", "look", "in"]:
		clip = ""
	if talking or (not st.walk and dist < 3.2):
		# he has stopped beside them: they turn to him (and talk, if he is talking to them)
		var dv := pp - fn.position
		yaw = atan2(dv.x, dv.z)
		clip = "talk" if talking else ""
	m.rotation.y = lerp_angle(m.rotation.y, yaw, 1.0 - exp(-d * (8.0 if st.walk else 4.0)))
	if clip != "" and not Assets.has_clip(m, clip):
		clip = "walk" if st.walk else ""
	# (the High Roads: on a rock face a pilgrim goes up hand over hand like anybody)
	var on_rock: bool = st.walk and _steep_at(fn.position) and Assets.has_clip(m, "scale")
	if on_rock:
		clip = "scale"
	m.rotation.x = lerpf(m.rotation.x, 0.24 if on_rock else 0.0, 1.0 - exp(-d * 8.0))
	Models.anim_person(m, t + float(fp.seed), false, false, clip)
	# what is in their hands: their work's tool, the load on the road, a lantern after dark
	var hold: String = st.hold if clip != "" and clip != "talk" and not on_rock else ""
	if st.walk and dark and hold == "":
		hold = "lantern"
	elif dark and fp.role in ["watchman", "lamplighter"] and hold == "":
		hold = "lantern"
	_post_hold(fn, m, hold)
	# New Year's Day: the children in new red clothes (folk.gd), and a mark over every child still
	# to be given a red envelope while that is what the day asks
	var dy := Folk.dye_now(fp, Game)
	if str(m.get_meta("dye", [])) != str(dy):
		Folk.apply_dye(m, dy)
		m.set_meta("dye", dy)
	var s := Game.cur_step()
	var want_mark: bool = not s.is_empty() and s.kind == "folk" and Folk.is_role(fp, str(s.role)) and not Game.folk_has(s, str(fp.id))
	if want_mark and not fn.has_meta("mark"):
		fn.set_meta("mark", _label(fn, "!", 2.2 if not fp.kid else 1.7, Color("ff6a5a"), 64))
	if fn.has_meta("mark"):
		var mk: Label3D = fn.get_meta("mark")
		mk.visible = want_mark
		if want_mark:
			mk.position.y = (2.2 if not fp.kid else 1.7) + sin(t * 4.0) * 0.12
	# a word as he passes: a bow (a child waves) and a greeting over their head, once in a while
	if dist < 4.2 and not talking and t - float(fn.get_meta("greeted", -99.0)) > 50.0:
		fn.set_meta("greeted", t)
		fn.set_meta("say_until", t + 2.6)
		fn.set_meta("say", Folk.greeting(fp, Game))
		Models.act(m, "wave" if fp.kid else "bow", t + float(fp.seed))
	var saying: bool = t < float(fn.get_meta("say_until", -1.0))
	# a hawker calls the wares, the watchman the watch
	if saying and dist < 24.0:
		if not fn.has_meta("bubble"):
			fn.set_meta("bubble", _label(fn, "", 2.35 if not fp.kid else 1.8, Color("fff4d8"), 26))
		var lb2: Label3D = fn.get_meta("bubble")
		lb2.text = str(fn.get_meta("say", ""))
		lb2.visible = true
	elif clip == "call" and dist < 24.0:
		if not fn.has_meta("bubble"):
			fn.set_meta("bubble", _label(fn, "", 2.35 if not fp.kid else 1.8, Color("fff4d8"), 26))
		var lbl: Label3D = fn.get_meta("bubble")
		var calls: Array = FOLK_CALLS.get(str(fp.role), ["Hey!"])
		lbl.text = str(calls[int(float(Game.clock) / 7.0 + float(fp.seed)) % calls.size()])
		lbl.visible = true
	elif fn.has_meta("bubble"):
		(fn.get_meta("bubble") as Label3D).visible = false

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
	# survival (needs.gd): the seven needs, small, under the panel; a low one is red
	if Game.survival:
		UI.panel(self, Rect2(12, 144, 330, 30))
		for ni in Needs.ORDER.size():
			var nk: String = Needs.ORDER[ni]
			var nv := Needs.value(Game, nk)
			var nx := 22.0 + ni * 46.0
			UI.text(self, Vector2(nx, 164), str(Needs.NEEDS[nk].n).substr(0, 2), 11, UI.C_DIM if nv >= Needs.LOW else UI.C_RED.lightened(0.3))
			UI.bar(self, Rect2(nx + 17, 156, 22, 7), nv / 100.0, Needs.NEEDS[nk].col if nv >= Needs.LOW else UI.C_RED)
	# objective: long quest titles (one in eight runs past the panel, up to 770 px of text) used to be
	# cut off mid-sentence; they now wrap onto a second line in place of the heading
	UI.panel(self, Rect2(VIEW.x - 520, 12, 508, 58))
	var obj := Game.objective_text()
	if UI.font().get_string_size(obj, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x <= 480.0:
		UI.text(self, Vector2(VIEW.x - 506, 34), "Objective", 13, UI.C_DIM)
		UI.text(self, Vector2(VIEW.x - 506, 56), obj, 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 480)
	else:
		# (two lines is all the panel holds: a longer objective is set a little smaller rather than spill a
		# third line out of the panel onto the minimap, as three of Part XV's did)
		var osz := UI.objective_size(obj)
		UI.wrapped(self, Vector2(VIEW.x - 506, 35 - (15 - osz)), obj, osz, UI.C_TEXT, 486)
	# (the line grew a key with every release and was still drawn 580 px wide: since G was added its
	# end was cut off, "Esc men")
	UI.text(self, Vector2(VIEW.x - 772, VIEW.y - 14), "Arrows/WASD move   Q/E camera   R ride   T talk   F strike   G sword qi   V glide   Z/Enter act   Esc menu", 13, UI.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, 760.0)
	_draw_minimap()
	_draw_clock()
	if banner_t > 0.0:
		var a := clampf(banner_t, 0.0, 1.0)
		var btxt := banner_text if banner_text != "" else area_name
		var bw := maxf(440.0, UI.font().get_string_size(btxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 60.0)
		UI.panel(self, Rect2(VIEW.x * 0.5 - bw * 0.5, 96, bw, 52), Color(0.04, 0.06, 0.13, 0.85 * a), Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, a))
		UI.text(self, Vector2(VIEW.x * 0.5 - bw * 0.5, 130), btxt, 26, Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, a), HORIZONTAL_ALIGNMENT_CENTER, bw)
		# the Six Hearths (cultures.gd): whose country this is, and what they call the hero there
		var bh := Cultures.of_area(area_id)
		if bh != "" and banner_text == "":
			var hh: Dictionary = Cultures.HEARTHS[bh]
			var hc: Color = hh.col
			UI.text(self, Vector2(VIEW.x * 0.5 - 300.0, 166), "Country of %s  -  %s" % [str(hh.n), Cultures.tier_name(Cultures.tier(Game, bh)).to_lower()], 15, Color(hc.r, hc.g, hc.b, a).lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, 600.0)
	elif banner_text != "":
		banner_text = ""
	# interaction hint
	var fe = face_entity()
	if fe != null and move_t < 0.0 and trip.is_empty() and using.is_empty() and fe.kind in ["npc", "boss", "ladder", "stele", "abode", "prop", "folk", "machine", "mark", "hold"]:
		var hint := "Talk" if fe.kind != "folk" else "Talk to %s" % str(fe.n)
		if fe.kind == "machine" or fe.kind == "mark" or fe.kind == "hold":
			hint = "Look"
		match fe.kind:
			"prop":
				hint = str(Props.kind_of(fe).get("verb", "Look"))
			"boss":
				hint = "Challenge"
			"ladder":
				var lst := str(fe.get("style", ""))
				hint = ("Climb" if lst == "climb" else ("Board the boat" if lst == "sail" else "Take the stairs")) if ladder_open(fe) else "Look"
				# the Hollow Hills release: the mouth of a cave, the way out of one, and the shaft between its galleries
				if lst in ["cave", "cave_out", "cave_up", "cave_down"]:
					hint = {"cave": "Go down into the cave", "cave_out": "Climb out into the daylight", "cave_up": "Climb back up the rope", "cave_down": "Climb down the shaft"}[lst]
			"abode":
				hint = "Open the sealed cave" if Game.level >= int(fe.req) and not Game.abodes.has(fe.id) else "Look"
			"stele":
				hint = "Choose your Dao"
		UI.text(self, Vector2(VIEW.x * 0.5 - 150, VIEW.y - 60), "Enter: " + hint, 20, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 300)
	# the High Roads (peaks.gd): what the heights offer
	if not is_floor() and using.is_empty() and trip.is_empty() and not wd.is_empty():
		var hint2 := ""
		if not glide.is_empty():
			hint2 = "V: fold the kite    Left/Right: turn    %d m up" % int(maxf(float(glide.alt) - Peaks.at(wd, ptile), 0.0))
		elif Peaks.at(wd, ptile) >= 4.0:
			var pk2 := Peaks.of_tile(wd, ptile)
			hint2 = "V: open the cloud-kite    %s, %d m up" % [str(pk2.get("n", "")), int(Peaks.at(wd, ptile))]
		if hint2 != "":
			UI.text(self, Vector2(VIEW.x * 0.5 - 260, VIEW.y - 34), hint2, 16, Color("cfe8ff"), HORIZONTAL_ALIGNMENT_CENTER, 520)
	# a trip up or down the Jianmu (or the stairs) fades through white going up, dark going down
	var fade := trip_fade()
	if fade > 0.0:
		var fc := Color(0.96, 0.97, 1.0) if int(trip.dir) > 0 and trip.climb else Color(0.02, 0.02, 0.05)
		if trip.get("sail", false):
			fc = Color(0.55, 0.75, 0.86)
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(fc.r, fc.g, fc.b, fade * (1.0 if trip.climb else 0.85)))
	# toasts
	# (a long one, as most "Quest complete: ..." lines are, a little smaller to fit, and over two lines
	# if it still does not: 176 of them used to be cut off mid-word at 600 pixels)
	var y := 170.0
	for s in main.toast_list:
		var col := Color(UI.C_JADE.r, UI.C_JADE.g, UI.C_JADE.b, clampf(s.t, 0.0, 1.0))
		var sz := UI.fit(str(s.text), 18, UI.TOAST_W, 15)
		for ln in UI.wrap_lines(str(s.text), sz, UI.TOAST_W):
			UI.text(self, Vector2(VIEW.x * 0.5 - UI.TOAST_W * 0.5, y), ln, sz, col, HORIZONTAL_ALIGNMENT_CENTER, UI.TOAST_W)
			y += sz + 4.0
		y += 26.0 - (sz + 4.0)

## The Living Land release (clock.gd): the hour under the minimap, with the sun or the moon on a
## little arc of sky (rising on the left, setting on the right) and the watch of the night.
func _draw_clock() -> void:
	var h := Clock.hour(Game)
	var r := Rect2(VIEW.x - 210, 218, 198, 46)
	UI.panel(self, r)
	var c := r.position + Vector2(26, 34)
	var night := Clock.is_night(h)
	# the arc of the sky, and where on it the light stands
	draw_arc(c, 18.0, PI, TAU, 18, Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, 0.6), 1.5)
	draw_line(c + Vector2(-22, 0), c + Vector2(22, 0), Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, 0.6), 1.0)
	var k := 0.0
	if not night:
		k = clampf((h - Clock.DAWN) / (Clock.DUSK - Clock.DAWN), 0.0, 1.0)
	else:
		k = clampf(fposmod(h - Clock.DUSK, 24.0) / (24.0 - (Clock.DUSK - Clock.DAWN)), 0.0, 1.0)
	var p := c + Vector2(-cos(k * PI), -sin(k * PI)) * 18.0
	if night:
		draw_circle(p, 5.5, Color("e8f0ff"))
		draw_circle(p + Vector2(2.6, -1.6), 4.8, UI.C_PANEL)
	else:
		for i in 8:
			var a := i * TAU / 8.0
			draw_line(p + Vector2(cos(a), sin(a)) * 6.5, p + Vector2(cos(a), sin(a)) * 9.0, UI.C_GOLD, 1.5)
		draw_circle(p, 5.0, UI.C_GOLD)
	UI.text(self, r.position + Vector2(52, 19), Clock.shichen_name(h), 14, UI.C_GOLD if not night else Color("c8d8ff"))
	var wt := Clock.watch(h)
	var sub := "%s  day %d" % [Clock.hm(h), Game.day]
	if Clock.frozen(Game) == "noon":
		sub = "the sun will not move"
	elif Clock.frozen(Game) == "night":
		sub = "the night will not move"
	elif wt >= 0:
		sub = "%s  %s watch" % [Clock.hm(h), Clock.WATCHES[wt]]
	UI.text(self, r.position + Vector2(52, 38), sub, 13, UI.C_DIM)

func _draw_minimap() -> void:
	if mini_tex == null:
		return
	var mw := 190.0
	var mh := 120.0
	var r := Rect2(VIEW.x - mw - 16, 88, mw, mh)
	# a window of the world map centred on the player (upstairs or in a cellar: the map of the realm
	# outside, centred on the building)
	var vb: Dictionary = bundles[_view_layer() if _view_layer() != "" else str(wd.get("parent", layer))]
	var vt := view_tile()
	var span := Vector2(96, 96 * mh / mw)
	if is_cave():
		# a cave is drawn from its own map, in its own tiles, a little closer
		vb = bundles[layer]
		vt = ptile
		span = Vector2(minf(38.0, float(vb.wd.w)), minf(38.0, float(vb.wd.w)) * mh / mw)
	var mw_t: int = vb.wd.w
	var mh_t: int = vb.wd.h
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
				col = Color("a8e0ff") if str(e.get("style", "")) in ["climb", "cave", "cave_out", "cave_up", "cave_down"] else Color(0, 0, 0, 0)
			"enemy":
				col = Color("ff8a60") if is_cave() else Color(0, 0, 0, 0)
			"stele":
				col = UI.C_JADE
			"abode":
				col = Color("ffc860") if not Game.abodes.has(e.id) else Color(0, 0, 0, 0)
		if col.a > 0.0:
			draw_circle(r.position + (Vector2(e.pos) - o + Vector2(0.5, 0.5)) * sc, 2.4, col)
	# the High Roads (peaks.gd): a mark on every summit, gold until he has stood on it
	for pk in vb.wd.get("peaks", []):
		if src.has_point(Vector2(pk.c)):
			var sp := r.position + (Vector2(pk.c) - o + Vector2(0.5, 0.5)) * sc
			var pc := Color("f4f4f8") if Game.summits.has(str(pk.id)) else UI.C_GOLD
			draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -4.5), sp + Vector2(4, 3), sp + Vector2(-4, 3)]), Color(0, 0, 0, 0.7))
			draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -3.2), sp + Vector2(2.8, 2.2), sp + Vector2(-2.8, 2.2)]), pc)
	var pp := r.position + (Vector2(vt) - o + Vector2(0.5, 0.5)) * sc
	draw_circle(pp, 4.5 + sin(t * 5.0), Color(1, 1, 1, 0.35))
	draw_circle(pp, 2.6, Color("5aa9ff"))
	var here := area_name
	if is_cave():
		here = str(wd.bld_n)
	elif is_floor():
		here = "%s, %s" % [wd.bld_n, "upstairs" if int(wd.level) > 0 else "below"]
	elif inside != "":
		here = building_at(ptile).get("n", area_name)
	UI.text(self, r.position + Vector2(0, r.size.y + 20), here, 12, UI.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, mw)
	if layer != "surface":
		var realm: String = Atlas.LAYER_NAMES.get(str(wd.get("parent", layer)) if is_floor() else layer, "")
		if realm != "" and realm != Atlas.LAYER_NAMES.surface:
			UI.text(self, r.position + Vector2(0, r.size.y + 36), realm, 12, Color("a8d0ff"), HORIZONTAL_ALIGNMENT_RIGHT, mw)
