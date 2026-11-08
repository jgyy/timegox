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
var bot = null
var bot_active := false
var args := {}
var toast_list: Array = []
var chat_idx := {}
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
			start_encounter(e)
		"boss":
			boss_interact(e)
		"seal":
			var need: Dictionary = Data.STEPS[Data.step_index(e.open)]
			Game.toast("A Lotus Seal bars the road to %s. (%s)" % [Data.AREAS[e.to].n, need.t])
		"pickup":
			Game.add_item(e.item)
			Game.taken[e.id] = true
			Game.toast("Obtained %s" % Data.ITEMS[e.item].n)
			Game.poll_steps()

func talk_npc(e: Dictionary) -> void:
	var s := Game.cur_step()
	if not s.is_empty() and s.kind == "talk" and s.npc == e.id and s.area == e.get("area", Game.area):
		var sid: String = s.id
		say(Data.DIALOGUE[sid], func():
			Game.advance()
			if sid == "s_yue":
				Game.companion = true
				Game.hp[1] = float(Game.max_hp(1))
				Game.qi[1] = float(Game.max_qi(1))
				Game.toast("Yue Ling joins your party!")
				Game.note("Yue Ling joined")
			if sid == "s_swordghost":
				pass
		)
		return
	var chats: Array = Data.CHAT.get(e.id, ["..."])
	var i: int = chat_idx.get(e.id, 0)
	chat_idx[e.id] = i + 1
	var lines := [[e.n, chats[i % chats.size()]]]
	if e.id == "elder":
		lines.append([e.n, "Your task: " + Game.objective_text()])
	var after := Callable()
	if e.id == "alchemist":
		after = func(): shop.open("alchemist"); push("shop")
	elif e.id == "smith":
		after = func(): shop.open("smith"); push("shop")
	say(lines, after)

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
		battle.start([{"id": "tribulation", "lv": Game.level + 1, "mult": 1.1}], {"boss": true, "tribulation": true, "step": sid, "theme": "thunder"})
		push("battle")
	)

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
				say(Data.DIALOGUE.get("post:" + sid, []), func():
					if Game.finished:
						Game.note("Ending reached")
						push("ending")
					elif sid == "s_break6":
						recall_to_sect()
					elif sid == "s_break8":
						recall_to_sect("recall2")
					elif sid == "s_break9":
						recall_to_sect("recall3")
					elif sid == "s_break10":
						recall_to_sect("recall4")
					elif sid == "s_break11":
						recall_to_sect("recall5")
					elif sid == "s_break12":
						recall_to_sect("recall6")
					elif sid == "s_break13":
						recall_to_sect("recall7")
					elif sid == "s_break14":
						recall_to_sect("recall8")
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
				var post: Array = Data.DIALOGUE.get("post:" + ctx.enemy, [])
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
