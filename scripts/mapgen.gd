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
	"longmen": 0.24, "drowned": 0.18, "tushan": 0.27, "buzhou": 0.26,
	"juntian": 0.22, "changhe": 0.22, "ninesprings": 0.26, "youdu": 0.2,
	"penglai": 0.2, "fangzhang": 0.24, "yingzhou": 0.26, "guixu": 0.22,
}

## themes with scattered water (noise threshold: lower = rarer)
const POOLS := {"dunes": -0.55, "fungal": -0.42, "aurora": -0.45, "chaos": -0.4, "maple": -0.5, "karst": -0.3, "lilies": -0.35, "diyu": -0.45, "village": -0.32, "tea": -0.5, "silk": -0.45, "loom": -0.4, "starferry": -0.3, "jasper": -0.38, "fusang": -0.36, "guanghan": -0.44, "longmen": -0.42, "drowned": -0.08, "tushan": -0.52, "buzhou": -0.3, "ninesprings": -0.42, "youdu": -0.55, "penglai": -0.45, "fangzhang": -0.4, "yingzhou": -0.36, "guixu": -0.3}

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
		var keep := _keep_set(spec, id)
		_wild(grid, w, h, spec, rng)
		_outline(grid, w, h, spec, keep)
		# a river through the region (Longmen) and ponds (the Shazhou oasis), never over a clearing
		if spec.has("river"):
			_river(grid, w, h, spec.river, spec.seed, keep)
		for pd in spec.get("ponds", []):
			var pc: Vector2i = pd[0]
			var pr: int = pd[1]
			for dy in range(-pr, pr + 1):
				for dx in range(-pr, pr + 1):
					var q := pc + Vector2i(dx, dy)
					if dx * dx + dy * dy <= pr * pr and q.x > 0 and q.y > 0 and q.x < w - 1 and q.y < h - 1 and not keep.has(q):
						grid[q.y * w + q.x] = WATER
	# lanes: paved strips (market streets, farm tracks, causeways) laid over the ground before the
	# buildings go up; a Rect2i each, in the region's own tiles
	for ln in spec.get("lanes", []):
		var lr: Rect2i = ln
		_rect(grid, w, lr.position.x, lr.position.y, lr.end.x - 1, lr.end.y - 1, PATH)
	# roads: winding streets and dyke paths, a smooth curve through the given points, two tiles wide
	for rd in spec.get("roads", []):
		_road(grid, w, h, rd)
	# blocks: solid, flattened ground under a great landmark (the Fusang's trunk, the Dragon Gate's
	# cliffs, the great cauldron, the pillar of Buzhou).  BUILDING, not WALL: the forest is planted on
	# WALL tiles, and pines grew up through the middle of the cauldron
	for bk in spec.get("blocks", []):
		var br: Rect2i = bk
		_rect(grid, w, br.position.x, br.position.y, br.end.x - 1, br.end.y - 1, BUILDING)
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
	# people and things upstairs or in a cellar (Part XI) live on that floor, not on the ground
	var floor_ents: Array = []
	for p in spec.get("portals", []):
		ents.append({"kind": "portal", "id": "p_" + p.to, "to": p.to, "pos": p.pos, "dest": p.dest, "open": p.open})
		fixed.append(p.pos)
	for n in spec.get("npcs", []):
		# (somebody who came later in the story, "late", is stood in the world after it is built: atlas.gd)
		if n.get("late", false):
			continue
		var ne := {"kind": "npc", "id": n.id, "n": n.n, "pos": n.pos, "col": n.col, "vis": n.get("vis", ["", ""])}
		# (a fated encounter, fate.gd, stands where the story has them: world.ent_visible asks Fate.present)
		for k in ["asset", "race", "hide", "fate"]:
			if n.has(k):
				ne[k] = n[k]
		if n.has("floor"):
			ne["floor"] = n.floor
			floor_ents.append(ne)
			continue
		ents.append(ne)
		fixed.append(n.pos)
	for b in spec.get("bosses", []):
		if b.get("late", false):
			continue
		var be := {"kind": "boss", "id": "boss_" + b.id, "enemy": b.id, "pos": b.pos, "lv": b.lv, "req": b.req}
		# a boss who appears later in the story (Part XIII's Gate Generals and Chiyou)
		if b.has("vis"):
			be["vis"] = b.vis
		ents.append(be)
		fixed.append(b.pos)
	for pk in spec.get("pickups", []):
		if pk.get("late", false):
			continue
		# (a pickup may name the step it appears with: Part XVI's thunder bamboo is not there in Part I)
		var pe := {"kind": "pickup", "id": pk.id, "item": pk.item, "pos": pk.pos, "vis": pk.get("vis", ["" if pk.get("always", false) else spec.get("pickup_vis", ""), ""])}
		if pk.has("n"):
			pe["n"] = pk.n
		# a cache only Spirit Sense can feel (Part XII)
		if pk.get("sense", false):
			pe["sense"] = true
		if pk.has("floor"):
			pe["floor"] = pk.floor
			floor_ents.append(pe)
			continue
		ents.append(pe)
		fixed.append(pk.pos)
	for sp in spec.get("springs", []):
		ents.append({"kind": "spring", "id": "spring", "pos": sp})
	# the Founder's sealed caves (Part XII): a stone door that opens only to a cultivator of its realm
	for ab in spec.get("abodes", []):
		ents.append({"kind": "abode", "id": ab.id, "n": ab.n, "pos": ab.pos, "req": ab.req, "stones": ab.get("stones", 0), "motto": ab.get("motto", "")})
		fixed.append(ab.pos)
	# Dao Steles (Part XI): where a cultivator chooses which road to walk; they stand once the Elder
	# has spoken of the Daos
	for k in spec.get("steles", []).size():
		var st: Vector2i = spec.steles[k]
		ents.append({"kind": "stele", "id": "stele_%s_%d" % [id, k], "pos": st, "vis": ["s_p11_home", ""]})
		fixed.append(st)
	# the ends of the ladders between the realms must be open ground everyone can walk to
	for le in ladder_ends(id):
		fixed.append(le[0])
		fixed.append(le[0] + le[1])
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
	if spec.has("start"):
		start = spec.start
	elif not arrivals.is_empty():
		start = arrivals[0]
	elif not spec.get("portals", []).is_empty():
		start = spec.portals[0].pos + Vector2i(2, 0)
	_clear(grid, w, h, start, 1)
	var trails: AStarGrid2D = null
	for _i in 40:
		var reach := flood(grid, w, h, start)
		var fixed_missing := false
		for f in fixed:
			if not reach.has(f):
				if trails == null:
					trails = _trail_grid(grid, w, h, spec.seed)
				_carve(trails, grid, w, _outside(f, buildings), start)
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
		# Part XIII: the war-bands of the Eight Gates, placed after the region's own packs (so those do
		# not move) and marching only once the formation wakes (`vis`)
		var band: Dictionary = spec.get("warband", {})
		# (a band that came later in the story, "late", is stood in the finished world: atlas.gd)
		if not band.is_empty() and not band.get("late", false):
			var bpool: Array = band.pool
			var bplaced := 0
			tries = 0
			while bplaced < int(band.n) and tries < 4000:
				tries += 1
				var c2: Vector2i = cands[rng.randi() % cands.size()]
				var ok2 := true
				for f in fixed:
					if maxi(absi(f.x - c2.x), absi(f.y - c2.y)) < 5:
						ok2 = false
						break
				if ok2:
					for q in placed:
						if maxi(absi(q.x - c2.x), absi(q.y - c2.y)) < 4:
							ok2 = false
							break
				if not ok2:
					continue
				placed.append(c2)
				bplaced += 1
				var group2: Array = []
				for _k in rng.randi_range(2, 3):
					var pe2: Array = bpool[rng.randi() % bpool.size()]
					group2.append({"id": pe2[0], "lv": rng.randi_range(pe2[1], pe2[2])})
				ents.append({"kind": "enemy", "id": "w%d" % bplaced, "pos": c2, "group": group2, "vis": [str(band.vis), ""]})
	return {"w": w, "h": h, "grid": grid, "ents": ents, "theme": spec.theme, "name": spec.n, "start": start, "buildings": buildings, "floor_ents": floor_ents}

## The ladders (Data.LADDERS) with an end in region `id`: [[tile, out, ladder, end ("a" or "b")], ...]
static func ladder_ends(id: String) -> Array:
	var out: Array = []
	for ld in Data.LADDERS:
		for e in ["a", "b"]:
			if ld[e][0] == id:
				out.append([ld[e][1], ld[e][2], ld, e])
	return out

## The grid of a building's upper storey (level 1) or cellar (level -1), the size of the building's
## rectangle: walls round the edge (no door: the stairs are the way in), floor inside, furniture that
## blocks.  `fl` is the floor's spec ({"props": [[kind, tile, blocks], ...]}) and `stairs` the tile of
## the stairs, both in the same tiles as the rectangle.
static func floor_grid(r: Rect2i, fl: Dictionary, stairs: Vector2i) -> PackedByteArray:
	var g := PackedByteArray()
	g.resize(r.size.x * r.size.y)
	for y in r.size.y:
		for x in r.size.x:
			var edge := x == 0 or y == 0 or x == r.size.x - 1 or y == r.size.y - 1
			g[y * r.size.x + x] = BUILDING if edge else INTERIOR
	for pr in fl.get("props", []):
		var pt: Vector2i = pr[1] - r.position
		if pr.size() > 2 and pr[2] and pt != stairs - r.position:
			g[pt.y * r.size.x + pt.x] = BUILDING
	return g

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

## Trails join anything the forest cut off.  They used to be a greedy random walk towards the
## target that turned whatever it stepped on into path, building walls included, so a trail could
## break through the side of a house (four buildings lost a wall that way once the open ground
## stopped being the whole map).  Now a trail is the cheapest way across a cost grid: open ground is
## cheap, forest and water dear with a little random variation (so trails still wander like deer
## tracks), and buildings and the map's edge cannot be crossed at all.
static func _trail_grid(grid: PackedByteArray, w: int, h: int, seed_: int) -> AStarGrid2D:
	var a := AStarGrid2D.new()
	a.region = Rect2i(0, 0, w, h)
	a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	a.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	a.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	a.update()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 13 + 7
	for y in h:
		for x in w:
			var p := Vector2i(x, y)
			var t := grid[y * w + x]
			if t == BUILDING or t == INTERIOR or x == 0 or y == 0 or x == w - 1 or y == h - 1:
				a.set_point_solid(p, true)
			elif is_walkable_tile(t):
				a.set_point_weight_scale(p, 1.0 + rng.randf() * 0.3)
			elif t == WATER:
				a.set_point_weight_scale(p, 6.0 + rng.randf() * 3.0)
			else:
				a.set_point_weight_scale(p, 2.5 + rng.randf() * 2.5)
	return a

static func _carve(trails: AStarGrid2D, grid: PackedByteArray, w: int, from: Vector2i, to: Vector2i) -> void:
	var was_from := trails.is_point_solid(from)
	trails.set_point_solid(from, false)
	var path := trails.get_id_path(from, to)
	trails.set_point_solid(from, was_from)
	for c in path:
		if not is_walkable_tile(grid[c.y * w + c.x]):
			grid[c.y * w + c.x] = PATH
		trails.set_point_weight_scale(c, 1.0)

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

## The open ground of a wild region is not the rectangle of its map: it is an ellipse filling the
## map, pushed and pulled into lobes and bays by broad noise (a domain warp), bitten into by a second
## noise and frayed at its edge by a fine one; outside it lies forest.  Clearings stay open round
## everything that matters (gates, arrivals, people, bosses, pickups, springs, buildings and lanes),
## and the connectivity pass below joins any that end up in the forest with a trail.
const OUTLINE_P := 2.3

## Tiles of a region's own map that must stay dry, open ground: round everything that matters
## (gates, arrivals, people, bosses, pickups, springs), buildings and lanes.
static func _keep_set(spec: Dictionary, id: String) -> Dictionary:
	var keep := {}
	var pts: Array = []
	for p in spec.get("portals", []):
		pts.append(p.pos)
	# (not the people, lords and things that came later in the story, "late": they are stood in the
	# finished world, atlas.gd, and no older map moves for them)
	for n in spec.get("npcs", []):
		if not n.get("late", false):
			pts.append(n.pos)
	for b in spec.get("bosses", []):
		if not b.get("late", false):
			pts.append(b.pos)
	for pk in spec.get("pickups", []):
		if not pk.get("late", false):
			pts.append(pk.pos)
	for sp in spec.get("springs", []):
		pts.append(sp)
	for a in arrival_tiles(id):
		pts.append(a)
	for st in spec.get("steles", []):
		pts.append(st)
	for ab in spec.get("abodes", []):
		pts.append(ab.pos)
	for le in ladder_ends(id):
		pts.append(le[0])
		pts.append(le[0] + le[1])
	for c in pts:
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				if dx * dx + dy * dy <= 10:
					keep[c + Vector2i(dx, dy)] = true
	var rects: Array = []
	for bd in spec.get("buildings", []):
		rects.append((bd.rect as Rect2i).grow(2))
	for ln in spec.get("lanes", []):
		rects.append((ln as Rect2i).grow(1))
	for bk in spec.get("blocks", []):
		rects.append((bk as Rect2i).grow(3))
	for rr in rects:
		for yy in range(rr.position.y, rr.end.y):
			for xx in range(rr.position.x, rr.end.x):
				keep[Vector2i(xx, yy)] = true
	return keep

static func _outline(grid: PackedByteArray, w: int, h: int, spec: Dictionary, keep: Dictionary) -> void:
	var warp := FastNoiseLite.new()
	warp.seed = spec.seed * 5 + 1
	warp.frequency = 0.02
	warp.fractal_octaves = 2
	var bite := FastNoiseLite.new()
	bite.seed = spec.seed * 5 + 2
	bite.frequency = 0.035
	bite.fractal_octaves = 2
	var fray := FastNoiseLite.new()
	fray.seed = spec.seed * 5 + 3
	fray.frequency = 0.13
	for y in h:
		for x in w:
			var i := y * w + x
			var t := grid[i]
			if t != FLOOR and t != DECOR:
				continue
			if keep.has(Vector2i(x, y)):
				continue
			var u := absf((x + 0.5) / w * 2.0 - 1.0 + warp.get_noise_2d(x, y) * 0.38)
			var v := absf((y + 0.5) / h * 2.0 - 1.0 + warp.get_noise_2d(x + 517.0, y - 211.0) * 0.38)
			var r := pow(pow(u, OUTLINE_P) + pow(v, OUTLINE_P), 1.0 / OUTLINE_P)
			if r > 0.86 + bite.get_noise_2d(x, y) * 0.24 + fray.get_noise_2d(x, y) * 0.06:
				grid[i] = WALL

## A river from `rv[0]` to `rv[1]`, `rv[2]` tiles wide, meandering either side of the straight line
## (the bends grow towards the middle of its course and fade at the ends).
static func _river(grid: PackedByteArray, w: int, h: int, rv: Array, seed_: int, keep: Dictionary) -> void:
	var a: Vector2 = Vector2(rv[0])
	var b: Vector2 = Vector2(rv[1])
	var width: float = float(rv[2])
	var n := FastNoiseLite.new()
	n.seed = seed_ * 3 + 17
	n.frequency = 0.06
	var ln := a.distance_to(b)
	var side := (b - a).orthogonal().normalized()
	var steps := int(ln * 2.0)
	var r := width * 0.5
	for k in steps + 1:
		var t := k / float(maxi(steps, 1))
		var c := a.lerp(b, t) + side * n.get_noise_1d(k * 0.5) * 7.0 * sin(PI * t)
		for dy in range(-int(ceil(r)) - 1, int(ceil(r)) + 2):
			for dx in range(-int(ceil(r)) - 1, int(ceil(r)) + 2):
				var q := Vector2i(int(round(c.x)) + dx, int(round(c.y)) + dy)
				if q.x < 1 or q.y < 1 or q.x >= w - 1 or q.y >= h - 1 or keep.has(q):
					continue
				if Vector2(q).distance_to(c) <= r:
					grid[q.y * w + q.x] = WATER

## A road through `pts` (local tiles): a Catmull-Rom curve, sampled finely, paved two tiles wide.
static func _road(grid: PackedByteArray, w: int, h: int, pts: Array) -> void:
	var p: Array = [pts[0]] + pts + [pts[pts.size() - 1]]
	for i in range(1, p.size() - 2):
		var p0 := Vector2(p[i - 1])
		var p1 := Vector2(p[i])
		var p2 := Vector2(p[i + 1])
		var p3 := Vector2(p[i + 2])
		var steps := int(p1.distance_to(p2) * 3.0) + 1
		for k in steps + 1:
			var t := k / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			var c := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			var q := Vector2i(int(floor(c.x)), int(floor(c.y)))
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var e: Vector2i = q + d
				if e.x > 0 and e.y > 0 and e.x < w - 1 and e.y < h - 1:
					grid[e.y * w + e.x] = PATH

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
	_rect(grid, w, 34, 22, 34, h - 2, PATH)    # down to the Dawn Market at Yanggu (Part IX)
	_rect(grid, w, 6, 22, 6, h - 2, PATH)      # down to the village (Part VII)
	_rect(grid, w, 27, 22, 27, h - 2, PATH)    # to the desert gate (Part V)
	_rect(grid, w, 12, 1, 12, 12, PATH)        # up to the north gate and the river road (Part X)
	for i in 36:
		var x := rng.randi_range(2, w - 3)
		var y := rng.randi_range(2, h - 3)
		if grid[y * w + x] == FLOOR and absi(y - 13) > 1 and absi(x - 20) > 1 and y > 12:
			grid[y * w + x] = WALL
