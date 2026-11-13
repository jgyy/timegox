extends Node
## Screenshot tour (developer tool).  Teleports through every screen, region and boss and saves
## PNGs.  Needs a real window (use xvfb on a server):
##   godot --path . --fixed-fps 30 -- --tour=docs/screenshots

var main
var dir := ""
## the playthrough bot's plan through the trials (the screenshots show a game that took those roads)
const BOT := preload("res://scripts/bot.gd")

const ELEMS := {"penglai": "earth", "fangzhang": "water", "yingzhou": "thunder", "guixu": "fire", "juntian": "thunder", "changhe": "wood", "ninesprings": "thunder", "youdu": "fire", "sect": "phys", "bamboo": "fire", "marsh": "fire", "frost": "thunder", "thunder": "earth", "palace": "water", "dragon": "thunder", "volcano": "water", "void": "dark", "celestial": "thunder", "mirror": "thunder", "grave": "fire", "time": "dark", "origin": "thunder", "cloudsea": "thunder", "court": "fire", "forge": "water", "garden": "fire", "dunes": "wood", "fungal": "fire", "aurora": "earth", "chaos": "thunder", "maple": "water", "karst": "thunder", "springs": "fire", "wheel": "thunder", "mountain": "phys", "village": "thunder", "terraces": "earth", "silk": "fire", "loom": "fire", "starferry": "earth", "magpie": "wood", "starpalace": "earth", "jasper": "wood", "yanggu": "water", "millet": "fire", "fusang": "thunder", "guanghan": "thunder", "longmen": "earth", "drowned": "earth", "tushan": "water", "buzhou": "earth"}

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
	# Part XII: the Isles of the Eastern Sea, Landfall, the Pavilion of Penglai and the Returning Ruins
	"penglai": [["town_landfall", "penglai", Vector2i(40, 30), Vector3(-30.0, 28.0, 32.0), Vector3(2.0, 0.0, -4.0)],
		["penglai_pavilion", "penglai", Vector2i(8, 26), Vector3(-22.0, 12.0, 26.0), Vector3(2.0, 7.0, 0.0)],
		["realm_sea", "penglai", Vector2i(60, 32), Vector3(-80.0, 60.0, 110.0), Vector3(40.0, -10.0, -30.0)]],
	"fangzhang": [["isle_fangzhang", "fangzhang", Vector2i(36, 26), Vector3(-30.0, 26.0, 30.0), Vector3(2.0, 0.0, -2.0)]],
	"yingzhou": [["isle_yingzhou", "yingzhou", Vector2i(46, 28), Vector3(-30.0, 24.0, 30.0), Vector3(2.0, 0.0, -2.0)]],
	"guixu": [["guixu_whirl", "guixu", Vector2i(86, 32), Vector3(-34.0, 24.0, 30.0), Vector3(12.0, -4.0, 0.0)]],
	"fusang": [["mazu_boat", "fusang", Vector2i(70, 48), Vector3(-9.0, 6.0, 11.0), Vector3(0.0, 1.0, 0.0)]],
}
## Part XI: upstairs and down in the buildings: [shot name, floor id]
const FLOOR_SHOTS := {
	"sect": [["cellar_sealed_archive", "f:sect:library:-1"], ["cellar_ancestral_crypt", "f:sect:hall:-1"], ["upper_dormitory", "f:sect:dormitory:1"]],
	"juntian": [["upper_aerie_tower", "f:juntian:aerie_tower:1"], ["cellar_archive_of_rain", "f:juntian:rain_ministry:-1"], ["cellar_egg_nursery", "f:juntian:egg_nursery:-1"]],
	"changhe": [["upper_moon_terrace", "f:changhe:fox_pavilion:1"]],
	"ninesprings": [["cellar_pearl_vault", "f:ninesprings:pearl_hall:-1"], ["upper_root_loft", "f:ninesprings:root_house:1"]],
	"youdu": [["upper_ward_office", "f:youdu:ward_office:1"], ["cellar_deep_hall", "f:youdu:earth_palace:-1"]],
	"longmen": [["upper_guest_rooms", "f:longmen:carp_inn:1"]],
	"penglai": [["upper_drinking_room", "f:penglai:drunk_immortal:1"], ["upper_names_gallery", "f:penglai:names_hall:1"]],
	"guixu": [["upper_steersman_cabin", "f:guixu:wreck_house:1"]],
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
		last_img.save_webp("%s/%s.webp" % [dir, n], true, 0.9)
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
	out.save_webp("%s/%s.webp" % [dir, n], true, 0.9)
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
			if m2.get_meta("kind", "") == "ride_group":
				# (a ride with its riders, posed once: Fates and Faces)
				continue
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
## checked from every side.  Writes inspect_<id>_<view>.webp.
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
		# a strip of frames through a clip, seen from the side (--clip=run [--frames=6]); several clips
		# at once with a comma between them (--clip=sit_bench,drink)
		var ap: AnimationPlayer = m.get_meta("ap", null)
		var frames := int(main.args.get("frames", "6"))
		for clip in str(main.args.clip).split(",", false):
			if ap == null or not ap.has_animation(clip):
				print("[tour] no clip ", clip)
				continue
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

## A sheet of one monster shape framed from its own bounds (developer tool, --beasts=tiger,ape,...):
## three-quarter front, side, three-quarter back and a close-up of the head (found from its "head"
## bone), so the sculpt can be judged from every side.  Writes beast_<shape>.webp; with --beasts-tag=x
## writes beast_<shape>_x.webp, for before-and-after comparisons.
func _beast_sheet(shape: String, tint: Color) -> Image:
	var m: Node3D = _foe(shape) if Data.ENEMIES.has(shape) else Models.monster(shape, tint)
	return await _model_sheet(m)

## The same sheet for any model (a person, a test export: --people=yue_ling,characters/zz_test).
func _model_sheet(m: Node3D) -> Image:
	var sc := _bare_stage(480.0, 30.0, 9.0)
	var stage: Node3D = sc[0]
	var cam: Camera3D = sc[1]
	stage.add_child(m)
	m.add_child(Models.shadow_disc(0.8))
	var ab := AABB()
	var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var mm := mi as MeshInstance3D
		if mm.mesh == null or not mm.visible:
			continue
		var bb: AABB = mm.transform * mm.get_aabb()
		ab = bb if first else ab.merge(bb)
		first = false
	var ctr := ab.get_center()
	var rad := maxf(0.3, ab.size.length() * 0.5)
	var dist := rad / sin(deg_to_rad(cam.fov * 0.5)) * 0.92
	var sk: Skeleton3D = Assets._skeleton(m)
	var views := [["three", 0.7, false], ["side", PI * 0.5, false], ["back", PI + 0.75, false], ["head", 0.45, true]]
	var shots: Array = []
	var t0 := 0.0
	for v in views:
		m.rotation.y = -float(v[1])
		for k in 24:
			t0 += 1.0 / 30.0
			Models.anim_monster(m, t0 + 0.5, 0.0)
			await get_tree().process_frame
		if bool(v[2]):
			var hp := ctr + Vector3(0, ab.size.y * 0.3, ab.size.z * 0.3)
			if sk != null and sk.find_bone("head") >= 0:
				var hb := sk.find_bone("head")
				# (the middle of the head bone: its head is the back of the skull, its tail the snout)
				var gp: Transform3D = sk.global_transform * sk.get_bone_global_pose(hb)
				var tail_l := Vector3.ZERO
				for cb in sk.get_bone_children(hb):
					tail_l = sk.get_bone_rest(cb).origin
					break
				hp = stage.to_local(gp * (tail_l * 0.5))
			var fwd := Vector3(sin(m.rotation.y), 0, cos(m.rotation.y))
			var hd := clampf(rad * 0.7, 0.45, 3.2)
			cam.position = hp + (fwd.rotated(Vector3.UP, 0.5)) * hd + Vector3(0, hd * 0.12, 0)
			cam.look_at(stage.to_global(hp), Vector3.UP)
		else:
			cam.position = ctr + Vector3(0, rad * 0.32, dist)
			cam.look_at(stage.to_global(ctr), Vector3.UP)
		cam.make_current()
		await get_tree().process_frame
		await _shot("beast_view", false)
		shots.append(last_img)
	stage.queue_free()
	main.world.show()
	var fw: int = shots[0].get_width()
	var fh: int = shots[0].get_height()
	var cw := int(fw * 0.62)
	var out := Image.create(cw * 2, fh * 2, false, Image.FORMAT_RGB8)
	for i in shots.size():
		var im: Image = shots[i]
		im.convert(Image.FORMAT_RGB8)
		out.blit_rect(im, Rect2i((fw - cw) / 2, 0, cw, fh), Vector2i((i % 2) * cw, (i / 2) * fh))
	out.resize(int(out.get_width() * 0.75), int(out.get_height() * 0.75), Image.INTERPOLATE_LANCZOS)
	return out

## A person's turnaround at full height (front, three-quarter, side, back) and two close views of the
## body (chest to knee from the front and the three-quarter), in one strip.
func _person_turn(m: Node3D) -> Image:
	var sc := _bare_stage(500.0, 30.0, 9.0)
	var stage: Node3D = sc[0]
	var cam: Camera3D = sc[1]
	stage.add_child(m)
	m.add_child(Models.shadow_disc(0.6))
	var views := [[0.0, false], [0.7, false], [PI * 0.5, false], [PI, false], [0.0, true], [0.75, true]]
	if main.args.has("faces"):
		# (--faces: the head close, from the front, the three-quarter and the side)
		views = [[0.0, 2], [0.55, 2], [PI * 0.5, 2], [-0.4, 2]]
	var shots: Array = []
	var t0 := 0.0
	for v in views:
		m.rotation.y = -float(v[0])
		for k in 20:
			t0 += 1.0 / 30.0
			Models.anim_person(m, t0 + 0.4, false)
			await get_tree().process_frame
		if typeof(v[1]) == TYPE_INT:
			var sk2: Skeleton3D = Assets._skeleton(m)
			var hy := 1.68
			if sk2 != null and sk2.find_bone("eyes") >= 0:
				hy = (sk2.global_transform * sk2.get_bone_global_pose(sk2.find_bone("eyes"))).origin.y - stage.global_position.y
			cam.fov = 18.0
			cam.position = Vector3(0, hy + 0.01, 1.05)
			cam.look_at(stage.to_global(Vector3(0, hy - 0.04, 0)), Vector3.UP)
		elif bool(v[1]):
			cam.fov = 22.0
			cam.position = Vector3(0, 1.08, 2.6)
			cam.look_at(stage.to_global(Vector3(0, 1.0, 0)), Vector3.UP)
		else:
			cam.fov = 30.0
			cam.position = Vector3(0, 1.05, 3.9)
			cam.look_at(stage.to_global(Vector3(0, 0.93, 0)), Vector3.UP)
		cam.make_current()
		await get_tree().process_frame
		await _shot("person_view", false)
		shots.append(last_img)
	stage.queue_free()
	main.world.show()
	var fw: int = shots[0].get_width()
	var fh: int = shots[0].get_height()
	var cw := int(fw * 0.3)
	var out := Image.create(cw * shots.size(), fh, false, Image.FORMAT_RGB8)
	for i in shots.size():
		var im: Image = shots[i]
		im.convert(Image.FORMAT_RGB8)
		out.blit_rect(im, Rect2i((fw - cw) / 2, 0, cw, fh), Vector2i(i * cw, 0))
	return out

func _people_sheets(list: String) -> void:
	var tag := str(main.args.get("beasts-tag", ""))
	for id in list.split(",", false):
		var m: Node3D
		if Assets.PEOPLE.has(id):
			m = Assets.person(id)
		else:
			m = Assets.instance(id)
			m.set_meta("kind", "person")
		if main.args.has("bare"):
			Models.undress(m, true)
		var img := await _person_turn(m)
		var n := "person_%s%s" % [id.get_file(), ("_" + tag) if tag != "" else ""]
		img.save_webp("%s/%s.webp" % [dir, n], true, 0.9)
		print("[tour] ", n)

func _beast_sheets(list: String) -> void:
	var tint := Color(main.args.get("tint", "a87a52"))
	var tag := str(main.args.get("beasts-tag", ""))
	# (a shape is shown as the first foe of the land that wears it, in that foe's own colours, unless
	# --beasts-tint asks for the plain tint: the way the bestiary picks its pages)
	var as_foe: bool = not main.args.has("beasts-tint")
	var foe_of := {}
	for pass_i in 2:
		for id in Data.ENEMIES:
			var sh := str(Data.ENEMIES[id].get("shape", ""))
			if sh == "" or foe_of.has(sh) or (pass_i == 0 and bool(Data.ENEMIES[id].get("boss", false))):
				continue
			foe_of[sh] = id
	for shape in list.split(",", false):
		var who: String = shape
		if as_foe and not Data.ENEMIES.has(shape) and foe_of.has(shape):
			who = str(foe_of[shape])
		var img := await _beast_sheet(who, tint)
		var n := "beast_%s%s" % [shape, ("_" + tag) if tag != "" else ""]
		img.save_webp("%s/%s.webp" % [dir, n], true, 0.9)
		print("[tour] ", n)

## The hero runs down the longest free line of tiles with Yue Ling at his shoulder, then stops; a
## camera on her side tracks them (--follow writes follow_<id>.webp).  Both should face the way they
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
## Part XVI (--part16, or --part16=a,b to pick shots): the Kitchen God, a town drilled in the old
## ways, the noise of the long last night, Xi and Nian, the vigil, the first dawn and the red
## envelopes of New Year's Day.
func _part16_state(step_id: String) -> void:
	_lotus_state("s_p15_end")
	Game.step = Data.step_index(step_id)
	Game.level = 61
	Game.exp = float(Game.exp_need()) * 0.4
	for i in Game.step:
		if str(Data.STEPS[i].kind) == "kill":
			Game.boss_done[str(Data.STEPS[i].boss)] = true
	Game.future = "companion"
	Game.bond = 400
	Game.heal_full()

func _part16_shots(which: String = "1") -> void:
	# (--part16=a,b renders only those shots)
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(names: Array) -> bool:
		if only.is_empty():
			return true
		for n in names:
			if only.has(str(n)):
				return true
		return false
	main.set_stack(["world"])
	# the Kitchen God on the stove
	if want.call(["part16_kitchen_god"]):
		_part16_state("s_p16_kitchen")
		Game.clock = 10.0 * 60.0
		var zj := _land_ent("zao_jun")
		if not zj.is_empty():
			_stand_by(zj)
			await _wait(0.6)
			main.talk_npc(zj)
			for k in 2:
				main.dialogue.shown = 999.0
				main.press("confirm")
				await _wait(0.25)
			main.dialogue.shown = 999.0
			await _wait(1.0)
			await _shot("part16_kitchen_god")
			await _skip_talk()
	# Yanggu remembers the old ways: the drill
	if want.call(["part16_drill"]):
		_part16_state("s_p16_rally")
		Game.clock = 15.5 * 60.0
		var wz := _land_ent("watchman_zhou")
		if not wz.is_empty():
			_stand_by(wz)
			await _wait(1.5)
			main.talk_npc(wz)
			await _skip_talk()
			await _wait(2.0)
			_frame_crowd(Vector3(-11.0, 7.0, 12.0))
			await _wait(0.4)
			await _shot("part16_drill")
			main.world.cam_override = null
	# the long last night: every pot in Yanggu, with lanterns
	if want.call(["part16_noise_night"]):
		_part16_state("s_p16_vigil")
		for npc in ["granny_wen", "watchman_zhou", "postmaster_lu", "caster_wei"]:
			Game.rallied[npc] = true
		Game.clock = 22.4 * 60.0
		main.world.enter_layer("surface")
		main.world.teleport(_nearest_free(Atlas.to_world("yanggu", Vector2i(34, 30))), "surface")
		main.world._snap_cam()
		await _wait(2.5)
		_frame_crowd(Vector3(-10.0, 6.0, 11.0))
		await _wait(0.4)
		await _shot("part16_noise_night")
		main.world.cam_override = null
	# Xi, the Last Night, by the door gods' peach wood
	if want.call(["battle_boss_xi_beast"]):
		var xm: Array = Trials.TRIALS.xi_beast.might
		main.battle.start([{"id": "xi_beast", "lv": 61, "mult": float(xm[0]), "atk": float(xm[1])}], {"boss": true, "enemy": "xi_beast", "theme": "yanggu", "trial": "xi_beast", "path": "relic",
			"boon": Trials.path("xi_beast", "relic").boon, "path_n": "Charms of peach wood", "path_kind": str(Trials.KINDS.relic.n)})
		main.push("battle")
		await _wait(3.4)
		await _shot("battle_boss_xi_beast")
		main.pop()
	# the vigil at Granny Wen's
	if want.call(["part16_vigil", "part16_vigil_choice"]):
		_part16_state("s_p16_vigil")
		Game.clock = 23.0 * 60.0
		var vt := _land_ent("furn:village:wen_house:2")
		if not vt.is_empty():
			main.world.open_world()
			main.world.enter_layer("surface")
			main.world.teleport(_nearest_free(vt.pos + Vector2i(1, 0)), "surface")
			main.world._snap_cam()
			await _wait(0.6)
			main.share_scene(vt, "s_p16_vigil")
			for k2 in 3:
				main.dialogue.shown = 999.0
				main.press("confirm")
				await _wait(0.3)
			main.world.using.t0 = main.world.t - main.world.USE_STEP - 2.0
			main.dialogue.shown = 999.0
			await _wait(1.0)
			await _shot("part16_vigil")
			await _skip_talk()
			await _wait(0.4)
			await _shot("part16_vigil_choice")
			main.choice.press("confirm")
			await _wait(0.3)
			await _skip_talk()
	# Nian, the Year Beast, by every pot in the land
	if want.call(["battle_boss_nian"]):
		var nm: Array = Trials.TRIALS.nian.might
		main.battle.start([{"id": "nian", "lv": 62, "mult": float(nm[0]), "atk": float(nm[1])}], {"boss": true, "enemy": "nian", "theme": "village", "trial": "nian", "path": "folk",
			"boon": Trials.path("nian", "folk").boon, "path_n": "Every pot in the land", "path_kind": str(Trials.KINDS.folk.n)})
		main.push("battle")
		await _wait(3.4)
		await _shot("battle_boss_nian")
		main.pop()
	# New Year's Day in Cloudfoot: the children in red, and a red envelope
	if want.call(["part16_new_year_children", "part16_hongbao"]):
		_part16_state("s_p16_hongbao")
		Game.clock = 8.0 * 60.0
		main.world.enter_layer("surface")
		main.world.teleport(_nearest_free(Atlas.to_world("mountain", Vector2i(82, 34))), "surface")
		main.world._snap_cam()
		await _wait(2.0)
		var lw := Atlas.world_of("surface")
		var kid := {}
		for fp in Folk.people(lw, "cloudfoot"):
			var st := Folk.state(lw, fp, Game.clock)
			if fp.kid and st.vis and not st.walk and kid.is_empty():
				kid = {"p": fp, "tile": Vector2i(int(floor(st.at.x)), int(floor(st.at.y)))}
		if not kid.is_empty():
			var kt: Vector2i = kid.tile
			var spot := _nearest_free(kt + Vector2i(0, 1))
			main.world.teleport(spot, "surface")
			main.world.facing = Vector2i(signi(kt.x - spot.x), signi(kt.y - spot.y)) if (kt - spot).length() > 0 else Vector2i(0, -1)
			main.world.cam_q = _quarter(Vector2(main.world.facing))
			main.world._snap_cam()
			await _wait(1.5)
			await _shot("part16_new_year_children")
			main.talk_folk({"kind": "folk", "id": kid.p.id, "n": kid.p.n, "p": kid.p})
			main.dialogue.shown = 999.0
			main.press("confirm")
			await _wait(0.3)
			main.dialogue.shown = 999.0
			await _wait(0.8)
			await _shot("part16_hongbao")
			await _skip_talk()
	# the first dawn of the year: the bell
	if want.call(["part16_dawn_bell"]):
		_part16_state("s_p16_dawn")
		Game.clock = 6.3 * 60.0
		var bspot := Bonds.find_spot(Atlas.world_of("surface").ents, "kind:sect:bell")
		if not bspot.is_empty():
			_stand_by(bspot)
			await _wait(0.6)
			main.share_scene(bspot, "s_p16_dawn")
			for k3 in 2:
				main.dialogue.shown = 999.0
				main.press("confirm")
				await _wait(0.3)
			main.world.using.t0 = main.world.t - main.world.USE_STEP - 1.0
			main.dialogue.shown = 999.0
			await _wait(1.0)
			await _shot("part16_dawn_bell")
			await _skip_talk()
			main.choice.press("confirm")
			await _wait(0.3)
			await _skip_talk()

## The Living Land release (--living, or --living=a,b to pick shots): the hours of the day and the
## people of the towns.  [shot, region, a tile of its own map, hour, eye offset, look-at offset]
const LIVING := [
	["living_qingshi_morning", "village", Vector2i(30, 28), 8.6, Vector3(-13.0, 8.0, 15.0), Vector3(3.0, 0.0, -3.0)],
	["living_qingshi_dusk", "village", Vector2i(30, 28), 18.4, Vector3(-13.0, 8.0, 15.0), Vector3(3.0, 0.0, -3.0)],
	["living_yanggu_market", "yanggu", Vector2i(34, 30), 10.4, Vector3(-12.0, 9.0, 14.0), Vector3(2.0, 0.0, -2.0)],
	["living_yanggu_night", "yanggu", Vector2i(34, 30), 21.2, Vector3(-11.0, 7.0, 12.0), Vector3(2.0, 0.0, -2.0)],
	["living_sect_dawn", "sect", Vector2i(20, 12), 5.6, Vector3(-12.0, 8.0, 13.0), Vector3(2.0, 0.0, -3.0)],
	["living_sect_practice", "sect", Vector2i(20, 12), 7.6, Vector3(-12.0, 8.0, 13.0), Vector3(2.0, 0.0, -3.0)],
	["living_longmen_fishers", "longmen", Vector2i(28, 30), 6.2, Vector3(-14.0, 9.0, 15.0), Vector3(2.0, 0.0, -2.0)],
	["living_youdu_night", "youdu", Vector2i(38, 30), 22.5, Vector3(-12.0, 8.0, 14.0), Vector3(2.0, 0.0, -2.0)],
]

func _living_shots(which: String) -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	Game.reset()
	Game.level = 45
	Game.step = Data.step_index("s_p15_home")
	Game.companion = true
	Game.heal_full()
	# (everything she had to say said, so the corner is clear for the picture)
	for tk in Bonds.TALKS:
		Game.talks[str(tk.id)] = str(tk.options[0].id)
	main.world.clear_cache()
	main.set_stack(["world"])
	main.world.open_world()
	for sh in LIVING:
		if not only.is_empty() and not only.has(str(sh[0])):
			continue
		var lid := Data.layer_of(str(sh[1]))
		main.world.enter_layer(lid)
		Game.clock = float(sh[3]) * 60.0
		main.world.teleport(_nearest_free(Atlas.to_world(str(sh[1]), sh[2])), lid)
		main.world.facing = Vector2i(1, 0)
		main.world.cam_q = 1
		main.world._snap_cam()
		main.world.banner_t = 0.0
		# a moment for the people to come out (two are made a frame)
		Game.clock = float(sh[3]) * 60.0
		await _wait(1.5)
		_frame_crowd(sh[4])
		await _wait(0.5)
		await _shot(str(sh[0]))
		main.world.cam_override = null
	if only.is_empty() or only.has("living_strike"):
		await _strike_shots()
	if only.is_empty() or only.has("living_hours"):
		await _hours_sheet()

## The square of Qingshi from one place at dawn, noon, dusk and night, side by side.
func _hours_sheet() -> void:
	main.world.enter_layer("surface")
	main.world.teleport(_nearest_free(Atlas.to_world("village", Vector2i(30, 28))), "surface")
	main.world.facing = Vector2i(1, 0)
	main.world.cam_q = 1
	main.world._snap_cam()
	# one camera for all four hours: framed on the square's people at mid-morning, and kept
	Game.clock = 8.6 * 60.0
	await _wait(1.6)
	_frame_crowd(Vector3(-13.0, 8.0, 15.0))
	var view = main.world.cam_override
	var frames: Array = []
	for h in [6.0, 12.5, 18.7, 22.5]:
		Game.clock = h * 60.0
		main.world.cam_override = view
		# (no banner or toast left over from the shots before)
		main.world.banner_t = 0.0
		Game.toasts.clear()
		main.toast_list.clear()
		await _wait(0.8)
		await _shot("living_hour_%02d" % int(h), false)
		frames.append(last_img.duplicate())
	main.world.cam_override = null
	_sheet("living_hours", frames, 0.5)

## Point the camera at the busiest knot of townsfolk in sight (the one with the most others within
## eight metres), from offset `eye`, or past the hero if nobody is about.
func _frame_crowd(eye: Vector3) -> void:
	var pp: Vector3 = main.world._player_pos()
	var best := pp
	var bn := -1
	for id in main.world.folk_nodes:
		var a: Node3D = main.world.folk_nodes[id]
		if not a.visible or a.position.distance_to(pp) > 40.0:
			continue
		var n := 0
		for id2 in main.world.folk_nodes:
			var b: Node3D = main.world.folk_nodes[id2]
			if b.visible and b.position.distance_to(a.position) < 8.0:
				n += 1
		if n > bn:
			bn = n
			best = a.position
	# round the knot of people, the first eye whose view of them no house or tree is in the way of
	var look := best + Vector3(0, 0.9, 0)
	var e := best + eye * 0.85
	var dist := Vector2(eye.x, eye.z).length() * 0.85
	for k in 12:
		var a := atan2(eye.z, eye.x) + k * TAU / 12.0
		var c := best + Vector3(cos(a) * dist, eye.y * 0.85, sin(a) * dist)
		c.y = maxf(c.y, main.world.ground_y(c) + 3.0)
		if _clear_view(c, look):
			e = c
			break
	main.world.cam_override = Transform3D(Basis.IDENTITY, e).looking_at(look, Vector3.UP)

## Whether nothing built or grown stands between `a` and `b`: no wall, roof or forest tile under the
## line where it runs low enough to hit it.
func _clear_view(a: Vector3, b: Vector3) -> bool:
	var w = main.world
	for i in range(1, 14):
		var p := a.lerp(b, float(i) / 14.0)
		var tile := Vector2i(int(floor((p.x - w.off.x) / Terrain3D.T)), int(floor((p.z - w.off.z) / Terrain3D.T)))
		if tile.x < 0 or tile.y < 0 or tile.x >= w.w or tile.y >= w.h:
			continue
		var g: int = w.grid[tile.y * w.w + tile.x]
		var above: float = p.y - w.ground_y(p)
		if (g == MapGen.BUILDING or g == MapGen.INTERIOR) and above < 7.5:
			return false
		if g == MapGen.WALL and above < 9.0:
			return false
	return true

## F at a jar by a house in Yanggu: the sword swings, the jar comes apart, its pieces fly and fall.
func _strike_shots() -> void:
	Game.clock = 11.0 * 60.0
	var lw := Atlas.world_of("surface")
	main.world.enter_layer("surface")
	# a jar (or else a stack of pots, a barrel, a crate) with open street in front of it to stand on
	var b := {}
	var spot := Vector2i(-1, -1)
	for want in ["jar", "pots", "barrel", "crate"]:
		for c in Havoc.of_area(lw, "yanggu"):
			if not b.is_empty() or str(c.kind) != want:
				continue
			for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				var s: Vector2i = c.tile + d
				if b.is_empty() and main.world.tile_free(s) and main.world.tile_free(s + d) and Havoc.at_tile(lw, s).is_empty():
					b = c
					spot = s
	if b.is_empty():
		return
	main.world.teleport(spot, "surface")
	main.world.facing = b.tile - spot
	main.world.cam_q = _quarter(Vector2(main.world.facing))
	main.world._snap_cam()
	await _wait(1.0)
	var pp: Vector3 = main.world._player_pos()
	var fwd := Vector3(main.world.facing.x, 0, main.world.facing.y)
	var side := fwd.cross(Vector3.UP)
	var look := pp + fwd * 1.5 + Vector3(0, 0.7, 0)
	# from one side (the pieces fly out past him), or else over his shoulder from the street: the first
	# eye with no tree, wall or house beside it or in the way
	var eye := pp - fwd * 0.6 + side * 3.6 + Vector3(0, 2.0, 0)
	for c2 in [[-0.6, 3.6], [-0.6, -3.6], [-2.0, 3.0], [-2.0, -3.0], [-3.2, 1.8], [-3.2, -1.8]]:
		var e: Vector3 = pp + fwd * float(c2[0]) + side * float(c2[1]) + Vector3(0, 2.0, 0)
		if _open_round(e) and _clear_view(e, look):
			eye = e
			break
	main.world.cam_override = Transform3D(Basis.IDENTITY, eye).looking_at(look, Vector3.UP)
	main.world.strike()
	await _wait(0.42)
	await _shot("living_strike")
	await _wait(0.9)
	await _shot("living_strike_after")
	main.world.cam_override = null

## Whether the ground round world point `p` (its tile and the eight about it) is open: no tree,
## wall, house or water for a camera to be inside.
func _open_round(p: Vector3) -> bool:
	var w = main.world
	var tile := Vector2i(int(floor((p.x - w.off.x) / Terrain3D.T)), int(floor((p.z - w.off.z) / Terrain3D.T)))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q := tile + Vector2i(dx, dy)
			if not w.tile_free(q) or w.grid[q.y * w.w + q.x] == MapGen.INTERIOR:
				return false
	return true

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

## Part XII: the people of Landfall and the isles, the new townsfolk of every town, and the bosses of
## the Returning Ruins (--gallery12).
func _part12_galleries() -> void:
	await _gallery("gallery_landfall", [
		Assets.person("xu_qian"), Assets.person("teacher_qin"), Assets.person("shipwright_ban"), Assets.person("ah_shui"),
		Assets.person("little_haibao"), Assets.person("pilot_zheng"), Assets.person("diver_yulan"), Assets.person("mazu"),
	], 0.72)
	await _gallery("gallery_immortals", [
		Assets.person("lu_dongbin"), Assets.person("li_tieguai"), Assets.person("lan_caihe"), Assets.person("han_xiangzi"),
		Assets.person("he_xiangu"), Assets.person("zhang_guolao"), Assets.person("zhongli_quan"), Assets.person("cao_guojiu"),
	], 0.72)
	await _gallery("gallery_isles", [
		Assets.person("jingwei"), Assets.person("gui_lao"), Assets.person("mist_fisher"), Assets.person("furnace_boy"),
		Assets.person("steersman_hong"), Assets.person("ship_boy_ah_fu"), Assets.person("xu_fu_home"),
	], 0.76)
	await _gallery("gallery_townsfolk_new", [
		Assets.person("xiao_qing"), Assets.person("gardener_ruan"), Assets.person("clerk_wei"), Assets.person("noodle_he"),
		Assets.person("courier_ma"), Assets.person("ox_herd_niu"), Assets.person("teacher_ren"), Assets.person("lantern_xi"),
		Assets.person("archer_kong"), Assets.person("farida"), Assets.person("navid"),
	], 0.62)
	await _gallery("gallery_townsfolk_new2", [
		Assets.person("examiner_fan"), Assets.person("xia_cormorant"), Assets.person("bell_tuner_gong"), Assets.person("auntie_rong"),
		Assets.person("ling_fei"), Assets.person("ao_xun"), Assets.person("hu_xiao"), Assets.person("yao_silk"),
		Assets.person("bu_lin"), Assets.person("roll_clerk_ning"), Assets.person("lamplighter_bo"),
	], 0.62)
	await _gallery("gallery_part12", [
		_foe("longbo_giant", true), _foe("tianwu", true), _foe("shen", true), _foe("great_ao", true),
		_foe("yu_qiang", true), _foe("hai_ruo", true), _foe("xu_fu", true),
	], 1.4)
	await _gallery("gallery_part12_monsters", [
		_foe("stranded_shark"), _foe("sand_crab"), _foe("cinnabar_toad"), _foe("elixir_crane"), _foe("bore_horse"),
		_foe("shell_soldier"), _foe("drowned_sailor"), _foe("abyss_eel"), _foe("ruin_sentinel"),
	], 0.9)

## Part XII screens (--part12): the Cultivation page and a branch of the root waking, a cutscene with
## its gestures and two-shot camera, one of the Founder's sealed caves and the map of the Eastern Sea.
func _part12_shots() -> void:
	Game.reset()
	Game.level = 33
	Game.companion = true
	Game.heal_full()
	Game.step = Data.step_index("s_p8_home")
	Game.talents = {"sword_bone": 3, "thunder_root": 3, "vajra": 2, "qi_sea": 1, "five_phase": 1, "fortune": 1}
	Game.awakenings = 12
	Game.abodes = {"cave_core": true, "cave_soul": true, "cave_deity": true, "cave_void": true, "cave_merging": true, "cave_mahayana": true, "cave_immortal": true}
	Game.scattered = 41
	main.set_stack(["world"])
	main.world.clear_cache()
	main.world.load_area("sect", Vector2i(20, 9))
	main.open_menu()
	main.menu.mode = "cultivation"
	main.menu._build()
	await _wait(0.5)
	await _shot("cultivation")
	main.pop()
	Game.talent_pts = 1
	main.open_talent_choice()
	main.choice.cursor = 4
	await _wait(0.5)
	await _shot("talent_choice")
	main.pop()
	Game.talent_pts = 0
	# a Founder's cave on the mountain, sealed for a realm Lin Feng has not reached (its door faces the
	# sect, to the north-east)
	main.world.load_area("mountain", Vector2i(113, 72))
	main.world.facing = Vector2i(1, 0)
	main.world.cam_q = 1
	main.world._snap_cam()
	var cave_t: Vector2i = Atlas.to_world("mountain", Vector2i(116, 72))
	var cp: Vector3 = main.world.wpos(cave_t)
	cp.y = main.world.ground_y(cp)
	var to_sect: Vector2i = Atlas.to_world("sect", Vector2i(20, 13)) - cave_t
	var dir := Vector3(to_sect.x, 0, to_sect.y).normalized()
	main.world.cam_override = Transform3D(Basis.IDENTITY, cp + dir * 9.0 + Vector3(dir.z, 0, -dir.x) * 3.0 + Vector3(0, 5.5, 0)).looking_at(cp + Vector3(0, 1.2, 0), Vector3.UP)
	await _wait(1.2)
	await _shot("founder_cave")
	main.world.cam_override = null
	if main.args.has("cave-only"):
		return
	# a cutscene: Mazu gives Yue Ling her lantern at the pool of the suns (gestures and the two-shot)
	Game.step = Data.step_index("s_p12_shore")
	main.world.load_area("fusang", Vector2i(69, 49))
	main.world.facing = Vector2i(0, -1)
	main.world.cam_q = 0
	main.world._snap_cam()
	await _wait(1.0)
	main.say(Data.DIALOGUE.s_p12_shore)
	await _wait(2.6)
	await _shot("cutscene_mazu")
	main.dialogue.press("confirm")
	main.dialogue.press("confirm")
	await _wait(2.4)
	await _shot("cutscene_mazu2")
	while main.top_name() == "dialogue":
		main.dialogue.press("confirm")
		main.dialogue.press("confirm")
	# the map of the Eastern Sea
	for rid3 in Atlas.all_region_ids():
		Game.seen[rid3] = true
	main.world.load_area("penglai", Vector2i(40, 30))
	main.open_menu()
	main.menu.mode = "map"
	main.menu.map_layer = "sea"
	main.menu._build()
	await _wait(0.5)
	await _shot("world_map_sea")
	main.pop()

## Many roads and Part XIII (--part13): a trial's paths on the choice screen, the alchemist's
## crafting, the Journal, a townsperson's request, two Gate Generals in their regions, the Journal
## during the Eight Gates, a trial battle with allies striking, Chiyou, and the ending.
func _part13_shots() -> void:
	Game.reset()
	Game.level = 11
	Game.exp = float(Game.exp_need())
	Game.companion = true
	Game.temper = 3
	Game.stones = 2650
	Game.renown = 38
	Game.deeds = {"deed_cook": true, "deed_gate": true}
	Game.trials = {"iron_fang": "craft", "thunder_roc": "craft"}
	Game.inv = {"hp_pill": 6, "qi_pill": 3, "ess_wood": 4, "ess_fire": 1, "ess_water": 7, "ess_earth": 2, "ess_thunder": 5, "ess_dark": 9, "ess_metal": 3, "shard": 4, "herb": 3, "jade": 2, "feather": 1}
	Game.heal_full()
	Game.step = Data.step_index("s_lord")
	main.set_stack(["world"])
	main.world.clear_cache()
	main.world.load_area("sect", Vector2i(20, 9))
	main.world.banner_t = 0.0
	# the Demon Lord's trial: four ways, one of them open
	main.open_trial({"enemy": "demon_lord", "lv": 12, "req": 11, "id": "boss_demon_lord", "pos": Vector2i.ZERO})
	main.choice.cursor = 2
	await _wait(0.6)
	await _shot("trial_choice")
	main.pop()
	# Alchemist Mo's cauldron: one more Thunder Essence and the talisman can be made
	main.shop.open("alchemist")
	main.push("shop")
	main.shop.cursor = main.shop.ids.find("craft:thunder_seal")
	await _wait(0.5)
	await _shot("crafting")
	main.pop()
	# the Journal: renown, essences, requests, the trial ahead
	main.open_menu()
	main.menu.mode = "journal"
	main.menu._build()
	await _wait(0.5)
	await _shot("journal")
	main.pop()
	# a request: Old Shen's cracked bell
	main.offer_deed({"id": "bell_shen", "n": "Old Shen the Bell-Ringer"}, "deed_bell")
	await _wait(0.5)
	await _shot("deed_request")
	main.pop()
	# Part XIII: two of the Eight Gates, standing in their regions in gold light
	Game.level = 52
	Game.exp = 0.0
	Game.temper = 8
	Game.stones = 420000
	Game.renown = 470
	Game.dao = "heart"
	Game.dao_xp = {"sword": 44, "heart": 41}
	for rc in Data.RACE_ORDER:
		if rc != "human":
			Game.standing[rc] = 64
			Game.met[rc] = true
	Game.standing["xian"] = 100
	Game.step = Data.step_index("s_p13_gates")
	Game.gates_open = {"liang": true, "red_banner": true}
	Game.heal_full()
	Game.deeds = {}
	for did in Trials.DEEDS.keys().slice(0, 11):
		Game.deeds[did] = true
	Game.trials = {}
	for tid in BOT.TRIAL_PLAN:
		if not Trials.is_gate(tid):
			Game.trials[tid] = BOT.TRIAL_PLAN[tid]
	# the two gates standing open, and how they were passed
	Game.trials["liang"] = "dao"
	Game.trials["red_banner"] = "craft"
	Game.inv = {"hp_pill": 8, "qi_pill": 4, "ess_wood": 23, "ess_fire": 31, "ess_water": 40, "ess_earth": 27, "ess_thunder": 18, "ess_dark": 35, "ess_metal": 12, "autumn_leaf": 1, "spring_water": 4, "noon_ember": 4, "jingwei_stone": 4, "wind_bell": 4, "shift_horn": 1}
	for gs in [["gate_kui_drum", "kui_drum", Vector3(-12.0, 7.0, 13.0)], ["gate_fetter_maple", "fetter_maple", Vector3(-9.0, 13.0, 15.0)]]:
		var ga := Trials.boss_area(str(gs[1]))
		var gpos: Vector2i = Vector2i.ZERO
		for b in Data.AREAS[ga].bosses:
			if b.id == gs[1]:
				gpos = b.pos
		var lid := Data.layer_of(ga)
		main.world.open_world()
		main.world.enter_layer(lid)
		main.world.teleport(_nearest_free(Atlas.to_world(ga, gpos + Vector2i(-5, 3))), lid)
		main.world.facing = Vector2i(1, 0)
		main.world.cam_q = 1
		main.world._snap_cam()
		var bp: Vector3 = main.world.wpos(Atlas.to_world(ga, gpos))
		bp.y = main.world.ground_y(bp)
		main.world.cam_override = Transform3D(Basis.IDENTITY, bp + gs[2]).looking_at(bp + Vector3(0, 3.0, 0), Vector3.UP)
		await _wait(1.4)
		await _shot(str(gs[0]))
		main.world.cam_override = null
	main.world.enter_layer("surface")
	main.world.teleport(Atlas.to_world("sect", Vector2i(20, 9)), "surface")
	main.open_menu()
	main.menu.mode = "journal"
	main.menu._build()
	await _wait(0.5)
	await _shot("journal_gates")
	main.pop()
	# a Gate General's trial battle, by the friendship of the foxes: allies strike every round (the first strike at once)
	main.battle.start([{"id": "xingtian", "lv": 52, "mult": 1.3, "atk": 1.1}], {"entity": {"id": "boss_xingtian"}, "boss": true, "enemy": "xingtian", "theme": "changhe",
		"trial": "xingtian", "path": "peoples", "boon": Trials.path("xingtian", "peoples").boon, "path_n": "Kin of the celestial foxes", "path_kind": "By friendship"})
	main.push("battle")
	await _wait(3.1)
	await _shot("battle_boss_xingtian")
	main.pop()
	# Chiyou at the heart, on the Road of the Many Peoples
	Game.step = Data.step_index("s_p13_chiyou")
	Game.level = 53
	main.battle.start([{"id": "chiyou", "lv": 53, "mult": 2.0, "atk": 1.25}], {"entity": {"id": "boss_chiyou"}, "boss": true, "enemy": "chiyou", "theme": "maple",
		"trial": "chiyou", "path": "peoples", "boon": Trials.path("chiyou", "peoples").boon, "path_n": "The Road of the Many Peoples", "path_kind": "By friendship"})
	main.push("battle")
	await _wait(2.9)
	await _shot("battle_boss_chiyou")
	main.pop()
	# the ending: a frame of every shot of its film, and the results
	_ending_state()
	await _ending_shots()

## Things to do (--props, props.gd): for each kind of thing (or those named, --props=bench,well), the
## first one of it in the land, Lin Feng beside it with Yue Ling, Enter, and a frame from the side while
## he does it (prop_<kind>.webp), and all of them on sheets (props_sheet_<n>.webp).
const PROP_SHOTS := ["bench", "well", "shrine", "bell", "qin", "fishing", "swing", "wish_tree", "campfire", "stones", "broom", "koi",
	"altar", "bookshelf", "bed", "cauldron", "anvil", "loom", "tea", "drum", "herb_patch", "stele", "cushion", "stove", "barrel", "rack"]

func _props_shots() -> void:
	Game.reset()
	Game.level = 30
	Game.companion = true
	Game.heal_full()
	Game.hp[0] = Game.max_hp(0) * 0.6
	Game.step = Data.step_index("s_p11_home")
	main.set_stack(["world"])
	main.world.clear_cache()
	main.world.open_world()
	var want: Array = PROP_SHOTS
	if Props.KINDS.has(str(main.args.props).split(",", false)[0] if str(main.args.props) != "" else ""):
		want = str(main.args.props).split(",", false)
	var frames: Array = []
	for kind in want:
		var found = null
		var lid_f := ""
		for lid in ["surface", "heaven", "under", "sea"]:
			var lw := Atlas.world_of(lid)
			for e in lw.ents:
				if e.kind == "prop" and str(e.prop) == kind and _prop_spot(lw, e) != Vector2i(-1, -1):
					found = e
					lid_f = lid
					break
			if found != null:
				break
			# furniture upstairs and in cellars
			for fid in lw.floors:
				for fe in lw.floors[fid].ents:
					if fe.kind == "prop" and str(fe.prop) == kind and _prop_spot(lw.floors[fid], fe) != Vector2i(-1, -1):
						found = fe
						lid_f = fid
						break
				if found != null:
					break
			if found != null:
				break
		if found == null:
			print("[tour] no ", kind)
			continue
		var e2: Dictionary = found
		print("[tour] %s at %s in %s" % [kind, str(e2.pos), lid_f])
		var lw2 := Atlas.world_of(lid_f)
		var spot := _prop_spot(lw2, e2)
		main.world.enter_layer(lid_f)
		main.world.teleport(spot, lid_f)
		main.world.facing = e2.pos - spot
		main.world.cam_q = maxi(0, main.world.FWD.find(main.world.facing))
		main.world._snap_cam()
		main.world.banner_t = 0.0
		Game.toasts.clear()
		main.toast_list.clear()
		await _wait(0.2)
		print("[tour] using ", kind)
		main.world.start_use(e2)
		var k := Props.kind_of(e2)
		var once: bool = Props.ONCE.has(str(k.clip))
		var into := minf(float(k.dur) * 0.55, 2.4) if not once else float(main.world.FX_AT.get(str(k.clip), 0.6)) + 0.1
		# (rendering the world is slow here: jump straight to him at it, and a one-shot to its moment)
		main.world.using.t0 = main.world.t - main.world.USE_STEP - maxf(0.0, into - 0.25)
		await _wait(0.07)
		if once:
			main.world.player.set_meta("act_t", main.world.t - into + 0.1)
		# and Yue Ling's answer to it, when it is a gesture (she laughs a second after), well begun
		var cc := str(k.get("comp", "watch"))
		if Game.companion and cc != "watch" and not main.world.COMP_LOOP.has(cc):
			main.world.comp.set_meta("act_t", main.world.t - 0.7)
		# a camera off to the side, looking across the hero at the thing
		var hp: Vector3 = main.world.player.position
		var c: Vector3 = main.world.ent_pos(e2)
		var dir := Vector3(c.x - hp.x, 0, c.z - hp.z)
		if dir.length() < 0.3:
			# (on it, a cushion: the way he came onto it)
			dir = Vector3(main.world.using.dir.x, 0, main.world.using.dir.z)
		dir = dir.normalized()
		var side := Vector3(dir.z, 0, -dir.x)
		var mid := hp.lerp(Vector3(c.x, hp.y, c.z), 0.45) + Vector3(0, 0.9, 0)
		var eye := _prop_eye(lw2, mid, dir, e2.has("furn"))
		main.world.cam_override = Transform3D(Basis.IDENTITY, eye).looking_at(mid, Vector3.UP)
		await _wait(0.2)
		await _shot("prop_" + kind)
		frames.append(last_img.duplicate())
		# done: on to the next
		main.world.using.t0 = main.world.t - 100.0
		await _wait(0.07)
		main.world.cam_override = null
	for sh in range(0, frames.size(), 6):
		_grid("props_sheet_%d" % (sh / 6), frames.slice(sh, sh + 6), 2)

## Where to put the side camera on a thing (looking at `mid`, the thing along `dir` from the hero): off to
## one side and a little back, over open ground (not inside the trees beside it) and above the ground
## there; indoors, low in the room itself (over its floorboards, under the eaves). The first place with
## a clear view, else the clearest.
func _prop_eye(lw: Dictionary, mid: Vector3, dir: Vector3, furn: bool) -> Vector3:
	var wo = main.world
	var g: PackedByteArray = lw.grid
	var W: int = lw.w
	var H: int = lw.h
	var side := Vector3(dir.z, 0, -dir.x)
	# [to the side, back, up]
	var tries: Array = [[2.2, 1.0, 1.2], [1.4, 1.8, 1.3], [2.4, 0.2, 1.3], [0.5, 2.2, 1.4], [1.2, 0.9, 1.5]] if furn else \
		[[4.2, 2.2, 1.4], [3.2, 3.2, 1.6], [1.8, 4.0, 1.9], [2.8, 1.2, 2.8], [1.0, 2.6, 3.4]]
	var best := Vector3.ZERO
	var best_n := -1
	for t in tries:
		for s in [1.0, -1.0]:
			var eye: Vector3 = mid + side * (float(t[0]) * s) - dir * float(t[1]) + Vector3(0, float(t[2]), 0)
			var n := 0
			for i in 8:
				var p: Vector3 = eye.lerp(mid, i / 10.0)
				var tx := floori((p.x - wo.off.x) / Terrain3D.T)
				var ty := floori((p.z - wo.off.z) / Terrain3D.T)
				if tx >= 0 and ty >= 0 and tx < W and ty < H:
					var tile: int = g[ty * W + tx]
					if (tile == MapGen.INTERIOR) if furn else (MapGen.is_walkable_tile(tile) or tile == MapGen.WATER):
						n += 1
			if n > best_n:
				best_n = n
				best = eye
			if n == 8:
				break
		if best_n == 8:
			break
	best.y = maxf(best.y, wo.ground_y(best) + 1.2)
	return best

## A free tile beside thing `e` in world `lw` to use it from (-1,-1 if none).
func _prop_spot(lw: Dictionary, e: Dictionary) -> Vector2i:
	var g: PackedByteArray = lw.grid
	var W: int = lw.w
	var fd: Vector2i = e.get("face", Vector2i.ZERO)
	var dirs: Array = ([fd] if fd != Vector2i.ZERO else []) + MapGen.DIRS
	for d in dirs:
		var n: Vector2i = e.pos + d
		if n.x < 0 or n.y < 0 or n.x >= W or n.y >= int(lw.h):
			continue
		if MapGen.is_walkable_tile(g[n.y * W + n.x]):
			var busy := false
			for o in lw.ents:
				if o.pos == n and o.kind != "prop":
					busy = true
					break
			if not busy:
				return n
	return Vector2i(-1, -1)

## The state the bot's run (seed 1234) reaches the ending in: every trial passed the way its plan
## takes it, the heart by the Road of the Many Peoples, and the run's numbers (the clock stopped).
## Fates and Faces (--fates): character creation, the hero's looks and outfits, the rides, the people
## met on the road, the wardrobe, the Fates page, a chapter and its choice, a fated battle, the bestiary
## and Nie at the heart of the Wheel.
func _fates_state(step_id: String, lv: int) -> void:
	Game.reset()
	Game.level = lv
	Game.exp = float(Game.exp_need()) * 0.4
	Game.companion = true
	Game.stones = 52000
	Game.renown = 220
	Game.step = Data.step_index(step_id)
	# every boss the story has put down by then is gone from the world, and the gates the bot opened
	# stand open (else Iron Fang would stand beside his own grudge)
	for i in Game.step:
		if str(Data.STEPS[i].kind) == "kill":
			Game.boss_done[str(Data.STEPS[i].boss)] = true
	if Game.step > Data.step_index(Trials.GATE_STEP):
		for gid in BOT.GATE_PLAN:
			Game.boss_done[gid] = true
			Game.gates_open[gid] = true
	Game.outfits = {"sweeper": true, "inner": true, "hunter": true, "dragon": true, "phoenix": true, "celestial": true, "immortal": true}
	Game.rides = {"pony": true, "sword": true, "qilin": true, "cloud": true}
	Game.ride = "pony"
	# the first two meetings of every thread, answered as the bot answers them (bot.gd FATE_PLAN), so that
	# the Fates page's words agree with where each person stands
	Game.fates = {}
	Game.fate_log = {}
	for th in Fate.THREAD_ORDER:
		var lg: Array = []
		for ch in Fate.PATH[th].slice(0, 2):
			var sid := str(ch[0])
			var v := Fate.variant(Game, sid)
			var o := {}
			for want in BOT.FATE_PLAN.get(sid, []):
				o = Fate.option(v, str(want))
				if not o.is_empty():
					break
			if o.is_empty():
				o = v.options[0]
			if o.has("follow"):
				var fo: Dictionary = o.follow.options[0]
				for want2 in BOT.FATE_PLAN.get(sid + ":follow", []):
					if not Fate.option(o.follow, str(want2)).is_empty():
						fo = Fate.option(o.follow, str(want2))
						break
				o = fo
			Game.fates[th] = str(o.then)
			lg.append(str(o.get("log", "")))
		Game.fate_log[th] = lg
	Game.heal_full()

func _fates_shots() -> void:
	if str(main.args.get("fates", "")) == "grudges":
		# (--fates=grudges: only Part XIV's grudges and Nie)
		main.set_stack(["world"])
		await _grudge_shots()
		return
	if str(main.args.get("fates", "")) == "chapter":
		# (--fates=chapter: a chapter and its choice, the battles, the grudges and Nie)
		main.set_stack(["world"])
		await _fates_chapter_shots()
		return
	if str(main.args.get("fates", "")) == "page":
		# (--fates=page: only the Fates page and the Bestiary)
		main.set_stack(["world"])
		_fates_state("s_f_qiu1", 3)
		main.world.clear_cache()
		main.world.load_area("sect", Vector2i(20, 12))
		await _fates_pages()
		return
	# character creation over the moonlit cliff, the story's sweeper and a sweeper of one's own
	main.set_stack(["title"])
	main.open_creation()
	await _wait(1.5)
	await _shot("create")
	main.create.h = {"family": "Bai", "given": "Chen", "look": "wild", "hair": 2, "eyes": 3, "robe": 1, "origin": "hunter"}
	main.create.cursor = 2
	main.create._preview()
	await _wait(1.5)
	await _shot("create_custom")
	# (the galleries draw over an empty world: nothing of the title screen's menu over them)
	main.set_stack(["world"])
	# the four looks in four colourings, and the outfits
	var looks: Array = []
	var cs := [{}, {"hair": Color("5a3424"), "eyes": Color("2eb07e"), "robe": Color("2e9a6e"), "sec": Color("163a2c"), "trim": Color("e8f4e0")},
		{"hair": Color("dfe6ee"), "eyes": Color("8a50d0"), "robe": Color("b8323a"), "sec": Color("3a1418"), "trim": Color("f0d8a0")},
		{"hair": Color("1e2c5c"), "eyes": Color("e0a030"), "robe": Color("6a48b0"), "sec": Color("241840"), "trim": Color("e8dcff")}]
	for k in Fashion.LOOK_ORDER.size():
		looks.append(Models.hero({"look": Fashion.LOOK_ORDER[k], "cols": cs[k], "outfit": "sweeper"}))
	await _gallery("hero_looks", looks, 0.8)
	var outs: Array = []
	for oid in ["inner", "dragon", "phoenix", "celestial", "ink", "starlit", "sea", "conclave"]:
		Game.outfit = oid
		outs.append(Models.hero({"outfit": oid, "cols": Fashion.hero_colors(Game)}))
	Game.outfit = "sweeper"
	await _gallery("outfits", outs, 0.62)
	# the five people met on the road, as they are first met and as they grow
	var folk: Array = []
	for pid in ["tala", "qiu_ye", "little_hu", "hu_grown", "xu_lan", "liu_ying"]:
		folk.append(Models.person(Color("888888"), Color("222222"), {"asset": pid}))
	await _gallery("fated_people", folk, 0.7)
	await _portraits("fated_portraits", [Models.person(Color.WHITE, Color.BLACK, {"asset": "tala"}), Models.person(Color.WHITE, Color.BLACK, {"asset": "qiu_ye"}),
		Models.person(Color.WHITE, Color.BLACK, {"asset": "hu_grown"})])
	await _portraits("fated_portraits2", [Models.person(Color.WHITE, Color.BLACK, {"asset": "xu_lan"}), Models.person(Color.WHITE, Color.BLACK, {"asset": "liu_ying"}),
		Models.person(Color.WHITE, Color.BLACK, {"asset": "little_hu"})], 0.95, 1.4)
	# the rides, each with Lin Feng and Yue Ling on board
	var rides: Array = []
	for rid in Fashion.RIDE_ORDER:
		var r: Dictionary = Fashion.RIDES[rid]
		var holder := Node3D.new()
		var rn := Models.ride(rid)
		holder.add_child(rn)
		var standing := str(r.kind) == "vehicle"
		var clip := "ride_stand" if standing else "ride_idle"
		var lift := 0.0 if standing else 0.9
		var rise := Models.anim_ride(rn, 0.3, false)
		var h1 := Models.hero({})
		h1.position = Vector3(r.seat) + rise - Vector3(0, lift, 0)
		holder.add_child(h1)
		var y1 := Models.person(Color("e86a9a"), Color("402030"), {"asset": "yue_ling"})
		y1.position = Vector3(r.pillion) + rise - Vector3(0, lift, 0)
		holder.add_child(y1)
		for pm in [h1, y1]:
			Assets.animate(pm, 0.0, clip, 0.0)
			Assets.animate(pm, 0.4, clip, 0.0)
		holder.rotation.y = PI / 2.0
		holder.set_meta("kind", "ride_group")
		rides.append(holder)
	await _gallery("rides", rides, 1.15, 1.1)
	# riding in the world: the horse on the road from the sect's north gate, and the flying sword
	_fates_state("s_f_qiu1", 3)
	main.set_stack(["world"])
	main.world.clear_cache()
	main.world.load_area("sect", Vector2i(20, 9))
	for rid2 in ["pony", "sword", "cloud"]:
		Game.ride = rid2
		Game.riding = true
		main.world.teleport(Atlas.to_world("mountain", Vector2i(82, 48)))
		main.world.facing = Vector2i(0, -1)
		main.world.move_dir = Vector2i(0, -1)
		await _wait(1.2)
		var pp: Vector3 = main.world.player.global_position
		main.world.cam_override = Transform3D(Basis.IDENTITY, pp + Vector3(6.5, 2.4, 1.0)).looking_at(pp + Vector3(0, 1.3, -0.6), Vector3.UP)
		await _wait(0.4)
		await _shot("riding_" + rid2)
		main.world.move_dir = Vector2i.ZERO
		main.world.cam_override = null
	Game.riding = false
	# the wardrobe: the cursor on the Heaven-Gate Armour, and the hero in it
	main.world.teleport(Atlas.to_world("sect", Vector2i(20, 12)))
	main.world.facing = Vector2i(0, 1)
	await _wait(0.6)
	main.open_wardrobe()
	main.choice.cursor = Fashion.OUTFIT_ORDER.find("celestial")
	main.choice._show()
	await _wait(0.8)
	await _shot("wardrobe")
	main.choice.press("cancel")
	await _fates_pages()
	# a chapter: Xu Lan in the inner sanctum, and the choice it ends in
	await _fates_chapter_shots()

## (the carriages' gallery: everybody aboard put in the seated pose once they are in the tree)
func _seat_all(holder: Node3D) -> void:
	for c in holder.get_children():
		if c.has_meta("pose_ap"):
			var pap: AnimationPlayer = c.get_meta("pose_ap")
			pap.play("sit_bench")
			pap.seek(1.0, true)
			pap.pause()

## The Fates page and the Bestiary.
func _fates_pages() -> void:
	Game.bestiary = {"bamboo_wolf": 12, "bandit": 9, "leaf_sprite": 7, "mire_toad": 5, "bog_wraith": 4, "thunder_ape": 3}
	Game.told = {"jade_mantis": true, "iron_fang": true, "marsh_hag": true}
	main.open_menu()
	main.menu.mode = "fates"
	main.menu._build()
	await _wait(0.4)
	await _shot("fates_page")
	main.menu.mode = "bestiary"
	main.menu._build()
	main.menu.cursor = 1
	await _wait(0.4)
	await _shot("bestiary")
	main.pop()

## A fated encounter's chapter, its choice and a fated battle; a species' story over a battle's opening;
## then Part XIV's grudges and Nie.
func _fates_chapter_shots() -> void:
	_fates_state("s_f_xu1", 12)
	Game.fates.erase("xu_lan")
	main.world.clear_cache()
	main.world.load_area("palace", Vector2i(48, 25))
	main.world.facing = Vector2i(0, -1)
	await _wait(1.0)
	main.play_chapter("s_f_xu1", {})
	await _wait(5.0)
	await _shot("fate_chapter")
	while main.top_name() == "dialogue":
		main.dialogue.idx = main.dialogue.lines.size() - 1
		main.dialogue.shown = 999.0
		main.press("confirm")
		await _wait(0.2)
	await _wait(0.4)
	await _shot("fate_choice")
	main.choice.press("cancel")
	# a fated battle: Qiu Ye of the Ashen Moon among the sword saints' barrows
	_fates_state("s_f_qiu2", 19)
	main.world.clear_cache()
	main.world.load_area("grave", Vector2i(10, 28))
	main.battle.start([{"id": "qiu_ye", "lv": 19}], {"boss": true, "fate": "s_f_qiu2", "fate_opt": {}, "theme": main.world.theme_name})
	main.push("battle")
	await _wait(3.0)
	await _shot("battle_fate_qiu_ye")
	main.pop()
	# a species met for the first time: its story over the opening
	Game.bestiary = {}
	main.battle.start([{"id": "thunder_ape", "lv": 10}, {"id": "storm_hawk", "lv": 9}], {"boss": false, "theme": "thunder"})
	main.push("battle")
	await _wait(2.2)
	await _shot("battle_lore")
	main.pop()
	await _grudge_shots()

## Part XIV: the grudges that stayed (grudges.gd), the choice once one is spent, and Nie.
func _grudge_shots() -> void:
	# Iron Fang's grudge in the bamboo and Kui's over the aeries of Juntian, each smouldering beside the
	# place its owner fell; a battle with Kui's
	_fates_state(Grudges.STEP, 55)
	Game.fates = {"tala": "ally", "qiu_ye": "ally", "hu": "ally", "xu_lan": "spared", "liu_ying": "fallen"}
	Game.grudges = {"grudge_headless_saint": "bow", "grudge_marsh_hag": "pay"}
	for gd in Game.grudges:
		Game.boss_done[gd] = true
	Game.rides["barque"] = true
	for gs2 in [["grudge_iron_fang", Vector3(-6.5, 3.6, 8.5)], ["grudge_kui", Vector3(-11.0, 5.5, 13.0)]]:
		var gid2: String = gs2[0]
		var ga2 := Trials.boss_area(gid2)
		var gpos2 := Vector2i.ZERO
		for b2 in Data.AREAS[ga2].bosses:
			if b2.id == gid2:
				gpos2 = b2.pos
		var lid2 := Data.layer_of(ga2)
		main.world.open_world()
		main.world.enter_layer(lid2)
		main.world.teleport(_nearest_free(Atlas.to_world(ga2, gpos2 + Vector2i(-4, 3))), lid2)
		main.world.facing = Vector2i(1, 0)
		main.world.cam_q = 1
		main.world._snap_cam()
		var bp2: Vector3 = main.world.wpos(Atlas.to_world(ga2, gpos2))
		bp2.y = main.world.ground_y(bp2)
		main.world.cam_override = Transform3D(Basis.IDENTITY, bp2 + gs2[1]).looking_at(bp2 + Vector3(0, 2.2, 0), Vector3.UP)
		# (the land round him was built on arrival; a few frames for the soot to rise. The bamboo is slow
		# to draw in software, a frame every few seconds)
		await _wait(0.6)
		await _shot(gid2)
		main.world.cam_override = null
	main.battle.start([{"id": "grudge_kui", "lv": 55}], {"boss": true, "enemy": "grudge_kui", "theme": main.world.theme_name})
	main.push("battle")
	await _wait(3.0)
	await _shot("battle_grudge_kui")
	main.pop()
	main.world.enter_layer("surface")
	main.world.teleport(Atlas.to_world("sect", Vector2i(20, 9)), "surface")
	# the journal keeps the six, where they stand and what became of them
	main.open_menu()
	main.menu.mode = "journal"
	main.menu._build()
	await _wait(0.5)
	await _shot("grudges_journal")
	main.pop()
	# a grudge spent: what was it owed?  (Fang Hu stands with Lin Feng, so his son can answer him)
	main.ask_grudge("grudge_iron_fang")
	await _wait(0.6)
	await _shot("grudge_choice")
	main.choice.press("confirm")
	await _wait(0.4)
	while main.top_name() == "dialogue":
		main.dialogue.idx = main.dialogue.lines.size() - 1
		main.dialogue.shown = 999.0
		main.press("confirm")
		await _wait(0.2)
	# Part XIV: Nie, the Unpaid, at the heart of the Wheel, the friends Lin Feng made striking with him
	_fates_state("s_p14_nie", 55)
	main.world.clear_cache()
	main.world.load_area("wheel", Vector2i(70, 30))
	var nb: Dictionary = Trials.path("nie", "bond").boon
	var nm: Array = Trials.TRIALS.nie.might
	main.battle.start([{"id": "nie", "lv": 56, "mult": float(nm[0]), "atk": float(nm[1])}], {"boss": true, "enemy": "nie", "theme": main.world.theme_name, "trial": "nie", "path": "bond", "boon": nb,
		"path_n": "By the bonds you made", "path_kind": str(Trials.KINDS.bond.n)})
	main.push("battle")
	await _wait(3.4)
	await _shot("battle_boss_nie")
	main.pop()

# ---------------------------------------------------------------- the Lotus release (--lotus)
## A game state in Part XV at step `step_id`: the friends the bot makes, how close Lin Feng and Yue Ling
## have come, the heart-to-hearts had (as the bot answers them) and her wishes granted so far.
func _lotus_state(step_id: String) -> void:
	_fates_state(step_id, 57)
	Game.fates = {"tala": "ally", "qiu_ye": "ally", "hu": "ally", "xu_lan": "redeemed", "liu_ying": "fallen"}
	Game.bond = 52
	Game.heart = {"companion": 24, "lotus": 10, "wander": 9}
	Game.talks = {}
	for tk in Bonds.TALKS:
		if Data.step_index(str(tk.after)) < Game.step:
			Game.talks[str(tk.id)] = str(BOT.TALK_PLAN.get(str(tk.id), tk.options[0].id))
	Game.wishes = {}
	for w in Bonds.WISHES.slice(0, 11):
		Game.wishes[str(w.id)] = true
	Game.heal_full()

## A thing to do (or anybody) of the land by its id, and a free tile beside it to stand on.
func _land_ent(id: String) -> Dictionary:
	for e in Atlas.world_of("surface").ents:
		if str(e.get("id", "")) == id:
			return e
	return {}

func _stand_by(e: Dictionary) -> void:
	var lw := Atlas.world_of("surface")
	var spot := _prop_spot(lw, e) if e.kind == "prop" else _nearest_free(e.pos + Vector2i(0, 2))
	main.world.open_world()
	main.world.enter_layer("surface")
	main.world.teleport(spot, "surface")
	main.world.facing = e.pos - spot if e.kind == "prop" else Vector2i(0, -1)
	main.world.cam_q = _quarter(Vector2(main.world.facing))
	main.world._snap_cam()
	main.world.banner_t = 0.0
	Game.toasts.clear()
	main.toast_list.clear()

## The camera's quarter that looks most nearly along `v` (a thing beside him can be on a diagonal, or
## two tiles off: FWD.find only knows the four straight steps).
func _quarter(v: Vector2) -> int:
	var best := 0
	var bd := -INF
	for i in main.world.FWD.size():
		var f: Vector2i = main.world.FWD[i]
		var d := f.x * v.x + f.y * v.y
		if d > bd:
			bd = d
			best = i
	return best

## Every line of the conversation on top shown at once and passed, up to the next choice.
func _skip_talk() -> void:
	var guard := 0
	while main.top_name() == "dialogue" and guard < 60:
		guard += 1
		main.dialogue.shown = 999.0
		main.press("confirm")
		await _wait(0.12)

## The Founder's hermitage and its bathhouse under the Last Cave, and the Warden waiting by them
## (also on their own: --hermitage).
func _hermitage_shots() -> void:
	_lotus_state("s_p15_warden")
	var hp := Atlas.to_world("mountain", Vector2i(62, 106))
	main.world.open_world()
	main.world.teleport(_nearest_free(hp), "surface")
	main.world.facing = Vector2i(1, 0)
	main.world.cam_q = 1
	main.world._snap_cam()
	await _wait(0.8)
	var hc: Vector3 = main.world.wpos(Atlas.to_world("mountain", Vector2i(70, 108)))
	hc.y = main.world.ground_y(hc)
	main.world.cam_override = Transform3D(Basis.IDENTITY, hc + Vector3(-14.0, 9.0, 13.0)).looking_at(hc + Vector3(2.0, 1.5, -2.0), Vector3.UP)
	await _wait(0.5)
	await _shot("hermitage")
	# the moon gate: the door in the middle of its west wall, seen from the path that comes up to it
	var dg: Vector3 = main.world.wpos(Atlas.to_world("mountain", Vector2i(68, 104)))
	dg.y = main.world.ground_y(dg)
	main.world.cam_override = Transform3D(Basis.IDENTITY, dg + Vector3(-8.0, 2.4, 2.0)).looking_at(dg + Vector3(1.0, 1.6, 0.0), Vector3.UP)
	await _wait(0.4)
	await _shot("hermitage_gate")
	main.world.cam_override = null

## The bigger things in use, Yue Ling's heart-to-hearts and her page, Part XV's memories, the
## Founder's echo and her hermitage, the lotus pond, and the new battles.
func _lotus_shots() -> void:
	# a memory given back: Wen Shu's lantern green on the Magpie Bridge, the two of them dancing under
	# the lanterns as she danced at his wedding
	_lotus_state("s_p15_memories")
	Game.memories = {"mem_spring": "nothing", "mem_lanterns": "two", "mem_flute": "forest"}
	var mf := _land_ent("mem:mem_dance")
	if not mf.is_empty():
		_stand_by(mf)
		await _wait(0.3)
		main._memory_won("mem_dance")
		for k in 3:
			main.dialogue.shown = 999.0
			main.press("confirm")
			await _wait(0.2)
		main.world.using.t0 = main.world.t - main.world.USE_STEP - 2.0
		await _wait(1.2)
		main.dialogue.shown = 999.0
		await _wait(0.4)
		await _shot("memory_dance")
		await _skip_talk()
		await _wait(0.5)
		await _shot("memory_choice")
		main.choice.press("confirm")
		await _wait(0.3)
		await _skip_talk()
	# the fight for a memory: the moths that eat forgetting
	main.battle.start([{"id": "forgetting_moth", "lv": 57}, {"id": "loose_thread", "lv": 57}, {"id": "unweaver_shuttle", "lv": 58}], {"boss": false, "theme": "magpie"})
	main.push("battle")
	await _wait(3.0)
	await _shot("battle_forgetting")
	main.pop()
	# a heart-to-heart in the courtyard: what she is, and whether he still wants her beside him
	_lotus_state("s_p15_memories")
	main.world.clear_cache()
	main.world.load_area("sect", Vector2i(20, 12))
	Game.talks.erase("t_seal")
	main.open_talk("t_seal")
	for k2 in 4:
		main.dialogue.shown = 999.0
		main.press("confirm")
		await _wait(0.25)
	main.dialogue.shown = 999.0
	await _wait(0.6)
	await _shot("talk_seal")
	await _skip_talk()
	await _wait(0.5)
	await _shot("talk_choice")
	main.choice.press("confirm")
	await _wait(0.3)
	await _skip_talk()
	# her page
	Game.memories = {"mem_spring": "nothing", "mem_lanterns": "two", "mem_flute": "forest", "mem_dance": "again"}
	main.open_menu()
	main.menu.mode = "yue"
	main.menu._build()
	await _wait(0.5)
	await _shot("yue_page")
	main.pop()
	# the Founder's echo by her barrow
	_lotus_state("s_p15_founder")
	var fe := _land_ent("qing_lian_echo")
	if not fe.is_empty():
		_stand_by(fe)
		await _wait(0.4)
		main.talk_npc(fe)
		for k3 in 2:
			main.dialogue.shown = 999.0
			main.press("confirm")
			await _wait(0.25)
		main.dialogue.shown = 999.0
		await _wait(1.0)
		await _shot("founder_echo")
		await _skip_talk()
	await _hermitage_shots()
	# the two trials
	var ub: Dictionary = Trials.path("unweaver", "heart").boon
	main.battle.start([{"id": "unweaver", "lv": 59, "mult": 2.0, "atk": 1.2}], {"boss": true, "enemy": "unweaver", "theme": "loom", "trial": "unweaver", "path": "heart", "boon": ub, "path_n": str(Trials.path("unweaver", "heart").n), "path_kind": str(Trials.KINDS.heart.n)})
	main.push("battle")
	await _wait(3.2)
	await _shot("battle_unweaver")
	main.pop()
	var wb: Dictionary = Trials.path("lock_warden", "craft").boon
	main.battle.start([{"id": "lock_warden", "lv": 59, "mult": 2.2, "atk": 1.25}], {"boss": true, "enemy": "lock_warden", "theme": "sect", "trial": "lock_warden", "path": "craft", "boon": wb, "path_n": "The Key of the Open Door", "path_kind": str(Trials.KINDS.craft.n)})
	main.push("battle")
	await _wait(3.2)
	await _shot("battle_lock_warden")
	main.pop()
	# the lotus pond at dawn: the first line of her life
	_lotus_state("s_p15_name")
	Game.memories = {"mem_spring": "nothing", "mem_lanterns": "two", "mem_flute": "forest", "mem_stars": "beside", "mem_kite": "cut"}
	var pe := _land_ent("mem:mem_pond")
	if not pe.is_empty():
		_stand_by(pe)
		await _wait(0.4)
		main.share_scene(pe, "s_p15_name")
		for k4 in 2:
			main.dialogue.shown = 999.0
			main.press("confirm")
			await _wait(0.25)
		main.world.using.t0 = main.world.t - main.world.USE_STEP - 1.4
		main.dialogue.shown = 999.0
		await _wait(1.0)
		await _shot("pond_scene")
		await _skip_talk()
		await _wait(0.5)
		await _shot("future_choice")
		main.choice.press("confirm")
		await _wait(0.3)
		await _skip_talk()
	await _kite_shot()

## A red kite high over the hills: Chun's kite post on the Cloud-Tea Terraces (failing that, the first
## kite post in the land), flown for a few seconds (also on its own: --kite).
func _kite_shot() -> void:
	_lotus_state("s_p15_memories")
	var kt := _land_ent("mem:mem_kite")
	if kt.is_empty() or _prop_spot(Atlas.world_of("surface"), kt) == Vector2i(-1, -1):
		kt = {}
		for e2 in Atlas.world_of("surface").ents:
			if e2.kind == "prop" and str(e2.prop) == "kite" and _prop_spot(Atlas.world_of("surface"), e2) != Vector2i(-1, -1):
				kt = e2
				break
	if kt.is_empty():
		return
	_stand_by(kt)
	await _wait(0.3)
	main.world.start_use(kt)
	# a few seconds into the flight: his clock and the kite's (it climbs by the time since he began)
	main.world.using.t0 = main.world.t - main.world.USE_STEP - 3.6
	var nd = main.world.ent_nodes.get(kt.id)
	if nd != null:
		(nd as Node3D).set_meta("used_t", main.world.t - 3.6)
	await _wait(0.4)
	var kp: Vector3 = main.world.player.position + Vector3(0, 5.0, 0)
	if nd != null and (nd as Node3D).has_meta("model"):
		var mm := (nd as Node3D).get_meta("model") as Node3D
		if mm.has_meta("mover"):
			kp = (mm.get_meta("mover") as Node3D).global_position
	var pp: Vector3 = main.world.player.position
	var away := Vector3(pp.x - kp.x, 0, pp.z - kp.z).normalized()
	main.world.cam_override = Transform3D(Basis.IDENTITY, pp + away * 4.5 + Vector3(0, 1.2, 0) + Vector3(away.z, 0, -away.x) * 1.5).looking_at(pp.lerp(kp, 0.55), Vector3.UP)
	await _wait(0.3)
	await _shot("kite_sky")
	main.world.cam_override = null
	main.world.using.t0 = main.world.t - 100.0
	await _wait(0.2)

func _ending_state() -> void:
	Game.level = Data.MAX_LEVEL
	Game.dao = "heart"
	# the five people met on the road and the six grudges that stayed, as the bot leaves them
	Game.fates = {"tala": "ally", "qiu_ye": "ally", "hu": "ally", "xu_lan": "redeemed", "liu_ying": "fallen"}
	Game.grudges = {}
	for gid in BOT.GRUDGE_PLAN:
		Game.grudges[gid] = str(BOT.GRUDGE_PLAN[gid][0]) if gid != "grudge_marsh_hag" else "pay"
	Game.trials = {"bifang": "bond", "chiyou": "peoples", "chong": "dao", "crow_marshal": "craft", "demon_lord": "respect", "fetter_maple": "relic", "founder_qing": "respect", "gonggong": "might", "gun": "craft", "heavenly_emperor": "wealth", "hollow_heaven": "craft", "horse_face": "craft", "hundun": "respect", "inferno_lord": "might", "iron_fang": "craft", "jade_ledger": "might", "king_yama": "bond", "kui_drum": "might", "li": "dao", "liang": "dao", "nie": "bond", "qianxian": "bond", "registrar_siming": "craft", "thread_matron": "respect", "thunder_roc": "craft", "tianwu": "wealth", "vermilion_bird": "wealth", "xihe": "craft", "xingtian": "wealth", "xiwangmu": "respect", "xu_fu": "dao"}
	Game.gates_open = {}
	for gid in ["fetter_maple", "kui_drum", "liang", "xingtian"]:
		Game.gates_open[gid] = true
	Game.renown = 716
	Game.deeds = {}
	for did in Trials.DEEDS.keys().slice(0, 5):
		Game.deeds[did] = true
	Game.playtime = 66222.1
	Game.finished = true
	Game.kills = 3223
	Game.battles = 1741
	Game.deaths = 0
	Game.meditated = 12057.0
	Game.talents = {"sword_bone": 3, "thunder_root": 3, "vajra": 3, "qi_sea": 3, "five_phase": 3, "fortune": 3, "yin_root": 3, "spirit_sense": 3, "insight": 3}
	# the Lotus release (bonds.gd): Part XV's two trials, and Yue Ling as the bot leaves her
	Game.trials["unweaver"] = "heart"
	Game.trials["lock_warden"] = "craft"
	Game.bond = 120
	Game.future = "companion"
	Game.heart = {"companion": 44, "lotus": 12, "wander": 9}
	Game.memories = {}
	for mid in BOT.MEMORY_ROUTE:
		Game.memories[mid] = str(BOT.MEMORY_PLAN.get(mid, ""))
	for tk in Bonds.TALKS:
		Game.talks[str(tk.id)] = str(BOT.TALK_PLAN.get(str(tk.id), ""))

## The ending: a frame from the middle of every shot of the film (ending_<shot>.webp, and all of them
## on one sheet, ending_film.webp) and the results once the film is over (ending.webp).
func _ending_shots() -> void:
	main.push("ending")
	await _wait(1.0)
	var e = main.ending
	var frames: Array = []
	var t0 := 0.0
	for s in e.FILM:
		e.t = t0 + float(s.dur) * 0.55
		await _wait(0.5)
		await _shot("ending_%s" % s.id)
		frames.append(last_img.duplicate())
		t0 += float(s.dur)
	# the six wonders on one sheet (the last shot, on the lotus, is the results without them)
	_grid("ending_film", frames.slice(0, 6), 2)
	# Enter in the middle of the film skips to the results, as a player would
	e.t = 4.0
	main.press("confirm")
	await _wait(3.5)
	await _shot("ending")
	main.pop()

## Frames laid out on a grid at half size, `cols` to a row.
func _grid(n: String, frames: Array, cols: int) -> void:
	if frames.is_empty():
		return
	var fw: int = frames[0].get_width() / 2
	var fh: int = frames[0].get_height() / 2
	var rows := int(ceil(frames.size() / float(cols)))
	var out := Image.create(fw * cols, fh * rows, false, Image.FORMAT_RGB8)
	for i in frames.size():
		var im: Image = frames[i]
		im.convert(Image.FORMAT_RGB8)
		im.resize(fw, fh, Image.INTERPOLATE_LANCZOS)
		out.blit_rect(im, Rect2i(0, 0, fw, fh), Vector2i((i % cols) * fw, (i / cols) * fh))
	out.save_webp("%s/%s.webp" % [dir, n], true, 0.9)
	print("[tour] ", n)

func _run() -> void:
	await _wait(1.0)
	if (main.args.has("beasts") or main.args.has("people")) and main.args.has("no-extras"):
		# (the monster sheets need no world: shot straight from the title, and the tour ends)
		main.set_stack(["world"])
		main.world.set_process(false)
		if main.args.has("beasts"):
			await _beast_sheets(str(main.args.beasts))
		if main.args.has("people"):
			await _people_sheets(str(main.args.people))
		get_tree().quit(0)
		return
	await _shot("01_title")
	var only: PackedStringArray = str(main.args.get("areas", "")).split(",", false)
	var skip_bosses: bool = main.args.has("no-bosses")
	for id in Data.AREA_CHAIN:
		if not only.is_empty() and not only.has(id):
			continue
		var stop: Array = _stop(id)
		Game.reset()
		# the Living Land release: --hour=H shows the land at that hour (clock.gd)
		if main.args.has("hour"):
			Game.clock = float(main.args.hour) * 60.0
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
		# (every region, the mountain round the sect too: it is not on the chain of regions the story
		# opens one after another, and a lord who stands on it, Part XVIII's Huilu, could not be shot)
		for aid in Data.AREAS:
			var aspec: Dictionary = Data.AREAS[aid]
			for bb in aspec.get("bosses", []):
				if bb.id != bid:
					continue
				var bstop: Array = _stop(aid)
				Game.reset()
				# (at the level a player meets the boss at, at the least: the region's own stop may be
				# chapters earlier, and Part XVII's lords would floor a cultivator of Part I at a blow)
				Game.level = maxi(int(bstop[1]), int(bb.get("req", 0)))
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
	if main.args.has("part12"):
		await _part12_shots()
	if main.args.has("part13"):
		await _part13_shots()
	if main.args.has("gallery12"):
		await _part12_galleries()
	if main.args.has("props"):
		await _props_shots()
	if main.args.has("lotus"):
		await _lotus_shots()
	elif main.args.has("hermitage"):
		await _hermitage_shots()
	elif main.args.has("kite"):
		await _kite_shot()
	if main.args.has("fates"):
		await _fates_shots()
	if main.args.has("living"):
		await _living_shots(str(main.args.living))
	if main.args.has("part16"):
		await _part16_shots(str(main.args.part16))
	if main.args.has("sword"):
		# the Spring Thunder release (--sword, or --sword=a,b): the sword in the open world and Part XVII
		await _sword_shots(str(main.args.sword))
	if main.args.has("fire"):
		# the New Fire release (--fire, or --fire=a,b): the Six Hearths, the hero as a young woman, the
		# beginnings and the ends, and Part XVIII
		await _fire_shots(str(main.args.fire))
	if main.args.has("works"):
		# the Hundred Works release (--works, or --works=a,b): the machines, the Works and Crossroads
		# pages, a crossroads being asked, the wild by the hour, and Part XIX
		await _works_shots(str(main.args.works))
	if main.args.has("hollow"):
		# the Hollow Hills release (--hollow, or --hollow=a,b): the caves, the bigger houses, the new
		# things to do and Part XX
		await _hollow_shots(str(main.args.hollow))
	if main.args.has("arms"):
		# the Hundred Arms release (--arms, or --arms=a,b): the faces, the Eight Arms and their forms, the
		# Arms page, the ends of the story and Part XXI
		await _arms_shots(str(main.args.arms))
	if main.args.has("bestiary"):
		# every monster model, one foe of each shape in its own palette, seven to a sheet (developer tool,
		# and the "before and after" of a release that reworks them): --bestiary, or --bestiary=<prefix>
		await _bestiary_shots(str(main.args.bestiary))
	if main.args.has("high"):
		# the High Roads release (--high, or --high=a,b): the mountains, climbing, the cloud-kite, the
		# people of the road and Part XXII
		await _high_shots(str(main.args.high))
	if main.args.has("pots"):
		# the Thundering Pots release (--pots, or --pots=a,b): the wardrobe, the field of war, the pages of
		# feats, songs and the host, the Drum Tower quarter, Old Du's mat and Part XXIII
		await _pots_shots(str(main.args.pots))
	if main.args.has("horse"):
		# the Lost Horse release (--horse, or --horse=a,b): what the choices left standing, the battles that
		# cannot be won, and Part XXIV
		await _horse_shots(str(main.args.horse))
	if main.args.has("burrows"):
		# the Three Burrows release (--burrows, or --burrows=a,b): the town that is the hero's own, its plots,
		# its people, the three crossroads and Part XXV
		await _burrows_shots(str(main.args.burrows))
	if main.args.has("frolics"):
		# the Underclothes release (--frolics, or --frolics=a,b): the people in their underclothes, the
		# physician's chapter, its lords, its crossroads and what each answer leaves standing (Part XXVI)
		await _frolics_shots(str(main.args.frolics))
	if main.args.has("heavy"):
		# the Heavy Road release (--heavy, or --heavy=a,b): what a load looks like, the work of the hands,
		# the people, foes and lords of Part XXVII, its crossroads and the page of the load
		await _heavy_shots(str(main.args.heavy))
	if main.args.has("answer"):
		# the Answering Land release (--answer, or --answer=a,b): the ten clips of the work of the towns, a town
		# festive, afraid and cold with what it hangs at its doors, the page of the land, the people, foes and
		# lords of Part XXVIII, its crossroads and what each answer leaves standing
		await _answer_shots(str(main.args.answer))
	if main.args.has("ending"):
		# the ending on its own (--ending, or --ending=<id> for one of the ends: cultures.gd): its film
		# and the results
		_ending_state()
		if Cultures.ENDINGS.has(str(main.args.ending)):
			Game.ending = str(main.args.ending)
		await _ending_shots()
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
	_ending_state()
	await _ending_shots()
	get_tree().quit(0)


# ---------------------------------------------------------------- the Spring Thunder release (--sword)
## The game as it stands at Part XVII's step `step_id`.
func _spring_state(step_id: String) -> void:
	_part16_state("s_p16_end")
	Game.step = Data.step_index(step_id)
	Game.level = 64
	Game.exp = float(Game.exp_need()) * 0.4
	for i in Game.step:
		if str(Data.STEPS[i].kind) == "kill":
			Game.boss_done[str(Data.STEPS[i].boss)] = true
	Game.heal_full()

## An open tile beside world tile `t` with another open tile behind it (to stand on and swing from),
## and the direction from it to `t`; [] if there is none.
func _swing_from(t: Vector2i) -> Array:
	var w = main.world
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		var st: Vector2i = t + d
		if w.tile_free(st) and w.tile_free(st + d) and w.ent_at(st) == null and Havoc.at_tile(w.wd, st).is_empty():
			return [st, -d]
	return []

## A camera beside the swing: the first open eye from the side or over the shoulder with a clear view.
func _side_eye(pp: Vector3, fwd: Vector3, look: Vector3, dist: float = 3.6, hgt: float = 2.0) -> Vector3:
	var side := fwd.cross(Vector3.UP)
	for c2 in [[-0.6, 1.0], [-0.6, -1.0], [-2.0, 0.85], [-2.0, -0.85], [-3.2, 0.5], [-3.2, -0.5]]:
		var e: Vector3 = pp + fwd * float(c2[0]) + side * float(c2[1]) * dist + Vector3(0, hgt, 0)
		if _open_round(e) and _clear_view(e, look):
			return e
	return pp - fwd * 0.6 + side * dist + Vector3(0, hgt, 0)

func _sword_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_spring_state("s_p17_home")
	for tk in Bonds.TALKS:
		Game.talks[str(tk.id)] = str(tk.options[0].id)
	main.world.clear_cache()
	main.set_stack(["world"])
	main.world.open_world()
	Game.clock = 10.5 * 60.0
	if want.call("fell"):
		await _fell_shots()
	if want.call("rock"):
		await _rock_shot()
	if want.call("qi"):
		await _qi_shots()
	if want.call("first"):
		await _first_strike_shots()
	if want.call("ox"):
		await _obstacle_shots("s_p17_ox", "p17_ox", "part17_spring_ox")
	if want.call("deadfall"):
		await _obstacle_shots("s_p17_deadfall", "p17_dead1", "part17_deadfall")
	if want.call("ice"):
		await _obstacle_shots("s_p17_ice", "p17_ice1", "part17_ice")
	if want.call("chains"):
		await _obstacle_shots("s_p17_chains", "p17_chain1", "part17_chains")
	if want.call("gods"):
		await _portraits("part17_gods", [Assets.person("gou_mang"), Assets.person("lei_gong")], 1.2, 1.55, 3.6)
		# (the lords between the beasts, so the big ones do not stand shoulder to shoulder)
		await _gallery("part17_foes", [_foe("rime_wisp"), _foe("qing_nu", true), _foe("hoarfrost_hare"), _foe("late_frost"), _foe("taisui", true), _foe("waking_scorpion"), _foe("waking_centipede"), _foe("poison_mother", true), _foe("waking_toad")], 1.15, 0.25)
	if want.call("cast"):
		# the anime re-sculpt: the cast of the game in a row, women and men, young and old
		await _gallery("anime_cast", [Assets.person("yue_ling"), Models.hero({"glow": Color(0.4, 0.7, 1.0)}), Assets.person("chang_e"), Assets.person("elder_qing"),
			Assets.person("ah_mei"), Assets.person("hu_qingyi"), Assets.person("granny_wen"), Assets.person("child_hua"), Assets.person("gou_mang")], 0.42, 0.0)
		await _portraits("anime_faces", [Assets.person("yue_ling"), Models.hero({"glow": Color(0.4, 0.7, 1.0)}), Assets.person("chang_e"), Assets.person("hu_qingyi")], 0.62, 1.68, 1.9)

## A tree at the forest's edge is cut through and falls: a strip of its fall, and the logs after.
func _fell_shots() -> void:
	var w = main.world
	main.world.open_world()
	for area in ["bamboo", "sect", "garden", "maple"]:
		var lw := Atlas.world_of("surface")
		var target := Vector2i(-1, -1)
		var stand: Array = []
		w.enter_layer("surface")
		var cand: Array = []
		for e in lw.ents:
			if str(e.get("area", "")) == area and e.kind in ["npc", "pickup", "prop"]:
				cand.append(e.pos)
		if cand.is_empty():
			continue
		w.teleport(_nearest_free(cand[0]), "surface")
		await _wait(1.5)
		var v: Dictionary = w.views.get(area, {})
		if v.is_empty():
			print("[tour] no view of %s yet (views: %s)" % [area, str(w.views.keys())])
			continue
		var reg: Dictionary = (v.root as Node3D).get_meta("nature", {})
		var r0: Vector2i = v.get("origin", Vector2i.ZERO)
		print("[tour] %s: %d tiles with things growing on them" % [area, reg.size()])
		var best := 1 << 30
		for lt in reg:
			var has_tree := false
			for en in reg[lt]:
				if str(en.kind) == "tree":
					has_tree = true
			if not has_tree:
				continue
			var wt: Vector2i = lt + r0
			var sf := _swing_from(wt)
			if sf.is_empty():
				continue
			var dd: int = absi(wt.x - w.ptile.x) + absi(wt.y - w.ptile.y)
			if dd < best:
				best = dd
				target = wt
				stand = sf
		if stand.is_empty():
			continue
		w.teleport(stand[0], "surface")
		w.facing = stand[1]
		w.cam_q = _quarter(Vector2(w.facing))
		w._snap_cam()
		await _wait(1.2)
		var pp: Vector3 = w._player_pos()
		var fwd := Vector3(w.facing.x, 0, w.facing.y)
		var look := pp + fwd * 2.5 + Vector3(0, 1.6, 0)
		var eye := _side_eye(pp, fwd, look, 6.0, 2.6)
		w.cam_override = Transform3D(Basis.IDENTITY, eye).looking_at(look, Vector3.UP)
		w.strike()
		var strip: Array = []
		for k in 5:
			await _wait(0.42)
			await _shot("sword_fell_%d" % k, false)
			strip.append(last_img)
		await _sheet("sword_fell_sheet", strip, 0.4)
		last_img = strip[2]
		last_img.save_webp("%s/sword_fell.webp" % dir, true, 0.9)
		await _wait(1.0)
		await _shot("sword_fell_after")
		w.cam_override = null
		return

## A boulder on open ground shatters.
func _rock_shot() -> void:
	var w = main.world
	main.world.open_world()
	for area in ["thunder", "frost", "sect", "bamboo"]:
		var lw := Atlas.world_of("surface")
		w.enter_layer("surface")
		var cand: Array = []
		for e in lw.ents:
			if str(e.get("area", "")) == area and e.kind in ["npc", "pickup", "prop"]:
				cand.append(e.pos)
		if cand.is_empty():
			continue
		w.teleport(_nearest_free(cand[0]), "surface")
		await _wait(1.5)
		var v: Dictionary = w.views.get(area, {})
		if v.is_empty():
			continue
		var reg: Dictionary = (v.root as Node3D).get_meta("nature", {})
		var r0: Vector2i = v.get("origin", Vector2i.ZERO)
		var stand: Array = []
		for lt in reg:
			for en in reg[lt]:
				if str(en.kind) == "rock" and stand.is_empty():
					var sf := _swing_from(lt + r0)
					if not sf.is_empty():
						stand = sf
		if stand.is_empty():
			continue
		w.teleport(stand[0], "surface")
		w.facing = stand[1]
		w.cam_q = _quarter(Vector2(w.facing))
		w._snap_cam()
		await _wait(1.2)
		var pp: Vector3 = w._player_pos()
		var fwd := Vector3(w.facing.x, 0, w.facing.y)
		var look := pp + fwd * 1.5 + Vector3(0, 0.6, 0)
		w.cam_override = Transform3D(Basis.IDENTITY, _side_eye(pp, fwd, look, 3.8, 1.8)).looking_at(look, Vector3.UP)
		w.strike()
		await _wait(0.4)
		await _shot("sword_rock")
		w.cam_override = null
		return

## The sword qi across a meadow: in flight, and the swathe it mowed.
func _qi_shots() -> void:
	var w = main.world
	main.world.open_world()
	w.enter_layer("surface")
	var lw := Atlas.world_of("surface")
	# a long straight run of open ground in a field: the Scorched Millet Plains first, else round the
	# village, the tea terraces or the maple gorge
	var start := Vector2i(-1, -1)
	var dir := Vector2i(1, 0)
	var bases: Array = []
	for aid in ["millet", "village", "terraces", "maple"]:
		var sp: Dictionary = Data.AREAS[aid]
		bases.append(Atlas.to_world(aid, Vector2i(int(sp.w) / 2, int(sp.h) / 2)))
	for base in bases:
		if start.x >= 0:
			break
		for r in 45:
			if start.x >= 0:
				break
			for dx in range(-r, r + 1):
				for dy in [-r, r]:
					for dd in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
						var p: Vector2i = base + Vector2i(dx, dy)
						if start.x >= 0:
							continue
						var ok := true
						# (open ground behind him too, for the eye over his shoulder, and two tiles either side: a
						# field, not a lane between houses)
						var sd := Vector2i(-dd.y, dd.x)
						for k in range(-6, 9):
							for o2 in [0, -2, -1, 1, 2]:
								var q: Vector2i = p + dd * k + sd * o2
								if not w.tile_free(q) or lw.grid[q.y * int(lw.w) + q.x] == MapGen.PATH or w.ent_at(q) != null:
									ok = false
									break
							if not ok:
								break
						if ok:
							start = p
							dir = dd
	if start.x < 0:
		return
	w.teleport(start, "surface")
	w.facing = dir
	w.cam_q = _quarter(Vector2(dir))
	w._snap_cam()
	await _wait(1.5)
	Game.qi[0] = float(Game.max_qi(0))
	var pp: Vector3 = w._player_pos()
	var fwd := Vector3(dir.x, 0, dir.y)
	var look := pp + fwd * 6.0 + Vector3(0, 0.6, 0)
	# (over his shoulder, down the way the qi flies: from the side the eye can land in a house)
	var side := fwd.cross(Vector3.UP)
	var eye := pp - fwd * 4.2 + side * 1.4 + Vector3(0, 2.7, 0)
	for c3 in [[4.2, 1.4], [4.2, -1.4], [3.2, 2.2], [3.2, -2.2], [2.4, 0.8]]:
		var e3: Vector3 = pp - fwd * float(c3[0]) + side * float(c3[1]) + Vector3(0, 2.7, 0)
		if _open_round(e3) and _clear_view(e3, look):
			eye = e3
			break
	w.cam_override = Transform3D(Basis.IDENTITY, eye).looking_at(look, Vector3.UP)
	w.qi_wave()
	await _wait(0.12)
	await _shot("sword_qi")
	await _wait(1.6)
	await _shot("sword_qi_mown")
	w.cam_override = null

## A pack struck first in the land: thrown back, and the battle that opens with it reeling.
func _first_strike_shots() -> void:
	var w = main.world
	main.world.open_world()
	w.enter_layer("surface")
	var lw := Atlas.world_of("surface")
	for e in lw.ents:
		if e.kind != "enemy" or str(e.get("area", "")) != "frost" or not w.ent_visible(e):
			continue
		# (at the pack's own level: two realms above it, it would scatter before his aura instead)
		var top_lv := 1
		for g in e.group:
			top_lv = maxi(top_lv, int(g.lv))
		Game.level = top_lv
		Game.heal_full()
		if Game.scatters(e.group):
			continue
		var sf := _swing_from(e.pos)
		if sf.is_empty():
			continue
		w.teleport(sf[0], "surface")
		w.facing = sf[1]
		w.cam_q = _quarter(Vector2(w.facing))
		w._snap_cam()
		await _wait(1.5)
		var pp: Vector3 = w._player_pos()
		var fwd := Vector3(w.facing.x, 0, w.facing.y)
		var look := pp + fwd * 2.0 + Vector3(0, 0.9, 0)
		w.cam_override = Transform3D(Basis.IDENTITY, _side_eye(pp, fwd, look, 4.2, 2.0)).looking_at(look, Vector3.UP)
		w.strike()
		await _wait(0.22)
		await _shot("sword_first_strike")
		w.cam_override = null
		await _wait(2.4)
		await _shot("sword_first_strike_battle")
		return

## One of Part XVII's obstacles, before the blow and as it comes apart.
func _obstacle_shots(step_id: String, ob_id: String, n: String) -> void:
	_spring_state(step_id)
	for tk in Bonds.TALKS:
		Game.talks[str(tk.id)] = str(tk.options[0].id)
	Game.clock = 10.5 * 60.0
	var w = main.world
	main.world.open_world()
	w.enter_layer("surface")
	var e := _land_ent(ob_id)
	if e.is_empty():
		print("[tour] no obstacle ", ob_id)
		return
	var sf := _swing_from(e.pos)
	if sf.is_empty():
		print("[tour] nowhere to swing at ", ob_id, " from")
		return
	w.teleport(sf[0], "surface")
	w.facing = sf[1]
	w.cam_q = _quarter(Vector2(w.facing))
	w._snap_cam()
	await _wait(1.6)
	var pp: Vector3 = w._player_pos()
	var fwd := Vector3(w.facing.x, 0, w.facing.y)
	var look := pp + fwd * 1.3 + Vector3(0, 0.8, 0)
	w.cam_override = Transform3D(Basis.IDENTITY, _side_eye(pp, fwd, look, 3.9, 2.0)).looking_at(look, Vector3.UP)
	await _wait(0.3)
	await _shot(n)
	var spec: Dictionary = Impact.OBSTACLES.get(str(e.what), {"hits": 1})
	for k in int(spec.hits):
		w.strike_t = -9.0
		w.strike()
		await _wait(0.2 if k < int(spec.hits) - 1 else 0.38)
	await _shot(n + "_broken")
	w.cam_override = null
	while main.top_name() == "dialogue":
		_skip_talk()
		await _wait(0.1)

## Stand beside the thing of the land `ent_id` at hour `hour` and look at it from the side: screenshot `n`.
func _ent_shot(ent_id: String, n: String, hour: float, dist: float = 4.6, hgt: float = 2.2, up: float = 1.0) -> void:
	var w = main.world
	w.open_world()
	w.enter_layer("surface")
	Game.clock = hour * 60.0
	var e := _land_ent(ent_id)
	if e.is_empty():
		print("[tour] nothing called ", ent_id)
		return
	var sf := _swing_from(e.pos)
	if sf.is_empty():
		sf = [_nearest_free(e.pos + Vector2i(0, 2)), Vector2i(0, -1)]
	w.teleport(sf[0], "surface")
	w.facing = sf[1]
	w.cam_q = _quarter(Vector2(w.facing))
	w._snap_cam()
	w.banner_t = 0.0
	await _wait(1.2)
	var pp: Vector3 = w._player_pos()
	var fwd := Vector3(w.facing.x, 0, w.facing.y)
	var look := pp + fwd * 1.6 + Vector3(0, up, 0)
	w.cam_override = Transform3D(Basis.IDENTITY, _side_eye(pp, fwd, look, dist, hgt)).looking_at(look, Vector3.UP)
	await _wait(0.5)
	await _shot(n)
	w.cam_override = null

## The Hundred Works release (works.gd, machines.gd, echoes.gd, habits.gd): the machines of the three
## schools, the people and the foes of Part XIX, the Works and Crossroads pages, the last question of
## Part XIX being asked, machines standing in the land, and a pack of the wild at noon and at dawn.
## The Hollow Hills release (--hollow, or --hollow=a,b to pick): caves made of voxels (their mouths on
## the land, their chambers, shafts, pools and lower galleries: "caves", for the regions of
## --cave-areas=a,b), the things of the caves ("things"), the houses with twice the room ("rooms"),
## the people, foes and lords of Part XX ("people", "foes", "bosses"), a crossroads being asked
## ("choice"), the Journal's new way through a trial ("page") and the eyes before and after ("eyes").
func _hollow_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_spring_state("s_p19_end")
	Game.level = 72
	Game.step = Data.step_index("s_p20_hollow")
	for cid in BOT.CROSS_PLAN:
		if Data.step_index(str(Echoes.CROSSROADS[cid].step)) < Game.step:
			Echoes.take(Game, cid, str(BOT.CROSS_PLAN[cid][0]))
	Game.toasts.clear()
	main.set_stack(["world"])
	main.world.clear_cache()
	main.world.load_area("sect", Vector2i(20, 9))
	main.world.banner_t = 0.0
	var w = main.world
	if want.call("things"):
		for half in 2:
			var ms: Array = []
			for k in CaveThings.KINDS.slice(half * 7, half * 7 + 7):
				ms.append(CaveThings.model(str(k), "bamboo" if CaveThings.KINDS.find(k) % 2 == 0 else "frost"))
			await _gallery("cave_things_%d" % (half + 1), ms, 2.4, 0.0)
	if want.call("people"):
		await _gallery("part20_people", [Assets.person("xu_xiake"), Assets.person("yu_gong"), Assets.person("zhi_sou"), Assets.person("wang_zhi"), Assets.person("xuanpin")], 0.7, 0.2)
		await _portraits("part20_faces", [Assets.person("xu_xiake"), Assets.person("yu_gong"), Assets.person("wang_zhi"), Assets.person("xuanpin")], 0.66, 1.68, 2.1)
	if want.call("foes"):
		await _gallery("part20_foes", [_foe("cave_cricket"), _foe("blind_newt"), _foe("drip_wisp"), _foe("fen_yang", true), _foe("stone_bat"), _foe("dig_mole"), _foe("ore_gnawer"), _foe("white_rat", true),
			_foe("lamp_ghost"), _foe("kept_voice"), _foe("hollow_one"), _foe("wangliang", true), _foe("burrow_marmot"), _foe("sink_toad"), _foe("karst_crawler"), _foe("xuanpin", true)], 1.2, 0.25)
	if want.call("eyes"):
		# the same four faces as docs/screenshots/sculpt_faces.webp showed before the eyes were made larger
		await _portraits("eyes_faces", [Assets.person("yue_ling"), Models.hero({"glow": Color(0.4, 0.7, 1.0), "look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": false}), Assets.person("chang_e"), Assets.person("hu_qingyi")], 0.62, 1.68, 1.9)
		var after: Image = last_img.duplicate()
		var before := Image.load_from_file(ProjectSettings.globalize_path("res://docs/screenshots/sculpt_faces.webp"))
		if before != null and not before.is_empty():
			before.resize(after.get_width(), after.get_height(), Image.INTERPOLATE_LANCZOS)
			var sheet := Image.create(after.get_width(), after.get_height() * 2, false, after.get_format())
			before.convert(after.get_format())
			sheet.blit_rect(before, Rect2i(0, 0, after.get_width(), after.get_height()), Vector2i(0, 0))
			sheet.blit_rect(after, Rect2i(0, 0, after.get_width(), after.get_height()), Vector2i(0, after.get_height()))
			sheet.save_webp("%s/eyes_before_after.webp" % dir, true, 0.9)
			print("[tour] eyes_before_after")
	if want.call("caves"):
		for area in str(main.args.get("cave-areas", "bamboo,frost,volcano,karst,cloudsea,tushan")).split(",", false):
			var cw: Dictionary = Atlas.world_of(Caves.fid(area))
			if cw.is_empty():
				continue
			var lay := Caves.layout(area)
			# the mouth, from the land
			var le: Array = w.locate_ent("cave:" + area)
			if not le.is_empty():
				w.teleport(le[1].pos + Vector2i(0, 3), str(le[0]))
				w.facing = Vector2i(0, -1)
				w.cam_q = 0
				w._snap_cam()
				w.banner_t = 0.0
				await _wait(1.0)
				await _shot("cave_mouth_" + area)
			# inside: looking back at the way out, then the chambers in turn, deepest last
			await _cave_shot(area, -1, lay.arrive + Vector2i(0, -2), Vector2i(0, 1), "cave_%s_in" % area)
			var rooms: Array = (lay.rooms as Array).duplicate()
			rooms.sort_custom(func(a, b): return int(a.far) < int(b.far))
			var n := 0
			for r in rooms.slice(1):
				n += 1
				await _cave_shot(area, -1, r.c, Vector2i(0, -1) if n % 2 == 1 else Vector2i(1, 0), "cave_%s_%d" % [area, n])
			if not Caves.spec(area, -2).is_empty():
				var lay2 := Caves.layout(area, -2)
				await _cave_shot(area, -2, lay2.rooms[int(lay2.far_room)].c, Vector2i(0, -1), "cave_%s_lower" % area)
	if want.call("rooms"):
		# a storey and a cellar that rooms.gd laid out, in Qingshi and at Tushan
		var sw: Dictionary = Atlas.world_of("surface")
		var shot_n := {}
		for fid in sw.floors:
			var fw: Dictionary = sw.floors[fid]
			if fw.get("cave", false) or not str(fw.area) in ["village", "tushan", "longmen"]:
				continue
			var key := "%s_%s" % [fw.area, "upper" if int(fw.level) > 0 else "cellar"]
			if int(shot_n.get(key, 0)) >= 2:
				continue
			var made := false
			for bd in Data.AREAS[str(fw.area)].get("buildings", []):
				if str(bd.id) == str(fw.bld):
					made = not bd.has("upper" if int(fw.level) > 0 else "cellar")
			if not made:
				continue
			shot_n[key] = int(shot_n.get(key, 0)) + 1
			w.teleport(fw.start, fid)
			var mid := Vector2(fw.w, fw.h) * 0.5
			var dv := mid - Vector2(fw.start)
			var fdir := Vector2i(signi(int(dv.x)), 0) if absf(dv.x) > absf(dv.y) else Vector2i(0, signi(int(dv.y)))
			if fdir == Vector2i.ZERO:
				fdir = Vector2i(0, 1)
			w.facing = fdir
			w.cam_q = w.FWD.find(fdir)
			w._snap_cam()
			w.banner_t = 0.0
			await _wait(0.8)
			await _shot("rooms_%s_%d" % [key, int(shot_n[key])])
		w.load_area("sect", Vector2i(20, 9))
	if want.call("bosses"):
		for bid in ["fen_yang", "white_rat", "wangliang", "xuanpin"]:
			var ba := Trials.boss_area(bid)
			w.load_area(ba, MapGen.arrival_tiles(ba)[0] if not MapGen.arrival_tiles(ba).is_empty() else Vector2i(20, 20))
			main.battle.start([{"id": bid, "lv": 74}], {"boss": true, "enemy": bid, "theme": "ninesprings"})
			main.push("battle")
			await _wait(2.8)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		Game.cross_pending = ["the_hollow"]
		main.ask_crossroads()
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("crossroads_hollow")
		main.pop()
		Game.cross_pending = []
	if want.call("page"):
		Game.delved = {"f:bamboo:cave:-1": true, "f:tushan:cave:-1": true, "f:karst:cave:-1": true}
		main.open_trial({"enemy": "white_rat", "lv": 74, "req": 73, "id": "boss_white_rat", "pos": Vector2i.ZERO})
		await _wait(0.8)
		await _shot("trial_by_the_dark")
		main.pop()
	main.world.load_area("sect", Vector2i(20, 9))

## One look inside a cave: the hero on the free tile nearest `at` of gallery `level` of the cave of
## `area`, facing `dir`.
func _cave_shot(area: String, level: int, at: Vector2i, dir: Vector2i, name: String) -> void:
	var w = main.world
	var fid := Caves.fid(area, level)
	var fw: Dictionary = Atlas.world_of(fid)
	if fw.is_empty():
		return
	w.enter_layer(fid)
	var best := Vector2i(-1, -1)
	var bd := 1 << 30
	for y in int(fw.h):
		for x in int(fw.w):
			var t := Vector2i(x, y)
			if fw.grid[y * int(fw.w) + x] != MapGen.INTERIOR or w.ent_at(t) != null:
				continue
			# (with open floor ahead, so that there is something to look along)
			var ahead: Vector2i = t + dir * 2
			if ahead.x < 0 or ahead.y < 0 or ahead.x >= int(fw.w) or ahead.y >= int(fw.h) or fw.grid[ahead.y * int(fw.w) + ahead.x] != MapGen.INTERIOR:
				continue
			var dd: int = (t - at).length_squared()
			if dd < bd:
				bd = dd
				best = t
	if best.x < 0:
		return
	w.teleport(best, fid)
	w.facing = dir
	w.cam_q = maxi(0, w.FWD.find(dir))
	w._snap_cam()
	w.banner_t = 0.0
	await _wait(0.7)
	await _shot(name)

func _works_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	main.set_stack(["world"])
	main.world.load_area("sect", Vector2i(20, 9))
	main.world.banner_t = 0.0
	if want.call("machines"):
		var by_school := {"works_wheel": ["well_sweep", "water_wheel", "trip_hammer", "water_bellows", "crossbow", "chariot", "wooden_ox"],
			"works_hand": ["fire_kit", "cords", "sling", "kiln", "adze", "hide_coat"], "works_art": ["array", "talismans", "furnace", "paper_servants", "mirror", "flags"]}
		for shot in by_school:
			var ms: Array = []
			for k in by_school[shot]:
				var mm := Machines.model(str(k))
				Machines.animate(mm, 2.2)
				mm.scale = Vector3.ONE * 1.5
				ms.append(mm)
			await _gallery(shot, ms, 2.0, 0.35)
	if want.call("people"):
		await _gallery("part19_people", [Assets.person("gongshu_ban"), Assets.person("mo_di"), Assets.person("gardener_hanyin"), Assets.person("yan_shi"), Assets.person("the_player")], 0.7, 0.2)
		await _portraits("part19_faces", [Assets.person("gongshu_ban"), Assets.person("mo_di"), Assets.person("gardener_hanyin"), Assets.person("the_player")], 0.66, 1.68, 2.1)
	if want.call("foes"):
		await _gallery("part19_foes", [_foe("wheel_mite"), _foe("treadle_imp"), _foe("idle_shuttle"), _foe("cloud_ladder", true), _foe("cog_crab"), _foe("bellows_wraith"), _foe("hammer_golem"),
			_foe("the_player", true), _foe("wooden_kite"), _foe("stray_ox"), _foe("paper_servant"), _foe("jixin", true), _foe("brass_spiderling"), _foe("counting_wasp"), _foe("tally_golem"), _foe("wooden_magpie", true)], 1.2, 0.25)
	if want.call("page") or want.call("choice") or want.call("land"):
		# a journey as the bot makes it: the wheel's school first, the answers of its plan at the crossroads
		_spring_state("s_p19_makers")
		Game.level = 71
		for eid in Data.ENEMIES:
			Game.bestiary[eid] = 1
		Game.stones = 420000
		for wid in ["well_sweep", "trip_hammer", "water_bellows", "crossbow", "chariot", "fire_kit", "cords", "sling", "kiln", "array", "talismans", "furnace"]:
			Game.works[wid] = 3 + Works.ORDER.find(wid) * 9
		for cid in BOT.CROSS_PLAN:
			if Data.step_index(str(Echoes.CROSSROADS[cid].step)) < Game.step:
				Echoes.take(Game, cid, str(BOT.CROSS_PLAN[cid][0]))
		for cid2 in Game.picks:
			for ek in Echoes.CROSSROADS.get(cid2, {}).get("echo", {}):
				Game.echoed["%s|%s" % [cid2, ek]] = true
		Game.toasts.clear()
		main.world.clear_cache()
		main.world.load_area("sect", Vector2i(20, 12))
	if want.call("page"):
		main.open_menu()
		main.menu.cursor = main.menu.ids.find("works")
		await _wait(0.6)
		await _shot("menu_works_root")
		main.menu.mode = "works"
		main.menu.cursor = Works.ORDER.find("wooden_ox")
		main.menu._build()
		await _wait(0.6)
		await _shot("works_page")
		main.menu.mode = "roads"
		main.menu.cursor = Echoes.ORDER.find("bandits")
		main.menu._build()
		await _wait(0.6)
		await _shot("crossroads_page")
		main.menu.mode = "bestiary"
		main.menu._build()
		main.menu.cursor = maxi(0, main.menu.ids.find("bamboo_wolf"))
		await _wait(0.6)
		await _shot("bestiary_hours")
		main.pop()
	if want.call("choice"):
		Game.cross_pending = ["the_works"]
		main.ask_crossroads()
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("crossroads_choice")
		main.pop()
		Game.cross_pending = []
	if want.call("land"):
		await _ent_shot("work_ban_wheel", "works_ban_wheel", 9.5, 6.4, 2.6, 1.6)
		await _ent_shot("work_well_sweep", "works_well_sweep", 16.5, 5.6, 2.4, 1.4)
		await _ent_shot("work_trip_hammer", "works_trip_hammer", 10.5, 5.0, 2.2, 1.0)
		await _ent_shot("work_chariot", "works_chariot", 8.0, 5.0, 2.2, 1.0)
	if want.call("wild"):
		# the same pack of wolves in the Bamboo Forest at noon (asleep), at dawn (hunting) and at
		# dusk on the same day (hunting again); and things of the night gathered at midnight
		Game.reset()
		Game.level = 2
		Game.companion = true
		Game.heal_full()
		Game.step = Data.step_index("s_hunt1")
		main.world.clear_cache()
		main.set_stack(["world"])
		main.world.open_world()
		var pack := ""
		for e in Atlas.world_of("surface").ents:
			if e.kind == "enemy" and str(e.area) == "bamboo" and str(e.group[0].id) == "bamboo_wolf" and (e.group as Array).size() >= 2 and not _swing_from(e.pos).is_empty():
				pack = str(e.id)
				break
		if pack != "":
			await _ent_shot(pack, "wild_noon_asleep", 12.2, 5.2, 2.0, 0.8)
			await _ent_shot(pack, "wild_dawn_hunting", 5.3, 5.2, 2.0, 0.8)
			await _ent_shot(pack, "wild_morning_foraging", 9.0, 5.2, 2.0, 0.8)
		else:
			print("[tour] no pack of wolves to look at")
	if want.call("part19"):
		_spring_state("s_p19_cogs")
		Game.level = 70
		main.world.clear_cache()
		main.set_stack(["world"])
		main.world.open_world()
		await _obstacle_shots("s_p19_cogs", "p19_cog1", "part19_cogwork")

## The New Fire release (cultures.gd, voice.gd): the creation screen with its two new choices, the four
## looks on a woman's frame, the people and the dress of the Six Hearths, the faces before and after
## the re-sculpt, the Hearths page, two of the six beginnings, Part XVIII's obstacles and foes, and the
## choice of an end with one of the ends chosen.
func _fire_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	if want.call("create"):
		Game.reset()
		main.set_stack(["title"])
		main.open_creation()
		main.create.h = {"family": "Lin", "given": "Feng", "body": "f", "look": "sweeper", "hair": 0, "eyes": 0, "robe": 0, "origin": "foundling", "hearth": "valley"}
		main.create.cursor = main.create.ROWS.find("body")
		main.create._preview()
		await _wait(1.5)
		await _shot("create_woman")
		main.create.h = {"family": "Su", "given": "Lan", "body": "f", "look": "wanderer", "hair": 1, "eyes": 2, "robe": 1, "origin": "hunter", "hearth": "steppe"}
		main.create.cursor = main.create.ROWS.find("hearth")
		main.create._preview()
		await _wait(1.5)
		await _shot("create_hearth")
		main.set_stack(["title"])
		main.title.show_hero({"look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": false})
	main.set_stack(["world"])
	main.world.load_area("sect", Vector2i(20, 9))
	main.world.banner_t = 0.0
	if want.call("looks"):
		var looks: Array = []
		for lk in Fashion.LOOK_ORDER:
			looks.append(Models.hero({"look": lk, "cols": {}, "outfit": "sweeper", "fem": true}))
		for lk2 in Fashion.LOOK_ORDER:
			looks.append(Models.hero({"look": lk2, "cols": {}, "outfit": "sweeper", "fem": false}))
		await _gallery("hero_women_and_men", looks, 0.62, 0.2)
		await _portraits("hero_women_faces", [Models.hero({"look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": true}), Models.hero({"look": "wanderer", "cols": {}, "outfit": "sweeper", "fem": true}),
			Models.hero({"look": "wild", "cols": {}, "outfit": "sweeper", "fem": true}), Models.hero({"look": "scholar", "cols": {}, "outfit": "sweeper", "fem": true})], 0.62, 1.68, 1.9)
	if want.call("people"):
		# the keeper of the Felt Hearth and her grandson, the dress of five hearths, and the Lord of Fire
		await _gallery("hearth_people", [Assets.person("sarnai"), Assets.person("batu"), Assets.person("folk_herder_f"), Assets.person("folk_herder"), Assets.person("folk_oasis_f"),
			Assets.person("folk_boatwoman"), Assets.person("folk_founder"), Assets.person("folk_lantern_f")], 0.6, 0.2)
		await _portraits("hearth_faces", [Assets.person("sarnai"), Assets.person("folk_oasis_f"), Assets.person("folk_boatwoman"), Assets.person("folk_lantern_f")], 0.66, 1.68, 2.1)
	if want.call("sculpt"):
		# the faces after the re-sculpt, beside what docs/screenshots/anime_faces.webp showed before it
		await _portraits("sculpt_faces", [Assets.person("yue_ling"), Models.hero({"glow": Color(0.4, 0.7, 1.0), "look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": false}), Assets.person("chang_e"), Assets.person("hu_qingyi")], 0.62, 1.68, 1.9)
		var after: Image = last_img.duplicate()
		var before := Image.load_from_file(ProjectSettings.globalize_path("res://docs/screenshots/anime_faces.webp"))
		if before != null and not before.is_empty():
			before.resize(after.get_width(), after.get_height(), Image.INTERPOLATE_LANCZOS)
			var sheet := Image.create(after.get_width(), after.get_height() * 2, false, after.get_format())
			before.convert(after.get_format())
			sheet.blit_rect(before, Rect2i(0, 0, after.get_width(), after.get_height()), Vector2i(0, 0))
			sheet.blit_rect(after, Rect2i(0, 0, after.get_width(), after.get_height()), Vector2i(0, after.get_height()))
			sheet.save_webp("%s/sculpt_before_after.webp" % dir, true, 0.9)
			print("[tour] sculpt_before_after")
		await _gallery("sculpt_cast", [Assets.person("yue_ling"), Models.hero({"glow": Color(0.4, 0.7, 1.0), "look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": true}), Models.hero({"look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": false}),
			Assets.person("chang_e"), Assets.person("elder_qing"), Assets.person("ah_mei"), Assets.person("granny_wen"), Assets.person("sarnai"), Assets.person("zhurong")], 0.46, 0.0)
	if want.call("page"):
		_ending_state()
		Game.finished = false
		Game.hearth = {"valley": 12, "steppe": 10, "sand": 12, "river": 7, "forge": 4, "dawn": 12}
		main.world.clear_cache()
		main.world.load_area("sect", Vector2i(20, 12))
		main.open_menu()
		await _wait(0.6)
		await _shot("menu_hearths_root")
		main.menu.mode = "hearths"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.6)
		await _shot("hearths_page")
		main.pop()
	if want.call("prologue") or which.contains("prologue_"):
		for hid in ["steppe", "sand", "valley"]:
			# (--fire=prologue_steppe: one of them)
			if not want.call("prologue") and not only.has("prologue_" + hid):
				continue
			main.new_game({"family": "Su", "given": "Lan", "body": "f", "look": "wanderer", "hair": 1, "eyes": 2, "robe": 1, "origin": "hunter", "hearth": hid})
			Game.clock = 7.2 * 60.0
			await _wait(2.5)
			await _shot("prologue_%s_words" % hid)
			while main.top_name() == "dialogue":
				_skip_talk()
				await _wait(0.1)
			var keeper = main.world.find_ent(str(Cultures.HEARTHS[hid].keeper))
			if keeper != null:
				var by := _nearest_free(keeper.pos)
				main.world.teleport(by)
				main.world.leash = by
				main.world.facing = keeper.pos - by if absi(keeper.pos.x - by.x) + absi(keeper.pos.y - by.y) == 1 else Vector2i(0, -1)
				main.world.cam_q = _quarter(Vector2(main.world.facing))
				main.world._snap_cam()
			main.world.banner_t = 3.0
			await _wait(2.0)
			await _shot("prologue_%s" % hid)
			if keeper != null and hid == "steppe":
				main.interact(keeper)
				await _wait(1.0)
				main.dialogue.shown = 999.0
				await _wait(0.6)
				await _shot("prologue_%s_farewell" % hid)
				while main.top_name() == "dialogue":
					_skip_talk()
					await _wait(0.1)
		Game.reset()
	if want.call("part18"):
		_spring_state("s_p18_home")
		Game.level = 67
		main.world.clear_cache()
		main.set_stack(["world"])
		main.world.open_world()
		await _obstacle_shots("s_p18_clinker", "p18_clinker1", "part18_clinker")
		await _obstacle_shots("s_p18_brush", "p18_brush1", "part18_brush")
		await _gallery("part18_foes", [_foe("damp_smoke"), _foe("bilge_imp"), _foe("drowned_ember"), _foe("zhurong", true), _foe("ash_moth"), _foe("cinder_imp"), _foe("clinker_crab"),
			_foe("huilu", true), _foe("wildfire_sprite"), _foe("spark_swallow"), _foe("smoke_hound")], 1.15, 0.25)
	if want.call("ends"):
		_ending_state()
		Game.hero = Fashion.default_hero()
		Game.hero["body"] = "f"
		Game.hero["hearth"] = "river"
		UI.set_hero_name("Lin", "Feng", true)
		Game.hearth = {"valley": 9, "steppe": 10, "sand": 12, "river": 12, "forge": 7, "dawn": 12}
		for rc in ["yumin", "dragon", "tianhu", "jiaoren", "deathless", "shade"]:
			Game.standing[rc] = 60
			Game.met[rc] = true
		main.world.clear_cache()
		main.set_stack(["world"])
		main.world.load_area("sect", Vector2i(20, 12))
		main.world.refresh_hero()
		main.choose_ending()
		main.choice.cursor = 2
		await _wait(1.0)
		await _shot("ending_choice")
		main.pop()
		Game.ending = "road"
		main.push("ending")
		await _wait(1.0)
		main.ending.t = 4.0
		main.press("confirm")
		await _wait(3.5)
		await _shot("ending_road")
		main.pop()
		UI.set_hero_name(Fashion.DEFAULT_FAMILY, Fashion.DEFAULT_GIVEN)
		Game.reset()


# ---------------------------------------------------------------- the Hundred Arms release
## A bare stage for figures: [stage, camera].
func _bare_stage(at_y: float, fov: float, floor_r: float = 0.0) -> Array:
	main.world.hide()
	var stage := Node3D.new()
	stage.position = Vector3(0, at_y, 0)
	main.add_child(stage)
	var cam := Camera3D.new()
	cam.fov = fov
	cam.environment = Look.environment("garden", 0.1)
	cam.environment.tonemap_exposure = 0.8
	stage.add_child(cam)
	stage.add_child(Look.sun("garden"))
	stage.add_child(Look.fill("garden"))
	var key := OmniLight3D.new()
	key.position = Vector3(1.5, 2.4, 4.0)
	key.omni_range = 12.0
	key.light_energy = 0.3
	stage.add_child(key)
	if floor_r > 0.0:
		var fl := MB.new()
		fl.disc(Vector3.ZERO, floor_r, MB.tag(Color("8a9a88"), MB.STONE), 48, MB.tag(Color("6a7a6a"), MB.STONE))
		MB.mesh_node(stage, fl.build(MB.mat_plain()))
	return [stage, cam]

func _caption(parent: Node3D, at: Vector3, text: String, size: float = 0.0016) -> void:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = 48
	lb.pixel_size = size
	lb.outline_size = 12
	lb.modulate = Color("fff4d8")
	lb.outline_modulate = Color("201810")
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.position = at
	parent.add_child(lb)

## Images of the same width stacked into one.
func _stack(n: String, rows: Array) -> void:
	if rows.is_empty():
		return
	var w: int = rows[0].get_width()
	var h := 0
	for im in rows:
		h += int(im.get_height() * float(w) / im.get_width())
	var out := Image.create(w, h, false, Image.FORMAT_RGB8)
	var y := 0
	for im2 in rows:
		var im: Image = im2
		im.convert(Image.FORMAT_RGB8)
		var hh := int(im.get_height() * float(w) / im.get_width())
		if im.get_width() != w:
			im.resize(w, hh, Image.INTERPOLATE_LANCZOS)
		out.blit_rect(im, Rect2i(0, 0, w, hh), Vector2i(0, y))
		y += hh
	out.save_webp("%s/%s.webp" % [dir, n], true, 0.9)
	print("[tour] ", n)

## A row of heads, each wearing one face (faces.gd), with its name under it: returns the image.
func _face_row(make: Callable, ids: Array, height: float, spacing: float = 0.36) -> Image:
	var sc := _bare_stage(460.0, 22.0)
	var stage: Node3D = sc[0]
	var cam: Camera3D = sc[1]
	var models: Array = []
	for i in ids.size():
		var m: Node3D = make.call()
		m.position = Vector3((i - (ids.size() - 1) * 0.5) * spacing, 0.0, 0.0)
		m.rotation.y = 0.18 if i % 2 == 0 else -0.18
		stage.add_child(m)
		Faces.wear(m, str(ids[i]))
		_caption(stage, m.position + Vector3(0, height - 0.215, 0.2), str(Faces.EXPRESSIONS[ids[i]].get("n", "At rest")), 0.00056)
		models.append(m)
	cam.position = Vector3(0, height + 0.02, 0.5 + ids.size() * spacing * 1.28)
	cam.look_at(stage.global_position + Vector3(0, height - 0.035, 0), Vector3.UP)
	cam.make_current()
	var t0 := 0.0
	for k in 36:
		t0 += 1.0 / 30.0
		for m2 in models:
			# (the idle clip from just after a blink, so no eye is caught shut by chance)
			Models.anim_person(m2, 1.6 + t0, false)
		await get_tree().process_frame
	await _shot("face_row", false)
	var img: Image = last_img
	var crop := img.get_region(Rect2i(0, int(img.get_height() * 0.3), img.get_width(), int(img.get_height() * 0.37)))
	stage.queue_free()
	main.world.show()
	return crop

func _arms_state() -> void:
	_spring_state("s_p19_end")
	Game.level = 74
	for id in Arms.ORDER:
		Game.arms[id] = true
	Game.arm_xp = {"sword": 96, "staff": 90, "sabre": 41, "spear": 22, "fan": 6, "bow": 37, "whip": 15, "brush": 2}
	Game.toasts.clear()

func _arms_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_arms_state()
	main.set_stack(["world"])
	main.world.clear_cache()
	main.world.load_area("sect", Vector2i(20, 9))
	main.world.banner_t = 0.0
	if want.call("faces"):
		# fourteen faces on four heads: the hero as a young man and as a young woman, Yue Ling, the Elder
		var makers := {
			"hero": func(): return Models.hero({"look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": false}),
			"hero_f": func(): return Models.hero({"look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": true}),
			"yue_ling": func(): return Assets.person("yue_ling"),
			"elder": func(): return Assets.person("elder_qing"),
		}
		for who in makers:
			var rows: Array = []
			rows.append(await _face_row(makers[who], Faces.ORDER.slice(0, 7), 1.6 if who != "elder" else 1.58))
			rows.append(await _face_row(makers[who], Faces.ORDER.slice(7, 14), 1.6 if who != "elder" else 1.58))
			_stack("faces_%s" % who, rows)
	if want.call("rack"):
		# the Eight Arms in the hand
		var sc := _bare_stage(480.0, 30.0, 9.0)
		var stage: Node3D = sc[0]
		var cam: Camera3D = sc[1]
		var hs: Array = []
		for i in Arms.ORDER.size():
			var id: String = Arms.ORDER[i]
			var h := Models.hero({"look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": i % 2 == 1, "arm": id})
			h.position = Vector3((i - 3.5) * 1.02, 0, 0)
			h.rotation.y = 0.5
			stage.add_child(h)
			h.add_child(Models.shadow_disc(0.6))
			_caption(stage, h.position + Vector3(0.0 if id != "spear" else 0.42, 2.02, 0), str(Arms.WEAPONS[id].zh).trim_prefix("the "), 0.0024)
			hs.append(h)
		cam.position = Vector3(0, 1.45, 9.7)
		cam.look_at(stage.global_position + Vector3(0, 1.12, 0), Vector3.UP)
		cam.make_current()
		for k in 30:
			for h2 in hs:
				Models.anim_person(h2, 1.6 + k / 30.0, false)
			await get_tree().process_frame
		await _shot("arms_rack")
		stage.queue_free()
		main.world.show()
	for kind in ["clip", "art"]:
		if not want.call("forms") and not want.call(kind):
			continue
		# each weapon's own blow (and the technique of its Dao), six moments of it from the side
		var rows2: Array = []
		for id2 in Arms.ORDER:
			if main.args.has("arm") and not str(main.args.arm).split(",").has(id2):
				continue
			var sc2 := _bare_stage(500.0, 30.0, 5.0)
			var stage2: Node3D = sc2[0]
			var cam2: Camera3D = sc2[1]
			var m := Models.hero({"look": "sweeper", "cols": {}, "outfit": "sweeper", "fem": false, "arm": id2})
			stage2.add_child(m)
			m.add_child(Models.shadow_disc(0.6))
			m.rotation.y = float(main.args.get("yaw", "1.1"))
			cam2.position = Vector3(0, 1.3, 6.4)
			cam2.look_at(stage2.global_position + Vector3(0, 1.0, 0), Vector3.UP)
			cam2.make_current()
			var ap: AnimationPlayer = m.get_meta("ap", null)
			var clip := str(Arms.WEAPONS[id2][kind])
			if ap == null or not ap.has_animation(clip):
				print("[tour] no clip ", clip)
				stage2.queue_free()
				continue
			var ln: float = ap.get_animation(clip).length
			Faces.wear(m, "shout")
			Arms.tick(m, 1.0, clip)
			ap.play(clip)
			var strip: Array = []
			var moments := [0.12, 0.3, 0.44, 0.54, 0.64, 0.84] if kind == "clip" else [0.14, 0.3, 0.46, 0.6, 0.72, 0.86]
			for f in moments:
				ap.seek(ln * float(f), true)
				Faces.tick(m, 0.2)
				await get_tree().process_frame
				await get_tree().process_frame
				await _shot("form", false)
				strip.append(last_img)
			var fw: int = strip[0].get_width()
			var fh: int = strip[0].get_height()
			var cw := int(fw * 0.42)
			var row := Image.create(cw * strip.size(), int(fh * 0.72), false, Image.FORMAT_RGB8)
			for i2 in strip.size():
				var im: Image = strip[i2]
				im.convert(Image.FORMAT_RGB8)
				row.blit_rect(im, Rect2i((fw - cw) / 2, int(fh * 0.2), cw, int(fh * 0.72)), Vector2i(i2 * cw, 0))
			row.resize(1920, int(row.get_height() * 1920.0 / row.get_width()), Image.INTERPOLATE_LANCZOS)
			if main.args.has("each"):
				row.save_webp("%s/arms_%s_%s.webp" % [dir, kind, id2], true, 0.9)
			rows2.append(row)
			stage2.queue_free()
			main.world.show()
		_stack("arms_blows" if kind == "clip" else "arms_arts", rows2)
	if want.call("people"):
		await _gallery("part21_people", [Assets.person("ou_yezi"), Assets.person("yue_maiden"), Assets.person("ji_chang"), Assets.person("zhuang_envoy"), Assets.person("king_zhao"), Assets.person("wuzhu")], 0.72, 0.2)
		var cast: Array = [Assets.person("ou_yezi"), Assets.person("yue_maiden"), Assets.person("ji_chang"), Assets.person("king_zhao")]
		var moods := ["resolve", "joy", "doubt", "sorrow"]
		for i in cast.size():
			Faces.wear(cast[i], moods[i])
		await _portraits("part21_faces", cast, 0.66, 1.68, 2.1)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["sword_reed", "white_gibbon", "hook_heron", "stray_arrow", "wheel_louse", "cup_snake", "gate_swordsman", "fighting_cock", "broken_edge", "pool_blade", "mound_tiger", "humming_sword"]:
			fs.append(_foe(fid))
		await _gallery("part21_foes", fs, 1.0, 0.25)
		await _gallery("part21_lords", [_foe("yuan_gong", true), _foe("sword_dragons", true), _foe("king_zhao", true), _foe("wuzhu", true)], 2.2, 0.25)
	if want.call("bosses"):
		var arms_for := {"yuan_gong": "staff", "sword_dragons": "spear", "king_zhao": "fan", "wuzhu": "sword"}
		for bid in arms_for:
			var ba := Trials.boss_area(bid)
			Game.arm = str(arms_for[bid])
			main.world.load_area(ba, MapGen.arrival_tiles(ba)[0] if not MapGen.arrival_tiles(ba).is_empty() else Vector2i(20, 20))
			main.battle.start([{"id": bid, "lv": 77}], {"boss": true, "enemy": bid, "theme": str(Data.AREAS[ba].theme)})
			main.push("battle")
			await _wait(2.8)
			await _shot("battle_boss_" + bid)
			main.pop()
		Game.arm = "sword"
	if want.call("battle"):
		# a blow with each of four weapons, in the middle of a battle
		for aid in ["spear", "staff", "bow", "whip"]:
			Game.arm = aid
			main.world.load_area("marsh", MapGen.arrival_tiles("marsh")[0])
			main.battle.start([{"id": "sword_reed", "lv": 75}, {"id": "white_gibbon", "lv": 75}, {"id": "hook_heron", "lv": 75}], {"theme": "marsh"})
			main.push("battle")
			await _wait(1.6)
			var b = main.battle
			for tries in 40:
				if b.state == "menu" and b.cur.get("idx", -1) == 0:
					break
				if b.state == "menu":
					b._perform(b.cur, "needle", [b.alive(b.foes)[0]])
				await _wait(0.3)
			if b.state == "menu":
				b._perform(b.cur, "strike", [b.alive(b.foes)[0]])
				await _wait(0.2 + float(main.args.get("blow-at", "0.22")))
				await _shot("battle_arm_" + aid)
			main.pop()
		Game.arm = "sword"
	if want.call("page"):
		main.world.load_area("sect", Vector2i(20, 9))
		main.world.banner_t = 0.0
		main.open_arms()
		main.choice.cursor = 3
		main.choice.preview.call("spear")
		await _wait(1.0)
		await _shot("arms_page")
		main.choice.cursor = 5
		main.choice.preview.call("bow")
		await _wait(0.8)
		await _shot("arms_page_bow")
		main.pop()
		main.world.preview_weapon("")
		Game.arm_xp["sabre"] = 15
		Game.trials = {}
		main.open_trial({"enemy": "king_zhao", "lv": 77, "req": 76, "id": "boss_king_zhao", "pos": Vector2i.ZERO})
		await _wait(0.8)
		await _shot("trial_by_the_hand")
		main.pop()
	if want.call("choice"):
		Game.step = Data.step_index("s_p21_racks")
		Game.cross_pending = ["the_arms"]
		main.ask_crossroads()
		main.choice.cursor = 2
		await _wait(1.0)
		await _shot("crossroads_arms")
		main.pop()
		Game.cross_pending = []
	if want.call("ends"):
		# the twelve ends as the choice shows them: a journey that earned most of them, and a dark one chosen
		_ending_state()
		Game.finished = false
		Game.hearth = {"valley": 12, "steppe": 10, "sand": 12, "river": 7, "forge": 4, "dawn": 12}
		Game.scales = {"heart": -4, "reach": 5, "craft": 4}
		Game.fates = {}
		for wid in Works.ORDER.slice(0, 10):
			Game.works[wid] = 1
		main.set_stack(["world"])
		main.choose_ending()
		main.choice.cursor = 5
		await _wait(1.0)
		await _shot("ending_choice_twelve")
		main.choice.cursor = 8
		await _wait(0.6)
		await _shot("ending_choice_dark")
		main.pop()
		for eid in ["throne", "school", "far"]:
			_ending_state()
			Game.ending = eid
			main.set_stack(["world"])
			main.push("ending")
			await _wait(1.0)
			var e = main.ending
			e.t = 4.0
			main.press("confirm")
			await _wait(3.5)
			await _shot("ending_" + eid)
			main.pop()
		Game.finished = false
		Game.ending = ""


# ---------------------------------------------------------------- the High Roads release
func _high_state() -> void:
	_arms_state()
	Game.seen = {}
	for id in Data.AREAS:
		Game.seen[id] = true
	Game.toasts.clear()

## The hero put on tile `tl` of the land facing `dir`, the camera behind.
func _high_put(tl: Vector2i, dir: Vector2i, hour: float) -> void:
	var w = main.world
	Game.clock = hour * 60.0
	w.teleport(tl, "surface")
	w.facing = dir
	w.cam_q = _quarter(Vector2(dir))
	w._snap_cam()
	w.banner_t = 0.0

## The High Roads (--high, or --high=a,b): a peak from its foot and from far off ("peaks", for the
## regions of --high-areas=a,b), the climb ("climb"), a summit ("summit"), the cloud-kite ("glide"),
## the clips ("clips").
func _high_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_high_state()
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	w.open_world()
	w.enter_layer("surface")
	var lw: Dictionary = Atlas.world_of("surface")
	var areas: PackedStringArray = str(main.args.get("high-areas", "mountain")).split(",", false)
	for area in areas:
		var pks := Peaks.of_area(lw, area)
		if pks.is_empty():
			continue
		var pk: Dictionary = pks[0]
		var c: Vector2i = pk.c
		var r: int = pk.r
		if want.call("peaks"):
			# from the open ground at its foot, wherever that is widest
			var best := c + Vector2i(0, r + 5)
			var bn := -1
			for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				var at: Vector2i = c + d * (r + 7)
				var n := 0
				for k in range(r, r + 12):
					if w.tile_free(c + d * k):
						n += 1
				if n > bn and w.tile_free(_nearest_free(at)):
					bn = n
					best = at
			var foot := _nearest_free(best)
			var to_c := Vector2(c - foot)
			var dir := Vector2i(int(signf(to_c.x)), 0) if absf(to_c.x) > absf(to_c.y) else Vector2i(0, int(signf(to_c.y)))
			# (at the hour that lights the side he is looking at: the sun is in the east before noon, in the
			# south at noon and in the west after it)
			var lit_hr := 12.5
			if absf(to_c.x) > absf(to_c.y):
				lit_hr = 15.6 if to_c.x > 0.0 else 8.6
			_high_put(foot, dir, lit_hr)
			await _wait(1.6)
			await _shot("peak_%s_foot" % area)
			var pp: Vector3 = w._player_pos()
			var mid: Vector3 = w.wpos(c) + Vector3(0, float(pk.h) * 0.45, 0)
			var back := (pp - mid)
			back.y = 0.0
			back = back.normalized()
			w.cam_override = Transform3D(Basis.IDENTITY, pp + back * 16.0 + Vector3(0, 9.0, 0)).looking_at(mid, Vector3.UP)
			await _wait(0.6)
			await _shot("peak_%s_far" % area)
			w.cam_override = null
		if want.call("climb"):
			# half way up its steepest side
			var dirs := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]
			var at2 := c
			var d2: Vector2i = dirs[0]
			var steep := 0.0
			for d in dirs:
				for k in range(2, r):
					var a: Vector2i = c + d * k
					var dz := Peaks.at(lw, a - d) - Peaks.at(lw, a)
					if dz > steep and Peaks.at(lw, a) > float(pk.h) * 0.3:
						steep = dz
						at2 = a
						d2 = d
			_high_put(at2 + d2, -d2, 12.5)
			w.climb = 1
			await _wait(0.9)
			await _shot("climb_%s" % area)
			# six moments of the climb itself, from beside and below (the bot's hand on the keys, so that
			# a direction stays held)
			var fwd := Vector3(-d2.x, 0, -d2.y)
			var side := fwd.cross(Vector3.UP)
			var frames: Array = []
			_high_put(at2 + d2 * 2, -d2, 12.5)
			await _wait(0.6)
			main.bot_active = true
			w.move_dir = -d2
			for i in 6:
				await _wait(0.22)
				var pp2: Vector3 = w._player_pos()
				w.cam_override = Transform3D(Basis.IDENTITY, pp2 - fwd * 4.4 - side * 2.6 + Vector3(0, 0.6, 0)).looking_at(pp2 + side * 0.7 + Vector3(0, 1.2, 0), Vector3.UP)
				await _shot("climb_%s_%d" % [area, i], false)
				frames.append(last_img)
			w.move_dir = Vector2i.ZERO
			main.bot_active = false
			_sheet("climb_%s_strip" % area, frames, 0.3)
			w.cam_override = null
			w.climb = 0
		if want.call("summit"):
			_high_put(c, Vector2i(0, 1), 17.6)
			await _wait(1.2)
			await _shot("summit_%s" % area)
		if want.call("glide"):
			_high_put(c, Vector2i(0, 1), 10.5)
			await _wait(0.8)
			w.toggle_glide()
			await _wait(0.75)
			await _shot("glide_%s" % area)
			var pp3: Vector3 = w._player_pos()
			var f3 := Vector3(w.facing.x, 0, w.facing.y)
			var s3 := f3.cross(Vector3.UP)
			w.cam_override = Transform3D(Basis.IDENTITY, pp3 + f3 * 5.2 + s3 * 4.4 + Vector3(0, 0.9, 0)).looking_at(pp3 + f3 * 1.2 + Vector3(0, 1.3, 0), Vector3.UP)
			await _shot("glide_%s_side" % area)
			w.cam_override = null
			await _wait(4.0)
			await _shot("glide_%s_landed" % area)
	if want.call("camp"):
		# a camp of the people of the road: at work in the morning, and round the fire after dark
		var ca: String = str(main.args.get("high-camp", "mountain"))
		if (lw.camps as Dictionary).has(ca):
			var heart: Vector2i = lw.camps[ca]
			for hr in [[18.9, "camp_%s_dusk"], [21.9, "camp_%s_night"]]:
				_high_put(_nearest_free(heart + Vector2i(0, 4)), Vector2i(0, -1), float(hr[0]))
				await _wait(2.5)
				var pp4: Vector3 = w._player_pos()
				var hc: Vector3 = w.wpos(heart)
				hc.y = pp4.y
				w.cam_override = Transform3D(Basis.IDENTITY, hc + Vector3(3.6, 3.0, 6.6)).looking_at(hc + Vector3(0, 0.9, -0.5), Vector3.UP)
				await _wait(1.0)
				await _shot(str(hr[1]) % ca)
				w.cam_override = null
			# each of them at their work, at ten in the morning (and the hermit and the pilgrim on the top)
			for fp in Folk.people(lw, "camp_" + ca):
				Game.clock = 10.0 * 60.0
				var st: Dictionary = Folk.state(lw, fp, Game.clock)
				if not st.vis:
					continue
				var ft := Vector2i(int(floor((st.at as Vector2).x)), int(floor((st.at as Vector2).y)))
				var stand := Vector2i(-1, -1)
				for d in [Vector2i(0, 3), Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, -3), Vector2i(2, 3), Vector2i(-2, 3), Vector2i(0, 2), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, -2)]:
					if w.tile_free(ft + d) and stand.x < 0:
						stand = ft + d
				if stand.x < 0:
					continue
				var dv := Vector2(ft - stand)
				_high_put(stand, Vector2i(int(signf(dv.x)), 0) if absf(dv.x) > absf(dv.y) else Vector2i(0, int(signf(dv.y))), 10.0)
				await _wait(2.4)
				var fpos: Vector3 = w.wpos(ft)
				fpos.y = w._player_pos().y + (Peaks.at(lw, ft) - Peaks.at(lw, stand))
				var hp: Vector3 = w._player_pos()
				var away := (hp - fpos)
				away.y = 0.0
				away = away.normalized()
				var sd := away.cross(Vector3.UP)
				w.cam_override = Transform3D(Basis.IDENTITY, fpos + away * 3.9 + sd * 0.9 + Vector3(0, 1.7, 0)).looking_at(fpos + Vector3(0, 1.0, 0), Vector3.UP)
				await _wait(0.8)
				await _shot("road_%s_%s" % [ca, str(fp.role)])
				w.cam_override = null
	if want.call("people"):
		await _gallery("part22_people", [Assets.person("xie_lingyun"), Assets.person("zhong_ziqi"), Assets.person("liezi"), Assets.person("han_yu"), Assets.person("shan_gui"), Assets.person("dongyue")], 0.74, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["salt_thief", "false_echo", "fire_crab", "stray_gust", "kite_hawk", "wind_bag", "red_leopard", "fig_creeper", "rain_gibbon", "merit_stele", "report_smoke", "bends_serpent"]:
			fs.append(_foe(fid))
		await _gallery("part22_foes", fs, 1.0, 0.25)
		await _gallery("part22_lords", [_foe("shanxiao", true), _foe("fei_lian", true), _foe("shan_gui", true), _foe("dongyue", true)], 2.2, 0.25)
	if want.call("bosses"):
		for bid in ["shanxiao", "fei_lian", "shan_gui", "dongyue"]:
			var ba := Trials.boss_area(bid)
			main.world.load_area(ba, MapGen.arrival_tiles(ba)[0] if not MapGen.arrival_tiles(ba).is_empty() else Vector2i(20, 20))
			main.battle.start([{"id": bid, "lv": 80}], {"boss": true, "enemy": bid, "theme": str(Data.AREAS[ba].theme)})
			main.push("battle")
			await _wait(2.8)
			await _shot("battle_boss_" + bid)
			main.set_stack(["world"])
	if want.call("page"):
		Game.level = 80
		Game.step = Data.step_index("s_p22_yue")
		Game.summits = {}
		for pk in (lw.peaks as Array).slice(0, 9):
			Game.summits[str(pk.id)] = true
		Game.trials = {}
		main.set_stack(["world"])
		main.open_trial({"enemy": "dongyue", "lv": 80, "req": 80, "id": "boss_dongyue", "pos": Vector2i.ZERO})
		await _wait(0.8)
		await _shot("trial_by_the_heights")
		main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.step = Data.step_index("s_p22_pilgrims")
		Game.cross_pending = ["the_tops"]
		main.ask_crossroads()
		main.choice.cursor = 0
		await _wait(1.0)
		await _shot("crossroads_tops")
		main.pop()
		Game.cross_pending = []
	if want.call("story"):
		# the lords of Part XXII where the story stands them: on the tops
		for sp in [["s_p22_xiao", "silk", 1, "shanxiao_on_the_height"], ["s_p22_yue", "mountain", 0, "dongyue_on_the_peak"], ["s_p22_lian", "thunder", 0, "liezi_and_the_earl"]]:
			Game.step = Data.step_index(str(sp[0]))
			var pk3: Dictionary = Peaks.by_id(lw, "peak:%s:%d" % [str(sp[1]), int(sp[2])])
			if pk3.is_empty():
				continue
			_high_put(pk3.c, Vector2i(0, -1), 9.0)
			await _wait(2.0)
			var p5: Vector3 = w._player_pos()
			w.cam_override = Transform3D(Basis.IDENTITY, p5 + Vector3(2.6, 2.6, 5.6)).looking_at(p5 + Vector3(-0.4, 1.2, -1.6), Vector3.UP)
			await _wait(0.8)
			await _shot(str(sp[3]))
			w.cam_override = null

## One foe of every shape the monsters come in (the first, not a lord, that Data.ENEMIES gives each),
## seven to a sheet, from a quarter in front and from the side: `prefix`_1 .. and `prefix`_side_1 ..
func _bestiary_shots(prefix: String = "1") -> void:
	var pre := "bestiary" if prefix == "1" else prefix
	var by_shape := {}
	for id in Data.ENEMIES:
		var sh := str(Data.ENEMIES[id].get("shape", ""))
		if sh == "" or sh.begins_with("person") or by_shape.has(sh) or bool(Data.ENEMIES[id].get("boss", false)):
			continue
		by_shape[sh] = id
	for id2 in Data.ENEMIES:
		var sh2 := str(Data.ENEMIES[id2].get("shape", ""))
		if sh2 != "" and not sh2.begins_with("person") and not by_shape.has(sh2):
			by_shape[sh2] = id2
	var shapes: Array = by_shape.keys()
	shapes.sort()
	var only: PackedStringArray = str(main.args.get("shapes", "")).split(",", false)
	if not only.is_empty():
		shapes = shapes.filter(func(x): return only.has(str(x)))
	var per := int(main.args.get("per", "6"))
	for i in range(0, shapes.size(), per):
		var row: Array = shapes.slice(i, i + per)
		print("[tour] sheet ", i / per + 1, ": ", row)
		for view in [["", 0.45], ["_side", 1.45]]:
			var ms: Array = []
			for sh3 in row:
				ms.append(_foe(str(by_shape[sh3]), bool(Data.ENEMIES[by_shape[sh3]].get("boss", false))))
			await _gallery("%s%s_%d" % [pre, str(view[0]), i / per + 1], ms, float(main.args.get("spacing", "1.9")), float(view[1]))


# ---------------------------------------------------------------- the Thundering Pots release
## A journey at the end of Part XXIII: the host raised, the airs learned, a good many feats done.
func _pots_state() -> void:
	_high_state()
	Game.level = 83
	Game.step = Data.step_index("s_p23_xiang")
	Game.companion = true
	Game.host = {}
	for cid in ["sect", "valley", "steppe", "sand", "river", "forge", "dawn"]:
		Game.host[cid] = true
	Game.works["crossbow"] = true
	Game.works["chariot"] = true
	Game.airs = {"valley": true, "steppe": true, "sand": true, "river": true, "forge": true}
	Game.heard = {}
	for tid in Music.ORDER.slice(0, 27):
		Game.heard[tid] = true
	Game.war_won = {"lishan": 7, "river": 5, "drill1": 3}
	Game.jobs = {"job_firewood": "done", "job_brine": "done", "job_tally": "done", "job_stage": "done", "job_letters": "taken"}
	Game.job_base = {"job_letters": {"v": float(Game.folk_talk.size())}}
	Game.outfits = {}
	for oid in Fashion.OUTFIT_ORDER.slice(0, 22):
		Game.outfits[oid] = true
	Game.worn = Game.outfits.duplicate()
	Game.yue_outfits = {}
	for yid in Fashion.YUE_ORDER.slice(0, 8):
		Game.yue_outfits[yid] = true
	Game.bond = 50
	Game.stones = 184000
	Game.kills = 4100
	Game.summits = {}
	for k in 12:
		Game.summits["s%d" % k] = true
	Game.glide_best = 52
	Game.glides = 14
	Game.eggs = {"old_code": 3600.0, "good_listener": 41000.0, "midnight_summit": 90000.0, "bell_nine": 12000.0}
	Game.feats = {}
	Game.playtime = 100800.0
	for fid in Feats.FEATS:
		if Feats.met(Game, fid):
			Game.feats[fid] = Game.playtime * (0.2 + 0.7 * Terrain3D.hash2(fid.length(), fid.hash() % 97, 3.0))
	Game.toasts.clear()

func _pots_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_pots_state()
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	if want.call("outfits"):
		# the fourteen new outfits, on a man's frame and a woman's, and Yue Ling's ten dresses
		var rows := [["rain", "exam", "newyear", "fur", "pilgrim", "swallow", "delver"], ["broom", "fox", "opera", "levy", "pipes", "marshal", "clay"]]
		for ri in rows.size():
			var outs: Array = []
			for oid in rows[ri]:
				Game.outfit = oid
				outs.append(Models.hero({"outfit": oid, "cols": Fashion.hero_colors(Game), "fem": ri == 1 and false}))
			await _gallery("outfits_new_%d" % (ri + 1), outs, 0.66)
		var fouts: Array = []
		for oid2 in ["rain", "exam", "fur", "swallow", "fox", "levy", "marshal"]:
			Game.outfit = oid2
			fouts.append(Models.hero({"outfit": oid2, "cols": Fashion.hero_colors(Game), "fem": true}))
		await _gallery("outfits_new_f", fouts, 0.66)
		Game.outfit = "sweeper"
		for yi in 2:
			var ys: Array = []
			for yid in Fashion.YUE_ORDER.slice(yi * 5, yi * 5 + 5):
				ys.append(Models.yue_ling({"outfit": yid}))
			await _gallery("yue_dresses_%d" % (yi + 1), ys, 0.66)
		await _portraits("outfits_new_faces", [Models.hero({"outfit": "exam", "cols": {}}), Models.hero({"outfit": "levy", "cols": {}}), Models.hero({"outfit": "opera", "cols": {}}), Models.yue_ling({"outfit": "plum"}), Models.yue_ling({"outfit": "moon"})], 0.8, 1.66, 2.1)
	if want.call("people"):
		await _gallery("part23_people", [Assets.person("ling_lun"), Assets.person("sun_wu"), Assets.person("fu_hao"), Assets.person("shi_kuang"), Assets.person("gao_jianli"), Assets.person("xiang_yu")], 0.76, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["pot_drummer", "flat_note", "kiln_wasp", "clay_spearman", "clay_archer", "clay_horse", "lead_string", "reed_pipe", "drowned_drum", "chu_halberd", "black_steed", "cauldron_breaker"]:
			fs.append(_foe(fid))
		await _gallery("part23_foes", fs, 1.0, 0.25)
		await _gallery("part23_lords", [_foe("meng_tian", true), _foe("gao_jianli", true), _foe("xiang_yu", true), _foe("wafu", true)], 2.2, 0.25)
		# the figures of the field, built from code: the levy's four arms and the clay host's three
		var figs: Array = []
		for fg in [["foot", Color("6a9a4a"), false], ["bow", Color("c8a050"), false], ["horse", Color("8a2a3a"), false], ["drum", Color("e87a2a"), false], ["foot", Color("b0785a"), true], ["bow", Color("b0785a"), true], ["horse", Color("b0785a"), true]]:
			var n3 := Node3D.new()
			MB.mesh_node(n3, load("res://scripts/field.gd").figure(str(fg[0]), fg[1], bool(fg[2])))
			n3.rotation.y = -PI / 2.0
			figs.append(n3)
		await _gallery("field_figures", figs, 1.3, 0.5)
	if want.call("bosses"):
		for bid in ["meng_tian", "gao_jianli", "xiang_yu", "wafu"]:
			var ba := Trials.boss_area(bid)
			main.world.load_area(ba, MapGen.arrival_tiles(ba)[0] if not MapGen.arrival_tiles(ba).is_empty() else Vector2i(20, 20))
			main.battle.start([{"id": bid, "lv": 83}], {"boss": true, "enemy": bid, "theme": str(Data.AREAS[ba].theme)})
			main.push("battle")
			await _wait(2.8)
			await _shot("battle_boss_" + bid)
			main.set_stack(["world"])
	if want.call("field"):
		# a field battle: the scouts' word and the orders; a volley in the air; the airs sounded; the end
		main.world.load_area("millet", MapGen.arrival_tiles("millet")[0])
		main.start_war("lishan", {})
		var f = main.field
		await _wait(0.4)
		await _shot("field_lishan_intro")
		f.state = "order"
		f.cursor = f.ids.find("hold")
		await _wait(0.6)
		await _shot("field_lishan_orders")
		f._give("volley")
		await _wait(f.RESOLVE * 0.5)
		await _shot("field_lishan_volley")
		await _wait(f.RESOLVE * 0.6)
		f._give("advance")
		await _wait(f.RESOLVE * 0.5)
		await _shot("field_lishan_advance")
		await _wait(f.RESOLVE * 0.6)
		f._give("charge")
		await _wait(f.RESOLVE * 0.45)
		await _shot("field_lishan_charge")
		await _wait(f.RESOLVE * 0.65)
		main.pop()
		main.world.load_area("dunes", MapGen.arrival_tiles("dunes")[0])
		Game.airs["dawn"] = true
		main.start_war("gaixia", {})
		f.state = "order"
		f._give("hold")
		await _wait(f.RESOLVE * 1.1)
		f._give("sound")
		await _wait(f.RESOLVE * 0.5)
		await _shot("field_gaixia_songs")
		await _wait(f.RESOLVE * 0.6)
		while str(f.st.over) == "":
			War.step(f.st, War.best(f.st))
		f._thin()
		f.state = "result"
		await _wait(0.8)
		await _shot("field_gaixia_held")
		main.pop()
		Game.war_won["gaixia"] = int(f.st.drum)
	if want.call("pages"):
		main.world.load_area("sect", Vector2i(20, 12))
		main.open_menu()
		main.menu.cursor = main.menu.ids.find("feats")
		await _wait(0.6)
		await _shot("menu_pots_root")
		for pg in [["feats", Feats.order().find("summits_nine"), "feats_page"], ["feats", Feats.order().size() + 2, "finds_page"], ["songs", Music.ORDER.find("valley"), "songs_page"], ["songs", Music.ORDER.find("war"), "songs_page_war"],
				["host", War.ORDER.find("steppe"), "host_page"]]:
			main.menu.mode = str(pg[0])
			main.menu._build()
			main.menu.cursor = int(pg[1])
			if str(pg[0]) == "songs":
				Music.ask(str(Music.ORDER[int(pg[1])]))
				main.menu.t = 9.0
			await _wait(0.6)
			await _shot(str(pg[2]))
		Music.ask("")
		main.pop()
	if want.call("town"):
		# the Drum Tower quarter of Qingshi: from above at nine in the morning, the street, the levy at
		# drill, the players, the notice board, the tailor's and Old Du's mat
		w.open_world()
		w.enter_layer("surface")
		# (--pots-town=a,b: only those of the town's shots)
		var tonly: PackedStringArray = str(main.args.get("pots-town", "")).split(",", false)
		for sh in [["quarter_above", Vector2i(79, 20), Vector3(-26.0, 30.0, 34.0), Vector3(0.0, 0.0, -2.0), 9.0], ["quarter_dusk", Vector2i(79, 20), Vector3(22.0, 30.0, 28.0), Vector3(0.0, 1.0, -3.0), 18.4],
				# (from high up only: a region is turned on the continent, so an offset in the world's axes that
				# is a street's length puts a low camera inside somebody's house)
				["qingshi_whole", Vector2i(52, 26), Vector3(-10.0, 78.0, 62.0), Vector3(4.0, 0.0, -4.0), 10.0]]:
			if not tonly.is_empty() and not tonly.has(str(sh[0])):
				continue
			var at: Vector2i = Atlas.to_world("village", sh[1])
			_high_put(Atlas.to_world("village", Vector2i(79, 19)), Vector2i(0, 1), float(sh[4]))
			await _wait(2.6)
			var c3: Vector3 = w.wpos(at)
			w.cam_override = Transform3D(Basis.IDENTITY, c3 + (sh[2] as Vector3)).looking_at(c3 + (sh[3] as Vector3), Vector3.UP)
			await _wait(1.0)
			await _shot(str(sh[0]))
			w.cam_override = null
		for sp in [["clerk_bai", "notice_board"], ["tailor_qiao", "tailor_shop"], ["dicer_du", "gamble_mat"]]:
			if not tonly.is_empty() and not tonly.has(str(sp[1])):
				continue
			var ne: Dictionary = {}
			for e in w.ents:
				if str(e.id) == str(sp[0]):
					ne = e
			if ne.is_empty():
				continue
			_high_put(ne.pos + Vector2i(0, 1), Vector2i(0, -1), 10.0)
			await _wait(2.0)
			if str(sp[0]) == "clerk_bai":
				main.offer_jobs(ne)
				main.choice.cursor = 2
			elif str(sp[0]) == "tailor_qiao":
				Game.outfits.erase("rain")
				Game.yue_outfits.erase("willow")
				main.offer_outfits({"id": "tailor_qiao", "n": "Tailor Qiao"})
			else:
				main.offer_gamble()
				main.choice.cursor = 2
			await _wait(0.9)
			await _shot(str(sp[1]))
			main.pop()
		main.set_stack(["world"])
	if want.call("body"):
		# survival and courtship: The Body's page a day and a half in, her page with the two of them
		# promised, and an hour together being chosen (in the sect's own courts: the steps)
		main.world.load_area("sect", Vector2i(20, 12))
		Needs.begin(Game)
		Game.needs = {"rest": 62.0, "hunger": 38.0, "thirst": 71.0, "bladder": 19.0, "bowels": 55.0, "comfort": 44.0, "clean": 67.0, "since": Game.day}
		Game.gourd = 3
		Game.inv["noodle_bowl"] = 1
		main.open_menu()
		main.menu.mode = "body"
		main.menu._build()
		main.menu.cursor = 6
		await _wait(0.6)
		await _shot("body_page")
		main.pop()
		main.set_stack(["world"])
		await _wait(0.4)
		await _shot("body_hud")
		Needs.end(Game)
		Game.romance = {"stage": 2, "gifts": {"haws": "love", "socks": "love", "ribbon": "like", "rouge": "meh", "needles": "love"}, "outings": {"tea": "quiet", "market": "playful", "lanterns": "tender", "water": "tender"},
			"tone": {"tender": 4, "playful": 2, "quiet": 1}}
		Game.future = "companion"
		Game.bond = 58
		main.open_menu()
		main.menu.mode = "yue"
		main.menu._build()
		main.menu.cursor = 2
		await _wait(0.6)
		await _shot("yue_courtship_page")
		main.pop()
		main.open_gifts()
		main.choice.cursor = Romance.GIFT_ORDER.find("kite")
		await _wait(0.6)
		await _shot("gifts_choice")
		main.pop()
		Game.clock = 10.0 * 60.0
		main.open_outings()
		main.choice.cursor = 0
		await _wait(0.6)
		await _shot("outings_choice")
		main.pop()
		main.say(Romance.OUTINGS.steps.lines)
		main.dialogue.shown = 999.0
		await _wait(1.2)
		await _shot("outing_steps")
		main.set_stack(["world"])
	if want.call("page"):
		Game.step = Data.step_index("s_p23_gao")
		Game.trials = {}
		main.set_stack(["world"])
		main.open_trial({"enemy": "gao_jianli", "lv": 83, "req": 82, "id": "boss_gao_jianli", "pos": Vector2i.ZERO})
		await _wait(0.8)
		await _shot("trial_by_the_song")
		main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.step = Data.step_index("s_p23_end")
		Game.cross_pending = ["the_host"]
		main.ask_crossroads()
		main.choice.cursor = 2
		await _wait(1.0)
		await _shot("crossroads_host")
		main.pop()
		Game.cross_pending = []


# ================================================================ the Lost Horse release
func _horse_state() -> void:
	_pots_state()
	Game.level = 86
	Game.step = Data.step_index("s_p24_marks")
	Game.picks = {}
	Game.scales = {}
	Game.falls = {}
	Game.fallen = 0
	Game.marks_seen = {}
	Game.toasts.clear()

## Put the party a little way off mark `id` of the land (on open ground beside it), at `hour`, and look
## down at the whole row of it from `dist` metres off and `up` metres above, from whichever quarter
## has open ground under the camera (a region is turned on the continent, and a wood may be anywhere).
func _mark_view(id: String, hour: float, dist: float, up: float) -> bool:
	var w = main.world
	var row: Array = []
	for e in Atlas.world_of("surface").ents:
		if str(e.id) == id or str(e.id).begins_with(id + ":"):
			row.append(e)
	if row.is_empty():
		return false
	var me: Dictionary = row[0]
	var at: Vector2i = me.pos
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		if w.tile_free(me.pos + d) and w.ent_at(me.pos + d) == null:
			at = me.pos + d
			break
	_high_put(at, me.pos - at if at != me.pos else Vector2i(0, 1), hour)
	await _wait(0.5)
	var c := Vector3.ZERO
	for e2 in row:
		c += w.wpos(e2.pos)
	c /= float(row.size())
	c.y = w.ground_y(c)
	var best := Vector2(-1, 1)
	var bs := -1
	for az in [Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]:
		# open ground all the way from the camera to the thing looked at
		var sc := 0
		for k in range(1, 9):
			var q: Vector2i = me.pos + Vector2i(roundi(az.normalized().x * dist * 0.5 * k / 6.0), roundi(az.normalized().y * dist * 0.5 * k / 6.0))
			# (a roof between the camera and the thing is no better than a wood)
			if q.x >= 0 and q.y >= 0 and q.x < int(w.w) and q.y < int(w.h) and int(w.grid[q.y * int(w.w) + q.x]) in [MapGen.FLOOR, MapGen.PATH, MapGen.DECOR]:
				sc += 1
		if sc > bs:
			bs = sc
			best = az
	var off := Vector3(best.normalized().x * dist, up, best.normalized().y * dist)
	w.cam_override = Transform3D(Basis.IDENTITY, c + off).looking_at(c + Vector3(0, 0.8, 0), Vector3.UP)
	await _wait(0.4)
	return true

## The Lost Horse (--horse, or --horse=a,b): the people ("people"), the foes, the dooms and the lords
## ("foes"), what stands as a row of models ("marks"), the same ground under each answer in the land
## ("world"), the battles that cannot be won ("battle"), the choice and the scene after ("choice"),
## and the pages ("page").
func _horse_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_horse_state()
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	if want.call("people"):
		await _gallery("part24_people", [Assets.person("sai_weng"), Assets.person("weng_son"), Assets.person("qian_liu")], 0.76, 0.2)
	if want.call("roads"):
		# the high road (roads.gd): the wagon on it between Cloudfoot and Longmen, and the map of the land
		main.world.load_area("sect", Vector2i(20, 9))
		var rl: Dictionary = Roads.of("surface").lines[0]
		var rk: int = (rl.pts as Array).size() / 2
		for k in range(8, (rl.pts as Array).size() - 8):
			# (a straight stretch, to stand the wagon along)
			if rl.pts[k + 4] - rl.pts[k - 4] == (rl.pts[k + 1] - rl.pts[k]) * 8:
				rk = k
				break
		Game.rides["wagon"] = true
		Game.ride = "wagon"
		Game.riding = true
		Game.companion = true
		for sa in Data.AREAS:
			Game.seen[sa] = true
		main.world.teleport(rl.pts[rk])
		main.world.facing = rl.pts[rk + 1] - rl.pts[rk]
		await _wait(2.0)
		var rpp: Vector3 = main.world.player.global_position
		var rdir := Vector3(main.world.facing.x, 0, main.world.facing.y)
		main.world.cam_override = Transform3D(Basis.IDENTITY, rpp - rdir * 9.0 + Vector3(rdir.z, 0, -rdir.x) * 4.5 + Vector3(0, 5.5, 0)).looking_at(rpp + rdir * 6.0 + Vector3(0, 0.8, 0), Vector3.UP)
		await _wait(0.6)
		await _shot("road_wagon")
		main.world.cam_override = null
		Game.riding = false
		main.open_menu()
		main.menu.mode = "map"
		main.menu._build()
		await _wait(0.5)
		await _shot("road_map")
		main.pop()
	if want.call("sea"):
		# the sea lanes (ships.gd): the junk at her mooring off Longmen, and the counter of the harbour
		main.world.load_area("longmen", Vector2i(28, 30))
		for sa2 in ["longmen", "yanggu", "penglai"]:
			Game.seen[sa2] = true
		var mo2 := Ships.mooring(Atlas.world_of("surface"), "longmen")
		print("[tour] mooring ", mo2, " quay ", Ships.quay("longmen"))
		main.world.teleport(Ships.quay("longmen"))
		await _wait(2.5)
		if mo2.x >= 0:
			var jp2: Vector3 = main.world.wpos(mo2)
			main.world.cam_override = Transform3D(Basis.IDENTITY, jp2 + Vector3(7.0, 17.0, 13.0)).looking_at(jp2 + Vector3(0, 3.0, 0), Vector3.UP)
			await _wait(0.8)
			await _shot("sea_junk")
			main.world.cam_override = null
		main.offer_carriage({"id": "harbour_longmen", "n": str(Offices.OFFICES.harbour_longmen.n), "office": "harbour_longmen"})
		await _wait(0.5)
		main.choice.cursor = 1 if "cursor" in main.choice else 0
		await _shot("sea_counter")
		main.pop()
	if want.call("fame"):
		# fame (fame.gd): the street behind somebody known everywhere, outside the Green Stone Inn of Qingshi
		Game.level = Data.MAX_LEVEL
		Game.riding = false
		for fb in Atlas.world_of("surface").buildings:
			if str(fb.area) == "village" and str(fb.id) == "inn":
				var fr: Rect2i = fb.rect
				var fd9: Vector2i = fb.door
				var fov := Vector2(fd9) - Vector2(fr.get_center())
				var fod := Vector2i(signi(int(fov.x)), 0) if absf(fov.x) / fr.size.x > absf(fov.y) / fr.size.y else Vector2i(0, signi(int(fov.y)))
				main.world.teleport(fd9 + fod * 4)
				main.world.facing = fod
				await _wait(2.0)
				# (the way he came: up the street to where he stands, so that they come up it behind him)
				var fpp: Vector3 = main.world.player.position
				var trail9: Array = []
				for k4 in 24:
					trail9.append(fpp - Vector3(fod.x, 0, fod.y) * (23 - k4) * 0.0 + Vector3(-fod.y, 0, fod.x) * (23 - k4) * 0.75)
				main.world.fan_trail = trail9
				await _wait(9.0)
				print("[tour] fans ", main.world.fans.size())
				await _shot("fame_street")
				break
	if want.call("windows"):
		# open windows (architecture.gd _wall): the Green Stone Inn of Qingshi from the street, the room seen through them
		var wsw: Dictionary = Atlas.world_of("surface")
		for wb in wsw.buildings:
			if str(wb.area) == "village" and str(wb.id) == "inn":
				var wr: Rect2i = wb.rect
				var wd9: Vector2i = wb.door
				var wc := Vector2(wr.get_center())
				var outv := (Vector2(wd9) - wc)
				var outd := Vector2i(signi(int(outv.x)), 0) if absf(outv.x) / wr.size.x > absf(outv.y) / wr.size.y else Vector2i(0, signi(int(outv.y)))
				main.world.teleport(wd9 + outd * 3)
				main.world.facing = -outd
				await _wait(2.5)
				var wp: Vector3 = main.world.wpos(wd9)
				var o3 := Vector3(outd.x, 0, outd.y)
				var side3 := Vector3(-outd.y, 0, outd.x)
				main.world.cam_override = Transform3D(Basis.IDENTITY, wp + o3 * 9.0 + side3 * 5.0 + Vector3(0, 2.6, 0)).looking_at(wp - o3 * 2.0 + side3 * 2.0 + Vector3(0, 2.0, 0), Vector3.UP)
				await _wait(0.8)
				await _shot("windows_inn")
				main.world.cam_override = null
				break
	if want.call("beasts"):
		# beasts with hides instead of paint (assets.gd NATURAL)
		var bs: Array = []
		for fid in ["bamboo_wolf", "thunder_ape", "wrack_crab", "mired_ox", "silt_ape"]:
			if Data.ENEMIES.has(fid):
				bs.append(_foe(fid))
		await _gallery("beasts_natural", bs, 1.5, 0.5)
	if want.call("shapes"):
		# one foe of every shape, three to a picture, close enough to look at
		var seen_shape := {}
		var row: Array = []
		var k9 := 0
		for fid in Data.ENEMIES:
			var sh := str(Data.ENEMIES[fid].shape)
			if seen_shape.has(sh):
				continue
			seen_shape[sh] = true
			row.append(_foe(fid))
			if row.size() == 3:
				await _gallery("shapes_%02d" % k9, row, 1.7, 0.5)
				row = []
				k9 += 1
		if not row.is_empty():
			await _gallery("shapes_%02d" % k9, row, 1.7, 0.5)
	if want.call("post"):
		# the post (mail.gd): the counter of Headman Luo with letters waiting and a bag to carry, and a letter being read
		main.world.load_area("sect", Vector2i(20, 9))
		Game.picks["bandits"] = "mend"
		Game.mail_read = {"ge_satchel": true}
		var luo := {"id": "head_qingshi", "n": str(Offices.OFFICES.head_qingshi.n), "office": "head_qingshi"}
		main.offer_carriage(luo)
		await _wait(0.5)
		await _shot("post_counter")
		main.pop()
		main.read_letter("bandits_mend")
		await _wait(0.8)
		await _shot("post_letter")
		main.pop()
		main.write_back("wen_first")
		await _wait(0.5)
		await _shot("post_reply")
		main.pop()
		Game.mail_read = {}
	if want.call("carriages"):
		var oxm := Assets.mount("ox", Assets.palette(Color("b4a290"), "", {"sec": Color("a83c30"), "acc": Color("3a2416"), "mark": Color("6a5a4c")}))
		oxm.rotation.y = PI / 2.0
		oxm.set_meta("kind", "ride_group")
		await _gallery("ox", [oxm], 1.5, 0.9)
		# the three carriages, every seat taken: the hero, Yue Ling, and whoever is being carried
		for rid in ["ox_cart", "wagon", "carriage"]:
			var r: Dictionary = Fashion.RIDES[rid]
			var holder := Node3D.new()
			var rn := Models.ride(rid)
			holder.add_child(rn)
			Models.anim_ride(rn, 0.3, false)
			var bodies := ["", "yue_ling", "folk_scholar", "folk_maiden", "folk_youth", "folk_scholar"]
			for i in (r.seats as Array).size():
				var pm: Node3D = Models.person(Color("3a6ac8"), Color("202030"), {"asset": "lin_feng"}) if i == 0 else Models.person(Color("888888"), Color("222222"), {"asset": bodies[i]})
				pm.position = Vector3(r.seats[i]) - Vector3(0, 0.46, 0)
				holder.add_child(pm)
				Assets.lend_clips(pm)
				for k in 8:
					Assets.animate(pm, k * 0.2, "sit_bench", 0.0)
				var pap: AnimationPlayer = pm.get_meta("ap", null)
				if pap != null and pap.has_animation("sit_bench"):
					pm.set_meta("pose_ap", pap)
			holder.rotation.y = PI / 2.0
			holder.set_meta("kind", "ride_group")
			_seat_all.call_deferred(holder)
			await _gallery("carriage_" + rid, [holder], 4.4, 0.9)
		# and on the road: the wagon with every seat taken, below the sect's north gate
		main.world.load_area("sect", Vector2i(20, 9))
		Game.rides["wagon"] = true
		Game.ride = "wagon"
		Game.riding = true
		Game.companion = true
		Game.passengers = [{"id": "a", "n": "Lodger Wu", "asset": "folk_merchant", "to": "dunes", "pay": 300}, {"id": "b", "n": "Lodger Hu", "asset": "folk_shopwife", "to": "dunes", "pay": 300},
			{"id": "c", "n": "Lodger Ma", "asset": "folk_youth", "to": "tushan", "pay": 300}, {"id": "d", "n": "Lodger An", "asset": "folk_porter", "to": "tushan", "pay": 300}]
		main.world.teleport(Atlas.to_world("mountain", Vector2i(82, 48)))
		main.world.facing = Vector2i(1, 0)
		await _wait(1.5)
		await _shot("carriage_road")
		Game.passengers = []
		Game.riding = false
	if want.call("foes"):
		var fs: Array = []
		for fid in ["slipped_halter", "burr_sprite", "hoof_echo", "wrack_crab", "salt_gull", "drift_log", "silt_ape", "weir_eel", "mired_ox", "outrider", "remount", "camp_hound"]:
			fs.append(_foe(fid))
		await _gallery("part24_foes", fs, 1.0, 0.25)
		await _gallery("part24_dooms", [_foe("spring_colt"), _foe("tide_horse"), _foe("tide_mare"), _foe("wuzhiqi", true), _foe("the_riders", true)], 2.0, 0.25)
		await _gallery("part24_lords", [_foe("hu_steed", true), _foe("huofu", true)], 2.2, 0.25)
	if want.call("marks"):
		# what stands, as the game builds it: each crossroads' answers side by side
		var rows := [["marks_part1", [["bandits", "mend"], ["bandits", "drive"], ["palace", "seal"], ["palace", "open"], ["widow", "truth"], ["widow", "kind"]]],
			["marks_makers", [["drawings", "keep"], ["the_wheel", "hours"], ["the_wheel", "down"], ["furnace", "return"], ["the_player", "keep"], ["the_lute", "melt"], ["the_host", "band"]]],
			["marks_tide", [["the_tide", "wall"], ["the_tide", "yield"], ["the_tide", "arrows"]]],
			["marks_ape", [["the_ape", "chain"], ["the_ape", "dredge"], ["the_ape", "boats"]]],
			["marks_horse", [["the_horse", "keep"], ["the_horse", "loose"], ["the_horse", "breed"]]]]
		for rw in rows:
			var ms: Array = []
			for pr in rw[1]:
				ms.append(Marks.model(Marks.MARKS[pr[0]][pr[1]], 0))
			await _gallery(str(rw[0]), ms, 1.5, 0.3)
		var sg: Array = []
		for sc in Echoes.SCALE_ORDER:
			for l in [1, -1]:
				var sm := Marks.model(Marks.SIGNS[sc][l], 0)
				Machines.animate(sm, 1.3)
				sg.append(sm)
		await _gallery("marks_signs", sg, 1.5, 0.3)
	if want.call("world"):
		# the same ground under each answer: the shore at Yanggu, the Drowned Fields, the frontier, and
		# two of the oldest crossroads
		w.open_world()
		w.enter_layer("surface")
		# (--horse-world=a,b: only those crossroads)
		var wonly: PackedStringArray = str(main.args.get("horse-world", "")).split(",", false)
		for sh in [["the_tide", "yanggu", ["wall", "yield", "arrows"], [17.0, 11.0], 10.0], ["the_ape", "drowned", ["chain", "dredge", "boats"], [15.0, 10.0], 15.0],
				["the_horse", "aurora", ["keep", "loose", "breed"], [8.0, 4.5], 17.0], ["bandits", "bamboo", ["mend", "drive"], [13.0, 8.0], 9.0],
				["palace", "palace", ["seal", "open"], [8.0, 4.5], 19.0], ["the_clay", "millet", ["stand", "kiln"], [12.0, 7.0], 16.0]]:
			if not wonly.is_empty() and not wonly.has(str(sh[0])):
				continue
			var frames: Array = []
			for oid in sh[2]:
				Game.picks = {str(sh[0]): str(oid)}
				if not await _mark_view("mark:%s:%s" % [str(sh[0]), str(sh[1])], float(sh[4]), float(sh[3][0]), float(sh[3][1])):
					continue
				await _shot("mark_%s_%s" % [str(sh[0]).trim_prefix("the_"), str(oid)])
				frames.append(last_img)
				w.cam_override = null
			_sheet("mark_%s_answers" % str(sh[0]).trim_prefix("the_"), frames, 0.62 if frames.size() == 2 else 0.48)
		# and what the scales stand in a region: mercy and rigour on the same spot, the new works and the old ways
		for sv in [["heart", 6, "sign_mercy"], ["heart", -6, "sign_rigour"], ["craft", 6, "sign_new_works"], ["craft", -6, "sign_old_ways"], ["reach", 6, "sign_wide_world"], ["reach", -6, "sign_home_fire"]]:
			Game.picks = {}
			Game.scales = {str(sv[0]): int(sv[1])}
			if not wonly.is_empty() and not wonly.has("signs"):
				continue
			if await _mark_view("sign:bamboo:%s" % str(sv[0]), 10.0, 7.0, 3.6):
				await _shot(str(sv[2]))
				w.cam_override = null
		Game.scales = {}
		# somebody who is only there for one answer
		Game.picks = {"bandits": "mend"}
		if (wonly.is_empty() or wonly.has("who")) and await _mark_view("who:bandits:mend", 9.5, 5.5, 2.8):
			await _shot("mark_who_road_mender")
			w.cam_override = null
		Game.picks = {}
	if want.call("houses"):
		# houses that are not boxes: the ones with wings built out from them, and the tall ones, in three towns
		w.open_world()
		w.enter_layer("surface")
		for hv in [["village", 4], ["mountain", 3], ["longmen", 3], ["yanggu", 3], ["tushan", 2]]:
			var shown := 0
			for bd in Atlas.world_of("surface").buildings:
				if str(bd.area) != str(hv[0]) or shown >= int(hv[1]) or (bd.get("wings", []) as Array).is_empty():
					continue
				var rr: Rect2i = bd.rect
				var door: Vector2i = bd.door
				var outv := Vector2i(-1 if door.x == rr.position.x else (1 if door.x == rr.end.x - 1 else 0), -1 if door.y == rr.position.y else (1 if door.y == rr.end.y - 1 else 0))
				_high_put(door + outv * 2, -outv, 10.0)
				await _wait(0.5)
				var c: Vector3 = w.wpos(rr.position + rr.size / 2)
				c.y = w.ground_y(w.wpos(door + outv * 2))
				var wsd: Vector2i = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)][int(bd.wings[0].side)]
				var dirv := (Vector3(outv.x, 0, outv.y) * 0.8 + Vector3(wsd.x, 0, wsd.y)).normalized()
				w.cam_override = Transform3D(Basis.IDENTITY, c + dirv * 9.0 + Vector3(0, 40.0, 0)).looking_at(c + Vector3(0, 2.0, 0), Vector3.UP)
				await _wait(0.4)
				await _shot("house_%s_%s" % [str(hv[0]), str(bd.id)])
				w.cam_override = null
				shown += 1
	if want.call("battle"):
		main.set_stack(["world"])
		Game.level = 85
		main.battle.start([{"id": "tide_horse", "lv": 85}, {"id": "tide_mare", "lv": 85}, {"id": "spring_colt", "lv": 85}], {"entity": {"id": "tour:tide", "group": []}, "boss": false, "theme": "yanggu"})
		main.push("battle")
		await _wait(3.4)
		await _shot("battle_doom_tide")
		main.battle.round_no = 3
		main.battle.acts = {"blows": 6, "mends": 1}
		main.battle._fall(false)
		await _wait(1.0)
		await _shot("battle_doom_overwhelmed")
		main.pop()
		Game.level = 86
		main.battle.start([{"id": "wuzhiqi", "lv": 86}], {"entity": {"id": "boss_wuzhiqi"}, "boss": true, "enemy": "wuzhiqi", "theme": "drowned"})
		main.push("battle")
		await _wait(3.6)
		await _shot("battle_boss_wuzhiqi")
		main.pop()
		main.battle.start([{"id": "the_riders", "lv": 87}], {"entity": {"id": "boss_the_riders"}, "boss": true, "enemy": "the_riders", "theme": "aurora"})
		main.push("battle")
		await _wait(3.6)
		await _shot("battle_boss_the_riders")
		main.pop()
		for bid in ["hu_steed", "huofu"]:
			var bm: Array = Trials.TRIALS[bid].might
			main.battle.start([{"id": bid, "lv": 86, "mult": float(bm[0]), "atk": float(bm[1])}], {"entity": {"id": "boss_" + bid}, "boss": true, "enemy": bid, "theme": "aurora" if bid == "hu_steed" else "yanggu",
				"trial": bid, "path": "loss", "boon": Trials.path(bid, "loss").boon, "path_n": str(Trials.path(bid, "loss").n), "path_kind": str(Trials.KINDS.loss.n)})
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		main.say(Data.DIALOGUE["fall:wuzhiqi"] + Data.DIALOGUE["fall:wuzhiqi:gave"])
		main.dialogue.shown = 999.0
		await _wait(1.2)
		await _shot("fall_wuzhiqi")
		main.set_stack(["world"])
		for cc in [["the_tide", "s_p24_wrack", 1, "crossroads_tide"], ["the_ape", "s_p24_lost", 1, "crossroads_ape"], ["the_horse", "s_p24_end", 0, "crossroads_horse"]]:
			Game.step = Data.step_index(str(cc[1]))
			Game.picks = {}
			Game.cross_pending = [str(cc[0])]
			main.ask_crossroads()
			main.choice.cursor = int(cc[2])
			await _wait(1.0)
			await _shot(str(cc[3]))
			main.pop()
			Game.cross_pending = []
	if want.call("page"):
		Game.step = Data.step_index("s_p24_twin")
		Game.trials = {}
		Game.fallen = 5
		Game.marks_seen = {"a": true, "b": true, "c": true, "d": true}
		main.set_stack(["world"])
		main.open_trial({"enemy": "huofu", "lv": 87, "req": 86, "id": "boss_huofu", "pos": Vector2i.ZERO})
		await _wait(0.8)
		await _shot("trial_by_the_loss")
		main.pop()
	get_tree().quit(0)


# ================================================================ the Three Burrows release
func _burrows_state() -> void:
	_horse_state()
	Game.level = 89
	Game.step = Data.step_index("s_p25_marks")
	Game.picks = {}
	Game.scales = {}
	Game.hold = {}
	Game.stones = 96000
	# (nothing is news while the pictures are taken)
	for fid in Feats.FEATS:
		Game.feats[fid] = true
	Game.toasts.clear()
	main.toast_list.clear()

## The town built as far as `n` plots, with `fam` families asked to come.
func _burrows_town(n: int, fam: int) -> void:
	Game.hold = {"built": {}, "settlers": {}, "day0": int(Game.day), "taken": int(Game.day) - 3}
	for k in mini(n, Hold.ORDER.size()):
		Game.hold.built[Hold.ORDER[k]] = true
	for k2 in fam:
		Game.hold.settlers["t%d" % k2] = "A family"

## Look down on Guiyun from `dist` metres south of its middle and `up` metres above, at `hour`.
func _burrows_view(hour: float, dist: float, up: float, side: float = 0.0) -> void:
	var w = main.world
	_high_put(Atlas.to_world(Hold.AREA, Hold.tile(Vector2i(5, 8))), Vector2i(0, -1), hour)
	await _wait(0.6)
	var c: Vector3 = w.wpos(Atlas.to_world(Hold.AREA, Hold.tile(Vector2i(5, 4))))
	c.y = w.ground_y(c)
	w.cam_override = Transform3D(Basis.IDENTITY, c + Vector3(side, up, dist)).looking_at(c + Vector3(0, 0.6, 0), Vector3.UP)
	await _wait(0.5)

## The Three Burrows (--burrows, or --burrows=a,b): the people ("people"), the foes and the lords
## ("foes"), the plots as models ("plots"), what the three crossroads leave standing ("marks"), the
## town in the land as it grows ("world"), the lords' battles ("battle"), the crossroads and the
## steward's table ("choice"), and the pages ("page").
func _burrows_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	if want.call("people"):
		await _gallery("part25_people", [Assets.person("feng_xuan"), Assets.person("tai_widow"), Assets.person("han_song")], 0.76, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["granary_rat", "seed_sparrow", "thatch_moth", "writ_wasp", "tally_crow", "corvee_ox", "cock_crower", "dog_thief", "gate_crasher", "pine_swordsman", "needle_sprite", "frost_crane"]:
			fs.append(_foe(fid))
		await _gallery("part25_foes", fs, 1.0, 0.25)
		await _gallery("part25_lords", [_foe("shuo_shu", true), _foe("ke_zheng", true), _foe("han_song", true)], 2.2, 0.25)
	if want.call("plots"):
		for half in [["hold_plots_1", Hold.ORDER.slice(0, 6), 1], ["hold_plots_2", Hold.ORDER.slice(6), 3]]:
			var ms: Array = []
			for pid in half[1]:
				var pm := Hold.model(str(pid), int(half[2]), "found")
				Machines.animate(pm, 0.9)
				ms.append(pm)
			await _gallery(str(half[0]), ms, 1.8, 0.3)
		var rk: Array = []
		for r in [1, 2, 3]:
			rk.append(Hold.model("homes2", r, ""))
		for r2 in [1, 2, 3]:
			rk.append(Hold.model("hall", r2, ["", "serve", "found"][r2 - 1]))
		await _gallery("hold_ranks", rk, 1.9, 0.3)
	if want.call("marks"):
		for rw in [["marks_tallies", [["the_tallies", "burn"], ["the_tallies", "collect"], ["the_tallies", "shares"]]],
				["marks_door", [["the_door", "all"], ["the_door", "hearth"], ["the_door", "sweep"]]],
				["marks_seat", [["the_seat", "found"], ["the_seat", "take"], ["the_seat", "serve"]]]]:
			var mm: Array = []
			for pr in rw[1]:
				var m1 := Marks.model(Marks.MARKS[pr[0]][pr[1]], 0)
				Machines.animate(m1, 1.3)
				mm.append(m1)
			await _gallery(str(rw[0]), mm, 1.7, 0.3)
	if want.call("world"):
		w.open_world()
		w.enter_layer("surface")
		var frames: Array = []
		# the ground before the town, a hamlet, a town and a city, from the same place
		for st in [[0, 0, "s_p25_home", "guiyun_ground"], [4, 3, "s_p25_marks", "guiyun_hamlet"], [8, 9, "s_p25_marks", "guiyun_town"], [12, 16, "s_p25_marks", "guiyun_city"]]:
			Game.step = Data.step_index(str(st[2]))
			Game.picks = {} if int(st[0]) < 12 else {"the_tallies": "burn", "the_door": "all", "the_seat": "found"}
			_burrows_town(int(st[0]), int(st[1]))
			if int(st[0]) == 0:
				Game.hold = {}
			await _burrows_view(10.5, 16.0, 12.0)
			await _wait(0.8)
			await _shot(str(st[3]))
			frames.append(last_img)
			w.cam_override = null
		_grid("guiyun_grows", frames, 2)
		# the city from the street, in the evening, and from high above
		await _burrows_view(18.4, 5.2, 2.8, 2.4)
		await _shot("guiyun_street")
		w.cam_override = null
		await _burrows_view(9.0, 26.0, 22.0)
		await _shot("guiyun_above")
		w.cam_override = null
		# what the three answers left standing beside it
		for sh in [["the_tallies", ["burn", "collect", "shares"], 9.0, 5.0], ["the_door", ["all", "hearth", "sweep"], 13.0, 7.5], ["the_seat", ["found", "serve"], 9.0, 5.0]]:
			var fr: Array = []
			for oid in sh[1]:
				Game.picks = {str(sh[0]): str(oid)}
				if not await _mark_view("mark:%s:mountain" % str(sh[0]), 16.0, float(sh[2]), float(sh[3])):
					continue
				await _shot("mark_%s_%s" % [str(sh[0]).trim_prefix("the_"), str(oid)])
				fr.append(last_img)
				w.cam_override = null
			_sheet("mark_%s_answers" % str(sh[0]).trim_prefix("the_"), fr, 0.62 if fr.size() == 2 else 0.48)
		Game.picks = {}
	if want.call("battle"):
		main.set_stack(["world"])
		for bb in [["shuo_shu", "ninesprings", "relic"], ["ke_zheng", "tea", "town"], ["han_song", "frost", "town"]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might
			var pth: Dictionary = Trials.path(bid, str(bb[2]))
			main.battle.start([{"id": bid, "lv": 89, "mult": float(bm[0]), "atk": float(bm[1])}], {"entity": {"id": "boss_" + bid}, "boss": true, "enemy": bid, "theme": str(bb[1]),
				"trial": bid, "path": str(bb[2]), "boon": pth.boon, "path_n": str(pth.n), "path_kind": str(Trials.KINDS[str(pth.kind)].n)})
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		_burrows_town(8, 9)
		for cc in [["the_tallies", "s_p25_town", 0, "crossroads_tallies"], ["the_door", "s_p25_herbs", 0, "crossroads_door"], ["the_seat", "s_p25_hermits", 0, "crossroads_seat"]]:
			Game.step = Data.step_index(str(cc[1]))
			Game.picks = {}
			Game.cross_pending = [str(cc[0])]
			main.ask_crossroads()
			main.choice.cursor = int(cc[2])
			await _wait(1.0)
			await _shot(str(cc[3]))
			main.pop()
			Game.cross_pending = []
		# the steward's table: what is in the chest, and what is drawn up
		Game.step = Data.step_index("s_p25_city")
		main.set_stack(["world"])
		main.offer_hold({"id": Hold.STEWARD, "n": "Feng Xuan"})
		main.choice.cursor = 2
		await _wait(1.0)
		await _shot("hold_table")
		main.pop()
		# somebody of the road asked to come
		main.set_stack(["world"])
		main.offer_home({"id": "tour:pedlar", "n": "Pedlar Yuan", "role": "pedlar", "kid": false})
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("hold_ask_home")
		main.pop()
		# and the ends the town opens
		_burrows_town(12, 16)
		Game.picks = {"the_tallies": "burn", "the_door": "all", "the_seat": "found"}
		Game.step = Data.STEPS.size() - 1
		main.set_stack(["world"])
		main.choose_ending()
		var ek: int = main.choice.ids().find("founder")
		main.choice.cursor = maxi(ek, 0)
		await _wait(1.0)
		await _shot("ending_choice_founder")
		main.pop()
	if want.call("page"):
		_burrows_town(9, 12)
		Game.picks = {"the_tallies": "shares", "the_door": "sweep"}
		Game.step = Data.step_index("s_p25_city")
		main.set_stack(["world"])
		main.open_menu()
		main.menu.mode = "town"
		main.menu.cursor = 4
		main.menu._build()
		await _wait(0.8)
		await _shot("town_page")
		main.menu.cursor = Hold.ORDER.size()
		await _wait(0.4)
		await _shot("town_page_all")
		main.pop()
		Game.step = Data.step_index("s_p25_han")
		_burrows_town(12, 16)
		Game.trials = {}
		main.set_stack(["world"])
		main.open_trial({"enemy": "han_song", "lv": 90, "req": 89, "id": "boss_han_song", "pos": Vector2i.ZERO})
		await _wait(0.8)
		await _shot("trial_by_the_town")
		main.pop()
	get_tree().quit(0)

## The Five Frolics (--frolics, or --frolics=a,b): the people of Part XXVI ("people"), the cast dressed
## and in their underclothes ("bare"), the chapter's foes and lords ("foes"), the lords' battles
## ("battle"), the crossroads and the wardrobe ("choice"), what each answer of the crossroads leaves
## standing ("marks"), and a soak in the hot springs of Glowcap Vale ("soak").
func _frolics_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 92
	Game.step = Data.step_index("s_p26_marks")
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	if want.call("people"):
		await _gallery("part26_people", [Assets.person("hua_tuo"), Assets.person("wu_pu"), Assets.person("pao_ding"), Assets.person("jailer_wife")], 0.5, 0.2)
	if want.call("bare"):
		# six of the people of the land, three at a time, dressed and then down to their underclothes
		var frames: Array = []
		for trio in [["disciple_han", "disciple_mei", "elder_qing"], ["batu", "auntie_rong", "child_hua"]]:
			for bare in [false, true]:
				var ms: Array = []
				for pid in trio:
					var m: Node3D = Assets.person(str(pid))
					if bare:
						Models.undress(m, true)
					ms.append(m)
				await _gallery("cast_%s_%s" % [str(trio[0]), "bare" if bare else "dressed"], ms, 0.42, 0.15)
				frames.append(last_img)
		_grid("cast_dressed_and_bare", frames, 2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["rust_beetle", "still_toad", "idle_spore", "gristle_hound", "locked_joint", "hacking_butcher", "tiger_guard", "headache_crow", "sleepless_drum"]:
			fs.append(_foe(fid))
		await _gallery("part26_foes", fs, 1.0, 0.25)
		await _gallery("part26_lords", [_foe("duke_huan", true), _foe("quan_niu", true), _foe("cao_cao", true)], 1.05, 0.25)
	if want.call("battle"):
		main.set_stack(["world"])
		for bb in [["duke_huan", "fungal", "relic"], ["quan_niu", "tushan", "arms"], ["cao_cao", "millet", "host"]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might
			var pth: Dictionary = Trials.path(bid, str(bb[2]))
			main.battle.start([{"id": bid, "lv": 92, "mult": float(bm[0]), "atk": float(bm[1])}], {"entity": {"id": "boss_" + bid}, "boss": true, "enemy": bid, "theme": str(bb[1]),
				"trial": bid, "path": str(bb[2]), "boon": pth.boon, "path_n": str(pth.n), "path_kind": str(Trials.KINDS[str(pth.kind)].n)})
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.step = Data.step_index("s_p26_herbs")
		Game.picks = {}
		Game.cross_pending = ["the_book"]
		main.ask_crossroads()
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("crossroads_book")
		main.pop()
		Game.cross_pending = []
		# the wardrobe, with the cursor on the underclothes and the hero in them
		main.set_stack(["world"])
		main.world.teleport(Atlas.to_world("sect", Vector2i(20, 12)))
		main.world.facing = Vector2i(0, 1)
		await _wait(0.6)
		main.open_wardrobe()
		main.choice.cursor = Fashion.OUTFIT_ORDER.size()
		main.choice._show()
		await _wait(0.8)
		await _shot("wardrobe_underclothes")
		main.choice.press("cancel")
		Game.step = Data.step_index("s_p26_marks")
	if want.call("marks"):
		# what each answer of the crossroads leaves standing, each in its own country
		var fr: Array = []
		for oa in [["copy", "village"], ["keep", "mountain"], ["burn", "millet"]]:
			Game.picks = {"the_book": str(oa[0])}
			main.set_stack(["world"])
			if not await _mark_view("mark:the_book:%s" % str(oa[1]), 15.0, 9.0, 5.0):
				continue
			await _shot("mark_book_%s" % str(oa[0]))
			fr.append(last_img)
			w.cam_override = null
		_sheet("mark_book_answers", fr, 0.48)
		Game.picks = {}
	if want.call("soak"):
		# Lin Feng and Yue Ling in the hot springs of Glowcap Vale, in their underclothes
		main.set_stack(["world"])
		var spring = null
		for e in Atlas.world_of("surface").ents:
			if e.kind == "prop" and str(e.get("prop", "")) == "hot_spring" and str(e.get("area", "")) == "fungal":
				spring = e
				break
		if spring != null:
			Game.companion = true
			_high_put(spring.pos + Vector2i(0, 1), Vector2i(0, -1), 17.5)
			await _wait(0.8)
			w.start_scene_use(spring)
			await _wait(3.0)
			var c: Vector3 = w.wpos(spring.pos)
			c.y = w.ground_y(c)
			# (from the open side it is come up to, a little above: the screen of the spring is behind it)
			var fd: Vector2i = spring.get("face", Vector2i(0, 1))
			var out := Vector3(fd.x, 0.0, fd.y)
			var side := Vector3(-out.z, 0.0, out.x)
			w.cam_override = Transform3D(Basis.IDENTITY, c + out * 3.1 + side * 1.2 + Vector3(0, 2.3, 0)).looking_at(c + Vector3(0, 0.3, 0), Vector3.UP)
			await _wait(0.6)
			await _shot("soak_fungal")
			w.cam_override = null
			w.end_use()
			await _wait(1.0)
	get_tree().quit(0)

## A showroom shot like _gallery, of people each held on a clip of their own at a moment of it
## (`poses`: [clip, seconds into it]), seen from `yaw` round them (the Heavy Road release).
func _pose_gallery(n: String, models: Array, poses: Array, spacing: float, yaw: float = 0.5) -> void:
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
		m.rotation.y = yaw
		stage.add_child(m)
		m.add_child(Models.shadow_disc(0.8))
	var span := models.size() * w
	cam.position = Vector3(0, 1.7 + spacing * 0.6, span * 0.8 + 1.5)
	cam.look_at(stage.global_position + Vector3(0, 1.05 + spacing * 0.25, 0), Vector3.UP)
	cam.make_current()
	for k in 6:
		await get_tree().process_frame
	for i2 in models.size():
		var m2: Node3D = models[i2]
		var ap: AnimationPlayer = m2.get_meta("ap") if m2.has_meta("ap") else null
		if ap != null and ap.has_animation(str(poses[i2][0])):
			ap.play(str(poses[i2][0]), 0.0)
			ap.seek(float(poses[i2][1]), true)
			ap.pause()
	for k2 in 4:
		await get_tree().process_frame
	await _shot(n)
	stage.queue_free()
	main.world.show()
	if main.world.cam != null:
		main.world.cam.make_current()

## The Heavy Road (--heavy, or --heavy=a,b): the loads on a back ("loads"), the clips of the work of
## the hands ("clips"), the work done out in the land ("work"), walking under timber ("haul"), the page
## of the load ("page"), the people, foes and lords of Part XXVII ("people", "foes"), the lords'
## battles ("battle"), the crossroads ("choice") and what each answer leaves standing ("marks").
func _heavy_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 95
	Game.step = Data.step_index("s_p27_sack")
	Game.companion = true
	for tl in ["axe", "fishing_rod", "pick", "sickle"]:
		Game.inv[tl] = 1
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	if want.call("loads"):
		# what a load looks like: the six kinds on Lin Feng's back, and Yue Ling with her share
		var ms: Array = []
		var poses: Array = []
		for bk in ["pack", "logs", "stone", "sacks", "fish", "herbs"]:
			var m: Node3D = Models.hero({"glow": w.HERO_OPTS.glow})
			Burden.wear(m, bk, 1.1)
			ms.append(m)
			poses.append(["haul_idle", 0.4])
		var y: Node3D = Models.yue_ling({})
		Burden.wear(y, "basket", 1.0)
		ms.append(y)
		poses.append(["haul_idle", 1.2])
		await _pose_gallery("loads_on_the_back", ms, poses, 0.42, 2.5)
		var ms2: Array = []
		var poses2: Array = []
		for bk2 in ["logs", "stone", "sacks"]:
			var m3: Node3D = Models.hero({"glow": w.HERO_OPTS.glow})
			Burden.wear(m3, bk2, 1.5)
			ms2.append(m3)
			poses2.append(["haul", 0.3 + 0.25 * ms2.size()])
		await _pose_gallery("loads_walking", ms2, poses2, 0.5, 1.2)
	if want.call("clips"):
		# the clips of the work of the hands, each at the moment of the blow, with its tool
		var cm: Array = []
		var cp: Array = []
		for cw in [["fell", 0.82, "felling_axe"], ["quarry", 0.7, "pickaxe"], ["reap", 0.75, "sickle"], ["angle", 3.9, "rod"]]:
			var m4: Node3D = Models.hero({"glow": w.HERO_OPTS.glow, "arm": ""})
			w._hold_in_hand(m4, str(cw[2]))
			cm.append(m4)
			cp.append([str(cw[0]), float(cw[1])])
		await _pose_gallery("clips_of_the_hands", cm, cp, 0.6, 0.9)
		var cm2: Array = []
		var cp2: Array = []
		for cw2 in [["fell", 0.5, "felling_axe"], ["quarry", 0.5, "pickaxe"], ["reap", 0.3, "sickle"], ["angle", 0.4, "rod"]]:
			var m5: Node3D = Models.hero({"glow": w.HERO_OPTS.glow, "arm": ""})
			w._hold_in_hand(m5, str(cw2[2]))
			cm2.append(m5)
			cp2.append([str(cw2[0]), float(cw2[1])])
		await _pose_gallery("clips_of_the_hands_back", cm2, cp2, 0.6, 0.9)
	if want.call("people"):
		await _gallery("part27_people", [Assets.person("tao_kan"), Assets.person("charcoal_seller"), Assets.person("zhichang"), Assets.person("budai")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["ease_moth", "sedan_shade", "waste_golem", "yellow_runner", "white_shirt", "gauze_ox", "loose_scroll", "ivory_tag", "book_worm", "clenched_fist", "old_grudge", "heirloom_crab"]:
			fs.append(_foe(fid))
		await _gallery("part27_foes", fs, 1.0, 0.25)
		await _gallery("part27_lords", [_foe("palace_buyer", true), _foe("wan_juan", true), _foe("li_jing", true)], 1.05, 0.25)
	if want.call("work") or want.call("haul"):
		# out in the land: the nearest piece of a region that can be worked at each way, and the work done
		var ws: Dictionary = Atlas.world_of("surface")
		var reach := MapGen.flood(ws.grid, ws.w, ws.h, ws.start)
		var fr: Array = []
		for wk in [["fell", "silk"], ["quarry", "volcano"], ["reap", "karst"], ["angle", "maple"]]:
			if not want.call("work"):
				break
			var arr: Vector2i = Atlas.to_world(str(wk[1]), MapGen.arrival_tiles(str(wk[1]))[0])
			var best := Vector2i(-1, -1)
			var bdir := Vector2i.ZERO
			var bd := 1 << 30
			for oy in range(-70, 71):
				for ox in range(-70, 71):
					var t := arr + Vector2i(ox, oy)
					var dd: int = absi(ox) + absi(oy)
					if dd >= bd or not reach.has(t) or Atlas.owner_id(ws, t) != str(wk[1]):
						continue
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						if Toil.work_at(ws, t, t + d) == str(wk[0]) and reach.has(t - d) and reach.has(t - d * 2):
							best = t
							bdir = d
							bd = dd
			if best.x < 0:
				continue
			Game.inv["timber"] = 0
			Game.toiled = {}
			# (he is alone at it: Yue Ling would stand between him and the camera)
			Game.companion = false
			_high_put(best, bdir, 10.5)
			await _wait(0.5)
			Game.toasts.clear()
			main.toast_list.clear()
			w.work()
			var wkd: Dictionary = Toil.WORKS[str(wk[0])]
			await _wait(w.USE_STEP + float(w.FX_AT[str(wkd.clip)]) + 0.12)
			var pp: Vector3 = w.player.position
			var fw := Vector3(bdir.x, 0.0, bdir.y)
			var sd := Vector3(-fw.z, 0.0, fw.x)
			w.cam_override = Transform3D(Basis.IDENTITY, pp - fw * 1.2 + sd * 4.2 + Vector3(0, 1.7, 0)).looking_at(pp + fw * 0.7 + Vector3(0, 1.05, 0), Vector3.UP)
			await _wait(0.05)
			Game.toasts.clear()
			main.toast_list.clear()
			await _shot("work_%s" % str(wk[0]))
			fr.append(last_img)
			w.cam_override = null
			# (the rest of the work is not waited for: the picture is taken)
			w.using.dur = 0.1
			await _wait(1.2)
			Game.toasts.clear()
			main.toast_list.clear()
		_grid("work_of_the_hands", fr, 2)
		if want.call("haul"):
			# walking under five stems of timber, Yue Ling with her share behind
			var arr2: Vector2i = Atlas.to_world("silk", MapGen.arrival_tiles("silk")[0])
			Game.inv["timber"] = 6
			Game.companion = true
			Game.riding = false
			_high_put(arr2, Vector2i(1, 0), 16.5)
			await _wait(0.8)
			var go := Vector2i(1, 0)
			for d2 in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var ok := true
				for k in range(1, 9):
					ok = ok and w.tile_free(arr2 + d2 * k)
				if ok:
					go = d2
					break
			main.bot_active = true
			w.move_dir = go
			await _wait(1.9)
			var pp2: Vector3 = w._player_pos()
			var fw2 := Vector3(go.x, 0.0, go.y)
			var sd2 := Vector3(-fw2.z, 0.0, fw2.x)
			w.cam_override = Transform3D(Basis.IDENTITY, pp2 + fw2 * 3.4 + sd2 * 3.0 + Vector3(0, 1.7, 0)).looking_at(pp2 - fw2 * 0.4 + Vector3(0, 1.1, 0), Vector3.UP)
			Game.toasts.clear()
			main.toast_list.clear()
			await _wait(0.12)
			await _shot("haul_timber")
			w.move_dir = Vector2i.ZERO
			main.bot_active = false
			w.cam_override = null
			await _wait(0.6)
			var pp3: Vector3 = w._player_pos()
			w.cam_override = Transform3D(Basis.IDENTITY, pp3 + fw2 * 3.6 - sd2 * 2.4 + Vector3(0, 1.6, 0)).looking_at(pp3 - fw2 * 0.3 + Vector3(0, 1.1, 0), Vector3.UP)
			await _wait(0.3)
			await _shot("haul_standing")
			w.cam_override = null
	if want.call("page"):
		main.set_stack(["world"])
		Game.inv["timber"] = 4
		Game.inv["carp"] = 3
		Game.inv["herb_bundle"] = 2
		Game.inv["pack_frame"] = 1
		Game.hauled = 1240.0
		main.open_menu()
		main.menu.mode = "load"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.6)
		await _shot("load_page")
		main.pop()
		Game.inv["timber"] = 0
	if want.call("battle"):
		main.set_stack(["world"])
		for bb in [["palace_buyer", "volcano", "relic"], ["wan_juan", "karst", "relic"], ["li_jing", "maple", "relic"]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might
			var pth: Dictionary = Trials.path(bid, str(bb[2]))
			main.battle.start([{"id": bid, "lv": 95, "mult": float(bm[0]), "atk": float(bm[1])}], {"entity": {"id": "boss_" + bid}, "boss": true, "enemy": bid, "theme": str(bb[1]),
				"trial": bid, "path": str(bb[2]), "boon": pth.boon, "path_n": str(pth.n), "path_kind": str(Trials.KINDS[str(pth.kind)].n)})
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_sack"]
		main.ask_crossroads()
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("crossroads_sack")
		main.pop()
		Game.cross_pending = []
	if want.call("marks"):
		var fr2: Array = []
		for oa in [["carry", "maple"], ["share", "silk"], ["down", "bamboo"]]:
			Game.picks = {"the_sack": str(oa[0])}
			main.set_stack(["world"])
			if not await _mark_view("mark:the_sack:%s" % str(oa[1]), 15.0, 9.0, 5.0):
				continue
			await _shot("mark_sack_%s" % str(oa[0]))
			fr2.append(last_img)
			w.cam_override = null
		_sheet("mark_sack_answers", fr2, 0.48)
		Game.picks = {}
	get_tree().quit(0)


## The Answering Land (--answer, or --answer=a,b): "clips" (the work of the towns), "people", "foes", "towns" (a
## street of Qingshi festive at dusk, afraid, and cold, and a door of each), "page" (Esc > The Land), "battle",
## "choice", "marks".
func _answer_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 98
	Game.step = Data.step_index("s_p28_knot")
	Game.companion = true
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	if want.call("clips"):
		for row in [["work_of_the_towns_1", [["serve", 2.3, "tray"], ["knead", 0.6, ""], ["weigh", 1.6, "steelyard"], ["arrange", 0.9, ""], ["sew", 1.4, "needle"]]],
				["work_of_the_towns_2", [["scrub", 3.3, "cloth"], ["wring", 1.0, "cloth"], ["fan", 0.4, "fan"], ["stalk", 2.6, ""], ["flay", 0.7, "knife"]]]]:
			var cm: Array = []
			var cp: Array = []
			var bodies := ["folk_maiden", "folk_cook", "folk_merchant", "folk_shopwife", "folk_grandma", "folk_porter", "folk_farmwife", "folk_cook", "folk_guard", "folk_fisher"]
			for cw in row[1]:
				var fp := {"body": bodies[(cm.size() + (5 if str(row[0]).ends_with("2") else 0)) % bodies.size()], "dye": []}
				var m4: Node3D = Folk.model(fp)
				if str(cw[2]) != "":
					w._hold_in_hand(m4, str(cw[2]), Folk.hand_of(str(cw[2])))
				if str(cw[0]) == "scrub":
					Models.undress(m4, true)
				cm.append(m4)
				cp.append([str(cw[0]), float(cw[1])])
			await _pose_gallery(str(row[0]), cm, cp, 0.6, 0.6)
	if want.call("people"):
		await _gallery("part28_people", [Assets.person("wei_ke"), Assets.person("grass_elder"), Assets.person("yang_bao"), Assets.person("zhou_chu")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["trip_grass", "qin_footman", "field_dust", "nest_robber", "owl_shadow", "forgetful_fox", "white_brow", "hill_roar", "bridge_eel", "early_drum"]:
			fs.append(_foe(fid))
		await _gallery("part28_foes", fs, 1.0, 0.25)
		await _gallery("part28_lords", [_foe("du_hui", true), _foe("night_owl", true), _foe("bridge_jiao", true), _foe("zhou_chu", true)], 1.05, 0.25)
	if want.call("towns"):
		# one street, three ways: what Qingshi looks like festive at dusk, afraid, and cold to him
		var ws: Dictionary = Atlas.world_of("surface")
		var heart: Vector2i = Folk.heart("qingshi")
		var door := Vector2i(-1, -1)
		var out_d := Vector2i(0, 1)
		var bdist := 1 << 30
		for bd in ws.buildings:
			if str(bd.get("area", "")) != "village" or not str(bd.get("style", "house")) in ["house", "shop", "inn", "teahouse", "farmhouse"]:
				continue
			var r: Rect2i = bd.rect
			var dd: Vector2i = bd.door
			var od := Vector2i(0, 1)
			if dd.y >= r.end.y - 1:
				od = Vector2i(0, 1)
			elif dd.y <= r.position.y:
				od = Vector2i(0, -1)
			elif dd.x >= r.end.x - 1:
				od = Vector2i(1, 0)
			else:
				od = Vector2i(-1, 0)
			var dist: int = absi(dd.x - heart.x) + absi(dd.y - heart.y)
			if od == Vector2i(0, 1) and dist < bdist and w.tile_free(dd + od * 2):
				bdist = dist
				door = dd
				out_d = od
		var fr: Array = []
		var fr2: Array = []
		var placed := false
		# (in the order of the day: the clock is only ever put forward)
		for st in [["thriving", 10.0], ["lean", 10.2], ["cold", 10.4], ["afraid", 18.6], ["festive", 19.2]]:
			Game.weal = {}
			Game.picks = {}
			Game.boss_done = {}
			match str(st[0]):
				"festive":
					Game.weal_force = {}
					Game.weal = {"qingshi|gift": 3, "qingshi|shift": 4, "qingshi|fare": 4, "qingshi|bag": 4, "qingshi|errand": 12, "kills|village": 200, "kills|bamboo": 200}
					Game.war_won = {"a": 3, "b": 3}
				"thriving":
					Game.weal = {"qingshi|gift": 3, "qingshi|shift": 4, "qingshi|errand": 8}
					Game.war_won = {}
				"afraid":
					Game.weal = {}
					Game.war_won = {}
					Game.weal_force = {"qingshi": "afraid"}
				"lean":
					Game.weal_force = {"qingshi": "lean"}
				"cold":
					Game.weal_force = {}
					Game.weal = {"qingshi|broke": 9}
			Game.weal_n += 1
			Game.toasts.clear()
			main.toast_list.clear()
			if door.x < 0:
				continue
			# (he stands once, two tiles out from one door, for all five: only the hour and the town change)
			if not placed:
				_high_put(door + out_d * 2, -out_d, float(st[1]))
				placed = true
				await _wait(0.6)

			Game.clock = float(st[1]) * 60.0
			w._weal_t = 0.0
			# (a town is slow to draw without a graphics card: a few frames are enough for the doors to be hung)
			await _wait(0.4)
			var dp: Vector3 = Terrain3D.world_pos(door)
			dp.y = w._player_pos().y
			var fw := Vector3(out_d.x, 0.0, out_d.y)
			w.cam_override = Transform3D(Basis.IDENTITY, dp + fw * 5.2 + Vector3(1.4, 2.2, 0)).looking_at(dp + Vector3(0, 1.7, 0), Vector3.UP)
			Game.toasts.clear()
			main.toast_list.clear()
			await _wait(0.1)
			await _shot("door_%s" % str(st[0]), false)
			print("[tour] (door ", st[0], ")")
			fr2.append(last_img)
			if str(st[0]) in ["festive", "afraid", "cold"]:
				# the street from above and behind him
				w.cam_override = Transform3D(Basis.IDENTITY, dp + fw * 15.0 + Vector3(7.0, 9.5, 0)).looking_at(dp + fw * 2.0 + Vector3(0, 1.2, 0), Vector3.UP)
				await _wait(0.1)
				await _shot("town_%s" % str(st[0]))
				fr.append(last_img)
			w.cam_override = null
		Game.weal_force = {}
		_sheet("towns_three_ways", fr, 0.5)
		_sheet("doors_by_state", fr2, 0.36)
	if want.call("page"):
		main.set_stack(["world"])
		Game.weal_force = {}
		Game.war_lost = 0
		Game.picks = {"bandits": "mend", "drawings": "keep", "the_wheel": "hours", "dragon_boon": "sea", "the_tide": "wall", "the_sack": "share", "garden": "study", "widow": "kind", "cauldron_map": "copy"}
		Game.weal = {"qingshi|gift": 2, "qingshi|shift": 4, "qingshi|errand": 8, "yanggu|broke": 8, "longmen|bag": 4, "kills|village": 170}
		Game.weal_n += 1
		main.open_menu()
		main.menu.mode = "land"
		main.menu.cursor = 2
		main.menu._build()
		await _wait(0.6)
		await _shot("land_page")
		main.pop()
	if want.call("battle"):
		main.set_stack(["world"])
		for bb in [["du_hui", "fusang", "relic"], ["night_owl", "bamboo", "relic"], ["bridge_jiao", "mirror", "relic"], ["zhou_chu", "mirror", "towns"]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might
			var pth: Dictionary = Trials.path(bid, str(bb[2]))
			main.battle.start([{"id": bid, "lv": 98, "mult": float(bm[0]), "atk": float(bm[1])}], {"entity": {"id": "boss_" + bid}, "boss": true, "enemy": bid, "theme": str(bb[1]),
				"trial": bid, "path": str(bb[2]), "boon": pth.boon, "path_n": str(pth.n), "path_kind": str(Trials.KINDS[str(pth.kind)].n)})
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_knot"]
		main.ask_crossroads()
		main.choice.cursor = 2
		await _wait(1.0)
		await _shot("crossroads_knot")
		main.pop()
		Game.cross_pending = []
	if want.call("marks"):
		var fr3: Array = []
		for oa in [["nothing", "fusang"], ["ledger", "village"], ["onward", "bamboo"]]:
			Game.picks = {"the_knot": str(oa[0])}
			main.set_stack(["world"])
			if not await _mark_view("mark:the_knot:%s" % str(oa[1]), 15.0, 9.0, 5.0):
				continue
			await _shot("mark_knot_%s" % str(oa[0]), false)
			fr3.append(last_img)
			w.cam_override = null
		_sheet("mark_knot_answers", fr3, 0.48)
		Game.picks = {}
	get_tree().quit(0)
