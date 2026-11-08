extends Node
## Screenshot tour (developer tool).  Teleports through every screen, region and boss and saves
## PNGs.  Needs a real window (use xvfb on a server):
##   godot --path . --fixed-fps 30 -- --tour=docs/screenshots

var main
var dir := ""

const ELEMS := {"juntian": "thunder", "changhe": "wood", "ninesprings": "thunder", "youdu": "fire", "sect": "phys", "bamboo": "fire", "marsh": "fire", "frost": "thunder", "thunder": "earth", "palace": "water", "dragon": "thunder", "volcano": "water", "void": "dark", "celestial": "thunder", "mirror": "thunder", "grave": "fire", "time": "dark", "origin": "thunder", "cloudsea": "thunder", "court": "fire", "forge": "water", "garden": "fire", "dunes": "wood", "fungal": "fire", "aurora": "earth", "chaos": "thunder", "maple": "water", "karst": "thunder", "springs": "fire", "wheel": "thunder", "mountain": "phys", "village": "thunder", "terraces": "earth", "silk": "fire", "loom": "fire", "starferry": "earth", "magpie": "wood", "starpalace": "earth", "jasper": "wood", "yanggu": "water", "millet": "fire", "fusang": "thunder", "guanghan": "thunder", "longmen": "earth", "drowned": "earth", "tushan": "water", "buzhou": "earth"}

## [shot name, area, a tile of that area's own map to look at, eye offset, look-at offset]
const TOWN_SHOTS := {
	"sect": [["town_cloudfoot", "mountain", Vector2i(82, 34), Vector3(-26.0, 30.0, 34.0), Vector3(0.0, 0.0, -4.0)],
		# Part XI: the Jianmu, grown overnight on the open ground west of the sect
		["jianmu", "mountain", Vector2i(34, 54), Vector3(-30.0, 10.0, 62.0), Vector3(0.0, 46.0, 0.0)],
		["jianmu_foot", "mountain", Vector2i(34, 60), Vector3(-10.0, 5.0, 14.0), Vector3(0.0, 6.0, -6.0)]],
	"dunes": [["town_shazhou", "dunes", Vector2i(12, 40), Vector3(-24.0, 26.0, 30.0), Vector3(0.0, 0.0, 0.0)]],
	"longmen": [["town_longmen", "longmen", Vector2i(28, 30), Vector3(-30.0, 30.0, 26.0), Vector3(4.0, 0.0, -2.0)],
		["dragon_gate", "longmen", Vector2i(54, 3), Vector3(46.0, 12.0, 10.0), Vector3(0.0, 9.0, 0.0)]],
	"tushan": [["town_tushan", "tushan", Vector2i(28, 26), Vector3(-26.0, 28.0, 30.0), Vector3(0.0, 0.0, -2.0)],
		["great_cauldron", "tushan", Vector2i(38, 22), Vector3(-12.0, 8.0, 12.0), Vector3(0.0, 3.0, 0.0)]],
	"buzhou": [["buzhou_pillar", "buzhou", Vector2i(70, 20), Vector3(-52.0, 18.0, 46.0), Vector3(0.0, 22.0, 0.0)]],
	# Part XI: the realms above and below, their towns and the great tree between them
	"juntian": [["town_featherfall", "juntian", Vector2i(42, 30), Vector3(-30.0, 30.0, 32.0), Vector3(2.0, 0.0, -4.0)],
		["jianmu_crown", "juntian", Vector2i(9, 32), Vector3(46.0, 10.0, 40.0), Vector3(0.0, 16.0, 0.0)],
		["realm_heaven", "juntian", Vector2i(46, 34), Vector3(-90.0, 54.0, 110.0), Vector3(30.0, -14.0, -30.0)]],
	"changhe": [["changhe_gate", "changhe", Vector2i(80, 30), Vector3(-44.0, 14.0, 34.0), Vector3(6.0, 14.0, 0.0)]],
	"ninesprings": [["town_tearwater", "ninesprings", Vector2i(40, 26), Vector3(-30.0, 24.0, 30.0), Vector3(2.0, 0.0, -2.0)],
		["jianmu_roots", "ninesprings", Vector2i(8, 30), Vector3(36.0, 24.0, 30.0), Vector3(0.0, 12.0, 0.0)],
		["realm_under", "ninesprings", Vector2i(44, 32), Vector3(-80.0, 26.0, 90.0), Vector3(30.0, -6.0, -30.0)]],
	"youdu": [["town_youdu", "youdu", Vector2i(40, 30), Vector3(-30.0, 26.0, 32.0), Vector3(2.0, 0.0, -2.0)],
		["youdu_gate", "youdu", Vector2i(72, 32), Vector3(-40.0, 12.0, 30.0), Vector3(6.0, 10.0, 0.0)]],
}
## Part XI: upstairs and down in the buildings: [shot name, floor id]
const FLOOR_SHOTS := {
	"sect": [["cellar_sealed_archive", "f:sect:library:-1"], ["cellar_ancestral_crypt", "f:sect:hall:-1"], ["upper_dormitory", "f:sect:dormitory:1"]],
	"juntian": [["upper_aerie_tower", "f:juntian:aerie_tower:1"], ["cellar_archive_of_rain", "f:juntian:rain_ministry:-1"], ["cellar_egg_nursery", "f:juntian:egg_nursery:-1"]],
	"changhe": [["upper_moon_terrace", "f:changhe:fox_pavilion:1"]],
	"ninesprings": [["cellar_pearl_vault", "f:ninesprings:pearl_hall:-1"], ["upper_root_loft", "f:ninesprings:root_house:1"]],
	"youdu": [["upper_ward_office", "f:youdu:ward_office:1"], ["cellar_deep_hall", "f:youdu:earth_palace:-1"]],
	"longmen": [["upper_guest_rooms", "f:longmen:carp_inn:1"]],
}

func _stop(id: String) -> Array:
	## [first quest step set in this area, a sensible player level]
	var step_id := "s_intro"
	for st in Data.STEPS:
		if st.get("area", "") == id:
			step_id = st.id
			break
	var lv := 0
	var spec: Dictionary = Data.AREAS[id]
	if spec.has("pool"):
		lv = spec.pool[0][1]
	return [step_id, lv]

func _ready() -> void:
	dir = main.args.tour
	DirAccess.make_dir_recursive_absolute(dir)
	_run()

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

var last_img: Image = null

func _shot(n: String, save: bool = true) -> void:
	await RenderingServer.frame_post_draw
	last_img = get_viewport().get_texture().get_image()
	if save:
		last_img.save_png("%s/%s.png" % [dir, n])
		print("[tour] ", n)

## Compose a row of captured frames into one image: the middle `keep` of each frame's width,
## scaled so the row fits `max_w` pixels.
func _sheet(n: String, frames: Array, keep: float = 0.36) -> void:
	if frames.is_empty():
		return
	var fw: int = frames[0].get_width()
	var fh: int = frames[0].get_height()
	var cw := int(fw * keep)
	var out := Image.create(cw * frames.size(), fh, false, Image.FORMAT_RGB8)
	for i in frames.size():
		var im: Image = frames[i]
		im.convert(Image.FORMAT_RGB8)
		out.blit_rect(im, Rect2i((fw - cw) / 2, 0, cw, fh), Vector2i(i * cw, 0))
	var max_w := 1920
	if out.get_width() > max_w:
		out.resize(max_w, int(fh * float(max_w) / out.get_width()), Image.INTERPOLATE_LANCZOS)
	out.save_png("%s/%s.png" % [dir, n])
	print("[tour] ", n)

## A showroom shot: models in a row on a lotus-pond stage, lit from the front.
## An enemy's model as the game builds it: its shape in its own palette.
func _foe(id: String, boss: bool = false) -> Node3D:
	var d: Dictionary = Data.ENEMIES[id]
	return Models.monster(d.shape, d.col, boss, id)

func _gallery(n: String, models: Array, spacing: float, yaw: float = 0.35) -> void:
	main.world.hide()
	var stage := Node3D.new()
	stage.position = Vector3(0, 400, 0)
	main.add_child(stage)
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.environment = Look.environment("garden", 0.2)
	cam.environment.tonemap_exposure = 0.85
	stage.add_child(cam)
	stage.add_child(Look.sun("garden"))
	stage.add_child(Look.fill("garden"))
	var key := OmniLight3D.new()
	key.position = Vector3(0, 4, 7)
	key.omni_range = 16.0
	key.light_energy = 0.5
	stage.add_child(key)
	var fl := MB.new()
	fl.disc(Vector3.ZERO, 14.0, MB.tag(Color("8a9a88"), MB.STONE), 48, MB.tag(Color("6a7a6a"), MB.STONE))
	MB.mesh_node(stage, fl.build(MB.mat_plain()))
	var w := spacing * 2.2
	for i in models.size():
		var m: Node3D = models[i]
		m.position = Vector3((i - (models.size() - 1) * 0.5) * w, 0.0, 0.0)
		m.rotation.y = yaw * (1 if i % 2 == 0 else -1)
		stage.add_child(m)
		m.add_child(Models.shadow_disc(0.8))
	var span := models.size() * w
	cam.position = Vector3(0, 1.6 + spacing * 0.6, span * 0.95)
	cam.look_at(stage.global_position + Vector3(0, 1.0 + spacing * 0.25, 0), Vector3.UP)
	cam.make_current()
	var t0 := 0.0
	for k in 40:
		t0 += 1.0 / 30.0
		for m2 in models:
			if m2.get_meta("kind", "") == "person":
				Models.anim_person(m2, t0 + 3.0, false)
			else:
				Models.anim_monster(m2, t0 + 3.0, 0.0)
		await get_tree().process_frame
	await _shot(n)
	stage.queue_free()
	main.world.show()
	if main.world.cam != null:
		main.world.cam.make_current()

## Close-up portraits (head and shoulders): the faces, hair and costume details the chase
## camera is too far away to show.
func _portraits(n: String, models: Array, spacing: float = 0.95, height: float = 1.5, dist: float = 2.6) -> void:
	main.world.hide()
	var stage := Node3D.new()
	stage.position = Vector3(0, 420, 0)
	main.add_child(stage)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.environment = Look.environment("garden", 0.1)
	cam.environment.tonemap_exposure = 0.75
	stage.add_child(cam)
	stage.add_child(Look.sun("garden"))
	stage.add_child(Look.fill("garden"))
	var key := OmniLight3D.new()
	key.position = Vector3(1.5, 2.2, 3.0)
	key.omni_range = 8.0
	key.light_energy = 0.25
	stage.add_child(key)
	for i in models.size():
		var m: Node3D = models[i]
		m.position = Vector3((i - (models.size() - 1) * 0.5) * spacing, 0.0, 0.0)
		m.rotation.y = 0.25 * (1 if i % 2 == 0 else -1)
		stage.add_child(m)
	cam.position = Vector3(0, height + 0.08, dist)
	cam.look_at(stage.global_position + Vector3(0, height - 0.12, 0), Vector3.UP)
	cam.make_current()
	var t0 := 0.0
	for k in 30:
		t0 += 1.0 / 30.0
		for m2 in models:
			if m2.get_meta("kind", "") == "person":
				Models.anim_person(m2, t0 + 0.5, false)
			else:
				Models.anim_monster(m2, t0 + 0.5, 0.0)
		await get_tree().process_frame
	await _shot(n)
	stage.queue_free()
	main.world.show()

## Turnaround of one model (developer tool, --inspect=a,b,c): front, three-quarter, side and back
## views of the whole figure and a close-up of the head, so faces, hands and costume details can be
## checked from every side.  Writes inspect_<id>_<view>.png.
func _inspect(id: String, m: Node3D, height: float) -> void:
	main.world.hide()
	var stage := Node3D.new()
	stage.position = Vector3(0, 440, 0)
	main.add_child(stage)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.environment = Look.environment("garden", 0.1)
	stage.add_child(cam)
	stage.add_child(Look.sun("garden"))
	stage.add_child(Look.fill("garden"))
	var fl := MB.new()
	fl.disc(Vector3.ZERO, 6.0, MB.tag(Color("8a9a88"), MB.STONE), 40, MB.tag(Color("6a7a6a"), MB.STONE))
	MB.mesh_node(stage, fl.build(MB.mat_plain()))
	stage.add_child(m)
	m.add_child(Models.shadow_disc(0.8))
	var t0 := 0.0
	if main.args.has("clip"):
		# a strip of frames through one clip, seen from the side (--clip=run [--frames=6])
		var clip := str(main.args.clip)
		var ap: AnimationPlayer = m.get_meta("ap", null)
		var frames := int(main.args.get("frames", "6"))
		if ap != null and ap.has_animation(clip):
			var ln: float = ap.get_animation(clip).length
			m.rotation.y = float(main.args.get("yaw", str(PI * 0.5)))
			var aim2 := Vector3(0, height * 0.5, 0)
			cam.position = aim2 + Vector3(0, height * 0.1, height * 2.4)
			cam.look_at(stage.global_position + aim2, Vector3.UP)
			cam.make_current()
			ap.play(clip)
			var strip: Array = []
			for f in frames:
				ap.seek(ln * f / float(frames), true)
				await get_tree().process_frame
				await get_tree().process_frame
				await _shot("clip_%s_%s_%d" % [id, clip, f], false)
				strip.append(last_img)
			await _sheet("anim_%s_%s" % [id, clip], strip, 0.3)
		stage.queue_free()
		main.world.show()
		return
	var views := [["front", 0.0, false], ["three", 0.65, false], ["side", PI * 0.5, false], ["back", PI, false], ["face", 0.3, true]]
	var body: Array = []
	for v in views:
		m.rotation.y = v[1]
		var close: bool = v[2]
		var aim := Vector3(0, height * (0.9 if close else 0.5), 0)
		var dist := height * (0.75 if close else 2.6)
		cam.position = aim + Vector3(0, height * (0.02 if close else 0.12), dist)
		cam.look_at(stage.global_position + aim, Vector3.UP)
		cam.make_current()
		for k in 20:
			t0 += 1.0 / 30.0
			if m.get_meta("kind", "") == "person":
				Models.anim_person(m, t0 + 0.5, false)
			else:
				Models.anim_monster(m, t0 + 0.5, 0.0)
			await get_tree().process_frame
		await _shot("inspect_%s_%s" % [id, v[0]], not main.args.has("sheet"))
		body.append(last_img)
	if main.args.has("sheet"):
		await _sheet("turnaround_" + id, body, 0.3)
	stage.queue_free()
	main.world.show()

## The hero runs down the longest free line of tiles with Yue Ling at his shoulder, then stops; a
## camera on her side tracks them (--follow writes follow_<id>.png).  Both should face the way they
## run, and she should stop running once she has caught up.
func _follow(id: String) -> void:
	var wo = main.world
	var dir := Vector2i(1, 0)
	var best := -1
	for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n := 0
		while n < 10 and wo.tile_free(wo.ptile + dv * (n + 1)) and wo.ent_at(wo.ptile + dv * (n + 1)) == null:
			n += 1
		if n > best:
			best = n
			dir = dv
	var fwd := Vector3(dir.x, 0.0, dir.y)
	var side := Vector3(-dir.y, 0.0, dir.x)  # Yue Ling's side of the hero
	main.bot_active = true  # hold the direction: the keyboard is not read while the bot flag is up
	wo.move_dir = dir
	var strip: Array = []
	for k in 7:
		if k == 4:
			wo.move_dir = Vector2i.ZERO
		for f in (5 if k < 4 else 9):
			var hp: Vector3 = wo._player_pos()
			var eye := hp + side * 8.0 - fwd * 1.0 + Vector3(0.0, 2.0, 0.0)
			wo.cam_override = Transform3D(Basis.IDENTITY, eye).looking_at(hp + side * 0.8 + Vector3(0.0, 0.9, 0.0), Vector3.UP)
			await get_tree().process_frame
		await _shot("follow_%s_%d" % [id, k], false)
		strip.append(last_img)
	wo.move_dir = Vector2i.ZERO
	main.bot_active = false
	wo.cam_override = null
	await _sheet("follow_" + id, strip, 0.4)

## The nearest walkable tile with nobody on it, on dry ground if there is any within 20 steps: the
## shore of a river or pond is sunk below the waterline in 3D, so heroes standing on the bank
## itself seem to wade in the water.
func _nearest_free(pos: Vector2i) -> Vector2i:
	for dry in [true, false]:
		for r in 20:
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					var p := pos + Vector2i(dx, dy)
					if maxi(absi(dx), absi(dy)) != r or not main.world.tile_free(p) or main.world.ent_at(p) != null:
						continue
					if not dry or not _by_water(p):
						return p
	return pos

func _by_water(p: Vector2i) -> bool:
	var gw: int = main.world.w
	var gh: int = main.world.h
	var g: PackedByteArray = main.world.grid
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q := p + Vector2i(dx, dy)
			if q.x >= 0 and q.y >= 0 and q.x < gw and q.y < gh and g[q.y * gw + q.x] == MapGen.WATER:
				return true
	return false

func _run() -> void:
	await _wait(1.0)
	await _shot("01_title")
	var only: PackedStringArray = str(main.args.get("areas", "")).split(",", false)
	var skip_bosses: bool = main.args.has("no-bosses")
	for id in Data.AREA_CHAIN:
		if not only.is_empty() and not only.has(id):
			continue
		var stop: Array = _stop(id)
		Game.reset()
		Game.level = stop[1]
		Game.exp = Data.EXP_NEED[mini(Game.level, Data.EXP_NEED.size() - 1)] * 0.45
		Game.stones = 800
		Game.companion = true
		Game.heal_full()
		Game.hp[0] = Game.max_hp(0) * 0.8
		Game.step = Data.step_index(stop[0])
		for b in Data.ENEMIES:
			if Data.ENEMIES[b].get("boss", false):
				Game.boss_done.erase(b)
		main.world.clear_cache()
		var spec: Dictionary = Data.AREAS[id]
		var focus: Vector2i = Vector2i(14, 22)
		if spec.has("bosses"):
			focus = spec.bosses[0].pos + Vector2i(-7, 2)
		elif spec.has("npcs"):
			focus = spec.npcs[0].pos + Vector2i(0, 3)
		main.set_stack(["world"])
		main.world.open_world()
		# (the realm the region lies in first: its tiles are its own, Part XI)
		var lid: String = Data.layer_of(id)
		main.world.enter_layer(lid)
		main.world.teleport(_nearest_free(Atlas.to_world(id, focus)), lid)
		main.world.facing = Vector2i(1, 0)
		main.world.cam_q = 1  # behind the hero, who faces east
		main.world._snap_cam()
		main.world.banner_t = 0.0
		# --battles-only (developer tool): only the battle screenshots of the chosen regions
		var battles_only: bool = main.args.has("battles-only")
		await _wait(0.2 if battles_only else 1.2)
		if not battles_only:
			await _shot("world_" + id)
		if main.args.has("follow"):
			await _follow(id)
		if main.args.has("vista"):
			# a wide, high establishing shot over the region's landscape
			var pp: Vector3 = main.world._player_pos()
			var eye := pp + Vector3(-14.0, 11.0, 16.0)
			eye.y = maxf(eye.y, main.world.ground_y(eye) + 9.0)
			main.world.cam_override = Transform3D(Basis.IDENTITY, eye).looking_at(pp + Vector3(10.0, 0.0, -10.0), Vector3.UP)
			await _wait(0.6)
			await _shot("vista_" + id)
			main.world.cam_override = null
		if id == "sect":
			# the sect's architecture from above: halls, pagoda, walls, gate archways, the pond bridge
			var so := Vector3(Atlas.to_world("sect", Vector2i.ZERO).x, 0, Atlas.to_world("sect", Vector2i.ZERO).y) * Terrain3D.T
			main.world.cam_override = Transform3D(Basis.IDENTITY, so + Vector3(41, 26, 70)).looking_at(so + Vector3(41, 0, 28), Vector3.UP)
			await _wait(0.6)
			await _shot("architecture_sect")
			main.world.cam_override = Transform3D(Basis.IDENTITY, so + Vector3(30, 9, 30)).looking_at(so + Vector3(41, 3, 8), Vector3.UP)
			await _wait(0.4)
			await _shot("architecture_hall")
			# the open world from high above the sect: the mountain, its roads and the bamboo forest beyond
			main.world.cam_override = Transform3D(Basis.IDENTITY, so + Vector3(-30, 90, 120)).looking_at(so + Vector3(90, 0, 10), Vector3.UP)
			await _wait(0.8)
			await _shot("openworld_sect")
			main.world.cam_override = null
			# inside the buildings: the roof lifts away while the hero is indoors
			for inn in [["interior_hall", Vector2i(20, 6), Vector2i(0, -1)], ["interior_pharmacy", Vector2i(7, 10), Vector2i(0, -1)], ["interior_smithy", Vector2i(32, 10), Vector2i(0, -1)], ["interior_library", Vector2i(31, 17), Vector2i(1, 0)]]:
				main.world.teleport(Atlas.to_world("sect", inn[1]))
				main.world.facing = inn[2]
				main.world.cam_q = main.world.FWD.find(inn[2])
				main.world._snap_cam()
				await _wait(0.8)
				await _shot(inn[0])
		if id == "village":
			# Granny Wen at home: the roof lifts away while the hero is inside
			main.world.teleport(Atlas.to_world("village", Vector2i(10, 23)))
			main.world.facing = Vector2i(0, -1)
			main.world.cam_q = 0
			main.world._snap_cam()
			await _wait(0.8)
			await _shot("interior_village")
		if id == "yanggu":
			# the Dawn Market from above its main street, and Ah Mei among her lanterns indoors
			var mo := Atlas.to_world("yanggu", Vector2i(30, 30))
			var mp := Terrain3D.world_pos(mo)
			main.world.cam_override = Transform3D(Basis.IDENTITY, mp + Vector3(-6.0, 22.0, 26.0)).looking_at(mp + Vector3(14.0, 0.0, -6.0), Vector3.UP)
			await _wait(0.8)
			await _shot("market_yanggu")
			main.world.cam_override = null
			main.world.teleport(Atlas.to_world("yanggu", Vector2i(12, 37)))
			main.world.facing = Vector2i(0, -1)
			main.world.cam_q = 0
			main.world._snap_cam()
			await _wait(0.8)
			await _shot("interior_yanggu")
		# Part X: the towns and great landmarks, each from above at an angle
		for shot in ([] if battles_only else TOWN_SHOTS.get(id, [])):
			var tp: Vector3 = main.world.wpos(Atlas.to_world(shot[1], shot[2]))
			tp.y = main.world.ground_y(tp)
			var eye: Vector3 = tp + shot[3]
			main.world.cam_override = Transform3D(Basis.IDENTITY, eye).looking_at(tp + shot[4], Vector3.UP)
			await _wait(0.8)
			await _shot(shot[0])
			main.world.cam_override = null
		# Part XI: upstairs and down: the hero on the floor where the stairs come out, looking into the room
		for fshot in ([] if battles_only else FLOOR_SHOTS.get(id, [])):
			var fwd: Dictionary = Atlas.world_of(fshot[1])
			if fwd.is_empty():
				continue
			main.world.teleport(fwd.start, fshot[1])
			var mid := Vector2(fwd.w, fwd.h) * 0.5
			var dv := mid - Vector2(fwd.start)
			var fdir := Vector2i(signi(int(dv.x)), 0) if absf(dv.x) > absf(dv.y) else Vector2i(0, signi(int(dv.y)))
			if fdir == Vector2i.ZERO:
				fdir = Vector2i(0, 1)
			main.world.facing = fdir
			main.world.cam_q = main.world.FWD.find(fdir)
			main.world._snap_cam()
			await _wait(0.8)
			await _shot(fshot[0])
		if not battles_only and not FLOOR_SHOTS.get(id, []).is_empty():
			main.world.enter_layer(lid)
			main.world.teleport(_nearest_free(Atlas.to_world(id, focus)), lid)
		if id == "fusang":
			# the colossal Fusang across the valley, the stuck sun glowing in its crown
			var fo := Terrain3D.world_pos(Atlas.to_world("fusang", Data.AREAS.fusang.landmark.pos))
			fo.y = main.world.ground_y(fo)
			main.world.cam_override = Transform3D(Basis.IDENTITY, fo + Vector3(-58.0, 16.0, 40.0)).looking_at(fo + Vector3(0.0, 32.0, 0.0), Vector3.UP)
			await _wait(0.8)
			await _shot("fusang_tree")
			main.world.cam_override = null
		if id == "sect" or main.args.has("world-only"):
			continue
		# a regular battle with this region's monster pool
		var foes: Array = []
		for k in 3:
			var pe: Array = spec.pool[k % spec.pool.size()]
			foes.append({"id": pe[0], "lv": pe[1]})
		main.battle.start(foes, {"entity": {"id": "x", "group": foes}, "boss": false, "theme": spec.theme})
		main.push("battle")
		await _wait(2.6)
		main.battle.fx.append({"text": "1337! weak", "p": main.battle.head3(main.battle.foes[0]), "t": 0.75, "col": Color("f6e85c"), "slash": ELEMS[id]})
		Fx3D.hit(main.battle.scene3d, main.battle.pos3(main.battle.foes[0]) + Vector3(0, 1.4, 0), ELEMS[id])
		await _wait(0.12)
		await _shot("battle_" + id)
		main.pop()
		# every boss of the region, one screenshot each
		for b in spec.bosses:
			if skip_bosses and b != spec.bosses[spec.bosses.size() - 1]:
				continue
			main.battle.start([{"id": b.id, "lv": b.lv}], {"entity": b, "boss": true, "enemy": b.id, "theme": spec.theme})
			main.push("battle")
			await _wait(2.8)
			await _shot("battle_boss_" + b.id)
			main.pop()
	# chosen bosses, each on its own region's battle stage (--boss-shots=id,id: bosses that are not
	# the last of their region, which --no-bosses leaves out)
	if main.args.has("boss-shots"):
		main.world.open_world()
	for bid in str(main.args.get("boss-shots", "")).split(",", false):
		for aid in Data.AREA_CHAIN:
			var aspec: Dictionary = Data.AREAS[aid]
			for bb in aspec.get("bosses", []):
				if bb.id != bid:
					continue
				var bstop: Array = _stop(aid)
				Game.reset()
				Game.level = bstop[1]
				Game.companion = true
				Game.heal_full()
				Game.step = Data.step_index(bstop[0])
				main.set_stack(["world"])
				main.battle.start([{"id": bb.id, "lv": bb.lv}], {"entity": bb, "boss": true, "enemy": bb.id, "theme": aspec.theme})
				main.push("battle")
				await _wait(2.8)
				await _shot("battle_boss_" + bb.id)
				main.pop()
	# galleries are shot from the world screen (the title menu would cover them)
	main.set_stack(["world"])
	main.world.load_area("sect", Vector2i(20, 9))
	main.world.banner_t = 0.0
	if main.args.has("inspect"):
		var tint := Color(main.args.get("tint", "c8a070"))
		for id2 in str(main.args.inspect).split(",", false):
			var mm: Node3D
			var hgt := 1.8
			if Assets.PEOPLE.has(id2):
				mm = Assets.person(id2)
			else:
				mm = _foe(id2) if Data.ENEMIES.has(id2) else Models.monster(id2, tint)
				var ab := AABB()
				for mi in mm.get_meta("meshes", []):
					ab = ab.merge((mi as MeshInstance3D).get_aabb())
				hgt = maxf(ab.size.y, ab.size.x * 0.6)
			await _inspect(id2, mm, hgt)
	if main.args.has("show"):
		# a quick look at chosen models (developer tool): --show=beast,fox,yue_ling
		var cols := [Color("7aa860"), Color("d0602a"), Color("3a8ad8"), Color("c8a040"), Color("9a6ad0"), Color("40b0a0")]
		var picks: PackedStringArray = str(main.args.show).split(",", false)
		for pass_i in 2:
			var ms: Array = []
			for i in picks.size():
				var id: String = picks[i]
				if Assets.PEOPLE.has(id):
					ms.append(Assets.person(id))
				elif Data.ENEMIES.has(id):
					# an enemy by id: its shape in its own palette (element accent, pinned colours)
					ms.append(_foe(id))
				elif not Assets.has_monster(id) and Assets.has("props/" + id):
					var ph := Node3D.new()
					MB.mesh_node(ph, Assets.static_mesh("props/" + id))
					ms.append(ph)
				else:
					ms.append(Models.monster(id, cols[i % cols.size()]))
			if pass_i == 0:
				await _gallery("show", ms, 1.3, 1.25)
			else:
				await _portraits("show_close", ms, 1.9, 1.0, 4.6)
	# Part X: the people of the four new towns and the bosses of the Nine Cauldrons (--gallery10 shoots
	# only these)
	if main.args.has("gallery") or main.args.has("gallery10") or not main.args.has("no-extras"):
		await _gallery("gallery_townsfolk_cloudfoot", [
			Assets.person("cartographer_pei"), Assets.person("postmaster_lu"), Assets.person("storyteller_wu"),
			Assets.person("caravan_kang"), Assets.person("priestess_yun"), Assets.person("stableboy_shitou"),
		], 0.8)
		await _gallery("gallery_townsfolk_longmen", [
			Assets.person("harbour_yao"), Assets.person("boatwright_gao"), Assets.person("fishwife_lu"), Assets.person("lockkeeper_qian"),
			Assets.person("shrine_hua"), Assets.person("scholar_cen"), Assets.person("carp_boy_yu"), Assets.person("innkeeper_dong"),
		], 0.72)
		await _gallery("gallery_townsfolk_tushan", [
			Assets.person("tu_lan"), Assets.person("caster_wei"), Assets.person("carver_shi"), Assets.person("charcoal_tan"),
			Assets.person("innkeeper_lou"), Assets.person("little_qi"), Assets.person("bo_yi"), Assets.person("yinglong"),
		], 0.72)
		await _gallery("gallery_townsfolk_shazhou", [
			Assets.person("well_keeper_zhaya"), Assets.person("cook_aysha"), Assets.person("star_reader_kumar"),
			Assets.person("camel_boy_temur"), Assets.person("nomad"),
		], 0.8)
		await _gallery("gallery_part10", [
			_foe("he_bo", true), _foe("gun", true), _foe("taotie", true), _foe("xiangliu", true), _foe("gonggong", true),
		], 1.7)
	# Part XI: the peoples of the realms above and below and the bosses of the Ladder of Heaven
	# (--gallery11 shoots only these)
	if main.args.has("gallery") or main.args.has("gallery11") or not main.args.has("no-extras"):
		await _gallery("gallery_yumin_dragons", [
			Assets.person("ling_yu"), Assets.person("yu_hua"), Assets.person("yu_jian"), Assets.person("egg_warden_luan"),
			Assets.person("que_er"), Assets.person("ao_run"), Assets.person("ao_qing"),
		], 0.76)
		await _gallery("gallery_foxes_jiaoren", [
			Assets.person("hu_qingyi"), Assets.person("hu_meier"), Assets.person("gate_fox_hu"),
			Assets.person("shui_lian"), Assets.person("hai_ge"), Assets.person("little_bei"),
		], 0.8)
		await _gallery("gallery_deathless_shades", [
			Assets.person("bu_si"), Assets.person("chang_sheng"), Assets.person("houtu"),
			Assets.person("ming_yi"), Assets.person("zhi_ma"), Assets.person("shade_lan"),
		], 0.8)
		await _gallery("gallery_part11", [
			_foe("leigong", true), _foe("jiufeng", true), _foe("zhulong", true), _foe("hei_wuchang", true),
			_foe("tubo", true), _foe("li", true),
		], 1.5)
	if main.args.has("gallery") or not main.args.has("no-extras"):
		await _gallery("gallery_people", [
			Models.person(Color("3a8ae8"), Color("1a1a2a"), main.world.HERO_OPTS),
			Models.person(Color("e86a9a"), Color("402030"), main.world.YUE_OPTS),
			Models.person(Color("e8e8ff"), Color("2a2a3a"), {"asset": "elder_qing", "beard": true, "staff": true, "hair": "bald", "trim": Color("c8a850")}),
			_foe("iron_fang"),
			_foe("demon_lord"),
		], 1.0)
		# Blender-built NPCs (art/characters)
		await _gallery("gallery_npcs", [
			Assets.person("alchemist"), Assets.person("smith"), Assets.person("nomad"),
			Assets.person("spore_witch"), Assets.person("steppe_shaman"), Assets.person("nuwa_echo"),
		], 0.8)
		# Part V creatures (art/monsters)
		await _gallery("gallery_part5", [
			_foe("glass_scorpion"), _foe("spore_mother"), _foe("mammoth_ancestor"),
			_foe("moth_queen"), _foe("hundun"),
		], 1.7)
		# Part VI people (art/characters)
		await _gallery("gallery_npcs_part6", [
			Assets.person("lantern_monk"), Assets.person("fisher"), Assets.person("meng_po"),
			Assets.person("judge_cui"), Assets.person("lin_shan"), Assets.person("su_wan"),
		], 0.8)
		# earlier NPCs, now Blender-built
		await _gallery("gallery_npcs_keepers", [
			Assets.person("sword_ghost"), Assets.person("dragon_envoy"), Assets.person("fire_sage"), Assets.person("lake_keeper"),
			Assets.person("cloud_warden"), Assets.person("forge_master"), Assets.person("peach_keeper"),
		], 0.7)
		# Part VI creatures (art/monsters)
		await _gallery("gallery_part6", [
			_foe("nine_tail_fox"), _foe("waterfall_koi"), _foe("ox_head"),
			_foe("horse_face"), _foe("corpse_patriarch"),
		], 1.7)
		# Part VII and VIII people (art/characters)
		await _gallery("gallery_npcs_part7", [
			Assets.person("granny_wen"), Assets.person("innkeeper"), Assets.person("weaver_liu"),
			Assets.person("tea_master"), Assets.person("can_niang"), Assets.person("apprentice_zhi"), Assets.person("archivist"),
		], 0.7)
		await _gallery("gallery_npcs_part8", [
			Assets.person("niu_lang"), Assets.person("zhi_nu"), Assets.person("que_lao"), Assets.person("dong_shuang"),
		], 0.9)
		# Part VIII creatures (art/monsters)
		await _gallery("gallery_part8", [
			_foe("jade_qilin"), _foe("white_tiger"), _foe("thunder_ape"),
			_foe("bridge_magpie"), _foe("kaiming_beast"),
		], 1.7)
		await _gallery("gallery_part8_bosses", [
			_foe("xiwangmu"), _foe("river_warden"), _foe("crow_marshal"),
		], 1.5)
		# Part IX people and creatures (art/characters, art/monsters)
		await _gallery("gallery_npcs_part9", [
			Assets.person("ah_mei"), Assets.person("farmer_tian"), Assets.person("feng_meng"), Assets.person("chang_e"),
		], 0.9)
		# the townsfolk: the sect's own people, Qingshi Village and the Dawn Market at Yanggu
		await _gallery("gallery_townsfolk_sect", [
			Assets.person("disciple_han"), Assets.person("disciple_mei"), Assets.person("cook_zhou"),
			Assets.person("sweeper_bai"), Assets.person("gate_wu"), Assets.person("bell_shen"),
		], 0.8)
		await _gallery("gallery_townsfolk_village", [
			Assets.person("farmer_lao"), Assets.person("child_hua"), Assets.person("tofu_sun"),
			Assets.person("scholar_wang"), Assets.person("carpenter_gu"), Assets.person("herb_lan"),
		], 0.8)
		await _gallery("gallery_townsfolk_market", [
			Assets.person("watchman_zhou"), Assets.person("innkeeper_bao"), Assets.person("tea_seller_pan"), Assets.person("dyer_su"),
			Assets.person("monk_huiming"), Assets.person("granny_gu"), Assets.person("porter_niu"), Assets.person("little_dou"),
		], 0.7)
		await _gallery("gallery_part9", [
			_foe("jinwu"), _foe("mortar_rabbit"), _foe("bifang"),
			_foe("hanba"), _foe("xihe"),
		], 1.7)
		# one shape, three enemies: the palette (Assets.palette) turns a single tint into a scheme
		await _gallery("gallery_palettes", [
			_foe("bamboo_wolf"), _foe("frost_wolf"), _foe("blood_hound"),
			_foe("dragon_king"), _foe("dune_leviathan"),
		], 1.7)
		# one enemy per element: the accent (eyes, crests, glow) follows the element
		await _gallery("gallery_elements", [
			_foe("leaf_sprite"), _foe("magma_slime"), _foe("tide_qilin"),
			_foe("jade_lion"), _foe("thunder_ape"), _foe("void_sentinel"),
		], 1.5)
		# Blender landmarks (art/props)
		var props: Array = []
		for pr in ["pine", "bamboo", "peach", "meteor", "glowcap", "icespire", "chaosrock", "stonelantern", "ghostpagoda"]:
			var holder := Node3D.new()
			MB.mesh_node(holder, Assets.static_mesh("props/" + pr))
			props.append(holder)
		await _gallery("gallery_props", props, 1.3)
		# Blender landmarks of the built regions
		var built: Array = []
		for pr2 in ["obelisk", "jadepillar", "column", "furnace", "gear", "monolith", "floatisle", "shard"]:
			var holder2 := Node3D.new()
			MB.mesh_node(holder2, Assets.static_mesh("props/" + pr2))
			built.append(holder2)
		await _gallery("gallery_landmarks", built, 1.1)
		var built8: Array = []
		for pr3 in ["ferrypost", "magpienest", "starpillar", "jadepeach"]:
			var holder3 := Node3D.new()
			MB.mesh_node(holder3, Assets.static_mesh("props/" + pr3))
			built8.append(holder3)
		await _gallery("gallery_landmarks_part8", built8, 1.4)
		await _gallery("gallery_beasts", [
			_foe("bamboo_wolf"), _foe("jade_mantis"), _foe("time_tortoise"),
			_foe("crab_general"), _foe("rift_spider"),
		], 1.5)
		await _gallery("gallery_spirits", [
			_foe("ash_phoenix"), _foe("manta_sovereign"), _foe("abyss_jelly"),
			_foe("bog_wraith"), _foe("jade_ledger", true),
		], 1.6)
		await _gallery("gallery_giants", [
			_foe("dragon_king"), _foe("lava_titan"), _foe("tide_hydra"),
			_foe("bamboo_spirit"), _foe("tribulation"),
		], 1.7)
	if main.args.has("portraits") or not main.args.has("no-extras"):
		await _portraits("portrait_heroes", [
			Models.person(Color("3a8ae8"), Color("1a1a2a"), main.world.HERO_OPTS),
			Models.person(Color("e86a9a"), Color("402030"), main.world.YUE_OPTS),
			Models.person(Color("e8e8ff"), Color("2a2a3a"), {"asset": "elder_qing", "beard": true, "staff": true, "hair": "bald", "trim": Color("c8a850")}),
		], 0.9, 1.5, 3.2)
		# Part IX's leads close up: Ah Mei, Farmer Tian, Feng Meng and Chang'e
		await _portraits("portrait_part9", [
			Assets.person("ah_mei"), Assets.person("farmer_tian"), Assets.person("feng_meng"), Assets.person("chang_e"),
		], 0.85, 1.5, 3.6)
	if main.args.has("map"):
		# the world map from Cloudfoot, the post town under the north gate, and the Annals
		for rid in [Atlas.HUB] + Data.AREA_CHAIN:
			Game.seen[rid] = true
		main.world.load_area("mountain", Vector2i(82, 36))
		main.open_menu()
		main.menu.mode = "map"
		main.menu._build()
		await _wait(0.5)
		await _shot("world_map")
		main.menu.mode = "annals"
		main.menu._build()
		main.menu.cursor = 2
		await _wait(0.3)
		await _shot("annals")
		main.pop()
		main.pop()
	if main.args.has("daos"):
		# Part XI: choosing a road at a Dao Stele, the Dao and peoples page, the maps of the realms
		Game.dao = "heart"
		Game.dao_xp = {"heart": 22, "sword": 44, "wander": 3}
		Game.standing = {"yumin": 64, "dragon": 38, "tianhu": 51, "jiaoren": 20, "deathless": 8, "shade": 70}
		Game.met = {"yumin": true, "dragon": true, "tianhu": true, "jiaoren": true, "deathless": true, "shade": true}
		main.world.load_area("sect", Vector2i(16, 12))
		main.open_dao_choice("stele")
		main.choice.cursor = 2
		await _wait(0.5)
		await _shot("dao_choice")
		main.pop()
		main.open_menu()
		main.menu.mode = "dao"
		main.menu._build()
		await _wait(0.4)
		await _shot("dao_peoples")
		main.menu.mode = "map"
		for rid3 in Atlas.all_region_ids():
			Game.seen[rid3] = true
		for ml in ["surface", "heaven", "under"]:
			main.menu.map_layer = ml
			main.menu._build()
			await _wait(0.4)
			await _shot("world_map" if ml == "surface" else "world_map_" + ml)
		main.pop()
	if main.args.has("ending"):
		# the results screen on its own (--ending): the finale set pieces of every part
		main.push("ending")
		await _wait(14.0)
		await _shot("ending")
	if main.args.has("no-extras"):
		get_tree().quit(0)
		return
	# tribulation, meditation, menu, shop, dialogue, ending
	Game.reset()
	Game.level = 14
	Game.exp = 1000
	Game.companion = true
	Game.heal_full()
	Game.step = Data.step_index("s_break5")
	main.set_stack(["world"])
	main.world.load_area("volcano", Vector2i(10, 28))
	main.battle.start([{"id": "tribulation", "lv": 15, "mult": 1.1}], {"boss": true, "tribulation": true, "step": "s_break5", "theme": "thunder"})
	main.push("battle")
	await _wait(2.8)
	await _shot("battle_tribulation")
	main.pop()
	main.start_meditation()
	await _wait(3.0)
	await _shot("meditate")
	main.pop()
	main.open_menu()
	await _wait(0.3)
	await _shot("menu")
	main.menu.mode = "map"
	main.menu._build()
	await _wait(0.3)
	await _shot("world_map")
	main.pop()
	main.shop.open("alchemist")
	main.push("shop")
	await _wait(0.3)
	await _shot("shop")
	main.pop()
	main.world.load_area("sect", Vector2i(20, 9))
	main.world.banner_t = 0.0
	main.say([["Elder Qing Xuan", "Lin Feng. Three years you have swept the steps of Azure Cloud Sect, and three years your qi has refused to stir."], ["Lin Feng", "Elder, I have tried every method in the scriptures."]])
	await _wait(3.5)
	await _shot("02_dialogue")
	main.pop()
	main.push("ending")
	await _wait(1.5)
	await _shot("ending")
	get_tree().quit(0)
