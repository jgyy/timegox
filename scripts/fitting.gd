class_name Fitting
extends RefCounted
## The fitness of things (the Ordered House release).  People are particular about what stands where in
## their own houses, and they are right to be: a bed that looks straight out of the door, a mirror that
## faces a sleeper, a stove with no water by it.  Three things come of it:
##
##  * **Every lived-in house may want something** (`want`): read from the furniture the house really
##    has and where its door really is (a fault first: bed and door in a line, mirror by a bed, a fire
##    with no water near; else something the household has always meant to see to).  Whoever lives
##    there says so (`complaint`), and it is put right by setting the right thing down at the right
##    piece of furniture (`set_down`): the house is *put to rights* (`g.fitted`), once.
##  * **Things can be set down anywhere in a house** (`THINGS`, `options`, `set_down`, `take_up`), and
##    whoever lives there has an opinion (`verdict`): right, wrong (`bad`: a broom by the altar, a lamp
##    by the books, an orchid by the stove), or merely suffered.  What is set down is drawn where it was
##    put (`model`) and stays until it is taken up; a thing left where it should not be is remembered.
##  * **Nobody likes their things handled** (`touched`): the first time a piece of a lived-in house is
##    used, whoever lives there says what they think of it.
##
## Household things weigh nothing (load.gd: only bulk weighs) and are sent out for at the door of the
## house that wants one (`price`: worth less than the road).  Nothing is placed in the world for any of
## this: a spot is a piece of furniture that already stands (`furn:<area>:<building>:<k>`), so no map
## moves.  New step kind `"fit"` (`n` houses put to rights since the step began); the bot goes to the
## nearest house that wants something (`wanted`), and sets it down.  No trial or ending needs a house.

## the household things: what each is, and where it belongs (`good`: kinds of furniture), where it must
## never stand (`bad`: kind -> what is said), `on`: stood on the piece rather than beside it
const THINGS := {
	"bead_curtain": {"n": "Bead Curtain", "good": ["bed"], "on": false,
		"bad": {"stove": "Beads over a stove! They will be black in a week and in the soup in two.", "altar": "You do not hang a curtain in front of the ancestors. They like to see who comes in."}},
	"mirror_cloth": {"n": "Mirror Cloth", "good": ["mirror"], "on": true,
		"bad": {"altar": "A cloth over the altar is for a house in mourning. Take it off. Take it off now.", "table": "That is a mirror cloth, not a table cloth. My mother would rise up."}},
	"water_jar": {"n": "Jar of Water", "good": ["stove", "hearth", "cauldron"], "on": false,
		"bad": {"bed": "Water at the head of a bed! The damp gets into the quilt and the quilt into the chest.", "bookshelf": "Water by the books. Water. By the books.", "altar": "Not there. That is where the offering bowl goes, and it is not a wash-place."}},
	"incense_burner": {"n": "Incense Burner", "good": ["altar", "statue"], "on": true,
		"bad": {"bed": "Incense by a bed is for the sick and the dead. Which did you take me for?", "stove": "The Kitchen God has his own smoke. He does not want yours in it.", "grain_bin": "Ash in the millet. No."}},
	"orchid": {"n": "Pot of Orchids", "good": ["window", "desk", "table"], "on": true,
		"bad": {"stove": "An orchid by the stove is a cooked orchid. They are not vegetables.", "altar": "Flowers that are still in earth do not go before the dead. Cut ones. Everybody knows that.", "anvil": "It will be dead of the heat and the hammering by noon, and I shall be blamed."}},
	"oil_lamp": {"n": "Oil Lamp", "good": ["desk", "table", "workbench", "counter"], "on": true,
		"bad": {"bookshelf": "A flame on a shelf of paper. Were you raised in a kiln?", "loom": "One spark in the warp and there goes a winter's work.", "bed": "A lamp at the bed-head is how half the fires in this street began. On the table, where a body can see it."}},
	"house_broom": {"n": "House Broom", "good": ["cabinet", "rack", "shelf", "barrel", "chest"], "on": false,
		"bad": {"altar": "A broom by the altar sweeps the ancestors out of the house. Move it before my husband sees.", "bed": "A broom by the bed sweeps the luck out from under whoever sleeps there.", "stove": "The Kitchen God reports once a year, and you want him to say we keep the broom in his face?", "table": "Brooms do not go where food goes. I should not have to say so."}},
}
const ORDER := ["bead_curtain", "mirror_cloth", "water_jar", "incense_burner", "orchid", "oil_lamp", "house_broom"]

## what the house says it wants, and what it says when it has it: thing -> [complaint, thanks]
const WORDS := {
	"bead_curtain": ["The bed looks straight out of the door. Feet first through a door is how the dead are carried. I have not slept a whole night in that bed. A curtain of beads at it would break the line.",
		"There. The line is broken; you can hear it click when the draught comes in. I shall sleep tonight with my feet where they like."],
	"mirror_cloth": ["The mirror faces the bed. Wake in the night and there is somebody looking at you, and it is you, which is worse. It wants a cloth over it, and I have never had the right cloth.",
		"Covered. Now whoever is in the mirror can sleep as well. It is a good cloth; you have folded it the wrong way, but I shall see to that."],
	"water_jar": ["There is a fire in this room and no water within two steps of it. My grandmother's house went that way, in the time it takes to say so. A full jar should stand by the stove. It never has.",
		"A full jar, by the fire, where a hand finds it without the eyes. Good. A finger's width to the left would be better. No, leave it. I shall do it."],
	"incense_burner": ["Nothing has burned here since the old burner cracked. The shelf remembers; you can see the ring. Whoever is honoured in this house has gone hungry for smoke a long while.",
		"Squarely on the old ring, as if it had never been away. They will have noticed already. They notice everything; it is what they are for."],
	"orchid": ["The light comes in there every morning and falls on nothing. It has annoyed me for eleven years. An orchid should stand in it. One. Not a bush; an orchid.",
		"One orchid, in the light, with the leaf turned so. I have wanted to see that every morning for eleven years. Do not touch it. Do not water it either; that is mine to forget."],
	"oil_lamp": ["We work here after dark by a lamp that hangs behind our own heads, so that every hand is in its own shadow. A lamp on the board itself, on the left, is all it wants. Nobody has gone for one.",
		"On the left, so the right hand casts no shadow on the work. You were told that, or you guessed. Either way it is where it should be, which is more than I can say for most things."],
	"house_broom": ["The broom in this house lives wherever it was last dropped. I find it in my way three times a day. A broom has a place: upright, bristles up, out of sight beside the store.",
		"Upright, bristles up, where nobody will meet it in the dark. That is the first thing in this house that has been where I expect it since I married into it."],
}
## what is said of a thing set down where it neither belongs nor offends
const SUFFERED := ["It may stand there, I suppose. I shall move it when you have gone.", "Hm. There. Well. It is not where I should have put it. Nothing is.", "If you like. It will be in somebody's way by supper; I shall see whose."]
## what is said the first time a piece of the house is handled, by kind (else the last three)
const TOUCHED := {
	"bed": "That is a bed that has been made. Was a bed that had been made.",
	"chest": "The hasp on that chest sits a hair to the left when it has been opened. It is sitting a hair to the left.",
	"cabinet": "Third shelf, the blue bowl goes rim down. It was rim down. I shall look in a moment and I hope to find it rim down.",
	"grain_bin": "We keep a line scratched in that bin. I can tell a hand has been in it by the dust on the line.",
	"mirror": "Breathe on it if you must, but polish it after. With the sleeve, not the palm.",
	"loom": "Forty threads to the inch and every one of them knows when a stranger has leaned on the beam.",
	"altar": "Bow first. Then look. Then, if you must, touch. You have done those in the wrong order.",
	"table": "Elbows. No, it is nothing. Only that we oil that table, and now it will have to be oiled again.",
	"stove": "Do not lift the lid. You have lifted the lid. Now it will take the length of a meal to come back to the boil.",
	"": ["Everything in this room has a place, and you have just had your hand on one of the places.", "I do not mind. I only like to know what has been moved, so that I can move it back.", "Put it down exactly as it was. No. Exactly."],
}

## what a boy sent to the market asks for a household thing, by realm (worth less than the road)
const PRICE := 8
const PRICE_REALM := 3
## what a house put to rights gives, by realm
const THANKS := 14
const THANKS_REALM := 7

# ---------------------------------------------------------------- the houses
static var _cache := {}

## What is known of a realm's houses: {houses: {key -> {bd, res, furn: {k -> ent}}}, by_spot: {ent id -> key}}.
static func _index(wd: Dictionary) -> Dictionary:
	var lid := "%d|%d|%d|%d" % [int(wd.get("w", 0)), int(wd.get("h", 0)), (wd.get("ents", []) as Array).size(), (wd.get("buildings", []) as Array).size()]
	if _cache.has(lid):
		return _cache[lid]
	var houses := {}
	var by_spot := {}
	for bd in wd.get("buildings", []):
		houses["%s:%s" % [str(bd.get("area", "")), str(bd.id)]] = {"bd": bd, "res": "", "n": "", "furn": {}}
	for e in wd.get("ents", []):
		var id := str(e.get("id", ""))
		if id.begins_with("res:"):
			var p := id.split(":")
			var hk := "%s:%s" % [p[1], p[2]]
			if houses.has(hk) and str(houses[hk].res) == "":
				houses[hk].res = id
				houses[hk].n = str(e.get("n", "Somebody"))
		elif id.begins_with("furn:") and not bool(e.get("walk", false)):
			var p2 := id.split(":")
			if p2.size() == 4:
				var hk2 := "%s:%s" % [p2[1], p2[2]]
				if houses.has(hk2):
					houses[hk2].furn[int(p2[3])] = e
					by_spot[id] = hk2
	if _cache.size() > 12:
		_cache.clear()
	var out := {"houses": houses, "by_spot": by_spot}
	_cache[lid] = out
	return out

## The house (its key, "<area>:<building>") a piece of furniture belongs to, or "".
static func house_of(wd: Dictionary, spot: String) -> String:
	return str(_index(wd).by_spot.get(spot, ""))

## The name of whoever lives in house `hk` ("" if nobody does).
static func resident(wd: Dictionary, hk: String) -> String:
	var h: Dictionary = _index(wd).houses.get(hk, {})
	return str(h.get("n", "")) if str(h.get("res", "")) != "" else ""

## Who answers for house `hk` now: whoever lives there, or whoever came after somebody he struck down (crime.gd).
static func keeper(g, wd: Dictionary, hk: String) -> String:
	var h: Dictionary = _index(wd).houses.get(hk, {})
	if str(h.get("res", "")) != "" and not g.slain.is_empty() and Crime.dead(g, str(h.res)):
		return "Whoever has the house now"
	return resident(wd, hk)

static func _near(a: Vector2i, b: Vector2i, r: int) -> bool:
	return maxi(absi(a.x - b.x), absi(a.y - b.y)) <= r

## What house `hk` wants: {thing, spot (the furniture entity's id), kind, fault} or {} (nobody lives
## there, or nothing in it is out of place).  Read from what really stands in it.
static func want(wd: Dictionary, hk: String) -> Dictionary:
	var h: Dictionary = _index(wd).houses.get(hk, {})
	if h.is_empty() or str(h.res) == "" or (h.furn as Dictionary).is_empty():
		return {}
	var bd: Dictionary = h.bd
	var furn: Dictionary = h.furn
	var ks: Array = furn.keys()
	ks.sort()
	var of_kind := func(kinds: Array) -> Array:
		var out: Array = []
		for k in ks:
			if kinds.has(str(furn[k].furn)):
				out.append(furn[k])
		return out
	var mk := func(thing: String, e: Dictionary, fault: bool) -> Dictionary:
		return {"thing": thing, "spot": str(e.id), "kind": str(e.furn), "fault": fault, "house": hk}
	# a bed in a line with the door
	var door: Vector2i = bd.get("door", Vector2i(-99, -99))
	if door.x > -99:
		var dw := door
		for b in of_kind.call(["bed"]):
			var bp: Vector2i = b.pos
			if (bp.x == dw.x and absi(bp.y - dw.y) <= 5) or (bp.y == dw.y and absi(bp.x - dw.x) <= 5):
				return mk.call("bead_curtain", b, true)
	# a mirror by a bed
	for m in of_kind.call(["mirror"]):
		for b2 in of_kind.call(["bed"]):
			if _near(m.pos, b2.pos, 2):
				return mk.call("mirror_cloth", m, true)
	# a fire with no water near it
	for f in of_kind.call(["stove", "hearth", "cauldron"]):
		var wet := false
		for w in of_kind.call(["tub", "washstand", "barrel", "wine_jar"]):
			wet = wet or _near(f.pos, w.pos, 2)
		if not wet:
			return mk.call("water_jar", f, true)
	# else what the household has always meant to see to, by the house's own lot
	var lot := absi(hash(hk))
	var rest: Array = []
	for pr in [["incense_burner", ["altar", "statue"]], ["orchid", ["window", "desk", "table"]], ["oil_lamp", ["desk", "table", "workbench", "counter"]], ["house_broom", ["cabinet", "rack", "shelf", "barrel", "chest"]]]:
		var es: Array = of_kind.call(pr[1])
		if not es.is_empty():
			rest.append(mk.call(str(pr[0]), es[lot % es.size()], false))
	if rest.is_empty() or lot % 4 == 3:
		return {}
	return rest[(lot / 4) % rest.size()]

## Whether house `hk` has been put to rights.
static func is_fitted(g, hk: String) -> bool:
	return g.fitted.has(hk)

## What whoever lives in `hk` says is wrong with it ("" if nothing is, or it has been seen to).
static func complaint(g, wd: Dictionary, hk: String) -> String:
	var w := want(wd, hk)
	if w.is_empty() or is_fitted(g, hk):
		return ""
	return str(WORDS[str(w.thing)][0])

## The houses of region `area` that still want something: [want].
static func wants_in(g, wd: Dictionary, area: String) -> Array:
	var out: Array = []
	var hs: Dictionary = _index(wd).houses
	var ks: Array = hs.keys()
	ks.sort()
	for hk in ks:
		if str(hk).begins_with(area + ":") and not is_fitted(g, str(hk)):
			var w := want(wd, str(hk))
			if not w.is_empty():
				out.append(w)
	return out

## How many houses of the realm want something at all (fitted or not).
static func count(wd: Dictionary, area: String = "") -> int:
	var n := 0
	for hk in _index(wd).houses:
		if (area == "" or str(hk).begins_with(area + ":")) and not want(wd, str(hk)).is_empty():
			n += 1
	return n

# ---------------------------------------------------------------- setting down, taking up
static func price(g) -> int:
	return PRICE + PRICE_REALM * int(g.realm())

static func thanks(g) -> int:
	return THANKS + THANKS_REALM * int(g.realm())

## What stands at `spot` ("" if nothing).
static func at(g, spot: String) -> String:
	return str(g.placed.get(spot, "")).get_slice("|", 0)

## How a thing set down at a piece of furniture of kind `kind` is taken: 1 right, -1 wrong, 0 suffered.
static func verdict(thing: String, kind: String) -> int:
	var t: Dictionary = THINGS[thing]
	if (t.good as Array).has(kind):
		return 1
	return -1 if (t.bad as Dictionary).has(kind) else 0

## What can be done at piece of furniture `e` of a lived-in house: [{id, label, desc, enabled}] ([] when
## there is nothing to offer: no house, nobody home, nothing carried, nothing wanted here, nothing set).
static func options(g, wd: Dictionary, e: Dictionary) -> Array:
	var spot := str(e.get("id", ""))
	var hk := house_of(wd, spot)
	if hk == "" or resident(wd, hk) == "":
		return []
	var out: Array = []
	var here := at(g, spot)
	if here != "":
		# (the Uncarved Block release: a spot already put to rights offered a thing to set down that could not be)
		if str(g.placed[spot]).ends_with("|fit"):
			return out
		out.append({"id": "fit:take", "label": "Take up the %s" % str(THINGS[here].n).to_lower(), "desc": "It was set down here. It can be taken up again and put somewhere it belongs.", "enabled": true})
		return out
	var w := want(wd, hk)
	var wanted_here: bool = not w.is_empty() and str(w.spot) == spot and not is_fitted(g, hk)
	for tid in ORDER:
		var have := int(g.inv.get(tid, 0))
		if have > 0:
			out.append({"id": "fit:set:" + tid, "label": "Set down the %s here" % str(THINGS[tid].n).to_lower(), "desc": "%s is watching where you put it." % keeper(g, wd, hk), "enabled": true})
		elif wanted_here and str(w.thing) == tid:
			var pr := price(g)
			out.append({"id": "fit:send:" + tid, "label": "Send out for a %s" % str(THINGS[tid].n).to_lower(), "note": "%d stones" % pr,
				"desc": "A boy of the street will run to the market and back for %d spirit stones. It is what this house has wanted here." % pr, "enabled": int(g.stones) >= pr})
	return out

## Send out for thing `tid`: paid for, and in the bag.  Returns what is said ("" if it cannot be paid).
static func send_for(g, tid: String) -> String:
	var pr := price(g)
	if int(g.stones) < pr:
		return ""
	g.stones -= pr
	g.add_item(tid)
	return "A boy runs to the market and back: %s, for %d spirit stones." % [str(THINGS[tid].n), pr]

## Set thing `tid` down at piece of furniture `e`.  Returns what whoever lives there says of it:
## {who, line, v (1 right and wanted, 2 right, 0 suffered, -1 wrong), stones}.
static func set_down(g, wd: Dictionary, e: Dictionary, tid: String) -> Dictionary:
	var spot := str(e.id)
	var hk := house_of(wd, spot)
	if hk == "" or int(g.inv.get(tid, 0)) <= 0 or at(g, spot) != "":
		return {}
	g.inv[tid] = int(g.inv[tid]) - 1
	if int(g.inv[tid]) <= 0:
		g.inv.erase(tid)
	var v := verdict(tid, str(e.furn))
	g.placed[spot] = "%s|%d" % [tid, v]
	var who := keeper(g, wd, hk)
	var w := want(wd, hk)
	if v < 0:
		g.misplaced += 1
		return {"who": who, "line": str(THINGS[tid].bad[str(e.furn)]), "v": -1, "stones": 0}
	if not w.is_empty() and str(w.spot) == spot and str(w.thing) == tid and not is_fitted(g, hk):
		g.fitted[hk] = int(g.day)
		g.step_fit += 1
		# (the Unpicked Road release: the thing that put a house to rights stays in it; one lamp used to be
		# taken up again and put every house of a town to rights in turn)
		g.placed[spot] = "%s|fit" % tid
		var st := thanks(g)
		g.stones += st
		g.note("Put %s's house to rights: %s" % [who, str(THINGS[tid].n).to_lower()])
		return {"who": who, "line": str(WORDS[tid][1]), "v": 1, "stones": st}
	if v > 0:
		return {"who": who, "line": "A %s, there. Yes. It is not what was wanting in this house, but it is not wrong, and I do not say that often." % str(THINGS[tid].n).to_lower(), "v": 2, "stones": 0}
	return {"who": who, "line": str(SUFFERED[absi(hash(spot)) % SUFFERED.size()]), "v": 0, "stones": 0}

## Take up what stands at `spot`: back in the bag.  A house that was put to rights by it stays so (it
## was seen to; they will have moved it themselves by now).
static func take_up(g, spot: String) -> String:
	var here := at(g, spot)
	if here == "" or str(g.placed[spot]).ends_with("|fit"):
		return ""
	if str(g.placed[spot]).ends_with("|-1"):
		g.misplaced = maxi(0, int(g.misplaced) - 1)
	g.placed.erase(spot)
	g.add_item(here)
	return "Taken up: %s" % str(THINGS[here].n)

## What whoever lives in the house says the first time piece of furniture `e` is handled ("" in a house
## nobody lives in, or when it has been said).
static func touched(g, wd: Dictionary, e: Dictionary) -> String:
	var spot := str(e.get("id", ""))
	var hk := house_of(wd, spot)
	if hk == "" or resident(wd, hk) == "" or int(g.prop_uses.get(spot, 0)) != 1:
		return ""
	var fk := str(e.get("furn", ""))
	var ln: String = str(TOUCHED[fk]) if TOUCHED.has(fk) and fk != "" else str(TOUCHED[""][absi(hash(spot)) % 3])
	return "%s: \"%s\"" % [keeper(g, wd, hk), ln]

## The nearest house to put to rights for the step in hand: a want of region `area` (the first by key;
## the bot walks to its spot).  {} when the region has none left.
static func wanted(g, wd: Dictionary, area: String) -> Dictionary:
	var ws := wants_in(g, wd, area)
	return {} if ws.is_empty() else ws[0]

# ---------------------------------------------------------------- the things themselves
## A household thing as it stands where it was set down (built from code, a few dozen triangles).
static func model(tid: String) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	var bronze := MB.tag(Color("9a8444"), MB.METAL)
	match tid:
		"bead_curtain":
			b.box(Vector3(0, 1.7, 0), Vector3(0.9, 0.05, 0.05), MB.tag(Color("6a4a30"), MB.WOOD))
			for i in 7:
				for j in 6:
					b.box(Vector3(-0.39 + 0.13 * float(i), 1.58 - 0.2 * float(j), 0), Vector3(0.04, 0.12, 0.04), MB.tag(Color("c84a3a") if (i + j) % 2 == 0 else Color("e8c860"), MB.STONE))
		"mirror_cloth":
			b.box(Vector3(0, 0.3, 0), Vector3(0.5, 0.6, 0.1), MB.tag(Color("7a3a5a"), MB.CLOTH))
			b.box(Vector3(0, 0.6, 0), Vector3(0.54, 0.06, 0.14), MB.tag(Color("d8b860"), MB.CLOTH))
		"water_jar":
			b.lathe(Vector3.ZERO, [Vector2(0.16, 0.0), Vector2(0.28, 0.2), Vector2(0.29, 0.38), Vector2(0.2, 0.56), Vector2(0.22, 0.6)], MB.tag(Color("7a4a32"), MB.STONE), 12)
			b.disc(Vector3(0, 0.55, 0), 0.19, MB.tag(Color("4a7a9a"), MB.CRYSTAL), 12)
		"incense_burner":
			b.lathe(Vector3.ZERO, [Vector2(0.07, 0.0), Vector2(0.14, 0.05), Vector2(0.15, 0.13), Vector2(0.12, 0.17)], bronze, 10)
			for k in 3:
				b.box(Vector3(0.03 * float(k - 1), 0.3, 0), Vector3(0.012, 0.28, 0.012), MB.tag(Color("a84a3a"), MB.WOOD))
				g.ball(Vector3(0.03 * float(k - 1), 0.45, 0), 0.02, Color(1.0, 0.5, 0.2, 0.9), true)
		"orchid":
			b.lathe(Vector3.ZERO, [Vector2(0.08, 0.0), Vector2(0.13, 0.08), Vector2(0.12, 0.16)], MB.tag(Color("3a5a7a"), MB.STONE), 10)
			for k2 in 6:
				var a := float(k2) * TAU / 6.0
				b.leaf(Vector3(0, 0.15, 0), Vector3(cos(a) * 0.26, 0.4 + 0.06 * float(k2 % 2), sin(a) * 0.26), 0.05, MB.tag(Color("3a7a44"), MB.FOLIAGE))
			b.limb(Vector3(0, 0.15, 0), Vector3(0.04, 0.56, 0.02), 0.012, 0.008, MB.tag(Color("5a8a4a"), MB.FOLIAGE), 4)
			b.ball(Vector3(0.05, 0.58, 0.02), 0.05, MB.tag(Color("e8d8f0"), MB.CLOTH), true)
		"oil_lamp":
			b.lathe(Vector3.ZERO, [Vector2(0.09, 0.0), Vector2(0.03, 0.04), Vector2(0.02, 0.22), Vector2(0.1, 0.26), Vector2(0.09, 0.3)], bronze, 10)
			g.ball(Vector3(0.07, 0.36, 0), 0.05, Color(1.0, 0.8, 0.4, 0.95), true)
			g.ball(Vector3(0.07, 0.36, 0), 0.2, Color(1.0, 0.7, 0.3, 0.25), true)
		_:
			# the house broom: upright, bristles up
			b.limb(Vector3(0, 0, 0), Vector3(0, 1.25, 0), 0.02, 0.02, MB.tag(Color("a87a4a"), MB.WOOD), 5)
			b.box(Vector3(0, 1.38, 0), Vector3(0.3, 0.26, 0.08), MB.tag(Color("c8b070"), MB.HAIR))
	MB.mesh_node(root, b.build(MB.mat_vc()))
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root
