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

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const DENSITY := {
	"bamboo": 0.30, "marsh": 0.22, "frost": 0.30, "thunder": 0.26, "palace": 0.28,
	"abyss": 0.26, "volcano": 0.30, "void": 0.24, "celestial": 0.22,
}

static func is_walkable_tile(t: int) -> bool:
	return t == FLOOR or t == PATH or t == DECOR

static func build(id: String) -> Dictionary:
	var spec: Dictionary = Data.AREAS[id]
	var w: int = spec.w
	var h: int = spec.h
	var rng := RandomNumberGenerator.new()
	rng.seed = spec.seed
	var grid := PackedByteArray()
	grid.resize(w * h)
	if id == "sect":
		_town(grid, w, h)
	else:
		_wild(grid, w, h, spec, rng)
	# solid border
	for x in w:
		grid[x] = WALL
		grid[(h - 1) * w + x] = WALL
	for y in h:
		grid[y * w] = WALL
		grid[y * w + w - 1] = WALL

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
	var start: Vector2i = arrivals[0] if not arrivals.is_empty() else spec.portals[0].pos + Vector2i(2, 0)
	_clear(grid, w, h, start, 1)
	for _i in 40:
		var reach := flood(grid, w, h, start)
		var fixed_missing := false
		for f in fixed:
			if not reach.has(f):
				_carve(grid, w, f, start)
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
			if pos.x < 9 or pos.x > w - 6:
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
	return {"w": w, "h": h, "grid": grid, "ents": ents, "theme": spec.theme, "name": spec.n, "start": start}

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
				if not is_walkable_tile(t):
					grid[y * w + x] = FLOOR

static func _carve(grid: PackedByteArray, w: int, from: Vector2i, to: Vector2i) -> void:
	var c := from
	while c.x != to.x:
		c.x += signi(to.x - c.x)
		if not is_walkable_tile(grid[c.y * w + c.x]):
			grid[c.y * w + c.x] = PATH
	while c.y != to.y:
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
	_rect(grid, w, 20, 4, 20, h - 2, PATH)
	_rect(grid, w, 15, 1, 25, 3, BUILDING)   # elder hall
	_rect(grid, w, 5, 9, 11, 12, BUILDING)    # alchemist hut
	_rect(grid, w, 28, 9, 34, 12, BUILDING)   # smithy
	_rect(grid, w, 16, 17, 24, 21, WATER)     # lotus pond
	_rect(grid, w, 20, 17, 20, 21, PATH)
	for i in 36:
		var x := rng.randi_range(2, w - 3)
		var y := rng.randi_range(2, h - 3)
		if grid[y * w + x] == FLOOR and absi(y - 13) > 1 and absi(x - 20) > 1:
			grid[y * w + x] = WALL
