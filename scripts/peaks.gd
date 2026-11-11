class_name Peaks
extends RefCounted
## The mountains of the land (the High Roads release).  Until now the land rolled a metre up and a
## metre down and called that a hill: every region now has peaks of its own, crags of bare rock
## fifteen to forty-five metres high with a level top, laid out from the region's seed on ground
## that nothing of the story stands on.  A peak is a term added to the height field (Terrain3D.
## world_heights), not a model: the ground itself goes up, and whoever is on it goes up with it.
##
## Nothing on a peak is closed.  Its tiles are open ground (trees that stood there are gone), and
## what its slope does is decided by how much it rises from one tile to the next: a rise of a
## stride or less is walked, more than that is climbed, hand over hand (world.gd), and from
## anywhere high a glider carries its bearer down (world.gd again).  All of that asks only
## `rise`, which is a sum of a few sines and needs no mesh: the bot and the tests climb and glide
## without drawing anything.
##
## A peak never joins two regions (the whole of its footprint lies in one region's own land), so
## the seals between regions keep what they kept.

## the side of the blocks peaks are looked up by (tiles)
const BLK := 16
## a step that rises (or falls) more than this is a climb (metres between the middles of two tiles)
const STEEP := 0.95
## radius of a peak's footprint (tiles), smallest and largest
const R_MIN := 5
const R_TIGHT := 4
const R_MAX := 14
## clear ground kept round a footprint when a place is chosen (tiles)
const MARGIN := 2
## how many peaks a region is given: one for so many tiles of its land, between these
const PER_TILES := 1500
const N_MIN := 1
const N_MAX := 5
## the height of a peak for each tile of its radius (metres), least and most
const H_LO := 2.3
const H_HI := 3.3
## a peak this high has snow on its head where the land is cold enough for it, and above
## SNOW_ANY anywhere under the open sky
const SNOW_COLD := 12.0
const SNOW_ANY := 30.0

## Regions with no peaks: the sect's own courtyard (it stands on the mountain already).
const NONE := ["sect"]

## Peaks of the story: the names of a region's highest peaks, from the highest down (`big`: the
## largest place the region has is kept for it; `at`: the place nearest a tile of the region's own map).
const OWN := {
	"mountain": [{"n": "Sun-Viewing Peak", "big": true}, {"n": "the Sweeper's Lookout"}],
}

const NAME_A := ["Crane", "Listening", "Cloud-Gate", "Old Man", "Jade Maiden", "Nine Pines", "Wind-Rest", "Lonely", "Returning Goose", "Sleeping Ox",
	"Brush-Rest", "Lotus", "Thousand-Steps", "Moon-Viewing", "Echo", "Rain-Bell", "Tiger-Crouch", "Dawn-Greeting", "Hermit's", "Sword-Edge",
	"Purple Mist", "Stone Drum", "Heaven-Pillar", "Falling Star", "White Deer", "Immortal's Palm", "Flying-In", "Five Elders", "Camel-Back", "Ink-Pool",
	"Stork", "Plum-Root", "Lantern", "Mirror", "Thunder-Seat", "Quiet", "Cinnabar", "Tea-Smoke", "Monkey's Regret", "Kingfisher"]
const NAME_B := ["Peak", "Crag", "Terrace", "Tor", "Summit", "Rock", "Brow", "Spire", "Head", "Needle"]

# ---------------------------------------------------------------- laying them out
## Choose where the peaks of realm `layer` stand, open their ground (every tile a peak lifts
## becomes open ground, and a way to its foot is cut if the forest shut it in), and return
## {"peaks": [...], "blk": {...}} for the realm's data.  Called last of all when the realm is
## built (Atlas._build), so that nothing older moves.
static func place(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, sea: PackedByteArray, ids: Array, ents: Array, layer: String, reach: Dictionary) -> Dictionary:
	var out := {"peaks": [], "blk": {}}
	var cands := _cands(grid, W, H, owner, sea, ids, ents, reach, R_MIN, MARGIN, 4, 6)
	# (a crowded region, all lanes and people, is looked at again for a smaller place nearer to things)
	var missing := false
	for k0 in ids.size():
		if not cands.has(k0) and not (ids[k0] in NONE):
			missing = true
	if missing:
		var more := _cands(grid, W, H, owner, sea, ids, ents, reach, R_TIGHT, 1, 2, 3)
		for k1 in more:
			if not cands.has(k1):
				cands[k1] = more[k1]
	var area_n := PackedInt32Array()
	area_n.resize(ids.size())
	for i0 in W * H:
		if sea[i0] == 0:
			area_n[owner[i0]] += 1
	var used_names := {}
	for k in ids.size():
		var area: String = ids[k]
		if area in NONE or not cands.has(k):
			continue
		var spec: Dictionary = Data.AREAS[area]
		var want := clampi(int(area_n[k] / float(PER_TILES)), N_MIN, N_MAX)
		want = int(spec.get("peaks", want))
		var own: Array = OWN.get(area, [])
		want = maxi(want, own.size())
		var rng := RandomNumberGenerator.new()
		rng.seed = int(spec.seed) * 4099 + 17
		var list: Array = cands[k]
		var mine: Array = []
		# the peaks of the story first (the nearest place to where each is wanted, or the largest),
		# then the rest wherever the seed puts them, the big ones first and well apart
		for oi in own.size():
			var os: Dictionary = own[oi]
			var best := -1
			var bs := -1.0e9
			for ci in list.size():
				var c: Array = list[ci]
				if not _apart(c, mine):
					continue
				var sc := float(c[1]) * 4.0
				if os.has("at"):
					sc -= Vector2((c[0] as Vector2i) - Atlas.to_world(area, os.at)).length()
				elif not os.get("big", false):
					sc = rng.randf()
				if sc > bs:
					bs = sc
					best = ci
			if best >= 0:
				mine.append([list[best][0], list[best][1], str(os.n)])
		var tries := 0
		while mine.size() < want and tries < 400:
			tries += 1
			var c2: Array = list[rng.randi() % list.size()]
			# (a small place is taken only when the dice have failed to find a big one a few times)
			if int(c2[1]) < R_MIN + 3 and tries < 60 and int(c2[1]) >= R_MIN:
				continue
			if _apart(c2, mine):
				mine.append([c2[0], c2[1], ""])
		# (the region's peaks are numbered from its highest down, and the names of the story go to the highest)
		var made: Array = []
		for pi in mine.size():
			var m: Array = mine[pi]
			var c3: Vector2i = m[0]
			var r3: int = m[1]
			# (a region's first peaks are its great ones; no two are quite the same size)
			var rr3 := r3 if pi == 0 or str(m[2]) != "" else maxi(mini(r3, R_MIN), r3 - rng.randi_range(0, 3))
			made.append({"area": area, "layer": layer, "c": c3, "r": rr3, "r0": r3,
				"h": snappedf(float(rr3) * rng.randf_range(H_LO, H_HI), 0.1), "cx": float(c3.x) + 0.5, "cz": float(c3.y) + 0.5,
				"s1": rng.randf() * TAU, "s2": rng.randf() * TAU, "led": float(rng.randi_range(2, 4))})
		made.sort_custom(func(a, b): return float(a.h) > float(b.h) or (float(a.h) == float(b.h) and (a.c as Vector2i) < (b.c as Vector2i)))
		for pi2 in made.size():
			var pk: Dictionary = made[pi2]
			var nm := str(own[pi2].n) if pi2 < own.size() else ""
			var guard := 0
			while nm == "" or used_names.has(nm):
				nm = "%s %s" % [NAME_A[rng.randi() % NAME_A.size()], NAME_B[rng.randi() % NAME_B.size()]]
				guard += 1
				if guard > 60:
					nm = "%s %d" % [nm, out.peaks.size()]
			used_names[nm] = true
			pk.id = "peak:%s:%d" % [area, pi2]
			pk.n = nm
			pk.i = out.peaks.size()
			out.peaks.append(pk)
			var c4: Vector2i = pk.c
			var r4: int = pk.r
			for by in range((c4.y - r4 - 1) / BLK, (c4.y + r4 + 1) / BLK + 1):
				for bx in range((c4.x - r4 - 1) / BLK, (c4.x + r4 + 1) / BLK + 1):
					var bk := by * 4096 + bx
					if not out.blk.has(bk):
						out.blk[bk] = []
					out.blk[bk].append(pk)
			_open(grid, W, H, pk, reach)
	return out

## Every place a peak could stand in each region (by its index), with the largest radius it could
## have there: [tile, radius] pairs.
static func _cands(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, sea: PackedByteArray, ids: Array, ents: Array, reach: Dictionary, r_min: int, margin: int, e_small: int, e_big: int) -> Dictionary:
	# ---- where a footprint may not lie: the sea, the edge of a region, roads, water, buildings,
	# and round everything that stands on the land
	var bad := PackedByteArray()
	bad.resize(W * H)
	var area_n := PackedInt32Array()
	area_n.resize(ids.size())
	for y in H:
		var row := y * W
		for x in W:
			var i := row + x
			var g := grid[i]
			if sea[i] == 1 or (g != MapGen.FLOOR and g != MapGen.WALL and g != MapGen.DECOR):
				bad[i] = 1
				continue
			var o := owner[i]
			area_n[o] += 1
			if x == 0 or y == 0 or x >= W - 1 or y >= H - 1 or owner[i + 1] != o or owner[i + W] != o:
				bad[i] = 1
	for e in ents:
		var tiles: Array = e.tiles if e.kind == "seal" else ([e.pos] if e.has("pos") else [])
		var rr := e_small if e.kind in ["enemy", "prop", "spring"] else e_big
		for et in tiles:
			for dy in range(-rr, rr + 1):
				var yy: int = et.y + dy
				if yy < 0 or yy >= H:
					continue
				for dx in range(-rr, rr + 1):
					var xx: int = et.x + dx
					if xx >= 0 and xx < W:
						bad[yy * W + xx] = 1
	# ---- summed tables: how many forbidden tiles, and how many tiles that can be walked to, in
	# any rectangle
	var SW := W + 1
	var sat_bad := PackedInt32Array()
	sat_bad.resize(SW * (H + 1))
	var sat_reach := PackedInt32Array()
	sat_reach.resize(SW * (H + 1))
	for y in H:
		var run_b := 0
		var run_r := 0
		for x in W:
			run_b += bad[y * W + x]
			if reach.has(Vector2i(x, y)):
				run_r += 1
			var j := (y + 1) * SW + x + 1
			sat_bad[j] = sat_bad[j - SW] + run_b
			sat_reach[j] = sat_reach[j - SW] + run_r
	var box := func(sat: PackedInt32Array, cx: int, cy: int, r: int) -> int:
		var x0 := cx - r
		var y0 := cy - r
		var x1 := cx + r + 1
		var y1 := cy + r + 1
		if x0 < 0 or y0 < 0 or x1 > W or y1 > H:
			return 1 << 20
		return sat[y1 * SW + x1] - sat[y0 * SW + x1] - sat[y1 * SW + x0] + sat[y0 * SW + x0]
	# ---- every place a peak could stand, with the largest it could be there, by region
	var cands := {}
	for cy in range(r_min + margin, H - R_MIN - MARGIN, 3):
		for cx in range(r_min + margin, W - R_MIN - MARGIN, 3):
			if bad[cy * W + cx] == 1 or int(box.call(sat_bad, cx, cy, r_min + margin)) > 0:
				continue
			var r := r_min
			while r < R_MAX and int(box.call(sat_bad, cx, cy, r + 1 + margin)) == 0:
				r += 1
			# (somebody must be able to walk to its foot)
			if int(box.call(sat_reach, cx, cy, r + margin)) < 4:
				continue
			var o2 := owner[cy * W + cx]
			if not cands.has(o2):
				cands[o2] = []
			cands[o2].append([Vector2i(cx, cy), r])
	return cands

static func _apart(c: Array, mine: Array) -> bool:
	for m in mine:
		if Vector2((c[0] as Vector2i) - (m[0] as Vector2i)).length() < float(int(c[1]) + int(m[1]) + 6):
			return false
	return true

## Open the ground of peak `pk`: every tile it lifts is bare rock anybody may stand on, and if no
## tile of its foot can be walked to, a way is cut to the nearest that can.
static func _open(grid: PackedByteArray, W: int, H: int, pk: Dictionary, reach: Dictionary) -> void:
	var c: Vector2i = pk.c
	var r: int = pk.r
	var touches := false
	for y in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			if rise_of(pk, float(x) + 0.5, float(y) + 0.5) < 0.25:
				continue
			grid[y * W + x] = MapGen.FLOOR
			for d in MapGen.DIRS:
				if reach.has(Vector2i(x, y) + d):
					touches = true
	if touches:
		return
	var near := Vector2i(-1, -1)
	var bd := 1 << 30
	# (the place was chosen with ground that can be walked to somewhere inside this square)
	var rr := int(pk.get("r0", r)) + MARGIN
	for y2 in range(c.y - rr, c.y + rr + 1):
		for x2 in range(c.x - rr, c.x + rr + 1):
			var p := Vector2i(x2, y2)
			if reach.has(p) and (p - c).length_squared() < bd:
				bd = (p - c).length_squared()
				near = p
	if near.x < 0:
		return
	var steps := maxi(absi(near.x - c.x), absi(near.y - c.y)) * 2
	for s in steps + 1:
		var f := Vector2(near).lerp(Vector2(c), float(s) / float(maxi(steps, 1)))
		var q := Vector2i(int(round(f.x)), int(round(f.y)))
		for q2 in [q, q + Vector2i(1, 0)]:
			if q2.x >= 0 and q2.y >= 0 and q2.x < W and q2.y < H and not MapGen.is_walkable_tile(grid[q2.y * W + q2.x]):
				grid[q2.y * W + q2.x] = MapGen.FLOOR

## Stand on the peaks the people, lords and things the story puts there: written with their region in
## Data.AREAS like everybody else, with `"late": true, "peak": k` (the region's k-th highest peak) and
## `"stand": "top" | "flank" | "foot"`.  The very top tile is left for whoever climbs: a lord stands
## a step north of it, people beside him, things to find on the rock below.
static func world(grid: PackedByteArray, W: int, peaks: Array, ents: Array, layer: String, ids: Array) -> void:
	var used := {}
	for e0 in ents:
		if e0.has("pos"):
			used[e0.pos] = true
	for area in ids:
		var spec: Dictionary = Data.AREAS[area]
		var mine: Array = []
		for pk in peaks:
			if str(pk.area) == area:
				mine.append(pk)
		for kind in ["npcs", "bosses", "pickups"]:
			for d in spec.get(kind, []):
				if not d.has("peak") or mine.is_empty():
					continue
				var pk2: Dictionary = mine[mini(int(d.peak), mine.size() - 1)]
				var at := _stand(grid, W, pk2, str(d.get("stand", "top")), str(d.id), used)
				used[at] = true
				match kind:
					"npcs":
						ents.append({"kind": "npc", "id": d.id, "n": d.n, "pos": at, "col": d.col, "vis": d.get("vis", ["", ""]), "area": area, "layer": layer, "late": true})
					"bosses":
						ents.append({"kind": "boss", "id": "boss_" + str(d.id), "enemy": d.id, "pos": at, "lv": d.lv, "req": d.req, "vis": d.get("vis", ["", ""]), "area": area, "layer": layer, "late": true})
					"pickups":
						ents.append({"kind": "pickup", "id": d.id, "item": d.item, "pos": at, "vis": d.get("vis", ["", ""]), "area": area, "layer": layer, "late": true})

static func _stand(grid: PackedByteArray, W: int, pk: Dictionary, how: String, id: String, used: Dictionary) -> Vector2i:
	var c: Vector2i = pk.c
	var r: int = pk.r
	var cands: Array = []
	if how == "top":
		for d in [Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(0, -2), Vector2i(1, -2), Vector2i(-1, -2)]:
			cands.append(c + d)
	else:
		var lo := 0.3 if how == "flank" else 0.02
		var hi := 0.8 if how == "flank" else 0.12
		for y in range(c.y - r, c.y + r + 1):
			for x in range(c.x - r, c.x + r + 1):
				var k := rise_of(pk, float(x) + 0.5, float(y) + 0.5) / float(pk.h)
				if k >= lo and k <= hi and Vector2i(x, y) != c:
					cands.append(Vector2i(x, y))
		# (spread by the thing's own name, so that three things of a kind lie on three sides)
		var start := absi(hash(id)) % maxi(cands.size(), 1)
		cands = cands.slice(start) + cands.slice(0, start)
	for q in cands:
		if not used.has(q) and MapGen.is_walkable_tile(grid[q.y * W + q.x]):
			return q
	return c + Vector2i(0, -1)

# ---------------------------------------------------------------- the shape of a peak
## How far peak `pk` lifts the ground at a point (in tiles of its realm, fractional; a tile's
## middle is at +0.5): a crag with a level head, steep flanks cut by ledges and a foot that runs
## out into the land, its outline pushed in and out by two slow sines so that no peak is a cone.
static func rise_of(pk: Dictionary, fx: float, fz: float) -> float:
	var dx: float = fx - float(pk.cx)
	var dz: float = fz - float(pk.cz)
	var r: float = float(pk.r)
	var d2 := dx * dx + dz * dz
	if d2 >= r * r:
		return 0.0
	var a := atan2(dz, dx)
	var rw := r * (0.79 + 0.11 * sin(3.0 * a + float(pk.s1)) + 0.06 * sin(5.0 * a + float(pk.s2)) + 0.04 * sin(8.0 * a - float(pk.s1) * 2.0))
	var q := sqrt(d2) / rw
	if q >= 1.0:
		return 0.0
	var u := 1.0 - q
	var s := u * u * (3.0 - 2.0 * u)
	return float(pk.h) * (pow(s, 1.12) + 0.075 * sin(u * float(pk.led) * TAU + a * 2.0) * s * (1.0 - s) * 4.0)

## The peaks whose footprint may reach a point of realm data `wd`.
static func near(wd: Dictionary, fx: float, fz: float) -> Array:
	var blk: Dictionary = wd.get("peak_blk", {})
	if blk.is_empty() or fx < 0.0 or fz < 0.0:
		return []
	return blk.get(int(fz / BLK) * 4096 + int(fx / BLK), [])

## How far the mountains lift the ground at a point of realm data `wd` (metres).
static func rise(wd: Dictionary, fx: float, fz: float) -> float:
	var best := 0.0
	for pk in near(wd, fx, fz):
		best = maxf(best, rise_of(pk, fx, fz))
	return best

## ... and under the middle of a tile.
static func at(wd: Dictionary, tile: Vector2i) -> float:
	return rise(wd, float(tile.x) + 0.5, float(tile.y) + 0.5)

## The peak whose rock a tile is on ({} on the plain).
static func of_tile(wd: Dictionary, tile: Vector2i) -> Dictionary:
	var fx := float(tile.x) + 0.5
	var fz := float(tile.y) + 0.5
	for pk in near(wd, fx, fz):
		if rise_of(pk, fx, fz) > 0.25:
			return pk
	return {}

## The peak whose very top a tile is ({} anywhere else).
static func summit_at(wd: Dictionary, tile: Vector2i) -> Dictionary:
	for pk in near(wd, float(tile.x) + 0.5, float(tile.y) + 0.5):
		if pk.c == tile:
			return pk
	return {}

## The peaks of region `area` in realm data `wd`, highest first.
static func of_area(wd: Dictionary, area: String) -> Array:
	var out: Array = []
	for pk in wd.get("peaks", []):
		if str(pk.area) == area:
			out.append(pk)
	out.sort_custom(func(a, b): return float(a.h) > float(b.h))
	return out

static func by_id(wd: Dictionary, id: String) -> Dictionary:
	for pk in wd.get("peaks", []):
		if str(pk.id) == id:
			return pk
	return {}

## Whether the step from tile `a` to tile `b` (side by side) is a climb, and which way: +1 up, -1
## down, 0 a step anybody walks.
static func climb(wd: Dictionary, a: Vector2i, b: Vector2i) -> int:
	if (wd.get("peak_blk", {}) as Dictionary).is_empty():
		return 0
	var d := at(wd, b) - at(wd, a)
	return 1 if d > STEEP else (-1 if d < -STEEP else 0)

## Whether a peak of height `h` in a land of theme `theme_name` has snow on its head.
static func snowy(theme_name: String, h: float) -> bool:
	if theme_name in ["volcano", "forge", "dunes", "diyu", "abyss", "void", "chaos", "fungal"]:
		return false
	return h >= (SNOW_COLD if theme_name in ["snow", "aurora", "glacier", "frost", "mountain"] else SNOW_ANY)

# ---------------------------------------------------------------- what stands on a summit
## A cairn with a pole of prayer flags, built from code: what somebody who got to the top first
## left there.  `flags` is the colour of the cloth.
static func cairn(seed_: int, flags: Color) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var stone := Color("8a8478")
	var y := 0.0
	for i in 5:
		var s := 0.42 - i * 0.065
		var hgt := 0.2 - i * 0.012
		var off := Vector3((Terrain3D.hash2(seed_, i, 1.0) - 0.5) * 0.09, 0.0, (Terrain3D.hash2(seed_, i, 2.0) - 0.5) * 0.09)
		b.box(Vector3(0, y + hgt * 0.5, 0) + off, Vector3(s * 2.0, hgt, s * 1.7), stone.darkened(Terrain3D.hash2(seed_, i, 3.0) * 0.25), Vector3(0.0, Terrain3D.hash2(seed_, i, 4.0) * TAU, 0.0))
		y += hgt
	# the pole and its line of flags, blown out on the wind
	b.box(Vector3(0, y + 1.1, 0), Vector3(0.05, 2.2, 0.05), Color("5a4630"))
	var cols := [flags, Color("f4f0e0"), Color("d84a3a"), Color("e8b84a"), Color("3a8a5a")]
	for f in 5:
		var fy := y + 2.1 - f * 0.34
		b.box(Vector3(0.2 + 0.02 * f, fy, 0.0), Vector3(0.34, 0.24, 0.02), cols[f % cols.size()])
	MB.mesh_node(root, b.build())
	return root
