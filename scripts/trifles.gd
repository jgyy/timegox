class_name Trifles
extends RefCounted
## The Unpicked Road release: the small things.  The land was full of what people own and leave
## about (havoc.gd: jars, crates, woodpiles), and every one of them could only be broken.  These are
## the things a hand closes on: a bun on a tray by the kitchen wall, a child's cloth tiger on a step, a
## pipe left on a bench, a peach on the offering table, a purse somebody dropped in the road this
## morning, a feather in the grass.  Forty-seven kinds in five classes:
##
##   ware    a seller's, set out by the wall of the shop, the inn, the tea-house, the smithy: taken, it
##           is bought or it is pocketed
##   keep    somebody's own, by the house they live in: a toy, a broom, a pipe, a pair of sandals
##   altar   what was laid before a shrine: it was given already, and not to him
##   lost    dropped in the road of a town, new every morning (by the day, never by lot): it has an
##           owner and a door, and can be carried to either
##   wild    nobody's: a feather, a cone, a shell, a husk
##
## **Nothing is placed in the world for them**: no entity, so no map moves.  Where each lies is read
## from the town's own buildings and roads (`stood`, `lost`, `wild`, as havoc.gd reads where a jar
## stands), a thing lies on a tile that is walked over, and what has been taken is game state
## (`Game.trifles`: id -> the day it was taken; `Game.pocket`: what is in his sleeve).  So the bot and
## the tests see the same things without drawing any of them.  They weigh nothing (load.gd: only bulk
## weighs), and a sleeve holds `SLEEVE` of them.
##
## What is done with one is answered by whoever sees it done (manners.gd): the seller names a price, a
## child wails for a tiger, a watchman says whose purse that is and where she lives.  Pocketing what is
## somebody's, seen, is a small charge at the town's gate (crime.gd, "theft") and is remembered in its
## streets (weal.gd, "pilfer"); carrying what was lost to its owner, or to their door, is remembered
## too ("restored"), and both are weighed in the Way he walks (creed.gd).  Nothing here is random.
##
## The story asks for it with two step kinds: `"restore"` (`n` lost things brought to whose they are
## since the step began; `area` says where to look) and `"leap"` (world.gd: `n` leaps since the step
## began).  The bot does both by itself (`_restore_step`, `_leap_step`); it buys nothing, pockets
## nothing and breaks nothing.

## how many small things a sleeve holds
const SLEEVE := 6
## how many things are dropped in the road of a town each day, and how far from its heart
const LOST_N := 4
const LOST_REACH := 16
## how many things nobody owns lie in a region
const WILD_N := 14
## what is given for a lost thing brought home: so many spirit stones, and so many more a great realm
## (worth less than the road: a pack of the wild pays more)
const THANKS := 4
const THANKS_REALM := 3

## kind -> what it is called (after "a"/"an"/"the": `art`), its class, what a ware costs, who would
## own it (`own`: "kid", "old", "trade", or anybody), whether a blow breaks it (`frail`), whether it
## can be eaten or played with where it lies (`use`), its colour, and for a keep what its owner says
## as it goes (`mine`), for a lost thing what is said when it comes home (`thanks`)
const KINDS := {
	# ---- wares
	"bun": {"n": "steamed bun", "cls": "ware", "price": 2, "use": "eat", "col": Color("f0e8d8")},
	"pear": {"n": "pear", "cls": "ware", "price": 2, "use": "eat", "col": Color("d8d070")},
	"candied_haw": {"n": "stick of candied haws", "cls": "ware", "price": 3, "use": "eat", "col": Color("c8282a")},
	"teacup": {"n": "teacup", "cls": "ware", "price": 4, "frail": true, "col": Color("e8f0f0")},
	"wine_gourd": {"n": "gourd of wine", "cls": "ware", "price": 6, "col": Color("c89a50")},
	"fan": {"n": "paper fan", "cls": "ware", "price": 5, "col": Color("f0e8d0")},
	"comb": {"n": "wooden comb", "cls": "ware", "price": 4, "col": Color("8a5a34")},
	"horseshoe": {"n": "horseshoe", "cls": "ware", "price": 5, "col": Color("5a5a62")},
	"nails": {"n": "paper of nails", "cls": "ware", "price": 3, "col": Color("d8d0b8")},
	"pill_gourd": {"n": "gourd of pills", "cls": "ware", "price": 12, "col": Color("7aa860")},
	"brush": {"n": "writing brush", "cls": "ware", "price": 6, "col": Color("3a2a20")},
	"dried_fish": {"n": "dried fish", "cls": "ware", "price": 3, "use": "eat", "col": Color("b0a888")},
	# ---- somebody's own
	"cloth_tiger": {"n": "cloth tiger", "cls": "keep", "own": "kid", "col": Color("e8a030"), "mine": "My tiger! That is MY tiger! He sleeps on my pillow!"},
	"ball": {"n": "stitched ball", "cls": "keep", "own": "kid", "use": "play", "col": Color("c83a3a"), "mine": "That is our ball. We were only gone for our dinner."},
	"top": {"n": "spinning top", "cls": "keep", "own": "kid", "use": "play", "col": Color("3a7ac8"), "mine": "My top! I had it going a hundred turns. Ask anybody."},
	"broom": {"n": "broom", "cls": "keep", "col": Color("c8a860"), "mine": "The broom? You of all people want my broom?"},
	"sandals": {"n": "pair of straw sandals", "cls": "keep", "col": Color("d0b878"), "mine": "Those are mine. I walk to the fields in those."},
	"washing_bat": {"n": "washing bat", "cls": "keep", "col": Color("9a7048"), "mine": "My bat! My mother beat sheets with that before I could walk."},
	"pipe": {"n": "long pipe", "cls": "keep", "own": "old", "col": Color("6a4a2a"), "mine": "I shall want that pipe back. It is forty years broken in."},
	"straw_hat": {"n": "straw hat", "cls": "keep", "col": Color("d8c070"), "mine": "My hat. It will rain the moment that is gone, you watch."},
	"cricket_cage": {"n": "cricket cage", "cls": "keep", "own": "old", "frail": true, "col": Color("b89858"), "mine": "Gently! General Black is in there. He has won eleven bouts."},
	"chess_piece": {"n": "chess piece", "cls": "keep", "own": "old", "col": Color("e8e0c8"), "mine": "That is my chariot. The game has stood at that move since spring."},
	"practice_sword": {"n": "wooden practice sword", "cls": "keep", "col": Color("a8824a"), "mine": "That is my practice sword. It has my thumb worn into it."},
	# ---- what was laid before a shrine
	"offering_peach": {"n": "peach from the offering table", "cls": "altar", "use": "eat", "col": Color("f0a8a0")},
	"incense": {"n": "bundle of incense", "cls": "altar", "col": Color("a84a3a")},
	"prayer_slip": {"n": "prayer slip", "cls": "altar", "col": Color("e8d8a0")},
	"altar_coin": {"n": "copper from the offering dish", "cls": "altar", "col": Color("b87a3a")},
	# ---- dropped in the road
	"purse": {"n": "purse", "cls": "lost", "col": Color("7a3a5a"), "thanks": "The rice money. All of it, to the copper. I had told nobody; I did not know how to."},
	"hairpin": {"n": "silver hairpin", "cls": "lost", "own": "fem", "col": Color("d8d8e0"), "thanks": "My mother's pin. I had my hair up with a chopstick all day, and said it was the fashion."},
	"letter": {"n": "sealed letter", "cls": "lost", "col": Color("f0e8d0"), "thanks": "Unopened. ...You did not read it. No. I can see by your face you did not."},
	"small_shoe": {"n": "child's shoe", "cls": "lost", "own": "kid", "col": Color("c83a3a"), "thanks": "My shoe! I hopped home. I said I had not lost it, I had only left it somewhere."},
	"name_seal": {"n": "name seal", "cls": "lost", "own": "trade", "col": Color("b84a3a"), "thanks": "My seal. Without that I am nobody: I cannot so much as sign for a sack of flour."},
	"cash_string": {"n": "string of cash", "cls": "lost", "col": Color("b87a3a"), "thanks": "A hundred on the string, and a hundred still. I counted. Forgive me; anybody would."},
	"pendant": {"n": "jade pendant", "cls": "lost", "col": Color("8ad0a0"), "thanks": "It was my father's. The cord is older than I am; I knew it would go one day."},
	"rattle": {"n": "rattle-drum", "cls": "lost", "own": "kid", "col": Color("d84a3a"), "thanks": "It is for the baby. He would not sleep without it. Nobody in our house has slept."},
	"key": {"n": "iron key", "cls": "lost", "own": "trade", "col": Color("4a4a52"), "thanks": "The key of the store. I have been sitting on the step since noon, looking honest."},
	"longevity_lock": {"n": "longevity lock", "cls": "lost", "own": "kid", "col": Color("e0d090"), "thanks": "Granny said if I lost it I should not live to be a hundred. Now I shall again."},
	"needle_case": {"n": "needle case", "cls": "lost", "own": "fem", "col": Color("a86a8a"), "thanks": "Nine needles and my good thimble. A woman without them is a guest in her own house."},
	"reading_stone": {"n": "reading stone", "cls": "lost", "own": "old", "col": Color("d0e8f0"), "thanks": "My eyes! I have been reading the almanac with my finger, and it has not been reading back."},
	# ---- nobody's
	"feather": {"n": "pheasant's feather", "cls": "wild", "col": Color("b8743a")},
	"pine_cone": {"n": "pine cone", "cls": "wild", "col": Color("6a4a2a")},
	"pebble": {"n": "smooth pebble", "cls": "wild", "col": Color("9a9a98"), "water": true},
	"shell": {"n": "river shell", "cls": "wild", "col": Color("e8d8d0"), "water": true},
	"mushroom": {"n": "wood-ear mushroom", "cls": "wild", "use": "eat", "col": Color("5a4038")},
	"antler": {"n": "shed antler", "cls": "wild", "col": Color("d8c8a0")},
	"cicada_husk": {"n": "cicada husk", "cls": "wild", "col": Color("b08a50")},
	"blossom": {"n": "fallen spray of blossom", "cls": "wild", "col": Color("f0b8c8")},
}
## what lies by the wall of each kind of building (the first is the likeliest)
const BY_STYLE := {"inn": ["wine_gourd", "bun", "sandals"], "teahouse": ["teacup", "chess_piece", "pipe", "cricket_cage"], "shop": ["pear", "candied_haw", "fan", "comb"],
	"farmhouse": ["straw_hat", "washing_bat", "cloth_tiger", "pipe"], "smithy": ["horseshoe", "nails"], "house": ["cloth_tiger", "ball", "sandals", "top", "broom"],
	"huizhou": ["comb", "cricket_cage", "sandals", "top"], "dorm": ["practice_sword", "broom", "ball"], "shrine": ["offering_peach", "incense", "prayer_slip", "altar_coin"],
	"hall": ["broom", "incense"], "kitchen": ["bun", "broom"], "library": ["brush", "chess_piece"], "alchemist": ["pill_gourd", "teacup"],
	"seahouse": ["dried_fish", "straw_hat", "ball"], "aerie": ["fan", "cloth_tiger", "top"]}
const LOST := ["purse", "hairpin", "letter", "small_shoe", "name_seal", "cash_string", "pendant", "rattle", "key", "longevity_lock", "needle_case", "reading_stone"]
const WILD := ["feather", "pine_cone", "mushroom", "antler", "cicada_husk", "blossom", "pebble", "shell"]
## the houses somebody of a town may live in (a lost thing is carried to the door of one)
const HOMES := ["house", "farmhouse", "huizhou", "seahouse", "aerie", "dorm"]
## what is said of a thing eaten, or played with where it lies
const USES := {
	"eat": ["It is gone in three bites. He had not known he was hungry.", "He eats it standing, the way the sweepers do, and wipes his hand on his sleeve."],
	"play": ["He sets it going with one flick. It runs true a good while; some things the hand does not forget.", "Once, twice, and it comes back to his palm. He was a boy on this mountain too."],
}
## what a child says to a thing held out
const TREATS := ["For me? The whole {thing}? ...I am not sharing it. I might share it.", "A {thing}! I shall tell everybody an immortal gave it me, and nobody will believe it.",
	"Thank you! Granny says not to take things from strangers, but you are not strange, you are only tall.", "Is it magic? It is not magic. I like it anyway."]
## classes whose taking, seen, is answered for
const OWNED := ["ware", "keep", "altar"]

static var _cache := {}

## A number from a name, well mixed (the hash of a name that ends "...:3" is one more than of
## "...:2": things would lie in a row).
static func _h(s) -> int:
	var x: int = hash(str(s)) & 0xffffffff
	x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff
	x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff
	return (x ^ (x >> 16)) & 0x7fffffff

static func art(kind: String) -> String:
	var n := str(KINDS[kind].n)
	return ("an " if n[0] in ["a", "e", "i", "o", "u"] else "a ") + n

static func cls_of(kind: String) -> String:
	return str(KINDS[kind].cls)

# ---------------------------------------------------------------- where things lie
static func _free(wd: Dictionary, p: Vector2i, area: String, kinds: Array) -> bool:
	if p.x < 1 or p.y < 1 or p.x >= int(wd.w) - 1 or p.y >= int(wd.h) - 1:
		return false
	if not int(wd.grid[p.y * int(wd.w) + p.x]) in kinds:
		return false
	return Atlas.owner_id(wd, p) == area

## The tiles of region `area` something written with the land stands on or beside (nothing lies there).
static func _taken(wd: Dictionary, area: String) -> Dictionary:
	var key := "taken|%s|%s" % [str(wd.get("layer", "")), area]
	if _cache.has(key):
		return _cache[key]
	var taken := {}
	for e in wd.ents:
		if str(e.get("area", "")) != area:
			continue
		taken[e.pos] = true
	for p in Havoc.tiles(wd, area):
		taken[p] = true
	for bd in wd.buildings:
		if str(bd.area) == area:
			taken[bd.door] = true
	_cache[key] = taken
	return taken

## One of the people of town `tid` who would own a thing of `kind` (`salt`: which of them), the same
## one every time: a child for a toy, somebody old for a pipe, a seller for a ware.
static func owner_in(wd: Dictionary, tid: String, kind: String, salt: String) -> Dictionary:
	var ppl: Array = Folk.people(wd, tid)
	if ppl.is_empty():
		return {}
	var pool := _owners(ppl, kind)
	if pool.is_empty():
		pool = ppl
	return pool[_h(salt) % pool.size()]

static func _owners(ppl: Array, kind: String) -> Array:
	var want := str(KINDS[kind].get("own", "trade" if str(KINDS[kind].cls) == "ware" else ""))
	var pool: Array = []
	for p in ppl:
		var ok := true
		match want:
			"kid":
				ok = bool(p.kid)
			"old":
				ok = bool(p.old)
			"fem":
				ok = bool(p.fem) and not bool(p.kid)
			"trade":
				ok = str(p.role) in Manners.TRADE
			_:
				ok = not bool(p.kid)
		if ok:
			pool.append(p)
	return pool

## The door somebody of town `tid` lives behind (`salt`: which house), or (-1, -1) in a town with no
## houses (a camp of the road).
static func door_in(wd: Dictionary, tid: String, salt: String) -> Vector2i:
	var area := str(Folk.town(tid).area)
	var c := Folk.heart(tid)
	var pool: Array = []
	var any: Array = []
	for bd in wd.buildings:
		if str(bd.area) != area:
			continue
		var r: Rect2i = bd.rect
		if maxi(absi(r.get_center().x - c.x), absi(r.get_center().y - c.y)) > Folk.RADIUS + 4:
			continue
		any.append(bd.door)
		if str(bd.get("style", "house")) in HOMES:
			pool.append(bd.door)
	if pool.is_empty():
		pool = any
	if pool.is_empty():
		return Vector2i(-1, -1)
	return pool[_h(("door:" + salt)) % pool.size()]

## The wares, keeps and offerings of region `area`: [{id, kind, cls, tile, town, area, owner, who,
## bld}], one or two by the walls of every building of every town in it, on open ground nothing
## stands on.  Made once from the town's map.
static func stood(wd: Dictionary, area: String) -> Array:
	var key := "stood|%s|%s" % [str(wd.get("layer", "")), area]
	if _cache.has(key):
		return _cache[key]
	var out: Array = []
	if not wd.has("buildings") or not wd.has("owner") or wd.has("level"):
		_cache[key] = out
		return out
	var taken: Dictionary = _taken(wd, area).duplicate()
	for tid in Folk.towns_in(area):
		if Folk.is_camp(tid):
			continue
		var c := Folk.heart(tid)
		var bi := 0
		for bd in wd.buildings:
			if str(bd.area) != area:
				continue
			var r: Rect2i = bd.rect
			if maxi(absi(r.get_center().x - c.x), absi(r.get_center().y - c.y)) > Folk.RADIUS + 4:
				continue
			var kinds: Array = BY_STYLE.get(str(bd.get("style", "house")), ["sandals", "broom"])
			var ring: Array = []
			for x in range(r.position.x - 1, r.end.x + 1):
				ring.append(Vector2i(x, r.position.y - 1))
				ring.append(Vector2i(x, r.end.y))
			for y in range(r.position.y, r.end.y):
				ring.append(Vector2i(r.position.x - 1, y))
				ring.append(Vector2i(r.end.x, y))
			var start := _h(("trf:" + str(bd.id))) % maxi(1, ring.size())
			var made := 0
			for k in ring.size():
				if made >= 2:
					break
				var p: Vector2i = ring[(start + k * 3) % ring.size()]
				if taken.has(p) or not _free(wd, p, area, [MapGen.FLOOR, MapGen.DECOR, MapGen.PATH]):
					continue
				var kind: String = kinds[(_h(str(bd.id)) + made) % kinds.size()]
				var id := "trf:%s:%d" % [area, out.size()]
				var ow := owner_in(wd, tid, kind, id)
				out.append({"id": id, "kind": kind, "cls": str(KINDS[kind].cls), "tile": p, "town": tid, "area": area, "bld": str(bd.id),
					"owner": str(ow.get("id", "")), "who": str(ow.get("n", "somebody")), "door": bd.door})
				taken[p] = true
				made += 1
			bi += 1
	_cache[key] = out
	return out

## The road tiles of town `tid` a thing may be dropped on, in a fixed order.
static func _roads(wd: Dictionary, tid: String) -> Array:
	var key := "roads|%s|%s" % [str(wd.get("layer", "")), tid]
	if _cache.has(key):
		return _cache[key]
	var area := str(Folk.town(tid).area)
	var c := Folk.heart(tid)
	var taken: Dictionary = _taken(wd, area)
	var here := {}
	for t in stood(wd, area):
		here[t.tile] = true
	var out: Array = []
	for kinds in [[MapGen.PATH], [MapGen.FLOOR]]:
		for y in range(c.y - LOST_REACH, c.y + LOST_REACH + 1):
			for x in range(c.x - LOST_REACH, c.x + LOST_REACH + 1):
				var p := Vector2i(x, y)
				if taken.has(p) or here.has(p) or not _free(wd, p, area, kinds):
					continue
				# (never against something that stands: a late-comer of the story may be stood beside it)
				var clear := true
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if taken.has(p + d):
						clear = false
				if clear:
					out.append(p)
		if out.size() >= LOST_N * 4:
			break
	_cache[key] = out
	return out

## What was dropped in the roads of region `area` on day `day`: LOST_N things a town, each with an
## owner of the town and the door they live behind.
static func lost(wd: Dictionary, area: String, day: int) -> Array:
	var key := "lost|%s|%s|%d" % [str(wd.get("layer", "")), area, day]
	if _cache.has(key):
		return _cache[key]
	var out: Array = []
	if wd.has("buildings") and wd.has("owner") and not wd.has("level"):
		for tid in Folk.towns_in(area):
			if Folk.is_camp(tid):
				continue
			var roads := _roads(wd, tid)
			if roads.is_empty() or door_in(wd, tid, "x").x < 0:
				continue
			var used := {}
			for k in LOST_N:
				var id := "lost:%s:%d:%d" % [tid, day, k]
				var i := _h((id)) % roads.size()
				for tries in roads.size():
					if not used.has(i):
						break
					i = (i + 1) % roads.size()
				if used.has(i):
					continue
				used[i] = true
				# (a thing somebody of this town could have dropped: no rattle where there are no children)
				var kind: String = LOST[_h("k" + id) % LOST.size()]
				for tries2 in LOST.size():
					if not _owners(Folk.people(wd, tid), kind).is_empty():
						break
					kind = LOST[(LOST.find(kind) + 1) % LOST.size()]
				var ow := owner_in(wd, tid, kind, id)
				out.append({"id": id, "kind": kind, "cls": "lost", "tile": roads[i], "town": tid, "area": area, "bld": "",
					"owner": str(ow.get("id", "")), "who": str(ow.get("n", "somebody")), "door": door_in(wd, tid, str(ow.get("id", id)))})
	# (only today's and yesterday's are remembered: the days are many)
	for k2 in _cache.keys():
		if str(k2).begins_with("lost|") and int(str(k2).get_slice("|", 3)) < day - 1:
			_cache.erase(k2)
	_cache[key] = out
	return out

## The things nobody owns that lie in region `area`: WILD_N of them on open ground out of the towns.
static func wild(wd: Dictionary, area: String) -> Array:
	var key := "wild|%s|%s" % [str(wd.get("layer", "")), area]
	if _cache.has(key):
		return _cache[key]
	var out: Array = []
	if not wd.has("owner") or wd.has("level") or not wd.has("layout") or not wd.layout.has(area):
		_cache[key] = out
		return out
	var taken: Dictionary = _taken(wd, area)
	var rr: Rect2i = wd.layout[area].cell
	var used := {}
	for t0 in stood(wd, area):
		used[t0.tile] = true
	for k in WILD_N * 6:
		if out.size() >= WILD_N:
			break
		var h := _h("wild:%s:%d" % [area, k])
		var p := rr.position + Vector2i(h % maxi(1, rr.size.x), _h("wy:%s:%d" % [area, k]) % maxi(1, rr.size.y))
		if used.has(p) or taken.has(p) or not _free(wd, p, area, [MapGen.FLOOR]):
			continue
		var wet := false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
			var q: Vector2i = p + d
			if q.x >= 0 and q.y >= 0 and q.x < int(wd.w) and q.y < int(wd.h) and int(wd.grid[q.y * int(wd.w) + q.x]) == MapGen.WATER:
				wet = true
		var kind: String = WILD[(h / 31) % WILD.size()]
		if bool(KINDS[kind].get("water", false)) != wet:
			kind = ("pebble" if (h / 7) % 2 == 0 else "shell") if wet else WILD[(h / 31) % (WILD.size() - 2)]
		used[p] = true
		out.append({"id": "wild:%s:%d" % [area, k], "kind": kind, "cls": "wild", "tile": p, "town": "", "area": area, "bld": "", "owner": "", "who": "", "door": Vector2i(-1, -1)})
	_cache[key] = out
	return out

# ---------------------------------------------------------------- what is there now
## Whether thing `t` has been taken up and is not back (a ware is set out again and a wild thing
## falls again by the next dawn; a keep stays gone while it is in his sleeve).
static func gone(g, t: Dictionary) -> bool:
	if not g.trifles.has(t.id):
		return false
	if held(g, str(t.id)):
		return true
	match str(t.cls):
		"lost":
			return true
		_:
			if int(g.day) > int(g.trifles[t.id]):
				g.trifles.erase(t.id)
				return false
			return true

## Whether the thing with id `id` is in his sleeve.
static func held(g, id: String) -> bool:
	for q in g.pocket:
		# (what he bought or found is his: its place is filled again by the next dawn like any other)
		if str(q.id) == id and not bool(q.get("own", false)):
			return true
	return false

## Everything that lies in region `area` of realm `wd` today (taken or not).
static func of_area(g, wd: Dictionary, area: String) -> Array:
	var out: Array = []
	out.append_array(stood(wd, area))
	out.append_array(lost(wd, area, int(g.day)))
	out.append_array(wild(wd, area))
	return out

## The thing lying on tile `p` of realm `wd` now, or {}.
static func at_tile(g, wd: Dictionary, p: Vector2i) -> Dictionary:
	if not wd.has("owner") or wd.has("level"):
		return {}
	var area := Atlas.owner_id(wd, p)
	var key := "tiles|%s|%s|%d" % [str(wd.get("layer", "")), area, int(g.day)]
	if not _cache.has(key):
		for k2 in _cache.keys():
			if str(k2).begins_with("tiles|%s|%s|" % [str(wd.get("layer", "")), area]):
				_cache.erase(k2)
		var m := {}
		for t in of_area(g, wd, area):
			m[t.tile] = t
		_cache[key] = m
	var t: Dictionary = _cache[key].get(p, {})
	if t.is_empty() or gone(g, t):
		return {}
	return t

## The place a keep, a ware or an offering in his sleeve belongs on, if `p` is that place: the thing,
## or {}.
static func home_at(g, wd: Dictionary, p: Vector2i) -> Dictionary:
	for q in g.pocket:
		if str(q.cls) in OWNED and not bool(q.get("own", false)) and q.tile == p and str(q.layer) == str(wd.get("layer", "")):
			return q
	return {}

# ---------------------------------------------------------------- taking, buying, putting back
## What a ware costs him: its price, a stone more a great realm, and whatever the town thinks of him.
static func price(g, t: Dictionary) -> int:
	return maxi(1, int(round(float(int(KINDS[str(t.kind)].get("price", 1)) + int(g.realm())) * Weal.mod(g, str(t.area), "mend"))))

## Why thing `t` cannot be taken up now ("" if it can).
static func blocked(g, _t: Dictionary) -> String:
	if g.pocket.size() >= SLEEVE:
		return "His sleeves are full: six small things are all they hold."
	return ""

static func _pocket(g, wd: Dictionary, t: Dictionary, own: bool) -> void:
	var q: Dictionary = t.duplicate()
	q.own = own
	q.day = int(g.day)
	q.layer = str(wd.get("layer", ""))
	g.pocket.append(q)
	g.trifles[t.id] = int(g.day)
	g.picked += 1

## He takes up thing `t` (`how`: "take" a thing nobody sells, "buy" a ware, "pocket" what is
## somebody's).  `seen`: who saw it (manners.gd `watchers`).  Returns {ok, lines, react}: what is told,
## and who answers it and how ({who, line, clip} or {}).
static func take(g, wd: Dictionary, t: Dictionary, how: String, seen: Array) -> Dictionary:
	var why := blocked(g, t)
	if why != "":
		return {"ok": false, "lines": [why], "react": {}}
	var kind := str(t.kind)
	var cls := str(t.cls)
	var lines: Array = []
	var react := {}
	match how:
		"buy":
			var n := price(g, t)
			if int(g.stones) < n:
				return {"ok": false, "lines": ["%s is %d spirit stones, and he has not got them." % [art(kind).capitalize(), n]], "react": {}}
			g.stones -= n
			_pocket(g, wd, t, true)
			lines.append("Bought: %s, for %d spirit stones" % [art(kind), n])
			react = Manners.answer("buy", Manners.find(seen, str(t.owner)), g, {"thing": str(KINDS[kind].n), "who": str(t.who)}, int(g.picked))
		"pocket":
			_pocket(g, wd, t, false)
			g.pilfered += 1
			if seen.is_empty():
				lines.append("Nobody saw. %s is in his sleeve, and it is still %s's." % [art(kind).capitalize(), str(t.who)])
			else:
				var ow := Manners.find(seen, str(t.owner))
				var deed := "altar" if cls == "altar" else "pilfer"
				react = Manners.answer(deed, ow if not ow.is_empty() else seen[0], g, {"thing": str(KINDS[kind].n), "who": str(t.who), "mine": str(KINDS[kind].get("mine", "")) if not ow.is_empty() else ""}, int(g.picked))
		_:
			_pocket(g, wd, t, cls == "wild")
			if cls == "lost":
				lines.append("Picked up: %s. It is not his." % art(kind))
				if not seen.is_empty():
					react = Manners.answer("whose", seen[0], g, {"thing": str(KINDS[kind].n), "who": str(t.who), "town": str(Folk.town(str(t.town)).n).trim_prefix("the ")}, int(g.picked))
			else:
				lines.append("Picked up: %s" % art(kind))
				if not seen.is_empty():
					react = Manners.answer("wild", seen[0], g, {"thing": str(KINDS[kind].n)}, int(g.picked))
	return {"ok": true, "lines": lines, "react": react}

## What he walked off with, seen, is answered for: a small price at the gate of the town that hears of
## it, and its streets remember.
static func charge(g, t: Dictionary) -> void:
	var tid := Weal.town_of(str(t.area))
	Weal.act(g, tid, "pilfer")
	Crime.record(g, "theft", tid, "%s's %s" % [str(t.who), str(KINDS[str(t.kind)].n)])

## He pays for a ware already in his sleeve.
static func pay(g, id: String) -> Array:
	for q in g.pocket:
		if str(q.id) == id and not bool(q.own):
			var n := price(g, q)
			if int(g.stones) < n:
				return ["%d spirit stones, and he has not got them." % n]
			g.stones -= n
			q.own = true
			g.pilfered = maxi(0, int(g.pilfered) - 1)
			return ["Paid: %d spirit stones for %s" % [n, art(str(q.kind))]]
	return []

## He puts back what he took where it lay.
static func put_back(g, id: String) -> Array:
	for i in g.pocket.size():
		var q: Dictionary = g.pocket[i]
		if str(q.id) == id:
			g.pocket.remove_at(i)
			g.trifles.erase(id)
			if not bool(q.own) and str(q.cls) in OWNED:
				g.pilfered = maxi(0, int(g.pilfered) - 1)
			return ["Put back: %s" % art(str(q.kind))]
	return []

## He eats, or plays with, the thing in his sleeve with id `id` (or uses up what lies there: a thing
## eaten is gone).
static func use(g, id: String) -> Array:
	for i in g.pocket.size():
		var q: Dictionary = g.pocket[i]
		if str(q.id) == id:
			var u := str(KINDS[str(q.kind)].get("use", ""))
			if u == "":
				return []
			var ls: Array = USES[u]
			if u == "eat":
				g.pocket.remove_at(i)
				Needs.used(g, "", "herb")
			return [str(ls[int(g.picked) % ls.size()])]
	return []

## A blow lands on thing `t` where it lies: a frail one is broken (and paid for, if it was
## somebody's), anything else only flies.  Returns what is told.
static func struck(g, t: Dictionary) -> Array:
	if not bool(KINDS[str(t.kind)].get("frail", false)):
		return []
	g.trifles[t.id] = int(g.day)
	var n := price(g, t) if KINDS[str(t.kind)].has("price") else maxi(1, 3 + int(g.realm()))
	Weal.act(g, Weal.town_of(str(t.area)), "broke")
	if int(g.stones) >= n:
		g.stones -= n
		return ["%s's %s: you pay %d spirit stones for it" % [str(t.who), str(KINDS[str(t.kind)].n), n]]
	Weal.act(g, Weal.town_of(str(t.area)), "unpaid")
	return ["%s: \"My %s! And not a stone to pay for it, %s?\"" % [str(t.who), str(KINDS[str(t.kind)].n), str(g.address())]]

# ---------------------------------------------------------------- bringing things home
## The lost things in his sleeve (the oldest first).
static func carried(g) -> Array:
	var out: Array = []
	for q in g.pocket:
		if str(q.cls) == "lost":
			out.append(q)
	return out

## What of his sleeve belongs to person `pid` of the towns: the things, [] if none.
static func theirs(g, pid: String) -> Array:
	var out: Array = []
	for q in g.pocket:
		if str(q.owner) == pid and not bool(q.own) and str(q.cls) != "wild":
			out.append(q)
	return out

## What of his sleeve is carried to the door at (or beside) tile `p` of realm `wd`.
static func at_door(g, wd: Dictionary, p: Vector2i) -> Array:
	var out: Array = []
	for q in g.pocket:
		if str(q.cls) == "lost" and str(q.layer) == str(wd.get("layer", "")) and maxi(absi(int(q.door.x) - p.x), absi(int(q.door.y) - p.y)) <= 1:
			out.append(q)
	return out

## Thing `id` of his sleeve is given to whose it is (`door`: left at their door, with a knock).
## Returns {lines: what is said, as dialogue lines, stones}.
static func restore(g, id: String, door: bool = false) -> Dictionary:
	for i in g.pocket.size():
		var q: Dictionary = g.pocket[i]
		if str(q.id) != id:
			continue
		g.pocket.remove_at(i)
		var kind := str(q.kind)
		var lines: Array = []
		var stones := 0
		if str(q.cls) == "lost":
			g.restored += 1
			g.step_restore += 1
			stones = THANKS + THANKS_REALM * int(g.realm())
			g.stones += stones
			Weal.act(g, Weal.town_of(str(q.area)), "restored")
			if door:
				lines.append(["Narrator", "He knocks. %s comes to the door wiping both hands, sees the %s, and for a moment says nothing at all." % [str(q.who), str(KINDS[kind].n)]])
			lines.append([str(q.who), str(KINDS[kind].thanks), "bow"])
			lines.append(["Narrator", "%s presses %d spirit stones on him, and will not hear of his refusing. (%d things brought home)" % [str(q.who), stones, int(g.restored)]])
		else:
			# a keep, a ware or an offering he walked off with, handed back to whose it was
			g.trifles.erase(id)
			g.pilfered = maxi(0, int(g.pilfered) - 1)
			lines.append([str(q.who), "Hm. Well. It is back, and I shall say no more about it. I shall think it, mind.", "nod"])
		g.poll_steps()
		return {"lines": lines, "stones": stones}
	return {"lines": [], "stones": 0}

## A thing nobody would grudge a child, out of his sleeve (the first that is his to give), or {}.
static func treat(g) -> Dictionary:
	for q in g.pocket:
		if bool(q.own) and (str(q.cls) == "wild" or str(KINDS[str(q.kind)].get("use", "")) != "" or str(q.kind) in ["fan", "comb"]):
			return q
	return {}

## He gives thing `id` of his sleeve to a child.
static func give(g, id: String) -> void:
	for i in g.pocket.size():
		if str(g.pocket[i].id) == id:
			g.pocket.remove_at(i)
			g.treats += 1
			return

## The lost thing of region `area` the bot should go for next ("restore" steps): the nearest by the
## count of tiles from `from` that still lies there, or {}.
static func wanted(g, wd: Dictionary, area: String, from: Vector2i) -> Dictionary:
	var best := {}
	var bd := 1 << 30
	for t in lost(wd, area, int(g.day)):
		if gone(g, t):
			continue
		var d := absi(int(t.tile.x) - from.x) + absi(int(t.tile.y) - from.y)
		if d < bd:
			bd = d
			best = t
	return best

## What is in his sleeve, said in a line ("" if nothing).
static func text(g) -> String:
	if g.pocket.is_empty():
		return ""
	var parts: Array = []
	for q in g.pocket:
		if str(q.cls) == "lost" or (str(q.cls) in OWNED and not bool(q.own)):
			parts.append("%s's %s" % [str(q.who), str(KINDS[str(q.kind)].n)])
		else:
			parts.append(art(str(q.kind)))
	return ", ".join(parts)

# ---------------------------------------------------------------- the things themselves
## The 3D model of a small thing (procedural, a few dozen triangles, lying on the ground at its
## origin; never more than a hand high).
static func model(kind: String) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var col: Color = KINDS[kind].col
	var wood := MB.tag(Color("8a6038"), MB.WOOD)
	var cord := MB.tag(Color("c83a3a"), MB.CLOTH)
	match kind:
		"bun":
			b.sph(Vector3(0, 0.05, 0), Vector3(0.09, 0.065, 0.09), MB.tag(col, MB.CLOTH))
			b.cyl(Vector3(0, 0.005, 0), 0.12, 0.01, MB.tag(Color("b8a070"), MB.WOOD), Vector3.ZERO, 10)
		"pear":
			b.sph(Vector3(0, 0.06, 0), Vector3(0.065, 0.07, 0.065), MB.tag(col, MB.FOLIAGE))
			b.sph(Vector3(0, 0.12, 0), Vector3(0.04, 0.05, 0.04), MB.tag(col, MB.FOLIAGE))
			b.limb(Vector3(0, 0.15, 0), Vector3(0.01, 0.2, 0), 0.006, 0.004, wood, 4)
		"candied_haw":
			b.limb(Vector3(-0.2, 0.03, 0), Vector3(0.2, 0.03, 0), 0.006, 0.006, wood, 4)
			for i in 5:
				b.sph(Vector3(-0.12 + i * 0.055, 0.035, 0), Vector3(0.03, 0.03, 0.03), MB.tag(col, MB.STONE))
		"teacup":
			b.lathe(Vector3.ZERO, [Vector2(0.03, 0.0), Vector2(0.05, 0.03), Vector2(0.055, 0.07), Vector2(0.045, 0.07), Vector2(0.03, 0.02)], MB.tag(col, MB.STONE), 10)
		"wine_gourd", "pill_gourd":
			b.sph(Vector3(0, 0.07, 0), Vector3(0.075, 0.07, 0.075), MB.tag(col, MB.WOOD))
			b.sph(Vector3(0, 0.16, 0), Vector3(0.045, 0.045, 0.045), MB.tag(col, MB.WOOD))
			b.cyl(Vector3(0, 0.21, 0), 0.015, 0.03, wood, Vector3.ZERO, 6)
			b.torus(Vector3(0, 0.125, 0), 0.04, 0.008, cord)
		"fan":
			for i2 in 7:
				var a := -0.9 + i2 * 0.3
				b.box(Vector3(sin(a) * 0.09, 0.012, cos(a) * 0.09), Vector3(0.05, 0.006, 0.2), MB.tag(col if i2 % 2 == 0 else col.darkened(0.12), MB.CLOTH), Vector3(0, a, 0))
			b.sph(Vector3(0, 0.012, 0), Vector3(0.015, 0.012, 0.015), wood)
		"comb":
			b.box(Vector3(0, 0.01, 0), Vector3(0.14, 0.012, 0.03), MB.tag(col, MB.WOOD))
			for i3 in 7:
				b.box(Vector3(-0.06 + i3 * 0.02, 0.01, 0.035), Vector3(0.008, 0.01, 0.045), MB.tag(col, MB.WOOD))
		"horseshoe":
			b.torus(Vector3(0, 0.015, 0), 0.07, 0.014, MB.tag(col, MB.METAL))
			b.box(Vector3(0, 0.015, 0.075), Vector3(0.07, 0.04, 0.05), MB.tag(Color("6a5a48"), MB.STONE))
		"nails":
			b.box(Vector3(0, 0.02, 0), Vector3(0.1, 0.035, 0.07), MB.tag(col, MB.CLOTH), Vector3(0, 0.3, 0))
			b.limb(Vector3(0.04, 0.04, 0.0), Vector3(0.1, 0.012, 0.05), 0.005, 0.002, MB.tag(Color("4a4a52"), MB.METAL), 4)
		"brush":
			b.limb(Vector3(-0.12, 0.012, 0), Vector3(0.08, 0.012, 0), 0.008, 0.008, MB.tag(Color("b89858"), MB.WOOD), 5)
			b.limb(Vector3(0.08, 0.012, 0), Vector3(0.14, 0.012, 0), 0.011, 0.002, MB.tag(col, MB.CLOTH), 5)
		"dried_fish":
			b.sph(Vector3(0, 0.015, 0), Vector3(0.12, 0.012, 0.04), MB.tag(col, MB.STONE))
			b.box(Vector3(0.13, 0.015, 0), Vector3(0.05, 0.008, 0.07), MB.tag(col.darkened(0.2), MB.STONE), Vector3(0, 0.78, 0))
		"cloth_tiger":
			b.sph(Vector3(0, 0.06, 0), Vector3(0.1, 0.055, 0.06), MB.tag(col, MB.CLOTH))
			b.sph(Vector3(0.1, 0.085, 0), Vector3(0.055, 0.055, 0.055), MB.tag(col, MB.CLOTH))
			for s in [-1.0, 1.0]:
				b.sph(Vector3(0.11, 0.135, 0.03 * s), Vector3(0.018, 0.02, 0.012), MB.tag(Color("2a2a2a"), MB.CLOTH))
				b.sph(Vector3(0.05 * s, 0.015, 0.04), Vector3(0.02, 0.02, 0.02), MB.tag(col.darkened(0.15), MB.CLOTH))
				b.sph(Vector3(0.05 * s, 0.015, -0.04), Vector3(0.02, 0.02, 0.02), MB.tag(col.darkened(0.15), MB.CLOTH))
			b.limb(Vector3(-0.1, 0.07, 0), Vector3(-0.17, 0.13, 0), 0.012, 0.008, MB.tag(Color("2a2a2a"), MB.CLOTH), 4)
		"ball":
			b.sph(Vector3(0, 0.07, 0), Vector3(0.07, 0.07, 0.07), MB.tag(col, MB.CLOTH))
			b.torus(Vector3(0, 0.07, 0), 0.07, 0.006, MB.tag(Color("f0d060"), MB.CLOTH))
		"top":
			b.lathe(Vector3.ZERO, [Vector2(0.004, 0.0), Vector2(0.06, 0.07), Vector2(0.05, 0.1), Vector2(0.01, 0.11), Vector2(0.008, 0.15)], MB.tag(col, MB.WOOD), 10)
		"broom":
			b.limb(Vector3(-0.48, 0.03, 0), Vector3(0.28, 0.03, 0), 0.014, 0.014, wood, 5)
			b.box(Vector3(0.37, 0.03, 0), Vector3(0.22, 0.04, 0.2), MB.tag(col, MB.FOLIAGE))
		"sandals":
			for s2 in [-1.0, 1.0]:
				b.box(Vector3(0.0, 0.012, 0.06 * s2), Vector3(0.2, 0.02, 0.085), MB.tag(col, MB.FOLIAGE), Vector3(0, 0.15 * s2, 0))
				b.torus(Vector3(0.04, 0.03, 0.06 * s2), 0.035, 0.006, MB.tag(col.darkened(0.2), MB.CLOTH))
		"washing_bat":
			b.box(Vector3(0.08, 0.02, 0), Vector3(0.3, 0.035, 0.09), MB.tag(col, MB.WOOD))
			b.limb(Vector3(-0.07, 0.02, 0), Vector3(-0.24, 0.02, 0), 0.016, 0.016, MB.tag(col, MB.WOOD), 5)
		"pipe":
			b.limb(Vector3(-0.22, 0.015, 0), Vector3(0.18, 0.015, 0), 0.007, 0.007, MB.tag(col, MB.WOOD), 5)
			b.cyl(Vector3(0.2, 0.025, 0), 0.02, 0.035, MB.tag(Color("b89040"), MB.METAL), Vector3.ZERO, 8)
		"straw_hat":
			b.lathe(Vector3.ZERO, [Vector2(0.24, 0.0), Vector2(0.22, 0.02), Vector2(0.1, 0.06), Vector2(0.02, 0.14)], MB.tag(col, MB.FOLIAGE), 12)
		"cricket_cage":
			b.lathe(Vector3.ZERO, [Vector2(0.06, 0.0), Vector2(0.075, 0.04), Vector2(0.06, 0.1), Vector2(0.015, 0.13)], MB.tag(col, MB.WOOD), 8)
			b.torus(Vector3(0, 0.15, 0), 0.02, 0.004, cord)
		"chess_piece":
			b.cyl(Vector3(0, 0.012, 0), 0.04, 0.024, MB.tag(col, MB.WOOD), Vector3.ZERO, 10)
			b.cyl(Vector3(0, 0.026, 0), 0.026, 0.003, cord, Vector3.ZERO, 8)
		"practice_sword":
			b.box(Vector3(0.1, 0.015, 0), Vector3(0.62, 0.02, 0.05), MB.tag(col, MB.WOOD))
			b.box(Vector3(-0.22, 0.015, 0), Vector3(0.03, 0.03, 0.14), wood)
			b.limb(Vector3(-0.23, 0.015, 0), Vector3(-0.4, 0.015, 0), 0.016, 0.016, wood, 5)
		"offering_peach":
			b.sph(Vector3(0, 0.07, 0), Vector3(0.075, 0.07, 0.075), MB.tag(col, MB.FOLIAGE))
			b.sph(Vector3(0, 0.13, 0), Vector3(0.02, 0.025, 0.02), MB.tag(col.darkened(0.15), MB.FOLIAGE))
			b.cyl(Vector3(0, 0.005, 0), 0.11, 0.01, MB.tag(Color("a83a2a"), MB.WOOD), Vector3.ZERO, 10)
		"incense":
			for i4 in 5:
				b.limb(Vector3(-0.14, 0.012 + 0.004 * i4, -0.016 + 0.008 * i4), Vector3(0.14, 0.012 + 0.004 * i4, -0.02 + 0.01 * i4), 0.004, 0.004, MB.tag(col, MB.WOOD), 4)
			b.torus(Vector3(0, 0.02, 0), 0.02, 0.005, MB.tag(Color("e8d8a0"), MB.CLOTH), Vector3(0, 0, PI * 0.5))
		"prayer_slip":
			b.box(Vector3(0, 0.008, 0), Vector3(0.06, 0.008, 0.22), MB.tag(col, MB.CLOTH), Vector3(0, 0.4, 0))
			b.box(Vector3(0, 0.014, 0), Vector3(0.012, 0.004, 0.14), MB.tag(Color("a83a2a"), MB.CLOTH), Vector3(0, 0.4, 0))
		"altar_coin", "cash_string":
			var nn := 1 if kind == "altar_coin" else 7
			for i5 in nn:
				b.cyl(Vector3(-0.06 + 0.02 * i5 if nn > 1 else 0.0, 0.035 if nn > 1 else 0.004, 0), 0.035, 0.006, MB.tag(col, MB.METAL), Vector3(0, 0, PI * 0.5) if nn > 1 else Vector3.ZERO, 10)
			if nn > 1:
				b.limb(Vector3(-0.1, 0.035, 0), Vector3(0.1, 0.035, 0), 0.005, 0.005, cord, 4)
			else:
				b.cyl(Vector3(0, 0.002, 0), 0.08, 0.004, MB.tag(Color("d8d0c0"), MB.STONE), Vector3.ZERO, 10)
		"purse":
			b.sph(Vector3(0, 0.045, 0), Vector3(0.07, 0.045, 0.06), MB.tag(col, MB.CLOTH))
			b.sph(Vector3(0, 0.095, 0), Vector3(0.03, 0.02, 0.03), MB.tag(col.lightened(0.15), MB.CLOTH))
			b.torus(Vector3(0, 0.08, 0), 0.028, 0.006, MB.tag(Color("e0c060"), MB.CLOTH))
		"hairpin":
			b.limb(Vector3(-0.1, 0.008, 0), Vector3(0.08, 0.008, 0), 0.004, 0.002, MB.tag(col, MB.METAL), 4)
			b.sph(Vector3(-0.11, 0.012, 0), Vector3(0.02, 0.012, 0.02), MB.tag(Color("8ad0c0"), MB.STONE))
		"letter":
			b.box(Vector3(0, 0.006, 0), Vector3(0.11, 0.008, 0.2), MB.tag(col, MB.CLOTH), Vector3(0, 0.5, 0))
			b.cyl(Vector3(0, 0.012, 0), 0.016, 0.004, MB.tag(Color("a82a2a"), MB.STONE), Vector3.ZERO, 8)
		"small_shoe":
			b.sph(Vector3(0, 0.025, 0), Vector3(0.065, 0.025, 0.035), MB.tag(col, MB.CLOTH))
			b.sph(Vector3(0.045, 0.04, 0), Vector3(0.025, 0.02, 0.028), MB.tag(Color("f0d060"), MB.CLOTH))
		"name_seal":
			b.box(Vector3(0, 0.035, 0), Vector3(0.035, 0.07, 0.035), MB.tag(Color("d8d0b8"), MB.STONE))
			b.box(Vector3(0, 0.004, 0), Vector3(0.037, 0.008, 0.037), MB.tag(col, MB.STONE))
		"pendant":
			b.torus(Vector3(0, 0.008, 0), 0.035, 0.012, MB.tag(col, MB.STONE), Vector3(PI * 0.5, 0, 0))
			b.limb(Vector3(0.035, 0.008, 0), Vector3(0.16, 0.008, 0.04), 0.004, 0.004, cord, 4)
		"rattle":
			b.cyl(Vector3(0, 0.03, 0), 0.05, 0.03, MB.tag(col, MB.WOOD), Vector3(PI * 0.5, 0, 0), 10)
			b.limb(Vector3(0, 0.03, 0), Vector3(-0.2, 0.012, 0), 0.007, 0.007, wood, 4)
			for s3 in [-1.0, 1.0]:
				b.sph(Vector3(0.02, 0.012, 0.07 * s3), Vector3(0.012, 0.012, 0.012), MB.tag(Color("e8d8a0"), MB.WOOD))
		"key":
			b.limb(Vector3(-0.05, 0.006, 0), Vector3(0.08, 0.006, 0), 0.005, 0.005, MB.tag(col, MB.METAL), 4)
			b.torus(Vector3(-0.075, 0.006, 0), 0.025, 0.005, MB.tag(col, MB.METAL), Vector3(PI * 0.5, 0, 0))
			b.box(Vector3(0.07, 0.006, 0.015), Vector3(0.02, 0.008, 0.03), MB.tag(col, MB.METAL))
		"longevity_lock":
			b.box(Vector3(0, 0.008, 0), Vector3(0.07, 0.012, 0.05), MB.tag(col, MB.METAL))
			b.torus(Vector3(0, 0.008, -0.04), 0.03, 0.004, MB.tag(col, MB.METAL), Vector3(PI * 0.5, 0, 0))
		"needle_case":
			b.cyl(Vector3(0, 0.014, 0), 0.014, 0.12, MB.tag(col, MB.WOOD), Vector3(0, 0, PI * 0.5), 8)
			b.torus(Vector3(0.03, 0.014, 0), 0.015, 0.004, MB.tag(Color("e0c060"), MB.METAL), Vector3(0, 0, PI * 0.5))
		"reading_stone":
			b.sph(Vector3(0, 0.02, 0), Vector3(0.05, 0.022, 0.05), MB.tag(col, MB.STONE))
			b.torus(Vector3(0, 0.012, 0), 0.05, 0.006, MB.tag(Color("b89040"), MB.METAL), Vector3(PI * 0.5, 0, 0))
		"feather":
			b.limb(Vector3(-0.14, 0.008, 0), Vector3(0.14, 0.02, 0.02), 0.003, 0.002, MB.tag(Color("e8e0d0"), MB.WOOD), 4)
			b.sph(Vector3(0.03, 0.016, 0.004), Vector3(0.1, 0.004, 0.028), MB.tag(col, MB.FOLIAGE))
			b.sph(Vector3(0.1, 0.02, 0.014), Vector3(0.035, 0.004, 0.02), MB.tag(Color("2a2a2a"), MB.FOLIAGE))
		"pine_cone":
			b.lathe(Vector3.ZERO, [Vector2(0.02, 0.0), Vector2(0.045, 0.03), Vector2(0.04, 0.07), Vector2(0.015, 0.11), Vector2(0.002, 0.12)], MB.tag(col, MB.WOOD), 7)
		"pebble":
			b.sph(Vector3(0, 0.02, 0), Vector3(0.055, 0.022, 0.04), MB.tag(col, MB.STONE))
		"shell":
			b.lathe(Vector3.ZERO, [Vector2(0.06, 0.0), Vector2(0.05, 0.02), Vector2(0.02, 0.035), Vector2(0.002, 0.04)], MB.tag(col, MB.STONE), 8)
		"mushroom":
			for i6 in 3:
				b.sph(Vector3(-0.04 + i6 * 0.04, 0.02 + 0.01 * (i6 % 2), 0.02 * (i6 % 2)), Vector3(0.045, 0.012, 0.035), MB.tag(col if i6 != 1 else col.lightened(0.1), MB.FOLIAGE))
		"antler":
			b.limb(Vector3(-0.18, 0.02, 0), Vector3(0.1, 0.05, 0.03), 0.014, 0.01, MB.tag(col, MB.STONE), 5)
			b.limb(Vector3(0.1, 0.05, 0.03), Vector3(0.24, 0.12, 0.0), 0.01, 0.004, MB.tag(col, MB.STONE), 4)
			b.limb(Vector3(0.0, 0.04, 0.02), Vector3(0.06, 0.13, 0.08), 0.009, 0.003, MB.tag(col, MB.STONE), 4)
			b.limb(Vector3(-0.1, 0.03, 0.0), Vector3(-0.08, 0.11, -0.06), 0.009, 0.003, MB.tag(col, MB.STONE), 4)
		"cicada_husk":
			b.sph(Vector3(0, 0.02, 0), Vector3(0.035, 0.02, 0.02), MB.tag(col, MB.WOOD))
			b.sph(Vector3(0.035, 0.022, 0), Vector3(0.018, 0.016, 0.018), MB.tag(col.lightened(0.1), MB.WOOD))
		"blossom":
			b.limb(Vector3(-0.16, 0.01, 0), Vector3(0.12, 0.03, 0.03), 0.006, 0.003, wood, 4)
			for i7 in 5:
				b.sph(Vector3(-0.1 + i7 * 0.055, 0.035, 0.02 * sin(i7 * 2.1)), Vector3(0.028, 0.012, 0.028), MB.tag(col if i7 % 2 == 0 else Color.WHITE, MB.FOLIAGE))
		_:
			b.sph(Vector3(0, 0.03, 0), Vector3(0.05, 0.03, 0.05), MB.tag(col, MB.STONE))
	MB.mesh_node(root, b.build(MB.mat_vc()))
	return root

## What is drawn under and over a small thing so that it can be seen in long grass: a patch of trodden
## earth, and a glint the colour of its class (gold for what was lost, pale for anything else).
static func patch(cls: String) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	b.cyl(Vector3(0, 0.006, 0), 0.3, 0.012, MB.tag(Color("8a7a5a"), MB.STONE), Vector3.ZERO, 12)
	MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var g := MB.new()
	g.ball(Vector3.ZERO, 0.07, Color(1.0, 0.85, 0.4, 0.55) if cls == "lost" else Color(1.0, 1.0, 0.9, 0.35), true)
	var gn := MB.mesh_node(root, g.build(MB.mat_glow()))
	gn.name = "glint"
	gn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

## What a thing is, said in a line under "Leave it".
static func about(t: Dictionary) -> String:
	var kind := str(t.kind)
	match str(t.cls):
		"ware":
			return "%s, set out for sale by %s." % [art(kind).capitalize(), str(t.who)]
		"keep":
			return "%s. It is %s's, and has been left where it is used." % [art(kind).capitalize(), str(t.who)]
		"altar":
			return "%s. It was laid here for somebody who is not present." % art(kind).capitalize()
		"lost":
			return "%s, lying in the road. Somebody dropped it this morning, and will be looking." % art(kind).capitalize()
	return "%s. It is nobody's." % art(kind).capitalize()
