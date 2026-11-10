extends SceneTree
## Feeds real keyboard events (no bot) into the game: title -> character creation (a name typed, a
## look and an origin changed) -> dialogue -> walk -> menu -> a thing to do (props.gd): face it, Enter,
## he does it, Enter again finishes it; T to Yue Ling; F swings the sword and G throws the sword qi;
## a key held into somebody talks to them once.
## Run: godot --headless --path . --script tests/manual_input_test.gd

var main
var frame := 0
var fails := 0
var start_y := 0
## the thing to do tried at the end, and the frame the wait for it began
var prop := {}
var wait_from := 0

func key(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)

func tap(code: int) -> void:
	key(code, true)
	key(code, false)

func expect(c: bool, m: String) -> void:
	print(("  ok   " if c else "  FAIL ") + m)
	if not c:
		fails += 1

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

func _process(_d: float) -> bool:
	frame += 1
	if frame > 2400:
		printerr("  FAIL smoke test did not finish (script error?)")
		quit(1)
	match frame:
		5:
			expect(main.top_name() == "title", "starts on title")
			tap(KEY_ENTER)
		8:
			expect(main.top_name() == "create", "New Game opens character creation")
			# Enter on the family name writes one of your own
			tap(KEY_ENTER)
		9:
			expect(main.create.typing == "family", "Enter on the name starts typing")
			for c in [KEY_B, KEY_A, KEY_I, KEY_1]:
				tap(c)
			tap(KEY_BACKSPACE)
			tap(KEY_I)
			tap(KEY_ENTER)
		10:
			expect(main.create.typing == "" and str(main.create.h.family) == "Bai", "a typed family name, letters only (%s)" % str(main.create.h.family))
			# the given name from the rolls, a young woman, the next look, the next trade, the next hearth
			tap(KEY_DOWN)
			tap(KEY_RIGHT)
			tap(KEY_DOWN)
			tap(KEY_RIGHT)
			tap(KEY_DOWN)
			tap(KEY_RIGHT)
			for i in 4:
				tap(KEY_DOWN)
			tap(KEY_RIGHT)
			tap(KEY_DOWN)
			tap(KEY_RIGHT)
		11:
			var h: Dictionary = main.create.h
			expect(str(h.given) == "Chen" and str(h.look) == "wanderer" and str(h.origin) == "fisher", "Left/Right change the name, the look and the origin (%s)" % str(h))
			expect(str(h.body) == "f" and str(h.hearth) == "steppe" and main.create.value_text("origin") == "Ferry-Hand of Qingshi" and not main.create.told("He poled the ferry.").contains("He "),
				"and who the sweeper is, and the hearth of the year away (the New Fire release)")
			tap(KEY_DOWN)
			tap(KEY_ENTER)
		12:
			var gs0 = root.get_node("Game")
			expect(gs0.hero_name() == "Bai Chen" and UI.named("Lin Feng swept the steps.") == "Bai Chen swept the steps.", "the journey begins with the name chosen, on screen everywhere")
			expect(gs0.fem() and UI.named("Lin Feng lifts his broom.") == "Bai Chen lifts her broom." and UI.named("Elder Qing Xuan puts down his cup.") == "Elder Qing Xuan puts down his cup.", "she is told of as she, and the Elder as he")
			expect(int(gs0.inv.get("hp_pill", 0)) == 6 and gs0.max_hp(0) > Data.max_hp(0), "the origin's gift and strength (a ferry-hand: two more pills, more health), and the hearth's (one more)")
			expect(Cultures.own(gs0) == "steppe" and Cultures.tier(gs0, "steppe") == 2 and gs0.prologue == "steppe", "kin of the Felt Hearth, and the story begins there")
		15:
			expect(main.top_name() == "dialogue" and str(main.dialogue.lines[0][1]).contains("tents of the horse-folk"), "Begin starts the new game with the last morning at her hearth")
			# (three lines; Enter once to finish typing a line and once to go on)
			for i in 6:
				tap(KEY_ENTER)
		17:
			var gs1 = root.get_node("Game")
			var keeper = main.world.find_ent("sarnai")
			expect(main.top_name() == "world" and gs1.area == "thunder" and gs1.objective_text().contains("say goodbye to Grandmother Sarnai") and keeper != null, "three years ago, in the tents below Thunder Valley, with a goodbye to say")
			var dk: int = absi(keeper.pos.x - main.world.ptile.x) + absi(keeper.pos.y - main.world.ptile.y)
			var foes: int = main.world.ents.filter(func(e0): return e0.kind in ["enemy", "boss"] and main.world.ent_visible(e0)).size()
			expect(dk >= 2 and dk <= 6 and foes == 0 and main.world.leash == main.world.ptile, "the keeper is a short walk off, and nothing prowls (%d steps, %d foes)" % [dk, foes])
			# the leash: nobody leaves before the farewell is said
			main.world.ptile = main.world.leash + Vector2i(main.world.LEASH, 0)
			main.world.target = main.world.ptile
			main.world.move_dir = Vector2i(1, 0)
			main.world._move(0.2)
			expect(main.world.ptile == main.world.leash + Vector2i(main.world.LEASH, 0) and main.world.move_dir == Vector2i.ZERO, "and no walking away before it is said")
			main.world.key_lock = false
			main.world.ptile = main.world.leash
			main.world.target = main.world.leash
			main.interact(keeper)
		18:
			expect(main.top_name() == "dialogue" and str(main.dialogue.lines[0][0]) == "Grandmother Sarnai", "Enter facing the keeper: the farewell")
			# (the farewell's five lines, "Three years later.", and the three lines at the sect)
			for i in 18:
				tap(KEY_ENTER)
		20:
			var gs1b = root.get_node("Game")
			expect(gs1b.prologue == "" and gs1b.area == "sect" and gs1b.cur_step().id == "s_intro", "three years later: the sect, and the Elder's summons")
			expect(main.top_name() == "world", "dialogue dismissed with Enter")
			start_y = main.world.ptile.y
			key(KEY_DOWN, true)
		50:
			key(KEY_DOWN, false)
			expect(main.world.ptile.y > start_y, "held Down key walks the player (y %d -> %d)" % [start_y, main.world.ptile.y])
			tap(KEY_ESCAPE)
		55:
			expect(main.top_name() == "menu", "Esc opens menu")
			tap(KEY_ESCAPE)
		60:
			expect(main.top_name() == "world", "Esc closes menu")
			# a thing to do in the land that he keeps doing until he is told (not a one-shot), and a tile
			# beside it to do it from
			var w = main.world
			for e in w.ents:
				if e.kind == "prop" and not e.has("furn") and not Props.ONCE.has(str(Props.kind_of(e).clip)):
					var spot: Vector2i = e.pos + e.face
					w.teleport(spot)
					w.facing = e.pos - spot
					prop = e
					break
			expect(not prop.is_empty(), "there is a thing to do in the land")
		62:
			tap(KEY_ENTER)
		64:
			expect(not main.world.using.is_empty(), "Enter facing a thing to do starts doing it (%s)" % str(prop.get("prop", "")))
			wait_from = frame
	if frame > 64 and wait_from > 0:
		var u: Dictionary = main.world.using
		if prop.has("started"):
			if u.is_empty() and not prop.has("talked"):
				var gs = root.get_node("Game")
				expect(gs.pastimes.has(str(prop.prop)) and gs.prop_uses.has(str(prop.id)), "Enter again finishes it: a new pastime")
				expect(main.top_name() == "world", "and he can walk on")
				# the Lotus release: T talks to Yue Ling (bonds.gd); before she has joined, it only says so
				tap(KEY_T)
				prop["talked"] = frame
			elif prop.has("talked") and frame == int(prop.talked) + 2:
				var gs2 = root.get_node("Game")
				expect(main.top_name() == "world" and gs2.toasts.has("Yue Ling is not with you yet.") or main.toast_list.any(func(tt): return str(tt.text) == "Yue Ling is not with you yet."), "T before Yue Ling has joined: she is not with you yet")
				gs2.companion = true
				tap(KEY_T)
			elif prop.has("talked") and frame == int(prop.talked) + 4:
				expect(main.top_name() == "dialogue" and str(main.dialogue.lines[0][0]) == "Yue Ling", "T with Yue Ling beside him: she has a word to say")
				prop["sword"] = frame
			elif prop.has("sword") and not prop.has("struck"):
				# Enter through her words, then the sword (the Spring Thunder release: impact.gd): F swings
				# it, G throws the sword qi
				if main.top_name() == "dialogue":
					tap(KEY_ENTER)
				elif main.top_name() == "world":
					var gs3 = root.get_node("Game")
					gs3.qi[0] = gs3.max_qi(0)
					prop["struck"] = frame
					prop["strikes0"] = gs3.strikes
					prop["waves0"] = gs3.waves
					prop["qi0"] = float(gs3.qi[0])
					tap(KEY_F)
					tap(KEY_G)
			elif prop.has("struck") and frame == int(prop.struck) + 2:
				var gs4 = root.get_node("Game")
				expect(main.top_name() == "world" and gs4.strikes == int(prop.strikes0) + 1, "F swings the sword")
				expect(gs4.waves == int(prop.waves0) + 1 and float(gs4.qi[0]) < float(prop.qi0), "G throws the sword qi, for some of his qi (%.0f -> %.0f)" % [float(prop.qi0), float(gs4.qi[0])])
				# walking into somebody talks to them: hold the key into the Elder, Enter through what he
				# says, and keep holding it (the conversation used to open again the moment it closed)
				var w2 = main.world
				for e2 in w2.ents:
					if str(e2.id) != "elder" or not w2.ent_visible(e2):
						continue
					for dd in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
						var spot2: Vector2i = e2.pos + dd
						if prop.has("hold") or not w2.tile_free(spot2) or w2.ent_at(spot2) != null:
							continue
						w2.teleport(spot2)
						var f2: Vector2i = w2.FWD[w2.cam_q]
						var r2: Vector2i = w2.RIGHT[w2.cam_q]
						var keys := [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
						var dirs := [-r2, r2, f2, -f2]
						prop["hold"] = keys[dirs.find(-dd)]
						prop["held"] = frame
				expect(prop.has("hold"), "there is a way to walk up to the Elder")
				if prop.has("hold"):
					key(int(prop.hold), true)
				else:
					print("failures: ", fails)
					quit(1)
			elif prop.has("held") and not prop.has("closed"):
				if main.top_name() == "dialogue":
					prop["opened"] = true
					tap(KEY_ENTER)
				elif prop.has("opened") and main.top_name() == "world":
					prop["closed"] = frame
				elif frame > int(prop.held) + 600:
					expect(false, "walking into the Elder opens a conversation")
					print("failures: ", fails)
					quit(1)
			elif prop.has("closed") and frame == int(prop.closed) + 30:
				expect(main.top_name() == "world", "and with the key still held it does not open again the moment it closes")
				key(int(prop.hold), false)
				# a pack struck first flies back for a moment before its battle (impact.gd): Esc then must
				# not open the menu in its way (the battle never began)
				main.world.ambush_t = main.world.t
				tap(KEY_ESCAPE)
			elif prop.has("closed") and frame == int(prop.closed) + 32:
				expect(main.top_name() == "world", "Esc while a pack struck first is flying back does not open the menu over its battle")
				main.world.ambush_t = -1.0
				print("failures: ", fails)
				quit(1 if fails > 0 else 0)
		elif not u.is_empty() and bool(u.started):
			prop["started"] = true
			expect(not bool(u.ended), "he steps up to it and does it")
			tap(KEY_ENTER)
	return false
