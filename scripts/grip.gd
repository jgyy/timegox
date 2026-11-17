class_name Grip
extends RefCounted
## The Five Hands release: a hand closes on what it holds, and touches what it touches.
##
## Three things were wrong with every animation that had a thing in it, and nobody had seen them
## because nobody had looked at a hand from a pace away:
##
## 1. **What was held was not in the hand.**  Every held thing is drawn to be gripped at its own
##    y = -0.08, eight centimetres *below* a wrist.  The bones of the people the Blender scripts make
##    point down their own +Y, so that was eight centimetres *up the forearm*: a hoe went through the
##    sleeve and the fist closed on air fifteen centimetres below it.  `seat` puts the grip in the palm.
## 2. **The other hand was nowhere.**  A hoe, a broom, an axe, a spade and a pick are worked with two
##    hands; the clips moved the right arm and left the left one swinging.  `Reach` (a
##    SkeletonModifier3D, so that what it does is over the clip and gone the next frame) closes the
##    other hand on the shaft, where on the shaft it is nearest: two bones solved for one point
##    (`solve`), the elbow kept on the side the clip had it.
## 3. **The tool met nothing.**  A hoe was swung at the air at the height of the waist; a broom swept a
##    hand above the ground; a hammer stopped short of the anvil or went through it.  Each tool says
##    where its working end is (`TOOLS.work`) and how it is used (`on`: brought `down`, swung `fwd`, or
##    `drag`ged); in the part of the stroke where the clip brings it nearest (`span`: measured from the
##    clip itself, once), the arm is solved and the wrist turned so that the working end is *on* what
##    it works: the ground under it (whatever the slope), the trunk of the tree that is really there,
##    the nearest face of the thing in front of him (`closest`, on the triangles of its own mesh).
##
## And a bare hand that the clip brings within a span of something is laid on it (`palms`): the stele
## he reads, the lion's head, the panel he knocks on, the strings of the qin.
##
## What hangs from a hand hangs (`hang`, heft.gd): a lantern on its stick, the baskets of a shoulder
## pole, the pan of a steelyard, a float on a line are weights on cords, driven by the hand that
## carries them.
##
## All of it is drawn only.  `solve` and `closest` are pure, and the tests measure them; with no
## window nothing is held and nothing is solved.

## the middle of the palm, along the hand bone from the wrist (metres)
const PALM := 0.075
## where every held thing is drawn to be gripped: its own y
const AUTHORED := -0.08
## how near a bare palm must come to a thing before it is laid on it, and a tool's end before it is
## drawn to it when nothing is known of its stroke
const NEAR := 0.34

## held thing -> where its working end is (`work`, in its own drawing), how it is brought to what it
## works on (`on`: "down" onto what is under it, "fwd" into what is in front, "drag" along the ground
## all the time), the lengths of its shaft the other hand may close on (`two`: [z0, z1] pairs), whether
## it was drawn with its working end towards the elbow (`turn`: it is turned end for end in the hand),
## and what hangs from it (`hang`: built by its model as children named "hang...").
const TOOLS := {
	"hoe": {"work": Vector3(0, -0.33, -1.02), "on": "down", "two": [[-0.7, -0.22]]},
	"broom": {"work": Vector3(0, -0.08, -1.2), "on": "drag", "two": [[-0.6, -0.2], [0.2, 0.55]]},
	"felling_axe": {"work": Vector3(0, -0.295, 0.58), "on": "fwd", "two": [[0.16, 0.48], [-0.28, -0.14]]},
	"axe": {"work": Vector3(0, -0.26, -0.42), "on": "down", "two": [[0.16, 0.38]]},
	"spade": {"work": Vector3(0, -0.08, 0.74), "on": "down", "two": [[-0.36, -0.2], [0.2, 0.42]]},
	"pickaxe": {"work": Vector3(0, -0.34, 0.6), "on": "fwd", "two": [[0.18, 0.5], [-0.24, -0.14]]},
	"hammer": {"work": Vector3(0, -0.115, 0.34), "on": "down"},
	"pestle": {"work": Vector3(0, -0.08, -0.79), "on": "down"},
	"ladle": {"two": [[-0.55, -0.2]]},
	"chisel": {"work": Vector3(0, -0.08, 0.2), "on": "fwd"},
	"brush": {"work": Vector3(0, -0.13, 0.22), "on": "down"},
	"kitchen_knife": {"work": Vector3(0, -0.155, 0.22), "on": "down"},
	"rod": {}, "lantern": {}, "pole": {}, "steelyard": {}, "trug": {}, "basket": {},
}

## (for the tour's before-and-after only: things held as they were held before this release, in the
## sleeve, with nothing solved; the stroke is still watched for, so that both can be caught at the same moment)
static var plain := false

# ---------------------------------------------------------------- in the palm
## The thing `model` (drawn to be gripped at its own y = -0.08) as it sits in a hand of the Blender
## people: a holder whose child it is, to be hung on a hand bone.  What is asked of the tool (`TOOLS`)
## is asked in the model's own drawing, and carried into the bone by the holder's transform.
static func seat(model: Node3D, what: String = "") -> Node3D:
	var holder := Node3D.new()
	holder.name = "seat"
	var tl: Dictionary = TOOLS.get(what, {})
	if bool(tl.get("turn", false)):
		holder.basis = Basis(Vector3.UP, PI)
	holder.position = Vector3(0, PALM - AUTHORED, 0)
	if plain:
		holder.transform = Transform3D.IDENTITY
	holder.add_child(model)
	return holder

# ---------------------------------------------------------------- two bones, one point
## An arm of two bones (shoulder `sh`, elbow `el`, wrist `wr`) reaches for `target`: where the elbow
## and the wrist go.  The lengths of the bones are kept; the elbow stays on the side of the arm's line
## it was on; a target further off than the arm is long is reached towards, the arm straight.
## Returns [elbow, wrist].
static func solve(sh: Vector3, el: Vector3, wr: Vector3, target: Vector3) -> Array:
	var a := (el - sh).length()
	var b := (wr - el).length()
	var to := target - sh
	var far := to.length()
	var dir := to / far if far > 1e-5 else (wr - sh).normalized()
	var d := clampf(far, absf(a - b) + 0.002, a + b - 0.002)
	var up := el - sh
	var pole := up - dir * up.dot(dir)
	if pole.length() < 1e-4:
		pole = dir.cross(Vector3.RIGHT)
		if pole.length() < 1e-4:
			pole = dir.cross(Vector3.UP)
	pole = pole.normalized()
	var x := (a * a - b * b + d * d) / (2.0 * d)
	var h := sqrt(maxf(0.0, a * a - x * x))
	return [sh + dir * x + pole * h, sh + dir * d]

## The arm on `side` ("L" or "R") of skeleton `sk` is posed so that its wrist is at `target` (skeleton
## space).  The hand keeps the way it was turned (`keep`), or turns with the forearm.  Returns where
## the wrist came to (short of the target if it was out of reach).
static func apply(sk: Skeleton3D, side: String, target: Vector3, keep: bool = true) -> Vector3:
	var iu := sk.find_bone("upper_arm." + side)
	var ifo := sk.find_bone("forearm." + side)
	var ih := sk.find_bone("hand." + side)
	if iu < 0 or ifo < 0 or ih < 0:
		return target
	var gu := sk.get_bone_global_pose(iu)
	var gf := sk.get_bone_global_pose(ifo)
	var gh := sk.get_bone_global_pose(ih)
	var res: Array = solve(gu.origin, gf.origin, gh.origin, target)
	var d0 := (gf.origin - gu.origin).normalized()
	var d1 := ((res[0] as Vector3) - gu.origin).normalized()
	if d0.dot(d1) < 0.999999:
		sk.set_bone_global_pose(iu, Transform3D(Basis(Quaternion(d0, d1)) * gu.basis, gu.origin))
	var gf2 := sk.get_bone_global_pose(ifo)
	var wr2 := sk.get_bone_global_pose(ih).origin
	var e0 := (wr2 - gf2.origin).normalized()
	var e1 := ((res[1] as Vector3) - gf2.origin).normalized()
	if e0.dot(e1) < 0.999999:
		sk.set_bone_global_pose(ifo, Transform3D(Basis(Quaternion(e0, e1)) * gf2.basis, gf2.origin))
	var gh2 := sk.get_bone_global_pose(ih)
	if keep:
		sk.set_bone_global_pose(ih, Transform3D(gh.basis, gh2.origin))
	return gh2.origin

# ---------------------------------------------------------------- the nearest of a thing
## The point of triangle (a, b, c) nearest to `p`.
static func on_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var den := 1.0 / (va + vb + vc)
	return a + ab * (vb * den) + ac * (vc * den)

## The point of the triangles `faces` (three vertices each) nearest to `p`, if one is within `within`:
## [point, how far], or [] if none.
static func closest(faces: PackedVector3Array, p: Vector3, within: float) -> Array:
	var best := within
	var out: Array = []
	var n := faces.size() - 2
	var i := 0
	while i < n:
		var a := faces[i]
		# (a triangle wholly further off than the best so far along any axis is not looked at closely)
		if absf(a.x - p.x) < best + 1.2 and absf(a.y - p.y) < best + 1.2 and absf(a.z - p.z) < best + 1.2:
			var q := on_triangle(p, a, faces[i + 1], faces[i + 2])
			var d := q.distance_to(p)
			if d < best:
				best = d
				out = [q, d]
		i += 3
	return out

## The triangles of everything drawn under `node` (world space) that come within `radius` of `near`:
## what a hand in front of it could touch.
static func faces_of(node: Node3D, near: Vector3, radius: float = 1.7) -> PackedVector3Array:
	var out := PackedVector3Array()
	if node == null or not is_instance_valid(node):
		return out
	var list: Array = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		list.append(node)
	for mi0 in list:
		var mi := mi0 as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var xf := mi.global_transform if mi.is_inside_tree() else mi.transform
		var fs: PackedVector3Array = mi.mesh.get_faces()
		var i := 0
		while i + 2 < fs.size():
			var a := xf * fs[i]
			var b := xf * fs[i + 1]
			var c := xf * fs[i + 2]
			if ((a + b + c) / 3.0).distance_to(near) < radius:
				out.append(a)
				out.append(b)
				out.append(c)
			i += 3
	return out

# ---------------------------------------------------------------- the stroke of a clip
static var _spans := {}

## Where the working end of a tool goes in the course of clip `clip` on model `m`, and where in that
## the stroke lands: measured from the clip itself the first time it is asked (twenty-four poses,
## skeleton space) and remembered by model, clip and tool.  A tool brought `down` lands where its end
## is lowest in front of him (a hoe is lower still behind his back at the top of the swing, and that is
## not the stroke); one swung `fwd`, where it is furthest forward at the height of the chest.
## {"at": the landing, "r": how far from it the end is ever carried}; {} if the model has no such clip.
static func span(m: Node3D, sk: Skeleton3D, clip: String, hand: String, work: Vector3, on: String = "down") -> Dictionary:
	var key := "%s|%s|%s|%s|%s" % [str(m.get_meta("glb", m.name)), clip, hand, str(work.snappedf(0.01)), on]
	if _spans.has(key):
		return _spans[key]
	var out := {}
	var ap = m.get_meta("ap") if m.has_meta("ap") else null
	var ih := sk.find_bone("hand." + hand)
	if ap != null and ih >= 0 and (ap as AnimationPlayer).has_animation(clip):
		var pl := ap as AnimationPlayer
		var was := pl.assigned_animation
		var at := pl.current_animation_position if was != "" and pl.is_playing() else 0.0
		var ln: float = pl.get_animation(clip).length
		pl.play(clip, 0.0)
		var pts: Array = []
		var best := -INF
		var land := Vector3.ZERO
		for i in 24:
			pl.seek(ln * float(i) / 24.0, true)
			var p := sk.get_bone_global_pose(ih) * work
			pts.append(p)
			# (down: the lowest it comes in front of him; forward: the furthest, about the height of the chest)
			var score := (-p.y if p.z > 0.05 else -p.y - 10.0) if on == "down" else p.z - 0.4 * absf(p.y - 1.0)
			if score > best:
				best = score
				land = p
		var r := 0.05
		for p2 in pts:
			r = maxf(r, (p2 as Vector3).distance_to(land))
		if was != "" and pl.has_animation(was):
			pl.play(was, 0.0)
			pl.seek(at, true)
		out = {"at": land, "r": r}
	_spans[key] = out
	return out

# ---------------------------------------------------------------- holding
## `what` is put into the hand of `m` (`bone`: "hand.R" or "hand.L") in the palm, with whatever of it
## hangs hanging and the other hand on its shaft if it has one.  Returns the BoneAttachment3D (free it
## to let go), or null if the model has no such bone.  The modifier that does the reaching is its
## meta "reach".
static func hold(m: Node3D, model: Node3D, what: String, bone: String = "hand.R") -> Node3D:
	var sks := m.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		model.queue_free()
		return null
	var sk := sks[0] as Skeleton3D
	if sk.find_bone(bone) < 0:
		model.queue_free()
		return null
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	sk.add_child(ba)
	var st := seat(model, what)
	ba.add_child(st)
	var tl: Dictionary = TOOLS.get(what, {})
	var hangs: Array = []
	for c in model.get_children():
		if str(c.name).begins_with("hang"):
			hangs.append(c)
	if tl.has("two") or tl.has("work") or not hangs.is_empty():
		var r := Reach.new()
		r.name = "reach_" + bone.replace(".", "_")
		r.owner_model = m
		r.main = "L" if bone.ends_with(".L") else "R"
		r.seat_node = st
		r.tool = tl
		r.hangs = hangs
		r.mute = plain
		sk.add_child(r)
		ba.set_meta("reach", r)
		ba.tree_exiting.connect(func() -> void:
			if is_instance_valid(r):
				r.queue_free())
	return ba

## Bare hands that will be laid on what is in front of them: the modifier, on the skeleton of `m`
## (null if it has none).  Free it when the thing is done.
static func bare(m: Node3D) -> Reach:
	var sks := m.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return null
	var r := Reach.new()
	r.name = "reach_bare"
	r.owner_model = m
	(sks[0] as Skeleton3D).add_child(r)
	return r

## The modifier `hold` made for what is held on `ba` (null if it needed none).
static func reach_of(ba) -> Reach:
	if ba == null or not is_instance_valid(ba) or not (ba as Node).has_meta("reach"):
		return null
	var r = (ba as Node).get_meta("reach")
	return r if is_instance_valid(r) else null

# ---------------------------------------------------------------- the modifier
## What is done to an arm after the clip has posed it, every frame, and undone before the next.
class Reach extends SkeletonModifier3D:
	## the model whose skeleton this is (its "ap" is asked for the stroke of a clip)
	var owner_model: Node3D = null
	## the hand that holds ("R" or "L"), the holder of what it holds (Grip.seat) and its entry of TOOLS
	var main := "R"
	var seat_node: Node3D = null
	var tool := {}
	## the parts of it that hang (children of the model named "hang...", meta "len", "drag", "floor")
	var hangs: Array = []
	## the clip being played (the stroke is measured from it); "" for none
	var clip := ""
	## how much of the contact is wanted now (eased towards): 1 while the thing is being done
	var k := 0.0
	## the height of the ground under a point of the world (a Callable, or null)
	var ground = null
	## the triangles of what is in front of him (world space)
	var faces := PackedVector3Array()
	## the trunk the axe is laid to: {"at": the foot of it (world), "r": its radius}
	var trunk := {}
	## the bare hands that are laid on what they come near: ["R"], ["L", "R"]
	var palms: Array = []
	## called with the point of the world where the working end of the tool has just landed
	var on_hit = null
	## the last place the working end met something (world), and whether it is on it now
	var met := Vector3.ZERO
	var down := false
	## (Grip.plain: nothing is solved, the stroke is only watched)
	var mute := false
	var _k := 0.0
	var _seen := {}
	var _hang := {}

	func _process_modification_with_delta(delta: float) -> void:
		var sk := get_skeleton()
		if sk == null:
			return
		_k = move_toward(_k, k, delta * 4.0)
		var xf := sk.global_transform
		var ih := sk.find_bone("hand." + main)
		if seat_node != null and is_instance_valid(seat_node) and ih >= 0:
			if _k > 0.01 and tool.has("work"):
				_work(sk, xf, ih)
			if tool.has("two") and not mute:
				_other(sk, ih)
		if _k > 0.01:
			for side in palms:
				if seat_node != null and str(side) == main:
					continue
				_palm(sk, xf, str(side), delta)
		if seat_node != null and is_instance_valid(seat_node) and ih >= 0:
			for hn in hangs:
				if is_instance_valid(hn) and not mute:
					_swing(sk, xf, ih, hn as Node3D, delta)

	## how far into the working part of its stroke the tool's end is (0..1), `ws` in skeleton space
	func _stroke(sk: Skeleton3D, ws: Vector3) -> float:
		var on := str(tool.get("on", ""))
		if on == "drag":
			return 1.0
		if clip == "" or owner_model == null:
			return 0.0
		var sp: Dictionary = Grip.span(owner_model, sk, clip, main, seat_node.transform * (tool.work as Vector3), on)
		if sp.is_empty():
			return 0.0
		return 1.0 - smoothstep(0.16, 0.6, ws.distance_to(sp.at) / float(sp.r))

	## where the working end should be, in the world, when it is at `ww` (null: on nothing)
	func _goal(ww: Vector3):
		var on := str(tool.get("on", ""))
		if on == "fwd" and not trunk.is_empty():
			var at: Vector3 = trunk.at
			var out := Vector3(ww.x - at.x, 0.0, ww.z - at.z)
			out = out.normalized() if out.length() > 0.01 else Vector3(0, 0, 1)
			return Vector3(at.x, clampf(ww.y, at.y + 0.45, at.y + 0.95), at.z) + out * float(trunk.r)
		if not faces.is_empty():
			var hit: Array = Grip.closest(faces, ww, 1.4)
			if not hit.is_empty():
				return hit[0]
		if on != "fwd" and ground != null and (ground as Callable).is_valid():
			return Vector3(ww.x, float((ground as Callable).call(ww)) + 0.012, ww.z)
		return null

	func _work(sk: Skeleton3D, xf: Transform3D, ih: int) -> void:
		var hg := sk.get_bone_global_pose(ih)
		var wl: Vector3 = seat_node.transform * (tool.work as Vector3)
		var ws := hg * wl
		var w := _stroke(sk, ws) * _k
		if w < 0.4:
			down = false
		if mute:
			down = down or w > 0.86
			return
		if w <= 0.01:
			return
		var goal = _goal(xf * ws)
		if goal == null:
			return
		var gs: Vector3 = xf.affine_inverse() * (goal as Vector3)
		# the wrist goes where the tool's own length puts it from the place its end must be
		var lw := wl.length()
		var from := hg.origin - gs
		var want := gs + (from.normalized() if from.length() > 1e-4 else Vector3.UP) * lw
		Grip.apply(sk, main, hg.origin.lerp(want, w), true)
		# and turns, so that the end is on it
		var hg2 := sk.get_bone_global_pose(ih)
		var a := (hg2 * wl - hg2.origin).normalized()
		var b := (gs - hg2.origin).normalized()
		if a.dot(b) < 0.999999:
			var q := Quaternion.IDENTITY.slerp(Quaternion(a, b), w)
			sk.set_bone_global_pose(ih, Transform3D(Basis(q) * hg2.basis, hg2.origin))
		if w > 0.86 and not down:
			down = true
			met = goal
			if on_hit != null and (on_hit as Callable).is_valid():
				(on_hit as Callable).call(goal)

	## the other hand, onto the shaft where the shaft is nearest it
	func _other(sk: Skeleton3D, ih: int) -> void:
		var off := "L" if main == "R" else "R"
		var io := sk.find_bone("hand." + off)
		var iu := sk.find_bone("upper_arm." + off)
		var ifo := sk.find_bone("forearm." + off)
		if io < 0 or iu < 0 or ifo < 0:
			return
		var hg := sk.get_bone_global_pose(ih)
		var og := sk.get_bone_global_pose(io)
		var sh := sk.get_bone_global_pose(iu).origin
		var el := sk.get_bone_global_pose(ifo).origin
		var arm := (el - sh).length() + (og.origin - el).length() + Grip.PALM
		var palm := og * Vector3(0, Grip.PALM, 0)
		var best := Vector3.ZERO
		var bd := INF
		for rg in tool.two:
			var a: Vector3 = hg * (seat_node.transform * Vector3(0, Grip.AUTHORED, float(rg[0])))
			var b: Vector3 = hg * (seat_node.transform * Vector3(0, Grip.AUTHORED, float(rg[1])))
			var c := Geometry3D.get_closest_point_to_segment(palm, a, b)
			# (a place on the shaft the arm cannot reach is no place for a hand: the nearest it can)
			if c.distance_to(sh) > arm:
				c = Geometry3D.get_closest_point_to_segment(sh, a, b)
			var d := c.distance_to(palm) + maxf(0.0, c.distance_to(sh) - arm) * 4.0
			if d < bd:
				bd = d
				best = c
		if bd == INF:
			return
		Grip.apply(sk, off, og.origin + (best - palm), true)

	## a bare palm, onto the nearest of what is in front of it
	func _palm(sk: Skeleton3D, xf: Transform3D, side: String, delta: float) -> void:
		var ih := sk.find_bone("hand." + side)
		if ih < 0 or faces.is_empty():
			return
		var og := sk.get_bone_global_pose(ih)
		var palm := og * Vector3(0, Grip.PALM + 0.02, 0)
		var pw := xf * palm
		# (looked for again a dozen times a second: the triangles are many and the hand is slow)
		var sn: Dictionary = _seen.get(side, {})
		sn["t"] = float(sn.get("t", 0.0)) - delta
		if float(sn.t) <= 0.0:
			sn["t"] = 0.08
			sn["hit"] = Grip.closest(faces, pw, Grip.NEAR)
		_seen[side] = sn
		var hit: Array = sn.get("hit", [])
		if hit.is_empty():
			return
		var q: Vector3 = hit[0]
		var w := (1.0 - smoothstep(0.03, Grip.NEAR, q.distance_to(pw))) * _k
		if w <= 0.01:
			return
		Grip.apply(sk, side, og.origin + (xf.affine_inverse() * q - palm) * w, true)

	## a part that hangs: a weight on a cord from where it is hung
	func _swing(sk: Skeleton3D, xf: Transform3D, ih: int, hn: Node3D, delta: float) -> void:
		var par := xf * sk.get_bone_global_pose(ih) * seat_node.transform
		var pivot := par * hn.position
		var id := hn.get_instance_id()
		var st: Dictionary = _hang.get(id, {})
		var ln := float(hn.get_meta("len", 0.3))
		var fl := -INF
		if hn.has_meta("floats") and ground != null and (ground as Callable).is_valid():
			fl = float((ground as Callable).call(pivot))
		var bobp := Heft.hang(st, pivot, delta, ln, float(hn.get_meta("drag", 1.4)), fl)
		_hang[id] = st
		var pb := par.basis.orthonormalized()
		hn.basis = pb.inverse() * Heft.hung(bobp - pivot, pb)
