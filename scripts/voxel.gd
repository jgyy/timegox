class_name Voxel
extends RefCounted
## Voxels (the Hollow Hills release): the ground under the land is made of cubes half a metre on a
## side, so that it can be hollow.  A height field has one surface over every point and no more: no
## roof over a floor, no arch, no shaft, no stalactite.  A volume of voxels has as many as it likes,
## which is what a cave is.
##
## A volume is a box of `nx` x `ny` x `nz` cells, each empty (0) or made of something (a material + 1),
## with the span of air in every column (`lo`..`hi`) kept beside it: the mesher walks only the air and
## draws the face of every solid cell that touches it (looking outward from the hollow, never inward
## from the rock, so a cave of 600,000 cells is meshed from about 60,000), with the corners where two
## faces meet darkened (the ambient occlusion every voxel world has, here from the six neighbours the
## mesher has looked at anyway).  One surface, the toon shader's own materials: stone that has grain,
## crystal that glitters and glows, wood, earth.  It dissolves between the camera and the hero like
## every other piece of scenery, so a real roof can stay on a cave.

## the edge of a voxel in metres: four to a tile's side
const S := 0.5
const PER_TILE := 4

## what a cell is made of
const ROCK := 0       # the body of the hill
const BAND := 1       # a darker course of it (strata)
const PALE := 2       # limestone flow: stalactites, stalagmites, pillars
const EARTH := 3      # the trodden floor
const MOSS := 4       # where water drips
const SAND := 5       # the bed of a pool, the edge of a stream
const ORE := 6        # a vein
const GEM := 7        # crystal (glows)
const GLOW := 8       # glow-moss and foxfire (glows)
const WOOD := 9       # props, old shoring
const ICE := 10       # (glows faintly)
const EMBER := 11     # slag and embers (glows)
const JADE := 12      # cloud-stone of the Nine Heavens
const BONE := 13
const COAL := 14
const DAY := 15       # the daylight at the mouth of a cave (glows white)
const N_MAT := 16

## how each material is drawn: [colour, the toon shader's surface class]
static func palette(theme: Dictionary = {}) -> Array:
	var rock: Color = theme.get("rock", Color("6e6a66"))
	var band: Color = theme.get("band", rock.darkened(0.22))
	var pale: Color = theme.get("pale", Color("b8b0a0"))
	var earth: Color = theme.get("earth", Color("6a563e"))
	var gem: Color = theme.get("gem", Color("58c8e8"))
	var glow: Color = theme.get("glow", Color("7ae8a0"))
	var ore: Color = theme.get("ore", Color("c8923a"))
	return [
		[rock, MB.STONE], [band, MB.STONE], [pale, MB.STONE], [earth, MB.CLOTH], [theme.get("moss", Color("4a7a44")), MB.CLOTH], [theme.get("sand", Color("b8a878")), MB.CLOTH],
		[ore, MB.METAL], [gem, MB.CRYSTAL], [glow, MB.CRYSTAL], [Color("6a4a30"), MB.WOOD], [Color("b8e0f0"), MB.CRYSTAL],
		[Color("ff7a30"), MB.CRYSTAL], [Color("a8d8c0"), MB.STONE], [Color("e0d8c4"), MB.STONE], [Color("2a2a30"), MB.STONE],
		[Color(2.6, 2.5, 2.2), MB.CRYSTAL],
	]

## An empty volume (all rock of material `fill`, or all air if `fill` is -1).
static func make(nx: int, ny: int, nz: int, fill: int = ROCK) -> Dictionary:
	var d := PackedByteArray()
	d.resize(nx * ny * nz)
	if fill >= 0:
		d.fill(fill + 1)
	var lo := PackedInt32Array()
	var hi := PackedInt32Array()
	lo.resize(nx * nz)
	hi.resize(nx * nz)
	if fill >= 0:
		lo.fill(ny)
		hi.fill(0)
	else:
		lo.fill(0)
		hi.fill(ny)
	return {"nx": nx, "ny": ny, "nz": nz, "d": d, "lo": lo, "hi": hi}

## cell (x, y, z) is at d[(z * nx + x) * ny + y]: a column is one run of the array
static func at(vol: Dictionary, x: int, y: int, z: int) -> int:
	if x < 0 or z < 0 or y < 0 or x >= vol.nx or z >= vol.nz or y >= vol.ny:
		return 0
	return vol.d[(z * int(vol.nx) + x) * int(vol.ny) + y]

## Hollow out cells y0..y1-1 of column (x, z).
static func carve(vol: Dictionary, x: int, z: int, y0: int, y1: int) -> void:
	var nx: int = vol.nx
	var ny: int = vol.ny
	if x < 0 or z < 0 or x >= nx or z >= int(vol.nz):
		return
	y0 = maxi(y0, 0)
	y1 = mini(y1, ny)
	if y1 <= y0:
		return
	var c := z * nx + x
	var base := c * ny
	var d: PackedByteArray = vol.d
	for y in range(y0, y1):
		d[base + y] = 0
	vol.d = d
	if y0 < vol.lo[c]:
		vol.lo[c] = y0
	if y1 > vol.hi[c]:
		vol.hi[c] = y1

## Fill cells y0..y1-1 of column (x, z) with material `mat` (inside the air, a stalactite or a pillar;
## the span of air is left as it was: the mesher skips what is solid in it).
static func fill(vol: Dictionary, x: int, z: int, y0: int, y1: int, mat: int) -> void:
	var nx: int = vol.nx
	var ny: int = vol.ny
	if x < 0 or z < 0 or x >= nx or z >= int(vol.nz):
		return
	y0 = maxi(y0, 0)
	y1 = mini(y1, ny)
	var base := (z * nx + x) * ny
	var d: PackedByteArray = vol.d
	for y in range(y0, y1):
		d[base + y] = mat + 1
	vol.d = d

## Change what the solid cells y0..y1-1 of a column are made of (air stays air).
static func paint(vol: Dictionary, x: int, z: int, y0: int, y1: int, mat: int) -> void:
	var nx: int = vol.nx
	var ny: int = vol.ny
	if x < 0 or z < 0 or x >= nx or z >= int(vol.nz):
		return
	var base := (z * nx + x) * ny
	var d: PackedByteArray = vol.d
	for y in range(maxi(y0, 0), mini(y1, ny)):
		if d[base + y] != 0:
			d[base + y] = mat + 1
	vol.d = d

## The top of the highest solid cell at or below cell `from` in column (x, z), in cells (0 if none).
static func floor_under(vol: Dictionary, x: int, z: int, from: int) -> int:
	var ny: int = vol.ny
	if x < 0 or z < 0 or x >= int(vol.nx) or z >= int(vol.nz):
		return from
	var base := (z * int(vol.nx) + x) * ny
	var d: PackedByteArray = vol.d
	var y := mini(from, ny - 1)
	while y >= 0 and d[base + y] == 0:
		y -= 1
	return y + 1

static func _h(x: int, y: int, z: int) -> float:
	var n := (x * 73856093) ^ (y * 19349663) ^ (z * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xffff) / 65535.0

# the six faces: the neighbour's offset, the four corners of the face it shares with an air cell at the
# origin (counter-clockwise seen from the air), and for each corner the two neighbours of the air cell
# (as indices into the same six) whose solidity darkens it
const _DIR := [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
const _QUAD := [
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0)],
	[Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)],
	[Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1)],
	[Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1), Vector3(0, 0, 1)],
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)],
]
static var _ao_tab: Array = []
static var _flip: Array = []

## For each face: which two neighbours of the air cell touch each corner of it (their solidity darkens
## the corner), and which way round its triangles go (front faces are clockwise).
static func _tables() -> void:
	if not _ao_tab.is_empty():
		return
	for f in 6:
		var q: Array = _QUAD[f]
		var axis := f / 2
		var per: Array = []
		for k in 4:
			var pr: Array = []
			for b in 3:
				if b != axis:
					pr.append(b * 2 + (0 if (q[k] as Vector3)[b] > 0.5 else 1))
			per.append(pr)
		_ao_tab.append(per)
		var geo: Vector3 = ((q[1] as Vector3) - (q[0] as Vector3)).cross((q[2] as Vector3) - (q[0] as Vector3))
		_flip.append(geo.dot(-Vector3(_DIR[f])) > 0.0)

## The mesh of a volume: every face of a solid cell that an air cell touches, coloured by its material
## (a little different from cell to cell, darker in the corners).  `pal` is palette(); `part` (columns)
## meshes only a piece of it.
## Returns {"mesh": ArrayMesh or null, "faces": int}.
static func mesh(vol: Dictionary, pal: Array, mat: Material = null, part: Rect2i = Rect2i()) -> Dictionary:
	var nx: int = vol.nx
	var ny: int = vol.ny
	var nz: int = vol.nz
	var d: PackedByteArray = vol.d
	var lo: PackedInt32Array = vol.lo
	var hi: PackedInt32Array = vol.hi
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var cs := PackedColorArray()
	var ix := PackedInt32Array()
	var cols: Array = []
	var cls: Array = []
	for p in pal:
		cols.append(p[0])
		cls.append(p[1])
	var nv := 0
	_tables()
	var sol := [0, 0, 0, 0, 0, 0]
	var stride_x := ny
	var stride_z := nx * ny
	var px0 := 0
	var pz0 := 0
	var px1 := nx
	var pz1 := nz
	if part.size.x > 0:
		px0 = maxi(part.position.x, 0)
		pz0 = maxi(part.position.y, 0)
		px1 = mini(part.end.x, nx)
		pz1 = mini(part.end.y, nz)
	for z in range(pz0, pz1):
		for x in range(px0, px1):
			var c := z * nx + x
			var y0: int = lo[c]
			var y1: int = hi[c]
			if y1 <= y0:
				continue
			var base := c * ny
			for y in range(y0, y1):
				if d[base + y] != 0:
					continue
				# the six neighbours of this cell of air
				var i := base + y
				sol[0] = d[i + stride_x] if x + 1 < nx else 0
				sol[1] = d[i - stride_x] if x > 0 else 0
				sol[2] = d[i + 1] if y + 1 < ny else 0
				sol[3] = d[i - 1] if y > 0 else 0
				sol[4] = d[i + stride_z] if z + 1 < nz else 0
				sol[5] = d[i - stride_z] if z > 0 else 0
				if sol[0] + sol[1] + sol[2] + sol[3] + sol[4] + sol[5] == 0:
					continue
				var o := Vector3(x, y, z)
				for f in 6:
					var m: int = sol[f]
					if m == 0:
						continue
					var dv: Vector3i = _DIR[f]
					var q: Array = _QUAD[f]
					var ao: Array = _ao_tab[f]
					var col: Color = cols[m - 1]
					var jit := 0.86 + 0.24 * _h(x + dv.x, y + dv.y, z + dv.z)
					# floors read lighter than walls, walls than roofs (a light from above that is not there)
					var face_k := 1.0 if f == 3 else (0.72 if f == 2 else 0.86)
					var nrm := -Vector3(dv)
					for k in 4:
						var a: Array = ao[k]
						var dark := 1.0 - 0.2 * float((1 if sol[a[0]] != 0 else 0) + (1 if sol[a[1]] != 0 else 0))
						var kk := jit * face_k * dark
						vs.append((o + q[k]) * S)
						ns.append(nrm)
						cs.append(Color(col.r * kk, col.g * kk, col.b * kk, cls[m - 1]))
					if _flip[f]:
						ix.append(nv)
						ix.append(nv + 2)
						ix.append(nv + 1)
						ix.append(nv)
						ix.append(nv + 3)
						ix.append(nv + 2)
					else:
						ix.append(nv)
						ix.append(nv + 1)
						ix.append(nv + 2)
						ix.append(nv)
						ix.append(nv + 2)
						ix.append(nv + 3)
					nv += 4
	if nv == 0:
		return {"mesh": null, "faces": 0}
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	arr[Mesh.ARRAY_COLOR] = cs
	arr[Mesh.ARRAY_INDEX] = ix
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	out.surface_set_material(0, mat if mat != null else MB.mat_scenery_plain())
	return {"mesh": out, "faces": nv / 4}

## A free-standing thing made of voxels (a boulder, a cave mouth, a cairn): `cells` is a list of
## [Vector3i, material]; the model's origin is the middle of its footprint on the ground.
static func model(cells: Array, pal: Array, mat: Material = null) -> MeshInstance3D:
	var lo := Vector3i(1 << 20, 1 << 20, 1 << 20)
	var hi := Vector3i(-(1 << 20), -(1 << 20), -(1 << 20))
	for c in cells:
		var p: Vector3i = c[0]
		lo = Vector3i(mini(lo.x, p.x), mini(lo.y, p.y), mini(lo.z, p.z))
		hi = Vector3i(maxi(hi.x, p.x), maxi(hi.y, p.y), maxi(hi.z, p.z))
	var mi := MeshInstance3D.new()
	if cells.is_empty():
		return mi
	# a cell of air all round, so that every outside face has an air cell to be seen from
	var sz := hi - lo + Vector3i(3, 2, 3)
	var vol := make(sz.x, sz.y, sz.z, -1)
	var dd: PackedByteArray = vol.d
	for c2 in cells:
		var p2: Vector3i = c2[0] - lo + Vector3i(1, 0, 1)
		dd[(p2.z * sz.x + p2.x) * sz.y + p2.y] = int(c2[1]) + 1
	vol.d = dd
	var res := mesh(vol, pal, mat)
	mi.mesh = res.mesh
	mi.position = Vector3(-(1 - lo.x) * S, lo.y * S, -(1 - lo.z) * S)
	return mi
