class_name Wilds
extends RefCounted
## The balance of the wild (the Open Net release): a country that is hunted too hard changes.
##
## Every region has beasts of its own (the packs its map was made with: not the war-bands of the story,
## which are invaders, nor what lives in a cave).  Each time one of those packs is put down the region's
## **strain** rises (`cull`), and it eases by half every `HALF` days he leaves the place alone.  Strain is
## counted against how many packs the region has, so a large country bears more than a small one:
##
##   in balance   as it was made
##   thinned      every pack is a head short (never fewer than one), and is slower to come back
##   hunted out   what is left is followed by what eats the leavings: carrion crows and midden rats fight
##                beside it; the towns that hear of the region are the poorer; the colour goes out of it
##   barren       one gaunt survivor, the scavengers, and the Hunger That Follows at their head; the packs
##                are four times as slow to return; the towns go lean; the sky is the colour of ash
##
## It is felt in the towns through `town_causes` (weal.gd asks), in the battle through `group` (the heads
## he meets), in how soon a pack is back through `back`, in what the people of the camps say (`line`), and
## it is **drawn**: `fade` is how much colour
## the region has lost, and `World` takes it out of the sky and the grass and puts crows in the air.
##
## A hunter of the camps can be paid to open three sides of his net (`open_net`): the strain of his
## region is halved, once a day.  Left alone, a barren country is in balance again in a week.
##
## The state kept: `g.cull` (region -> [strain in packs, the day it was counted]), `g.cull_told` (region
## -> the state last told), `g.cull_worst` (region -> the worst state it has been brought to), `g.nets`.
## Pure functions of that and the day; the bot hunts as it always did, and what that does to the land is
## told in its report.

## days for a region's strain to ease by half
const HALF := 2.0
## strain, in times the region's own packs put down, at which it is thinned, hunted out, barren
const AT := [1.5, 3.0, 5.0]
const STATES := [
	{"id": "balance", "n": "In balance", "word": "", "col": Color("a8d8a0"), "back": 1.0, "fade": 0.0,
		"desc": "As many as the land feeds. What he takes is made up by the spring."},
	{"id": "thinned", "n": "Thinned", "word": "thinned", "col": Color("d8c880"), "back": 1.5, "fade": 0.12,
		"desc": "Fewer than there were. Every pack is a head short, and slower to come back to its ground.",
		"say": "This country has been hunted hard: the pack is a head short of what it was."},
	{"id": "hunted", "n": "Hunted out", "word": "hunted out", "col": Color("e09050"), "back": 2.5, "fade": 0.4,
		"desc": "What is left is followed by what eats the leavings. The towns that hear of this country have less in the pot.",
		"say": "This country is hunted out. What is left of the pack is not alone: the crows and the rats have come in behind it."},
	{"id": "barren", "n": "Barren", "word": "barren", "col": Color("c85a4a"), "back": 4.0, "fade": 0.75,
		"desc": "One gaunt survivor to a pack, and the scavengers, and the Hunger that follows them. The towns go lean. It will be a week before anything comes back.",
		"say": "This country is barren. One gaunt thing is left of the pack, and behind it comes everything that feeds on an emptied land."},
]
## what comes in behind, and what leads it when nothing else is left
const SCAVENGERS := ["carrion_crow", "midden_rat"]
const HUNGER := "the_hunger"
## what a hunter asks to open three sides of his net (and so much more a great realm), once a day a region
const NET_BASE := 300
const NET_REALM := 100

## What the people of the camps say of a country that has been hunted too hard, by state (2, 3).
const LINES := {
	2: ["Three days I have had the snares out, %s, and brought home a crow. A crow. My wife asked what it was for. I said it was for looking at.",
		"You hear that? No. Nor do I. There used to be a noise in these hills at dusk you could not talk over.",
		"Somebody has been through here killing as if it were threshing. I do not ask who. I only say the rats are bold this year, and they were not before."],
	3: ["There is nothing left to hunt. I say it to you plainly, %s. I have been a hunter thirty years and I am learning to plait baskets.",
		"The crows have it now. Them and the thing that walks behind them. We keep the children in after noon.",
		"My father used to say: open three sides of the net, and take what will not turn aside. Somebody did not have a father like mine."],
}
const NET_ASK := "A net hung on four sides takes everything. Pay the hunter to take three of them down?"

# ---------------------------------------------------------------- strain
## Whether pack `e` is one of the land's own (not a war-band of the story, not of a cave).
static func native(e: Dictionary) -> bool:
	if str(e.get("kind", "")) != "enemy" or e.has("late"):
		return false
	var v: Array = e.get("vis", ["", ""])
	return str(v[0]) == ""

static func _packs(area: String) -> float:
	return maxf(6.0, float(int(Data.AREAS.get(area, {}).get("enemies", 0))))

## The strain on region `area` now, in times its own packs have been put down (eased by the days since).
static func strain(g, area: String) -> float:
	if not g.cull.has(area):
		return 0.0
	var c: Array = g.cull[area]
	var days := maxf(0.0, Almanac.now(g) - float(c[1]))
	return float(c[0]) * pow(0.5, days / HALF) / _packs(area)

static func state_of(s: float) -> int:
	var st := 0
	for k in AT.size():
		if s >= float(AT[k]):
			st = k + 1
	return st

## How region `area` stands: 0 in balance, 1 thinned, 2 hunted out, 3 barren.
static func state(g, area: String) -> int:
	if g.cull.is_empty() or not g.cull.has(area):
		return 0
	return state_of(strain(g, area))

static func info(g, area: String) -> Dictionary:
	return STATES[state(g, area)]

## One of the land's own packs has been put down in `area`.  Told when the country changes for it.
static func culled(g, area: String, n: float = 1.0) -> void:
	if not Data.AREAS.has(area):
		return
	var now := strain(g, area) * _packs(area)
	g.cull[area] = [now + n, Almanac.now(g)]
	poll(g, area)

## Told when region `area` has changed (for the worse as he hunts, for the better as the days pass).
static func poll(g, area: String) -> void:
	var st := state(g, area)
	var was := int(g.cull_told.get(area, 0))
	if st == was:
		return
	g.cull_told[area] = st
	g.weal_n += 1
	g.cull_worst[area] = maxi(st, int(g.cull_worst.get(area, 0)))
	var nm := str(Data.AREAS[area].n)
	if st > was:
		g.toast("%s is %s" % [nm, str(STATES[st].n).to_lower()])
		g.note("%s: %s. %s" % [nm, str(STATES[st].n), str(STATES[st].desc)])
	elif g.started and not g.finished:
		g.toast("%s is coming back: %s" % [nm, str(STATES[st].n).to_lower()])
		if st == 0:
			g.note("%s is in balance again" % nm)

## Looked at once a day: what the days have mended.
static func poll_all(g) -> void:
	for a in g.cull.keys():
		poll(g, str(a))
		if strain(g, str(a)) < 0.02:
			g.cull.erase(a)

## How many of the regions he has hunted in stand at `st` or worse now.
static func count(g, st: int) -> int:
	var n := 0
	for a in g.cull:
		if state(g, str(a)) >= st:
			n += 1
	return n

## How many regions have ever been brought to `st` or worse by him.
static func worst_count(g, st: int) -> int:
	var n := 0
	for a in g.cull_worst:
		if int(g.cull_worst[a]) >= st:
			n += 1
	return n

## Whether the wild stands (nothing he has hunted in is worse than thinned).
static func stands(g) -> bool:
	return count(g, 2) == 0

# ---------------------------------------------------------------- what it changes
## How many times as long a pack of `area` takes to come back.
static func back(g, area: String) -> float:
	return float(STATES[state(g, area)].back) if not g.cull.is_empty() else 1.0

## How much of its colour region `area` has lost (0..1): drawn by the world.
static func fade(g, area: String) -> float:
	return float(STATES[state(g, area)].fade) if not g.cull.is_empty() else 0.0

## The heads pack `e` fights with in a region that stands at `st` (the land's own packs only): a head
## short when thinned; the first of them and the scavengers when hunted out; one gaunt survivor, the
## scavengers and the Hunger when barren.  Nothing here is past the last level there is.
static func group_at(grp: Array, st: int, seed_: int = 0) -> Array:
	if st <= 0 or grp.is_empty():
		return grp
	var out: Array = []
	var lv := 0
	for f in grp:
		lv = maxi(lv, int(f.lv))
	if st == 1:
		out = grp.duplicate()
		if out.size() > 1:
			out.pop_back()
		return out
	var first: Dictionary = (grp[0] as Dictionary).duplicate()
	if st >= 3:
		first["mult"] = float(first.get("mult", 1.0)) * 0.8
		first["gaunt"] = true
	out.append(first)
	var extra := maxi(1, grp.size() - 1) if st == 2 else maxi(2, grp.size() - 1)
	for k in mini(extra, 3):
		out.append({"id": str(SCAVENGERS[(absi(seed_) + k) % SCAVENGERS.size()]), "lv": lv})
	if st >= 3 and out.size() < 5:
		out.append({"id": HUNGER, "lv": mini(Data.MAX_LEVEL, lv + 1), "atk": 1.1, "elder": true})
	return out

## The heads pack `e` fights with now (after whatever the days have grown it to, almanac.gd).
static func group(g, e: Dictionary, grp: Array) -> Array:
	if g.cull.is_empty() or not native(e):
		return grp
	return group_at(grp, state(g, str(e.get("area", g.area))), absi(hash(str(e.id))))

## What the towns feel of the regions they hear of (weal.gd): [{m, d, why}].
static func town_causes(g, areas: Array) -> Array:
	var out: Array = []
	if g.cull.is_empty():
		return out
	var worst := 0
	var where := ""
	var n := 0
	for a in areas:
		var st := state(g, str(a))
		if st >= 2:
			n += 1
			if st > worst:
				worst = st
				where = str(Data.AREAS[str(a)].n)
	if worst == 2:
		out.append({"m": "plenty", "d": -mini(3, n), "why": "%s is hunted out: nothing for the pot, and the rats are in the grain." % where})
	elif worst >= 3:
		out.append({"m": "plenty", "d": -mini(5, 2 + n), "why": "%s is barren: no game, no hides, no tallow." % where})
		out.append({"m": "regard", "d": -1, "why": "They know who emptied %s." % where})
	return out

## A number for weal.gd's memory of how the towns stand (it moves when a region changes state).
static func stamp(g) -> int:
	var n := 0
	for a in g.cull_told:
		n += int(g.cull_told[a]) * 7 + 1
	return n

## What one of the people of a camp says of his own country ("" while it is no worse than thinned).
static func line(g, area: String, seed_: int) -> String:
	var st := state(g, area)
	if st < 2:
		return ""
	var pool: Array = LINES[st]
	return str(pool[absi(seed_) % pool.size()])

# ---------------------------------------------------------------- three sides of the net
static func net_price(g) -> int:
	return NET_BASE + NET_REALM * int(g.realm())

## Why a hunter of `area` cannot be paid to open his net now ("" if he can).
static func net_blocked(g, area: String) -> String:
	if state(g, area) < 1:
		return "\"The net is as my father hung it, and the hills are full. Come back when they are not; I hope you never do.\""
	if int(g.nets.get(area, -1)) == int(g.day):
		return "\"Three sides are down already. I cannot take down the fourth, or it is not a net; it is a piece of string.\""
	if int(g.stones) < net_price(g):
		return "\"I have children, cultivator. An open net catches a third of a closed one. Somebody has to make up the two thirds.\""
	return ""

## Pay the hunter: three sides come down and the strain of his country is halved.
static func open_net(g, area: String) -> bool:
	if net_blocked(g, area) != "":
		return false
	g.stones -= net_price(g)
	g.nets[area] = int(g.day)
	g.nets_opened += 1
	g.cull[area] = [strain(g, area) * _packs(area) * 0.5, Almanac.now(g)]
	poll(g, area)
	return true

## "The Whispering Bamboo Forest hunted out, Thunder Valley thinned" or "the wild stands".
static func text(g) -> String:
	var parts: Array = []
	for a in g.cull:
		var st := state(g, str(a))
		if st > 0:
			parts.append("%s %s" % [str(Data.AREAS[str(a)].n), str(STATES[st].word)])
	return "the wild stands" if parts.is_empty() else ", ".join(parts)

## What the end says of the land (for the journey that emptied some of it).
static func epilogue(g) -> Array:
	var out: Array = []
	var n := worst_count(g, 3)
	if n > 0:
		for a in g.cull_worst:
			if int(g.cull_worst[a]) >= 3:
				out.append("In %s the old hunters still show the children where the deer used to cross. The children are polite about it. %s" % [str(Data.AREAS[str(a)].n), "It was not the only country he emptied." if n > 1 else "Something has begun to come back; it is not the same thing."])
				break
	return out

# ---------------------------------------------------------------- what is drawn
## Carrion crows turning over a country that has been emptied: built from code, turned by the world.
static func crows(n: int) -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("16141a")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in n:
		var bird := Node3D.new()
		var body := MeshInstance3D.new()
		var bm := PrismMesh.new()
		bm.size = Vector3(0.16, 0.5, 0.05)
		body.mesh = bm
		body.rotation = Vector3(deg_to_rad(90.0), 0, 0)
		body.material_override = mat
		bird.add_child(body)
		for s in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			var wm := PrismMesh.new()
			wm.size = Vector3(0.62, 0.3, 0.02)
			wm.left_to_right = 0.0 if s > 0.0 else 1.0
			wing.mesh = wm
			wing.rotation = Vector3(deg_to_rad(90.0), 0, 0)
			wing.position = Vector3(0.33 * s, 0.0, 0.02)
			wing.material_override = mat
			wing.set_meta("side", s)
			bird.add_child(wing)
		var a := TAU * float(i) / float(maxi(1, n))
		bird.set_meta("a", a)
		bird.set_meta("r", 7.0 + 3.0 * float(i % 3))
		bird.set_meta("h", 9.0 + 1.6 * float(i % 4))
		root.add_child(bird)
	return root

## Turn the crows of `root` about `at` at time `t`.
static func turn_crows(root: Node3D, at: Vector3, t: float) -> void:
	for bird in root.get_children():
		var a := float(bird.get_meta("a")) + t * 0.32
		var r := float(bird.get_meta("r"))
		bird.position = at + Vector3(cos(a) * r, float(bird.get_meta("h")) + sin(t * 0.7 + a) * 0.6, sin(a) * r)
		bird.rotation = Vector3(0, -a, deg_to_rad(-14.0))
		for w in bird.get_children():
			if w.has_meta("side"):
				w.rotation.y = float(w.get_meta("side")) * sin(t * 5.0 + a * 3.0) * 0.45
