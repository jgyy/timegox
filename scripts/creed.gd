class_name Creed
extends RefCounted
## The Way he walks (the Ordered House release): where a cultivator stands between the Righteous Path and
## the Demonic, and between the Precepts and the open road.  Two scales, three places on each, nine Ways.
##
##   virtue:  Righteous (zheng)  ..  of the middle  ..  Demonic (mo)
##   rule:    Orthodox (keeps the precepts of a sect)  ..  of the middle  ..  Unfettered (a rogue cultivator)
##
## Nothing is chosen from a list.  The Way is weighed from what was done (`tally`): gifts to a town's
## chest, errands, houses put to rights, what was answered at the crossroads; things broken and not paid
## for, packs struck in their sleep, an art that feeds on what it kills; shifts worked, the post carried,
## notices answered; the mat, the open road.  It is a pure function of the game state, so a journey begun
## in the middle of the story (--bot-start) stands where its deeds put it.  The only state kept is
## `g.creed` (deeds that leave no other trace: "sleeper", "devour", "virtue", "rule") and `g.creed_told`.
##
## **A Way opens some doors and shuts others** (`can`, `why_not`), and nothing here ever stops a step of
## the story: what is shut is the mat, a shift, a fare, the post, a shrine, a blow at what sleeps, the
## stipend, and the art of the other side.
##   Righteous   will not strike a sleeping pack first; cannot learn the Devouring Palm
##   Demonic     no incense lights for him, nobody hires him, rides with him or trusts him with the post
##   Orthodox    does not sit at a gambling mat
##   Unfettered  carries no post-bag, is on nobody's books, and draws no stipend
## Each side has an art of its own in battle (`ARTS`, `skills`) and changes numbers through `mod`.

const SIDE := 12
const CAP := 40
const AXES := ["virtue", "rule"]
const AXIS := {
	"virtue": {"n": "The Righteous Path and the Demonic", "pos": "Righteous", "neg": "Demonic", "col": Color("f0d890"), "neg_col": Color("b05ad0")},
	"rule": {"n": "The Precepts and the Open Road", "pos": "Orthodox", "neg": "Unfettered", "col": Color("8ab8e8"), "neg_col": Color("8ad890")},
}
## the nine Ways: [rule, virtue] each -1, 0, 1 -> name, what it is
const WAYS := {
	"1|1": {"n": "Pillar of the Righteous Path", "desc": "Keeps the precepts and does right by them. Sects send their children to somebody like this, and towns their quarrels."},
	"0|1": {"n": "Benevolent Wayfarer", "desc": "Does right because it is right, and neither asks a sect's leave nor scorns it."},
	"-1|1": {"n": "Knight-Errant", "desc": "Rights wrongs on the open road and answers to nobody. The songs are about people like this, and so are the warrants."},
	"1|0": {"n": "Keeper of the Precepts", "desc": "The rule is the rule. Whether it is kind is somebody else's question."},
	"0|0": {"n": "Walker of the Middle Way", "desc": "Neither bound nor loose, neither saint nor devil. Most of the land walks here, and most of the Dao."},
	"-1|0": {"n": "Carefree Wanderer", "desc": "A rogue cultivator: no sect, no master, no debts. Comes like the wind and is as much use to plan by."},
	"1|-1": {"n": "Iron Hand of the Devil Sects", "desc": "Takes what he wants by rule and rank, and keeps the letter of every oath he twists."},
	"0|-1": {"n": "Devourer", "desc": "Whatever makes him stronger is the Way. He has stopped counting what it costs other people."},
	"-1|-1": {"n": "Calamity", "desc": "Bound by nothing and sparing nothing. Doors are barred when the wind is from his quarter."},
}

## The arts of the four sides: a technique of battle only that side may use (Data.SKILLS, `"creed"`).
const ARTS := {"virtue|1": "creed_rectify", "virtue|-1": "creed_devour", "rule|1": "creed_precept", "rule|-1": "creed_carefree"}

## What a side changes (through `mod`): a missing key is 1.
const MODS := {
	"virtue|1": {"dark": 1.15, "price": 0.9},
	"virtue|-1": {"dealt": 1.08, "exp": 1.06, "price": 1.5},
	"rule|1": {"taken": 0.95, "stipend": 1.5},
	"rule|-1": {"stones": 1.08, "stipend": 0.0},
}
## What each side is told it has, and has not (the page of the Way).
const CAN := {
	"virtue|1": ["The Sword That Sets Right, in battle", "Blows fall a sixth harder on what is of the dark", "The sect's counters ask a tenth less of him"],
	"virtue|-1": ["The Devouring Palm, in battle: what it wounds, it feeds on", "Every blow a little harder, every kill a little more learned from"],
	"rule|1": ["The Wall of the Precepts, in battle", "Blows land a twentieth lighter on him", "Half as much again from the sect on the first of the month"],
	"rule|-1": ["The Carefree Step, in battle", "A beaten pack gives up a twelfth more spirit stones"],
}
const CANNOT := {
	"virtue|1": ["Will not strike a sleeping pack first", "Cannot learn the Devouring Palm"],
	"virtue|-1": ["No incense lights for him: shrines and altars give him nothing", "Nobody hires him, rides in his carriage or trusts him with the post", "The sect's counters ask half as much again", "Cannot learn the Sword That Sets Right"],
	"rule|1": ["Does not sit at a gambling mat", "Cannot learn the Carefree Step"],
	"rule|-1": ["Carries no post-bag and is on nobody's books: no salary", "Draws no stipend from the sect", "Cannot learn the Wall of the Precepts"],
}
## What cannot be done on a side, and what is said when it is tried.
const SHUT := {
	"sleeper": ["virtue", 1, "He will not strike what sleeps. That is not how somebody of the Righteous Path begins a fight."],
	"pray": ["virtue", -1, "The incense will not catch. He holds the flame to it three times, and three times it goes out. Whatever is asked for here is not given to somebody of the Demonic Path."],
	"work": ["virtue", -1, "\"No. Not you. I have a family.\" The door is shut quietly, which is worse. Nobody hires somebody of the Demonic Path."],
	"fare": ["virtue", -1, "They look at the carriage, and at who is driving it, and find that they are not going anywhere today after all."],
	"gamble": ["rule", 1, "\"A disciple who keeps the precepts, at my mat? Your Elder would have my ears, and you would have a penance. Go and sweep something.\""],
	"bag": ["rule", -1, "\"The post goes with people who can be found afterwards. You are a rogue cultivator: you might be in another province by supper.\""],
	"bag_dark": ["virtue", -1, "\"The seal on this bag is the town's word. I will not put it in that hand.\""],
	"salary": ["rule", -1, "On nobody's books: a rogue cultivator is paid by the day, and draws no salary."],
}
## What the street says to him, by where he stands (`line`).
const LINES := {
	"virtue|1": ["They say you have never taken a thing that was not offered, %s. My husband says nobody is like that. I say look.", "A righteous cultivator in our street. I shall leave the washing out tonight."],
	"virtue|-1": ["...Good day. I was just going in. We are all just going in.", "My boy says your shadow is the wrong colour, %s. I told him to hush. He is not wrong."],
	"rule|1": ["You keep your sect's rule, they say, even where nobody could see. Somebody always sees, %s. It is usually a child.", "A disciple in good standing. You may tell your Elder our gate was swept when you came."],
	"rule|-1": ["A rogue cultivator! No master, no rule. Do you get up when you like, %s? Every day? Heavens.", "They say you answer to nobody. My mother-in-law would like a word with you about how it is done."],
}

# ---------------------------------------------------------------- weighing
static func _weal(g, what: String) -> int:
	var n := 0
	for k in g.weal:
		if str(k).ends_with("|" + what):
			n += int(g.weal[k])
	return n

static func _jobs_done(g) -> int:
	var n := 0
	for k in g.jobs:
		if str(g.jobs[k]) == "done":
			n += 1
	return n

static func _shifts(g) -> int:
	var n := 0
	for k in g.shifts:
		n += int(g.shifts[k])
	return n

## Everything the Way is weighed by: [{axis, d, why}], the heaviest first.
static func causes(g) -> Array:
	var out: Array = []
	var add := func(axis: String, d: int, why: String):
		if d != 0:
			out.append({"axis": axis, "d": d, "why": why})
	# ---- virtue
	add.call("virtue", mini(18, 2 * _weal(g, "gift")), "gifts to the chests of the towns")
	add.call("virtue", mini(8, _weal(g, "errand")), "errands run for the people of the towns")
	add.call("virtue", mini(15, 3 * g.fitted.size()), "houses put to rights")
	add.call("virtue", clampi(Echoes.scale(g, "heart"), -12, 12), "mercy and rigour at the crossroads")
	add.call("virtue", mini(6, int(g.fares) + int(g.bags_done)), "people and letters carried")
	add.call("virtue", -mini(16, 4 * _weal(g, "unpaid")), "things broken and not paid for")
	add.call("virtue", -mini(10, int(g.smashed) / 3), "things broken in the towns")
	add.call("virtue", -mini(16, 2 * int(g.creed.get("sleeper", 0))), "packs struck in their sleep")
	add.call("virtue", -mini(24, 3 * int(g.creed.get("devour", 0))), "the Devouring Palm")
	add.call("virtue", -mini(6, int(g.misplaced)), "things set down where they should not be, and left")
	add.call("virtue", int(g.creed.get("virtue", 0)), "what was answered when it was asked")
	# ---- rule
	add.call("rule", mini(12, 2 * _shifts(g)), "shifts worked at a trade")
	add.call("rule", mini(10, 2 * int(g.bags_done)), "the post carried")
	add.call("rule", mini(10, 2 * _jobs_done(g)), "notices answered")
	add.call("rule", mini(8, int(g.stipends)), "months on the roll of the sect")
	add.call("rule", mini(8, Hold.built_n(g)), "what was built at Guiyun")
	add.call("rule", clampi(-Echoes.scale(g, "reach"), -10, 10), "the home fire and the wide world")
	add.call("rule", -mini(20, int(g.gamble_rounds) / 2), "rounds at the mat")
	add.call("rule", -mini(10, int(g.smashed) / 3), "things broken in the towns")
	add.call("rule", -mini(8, 2 * int(g.dao_switches)), "Daos taken up and dropped")
	add.call("rule", -mini(8, int(g.yielded) * 2), "ground given to what could not be beaten")
	add.call("rule", int(g.creed.get("rule", 0)), "what was answered when it was asked")
	out.sort_custom(func(a, b): return absi(int(a.d)) > absi(int(b.d)))
	return out

## Where he stands on `axis` (-CAP..CAP).
static func value(g, axis: String) -> int:
	var v := 0
	for c in causes(g):
		if str(c.axis) == axis:
			v += int(c.d)
	return clampi(v, -CAP, CAP)

## Which side of `axis` he is on: 1, -1, or 0 for the middle.
static func side(g, axis: String) -> int:
	var v := value(g, axis)
	return 1 if v >= SIDE else (-1 if v <= -SIDE else 0)

static func key(g) -> String:
	return "%d|%d" % [side(g, "rule"), side(g, "virtue")]

static func way(g) -> Dictionary:
	return WAYS[key(g)]

static func name_of(g) -> String:
	return str(WAYS[key(g)].n)

static func is_side(g, axis: String, s: int) -> bool:
	return side(g, axis) == s

## A deed that leaves no other trace ("sleeper", "devour"), or a tilt of a scale ("virtue", "rule").
static func act(g, what: String, n: int = 1) -> void:
	g.creed[what] = int(g.creed.get(what, 0)) + n

## Told when the Way he walks has changed: a toast, and a line in the annals.
static func poll(g) -> void:
	if not bool(g.started) or str(g.prologue) != "":
		return
	var k := key(g)
	if str(g.creed_told) == "":
		g.creed_told = k
		return
	if k != str(g.creed_told):
		g.creed_told = k
		g.toast("The land has a name for the way you walk: %s" % str(WAYS[k].n))
		g.note("Known as a %s. %s" % [str(WAYS[k].n), str(WAYS[k].desc)])

# ---------------------------------------------------------------- what a Way opens and shuts
## Whether `what` (a key of SHUT) can be done by him as he stands.
static func can(g, what: String) -> bool:
	if not SHUT.has(what):
		return true
	var sh: Array = SHUT[what]
	return side(g, str(sh[0])) != int(sh[1])

## What is said when `what` is tried and cannot be done ("" when it can).
static func why_not(g, what: String) -> String:
	return "" if can(g, what) else str(SHUT[what][2])

## A number the Way changes (`key`: "dealt", "dark", "taken", "exp", "stones", "price", "stipend").
static func mod(g, key_: String) -> float:
	var k := 1.0
	for axis in AXES:
		var s := side(g, axis)
		if s != 0:
			k *= float(MODS["%s|%d" % [axis, s]].get(key_, 1.0))
	return k

## The arts of battle his Way gives him (ids of Data.SKILLS).
static func skills(g) -> Array:
	var out: Array = []
	for axis in AXES:
		var s := side(g, axis)
		if s != 0:
			out.append(str(ARTS["%s|%d" % [axis, s]]))
	return out

## What he has and has not for standing where he does: [can[], cannot[]].
static func doors(g) -> Array:
	var yes: Array = []
	var no: Array = []
	for axis in AXES:
		var s := side(g, axis)
		if s != 0:
			yes.append_array(CAN["%s|%d" % [axis, s]])
			no.append_array(CANNOT["%s|%d" % [axis, s]])
	return [yes, no]

## What somebody in the street says to him for the Way he walks ("" in the middle of both).
static func line(g, seed_: int) -> String:
	var pool: Array = []
	for axis in AXES:
		var s := side(g, axis)
		if s != 0:
			pool.append_array(LINES["%s|%d" % [axis, s]])
	return "" if pool.is_empty() else str(pool[absi(seed_) % pool.size()])

## Whether a need of a trial (`["creed", axis, n]`: at least n, or at most n when n is below nothing) is met.
static func meets(g, axis: String, n: int) -> bool:
	var v := value(g, axis)
	return v >= n if n > 0 else v <= n

## "Righteous 14, Orthodox 12"
static func text(g) -> String:
	var parts: Array = []
	for axis in AXES:
		var v := value(g, axis)
		var s := side(g, axis)
		parts.append("%s %+d" % [str(AXIS[axis].pos if s > 0 else (AXIS[axis].neg if s < 0 else "the middle")), v])
	return ", ".join(parts)
