class_name MapGen
extends RefCounted
## Deterministic procedural map generator.  Every area is seeded, and the generator
## guarantees that all portals, NPCs, pickups and bosses are reachable from the entrance.

const FLOOR := 0
const WALL := 1
const WATER := 2
const PATH := 3
const DECOR := 4
const BUILDING := 5
## floor inside a building (walkable; rendered as planks under a roof that lifts away)
const INTERIOR := 6
## a tile owned by another region (only in a region's render slice; never in the world grid)
const VOID := 7

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const DENSITY := {
	"bamboo": 0.30, "marsh": 0.22, "frost": 0.30, "thunder": 0.26, "palace": 0.28,
	"abyss": 0.26, "volcano": 0.30, "void": 0.24, "celestial": 0.22,
	"mirror": 0.24, "grave": 0.28, "time": 0.26, "origin": 0.22,
	"cloudsea": 0.24, "court": 0.26, "forge": 0.28, "garden": 0.24,
	"dunes": 0.22, "fungal": 0.28, "aurora": 0.24, "chaos": 0.24,
	"maple": 0.3, "karst": 0.26, "lilies": 0.22, "diyu": 0.26,
	"village": 0.2, "tea": 0.24, "silk": 0.3, "loom": 0.22,
	"starferry": 0.2, "magpie": 0.26, "starpalace": 0.22, "jasper": 0.24,
	"yanggu": 0.17, "millet": 0.2, "fusang": 0.27, "guanghan": 0.23,
}

## themes with scattered water (noise threshold: lower = rarer)
const POOLS := {"dunes": -0.55, "fungal": -0.42, "aurora": -0.45, "chaos": -0.4, "maple": -0.5, "karst": -0.3, "lilies": -0.35, "diyu": -0.45, "village": -0.32, "tea": -0.5, "silk": -0.45, "loom": -0.4, "starferry": -0.3, "jasper": -0.38, "fusang": -0.36, "guanghan": -0.44}

static func is_walkable_tile(t: int) -> bool:
	return t == FLOOR or t == PATH or t == DECOR or t == INTERIOR

static func build(id: String, size := Vector2i.ZERO) -> Dictionary:
	var spec: Dictionary = Data.AREAS[id]
	var w: int = spec.w if size == Vector2i.ZERO else size.x
	var h: int = spec.h if size == Vector2i.ZERO else size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = spec.seed
	var grid := PackedByteArray()
	grid.resize(w * h)
	if id == "sect":
		_town(grid, w, h)
	else:
		_wild(grid, w, h, spec, rng)
	# lanes: paved strips (market streets, farm tracks, causeways) laid over the ground before the
	# buildings go up; a Rect2i each, in the region's own tiles
	for ln in spec.get("lanes", []):
		var lr: Rect2i = ln
		_rect(grid, w, lr.position.x, lr.position.y, lr.end.x - 1, lr.end.y - 1, PATH)
	# blocks: ground kept solid under a great landmark (the Fusang's trunk)
	for bk in spec.get("blocks", []):
		var br: Rect2i = bk
		_rect(grid, w, br.position.x, br.position.y, br.end.x - 1, br.end.y - 1, WALL)
	# solid border
	for x in w:
		grid[x] = WALL
		grid[(h - 1) * w + x] = WALL
	for y in h:
		grid[y * w] = WALL
		grid[y * w + w - 1] = WALL
	# enterable buildings: walls round the edge, a door, planks inside, furniture that blocks
	var buildings: Array = []
	for bd in spec.get("buildings", []):
		buildings.append(stamp_building(grid, w, bd))

	var ents: Array = []
	var fixed: Array = []
	for p in spec.get("portals", []):
		ents.append({"kind": "portal", "id": "p_" + p.to, "to": p.to, "pos": p.pos, "dest": p.dest, "open": p.open})
		fixed.append(p.pos)
	for n in spec.get("npcs", []):
		ents.append({"kind": "npc", "id": n.id, "n": n.n, "pos": n.pos, "col": n.col, "vis": n.get("vis", ["", ""])})
		fixed.append(n.pos)
	for b in spec.get("bosses", []):
		ents.append({"kind": "boss", "id": "boss_" + b.id, "enemy": b.id, "pos": b.pos, "lv": b.lv, "req": b.req})
		fixed.append(b.pos)
	for pk in spec.get("pickups", []):
		ents.append({"kind": "pickup", "id": pk.id, "item": pk.item, "pos": pk.pos, "vis": [spec.get("pickup_vis", ""), ""]})
		fixed.append(pk.pos)
	for sp in spec.get("springs", []):
		ents.append({"kind": "spring", "id": "spring", "pos": sp})
	# every door opens onto walkable ground that the rest of the map can reach
	for bd in buildings:
		var o := _outside(bd.rect.position + Vector2i(1, 1), buildings)
		if not is_walkable_tile(grid[o.y * w + o.x]):
			grid[o.y * w + o.x] = PATH
		fixed.append(o)

	# arrival tiles (where other areas drop the player)
	var arrivals: Array = arrival_tiles(id)
	for a in arrivals:
		fixed.append(a)
	# clear space around anything important
	for f in fixed:
		_clear(grid, w, h, f, 1)
	for a in arrivals:
		_clear(grid, w, h, a, 2)
	for p in spec.get("portals", []):
		_clear(grid, w, h, p.pos + Vector2i(1, 0), 1)
	# connectivity
	var start: Vector2i = Vector2i(w / 2, h / 2)
	if not arrivals.is_empty():
		start = arrivals[0]
	elif not spec.get("portals", []).is_empty():
		start = spec.portals[0].pos + Vector2i(2, 0)
	_clear(grid, w, h, start, 1)
	for _i in 40:
		var reach := flood(grid, w, h, start)
		var fixed_missing := false
		for f in fixed:
			if not reach.has(f):
				_carve(grid, w, _outside(f, buildings), start, spec.seed + _i)
				fixed_missing = true
				break
		if not fixed_missing:
			break
	var reach2 := flood(grid, w, h, start)

	# enemies
	var count: int = spec.get("enemies", 0)
	if count > 0:
		var cands: Array = []
		for pos in reach2:
			if pos.x < 9 or pos.x > w - 6 or grid[pos.y * w + pos.x] == INTERIOR:
				continue
			if _free_neighbors(grid, w, pos) < 7:
				continue
			cands.append(pos)
		cands.sort()
		var placed: Array = []
		var tries := 0
		var pool: Array = spec.pool
		while placed.size() < count and tries < 4000:
			tries += 1
			var c: Vector2i = cands[rng.randi() % cands.size()]
			var ok := true
			for f in fixed:
				if maxi(absi(f.x - c.x), absi(f.y - c.y)) < 6:
					ok = false
					break
			if ok:
				for q in placed:
					if maxi(absi(q.x - c.x), absi(q.y - c.y)) < 5:
						ok = false
						break
			if not ok:
				continue
			placed.append(c)
			var group: Array = []
			var n := rng.randi_range(1, 3)
			for _k in n:
				var pe: Array = pool[rng.randi() % pool.size()]
				group.append({"id": pe[0], "lv": rng.randi_range(pe[1], pe[2])})
			ents.append({"kind": "enemy", "id": "e%d" % placed.size(), "pos": c, "group": group})
	return {"w": w, "h": h, "grid": grid, "ents": ents, "theme": spec.theme, "name": spec.n, "start": start, "buildings": buildings}

## Walls on the rectangle's edge, a door gap, a plank floor inside and furniture tiles that block.
static func stamp_building(grid: PackedByteArray, w: int, bd: Dictionary) -> Dictionary:
	var r: Rect2i = bd.rect
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var edge := x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1
			grid[y * w + x] = BUILDING if edge else INTERIOR
	var door: Vector2i = bd.door
	grid[door.y * w + door.x] = INTERIOR
	for pr in bd.get("props", []):
		var pt: Vector2i = pr[1]
		if pr.size() > 2 and pr[2]:
			grid[pt.y * w + pt.x] = BUILDING
	var out := bd.duplicate(true)
	return out

## A point inside a building is reached through its door: trails are carved to the doorstep.
static func _outside(p: Vector2i, buildings: Array) -> Vector2i:
	for bd in buildings:
		var r: Rect2i = bd.rect
		if r.has_point(p):
			var d: Vector2i = bd.door
			var c := r.get_center()
			var out := Vector2i(signi(d.x - c.x) if (d.x == r.position.x or d.x == r.end.x - 1) else 0, signi(d.y - c.y) if (d.y == r.position.y or d.y == r.end.y - 1) else 0)
			return d + out
	return p

## the inside of a building (walkable tiles under the roof)
static func inner_rect(bd: Dictionary) -> Rect2i:
	var r: Rect2i = bd.rect
	return Rect2i(r.position + Vector2i(1, 1), r.size - Vector2i(2, 2))

static func arrival_tiles(id: String) -> Array:
	var out: Array = []
	for aid in Data.AREAS:
		for p in Data.AREAS[aid].get("portals", []):
			if p.to == id:
				out.append(p.dest)
	return out

static func flood(grid: PackedByteArray, w: int, h: int, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var q: Array = [start]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		for d in DIRS:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or seen.has(n):
				continue
			if not is_walkable_tile(grid[n.y * w + n.x]):
				continue
			seen[n] = true
			q.append(n)
	return seen

static func _free_neighbors(grid: PackedByteArray, w: int, pos: Vector2i) -> int:
	var n := 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if is_walkable_tile(grid[(pos.y + dy) * w + pos.x + dx]):
				n += 1
	return n

static func _clear(grid: PackedByteArray, w: int, h: int, c: Vector2i, r: int) -> void:
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			var x := c.x + dx
			var y := c.y + dy
			if x > 0 and y > 0 and x < w - 1 and y < h - 1:
				var t := grid[y * w + x]
				if not is_walkable_tile(t) and t != BUILDING:
					grid[y * w + x] = FLOOR

## A trail from `from` to `to` that wanders like a deer track: each step goes along x or y at
## random, weighted by how far there is still to go on each axis, so trails run on the diagonal
## in ragged steps instead of the old straight L-shaped corridors.
static func _carve(grid: PackedByteArray, w: int, from: Vector2i, to: Vector2i, salt: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(from.x * 31 + to.x, from.y * 17 + to.y, salt))
	var c := from
	var guard := 0
	while c != to and guard < 4000:
		guard += 1
		var dx := absi(to.x - c.x)
		var dy := absi(to.y - c.y)
		if rng.randf() * float(dx + dy) < float(dx):
			c.x += signi(to.x - c.x)
		else:
			c.y += signi(to.y - c.y)
		if not is_walkable_tile(grid[c.y * w + c.x]):
			grid[c.y * w + c.x] = PATH

static func _wild(grid: PackedByteArray, w: int, h: int, spec: Dictionary, rng: RandomNumberGenerator) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = spec.seed
	noise.frequency = 0.075
	var noise2 := FastNoiseLite.new()
	noise2.seed = spec.seed + 99
	noise2.frequency = 0.05
	var thr: float = 1.0 - float(DENSITY.get(spec.theme, 0.28)) * 2.0
	for y in h:
		for x in w:
			var v := noise.get_noise_2d(x, y)
			var t := FLOOR
			if v > thr * 0.55 + 0.1:
				t = WALL
			elif spec.theme == "marsh" and noise2.get_noise_2d(x, y) < -0.22:
				t = WATER
			elif spec.theme == "garden" and noise2.get_noise_2d(x, y) < -0.4:
				t = WATER  # lotus ponds between the orchards
			elif spec.theme in POOLS and noise2.get_noise_2d(x, y) < POOLS[spec.theme]:
				t = WATER  # oases, glowing spore pools, frozen lakes, the formless sea
			elif rng.randf() < 0.045:
				t = WALL
			elif rng.randf() < 0.12:
				t = DECOR
			grid[y * w + x] = t

static func _rect(grid: PackedByteArray, w: int, x0: int, y0: int, x1: int, y1: int, t: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			grid[y * w + x] = t

static func _town(grid: PackedByteArray, w: int, h: int) -> void:
	for i in grid.size():
		grid[i] = FLOOR
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 90:
		var x := rng.randi_range(1, w - 2)
		var y := rng.randi_range(1, h - 2)
		grid[y * w + x] = DECOR
	_rect(grid, w, 1, 13, w - 2, 13, PATH)
	_rect(grid, w, 20, 8, 20, h - 2, PATH)     # from the hall door to the south gate
	_rect(grid, w, 7, 12, 7, 13, PATH)         # alchemist's door
	_rect(grid, w, 32, 12, 32, 13, PATH)       # smithy door
	_rect(grid, w, 31, 14, 31, 14, PATH)       # library door
	_rect(grid, w, 1, 6, 7, 6, PATH)           # kitchen door, round the pharmacy to the west road
	_rect(grid, w, 1, 6, 1, 13, PATH)
	_rect(grid, w, 33, 6, 38, 6, PATH)         # training hall door, round the smithy to the east road
	_rect(grid, w, 38, 6, 38, 13, PATH)
	_rect(grid, w, 7, 14, 7, 14, PATH)         # dormitory door
	for py in range(16, 23):                   # lotus pond (an oval, not a box)
		for px in range(14, 27):
			var ex := (px - 20.0) / 5.6
			var ey := (py - 19.0) / 2.9
			if ex * ex + ey * ey <= 1.0:
				grid[py * w + px] = WATER
	_rect(grid, w, 20, 17, 20, 21, PATH)
	_rect(grid, w, 21, 22, w - 2, 22, PATH)    # south-east road (Part V)
	_rect(grid, w, 1, 22, 19, 22, PATH)        # south-west funeral road (Part VI)
	_rect(grid, w, 34, 22, 34, h - 2, PATH)    # to the desert gate
	_rect(grid, w, 6, 22, 6, h - 2, PATH)      # down to the village (Part VII)
	_rect(grid, w, 27, 22, 27, h - 2, PATH)    # down to the Dawn Market at Yanggu (Part IX)
	for i in 36:
		var x := rng.randi_range(2, w - 3)
		var y := rng.randi_range(2, h - 3)
		if grid[y * w + x] == FLOOR and absi(y - 13) > 1 and absi(x - 20) > 1 and y > 12:
			grid[y * w + x] = WALL
