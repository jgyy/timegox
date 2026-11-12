extends Node
## End-to-end playthrough bot.
##
## The bot plays through the same input surface as a human: it presses
## up/down/confirm/cancel on whichever screen is on top and holds a movement
## direction in the world.  Every key press has a human-like delay, and dialogue is
## "read" for a time proportional to its length, so the elapsed *game clock* is a fair
## estimate of how long a person would need.  Run it with Godot's --fixed-fps so a
## full hour of game time is simulated in minutes of wall clock:
##
##   godot --headless --fixed-fps 30 --path . -- --bot --report=build/bot_report.json

var main
var world
var cool := 0.5
var wall_start := Time.get_ticks_msec()
var finished := false
var report_path := "build/bot_report.json"
var shots_dir := ""
var min_time := 3600.0
var max_time := 33.0 * 3600.0
var shots_taken := {}
var logged := 0

# navigation
var path: Array = []
var path_key := ""
var last_tile := Vector2i(-1, -1)
var stuck_t := 0.0
var grind_target := ""

# state
var read_done := false
var med_goal := "rest"
var menu_goal := ""
var result_wait := false
var shop_done := {}
var last_area := ""
var last_top := ""
var last_step := -1
var last_progress := 0.0
var dwell := 0.0
var time_by_screen := {}
var time_by_area := {}
## meditation time by what it was for: resting, grinding to a stage, waiting for packs to come back
var time_by_med := {}
var gave_up := ""

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const HEALS := ["mazu_lantern", "jianmu_ward", "river_mother", "moon_dew", "magpie_wing", "homeward", "rebirth", "mending", "seal_bloom", "dawn", "starlight", "rain", "lotus_heart"]
## Part XI: the Dao the bot walks from each quest step on (it chooses the first from the Elder, and
## changes roads at a Dao Stele when it reaches the later steps, as a player trying the Daos would)
const DAO_PLAN := [["s_p11_home", "sword"], ["s_ns_intro", "heart"]]
## Part XII: the order in which the bot wakes the branches of the root, as a sword-and-thunder fighter
## would: the Sword Bone and the Thunder Root first, then a body that can take a blow and a dantian
## that does not run dry, then everything else; the Enlightened Mind last (a player in a hurry would
## take it early and meditate far less)
const TALENT_PLAN := ["sword_bone", "thunder_root", "vajra", "sword_bone", "thunder_root", "qi_sea", "five_phase", "sword_bone",
	"thunder_root", "vajra", "fortune", "five_phase", "yin_root", "qi_sea", "spirit_sense", "vajra", "five_phase", "qi_sea",
	"fortune", "yin_root", "spirit_sense", "fortune", "yin_root", "spirit_sense", "insight", "insight", "insight"]
var last_layer := ""
## Many roads (trials.gd): the path the bot takes through each trial, chosen so that one run walks
## every kind of road (a player would take whatever suited them); where a planned path cannot be
## taken, the cheapest one that can.  The Eight Gates it opens in Part XIII, in order (any four do),
## and the road it takes into the heart of them (--route=sword|peoples|cauldron).
const TRIAL_PLAN := {"iron_fang": "craft", "thunder_roc": "craft", "demon_lord": "respect", "inferno_lord": "might", "heavenly_emperor": "wealth",
	"founder_qing": "respect", "hollow_heaven": "craft", "registrar_siming": "craft", "jade_ledger": "might", "vermilion_bird": "wealth",
	"hundun": "respect", "horse_face": "craft", "king_yama": "bond", "thread_matron": "respect", "qianxian": "bond",
	"crow_marshal": "craft", "xiwangmu": "respect", "bifang": "bond", "xihe": "craft", "gun": "craft", "gonggong": "might",
	"chong": "dao", "li": "dao", "tianwu": "wealth", "xu_fu": "dao",
	"fetter_maple": "relic", "kui_drum": "might", "liang": "dao", "xingtian": "wealth",
	# Part XIV: the friends it kept faith with come to the Wheel
	"nie": "bond",
	# Part XV: side by side with Yue Ling against the Unweaver; a key of pressed petals for the Warden
	"unweaver": "heart", "lock_warden": "craft",
	# Part XVI: the door gods' peach wood for the Last Night, and every pot in the land for the Year Beast
	"xi_beast": "relic", "nian": "folk",
	# Part XVII: the land it opened with its sword for the Maiden of Frost, the old way of asking for Taisui
	"qing_nu": "land", "taisui": "folk",
	# Part XVIII: a drill of summer wood from the smith for the Lord of Fire, and six lines of buckets (the
	# hearths that call it a guest) for the fire nobody sat up with
	"zhurong": "craft", "huilu": "hearth",
	# Part XIX: Mozi's belt and nine sticks from the smith for the Cloud Ladder, Yue Ling to speak to the
	# Player as one who was made to another, and a maker's own word (four works of one school) for the
	# Machine Heart
	"cloud_ladder": "craft", "the_player": "heart", "jixin": "works",
	# and the stopped escapement the Machine Heart left, held up to the Wooden Magpie
	"wooden_magpie": "relic",
	# Part XX: a clay bell from the alchemist for the Lamb of the Earth; the caves it has gone to the back
	# of (three by then) for the White-Haired Rat, who hears out a guest who knows the way in; Yue Ling's
	# one voice that is not an echo for the Penumbra; and the shadow's shadow it left, held up to the
	# Valley Spirit
	"fen_yang": "craft", "white_rat": "delve", "wangliang": "heart", "xuanpin": "relic",
	# Part XXI: two Daos of arms for the White Ape, who has only ever seen one stroke; Yue Ling to walk the
	# Paired Dragons in to one another; a cock of wood from the smith for the king who loved swords; and
	# the scroll the king left, read aloud to the Masterless Edge
	"yuan_gong": "arms", "sword_dragons": "heart", "king_zhao": "craft", "wuzhu": "relic",
	# Part XXII: up on its hands to the shanxiao, the Earl's own knot handed back to him, four tops told
	# to the Mountain Spirit, and nine summits with nothing to report to the Lord of the Eastern Peak
	"shanxiao": "heights", "fei_lian": "relic", "shan_gui": "heights", "dongyue": "heights",
	# Part XXIII: seven companies that were asked for to the general who only ever obeyed, a planting song to the lute
	# with lead in it, eight hundred who will all go home to the king who could not face their fathers, and a potter's
	# hands to the first pot
	"meng_tian": "host", "gao_jianli": "song", "xiang_yu": "host", "wafu": "works",
	# Part XXIV: the old mare's four cast shoes to the horse that followed her, and three losses in the red
	# column to the keeper of the book
	"hu_steed": "relic", "huofu": "loss",
}
## Fates and Faces (fate.gd): what the bot chooses at every meeting of the five fated encounters, in
## order of preference (the first that can be taken), so that one run walks friends and foes alike:
## Tala, Qiu Ye and Fang Hu become friends, Xu Lan an enemy spared at the end, Liu Ying an enemy who
## falls.  "<step>:follow" is the choice after a chapter's battle.
const FATE_PLAN := {
	"s_f_hu1": ["village"], "s_f_liu1": ["keep"], "s_f_qiu1": ["share", "secret"], "s_f_tala1": ["drive"], "s_f_xu1": ["surrender"],
	"s_f_xu2": ["stop", "trust", "first"], "s_f_qiu2": ["duel", "break", "hand"], "s_f_tala2": ["lead", "hunt"], "s_f_liu2": ["stop", "essence", "teach"],
	"s_f_qiu3": ["walk", "farewell"], "s_f_hu2": ["fight", "teach"], "s_f_tala3": ["dig", "buy", "sell"], "s_f_hu3": ["truth", "offer", "fight"],
	"s_f_xu3": ["stop", "forgive"], "s_f_liu3": ["stop", "forbid"],
	"s_f_tala4": ["ride", "buyback", "absolve"], "s_f_qiu4": ["together", "vouch", "ask", "face"], "s_f_hu4": ["together", "face"],
	"s_f_xu4": ["face", "together"], "s_f_xu4:follow": ["spare"], "s_f_liu4": ["face", "together"], "s_f_liu4:follow": ["end"],
	"s_f_qiu4:follow": ["spare"], "s_f_hu4:follow": ["spare", "why"],
}
## the small choices of the road (fate.gd PICKS)
const PICK_PLAN := {"qilin": "ride"}
## The crossroads of the road (echoes.gd): what the bot answers at each, in order of preference (the
## first that can be taken), chosen so that one run leans every scale far enough to be known for it:
## mercy (the bandits mend the road, the egg is carried down, the crows build, the Player keeps its
## heart; but the Ancestor's name is struck and the widow told the truth), the new works (the garden
## studied, the drawings kept, the axe given, the wheel given hours) and the wide world (the palace
## opened, the sea-roads, the names to the wind, the map copied); and for the last question the
## wheel's answer, as a builder of engines, if it has built three of them.
const CROSS_PLAN := {"bandits": ["mend"], "garden": ["study"], "roc_egg": ["hatch"], "palace": ["open"], "dragon_boon": ["sea"], "drawings": ["keep"], "nineteen": ["wind"],
	"ancestor": ["strike"], "widow": ["truth"], "crows": ["pardon"], "axe": ["give"], "cauldron_map": ["copy"], "furnace": ["return"],
	"the_wheel": ["hours"], "the_player": ["keep"], "the_works": ["wheel", "hand", "dao", "ask"],
	# Part XX: a road through Yu Gong's mountains, the echoes let go home, and the Hollow left open
	"the_mountain": ["road"], "the_echoes": ["home"], "the_hollow": ["open"],
	# Part XXI: the Maiden teaches those who have swept a year, the three thousand go home by way of
	# their dead, and a school is founded where the broom is learned first
	"the_pupils": ["sweep"], "the_three_thousand": ["home"], "the_arms": ["school", "rack"],
	# Part XXII: a place at the fires for the shanxiao, the air asked for, and a stone on the cairn
	"the_voices": ["fire"], "the_kites": ["ask"], "the_tops": ["cairn"],
	# Part XXIII: the clay soldiers carried home by the names in their collars, the lead melted out of the lute, and
	# the song kept when the spears go home
	"the_clay": ["home"], "the_lute": ["melt"], "the_host": ["band"],
	# Part XXIV: a sea-wall of ten thousand baskets, nine channels for the Huai and the ape let go to the sea,
	# and the black horse kept by the tent
	"the_tide": ["wall"], "the_ape": ["dredge"], "the_horse": ["keep"]}
## The Hundred Works (works.gd): the order in which the bot builds, as a builder of engines who keeps
## a fire-drill in his pack and an array to sit in: the wheel's school first, the cheap first works
## of the other two beside it.  It builds a work once it can and has four times its price in hand
## (so the trials' cauldron and forge are never kept waiting), or at once when the story asks for works.
const WORKS_PLAN := ["well_sweep", "fire_kit", "array", "trip_hammer", "cords", "water_bellows", "talismans", "crossbow", "sling", "chariot", "furnace", "wooden_ox",
	"kiln", "paper_servants", "adze", "mirror", "hide_coat", "flags"]
## Part XIV, the grudges that stayed (grudges.gd): the order the bot goes to them in (a round trip from
## the Wheel: the old roads near the sect, up the Jianmu, out to sea), and what it answers each, in order
## of preference: a friend answers where one can, else it pays, and it leaves the Admiral to the Wheel
## so that one run sees a grudge feed Nie.
const GRUDGE_ROUTE := ["grudge_headless_saint", "grudge_iron_fang", "grudge_marsh_hag", "grudge_fangfeng", "grudge_kui", "grudge_admiral"]
const GRUDGE_PLAN := {"grudge_iron_fang": ["son", "test"], "grudge_marsh_hag": ["name", "pay"], "grudge_headless_saint": ["bow", "tablet"],
	"grudge_fangfeng": ["ask", "shrine"], "grudge_kui": ["home", "unstring"], "grudge_admiral": ["wheel"]}
const GATE_PLAN := ["fetter_maple", "kui_drum", "liang", "xingtian"]
## The Lotus release (bonds.gd): the bot has every heart-to-heart Yue Ling wants as soon as she wants
## it (T), and answers by TALK_PLAN (mostly towards walking beside him, now and then towards the
## mountain or a road of her own, so one run leans all three ways); the memories it gives back in Part
## XV, in this order (any six of seven do: the bamboo and the snow of Part I, the Yellow Springs on the
## funeral road, the ferry's stars, the Magpie Bridge and the tea hills on the way to the silk woods), what it says at each,
## and at the lotus pond; and the future she writes for herself (the one her heart leans to).
const TALK_PLAN := {"t_lotus": "mine", "t_hands": "teach", "t_winter": "here", "t_chains": "cut", "t_sky": "share", "t_seal": "you",
	"t_ageless": "keep", "t_mend": "me", "t_ancestors": "make", "t_mother": "sing", "t_bridge": "yes", "t_noon": "duty", "t_maps": "draw",
	"t_choice": "proof", "t_sea": "sail", "t_war": "hold", "t_threads": "tie", "t_dragon": "ask", "t_nineteen": "left", "t_peach": "see", "t_heaven": "home", "t_xufu": "front", "t_page": "long", "t_qinglian": "mother", "t_twenty": "share", "t_loom": "through", "t_moths": "keep", "t_wrist": "family", "t_after": "never", "t_feast": "every",
	"t_newyear": "bowl", "t_hunger": "share", "t_lastnight": "stay", "t_newday": "red",
	"t_spring": "first", "t_thunder": "glad", "t_soil": "mend", "t_qingming": "first",
}
const MEMORY_ROUTE := ["mem_flute", "mem_spring", "mem_lanterns", "mem_stars", "mem_dance", "mem_kite"]
const MEMORY_PLAN := {"mem_lanterns": "two", "mem_flute": "forest", "mem_spring": "nothing", "mem_stars": "beside", "mem_kite": "cut", "mem_dance": "again", "mem_mill": "cook"}
const SHARE_PLAN := {"s_p15_pond": "remember", "s_p15_loom": "both", "s_p15_feast": "her", "s_p16_sweep": "fear", "s_p16_eve": "with", "s_p16_vigil": "mine", "s_p16_dawn": "us", "s_p16_lanterns": "her", "s_p16_couplets": "together",
	"s_p17_haircut": "trust", "s_p17_thunder": "us", "s_p17_teacup": "home", "s_p17_graves": "her", "s_p17_kite": "road",
	"s_p18_drill": "both", "s_p18_feast": "seventh",
	"s_p19_campfire": "both", "s_p19_rest": "us",
	"s_p20_tea": "room", "s_p20_fire": "live",
	"s_p21_stage": "none", "s_p21_sweep": "broom",}
## the end of the story the bot chooses (cultures.gd ENDINGS), rarest first, of those its journey earned
const ENDING_PLAN := ["school", "open", "road", "lotus", "home", "azure"]
var route := "peoples"
var give_way := false
## the trial ahead (cached for the frame: it is asked for many times a frame)
var tt_cache := {}
var tt_frame := -1

func _ready() -> void:
	world = main.world
	if main.args.has("report"):
		report_path = main.args.report
	if main.args.has("shots") and DisplayServer.get_name() != "headless":
		shots_dir = main.args.shots
		DirAccess.make_dir_recursive_absolute(shots_dir)
	if main.args.has("min-time"):
		min_time = float(main.args["min-time"])
	if main.args.has("max-time"):
		max_time = float(main.args["max-time"])
	if main.args.has("route"):
		route = str(main.args.route)
	# (dooms.gd: with --yield the bot gives way to what cannot be beaten instead of fighting it to the end)
	give_way = main.args.has("yield")

## Developer shortcut: --bot-start=<step id> drops a fresh game straight at that quest step with
## the level, companion, techniques and boss kills a player would have by then (the reported play
## time then covers only the rest of the game).  Used to iterate on late chapters quickly.
var start_applied := false

func _apply_start() -> void:
	start_applied = true
	if not main.args.has("bot-start"):
		return
	var idx := Data.step_index(str(main.args["bot-start"]))
	if idx < 0:
		return
	# (the crossroads behind the start are answered as the plan answers them: what a journey that far
	# along has left standing in the land stands, marks.gd)
	for cid in Echoes.ORDER:
		if Data.step_index(str(Echoes.CROSSROADS[cid].step)) < idx and not Game.picks.has(cid):
			for oid in CROSS_PLAN.get(cid, []):
				if Echoes.option_ok(Game, Echoes.option(cid, str(oid))):
					Echoes.take(Game, cid, str(oid))
					break
	var lv := 0
	for i in idx:
		var st: Dictionary = Data.STEPS[i]
		match st.kind:
			"breakthrough":
				lv = st.to
			"level":
				lv = maxi(lv, st.lv)
			"kill":
				Game.boss_done[st.boss] = true
				for a in Data.AREAS:
					for b in Data.AREAS[a].get("bosses", []):
						if b.id == st.boss:
							lv = maxi(lv, b.req)
	Game.level = lv
	Game.exp = 0.0
	Game.companion = true
	Game.step = idx
	# (and he has walked into every region the story has sent him to so far: the camps of the road and
	# the cloud-kite ask where he has been)
	for i3 in idx:
		if Data.STEPS[i3].has("area") and Data.AREAS.has(str(Data.STEPS[i3].area)):
			Game.seen[str(Data.STEPS[i3].area)] = true
	# about what a player would have saved by then (quest rewards and half as much again from battles)
	var saved := 0
	for i2 in idx:
		saved += int(Data.STEPS[i2].get("stones", 0))
	Game.stones = maxi(20000, int(saved * 1.5))
	# (--bot-stones=N: start with that purse, to try a chapter short of money)
	if main.args.has("bot-stones"):
		Game.stones = int(main.args["bot-stones"])
	Game.inv["hp_pill"] = 6
	Game.inv["qi_pill"] = 4
	# (and the essences, renown, standing and Dao mastery a player would have gathered by then)
	for ek in Trials.ESSENCE_ORDER:
		Game.inv[ek] = int(idx / 12)
	Game.renown = int(idx * 1.15)
	if idx > Data.step_index("s_p11_home"):
		Game.dao = "heart"
		Game.dao_xp = {"sword": 40, "heart": 40}
		for rc in ["yumin", "dragon", "tianhu", "jiaoren", "deathless", "shade"] + (["qianzi", "xian"] if idx > Data.step_index("s_p12_home") else []):
			Game.standing[rc] = 60
			Game.met[rc] = true
	# the Founder's caves its realm has opened
	for ab in Data.AREAS.mountain.get("abodes", []):
		if lv >= int(ab.req):
			Game.abodes[ab.id] = true
	for st2 in Data.STEPS.slice(0, idx):
		if st2.kind == "collect":
			Game.inv[st2.item] = maxi(int(Game.inv.get(st2.item, 0)), st2.n)
		if st2.kind == "kill" and Trials.TRIALS.has(st2.boss):
			Game.trials[st2.boss] = str(TRIAL_PLAN.get(st2.boss, "might"))
		# the fated encounters met so far, as the plan would have chosen (what they give included)
		if st2.kind == "fate":
			var fv := Fate.variant(Game, str(st2.id))
			var pick := {}
			for want in FATE_PLAN.get(str(st2.id), []):
				var o := Fate.option(fv, str(want))
				if not o.is_empty() and o.get("need", []).is_empty():
					pick = o
					break
			if pick.is_empty():
				for o2 in fv.get("options", []):
					if o2.get("need", []).is_empty():
						pick = o2
						break
			if pick.has("follow"):
				var fo := {}
				for want2 in FATE_PLAN.get(str(st2.id) + ":follow", []):
					fo = Fate.option(pick.follow, str(want2))
				pick = fo if not fo.is_empty() else pick.follow.options[0]
			if not pick.is_empty():
				Fate.take(Game, Fate.thread_of_step(str(st2.id)), pick)
	# Part XXIII: the levy, the airs, the notices and the fields a player would have behind them by then
	for st4 in Data.STEPS.slice(0, idx):
		if bool(st4.get("levy", false)):
			for ln in st4.npcs:
				Game.host[War.levy_of(str(ln))] = true
		if str(st4.kind) == "airs":
			for an in (st4.npcs as Array).slice(0, int(st4.n)):
				Game.airs[Cultures.of_npc(str(an))] = true
		if str(st4.kind) == "war":
			Game.war_won[str(st4.battle)] = 8
		if str(st4.kind) == "jobs":
			for jid in ["job_tally", "job_mill"]:
				Game.jobs[jid] = "done"
	if idx > Data.step_index("s_p19_home"):
		for wid in ["well_sweep", "fire_kit", "cords", "sling", "trip_hammer", "water_bellows", "crossbow", "chariot"]:
			Game.works[wid] = true
	if idx > Data.step_index("s_p21_home"):
		for aid in Arms.ORDER:
			Game.arms[aid] = true
			Game.arm_xp[aid] = 20
	# the heart-to-hearts Yue Ling would have had by then, answered as the plan answers them (bonds.gd)
	for tk in Bonds.TALKS:
		if Data.step_index(str(tk.after)) < idx:
			var o := Bonds.talk_option(str(tk.id), str(TALK_PLAN.get(str(tk.id), "")))
			Bonds.take_talk(Game, str(tk.id), o if not o.is_empty() else tk.options[0])
	# and what the story gave on the way (the Elder's robe, the flying sword, an immortal's cloud)
	for st3 in Data.STEPS.slice(0, idx):
		for rw in Fashion.step_rewards(str(st3.id)):
			if rw[0] == "outfit":
				Game.outfits[str(rw[1])] = true
			else:
				Game.rides[str(rw[1])] = true
	if not Game.rides.is_empty():
		Game.ride = Fashion.best_ride(Game)
	Game.heal_full()
	Game.note("bot-start: jumped to step %d (%s) at %s" % [idx, Data.STEPS[idx].id, Data.level_name(lv)])

# ---------------------------------------------------------------- main loop
func _process(d: float) -> void:
	if finished:
		return
	var top: String = main.top_name()
	if Game.started and not start_applied:
		_apply_start()
	if Game.started:
		time_by_screen[top] = time_by_screen.get(top, 0.0) + d
		time_by_area[Game.area] = time_by_area.get(Game.area, 0.0) + d
		if top == "meditate":
			time_by_med[med_goal] = time_by_med.get(med_goal, 0.0) + d
		_log_new_events()
		if Game.step != last_step:
			last_step = Game.step
			last_progress = Game.playtime
		if Game.playtime > max_time:
			_finish("timeout: exceeded max game time")
			return
		if Game.playtime - last_progress > 2700.0:
			_finish("stuck: no quest progress for 45 game-minutes at step %d (%s)" % [Game.step, Game.cur_step().get("id", "?")])
			return
	if Game.area != last_area:
		last_area = Game.area
		shop_done = {}
		path = []
		dwell = 0.0
		grind_target = ""
	if world.layer != last_layer:
		# up or down a ladder or the stairs: tiles are a different realm's now
		last_layer = world.layer
		path = []
		path_key = ""
		grind_target = ""
	if top != last_top:
		if last_top == "shop":
			shop_done[main.shop.kind] = true
		last_top = top
		path = []
	if top != "world":
		world.move_dir = Vector2i.ZERO
	cool -= d
	if cool > 0.0:
		return
	if main.args.has("bot-trace") and Game.playtime >= float(main.args["bot-trace"]):
		print("[trace] %.2f top=%s area=%s step=%s tile=%s path=%d goal=%s trial=%s" % [Game.playtime, top, Game.area, Game.cur_step().get("id", "-"), world.ptile, path.size(), path_key, str(_trial_target())])
	_shots(top, d)
	match top:
		"title":
			if shots_dir != "" and not shots_taken.has("01_title"):
				_shot("01_title")
				cool = 0.6
			else:
				_press("confirm", 1.0)
		"create":
			_create()
		"dialogue":
			_dialogue()
		"world":
			_world(d)
		"battle":
			_battle()
		"menu":
			_menu()
		"shop":
			_shop()
		"meditate":
			_meditate()
		"choice":
			_choice()
		"field":
			_field()
		"ending":
			cool = 2.0
			await _shot("ending")
			_finish("")

func _press(a: String, delay: float = 0.28) -> void:
	main.press(a)
	cool = delay

func _log_new_events() -> void:
	while logged < Game.timeline.size():
		var e: Dictionary = Game.timeline[logged]
		print("[bot] %s  %s" % [Fmt.clock(e.t), e.text])
		logged += 1

# ---------------------------------------------------------------- character creation (create.gd)
## The bot makes the sweeper the story first told of (every choice at its first value) and looks at
## each row on the way down, as a player reading the screen would.
## (the New Fire release: --hero=f plays a young woman, --hearth=<id> the hearth of the year away, and so
## where the story begins: steppe, sand, river, forge or dawn; --look=<id> and --origin=<id> the rest)
const CREATE_ARGS := {"body": "hero", "hearth": "hearth", "look": "look", "origin": "origin"}

func _create() -> void:
	var c = main.create
	var row: String = c.ROWS[c.cursor]
	if CREATE_ARGS.has(row) and main.args.has(CREATE_ARGS[row]):
		var want := str(main.args[CREATE_ARGS[row]])
		var have := str(c.h.get(row, ""))
		var known: Array = {"body": Fashion.BODY_ORDER, "hearth": Cultures.ORDER, "look": Fashion.LOOK_ORDER, "origin": Fashion.ORIGIN_ORDER}[row]
		if want in known and have != want:
			_press("right", 0.5)
			return
	if c.cursor < c.ROWS.size() - 1:
		_press("down", 0.6)
	else:
		_press("confirm", 0.8)

# ---------------------------------------------------------------- dialogue
func _dialogue() -> void:
	var dlg = main.dialogue
	if dlg.lines.is_empty():
		_press("confirm", 0.2)
		return
	if not dlg.typed_done():
		cool = 0.15
		return
	if not read_done:
		read_done = true
		cool = maxf(0.7, dlg.line_len() / 40.0)
		return
	read_done = false
	_press("confirm", 0.3)

# ---------------------------------------------------------------- world planning
func _hp_ratio() -> float:
	var r := 2.0
	for i in Game.party_size():
		r = minf(r, Game.hp[i] / float(Game.max_hp(i)))
	return r

func _qi_ratio() -> float:
	var r := 2.0
	for i in Game.party_size():
		r = minf(r, Game.qi[i] / float(Game.max_qi(i)))
	return r

func _cult_target() -> Dictionary:
	var s := Game.cur_step()
	if s.is_empty():
		return {}
	var tg := {}
	match s.kind:
		"level":
			return {"lv": s.lv, "full": false}
		"reckon":
			return {"lv": 86, "full": false}
		"kill", "fall":
			for b in Data.AREAS[s.area].get("bosses", []):
				if b.id == s.boss:
					tg = {"lv": b.req, "full": false}
		"gates":
			var ng := _next_gate()
			for b2 in Data.AREAS.get(Trials.boss_area(ng), {}).get("bosses", []):
				if b2.id == ng:
					tg = {"lv": b2.req, "full": false}
		"grudges":
			var ngr := _next_grudge()
			for b3 in Data.AREAS.get(Trials.boss_area(ngr), {}).get("bosses", []):
				if b3.id == ngr:
					tg = {"lv": b3.req, "full": false}
		"breakthrough":
			return {"lv": s.to - 1, "full": true}
	if tg.is_empty():
		return {}
	# a trial's path may ask for more: a level, or cultivation full at the peak of a realm
	var tt := _trial_target()
	if not tt.is_empty():
		for n in Trials.path(tt.tid, str(tt.pid)).needs:
			if str(n[0]) == "lv" and int(n[1]) > int(tg.lv):
				tg = {"lv": int(n[1]), "full": false}
			elif str(n[0]) == "peak" and int(n[1]) >= int(tg.lv):
				tg = {"lv": int(n[1]), "full": true}
	return tg

func _cult_met() -> bool:
	var tg := _cult_target()
	if tg.is_empty():
		return true
	if Game.level > tg.lv:
		return true
	if Game.level == tg.lv:
		return (not tg.full) or Game.exp >= Game.exp_need() - 0.5
	return false

func _want_shop() -> String:
	if Game.area != "sect":
		return ""
	var price := Works.pill_price(Game, "hp_pill", Game.level)
	if not shop_done.get("smith", false) and Game.temper < Data.TEMPER_COST.size() and Game.stones >= Works.temper_cost(Game) + price * 2:
		return "smith"
	if not shop_done.get("alchemist", false) and Game.stones >= price * 2 and (Game.inv.get("hp_pill", 0) < 8 or Game.inv.get("qi_pill", 0) < 3):
		return "alchemist"
	return ""

func _world(d: float) -> void:
	dwell += d
	if world.traveling():
		# on a ladder or the stairs
		world.move_dir = Vector2i.ZERO
		return
	if not world.using.is_empty():
		# doing something (props.gd): let it be done (a key now would cut it short)
		world.move_dir = Vector2i.ZERO
		return
	if world.gliding():
		# under the cloud-kite (peaks.gd): the flight was aimed before it began
		world.move_dir = Vector2i.ZERO
		return
	# stuck watchdog
	if world.ptile == last_tile and world.move_dir != Vector2i.ZERO:
		stuck_t += d
		if stuck_t > 6.0:
			path = []
			stuck_t = 0.0
			grind_target = ""
	else:
		stuck_t = 0.0
	last_tile = world.ptile
	# 0) the beginning (cultures.gd): the last morning at the hero's own hearth; walk to its keeper and
	# say goodbye, as a player would
	if Game.prologue != "":
		var hh: Dictionary = Cultures.HEARTHS[Game.prologue]
		_goto_entity(str(hh.keeper_area), str(hh.keeper))
		return
	var s := Game.cur_step()
	if s.is_empty():
		return
	# 1) rest when hurt or out of qi
	if _hp_ratio() < 0.5 or _qi_ratio() < 0.15:
		_start_meditate("rest")
		return
	# 1') survival (needs.gd, with --survival): tend the body as somebody careful would, from The Body's page
	if Game.survival and Needs.advice(Game, main.body_ctx()) != "":
		menu_goal = "body"
		world.move_dir = Vector2i.ZERO
		_press("cancel", 0.4)
		return
	# 1b) the Lotus release: Yue Ling has something to say; hear her out (T)
	if Bonds.talk_ready(Game) != "" and world.using.is_empty():
		world.move_dir = Vector2i.ZERO
		_press("talk", 0.5)
		return
	# 1c) and a wish of hers that a thing near the road can grant: a player passing a swing she asked
	# about would stop for it
	var wt = _wish_target(d)
	if wt != null:
		_walk_to(wt.pos, "wish:" + str(wt.id))
		return
	# 1a) Fates and Faces: ride whenever there is a ride (it waits outside buildings by itself), and
	# wear the newest outfit earned
	if Game.ride != "" and not Game.riding:
		_press("ride", 0.35)
		return
	var fit := _want_outfit()
	if fit == "":
		fit = _want_yue_outfit()
	if fit != "":
		menu_goal = "wardrobe"
		world.move_dir = Vector2i.ZERO
		_press("cancel", 0.4)
		return
	# 1a') the Eight Arms (arms.gd): the weapon the step asks for, or the next whose Dao is to be learned
	if _want_arm() != "":
		menu_goal = "arms"
		world.move_dir = Vector2i.ZERO
		_press("cancel", 0.4)
		return
	# 1b) the Hundred Works (works.gd): build the next work of the plan when it can be afforded
	if _want_work() != "":
		menu_goal = "works"
		world.move_dir = Vector2i.ZERO
		_press("cancel", 0.4)
		return
	# 2) shopping while in the sect
	var shop := _want_shop()
	if shop != "":
		_goto_entity("sect", shop)
		return
	# 2a) Part XII: open a Founder's cave nearby once the realm carved on its door is reached
	var ab = _openable_abode()
	if ab != null:
		_walk_to(ab.pos, "abode:" + str(ab.id))
		return
	# 2b) Part XI: change roads at a Dao Stele when the plan (or a trial's path) says so
	var want_dao := _planned_dao()
	if want_dao != "" and Game.dao != "" and Game.dao != want_dao:
		var st = _nearest_stele()
		if st != null:
			_walk_to(st.pos, "stele:" + str(st.id))
			return
	# 2c) many roads: prepare for the trial ahead along the path the plan chose (make it, earn it,
	# be asked for it, find it); levels are the quest's own grinding below
	if _prepare_trial():
		return
	# 3) quest objective
	match s.kind:
		"talk":
			_goto_entity(s.area, s.npc)
		"fate":
			# a fated encounter may come to blows: go to it rested, as to a boss
			if _hp_ratio() < 0.85 or _qi_ratio() < 0.6:
				_start_meditate("rest")
			else:
				_goto_entity(s.area, s.npc)
		"level":
			if not _cult_met():
				_grind()
		"collect":
			if s.has("cave"):
				# Part XX: the things to find are down in the region's cave (caves.gd): the nearest of them,
				# by way of the cave mouth
				_fetch(str(s.item))
			elif world.layer != Data.layer_of(s.area):
				# (upstairs or in a cellar of the region: the things to find are out in it, Part XI)
				_travel(s.area)
			elif not _goto_nearest("pickup", s.item, str(s.area)):
				_travel(s.area)
		"hunt", "falls":
			# (Part XXIV, "falls": the packs that cannot be beaten, dooms.gd, are walked up to like any
			# others, fought as the bot fights anything, and lost to)
			if s.has("cave") and world.layer != Caves.fid(str(s.area), int(s.cave)):
				# Part XX: a hunt in a cave: down by the cave mouth (and the shaft, for the lower gallery)
				if _hp_ratio() < 0.6 or _qi_ratio() < 0.3:
					_start_meditate("rest")
				else:
					_goto_layer(Caves.fid(str(s.area), int(s.cave)))
			elif not s.has("cave") and (Game.area != s.area or world.layer != Data.layer_of(s.area)):
				_travel(s.area)
			elif _hp_ratio() < 0.6:
				_start_meditate("rest")
			else:
				# (a hunt for particular foes, Part XIII's war-band, goes after those alone)
				var of: Array = s.get("of", [])
				var e = _nearest_enemy(s.area, false, of)
				if e == null:
					# nothing within a short walk: borders now lie well outside a region's open ground,
					# so head for the nearest pack anywhere in the region before waiting for respawns
					e = _any_enemy(s.area, false, of)
				if e != null:
					# Part XVII: a hunt that asks for the first strike (impact.gd) is fought that way: the
					# sword qi from a few tiles off when there is qi to spare, else F from beside the pack
					if bool(s.get("first", false)) and _strike_first(e):
						return
					_walk_to(e.pos, "enemy:" + e.id)
				else:
					_start_meditate("respawn")
		"kill", "fall":
			# (Part XXIV, "fall": a lord that cannot be beaten, dooms.gd: gone to rested all the same)
			if not _cult_met():
				_grind()
			elif _hp_ratio() < 0.85 or _qi_ratio() < 0.6:
				_start_meditate("rest")
			else:
				_goto_entity(s.area, "boss_" + s.boss)
		"marks":
			# Part XXIV: the nearest thing a choice left standing that has not been looked at (marks.gd)
			_marks_step()
		"reckon":
			# the reckoning (reckon.gd): whoever the journey's choices made, one after another, each gone to rested
			var rl: Array = Reckon.left(Game)
			if rl.is_empty():
				return
			if not _cult_met():
				_grind()
			elif _hp_ratio() < 0.85 or _qi_ratio() < 0.6:
				_start_meditate("rest")
			else:
				_goto_entity("mountain", "boss_" + str(rl[0]))
		"breakthrough":
			if not _cult_met():
				_grind()
			elif _hp_ratio() < 0.9 or _qi_ratio() < 0.8:
				_start_meditate("rest")
			else:
				menu_goal = "breakthrough"
				_press("cancel", 0.4)
		"visits", "fates":
			# Part XIII: the nearest of the people still to visit (any of them, in any order); Part XIV:
			# the nearest of the five fated encounters still to settle
			var vt := _visit_target()
			if s.kind == "fates" and (_hp_ratio() < 0.85 or _qi_ratio() < 0.6):
				_start_meditate("rest")
			elif vt != "":
				_goto_entity(Trials.npc_area(vt), vt)
		"share":
			# Part XV: the lotus pond where Yue Ling woke
			var sp := Bonds.find_spot(world.ents, str(s.spot))
			_goto_entity(str(s.area), str(sp.get("id", s.spot)))
		"memories":
			# Part XV: the next of her memories on the bot's round (any five), each guarded by moths
			var mm := _next_memory()
			if mm == "":
				return
			if _hp_ratio() < 0.85 or _qi_ratio() < 0.6:
				_start_meditate("rest")
			else:
				_goto_entity(str(Bonds.MEMORIES[mm].area), "mem:" + mm)
		"threads", "rally":
			# Part XV: the nearest of the people still to tie a thread for her; Part XVI: the nearest town
			# still to be reminded of the old ways
			var tv := _visit_target()
			if tv != "":
				_goto_entity(Trials.npc_area(tv), tv)
		"folk":
			# Part XVI: the nearest child of the towns still without a red envelope (folk.gd)
			_folk_step(s)
		"clear":
			# Part XVII: the nearest obstacle of the kind the step names, struck with the sword until it
			# goes (impact.gd)
			_clear_step(s)
		"works":
			# Part XIX: works are built from the menu (1b above builds as soon as one can be); if none
			# can be yet, there is know-how and there are spirit stones to be had from the wild
			_grind()
		"delve":
			# Part XX: the nearest cave it has not been to the back of (caves.gd)
			_delve_step()
		"arms":
			# Part XXI: Daos of arms are learned by winning with the weapon in hand (1a' above changes to
			# the next one to learn); there are battles to be had in the wild
			_grind()
		"try":
			# Part XX: the nearest thing of the cave still to be done (props.gd)
			_try_step(s)
		"war":
			# Part XXIII: a field battle, begun by a word with whoever commands on that field: go to it rested
			if _hp_ratio() < 0.85 or _qi_ratio() < 0.6:
				_start_meditate("rest")
			else:
				_goto_entity(str(s.area), str(s.npc))
		"airs":
			# Part XXIII: the next of the people who still sing their hearth's air
			for an in s.npcs:
				if not Game.airs.has(Cultures.of_npc(str(an))):
					_goto_entity(Trials.npc_area(str(an)), str(an))
					break
		"jobs", "host":
			# Part XXIII: the notice board of Qingshi: Clerk Bai, by the Drum Tower (the choice takes down
			# what can be reported at once, _choice)
			_goto_entity("village", Jobs.CLERK)
		"summit":
			# Part XXII: the top of the peak the step names, or of the nearest it has not stood on (peaks.gd)
			_summit_step(s)
		"glide":
			# Part XXII: up something high enough, and off it under the cloud-kite
			_glide_step(s)
		"grudges":
			# Part XIV: the next of the grudges that stayed (all six, in any order), each a boss
			var gr := _next_grudge()
			if gr == "":
				return
			if not _cult_met():
				_grind()
			elif _hp_ratio() < 0.85 or _qi_ratio() < 0.6:
				_start_meditate("rest")
			else:
				_goto_entity(Trials.boss_area(gr), "boss_" + gr)
		"gates":
			# Part XIII: the next of the Eight Gates (any four, in any order)
			var g := _next_gate()
			if g == "":
				return
			if not _cult_met():
				_grind()
			elif _hp_ratio() < 0.85 or _qi_ratio() < 0.6:
				_start_meditate("rest")
			else:
				_goto_entity(Trials.boss_area(g), "boss_" + g)

## Part XVII (impact.gd): an obstacle of the story, cleared as a player would clear it: walk up to it,
## turn to it (walking into it says what it is) and swing the sword (F) until it goes.
func _clear_step(s: Dictionary) -> void:
	if Game.area != str(s.area) or world.layer != Data.layer_of(str(s.area)):
		_travel(str(s.area))
		return
	var dist := _bfs_dist(world.ptile, 90)
	var best = null
	var bd := 1 << 30
	for e in world.ents:
		if e.kind != "obstacle" or str(e.area) != str(s.area) or str(e.what) != str(s.what) or not world.ent_visible(e):
			continue
		var ed := 1 << 20
		for dd in DIRS:
			if dist.has(e.pos + dd):
				ed = mini(ed, int(dist[e.pos + dd]))
		if ed >= 1 << 20:
			ed = (1 << 20) + absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)
		if ed < bd:
			bd = ed
			best = e
	if best == null:
		return
	if world.move_t < 0.0 and _beside(best.pos):
		var d: Vector2i = best.pos - world.ptile
		if world.facing != d:
			world.move_dir = d
			return
		world.move_dir = Vector2i.ZERO
		_press("strike", 0.45)
		return
	_walk_to(best.pos, "obstacle:" + str(best.id))

## Standing right beside tile `p` (not diagonally).
func _beside(p: Vector2i) -> bool:
	var d: Vector2i = p - world.ptile
	return absi(d.x) + absi(d.y) == 1

## The first strike (impact.gd) on pack `e`, as a player would deal it: walking straight at the pack,
## stop beside it and swing the sword (F), or stop a few tiles short in a clear line and throw the sword
## qi (G) when there is qi to spare.  Returns whether it is doing that this frame (else the bot walks on
## towards the pack, and walks into it: the ordinary battle).
func _strike_first(e: Dictionary) -> bool:
	if Game.scatters(e.group):
		return false
	# (where he is, or the tile he is stepping onto: the decision is made before he gets there)
	var here: Vector2i = world.target if world.move_t >= 0.0 else world.ptile
	var d: Vector2i = e.pos - here
	var n := absi(d.x) + absi(d.y)
	if (d.x == 0) == (d.y == 0) or n > 5:
		return false
	var step := Vector2i(signi(d.x), signi(d.y))
	# (only the way he is already going: turning to a pack beside him walks into it)
	if world.facing != step:
		return false
	for k in range(1, n):
		var q: Vector2i = here + step * k
		if not world.tile_free(q) or world.ent_at(q) != null:
			return false
	if n > 1 and _qi_ratio() <= 0.6:
		return false
	# stop where he is going, then swing
	world.move_dir = Vector2i.ZERO
	if world.move_t < 0.0:
		_press("strike" if n == 1 else "qi", 0.4)
	return true

func _start_meditate(goal: String) -> void:
	med_goal = goal
	menu_goal = "meditate"
	world.move_dir = Vector2i.ZERO
	_press("cancel", 0.4)

func _grind() -> void:
	# fight a nearby enemy if one is safe; failing that, the nearest pack anywhere in the region (in the
	# higher realms meditating to the next stage takes hours, where a few fights take minutes); only
	# then meditate
	if Game.area != "sect" and Game.area != Atlas.HUB and _hp_ratio() > 0.55:
		if world.is_floor():
			_travel(Game.area)
			return
		# (only packs that will stand and fight: a pack that scatters before Lin Feng's aura teaches
		# nothing, Part XII)
		var e = _nearest_enemy("", true)
		if e == null:
			e = _any_enemy(Game.area, true)
		if e != null:
			_walk_to(e.pos, "enemy:" + e.id)
			return
	# nothing here will fight (the sect, the mountain, a region whose beasts all scatter): go to where
	# the quest or the trial ahead is, if anything there will, rather than meditate for hours (back at
	# the sect to craft for a trial, the bot sat meditating towards Chiyou's realm, Part XIII).  From
	# anywhere, not only the sect: on its way to the graves it used to sit down in the Mirror Lake,
	# whose beasts all scatter, and meditate there for the rest of the game
	if true:
		var tt := _trial_target()
		var qa: String = str(tt.get("area", Game.cur_step().get("area", "")))
		if qa == "" or not _fights_in(qa):
			# a breakthrough has no region of its own: the latest one back along the quest with
			# something to fight (after the Conclave the last tribulation wants cultivation full)
			qa = ""
			for i in range(Game.step - 1, maxi(-1, Game.step - 12), -1):
				var pa: String = str(Data.STEPS[i].get("area", ""))
				if pa != "" and pa != "sect" and pa != Atlas.HUB and _fights_in(pa):
					qa = pa
					break
		if qa != "" and qa != Game.area and _hp_ratio() > 0.55:
			_travel(qa)
			return
	_start_meditate("grind")

## Whether region `area` has a pack that will stand and fight Lin Feng now.
func _fights_in(area: String) -> bool:
	for e in Atlas.world_of(Data.layer_of(area)).ents:
		if e.kind != "enemy" or str(e.get("area", "")) != area or not world.ent_visible(e) or Game.scatters(e.group) or Dooms.in_group(e.group):
			continue
		var mx := 0
		for g in e.group:
			mx = maxi(mx, g.lv)
		if mx <= Game.level + 2:
			return true
	return false

## Nearest reachable enemy group the party can handle.  The current target is kept unless another
## group is clearly closer: without that hysteresis two groups at almost the same distance swapped
## places as "nearest" with every step and the bot walked back and forth between two tiles forever.
func _nearest_enemy(area: String, fights: bool = false, of: Array = []):
	var dist := _bfs_dist(world.ptile, 64)
	var best = null
	var bd := 9999
	var cur_id := path_key.trim_prefix("enemy:") if path_key.begins_with("enemy:") else ""
	var cur = null
	var cur_d := 9999
	for e in world.ents:
		if e.kind != "enemy" or not world.ent_visible(e):
			continue
		if area != "" and e.area != area:
			continue
		if absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y) > 70:
			continue
		var mx := 0
		for g in e.group:
			mx = maxi(mx, g.lv)
		if mx > Game.level + 2 or (fights and Game.scatters(e.group)) or (not of.is_empty() and not e.group.any(func(g): return of.has(g.id))):
			continue
		# (dooms.gd: nobody goes looking for what cannot be beaten unless the step asks for it)
		if of.is_empty() and Dooms.in_group(e.group):
			continue
		var ed := 9999
		for dd in DIRS:
			var n: Vector2i = e.pos + dd
			if dist.has(n):
				ed = mini(ed, dist[n])
		if ed < bd:
			bd = ed
			best = e
		if e.id == cur_id:
			cur = e
			cur_d = ed
	if cur != null and cur_d <= bd + 4 and cur_d <= 60:
		return cur
	if bd > 60:
		return null
	return best

## The nearest pack of region `area` the party can handle, however far (straight-line distance).
func _any_enemy(area: String, fights: bool = false, of: Array = []):
	var best = null
	var bd := 1 << 30
	for e in world.ents:
		if e.kind != "enemy" or e.area != area or not world.ent_visible(e):
			continue
		var mx := 0
		for g in e.group:
			mx = maxi(mx, g.lv)
		if mx > Game.level + 2 or (fights and Game.scatters(e.group)) or (not of.is_empty() and not e.group.any(func(g): return of.has(g.id))):
			continue
		if of.is_empty() and Dooms.in_group(e.group):
			continue
		var dd: int = absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)
		if dd < bd:
			bd = dd
			best = e
	return best

## Walk to the nearest thing of `kind` and `item` that can be seen (in region `area`, if one is named:
## the road to it may cross a corner of another region, so it is the thing that is headed for and
## not the region; the one already being walked to is kept to).  False if there is none.
func _goto_nearest(kind: String, item: String, area: String = "") -> bool:
	var best = null
	var bd := 1 << 30
	for e in world.ents:
		if e.kind == kind and e.get("item", "") == item and world.ent_visible(e) and (area == "" or str(e.get("area", area)) == area):
			var dd: int = absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)
			if path_key == "pickup:" + str(e.id):
				dd = -1
			if dd < bd:
				bd = dd
				best = e
	if best == null:
		return false
	_walk_to(best.pos, "pickup:" + best.id)
	return true

func _goto_entity(area: String, id: String) -> void:
	var e = world.find_ent(id)
	if e == null:
		# in another realm or on another floor (Part XI): head for the ladder or stairs towards it
		var hit: Array = world.locate_ent(id)
		if not hit.is_empty():
			_goto_layer(str(hit[0]))
			return
		_travel(area)
		return
	_walk_to(e.pos, "ent:" + id)

## Walk to where travellers arrive in region `dest` (the open world has no gates to step through),
## by way of the ladders if it lies in another realm.
func _travel(dest: String) -> void:
	var lid := Data.layer_of(dest)
	if lid != world.layer:
		_goto_layer(lid)
		return
	var goal := Atlas.to_world("sect", Vector2i(20, 8))
	if dest != "sect":
		var arr: Array = MapGen.arrival_tiles(dest)
		if not arr.is_empty():
			goal = Atlas.to_world(dest, arr[0])
		else:
			# a realm's first region has no road in: its ladder end is where travellers arrive
			for le in MapGen.ladder_ends(dest):
				goal = Atlas.to_world(dest, le[0] + le[1])
	_walk_to(goal, "travel:" + dest)

## Head for the ladder or stairs that leads one step nearer realm (or floor) `target`: a breadth-first
## search over the realms the open ladders join.
func _goto_layer(target: String) -> void:
	var lad = _ladder_towards(target)
	if lad == null:
		world.move_dir = Vector2i.ZERO
		return
	_walk_to(lad.pos, "ladder:" + str(lad.id))

func _ladder_towards(target: String):
	var start: String = world.layer
	var prev := {start: null}
	var q: Array = [start]
	var i := 0
	while i < q.size():
		var cur: String = q[i]
		i += 1
		if cur == target:
			break
		for e in _realm_ents(cur):
			if e.kind != "ladder" or not world.ladder_open(e):
				continue
			var nx: String = str(e.to_layer)
			if not prev.has(nx):
				prev[nx] = [cur, e]
				q.append(nx)
	if not prev.has(target) or target == start:
		return null
	var step = prev[target]
	while step[0] != start:
		step = prev[step[0]]
	return step[1]

func _realm_ents(lid: String) -> Array:
	var lw: Dictionary = Atlas.world_of(lid)
	return lw.get("ents", [])

## Part XI: the Dao the plan wants for the current quest step ("" before Part XI).
func _planned_dao() -> String:
	var want := ""
	for pl in DAO_PLAN:
		if Game.reached(pl[0]):
			want = pl[1]
	# a trial's path that asks for a Dao: walk it until the trial is passed
	var tt := _trial_target()
	if want != "" and not tt.is_empty():
		for n in Trials.path(tt.tid, str(tt.pid)).needs:
			if str(n[0]) == "dao" and str(n[1]) != "":
				want = str(n[1])
	return want

func _nearest_stele():
	var best = null
	var bd := 1 << 30
	for e in world.ents:
		if e.kind == "stele" and world.ent_visible(e):
			var dd: int = absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)
			if dd < bd:
				bd = dd
				best = e
	return best

## Part XII: a Founder's cave on this realm the bot can open now, not far off the road.
func _openable_abode():
	var best = null
	var bd := 90
	for e in world.ents:
		if e.kind != "abode" or Game.abodes.has(e.id) or Game.level < int(e.req):
			continue
		var dd: int = absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)
		if dd < bd:
			bd = dd
			best = e
	return best

## Part XII: the branch the plan wakes next (the first planned rank not yet woken).
func _planned_talent(ids: Array) -> String:
	var seen := {}
	for t in TALENT_PLAN:
		seen[t] = int(seen.get(t, 0)) + 1
		if Game.talent(t) < int(seen[t]) and ids.has(t):
			return t
	return str(ids[0]) if not ids.is_empty() else ""

## The newest outfit earned, if the bot is not wearing it ("" if it is).
func _want_outfit() -> String:
	var best := ""
	for id in Fashion.OUTFIT_ORDER:
		if Game.outfits.has(id):
			best = id
	return best if best != Game.outfit else ""

## Whether a notice of the board asks for something the journey has done already (jobs.gd).
func _job_done_already(id: String) -> bool:
	var nd: Array = Jobs.JOBS[id].need
	match str(nd[0]):
		"reach":
			return Feats.value(Game, [str(nd[1]), 0]) >= float(nd[2])
		"have":
			for k in nd[1]:
				if int(Game.inv.get(k, 0)) < int(nd[1][k]) + 2:
					return false
			return true
		"war":
			return Game.war_won.has(str(nd[1]))
	return false

## The field of war (field.gd): the order Master Sun would give (War.best), a drum at a time.
func _field() -> void:
	var f = main.field
	match str(f.state):
		"order":
			var want: int = f.ids.find(War.best(f.st))
			if want < 0 or not f.enabled[want]:
				want = f.ids.find("hold")
			if f.cursor == want:
				_press("confirm", 0.9)
			else:
				_nav(f.labels.size(), f.cursor, want)
		"result":
			_press("confirm", 1.6)
		_:
			cool = 0.3

## The newest dress Yue Ling has that she is not wearing ("" if she wears it).
func _want_yue_outfit() -> String:
	if not Game.companion:
		return ""
	var best := ""
	for id in Fashion.YUE_ORDER:
		if Game.yue_outfits.has(id):
			best = id
	return best if best != Game.yue_outfit else ""

## The Eight Arms (arms.gd): the weapon the bot should have in its hand, "" if it already has.  The
## one a step of the story asks for; else it learns each weapon it owns in turn, to Adept and then to
## Master (the way a player who wants every technique would), and ends with the jian in its hand.
func _want_arm() -> String:
	var st := Game.cur_step()
	var want := ""
	if st.has("arm") and Game.arms.has(str(st.arm)):
		want = str(st.arm)
	else:
		for goal in [1, 2]:
			if want != "":
				break
			# (the one in hand is kept until it reaches the rank, so it is not put down half learned)
			if Arms.tier(Game) < goal:
				want = Arms.held(Game)
				break
			for id in Arms.ORDER:
				if Game.arms.has(id) and Arms.tier(Game, id) < goal:
					want = id
					break
		if want == "":
			want = "sword"
	return want if want != Arms.held(Game) else ""

## The option of a fated encounter's choice the plan prefers (the first in FATE_PLAN that can be taken).
func _fate_pick(c, ids: Array) -> int:
	var sid: String = str(main.fate_sid)
	# (the follow-up choice after a chapter's battle has its own plan)
	var keys := [sid + ":follow", sid] if not main.choice.cancel_ok else [sid]
	for key in keys:
		for want in FATE_PLAN.get(key, []):
			var k: int = ids.find(want)
			if k >= 0 and c.options[k].get("enabled", true):
				return k
	for k2 in ids.size():
		if c.options[k2].get("enabled", true):
			return k2
	return 0

## The choice screen (Part XI): the Dao the plan wants; a gift is kept; a branch of the root as the
## plan says (Part XII).
func _choice() -> void:
	var c = main.choice
	var ids: Array = c.ids()
	var want := -1
	var tt := _trial_target()
	var st := Game.cur_step()
	if str(c.title) == main.ENDING_ASK:
		# the end of the story (cultures.gd): the end asked for (--ending=<id>) if the journey earned it,
		# else the rarest it did earn
		for eid in [str(main.args.get("ending", ""))] + ENDING_PLAN:
			var k0: int = ids.find(eid)
			if want < 0 and k0 >= 0 and c.options[k0].get("enabled", true):
				want = k0
		_nav(ids.size(), c.cursor, maxi(want, 0))
		return
	if str(c.title) == Jobs.ASK:
		# the notice board (jobs.gd): report what is done; else take down a notice that is done already
		# (it is reported in the same breath); else leave it
		want = -1
		for kj in ids.size():
			if want < 0 and str(ids[kj]).begins_with("report:"):
				want = kj
		for kj2 in ids.size():
			if want < 0 and str(ids[kj2]).begins_with("take:") and _job_done_already(str(ids[kj2]).get_slice(":", 1)):
				want = kj2
		_nav(ids.size(), c.cursor, want if want >= 0 else ids.find("later"))
		return
	if str(c.title) == Needs.FOOD_ASK:
		# a cook, with survival on: keep four buns and two boxes of noodles in the pack
		want = ids.find("later")
		for fw in [["noodle_bowl", 2], ["steamed_bun", 4]]:
			var kf: int = ids.find(str(fw[0]))
			if want == ids.find("later") and kf >= 0 and c.options[kf].get("enabled", true) and int(Game.inv.get(str(fw[0]), 0)) < int(fw[1]):
				want = kf
		_nav(ids.size(), c.cursor, want)
		return
	if str(c.title) == main.DRILL_ASK or str(c.title) == main.TAILOR_ASK or str(c.title) == Gamble.ASK:
		_nav(ids.size(), c.cursor, ids.find("later"))
		return
	if str(c.title) == main.ARMS_ASK:
		want = ids.find(_want_arm())
		if want < 0:
			want = ids.find(Arms.held(Game))
		_nav(ids.size(), c.cursor, want)
		return
	if str(c.title) == main.WARDROBE_ASK:
		want = ids.find(_want_outfit())
		if want < 0:
			# (his own is on: hers next, if she has something newer to put on)
			want = ids.find("yue") if _want_yue_outfit() != "" else ids.find(Game.outfit)
		_nav(ids.size(), c.cursor, want)
		return
	if str(c.title) == main.YUE_WARDROBE_ASK:
		want = ids.find(_want_yue_outfit())
		if want < 0:
			want = ids.find(Game.yue_outfit)
		_nav(ids.size(), c.cursor, want)
		return
	for pk in PICK_PLAN:
		if str(c.title) == str(Fate.PICKS[pk].ask):
			_nav(ids.size(), c.cursor, ids.find(PICK_PLAN[pk]))
			return
	# a crossroads of the road (echoes.gd): the answer the plan prefers that can be given
	for cid in Echoes.ORDER:
		if str(c.title) == str(Echoes.CROSSROADS[cid].ask):
			want = -1
			for oid in CROSS_PLAN.get(cid, []):
				var kc: int = ids.find(oid)
				if want < 0 and kc >= 0 and c.options[kc].get("enabled", true):
					want = kc
			if want < 0:
				for kc2 in ids.size():
					if want < 0 and c.options[kc2].get("enabled", true):
						want = kc2
			_nav(ids.size(), c.cursor, maxi(want, 0))
			return
	# the Lotus release (bonds.gd): a heart-to-heart, a memory given back, the lotus pond
	for tk in Bonds.TALKS:
		if str(c.title) == str(tk.ask):
			_nav(ids.size(), c.cursor, maxi(0, ids.find(str(TALK_PLAN.get(str(tk.id), "")))))
			return
	for mid in Bonds.MEMORIES:
		if str(c.title) == str(Bonds.MEMORIES[mid].ask):
			_nav(ids.size(), c.cursor, maxi(0, ids.find(str(MEMORY_PLAN.get(mid, "")))))
			return
	for shid in Bonds.SHARES:
		if str(c.title) == str(Bonds.SHARES[shid].ask):
			var want_s := str(SHARE_PLAN.get(shid, ""))
			if Bonds.SHARES[shid].get("future", false):
				want_s = Bonds.leaning(Game) if Bonds.leaning(Game) != "" else "companion"
			_nav(ids.size(), c.cursor, maxi(0, ids.find(want_s)))
			return
	for gid in GRUDGE_PLAN:
		if str(c.title) == str(Grudges.GRUDGES[gid].ask):
			# a grudge that stayed, spent: the answer the plan prefers that can be given
			want = -1
			for oid in GRUDGE_PLAN[gid]:
				var k: int = ids.find(oid)
				if want < 0 and k >= 0 and c.options[k].get("enabled", true):
					want = k
			_nav(ids.size(), c.cursor, want if want >= 0 else ids.find("wheel"))
			return
	if not st.is_empty() and (st.kind == "fate" or st.kind == "fates") and not str(c.title).ends_with("how will you face it?"):
		_nav(ids.size(), c.cursor, _fate_pick(c, ids))
		return
	if str(c.title).ends_with("how will you face it?"):
		# a trial: the path the plan chose (cancel if it cannot be taken after all)
		want = ids.find(str(tt.get("pid", ""))) if not tt.is_empty() else -1
		if want >= 0 and not c.options[want].get("enabled", true):
			want = -1
		_nav(ids.size(), c.cursor, want)
		return
	if Data.TALENTS.has(str(ids[0]) if not ids.is_empty() else ""):
		want = ids.find(_planned_talent(ids))
	elif ids.has("sword"):
		want = ids.find(_planned_dao() if _planned_dao() != "" else "sword")
	elif ids.has("help"):
		# a townsperson's request: help when it can be done
		want = ids.find("help") if c.options[ids.find("help")].get("enabled", true) else ids.find("later")
	elif ids.has("keep"):
		want = ids.find("keep")
	if want < 0:
		want = 0
	_nav(ids.size(), c.cursor, want)

# ---------------------------------------------------------------- many roads (trials.gd)
## The trial ahead: {"tid" (the boss), "pid" (the path the bot takes), "area"} or {}.
func _trial_target() -> Dictionary:
	var fr := Engine.get_process_frames()
	if fr == tt_frame:
		return tt_cache
	tt_frame = fr
	tt_cache = {}
	var s := Game.cur_step()
	if s.is_empty():
		return tt_cache
	var tid := ""
	if s.kind == "kill" and Trials.TRIALS.has(str(s.boss)):
		tid = str(s.boss)
	elif s.kind == "gates":
		tid = _next_gate()
	if tid == "":
		return tt_cache
	tt_cache = {"tid": tid, "pid": _path_for(tid), "area": Trials.boss_area(tid)}
	return tt_cache

## A thing near the bot that grants one of Yue Ling's open wishes (bonds.gd), or null: the nearest of
## that kind within a short walk, out of doors, while she is with him.  One it cannot get to within half
## a minute is left alone.
var wish_id := ""
var wish_t := 0.0
var wish_skip := {}
const WISH_REACH := 24

func _wish_target(d: float):
	if not Game.companion or world.is_floor():
		return null
	var st := Game.cur_step()
	if st.is_empty() or str(st.kind) in ["fate", "fates", "breakthrough"]:
		return null
	if wish_id != "":
		var we = world.find_ent(wish_id)
		var still := false
		if we != null:
			for wid in Bonds.wishes_open(Game):
				still = still or str(Bonds.wish(str(wid)).kind) == str(we.prop)
		wish_t += d
		if we != null and still and wish_t < 30.0:
			return we
		if wish_t >= 30.0:
			wish_skip[wish_id] = true
		wish_id = ""
	var kinds := {}
	for wid2 in Bonds.wishes_open(Game):
		kinds[str(Bonds.wish(str(wid2)).kind)] = true
	if kinds.is_empty():
		return null
	var best = null
	var bd := WISH_REACH + 1
	for e in world.ents:
		if e.kind != "prop" or e.has("furn") or not kinds.has(str(e.prop)) or wish_skip.has(str(e.id)):
			continue
		var dd: int = absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)
		if dd < bd:
			bd = dd
			best = e
	if best != null:
		wish_id = str(best.id)
		wish_t = 0.0
	return best

## The next of Yue Ling's memories (Part XV) on the bot's round, "" when none is left to give back.
func _next_memory() -> String:
	for mid in MEMORY_ROUTE + Bonds.MEMORY_ORDER:
		if Game.memories.has(mid):
			continue
		if world.find_ent("mem:" + mid) != null or not world.locate_ent("mem:" + mid).is_empty():
			return mid
	return ""

## The next of the grudges that stayed (Part XIV) on the bot's round, "" once all six are answered.
func _next_grudge() -> String:
	for gid in GRUDGE_ROUTE:
		if not Game.grudges.has(gid):
			return gid
	return ""

## The next of the Eight Gates: the planned ones in order, then any a way is open through.
func _next_gate() -> String:
	for g in GATE_PLAN:
		if not Game.gates_open.has(g) and _feasible(g, Trials.path(g, str(TRIAL_PLAN.get(g, "")))):
			return g
	for g2 in Trials.GATES:
		if not Game.gates_open.has(g2) and not Trials.open_paths(g2, Game).is_empty():
			return g2
	for g3 in GATE_PLAN:
		if not Game.gates_open.has(g3):
			return g3
	return ""

## The path through trial `tid`: the planned one if it can be taken, else the one with fewest needs
## still unmet among those the bot can work towards.
func _path_for(tid: String) -> String:
	var want: String = route if tid == "chiyou" else str(TRIAL_PLAN.get(tid, ""))
	var p := Trials.path(tid, want)
	if not p.is_empty() and _feasible(tid, p):
		return want
	var best := ""
	var bn := 99
	for q in Trials.TRIALS[tid].paths:
		if not _feasible(tid, q):
			continue
		var paid: bool = str(Game.paid.get(tid, "")) == str(q.id)
		var unmet := 0
		for n in q.needs:
			if not Trials.need_met(n, Game, paid):
				unmet += 1
		if unmet < bn:
			bn = unmet
			best = str(q.id)
	return best if best != "" else want

## Can the bot work its way to every need of path `p`?  (Levels by fighting, stones by fighting,
## things made from essences it can hunt, things it can pick up, renown from deeds it can do, a Dao
## it has already walked far enough.)
func _feasible(tid: String, p: Dictionary) -> bool:
	if p.is_empty():
		return false
	var paid: bool = str(Game.paid.get(tid, "")) == str(p.id)
	for n in p.needs:
		if Trials.need_met(n, Game, paid):
			continue
		match str(n[0]):
			"lv", "peak", "temper":
				pass
			"stones":
				if Game.stones < int(n[1]) * 0.6:
					return false
			"item", "give":
				var id: String = str(n[1])
				if Trials.RECIPES.has(id):
					var r: Dictionary = Trials.RECIPES[id]
					if not Game.reached(str(r.after)):
						return false
					# (the Lost Horse release: nor is a thing made that the purse is nowhere near: what the
					# forge asks late in the story is more than a day of fighting pays, and a bot that had
					# lost a seventh of its purse to the healers once waited at the Cloud Ladder for ever.
					# It takes another road through the trial)
					# (short by no more than a hundred beaten foes pay: that much it will go and earn)
					if int(Game.inv.get(id, 0)) < int(n[2]) and Game.stones + Data.enemy_stones(Game.level, false) * 100 < Trials.recipe_stones(id, Game):
						return false
					for k in r.in:
						# (a keepsake in a recipe can be picked up where one lies)
						if not str(k).begins_with("ess_") and int(Game.inv.get(k, 0)) + _pickups_of(str(k)) < int(r.in[k]):
							return false
				elif _pickups_of(id) < int(n[2]) - int(Game.inv.get(id, 0)):
					return false
			"renown":
				if Game.renown + _deed_renown() < int(n[1]):
					return false
			"dao":
				var did: String = str(n[1]) if str(n[1]) != "" else Game.dao
				if did == "" or Game.dao == "" or Game.dao_tier(did) < int(n[2]):
					return false
			"heart":
				# closeness with Yue Ling grows by itself on the road (talks, memories); none to make
				return false
			"cleared":
				# the Spring Thunder release: the land is opened by the chapter's own clearing quests on
				# the way to the trial (impact.gd); there is nothing else to do for it
				pass
			"hearths":
				# the New Fire release: a place at the hearths is earned by the chapter's own errands
				# among their people on the way to the trial (cultures.gd); nothing else to do for it
				pass
			"works":
				# the Hundred Works release: works are built as the plan affords them (WORKS_PLAN); a path
				# that asks for more than stand is not one to wait for
				return false
			"delved":
				# the Hollow Hills release: caves can be gone to the back of whenever it likes (_delve_step)
				pass
			"arms":
				# the Hundred Arms release: a Dao of arms is learned by fighting with the weapon in hand,
				# which the bot does all along (_want_arm)
				pass
			"summits":
				# the High Roads release: a summit can be climbed whenever it likes (_summit_step)
				pass
			"falls", "marks":
				# the Lost Horse release: what was lost to is what the story has put in the way by then; what
				# stands can be gone and looked at whenever it likes (_marks_step does, when a step asks)
				if str(n[0]) == "falls":
					return false
			"companies", "airs":
				# the Thundering Pots release: the host and the airs are what the story has given by then
				if not Trials.need_met(n, Game) and Game.done("s_p23_levy"):
					return false
			_:
				return false
	return true

## Work towards the next unmet need of the path chosen through the trial ahead.  Returns whether it
## did something this frame.
func _prepare_trial() -> bool:
	var tt := _trial_target()
	if tt.is_empty() or str(tt.pid) == "":
		return false
	var tid: String = tt.tid
	var p := Trials.path(tid, str(tt.pid))
	if p.is_empty() or not _feasible(tid, p):
		return false
	var paid: bool = str(Game.paid.get(tid, "")) == str(p.id)
	for n in p.needs:
		if Trials.need_met(n, Game, paid):
			continue
		match str(n[0]):
			"temper":
				if Game.stones >= Works.temper_cost(Game):
					_goto_entity("sect", "smith")
				else:
					_earn(tt)
				return true
			"stones":
				_earn(tt)
				return true
			"item", "give":
				var id: String = str(n[1])
				if Trials.RECIPES.has(id):
					return _craft_step(id, tt)
				return _fetch(id)
			"renown":
				return _deed_step(tt)
			"delved":
				# the Hollow Hills release: go to the back of another cave
				return _delve_step()
			"arms":
				# the Hundred Arms release: more battles with the weapon it is learning in hand
				_grind()
				return true
			"summits":
				# the High Roads release: up the nearest peak it has not stood on
				return _summit_step({})
			_:
				# levels: the quest's own grinding (_cult_target); a Dao: the stele (_planned_dao)
				return false
	return false

## Part XX (caves.gd): head for what is left at the very back of the nearest cave the bot has not been
## to the back of (in this realm; once chosen, that one until it is done).  False if none is left.
var delve_id := ""

func _delve_step() -> bool:
	if _hp_ratio() < 0.6 or _qi_ratio() < 0.3:
		_start_meditate("rest")
		return true
	if delve_id != "" and (Game.taken.has(delve_id) or world.locate_ent(delve_id).is_empty()):
		delve_id = ""
	if delve_id == "":
		var realm: String = str(world.wd.parent) if world.is_floor() else str(world.layer)
		var lw: Dictionary = Atlas.world_of(realm)
		var me: Vector2i = world.ptile + (Vector2i(world.wd.origin) if world.is_floor() else Vector2i.ZERO)
		var bd := 1 << 30
		for fid in lw.floors:
			var fw: Dictionary = lw.floors[fid]
			if not fw.get("cave", false) or int(fw.level) != -1 or Game.delved.has(fid):
				continue
			# (a cave in a region the journey has been through, before one it has not: the roads there
			# are known to be open)
			var mouth: Vector2i = fw.realm_mouth
			var dd: int = absi(mouth.x - me.x) + absi(mouth.y - me.y) + (0 if Game.seen.has(str(fw.area)) else 100000)
			if dd < bd:
				bd = dd
				delve_id = "cave_cache:%s:-1" % str(fw.area)
	if delve_id == "":
		return false
	_goto_entity(delve_id.get_slice(":", 1), delve_id)
	return true

## Part XXIV (marks.gd): walk up to the nearest thing a choice left standing in this realm that has not
## been looked at yet (in a region the journey has been through before one it has not), and look at it.
var mark_id := ""

func _marks_step() -> void:
	if mark_id != "":
		var hit: Array = world.locate_ent(mark_id)
		if Game.marks_seen.has(Marks.seen_key(mark_id)) or hit.is_empty() or not Marks.stands(Game, hit[1]):
			mark_id = ""
	if mark_id == "":
		var bd := 1 << 30
		for lid in ["surface", "heaven", "under", "sea"]:
			var lw: Dictionary = Atlas.world_of(lid)
			var here: Vector2i = world.ptile if world.layer == lid else Vector2i(-100000, 0)
			for e in lw.ents:
				if e.kind != "mark" or not Marks.stands(Game, e) or Game.marks_seen.has(Marks.seen_key(str(e.id))):
					continue
				var dd: int = (absi(e.pos.x - here.x) + absi(e.pos.y - here.y) if world.layer == lid else 200000) + (0 if Game.seen.has(str(e.area)) else 100000)
				if dd < bd:
					bd = dd
					mark_id = str(e.id)
	if mark_id == "":
		# (nothing left standing that has not been looked at: a journey cannot get here that way, but a
		# run that is lost should say so and stop)
		_finish("nothing stands in the land that has not been looked at")
		return
	_goto_entity(mark_id.get_slice(":", 1) if mark_id.begins_with("sign:") else mark_id.get_slice(":", 2), mark_id)

## Part XXII (peaks.gd): climb to the very top of the peak step `s` names (the highest of a region), or
## of the nearest peak of this realm it has not stood on, as a player with the map open would: there is
## a mark on the minimap for every one.  Returns false if there is none left.
var summit_id := ""

func _summit_step(s: Dictionary) -> bool:
	var realm: String = str(world.wd.parent) if world.is_floor() else str(world.layer)
	if s.has("peak"):
		var lid := Data.layer_of(str(s.peak))
		if lid != realm:
			_goto_layer(lid)
			return true
		summit_id = "peak:%s:%d" % [str(s.peak), int(s.get("k", 0))]
	if world.is_floor():
		_goto_layer(realm)
		return true
	var lw: Dictionary = world.wd
	if summit_id != "" and (Game.summits.has(summit_id) or Peaks.by_id(lw, summit_id).is_empty()):
		summit_id = ""
	if summit_id == "":
		var bd := 1 << 30
		for pk in lw.get("peaks", []):
			if Game.summits.has(str(pk.id)):
				continue
			# (a peak in a region the journey has been through, before one it has not)
			var c: Vector2i = pk.c
			var dd: int = absi(c.x - world.ptile.x) + absi(c.y - world.ptile.y) + (0 if Game.seen.has(str(pk.area)) else 100000)
			if dd < bd:
				bd = dd
				summit_id = str(pk.id)
	if summit_id == "":
		return false
	_walk_to(Peaks.by_id(lw, summit_id).c, "summit:" + summit_id)
	return true

## Part XXII: a flight of so many tiles: up the nearest peak tall enough for it, and off its top in
## whichever direction the air is clear for longest (V), as a player on a summit would look round
## before leaping.  A peak whose every side is shut is not tried twice.
var glide_from := ""
var glide_skip := {}

func _glide_step(s: Dictionary) -> void:
	if world.gliding():
		world.move_dir = Vector2i.ZERO
		return
	if world.is_floor():
		_goto_layer(str(world.wd.parent))
		return
	var lw: Dictionary = world.wd
	var need := int(s.n)
	if glide_from == "" or Peaks.by_id(lw, glide_from).is_empty() or glide_skip.has(glide_from):
		glide_from = ""
		var bd := 1 << 30
		for pk in lw.get("peaks", []):
			# (a flight loses four fifths of a metre a tile: a peak must be tall enough to give it room)
			if glide_skip.has(str(pk.id)) or float(pk.h) + float(world.GLIDE_LEAP) < float(need) * float(world.GLIDE_SINK) + 1.0 or not Game.seen.has(str(pk.area)):
				continue
			var c: Vector2i = pk.c
			var dd: int = absi(c.x - world.ptile.x) + absi(c.y - world.ptile.y) + (0 if str(pk.area) == str(s.get("area", "")) else 600)
			if dd < bd:
				bd = dd
				glide_from = str(pk.id)
	if glide_from == "":
		# nowhere it has been is tall enough: go and stand on more of the land's peaks
		glide_skip = {}
		_summit_step({})
		return
	var top: Vector2i = Peaks.by_id(lw, glide_from).c
	if world.ptile != top or world.move_t >= 0.0:
		_walk_to(top, "glide:" + glide_from)
		return
	var best := Vector2i.ZERO
	var bn := 0
	for d in DIRS:
		var n: int = world.glide_reach(d)
		if n > bn:
			bn = n
			best = d
	if bn < need:
		glide_skip[glide_from] = true
		return
	world.move_dir = Vector2i.ZERO
	world.facing = best
	_press("glide", 0.5)

## Part XX: do the nearest thing of the step's cave that has not been done for it yet.
func _try_step(s: Dictionary) -> void:
	var fid := Caves.fid(str(s.area), int(s.get("cave", -1)))
	var fw: Dictionary = Atlas.world_of(fid)
	if fw.is_empty():
		return
	var best = null
	var bd := 1 << 30
	for e in fw.ents:
		if e.kind != "prop" or Game.step_uses.has(str(e.prop)):
			continue
		if s.has("things") and not str(e.prop) in s.things:
			continue
		var dd: int = (absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)) if world.layer == fid else (absi(e.pos.x - int(fw.start.x)) + absi(e.pos.y - int(fw.start.y)))
		if dd < bd:
			bd = dd
			best = e
	if best == null:
		return
	_goto_entity(str(s.area), str(best.id))

## Make something for a trial: hunt the essences it needs, earn the stones, then take it all to the
## alchemist or the smith (the shop crafts it, _shop).
func _craft_step(id: String, tt: Dictionary) -> bool:
	var r: Dictionary = Trials.RECIPES[id]
	for k in r.in:
		if int(Game.inv.get(k, 0)) < int(r.in[k]):
			if str(k).begins_with("ess_"):
				return _farm(str(k), tt)
			return _fetch(str(k))
	if Game.stones < int(r.get("stones", 0)):
		_earn(tt)
		return true
	_goto_entity("sect", str(r.at))
	return true

## Hunt packs that leave essence `ek`: the nearest in this realm that will stand and fight.
func _farm(ek: String, tt: Dictionary) -> bool:
	if _hp_ratio() < 0.55:
		_start_meditate("rest")
		return true
	var el := Trials.elem_of(ek)
	var best = null
	var bd := 1 << 30
	if not world.is_floor():
		for e in world.ents:
			if e.kind != "enemy" or not world.ent_visible(e) or Game.scatters(e.group) or Dooms.in_group(e.group):
				continue
			var mx := 0
			var has := false
			for g in e.group:
				mx = maxi(mx, g.lv)
				has = has or str(Data.ENEMIES[g.id].elem) == el
			if not has or mx > Game.level + 2:
				continue
			var dd: int = absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)
			if dd < bd:
				bd = dd
				best = e
	if best != null:
		_walk_to(best.pos, "enemy:" + best.id)
		return true
	if world.is_floor() or world.layer != Data.layer_of(str(tt.area)):
		_travel(str(tt.area))
	else:
		_start_meditate("respawn_any")
	return true

## Earn spirit stones by fighting: here if anything will fight, else in the trial's own region.
func _earn(tt: Dictionary) -> void:
	if _hp_ratio() < 0.55:
		_start_meditate("rest")
		return
	var e = null if world.is_floor() else _any_enemy(Game.area, true)
	if e != null:
		_walk_to(e.pos, "enemy:" + e.id)
		return
	# (the Lost Horse release: nothing here will fight.  The trial's own region, if anything there will;
	# else the latest region back along the story where something does.  The bot once came to the Cloud
	# Ladder short of what the forge asked, a fall having cost it a seventh of its purse, and sat down on
	# the mountain, whose beasts all scatter, to wait for packs that would never stand)
	var where := str(tt.area)
	if not _fights_in(where):
		where = ""
		for i in range(Game.step - 1, maxi(-1, Game.step - 16), -1):
			var pa: String = str(Data.STEPS[i].get("area", ""))
			if pa != "" and pa != "sect" and pa != Atlas.HUB and _fights_in(pa):
				where = pa
				break
	if where != "" and (Game.area != where or world.is_floor()):
		_travel(where)
	elif Game.area != str(tt.area) and where == "":
		_travel(str(tt.area))
	else:
		_start_meditate("respawn_any")

## The next person a "visits" step still wants seen: once chosen, that one until visited (the nearest by
## realm first: this realm or its floors, then the others).
var visit_id := ""

func _visit_target() -> String:
	var s := Game.cur_step()
	var want: Array = s.get("npcs", [])
	# (Part XV's threads are counted apart from the visits of Parts XIII and XIV)
	# (and Part XVI's towns reminded of the old ways)
	var seen_: Dictionary = Game.threads if str(s.kind) == "threads" else (Game.rallied if str(s.kind) == "rally" else Game.visited)
	if visit_id != "" and want.has(visit_id) and not seen_.has(visit_id):
		return visit_id
	var here: String = str(world.layer) if not world.is_floor() else str(world.wd.parent)
	var best := ""
	var bd := 1 << 30
	for k in want.size():
		var id: String = str(want[k])
		if seen_.has(id):
			continue
		var cost := k + (0 if Data.layer_of(Trials.npc_area(id)) == here else 1000)
		var e = world.find_ent(id)
		if e != null and not world.ent_visible(e):
			# (somebody who is not there: a friend who fell, Part XIV)
			continue
		if e != null:
			cost = absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y) - 2000
		if cost < bd:
			bd = cost
			best = id
	visit_id = best
	return best

## Part XVI's red envelopes (folk.gd): walk up to the nearest child of the towns still to be given
## one, turn to them and press Enter, as a player would; while they are all indoors (the dinner hour,
## the night), wait in the town of the step for them to come out.
func _folk_step(s: Dictionary) -> void:
	var role: String = str(s.get("role", "child"))
	var tgt := _folk_target(role)
	if tgt.is_empty():
		# nobody to be found out of doors: wait in the town it is working through (the step's own town
		# first), never in the one before; a town of the step's region before any other
		var town := _folk_town(role)
		var ar: String = str(Folk.town(town).area) if town != "" else str(s.area)
		var hc: Vector2i = Folk.heart(town) if town != "" else world.ptile
		if Game.area != ar or world.layer != Data.layer_of(ar):
			_travel(ar)
		elif absi(hc.x - world.ptile.x) + absi(hc.y - world.ptile.y) > Folk.RADIUS:
			_walk_to(_near_free(hc), "folk_town:" + town)
		else:
			_start_meditate("children")
		return
	var at: Vector2i = tgt.tile
	var here: Vector2i = world.ptile
	if world.move_t < 0.0 and absi(at.x - here.x) + absi(at.y - here.y) == 1:
		world.move_dir = Vector2i.ZERO
		world.facing = at - here
		_press("confirm", 0.4)
		return
	var best := Vector2i(-1, -1)
	var bd := 1 << 30
	for d in DIRS:
		var q: Vector2i = at + d
		if not world.tile_free(q) or world.ent_at(q) != null:
			continue
		var dd := absi(q.x - here.x) + absi(q.y - here.y)
		if dd < bd:
			bd = dd
			best = q
	if best.x < 0:
		_start_meditate("children")
		return
	_walk_to(best, "folk:%s:%s" % [str(tgt.id), str(best)])

## The town the bot works an errand through (Part XVI): the town of the step's own region while anybody
## there is still to be done, else the nearest town of this realm with somebody left ("" if none).
func _folk_town(role: String) -> String:
	var s := Game.cur_step()
	if world.is_floor() or world.wd.is_empty():
		return ""
	var best := ""
	var bd := 1 << 30
	var homes: Array = Folk.TOWNS.keys()
	# (the High Roads release: an errand among the people of the road is run from camp to camp, the
	# camps of regions the journey has been through)
	if Folk.CAMP_ROLES.has(role):
		homes = []
		for ca in world.wd.get("camps", {}):
			if Game.seen.has(str(ca)):
				homes.append("camp_" + str(ca))
	for tid in homes:
		var ar: String = Folk.town(tid).area
		if Data.layer_of(ar) != world.layer:
			continue
		var left := 0
		for fp in Folk.people(world.wd, tid):
			if Folk.is_role(fp, role) and Folk.in_town(fp, s) and not Game.folk_has(s, str(fp.id)):
				left += 1
		if left == 0:
			continue
		var hc := Folk.heart(tid)
		var cost := absi(hc.x - world.ptile.x) + absi(hc.y - world.ptile.y) + (0 if ar == str(s.get("area", "")) else 100000)
		if cost < bd:
			bd = cost
			best = tid
	return best

## The child (or townsperson of kind `role`) of the town the errand is going through who is out of
## doors and standing still for a while yet, nearest the bot: {id, tile} or {}.
func _folk_target(role: String) -> Dictionary:
	var town := _folk_town(role)
	if town == "":
		return {}
	var best := {}
	var bd := 1 << 30
	for fp in Folk.people(world.wd, town):
		if not Folk.is_role(fp, role) or not Folk.in_town(fp, Game.cur_step()) or Game.folk_has(Game.cur_step(), str(fp.id)):
			continue
		var st := Folk.state(world.wd, fp, Game.clock)
		if not st.vis or st.walk or float(st.left) < 4.0:
			continue
		var tile := Vector2i(int(floor((st.at as Vector2).x)), int(floor((st.at as Vector2).y)))
		var dd := absi(tile.x - world.ptile.x) + absi(tile.y - world.ptile.y)
		if dd < bd:
			bd = dd
			best = {"id": str(fp.id), "tile": tile}
	return best

## A free tile at or near `p` to walk to.
func _near_free(p: Vector2i) -> Vector2i:
	for r in 8:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := p + Vector2i(dx, dy)
				if maxi(absi(dx), absi(dy)) == r and world.tile_free(q) and world.ent_at(q) == null:
					return q
	return p

## Renown the bot can still earn from deeds the story has reached.
func _deed_renown() -> int:
	var n := 0
	for did in Trials.DEEDS:
		var d: Dictionary = Trials.DEEDS[did]
		if not Game.deeds.has(did) and Game.reached(str(d.after)):
			n += int(d.renown)
	return n

## Do a deed for renown: the nearest one whose wants are in hand; failing that, hunt the essence the
## cheapest one still needs.
func _deed_step(tt: Dictionary) -> bool:
	var best := ""
	var bd := 1 << 30
	var short_ek := ""
	var short_n := 1 << 30
	for did in Trials.DEEDS:
		var d: Dictionary = Trials.DEEDS[did]
		if Game.deeds.has(did) or not Game.reached(str(d.after)):
			continue
		if Trials.deed_ready(did, Game):
			var dd := _deed_dist(d)
			if dd < bd:
				bd = dd
				best = did
		else:
			for k in d.want:
				var miss: int = int(d.want[k]) - int(Game.inv.get(k, 0))
				if miss > 0 and str(k).begins_with("ess_") and miss < short_n:
					short_n = miss
					short_ek = str(k)
	if best != "":
		_goto_entity(str(Trials.DEEDS[best].area), str(Trials.DEEDS[best].npc))
		return true
	if short_ek != "":
		return _farm(short_ek, tt)
	return false

## How far the bot is from doing deed `d`: in this realm, the walk; in another, a long way.
func _deed_dist(d: Dictionary) -> int:
	var e = world.find_ent(str(d.npc))
	if e != null:
		return absi(e.pos.x - world.ptile.x) + absi(e.pos.y - world.ptile.y)
	return 5000 + (0 if Data.layer_of(str(d.area)) == Data.layer_of(Game.area) else 5000)

## How many of `item` can still be picked up somewhere (keepsakes on the floors of buildings).
func _pickups_of(item: String) -> int:
	var n := 0
	for lid in ["surface", "heaven", "under", "sea"]:
		var lw: Dictionary = Atlas.world_of(lid)
		var groups: Array = [lw.ents]
		for fid in lw.floors:
			groups.append(lw.floors[fid].ents)
		for grp in groups:
			for e in grp:
				if e.kind == "pickup" and str(e.get("item", "")) == item and world.ent_visible(e):
					n += 1
	return n

## Go and pick up one `item`: the nearest that can be reached (this realm first), and once chosen,
## that one until it is in hand (an upper storey's tiles are its own: measured from the floor's tiles
## the nearest used to flip between two buildings, and the bot went up and down the stairs forever).
var fetch_id := ""

func _fetch(item: String) -> bool:
	var here: String = str(world.layer) if not world.is_floor() else str(world.wd.parent)
	var me: Vector2i = world.ptile + (Vector2i(world.wd.origin) if world.is_floor() else Vector2i.ZERO)
	var best = null
	var bd := 1 << 30
	for lid in ["surface", "heaven", "under", "sea"]:
		var lw: Dictionary = Atlas.world_of(lid)
		var groups: Array = [[lw.ents, Vector2i.ZERO]]
		for fid in lw.floors:
			groups.append([lw.floors[fid].ents, Vector2i(lw.floors[fid].origin)])
		for grp in groups:
			for e in grp[0]:
				if e.kind != "pickup" or str(e.get("item", "")) != item or not world.ent_visible(e):
					continue
				var at: Vector2i = e.pos + grp[1]
				var dd: int = absi(at.x - me.x) + absi(at.y - me.y) + (0 if lid == here else 10000)
				if str(e.id) == fetch_id:
					dd = -1
				if dd < bd:
					bd = dd
					best = e
	if best == null:
		fetch_id = ""
		return false
	fetch_id = str(best.id)
	_goto_entity(str(best.get("area", "")), str(best.id))
	return true

# ---------------------------------------------------------------- pathing
var astar: AStarGrid2D = null
var astars := {}

## The path grid of the realm (or floor) the hero is in, built once per realm.
func _astar() -> AStarGrid2D:
	if astars.has(world.layer):
		astar = astars[world.layer]
		return astar
	astar = AStarGrid2D.new()
	astars[world.layer] = astar
	astar.region = Rect2i(0, 0, world.w, world.h)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	for y in world.h:
		for x in world.w:
			if not MapGen.is_walkable_tile(world.grid[y * world.w + x]):
				astar.set_point_solid(Vector2i(x, y), true)
	# the High Roads release (peaks.gd): a crag is gone round unless the top of it is where he is going,
	# as anybody goes round one (a climbed tile costs what it costs in time)
	if not world.is_floor():
		for pk in world.wd.get("peaks", []):
			var pc: Vector2i = pk.c
			var pr: int = pk.r
			for py in range(pc.y - pr, pc.y + pr + 1):
				for px in range(pc.x - pr, pc.x + pr + 1):
					var pt := Vector2i(px, py)
					if astar.is_in_boundsv(pt) and not astar.is_point_solid(pt) and Peaks.rise_of(pk, float(px) + 0.5, float(py) + 0.5) > 0.25:
						astar.set_point_weight_scale(pt, 3.0)
	# the Living Land release: the things people leave about their towns (havoc.gd) are walked round,
	# not galloped through, as a player minding other people's jars would
	if not world.is_floor():
		for tid in Folk.TOWNS:
			var ar: String = Folk.TOWNS[tid].area
			if Data.layer_of(ar) == world.layer:
				for b in Havoc.of_area(world.wd, ar):
					if astar.is_in_boundsv(b.tile) and not astar.is_point_solid(b.tile):
						astar.set_point_weight_scale(b.tile, 12.0)
	return astar

## tiles an entity stands on (closed seals always; enemies only when avoiding fights)
func _blocked_list(avoid_enemies: bool, goal: Vector2i) -> Array:
	var out: Array = []
	for e in world.ents:
		# (a thing to do on a floor anyone walks over stands in nobody's way: props.gd)
		if e.kind == "spring" or e.get("walk", false) or not world.ent_visible(e):
			continue
		if e.kind == "seal":
			if not world.seal_open(e):
				out += e.tiles
			continue
		if e.pos == goal:
			continue
		if e.kind == "enemy" and not avoid_enemies:
			continue
		out.append(e.pos)
	return out

func _blocked_tile(n: Vector2i) -> bool:
	var e = world.tile_ents.get(n)
	if e == null or not world.ent_visible(e):
		return false
	return not (e.kind == "seal" and world.seal_open(e))

## breadth-first distances from `start`, up to `cap` steps
func _bfs_dist(start: Vector2i, cap: int = 64) -> Dictionary:
	var dist := {start: 0}
	var q: Array = [start]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		if dist[c] >= cap:
			continue
		for dd in DIRS:
			var n: Vector2i = c + dd
			if dist.has(n) or not world.tile_free(n) or _blocked_tile(n):
				continue
			dist[n] = dist[c] + 1
			q.append(n)
	return dist

func _bfs_path(start: Vector2i, goal: Vector2i, avoid_enemies: bool) -> Array:
	var a := _astar()
	if not a.is_in_boundsv(goal) or not a.is_in_boundsv(start):
		return []
	var blocked := _blocked_list(avoid_enemies, goal)
	var toggled: Array = []
	for b in blocked:
		if b != start and b != goal and not a.is_point_solid(b):
			a.set_point_solid(b, true)
			toggled.append(b)
	var goal_solid := a.is_point_solid(goal)
	if goal_solid:
		a.set_point_solid(goal, false)
	var out: Array = Array(a.get_id_path(start, goal))
	for b2 in toggled:
		a.set_point_solid(b2, false)
	if goal_solid:
		a.set_point_solid(goal, true)
	return out

func _walk_to(goal: Vector2i, key: String) -> void:
	var here: Vector2i = world.target if world.move_t >= 0.0 else world.ptile
	if key != path_key or path.is_empty() or not path.has(here):
		path = _bfs_path(here, goal, true)
		if path.is_empty():
			path = _bfs_path(here, goal, false)
		path_key = key
		if path.is_empty():
			world.move_dir = Vector2i.ZERO
			return
	var i := path.find(here)
	if i < 0 or i >= path.size() - 1:
		world.move_dir = Vector2i.ZERO
		path = []
		return
	world.move_dir = path[i + 1] - here
	cool = 0.0

# ---------------------------------------------------------------- menus
func _nav(labels_n: int, cursor: int, want: int) -> void:
	if want < 0:
		_press("cancel", 0.3)
		return
	if cursor == want:
		_press("confirm", 0.35)
	else:
		var fwd := (want - cursor + labels_n) % labels_n
		_press("down" if fwd <= labels_n / 2 else "up", 0.22)

## The work the bot would build now ("" for none): the first of its plan that can be built, when it
## has four times the price in hand or the story is asking for works (then any that can be built).
func _want_work() -> String:
	var asked: bool = str(Game.cur_step().get("kind", "")) == "works"
	var keep := _stones_ahead()
	for id in WORKS_PLAN:
		if Works.has(Game, id):
			continue
		# (four times its price in hand, and what the cauldron and the forge will ask for the trials of
		# the next chapter or so left over: a work bought with a trial's recipe money is paid for twice,
		# in an hour of fighting for spirit stones)
		if Works.can_build(Game, id) and (asked or (Game.stones >= Works.cost_stones(Game, id) * 4 and Game.stones - Works.cost_stones(Game, id) >= keep)):
			return id
		# (the next work of the plan that the land knows how to make is saved up for: know-how spent
		# on a cheaper one further down the list would never finish the wheel's school)
		if not asked and Works.known(Game, id) and (Works.before(id) == "" or Works.has(Game, Works.before(id))):
			return ""
		# (and a work of the wheel's school that the land does not yet know how to make is waited for: what
		# comes after it in the plan would spend what it will cost)
		if not asked and not Works.known(Game, id) and str(Works.WORKS[id].school) == "wheel":
			return ""
	return ""

## The spirit stones the recipes of the trials ahead will ask for: every recipe made for a trial not
## yet passed (that the bot means to take by craft) whose step is within fifty steps of the story.
func _stones_ahead() -> int:
	var n := 0
	for rid in Trials.RECIPES:
		var r: Dictionary = Trials.RECIPES[rid]
		if Game.trials.has(str(r.get("for", ""))) or int(Game.inv.get(rid, 0)) > 0:
			continue
		var at := Data.step_index(str(r.after))
		if at >= Game.step - 12 and at <= Game.step + 50 and str(TRIAL_PLAN.get(str(r.get("for", "")), "")) == "craft":
			n += Trials.recipe_stones(rid, Game)
	return n

func _menu() -> void:
	var m = main.menu
	if menu_goal == "":
		_press("cancel", 0.3)
		return
	if menu_goal == "body":
		# The Body: the line somebody careful would choose, then out
		var adv := Needs.advice(Game, main.body_ctx())
		if m.mode == "body":
			if adv == "":
				menu_goal = ""
				_press("cancel", 0.3)
			else:
				_nav(m.labels.size(), m.cursor, m.ids.find("body:" + adv))
			return
		if m.mode == "root" and adv != "":
			_nav(m.labels.size(), m.cursor, m.ids.find("body"))
			return
		menu_goal = ""
		_press("cancel", 0.3)
		return
	if menu_goal == "works":
		# the Works page: down to the work wanted and Enter builds it; out again when there is no more
		var ww := _want_work()
		if m.mode == "works":
			if ww == "":
				menu_goal = ""
				_press("cancel", 0.3)
			else:
				_nav(m.labels.size(), m.cursor, m.ids.find("work:" + ww))
			return
		if m.mode == "root" and ww != "":
			_nav(m.labels.size(), m.cursor, m.ids.find("works"))
			return
		menu_goal = ""
		_press("cancel", 0.3)
		return
	if m.mode != "root":
		_press("cancel", 0.3)
		return
	var want: int = m.ids.find(menu_goal)
	if want < 0 or not m.enabled[want]:
		menu_goal = ""
		_press("cancel", 0.3)
		return
	if m.cursor == want:
		menu_goal = ""
	_nav(m.labels.size(), m.cursor, want)

func _shop() -> void:
	var s = main.shop
	var want := "leave"
	# many roads: what the trial ahead needs made at this station
	var tt := _trial_target()
	if not tt.is_empty():
		for n in Trials.path(tt.tid, str(tt.pid)).needs:
			var rid: String = ("craft:" + str(n[1])) if n.size() > 2 else ""
			var k: int = s.ids.find(rid)
			if rid != "" and k >= 0 and s.enabled[k] and int(Game.inv.get(str(n[1]), 0)) < int(n[2]):
				_nav(s.labels.size(), s.cursor, k)
				return
	if s.kind == "smith":
		if s.ids.has("temper") and s.enabled[s.ids.find("temper")]:
			want = "temper"
	else:
		var hp_price := Works.pill_price(Game, "hp_pill", Game.level)
		var qi_price := Works.pill_price(Game, "qi_pill", Game.level)
		if Game.inv.get("hp_pill", 0) < 8 and Game.stones >= hp_price:
			want = "hp_pill"
		elif Game.inv.get("qi_pill", 0) < 4 and Game.stones >= qi_price:
			want = "qi_pill"
	_nav(s.labels.size(), s.cursor, s.ids.find(want))

func _meditate() -> void:
	var done := false
	match med_goal:
		"rest":
			done = _hp_ratio() > 0.97 and _qi_ratio() > 0.9
		"grind":
			# back to the fight as soon as the party is fit and a pack has come back
			done = (_cult_met() and _hp_ratio() > 0.6) or (Game.area != "sect" and Game.area != Atlas.HUB and _hp_ratio() > 0.9 and _qi_ratio() > 0.6 and _any_enemy(Game.area, true) != null)
		"respawn":
			done = _any_enemy(Game.cur_step().get("area", ""), false, Game.cur_step().get("of", [])) != null
		"respawn_any":
			# waiting for packs to come back to fight (essences, spirit stones for a trial)
			done = _any_enemy(Game.area, true) != null
		"children":
			# Part XVI: waiting for the children of the towns to come out of doors (folk.gd)
			done = not _folk_target(str(Game.cur_step().get("role", "child"))).is_empty() or Game.cur_step().get("kind", "") != "folk"
	if done:
		_press("cancel", 0.4)
	else:
		cool = 0.4

# ---------------------------------------------------------------- battle
func _battle() -> void:
	var b = main.battle
	match b.state:
		"intro", "acting":
			cool = 0.2
		"result":
			if not result_wait:
				result_wait = true
				cool = 1.6
			else:
				result_wait = false
				_press("confirm", 0.5)
		"menu":
			_battle_menu(b)

func _battle_menu(b) -> void:
	var plan := _plan(b)
	var want := -1
	match b.menu_kind:
		"main":
			want = b.ids.find(plan.top)
		"skills":
			want = b.ids.find(plan.get("skill", ""))
		"items":
			want = b.ids.find(plan.get("item", ""))
		"target":
			for i in b.targets.size():
				if is_same(b.targets[i], plan.target):
					want = i
	if want < 0 or (b.menu_kind != "target" and not b.enabled[want]):
		_press("cancel", 0.3)
		return
	_nav(b.labels.size(), b.cursor, want)

func _plan(b) -> Dictionary:
	var me: Dictionary = b.cur
	if b.doomed and give_way:
		return {"top": "yield"}
	var allies: Array = b.alive(b.party)
	var foes: Array = b.alive(b.foes)
	var low: Dictionary = allies[0]
	for a in allies:
		if a.hp / a.maxhp < low.hp / low.maxhp:
			low = a
	var low_r: float = low.hp / low.maxhp
	# healing
	# strongest heal Yue Ling knows (Seal Bloom and Nuwa's Mending used to be skipped)
	var heal_id := "rain"
	for hid in HEALS:
		if me.skills.has(hid):
			heal_id = hid
			break
	var heal_cost: float = Game.skill_cost(heal_id)
	# an ally has fallen: raise them if a reviving heal is known
	if allies.size() < b.party.size() and me.skills.has(heal_id) and me.qi >= heal_cost and Data.SKILLS[heal_id].get("revive", false):
		return {"top": "skills", "skill": heal_id}
	if me.skills.has(heal_id) and me.qi >= heal_cost and low_r < 0.55:
		return {"top": "skills", "skill": heal_id}
	if low_r < 0.3 and Game.inv.get("hp_pill", 0) > 0 and not (me.skills.has(heal_id) and me.qi >= heal_cost):
		return {"top": "items", "item": "hp_pill", "target": low}
	if me.idx == 0 and me.qi < 12 and Game.inv.get("qi_pill", 0) > 0 and b.ctx.get("boss", false):
		return {"top": "items", "item": "qi_pill", "target": me}
	# offense
	var best_score := 0.0
	var best: Dictionary = {"top": "attack", "target": _weakest(foes, "phys")}
	if me.idx == 1:
		best = {"top": "attack", "target": _weakest(foes, "wood")}
	best_score = 1.0
	for sid in me.skills:
		var sk: Dictionary = Game.skill_of(sid)
		if sk.has("heal") or me.qi < Game.skill_cost(sid) or sk.cost == 0:
			continue
		var tgt: Dictionary = _weakest(foes, sk.elem)
		var score: float = sk.mult * (1.5 if tgt.weak == sk.elem else 1.0)
		if sk.tgt == "all":
			var tot := 0.0
			for f in foes:
				tot += sk.mult * (1.5 if f.weak == sk.elem else 1.0)
			score = tot
		# don't burn the biggest techniques on trash when few enemies remain
		if not b.ctx.get("boss", false) and foes.size() == 1 and tgt.hp < me.atk * 1.2:
			continue
		if score > best_score:
			best_score = score
			best = {"top": "skills", "skill": sid, "target": tgt}
	return best

func _weakest(foes: Array, elem: String) -> Dictionary:
	var best: Dictionary = foes[0]
	for f in foes:
		var fw: bool = f.weak == elem
		var bw: bool = best.weak == elem
		if fw and not bw:
			best = f
		elif fw == bw and f.hp < best.hp:
			best = f
	return best

# ---------------------------------------------------------------- screenshots
func _shots(top: String, d: float) -> void:
	if shots_dir == "":
		return
	match top:
		"title":
			_shot("01_title")
		"dialogue":
			if Game.step == 0 and main.dialogue.idx == 1 and main.dialogue.typed_done():
				_shot("02_dialogue")
		"world":
			if dwell > 2.5 and Game.step > 0:
				_shot("world_" + Game.area)
		"meditate":
			if med_goal != "" and main.meditate.t > 4.0:
				_shot("meditate")
		"menu":
			if Game.level >= 2:
				_shot("menu")
		"shop":
			_shot("shop")
		"battle":
			var b = main.battle
			if b.state == "menu" and b.menu_kind == "main":
				if b.ctx.get("tribulation", false):
					_shot("battle_tribulation")
				elif b.ctx.get("boss", false):
					_shot("battle_boss_" + b.ctx.enemy)
				elif b.foes.size() >= 2:
					_shot("battle_" + Game.area)

func _shot(n: String) -> void:
	if shots_dir == "" or shots_taken.has(n):
		return
	shots_taken[n] = true
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_webp("%s/%s.webp" % [shots_dir, n], true, 0.9)

# ---------------------------------------------------------------- report
func _finish(reason: String) -> void:
	if finished:
		return
	finished = true
	var wall := (Time.get_ticks_msec() - wall_start) / 1000.0
	var ok := Game.finished and Game.playtime >= min_time and reason == ""
	var breakdown := {}
	for k in time_by_screen:
		breakdown[k] = snappedf(time_by_screen[k], 0.1)
	var areas := {}
	for k in time_by_area:
		areas[k] = snappedf(time_by_area[k], 0.1)
	var rep := {
		"completed": Game.finished,
		"passed": ok,
		"failure_reason": reason,
		"game_time_seconds": snappedf(Game.playtime, 0.1),
		"game_time": Fmt.clock(Game.playtime),
		"wall_clock_seconds": snappedf(wall, 0.1),
		"final_realm": Data.level_name(Game.level),
		"battles": Game.battles,
		"foes_defeated": Game.kills,
		"deaths": Game.deaths,
		"spirit_stones": Game.stones,
		"sword_tempering": Game.temper,
		"renown": Game.renown,
		"deeds": Game.deeds.size(),
		# the Spring Thunder release (impact.gd): the sword in the open world
		"strikes": Game.strikes, "first_strikes": Game.ambushes, "sword_qi": Game.waves, "cleared": Game.cleared.size(),
		# the New Fire release (cultures.gd): who the hero was, the hearths and the end chosen
		"hero": {"body": str(Game.hero.get("body", "m")), "hearth": Cultures.own(Game), "look": str(Game.hero.get("look", "")), "origin": str(Game.hero.get("origin", ""))},
		"hearths": Game.hearth, "guest_of": Cultures.guests(Game), "ending": Cultures.ending_of(Game),
		# the Hundred Works release: what was built (works.gd), what was answered at the crossroads and how
		# the scales stand (echoes.gd)
		"works": Game.works.keys(), "works_by_school": {"hand": Works.count(Game, "hand"), "wheel": Works.count(Game, "wheel"), "dao": Works.count(Game, "dao")},
		"know_how": {"earned": Works.know_earned(Game), "spent": Works.know_spent(Game)}, "maker": Works.title(Game),
		"crossroads": Game.picks, "scales": {"heart": Echoes.scale(Game, "heart"), "craft": Echoes.scale(Game, "craft"), "reach": Echoes.scale(Game, "reach")},
		"known_as": Echoes.names(Game), "echoes_heard": Game.echoed.size(),
		# the Hundred Arms release: the weapons owned, the one in hand, the Daos of arms and their mastery
		"arms": Game.arms.keys(), "arm": Arms.held(Game), "arm_xp": Game.arm_xp, "arms_adept": Arms.adept(Game), "arms_master": Arms.masters(Game),
		"arm_switches": Game.arm_switches, "ending_kind": Cultures.ending_kind(Game),
		# the Hollow Hills release: the caves gone to the very back of (caves.gd)
		"caves_delved": Game.delved.keys(),
		# the High Roads release: the summits stood on, the rock climbed and the flights under the cloud-kite (peaks.gd)
		"summits": Game.summits.keys(), "metres_climbed": snappedf(Game.climbed, 0.1), "flights": Game.glides, "metres_flown": Game.glided * 2,
		"longest_flight_metres": Game.glide_best * 2, "greatest_descent_metres": snappedf(Game.glide_drop, 0.1),
		"trials": Game.trials,
		"gates": Game.gates_open.keys(),
		"time_by_screen_seconds": breakdown,
		"time_by_area_seconds": areas,
		"meditation_by_purpose_seconds": time_by_med,
		"timeline": Game.timeline,
		"feats": Game.feats.keys(), "feat_points": Feats.points(Game), "finds": Game.eggs.keys(), "companies": War.companies(Game), "fields_held": Game.war_won, "fields_lost": Game.war_lost,
		"tunes_heard": Game.heard.keys(), "airs": Game.airs.keys(), "commissions": Jobs.done_count(Game), "outfits": Game.outfits.keys(), "yue_outfits": Game.yue_outfits.keys(),
	}
	var dir := report_path.get_base_dir()
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir if dir.is_absolute_path() else ProjectSettings.globalize_path("res://" + dir))
	var path_abs := report_path if report_path.is_absolute_path() else ProjectSettings.globalize_path("res://" + report_path)
	var f := FileAccess.open(path_abs, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(rep, "  "))
		f.close()
	print("")
	print("================ BOT REPORT ================")
	print("completed       : %s" % Game.finished)
	print("game play time  : %s (%.0f s)" % [Fmt.clock(Game.playtime), Game.playtime])
	print("wall clock      : %.1f s" % wall)
	print("final realm     : %s" % Data.level_name(Game.level))
	print("battles / kills : %d / %d   deaths: %d" % [Game.battles, Game.kills, Game.deaths])
	print("time by screen  : %s" % JSON.stringify(breakdown))
	print("time by area    : %s" % JSON.stringify(areas))
	print("meditation for  : %s" % JSON.stringify(time_by_med))
	print("trials passed   : %d   renown: %d   deeds: %d   gates: %d" % [Game.trials.size(), Game.renown, Game.deeds.size(), Game.gates_open.size()])
	print("paths taken     : %s" % JSON.stringify(Game.trials))
	print("the sword       : %d strikes, %d packs struck first, %d sword qi, %d obstacles cleared" % [Game.strikes, Game.ambushes, Game.waves, Game.cleared.size()])
	print("works           : %d built (hand %d, wheel %d, art %d): %s; know-how %d earned, %d spent" % [Works.count(Game), Works.count(Game, "hand"), Works.count(Game, "wheel"), Works.count(Game, "dao"), Works.title(Game),
		Works.know_earned(Game), Works.know_spent(Game)])
	print("the dark        : %d caves gone to the very back of" % Game.delved.size())
	print("the heights     : %d summits stood on, %.0f m of rock climbed, %d flights under the cloud-kite (%d m flown, the longest %d m)" % [Game.summits.size(), Game.climbed, Game.glides, Game.glided * 2, Game.glide_best * 2])
	var arm_parts: Array = []
	for aid in Arms.ORDER:
		if Game.arms.has(aid):
			arm_parts.append("%s %s (%d)" % [aid, Data.DAO_RANKS[Arms.tier(Game, aid)], int(Game.arm_xp.get(aid, 0))])
	print("the eight arms  : %d owned, %d Daos of arms at Adept, %d mastered, in hand %s" % [Game.arms.size(), Arms.adept(Game), Arms.masters(Game), Arms.held(Game)])
	print("                  " + ", ".join(arm_parts))
	print("crossroads      : %d answered, %d echoes heard; mercy %+d, new works %+d, wide world %+d%s" % [Game.picks.size(), Game.echoed.size(), Echoes.scale(Game, "heart"), Echoes.scale(Game, "craft"), Echoes.scale(Game, "reach"),
		(": " + Echoes.names(Game)) if Echoes.names(Game) != "" else ""])
	var m := War.muster(Game)
	print("the host        : %d companies (foot %d, bows %d, horse %d, drums %d); fields held %d of %d %s, driven off %d" % [War.companies(Game).size(), int(m.foot), int(m.bow), int(m.horse), int(m.drum),
		Game.war_won.size(), War.BATTLE_ORDER.size(), JSON.stringify(Game.war_won), Game.war_lost])
	print("the song        : %d of %d tunes heard, %d airs of the hearths learned" % [Game.heard.size(), Music.count(), Game.airs.size()])
	print("the board       : %d of %d commissions done" % [Jobs.done_count(Game), Jobs.ORDER.size()])
	print("the mat         : %s" % Gamble.summary(Game))
	print("the body        : survival %s%s" % ["on" if Game.survival else "off", (": " + Needs.state(Game) + "; gave way " + JSON.stringify(Game.needs_fell)) if Game.survival else ""])
	print("the two of them : %s" % Romance.summary(Game))
	print("the wardrobe    : %d of %d outfits (wearing the %s), %d of %d dresses for Yue Ling (wearing %s)" % [Game.outfits.size(), Fashion.OUTFIT_ORDER.size(), str(Fashion.OUTFITS[Game.outfit].n),
		Game.yue_outfits.size(), Fashion.YUE_ORDER.size(), str(Fashion.YUE_OUTFITS[Game.yue_outfit].n)])
	print("feats           : %d of %d (%d of %d points): %s; found unasked: %d of %d %s" % [Game.feats.size(), Feats.FEATS.size(), Feats.points(Game), Feats.total(), Feats.title(Game), Game.eggs.size(), Eggs.ORDER.size(),
		JSON.stringify(Game.eggs.keys())])
	print("the hero        : %s, a young %s, kin %s; guest of %d hearths %s" % [Game.hero_name(), "woman" if Game.fem() else "man", str(Cultures.HEARTHS[Cultures.own(Game)].short), Cultures.guests(Game), JSON.stringify(Game.hearth)])
	# (the Lost Horse release: dooms.gd, marks.gd)
	var how_n := {}
	for fid in Game.falls:
		how_n[str(Game.falls[fid].how)] = int(how_n.get(str(Game.falls[fid].how), 0)) + 1
	print("what was lost   : %d battles that could not be won (%d given way to), %d of 3 dooms of the story stood in front of %s" % [Game.fallen, Game.yielded, int(Feats.value(Game, ["dooms", 3])), str(how_n)])
	var stood := 0
	for lid9 in ["surface", "heaven", "under", "sea"]:
		stood += Marks.standing(Game, Atlas.world_of(lid9).ents)
	print("the reckoning   : %s" % (", ".join(Game.reckoned.keys().map(func(id): return str(Data.ENEMIES[id].n))) if not Game.reckoned.is_empty() else "nobody met"))
	print("trades          : %d shifts at %d trades, %d spirit stones in wages%s" % [int(Offices.worked(Game)[0]), int(Offices.worked(Game)[1]), Game.wages, (": " + Offices.careers(Game)) if Offices.careers(Game) != "" else ""])
	print("what stands     : %d things stand in the land for what was chosen and what the scales lean to (the answers of all the crossroads would stand %d between them), %d looked at" % [stood, int(Marks.totals()[1]), Game.marks_seen.size()])
	print("the ending      : %s" % str(Cultures.ENDINGS[Cultures.ending_of(Game)].n))
	if reason != "":
		print("FAILED          : %s" % reason)
	print("result          : %s (needs >= %.0f s)" % ["PASS" if ok else "FAIL", min_time])
	print("============================================")
	get_tree().quit(0 if ok else 1)
