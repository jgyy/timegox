class_name Burden
extends RefCounted
## The Heavy Road release: what a load looks like on somebody's back (load.gd `look`), and the tools
## of the work of the hands (toil.gd).  All of it is built here from code, in the model space of a
## person (facing +Z, the chest bone at 1.28 m, the shoulders 1.4 m up), and hung on the chest bone so
## that it leans when the back leans.
##
## A load is a carrying-frame (two uprights of bamboo from the hip to above the head, three rungs, a
## shelf, two straps of plaited hemp over the shoulders) and whatever is lashed to it:
##
##   pack    a bundle in oiled cloth, a rolled mat across the top, a pot and a gourd hung off the side
##   logs    stems of timber upright against the frame, standing well clear of the head
##   stone   dressed blocks on the shelf, roped down
##   sacks   sacks of charcoal stacked three high, black at the seams
##   fish    a creel of split bamboo and a string of carp hung from the top rung
##   herbs   a tall back-basket with green standing out of it
##   basket  what Yue Ling carries: the back-basket, a bundle in it and a cloth over the top
##
## `k` is how full it is (0.5 a half load, 1.0 all his back was made for, 1.6 staggering): more of
## whatever it is, piled higher.

const BAMBOO := Color("8f8668")
const BAMBOO_D := Color("686048")
const HEMP := Color("8c8470")
const CLOTH_C := Color("6a7a8a")
const BARK := Color("5c5044")
const HEART := Color("b8a888")
const ROCK := Color("9a9890")
const SACK := Color("7c7464")
const COAL := Color("26242a")
const GREEN := Color("5a8a4a")
const IRON := Color("50505a")

const KINDS := ["pack", "logs", "stone", "sacks", "fish", "herbs", "basket"]

## The frame everything but a basket is lashed to.
static func _frame(b: MB, top: float) -> void:
	var bam := MB.tag(BAMBOO, MB.WOOD)
	var bam_d := MB.tag(BAMBOO_D, MB.WOOD)
	for s in [-1.0, 1.0]:
		b.limb(Vector3(0.15 * s, 0.86, -0.2), Vector3(0.16 * s, top, -0.24), 0.017, 0.014, bam, 6)
		# the straps, over the shoulder and back under the arm
		b.limb(Vector3(0.13 * s, 1.5, -0.19), Vector3(0.12 * s, 1.5, 0.07), 0.016, 0.016, MB.tag(HEMP, MB.CLOTH), 5)
		b.limb(Vector3(0.12 * s, 1.5, 0.07), Vector3(0.15 * s, 1.14, 0.03), 0.016, 0.014, MB.tag(HEMP, MB.CLOTH), 5)
		b.limb(Vector3(0.15 * s, 1.14, 0.03), Vector3(0.15 * s, 1.02, -0.19), 0.014, 0.014, MB.tag(HEMP, MB.CLOTH), 5)
	for y in [0.92, 1.24, top - 0.06]:
		b.limb(Vector3(-0.17, y, -0.22), Vector3(0.17, y, -0.22), 0.012, 0.012, bam_d, 5)
	# the shelf the load stands on
	b.box(Vector3(0, 0.9, -0.33), Vector3(0.34, 0.02, 0.24), bam_d)
	for s2 in [-1.0, 1.0]:
		b.limb(Vector3(0.15 * s2, 0.9, -0.44), Vector3(0.15 * s2, 1.2, -0.23), 0.009, 0.009, bam_d, 4)

static func _rope(b: MB, y: float, half: float, depth: float) -> void:
	var hemp := MB.tag(HEMP.darkened(0.15), MB.CLOTH)
	b.limb(Vector3(-half, y, -0.22), Vector3(-half, y, -0.22 - depth), 0.008, 0.008, hemp, 4)
	b.limb(Vector3(-half, y, -0.22 - depth), Vector3(half, y, -0.22 - depth), 0.008, 0.008, hemp, 4)
	b.limb(Vector3(half, y, -0.22 - depth), Vector3(half, y, -0.22), 0.008, 0.008, hemp, 4)

static func _basket(b: MB, h: float) -> void:
	var weave := MB.tag(BAMBOO, MB.WOOD)
	var prof: Array = [Vector2(0.13, 0.0), Vector2(0.16, h * 0.4), Vector2(0.19, h * 0.8), Vector2(0.2, h)]
	b.lathe(Vector3(0, 0.92, -0.36), prof, weave, 12, MB.tag(BAMBOO_D, MB.WOOD), Vector2(1.0, 0.82))
	for k in 3:
		b.torus(Vector3(0, 0.92 + h * (0.25 + 0.3 * k), -0.36), 0.15 + 0.022 * k, 0.008, MB.tag(BAMBOO_D, MB.WOOD))
	for s in [-1.0, 1.0]:
		b.limb(Vector3(0.12 * s, 0.92 + h * 0.9, -0.22), Vector3(0.12 * s, 1.5, 0.07), 0.015, 0.015, MB.tag(HEMP, MB.CLOTH), 5)
		b.limb(Vector3(0.12 * s, 1.5, 0.07), Vector3(0.15 * s, 1.12, 0.03), 0.015, 0.013, MB.tag(HEMP, MB.CLOTH), 5)
		b.limb(Vector3(0.15 * s, 1.12, 0.03), Vector3(0.13 * s, 0.98, -0.22), 0.013, 0.013, MB.tag(HEMP, MB.CLOTH), 5)

## The load `kind`, `k` full, in a person's model space.
static func model(kind: String, k: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	k = clampf(k, 0.4, 1.6)
	match kind:
		"logs":
			var n := clampi(int(round(k * 3.0)), 2, 5)
			var top := 1.75 + 0.22 * k
			_frame(b, 1.9)
			for i in n:
				var x := (float(i) - float(n - 1) * 0.5) * 0.105
				var z := -0.34 - 0.06 * float(i % 2) - (0.1 if i >= 3 else 0.0)
				var h := top + 0.12 * float((i * 7) % 3) - 0.1
				b.limb(Vector3(x, 0.78, z), Vector3(x * 1.15, h, z - 0.05), 0.056, 0.048, MB.tag(BARK, MB.WOOD), 8)
				b.cyl(Vector3(x * 1.15, h + 0.002, z - 0.05), 0.047, 0.006, MB.tag(HEART, MB.WOOD), Vector3.ZERO, 8)
				b.cyl(Vector3(x, 0.777, z), 0.055, 0.006, MB.tag(HEART, MB.WOOD), Vector3.ZERO, 8)
			_rope(b, 1.1, 0.3, 0.3)
			_rope(b, 1.62, 0.3, 0.3)
		"stone":
			var n2 := clampi(int(round(k * 1.6)), 1, 3)
			_frame(b, 1.72)
			for i2 in n2:
				var y := 1.06 + 0.3 * float(i2)
				var sz := Vector3(0.34 - 0.03 * i2, 0.28, 0.26 - 0.02 * i2)
				b.box(Vector3(0.01 * (i2 % 2), y, -0.36), sz, MB.tag(ROCK.darkened(0.06 * i2), MB.STONE), Vector3(0, 0.12 * (i2 % 2), 0))
				_rope(b, y + 0.02, 0.19, 0.3)
		"sacks":
			var n3 := clampi(int(round(k * 2.6)), 2, 4)
			_frame(b, 1.9)
			for i3 in n3:
				var y3 := 1.02 + 0.24 * float(i3)
				b.sph(Vector3(0.015 * (1 - 2 * (i3 % 2)), y3, -0.37), Vector3(0.2, 0.13, 0.16), MB.tag(SACK.darkened(0.05 * (i3 % 2)), MB.CLOTH))
				# the black of it worked through at the tied end
				b.sph(Vector3(0.19 * (1 - 2 * (i3 % 2)), y3, -0.37), Vector3(0.035, 0.05, 0.05), MB.tag(COAL, MB.STONE))
			_rope(b, 1.02 + 0.24 * float(n3 - 1) + 0.02, 0.21, 0.32)
		"fish":
			_frame(b, 1.74)
			# a creel on the shelf and a string of carp off the top rung
			b.lathe(Vector3(0, 0.92, -0.35), [Vector2(0.13, 0.0), Vector2(0.16, 0.14), Vector2(0.13, 0.3), Vector2(0.09, 0.34)], MB.tag(BAMBOO, MB.WOOD), 10, MB.tag(BAMBOO_D, MB.WOOD), Vector2(1.0, 0.8))
			var nf := clampi(int(round(k * 4.0)), 2, 6)
			for i4 in nf:
				var x4 := (float(i4) - float(nf - 1) * 0.5) * 0.07
				var y4 := 1.5 - 0.03 * float(i4 % 2)
				b.limb(Vector3(x4, 1.68, -0.25), Vector3(x4, y4, -0.27), 0.004, 0.004, MB.tag(HEMP, MB.CLOTH), 3)
				b.sph(Vector3(x4, y4 - 0.11, -0.28), Vector3(0.028, 0.12, 0.05), MB.tag(Color("b8c0c8") if i4 % 2 == 0 else Color("d8a060"), MB.SCALE))
				b.cone(Vector3(x4, y4 - 0.25, -0.28), 0.04, 0.07, MB.tag(Color("8a8a90"), MB.SCALE), Vector3(PI, 0, 0), 4)
		"herbs", "basket":
			var hh := 0.5 + 0.1 * k
			_basket(b, hh)
			if kind == "herbs":
				for i5 in 9:
					var a := float(i5) * 2.4
					var r := 0.04 + 0.03 * float(i5 % 3)
					b.limb(Vector3(cos(a) * r, 0.92 + hh - 0.05, -0.36 + sin(a) * r * 0.8), Vector3(cos(a) * (r + 0.09), 0.92 + hh + 0.14 + 0.04 * float(i5 % 2) + 0.1 * (k - 0.5), -0.36 + sin(a) * (r + 0.08)), 0.02, 0.004, MB.tag(GREEN.lightened(0.08 * float(i5 % 3)), MB.FOLIAGE), 4)
			else:
				b.sph(Vector3(0, 0.92 + hh, -0.36), Vector3(0.17, 0.09 + 0.05 * k, 0.14), MB.tag(Color("c86a8a"), MB.CLOTH))
				b.limb(Vector3(0.1, 0.92 + hh + 0.05, -0.3), Vector3(0.2, 0.92 + hh - 0.12, -0.28), 0.02, 0.006, MB.tag(Color("c86a8a"), MB.CLOTH), 4)
		_:
			# a pack of small things: a bundle, a mat, a pot and a gourd
			_frame(b, 1.74)
			var fat := 0.75 + 0.3 * k
			b.sph(Vector3(0, 1.14, -0.37), Vector3(0.19, 0.2, 0.15) * fat, MB.tag(CLOTH_C, MB.CLOTH))
			b.sph(Vector3(0.02, 1.4, -0.36), Vector3(0.16, 0.13, 0.13) * fat, MB.tag(CLOTH_C.lightened(0.12), MB.CLOTH))
			_rope(b, 1.14, 0.2 * fat, 0.3)
			_rope(b, 1.4, 0.17 * fat, 0.28)
			# the mat rolled across the top
			b.cyl(Vector3(0, 1.66, -0.3), 0.065, 0.5, MB.tag(Color("c8b480"), MB.WOOD), Vector3(0, 0, PI * 0.5), 10)
			for s in [-1.0, 1.0]:
				b.torus(Vector3(0.16 * s, 1.66, -0.3), 0.066, 0.007, MB.tag(HEMP.darkened(0.2), MB.CLOTH), Vector3(0, 0, PI * 0.5))
			# a pot and a gourd swinging off the side
			b.lathe(Vector3(0.24, 0.98, -0.3), [Vector2(0.05, 0.0), Vector2(0.075, 0.04), Vector2(0.07, 0.09), Vector2(0.05, 0.1)], MB.tag(IRON, MB.METAL), 10)
			b.limb(Vector3(0.24, 1.08, -0.3), Vector3(0.17, 1.24, -0.23), 0.004, 0.004, MB.tag(HEMP, MB.CLOTH), 3)
			b.sph(Vector3(-0.25, 1.0, -0.3), Vector3(0.055, 0.06, 0.055), MB.tag(Color("c89a50"), MB.WOOD))
			b.sph(Vector3(-0.25, 1.09, -0.3), Vector3(0.035, 0.04, 0.035), MB.tag(Color("c89a50"), MB.WOOD))
			b.limb(Vector3(-0.25, 1.12, -0.3), Vector3(-0.17, 1.24, -0.23), 0.004, 0.004, MB.tag(HEMP, MB.CLOTH), 3)
	MB.mesh_node(root, b.build(MB.mat_plain()))
	return root

## Put load `kind`, `k` full, on person `m` (hung on the chest bone), or take it off (`kind` "").
## Nothing is rebuilt while the same load is worn.
static func wear(m: Node3D, kind: String, k: float = 1.0) -> void:
	var sig := "" if kind == "" else "%s|%d" % [kind, int(round(k * 5.0))]
	if str(m.get_meta("burden", "")) == sig:
		return
	m.set_meta("burden", sig)
	var sks := m.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return
	var sk := sks[0] as Skeleton3D
	var old := sk.get_node_or_null("burden")
	if old != null:
		sk.remove_child(old)
		old.queue_free()
	var bi := sk.find_bone("chest")
	if kind == "" or bi < 0:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = "chest"
	ba.name = "burden"
	sk.add_child(ba)
	var node := model(kind, k)
	node.transform = sk.get_bone_global_rest(bi).affine_inverse() * node.transform
	ba.add_child(node)

## The tools of the work of the hands that nothing older holds (Props.held asks here first): held by
## the grip at the hand, their length along +Z as a rod's or a pick's is.
static func held(what: String) -> Node3D:
	if not what in ["felling_axe", "sickle"]:
		return null
	var root := Node3D.new()
	var b := MB.new()
	var wood := MB.tag(Color("a87a4a"), MB.WOOD)
	var iron := MB.tag(IRON, MB.METAL)
	match what:
		"felling_axe":
			# a long haft of ash and a bearded head, the edge bright where the stone has been
			b.limb(Vector3(0, -0.08, -0.3), Vector3(0, -0.08, 0.62), 0.019, 0.016, wood, 6)
			b.box(Vector3(0, -0.16, 0.58), Vector3(0.035, 0.2, 0.11), iron)
			b.box(Vector3(0, -0.275, 0.58), Vector3(0.012, 0.04, 0.15), MB.tag(Color("c8ccd4"), MB.METAL))
			b.box(Vector3(0, -0.05, 0.58), Vector3(0.045, 0.06, 0.08), iron)
		"sickle":
			b.limb(Vector3(0, -0.08, -0.06), Vector3(0, -0.08, 0.2), 0.017, 0.015, wood, 6)
			for i in 6:
				var a0 := float(i) / 6.0 * PI * 0.95
				var a1 := float(i + 1) / 6.0 * PI * 0.95
				b.limb(Vector3(0, -0.08 - sin(a0) * 0.16, 0.2 + (1.0 - cos(a0)) * 0.13), Vector3(0, -0.08 - sin(a1) * 0.16, 0.2 + (1.0 - cos(a1)) * 0.13), 0.012 - 0.0015 * i, 0.0105 - 0.0015 * i, iron, 4)
	MB.mesh_node(root, b.build(MB.mat_plain()))
	return root
