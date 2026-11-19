class_name Crafts
extends RefCounted
## The crafts of the Daos (the Unblunted Knife release): every one of the six roads has work of the hands
## that is its own, and what the hands make is worn.  The Sword forges, Free Wandering cobbles, the Heart
## carves, the Array writes, the Cauldron refines, the Mirror polishes.
##
## **N**, standing free in open country or in a place of peace (`World.make`; "Not now" first).  A thing
## (`THINGS`, three a craft: `grade` 0 to 2) is made of the goods of the land the hands gather (load.gd,
## toil.gd), takes hours, and comes out **Rough, Sound, Fine or a Masterwork** (`quality`).  Nothing is
## thrown for: the grade is his mastery of the craft (`rank`: five places, by things made), how far he walks
## the road the craft belongs to (a craft can be worked by anybody; whoever walks its road works it a grade
## or more better), how quiet the place is (retreats.gd), what he has opened of the chart (channels.gd), and
## how hard the thing is.  The best thing he has made in each craft is **kept and worn** (`Game.kept`:
## craft -> {id, q}) and changes one number through `Crafts.mod` / `Crafts.add` (1 and 0 with nothing kept);
## anything less is set aside.  It is on nobody's counter and weighs nothing.
##
## Each craft is worked on a clip the party already carries, with something held that already has a model,
## at a bench that is drawn while he works and stood on no tile (`Crafts.bench`).
##
## New step kind "craft" (`n` things made since the step began; `craft`: of that craft; `thing`: that thing;
## `"good": true`: that came out Sound or better).  The bot makes `Crafts.wanted(s)` and gathers what it
## lacks with its own hands.  **A new thing** needs a line in `THINGS` made of goods of `Load.GOODS`; a new
## craft a road of `Data.DAO_ORDER` that has none, a clip the party has, and three things.

const CRAFTS := {
	"forge": {"n": "Forging", "dao": "sword", "key": "atk", "clip": "hammer", "hold": "hammer", "verb": "forges", "worn": "at the hilt", "col": Color("c8d8e8"),
		"desc": "Iron heated, folded and drawn out. What the Sword's road makes is carried on the sword: a guard, a collar, an edge.", "things": ["plain_guard", "folded_collar", "gapless_edge"]},
	"cobble": {"n": "Cobbling", "dao": "wander", "key": "spd", "clip": "sew", "hold": "", "verb": "cobbles", "worn": "on his feet", "col": Color("a8e0c8"),
		"desc": "Straw, hemp and hide for the feet. Whoever means to go a thousand li looks to his soles first.", "things": ["straw_sandals", "hemp_soles", "traceless_boots"]},
	"carve": {"n": "Carving", "dao": "heart", "key": "hp", "clip": "carve", "hold": "chisel", "verb": "carves", "worn": "at his wrist", "col": Color("f0a8b0"),
		"desc": "Wood and stone cut to what was already in them. The Heart's road carves beads to count the breath on.", "things": ["peach_beads", "stone_fish", "bell_stand"]},
	"write": {"n": "Writing", "dao": "formation", "key": "def", "clip": "write", "hold": "brush", "verb": "writes", "worn": "in his sash", "col": Color("d8c890"),
		"desc": "Wards brushed on slips, flags and plates. An array is a sentence the ground is made to keep.", "things": ["ward_slip", "nine_flags", "turtle_plate"]},
	"refine": {"n": "Refining", "dao": "alchemy", "key": "qi", "clip": "pound", "hold": "pestle", "verb": "refines", "worn": "in a gourd at his belt", "col": Color("e8b070"),
		"desc": "Herbs ground, steeped and reduced. What the Cauldron's road makes is kept in a gourd and breathed, not swallowed.", "things": ["herb_paste", "pine_resin_pill", "nine_turn_cinnabar"]},
	"polish": {"n": "Polishing", "dao": "illusion", "key": "taken", "clip": "wash", "hold": "", "verb": "polishes", "worn": "over his heart", "col": Color("c8a8f0"),
		"desc": "Stone and bronze rubbed until they answer. A mirror worn over the heart is struck first.", "things": ["river_stone", "bronze_mirror", "dustless_mirror"]},
}
const ORDER := ["forge", "cobble", "carve", "write", "refine", "polish"]

## `needs`: goods of load.gd; `hours`; `min`: the place in the craft it is first made at; `k`: what it gives a
## quality step (a share of the craft's number; whole points of speed for the cobbler)
const THINGS := {
	"plain_guard": {"craft": "forge", "grade": 0, "n": "Plain Iron Guard", "needs": {"stone_block": 1, "timber": 1}, "hours": 2.0, "min": 0, "k": 0.004,
		"desc": "A guard of plain iron, beaten flat on a stone and quenched in whatever was to hand."},
	"folded_collar": {"craft": "forge", "grade": 1, "n": "Hundred-Fold Collar", "needs": {"ore_lump": 2, "timber": 1}, "hours": 4.0, "min": 1, "k": 0.008,
		"desc": "A blade-collar folded until the layers cannot be counted, so that the sword sits in its guard like a tooth in a jaw."},
	"gapless_edge": {"craft": "forge", "grade": 2, "n": "The Edge with No Thickness", "needs": {"ore_lump": 3, "timber": 2, "jade_rough": 1}, "hours": 8.0, "min": 3, "k": 0.015,
		"desc": "\"There are spaces between the joints, and the edge of the blade has no thickness.\" An edge-fitting drawn out so fine it is seen only from the side."},
	"straw_sandals": {"craft": "cobble", "grade": 0, "n": "Straw Sandals", "needs": {"herb_bundle": 3}, "hours": 1.5, "min": 0, "k": 0.34,
		"desc": "Sandals plaited of green stalks, the way every child on the mountain is taught and nearly every child forgets."},
	"hemp_soles": {"craft": "cobble", "grade": 1, "n": "Thousand-Layer Soles", "needs": {"herb_bundle": 4, "wild_yam": 2}, "hours": 4.0, "min": 1, "k": 0.5,
		"desc": "Cloth soles of a thousand layers, each pasted with yam starch and stitched through. They outlast the feet in them."},
	"traceless_boots": {"craft": "cobble", "grade": 2, "n": "Boots That Leave No Track", "needs": {"herb_bundle": 5, "wild_yam": 2, "carp": 3}, "hours": 8.0, "min": 3, "k": 0.75,
		"desc": "\"A good walker leaves no track.\" Soft boots soled with fish-skin, scale outward, that take hold of wet rock and let go of it silently."},
	"peach_beads": {"craft": "carve", "grade": 0, "n": "Peach-Wood Beads", "needs": {"timber": 1}, "hours": 2.0, "min": 0, "k": 0.005,
		"desc": "Eighteen beads cut from a billet of timber and strung on a boot-lace, for counting breaths on."},
	"stone_fish": {"craft": "carve", "grade": 1, "n": "Wooden Fish", "needs": {"timber": 1, "mushrooms": 2}, "hours": 4.0, "min": 1, "k": 0.01,
		"desc": "A hollow fish to tap the hours on, rubbed dark with a paste of mushrooms. A fish does not shut its eyes, so it is carved to keep whoever taps it awake."},
	"bell_stand": {"craft": "carve", "grade": 2, "n": "A Bell-Stand in Little", "needs": {"timber": 2, "jade_rough": 1}, "hours": 8.0, "min": 3, "k": 0.018,
		"desc": "\"Those who saw it were amazed, as if it were the work of spirits.\" A bell-stand a hand high, with a jade bell that does not ring."},
	"ward_slip": {"craft": "write", "grade": 0, "n": "Ward Slip", "needs": {"timber": 1, "herb_bundle": 1}, "hours": 1.5, "min": 0, "k": 0.006,
		"desc": "A slip of split timber with one character brushed on it in green juice. The character is 'stop'."},
	"nine_flags": {"craft": "write", "grade": 1, "n": "Nine Palace Flags", "needs": {"timber": 2, "herb_bundle": 2}, "hours": 4.0, "min": 1, "k": 0.012,
		"desc": "Nine little flags inked in the black of burnt timber, one for each palace of the square. Stood in a sash they still know which way is north."},
	"turtle_plate": {"craft": "write", "grade": 2, "n": "Turtle-Back Plate", "needs": {"stone_block": 1, "timber": 1, "jade_rough": 1}, "hours": 8.0, "min": 3, "k": 0.02,
		"desc": "The diagram that came up out of the Luo on a turtle's back, cut into a stone plate and filled with jade dust. Every row adds to fifteen."},
	"herb_paste": {"craft": "refine", "grade": 0, "n": "Green Paste", "needs": {"herb_bundle": 3}, "hours": 1.5, "min": 0, "k": 0.005,
		"desc": "Herbs pounded to a paste and rolled into a pellet. It smells of a cut lawn and tastes exactly as that suggests."},
	"pine_resin_pill": {"craft": "refine", "grade": 1, "n": "Pine-Resin Pill", "needs": {"herb_bundle": 3, "mushrooms": 2, "timber": 1}, "hours": 4.0, "min": 1, "k": 0.01,
		"desc": "Resin sweated out of timber over a slow fire, with nine herbs and two mushrooms. The hermits of every mountain live on it and complain of it."},
	"nine_turn_cinnabar": {"craft": "refine", "grade": 2, "n": "Nine-Turn Cinnabar", "needs": {"ore_lump": 2, "timber": 2, "herb_bundle": 4}, "hours": 8.0, "min": 3, "k": 0.018,
		"desc": "Ore roasted red over a timber fire, quenched and roasted again, nine times. Not to be eaten. It is kept stoppered, and the gourd is breathed from."},
	"river_stone": {"craft": "polish", "grade": 0, "n": "Rubbed River Stone", "needs": {"stone_block": 1}, "hours": 2.0, "min": 0, "k": 0.004,
		"desc": "A flat of stone rubbed on another with sand and water until it shows the sky, very faintly, and nothing else."},
	"bronze_mirror": {"craft": "polish", "grade": 1, "n": "Bronze Mirror", "needs": {"ore_lump": 2, "carp": 2}, "hours": 4.0, "min": 1, "k": 0.008,
		"desc": "A disc of bright metal polished with fish-skin and its own dust. It shows a face a little kinder than the face."},
	"dustless_mirror": {"craft": "polish", "grade": 2, "n": "The Mirror with No Dust", "needs": {"ore_lump": 3, "jade_rough": 1, "carp": 2}, "hours": 8.0, "min": 3, "k": 0.014,
		"desc": "\"If a mirror is bright, dust will not settle on it.\" Rubbed until there is nothing on it to rub. It sends nothing away and keeps nothing."},
}

## the five places of a craft, by what has been learned at it (a thing made teaches 1, 2 or 4 by its grade)
const RANK_AT := [0, 3, 8, 16, 30]
const RANK_NAMES := ["Raw Hand", "Apprentice", "Journeyman", "Artisan", "Master"]
const QUALITIES := ["Rough", "Sound", "Fine", "Masterwork"]
const LEARN := [1, 2, 4]
## what the place adds to the grade a thing comes out at, by how quiet it is (retreats.gd: 0 troubled or no
## place at all, 1 quiet, 2 still, 3 deep peace)
const PEACE_K := [0.0, 1.0, 2.0, 3.0]
const ASK := "The work of the hands: what is made?"
## what is said as a thing comes out, by quality
const SAID := [
	"%s: made. It will do what one does. Nobody would ask who made it.",
	"%s: made, and sound: square where it should be square. The hands knew a little more than he did.",
	"%s: made, and fine. He turns it over twice, looking for the place where he hurried, and there is none.",
	"%s: made, and he does not remember the making. The work went in at the eyes and came out at the hands, and he was not asked.",
]

static func craft_of(thing: String) -> String:
	return str(THINGS[thing].craft)

static func xp(g, craft: String) -> int:
	return int(g.craft_xp.get(craft, 0))

## His place in craft `craft`: 0 (a raw hand) to 4 (a master).
static func rank(g, craft: String) -> int:
	var x := xp(g, craft)
	var r := 0
	for k in RANK_AT.size():
		if x >= int(RANK_AT[k]):
			r = k
	return r

## What walking the craft's own road is worth to it: nothing to somebody who does not, a grade to a novice
## of the road, two to an adept, three to a master.
static func road(g, craft: String) -> int:
	var dao := str(CRAFTS[craft].dao)
	if not Braid.holds(g, dao):
		return 0
	return 1 + int(g.dao_tier(dao))

## The score a thing would be made at here (`peace`: 0 to 3), and the quality that is (0 Rough to 3 a Masterwork).
static func score(g, thing: String, peace: int = 0) -> float:
	var t: Dictionary = THINGS[thing]
	var c := str(t.craft)
	return float(rank(g, c)) + float(road(g, c)) + float(PEACE_K[clampi(peace, 0, 3)]) + Channels.add(g, "craft") + Channels.add(g, "craft_" + c) - 2.0 * float(int(t.grade)) - 1.0

static func quality(g, thing: String, peace: int = 0) -> int:
	return clampi(int(floor(score(g, thing, peace) / 2.0)), 0, 3)

## What a making of `thing` asks for, after what the Offcut Kept saves: good -> n.
static func needs(g, thing: String) -> Dictionary:
	var out: Dictionary = (THINGS[thing].needs as Dictionary).duplicate()
	var save := int(Channels.add(g, "thrift"))
	if save > 0:
		var first := str(out.keys()[0])
		out[first] = maxi(1, int(out[first]) - save)
	return out

## What he lacks for it: good -> how many more.
static func missing(g, thing: String) -> Dictionary:
	var out := {}
	var nd := needs(g, thing)
	for good in nd:
		var lack := int(nd[good]) - int(g.inv.get(good, 0))
		if lack > 0:
			out[good] = lack
	return out

static func hours(g, thing: String) -> float:
	return float(THINGS[thing].hours) * maxf(0.4, 1.0 - Channels.add(g, "craft_hours"))

## Why `thing` cannot be made now ("" if it can).
static func blocked(g, thing: String) -> String:
	if not THINGS.has(thing):
		return "There is no such thing to make."
	var t: Dictionary = THINGS[thing]
	if rank(g, str(t.craft)) < int(t.min):
		return "That is %s's work. He is %s at %s." % [_a(str(RANK_NAMES[int(t.min)])), _a(str(RANK_NAMES[rank(g, str(t.craft))])), str(CRAFTS[str(t.craft)].n).to_lower()]
	var ms := missing(g, thing)
	if not ms.is_empty():
		var parts: Array = []
		for good in ms:
			parts.append("%d more %s" % [int(ms[good]), str(Data.ITEMS[str(good)].n)])
		return "He lacks %s." % ", ".join(parts)
	return ""

static func _a(s: String) -> String:
	return ("an " if s.substr(0, 1) in ["A", "E", "I", "O", "U"] else "a ") + s

## What a kept thing is worth (the better is kept): its grade and how it came out.
static func worth(thing: String, q: int) -> float:
	return float(THINGS[thing].k) * float(q + 1)

## Make `thing` here.  Returns {"ok", "why", "q", "kept", "lines"}.  What it is made of is used up, the hours
## pass, the craft is learned, and the best of each craft is kept.
static func make(g, thing: String, peace: int = 0) -> Dictionary:
	var why := blocked(g, thing)
	if why != "":
		return {"ok": false, "why": why}
	var t: Dictionary = THINGS[thing]
	var c := str(t.craft)
	var q := quality(g, thing, peace)
	var nd := needs(g, thing)
	for good in nd:
		g.inv[good] = int(g.inv.get(good, 0)) - int(nd[good])
		if int(g.inv[good]) <= 0:
			g.inv.erase(good)
	var before := rank(g, c)
	g.craft_xp[c] = xp(g, c) + int(round(float(LEARN[int(t.grade)]) * Channels.mod(g, "craft_xp")))
	g.crafted_n = int(g.crafted_n) + 1
	g.crafted[thing] = maxi(int(g.crafted.get(thing, -1)), q)
	Clock.set_hour(g, Clock.hour(g) + hours(g, thing))
	var lines: Array = [str(SAID[q]) % str(t.n)]
	var kept := false
	var old: Dictionary = g.kept.get(c, {})
	if old.is_empty() or worth(thing, q) > worth(str(old.id), int(old.q)):
		g.kept[c] = {"id": thing, "q": q}
		kept = true
		lines.append("He wears it %s: %s." % [str(CRAFTS[c].worn), effect_text(c, thing, q)])
	else:
		lines.append("What he wears %s is better. This one is set aside for whoever comes by wanting one." % str(CRAFTS[c].worn))
	if rank(g, c) > before:
		lines.append("%s: he is %s now." % [str(CRAFTS[c].n), _a(str(RANK_NAMES[rank(g, c)]))])
	if q == 3 and not g.masterworks.has(c):
		g.masterworks[c] = thing
		var got := Channels.learn(g, 1 + int(Channels.add(g, "insight")), "the first masterwork of %s" % str(CRAFTS[c].n).to_lower())
		if got > 0:
			lines.append("A first masterwork. Insight: +%d." % got)
	g.note("Made %s (%s)" % [str(t.n), str(QUALITIES[q])])
	var s: Dictionary = g.cur_step()
	if not s.is_empty() and str(s.kind) == "craft" and (not s.has("craft") or str(s.craft) == c) and (not s.has("thing") or str(s.thing) == thing) and (not bool(s.get("good", false)) or q >= 1):
		g.step_did["craft"] = int(g.step_did.get("craft", 0)) + 1
		g.poll_steps()
	return {"ok": true, "why": "", "q": q, "kept": kept, "lines": lines}

## What the thing kept of the craft whose number is `key` multiplies it by (1 with nothing kept).  Blows that
## reach him are made less ("taken"); everything else is made more.
static func mod(g, key: String) -> float:
	if g.kept.is_empty() or key == "spd":
		return 1.0
	for c in g.kept:
		if str(CRAFTS[str(c)].key) == key:
			var w := worth(str(g.kept[c].id), int(g.kept[c].q))
			return 1.0 - w if key == "taken" else 1.0 + w
	return 1.0

## What the cobbler's work adds to his speed (0 with nothing kept).
static func add(g, key: String) -> float:
	if key != "spd" or not g.kept.has("cobble"):
		return 0.0
	return floor(worth(str(g.kept.cobble.id), int(g.kept.cobble.q)))

static func effect_text(craft: String, thing: String, q: int) -> String:
	var w := worth(thing, q)
	match str(CRAFTS[craft].key):
		"spd":
			return "speed +%d" % int(floor(w))
		"taken":
			return "every blow that reaches him %.1f%% less" % (w * 100.0)
		"atk":
			return "attack +%.1f%%" % (w * 100.0)
		"def":
			return "defence +%.1f%%" % (w * 100.0)
		"hp":
			return "health +%.1f%%" % (w * 100.0)
		_:
			return "qi +%.1f%%" % (w * 100.0)

## The thing a "craft" step is asking for (the bot makes it): the step's own, or the plainest of its craft.
static func wanted(s: Dictionary) -> String:
	if s.has("thing"):
		return str(s.thing)
	return str(CRAFTS[str(s.get("craft", "forge"))].things[0])

## Everything that can be made, craft by craft, for the choice and the page:
## [{craft, thing, n, q (what it would come out as here), why}].
static func offers(g, peace: int = 0) -> Array:
	var out: Array = []
	for c in ORDER:
		for th in CRAFTS[c].things:
			out.append({"craft": c, "thing": str(th), "n": str(THINGS[th].n), "q": quality(g, str(th), peace), "why": blocked(g, str(th))})
	return out

static func needs_text(g, thing: String) -> String:
	var parts: Array = []
	var nd := needs(g, thing)
	for good in nd:
		parts.append("%d %s (%d)" % [int(nd[good]), str(Data.ITEMS[str(good)].n), int(g.inv.get(good, 0))])
	return ", ".join(parts)

## The bench drawn in front of him while he works (stood on no tile): a block, and on it what the craft is
## worked on.  Built from code.
static func bench(craft: String) -> Node3D:
	var root := Node3D.new()
	var g := MB.new()
	var wood := MB.tag(Color("7a5a3a"), MB.WOOD)
	var col: Color = CRAFTS[craft].col
	match craft:
		"forge":
			# an anvil on a stump, and a bar on it
			g.cyl(Vector3(0, 0.22, 0), 0.26, 0.44, wood, Vector3.ZERO, 10)
			g.box(Vector3(0, 0.52, 0), Vector3(0.4, 0.16, 0.2), Color("4a4a52"))
			g.box(Vector3(0.24, 0.52, 0), Vector3(0.16, 0.08, 0.12), Color("4a4a52"))
			g.box(Vector3(0, 0.63, 0), Vector3(0.34, 0.04, 0.05), Color("e88a3a"))
		"cobble":
			# a last on a low bench, and a hank of straw
			g.box(Vector3(0, 0.2, 0), Vector3(0.6, 0.06, 0.3), wood)
			for sx in [-0.24, 0.24]:
				g.box(Vector3(sx, 0.09, 0), Vector3(0.06, 0.18, 0.26), wood)
			g.box(Vector3(-0.1, 0.3, 0), Vector3(0.24, 0.1, 0.1), col.darkened(0.3))
			g.cyl(Vector3(0.2, 0.27, 0), 0.07, 0.08, Color("c8b060"), Vector3.ZERO, 8)
		"carve":
			# a billet stood in a vice of two stones
			g.box(Vector3(-0.16, 0.12, 0), Vector3(0.14, 0.24, 0.22), Color("8a8a88"))
			g.box(Vector3(0.16, 0.12, 0), Vector3(0.14, 0.24, 0.22), Color("8a8a88"))
			g.cyl(Vector3(0, 0.34, 0), 0.09, 0.56, Color("c89a6a"), Vector3.ZERO, 10)
		"write":
			# a low table, a slip, an ink-stone
			g.box(Vector3(0, 0.26, 0), Vector3(0.66, 0.05, 0.36), wood)
			for sx2 in [-0.28, 0.28]:
				g.box(Vector3(sx2, 0.12, 0), Vector3(0.05, 0.24, 0.3), wood)
			g.box(Vector3(-0.08, 0.3, 0), Vector3(0.1, 0.012, 0.3), Color("e8dcc0"))
			g.cyl(Vector3(0.2, 0.3, 0.06), 0.06, 0.03, Color("2a2a30"), Vector3.ZERO, 10)
		"refine":
			# a mortar on a stone, and a little pot
			g.box(Vector3(0, 0.1, 0), Vector3(0.5, 0.2, 0.4), Color("8a8a88"))
			g.cyl(Vector3(-0.08, 0.28, 0), 0.13, 0.16, Color("6a6a70"), Vector3.ZERO, 12)
			g.cyl(Vector3(0.18, 0.26, 0.06), 0.07, 0.12, col.darkened(0.2), Vector3.ZERO, 10)
		_:
			# a flat stone, a disc on it, a bowl of water
			g.box(Vector3(0, 0.12, 0), Vector3(0.56, 0.24, 0.4), Color("8a8a88"))
			g.cyl(Vector3(-0.06, 0.255, 0), 0.14, 0.02, Color("d8c890"), Vector3.ZERO, 16)
			g.cyl(Vector3(0.2, 0.28, 0.08), 0.07, 0.06, Color("5a7a9a"), Vector3.ZERO, 10)
	MB.mesh_node(root, g.build(MB.mat_plain()))
	return root

## What is said of the crafts, for the page: [{craft, n, dao, rank, xp, next, kept, road}].
static func page(g) -> Array:
	var out: Array = []
	for c in ORDER:
		var r := rank(g, c)
		var k: Dictionary = g.kept.get(c, {})
		out.append({"craft": c, "n": str(CRAFTS[c].n), "dao": str(Data.DAOS[str(CRAFTS[c].dao)].n), "rank": str(RANK_NAMES[r]), "xp": xp(g, c),
			"next": int(RANK_AT[r + 1]) if r + 1 < RANK_AT.size() else -1, "road": road(g, c), "col": CRAFTS[c].col,
			"kept": "" if k.is_empty() else "%s (%s): %s" % [str(THINGS[str(k.id)].n), str(QUALITIES[int(k.q)]), effect_text(c, str(k.id), int(k.q))]})
	return out
