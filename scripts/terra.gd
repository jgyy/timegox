class_name Terra
extends RefCounted
## The Dao of Leading Water (the Sea Floor release): the ground rises and falls under his hand.  "Gun built
## walls.  His son went and asked the water where it wished to go."  It is taught by the Turtle of the
## Eastern Sea at Lampdeep (the step LEARN); until then the ground does not answer.
##
## **Y**, facing open ground: what is asked of it ("Leave it as it is" first): raised, lowered, lowered and
## filled (a pool), or let go back to how it lay.  Each asking moves that piece of ground STEP metres, takes
## half an hour, and is kept (`Game.shaped`: realm -> tile -> {h, w}); it does not mend.  **It is a term in
## the height field and nothing else** (`rise`, added in Terrain3D.world_heights like the mountains of
## peaks.gd): no tile changes its kind, a pool is drawn and waded through, and what asks where he may walk,
## climb or fly (the grid, Peaks.at) is asked what it always was.  So no map moves, nothing is shut in or let
## out by it, and shaping the land can never be a way round the story.
##
## What may be shaped is read from the grid and what stands (`why`, pure): open ground, with open ground all
## round it, two tiles from anybody and anything, off the mountains, the roads and the camps, and never the
## courtyard of the sect.  A piece of ground takes no more than MAX metres either way ("the ground has had
## enough").  With no window nothing is drawn; the state is the same.
##
## New step kind "terra" (`n` askings the ground answered since the step began; `area`: in that country;
## `shape`: of that kind).  The bot shapes only inside such a step (`Terra.spot`).

const LEARN := "s_p42_learn"
const STEP := 0.6
const MAX := 2.4
## how far from the middle of a shaped tile the ground is moved (tiles), and how much several pieces of
## ground beside one another can add up to (metres)
const REACH := 2.5
const TOTAL := 3.6
const HOURS := 0.5
const ASK := "The Dao of Leading Water: what is asked of the ground?"
const SHAPES := {
	"raise": {"n": "Raise it", "dh": 1.0, "verb": "rises", "desc": "The ground under his palm comes up a hand and a half, as a breath comes in, and stays. Silt and water run off it."},
	"lower": {"n": "Lower it", "dh": -1.0, "verb": "sinks", "desc": "The ground under his palm goes down a hand and a half, as a breath goes out, and stays. What was lying on it goes where it was going."},
	"pool": {"n": "Lower it, and let it fill", "dh": -1.0, "water": true, "verb": "sinks and fills", "desc": "The ground goes down, and water comes into the hollow from wherever water comes: a pool, a hand and a half deep, to be waded through."},
	"level": {"n": "Let it lie as it lay", "dh": 0.0, "verb": "goes back to how it lay", "desc": "What was asked of this piece of ground is taken back. It returns to how the land made it."},
}
const ORDER := ["raise", "lower", "pool", "level"]

static var _near := {}

static func known(g) -> bool:
	return g.done(LEARN)

## What has been asked of tile `tile` of realm `layer` so far: metres up (or down).
static func height(g, layer: String, tile: Vector2i) -> float:
	return float((g.shaped.get(layer, {}) as Dictionary).get(tile, {}).get("h", 0.0))

static func pooled(g, layer: String, tile: Vector2i) -> bool:
	var d: Dictionary = (g.shaped.get(layer, {}) as Dictionary).get(tile, {})
	return bool(d.get("w", false)) and float(d.get("h", 0.0)) < 0.0

## How many pieces of ground stand shaped (in realm `layer`, or anywhere).
static func count(g, layer: String = "") -> int:
	var n := 0
	for l in g.shaped:
		if layer == "" or str(l) == layer:
			n += (g.shaped[l] as Dictionary).size()
	return n

## The tiles of realm `wd` that stand too near somebody or something to be shaped (made once a realm).
static func _stood(wd: Dictionary, layer: String) -> Dictionary:
	if _near.has(layer):
		return _near[layer]
	var out := {}
	for e in wd.ents:
		if not e.has("pos") or str(e.kind) == "seal":
			continue
		var p: Vector2i = e.pos
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				out[p + Vector2i(dx, dy)] = true
	for a in wd.get("camps", {}):
		var c: Vector2i = wd.camps[a]
		for dy2 in range(-6, 7):
			for dx2 in range(-6, 7):
				out[c + Vector2i(dx2, dy2)] = true
	_near[layer] = out
	return out

## Why tile `tile` of realm `wd` (`layer`) cannot be given shape `shape` now ("" if it can).  Pure: the
## grid, what stands, the mountains, the roads, and what has been asked of it already.
static func why(g, wd: Dictionary, layer: String, tile: Vector2i, shape: String) -> String:
	if not known(g):
		return "The ground does not answer him. Nobody has taught him how it is asked."
	if not SHAPES.has(shape):
		return "There is no such asking."
	if wd.get("kind", "") == "floor" or not Atlas.LAYERS.has(layer):
		return "Only open ground answers: not a floor, and not the rock of a cave."
	var W: int = wd.w
	var H: int = wd.h
	if tile.x < 2 or tile.y < 2 or tile.x >= W - 2 or tile.y >= H - 2:
		return "That is the edge of the world, and is nobody's to move."
	if int(wd.grid[tile.y * W + tile.x]) != MapGen.FLOOR:
		return "Only open ground answers: not a road, a wood, a wall or water."
	if Atlas.owner_id(wd, tile) == "sect":
		return "Not in the Elder's courtyard. He swept it level himself, for seventy years."
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var gq := int(wd.grid[(tile.y + dy) * W + tile.x + dx])
			if gq == MapGen.WATER or gq == MapGen.WALL or gq == MapGen.BUILDING or gq == MapGen.INTERIOR:
				return "Too near a wall, a wood or the water's edge: the ground there is spoken for."
	if _stood(wd, layer).has(tile):
		return "Too near somebody or something that stands: the ground under what stands is left alone."
	if Peaks.at(wd, tile) > 0.05:
		return "The mountains are not his to move."
	if Roads.on(layer, tile):
		return "The high road is everybody's. It stays where it is."
	var h := height(g, layer, tile)
	if shape == "level":
		return "" if (g.shaped.get(layer, {}) as Dictionary).has(tile) else "This ground lies as the land made it already."
	var nh := h + float(SHAPES[shape].dh) * STEP
	if absf(nh) > MAX + 0.001:
		return "The ground has had enough. A piece of land moves so far for anybody, and no further."
	return ""

## Ask shape `shape` of tile `tile`.  Returns {"ok", "why", "h", "line"}.  The half-hour it takes passes,
## and a step that is asking for it counts it.
static func shape(g, wd: Dictionary, layer: String, tile: Vector2i, shape_id: String) -> Dictionary:
	var wy := why(g, wd, layer, tile, shape_id)
	if wy != "":
		return {"ok": false, "why": wy}
	if not g.shaped.has(layer):
		g.shaped[layer] = {}
	var sd: Dictionary = SHAPES[shape_id]
	var h := 0.0
	if shape_id == "level":
		(g.shaped[layer] as Dictionary).erase(tile)
	else:
		h = snappedf(height(g, layer, tile) + float(sd.dh) * STEP, 0.01)
		if absf(h) < 0.01:
			(g.shaped[layer] as Dictionary).erase(tile)
		else:
			g.shaped[layer][tile] = {"h": h, "w": bool(sd.get("water", false)) and h < 0.0}
	g.shaped_n = int(g.shaped_n) + 1
	g.shaped_kinds[shape_id] = int(g.shaped_kinds.get(shape_id, 0)) + 1
	var area := Atlas.owner_id(wd, tile)
	var s: Dictionary = g.cur_step()
	if not s.is_empty() and str(s.kind) == "terra" and (not s.has("area") or str(s.area) == area) and (not s.has("shape") or str(s.shape) == shape_id):
		g.step_terra = int(g.step_terra) + 1
	Clock.set_hour(g, maxf(Clock.hour(g), minf(23.5, Clock.hour(g) + HOURS)))
	g.note("Asked the ground of %s: it %s" % [str(Data.AREAS[area].n) if Data.AREAS.has(area) else "the land", str(sd.verb)])
	return {"ok": true, "why": "", "h": h, "line": str(sd.desc), "area": area}

## The falloff of a shaped tile at `d` tiles from its middle.
static func _fall(d: float) -> float:
	return 1.0 - smoothstep(0.35, REACH, d)

## What the shaped ground of one realm (`sh`: tile -> {h, w}, Game.shaped[layer]) adds to the height of the
## land at point (`x`, `z`) in tiles.
static func rise(sh: Dictionary, x: float, z: float) -> float:
	if sh.is_empty():
		return 0.0
	var sum := 0.0
	var tx := int(floor(x))
	var tz := int(floor(z))
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var t := Vector2i(tx + dx, tz + dy)
			if sh.has(t):
				var d := Vector2(float(t.x) + 0.5 - x, float(t.y) + 0.5 - z).length()
				if d < REACH:
					sum += float(sh[t].h) * _fall(d)
	return clampf(sum, -TOTAL, TOTAL)

## The pools of realm `layer` whose tile lies in rectangle `r`: [[tile, depth], ...].
static func pools(g, layer: String, r: Rect2i) -> Array:
	var out: Array = []
	var sh: Dictionary = g.shaped.get(layer, {})
	for t in sh:
		if r.has_point(t) and bool(sh[t].get("w", false)) and float(sh[t].h) < 0.0:
			out.append([t, -float(sh[t].h)])
	return out

## The piece of open ground of region `area` nearest `from` (by the steps in `dist`: tile -> steps, a
## flood from where he stands) that can be given `shape` from a tile he can stand on: [stand, dir], or [].
static func spot(g, wd: Dictionary, layer: String, area: String, shape_id: String, dist: Dictionary) -> Array:
	var best: Array = []
	var bd := 1 << 30
	for tl in dist:
		var dd := int(dist[tl])
		if dd >= bd or Atlas.owner_id(wd, tl) != area:
			continue
		for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if why(g, wd, layer, tl + d, shape_id) == "":
				bd = dd
				best = [tl, d]
				break
	return best

## The water drawn in a pool `depth` metres deep (a disc a little under the lip of the hollow).
static func pool_model(depth: float, col: Color) -> Node3D:
	var root := Node3D.new()
	var g := MB.new()
	var r := 1.0 + 0.9 * clampf(depth / MAX, 0.0, 1.0)
	g.disc(Vector3(0, 0, 0), r, Color(col.r, col.g, col.b, 0.62), 18, Color(col.r, col.g, col.b, 0.3))
	var mi := MB.mesh_node(root, g.build(MB.mat_glass()))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

## What is said of the land he has shaped, for the page.
static func text(g) -> String:
	if not known(g):
		return "The ground does not answer him yet. It is said somebody under the sea remembers how Yu asked it."
	var n := count(g)
	return "The Dao of Leading Water (Y, facing open ground). %d piece%s of ground stand%s as he asked: %d askings in all (raised %d, lowered %d, pools %d, let lie %d)." % [n, "" if n == 1 else "s", "s" if n == 1 else "",
		int(g.shaped_n), int(g.shaped_kinds.get("raise", 0)), int(g.shaped_kinds.get("lower", 0)), int(g.shaped_kinds.get("pool", 0)), int(g.shaped_kinds.get("level", 0))]
