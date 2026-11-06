extends Node
## Screenshot tour (developer tool).  Teleports through every screen, region and boss and saves
## PNGs.  Needs a real window (use xvfb on a server):
##   godot --path . --fixed-fps 30 -- --tour=docs/screenshots

var main
var dir := ""

const ELEMS := {"sect": "phys", "bamboo": "fire", "marsh": "fire", "frost": "thunder", "thunder": "earth", "palace": "water", "dragon": "thunder", "volcano": "water", "void": "dark", "celestial": "thunder", "mirror": "thunder", "grave": "fire", "time": "dark", "origin": "thunder", "cloudsea": "thunder", "court": "fire", "forge": "water", "garden": "fire", "dunes": "wood", "fungal": "fire", "aurora": "earth", "chaos": "thunder", "maple": "water", "karst": "thunder", "springs": "fire", "wheel": "thunder", "mountain": "phys", "village": "thunder", "terraces": "earth", "silk": "fire", "loom": "fire"}

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

func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, n])
	print("[tour] ", n)

## A showroom shot: models in a row on a lotus-pond stage, lit from the front.
func _gallery(n: String, models: Array, spacing: float) -> void:
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
		m.rotation.y = 0.35 * (1 if i % 2 == 0 else -1)
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

func _nearest_free(pos: Vector2i) -> Vector2i:
	for r in 20:
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var p := pos + Vector2i(dx, dy)
				if main.world.tile_free(p) and main.world.ent_at(p) == null and maxi(absi(dx), absi(dy)) == r:
					return p
	return pos

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
		main.world.teleport(_nearest_free(Atlas.to_world(id, focus)))
		main.world.facing = Vector2i(1, 0)
		main.world.cam_q = 1  # behind the hero, who faces east
		main.world._snap_cam()
		main.world.banner_t = 0.0
		await _wait(1.2)
		await _shot("world_" + id)
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
	# galleries are shot from the world screen (the title menu would cover them)
	main.set_stack(["world"])
	main.world.load_area("sect", Vector2i(20, 9))
	main.world.banner_t = 0.0
	if main.args.has("gallery") or not main.args.has("no-extras"):
		await _gallery("gallery_people", [
			Models.person(Color("3a8ae8"), Color("1a1a2a"), main.world.HERO_OPTS),
			Models.person(Color("e86a9a"), Color("402030"), main.world.YUE_OPTS),
			Models.person(Color("e8e8ff"), Color("2a2a3a"), {"asset": "elder_qing", "beard": true, "staff": true, "hair": "bald", "trim": Color("c8a850")}),
			Models.monster("humanoid", Color("c0603a"), false),
			Models.monster("demon", Color("e02050"), false),
		], 1.0)
		# Blender-built NPCs (art/characters)
		await _gallery("gallery_npcs", [
			Assets.person("alchemist"), Assets.person("smith"), Assets.person("nomad"),
			Assets.person("spore_witch"), Assets.person("steppe_shaman"), Assets.person("nuwa_echo"),
		], 0.8)
		# Part V creatures (art/monsters)
		await _gallery("gallery_part5", [
			Models.monster("scorpion", Color("e8d8a0")), Models.monster("mushroom", Color("c070e0")), Models.monster("mammoth", Color("a0b8d0")),
			Models.monster("moth", Color("ffb040")), Models.monster("hundun", Color("e05030")),
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
			Models.monster("fox", Color("ff6a30")), Models.monster("carp", Color("ffb060")), Models.monster("oxhead", Color("6a3a2a")),
			Models.monster("horseface", Color("8a4a3a")), Models.monster("jiangshi", Color("3a5a4a")),
		], 1.7)
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
		await _gallery("gallery_beasts", [
			Models.monster("beast", Color("7aa860")), Models.monster("mantis", Color("5fd890")), Models.monster("tortoise", Color("b8903a")),
			Models.monster("crab", Color("d0502a")), Models.monster("spider", Color("5a3a90")),
		], 1.5)
		await _gallery("gallery_spirits", [
			Models.monster("phoenix", Color("ff8a2a")), Models.monster("ray", Color("7ab0f0")), Models.monster("jelly", Color("7ad8ff")),
			Models.monster("wraith", Color("6a5a8a")), Models.monster("tome", Color("40c090"), true),
		], 1.6)
		await _gallery("gallery_giants", [
			Models.monster("dragon", Color("3a8ad8")), Models.monster("golem", Color("e0501a")), Models.monster("serpent", Color("2a9a8a")),
			Models.monster("plant", Color("4fc07a")), Models.monster("storm", Color("c8d8ff")),
		], 1.7)
	if main.args.has("portraits") or not main.args.has("no-extras"):
		await _portraits("portrait_heroes", [
			Models.person(Color("3a8ae8"), Color("1a1a2a"), main.world.HERO_OPTS),
			Models.person(Color("e86a9a"), Color("402030"), main.world.YUE_OPTS),
			Models.person(Color("e8e8ff"), Color("2a2a3a"), {"asset": "elder_qing", "beard": true, "staff": true, "hair": "bald", "trim": Color("c8a850")}),
		], 0.9, 1.5, 3.2)
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
