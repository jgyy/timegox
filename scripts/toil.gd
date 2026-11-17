class_name Toil
extends RefCounted
## The Heavy Road release: the work of the hands.  Facing the land, **C**: Lin Feng does what that
## piece of it can be worked at, with the tool for it in his hands and on a clip of its own
## (art/lib/person.py INTERACT), and what comes of it goes on his back (load.gd):
##
##   fell     a tree at the forest's edge, with an axe: three blows, the trunk goes over the way a
##            trunk goes (impact.gd), and a stem of timber is shouldered
##   angle    any water he stands beside, with a rod: the cast, the wait, the strike, and two times in
##            three a carp on the line
##   quarry   the rock of a crag (a step that would be climbed) with a pick, for a block of dressed
##            stone; or the wall of a cave, for a lump of ore
##   reap     open ground out in the country, with a sickle: a bundle of herbs
##
## A tile gives once a day (`Game.toiled`: the land of a cultivation world mends by the next dawn, as a
## felled tree does), so a load is walked for along the forest's edge and not stood for.  What a place
## can be worked at is read from the tiles and the height field alone (`work_at`), so the bot and the
## tests work the same land without drawing it.  Nothing here is random: whether a cast catches is
## counted from `Game.toil_n`.
##
## The story asks for it twice over: a step of kind `"toil"` (`work`, `n`: do it so many times) and one
## of kind `"haul"` (`good`, `n`, `npc`: bring so many of a good to somebody, on whatever he has to
## carry it with).  Both are counted from when the step began (`Game.step_toil`, `Game.step_haul`).

## work -> what it is called, the tool (an item of load.gd WARES) and what is held for it (Props.held),
## the clip and how long it takes, the good it gives, how the land answers, what Yue Ling does
## meanwhile, and what is said of it
const WORKS := {
	"fell": {"n": "Fell a tree", "tool": "axe", "hold": "felling_axe", "clip": "fell", "dur": 4.5, "good": "timber", "fx": "chips", "comp": "watch",
		"none": "The forest's edge: with an axe a tree could be felled here.",
		"lines": ["Three blows, a creak, and the trunk goes over where he meant it to. He trims it and gets it on his shoulder.",
			"The axe bites, sticks, and comes free. The second cut is cleaner. Timber is mostly learning where not to stand.",
			"It comes down with a sound like a door closing somewhere very large. The birds are back in a minute."]},
	"angle": {"n": "Cast a line", "tool": "fishing_rod", "hold": "rod", "clip": "angle", "dur": 6.4, "good": "carp", "fx": "ripple", "comp": "sit_bench",
		"none": "Water: with a rod there would be fish in it.",
		"lines": ["The float goes under and he strikes: a carp as long as his forearm, cross about it.",
			"A good fish, bright as a new coin. He knocks it on the head quickly, as Auntie Zhou taught him.",
			"The line goes tight and stays tight. It is a long minute before it is his fish and not the river's."],
		"miss": ["The float nods twice and is still. Whatever it was has gone to tell the others.",
			"Nothing. The water keeps its own counsel, and its fish."]},
	"quarry": {"n": "Cut stone", "tool": "pick", "hold": "pickaxe", "clip": "quarry", "dur": 4.8, "good": "stone_block", "fx": "sparks", "comp": "watch",
		"none": "Rock: with a pick a block could be cut from it.",
		"lines": ["He finds the bed of the stone and works along it, and a block comes away almost square.",
			"Sparks, grit in the teeth, and at last the dull note that means it has let go.",
			"Forty-five jin of mountain. He gets his knees under it, and it comes up."],
		# (the Answering Land release: at the wall of a cave it is ore that comes away, and it is told so)
		"cave_lines": ["He follows the dull red of the seam with the point, and a lump works loose and drops at his feet.",
			"Sparks in the dark, grit in the teeth, and a piece of the wall heavier than it has any right to be.",
			"Twenty jin of something a smith will know the name of. It is cold, and it smells of rain."]},
	"reap": {"n": "Cut herbs", "tool": "sickle", "hold": "sickle", "clip": "reap", "dur": 3.2, "good": "herb_bundle", "fx": "reaped", "comp": "gather",
		"none": "Open ground: with a sickle there are herbs to be cut here.",
		"lines": ["A sweep of the sickle and a handful of what grows low: plantain, mugwort, a sprig of something bitter.",
			"He ties the bundle with a stem of its own grass, the way the herbalists of the road do.",
			"He names each as it is cut, as the herbalists do, and sets two aside: those are not for eating."]},
	# ---- the Small Fish release: three more things the hands can take from the land.  Each is the *other*
	# thing a piece of it offers (`offers`): C does the first he has the tool for, Shift+C the other.
	"pick": {"n": "Pick mushrooms", "tool": "trug", "hold": "trug", "clip": "gather", "dur": 3.4, "good": "mushrooms", "fx": "reaped", "comp": "gather",
		"none": "The forest's edge: with a basket there are mushrooms to be picked under these trees.",
		"lines": ["Wood-ears off a fallen branch, and two brown caps from the leaf-mould under it. He leaves the red one where it is.",
			"He picks as Auntie Zhou taught him: cut, do not pull, and leave the small ones for whoever comes after.",
			"A double handful, cool and damp, smelling of the inside of the wood. He turns each over. None is the kind with a ring."]},
	"dig": {"n": "Dig for yams", "tool": "spade", "hold": "spade", "clip": "dig", "dur": 4.4, "good": "wild_yam", "fx": "clods", "comp": "watch",
		"none": "Open ground: the vine on it means a yam under it, for somebody with a spade.",
		"lines": ["He follows the vine down two spans, working round it, and the yam comes up whole and as long as his arm.",
			"A wild yam goes straight down and breaks if it is hurried. He does not hurry it.",
			"Earth to the elbows, and a root the colour of the earth it came from. He fills the hole in again; the farmers do."]},
	"mine": {"n": "Work a vein", "tool": "pick", "hold": "pickaxe", "clip": "mine", "dur": 5.2, "good": "jade_rough", "fx": "sparks", "comp": "watch",
		"none": "A vein shows green in the wall here: with a pick it could be worked.",
		"lines": ["He does not strike the vein. He takes away what is round it, a chip at a time, until it can be lifted out.",
			"The rock rings dull and the vein rings like a cup. He works by ear, and the piece that comes away has a skin on it like a river stone.",
			"Eight jin of something in a rind. Whether it is jade is for somebody with a wheel and a week to say."]},
}
const ORDER := ["fell", "angle", "quarry", "reap", "pick", "dig", "mine"]
## the other thing a piece of the land offers beside its first (the Small Fish release)
const ALSO := {"fell": "pick", "reap": "dig"}

## Whether the wall of a cave shows a vein at `tile` (about one piece of wall in four that floor lies
## beside: read from where it is, so the same every time, and nothing is placed for it).
static func vein(wd: Dictionary, tile: Vector2i) -> bool:
	if wd.is_empty() or not bool(wd.get("cave", false)):
		return false
	var w := int(wd.w)
	var h := int(wd.h)
	if tile.x < 0 or tile.y < 0 or tile.x >= w or tile.y >= h or not wd.grid[tile.y * w + tile.x] in [MapGen.WALL, MapGen.BUILDING]:
		return false
	var n := (tile.x * 73856093) ^ (tile.y * 19349663) ^ (str(wd.get("area", "")).hash() & 0xffff)
	return posmod(n, 4) == 0

## Everything the land offers on `tile` faced from `from`, its first work first (`work_at`), then the
## other: mushrooms under the trees that could be felled, a yam under the ground that could be reaped,
## a vein in the cave wall that could be quarried.
static func offers(wd: Dictionary, from: Vector2i, tile: Vector2i, cave: bool = false, indoors: bool = false) -> Array:
	var first := work_at(wd, from, tile, cave, indoors)
	if first == "":
		return []
	var out: Array = [first]
	if ALSO.has(first):
		out.append(str(ALSO[first]))
	if cave and first == "quarry" and vein(wd, tile):
		out.insert(0, "mine")
	return out

## Which of what a tile `offers` he does: the one the story is asking for if it is there, else the first
## he has the tool for (`second`: the other one), else the first, so that he is told what he lacks.
static func choose(g, offered: Array, second: bool = false) -> String:
	if offered.is_empty():
		return ""
	var s: Dictionary = g.cur_step()
	if not s.is_empty() and str(s.kind) == "toil" and offered.has(str(s.work)) and not second:
		return str(s.work)
	var have: Array = []
	for id in offered:
		if int(g.inv.get(str(WORKS[id].tool), 0)) > 0:
			have.append(id)
	if have.is_empty():
		return str(offered[0])
	return str(have[mini(1 if second else 0, have.size() - 1)])
## what the wall of a cave gives instead of dressed stone
const CAVE_GOOD := "ore_lump"

## The work the land offers on `tile` of world `wd`, faced from `from` ("" for none).  `cave`: is this
## a cave's floor?  `indoors`: any other floor of a building (nothing to work at).
static func work_at(wd: Dictionary, from: Vector2i, tile: Vector2i, cave: bool = false, indoors: bool = false) -> String:
	if indoors or wd.is_empty() or not wd.has("grid"):
		return ""
	var w := int(wd.w)
	var h := int(wd.h)
	if tile.x < 0 or tile.y < 0 or tile.x >= w or tile.y >= h:
		return ""
	var c: int = wd.grid[tile.y * w + tile.x]
	if cave:
		# (the Small Fish release: the rock of a cave is laid as BUILDING, the way the walls of any floor are, and
		# this asked for WALL: no cave wall had ever given its ore)
		return "quarry" if (c == MapGen.WALL or c == MapGen.BUILDING) else ""
	if c == MapGen.WATER:
		return "angle"
	if c == MapGen.WALL:
		return "fell"
	if c == MapGen.FLOOR or c == MapGen.DECOR:
		# a crag (peaks.gd): the rock of a step that would be climbed
		if Peaks.climb(wd, from, tile) > 0:
			return "quarry"
		# open country, away from the towns and the paths
		if c == MapGen.FLOOR and Music.town_at(Atlas.owner_id(wd, tile), tile) == "" and Atlas.owner_id(wd, tile) != Atlas.HUB:
			return "reap"
	return ""

## The key a worked tile is remembered by until the next dawn.
static func key(layer: String, tile: Vector2i) -> String:
	return "%s|%d|%d" % [layer, tile.x, tile.y]

static func spent(g, layer: String, tile: Vector2i) -> bool:
	return int(g.toiled.get(key(layer, tile), -1)) == int(g.day)

## Why work `id` cannot be done on this tile now ("" if it can).
static func blocked(g, id: String, layer: String, tile: Vector2i) -> String:
	if not WORKS.has(id):
		return "There is nothing here to work at."
	var wk: Dictionary = WORKS[id]
	if int(g.inv.get(str(wk.tool), 0)) <= 0:
		return "%s (%s: the pedlars of the road sell one, and Smith Tie)" % [str(wk.none), str(Data.ITEMS[str(wk.tool)].n).to_lower()]
	if spent(g, layer, tile):
		return "This piece of the land has given what it had today. Further along."
	return Load.refuses(g, str(wk.good))

## The good work `id` gives on a floor of that kind.
static func good_of(id: String, cave: bool) -> String:
	return CAVE_GOOD if cave and id == "quarry" else str(WORKS[id].good)

## Work `id` is done on `tile`: what came of it (lines to tell).  The tile is spent for the day, the
## good is on his back, and a step that asked for the work or the good hears of it.
static func done(g, id: String, layer: String, tile: Vector2i, cave: bool = false) -> Array:
	var wk: Dictionary = WORKS[id]
	g.toiled[key(layer, tile)] = int(g.day)
	g.toil_n += 1
	var n: int = int(g.toil.get(id, 0))
	g.toil[id] = n + 1
	var out: Array = []
	var got := true
	# (the Answering Land release: every third cast, counted in casts: counted in all the work of the hands, a
	# reaping between casts used to make sure no cast ever missed)
	if id == "angle" and (n + 1) % 3 == 0:
		# (two casts in three catch: counted, never thrown for)
		got = false
		out.append(str(wk.miss[n % (wk.miss as Array).size()]))
	else:
		var told: Array = wk.cave_lines if (cave and wk.has("cave_lines")) else wk.lines
		# (the Ordered House release: of the casts that catch, counted by themselves: every third cast misses, and
		# the third thing there is to say of a catch was never said)
		var li := (n - n / 3) if id == "angle" else n
		out.append(str(told[li % told.size()]))
	if got:
		var good := good_of(id, cave)
		g.add_item(good)
		out.append("%s: %d jin (%s)" % [str(Data.ITEMS[good].n), int(round(Load.weight_of(good))), Load.text(g).split(":")[0]])
		if Needs.on(g) and good in ["carp", "herb_bundle", "mushrooms", "wild_yam"]:
			Needs.give(g, {"hunger": 6.0})
	var s: Dictionary = g.cur_step()
	if not s.is_empty() and str(s.kind) == "toil" and str(s.work) == id:
		g.step_toil += 1
		g.poll_steps()
	return out

# ---------------------------------------------------------------- hauling for the story
## How many of the good a "haul" step asks for he has on him now.
static func on_hand(g, s: Dictionary) -> int:
	return Load.carried(g, str(s.good))

## He stands in front of whoever a "haul" step is for with some of it on his back: it is set down.
## Returns how many were handed over (0 if he had none).
static func hand_over(g, s: Dictionary) -> int:
	var have := on_hand(g, s)
	var want := int(s.n) - int(g.step_haul)
	var n := mini(have, want)
	if n <= 0:
		return 0
	g.inv[str(s.good)] = int(g.inv[str(s.good)]) - n
	g.step_haul += n
	return n

## How many more of its good a "haul" step still wants brought.
static func wanted(g, s: Dictionary) -> int:
	return maxi(0, int(s.n) - int(g.step_haul))
