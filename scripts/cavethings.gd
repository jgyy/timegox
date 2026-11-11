class_name CaveThings
extends RefCounted
## The things to do in a cave (the Hollow Hills release; props.gd says what each is, caves.gd where it
## stands): built here, the rock of them in voxels of the cave's own stone (voxel.gd), the rest with
## the mesh builder.  Each stands in a niche of the cave wall two metres square and three high, the
## open side towards +z (the model is turned to face the floor it is used from); the niche's back
## wall is at z = -1.

const KINDS := ["ore_vein", "drip_pool", "cave_painting", "glow_shrooms", "crystal", "echo_stone", "squeeze", "stream_bank", "fossil", "dig_spot", "bat_roost", "miner_niche", "cave_weiqi"]

static func _h(a: int, b: int, c: int) -> float:
	var n := (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xffff) / 65535.0

static func model(kind: String, theme: String) -> Node3D:
	var root := Node3D.new()
	var lk := Caves.look_of(theme)
	var pal := Voxel.palette(lk)
	var cells: Array = []
	var b := MB.new()
	var g := MB.new()
	var mv := MB.new()
	var mv_at := Vector3.ZERO
	var wood := MB.tag(Color("6a4a30"), MB.WOOD)
	var wood_l := MB.tag(Color("a87a4a"), MB.WOOD)
	var iron := MB.tag(Color("44444c"), MB.METAL)
	var lc: Color = lk.light
	match kind:
		"ore_vein":
			# the seam: a bulge of the back wall shot through with ore, the broken pieces at its foot, a
			# basket half full
			for y in 6:
				for x in range(-2, 2):
					var deep := 1 if (y == 0 or y == 5 or x == -2 or x == 1) else 2
					for z in deep:
						var ore := _h(x, y, z) < 0.45 and y > 0 and y < 5
						cells.append([Vector3i(x, y, -2 + z), Voxel.ORE if ore else (Voxel.BAND if (y + x) % 3 == 0 else Voxel.ROCK)])
			cells.append([Vector3i(-1, 0, 0), Voxel.ORE])
			cells.append([Vector3i(1, 0, 0), Voxel.ROCK])
			b.lathe(Vector3(0.62, 0, 0.35), [Vector2(0.2, 0.0), Vector2(0.27, 0.3), Vector2(0.24, 0.32)], MB.tag(Color("b89a60"), MB.HAIR), 10)
			b.sph(Vector3(0.62, 0.3, 0.35), Vector3(0.2, 0.08, 0.2), MB.tag(Color(lk.ore), MB.METAL))
		"drip_pool":
			# a rimstone basin, the water in it lit from under, and the stalactite it drips from
			for x in range(-2, 2):
				for z in range(-2, 1):
					var rim := x == -2 or x == 1 or z == -2 or z == 0
					if rim:
						cells.append([Vector3i(x, 0, z), Voxel.PALE])
			for y in 3:
				cells.append([Vector3i(-1, 5 - y, -1), Voxel.PALE])
			cells.append([Vector3i(0, 5, -1), Voxel.PALE])
			cells.append([Vector3i(-1, 5, -2), Voxel.PALE])
			g.quad(-0.5, -0.5, 0.5, 0.0, 0.34, Color(lc.r * 0.6, lc.g * 0.8, lc.b, 0.55))
			g.ball(Vector3(-0.25, 0.6, -0.25), 0.7, Color(lc.r, lc.g, lc.b, 0.1), true)
			# the drop, falling (the mover is shown while the pool is used)
			mv.sph(Vector3.ZERO, Vector3(0.035, 0.06, 0.035), Color(0.8, 0.95, 1.0, 0.9))
			mv_at = Vector3(-0.25, 1.2, -0.25)
		"cave_painting":
			# a smooth face of pale rock, and on it in red ochre and soot: a deer, three people holding
			# hands, a river, a sun with nine suns round it, and a hand
			for y in 6:
				for x in range(-2, 2):
					cells.append([Vector3i(x, y, -2), Voxel.PALE])
			var ochre := MB.tag(Color("a8402a"), MB.CLOTH)
			var soot := MB.tag(Color("2a2220"), MB.CLOTH)
			var px := 0.11
			var art := {
				ochre: [[-6, 9], [-5, 9], [-4, 9], [-3, 9], [-6, 8], [-3, 8], [-6, 7], [-3, 7], [-2, 10], [-2, 11], [-1, 11], [-7, 10],
					[2, 9], [2, 8], [2, 7], [1, 8], [3, 8], [4, 9], [4, 8], [4, 7], [5, 8], [6, 9], [6, 8], [6, 7], [7, 8],
					[5, 17], [4, 16], [6, 16], [5, 16], [5, 15], [4, 17], [6, 17], [5, 18], [5, 14], [3, 16], [7, 16]],
				soot: [[-7, 4], [-6, 4], [-5, 5], [-4, 5], [-3, 4], [-2, 4], [-1, 5], [0, 5], [1, 4], [2, 4], [3, 5], [4, 5], [5, 4], [6, 4],
					[2, 10], [4, 10], [6, 10], [-4, 15], [-5, 15], [-3, 15], [-4, 16], [-5, 16], [-3, 16], [-6, 17], [-5, 17], [-4, 17], [-3, 17], [-2, 16], [-4, 14], [-5, 14]],
			}
			for col in art:
				for q in art[col]:
					b.box(Vector3(q[0] * px, 0.35 + q[1] * px, -0.49), Vector3(px, px, 0.02), col)
		"glow_shrooms":
			# foxfire: a troop of pale-stalked mushrooms with caps of cold light, on a rotten log
			b.limb(Vector3(-0.8, 0.14, -0.5), Vector3(0.8, 0.14, -0.3), 0.16, 0.14, wood, 7)
			for k in 7:
				var sx := -0.7 + k * 0.23 + _h(k, 2, 5) * 0.08
				var sz := -0.45 + _h(k, 4, 9) * 0.35
				var sh := 0.22 + _h(k, 7, 1) * 0.3
				b.limb(Vector3(sx, 0.2, sz), Vector3(sx + 0.02, 0.2 + sh, sz), 0.025, 0.02, MB.tag(Color("e8e4d4"), MB.STONE), 5)
				g.sph(Vector3(sx + 0.02, 0.2 + sh, sz), Vector3(0.1 + sh * 0.12, 0.05, 0.1 + sh * 0.12), Color(lk.glow.r, lk.glow.g, lk.glow.b, 0.95))
			g.ball(Vector3(0, 0.5, -0.4), 0.9, Color(lk.glow.r, lk.glow.g, lk.glow.b, 0.1), true)
		"crystal":
			# a druse of spirit crystal growing out of the back wall and the floor: spikes of cells
			for k in 7:
				var cx := -2 + int(_h(k, 1, 3) * 4.0)
				var cz := -2 + int(_h(k, 5, 7) * 2.0)
				var ht := 1 + int(_h(k, 9, 2) * 5.0)
				for y in ht:
					cells.append([Vector3i(cx, y, cz), Voxel.GEM])
			for x in range(-2, 2):
				cells.append([Vector3i(x, 0, -2), Voxel.BAND])
			g.ball(Vector3(-0.2, 0.9, -0.7), 1.1, Color(lk.gem.r, lk.gem.g, lk.gem.b, 0.12), true)
		"echo_stone":
			# a stalagmite that has grown up into a pillar as tall as a man, hollow as a bell
			for y in 5:
				var wide := 2 if y < 2 else 1
				for x in wide:
					for z in wide:
						cells.append([Vector3i(-1 + x, y, -1 + z), Voxel.PALE if y != 2 else Voxel.BAND])
			cells.append([Vector3i(-1, 5, -1), Voxel.PALE])
		"squeeze":
			# two leaves of rock leaning together, and the dark between them, a hand and a half wide
			for y in 6:
				for z in range(-2, 0):
					cells.append([Vector3i(-2, y, z), Voxel.ROCK if (y + z) % 3 != 0 else Voxel.BAND])
					cells.append([Vector3i(1, y, z), Voxel.ROCK if (y + z) % 3 != 1 else Voxel.BAND])
					if y >= 4:
						cells.append([Vector3i(-1, y, z), Voxel.ROCK])
						cells.append([Vector3i(0, y, z), Voxel.BAND])
				if y < 4:
					cells.append([Vector3i(-1, y, -2), Voxel.ROCK])
					cells.append([Vector3i(0, y, -2), Voxel.COAL])
			b.box(Vector3(0.12, 1.0, -0.74), Vector3(0.3, 2.0, 0.04), MB.tag(Color("06060a"), MB.STONE))
		"stream_bank":
			# a shelf of gravel, and behind it the stream itself, coming out of one hole and into another
			for x in range(-2, 2):
				cells.append([Vector3i(x, 0, 0), Voxel.SAND])
				cells.append([Vector3i(x, 0, -2), Voxel.BAND])
				cells.append([Vector3i(x, 1, -2), Voxel.ROCK])
				cells.append([Vector3i(x, 2, -2), Voxel.BAND if x % 2 == 0 else Voxel.ROCK])
			g.quad(-1.0, -0.55, 1.0, 0.02, 0.3, Color(lc.r * 0.5, lc.g * 0.75, lc.b, 0.6))
			for k in 6:
				b.sph(Vector3(-0.8 + k * 0.32, 0.52, 0.18 + _h(k, 3, 3) * 0.2), Vector3(0.07, 0.04, 0.06), MB.tag(Color("8a8a84").darkened(_h(k, 1, 1) * 0.3), MB.STONE))
			# ripples (shown while the gravel is panned)
			mv.torus(Vector3.ZERO, 0.22, 0.012, Color(0.9, 0.97, 1.0, 0.6))
			mv_at = Vector3(0.1, 0.32, -0.2)
		"fossil":
			# a slab with an ammonite in it as wide as a cartwheel: the coil picked out in bone-white
			for y in 5:
				for x in range(-2, 2):
					cells.append([Vector3i(x, y, -2), Voxel.BAND if y % 2 == 0 else Voxel.ROCK])
			var bone := MB.tag(Color("e0d8c4"), MB.STONE)
			for k in 40:
				var a := k * 0.42
				var r := 0.08 + k * 0.016
				b.box(Vector3(cos(a) * r, 1.25 + sin(a) * r, -0.48), Vector3(0.07 + k * 0.002, 0.07 + k * 0.002, 0.03), bone, Vector3(0, 0, a))
		"dig_spot":
			# a mound of turned earth, three stones on it, and a spade stood in the ground beside it
			for x in range(-1, 1):
				for z in range(-2, 0):
					cells.append([Vector3i(x, 0, z), Voxel.EARTH])
			cells.append([Vector3i(-1, 1, -1), Voxel.EARTH])
			for k in 3:
				b.sph(Vector3(-0.3 + k * 0.28, 0.58, -0.3 - (k % 2) * 0.2), Vector3(0.09, 0.06, 0.08), MB.tag(Color("9a968e"), MB.STONE))
			b.limb(Vector3(0.75, 0.25, -0.5), Vector3(0.82, 1.3, -0.62), 0.022, 0.022, wood_l, 5)
			b.box(Vector3(0.74, 0.14, -0.49), Vector3(0.2, 0.3, 0.03), iron, Vector3(-0.1, 0, 0.06))
		"bat_roost":
			# a low roof of rock crowded with sleeping bats, and under it what bats leave
			for x in range(-2, 2):
				for z in range(-2, 0):
					cells.append([Vector3i(x, 5, z), Voxel.ROCK if (x + z) % 2 == 0 else Voxel.BAND])
					if _h(x, z, 4) < 0.4:
						cells.append([Vector3i(x, 4, z), Voxel.ROCK])
			cells.append([Vector3i(-1, 0, -1), Voxel.PALE])
			cells.append([Vector3i(0, 0, -2), Voxel.PALE])
			var bat := MB.tag(Color("2a2428"), MB.HAIR)
			for k in 11:
				var bx := -0.85 + _h(k, 2, 2) * 1.7
				var bz := -0.9 + _h(k, 6, 5) * 0.8
				var by := 2.25 - (0.5 if _h(int(bx * 2.0 + 2.0), int(bz * 2.0 + 2.0), 4) < 0.4 else 0.0)
				b.sph(Vector3(bx, by, bz), Vector3(0.06, 0.13, 0.05), bat)
				b.sph(Vector3(bx, by - 0.14, bz), Vector3(0.035, 0.04, 0.035), bat)
		"miner_niche":
			# a shelf cut in the wall with the soot of old flames over it, a hook, a tally scratched in
			# fives, and (once it has been lit) a lamp burning
			for y in 6:
				for x in range(-2, 2):
					if y >= 2 and y <= 3 and x >= -1 and x <= 0:
						continue
					cells.append([Vector3i(x, y, -2), Voxel.COAL if (y == 4 and x >= -1 and x <= 0) else (Voxel.BAND if y % 3 == 0 else Voxel.ROCK)])
			b.box(Vector3(0, 1.0, -0.9), Vector3(1.0, 0.06, 0.3), MB.tag(Color("8a8680"), MB.STONE))
			b.limb(Vector3(0, 1.95, -0.98), Vector3(0, 1.85, -0.8), 0.015, 0.012, iron, 4)
			for k in 9:
				b.box(Vector3(0.62 + (k % 5) * 0.06, 1.1 + (k / 5) * 0.22, -0.49), Vector3(0.015, 0.16, 0.02), MB.tag(Color("d8d4cc"), MB.STONE), Vector3(0, 0, 0.35 if k % 5 == 4 else 0.0))
			b.lathe(Vector3(0, 1.03, -0.85), [Vector2(0.09, 0.0), Vector2(0.12, 0.06), Vector2(0.05, 0.12)], MB.tag(Color("9a8444"), MB.METAL), 8)
			mv.sph(Vector3.ZERO, Vector3(0.05, 0.11, 0.05), Color(1.0, 0.75, 0.35, 0.95))
			mv.ball(Vector3.ZERO, 0.4, Color(1.0, 0.7, 0.3, 0.14), true)
			mv_at = Vector3(0, 1.26, -0.85)
		"cave_weiqi":
			# Rotten-Axe Mountain: a board cut in the top of a flat stone, the game half played, two
			# stone seats, two cups, and an axe whose handle has gone to dust
			for x in range(-1, 1):
				for z in range(-2, 0):
					cells.append([Vector3i(x, 0, z), Voxel.BAND])
					cells.append([Vector3i(x, 1, z), Voxel.PALE])
			cells.append([Vector3i(-2, 0, -1), Voxel.ROCK])
			cells.append([Vector3i(1, 0, -1), Voxel.ROCK])
			b.box(Vector3(0, 1.01, -0.5), Vector3(0.8, 0.02, 0.8), MB.tag(Color("c8a868"), MB.WOOD))
			for k in 26:
				var gx := int(_h(k, 1, 8) * 9.0)
				var gz := int(_h(k, 3, 6) * 9.0)
				b.sph(Vector3(-0.36 + gx * 0.09, 1.03, -0.86 + gz * 0.09), Vector3(0.035, 0.014, 0.035), MB.tag(Color("1a1a1e") if k % 2 == 0 else Color("f0ece0"), MB.STONE))
			for s: float in [-1.0, 1.0]:
				b.lathe(Vector3(s * 0.48, 1.0, -0.2), [Vector2(0.04, 0.0), Vector2(0.055, 0.07)], MB.tag(Color("d8d4c8"), MB.STONE), 8)
			b.box(Vector3(0.95, 0.04, 0.2), Vector3(0.2, 0.05, 0.28), iron, Vector3(0, 0.5, 0))
			for k2 in 6:
				b.sph(Vector3(0.9 - k2 * 0.1, 0.03, 0.3 + k2 * 0.09), Vector3(0.05, 0.015, 0.04), MB.tag(Color("5a4a3a").darkened(k2 * 0.06), MB.WOOD))
	if not cells.is_empty():
		var mi := Voxel.model(cells, pal, MB.mat_plain())
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not mv.is_empty():
		var mover := Node3D.new()
		mover.name = "mover"
		mover.position = mv_at
		mover.visible = false
		root.add_child(mover)
		MB.mesh_node(mover, mv.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.set_meta("mover", mover)
	return root

## What is held for the new clips (in the hand bone's own space, like Props.held): null if `what` is
## not one of these.
static func held(what: String) -> Node3D:
	var b := MB.new()
	var wood := MB.tag(Color("6a4a30"), MB.WOOD)
	var wood_l := MB.tag(Color("a87a4a"), MB.WOOD)
	var iron := MB.tag(Color("44444c"), MB.METAL)
	match what:
		"pickaxe":
			b.limb(Vector3(0, -0.08, -0.25), Vector3(0, -0.08, 0.62), 0.018, 0.018, wood_l, 5)
			b.limb(Vector3(0, -0.34, 0.6), Vector3(0, 0.18, 0.6), 0.03, 0.008, iron, 5)
			b.box(Vector3(0, -0.08, 0.6), Vector3(0.06, 0.09, 0.07), iron)
		"spade":
			b.limb(Vector3(0, -0.08, -0.35), Vector3(0, -0.08, 0.7), 0.018, 0.018, wood_l, 5)
			b.box(Vector3(0, -0.08, 0.84), Vector3(0.02, 0.2, 0.3), iron)
			b.limb(Vector3(0, -0.16, -0.36), Vector3(0, 0.0, -0.36), 0.016, 0.016, wood, 4)
		"pan":
			b.lathe(Vector3(0.08, -0.14, 0.1), [Vector2(0.1, 0.0), Vector2(0.2, 0.05), Vector2(0.21, 0.06)], iron, 12)
		"chisel":
			b.limb(Vector3(0, -0.08, -0.06), Vector3(0, -0.08, 0.08), 0.014, 0.014, wood, 5)
			b.limb(Vector3(0, -0.08, 0.08), Vector3(0, -0.08, 0.2), 0.008, 0.004, iron, 4)
		"pestle":
			b.limb(Vector3(0, -0.08, 0.2), Vector3(0, -0.08, -0.7), 0.025, 0.04, wood_l, 6)
			b.sph(Vector3(0, -0.08, -0.72), Vector3(0.055, 0.055, 0.07), wood_l)
		"jug":
			b.lathe(Vector3(0.1, -0.3, 0.0), [Vector2(0.07, 0.0), Vector2(0.12, 0.1), Vector2(0.11, 0.22), Vector2(0.05, 0.3), Vector2(0.065, 0.34)], MB.tag(Color("9a5a3a"), MB.STONE), 10)
		"comb":
			b.box(Vector3(0, -0.1, 0.03), Vector3(0.012, 0.05, 0.11), wood_l)
			for k in 6:
				b.box(Vector3(0, -0.145, -0.015 + k * 0.018), Vector3(0.008, 0.045, 0.006), wood_l)
		_:
			return null
	var root := Node3D.new()
	MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root
