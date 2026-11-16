class_name Visage
extends RefCounted
## The face he has earned (the Tall People release).  The Way he walks is weighed, never chosen
## (creed.gd), and now it shows: where Lin Feng stands between the Righteous Path and the Demonic is
## read off his own face and figure, in nine looks (`LOOKS`: four either side of a face nobody
## would remark on).
##
##  * **the structure of the face**: a pose of the six bones of expression (faces.gd) that every
##    expression is worn *over* (`rest`: the brows open and level, or drawn down and in; the eyes wide or
##    narrowed; the corners of the mouth; the width of the jaw), so that he smiles a different smile.
##    Keeping the precepts sets the mouth; the open road lifts one eyebrow (`rest`, by Creed.side "rule");
##  * **the look of him** (`cols`, `skin`): the skin warm, or grey as ash; the iris towards gold, or
##    red; the hair streaked and then white, as it goes for whoever cultivates what the precepts
##    forbid; the robe a shade lighter or darker than it was dyed;
##  * **what is on him** (`hang`: built from code on the head bone and at the feet): a point of light
##    between the brows or a red mark there, a pale light behind the head, a dark smoke at the hem.
##
## It is drawn only: nothing here is read by a rule, a price, a trial or the bot, and with no window
## nothing is built.  The world asks `key` now and then and rebuilds him when it has changed
## (World.refresh_hero); Esc > The Way says what people see (`text`).

## how far along the scale each look begins (Creed.value "virtue", either way)
const STEPS := [6, 12, 24, 36]
const LOOKS := {
	4: {"n": "A light behind the skin", "desc": "The brow is open and the eyes are wide and very clear, with gold in them. There is a point of light between the brows, and people lower their voices without knowing why."},
	3: {"n": "Bright-faced", "desc": "The face has opened: level brows, a mouth that rests a little way into a smile. Children walk up to him. Dogs do."},
	2: {"n": "Open-browed", "desc": "The set of somebody who sleeps well. The brow is smooth and the eyes are a shade lighter than they were."},
	1: {"n": "Clear-eyed", "desc": "Nothing anybody could name. He looks at people as if he had time for them."},
	0: {"n": "A face like anybody's", "desc": "A young face that has not yet been made up either way."},
	-1: {"n": "Hard-eyed", "desc": "Nothing anybody could name. He looks at people a moment longer than is comfortable."},
	-2: {"n": "Hollow-cheeked", "desc": "The brows have come down and in, and the eyes have narrowed. The colour is going out of the skin."},
	-3: {"n": "Ash-pale", "desc": "Grey skin, red at the rim of the iris, white coming into the hair at the temples, and one corner of the mouth higher than the other."},
	-4: {"n": "Marked between the brows", "desc": "White-haired, red-eyed, grey as a drowned man, with a red mark like a flame between the brows and a smoke about the hem that is not smoke. Mothers take their children indoors."},
}

## Which of the nine looks his Way has given him: -4 (the Demonic Path, to the end) .. 4.
static func stage(g) -> int:
	if g == null or g.hero.is_empty():
		return 0
	return stage_of(Creed.value(g, "virtue"))

static func stage_of(v: int) -> int:
	var s := 0
	for st in STEPS:
		if absi(v) >= int(st):
			s += 1
	return s * signi(v)

## What the world compares to know when to draw him again.
static func key(g) -> String:
	if g == null or g.hero.is_empty():
		return "0|0"
	return "%d|%d" % [stage(g), Creed.side(g, "rule")]

## The pose his face rests in, as the thirteen numbers of Faces.vector_of: the first ten are added to
## whatever expression is worn, the last three (lids, the jaw's width and opening) multiply it.
static func rest(st: int, rule: int = 0) -> Array:
	var k := float(st) / 4.0
	var v := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
	if k > 0.0:
		for i in [0, 3]:
			v[i] += 0.0016 * k
			v[i + 1] += -0.07 * k
		for i in [6, 8]:
			v[i] += 0.0013 * k
		v[10] = 1.0 + 0.06 * k
	elif k < 0.0:
		var m := -k
		for i in [0, 3]:
			v[i] += -0.0026 * m
			v[i + 1] += 0.32 * m
			v[i + 2] += 0.0018 * m
		v[6] += -0.0016 * m
		v[8] += 0.0012 * m
		v[9] += 0.0008 * m
		v[10] = 1.0 - 0.24 * m
		v[11] = 1.0 - 0.1 * m
	if rule > 0:
		# the precepts kept: a set mouth
		v[7] += -0.0006
		v[9] += -0.0006
		v[11] *= 0.96
	elif rule < 0:
		# the open road: one eyebrow up, half a smile
		v[3] += 0.0018
		v[8] += 0.001
	return v

## What his skin is multiplied by (linear): warm, or the grey of ash.
static func skin(st: int) -> Color:
	var k := float(st) / 4.0
	if k >= 0.0:
		return Color(1.0, 1.0, 1.0).lerp(Color(1.06, 1.0, 0.93), k)
	return Color(1.0, 1.0, 1.0).lerp(Color(0.66, 0.7, 0.78), -k)

## His colours (Fashion.hero_colors: robe, sec, trim, hair, eyes) as the look changes them.
static func cols(st: int, base: Dictionary) -> Dictionary:
	if st == 0 or base.is_empty():
		return base
	var out := base.duplicate()
	var k := float(st) / 4.0
	if k > 0.0:
		if out.has("eyes"):
			out["eyes"] = (out.eyes as Color).lerp(Color("e8b030"), 0.42 * k)
		if out.has("trim"):
			out["trim"] = (out.trim as Color).lightened(0.18 * k)
		if out.has("robe"):
			out["robe"] = (out.robe as Color).lightened(0.07 * k)
	else:
		var m := -k
		if out.has("eyes"):
			out["eyes"] = (out.eyes as Color).lerp(Color("d01414"), minf(1.0, 1.1 * m))
		if out.has("hair"):
			out["hair"] = (out.hair as Color).lerp(Color("e4e2ea"), [0.0, 0.0, 0.12, 0.5, 0.94][-st])
		if out.has("robe"):
			out["robe"] = (out.robe as Color).darkened(0.3 * m)
		if out.has("sec"):
			out["sec"] = (out.sec as Color).lerp(Color("3a0a10"), 0.45 * m)
	out["skin"] = skin(st)
	return out

## Give model `m` (Models.hero) the face and the marks of look `st`.
static func apply(m: Node3D, st: int, rule: int = 0) -> void:
	if m == null:
		return
	m.set_meta("visage", st)
	if st == 0 and rule == 0:
		if m.has_meta("face_rest"):
			m.remove_meta("face_rest")
	else:
		m.set_meta("face_rest", rest(st, rule))
	if DisplayServer.get_name() == "headless":
		return
	hang(m, st)

## What hangs on him: a mark between the brows and a light or a smoke, from the third look either way.
static func hang(m: Node3D, st: int) -> void:
	if absi(st) < 3:
		return
	var sks := m.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return
	var sk := sks[0] as Skeleton3D
	var bl := sk.find_bone("brow.L")
	var br := sk.find_bone("brow.R")
	var hd := sk.find_bone("head")
	if bl < 0 or br < 0 or hd < 0:
		return
	var mid := (sk.get_bone_global_rest(bl).origin + sk.get_bone_global_rest(br).origin) * 0.5
	var ba := BoneAttachment3D.new()
	ba.bone_name = "head"
	ba.name = "visage_mark"
	sk.add_child(ba)
	var holder := Node3D.new()
	holder.transform = sk.get_bone_global_rest(hd).affine_inverse()
	ba.add_child(holder)
	var gl := MB.new()
	var b := MB.new()
	var at := mid + Vector3(0, 0.011, 0.016)
	if st > 0:
		if st >= 4:
			gl.ball(at, 0.007, Color(1.0, 0.93, 0.6, 0.95), true)
			gl.ball(at, 0.02, Color(1.0, 0.9, 0.55, 0.35), true)
		# a pale light behind the head
		var hc := sk.get_bone_global_rest(hd).origin + Vector3(0, 0.1, -0.1)
		gl.disc(hc, 0.2 if st >= 4 else 0.15, Color(1.0, 0.94, 0.7, 0.22 if st >= 4 else 0.12), 28, Color(1.0, 0.94, 0.7, 0.0), Vector3(PI * 0.5, 0, 0))
	else:
		if st <= -4:
			# a flame of three strokes, cinnabar red
			b.leaf(at + Vector3(0, -0.008, 0), at + Vector3(0, 0.014, 0.001), 0.006, MB.tag(Color("c0101a"), MB.CLOTH), Vector3(0, 0, 1))
			for s in [-1.0, 1.0]:
				b.leaf(at + Vector3(0.004 * s, -0.007, 0), at + Vector3(0.008 * s, 0.006, 0.0005), 0.0035, MB.tag(Color("c0101a"), MB.CLOTH), Vector3(0, 0, 1))
			gl.ball(at + Vector3(0, 0.002, 0.002), 0.016, Color(1.0, 0.1, 0.1, 0.4), true)
	if not b.is_empty():
		MB.mesh_node(holder, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not gl.is_empty():
		MB.mesh_node(holder, gl.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# at the hem: a light on the ground, or a smoke that is not smoke
	var fg := MB.new()
	if st > 0:
		fg.disc(Vector3(0, 0.06, 0), 0.9, Color(1.0, 0.92, 0.6, 0.16 if st >= 4 else 0.09), 24, Color(1.0, 0.92, 0.6, 0.0))
	else:
		fg.disc(Vector3(0, 0.06, 0), 0.95, Color(0.5, 0.02, 0.06, 0.34 if st <= -4 else 0.2), 24, Color(0.2, 0.0, 0.02, 0.0))
		for i in (7 if st <= -4 else 4):
			var a := TAU * float(i) / (7.0 if st <= -4 else 4.0) + 0.4
			var p := Vector3(cos(a) * 0.42, 0.16 + 0.07 * float(i % 3), sin(a) * 0.42)
			fg.ball(p, 0.13, Color(0.16, 0.02, 0.04, 0.3), true)
			fg.ball(p + Vector3(0, 0.16, 0), 0.08, Color(0.3, 0.02, 0.05, 0.2), true)
	var fm := MB.mesh_node(m, fg.build(MB.mat_glow()))
	fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fm.name = "visage_hem"

## "Ash-pale: grey skin, red at the rim of the iris, ..."
static func text(g) -> String:
	var lk: Dictionary = LOOKS[stage(g)]
	return "%s. %s" % [str(lk.n), str(lk.desc)]
