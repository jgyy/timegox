class_name MB
extends RefCounted
## Mesh builder: merges primitive shapes (box, sphere, cylinder, cone, torus) into one ArrayMesh
## with per-vertex colours.  Every 3D model in the game is generated with this at runtime.

var v := PackedVector3Array()
var n := PackedVector3Array()
var c := PackedColorArray()
var idx := PackedInt32Array()

static var _protos := {}
static var _mat_vc: StandardMaterial3D = null
static var _mat_glow: StandardMaterial3D = null
static var _mat_glass: StandardMaterial3D = null

static func _proto(key: String) -> Array:
	if _protos.has(key):
		return _protos[key]
	var m: PrimitiveMesh
	match key:
		"box":
			m = BoxMesh.new()
		"sph":
			var s := SphereMesh.new()
			s.radial_segments = 12
			s.rings = 6
			m = s
		"sph_lo":
			var s2 := SphereMesh.new()
			s2.radial_segments = 8
			s2.rings = 4
			m = s2
		"cyl8":
			var cy := CylinderMesh.new()
			cy.radial_segments = 8
			cy.rings = 1
			m = cy
		"cyl4":
			var c4 := CylinderMesh.new()
			c4.radial_segments = 4
			c4.rings = 1
			m = c4
		"cyl14":
			var c14 := CylinderMesh.new()
			c14.radial_segments = 14
			c14.rings = 1
			m = c14
		"fr8":
			var fr := CylinderMesh.new()
			fr.top_radius = 0.28
			fr.radial_segments = 10
			fr.rings = 1
			m = fr
		"cone8":
			var co := CylinderMesh.new()
			co.top_radius = 0.0
			co.radial_segments = 8
			co.rings = 1
			m = co
		"cone4":
			var c5 := CylinderMesh.new()
			c5.top_radius = 0.0
			c5.radial_segments = 4
			c5.rings = 1
			m = c5
		"cone14":
			var c6 := CylinderMesh.new()
			c6.top_radius = 0.0
			c6.radial_segments = 14
			c6.rings = 1
			m = c6
		"torus":
			var t := TorusMesh.new()
			t.inner_radius = 0.42
			t.outer_radius = 0.5
			t.rings = 20
			t.ring_segments = 6
			m = t
		_:
			m = BoxMesh.new()
	var arr := m.get_mesh_arrays()
	var out := [arr[Mesh.ARRAY_VERTEX], arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_INDEX]]
	_protos[key] = out
	return out

## Add a unit primitive transformed by `xf` (all prototypes have unit size: box 1x1x1, sphere diameter 1,
## cylinder/cone radius 0.5 and height 1, torus outer diameter 1).
func prim(key: String, xf: Transform3D, col: Color) -> void:
	var p := _proto(key)
	var pv: PackedVector3Array = p[0]
	var pn: PackedVector3Array = p[1]
	var pi: PackedInt32Array = p[2]
	var base := v.size()
	var nb := xf.basis.inverse().transposed()
	var lc := col.srgb_to_linear()
	for i in pv.size():
		v.append(xf * pv[i])
		n.append((nb * pn[i]).normalized())
		c.append(lc)
	for i in pi:
		idx.append(base + i)

static func _xf(pos: Vector3, size: Vector3, rot: Vector3) -> Transform3D:
	var b := Basis.from_euler(rot) if rot != Vector3.ZERO else Basis.IDENTITY
	b = b.scaled(size)
	return Transform3D(b, pos)

func box(pos: Vector3, size: Vector3, col: Color, rot: Vector3 = Vector3.ZERO) -> void:
	prim("box", _xf(pos, size, rot), col)

func sph(pos: Vector3, radii: Vector3, col: Color, rot: Vector3 = Vector3.ZERO, lo: bool = false) -> void:
	prim("sph_lo" if lo else "sph", _xf(pos, radii * 2.0, rot), col)

func ball(pos: Vector3, r: float, col: Color, lo: bool = false) -> void:
	prim("sph_lo" if lo else "sph", _xf(pos, Vector3(r, r, r) * 2.0, Vector3.ZERO), col)

## cylinder, pos is the centre
func cyl(pos: Vector3, r: float, h: float, col: Color, rot: Vector3 = Vector3.ZERO, seg: int = 8) -> void:
	prim("cyl%d" % seg, _xf(pos, Vector3(r * 2.0, h, r * 2.0), rot), col)

## cone with its base at the bottom, pos is the centre of the height
func cone(pos: Vector3, r: float, h: float, col: Color, rot: Vector3 = Vector3.ZERO, seg: int = 8) -> void:
	prim("cone%d" % seg, _xf(pos, Vector3(r * 2.0, h, r * 2.0), rot), col)

## torus lying flat (axis = y)
func torus(pos: Vector3, r: float, thick: float, col: Color, rot: Vector3 = Vector3.ZERO) -> void:
	prim("torus", _xf(pos, Vector3(r * 2.0, thick * 25.0, r * 2.0), rot), col)

## flat horizontal quad of colour `col` at height y
func quad(x0: float, z0: float, x1: float, z1: float, y: float, col: Color) -> void:
	var base := v.size()
	v.append(Vector3(x0, y, z0))
	v.append(Vector3(x1, y, z0))
	v.append(Vector3(x1, y, z1))
	v.append(Vector3(x0, y, z1))
	var lc := col.srgb_to_linear()
	for i in 4:
		n.append(Vector3.UP)
		c.append(lc)
	idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

func quad4(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, c0: Color, c1: Color, c2: Color, c3: Color) -> void:
	var base := v.size()
	var nn := (p1 - p0).cross(p3 - p0).normalized()
	if nn.y < 0:
		nn = -nn
	v.append(p0)
	v.append(p1)
	v.append(p2)
	v.append(p3)
	for i in 4:
		n.append(nn)
	c.append(c0.srgb_to_linear())
	c.append(c1.srgb_to_linear())
	c.append(c2.srgb_to_linear())
	c.append(c3.srgb_to_linear())
	idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

func is_empty() -> bool:
	return v.is_empty()

func build(mat: Material = null) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if v.is_empty():
		return mesh
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(0, mat if mat != null else mat_vc())
	return mesh

# ---------------------------------------------------------------- materials
static func mat_vc() -> StandardMaterial3D:
	if _mat_vc == null:
		_mat_vc = StandardMaterial3D.new()
		_mat_vc.vertex_color_use_as_albedo = true
		_mat_vc.roughness = 0.85
		_mat_vc.metallic = 0.0
		_mat_vc.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_vc

## unshaded additive-looking glow (colour alpha controls intensity)
static func mat_glow() -> StandardMaterial3D:
	if _mat_glow == null:
		_mat_glow = StandardMaterial3D.new()
		_mat_glow.vertex_color_use_as_albedo = true
		_mat_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat_glow.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_glow.no_depth_test = false
	return _mat_glow

## translucent shiny glass
static func mat_glass() -> StandardMaterial3D:
	if _mat_glass == null:
		_mat_glass = StandardMaterial3D.new()
		_mat_glass.vertex_color_use_as_albedo = true
		_mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_glass.roughness = 0.15
		_mat_glass.metallic = 0.4
		_mat_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _mat_glass

static func emissive(col: Color, energy: float = 1.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m

static func mesh_node(parent: Node, mesh: Mesh, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	if parent != null:
		parent.add_child(mi)
	return mi
