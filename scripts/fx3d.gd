class_name Fx3D
extends RefCounted
## 3D particle effects: ambient weather per region and element-coloured combat bursts.

static var _spark_mesh: Mesh = null
static var _bolt_mesh: Mesh = null
static var _leaf_mesh: Mesh = null

static func headless() -> bool:
	return DisplayServer.get_name() == "headless"

static func _sparks() -> Mesh:
	if _spark_mesh == null:
		var s := SphereMesh.new()
		s.radius = 0.07
		s.height = 0.14
		s.radial_segments = 6
		s.rings = 3
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		s.material = m
		_spark_mesh = s
	return _spark_mesh

static func _bolts() -> Mesh:
	if _bolt_mesh == null:
		var s := BoxMesh.new()
		s.size = Vector3(0.05, 0.05, 0.9)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		s.material = m
		_bolt_mesh = s
	return _bolt_mesh

static func _leaves() -> Mesh:
	if _leaf_mesh == null:
		var s := BoxMesh.new()
		s.size = Vector3(0.16, 0.02, 0.1)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		s.material = m
		_leaf_mesh = s
	return _leaf_mesh

## ambient particles that follow the player; call configure_weather to switch region
static func make_weather() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p

static func configure_weather(p: CPUParticles3D, kind: String) -> void:
	p.set_deferred("emitting", not headless())
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(16, 0.5, 16)
	p.position = Vector3(0, 12, 0)
	p.mesh = _sparks()
	p.amount = 140
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.direction = Vector3(0, -1, 0)
	p.spread = 12.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.4
	p.angular_velocity_min = 0.0
	p.angular_velocity_max = 0.0
	p.color = Color(1, 1, 1, 0.9)
	match kind:
		"snow":
			p.amount = 260
			p.lifetime = 7.0
			p.preprocess = 7.0
			p.initial_velocity_min = 1.2
			p.initial_velocity_max = 2.2
			p.spread = 30.0
			p.color = Color(1, 1, 1, 0.95)
		"rain":
			p.amount = 320
			p.lifetime = 1.0
			p.preprocess = 1.0
			p.mesh = _bolts()
			p.direction = Vector3(0.15, -1, 0)
			p.spread = 2.0
			p.initial_velocity_min = 22.0
			p.initial_velocity_max = 26.0
			p.color = Color(0.7, 0.8, 1.0, 0.55)
		"petals", "leaves":
			p.mesh = _leaves()
			p.amount = 110
			p.lifetime = 8.0
			p.preprocess = 8.0
			p.spread = 40.0
			p.initial_velocity_min = 0.6
			p.initial_velocity_max = 1.4
			p.gravity = Vector3(0.6, 0, 0.2)
			p.angular_velocity_min = -90.0
			p.angular_velocity_max = 90.0
			p.color = Color(1.0, 0.72, 0.84, 0.9) if kind == "petals" else Color(0.62, 0.9, 0.4, 0.9)
		"bubbles", "bubbles_up":
			p.position = Vector3(0, 0.2, 0)
			p.direction = Vector3(0, 1, 0)
			p.spread = 15.0
			p.initial_velocity_min = 0.4
			p.initial_velocity_max = 1.2
			p.lifetime = 5.0
			p.preprocess = 5.0
			p.amount = 120
			p.scale_amount_min = 1.0
			p.scale_amount_max = 2.0
			p.color = Color(0.6, 0.9, 0.7, 0.5) if kind == "bubbles" else Color(0.7, 0.95, 1.0, 0.6)
		"embers":
			p.position = Vector3(0, 0.3, 0)
			p.direction = Vector3(0, 1, 0)
			p.spread = 20.0
			p.initial_velocity_min = 1.5
			p.initial_velocity_max = 3.5
			p.lifetime = 5.0
			p.preprocess = 5.0
			p.amount = 160
			p.color = Color(1.0, 0.55, 0.2, 0.95)
		"motes_red":
			p.position = Vector3(0, 3.0, 0)
			p.emission_box_extents = Vector3(16, 3, 16)
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.8
			p.color = Color(1.0, 0.2, 0.25, 0.8)
		"stars", "glints", "light", "wisps", "sand":
			p.position = Vector3(0, 3.5, 0)
			p.emission_box_extents = Vector3(16, 3.5, 16)
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.initial_velocity_min = 0.1
			p.initial_velocity_max = 0.7
			p.amount = 120
			match kind:
				"stars":
					p.color = Color(0.8, 0.6, 1.0, 0.95)
				"glints":
					p.color = Color(0.85, 0.97, 1.0, 0.95)
				"light":
					p.color = Color(1.0, 0.92, 0.6, 0.9)
				"wisps":
					p.color = Color(0.5, 0.95, 1.0, 0.75)
					p.scale_amount_min = 1.3
					p.scale_amount_max = 2.2
				"sand":
					p.color = Color(1.0, 0.82, 0.4, 0.8)
					p.gravity = Vector3(1.2, -0.1, 0.3)
		_:
			p.set_deferred("emitting", false)

# ---------------------------------------------------------------- combat bursts
static func _burst(parent: Node3D, pos: Vector3, col: Color, amount: int, speed: float, life: float, mesh: Mesh, gravity: Vector3, dir: Vector3 = Vector3(0, 1, 0), spread: float = 180.0) -> void:
	var p := CPUParticles3D.new()
	p.mesh = mesh
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.25
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = gravity
	p.scale_amount_min = 0.8
	p.scale_amount_max = 2.0
	p.color = col
	p.position = pos
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.emitting = true
	var tm := parent.get_tree().create_timer(life + 0.3)
	tm.timeout.connect(p.queue_free)

static func _flash(parent: Node3D, pos: Vector3, col: Color, size: float, life: float) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 5
	mi.mesh = s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r, col.g, col.b, 0.8)
	mi.material_override = m
	mi.position = pos
	mi.scale = Vector3.ONE * 0.3
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size, life)
	tw.tween_property(m, "albedo_color:a", 0.0, life)
	tw.chain().tween_callback(mi.queue_free)

## element-coloured hit burst at a world position
static func hit(parent: Node3D, pos: Vector3, elem: String) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var col: Color = Data.ELEM_COLORS.get(elem, Color.WHITE)
	_flash(parent, pos, col, 2.2, 0.35)
	match elem:
		"fire":
			_burst(parent, pos, col, 40, 5.0, 0.9, _sparks(), Vector3(0, 2.5, 0))
		"water":
			_burst(parent, pos, col, 44, 5.0, 0.9, _sparks(), Vector3(0, -9.0, 0), Vector3(0, 1, 0), 70.0)
		"wood":
			_burst(parent, pos, col, 36, 4.5, 1.0, _leaves(), Vector3(0, -3.0, 0))
		"earth":
			_burst(parent, pos, col, 30, 4.5, 0.9, _sparks(), Vector3(0, -12.0, 0), Vector3(0, 1, 0), 60.0)
		"thunder":
			_burst(parent, pos, col, 26, 9.0, 0.45, _bolts(), Vector3.ZERO)
			_flash(parent, pos + Vector3(0, 1.0, 0), Color.WHITE, 3.0, 0.2)
		"dark":
			_burst(parent, pos, col, 36, 4.0, 0.9, _sparks(), Vector3(0, 0.5, 0))
		_:
			_burst(parent, pos, Color(1, 1, 0.9), 24, 6.0, 0.5, _sparks(), Vector3.ZERO)

static func heal(parent: Node3D, pos: Vector3) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	_burst(parent, pos, Color(0.5, 1.0, 0.8, 0.9), 30, 2.0, 1.2, _sparks(), Vector3(0, 1.5, 0), Vector3(0, 1, 0), 40.0)
	_flash(parent, pos, Color(0.5, 1.0, 0.8), 1.6, 0.5)
