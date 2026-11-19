class_name Wagons
extends RefCounted
## What is drawn on the roads (the Rivers and Lakes release): the vehicles of traffic.gd and the raids of
## raids.gd, all built from code.  Every vehicle faces +Z with its origin on the ground under its middle.
## `build` gives a vehicle with its crew aboard (meta "crew": [[node, seat, clip]]), its wheels (meta
## "wheels": nodes with meta "r") and whatever draws it (meta "anims": the Blender ox and horse);
## `animate` turns the wheels with the road, walks the team and seats or walks the crew.  Three of the
## ten kinds are the carriages he can buy (models.gd `ride`), driven by somebody else.

## The model of vehicle `kind`, crewed.  `seed` chooses its colours.
static func build(kind: String, seed: int = 0) -> Node3D:
	var kd: Dictionary = Traffic.KINDS[kind]
	var root: Node3D
	if kd.has("ride"):
		root = Models.ride(str(kd.ride))
	else:
		root = Node3D.new()
		_body(root, kind, seed)
	root.set_meta("vehicle", kind)
	var crew: Array = []
	for c in kd.get("crew", []):
		var pn: Node3D = Assets.person(str(c[0])) if Assets.PEOPLE.has(str(c[0])) and Assets.has(Assets.PEOPLE[str(c[0])]) else Models.person(Color("8a7a6a"), Color("2a2a3a"), {})
		Assets.lend_clips(pn)
		root.add_child(pn)
		var seat: Vector3 = c[1]
		pn.position = seat - (Vector3(0, 0.46, 0) if str(c[2]) == "sit_bench" else Vector3.ZERO)
		crew.append([pn, seat, str(c[2])])
	root.set_meta("crew", crew)
	return root

## Move vehicle `n`: `clk` its own clock, `moving` whether it is under way.
static func animate(n: Node3D, clk: float, moving: bool) -> void:
	for wn in n.get_meta("wheels", []):
		if moving:
			(wn as Node3D).rotation.x = clk * 1.6 / maxf(0.2, float((wn as Node3D).get_meta("r", 0.5)))
	for hm in n.get_meta("anims", []):
		var gait := "walk" if Assets.has_clip(hm, "walk") else "idle"
		if str(n.get_meta("vehicle", "")) == "rider" and Assets.has_clip(hm, "run"):
			gait = "run"
		Assets.animate(hm, clk + float((hm as Node3D).position.z), gait if moving else "idle", 0.0)
	var k := 0
	for c in n.get_meta("crew", []):
		k += 1
		var pn: Node3D = c[0]
		if str(c[2]) == "sit_bench":
			Models.anim_person(pn, clk + k, false, false, "sit_bench")
		else:
			Models.anim_person(pn, clk + k * 0.37, moving)
	# (what is carried sways a little with the road)
	if n.has_meta("sway"):
		(n.get_meta("sway") as Node3D).rotation.z = sin(clk * 2.2) * 0.02 if moving else 0.0

static func _team(root: Node3D, kind: String, at: Array, coat: Color, acc: Color) -> void:
	var anims: Array = root.get_meta("anims", [])
	if Assets.has(Assets.MOUNTS.horse) and Assets.has(Assets.MOUNTS.ox):
		for p in at:
			var pal: Array = Assets.palette(coat, "", {"sec": coat.darkened(0.5) if kind == "horse" else acc, "acc": acc if kind == "horse" else Color("3a2416"), "mark": coat.darkened(0.3)})
			var hm := Assets.mount(kind, pal)
			hm.position = p
			root.add_child(hm)
			anims.append(hm)
	root.set_meta("anims", anims)

static func _wheels(root: Node3D, axles: Array, dark: Color, pale: Color, iron: Color) -> void:
	var wheels: Array = root.get_meta("wheels", [])
	for ax in axles:
		var wr := float(ax[1])
		var hw := float(ax[2])
		if hw > 0.0:
			var b := MB.new()
			b.limb(Vector3(-hw, wr, float(ax[0])), Vector3(hw, wr, float(ax[0])), 0.05, 0.05, iron, 6)
			Models._mi(root, b)
		for s in ([-1.0, 1.0] if hw > 0.0 else [0.0]):
			var wb := MB.new()
			Models._wheel_mb(wb, wr, 12 if wr > 0.7 else 8, dark, pale, iron, Vector3.ZERO, false)
			var wn := Models._mi(root, wb, null, Vector3(s * hw, wr, float(ax[0])))
			wn.set_meta("r", wr)
			wheels.append(wn)
	root.set_meta("wheels", wheels)

static func _body(root: Node3D, kind: String, seed: int) -> void:
	var b := MB.new()
	var wood := MB.tag(Color("8a6238"), MB.WOOD)
	var wood_d := MB.tag(Color("4e3422"), MB.WOOD)
	var wood_p := MB.tag(Color("a08660"), MB.WOOD)
	var iron := MB.tag(Color("3c3c44"), MB.METAL)
	var rope := MB.tag(Color("b8a070"), MB.CLOTH)
	var cloths := [Color("a83c30"), Color("3f5f96"), Color("5a8a4a"), Color("b8985a"), Color("7a4a8a")]
	var cloth := MB.tag(cloths[absi(seed) % cloths.size()], MB.CLOTH)
	match kind:
		"salt_wagon":
			# a long bed on four wheels, hooped and sheeted, sacks showing at the tail, a pole and two oxen
			b.box(Vector3(0, 1.0, -0.2), Vector3(1.7, 0.1, 3.9), wood)
			for s in [-1.0, 1.0]:
				b.box(Vector3(s * 0.84, 1.3, -0.2), Vector3(0.06, 0.5, 3.9), wood_d)
				for k in 5:
					b.limb(Vector3(s * 0.84, 1.05, -1.9 + k * 0.85), Vector3(s * 0.86, 1.58, -1.9 + k * 0.85), 0.035, 0.03, wood_p, 5)
			for k2 in 5:
				var z := -1.9 + k2 * 0.85
				for q in 6:
					var a0 := PI * q / 6.0
					var a1 := PI * (q + 1) / 6.0
					b.limb(Vector3(cos(a0) * 0.86, 1.55 + sin(a0) * 0.75, z), Vector3(cos(a1) * 0.86, 1.55 + sin(a1) * 0.75, z), 0.025, 0.025, wood_p, 4)
			Models._canopy(b, Vector3(0, 2.28, -0.2), 0.9, 2.0, 0.1, 0.0, MB.tag(Color("d8d0b8"), MB.CLOTH), MB.tag(Color("c0b89c"), MB.CLOTH), MB.tag(Color("8a8470"), MB.CLOTH))
			for k3 in 6:
				b.sph(Vector3(-0.5 + (k3 % 3) * 0.5, 1.22 + (k3 / 3) * 0.3, -1.95), Vector3(0.26, 0.19, 0.2), MB.tag(Color("e8e4d8") if k3 % 2 == 0 else Color("d0c8b0"), MB.CLOTH))
			b.box(Vector3(0, 1.5, 1.55), Vector3(1.5, 0.08, 0.45), wood_p)
			b.box(Vector3(0, 1.24, 1.42), Vector3(1.5, 0.5, 0.08), wood_d)
			b.limb(Vector3(0, 0.95, 1.7), Vector3(0, 1.0, 4.6), 0.06, 0.045, wood_d, 6)
			b.limb(Vector3(-0.95, 1.28, 4.2), Vector3(0.95, 1.28, 4.2), 0.05, 0.05, wood_d, 6)
			Models._mi(root, b)
			_wheels(root, [[1.2, 0.6, 1.02], [-1.5, 0.78, 1.02]], wood_d, wood_p, iron)
			_team(root, "ox", [Vector3(-0.5, 0, 3.6), Vector3(0.5, 0, 3.6)], Color("b4a290"), cloth)
		"barrow":
			# the one-wheeled barrow of the plains: a great wheel in the middle of a frame, a load each side
			# of it, two handles behind, and a mat sail on a mast to let the wind do half
			var sway := Node3D.new()
			root.add_child(sway)
			for s2 in [-1.0, 1.0]:
				b.limb(Vector3(s2 * 0.28, 0.72, -1.45), Vector3(s2 * 0.2, 0.6, 1.0), 0.035, 0.035, wood_d, 5)
				b.box(Vector3(s2 * 0.42, 0.7, 0.1), Vector3(0.36, 0.05, 1.3), wood)
				b.sph(Vector3(s2 * 0.44, 0.9, 0.3), Vector3(0.2, 0.2, 0.3), MB.tag(Color("c0a878"), MB.CLOTH))
				b.sph(Vector3(s2 * 0.44, 0.88, -0.25), Vector3(0.19, 0.18, 0.26), MB.tag(Color("b09868"), MB.CLOTH))
				b.limb(Vector3(s2 * 0.3, 0.72, -0.9), Vector3(s2 * 0.3, 0.02, -0.95), 0.03, 0.025, wood_d, 5)
			b.box(Vector3(0, 1.02, 0.1), Vector3(0.12, 0.05, 1.3), wood_d)
			b.limb(Vector3(0, 0.7, 0.75), Vector3(0, 2.7, 0.7), 0.03, 0.022, wood_p, 5)
			b.limb(Vector3(-0.55, 2.55, 0.7), Vector3(0.55, 2.55, 0.7), 0.02, 0.02, wood_p, 4)
			b.limb(Vector3(-0.5, 1.25, 0.7), Vector3(0.5, 1.25, 0.7), 0.02, 0.02, wood_p, 4)
			b.box(Vector3(0, 1.9, 0.72), Vector3(1.0, 1.26, 0.02), MB.tag(Color("c8b888"), MB.CLOTH))
			for k4 in 4:
				b.box(Vector3(0, 1.4 + k4 * 0.32, 0.735), Vector3(1.02, 0.02, 0.02), wood_d)
			Models._mi(sway, b)
			root.set_meta("sway", sway)
			_wheels(root, [[0.1, 0.5, 0.0]], wood_d, wood_p, iron)
		"handcart":
			# a pedlar's handcart: a shallow box on two small wheels, a rack of wares under an awning,
			# two shafts and a cross-bar to pull it by
			b.box(Vector3(0, 0.62, -0.1), Vector3(1.0, 0.08, 1.5), wood)
			for s3 in [-1.0, 1.0]:
				b.box(Vector3(s3 * 0.5, 0.78, -0.1), Vector3(0.04, 0.26, 1.5), wood_d)
				b.limb(Vector3(s3 * 0.42, 0.62, 0.6), Vector3(s3 * 0.36, 0.95, 1.6), 0.03, 0.025, wood_d, 5)
				for pz in [0.55, -0.75]:
					b.limb(Vector3(s3 * 0.48, 0.66, pz), Vector3(s3 * 0.48, 1.86, pz), 0.022, 0.02, wood_p, 4)
			b.limb(Vector3(-0.36, 0.95, 1.6), Vector3(0.36, 0.95, 1.6), 0.025, 0.025, wood_d, 5)
			b.box(Vector3(0, 0.78, -0.84), Vector3(1.0, 0.26, 0.04), wood_d)
			Models._canopy(b, Vector3(0, 1.86, -0.1), 0.62, 0.8, 0.08, 0.0, cloth, cloth.darkened(0.15), MB.tag(Color("e8dcc0"), MB.CLOTH))
			b.box(Vector3(0, 1.2, -0.1), Vector3(0.94, 0.03, 1.2), wood_p)
			for k5 in 8:
				var hx := -0.36 + (k5 % 4) * 0.24
				var hz := -0.4 + (k5 / 4) * 0.55
				b.lathe(Vector3(hx, 0.67, hz), [Vector2(0.05, 0.0), Vector2(0.08, 0.06), Vector2(0.07, 0.14), Vector2(0.04, 0.16)], MB.tag([Color("8a5a3a"), Color("5a7a8a"), Color("b8a060"), Color("7a3a30")][k5 % 4], MB.STONE), 8)
				b.limb(Vector3(hx, 1.84, hz), Vector3(hx, 1.6 - (k5 % 3) * 0.07, hz), 0.004, 0.004, rope, 3)
				b.sph(Vector3(hx, 1.56 - (k5 % 3) * 0.07, hz), Vector3(0.05, 0.05, 0.05), MB.tag([Color("c83a30"), Color("e8c040"), Color("3a8a6a")][k5 % 3], MB.CLOTH))
			Models._mi(root, b)
			_wheels(root, [[-0.2, 0.42, 0.56]], wood_d, wood_p, iron)
		"sedan":
			# a curtained chair on two long poles, carried between two bearers
			for s4 in [-1.0, 1.0]:
				b.limb(Vector3(s4 * 0.36, 0.98, -2.0), Vector3(s4 * 0.36, 0.98, 2.0), 0.03, 0.03, MB.tag(Color("7a2a22"), MB.WOOD), 6)
				for pz2 in [0.42, -0.42]:
					b.limb(Vector3(s4 * 0.36, 0.72, pz2), Vector3(s4 * 0.36, 2.0, pz2), 0.025, 0.025, wood_d, 5)
				b.box(Vector3(s4 * 0.365, 1.4, 0.0), Vector3(0.02, 0.9, 0.8), cloth)
			b.box(Vector3(0, 0.72, 0), Vector3(0.76, 0.05, 0.9), wood_d)
			b.box(Vector3(0, 1.0, -0.2), Vector3(0.7, 0.06, 0.45), MB.tag(Color("b8985a"), MB.CLOTH))
			b.box(Vector3(0, 1.4, -0.43), Vector3(0.74, 0.9, 0.02), cloth.darkened(0.1))
			b.box(Vector3(0, 1.62, 0.43), Vector3(0.74, 0.46, 0.02), cloth)
			Models._canopy(b, Vector3(0, 2.0, 0), 0.5, 0.58, 0.2, 0.08, MB.tag(Color("3a3a44"), MB.STONE), MB.tag(Color("2e2e38"), MB.STONE), MB.tag(Color("b8985a"), MB.METAL))
			b.lathe(Vector3(0, 2.2, 0), [Vector2(0.05, 0.0), Vector2(0.07, 0.05), Vector2(0.0, 0.14)], MB.tag(Color("b8985a"), MB.METAL), 8)
			for s5 in [-1.0, 1.0]:
				for cz in [0.5, -0.5]:
					b.cone(Vector3(s5 * 0.46, 1.86, cz), 0.03, 0.12, MB.tag(Color("c8322a"), MB.CLOTH))
			var sw := Node3D.new()
			root.add_child(sw)
			Models._mi(sw, b)
			root.set_meta("sway", sw)
		"packtrain":
			# three pack-horses nose to tail on a lead, each under a pair of panniers and a roll
			var at: Array = [Vector3(0, 0, 1.6), Vector3(0, 0, -0.6), Vector3(0, 0, -2.8)]
			for i in at.size():
				var c: Vector3 = at[i]
				for s6 in [-1.0, 1.0]:
					b.box(Vector3(s6 * 0.36, 1.12, c.z - 0.05), Vector3(0.26, 0.4, 0.62), MB.tag([Color("8a6a44"), Color("6a5a3a"), Color("9a7a50")][i], MB.WOOD))
					b.box(Vector3(s6 * 0.36, 1.33, c.z - 0.05), Vector3(0.28, 0.03, 0.64), wood_d)
				b.cyl(Vector3(0, 1.46, c.z - 0.05), 0.14, 0.7, cloth if i != 1 else MB.tag(Color("c8b888"), MB.CLOTH), Vector3(0, 0, PI / 2.0), 8)
				b.box(Vector3(0, 1.3, c.z - 0.05), Vector3(0.82, 0.03, 0.1), rope)
				if i > 0:
					b.limb(Vector3(0, 1.3, c.z + 0.95), Vector3(0, 1.22, c.z + 1.5), 0.008, 0.008, rope, 3)
			b.limb(Vector3(0, 1.3, 2.5), Vector3(0.45, 1.05, 2.65), 0.008, 0.008, rope, 3)
			Models._mi(root, b)
			_team(root, "horse", at, [Color("8a5a36"), Color("b08a5a"), Color("5a4a40")][absi(seed) % 3], Color("a83c30"))
		"rider":
			# a courier's horse: a satchel of the post behind the saddle and a pennon on a short staff
			b.box(Vector3(0, 1.3, -0.1), Vector3(0.5, 0.06, 0.6), MB.tag(Color("3f5f96"), MB.CLOTH))
			for s7 in [-1.0, 1.0]:
				b.box(Vector3(s7 * 0.3, 1.1, -0.45), Vector3(0.12, 0.3, 0.34), MB.tag(Color("6a4a30"), MB.WOOD))
				b.box(Vector3(s7 * 0.3, 1.24, -0.45), Vector3(0.13, 0.04, 0.36), MB.tag(Color("c8322a"), MB.CLOTH))
			b.limb(Vector3(0.22, 1.3, -0.62), Vector3(0.22, 2.5, -0.7), 0.014, 0.012, wood_d, 4)
			b.ribbon([Vector3(0.22, 2.44, -0.72), Vector3(0.22, 2.42, -1.0), Vector3(0.22, 2.46, -1.3)], [0.2, 0.18, 0.03], Vector3(0, 1, 0), MB.tag(Color("3f5f96"), MB.CLOTH))
			Models._mi(root, b)
			_team(root, "horse", [Vector3.ZERO], [Color("3a2a22"), Color("8a5a36"), Color("d8d0c0")][absi(seed) % 3], Color("3f5f96"))
		"banner_cart":
			# a sect's cart: a high two-wheeled car behind one horse, a drum at the tail, and the sect's
			# banner on a tall staff, long enough to be read from the next hill
			b.box(Vector3(0, 0.98, -0.1), Vector3(1.4, 0.08, 2.2), wood_d)
			for s8 in [-1.0, 1.0]:
				b.box(Vector3(s8 * 0.7, 1.3, -0.1), Vector3(0.05, 0.56, 2.2), MB.tag(Color("3a2a2a"), MB.WOOD))
				b.box(Vector3(s8 * 0.725, 1.3, -0.1), Vector3(0.01, 0.2, 1.9), cloth)
				b.limb(Vector3(s8 * 0.55, 0.92, 0.9), Vector3(s8 * 0.42, 1.0, 3.1), 0.05, 0.04, wood_d, 6)
			b.box(Vector3(0, 1.3, -1.2), Vector3(1.4, 0.56, 0.05), MB.tag(Color("3a2a2a"), MB.WOOD))
			b.box(Vector3(0, 1.44, 0.75), Vector3(1.3, 0.07, 0.4), wood_p)
			b.cyl(Vector3(0, 1.45, -0.7), 0.36, 0.5, MB.tag(Color("8a2a22"), MB.WOOD), Vector3.ZERO, 12)
			b.cyl(Vector3(0, 1.71, -0.7), 0.35, 0.02, MB.tag(Color("e8dcc0"), MB.CLOTH), Vector3.ZERO, 12)
			b.limb(Vector3(-0.55, 1.0, -1.0), Vector3(-0.55, 4.6, -1.0), 0.035, 0.025, wood_d, 5)
			b.limb(Vector3(-0.55, 4.5, -1.0), Vector3(-0.55, 4.5, -1.75), 0.02, 0.02, wood_d, 4)
			b.ribbon([Vector3(-0.55, 4.5, -1.4), Vector3(-0.55, 3.6, -1.42), Vector3(-0.55, 2.8, -1.38), Vector3(-0.55, 2.1, -1.42)], [0.72, 0.72, 0.7, 0.5], Vector3(0, 0, 1), cloth, cloth.darkened(0.25))
			b.sph(Vector3(-0.55, 4.66, -1.0), Vector3(0.07, 0.09, 0.07), MB.tag(Color("b8985a"), MB.METAL))
			Models._mi(root, b)
			_wheels(root, [[-0.1, 0.8, 0.86]], wood_d, wood_p, iron)
			_team(root, "horse", [Vector3(0, 0, 2.5)], Color("2a2622"), cloth)

## What a raid looks like while it stands (raids.gd): the raiders, turned on whoever they came for; on the road, a
## cart slewed across it with a wheel in the ditch.  Meta "raiders": the monsters, to be moved.
static func raid_scene(raid: Dictionary) -> Node3D:
	var root := Node3D.new()
	var raiders: Array = []
	var grp: Array = Raids.group(raid)
	for i in grp.size():
		var d: Dictionary = Data.ENEMIES[str(grp[i].id)]
		var m: Node3D = Models.monster(str(d.shape), d.col, false, str(grp[i].id))
		var a := TAU * float(i) / float(grp.size()) + 0.6
		m.position = Vector3(cos(a) * 2.3, 0, sin(a) * 2.3)
		m.rotation.y = atan2(-m.position.x, -m.position.z)
		root.add_child(m)
		raiders.append(m)
	root.set_meta("raiders", raiders)
	if str(raid.kind) == "road":
		var cart := Models.ride("ox_cart")
		cart.rotation = Vector3(0.0, 0.9, 0.16)
		cart.position = Vector3(0.3, -0.12, 0.0)
		root.add_child(cart)
		root.set_meta("cart", cart)
	return root
