class_name Machines
extends RefCounted
## The machines of the Hundred Works (works.gd), built from code like everything else: what stands in
## the land once Lin Feng has built a work, to be walked up to and looked at.
##
## Each is a few hundred triangles of the shared mesh builder (mb.gd) in the game's own toon shading,
## and the ones that move have a part of their own to move: a node under the meta key "spin" (it turns
## about its Z axis: a water-wheel, a gear), "rock" (it see-saws: a well-sweep, a bellows arm), "drop"
## (it rises and falls: a trip-hammer) or "turn" (it turns about Y: the pointing figure, the mirror's
## ring, the paper servants), animated by `animate` from the world's clock, so the screenshots and
## the bot see the same thing at the same second.

const WOOD := Color("7a5a38")
const WOOD_DARK := Color("4a3626")
const WOOD_PALE := Color("b89868")
const BRONZE := Color("b8863a")
const BRONZE_OLD := Color("6a8a6a")
const STONE := Color("8a8478")
const CLAY := Color("b8704a")
const ROPE := Color("c8b080")
const PAPER := Color("f0e8d0")
const JADE := Color("7ac8a0")
const RED := Color("c8302a")

## What a built work looks like ("model" of a story site, or the work's own id).
static func model(key: String) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()      # the fixed part
	var m := MB.new()      # the moving part, about its own origin
	var g := MB.new()      # what glows
	var pivot := Vector3.ZERO
	var move := ""
	var w := MB.tag(WOOD, MB.WOOD)
	var wd := MB.tag(WOOD_DARK, MB.WOOD)
	var wp := MB.tag(WOOD_PALE, MB.WOOD)
	var br := MB.tag(BRONZE, MB.METAL)
	var st := MB.tag(STONE, MB.STONE)
	match key:
		"fire_kit":
			# a ring of stones, a hearth-board and spindle, a bow, a little lean-to of sticks
			for k in 7:
				var a := TAU * k / 7.0
				b.sph(Vector3(cos(a) * 0.55, 0.1, sin(a) * 0.55), Vector3(0.16, 0.12, 0.16), st)
			b.box(Vector3(0, 0.06, 0), Vector3(0.5, 0.05, 0.16), wp)
			b.cyl(Vector3(0, 0.3, 0), 0.025, 0.5, wd)
			b.limb(Vector3(-0.35, 0.34, 0.1), Vector3(0.35, 0.34, 0.1), 0.02, 0.02, w, 5)
			for k2 in 5:
				b.limb(Vector3(-0.9 + k2 * 0.12, 0.0, -0.7), Vector3(-0.5 + k2 * 0.05, 1.1, -0.2), 0.035, 0.03, wd, 5)
			g.ball(Vector3(0, 0.16, 0), 0.12, Color(1.0, 0.55, 0.2, 0.7), true)
		"cords":
			# a frame of two posts and a bar, hung with knotted cords of many lengths
			b.cyl(Vector3(-0.8, 0.9, 0), 0.07, 1.8, w)
			b.cyl(Vector3(0.8, 0.9, 0), 0.07, 1.8, w)
			b.limb(Vector3(-0.9, 1.75, 0), Vector3(0.9, 1.75, 0), 0.05, 0.05, wd, 6)
			for k3 in 9:
				var x := -0.7 + k3 * 0.175
				var ln := 0.5 + 0.9 * Terrain3D.hash2(k3, 7)
				b.limb(Vector3(x, 1.72, 0), Vector3(x, 1.72 - ln, 0.02), 0.014, 0.014, MB.tag(ROPE if k3 % 3 != 0 else RED, MB.CLOTH), 4)
				for j in int(2 + 3 * Terrain3D.hash2(k3, 3)):
					b.ball(Vector3(x, 1.6 - j * 0.22, 0.02), 0.035, MB.tag(ROPE.darkened(0.2), MB.CLOTH), true)
		"sling":
			# a butt of straw with a painted mark, a rack with slings, a heap of river stones
			_cyl(b, Vector3(0, 0.8, -0.5), 0.6, 0.3, MB.tag(Color("d8c070"), MB.FOLIAGE), Vector3(PI * 0.5, 0, 0), 12)
			_cyl(b, Vector3(0, 0.8, -0.34), 0.25, 0.02, MB.tag(RED, MB.CLOTH), Vector3(PI * 0.5, 0, 0), 10)
			b.limb(Vector3(-0.4, 0.0, -0.7), Vector3(0, 0.8, -0.6), 0.04, 0.04, wd, 5)
			b.limb(Vector3(0.4, 0.0, -0.7), Vector3(0, 0.8, -0.6), 0.04, 0.04, wd, 5)
			for k4 in 9:
				b.sph(Vector3(0.7 + 0.14 * (k4 % 3), 0.07 + 0.1 * (k4 / 3), 0.4 + 0.12 * (k4 % 2)), Vector3(0.09, 0.07, 0.08), st)
			b.cyl(Vector3(-0.8, 0.5, 0.4), 0.04, 1.0, w)
			b.limb(Vector3(-0.8, 0.95, 0.4), Vector3(-0.7, 0.4, 0.45), 0.015, 0.015, MB.tag(ROPE, MB.CLOTH), 4)
		"kiln":
			# a beehive kiln with a fire-mouth, a chimney hole and a row of jars
			b.lathe(Vector3.ZERO, [Vector2(0.95, 0.0), Vector2(1.0, 0.5), Vector2(0.8, 1.1), Vector2(0.4, 1.5), Vector2(0.18, 1.62)], MB.tag(CLAY, MB.STONE), 12)
			b.box(Vector3(0, 0.3, 0.95), Vector3(0.45, 0.5, 0.2), MB.tag(Color("2a1a14"), MB.STONE))
			g.ball(Vector3(0, 0.3, 1.0), 0.2, Color(1.0, 0.5, 0.15, 0.8), true)
			for k5 in 4:
				b.lathe(Vector3(1.3, 0.0, -0.6 + k5 * 0.42), [Vector2(0.12, 0.0), Vector2(0.2, 0.2), Vector2(0.16, 0.4), Vector2(0.08, 0.46)], MB.tag(Color("8a5a3a") if k5 % 2 == 0 else Color("3a4a5a"), MB.STONE), 8)
		"adze":
			# a chopping block with the adze struck into it, a trestle and a half-hewn log
			b.cyl(Vector3(0, 0.3, 0), 0.4, 0.6, wd, Vector3.ZERO, 10)
			b.limb(Vector3(0.05, 0.6, 0), Vector3(0.5, 1.3, 0.1), 0.035, 0.03, wp, 5)
			b.box(Vector3(0.02, 0.66, 0), Vector3(0.1, 0.18, 0.3), MB.tag(Color("5a8a6a"), MB.STONE), Vector3(0, 0, 0.5))
			b.limb(Vector3(-1.3, 0.45, -0.5), Vector3(-0.2, 0.45, -0.9), 0.2, 0.2, w, 8)
			b.box(Vector3(-0.75, 0.62, -0.7), Vector3(0.9, 0.04, 0.26), wp, Vector3(0, 0.35, 0))
			for sx in [-1.2, -0.3]:
				b.limb(Vector3(sx, 0.0, -0.4), Vector3(sx + 0.05, 0.4, -0.7), 0.04, 0.04, wd, 4)
				b.limb(Vector3(sx, 0.0, -1.0), Vector3(sx + 0.05, 0.4, -0.75), 0.04, 0.04, wd, 4)
		"hide_coat":
			# a hide stretched on a frame to dry, and a finished coat on a stand
			b.cyl(Vector3(-0.9, 0.9, 0), 0.05, 1.8, w)
			b.cyl(Vector3(0.5, 0.9, 0), 0.05, 1.8, w)
			b.limb(Vector3(-0.95, 1.75, 0), Vector3(0.55, 1.75, 0), 0.04, 0.04, w, 5)
			b.limb(Vector3(-0.95, 0.2, 0), Vector3(0.55, 0.2, 0), 0.04, 0.04, w, 5)
			b.box(Vector3(-0.2, 0.98, 0), Vector3(1.1, 1.3, 0.03), MB.tag(Color("c8a070"), MB.CLOTH))
			b.cyl(Vector3(1.2, 0.7, 0.2), 0.04, 1.4, wd)
			b.limb(Vector3(0.85, 1.3, 0.2), Vector3(1.55, 1.3, 0.2), 0.04, 0.04, wd, 5)
			b.sph(Vector3(1.2, 0.95, 0.2), Vector3(0.36, 0.5, 0.2), MB.tag(Color("8a6a4a"), MB.CLOTH))
			b.sph(Vector3(1.2, 1.38, 0.2), Vector3(0.2, 0.1, 0.16), MB.tag(Color("e8dcc0"), MB.HAIR))
		"well_sweep":
			# the shadoof: a forked post, a long pole on it, a stone at the short end, a bucket on a rope
			# at the long end, over a stone well-head
			b.lathe(Vector3(1.5, 0, 0), [Vector2(0.5, 0.0), Vector2(0.5, 0.5), Vector2(0.4, 0.5), Vector2(0.4, 0.1)], st, 10)
			b.cyl(Vector3(0, 1.1, 0), 0.09, 2.2, w)
			b.limb(Vector3(0, 2.1, 0), Vector3(0, 2.45, 0.16), 0.05, 0.04, w, 5)
			b.limb(Vector3(0, 2.1, 0), Vector3(0, 2.45, -0.16), 0.05, 0.04, w, 5)
			pivot = Vector3(0, 2.3, 0)
			m.limb(Vector3(-1.3, 0, 0), Vector3(1.9, 0, 0), 0.07, 0.04, wp, 6)
			m.sph(Vector3(-1.3, -0.12, 0), Vector3(0.24, 0.2, 0.22), st)
			m.limb(Vector3(1.9, 0, 0), Vector3(1.9, -1.2, 0), 0.015, 0.015, MB.tag(ROPE, MB.CLOTH), 4)
			m.lathe(Vector3(1.9, -1.5, 0), [Vector2(0.13, 0.0), Vector2(0.17, 0.3)], wd, 8)
			move = "rock"
		"water_wheel", "ban_wheel":
			# an undershot wheel on two trestles, with a trough under it
			for sz in [-0.45, 0.45]:
				b.limb(Vector3(-0.8, 0.0, sz), Vector3(0, 1.5, sz), 0.07, 0.06, wd, 5)
				b.limb(Vector3(0.8, 0.0, sz), Vector3(0, 1.5, sz), 0.07, 0.06, wd, 5)
			b.box(Vector3(0, 0.08, 0), Vector3(2.6, 0.14, 0.6), MB.tag(Color("4a7a9a"), MB.CRYSTAL))
			pivot = Vector3(0, 1.5, 0)
			_wheel(m, 1.3, 0.5, 10, w, wp)
			move = "spin"
		"trip_hammer":
			# a small wheel, a pegged shaft, and a hammer on a beam that the pegs lift and let fall on a mortar
			b.limb(Vector3(-1.4, 0.0, -0.3), Vector3(-1.4, 1.0, -0.3), 0.07, 0.07, wd, 5)
			b.limb(Vector3(-1.4, 0.0, 0.3), Vector3(-1.4, 1.0, 0.3), 0.07, 0.07, wd, 5)
			b.limb(Vector3(-1.4, 1.0, -0.4), Vector3(-1.4, 1.0, 0.4), 0.06, 0.06, w, 6)
			_cyl(b, Vector3(-1.4, 1.0, 0.0), 0.5, 0.12, wp, Vector3(PI * 0.5, 0, 0), 10)
			b.cyl(Vector3(0.2, 0.55, 0), 0.07, 1.1, wd)
			b.lathe(Vector3(1.3, 0, 0), [Vector2(0.3, 0.0), Vector2(0.36, 0.35), Vector2(0.24, 0.35), Vector2(0.2, 0.1)], st, 10)
			pivot = Vector3(0.2, 1.1, 0)
			m.limb(Vector3(-1.2, 0, 0), Vector3(1.1, 0, 0), 0.07, 0.07, w, 6)
			m.cyl(Vector3(1.1, -0.3, 0), 0.12, 0.6, MB.tag(Color("5a5a60"), MB.METAL))
			move = "drop"
		"water_bellows":
			# a furnace stack, a box bellows beside it and a rocking arm driven from a little wheel
			b.lathe(Vector3(0.9, 0, 0), [Vector2(0.55, 0.0), Vector2(0.5, 1.0), Vector2(0.32, 1.9), Vector2(0.26, 2.0)], MB.tag(Color("7a4a3a"), MB.STONE), 10)
			g.ball(Vector3(0.9, 0.35, 0.5), 0.18, Color(1.0, 0.5, 0.15, 0.8), true)
			b.box(Vector3(-0.3, 0.35, 0), Vector3(0.9, 0.6, 0.5), w)
			b.limb(Vector3(0.15, 0.3, 0), Vector3(0.45, 0.3, 0), 0.06, 0.04, MB.tag(Color("3a3a40"), MB.METAL), 5)
			_cyl(b, Vector3(-1.5, 0.6, 0), 0.5, 0.12, wp, Vector3(PI * 0.5, 0, 0), 10)
			b.cyl(Vector3(-0.9, 0.7, 0.4), 0.06, 1.4, wd)
			pivot = Vector3(-0.9, 1.4, 0.4)
			m.limb(Vector3(-0.7, 0, 0), Vector3(0.7, 0, 0), 0.05, 0.05, w, 5)
			m.limb(Vector3(0.6, 0, 0), Vector3(0.6, -0.75, -0.3), 0.03, 0.03, wd, 4)
			move = "rock"
		"crossbow":
			# a repeating crossbow on a tripod stand, its magazine on top, and a rack of bolts
			for k6 in 3:
				var a2 := TAU * k6 / 3.0
				b.limb(Vector3(cos(a2) * 0.5, 0.0, sin(a2) * 0.5), Vector3(0, 1.0, 0), 0.04, 0.04, wd, 5)
			b.box(Vector3(0, 1.08, 0.1), Vector3(0.12, 0.1, 1.2), w)
			b.box(Vector3(0, 1.26, 0.2), Vector3(0.1, 0.26, 0.6), wp)
			b.limb(Vector3(-0.75, 1.1, 0.6), Vector3(0, 1.1, 0.72), 0.03, 0.04, wd, 5)
			b.limb(Vector3(0.75, 1.1, 0.6), Vector3(0, 1.1, 0.72), 0.03, 0.04, wd, 5)
			b.limb(Vector3(-0.75, 1.1, 0.6), Vector3(0.75, 1.1, 0.6), 0.008, 0.008, MB.tag(ROPE, MB.CLOTH), 3)
			b.box(Vector3(1.0, 0.35, -0.3), Vector3(0.5, 0.7, 0.3), wd)
			for k7 in 6:
				b.limb(Vector3(0.82 + k7 * 0.07, 0.7, -0.3), Vector3(0.82 + k7 * 0.07, 1.05, -0.3), 0.012, 0.012, wp, 3)
		"chariot":
			# a two-wheeled cart with a pole, and on it a wooden figure whose arm always points south
			for sx2 in [-0.7, 0.7]:
				b.torus(Vector3(sx2, 0.6, 0), 0.55, 0.05, wd, Vector3(0, 0, PI * 0.5))
				for k8 in 4:
					var a3 := PI * k8 / 4.0
					b.limb(Vector3(sx2, 0.6 - sin(a3) * 0.55, -cos(a3) * 0.55), Vector3(sx2, 0.6 + sin(a3) * 0.55, cos(a3) * 0.55), 0.025, 0.025, w, 4)
			b.box(Vector3(0, 0.75, 0), Vector3(1.2, 0.12, 1.3), w)
			b.limb(Vector3(0, 0.7, 0.6), Vector3(0, 0.5, 2.0), 0.05, 0.04, wd, 5)
			b.cyl(Vector3(0, 0.95, 0), 0.22, 0.3, br, Vector3.ZERO, 10)
			pivot = Vector3(0, 1.1, 0)
			m.cyl(Vector3(0, 0.4, 0), 0.13, 0.8, MB.tag(Color("3a6a8a"), MB.CLOTH))
			m.ball(Vector3(0, 0.92, 0), 0.14, wp, true)
			m.limb(Vector3(0, 0.66, 0), Vector3(0, 0.72, 0.6), 0.04, 0.03, MB.tag(Color("3a6a8a"), MB.CLOTH), 4)
			move = "turn"
		"wooden_ox":
			# the walking barrow: a boxy ox of planks on four jointed legs, with panniers
			b.box(Vector3(0, 0.85, 0), Vector3(0.6, 0.5, 1.3), w)
			b.box(Vector3(0, 1.0, 0.85), Vector3(0.36, 0.34, 0.45), wp)
			for sx3 in [-1.0, 1.0]:
				b.limb(Vector3(0.14 * sx3, 1.15, 0.95), Vector3(0.36 * sx3, 1.36, 1.05), 0.04, 0.015, wd, 4)
				b.box(Vector3(0.42 * sx3, 0.8, -0.1), Vector3(0.22, 0.4, 0.7), MB.tag(Color("c8b080"), MB.CLOTH))
				for sz2 in [-0.45, 0.5]:
					b.limb(Vector3(0.24 * sx3, 0.62, sz2), Vector3(0.26 * sx3, 0.32, sz2 + 0.1), 0.06, 0.05, wd, 5)
					b.limb(Vector3(0.26 * sx3, 0.32, sz2 + 0.1), Vector3(0.26 * sx3, 0.0, sz2), 0.05, 0.05, wd, 5)
		"array":
			# eight jade pegs on the trigrams, a flat stone to sit on, and a ring of light that turns
			b.cyl(Vector3(0, 0.08, 0), 0.5, 0.16, st, Vector3.ZERO, 12)
			for k9 in 8:
				var a4 := TAU * k9 / 8.0
				b.crystal(Vector3(cos(a4) * 1.3, 0.0, sin(a4) * 1.3), 0.09, 0.55, MB.tag(JADE, MB.CRYSTAL))
			pivot = Vector3(0, 0.25, 0)
			var mg := MB.new()
			mg.arc(Vector3.ZERO, 1.3, 0.07, 0.0, TAU * 0.3, Color(0.6, 1.0, 0.85, 0.6), 12, Vector3(PI * 0.5, 0, 0))
			mg.arc(Vector3.ZERO, 1.3, 0.07, TAU * 0.5, TAU * 0.8, Color(0.6, 1.0, 0.85, 0.6), 12, Vector3(PI * 0.5, 0, 0))
			var ring := MB.mesh_node(root, mg.build(MB.mat_glow()), pivot)
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.set_meta("turn", ring)
		"talismans":
			# a writing table with brush and cinnabar, and a line of yellow talismans drying
			b.box(Vector3(0, 0.6, 0), Vector3(1.2, 0.08, 0.6), wd)
			for sx4 in [-0.5, 0.5]:
				for sz3 in [-0.22, 0.22]:
					b.cyl(Vector3(sx4, 0.3, sz3), 0.04, 0.6, wd)
			b.cyl(Vector3(0.35, 0.68, 0.05), 0.09, 0.06, MB.tag(RED, MB.STONE), Vector3.ZERO, 8)
			b.limb(Vector3(-0.1, 0.66, 0.1), Vector3(0.2, 0.7, 0.2), 0.015, 0.01, wp, 4)
			b.cyl(Vector3(-1.0, 1.0, -0.5), 0.04, 2.0, w)
			b.cyl(Vector3(1.0, 1.0, -0.5), 0.04, 2.0, w)
			b.limb(Vector3(-1.0, 1.9, -0.5), Vector3(1.0, 1.9, -0.5), 0.01, 0.01, MB.tag(ROPE, MB.CLOTH), 3)
			for k10 in 6:
				var x2 := -0.8 + k10 * 0.32
				b.box(Vector3(x2, 1.55, -0.5), Vector3(0.18, 0.62, 0.01), MB.tag(Color("e8c840"), MB.CLOTH), Vector3(0, 0, 0.06 * (k10 % 3 - 1)))
				b.box(Vector3(x2, 1.55, -0.49), Vector3(0.05, 0.42, 0.005), MB.tag(RED, MB.CLOTH), Vector3(0, 0, 0.06 * (k10 % 3 - 1)))
		"furnace":
			# a three-legged bronze furnace with eight windows and a trigram lid
			for k11 in 3:
				var a5 := TAU * k11 / 3.0 + 0.5
				b.limb(Vector3(cos(a5) * 0.6, 0.0, sin(a5) * 0.6), Vector3(cos(a5) * 0.45, 0.6, sin(a5) * 0.45), 0.09, 0.07, MB.tag(BRONZE_OLD, MB.METAL), 6)
			b.lathe(Vector3(0, 0.55, 0), [Vector2(0.4, 0.0), Vector2(0.7, 0.25), Vector2(0.72, 0.8), Vector2(0.5, 1.1), Vector2(0.52, 1.18)], MB.tag(BRONZE_OLD, MB.METAL), 12)
			b.lathe(Vector3(0, 1.73, 0), [Vector2(0.54, 0.0), Vector2(0.4, 0.16), Vector2(0.12, 0.26), Vector2(0.1, 0.4)], br, 12)
			for k12 in 8:
				var a6 := TAU * k12 / 8.0
				g.ball(Vector3(cos(a6) * 0.7, 1.05, sin(a6) * 0.7), 0.09, Color(1.0, 0.6, 0.2, 0.8), true)
		"paper_servants":
			# a low table with paper and scissors, and three paper figures standing a hand high
			b.box(Vector3(0, 0.35, -0.5), Vector3(1.0, 0.06, 0.5), wd)
			for sx5 in [-0.42, 0.42]:
				b.cyl(Vector3(sx5, 0.17, -0.5), 0.04, 0.34, wd)
			b.box(Vector3(0.1, 0.39, -0.5), Vector3(0.4, 0.01, 0.3), MB.tag(PAPER, MB.CLOTH))
			pivot = Vector3(0, 0, 0.3)
			for k13 in 3:
				var a7 := TAU * k13 / 3.0
				var c := Vector3(cos(a7) * 0.5, 0, sin(a7) * 0.5)
				m.box(c + Vector3(0, 0.3, 0), Vector3(0.2, 0.34, 0.012), MB.tag(PAPER, MB.CLOTH), Vector3(0, -a7, 0))
				m.sph(c + Vector3(0, 0.56, 0), Vector3(0.09, 0.09, 0.012), MB.tag(PAPER, MB.CLOTH), Vector3(0, -a7, 0))
				m.box(c + Vector3(0, 0.36, 0), Vector3(0.4, 0.06, 0.012), MB.tag(PAPER, MB.CLOTH), Vector3(0, -a7, 0))
				m.box(c + Vector3(0, 0.07, 0), Vector3(0.06, 0.14, 0.012), MB.tag(RED, MB.CLOTH), Vector3(0, -a7, 0))
			move = "turn"
		"mirror":
			# a bronze mirror in a ring on a stone pedestal, turned to the hillside
			b.lathe(Vector3.ZERO, [Vector2(0.5, 0.0), Vector2(0.4, 0.2), Vector2(0.18, 0.4), Vector2(0.16, 1.1), Vector2(0.26, 1.2)], st, 10)
			b.torus(Vector3(0, 1.9, 0), 0.7, 0.05, br, Vector3(PI * 0.5, 0, 0), true)
			pivot = Vector3(0, 1.9, 0)
			m.torus(Vector3.ZERO, 0.62, 0.04, MB.tag(BRONZE_OLD, MB.METAL), Vector3(0, 0, PI * 0.5), true)
			_cyl(m, Vector3.ZERO, 0.5, 0.04, MB.tag(Color("e8e0c0"), MB.METAL), Vector3(0, 0, PI * 0.5), 14)
			move = "turn"
		"flags":
			# five flags in the five colours on poles, in a ring
			var cols := [Color("3a8a4a"), Color("c8302a"), Color("d8b040"), Color("e8e8e8"), Color("2a3a5a")]
			for k14 in 5:
				var a8 := TAU * k14 / 5.0
				var p := Vector3(cos(a8) * 1.1, 0, sin(a8) * 1.1)
				b.cyl(p + Vector3(0, 1.1, 0), 0.03, 2.2, wd)
				b.box(p + Vector3(0.28, 1.8, 0), Vector3(0.55, 0.7, 0.012), MB.tag(cols[k14], MB.CLOTH))
				b.ball(p + Vector3(0, 2.24, 0), 0.05, br, true)
			g.ball(Vector3(0, 0.3, 0), 0.25, Color(0.8, 0.9, 1.0, 0.35), true)
		_:
			b.box(Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8), w)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc()))
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not m.is_empty():
		var mv := MB.mesh_node(root, m.build(MB.mat_vc()), pivot)
		root.set_meta(move, mv)
	return root

## A cylinder of radius `r` and height `h` turned by `rot`: built upright and then turned.  (MB.cyl
## scales after it turns, which is right for a column leaning a little and flattens a thin wheel
## stood on its rim into an ellipse.)
static func _cyl(mb: MB, pos: Vector3, r: float, h: float, col: Color, rot: Vector3, seg: int = 8) -> void:
	var t := MB.new()
	t.cyl(Vector3.ZERO, r, h, col, Vector3.ZERO, seg)
	mb.merge(t, Transform3D(Basis.from_euler(rot), pos))

## A wheel about the Z axis at the origin: a rim, spokes and float-boards.
static func _wheel(m: MB, r: float, wdt: float, n: int, wood: Color, pale: Color) -> void:
	for sz in [-wdt * 0.5, wdt * 0.5]:
		m.torus(Vector3(0, 0, sz), r, 0.06, wood, Vector3(PI * 0.5, 0, 0))
		for k in n / 2:
			var a := PI * k / float(n / 2)
			m.limb(Vector3(-cos(a) * r, -sin(a) * r, sz), Vector3(cos(a) * r, sin(a) * r, sz), 0.035, 0.035, wood, 4)
	for k2 in n:
		var a2 := TAU * k2 / float(n)
		m.box(Vector3(cos(a2) * r, sin(a2) * r, 0), Vector3(0.3, 0.04, wdt), pale, Vector3(0, 0, a2))
	_cyl(m, Vector3.ZERO, 0.1, wdt + 0.5, wood, Vector3(PI * 0.5, 0, 0))

## Move the moving part of machine model `n` to where it is at second `t`.
static func animate(n: Node3D, t: float) -> void:
	if n.has_meta("spin"):
		(n.get_meta("spin") as Node3D).rotation.z = -t * 0.7
	if n.has_meta("rock"):
		(n.get_meta("rock") as Node3D).rotation.z = 0.28 * sin(t * 0.9)
	if n.has_meta("drop"):
		# lifted slowly by the peg, let fall at once
		var k := fmod(t * 0.55, 1.0)
		(n.get_meta("drop") as Node3D).rotation.z = -0.3 * (k / 0.85 if k < 0.85 else 1.0 - (k - 0.85) / 0.15) + 0.05
	if n.has_meta("turn"):
		(n.get_meta("turn") as Node3D).rotation.y = t * 0.35
