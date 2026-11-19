class_name Mills
extends RefCounted
## The works of the sea floor (the Sea Floor release): six places where things are made, in the open, by the
## people who make them.  Each town under the Eastern Sea has two: a yard that makes something out of the sea
## and a shed that makes something out of that; and each shed also wants what another town's yard makes, so
## that no town can do without the next.
##
##   the Retting-Yard (sea-hemp)  ->  the Gauze-Looms (shark-gauze)      Shuttlereef
##   the Shell-Lime Kiln (lime)   ->  the Glass-House (floats)            Redbranch
##   the Brine-Pans (salt)        ->  the Salting-House (salted roe)      Lampdeep
##   and across the towns: lime to the looms, salt to the glass, glass to the salting.
##
## A works is three stations and a store, standing in its paved yard (entities of kind "mill", written with
## their region in Data.AREAS "mills"), and a counting-house whose keeper is the works' foreman.  At every
## station somebody works by day (drawn with the station: nobody is stood in the land for it), the machine
## turns while they do, and what is in the store is what has been made: `stock` is a function of the hour
## (a shift from SHIFT[0] to SHIFT[1]; so much a day; never more than the store holds), of what was bought or
## carried away, and of what was brought.  Nothing is thrown for.
##
## At the foreman ("Not today" first): what the works does, a thing of its make bought from the store, a
## crate taken for a works that wants it (each pair of works once a day, two crates in the hands at most:
## taking one costs the store CRATE of its stock, and bringing one adds CRATE to the store it is brought to
## and pays a carrier's fee worth less than the road).  A step of kind "supply" asks for so many crates
## brought since it began.  No trial, notice, letter or ending asks for any of it, and the bot carries only
## inside such a step.

## the step after which the works are known (he has stood on the sea floor)
const OPEN := "s_p42_dive"
## the hours of the shift
const SHIFT := [6.0, 19.0]
## what a crate is worth of a store's stock, how many can be in his hands, and what one pays (by his level)
const CRATE := 2
const HANDS := 2
const PAY_BASE := 280.0
const PAY_LEVEL := 6.0
const ASK := "The foreman wipes both hands and waits."
## how much over life size a machine is drawn
const MACHINE_K := 1.25

const WORKS := {
	"retting": {"n": "The Retting-Yard of Shuttlereef", "short": "the Retting-Yard", "town": "shuttlereef", "area": "jiaoshi", "foreman": "retter_mu",
		"makes": "mill_hemp", "unit": "hank", "per_day": 6, "cap": 12, "price": 900, "from": [], "col": Color("8aa870"),
		"raw": "kelp cut on the shoals at slack water",
		"desc": "Kelp goes into the vat with lime-water and is turned for a day. The trip-hammers beat it. The comb draws what is left into fibre as long as an arm. Six hanks on a good day.",
		"stations": [
			{"n": "The Retting-Vat", "m": "vat", "body": "folk_porter", "clip": "stir", "tint": Color("5a8a5a"),
				"does": "A vat as wide as a cart, full of kelp and lime-water the colour of weak tea. The paddle goes round, and round, and the weed comes apart into strings.",
				"says": "A day in the vat. Not a morning. I have had it explained to me that there is a flood on. The kelp has not been told."},
			{"n": "The Trip-Hammers", "m": "beater", "body": "folk_youth", "clip": "pound", "tint": Color("8aa870"),
				"does": "Three hammers on one shaft, lifted by cams and let fall on the retted weed. Each blow drives the water out of it and leaves a little more that is only thread.",
				"says": "You stand here and you feed it. Left hand in, left hand out, hammer. I have all ten fingers. Ask anybody else in the yard how many they have."},
			{"n": "The Hackling-Comb", "m": "comb", "body": "folk_jiaoren", "clip": "comb", "tint": Color("c8d8a0"),
				"does": "A bed of iron teeth, and a handful of beaten weed drawn through it again and again until what is left in the hand is pale and straight and as fine as hair.",
				"says": "The short stuff falls through and goes to stuff mattresses. The long stuff goes to the looms. People are much the same, the Loom-Mother says. She does not say which she means."},
		]},
	"loomery": {"n": "The Gauze-Looms of Shuttlereef", "short": "the Gauze-Looms", "town": "shuttlereef", "area": "jiaoshi", "foreman": "loomer_sha",
		"makes": "mill_gauze", "unit": "bolt", "per_day": 3, "cap": 8, "price": 2400, "from": ["retting", "kiln"], "col": Color("b8e0e8"),
		"raw": "sea-hemp from the yard across the town, and lime from Redbranch to bleach it",
		"desc": "The hank is spun, the thread is woven, and the web is pressed between shell plates until water will not stay on it. Three bolts on a good day, and no weaver has ever been hurried.",
		"stations": [
			{"n": "The Great Wheel", "m": "wheel", "body": "folk_jiaoren", "clip": "spin", "tint": Color("b8e0e8"),
				"does": "A wheel taller than a man, turned by one hand, and a thread running off the spindle so fine that it shows only where the light crosses it.",
				"says": "My mother spun on this wheel and hers before. It has been turning since before your mountain had a sect on it. I should not like to be the one who let it stop."},
			{"n": "The Gauze-Loom", "m": "loom", "body": "folk_jiaoren", "clip": "weave", "tint": Color("d8f0f0"),
				"does": "The shuttle goes across and the reed comes down, and a finger's width of gauze is in the world that was not. It goes into water and comes out dry. Nobody here finds that strange.",
				"says": "A Jiaoren never leaves off weaving. It is in the books. Nobody who wrote the books asked us whether we wished to. Some of us do. Pass me that quill."},
			{"n": "The Shell-Press", "m": "press", "body": "folk_porter", "clip": "push", "tint": Color("e8e0d0"),
				"does": "Two plates of polished shell and a wooden screw as thick as a thigh. The web goes between them wet and comes out with a sheen on it like the inside of an oyster.",
				"says": "Nine turns down, a count of sixty, nine turns up. If I lose count I start again. I have started again four times since you walked into the yard."},
		]},
	"kiln": {"n": "The Shell-Lime Kiln of Redbranch", "short": "the Shell-Lime Kiln", "town": "redbranch", "area": "shanhu", "foreman": "limer_shi",
		"makes": "mill_lime", "unit": "sack", "per_day": 6, "cap": 12, "price": 800, "from": [], "col": Color("f0ece0"),
		"raw": "coral that has died, and oyster shell",
		"desc": "Dead coral and shell are crushed, burnt white in the kiln and slaked in the pit. Nothing goes in that was alive that morning: that is the one rule of the yard. Six sacks on a good day.",
		"stations": [
			{"n": "The Shell-Crusher", "m": "beater", "body": "folk_porter", "clip": "pound", "tint": Color("e8dcc8"),
				"does": "Three hammers falling on a bed of oyster shell and dead white coral. What goes under them in pieces the size of a hand comes out the size of a fingernail.",
				"says": "I used to sort it first. Red here, to be looked at again; white there, to be burnt. This month it is all white. I do not sort any more."},
			{"n": "The Bottle-Kiln", "m": "kiln", "body": "folk_founder", "clip": "fan", "tint": Color("b84a3a"),
				"does": "A kiln shaped like a bottle, twice a man's height, with a fire in its belly that burns under the sea because nobody has told it that it cannot. The crushed shell goes in grey and comes out white.",
				"says": "Three days to bring her up, a day at heat, three to bring her down. The Kiln-Master says nothing alive should be hurried. I tell him the kiln is not alive. He says: are you sure?"},
			{"n": "The Slaking-Pit", "m": "vat", "body": "folk_youth", "clip": "stir", "tint": Color("f4f0e8"),
				"does": "Burnt lime goes into the pit and is turned with a long paddle until it has stopped hissing. It takes most of a day. Nobody stands downstream of it twice.",
				"says": "It bites. Look at my hands. No, do not look at my hands. It rets their kelp and clears her glass and sweetens the salt-pans, and it bites, and somebody has to stir it."},
		]},
	"glass": {"n": "The Glass-House of Redbranch", "short": "the Glass-House", "town": "redbranch", "area": "shanhu", "foreman": "glazier_liuli",
		"makes": "mill_float", "unit": "float", "per_day": 3, "cap": 8, "price": 2600, "from": ["kiln", "pans"], "col": Color("7ad0b8"),
		"raw": "white sand, lime from the kiln across the town, and salt-ash from Lampdeep",
		"desc": "Sand, lime and ash are melted, the melt is blown into a globe on the pipe, and something small and luminous is sealed inside before it cools. Three floats on a good day. Every lamp in Lampdeep is one.",
		"stations": [
			{"n": "The Glory-Hole", "m": "kiln", "body": "folk_founder", "clip": "fan", "tint": Color("e89a3a"),
				"does": "A furnace with a mouth the size of a bucket and a light in it too bright to look at. The melt lies in a pot at the back like honey.",
				"says": "Sand from the shoals, lime from across the yard, ash from the salt-pans. I mix it by eye. Mistress Liuli mixes it by weight and gets the same. We do not discuss it."},
			{"n": "The Blowing-Bench", "m": "blow", "body": "folk_shopwife", "clip": "lift", "tint": Color("7ad0b8"),
				"does": "A gather of melt on the end of an iron pipe, turned on the bench and blown, and turned, until it is a green globe the size of two fists with the yard reflected in it upside down.",
				"says": "One breath. If you take two there is a seam, and a float with a seam goes dark in a year. I have breathed for this town for thirty years. I know how many breaths I have left, roughly."},
			{"n": "The Cooling-Rack", "m": "rack", "body": "folk_boy", "clip": "arrange", "tint": Color("c8f0a0"),
				"does": "A rack of floats cooling from orange to green. Into each, before it is sealed, goes a pinch of something from a jar that glows, and goes on glowing.",
				"says": "They are alive. The little lights. I feed them on Tuesdays. Nobody told me to. If I am sent to bed early I come back and do it anyway."},
		]},
	"pans": {"n": "The Brine-Pans of Lampdeep", "short": "the Brine-Pans", "town": "lampdeep", "area": "beiming", "foreman": "salter_yan",
		"makes": "mill_salt", "unit": "cake", "per_day": 6, "cap": 12, "price": 700, "from": [], "col": Color("c8c8d0"),
		"raw": "the heavy brine that lies in the hollows of the Northern Dark",
		"desc": "A wheel lifts the heavy brine out of the hollows, the pans boil it down over the warm vents, and what is left is pressed into cakes and stamped with a lamp. Six cakes on a good day.",
		"stations": [
			{"n": "The Brine-Wheel", "m": "tidewheel", "body": "folk_farmer", "clip": "push", "tint": Color("7a8aa0"),
				"does": "A wheel hung with clay pots, turning slowly. Each pot goes down into the hollow empty and comes up full of brine too heavy to mix with the sea, and tips it into the trough.",
				"says": "The brine lies in the low places like oil under water. You would not know it was there. My grandfather found it by falling in. He floated. He was very surprised."},
			{"n": "The Boiling-Pan", "m": "pan", "body": "folk_farmwife", "clip": "sweep", "tint": Color("d8d8e0"),
				"does": "An iron pan as long as a boat, set over a crack in the floor where the water comes up warm. The brine thickens and a crust forms, and the rake draws the crust to the side.",
				"says": "The vent does the boiling. I do the raking. This autumn there is silt in the pan and I rake that too, and the salt comes grey. They say grey salt is the better. They are being kind."},
			{"n": "The Cake-Press", "m": "press", "body": "folk_youth", "clip": "knead", "tint": Color("b0b0b8"),
				"does": "Wet salt shovelled into a mould, the screw brought down on it, and a cake knocked out that is hard as a brick and stamped on one face with a lamp.",
				"says": "The stamp is a lamp because the town is. I asked to change it once. A fish, I said. Old Ao looked at me for a long time and asked what a fish had ever done for anybody."},
		]},
	"saltery": {"n": "The Salting-House of Lampdeep", "short": "the Salting-House", "town": "lampdeep", "area": "beiming", "foreman": "roe_wife",
		"makes": "mill_roe", "unit": "jar", "per_day": 3, "cap": 8, "price": 2200, "from": ["pans", "glass"], "col": Color("d88a5a"),
		"raw": "roe of the lantern-fish, salt from the pans across the town, and jars of Redbranch glass",
		"desc": "The roe is cleaned on the bench, laid down in salt in the tubs for a month, and packed into glass. Three jars on a good day, and each keeps a year.",
		"stations": [
			{"n": "The Cleaning-Bench", "m": "bench", "body": "folk_fisher", "clip": "flay", "tint": Color("c88a6a"),
				"does": "A stone bench with a groove down it and a knife that has been sharpened so often it is half the width it was. The roe comes out whole, in one piece, every time.",
				"says": "You take the roe and you put the fish back. She swims off. A little light on the end of a rod, going away in the dark, looking offended. They come back next year. I have never understood it."},
			{"n": "The Salting-Tub", "m": "vat", "body": "folk_farmwife", "clip": "knead", "tint": Color("d8a070"),
				"does": "A tub of roe and grey salt in layers, turned by hand once a day for a month. The hands that turn it are the colour of the salt to the wrist.",
				"says": "A month. Turned every day. If you miss a day you can taste it, and Mistress Zi can taste it from the door. I have missed two days in eleven years. She mentions them."},
			{"n": "The Packing-Rack", "m": "rack", "body": "folk_girl", "clip": "arrange", "tint": Color("e8b080"),
				"does": "Jars of green glass from Redbranch, filled to a finger below the lip, sealed with wax and set on the rack with the seal to the wall.",
				"says": "A finger below the lip. My finger, not yours. Mine is the finger the jars are made to. I shall have to stop growing."},
		]},
}
const ORDER := ["retting", "loomery", "kiln", "glass", "pans", "saltery"]
## what a thing of the works' make does when it is used from the Items page (a share of health, of qi)
const USES := {"mill_gauze": {"hp": 0.6}, "mill_float": {"qi": 0.6}, "mill_roe": {"hp": 0.4, "qi": 0.3}}

static func open(g) -> bool:
	return g.done(OPEN)

## The works whose foreman is person `npc` ("" if nobody's).
static func of_foreman(npc: String) -> String:
	for id in ORDER:
		if str(WORKS[id].foreman) == npc:
			return id
	return ""

## The works of region `area`.
static func in_area(area: String) -> Array:
	return ORDER.filter(func(id): return str(WORKS[id].area) == area)

## Whether the shift is on at hour `h`.
static func running(h: float) -> bool:
	return h >= float(SHIFT[0]) and h < float(SHIFT[1])

## How much of today's shift has been worked by hour `h` (0 before it, 1 after).
static func shift(h: float) -> float:
	return clampf((h - float(SHIFT[0])) / (float(SHIFT[1]) - float(SHIFT[0])), 0.0, 1.0)

## The days of work there have been by now (whole shifts, and how much of today's).
static func worked(g) -> float:
	return float(int(g.day)) + shift(Clock.hour(g))

## What is in the store of works `id`: what was kept when it was last counted and what has been made
## since, never more than the store holds.
static func stock(g, id: String) -> int:
	var w: Dictionary = WORKS[id]
	var st: Dictionary = g.mills.get(id, {})
	if st.is_empty():
		# (nobody has bought here or carried from here yet: a store that has been filling for as long as there
		# has been a works is full)
		return int(w.cap)
	return clampi(int(st.n) + int(floor(float(w.per_day) * maxf(0.0, worked(g) - float(st.at)))), 0, int(w.cap))

static func _keep(g, id: String, n: int) -> void:
	g.mills[id] = {"n": clampi(n, 0, int(WORKS[id].cap)), "at": worked(g)}

## What a thing of works `id` costs him at its store today (the town's own prices: weal.gd).
static func price(g, id: String) -> int:
	return int(round(float(WORKS[id].price) * Weal.mod(g, str(WORKS[id].area), "price")))

## Why a thing of works `id` cannot be bought now ("" if it can).
static func buy_blocked(g, id: String) -> String:
	if stock(g, id) < 1:
		return "The store is empty: come back when the shift has made something."
	if int(g.stones) < price(g, id):
		return "It costs more than he has."
	return ""

static func buy(g, id: String) -> bool:
	if buy_blocked(g, id) != "":
		return false
	g.stones = int(g.stones) - price(g, id)
	_keep(g, id, stock(g, id) - 1)
	g.add_item(str(WORKS[id].makes), 1)
	g.mill_bought = int(g.mill_bought) + 1
	g.note("Bought a %s at %s" % [str(WORKS[id].unit), str(WORKS[id].short)])
	return true

## What a crate carried pays (by his level; worth less than the road).
static func pay(level: int) -> int:
	return int(round(PAY_BASE + PAY_LEVEL * float(level)))

## The works that want what works `id` makes.
static func wanted_by(id: String) -> Array:
	return ORDER.filter(func(o): return id in WORKS[o].from)

## The crate works `from` has to be carried today: {from, to, pay, day}, or {} (its hands are full, the
## store has too little, every works that wants it has had one of him today, or none of them is in a
## country he has walked into).
static func crate_offer(g, from: String) -> Dictionary:
	if not open(g) or g.mill_crates.size() >= HANDS or stock(g, from) < CRATE:
		return {}
	for to in wanted_by(from):
		if int(g.mill_runs.get(from + ">" + str(to), -1)) == int(g.day):
			continue
		if not (g.seen.has(str(WORKS[to].area)) or g.seen.is_empty()):
			continue
		if g.mill_crates.any(func(c): return str(c.from) == from and str(c.to) == str(to)):
			continue
		return {"from": from, "to": str(to), "pay": pay(int(g.level)), "day": int(g.day)}
	return {}

static func take_crate(g, c: Dictionary) -> bool:
	if c.is_empty() or g.mill_crates.size() >= HANDS or stock(g, str(c.from)) < CRATE:
		return false
	_keep(g, str(c.from), stock(g, str(c.from)) - CRATE)
	g.mill_crates.append(c)
	g.mill_runs[str(c.from) + ">" + str(c.to)] = int(g.day)
	g.note("Took a crate from %s for %s" % [str(WORKS[str(c.from)].short), str(WORKS[str(c.to)].short)])
	return true

## The crates in his hands for works `to`.
static func crates_for(g, to: String) -> Array:
	return g.mill_crates.filter(func(c): return str(c.to) == to)

## The crates for works `to` are set down in its yard: its store is the fuller for them, and the carrier
## is paid.  Returns what was paid.
static func deliver(g, to: String) -> int:
	var paid := 0
	var keep: Array = []
	var n := 0
	for c in g.mill_crates:
		if str(c.to) == to:
			paid += int(c.pay)
			n += 1
		else:
			keep.append(c)
	if n == 0:
		return 0
	g.mill_crates = keep
	_keep(g, to, stock(g, to) + CRATE * n)
	g.stones = int(g.stones) + paid
	g.crates_done = int(g.crates_done) + n
	g.step_supply = int(g.step_supply) + n
	g.mill_paid = int(g.mill_paid) + paid
	Weal.act(g, str(WORKS[to].town), "supplied")
	g.note("Brought %d crate%s to %s" % [n, "" if n == 1 else "s", str(WORKS[to].short)])
	return paid

## What the bot goes for in a "supply" step: {"to": works} if there is a crate in his hands to set down,
## else {"from": works} where one can be taken, else {} (every pair has had its crate today).
static func errand(g) -> Dictionary:
	if not g.mill_crates.is_empty():
		return {"to": str(g.mill_crates[0].to)}
	for id in ORDER:
		if (g.seen.has(str(WORKS[id].area)) or g.seen.is_empty()) and not crate_offer(g, id).is_empty():
			return {"from": id}
	return {}

## What is said of station `k` of works `id` at hour `h`: what is done there, and what whoever does it says
## (or that nobody is at it).
static func station_lines(id: String, k: int, h: float) -> Array:
	var w: Dictionary = WORKS[id]
	if k >= (w.stations as Array).size():
		return []
	var st: Dictionary = w.stations[k]
	var out: Array = [["Narrator", "%s, at %s. %s" % [str(st.n), str(w.short), str(st.does)]]]
	if running(h):
		out.append([who(id, k), str(st.says)])
	else:
		out.append(["Narrator", "The shift is over. The machine stands as it was left, with the last of the day's work still in it, and whoever works it has gone home."])
	return out

## The name whoever works station `k` of works `id` is spoken of by.
static func who(id: String, k: int) -> String:
	return "The hand at the %s" % str(WORKS[id].stations[k].n).trim_prefix("The ")

## What the store of works `id` holds, in words.
static func store_text(g, id: String) -> String:
	var w: Dictionary = WORKS[id]
	var n := stock(g, id)
	var unit := str(w.unit)
	return "The store of %s: %d %s%s of %d (%s). %s" % [str(w.short), n, unit, "" if n == 1 else "s", int(w.cap), str(Data.ITEMS[str(w.makes)].n),
		"The shift is on: about %d a day." % int(w.per_day) if running(Clock.hour(g)) else "The shift is over until the %s hour." % Clock.shichen_name(float(SHIFT[0]))]

## What the works are to one another, for the page (Esc > The Sea Floor): one line each.
static func page(g) -> Array:
	var out: Array = []
	for id in ORDER:
		var w: Dictionary = WORKS[id]
		var known: bool = open(g) and g.seen.has(str(w.area))
		out.append({"id": id, "n": str(w.n), "known": known, "col": w.col, "stock": stock(g, id) if known else 0, "cap": int(w.cap),
			"makes": str(Data.ITEMS[str(w.makes)].n), "from": (w.from as Array).map(func(f): return str(WORKS[f].short)), "raw": str(w.raw), "desc": str(w.desc)})
	return out

# ---------------------------------------------------------------- what is drawn
## Station `k` of works `id` (3: its store): the machine, with whoever works it standing at it (meta
## "worker": the person, "clip": what they do), its moving parts (meta "parts") and, for a store, what is
## stacked in it (`show_stock`).  The machine faces +Z, where whoever works it stands.
static func model(id: String, k: int) -> Node3D:
	var root := Node3D.new()
	var w: Dictionary = WORKS[id]
	root.set_meta("works", id)
	root.set_meta("k", k)
	root.set_meta("parts", [])
	if k >= (w.stations as Array).size():
		_store(root, w)
		return root
	var st: Dictionary = w.stations[k]
	# (the machine is drawn a little over life size, as the things of a works are; whoever works it stands at
	# its near corner, half turned to it, so that both can be seen from the yard)
	var mroot := Node3D.new()
	mroot.name = "machine"
	mroot.scale = Vector3.ONE * MACHINE_K
	root.add_child(mroot)
	_machine(mroot, str(st.m), st.tint, k)
	root.set_meta("parts", mroot.get_meta("parts", []))
	var body := str(st.body)
	var pn: Node3D = Assets.person(body) if Assets.PEOPLE.has(body) and Assets.has(Assets.PEOPLE[body]) else Models.person(Color("8a7a6a"), Color("2a2a3a"), {})
	Assets.lend_clips(pn)
	pn.position = Vector3(0.62, 0.0, 0.9)
	pn.rotation.y = PI + 0.6
	root.add_child(pn)
	root.set_meta("worker", pn)
	root.set_meta("clip", str(st.clip))
	return root

static func _part(root: Node3D, b: MB, pos: Vector3, how: Dictionary, mat: Material = null) -> MeshInstance3D:
	var mi := MB.mesh_node(root, b.build(mat) if mat != null else b.build(), pos)
	mi.set_meta("how", how)
	mi.set_meta("at", pos)
	var parts: Array = root.get_meta("parts", [])
	parts.append(mi)
	root.set_meta("parts", parts)
	return mi

## Turn the machine of station `n` to clock `t` (seconds): `on` whether the shift is working.
static func tick(n: Node3D, t: float, on: bool) -> void:
	var pn = n.get_meta("worker") if n.has_meta("worker") else null
	if pn != null and is_instance_valid(pn):
		(pn as Node3D).visible = on
		if on:
			Models.anim_person(pn, t + float(int(n.get_meta("k", 0))) * 0.7, false, false, str(n.get_meta("clip", "")))
	if not on:
		return
	for p in n.get_meta("parts", []):
		var mi: Node3D = p
		var how: Dictionary = mi.get_meta("how", {})
		var at: Vector3 = mi.get_meta("at", Vector3.ZERO)
		var ph := float(how.get("ph", 0.0))
		match str(how.get("k", "")):
			"spin":
				mi.rotation = (how.axis as Vector3) * (t * float(how.v) + ph)
			"slide":
				mi.position = at + (how.axis as Vector3) * float(how.amp) * sin(t * float(how.v) + ph)
			"hammer":
				# lifted slowly by the cam and let fall: a saw-tooth, not a sine
				var c := fmod(t * float(how.v) + ph, 1.0)
				mi.position = at + Vector3(0, float(how.amp) * (c / 0.8 if c < 0.8 else (1.0 - c) / 0.2), 0)
			"pulse":
				var s := 1.0 + float(how.amp) * sin(t * float(how.v) + ph)
				mi.scale = Vector3(s, s, s)
			"rise":
				# a bubble, a wisp of warm water: up, and begun again
				var c2 := fmod(t * float(how.v) + ph, 1.0)
				mi.position = at + Vector3(0, float(how.amp) * c2, 0)
				mi.scale = Vector3.ONE * (0.4 + 0.6 * c2) * (1.0 - smoothstep(0.8, 1.0, c2))

static func _machine(root: Node3D, m: String, tint: Color, k: int) -> void:
	var b := MB.new()
	var g := MB.new()
	var wood := MB.tag(Color("6a4a2e"), MB.WOOD)
	var dark := MB.tag(Color("3e2c1c"), MB.WOOD)
	var iron := MB.tag(Color("4a4a54"), MB.METAL)
	var stone := MB.tag(Color("8a8880"), MB.STONE)
	var stuff := MB.tag(tint, MB.CLOTH)
	var z0 := -0.25
	match m:
		"vat":
			# a staved vat with what is in it, and a paddle that goes round
			b.cyl(Vector3(0, 0.35, z0), 0.62, 0.7, wood, Vector3.ZERO, 12)
			b.torus(Vector3(0, 0.2, z0), 0.63, 0.025, iron, Vector3.ZERO)
			b.torus(Vector3(0, 0.55, z0), 0.63, 0.025, iron, Vector3.ZERO)
			b.cyl(Vector3(0, 0.69, z0), 0.56, 0.03, stuff, Vector3.ZERO, 12)
			var pd := MB.new()
			pd.cyl(Vector3(0, 0.55, 0), 0.03, 1.1, dark, Vector3.ZERO, 6)
			pd.box(Vector3(0.2, 0.12, 0), Vector3(0.36, 0.2, 0.03), wood)
			pd.box(Vector3(0, 1.06, 0), Vector3(0.5, 0.04, 0.04), dark)
			_part(root, pd, Vector3(0, 0.5, z0), {"k": "spin", "axis": Vector3.UP, "v": 1.1})
			for i in 3:
				var bb := MB.new()
				bb.ball(Vector3.ZERO, 0.05, Color(0.85, 0.95, 1.0, 0.5), true)
				_part(root, bb, Vector3(-0.3 + 0.3 * i, 0.75, z0 + 0.1 * (i - 1)), {"k": "rise", "amp": 0.9, "v": 0.45, "ph": 0.33 * i}, MB.mat_glow())
		"beater":
			# three hammers on one shaft, lifted by cams and let fall on a bed
			b.box(Vector3(0, 0.12, z0), Vector3(1.3, 0.24, 0.6), stone)
			b.box(Vector3(0, 0.26, z0), Vector3(1.1, 0.05, 0.4), stuff)
			for sx in [-0.7, 0.7]:
				b.box(Vector3(sx, 0.7, z0 - 0.25), Vector3(0.1, 1.4, 0.1), wood)
			var sh := MB.new()
			sh.cyl(Vector3.ZERO, 0.06, 1.5, dark, Vector3(0, 0, PI / 2), 8)
			for i in 3:
				sh.box(Vector3(-0.4 + 0.4 * i, 0.09 * cos(i * 2.1), 0.09 * sin(i * 2.1)), Vector3(0.08, 0.1, 0.1), iron)
			_part(root, sh, Vector3(0, 1.25, z0 - 0.25), {"k": "spin", "axis": Vector3.RIGHT, "v": 2.0})
			for i in 3:
				var hm := MB.new()
				hm.box(Vector3(0, 0.45, 0), Vector3(0.07, 0.9, 0.07), wood)
				hm.box(Vector3(0, 0.0, 0), Vector3(0.2, 0.2, 0.2), iron)
				_part(root, hm, Vector3(-0.4 + 0.4 * i, 0.4, z0), {"k": "hammer", "amp": 0.4, "v": 0.7, "ph": 0.33 * i})
		"comb":
			# a bench with a bed of iron teeth, and a hank drawn through it
			b.box(Vector3(0, 0.45, z0), Vector3(1.2, 0.08, 0.5), wood)
			for sx in [-0.5, 0.5]:
				for sz in [-0.18, 0.18]:
					b.box(Vector3(sx, 0.22, z0 + sz), Vector3(0.07, 0.44, 0.07), dark)
			for i in 9:
				for j in 3:
					b.cone(Vector3(-0.2 + 0.05 * i, 0.56, z0 - 0.06 + 0.06 * j), 0.012, 0.14, iron, Vector3.ZERO, 4)
			var hk := MB.new()
			hk.sph(Vector3.ZERO, Vector3(0.3, 0.05, 0.09), stuff)
			_part(root, hk, Vector3(0, 0.62, z0), {"k": "slide", "axis": Vector3.RIGHT, "amp": 0.28, "v": 1.6})
			b.sph(Vector3(0.45, 0.53, z0), Vector3(0.14, 0.07, 0.12), stuff)
		"wheel":
			# a great spinning wheel and its spindle
			b.box(Vector3(0, 0.06, z0), Vector3(1.3, 0.12, 0.4), wood)
			for sz in [-0.14, 0.14]:
				b.box(Vector3(-0.25, 0.6, z0 + sz), Vector3(0.07, 1.1, 0.05), dark)
			b.box(Vector3(0.52, 0.42, z0), Vector3(0.06, 0.7, 0.06), dark)
			var wh := MB.new()
			wh.torus(Vector3.ZERO, 0.62, 0.035, wood, Vector3(PI / 2, 0, 0), true)
			for i in 8:
				var a := TAU * i / 8.0
				wh.limb(Vector3.ZERO, Vector3(cos(a) * 0.6, sin(a) * 0.6, 0), 0.018, 0.018, dark, 4)
			wh.cyl(Vector3.ZERO, 0.07, 0.3, dark, Vector3(PI / 2, 0, 0), 8)
			_part(root, wh, Vector3(-0.25, 0.95, z0), {"k": "spin", "axis": Vector3.BACK, "v": 2.4})
			var sp := MB.new()
			sp.cyl(Vector3.ZERO, 0.015, 0.34, iron, Vector3(PI / 2, 0, 0), 6)
			sp.sph(Vector3.ZERO, Vector3(0.05, 0.05, 0.11), stuff)
			_part(root, sp, Vector3(0.52, 0.8, z0), {"k": "spin", "axis": Vector3.BACK, "v": 14.0})
			b.limb(Vector3(-0.25, 1.57, z0), Vector3(0.52, 0.83, z0), 0.006, 0.006, stuff, 3)
		"loom":
			# a frame, a warp and a web, a reed that beats and a shuttle that crosses
			for sx in [-0.6, 0.6]:
				b.box(Vector3(sx, 0.75, z0 - 0.35), Vector3(0.08, 1.5, 0.08), wood)
				b.box(Vector3(sx, 0.45, z0 + 0.25), Vector3(0.08, 0.9, 0.08), wood)
				b.box(Vector3(sx, 0.9, z0 - 0.05), Vector3(0.06, 0.06, 0.7), dark)
			b.box(Vector3(0, 1.5, z0 - 0.35), Vector3(1.3, 0.08, 0.08), wood)
			b.cyl(Vector3(0, 0.9, z0 - 0.35), 0.07, 1.2, dark, Vector3(0, 0, PI / 2), 8)
			b.cyl(Vector3(0, 0.88, z0 + 0.25), 0.08, 1.2, stuff, Vector3(0, 0, PI / 2), 8)
			b.box(Vector3(0, 0.9, z0 - 0.05), Vector3(1.05, 0.01, 0.6), MB.tag(tint.lightened(0.2), MB.CLOTH))
			var rd := MB.new()
			rd.box(Vector3(0, 0, 0), Vector3(1.12, 0.3, 0.03), dark)
			_part(root, rd, Vector3(0, 1.0, z0 + 0.02), {"k": "slide", "axis": Vector3.BACK, "amp": 0.1, "v": 3.2})
			var su := MB.new()
			su.sph(Vector3.ZERO, Vector3(0.1, 0.025, 0.03), MB.tag(Color("1e1e26"), MB.STONE))
			_part(root, su, Vector3(0, 0.93, z0 - 0.12), {"k": "slide", "axis": Vector3.RIGHT, "amp": 0.45, "v": 3.2, "ph": 1.57})
		"press":
			# a screw-press: two posts, a beam, a screw that turns and a platen under it
			b.box(Vector3(0, 0.1, z0), Vector3(1.1, 0.2, 0.7), wood)
			for sx in [-0.45, 0.45]:
				b.box(Vector3(sx, 0.8, z0), Vector3(0.12, 1.4, 0.14), dark)
			b.box(Vector3(0, 1.5, z0), Vector3(1.1, 0.16, 0.2), wood)
			b.box(Vector3(0, 0.26, z0), Vector3(0.6, 0.12, 0.5), stuff)
			var sc := MB.new()
			sc.cyl(Vector3(0, 0, 0), 0.07, 1.0, dark, Vector3.ZERO, 8)
			for i in 6:
				sc.torus(Vector3(0, -0.4 + 0.14 * i, 0), 0.075, 0.012, wood, Vector3(0.12, 0, 0))
			sc.box(Vector3(0, 0.55, 0), Vector3(0.9, 0.05, 0.05), wood)
			sc.box(Vector3(0, -0.52, 0), Vector3(0.62, 0.06, 0.52), MB.tag(Color("e8e0d0"), MB.STONE))
			_part(root, sc, Vector3(0, 0.95, z0), {"k": "spin", "axis": Vector3.UP, "v": 0.9})
		"kiln":
			# a bottle kiln: a round belly, a neck, a fire-mouth that glows, and warm water going up from it
			b.lathe(Vector3(0, 0, z0 - 0.1), [Vector2(0.75, 0.0), Vector2(0.8, 0.5), Vector2(0.7, 1.1), Vector2(0.4, 1.7), Vector2(0.28, 2.3), Vector2(0.32, 2.4)], MB.tag(Color("9a6a52"), MB.STONE), 12, MB.tag(Color("5a3e34"), MB.STONE))
			b.torus(Vector3(0, 0.55, z0 - 0.1), 0.81, 0.03, iron, Vector3.ZERO)
			b.box(Vector3(0, 0.38, z0 + 0.62), Vector3(0.44, 0.5, 0.2), MB.tag(Color("4a3a34"), MB.STONE))
			var fm := MB.new()
			fm.sph(Vector3.ZERO, Vector3(0.16, 0.18, 0.06), Color(tint.r, tint.g * 0.9, tint.b * 0.5, 0.95))
			_part(root, fm, Vector3(0, 0.38, z0 + 0.73), {"k": "pulse", "amp": 0.18, "v": 5.0}, MB.mat_glow())
			for i in 3:
				var wb := MB.new()
				wb.ball(Vector3.ZERO, 0.09, Color(1.0, 0.9, 0.7, 0.35), true)
				_part(root, wb, Vector3(0.08 * (i - 1), 2.4, z0 - 0.1), {"k": "rise", "amp": 1.6, "v": 0.3, "ph": 0.33 * i}, MB.mat_glow())
		"blow":
			# a bench with two rails, an iron pipe laid across them and turned, and the gather on its end
			b.box(Vector3(0, 0.3, z0), Vector3(1.2, 0.06, 0.45), wood)
			for sx in [-0.5, 0.5]:
				b.box(Vector3(sx, 0.15, z0), Vector3(0.07, 0.3, 0.4), dark)
				b.box(Vector3(sx, 0.55, z0), Vector3(0.05, 0.5, 0.05), iron)
			var pp := MB.new()
			pp.cyl(Vector3.ZERO, 0.018, 1.5, iron, Vector3(0, 0, PI / 2), 6)
			_part(root, pp, Vector3(-0.1, 0.82, z0), {"k": "spin", "axis": Vector3.RIGHT, "v": 3.0})
			var gl := MB.new()
			gl.ball(Vector3.ZERO, 0.17, Color(tint.r, tint.g, tint.b, 0.75), true)
			_part(root, gl, Vector3(0.72, 0.82, z0), {"k": "pulse", "amp": 0.22, "v": 0.9}, MB.mat_glow())
			b.cyl(Vector3(-0.45, 0.4, z0 + 0.1), 0.1, 0.16, stone, Vector3.ZERO, 8)
		"rack":
			# three shelves of what has been made, each with a little light or a seal on it
			for sx in [-0.55, 0.55]:
				for sz in [-0.18, 0.18]:
					b.box(Vector3(sx, 0.65, z0 + sz), Vector3(0.06, 1.3, 0.06), dark)
			for lv in 3:
				b.box(Vector3(0, 0.3 + 0.42 * lv, z0), Vector3(1.2, 0.04, 0.44), wood)
				for i in 4:
					var px := -0.42 + 0.28 * i
					b.cyl(Vector3(px, 0.4 + 0.42 * lv, z0), 0.09, 0.16, MB.tag(Color("6ab8a0"), MB.CRYSTAL), Vector3.ZERO, 8)
					var lt := MB.new()
					lt.ball(Vector3.ZERO, 0.045, Color(tint.r, tint.g, tint.b, 0.9), true)
					_part(root, lt, Vector3(px, 0.42 + 0.42 * lv, z0), {"k": "pulse", "amp": 0.3, "v": 1.3, "ph": float(i + lv * 4) * 0.8}, MB.mat_glow())
		"tidewheel":
			# a wheel hung with pots that lifts the heavy brine, and the trough it tips into
			for sz in [-0.3, 0.3]:
				b.box(Vector3(0, 0.75, z0 + sz), Vector3(0.1, 1.5, 0.08), dark)
			b.box(Vector3(0.75, 0.55, z0), Vector3(0.6, 0.08, 0.3), wood)
			b.box(Vector3(0.75, 0.6, z0), Vector3(0.5, 0.02, 0.2), stuff)
			var tw := MB.new()
			tw.torus(Vector3.ZERO, 0.68, 0.04, wood, Vector3(PI / 2, 0, 0), true)
			tw.cyl(Vector3.ZERO, 0.07, 0.7, dark, Vector3(PI / 2, 0, 0), 8)
			for i in 8:
				var a2 := TAU * i / 8.0
				tw.limb(Vector3.ZERO, Vector3(cos(a2) * 0.66, sin(a2) * 0.66, 0), 0.02, 0.02, dark, 4)
				tw.cyl(Vector3(cos(a2) * 0.72, sin(a2) * 0.72, 0.0), 0.07, 0.14, MB.tag(Color("a86a4a"), MB.STONE), Vector3(0, 0, a2), 6)
			_part(root, tw, Vector3(0, 0.95, z0), {"k": "spin", "axis": Vector3.BACK, "v": -0.7})
		"pan":
			# a long iron pan over a warm vent, a rake that draws the crust, and the warm water going up
			b.box(Vector3(0, 0.1, z0), Vector3(1.0, 0.2, 0.5), MB.tag(Color("3a3430"), MB.STONE))
			b.box(Vector3(0, 0.3, z0), Vector3(1.5, 0.1, 0.7), iron)
			b.box(Vector3(0, 0.36, z0), Vector3(1.4, 0.02, 0.6), stuff)
			g.disc(Vector3(0, 0.03, z0), 0.5, Color(1.0, 0.5, 0.2, 0.5), 10, Color(1.0, 0.4, 0.1, 0.0))
			var rk := MB.new()
			rk.box(Vector3(0, 0, 0), Vector3(0.05, 0.08, 0.5), wood)
			rk.limb(Vector3(0, 0.02, 0.2), Vector3(0, 0.5, 0.9), 0.018, 0.018, dark, 4)
			_part(root, rk, Vector3(0, 0.4, z0), {"k": "slide", "axis": Vector3.RIGHT, "amp": 0.5, "v": 0.8})
			for i in 4:
				var st2 := MB.new()
				st2.ball(Vector3.ZERO, 0.08, Color(0.9, 0.95, 1.0, 0.3), true)
				_part(root, st2, Vector3(-0.5 + 0.33 * i, 0.4, z0), {"k": "rise", "amp": 1.2, "v": 0.35, "ph": 0.25 * i}, MB.mat_glow())
		_:
			# a stone bench with a groove, a board, and what is being worked on it
			b.box(Vector3(0, 0.42, z0), Vector3(1.3, 0.1, 0.55), stone)
			for sx in [-0.5, 0.5]:
				b.box(Vector3(sx, 0.2, z0), Vector3(0.16, 0.4, 0.45), MB.tag(Color("6a6860"), MB.STONE))
			b.box(Vector3(0, 0.475, z0), Vector3(1.1, 0.012, 0.05), MB.tag(Color("5a5850"), MB.STONE))
			b.sph(Vector3(-0.3, 0.5, z0 + 0.05), Vector3(0.16, 0.04, 0.07), MB.tag(Color("7a8aa0"), MB.SCALE))
			b.cyl(Vector3(0.42, 0.53, z0 - 0.05), 0.12, 0.1, wood, Vector3.ZERO, 8)
			b.cyl(Vector3(0.42, 0.585, z0 - 0.05), 0.1, 0.012, stuff, Vector3.ZERO, 8)
			var kn := MB.new()
			kn.box(Vector3(0, 0, 0), Vector3(0.16, 0.012, 0.03), iron)
			_part(root, kn, Vector3(-0.05, 0.5, z0 + 0.1), {"k": "slide", "axis": Vector3.RIGHT, "amp": 0.1, "v": 4.0})
	if not b.is_empty():
		MB.mesh_node(root, b.build())
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _store(root: Node3D, w: Dictionary) -> void:
	# a staging of planks under a little roof; what is stacked on it is `show_stock`
	var b := MB.new()
	var wood := MB.tag(Color("6a4a2e"), MB.WOOD)
	var dark := MB.tag(Color("3e2c1c"), MB.WOOD)
	b.box(Vector3(0, 0.12, 0), Vector3(1.5, 0.08, 1.2), wood)
	for sx in [-0.68, 0.68]:
		for sz in [-0.52, 0.52]:
			b.box(Vector3(sx, 0.85, sz), Vector3(0.08, 1.7, 0.08), dark)
	b.box(Vector3(0, 1.74, 0), Vector3(1.7, 0.06, 1.4), MB.tag((w.col as Color).darkened(0.35), MB.CLOTH), Vector3(0.08, 0, 0))
	MB.mesh_node(root, b.build())
	var stack := Node3D.new()
	stack.name = "stack"
	root.add_child(stack)
	root.set_meta("shown", -1)

## Stack `n` of the `cap` things the store of model `root` holds (rebuilt only when the number changes).
static func show_stock(root: Node3D, n: int) -> void:
	if int(root.get_meta("shown", -2)) == n or not root.has_node("stack"):
		return
	root.set_meta("shown", n)
	var stack: Node3D = root.get_node("stack")
	for c in stack.get_children():
		c.queue_free()
	if n <= 0:
		return
	var w: Dictionary = WORKS[str(root.get_meta("works", ORDER[0]))]
	var b := MB.new()
	var col := MB.tag(w.col, MB.CLOTH)
	var band := MB.tag((w.col as Color).darkened(0.4), MB.WOOD)
	for i in n:
		var lv := i / 6
		var j := i % 6
		var p := Vector3(-0.42 + 0.42 * float(j % 3), 0.3 + 0.27 * float(lv), -0.25 + 0.5 * float(j / 3))
		b.box(p, Vector3(0.36, 0.24, 0.4), col, Vector3(0, 0.07 * float((i * 7) % 5 - 2), 0))
		b.box(p + Vector3(0, 0, 0), Vector3(0.375, 0.04, 0.415), band, Vector3(0, 0.07 * float((i * 7) % 5 - 2), 0))
	MB.mesh_node(stack, b.build())
