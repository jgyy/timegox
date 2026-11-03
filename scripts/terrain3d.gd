class_name Terrain3D
extends RefCounted
## Builds the 3D terrain of an area from its tile grid: coloured ground, animated water,
## theme-specific landmarks (trees, crystals, pillars...), decorations and sect buildings.

const T := 2.0          # world units per tile
const CH := 12          # tiles per render chunk

static var _water_mats := {}
static var _protos := {}

static func world_pos(tile: Vector2i) -> Vector3:
	return Vector3((tile.x + 0.5) * T, 0.0, (tile.y + 0.5) * T)

static func hash2(x: int, y: int, salt: float = 0.0) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + salt * 37.719) * 43758.5453, 1.0)

static func _water_mat(col: Color, glow: float) -> ShaderMaterial:
	var key := "%s_%f" % [col.to_html(), glow]
	if _water_mats.has(key):
		return _water_mats[key]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 col : source_color = vec4(0.2, 0.4, 0.8, 0.8);
uniform float glow = 0.0;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float w = sin(wp.x * 2.3 + TIME * 1.4) * sin(wp.z * 2.1 + TIME * 1.1) + 0.5 * sin((wp.x + wp.z) * 4.0 - TIME * 2.0);
	ALBEDO = col.rgb + vec3(w * 0.06);
	ALPHA = col.a;
	ROUGHNESS = 0.12;
	METALLIC = 0.3;
	EMISSION = col.rgb * glow * (0.7 + 0.3 * w);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("col", Color(col.r, col.g, col.b, 0.82))
	m.set_shader_parameter("glow", glow)
	_water_mats[key] = m
	return m

# ---------------------------------------------------------------- main entry
static func build(grid: PackedByteArray, w: int, h: int, theme_name: String, seed_: int) -> Node3D:
	var th := Look.theme(theme_name)
	var root := Node3D.new()
	root.name = "terrain_" + theme_name
	var cw := int(ceil(w / float(CH)))
	var chh := int(ceil(h / float(CH)))
	var wall_proto := _proto("wall:" + theme_name, theme_name)
	var decor_proto := _proto("decor:" + theme_name, theme_name)
	var lily_proto: Mesh = null
	if theme_name == "sect":
		lily_proto = _proto("lily:" + theme_name, theme_name)
	var water_glow := 1.1 if theme_name in ["volcano", "time", "void", "origin", "abyss"] else 0.0
	var wmat := _water_mat(th.water, water_glow)
	for cy in chh:
		for cx in cw:
			var ground := MB.new()
			var water := MB.new()
			var wall_x: Array = []
			var wall_c: Array = []
			var dec_x: Array = []
			var dec_c: Array = []
			var lily_x: Array = []
			var lily_c: Array = []
			for ty in range(cy * CH, mini(h, (cy + 1) * CH)):
				for tx in range(cx * CH, mini(w, (cx + 1) * CH)):
					var tile := grid[ty * w + tx]
					var x0 := tx * T
					var z0 := ty * T
					var hv := hash2(tx, ty)
					var patch := 0.5 + 0.5 * sin(tx * 0.31 + sin(ty * 0.23) * 2.0) * cos(ty * 0.27 + tx * 0.05)
					var gcol: Color = Color(th.g1).lerp(Color(th.g2), patch).darkened(hv * 0.07)
					match tile:
						MapGen.PATH:
							var pc: Color = Color(th.path).darkened(hv * 0.1)
							ground.quad(x0, z0, x0 + T, z0 + T, 0.015, pc)
							if hv > 0.7:
								ground.quad(x0 + 0.3, z0 + 0.3, x0 + 0.9, z0 + 0.9, 0.03, pc.lightened(0.12))
						MapGen.WATER:
							var bed: Color = Color(th.water).darkened(0.55)
							ground.quad(x0, z0, x0 + T, z0 + T, -0.45, bed)
							water.quad(x0, z0, x0 + T, z0 + T, -0.1, Color.WHITE)
							_water_sides(ground, grid, w, h, tx, ty, th)
							if lily_proto != null and hv > 0.74:
								lily_x.append(Transform3D(Basis.from_euler(Vector3(0, hv * TAU, 0)), Vector3(x0 + T * 0.5, -0.08, z0 + T * 0.5)))
								lily_c.append(Color.WHITE)
						_:
							ground.quad(x0, z0, x0 + T, z0 + T, 0.0, gcol)
							if tile == MapGen.DECOR and decor_proto != null:
								var ox := (hash2(tx, ty, 1.0) - 0.5) * 1.2
								var oz := (hash2(tx, ty, 2.0) - 0.5) * 1.2
								var s := 0.8 + hash2(tx, ty, 3.0) * 0.6
								dec_x.append(Transform3D(Basis.from_euler(Vector3(0, hv * TAU, 0)).scaled(Vector3(s, s, s)), Vector3(x0 + T * 0.5 + ox, 0.0, z0 + T * 0.5 + oz)))
								dec_c.append(Color.WHITE.darkened(hash2(tx, ty, 4.0) * 0.25))
							elif tile == MapGen.WALL and wall_proto != null:
								var s2 := 0.85 + hash2(tx, ty, 5.0) * 0.55
								var sy := s2 * (0.9 + hash2(tx, ty, 6.0) * 0.4)
								var b2 := Basis.from_euler(Vector3((hash2(tx, ty, 7.0) - 0.5) * 0.12, hv * TAU, (hash2(tx, ty, 8.0) - 0.5) * 0.12)).scaled(Vector3(s2, sy, s2))
								wall_x.append(Transform3D(b2, Vector3(x0 + T * 0.5 + (hash2(tx, ty, 9.0) - 0.5) * 0.5, 0.0, z0 + T * 0.5 + (hash2(tx, ty, 10.0) - 0.5) * 0.5)))
								wall_c.append(Color.WHITE.darkened(hash2(tx, ty, 11.0) * 0.3))
			if not ground.is_empty():
				var gi := MB.mesh_node(root, ground.build())
				gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not water.is_empty():
				var wi := MB.mesh_node(root, water.build(wmat))
				wi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not wall_x.is_empty():
				_add_mm(root, wall_proto, wall_x, wall_c, true, 90.0)
			if not dec_x.is_empty():
				_add_mm(root, decor_proto, dec_x, dec_c, false, 45.0)
			if not lily_x.is_empty():
				_add_mm(root, lily_proto, lily_x, lily_c, false, 60.0)
	# endless ground beyond the map border so the horizon is never empty
	var skirt := MB.new()
	var gm: Color = Color(th.g1).darkened(0.35)
	var big := 90.0
	skirt.quad(-big, -big, w * T + big, 0.0, -0.02, gm)
	skirt.quad(-big, h * T, w * T + big, h * T + big, -0.02, gm)
	skirt.quad(-big, 0.0, 0.0, h * T, -0.02, gm)
	skirt.quad(w * T, 0.0, w * T + big, h * T, -0.02, gm)
	var si := MB.mesh_node(root, skirt.build())
	si.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if theme_name == "sect":
		_sect_buildings(root, grid, w, h, th)
	return root

static func _water_sides(ground: MB, grid: PackedByteArray, w: int, h: int, tx: int, ty: int, th: Dictionary) -> void:
	var side: Color = Color(th.g1).darkened(0.35)
	var x0 := tx * T
	var z0 := ty * T
	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for d in dirs:
		var nx: int = tx + d.x
		var ny: int = ty + d.y
		if nx < 0 or ny < 0 or nx >= w or ny >= h:
			continue
		if grid[ny * w + nx] == MapGen.WATER:
			continue
		var a: Vector3
		var b: Vector3
		if d == Vector2i(0, -1):
			a = Vector3(x0, 0, z0)
			b = Vector3(x0 + T, 0, z0)
		elif d == Vector2i(1, 0):
			a = Vector3(x0 + T, 0, z0)
			b = Vector3(x0 + T, 0, z0 + T)
		elif d == Vector2i(0, 1):
			a = Vector3(x0 + T, 0, z0 + T)
			b = Vector3(x0, 0, z0 + T)
		else:
			a = Vector3(x0, 0, z0 + T)
			b = Vector3(x0, 0, z0)
		var dn := Vector3(0, -0.45, 0)
		ground.quad4(a, b, b + dn, a + dn, side, side, side.darkened(0.3), side.darkened(0.3))

static func _add_mm(root: Node3D, mesh: Mesh, xf: Array, cols: Array, shadow: bool, vis_end: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = vis_end
	mi.visibility_range_end_margin = 6.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	root.add_child(mi)

# ---------------------------------------------------------------- landmark prototypes
static func _proto(key: String, theme_name: String) -> Mesh:
	if _protos.has(key):
		return _protos[key]
	var th := Look.theme(theme_name)
	var parts := key.split(":")
	var b := MB.new()
	var wc: Color = th.wall
	var glow := MB.new()
	var mat: Material = null
	if parts[0] == "wall":
		_build_landmark(b, glow, th.tree, wc, th)
	elif parts[0] == "decor":
		_build_decor(b, glow, th.decor, th)
	elif parts[0] == "lily":
		b.cone(Vector3(0, 0.05, 0), 0.4, 0.04, Color("2f8a4a"), Vector3.ZERO, 14)
		b.ball(Vector3(0, 0.12, 0), 0.14, Color("ff9ac8"), true)
		b.cone(Vector3(0, 0.2, 0), 0.1, 0.18, Color("ffd0e8"))
	var mesh := b.build(mat)
	if not glow.is_empty():
		# merge glow into the same mesh as a second surface
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = glow.v
		arr[Mesh.ARRAY_NORMAL] = glow.n
		arr[Mesh.ARRAY_COLOR] = glow.c
		arr[Mesh.ARRAY_INDEX] = glow.idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, MB.mat_glow())
	_protos[key] = mesh
	return mesh

static func _build_landmark(b: MB, g: MB, kind: String, wc: Color, th: Dictionary) -> void:
	var dark := wc.darkened(0.4)
	var light := wc.lightened(0.3)
	match kind:
		"pine":
			b.cyl(Vector3(0, 0.5, 0), 0.13, 1.0, Color("6a4a2a"))
			b.cone(Vector3(0, 1.4, 0), 0.8, 1.3, wc)
			b.cone(Vector3(0, 2.1, 0), 0.62, 1.1, wc.lightened(0.08))
			b.cone(Vector3(0, 2.75, 0), 0.42, 0.95, wc.lightened(0.16))
		"bamboo":
			for i in 5:
				var a := i * 1.256
				var px := cos(a) * 0.32
				var pz := sin(a) * 0.32
				var hh := 4.0 + (i % 3) * 0.7
				b.cyl(Vector3(px, hh * 0.5, pz), 0.065, hh, wc.lerp(Color("c8e070"), 0.25), Vector3((pz) * 0.03, 0, -(px) * 0.03))
				for k in range(1, 5):
					b.cyl(Vector3(px, hh * k / 5.0, pz), 0.085, 0.05, wc.darkened(0.3))
				b.sph(Vector3(px, hh - 0.2, pz), Vector3(0.45, 0.14, 0.2), light, Vector3(0, a, 0.2), true)
				b.sph(Vector3(px, hh - 0.7, pz), Vector3(0.4, 0.12, 0.18), wc.lightened(0.12), Vector3(0, a + 1.6, -0.2), true)
		"mangrove":
			b.cyl(Vector3(0, 1.2, 0), 0.2, 2.4, Color("4a3a30"), Vector3(0.08, 0, 0.12))
			for i in 4:
				var a2 := i * 1.57 + 0.4
				b.cyl(Vector3(cos(a2) * 0.5, 0.55, sin(a2) * 0.5), 0.07, 1.3, Color("3a2c26"), Vector3(sin(a2) * 0.5, 0, -cos(a2) * 0.5))
			b.sph(Vector3(0, 2.7, 0), Vector3(1.1, 0.55, 1.1), Color("4a5a3a"))
			b.sph(Vector3(0.5, 2.4, 0.3), Vector3(0.7, 0.4, 0.7), Color("5a6a44"))
			for i in 5:
				var a3 := i * 1.25
				b.cyl(Vector3(cos(a3) * 0.8, 2.0, sin(a3) * 0.8), 0.025, 1.1, Color("6a7a4a"))
		"ice":
			b.sph(Vector3(0, 0.15, 0), Vector3(0.8, 0.28, 0.8), Color("f0f6ff"))
			b.cone(Vector3(0, 1.3, 0), 0.38, 2.4, wc.lightened(0.2), Vector3(0.05, 0, 0.08), 4)
			b.cone(Vector3(0.45, 0.9, 0.1), 0.28, 1.6, wc.lightened(0.4), Vector3(0.1, 0, -0.4), 4)
			b.cone(Vector3(-0.4, 0.8, -0.1), 0.26, 1.4, wc, Vector3(-0.1, 0, 0.45), 4)
			g.cone(Vector3(0, 1.3, 0), 0.45, 2.5, Color(0.7, 0.9, 1.0, 0.12), Vector3(0.05, 0, 0.08), 4)
		"crag":
			b.box(Vector3(0, 0.6, 0), Vector3(1.3, 1.2, 1.1), wc, Vector3(0, 0.3, 0))
			b.box(Vector3(0.1, 1.5, 0), Vector3(0.9, 1.2, 0.8), wc.lightened(0.1), Vector3(0.1, 0.8, 0.1))
			b.box(Vector3(-0.1, 2.3, 0.05), Vector3(0.5, 0.9, 0.5), wc.lightened(0.18), Vector3(-0.1, 1.2, 0.15))
			g.box(Vector3(0.0, 1.0, 0.56), Vector3(0.05, 0.9, 0.03), Color(0.7, 0.8, 1.0, 0.9), Vector3(0, 0, 0.3))
		"obelisk":
			b.box(Vector3(0, 0.15, 0), Vector3(1.2, 0.3, 1.2), dark)
			b.prim("fr8", MB._xf(Vector3(0, 1.7, 0), Vector3(0.9, 3.0, 0.9), Vector3(0, PI / 4, 0)), wc.lightened(0.05))
			b.cone(Vector3(0, 3.5, 0), 0.32, 0.5, wc.lightened(0.15), Vector3.ZERO, 4)
			g.ball(Vector3(0, 4.1, 0), 0.18, Color(1.0, 0.25, 0.3, 1.0), true)
			g.ball(Vector3(0, 4.1, 0), 0.45, Color(1.0, 0.2, 0.3, 0.3), true)
		"coral":
			var cols := [Color("ff7a8a"), Color("ffa05a"), Color("5ae0c8"), Color("c88aff")]
			for i in 6:
				var a4 := i * 1.05
				var cc: Color = cols[i % 4]
				b.cone(Vector3(cos(a4) * 0.35, 0.9, sin(a4) * 0.35), 0.17, 1.8 - (i % 3) * 0.3, cc, Vector3(sin(a4) * 0.5, 0, -cos(a4) * 0.5))
				b.ball(Vector3(cos(a4) * 0.65, 1.6 - (i % 3) * 0.3, sin(a4) * 0.65), 0.14, cc.lightened(0.25), true)
			b.sph(Vector3(0, 0.15, 0), Vector3(0.9, 0.3, 0.9), Color("a8906a"))
			g.ball(Vector3(0, 1.0, 0), 1.1, Color(0.4, 0.9, 0.9, 0.07), true)
		"spire":
			b.cone(Vector3(0, 1.6, 0), 0.7, 3.2, wc.lightened(0.05), Vector3(0.05, 0, 0.04), 8)
			b.cone(Vector3(0.7, 0.9, 0.2), 0.4, 1.8, wc, Vector3(0, 0, -0.3), 8)
			b.cone(Vector3(-0.6, 0.7, -0.2), 0.35, 1.4, wc.darkened(0.1), Vector3(0, 0, 0.35), 8)
			g.box(Vector3(0.0, 0.8, 0.5), Vector3(0.1, 1.3, 0.04), Color(1.0, 0.5, 0.1, 0.95), Vector3(0.1, 0, 0.1))
			g.box(Vector3(0.3, 1.8, 0.2), Vector3(0.07, 0.9, 0.04), Color(1.0, 0.6, 0.15, 0.9), Vector3(0, 0.6, 0.2))
		"shard":
			b.box(Vector3(0, 0.15, 0), Vector3(0.9, 0.3, 0.9), dark, Vector3(0, 0.5, 0))
			b.cone(Vector3(0, 2.3, 0), 0.5, 1.5, Color("8a5ae8"), Vector3.ZERO, 4)
			b.cone(Vector3(0, 1.45, 0), 0.5, 1.5, Color("6a3ac8"), Vector3(PI, 0, 0), 4)
			g.cone(Vector3(0, 2.3, 0), 0.62, 1.6, Color(0.7, 0.5, 1.0, 0.18), Vector3.ZERO, 4)
			g.cone(Vector3(0, 1.45, 0), 0.62, 1.6, Color(0.7, 0.5, 1.0, 0.18), Vector3(PI, 0, 0), 4)
		"column":
			b.box(Vector3(0, 0.15, 0), Vector3(1.0, 0.3, 1.0), Color("f2eefc"))
			b.cyl(Vector3(0, 1.8, 0), 0.3, 3.0, Color("f8f4ff"), Vector3.ZERO, 14)
			b.cyl(Vector3(0, 1.0, 0), 0.34, 0.12, Color("e8c860"), Vector3.ZERO, 14)
			b.cyl(Vector3(0, 3.1, 0), 0.34, 0.12, Color("e8c860"), Vector3.ZERO, 14)
			b.box(Vector3(0, 3.45, 0), Vector3(0.9, 0.22, 0.9), Color("f2eefc"))
			g.ball(Vector3(0, 0.3, 0), 0.9, Color(1, 1, 1, 0.12), true)
		"mirrorpane":
			b.box(Vector3(0, 0.12, 0), Vector3(1.4, 0.24, 0.5), Color("3a5a78"))
			b.box(Vector3(0, 1.9, 0), Vector3(1.2, 3.4, 0.1), Color("d8f0ff"), Vector3(0.04, 0.2, 0.0))
			b.box(Vector3(0.1, 1.9, 0.0), Vector3(1.28, 3.5, 0.06), Color("4a6a88"), Vector3(0.04, 0.2, 0.0))
			g.box(Vector3(0, 1.9, 0.07), Vector3(1.05, 3.2, 0.03), Color(0.7, 0.92, 1.0, 0.45), Vector3(0.04, 0.2, 0.0))
			g.box(Vector3(0.0, 3.4, 0.05), Vector3(1.0, 0.04, 0.04), Color(1, 1, 1, 0.9), Vector3(0.04, 0.2, 0.0))
		"tombstone":
			b.box(Vector3(0, 0.15, 0), Vector3(1.0, 0.3, 0.6), dark)
			b.box(Vector3(0, 0.95, 0), Vector3(0.7, 1.3, 0.22), wc.lightened(0.1))
			b.cyl(Vector3(0, 1.6, 0), 0.35, 0.22, wc.lightened(0.1), Vector3(PI / 2, 0, 0), 14)
			b.box(Vector3(0, 1.0, 0.13), Vector3(0.1, 0.55, 0.04), dark)
			b.box(Vector3(0, 1.1, 0.13), Vector3(0.36, 0.09, 0.04), dark)
			g.ball(Vector3(0, 0.4, 0.4), 0.14, Color(0.6, 0.9, 1.0, 0.5), true)
		"gear":
			b.cyl(Vector3(0, 1.4, 0), 0.22, 2.8, Color("8a6a30"), Vector3.ZERO, 14)
			b.cyl(Vector3(0, 0.12, 0), 0.65, 0.24, Color("6a4a20"), Vector3.ZERO, 14)
			for ring in 2:
				var yy := 1.0 + ring * 1.2
				b.torus(Vector3(0, yy, 0), 0.8 - ring * 0.12, 0.09, Color("d8a848"))
				for i in 10:
					var a5 := TAU * i / 10.0 + ring * 0.3
					b.box(Vector3(cos(a5) * (0.82 - ring * 0.12), yy, sin(a5) * (0.82 - ring * 0.12)), Vector3(0.18, 0.12, 0.18), Color("e8b858"), Vector3(0, -a5, 0))
			g.cyl(Vector3(0, 2.9, 0), 0.4, 0.06, Color(1.0, 0.85, 0.4, 0.8), Vector3(PI / 2, 0, 0), 14)
		"monolith":
			b.box(Vector3(0, 0.2, 0), Vector3(1.4, 0.4, 1.4), Color("c8bcd8"))
			b.prim("fr8", MB._xf(Vector3(0, 2.2, 0), Vector3(1.1, 3.6, 0.7), Vector3.ZERO), Color("f4eefc"))
			g.box(Vector3(0, 2.2, 0.36), Vector3(0.08, 2.4, 0.03), Color(1.0, 0.85, 0.4, 0.95))
			g.box(Vector3(0, 2.8, 0.36), Vector3(0.5, 0.06, 0.03), Color(1.0, 0.85, 0.4, 0.95))
			g.box(Vector3(0, 1.6, 0.36), Vector3(0.36, 0.06, 0.03), Color(1.0, 0.85, 0.4, 0.95))
			g.torus(Vector3(0, 4.3, 0), 0.5, 0.04, Color(1.0, 0.9, 0.6, 0.9))
		_:
			b.sph(Vector3(0, 0.9, 0), Vector3(0.8, 0.9, 0.8), wc)

static func _build_decor(b: MB, g: MB, kind: String, th: Dictionary) -> void:
	var gc: Color = Color(th.g2).lightened(0.15)
	match kind:
		"flower":
			for i in 3:
				var a := i * 2.1
				b.cyl(Vector3(cos(a) * 0.2, 0.2, sin(a) * 0.2), 0.012, 0.4, Color("4a9a50"))
				b.ball(Vector3(cos(a) * 0.2, 0.42, sin(a) * 0.2), 0.07, [Color("ff9ac8"), Color("ffe080"), Color("ffffff")][i], true)
		"grass":
			for i in 5:
				var a2 := i * 1.26
				b.cone(Vector3(cos(a2) * 0.12, 0.2, sin(a2) * 0.12), 0.04, 0.45, gc, Vector3(sin(a2) * 0.25, 0, -cos(a2) * 0.25), 4)
		"reed":
			for i in 4:
				var a3 := i * 1.57
				b.cyl(Vector3(cos(a3) * 0.15, 0.5, sin(a3) * 0.15), 0.02, 1.0, Color("7a6a3a"))
				b.cyl(Vector3(cos(a3) * 0.15, 1.02, sin(a3) * 0.15), 0.05, 0.2, Color("5a3a22"))
		"snowrock":
			b.sph(Vector3(0, 0.12, 0), Vector3(0.35, 0.2, 0.3), Color("f4f8ff"), Vector3.ZERO, true)
			b.sph(Vector3(0.2, 0.08, 0.1), Vector3(0.2, 0.14, 0.18), Color("dce8f8"), Vector3.ZERO, true)
		"pebble":
			b.sph(Vector3(0, 0.1, 0), Vector3(0.3, 0.16, 0.24), Color("6a6878"), Vector3.ZERO, true)
			b.sph(Vector3(0.25, 0.07, 0.1), Vector3(0.16, 0.1, 0.14), Color("5a5868"), Vector3.ZERO, true)
		"bones":
			b.cyl(Vector3(0, 0.08, 0), 0.04, 0.6, Color("e8e0cc"), Vector3(0, 0, PI / 2))
			b.cyl(Vector3(0.1, 0.08, 0.15), 0.035, 0.5, Color("d8d0bc"), Vector3(0, 0.9, PI / 2))
			b.ball(Vector3(-0.2, 0.14, -0.1), 0.12, Color("f0e8d4"), true)
		"shell":
			b.cone(Vector3(0, 0.15, 0), 0.2, 0.3, Color("ffb8c0"), Vector3.ZERO, 8)
			b.ball(Vector3(0.2, 0.08, 0.1), 0.1, Color("ffe8d0"), true)
		"ember":
			b.sph(Vector3(0, 0.1, 0), Vector3(0.3, 0.16, 0.26), Color("2a1410"), Vector3.ZERO, true)
			g.ball(Vector3(0, 0.2, 0), 0.07, Color(1.0, 0.6, 0.2, 1.0), true)
			g.ball(Vector3(0, 0.2, 0), 0.2, Color(1.0, 0.4, 0.1, 0.3), true)
		"starcrystal":
			b.cone(Vector3(0, 0.3, 0), 0.12, 0.6, Color("9a6aff"), Vector3(0.1, 0, 0.1), 4)
			b.cone(Vector3(0.2, 0.2, 0.1), 0.08, 0.4, Color("b890ff"), Vector3(0.2, 0, -0.4), 4)
			g.ball(Vector3(0, 0.35, 0), 0.3, Color(0.7, 0.5, 1.0, 0.2), true)
		"cloudpuff":
			b.ball(Vector3(0, 0.15, 0), 0.28, Color(1, 1, 1), true)
			b.ball(Vector3(0.25, 0.1, 0.05), 0.2, Color(0.97, 0.97, 1.0), true)
			b.ball(Vector3(-0.22, 0.1, -0.05), 0.2, Color(0.97, 0.97, 1.0), true)
		"glassshard":
			b.cone(Vector3(0, 0.35, 0), 0.1, 0.7, Color("c8ecff"), Vector3(0.1, 0, 0.15), 4)
			b.cone(Vector3(0.18, 0.2, 0.1), 0.07, 0.4, Color("a8d8f8"), Vector3(0, 0, -0.5), 4)
			g.ball(Vector3(0, 0.35, 0), 0.28, Color(0.7, 0.95, 1.0, 0.18), true)
		"cog":
			b.torus(Vector3(0, 0.08, 0), 0.22, 0.05, Color("c8984a"))
			b.cyl(Vector3(0, 0.08, 0), 0.07, 0.1, Color("8a6a30"))
		_:
			b.sph(Vector3(0, 0.1, 0), Vector3(0.25, 0.15, 0.25), gc, Vector3.ZERO, true)

# ---------------------------------------------------------------- sect buildings
static func _sect_buildings(root: Node3D, grid: PackedByteArray, w: int, h: int, th: Dictionary) -> void:
	var seen := {}
	for y in h:
		for x in w:
			if grid[y * w + x] != MapGen.BUILDING or seen.has(Vector2i(x, y)):
				continue
			var x1 := x
			while x1 + 1 < w and grid[y * w + x1 + 1] == MapGen.BUILDING:
				x1 += 1
			var y1 := y
			while y1 + 1 < h and grid[(y1 + 1) * w + x] == MapGen.BUILDING:
				y1 += 1
			for yy in range(y, y1 + 1):
				for xx in range(x, x1 + 1):
					seen[Vector2i(xx, yy)] = true
			_building(root, Rect2(x * T, y * T, (x1 - x + 1) * T, (y1 - y + 1) * T))

static func _building(root: Node3D, r: Rect2) -> void:
	var b := MB.new()
	var g := MB.new()
	var cx := r.position.x + r.size.x * 0.5
	var cz := r.position.y + r.size.y * 0.5
	var wall_h := 2.6
	b.box(Vector3(cx, 0.25, cz), Vector3(r.size.x + 0.5, 0.5, r.size.y + 0.5), Color("a8a4b0"))
	b.box(Vector3(cx, 0.5 + wall_h * 0.5, cz), Vector3(r.size.x - 0.2, wall_h, r.size.y - 0.2), Color("efe4c8"))
	# pillars
	var step := 2.0
	var nx := int(r.size.x / step)
	for i in range(nx + 1):
		var px := r.position.x + 0.1 + (r.size.x - 0.2) * i / float(maxi(nx, 1))
		b.cyl(Vector3(px, 0.5 + wall_h * 0.5, r.end.y - 0.05), 0.13, wall_h, Color("b83a2a"))
		b.cyl(Vector3(px, 0.5 + wall_h * 0.5, r.position.y + 0.05), 0.13, wall_h, Color("b83a2a"))
	# door and windows on the south face
	b.box(Vector3(cx, 1.4, r.end.y - 0.08), Vector3(1.0, 1.8, 0.1), Color("5a2a1a"))
	g.box(Vector3(cx - 1.4, 1.9, r.end.y - 0.06), Vector3(0.5, 0.6, 0.04), Color(1.0, 0.85, 0.5, 0.85))
	g.box(Vector3(cx + 1.4, 1.9, r.end.y - 0.06), Vector3(0.5, 0.6, 0.04), Color(1.0, 0.85, 0.5, 0.85))
	# tiered roof
	var roof_y := 0.5 + wall_h
	b.box(Vector3(cx, roof_y + 0.08, cz), Vector3(r.size.x + 0.9, 0.16, r.size.y + 0.9), Color("5a2a22"))
	var tiers := 2 if r.size.y > 6.0 else 1
	for t in tiers:
		var sx := (r.size.x + 1.4) * (1.0 - t * 0.35)
		var sz := (r.size.y + 1.4) * (1.0 - t * 0.35)
		var hh := 1.4 if t == 0 else 1.0
		var yy := roof_y + 0.16 + hh * 0.5 + t * 1.2
		b.prim("cone4", Transform3D(Basis.from_euler(Vector3(0, PI / 4, 0)).scaled(Vector3(sx * 1.4142, hh, sz * 1.4142)), Vector3(cx, yy, cz)), Color("3a6a8a").lerp(Color("2a4a6a"), t * 0.5))
	b.ball(Vector3(cx, roof_y + 0.16 + 1.4 + (tiers - 1) * 1.2 + 0.25, cz), 0.16, Color("e8c860"), true)
	# lanterns
	for sx2 in [r.position.x + 0.2, r.end.x - 0.2]:
		b.ball(Vector3(sx2, 2.3, r.end.y + 0.1), 0.18, Color("e04a3a"), true)
		g.ball(Vector3(sx2, 2.3, r.end.y + 0.1), 0.42, Color(1.0, 0.45, 0.2, 0.28), true)
	var mi := MB.mesh_node(root, b.build())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	MB.mesh_node(root, g.build(MB.mat_glow()))
