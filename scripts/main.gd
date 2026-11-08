extends Node
## Orchestrator: screen stack, input routing, story logic.

var screens := {}
var stack: Array = []
var world
var battle
var dialogue
var menu
var shop
var meditate
var title
var ending
var choice
var bot = null
var bot_active := false
var args := {}
var toast_list: Array = []
var chat_idx := {}
## the realm each townsperson last noticed in Lin Feng (Part XII)
var greeted := {}
var post: PostFX = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(UI.C_BG)
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	world = _make("world")
	battle = _make("battle")
	meditate = _make("meditate")
	title = _make("title")
	ending = _make("ending")
	dialogue = _make("dialogue")
	menu = _make("menu")
	shop = _make("shop")
	choice = _make("choice")
	if DisplayServer.get_name() != "headless" and not args.has("no-post"):
		post = PostFX.new()
		post.name = "post"
		add_child(post)
	Game.level_changed.connect(func(): fx_pulse())
	if args.has("bot"):
		seed(int(args.get("seed", "1234")))
	if args.has("timescale"):
		Engine.time_scale = float(args.timescale)
	push("title")
	if args.has("tour"):
		var tour = load("res://scripts/tour.gd").new()
		tour.main = self
		add_child(tour)
	if args.has("bot"):
		bot_active = true
		bot = load("res://scripts/bot.gd").new()
		bot.main = self
		add_child(bot)

func _make(n: String) -> ScreenBase:
	var node := ScreenBase.new()
	node.set_script(load("res://scripts/%s.gd" % n))
	node.setup(self)
	node.name = n
	add_child(node)
	node.show_screen(false)
	screens[n] = node
	return node

# ---------------------------------------------------------------- stack
func top_name() -> String:
	return stack.back() if not stack.is_empty() else ""

func push(n: String) -> void:
	stack.append(n)
	_refresh()

func pop() -> void:
	if not stack.is_empty():
		stack.pop_back()
	_refresh()

func set_stack(names: Array) -> void:
	stack = names
	_refresh()

func _refresh() -> void:
	var first := 0
	for i in stack.size():
		if screens[stack[i]].opaque:
			first = i
	var shown := {}
	for i in range(first, stack.size()):
		shown[stack[i]] = true
	for n in screens:
		if not shown.has(n):
			screens[n].show_screen(false)
	for i in range(first, stack.size()):
		screens[stack[i]].show_screen(true)
	if post != null:
		# cinematic bars while a conversation plays over the 3D world
		post.letterbox_target = 0.075 if top_name() == "dialogue" and stack.size() > 1 and stack[stack.size() - 2] == "world" else 0.0
		post.enabled = not screens[stack[first]].scene3d == null if not stack.is_empty() else false

# ---------------------------------------------------------------- post-processing helpers (no-ops headless)
func fx_theme(name: String) -> void:
	if post != null:
		post.set_theme(name)

func fx_flash(col: Color = Color.WHITE, strength: float = 0.5) -> void:
	if post != null:
		post.do_flash(col, strength)

func fx_pulse() -> void:
	if post != null:
		post.do_pulse()

# ---------------------------------------------------------------- input
func _unhandled_input(ev: InputEvent) -> void:
	if bot_active or not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	match ev.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_Z, KEY_SPACE:
			press("confirm")
		KEY_ESCAPE, KEY_X:
			press("cancel")
		KEY_Q:
			if top_name() == "world":
				world.rotate_cam(-1)
		KEY_E:
			if top_name() == "world":
				world.rotate_cam(1)
		KEY_UP, KEY_W:
			press("up")
		KEY_DOWN, KEY_S:
			press("down")
		KEY_LEFT, KEY_A:
			press("left")
		KEY_RIGHT, KEY_D:
			press("right")

func press(act: String) -> void:
	var top := top_name()
	if top == "world":
		if act == "cancel":
			open_menu()
		elif act == "confirm":
			var e = world.face_entity()
			if e != null:
				interact(e)
	elif top != "":
		screens[top].press(act)

func _process(d: float) -> void:
	for t in toast_list:
		t.t -= d
	toast_list = toast_list.filter(func(t): return t.t > 0.0)
	while not Game.toasts.is_empty():
		toast_list.append({"text": Game.toasts.pop_front(), "t": 3.5})
	while toast_list.size() > 4:
		toast_list.pop_front()

func say(lines: Array, cb: Callable = Callable()) -> void:
	# an empty conversation used to push an empty dialogue box that Enter could never close
	if lines.is_empty():
		if cb.is_valid():
			cb.call()
		return
	dialogue.start(lines, cb)
	push("dialogue")

func open_menu() -> void:
	menu.open()
	push("menu")

## A choice over the world (Part XI): `cb` gets the chosen option's id ("" if cancelled).
func choose(title_text: String, options: Array, cb: Callable, cancel_ok: bool = true) -> void:
	if options.is_empty():
		cb.call("")
		return
	choice.start(title_text, options, cb, cancel_ok)
	push("choice")

## Choose the Dao Lin Feng walks: the first time from the Elder (no way out of that one), later at any
## Dao Stele.  Each option shows the Dao's motto, what it does and how far he has walked it.
func open_dao_choice(from: String) -> void:
	var opts: Array = []
	for id in Data.DAO_ORDER:
		var d: Dictionary = Data.DAOS[id]
		var tier := Game.dao_tier(id)
		var rank := "" if not Game.dao_xp.has(id) else str(Data.DAO_RANKS[tier])
		var desc: String = str(d.desc) + "\n\nIts technique, from Adept on: %s." % Data.SKILLS[d.skill].n
		var hon: Array = []
		for r in Data.RACE_ORDER:
			if r != "human" and Data.RACES[r].dao == id:
				hon.append(str(Data.RACES[r].n))
		if not hon.is_empty():
			desc += "\nHonoured by the %s." % ", ".join(hon)
		if id == Game.dao:
			desc += "\n\nThe road you walk now."
		opts.append({"id": id, "label": d.n, "sub": d.motto, "desc": desc, "note": rank, "col": d.col, "current": id == Game.dao})
	var first := Game.dao == ""
	choose("Which road will you walk?" if first else "The Dao Stele: walk another road?", opts, func(id: String):
		if id == "" or id == Game.dao:
			return
		Game.choose_dao(id)
		if first:
			say(Data.DAO_LINES.get("dao_chosen", {}).get(id, []))
		else:
			say([["Dao Stele", str(Data.DAOS[id].motto)]])
	, not first)

## A conversation with the lines the Dao Lin Feng walks adds to it (Part XI): the Elder's answer,
## what Chong and Li make of it, the ending; and when one of the peoples of the realms first speaks to
## him in a quest scene, what their people think of his Dao.
func dao_dialogue(key: String, npc: Dictionary = {}) -> Array:
	var lines: Array = Data.DIALOGUE.get(key, []).duplicate()
	if Game.dao == "":
		return lines
	var extra: Array = Data.DAO_LINES.get(key, {}).get(Game.dao, [])
	lines.append_array(extra)
	var race: String = str(npc.get("race", ""))
	if race != "" and extra.is_empty() and key in Data.DAO_GREETS:
		var rl: String = str(Data.RACES[race].dao_lines.get(Game.dao, ""))
		if rl != "":
			lines.append([str(npc.get("n", "")), rl])
	return lines

## Wake a branch of the Nine Heavens root (Part XII): one choice for every awakening Lin Feng has
## not spent yet, then `cb`.  Each option shows the branch's rank, what the next rank adds and the
## power of its crown.  There is no way out of it: a stirring root does not wait.
func open_talent_choice(cb: Callable = Callable()) -> void:
	if Game.talent_pts <= 0:
		if cb.is_valid():
			cb.call()
		return
	var opts: Array = []
	for id in Data.TALENT_ORDER:
		var tl: Dictionary = Data.TALENTS[id]
		var rk := Game.talent(id)
		if rk >= Data.TALENT_MAX:
			continue
		var desc: String = str(tl.desc) + "\n\nEach rank: %s.\nCrown (rank %d): %s" % [tl.per, Data.TALENT_MAX, tl.crown]
		opts.append({"id": id, "label": tl.n, "sub": "%s, then %s" % [Data.TALENT_RANKS[rk], Data.TALENT_RANKS[rk + 1]], "desc": desc, "note": "rank %d/%d" % [rk, Data.TALENT_MAX], "col": tl.col})
	if opts.is_empty():
		# every branch already in full leaf: the awakening deepens the root instead
		Game.talent_pts = 0
		Game.add_exp(float(Game.exp_need()) * 0.25)
		if cb.is_valid():
			cb.call()
		return
	choose("A branch of the Nine Heavens root stirs. Which will you wake?", opts, func(id: String):
		Game.wake_talent(id)
		open_talent_choice(cb)
	, false)

func start_meditation() -> void:
	meditate.start()
	push("meditate")

func game_finished_ack() -> void:
	if not bot_active:
		set_stack(["title"])

# ---------------------------------------------------------------- flow
func new_game() -> void:
	Game.reset()
	# a second run from the title must not inherit the last run's toasts or chat rotation
	toast_list.clear()
	chat_idx.clear()
	greeted.clear()
	world.clear_cache()
	world.load_area("sect", Vector2i(20, 8))
	set_stack(["world"])
	say([
		["Narrator", "Azure Cloud Sect, perched above the sea of clouds. For three years the orphan Lin Feng has swept its steps."],
		["Narrator", "Today, the old Elder summons him. Walk to the Elder with the arrow keys and press Enter to speak."],
	])

func interact(e: Dictionary) -> void:
	match e.kind:
		"npc":
			talk_npc(e)
		"enemy":
			# realm suppression in the world (Part XII): a pack two realms below Lin Feng will not fight him
			if Game.scatters(e.group):
				scatter_pack(e)
			else:
				start_encounter(e)
		"boss":
			boss_interact(e)
		"seal":
			var need: Dictionary = Data.STEPS[Data.step_index(e.open)]
			Game.toast("A Lotus Seal bars the road to %s. (%s)" % [Data.AREAS[e.to].n, need.t])
		"pickup":
			Game.taken[e.id] = true
			if e.item == "stones":
				# a cache of spirit stones somebody hid upstairs or in a cellar
				Game.stones += int(e.get("n", 0))
				Game.toast("Found a cache of %d spirit stones" % int(e.get("n", 0)))
			else:
				Game.add_item(e.item)
				Game.toast("Obtained %s" % Data.ITEMS[e.item].n)
			Game.poll_steps()
		"ladder":
			# the Jianmu between the realms (Part XI), or a flight of stairs in a building
			if world.ladder_open(e):
				world.use_ladder(e)
			else:
				var need2: Dictionary = Data.STEPS[Data.step_index(str(e.open))]
				Game.toast("The way is closed for now. (%s)" % need2.t)
		"stele":
			open_dao_choice("stele")
		"abode":
			open_abode(e)

func talk_npc(e: Dictionary) -> void:
	var s := Game.cur_step()
	var race: String = str(e.get("race", ""))
	if race != "":
		Game.met[race] = true
	if not s.is_empty() and s.kind == "talk" and s.npc == e.id and s.area == e.get("area", Game.area):
		var sid: String = s.id
		say(dao_dialogue(sid, e), func():
			Game.advance()
			if sid == "s_yue":
				Game.companion = true
				Game.hp[1] = float(Game.max_hp(1))
				Game.qi[1] = float(Game.max_qi(1))
				Game.toast("Yue Ling joins your party!")
				Game.note("Yue Ling joined")
			if sid == "s_p11_home":
				# the Jianmu has grown back: every road is open now, and Lin Feng must choose his
				open_dao_choice("elder")
			if sid == "s_report1":
				# Part XII: his qi stirs for the first time, and with it the first branch of his root
				Game.awaken("Lin Feng's qi stirred for the first time")
				open_talent_choice()
		)
		return
	var chats: Array = Data.CHAT.get(str(e.get("asset", e.id)), Data.CHAT.get(e.id, ["..."])).duplicate()
	# the peoples of the realms speak to the Dao Lin Feng walks, now and then
	if race != "" and Game.dao != "":
		var rl: String = str(Data.RACES[race].dao_lines.get(Game.dao, ""))
		if rl != "":
			chats.append(rl)
	# what people only say once the story has got there (Part XII)
	for cl in Data.CHAT_LATER.get(str(e.get("asset", e.id)), []):
		if Game.done(str(cl[0])):
			chats.append(str(cl[1]))
	# what people will only tell a cultivator of a high enough realm (Part XII): the deeper lore
	for dl in Data.CHAT_DEEP.get(str(e.get("asset", e.id)), []):
		if Game.level >= int(dl[0]):
			chats.append(str(dl[1]))
	var i: int = chat_idx.get(e.id, 0)
	chat_idx[e.id] = i + 1
	var lines := [[e.n, chats[i % chats.size()]]]
	# townsfolk feel a cultivator's realm (Part XII): the first word after every breakthrough is about it
	var band := Data.realm_band(Game.level)
	if Data.CHAT.has(str(e.get("asset", e.id))) and int(greeted.get(e.id, -1)) != Game.realm() and e.id != "elder":
		greeted[e.id] = Game.realm()
		if band > 0:
			lines.push_front([e.n, Data.REALM_GREETS[band] % Game.address()])
	if e.id == "elder":
		lines.append([e.n, "Your task: " + Game.objective_text()])
	var after := Callable()
	if e.id == "alchemist":
		after = func(): shop.open("alchemist"); push("shop")
	elif e.id == "smith":
		after = func(): shop.open("smith"); push("shop")
	elif race != "" and Game.inv.get(str(Data.RACES[race].gift), 0) > 0:
		# carrying a keepsake their people love: offer it
		after = func(): offer_gift(e)
	say(lines, after)

## Offer one of the peoples of the realms the keepsake they love (Part XI).
func offer_gift(e: Dictionary) -> void:
	var race: String = str(e.race)
	var item: String = str(Data.RACES[race].gift)
	var have: int = Game.inv.get(item, 0)
	choose("A gift for %s?" % e.n, [
		{"id": "give", "label": "Give the %s" % Data.ITEMS[item].n, "note": "you have %d" % have, "desc": str(Data.ITEMS[item].desc) + "\n\nThe %s call you %s." % [Data.RACES[race].n, Game.race_title(race)], "col": Look.PICKUP_COLORS.get(item, UI.C_GOLD)},
		{"id": "keep", "label": "Not now", "desc": "Keep it for now.", "col": UI.C_DIM},
	], func(id: String):
		if id == "give" and Game.give_gift(race):
			say([[str(e.n), str(Data.RACES[race].thanks)]])
	)

## A pack too far below Lin Feng's realm to fight scatters before his aura: it leaves the road (and
## comes back later, like any pack), but there is nothing to be learned from a beast that runs.
func scatter_pack(e: Dictionary) -> void:
	Game.defeated[e.id] = Game.playtime
	Game.scattered += 1
	var d: Dictionary = Data.ENEMIES[e.group[0].id]
	Game.toast("%s scatter before your %s aura" % [d.n, Data.REALMS[Game.realm()]])
	# a pack that runs has been driven off all the same: it counts for a hunt (an over-cultivated player
	# could otherwise never finish one)
	Game.record_kills(str(e.get("area", Game.area)), e.group.size())

## One of the Founder's sealed caves (Part XII): a door that opens only to a cultivator of the realm
## carved on it.  Inside, the Founder's words, a gift of spirit stones and an awakening of the root.
func open_abode(e: Dictionary) -> void:
	var id: String = str(e.id)
	if Game.abodes.has(id):
		say([["Narrator", "The cave is empty now, but for the Founder's words on the wall: \"%s\"" % str(e.motto)]])
		return
	if Game.level < int(e.req):
		say([["Narrator", "A seal of the %s realm is carved on the stone door, and it does not so much as warm under Lin Feng's palm. It will open for a cultivator of %s." % [Data.REALMS[Data.realm_of(int(e.req))], Data.level_name(int(e.req))]]])
		return
	Game.abodes[id] = true
	Game.stones += int(e.get("stones", 0))
	Game.note("Opened " + str(e.n))
	var lines: Array = Data.DIALOGUE.get("abode:" + id, []).duplicate()
	lines.append(["Narrator", "The seal knows the realm in him and the door rolls aside. Inside: %d spirit stones the Founder left for whoever came, and on the wall, carved by a sword: \"%s\"" % [int(e.get("stones", 0)), str(e.motto)]])
	say(lines, func():
		Game.awaken(str(e.n))
		open_talent_choice()
	)

func start_encounter(e: Dictionary) -> void:
	battle.start(e.group, {"entity": e, "boss": false, "theme": world.theme_name})
	push("battle")

func boss_interact(e: Dictionary) -> void:
	var s := Game.cur_step()
	var d: Dictionary = Data.ENEMIES[e.enemy]
	if s.is_empty() or s.kind != "kill" or s.boss != e.enemy:
		say([["Narrator", "%s looms before you, but this is not the time. Finish your current objective first." % d.n]])
		return
	if Game.level < e.req:
		say([["Narrator", "%s radiates a suffocating aura. You need at least %s cultivation." % [d.n, Data.level_name(e.req)]]])
		return
	say(Data.DIALOGUE.get("pre:" + e.enemy, []), func():
		battle.start([{"id": e.enemy, "lv": e.lv}], {"entity": e, "boss": true, "enemy": e.enemy, "theme": world.theme_name})
		push("battle")
	)

func start_breakthrough() -> void:
	var s := Game.cur_step()
	if s.is_empty() or s.kind != "breakthrough" or not Game.can_breakthrough():
		return
	var sid: String = s.id
	say(Data.DIALOGUE.get("pre:" + sid, []), func():
		# heaven's jealousy (Part XII): the more of the Nine Heavens root is awake, the harder the test
		battle.start([{"id": "tribulation", "lv": Game.level + 1, "mult": 1.1 * (1.0 + Data.TRIB_JEALOUSY * Game.talent_ranks())}], {"boss": true, "tribulation": true, "step": sid, "theme": "thunder"})
		push("battle")
	)

## The breakthroughs that close a chapter and the dialogue that brings Lin Feng home after them.
const RECALLS := {"s_break6": "recall", "s_break8": "recall2", "s_break9": "recall3", "s_break10": "recall4", "s_break11": "recall5",
	"s_break12": "recall6", "s_break13": "recall7", "s_break14": "recall8", "s_break15": "recall9", "s_break16": "recall10"}

## After the Dao-Merging tribulation (Part III), the True Immortal ascension (Part IV) and the
## Dao Ancestor ascension (Part V) and the Primordial Sovereign ascension (Part VI) the story
## brings Lin Feng home to the sect; so do the breakthroughs that close Parts VI to IX.
func recall_to_sect(key: String = "recall") -> void:
	world.load_area("sect", Vector2i(20, 9))
	Game.note("The Lotus Seal recalls Lin Feng to the sect")
	say(Data.DIALOGUE[key])

func battle_done(outcome: String, ctx: Dictionary) -> void:
	pop() # battle
	match outcome:
		"win":
			if ctx.get("tribulation", false):
				var sid: String = ctx.step
				Game.do_breakthrough()
				Game.advance()
				say(dao_dialogue("post:" + sid), func():
					if Game.finished:
						Game.note("Ending reached")
						push("ending")
						return
					# every tribulation survived wakes a branch of the root (Part XII), and then the
					# breakthroughs that close a chapter bring Lin Feng home
					Game.awaken("the tribulation of %s" % Data.REALMS[Game.realm()])
					open_talent_choice(func():
						if RECALLS.has(sid):
							recall_to_sect(RECALLS[sid])
					)
				)
			elif ctx.get("boss", false):
				var e: Dictionary = ctx.entity
				Game.boss_done[ctx.enemy] = true
				if Data.BOSS_DROPS.has(ctx.enemy):
					var drop: String = Data.BOSS_DROPS[ctx.enemy]
					Game.add_item(drop)
					Game.toast("Obtained %s" % Data.ITEMS[drop].n)
				Game.note("Defeated " + Data.ENEMIES[ctx.enemy].n)
				Game.advance()
				var post: Array = dao_dialogue("post:" + ctx.enemy)
				if not post.is_empty():
					say(post)
			else:
				var e2: Dictionary = ctx.entity
				Game.defeated[e2.id] = Game.playtime
				Game.record_kills(e2.get("area", Game.area), e2.group.size())
		"lose":
			Game.respawn()
			world.load_area("sect", Vector2i(20, 8))
			say([["Narrator", "You wake in the sect infirmary. Elder Qing Xuan watches over you. Some spirit stones were lost to the healers."]])
		_:
			pass
