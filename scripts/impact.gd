class_name Impact
extends RefCounted
## The Sword's Wake (the Spring Thunder release): a blow in the open world reaches the world.
##
## Before this release the sword (F) only broke the things people leave about their towns
## (havoc.gd).  Now whatever it meets in the land answers it, by physics:
##
##   * a **tree** at the forest edge is cut through at the foot and falls the way a felled trunk
##     falls, as a rod about its stump (theta'' = 3g / 2L sin theta: a tall pine takes two seconds,
##     a sapling half of one), and when it meets the ground it breaks into logs (rigid bodies that
##     roll down the slope), its crown bursts into leaves and a stump is left; bushes, ferns, reeds
##     and flowers are cut and their leaves fly;
##   * a **rock** (a boulder, a slab, a spire, a crystal) shatters into rigid-body chunks with a cloud
##     of grit;
##   * **grass** is mown in an arc in front of the blade (the grass shader shortens every blade inside
##     the arc, and it grows back over a minute), and the clippings fly;
##   * **water** splashes and rings spread;
##   * a **pack of monsters** is knocked back off its feet, and the battle opens with it reeling:
##     every one of them has lost a share of its health before it can move, and the party acts first
##     (a **first strike**; a boss cannot be taken by surprise, and a pack two realms below scatters);
##   * the **sword qi** (G) is a crescent of qi the sword throws ahead: it flies seven tiles, doing all
##     of that to everything along its way, for an eighth of Lin Feng's qi.
##
## Felled trees and shattered rocks grow back by the next dawn (the land of a cultivation world mends
## quickly).  They are drawn and simulated only on screen; what the story needs (Part XVII's fallen
## trunks across the roads, ice jams, rockfalls and the clay Spring Ox) is game state: **obstacles**
## (entities of kind "obstacle", OBSTACLES below) that take so many blows and stay cleared, counted by
## the steps of kind "clear", so the bot and the tests see the same world.

## a pack struck first in the land opens the battle reeling: each foe has lost this share of its
## health, and the party moves first in the first round
const AMBUSH_HURT := 0.2
## seconds the struck pack is seen flying back before the battle begins (on screen only)
const AMBUSH_SHOW := 0.45
## the sword qi (G): its cost (a share of Lin Feng's qi), how far it flies (tiles) and how often
const WAVE_QI := 0.125
const WAVE_TILES := 7
const WAVE_COOL := 1.2
const WAVE_SPEED := 22.0
## mown grass grows back over this many seconds
const REGROW := 60.0

# ---------------------------------------------------------------- what a blow reaches
## The tiles a swing reaches, relative to where Lin Feng stands facing `f`: the two in front and the
## two either side of the first.
static func reach(f: Vector2i) -> Array:
	var side := Vector2i(-f.y, f.x)
	return [f, f * 2, f + side, f - side]

## The tiles the sword qi crosses, in order.
static func wave_path(f: Vector2i) -> Array:
	var out: Array = []
	for k in range(1, WAVE_TILES + 1):
		out.append(f * k)
	return out

# ---------------------------------------------------------------- felled and shattered (game state)
## The key of a tree, a plant or a rock of the scatter (scatter.gd) in a region's view.
static func key(layer: String, area: String, local: Vector2i, i: int) -> String:
	return "%s|%s|%d|%d|%d" % [layer, area, local.x, local.y, i]

## Whether the thing under `k` lies felled (it grows back at the first dawn after, Havoc.MEND_HOUR).
static func is_down(g, k: String) -> bool:
	if not g.felled.has(k):
		return false
	var at: float = float(g.felled[k])
	var grow: float = (floorf((at - Havoc.MEND_HOUR * 60.0) / 1440.0) + 1.0) * 1440.0 + Havoc.MEND_HOUR * 60.0
	if Havoc.now(g) >= grow:
		g.felled.erase(k)
		return false
	return true

static func fell(g, k: String) -> void:
	g.felled[k] = Havoc.now(g)
	g.felled_n += 1

# ---------------------------------------------------------------- obstacles of the story (Part XVII)
## What stands in the way: its name, how many blows clear it, the pieces it comes apart into (havoc.gd
## piece kinds) and their colour, and what is said when it goes.
const OBSTACLES := {
	"deadfall": {"n": "fallen trunk", "hits": 1, "piece": "log", "col": Color("6a4a30"), "n_p": 5, "puff": Color("e8eef4"),
		"hint": "A trunk the snow brought down lies across the way (F to cut through it)"},
	"boulder": {"n": "rockfall", "hits": 2, "piece": "rock", "col": Color("8a8478"), "n_p": 8, "puff": Color("b0a898"),
		"hint": "Rocks the frost broke off the hill block the way (F to break them)"},
	"ice": {"n": "ice jam", "hits": 2, "piece": "shard", "col": Color("cfe8f4"), "n_p": 9, "puff": Color("f0f8ff"),
		"hint": "Ice has jammed against the bank (F to break it up)"},
	"spring_ox": {"n": "Spring Ox", "hits": 5, "piece": "shard", "col": Color("b07850"), "n_p": 12, "puff": Color("e0c090"),
		"hint": "The clay Spring Ox, painted in the five colours (F to whip it with the willow switch)"},
	"petty": {"n": "paper petty man", "hits": 1, "piece": "paper", "col": Color("e8e0d0"), "n_p": 4, "puff": Color("f0e8d8"),
		"hint": "A paper petty man pinned under the bridge (F to beat it)"},
	"chain": {"n": "frozen chain", "hits": 3, "piece": "rock", "col": Color("9ab8c8"), "n_p": 7, "puff": Color("e8f4ff"),
		"hint": "A chain of black ice holds the dragon's head down (F to break it)"},
	# Part XVIII (the New Fire release): what a tired fire leaves, and what a wildfire eats
	"clinker": {"n": "clinker crust", "hits": 2, "piece": "rock", "col": Color("3a3432"), "n_p": 8, "puff": Color("8a8480"),
		"hint": "Clinker has crusted over the mouth of a casting pit (F to break it off)"},
	# Part XIX (the Hundred Works release): a gear-train that has locked solid across a lane
	"cogwork": {"n": "locked gear-train", "hits": 2, "piece": "rock", "col": Color("b8863a"), "n_p": 8, "puff": Color("c8b890"),
		"hint": "A train of bronze gears has locked solid across the lane (F to break it apart)"},
	"brush": {"n": "dry brush", "hits": 1, "piece": "log", "col": Color("9a8450"), "n_p": 5, "puff": Color("c8b890"),
		"hint": "A stand of brush as dry as tinder (F to cut it for the firebreak)"},
}

## A blow lands on obstacle `e`.  Returns "cleared" when it is the blow that clears it, "hit" when
## more are needed, "" when there is nothing there.
static func hit_obstacle(g, e: Dictionary) -> String:
	var id := str(e.id)
	if g.cleared.has(id):
		return ""
	var spec: Dictionary = OBSTACLES.get(str(e.what), {"hits": 1})
	var n := int(g.obstacle_hits.get(id, 0)) + 1
	g.obstacle_hits[id] = n
	# (the stone adze, works.gd, takes one blow off whatever stands in the road)
	if n < Works.blows(g, int(spec.hits)):
		return "hit"
	# (remembered with its kind and region: a "clear" step counts them, Game.cleared_count)
	g.cleared[id] = "%s|%s" % [str(e.what), str(e.area)]
	g.obstacle_hits.erase(id)
	return "cleared"

## The model of an obstacle (procedural, a few hundred triangles).
static func obstacle_model(what: String, theme_name: String = "") -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	match what:
		"deadfall":
			# a trunk lying across the way, snapped at one end, with broken branches and snow along its top
			var bark := MB.tag(Color("5a4030"), MB.WOOD)
			b.limb(Vector3(-1.5, 0.32, 0.1), Vector3(1.45, 0.26, -0.15), 0.3, 0.24, bark, 8)
			# the snapped end: pale splintered wood
			b.cone(Vector3(-1.58, 0.32, 0.1), 0.27, 0.3, MB.tag(Color("c8a070"), MB.WOOD), Vector3(0, 0, PI * 0.5), 8)
			for k in 4:
				var x := -1.0 + k * 0.7
				b.limb(Vector3(x, 0.4, 0.0), Vector3(x + 0.35, 0.95, 0.25 * (1 if k % 2 == 0 else -1)), 0.06, 0.02, bark, 4)
			b.sph(Vector3(0.0, 0.56, -0.02), Vector3(1.4, 0.07, 0.2), MB.tag(Color("eef4fa"), MB.STONE))
		"boulder":
			var rm := Rocks.mesh("boulder", 2, theme_name if theme_name != "" else "terraces")
			var mi := MeshInstance3D.new()
			mi.mesh = rm
			mi.scale = Vector3.ONE * 1.25
			root.add_child(mi)
			b.sph(Vector3(0.7, 0.18, 0.5), Vector3(0.32, 0.22, 0.3), MB.tag(Color("8a8478"), MB.STONE))
			b.sph(Vector3(-0.6, 0.14, 0.6), Vector3(0.26, 0.18, 0.24), MB.tag(Color("7a7468"), MB.STONE))
		"ice":
			# slabs of river ice heaved up against each other
			var ic := MB.tag(Color("d8eef8"), MB.CRYSTAL)
			var ic2 := MB.tag(Color("a8d0e8"), MB.CRYSTAL)
			b.box(Vector3(0.0, 0.35, 0.0), Vector3(1.6, 0.18, 1.1), ic, Vector3(0.35, 0.2, 0.1))
			b.box(Vector3(0.5, 0.55, -0.3), Vector3(1.0, 0.16, 0.9), ic2, Vector3(-0.5, 0.7, 0.2))
			b.box(Vector3(-0.55, 0.5, 0.35), Vector3(0.9, 0.15, 0.8), ic, Vector3(0.6, -0.4, -0.35))
			b.box(Vector3(0.1, 0.9, 0.1), Vector3(0.7, 0.12, 0.6), ic2, Vector3(0.9, 0.3, 0.5))
		"spring_ox":
			# the clay Spring Ox of Lichun, painted in the five colours (the year's weather is read from them)
			var clay := MB.tag(Color("b8885a"), MB.STONE)
			b.sph(Vector3(0, 0.95, 0), Vector3(0.55, 0.5, 0.95), MB.tag(Color("d8b060"), MB.STONE))
			b.sph(Vector3(0, 1.0, 0.25), Vector3(0.5, 0.42, 0.45), MB.tag(Color("c8302a"), MB.STONE))
			b.sph(Vector3(0, 1.0, -0.45), Vector3(0.5, 0.42, 0.42), MB.tag(Color("2a6a9a"), MB.STONE))
			b.sph(Vector3(0, 1.38, 0.05), Vector3(0.3, 0.12, 0.6), MB.tag(Color("f0ece0"), MB.STONE))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					b.limb(Vector3(0.3 * sx, 0.8, 0.55 * sz), Vector3(0.32 * sx, 0.0, 0.58 * sz), 0.12, 0.1, MB.tag(Color("2a2a2a"), MB.STONE), 6)
			b.sph(Vector3(0, 1.15, 1.05), Vector3(0.3, 0.3, 0.38), MB.tag(Color("3a8a4a"), MB.STONE))
			b.sph(Vector3(0, 1.02, 1.35), Vector3(0.2, 0.17, 0.12), clay)
			for sx2 in [-1.0, 1.0]:
				b.limb(Vector3(0.18 * sx2, 1.38, 1.05), Vector3(0.42 * sx2, 1.6, 1.0), 0.06, 0.02, MB.tag(Color("f0e8d0"), MB.STONE), 5)
			b.limb(Vector3(0, 1.1, -0.9), Vector3(0.08, 0.5, -1.1), 0.04, 0.03, clay, 4)
			# the wooden frame it is set on
			b.box(Vector3(0, 0.04, 0), Vector3(1.0, 0.08, 1.9), MB.tag(Color("6a4a2a"), MB.WOOD))
		"petty":
			# paper figures pinned to a board under the bridge
			b.box(Vector3(0, 0.7, 0), Vector3(1.0, 1.4, 0.08), MB.tag(Color("6a5038"), MB.WOOD))
			for k2 in 3:
				var x2 := -0.3 + k2 * 0.3
				b.box(Vector3(x2, 0.95, 0.06), Vector3(0.2, 0.36, 0.01), MB.tag(Color("f0ead8"), MB.CLOTH))
				b.sph(Vector3(x2, 1.2, 0.06), Vector3(0.07, 0.07, 0.01), MB.tag(Color("f0ead8"), MB.CLOTH))
				b.box(Vector3(x2, 0.6, 0.06), Vector3(0.05, 0.3, 0.01), MB.tag(Color("e05040"), MB.CLOTH))
		"clinker":
			# a casting pit's mouth crusted over: a ring of stone, a dome of black glassy slag, and a
			# dull glow where the fire shows through the cracks
			var slag := MB.tag(Color("2a2624"), MB.CRYSTAL)
			var slag2 := MB.tag(Color("4a423c"), MB.STONE)
			b.torus(Vector3(0, 0.14, 0), 0.82, 0.16, MB.tag(Color("6a6058"), MB.STONE))
			b.sph(Vector3(0, 0.2, 0), Vector3(0.72, 0.42, 0.72), slag)
			b.sph(Vector3(0.3, 0.42, 0.15), Vector3(0.3, 0.2, 0.28), slag2)
			b.sph(Vector3(-0.28, 0.4, -0.2), Vector3(0.26, 0.18, 0.3), slag2)
			b.sph(Vector3(0.05, 0.5, -0.3), Vector3(0.22, 0.16, 0.2), slag)
			for k4 in 5:
				var a4 := TAU * k4 / 5.0 + 0.3
				g.box(Vector3(cos(a4) * 0.4, 0.5, sin(a4) * 0.4), Vector3(0.36, 0.03, 0.03), Color(1.0, 0.45, 0.15, 0.85), Vector3(0.3, -a4, 0.5))
			g.ball(Vector3(0, 0.5, 0), 0.75, Color(1.0, 0.4, 0.15, 0.16), true)
		"brush":
			# a stand of summer-dry brush: bare grey stems and straw-coloured twigs
			var stem := MB.tag(Color("8a7450"), MB.WOOD)
			var twig := MB.tag(Color("c8b070"), MB.WOOD)
			for k5 in 9:
				var a5 := TAU * k5 / 9.0 + 0.2
				var r5 := 0.25 + 0.3 * float(k5 % 3) / 2.0
				var base5 := Vector3(cos(a5) * r5, 0.0, sin(a5) * r5)
				var top5 := base5 * 1.9 + Vector3(0, 1.3 + 0.35 * float(k5 % 2), 0)
				b.limb(base5, top5, 0.045, 0.012, stem, 4)
				b.limb(base5.lerp(top5, 0.55), base5.lerp(top5, 0.8) + Vector3(sin(a5) * 0.4, 0.2, -cos(a5) * 0.4), 0.02, 0.006, twig, 3)
				b.limb(base5.lerp(top5, 0.75), top5 + Vector3(-sin(a5) * 0.3, 0.1, cos(a5) * 0.3), 0.016, 0.005, twig, 3)
			b.sph(Vector3(0, 0.12, 0), Vector3(0.7, 0.12, 0.7), MB.tag(Color("b8a468"), MB.WOOD))
		"cogwork":
			# three meshed gears of bronze on a timber frame, jammed tooth to tooth
			var bz := MB.tag(Color("b8863a"), MB.METAL)
			var bz2 := MB.tag(Color("7a6a3a"), MB.METAL)
			b.box(Vector3(0, 0.1, 0), Vector3(2.0, 0.2, 0.5), MB.tag(Color("5a4030"), MB.WOOD))
			for gk in 3:
				var gc := Vector3(-0.72 + gk * 0.72, 0.62 + (0.22 if gk == 1 else 0.0), 0.0)
				var gr := 0.42 if gk != 1 else 0.34
				Machines._cyl(b, gc, gr, 0.14, bz if gk != 1 else bz2, Vector3(PI * 0.5, 0, 0), 12)
				Machines._cyl(b, gc, 0.07, 0.4, MB.tag(Color("3a3a40"), MB.METAL), Vector3(PI * 0.5, 0, 0), 6)
				for tk in 10:
					var ta := TAU * tk / 10.0 + gk * 0.3
					b.box(gc + Vector3(cos(ta), sin(ta), 0) * (gr + 0.05), Vector3(0.1, 0.1, 0.14), bz if gk != 1 else bz2, Vector3(0, 0, ta))
		"chain":
			var ice := MB.tag(Color("6a8aa0"), MB.CRYSTAL)
			for k3 in 6:
				var y3 := 0.3 + k3 * 0.42
				b.torus(Vector3(0, y3, 0), 0.22, 0.07, ice, Vector3(0, PI * 0.5 * float(k3 % 2), 0))
			b.cyl(Vector3(0, 0.1, 0), 0.5, 0.2, MB.tag(Color("3a4a58"), MB.STONE), Vector3.ZERO, 10)
			g.ball(Vector3(0, 1.4, 0), 0.6, Color(0.6, 0.85, 1.0, 0.25), true)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc()))
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

## An obstacle comes apart at `at`: its pieces fly from the blow and tumble on the ground (`ground`, a
## Callable giving the height at a point).  A blow that does not clear it yet only chips it.
static func obstacle_burst(parent: Node3D, what: String, at: Vector3, dir: Vector3, ground, cleared: bool) -> void:
	var spec: Dictionary = OBSTACLES.get(what, OBSTACLES.boulder)
	if not cleared:
		Fx3D.dust(parent, at + Vector3(0, 0.6, 0), spec.puff)
		Fx3D.sparks(parent, at + Vector3(0, 0.8, 0) - dir * 0.3, Color(1.0, 0.9, 0.7))
		return
	Havoc.burst(parent, "rubble", at, dir, ground, 1.2 if what != "petty" else 0.7, spec.col)
	if what in ["spring_ox", "ice", "chain", "deadfall", "clinker", "brush", "cogwork"]:
		Havoc.burst(parent, "rubble", at + Vector3(0, 0.4, 0), -dir, ground, 0.8, Color(spec.col).darkened(0.2))
	if what == "ice" or what == "chain":
		Fx3D.splash(parent, at + Vector3(0, 0.2, 0), Color(0.8, 0.92, 1.0), 0.9, 1.4)
	if what == "spring_ox":
		# the five colours fly, and the grain inside spills
		Fx3D.leaf_spiral(parent, at + Vector3(0, 1.0, 0), Color("e8c050"), 1.2)
	if what == "petty":
		Fx3D.leaf_spiral(parent, at + Vector3(0, 0.9, 0), Color("f0e8d8"), 1.0)
	Fx3D.dust(parent, at + Vector3(0, 0.4, 0), spec.puff)
	Fx3D.shockwave(parent, at + Vector3(0, 0.1, 0), Color(spec.puff), 3.0, 0.5)

# ---------------------------------------------------------------- the land answers (on screen)
## Hide or show one instance of a MultiMesh (a felled tree, a shattered rock).
static func hide_instance(mmi: MultiMeshInstance3D, i: int) -> void:
	var mm := mmi.multimesh
	var xf := mm.get_instance_transform(i)
	if xf.basis.get_scale().length() < 0.01:
		return
	var gone := Transform3D(Basis().scaled(Vector3.ONE * 0.0001), xf.origin - Vector3(0, 40, 0))
	mm.set_instance_transform(i, gone)
	# (the same tree as it is drawn from far off, Terrain3D._add_mm, goes with it)
	if mmi.has_meta("far"):
		(mmi.get_meta("far") as MultiMeshInstance3D).multimesh.set_instance_transform(i, gone)

static func show_instance(mmi: MultiMeshInstance3D, i: int, xf: Transform3D) -> void:
	mmi.multimesh.set_instance_transform(i, xf)
	if mmi.has_meta("far"):
		(mmi.get_meta("far") as MultiMeshInstance3D).multimesh.set_instance_transform(i, xf)

## The fall of a felled trunk: the angle of a rod of height `h` pivoting on its stump, from the nudge of
## the cut to lying flat, integrated once (theta'' = 3g / 2L sin theta).  Returns [seconds, angles at
## 60 steps a second].
static func fall_curve(h: float) -> Array:
	var th := 0.04
	var om := 0.55
	var k := 3.0 * 9.8 / (2.0 * maxf(0.6, h))
	var out: Array = [th]
	var dt := 1.0 / 60.0
	var secs := 0.0
	while th < PI * 0.5 - 0.06 and secs < 6.0:
		om += k * sin(th) * dt
		th += om * dt
		secs += dt
		out.append(minf(th, PI * 0.5 - 0.06))
	return [secs, out]

## A tree (instance `i` of `mmi`, a MultiMesh of the scatter) is cut through: it falls away from the
## blow (`dir`) about its stump, breaks into logs where it lands, its crown bursts into leaves and a
## stump is left (returned, so it can go when the tree grows back).
static func topple(parent: Node3D, mmi: MultiMeshInstance3D, i: int, dir: Vector3, ground: Callable) -> Node3D:
	var mm := mmi.multimesh
	var lxf := mm.get_instance_transform(i)
	var wxf := mmi.global_transform * lxf
	var col := mm.get_instance_color(i)
	var aabb := mm.mesh.get_aabb()
	var sc := wxf.basis.get_scale()
	var h := maxf(0.8, aabb.end.y * sc.y)
	var crown := maxf(0.4, maxf(aabb.size.x, aabb.size.z) * sc.x * 0.5)
	hide_instance(mmi, i)
	var base := wxf.origin
	# the falling trunk: the same mesh and colour, on a pivot at the stump
	var pivot := Node3D.new()
	pivot.position = base
	parent.add_child(pivot)
	var one := MultiMesh.new()
	one.transform_format = MultiMesh.TRANSFORM_3D
	one.use_colors = true
	one.mesh = mm.mesh
	one.instance_count = 1
	one.set_instance_transform(0, Transform3D(wxf.basis, Vector3.ZERO))
	one.set_instance_color(0, col)
	var vis := MultiMeshInstance3D.new()
	vis.multimesh = one
	pivot.add_child(vis)
	var d := Vector3(dir.x, 0.0, dir.z)
	d = d.normalized() if d.length() > 0.01 else Vector3(0, 0, 1)
	var axis := Vector3.UP.cross(d).normalized()
	var fc: Array = fall_curve(h)
	var secs: float = fc[0]
	var angles: Array = fc[1]
	var tw := pivot.create_tween()
	tw.tween_method(func(x: float) -> void:
		var j := clampi(int(x * 60.0), 0, angles.size() - 1)
		pivot.basis = Basis(axis, float(angles[j])), 0.0, secs, secs)
	tw.tween_callback(func() -> void:
		# it lands: the trunk breaks into logs that roll, the crown bursts, dust along its length
		var tip := base + d * h * 0.92
		var mid := base.lerp(tip, 0.45)
		Havoc.burst(parent, "woodpile", mid + Vector3(0, 0.2, 0), d, ground, 0.6, Color(0.45, 0.32, 0.2).lerp(col, 0.2))
		Fx3D.leaf_spiral(parent, base.lerp(tip, 0.8) + Vector3(0, 0.6, 0), col.lerp(Color(0.4, 0.7, 0.3), 0.6), 1.4)
		Fx3D.leaf_spiral(parent, base.lerp(tip, 0.6) + Vector3(0, 0.4, 0), col.lerp(Color(0.5, 0.75, 0.3), 0.5), 1.2)
		Fx3D.dust(parent, mid, Color(0.75, 0.68, 0.55))
		Fx3D.dust(parent, tip, Color(0.75, 0.68, 0.55))
		Fx3D.shockwave(parent, mid + Vector3(0, 0.1, 0), Color(0.8, 0.72, 0.58), crown * 2.5, 0.5)
		pivot.queue_free())
	# the stump
	var sb := MB.new()
	var r0 := clampf(h * 0.045, 0.12, 0.42)
	sb.lathe(Vector3.ZERO, [Vector2(r0 * 1.25, 0.0), Vector2(r0, 0.12), Vector2(r0 * 0.95, r0 * 1.3)], MB.tag(Color("5a4030"), MB.WOOD), 9)
	sb.cyl(Vector3(0, r0 * 1.3, 0), r0 * 0.92, 0.02, MB.tag(Color("d8b888"), MB.WOOD), Vector3.ZERO, 9)
	var stump := Node3D.new()
	MB.mesh_node(stump, sb.build(MB.mat_vc()))
	stump.position = base
	parent.add_child(stump)
	return stump

## A bush, a fern, reeds or flowers are cut: hidden, and their leaves fly.
static func cut_plant(parent: Node3D, mmi: MultiMeshInstance3D, i: int, dir: Vector3) -> void:
	var mm := mmi.multimesh
	var wxf := mmi.global_transform * mm.get_instance_transform(i)
	var col := mm.get_instance_color(i)
	hide_instance(mmi, i)
	Fx3D.leaf_spiral(parent, wxf.origin + Vector3(0, 0.5, 0) + dir * 0.3, col.lerp(Color(0.45, 0.7, 0.3), 0.5), 0.9)

## A rock shatters into chunks with a cloud of grit.
static func shatter(parent: Node3D, mmi: MultiMeshInstance3D, i: int, dir: Vector3, ground: Callable) -> void:
	var mm := mmi.multimesh
	var wxf := mmi.global_transform * mm.get_instance_transform(i)
	var col := mm.get_instance_color(i)
	var big := wxf.basis.get_scale().x
	hide_instance(mmi, i)
	var stone := Color(0.55, 0.53, 0.5) * col
	stone.a = 1.0
	var at := wxf.origin + Vector3(0, 0.2 * big, 0)
	Havoc.burst(parent, "rubble", at, dir, ground, 0.9 + 0.4 * big, stone)
	if big > 0.9:
		Havoc.burst(parent, "rubble", at + Vector3(0, 0.3, 0), -dir, ground, 0.7, stone.darkened(0.15))
	Fx3D.dust(parent, at, Color(0.72, 0.68, 0.6))
	Fx3D.sparks(parent, at + Vector3(0, 0.3, 0), Color(1.0, 0.85, 0.6))

## A blow at the water: a splash, and rings spreading on it.
static func splash(parent: Node3D, at: Vector3, dir: Vector3) -> void:
	Fx3D.splash(parent, at + dir * 0.4, Color(0.75, 0.88, 1.0), 0.9, 1.3)
	Fx3D.shockwave(parent, at + Vector3(0, 0.05, 0), Color(0.75, 0.9, 1.0), 4.0, 0.9)

# ---------------------------------------------------------------- mowing (the grass shader)
static var _mow_i := 0
## Mow the grass within `radius` of `at`: the grass shader (nature.gd) shortens every blade there and
## lets it grow back over REGROW seconds.  Four cuts are remembered at a time (shader globals mow0..3,
## each x, z, radius, the world clock when it was cut), and the world clock is `mow_now`.
static func mow(at: Vector3, radius: float, now: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.global_shader_parameter_set("mow%d" % _mow_i, Vector4(at.x, at.z, radius, now))
	_mow_i = (_mow_i + 1) % 4

static func clear_mows() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for k in 4:
		RenderingServer.global_shader_parameter_set("mow%d" % k, Vector4(0, 0, 0, -9999.0))

# ---------------------------------------------------------------- a pack knocked back
## A pack struck in the land is thrown back off its feet: `n` (its node) flies along `dir`, spinning a
## little, and lands; returns the tween.
static func knock(n: Node3D, dir: Vector3, dist: float = 2.2) -> Tween:
	var d := Vector3(dir.x, 0.0, dir.z).normalized()
	var start := n.position
	var tw := n.create_tween()
	tw.tween_method(func(x: float) -> void:
		n.position = start + d * dist * (1.0 - (1.0 - x) * (1.0 - x)) + Vector3(0, sin(x * PI) * 0.9, 0)
		n.rotation.z = sin(x * PI) * 0.5, 0.0, 1.0, AMBUSH_SHOW)
	return tw

# ---------------------------------------------------------------- the sword qi
## The crescent the sword throws (G): a glowing arc flying from `from` along `dir` for `length` metres.
static func wave(parent: Node3D, from: Vector3, dir: Vector3, length: float, col: Color = Color(0.7, 0.9, 1.0)) -> Node3D:
	var root := Node3D.new()
	# a crescent standing on edge, bowed forward like the cut that threw it: two glowing arcs
	var arc := MB.new()
	arc.arc(Vector3.ZERO, 1.3, 0.34, PI * 0.5 - 1.15, PI * 0.5 + 1.15, Color(col.r, col.g, col.b, 0.9), 22)
	arc.arc(Vector3.ZERO, 1.22, 0.12, PI * 0.5 - 0.95, PI * 0.5 + 0.95, Color(1, 1, 1, 0.9), 18)
	var mi := MB.mesh_node(root, arc.build(MB.mat_glow()))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the arc lies in its own XZ plane bulging towards +Z: stand it up across the way it flies
	mi.rotation = Vector3(0, 0, PI * 0.5)
	mi.position = Vector3(0, 0, -1.0)
	root.position = from
	var d := Vector3(dir.x, 0.0, dir.z).normalized()
	root.rotation.y = atan2(d.x, d.z)
	root.rotation.z = 0.25
	parent.add_child(root)
	var tw := root.create_tween()
	tw.tween_property(root, "position", from + d * length, length / WAVE_SPEED)
	tw.parallel().tween_property(root, "scale", Vector3(1.4, 1.0, 1.4), length / WAVE_SPEED)
	tw.tween_property(root, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tw.tween_callback(root.queue_free)
	return root
