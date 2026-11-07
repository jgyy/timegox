class_name Atlas
extends RefCounted
## The open world.  Every region of the game lies on one continuous tile grid: the sect sits on
## Azure Cloud Mountain in the west, and each chapter's chain of regions runs east from the
## mountain as a band of land.  Roads replace the old teleporting gates; a region the story has
## not opened yet is closed by a Lotus Seal barrier across its road.  Borders between regions are
## forest and rock belts with organic, noise-warped edges, and the land itself (theme, trees,
## ground) changes along a wavy line rather than a straight seam.
##
## The world is built once and cached (`Atlas.world()`); it is fully deterministic.

const MARGIN := 8          # wild border round the whole world
const EAST := 14           # room on the east edge for the road that links one band to the next
const HUB := "mountain"
const HUB_W := 60          # the mountain column west of the bands
const ROW_PAD := 4
const WARP := 3.0          # how far region borders wander (tiles)
const BAND := 2.2          # half-thickness of the forest belt between regions (tiles)

## bands of regions, north to south; a flipped band runs west (its regions are mirrored)
const ROWS := [
	{"ids": ["cloudsea", "court", "forge", "garden"], "flip": false},
	{"ids": ["bamboo", "marsh", "frost", "thunder", "palace"], "flip": false},
	{"ids": ["dragon", "volcano", "void", "celestial"], "flip": true},
	{"ids": ["mirror", "grave", "time", "origin"], "flip": false},
	{"ids": ["dunes", "fungal", "aurora", "chaos"], "flip": false},
	{"ids": ["maple", "karst", "springs", "wheel"], "flip": false},
	{"ids": ["village", "terraces", "silk", "loom"], "flip": false},
	{"ids": ["starferry", "magpie", "starpalace", "jasper"], "flip": false},
	{"ids": ["yanggu", "millet", "fusang", "guanghan"], "flip": false},
]

static var _layout := {}
static var _world := {}

# ---------------------------------------------------------------- layout (cheap, no map generation)
## id -> {origin, size, cell (Rect2i), flip, row}; plus "_W", "_H", "_x0"
static func layout() -> Dictionary:
	if not _layout.is_empty():
		return _layout
	var L := {}
	var x0 := MARGIN + HUB_W
	var max_w := 0
	var rows: Array = []
	for row in ROWS:
		var ids: Array = []
		for id in row.ids:
			if Data.AREAS.has(id):
				ids.append(id)
		if ids.is_empty():
			continue
		var rw := 0
		var rh := 0
		for id in ids:
			rw += int(Data.AREAS[id].w)
			rh = maxi(rh, int(Data.AREAS[id].h))
		max_w = maxi(max_w, rw)
		rows.append({"ids": ids, "flip": row.flip, "w": rw, "h": rh + ROW_PAD})
	var x_end := x0 + max_w
	var W := x_end + EAST
	var y := MARGIN
	for ri in rows.size():
		var row: Dictionary = rows[ri]
		var top := 0 if ri == 0 else y
		var bottom := y + int(row.h)
		var ids: Array = row.ids
		var x := x0 if not row.flip else x_end
		for k in ids.size():
			var id: String = ids[k]
			var sw: int = Data.AREAS[id].w
			var sh: int = Data.AREAS[id].h
			if row.flip:
				x -= sw
			var origin := Vector2i(x, y + (int(row.h) - sh) / 2)
			var cl := x
			var cr := x + sw
			if not row.flip:
				if k == 0:
					cl = x0
				if k == ids.size() - 1:
					cr = W
				x += sw
			else:
				if k == 0:
					cr = W
				if k == ids.size() - 1:
					cl = x0
			L[id] = {"origin": origin, "size": Vector2i(sw, sh), "cell": Rect2i(cl, top, cr - cl, bottom - top), "flip": row.flip, "row": ri}
		y = bottom
	var H := y + MARGIN
	# stretch the last band's cells to the south edge
	for id in L:
		var c: Rect2i = L[id].cell
		if c.end.y == y:
			L[id].cell = Rect2i(c.position, Vector2i(c.size.x, H - c.position.y))
	L[HUB] = {"origin": Vector2i(MARGIN, MARGIN), "size": Vector2i(HUB_W, H - 2 * MARGIN), "cell": Rect2i(0, 0, x0, H), "flip": false, "row": -1}
	# the sect: inside the mountain, its east gate lined up with the bamboo forest's west gate
	var bo: Vector2i = L.bamboo.origin
	var sect_o := Vector2i(x0 - int(Data.AREAS.sect.w) - 1, bo.y + 22 - 13)
	L["sect"] = {"origin": sect_o, "size": Vector2i(Data.AREAS.sect.w, Data.AREAS.sect.h), "cell": Rect2i(sect_o, Vector2i(Data.AREAS.sect.w, Data.AREAS.sect.h)), "flip": false, "row": -1}
	L["_W"] = W
	L["_H"] = H
	L["_x0"] = x0
	_layout = L
	return L

static func region_ids() -> Array:
	var out: Array = [HUB, "sect"]
	for row in ROWS:
		for id in row.ids:
			if Data.AREAS.has(id):
				out.append(id)
	return out

## local tile of region `id` (as written in Data.AREAS) -> world tile
static func to_world(id: String, p: Vector2i) -> Vector2i:
	var L := layout()
	var r: Dictionary = L[id]
	var q := p
	if r.flip:
		q.x = int(r.size.x) - 1 - p.x
	return r.origin + q

# ---------------------------------------------------------------- world build
static func world() -> Dictionary:
	if _world.is_empty():
		_world = _build()
	return _world

static func _cell_index(cells: Array, x: float, y: float) -> int:
	for i in cells.size():
		var c: Rect2i = cells[i]
		if x >= c.position.x and x < c.end.x and y >= c.position.y and y < c.end.y:
			return i
	return 0

static func _build() -> Dictionary:
	var L := layout()
	var W: int = L._W
	var H: int = L._H
	var x0: int = L._x0
	var ids := region_ids()
	var idx := {}
	for i in ids.size():
		idx[ids[i]] = i
	var grid := PackedByteArray()
	grid.resize(W * H)
	grid.fill(MapGen.WALL)
	var maps := {}
	# ---- stamp every region's own map
	for id in ids:
		var r: Dictionary = L[id]
		var m: Dictionary = MapGen.build(id, r.size if id == HUB else Vector2i.ZERO)
		maps[id] = m
		var mw: int = m.w
		for yy in int(m.h):
			for xx in mw:
				var p := to_world(id, Vector2i(xx, yy))
				grid[p.y * W + p.x] = m.grid[yy * mw + xx]
	# ---- ownership: the cell under a noise-warped point, so region borders wander
	var cells: Array = []
	var cell_ids: Array = []
	for id in ids:
		if id == "sect":
			continue
		cells.append(L[id].cell)
		cell_ids.append(idx[id])
	var nx := FastNoiseLite.new()
	nx.seed = 4242
	nx.frequency = 0.06
	var ny := FastNoiseLite.new()
	ny.seed = 9191
	ny.frequency = 0.06
	var owner := PackedByteArray()
	owner.resize(W * H)
	var sect_r: Rect2i = L.sect.cell
	for y in H:
		for x in W:
			var i := y * W + x
			if sect_r.has_point(Vector2i(x, y)):
				owner[i] = idx.sect
				continue
			var wx := clampf(x + 0.5 + nx.get_noise_2d(x, y) * WARP, 0.0, W - 0.01)
			var wy := clampf(y + 0.5 + ny.get_noise_2d(x, y) * WARP, 0.0, H - 0.01)
			var ci := _cell_index(cells, wx, wy)
			owner[i] = cell_ids[ci]
			# the forest belt between regions (never opens anything; only adds trees and rock)
			var c: Rect2i = cells[ci]
			var dist := minf(minf(wx - c.position.x, c.end.x - wx), minf(wy - c.position.y, c.end.y - wy))
			var at_edge := wx - c.position.x < BAND and c.position.x == 0 or c.end.x - wx < BAND and c.end.x == W
			if dist < BAND or at_edge:
				grid[i] = MapGen.WALL
	# ---- the sect's pagoda stands on the mountain north-west of the courtyard
	var pag := sect_r.position + Vector2i(-5, 3)
	for yy in range(pag.y - 1, pag.y + 2):
		for xx in range(pag.x - 1, pag.x + 2):
			grid[yy * W + xx] = MapGen.BUILDING
	# ---- roads between gates, seals where the story has not opened the way yet
	var seals: Array = []
	var done := {}
	var road_n := 0
	for a in ids:
		for p in Data.AREAS[a].get("portals", []):
			var b: String = p.to
			if not Data.AREAS.has(b) or not L.has(b):
				continue
			var key := [a, b]
			key.sort()
			if done.has(str(key)):
				continue
			done[str(key)] = true
			var back = null
			for q in Data.AREAS[b].get("portals", []):
				if q.to == a:
					back = q
			if back == null:
				continue
			var ga := to_world(a, p.pos)
			var gb := to_world(b, back.pos)
			road_n += 1
			_road(grid, W, H, x0, ga, _gate_dir(a, p.pos), gb, _gate_dir(b, back.pos), road_n, a == "sect" or b == "sect")
			# the road runs on through the border forest to where travellers arrive in each region
			if a != "sect":
				_line(grid, W, ga, to_world(a, back.dest))
			if b != "sect":
				_line(grid, W, gb, to_world(b, p.dest))
			if p.open != "":
				seals.append(_seal(grid, W, b, back.pos, p.open, a))
			elif back.open != "":
				seals.append(_seal(grid, W, a, p.pos, back.open, b))
	# ---- entities, in world tiles
	var ents: Array = []
	var buildings: Array = []
	for id in ids:
		var m: Dictionary = maps[id]
		for e in m.ents:
			if e.kind == "portal":
				continue
			var ge: Dictionary = e.duplicate(true)
			ge.pos = to_world(id, e.pos)
			ge["area"] = id
			if ge.kind == "enemy":
				ge.id = id + ":" + str(e.id)
			ents.append(ge)
		for bd in m.buildings:
			var gb2: Dictionary = bd.duplicate(true)
			var rr: Rect2i = bd.rect
			gb2.rect = Rect2i(to_world(id, rr.position), rr.size)
			gb2.door = to_world(id, bd.door)
			gb2["area"] = id
			var props: Array = []
			for pr in bd.get("props", []):
				props.append([pr[0], to_world(id, pr[1]), pr.size() > 2 and pr[2]])
			gb2.props = props
			buildings.append(gb2)
	for s in seals:
		ents.append(s)
	var start := to_world("sect", Vector2i(20, 8))
	# ---- every entity must be reachable from the sect with all seals open
	_connect(grid, W, H, owner, idx, ents, start)
	return {"w": W, "h": H, "grid": grid, "owner": owner, "ids": ids, "idx": idx, "ents": ents, "buildings": buildings,
		"start": start, "layout": L, "maps": maps}

## which way a gate faces out of its region (in world directions)
static func _gate_dir(id: String, pos: Vector2i) -> Vector2i:
	var r: Dictionary = layout()[id]
	var s: Vector2i = r.size
	var d := Vector2i.ZERO
	if pos.x <= 1:
		d = Vector2i(-1, 0)
	elif pos.x >= s.x - 2:
		d = Vector2i(1, 0)
	elif pos.y <= 1:
		d = Vector2i(0, -1)
	else:
		d = Vector2i(0, 1)
	if r.flip:
		d.x = -d.x
	return d

## A road from gate `ga` to gate `gb`, two tiles wide, gently meandering on long stretches.
static func _road(grid: PackedByteArray, W: int, H: int, x0: int, ga: Vector2i, da: Vector2i, gb: Vector2i, db: Vector2i, n: int, hub: bool) -> void:
	var pts: Array = [ga]
	var a1 := ga + da * 3
	var b1 := gb + db * 3
	if da.x != 0 and da == db:
		# both gates face the same way (one band to the next, round the east edge)
		var cx := maxi(ga.x, gb.x) + 5 if da.x > 0 else mini(ga.x, gb.x) - 5
		pts += [Vector2i(cx, ga.y), Vector2i(cx, gb.y)]
	elif hub:
		# a mountain road: away from the sect, along the mountain, then east into the band
		var lane := x0 - 6
		if da.y != 0:
			pts += [a1, Vector2i(a1.x, gb.y), Vector2i(mini(a1.x, lane), gb.y)]
		elif da.x < 0:
			var wx := a1.x - 3 - (n % 4) * 3
			pts += [Vector2i(wx, ga.y), Vector2i(wx, gb.y), Vector2i(lane, gb.y)]
		else:
			pts += [Vector2i((ga.x + gb.x) / 2, ga.y), Vector2i((ga.x + gb.x) / 2, gb.y)]
	else:
		var mx := (ga.x + gb.x) / 2
		pts += [Vector2i(mx, ga.y), Vector2i(mx, gb.y)]
	pts.append(gb)
	var noise := FastNoiseLite.new()
	noise.seed = 700 + n
	noise.frequency = 0.05
	var prev := ga
	for i in range(1, pts.size()):
		var p0: Vector2i = pts[i - 1]
		var p1: Vector2i = pts[i]
		var seg := Vector2(p1 - p0)
		var ln := seg.length()
		var steps := int(ceil(ln))
		var perp := Vector2(-seg.y, seg.x).normalized() if ln > 0.0 else Vector2.ZERO
		var amp := 3.5 if ln > 16.0 else 0.0
		for k in range(1, steps + 1):
			var t := k / float(steps)
			var q := Vector2(p0).lerp(Vector2(p1), t) + perp * amp * sin(PI * t) * noise.get_noise_1d(k + i * 97.0)
			var c := Vector2i(roundi(q.x), roundi(q.y))
			if hub and absi(c.y - gb.y) > 1:
				c.x = mini(c.x, x0 - 4)
			c.x = clampi(c.x, 2, W - 3)
			c.y = clampi(c.y, 2, H - 3)
			_line(grid, W, prev, c)
			prev = c

## 4-connected line of 2x2 road stamps
static func _line(grid: PackedByteArray, W: int, a: Vector2i, b: Vector2i) -> void:
	var c := a
	_stamp(grid, W, c)
	while c != b:
		if absi(b.x - c.x) >= absi(b.y - c.y):
			c.x += signi(b.x - c.x)
		else:
			c.y += signi(b.y - c.y)
		_stamp(grid, W, c)

static func _stamp(grid: PackedByteArray, W: int, c: Vector2i) -> void:
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var p: Vector2i = c + d
		var t := grid[p.y * W + p.x]
		if t != MapGen.BUILDING and t != MapGen.INTERIOR:
			grid[p.y * W + p.x] = MapGen.PATH

## A Lotus Seal barrier across the road where it crosses the border of region `id` at gate `pos`.
static func _seal(grid: PackedByteArray, W: int, id: String, pos: Vector2i, req: String, from: String) -> Dictionary:
	var r: Dictionary = layout()[id]
	var s: Vector2i = r.size
	var line: Array = []
	if pos.x <= 1 or pos.x >= s.x - 2:
		var lx := 0 if pos.x <= 1 else s.x - 1
		for dy in range(-3, 4):
			line.append(to_world(id, Vector2i(lx, pos.y + dy)))
	else:
		var ly := 0 if pos.y <= 1 else s.y - 1
		for dx in range(-3, 4):
			line.append(to_world(id, Vector2i(pos.x + dx, ly)))
	var tiles: Array = []
	for t in line:
		var tv: Vector2i = t
		if MapGen.is_walkable_tile(grid[tv.y * W + tv.x]):
			tiles.append(tv)
	var c: Vector2i = to_world(id, pos)
	if not tiles.is_empty():
		c = tiles[tiles.size() / 2]
	return {"kind": "seal", "id": "seal_" + id, "area": id, "to": id, "from": from, "pos": c, "tiles": tiles, "open": req}

## Any entity the borders cut off is reconnected by a trail inside its own region.
static func _connect(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, idx: Dictionary, ents: Array, start: Vector2i) -> void:
	for _pass in 6:
		var reach := MapGen.flood(grid, W, H, start)
		var fixed := 0
		for e in ents:
			if e.kind == "seal" or e.kind == "spring":
				continue
			if reach.has(e.pos):
				continue
			fixed += 1
			# breadth-first through anything in the same region to the nearest reachable tile
			var own := owner[e.pos.y * W + e.pos.x]
			var prev := {e.pos: e.pos}
			var q: Array = [e.pos]
			var i := 0
			var hit := Vector2i(-1, -1)
			while i < q.size() and i < 20000:
				var c: Vector2i = q[i]
				i += 1
				if reach.has(c):
					hit = c
					break
				for d in MapGen.DIRS:
					var n: Vector2i = c + d
					if n.x < 1 or n.y < 1 or n.x >= W - 1 or n.y >= H - 1 or prev.has(n):
						continue
					if owner[n.y * W + n.x] != own:
						continue
					var tn := grid[n.y * W + n.x]
					if tn == MapGen.BUILDING:
						continue
					prev[n] = c
					q.append(n)
			if hit.x < 0:
				continue
			var cur := hit
			while cur != e.pos:
				if not MapGen.is_walkable_tile(grid[cur.y * W + cur.x]):
					grid[cur.y * W + cur.x] = MapGen.FLOOR
				cur = prev[cur]
			if not MapGen.is_walkable_tile(grid[cur.y * W + cur.x]):
				grid[cur.y * W + cur.x] = MapGen.FLOOR
		if fixed == 0:
			return

# ---------------------------------------------------------------- queries
static func owner_id(wd: Dictionary, p: Vector2i) -> String:
	if p.x < 0 or p.y < 0 or p.x >= wd.w or p.y >= wd.h:
		return HUB
	return wd.ids[wd.owner[p.y * wd.w + p.x]]

## The tiles a region renders: a copy of its bounding box with other regions' tiles blanked out.
static func slice(wd: Dictionary, id: String) -> Dictionary:
	var W: int = wd.w
	var me: int = wd.idx[id]
	var x_lo := W
	var y_lo: int = wd.h
	var x_hi := -1
	var y_hi := -1
	var c: Rect2i = wd.layout[id].cell
	var probe := c.grow(int(WARP) + 2).intersection(Rect2i(0, 0, W, wd.h))
	for y in range(probe.position.y, probe.end.y):
		for x in range(probe.position.x, probe.end.x):
			if wd.owner[y * W + x] == me:
				x_lo = mini(x_lo, x)
				x_hi = maxi(x_hi, x)
				y_lo = mini(y_lo, y)
				y_hi = maxi(y_hi, y)
	var r := Rect2i(x_lo, y_lo, x_hi - x_lo + 1, y_hi - y_lo + 1)
	var g := PackedByteArray()
	g.resize(r.size.x * r.size.y)
	for y in r.size.y:
		for x in r.size.x:
			var i: int = (y + r.position.y) * W + x + r.position.x
			g[y * r.size.x + x] = wd.grid[i] if wd.owner[i] == me else MapGen.VOID
	return {"rect": r, "grid": g}
