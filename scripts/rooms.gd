class_name Rooms
extends RefCounted
## Twice the room indoors (the Hollow Hills release).  Until now a building had the floors its entry
## in Data.AREAS wrote out by hand: eighty-six ground floors, seventeen upper storeys and thirteen
## cellars.  Now every building has a cellar, and every building whose roof can carry one (not a
## kitchen, a bathhouse or a hermit's one room) has an upper storey: the ones written by
## hand stay as they are, and the rest are laid out here from the building's own rectangle and seed:
## where the stairs go (against a wall, on a tile nobody needs to get past), what the floor is called
## (a house has a sleeping loft and a root cellar, an inn has guest rooms and a wine cellar, a smithy
## a pattern loft and an ore store...), and what stands on it, including twelve kinds of furniture
## that are new and can all be used (props.gd): a chest, a bronze mirror, a mortar, a spinning wheel,
## an abacus, a cradle, a wine jar, a clothes stand, a washstand, a carver's bench, a hollow panel in
## the wall, a grain bin and a lattice window.
##
## `MapGen.stamp_building` asks for the whole building (`complete`), so everything that reads a
## realm's buildings (the atlas, the world, the people of the towns) sees the same floors.

## styles whose roof does not take a storey
const NO_UPPER := ["kitchen", "bathhouse", "hermitage", "aerie"]

## what the floors of a building of each style are called and furnished with: [name, [kind, blocks]...]
## (the pieces that block go against the walls; the first few that fit are taken)
const UPPER := {
	"house": ["the sleeping loft", [["bed", true], ["chest", true], ["cradle", true], ["window", false], ["mirror", true], ["clothes_stand", true], ["lantern", false], ["cushion", false]]],
	"huizhou": ["the upper chamber", [["bed", true], ["mirror", true], ["spinning_wheel", true], ["window", false], ["chest", true], ["scroll", false], ["clothes_stand", true], ["lantern", false]]],
	"inn": ["the guest rooms", [["bed", true], ["bed", true], ["washstand", true], ["window", false], ["chest", true], ["table", true], ["clothes_stand", true], ["lantern", false]]],
	"teahouse": ["the upper tea room", [["table", true], ["window", false], ["cushion", false], ["cushion", false], ["scroll", false], ["wine_jar", true], ["abacus", true], ["lantern", false]]],
	"shop": ["the counting room", [["abacus", true], ["chest", true], ["shelf", true], ["window", false], ["desk", true], ["wall_panel", false], ["grain_bin", true], ["lantern", false]]],
	"hall": ["the gallery", [["scroll", false], ["scroll", false], ["cushion", false], ["window", false], ["cabinet", true], ["chest", true], ["desk", true], ["lantern", false]]],
	"library": ["the reading gallery", [["bookshelf", true], ["bookshelf", true], ["desk", true], ["window", false], ["abacus", true], ["scroll", false], ["cushion", false], ["lantern", false]]],
	"dorm": ["the upper bunks", [["bed", true], ["bed", true], ["bed", true], ["window", false], ["washstand", true], ["clothes_stand", true], ["chest", true], ["lantern", false]]],
	"alchemist": ["the drying loft", [["herbs", false], ["mortar", true], ["shelf", true], ["window", false], ["herbs", false], ["chest", true], ["workbench", true], ["lantern", false]]],
	"smithy": ["the pattern loft", [["workbench", true], ["rack", true], ["chest", true], ["window", false], ["shelf", true], ["wall_panel", false], ["barrel", true], ["lantern", false]]],
	"farmhouse": ["the hayloft", [["grain_bin", true], ["bed", true], ["chest", true], ["window", false], ["spinning_wheel", true], ["herbs", false], ["barrel", true], ["lantern", false]]],
	"shrine": ["the bell loft", [["cushion", false], ["chest", true], ["scroll", false], ["window", false], ["cabinet", true], ["cushion", false], ["altar", true], ["lantern", false]]],
	"seahouse": ["the net loft", [["bed", true], ["chest", true], ["spinning_wheel", true], ["window", false], ["clothes_stand", true], ["barrel", true], ["cradle", true], ["lantern", false]]],
}
const CELLAR := {
	"house": ["the root cellar", [["barrel", true], ["grain_bin", true], ["shelf", true], ["wine_jar", true], ["chest", true], ["wall_panel", false], ["lantern", false], ["lantern", false]]],
	"huizhou": ["the family store", [["chest", true], ["wine_jar", true], ["cabinet", true], ["grain_bin", true], ["wall_panel", false], ["shelf", true], ["lantern", false], ["lantern", false]]],
	"farmhouse": ["the root cellar", [["grain_bin", true], ["barrel", true], ["mortar", true], ["shelf", true], ["wine_jar", true], ["wall_panel", false], ["lantern", false], ["lantern", false]]],
	"inn": ["the wine cellar", [["wine_jar", true], ["wine_jar", true], ["barrel", true], ["barrel", true], ["shelf", true], ["chest", true], ["lantern", false], ["lantern", false]]],
	"teahouse": ["the tea store", [["chest", true], ["shelf", true], ["wine_jar", true], ["mortar", true], ["barrel", true], ["wall_panel", false], ["lantern", false], ["lantern", false]]],
	"shop": ["the strongroom", [["chest", true], ["chest", true], ["abacus", true], ["shelf", true], ["wall_panel", false], ["grain_bin", true], ["lantern", false], ["lantern", false]]],
	"hall": ["the undercroft", [["altar", true], ["chest", true], ["cabinet", true], ["wall_panel", false], ["cushion", false], ["scroll", false], ["lantern", false], ["lantern", false]]],
	"shrine": ["the offering store", [["chest", true], ["wine_jar", true], ["shelf", true], ["cushion", false], ["wall_panel", false], ["cabinet", true], ["lantern", false], ["lantern", false]]],
	"library": ["the stacks below", [["bookshelf", true], ["bookshelf", true], ["chest", true], ["desk", true], ["wall_panel", false], ["cabinet", true], ["lantern", false], ["lantern", false]]],
	"dorm": ["the wash cellar", [["washstand", true], ["washstand", true], ["barrel", true], ["clothes_stand", true], ["chest", true], ["shelf", true], ["lantern", false], ["lantern", false]]],
	"kitchen": ["the larder", [["grain_bin", true], ["wine_jar", true], ["barrel", true], ["mortar", true], ["shelf", true], ["shelf", true], ["lantern", false], ["lantern", false]]],
	"alchemist": ["the still room", [["cauldron", true], ["mortar", true], ["shelf", true], ["chest", true], ["herbs", false], ["wine_jar", true], ["lantern", false], ["lantern", false]]],
	"smithy": ["the ore store", [["barrel", true], ["chest", true], ["rack", true], ["workbench", true], ["grain_bin", true], ["wall_panel", false], ["lantern", false], ["lantern", false]]],
	"seahouse": ["the salt cellar", [["barrel", true], ["barrel", true], ["wine_jar", true], ["chest", true], ["shelf", true], ["wall_panel", false], ["lantern", false], ["lantern", false]]],
	"bathhouse": ["the boiler cellar", [["hearth", true], ["barrel", true], ["washstand", true], ["shelf", true], ["chest", true], ["wall_panel", false], ["lantern", false], ["lantern", false]]],
	"hermitage": ["the hermit's store", [["chest", true], ["wine_jar", true], ["spinning_wheel", true], ["shelf", true], ["cushion", false], ["wall_panel", false], ["lantern", false], ["lantern", false]]],
	"aerie": ["the feather store", [["chest", true], ["shelf", true], ["nest", true], ["barrel", true], ["wall_panel", false], ["cabinet", true], ["lantern", false], ["lantern", false]]],
}

static func _h(x: int, y: int, s: int) -> int:
	var n := (x * 374761393) ^ (y * 668265263) ^ (s * 1274126177)
	n = (n ^ (n >> 13)) * 1103515245
	return (n ^ (n >> 16)) & 0x7fffffff

## The tiles of `free` (a set) that can be walked to from `start` without stepping on `gone`.
static func _reach(free: Dictionary, start: Vector2i, gone: Vector2i) -> Dictionary:
	var seen := {}
	if not free.has(start) or start == gone:
		return seen
	seen[start] = true
	var q: Array = [start]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if free.has(n) and n != gone and not seen.has(n):
				seen[n] = true
				q.append(n)
	return seen

## Can `gone` be filled (stairs, a chest) without cutting off anything that can be walked to from
## `start` now?  (It must itself be reachable: the stairs are no use in a corner nobody can get to.)
static func _joined(free: Dictionary, gone: Vector2i, start: Vector2i) -> bool:
	var before := _reach(free, start, Vector2i(-999, -999))
	if not before.has(gone):
		return false
	return _reach(free, start, gone).size() == before.size() - 1

## Would every piece in `pieces` (tiles that are filled, used from beside them), and `t` itself, still
## have a free tile beside it once `t` is filled too?
static func _usable(free: Dictionary, pieces: Array, t: Vector2i) -> bool:
	for p in pieces + [t]:
		var ok := false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = p + d
			if n != t and free.has(n):
				ok = true
		if not ok:
			return false
	return true

## The tiles of a room's floor that lie against its walls, round from the north-west corner.
static func _edge(r: Rect2i) -> Array:
	var out: Array = []
	var x0 := r.position.x + 1
	var x1 := r.end.x - 2
	var y0 := r.position.y + 1
	var y1 := r.end.y - 2
	for x in range(x0, x1 + 1):
		out.append(Vector2i(x, y0))
	for y in range(y0 + 1, y1 + 1):
		out.append(Vector2i(x1, y))
	for x2 in range(x1 - 1, x0 - 1, -1):
		if y1 > y0:
			out.append(Vector2i(x2, y1))
	for y2 in range(y1 - 1, y0, -1):
		if x1 > x0:
			out.append(Vector2i(x0, y2))
	return out

## The tiles of region `id` (its own tiles) that a building must not grow over or up against: wherever
## the story stands somebody or something, where travellers arrive, where a work or a ladder stands,
## the heart of a town.
static func keep_off(id: String, spec: Dictionary) -> Dictionary:
	var out := {}
	var pts: Array = []
	for key in ["npcs", "bosses", "pickups", "portals", "obstacles", "abodes", "steles"]:
		for e in spec.get(key, []):
			if e is Dictionary and e.has("pos") and not e.has("floor") and (e.pos as Vector2i) != Vector2i.ZERO:
				pts.append(e.pos)
			elif e is Vector2i:
				pts.append(e)
	for p in spec.get("portals", []):
		pts.append((p.pos as Vector2i) + Vector2i(1, 0))
	for key2 in ["springs", "clear"]:
		for q in spec.get(key2, []):
			if q is Vector2i:
				pts.append(q)
	for a in MapGen.arrival_tiles(id):
		pts.append(a)
	for le in MapGen.ladder_ends(id):
		pts.append(le[0])
		pts.append((le[0] as Vector2i) + (le[1] as Vector2i))
	for ms in Works.sites():
		if str(ms[2]) == id:
			pts.append(ms[3])
	for tid in Folk.TOWNS:
		if str(Folk.TOWNS[tid].area) == id:
			pts.append(Folk.TOWNS[tid].at)
	if spec.has("start"):
		pts.append(spec.start)
	for bd in spec.get("buildings", []):
		# (the ground outside every door)
		var r: Rect2i = bd.rect
		var d: Vector2i = bd.door
		pts.append(d + Vector2i(0, -1 if d.y == r.position.y else (1 if d.y == r.end.y - 1 else 0)) + Vector2i(-1 if d.x == r.position.x else (1 if d.x == r.end.x - 1 else 0), 0))
	for pt in pts:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				out[(pt as Vector2i) + Vector2i(dx, dy)] = true
	return out

## More room indoors (the Lost Horse release): every building of a region let out by a tile, or two,
## on each side that has ground to spare, once the region's own map is made (so that nothing on it
## moves: the packs, the people and the roads are where they were, and whose land is whose does not
## change).  A side is let out only if it is not the side the door is in; the new row of wall stands on
## open ground or where the wood was, with somewhere to walk (or wood) beyond it; nobody and nothing
## stands there or beside it (`keep_off`, and every entity of the map `ents`); the map's edge is three
## tiles away; no other building is within a tile of the new wall; and **everything that could be
## walked to before can still be walked to** (the map is flooded from `start` again for every row).
## Everything written by hand inside a building stays where it was; the floors rooms.gd lays out are
## laid out again for the larger room.  `buildings` (the stamped buildings of the map) is changed in place.
static func let_out(id: String, spec: Dictionary, grid: PackedByteArray, w: int, h: int, buildings: Array, ents: Array, start: Vector2i) -> void:
	var raw: Array = spec.get("buildings", [])
	var rounds := int(spec.get("grow", 2))
	if raw.is_empty() or rounds <= 0:
		return
	var off := keep_off(id, Data.AREAS[id] if Data.AREAS.has(id) else spec)
	for e in ents:
		if e.has("pos"):
			var er := 2 if str(e.kind) == "enemy" else 1
			for dy in range(-er, er + 1):
				for dx in range(-er, er + 1):
					off[(e.pos as Vector2i) + Vector2i(dx, dy)] = true
	var now: Array = []
	for bd in raw:
		now.append(bd.rect)
	var reach := MapGen.flood(grid, w, h, start)
	for i in raw.size():
		var bd0: Dictionary = raw[i]
		var r: Rect2i = bd0.rect
		if r.size.x < 5 or r.size.y < 4 or bool(bd0.get("fixed", false)):
			continue
		var door: Vector2i = bd0.door
		var nr := r
		for _round in rounds:
			for side in 4:
				if (side == 0 and door.x == r.position.x) or (side == 1 and door.x == r.end.x - 1) or (side == 2 and door.y == r.position.y) or (side == 3 and door.y == r.end.y - 1):
					continue
				var wall_row: Rect2i
				var beyond: Rect2i
				var cand: Rect2i
				match side:
					0:
						wall_row = Rect2i(nr.position.x - 1, nr.position.y, 1, nr.size.y)
						beyond = Rect2i(nr.position.x - 2, nr.position.y - 1, 1, nr.size.y + 2)
						cand = Rect2i(nr.position.x - 1, nr.position.y, nr.size.x + 1, nr.size.y)
					1:
						wall_row = Rect2i(nr.end.x, nr.position.y, 1, nr.size.y)
						beyond = Rect2i(nr.end.x + 1, nr.position.y - 1, 1, nr.size.y + 2)
						cand = Rect2i(nr.position.x, nr.position.y, nr.size.x + 1, nr.size.y)
					2:
						wall_row = Rect2i(nr.position.x, nr.position.y - 1, nr.size.x, 1)
						beyond = Rect2i(nr.position.x - 1, nr.position.y - 2, nr.size.x + 2, 1)
						cand = Rect2i(nr.position.x, nr.position.y - 1, nr.size.x, nr.size.y + 1)
					_:
						wall_row = Rect2i(nr.position.x, nr.end.y, nr.size.x, 1)
						beyond = Rect2i(nr.position.x - 1, nr.end.y + 1, nr.size.x + 2, 1)
						cand = Rect2i(nr.position.x, nr.position.y, nr.size.x, nr.size.y + 1)
				var both := wall_row.merge(beyond)
				if both.position.x < 3 or both.position.y < 3 or both.end.x > w - 3 or both.end.y > h - 3:
					continue
				var ok := true
				for y in range(wall_row.position.y, wall_row.end.y):
					for x in range(wall_row.position.x, wall_row.end.x):
						var t: int = grid[y * w + x]
						if (t != MapGen.FLOOR and t != MapGen.DECOR and t != MapGen.WALL) or off.has(Vector2i(x, y)):
							ok = false
				for y2 in range(beyond.position.y, beyond.end.y):
					for x2 in range(beyond.position.x, beyond.end.x):
						var t2: int = grid[y2 * w + x2]
						if t2 == MapGen.BUILDING or t2 == MapGen.INTERIOR or t2 == MapGen.WATER:
							ok = false
				for j in now.size():
					if j != i and (now[j] as Rect2i).grow(1).intersects(wall_row):
						ok = false
				if not ok:
					continue
				# try it: is everything that could be walked to still walked to?
				var g2 := grid.duplicate()
				var tb: Dictionary = bd0.duplicate(true)
				tb.rect = cand
				MapGen.stamp_building(g2, w, tb)
				var reach2 := MapGen.flood(g2, w, h, start)
				if reach2.size() < reach.size() - (cand.get_area() - nr.get_area()) - 1:
					continue
				var lost := false
				for q in reach:
					if not reach2.has(q) and not cand.has_point(q):
						lost = true
						break
				if lost:
					continue
				nr = cand
				now[i] = nr
				for k in g2.size():
					grid[k] = g2[k]
				reach = reach2
		if nr != r:
			var gb: Dictionary = bd0.duplicate(true)
			gb.rect = nr
			gb["rect0"] = r
			buildings[i] = MapGen.stamp_building(grid, w, complete(gb, busy_of(id, bd0)))

## Building `bd` (an entry of Data.AREAS[..].buildings, in its region's own tiles) with every floor it
## has: its own, and the ones laid out here.  `busy` are tiles of its ground floor that somebody or
## something of the story stands on (nothing is put there or cut off from the door).
static func complete(bd: Dictionary, busy: Array = []) -> Dictionary:
	var out: Dictionary = bd.duplicate(true)
	var r: Rect2i = bd.rect
	if r.size.x < 5 or r.size.y < 4:
		return out
	var style := str(bd.get("style", "house"))
	var seed_ := r.position.x * 131 + r.position.y * 17 + r.size.x * 7 + style.length()
	# the ground floor as it is: what is free, what is not
	var free := {}
	for y in range(r.position.y + 1, r.end.y - 1):
		for x in range(r.position.x + 1, r.end.x - 1):
			free[Vector2i(x, y)] = true
	var used := {}
	var pieces: Array = []
	for pr in bd.get("props", []):
		used[pr[1]] = true
		if pr.size() > 2 and pr[2]:
			free.erase(pr[1])
			pieces.append(pr[1])
	for bt in busy:
		used[bt] = true
		free.erase(bt)
	for st in [bd.get("up", Vector2i(-99, -99)), bd.get("down", Vector2i(-99, -99))]:
		used[st] = true
		free.erase(st)
	# the tile inside the door, and the ones beside it, stay clear
	var door: Vector2i = bd.door
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		used[door + d] = true
	for bt2 in busy:
		for d2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			used[bt2 + d2] = true
	# everything is reached from the tile inside the door
	var inside: Vector2i = door
	for d0 in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if free.has(door + d0):
			inside = door + d0
	var edge := _edge(r)
	var want_up: bool = not bd.has("upper") and not NO_UPPER.has(style) and UPPER.has(style)
	var want_down: bool = not bd.has("cellar") and CELLAR.has(style)
	for which in ["up", "down"]:
		if (which == "up" and not want_up) or (which == "down" and not want_down):
			continue
		var at := Vector2i(-1, -1)
		var o: int = _h(r.position.x, r.position.y, 3 if which == "up" else 5) % edge.size()
		for k in edge.size():
			var t: Vector2i = edge[(o + k) % edge.size()]
			if used.has(t) or not free.has(t) or not _joined(free, t, inside) or not _usable(free, pieces, t):
				continue
			at = t
			break
		if at.x < 0:
			continue
		free.erase(at)
		pieces.append(at)
		used[at] = true
		for d3 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			used[at + d3] = true
		var spec: Array = UPPER[style] if which == "up" else CELLAR[style]
		out[which] = at
		out["upper" if which == "up" else "cellar"] = {"n": spec[0], "props": _furnish_floor(r, at, spec[1], seed_ + (1 if which == "up" else 2)), "made": true}
	return out

## The furniture of a floor of rectangle `r` whose stairs come out on `stairs`: the pieces of `kinds`
## in turn, each on the next tile round the walls that leaves the rest of the floor joined (a piece
## that blocks), or on a tile out in the room (one that does not), never beside the stairs.
static func _furnish_floor(r: Rect2i, stairs: Vector2i, kinds: Array, seed_: int) -> Array:
	var free := {}
	for y in range(r.position.y + 1, r.end.y - 1):
		for x in range(r.position.x + 1, r.end.x - 1):
			free[Vector2i(x, y)] = true
	free.erase(stairs)
	var used := {stairs: true}
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		used[stairs + d] = true
	var edge := _edge(r)
	var inner: Array = []
	for t0 in free:
		if not edge.has(t0):
			inner.append(t0)
	inner.sort()
	# everything on the floor is reached from beside the stairs
	var from := stairs
	for d1 in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if free.has(stairs + d1):
			from = stairs + d1
	var props: Array = []
	var pieces: Array = [stairs]
	var area := (r.size.x - 2) * (r.size.y - 2)
	var most := clampi(area / 3, 3, kinds.size())
	var e0 := _h(seed_, r.size.x, 11) % edge.size()
	var step := 2 if edge.size() >= 12 else 1
	var ei := 0
	for kd in kinds:
		if props.size() >= most:
			break
		var blocks: bool = kd[1]
		var placed := false
		if blocks or inner.is_empty() or str(kd[0]) in ["scroll", "window", "wall_panel", "lantern"]:
			# against a wall
			var tries := 0
			while tries < edge.size() and not placed:
				var t: Vector2i = edge[(e0 + ei) % edge.size()]
				ei += step if tries == 0 else 1
				tries += 1
				if used.has(t) or not free.has(t):
					continue
				if blocks and (t == from or not _joined(free, t, from) or not _usable(free, pieces, t)):
					continue
				props.append([str(kd[0]), t, blocks])
				used[t] = true
				if blocks:
					free.erase(t)
					pieces.append(t)
				placed = true
		else:
			for t2 in inner:
				if not used.has(t2):
					props.append([str(kd[0]), t2, false])
					used[t2] = true
					break
	return props

## How many tiles of floor the buildings of the world have to walk on: [as written by hand, with the
## floors laid out here] (for the tests and the README).
static func floor_tiles() -> Array:
	var before := 0
	var after := 0
	for a in Data.AREAS:
		for bd in Data.AREAS[a].get("buildings", []):
			var r: Rect2i = bd.rect
			var per := (r.size.x - 2) * (r.size.y - 2)
			var full := complete(bd, busy_of(a, bd))
			before += per * (1 + (1 if bd.has("upper") else 0) + (1 if bd.has("cellar") else 0))
			after += per * (1 + (1 if full.has("upper") else 0) + (1 if full.has("cellar") else 0))
	return [before, after]

## The tiles of the ground floor of building `bd` of region `area` that the story stands somebody or
## something on (people, lords, things to find).
static func busy_of(area: String, bd: Dictionary) -> Array:
	var out: Array = []
	var r: Rect2i = bd.rect
	var spec: Dictionary = Data.AREAS[area]
	for key in ["npcs", "bosses", "pickups", "obstacles", "steles", "abodes"]:
		for e in spec.get(key, []):
			if e is Vector2i:
				if r.has_point(e):
					out.append(e)
			elif not e.has("floor") and not e.has("cave") and r.has_point(e.pos):
				out.append(e.pos)
	for sp in spec.get("springs", []):
		if r.has_point(sp):
			out.append(sp)
	return out

# ---------------------------------------------------------------- the new furniture, drawn

## Draw furniture `kind` (one of the twelve new kinds) at tile centre `p`; `wallp` is the point on the
## nearest wall, `back` the direction to it and `side` along it.  False if the kind is not one of them.
static func furnish(b: MB, g: MB, kind: String, p: Vector3, wallp: Vector3, back: Vector3, side: Vector3, rng: RandomNumberGenerator, lights: Array) -> bool:
	var wood := MB.tag(Color("7a4a2e"), MB.WOOD)
	var wood_l := MB.tag(Color("a87a4a"), MB.WOOD)
	var wood_d := MB.tag(Color("4a2e1e"), MB.WOOD)
	var lacquer := MB.tag(Color("8a2a22"), MB.WOOD)
	var bronze := MB.tag(Color("9a8444"), MB.METAL)
	var iron := MB.tag(Color("44444c"), MB.METAL)
	var clay := MB.tag(Color("9a5a3a"), MB.STONE)
	var stone := MB.tag(Color("8a8680"), MB.STONE)
	var cloth := MB.tag(Color("c8b8a0"), MB.CLOTH)
	var ax := absf(back.x) > 0.5
	var yaw := atan2(-back.x, -back.z)
	match kind:
		"chest":
			# an iron-bound camphor chest against the wall, its lid a shallow barrel
			var c := wallp - back * 0.5
			b.box(c + Vector3(0, 0.3, 0), Vector3(0.62, 0.56, 1.1) if ax else Vector3(1.1, 0.56, 0.62), wood)
			b.cyl(c + Vector3(0, 0.58, 0), 0.31, 1.1, wood_l, Vector3(PI * 0.5, 0, 0) if ax else Vector3(0, 0, PI * 0.5), 10)
			for s: float in [-0.4, 0.0, 0.4]:
				b.box(c + side * s + Vector3(0, 0.34, 0), Vector3(0.66, 0.66, 0.06) if ax else Vector3(0.06, 0.66, 0.66), iron)
			b.box(c - back * 0.33 + Vector3(0, 0.48, 0), Vector3(0.05, 0.14, 0.12) if ax else Vector3(0.12, 0.14, 0.05), bronze)
		"mirror":
			# a round bronze mirror on a lacquer stand, on a low dressing table with a comb and a box
			var c2 := wallp - back * 0.45
			b.box(c2 + Vector3(0, 0.52, 0), Vector3(0.5, 0.06, 1.0) if ax else Vector3(1.0, 0.06, 0.5), lacquer)
			for s2: float in [-1.0, 1.0]:
				b.box(c2 + side * s2 * 0.42 + Vector3(0, 0.26, 0), Vector3(0.4, 0.5, 0.06) if ax else Vector3(0.06, 0.5, 0.4), lacquer)
			b.box(c2 + back * 0.1 + Vector3(0, 0.75, 0), Vector3(0.06, 0.4, 0.3) if ax else Vector3(0.3, 0.4, 0.06), wood_d)
			b.cyl(c2 + back * 0.06 + Vector3(0, 1.08, 0), 0.24, 0.03, bronze, Vector3(0, 0, PI * 0.5) if ax else Vector3(PI * 0.5, 0, 0), 16)
			g.disc(c2 + back * 0.035 + Vector3(0, 1.08, 0), 0.2, Color(0.9, 0.95, 1.0, 0.35), 14, Color(0.9, 0.95, 1.0, 0.1), Vector3(0, 0, -PI * 0.5 * signf(back.x)) if ax else Vector3(-PI * 0.5 * signf(back.z), 0, 0))
			b.box(c2 - side * 0.3 + Vector3(0, 0.6, 0), Vector3(0.14, 0.08, 0.2), MB.tag(Color("3a5a4a"), MB.STONE))
			b.box(c2 + side * 0.28 - back * 0.08 + Vector3(0, 0.565, 0), Vector3(0.05, 0.015, 0.16) if not ax else Vector3(0.16, 0.015, 0.05), wood_l)
		"mortar":
			# a stone mortar as high as the knee, its pestle standing in it
			b.lathe(p, [Vector2(0.3, 0.0), Vector2(0.36, 0.12), Vector2(0.4, 0.5), Vector2(0.34, 0.55), Vector2(0.24, 0.3)], stone, 12)
			b.limb(p + Vector3(0.05, 0.3, 0.02), p + Vector3(0.2, 1.15, 0.1), 0.06, 0.04, wood_l, 6)
			b.sph(p + Vector3(0.04, 0.32, 0.02), Vector3(0.09, 0.08, 0.09), wood_l)
			b.sph(p + Vector3(0, 0.33, 0), Vector3(0.22, 0.04, 0.22), MB.tag(Color("6a8a4a"), MB.CLOTH))
		"spinning_wheel":
			# a great wheel on a bench, the spindle at the far end, a hank of raw thread, and a stool
			var c3 := p + back * 0.25
			b.box(c3 + Vector3(0, 0.34, 0), Vector3(0.22, 0.08, 1.3) if not ax else Vector3(1.3, 0.08, 0.22), wood)
			for s3: float in [-1.0, 1.0]:
				b.box(c3 + side * s3 * 0.55 + Vector3(0, 0.17, 0), Vector3(0.3, 0.34, 0.08) if not ax else Vector3(0.08, 0.34, 0.3), wood)
			var hub := c3 + side * 0.3 + Vector3(0, 0.9, 0)
			b.box(c3 + side * 0.3 + Vector3(0, 0.62, 0), Vector3(0.08, 0.56, 0.08), wood)
			b.torus(hub, 0.42, 0.03, wood_l, Vector3(PI * 0.5, 0, 0) if ax else Vector3(0, 0, PI * 0.5) + Vector3(PI * 0.5, 0, 0), true)
			for k in 4:
				var a := PI * k / 4.0
				var sp := side * cos(a) * 0.42 + Vector3(0, sin(a) * 0.42, 0)
				b.limb(hub - sp, hub + sp, 0.015, 0.015, wood_l, 4)
			b.box(c3 - side * 0.5 + Vector3(0, 0.52, 0), Vector3(0.06, 0.3, 0.06), wood)
			b.limb(c3 - side * 0.5 + Vector3(0, 0.66, 0) - back * 0.12, c3 - side * 0.5 + Vector3(0, 0.66, 0) + back * 0.12, 0.012, 0.004, iron, 4)
			b.sph(c3 - side * 0.5 + Vector3(0, 0.66, 0), Vector3(0.05, 0.05, 0.05), MB.tag(Color("f0ead8"), MB.CLOTH))
			b.sph(c3 - side * 0.15 + Vector3(0, 0.44, 0), Vector3(0.14, 0.08, 0.14), MB.tag(Color("f0ead8"), MB.HAIR))
			b.cyl(p - back * 0.55 + Vector3(0, 0.2, 0), 0.2, 0.4, wood_l, Vector3.ZERO, 10)
		"abacus":
			# a counting desk with an abacus on it, a ledger and an ink stone
			var c4 := wallp - back * 0.5
			b.box(c4 + Vector3(0, 0.82, 0), Vector3(0.6, 0.06, 1.3) if ax else Vector3(1.3, 0.06, 0.6), wood)
			for s4: float in [-1.0, 1.0]:
				b.box(c4 + side * s4 * 0.58 + Vector3(0, 0.4, 0), Vector3(0.54, 0.8, 0.06) if ax else Vector3(0.06, 0.8, 0.54), wood)
			var ab := c4 - back * 0.08 + Vector3(0, 0.88, 0)
			b.box(ab, Vector3(0.26, 0.04, 0.6) if ax else Vector3(0.6, 0.04, 0.26), wood_d)
			for k2 in 7:
				var o := -0.24 + k2 * 0.08
				for k3 in 3:
					b.sph(ab + side * o + back * (-0.07 + k3 * 0.06) + Vector3(0, 0.035, 0), Vector3(0.03, 0.024, 0.03), lacquer if k3 > 0 else wood_l)
			b.box(c4 + side * 0.42 + Vector3(0, 0.87, 0), Vector3(0.22, 0.04, 0.3), MB.tag(Color("efe6d0"), MB.CLOTH))
			b.box(c4 - side * 0.45 + back * 0.1 + Vector3(0, 0.87, 0), Vector3(0.12, 0.04, 0.16), MB.tag(Color("1e1e22"), MB.STONE))
		"cradle":
			# a rocking cradle with a quilt in it, and a little tiger-head cap on its rail
			for s5: float in [-1.0, 1.0]:
				b.torus(p + side * s5 * 0.4 + Vector3(0, 0.34, 0), 0.34, 0.035, wood_l, Vector3(0, yaw + PI * 0.5, 0) + Vector3(0, 0, 0))
				b.box(p + side * s5 * 0.4 + Vector3(0, 0.5, 0), Vector3(0.05, 0.4, 0.62) if ax else Vector3(0.62, 0.4, 0.05), wood)
			for s6: float in [-1.0, 1.0]:
				b.box(p + back * s6 * 0.3 + Vector3(0, 0.5, 0), Vector3(0.05, 0.36, 0.8) if not ax else Vector3(0.8, 0.36, 0.05), wood)
			b.box(p + Vector3(0, 0.34, 0), Vector3(0.6, 0.05, 0.8) if not ax else Vector3(0.8, 0.05, 0.6), wood)
			b.sph(p + Vector3(0, 0.46, 0), Vector3(0.26, 0.12, 0.34) if not ax else Vector3(0.34, 0.12, 0.26), MB.tag(Color("c84a3a"), MB.CLOTH))
			b.sph(p + side * 0.25 + Vector3(0, 0.56, 0), Vector3(0.09, 0.08, 0.09), MB.tag(Color("e8b040"), MB.CLOTH))
		"wine_jar":
			# a sealed jar as high as the waist, red paper on its lid, and a dipper hung on its neck
			b.lathe(p, [Vector2(0.2, 0.0), Vector2(0.4, 0.3), Vector2(0.42, 0.62), Vector2(0.26, 0.9), Vector2(0.22, 1.0), Vector2(0.27, 1.04)], clay, 14)
			b.cyl(p + Vector3(0, 1.07, 0), 0.26, 0.06, MB.tag(Color("b83020"), MB.CLOTH), Vector3.ZERO, 12)
			b.box(p + Vector3(0, 0.62, 0.42), Vector3(0.22, 0.22, 0.01), MB.tag(Color("b83020"), MB.CLOTH))
			b.limb(p + Vector3(0.28, 0.95, 0), p + Vector3(0.34, 0.6, 0), 0.012, 0.012, wood_l, 4)
			b.sph(p + Vector3(0.36, 0.56, 0), Vector3(0.06, 0.05, 0.06), wood_l)
		"clothes_stand":
			# a lacquer stand with a robe over its bar, and a hat on one horn
			var c5 := wallp - back * 0.4
			for s7: float in [-1.0, 1.0]:
				b.box(c5 + side * s7 * 0.6 + Vector3(0, 0.85, 0), Vector3(0.06, 1.7, 0.06), lacquer)
				b.box(c5 + side * s7 * 0.6 + Vector3(0, 0.04, 0), Vector3(0.4, 0.08, 0.1) if ax else Vector3(0.1, 0.08, 0.4), lacquer)
				b.sph(c5 + side * s7 * 0.6 + Vector3(0, 1.72, 0), Vector3(0.06, 0.06, 0.06), bronze)
			b.limb(c5 - side * 0.7 + Vector3(0, 1.55, 0), c5 + side * 0.7 + Vector3(0, 1.55, 0), 0.03, 0.03, lacquer, 6)
			b.limb(c5 - side * 0.6 + Vector3(0, 0.5, 0), c5 + side * 0.6 + Vector3(0, 0.5, 0), 0.025, 0.025, lacquer, 6)
			var robe := MB.tag(Color("3a6a9a").lerp(Color("9a3a4a"), rng.randf()), MB.CLOTH)
			b.box(c5 + Vector3(0, 1.1, 0) - back * 0.05, Vector3(0.05, 0.92, 0.9) if ax else Vector3(0.9, 0.92, 0.05), robe)
			b.box(c5 + Vector3(0, 1.1, 0) + back * 0.05, Vector3(0.05, 0.7, 0.9) if ax else Vector3(0.9, 0.7, 0.05), robe)
			b.cone(c5 + side * 0.6 + Vector3(0, 1.84, 0), 0.26, 0.16, MB.tag(Color("c8b070"), MB.HAIR), Vector3.ZERO, 10)
		"washstand":
			# a basin on a tall stand, a towel on its rail, a ewer beside it
			for k4 in 3:
				var a2 := TAU * k4 / 3.0
				b.limb(p + Vector3(cos(a2) * 0.3, 0.0, sin(a2) * 0.3), p + Vector3(cos(a2) * 0.2, 0.8, sin(a2) * 0.2), 0.03, 0.03, wood, 5)
			b.lathe(p + Vector3(0, 0.78, 0), [Vector2(0.18, 0.0), Vector2(0.34, 0.14), Vector2(0.36, 0.17), Vector2(0.3, 0.12)], bronze, 14)
			g.disc(p + Vector3(0, 0.9, 0), 0.29, Color(0.5, 0.75, 0.9, 0.45), 14)
			b.limb(p + back * 0.3 + Vector3(0, 0.8, 0), p + back * 0.3 + Vector3(0, 1.4, 0), 0.025, 0.025, wood, 5)
			b.limb(p + back * 0.3 - side * 0.3 + Vector3(0, 1.4, 0), p + back * 0.3 + side * 0.3 + Vector3(0, 1.4, 0), 0.02, 0.02, wood, 5)
			b.box(p + back * 0.3 + Vector3(0, 1.2, 0), Vector3(0.03, 0.4, 0.4) if ax else Vector3(0.4, 0.4, 0.03), cloth)
			b.lathe(p + side * 0.55 - back * 0.1, [Vector2(0.1, 0.0), Vector2(0.15, 0.2), Vector2(0.07, 0.36), Vector2(0.09, 0.42)], clay, 10)
		"workbench":
			# a carver's bench: a thick plank on trestles, a half-carved figure in a vice, chisels, shavings
			var c6 := wallp - back * 0.5
			b.box(c6 + Vector3(0, 0.8, 0), Vector3(0.62, 0.1, 1.5) if ax else Vector3(1.5, 0.1, 0.62), wood_l)
			for s8: float in [-1.0, 1.0]:
				b.box(c6 + side * s8 * 0.6 + Vector3(0, 0.38, 0), Vector3(0.5, 0.76, 0.1) if ax else Vector3(0.1, 0.76, 0.5), wood)
			b.box(c6 + side * 0.4 + Vector3(0, 0.93, 0), Vector3(0.16, 0.16, 0.16), iron)
			b.lathe(c6 + side * 0.4 + Vector3(0, 0.98, 0), [Vector2(0.06, 0.0), Vector2(0.08, 0.12), Vector2(0.05, 0.24), Vector2(0.07, 0.3), Vector2(0.0, 0.36)], MB.tag(Color("d8b888"), MB.WOOD), 8)
			for k5 in 3:
				b.limb(c6 - side * (0.1 + k5 * 0.14) + back * 0.1 + Vector3(0, 0.86, 0), c6 - side * (0.1 + k5 * 0.14) - back * 0.12 + Vector3(0, 0.86, 0), 0.016, 0.008, iron if k5 % 2 == 0 else wood_d, 4)
			for k6 in 7:
				b.sph(c6 + side * rng.randf_range(-0.6, 0.6) - back * rng.randf_range(0.4, 0.75) + Vector3(0, 0.02, 0), Vector3(0.05, 0.015, 0.03), MB.tag(Color("e0c898"), MB.WOOD))
		"wall_panel":
			# a panel of the wainscot that sounds different from the rest: a frame, a knot-hole, a scuff
			var c7 := wallp + Vector3(0, 0.9, 0) - back * 0.06
			b.box(c7, Vector3(0.05, 1.1, 0.9) if ax else Vector3(0.9, 1.1, 0.05), wood_l)
			for s9: float in [-1.0, 1.0]:
				b.box(c7 + side * s9 * 0.45, Vector3(0.07, 1.16, 0.06) if ax else Vector3(0.06, 1.16, 0.07), wood_d)
				b.box(c7 + Vector3(0, s9 * 0.55, 0), Vector3(0.07, 0.06, 0.96) if ax else Vector3(0.96, 0.06, 0.07), wood_d)
			b.sph(c7 + side * 0.18 + Vector3(0, 0.2, 0) - back * 0.02, Vector3(0.04, 0.04, 0.04), wood_d)
		"grain_bin":
			# a round bin of woven bamboo plastered with clay, a wooden lid half off and grain to the brim
			b.lathe(p, [Vector2(0.5, 0.0), Vector2(0.55, 0.5), Vector2(0.5, 0.95), Vector2(0.46, 0.98)], MB.tag(Color("b89a68"), MB.HAIR), 14)
			b.cyl(p + Vector3(0, 0.3, 0), 0.56, 0.05, wood, Vector3.ZERO, 14)
			b.cyl(p + Vector3(0, 0.7, 0), 0.54, 0.05, wood, Vector3.ZERO, 14)
			b.sph(p + Vector3(0, 0.93, 0), Vector3(0.44, 0.1, 0.44), MB.tag(Color("d8c070"), MB.CLOTH))
			b.cyl(p + Vector3(0.22, 1.02, 0.1), 0.5, 0.04, wood_l, Vector3(0.25, 0, 0.12), 14)
		"window":
			# a lattice window in the wall with the daylight behind it, and a sill to lean on
			var c8 := wallp + Vector3(0, 1.45, 0) - back * 0.04
			g.box(c8, Vector3(0.02, 1.0, 1.2) if ax else Vector3(1.2, 1.0, 0.02), Color(1.0, 0.95, 0.75, 0.55))
			for k7 in 5:
				b.box(c8 + side * (-0.5 + k7 * 0.25) - back * 0.02, Vector3(0.04, 1.0, 0.035) if ax else Vector3(0.035, 1.0, 0.04), wood_d)
			for k8 in 4:
				b.box(c8 + Vector3(0, -0.375 + k8 * 0.25, 0) - back * 0.02, Vector3(0.04, 0.035, 1.2) if ax else Vector3(1.2, 0.035, 0.04), wood_d)
			for s10: float in [-1.0, 1.0]:
				b.box(c8 + side * s10 * 0.63 - back * 0.03, Vector3(0.07, 1.12, 0.07), wood)
				b.box(c8 + Vector3(0, s10 * 0.53, 0) - back * 0.03, Vector3(0.07, 0.07, 1.32) if ax else Vector3(1.32, 0.07, 0.07), wood)
			b.box(c8 + Vector3(0, -0.6, 0) - back * 0.12, Vector3(0.26, 0.05, 1.36) if ax else Vector3(1.36, 0.05, 0.26), wood_l)
			lights.append([c8 - back * 0.6, Color(1.0, 0.92, 0.75)])
		_:
			return false
	return true
