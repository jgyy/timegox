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
## he does it (prop_<kind>.png), and all of them on sheets (props_sheet_<n>.png).
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
	main.world.cam_q = maxi(0, main.world.FWD.find(main.world.facing))
	main.world._snap_cam()
	main.world.banner_t = 0.0
	Game.toasts.clear()
	main.toast_list.clear()

## Every line of the conversation on top shown at once and passed, up to the next choice.
func _skip_talk() -> void:
	var guard := 0
	while main.top_name() == "dialogue" and guard < 60:
		guard += 1
		main.dialogue.shown = 999.0
		main.press("confirm")
		await _wait(0.12)

## The bigger things in use, Yue Ling's heart-to-hearts and her page, Part XV's memories, the
## Founder's echo and her hermitage, the lotus pond, and the new battles.
func _lotus_shots() -> void:
	# a memory given back: Ah Zhu's flute stone in the bamboo, Yue Ling playing the flute while he listens
	_lotus_state("s_p15_memories")
	Game.memories = {"mem_spring": "nothing", "mem_lanterns": "two"}
	var mf := _land_ent("mem:mem_flute")
	if not mf.is_empty():
		_stand_by(mf)
		await _wait(0.3)
		main._memory_won("mem_flute")
		for k in 3:
			main.dialogue.shown = 999.0
			main.press("confirm")
			await _wait(0.2)
		main.world.using.t0 = main.world.t - main.world.USE_STEP - 2.0
		await _wait(1.2)
		main.dialogue.shown = 999.0
		await _wait(0.4)
		await _shot("memory_flute")
		await _skip_talk()
		await _wait(0.5)
		await _shot("memory_choice")
		main.choice.press("confirm")
		await _wait(0.3)
		await _skip_talk()
	# the fight for a memory: the moths that eat forgetting
	main.battle.start([{"id": "forgetting_moth", "lv": 57}, {"id": "loose_thread", "lv": 57}, {"id": "unweaver_shuttle", "lv": 58}], {"boss": false, "theme": "bamboo"})
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
	Game.memories = {"mem_spring": "nothing", "mem_lanterns": "two", "mem_flute": "forest"}
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
	# the Founder's hermitage and its bathhouse under the Last Cave, and the Warden waiting by them
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
	main.world.cam_override = Transform3D(Basis.IDENTITY, hc + Vector3(-5.0, 2.6, -3.0)).looking_at(hc + Vector3(-0.5, 1.6, -7.0), Vector3.UP)
	await _wait(0.4)
	await _shot("hermitage_gate")
	main.world.cam_override = null
	# the two trials
	var ub: Dictionary = Trials.path("unweaver", "heart").boon
	main.battle.start([{"id": "unweaver", "lv": 59, "mult": 2.0, "atk": 1.2}], {"boss": true, "enemy": "unweaver", "theme": "loom", "trial": "unweaver", "path": "heart", "boon": ub, "path_n": "Side by side", "path_kind": str(Trials.KINDS.heart.n)})
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
	# a red kite high over the hills
	_lotus_state("s_p15_memories")
	var kt := {}
	for e2 in Atlas.world_of("surface").ents:
		if e2.kind == "prop" and str(e2.prop) == "kite" and _prop_spot(Atlas.world_of("surface"), e2) != Vector2i(-1, -1):
			kt = e2
			break
	if not kt.is_empty():
		_stand_by(kt)
		await _wait(0.3)
		main.world.start_use(kt)
		main.world.using.t0 = main.world.t - main.world.USE_STEP - 3.6
		await _wait(0.4)
		var nd = main.world.ent_nodes.get(kt.id)
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
	Game.renown = 698
	Game.deeds = {}
	for did in Trials.DEEDS.keys().slice(0, 7):
		Game.deeds[did] = true
	Game.playtime = 62536.5
	Game.finished = true
	Game.kills = 3127
	Game.battles = 1700
	Game.deaths = 0
	Game.meditated = 11994.5
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

## The ending: a frame from the middle of every shot of the film (ending_<shot>.png, and all of them
## on one sheet, ending_film.png) and the results once the film is over (ending.png).
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
	out.save_png("%s/%s.png" % [dir, n])
	print("[tour] ", n)

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
	if main.args.has("fates"):
		await _fates_shots()
	if main.args.has("ending"):
		# the ending on its own (--ending): its film and the results
		_ending_state()
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
