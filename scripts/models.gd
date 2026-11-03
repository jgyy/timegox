class_name Models
extends RefCounted
## Procedural 3D character and monster models.  Everything faces +Z; one unit is roughly one metre.
## No imported assets: every model is merged from primitives by MB.

const SKIN := Color("f0c8a0")

static func _mi(parent: Node3D, mb: MB, mat: Material = null, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mb.build(mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	return p

# ---------------------------------------------------------------- people
## robe/hair colours + options: sword, staff, beard, hat, ribbon(Color), horns, scale, glow(Color)
static func person(robe: Color, hair: Color, o: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	var parts := {}
	var trim: Color = o.get("trim", robe.lightened(0.45))
	var dark := robe.darkened(0.45)
	# torso
	var b := MB.new()
	b.prim("fr8", MB._xf(Vector3(0, 0.74, 0), Vector3(0.82, 0.96, 0.62), Vector3.ZERO), robe)
	b.box(Vector3(0, 1.2, 0), Vector3(0.64, 0.16, 0.34), robe.lightened(0.08))
	b.cyl(Vector3(0, 0.86, 0), 0.27, 0.08, trim, Vector3.ZERO, 14)
	b.cyl(Vector3(0, 1.3, 0.02), 0.2, 0.07, Color("f4f0e0"), Vector3.ZERO, 14)
	if o.get("sash", true):
		b.box(Vector3(0.1, 0.55, 0.28), Vector3(0.1, 0.5, 0.04), trim)
	if o.has("ribbon"):
		b.box(Vector3(0, 0.7, -0.27), Vector3(0.16, 0.8, 0.04), o.ribbon)
	_mi(root, b)
	parts["body"] = root.get_child(root.get_child_count() - 1)
	# head
	var head := _pivot(root, Vector3(0, 1.55, 0))
	var hb := MB.new()
	hb.ball(Vector3.ZERO, 0.23, SKIN)
	hb.sph(Vector3(0, 0.07, -0.04), Vector3(0.26, 0.22, 0.26), hair)
	hb.ball(Vector3(0, 0.32, -0.05), 0.1, hair, true)
	hb.ball(Vector3(-0.08, 0.0, 0.21), 0.036, Color("1a1a24"), true)
	hb.ball(Vector3(0.08, 0.0, 0.21), 0.036, Color("1a1a24"), true)
	if o.get("beard", false):
		hb.cone(Vector3(0, -0.2, 0.08), 0.12, 0.3, Color("f4f4f8"), Vector3(PI, 0, 0))
		hb.sph(Vector3(0, 0.06, -0.03), Vector3(0.2, 0.18, 0.2), Color("e8e8f0"))
	if o.get("hat", false):
		hb.cyl(Vector3(0, 0.16, 0), 0.34, 0.03, Color("8a6a3a"), Vector3.ZERO, 14)
		hb.cone(Vector3(0, 0.3, 0), 0.2, 0.26, Color("8a6a3a"), Vector3.ZERO, 14)
	if o.get("horns", false):
		hb.cone(Vector3(-0.1, 0.27, 0), 0.05, 0.3, Color("2a1020"), Vector3(0, 0, 0.35))
		hb.cone(Vector3(0.1, 0.27, 0), 0.05, 0.3, Color("2a1020"), Vector3(0, 0, -0.35))
	if o.has("ribbon"):
		hb.box(Vector3(0, 0.2, -0.17), Vector3(0.07, 0.07, 0.04), o.ribbon)
		hb.box(Vector3(-0.08, -0.12, -0.2), Vector3(0.03, 0.34, 0.03), o.ribbon)
	_mi(head, hb)
	parts["head"] = head
	if o.get("red_eyes", false):
		var eg := MB.new()
		eg.ball(Vector3(-0.06, 0.0, 0.17), 0.04, Color(1, 0.15, 0.1, 1.0), true)
		eg.ball(Vector3(0.06, 0.0, 0.17), 0.04, Color(1, 0.15, 0.1, 1.0), true)
		_mi(head, eg, MB.mat_glow())
	# arms
	for s in [-1, 1]:
		var arm := _pivot(root, Vector3(0.33 * s, 1.2, 0))
		var ab := MB.new()
		ab.cyl(Vector3(0, -0.26, 0), 0.07, 0.52, robe.lightened(0.05))
		ab.ball(Vector3(0, -0.56, 0), 0.065, SKIN, true)
		_mi(arm, ab)
		parts["arm%d" % s] = arm
	# legs
	for s in [-1, 1]:
		var leg := _pivot(root, Vector3(0.1 * s, 0.32, 0))
		var lb := MB.new()
		lb.cyl(Vector3(0, -0.16, 0), 0.075, 0.34, dark)
		lb.box(Vector3(0, -0.32, 0.04), Vector3(0.14, 0.07, 0.24), Color("1c1820"))
		_mi(leg, lb)
		parts["leg%d" % s] = leg
	# held items (right arm)
	var ra: Node3D = parts["arm1"]
	if o.get("sword", false):
		var sw := _pivot(ra, Vector3(0, -0.56, 0.02))
		sw.rotation.x = -1.25
		var sb := MB.new()
		sb.box(Vector3(0, 0.46, 0), Vector3(0.05, 0.9, 0.012), Color("dbe8f8"))
		sb.box(Vector3(0, 0.0, 0), Vector3(0.18, 0.04, 0.05), Color("d8b050"))
		sb.cyl(Vector3(0, -0.1, 0), 0.025, 0.2, Color("5a3a2a"))
		_mi(sw, sb)
		var sg := MB.new()
		sg.box(Vector3(0, 0.46, 0), Vector3(0.09, 0.95, 0.04), Color(0.6, 0.85, 1.0, 0.35))
		_mi(sw, sg, MB.mat_glow())
	if o.get("staff", false):
		var st := _pivot(ra, Vector3(0, -0.56, 0.04))
		var sb2 := MB.new()
		sb2.cyl(Vector3(0, 0.3, 0), 0.03, 1.9, Color("7a5a3a"))
		sb2.ball(Vector3(0, 1.28, 0), 0.09, Color("ffe080"))
		_mi(st, sb2)
		var sg2 := MB.new()
		sg2.ball(Vector3(0, 1.28, 0), 0.22, Color(1, 0.85, 0.4, 0.35))
		_mi(st, sg2, MB.mat_glow())
	if o.has("glow"):
		var gb := MB.new()
		var gc: Color = o.glow
		gb.sph(Vector3(0, 0.95, 0), Vector3(0.75, 1.1, 0.75), Color(gc.r, gc.g, gc.b, 0.07))
		_mi(root, gb, MB.mat_glow())
	root.set_meta("p", parts)
	root.set_meta("kind", "person")
	var sc: float = o.get("scale", 1.0)
	root.scale = Vector3(sc, sc, sc)
	return root

static func anim_person(n: Node3D, t: float, walking: bool, sit: bool = false) -> void:
	var p: Dictionary = n.get_meta("p")
	var ph := t * 9.0
	if walking:
		p["leg-1"].rotation.x = sin(ph) * 0.75
		p["leg1"].rotation.x = -sin(ph) * 0.75
		p["arm-1"].rotation.x = -sin(ph) * 0.6
		p["arm1"].rotation.x = sin(ph) * 0.4
		p["body"].position.y = absf(sin(ph)) * 0.05
		p["head"].position.y = 1.55 + absf(sin(ph)) * 0.05
	else:
		var br := sin(t * 2.0) * 0.02
		p["leg-1"].rotation.x = 0.0
		p["leg1"].rotation.x = 0.0
		p["arm-1"].rotation.x = sin(t * 1.6) * 0.05
		p["arm1"].rotation.x = -sin(t * 1.6) * 0.05
		p["body"].position.y = 0.0
		p["head"].position.y = 1.55 + br
	if sit:
		p["leg-1"].rotation.x = -1.5
		p["leg1"].rotation.x = -1.5
		p["arm-1"].rotation.x = -0.6
		p["arm1"].rotation.x = -0.6

# ---------------------------------------------------------------- props
static func lotus(col: Color, radius: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	for ring in 2:
		var n := 8 + ring * 2
		for i in n:
			var a := TAU * (i + ring * 0.5) / n
			var r := radius * (0.62 + ring * 0.38)
			var xf := Transform3D(Basis.from_euler(Vector3(0.0, -a, 0.0)) * Basis.from_euler(Vector3(0, 0, -0.45 + ring * 0.2)).scaled(Vector3(0.5 * radius, 0.1, 0.22 * radius) * 1.0), Vector3(sin(a) * r, 0.06 + (1 - ring) * 0.08, cos(a) * r))
			b.prim("sph", xf, col.lerp(Color.WHITE, 0.25 + ring * 0.2))
	b.cyl(Vector3(0, 0.0, 0), radius * 0.45, 0.1, col.darkened(0.2), Vector3.ZERO, 14)
	_mi(root, b)
	var g := MB.new()
	g.cyl(Vector3(0, 0.05, 0), radius * 1.4, 0.02, Color(col.r, col.g, col.b, 0.35), Vector3.ZERO, 14)
	_mi(root, g, MB.mat_glow())
	return root

static func shadow_disc(r: float, alpha: float = 0.4) -> MeshInstance3D:
	var b := MB.new()
	b.cyl(Vector3(0, 0.02, 0), r, 0.01, Color(0, 0, 0, alpha), Vector3.ZERO, 14)
	var mi := MeshInstance3D.new()
	mi.mesh = b.build(MB.mat_glass())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func gem(col: Color) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	b.cone(Vector3(0, 0.3, 0), 0.26, 0.5, col.lightened(0.15), Vector3.ZERO, 4)
	b.cone(Vector3(0, -0.05, 0), 0.26, 0.4, col, Vector3(PI, 0, 0), 4)
	_mi(root, b)
	var g := MB.new()
	g.ball(Vector3(0, 0.15, 0), 0.6, Color(col.r, col.g, col.b, 0.22))
	g.ball(Vector3(0, 0.15, 0), 0.36, Color(col.r, col.g, col.b, 0.3))
	_mi(root, g, MB.mat_glow())
	return root

static func portal(col: Color, open: bool) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	b.cyl(Vector3(-1.1, 1.5, 0), 0.14, 3.0, Color("7a5a3a").lerp(col, 0.25))
	b.cyl(Vector3(1.1, 1.5, 0), 0.14, 3.0, Color("7a5a3a").lerp(col, 0.25))
	b.box(Vector3(0, 3.1, 0), Vector3(2.8, 0.2, 0.28), Color("8a3a2a").lerp(col, 0.3))
	b.box(Vector3(0, 2.8, 0), Vector3(2.4, 0.1, 0.18), Color("c8a850"))
	b.box(Vector3(0, 3.28, 0), Vector3(3.2, 0.1, 0.34), Color("8a3a2a").lerp(col, 0.3))
	_mi(root, b)
	var ring := _pivot(root, Vector3(0, 1.5, 0))
	var rb := MB.new()
	rb.torus(Vector3.ZERO, 1.05, 0.06, Color(col.r, col.g, col.b, 0.9), Vector3(PI / 2, 0, 0))
	rb.torus(Vector3.ZERO, 0.8, 0.04, Color(1, 1, 1, 0.7), Vector3(PI / 2, 0, 0))
	_mi(ring, rb, MB.mat_glow())
	var sb := MB.new()
	sb.cyl(Vector3.ZERO, 1.0, 0.04, Color(col.r, col.g, col.b, 0.28 if open else 0.12), Vector3(PI / 2, 0, 0), 14)
	_mi(root, sb, MB.mat_glow(), Vector3(0, 1.5, 0))
	root.set_meta("ring", ring)
	return root

static func spring_basin() -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	b.cyl(Vector3(0, 0.12, 0), 1.3, 0.24, Color("8a96a8"), Vector3.ZERO, 14)
	b.cyl(Vector3(0, 0.26, 0), 1.05, 0.06, Color("5ab0ff"), Vector3.ZERO, 14)
	_mi(root, b)
	var g := MB.new()
	g.cyl(Vector3(0, 0.3, 0), 1.0, 0.02, Color(0.4, 0.8, 1.0, 0.5), Vector3.ZERO, 14)
	g.cyl(Vector3(0, 0.9, 0), 0.07, 1.2, Color(0.5, 0.9, 1.0, 0.25))
	_mi(root, g, MB.mat_glow())
	return root

# ---------------------------------------------------------------- monsters
static func _node(solid: MB, glow: MB = null, glass: MB = null) -> Node3D:
	var root := Node3D.new()
	_mi(root, solid)
	if glow != null and not glow.is_empty():
		_mi(root, glow, MB.mat_glow())
	if glass != null and not glass.is_empty():
		_mi(root, glass, MB.mat_glass())
	return root

static func _wing(parent: Node3D, side: int, pos: Vector3, span: float, chord: float, col: Color, tip: Color) -> Node3D:
	var w := _pivot(parent, pos)
	var wb := MB.new()
	wb.box(Vector3(span * 0.5 * side, 0, 0), Vector3(span, 0.05, chord), col)
	wb.box(Vector3(span * 0.85 * side, 0, -chord * 0.2), Vector3(span * 0.35, 0.04, chord * 0.7), tip)
	_mi(w, wb)
	return w

static func monster(shape: String, col: Color, boss: bool = false) -> Node3D:
	match shape:
		"humanoid", "hero", "healer", "demon":
			return _humanoid_monster(shape, col, boss)
	var dark := col.darkened(0.45)
	var light := col.lightened(0.35)
	var b := MB.new()
	var g := MB.new()
	var gl := MB.new()
	var root: Node3D
	var wings: Array = []
	match shape:
		"beast":
			b.sph(Vector3(0, 0.78, 0), Vector3(0.38, 0.42, 0.72), col)
			b.sph(Vector3(0, 1.0, 0.68), Vector3(0.26, 0.26, 0.28), light)
			b.box(Vector3(0, 0.92, 0.95), Vector3(0.2, 0.16, 0.26), light)
			b.cone(Vector3(-0.14, 1.34, 0.62), 0.07, 0.24, dark)
			b.cone(Vector3(0.14, 1.34, 0.62), 0.07, 0.24, dark)
			b.cyl(Vector3(0, 0.95, -0.78), 0.06, 0.7, dark, Vector3(1.0, 0, 0))
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					b.box(Vector3(0.22 * sx, 0.3, 0.42 * sz), Vector3(0.15, 0.6, 0.15), dark)
			g.ball(Vector3(-0.1, 1.07, 0.9), 0.05, Color("ffe060"), true)
			g.ball(Vector3(0.1, 1.07, 0.9), 0.05, Color("ffe060"), true)
			root = _node(b, g)
		"wisp":
			b.ball(Vector3(0, 0.95, 0), 0.34, light)
			for i in range(1, 5):
				b.ball(Vector3(sin(i * 1.3) * 0.15, 0.95 - i * 0.12, -0.3 * i), 0.3 - i * 0.05, Color(col.r, col.g, col.b, 1.0).lerp(dark, i * 0.15), true)
			b.ball(Vector3(-0.1, 1.0, 0.31), 0.06, Color.BLACK, true)
			b.ball(Vector3(0.1, 1.0, 0.31), 0.06, Color.BLACK, true)
			g.ball(Vector3(0, 0.95, 0), 0.75, Color(col.r, col.g, col.b, 0.22))
			g.ball(Vector3(0, 0.95, 0), 0.5, Color(col.r, col.g, col.b, 0.28))
			root = _node(b, g)
		"blob":
			b.sph(Vector3(0, 0.5, 0), Vector3(0.78, 0.55, 0.78), col)
			b.sph(Vector3(-0.2, 0.85, 0.2), Vector3(0.3, 0.14, 0.26), light)
			for s in [-1, 1]:
				b.ball(Vector3(0.24 * s, 0.7, 0.58), 0.13, Color.WHITE, true)
				b.ball(Vector3(0.24 * s, 0.7, 0.69), 0.065, Color.BLACK, true)
			g.sph(Vector3(0, 0.5, 0), Vector3(0.9, 0.65, 0.9), Color(col.r, col.g, col.b, 0.14))
			root = _node(b, g)
		"wraith":
			b.prim("fr8", MB._xf(Vector3(0, 0.85, 0), Vector3(1.1, 1.7, 1.1), Vector3.ZERO), Color(col.r, col.g, col.b).darkened(0.1))
			b.ball(Vector3(0, 1.75, 0), 0.27, dark)
			b.cone(Vector3(0, 1.98, -0.05), 0.2, 0.3, dark)
			for i in 7:
				var a := TAU * i / 7.0
				b.cone(Vector3(sin(a) * 0.5, 0.12, cos(a) * 0.5), 0.1, 0.3, col, Vector3(PI, 0, 0))
			for s in [-1, 1]:
				b.cyl(Vector3(0.38 * s, 1.15, 0.28), 0.05, 0.6, dark, Vector3(1.1, 0, 0.2 * s))
			g.ball(Vector3(-0.1, 1.75, 0.23), 0.05, Color.WHITE, true)
			g.ball(Vector3(0.1, 1.75, 0.23), 0.05, Color.WHITE, true)
			g.sph(Vector3(0, 0.9, 0), Vector3(0.8, 1.2, 0.8), Color(col.r, col.g, col.b, 0.1))
			root = _node(b, g)
		"plant":
			b.sph(Vector3(0, 0.45, 0), Vector3(0.5, 0.42, 0.5), col)
			for i in 5:
				var a := (i - 2) * 0.55
				b.cyl(Vector3(sin(a) * 0.5, 1.0, 0), 0.055, 1.0, dark, Vector3(0, 0, -a * 0.9))
				b.ball(Vector3(sin(a) * 0.95, 1.45 - absf(a) * 0.1, 0), 0.12, light, true)
			b.ball(Vector3(0, 0.62, 0.3), 0.22, Color("ffd0f0"))
			b.ball(Vector3(0, 0.62, 0.45), 0.09, Color("ffe060"), true)
			root = _node(b, g)
		"dragon":
			var prev := Vector3.ZERO
			for i in 15:
				var f := i / 14.0
				var p := Vector3(sin(f * 6.0) * 0.4, 0.45 + 0.12 * sin(f * 4.0), -1.5 + f * 2.3)
				b.ball(p, 0.5 - f * 0.26 + (0.1 if i > 11 else 0.0) * 0.0, col.lerp(light, f), true)
				if i % 2 == 0:
					b.cone(p + Vector3(0, 0.3, 0), 0.07, 0.2, dark)
				prev = p
			b.box(prev + Vector3(0, 0.05, 0.3), Vector3(0.4, 0.3, 0.6), light)
			b.cone(prev + Vector3(-0.16, 0.34, 0.0), 0.06, 0.4, dark, Vector3(-0.5, 0, 0.2))
			b.cone(prev + Vector3(0.16, 0.34, 0.0), 0.06, 0.4, dark, Vector3(-0.5, 0, -0.2))
			g.ball(prev + Vector3(-0.15, 0.15, 0.42), 0.06, Color("ff4040"), true)
			g.ball(prev + Vector3(0.15, 0.15, 0.42), 0.06, Color("ff4040"), true)
			var wing_l := Vector3(0, 0.9, -0.3)
			root = _node(b, g)
			wings.append(_wing(root, -1, wing_l, 1.3, 0.8, dark, col))
			wings.append(_wing(root, 1, wing_l, 1.3, 0.8, dark, col))
		"bird", "phoenix":
			var ph := shape == "phoenix"
			b.sph(Vector3(0, 1.2, 0), Vector3(0.3, 0.3, 0.55), light)
			b.ball(Vector3(0, 1.45, 0.5), 0.2, col)
			b.cone(Vector3(0, 1.4, 0.8), 0.07, 0.3, Color("f0c860"), Vector3(PI / 2, 0, 0))
			b.ball(Vector3(-0.09, 1.5, 0.64), 0.04, Color.BLACK, true)
			b.ball(Vector3(0.09, 1.5, 0.64), 0.04, Color.BLACK, true)
			var tail_n := 5 if ph else 3
			for i in tail_n:
				var a := (i - (tail_n - 1) * 0.5) * 0.22
				b.cone(Vector3(sin(a) * 0.6, 1.1 - absf(a) * 0.3, -0.9 - (0.35 if ph else 0.0)), 0.1, 0.9 if ph else 0.6, col.lerp(dark, absf(a)), Vector3(-1.4, 0, -a * 0.8))
			if ph:
				b.cone(Vector3(0, 1.75, 0.45), 0.05, 0.3, Color("ffe060"), Vector3(-0.3, 0, 0))
				g.sph(Vector3(0, 1.2, -0.2), Vector3(1.0, 0.8, 1.4), Color(1.0, 0.5, 0.1, 0.18))
				g.sph(Vector3(0, 1.2, -0.2), Vector3(0.6, 0.5, 0.9), Color(1.0, 0.8, 0.3, 0.22))
			root = _node(b, g)
			var spread := 1.2 if ph else 1.0
			wings.append(_wing(root, -1, Vector3(0, 1.3, 0), 1.1 * spread, 0.7, col, light))
			wings.append(_wing(root, 1, Vector3(0, 1.3, 0), 1.1 * spread, 0.7, col, light))
		"storm":
			var cp := [Vector3(-0.7, 1.7, 0), Vector3(0.0, 1.95, 0.1), Vector3(0.7, 1.7, -0.1), Vector3(-0.3, 1.6, 0.5), Vector3(0.4, 1.55, 0.45)]
			for p in cp:
				b.sph(p, Vector3(0.62, 0.38, 0.55), Color(0.38, 0.4, 0.56).lerp(col, 0.25))
			var bolt := Vector3(0, 1.45, 0.2)
			for i in 6:
				var nx := Vector3(((i % 2) * 2 - 1) * 0.22, bolt.y - 0.3, bolt.z)
				g.box((bolt + nx) * 0.5, Vector3(0.07, 0.42, 0.07), Color(0.95, 0.97, 1.0, 0.95), Vector3(0, 0, ((i % 2) * 2 - 1) * 0.45))
				bolt = nx
			g.ball(Vector3(0, 1.0, 0.2), 0.7, Color(0.7, 0.8, 1.0, 0.12))
			root = _node(b, g)
		"golem":
			for s in [-1, 1]:
				b.box(Vector3(0.3 * s, 0.4, 0), Vector3(0.36, 0.8, 0.42), dark)
				b.ball(Vector3(0.68 * s, 1.45, 0), 0.3, light, true)
				b.box(Vector3(0.78 * s, 0.9, 0.05), Vector3(0.3, 0.95, 0.34), col)
				b.box(Vector3(0.78 * s, 0.38, 0.1), Vector3(0.4, 0.28, 0.4), dark)
			b.box(Vector3(0, 1.15, 0), Vector3(1.0, 0.9, 0.62), col)
			b.box(Vector3(0, 1.8, 0.04), Vector3(0.46, 0.4, 0.44), light)
			b.box(Vector3(0, 0.78, 0.0), Vector3(1.02, 0.14, 0.64), dark)
			g.ball(Vector3(0, 1.2, 0.33), 0.15, Color(1.0, 0.7, 0.3, 1.0), true)
			g.ball(Vector3(0, 1.2, 0.33), 0.32, Color(1.0, 0.6, 0.2, 0.3), true)
			g.box(Vector3(-0.11, 1.84, 0.27), Vector3(0.12, 0.05, 0.03), Color(1.0, 0.75, 0.3))
			g.box(Vector3(0.11, 1.84, 0.27), Vector3(0.12, 0.05, 0.03), Color(1.0, 0.75, 0.3))
			for i in 4:
				g.box(Vector3(0.78 * (1 if i % 2 == 0 else -1), 0.8 + i * 0.12, 0.23), Vector3(0.14, 0.04, 0.03), Color(1.0, 0.6, 0.2, 0.8))
			root = _node(b, g)
		"serpent":
			var top := Vector3.ZERO
			for i in 13:
				var f := i / 12.0
				var a := f * TAU * 1.15
				var rh := 0.55 * (1.0 - f * 0.35)
				var p := Vector3(cos(a) * rh, 0.2 + f * 1.15, sin(a) * rh)
				b.ball(p, 0.23 - f * 0.08, col.lerp(light, f), true)
				top = p
			b.sph(top + Vector3(0, 0.12, 0.12), Vector3(0.2, 0.15, 0.28), light)
			b.cone(top + Vector3(-0.2, 0.05, 0), 0.1, 0.3, dark, Vector3(0, 0, 1.2))
			b.cone(top + Vector3(0.2, 0.05, 0), 0.1, 0.3, dark, Vector3(0, 0, -1.2))
			g.ball(top + Vector3(-0.09, 0.2, 0.3), 0.04, Color("ffe040"), true)
			g.ball(top + Vector3(0.09, 0.2, 0.3), 0.04, Color("ffe040"), true)
			root = _node(b, g)
		"crab":
			b.sph(Vector3(0, 0.5, 0), Vector3(0.8, 0.32, 0.58), col)
			b.sph(Vector3(0, 0.6, 0.1), Vector3(0.5, 0.2, 0.36), light)
			for s in [-1, 1]:
				b.cyl(Vector3(0.95 * s, 0.62, 0.45), 0.06, 0.6, dark, Vector3(0.8, 0, 0.3 * s))
				b.sph(Vector3(1.0 * s, 0.7, 0.85), Vector3(0.3, 0.2, 0.26), col)
				b.cone(Vector3(1.05 * s, 0.7, 1.12), 0.1, 0.34, light, Vector3(PI / 2, 0, 0))
				b.cyl(Vector3(0.18 * s, 0.9, 0.42), 0.025, 0.28, dark)
				b.ball(Vector3(0.18 * s, 1.06, 0.42), 0.06, Color.WHITE, true)
				for k in 3:
					b.cyl(Vector3((0.85 + k * 0.05) * s, 0.3, -0.25 + k * 0.3), 0.04, 0.6, dark, Vector3(0, 0, 0.9 * s))
			root = _node(b, g)
		"spider":
			b.sph(Vector3(0, 0.75, -0.45), Vector3(0.45, 0.42, 0.58), col)
			b.sph(Vector3(0, 0.7, 0.2), Vector3(0.28, 0.24, 0.3), light)
			b.ball(Vector3(0, 0.95, -0.7), 0.1, dark, true)
			for s in [-1, 1]:
				for k in 4:
					var zk := 0.35 - k * 0.3
					b.cyl(Vector3(0.5 * s, 0.9, zk), 0.035, 0.7, dark, Vector3(0, 0, 0.9 * s))
					b.cyl(Vector3(0.95 * s, 0.4, zk + (k - 1.5) * 0.08), 0.03, 0.85, dark, Vector3(0, 0, -0.35 * s))
			for i in 4:
				g.ball(Vector3((i % 2) * 0.12 - 0.06, 0.78 + (i / 2) * 0.07, 0.46), 0.035, Color("ff3030"), true)
			root = _node(b, g)
		"jelly":
			var gs := MB.new()
			gs.sph(Vector3(0, 1.1, 0), Vector3(0.72, 0.55, 0.72), Color(col.r, col.g, col.b, 0.55))
			for i in 8:
				var a := TAU * i / 8.0
				gs.cyl(Vector3(sin(a) * 0.5, 0.55, cos(a) * 0.5), 0.035, 0.9 + (i % 3) * 0.12, Color(col.lightened(0.2).r, col.lightened(0.2).g, col.lightened(0.2).b, 0.5))
			g.ball(Vector3(0, 1.05, 0), 0.28, Color(light.r, light.g, light.b, 0.7), true)
			g.ball(Vector3(0, 1.05, 0), 0.5, Color(light.r, light.g, light.b, 0.18), true)
			b.ball(Vector3(-0.15, 1.0, 0.5), 0.05, Color.BLACK, true)
			b.ball(Vector3(0.15, 1.0, 0.5), 0.05, Color.BLACK, true)
			root = _node(b, g, gs)
		_:
			b.ball(Vector3(0, 0.8, 0), 0.6, col)
			root = _node(b, g)
	root.set_meta("wings", wings)
	root.set_meta("kind", "monster")
	root.set_meta("shape", shape)
	if boss:
		var ab := MB.new()
		ab.ball(Vector3(0, 1.1, 0), 1.7, Color(col.r, col.g, col.b, 0.1))
		ab.ball(Vector3(0, 1.1, 0), 1.25, Color(col.r, col.g, col.b, 0.1))
		_mi(root, ab, MB.mat_glow())
		var ring := _pivot(root, Vector3(0, 0.05, 0))
		var rb := MB.new()
		rb.torus(Vector3.ZERO, 1.5, 0.05, Color(col.r, col.g, col.b, 0.8))
		rb.torus(Vector3.ZERO, 1.9, 0.03, Color(1, 1, 1, 0.35))
		_mi(ring, rb, MB.mat_glow())
		root.set_meta("ring", ring)
	return root

static func anim_monster(n: Node3D, t: float, phase: float = 0.0) -> void:
	if n.get_meta("kind", "") == "person":
		anim_person(n, t + phase, false)
		if n.has_meta("ring"):
			n.get_meta("ring").rotation.y = t * 0.9
		return
	var ws: Array = n.get_meta("wings", [])
	if not ws.is_empty():
		var f := sin(t * 5.0 + phase) * 0.55
		ws[0].rotation.z = -f
		ws[1].rotation.z = f
	if n.has_meta("ring"):
		n.get_meta("ring").rotation.y = t * 0.9

static func _humanoid_monster(shape: String, col: Color, boss: bool) -> Node3D:
	var n: Node3D
	match shape:
		"hero":
			n = person(Color("3a8ae8"), Color("1a1a2a"), {"sword": true, "glow": Color(0.4, 0.7, 1.0)})
		"healer":
			n = person(Color("e86a9a"), Color("402030"), {"ribbon": Color("ffb0cc"), "glow": Color(1.0, 0.6, 0.8)})
		"demon":
			n = person(col.darkened(0.45), Color("200010"), {"horns": true, "red_eyes": true, "sword": true, "glow": col, "scale": 1.35})
		_:
			n = person(col, col.darkened(0.5), {"sword": true})
	n.set_meta("kind", "person")
	if boss:
		var ab := MB.new()
		ab.ball(Vector3(0, 1.1, 0), 1.7, Color(col.r, col.g, col.b, 0.1))
		ab.ball(Vector3(0, 1.1, 0), 1.25, Color(col.r, col.g, col.b, 0.1))
		_mi(n, ab, MB.mat_glow())
		var ring := _pivot(n, Vector3(0, 0.05, 0))
		var rb := MB.new()
		rb.torus(Vector3.ZERO, 1.5, 0.05, Color(col.r, col.g, col.b, 0.8))
		_mi(ring, rb, MB.mat_glow())
		n.set_meta("ring", ring)
	return n
