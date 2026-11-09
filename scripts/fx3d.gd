class_name Fx3D
extends RefCounted
## 3D effects: ambient weather per region and element-coloured combat effects.
##
## Particles use soft, procedurally generated sprite textures (radial glow, snowflake, streak, petal,
## spark star) on camera-facing quads, so nothing looks like a hard-edged ball any more.  Combat has
## element-specific spell shapes: sword-slash arcs, travelling projectiles with trails, fire pillars,
## water rings, leaf spirals, rock spikes, sky lightning, dark vortices and ground shockwaves.

static var _spark_mesh: Mesh = null
static var _bolt_mesh: Mesh = null
static var _leaf_mesh: Mesh = null
static var _sprites := {}
static var _quads := {}

static func headless() -> bool:
	return DisplayServer.get_name() == "headless"

# ---------------------------------------------------------------- procedural sprite textures
## kind: glow | flake | streak | petal | star | ring | maple | flame | smoke | note | zed
static func sprite(kind: String) -> ImageTexture:
	if _sprites.has(kind):
		return _sprites[kind]
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y in sz:
		for x in sz:
			var u := (x + 0.5) / sz * 2.0 - 1.0
			var v := (y + 0.5) / sz * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var a := 0.0
			match kind:
				"glow":
					a = pow(clampf(1.0 - r, 0.0, 1.0), 2.2)
				"flake":
					var ang := atan2(v, u)
					var arms := absf(cos(ang * 3.0))
					a = clampf(1.0 - r * 1.3, 0.0, 1.0) * (0.35 + 0.65 * pow(arms, 6.0)) + pow(clampf(1.0 - r * 3.0, 0.0, 1.0), 2.0)
				"streak":
					a = pow(clampf(1.0 - absf(u) * 4.0, 0.0, 1.0), 1.5) * clampf(1.0 - absf(v), 0.0, 1.0)
				"petal":
					var pu := u * 1.6
					var pv := v + 0.25 * (1.0 - u * u)
					a = clampf(1.0 - (pu * pu + pv * pv * 2.2), 0.0, 1.0)
					a = smoothstep(0.0, 0.25, a)
				"star":
					var cross := pow(clampf(1.0 - absf(u) * 9.0, 0.0, 1.0), 2.0) * clampf(1.0 - absf(v), 0.0, 1.0)
					cross = maxf(cross, pow(clampf(1.0 - absf(v) * 9.0, 0.0, 1.0), 2.0) * clampf(1.0 - absf(u), 0.0, 1.0))
					a = maxf(cross, pow(clampf(1.0 - r * 1.6, 0.0, 1.0), 3.0))
				"ring":
					a = pow(clampf(1.0 - absf(r - 0.72) * 6.0, 0.0, 1.0), 1.5)
				"maple":
					# a five-lobed maple leaf with a short stem
					var ang2 := atan2(v, u) + PI * 0.5
					var rr := 0.55 + 0.4 * pow(absf(cos(ang2 * 2.5)), 0.7)
					a = smoothstep(0.0, 0.08, rr * 0.85 - r)
					a = maxf(a, pow(clampf(1.0 - absf(u) * 14.0, 0.0, 1.0), 2.0) * (1.0 if v >= 0.0 and v <= 0.95 else 0.0))
				"flame":
					# a soft teardrop flame (ghost-fire)
					var fv := (v + 1.0) * 0.5
					var fw := 0.55 * sqrt(clampf(fv, 0.0, 1.0)) * (1.0 - fv * 0.55)
					a = smoothstep(0.0, 0.25, fw - absf(u) * 0.5) * smoothstep(0.0, 0.2, 1.0 - fv)
				"smoke":
					var nz := 0.5 + 0.25 * sin(u * 7.0 + v * 3.0) * cos(v * 6.0 - u * 2.0)
					a = pow(clampf(1.0 - r, 0.0, 1.0), 1.4) * nz * 1.3
				"note":
					# a quaver: a tilted oval head, a stem and a flag
					var hu := u + 0.24
					var hv := v - 0.5
					var ru := (hu * 0.9 + hv * 0.43) / 0.3
					var rv := (-hu * 0.43 + hv * 0.9) / 0.2
					a = smoothstep(0.0, 0.3, 1.0 - (ru * ru + rv * rv))
					if v > -0.84 and v < 0.48:
						a = maxf(a, smoothstep(0.0, 0.04, 0.06 - absf(u - 0.03)))
					if v > -0.84 and v < -0.2:
						var fs := (-0.35 + sqrt(maxf(0.0, 0.1225 + 1.2 * (0.84 + v)))) / 0.6
						a = maxf(a, smoothstep(0.0, 0.04, 0.12 * (1.0 - 0.5 * fs) - absf(u - (0.03 + 0.34 * fs))))
				"zed":
					# a sleeper's z
					var bar := 1.0 if absf(u) < 0.46 else 0.0
					a = maxf(smoothstep(0.0, 0.04, 0.1 - absf(v + 0.5)), smoothstep(0.0, 0.04, 0.1 - absf(v - 0.5))) * bar
					if absf(v) < 0.56:
						a = maxf(a, smoothstep(0.0, 0.04, 0.1 - absf(u + 0.9 * v) / 1.345))
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	_sprites[kind] = tex
	return tex

## camera-facing textured quad mesh for particles
static func quad(kind: String, size: float = 0.3, additive: bool = true) -> Mesh:
	var key := "%s_%.2f_%s" % [kind, size, additive]
	if _quads.has(key):
		return _quads[key]
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = sprite(kind)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m
	_quads[key] = q
	return q

static func _sparks() -> Mesh:
	if _spark_mesh == null:
		_spark_mesh = quad("glow", 0.32)
	return _spark_mesh

static func _bolts() -> Mesh:
	if _bolt_mesh == null:
		var s := BoxMesh.new()
		s.size = Vector3(0.035, 0.035, 0.9)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		s.material = m
		_bolt_mesh = s
	return _bolt_mesh

static func _leaves() -> Mesh:
	if _leaf_mesh == null:
		var s := QuadMesh.new()
		s.size = Vector2(0.2, 0.2)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = sprite("petal")
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		s.material = m
		_leaf_mesh = s
	return _leaf_mesh

## autumn leaves: crimson, orange and gold, fading at both ends of their life
static func _autumn_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(0.9, 0.25, 0.1, 0.0))
	g.set_color(1, Color(1.0, 0.8, 0.3, 0.0))
	g.add_point(0.12, Color(0.92, 0.3, 0.12, 1.0))
	g.add_point(0.5, Color(1.0, 0.55, 0.15, 1.0))
	g.add_point(0.85, Color(1.0, 0.78, 0.3, 1.0))
	return g

## ghost-fire: white-blue core cooling to deep blue, then gone
static func _ghost_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(0.8, 0.95, 1.0, 0.0))
	g.set_color(1, Color(0.1, 0.25, 0.9, 0.0))
	g.add_point(0.15, Color(0.75, 0.92, 1.0, 1.0))
	g.add_point(0.6, Color(0.3, 0.6, 1.0, 0.8))
	return g

static func _fade_ramp(peak: float = 1.0) -> Gradient:
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_offset(1, 1.0)
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.15, Color(1, 1, 1, peak))
	g.add_point(0.75, Color(1, 1, 1, peak * 0.8))
	return g

## a colour ramp that cycles through the five colours of Nuwa's stones and fades out
static func _rainbow_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.35, 0.55, 0.75, 1.0])
	g.colors = PackedColorArray([Color(1, 0.4, 0.4, 0.0), Color(1, 0.4, 0.4, 1), Color(1, 0.85, 0.3, 1), Color(0.4, 0.7, 1, 1), Color(0.95, 0.95, 1, 0.8), Color(0.7, 0.5, 1, 0.0)])
	return g

static func _shrink_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0, 0.4))
	c.add_point(Vector2(0.2, 1.0))
	c.add_point(Vector2(1, 0.0))
	return c

# ---------------------------------------------------------------- weather
## ambient particles that follow the player; call configure_weather to switch region
static func make_weather() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a second, sparser layer of glowing motes rides along as a child
	var motes := CPUParticles3D.new()
	motes.name = "motes"
	motes.emitting = false
	motes.local_coords = false
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(motes)
	return p

static func configure_weather(p: CPUParticles3D, kind: String) -> void:
	p.set_deferred("emitting", not headless())
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(18, 0.5, 18)
	p.position = Vector3(0, 12, 0)
	p.mesh = quad("glow", 0.22)
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
	p.scale_amount_curve = null
	p.angular_velocity_min = 0.0
	p.angular_velocity_max = 0.0
	p.color = Color(1, 1, 1, 0.9)
	p.color_ramp = _fade_ramp()
	p.particle_flag_align_y = false
	var mote_kind := ""
	match kind:
		"snow":
			p.mesh = quad("flake", 0.24, false)
			p.amount = 300
			p.lifetime = 7.0
			p.preprocess = 7.0
			p.initial_velocity_min = 1.0
			p.initial_velocity_max = 2.0
			p.spread = 30.0
			p.gravity = Vector3(0.4, 0, 0.2)
			p.color = Color(1, 1, 1, 0.95)
			mote_kind = "frost"
		"rain":
			p.amount = 380
			p.lifetime = 1.0
			p.preprocess = 1.0
			p.mesh = _bolts()
			p.direction = Vector3(0.15, -1, 0)
			p.spread = 2.0
			p.particle_flag_align_y = true
			p.initial_velocity_min = 22.0
			p.initial_velocity_max = 26.0
			p.color = Color(0.7, 0.8, 1.0, 0.45)
			p.color_ramp = null
			mote_kind = "lightning_haze"
		"petals", "leaves":
			p.mesh = _leaves()
			p.amount = 130
			p.lifetime = 8.0
			p.preprocess = 8.0
			p.spread = 40.0
			p.initial_velocity_min = 0.6
			p.initial_velocity_max = 1.4
			p.gravity = Vector3(0.6, 0, 0.2)
			p.angular_velocity_min = -120.0
			p.angular_velocity_max = 120.0
			p.color = Color(1.0, 0.72, 0.84, 0.95) if kind == "petals" else Color(0.62, 0.9, 0.4, 0.95)
			mote_kind = "fireflies" if kind == "leaves" else "pollen"
		# ---- Part VI
		"maple_leaves":
			# maple leaves tumbling down through the gorge, every one a different autumn colour
			p.mesh = quad("maple", 0.34, false)
			p.amount = 170
			p.lifetime = 9.0
			p.preprocess = 9.0
			p.spread = 45.0
			p.initial_velocity_min = 0.5
			p.initial_velocity_max = 1.2
			p.gravity = Vector3(0.7, -0.05, 0.3)
			p.angular_velocity_min = -160.0
			p.angular_velocity_max = 160.0
			p.color = Color(1, 1, 1, 1)
			p.color_ramp = _autumn_ramp()
			mote_kind = "pollen"
		"river_mist":
			# a fine drizzle over the river, with banks of mist rolling between the stone towers
			p.amount = 160
			p.lifetime = 1.4
			p.preprocess = 1.4
			p.mesh = _bolts()
			p.direction = Vector3(0.05, -1, 0)
			p.spread = 3.0
			p.particle_flag_align_y = true
			p.initial_velocity_min = 14.0
			p.initial_velocity_max = 17.0
			p.color = Color(0.85, 0.92, 1.0, 0.22)
			p.color_ramp = null
			mote_kind = "mist_bank"
		"lily_souls":
			# soul lights drifting up out of the spider lilies towards the bridge
			p.position = Vector3(0, 1.0, 0)
			p.emission_box_extents = Vector3(18, 1.0, 18)
			p.mesh = quad("glow", 0.45)
			p.amount = 70
			p.lifetime = 9.0
			p.preprocess = 9.0
			p.direction = Vector3(0.2, 1, 0)
			p.spread = 20.0
			p.initial_velocity_min = 0.3
			p.initial_velocity_max = 0.7
			p.color = Color(1.0, 0.85, 0.55, 0.85)
			mote_kind = "red_petals"
		"ghostfire":
			# cold blue flames rising from the floor of the Ten Courts
			p.position = Vector3(0, 0.3, 0)
			p.emission_box_extents = Vector3(18, 0.3, 18)
			p.mesh = quad("flame", 0.6)
			p.amount = 90
			p.lifetime = 3.0
			p.preprocess = 3.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 6.0
			p.initial_velocity_min = 0.6
			p.initial_velocity_max = 1.4
			p.color = Color(1, 1, 1, 1)
			p.color_ramp = _ghost_ramp()
			mote_kind = "void_dust"
		"bubbles", "bubbles_up":
			p.position = Vector3(0, 0.2, 0)
			p.mesh = quad("ring", 0.3)
			p.direction = Vector3(0, 1, 0)
			p.spread = 15.0
			p.initial_velocity_min = 0.4
			p.initial_velocity_max = 1.2
			p.lifetime = 5.0
			p.preprocess = 5.0
			p.amount = 120
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.6
			p.color = Color(0.6, 0.9, 0.7, 0.6) if kind == "bubbles" else Color(0.7, 0.95, 1.0, 0.7)
			mote_kind = "spores" if kind == "bubbles" else "caustic"
		"embers", "sparks":
			p.position = Vector3(0, 0.3, 0)
			p.mesh = quad("star", 0.22)
			p.direction = Vector3(0, 1, 0)
			p.spread = 20.0
			p.initial_velocity_min = 1.5
			p.initial_velocity_max = 3.5
			p.lifetime = 5.0
			p.preprocess = 5.0
			p.amount = 170
			p.gravity = Vector3(0.3, 0.2, 0)
			p.color = Color(1.0, 0.55, 0.2, 0.95) if kind == "embers" else Color(1.0, 0.8, 0.35, 0.95)
			mote_kind = "ash"
		"motes_red":
			p.position = Vector3(0, 3.0, 0)
			p.emission_box_extents = Vector3(18, 3, 18)
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.8
			p.color = Color(1.0, 0.2, 0.25, 0.8)
			mote_kind = "ash"
		"clouds":
			p.position = Vector3(0, 1.0, 0)
			p.emission_box_extents = Vector3(20, 1.0, 20)
			p.mesh = quad("smoke", 3.5, false)
			p.amount = 40
			p.lifetime = 12.0
			p.preprocess = 12.0
			p.direction = Vector3(1, 0, 0.3)
			p.spread = 20.0
			p.initial_velocity_min = 0.3
			p.initial_velocity_max = 0.7
			p.scale_amount_min = 0.8
			p.scale_amount_max = 1.8
			p.color = Color(1, 1, 1, 0.35)
			mote_kind = "pollen"
		"sandstorm":
			# streaks of sand racing sideways with dust banks rolling behind them
			p.position = Vector3(0, 1.5, 0)
			p.emission_box_extents = Vector3(20, 1.5, 20)
			p.mesh = quad("streak", 0.32)
			p.amount = 260
			p.lifetime = 2.5
			p.preprocess = 2.5
			p.direction = Vector3(1, 0.05, 0.25)
			p.spread = 8.0
			p.initial_velocity_min = 7.0
			p.initial_velocity_max = 11.0
			p.particle_flag_align_y = false
			p.color = Color(1.0, 0.85, 0.55, 0.55)
			mote_kind = "dust_bank"
		"spores":
			# slow glowing spores drifting up from the moss in lazy spirals
			p.position = Vector3(0, 0.4, 0)
			p.emission_box_extents = Vector3(18, 0.4, 18)
			p.mesh = quad("glow", 0.2)
			p.amount = 220
			p.lifetime = 9.0
			p.preprocess = 9.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 25.0
			p.initial_velocity_min = 0.25
			p.initial_velocity_max = 0.7
			p.gravity = Vector3(0.15, 0.05, 0.05)
			p.angular_velocity_min = -40.0
			p.angular_velocity_max = 40.0
			p.color = Color(0.45, 1.0, 0.85, 0.9)
			mote_kind = "glowspores"
		"aurora_snow":
			p.mesh = quad("flake", 0.2, false)
			p.amount = 220
			p.lifetime = 8.0
			p.preprocess = 8.0
			p.initial_velocity_min = 0.7
			p.initial_velocity_max = 1.4
			p.spread = 25.0
			p.gravity = Vector3(0.25, 0, 0.1)
			p.color = Color(0.85, 0.95, 1.0, 0.95)
			mote_kind = "aurora_glints"
		"chaos":
			# motes of every colour orbiting slowly upward
			p.position = Vector3(0, 3.0, 0)
			p.emission_box_extents = Vector3(18, 3.0, 18)
			p.mesh = quad("star", 0.3)
			p.amount = 200
			p.lifetime = 7.0
			p.preprocess = 7.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.9
			p.color = Color(1, 1, 1, 0.95)
			p.color_ramp = _rainbow_ramp()
			mote_kind = "void_dust"
		"lanterns":
			p.position = Vector3(0, 2.0, 0)
			p.emission_box_extents = Vector3(18, 2, 18)
			p.mesh = quad("glow", 0.5)
			p.amount = 46
			p.lifetime = 10.0
			p.preprocess = 10.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 10.0
			p.initial_velocity_min = 0.3
			p.initial_velocity_max = 0.6
			p.color = Color(1.0, 0.6, 0.3, 0.9)
			mote_kind = "fireflies"
		# ---- Part IX
		"heat_haze":
			# the air itself shimmering over baked ground: faint veils of warm light rising slowly,
			# with fine dust drifting in the sunlight
			p.position = Vector3(0, 0.3, 0)
			p.emission_box_extents = Vector3(18, 0.6, 18)
			p.mesh = quad("smoke", 2.2, false)
			p.amount = 60
			p.lifetime = 5.0
			p.preprocess = 5.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 8.0
			p.initial_velocity_min = 0.5
			p.initial_velocity_max = 1.1
			p.scale_amount_min = 0.8
			p.scale_amount_max = 1.6
			p.color = Color(1.0, 0.96, 0.85, 0.12)
			mote_kind = "pollen"
		"steam":
			# steam lifting off the hot springs and drifting up the valley, gold motes in the dawn
			p.position = Vector3(0, 0.3, 0)
			p.emission_box_extents = Vector3(18, 0.3, 18)
			p.mesh = quad("smoke", 3.0, false)
			p.amount = 70
			p.lifetime = 7.0
			p.preprocess = 7.0
			p.direction = Vector3(0.15, 1, 0.05)
			p.spread = 12.0
			p.initial_velocity_min = 0.6
			p.initial_velocity_max = 1.3
			p.scale_amount_min = 0.8
			p.scale_amount_max = 2.0
			p.color = Color(1.0, 0.98, 0.94, 0.22)
			mote_kind = "pollen"
		"osmanthus":
			# tiny golden osmanthus flowers drifting down through the moonlight over glittering frost
			p.mesh = quad("petal", 0.12, false)
			p.amount = 160
			p.lifetime = 8.0
			p.preprocess = 8.0
			p.spread = 35.0
			p.initial_velocity_min = 0.4
			p.initial_velocity_max = 1.0
			p.gravity = Vector3(0.3, -0.05, 0.15)
			p.angular_velocity_min = -90.0
			p.angular_velocity_max = 90.0
			p.color = Color(1.0, 0.8, 0.3, 0.95)
			mote_kind = "frost"
		"stars", "glints", "light", "wisps", "sand":
			p.position = Vector3(0, 3.5, 0)
			p.emission_box_extents = Vector3(18, 3.5, 18)
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.initial_velocity_min = 0.1
			p.initial_velocity_max = 0.7
			p.amount = 120
			match kind:
				"stars":
					p.mesh = quad("star", 0.28)
					p.color = Color(0.8, 0.6, 1.0, 0.95)
					mote_kind = "void_dust"
				"glints":
					p.mesh = quad("star", 0.26)
					p.color = Color(0.85, 0.97, 1.0, 0.95)
					mote_kind = "pollen"
				"light":
					p.mesh = quad("star", 0.24)
					p.color = Color(1.0, 0.92, 0.6, 0.9)
					mote_kind = "pollen"
				"wisps":
					p.mesh = quad("glow", 0.5)
					p.color = Color(0.5, 0.95, 1.0, 0.75)
					p.scale_amount_min = 1.0
					p.scale_amount_max = 1.8
					mote_kind = "fog"
				"sand":
					p.mesh = quad("streak", 0.2)
					p.color = Color(1.0, 0.82, 0.4, 0.8)
					p.gravity = Vector3(1.2, -0.1, 0.3)
					mote_kind = "fog"
		_:
			p.set_deferred("emitting", false)
	_configure_motes(p.get_node_or_null("motes"), mote_kind, p.position.y)

## secondary weather layer: fireflies, pollen, haze...  positioned relative to the primary emitter
static func _configure_motes(m: CPUParticles3D, kind: String, parent_y: float) -> void:
	if m == null:
		return
	m.set_deferred("emitting", kind != "" and not headless())
	if kind == "":
		return
	m.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(14, 1.5, 14)
	m.position = Vector3(0, 1.6 - parent_y, 0)
	m.mesh = quad("glow", 0.18)
	m.amount = 40
	m.lifetime = 5.0
	m.preprocess = 5.0
	m.direction = Vector3(0, 1, 0)
	m.spread = 180.0
	m.gravity = Vector3.ZERO
	m.initial_velocity_min = 0.1
	m.initial_velocity_max = 0.4
	m.scale_amount_min = 0.6
	m.scale_amount_max = 1.4
	m.color_ramp = _fade_ramp()
	match kind:
		"fireflies":
			m.color = Color(0.9, 1.0, 0.45, 1.0)
		"pollen":
			m.color = Color(1.0, 0.95, 0.75, 0.7)
		"frost":
			m.mesh = quad("star", 0.16)
			m.color = Color(0.8, 0.95, 1.0, 0.9)
		"spores":
			m.color = Color(0.7, 1.0, 0.5, 0.7)
		"caustic":
			m.color = Color(0.6, 1.0, 1.0, 0.6)
		"ash":
			m.mesh = quad("smoke", 0.35, false)
			m.color = Color(0.25, 0.22, 0.22, 0.5)
			m.gravity = Vector3(0.2, -0.15, 0.1)
		"void_dust":
			m.color = Color(0.5, 0.8, 1.0, 0.8)
		"lightning_haze":
			m.mesh = quad("smoke", 2.5, false)
			m.amount = 18
			m.color = Color(0.55, 0.6, 0.8, 0.25)
		"dust_bank":
			m.mesh = quad("smoke", 4.0, false)
			m.amount = 26
			m.lifetime = 6.0
			m.preprocess = 6.0
			m.position.y = 0.8 - parent_y
			m.direction = Vector3(1, 0, 0.2)
			m.spread = 10.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 4.0
			m.color = Color(0.95, 0.78, 0.5, 0.18)
		"glowspores":
			m.mesh = quad("glow", 0.4)
			m.amount = 30
			m.color = Color(0.7, 0.5, 1.0, 0.8)
		"aurora_glints":
			m.mesh = quad("star", 0.2)
			m.amount = 50
			m.color = Color(0.5, 1.0, 0.75, 0.85)
		"mist_bank":
			m.mesh = quad("smoke", 5.0, false)
			m.amount = 24
			m.lifetime = 12.0
			m.preprocess = 12.0
			m.position.y = 0.9 - parent_y
			m.direction = Vector3(1, 0, 0.3)
			m.spread = 25.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 0.9
			m.color = Color(0.92, 0.96, 1.0, 0.2)
		"red_petals":
			m.mesh = quad("petal", 0.22, false)
			m.amount = 60
			m.lifetime = 7.0
			m.preprocess = 7.0
			m.position.y = 3.0 - parent_y
			m.direction = Vector3(0.3, -1, 0.1)
			m.spread = 40.0
			m.gravity = Vector3(0.4, -0.1, 0.1)
			m.angular_velocity_min = -120.0
			m.angular_velocity_max = 120.0
			m.color = Color(0.95, 0.15, 0.1, 0.95)
		"fog":
			m.mesh = quad("smoke", 3.0, false)
			m.amount = 22
			m.lifetime = 9.0
			m.preprocess = 9.0
			m.position.y = 0.6 - parent_y
			m.color = Color(0.85, 0.85, 0.95, 0.22)

# ---------------------------------------------------------------- combat bursts
static func _burst(parent: Node3D, pos: Vector3, col: Color, amount: int, speed: float, life: float, mesh: Mesh, gravity: Vector3, dir: Vector3 = Vector3(0, 1, 0), spread: float = 180.0, radius: float = 0.25) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = mesh
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = gravity
	p.damping_min = 1.0
	p.damping_max = 2.5
	p.scale_amount_min = 0.8
	p.scale_amount_max = 2.0
	p.scale_amount_curve = _shrink_curve()
	p.color = col
	p.color_ramp = _fade_ramp()
	p.position = pos
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.emitting = true
	var tm := parent.get_tree().create_timer(life + 0.3)
	tm.timeout.connect(p.queue_free)
	return p

static func _unshaded(col: Color, additive: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	m.vertex_color_use_as_albedo = true
	return m

static func _flash(parent: Node3D, pos: Vector3, col: Color, size: float, life: float) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	mi.mesh = q
	var m := _unshaded(Color(col.r, col.g, col.b, 0.9))
	m.albedo_texture = sprite("glow")
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mi.material_override = m
	mi.position = pos
	mi.scale = Vector3.ONE * 0.3
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, life)
	tw.chain().tween_callback(mi.queue_free)

## expanding flat ring on the ground
static func shockwave(parent: Node3D, pos: Vector3, col: Color, size: float = 5.0, life: float = 0.6) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := _unshaded(Color(col.r, col.g, col.b, 0.95))
	m.albedo_texture = sprite("ring")
	mi.material_override = m
	mi.position = pos + Vector3(0, 0.08, 0)
	mi.scale = Vector3.ONE * 0.4
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tw.tween_property(m, "albedo_color:a", 0.0, life).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)

## crescent sword-slash arc facing the camera side of the target
static func slash(parent: Node3D, pos: Vector3, col: Color, yaw: float = 0.0, size: float = 2.2, tilt: float = 0.5) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	b.arc(Vector3.ZERO, 1.0, 0.16, -1.3, 1.3, Color(col.r, col.g, col.b, 0.95), 24)
	b.arc(Vector3.ZERO, 0.93, 0.07, -1.1, 1.1, Color(1, 1, 1, 0.9), 20)
	var mi := MB.mesh_node(parent, b.build(MB.mat_glow()), pos)
	mi.rotation = Vector3(PI / 2 - tilt, yaw, 0.6)
	mi.scale = Vector3.ONE * size * 0.6
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "rotation:y", yaw + 1.2, 0.28)
	tw.tween_property(mi, "scale", Vector3.ONE * size, 0.28).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(mi, "scale", Vector3(size * 1.1, 0.01, size * 1.1), 0.12)
	tw.chain().tween_callback(mi.queue_free)

## glowing orb that flies from `a` to `b` leaving a sparkle trail, then calls `on_hit`
static func projectile(parent: Node3D, a: Vector3, b: Vector3, col: Color, life: float = 0.35, on_hit: Callable = Callable()) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		if on_hit.is_valid():
			on_hit.call()
		return
	var holder := Node3D.new()
	holder.position = a
	parent.add_child(holder)
	var orb := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.1, 1.1)
	orb.mesh = q
	var m := _unshaded(Color(col.r, col.g, col.b, 1.0))
	m.albedo_texture = sprite("glow")
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	orb.material_override = m
	holder.add_child(orb)
	var core := MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.45, 0.45)
	core.mesh = q2
	var m2 := _unshaded(Color(1, 1, 1, 1))
	m2.albedo_texture = sprite("star")
	m2.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	core.material_override = m2
	holder.add_child(core)
	var trail := CPUParticles3D.new()
	trail.mesh = quad("glow", 0.35)
	trail.amount = 40
	trail.lifetime = 0.4
	trail.local_coords = false
	trail.direction = Vector3(0, 1, 0)
	trail.spread = 180.0
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.gravity = Vector3.ZERO
	trail.color = col
	trail.color_ramp = _fade_ramp()
	trail.scale_amount_curve = _shrink_curve()
	holder.add_child(trail)
	trail.emitting = true
	var mid := (a + b) * 0.5 + Vector3(0, 1.4, 0)
	var tw := holder.create_tween()
	tw.tween_method(func(k: float):
		var p1 := a.lerp(mid, k)
		var p2 := mid.lerp(b, k)
		holder.position = p1.lerp(p2, k)
	, 0.0, 1.0, life).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if on_hit.is_valid():
			on_hit.call()
		orb.visible = false
		core.visible = false
		trail.emitting = false
	)
	tw.tween_interval(0.45)
	tw.tween_callback(holder.queue_free)

## vertical column of light / fire rising from the ground
static func pillar(parent: Node3D, pos: Vector3, col: Color, height: float = 6.0, radius: float = 0.9, life: float = 0.7) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	b.cyl(Vector3(0, 0.5, 0), 0.5, 1.0, Color(col.r, col.g, col.b, 0.55), Vector3.ZERO, 14)
	b.cyl(Vector3(0, 0.5, 0), 0.25, 1.0, Color(1, 1, 1, 0.5), Vector3.ZERO, 14)
	var mi := MB.mesh_node(parent, b.build(MB.mat_glow()), pos)
	mi.scale = Vector3(radius * 2.0, 0.05, radius * 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(radius * 2.0, height, radius * 2.0), life * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(mi, "scale", Vector3(0.02, height * 1.2, 0.02), life * 0.7).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	_burst(parent, pos + Vector3(0, 0.3, 0), col, 36, 4.0, life + 0.3, quad("glow", 0.35), Vector3(0, 6.0, 0), Vector3(0, 1, 0), 25.0, radius)

## jagged lightning bolt from the sky down to `pos`
static func lightning(parent: Node3D, pos: Vector3, col: Color = Color(0.85, 0.9, 1.0), height: float = 14.0, life: float = 0.35) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 1000.0 + pos.z * 37.0 + Time.get_ticks_msec())
	var pts: Array = []
	var p := Vector3(rng.randf_range(-1.5, 1.5), height, rng.randf_range(-1.5, 1.5))
	var steps := 10
	for i in steps + 1:
		var k := i / float(steps)
		pts.append(p.lerp(Vector3.ZERO, k) + (Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6)) if i > 0 and i < steps else Vector3.ZERO))
	var wd: Array = []
	for i in pts.size():
		wd.append(0.22 * (1.0 - i / float(pts.size())) + 0.06)
	b.ribbon(pts, wd, Vector3.RIGHT, Color(col.r, col.g, col.b, 0.95), Color(1, 1, 1, 1))
	b.ribbon(pts, wd, Vector3.BACK, Color(col.r, col.g, col.b, 0.95), Color(1, 1, 1, 1))
	# a forked branch
	var fk: int = rng.randi_range(3, 6)
	var bp: Array = [pts[fk], pts[fk] + Vector3(rng.randf_range(-2, 2), -2.0, rng.randf_range(-2, 2))]
	b.ribbon(bp, [0.1, 0.02], Vector3.RIGHT, Color(col.r, col.g, col.b, 0.8))
	var mi := MB.mesh_node(parent, b.build(MB.mat_glow()), pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 4.0
	light.omni_range = 12.0
	light.position = Vector3(0, 2, 0)
	mi.add_child(light)
	var tw := mi.create_tween()
	tw.tween_property(light, "light_energy", 0.0, life)
	tw.parallel().tween_property(mi, "scale", Vector3(0.2, 1.0, 0.2), life).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	_flash(parent, pos + Vector3(0, 0.5, 0), Color.WHITE, 3.5, 0.25)
	shockwave(parent, pos, col, 4.0, 0.4)

## stone spikes bursting out of the ground in a ring
static func spikes(parent: Node3D, pos: Vector3, col: Color, count: int = 7, life: float = 0.9) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	var stone := MB.tag(col.darkened(0.35), MB.STONE)
	for i in count:
		var a := TAU * i / count + 0.3
		var r := 0.7 + (i % 3) * 0.35
		b.cone(Vector3(cos(a) * r, 0.6, sin(a) * r), 0.28 + (i % 2) * 0.1, 1.4 + (i % 3) * 0.5, stone, Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35), 6)
	b.cone(Vector3(0, 0.9, 0), 0.4, 2.0, MB.tag(col.darkened(0.2), MB.STONE), Vector3.ZERO, 6)
	var mi := MB.mesh_node(parent, b.build(MB.mat_plain()), pos + Vector3(0, -2.2, 0))
	var tw := mi.create_tween()
	tw.tween_property(mi, "position:y", pos.y, life * 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(life * 0.5)
	tw.tween_property(mi, "position:y", pos.y - 2.4, life * 0.32).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	_burst(parent, pos + Vector3(0, 0.2, 0), col.darkened(0.2), 30, 5.0, 0.8, quad("smoke", 0.6, false), Vector3(0, -8.0, 0), Vector3(0, 1, 0), 70.0, 0.8)

## swirling dark vortex
static func vortex(parent: Node3D, pos: Vector3, col: Color, size: float = 2.4, life: float = 0.9) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	for k in 3:
		b.arc(Vector3(0, k * 0.35, 0), 1.0 - k * 0.22, 0.12, k * 2.1, k * 2.1 + 4.0, Color(col.r, col.g, col.b, 0.85 - k * 0.15), 20)
	b.disc(Vector3(0, 0.05, 0), 0.5, Color(0.02, 0.0, 0.06, 0.0), 12, Color(col.r, col.g, col.b, 0.6))
	var mi := MB.mesh_node(parent, b.build(MB.mat_glow()), pos)
	mi.scale = Vector3.ONE * 0.2
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "rotation:y", -TAU * 1.5, life)
	tw.tween_property(mi, "scale", Vector3.ONE * size, life * 0.4).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(mi, "scale", Vector3(0.01, size * 2.0, 0.01), life * 0.4).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)
	_burst(parent, pos + Vector3(0, 0.8, 0), col, 34, 2.5, life, quad("glow", 0.3), Vector3(0, 1.5, 0), Vector3(0, 1, 0), 180.0, 1.2)

## a spiral of leaves around a point
static func leaf_spiral(parent: Node3D, pos: Vector3, col: Color, life: float = 1.0) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	var b := MB.new()
	for i in 14:
		var a := TAU * i / 14.0
		var r := 1.0 + (i % 3) * 0.25
		var root := Vector3(cos(a) * r, i * 0.12, sin(a) * r)
		b.leaf(root, root + Vector3(-sin(a), 0.15, cos(a)) * 0.5, 0.12, MB.tag(col, MB.FOLIAGE), Vector3.UP, MB.tag(col.lightened(0.3), MB.FOLIAGE))
	var mi := MB.mesh_node(holder, b.build(MB.mat_plain()))
	mi.position.y = -0.6
	var tw := holder.create_tween()
	tw.set_parallel(true)
	tw.tween_property(holder, "rotation:y", TAU, life)
	tw.tween_property(holder, "scale", Vector3(0.1, 1.6, 0.1), life).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(holder.queue_free)

## expanding water ring with droplets
static func splash(parent: Node3D, pos: Vector3, col: Color, life: float = 0.8, size: float = 1.0) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	b.torus(Vector3.ZERO, 1.0, 0.07, Color(col.r, col.g, col.b, 0.85), Vector3.ZERO, true)
	b.torus(Vector3(0, 0.3, 0), 0.75, 0.05, Color(1, 1, 1, 0.7), Vector3.ZERO, true)
	var mi := MB.mesh_node(parent, b.build(MB.mat_glow()), pos)
	mi.scale = Vector3.ONE * 0.2
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(2.4, 2.8, 2.4) * size, life).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "position:y", pos.y + 1.2 * size, life)
	tw.chain().tween_callback(mi.queue_free)

## element-coloured hit effect at a world position (big = boss heavy attack or a technique)
static func hit(parent: Node3D, pos: Vector3, elem: String, big: bool = false) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var col: Color = Data.ELEM_COLORS.get(elem, Color.WHITE)
	var k := 1.5 if big else 1.0
	_flash(parent, pos, col, 2.6 * k, 0.35)
	var ground := Vector3(pos.x, 0.0, pos.z)
	match elem:
		"fire":
			_burst(parent, pos, col, int(44 * k), 5.0, 0.9, quad("glow", 0.4), Vector3(0, 3.5, 0))
			_burst(parent, pos, Color(0.3, 0.25, 0.25, 0.6), 16, 1.5, 1.4, quad("smoke", 0.9, false), Vector3(0, 2.0, 0))
			if big:
				pillar(parent, ground, col, 5.0, 1.0)
		"water":
			_burst(parent, pos, col, int(48 * k), 5.0, 0.9, quad("glow", 0.3), Vector3(0, -9.0, 0), Vector3(0, 1, 0), 70.0)
			splash(parent, ground + Vector3(0, 0.2, 0), col)
		"wood":
			_burst(parent, pos, col, int(36 * k), 4.5, 1.0, _leaves(), Vector3(0, -3.0, 0))
			leaf_spiral(parent, ground + Vector3(0, 1.0, 0), col)
		"earth":
			_burst(parent, pos, col, int(30 * k), 4.5, 0.9, quad("smoke", 0.5, false), Vector3(0, -12.0, 0), Vector3(0, 1, 0), 60.0)
			spikes(parent, ground, col, 7 if big else 5)
		"thunder":
			_burst(parent, pos, col, int(26 * k), 9.0, 0.45, _bolts(), Vector3.ZERO)
			lightning(parent, ground, col.lerp(Color.WHITE, 0.4))
		"dark":
			_burst(parent, pos, col, int(36 * k), 4.0, 0.9, quad("glow", 0.35), Vector3(0, 0.5, 0))
			vortex(parent, ground, col)
		_:
			_burst(parent, pos, Color(1, 1, 0.9), int(24 * k), 6.0, 0.5, quad("star", 0.3), Vector3.ZERO)
	if big:
		shockwave(parent, ground, col, 7.0, 0.7)

static func heal(parent: Node3D, pos: Vector3) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var col := Color(0.5, 1.0, 0.8, 0.9)
	_burst(parent, pos, col, 34, 2.0, 1.2, quad("star", 0.26), Vector3(0, 1.5, 0), Vector3(0, 1, 0), 40.0)
	_flash(parent, pos, Color(0.5, 1.0, 0.8), 1.8, 0.5)
	var ground := Vector3(pos.x, 0.0, pos.z)
	shockwave(parent, ground, col, 3.0, 0.8)
	pillar(parent, ground, col, 4.0, 0.6, 0.9)

## Ring of light and rising sparks used when cultivation advances.
static func ascend(parent: Node3D, pos: Vector3, col: Color = Color(1.0, 0.85, 0.4)) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	pillar(parent, pos, col, 9.0, 1.2, 1.4)
	shockwave(parent, pos, col, 9.0, 1.0)
	_burst(parent, pos + Vector3(0, 1.0, 0), col, 60, 3.0, 1.8, quad("star", 0.3), Vector3(0, 2.5, 0), Vector3(0, 1, 0), 60.0, 1.0)

## A few small things drifting up from a point and fading: notes off a qin, steam off a pot, incense
## smoke, embers off a fire, qi gathering about a sitter, a sleeper's z's. Quiet, nothing like `ascend`.
## (Pale smoke and steam are soft glows added on: the mixed particle quads come out dark in the middle.)
static func drift(parent: Node3D, pos: Vector3, col: Color, kind: String = "glow", amount: int = 4, size: float = 0.25,
		rise: float = 0.5, life: float = 2.0, radius: float = 0.15, additive: bool = true) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles3D.new()
	p.mesh = quad(kind, size, additive)
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.35
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3(0, 1, 0)
	p.spread = 28.0
	p.initial_velocity_min = rise * 0.6
	p.initial_velocity_max = rise
	p.gravity = Vector3(0, 0.05, 0)
	p.damping_min = 0.05
	p.damping_max = 0.2
	p.scale_amount_min = 0.75
	p.scale_amount_max = 1.15
	p.color = col
	p.color_ramp = _fade_ramp()
	p.position = pos
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.emitting = true
	var tm := parent.get_tree().create_timer(life * 2.0 + 0.3)
	tm.timeout.connect(p.queue_free)

## Soot smouldering off a grudge (grudges.gd, Part XIV): dark smoke rising round the body for as long as
## it stands, with a few grudge-red embers and tally-slips of ash drifting up in it.
static func soot(parent: Node3D, col: Color) -> void:
	if headless() or parent == null:
		return
	var smoke := CPUParticles3D.new()
	smoke.mesh = quad("smoke", 0.9, false)
	smoke.amount = 18
	smoke.lifetime = 2.6
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 0.55
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 20.0
	smoke.initial_velocity_min = 0.35
	smoke.initial_velocity_max = 0.7
	smoke.gravity = Vector3(0, 0.12, 0)
	smoke.scale_amount_min = 0.7
	smoke.scale_amount_max = 1.4
	smoke.color = Color(col.r * 0.25, col.g * 0.18, col.b * 0.22, 0.55)
	smoke.color_ramp = _fade_ramp(0.8)
	smoke.position = Vector3(0, 0.9, 0)
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(smoke)
	var embers := CPUParticles3D.new()
	embers.mesh = quad("glow", 0.16)
	embers.amount = 12
	embers.lifetime = 2.0
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 0.6
	embers.direction = Vector3(0, 1, 0)
	embers.spread = 35.0
	embers.initial_velocity_min = 0.4
	embers.initial_velocity_max = 0.9
	embers.gravity = Vector3(0, 0.2, 0)
	embers.color = Color(1.0, 0.3, 0.42, 0.9)
	embers.color_ramp = _fade_ramp()
	embers.position = Vector3(0, 0.8, 0)
	embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(embers)

## A small glint and a few stars rising: a blessing at a statue, herbs found, a lamp lit.
static func glimmer(parent: Node3D, pos: Vector3, col: Color = Color(1.0, 0.9, 0.6)) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	_flash(parent, pos, col, 1.3, 0.5)
	var p := _burst(parent, pos, Color(col.r, col.g, col.b, 0.9), 14, 1.1, 1.4, quad("star", 0.2), Vector3(0, 0.7, 0), Vector3(0, 1, 0), 55.0, 0.3)
	p.explosiveness = 0.7

## A spray of sparks off a hammer blow.
static func sparks(parent: Node3D, pos: Vector3, col: Color = Color(1.0, 0.72, 0.3)) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	_flash(parent, pos, col, 0.9, 0.2)
	var p := _burst(parent, pos, col, 18, 3.5, 0.55, quad("glow", 0.14), Vector3(0, -7.0, 0), Vector3(0, 1, 0), 75.0, 0.06)
	p.scale_amount_max = 1.3

## Little cloud of dust at the feet (footsteps, landing).
static func dust(parent: Node3D, pos: Vector3, col: Color) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var p := _burst(parent, pos + Vector3(0, 0.1, 0), Color(col.r, col.g, col.b, 0.45), 5, 0.6, 0.7, quad("smoke", 0.45, false), Vector3(0, 0.4, 0), Vector3(0, 1, 0), 80.0, 0.15)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.1

## Charge-up glow around a caster before a technique.
static func charge(parent: Node3D, pos: Vector3, col: Color, life: float = 0.4) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var p := _burst(parent, pos, col, 26, 0.2, life, quad("star", 0.24), Vector3.ZERO, Vector3(0, 1, 0), 180.0, 1.4)
	p.explosiveness = 0.6
	p.radial_accel_min = -9.0
	p.radial_accel_max = -6.0
	_flash(parent, pos, col, 1.4, life)

# ---------------------------------------------------------------- signature techniques
const FIVE := [Color("ff5050"), Color("ffd040"), Color("50a0ff"), Color("f0f0ff"), Color("b070ff")]

## A meteor that falls from the sky onto `pos` trailing sparks, then bursts.
static func meteor(parent: Node3D, pos: Vector3, col: Color, delay: float = 0.0, size: float = 1.0) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var start := pos + Vector3(-6.0 + randf() * 3.0, 16.0, randf_range(-3.0, 3.0))
	var go := func():
		projectile(parent, start, pos + Vector3(0, 0.3, 0), col, 0.45, func():
			_flash(parent, pos + Vector3(0, 0.6, 0), col.lerp(Color.WHITE, 0.5), 4.0 * size, 0.3)
			shockwave(parent, pos, col, 5.0 * size, 0.5)
			_burst(parent, pos + Vector3(0, 0.3, 0), col, 26, 6.0, 0.7, quad("star", 0.3), Vector3(0, -9.0, 0), Vector3(0, 1, 0), 70.0, 0.4))
	if delay <= 0.0:
		go.call()
	else:
		parent.get_tree().create_timer(delay).timeout.connect(go)

## Five glowing rings in Nuwa's colours spiralling upward around a point (mending / threads).
static func five_rings(parent: Node3D, pos: Vector3, life: float = 1.2, radius: float = 1.2) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	for k in 5:
		var b := MB.new()
		var c: Color = FIVE[k]
		b.arc(Vector3.ZERO, radius * (1.0 - k * 0.1), 0.07, 0.0, TAU * 0.8, Color(c.r, c.g, c.b, 0.9), 28)
		var mi := MB.mesh_node(holder, b.build(MB.mat_glow()))
		mi.position.y = 0.1
		mi.rotation = Vector3(0.25 * sin(k * 1.3), k * 1.256, 0.25 * cos(k * 1.3))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tw := mi.create_tween()
		tw.set_parallel(true)
		tw.tween_property(mi, "position:y", 1.2 + k * 0.45, life).set_delay(k * 0.06).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "rotation:y", mi.rotation.y + TAU, life)
		tw.tween_property(mi, "scale", Vector3.ONE * 0.2, life).set_ease(Tween.EASE_IN)
	_burst(parent, pos + Vector3(0, 0.6, 0), Color(1, 1, 1), 30, 2.0, life, quad("star", 0.25), Vector3(0, 2.0, 0), Vector3(0, 1, 0), 60.0, radius)
	parent.get_tree().create_timer(life + 0.3).timeout.connect(holder.queue_free)

## A stone pillar wrapped in five-coloured bands that drops out of the sky onto the target.
static func sky_pillar(parent: Node3D, pos: Vector3, col: Color, life: float = 1.1, radius: float = 1.0) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	var stone := MB.tag(Color("d8d0c0"), MB.STONE)
	b.cyl(Vector3(0, 4.0, 0), radius, 8.0, stone, Vector3.ZERO, 14)
	b.cyl(Vector3(0, 0.25, 0), radius * 1.35, 0.5, stone, Vector3.ZERO, 14)
	var g := MB.new()
	for k in 5:
		var c: Color = FIVE[k]
		b.cyl(Vector3(0, 1.2 + k * 1.4, 0), radius * 1.06, 0.3, MB.tag(c, MB.CRYSTAL), Vector3.ZERO, 14)
		g.cyl(Vector3(0, 1.2 + k * 1.4, 0), radius * 1.12, 0.12, Color(c.r, c.g, c.b, 0.8), Vector3.ZERO, 14)
	var mesh := b.build(MB.mat_vc())
	g.add_to(mesh, MB.mat_glow())
	var mi := MB.mesh_node(parent, mesh, pos + Vector3(0, 18.0, 0))
	var tw := mi.create_tween()
	tw.tween_property(mi, "position:y", pos.y - 0.2, life * 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		shockwave(parent, pos, col, 9.0 * radius, 0.6)
		shockwave(parent, pos, Color.WHITE, 6.0 * radius, 0.4)
		spikes(parent, pos, col, 9, 0.8)
		_burst(parent, pos + Vector3(0, 0.4, 0), Color(0.85, 0.8, 0.7), 40, 7.0, 0.9, quad("smoke", 0.9, false), Vector3(0, -4.0, 0), Vector3(0, 1, 0), 80.0, 1.2))
	tw.tween_interval(life * 0.45)
	tw.tween_property(mi, "scale", Vector3(1.0, 0.01, 1.0), life * 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)

## Ink-black crescent slashes crossing over the target (Ledger-Breaking Stroke and its kin).
static func cross_slash(parent: Node3D, pos: Vector3, col: Color, yaw: float) -> void:
	slash(parent, pos, col, yaw, 3.6, 0.2)
	slash(parent, pos + Vector3(0, 0.2, 0), col.lerp(Color.WHITE, 0.4), yaw + PI * 0.5, 3.2, 1.0)
	vortex(parent, pos + Vector3(0, -1.2, 0), col, 2.0, 0.7)

## the six paths of rebirth: gods, men, titans, beasts, hungry ghosts and hells
const SIX := [Color("fff0b0"), Color("a0e0ff"), Color("ff7050"), Color("90e070"), Color("c0a0ff"), Color("ff4080")]

## A spoked wheel of light that spins up in front of the target and shatters into six beams.
static func samsara_wheel(parent: Node3D, pos: Vector3, col: Color, yaw: float, radius: float = 1.6, life: float = 0.9) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	b.arc(Vector3.ZERO, radius, 0.14, 0.0, TAU, Color(col.r, col.g, col.b, 0.95), 40, Vector3(PI * 0.5, 0, 0))
	b.arc(Vector3.ZERO, radius * 0.35, 0.1, 0.0, TAU, Color(1, 1, 1, 0.9), 20, Vector3(PI * 0.5, 0, 0))
	for k in 6:
		var a := TAU * k / 6.0
		var c: Color = SIX[k]
		b.box(Vector3(cos(a), sin(a), 0) * radius * 0.67, Vector3(radius * 0.62, 0.07, 0.02), Color(c.r, c.g, c.b, 0.9), Vector3(0, 0, a))
		b.ball(Vector3(cos(a), sin(a), 0) * radius, 0.16, Color(c.r, c.g, c.b, 0.95), true)
	var mi := MB.mesh_node(parent, b.build(MB.mat_glow()), pos)
	mi.rotation.y = yaw + PI * 0.5
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3.ONE * 0.2
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE, life * 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(mi, "rotation:z", TAU * 1.5, life).set_ease(Tween.EASE_IN)
	tw.chain().tween_property(mi, "scale", Vector3.ONE * 1.6, life * 0.25)
	tw.chain().tween_callback(func():
		shockwave(parent, pos - Vector3(0, pos.y - 0.1, 0) + Vector3(0, 0.0, 0), col, 6.0, 0.5)
		_burst(parent, pos, col, 40, 6.0, 0.7, quad("star", 0.3), Vector3.ZERO, Vector3(0, 0, 1), 180.0, radius)
		mi.queue_free())

## Paper soul-lanterns drift down onto the target and burst into fox-fire.
static func lantern_rain(parent: Node3D, pos: Vector3, delay: float = 0.0, count: int = 7) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	for k in count:
		var lb := MB.new()
		lb.lathe(Vector3.ZERO, [Vector2(0.12, -0.18), Vector2(0.2, -0.05), Vector2(0.2, 0.08), Vector2(0.12, 0.2)], MB.tag(Color("fff0c8"), MB.CLOTH), 10)
		lb.cyl(Vector3(0, -0.2, 0), 0.13, 0.04, MB.tag(Color("c03020"), MB.WOOD), Vector3.ZERO, 10)
		lb.cyl(Vector3(0, 0.22, 0), 0.13, 0.04, MB.tag(Color("c03020"), MB.WOOD), Vector3.ZERO, 10)
		var mesh := lb.build(MB.mat_plain())
		var gb := MB.new()
		gb.ball(Vector3.ZERO, 0.3, Color(1.0, 0.65, 0.3, 0.6), true)
		gb.add_to(mesh, MB.mat_glow())
		var start := pos + Vector3(randf_range(-2.0, 2.0), randf_range(6.0, 9.0), randf_range(-2.0, 2.0))
		var mi := MB.mesh_node(parent, mesh, start)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tw := mi.create_tween()
		tw.tween_interval(delay + k * 0.06)
		tw.set_parallel(true)
		tw.tween_property(mi, "position", pos + Vector3(randf_range(-0.8, 0.8), 1.2, randf_range(-0.8, 0.8)), 0.55).set_ease(Tween.EASE_IN)
		tw.tween_property(mi, "rotation:y", randf_range(-3.0, 3.0), 0.55)
		tw.chain().tween_callback(func():
			_flash(parent, mi.position, Color(1.0, 0.6, 0.25), 1.6, 0.3)
			_burst(parent, mi.position, Color(1.0, 0.7, 0.3), 12, 3.0, 0.6, _sparks(), Vector3(0, -2.0, 0))
			mi.queue_free())

## A golden lotus opens under each ally and lifts them in a column of petals (Lotus of Rebirth).
static func rebirth_lotus(parent: Node3D, pos: Vector3) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	var b := MB.new()
	for layer in 2:
		for k in 8:
			var a := TAU * (k + layer * 0.5) / 8.0
			var r := 0.9 - layer * 0.3
			b.leaf(Vector3(0, 0.05, 0), Vector3(cos(a) * r, 0.35 + layer * 0.25, sin(a) * r), 0.22 - layer * 0.05, Color(1.0, 0.85 - layer * 0.1, 0.6, 0.85), Vector3(-sin(a), 0, cos(a)), Color(1.0, 0.95, 0.85, 0.6))
	var mi := MB.mesh_node(parent, b.build(MB.mat_glow()), pos + Vector3(0, 0.05, 0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3(0.1, 0.1, 0.1)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(mi, "rotation:y", PI, 1.2)
	tw.tween_property(mi, "scale", Vector3(1.4, 0.01, 1.4), 0.4)
	tw.tween_callback(mi.queue_free)
	pillar(parent, pos, Color(1.0, 0.85, 0.5), 5.0, 0.8, 1.0)
	_burst(parent, pos + Vector3(0, 0.3, 0), Color(1.0, 0.8, 0.9), 30, 2.5, 1.2, _leaves(), Vector3(0, 1.5, 0), Vector3(0, 1, 0), 40.0, 0.8)

## Extra flourish for the late-game techniques, on top of the usual projectile and hit effects.
## `from` is the caster, `targets` the struck positions.
static func technique(parent: Node3D, id: String, from: Vector3, targets: Array, cam_yaw: float = 0.0) -> void:
	if headless() or parent == null or not parent.is_inside_tree():
		return
	match id:
		"skymend":
			for t in targets:
				sky_pillar(parent, t, Color("ffd890"), 1.1, 1.0)
		"pillar":
			for t in targets:
				sky_pillar(parent, t, Color("c8e0ff"), 1.3, 1.5)
				lightning(parent, t, Color(0.85, 0.9, 1.0), 22.0, 0.4)
		"fivecolour":
			for i in targets.size():
				for k in 3:
					meteor(parent, targets[i] + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8)), FIVE[(i + k) % 5], 0.12 * k + 0.05 * i, 0.7)
		"starfall", "meteor":
			for i in targets.size():
				meteor(parent, targets[i], Color("ffa040") if id == "meteor" else Color("ffe080"), 0.1 * i, 1.0)
		"genesis", "judgement", "heaven":
			for t in targets:
				lightning(parent, t, Color(1.0, 0.95, 0.7), 20.0, 0.35)
				pillar(parent, t, Color(1.0, 0.9, 0.5), 9.0, 1.2, 0.8)
		"inkbreak", "voidcut", "chrono":
			for t in targets:
				cross_slash(parent, t + Vector3(0, 1.4, 0), Color("6040a0") if id != "inkbreak" else Color("203040"), cam_yaw)
		"mending", "seal_bloom", "dawn":
			for t in targets:
				five_rings(parent, t, 1.2, 1.1)
		"thread":
			for t in targets:
				five_rings(parent, t, 0.9, 1.4)
				spikes(parent, t, Color("d0a060"), 5, 0.6)
		# ---- Part VI
		"wheelcut":
			for t in targets:
				samsara_wheel(parent, t + Vector3(0, 1.4, 0), Color("8060ff"), cam_yaw, 1.6, 0.8)
				cross_slash(parent, t + Vector3(0, 1.4, 0), Color("4030a0"), cam_yaw)
		"samsara":
			for t in targets:
				samsara_wheel(parent, t + Vector3(0, 2.2, 0), Color("ffe0a0"), cam_yaw, 2.6, 1.2)
				for k in 6:
					var a := TAU * k / 6.0
					pillar(parent, t + Vector3(cos(a) * 1.6, 0, sin(a) * 1.6), SIX[k], 6.0, 0.35, 0.9)
				lightning(parent, t, Color(1.0, 0.95, 0.8), 20.0, 0.35)
		"lanternrain", "lantern_ward":
			for i in targets.size():
				lantern_rain(parent, targets[i], 0.08 * i, 9 if id == "lanternrain" else 5)
		"rebirth":
			for t in targets:
				rebirth_lotus(parent, t)
