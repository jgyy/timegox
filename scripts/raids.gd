class_name Raids
extends RefCounted
## Raids on the roads (the Rivers and Lakes release).
##
## Until now a pack stood on its own ground and waited to be walked into.  The springs are drying
## (Part XLI), and what lived by them has come down to where the people are: from the step `OPEN` on,
## **packs go for the people of the road**.  In every region the journey has walked into, on every
## watch of three hours, something is set on: the **camp** at the foot of the region's highest peak
## (folk.gd: the seven people of the road), and a **cart on the high road** (traffic.gd) where the road
## runs through the region.
##
## Nothing is thrown for and nothing is placed in the world.  Which raids are on is a function of the
## realm, the day and the hour (`on`); where each stands is read from the realm's camps and its roads
## (`sites`, worked out once a realm, the first time it is asked); who the raiders are is drawn from
## the region's own pool by the watch (`group`).  The only state is what he broke (`Game.raid_done`:
## region, kind and watch) and how many (`Game.raids_broken`).
##
## **A raid is broken by going there.**  Walking up to it (`at`: within a tile) begins a battle with
## the raiders in earnest (`Main.start_raid`), or, if they are two great realms below him, scatters
## them at his coming (`Game.scatters`), which counts too.  Whoever was set on thanks him, a little
## (`gift`: worth less than the road), the town that hears of that country is the more at peace
## (`Weal.ACTS.rescued`), and it is counted.  A raid nobody breaks is over when the watch is; the
## people of the road say what it cost them (`news`), and nothing else is taken: **no number of any
## town falls because he was elsewhere**.
##
## New step kind `"rescue"` (`n` raids broken since the step began; `layer`: in that realm).  The bot
## goes to the nearest raid of the realm it is in (`nearest`) and fights it as it fights anything.

const OPEN := "s_p41_home"
## hours a watch lasts: eight to the day
const WATCH := 3.0
## how near he must come (tiles, Chebyshev) for the raiders to turn on him
const NEAR := 1
## how far from a town's own road-foot a cart is set on (tiles): never in sight of the gate
const OFF_TOWN := 14
const KINDS := ["camp", "road"]
## what is seen when he comes up to one
const SEEN := {
	"camp": ["The camp fire has been kicked apart. The people of the road are behind the pedlar's handcart with a wood-axe between them, and %s between them and the trees.",
		"Somebody is shouting at the camp, hoarse, the same three words. The hunter has an arrow on the string and no shot: %s, in among the tents."],
	"road": ["A cart is slewed across the road with one wheel in the ditch. The carter is under it. Round it, taking their time, %s.",
		"The ox has broken its trace and gone. The cart has not, and neither has the carter, who is standing on the load with a whip. Below: %s."],
}
## what is said by whoever was set on, once it is over
const THANKS := {
	"camp": [["The Pedlar", "They came down off the hill at the change of the watch, like men going to work. I have sold on this road thirty years. They never used to come to the fire."],
		["The Woodcutter", "I had the axe. I want that known. I had not yet decided where to put it, that is all. Take this. No: take it."]],
	"road": [["The Carter", "Forty years I have driven this road and been robbed by nothing worse than a toll. Take this. It is not what the load is worth. It is what I have."],
		["The Carter", "They went for the ox first. Not the load: the ox. Something has taught them what a cart cannot do without. Here. For the ox."]],
	"fled": [["The Carter", "They ran. They looked up, and saw who was coming along the road, and they ran. I should like to be looked at like that once."],
		["The Pedlar", "Gone, before a blow. Like birds off a field. I do not know what you are, friend, and I am glad of it."]],
}
## what the people of a camp or a town say of a raid nobody broke, the watch after
const NEWS := ["They came at the last watch. Nobody dead. The pedlar's stock is in the river.", "A cart was set on up the road an hour since. The carter walked in. The ox did not.",
	"The fire was kicked out last watch and half the stores gone. They come to people now.", "Raided, at the turn of the watch. They did not use to leave the hills."]

static var _sites := {}

static func open(g) -> bool:
	return g.reached(OPEN) and g.prologue == ""

## The watch of the journey of `g`: a count of the three-hour watches since the first day.
static func watch(g) -> int:
	return int(g.day) * int(24.0 / WATCH) + int(Clock.hour(g) / WATCH)

static func forget() -> void:
	_sites = {}

## Where raids can stand in realm `layer`: {region: {"camp": tile, "road": [tiles]}}.  The camp's tile is
## open ground beside the camp with nothing on it; the road's are tiles of the high road in the region,
## out of sight of any town, with nothing standing on them, every tenth one.
static func sites(layer: String) -> Dictionary:
	if _sites.has(layer):
		return _sites[layer]
	var out := {}
	if layer.begins_with("f:"):
		_sites[layer] = out
		return out
	var wd: Dictionary = Atlas.world_of(layer)
	var W: int = wd.w
	var H: int = wd.h
	var taken := {}
	for e in wd.ents:
		if e.has("pos"):
			taken[e.pos] = true
	var free := func(p: Vector2i) -> bool:
		return p.x > 0 and p.y > 0 and p.x < W - 1 and p.y < H - 1 and MapGen.is_walkable_tile(wd.grid[p.y * W + p.x]) and not taken.has(p)
	var camps: Dictionary = wd.get("camps", {})
	for area in camps:
		# (a country with nothing wild in it of its own, the mountain round the sect, has nobody to come down)
		if not _wild(str(area)):
			continue
		var c: Vector2i = camps[area]
		var best := Vector2i(-1, -1)
		for rad in [5, 6, 4, 7]:
			for dd in [Vector2i(rad, 0), Vector2i(0, rad), Vector2i(-rad, 0), Vector2i(0, -rad), Vector2i(rad, rad), Vector2i(-rad, rad), Vector2i(rad, -rad), Vector2i(-rad, -rad)]:
				var p: Vector2i = c + dd
				var ok: bool = best.x < 0 and free.call(p) and Atlas.owner_id(wd, p) == str(area)
				# (open ground all round it, so that he can come at it from any side)
				for d4 in MapGen.DIRS:
					ok = ok and free.call(p + d4)
				if ok:
					best = p
		if best.x >= 0:
			out[str(area)] = {"camp": best, "road": []}
	var net: Dictionary = Roads.of(layer)
	var feet: Array = (net.get("at", {}) as Dictionary).values()
	var tiles: Array = (net.get("tiles", {}) as Dictionary).keys()
	tiles.sort()
	var k := 0
	for p2 in tiles:
		k += 1
		if k % 10 != 0 or not free.call(p2):
			continue
		var far := true
		for f in feet:
			far = far and maxi(absi(f.x - p2.x), absi(f.y - p2.y)) >= OFF_TOWN
		var a2 := Atlas.owner_id(wd, p2)
		if not far or a2 == "sect" or not _wild(a2):
			continue
		if not out.has(a2):
			out[a2] = {"road": []}
		(out[a2].road as Array).append(p2)
	_sites[layer] = out
	return out

static func _wild(area: String) -> bool:
	return Data.AREAS.has(area) and not (Data.AREAS[area].get("pool", []) as Array).is_empty()

static func _key(area: String, kind: String, w: int) -> String:
	return "%s|%s|%d" % [area, kind, w]

static func _pick(area: String, kind: String, w: int, n: int) -> int:
	return absi(hash(_key(area, kind, w))) % maxi(n, 1)

## The raids that are on in realm `layer` for the journey of `g`, broken or not: [{area, kind, tile, watch,
## key, broken}].  One at the camp and one on the road of every region he has walked into that has them.
static func on(g, layer: String) -> Array:
	var out: Array = []
	if not open(g):
		return out
	var w := watch(g)
	var ss := sites(layer)
	var areas: Array = ss.keys()
	areas.sort()
	for area in areas:
		if not g.seen.has(area):
			continue
		var s: Dictionary = ss[area]
		if s.has("camp"):
			out.append({"area": area, "kind": "camp", "tile": s.camp, "watch": w, "key": _key(area, "camp", w), "broken": g.raid_done.has(_key(area, "camp", w))})
		var rd: Array = s.get("road", [])
		if not rd.is_empty():
			out.append({"area": area, "kind": "road", "tile": rd[_pick(area, "road", w, rd.size())], "watch": w, "key": _key(area, "road", w), "broken": g.raid_done.has(_key(area, "road", w))})
	return out

## The raid he has come up to at `tile` of realm `layer` ({} if there is none there that still stands).
static func at(g, layer: String, tile: Vector2i) -> Dictionary:
	for r in on(g, layer):
		if not r.broken and maxi(absi(r.tile.x - tile.x), absi(r.tile.y - tile.y)) <= NEAR:
			return r
	return {}

## The nearest raid of realm `layer` that still stands, from `tile` ({} if there is none); with `area`, in that region.
static func nearest(g, layer: String, tile: Vector2i, area: String = "") -> Dictionary:
	var best := {}
	var bd := 1 << 30
	for r in on(g, layer):
		if r.broken or (area != "" and str(r.area) != area):
			continue
		var d: int = absi(r.tile.x - tile.x) + absi(r.tile.y - tile.y)
		if d < bd:
			bd = d
			best = r
	return best

## The road tiles of realm `layer` a raid stands on now: a cart does not drive through one (traffic.gd).
static func blocked(g, layer: String) -> Dictionary:
	var out := {}
	for r in on(g, layer):
		if not r.broken and str(r.kind) == "road":
			out[r.tile] = true
	return out

## Who the raiders of `raid` are: two or three of the region's own, by the watch; in a country hunted out
## they are fewer (wilds.gd is asked nothing: a raid is not one of the land's standing packs).
static func group(raid: Dictionary) -> Array:
	var pool: Array = Data.AREAS[str(raid.area)].get("pool", [])
	var out: Array = []
	if pool.is_empty():
		return out
	var h := absi(hash(str(raid.key)))
	for k in 2 + h % 2:
		var pe: Array = pool[(h / (7 + k * 13)) % pool.size()]
		out.append({"id": str(pe[0]), "lv": int(pe[2]) if k == 0 else int(pe[1])})
	return out

## The raiders, named: "two Reavers of the Reed-Banks and a Carp Left on the Mud".
static func named(raid: Dictionary) -> String:
	var counts := {}
	var order: Array = []
	for f in group(raid):
		if not counts.has(f.id):
			order.append(f.id)
		counts[f.id] = int(counts.get(f.id, 0)) + 1
	var bits: Array = []
	for id in order:
		var n: String = str(Data.ENEMIES[id].n)
		bits.append(("a %s" % n) if int(counts[id]) == 1 else ("%s of the %s kind" % [Weal.NUMBER_WORDS[int(counts[id])], n]))
	return " and ".join(bits)

static func seen_line(raid: Dictionary) -> String:
	var ls: Array = SEEN[str(raid.kind)]
	return str(ls[absi(hash(str(raid.key))) % ls.size()]) % named(raid)

## What whoever was set on presses on him afterwards (spirit stones: less than the road pays).
static func gift(g) -> int:
	return 60 + 14 * int(g.level)

## The town that hears of region `area` ("" if none does).
static func town(area: String) -> String:
	for tid in Weal.ORDER:
		if area in (Weal.TOWNS[tid].areas as Array):
			return str(tid)
	return ""

## The raid is broken (`fled`: the raiders ran from his realm before a blow).  Returns what is said after.
static func broke(g, raid: Dictionary, fled: bool = false) -> Array:
	if raid.is_empty() or g.raid_done.has(str(raid.key)):
		return []
	# (only this watch's are remembered: an older key can never be asked for again)
	for k in g.raid_done.keys():
		if int(str(k).get_slice("|", 2)) < int(raid.watch) - 1:
			g.raid_done.erase(k)
	g.raid_done[str(raid.key)] = true
	g.raids_broken = int(g.raids_broken) + 1
	# (a step that asks for raids of one realm counts those)
	var want := str(g.cur_step().get("layer", ""))
	if want == "" or Data.layer_of(str(raid.area)) == want:
		g.step_raids = int(g.step_raids) + 1
	if fled:
		g.raids_fled = int(g.raids_fled) + 1
	var n := gift(g) / (2 if fled else 1)
	g.stones += n
	g.toast("A raid broken: +%d spirit stones" % n)
	g.note("Broke a raid on the %s in %s" % ["camp" if str(raid.kind) == "camp" else "road", str(Data.AREAS[str(raid.area)].n).split(",")[0]])
	var tid := town(str(raid.area))
	if tid != "" and tid in Weal.towns(g):
		Weal.act(g, tid, "rescued")
	g.poll_steps()
	var ls: Array = THANKS["fled" if fled else str(raid.kind)]
	return [ls[absi(hash(str(raid.key))) % ls.size()]]

## What is said in region `area` of a raid of the last watch that nobody broke ("" before the raids began, and
## in a region with nothing to raid).
static func news(g, area: String, seed: int) -> String:
	if not open(g) or not sites(Data.layer_of(area)).has(area):
		return ""
	# (what he broke last watch is not news of that kind)
	var w := watch(g) - 1
	if g.raid_done.has(_key(area, "camp", w)) or g.raid_done.has(_key(area, "road", w)):
		return ""
	return str(NEWS[absi(seed + watch(g)) % NEWS.size()])

## How many raids of realm `layer` still stand.
static func standing(g, layer: String) -> int:
	var n := 0
	for r in on(g, layer):
		if not r.broken:
			n += 1
	return n
