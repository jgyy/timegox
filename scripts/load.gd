class_name Load
extends RefCounted
## The Heavy Road release: what things weigh, and who carries them.
##
## Until this release a sweeper could put a mountain in his sleeve.  Now everything Lin Feng has is on
## his back, in jin (a catty: about half a kilogram), and his back has a size:
##
##   * **what a thing weighs** (`weight_of`): the **goods** of the land (`GOODS`: timber, stone, ore,
##     fish, herbs, charcoal, toil.gd) are what makes a load: a stem of timber is thirty jin and a
##     dressed block forty-five.  The tools weigh what tools weigh, and food what food does.  What a
##     search of the story is looking for weighs about a jin, or what `WEIGHTS` says it would in the
##     hand, until it is handed to whoever asked (`handed`: the step is done), and then nothing.
##     **Everything else weighs nothing**: a pill, an essence (a mote of light), a keepsake, a token, a
##     thing made for a trial.  A journey gathers thousands of those, and a sleeve is deep enough for
##     what has no bulk; it is bulk that a back knows about.
##   * **what he can bear** (`cap`): sixty jin as a sweeper, two more for every great realm (a body that
##     is cultivated is a strong one), two fifths as much again with Yue Ling along (she takes her
##     share, and is drawn carrying it), forty more with a pack-frame, and whatever he rides while he
##     rides it: a horse, a qilin or a tiger bears a hundred and sixty jin, a carriage six hundred.  A
##     flying sword or a cloud is his own qi and lifts no more than he can.
##   * **what it costs** (`tier`, `pace`): under half of it he walks as he always did; up to all of it
##     he is laden (drawn with the load, and no slower); over it he is heavy (half as slow again, on a
##     clip of its own, off the sword and under no kite); past half as much again he staggers, and can
##     take up nothing more that the land gives.  Nothing the story hands him is ever refused, and
##     nobody is ever stopped: a load only slows.
##   * **where it can be left** (`at_home`, `stow`, `fetch`): the storehouse of the sect, and the
##     steward's yard at Guiyun once the town stands.  What is left there weighs nothing and waits.
##   * **the two things everybody wants** (`POUCH`, `RING`): a pouch of heaven and earth, sewn only for
##     somebody who has carried enough on his own back to know what it is for (`pouch_blocked`), and the
##     Mustard-Seed Ring, which is not for sale anywhere and is given once, at the end of Part XXVII.
##     The pouch takes the first three hundred jin as if they were thirty; the ring takes everything.
##
## Nothing here is random, and nothing but `Game.stash`, `Game.hauled` and the bag keeps state.  The
## bot's journey before Part XXVII never passes "laden" (the tests walk the story and weigh it), so
## every older road is walked exactly as it was.

const BASE := 60.0
const PER_REALM := 2.0
const WITH_YUE := 0.4
const FRAME := 40.0
const BY_RIDE := {"mount": 160.0, "carriage": 600.0}
## what a load is called by how much of the back it takes, and how much slower a step is under it
const TIERS := ["light", "laden", "heavy", "staggering"]
const PACE := [1.0, 1.0, 1.5, 2.2]
const TIER_AT := [0.5, 1.0, 1.5]
const TIER_TEXT := ["He walks as if he carried nothing.", "A full load, carried well: no slower for it.",
	"More than his back was made for: half as slow again, off the sword and under no kite.",
	"He staggers: every step is two, and he can take up nothing more."]

## the pouch of heaven and earth and the Mustard-Seed Ring (items of Data.ITEMS)
const POUCH := "qiankun_pouch"
const RING := "mustard_ring"
const FRAME_ITEM := "pack_frame"
## the pouch: how much goes into it, and what that much weighs once it is in
const POUCH_HOLDS := 300.0
const POUCH_K := 0.1
## what Old Hu the gourd-seller asks before he will sew one: a great realm (the mouth of it is opened
## with the spirit, not the fingers), so many jin carried a league on the hero's own back, essences of
## metal and of the dark, and more spirit stones than a hall costs
const POUCH_NEEDS := {"realm": 3, "hauled": 3000, "stones": 30000, "items": {"ess_metal": 30, "ess_dark": 30}}

## the goods of the land: what the hands take from it (toil.gd), what each weighs and what a pedlar
## of the road gives for one (a day of it is worth less than the road)
const GOODS := {
	"timber": {"jin": 30.0, "sell": 14, "bulk": "logs"},
	"stone_block": {"jin": 45.0, "sell": 18, "bulk": "stone"},
	"ore_lump": {"jin": 20.0, "sell": 16, "bulk": "stone"},
	"carp": {"jin": 3.0, "sell": 5, "bulk": "fish"},
	"herb_bundle": {"jin": 1.0, "sell": 3, "bulk": "herbs"},
	"charcoal": {"jin": 25.0, "sell": 20, "bulk": "sacks"},
}
const GOOD_ORDER := ["timber", "stone_block", "ore_lump", "charcoal", "carp", "herb_bundle"]

## what a pedlar of the road or Smith Tie sells for carrying and for the work of the hands
const WARES := {
	"axe": {"price": 30}, "fishing_rod": {"price": 20}, "pick": {"price": 40}, "sickle": {"price": 15},
	"pack_frame": {"price": 400},
}
const WARE_ORDER := ["axe", "fishing_rod", "pick", "sickle", "pack_frame"]

## what the tools and the food weigh, and what a thing a search of the story looks for weighs in the
## hand where it is not about a jin
const WEIGHTS := {
	"steamed_bun": 0.3, "tea_egg": 0.2, "dried_meat": 0.5, "noodle_bowl": 1.0,
	"axe": 4.0, "fishing_rod": 1.0, "pick": 5.0, "sickle": 1.0,
	"ingot": 12.0, "five_stone": 6.0, "earth_basket": 22.0, "argal": 4.0, "frolic_tablet": 8.0, "whetstone": 3.0, "sword_blank": 6.0,
	"fallen_star": 5.0, "silver_needle": 0.1, "datura_flower": 0.1, "tiger_tally": 2.0, "feather_cloud": 0.1,
	"tao_brick": 12.0, "red_gauze": 0.5, "scroll_case": 3.0, "pagoda_tile": 9.0,
}
## what is carried about and is not a good, a tool or food: weighed only while a search asks for it
const SOUGHT := 1.0

# ---------------------------------------------------------------- what things weigh
## What one of item `id` weighs in jin, in the hand.
static func weight_of(id: String) -> float:
	if GOODS.has(id):
		return float(GOODS[id].jin)
	if WARES.has(id) or Needs.FOOD.has(id):
		return float(WEIGHTS.get(id, 0.0))
	# (what a search of the story looks for; anything else has no bulk)
	if _asked_at(id) >= 0:
		return float(WEIGHTS.get(id, SOUGHT))
	return 0.0

static var _asked := {}

## The last step of the story that asks for item `id` to be found (-1 if none does).
static func _asked_at(id: String) -> int:
	if _asked.is_empty():
		for i in Data.STEPS.size():
			var s: Dictionary = Data.STEPS[i]
			if str(s.kind) == "collect":
				_asked[str(s.item)] = i
		_asked["#"] = -1
	return int(_asked.get(id, -1))

## Has what was found of `id` been handed to whoever asked for it?  (The step that asked is done.)
static func handed(g, id: String) -> bool:
	var at := _asked_at(id)
	return at >= 0 and int(g.step) > at

## How many of `id` are on his back (not handed over).
static func carried(g, id: String) -> int:
	var n := int(g.inv.get(id, 0))
	return 0 if n <= 0 or handed(g, id) else n

## Everything on his back in the hand, before any pouch: jin.
static func gross(g) -> float:
	var w := 0.0
	for id in g.inv:
		w += weight_of(str(id)) * float(carried(g, str(id)))
	return w

## What his back feels of it: nothing with the ring on, the first three hundred jin a tenth with the pouch.
static func weight(g) -> float:
	var w := gross(g)
	if int(g.inv.get(RING, 0)) > 0:
		return 0.0
	if int(g.inv.get(POUCH, 0)) > 0:
		var inside := minf(w, POUCH_HOLDS)
		return inside * POUCH_K + (w - inside)
	return w

# ---------------------------------------------------------------- what he can bear
## The jin he can carry all day.  `riding`: is he in the saddle or on the box just now (world.riding_here)?
static func cap(g, riding: bool = false) -> float:
	var c := BASE + PER_REALM * float(Data.realm_of(int(g.level)))
	if bool(g.companion):
		c *= 1.0 + WITH_YUE
	if int(g.inv.get(FRAME_ITEM, 0)) > 0:
		c += FRAME
	if riding and str(g.ride) != "":
		c += float(BY_RIDE.get(str(Fashion.RIDES.get(str(g.ride), {}).get("kind", "")), 0.0))
	return c

static func ratio(g, riding: bool = false) -> float:
	return weight(g) / maxf(cap(g, riding), 1.0)

## 0 light, 1 laden, 2 heavy, 3 staggering.
static func tier(g, riding: bool = false) -> int:
	var r := ratio(g, riding)
	for i in TIER_AT.size():
		if r <= float(TIER_AT[i]) + 0.0001:
			return i
	return 3

## How many times as long a step takes under what he carries.
static func pace(g, riding: bool = false) -> float:
	return float(PACE[tier(g, riding)])

## Is what he carries more than his own qi will lift (a flying sword, a cloud, the kite)?
static func grounded(g) -> bool:
	return tier(g) >= 2

## Can he take up `n` more of good `id` from the land?  (He staggers already, or would: "" if he can,
## else why not.  What the story hands him is never asked.)
static func refuses(g, id: String, n: int = 1) -> String:
	if int(g.inv.get(RING, 0)) > 0:
		return ""
	if tier(g) >= 3:
		return "He cannot lift another thing: what he carries is more than half again what his back was made for."
	return ""

## How many of good `id` he can take up and still walk at his own pace (never fewer than one).
static func room_for(g, id: String) -> int:
	var each := weight_of(id) * (POUCH_K if int(g.inv.get(POUCH, 0)) > 0 else 1.0)
	if int(g.inv.get(RING, 0)) > 0 or each <= 0.0:
		return 99
	return maxi(1, int(floor((cap(g) - weight(g) + 0.0001) / each)))

## A step is walked under what he carries: so many jin, one tile further (the pouch-maker counts it).
static func walked(g, riding: bool) -> void:
	if riding:
		return
	var w := gross(g)
	if w >= cap(g) * float(TIER_AT[0]) and int(g.inv.get(RING, 0)) <= 0:
		g.hauled += w / 500.0

## The jin carried a league on his own back so far (five hundred tiles under a jin is one).
static func hauled(g) -> int:
	return int(floor(float(g.hauled) + 0.0001))

# ---------------------------------------------------------------- what is drawn on his back
## What the load looks like: "" (nothing to see), or the kind of the heaviest goods he has ("logs",
## "stone", "sacks", "fish", "herbs"), or "pack" for a load of small things; and how full, 0 to 1.
static func look(g) -> Array:
	if int(g.inv.get(RING, 0)) > 0 or tier(g) < 1:
		return ["", 0.0]
	var best := "pack"
	var bw := 0.0
	for id in GOOD_ORDER:
		var w := weight_of(id) * float(carried(g, id))
		if w > bw:
			bw = w
			best = str(GOODS[id].bulk)
	if bw < gross(g) * 0.3:
		best = "pack"
	return [best, clampf(ratio(g), 0.5, 1.6)]

# ---------------------------------------------------------------- the storehouse
## Where things can be left: the sect's storehouse, and the steward's yard at Guiyun once it stands.
static func at_home(g, area: String, tile: Vector2i) -> String:
	if area == "sect":
		return "the storehouse of the Azure Cloud Sect"
	if area == Hold.AREA and Hold.founded(g):
		var r := Rect2i(Atlas.to_world(Hold.AREA, Hold.AT) - Vector2i(2, 2), Hold.SIZE + Vector2i(4, 4))
		if r.has_point(tile):
			return "the steward's yard at Guiyun"
	return ""

## What could be left behind: everything on his back that the road does not need at once (not the
## pills, the tools, the pouch or the ring), heaviest first.
static func stowable(g) -> Array:
	var out: Array = []
	for id in g.inv:
		var sid := str(id)
		if carried(g, sid) <= 0 or WARES.has(sid):
			continue
		if weight_of(sid) * float(carried(g, sid)) >= 1.0:
			out.append(sid)
	out.sort_custom(func(a, b): return weight_of(a) * float(carried(g, a)) > weight_of(b) * float(carried(g, b)))
	return out

static func stow(g, id: String) -> int:
	var n := carried(g, id)
	if n <= 0:
		return 0
	g.inv[id] = int(g.inv[id]) - n
	g.stash[id] = int(g.stash.get(id, 0)) + n
	return n

static func fetch(g, id: String) -> int:
	var n := int(g.stash.get(id, 0))
	if n <= 0:
		return 0
	g.stash.erase(id)
	g.inv[id] = int(g.inv.get(id, 0)) + n
	return n

# ---------------------------------------------------------------- buying, selling, the pouch
## What a pedlar gives for everything of the land's goods on his back: [stones, pieces].
static func sale(g) -> Array:
	var st := 0
	var n := 0
	for id in GOOD_ORDER:
		var c := carried(g, id)
		st += c * int(GOODS[id].sell)
		n += c
	return [st, n]

static func sell_all(g) -> Array:
	var s := sale(g)
	for id in GOOD_ORDER:
		if carried(g, id) > 0:
			g.inv[id] = 0
	g.stones += int(s[0])
	g.sold += int(s[1])
	return s

## Buy ware `id` ("" if it was bought, else why not).
static func buy(g, id: String) -> String:
	if not WARES.has(id):
		return "Nobody sells that."
	if int(g.inv.get(id, 0)) > 0:
		return "He has one already."
	if int(g.stones) < int(WARES[id].price):
		return "Not enough spirit stones."
	g.stones -= int(WARES[id].price)
	g.add_item(id)
	return ""

## Why the pouch cannot be sewn yet ("" if it can): each thing still wanting, said plainly.
static func pouch_blocked(g) -> String:
	if int(g.inv.get(POUCH, 0)) > 0 or int(g.inv.get(RING, 0)) > 0:
		return "He has no need of another."
	var miss: Array = []
	if Data.realm_of(int(g.level)) < int(POUCH_NEEDS.realm):
		miss.append("the realm of %s (its mouth is opened with the spirit, not the fingers)" % str(Data.REALMS[int(POUCH_NEEDS.realm)]))
	if hauled(g) < int(POUCH_NEEDS.hauled):
		miss.append("%d jin carried a league on your own back (%d so far)" % [int(POUCH_NEEDS.hauled), hauled(g)])
	for k in POUCH_NEEDS.items:
		if int(g.inv.get(k, 0)) < int(POUCH_NEEDS.items[k]):
			miss.append("%d %s (%d)" % [int(POUCH_NEEDS.items[k]), str(Data.ITEMS[k].n), int(g.inv.get(k, 0))])
	if int(g.stones) < int(POUCH_NEEDS.stones):
		miss.append("%d spirit stones" % int(POUCH_NEEDS.stones))
	return "" if miss.is_empty() else "Still wanting: " + "; ".join(miss) + "."

static func sew_pouch(g) -> bool:
	if pouch_blocked(g) != "":
		return false
	g.stones -= int(POUCH_NEEDS.stones)
	for k in POUCH_NEEDS.items:
		g.inv[k] = int(g.inv[k]) - int(POUCH_NEEDS.items[k])
	g.add_item(POUCH)
	g.note("A pouch of heaven and earth, sewn by a pedlar of the road")
	return true

# ---------------------------------------------------------------- said on the page
static func text(g, riding: bool = false) -> String:
	if int(g.inv.get(RING, 0)) > 0:
		return "Everything he has is in the Mustard-Seed Ring, and the ring weighs what a ring weighs."
	return "%d of %d jin: %s. %s" % [int(round(weight(g))), int(round(cap(g, riding))), str(TIERS[tier(g, riding)]), str(TIER_TEXT[tier(g, riding)])]

## The lines of the page: [name, count, jin] of everything on his back that has any bulk, heaviest first.
static func rows(g) -> Array:
	var out: Array = []
	for id in g.inv:
		var sid := str(id)
		var n := carried(g, sid)
		# (what has no bulk is not on the page: it is in a sleeve)
		if n > 0 and Data.ITEMS.has(sid) and weight_of(sid) > 0.0:
			out.append([str(Data.ITEMS[sid].n), n, weight_of(sid) * float(n)])
	out.sort_custom(func(a, b): return float(a[2]) > float(b[2]))
	return out
