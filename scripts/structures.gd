class_name Structures
extends RefCounted
## The bigger things to do (the Lotus release, Part XV): built where a region's forest meets its open
## ground, like the smaller things of props.gd, but each a piece of architecture or a whole set-up
## that Lin Feng does something in or on, and Yue Ling with him:
##
##   * a pavilion (ting) with a stone bench across it, to sit in side by side and watch the land;
##   * a watchtower of four posts and a ladder, climbed to the top to look out over the region;
##   * an open-air stage (xitai) under a hip roof with a painted screen, for a sword form;
##   * a hot spring in a ring of rocks with a bamboo spout, to soak in;
##   * a millstone with a push bar, walked round and round;
##   * archery butts: a straw target, a bow rack and a quiver;
##   * a lantern green: a dancing floor under strings of red lanterns;
##   * a kite post, an armillary sphere for the stars, a table of sky lanterns, a jetty of lotus lanterns
##     on the water, a writing table with brush and ink, and a flat rock with a bamboo flute on it.
##
## Each model stands at the origin of its tile with its front (where it is used from) towards +z, like
## Props.model; the parts that move are kept under the node "mover" (Props.model's convention): the
## kite and its string, the armillary's rings, a sky lantern, a lotus lantern, the arrow in the target,
## the upper millstone and its bar, the strings of lanterns.  `HEIGHT` and `TOP` tell world.gd where
## a person stands on them.

const WOOD := Color("6a4a30")
const WOOD_L := Color("a87a4a")
const STONE := Color("b0a898")
const STONE_D := Color("7a7468")
const RED := Color("b8382a")
const TILE := Color("2f4a6a")
const BRONZE := Color("8a7038")
const PAPER := Color("f4ecd8")
const BAMBOO := Color("b8a860")

## the kinds built here (props.gd KINDS has what doing them means)
const KINDS := ["pavilion", "watchtower", "stage", "hot_spring", "millstone", "archery", "lantern_green", "kite", "armillary",
	"sky_lantern", "river_lantern", "calligraphy", "flute_rock"]
## the top of the watchtower's platform, and the stage's and the pavilion's floors (metres above the
## ground they stand on)
const TOWER_TOP := 4.28
## how far the watchtower's roof stands above its platform
const TOWER_ROOF := 2.35
const STAGE_TOP := 0.95
const PAVILION_TOP := 0.34
## where the millstone's bar is pushed from (metres from the stone's middle)
const MILL_R := 1.45
## where the target stands (model space)
const TARGET := Vector3(0, 1.1, -0.95)

## A structure's model (`theme`: the region's look, for its roof colour).
static func model(kind: String, theme: String) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	var mv := MB.new()
	var mv_at := Vector3.ZERO
	var mv_glow := false
	var roof_hex: String = {"court": "c89a30", "celestial": "c89a30", "starpalace": "4a5a9a", "guanghan": "8a9ab8", "wheel": "3a2a3a",
		"youdu": "2a2a3a", "juntian": "4a6aa8", "changhe": "4a6aa8", "village": "5a4a3a", "millet": "8a6a3a"}.get(theme, "2f6a5a")
	var st := {"roof": roof_hex, "roof2": Color(roof_hex).darkened(0.25).to_html(false), "column": "b83a2a", "wall": "efe4c8", "beam": "2a7a6a", "trim": "e8c860", "double": false}
	match kind:
		"pavilion":
			# Arch.pavilion's opening is on its -x side: turned a quarter so it faces the open ground
			var pb := MB.new()
			var pg := MB.new()
			Arch.pavilion(pb, pg, roof_hex, "b83a2a", 0.85)
			var xf := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO)
			b.merge(pb, xf)
			g.merge(pg, xf)
			# a stone bench across the middle, for two
			b.box(Vector3(0, PAVILION_TOP + 0.22, 0.05), Vector3(1.3, 0.08, 0.36), MB.tag(STONE, MB.STONE))
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 0.5, PAVILION_TOP + 0.1, 0.05), Vector3(0.16, 0.2, 0.3), MB.tag(STONE_D, MB.STONE))
			# a step up at the opening
			b.box(Vector3(0, 0.1, 1.15), Vector3(0.8, 0.2, 0.3), MB.tag(STONE_D, MB.STONE))
		"watchtower":
			var c := Vector3(0, 0, -0.45)
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					b.limb(c + Vector3(sx * 0.82, 0, sz * 0.82), c + Vector3(sx * 0.72, TOWER_TOP + TOWER_ROOF, sz * 0.72), 0.09, 0.07, MB.tag(WOOD, MB.WOOD), 6)
					b.box(c + Vector3(sx * 0.82, 0.12, sz * 0.82), Vector3(0.32, 0.24, 0.32), MB.tag(STONE_D, MB.STONE))
			# cross braces on the sides and the back
			for lv in 2:
				var y0 := 0.4 + lv * 1.9
				var y1 := y0 + 1.8
				for s2: float in [-1.0, 1.0]:
					b.limb(c + Vector3(s2 * 0.8, y0, -0.8), c + Vector3(-s2 * 0.78, y1, -0.78), 0.035, 0.035, MB.tag(WOOD_L, MB.WOOD), 4)
					b.limb(c + Vector3(s2 * 0.8, y0, 0.8), c + Vector3(s2 * 0.8, y1, -0.8), 0.035, 0.035, MB.tag(WOOD_L, MB.WOOD), 4)
			# the platform, its railing and a little roof
			b.box(c + Vector3(0, TOWER_TOP - 0.08, 0), Vector3(1.95, 0.16, 1.95), MB.tag(WOOD_L, MB.WOOD))
			for k in 4:
				var a := TAU * k / 4.0
				var d := Vector3(sin(a), 0, cos(a))
				var sd := Vector3(cos(a), 0, -sin(a))
				var mid := c + d * 0.95 + Vector3(0, TOWER_TOP + 0.55, 0)
				if k != 0:
					b.limb(mid - sd * 0.95, mid + sd * 0.95, 0.035, 0.035, MB.tag(RED, MB.WOOD), 5)
				b.limb(mid - sd * 0.95 - Vector3(0, 0.25, 0), mid + sd * 0.95 - Vector3(0, 0.25, 0), 0.025, 0.025, MB.tag(RED, MB.WOOD), 5)
			# (the roof high enough over the platform for somebody to stand under it and look out)
			b.box(c + Vector3(0, TOWER_TOP + TOWER_ROOF - 0.05, 0), Vector3(1.75, 0.1, 1.75), MB.tag(WOOD, MB.WOOD))
			b.cone(c + Vector3(0, TOWER_TOP + TOWER_ROOF, 0), 1.45, 0.85, MB.tag(TILE, MB.STONE), Vector3(0, PI / 4, 0), 4)
			b.limb(c + Vector3(0, TOWER_TOP + TOWER_ROOF + 0.8, 0), c + Vector3(0, TOWER_TOP + TOWER_ROOF + 1.7, 0), 0.025, 0.02, MB.tag(WOOD, MB.WOOD), 5)
			b.leaf(c + Vector3(0, TOWER_TOP + TOWER_ROOF + 1.65, 0), c + Vector3(0.6, TOWER_TOP + TOWER_ROOF + 1.55, 0.05), 0.18, MB.tag(RED, MB.CLOTH), Vector3(0, 1, 0))
			g.ball(c + Vector3(0, TOWER_TOP + TOWER_ROOF - 0.3, 0), 0.12, Color(1.0, 0.75, 0.4, 0.8), true)
			# the ladder up the front
			for s3: float in [-1.0, 1.0]:
				b.limb(Vector3(s3 * 0.26, 0, 0.7), Vector3(s3 * 0.26, TOWER_TOP + 0.6, 0.42), 0.035, 0.035, MB.tag(WOOD_L, MB.WOOD), 5)
			for r in 13:
				var ry := 0.3 + r * 0.33
				var rz := 0.7 - 0.28 * ry / (TOWER_TOP + 0.6)
				b.limb(Vector3(-0.26, ry, rz), Vector3(0.26, ry, rz), 0.022, 0.022, MB.tag(WOOD, MB.WOOD), 4)
		"stage":
			var c2 := Vector3(0, 0, -0.55)
			b.box(c2 + Vector3(0, STAGE_TOP * 0.5, 0), Vector3(3.4, STAGE_TOP, 2.6), MB.tag(STONE_D, MB.STONE))
			b.box(c2 + Vector3(0, STAGE_TOP * 0.55, 1.31), Vector3(3.2, STAGE_TOP * 0.7, 0.03), MB.tag(RED, MB.WOOD))
			for k2 in 5:
				g.box(c2 + Vector3(-1.2 + k2 * 0.6, STAGE_TOP * 0.55, 1.33), Vector3(0.36, 0.3, 0.01), Color(1.0, 0.82, 0.4, 0.55))
			b.box(c2 + Vector3(0, STAGE_TOP + 0.02, 0), Vector3(3.3, 0.05, 2.5), MB.tag(WOOD_L, MB.WOOD))
			var ch := 2.5
			for sx2: float in [-1.0, 1.0]:
				for sz2: float in [-1.0, 1.0]:
					var cp := c2 + Vector3(sx2 * 1.5, STAGE_TOP, sz2 * 1.1)
					b.cyl(cp + Vector3(0, ch * 0.5, 0), 0.1, ch, MB.tag(RED, MB.WOOD), Vector3.ZERO, 10)
					Arch._dougong(b, cp + Vector3(0, ch, 0), MB.tag(Color("e8c860"), MB.METAL), MB.tag(Color("2a7a6a"), MB.WOOD), MB.tag(RED, MB.WOOD))
			# the painted screen at the back, with its two doors (the "out of the general's tent" door and
			# the "into the general's tent" one)
			b.box(c2 + Vector3(0, STAGE_TOP + 1.15, -1.12), Vector3(3.0, 2.3, 0.08), MB.tag(Color("a8302a"), MB.WOOD))
			for sx3: float in [-1.0, 1.0]:
				b.box(c2 + Vector3(sx3 * 1.05, STAGE_TOP + 0.85, -1.07), Vector3(0.55, 1.6, 0.03), MB.tag(Color("2a5a4a"), MB.CLOTH))
			b.sph(c2 + Vector3(0, STAGE_TOP + 1.4, -1.07), Vector3(0.55, 0.55, 0.02), MB.tag(Color("e8c860"), MB.METAL))
			b.sph(c2 + Vector3(0, STAGE_TOP + 1.4, -1.06), Vector3(0.38, 0.38, 0.02), MB.tag(Color("2a7a6a"), MB.CLOTH))
			b.box(c2 + Vector3(0, STAGE_TOP + ch - 0.1, 0), Vector3(3.3, 0.18, 2.5), MB.tag(Color("2a7a6a"), MB.WOOD))
			Arch.hip_roof(b, g, c2 + Vector3(0, STAGE_TOP + ch + 0.2, 0), 1.6, 1.2, 0.55, 1.05, st, true)
			# steps up at the front, and red lanterns hung from the front eave
			for k3 in 3:
				b.box(Vector3(0, 0.15 + k3 * 0.3, 1.05 - k3 * 0.18), Vector3(1.0, 0.3, 0.2), MB.tag(STONE, MB.STONE))
			for sx4: float in [-1.0, 1.0]:
				var lp := c2 + Vector3(sx4 * 1.5, STAGE_TOP + ch - 0.35, 1.35)
				b.limb(lp + Vector3(0, 0.3, 0), lp + Vector3(0, 0.18, 0), 0.01, 0.01, MB.tag(Color("6a5a40"), MB.METAL), 4)
				g.sph(lp, Vector3(0.16, 0.2, 0.16), Color(1.0, 0.35, 0.25, 0.9))
		"hot_spring":
			var c3 := Vector3(0, 0, -0.25)
			var rng := RandomNumberGenerator.new()
			rng.seed = 3131
			for k4 in 16:
				var a2 := TAU * k4 / 16.0
				var rr := 1.25 + rng.randf_range(-0.06, 0.08)
				b.sph(c3 + Vector3(cos(a2) * rr, 0.12 + rng.randf() * 0.08, sin(a2) * rr), Vector3(0.3, 0.26 + rng.randf() * 0.12, 0.26), MB.tag(STONE.darkened(rng.randf() * 0.25), MB.STONE), Vector3(0, a2, 0))
			b.disc(c3 + Vector3(0, -0.25, 0), 1.15, MB.tag(Color("3a4a48"), MB.STONE), 20)
			g.disc(c3 + Vector3(0, 0.2, 0), 1.12, Color(0.42, 0.78, 0.76, 0.75), 20)
			# the bamboo spout from the rocks behind, and its little fall of water
			b.sph(c3 + Vector3(0.1, 0.55, -1.45), Vector3(0.45, 0.6, 0.35), MB.tag(STONE_D, MB.STONE))
			b.limb(c3 + Vector3(0.1, 0.95, -1.5), c3 + Vector3(0.1, 0.75, -0.95), 0.05, 0.05, MB.tag(BAMBOO, MB.WOOD), 6)
			g.limb(c3 + Vector3(0.1, 0.72, -0.92), c3 + Vector3(0.1, 0.22, -0.85), 0.03, 0.05, Color(0.7, 0.9, 0.95, 0.6), 5)
			# a bamboo screen at the side and a stone lantern
			for k5 in 7:
				b.limb(Vector3(1.55, 0, -0.9 + k5 * 0.2), Vector3(1.55, 1.5, -0.9 + k5 * 0.2), 0.035, 0.035, MB.tag(BAMBOO, MB.WOOD), 5)
			b.limb(Vector3(1.55, 1.2, -1.0), Vector3(1.55, 1.2, 0.4), 0.03, 0.03, MB.tag(WOOD, MB.WOOD), 4)
			b.box(Vector3(-1.6, 0.4, -0.6), Vector3(0.22, 0.8, 0.22), MB.tag(STONE, MB.STONE))
			b.box(Vector3(-1.6, 0.9, -0.6), Vector3(0.38, 0.26, 0.38), MB.tag(STONE.lightened(0.05), MB.STONE))
			b.cone(Vector3(-1.6, 1.1, -0.6), 0.36, 0.25, MB.tag(STONE_D, MB.STONE), Vector3(0, PI / 4, 0), 4)
			g.box(Vector3(-1.6, 0.9, -0.6), Vector3(0.2, 0.14, 0.4), Color(1.0, 0.75, 0.4, 0.8))
		"millstone":
			b.lathe(Vector3.ZERO, [Vector2(0.8, 0.0), Vector2(0.8, 0.42), Vector2(0.74, 0.48), Vector2(0.66, 0.5)], MB.tag(STONE_D, MB.STONE), 18)
			b.torus(Vector3(0, 0.46, 0), 0.72, 0.03, MB.tag(STONE_D.darkened(0.1), MB.STONE))
			mv.cyl(Vector3(0, 0.18, 0), 0.56, 0.36, MB.tag(STONE, MB.STONE), Vector3.ZERO, 18)
			mv.disc(Vector3(0, 0.37, 0), 0.1, MB.tag(Color("3a342c"), MB.STONE), 10)
			mv.limb(Vector3(0.4, 0.25, 0), Vector3(MILL_R - 0.05, 0.55, 0), 0.05, 0.045, MB.tag(WOOD_L, MB.WOOD), 6)
			mv.limb(Vector3(MILL_R - 0.2, 0.55, -0.12), Vector3(MILL_R - 0.2, 0.55, 0.12), 0.04, 0.04, MB.tag(WOOD, MB.WOOD), 5)
			mv_at = Vector3(0, 0.5, 0)
			# sacks of grain and a sieve, and the white of the flour on the ground
			for k6 in 3:
				b.sph(Vector3(-1.2 + k6 * 0.32, 0.25, -1.05 - (k6 % 2) * 0.2), Vector3(0.2, 0.28, 0.18), MB.tag(Color("c8b078"), MB.CLOTH))
			b.torus(Vector3(1.1, 0.06, -1.0), 0.22, 0.04, MB.tag(BAMBOO, MB.WOOD))
			b.disc(Vector3(0, 0.505, 0), 0.62, MB.tag(Color("eae4d8"), MB.CLOTH), 18)
		"archery":
			var tc := TARGET
			b.cyl(tc, 0.56, 0.26, MB.tag(Color("c8b070"), MB.HAIR), Vector3(PI * 0.5, 0, 0), 20)
			for ring in [[0.5, Color("f0ece0")], [0.38, Color("c8302a")], [0.26, Color("f0ece0")], [0.15, Color("e8b830")]]:
				b.cyl(tc + Vector3(0, 0, 0.13 + 0.01 * (0.5 - float(ring[0]))), float(ring[0]), 0.012, MB.tag(ring[1], MB.CLOTH), Vector3(PI * 0.5, 0, 0), 20)
			for s4: float in [-1.0, 1.0]:
				b.limb(tc + Vector3(s4 * 0.35, -0.3, -0.05), Vector3(s4 * 0.55, 0, tc.z + 0.25), 0.035, 0.035, MB.tag(WOOD, MB.WOOD), 5)
			b.limb(tc + Vector3(0, -0.3, -0.12), Vector3(0, 0, tc.z - 0.55), 0.035, 0.035, MB.tag(WOOD, MB.WOOD), 5)
			# a rack of bows and a quiver at the side
			for s5: float in [-1.0, 1.0]:
				b.limb(Vector3(1.3, 0, -0.2 + s5 * 0.35), Vector3(1.3, 1.3, -0.2 + s5 * 0.35), 0.04, 0.04, MB.tag(WOOD, MB.WOOD), 5)
			b.limb(Vector3(1.3, 1.1, -0.6), Vector3(1.3, 1.1, 0.2), 0.03, 0.03, MB.tag(WOOD, MB.WOOD), 4)
			for k7 in 2:
				b.arc(Vector3(1.25, 0.65, -0.35 + k7 * 0.3), 0.55, 0.035, -PI * 0.38, PI * 0.38, MB.tag(Color("5a3a24"), MB.WOOD), 10, Vector3(0, PI * 0.5, PI * 0.5))
			b.lathe(Vector3(-1.2, 0, -0.2), [Vector2(0.11, 0.0), Vector2(0.12, 0.7), Vector2(0.13, 0.72)], MB.tag(Color("7a3a24"), MB.CLOTH), 10)
			for k8 in 5:
				b.limb(Vector3(-1.2 + (k8 - 2) * 0.03, 0.6, -0.2), Vector3(-1.22 + (k8 - 2) * 0.05, 1.05, -0.2), 0.008, 0.008, MB.tag(WOOD_L, MB.WOOD), 3)
				b.leaf(Vector3(-1.22 + (k8 - 2) * 0.05, 0.95, -0.2), Vector3(-1.22 + (k8 - 2) * 0.05, 1.08, -0.2), 0.03, MB.tag(Color("f0f0f0"), MB.CLOTH), Vector3(1, 0, 0))
			# the arrow that lands (shown once he has shot)
			mv.limb(Vector3(0, 0, 0), Vector3(0, 0, 0.75), 0.01, 0.01, MB.tag(WOOD_L, MB.WOOD), 4)
			mv.leaf(Vector3(0, 0, 0.6), Vector3(0, 0, 0.78), 0.035, MB.tag(Color("f0f0f0"), MB.CLOTH), Vector3(1, 0, 0))
			mv.leaf(Vector3(0, 0, 0.6), Vector3(0, 0, 0.78), 0.035, MB.tag(Color("f0f0f0"), MB.CLOTH), Vector3(0, 1, 0))
			mv_at = tc + Vector3(0.06, 0.05, 0.12)
		"lantern_green":
			b.disc(Vector3(0, 0.03, -0.6), 1.35, MB.tag(STONE, MB.STONE), 20)
			b.torus(Vector3(0, 0.04, -0.6), 1.35, 0.05, MB.tag(STONE_D, MB.STONE))
			for k9 in 8:
				var a3 := TAU * k9 / 8.0
				b.box(Vector3(cos(a3) * 0.75, 0.035, -0.6 + sin(a3) * 0.75), Vector3(0.3, 0.01, 0.06), MB.tag(RED, MB.STONE), Vector3(0, -a3, 0))
			var poles := [Vector3(-1.45, 0, 0.3), Vector3(1.45, 0, 0.3), Vector3(1.45, 0, -1.5), Vector3(-1.45, 0, -1.5)]
			for pp in poles:
				b.limb(pp, (pp as Vector3) + Vector3(0, 2.7, 0), 0.05, 0.04, MB.tag(RED, MB.WOOD), 6)
				b.ball((pp as Vector3) + Vector3(0, 2.75, 0), 0.07, MB.tag(Color("e8c860"), MB.METAL), true)
			# the strings of lanterns (they sway)
			for k10 in 4:
				var p0: Vector3 = poles[k10] + Vector3(0, 2.6, 0)
				var p1: Vector3 = poles[(k10 + 1) % 4] + Vector3(0, 2.6, 0)
				for j in 6:
					var t := (j + 0.5) / 6.0
					var lp2 := p0.lerp(p1, t) - Vector3(0, sin(t * PI) * 0.35, 0)
					var pj := p0.lerp(p1, j / 6.0) - Vector3(0, sin(j / 6.0 * PI) * 0.35, 0)
					mv.limb(pj - Vector3(0, 2.6, 0) + Vector3(0, 0, 0.6), lp2 - Vector3(0, 2.6, 0) + Vector3(0, 0, 0.6), 0.008, 0.008, MB.tag(Color("6a5a40"), MB.CLOTH), 3)
					mv.sph(lp2 - Vector3(0, 2.6 + 0.16, 0) + Vector3(0, 0, 0.6), Vector3(0.11, 0.14, 0.11), Color(1.0, 0.32 + 0.1 * (j % 2), 0.22, 0.95))
			mv_at = Vector3(0, 2.6, -0.6)
			mv_glow = true
		"kite":
			b.limb(Vector3(0.7, 0, -0.35), Vector3(0.7, 1.7, -0.35), 0.06, 0.05, MB.tag(WOOD, MB.WOOD), 6)
			b.cyl(Vector3(0.7, 1.05, -0.24), 0.09, 0.1, MB.tag(WOOD_L, MB.WOOD), Vector3(PI * 0.5, 0, 0), 10)
			# two kites leaning on the post: a swallow and a butterfly
			b.leaf(Vector3(0.35, 0.05, -0.55), Vector3(0.3, 1.1, -0.58), 0.38, MB.tag(Color("d8382a"), MB.CLOTH), Vector3(1, 0, 0.2))
			b.leaf(Vector3(1.05, 0.05, -0.55), Vector3(1.1, 0.95, -0.58), 0.32, MB.tag(Color("3a7ac8"), MB.CLOTH), Vector3(1, 0, -0.2))
			b.limb(Vector3(0.3, 1.1, -0.56), Vector3(0.36, 0.3, -0.5), 0.006, 0.006, MB.tag(Color("e8c860"), MB.CLOTH), 3)
			# the kite that flies: a swallow, its two tail streamers, and a string (scaled to its length
			# by world.gd, along -y)
			mv.leaf(Vector3(0, -0.35, 0), Vector3(0, 0.45, 0), 0.45, MB.tag(Color("d8382a"), MB.CLOTH), Vector3(1, 0, 0))
			mv.leaf(Vector3(-0.42, 0.05, 0.0), Vector3(0.42, 0.05, 0.0), 0.12, MB.tag(Color("f0d050"), MB.CLOTH), Vector3(0, 1, 0))
			for s6: float in [-1.0, 1.0]:
				mv.leaf(Vector3(s6 * 0.06, -0.3, 0), Vector3(s6 * 0.25, -1.1, 0.0), 0.06, MB.tag(Color("f0f0e0"), MB.CLOTH), Vector3(1, 0, 0))
			mv_at = Vector3(0.7, 1.7, -0.35)
		"armillary":
			b.box(Vector3(0, 0.3, -0.35), Vector3(0.9, 0.6, 0.9), MB.tag(STONE_D, MB.STONE))
			b.lathe(Vector3(0, 0.6, -0.35), [Vector2(0.16, 0.0), Vector2(0.1, 0.3), Vector2(0.14, 0.45), Vector2(0.06, 0.55)], MB.tag(BRONZE, MB.METAL), 10)
			for k11 in 4:
				var a4 := TAU * k11 / 4.0 + PI / 4.0
				b.limb(Vector3(cos(a4) * 0.36, 0.6, -0.35 + sin(a4) * 0.36), Vector3(cos(a4) * 0.12, 0.95, -0.35 + sin(a4) * 0.12), 0.03, 0.025, MB.tag(Color("4a8a6a"), MB.METAL), 5)
			mv.torus(Vector3.ZERO, 0.55, 0.025, MB.tag(BRONZE.lightened(0.1), MB.METAL), Vector3(PI * 0.5, 0, 0))
			mv.torus(Vector3.ZERO, 0.52, 0.022, MB.tag(BRONZE, MB.METAL), Vector3(PI * 0.5, PI * 0.5, 0))
			mv.torus(Vector3.ZERO, 0.5, 0.02, MB.tag(BRONZE.lightened(0.2), MB.METAL), Vector3(0.41, 0, 0))
			mv.limb(Vector3(0, -0.62, 0.0), Vector3(0, 0.62, 0.0), 0.012, 0.012, MB.tag(BRONZE.darkened(0.2), MB.METAL), 4)
			mv.ball(Vector3.ZERO, 0.12, MB.tag(Color("4aa88a"), MB.STONE))
			mv_at = Vector3(0, 1.45, -0.35)
			# a star chart cut in a stone slab in front
			b.box(Vector3(0.65, 0.06, 0.3), Vector3(0.6, 0.12, 0.5), MB.tag(STONE, MB.STONE), Vector3(0, 0.3, 0))
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 777
			for k12 in 9:
				g.sph_hi(Vector3(0.65 + rng2.randf_range(-0.24, 0.24), 0.125, 0.3 + rng2.randf_range(-0.18, 0.18)), Vector3.ONE * 0.018, Color(0.85, 0.9, 1.0, 0.9))
		"sky_lantern":
			b.box(Vector3(0, 0.36, -0.35), Vector3(1.1, 0.06, 0.55), MB.tag(WOOD, MB.WOOD))
			for s7: float in [-1.0, 1.0]:
				for s8: float in [-1.0, 1.0]:
					b.box(Vector3(s7 * 0.48, 0.17, -0.35 + s8 * 0.2), Vector3(0.06, 0.34, 0.06), MB.tag(WOOD, MB.WOOD))
			for k13 in 3:
				var lp3 := Vector3(-0.35 + k13 * 0.35, 0.4, -0.35)
				b.lathe(lp3, [Vector2(0.13, 0.0), Vector2(0.17, 0.12), Vector2(0.18, 0.3), Vector2(0.15, 0.4), Vector2(0.02, 0.42)], MB.tag(PAPER if k13 != 1 else Color("e85a3a"), MB.CLOTH), 10)
			b.lathe(Vector3(0.8, 0, -0.55), [Vector2(0.05, 0.0), Vector2(0.06, 0.35), Vector2(0.18, 0.45), Vector2(0.2, 0.5)], MB.tag(BRONZE, MB.METAL), 10)
			g.ball(Vector3(0.8, 0.52, -0.55), 0.1, Color(1.0, 0.55, 0.2, 0.9), true)
			# the lantern that goes up (shown while it rises)
			mv.lathe(Vector3.ZERO, [Vector2(0.15, 0.0), Vector2(0.2, 0.14), Vector2(0.21, 0.36), Vector2(0.17, 0.48), Vector2(0.02, 0.5)], Color(1.0, 0.68, 0.35, 0.92), 10)
			mv_at = Vector3(0, 1.6, 0.4)
			mv_glow = true
		"river_lantern":
			# in the water, like the fishing spot: the end of a little jetty with the lanterns stacked on it
			for s9: float in [-1.0, 1.0]:
				b.cyl(Vector3(s9 * 0.5, -0.15, 0.6), 0.07, 0.8, MB.tag(WOOD, MB.WOOD), Vector3.ZERO, 6)
			b.box(Vector3(0, 0.25, 0.75), Vector3(1.3, 0.08, 0.9), MB.tag(WOOD_L, MB.WOOD))
			for k14 in 3:
				var lc := Vector3(-0.35 + k14 * 0.3, 0.3, 0.95)
				for pt in 8:
					var a5 := TAU * pt / 8.0
					b.leaf(lc, lc + Vector3(cos(a5) * 0.12, 0.08, sin(a5) * 0.12), 0.05, MB.tag(Color("f0a0c0"), MB.CLOTH), Vector3(-sin(a5), 0, cos(a5)))
				g.ball(lc + Vector3(0, 0.05, 0), 0.03, Color(1.0, 0.8, 0.4, 0.95), true)
			for pt2 in 8:
				var a6 := TAU * pt2 / 8.0
				mv.leaf(Vector3.ZERO, Vector3(cos(a6) * 0.14, 0.1, sin(a6) * 0.14), 0.06, Color(1.0, 0.62, 0.78, 0.92), Vector3(-sin(a6), 0, cos(a6)))
			mv.ball(Vector3(0, 0.06, 0), 0.035, Color(1.0, 0.85, 0.45, 1.0))
			mv_at = Vector3(0, Terrain3D.WATER_Y + 0.02, 0.2)
			mv_glow = true
		"calligraphy":
			b.box(Vector3(0, 0.62, -0.25), Vector3(1.2, 0.06, 0.6), MB.tag(Color("3a2418"), MB.WOOD))
			for s10: float in [-1.0, 1.0]:
				b.box(Vector3(s10 * 0.52, 0.3, -0.25), Vector3(0.08, 0.6, 0.5), MB.tag(Color("3a2418"), MB.WOOD))
			b.box(Vector3(0.05, 0.655, -0.2), Vector3(0.55, 0.006, 0.38), MB.tag(PAPER, MB.CLOTH))
			for k15 in 6:
				b.box(Vector3(0.22 - (k15 / 3) * 0.2, 0.66, -0.32 + (k15 % 3) * 0.12), Vector3(0.07, 0.004, 0.07), MB.tag(Color("1a1a1e"), MB.CLOTH))
			b.box(Vector3(-0.42, 0.665, -0.25), Vector3(0.18, 0.035, 0.26), MB.tag(Color("2a2a2e"), MB.STONE))
			b.box(Vector3(0.48, 0.68, -0.42), Vector3(0.06, 0.06, 0.2), MB.tag(Color("4a6a4a"), MB.STONE))
			for k16 in 3:
				b.limb(Vector3(0.44 + k16 * 0.02, 0.7, -0.5), Vector3(0.44 + k16 * 0.02, 0.7, -0.22), 0.008, 0.008, MB.tag(BAMBOO, MB.WOOD), 4)
			# a hanging scroll on a stand behind
			for s11: float in [-1.0, 1.0]:
				b.limb(Vector3(s11 * 0.4, 0, -0.85), Vector3(s11 * 0.4, 2.0, -0.85), 0.03, 0.03, MB.tag(WOOD, MB.WOOD), 5)
			b.limb(Vector3(-0.45, 1.95, -0.85), Vector3(0.45, 1.95, -0.85), 0.025, 0.025, MB.tag(WOOD, MB.WOOD), 5)
			b.box(Vector3(0, 1.3, -0.84), Vector3(0.5, 1.2, 0.01), MB.tag(PAPER, MB.CLOTH))
			for k17 in 4:
				b.box(Vector3(0, 1.75 - k17 * 0.27, -0.83), Vector3(0.16 + 0.05 * (k17 % 2), 0.16, 0.005), MB.tag(Color("1a1a1e"), MB.CLOTH))
			b.box(Vector3(0.14, 0.85, -0.83), Vector3(0.06, 0.06, 0.005), MB.tag(RED, MB.CLOTH))
		"flute_rock":
			b.sph(Vector3(0, 0.25, -0.2), Vector3(0.85, 0.36, 0.68), MB.tag(STONE, MB.STONE), Vector3(0, 0.3, 0))
			b.sph(Vector3(0.65, 0.18, -0.55), Vector3(0.38, 0.3, 0.34), MB.tag(STONE_D, MB.STONE))
			b.limb(Vector3(-0.32, 0.6, 0.0), Vector3(0.3, 0.6, -0.1), 0.022, 0.022, MB.tag(BAMBOO, MB.WOOD), 6)
			for k18 in 6:
				b.ball(Vector3(-0.18 + k18 * 0.07, 0.62, -0.03 - k18 * 0.012), 0.008, MB.tag(Color("2a2018"), MB.WOOD))
			b.leaf(Vector3(0.3, 0.6, -0.1), Vector3(0.36, 0.38, -0.02), 0.03, MB.tag(RED, MB.CLOTH), Vector3(1, 0, 0))
			for k19 in 6:
				b.limb(Vector3(-0.85 + k19 * 0.12, 0, -0.9), Vector3(-0.9 + k19 * 0.14, 2.2 + (k19 % 2) * 0.5, -0.95), 0.04, 0.03, MB.tag(Color("6a9a4a"), MB.WOOD), 5)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not mv.is_empty():
		var mover := Node3D.new()
		mover.name = "mover"
		mover.position = mv_at
		root.add_child(mover)
		MB.mesh_node(mover, mv.build(MB.mat_glow() if mv_glow else MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.set_meta("mover", mover)
		root.set_meta("mover_at", mv_at)
		if kind == "kite":
			# the kite's string: a unit length down -y, stretched to the post by world.gd
			var sb := MB.new()
			sb.limb(Vector3.ZERO, Vector3(0, -1, 0), 0.006, 0.006, MB.tag(Color("f0f0f0"), MB.CLOTH), 3)
			var sn := MB.mesh_node(root, sb.build(MB.mat_plain()))
			sn.name = "string"
			sn.visible = false
			root.set_meta("string", sn)
		if kind in ["sky_lantern", "river_lantern", "archery", "kite"]:
			# shown only while (or once) it is used
			mover.visible = false
	return root

## Something more in the hero's (or Yue Ling's) hand for the Lotus release's clips, in the hand bone's
## own space (Props.held's convention); null for something Props.held makes.
static func held(what: String) -> Node3D:
	var b := MB.new()
	match what:
		"flute":
			b.limb(Vector3(0, -0.08, -0.32), Vector3(0, -0.08, 0.3), 0.012, 0.012, MB.tag(BAMBOO, MB.WOOD), 6)
			b.leaf(Vector3(0, -0.08, 0.3), Vector3(0, -0.22, 0.34), 0.02, MB.tag(RED, MB.CLOTH), Vector3(1, 0, 0))
		"reel":
			b.cyl(Vector3(0, -0.08, 0.0), 0.06, 0.12, MB.tag(WOOD_L, MB.WOOD), Vector3(0, 0, PI * 0.5), 10)
			b.limb(Vector3(0, -0.08, -0.08), Vector3(0, -0.08, 0.08), 0.012, 0.012, MB.tag(WOOD, MB.WOOD), 4)
		"sky_lantern":
			b.lathe(Vector3(0.12, -0.2, 0.0), [Vector2(0.15, 0.0), Vector2(0.2, 0.14), Vector2(0.21, 0.36), Vector2(0.17, 0.48), Vector2(0.02, 0.5)], MB.tag(PAPER, MB.CLOTH), 10)
		"brush":
			b.limb(Vector3(0, -0.06, -0.12), Vector3(0, -0.12, 0.14), 0.008, 0.008, MB.tag(BAMBOO, MB.WOOD), 4)
			b.cone(Vector3(0, -0.13, 0.17), 0.012, 0.05, MB.tag(Color("1a1a1e"), MB.HAIR), Vector3(PI * 0.5, 0, 0), 6)
		"bow":
			b.arc(Vector3(0, -0.08, 0.0), 0.62, 0.025, -PI * 0.36, PI * 0.36, MB.tag(Color("5a3a24"), MB.WOOD), 12, Vector3(PI * 0.5, 0, 0))
			b.limb(Vector3(0.55 * cos(PI * 0.36) - 0.62, -0.08, 0.62 * sin(PI * 0.36)), Vector3(0.55 * cos(PI * 0.36) - 0.62, -0.08, -0.62 * sin(PI * 0.36)), 0.004, 0.004, MB.tag(Color("f0f0e0"), MB.CLOTH), 3)
		_:
			return null
	var root := Node3D.new()
	MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

## The High Roads release (folk.gd): a camp of the people of the road, out in the land at the foot of
## a mountain.  A fire in a ring of stones (the campfire of props.gd, so its flames move like any
## other's), two logs to sit on, a lean-to of poles and oiled cloth with bedrolls under it, a pedlar's
## pole of boxes stood against a post, a stack of cut wood, and a light for the night.
static func camp(seed_: int) -> Node3D:
	var root := Node3D.new()
	root.name = "camp"
	var fire := Props.model("campfire", "")
	fire.scale = Vector3.ONE * 1.3
	root.add_child(fire)
	var b := MB.new()
	var wood := MB.tag(Color("5a4030"), MB.WOOD)
	var cloth := Color("8a6a48").lerp(Color("5a7a8a"), Terrain3D.hash2(seed_, 3, 1.0))
	# the lean-to: two forked poles, a ridge, a sloping sheet down to the ground behind
	var back := Vector3(0, 0, -4.2)
	for sx in [-1.5, 1.5]:
		b.limb(back + Vector3(sx, 0, 1.2), back + Vector3(sx, 1.75, 1.2), 0.05, 0.04, wood, 6)
		b.limb(back + Vector3(sx, 1.72, 1.2), back + Vector3(sx, 0.0, -0.9), 0.035, 0.03, wood, 5)
	b.limb(back + Vector3(-1.7, 1.75, 1.2), back + Vector3(1.7, 1.75, 1.2), 0.04, 0.04, wood, 6)
	b.quad4(back + Vector3(-1.6, 1.78, 1.25), back + Vector3(1.6, 1.78, 1.25), back + Vector3(1.6, 0.04, -0.95), back + Vector3(-1.6, 0.04, -0.95), cloth, cloth, cloth.darkened(0.2), cloth.darkened(0.2))
	b.quad4(back + Vector3(-1.6, 0.03, -0.96), back + Vector3(1.6, 0.03, -0.96), back + Vector3(1.6, 1.77, 1.24), back + Vector3(-1.6, 1.77, 1.24), cloth.darkened(0.3), cloth.darkened(0.3), cloth.darkened(0.15), cloth.darkened(0.15))
	# bedrolls under it
	for k in 3:
		var bx := -1.0 + k * 1.0
		b.box(back + Vector3(bx, 0.06, 0.25), Vector3(0.7, 0.1, 1.7), MB.tag(Color("b8a888").darkened(k * 0.08), MB.CLOTH))
		b.limb(back + Vector3(bx - 0.3, 0.17, 0.95), back + Vector3(bx + 0.3, 0.17, 0.95), 0.12, 0.12, MB.tag(Color("7a3a34").lerp(Color("3a5a7a"), k * 0.5), MB.CLOTH), 8)
	# the stack of cut wood, and the pedlar's pole and boxes
	for k2 in 7:
		var ly := 0.1 + float(k2 / 4) * 0.19
		var lz := -0.9 + float(k2 % 4) * 0.21 + float(k2 / 4) * 0.1
		b.limb(Vector3(2.85, ly, lz), Vector3(3.95, ly, lz), 0.1, 0.095, MB.tag(Color("6a4a30").darkened(Terrain3D.hash2(seed_, k2, 2.0) * 0.2), MB.WOOD), 6)
	b.limb(Vector3(-3.3, 0.0, -0.6), Vector3(-3.3, 1.5, -0.6), 0.045, 0.04, wood, 6)
	b.limb(Vector3(-3.25, 1.35, -1.5), Vector3(-3.25, 1.2, 0.3), 0.025, 0.025, MB.tag(Color("b89a5a"), MB.WOOD), 5)
	for k3 in 2:
		var bz := -1.4 + k3 * 1.6
		b.box(Vector3(-3.25, 0.28, bz), Vector3(0.5, 0.56, 0.5), MB.tag(Color("7a5030"), MB.WOOD))
		b.box(Vector3(-3.25, 0.58, bz), Vector3(0.54, 0.05, 0.54), MB.tag(Color("a03a2a"), MB.WOOD))
	# a pot on three sticks beside the fire
	for k4 in 3:
		var a := TAU * k4 / 3.0
		b.limb(Vector3(1.3 + cos(a) * 0.4, 0.0, 0.6 + sin(a) * 0.4), Vector3(1.3, 0.95, 0.6), 0.022, 0.02, wood, 5)
	b.sph(Vector3(1.3, 0.42, 0.6), Vector3(0.19, 0.16, 0.19), MB.tag(Color("2a2a2e"), MB.METAL))
	MB.mesh_node(root, b.build(MB.mat_scenery()))
	var lt := OmniLight3D.new()
	lt.light_color = Color(1.0, 0.62, 0.3)
	lt.light_energy = 2.8
	lt.omni_range = 9.5
	lt.position = Vector3(0, 0.9, 0)
	lt.shadow_enabled = false
	lt.distance_fade_enabled = true
	lt.distance_fade_begin = 40.0
	lt.distance_fade_length = 15.0
	root.add_child(lt)
	return root
