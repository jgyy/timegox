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
var create
var bot = null
var bot_active := false
var args := {}
var toast_list: Array = []
var chat_idx := {}
## the realm each townsperson last noticed in Lin Feng (Part XII)
var greeted := {}
## the chapter of a fated encounter being played (fate.gd), "" when none
var fate_sid := ""
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
	create = _make("create")
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
	# writing a name at character creation: the keyboard types letters, not commands
	if top_name() == "create" and create.typing != "":
		create.type_key(ev)
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
		KEY_R:
			# mount up or get down (Fates and Faces: the stable)
			press("ride")
		KEY_T:
			# talk to Yue Ling (the Lotus release: bonds.gd)
			press("talk")
		KEY_F:
			# swing the sword at what is in front of him (the Living Land release: havoc.gd)
			press("strike")
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
	if top == "world" and not world.using.is_empty():
		# doing something (props.gd): Enter or Esc finishes it
		world.press_use(act)
		return
	if top == "world":
		if act == "ride":
			world.toggle_ride()
		elif act == "strike":
			world.strike()
		elif act == "talk":
			talk_yue()
		elif act == "cancel":
			open_menu()
		elif act == "confirm":
			var e = world.face_entity()
			if e != null:
				interact(e)
	elif top != "":
		screens[top].press(act)

func _process(d: float) -> void:
	_talk_hint()
	for t in toast_list:
		t.t -= d
	toast_list = toast_list.filter(func(t): return t.t > 0.0)
	while not Game.toasts.is_empty():
		var txt: String = Game.toasts.pop_front()
		# the same news again (walking into a closed Lotus Seal every frame) keeps its one line up instead
		# of filling the corner with copies and pushing out what else was said
		var same: Array = toast_list.filter(func(t): return t.text == txt)
		if not same.is_empty():
			same[0].t = 3.5
		else:
			toast_list.append({"text": txt, "t": 3.5})
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
	# who he was before the sect (character creation) has a word to say here and there
	lines.append_array(origin_lines(key))
	# the end of the climb: what became of the five whose lives he changed (fate.gd), and of the place
	# he came from
	if key == "post:" + str(Data.STEPS[Data.STEPS.size() - 1].id):
		for th in Fate.THREAD_ORDER:
			var ep := Fate.epilogue(Game, th)
			if ep != "":
				lines.append(["Narrator", ep])
		# and of the grudges that stayed, the ones laid to rest (grudges.gd)
		for ep2 in Grudges.epilogues(Game):
			lines.append(["Narrator", ep2])
		# and of Yue Ling, and the road she chose for herself (bonds.gd)
		for ep3 in Bonds.epilogues(Game):
			lines.append(["Narrator", ep3])
		lines.append_array(origin_lines("ending"))
	# the road Lin Feng took into the heart of the Eight Gates (Part XIII) tells the end its own way
	var road: String = str(Game.trials.get("chiyou", ""))
	if road != "":
		lines.append_array(Data.ROUTE_LINES.get(key, {}).get(road, []))
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
## New Game: first the sweeper is made (create.gd), then the journey begins (start_journey).
func open_creation() -> void:
	create.start()
	push("create")

## The journey begins with the sweeper the player made (character creation).
func start_journey(h: Dictionary) -> void:
	new_game(h)

func new_game(h: Dictionary = {}) -> void:
	Game.reset()
	if not h.is_empty():
		Game.create_hero(h)
	# a second run from the title must not inherit the last run's toasts or chat rotation
	toast_list.clear()
	chat_idx.clear()
	greeted.clear()
	world.clear_cache()
	world.refresh_hero()
	world.load_area("sect", Vector2i(20, 8))
	set_stack(["world"])
	var intro: Array = [["Narrator", "Azure Cloud Sect, perched above the sea of clouds. For three years the orphan Lin Feng has swept its steps."]]
	intro.append_array(origin_lines("intro"))
	intro.append(["Narrator", "Today, the old Elder summons him. Walk to the Elder with the arrow keys and press Enter to speak."])
	say(intro)

## The lines the hero's origin (character creation, Fashion.ORIGIN_LINES) adds to a conversation.
func origin_lines(key: String) -> Array:
	return Fashion.ORIGIN_LINES.get(key, {}).get(str(Game.hero.get("origin", "foundling")), []).duplicate()

func interact(e: Dictionary) -> void:
	match e.kind:
		"npc":
			talk_npc(e)
		"folk":
			talk_folk(e)
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
			if Game.dao == "":
				# (the steles stand once the Elder is ready to speak of the roads; until he has, they are
				# only carved stone, and the first choice is his to offer)
				say([["Narrator", "Six roads are carved on the stele, and every one runs off the edge of the stone. Elder Qing Xuan means to speak of them first."]])
			else:
				open_dao_choice("stele")
		"abode":
			open_abode(e)
		"prop":
			# Part XV: one of Yue Ling's memories, or the lotus pond where she woke (bonds.gd)
			if e.has("memory") and Bonds.memory_ready(Game, str(e.memory)):
				memory_scene(e)
				return
			var s0 := Game.cur_step()
			if not s0.is_empty() and str(s0.kind) == "share" and Bonds.spot_is(str(s0.get("spot", "")), e):
				share_scene(e, str(s0.id))
				return
			# a thing to do (props.gd): Lin Feng steps up to it and does it
			world.start_use(e)

## The Living Land release (folk.gd): a word with one of the people of the towns.
func talk_folk(e: Dictionary) -> void:
	var fp: Dictionary = e.p
	var lines := [[str(fp.n), Folk.line(fp, Game)]]
	Game.folk_talk[str(fp.id)] = int(Game.folk_talk.get(str(fp.id), 0)) + 1
	world.folk_talking = str(fp.id)
	# Part XVI: on New Year's Day the children of the towns are given red envelopes
	var s := Game.cur_step()
	var given := false
	if not s.is_empty() and s.kind == "folk" and Folk.is_role(fp, str(s.role)) and not Game.hongbao.has(str(fp.id)):
		Game.hongbao[str(fp.id)] = true
		given = true
		lines = [["Lin Feng", "A good new year to you. Here: for luck."], [str(fp.n), Folk.hongbao_line(fp)]]
	say(lines, func():
		world.folk_talking = ""
		if given:
			Game.toast("A red envelope for %s (%d of %d)" % [str(fp.n), Game.hongbao.size(), int(s.n)])
			Game.note("Gave %s a red envelope" % str(fp.n))
			Game.poll_steps()
	)

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
			if sid == "s_p16_doorgods":
				# Part XVI: two boards of peach wood carved with the door gods' names
				Game.add_item("peach_charm", 2)
				Game.toast("Obtained %s x2" % Data.ITEMS.peach_charm.n)
		)
		return
	# a fated encounter (fate.gd): a chapter of somebody's story, and a choice in it
	if not s.is_empty() and s.kind == "fate" and s.npc == e.id:
		play_chapter(str(s.id), e)
		return
	# Part XIV: the five threads settled in any order, each its own last chapter
	if not s.is_empty() and s.kind == "fates" and str(e.id) in s.npcs and not Game.visited.has(str(e.id)):
		play_chapter(Fate.chapter_of_npc(str(e.id)), e)
		return
	# Part XV: the people who knew Yue Ling tie a thread for her, in any order
	if not s.is_empty() and s.kind == "threads" and str(e.id) in s.npcs and not Game.threads.has(str(e.id)) and Game.companion:
		say(Data.DIALOGUE.get("thread:" + str(e.id), []), func():
			Game.threads[str(e.id)] = true
			Bonds.add(Game, 2, "a thread tied")
			Game.toast("A thread tied for Yue Ling (%d of %d)" % [Game.visits_done(s), int(s.n)])
			Game.note("%s tied a thread for Yue Ling" % str(e.n))
			Game.poll_steps()
		)
		return
	# Part XVI: a town reminded of the old ways, in any order; its people come out and practise
	if not s.is_empty() and s.kind == "rally" and str(e.id) in s.npcs and not Game.rallied.has(str(e.id)):
		say(Data.DIALOGUE.get("rally:" + str(e.id), []), func():
			Game.rallied[str(e.id)] = true
			world.drill(str(e.get("area", Game.area)))
			Game.toast("A town remembers the old ways (%d of %d)" % [Game.visits_done(s), int(s.n)])
			Game.note("%s's town remembers the old ways" % str(e.n))
			Game.poll_steps()
		)
		return
	# a step that asks for visits, in any order (Part XIII: the Conclave's invitations): this is one
	if not s.is_empty() and s.kind == "visits" and str(e.id) in s.npcs and not Game.visited.has(str(e.id)):
		say(Data.DIALOGUE.get("visit:" + str(e.id), []), func():
			Game.visited[str(e.id)] = true
			Game.toast("Invitation delivered (%d of %d)" % [Game.visits_done(s), int(s.n)])
			Game.note("Invited " + str(e.n))
			if race != "":
				Game.race_gain(race, 5)
			Game.poll_steps()
		)
		return
	var chats: Array = Data.CHAT.get(str(e.get("asset", e.id)), Data.CHAT.get(e.id, ["..."])).duplicate()
	# somebody met on the road (fate.gd) has their own words for afterwards
	if e.get("fate", false):
		chats = FateText.CHAT.get(str(e.id), ["..."]).duplicate()
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
	# a townsperson with something to ask (a deed, trials.gd) asks it instead
	var deed := Trials.deed_of(str(e.id), Game)
	if deed != "":
		lines = [[e.n, str(Trials.DEEDS[deed].ask)]]
	# townsfolk feel a cultivator's realm (Part XII): the first word after every breakthrough is about it
	var band := Data.realm_band(Game.level)
	if Data.CHAT.has(str(e.get("asset", e.id))) and int(greeted.get(e.id, -1)) != Game.realm() and e.id != "elder" and not e.get("fate", false):
		greeted[e.id] = Game.realm()
		if band > 0:
			lines.push_front([e.n, Data.REALM_GREETS[band] % Game.address()])
	if e.id == "elder":
		lines.append([e.n, "Your task: " + Game.objective_text()])
	var after := Callable()
	if e.id == "dyer_su" and _dyer_stock().size() > 0 and deed == "":
		# Dyer Su of the Dawn Market sells outfits (fashion.gd)
		after = func(): offer_outfits(e)
	elif e.id == "alchemist":
		after = func(): shop.open("alchemist"); push("shop")
	elif e.id == "smith":
		after = func(): shop.open("smith"); push("shop")
	elif deed != "":
		after = func(): offer_deed(e, deed)
	elif race != "" and Game.inv.get(str(Data.RACES[race].gift), 0) > 0:
		# carrying a keepsake their people love: offer it
		after = func(): offer_gift(e)
	say(lines, after)

# ---------------------------------------------------------------- fated encounters (fate.gd)
## A chapter of somebody's story: the variant for what Lin Feng made of them so far, then the choice.
func play_chapter(sid: String, e: Dictionary) -> void:
	var v := Fate.variant(Game, sid)
	if v.is_empty():
		return
	fate_sid = sid
	say(v.get("lines", []), func(): _fate_choice(sid, v))

## The choice of a chapter (or of the follow-up once its battle is won): every option says what it
## does, needs and brings; one whose needs are not met cannot be taken.  Cancelling leaves the
## chapter to come back to.
func _fate_choice(sid: String, v: Dictionary, outer: Dictionary = {}) -> void:
	var th := Fate.thread_of_step(sid)
	var opts: Array = []
	for o in v.get("options", []):
		var ok := Fate.option_ok(Game, o)
		var extra := Fate.option_text(Game, o)
		opts.append({"id": str(o.id), "label": str(o.label), "note": "" if ok else "not yet", "desc": str(o.desc) + ("\n\n" + extra if extra != "" else ""),
			"col": Fate.THREADS[th].col, "enabled": ok})
	choose(str(v.get("ask", "What will you do?")), opts, func(pid: String):
		if pid == "":
			return
		var o := Fate.option(v, pid)
		if o.is_empty() or not Fate.option_ok(Game, o):
			return
		Fate.pay(Game, o)
		if o.has("battle"):
			fate_battle(sid, o)
		else:
			_fate_end(sid, o)
	, outer.is_empty())

## A chapter's fight: the option's foes, in the region where it happens.
func fate_battle(sid: String, o: Dictionary) -> void:
	var foes: Array = []
	var boss := false
	for f in o.battle:
		foes.append({"id": str(f[0]), "lv": int(f[1])})
		boss = boss or Data.ENEMIES[str(f[0])].get("boss", false)
	battle.start(foes, {"boss": boss, "fate": sid, "fate_opt": o, "theme": world.theme_name})
	push("battle")

## The fight of a chapter is won: its follow-up choice, if it has one, or the end of the chapter.
func _fate_won(sid: String, o: Dictionary) -> void:
	if o.has("follow"):
		var fv: Dictionary = o.follow
		say(fv.get("lines", []), func(): _fate_choice(sid, fv, o))
	else:
		_fate_end(sid, o)

## The end of a chapter: the thread's new state, what the option brings, the lines that follow; then
## the story goes on (a "fate" step is done, or one of Part XIV's five is settled).
func _fate_end(sid: String, o: Dictionary) -> void:
	var th := Fate.thread_of_step(sid)
	Fate.take(Game, th, o)
	say(o.get("after", []), func():
		var s := Game.cur_step()
		if not s.is_empty() and s.kind == "fate" and str(s.id) == sid:
			Game.advance()
		elif not s.is_empty() and s.kind == "fates":
			var npc: String = str(Fate.PATH[th][Fate.PATH[th].size() - 1][1])
			Game.visited[npc] = true
			Game.toast("A thread settled (%d of %d)" % [Game.visits_done(s), int(s.n)])
			Game.poll_steps()
		world.refresh_hero()
	)

## The small choices of the road (fate.gd PICKS), asked once after their step's own dialogue.
func ask_picks() -> void:
	for pid in Fate.PICKS:
		var pk: Dictionary = Fate.PICKS[pid]
		if Game.picks.has(pid) or not Game.done(str(pk.step)):
			continue
		var opts: Array = []
		for o in pk.options:
			opts.append({"id": str(o.id), "label": str(o.label), "desc": str(o.desc), "col": UI.C_GOLD})
		choose(str(pk.ask), opts, func(oid: String):
			var o2: Dictionary = {}
			for o3 in pk.options:
				if str(o3.id) == oid:
					o2 = o3
			Game.pick(pid, str(o2.get("log", oid)))
			Game.picks[pid] = oid
			if pid == "qilin" and oid == "ride":
				Game.grant_ride("qilin")
			elif pid == "qilin":
				Game.add_renown(12)
			say(pk.after.get(oid, []))
		, false)
		return

## A grudge that stayed is spent (grudges.gd, Part XIV): what was it owed?  Every option says what it
## does, needs and costs; one whose needs are not met cannot be taken, and leaving it to the Wheel
## always can.  There is no way out of the choice: a grudge that has spoken waits for an answer.
func ask_grudge(id: String) -> void:
	var gd: Dictionary = Grudges.GRUDGES[id]
	var opts: Array = []
	for o in gd.options:
		var ok := Fate.option_ok(Game, o)
		var extra := Fate.option_text(Game, o)
		opts.append({"id": str(o.id), "label": str(o.label), "note": "" if ok else "not yet", "desc": str(o.desc) + ("\n\n" + extra if extra != "" else ""),
			"col": gd.col, "enabled": ok})
	choose(str(gd.ask), opts, func(oid: String):
		var o := Grudges.option(id, oid)
		if o.is_empty() or not Fate.option_ok(Game, o):
			# (never leave a spent grudge unanswered: it could not be met again)
			o = Grudges.option(id, "wheel")
		Fate.pay(Game, o)
		Grudges.take(Game, id, o)
		say(o.get("after", []), func(): Game.poll_steps())
	, false)

# ---------------------------------------------------------------- Yue Ling (bonds.gd, the Lotus release)
var yue_chat := 0

## T in the world: a heart-to-heart if she has one waiting, else a word about where they are.
func talk_yue() -> void:
	if not Game.companion:
		Game.toast("Yue Ling is not with you yet.")
		return
	var tid := Bonds.talk_ready(Game)
	if tid != "":
		open_talk(tid)
		return
	yue_chat += 1
	say([["Yue Ling", Bonds.chat(Game, world.area_id if not world.is_floor() else "", yue_chat)]])

## A heart-to-heart: her lines, then Lin Feng's reply (no way out of it once she has said it).
func open_talk(tid: String) -> void:
	var tk := Bonds.talk(tid)
	if tk.is_empty():
		return
	say(tk.lines, func():
		var opts: Array = []
		for o in tk.options:
			var fut: Dictionary = Bonds.FUTURES.get(str(o.get("lean", "")), {})
			opts.append({"id": str(o.id), "label": str(o.label), "desc": "Leans her heart towards %s." % Bonds.toward(str(o.get("lean", ""))), "col": fut.get("col", UI.C_GOLD)})
		choose(str(tk.ask), opts, func(oid: String):
			var o := Bonds.talk_option(tid, oid)
			if o.is_empty():
				o = tk.options[0]
			Bonds.take_talk(Game, tid, o)
			say(o.get("after", []))
		, false)
	)

## Tell the player when she has something to talk about (once for each heart-to-heart).
var talk_told := ""

var talk_seen := Vector2i(-1, -1)

func _talk_hint() -> void:
	# (asked again only when the story moves on or a heart-to-heart is had)
	var key := Vector2i(Game.step, Game.talks.size() + (1000 if Game.companion else 0))
	if key == talk_seen:
		return
	talk_seen = key
	var tid := Bonds.talk_ready(Game)
	if tid != "" and tid != talk_told:
		talk_told = tid
		Game.toast("Yue Ling wants to talk (T)")

## One of the memories the Founder pressed (Part XV): what Yue Ling remembers of the place, the things
## eating it driven off, then the memory itself while the two of them do what she did there with the
## bearer, and what Lin Feng says to her afterwards.
func memory_scene(e: Dictionary) -> void:
	var mid := str(e.memory)
	var m := Bonds.memory(mid)
	say(m.get("lines", []), func():
		var foes: Array = []
		for f in m.get("battle", []):
			foes.append({"id": str(f[0]), "lv": int(f[1])})
		if foes.is_empty():
			_memory_won(mid)
			return
		battle.start(foes, {"boss": false, "memory": mid, "theme": world.theme_name})
		push("battle")
	)

func _memory_won(mid: String) -> void:
	var m := Bonds.memory(mid)
	var e = world.find_ent("mem:" + mid)
	if e != null:
		world.start_scene_use(e)
	say(m.get("scene", []), func():
		var opts: Array = []
		for o in m.options:
			var fut: Dictionary = Bonds.FUTURES.get(str(o.get("lean", "")), {})
			opts.append({"id": str(o.id), "label": str(o.label), "desc": "Leans her heart towards %s." % Bonds.toward(str(o.get("lean", ""))), "col": fut.get("col", UI.C_GOLD)})
		choose(str(m.ask), opts, func(oid: String):
			var o := Bonds.memory_option(mid, oid)
			if o.is_empty():
				o = m.options[0]
			Bonds.take_memory(Game, mid, o)
			say(o.get("after", []), func():
				world.end_use()
				Game.poll_steps()
			)
		, false)
	)

## Kind "share" (Part XV): the lotus pond where she woke.  The first time her heart leans one way;
## the last time she writes the first line of her own life (Bonds.FUTURES).
func share_scene(e: Dictionary, sid: String) -> void:
	var sh: Dictionary = Bonds.SHARES.get(sid, {})
	world.start_scene_use(e)
	say(sh.get("lines", []), func():
		var opts: Array = []
		if sh.get("future", false):
			var lean := Bonds.leaning(Game)
			for fk in Bonds.FUTURE_ORDER:
				var fut: Dictionary = Bonds.FUTURES[fk]
				opts.append({"id": fk, "label": str(fut.n), "note": "her heart" if fk == lean else "", "desc": "She would choose %s." % str(fut.what), "col": fut.col})
		else:
			for o in sh.options:
				var fut2: Dictionary = Bonds.FUTURES.get(str(o.get("lean", "")), {})
				opts.append({"id": str(o.id), "label": str(o.label), "desc": str(o.get("desc", "")), "col": fut2.get("col", UI.C_GOLD)})
		choose(str(sh.ask), opts, func(oid: String):
			var after: Array = []
			if sh.get("future", false):
				var key := oid if Bonds.FUTURES.has(oid) else Bonds.FUTURE_ORDER[0]
				var was := Bonds.leaning(Game)
				Bonds.choose_future(Game, key)
				after = Bonds.FUTURE_AFTER[key].duplicate()
				after.append_array(Bonds.HEART_YES if key == was or was == "" else Bonds.HEART_NO)
			else:
				var o: Dictionary = {}
				for o2 in sh.options:
					if str(o2.id) == oid:
						o = o2
				if o.is_empty():
					o = sh.options[0]
				Bonds.lean(Game, str(o.get("lean", "")), 3)
				# (the closeness is credited to where it happened: every share used to say "by the lotus
				# pond", the loom in the hermitage and the naming feast's stage too)
				Bonds.add(Game, 3, Bonds.share_place(sid))
				Game.note("With Yue Ling (%s): %s" % [str(Data.STEPS[Data.step_index(sid)].t).split(":")[0], str(o.label)])
				after = o.get("after", [])
			say(after, func():
				world.end_use()
				var s := Game.cur_step()
				if not s.is_empty() and str(s.id) == sid:
					Game.advance()
			)
		, false)
	)

# ---------------------------------------------------------------- the wardrobe, the stable, the dyer (fashion.gd)
## The wardrobe: every outfit, the ones not yet earned greyed out with how to earn them; the hero in
## the world changes as the cursor moves.
func open_wardrobe() -> void:
	var opts: Array = []
	for id in Fashion.OUTFIT_ORDER:
		var o: Dictionary = Fashion.OUTFITS[id]
		var have: bool = Game.outfits.has(id)
		var col := Color(str(o.cols[0])) if str(o.cols[0]) != "" else UI.C_GOLD
		opts.append({"id": id, "label": str(o.n) if have else "? " + str(o.n), "note": "wearing" if id == Game.outfit else ("" if have else "not yet"),
			"desc": str(o.desc) + "\n\nWhile worn: " + Fashion.fx_text(o.fx) + ".\n" + str(o.how), "col": col, "enabled": have, "current": id == Game.outfit})
	choice.preview = func(id: String): world.preview_outfit(id)
	choose("The wardrobe: what will you wear?", opts, func(id: String):
		world.preview_outfit("")
		if id != "" and Game.wear(id):
			Game.toast("You wear the %s" % Fashion.OUTFITS[id].n)
		world.refresh_hero()
	)

## The stable: the rides owned (and the ones still to be earned); choosing one saddles it and mounts.
func open_stable() -> void:
	var opts: Array = []
	for id in Fashion.RIDE_ORDER:
		var r: Dictionary = Fashion.RIDES[id]
		var have: bool = Game.rides.has(id)
		opts.append({"id": id, "label": str(r.n) if have else "? " + str(r.n), "note": ("riding" if Game.riding else "saddled") if id == Game.ride else ("" if have else "not yet"),
			"desc": str(r.desc) + "\n\n%s, %d%% faster than running. %s" % ["Ridden" if str(r.kind) == "mount" else "Stood on", int(round((float(r.speed) - 1.0) * 100.0)), str(r.how)],
			"col": UI.C_JADE, "enabled": have, "current": id == Game.ride})
	opts.append({"id": "off", "label": "Go on foot", "desc": "Send the ride away and walk (R mounts again).", "col": UI.C_DIM, "enabled": Game.riding})
	choose("The stable: what will you ride?", opts, func(id: String):
		if id == "off":
			Game.riding = false
		elif id != "":
			Game.ride = id
			Game.riding = true
			Game.toast("You ride the %s" % Fashion.RIDES[id].n)
	)

## What Dyer Su has for sale now (fashion.gd outfits with a price).
func _dyer_stock() -> Array:
	var out: Array = []
	for id in Fashion.OUTFIT_ORDER:
		if Fashion.outfit_for_sale(id, Game):
			out.append(id)
	return out

func offer_outfits(e: Dictionary) -> void:
	var opts: Array = []
	for id in _dyer_stock():
		var o: Dictionary = Fashion.OUTFITS[id]
		opts.append({"id": id, "label": "%s (%d stones)" % [o.n, int(o.buy)], "desc": str(o.desc) + "\n\nWhile worn: " + Fashion.fx_text(o.fx) + ".",
			"col": Color(str(o.cols[0])), "enabled": Game.stones >= int(o.buy)})
	opts.append({"id": "later", "label": "Not today", "desc": "Dyer Su will keep it for you. She says that to everyone.", "col": UI.C_DIM})
	choose("Dyer Su's stall: something to wear?", opts, func(id: String):
		if id == "" or id == "later":
			return
		var o: Dictionary = Fashion.OUTFITS[id]
		if Game.stones < int(o.buy):
			return
		Game.stones -= int(o.buy)
		Game.grant_outfit(id)
		say([[str(e.n), "It suits you. I would say that anyway, but this time it is true."]])
	)

## A townsperson's request (trials.gd DEEDS): give them what they asked for, or come back later.
func offer_deed(e: Dictionary, id: String) -> void:
	var d: Dictionary = Trials.DEEDS[id]
	var ready := Trials.deed_ready(id, Game)
	var reward := "Renown +%d, %d spirit stones." % [int(d.renown), int(d.get("stones", 0))]
	choose("A request from %s" % e.n, [
		{"id": "help", "label": "Help", "note": "ready" if ready else "not yet", "desc": str(d.ask) + "\n\nThey want: " + Trials.want_text(id, Game) + "\n\n" + reward, "col": Trials.KINDS.respect.col, "enabled": ready},
		{"id": "later", "label": "Not now", "desc": "Come back when you have it.", "col": UI.C_DIM},
	], func(pick: String):
		if pick == "help" and Game.do_deed(id):
			say([[str(e.n), str(d.thanks)]])
	)

## Offer one of the peoples of the realms the keepsake they love (Part XI).
func offer_gift(e: Dictionary) -> void:
	var race: String = str(e.race)
	var item: String = str(Data.RACES[race].gift)
	var have: int = Game.inv.get(item, 0)
	choose("A gift for %s?" % e.n, [
		{"id": "give", "label": "Give the %s" % Data.ITEMS[item].n, "note": "you have %d" % have, "desc": str(Data.ITEMS[item].desc) + "\n\n%s call you %s." % [Game.the_race(race), Game.race_title(race)], "col": Look.PICKUP_COLORS.get(item, UI.C_GOLD)},
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
	Game.record_kills(str(e.get("area", Game.area)), e.group.size(), e.group.map(func(g): return g.id))

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
	if Trials.is_gate(e.enemy):
		# one of the Eight Gates (Part XIII): any of them, in any order, once the lock has been explained
		if not Game.reached(Trials.GATE_STEP):
			say([["Narrator", "%s stands in a column of gold light that will not let you near. Not yet." % d.n]])
			return
	elif Grudges.is_grudge(e.enemy):
		# a grudge that stayed (grudges.gd, Part XIV): any of them, in any order, once the Mirror has shown them
		if s.is_empty() or s.kind != "grudges" or Game.grudges.has(e.enemy):
			say([["Narrator", "%s stands where its owner fell, muttering a sum nobody ever paid. It does not see you yet." % d.n]])
			return
	elif s.is_empty() or s.kind != "kill" or s.boss != e.enemy:
		say([["Narrator", "%s looms before you, but this is not the time. Finish your current objective first." % d.n]])
		return
	if Game.level < e.req:
		say([["Narrator", "%s radiates a suffocating aura. You need at least %s cultivation." % [d.n, Data.level_name(e.req)]]])
		return
	if Trials.TRIALS.has(e.enemy):
		# a trial (trials.gd): nobody faces this one unprepared, and there is more than one way to prepare
		var why: Array = boss_story(e.enemy)
		why.append(["Narrator", str(Trials.TRIALS[e.enemy].why)])
		if e.enemy == "nie" and Grudges.nie_line(Game) != "":
			# the grudges that stayed (grudges.gd): the ones left to the Wheel are in Nie's hands
			why.append(["Narrator", Grudges.nie_line(Game)])
		say(why, func(): open_trial(e))
		return
	var pre: Array = boss_story(e.enemy)
	pre.append_array(Data.DIALOGUE.get("pre:" + e.enemy, []))
	say(pre, func():
		var foe := {"id": e.enemy, "lv": e.lv}
		if Grudges.is_grudge(e.enemy):
			# a grudge does not listen until it has spent itself: it fights as hard as a trial's boss
			foe["mult"] = float(Grudges.MIGHT[0])
			foe["atk"] = float(Grudges.MIGHT[1])
		battle.start([foe], {"entity": e, "boss": true, "enemy": e.enemy, "theme": world.theme_name})
		push("battle")
	)

## Who a boss was before it stood in the road (lore.gd), told by the narrator the first time Lin Feng
## comes to face it (and kept in the Bestiary); nothing the second time.
func boss_story(id: String) -> Array:
	if Game.told.has(id) or not Lore.BOSS.has(id):
		return []
	Game.told[id] = true
	var out: Array = []
	for ln in Lore.BOSS[id]:
		out.append(["Narrator", str(ln)])
	return out

## The ways through a trial, on the choice screen: each with what it needs (ticked or not) and what it
## does in battle; only a path whose needs are met can be taken.  Taking it pays what it costs (once),
## and the battle starts with its boon.
func open_trial(e: Dictionary) -> void:
	var tid: String = e.enemy
	var d: Dictionary = Data.ENEMIES[tid]
	var opts: Array = []
	for p in Trials.TRIALS[tid].paths:
		var ok := Trials.path_met(tid, p, Game)
		var kind: Dictionary = Trials.KINDS[p.kind]
		opts.append({"id": p.id, "label": p.n, "note": "ready" if ok else "", "desc": "%s: %s.\n\n" % [kind.n, kind.what] + Trials.path_desc(tid, p, Game), "col": kind.col, "enabled": ok})
	choose("%s: how will you face it?" % d.n, opts, func(pid: String):
		if pid == "":
			return
		var p := Game.take_path(tid, pid)
		if p.is_empty():
			return
		var lines: Array = [["Narrator", str(p.line)]]
		lines.append_array(Data.DIALOGUE.get("pre:" + tid, []))
		say(lines, func(): trial_battle(e, p))
	)

func trial_battle(e: Dictionary, p: Dictionary) -> void:
	var tid: String = e.enemy
	var mt: Array = Trials.TRIALS[tid].get("might", Trials.MIGHT)
	var bn: Dictionary = p.get("boon", {}).duplicate()
	if tid == "chiyou":
		# every gate opened beyond the four that break the lock takes a little off the war god
		var extra := maxi(0, Game.gates_open.size() - Trials.GATES_NEEDED)
		bn["foe_hp"] = float(bn.get("foe_hp", 1.0)) * (1.0 - Trials.GATE_WEAKEN * extra)
	elif tid == "nie":
		# every grudge left to the Wheel feeds Nie, every one laid to rest takes something off it (grudges.gd)
		bn["foe_hp"] = float(bn.get("foe_hp", 1.0)) * Grudges.nie_mult(Game)
	battle.start([{"id": tid, "lv": e.lv, "mult": mt[0], "atk": mt[1]}], {"entity": e, "boss": true, "enemy": tid, "theme": world.theme_name,
		"trial": tid, "path": str(p.id), "boon": bn, "path_n": str(p.n), "path_kind": str(Trials.KINDS[p.kind].n)})
	push("battle")

func start_breakthrough() -> void:
	var s := Game.cur_step()
	if s.is_empty() or s.kind != "breakthrough" or not Game.can_breakthrough():
		return
	var sid: String = s.id
	# the first tribulation tells what a tribulation is (lore.gd)
	var pre: Array = boss_story("tribulation")
	pre.append_array(Data.DIALOGUE.get("pre:" + sid, []))
	say(pre, func():
		# heaven's jealousy (Part XII): the more of the Nine Heavens root is awake, the harder the test
		battle.start([{"id": "tribulation", "lv": Game.level + 1, "mult": 1.1 * (1.0 + Data.TRIB_JEALOUSY * Game.talent_ranks())}], {"boss": true, "tribulation": true, "step": sid, "theme": "thunder"})
		push("battle")
	)

## The breakthroughs that close a chapter and the dialogue that brings Lin Feng home after them.
const RECALLS := {"s_break6": "recall", "s_break8": "recall2", "s_break9": "recall3", "s_break10": "recall4", "s_break11": "recall5",
	"s_break12": "recall6", "s_break13": "recall7", "s_break14": "recall8", "s_break15": "recall9", "s_break16": "recall10", "s_break17": "recall11",
	"s_break18": "recall12", "s_break19": "recall13", "s_break20": "recall14"}

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
			if str(ctx.get("fate", "")) != "":
				# the fight of a fated encounter (fate.gd): the chapter goes on
				_fate_won(str(ctx.fate), ctx.fate_opt)
			elif str(ctx.get("memory", "")) != "":
				# the things eating one of Yue Ling's memories are driven off (bonds.gd): it comes back
				_memory_won(str(ctx.memory))
			elif ctx.get("tribulation", false):
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
				world.battle_mark(e, true)
				Game.boss_done[ctx.enemy] = true
				# every boss is talked of; a trial passed is remembered with the path that passed it
				Game.add_renown(Trials.RENOWN_BOSS)
				if str(ctx.get("trial", "")) != "":
					Game.trial_won(str(ctx.trial), str(ctx.path))
				if Data.BOSS_DROPS.has(ctx.enemy):
					var drop: String = Data.BOSS_DROPS[ctx.enemy]
					Game.add_item(drop)
					Game.toast("Obtained %s" % Data.ITEMS[drop].n)
				Game.note("Defeated " + Data.ENEMIES[ctx.enemy].n)
				if Trials.is_gate(ctx.enemy):
					# one of the Eight Gates stands open (Part XIII): the lock breaks at the fourth
					Game.gates_open[ctx.enemy] = true
					var gn: String = str(Trials.GATE_NAMES[ctx.enemy])
					Game.toast("%s stands open (%d of 8)" % [gn.substr(0, 1).to_upper() + gn.substr(1), Game.gates_open.size()])
					Game.note("Opened " + str(Trials.GATE_NAMES[ctx.enemy]))
					Game.poll_steps()
				elif not Grudges.is_grudge(ctx.enemy):
					Game.advance()
				var post: Array = dao_dialogue("post:" + ctx.enemy)
				if Grudges.is_grudge(ctx.enemy):
					# a grudge that stayed is spent: it says what it was owed, and waits for an answer
					var gid: String = ctx.enemy
					say(post, func(): ask_grudge(gid))
				# (a small choice of the road may wait on this boss: fate.gd PICKS)
				elif not post.is_empty():
					say(post, func(): ask_picks())
				else:
					ask_picks()
			else:
				var e2: Dictionary = ctx.entity
				# the Living Land release: the fight leaves its mark on the ground (havoc.gd)
				world.battle_mark(e2, false)
				Game.defeated[e2.id] = Game.playtime
				Game.record_kills(e2.get("area", Game.area), e2.group.size(), e2.group.map(func(g): return g.id))
		"lose":
			Game.respawn()
			world.load_area("sect", Vector2i(20, 8))
			say([["Narrator", "You wake in the sect infirmary. Elder Qing Xuan watches over you. Some spirit stones were lost to the healers."]])
		_:
			pass
