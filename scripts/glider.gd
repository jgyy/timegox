class_name Glider
extends RefCounted
## The cloud-kite (the High Roads release): a swallow of oiled paper on a frame of split bamboo, the
## kind children fly on a string from the fields below Qingshi, made large enough to hang under.
## Held over the head by its bar, it carries its bearer down from anywhere high (world.gd).  It is
## built here from code, like everything else, in the colours of whoever carries it.

static var _mat: StandardMaterial3D = null

static func _paper() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat.roughness = 0.85
		# (oiled paper lets the sun through: the underside is never black)
		_mat.emission_enabled = true
		_mat.emission = Color(0.16, 0.15, 0.13)
	return _mat

## A glider in cloth of colour `col` with trim `trim`.  It stands with its grip bar at the origin,
## its nose towards +Z (the way a person faces) and its span along X.
static func build(col: Color, trim: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "glider"
	var frame := MB.new()
	var bamboo := Color("b89a5a")
	var nose := Vector3(0, 0.16, 0.95)
	var tail := Vector3(0, 0.1, -0.95)
	# the keel, the grip bar and the two struts that hang it
	frame.limb(nose, tail, 0.022, 0.022, bamboo, 6)
	frame.limb(Vector3(-0.5, 0.0, 0.05), Vector3(0.5, 0.0, 0.05), 0.02, 0.02, bamboo.darkened(0.15), 6)
	frame.limb(Vector3(-0.32, 0.0, 0.05), Vector3(0, 0.14, 0.3), 0.014, 0.014, bamboo, 6)
	frame.limb(Vector3(0.32, 0.0, 0.05), Vector3(0, 0.14, 0.3), 0.014, 0.014, bamboo, 6)
	var sail := MB.new()
	for sd in [-1.0, 1.0]:
		var tip := Vector3(1.75 * sd, 0.34, -0.35)
		var mid := Vector3(0.95 * sd, 0.2, -0.78)
		var fork := Vector3(0.38 * sd, 0.06, -1.35)
		# the leading spar and a rib
		frame.limb(nose, tip, 0.018, 0.018, bamboo, 6)
		frame.limb(Vector3(0, 0.15, 0.2), mid, 0.012, 0.012, bamboo, 6)
		# the wing: nose, tip, the scallop of the trailing edge, the keel
		var dark := col.darkened(0.22)
		sail.quad4(nose, tip, mid, Vector3(0, 0.13, -0.3), col.lightened(0.08), dark, col, col.lightened(0.12))
		# a band of the trim along the leading edge, and the white breast of the swallow
		sail.quad4(nose + Vector3(0, 0.006, 0), tip + Vector3(0, 0.006, 0), tip.lerp(mid, 0.3) + Vector3(0, 0.006, 0), nose.lerp(Vector3(0, 0.13, -0.3), 0.28) + Vector3(0, 0.006, 0), trim, trim, trim, trim)
		# the forked tail
		sail.quad4(Vector3(0, 0.13, -0.3), mid, fork, tail, col, col, dark, dark)
		# two streamers from the fork
		sail.ribbon([fork, fork + Vector3(0.05 * sd, -0.08, -0.5), fork + Vector3(-0.03 * sd, -0.2, -1.0), fork + Vector3(0.06 * sd, -0.3, -1.5)], [0.05, 0.045, 0.035, 0.02], Vector3(1, 0, 0), trim, col)
	# the eyes of the swallow, either side of the nose
	sail.disc(Vector3(-0.2, 0.175, 0.55), 0.07, Color("202028"), 10)
	sail.disc(Vector3(0.2, 0.175, 0.55), 0.07, Color("202028"), 10)
	MB.mesh_node(root, frame.build())
	var sm := MB.mesh_node(root, sail.build(_paper()))
	sm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return root
