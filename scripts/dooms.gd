class_name Dooms
extends RefCounted
## What cannot be beaten (the Lost Horse release): battles that are lost, and are not the end.
##
## For twenty-three chapters a battle had two ends: the foe fell, or Lin Feng woke in the infirmary
## and tried again.  A **doom** is a third thing: a foe that no realm, sword or trial's road can put
## down (`"doom": true` in Data.ENEMIES), met in a battle that is fought in earnest and **lost**, after
## which the story goes on from the losing.
##
##   * a blow lands on a doom and does its harm, and the harm closes like water: it cannot be brought
##     under a tenth of its strength (FLOOR), and it mends at every drum (MEND);
##   * it grows as it comes on (RISE a round), and on the round it crests (`rounds`) whoever is still
##     standing is carried off their feet;
##   * the battle menu has a fourth road, **Give way**: to stop fighting what cannot be fought, at
##     once, standing;
##   * nothing is taken for it: no spirit stones to the healers, no waking in the sect, no fall counted
##     against the journey.  What it was worth to have stood there is learned (`exp`).
##
## **How** it was lost is remembered (`Game.falls`): `struck` (he fought it to the end, and most of what
## he did was blows), `kept` (most of what the two of them did was mending each other), or `gave` (he
## gave way).  The scene after is told differently for each ("fall:<id>:<how>" in Data.DIALOGUE), each
## tips a scale a little (TILT), and the ending says which he was.
##
## A doom of the story is a step of kind `"fall"` (`boss`); the dooms that roam (a war-band of them)
## are a step of kind `"falls"` (`n` of the kinds in `of`): a pack that has rolled over him has passed,
## and is gone from that ground for a while like any pack.  The bot fights each as it fights anything
## (`--yield` makes it give way instead), and the tests fight every doom with a party of the last realm.

## a doom cannot be brought under this share of its health, and gets this share back at every round
const FLOOR := 0.1
const MEND := 0.25
## how much harder it hits with every round that passes
const RISE := 1.35
## the health the party is left with afterwards (a share of each one's own)
const LEFT := 0.35

## The dooms: how many rounds each can be stood against, what its last blow is called, what is
## learned of losing to it (a share of what beating a foe of its level would teach), and for the
## ones that roam the words said as each pack passes.
const DOOMS := {
	"tide_horse": {"rounds": 3, "crest": "The crest comes down", "exp": 1.5,
		"passes": ["The white horse goes over them and on up the shore, and does not look round. When Lin Feng can see again he is forty paces inland, sitting down, with a crab in his sleeve.",
			"It breaks, and for a moment there is no up. Then there is sand under his hands, and Yue Ling beside him wringing out her hair, and the wave a long way off, going where it was always going.",
			"The sword goes through it like a hand through rain. The tide takes no notice of having been cut. It sets them both down, quite gently, on the wrack-line with the driftwood."]},
	"tide_mare": {"rounds": 3, "crest": "The crest comes down", "exp": 1.5,
		"passes": ["The grey mare of the tide shoulders past. It is not anger. A cart-horse does not hate the gate it leans on."]},
	"spring_colt": {"rounds": 4, "crest": "The undertow takes their feet", "exp": 1.5,
		"passes": ["The colt is only knee-high, and it has all the sea behind it. They are sat down in the shallows like children."]},
	"wuzhiqi": {"rounds": 5, "crest": "The Huai rises to his shoulder and comes down", "exp": 6.0},
	"the_riders": {"rounds": 5, "crest": "Ten thousand riders come on at a walk", "exp": 6.0},
}

## what the manner of a fall tips (echoes.gd SCALES): unbending, merciful, of the home fire
const TILT := {"struck": ["heart", -1], "kept": ["heart", 1], "gave": ["craft", -1]}
const HOW := {"struck": "fought it to the end", "kept": "kept each other standing as long as could be", "gave": "gave way"}
const HOW_ORDER := ["struck", "kept", "gave"]

static func is_doom(id: String) -> bool:
	return bool(Data.ENEMIES.get(id, {}).get("doom", false))

## Whether a pack (a list of {id, lv}) has a doom in it.
static func in_group(group: Array) -> bool:
	for f in group:
		if is_doom(str(f.id)):
			return true
	return false

static func rounds(id: String) -> int:
	return int(DOOMS.get(id, {}).get("rounds", 4))

## The round on which a battle with these foes (fighter dictionaries) is over: the soonest of theirs.
static func crest_round(foes: Array) -> int:
	var r := 99
	for f in foes:
		if is_doom(str(f.id)):
			r = mini(r, rounds(str(f.id)))
	return r

## How a battle was lost, from what was done in it: gave way; mostly mending; mostly blows.
static func manner(gave: bool, blows: int, mends: int) -> String:
	if gave:
		return "gave"
	return "kept" if mends > blows else "struck"

## A doom has rolled over the party of `g`: remembered, its scale tipped (the first time for each
## doom), what it taught learned.  `ids` are the kinds that were in the battle, `lv` their level.
## Returns the words for it if it was a pack that passed ("" for a doom of the story: main tells that).
static func fell(g, ids: Array, lv: int, how: String, round_n: int) -> String:
	var first: String = str(ids[0])
	g.fallen += 1
	if how == "gave":
		g.yielded += 1
	var fresh: bool = not g.falls.has(first)
	for id in ids:
		if not g.falls.has(str(id)):
			g.falls[str(id)] = {"how": how, "rounds": round_n}
	if fresh and TILT.has(how):
		g.scales[TILT[how][0]] = int(g.scales.get(TILT[how][0], 0)) + int(TILT[how][1])
	for i in g.party_size():
		g.hp[i] = maxf(g.hp[i], float(g.max_hp(i)) * LEFT)
	var xp := int(Data.enemy_exp(lv, false) * float(DOOMS.get(first, {}).get("exp", 1.0)))
	g.add_exp(xp)
	g.note("Lost to %s (%s), and went on" % [str(Data.ENEMIES[first].n), str(HOW[how])])
	var lines: Array = DOOMS.get(first, {}).get("passes", [])
	return "" if lines.is_empty() else str(lines[(g.fallen - 1) % lines.size()])

## How many of the dooms of the story `g` has stood in front of.
static func met(g) -> int:
	var n := 0
	for id in DOOMS:
		if g.falls.has(id):
			n += 1
	return n

## What the ending tells of it: one sentence, for whichever way most of them were lost.
static func epilogue(g) -> String:
	if g.falls.is_empty():
		return ""
	var by := {}
	for id in g.falls:
		var hw := str(g.falls[id].how)
		by[hw] = int(by.get(hw, 0)) + 1
	var top := "struck"
	for hw2 in HOW_ORDER:
		if int(by.get(hw2, 0)) > int(by.get(top, 0)):
			top = hw2
	match top:
		"kept":
			return "Of the things that could not be beaten, it is told that the two of them were seen holding each other up in front of every one, long after it was any use."
		"gave":
			return "Of the things that could not be beaten, it is told that he looked at each, and put up his sword, and stood aside; and that it was the first time anybody had seen him do it."
	return "Of the things that could not be beaten, it is told that he fought every one of them to the last round, and lost every time, and was not smaller for it."
