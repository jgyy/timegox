extends SceneTree
## Feeds real keyboard events (no bot) into the game: title -> character creation (a name typed, a
## look and an origin changed) -> dialogue -> walk -> menu -> a thing to do (props.gd): face it, Enter,
## he does it, Enter again finishes it; T to Yue Ling; F swings the sword and G throws the sword qi;
## a key held into somebody talks to them once; and (the Hollow Hills release) a key held into the mouth
## of a cave goes down into it, a step is walked on its floor, and the way out comes up into the daylight;
## and (the High Roads release) a key held up a crag climbs it to the top, V opens the cloud-kite there,
## and the flight comes down on open ground; and (the Thundering Pots release) a field battle is fought to
## the end with the arrow keys and Enter, and the songbook is opened and a tune asked for.
## Run: godot --headless --path . --script tests/manual_input_test.gd

var main
var frame := 0
var fails := 0
var start_y := 0
## the thing to do tried at the end, and the frame the wait for it began
var prop := {}
var wait_from := 0
## the walk into a cave and out again: its stage, and the frame the stage began
var cave := {}
## the field battle and the pages at the very end
var pots := {}

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

## The key that walks the hero the way `dir` now (the keys follow the camera).
func key_for(dir: Vector2i) -> int:
	var w = main.world
	var f: Vector2i = w.FWD[w.cam_q]
	var r: Vector2i = w.RIGHT[w.cam_q]
	return [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN][[-r, r, f, -f].find(dir)]

## Down into the cave under the Bamboo Forest by its mouth, a step on its floor, and out again.
func cave_step() -> void:
	var w = main.world
	var lay := Caves.layout("bamboo")
	var since: int = frame - int(cave.at)
	match int(cave.stage):
		0:
			var hit: Array = w.locate_ent("cave:bamboo")
			expect(not hit.is_empty() and str(hit[0]) == "surface", "there is a cave mouth in the Bamboo Forest")
			if hit.is_empty():
				print("failures: ", fails)
				quit(1)
				return
			cave["mouth"] = hit[1].pos
			w.teleport(hit[1].pos + Vector2i(0, 1), "surface")
			cave["key"] = key_for(Vector2i(0, -1))
			key(int(cave.key), true)
			cave.stage = 1
			cave.at = frame
		1:
			if w.is_cave() and not w.traveling():
				key(int(cave.key), false)
				expect(str(w.layer) == Caves.fid("bamboo") and w.ptile == lay.arrive and main.top_name() == "world", "a key held into the cave mouth goes down into the cave (%s)" % str(w.wd.bld_n))
				expect(absf(w._player_pos().y - w.ground_y(w.wpos(w.ptile))) < 0.01, "and he stands on its floor")
				cave.stage = 2
				cave.at = frame
			elif since > 400:
				expect(false, "a key held into the cave mouth goes down into the cave")
				print("failures: ", fails)
				quit(1)
		2:
			# (the key must be let go before he will walk again: he arrives facing the way he came)
			if since == 10:
				var ahead: Vector2i = lay.arrive + Vector2i(0, -1)
				if w.tile_free(ahead) and w.ent_at(ahead) == null:
					cave["key"] = key_for(Vector2i(0, -1))
					key(int(cave.key), true)
				else:
					cave.stage = 3
					cave.at = frame
			elif since > 10 and w.ptile != lay.arrive:
				key(int(cave.key), false)
				expect(w.ptile.x == lay.arrive.x and w.ptile.y < lay.arrive.y and w.is_cave() and w.tile_free(w.ptile), "he walks on the cave's floor like any other")
				cave.stage = 3
				cave.at = frame
			elif since > 300:
				expect(false, "he walks on the cave's floor like any other")
				cave.stage = 3
				cave.at = frame
		3:
			if since == 10:
				cave["key"] = key_for(Vector2i(0, 1))
				key(int(cave.key), true)
			elif since > 10 and not w.is_cave() and not w.traveling():
				key(int(cave.key), false)
				expect(str(w.layer) == "surface" and w.ptile == (cave.mouth as Vector2i) + Vector2i(0, 1), "and the way out comes up into the daylight, in front of the mouth")
				# and last of all, the arms rack (the Hundred Arms release): Esc > Arms, down to the staff, Enter
				cave.stage = 4
				cave.at = frame
			elif since > 500:
				expect(false, "the way out of the cave comes up into the daylight")
				print("failures: ", fails)
				quit(1)
		4:
			if since == 20:
				expect(Arms.held(root.get_node("Game")) == "sword" and Arms.attached(w.player) == "sword", "he comes out of the cave with the jian in his hand")
				tap(KEY_ESCAPE)
			elif since > 22 and since < 200 and main.top_name() == "menu" and main.menu.mode == "root":
				var want: int = main.menu.ids.find("arms")
				if since == 24:
					expect(want >= 0 and main.menu.enabled.size() == main.menu.ids.size() and main.menu.enabled[want], "the menu has the arms rack, and knows which of its entries can be chosen")
				if main.menu.cursor != want:
					tap(KEY_DOWN)
				elif since % 2 == 0:
					tap(KEY_ENTER)
			elif since > 22 and since < 260 and main.top_name() == "choice" and not cave.has("racked"):
				cave["racked"] = frame
				expect(str(main.choice.title) == main.ARMS_ASK and main.choice.ids() == Arms.ORDER, "Enter on Arms opens the rack, with all eight on it")
				tap(KEY_DOWN)
			elif cave.has("racked") and frame == int(cave.racked) + 4:
				expect(main.top_name() == "choice" and Arms.attached(w.player) == "staff" and Arms.held(root.get_node("Game")) == "sword", "the weapon under the cursor is shown in his hand before it is chosen")
				tap(KEY_ENTER)
			elif cave.has("racked") and frame == int(cave.racked) + 10:
				expect(main.top_name() == "world" and Arms.held(root.get_node("Game")) == "staff" and Arms.attached(w.player) == "staff", "Enter takes the staff in hand")
				tap(KEY_F)
			elif cave.has("racked") and frame == int(cave.racked) + 13:
				expect(str(w.player.get_meta("act", "")) == "arm_staff" and Faces.worn(w.player) == "shout", "F strikes with the staff's own blow, and it shows in his face")
				# and last of all, up a crag on his hands and down again under the cloud-kite (the High Roads release)
				cave.stage = 5
				cave.at = frame
			elif since > 400:
				expect(false, "the arms rack opens from the menu")
				print("failures: ", fails)
				quit(1)

## The High Roads release (peaks.gd): a key held up a rock face climbs it to the summit, V opens the
## cloud-kite there, and the flight ends on open ground.
func high_step() -> void:
	var w = main.world
	var g = root.get_node("Game")
	var since: int = frame - int(cave.at)
	if since == 20:
		var pk: Dictionary = Peaks.by_id(w.wd, "peak:mountain:1")
		expect(not pk.is_empty() and float(pk.h) > 10.0, "the mountain has a second peak, and it is a real one (%s m)" % str(pk.get("h", 0)))
		cave["peak"] = pk
		# three tiles down its south side, facing up
		var c: Vector2i = pk.c
		w.teleport(c + Vector2i(0, 3), "surface")
		cave["key"] = key_for(Vector2i(0, -1))
		cave["rock"] = Peaks.at(w.wd, c) - Peaks.at(w.wd, c + Vector2i(0, 3))
		key(int(cave.key), true)
	elif since > 20 and not cave.has("top"):
		if int(w.climb) > 0:
			cave["climbed"] = true
		# (a held key goes straight on over the top: the summit is his the moment he stands on it)
		if g.summits.has(str(cave.peak.id)):
			key(int(cave.key), false)
			cave["top"] = frame
			expect(cave.has("climbed") and float(g.climbed) > 3.0 and float(cave.rock) > 3.0, "a key held up the rock climbs it, hand over hand (%.1f m of %.1f)" % [float(g.climbed), float(cave.rock)])
			expect(g.summits.has(str(cave.peak.id)), "and standing on the very top is a summit stood on")
		elif since > 900:
			print("    (at %s of %s, top %s, moving %s, climb %d, prologue '%s', key lock %s, free ahead %s)" % [str(w.ptile), str(cave.peak.c), main.top_name(), str(w.move_dir), int(w.climb), str(g.prologue), str(w.key_lock), str(w.tile_free(w.ptile + Vector2i(0, -1)))])
			expect(false, "a key held up the rock reaches the top")
			print("failures: ", fails)
			quit(1)
	elif cave.has("top") and frame == int(cave.top) + 40:
		# the way the air is clear for longest, as somebody on a summit would look round
		var best := Vector2i(0, 1)
		var bn := 0
		for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			if int(w.glide_reach(d)) > bn:
				bn = int(w.glide_reach(d))
				best = d
		cave["reach"] = bn
		w.facing = best
		tap(KEY_V)
	elif cave.has("top") and frame > int(cave.top) + 40 and not cave.has("air"):
		# (the kite opens at his next footfall, if he is still finishing a step)
		if w.gliding():
			cave["air"] = frame
			expect(int(g.glides) == 1 and int(cave.reach) >= 6, "V at the top opens the cloud-kite, and he is in the air (%d tiles of it ahead)" % int(cave.reach))
		elif frame > int(cave.top) + 400:
			expect(false, "V at the top opens the cloud-kite")
			print("failures: ", fails)
			quit(1)
	elif cave.has("air") and not w.gliding():
		expect(int(g.glided) >= 6 and int(g.glide_best) == int(g.glided) and w.tile_free(w.ptile) and w.ent_at(w.ptile) == null and Peaks.at(w.wd, w.ptile) < float(cave.peak.h) * 0.5 and main.top_name() == "world",
			"the flight ends on open ground lower down (%d tiles flown)" % int(g.glided))
		# and last (the Thundering Pots release): a field battle fought with the keys, and the new pages
		pots = {"field": frame, "clock": Time.get_ticks_msec()}
		g.host = {"sect": true, "valley": true, "steppe": true, "sand": true, "river": true, "forge": true, "dawn": true}
		g.airs = {"valley": true, "river": true}
		main.start_war("drill1", {})
	elif cave.has("top") and frame > int(cave.top) + 1500:
		expect(false, "the flight comes down")
		print("failures: ", fails)
		quit(1)


## The Thundering Pots release: a lesson of Master Sun's fought with the arrow keys and Enter, then the
## menu's new pages and a tune asked for out of the songbook.
func pots_step() -> void:
	var g = root.get_node("Game")
	if not pots.has("done"):
		# (a key every sixth frame: one press is seen before the next is made)
		if frame % 6 != 0:
			return
		var f = main.field
		if main.top_name() == "field" and str(f.state) == "order":
			if not pots.has("seen"):
				pots["seen"] = true
				expect(f.labels.size() == War.ORDER_IDS.size() and War.intent(f.st) != "", "a field battle opens on the scouts' word and seven orders")
				tap(KEY_DOWN)
			elif not pots.has("moved"):
				pots["moved"] = true
				expect(int(f.cursor) == 1, "Down moves the cursor down the orders")
				tap(KEY_UP)
			else:
				# the order Master Sun would give: walk the cursor to it, a key at a time, and Enter
				var want: int = f.ids.find(War.best(f.st))
				if int(f.cursor) == want:
					tap(KEY_ENTER)
				else:
					tap(KEY_DOWN if int(f.cursor) < want else KEY_UP)
		elif main.top_name() == "field" and str(f.state) == "result":
			pots["over"] = str(f.st.over)
			pots["drums"] = int(f.st.drum)
			tap(KEY_ENTER)
		elif main.top_name() == "world" and pots.has("over"):
			pots["done"] = frame
			expect(str(pots.over) == "won" and g.war_won.has("drill1") and int(g.war_won.drill1) == int(pots.drums), "the lesson is fought to the end with the keys and the field is held (in %d drums)" % int(pots.drums))
			tap(KEY_ESCAPE)
		elif Time.get_ticks_msec() > int(pots.clock) + 180000:
			expect(false, "a field battle can be fought to the end")
			print("failures: ", fails)
			quit(1)
	elif pots.has("done") and frame == int(pots.done) + 20:
		expect(main.top_name() == "menu" and main.menu.ids.has("feats") and main.menu.ids.has("songs") and main.menu.ids.has("host"), "the menu has its three new pages: the Host, Songs and Feats")
		main.menu.cursor = main.menu.ids.find("songs")
		tap(KEY_ENTER)
	elif pots.has("done") and frame == int(pots.done) + 40:
		expect(str(main.menu.mode) == "songs" and main.menu.labels.size() == Music.count() + 1, "Enter opens the songbook: every tune, and a way back")
		g.heard["title"] = true
		main.menu._build()
		main.menu.cursor = 0
		tap(KEY_ENTER)
	elif pots.has("done") and frame == int(pots.done) + 60:
		expect(Music.asked() == "title" and int(g.songs_played) == 1, "Enter on a tune that has been heard asks for it")
		tap(KEY_ESCAPE)
		tap(KEY_ESCAPE)
	elif pots.has("done") and frame == int(pots.done) + 80:
		expect(main.top_name() == "world" and Music.asked() == "", "and leaving the menu lets the land's own tune come back")
		print("failures: ", fails)
		quit(1 if fails > 0 else 0)

func _process(_d: float) -> bool:
	frame += 1
	if not pots.is_empty():
		pots_step()
		return false
	if not cave.is_empty() and int(cave.stage) == 5:
		high_step()
		return false
	if not cave.is_empty():
		cave_step()
		return false
	if frame > 5200:
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
			# (the typewriter types the name the player gave, never the story's own letter by letter)
			expect(main.dialogue.text_of(1).contains("Bai Chen's year was spent here") and not main.dialogue.text_of(1).contains("Lin Feng") and main.dialogue.line_len() == main.dialogue.text_of(0).length(),
				"a line is typed with the hero's own name in it from its first letter")
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
				# and last, down a cave and out again (the Hollow Hills release)
				cave = {"stage": 0, "at": frame}
		elif not u.is_empty() and bool(u.started):
			prop["started"] = true
			expect(not bool(u.ended), "he steps up to it and does it")
			tap(KEY_ENTER)
	return false
