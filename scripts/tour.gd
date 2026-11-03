extends Node
## Screenshot tour (developer tool).  Teleports through every screen, region and boss and saves
## PNGs.  Needs a real window (use xvfb on a server):
##   godot --path . --fixed-fps 30 -- --tour=docs/screenshots

var main
var dir := ""

const ELEMS := {"sect": "phys", "bamboo": "fire", "marsh": "fire", "frost": "thunder", "thunder": "earth", "palace": "water", "dragon": "thunder", "volcano": "water", "void": "dark", "celestial": "thunder", "mirror": "thunder", "grave": "fire", "time": "dark", "origin": "thunder"}

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
		main.world.load_area(id, Vector2i(2, 2))
		main.world.ptile = _nearest_free(focus)
		main.world.target = main.world.ptile
		main.world.facing = Vector2i(1, 0)
		main.world._snap_cam()
		main.world.cam_q = 0
		Game.tile = main.world.ptile
		main.world.banner_t = 0.0
		await _wait(1.2)
		await _shot("world_" + id)
		if id == "sect":
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
