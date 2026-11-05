class_name Models
extends RefCounted
## Procedural 3D character and monster models.  Everything faces +Z; one unit is roughly one metre.
## All art is generated from scripts: every model here is merged from primitives by MB.
##
## Characters are articulated: two-segment arms and legs, hanging robe panels, a head with anime
## eyes that blink, hair with a swinging ponytail or long tresses, and held weapons.  Monsters have
## their own skeletons of pivots (legs, jaws, wings, tails, tentacles, body segments) so each shape
## gets its own walk, flap, slither, scuttle or pulse.  `act()` triggers attack / cast / hurt poses.

const SKIN := Color("f4cfaa")
const INK := Color("1a1a24")

static func _mi(parent: Node3D, mb: MB, mat: Material = null, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mb.build(mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _pivot(parent: Node3D, pos: Vector3, nm: String = "") -> Node3D:
	var p := Node3D.new()
	p.position = pos
	if nm != "":
		p.name = nm
	parent.add_child(p)
	return p

static func _aura(parent: Node3D, pos: Vector3, radii: Vector3, col: Color, strength: float = 0.5) -> MeshInstance3D:
	var g := MB.new()
	g.sph_hi(Vector3.ZERO, radii, Color(col.r, col.g, col.b, strength))
	var mi := _mi(parent, g, MB.mat_aura(), pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

# ---------------------------------------------------------------- people
## robe/hair colours + options: sword, staff, beard, hat, ribbon(Color), horns, scale, glow(Color),
## hair ("topknot" | "long" | "bun" | "bald" | "wild"), armor, cape(Color), crown, eyes(Color), trim(Color), sash
static func person(robe: Color, hair: Color, o: Dictionary = {}) -> Node3D:
	if o.has("asset") and Assets.PEOPLE.has(o.asset) and Assets.has(Assets.PEOPLE[o.asset]):
		return _glb_person(o)
	var root := Node3D.new()
	var parts := {}
	var trim: Color = o.get("trim", robe.lightened(0.45))
	var dark := robe.darkened(0.45)
	var cloth := MB.tag(robe, MB.CLOTH)
	var cloth_l := MB.tag(robe.lightened(0.1), MB.CLOTH)
	var cloth_d := MB.tag(dark, MB.CLOTH)
	var trim_c := MB.tag(trim, MB.CLOTH)
	var skin := MB.tag(SKIN, MB.SKIN)
	var hair_c := MB.tag(hair, MB.HAIR)
	var armor: bool = o.get("armor", false)
	var metal := MB.tag(Color("b8bcc8") if not o.has("metal") else o.metal, MB.METAL)
	# ---- hips / torso pivot (everything above the legs hangs from here)
	var body := _pivot(root, Vector3(0, 0.92, 0), "body")
	var tb := MB.new()
	tb.ao_floor = -0.9
	tb.ao_height = 0.9
	tb.ao_strength = 0.25
	# upper robe: waist to shoulders, slightly flattened front-to-back
	tb.lathe(Vector3.ZERO, [Vector2(0.21, -0.06), Vector2(0.215, 0.08), Vector2(0.235, 0.24), Vector2(0.25, 0.38), Vector2(0.22, 0.48), Vector2(0.12, 0.56), Vector2(0.075, 0.6)], cloth, 16, cloth_l, Vector2(1.0, 0.78))
	# crossed collar (the left lapel over the right) and inner robe
	tb.ribbon([Vector3(-0.1, 0.56, 0.11), Vector3(0.0, 0.42, 0.19), Vector3(0.1, 0.2, 0.19)], [0.035, 0.04, 0.03], Vector3(0.7, 0.7, 0), trim_c)
	tb.ribbon([Vector3(0.1, 0.56, 0.11), Vector3(0.02, 0.44, 0.185)], [0.03, 0.03], Vector3(-0.7, 0.7, 0), MB.tag(Color("f4f0e0"), MB.CLOTH))
	# belt, sash knot and hanging jade pendant
	tb.cyl(Vector3(0, 0.03, 0), 0.225, 0.1, trim_c, Vector3.ZERO, 24)
	tb.cyl(Vector3(0, 0.03, 0), 0.229, 0.025, MB.tag(trim.darkened(0.3), MB.CLOTH), Vector3.ZERO, 24)
	if o.get("sash", true):
		tb.box(Vector3(0.09, 0.03, 0.19), Vector3(0.09, 0.09, 0.05), trim_c, Vector3(0, 0, 0.3))
		tb.leaf(Vector3(0.09, 0.0, 0.2), Vector3(0.13, -0.32, 0.22), 0.05, trim_c, Vector3.RIGHT)
		tb.leaf(Vector3(0.07, 0.0, 0.2), Vector3(0.03, -0.28, 0.22), 0.045, trim_c, Vector3.RIGHT)
	if armor:
		# lamellar chest plate and pauldrons
		tb.lathe(Vector3(0, 0.12, 0), [Vector2(0.23, 0.0), Vector2(0.255, 0.14), Vector2(0.262, 0.26), Vector2(0.2, 0.36)], metal, 16, MB.tag(Color("e0e4ee"), MB.METAL), Vector2(1.0, 0.8))
		for row in 3:
			tb.cyl(Vector3(0, 0.15 + row * 0.08, 0), 0.258 - row * 0.004, 0.012, MB.tag(Color("6a6e7a"), MB.METAL), Vector3.ZERO, 16)
		tb.ball(Vector3(0, 0.33, 0.2), 0.04, MB.tag(Color("f0c850"), MB.METAL), true)
	# robe skirt: a short fixed top under the belt...
	tb.lathe(Vector3.ZERO, [Vector2(0.235, -0.22), Vector2(0.22, -0.06)], cloth, 16, cloth, Vector2(1.0, 0.82))
	_mi(body, tb)
	# ...and four hanging panels that swing with the legs
	var panels := {}
	for k in ["f", "b", "l", "r"]:
		var ang: float = {"f": 0.0, "b": PI, "l": -PI / 2, "r": PI / 2}[k]
		var pv := _pivot(body, Vector3(sin(ang) * 0.17, -0.18, cos(ang) * 0.14))
		pv.rotation.y = ang
		var pb := MB.new()
		var wdt := 0.2 if k in ["f", "b"] else 0.15
		pb.ribbon([Vector3(0, 0, 0), Vector3(0, -0.3, 0.05), Vector3(0, -0.62, 0.1)], [wdt, wdt * 1.1, wdt * 1.25], Vector3.RIGHT, cloth, cloth_d)
		pb.ribbon([Vector3(0, -0.6, 0.105), Vector3(0, -0.66, 0.11)], [wdt * 1.25, wdt * 1.27], Vector3.RIGHT, trim_c)
		_mi(pv, pb, MB.mat_plain())
		panels[k] = pv
	parts["panels"] = panels
	var pend := _pivot(body, Vector3(-0.1, -0.02, 0.2))
	var pdb := MB.new()
	pdb.cyl(Vector3(0, -0.07, 0), 0.006, 0.14, MB.tag(Color("d04040"), MB.CLOTH))
	pdb.cyl(Vector3(0, -0.16, 0), 0.04, 0.02, MB.tag(Color("6af0b0"), MB.CRYSTAL), Vector3(PI / 2, 0, 0), 14)
	pdb.cone(Vector3(0, -0.22, 0), 0.02, 0.08, MB.tag(Color("d04040"), MB.CLOTH), Vector3(PI, 0, 0))
	_mi(pend, pdb, MB.mat_plain())
	parts["pendant"] = pend
	if o.has("ribbon"):
		var rb := MB.new()
		var rc := MB.tag(o.ribbon, MB.CLOTH)
		rb.box(Vector3(0, 0.03, -0.21), Vector3(0.14, 0.1, 0.05), rc)
		_mi(body, rb)
		for s in [-1, 1]:
			var rp := _pivot(body, Vector3(0.04 * s, 0.03, -0.23))
			var rbb := MB.new()
			rbb.ribbon([Vector3.ZERO, Vector3(0.04 * s, -0.25, -0.05), Vector3(0.02 * s, -0.55, -0.08)], [0.045, 0.05, 0.035], Vector3.RIGHT, rc, MB.tag(o.ribbon.lightened(0.3), MB.CLOTH))
			_mi(rp, rbb, MB.mat_plain())
			parts["sash%d" % s] = rp
	if o.has("cape"):
		var cp := _pivot(body, Vector3(0, 0.52, -0.16))
		var cb := MB.new()
		var cc := MB.tag(o.cape, MB.CLOTH)
		cb.ribbon([Vector3(0, 0, 0), Vector3(0, -0.5, -0.1), Vector3(0, -1.1, -0.18), Vector3(0, -1.35, -0.2)], [0.26, 0.32, 0.38, 0.4], Vector3.RIGHT, cc, MB.tag(o.cape.darkened(0.35), MB.CLOTH))
		_mi(cp, cb, MB.mat_plain())
		parts["cape"] = cp
	parts["body"] = body
	# ---- head
	var head := _pivot(body, Vector3(0, 0.63, 0), "head")
	var hb := MB.new()
	hb.sph_hi(Vector3(0, 0.0, 0), Vector3(0.19, 0.21, 0.19), skin)
	hb.sph_hi(Vector3(0, -0.1, 0.035), Vector3(0.13, 0.11, 0.13), skin)
	hb.cyl(Vector3(0, -0.2, -0.01), 0.06, 0.16, skin)
	for s in [-1, 1]:
		hb.sph(Vector3(0.19 * s, -0.01, -0.01), Vector3(0.03, 0.055, 0.04), skin)
		hb.sph(Vector3(0.1 * s, -0.08, 0.15), Vector3(0.035, 0.02, 0.01), MB.tag(Color("ffb0a0"), MB.SKIN))
	hb.sph(Vector3(0, -0.04, 0.19), Vector3(0.016, 0.022, 0.016), skin)
	hb.box(Vector3(0, -0.12, 0.16), Vector3(0.05, 0.012, 0.01), MB.tag(Color("b8605a"), MB.SKIN))
	# eyebrows
	for s in [-1, 1]:
		hb.box(Vector3(0.075 * s, 0.075, 0.175), Vector3(0.07, 0.014, 0.012), hair_c, Vector3(0, 0, -0.18 * s if not o.get("horns", false) else 0.35 * s))
	_hair(hb, hair_c, o)
	if o.get("beard", false):
		var bc := MB.tag(Color("f0f0f6"), MB.HAIR)
		hb.cone(Vector3(0, -0.28, 0.1), 0.11, 0.36, bc, Vector3(PI + 0.2, 0, 0), 8)
		for s in [-1, 1]:
			hb.ribbon([Vector3(0.05 * s, -0.11, 0.17), Vector3(0.1 * s, -0.16, 0.16), Vector3(0.12 * s, -0.3, 0.12)], [0.012, 0.012, 0.004], Vector3.FORWARD, bc)
	if o.get("hat", false):
		var hc := MB.tag(Color("9a7a48"), MB.WOOD)
		hb.lathe(Vector3(0, 0.12, 0), [Vector2(0.4, 0.0), Vector2(0.3, 0.06), Vector2(0.16, 0.18), Vector2(0.02, 0.3)], hc, 16)
		hb.torus(Vector3(0, 0.15, 0), 0.24, 0.02, MB.tag(Color("6a3a20"), MB.CLOTH))
	if o.get("crown", false):
		var gc := MB.tag(Color("f0c850"), MB.METAL)
		hb.cyl(Vector3(0, 0.2, -0.02), 0.13, 0.06, gc, Vector3.ZERO, 14)
		for i in 5:
			var a := -0.9 + i * 0.45
			hb.cone(Vector3(sin(a) * 0.13, 0.27, cos(a) * 0.13 - 0.02), 0.025, 0.1, gc, Vector3.ZERO, 4)
		hb.ball(Vector3(0, 0.22, 0.12), 0.025, MB.tag(Color("ff4060"), MB.CRYSTAL), true)
	if o.get("horns", false):
		var hc2 := MB.tag(Color("2a1020"), MB.STONE)
		for s in [-1, 1]:
			hb.limb(Vector3(0.1 * s, 0.17, 0), Vector3(0.2 * s, 0.32, -0.05), 0.045, 0.03, hc2, 6)
			hb.limb(Vector3(0.2 * s, 0.32, -0.05), Vector3(0.24 * s, 0.48, -0.16), 0.03, 0.0, hc2, 6)
	if o.has("ribbon"):
		var rc2 := MB.tag(o.ribbon, MB.CLOTH)
		hb.sph(Vector3(-0.07, 0.17, -0.15), Vector3(0.07, 0.045, 0.03), rc2, Vector3(0, 0, 0.5))
		hb.sph(Vector3(0.07, 0.17, -0.15), Vector3(0.07, 0.045, 0.03), rc2, Vector3(0, 0, -0.5))
		hb.ball(Vector3(0, 0.17, -0.16), 0.025, rc2, true)
	_mi(head, hb)
	# eyes on their own pivot so they can blink
	var eyes := _pivot(head, Vector3(0, 0.0, 0.0))
	var eb := MB.new()
	var iris: Color = o.get("eyes", Color("3a5a9a") if not o.get("red_eyes", false) else Color("ff2020"))
	for s in [-1, 1]:
		eb.sph(Vector3(0.068 * s, 0.0, 0.165), Vector3(0.045, 0.055, 0.02), MB.tag(Color("fbfbff"), MB.SKIN), Vector3(0, 0.38 * s, 0))
		eb.sph(Vector3(0.07 * s, -0.004, 0.178), Vector3(0.032, 0.045, 0.014), MB.tag(iris, MB.CRYSTAL), Vector3(0, 0.38 * s, 0))
		eb.sph(Vector3(0.071 * s, -0.004, 0.186), Vector3(0.016, 0.024, 0.01), MB.tag(INK, MB.SKIN), Vector3(0, 0.38 * s, 0))
		eb.ball(Vector3(0.062 * s + 0.012, 0.018, 0.192), 0.009, MB.tag(Color.WHITE, MB.CRYSTAL), true)
		eb.box(Vector3(0.07 * s, 0.05, 0.176), Vector3(0.1, 0.012, 0.012), MB.tag(INK, MB.HAIR), Vector3(0, 0.38 * s, -0.08 * s))
	_mi(eyes, eb, MB.mat_plain())
	parts["eyes"] = eyes
	if o.get("red_eyes", false):
		var eg := MB.new()
		eg.ball(Vector3(-0.07, 0.0, 0.18), 0.05, Color(1, 0.15, 0.1, 0.9), true)
		eg.ball(Vector3(0.07, 0.0, 0.18), 0.05, Color(1, 0.15, 0.1, 0.9), true)
		_mi(head, eg, MB.mat_glow())
	if o.get("hair", "topknot") in ["topknot", "long"]:
		var tail := _pivot(head, Vector3(0, 0.2, -0.16) if o.get("hair", "topknot") == "topknot" else Vector3(0, 0.04, -0.17))
		var tlb := MB.new()
		if o.get("hair", "topknot") == "topknot":
			tlb.ribbon([Vector3.ZERO, Vector3(0, -0.12, -0.1), Vector3(0, -0.36, -0.12), Vector3(0, -0.56, -0.08)], [0.05, 0.07, 0.06, 0.01], Vector3.RIGHT, hair_c, MB.tag(hair.lightened(0.15), MB.HAIR))
			tlb.ribbon([Vector3.ZERO, Vector3(0, -0.12, -0.1), Vector3(0, -0.36, -0.12), Vector3(0, -0.56, -0.08)], [0.05, 0.07, 0.06, 0.01], Vector3.UP, hair_c)
		else:
			tlb.ribbon([Vector3.ZERO, Vector3(0, -0.3, -0.06), Vector3(0, -0.62, -0.08), Vector3(0, -0.82, -0.04)], [0.16, 0.18, 0.17, 0.08], Vector3.RIGHT, hair_c, MB.tag(hair.lightened(0.12), MB.HAIR))
		_mi(tail, tlb, MB.mat_plain())
		parts["tail"] = tail
	parts["head"] = head
	# ---- arms: shoulder -> elbow -> hand, with a wide hanging sleeve
	for s in [-1, 1]:
		var arm := _pivot(body, Vector3(0.25 * s, 0.47, 0))
		arm.rotation.z = 0.1 * s
		var ab := MB.new()
		ab.limb(Vector3(0, 0.02, 0), Vector3(0, -0.3, 0), 0.075, 0.068, cloth_l, 8)
		if armor:
			ab.hemi(Vector3(0.02 * s, 0.0, 0), Vector3(0.11, 0.09, 0.11), metal, Vector3(0, 0, -0.25 * s))
			ab.hemi(Vector3(0.03 * s, -0.06, 0), Vector3(0.105, 0.07, 0.1), MB.tag(Color("8a8e9a"), MB.METAL), Vector3(0, 0, -0.35 * s))
		_mi(arm, ab)
		var fore := _pivot(arm, Vector3(0, -0.3, 0))
		var fb := MB.new()
		fb.limb(Vector3.ZERO, Vector3(0, -0.24, 0), 0.062, 0.05, cloth_l, 8)
		# trumpet sleeve
		fb.lathe(Vector3(0, -0.28, 0), [Vector2(0.125, -0.04), Vector2(0.13, -0.02), Vector2(0.09, 0.08), Vector2(0.06, 0.24)], trim_c, 12, cloth)
		fb.lathe(Vector3(0, -0.28, 0), [Vector2(0.11, -0.03), Vector2(0.06, 0.06)], cloth_d, 12)
		if armor:
			fb.cyl(Vector3(0, -0.12, 0), 0.07, 0.14, metal, Vector3.ZERO, 8)
		# hand with thumb
		fb.sph(Vector3(0, -0.33, 0.01), Vector3(0.045, 0.065, 0.035), skin)
		fb.sph(Vector3(-0.03 * s, -0.31, 0.035), Vector3(0.018, 0.035, 0.018), skin, Vector3(0.4, 0, 0.3 * s))
		_mi(fore, fb)
		parts["arm%d" % s] = arm
		parts["fore%d" % s] = fore
	# ---- legs: hip -> knee -> boot
	for s in [-1, 1]:
		var leg := _pivot(root, Vector3(0.105 * s, 0.86, 0))
		var lb := MB.new()
		lb.limb(Vector3(0, 0.02, 0), Vector3(0, -0.42, 0), 0.088, 0.066, MB.tag(dark.lightened(0.05), MB.CLOTH), 8)
		_mi(leg, lb)
		var knee := _pivot(leg, Vector3(0, -0.42, 0))
		var kb := MB.new()
		kb.limb(Vector3.ZERO, Vector3(0, -0.36, 0), 0.064, 0.05, MB.tag(Color("2a2430"), MB.CLOTH), 8)
		var boot := MB.tag(Color("1e1a24"), MB.WOOD)
		kb.cyl(Vector3(0, -0.3, 0), 0.062, 0.14, boot, Vector3.ZERO, 8)
		kb.sph(Vector3(0, -0.4, 0.05), Vector3(0.065, 0.045, 0.13), boot)
		kb.box(Vector3(0, -0.435, 0.04), Vector3(0.13, 0.018, 0.27), MB.tag(Color("3a3038"), MB.WOOD))
		kb.cyl(Vector3(0, -0.22, 0), 0.066, 0.025, trim_c, Vector3.ZERO, 8)
		_mi(knee, kb)
		parts["leg%d" % s] = leg
		parts["knee%d" % s] = knee
	# ---- held items (right hand)
	var ra: Node3D = parts["fore1"]
	if o.get("sword", false):
		var sw := _pivot(ra, Vector3(0, -0.33, 0.02))
		sw.rotation.x = -1.3
		var sb := MB.new()
		var steel := MB.tag(Color("e4eef8"), MB.METAL)
		# blade with a central fuller and tapered tip
		sb.box(Vector3(0, 0.5, 0), Vector3(0.055, 0.82, 0.012), steel)
		sb.box(Vector3(0, 0.48, 0.007), Vector3(0.012, 0.74, 0.004), MB.tag(Color("a8b8d0"), MB.METAL))
		sb.prim("cone4", Transform3D(Basis.from_euler(Vector3(0, PI / 4, 0)).scaled(Vector3(0.055, 0.14, 0.018)), Vector3(0, 0.98, 0)), steel)
		# guard, grip wrap, pommel and tassel
		var gold := MB.tag(Color("d8b050"), MB.METAL)
		sb.box(Vector3(0, 0.07, 0), Vector3(0.2, 0.035, 0.05), gold)
		sb.ball(Vector3(-0.1, 0.07, 0), 0.03, gold, true)
		sb.ball(Vector3(0.1, 0.07, 0), 0.03, gold, true)
		sb.cyl(Vector3(0, -0.04, 0), 0.024, 0.2, MB.tag(Color("5a2a2a"), MB.CLOTH))
		for i in 4:
			sb.torus(Vector3(0, -0.11 + i * 0.045, 0), 0.026, 0.006, MB.tag(Color("2a1414"), MB.CLOTH))
		sb.ball(Vector3(0, -0.15, 0), 0.032, gold, true)
		sb.ribbon([Vector3(0, -0.17, 0), Vector3(0.02, -0.28, 0.02), Vector3(0.0, -0.36, 0.03)], [0.012, 0.02, 0.008], Vector3.RIGHT, MB.tag(Color("e04050"), MB.CLOTH))
		_mi(sw, sb)
		var sg := MB.new()
		sg.box(Vector3(0, 0.52, 0), Vector3(0.09, 0.9, 0.03), Color(0.6, 0.85, 1.0, 0.28))
		_mi(sw, sg, MB.mat_glow())
		parts["sword"] = sw
	if o.get("staff", false):
		var st := _pivot(ra, Vector3(0, -0.33, 0.04))
		var sb2 := MB.new()
		var wood := MB.tag(Color("7a5a3a"), MB.WOOD)
		sb2.limb(Vector3(0, -0.7, 0), Vector3(0, 1.25, 0), 0.032, 0.026, wood, 6)
		sb2.torus(Vector3(0, 1.4, 0), 0.13, 0.016, MB.tag(Color("d8b050"), MB.METAL), Vector3(PI / 2, 0, 0))
		for i in 4:
			var a := TAU * i / 4.0
			sb2.torus(Vector3(cos(a) * 0.13, 1.4 + sin(a) * 0.13 - 0.05, 0), 0.03, 0.006, MB.tag(Color("e8c860"), MB.METAL), Vector3(PI / 2, 0, 0))
		sb2.ball(Vector3(0, 1.4, 0), 0.06, MB.tag(Color("ffe080"), MB.CRYSTAL))
		_mi(st, sb2)
		var sg2 := MB.new()
		sg2.sph_hi(Vector3(0, 1.4, 0), Vector3(0.2, 0.2, 0.2), Color(1, 0.85, 0.4, 0.5))
		_mi(st, sg2, MB.mat_aura())
	if o.has("glow"):
		# a faint rim of qi plus a soft pool of light underfoot
		var gc: Color = o.glow
		var gd := MB.new()
		gd.disc(Vector3(0, 0.05, 0), 0.75, Color(gc.r, gc.g, gc.b, 0.35), 24, Color(gc.r, gc.g, gc.b, 0.0))
		gd.arc(Vector3(0, 0.055, 0), 0.62, 0.025, 0.0, TAU, Color(gc.r, gc.g, gc.b, 0.5), 32)
		var gm := _mi(root, gd, MB.mat_glow())
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("p", parts)
	root.set_meta("kind", "person")
	var sc: float = o.get("scale", 1.0)
	root.scale = Vector3(sc, sc, sc)
	return root

## A Blender-built character (art/characters/*.py) with the same glow pool as procedural people.
static func _glb_person(o: Dictionary) -> Node3D:
	var root := Assets.person(o.asset)
	if o.has("glow"):
		var gc: Color = o.glow
		var gd := MB.new()
		gd.disc(Vector3(0, 0.05, 0), 0.75, Color(gc.r, gc.g, gc.b, 0.35), 24, Color(gc.r, gc.g, gc.b, 0.0))
		gd.arc(Vector3(0, 0.055, 0), 0.62, 0.025, 0.0, TAU, Color(gc.r, gc.g, gc.b, 0.5), 32)
		var gm := _mi(root, gd, MB.mat_glow())
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sc: float = o.get("scale", 1.0)
	root.scale = Vector3(sc, sc, sc)
	return root

## hair cap, bangs and side locks
static func _hair(hb: MB, hc: Color, o: Dictionary) -> void:
	var style: String = o.get("hair", "topknot")
	if style == "bald":
		hb.sph_hi(Vector3(0, 0.0, -0.06), Vector3(0.2, 0.17, 0.17), MB.tag(Color("e8e8f0"), MB.HAIR))
		return
	hb.sph_hi(Vector3(0, 0.05, -0.025), Vector3(0.21, 0.205, 0.215), hc)
	# bangs: a fan of pointed locks over the forehead
	for i in 7:
		var x := -0.15 + i * 0.05
		var lift := absf(x) * 0.25
		hb.leaf(Vector3(x * 0.7, 0.21, 0.08), Vector3(x * 1.05, 0.04 + lift, 0.2), 0.045, hc, Vector3(1, 0, -x))
	# side locks framing the face
	for s in [-1, 1]:
		hb.ribbon([Vector3(0.17 * s, 0.1, 0.06), Vector3(0.2 * s, -0.08, 0.08), Vector3(0.18 * s, -0.26, 0.06)], [0.035, 0.04, 0.008], Vector3.FORWARD, hc)
	match style:
		"topknot":
			hb.sph(Vector3(0, 0.25, -0.08), Vector3(0.09, 0.07, 0.09), hc)
			hb.cyl(Vector3(0, 0.25, -0.08), 0.008, 0.26, MB.tag(Color("d8b050"), MB.METAL), Vector3(0, 0, PI / 2))
			hb.cyl(Vector3(0, 0.215, -0.08), 0.095, 0.03, MB.tag(Color("f0c850"), MB.METAL), Vector3.ZERO, 14)
		"bun":
			hb.ball(Vector3(0, 0.12, -0.2), 0.09, hc)
			hb.cyl(Vector3(0.05, 0.14, -0.22), 0.006, 0.24, MB.tag(Color("6af0b0"), MB.CRYSTAL), Vector3(0.3, 0, 0.8))
		"long":
			hb.sph_hi(Vector3(0, -0.04, -0.09), Vector3(0.215, 0.24, 0.17), hc)
			for s in [-1, 1]:
				hb.ribbon([Vector3(0.15 * s, 0.0, -0.08), Vector3(0.2 * s, -0.3, -0.06), Vector3(0.17 * s, -0.55, -0.04)], [0.06, 0.07, 0.02], Vector3.FORWARD, hc)
		"wild":
			for i in 9:
				var a := -1.3 + i * 0.32
				hb.leaf(Vector3(sin(a) * 0.1, 0.15, cos(a) * 0.05 - 0.08), Vector3(sin(a) * 0.32, 0.18 + cos(a) * 0.1, -0.2 + cos(a) * 0.05), 0.06, hc, Vector3(cos(a), 0, -sin(a)))

## Trigger an action pose: "attack" (sword swing / bite / lunge), "cast" (both arms raised),
## "hurt" (recoil) or "victory".  `now` is the same clock passed to the animate functions.
static func act(n: Node3D, kind: String, now: float) -> void:
	if n == null:
		return
	n.set_meta("act", kind)
	n.set_meta("act_t", now)

static func _act_k(n: Node3D, t: float, dur: float = 0.55) -> Array:
	## [kind, 0..1 envelope] for the current action pose
	var kind: String = n.get_meta("act", "")
	if kind == "":
		return ["", 0.0]
	var e: float = t - float(n.get_meta("act_t", 0.0))
	if e < 0.0 or e > dur:
		if e > dur:
			n.set_meta("act", "")
		return ["", 0.0]
	return [kind, e / dur]

static func anim_person(n: Node3D, t: float, walking: bool, sit: bool = false) -> void:
	if n.has_meta("glb"):
		Assets.animate(n, t, "sit" if sit else ("walk" if walking else "idle"), t)
		return
	var p: Dictionary = n.get_meta("p")
	var ph := t * 9.0
	var body: Node3D = p["body"]
	var head: Node3D = p["head"]
	var legs := [p["leg-1"], p["leg1"]]
	var knees := [p["knee-1"], p["knee1"]]
	var arms := [p["arm-1"], p["arm1"]]
	var fores := [p["fore-1"], p["fore1"]]
	var swing := 0.0
	if walking:
		swing = sin(ph)
		legs[0].rotation = Vector3(swing * 0.62, 0, 0)
		legs[1].rotation = Vector3(-swing * 0.62, 0, 0)
		knees[0].rotation.x = 0.15 + maxf(0.0, -cos(ph)) * 0.95
		knees[1].rotation.x = 0.15 + maxf(0.0, cos(ph)) * 0.95
		arms[0].rotation = Vector3(-swing * 0.5, 0, -0.12)
		arms[1].rotation = Vector3(swing * 0.4, 0, 0.12)
		fores[0].rotation.x = -0.35 - maxf(0.0, swing) * 0.3
		fores[1].rotation.x = -0.35 - maxf(0.0, -swing) * 0.3
		body.position.y = 0.92 + absf(sin(ph)) * 0.045
		body.rotation = Vector3(0.07, swing * 0.12, 0)
		head.rotation = Vector3(-0.05, -swing * 0.1, 0)
	else:
		var br := sin(t * 2.0)
		for i in 2:
			legs[i].rotation = Vector3.ZERO
			knees[i].rotation.x = 0.04
		arms[0].rotation = Vector3(sin(t * 1.6) * 0.05, 0, -0.1 - br * 0.02)
		arms[1].rotation = Vector3(-sin(t * 1.6) * 0.05, 0, 0.1 + br * 0.02)
		fores[0].rotation.x = -0.18
		fores[1].rotation.x = -0.18
		body.position.y = 0.92 + br * 0.008
		body.rotation = Vector3(0, sin(t * 0.5) * 0.05, 0)
		body.scale = Vector3(1.0 + br * 0.008, 1.0, 1.0 + br * 0.008)
		head.rotation = Vector3(sin(t * 0.7) * 0.04, sin(t * 0.35) * 0.18, sin(t * 0.5) * 0.03)
	if sit:
		for i in 2:
			var s := -1.0 if i == 0 else 1.0
			legs[i].rotation = Vector3(-1.45, 0, 0.55 * s)
			knees[i].rotation.x = 2.5
			arms[i].rotation = Vector3(-0.55, 0, 0.25 * s)
			fores[i].rotation.x = -0.9
		body.position.y = 0.92
		body.rotation = Vector3.ZERO
	# action poses override the arms (and lean the body)
	var a := _act_k(n, t)
	if a[0] != "":
		var k: float = a[1]
		var env := sin(k * PI)
		match a[0]:
			"attack":
				# wind up behind the head, then a fast diagonal cut
				var cut := clampf((k - 0.3) / 0.35, 0.0, 1.0)
				arms[1].rotation = Vector3(lerpf(-2.6, 0.4, cut), 0, lerpf(0.5, -0.3, cut))
				fores[1].rotation.x = lerpf(-0.9, -0.1, cut)
				arms[0].rotation = Vector3(-0.6 * env, 0, -0.5 * env)
				body.rotation = Vector3(0.2 * env, lerpf(0.5, -0.6, cut) * env, 0)
			"cast":
				for i in 2:
					var s2 := -1.0 if i == 0 else 1.0
					arms[i].rotation = Vector3(-1.5 * env, 0, (0.15 + 0.5 * env) * s2)
					fores[i].rotation.x = -0.6 * env
				head.rotation.x = -0.25 * env
				body.rotation.x = -0.12 * env
			"hurt":
				body.rotation.x = -0.35 * env
				head.rotation.x = -0.3 * env
				for i in 2:
					arms[i].rotation.x = 0.5 * env
			"victory":
				arms[1].rotation = Vector3(-2.8 * env, 0, 0.2)
				fores[1].rotation.x = -0.2
	# secondary motion: hair, robe panels, ribbons, pendant
	var lag := sin(t * 9.0 - 0.8) if walking else sin(t * 1.3)
	if p.has("tail"):
		p["tail"].rotation = Vector3(0.15 + (0.35 if walking else 0.05) * absf(lag), 0, lag * (0.25 if walking else 0.06))
	if p.has("panels"):
		var pn: Dictionary = p["panels"]
		var fwd := maxf(-legs[0].rotation.x, -legs[1].rotation.x) if not sit else 1.2
		pn["f"].rotation.x = -maxf(0.0, fwd) * 0.8 - (0.15 if walking else 0.0)
		pn["b"].rotation.x = -maxf(0.0, maxf(legs[0].rotation.x, legs[1].rotation.x)) * 0.7 - (0.35 if walking else 0.03)
		pn["l"].rotation.x = -absf(legs[0].rotation.x) * 0.35 - (0.6 if sit else 0.0)
		pn["r"].rotation.x = -absf(legs[1].rotation.x) * 0.35 - (0.6 if sit else 0.0)
	for k2 in ["sash-1", "sash1"]:
		if p.has(k2):
			p[k2].rotation.x = 0.25 + (0.5 * absf(lag) if walking else 0.08 * sin(t * 1.7))
	if p.has("cape"):
		p["cape"].rotation.x = 0.12 + (0.45 + 0.12 * lag if walking else 0.04 * sin(t * 1.1))
	if p.has("pendant"):
		p["pendant"].rotation.x = (0.3 * sin(t * 9.0 + 0.6) if walking else 0.05 * sin(t * 2.0))
	# blink every few seconds
	var bl := fmod(t + float(n.get_instance_id() % 7), 3.7)
	p["eyes"].scale.y = 0.12 if bl < 0.12 else 1.0

# ---------------------------------------------------------------- props
static func lotus(col: Color, radius: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	for ring in 3:
		var n := 8 + ring * 2
		for i in n:
			var a := TAU * (i + ring * 0.5) / n
			var r := radius * (0.35 + ring * 0.33)
			var tip := Vector3(sin(a) * r * 1.5, 0.28 - ring * 0.08, cos(a) * r * 1.5)
			var c0 := MB.tag(col.lerp(Color.WHITE, 0.55 - ring * 0.15), MB.CLOTH)
			var c1 := MB.tag(col.lerp(Color("ff80b0"), 0.25 + ring * 0.15), MB.CLOTH)
			b.leaf(Vector3(sin(a) * r * 0.4, 0.06, cos(a) * r * 0.4), tip + Vector3(0, radius * (0.35 - ring * 0.1), 0), radius * 0.2, c0, Vector3(cos(a), 0, -sin(a)), c1)
	b.cyl(Vector3(0, 0.02, 0), radius * 0.3, 0.1, MB.tag(Color("f0d060"), MB.CLOTH), Vector3.ZERO, 14)
	for i in 10:
		var a2 := TAU * i / 10.0
		b.ball(Vector3(sin(a2) * radius * 0.18, 0.1, cos(a2) * radius * 0.18), radius * 0.035, MB.tag(Color("ffe890"), MB.CRYSTAL), true)
	# lily pads around the flower
	for i in 4:
		var a3 := TAU * i / 4.0 + 0.4
		b.disc(Vector3(sin(a3) * radius * 1.35, -0.02, cos(a3) * radius * 1.35), radius * 0.45, MB.tag(Color("3f9a5a"), MB.FOLIAGE), 14, MB.tag(Color("2a7040"), MB.FOLIAGE))
	_mi(root, b, MB.mat_plain())
	var g := MB.new()
	g.disc(Vector3(0, 0.03, 0), radius * 1.6, Color(col.r, col.g, col.b, 0.3), 24, Color(col.r, col.g, col.b, 0.0))
	_mi(root, g, MB.mat_glow())
	return root

static func shadow_disc(r: float, alpha: float = 0.4) -> MeshInstance3D:
	var b := MB.new()
	b.disc(Vector3(0, 0.03, 0), r, Color(0, 0, 0, alpha), 20, Color(0, 0, 0, 0.0))
	var mi := MeshInstance3D.new()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.mesh = b.build(m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func gem(col: Color) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var cc := MB.tag(col.lightened(0.1), MB.CRYSTAL)
	b.crystal(Vector3(0, 0.05, 0), 0.24, 0.85, cc, Vector3.ZERO, 6)
	b.crystal(Vector3(0.18, -0.08, 0.05), 0.1, 0.4, MB.tag(col, MB.CRYSTAL), Vector3(0, 0, -0.5), 6)
	b.crystal(Vector3(-0.16, -0.06, -0.04), 0.09, 0.35, MB.tag(col.darkened(0.1), MB.CRYSTAL), Vector3(0.2, 0, 0.55), 6)
	_mi(root, b)
	var g := MB.new()
	g.sph_hi(Vector3(0, 0.15, 0), Vector3(0.5, 0.5, 0.5), Color(col.r, col.g, col.b, 0.45))
	_mi(root, g, MB.mat_aura())
	var rg := MB.new()
	rg.arc(Vector3(0, -0.85, 0), 0.5, 0.05, 0.0, TAU, Color(col.r, col.g, col.b, 0.7), 24)
	rg.disc(Vector3(0, -0.86, 0), 0.6, Color(col.r, col.g, col.b, 0.25), 20, Color(col.r, col.g, col.b, 0.0))
	_mi(root, rg, MB.mat_glow())
	return root

static func portal(col: Color, open: bool) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var wood := MB.tag(Color("8a3a2a").lerp(col, 0.25), MB.WOOD)
	var stone := MB.tag(Color("9a96a0"), MB.STONE)
	var gold := MB.tag(Color("d8b050"), MB.METAL)
	# stone plinths, lacquered pillars, two-tier paifang roof with upturned eaves
	for s in [-1, 1]:
		b.box(Vector3(1.2 * s, 0.2, 0), Vector3(0.6, 0.4, 0.6), stone)
		b.box(Vector3(1.2 * s, 0.45, 0), Vector3(0.45, 0.1, 0.45), stone)
		b.cyl(Vector3(1.2 * s, 1.75, 0), 0.15, 2.6, wood, Vector3.ZERO, 14)
		b.cyl(Vector3(1.2 * s, 0.62, 0), 0.19, 0.12, gold, Vector3.ZERO, 14)
		b.cyl(Vector3(1.2 * s, 2.9, 0), 0.18, 0.1, gold, Vector3.ZERO, 14)
	b.box(Vector3(0, 2.75, 0), Vector3(2.7, 0.16, 0.22), wood)
	b.box(Vector3(0, 3.05, 0), Vector3(3.0, 0.2, 0.3), wood)
	b.box(Vector3(0, 2.9, 0.12), Vector3(0.9, 0.36, 0.05), MB.tag(Color("1a2a4a"), MB.WOOD))
	b.box(Vector3(0, 2.9, 0.15), Vector3(0.75, 0.24, 0.02), gold)
	var roof := MB.tag(Color("2a4a6a").lerp(col, 0.2), MB.STONE)
	b.box(Vector3(0, 3.25, 0), Vector3(3.6, 0.12, 0.7), roof)
	b.prim("prism", Transform3D(Basis.IDENTITY.scaled(Vector3(3.4, 0.35, 0.7)), Vector3(0, 3.48, 0)), roof)
	b.box(Vector3(0, 3.67, 0), Vector3(3.5, 0.08, 0.1), gold)
	for s in [-1, 1]:
		b.cone(Vector3(1.85 * s, 3.4, 0), 0.08, 0.35, roof, Vector3(0, 0, -0.9 * s), 6)
		b.ball(Vector3(1.75 * s, 3.72, 0), 0.07, gold, true)
	_mi(root, b)
	var ring := _pivot(root, Vector3(0, 1.55, 0))
	var rb := MB.new()
	rb.torus(Vector3.ZERO, 1.0, 0.05, Color(col.r, col.g, col.b, 0.95), Vector3(PI / 2, 0, 0), true)
	rb.torus(Vector3.ZERO, 0.78, 0.03, Color(1, 1, 1, 0.7), Vector3(PI / 2, 0, 0), true)
	for i in 8:
		var a := TAU * i / 8.0
		rb.box(Vector3(cos(a) * 0.9, sin(a) * 0.9, 0), Vector3(0.1, 0.1, 0.02), Color(1, 1, 1, 0.9), Vector3(0, 0, a + PI / 4))
	_mi(ring, rb, MB.mat_glow())
	var sb := MB.new()
	sb.disc(Vector3.ZERO, 1.0, Color(col.r, col.g, col.b, 0.6 if open else 0.15), 32, Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 0.1), Vector3(PI / 2, 0, 0))
	var swirl := _pivot(root, Vector3(0, 1.55, 0))
	_mi(swirl, sb, MB.mat_glow())
	if open:
		var sw2 := MB.new()
		for k in 3:
			sw2.arc(Vector3.ZERO, 0.3 + k * 0.22, 0.06, k * 2.0, k * 2.0 + 3.0, Color(1, 1, 1, 0.5), 16, Vector3(PI / 2, 0, 0))
		_mi(swirl, sw2, MB.mat_glow())
	root.set_meta("ring", ring)
	root.set_meta("swirl", swirl)
	return root

static func spring_basin() -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var stone := MB.tag(Color("9aa4b4"), MB.STONE)
	b.lathe(Vector3.ZERO, [Vector2(1.45, 0.0), Vector2(1.5, 0.12), Vector2(1.42, 0.3), Vector2(1.25, 0.34), Vector2(1.18, 0.2)], stone, 24)
	for i in 10:
		var a := TAU * i / 10.0
		b.box(Vector3(cos(a) * 1.36, 0.36, sin(a) * 1.36), Vector3(0.36, 0.08, 0.26), MB.tag(Color("b4bcc8"), MB.STONE), Vector3(0, -a, 0))
	b.disc(Vector3(0, 0.24, 0), 1.2, MB.tag(Color("4aa0ff"), MB.CRYSTAL), 24, MB.tag(Color("2a70c8"), MB.CRYSTAL))
	# a little stone lantern beside the basin
	b.box(Vector3(1.9, 0.1, 0.2), Vector3(0.4, 0.2, 0.4), stone)
	b.cyl(Vector3(1.9, 0.5, 0.2), 0.08, 0.6, stone, Vector3.ZERO, 6)
	b.box(Vector3(1.9, 0.9, 0.2), Vector3(0.32, 0.26, 0.32), stone)
	b.cone(Vector3(1.9, 1.15, 0.2), 0.3, 0.25, stone, Vector3.ZERO, 4)
	_mi(root, b)
	var g := MB.new()
	g.disc(Vector3(0, 0.27, 0), 1.15, Color(0.4, 0.8, 1.0, 0.45), 24, Color(0.4, 0.8, 1.0, 0.05))
	g.cyl(Vector3(0, 1.1, 0), 0.08, 1.7, Color(0.5, 0.9, 1.0, 0.2), Vector3.ZERO, 14)
	g.box(Vector3(1.9, 0.9, 0.2), Vector3(0.2, 0.16, 0.34), Color(1.0, 0.8, 0.4, 0.8))
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

## Two-segment feathered or membrane wing; returns [shoulder, elbow] pivots.
static func _wing(parent: Node3D, side: int, pos: Vector3, span: float, chord: float, col: Color, tip: Color, feathers: bool = true) -> Node3D:
	var w := _pivot(parent, pos)
	var wb := MB.new()
	var cc := MB.tag(col, MB.SCALE if not feathers else MB.CLOTH)
	var tc := MB.tag(tip, MB.CLOTH)
	wb.limb(Vector3.ZERO, Vector3(span * 0.5 * side, 0.05, 0), 0.06, 0.045, cc, 6)
	if feathers:
		for i in 5:
			var x := span * (0.08 + i * 0.1) * side
			wb.leaf(Vector3(x, 0.02, 0.02), Vector3(x + span * 0.06 * side, -0.02, -chord * (0.75 + i * 0.05)), chord * 0.14, cc, Vector3(1, 0, 0), tc)
	else:
		wb.quad4(Vector3(0, 0, 0), Vector3(span * 0.5 * side, 0.05, 0), Vector3(span * 0.45 * side, 0, -chord), Vector3(0, 0, -chord * 0.7), cc, cc, tc, tc)
		wb.quad4(Vector3(0, 0, 0), Vector3(0, 0, -chord * 0.7), Vector3(span * 0.45 * side, 0, -chord), Vector3(span * 0.5 * side, 0.05, 0), cc, tc, tc, cc)
	_mi(w, wb)
	var outer := _pivot(w, Vector3(span * 0.5 * side, 0.05, 0))
	var ob := MB.new()
	ob.limb(Vector3.ZERO, Vector3(span * 0.48 * side, 0.08, -chord * 0.15), 0.045, 0.02, cc, 6)
	if feathers:
		for i in 6:
			var x2 := span * (0.04 + i * 0.08) * side
			ob.leaf(Vector3(x2, 0.02, 0.0), Vector3(x2 + span * (0.1 + i * 0.02) * side, -0.03, -chord * (0.95 - i * 0.05)), chord * 0.13, tc, Vector3(1, 0, 0), MB.tag(tip.lightened(0.25), MB.CLOTH))
	else:
		ob.quad4(Vector3.ZERO, Vector3(span * 0.48 * side, 0.08, -chord * 0.15), Vector3(span * 0.3 * side, 0, -chord * 0.9), Vector3(0, 0, -chord), cc, tc, tc, cc)
		ob.quad4(Vector3.ZERO, Vector3(0, 0, -chord), Vector3(span * 0.3 * side, 0, -chord * 0.9), Vector3(span * 0.48 * side, 0.08, -chord * 0.15), cc, cc, tc, tc)
	_mi(outer, ob, MB.mat_plain())
	w.set_meta("outer", outer)
	return w

## Chain of pivots (tails, tentacles, vines, necks).  Each segment is built by `seg_fn(mb, i, f)`.
static func _chain(parent: Node3D, start: Vector3, step: Vector3, count: int, r0: float, r1: float, col: Color, col_end: Color, mat: Material = null) -> Array:
	var out: Array = []
	var cur := _pivot(parent, start)
	for i in count:
		var f := i / float(maxi(1, count - 1))
		var b := MB.new()
		var cc := MB.tag(col.lerp(col_end, f), col.a)
		var r := lerpf(r0, r1, f)
		var r2 := lerpf(r0, r1, minf(1.0, (i + 1) / float(maxi(1, count - 1))))
		b.limb(Vector3.ZERO, step, r, r2, cc, 8)
		_mi(cur, b, mat)
		out.append(cur)
		if i < count - 1:
			cur = _pivot(cur, step)
	return out

static func _eyes(g: MB, b: MB, pos: Vector3, spread: float, r: float, col: Color, slit: bool = false) -> void:
	for s in [-1, 1]:
		var p := pos + Vector3(spread * s, 0, 0)
		b.ball(p, r * 1.15, MB.tag(Color("1a1018"), MB.SKIN), true)
		g.ball(p + Vector3(0, 0, r * 0.4), r * 0.85, Color(col.r, col.g, col.b, 1.0), true)
		if slit:
			b.box(p + Vector3(0, 0, r * 1.05), Vector3(r * 0.25, r * 1.4, r * 0.1), MB.tag(Color.BLACK, MB.SKIN))
		g.ball(p + Vector3(r * 0.3, r * 0.3, r * 0.9), r * 0.25, Color(1, 1, 1, 1), true)

## Procedural stand-ins for the Blender-only shapes (used if their .glb is missing).
const FALLBACK := {"scorpion": "crab", "mushroom": "plant", "mammoth": "beast", "moth": "bird", "hundun": "jelly", "fox": "beast", "carp": "serpent", "oxhead": "demon", "horseface": "demon", "jiangshi": "humanoid"}

static func monster(shape: String, col: Color, boss: bool = false) -> Node3D:
	if Assets.has_monster(shape):
		var gm := Assets.monster(shape, col)
		if boss:
			_boss_halo(gm, col)
		return gm
	shape = FALLBACK.get(shape, shape)
	match shape:
		"humanoid", "hero", "healer", "demon":
			return _humanoid_monster(shape, col, boss)
	var dark := col.darkened(0.45)
	var light := col.lightened(0.35)
	var b := MB.new()
	var g := MB.new()
	var root: Node3D
	var wings: Array = []
	var rig := {}
	b.ao_floor = 0.0
	b.ao_height = 0.9
	b.ao_strength = 0.3
	match shape:
		"beast":
			var fur := MB.tag(col, MB.CLOTH)
			b.sph_hi(Vector3(0, 0.82, -0.05), Vector3(0.36, 0.38, 0.66), fur)
			b.sph_hi(Vector3(0, 0.92, 0.4), Vector3(0.38, 0.42, 0.4), MB.tag(col.lightened(0.08), MB.CLOTH))
			b.sph(Vector3(0, 0.66, 0.1), Vector3(0.28, 0.2, 0.55), MB.tag(light, MB.CLOTH))
			# mane / spine ridge of fur tufts
			for i in 9:
				var z := 0.55 - i * 0.13
				b.leaf(Vector3(0, 1.1 + (0.12 if i < 3 else 0.0) - i * 0.015, z), Vector3(0, 1.32 - i * 0.02, z - 0.22), 0.09, MB.tag(dark, MB.HAIR), Vector3.RIGHT)
			for s in [-1, 1]:
				for i in 3:
					b.leaf(Vector3(0.3 * s, 1.0 - i * 0.1, 0.52), Vector3(0.48 * s, 0.85 - i * 0.12, 0.35), 0.08, MB.tag(dark, MB.HAIR), Vector3.UP)
			root = _node(b, g)
			# head with ears, snout, fangs and a hinged jaw
			var head := _pivot(root, Vector3(0, 1.08, 0.72))
			var hb := MB.new()
			hb.sph_hi(Vector3(0, 0, 0), Vector3(0.24, 0.23, 0.26), MB.tag(col, MB.CLOTH))
			hb.sph(Vector3(0, -0.05, 0.25), Vector3(0.13, 0.11, 0.18), MB.tag(light, MB.CLOTH))
			hb.ball(Vector3(0, 0.0, 0.42), 0.05, MB.tag(Color("1a1018"), MB.SKIN), true)
			for s in [-1, 1]:
				hb.cone(Vector3(0.14 * s, 0.24, -0.04), 0.07, 0.22, MB.tag(dark, MB.CLOTH), Vector3(-0.2, 0, -0.35 * s), 6)
				hb.cone(Vector3(0.14 * s, 0.22, -0.02), 0.04, 0.14, MB.tag(Color("ffb0b0"), MB.SKIN), Vector3(-0.2, 0, -0.35 * s), 6)
				hb.cone(Vector3(0.06 * s, -0.15, 0.33), 0.022, 0.09, MB.tag(Color("f8f4e8"), MB.STONE), Vector3(PI, 0, 0), 6)
			var hg := MB.new()
			_eyes(hg, hb, Vector3(0, 0.07, 0.2), 0.11, 0.045, Color("ffe060"), true)
			_mi(head, hb)
			_mi(head, hg, MB.mat_glow())
			var jaw := _pivot(head, Vector3(0, -0.1, 0.06))
			var jb := MB.new()
			jb.sph(Vector3(0, -0.04, 0.18), Vector3(0.11, 0.05, 0.17), MB.tag(light, MB.CLOTH))
			jb.box(Vector3(0, 0.0, 0.2), Vector3(0.14, 0.02, 0.2), MB.tag(Color("a03040"), MB.SKIN))
			_mi(jaw, jb)
			rig["head"] = head
			rig["jaw"] = jaw
			# legs: shoulder/hip -> lower leg -> paw
			var legs: Array = []
			for sz in [1, -1]:
				for sx in [-1, 1]:
					var lp := _pivot(root, Vector3(0.22 * sx, 0.8, 0.38 * sz))
					var lb := MB.new()
					lb.limb(Vector3.ZERO, Vector3(0, -0.38, 0.02 * sz), 0.11, 0.075, MB.tag(col.darkened(0.1), MB.CLOTH), 8)
					_mi(lp, lb)
					var low := _pivot(lp, Vector3(0, -0.38, 0.02 * sz))
					var lw := MB.new()
					lw.limb(Vector3.ZERO, Vector3(0, -0.36, -0.05 * sz), 0.07, 0.06, MB.tag(dark, MB.CLOTH), 8)
					lw.sph(Vector3(0, -0.38, 0.03), Vector3(0.08, 0.05, 0.11), MB.tag(dark.darkened(0.2), MB.CLOTH))
					for k in 3:
						lw.cone(Vector3((k - 1) * 0.04, -0.4, 0.13), 0.012, 0.06, MB.tag(Color("f0ece0"), MB.STONE), Vector3(PI / 2, 0, 0), 4)
					_mi(low, lw)
					legs.append([lp, low])
			rig["legs"] = legs
			rig["tail"] = _chain(root, Vector3(0, 0.95, -0.66), Vector3(0, 0.1, -0.2), 5, 0.08, 0.03, MB.tag(col, MB.CLOTH), MB.tag(dark, MB.CLOTH))
		"wisp":
			var core := MB.tag(light, MB.CRYSTAL)
			b.sph_hi(Vector3(0, 0.95, 0), Vector3(0.3, 0.32, 0.3), core)
			for i in range(1, 6):
				b.ball(Vector3(sin(i * 1.3) * 0.15, 0.95 - i * 0.1, -0.24 * i), 0.26 - i * 0.04, MB.tag(col.lerp(dark, i * 0.13), MB.CRYSTAL), true)
			var wg := MB.new()
			_eyes(wg, b, Vector3(0, 1.0, 0.25), 0.1, 0.05, Color(1, 1, 1))
			b.arc(Vector3(0, 0.88, 0.27), 0.07, 0.02, 0.3, PI - 0.3, MB.tag(Color("1a1018"), MB.SKIN), 8, Vector3(PI / 2, 0, 0))
			root = _node(b, wg)
			var flame := _pivot(root, Vector3(0, 0.95, 0))
			var fb := MB.new()
			for i in 7:
				var a := TAU * i / 7.0
				fb.leaf(Vector3(cos(a) * 0.2, 0.1, sin(a) * 0.2), Vector3(cos(a) * 0.32, 0.55 + (i % 3) * 0.12, sin(a) * 0.32 - 0.1), 0.12, Color(col.r, col.g, col.b, 0.75), Vector3(-sin(a), 0, cos(a)), Color(1, 1, 1, 0.2))
			_mi(flame, fb, MB.mat_glow())
			rig["flame"] = flame
			_aura(root, Vector3(0, 0.95, 0), Vector3(0.65, 0.65, 0.65), col, 0.3)
		"blob":
			var gel := MB.tag(col, MB.CRYSTAL)
			b.lathe(Vector3.ZERO, [Vector2(0.0, 0.02), Vector2(0.62, 0.05), Vector2(0.8, 0.3), Vector2(0.72, 0.65), Vector2(0.45, 0.95), Vector2(0.15, 1.08), Vector2(0.0, 1.1)], gel, 20, MB.tag(light, MB.CRYSTAL))
			for i in 6:
				var a := TAU * i / 6.0 + 0.3
				b.sph(Vector3(cos(a) * 0.72, 0.12, sin(a) * 0.72), Vector3(0.16, 0.08, 0.16), gel)
			b.sph(Vector3(-0.25, 0.85, 0.3), Vector3(0.16, 0.08, 0.12), MB.tag(Color.WHITE.lerp(col, 0.3), MB.CRYSTAL))
			root = _node(b, g)
			var face := _pivot(root, Vector3(0, 0.65, 0.62))
			var fb2 := MB.new()
			for s in [-1, 1]:
				fb2.sph(Vector3(0.22 * s, 0.05, 0.0), Vector3(0.13, 0.15, 0.05), MB.tag(Color.WHITE, MB.SKIN))
				fb2.sph(Vector3(0.22 * s, 0.03, 0.04), Vector3(0.065, 0.085, 0.03), MB.tag(Color("1a1018"), MB.SKIN))
				fb2.ball(Vector3(0.22 * s + 0.03, 0.08, 0.07), 0.022, MB.tag(Color.WHITE, MB.CRYSTAL), true)
			fb2.arc(Vector3(0, -0.18, 0.02), 0.13, 0.04, 0.2, PI - 0.2, MB.tag(Color("3a1018"), MB.SKIN), 10, Vector3(PI / 2, 0, 0))
			_mi(face, fb2, MB.mat_plain())
			rig["face"] = face
			_aura(root, Vector3(0, 0.5, 0), Vector3(0.95, 0.7, 0.95), col, 0.12)
		"wraith":
			var robe := MB.tag(col.darkened(0.15), MB.CLOTH)
			b.lathe(Vector3(0, 0.15, 0), [Vector2(0.55, 0.0), Vector2(0.45, 0.4), Vector2(0.36, 0.9), Vector2(0.34, 1.3), Vector2(0.28, 1.5), Vector2(0.0, 1.62)], robe, 16, MB.tag(col, MB.CLOTH))
			# hood
			b.lathe(Vector3(0, 1.55, -0.03), [Vector2(0.24, -0.1), Vector2(0.3, 0.1), Vector2(0.26, 0.3), Vector2(0.12, 0.45), Vector2(0.02, 0.5)], MB.tag(dark, MB.CLOTH), 14)
			b.sph(Vector3(0, 1.65, 0.12), Vector3(0.17, 0.2, 0.1), MB.tag(Color("0a0610"), MB.SKIN))
			# chains across the chest
			for i in 6:
				b.torus(Vector3(-0.25 + i * 0.1, 1.15 - absf(i - 2.5) * 0.04, 0.33), 0.04, 0.01, MB.tag(Color("8a8a9a"), MB.METAL), Vector3(PI / 2, 0, 0.5 * (i % 2)))
			g.ball(Vector3(-0.07, 1.67, 0.2), 0.04, Color.WHITE, true)
			g.ball(Vector3(0.07, 1.67, 0.2), 0.04, Color.WHITE, true)
			g.ball(Vector3(-0.07, 1.67, 0.2), 0.08, Color(col.r, col.g, col.b, 0.6), true)
			g.ball(Vector3(0.07, 1.67, 0.2), 0.08, Color(col.r, col.g, col.b, 0.6), true)
			root = _node(b, g)
			# tattered hem strips that flutter
			var hem: Array = []
			for i in 9:
				var a := TAU * i / 9.0
				var hp := _pivot(root, Vector3(sin(a) * 0.5, 0.2, cos(a) * 0.5))
				hp.rotation.y = a
				var hb2 := MB.new()
				hb2.ribbon([Vector3.ZERO, Vector3(0, -0.15, 0.05), Vector3(0, -0.32, 0.02)], [0.1, 0.08, 0.01], Vector3.RIGHT, robe, MB.tag(dark, MB.CLOTH))
				_mi(hp, hb2, MB.mat_plain())
				hem.append(hp)
			rig["hem"] = hem
			# clawed arms reaching forward
			var warms: Array = []
			for s in [-1, 1]:
				var ap := _pivot(root, Vector3(0.36 * s, 1.35, 0.05))
				var awb := MB.new()
				awb.limb(Vector3.ZERO, Vector3(0.1 * s, -0.25, 0.3), 0.09, 0.07, robe, 8)
				awb.lathe(Vector3(0.1 * s, -0.25, 0.3), [Vector2(0.06, 0.0), Vector2(0.14, -0.08)], MB.tag(dark, MB.CLOTH), 10)
				for k in 4:
					var fx := (k - 1.5) * 0.035
					awb.limb(Vector3(0.1 * s + fx, -0.32, 0.33), Vector3(0.1 * s + fx * 1.4, -0.48, 0.42), 0.014, 0.004, MB.tag(Color("d8d0e0"), MB.STONE), 4)
				_mi(ap, awb)
				warms.append(ap)
			rig["arms"] = warms
			_aura(root, Vector3(0, 0.95, 0), Vector3(0.75, 1.15, 0.75), col, 0.14)
		"plant":
			var stem := MB.tag(dark, MB.FOLIAGE)
			b.lathe(Vector3.ZERO, [Vector2(0.55, 0.0), Vector2(0.6, 0.2), Vector2(0.5, 0.5), Vector2(0.3, 0.75), Vector2(0.15, 0.85)], MB.tag(col, MB.FOLIAGE), 14, MB.tag(light, MB.FOLIAGE))
			for i in 8:
				var a := TAU * i / 8.0
				b.leaf(Vector3(cos(a) * 0.45, 0.1, sin(a) * 0.45), Vector3(cos(a) * 1.1, 0.25, sin(a) * 1.1), 0.22, MB.tag(col.darkened(0.15), MB.FOLIAGE), Vector3(-sin(a), 0, cos(a)), MB.tag(light, MB.FOLIAGE))
			root = _node(b, g)
			# flower head with petals and a toothy maw
			var bloom := _pivot(root, Vector3(0, 0.95, 0.15))
			var bb := MB.new()
			bb.sph_hi(Vector3.ZERO, Vector3(0.24, 0.24, 0.2), MB.tag(Color("ffd0f0"), MB.CLOTH))
			for i in 8:
				var a2 := TAU * i / 8.0
				bb.leaf(Vector3(cos(a2) * 0.15, sin(a2) * 0.15, 0.05), Vector3(cos(a2) * 0.5, sin(a2) * 0.5, 0.18), 0.17, MB.tag(Color("ff7ab0"), MB.CLOTH), Vector3(0, 0, 1), MB.tag(Color("ffe060"), MB.CLOTH))
			bb.disc(Vector3(0, 0, 0.2), 0.12, MB.tag(Color("3a0a1a"), MB.SKIN), 12, MB.tag(Color("6a1a2a"), MB.SKIN), Vector3(PI / 2, 0, 0))
			for i in 8:
				var a3 := TAU * i / 8.0
				bb.cone(Vector3(cos(a3) * 0.11, sin(a3) * 0.11, 0.21), 0.02, 0.07, MB.tag(Color("f8f4e8"), MB.STONE), Vector3(PI / 2, 0, 0) + Vector3(sin(a3) * 0.5, -cos(a3) * 0.5, 0), 4)
			_mi(bloom, bb)
			rig["head"] = bloom
			var vines: Array = []
			for i in 5:
				var a4 := (i - 2) * 0.62
				var ch := _chain(root, Vector3(sin(a4) * 0.35, 0.65, cos(a4) * 0.2 - 0.1), Vector3(sin(a4) * 0.12, 0.2, -0.02), 5, 0.06, 0.025, stem, MB.tag(col, MB.FOLIAGE))
				# a thorny bud at each vine tip
				var tipb := MB.new()
				tipb.ball(Vector3(sin(a4) * 0.12, 0.22, 0), 0.08, MB.tag(light, MB.FOLIAGE), true)
				for k in 3:
					tipb.cone(Vector3(sin(a4) * 0.12, 0.22, 0) + Vector3(cos(k * 2.1), 0.3, sin(k * 2.1)) * 0.08, 0.02, 0.08, MB.tag(Color("f0e8d0"), MB.STONE), Vector3(sin(k * 2.1) * 0.8, 0, -cos(k * 2.1) * 0.8), 4)
				_mi(ch[ch.size() - 1], tipb)
				vines.append(ch)
			rig["vines"] = vines
		"dragon":
			var scale_c := MB.tag(col, MB.SCALE)
			root = Node3D.new()
			# body: a chain of segments that undulates
			var segs: Array = []
			var cur := _pivot(root, Vector3(0, 0.55, -1.6))
			for i in 12:
				var f := i / 11.0
				var sb := MB.new()
				var r := 0.26 + sin(f * PI) * 0.18
				sb.sph_hi(Vector3(0, 0, 0.1), Vector3(r, r * 0.95, 0.26), MB.tag(col.lerp(light, f * 0.6), MB.SCALE))
				sb.sph(Vector3(0, -r * 0.45, 0.1), Vector3(r * 0.75, r * 0.5, 0.22), MB.tag(Color("f0e0b0").lerp(col, 0.3), MB.SCALE))
				sb.cone(Vector3(0, r + 0.06, 0.08), 0.06, 0.2, MB.tag(Color("f0e8d0") if i % 2 == 0 else dark, MB.STONE), Vector3(-0.4, 0, 0), 6)
				if i == 3 or i == 8:
					for s in [-1, 1]:
						sb.limb(Vector3(r * 0.8 * s, -0.1, 0.1), Vector3(r * 1.3 * s, -0.45, 0.2), 0.07, 0.05, scale_c, 6)
						for k in 3:
							sb.cone(Vector3(r * 1.3 * s + (k - 1) * 0.04, -0.5, 0.28), 0.015, 0.08, MB.tag(Color("f0ece0"), MB.STONE), Vector3(PI / 2, 0, 0), 4)
				_mi(cur, sb)
				segs.append(cur)
				if i < 11:
					cur = _pivot(cur, Vector3(0, 0.02, 0.21))
			rig["segs"] = segs
			# head on the last segment
			var dh := _pivot(cur, Vector3(0, 0.12, 0.35))
			var dhb := MB.new()
			dhb.sph_hi(Vector3(0, 0, 0), Vector3(0.26, 0.22, 0.3), scale_c)
			dhb.box(Vector3(0, -0.02, 0.32), Vector3(0.3, 0.16, 0.36), MB.tag(light, MB.SCALE))
			dhb.ball(Vector3(-0.08, 0.04, 0.5), 0.03, MB.tag(Color("1a1018"), MB.SKIN), true)
			dhb.ball(Vector3(0.08, 0.04, 0.5), 0.03, MB.tag(Color("1a1018"), MB.SKIN), true)
			for s in [-1, 1]:
				dhb.limb(Vector3(0.12 * s, 0.15, -0.05), Vector3(0.22 * s, 0.4, -0.35), 0.05, 0.02, MB.tag(Color("f0e0b0"), MB.STONE), 6)
				dhb.limb(Vector3(0.22 * s, 0.4, -0.35), Vector3(0.26 * s, 0.48, -0.6), 0.02, 0.0, MB.tag(Color("f0e0b0"), MB.STONE), 6)
				dhb.ribbon([Vector3(0.14 * s, -0.04, 0.46), Vector3(0.35 * s, -0.02, 0.4), Vector3(0.55 * s, -0.12, 0.2), Vector3(0.65 * s, -0.3, 0.0)], [0.015, 0.012, 0.008, 0.002], Vector3.UP, MB.tag(Color("f0d070"), MB.HAIR))
			for i in 5:
				dhb.leaf(Vector3(0, 0.18, -0.05 - i * 0.06), Vector3(0, 0.36 - i * 0.02, -0.3 - i * 0.06), 0.08, MB.tag(Color("f0d070").lerp(light, 0.4), MB.HAIR), Vector3.RIGHT)
			var dg := MB.new()
			_eyes(dg, dhb, Vector3(0, 0.1, 0.24), 0.14, 0.045, Color("ff4040"), true)
			_mi(dh, dhb)
			_mi(dh, dg, MB.mat_glow())
			var djaw := _pivot(dh, Vector3(0, -0.1, 0.1))
			var djb := MB.new()
			djb.box(Vector3(0, -0.03, 0.26), Vector3(0.26, 0.08, 0.36), MB.tag(light, MB.SCALE))
			for s in [-1, 1]:
				djb.cone(Vector3(0.1 * s, 0.03, 0.4), 0.02, 0.07, MB.tag(Color("f8f4e8"), MB.STONE), Vector3.ZERO, 4)
			_mi(djaw, djb)
			rig["head"] = dh
			rig["jaw"] = djaw
			wings.append(_wing(segs[5], -1, Vector3(-0.3, 0.25, 0.0), 1.6, 0.9, dark, col, false))
			wings.append(_wing(segs[5], 1, Vector3(0.3, 0.25, 0.0), 1.6, 0.9, dark, col, false))
		"bird", "phoenix", "ray":
			var ph := shape == "phoenix"
			var feather := MB.tag(light, MB.CLOTH)
			if shape == "ray":
				b.lathe(Vector3(0, 1.1, 0), [Vector2(0.0, -0.08), Vector2(0.55, -0.04), Vector2(0.6, 0.02), Vector2(0.3, 0.1), Vector2(0.0, 0.12)], MB.tag(col, MB.SCALE), 18, MB.tag(light, MB.SCALE), Vector2(0.7, 1.0))
				b.sph(Vector3(0, 1.08, 0.45), Vector3(0.3, 0.08, 0.2), MB.tag(light, MB.SCALE))
				for s in [-1, 1]:
					b.cone(Vector3(0.18 * s, 1.1, 0.68), 0.05, 0.22, MB.tag(dark, MB.SCALE), Vector3(PI / 2, 0, 0.2 * s), 6)
				var rgl := MB.new()
				_eyes(rgl, b, Vector3(0, 1.15, 0.5), 0.2, 0.04, Color("a0f0ff"))
				root = _node(b, rgl)
				rig["tail"] = _chain(root, Vector3(0, 1.1, -0.55), Vector3(0, 0, -0.3), 5, 0.04, 0.01, MB.tag(dark, MB.SCALE), MB.tag(light, MB.SCALE))
				wings.append(_wing(root, -1, Vector3(-0.4, 1.1, 0.1), 1.6, 0.8, col, light, false))
				wings.append(_wing(root, 1, Vector3(0.4, 1.1, 0.1), 1.6, 0.8, col, light, false))
			else:
				b.sph_hi(Vector3(0, 1.2, 0), Vector3(0.3, 0.32, 0.5), feather)
				b.sph(Vector3(0, 1.1, 0.15), Vector3(0.24, 0.24, 0.35), MB.tag(Color("f8f0e0").lerp(col, 0.3), MB.CLOTH))
				for s in [-1, 1]:
					b.limb(Vector3(0.12 * s, 0.95, 0.0), Vector3(0.14 * s, 0.55, 0.05), 0.04, 0.03, MB.tag(Color("e0a040"), MB.SCALE), 6)
					for k in 3:
						b.limb(Vector3(0.14 * s, 0.55, 0.05), Vector3(0.14 * s + (k - 1) * 0.06, 0.5, 0.18), 0.015, 0.008, MB.tag(Color("e0a040"), MB.SCALE), 4)
				root = _node(b, g)
				var bh := _pivot(root, Vector3(0, 1.45, 0.42))
				var bhb := MB.new()
				bhb.sph_hi(Vector3.ZERO, Vector3(0.18, 0.18, 0.2), MB.tag(col, MB.CLOTH))
				bhb.cone(Vector3(0, -0.02, 0.26), 0.06, 0.24, MB.tag(Color("f0c860"), MB.METAL), Vector3(PI / 2 + 0.2, 0, 0), 6)
				var crest_n := 5 if ph else 3
				for i in crest_n:
					var ca := (i - (crest_n - 1) * 0.5) * 0.25
					bhb.leaf(Vector3(0, 0.14, 0.0), Vector3(sin(ca) * 0.15, 0.45 + (0.15 if ph else 0.0), -0.2), 0.06, MB.tag(Color("ffe060") if ph else dark, MB.CLOTH), Vector3.RIGHT, MB.tag(Color("ff6020") if ph else col, MB.CLOTH))
				var bg := MB.new()
				_eyes(bg, bhb, Vector3(0, 0.05, 0.12), 0.11, 0.035, Color("ffe060") if ph else Color("ff6040"))
				_mi(bh, bhb)
				_mi(bh, bg, MB.mat_glow())
				rig["head"] = bh
				# fanned tail plumes on a pivot
				var tail := _pivot(root, Vector3(0, 1.15, -0.45))
				var tb := MB.new()
				var tail_n := 7 if ph else 5
				for i in tail_n:
					var a := (i - (tail_n - 1) * 0.5) * 0.2
					var ln := 1.4 if ph else 0.9
					tb.leaf(Vector3.ZERO, Vector3(sin(a) * ln * 0.5, -0.25 - absf(a) * 0.3, -ln), 0.1 if not ph else 0.13, MB.tag(col.lerp(dark, absf(a)), MB.CLOTH), Vector3(cos(a), 0, 0), MB.tag(Color("ffe060") if ph else light, MB.CLOTH))
				_mi(tail, tb, MB.mat_plain())
				rig["tail_p"] = tail
				if ph:
					var tgl := MB.new()
					for i in tail_n:
						var a2 := (i - (tail_n - 1) * 0.5) * 0.2
						tgl.ball(Vector3(sin(a2) * 0.7, -0.25 - absf(a2) * 0.3 - 0.05, -1.4), 0.09, Color(1.0, 0.8, 0.3, 0.9), true)
					_mi(tail, tgl, MB.mat_glow())
					_aura(root, Vector3(0, 1.2, -0.2), Vector3(1.0, 0.8, 1.3), Color(1.0, 0.55, 0.1), 0.2)
				var spread := 1.25 if ph else 1.0
				wings.append(_wing(root, -1, Vector3(-0.22, 1.32, 0.05), 1.1 * spread, 0.75, col, light))
				wings.append(_wing(root, 1, Vector3(0.22, 1.32, 0.05), 1.1 * spread, 0.75, col, light))
		"storm":
			root = Node3D.new()
			var cloud := _pivot(root, Vector3(0, 1.75, 0))
			var cb := MB.new()
			var cp := [Vector3(-0.7, 0, 0), Vector3(0.0, 0.25, 0.1), Vector3(0.7, 0, -0.1), Vector3(-0.3, -0.1, 0.5), Vector3(0.4, -0.15, 0.45), Vector3(0.1, 0.1, -0.5), Vector3(-0.55, 0.15, -0.35)]
			for p in cp:
				cb.sph_hi(p, Vector3(0.6, 0.4, 0.55), MB.tag(Color(0.38, 0.4, 0.56).lerp(col, 0.3), MB.CLOTH))
				cb.sph(p + Vector3(0, 0.2, 0), Vector3(0.4, 0.25, 0.38), MB.tag(Color(0.62, 0.64, 0.78).lerp(col, 0.25), MB.CLOTH))
			_mi(cloud, cb)
			var eg := MB.new()
			for s in [-1, 1]:
				eg.sph(Vector3(0.22 * s, -0.05, 0.55), Vector3(0.12, 0.06, 0.04), Color(1, 1, 0.8, 1), Vector3(0, 0, 0.3 * s))
			_mi(cloud, eg, MB.mat_glow())
			rig["cloud"] = cloud
			var bolts: Array = []
			for k in 3:
				var bolt := Vector3((k - 1) * 0.5, 1.45, 0.25)
				var bb2 := MB.new()
				var pts: Array = [bolt]
				for i in 6:
					bolt = Vector3(bolt.x + ((i % 2) * 2 - 1) * 0.18, bolt.y - 0.26, bolt.z)
					pts.append(bolt)
				bb2.ribbon(pts, [0.05, 0.05, 0.045, 0.04, 0.03, 0.02, 0.01], Vector3.RIGHT, Color(0.95, 0.97, 1.0, 1.0), Color(col.r, col.g, col.b, 0.8))
				bb2.ribbon(pts, [0.05, 0.05, 0.045, 0.04, 0.03, 0.02, 0.01], Vector3.BACK, Color(0.95, 0.97, 1.0, 1.0), Color(col.r, col.g, col.b, 0.8))
				bolts.append(_mi(root, bb2, MB.mat_glow()))
			rig["bolts"] = bolts
			_aura(root, Vector3(0, 1.6, 0), Vector3(1.4, 0.9, 1.2), Color(0.7, 0.8, 1.0), 0.15)
		"golem":
			var rock := MB.tag(col, MB.STONE)
			var rock_d := MB.tag(dark, MB.STONE)
			b.lathe(Vector3(0, 0.75, 0), [Vector2(0.4, 0.0), Vector2(0.55, 0.3), Vector2(0.6, 0.65), Vector2(0.48, 0.95), Vector2(0.2, 1.05)], rock, 8, MB.tag(light, MB.STONE), Vector2(1.0, 0.75))
			b.box(Vector3(0, 0.82, 0), Vector3(0.9, 0.2, 0.58), rock_d)
			for i in 5:
				b.crystal(Vector3(-0.35 + i * 0.17, 1.75 + sin(i) * 0.05, -0.2), 0.08, 0.35 + (i % 2) * 0.15, MB.tag(light.lerp(Color.WHITE, 0.3), MB.CRYSTAL), Vector3(-0.3, 0, (i - 2) * 0.2), 6)
			# legs (static stumps)
			for s in [-1, 1]:
				b.limb(Vector3(0.28 * s, 0.8, 0), Vector3(0.3 * s, 0.2, 0.02), 0.2, 0.18, rock_d, 6)
				b.box(Vector3(0.3 * s, 0.12, 0.08), Vector3(0.38, 0.24, 0.48), rock)
			# head
			b.box(Vector3(0, 1.95, 0.08), Vector3(0.44, 0.36, 0.4), MB.tag(light, MB.STONE), Vector3(0.1, 0, 0))
			b.box(Vector3(0, 2.07, 0.22), Vector3(0.46, 0.08, 0.18), rock_d, Vector3(0.2, 0, 0))
			g.ball(Vector3(0, 1.3, 0.42), 0.15, Color(1.0, 0.7, 0.3, 1.0), true)
			g.box(Vector3(-0.1, 1.96, 0.29), Vector3(0.11, 0.05, 0.03), Color(1.0, 0.75, 0.3))
			g.box(Vector3(0.1, 1.96, 0.29), Vector3(0.11, 0.05, 0.03), Color(1.0, 0.75, 0.3))
			# glowing rune seams
			for i in 4:
				var a := -0.6 + i * 0.4
				g.box(Vector3(sin(a) * 0.55, 1.1 + i * 0.12, cos(a) * 0.42), Vector3(0.18, 0.03, 0.02), Color(1.0, 0.6, 0.2, 0.85), Vector3(0, a, 0.3))
			root = _node(b, g)
			_aura(root, Vector3(0, 1.3, 0.42), Vector3(0.35, 0.35, 0.35), Color(1.0, 0.6, 0.2), 0.7)
			var garms: Array = []
			for s in [-1, 1]:
				var ap2 := _pivot(root, Vector3(0.68 * s, 1.55, 0))
				var gab := MB.new()
				gab.ball(Vector3(0, 0, 0), 0.3, MB.tag(light, MB.STONE), true)
				gab.limb(Vector3(0.05 * s, -0.1, 0), Vector3(0.12 * s, -0.6, 0.05), 0.17, 0.15, rock, 6)
				gab.box(Vector3(0.14 * s, -0.85, 0.1), Vector3(0.42, 0.42, 0.42), rock_d, Vector3(0.2, 0.3, 0))
				for k in 3:
					gab.cone(Vector3(0.14 * s + (k - 1) * 0.12, -1.0, 0.25), 0.05, 0.16, MB.tag(light, MB.STONE), Vector3(PI / 2 + 0.5, 0, 0), 4)
				_mi(ap2, gab)
				garms.append(ap2)
			rig["arms"] = garms
			var orbit := _pivot(root, Vector3(0, 1.4, 0))
			var ob := MB.new()
			for i in 5:
				var a5 := TAU * i / 5.0
				ob.box(Vector3(cos(a5) * 1.05, sin(i * 1.7) * 0.25, sin(a5) * 1.05), Vector3(0.16, 0.14, 0.18), rock, Vector3(i, i * 0.7, 0))
			_mi(orbit, ob)
			rig["orbit"] = orbit
		"serpent":
			var scl := MB.tag(col, MB.SCALE)
			# coiled lower body
			for i in 14:
				var f := i / 13.0
				var a := f * TAU * 1.2
				var rh := 0.6 * (1.0 - f * 0.3)
				b.sph_hi(Vector3(cos(a) * rh, 0.2 + f * 0.35, sin(a) * rh), Vector3(0.25, 0.22, 0.25) * (1.0 - f * 0.25), MB.tag(col.lerp(light, f * 0.4), MB.SCALE))
			root = _node(b, g)
			var neck := _chain(root, Vector3(0.35, 0.6, 0.35), Vector3(0, 0.22, 0.04), 5, 0.18, 0.15, scl, MB.tag(light, MB.SCALE))
			var top: Node3D = neck[neck.size() - 1]
			var sh := _pivot(top, Vector3(0, 0.25, 0.05))
			var shb := MB.new()
			# cobra hood
			shb.ribbon([Vector3(0, -0.35, -0.04), Vector3(0, -0.15, -0.06), Vector3(0, 0.02, -0.05)], [0.18, 0.32, 0.18], Vector3.RIGHT, MB.tag(col.darkened(0.1), MB.SCALE), MB.tag(light, MB.SCALE))
			shb.sph_hi(Vector3(0, 0.05, 0.12), Vector3(0.17, 0.13, 0.25), MB.tag(light, MB.SCALE))
			for s in [-1, 1]:
				shb.cone(Vector3(0.14 * s, 0.13, -0.02), 0.05, 0.22, MB.tag(dark, MB.STONE), Vector3(-0.6, 0, -0.5 * s), 6)
			var sgl := MB.new()
			_eyes(sgl, shb, Vector3(0, 0.12, 0.25), 0.08, 0.035, Color("ffe040"), true)
			_mi(sh, shb)
			_mi(sh, sgl, MB.mat_glow())
			var tongue := _pivot(sh, Vector3(0, 0.0, 0.36))
			var tgb := MB.new()
			tgb.ribbon([Vector3.ZERO, Vector3(0, -0.02, 0.12), Vector3(0.03, -0.02, 0.2)], [0.012, 0.01, 0.003], Vector3.UP, MB.tag(Color("e03050"), MB.SKIN))
			tgb.ribbon([Vector3(0, -0.02, 0.12), Vector3(-0.03, -0.02, 0.2)], [0.01, 0.003], Vector3.UP, MB.tag(Color("e03050"), MB.SKIN))
			_mi(tongue, tgb, MB.mat_plain())
			rig["neck"] = neck
			rig["head"] = sh
			rig["tongue"] = tongue
		"crab":
			var shell := MB.tag(col, MB.SCALE)
			b.hemi(Vector3(0, 0.45, 0), Vector3(0.82, 0.38, 0.6), shell)
			b.sph(Vector3(0, 0.42, 0), Vector3(0.78, 0.12, 0.58), MB.tag(dark, MB.SCALE))
			for i in 5:
				b.cone(Vector3(-0.5 + i * 0.25, 0.75 - absf(i - 2) * 0.06, -0.1), 0.06, 0.16, MB.tag(light, MB.STONE), Vector3(-0.2, 0, 0), 6)
			for i in 3:
				b.arc(Vector3(0, 0.48 + i * 0.1, 0), 0.7 - i * 0.18, 0.03, 0.0, PI, MB.tag(light, MB.SCALE), 14, Vector3(0, 0, 0))
			for s in [-1, 1]:
				b.cyl(Vector3(0.18 * s, 0.85, 0.42), 0.025, 0.3, MB.tag(dark, MB.SCALE))
			var cg := MB.new()
			for s in [-1, 1]:
				cg.ball(Vector3(0.18 * s, 1.02, 0.42), 0.06, Color(1, 1, 0.8), true)
			root = _node(b, cg)
			var claws: Array = []
			for s in [-1, 1]:
				var arm_p := _pivot(root, Vector3(0.7 * s, 0.55, 0.35))
				var arb := MB.new()
				arb.limb(Vector3.ZERO, Vector3(0.25 * s, 0.1, 0.35), 0.08, 0.07, shell, 8)
				arb.sph_hi(Vector3(0.3 * s, 0.15, 0.55), Vector3(0.26, 0.18, 0.24), MB.tag(light, MB.SCALE))
				arb.cone(Vector3(0.3 * s, 0.1, 0.84), 0.09, 0.32, MB.tag(dark, MB.STONE), Vector3(PI / 2, 0, 0), 6)
				_mi(arm_p, arb)
				var pincer := _pivot(arm_p, Vector3(0.3 * s, 0.24, 0.7))
				var pb := MB.new()
				pb.cone(Vector3(0, 0, 0.14), 0.07, 0.3, MB.tag(light, MB.SCALE), Vector3(PI / 2, 0, 0), 6)
				_mi(pincer, pb)
				claws.append([arm_p, pincer])
			rig["claws"] = claws
			var clegs: Array = []
			for s in [-1, 1]:
				for k in 3:
					var lp2 := _pivot(root, Vector3(0.65 * s, 0.4, -0.25 + k * 0.25))
					var clb := MB.new()
					clb.limb(Vector3.ZERO, Vector3(0.35 * s, 0.15, 0), 0.045, 0.035, shell, 6)
					clb.limb(Vector3(0.35 * s, 0.15, 0), Vector3(0.55 * s, -0.38, 0), 0.035, 0.01, MB.tag(dark, MB.SCALE), 6)
					_mi(lp2, clb)
					clegs.append(lp2)
			rig["legs6"] = clegs
		"spider", "mantis":
			if shape == "spider":
				b.sph_hi(Vector3(0, 0.75, -0.5), Vector3(0.48, 0.42, 0.6), MB.tag(col, MB.SCALE))
				# abdomen markings
				for i in 3:
					b.sph(Vector3(0, 0.98 + i * 0.0, -0.3 - i * 0.22), Vector3(0.12 - i * 0.02, 0.05, 0.08), MB.tag(Color("e04040").lerp(light, 0.4), MB.SCALE))
				for i in 6:
					var a := -0.9 + i * 0.36
					b.cone(Vector3(sin(a) * 0.4, 0.95, -0.5 + cos(a) * 0.3), 0.025, 0.12, MB.tag(dark, MB.HAIR), Vector3(-0.3, 0, -a * 0.5), 4)
				b.sph_hi(Vector3(0, 0.7, 0.18), Vector3(0.3, 0.24, 0.3), MB.tag(light, MB.SCALE))
				for s in [-1, 1]:
					b.limb(Vector3(0.08 * s, 0.6, 0.42), Vector3(0.06 * s, 0.42, 0.52), 0.04, 0.012, MB.tag(Color("e8e0d0"), MB.STONE), 6)
				for i in 6:
					g.ball(Vector3((i % 3 - 1) * 0.09, 0.8 + (i / 3) * 0.07, 0.44), 0.035 - (i / 3) * 0.01, Color("ff3030"), true)
				root = _node(b, g)
				var slegs: Array = []
				for s in [-1, 1]:
					for k in 4:
						var zk := 0.4 - k * 0.26
						var lp3 := _pivot(root, Vector3(0.22 * s, 0.75, zk))
						lp3.rotation.y = (k - 1.5) * -0.35 * s
						var slb := MB.new()
						slb.limb(Vector3.ZERO, Vector3(0.45 * s, 0.35, 0), 0.04, 0.035, MB.tag(dark, MB.SCALE), 6)
						_mi(lp3, slb)
						var low2 := _pivot(lp3, Vector3(0.45 * s, 0.35, 0))
						var slb2 := MB.new()
						slb2.limb(Vector3.ZERO, Vector3(0.35 * s, -1.08, 0), 0.035, 0.012, MB.tag(col.darkened(0.2), MB.SCALE), 6)
						_mi(low2, slb2)
						slegs.append(lp3)
				rig["legs8"] = slegs
			else:
				# mantis: slender thorax, triangular head with huge eyes, raptor arms and folded wings
				var chit := MB.tag(col, MB.SCALE)
				b.sph_hi(Vector3(0, 0.75, -0.55), Vector3(0.24, 0.22, 0.6), MB.tag(col.darkened(0.1), MB.SCALE))
				for i in 4:
					b.torus(Vector3(0, 0.75, -0.3 - i * 0.18), 0.21 - i * 0.02, 0.012, MB.tag(dark, MB.SCALE), Vector3(PI / 2, 0, 0))
				b.limb(Vector3(0, 0.8, -0.05), Vector3(0, 1.45, 0.3), 0.11, 0.08, chit, 8)
				for s in [-1, 1]:
					for k in 2:
						b.limb(Vector3(0.08 * s, 0.78, -0.2 - k * 0.35), Vector3(0.45 * s, 0.6, -0.15 - k * 0.42), 0.03, 0.025, MB.tag(dark, MB.SCALE), 6)
						b.limb(Vector3(0.45 * s, 0.6, -0.15 - k * 0.42), Vector3(0.55 * s, 0.0, -0.1 - k * 0.5), 0.025, 0.01, MB.tag(dark, MB.SCALE), 6)
					b.leaf(Vector3(0.05 * s, 1.0, -0.1), Vector3(0.18 * s, 0.85, -1.15), 0.2, MB.tag(Color(light.r, light.g, light.b, 1.0), MB.FOLIAGE), Vector3.UP, MB.tag(col, MB.FOLIAGE))
				root = _node(b, g)
				var mh := _pivot(root, Vector3(0, 1.55, 0.36))
				var mhb := MB.new()
				mhb.prim("cone4", Transform3D(Basis.from_euler(Vector3(PI, PI / 4, 0)).scaled(Vector3(0.36, 0.3, 0.2)), Vector3(0, 0, 0.02)), MB.tag(light, MB.SCALE))
				for s in [-1, 1]:
					mhb.sph_hi(Vector3(0.15 * s, 0.06, 0.02), Vector3(0.08, 0.1, 0.08), MB.tag(Color("40e080").lerp(col, 0.3), MB.CRYSTAL))
					mhb.ribbon([Vector3(0.05 * s, 0.12, 0.04), Vector3(0.18 * s, 0.4, 0.1), Vector3(0.3 * s, 0.55, -0.05)], [0.01, 0.008, 0.002], Vector3.FORWARD, MB.tag(dark, MB.SCALE))
				mhb.box(Vector3(0, -0.12, 0.06), Vector3(0.08, 0.06, 0.05), MB.tag(dark, MB.SCALE))
				_mi(mh, mhb)
				rig["head"] = mh
				var marms: Array = []
				for s in [-1, 1]:
					var ap3 := _pivot(root, Vector3(0.1 * s, 1.25, 0.2))
					var mab := MB.new()
					mab.limb(Vector3.ZERO, Vector3(0.05 * s, 0.35, 0.3), 0.05, 0.045, chit, 6)
					_mi(ap3, mab)
					var scythe := _pivot(ap3, Vector3(0.05 * s, 0.35, 0.3))
					var scb := MB.new()
					scb.limb(Vector3.ZERO, Vector3(0, -0.5, 0.15), 0.04, 0.02, chit, 6)
					for k in 4:
						scb.cone(Vector3(0, -0.1 - k * 0.1, 0.06 + k * 0.03), 0.012, 0.07, MB.tag(Color("f0f0e0"), MB.STONE), Vector3(-0.8, 0, 0), 4)
					_mi(scythe, scb)
					marms.append([ap3, scythe])
				rig["scythes"] = marms
		"tortoise":
			var sh2 := MB.tag(col, MB.STONE)
			b.lathe(Vector3(0, 0.45, 0), [Vector2(1.05, 0.0), Vector2(1.08, 0.12), Vector2(0.95, 0.45), Vector2(0.65, 0.78), Vector2(0.3, 0.92), Vector2(0.0, 0.95)], sh2, 12, MB.tag(light, MB.STONE), Vector2(0.95, 1.15))
			b.cyl(Vector3(0, 0.45, 0), 1.06, 0.12, MB.tag(dark, MB.STONE), Vector3.ZERO, 24)
			# hex plates
			for i in 6:
				var a := TAU * i / 6.0
				b.cyl(Vector3(cos(a) * 0.55, 1.15, sin(a) * 0.62), 0.24, 0.06, MB.tag(light.lerp(col, 0.4), MB.STONE), Vector3(sin(a) * -0.5, 0, cos(a) * 0.45), 6)
			b.cyl(Vector3(0, 1.42, 0), 0.26, 0.06, MB.tag(light, MB.STONE), Vector3.ZERO, 6)
			# a tiny world on its back: a pagoda, a tree, crystals
			b.box(Vector3(0.1, 1.58, -0.1), Vector3(0.22, 0.2, 0.22), MB.tag(Color("e8dcc0"), MB.WOOD))
			b.cone(Vector3(0.1, 1.75, -0.1), 0.2, 0.16, MB.tag(Color("3a5a8a"), MB.STONE), Vector3(0, PI / 4, 0), 4)
			b.limb(Vector3(-0.3, 1.4, 0.15), Vector3(-0.32, 1.8, 0.15), 0.04, 0.03, MB.tag(Color("6a4a2a"), MB.WOOD), 6)
			b.sph(Vector3(-0.32, 1.9, 0.15), Vector3(0.2, 0.15, 0.2), MB.tag(Color("6ac070"), MB.FOLIAGE))
			for i in 3:
				b.crystal(Vector3(0.45 - i * 0.2, 1.3, 0.4 - i * 0.05), 0.06, 0.3, MB.tag(Color("ffd070"), MB.CRYSTAL), Vector3(0.3, 0, -0.3 + i * 0.3), 6)
			root = _node(b, g)
			var th := _pivot(root, Vector3(0, 0.6, 1.05))
			var thb := MB.new()
			thb.limb(Vector3(0, 0, -0.2), Vector3(0, 0.18, 0.15), 0.17, 0.15, MB.tag(Color("a89060").lerp(col, 0.3), MB.SCALE), 8)
			thb.sph_hi(Vector3(0, 0.22, 0.28), Vector3(0.2, 0.17, 0.25), MB.tag(Color("b8a070").lerp(col, 0.3), MB.SCALE))
			thb.ribbon([Vector3(0, 0.08, 0.42), Vector3(0, -0.15, 0.45), Vector3(0, -0.45, 0.38)], [0.03, 0.05, 0.01], Vector3.RIGHT, MB.tag(Color("f0f0f0"), MB.HAIR))
			var tgl2 := MB.new()
			_eyes(tgl2, thb, Vector3(0, 0.28, 0.42), 0.11, 0.035, Color("ffd070"))
			_mi(th, thb)
			_mi(th, tgl2, MB.mat_glow())
			rig["head"] = th
			var tlegs: Array = []
			for sz in [1, -1]:
				for sx in [-1, 1]:
					var lp4 := _pivot(root, Vector3(0.75 * sx, 0.5, 0.6 * sz))
					var tlb := MB.new()
					tlb.limb(Vector3.ZERO, Vector3(0.1 * sx, -0.45, 0.05 * sz), 0.18, 0.2, MB.tag(Color("a89060").lerp(col, 0.3), MB.SCALE), 8)
					for k in 3:
						tlb.cone(Vector3(0.1 * sx + (k - 1) * 0.07, -0.47, 0.05 * sz + 0.16), 0.03, 0.08, MB.tag(Color("f0ece0"), MB.STONE), Vector3(PI / 2, 0, 0), 4)
					_mi(lp4, tlb)
					tlegs.append(lp4)
			rig["legs"] = tlegs
		"jelly":
			var gs := MB.new()
			gs.lathe(Vector3(0, 0.75, 0), [Vector2(0.75, 0.0), Vector2(0.78, 0.15), Vector2(0.65, 0.45), Vector2(0.4, 0.66), Vector2(0.0, 0.74)], Color(col.r, col.g, col.b, 0.5), 20, Color(light.r, light.g, light.b, 0.65))
			gs.lathe(Vector3(0, 0.75, 0), [Vector2(0.0, 0.05), Vector2(0.55, 0.0), Vector2(0.72, 0.02)], Color(col.r, col.g, col.b, 0.35), 20)
			# frilled bell rim
			for i in 16:
				var a := TAU * i / 16.0
				gs.sph(Vector3(cos(a) * 0.75, 0.74, sin(a) * 0.75), Vector3(0.1, 0.06, 0.1), Color(light.r, light.g, light.b, 0.55))
			g.sph_hi(Vector3(0, 1.05, 0), Vector3(0.28, 0.22, 0.28), Color(light.r, light.g, light.b, 0.8))
			for i in 4:
				var a2 := TAU * i / 4.0
				g.torus(Vector3(cos(a2) * 0.2, 0.95, sin(a2) * 0.2), 0.09, 0.012, Color(1, 1, 1, 0.7), Vector3(0.3, a2, 0))
			b.ball(Vector3(-0.17, 1.0, 0.62), 0.06, MB.tag(Color.BLACK, MB.SKIN), true)
			b.ball(Vector3(0.17, 1.0, 0.62), 0.06, MB.tag(Color.BLACK, MB.SKIN), true)
			b.ball(Vector3(-0.15, 1.02, 0.67), 0.02, MB.tag(Color.WHITE, MB.CRYSTAL), true)
			b.ball(Vector3(0.19, 1.02, 0.67), 0.02, MB.tag(Color.WHITE, MB.CRYSTAL), true)
			root = _node(b, g, gs)
			var bell := root.get_child(root.get_child_count() - 1)
			rig["bell"] = bell
			var tents: Array = []
			for i in 8:
				var a3 := TAU * i / 8.0
				var ch2 := _chain(root, Vector3(cos(a3) * 0.5, 0.75, sin(a3) * 0.5), Vector3(0, -0.2, 0), 5, 0.04, 0.012, Color(col.lightened(0.2).r, col.lightened(0.2).g, col.lightened(0.2).b, 0.7), Color(light.r, light.g, light.b, 0.3), MB.mat_glass())
				tents.append(ch2)
			rig["tents"] = tents
			_aura(root, Vector3(0, 1.0, 0), Vector3(0.95, 0.75, 0.95), col, 0.14)
		"tome":
			# the Jade Ledger: a floating open book with jade covers, fluttering pages and orbiting seals
			root = Node3D.new()
			var book := _pivot(root, Vector3(0, 1.5, 0))
			book.rotation.x = -0.5
			var spine := MB.new()
			var jade := MB.tag(col, MB.CRYSTAL)
			var gold := MB.tag(Color("e8c860"), MB.METAL)
			spine.cyl(Vector3.ZERO, 0.09, 1.3, gold, Vector3(PI / 2, 0, 0), 8)
			for k in 3:
				spine.torus(Vector3(0, 0, -0.45 + k * 0.45), 0.1, 0.012, MB.tag(Color("f0d070"), MB.METAL), Vector3(PI / 2, 0, 0))
			_mi(book, spine)
			var covers: Array = []
			for s2 in [-1, 1]:
				var cv := _pivot(book, Vector3.ZERO)
				var cb2 := MB.new()
				cb2.box(Vector3(0.55 * s2, 0, 0), Vector3(1.1, 0.06, 1.3), jade)
				cb2.box(Vector3(0.55 * s2, 0.035, 0), Vector3(0.9, 0.02, 1.1), gold)
				cb2.box(Vector3(0.55 * s2, -0.04, 0), Vector3(1.04, 0.02, 1.24), MB.tag(Color("f4ecd8"), MB.CLOTH))
				for k in 4:
					cb2.ball(Vector3((0.1 + k * 0.3) * s2, 0.05, 0.62), 0.03, gold, true)
				_mi(cv, cb2)
				var tx := MB.new()
				for row in 6:
					for c2 in 4:
						if (row + c2) % 3 != 0:
							tx.box(Vector3((0.2 + c2 * 0.22) * s2, -0.06, -0.45 + row * 0.18), Vector3(0.12, 0.004, 0.035), Color(col.r, col.g, col.b, 0.95))
				_mi(cv, tx, MB.mat_glow())
				covers.append(cv)
			rig["covers"] = covers
			var pages: Array = []
			for i in 6:
				var pg := _pivot(book, Vector3(0, -0.03, 0))
				var pgb := MB.new()
				pgb.ribbon([Vector3(0, 0, -0.6), Vector3(0, 0, 0.6)], [0.0, 0.0], Vector3.RIGHT, MB.tag(Color("f8f0dc"), MB.CLOTH))
				pgb.quad4(Vector3(0, 0, -0.6), Vector3(0, 0, 0.6), Vector3(1.0, 0, 0.6), Vector3(1.0, 0, -0.6), MB.tag(Color("f8f0dc"), MB.CLOTH), MB.tag(Color("f8f0dc"), MB.CLOTH), MB.tag(Color("e8dcc0"), MB.CLOTH), MB.tag(Color("e8dcc0"), MB.CLOTH))
				pgb.quad4(Vector3(0, -0.005, -0.6), Vector3(1.0, -0.005, -0.6), Vector3(1.0, -0.005, 0.6), Vector3(0, -0.005, 0.6), MB.tag(Color("f8f0dc"), MB.CLOTH), MB.tag(Color("e8dcc0"), MB.CLOTH), MB.tag(Color("e8dcc0"), MB.CLOTH), MB.tag(Color("f8f0dc"), MB.CLOTH))
				_mi(pg, pgb, MB.mat_plain())
				pages.append(pg)
			rig["pages"] = pages
			# a great eye of jade ink above the spine
			var eye := MB.new()
			eye.sph_hi(Vector3(0, 0.55, -0.1), Vector3(0.22, 0.22, 0.22), MB.tag(Color("f8f8f0"), MB.SKIN))
			eye.sph(Vector3(0, 0.55, 0.08), Vector3(0.12, 0.12, 0.06), MB.tag(col, MB.CRYSTAL))
			eye.sph(Vector3(0, 0.55, 0.13), Vector3(0.03, 0.09, 0.02), MB.tag(Color("0a0a0a"), MB.SKIN))
			_mi(book, eye)
			var orbit2 := _pivot(root, Vector3(0, 1.5, 0))
			var ob2 := MB.new()
			for i in 6:
				var a11 := TAU * i / 6.0
				var p11 := Vector3(cos(a11) * 1.5, sin(i * 2.0) * 0.3, sin(a11) * 1.5)
				if i % 2 == 0:
					ob2.box(p11, Vector3(0.22, 0.22, 0.22), MB.tag(col.lightened(0.2), MB.CRYSTAL), Vector3(0.3, a11, 0))
					ob2.box(p11 + Vector3(0, -0.13, 0), Vector3(0.18, 0.05, 0.18), MB.tag(Color("c83030"), MB.CLOTH), Vector3(0.3, a11, 0))
				else:
					ob2.limb(p11 + Vector3(0, -0.3, 0), p11 + Vector3(0, 0.3, 0), 0.03, 0.02, MB.tag(Color("6a4a2a"), MB.WOOD), 6)
					ob2.cone(p11 + Vector3(0, -0.38, 0), 0.04, 0.14, MB.tag(Color("1a1a1a"), MB.HAIR), Vector3(PI, 0, 0), 6)
			_mi(orbit2, ob2)
			rig["orbit"] = orbit2
			# ink dripping from the pages into a pool
			var drip := MB.new()
			drip.disc(Vector3(0, 0.03, 0), 1.1, Color(col.r * 0.4, col.g * 0.4, col.b * 0.4, 0.7), 24, Color(0, 0, 0, 0.0))
			for i in 5:
				drip.ribbon([Vector3(-0.8 + i * 0.4, 1.3, 0.2), Vector3(-0.8 + i * 0.4, 0.6, 0.2), Vector3(-0.8 + i * 0.4, 0.1, 0.2)], [0.02, 0.015, 0.0], Vector3.RIGHT, Color(col.r, col.g, col.b, 0.6))
			_mi(root, drip, MB.mat_glow())
		_:
			b.ball(Vector3(0, 0.8, 0), 0.6, col)
			root = _node(b, g)
	root.set_meta("wings", wings)
	root.set_meta("rig", rig)
	root.set_meta("kind", "monster")
	root.set_meta("shape", shape)
	if boss:
		_boss_halo(root, col)
	return root

## Boss aura (a fresnel halo) and a rotating rune circle on the ground.
static func _boss_halo(root: Node3D, col: Color) -> void:
	var ring := _pivot(root, Vector3(0, 0.06, 0))
	var rb := MB.new()
	rb.arc(Vector3.ZERO, 1.5, 0.06, 0.0, TAU, Color(col.r, col.g, col.b, 0.85), 48)
	rb.arc(Vector3.ZERO, 1.9, 0.03, 0.0, TAU, Color(1, 1, 1, 0.45), 48)
	rb.arc(Vector3.ZERO, 1.2, 0.025, 0.0, TAU, Color(col.r, col.g, col.b, 0.5), 40)
	# rune glyphs between the circles
	for i in 12:
		var a := TAU * i / 12.0
		var p := Vector3(cos(a) * 1.7, 0, sin(a) * 1.7)
		rb.box(p, Vector3(0.14, 0.01, 0.03), Color(1, 1, 1, 0.75), Vector3(0, -a, 0))
		rb.box(p + Vector3(cos(a), 0, sin(a)) * 0.05, Vector3(0.03, 0.01, 0.12), Color(col.r, col.g, col.b, 0.75), Vector3(0, -a, 0))
	# a six-pointed star inside
	for k in 2:
		for i in 3:
			var a0 := TAU * i / 3.0 + k * PI / 3.0
			var a1 := a0 + TAU / 3.0
			var p0 := Vector3(cos(a0), 0, sin(a0)) * 1.2
			var p1 := Vector3(cos(a1), 0, sin(a1)) * 1.2
			rb.ribbon([p0, p1], [0.02, 0.02], Vector3.UP.cross(p1 - p0).normalized(), Color(col.r, col.g, col.b, 0.5))
	_mi(ring, rb, MB.mat_glow())
	root.set_meta("ring", ring)

static func anim_monster(n: Node3D, t: float, phase: float = 0.0) -> void:
	if n.get_meta("kind", "") == "person":
		anim_person(n, t + phase, false)
		if n.has_meta("ring"):
			n.get_meta("ring").rotation.y = t * 0.9
		return
	if n.has_meta("glb"):
		Assets.animate(n, t, "idle", phase * 0.37)
		if n.has_meta("ring"):
			n.get_meta("ring").rotation.y = t * 0.9
		return
	var ws: Array = n.get_meta("wings", [])
	var tt := t + phase
	var a := _act_k(n, t)
	var atk: float = sin(a[1] * PI) if a[0] == "attack" else 0.0
	var hurt: float = sin(a[1] * PI) if a[0] == "hurt" else 0.0
	if not ws.is_empty():
		var f := sin(tt * 5.0) * 0.55 + atk * 0.4
		ws[0].rotation.z = -f
		ws[1].rotation.z = f
		var o0: Node3D = ws[0].get_meta("outer")
		var o1: Node3D = ws[1].get_meta("outer")
		var lagf := sin(tt * 5.0 - 0.9) * 0.4
		o0.rotation.z = -lagf
		o1.rotation.z = lagf
	if n.has_meta("ring"):
		n.get_meta("ring").rotation.y = t * 0.9
	var rig: Dictionary = n.get_meta("rig", {})
	var shape: String = n.get_meta("shape", "")
	match shape:
		"beast":
			var legs: Array = rig.get("legs", [])
			for i in legs.size():
				var ph := tt * 6.0 + (PI if i == 1 or i == 2 else 0.0)
				legs[i][0].rotation.x = sin(ph) * 0.18
				legs[i][1].rotation.x = maxf(0.0, cos(ph)) * 0.25
			_wave(rig.get("tail", []), tt, 3.0, 0.25, 0.3)
			var hd: Node3D = rig.get("head")
			hd.rotation.x = sin(tt * 1.5) * 0.06 - atk * 0.3
			rig["jaw"].rotation.x = 0.05 + absf(sin(tt * 0.7)) * 0.08 + atk * 0.6
		"wisp":
			var fl: Node3D = rig.get("flame")
			fl.rotation.y = tt * 1.5
			fl.scale = Vector3(1.0, 1.0 + sin(tt * 7.0) * 0.12 + atk * 0.4, 1.0)
		"blob":
			var sq := sin(tt * 3.0) * 0.06 + atk * 0.2 - hurt * 0.15
			n.get_child(0).scale = Vector3(1.0 + sq, 1.0 - sq, 1.0 + sq)
			var fc: Node3D = rig.get("face")
			fc.scale.y = 0.12 if fmod(tt, 4.1) < 0.12 else 1.0
		"wraith":
			var hem: Array = rig.get("hem", [])
			for i in hem.size():
				hem[i].rotation.x = -0.2 - sin(tt * 4.0 + i * 0.9) * 0.3
			var arms: Array = rig.get("arms", [])
			for i in arms.size():
				arms[i].rotation.x = sin(tt * 1.4 + i) * 0.15 - atk * 0.9
		"plant":
			for vi in rig.get("vines", []).size():
				_wave(rig.vines[vi], tt + vi * 0.7, 2.0, 0.22, 0.15 + atk * 0.4)
			var hd2: Node3D = rig.get("head")
			hd2.rotation = Vector3(sin(tt * 1.1) * 0.12 - atk * 0.5, sin(tt * 0.8) * 0.2, 0)
		"dragon":
			var segs: Array = rig.get("segs", [])
			for i in segs.size():
				segs[i].rotation = Vector3(sin(tt * 2.0 - i * 0.55) * 0.09, sin(tt * 1.6 - i * 0.5) * 0.16, 0)
			rig["head"].rotation.x = -0.15 - atk * 0.3
			rig["jaw"].rotation.x = 0.1 + absf(sin(tt * 0.9)) * 0.1 + atk * 0.7
		"bird", "phoenix":
			if rig.has("head"):
				rig["head"].rotation.x = sin(tt * 2.2) * 0.12 - atk * 0.4
			if rig.has("tail_p"):
				rig["tail_p"].rotation.x = sin(tt * 2.5) * 0.1
		"ray":
			_wave(rig.get("tail", []), tt, 3.5, 0.3, 0.2)
		"storm":
			var cl: Node3D = rig.get("cloud")
			cl.rotation.y = tt * 0.4
			cl.scale = Vector3.ONE * (1.0 + sin(tt * 2.0) * 0.04 + atk * 0.15)
			var bolts: Array = rig.get("bolts", [])
			for i in bolts.size():
				bolts[i].visible = fmod(tt * 3.0 + i * 1.3, 2.0) < 0.6 or atk > 0.1
		"golem":
			var garms: Array = rig.get("arms", [])
			for i in garms.size():
				garms[i].rotation.x = sin(tt * 1.2 + i * PI) * 0.12 - atk * 1.3
			rig["orbit"].rotation.y = tt * 0.8
		"serpent":
			var neck: Array = rig.get("neck", [])
			for i in neck.size():
				neck[i].rotation = Vector3(sin(tt * 1.8 - i * 0.6) * 0.1 + atk * 0.25, sin(tt * 1.2 - i * 0.4) * 0.15, 0)
			rig["tongue"].scale.z = 1.0 if fmod(tt, 1.7) < 0.35 else 0.05
		"crab":
			var claws: Array = rig.get("claws", [])
			for i in claws.size():
				claws[i][0].rotation.x = sin(tt * 1.5 + i) * 0.1 - atk * 0.6
				claws[i][1].rotation.x = -absf(sin(tt * 3.0 + i * 1.3)) * 0.4 - atk * 0.4
			var cl6: Array = rig.get("legs6", [])
			for i in cl6.size():
				cl6[i].rotation.z = sin(tt * 6.0 + i * 1.1) * 0.12
		"spider":
			var l8: Array = rig.get("legs8", [])
			for i in l8.size():
				l8[i].rotation.x = sin(tt * 5.0 + i * 1.6) * 0.12
				l8[i].rotation.z = cos(tt * 5.0 + i * 1.6) * 0.06
		"mantis":
			var sc: Array = rig.get("scythes", [])
			for i in sc.size():
				sc[i][0].rotation.x = sin(tt * 1.3 + i) * 0.08 - atk * 0.9
				sc[i][1].rotation.x = -0.4 + sin(tt * 1.6 + i) * 0.1 + atk * 1.2
			rig["head"].rotation.y = sin(tt * 0.9) * 0.35
		"tortoise":
			var tl: Array = rig.get("legs", [])
			for i in tl.size():
				tl[i].rotation.x = sin(tt * 1.5 + (PI if i == 1 or i == 2 else 0.0)) * 0.12
			rig["head"].rotation = Vector3(sin(tt * 0.8) * 0.1 - atk * 0.3, sin(tt * 0.5) * 0.25, 0)
		"tome":
			var cv: Array = rig.get("covers", [])
			var open_a := 0.35 + sin(tt * 1.2) * 0.08 + atk * 0.3
			cv[0].rotation.z = -open_a
			cv[1].rotation.z = open_a
			var pg: Array = rig.get("pages", [])
			for i in pg.size():
				# pages flip from one side to the other, each a little behind the last
				var f := fmod(tt * 0.6 + i / float(pg.size()), 1.0)
				pg[i].rotation.z = lerpf(open_a, PI - open_a, smoothstep(0.0, 1.0, f))
			rig["orbit"].rotation.y = tt * 0.7
		"jelly":
			var bell: Node3D = rig.get("bell")
			var pul := sin(tt * 2.6)
			bell.scale = Vector3(1.0 + pul * 0.07, 1.0 - pul * 0.06, 1.0 + pul * 0.07)
			for i in rig.get("tents", []).size():
				_wave(rig.tents[i], tt + i * 0.5, 2.6, 0.25, 0.1)
	if hurt > 0.0:
		n.rotation.x = -hurt * 0.25

## travelling sine wave down a pivot chain
static func _wave(chain: Array, t: float, speed: float, amp: float, curl: float) -> void:
	for i in chain.size():
		var p: Node3D = chain[i]
		p.rotation = Vector3(sin(t * speed - i * 0.7) * amp * 0.5 + curl * 0.15, sin(t * speed * 0.8 - i * 0.6) * amp, 0)

static func _humanoid_monster(shape: String, col: Color, boss: bool) -> Node3D:
	var n: Node3D
	match shape:
		"hero":
			n = person(Color("3a8ae8"), Color("1a1a2a"), {"asset": "lin_feng", "sword": true, "glow": Color(0.4, 0.7, 1.0), "hair": "topknot", "trim": Color("e8f0ff")})
		"healer":
			n = person(Color("e86a9a"), Color("402030"), {"asset": "yue_ling", "ribbon": Color("ffb0cc"), "glow": Color(1.0, 0.6, 0.8), "hair": "long", "eyes": Color("c04080")})
		"demon":
			n = person(col.darkened(0.45), Color("200010"), {"horns": true, "red_eyes": true, "sword": true, "glow": col, "scale": 1.35, "hair": "wild", "armor": true, "metal": Color("4a3a48"), "cape": col.darkened(0.2)})
		_:
			n = person(col, col.darkened(0.5), {"sword": true, "armor": boss, "hair": "bun", "trim": col.lightened(0.5)})
	n.set_meta("kind", "person")
	if boss:
		_boss_halo(n, col)
	return n
