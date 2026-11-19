class_name Sects
extends RefCounted
## The sects of the Rivers and Lakes (the Rivers and Lakes release).
##
## Until now there was one sect in the world, his own.  Down the river there are four more, and each
## **answers for a town** (sides.gd: what a town is, its sect is), keeps **a way of its own** and has
## **work of its own** to give:
##
##   * the **Listening Reeds** of Reedhaven in Yunmeng: boat people, who give every child a flute
##     before a name and feed every stranger before asking who he is.  Upright.  They pay as written,
##     and whoever reports to them is fed: health and qi are mended.
##   * the **Cold Mountain Hermitage** above Clearbell: hermits with no master but the man who sweeps
##     the kitchen, who write poems on rocks and walk away.  Upright.  They have no spirit stones and
##     pay in understanding (cultivation), and in renown.
##   * the **Black Water Gate** of Ashmarket: keepers of the one ledger every debt of the Rivers and
##     Lakes is written in.  Crooked.  They pay double, and some of their work is foul (`"foul": true`:
##     a wrong done in the street; it is said which, and nothing ever asks for it).
##   * the **Wolf Banner** of Knifegate in the Wolf-Tooth Pass: the strongest takes first.  Crooked.
##     They pay by what he is: more for every great realm he stands in, and no renown, for nobody
##     there says thank you.
##
## and his own, the **Azure Cloud Sect**, which is listed with them (`SECTS.azure`) and has no hall of
## tasks: what it wants of him is the story.
##
## **Tasks** (`TASKS`, four a sect, asked for at the counter of whoever keeps its hall: offices.gd)
## are taken, done out in the land and reported, like the notices of Qingshi (jobs.gd), and need one
## thing (`need`):
##   ["kills", [ids], n]   so many of these put down, counted from when it was taken
##   ["raids", n]          so many raids on the roads broken since it was taken (raids.gd)
##   ["more", what, n]     so many more of something than when it was taken (Feats.value)
##   ["reach", what, n]    be somebody who has done so much of it
##   ["have", {item: n}]   bring them (they are handed over)
##   ["folk", role, n]     speak with so many of one kind of the people of the towns
## Nothing keeps state but `Game.sect_q` (task -> "taken" or "done") and `Game.sect_base`.
##
## **Standing** (`rep`, `rank`) is what the tasks done for a sect and the steps of the story done in
## its name (a step with `"sect": id`) come to: four ranks, each with a name of the sect's own.  A
## guest of a sect (rank 1) pays a little less at its town's counters for every rank, is not robbed in
## a crooked town, and at the fourth rank is given the sect's token (a keepsake: it weighs nothing).
##
## A step of kind `"sect"` asks that so many tasks be done for one sect (`sect`, `n`: never a task by
## name, and never more than the two of each sect that are neither foul nor a matter of taste: the
## tests check that the first two of every sect are a hunt and a road kept).  The bot takes them in
## order (`Sects.next`) and does them as it does a hunt or a rescue.

const SECTS := {
	"azure": {"n": "The Azure Cloud Sect", "short": "Azure Cloud", "town": "sect", "area": "sect", "office": "", "master": "elder", "side": "upright", "col": Color("5aa0d8"),
		"creed": ["Sweep the step you are standing on.", "The mountain keeps what is left on it.", "Nobody is sent down who asked to stay."],
		"custom": "Nine hundred and ninety-nine steps, swept every morning by whoever is newest. Nobody remembers a rule about it; nobody has ever not done it.",
		"ranks": ["a sweeper of steps", "a disciple of the outer court", "a disciple of the inner court", "the mountain's own"]},
	"reed": {"n": "The Listening Reeds", "short": "the Reeds", "town": "reedhaven", "area": "yunmeng", "office": "hall_reed", "master": "lu_ting", "side": "upright", "col": Color("7ab86a"),
		"creed": ["Feed him first. Ask after.", "A flute before a name.", "Forty boats out, forty boats home."],
		"custom": "Every child of the fleet is given a reed flute before it is given a name, and is called by the tune it first plays. A stranger is fed at the landing before anybody asks who he is: whoever reports a task here is given a bowl, and is mended.",
		"pay": "A bowl at the landing: health and qi mended when a task is reported.",
		"ranks": ["a stranger on the landing", "a guest of the fleet", "an oar of the fleet", "kin of the Reeds"]},
	"cold": {"n": "The Cold Mountain Hermitage", "short": "the Hermitage", "town": "clearbell", "area": "hanshan", "office": "hall_cold", "master": "shide", "side": "upright", "col": Color("a8b8d0"),
		"creed": ["Write it on a rock and walk away.", "Whoever sweeps the kitchen is the abbot.", "No road goes through. Come anyway."],
		"custom": "The hermits own nothing, so they pay nothing: there is not a spirit stone on the mountain. A thing done for it is paid in what was understood on the way, and in what is said of him afterwards.",
		"pay": "No spirit stones: cultivation, and renown.",
		"ranks": ["somebody who asked the way", "a guest of the kitchen", "a copyist of the rocks", "a friend of Cold Mountain"]},
	"black": {"n": "The Black Water Gate", "short": "the Gate", "town": "ashmarket", "area": "heishui", "office": "hall_black", "master": "mo_chou", "side": "crooked", "col": Color("8a3a4a"),
		"creed": ["A debt is the only promise ever kept.", "No names. A thumbprint will do.", "Everything is for sale. Say so, and it is honest."],
		"custom": "Every debt of the Rivers and Lakes is written in one ledger, and the Gate collects. It pays twice what anybody else would and writes that down too. Some of its work is foul, and the counting-master says which before the brush is wet.",
		"pay": "Double the spirit stones. Some tasks are foul, and are marked.",
		"ranks": ["a line not yet written", "a name in the ledger", "a hand of the Gate", "a partner in the book"]},
	"wolf": {"n": "The Wolf Banner", "short": "the Banner", "town": "knifegate", "area": "langya", "office": "hall_wolf", "master": "tuoba_lie", "side": "crooked", "col": Color("c85a3a"),
		"creed": ["The strongest takes first.", "Say it to his face.", "Nobody robs this road but us."],
		"custom": "Travellers are priced at the toll-rope, by weight, bearing and the look in the eye. The Banner pays the strong more than the weak for the same work, at once, and nobody says thank you: thanks are for people who were not sure.",
		"pay": "More spirit stones for every great realm he stands in. No renown.",
		"ranks": ["priced at the rope", "let through the gate", "a rider of the Banner", "a jaw of the Wolf"]},
}
const ORDER := ["azure", "reed", "cold", "black", "wolf"]
## standing a task done is worth, standing a step of the story done in a sect's name is worth, and what each rank asks
const REP_TASK := 2
const REP_STEP := 1
const RANK_AT := [0, 2, 5, 8]
## what a guest pays less at the counters of the sect's town, for each rank
const RANK_PRICE := 0.03
const ASK := "The hall of tasks: what will you take?"

const TASKS := {
	# ---- the Listening Reeds
	"reed_banks": {"sect": "reed", "n": "Reavers on the Banks", "need": ["kills", ["reed_reaver", "gasping_carp", "spit_wisp"], 10], "stones": 9000, "renown": 3,
		"ask": "The marsh is low this year and everything that lived in it is up on the banks, with the reavers behind. Ten of them, any ten, put down between here and the eastern reeds.",
		"thanks": "Ten. The night boats went out without a lantern man in the bow. Sit; there is a bowl coming, and do not tell me you have eaten."},
	"reed_home": {"sect": "reed", "n": "Forty Out, Forty Home", "need": ["raids", 2], "stones": 10000, "renown": 4,
		"ask": "They come down on the carts and on the people of the road now, not only on us. Break two of those raids, wherever on the roads of the Rivers and Lakes you find one. We count people home here. We should like to go on counting.",
		"thanks": "Two carts came in this morning that would not have. The carters asked your name. I said you would have eaten first, and told them that."},
	"reed_pot": {"sect": "reed", "n": "Fish for the Landing Pot", "need": ["have", {"carp": 5}], "stones": 7000, "renown": 2,
		"ask": "The pot at the landing feeds whoever steps off the boat, and it is down to broth. Five carp, caught with your own hands; a bought fish knows it was bought.",
		"thanks": "Five, and still bright in the eye. The pot will see the week out. You have fed forty strangers and will meet none of them, which is the right way round."},
	"reed_pipers": {"sect": "reed", "n": "Hear the Pipers Out", "need": ["folk", "musician", 3], "stones": 6000, "renown": 3,
		"ask": "Three of our pipers have a new tune each and nobody to play it at: the fleet has heard everything. Go and stand in front of three of them and listen to the end. That is the task.",
		"thanks": "They say you did not look away once. One of them has named the tune after you, which is how people here get their names. You may not like it."},
	# ---- the Cold Mountain Hermitage
	"cold_cliff": {"sect": "cold", "n": "What Laughs in the Pines", "need": ["kills", ["cliff_gibbon", "pine_laughter", "uncopied_poem"], 10], "stones": 0, "exp": 0.05, "renown": 6,
		"ask": "The poems nobody copied have come loose from their rocks and the gibbons have learned to laugh like him. The woodmen will not go up. Ten of them quieted. I cannot pay you. I can tell you that.",
		"thanks": "It is quiet. It was not, and now it is, and you were between. That is all a poem is. Go and sit down; something will have come clear by supper."},
	"cold_path": {"sect": "cold", "n": "The Woodmen's Path", "need": ["raids", 2], "stones": 0, "exp": 0.06, "renown": 6,
		"ask": "The mountain feeds whoever climbs it, and the wood for the pot comes up on men's backs. They are being set on at the turns. Break two such raids, anywhere on the roads. The kitchen will know.",
		"thanks": "The wood came up. Shide swept towards the door all morning, which is the nearest he comes to saying a name. You are paid, though you will not find it in your purse."},
	"cold_top": {"sect": "cold", "n": "Where No Road Goes Through", "need": ["more", "summits", 1], "stones": 0, "exp": 0.04, "renown": 5,
		"ask": "\"People ask the way to Cold Mountain.\" Stand on the top of a height you have not stood on, any height in any country, and come and tell me whether there was a road.",
		"thanks": "No road. No. And yet you were there, and came back by one. Write that on something and leave it where it will not be found."},
	"cold_wood": {"sect": "cold", "n": "Wood for the Gruel", "need": ["have", {"timber": 2}], "stones": 0, "exp": 0.04, "renown": 4,
		"ask": "Two logs for the kitchen fire, felled by you. We do not buy wood; a log that was paid for burns sullen. The tiger likes the gruel warm.",
		"thanks": "Dry, and split along the grain. The tiger has moved closer to the stove, and thinks it is its own idea."},
	# ---- the Black Water Gate
	"black_leech": {"sect": "black", "n": "Leeches in the Counting-Water", "need": ["kills", ["blackwater_leech", "owed_ledger", "gate_collector"], 10], "stones": 9500, "renown": 2,
		"ask": "The water is full of leeches, a ledger has got loose that owes more than it holds, and three of our collectors have begun collecting on their own account. Ten of the lot. Clean work; I say so, and it is written.",
		"thanks": "Ten. The sum is twice what the reed-pipers would have paid you, and I want you to notice that. There. It is in the book, on the side that pleases you."},
	"black_carts": {"sect": "black", "n": "The Gate's Own Carts", "need": ["raids", 2], "stones": 10500, "renown": 2,
		"ask": "Somebody is raiding on our roads without having bought the right to. Break two raids, anywhere in the Rivers and Lakes. Whose carts they were raiding I do not ask. Clean work.",
		"thanks": "Two. The carters do not know who to thank, and the Gate prefers it so. Count it. I shall not be offended; I should think less of you if you did not."},
	"black_jar": {"sect": "black", "n": "Something for the Black Jar", "need": ["have", {"ess_dark": 3}], "stones": 8000, "renown": 1,
		"ask": "Apothecary She wants three Dark Essences and does not say for what, and I have not asked, which is how I am able to tell you that it is clean work as far as I know.",
		"thanks": "Three. She says to tell you it is for rats. She says it of everything. Here is the sum; it is fair, and it is double."},
	"black_call": {"sect": "black", "n": "A Debt Called In", "foul": true, "need": ["more", "deeds_bad", 1], "stones": 12000, "renown": 0,
		"ask": "This one is foul; I tell you before the brush is wet. Somebody in some street owes, or will be made to think so. Do one wrong thing to one person, anywhere, and come and tell me. You may leave it on the wall. Most do.",
		"thanks": "It is written. I do not ask who. You will find the sum is large, and that it does not feel like much. That is the ledger working as it should."},
	# ---- the Wolf Banner
	"wolf_strays": {"sect": "wolf", "n": "Strays of the Banner", "need": ["kills", ["banner_wolf", "pass_raider", "tooth_golem"], 10], "stones": 8000, "realm_pay": 80, "renown": 0,
		"ask": "Wolves that slipped the kennel, riders who left the Banner and took its name with them, and the rock itself has got teeth. Ten. You look as if you could. I have been wrong before, and buried them.",
		"thanks": "Ten. Hm. Paid. No, there is nothing else. Did you want me to say something? Sit down, then. That is what we say."},
	"wolf_road": {"sect": "wolf", "n": "Nobody Robs This Road but Us", "need": ["raids", 2], "stones": 9000, "realm_pay": 80, "renown": 0,
		"ask": "There are raids in the pass that are not ours, on carts that had paid the toll. A toll that does not buy safe passage is only theft, and we are not thieves. Break two raids, on any road down here.",
		"thanks": "Two. The carters paid the toll again on the way back and did not argue. That is what your work bought. The Banner-Lord nodded. I should frame it."},
	"wolf_arms": {"sect": "wolf", "n": "Three Ways to Say It", "need": ["reach", "arms", 3], "stones": 7000, "realm_pay": 60, "renown": 0,
		"ask": "The riders respect a hand that knows more than one weapon. Be somebody who has learned the Dao of three, and show the pit. Nobody will clap. Several will stop sneering.",
		"thanks": "Three. The pit went quiet at the second and stayed quiet. You will be let alone in the long house now. It is the nearest thing we have to a welcome."},
	"wolf_tribute": {"sect": "wolf", "n": "The Weak Pay", "foul": true, "need": ["more", "deeds_bad", 1], "stones": 11000, "realm_pay": 80, "renown": 0,
		"ask": "This one is foul and I will say so, since we say things to faces here. Take from somebody weaker, anywhere, because you can. It is how the pass has always been held. You may refuse. The Banner-Lord would.",
		"thanks": "Done, then. Paid. I shall tell you something for nothing: the Banner-Lord has never taken that one off the wall himself. Think what you like of that."},
}
const TASK_ORDER := ["reed_banks", "reed_home", "reed_pot", "reed_pipers", "cold_cliff", "cold_path", "cold_top", "cold_wood",
	"black_leech", "black_carts", "black_jar", "black_call", "wolf_strays", "wolf_road", "wolf_arms", "wolf_tribute"]
## what is said at the counter of a hall, by how he stands with the sect
const GREET := {
	"reed": ["You have eaten? Good. Then here is what the fleet wants done.", "The landing knows your step now. Here is what wants doing.", "An oar of ours. Sit, you need not stand at this counter.", "Kin. Take what you like off the wall, or nothing, and stay to supper."],
	"cold": ["Nobody sent you. Good. Those are the ones who stay.", "The kitchen has a bowl with a chip in it that is yours now.", "You read the rocks. Read the wall, then.", "A friend of the mountain does not need to be asked. But here is the wall."],
	"black": ["No name. Good. Here is the wall; the prices are fair.", "You are in the book. A small line. It can grow.", "A hand of the Gate reads the wall before the others see it.", "Partner. Your credit here is whatever you say it is."],
	"wolf": ["You were priced high. Here is the wall. Prove the price.", "The gate knows you. That is not nothing, here.", "A rider. Take what you want from the wall; nobody will argue.", "A jaw of the Wolf. The wall is yours. So is the first cut."],
}
## the keepsake a sect gives at its fourth rank
const TOKENS := {"reed": "token_reed", "cold": "token_cold", "black": "token_black", "wolf": "token_wolf"}

static func of_town(tid: String) -> String:
	for id in ORDER:
		if str(SECTS[id].town) == tid:
			return str(id)
	return ""

static func of_office(office: String) -> String:
	if office == "":
		return ""
	for id in ORDER:
		if str(SECTS[id].office) == office:
			return str(id)
	return ""

static func of_area(area: String) -> String:
	for id in ORDER:
		if str(SECTS[id].area) == area:
			return str(id)
	return ""

## The tasks of sect `id`, in the order they hang on the wall.
static func tasks_of(id: String) -> Array:
	var out: Array = []
	for t in TASK_ORDER:
		if str(TASKS[t].sect) == id:
			out.append(t)
	return out

static func state(g, t: String) -> String:
	return str(g.sect_q.get(t, ""))

static func is_done(g, t: String) -> bool:
	return state(g, t) == "done"

## How many tasks have been done for sect `id` ("" for all of them).
static func done_count(g, id: String = "") -> int:
	var n := 0
	for t in g.sect_q:
		if str(g.sect_q[t]) == "done" and (id == "" or str(TASKS[t].sect) == id):
			n += 1
	return n

## How he stands with sect `id`: the tasks done for it and the steps of the story done in its name.
static func rep(g, id: String) -> int:
	if id == "" or not SECTS.has(id):
		return 0
	if id == "azure":
		# (his own: the mountain has known him since he swept its steps)
		return RANK_AT[mini(int(g.realm()) / 3, RANK_AT.size() - 1)]
	var n := done_count(g, id) * REP_TASK
	for i in mini(int(g.step), Data.STEPS.size()):
		if str(Data.STEPS[i].get("sect", "")) == id:
			n += REP_STEP
	return n

static func rank(g, id: String) -> int:
	var r := rep(g, id)
	var k := 0
	for i in RANK_AT.size():
		if r >= int(RANK_AT[i]):
			k = i
	return k

static func rank_name(g, id: String) -> String:
	return str(SECTS[id].ranks[rank(g, id)])

## What a guest of the sect that answers for town `tid` pays at its counters (1 for a stranger, and anywhere else).
static func price(g, tid: String) -> float:
	var id := of_town(tid)
	if id == "" or id == "azure":
		return 1.0
	return 1.0 - RANK_PRICE * float(rank(g, id))

## [done, wanted] for task `t`.
static func progress(g, t: String) -> Array:
	var nd: Array = TASKS[t].need
	var base: Dictionary = g.sect_base.get(t, {})
	match str(nd[0]):
		"have":
			var have := 0
			var want := 0
			for k in nd[1]:
				want += int(nd[1][k])
				have += mini(int(nd[1][k]), int(g.inv.get(k, 0)))
			return [have, want]
		"kills":
			var n := 0
			for k in nd[1]:
				n += int(g.felled_kind.get(k, 0)) - int(base.get(k, 0))
			return [mini(n, int(nd[2])), int(nd[2])]
		"raids":
			return [mini(int(g.raids_broken) - int(base.get("v", 0)), int(nd[1])), int(nd[1])]
		"more":
			return [mini(int(Feats.value(g, [str(nd[1]), 0]) - float(base.get("v", 0.0))), int(nd[2])), int(nd[2])]
		"reach":
			return [mini(int(Feats.value(g, [str(nd[1]), 0])), int(nd[2])), int(nd[2])]
		"folk":
			return [mini((base.get("met", {}) as Dictionary).size(), int(nd[2])), int(nd[2])]
	return [0, 1]

static func ready(g, t: String) -> bool:
	var p := progress(g, t)
	return state(g, t) == "taken" and int(p[0]) >= int(p[1])

## Whether the hall of sect `id` is open to him yet: he has stood in its country.
static func open(g, id: String) -> bool:
	return id != "" and id != "azure" and SECTS.has(id) and g.seen.has(str(SECTS[id].area))

static func take(g, t: String) -> void:
	if state(g, t) != "":
		return
	g.sect_q[t] = "taken"
	var nd: Array = TASKS[t].need
	var base := {}
	match str(nd[0]):
		"kills":
			for k in nd[1]:
				base[k] = int(g.felled_kind.get(k, 0))
		"raids":
			base["v"] = int(g.raids_broken)
		"more":
			base["v"] = Feats.value(g, [str(nd[1]), 0])
		"folk":
			base["met"] = {}
	g.sect_base[t] = base
	g.note("Took a task of %s: %s" % [str(SECTS[str(TASKS[t].sect)].short), str(TASKS[t].n)])

## What task `t` pays him today: {stones, exp (a share of the level he is on), renown}.  Each sect pays its own way.
static func pay(g, t: String) -> Dictionary:
	var j: Dictionary = TASKS[t]
	var stones := int(j.get("stones", 0)) + int(j.get("realm_pay", 0)) * int(g.realm())
	if str(j.sect) == "black":
		stones *= 2
	return {"stones": stones, "exp": float(j.get("exp", 0.0)), "renown": int(j.get("renown", 0))}

## Reported: what was asked for is handed over, and the sect pays in its own way.  True if it was ready.
static func finish(g, t: String) -> bool:
	if not ready(g, t):
		return false
	var j: Dictionary = TASKS[t]
	var id := str(j.sect)
	var was := rank(g, id)
	if str(j.need[0]) == "have":
		for k in j.need[1]:
			g.inv[k] = int(g.inv.get(k, 0)) - int(j.need[1][k])
	var p := pay(g, t)
	g.sect_q[t] = "done"
	g.stones += int(p.stones)
	if float(p.exp) > 0.0 and int(g.level) < Data.MAX_LEVEL:
		g.add_exp(float(Data.EXP_NEED[mini(int(g.level), Data.EXP_NEED.size() - 1)]) * float(p.exp))
	g.add_renown(int(p.renown))
	if id == "reed":
		g.heal_full()
	var bits: Array = []
	if int(p.stones) > 0:
		bits.append("+%d spirit stones" % int(p.stones))
	if float(p.exp) > 0.0:
		bits.append("something understood")
	if int(p.renown) > 0:
		bits.append("+%d renown" % int(p.renown))
	if id == "reed":
		bits.append("a bowl at the landing")
	g.toast("A task done for %s: %s" % [str(SECTS[id].short), ", ".join(bits) if not bits.is_empty() else "nothing said"])
	g.note("A task done for %s: %s" % [str(SECTS[id].short), str(j.n)])
	# (what is done for a town's sect is felt in the town: weal.gd)
	Weal.act(g, str(SECTS[id].town), "errand")
	var now := rank(g, id)
	if now > was:
		g.toast("%s: %s" % [str(SECTS[id].n), str(SECTS[id].ranks[now])])
		if now == RANK_AT.size() - 1 and int(g.inv.get(str(TOKENS[id]), 0)) <= 0:
			g.add_item(str(TOKENS[id]))
			g.toast("Given: %s" % str(Data.ITEMS[str(TOKENS[id])].n))
	g.poll_steps()
	return true

## One of the people of the towns has been spoken with (main.talk_folk): a task that asks for their kind counts them.
static func folk_talked(g, p: Dictionary) -> void:
	for t in g.sect_q:
		if str(g.sect_q[t]) != "taken" or str(TASKS[t].need[0]) != "folk" or not Folk.is_role(p, str(TASKS[t].need[1])):
			continue
		g.sect_base[t]["met"][str(p.id)] = true

## The task of sect `id` the bot goes on with: the one it has taken, else the first on the wall that is neither
## done nor foul ("" when there is none).
static func next(g, id: String) -> String:
	for t in tasks_of(id):
		if state(g, t) == "taken":
			return str(t)
	for t2 in tasks_of(id):
		if state(g, t2) == "" and not bool(TASKS[t2].get("foul", false)):
			return str(t2)
	return ""

## What the wall says of task `t`.
static func text(g, t: String) -> String:
	var j: Dictionary = TASKS[t]
	var p := progress(g, t)
	var py := pay(g, t)
	var paid: Array = []
	if int(py.stones) > 0:
		paid.append("%d spirit stones" % int(py.stones))
	if float(py.exp) > 0.0:
		paid.append("understanding")
	if int(py.renown) > 0:
		paid.append("%d renown" % int(py.renown))
	var s := "%s\n\n%s%s" % [str(j.ask), "FOUL WORK: a wrong done to somebody. Nothing asks for it.\n" if bool(j.get("foul", false)) else "", "Pays: %s." % (", ".join(paid) if not paid.is_empty() else "nothing")]
	if state(g, t) == "taken":
		s += "\nSo far: %d of %d." % [int(p[0]), int(p[1])]
	return s

static func label(g, t: String) -> String:
	var st := state(g, t)
	var p := progress(g, t)
	if st == "done":
		return "%s (done)" % str(TASKS[t].n)
	if st == "taken":
		return "%s: report (%d/%d)" % [str(TASKS[t].n), int(p[0]), int(p[1])] if ready(g, t) else "%s (%d/%d)" % [str(TASKS[t].n), int(p[0]), int(p[1])]
	return "%s%s" % [str(TASKS[t].n), " (foul)" if bool(TASKS[t].get("foul", false)) else ""]

## The page of the sects: for each, its name, its side, how he stands and what its way is.
static func page(g) -> Array:
	var out: Array = []
	for id in ORDER:
		var s: Dictionary = SECTS[id]
		var known: bool = id == "azure" or g.seen.has(str(s.area))
		out.append({"id": id, "n": str(s.n) if known else "A sect down the river", "side": str(s.side), "rank": rank_name(g, id) if known else "", "rep": rep(g, id),
			"creed": s.creed if known else [], "custom": str(s.custom) if known else "He has not stood in its country.", "done": done_count(g, id), "of": tasks_of(id).size(), "col": s.col})
	return out
