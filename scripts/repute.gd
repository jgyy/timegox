class_name Repute
extends RefCounted
## The Turned Face (the Turned Face release): what the people of the land think of him, and what it costs.
##
## The Way he walks (creed.gd) is a name; this is a grudge.  It is weighed from two things only, both of them
## things done to *people*: **greed** (what was taken that was somebody's, wrongs done for a purse, things
## broken and never paid for, nights at the mat, countries hunted bare) and **cruelty** (people dead by his
## hand, the forbidden arts, the Devouring Palm, a price on his head).  What was done for them (gifts to a
## town's chest, kindnesses in the street, lost things carried home, days stood in the circle) is set against
## it, but **never more than half of it**: a town forgives, it does not forget.
##
## The score is a pure function of the game state (`causes`, `score`), so a journey begun in the middle of the
## story stands where its deeds put it; the only state kept is `g.repute_told` (the stage last told).
##
## **What it costs is difficulty.**  Six stages (`STAGES`), each with a weight on every foe he meets
## (`mod(g, "foe")`: their health and their blow, through `Battle.start`), on the counters of the towns
## (`mod(g, "price")`, through `Weal.mod`), on the crowd that follows a cultivator of his standing about
## (`shuns`: nobody walks up to somebody the street has turned from), and on what the street says
## (`line`).  People who dislike somebody tell the wild where he sleeps, sell him short weight, and cheer for
## whatever he fights.
##
## **Nothing here may stop a step of the story**: it only makes what is asked harder to do.  A heavenly
## tribulation is heaven's and a doom cannot be beaten anyway: neither is weighed.  The bot does nothing
## greedy or cruel, so its journey is fought at the first stage, as it always was (the tests check both).

## the score at which each stage begins
const AT := [0, 8, 18, 32, 50, 75]
const STAGES := [
	{"n": "Well Thought Of", "foe": 1.0, "price": 1.0, "col": Color("a8d8a0"),
		"desc": "Nobody in the land has a grudge against him that they would say out loud. Foes are what they are."},
	{"n": "Talked About", "foe": 1.06, "price": 1.0, "col": Color("d8d090"),
		"desc": "Things are said behind his back, in the low voice people keep for somebody who might be listening. Somebody tells a pack which way he went: foes are a little stronger."},
	{"n": "Disliked", "foe": 1.14, "price": 1.1, "col": Color("e0b070"),
		"desc": "The street does not like him. Counters ask a tenth more and weigh short; the herdsman who saw the wolves does not warn him. Foes are stronger by a seventh."},
	{"n": "Shunned", "foe": 1.25, "price": 1.2, "col": Color("e08850"),
		"desc": "Doors close as he comes up the street, and nobody walks beside him. What hunts in the wild is told where he sleeps, and comes rested. Foes are a quarter stronger; counters ask a fifth more."},
	{"n": "Reviled", "foe": 1.4, "price": 1.35, "col": Color("d05040"),
		"desc": "Children are called in when he is seen. There are people in every town who would pay to have him hurt, and some of them have paid. Foes are two fifths stronger; counters ask a third more."},
	{"n": "Cursed in Every Town", "foe": 1.6, "price": 1.5, "col": Color("a02838"),
		"desc": "His name is a word people use to frighten each other. Every hand in the land is against him, and the wild knows it. Foes are three fifths stronger; counters ask half as much again."},
]
## the stage from which the crowd that follows a famous cultivator about (fame.gd) keeps away
const SHUN := 3
## how much of the harm the good done may undo
const MERCY := 0.5

## What the street says to him, by stage (from the second: before that they say what they always said).
## Each fits the street (sixty-four letters) and reads of a hero of either sex.
const STREET := [
	[],
	["I heard something about you, %s. I shan't say what.", "Oh. It is you. ...No, nothing. Good day."],
	["We know what you did. The whole street knows.", "I will serve you. I do not have to like it.", "Mind your purse, everybody. Ah. Sorry. Not you, of course."],
	["Go on. Walk past. Everybody else does now, from you.", "My door is shut, %s. It is shut for you.", "I would sooner sell to a fox. A fox at least is honest about it."],
	["Get away from my stall. Go on, get away from it.", "There. That is the one. Do not look at it, child.", "If the wolves have you, %s, nobody here will go and look."],
	["Murderer. Thief. Go and be it somewhere else.", "Every town has your name in it now, %s. None kindly.", "Spit, child. That is right. That is what it is for."],
]
## What Yue Ling says the first time each stage is reached (told as a note in the annals and a toast).
const YUE := [
	"",
	"People have started to stop talking when you come into a room. I thought you should know. I noticed.",
	"A woman in the market sold me rice today and gave me short weight, and when I said so she said: tell him. I did not know what she meant. I think I do.",
	"Nobody walks with us any more. I used to think the crowd was a nuisance. It was not a nuisance. It was people being glad of you.",
	"A pack came at us last night from downwind, the way nothing comes at you by accident. Somebody told them where we were. Somebody in a town we helped.",
	"I am still here. I want you to notice that I am the only one who is. I am not going anywhere. But I want you to notice.",
]

# ---------------------------------------------------------------- weighing
static func _weal(g, what: String) -> int:
	var n := 0
	for k in g.weal:
		if str(k).ends_with("|" + what):
			n += int(g.weal[k])
	return n

## What is held against him: [{d, why, kind}], the heaviest first (`kind` "greed" or "cruelty").
static func harms(g) -> Array:
	var out: Array = []
	var add := func(kind: String, d: int, why: String):
		if d > 0:
			out.append({"d": d, "why": why, "kind": kind})
	# ---- greed
	add.call("greed", 4 * int(g.deeds_bad), "people of the towns wronged for what it paid")
	add.call("greed", 3 * int(g.pilfered), "things that were somebody's, kept in his sleeve")
	add.call("greed", 3 * _weal(g, "unpaid"), "things broken and never paid for")
	add.call("greed", mini(15, int(g.gamble_rounds) / 5), "nights at the gambling mat")
	add.call("greed", 3 * Wilds.worst_count(g, 2), "countries hunted until nothing was left")
	# ---- cruelty
	add.call("cruelty", 8 * Crime.count(g), "people dead by his hand")
	add.call("cruelty", 3 * Taboo.taint(g), "arts the precepts forbid")
	add.call("cruelty", 2 * int(g.creed.get("devour", 0)), "the Devouring Palm")
	add.call("cruelty", 6 if not g.bounty.is_empty() else 0, "a price on his head")
	out.sort_custom(func(a, b): return int(a.d) > int(b.d))
	return out

## What is set against it: [{d, why}], the heaviest first.
static func amends(g) -> Array:
	var out: Array = []
	var add := func(d: int, why: String):
		if d > 0:
			out.append({"d": d, "why": why})
	add.call(2 * _weal(g, "gift"), "gifts to the chests of the towns")
	add.call(2 * int(g.deeds_good), "kindnesses done in the street")
	add.call(int(g.restored), "lost things carried home")
	add.call(_weal(g, "errand"), "errands run for the people of the towns")
	add.call(2 * int(g.nets_opened), "nets opened on three sides")
	add.call(2 * int(g.served), "days stood in the circle")
	out.sort_custom(func(a, b): return int(a.d) > int(b.d))
	return out

static func _sum(a: Array) -> int:
	var n := 0
	for c in a:
		n += int(c.d)
	return n

## The harm left once what was done for them has been set against it (never below half of the harm).
static func score(g) -> int:
	var bad := _sum(harms(g))
	if bad <= 0:
		return 0
	var good := mini(_sum(amends(g)), int(floor(float(bad) * MERCY)))
	return maxi(0, bad - good)

## 0 (well thought of) .. 5 (cursed in every town).
static func stage(g) -> int:
	var s := score(g)
	var st := 0
	for i in AT.size():
		if s >= int(AT[i]):
			st = i
	return st

static func name_of(g) -> String:
	return str(STAGES[stage(g)].n)

## A weight of the stage he stands at: "foe" (health and blow of what he fights), "price" (a town's counters).
static func mod(g, key: String) -> float:
	return float(STAGES[stage(g)].get(key, 1.0))

## How much harder a battle is, as a word for the log ("" at the first stage).
static func battle_word(g) -> String:
	var st := stage(g)
	if st == 0:
		return ""
	return "The land has turned its face (%s): somebody told these where to look, and they fight %d%% harder." % [str(STAGES[st].n).to_lower(), int(round((float(STAGES[st].foe) - 1.0) * 100.0))]

## Whether the crowd that follows a famous cultivator keeps away from him.
static func shuns(g) -> bool:
	return stage(g) >= SHUN

## What somebody in the street says to him at this stage ("" when they have nothing to say of it).
static func line(g, seed_: int) -> String:
	var ls: Array = STREET[stage(g)]
	return "" if ls.is_empty() else str(ls[absi(seed_) % ls.size()])

## The score that would put him a stage up, or -1 at the last.
static func next_at(g) -> int:
	var st := stage(g)
	return -1 if st + 1 >= AT.size() else int(AT[st + 1])

## Told when the stage changes: a toast, and a note in the annals (with Yue Ling's word, the first time
## each stage is reached).
static func poll(g) -> void:
	if not bool(g.started) or str(g.prologue) != "":
		return
	var st := stage(g)
	var was := int(g.repute_told)
	if st == was:
		return
	g.repute_told = st
	if st > was:
		g.toast("The land thinks less of you: %s. Foes will fight harder." % str(STAGES[st].n))
		g.note("%s. %s" % [str(STAGES[st].n), str(STAGES[st].desc)])
		if not g.repute_seen.has(st):
			g.repute_seen[st] = true
			g.note("Yue Ling: \"%s\"" % str(YUE[st]))
	else:
		g.toast("The land thinks better of you: %s." % str(STAGES[st].n))
		g.note("Thought better of: %s." % str(STAGES[st].n))

## A line for the bot's report and the tests.
static func text(g) -> String:
	return "%s (score %d: harm %d, amends %d)" % [name_of(g), score(g), _sum(harms(g)), _sum(amends(g))]
