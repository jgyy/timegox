class_name Channels
extends RefCounted
## The Chart of the Channels (the Unblunted Knife release): a skill tree he trains on.  "I go at the big
## hollows, I guide the knife through the big openings, and follow things as they are."  Sixty-one points on
## ten channels that leave the dantian like spokes: the Eight Vessels, one channel for each of the six Daos
## (its body, the craft of that Dao, its phase, a fork, and a seal that only somebody who walks the road can
## open), the Hands (crafts.gd), the Beasts (pets.gd) and Stillness (retreats.gd).
##
## **Insight** opens them: one for every stage he has cultivated (his level), and what `Game.insight` holds
## (a sitting in a place of peace, the first each day in each place; the first masterwork of a craft).  A
## point is opened a rank at a time (`open`), from Esc > The Channels; what is spent is never given back.
## Every channel has the same shape (`BRANCHES[b].nodes`, six of them): three in a line (three ranks, three,
## two), **a fork** (two points of two ranks: opening one bars the other), and a seal (one rank, after either
## side of the fork).  A journey's insight never opens the whole chart (the tests count), so which channels
## to open stays a choice.
##
## **Every number goes through `mod` (a multiplier, 1 with nothing open) or `add` (0 with nothing open)**:
## the bot opens points only inside a step of kind "train" (`PLAN`), so every older journey and test is that
## of somebody with a closed chart.  A new point is a line in a branch's `nodes` with its `fx` (key -> per
## rank); a new key needs asking somewhere through `mod` or `add`.

const ROOT := "dantian"
## how many ranks each of a channel's six points takes, and what a rank of it costs
const RANKS := [3, 3, 2, 2, 2, 1]
const COST := [1, 2, 3, 4, 4, 8]
const FORK_L := 3
const FORK_R := 4
const SEAL := 5
const TIERS := ["closed", "stirred", "open", "wide open"]

const BRANCHES := {
	"vessels": {"n": "The Eight Vessels", "col": Color("e8d8a0"), "desc": "The seas the twelve rivers drain into. Whoever opens them is harder to kill and slower to tire.", "nodes": [
		{"id": "ren", "n": "The Conception Vessel", "fx": {"hp": 0.02}, "desc": "Down the front of the body, from the lip to the root. The sea of yin: he has more blood to lose."},
		{"id": "du", "n": "The Governing Vessel", "fx": {"qi": 0.02}, "desc": "Up the spine, from the root to the crown. The sea of yang: the dantian holds more."},
		{"id": "chong", "n": "The Thrusting Vessel", "fx": {"atk": 0.015}, "desc": "Straight up through the middle of him, the sea of the twelve channels. What he strikes with comes from lower down."},
		{"id": "dai", "n": "The Girdle Vessel", "fx": {"def": 0.03}, "desc": "The only channel that runs round and not along: it binds the others like a hoop on a barrel. A blow has more to get through."},
		{"id": "qiao", "n": "The Heel Vessels", "fx": {"spd": 1.0}, "desc": "From the heels to the corners of the eyes: they open and shut the lids, and say when a foot comes down. He is quicker off the mark."},
		{"id": "circuit", "n": "The Small Heavenly Circuit", "fx": {"regen": 0.02, "med": 0.25}, "desc": "Up the back and down the front and round again, without being pushed. His qi comes back by itself, in battle and out of it."},
	]},
	"sword": {"n": "The Channel of the Edge", "dao": "sword", "col": Color("c8d8e8"), "desc": "The Sword's own road through the arm: from the shoulder-well to the tiger's mouth of the hand.", "nodes": [
		{"id": "sw_arm", "n": "Shoulder-Well", "fx": {"atk": 0.015}, "desc": "Where the weight of the arm hangs from. The blade is swung from here, and not from the wrist."},
		{"id": "sw_forge", "n": "The Smith's Palm", "fx": {"craft_forge": 0.5}, "desc": "A palm that has learned heat through a hammer's handle. What he forges comes out better (half a grade a rank)."},
		{"id": "sw_edge", "n": "Tiger's Mouth", "fx": {"phys": 0.03}, "desc": "The web between thumb and finger, where the hilt lives. The plain blow and every technique of the body land harder."},
		{"id": "sw_gap", "n": "The Gap in the Joint", "fx": {"one": 0.04}, "desc": "\"There are spaces in the joints, and the blade has no thickness.\" A technique that goes for one foe finds the space."},
		{"id": "sw_sweep", "n": "The Wide Stroke", "fx": {"atk": 0.02}, "desc": "A stroke that is in no hurry and leaves nothing out. Everything he strikes with is a little heavier."},
		{"id": "sw_seal", "n": "The Knife Nineteen Years Sharp", "fx": {"atk": 0.03, "phys": 0.03}, "desc": "\"I have had this knife nineteen years, and its edge is as if fresh from the stone.\" Opens only to somebody who walks the Sword's road."},
	]},
	"wander": {"n": "The Channel of the Far Roam", "dao": "wander", "col": Color("a8e0c8"), "desc": "Free Wandering's own road, down the outside of the leg to the bubbling spring of the sole.", "nodes": [
		{"id": "wa_leg", "n": "Leaping Circle", "fx": {"spd": 1.0}, "desc": "The point at the hip that every jump begins from. He is quicker."},
		{"id": "wa_shoe", "n": "The Cobbler's Thumb", "fx": {"craft_cobble": 0.5}, "desc": "A thumb that knows where a sole will wear before it has been walked on. What he cobbles comes out better (half a grade a rank)."},
		{"id": "wa_wind", "n": "Wind Pool", "fx": {"wood": 0.03, "thunder": 0.03}, "desc": "The hollow under the skull where wind gets in. Techniques of wood and of thunder land harder."},
		{"id": "wa_back", "n": "The Carrier's Spine", "fx": {"load": 6.0}, "desc": "\"He who goes a thousand li takes three months to gather his grain.\" He carries six jin more a rank."},
		{"id": "wa_light", "n": "The Bubbling Spring", "fx": {"evade": 0.02}, "desc": "The first point of the sole. A foot that knows it is already somewhere else when the blow arrives."},
		{"id": "wa_seal", "n": "Riding What Is So", "fx": {"spd": 2.0, "exp": 0.03}, "desc": "\"He mounts on the truth of heaven and earth, and rides the changes of the six breaths.\" Opens only to somebody who walks the road of Free Wandering."},
	]},
	"heart": {"n": "The Channel of the Heart", "dao": "heart", "col": Color("f0a8b0"), "desc": "The Compassionate Heart's road, from the armpit down the inside of the arm to the little finger.", "nodes": [
		{"id": "he_gate", "n": "Spirit Gate", "fx": {"hp": 0.02}, "desc": "At the crease of the wrist, where a physician first lays three fingers. He has more life in him."},
		{"id": "he_carve", "n": "The Carver's Wrist", "fx": {"craft_carve": 0.5}, "desc": "A wrist that waits for the wood to say what is in it. What he carves comes out better (half a grade a rank)."},
		{"id": "he_water", "n": "Lesser Sea", "fx": {"water": 0.04}, "desc": "At the inside of the elbow, where the channel pools. Techniques of water land harder."},
		{"id": "he_mend", "n": "Utmost Spring", "fx": {"heal": 0.05}, "desc": "Deep in the armpit, the source of the channel. What mends him mends more."},
		{"id": "he_bear", "n": "The Heart That Bears", "fx": {"taken": 0.015}, "desc": "\"To know what cannot be helped, and to rest in it as in fate.\" Every blow that reaches him is a little less."},
		{"id": "he_seal", "n": "The Fasting of the Heart", "fx": {"hp": 0.04, "taken": 0.02}, "desc": "\"Do not listen with the ear; listen with the breath. The breath is empty, and waits on things.\" Opens only to somebody who walks the road of the Heart."},
	]},
	"formation": {"n": "The Channel of the Square", "dao": "formation", "col": Color("d8c890"), "desc": "The road of the Array, down the back on either side of the spine, where the body keeps its own ranks.", "nodes": [
		{"id": "fo_back", "n": "Great Shuttle", "fx": {"def": 0.03}, "desc": "Where the bones of the back meet like the warp of a loom. A blow has more to get through."},
		{"id": "fo_write", "n": "The Scribe's Elbow", "fx": {"craft_write": 0.5}, "desc": "An elbow that hangs, so that the brush goes where the line is and not where the arm is. What he writes comes out better (half a grade a rank)."},
		{"id": "fo_earth", "n": "Kidney Hall", "fx": {"earth": 0.04}, "desc": "Low in the back, where the body stores what it will need in winter. Techniques of earth land harder."},
		{"id": "fo_wall", "n": "The Standing Rank", "fx": {"def": 0.04}, "desc": "A formation that only stands. Nothing clever. It is astonishing how much stands."},
		{"id": "fo_turn", "n": "The Turning Rank", "fx": {"spd": 1.0, "evade": 0.01}, "desc": "A formation that has already faced about. He is quicker, and is not quite where the blow was sent."},
		{"id": "fo_seal", "n": "The Wheel Cut by Feel", "fx": {"def": 0.05, "qi": 0.03}, "desc": "\"Not too slow, not too fast: I get it in my hand and feel it in my heart. I cannot put it into words.\" Opens only to somebody who walks the road of the Array."},
	]},
	"alchemy": {"n": "The Channel of the Cauldron", "dao": "alchemy", "col": Color("e8b070"), "desc": "The Cauldron's road: the triple burner, which is no organ at all and warms all three.", "nodes": [
		{"id": "al_burn", "n": "The Lower Burner", "fx": {"qi": 0.02}, "desc": "The fire under the pot. The dantian holds more."},
		{"id": "al_pill", "n": "The Refiner's Nose", "fx": {"craft_refine": 0.5}, "desc": "A nose that knows the turn of a decoction a breath before the colour changes. What he refines comes out better (half a grade a rank)."},
		{"id": "al_fire", "n": "The Middle Burner", "fx": {"fire": 0.04}, "desc": "Where what was eaten is cooked into what is used. Techniques of fire land harder."},
		{"id": "al_swift", "n": "The Quick Decoction", "fx": {"regen": 0.01}, "desc": "Boiled hard and drunk at once. His qi comes back faster in battle."},
		{"id": "al_deep", "n": "The Long Decoction", "fx": {"qi": 0.03}, "desc": "Three days on embers. There is simply more of it."},
		{"id": "al_seal", "n": "The Upper Burner", "fx": {"qi": 0.04, "pill": 0.1}, "desc": "\"Like a mist.\" What rises from the pot is finer than what went in. Opens only to somebody who walks the Cauldron's road."},
	]},
	"illusion": {"n": "The Channel of the Mirror", "dao": "illusion", "col": Color("c8a8f0"), "desc": "The Mirror's road, round the eye and over the skull: the channel by which a thing seen becomes a thing known.", "nodes": [
		{"id": "il_eye", "n": "Bright Eyes", "fx": {"exp": 0.01}, "desc": "At the inner corner of the eye. Whoever sees more of a fight learns more from it."},
		{"id": "il_glass", "n": "The Polisher's Breath", "fx": {"craft_polish": 0.5}, "desc": "A breath on bronze that shows where it is not yet flat. What he polishes comes out better (half a grade a rank)."},
		{"id": "il_all", "n": "Hundred Meetings", "fx": {"fire": 0.015, "water": 0.015, "wood": 0.015, "earth": 0.015, "thunder": 0.015}, "desc": "The crown of the head, where every yang channel meets. Techniques of all five phases land a little harder."},
		{"id": "il_haze", "n": "The Breath on the Glass", "fx": {"evade": 0.02}, "desc": "A mirror that has been breathed on shows a man a little to one side of where he is."},
		{"id": "il_clear", "n": "The Wiped Glass", "fx": {"exp": 0.02}, "desc": "\"The perfect man uses his mind like a mirror: it sends nothing away and goes out to meet nothing.\" He learns more from every battle."},
		{"id": "il_seal", "n": "The Mirror That Keeps Nothing", "fx": {"taken": 0.02, "exp": 0.03}, "desc": "\"It answers, and does not store. So it can bear all things and not be hurt.\" Opens only to somebody who walks the Mirror's road."},
	]},
	"hands": {"n": "The Channel of the Hands", "col": Color("d8a070"), "desc": "No physician's chart shows it. It is cut by use, like the hollow in a doorstep.", "nodes": [
		{"id": "ha_grip", "n": "The Callus", "fx": {"craft": 0.34}, "desc": "Whatever the hands make, in any craft, comes out a little better (a third of a grade a rank)."},
		{"id": "ha_eye", "n": "The Measuring Eye", "fx": {"craft_xp": 0.25}, "desc": "An eye that keeps what the hands did. He learns a craft a quarter faster a rank."},
		{"id": "ha_thrift", "n": "The Offcut Kept", "fx": {"thrift": 1.0}, "desc": "Nothing is thrown down. A rank saves one piece of the first thing a making asks for, where it asks for more than one."},
		{"id": "ha_quick", "n": "The Quick Bench", "fx": {"craft_hours": 0.2}, "desc": "A making takes a fifth less of the day a rank."},
		{"id": "ha_slow", "n": "The Slow Bench", "fx": {"craft": 0.5}, "desc": "It takes as long as it takes. Half a grade better a rank."},
		{"id": "ha_seal", "n": "The Bell-Stand", "fx": {"craft": 1.0, "insight": 1.0}, "desc": "\"I fast until I have forgotten I have four limbs and a body. Then I go into the forest, and see the bell-stand in the tree.\" A whole grade, and a masterwork teaches him twice."},
	]},
	"beasts": {"n": "The Channel of the Beasts", "col": Color("a8c878"), "desc": "It runs from his heel to whatever walks at it.", "nodes": [
		{"id": "be_hand", "n": "The Open Hand", "fx": {"pet_bond": 0.25}, "desc": "A hand held out flat, below the jaw. A beast comes to trust him a quarter faster a rank."},
		{"id": "be_fang", "n": "The Shared Blow", "fx": {"pet_atk": 0.1}, "desc": "The beast at his heel strikes a tenth harder a rank."},
		{"id": "be_nose", "n": "The Borrowed Nose", "fx": {"pet_nose": 1.0}, "desc": "A beast sent out to gather comes back with one piece more a rank."},
		{"id": "be_pack", "n": "The Second Bowl", "fx": {"pet_room": 1.0}, "desc": "There is room for one more beast a rank."},
		{"id": "be_one", "n": "The One Bowl", "fx": {"pet_atk": 0.15}, "desc": "One beast, and all of it. The one at his heel strikes harder."},
		{"id": "be_seal", "n": "The Wooden Cock", "fx": {"pet_atk": 0.2, "pet_guard": 1.0}, "desc": "\"Other cocks crow and it does not change. Seen from afar it is like a cock of wood. Its virtue is whole.\" The beast at his heel takes the first blow of a battle that would have been his."},
	]},
	"still": {"n": "The Channel of Stillness", "col": Color("9ab8d8"), "desc": "It is not a channel. It is what is left when the others are let alone.", "nodes": [
		{"id": "st_sit", "n": "Sitting", "fx": {"med": 0.1}, "desc": "He goes deeper into every meditation, a tenth a rank."},
		{"id": "st_breath", "n": "Breathing from the Heels", "fx": {"sit": 0.25}, "desc": "\"The true man breathes from his heels; the many breathe from their throats.\" A sitting in a place of peace gives a quarter more a rank."},
		{"id": "st_ear", "n": "The Ear Let Go", "fx": {"peace": 1.0}, "desc": "A place is one step more peaceful than it is, for him."},
		{"id": "st_body", "n": "The Body Dropped", "fx": {"hp": 0.03}, "desc": "\"I drop away limbs and body.\" What he has dropped cannot be struck."},
		{"id": "st_mind", "n": "The Wits Dismissed", "fx": {"qi": 0.03}, "desc": "\"I drive out perception and intellect.\" There is more room."},
		{"id": "st_seal", "n": "Sitting and Forgetting", "fx": {"sit": 0.5, "insight": 1.0}, "desc": "\"I cast off form, do away with understanding, and make myself one with the Great Thoroughfare.\" The first sitting of a day in each place teaches him twice."},
	]},
}
const ORDER := ["vessels", "sword", "wander", "heart", "formation", "alchemy", "illusion", "hands", "beasts", "still"]
## what the bot opens inside a "train" step, in order (the body first: nothing that changes what it decides)
const PLAN := ["ren", "du", "chong", "sw_arm", "ren", "du", "st_sit", "ha_grip", "be_hand", "be_fang", "ren", "du", "chong"]
## how much insight what he does (other than cultivating) can ever add
const INSIGHT_MAX := 80

static var _nodes := {}

## Every point of the chart: id -> {id, n, fx, desc, b (its channel), k (0..5, its place on it)}.
static func nodes() -> Dictionary:
	if _nodes.is_empty():
		for b in ORDER:
			var k := 0
			for nd in BRANCHES[b].nodes:
				var d: Dictionary = (nd as Dictionary).duplicate()
				d["b"] = b
				d["k"] = k
				_nodes[str(nd.id)] = d
				k += 1
	return _nodes

static func known(g) -> bool:
	return str(g.prologue) == ""

static func rank(g, id: String) -> int:
	return int(g.channels.get(id, 0))

static func max_rank(id: String) -> int:
	return int(RANKS[int(nodes()[id].k)])

static func cost(id: String) -> int:
	return int(COST[int(nodes()[id].k)])

## The insight he has had in all: a point for every stage cultivated, and what was learned sitting and making.
static func earned(g) -> int:
	return int(g.level) + mini(int(g.insight), INSIGHT_MAX)

static func spent(g) -> int:
	var n := 0
	for id in g.channels:
		n += cost(str(id)) * int(g.channels[id])
	return n

static func spare(g) -> int:
	return earned(g) - spent(g)

## What the whole chart would cost, taking one side of every fork.
static func total_cost() -> int:
	var n := 0
	for k in RANKS.size():
		if k != FORK_R:
			n += int(RANKS[k]) * int(COST[k])
	return n * ORDER.size()

## Insight that comes of something done (a sitting, a masterwork): kept up to INSIGHT_MAX.
static func learn(g, n: int, why: String) -> int:
	var before := mini(int(g.insight), INSIGHT_MAX)
	g.insight = int(g.insight) + n
	var got := mini(int(g.insight), INSIGHT_MAX) - before
	if got > 0:
		g.note("Insight (%d): %s" % [got, why])
	return got

## Why the next rank of point `id` cannot be opened now ("" if it can).
static func why(g, id: String) -> String:
	if not known(g):
		return "Not yet."
	if not nodes().has(id):
		return "There is no such point."
	var nd: Dictionary = nodes()[id]
	var k := int(nd.k)
	var br: Array = BRANCHES[str(nd.b)].nodes
	if rank(g, id) >= max_rank(id):
		return "It is as open as it goes."
	if k in [1, 2] and rank(g, str(br[k - 1].id)) < 1:
		return "The point before it is closed: %s." % str(br[k - 1].n)
	if k in [FORK_L, FORK_R]:
		if rank(g, str(br[2].id)) < 1:
			return "The point before it is closed: %s." % str(br[2].n)
		var other: Dictionary = br[FORK_R if k == FORK_L else FORK_L]
		if rank(g, str(other.id)) > 0:
			return "The channel forks here, and he took the other way: %s." % str(other.n)
	if k == SEAL:
		if rank(g, str(br[FORK_L].id)) < 1 and rank(g, str(br[FORK_R].id)) < 1:
			return "Neither side of the fork is open."
		var dao := str(BRANCHES[str(nd.b)].get("dao", ""))
		if dao != "" and not Braid.holds(g, dao):
			return "Only somebody who walks %s can open it." % str(Data.DAOS[dao].n)
	if spare(g) < cost(id):
		return "It wants %d insight, and he has %d to spend." % [cost(id), spare(g)]
	return ""

## Open the next rank of point `id`.  Returns whether it opened.
static func open(g, id: String) -> bool:
	if why(g, id) != "":
		return false
	var nd: Dictionary = nodes()[id]
	g.channels[id] = rank(g, id) + 1
	g.channels_n = int(g.channels_n) + 1
	g.toast("%s: %s" % [str(nd.n), str(TIERS[mini(rank(g, id), 3)]) if max_rank(id) > 1 else "open"])
	g.note("Opened %s (%s)" % [str(nd.n), str(BRANCHES[str(nd.b)].n)])
	# (a point that grows the body or the dantian fills what it grew)
	g.hp[0] = minf(float(g.max_hp(0)), float(g.hp[0]) + Data.max_hp(int(g.level)) * float(nd.fx.get("hp", 0.0)))
	g.qi[0] = minf(float(g.max_qi(0)), float(g.qi[0]) + Data.max_qi(int(g.level)) * float(nd.fx.get("qi", 0.0)))
	var s: Dictionary = g.cur_step()
	if not s.is_empty() and str(s.kind) == "train":
		g.step_did["train"] = int(g.step_did.get("train", 0)) + 1
		g.poll_steps()
	return true

## What the open points add up to for effect `key` (0 with a closed chart).
static func add(g, key: String) -> float:
	if g.channels.is_empty():
		return 0.0
	var v := 0.0
	var all := nodes()
	for id in g.channels:
		var fx: Dictionary = all[str(id)].fx
		if fx.has(key):
			v += float(fx[key]) * float(int(g.channels[id]))
	return v

## The same as a multiplier (1 with a closed chart).
static func mod(g, key: String) -> float:
	return 1.0 + add(g, key)

## How much harder technique `skill_id` lands for the points he has opened: its phase, and the Gap in the
## Joint for a technique that goes for one foe.
static func power(g, skill_id: String) -> float:
	if g.channels.is_empty():
		return 1.0
	var s: Dictionary = Data.SKILLS[skill_id]
	var m := 1.0 + add(g, str(s.get("elem", "phys")))
	if str(s.get("tgt", "")) == "one":
		m += add(g, "one")
	return m

## The next point of `plan` (ids, a rank each time one is named) that can be opened now: "" if none can.
static func next(g, plan: Array = PLAN) -> String:
	var want := {}
	for id in plan:
		want[id] = int(want.get(id, 0)) + 1
		if rank(g, str(id)) < int(want[id]):
			return str(id) if why(g, str(id)) == "" else ""
	return ""

## How many points have anything open, and how many ranks in all.
static func opened(g) -> int:
	return g.channels.size()

static func ranks(g) -> int:
	var n := 0
	for id in g.channels:
		n += int(g.channels[id])
	return n

## Where point `id` is drawn on a chart whose dantian is at the origin (pixels; y down).
static func pos(id: String) -> Vector2:
	if id == ROOT:
		return Vector2.ZERO
	var nd: Dictionary = nodes()[id]
	var a := TAU * float(ORDER.find(str(nd.b))) / float(ORDER.size()) - PI / 2.0
	var dir := Vector2(cos(a), sin(a))
	var side := Vector2(-dir.y, dir.x)
	var k := int(nd.k)
	var depth := [1.0, 2.0, 3.0, 4.0, 4.0, 5.0][k] as float
	var off := -1.0 if k == FORK_L else (1.0 if k == FORK_R else 0.0)
	return dir * (38.0 + depth * 44.0) + side * off * 24.0

## The lines of the chart: [[from id, to id], ...] (ROOT for the dantian).
static func links() -> Array:
	var out: Array = []
	for b in ORDER:
		var br: Array = BRANCHES[b].nodes
		out.append([ROOT, str(br[0].id)])
		out.append([str(br[0].id), str(br[1].id)])
		out.append([str(br[1].id), str(br[2].id)])
		out.append([str(br[2].id), str(br[FORK_L].id)])
		out.append([str(br[2].id), str(br[FORK_R].id)])
		out.append([str(br[FORK_L].id), str(br[SEAL].id)])
		out.append([str(br[FORK_R].id), str(br[SEAL].id)])
	return out

## What a point does, said for one rank and for what he has of it.
static func fx_text(g, id: String) -> String:
	var nd: Dictionary = nodes()[id]
	var parts: Array = []
	for key in nd.fx:
		var v := float(nd.fx[key])
		parts.append("%s %s" % [str(WORDS.get(str(key), key)), ("+%d%%" % int(round(v * 100.0))) if v < 0.34 and not str(key) in ADDED else ("+%s" % str(snappedf(v, 0.01)))])
	return "%s a rank.  Rank %d of %d, %d insight a rank." % [", ".join(parts), rank(g, id), max_rank(id), cost(id)]

## the keys that are added as they stand, and what each key is called
const ADDED := ["spd", "load", "thrift", "pet_nose", "pet_room", "peace", "insight", "pet_guard", "craft", "craft_forge", "craft_cobble", "craft_carve", "craft_write", "craft_refine", "craft_polish"]
const WORDS := {"hp": "health", "qi": "qi", "atk": "attack", "def": "defence", "spd": "speed", "regen": "qi each turn", "med": "meditation", "phys": "blows of the body",
	"one": "techniques at one foe", "wood": "wood", "thunder": "thunder", "water": "water", "earth": "earth", "fire": "fire", "load": "jin carried", "evade": "blows slipped",
	"exp": "cultivation from battle", "heal": "mending", "taken": "less of every blow", "pill": "pills", "craft": "grades in every craft",
	"craft_forge": "grades at the forge", "craft_cobble": "grades at the last", "craft_carve": "grades at the carving", "craft_write": "grades at the brush", "craft_refine": "grades at the cauldron",
	"craft_polish": "grades at the polishing", "craft_xp": "a craft learned", "thrift": "piece saved", "craft_hours": "quicker making", "insight": "insight again from a first",
	"pet_bond": "a beast's trust", "pet_atk": "the beast's blow", "pet_nose": "piece gathered", "pet_room": "beast kept", "pet_guard": "blow taken for him", "sit": "from a sitting", "peace": "step of peace"}

## What is said of the chart, for the page.
static func text(g) -> String:
	return "Insight: %d to spend (%d in all: %d for the stages he has cultivated, %d from sitting and making; %d spent). %d points open, %d ranks. The whole chart would want %d." % [
		spare(g), earned(g), int(g.level), mini(int(g.insight), INSIGHT_MAX), spent(g), opened(g), ranks(g), total_cost()]
