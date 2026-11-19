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
	if main.args.has("wits"):
		# the Iron Pestle release (--wits, or --wits=a,b): what the people of the towns work for, people
		# who know the way, and foes that fight as what they are
		await _wits_shots(str(main.args.wits))
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
	if main.args.has("ordered"):
		# the Ordered House release (--ordered, or --ordered=a,b): the people, foes and lords of Part XXIX, the pages
		# of the Way and the almanac, a house with things set down in it and what can be done at its furniture, a
		# pack grown old, the chapter's lords, its crossroads and what each answer leaves standing
		await _ordered_shots(str(main.args.ordered))
	if main.args.has("net"):
		# the Open Net release (--net, or --net=a,b): the people, foes and lords of Part XXX, the pages of the law
		# and the wild, a sword drawn on somebody and the mound afterwards, the watch, the forbidden shelf, a
		# country in balance and barren, a barren pack, the watch and the lords in battle, the crossroads and
		# what each answer leaves standing
		await _net_shots(str(main.args.net))
	if main.args.has("mirror"):
		# the Broken Mirror release (--mirror, or --mirror=a,b): the re-sculpted bodies from the front and from
		# behind, the cast dressed and bare, the three things two people do, the people, foes and lords of
		# Part XXXII, the lords in battle, the crossroads, and Yue Ling's page
		await _mirror_shots(str(main.args.mirror))
	if main.args.has("pestle"):
		# the Iron Pestle release (--pestle, or --pestle=a,b): the people, foes and lords of Part XXXIII, what each
		# answer of its crossroads leaves standing, the lords in battle, and the crossroads
		await _pestle_shots(str(main.args.pestle))
	if main.args.has("lakes"):
		# the Rivers and Lakes release (--lakes, or --lakes=a,b): the four towns of the sects, upright and crooked,
		# the ten vehicles, traffic on the high road, a raid on a cart and on a camp, the hall of tasks, the page of
		# the sects, the river-boat's landing, the map of the sixth realm, and Part XLI
		await _lakes_shots(str(main.args.lakes))
	if main.args.has("knife"):
		# the Unblunted Knife release (--knife, or --knife=a,b): the chart of the channels, the bench of each craft,
		# a place of peace on a summit, at the back of a cave and in a pavilion, a beast asked to stay and at his
		# heel, the pages, and Part XLIII
		await _knife_shots(str(main.args.knife))
	if main.args.has("turned"):
		# the Turned Face release (--turned, or --turned=a,b): the three new bodies and the foes of Part XLIV, the old
		# toads, centipede and owls on bodies of their own kind, each new body's art in battle, the page of his good
		# name well and ill thought of, a battle made harder by it, the crossroads and what it leaves standing
		await _turned_shots(str(main.args.turned))
	if main.args.has("deeps"):
		# the Sea Floor release (--deeps, or --deeps=a,b): the three towns under the sea, the six works at their
		# stations, the places of the sea floor, the ground shaped by the Dao of Leading Water, the way down at
		# the Returning Ruins, the page and the map of the seventh realm, and Part XLII
		await _deeps_shots(str(main.args.deeps))
	if main.args.has("roads"):
		# the Two Roads release (--roads, or --roads=a,b): the table of leaves in both games, the counter that keeps
		# one, the page of leaves, a stele offering a second road, the page of the Daos, a fuller street, and Part XL
		await _roads_shots(str(main.args.roads))
	if main.args.has("seal"):
		# the Red Seal release (--seal, or --seal=a,b): the desk of the Hall of Seals and a paper sealed, the page of
		# papers, a board of the lists, bouts and what is said in them, an auction room, the post, and Part XXXIX
		await _seal_shots(str(main.args.seal))
	if main.args.has("sky"):
		# the Higher Sky release (--sky, or --sky=a,b): those above him where they stand, the choice in front of
		# one, a bout and how it ends, the pages in their own words, and Part XXXVIII
		await _sky_shots(str(main.args.sky))
	if main.args.has("hands"):
		# the Five Hands release (--hands, or --hands=a,b): hands on what they hold, before and after; the five
		# phases turned on a wood, one after another; what hangs from a hand; and Part XXXVII
		await _hands_shots(str(main.args.hands))
	if main.args.has("fish"):
		# the Small Fish release (--fish, or --fish=a,b): a meal cooked stage by stage, the land out of his own
		# eyes, a blow at each weight, a vein in a cave wall, picking and digging, and Part XXXVI
		await _fish_shots(str(main.args.fish))
	if main.args.has("block"):
		# the Uncarved Block release (--block, or --block=a,b): the seventeen rites of the Daos, the page of the
		# root, the street answering a root and a road, and Part XXXV
		await _block_shots(str(main.args.block))
	if main.args.has("road"):
		# the Unpicked Road release: small things, how the street answers, a leap, Part XXXIV
		await _road_shots(str(main.args.road))
	if main.args.has("tall"):
		# the Tall People release (--tall, or --tall=a,b): the Great People beside a man, the eight gestures of a
		# close-up, the nine faces of the Way, the people, foes and lords of Part XXXI, a town with giants in its
		# streets, a giant at a door, a conversation cut to a close-up, the lords in battle, the crossroads and
		# what each answer leaves standing
		await _tall_shots(str(main.args.tall))
	if main.args.has("keel"):
		# the Cloud Keel release (--keel, or --keel=a,b): an ark at her mooring and under way, the arks over
		# Cloudfoot and Lightfoot, the counter that sells a passage, the four Far Countries and their two
		# towns, a storey divided into apartments with the people who live in them, and what the audit mended
		await _keel_shots(str(main.args.keel))
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
		# (at dusk and after, when the lanterns are lit and the street is nearly empty: a town at noon, with
		# thirty people in it, takes a software renderer minutes a frame.  The clock is only ever put forward.)
		for st in [["festive", 19.2], ["thriving", 21.7], ["afraid", 21.8], ["lean", 21.9], ["cold", 22.0]]:
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
			if str(st[0]) in ["festive"]:
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

## The Ordered House (--ordered, or --ordered=a,b): "people", "foes", "things" (the seven things of a house),
## "pages" (Esc > The Way, The Almanac), "house" (things set down in a house of Qingshi, and the choice at a piece
## of its furniture), "battle" (a pack grown old, and the four lords), "choice", "marks".
func _ordered_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 101
	Game.step = Data.step_index("s_p29_mat")
	Game.companion = true
	Game.day = 143
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	if want.call("people"):
		await _gallery("part29_people", [Assets.person("the_guest"), Assets.person("ding_lingwei"), Assets.person("guan_ning"), Assets.person("hua_xin")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["stray_spark", "smoke_tongue", "wood_stack", "lost_year", "wall_townsman", "mound_moss", "furrow_glint", "half_mat", "carriage_dust", "gate_gawker"]:
			fs.append(_foe(fid))
		await _gallery("part29_foes", fs, 1.0, 0.25)
		await _gallery("part29_lords", [_foe("chimney_fire", true), _foe("old_wall", true), _foe("furrow_gold", true), _foe("hua_xin", true)], 1.05, 0.25)
	if want.call("things"):
		var ts: Array = []
		for tid in Fitting.ORDER:
			var tm: Node3D = Fitting.model(tid)
			tm.scale = Vector3.ONE * 1.6
			ts.append(tm)
		await _gallery("things_of_a_house", ts, 0.62, 0.3)
	if want.call("pages"):
		main.set_stack(["world"])
		Game.picks = {"bandits": "mend", "widow": "kind", "the_mat": "whole"}
		Game.scales = {"heart": 7, "craft": 1, "reach": -4}
		Game.creed = {"virtue": 8}
		Game.fitted = {"village:inn": 140, "village:study": 141, "village:tofu_shop": 141}
		Game.weal = {"qingshi|gift": 3, "yanggu|gift": 2, "qingshi|errand": 6, "qingshi|shift": 4, "longmen|bag": 2}
		Game.shifts = {"shop": 4}
		Game.bags_done = 2
		Game.stipends = 4
		Game.gamble_rounds = 6
		Game.smashed = 3
		main.open_menu()
		main.menu.mode = "way"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.6)
		await _shot("way_page")
		main.menu.mode = "almanac"
		main.menu._build()
		for pe in Atlas.world_of("surface").ents:
			if str(pe.kind) == "enemy" and str(pe.get("area", "")) in ["village", "bamboo", "marsh", "mountain"]:
				Game.pack_day[str(pe.id)] = 143.0 - float(absi(hash(str(pe.id))) % 7)
		await _wait(0.4)
		await _shot("almanac_page")
		main.pop()
		Game.pack_day = {}
	if want.call("house"):
		main.set_stack(["world"])
		var ws: Dictionary = Atlas.world_of("surface")
		Game.fitted = {}
		Game.placed = {}
		var fw: Dictionary = {}
		for cand in Fitting.wants_in(Game, ws, "village"):
			if str(cand.kind) in ["table", "desk", "stove"]:
				fw = cand
				break
		if not fw.is_empty():
			var hk := str(fw.house)
			var furn: Dictionary = Fitting._index(ws).houses[hk].furn
			var fe: Dictionary = furn[int(str(fw.spot).get_slice(":", 3))]
			# what the house wanted, where it wanted it, and two things more where they do and do not belong
			Game.placed[str(fw.spot)] = "%s|1" % str(fw.thing)
			for k in furn:
				var oe: Dictionary = furn[k]
				if str(oe.id) == str(fw.spot):
					continue
				for tid2 in Fitting.ORDER:
					if Fitting.verdict(tid2, str(oe.furn)) != 0 and not Game.placed.has(str(oe.id)) and Game.placed.size() < 4 and not Game.placed.values().has("%s|%d" % [tid2, Fitting.verdict(tid2, str(oe.furn))]):
						Game.placed[str(oe.id)] = "%s|%d" % [tid2, Fitting.verdict(tid2, str(oe.furn))]
			var at := Vector2i(-1, -1)
			var dir := Vector2i(0, 1)
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				var q: Vector2i = fe.pos + d
				if MapGen.is_walkable_tile(ws.grid[q.y * int(ws.w) + q.x]):
					at = q
					dir = -d
			if at.x >= 0:
				Game.clock = 10.0 * 60.0
				w.teleport(at)
				w.facing = dir
				w.placed_changed()
				await _wait(1.5)
				await _shot("house_set_down")
				Game.placed.erase(str(fw.spot))
				Game.inv[str(fw.thing)] = 1
				Game.inv["house_broom"] = 1
				w.placed_changed()
				main.offer_fit(fe)
				await _wait(0.8)
				await _shot("fit_choice")
				main.pop()
		Game.placed = {}
		w.placed_changed()
	if want.call("battle"):
		main.set_stack(["world"])
		var grp: Array = Almanac.grown_at([{"id": "stray_spark", "lv": 99}, {"id": "wood_stack", "lv": 99}], 3)
		main.battle.start(grp, {"entity": {"id": "t:old"}, "boss": false, "theme": "marsh", "habit": "", "group": grp, "grown": 3})
		main.push("battle")
		await _wait(3.2)
		await _shot("battle_pack_grown_old")
		main.pop()
		for bb in [["chimney_fire", "village", "relic"], ["old_wall", "grave", "relic"], ["furrow_gold", "court", "way"], ["hua_xin", "court", "house"]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might
			var pth: Dictionary = Trials.path(bid, str(bb[2]))
			main.battle.start([{"id": bid, "lv": 101, "mult": float(bm[0]), "atk": float(bm[1])}], {"entity": {"id": "boss_" + bid}, "boss": true, "enemy": bid, "theme": str(bb[1]),
				"trial": bid, "path": str(bb[2]), "boon": pth.boon, "path_n": str(pth.n), "path_kind": str(Trials.KINDS[str(pth.kind)].n)})
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_mat"]
		main.ask_crossroads()
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("crossroads_mat")
		main.pop()
		Game.cross_pending = []
	if want.call("marks"):
		var fr3: Array = []
		for oa in ["cut", "whole", "road"]:
			Game.picks = {"the_mat": str(oa)}
			main.set_stack(["world"])
			if not await _mark_view("mark:the_mat:court", 15.0, 9.0, 5.0):
				continue
			await _shot("mark_mat_%s" % str(oa), false)
			fr3.append(last_img)
			w.cam_override = null
		_sheet("mark_mat_answers", fr3, 0.48)
		Game.picks = {}
	get_tree().quit(0)

## The Open Net (--net, or --net=a,b): "people", "foes", "pages" (Esc > The Law, The Wild), "draw" (F at somebody,
## and the mound where they stood), "watch" (the watch's question), "shelf" (the forbidden shelf), "land" (a
## country in balance and barren, side by side), "battle" (a barren pack, the watch, the enforcers, the four
## lords), "choice", "marks".
func _net_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 104
	Game.step = Data.step_index("s_p30_verdict")
	Game.companion = true
	Game.day = 171
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var clean := func():
		Game.slain = {}
		Game.slain_n = 0
		Game.bounty = {}
		Game.crimes = []
		Game.watch_day = {}
		Game.taboo = {}
		Game.cull = {}
		Game.cull_told = {}
		Game.cull_worst = {}
		Game.hunter_day = -1
		Game.toasts.clear()
		main.toast_list.clear()
	clean.call()
	if want.call("people"):
		await _gallery("part30_people", [Assets.person("cheng_tang"), Assets.person("li_li"), Assets.person("shang_yang"), Assets.person("jiang_chong")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["close_mesh", "drained_pool", "empty_snare", "wanted_bill", "false_witness", "hasty_seal", "inn_door", "torn_pass", "buried_doll", "keyhole_ear", "spade_shadow"]:
			fs.append(_foe(fid))
		await _gallery("part30_foes", fs, 1.0, 0.25)
		await _gallery("part30_lords", [_foe("four_net", true), _foe("the_sentence", true), _foe("shang_yang", true), _foe("jiang_chong", true)], 1.05, 0.25)
		var ls: Array = []
		for fid2 in ["watch_spear", "watch_captain", "bounty_taker", "league_enforcer", "carrion_crow", "midden_rat", "the_hunger"]:
			ls.append(_foe(fid2))
		await _gallery("law_and_leavings", ls, 1.0, 0.25)
	if want.call("pages"):
		main.set_stack(["world"])
		clean.call()
		var wen := _land_ent("granny_wen")
		var tie := _land_ent("smith")
		Game.level = 104
		if not wen.is_empty():
			Crime.strike(Game, wen, 3)
		Game.day += 2
		if not tie.is_empty():
			Crime.strike(Game, tie, 0)
		Crime.record(Game, "assault", "yanggu", "Watchman Zhou")
		Crime.record(Game, "flight", "qingshi", "Qingshi Village")
		Game.taboo = {"blood": 4, "soul": 1}
		Game.toasts.clear()
		main.toast_list.clear()
		main.open_menu()
		main.menu.mode = "law"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.6)
		await _shot("law_page")
		for pr in [["bamboo", 5.6], ["marsh", 3.4], ["thunder", 1.9], ["frost", 0.8], ["mirror", 0.3]]:
			Game.cull[str(pr[0])] = [float(pr[1]) * maxf(6.0, float(int(Data.AREAS[str(pr[0])].enemies))), Almanac.now(Game)]
		main.menu.mode = "wild"
		main.menu._build()
		await _wait(0.4)
		await _shot("wild_page")
		main.pop()
		clean.call()
	if want.call("draw"):
		main.set_stack(["world"])
		clean.call()
		var e := _land_ent("cook_zhou")
		if e.is_empty():
			e = _land_ent("gate_wu")
		if not e.is_empty():
			Game.clock = 10.0 * 60.0
			_stand_by(e)
			w.teleport(_nearest_free(e.pos + Vector2i(0, 1)), "surface")
			w.facing = e.pos - w.ptile
			await _wait(1.2)
			main.offer_draw(e)
			main.choice.cursor = 1
			await _wait(0.8)
			await _shot("draw_choice")
			main.pop()
			Crime.strike(Game, e, 2)
			# (the watch has been already today: the picture is of the mound)
			for wt in Weal.ORDER:
				Game.watch_day[wt] = Game.day
			Game.hunter_day = Game.day
			Game.toasts.clear()
			main.toast_list.clear()
			w.clear_cache()
			await _ent_shot(str(e.id), "grave_where_they_stood", 16.5, 4.2, 2.0, 0.6)
		clean.call()
		w.clear_cache()
	if want.call("watch"):
		main.set_stack(["world"])
		clean.call()
		Game.bounty = {"qingshi": 23400}
		Game.stones = 96000
		var hq := _land_ent("head_qingshi")
		var gw := _land_ent("granny_wen")
		if not gw.is_empty():
			_stand_by(gw)
		await _wait(1.0)
		var wdue := Crime.watch_due(Game, "village")
		if not wdue.is_empty():
			main.offer_watch(wdue)
			await _wait(0.5)
			await _shot("watch_comes")
			_skip_talk()
			await _wait(0.8)
			await _shot("watch_choice")
			main.pop()
		clean.call()
	if want.call("shelf"):
		main.set_stack(["world"])
		clean.call()
		Game.taboo = {"blood": 2}
		Game.hp[0] = float(Game.max_hp(0))
		main.open_forbidden()
		main.choice.cursor = 1
		await _wait(0.8)
		await _shot("forbidden_shelf")
		main.pop()
		clean.call()
	if want.call("land"):
		main.set_stack(["world"])
		var fr: Array = []
		var spot := Vector2i(-1, -1)
		for pe in Atlas.world_of("surface").ents:
			if str(pe.kind) == "enemy" and str(pe.get("area", "")) == "bamboo" and Wilds.native(pe):
				spot = _nearest_free(pe.pos + Vector2i(0, 3))
				break
		print("[tour] land: standing at ", spot)
		if spot.x >= 0:
			for stv in [0.0, 3.2, 5.6]:
				print("[tour] land: strain ", stv)
				clean.call()
				if stv > 0.0:
					Game.cull["bamboo"] = [stv * maxf(6.0, float(int(Data.AREAS.bamboo.enemies))), Almanac.now(Game)]
				Game.clock = 11.0 * 60.0
				w.open_world()
				w.enter_layer("surface")
				w.teleport(spot, "surface")
				w.facing = Vector2i(0, -1)
				w.cam_q = _quarter(Vector2(w.facing))
				w._snap_cam()
				w.wild_fade = Wilds.fade(Game, "bamboo")
				w.banner_t = 0.0
				await _wait(2.0)
				var pp: Vector3 = w._player_pos()
				w.cam_override = Transform3D(Basis.IDENTITY, pp + Vector3(5.5, 3.4, 8.5)).looking_at(pp + Vector3(0, 4.6, -6.0), Vector3.UP)
				await _wait(0.6)
				await _shot("wild_bamboo_%s" % str(Wilds.info(Game, "bamboo").id), false)
				fr.append(last_img)
				w.cam_override = null
			_sheet("wild_balance_to_barren", fr, 0.34)
		clean.call()
		w.wild_fade = 0.0
	if want.call("battle"):
		main.set_stack(["world"])
		var grp: Array = Wilds.group_at([{"id": "bamboo_wolf", "lv": 3}, {"id": "bamboo_wolf", "lv": 3}, {"id": "bamboo_wolf", "lv": 3}] if Data.ENEMIES.has("bamboo_wolf") else [{"id": "peach_sprite", "lv": 26}, {"id": "garden_crane", "lv": 26}, {"id": "moss_tortoise", "lv": 26}], 3, 1)
		main.battle.start(grp, {"entity": {"id": "t:barren"}, "boss": false, "theme": "bamboo", "habit": "", "group": grp, "grown": 0, "wild": 3})
		main.push("battle")
		await _wait(3.2)
		await _shot("battle_barren_pack")
		main.pop()
		Game.bounty = {"qingshi": 23400}
		main.battle.start(Crime.watch_group(Game), {"crime": "watch", "w": {"tid": "qingshi", "n": "Qingshi Village", "price": 23400}, "boss": false, "theme": "village"})
		main.push("battle")
		await _wait(3.2)
		await _shot("battle_the_watch")
		main.pop()
		Game.bounty = {}
		Game.taboo = {"blood": 3, "marked": 170}
		main.battle.start(Crime.hunters(Game), {"crime": "hunt", "boss": false, "theme": "marsh"})
		main.push("battle")
		await _wait(3.2)
		await _shot("battle_league_enforcers")
		main.pop()
		clean.call()
		for bb in [["four_net", "garden", "relic"], ["the_sentence", "lilies", "clean"], ["shang_yang", "lilies", "house"], ["jiang_chong", "palace", "relic"]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might
			var pth: Dictionary = Trials.path(bid, str(bb[2]))
			main.battle.start([{"id": bid, "lv": 104, "mult": float(bm[0]), "atk": float(bm[1])}], {"entity": {"id": "boss_" + bid}, "boss": true, "enemy": bid, "theme": str(bb[1]),
				"trial": bid, "path": str(bb[2]), "boon": pth.boon, "path_n": str(pth.n), "path_kind": str(Trials.KINDS[str(pth.kind)].n)})
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_verdict"]
		main.ask_crossroads()
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("crossroads_verdict")
		main.pop()
		Game.cross_pending = []
	if want.call("marks"):
		var fr3: Array = []
		for oa in ["sword", "bench", "field"]:
			Game.picks = {"the_verdict": str(oa)}
			main.set_stack(["world"])
			Game.mail_told = 999
			Game.fame_told = Fame.rank(Game)
			if not await _mark_view("mark:the_verdict:springs", 15.0, 9.0, 5.0):
				continue
			Game.toasts.clear()
			main.toast_list.clear()
			await _wait(0.3)
			await _shot("mark_verdict_%s" % str(oa), false)
			fr3.append(last_img)
			w.cam_override = null
		_sheet("mark_verdict_answers", fr3, 0.48)
		Game.picks = {}
	get_tree().quit(0)

## The Broken Mirror release (--mirror, or --mirror=a,b): see _run.
func _bare(asset: String) -> Node3D:
	var m: Node3D = Models.hero({"cols": {}}) if asset == "lin_feng" else (Models.yue_ling() if asset == "yue_ling" else Assets.person(asset))
	m.set_meta("kind", "person")
	Models.undress(m, true)
	return m

func _mirror_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 110
	Game.step = Data.step_index("s_p32_mirror")
	Game.companion = true
	Game.day = 190
	main.set_stack(["world"])
	main.world.clear_cache()
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
	quiet.call()
	if want.call("bodies"):
		var cast := ["lin_feng", "yue_ling", "smith", "granny_wen", "folk_boy"]
		var front: Array = []
		var back: Array = []
		for c in cast:
			front.append(_bare(c))
			back.append(_bare(c))
		await _pose_gallery("bodies_front", front, [["idle", 0.5], ["idle", 0.5], ["idle", 0.5], ["idle", 0.5], ["idle", 0.5]], 0.42, 0.3)
		await _pose_gallery("bodies_back", back, [["idle", 0.5], ["idle", 0.5], ["idle", 0.5], ["idle", 0.5], ["idle", 0.5]], 0.42, PI - 0.35)
		await _pose_gallery("bodies_man_and_woman", [_bare("lin_feng"), _bare("lin_feng"), _bare("yue_ling"), _bare("yue_ling")], [["idle", 0.5], ["idle", 0.5], ["idle", 0.5], ["idle", 0.5]], 0.36, 0.0)
	if want.call("close"):
		# (nearer: a man and a woman from the front, and from behind)
		await _pose_gallery("bodies_close_front", [_bare("lin_feng"), _bare("yue_ling")], [["idle", 0.5], ["idle", 0.5]], 0.24, 0.25)
		await _pose_gallery("bodies_close_back", [_bare("lin_feng"), _bare("yue_ling")], [["idle", 0.5], ["idle", 0.5]], 0.24, PI - 0.3)
	if want.call("people"):
		await _gallery("part32_people", [Assets.person("yue_lao"), Assets.person("weisheng"), Assets.person("meng_jiang"), Assets.person("xu_deyan"), Assets.person("lechang")], 0.5, 0.2)
	if want.call("clips"):
		await _pose_gallery("clips_of_two", [Models.hero({"cols": {}}), Models.yue_ling(), Models.hero({"cols": {}}), Models.yue_ling(), Models.hero({"cols": {}}), Models.yue_ling()],
			[["take_hands", 1.7], ["take_hands", 1.7], ["embrace", 2.2], ["embrace", 2.2], ["brow_touch", 2.0], ["brow_touch", 2.0]], 0.4, 0.5)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["snapped_thread", "kings_seal", "torn_sleeve", "rising_water", "held_pillar", "plank_step", "named_brick", "overseer_lash", "tally_bone", "mirror_shard", "market_cry", "empty_moon"]:
			fs.append(_foe(fid))
		await _gallery("part32_foes", fs, 1.0, 0.25)
		await _gallery("part32_lords", [_foe("two_graves", true), _foe("the_flood", true), _foe("the_wall", true)], 1.3, 0.25)
	if want.call("touch"):
		Game.romance = {"stage": 3, "tone": {"tender": 3}}
		Game.bond = 80
		for tc in [["hands", "touch_take_hands", 2.6], ["embrace", "touch_embrace", 3.2], ["brow", "touch_brow_to_brow", 3.0]]:
			main.set_stack(["world"])
			quiet.call()
			await _wait(0.6)
			main.say(Romance.touch(Game, str(tc[0])))
			await _wait(float(tc[2]))
			await _shot(str(tc[1]))
		main.set_stack(["world"])
		main.open_menu()
		main.menu.mode = "yue"
		main.menu.cursor = 4
		main.menu._build()
		await _wait(0.6)
		await _shot("yue_page_near")
		main.set_stack(["world"])
	if want.call("battles"):
		for bb in [["two_graves", "starpalace", "relic", 109], ["the_flood", "magpie", "relic", 110], ["the_wall", "youdu", "relic", 111]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might
			main.set_stack(["world"])
			Game.area = str(bb[1])
			var ctx := {"boss": bid, "area": str(bb[1]), "theme": str(Data.AREAS[str(bb[1])].theme), "trial": str(bb[2])}
			main.battle.start([{"id": bid, "lv": int(bb[3]), "mult": float(bm[0]), "atk": float(bm[1])}], ctx)
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_mirror"]
		main.ask_crossroads()
		main.choice.cursor = 0
		await _wait(1.0)
		await _shot("crossroads_mirror")

## The Iron Pestle release (--pestle, or --pestle=a,b): see _run.
func _pestle_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 113
	Game.step = Data.step_index("s_p33_needle")
	Game.companion = true
	Game.day = 200
	main.set_stack(["world"])
	main.world.clear_cache()
	Game.toasts.clear()
	main.toast_list.clear()
	Game.mail_told = 999
	Game.fame_told = Fame.rank(Game)
	if want.call("people"):
		await _gallery("part33_people", [Assets.person("granny_wu"), Assets.person("li_bai"), Assets.person("kuang_heng"), Assets.person("oil_seller"), Assets.person("chen_yaozi")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["green_peach", "skipped_page", "skipped_step", "stopped_hole", "idle_lamp", "uncut_book", "proud_arrow", "spilt_oil", "idle_clap", "third_watch", "dry_lamp", "melting_snow"]:
			fs.append(_foe(fid))
		await _gallery("part33_foes", fs, 1.0, 0.25)
		await _gallery("part33_lords", [_foe("the_short_way", true), _foe("the_shelf", true), _foe("the_knack", true)], 1.3, 0.25)
	if want.call("marks"):
		var ms: Array = []
		for oid in ["truth", "finish", "turn"]:
			ms.append(Marks.model(Marks.MARKS.the_needle[oid], 0))
		await _gallery("part33_marks", ms, 0.9, 0.3)
	if want.call("battles"):
		for bb in [["the_short_way", "jasper", "relic", 112], ["the_shelf", "void", "relic", 113], ["the_knack", "celestial", "relic", 114]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might
			main.set_stack(["world"])
			Game.area = str(bb[1])
			var ctx := {"boss": bid, "area": str(bb[1]), "theme": str(Data.AREAS[str(bb[1])].theme), "trial": str(bb[2])}
			main.battle.start([{"id": bid, "lv": int(bb[3]), "mult": float(bm[0]), "atk": float(bm[1])}], ctx)
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_needle"]
		main.ask_crossroads()
		main.choice.cursor = 0
		await _wait(1.0)
		await _shot("crossroads_needle")

## The Tall People release (--tall, or --tall=a,b): see _run.
func _giant(asset: String) -> Node3D:
	var m: Node3D = Assets.person(asset) if Assets.PEOPLE.has(asset) else Assets.instance("characters/" + asset)
	m.set_meta("kind", "person")
	Assets.lend_clips(m)
	m.scale = Vector3.ONE * Giants.SCALE
	return m

## The Cloud Keel release: see `--keel` above.
func _keel_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 60
	Game.stones = 48000
	Game.step = Data.step_index("s_p13_home")
	Game.companion = true
	Game.day = 120
	for rid in [Atlas.HUB] + Data.AREA_CHAIN:
		Game.seen[rid] = true
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
	quiet.call()
	if want.call("ark"):
		var arks2: Array = []
		for am in [Models.ark(true, 3.0), Models.ark(false)]:
			var holder := Node3D.new()
			(am as Node3D).scale = Vector3.ONE * 0.3
			holder.add_child(am)
			arks2.append(holder)
		await _gallery("ark_moored_and_under_way", arks2, 2.0, 0.75)
	# the ark over a dock: from the ground beside her, and from the air
	for dk in [["cloudfoot", "ark_over_cloudfoot", 10.0], ["lightfoot", "ark_over_lightfoot", 9.5], ["fourstreams", "ark_over_fourstreams", 9.0], ["landfall", "ark_over_landfall", 9.5]]:
		if not want.call("docks") and not want.call(str(dk[0])):
			continue
		var did := str(dk[0])
		var dl := Data.layer_of(str(Arks.DOCKS[did].area))
		var dw: Dictionary = Atlas.world_of(dl)
		var bt := Arks.berth(dw, did)
		var q := Arks.quay(did)
		Clock.set_hour(Game, float(dk[2]))
		w.teleport(_nearest_free(q), dl)
		quiet.call()
		await _wait(1.2)
		var bp: Vector3 = w.wpos(bt)
		bp.y = w.ground_y(bp)
		var qp: Vector3 = w.wpos(q)
		var away := (Vector3(qp.x, 0, qp.z) - Vector3(bp.x, 0, bp.z)).normalized()
		if away.length() < 0.5:
			away = Vector3(0.6, 0, 0.8)
		var side := Vector3(-away.z, 0, away.x)
		w.cam_override = Transform3D(Basis.IDENTITY, bp + away * 30.0 + side * 22.0 + Vector3(0, Arks.HOVER + 13.0, 0)).looking_at(bp + Vector3(0, Arks.HOVER * 0.7, 0), Vector3.UP)
		await _wait(0.8)
		await _shot(str(dk[1]))
		if did == "lightfoot":
			w.cam_override = Transform3D(Basis.IDENTITY, bp + away * 46.0 - side * 30.0 + Vector3(0, 46.0, 0)).looking_at(bp + away * 10.0 + Vector3(0, 6.0, 0), Vector3.UP)
			await _wait(0.6)
			await _shot("town_lightfoot")
		w.cam_override = null
	if want.call("counter"):
		var cl := "far"
		Clock.set_hour(Game, 10.0)
		var ce: Dictionary = {}
		for e in Atlas.world_of(cl).ents:
			if str(e.get("office", "")) == "moorer_lightfoot":
				ce = e
		if not ce.is_empty():
			w.teleport(_nearest_free(ce.pos + Vector2i(0, 1)), cl)
			quiet.call()
			await _wait(0.8)
			main.offer_carriage(ce)
			await _wait(0.4)
			for oi in main.choice.options.size():
				if str(main.choice.options[oi].id).begins_with("ark:cloudfoot"):
					main.choice.cursor = oi
			main.choice._show()
			await _wait(0.3)
			await _shot("ark_counter")
			main.pop()
	if want.call("far"):
		for fs in [["huaxu", Vector2i(86, 32), "far_huaxu", 10.0, Vector3(-30.0, 16.0, 34.0)], ["zhongbei", Vector2i(37, 31), "town_fourstreams", 15.5, Vector3(-30.0, 30.0, 34.0)],
				["zhongbei", Vector2i(70, 30), "far_zhongbei", 16.0, Vector3(-40.0, 18.0, 40.0)], ["gumang", Vector2i(42, 28), "far_gumang", 22.0, Vector3(-24.0, 16.0, 28.0)],
				["fuluo", Vector2i(47, 28), "far_fuluo", 12.0, Vector3(-26.0, 18.0, 30.0)]]:
			Clock.set_hour(Game, float(fs[3]))
			var ft := _nearest_free(Atlas.to_world(str(fs[0]), fs[1]))
			w.teleport(ft, "far")
			quiet.call()
			await _wait(1.2)
			var fp: Vector3 = w.wpos(ft)
			fp.y = w.ground_y(fp)
			w.cam_override = Transform3D(Basis.IDENTITY, fp + (fs[4] as Vector3)).looking_at(fp + Vector3(2.0, 1.0, -3.0), Vector3.UP)
			await _wait(0.8)
			await _shot(str(fs[2]))
			w.cam_override = null
		# ... and from the ground, with Yue Ling
		Clock.set_hour(Game, 9.0)
		w.teleport(_nearest_free(Atlas.to_world("huaxu", Vector2i(46, 32))), "far")
		w.facing = Vector2i(1, 0)
		w.cam_q = w.FWD.find(Vector2i(1, 0))
		w._snap_cam()
		quiet.call()
		await _wait(1.2)
		await _shot("street_of_lightfoot")
	if want.call("sky"):
		# the arks under way, looked up at from open country east of Lightfoot (one of them brought down to
		# where she can be seen)
		Clock.set_hour(Game, 16.5)
		w.teleport(_nearest_free(Atlas.to_world("huaxu", Vector2i(88, 32))), "far")
		quiet.call()
		await _wait(1.2)
		var pp: Vector3 = w.player.position
		var demo: Node3D = Models.ark(false)
		demo.position = pp + Vector3(10.0, 24.0, -26.0)
		demo.rotation = Vector3(0.0, 2.2, 0.05)
		w.scene3d.add_child(demo)
		var demo2: Node3D = Models.ark(false)
		demo2.position = pp + Vector3(-46.0, 44.0, -90.0)
		demo2.rotation = Vector3(0.0, 0.8, 0.0)
		w.scene3d.add_child(demo2)
		w.cam_override = Transform3D(Basis.IDENTITY, pp + Vector3(-7.0, 2.4, 9.0)).looking_at(pp + Vector3(4.0, 17.0, -20.0), Vector3.UP)
		await _wait(0.6)
		await _shot("arks_under_way")
		demo.queue_free()
		demo2.queue_free()
		w.cam_override = null
	if want.call("apartments"):
		for fs2 in [["huaxu", "ark_hands", "apartments_ark_hands", "far"], ["mountain", "caravanserai", "apartments_caravanserai", "surface"], ["huaxu", "unhurried_inn", "guest_rooms_unhurried", "far"], ["huaxu", "wind_chandler", "apartments_over_a_shop", "far"]]:
			var fid := Atlas.floor_id(str(fs2[0]), str(fs2[1]), 1)
			var fwd: Dictionary = Atlas.world_of(fid)
			if fwd.is_empty():
				continue
			Clock.set_hour(Game, 19.5)
			w.teleport(fwd.start, fid)
			var mid := Vector2(fwd.w, fwd.h) * 0.5
			var dv := mid - Vector2(fwd.start)
			var fdir := Vector2i(signi(int(dv.x)), 0) if absf(dv.x) > absf(dv.y) else Vector2i(0, signi(int(dv.y)))
			if fdir == Vector2i.ZERO:
				fdir = Vector2i(0, 1)
			w.facing = fdir
			w.cam_q = w.FWD.find(fdir)
			w._snap_cam()
			quiet.call()
			await _wait(1.0)
			await _shot(str(fs2[2]))
			# from straight above, with the roof off: the plan of the storey
			var c3: Vector3 = w.player.position
			var org: Vector3 = w.wpos(Vector2i(int(fwd.w / 2), int(fwd.h / 2)))
			w.cam_override = Transform3D(Basis.IDENTITY, Vector3(org.x, c3.y + 17.0, org.z + 7.5)).looking_at(Vector3(org.x, c3.y, org.z - 0.5), Vector3.UP)
			await _wait(0.5)
			await _shot(str(fs2[2]) + "_plan")
			w.cam_override = null
	if want.call("apartments") or want.call("lodger"):
		# somebody at home upstairs, spoken to
		var afid := Atlas.floor_id("huaxu", "ark_hands", 1)
		var afw: Dictionary = Atlas.world_of(afid)
		for e2 in afw.get("ents", []):
			if bool(e2.get("lodger", false)):
				var at := Vector2i(-1, -1)
				for d in MapGen.DIRS:
					var n: Vector2i = e2.pos + d
					if MapGen.is_walkable_tile(afw.grid[n.y * int(afw.w) + n.x]) and not afw.ents.any(func(o): return o.has("pos") and o.pos == n and not bool(o.get("walk", false))):
						at = n
				if at.x < 0:
					continue
				w.teleport(at, afid)
				w.facing = e2.pos - at
				w.cam_q = w.FWD.find(w.facing)
				w._snap_cam()
				quiet.call()
				await _wait(0.8)
				main.talk_npc(e2)
				await _wait(1.2)
				await _shot("lodger_at_home")
				main.set_stack(["world"])
				break
	if want.call("mended"):
		# what the audit of shared ground mended, seen: a cellar whose shelves stand clear of its wall, a
		# bed along a wall, lanterns over heads
		for fs3 in [["f:sect:library:-1", "cellar_furniture_clear"], ["f:village:green_stone_inn:-1", "cellar_inn_clear"]]:
			var fw3: Dictionary = Atlas.world_of(str(fs3[0]))
			if fw3.is_empty():
				continue
			w.teleport(fw3.start, str(fs3[0]))
			w._snap_cam()
			quiet.call()
			await _wait(0.9)
			await _shot(str(fs3[1]))
		Clock.set_hour(Game, 10.0)
		var yq := Ships.quay("yanggu")
		var yw: Dictionary = Atlas.world_of("surface")
		var ym := Ships.mooring(yw, "yanggu")
		if ym.x >= 0:
			w.teleport(_nearest_free(yq), "surface")
			quiet.call()
			await _wait(1.0)
			var yp: Vector3 = w.wpos(ym)
			w.cam_override = Transform3D(Basis.IDENTITY, yp + Vector3(6.0, 34.0, 20.0)).looking_at(yp + Vector3(0, 1.0, 0), Vector3.UP)
			await _wait(0.6)
			await _shot("junk_afloat_at_yanggu")
			w.cam_override = null
	if want.call("map"):
		w.teleport(_nearest_free(Arks.quay("lightfoot")), "far")
		quiet.call()
		await _wait(0.6)
		main.open_menu()
		main.menu.mode = "map"
		main.menu.map_layer = "far"
		main.menu._build()
		await _wait(0.5)
		await _shot("map_far_countries")
		main.set_stack(["world"])

func _tall_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 107
	Game.step = Data.step_index("s_p31_lintel")
	Game.companion = true
	Game.day = 190
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
	quiet.call()
	if want.call("people"):
		await _gallery("great_people_and_a_man", [_giant("folk_giant"), Models.hero({"cols": {}}), _giant("folk_giantess"), Models.yue_ling(), _giant("fangfeng")], 1.15, 0.2)
		await _gallery("part31_giants", [_giant("fangfeng"), _giant("kuafu"), _giant("longbo_angler")], 1.3, 0.2)
		await _gallery("part31_people", [Assets.person("yan_ying"), Assets.person("zheng_buyer"), Models.hero({"cols": {}})], 0.5, 0.2)
	if want.call("clips"):
		var ms: Array = []
		var ps: Array = []
		var who := {"stroke_beard": "elder", "sleeve_smile": "yue_ling", "fist_palm": "lin_feng", "hand_heart": "li_li", "shade_eyes": "hua_xin", "measure": "zheng_buyer", "arms_cross": "yan_ying", "stoop": "cheng_tang"}
		for cl in ["stroke_beard", "sleeve_smile", "fist_palm", "hand_heart", "shade_eyes", "measure", "arms_cross", "stoop"]:
			var pm: Node3D = Assets.person(str(who[cl])) if Assets.PEOPLE.has(str(who[cl])) else Assets.person("lin_feng")
			Assets.lend_clips(pm)
			ms.append(pm)
			ps.append([cl, float(Closeup.SECONDS[cl]) * 0.5])
		await _pose_gallery("closeup_gestures", ms, ps, 0.42, 0.35)
		await _pose_gallery("giant_stoops_to_a_man", [_giant("fangfeng"), Models.hero({"cols": {}}), _giant("folk_giantess")], [["stoop", 1.8], ["idle", 0.5], ["stoop", 1.2]], 1.25, 0.25)
	if want.call("faces"):
		var rows: Array = []
		for grp in [[4, 3, 2, 1, 0], [0, -1, -2, -3, -4]]:
			var sc := _bare_stage(460.0, 22.0)
			var stage: Node3D = sc[0]
			var cam: Camera3D = sc[1]
			var models: Array = []
			for i in grp.size():
				var m: Node3D = Models.hero({"visage": int(grp[i]), "cols": {"robe": Color("3a8ae8"), "sec": Color("2a3a6a"), "trim": Color("e8f0ff")}})
				m.position = Vector3((i - (grp.size() - 1) * 0.5) * 0.36, 0.0, 0.0)
				m.rotation.y = 0.18 if i % 2 == 0 else -0.18
				stage.add_child(m)
				_caption(stage, m.position + Vector3(0, 1.66 - 0.215, 0.2), str(Visage.LOOKS[int(grp[i])].n), 0.00046)
				models.append(m)
			cam.position = Vector3(0, 1.68, 0.5 + grp.size() * 0.36 * 1.28)
			cam.look_at(stage.global_position + Vector3(0, 1.625, 0), Vector3.UP)
			cam.make_current()
			var t0 := 0.0
			for k in 40:
				t0 += 1.0 / 30.0
				for m2 in models:
					Models.anim_person(m2, 1.6 + t0, false)
				await get_tree().process_frame
			await _shot("face_row", false)
			var img: Image = last_img
			rows.append(img.get_region(Rect2i(0, int(img.get_height() * 0.3), img.get_width(), int(img.get_height() * 0.37))))
			stage.queue_free()
			main.world.show()
		_stack("faces_of_the_way", rows)
		await _gallery("looks_of_the_way", [Models.hero({"visage": 4, "cols": {}}), Models.hero({"visage": 2, "cols": {}}), Models.hero({"visage": 0, "cols": {}}), Models.hero({"visage": -2, "cols": {}}), Models.hero({"visage": -4, "cols": {}})], 0.5, 0.15)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["late_drum", "roll_call", "flood_mire", "noon_glare", "long_shadow", "dry_bed", "small_decree", "low_lintel", "drift_isle", "tight_shoe", "cut_measure", "dog_door"]:
			fs.append(_foe(fid))
		await _gallery("part31_foes", fs, 1.0, 0.25)
		var kw := _foe("kuafu_west", true)
		kw.scale = Vector3.ONE * Giants.SCALE
		await _gallery("part31_lords", [_foe("late_axe", true), kw, _foe("the_decree", true), _foe("the_shoe", true)], 1.3, 0.25)
		var og: Array = []
		for oid in ["fangfeng", "kuafu", "longbo_giant"]:
			var om := _foe(oid, true)
			om.scale = Vector3.ONE * Giants.SCALE
			og.append(om)
		og.insert(1, Models.hero({"cols": {}}))
		await _gallery("old_giants_in_their_own_bodies", og, 1.2, 0.2)
	var lw := Atlas.world_of("surface")
	if want.call("town"):
		for tw in [["qingshi", 10.4, "giants_in_qingshi"], ["tushan", 17.8, "giants_in_tushan"]]:
			main.set_stack(["world"])
			w.open_world()
			w.enter_layer("surface")
			Game.clock = float(tw[1]) * 60.0
			for fp in Folk.people(lw, str(tw[0])):
				if str(fp.role) != Giants.ROLE:
					continue
				var st: Dictionary = Folk.state(lw, fp, Game.clock)
				if not bool(st.vis):
					continue
				var gt := Vector2i(int(floor(float(st.at.x))), int(floor(float(st.at.y))))
				var spot := _nearest_free(gt + Vector2i(0, 3))
				w.teleport(spot, "surface")
				w.facing = Vector2i(0, -1)
				w.cam_q = 0
				w._snap_cam()
				w.banner_t = 0.0
				quiet.call()
				await _wait(1.4)
				var gp: Vector3 = w.wpos(gt)
				var pp: Vector3 = w._player_pos()
				var look := (gp + pp) * 0.5 + Vector3(0, 1.9, 0)
				var side := (gp - pp).normalized().cross(Vector3.UP)
				w.cam_override = Transform3D(Basis.IDENTITY, look + side * 8.5 + Vector3(0, 1.4, 0) - (gp - pp).normalized() * 2.0).looking_at(look, Vector3.UP)
				await _wait(0.3)
				await _shot(str(tw[2]))
				w.cam_override = null
				break
	if want.call("door"):
		main.set_stack(["world"])
		w.open_world()
		w.enter_layer("surface")
		Game.clock = 10.0 * 60.0
		for bd in lw.buildings:
			if str(bd.get("area", "")) != "village" or not str(bd.get("style", "")) in ["house", "inn", "shop", "teahouse"]:
				continue
			var d: Vector2i = bd.door
			var out := Vector2i.ZERO
			for dd in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				if not Rooms.inside(bd, d + dd) and MapGen.is_walkable_tile(lw.grid[(d.y + dd.y) * int(lw.w) + d.x + dd.x]) and lw.grid[(d.y + dd.y) * int(lw.w) + d.x + dd.x] != MapGen.INTERIOR:
					out = dd
			if out == Vector2i.ZERO or out != Vector2i(0, 1):
				continue
			w.teleport(d + out * 3 + Vector2i(1, 0), "surface")
			w.facing = -out
			w.cam_q = _quarter(Vector2(-out))
			w._snap_cam()
			w.banner_t = 0.0
			quiet.call()
			await _wait(0.5)
			var o3 := Vector3(out.x, 0, out.y)
			var s3 := Vector3(-out.y, 0, out.x)
			var dp: Vector3 = w.wpos(d)
			var gm := _giant("folk_giant")
			gm.position = dp + o3 * 0.2 + Vector3(0, Arch.FLOOR_Y, 0)
			gm.rotation.y = atan2(o3.x, o3.z)
			w.scene3d.add_child(gm)
			var gm2 := _giant("folk_giantess")
			gm2.position = dp + o3 * 3.6 - s3 * 2.2
			gm2.position.y = w.ground_y(gm2.position)
			gm2.rotation.y = atan2(-o3.x, -o3.z) + 0.5
			w.scene3d.add_child(gm2)
			var fm: Node3D = Assets.instance("characters/folk_farmer")
			fm.position = dp + o3 * 2.4 - s3 * 0.9
			fm.position.y = w.ground_y(fm.position)
			fm.rotation.y = atan2(-o3.x, -o3.z)
			w.scene3d.add_child(fm)
			for k in 6:
				Models.anim_person(gm, 2.0 + k * 0.03, true)
				Models.anim_person(gm2, 1.0 + k * 0.03, false, false, "talk")
				Models.anim_person(fm, 1.0 + k * 0.03, false)
				await get_tree().process_frame
			var lk := dp + Vector3(0, 2.3, 0)
			w.cam_override = Transform3D(Basis.IDENTITY, dp + o3 * 9.5 + s3 * 4.2 + Vector3(0, 2.2, 0)).looking_at(lk, Vector3.UP)
			await _wait(0.2)
			await _shot("giant_in_a_doorway")
			w.cam_override = null
			# and indoors, under the ceiling: the roof lifts away
			var inn := d - out * 2
			if Rooms.inside(bd, inn):
				gm.position = w.wpos(d - out * 3) + Vector3(0.9, Arch.FLOOR_Y, 0)
				gm.rotation.y = 0.4
				w.teleport(inn, "surface")
				w.facing = -out
				w.cam_q = _quarter(Vector2(-out))
				w._snap_cam()
				quiet.call()
				for k2 in 10:
					Models.anim_person(gm, 1.0 + k2 * 0.03, false, false, "talk")
					await get_tree().process_frame
				await _shot("giant_indoors")
			gm.queue_free()
			gm2.queue_free()
			fm.queue_free()
			break
	if want.call("closeup"):
		for cv in [["fangfeng", "s_p31_late", "closeup_fangfeng"], ["yan_ying", "s_p31_envoy", "closeup_yan_ying"]]:
			main.set_stack(["world"])
			Game.step = Data.step_index(str(cv[1]))
			w.clear_cache()
			var e := _land_ent(str(cv[0]))
			if e.is_empty():
				continue
			Game.clock = 15.5 * 60.0
			_stand_by(e)
			quiet.call()
			await _wait(0.5)
			main.say(Echoes.told(Game, str(cv[1]), Data.DIALOGUE[str(cv[1])]))
			var frames: Array = []
			for li in (Data.DIALOGUE[str(cv[1])] as Array).size():
				main.dialogue.shown = 999.0
				await _wait(1.3 if li > 0 else 2.0)
				await _shot("%s_%d" % [str(cv[2]), li], true)
				frames.append(last_img)
				main.press("confirm")
				await _wait(0.15)
			_sheet(str(cv[2]) + "_cut", frames, 1.0)
			await _skip_talk()
	if want.call("page"):
		main.set_stack(["world"])
		Game.creed["virtue"] = -34
		quiet.call()
		w.refresh_hero()
		main.open_menu()
		main.menu.mode = "way"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.6)
		await _shot("way_page_face")
		main.pop()
		Game.creed["virtue"] = 0
	if want.call("battle"):
		main.set_stack(["world"])
		for bb in [["kuafu_west", "buzhou", "relic", 107], ["late_axe", "time", "folk", 106], ["the_decree", "penglai", "relic", 107], ["the_shoe", "loom", "relic", 108], ["fangfeng", "tushan", "might", 44]]:
			var bid := str(bb[0])
			var bm: Array = Trials.TRIALS[bid].might if Trials.TRIALS.has(bid) else [3.0, 1.2]
			var pth: Dictionary = Trials.path(bid, str(bb[2])) if Trials.TRIALS.has(bid) else {}
			var ctx := {"entity": {"id": "boss_" + bid}, "boss": true, "enemy": bid, "theme": str(Data.AREAS[str(bb[1])].theme)}
			if not pth.is_empty():
				ctx.merge({"trial": bid, "path": str(bb[2]), "boon": pth.boon, "path_n": str(pth.n), "path_kind": str(Trials.KINDS[str(pth.kind)].n)})
			main.battle.start([{"id": bid, "lv": int(bb[3]), "mult": float(bm[0]), "atk": float(bm[1])}], ctx)
			main.push("battle")
			await _wait(3.4)
			await _shot("battle_boss_" + bid)
			main.pop()
	if want.call("choice"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_lintel"]
		main.ask_crossroads()
		main.choice.cursor = 2
		await _wait(1.0)
		await _shot("crossroads_lintel")
		main.pop()
		Game.cross_pending = []
	get_tree().quit(0)

## The Iron Pestle release: somebody of the towns faced, with what they work for under their name; what
## they say of it; somebody asked the way; a disciple of the sect and his layer; a battle in which the
## foes have said why they went for whom; and the bestiary's line on how a thing fights.
func _wits_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 40
	Game.step = Data.step_index("s_p16_report")
	Game.companion = true
	Game.day = 64
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var lw := Atlas.world_of("surface")
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
	quiet.call()
	# somebody of `town` at hour `h` who is out of doors, standing still, with open ground south of them
	var find := func(town: String, h: float, ok: Callable) -> Dictionary:
		Game.clock = h * 60.0
		for fp in Folk.people(lw, town):
			if not ok.call(fp):
				continue
			var st: Dictionary = Folk.state(lw, fp, Game.clock)
			if not bool(st.vis) or bool(st.walk):
				continue
			var gt := Vector2i(int(floor(float(st.at.x))), int(floor(float(st.at.y))))
			var spot := gt + Vector2i(0, 1)
			if not w.tile_free(spot) or w.ent_at(spot) != null or not w.building_at(spot).is_empty():
				continue
			return {"p": fp, "at": gt, "spot": spot}
		return {}
	var stand := func(f: Dictionary) -> void:
		main.set_stack(["world"])
		w.open_world()
		w.enter_layer("surface")
		w.teleport(f.spot, "surface")
		w.facing = Vector2i(0, -1)
		w.cam_q = 0
		w._snap_cam()
		w.banner_t = 0.0
		quiet.call()
	if want.call("town"):
		for tw in [["qingshi", 10.4, "living_farmer", "farmer"], ["cloudfoot", 15.0, "living_merchant", "merchant"], ["sect", 9.0, "living_disciple", "disciple"]]:
			main.set_stack(["world"])
			w.open_world()
			w.enter_layer("surface")
			var f: Dictionary = find.call(str(tw[0]), float(tw[1]), func(q: Dictionary) -> bool: return str(q.role) == str(tw[3]))
			if f.is_empty():
				print("[tour] nobody to face in ", tw[0])
				continue
			stand.call(f)
			await _wait(1.6)
			await _shot(str(tw[2]) + "_tag")
			Game.folk_talk[str(f.p.id)] = 2
			main.talk_folk({"kind": "folk", "id": f.p.id, "n": f.p.n, "p": f.p, "pos": f.at, "area": f.p.area})
			main.dialogue.shown = 999.0
			await _wait(0.5)
			await _shot(str(tw[2]) + "_says")
			main.set_stack(["world"])
			w.folk_talking = ""
	if want.call("way"):
		main.set_stack(["world"])
		w.open_world()
		w.enter_layer("surface")
		var f2: Dictionary = find.call("qingshi", 10.4, func(q: Dictionary) -> bool: return str(q.role) in ["merchant", "cook", "washer", "elder"])
		if not f2.is_empty():
			var keep_step: int = Game.step
			for i in Data.STEPS.size():
				var st2: Dictionary = Data.STEPS[i]
				if str(st2.kind) == "talk" and str(st2.get("area", "")) == "village" and st2.has("npc"):
					Game.step = i
					var we = w.find_ent(str(st2.npc))
					if we != null and w.ent_visible(we) and (we.pos - f2.at).length() > 12.0:
						break
			stand.call(f2)
			Game.folk_talk[str(f2.p.id)] = 1
			main.talk_folk({"kind": "folk", "id": f2.p.id, "n": f2.p.n, "p": f2.p, "pos": f2.at, "area": f2.p.area})
			main.dialogue.shown = 999.0
			await _wait(0.5)
			await _shot("folk_knows_the_way")
			main.set_stack(["world"])
			w.folk_talking = ""
			Game.step = keep_step
	if want.call("battle"):
		main.set_stack(["world"])
		var pick := {}
		for id in Data.ENEMIES:
			var d: Dictionary = Data.ENEMIES[id]
			if d.get("boss", false) or d.get("doom", false):
				continue
			for sh in ["fox", "humanoid", "beast"]:
				if str(d.shape) == sh and not pick.has(sh):
					pick[sh] = str(id)
		var b = main.battle
		b.start([{"id": pick.fox, "lv": 40}, {"id": pick.humanoid, "lv": 40}, {"id": pick.humanoid, "lv": 40}, {"id": pick.beast, "lv": 40}], {"boss": false, "theme": "bamboo"})
		main.push("battle")
		await _wait(2.6)
		b.log_lines.clear()
		b.round_no = 2
		Tactics.new_round(b.wits, 2)
		b.wits.mended[1] = 2
		b.party[1].hp = float(b.party[1].maxhp) * 0.5
		seed(7)
		b._foe_act(b.foes[0])
		await _wait(0.9)
		b._foe_act(b.foes[1])
		await _wait(0.9)
		b.foes[2].hp = float(b.foes[2].maxhp) * 0.2
		b._foe_act(b.foes[2])
		await _wait(0.9)
		b._foe_act(b.foes[3])
		await _wait(0.7)
		await _shot("battle_foes_that_think")
		main.pop()
	if want.call("page"):
		main.set_stack(["world"])
		var fox_id := ""
		for id2 in Data.ENEMIES:
			if str(Data.ENEMIES[id2].shape) == "fox" and not Data.ENEMIES[id2].get("boss", false) and fox_id == "":
				fox_id = str(id2)
			if Game.bestiary.size() < 24 and not Data.ENEMIES[id2].get("boss", false):
				Game.bestiary[str(id2)] = 3
		Game.bestiary[fox_id] = 5
		main.open_menu()
		main.menu.mode = "bestiary"
		main.menu._build()
		var ents: Array = main.menu.bestiary()
		for i2 in ents.size():
			if str(ents[i2][0]) == fox_id:
				main.menu.cursor = i2
		await _wait(0.6)
		await _shot("bestiary_how_it_fights")
		main.pop()
	get_tree().quit(0)

## The Unpicked Road release (--road, or --road=a,b): the small things in a row; a street with things
## lying in it; the choice at a thing that is somebody's; what its owner says; a lost thing brought to a
## door; the street answering a blade; a leap, and a child who jumps too; somebody walked into; and the
## people, foes, lords and marks of Part XXXIV with its crossroads.
func _road_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 116
	Game.step = Data.step_index("s_p34_belts")
	Game.companion = true
	Game.day = 210
	Game.stones = 5000
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var lw := Atlas.world_of("surface")
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
	quiet.call()
	if want.call("things"):
		for row in [["ware", "trifles_wares"], ["keep", "trifles_keeps"], ["lost", "trifles_lost"], ["wild", "trifles_wild_and_altar"]]:
			var ms: Array = []
			for k in Trifles.KINDS:
				var c := str(Trifles.KINDS[k].cls)
				if c == str(row[0]) or (str(row[0]) == "wild" and c == "altar"):
					var holder := Node3D.new()
					var m := Trifles.model(str(k))
					# (each shown at the same size, a pace across, on a stand: a hairpin beside a broom)
					var bx := AABB()
					for mc in m.get_children():
						if mc is MeshInstance3D:
							bx = bx.merge((mc as MeshInstance3D).get_aabb())
					var sc := 0.8 / maxf(0.05, maxf(bx.size.x, maxf(bx.size.y, bx.size.z)))
					m.scale = Vector3.ONE * sc
					m.position = Vector3(-bx.get_center().x * sc, 0.75 - bx.position.y * sc, 0.0)
					var stand_b := MB.new()
					stand_b.cyl(Vector3(0, 0.36, 0), 0.34, 0.72, MB.tag(Color("6a5a4a"), MB.WOOD), Vector3.ZERO, 12)
					MB.mesh_node(holder, stand_b.build(MB.mat_vc()))
					holder.add_child(m)
					ms.append(holder)
			await _gallery(str(row[1]), ms, 0.45, 0.3)
	if want.call("people"):
		await _gallery("part34_people", [Assets.person("yangzi_wife"), Assets.person("yang_zhen"), Assets.person("bell_thief"), Assets.person("pei_du")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["thrown_gold", "robber_spring", "flung_food", "dusk_gold", "nobody_knows", "heavy_sleeve", "rung_bell", "ear_wad", "bell_mallet"]:
			fs.append(_foe(fid))
		await _gallery("part34_foes", fs, 1.0, 0.25)
		await _gallery("part34_lords", [_foe("the_find", true), _foe("the_dusk", true), _foe("the_bell", true)], 1.3, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["wait", "cry", "lie"]:
			mk.append(Marks.model(Marks.MARKS.the_belts[oid], 0))
		await _gallery("part34_marks", mk, 0.9, 0.3)
	# a thing of class `cls` in Qingshi with open ground south of it, at an hour when somebody can see it
	var thing := func(cls: String, h: float, seen: bool) -> Dictionary:
		Game.clock = h * 60.0
		for tf in Trifles.of_area(Game, lw, "village"):
			if str(tf.cls) != cls or Trifles.gone(Game, tf):
				continue
			var spot: Vector2i = tf.tile + Vector2i(0, 1)
			if not w.tile_free(spot) or w.ent_at(spot) != null or not w.building_at(spot).is_empty() or w.ent_at(tf.tile) != null:
				continue
			if seen and Manners.watchers(Game, lw, tf.tile, 4).is_empty():
				continue
			return tf
		return {}
	var stand := func(spot: Vector2i, face: Vector2i) -> void:
		main.set_stack(["world"])
		w.open_world()
		w.enter_layer("surface")
		w.teleport(spot, "surface")
		w.facing = face
		w.cam_q = w.FWD.find(face) if w.FWD.find(face) >= 0 else 0
		w._snap_cam()
		w.banner_t = 0.0
		quiet.call()
	if want.call("street"):
		var best := {}
		var bn := 0
		for h0 in [9.0, 10.5, 15.0, 17.0]:
			for cls0 in ["keep", "ware", "lost"]:
				var t0: Dictionary = thing.call(cls0, h0, true)
				if not t0.is_empty():
					var n0 := Manners.watchers(Game, lw, t0.tile, 5).size()
					if n0 > bn:
						bn = n0
						best = {"t": t0, "h": h0}
		if not best.is_empty():
			Game.clock = float(best.h) * 60.0
			# (seen from the side: straight on, he stands in front of it)
			stand.call(best.t.tile + Vector2i(0, 1), Vector2i(1, 0))
			w.facing = Vector2i(0, -1)
			await _wait(2.4)
			await _shot("trifles_in_the_street")
			main.offer_trifle(best.t)
			await _wait(0.6)
			await _shot("trifle_choice")
			main.set_stack(["world"])
	if want.call("owner"):
		for h1 in [9.0, 10.5, 15.0, 17.0, 8.0, 12.0]:
			Game.clock = h1 * 60.0
			var got := {}
			for tf1 in Trifles.stood(lw, "village"):
				if str(tf1.cls) != "keep" or not w.tile_free(tf1.tile + Vector2i(0, 1)):
					continue
				if not Manners.find(Manners.watchers(Game, lw, tf1.tile, 5), str(tf1.owner)).is_empty():
					got = tf1
					break
			if got.is_empty():
				continue
			stand.call(got.tile + Vector2i(0, 1), Vector2i(0, -1))
			await _wait(2.0)
			var seen1 := Manners.watchers(Game, lw, got.tile, 5)
			var r1: Dictionary = Trifles.take(Game, lw, got, "pocket", seen1)
			w.start_gesture("offer")
			w.folk_talking = str(got.owner)
			main.say([[str(r1.react.who), str(r1.react.line), str(r1.react.clip)]])
			main.dialogue.shown = 999.0
			await _wait(0.7)
			await _shot("trifle_owner_says")
			main.set_stack(["world"])
			w.folk_talking = ""
			Trifles.put_back(Game, str(got.id))
			break
	if want.call("door"):
		Game.clock = 10.0 * 60.0
		var lt: Dictionary = Trifles.lost(lw, "village", int(Game.day))[0]
		stand.call(lt.tile + Vector2i(0, 1), Vector2i(1, 0))
		w.facing = Vector2i(0, -1)
		await _wait(1.6)
		await _shot("lost_in_the_road")
		Trifles.take(Game, lw, lt, "take", [])
		var dspot: Vector2i = lt.door
		for d0 in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			if w.tile_free(lt.door + d0) and w.building_at(lt.door + d0).is_empty():
				dspot = lt.door + d0
				stand.call(dspot, -d0)
				break
		await _wait(1.2)
		w._at_door()
		main.dialogue.shown = 999.0
		await _wait(0.6)
		await _shot("brought_to_the_door")
		main.dialogue.idx = 1 if "idx" in main.dialogue else 0
		main.set_stack(["world"])
	# somebody of Qingshi out of doors and standing, with open ground south of them
	var find := func(h: float, ok: Callable) -> Dictionary:
		Game.clock = h * 60.0
		for fp in Folk.people(lw, "qingshi"):
			if not ok.call(fp):
				continue
			var st: Dictionary = Folk.state(lw, fp, Game.clock)
			if not bool(st.vis) or bool(st.walk):
				continue
			var gt := Vector2i(int(floor(float(st.at.x))), int(floor(float(st.at.y))))
			var ok2 := true
			for dd in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]:
				if not w.tile_free(gt + dd) or w.ent_at(gt + dd) != null or not w.building_at(gt + dd).is_empty():
					ok2 = false
			if ok2:
				return {"p": fp, "at": gt}
		return {}
	if want.call("blade"):
		for h2 in [10.4, 15.0, 9.0, 17.0]:
			var f2: Dictionary = find.call(h2, func(q: Dictionary) -> bool: return not bool(q.kid))
			if f2.is_empty():
				continue
			stand.call(f2.at + Vector2i(0, 2), Vector2i(1, 0))
			await _wait(2.4)
			w.strike()
			await _wait(0.45)
			await _shot("street_answers_a_blade")
			break
	if want.call("leap"):
		for h3 in [10.4, 15.0, 9.0, 16.0, 12.0]:
			var f3: Dictionary = find.call(h3, func(q: Dictionary) -> bool: return bool(q.kid))
			if f3.is_empty():
				continue
			stand.call(f3.at + Vector2i(0, 2), Vector2i(1, 0))
			await _wait(2.4)
			w.jump()
			w._move(0.01)
			await _wait(0.42)
			await _shot("jump_in_the_street")
			await _wait(0.45)
			await _shot("the_street_on_a_jump")
			await _wait(1.2)
			# and a leap of two tiles, caught at the top
			for d3 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
				if w.leap_to(d3).x >= 0:
					w.move_dir = d3
					w.jump()
					w._move(0.01)
					w.move_dir = Vector2i.ZERO
					await _wait(0.2)
					await _shot("leap_of_two_tiles")
					break
			break
	if want.call("leapover"):
		# a leap of two tiles over something lying in the road, caught at the top, from the side
		Game.clock = 10.0 * 60.0
		for tf9 in Trifles.of_area(Game, lw, "village"):
			var dn := false
			for d9 in [Vector2i(1, 0), Vector2i(-1, 0)]:
				var from9: Vector2i = tf9.tile - d9
				var ok9 := not Trifles.gone(Game, tf9) and w.ent_at(tf9.tile) == null
				for q9 in [from9, tf9.tile, tf9.tile + d9, from9 + Vector2i(0, 1), tf9.tile + Vector2i(0, 1), tf9.tile + Vector2i(0, 2)]:
					if not w.tile_free(q9) or w.ent_at(q9) != null or not w.building_at(q9).is_empty():
						ok9 = false
				if not ok9:
					continue
				stand.call(from9, Vector2i(0, -1))
				w.facing = d9
				await _wait(2.0)
				if w.leap_to(d9).x < 0:
					continue
				w.move_dir = d9
				w.jump()
				w._move(0.01)
				w.cam_q = 0
				w.move_dir = Vector2i.ZERO
				await _wait(0.2)
				await _shot("leap_of_two_tiles")
				dn = true
				break
			if dn:
				break
	if want.call("bump"):
		for h4 in [10.4, 15.0, 9.0, 17.0]:
			var f4: Dictionary = find.call(h4, func(q: Dictionary) -> bool: return not bool(q.kid) and str(q.role) != Giants.ROLE)
			if f4.is_empty():
				continue
			stand.call(f4.at + Vector2i(0, 1), Vector2i(0, -1))
			await _wait(2.4)
			var fn: Node3D = w.folk_nodes.get(str(f4.p.id))
			if fn == null:
				continue
			w.target = w.ptile + Vector2i(0, -1)
			w._bump(fn, f4.p)
			w.target = w.ptile
			await _wait(0.5)
			await _shot("walked_into")
			break
	if want.call("cross"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_belts"]
		main.ask_crossroads()
		main.choice.cursor = 0
		await _wait(1.0)
		await _shot("crossroads_belts")
		main.pop()
		Game.cross_pending = []
	if want.call("battles"):
		for bb in [["the_find", "yanggu"], ["the_dusk", "dunes"], ["the_bell", "buzhou"]]:
			main.set_stack(["world"])
			var b = main.battle
			b.start([{"id": str(bb[0]), "lv": int(Data.ENEMIES[str(bb[0])].get("lv", 116))}], {"boss": true, "theme": str(Data.AREAS[str(bb[1])].theme), "area": str(bb[1])})
			main.push("battle")
			await _wait(3.0)
			await _shot("battle_boss_" + str(bb[0]))
			main.pop()
	get_tree().quit(0)

## The Uncarved Block release (--block, or --block=a,b): every rite of the seventeen Daos caught at a beat of its
## scene, the things they are done with in a row, the Root & Rites page for a root of one phase and of five, the
## creation screen at the root's row, the street answering a root and a road, and the people, foes, lords and
## marks of Part XXXV with its crossroads.
func _block_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 118
	Game.step = Data.step_index("s_p35_gate") if Data.step_index("s_p35_gate") >= 0 else Data.STEPS.size() - 2
	Game.companion = true
	Game.day = 240
	Game.stones = 5000
	Game.dao = "sword"
	for d0 in Data.DAO_ORDER:
		Game.dao_xp[d0] = 40
	for a0 in Arms.ORDER:
		Game.arms[a0] = true
		Game.arm_xp[a0] = 40
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
		Game.rite_due = []
	quiet.call()
	w.open_world()
	w.enter_layer("surface")
	# open ground: a tile with nothing within four tiles of it
	var spot: Vector2i = w.ptile
	var found := false
	for rr in range(2, 60):
		for dx in range(-rr, rr + 1, 2):
			for dy in [-rr, rr]:
				var q: Vector2i = w.ptile + Vector2i(dx, dy)
				var ok := true
				for ax in range(-4, 5):
					for ay in range(-4, 5):
						var q2 := q + Vector2i(ax, ay)
						if not w.tile_free(q2) or w.ent_at(q2) != null or not w.building_at(q2).is_empty():
							ok = false
							break
					if not ok:
						break
				if ok:
					spot = q
					found = true
					break
			if found:
				break
		if found:
			break
	var stand := func() -> void:
		main.set_stack(["world"])
		w.teleport(spot, "surface")
		w.facing = Vector2i(0, 1)
		w.cam_q = 0
		w._snap_cam()
		w.banner_t = 0.0
		Game.clock = 10.5 * 60.0
		quiet.call()
	if want.call("props"):
		for row in [["road", "rite_props_roads"], ["arm", "rite_props_arms"], ["taboo", "rite_props_forbidden"]]:
			var ms: Array = []
			for rid in Rites.ORDER:
				if str(Rites.RITES[rid].kind) == str(row[0]):
					var pm := Rites.prop(str(rid))
					Rites.tick(pm, str(rid), 0.8, 2.0)
					# (each shown at about the same size: a field of eight flags beside a lamp held in two hands)
					var sc: float = float({"bagua_field": 0.3, "sword_wheel": 0.55, "peng_feather": 0.75, "straw_butt": 0.7, "soul_banner": 0.5, "hung_scroll": 0.6, "plumb_line": 0.6, "hung_coin": 0.6,
						"moon_mirror": 0.75, "candle": 0.95, "nine_reeds": 0.8, "bamboo_stake": 0.75, "leaf_ring": 0.38, "corpse_bell": 0.8, "lotus_lamp": 2.6, "cauldron": 1.5, "blood_bowl": 2.4}.get(str(Rites.RITES[rid].prop), 1.0))
					pm.scale = Vector3.ONE * sc
					var hold := Node3D.new()
					hold.add_child(pm)
					ms.append(hold)
			await _gallery(str(row[1]), ms, 1.5, 0.3)
	if want.call("rites"):
		stand.call()
		await _wait(1.0)
		var t00 := Time.get_ticks_msec()
		for rid in Rites.ORDER:
			if main.args.has("rite") and not str(main.args.rite).split(",").has(str(rid)):
				continue
			main.set_stack(["world"])
			Game.taboo = {}
			if str(Rites.RITES[rid].kind) == "taboo":
				Game.taboo[str(Rites.RITES[rid].key)] = 1
			main.play_rite(str(rid))
			# (the beat that shows the thing done: --beat=k for another; each caught late in its form)
			var bi := int(main.args.get("beat", 1))
			main.dialogue.idx = bi
			main.dialogue.shown = 9999.0
			await _wait(0.2)
			# (caught late in the form, when the thing has happened: the form and what it is done with are set
			# that far along at once, since every frame of a software renderer is seconds)
			var along := Rites.SECONDS * float(main.args.get("at", 0.66))
			w.rite_t0 = w.t - along
			Models.act(w.player, str(Rites.RITES[rid].clip), w.t - along)
			w.cine_k = 1.0
			await _wait(0.7)
			await _shot("rite_%s%s" % [str(rid), ("_%d" % bi) if main.args.has("beat") else ""])
			main.set_stack(["world"])
			w.rite_end()
			Game.taboo = {}
			await _wait(0.3)
		print("[tour] rites took ", (Time.get_ticks_msec() - t00) / 1000.0)
	if want.call("page"):
		for rn in [1, 5]:
			stand.call()
			Game.hero["root"] = rn
			Game.hero["root_el"] = "fire"
			Game.rites = {"sword": 1, "a_staff": 2, "heart": 1}
			main.open_menu()
			main.menu.mode = "rites"
			main.menu.cursor = 0
			main.menu._build()
			await _wait(0.8)
			await _shot("root_and_rites_%d" % rn)
			main.pop()
		Game.hero.erase("root")
		Game.hero.erase("root_el")
	if want.call("people"):
		await _gallery("part35_people", [Assets.person("zeng_shen"), Assets.person("fang_zhongyong"), Assets.person("carpenter_shi"), Assets.person("bian_he")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid in ["shown_verse", "guest_seat", "idle_slate", "inked_line", "squared_log", "use_adze", "court_eye", "plain_rind", "fraud_writ"]:
			fs.append(_foe(fid))
		await _gallery("part35_foes", fs, 1.0, 0.25)
		await _gallery("part35_lords", [_foe("the_gift", true), _foe("the_rule", true), _foe("the_appraiser", true)], 1.3, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["keep", "cut", "bury"]:
			mk.append(Marks.model(Marks.MARKS.the_stone[oid], 0))
		await _gallery("part35_marks", mk, 1.2, 0.3)
	if want.call("street"):
		# somebody of Qingshi out of doors and standing, with open ground south of them: their fourth word, of a
		# Heavenly Root and of a waste root; and their word for a road walked and for none
		var lw := Atlas.world_of("surface")
		for sh in [["street_answers_root_1", 1, 3, "sword"], ["street_answers_root_5", 5, 3, "sword"], ["street_answers_no_dao", 3, 6, ""], ["street_answers_dao", 3, 6, "heart"]]:
			var done_s := false
			for h2 in [10.4, 15.0, 9.0, 16.0, 12.0]:
				Game.clock = h2 * 60.0
				for fp in Folk.people(lw, "qingshi"):
					if bool(fp.kid) != (str(sh[0]) == "street_answers_root_5"):
						continue
					var st: Dictionary = Folk.state(lw, fp, Game.clock)
					if not bool(st.vis) or bool(st.walk):
						continue
					var gt := Vector2i(int(floor(float(st.at.x))), int(floor(float(st.at.y))))
					var ok2 := true
					for dd in [Vector2i(0, 1), Vector2i(0, 2)]:
						if not w.tile_free(gt + dd) or w.ent_at(gt + dd) != null or not w.building_at(gt + dd).is_empty():
							ok2 = false
					if not ok2:
						continue
					print("[tour] street: ", fp.n, " at ", gt, " hour ", h2)
					main.set_stack(["world"])
					w.teleport(gt + Vector2i(0, 1), "surface")
					w.facing = Vector2i(0, -1)
					w.cam_q = 0
					w._snap_cam()
					w.banner_t = 0.0
					quiet.call()
					Game.hero["root"] = int(sh[1])
					Game.hero["root_el"] = "fire"
					Game.dao = str(sh[3])
					# (the word that is about his root for this person, or about his road)
					var want_root: bool = str(sh[0]).contains("root")
					var wn2 := 3 if (want_root == (int(fp.seed) % 2 == 0)) else 6
					Game.folk_talk[str(fp.id)] = wn2
					await _wait(0.7)
					main.talk_folk({"kind": "folk", "id": "folk:" + str(fp.id), "p": fp, "pos": gt})
					main.dialogue.shown = 999.0
					await _wait(0.9)
					quiet.call()
					await _wait(0.1)
					await _shot(str(sh[0]))
					main.set_stack(["world"])
					w.folk_talking = ""
					done_s = true
					break
				if done_s:
					break
		Game.hero.erase("root")
		Game.hero.erase("root_el")
		Game.dao = "sword"
	if want.call("cross"):
		main.set_stack(["world"])
		Game.picks = {}
		Game.cross_pending = ["the_stone"]
		main.ask_crossroads()
		main.choice.cursor = 0
		await _wait(1.0)
		await _shot("crossroads_stone")
		main.pop()
		Game.cross_pending = []
	if want.call("battles"):
		for bb in [["the_gift", "maple"], ["the_rule", "garden"], ["the_appraiser", "jasper"]]:
			main.set_stack(["world"])
			var b = main.battle
			b.start([{"id": str(bb[0]), "lv": int(Data.ENEMIES[str(bb[0])].get("lv", 119))}], {"boss": true, "theme": str(Data.AREAS[str(bb[1])].theme), "area": str(bb[1])})
			main.push("battle")
			await _wait(3.0)
			await _shot("battle_boss_" + str(bb[0]))
			main.pop()
	if want.call("create"):
		for rn2 in [1, 5]:
			main.set_stack(["title"])
			main.open_creation()
			main.create.h["root"] = rn2
			main.create.h["root_el"] = "fire" if rn2 == 1 else "wood"
			main.create.cursor = main.create.ROWS.find("root")
			await _wait(1.0)
			await _shot("create_root_%d" % rn2)
		main.set_stack(["world"])
	get_tree().quit(0)


## The Higher Sky release: the three who stand above him at the back of their caves (betters.gd), the choice in
## front of one of them, a bout and the fourth end of a battle, a page read out and the book of pages
## (memoir.gd), and the people, foes and marks of Part XXXVIII.
func _sky_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 126
	Game.step = Data.step_index("s_p38_fuchai")
	Game.companion = true
	Game.day = 270
	Game.stones = 96000
	Game.dao = "sword"
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
	# (the hero two tiles in front of a lord of a cave, looking at him)
	var before := func(area: String, id: String) -> Dictionary:
		var fid := Caves.fid(area, -1)
		var cw: Dictionary = Atlas.world_of(fid)
		for e in cw.get("ents", []):
			if str(e.get("id", "")) != "boss_" + id:
				continue
			for d in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
				var t1: Vector2i = e.pos + d
				var t2: Vector2i = e.pos + d * 2
				if t2.x < 0 or t2.y < 0 or t2.x >= int(cw.w) or t2.y >= int(cw.h):
					continue
				if MapGen.is_walkable_tile(cw.grid[t1.y * int(cw.w) + t1.x]) and MapGen.is_walkable_tile(cw.grid[t2.y * int(cw.w) + t2.x]):
					w.enter_layer(fid)
					w.teleport(t2, fid)
					w.facing = -d
					w.cam_q = maxi(0, w.FWD.find(-d))
					w._snap_cam()
					w.banner_t = 0.0
					return e
		return {}
	if want.call("stand"):
		for bb in [["dragon", "fuchai"], ["maple", "pang_juan"], ["terraces", "lian_po"]]:
			main.set_stack(["world"])
			Game.step = Data.step_index("s_p38_home") + 1
			var e0: Dictionary = before.call(str(bb[0]), str(bb[1]))
			if e0.is_empty():
				continue
			quiet.call()
			await _wait(1.0)
			quiet.call()
			await _shot("better_stands_" + str(bb[1]))
	if want.call("choice"):
		main.set_stack(["world"])
		Game.step = Data.step_index("s_p38_fuchai")
		Game.watched = {"fuchai": 1}
		Game.watch_on = {}
		var e1: Dictionary = before.call("dragon", "fuchai")
		if not e1.is_empty():
			quiet.call()
			await _wait(0.6)
			main.meet_better(e1)
			main.choice.cursor = 1
			await _wait(0.8)
			await _shot("better_choice")
			main.pop()
		Game.watched = {}
	if want.call("battles"):
		for bt in [["fuchai", "dragon"], ["pang_juan", "maple"], ["lian_po", "terraces"]]:
			main.set_stack(["world"])
			var b = main.battle
			b.start([Betters.foe(Game, str(bt[0]))], {"boss": true, "enemy": str(bt[0]), "better": str(bt[0]), "theme": str(Data.AREAS[str(bt[1])].theme), "area": str(bt[1]), "path_kind": "Above you", "path_n": "%d realms" % Betters.gap(Game, str(bt[0])),
				"entity": {"kind": "boss", "id": "boss_" + str(bt[0]), "enemy": str(bt[0]), "area": str(bt[1]), "pos": Vector2i.ZERO}})
			main.push("battle")
			await _wait(3.2)
			await _shot("battle_better_" + str(bt[0]))
			if str(bt[0]) == "fuchai":
				b._bested(false)
				await _wait(1.6)
				await _shot("battle_bested")
			main.pop()
	if want.call("pages"):
		main.set_stack(["world"])
		w.load_area("sect", Vector2i(20, 9))
		w.banner_t = 0.0
		Game.bested = {"fuchai": {"first": "lost", "last": "lost", "base": 138, "day": 268, "took": 48000, "wound": true, "bouts": 1}}
		for pid in Memoir.ORDER:
			if Memoir.open(Game, pid) and Data.step_index(str(Memoir.PAGES[pid].after)) <= Data.step_index("s_p38_fuchai"):
				Game.pages[pid] = 3 + 7 * Game.pages.size()
		quiet.call()
		await _wait(0.6)
		main.say(Memoir.lines(Game, "p38_fuchai_down_lin"))
		await _wait(7.0)
		await _shot("page_stables")
		main.pop()
		main.say(Memoir.lines(Game, "p38_fuchai_down_yue").slice(1))
		await _wait(9.0)
		await _shot("page_wall")
		main.pop()
		main.open_menu()
		main.menu.mode = "words"
		main.menu._build()
		main.menu.cursor = main.menu.ids.find("page:p38_fuchai_down_lin")
		await _wait(0.6)
		await _shot("words_book")
		main.menu.cursor = main.menu.ids.find("page:p15_woven")
		await _wait(0.4)
		await _shot("words_book_yue")
		main.pop()
	if want.call("people"):
		await _gallery("part38_people", [Assets.person("goujian"), Assets.person("sun_bin"), Assets.person("lin_xiangru")], 0.5, 0.2)
		await _gallery("part38_betters", [Assets.person("fuchai"), Assets.person("pang_juan"), Assets.person("lian_po")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid2 in ["stable_fork", "tribute_chest", "hung_gall", "counted_fire", "forced_march", "barked_tree", "barred_lane", "old_scar", "turned_cart"]:
			fs.append(_foe(fid2))
		await _gallery("part38_foes", fs, 1.0, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["gall", "ditch", "road"]:
			mk.append(Marks.model(Marks.MARKS.the_higher_sky[oid], 0))
		await _gallery("part38_marks", mk, 1.6, 0.3)
	if want.call("cross"):
		main.set_stack(["world"])
		Game.picks.erase("the_higher_sky")
		Game.cross_pending = ["the_higher_sky"]
		main.ask_crossroads()
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("crossroads_higher_sky")
		main.pop()
		Game.cross_pending = []
	get_tree().quit(0)

## The Red Seal release: the desk of the Hall of Seals (seals.gd), the lists and words across a ring (lists.gd),
## an auction room (auction.gd), what else the post carries (mail.gd), and the people, foes and marks of Part XXXIX.
func _seal_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 130
	Game.step = Data.step_index("s_p39_papers")
	Game.companion = true
	Game.day = 300
	Game.stones = 96000
	Game.dao = "sword"
	Game.dao_xp = {"sword": 60, "heart": 14}
	Game.arm_xp = {"sword": 120, "staff": 20, "spear": 30}
	Game.arms = {"sword": true, "staff": true, "spear": true}
	for a9 in ["village", "longmen", "tushan", "yanggu", "mountain"]:
		Game.seen[a9] = true
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
	var counter := func(office: String) -> Dictionary:
		return {"kind": "office", "id": office, "office": office, "n": str(Offices.OFFICES[office].n), "area": str(Offices.OFFICES[office].area), "pos": Vector2i.ZERO}
	if want.call("desk"):
		w.load_area("sect", Vector2i(20, 9))
		w.banner_t = 0.0
		quiet.call()
		await _wait(0.8)
		main.offer_carriage(counter.call("treasurer"))
		main.choice.cursor = maxi(0, main.choice.ids().find("seals"))
		await _wait(0.8)
		await _shot("counter_red_seal")
		main.pop()
		Game.seals = {"sword": {"grade": 2, "day": 298}, "t_blood": {"grade": 1, "day": 298}}
		main.offer_seals(counter.call("treasurer"))
		main.choice.cursor = maxi(0, main.choice.ids().find("a_sword"))
		await _wait(0.8)
		await _shot("seal_desk")
		main.pop()
		main.say(Seals.sit(Game, "a_sword", "sect"))
		await _wait(5.0)
		await _wait(2.0)
		await _shot("seal_sealed")
		main.pop()
	if want.call("page"):
		main.set_stack(["world"])
		Game.seals = {}
		for sid in Seals.order():
			if Seals.due(Game, sid) > 0 and sid != "t_husk":
				Game.seals[sid] = {"grade": Seals.due(Game, sid), "day": 290 + Game.seals.size()}
		Game.meets = {"outer": {"round": 3, "day": 296, "place": 1, "crowd": 2, "best": 1, "times": 1, "said": {}}, "arms": {"round": 1, "day": 300, "place": 0, "crowd": 1, "best": 0, "times": 1, "said": {}}}
		Game.bouts = 4
		Game.bouts_won = 4
		Game.words_said = 3
		Game.purses = 13920
		Game.lots_won = 2
		Game.lot_spent = 2417
		Game.lot_saved = 310
		Game.inv["curio_inkstone"] = 1
		main.open_menu()
		main.menu.mode = "seals"
		main.menu._build()
		await _wait(0.6)
		await _shot("seals_page")
		main.pop()
	if want.call("board"):
		main.set_stack(["world"])
		w.load_area("yanggu", Vector2i(34, 32))
		w.banner_t = 0.0
		Game.meets = {"outer": {"round": 3, "day": 296, "place": 1, "crowd": 2, "best": 1, "times": 1, "said": {}}}
		Game.seals["a_sword"] = {"grade": 3, "day": 298}
		quiet.call()
		await _wait(0.8)
		main.offer_lists(counter.call("warden_yanggu"), "arms")
		main.choice.cursor = 1
		await _wait(0.8)
		await _shot("lists_board")
		main.pop()
	if want.call("bouts"):
		for bt in [["outer", 2, "sect"], ["arms", 2, "yanggu"], ["schools", 2, "tushan"], ["schools", 1, "tushan"]]:
			main.set_stack(["world"])
			var b = main.battle
			var rid := str(Lists.MEETS[str(bt[0])].rivals[int(bt[1])])
			Game.heal_full()
			Game.meets[str(bt[0])] = {"round": int(bt[1]), "day": 300, "place": 0, "crowd": 0, "best": 0, "times": 1, "said": {}}
			b.start([Lists.foe(Game, str(bt[0]), int(bt[1]))], {"entity": counter.call(str(Lists.MEETS[str(bt[0])].office)), "boss": bool(Data.ENEMIES[rid].get("boss", false)), "enemy": rid, "meet": str(bt[0]), "round": int(bt[1]), "theme": str(Data.AREAS[str(bt[2])].theme), "area": str(bt[2]), "path_kind": "The lists", "path_n": str(Lists.ROUNDS[int(bt[1])].n)})
			main.push("battle")
			await _wait(3.4)
			await _shot("bout_" + rid)
			if rid == "deng_xi":
				b.cur = b.party[0]
				b.state = "menu"
				b._open_main()
				b.cursor = b.ids.find("words")
				await _wait(0.5)
				await _shot("bout_menu")
				b._open_words()
				b.cursor = 1
				await _wait(0.5)
				await _shot("bout_words")
				b._say_word("boast")
				await _wait(0.7)
				await _shot("bout_said")
				b._out(false)
				await _wait(1.6)
				await _shot("bout_out")
			main.pop()
	if want.call("room"):
		main.set_stack(["world"])
		w.load_area("village", Vector2i(30, 30))
		w.banner_t = 0.0
		Game.lots = {}
		Game.lot_at = {}
		quiet.call()
		await _wait(0.8)
		main.offer_room(counter.call("head_qingshi"), "qingshi")
		main.choice.cursor = 1
		await _wait(0.8)
		await _shot("auction_room")
		main.pop()
		var lot: Dictionary = Auction.lots(Game, "qingshi")[1]
		Auction.bid(Game, "qingshi", lot, Auction.next_bid(Game, "qingshi", lot))
		main.bid_on(counter.call("head_qingshi"), "qingshi", 1)
		main.choice.cursor = 1
		await _wait(0.8)
		await _shot("auction_bid")
		main.pop()
	if want.call("post"):
		main.set_stack(["world"])
		w.load_area("village", Vector2i(30, 30))
		w.banner_t = 0.0
		Game.inv["timber"] = 6
		Game.wrote = {"wen": {"day": 290, "n": 1, "read": false}}
		Game.parcels = [{"item": "curio_carp", "n": 1, "from": "The Tide Hammer of Longmen"}]
		quiet.call()
		await _wait(0.8)
		main.offer_post(counter.call("head_qingshi"))
		main.choice.cursor = 2
		await _wait(0.8)
		await _shot("post_more")
		main.pop()
		main.say(Mail.read_answer(Game, "wen"))
		await _wait(5.0)
		await _shot("post_answer")
		main.pop()
		main.offer_sealed(counter.call("head_qingshi"), "tushan")
		main.choice.cursor = 2
		await _wait(0.8)
		await _shot("post_sealed_bid")
		main.pop()
	if want.call("people"):
		await _gallery("part39_people", [Assets.person("deng_xi"), Assets.person("hui_shi"), Assets.person("gongsun_long")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid2 in ["straw_champion", "scroll_form", "empty_title", "turnip_stamp", "sold_name", "ink_blot", "white_not_horse", "feathered_egg", "halved_stick"]:
			fs.append(_foe(fid2))
		await _gallery("part39_foes", fs, 1.0, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["open", "strict", "blank"]:
			mk.append(Marks.model(Marks.MARKS.the_red_seal[oid], 0))
		await _gallery("part39_marks", mk, 1.6, 0.3)
	if want.call("cross"):
		main.set_stack(["world"])
		Game.step = Data.step_index("s_p39_roll") + 1
		Game.picks.erase("the_red_seal")
		Game.cross_pending = ["the_red_seal"]
		main.ask_crossroads()
		main.choice.cursor = 1
		await _wait(1.0)
		await _shot("crossroads_red_seal")
		main.pop()
		Game.cross_pending = []
	get_tree().quit(0)

## The Two Roads release: the table of leaves (yezi.gd, leaves.gd), walking two roads (braid.gd), the fuller
## towns (folk.gd MORE), and the people, foes and marks of Part XL.
func _roads_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 133
	Game.step = Data.step_index("s_p40_zhen")
	Game.companion = true
	Game.day = 320
	Game.stones = 101000
	Game.dao = "sword"
	Game.dao_xp = {"sword": 60, "heart": 14, "formation": 3}
	for a9 in ["village", "longmen", "tushan", "yanggu", "mountain"]:
		Game.seen[a9] = true
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
	var counter := func(office: String) -> Dictionary:
		return {"kind": "office", "id": office, "office": office, "n": str(Offices.OFFICES[office].n), "area": str(Offices.OFFICES[office].area), "pos": Vector2i.ZERO}
	if want.call("table"):
		w.load_area("yanggu", Vector2i(34, 32))
		w.banner_t = 0.0
		quiet.call()
		await _wait(0.3)
		main.offer_carriage(counter.call("warden_yanggu"))
		main.choice.cursor = maxi(0, main.choice.ids().find("leaves"))
		await _wait(0.3)
		await _shot("counter_leaves")
		main.pop()
		Game.cards = {"du_outer": {"won": 1, "lost": 1, "beat_day": 300}}
		Game.leaves = {"du_outer": true}
		Game.leaf = "du_outer"
		main.offer_leaves(Yezi.at("warden_yanggu"))
		main.choice.cursor = 1
		await _wait(0.3)
		await _shot("leaves_sit")
		main.pop()
		Game.card_n = 4
		main.leaves.start(Yezi.foe("zhen_lantern"), {})
		main.push("leaves")
		await _wait(0.2)
		for k in 3:
			main.leaves.cursor = main.leaves.want()
			main.leaves.press("confirm")
			main.leaves.press("confirm")
			await _wait(0.1)
		main.leaves.cursor = main.leaves.want()
		await _wait(0.15)
		await _shot("leaves_round")
		main.leaves.press("confirm")
		await _wait(0.2)
		await _shot("leaves_trick")
		main.pop()
		main.leaves.state = "idle"
		Game.card_n = 9
		main.leaves.start(Yezi.foe("ju_gong"), {})
		main.push("leaves")
		await _wait(0.2)
		for k2 in 3:
			main.leaves.cursor = main.leaves.want()
			main.leaves.press("confirm")
			await _wait(0.3)
		main.leaves.cursor = main.leaves.want()
		await _wait(0.15)
		await _shot("leaves_morning")
		main.leaves.press("confirm")
		await _wait(0.2)
		await _shot("leaves_morning_shown")
		main.pop()
		main.leaves.state = "idle"
		Game.card_hands = 7
		Game.card_wins = 4
		Game.card_tea = 1656
		Game.cards = {"du_outer": {"won": 2, "lost": 1}, "zhen_lantern": {"won": 1, "lost": 2}, "ban_netloft": {"won": 1, "lost": 0}}
		Game.leaves = {"du_outer": true, "zhen_lantern": true, "ban_netloft": true}
		main.push("menu")
		main.menu.mode = "leaves"
		main.menu._build()
		main.menu.cursor = 1
		await _wait(0.3)
		await _shot("page_leaves")
		main.pop()
	if want.call("stele"):
		main.set_stack(["world"])
		w.load_area("sect", Vector2i(16, 12))
		w.banner_t = 0.0
		quiet.call()
		Game.braid = []
		await _wait(0.3)
		main.offer_braid("heart")
		main.choice.cursor = 1
		await _wait(0.3)
		await _shot("stele_two_roads")
		main.pop()
		Braid.take(Game, "heart")
		Braid.take(Game, "formation")
		Game.rite_due = []
		quiet.call()
		main.push("menu")
		main.menu.mode = "dao"
		main.menu._build()
		await _wait(0.3)
		await _shot("page_three_roads")
		main.pop()
	if want.call("street"):
		Game.rite_due = []
		Game.page_due = []
		Game.done_pending = []
		main.set_stack(["world"])
		Game.clock = 15.9 * 60.0
		w.load_area("yanggu", Vector2i(34, 31))
		w.banner_t = 0.0
		quiet.call()
		await _wait(1.2)
		await _shot("street_fuller_yanggu")
		w.load_area("village", Vector2i(30, 29))
		w.banner_t = 0.0
		quiet.call()
		await _wait(1.2)
		await _shot("street_fuller_qingshi")
	if want.call("plight"):
		# (plights.gd: somebody of Qingshi in the middle of something, and the three things to do about it)
		Game.rite_due = []
		Game.page_due = []
		main.set_stack(["world"])
		w.load_area("village", Vector2i(30, 29))
		w.banner_t = 0.0
		quiet.call()
		await _wait(0.3)
		var shown_p := 0
		for want_id in ["debt", "roof"]:
			for dd in 12:
				for fp2 in Folk.people(Atlas.world_of("surface"), "qingshi"):
					if shown_p < 2 and Plights.of(Game, fp2) == want_id:
						main.offer_plight(fp2, want_id)
						main.choice.cursor = 1 + shown_p
						await _wait(0.3)
						await _shot("plight_" + want_id)
						main.pop()
						shown_p += 1
						break
				if shown_p > (0 if want_id == "debt" else 1):
					break
				Game.day += 1
	if want.call("people"):
		Game.rite_due = []
		Game.page_due = []
		main.set_stack(["world"])
		var lf: Dictionary = {}
		var hw: Dictionary = {}
		var stl: Dictionary = {}
		for fp in Folk.people(Atlas.world_of("surface"), "yanggu"):
			if str(fp.role) == "leafer" and lf.is_empty():
				lf = fp
			elif str(fp.role) == "hawker" and hw.is_empty():
				hw = fp
			elif str(fp.role) == "storyteller" and stl.is_empty():
				stl = fp
		await _gallery("part40_people", [Assets.person("ju_gong"), Folk.model(lf), Folk.model(hw), Folk.model(stl)], 0.5, 0.2)
	if want.call("foes"):
		Game.rite_due = []
		Game.page_due = []
		var fs: Array = []
		for fid2 in ["furious_monkey", "counted_acorn", "morning_three", "marked_leaf", "sleeve_leaf", "faceless_dealer", "forked_shadow", "road_untaken", "two_minded"]:
			fs.append(_foe(fid2))
		await _gallery("part40_foes", fs, 1.0, 0.25)
	if want.call("marks"):
		Game.rite_due = []
		Game.page_due = []
		var mk: Array = []
		for oid in ["one", "two", "ask"]:
			mk.append(Marks.model(Marks.MARKS.the_two_roads[oid], 0))
		await _gallery("part40_marks", mk, 1.6, 0.3)
	if want.call("cross"):
		Game.rite_due = []
		Game.page_due = []
		main.set_stack(["world"])
		Game.step = Data.step_index("s_p40_court") + 1
		Game.picks.erase("the_two_roads")
		Game.cross_pending = ["the_two_roads"]
		main.ask_crossroads()
		main.choice.cursor = 2
		await _wait(0.3)
		await _shot("crossroads_two_roads")
		main.pop()
		Game.cross_pending = []
	get_tree().quit(0)

## The Five Hands release: the work of the hands as it was held and as it is held (grip.gd), the five phases
## turned on a forest's edge and met with one another (phases.gd), what hangs from a hand (heft.gd), and the
## people, foes, lords and marks of Part XXXVII.
func _hands_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 124
	Game.step = Data.step_index("s_p37_council")
	Game.companion = true
	Game.day = 260
	Game.stones = 5000
	Game.dao = "sword"
	for it in ["cook_pot", "trug", "spade", "axe", "pick", "sickle", "fishing_rod"]:
		Game.inv[it] = 1
	for it2 in ["carp", "herb_bundle", "mushrooms", "wild_yam"]:
		Game.inv[it2] = 9
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
		Game.rite_due = []
	quiet.call()
	w.open_world()
	w.enter_layer("surface")
	var wd: Dictionary = Atlas.world_of("surface")
	var W := int(wd.w)
	# a place of region `area` with open ground all round and (if `edge`) the forest three tiles to the south
	var find := func(area: String, edge: bool) -> Vector2i:
		for y in range(8, int(wd.h) - 12):
			for x in range(8, W - 8):
				var q := Vector2i(x, y)
				if Atlas.owner_id(wd, q) != area:
					continue
				var ok := true
				for ax in range(-2 if not edge else -1, 3 if not edge else 2):
					for ay in range(-3, 2):
						var q2 := q + Vector2i(ax, ay)
						if not wd.grid[q2.y * W + q2.x] in [MapGen.FLOOR, MapGen.DECOR] or Atlas.owner_id(wd, q2) != area or w.ent_at(q2) != null or Peaks.rise(wd, float(q2.x) + 0.5, float(q2.y) + 0.5) > 1.5:
							ok = false
				if not ok:
					continue
				if edge:
					for ax2 in range(-1, 2):
						for ay2 in range(2, 6):
							if wd.grid[(y + ay2) * W + x + ax2] != MapGen.WALL:
								ok = false
				else:
					for ax3 in range(-2, 3):
						for ay3 in range(2, 5):
							if not wd.grid[(y + ay3) * W + x + ax3] in [MapGen.FLOOR, MapGen.DECOR] or w.ent_at(Vector2i(x + ax3, y + ay3)) != null:
								ok = false
				if ok:
					return q
		return Vector2i(-1, -1)
	var stand := func(at: Vector2i, q: int = 2) -> void:
		main.set_stack(["world"])
		w.teleport(at, "surface")
		w.facing = Vector2i(0, 1)
		w.cam_q = q
		w._snap_cam()
		w.banner_t = 0.0
		Game.clock = 10.5 * 60.0
		Game.first_person = false
		quiet.call()
	var open_at: Vector2i = find.call("bamboo", false)
	var edge_at: Vector2i = find.call("bamboo", true)
	for ea in ["millet", "forge", "marsh", "village", "maple"]:
		if edge_at.x < 0:
			edge_at = find.call(ea, true)
	if edge_at.x >= 0:
		edge_at += Vector2i(0, 1)
	print("[tour] hands: open ground at %s, a forest's edge at %s" % [str(open_at), str(edge_at)])
	var frames_n := func(n: int) -> void:
		for _f in n:
			await get_tree().process_frame
	var finish := func() -> void:
		if not w.using.is_empty():
			w.using.t0 = w.t - w.USE_STEP * 2.0 - float(w.using.dur) - 0.05
	# the camera a pace and a half from his hands, on his left or his right
	var close := func(side: float, dist: float, up: float) -> void:
		var pp: Vector3 = w.player.position
		var f3 := Vector3(w.facing.x, 0, w.facing.y)
		var sd := Vector3(f3.z, 0, -f3.x) * side
		w.cam_override = Transform3D(Basis.IDENTITY, pp + sd * dist + f3 * 1.0 + Vector3(0, up, 0)).looking_at(pp + f3 * 0.7 + Vector3(0, 0.85, 0), Vector3.UP)
	if want.call("grip") and edge_at.x >= 0 and open_at.x >= 0:
		var frames: Array = []
		for wk in [["fell", edge_at, Vector2i(0, 1), 1.0, 3.0], ["dig", open_at, Vector2i(0, -1), -1.0, 3.0], ["reap", open_at + Vector2i(1, 0), Vector2i(0, -1), -1.0, 2.6]]:
			for mode in ["before", "after"]:
				Grip.plain = mode == "before"
				stand.call(wk[1], 2)
				w.facing = wk[2]
				Game.toiled = {}
				Game.felled = {}
				await frames_n.call(3)
				w.work_want = str(wk[0])
				w.work(str(wk[0]) == "dig")
				if w.using.is_empty():
					print("[tour] hands: no %s here" % str(wk[0]))
					continue
				# (to the moment the tool lands: the stroke is watched for, in both)
				w.using.t0 = w.t - w.USE_STEP - 0.4
				close.call(float(wk[3]), float(wk[4]), 1.4)
				var landed := false
				for _f2 in 30:
					# (a software renderer takes seconds over a frame: the clock is moved on a tenth of a second at a time)
					w.t += 0.1
					await get_tree().process_frame
					w.using.t0 = w.t - w.USE_STEP - 0.6
					var rc = Grip.reach_of(w.using.get("held"))
					if rc != null and rc.down:
						landed = true
						break
				quiet.call()
				await _shot("grip_%s_%s" % [str(wk[0]), mode])
				frames.append(last_img)
				print("[tour] hands: %s %s, landed %s" % [str(wk[0]), mode, str(landed)])
				finish.call()
				w.cam_override = null
				await frames_n.call(4)
		Grip.plain = false
		_sheet("grip_sheet", frames, 0.5)
	if want.call("phases") and edge_at.x >= 0:
		Game.level = 9
		var pf: Array = []
		for el in Phases.ORDER:
			stand.call(edge_at, 2)
			Game.touched = {}
			Game.scars = {}
			w._phase_t = 0.0
			await frames_n.call(4)
			Game.phase = str(el)
			w.strike_t = -9.0
			w.strike()
			await frames_n.call(8)
			quiet.call()
			await _shot("phase_%s_struck" % str(el))
			await frames_n.call(12)
			quiet.call()
			await _shot("phase_%s" % str(el))
			pf.append(last_img)
		_sheet("phases_sheet", pf, 0.36)
		# one phase met with another: fire and then water; blossom and then fire; and the round
		var meets: Array = []
		for sq in [["quench", ["fire", "water"]], ["blaze", ["wood", "fire"]], ["moss", ["earth", "wood"]], ["rain", ["thunder", "water"]], ["round", ["wood", "fire", "earth", "thunder", "water", "wood"]]]:
			stand.call(edge_at, 2)
			Game.touched = {}
			w._phase_t = 0.0
			await frames_n.call(4)
			for el2 in sq[1]:
				Game.phase = str(el2)
				w.strike_t = -9.0
				w.strike()
				await frames_n.call(9)
			await frames_n.call(20)
			quiet.call()
			await _shot("phase_meet_%s" % str(sq[0]))
			meets.append(last_img)
		_sheet("phases_meet_sheet", meets, 0.36)
		Game.phase = ""
		Game.touched = {}
		Game.level = 124
	if want.call("things"):
		var pk: Array = []
		for kd in ["burn", "pool", "sprout", "ridge", "glass", "kiln", "lode", "rain", "grove", "moss"]:
			pk.append(Phases.model(kd, 5, Color("8a7a5a"), Color("4a8a4a")))
		await _gallery("phase_things", pk, 2.4, 0.3)
		var hd: Array = []
		for hn in ["lantern", "pole", "steelyard", "hoe", "rod"]:
			var hm := Folk.held(hn)
			hm.scale = Vector3.ONE * (1.4 if hn in ["pole", "hoe", "rod"] else 2.2)
			hm.position = Vector3(0, 1.4, 0)
			var hh := Node3D.new()
			hh.add_child(hm)
			hd.append(hh)
		await _gallery("held_things", hd, 1.6, 0.3)
	if want.call("people"):
		await _gallery("part37_people", [Assets.person("su_dai"), Assets.person("bai_gui"), Assets.person("cai_yong")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid2 in ["carried_faggot", "thrown_cup", "fed_ember", "raised_dyke", "sent_flood", "drowned_furrow", "deaf_stove", "split_billet", "lost_note"]:
			fs.append(_foe(fid2))
		await _gallery("part37_foes", fs, 1.0, 0.25)
		await _gallery("part37_lords", [_foe("the_fed_fire", true), _foe("the_next_door", true), _foe("the_kindling", true)], 1.3, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["break", "watch", "leave"]:
			mk.append(Marks.model(Marks.MARKS.the_round[oid], 0))
		await _gallery("part37_marks", mk, 1.6, 0.3)
	if want.call("cross"):
		main.set_stack(["world"])
		Game.picks.erase("the_round")
		Game.cross_pending = ["the_round"]
		main.ask_crossroads()
		main.choice.cursor = 0
		await _wait(1.0)
		await _shot("crossroads_round")
		main.pop()
		Game.cross_pending = []
	if want.call("battles"):
		for bb in [["the_fed_fire", "volcano"], ["the_next_door", "drowned"], ["the_kindling", "thunder"]]:
			main.set_stack(["world"])
			var b = main.battle
			b.start([{"id": str(bb[0]), "lv": 125}], {"boss": true, "theme": str(Data.AREAS[str(bb[1])].theme), "area": str(bb[1])})
			main.push("battle")
			await _wait(3.0)
			# (a technique of each of two phases, to see what they leave under the lord: phases.gd)
			if b.foes.size() > 0:
				b._ground_mark(b.foes[0], "fire")
				b._ground_mark(b.party[0] if b.party.size() > 0 else b.foes[0], "water")
			await _wait(0.5)
			await _shot("battle_boss_" + str(bb[0]))
			main.pop()
	get_tree().quit(0)

## The Small Fish release: the twelve things done to a pot, the first-person view, the seven weights of a
## blow, the veins of a cave, the new work of the hands, and the people, foes, lords and marks of Part XXXVI.
func _fish_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 121
	Game.step = Data.step_index("s_p36_table")
	Game.companion = true
	Game.day = 260
	Game.stones = 5000
	Game.dao = "sword"
	for it in ["cook_pot", "trug", "spade", "axe", "pick", "sickle", "fishing_rod"]:
		Game.inv[it] = 1
	for it2 in ["carp", "herb_bundle", "mushrooms", "wild_yam"]:
		Game.inv[it2] = 9
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
		Game.rite_due = []
	quiet.call()
	w.open_world()
	w.enter_layer("surface")
	var wd: Dictionary = Atlas.world_of("surface")
	var W := int(wd.w)
	# a place of region `area` with open ground all round and (if `edge`) the forest three tiles to the south
	var find := func(area: String, edge: bool) -> Vector2i:
		for y in range(8, int(wd.h) - 12):
			for x in range(8, W - 8):
				var q := Vector2i(x, y)
				if Atlas.owner_id(wd, q) != area:
					continue
				var ok := true
				for ax in range(-2 if not edge else -1, 3 if not edge else 2):
					for ay in range(-3, 2):
						var q2 := q + Vector2i(ax, ay)
						if not wd.grid[q2.y * W + q2.x] in [MapGen.FLOOR, MapGen.DECOR] or Atlas.owner_id(wd, q2) != area or w.ent_at(q2) != null or Peaks.rise(wd, float(q2.x) + 0.5, float(q2.y) + 0.5) > 1.5:
							ok = false
				if not ok:
					continue
				if edge:
					for ax2 in range(-1, 2):
						for ay2 in range(2, 6):
							if wd.grid[(y + ay2) * W + x + ax2] != MapGen.WALL:
								ok = false
				else:
					for ax3 in range(-2, 3):
						for ay3 in range(2, 5):
							if not wd.grid[(y + ay3) * W + x + ax3] in [MapGen.FLOOR, MapGen.DECOR] or w.ent_at(Vector2i(x + ax3, y + ay3)) != null:
								ok = false
				if ok:
					return q
		return Vector2i(-1, -1)
	var stand := func(at: Vector2i, q: int = 2) -> void:
		main.set_stack(["world"])
		w.teleport(at, "surface")
		w.facing = Vector2i(0, 1)
		w.cam_q = q
		w._snap_cam()
		w.banner_t = 0.0
		Game.clock = 10.5 * 60.0
		Game.first_person = false
		quiet.call()
	var open_at: Vector2i = find.call("bamboo", false)
	var edge_at: Vector2i = find.call("millet", true)
	for ea in ["bamboo", "forge", "marsh", "village", "maple"]:
		if edge_at.x < 0:
			edge_at = find.call(ea, true)
	# (the wall begins two tiles south of what was found: he stands against it)
	if edge_at.x >= 0:
		edge_at += Vector2i(0, 1)
	print("[tour] fish: open ground at %s, a forest's edge at %s" % [str(open_at), str(edge_at)])
	# (a software renderer takes seconds over a frame: every scene below is jumped to the moment that is wanted,
	# by moving the clock of what is being done, and the pot is cooked across the gap by its own arithmetic)
	var frames_n := func(n: int) -> void:
		for _f in n:
			await get_tree().process_frame
	var jump := func(el: float) -> void:
		# what he is doing is `el` seconds in
		if not w.using.is_empty():
			w.using.t0 = w.t - w.USE_STEP - el
	var finish := func() -> void:
		if not w.using.is_empty():
			w.using.t0 = w.t - w.USE_STEP * 2.0 - float(w.using.dur) - 0.05
	if want.call("cook") and open_at.x >= 0:
		stand.call(open_at, 1)
		await frames_n.call(3)
		w.cook_auto = -1
		print("[tour] fish: cook ", w.cook("yam_stew"), " ", w.cook_why())
		var frames: Array = []
		var at := {"lay": 2.6, "light": 1.6, "fan": 2.0, "water": 2.4, "chop": 2.2, "add": 1.55, "boil": 3.2, "simmer": 3.0, "season": 1.2, "taste": 1.5, "serve": 2.2, "eat": 2.2}
		for k in Cooking.STAGES.size():
			if w.cooking.is_empty():
				break
			var st: Dictionary = Cooking.STAGES[k]
			var el: float = float(at[str(st.id)])
			# the pot, cooked up to this moment of this stage
			for _i in int(el * 30.0):
				w.cooking.pot = Cooking.step(w.cooking.pot, 1.0 / 30.0, {"fire": float(st.fire), "fan": str(st.id) == "fan", "lid": bool(st.lid), "stir": 0.8 if str(st.id) == "simmer" else 0.0})
			if str(st.id) == "boil":
				# (until the lid is in the air)
				for _i2 in 240:
					if float(w.cooking.pot.lid_y) > 0.012:
						break
					w.cooking.pot = Cooking.step(w.cooking.pot, 1.0 / 30.0, {"fire": 1.0, "lid": true})
			if str(st.id) == "simmer":
				w.cooking.pokes = 3
				w.cooking.stir_t = w.t
			jump.call(el)
			await frames_n.call(3)
			if str(st.id) == "simmer":
				w.cooking.stir_t = w.t
			quiet.call()
			await _shot("cook_%02d_%s" % [k + 1, str(st.id)])
			frames.append(last_img)
			# the rest of the stage, for the pot
			for _i3 in int(maxf(0.0, float(st.dur) - el) * 30.0):
				w.cooking.pot = Cooking.step(w.cooking.pot, 1.0 / 30.0, {"fire": float(st.fire), "lid": bool(st.lid)})
			finish.call()
			# (what splashed as the last pieces went in has gone before the next is looked at)
			await frames_n.call(16 if str(st.id) == "add" else 2)
		print("[tour] fish: cooked, ", frames.size(), " stages seen")
		_sheet("cook_sheet", frames, 0.3)
		await frames_n.call(3)
		quiet.call()
	if want.call("eyes") and open_at.x >= 0:
		stand.call(open_at, 2)
		Game.first_person = true
		w.cam_q = 2
		w._fp_k = 1.0
		await frames_n.call(8)
		await _shot("first_person_bamboo")
		stand.call(Atlas.to_world("sect", Vector2i(20, 12)), 0)
		Game.first_person = true
		w._fp_k = 1.0
		await frames_n.call(8)
		await _shot("first_person_sect")
		Game.first_person = false
		w._fp_k = 0.0
		await frames_n.call(2)
	if want.call("blow") and edge_at.x >= 0:
		for rk in [0, 3, 6]:
			stand.call(edge_at, 2)
			Game.scars = {}
			Game.felled = {}
			w._sunder_t = 0.0
			await frames_n.call(4)
			Game.level = Data.MAX_LEVEL
			Game.hand = rk if rk < 6 else -1
			w.strike_t = -9.0
			w.strike()
			await frames_n.call(9)
			quiet.call()
			await _shot("blow_%d_struck" % rk)
			await frames_n.call(40)
			quiet.call()
			await _shot("blow_%d_after" % rk)
		Game.hand = -1
		Game.scars = {}
	if want.call("toil") and edge_at.x >= 0:
		stand.call(edge_at, 3)
		w.facing = Vector2i(0, 1)
		w._snap_cam()
		await frames_n.call(3)
		w.work(true)
		jump.call(1.6)
		await frames_n.call(3)
		quiet.call()
		await _shot("toil_pick")
		finish.call()
		await frames_n.call(3)
		stand.call(edge_at + Vector2i(0, -2), 1)
		w.facing = Vector2i(0, -1)
		w._snap_cam()
		await frames_n.call(3)
		w.work(true)
		jump.call(1.5)
		await frames_n.call(3)
		quiet.call()
		await _shot("toil_dig")
		finish.call()
		await frames_n.call(3)
	if want.call("vein"):
		var fid := Caves.fid("forge", -1)
		var cw: Dictionary = Atlas.world_of(fid)
		var vat := Vector2i(-1, -1)
		var vdir := Vector2i.ZERO
		for y2 in int(cw.h):
			for x2 in int(cw.w):
				var q3 := Vector2i(x2, y2)
				if vat.x >= 0 or not MapGen.is_walkable_tile(cw.grid[y2 * int(cw.w) + x2]):
					continue
				for d3 in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
					if Toil.offers(cw, q3, q3 + d3, true, false).has("mine") and MapGen.is_walkable_tile(cw.grid[(y2 + 1) * int(cw.w) + x2]) and MapGen.is_walkable_tile(cw.grid[(y2 + 2) * int(cw.w) + x2]):
						vat = q3
						vdir = d3
						break
		if vat.x >= 0:
			main.set_stack(["world"])
			w.teleport(vat, fid)
			w.facing = vdir
			for cq in 4:
				if w.FWD[cq] == vdir:
					w.cam_q = cq
			w._snap_cam()
			w._sunder_t = 0.0
			quiet.call()
			await frames_n.call(20)
			quiet.call()
			await _shot("cave_vein")
			w.work()
			jump.call(2.2)
			await frames_n.call(3)
			quiet.call()
			await _shot("cave_vein_mined")
			finish.call()
			await frames_n.call(3)
			w.enter_layer("surface")
	if want.call("people"):
		await _gallery("part36_people", [Assets.person("yong_ji"), Assets.person("song_younger"), Assets.person("old_qi")], 0.5, 0.2)
	if want.call("foes"):
		var fs: Array = []
		for fid2 in ["dry_weir", "last_net", "mud_gasper", "pulled_shoot", "helping_hand", "wilt_noon", "gold_glare", "blind_grasp", "empty_adit"]:
			fs.append(_foe(fid2))
		await _gallery("part36_foes", fs, 1.0, 0.25)
		await _gallery("part36_lords", [_foe("the_drained", true), _foe("the_tugger", true), _foe("the_grasper", true)], 1.3, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["bind", "teach", "ground"]:
			mk.append(Marks.model(Marks.MARKS.the_ladle[oid], 0))
		await _gallery("part36_marks", mk, 1.6, 0.3)
		var kit := Kitchen.kit(Cooking.RECIPES.yam_stew.needs, Vector3(0, 0, 1), Color(Cooking.RECIPES.yam_stew.col))
		Kitchen.tick(kit, Cooking.run(2, 8), 7, 3.0, 10.0, 0.03)
		kit.scale = Vector3.ONE * 2.0
		var held: Array = [kit]
		for hn in ["trug", "spade", "kitchen_knife", "fan_leaf", "gourd", "bowl"]:
			var hm := Kitchen.held(hn)
			hm.scale = Vector3.ONE * 2.2
			hm.rotation = Vector3(-PI / 2.0, 0, 0)
			hm.position = Vector3(0, 0.6, 0)
			var hh := Node3D.new()
			hh.add_child(hm)
			held.append(hh)
		await _gallery("kitchen_things", held, 1.1, 0.3)
		var sc2: Array = []
		for kd in ["ground", "crater"]:
			sc2.append(Sunder.model(kd, 5, Color("8a7a5a")))
		await _gallery("sunder_scars", sc2, 3.2, 0.3)
	if want.call("cross"):
		main.set_stack(["world"])
		Game.picks.erase("the_ladle")
		Game.cross_pending = ["the_ladle"]
		main.ask_crossroads()
		main.choice.cursor = 0
		await _wait(1.0)
		await _shot("crossroads_ladle")
		main.pop()
		Game.cross_pending = []
		main.set_stack(["world"])
		stand.call(open_at if open_at.x >= 0 else w.ptile, 1)
		main.offer_cook()
		await frames_n.call(6)
		await _shot("cook_menu")
		main.pop()
	if want.call("battles"):
		for bb in [["the_drained", "marsh"], ["the_tugger", "millet"], ["the_grasper", "forge"]]:
			main.set_stack(["world"])
			var b = main.battle
			b.start([{"id": str(bb[0]), "lv": 122}], {"boss": true, "theme": str(Data.AREAS[str(bb[1])].theme), "area": str(bb[1])})
			main.push("battle")
			await _wait(3.0)
			await _shot("battle_boss_" + str(bb[0]))
			main.pop()
	get_tree().quit(0)

## The Rivers and Lakes (--lakes, or --lakes=a,b): "towns" (the four towns of the sects from above), "vehicles"
## (the ten kinds in a row), "traffic" (the high road with what goes along it), "raid" (a cart set on, and a
## camp), "hall" (the counter and the hall of tasks, upright and crooked), "page" (Esc > The Sects, and the map
## of the sixth realm), "boat" (the landing at Longmen), "foes", "marks" and "cross" (Part XLI).
func _deeps_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 140
	Game.step = Data.step_index("s_p42_channel")
	Game.companion = true
	Game.day = 352
	Game.stones = 112000
	Game.dao = "sword"
	for rid in [Atlas.HUB] + Data.AREA_CHAIN:
		Game.seen[rid] = true
	for sg in ["sunk_junk", "weeping_rock", "kelp_cathedral", "coral_arch", "giant_clam", "sunk_bell", "kun_rib", "black_smoker", "yu_statue", "caved_well", "tail_gate"]:
		Game.sights[sg] = 340
	Game.mills = {"loomery": {"n": 5, "at": Mills.worked(Game)}, "glass": {"n": 3, "at": Mills.worked(Game)}}
	Game.mill_crates = [{"from": "kiln", "to": "loomery", "pay": Mills.pay(140), "day": 352}]
	Game.crates_done = 4
	Game.mill_paid = 4 * Mills.pay(140)
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
		Game.page_due = []
		Game.rite_due = []
		Game.done_pending = []
	var ent := func(id: String) -> Dictionary:
		for e in Atlas.world_of("deeps").ents:
			if str(e.id) == id:
				return e
		return {}
	if want.call("towns"):
		for tw in [["shuttlereef", 10.5], ["redbranch", 12.0], ["lampdeep", 14.0]]:
			var tid := str(tw[0])
			var area := str(Weal.TOWNS[tid].area)
			var c: Vector2i = Atlas.to_world(area, Folk.TOWNS[tid].at)
			Clock.set_hour(Game, float(tw[1]))
			w.teleport(_nearest_free(c + Vector2i(0, 1)), "deeps")
			w.banner_t = 0.0
			quiet.call()
			await _wait(1.5)
			var cp: Vector3 = w.wpos(c)
			cp.y = w.ground_y(cp)
			w.cam_override = Transform3D(Basis.IDENTITY, cp + Vector3(-26.0, 30.0, 40.0)).looking_at(cp + Vector3(4.0, 3.0, -6.0), Vector3.UP)
			await _wait(0.8)
			await _shot("town_" + tid)
			w.cam_override = null
			await _wait(0.6)
			await _shot("street_" + tid)
	if want.call("works"):
		for wid in Mills.ORDER:
			var e1: Dictionary = ent.call("mill:%s:1" % wid)
			if e1.is_empty():
				continue
			Clock.set_hour(Game, 10.5)
			w.teleport(_nearest_free(e1.pos + Vector2i(-2, 2)), "deeps")
			w.facing = Vector2i(0, -1)
			w.banner_t = 0.0
			quiet.call()
			await _wait(1.6)
			var mp: Vector3 = w.wpos(e1.pos)
			mp.y = w.ground_y(mp)
			w.cam_override = Transform3D(Basis.IDENTITY, mp + Vector3(1.0, 3.6, 9.0)).looking_at(mp + Vector3(0.5, 1.0, 0.0), Vector3.UP)
			await _wait(0.9)
			await _shot("works_" + wid)
			w.cam_override = null
		# one station close to, the store, a yard at night, and the foreman's counter
		var e2: Dictionary = ent.call("mill:loomery:1")
		w.teleport(e2.pos + Vector2i(0, 1), "deeps")
		w.facing = Vector2i(0, -1)
		quiet.call()
		await _wait(1.0)
		var lp: Vector3 = w.wpos(e2.pos)
		lp.y = w.ground_y(lp)
		w.cam_override = Transform3D(Basis.IDENTITY, lp + Vector3(2.6, 2.2, 3.4)).looking_at(lp + Vector3(0, 1.0, 0), Vector3.UP)
		await _wait(0.6)
		await _shot("works_station_loom")
		w.cam_override = null
		main.interact(e2)
		await _wait(0.5)
		main.press("confirm")
		await _wait(0.4)
		await _shot("works_station_said")
		main.set_stack(["world"])
		Clock.set_hour(Game, 22.0)
		await _wait(1.0)
		w.cam_override = Transform3D(Basis.IDENTITY, lp + Vector3(1.5, 5.5, 12.5)).looking_at(lp + Vector3(1.0, 1.0, 0.0), Vector3.UP)
		await _wait(0.8)
		await _shot("works_night")
		w.cam_override = null
		Clock.set_hour(Game, 10.5)
		var fm: Dictionary = ent.call("loomer_sha")
		w.teleport(_nearest_free(fm.pos + Vector2i(0, 1)), "deeps")
		quiet.call()
		await _wait(0.8)
		main.offer_mill(fm, "loomery")
		await _wait(0.6)
		main.press("confirm")
		await _wait(0.3)
		main.press("confirm")
		await _wait(0.5)
		if main.top_name() != "choice":
			main.press("confirm")
			await _wait(0.5)
		if main.top_name() == "choice":
			main.choice.cursor = 1
			main.choice._show()
			await _wait(0.3)
		await _shot("works_counter")
		main.set_stack(["world"])
	if want.call("sights"):
		for sg2 in [["sunk_junk", 11.0], ["coral_arch", 12.5], ["giant_clam", 13.0], ["sunk_bell", 15.0], ["kun_rib", 12.0], ["black_smoker", 12.0], ["yu_statue", 12.0], ["caved_well", 12.0], ["tail_gate", 16.0], ["whale_fall", 16.0]]:
			var se: Dictionary = ent.call("sight:" + str(sg2[0]))
			if se.is_empty():
				continue
			Game.sights[str(sg2[0])] = 340
			Clock.set_hour(Game, float(sg2[1]))
			w.teleport(_nearest_free(se.pos + Vector2i(-2, 1)), "deeps")
			w.facing = Vector2i(1, 0)
			w.banner_t = 0.0
			quiet.call()
			await _wait(1.6)
			var sp: Vector3 = w.wpos(se.pos)
			sp.y = w.ground_y(sp)
			var tall: bool = str(sg2[0]) in ["kun_rib", "kelp_cathedral"]
			w.cam_override = Transform3D(Basis.IDENTITY, sp + (Vector3(7.0, 4.0, 20.0) if tall else Vector3(3.5, 3.0, 9.0))).looking_at(sp + Vector3(0, 6.0 if tall else 1.8, 0), Vector3.UP)
			await _wait(0.9)
			await _shot("sight_" + str(sg2[0]))
			w.cam_override = null
		var se2: Dictionary = ent.call("sight:sunk_bell")
		w.teleport(_nearest_free(se2.pos + Vector2i(0, 1)), "deeps")
		quiet.call()
		await _wait(0.8)
		main.interact(se2)
		await _wait(0.5)
		main.press("confirm")
		await _wait(0.4)
		await _shot("sight_said")
		main.set_stack(["world"])
	if want.call("terra"):
		Clock.set_hour(Game, 11.0)
		Game.step = Data.step_index("s_p42_shape")
		var dw: Dictionary = Atlas.world_of("deeps")
		var from: Vector2i = Atlas.to_world("shanhu", Vector2i(60, 54))
		w.teleport(_nearest_free(from), "deeps")
		quiet.call()
		await _wait(1.2)
		# the nearest open ground that answers, with room beside it
		var at := Vector2i(-1, -1)
		for rr in range(1, 30):
			for dy in range(-rr, rr + 1):
				for dx in range(-rr, rr + 1):
					var q: Vector2i = from + Vector2i(dx, dy)
					if at.x < 0 and Terra.why(Game, dw, "deeps", q, "raise") == "" and Terra.why(Game, dw, "deeps", q + Vector2i(3, 0), "pool") == "" and Terra.why(Game, dw, "deeps", q + Vector2i(-3, 0), "lower") == "" and int(dw.grid[(q.y + 2) * dw.w + q.x]) == MapGen.FLOOR and int(dw.grid[(q.y + 1) * dw.w + q.x + 1]) == MapGen.FLOOR and w.tile_free(q + Vector2i(0, 2)):
						at = q
		if at.x >= 0:
			w.teleport(at + Vector2i(0, 2), "deeps")
			w.facing = Vector2i(0, -1)
			quiet.call()
			await _wait(1.2)
			var tp: Vector3 = w.wpos(at)
			tp.y = w.ground_y(tp)
			var tcam := Transform3D(Basis.IDENTITY, tp + Vector3(3.0, 7.5, 15.0)).looking_at(tp + Vector3(0, 0.5, 0), Vector3.UP)
			w.cam_override = tcam
			await _wait(0.8)
			await _shot("terra_before")
			w.cam_override = null
			main.offer_shape()
			await _wait(0.4)
			if main.top_name() == "choice":
				main.choice.cursor = 1
				main.choice._show()
				await _wait(0.3)
				await _shot("terra_ask")
			main.set_stack(["world"])
			for k in 4:
				Terra.shape(Game, dw, "deeps", at, "raise")
				Terra.shape(Game, dw, "deeps", at + Vector2i(3, 0), "pool")
				if k < 3:
					Terra.shape(Game, dw, "deeps", at + Vector2i(-3, 0), "lower")
			Clock.set_hour(Game, 11.5)
			w.clear_cache()
			w.teleport(at + Vector2i(0, 2), "deeps")
			w.facing = Vector2i(0, -1)
			quiet.call()
			await _wait(1.6)
			w.cam_override = tcam
			await _wait(0.8)
			await _shot("terra_after")
			w.cam_override = null
			w.teleport(at + Vector2i(1, 1), "deeps")
			w.facing = Vector2i(-1, 0)
			quiet.call()
			await _wait(1.0)
			await _shot("terra_on_the_mound")
			Game.shaped = {}
			w.clear_cache()
		Game.step = Data.step_index("s_p42_channel")
	if want.call("dive"):
		Clock.set_hour(Game, 16.5)
		var de: Dictionary = {}
		for e3 in Atlas.world_of("sea").ents:
			if str(e3.id) == "sea_dive:a":
				de = e3
		if not de.is_empty():
			w.teleport(_nearest_free(de.pos + Vector2i(de.out)), "sea")
			w.banner_t = 0.0
			quiet.call()
			await _wait(1.5)
			await _shot("dive_at_guixu")
		var le: Dictionary = ent.call("sea_dive:b")
		if not le.is_empty():
			Clock.set_hour(Game, 11.0)
			w.teleport(_nearest_free(le.pos + Vector2i(1, 0)), "deeps")
			w.banner_t = 0.0
			quiet.call()
			await _wait(1.5)
			await _shot("dive_landing")
			var lp2: Vector3 = w.wpos(le.pos)
			lp2.y = w.ground_y(lp2)
			w.cam_override = Transform3D(Basis.IDENTITY, lp2 + Vector3(-6.0, 1.6, 14.0)).looking_at(lp2 + Vector3(10.0, 16.0, -20.0), Vector3.UP)
			await _wait(0.8)
			await _shot("sea_overhead")
			w.cam_override = null
	if want.call("page"):
		quiet.call()
		main.set_stack(["world"])
		Clock.set_hour(Game, 11.0)
		w.teleport(_nearest_free(Atlas.to_world("jiaoshi", Vector2i(41, 33))), "deeps")
		await _wait(0.6)
		main.push("menu")
		main.menu.mode = "deeps"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.3)
		await _shot("page_the_sea_floor")
		main.menu.mode = "map"
		main.menu.map_layer = "deeps"
		main.menu._build()
		await _wait(0.4)
		await _shot("map_sea_floor")
		main.set_stack(["world"])
	if want.call("foes"):
		var fs: Array = []
		for fid2 in ["silt_carp", "loom_crab", "tear_jelly", "net_ray", "bleach_polyp", "reef_eel", "well_frog", "summer_insect", "cramped_scholar", "silt_golem", "drain_wraith", "proud_flood"]:
			fs.append(_foe(fid2))
		await _gallery("part42_foes", fs, 1.0, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["shape", "teach", "leave"]:
			mk.append(Marks.model(Marks.MARKS.the_joy_of_fish[oid], 0))
		await _gallery("part42_marks", mk, 1.6, 0.3)
	if want.call("machines"):
		# (a sheet a works: its three stations, each with whoever works it)
		for wid2 in Mills.ORDER:
			var ms: Array = []
			for k2 in 3:
				var holder := Node3D.new()
				var mm := Mills.model(wid2, k2)
				mm.rotation.y = 0.55
				Mills.tick(mm, 2.3 + k2, true)
				holder.add_child(mm)
				ms.append(holder)
			await _gallery("works_stations_" + wid2, ms, 1.5, 0.0)
	if want.call("cross"):
		main.set_stack(["world"])
		w.teleport(_nearest_free(Atlas.to_world("jiaoshi", Vector2i(39, 31))), "deeps")
		Clock.set_hour(Game, 15.0)
		quiet.call()
		await _wait(1.0)
		Game.picks.erase("the_joy_of_fish")
		Game.cross_pending = ["the_joy_of_fish"]
		main.ask_crossroads()
		await _wait(0.6)
		await _shot("crossroads_joy_of_fish")
		main.set_stack(["world"])
		Game.cross_pending = []

func _lakes_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 136
	Game.step = Data.step_index("s_p41_carts")
	Game.companion = true
	Game.day = 330
	Game.stones = 108000
	Game.dao = "sword"
	for rid in [Atlas.HUB] + Data.AREA_CHAIN:
		Game.seen[rid] = true
	Game.sect_q = {"reed_banks": "done", "reed_home": "done", "cold_cliff": "done", "black_leech": "taken"}
	Game.sect_base = {"black_leech": {}}
	Game.raids_broken = 7
	Game.raids_fled = 2
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
		Game.page_due = []
		Game.rite_due = []
		Game.done_pending = []
	var counter := func(office: String) -> Dictionary:
		return {"kind": "office", "id": office, "office": office, "n": str(Offices.OFFICES[office].n), "area": str(Offices.OFFICES[office].area), "pos": Vector2i.ZERO}
	if want.call("towns") or want.call("knifegate"):
		for tw in [["reedhaven", 10.5], ["clearbell", 9.0], ["ashmarket", 20.6], ["knifegate", 16.5]]:
			var tid := str(tw[0])
			if not want.call("towns") and not want.call(tid):
				continue
			var area := str(Weal.TOWNS[tid].area)
			var c: Vector2i = Atlas.to_world(area, Folk.TOWNS[tid].at)
			Clock.set_hour(Game, float(tw[1]))
			w.teleport(_nearest_free(c + Vector2i(0, 1)), "lakes")
			w.banner_t = 0.0
			quiet.call()
			await _wait(1.5)
			var cp: Vector3 = w.wpos(c)
			cp.y = w.ground_y(cp)
			w.cam_override = Transform3D(Basis.IDENTITY, cp + Vector3(-26.0, 30.0, 40.0)).looking_at(cp + Vector3(4.0, 3.0, -6.0), Vector3.UP)
			await _wait(0.8)
			await _shot("town_" + tid)
			w.cam_override = null
			await _wait(0.6)
			await _shot("street_" + tid)
	if want.call("vehicles"):
		# (five to a sheet, so that each can be made out)
		for half in 2:
			var vs: Array = []
			for k in Traffic.ORDER.slice(half * 5, half * 5 + 5):
				var holder := Node3D.new()
				var vm := Wagons.build(k, 3)
				vm.scale = Vector3.ONE * 0.42
				vm.rotation.y = 0.9
				Wagons.animate(vm, 1.3, true)
				holder.add_child(vm)
				vs.append(holder)
			await _gallery("traffic_vehicles_%d" % (half + 1), vs, 2.6, 0.0)
	if want.call("traffic"):
		for lr in [["lakes", "traffic_rivers_and_lakes"], ["surface", "traffic_unbroken_land"]]:
			var lid := str(lr[0])
			Clock.set_hour(Game, 11.0)
			Game.step = Data.step_index("s_p40_home")
			# somebody under way out in the country, well clear of every town: he stands beside the road ahead of it
			var clk := float(Game.day) * Clock.DAY + float(Game.clock)
			var feet: Array = (Roads.of(lid).at as Dictionary).values()
			var pick: Dictionary = {}
			var bd := -1.0
			for v in Traffic.fleet(lid):
				var wv: Dictionary = Traffic.where(v, clk, float(Game.playtime))
				var far := 1e9
				for f in feet:
					far = minf(far, Vector2(f).distance_to(wv.pos))
				if bool(wv.moving) and far > bd and not str(v.kind) in ["handcart", "barrow"]:
					bd = far
					pick = wv
			if pick.is_empty():
				continue
			var ahead: Vector2 = (pick.pos as Vector2) + (pick.dir as Vector2) * 5.0
			var side2 := Vector2(-(pick.dir as Vector2).y, (pick.dir as Vector2).x)
			w.teleport(_nearest_free(Vector2i(ahead + side2 * 3.0)), lid)
			w.banner_t = 0.0
			quiet.call()
			await _wait(2.5)
			var vp := Vector3(pick.pos.x * w.TS + w.off.x, 0, pick.pos.y * w.TS + w.off.z)
			vp.y = w.ground_y(vp)
			var d3 := Vector3((pick.dir as Vector2).x, 0, (pick.dir as Vector2).y)
			var s3 := Vector3(side2.x, 0, side2.y)
			w.cam_override = Transform3D(Basis.IDENTITY, vp + d3 * 13.0 + s3 * 9.0 + Vector3(0, 6.0, 0)).looking_at(vp + d3 * 2.0 + Vector3(0, 1.4, 0), Vector3.UP)
			await _wait(1.0)
			await _shot(str(lr[1]))
			w.cam_override = null
		Game.step = Data.step_index("s_p41_carts")
	if want.call("raid"):
		for rk in [["road", "heishui", "raid_on_a_cart"], ["camp", "yunmeng", "raid_on_a_camp"]]:
			Clock.set_hour(Game, 15.5)
			var rd: Dictionary = {}
			for r in Raids.on(Game, "lakes"):
				if str(r.kind) == str(rk[0]) and str(r.area) == str(rk[1]):
					rd = r
			if rd.is_empty():
				continue
			w.teleport(_nearest_free(rd.tile + Vector2i(4, 3)), "lakes")
			w.banner_t = 0.0
			quiet.call()
			await _wait(2.4)
			var rp: Vector3 = w.wpos(rd.tile)
			rp.y = w.ground_y(rp)
			# (from along the road, or over open ground: not through the wood)
			var from := rp + Vector3(6.0, 4.5, 8.0)
			var bestd := 1e9
			for rt in (Roads.of("lakes").tiles as Dictionary):
				var dd: float = Vector2(rt).distance_to(Vector2(rd.tile))
				if dd >= 5.0 and dd <= 7.0 and absf(dd - 6.0) < bestd:
					bestd = absf(dd - 6.0)
					from = w.wpos(rt)
					from.y = w.ground_y(from) + 4.0
			if str(rk[0]) == "camp":
				var cc: Vector3 = w.wpos(Atlas.world_of("lakes").camps[str(rk[1])])
				from = rp + (rp - cc).normalized() * 9.0
				from.y = w.ground_y(from) + 5.0
			w.cam_override = Transform3D(Basis.IDENTITY, from).looking_at(rp + Vector3(0, 1.0, 0), Vector3.UP)
			await _wait(0.8)
			await _shot(str(rk[2]))
			w.cam_override = null
			if str(rk[0]) == "road":
				main.say([["Narrator", Raids.seen_line(rd)]])
				await _wait(0.5)
				await _shot("raid_come_up_to")
				main.set_stack(["world"])
	if want.call("hall"):
		for hc in [["hall_reed", "yunmeng", "reed"], ["hall_black", "heishui", "black"]]:
			Clock.set_hour(Game, 10.0)
			var ce: Dictionary = {}
			for e in Atlas.world_of("lakes").ents:
				if str(e.get("office", "")) == str(hc[0]):
					ce = e
			if ce.is_empty():
				ce = counter.call(str(hc[0]))
			else:
				w.teleport(_nearest_free(ce.pos + Vector2i(0, 1)), "lakes")
			w.banner_t = 0.0
			quiet.call()
			await _wait(0.8)
			main.offer_carriage(ce)
			await _wait(0.4)
			main.choice.cursor = maxi(0, main.choice.ids().find("sect:tasks"))
			main.choice._show()
			await _wait(0.3)
			await _shot("counter_sect_" + str(hc[2]))
			main.set_stack(["world"])
			main.offer_sect(ce, str(hc[2]))
			await _wait(0.3)
			main.set_stack(["world"])
			var opts: Array = [{"id": "later", "label": "Nothing today", "desc": "The wall will be here.", "col": UI.C_DIM}]
			for t in Sects.tasks_of(str(hc[2])):
				if Sects.state(Game, t) != "done":
					opts.append({"id": "take:" + str(t), "label": Sects.label(Game, t), "desc": Sects.text(Game, t), "col": UI.C_RED if bool(Sects.TASKS[t].get("foul", false)) else UI.C_GOLD})
			main.choose(Sects.ASK, opts, func(_id: String): pass)
			main.choice.cursor = opts.size() - 1
			main.choice._show()
			await _wait(0.3)
			await _shot("hall_of_tasks_" + str(hc[2]))
			main.set_stack(["world"])
	if want.call("page"):
		quiet.call()
		main.set_stack(["world"])
		w.teleport(_nearest_free(Atlas.to_world("yunmeng", Vector2i(41, 33))), "lakes")
		await _wait(0.6)
		main.push("menu")
		main.menu.mode = "sects"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.3)
		await _shot("page_the_sects")
		main.menu.mode = "map"
		main.menu.map_layer = "lakes"
		main.menu._build()
		await _wait(0.4)
		await _shot("map_rivers_and_lakes")
		main.set_stack(["world"])
	if want.call("boat"):
		Clock.set_hour(Game, 17.2)
		var be: Dictionary = {}
		for e2 in Atlas.world_of("surface").ents:
			if str(e2.id) == "river_boat:a":
				be = e2
		if not be.is_empty():
			w.teleport(_nearest_free(be.pos + Vector2i(be.out)), "surface")
			w.banner_t = 0.0
			quiet.call()
			await _wait(1.5)
			await _shot("river_boat_longmen")
	if want.call("foes"):
		var fs: Array = []
		for fid2 in ["gasping_carp", "reed_reaver", "spit_wisp", "uncopied_poem", "cliff_gibbon", "pine_laughter", "owed_ledger", "blackwater_leech", "gate_collector", "banner_wolf", "pass_raider", "tooth_golem"]:
			fs.append(_foe(fid2))
		await _gallery("part41_foes", fs, 1.0, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["bind", "dig", "toll"]:
			mk.append(Marks.model(Marks.MARKS.the_covenant[oid], 0))
		await _gallery("part41_marks", mk, 1.6, 0.3)
	if want.call("cross"):
		main.set_stack(["world"])
		w.teleport(_nearest_free(Atlas.to_world("yunmeng", Vector2i(39, 31))), "lakes")
		Clock.set_hour(Game, 18.0)
		quiet.call()
		await _wait(1.0)
		Game.picks.erase("the_covenant")
		Game.cross_pending = ["the_covenant"]
		main.ask_crossroads()
		await _wait(0.6)
		await _shot("crossroads_covenant")
		main.set_stack(["world"])
		Game.cross_pending = []

## The Unblunted Knife (--knife, or --knife=a,b): "chart" (Esc > The Channels, closed and with points open),
## "hands" (Esc > Hands & Beasts), "make" (the choice, and each craft at its bench), "peace" (the choice on a
## summit, sitting there, at the back of a cave and in a pavilion), "beast" (one that has not run, the choice,
## the beast at his heel, the beasts he keeps), "foes", "marks", "people" and "cross" (Part XLIII).
func _knife_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 143
	Game.step = Data.step_index("s_p43_tops")
	Game.companion = true
	Game.day = 371
	Game.stones = 118000
	Game.dao = "sword"
	Game.dao_xp["sword"] = 999999
	for rid in [Atlas.HUB] + Data.AREA_CHAIN:
		Game.seen[rid] = true
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
		Game.page_due = []
		Game.rite_due = []
		Game.done_pending = []
	var surf: Dictionary = Atlas.world_of("surface")
	var top: Vector2i = Peaks.of_area(surf, "mountain")[0].c
	if want.call("chart"):
		w.teleport(_nearest_free(Atlas.to_world("sect", Vector2i(20, 10))), "surface")
		quiet.call()
		await _wait(0.8)
		Game.channels = {}
		main.push("menu")
		main.menu.mode = "channels"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.3)
		await _shot("page_channels_closed")
		for id in ["ren", "ren", "ren", "du", "du", "chong", "dai", "circuit", "sw_arm", "sw_arm", "sw_forge", "sw_edge", "sw_gap", "sw_seal", "he_gate", "he_carve", "st_sit", "st_breath", "st_ear", "ha_grip", "ha_eye", "be_hand", "be_fang", "wa_leg", "al_burn", "fo_back", "il_eye"]:
			Channels.open(Game, id)
		main.menu.msg = ""
		main.menu._build()
		main.menu.cursor = main.menu.ids.find("point:sw_gap")
		await _wait(0.3)
		await _shot("page_channels_open")
		main.menu.cursor = main.menu.ids.find("point:qiao")
		await _wait(0.3)
		await _shot("page_channels_fork")
		main.pop()
	if want.call("make"):
		Clock.set_hour(Game, 10.0)
		Game.inv["timber"] = 9
		Game.inv["stone_block"] = 4
		Game.inv["herb_bundle"] = 12
		Game.inv["ore_lump"] = 5
		Game.craft_xp = {"forge": 9, "carve": 4}
		var mt := _nearest_free(Atlas.to_world("bamboo", Vector2i(30, 22)))
		w.teleport(mt, "surface")
		for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			if w.tile_free(mt + d) and w.ent_at(mt + d) == null:
				w.facing = d
				break
		quiet.call()
		await _wait(1.2)
		main.offer_make()
		await _wait(0.4)
		if main.top_name() == "choice":
			main.choice.cursor = 1
			main.choice._show()
			await _wait(0.3)
			await _shot("make_ask")
		main.set_stack(["world"])
		for th in ["plain_guard", "peach_beads", "ward_slip", "herb_paste", "river_stone", "straw_sandals"]:
			quiet.call()
			if w.make(th):
				await _wait(3.0)
				await _shot("make_" + Crafts.craft_of(th))
				w._use_finish()
				w._use_clear()
				await _wait(0.3)
			quiet.call()
	if want.call("peace"):
		Clock.set_hour(Game, 7.0)
		w.teleport(top, "surface")
		w.facing = Vector2i(0, 1)
		quiet.call()
		await _wait(1.5)
		main.offer_peace()
		await _wait(0.4)
		if main.top_name() == "choice":
			main.choice.cursor = 1
			main.choice._show()
			await _wait(0.3)
			await _shot("peace_ask_summit")
		main.set_stack(["world"])
		quiet.call()
		if w.sit("sit"):
			await _wait(3.0)
			await _shot("peace_sit_summit")
			w._use_finish()
			w._use_clear()
			await _wait(0.3)
		quiet.call()
		var fid := Caves.fid("fusang", -1)
		var cw: Dictionary = surf.floors[fid]
		for e in cw.ents:
			if str(e.id).begins_with("cave_cache:"):
				Game.taken[str(e.id)] = true
				Game.defeated = {}
				for e2 in cw.ents:
					if str(e2.kind) == "enemy":
						Game.defeated[e2.id] = Game.playtime
				w.teleport(e.pos + Vector2i(0, 1) if cw.grid[(e.pos.y + 1) * int(cw.w) + e.pos.x] == MapGen.FLOOR else e.pos, fid)
		quiet.call()
		await _wait(1.5)
		if w.sit("sit"):
			await _wait(3.0)
			await _shot("peace_sit_cave")
			w._use_finish()
			w._use_clear()
			await _wait(0.3)
		Game.defeated = {}
		quiet.call()
		for e3 in surf.ents:
			if str(e3.kind) == "prop" and str(e3.get("prop", "")) == "pavilion" and not e3.has("furn"):
				var spot := _prop_spot(surf, e3)
				if spot != Vector2i(-1, -1):
					Clock.set_hour(Game, 17.0)
					w.teleport(spot, "surface")
					w.facing = e3.pos - spot
					quiet.call()
					await _wait(1.5)
					main.offer_peace()
					await _wait(0.4)
					if main.top_name() == "choice":
						await _shot("peace_ask_pavilion")
					main.set_stack(["world"])
					break
	if want.call("beast"):
		Clock.set_hour(Game, 15.0)
		Game.pets = []
		Game.pet = -1
		Game.pets_n = 0
		Game.inv["carp"] = 4
		w.teleport(_nearest_free(Atlas.to_world("bamboo", Vector2i(34, 24))), "surface")
		quiet.call()
		await _wait(1.2)
		var pack := {"id": "tour_pack", "kind": "enemy", "group": [{"id": "bamboo_wolf", "lv": 1}, {"id": "bamboo_wolf", "lv": 1}], "pos": w.ptile + Vector2i(1, 0), "area": "bamboo", "vis": ["", ""]}
		main.offer_tame(pack, pack.group)
		await _wait(0.5)
		await _shot("beast_has_not_run")
		if main.top_name() == "dialogue":
			main.dialogue.press("confirm")
			await _wait(0.2)
			main.dialogue.press("confirm")
			await _wait(0.5)
		if main.top_name() == "choice":
			main.choice.cursor = 1
			main.choice._show()
			await _wait(0.3)
			await _shot("beast_ask")
		main.set_stack(["world"])
		Pets.tame(Game, "bamboo_wolf")
		Game.inv["mushrooms"] = 2
		Pets.tame(Game, "white_gibbon")
		Game.pets[0]["bond"] = 62.0
		quiet.call()
		w.move_dir = Vector2i(0, 1)
		await _wait(1.0)
		w.move_dir = Vector2i.ZERO
		await _wait(1.0)
		quiet.call()
		await _shot("beast_at_heel")
		main.offer_beasts()
		await _wait(0.4)
		if main.top_name() == "choice":
			main.choice.cursor = 2
			main.choice._show()
			await _wait(0.3)
			await _shot("beasts_kept")
		main.set_stack(["world"])
	if want.call("heel"):
		# on the flagstones of the sect, where the grass does not hide it
		Clock.set_hour(Game, 9.0)
		Game.pets = []
		Game.pet = -1
		Game.pets_n = 0
		Game.inv["carp"] = 2
		Pets.tame(Game, "bamboo_wolf")
		Game.pets[0]["bond"] = 62.0
		main.set_stack(["world"])
		w.teleport(_nearest_free(Atlas.to_world("sect", Vector2i(20, 12))), "surface")
		quiet.call()
		await _wait(0.8)
		w.move_dir = Vector2i(-1, 0)
		await _wait(0.8)
		w.move_dir = Vector2i.ZERO
		await _wait(1.8)
		quiet.call()
		w.banner_t = 0.0
		await _shot("beast_at_heel")
	if want.call("hands"):
		Game.kept = {"forge": {"id": "folded_collar", "q": 2}, "carve": {"id": "peach_beads", "q": 1}, "refine": {"id": "herb_paste", "q": 1}}
		Game.craft_xp = {"forge": 17, "carve": 4, "refine": 2}
		Game.crafted_n = 11
		Game.retreats = {str(Peaks.of_area(surf, "mountain")[0].id): 3, "deep:fusang:-1": 1, "pav:x": 2}
		Game.sittings = 6
		Game.slept = 1
		if Game.pets.is_empty():
			Game.inv["carp"] = 2
			Pets.tame(Game, "bamboo_wolf")
			Game.pets[0]["bond"] = 62.0
		main.push("menu")
		main.menu.mode = "hands"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.3)
		await _shot("page_hands_and_beasts")
		main.pop()
	if want.call("foes"):
		var fs: Array = []
		for fid2 in ["dropped_ball", "counted_wing", "trembling_pole", "crossed_grain", "hurried_chisel", "gold_archer", "crowing_cock", "glaring_cock", "hollow_swagger"]:
			fs.append(_foe(fid2))
		await _gallery("part43_foes", fs, 1.0, 0.25)
	if want.call("marks"):
		var mk: Array = []
		for oid in ["course", "fast", "show"]:
			mk.append(Marks.model(Marks.MARKS.the_first_form[oid], 0))
		await _gallery("part43_marks", mk, 1.6, 0.3)
	if want.call("benches"):
		var bs: Array = []
		for c in Crafts.ORDER:
			bs.append(Crafts.bench(c))
		bs.append(Retreats.mat())
		await _gallery("part43_benches", bs, 1.3, 0.2)
	if want.call("cross"):
		main.set_stack(["world"])
		w.teleport(_nearest_free(Atlas.to_world("sect", Vector2i(20, 10))), "surface")
		Clock.set_hour(Game, 18.0)
		quiet.call()
		await _wait(1.0)
		Game.picks.erase("the_first_form")
		Game.cross_pending = ["the_first_form"]
		main.ask_crossroads()
		await _wait(0.6)
		await _shot("crossroads_first_form")
		main.set_stack(["world"])
		Game.cross_pending = []


## The Turned Face (--turned, or --turned=a,b): "foes" (Part XLIV's nine), "old" (foes drawn on a body of their own
## kind at last), "arts" (the toad's Gold Tongue, the centipede's Hundred Steps, the owl's Screech, in battle),
## "name" (Esc > Good Name, well thought of and shunned), "harder" (a battle the land's ill will made harder),
## "marks" and "cross" (Part XLIV).
func _turned_shots(which: String = "1") -> void:
	var only := which.split(",", false) if which != "1" else PackedStringArray()
	var want := func(n: String) -> bool: return only.is_empty() or only.has(n)
	_burrows_state()
	Game.level = 146
	Game.step = Data.step_index("s_p44_cry")
	Game.companion = true
	Game.day = 402
	Game.stones = 121000
	for rid in [Atlas.HUB] + Data.AREA_CHAIN:
		Game.seen[rid] = true
	main.set_stack(["world"])
	main.world.clear_cache()
	var w = main.world
	var quiet := func():
		Game.toasts.clear()
		main.toast_list.clear()
		Game.mail_told = 999
		Game.fame_told = Fame.rank(Game)
		Game.page_due = []
		Game.rite_due = []
		Game.done_pending = []
	if want.call("foes"):
		var fs: Array = []
		for fid in ["thiefs_gait", "suspecting_eye", "wall_croak", "running_bark", "black_coat", "puffed_pride", "eastward_owl", "same_cry", "hundred_tongues"]:
			fs.append(_foe(fid))
		await _gallery("part44_foes", fs, 1.0, 0.3)
	if want.call("old"):
		var os: Array = []
		for fid2 in ["moon_toad", "cinnabar_toad", "toad_matriarch", "waking_centipede", "night_owl"]:
			os.append(_foe(fid2))
		await _gallery("drawn_as_their_kind", os, 1.2, 0.3)
	if want.call("arts"):
		for a in [["wall_croak", "yunmeng", "art_gold_tongue"], ["hundred_tongues", "langya", "art_hundred_steps"], ["eastward_owl", "hanshan", "art_screech"]]:
			Clock.set_hour(Game, 15.0)
			main.battle.start([{"id": a[0], "lv": 146}, {"id": a[0], "lv": 146}], {"theme": str(Data.AREAS[a[1]].theme), "enemy": a[0]})
			main.push("battle")
			await _wait(2.4)
			var f: Dictionary = main.battle.foes[0]
			f.turns = 3
			main.battle._foe_act(f)
			await _wait(0.42)
			await _shot(a[2])
			main.set_stack(["world"])
			await _wait(0.3)
	if want.call("name"):
		w.teleport(_nearest_free(Atlas.to_world("sect", Vector2i(20, 10))), "surface")
		quiet.call()
		await _wait(0.8)
		Game.deeds_bad = 0
		Game.pilfered = 0
		main.push("menu")
		main.menu.mode = "name"
		main.menu.cursor = 0
		main.menu._build()
		await _wait(0.3)
		await _shot("page_good_name")
		Game.deeds_bad = 6
		Game.pilfered = 3
		Game.gamble_rounds = 25
		Game.deeds_good = 4
		main.menu._build()
		await _wait(0.3)
		await _shot("page_good_name_shunned")
		main.pop()
	if want.call("harder"):
		Game.deeds_bad = 6
		Game.pilfered = 3
		Game.gamble_rounds = 25
		Clock.set_hour(Game, 21.0)
		main.battle.start([{"id": "suspecting_eye", "lv": 146}, {"id": "wall_croak", "lv": 146}, {"id": "thiefs_gait", "lv": 146}], {"theme": str(Data.AREAS.yunmeng.theme), "enemy": "suspecting_eye"})
		main.push("battle")
		await _wait(2.6)
		await _shot("battle_turned_face")
		main.set_stack(["world"])
		Game.deeds_bad = 0
		Game.pilfered = 0
		Game.gamble_rounds = 0
		Game.deeds_good = 0
	if want.call("marks"):
		var mk: Array = []
		for oid in ["drum", "herald", "cry"]:
			mk.append(Marks.model(Marks.MARKS.the_owls_cry[oid], 0))
		await _gallery("part44_marks", mk, 1.6, 0.3)
	if want.call("cross"):
		main.set_stack(["world"])
		w.teleport(_nearest_free(Atlas.to_world("sect", Vector2i(20, 10))), "surface")
		Clock.set_hour(Game, 18.0)
		quiet.call()
		await _wait(1.0)
		Game.picks.erase("the_owls_cry")
		Game.cross_pending = ["the_owls_cry"]
		main.ask_crossroads()
		await _wait(0.6)
		await _shot("crossroads_owls_cry")
		main.set_stack(["world"])
		Game.cross_pending = []
