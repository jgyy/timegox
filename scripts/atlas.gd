class_name Atlas
extends RefCounted
## The open world: the Unbroken Land, one continent within the Four Seas.
##
## Azure Cloud Mountain rises in the middle of the land with the sect on its slope, and each
## chapter's chain of regions winds outward from it as a province of its own.  Nothing is laid out
## on a grid any more (the old Heavenly Court surveyed the land into square provinces; Part X is
## the story of the land relaxing out of them):
##
## - every region has a site and a way (the direction its road runs through it), and its own map
##   is turned to face that way;
## - each tile belongs to the region whose site is nearest, measured in that region's own
##   half-sizes (so long regions own long land) under a two-scale domain warp, so borders wander
##   like coasts and ridges; the land round everything that matters in a region always belongs to
##   it;
## - land runs out about two half-sizes from every site: past that is the sea, so the coast curves
##   round bays, capes and inland seas;
## - a region's open ground is an ellipse warped into lobes and bays (MapGen._outline), not the
##   rectangle of its map; between regions lies a belt of forest and rock;
## - roads are searched for (A*) across the land, preferring open ground and old paths and paying
##   for forest and water, so they wind; each crosses its border once, where a Lotus Seal closes
##   it until the story opens the way.
##
## The world is built once and cached (`Atlas.world()`); it is fully deterministic.

const HUB := "mountain"
const W_WORLD := 1040
const H_WORLD := 900
const WARP := 6.0          # how far borders wander at the small scale (tiles)
const WARP_BIG := 22.0     # ... and at the large scale, so borders meander like coasts and ridges
const LAND := 1.95         # the coast lies about this many half-sizes out from the nearest site
const LAND_HUB := 1.45     # ... and closer round the broad mountain
const BAND_MIN := 1.6      # half-width of the forest belt between regions varies between these
const BAND_MAX := 3.6
const BLK := 16            # block size for the nearest-site search

## Where every region lies: [x, y, way], its centre tile and the way its road runs through it
## (0 east, 1 south, 2 west, 3 north).  Each chapter winds outward from the mountain: Part I east
## and north up the east coast, Part II west along the north coast, Part IX east to the sunrise,
## Part V south-east, Part III south, Part VIII south-south-west, Part VII south-west, Part VI
## west, Part IV west and north up into the sky, Part X north and west to Mount Buzhou.
const SITES := {
	"mountain": [520, 460, 0],
	"bamboo": [680, 430, 0], "marsh": [770, 370, 3], "frost": [790, 265, 3], "thunder": [750, 165, 3], "palace": [660, 95, 2],
	"dragon": [545, 80, 2], "volcano": [430, 95, 2], "void": [320, 80, 2], "celestial": [200, 70, 2],
	"mirror": [535, 655, 1], "grave": [585, 770, 1], "time": [690, 800, 0], "origin": [800, 810, 0],
	"cloudsea": [330, 390, 2], "court": [225, 350, 3], "forge": [200, 255, 2], "garden": [95, 260, 3],
	"dunes": [635, 640, 1], "fungal": [720, 680, 0], "aurora": [825, 640, 0], "chaos": [910, 715, 1],
	"maple": [320, 490, 2], "karst": [215, 530, 2], "springs": [115, 495, 3], "wheel": [100, 390, 3],
	"village": [345, 590, 2], "terraces": [300, 700, 1], "silk": [190, 720, 2], "loom": [110, 630, 3],
	"starferry": [440, 650, 1], "magpie": [460, 770, 1], "starpalace": [380, 840, 2], "jasper": [270, 830, 2],
	"yanggu": [705, 530, 0], "millet": [825, 495, 0], "fusang": [920, 405, 3], "guanghan": [925, 280, 3],
	"longmen": [525, 300, 3], "drowned": [420, 245, 2], "tushan": [320, 215, 3], "buzhou": [215, 170, 2],
}
## the sect sits a little north of the mountain's middle, its south gates facing the lower slopes
const SECT_OFFSET := Vector2i(0, -6)

## The realms above and below the Unbroken Land (Part XI).  Each is a world of its own, built the way
## the land is (sites and ways, warped ownership, land that runs out into open sky or the abyss, roads
## and seals) on a grid of its own.  `y` is how high it is drawn above the land (metres); its grid is
## laid over the land's so that the crown of the Jianmu in the Nine Heavens floats straight above its
## trunk on the mountain, and its roots in the Nine Springs hang straight below it (layer_origin).
## `land` is how far land reaches from a site (in half-sizes, like LAND); `holes` opens chasms of sky
## or abyss in the wild ground between regions; `start` is where every road of the realm must reach.
const STRATA := {
	"heaven": {"n": "The Nine Heavens", "w": 260, "h": 200, "y": 96.0, "land": 1.3, "holes": 168, "start": ["juntian", Vector2i(13, 32)],
		"sites": {"juntian": [90, 100, 0], "changhe": [192, 86, 0]}},
	"under": {"n": "The Nine Springs", "w": 260, "h": 200, "y": -64.0, "land": 1.45, "holes": 184, "start": ["ninesprings", Vector2i(12, 30)],
		"sites": {"ninesprings": [90, 100, 0], "youdu": [194, 112, 0]}},
	# Part XII: the Isles of the Eastern Sea, out past the edge of the shelf east of Fusang, at sea level:
	# four isles in a chain running east to the Returning Ruins, the sea between them (the roads cross it
	# on the sandbars the drain has left bare)
	"sea": {"n": "The Eastern Sea", "w": 520, "h": 200, "y": 0.0, "land": 1.22, "holes": 174, "start": ["penglai", Vector2i(13, 32)],
		"sites": {"penglai": [80, 100, 0], "fangzhang": [196, 80, 0], "yingzhou": [312, 116, 0], "guixu": [430, 96, 0]}},
}
const LAYER_NAMES := {"surface": "The Unbroken Land", "heaven": "The Nine Heavens", "under": "The Nine Springs", "sea": "The Eastern Sea"}

static var _layout := {}
static var _world := {}
static var _worlds := {}

# ---------------------------------------------------------------- layout (cheap, no map generation)
## id -> {origin, size (as laid in the world), local (the map's own size), rot, site, cell}; plus
## "_W", "_H".  `cell` starts as the region's footprint and becomes the bounding box of the land it
## owns once the world is built.
static func layout() -> Dictionary:
	if not _layout.is_empty():
		return _layout
	var L := {}
	for id in SITES:
		if not Data.AREAS.has(id):
			continue
		var s: Array = SITES[id]
		var rot: int = s[2]
		var loc := Vector2i(Data.AREAS[id].w, Data.AREAS[id].h)
		var size := loc if rot % 2 == 0 else Vector2i(loc.y, loc.x)
		var site := Vector2i(s[0], s[1])
		var origin := site - size / 2
		L[id] = {"origin": origin, "size": size, "local": loc, "rot": rot, "site": site, "cell": Rect2i(origin, size)}
	for lid in STRATA:
		var sites: Dictionary = STRATA[lid].sites
		for id2 in sites:
			if not Data.AREAS.has(id2):
				continue
			var s2: Array = sites[id2]
			var rot2: int = s2[2]
			var loc2 := Vector2i(Data.AREAS[id2].w, Data.AREAS[id2].h)
			var size2 := loc2 if rot2 % 2 == 0 else Vector2i(loc2.y, loc2.x)
			var site2 := Vector2i(s2[0], s2[1])
			var origin2 := site2 - size2 / 2
			L[id2] = {"origin": origin2, "size": size2, "local": loc2, "rot": rot2, "site": site2, "cell": Rect2i(origin2, size2), "layer": lid}
	var ss := Vector2i(Data.AREAS.sect.w, Data.AREAS.sect.h)
	var so: Vector2i = L[HUB].site - ss / 2 + SECT_OFFSET
	L["sect"] = {"origin": so, "size": ss, "local": ss, "rot": 0, "site": so + ss / 2, "cell": Rect2i(so, ss)}
	L["_W"] = W_WORLD
	L["_H"] = H_WORLD
	_layout = L
	return L

## The regions of a realm, in a fixed order ("surface": the mountain, the sect and the land's own).
static func region_ids(layer: String = "surface") -> Array:
	if layer != "surface":
		var lo: Array = []
		if STRATA.has(layer):
			for id2 in STRATA[layer].sites:
				if Data.AREAS.has(id2):
					lo.append(id2)
		return lo
	var out: Array = [HUB, "sect"]
	for id in SITES:
		if id != HUB and Data.AREAS.has(id):
			out.append(id)
	return out

## Every region of every realm.
static func all_region_ids() -> Array:
	var out := region_ids("surface")
	for lid in STRATA:
		out.append_array(region_ids(lid))
	return out

static func layer_of(id: String) -> String:
	return Data.layer_of(id)

## The grid size of a realm.
static func layer_size(layer: String) -> Vector2i:
	if STRATA.has(layer):
		return Vector2i(int(STRATA[layer].w), int(STRATA[layer].h))
	return Vector2i(W_WORLD, H_WORLD)

## How high a realm is drawn above the land (metres).
static func layer_y(layer: String) -> float:
	return float(STRATA[layer].y) if STRATA.has(layer) else 0.0

## Where a realm's grid lies over the land's (tiles): the end of the Jianmu's ladder in the realm sits
## straight above (or below) its end on the mountain.
static func layer_origin(layer: String) -> Vector2i:
	if not STRATA.has(layer):
		return Vector2i.ZERO
	for ld in Data.LADDERS:
		for e in [["a", "b"], ["b", "a"]]:
			var here: Array = ld[e[0]]
			var there: Array = ld[e[1]]
			if Data.layer_of(here[0]) == "surface" and Data.layer_of(there[0]) == layer:
				return to_world(here[0], here[1]) - to_world(there[0], there[1])
	return Vector2i.ZERO

## Floors of buildings (upper storeys and cellars) are small realms of their own: "f:<area>:<building>:<level>".
static func floor_id(area: String, bid: String, level: int) -> String:
	return "f:%s:%s:%d" % [area, bid, level]

## local tile of region `id` (as written in Data.AREAS) -> world tile
static func to_world(id: String, p: Vector2i) -> Vector2i:
	var r: Dictionary = layout()[id]
	return r.origin + _turn(p, r.local, int(r.rot))

## world tile -> local tile of region `id`
static func to_local(id: String, q: Vector2i) -> Vector2i:
	var r: Dictionary = layout()[id]
	var d: Vector2i = q - r.origin
	var lw: int = r.local.x
	var lh: int = r.local.y
	match int(r.rot):
		1:
			return Vector2i(d.y, lh - 1 - d.x)
		2:
			return Vector2i(lw - 1 - d.x, lh - 1 - d.y)
		3:
			return Vector2i(lw - 1 - d.y, d.x)
	return d

static func _turn(p: Vector2i, loc: Vector2i, rot: int) -> Vector2i:
	match rot:
		1:
			return Vector2i(loc.y - 1 - p.y, p.x)
		2:
			return Vector2i(loc.x - 1 - p.x, loc.y - 1 - p.y)
		3:
			return Vector2i(p.y, loc.x - 1 - p.x)
	return p

## a direction in region `id`'s own map -> the same direction in the world
static func dir_to_world(id: String, d: Vector2i) -> Vector2i:
	match int(layout()[id].rot):
		1:
			return Vector2i(-d.y, d.x)
		2:
			return -d
		3:
			return Vector2i(d.y, -d.x)
	return d

## a rectangle of region `id`'s own map -> the rectangle it covers in the world
static func rect_to_world(id: String, r: Rect2i) -> Rect2i:
	var a := to_world(id, r.position)
	var b := to_world(id, r.end - Vector2i.ONE)
	var lo := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var hi := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
	return Rect2i(lo, hi - lo + Vector2i.ONE)

# ---------------------------------------------------------------- world build
static func world() -> Dictionary:
	if _world.is_empty():
		if _warm != null:
			# (it is being generated in the background, `warm`: wait for that rather than start again)
			_world = _warm.wait_to_finish()
			_warm = null
		else:
			_world = _build()
		_worlds["surface"] = _world
	return _world

## Start generating the land in the background (it takes several seconds, and nothing but the layout
## is read from anywhere else while it runs), so that it is ready, or nearly, by the time the title
## screen and the making of the hero are done.  The game with a window calls this as it starts; the
## bot, the tests and the tour do not, and generate it where they first ask for it, as before.  The
## result is the same either way: the generator draws on nothing but the data and its own seeds.
static var _warm: Thread = null

static func warm() -> void:
	if not _world.is_empty() or _warm != null:
		return
	layout()
	_warm = Thread.new()
	_warm.start(func() -> Dictionary: return _build())

## The background generation, if it is still running, is waited for (the game is closing: a thread
## must not be left behind).
static func settle() -> void:
	if _warm != null:
		_world = _warm.wait_to_finish()
		_worlds["surface"] = _world
		_warm = null

## The world of a realm ("surface", "heaven", "under") or of a building's floor ("f:..."), built once.
static func world_of(layer: String) -> Dictionary:
	if layer == "surface":
		return world()
	if layer.begins_with("f:"):
		var parts := layer.split(":")
		var parent := world_of(Data.layer_of(parts[1]))
		return parent.floors.get(layer, {})
	if not _worlds.has(layer):
		_worlds[layer] = _build(layer)
	return _worlds[layer]

## A noise field over the whole world as bytes (0..255 for -1..1), generated natively: per-tile
## FastNoiseLite calls from GDScript would dominate the build time on a world this size.
static func _field(seed_: int, freq: float, octaves: int, W: int, H: int) -> PackedByteArray:
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = freq
	n.fractal_octaves = octaves
	return n.get_image(W, H, false, false, false).get_data()

static func _build(layer: String = "surface") -> Dictionary:
	var L := layout()
	var surf := layer == "surface"
	var lsz := layer_size(layer)
	var W: int = lsz.x
	var H: int = lsz.y
	var N := W * H
	var ids := region_ids(layer)
	var idx := {}
	for i in ids.size():
		idx[ids[i]] = i
	var maps := {}
	for id in ids:
		maps[id] = MapGen.build(id)
	# (the realms above and below have no sect: an empty rectangle contains nothing)
	var sect_r: Rect2i = L.sect.cell if surf else Rect2i(-9999, -9999, 0, 0)
	var land_far: float = LAND if surf else float(STRATA[layer].land)
	# ---- pins: the land round everything that matters in a region belongs to that region, however
	# far the border wanders (its look, its name on the screen, its kills)
	var pin := PackedInt32Array()
	pin.resize(N)
	pin.fill(-1)
	for id in ids:
		if id == "sect":
			continue
		for sp in _spots(id, maps[id]):
			var c: Vector2i = to_world(id, sp[0])
			var r: int = sp[1]
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if dx * dx + dy * dy > r * r + 1:
						continue
					var q := c + Vector2i(dx, dy)
					if q.x >= 0 and q.y >= 0 and q.x < W and q.y < H and pin[q.y * W + q.x] < 0:
						pin[q.y * W + q.x] = idx[id]
		for bd in maps[id].buildings:
			# (by the rectangle the building was written with, not the one it was let out to, rooms.gd `grown`:
			# whose land is whose does not move because a house has more room in it)
			var br := rect_to_world(id, (bd.get("rect0", bd.rect) as Rect2i).grow(2))
			for yy in range(br.position.y, br.end.y):
				for xx in range(br.position.x, br.end.x):
					if xx >= 0 and yy >= 0 and xx < W and yy < H:
						pin[yy * W + xx] = idx[id]
	# ---- ownership: the nearest site, measured in each region's own half-sizes, under a warp
	var sid := PackedInt32Array()
	var sx := PackedFloat32Array()
	var sy := PackedFloat32Array()
	var shx := PackedFloat32Array()
	var shy := PackedFloat32Array()
	for id in ids:
		if id == "sect":
			continue
		var rr: Dictionary = L[id]
		sid.append(idx[id])
		sx.append(rr.site.x + 0.5)
		sy.append(rr.site.y + 0.5)
		shx.append(rr.size.x * 0.5)
		shy.append(rr.size.y * 0.5)
	var ns := sid.size()
	var fx := _field(4242, 0.06, 1, W, H)
	var fy := _field(9191, 0.06, 1, W, H)
	var gx := _field(1717, 0.012, 2, W, H)
	var gy := _field(2828, 0.012, 2, W, H)
	var coast := _field(3131, 0.02, 3, W, H)
	# candidate sites per block: only sites that could be nearest somewhere in the block
	var bw := (W + BLK - 1) / BLK
	var bh := (H + BLK - 1) / BLK
	var cand: Array = []
	var reach := WARP + WARP_BIG + 1.0
	for by in bh:
		for bx in bw:
			var x0 := bx * BLK - reach
			var x1 := (bx + 1) * BLK + reach
			var y0 := by * BLK - reach
			var y1 := (by + 1) * BLK + reach
			var dmin := PackedFloat32Array()
			dmin.resize(ns)
			var cap := 1e20
			for k in ns:
				var nx := (clampf(sx[k], x0, x1) - sx[k]) / shx[k]
				var ny := (clampf(sy[k], y0, y1) - sy[k]) / shy[k]
				dmin[k] = nx * nx + ny * ny
				var ex := maxf(absf(x0 - sx[k]), absf(x1 - sx[k])) / shx[k]
				var ey := maxf(absf(y0 - sy[k]), absf(y1 - sy[k])) / shy[k]
				cap = minf(cap, ex * ex + ey * ey)
			var lst := PackedInt32Array()
			for k in ns:
				if dmin[k] <= cap:
					lst.append(k)
			cand.append(lst)
	var owner := PackedByteArray()
	owner.resize(N)
	var sea := PackedByteArray()
	sea.resize(N)
	var k_sect: int = idx.get("sect", -1)
	var k_hub_site := -1
	for k in ns:
		if sid[k] == idx.get(HUB, -2):
			k_hub_site = k
	for y in H:
		var row := y * W
		var brow := (y / BLK) * bw
		for x in W:
			var i := row + x
			var wx := x + 0.5 + (fx[i] / 127.5 - 1.0) * WARP + (gx[i] / 127.5 - 1.0) * WARP_BIG
			var wy := y + 0.5 + (fy[i] / 127.5 - 1.0) * WARP + (gy[i] / 127.5 - 1.0) * WARP_BIG
			var lst: PackedInt32Array = cand[brow + x / BLK]
			var bd := 1e20
			var bk := 0
			for k in lst:
				var dx := (wx - sx[k]) / shx[k]
				var dy := (wy - sy[k]) / shy[k]
				var dd := dx * dx + dy * dy
				if dd < bd:
					bd = dd
					bk = k
			var o: int = sid[bk]
			if sect_r.has_point(Vector2i(x, y)):
				o = k_sect
			elif pin[i] >= 0:
				o = pin[i]
			owner[i] = o
			# the coast: land reaches about LAND half-sizes out from the nearest site (the mountain
			# is broad, so its own shores come in closer)
			var reach_land := (LAND_HUB if bk == k_hub_site else land_far) + (coast[i] / 127.5 - 1.0) * 0.45
			# ... and fades out towards the edge of the world, which is always open sea
			reach_land *= clampf(mini(mini(x, y), mini(W - 1 - x, H - 1 - y)) / 30.0, 0.0, 1.0)
			if pin[i] < 0 and o != k_sect and sqrt(bd) > reach_land:
				sea[i] = 1
	# ---- land bridges: every road gets an isthmus to run on, so no road has to cross the sea
	_isthmuses(owner, sea, W, H, idx)
	# ---- the land: forest everywhere, the sea beyond the coast, and each region's own map (whose
	# open ground is already an organic outline, see MapGen._outline) where it owns the land
	var grid := PackedByteArray()
	grid.resize(N)
	grid.fill(MapGen.WALL)
	for i in N:
		if sea[i] == 1:
			grid[i] = MapGen.WATER
	var lake := _field(7070, 0.022, 2, W, H)
	for id in ids:
		_stamp_region(grid, owner, sea, W, H, id, idx[id], maps[id], sect_r)
	# lakes in the wild forest between regions (never in a region's open ground or by its people); in
	# the realms above and below they are chasms instead, down through the islands to the clouds or the
	# abyss
	var holes: int = 200 if surf else int(STRATA[layer].holes)
	for i in N:
		if grid[i] == MapGen.WALL and pin[i] < 0 and lake[i] > holes and owner[i] != k_sect:
			grid[i] = MapGen.WATER
			if not surf:
				sea[i] = 1
	# every region's open ground hangs together, inside its own land
	for id in ids:
		if id == "sect" or id == HUB:
			continue
		_reconnect(grid, owner, W, H, id, idx[id], maps[id])
	# ---- the belt between regions: forest and rock where two regions meet (it never opens anything)
	_belts(grid, owner, pin, W, H, k_sect)
	# ---- the sect's pagoda stands on the mountain north-west of the courtyard
	if surf:
		var pag := sect_r.position + Vector2i(-5, 3)
		for yy in range(pag.y - 1, pag.y + 2):
			for xx in range(pag.x - 1, pag.x + 2):
				grid[yy * W + xx] = MapGen.BUILDING
	# ---- roads between gates, seals where the story has not opened the way yet
	var road_cost := _field(8080, 0.045, 2, W, H)
	var blocked := {}
	for id in ids:
		for e in maps[id].ents:
			if e.kind in ["npc", "boss", "pickup"]:
				blocked[to_world(id, e.pos)] = true
	var seals: Array = []
	var done := {}
	var road_n := 0
	for a in ids:
		for p in Data.AREAS[a].get("portals", []):
			var b: String = p.to
			if not Data.AREAS.has(b) or not L.has(b) or not idx.has(b):
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
			road_n += 1
			var ga := to_world(a, p.pos)
			var gb := to_world(b, back.pos)
			var rd := _road(grid, owner, sea, road_cost, blocked, W, H, idx, a, ga, _gate_dir(a, p.pos), b, gb, _gate_dir(b, back.pos))
			# the road runs on to where travellers arrive in each region
			if a != "sect":
				_line(grid, W, ga, to_world(a, back.dest))
			if b != "sect":
				_line(grid, W, gb, to_world(b, p.dest))
			if rd.is_empty():
				push_warning("Atlas: no road between %s and %s" % [a, b])
				continue
			if p.open != "":
				seals.append(_seal(rd, b, rd.cross_b, rd.cross_a, p.open, a))
			elif back.open != "":
				seals.append(_seal(rd, a, rd.cross_a, rd.cross_b, back.open, b))
	# a road that still had to cross the open sea runs on a causeway, which belongs to the land
	for i in N:
		if sea[i] == 1 and grid[i] == MapGen.PATH:
			sea[i] = 0
	# ---- entities, in world tiles
	var ents: Array = []
	var buildings: Array = []
	var floor_ents: Array = []
	for id in ids:
		var m: Dictionary = maps[id]
		for e in m.ents:
			if e.kind == "portal":
				continue
			var ge: Dictionary = e.duplicate(true)
			ge.pos = to_world(id, e.pos)
			ge["area"] = id
			ge["layer"] = layer
			if ge.kind == "enemy":
				ge.id = id + ":" + str(e.id)
			ents.append(ge)
		for fe in m.floor_ents:
			var gf: Dictionary = fe.duplicate(true)
			gf.pos = to_world(id, fe.pos)
			gf["area"] = id
			floor_ents.append(gf)
		for bd in m.buildings:
			var gb2: Dictionary = bd.duplicate(true)
			gb2.rect = rect_to_world(id, bd.rect)
			gb2.door = to_world(id, bd.door)
			gb2["area"] = id
			# (the Lost Horse release: the rectangle as written, and the wings built out from it, turned
			# with the region: rooms.gd `let_out`)
			if bd.has("rect0"):
				gb2["rect0"] = rect_to_world(id, bd.rect0)
			if bd.has("wings"):
				var gws: Array = []
				var sides4 := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
				for wg in bd.wings:
					gws.append({"rect": rect_to_world(id, wg.rect), "side": sides4.find(dir_to_world(id, sides4[int(wg.side)]))})
				gb2["wings"] = gws
			var props: Array = []
			for pr in bd.get("props", []):
				props.append([pr[0], to_world(id, pr[1]), pr.size() > 2 and pr[2]])
			gb2.props = props
			# an upper storey and a cellar: their stairs and furniture in world tiles too
			for key2 in [["up", "upper"], ["down", "cellar"]]:
				if not bd.has(key2[0]):
					continue
				gb2[key2[0]] = to_world(id, bd[key2[0]])
				var fprops: Array = []
				for pr2 in bd[key2[1]].get("props", []):
					fprops.append([pr2[0], to_world(id, pr2[1]), pr2.size() > 2 and pr2[2]])
				gb2[key2[1]] = {"n": str(bd[key2[1]].get("n", "")), "props": fprops}
			buildings.append(gb2)
		# the ladders between the realms that have an end in this region
		for le in MapGen.ladder_ends(id):
			var ld: Dictionary = le[2]
			var other: Array = ld["b" if le[3] == "a" else "a"]
			var to_layer := Data.layer_of(other[0])
			ents.append({"kind": "ladder", "id": "%s:%s" % [ld.id, le[3]], "n": ld["n" + str(le[3])], "pos": to_world(id, le[0]), "area": id, "layer": layer,
				"to_layer": to_layer, "to_tile": to_world(other[0], other[1] + other[2]), "open": ld.open, "style": str(ld.get("style", "climb")),
				"dir": 1 if layer_y(to_layer) > layer_y(layer) else -1})
	for s in seals:
		s["layer"] = layer
		ents.append(s)
	var start := to_world("sect", Vector2i(20, 8))
	if not surf:
		var st: Array = STRATA[layer].start
		start = to_world(st[0], st[1])
	# ---- the floors of buildings with an upper storey or a cellar, and the stairs to them
	var floors := {}
	for bd2 in buildings:
		for lv in [1, -1]:
			var fl_key := "upper" if lv == 1 else "cellar"
			if not bd2.has(fl_key):
				continue
			var fw := _floor(layer, bd2, lv, grid, W, H, ents, floor_ents)
			floors[fw.layer] = fw
	# ---- every entity must be reachable from the sect with all seals open
	_connect(grid, W, H, owner, idx, ents, start, sea)
	# a monster pack the borders left on a pocket of its region's land that no trail of the region can
	# reach is dropped (only ever happens among the floating islands and chasms of the realms above
	# and below)
	var reach_e := MapGen.flood(grid, W, H, start)
	ents = ents.filter(func(e): return e.kind != "enemy" or reach_e.has(e.pos))
	# ---- things to do (props.gd): a few in every region on the forest edge and the shore, and the
	# furniture of every building; added once the ground is final, on tiles nobody walks over
	ents.append_array(Props.place(grid, W, H, owner, sea, ids, ents, layer))
	for bd3 in buildings:
		ents.append_array(Props.furniture(bd3.props, bd3.area, layer, "furn:%s:%s" % [bd3.area, bd3.id], grid, W))
	# ---- Part XVII (impact.gd): the obstacles of the story (fallen trunks, rockfalls, ice jams, the clay
	# Spring Ox), added last so that no road, seal, pack or thing to do moves for them; each stands on
	# open ground of its region with a way round it (tests/run_tests.gd checks both)
	for id2 in ids:
		for ob in Data.AREAS[id2].get("obstacles", []):
			ents.append({"kind": "obstacle", "id": str(ob.id), "what": str(ob.what), "pos": to_world(id2, ob.pos), "area": id2, "layer": layer, "vis": ob.get("vis", ["", ""])})
		# and the people, lords and things to find that came later in the story ("late": mapgen.gd leaves
		# them out of the region's own map), stood in the finished world in the same way
		var spec2: Dictionary = Data.AREAS[id2]
		# (all but those the story put in a cave: caves.gd stands them there)
		for n2 in spec2.get("npcs", []):
			if n2.get("late", false) and not n2.has("cave") and not n2.has("peak") and not n2.has("hold"):
				var ne := {"kind": "npc", "id": n2.id, "n": n2.n, "pos": to_world(id2, n2.pos), "col": n2.col, "vis": n2.get("vis", ["", ""]), "area": id2, "layer": layer, "late": true}
				for k2 in ["asset", "race", "hide", "fate"]:
					if n2.has(k2):
						ne[k2] = n2[k2]
				ents.append(ne)
		for b2 in spec2.get("bosses", []):
			if b2.get("late", false) and not b2.has("cave") and not b2.has("peak"):
				ents.append({"kind": "boss", "id": "boss_" + str(b2.id), "enemy": b2.id, "pos": to_world(id2, b2.pos), "lv": b2.lv, "req": b2.req, "vis": b2.get("vis", ["", ""]), "area": id2, "layer": layer, "late": true})
		for pk2 in spec2.get("pickups", []):
			if pk2.get("late", false) and not pk2.has("cave") and not pk2.has("peak"):
				var pe := {"kind": "pickup", "id": pk2.id, "item": pk2.item, "pos": to_world(id2, pk2.pos), "vis": pk2.get("vis", ["", ""]), "area": id2, "layer": layer, "late": true}
				if pk2.has("n"):
					pe["n"] = pk2.n
				ents.append(pe)
	# ---- the Hundred Works (works.gd): the machines stand in the land once they are built (and Gongshu
	# Ban's wheel from the step in which he is met), added after everything else, so no older map moves
	for ms in Works.sites():
		if ids.has(str(ms[2])):
			ents.append({"kind": "machine", "id": str(ms[0]), "work": str(ms[1]), "pos": to_world(str(ms[2]), ms[3]), "area": str(ms[2]), "layer": layer, "late": true})
	# and the war-bands that came later in the story: packs of two or three on open ground of their
	# region that the sect can reach, four tiles from anybody and anything (a seeded draw, so the same
	# every time)
	# (Part XXII: a region may have a second band, "warband2", for a later chapter)
	var band_slots: Array = []
	for id0 in ids:
		band_slots.append([id0, "warband", "w"])
	for id0 in ids:
		band_slots.append([id0, "warband2", "x"])
	_place_bands(band_slots, grid, W, H, owner, ids, ents, layer, reach_e, [], {})
	# ---- the Hollow Hills (caves.gd): a cave under every region, its mouth on open ground of the region
	# that the sect can reach, with open ground all round it (so that it stands in nobody's way), added
	# after everything else, so no older map moves
	Caves.place(grid, W, H, owner, ids, ents, layer, reach_e, floors)
	# ---- the High Roads (peaks.gd): mountains in every region, on ground nothing else stands on, added
	# last of all; their rock is open ground, climbed where it is steep
	var pk_t0 := Time.get_ticks_usec()
	var pks := Peaks.place(grid, W, H, owner, sea, ids, ents, layer, reach_e)
	# (what the story puts on a peak is stood there now: `"peak": k` in Data.AREAS)
	Peaks.world(grid, W, pks.peaks, ents, layer, ids)
	# ... and the camps of the people of the road, at the feet of the highest (folk.gd)
	var camps := Folk.place_camps(grid, W, H, owner, ids, ents, reach_e, pks.peaks)
	# ---- Part XXIV: a region's third and fourth bands ("warband3", "warband4") are placed now, after the
	# caves, the peaks and the camps, off the rock and away from the camp fires, so that no cave mouth,
	# peak or camp of an older map moves for them (a band may stop marching when a step is done: "until")
	# ---- the Three Burrows release (hold.gd): the plots, the steward and the settlers of the town that
	# is the hero's own, on ground that was found open with nothing near it; stood before the late bands
	# and the marks so that those keep off it, and no older map moves
	Hold.place(grid, W, ids, ents, layer)
	var late_slots: Array = []
	for id0 in ids:
		late_slots.append([id0, "warband3", "y"])
	for id0 in ids:
		late_slots.append([id0, "warband4", "z"])
	_place_bands(late_slots, grid, W, H, owner, ids, ents, layer, reach_e, pks.peaks, camps)
	# ---- the Lost Horse release (marks.gd): what the crossroads leave standing, and what the scales
	# stand in every region, on open ground nothing else is on; added last of all, so no older map moves
	Marks.place(grid, W, H, owner, ids, ents, layer, reach_e, pks.peaks, camps)
	# ---- the Three Burrows release: a region's fifth and sixth bands ("warband5", "warband6") are placed
	# after the marks, on what open ground is left, so that nothing a choice left standing moves for them
	# (a band placed before the marks takes ground a mark of an older release stood on)
	var last_slots: Array = []
	for id0 in ids:
		last_slots.append([id0, "warband5", "u"])
	for id0 in ids:
		last_slots.append([id0, "warband6", "v"])
	_place_bands(last_slots, grid, W, H, owner, ids, ents, layer, reach_e, pks.peaks, camps)
	# ---- and who is at home (rooms.gd `residents`): people indoors in the houses of every town, stood
	# after everything else on floor nobody needs to get past
	ents.append_array(Rooms.residents(buildings, grid, W, ents, layer))
	if OS.has_environment("AZ_PROFILE"):
		print("[profile] realm %s: %d peaks and %d camps placed in %d ms" % [layer, (pks.peaks as Array).size(), camps.size(), (Time.get_ticks_usec() - pk_t0) / 1000])
	# ---- each region's cell: the bounding box of the land it owns
	var lo: Array = []
	var hi: Array = []
	for i in ids.size():
		lo.append(Vector2i(W, H))
		hi.append(Vector2i(-1, -1))
	for y in H:
		for x in W:
			var i := y * W + x
			if sea[i] == 1:
				continue
			var o := owner[i]
			var l: Vector2i = lo[o]
			var hh: Vector2i = hi[o]
			if x < l.x or y < l.y:
				lo[o] = Vector2i(mini(l.x, x), mini(l.y, y))
			if x > hh.x or y > hh.y:
				hi[o] = Vector2i(maxi(hh.x, x), maxi(hh.y, y))
	for id in ids:
		var o2: int = idx[id]
		if hi[o2].x >= 0:
			L[id].cell = Rect2i(lo[o2], hi[o2] - lo[o2] + Vector2i.ONE)
	return {"w": W, "h": H, "grid": grid, "owner": owner, "sea": sea, "ids": ids, "idx": idx, "ents": ents, "buildings": buildings,
		"start": start, "layout": L, "maps": maps, "layer": layer, "floors": floors, "origin": layer_origin(layer), "y": layer_y(layer),
		"peaks": pks.peaks, "peak_blk": pks.blk, "camps": camps}


## The war-bands that came later in the story (`slots`: [region, key, letter]): packs of two or three
## on open ground of their region that the sect can reach, four tiles from anybody and anything (and
## off the `peaks` and away from the `camps`, for the bands placed after those).  A seeded draw.
static func _place_bands(slots: Array, grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, ids: Array, ents: Array, layer: String, reach_e: Dictionary, peaks: Array, camps: Dictionary) -> void:
	for bs in slots:
		var id3: String = bs[0]
		var band: Dictionary = Data.AREAS[id3].get(str(bs[1]), {})
		if band.is_empty() or not band.get("late", false):
			continue
		var near := {}
		for e5 in ents:
			if str(e5.get("area", "")) == id3 and e5.has("pos"):
				for dy5 in range(-4, 5):
					for dx5 in range(-4, 5):
						near[e5.pos + Vector2i(dx5, dy5)] = true
		if camps.has(id3):
			for dy7 in range(-7, 8):
				for dx7 in range(-7, 8):
					near[(camps[id3] as Vector2i) + Vector2i(dx7, dy7)] = true
		for pk5 in peaks:
			if str(pk5.area) == id3:
				var pr5 := int(pk5.r) + 2
				for dy8 in range(-pr5, pr5 + 1):
					for dx8 in range(-pr5, pr5 + 1):
						if dx8 * dx8 + dy8 * dy8 <= pr5 * pr5:
							near[(pk5.c as Vector2i) + Vector2i(dx8, dy8)] = true
		var cands: Array = []
		for p5 in reach_e:
			var g5: int = grid[p5.y * W + p5.x]
			if (g5 == MapGen.FLOOR or g5 == MapGen.PATH or g5 == MapGen.DECOR) and str(ids[owner[p5.y * W + p5.x]]) == id3 and not near.has(p5):
				cands.append(p5)
		cands.sort()
		var rng5 := RandomNumberGenerator.new()
		rng5.seed = int(Data.AREAS[id3].seed) * 977 + {"w": 31, "x": 77, "y": 131, "z": 173, "u": 211, "v": 251}[str(bs[2])]
		var made := 0
		var tries := 0
		while made < int(band.n) and tries < 4000 and not cands.is_empty():
			tries += 1
			var c5: Vector2i = cands[rng5.randi() % cands.size()]
			if near.has(c5):
				continue
			made += 1
			var group5: Array = []
			for _k5 in rng5.randi_range(2, 3):
				var pe5: Array = band.pool[rng5.randi() % (band.pool as Array).size()]
				group5.append({"id": pe5[0], "lv": rng5.randi_range(int(pe5[1]), int(pe5[2]))})
			ents.append({"kind": "enemy", "id": "%s:%s%d" % [id3, str(bs[2]), made], "pos": c5, "group": group5, "vis": [str(band.vis), str(band.get("until", ""))], "area": id3, "layer": layer, "late": true})
			for dy6 in range(-4, 5):
				for dx6 in range(-4, 5):
					near[c5 + Vector2i(dx6, dy6)] = true

## A building's upper storey (`lv` 1) or cellar (-1) as a small world of its own, the size of the
## building's rectangle (its own tiles start at the rectangle's corner), with the people and things
## that live on it and the stairs back down (or up); the stairs to it are added to the realm's
## entities.  Each flight of stairs puts a traveller on the first free tile beside the other end,
## nearest the middle of the room.
static func _floor(layer: String, bd: Dictionary, lv: int, grid: PackedByteArray, W: int, H: int, ents: Array, floor_ents: Array) -> Dictionary:
	var r: Rect2i = bd.rect
	var area: String = bd.area
	var fl: Dictionary = bd.upper if lv == 1 else bd.cellar
	var stairs: Vector2i = bd.up if lv == 1 else bd.down
	var g := MapGen.floor_grid(r, fl, stairs)
	var fid := floor_id(area, bd.id, lv)
	var fents: Array = []
	var taken := {stairs - r.position: true}
	for fe in floor_ents:
		if fe.area == area and str(fe.floor[0]) == str(bd.id) and int(fe.floor[1]) == lv:
			var e: Dictionary = fe.duplicate(true)
			e.erase("floor")
			e.pos = fe.pos - r.position
			e["layer"] = fid
			fents.append(e)
			taken[e.pos] = true
	var owner := PackedByteArray()
	owner.resize(r.size.x * r.size.y)
	var mid := Vector2(r.size) * 0.5
	var arrive := _beside(g, r.size.x, r.size.y, stairs - r.position, taken, mid)
	# where the stairs come out on the realm's own floor (the ground floor of the building)
	var taken2 := {}
	for e2 in ents:
		if r.has_point(e2.pos):
			taken2[e2.pos] = true
	taken2[stairs] = true
	var back := _beside(grid, W, H, stairs, taken2, Vector2(r.position) + mid)
	var fname := str(fl.get("n", ""))
	fents.append({"kind": "ladder", "id": "stairs:%s:%s:%d:back" % [area, bd.id, lv], "n": "Stairs down" if lv == 1 else "Stairs up", "pos": stairs - r.position,
		"area": area, "layer": fid, "to_layer": layer, "to_tile": back, "open": "", "style": "stairs", "dir": -lv})
	ents.append({"kind": "ladder", "id": "stairs:%s:%s:%d" % [area, bd.id, lv], "n": ("Up to " if lv == 1 else "Down to ") + fname, "pos": stairs,
		"area": area, "layer": layer, "to_layer": fid, "to_tile": arrive, "open": "", "style": "stairs", "dir": lv})
	var lprops: Array = []
	for pr in fl.get("props", []):
		lprops.append([pr[0], pr[1] - r.position, pr[2]])
	# its furniture can be used too (props.gd), all but anything standing where the stairs come up
	var st_l: Vector2i = stairs - r.position
	fents.append_array(Props.furniture(lprops.filter(func(pr): return pr[1] != st_l), area, fid, "furn:%s:%s:%d" % [area, bd.id, lv], g, r.size.x))
	return {"layer": fid, "kind": "floor", "parent": layer, "bld": bd.id, "bld_n": bd.n, "floor_n": fname, "level": lv, "area": area,
		"w": r.size.x, "h": r.size.y, "origin": r.position, "grid": g, "owner": owner, "sea": PackedByteArray(), "ids": [area], "idx": {area: 0},
		"ents": fents, "buildings": [], "start": arrive, "floors": {}, "y": 0.0, "props": lprops, "stairs": stairs - r.position, "style": str(bd.get("style", "house"))}

## The free tile beside `at` (4-neighbours) nearest `toward`, skipping tiles in `taken`.
static func _beside(g: PackedByteArray, w: int, h: int, at: Vector2i, taken: Dictionary, toward: Vector2) -> Vector2i:
	var best := at
	var bd := 1e20
	for d in MapGen.DIRS:
		var n: Vector2i = at + d
		if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or taken.has(n):
			continue
		if not MapGen.is_walkable_tile(g[n.y * w + n.x]):
			continue
		var dd := (Vector2(n) + Vector2(0.5, 0.5)).distance_squared_to(toward)
		if dd < bd:
			bd = dd
			best = n
	return best

## Raise land along the straight way between every pair of gates a road will join (on the two
## regions' own land only), so the coast never cuts a road.
static func _isthmuses(owner: PackedByteArray, sea: PackedByteArray, W: int, H: int, idx: Dictionary) -> void:
	var done := {}
	for a in idx:
		for p in Data.AREAS[a].get("portals", []):
			var b: String = p.to
			if not idx.has(b):
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
			var pa := to_world(a, p.pos) + _gate_dir(a, p.pos) * 3
			var pb := to_world(b, back.pos) + _gate_dir(b, back.pos) * 3
			var sa := _side(idx, a)
			var sb := _side(idx, b)
			var n := maxi(absi(pb.x - pa.x), absi(pb.y - pa.y))
			for k in n + 1:
				var c := Vector2(pa).lerp(Vector2(pb), k / float(maxi(n, 1)))
				for dy in range(-5, 6):
					for dx in range(-5, 6):
						if dx * dx + dy * dy > 26:
							continue
						var x := int(round(c.x)) + dx
						var y := int(round(c.y)) + dy
						if x < 0 or y < 0 or x >= W or y >= H:
							continue
						var i := y * W + x
						if owner[i] == sa or owner[i] == sb:
							sea[i] = 0

## Places in a region's own map that must stay open and belong to it: [local tile, radius].
static func _spots(id: String, m: Dictionary) -> Array:
	var spots: Array = []
	for e in m.ents:
		spots.append([e.pos, 2 if e.kind == "enemy" else 4])
	for a in MapGen.arrival_tiles(id):
		spots.append([a, 4])
	for p in Data.AREAS[id].get("portals", []):
		spots.append([p.pos, 4])
		spots.append([p.dest, 3])
	for le in MapGen.ladder_ends(id):
		spots.append([le[0], 4])
	return spots

## Stamp region `id`'s own map into the world where it owns the land.
static func _stamp_region(grid: PackedByteArray, owner: PackedByteArray, sea: PackedByteArray, W: int, H: int, id: String, me: int, m: Dictionary, sect_r: Rect2i) -> void:
	var r: Dictionary = layout()[id]
	var o: Vector2i = r.origin
	var loc: Vector2i = r.local
	var rot: int = r.rot
	var mw: int = m.w
	var mh: int = m.h
	var mg: PackedByteArray = m.grid
	var is_sect := id == "sect"
	for ly in mh:
		for lx in mw:
			var q := o + _turn(Vector2i(lx, ly), loc, rot)
			if q.x < 0 or q.y < 0 or q.x >= W or q.y >= H:
				continue
			var i := q.y * W + q.x
			if owner[i] != me or sea[i] == 1:
				continue
			if not is_sect and sect_r.has_point(q):
				continue
			grid[i] = mg[ly * mw + lx]

## The forest must not cut anything off: reconnect inside the region's own map and its own land, the
## way MapGen does (trails wander like deer tracks, and go round buildings).
static func _reconnect(grid: PackedByteArray, owner: PackedByteArray, W: int, H: int, id: String, me: int, m: Dictionary) -> void:
	var r: Dictionary = layout()[id]
	var o: Vector2i = r.origin
	var loc: Vector2i = r.local
	var rot: int = r.rot
	var mw: int = m.w
	var mh: int = m.h
	var local := PackedByteArray()
	local.resize(mw * mh)
	var wi := PackedInt32Array()
	wi.resize(mw * mh)
	for ly in mh:
		for lx in mw:
			var q := o + _turn(Vector2i(lx, ly), loc, rot)
			var li := ly * mw + lx
			if q.x < 0 or q.y < 0 or q.x >= W or q.y >= H or owner[q.y * W + q.x] != me:
				# other regions' land: a trail may not cross it
				local[li] = MapGen.BUILDING
				wi[li] = -1
				continue
			wi[li] = q.y * W + q.x
			local[li] = grid[wi[li]]
	var arr: Array = MapGen.arrival_tiles(id)
	var start: Vector2i = arr[0] if not arr.is_empty() else m.start
	var need: Array = []
	for e in m.ents:
		if e.kind != "spring":
			need.append(MapGen._outside(e.pos, m.buildings))
	for a in arr:
		need.append(a)
	for p in Data.AREAS[id].get("portals", []):
		need.append(p.pos)
	for le in MapGen.ladder_ends(id):
		need.append(le[0])
	for _pass in 40:
		var reach := MapGen.flood(local, mw, mh, start)
		var miss := false
		for q2 in need:
			if not reach.has(q2):
				_carve_around(local, mw, mh, q2, reach)
				miss = true
				break
		if not miss:
			break
	for li in mw * mh:
		if wi[li] >= 0:
			grid[wi[li]] = local[li]

## Forest and rock where two regions meet, its width wandering between BAND_MIN and BAND_MAX on each
## side.  Never across the sect's own courtyard or a region's pinned clearings.
static func _belts(grid: PackedByteArray, owner: PackedByteArray, pin: PackedInt32Array, W: int, H: int, k_sect: int) -> void:
	var N := W * H
	var dist := PackedByteArray()
	dist.resize(N)
	dist.fill(255)
	var q := PackedInt32Array()
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var i := y * W + x
			var o := owner[i]
			if owner[i - 1] != o or owner[i + 1] != o or owner[i - W] != o or owner[i + W] != o:
				dist[i] = 0
				q.append(i)
	var head := 0
	var cap := int(ceil(BAND_MAX))
	while head < q.size():
		var i := q[head]
		head += 1
		var nd := dist[i] + 1
		if nd > cap:
			continue
		for j in [i - 1, i + 1, i - W, i + W]:
			if j >= 0 and j < N and dist[j] > nd:
				dist[j] = nd
				q.append(j)
	var band := _field(5151, 0.05, 2, W, H)
	for i in N:
		if dist[i] == 255 or pin[i] >= 0 or owner[i] == k_sect:
			continue
		var t := grid[i]
		if t != MapGen.FLOOR and t != MapGen.DECOR and t != MapGen.PATH:
			continue
		if dist[i] < BAND_MIN + band[i] / 255.0 * (BAND_MAX - BAND_MIN):
			grid[i] = MapGen.WALL

## Carve the shortest trail from `from` to the nearest tile in `reach`, going round buildings (a
## trail must never break through a wall; the door is the way in).
static func _carve_around(grid: PackedByteArray, w: int, h: int, from: Vector2i, reach: Dictionary) -> void:
	var prev := {from: from}
	var q: Array = [from]
	var i := 0
	var hit := Vector2i(-1, -1)
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		if reach.has(c):
			hit = c
			break
		for d in MapGen.DIRS:
			var n: Vector2i = c + d
			if n.x < 1 or n.y < 1 or n.x >= w - 1 or n.y >= h - 1 or prev.has(n):
				continue
			var t := grid[n.y * w + n.x]
			if (t == MapGen.BUILDING or t == MapGen.INTERIOR) and not reach.has(n):
				continue
			prev[n] = c
			q.append(n)
	if hit.x < 0:
		return
	var cur := hit
	while cur != from:
		if not MapGen.is_walkable_tile(grid[cur.y * w + cur.x]):
			grid[cur.y * w + cur.x] = MapGen.PATH
		cur = prev[cur]
	if not MapGen.is_walkable_tile(grid[from.y * w + from.x]):
		grid[from.y * w + from.x] = MapGen.PATH

## which way a gate faces out of its region (in world directions)
static func _gate_dir(id: String, pos: Vector2i) -> Vector2i:
	var s: Vector2i = layout()[id].local
	var d := Vector2i.ZERO
	if pos.x <= 1:
		d = Vector2i(-1, 0)
	elif pos.x >= s.x - 2:
		d = Vector2i(1, 0)
	elif pos.y <= 1:
		d = Vector2i(0, -1)
	else:
		d = Vector2i(0, 1)
	return dir_to_world(id, d)

## The region whose land a road runs over on `id`'s side: the sect's roads leave over the mountain.
static func _side(idx: Dictionary, id: String) -> int:
	return idx[HUB] if id == "sect" else idx[id]

## A road from gate `ga` of region `a` to gate `gb` of region `b`.  It leaves each gate straight for a
## few steps, then is searched for (A*) across the land: open ground is cheap, old paths cheaper,
## forest dear and water dearer, and a slow noise field makes it wind.  It crosses from one region
## to the other exactly once, at the point of their border that makes the way shortest, and keeps
## to its own two regions' land.  Returns {"tiles", "cross_a", "cross_b"} ({} if there is no way).
static func _road(grid: PackedByteArray, owner: PackedByteArray, sea: PackedByteArray, cost: PackedByteArray, blocked: Dictionary, W: int, H: int, idx: Dictionary, a: String, ga: Vector2i, da: Vector2i, b: String, gb: Vector2i, db: Vector2i) -> Dictionary:
	var sa := _side(idx, a)
	var sb := _side(idx, b)
	var lead := 3 if a == "sect" else 2
	var lead_b := 3 if b == "sect" else 2
	var pa := ga + da * lead
	var pb := gb + db * lead_b
	var box := Rect2i(Vector2i(mini(pa.x, pb.x), mini(pa.y, pb.y)), Vector2i.ONE).merge(Rect2i(Vector2i(maxi(pa.x, pb.x), maxi(pa.y, pb.y)), Vector2i.ONE))
	box = box.grow(60).intersection(Rect2i(1, 1, W - 2, H - 2))
	# where to cross: the border tile pair that makes the way shortest (land before water)
	var best := 1e20
	var ca := Vector2i(-1, -1)
	var cb := Vector2i(-1, -1)
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var i := y * W + x
			if owner[i] != sb:
				continue
			for d in MapGen.DIRS:
				var n: Vector2i = Vector2i(x, y) + d
				if owner[n.y * W + n.x] != sa:
					continue
				var c := Vector2(pa).distance_to(Vector2(n)) + Vector2(pb).distance_to(Vector2(x, y))
				if sea[i] == 1 or sea[n.y * W + n.x] == 1:
					c += 40.0
				if grid[i] == MapGen.BUILDING or grid[n.y * W + n.x] == MapGen.BUILDING:
					c += 1000.0
				if c < best:
					best = c
					ca = n
					cb = Vector2i(x, y)
	if ca.x < 0:
		return {}
	var p1 := _astar(grid, owner, cost, blocked, W, box, sa, pa, ca)
	var p2 := _astar(grid, owner, cost, blocked, W, box, sb, cb, pb)
	if p1.is_empty() or p2.is_empty():
		return {}
	var tiles := {}
	_line_t(grid, W, ga, pa, tiles)
	var prev: Vector2i = pa
	for c2 in p1:
		_line_t(grid, W, prev, c2, tiles)
		prev = c2
	_line_t(grid, W, prev, cb, tiles)
	prev = cb
	for c3 in p2:
		_line_t(grid, W, prev, c3, tiles)
		prev = c3
	_line_t(grid, W, prev, gb, tiles)
	return {"tiles": tiles, "cross_a": ca, "cross_b": cb}

## A* over `box` keeping to the land of region `me`.
static func _astar(grid: PackedByteArray, owner: PackedByteArray, cost: PackedByteArray, blocked: Dictionary, W: int, box: Rect2i, me: int, from: Vector2i, to: Vector2i) -> Array:
	var a := AStarGrid2D.new()
	a.region = box
	a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	a.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	a.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	a.update()
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var i := y * W + x
			var p := Vector2i(x, y)
			if owner[i] != me:
				a.set_point_solid(p, true)
				continue
			var t := grid[i]
			var wgt := 1.0
			match t:
				MapGen.BUILDING, MapGen.INTERIOR:
					a.set_point_solid(p, true)
					continue
				MapGen.PATH:
					wgt = 0.45
				MapGen.FLOOR:
					wgt = 1.0
				MapGen.DECOR:
					wgt = 1.3
				MapGen.WATER:
					wgt = 9.0
				_:
					wgt = 2.8
			wgt += cost[i] / 255.0 * 1.8
			if blocked.has(p):
				wgt += 12.0
			a.set_point_weight_scale(p, wgt)
	for e in [from, to]:
		if a.is_in_boundsv(e):
			a.set_point_solid(e, false)
	if not a.is_in_boundsv(from) or not a.is_in_boundsv(to):
		return []
	return Array(a.get_id_path(from, to))

## 4-connected line of 2x2 road stamps, remembering the tiles it paved
static func _line_t(grid: PackedByteArray, W: int, a: Vector2i, b: Vector2i, tiles: Dictionary) -> void:
	var c := a
	_stamp(grid, W, c, tiles)
	while c != b:
		if absi(b.x - c.x) >= absi(b.y - c.y):
			c.x += signi(b.x - c.x)
		else:
			c.y += signi(b.y - c.y)
		_stamp(grid, W, c, tiles)

static func _line(grid: PackedByteArray, W: int, a: Vector2i, b: Vector2i) -> void:
	_line_t(grid, W, a, b, {})

static func _stamp(grid: PackedByteArray, W: int, c: Vector2i, tiles: Dictionary = {}) -> void:
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var p: Vector2i = c + d
		var t := grid[p.y * W + p.x]
		if t != MapGen.BUILDING and t != MapGen.INTERIOR:
			grid[p.y * W + p.x] = MapGen.PATH
			tiles[p] = true

## A Lotus Seal barrier across the road where it crosses into region `id`: every tile of that road
## within two steps of the crossing.  `axis` is the way the road runs there.
static func _seal(rd: Dictionary, id: String, at: Vector2i, from_tile: Vector2i, req: String, from: String) -> Dictionary:
	var tiles: Array = []
	for t in rd.tiles:
		var tv: Vector2i = t
		if maxi(absi(tv.x - at.x), absi(tv.y - at.y)) <= 2:
			tiles.append(tv)
	tiles.sort()
	return {"kind": "seal", "id": "seal_" + id, "area": id, "to": id, "from": from, "pos": at, "tiles": tiles, "open": req, "axis": at - from_tile}

## Any entity the borders cut off is reconnected by a trail inside its own region.
static func _connect(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, idx: Dictionary, ents: Array, start: Vector2i, sea: PackedByteArray = PackedByteArray()) -> void:
	for _pass in 6:
		var reach := MapGen.flood(grid, W, H, start)
		var fixed := 0
		for e in ents:
			if e.kind == "seal" or e.kind == "spring":
				continue
			if reach.has(e.pos):
				continue
			fixed += 1
			# breadth-first through anything in the same region to the nearest reachable tile, never
			# leaving the region's own land (a trail round the outside could bypass a Lotus Seal)
			var own := owner[e.pos.y * W + e.pos.x]
			var prev := {e.pos: e.pos}
			var q: Array = [e.pos]
			var i := 0
			var hit := Vector2i(-1, -1)
			while i < q.size() and i < 40000:
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
					if not sea.is_empty():
						sea[cur.y * W + cur.x] = 0
				cur = prev[cur]
			if not MapGen.is_walkable_tile(grid[cur.y * W + cur.x]):
				grid[cur.y * W + cur.x] = MapGen.FLOOR
				if not sea.is_empty():
					sea[cur.y * W + cur.x] = 0
		if fixed == 0:
			return

# ---------------------------------------------------------------- queries
static func owner_id(wd: Dictionary, p: Vector2i) -> String:
	if p.x < 0 or p.y < 0 or p.x >= wd.w or p.y >= wd.h:
		return HUB
	return wd.ids[wd.owner[p.y * wd.w + p.x]]

static func is_sea(wd: Dictionary, p: Vector2i) -> bool:
	if p.x < 0 or p.y < 0 or p.x >= wd.w or p.y >= wd.h:
		return true
	return wd.sea[p.y * wd.w + p.x] == 1

## The tiles a region renders: a copy of the bounding box of its land with other regions' tiles and
## the open sea blanked out (the sea is one surface for the whole world, see Terrain3D.world_sea).
static func slice(wd: Dictionary, id: String) -> Dictionary:
	var W: int = wd.w
	var me: int = wd.idx[id]
	var r: Rect2i = wd.layout[id].cell
	var g := PackedByteArray()
	g.resize(r.size.x * r.size.y)
	var sea: PackedByteArray = wd.sea
	for y in r.size.y:
		for x in r.size.x:
			var i: int = (y + r.position.y) * W + x + r.position.x
			g[y * r.size.x + x] = wd.grid[i] if wd.owner[i] == me and sea[i] == 0 else MapGen.VOID
	return {"rect": r, "grid": g}
