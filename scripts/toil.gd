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
			"Yue Ling names each as it is cut, and sets two aside: those are not for eating."]},
}
const ORDER := ["fell", "angle", "quarry", "reap"]
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
		return "quarry" if c == MapGen.WALL else ""
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
		out.append(str(told[n % told.size()]))
	if got:
		var good := good_of(id, cave)
		g.add_item(good)
		out.append("%s: %d jin (%s)" % [str(Data.ITEMS[good].n), int(round(Load.weight_of(good))), Load.text(g).split(":")[0]])
		if Needs.on(g) and good in ["carp", "herb_bundle"]:
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
