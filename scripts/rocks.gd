class_name Rocks
extends RefCounted
## Procedural rocks.  Each rock starts as a subdivided icosahedron (an even, round mesh) and is pushed
## in and out by layered 3D noise.  Shape recipes then squash, stretch or erode it:
##   boulder  rounded lump, flat underside
##   slab     wide, thin and tilted (river stones, flagstones of the old world)
##   spire    tall and tapering with wind-cut flutes
##   karst    limestone tower with vertical solution grooves and a crown of shrubs (Part VI)
##   scree    small sharp chips for slopes and path edges
##   crystal  hard faceted geodes (void, origin, chaos)
## Colours come from the region: a darker tone in the crevices (noise valleys), lighter on the
## exposed bumps, and a "cover" layer on top-facing faces: moss in green regions, snow in frozen
## ones, sand in the desert, ash in the volcano.  Several variants per recipe are cached.

const VARIANTS := 6
static var _cache := {}
static var _ico_cache := {}

## [base colour, cover colour, cover amount] per ground style
static func palette(th: Dictionary, theme_name: String = "") -> Array:
	var wall: Color = th.wall
	var base: Color = Color(th.g1).lerp(Color("8a8a88"), 0.65).lerp(wall, 0.12)
	var cover := Color(th.g2).darkened(0.1)
	var amount := 0.45
	match str(th.tex) if theme_name != "karst" else "karst":
		"snow", "permafrost":
			base = Color("7a8898")
			cover = Color("f4f8ff")
			amount = 0.7
		"sand":
			base = Color(th.g1).darkened(0.25).lerp(Color("b08a60"), 0.4)
			cover = Color(th.g2).lightened(0.1)
			amount = 0.35
		"ash":
			base = Color("3a302c")
			cover = Color("5a4a44")
			amount = 0.25
		"rock":
			base = Color(th.wall).lerp(Color("6a6870"), 0.6)
			cover = Color(th.g2)
			amount = 0.15
		"crystal", "nebula":
			base = Color(th.wall).lerp(Color("302848"), 0.5)
			cover = Color(th.wall).lightened(0.3)
			amount = 0.2
		"moss":
			base = Color("3a3448")
			cover = Color(th.wall).lerp(Color("50c0a0"), 0.5)
			amount = 0.55
		"marble", "tile", "glass":
			base = Color(th.path).lerp(Color("c8c4c0"), 0.4)
			cover = Color(th.g2)
			amount = 0.12
		"mud":
			base = Color("5a5248")
			cover = Color(th.g2).darkened(0.1)
			amount = 0.5
		"leaves":
			base = Color("7a746a")
			cover = Color("c86a38")
			amount = 0.45
		"karst":
			base = Color("a8a8a0")
			cover = Color("4a8a50")
			amount = 0.5
		"lilyfield":
			base = Color("6a5a58")
			cover = Color("9a3a30")
			amount = 0.3
		"underworld":
			base = Color("3a3a48")
			cover = Color("4a6a80")
			amount = 0.2
	return [base, cover, amount]

static func mesh(kind: String, variant: int, theme_name: String) -> ArrayMesh:
	var key := "%s#%d#%s" % [kind, variant, theme_name]
	if _cache.has(key):
		return _cache[key]
	var th := Look.theme(theme_name)
	var pal := palette(th, theme_name)
	var b := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) * 13 + variant * 101 + 7
	match kind:
		"boulder":
			_rock(b, rng, Vector3(1.0, 0.72, 0.9) * rng.randf_range(0.8, 1.2), 0.32, pal, 2, 0.0)
		"slab":
			_rock(b, rng, Vector3(1.3, 0.35, 1.0) * rng.randf_range(0.8, 1.2), 0.18, pal, 2, rng.randf_range(-0.25, 0.25))
		"spire":
			_rock(b, rng, Vector3(0.55, 1.8, 0.5) * rng.randf_range(0.8, 1.2), 0.25, pal, 2, 0.0, true)
		"scree":
			_rock(b, rng, Vector3(0.35, 0.22, 0.3) * rng.randf_range(0.7, 1.3), 0.4, pal, 1, 0.0)
		"karst":
			_karst(b, rng, pal)
		"crystal":
			_geode(b, rng, th)
		"pebbles":
			for i in rng.randi_range(5, 9):
				var a := rng.randf() * TAU
				var sub := MB.new()
				_rock(sub, rng, Vector3(0.12, 0.07, 0.1) * rng.randf_range(0.6, 1.5), 0.3, pal, 1, 0.0)
				b.merge(sub, Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)), Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * 0.6))
	var m := b.build(MB.mat_vc() if kind in ["boulder", "spire", "karst", "slab", "crystal"] else MB.mat_plain())
	_cache[key] = m
	return m

## unit icosphere subdivided `level` times: [vertices, triangle indices]
static func _ico(level: int) -> Array:
	if _ico_cache.has(level):
		return _ico_cache[level]
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i in verts.size():
		verts[i] = (verts[i] as Vector3).normalized()
	var faces: Array = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for l in level:
		var mids := {}
		var nf: Array = []
		for f in faces:
			var m: Array = []
			for e in 3:
				var a: int = f[e]
				var bb: int = f[(e + 1) % 3]
				var k := Vector2i(mini(a, bb), maxi(a, bb))
				if not mids.has(k):
					verts.append(((verts[a] as Vector3) + (verts[bb] as Vector3)).normalized())
					mids[k] = verts.size() - 1
				m.append(mids[k])
			nf.append([f[0], m[0], m[2]])
			nf.append([f[1], m[1], m[0]])
			nf.append([f[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		faces = nf
	_ico_cache[level] = [verts, faces]
	return [verts, faces]

## Displace an icosphere into a rock and append it to `b` (smooth normals from the displaced faces).
static func _rock(b: MB, rng: RandomNumberGenerator, size: Vector3, rough: float, pal: Array, level: int, tilt: float, flutes: bool = false) -> void:
	var ico := _ico(level)
	var src: Array = ico[0]
	var faces: Array = ico[1]
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 1.1
	noise.fractal_octaves = 3
	var fine := FastNoiseLite.new()
	fine.seed = rng.randi()
	fine.frequency = 3.5
	var pts: Array = []
	var depth: Array = []
	var rot := Basis.from_euler(Vector3(tilt, rng.randf() * TAU, tilt * 0.5))
	for p in src:
		var q: Vector3 = p
		var n1 := noise.get_noise_3dv(q * 1.3)
		var n2 := fine.get_noise_3dv(q * 2.0)
		var disp := 1.0 + n1 * rough + n2 * rough * 0.35
		if flutes:
			disp += sin(atan2(q.z, q.x) * 7.0 + n1 * 2.0) * 0.06
		# a flattened underside so the rock sits on the ground
		var y := q.y
		if y < -0.35:
			y = -0.35 - (y + 0.35) * 0.25
		var r := Vector3(q.x * disp, y * disp, q.z * disp) * size
		if flutes:
			r.x *= 1.0 - maxf(r.y, 0.0) / (size.y * 1.6)
			r.z *= 1.0 - maxf(r.y, 0.0) / (size.y * 1.6)
		pts.append(rot * r + Vector3(0, size.y * 0.3, 0))
		depth.append(n1)
	# smooth normals
	var nrm: Array = []
	nrm.resize(pts.size())
	for i in pts.size():
		nrm[i] = Vector3.ZERO
	for f in faces:
		var a: Vector3 = pts[f[0]]
		var fn := ((pts[f[1]] as Vector3) - a).cross((pts[f[2]] as Vector3) - a)
		for k in 3:
			nrm[f[k]] += fn
	var base: Color = pal[0]
	var cover: Color = pal[1]
	var amount: float = pal[2]
	var start := b.v.size()
	for i in pts.size():
		var nn: Vector3 = (nrm[i] as Vector3).normalized()
		var dd: float = depth[i]
		var col := base.darkened(clampf(-dd * 0.9, 0.0, 0.35)).lightened(clampf(dd * 0.4, 0.0, 0.15))
		var top := smoothstep(0.55 - amount * 0.5, 0.95 - amount * 0.4, nn.y + dd * 0.3)
		col = col.lerp(cover, top * amount * 1.4)
		# soil line: the base of the rock is darker where it meets the ground
		var py: float = (pts[i] as Vector3).y
		col = col.darkened(clampf(0.25 - py * 0.6, 0.0, 0.25))
		var lc := col.srgb_to_linear()
		lc.a = MB.STONE
		b.v.append(pts[i])
		b.n.append(nn)
		b.c.append(lc)
	for f in faces:
		# icosphere faces are counter-clockwise from outside; Godot's front faces are clockwise
		b.idx.append_array([start + f[0], start + f[2], start + f[1]])

## Limestone tower: stacked, fluted rock drums narrowing upward, a cave notch at the foot and a
## few shrubs clinging to the ledges.
static func _karst(b: MB, rng: RandomNumberGenerator, pal: Array) -> void:
	var h := rng.randf_range(5.0, 9.0)
	var drums := rng.randi_range(3, 5)
	var y := 0.0
	var w := rng.randf_range(1.2, 1.7)
	for i in drums:
		var dh := h / drums * rng.randf_range(0.9, 1.25)
		var sub := MB.new()
		_rock(sub, rng, Vector3(w, dh * 0.62, w * rng.randf_range(0.8, 1.0)), 0.2, pal, 2, 0.0, true)
		b.merge(sub, Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)), Vector3(rng.randf_range(-0.2, 0.2), y, rng.randf_range(-0.2, 0.2))))
		y += dh * 0.72
		w *= rng.randf_range(0.7, 0.85)
	# tufts of green on the ledges
	var green: Color = pal[1]
	for i in rng.randi_range(3, 6):
		var a := rng.randf() * TAU
		var yy := rng.randf_range(0.3, 0.95) * y
		var rr := 1.0 - yy / maxf(y, 1.0) * 0.6
		b.sph(Vector3(cos(a) * rr * 1.1, yy, sin(a) * rr * 1.1), Vector3(0.45, 0.25, 0.4) * rng.randf_range(0.7, 1.3), MB.tag(green.lerp(Color("3a6a3a"), rng.randf() * 0.5), MB.FOLIAGE), Vector3.ZERO, true)
	b.sph(Vector3(0, y + 0.1, 0), Vector3(w * 1.1, 0.4, w), MB.tag(green, MB.FOLIAGE), Vector3.ZERO, true)

static func _geode(b: MB, rng: RandomNumberGenerator, th: Dictionary) -> void:
	var col: Color = Color(th.wall).lightened(0.2)
	var sub := MB.new()
	_rock(sub, rng, Vector3(0.7, 0.45, 0.6), 0.3, [Color(th.wall).lerp(Color("302838"), 0.6), Color(th.wall), 0.1], 1, 0.0)
	b.merge(sub)
	for i in rng.randi_range(4, 7):
		var a := rng.randf() * TAU
		b.crystal(Vector3(cos(a) * 0.35, 0.35, sin(a) * 0.35), rng.randf_range(0.08, 0.16), rng.randf_range(0.5, 1.2), MB.tag(col.lerp(Color.WHITE, rng.randf() * 0.3), MB.CRYSTAL), Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5), 6)
