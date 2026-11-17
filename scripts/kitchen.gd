class_name Kitchen
extends RefCounted
## The Small Fish release: what cooking looks like (cooking.gd is what it is).  Everything here is
## built from code and **drawn only**: a ring of three stones, the sticks laid on them, flames that
## stand as high as the fire burns, the iron pot, the water in it (which rises as it is poured, takes the
## colour of the broth as it is done, and dishes in the middle as it is stirred), what floats in it
## (which goes round with the water and, as tea leaves do, gathers at the middle), the lid (which lies
## by the fire, or sits on the pot and hops when the steam under it weighs more than it does), the
## board and the knife, the pieces that are cut on it and thrown one by one into the pot along the arc a
## thrown thing takes, and two bowls.  `tick` moves all of it from the state of the pot.

const IRON := Color("2a2c30")
const ASH := Color("5a544c")
const RIM_Y := 0.6
const WATER_Y0 := 0.3

## the colour of a piece of each good, on the board and in the pot
const PIECE := {"carp": Color("c8b8a8"), "herb_bundle": Color("5a9a4a"), "mushrooms": Color("8a6a48"), "wild_yam": Color("d8c090")}

# ---------------------------------------------------------------- what is held
## What is in the hand for a stage of cooking or for the new works of the hands (null if not ours).
## Drawn along +Z from the grip, as everything held is (props.gd).
static func held(what: String) -> Node3D:
	if not what in ["flint", "fan_leaf", "gourd", "kitchen_knife", "bowl", "trug", "spade"]:
		return null
	var root := Node3D.new()
	var b := MB.new()
	var wood := MB.tag(Color("a87a4a"), MB.WOOD)
	var iron := MB.tag(Color("5a5e66"), MB.METAL)
	match what:
		"flint":
			b.box(Vector3(0, -0.08, 0.05), Vector3(0.035, 0.03, 0.06), MB.tag(Color("3a3a40"), MB.STONE), Vector3(0.2, 0.3, 0))
		"fan_leaf":
			# a palm-leaf fan: a short handle and a round leaf with its ribs
			b.limb(Vector3(0, -0.08, -0.02), Vector3(0, -0.08, 0.14), 0.011, 0.009, wood, 6)
			b.disc(Vector3(0, -0.08, 0.3), 0.17, MB.tag(Color("c8b46a"), MB.CLOTH), 12, MB.tag(Color("a8904a"), MB.CLOTH), Vector3(0, 0, PI / 2.0))
			for i in 5:
				var a := (float(i) - 2.0) * 0.32
				b.limb(Vector3(0, -0.08, 0.14), Vector3(0, -0.08 + sin(a) * 0.16, 0.3 + cos(a) * 0.16), 0.004, 0.003, wood, 4)
		"gourd":
			b.sph(Vector3(0, -0.08, 0.12), Vector3(0.075, 0.075, 0.085), MB.tag(Color("c8a060"), MB.WOOD))
			b.sph(Vector3(0, -0.08, 0.24), Vector3(0.05, 0.05, 0.055), MB.tag(Color("c8a060"), MB.WOOD))
			b.cyl(Vector3(0, -0.08, 0.31), 0.014, 0.04, wood, Vector3(PI / 2.0, 0, 0), 6)
		"kitchen_knife":
			b.limb(Vector3(0, -0.08, -0.03), Vector3(0, -0.08, 0.08), 0.014, 0.013, wood, 6)
			b.box(Vector3(0, -0.11, 0.2), Vector3(0.006, 0.09, 0.2), MB.tag(Color("c8ccd4"), MB.METAL))
		"bowl":
			b.lathe(Vector3(0, -0.1, 0.1), [Vector2(0.03, 0.0), Vector2(0.075, 0.04), Vector2(0.085, 0.07), Vector2(0.075, 0.065), Vector2(0.03, 0.02)], MB.tag(Color("e8e0d0"), MB.STONE), 10)
		"trug":
			# a shallow basket of split willow with a hooped handle
			b.lathe(Vector3(0, -0.3, 0.02), [Vector2(0.1, 0.0), Vector2(0.17, 0.05), Vector2(0.19, 0.1), Vector2(0.175, 0.1), Vector2(0.1, 0.02)], MB.tag(Color("b89a5a"), MB.WOOD), 10, Color(0, 0, 0, -1), Vector2(1.0, 0.75))
			for i in 8:
				var a0 := PI * float(i) / 8.0
				var a1 := PI * float(i + 1) / 8.0
				b.limb(Vector3(-cos(a0) * 0.18, -0.2 + sin(a0) * 0.12, 0.02), Vector3(-cos(a1) * 0.18, -0.2 + sin(a1) * 0.12, 0.02), 0.008, 0.008, wood, 5)
			b.sph(Vector3(0.04, -0.22, 0.03), Vector3(0.05, 0.03, 0.05), MB.tag(PIECE.mushrooms, MB.FOLIAGE))
			b.sph(Vector3(-0.06, -0.22, 0.0), Vector3(0.04, 0.025, 0.04), MB.tag(PIECE.mushrooms.lightened(0.2), MB.FOLIAGE))
		"spade":
			b.limb(Vector3(0, -0.08, -0.35), Vector3(0, -0.08, 0.5), 0.017, 0.015, wood, 6)
			b.box(Vector3(0, -0.08, -0.37), Vector3(0.1, 0.02, 0.03), wood)
			b.box(Vector3(0, -0.08, 0.62), Vector3(0.085, 0.012, 0.24), iron)
	MB.mesh_node(root, b.build(MB.mat_plain()))
	return root

# ---------------------------------------------------------------- the fire and the pot
## The whole of it, standing at the origin (the middle of the free tile in front of him), with the cook
## to the side of -`toward`.  Children by name: `logs`, `flames`, `embers`, `light`, `pot`, `water`,
## `swirl` (what floats), `lid`, `board`, `bowls`.  `needs`: what the dish is made of.
static func kit(needs: Dictionary, toward: Vector3, broth: Color) -> Node3D:
	var root := Node3D.new()
	root.set_meta("broth", broth)
	root.set_meta("toward", toward)
	var side := Vector3(toward.z, 0, -toward.x)
	var stone := MB.tag(Color("7a766e"), MB.STONE)
	var b := MB.new()
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		b.sph(Vector3(cos(a) * 0.3, 0.1, sin(a) * 0.3), Vector3(0.13, 0.11, 0.11), stone, Vector3(0, a, 0.2))
	b.disc(Vector3(0, 0.012, 0), 0.42, MB.tag(ASH.darkened(0.3), MB.STONE), 12, MB.tag(ASH, MB.STONE))
	MB.mesh_node(root, b.build(MB.mat_plain()))
	# the sticks
	var lb := MB.new()
	for i in 6:
		var a2 := TAU * float(i) / 6.0
		lb.limb(Vector3(cos(a2) * 0.3, 0.03, sin(a2) * 0.3), Vector3(-cos(a2) * 0.05, 0.13, -sin(a2) * 0.05), 0.028, 0.022, MB.tag(Color("6a4a2a").lightened(0.1 * float(i % 2)), MB.WOOD), 5)
	var logs := MB.mesh_node(root, lb.build(MB.mat_plain()))
	logs.name = "logs"
	logs.visible = false
	# the flames: three tongues, scaled by the fire
	var fb := MB.new()
	for i in 5:
		var a3 := TAU * float(i) / 5.0
		var rr := 0.1 if i > 0 else 0.0
		fb.cone(Vector3(cos(a3) * rr, 0.22, sin(a3) * rr), 0.08, 0.32, Color(1.0, 0.55 + 0.1 * float(i % 2), 0.15, 0.75), Vector3.ZERO, 6)
		fb.cone(Vector3(cos(a3) * rr, 0.18, sin(a3) * rr), 0.045, 0.2, Color(1.0, 0.9, 0.5, 0.8), Vector3.ZERO, 5)
	var flames := MB.mesh_node(root, fb.build(MB.mat_glow()))
	flames.name = "flames"
	flames.scale = Vector3(1, 0.001, 1)
	var eb := MB.new()
	eb.disc(Vector3(0, 0.03, 0), 0.24, Color(1.0, 0.35, 0.08, 0.7), 10, Color(0.8, 0.15, 0.02, 0.0))
	var embers := MB.mesh_node(root, eb.build(MB.mat_glow()))
	embers.name = "embers"
	embers.visible = false
	var light := OmniLight3D.new()
	light.name = "light"
	light.light_color = Color(1.0, 0.6, 0.3)
	light.omni_range = 5.0
	light.light_energy = 0.0
	light.position = Vector3(0, 0.5, 0)
	root.add_child(light)
	# the pot: round-bellied, three stub feet, a bail
	var pot := Node3D.new()
	pot.name = "pot"
	pot.visible = false
	root.add_child(pot)
	var pb := MB.new()
	var iron := MB.tag(IRON, MB.METAL)
	pb.lathe(Vector3(0, 0.22, 0), [Vector2(0.1, 0.0), Vector2(0.24, 0.07), Vector2(0.3, 0.2), Vector2(0.29, 0.32), Vector2(0.27, 0.38), Vector2(0.255, 0.38), Vector2(0.27, 0.3), Vector2(0.27, 0.2), Vector2(0.2, 0.08), Vector2(0.05, 0.05)], iron, 16)
	for i in 3:
		var a4 := TAU * float(i) / 3.0 + 0.5
		pb.cyl(Vector3(cos(a4) * 0.2, 0.2, sin(a4) * 0.2), 0.025, 0.08, iron, Vector3.ZERO, 6)
	for sx in [-1.0, 1.0]:
		pb.torus(Vector3(sx * 0.29, 0.56, 0), 0.03, 0.008, iron, Vector3(PI / 2.0, 0, 0))
	MB.mesh_node(pot, pb.build(MB.mat_plain()))
	var wb := MB.new()
	wb.disc(Vector3.ZERO, 0.265, Color(1, 1, 1), 16, Color(0.82, 0.82, 0.82))
	var water := MB.mesh_node(pot, wb.build(_tint_mat(Color("6a8a9a"))))
	water.name = "water"
	water.visible = false
	# the dish of a turning pot: a darker middle that sinks
	var db := MB.new()
	db.disc(Vector3.ZERO, 0.14, Color(0.7, 0.7, 0.7), 12, Color(1, 1, 1))
	var dish := MB.mesh_node(water, db.build(_tint_mat(Color("6a8a9a"))))
	dish.name = "dish"
	# what floats: one piece for each thing that went in
	var swirl := Node3D.new()
	swirl.name = "swirl"
	swirl.visible = false
	water.add_child(swirl)
	var k := 0
	for good in needs:
		for _n in int(needs[good]):
			var mb := MB.new()
			var col: Color = PIECE.get(str(good), Color("b0a080"))
			if str(good) == "carp":
				# the fish, whole: a body, a tail, an eye
				mb.sph(Vector3.ZERO, Vector3(0.15, 0.03, 0.05), MB.tag(col, MB.SCALE))
				mb.box(Vector3(-0.17, 0, 0), Vector3(0.06, 0.012, 0.08), MB.tag(col.darkened(0.2), MB.SCALE), Vector3(0, 0.0, 0))
				mb.ball(Vector3(0.1, 0.025, 0.02), 0.008, MB.tag(Color("1a1a1a"), MB.STONE), true)
			else:
				mb.box(Vector3.ZERO, Vector3(0.05, 0.03, 0.04), MB.tag(col, MB.FOLIAGE), Vector3(0.3, float(k), 0.2))
			var pn := MB.mesh_node(swirl, mb.build(MB.mat_plain()))
			pn.set_meta("good", str(good))
			pn.set_meta("a", TAU * float(k) / 5.0 + 0.7)
			pn.set_meta("r", 0.0 if str(good) == "carp" else 0.12 + 0.03 * float(k % 3))
			pn.visible = false
			k += 1
	# the lid, with a knob
	var lid := Node3D.new()
	lid.name = "lid"
	lid.visible = false
	root.add_child(lid)
	var ldb := MB.new()
	ldb.lathe(Vector3.ZERO, [Vector2(0.28, 0.0), Vector2(0.2, 0.035), Vector2(0.05, 0.05), Vector2(0.0, 0.05)], iron, 14)
	ldb.ball(Vector3(0, 0.075, 0), 0.03, iron, true)
	MB.mesh_node(lid, ldb.build(MB.mat_plain()))
	# the board, beside the cook, and what is cut on it
	var board := Node3D.new()
	board.name = "board"
	board.visible = false
	board.position = -toward * 0.62 + side * 0.42
	board.rotation.y = atan2(toward.x, toward.z)
	root.add_child(board)
	var bb := MB.new()
	bb.box(Vector3(0, 0.05, 0), Vector3(0.44, 0.035, 0.28), MB.tag(Color("b89464"), MB.WOOD))
	bb.box(Vector3(0, 0.02, 0), Vector3(0.3, 0.04, 0.2), MB.tag(Color("7a766e"), MB.STONE))
	MB.mesh_node(board, bb.build(MB.mat_plain()))
	var j := 0
	for good2 in needs:
		for _n2 in int(needs[good2]):
			var cb := MB.new()
			var c2: Color = PIECE.get(str(good2), Color("b0a080"))
			if str(good2) == "carp":
				cb.sph(Vector3.ZERO, Vector3(0.15, 0.03, 0.05), MB.tag(c2, MB.SCALE))
				cb.box(Vector3(-0.17, 0, 0), Vector3(0.06, 0.012, 0.08), MB.tag(c2.darkened(0.2), MB.SCALE))
			else:
				for q in 3:
					cb.box(Vector3(0.045 * float(q - 1), 0, 0), Vector3(0.035, 0.03, 0.05), MB.tag(c2.lightened(0.08 * float(q)), MB.FOLIAGE), Vector3(0, 0.3 * float(q), 0))
			var cn := MB.mesh_node(board, cb.build(MB.mat_plain()), Vector3(-0.14 + 0.1 * float(j % 4), 0.085, -0.06 + 0.1 * float(j / 4)))
			cn.name = "cut%d" % j
			cn.set_meta("home", cn.position)
			j += 1
	board.set_meta("n", j)
	# two bowls, on the side away from the board
	var bowls := Node3D.new()
	bowls.name = "bowls"
	bowls.visible = false
	bowls.position = -toward * 0.55 - side * 0.45
	root.add_child(bowls)
	var wlb := MB.new()
	for i in 2:
		wlb.lathe(Vector3(0.2 * float(i), 0.0, 0.05 * float(i)), [Vector2(0.03, 0.0), Vector2(0.075, 0.04), Vector2(0.085, 0.07), Vector2(0.075, 0.065), Vector2(0.03, 0.02)], MB.tag(Color("e8e0d0"), MB.STONE), 10)
	MB.mesh_node(bowls, wlb.build(MB.mat_plain()))
	var sb := MB.new()
	for i in 2:
		sb.disc(Vector3(0.2 * float(i), 0.055, 0.05 * float(i)), 0.07, Color(1, 1, 1), 10)
	var soup := MB.mesh_node(bowls, sb.build(_tint_mat(broth)))
	soup.name = "soup"
	soup.visible = false
	return root

static func _tint_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = col
	m.roughness = 0.25
	m.metallic = 0.1
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

## Where a thing thrown from `a` so as to come down at `b` after `secs` is at time `u` (0..1 of the
## flight): the arc a thrown thing takes, under the gravity of cooking.gd.
static func lob(a: Vector3, b: Vector3, secs: float, u: float) -> Vector3:
	var tt := clampf(u, 0.0, 1.0) * secs
	var v0 := (b - a) / secs - Vector3(0, -Cooking.G, 0) * secs * 0.5
	return a + v0 * tt + Vector3(0, -Cooking.G, 0) * tt * tt * 0.5

## Move everything to the state of the pot `s`, `el` seconds into stage `k`, at world time `t`.
## Returns what happened this frame that wants an effect: {"splash": Vector3 or null, "hop": bool,
## "steam": 0..1, "smoke": bool}.
static func tick(root: Node3D, s: Dictionary, k: int, el: float, t: float, d: float) -> Dictionary:
	var out := {"splash": null, "hop": false, "steam": float(s.steam), "smoke": false}
	var st: Dictionary = Cooking.STAGES[k]
	var id := str(st.id)
	var toward: Vector3 = root.get_meta("toward")
	var broth: Color = root.get_meta("broth")
	var logs: Node3D = root.get_node("logs")
	var flames: Node3D = root.get_node("flames")
	var pot: Node3D = root.get_node("pot")
	var water: MeshInstance3D = pot.get_node("water")
	var swirl: Node3D = water.get_node("swirl")
	var lid: Node3D = root.get_node("lid")
	var board: Node3D = root.get_node("board")
	var bowls: Node3D = root.get_node("bowls")
	# the sticks are laid over the first stage, the pot set on them when the fire will go by itself
	logs.visible = k > 0 or el > 0.8
	pot.visible = k >= 2
	# the flames stand as high as the fire burns, and never quite still
	var f := float(s.fire)
	var fl := 0.86 + 0.14 * sin(t * 17.0) * sin(t * 7.3)
	flames.scale = Vector3(0.6 + 0.5 * f, maxf(0.001, f * fl * (0.9 if pot.visible else 1.3)), 0.6 + 0.5 * f)
	flames.rotation.y = t * 0.7
	(root.get_node("embers") as Node3D).visible = f > 0.03
	(root.get_node("light") as OmniLight3D).light_energy = f * (1.6 + 0.4 * sin(t * 23.0))
	out.smoke = f > 0.05 and f < 0.5
	# the water: its level, the broth coming into it as it is done, the dish of a turning pot
	var lvl := float(s.water)
	water.visible = lvl > 0.0
	if id == "water":
		lvl *= clampf((el - 0.6) / 1.8, 0.0, 1.0)
		water.visible = lvl > 0.0
	water.position.y = WATER_Y0 + 0.24 * lvl + (0.004 * sin(t * 31.0) if float(s.T) >= 99.0 else 0.0)
	var done := clampf(float(s.done), 0.0, 1.0)
	var wm: StandardMaterial3D = water.get_surface_override_material(0) if water.get_surface_override_material(0) != null else water.mesh.surface_get_material(0)
	wm.albedo_color = Color("6a8a9a").lerp(broth, done)
	var dish: MeshInstance3D = water.get_node("dish")
	var dp := Cooking.dish(float(s.spin))
	dish.position.y = -minf(0.08, dp * 6.0) + 0.002
	dish.scale = Vector3.ONE * (0.4 + clampf(absf(float(s.spin)) / 5.0, 0.0, 1.0))
	(dish.mesh.surface_get_material(0) as StandardMaterial3D).albedo_color = wm.albedo_color.darkened(0.25)
	# what floats goes round with the water and gathers at the middle as it turns
	swirl.rotation.y = -float(s.turn)
	var gather := 1.0 - 0.6 * clampf(absf(float(s.spin)) / 5.0, 0.0, 1.0)
	var n_in := 0
	var total := swirl.get_child_count()
	if k > 5:
		n_in = total
	elif id == "add":
		n_in = int(clampf((el - 0.5) / maxf(0.1, float(st.dur) - 1.0), 0.0, 1.0) * float(total) + 0.001)
	swirl.visible = n_in > 0
	for i in total:
		var pn: Node3D = swirl.get_child(i)
		var was := pn.visible
		pn.visible = i < n_in
		if pn.visible and not was and id == "add":
			out.splash = root.to_global(Vector3(0, water.position.y + 0.22, 0))
		var a := float(pn.get_meta("a"))
		var r := float(pn.get_meta("r")) * gather
		var bob := 0.006 * sin(t * (9.0 if float(s.T) >= 99.0 else 2.0) + a * 3.0)
		pn.position = Vector3(cos(a) * r, 0.012 + bob, sin(a) * r)
		pn.rotation.y = a * 2.0 + float(s.turn) * 0.3
	# the pieces on the board: there from the cutting, thrown one by one at "add"
	board.visible = k >= 4 and k <= 5
	var nb := int(board.get_meta("n"))
	for i in nb:
		var cn: Node3D = board.get_node("cut%d" % i)
		var home: Vector3 = cn.get_meta("home")
		cn.visible = true
		cn.position = home
		if id == "chop":
			# each is cut in its turn: whole until the knife has been to it
			cn.scale = Vector3.ONE * (1.0 if el > 0.5 + float(i) * 0.6 else 1.25)
		elif id == "add":
			var slot := maxf(0.1, float(st.dur) - 1.0) / float(maxi(1, nb))
			var u := (el - 0.5 - float(i) * slot + 0.5) / 0.5
			if u >= 1.0:
				cn.visible = false
			elif u > 0.0:
				var target := board.to_local(root.to_global(Vector3(0, WATER_Y0 + 0.5, 0)))
				cn.position = lob(home, target, 0.5, u)
				cn.rotation = Vector3(u * 5.0, u * 3.0, 0)
	# the lid: by the fire, or on the pot, hopping
	lid.visible = k >= 2 and k < 10
	if bool(st.lid) and pot.visible:
		var ly := float(s.lid_y)
		lid.position = Vector3(0, RIM_Y + ly, 0)
		lid.rotation = Vector3(ly * 4.0, 0, ly * 2.5 * sin(t * 40.0))
		if ly > 0.004:
			out.hop = true
	else:
		var sd := Vector3(toward.z, 0, -toward.x)
		lid.position = lid.position.lerp(-sd * 0.62 + Vector3(0, 0.03, 0), 1.0 - exp(-d * 8.0))
		lid.rotation = lid.rotation.lerp(Vector3(0.12, 0, 0), 1.0 - exp(-d * 8.0))
	# the bowls
	bowls.visible = k >= 10
	(bowls.get_node("soup") as Node3D).visible = (k == 10 and el > 1.4) or (k == 11 and el < float(st.dur) * 0.75)
	return out
