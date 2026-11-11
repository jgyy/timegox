class_name Faces
## Faces that show what they feel (the Hundred Arms release).
##
## Every human head built by art/lib/face.py carries six bones of expression that no clip moves: one
## under each eyebrow ("brow.L", "brow.R"), one at each corner of the mouth ("lip.L", "lip.R"), "lids"
## over the eye bone and "jaw" over the mouth bone.  The brows and lips are weighted to them wholly and
## the skin beneath them partly, so a cheek lifts with a smile and a forehead follows a frown.  An
## expression is a pose of those six bones, written here in the head's own measures (metres and
## radians), and worn over whatever clip the body is playing: a blink still blinks inside narrowed lids
## and a mouth still talks inside a smile, because the eye and mouth bones hang from "lids" and "jaw".
##
##   Faces.wear(model, "joy", 1.6)   -- for 1.6 seconds, then back to the face the model keeps
##   Faces.keep(model, "resolve")    -- the face it keeps from now on ("" for a calm one)
##   Faces.tick(model, dt)           -- eased towards, once a frame (Assets.animate does it)
##
## Gestures and battle actions set a face by themselves (`OF_ACT`: Models.act asks), so does what a
## body is busy with (`OF_CLIP`: asleep on a bench, at peace in meditation, set at the anvil), and a
## line of dialogue is read for one (`for_line`): a cue as its fourth element, or else its words.

## brow: [raise, tilt (+ the inner end down, a frown), towards the nose]; brow_r: the same for the
## right brow alone (a raised eyebrow); lip: [up, out] for both corners; lip_r: the right corner alone
## (a crooked smile); lids: how open the eyes are (1 as sculpted, 0.12 shut); jaw: [width, opening] of
## the mouth.
const EXPRESSIONS := {
	"calm": {},
	"smile": {"n": "A smile", "brow": [0.001, -0.04, 0.0], "lip": [0.0032, 0.0016], "lids": 0.88},
	"joy": {"n": "Joy", "brow": [0.0022, -0.08, 0.0], "lip": [0.0044, 0.0026], "lids": 0.16, "jaw": [1.12, 3.4]},
	"tender": {"n": "Tenderness", "brow": [0.0006, -0.14, 0.0], "lip": [0.002, 0.0008], "lids": 0.78},
	"sorrow": {"n": "Sorrow", "brow": [0.0004, -0.34, 0.0006], "lip": [-0.003, -0.0004], "lids": 0.74},
	"anger": {"n": "Anger", "brow": [-0.003, 0.4, 0.0022], "lip": [-0.002, -0.0006], "lids": 0.8, "jaw": [0.9, 1.0]},
	"shout": {"n": "A battle cry", "brow": [-0.0028, 0.36, 0.002], "lip": [-0.001, 0.0006], "lids": 0.86, "jaw": [1.15, 4.4]},
	"resolve": {"n": "Resolve", "brow": [-0.0016, 0.2, 0.001], "lip": [-0.0008, -0.0004], "lids": 0.9, "jaw": [0.86, 1.0]},
	"surprise": {"n": "Surprise", "brow": [0.0052, -0.06, 0.0], "lip": [-0.0004, -0.0012], "lids": 1.2, "jaw": [0.7, 4.8]},
	"fear": {"n": "Fear", "brow": [0.0034, -0.28, 0.001], "lip": [-0.0016, 0.001], "lids": 1.16, "jaw": [0.95, 2.6]},
	"pain": {"n": "Pain", "brow": [-0.0026, 0.28, 0.0024], "lip": [-0.0018, 0.0014], "lids": 0.2, "jaw": [1.1, 2.8]},
	"doubt": {"n": "Doubt", "brow": [-0.0012, 0.14, 0.0006], "brow_r": [0.0046, -0.1, 0.0], "lip": [-0.0004, 0.0], "lip_r": [0.0018, 0.001], "lids": 0.86},
	"serene": {"n": "Stillness", "brow": [0.0006, -0.05, 0.0], "lip": [0.0012, 0.0004], "lids": 0.13},
	"asleep": {"n": "Sleep", "brow": [-0.0006, -0.08, 0.0], "lip": [-0.0004, 0.0], "lids": 0.12, "jaw": [0.9, 1.6]},
}
const ORDER := ["calm", "smile", "joy", "tender", "sorrow", "anger", "shout", "resolve", "surprise", "fear", "pain", "doubt", "serene", "asleep"]
const BONES := ["brow.L", "brow.R", "lip.L", "lip.R", "lids", "jaw"]
## how fast a face changes (per second: a face is about a fifth of a second in changing)
const EASE := 11.0

## the face a gesture or a battle action is made with, and for how long ([id, seconds]; 0: as long as
## the action is remembered, for the fallen)
const OF_ACT := {
	"attack": ["shout", 0.6], "cast": ["resolve", 0.7], "hurt": ["pain", 0.6], "victory": ["joy", 2.2], "die": ["pain", 0.0],
	"laugh": ["joy", 1.6], "grieve": ["sorrow", 2.6], "shock": ["surprise", 1.3], "think": ["doubt", 2.0], "shake": ["resolve", 1.3],
	"refuse": ["anger", 1.6], "cheer": ["joy", 1.7], "shiver": ["fear", 1.9], "wave": ["smile", 1.7], "offer": ["smile", 1.7],
	"bow": ["tender", 1.6], "nod": ["smile", 1.1], "kneel": ["sorrow", 2.4], "point": ["resolve", 1.4], "beckon": ["smile", 1.6],
	"shrug": ["doubt", 1.4],
}
## the face a body keeps while it is busy with something (the looping clip it plays)
const OF_CLIP := {
	"doze": "asleep", "meditate": "serene", "pray": "serene", "soak": "serene",
	"stargaze": "tender", "gaze": "tender", "kite": "smile", "float_lantern": "tender", "release": "tender", "rock": "tender", "comb": "tender",
	"dance": "smile", "play_flute": "serene", "play_qin": "serene", "eat": "smile", "drink": "smile", "clap": "joy", "warm": "smile",
	"hammer": "resolve", "chop": "resolve", "mine": "resolve", "dig": "resolve", "hoe": "resolve", "lift": "resolve", "push": "resolve",
	"scale": "resolve", "glide": "smile", "alight": "resolve",
	"climb": "resolve", "archery": "resolve", "sword_dance": "resolve", "pound": "resolve", "carve": "resolve", "squeeze": "resolve",
	"peer": "doubt", "count": "doubt", "trace": "doubt", "read": "calm", "duck": "fear",
}

## The face a line of dialogue is said with ("" for none of its own): its cue (a fourth element, or a
## third that names a face, not a gesture), or else what its words sound like.
static func for_line(line: Array) -> String:
	for k in range(2, line.size()):
		var cue := str(line[k])
		if cue.contains(":"):
			cue = cue.get_slice(":", 1)
		if EXPRESSIONS.has(cue):
			return cue
	if line.size() < 2 or str(line[0]) == "Narrator":
		return ""
	return for_text(str(line[1]))

static func _any(low: String, words: Array) -> bool:
	for w in words:
		if low.contains(w):
			return true
	return false

static func for_text(text: String) -> String:
	var low := text.to_lower()
	if _any(low, ["haha", "hah!", "hehe", "ha! ", "splendid", "wonderful", "at last!"]):
		return "joy"
	if _any(low, ["how dare", "insolen", "you will pay", "kneel!", "die!", "thief", "get out", "i will crush", "curse you", "enough!"]):
		return "anger"
	if _any(low, ["i weep", "weeping", "my tears", "i miss", "never came back", "did not come back", "i am sorry", "i'm sorry", "forgive me", "is gone", "are gone", "too late", "alone"]):
		return "sorrow"
	if _any(low, ["what?!", "impossible", "it cannot be", "how can", "?!", "what is that"]):
		return "surprise"
	if _any(low, ["i am afraid", "afraid of", "frightened", "do not let it", "it is coming", "run!", "help us", "save us", "spare me"]):
		return "fear"
	if _any(low, ["i will not", "we will not", "i swear", "never again", "stand aside", "i must", "we must", "hold the", "so be it"]):
		return "resolve"
	if _any(low, ["thank you", "welcome", "well done", "good.", "come in", "eat,", "have you eaten", "i am glad", "glad of", "proud of"]):
		return "smile"
	if _any(low, ["child", "little one", "rest now", "sleep now", "it is all right", "gently", "i remember when you"]):
		return "tender"
	if low.strip_edges().ends_with("?") or _any(low, ["hm.", "hmm", "i wonder", "strange", "perhaps", "who told you"]):
		return "doubt"
	return ""

# ---------------------------------------------------------------- wearing one
## Wear `id` for `hold` seconds (0: until something else is worn), then go back to the face kept.
static func wear(n: Node3D, id: String, hold: float = 0.0) -> void:
	if n == null or not EXPRESSIONS.has(id):
		return
	n.set_meta("face", id)
	n.set_meta("face_hold", hold if hold > 0.0 else -1.0)

## The face a model keeps when nothing else is asked of it ("" or "calm" for none).
static func keep(n: Node3D, id: String) -> void:
	if n == null:
		return
	n.set_meta("face_keep", id if EXPRESSIONS.has(id) else "calm")
	if float(n.get_meta("face_hold", 0.0)) == 0.0:
		n.set_meta("face", n.get_meta("face_keep"))

## The face a model is wearing (or easing towards) now.
static func worn(n: Node3D) -> String:
	return str(n.get_meta("face", "calm")) if n != null else "calm"

## What an action asks of the face (Models.act): nothing if the action has none.
static func act(n: Node3D, kind: String) -> void:
	if n == null:
		return
	var key := kind
	if kind.begins_with("arm_") or kind.begins_with("art_"):
		key = "attack"
	if kind == "" and float(n.get_meta("face_hold", 0.0)) < 0.0:
		# (an action called off: the fallen get up)
		n.set_meta("face", n.get_meta("face_keep", "calm"))
		n.set_meta("face_hold", 0.0)
		return
	if not OF_ACT.has(key):
		return
	wear(n, str(OF_ACT[key][0]), float(OF_ACT[key][1]))

## The six bones of a model's skeleton and where they rest, found once: {} if it has none (an older
## head, a beast's, a procedural figure).
static func _rig(n: Node3D) -> Dictionary:
	if n.has_meta("face_rig"):
		return n.get_meta("face_rig")
	var out := {}
	var sks := n.find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty():
		var sk := sks[0] as Skeleton3D
		var ok := true
		var idx := {}
		for bn in BONES:
			var bi := sk.find_bone(bn)
			if bi < 0:
				ok = false
				break
			var par := sk.get_bone_parent(bi)
			idx[bn] = [bi, sk.get_bone_global_rest(par).affine_inverse() if par >= 0 else Transform3D.IDENTITY, sk.get_bone_global_rest(bi)]
		if ok:
			out = {"sk": sk, "b": idx}
	n.set_meta("face_rig", out)
	return out

static func has_face(n: Node3D) -> bool:
	return n != null and not _rig(n).is_empty()

## Ease the face of `n` towards the one it should wear (called once a frame with the frame's time).
## `base`: the looping clip the body plays, which may ask for a face of its own (OF_CLIP).
static func tick(n: Node3D, dt: float, base: String = "") -> void:
	var want := str(n.get_meta("face", "calm"))
	var hold := float(n.get_meta("face_hold", 0.0))
	if hold > 0.0:
		hold -= dt
		if hold <= 0.0:
			hold = 0.0
			want = str(n.get_meta("face_keep", "calm"))
			n.set_meta("face", want)
		n.set_meta("face_hold", hold)
	elif hold == 0.0:
		# nothing asked: the face of what the body is doing, or the one it keeps
		want = str(OF_CLIP.get(base, n.get_meta("face_keep", "calm")))
		if want != str(n.get_meta("face", "calm")):
			n.set_meta("face", want)
	var cur: Array = n.get_meta("face_cur", [])
	if cur.is_empty() and want == "calm":
		return
	var rig := _rig(n)
	if rig.is_empty():
		return
	var tgt := vector_of(want)
	if cur.is_empty():
		cur = vector_of("calm")
	var k := 1.0 - exp(-dt * EASE)
	var moved := false
	for i in tgt.size():
		var d: float = tgt[i] - cur[i]
		if absf(d) > 0.00002:
			cur[i] += d * k
			moved = true
		else:
			cur[i] = tgt[i]
	if not moved and bool(n.get_meta("face_set", false)):
		if want == "calm":
			n.set_meta("face_cur", [])
		return
	n.set_meta("face_cur", cur)
	n.set_meta("face_set", true)
	apply(rig, cur)

## An expression as fourteen numbers: brow L (raise, tilt, in), brow R, lip L (up, out), lip R, lids,
## jaw (width, opening).
static func vector_of(id: String) -> Array:
	var e: Dictionary = EXPRESSIONS.get(id, {})
	var bl: Array = e.get("brow", [0.0, 0.0, 0.0])
	var br: Array = e.get("brow_r", bl)
	var ll: Array = e.get("lip", [0.0, 0.0])
	var lr: Array = e.get("lip_r", ll)
	var jw: Array = e.get("jaw", [1.0, 1.0])
	return [float(bl[0]), float(bl[1]), float(bl[2]), float(br[0]), float(br[1]), float(br[2]), float(ll[0]), float(ll[1]), float(lr[0]), float(lr[1]),
		float(e.get("lids", 1.0)), float(jw[0]), float(jw[1])]

## Pose the six bones for the numbers of `vector_of` (a blend of two faces is a blend of the numbers).
static func apply(rig: Dictionary, v: Array) -> void:
	var sk: Skeleton3D = rig.sk
	if not is_instance_valid(sk):
		return
	var b: Dictionary = rig.b
	# the head is a little bigger or smaller from one model to the next: measure by the brow's height
	var s: float = (b["brow.L"][2] as Transform3D).origin.y / 1.72
	_put(sk, b["brow.L"], Vector3(-v[2], v[0], 0.0) * s, v[1], Vector3.ONE)
	_put(sk, b["brow.R"], Vector3(v[5], v[3], 0.0) * s, -v[4], Vector3.ONE)
	# (a corner drawn outwards goes back a little, round the cheek)
	_put(sk, b["lip.L"], Vector3(v[7], v[6], -absf(v[7]) * 0.5) * s, v[6] * 30.0, Vector3.ONE)
	_put(sk, b["lip.R"], Vector3(-v[9], v[8], -absf(v[9]) * 0.5) * s, -v[8] * 30.0, Vector3.ONE)
	_put(sk, b["lids"], Vector3.ZERO, 0.0, Vector3(1.0, v[10], 1.0))
	_put(sk, b["jaw"], Vector3.ZERO, 0.0, Vector3(v[11], v[12], 1.0))

## Bone `e` ([index, the inverse of its parent's rest, its own rest], both in the model's space) moved
## by `d`, turned by `roll` about the way the face looks, and scaled along the model's axes.
static func _put(sk: Skeleton3D, e: Array, d: Vector3, roll: float, scl: Vector3) -> void:
	var rest: Transform3D = e[2]
	var g := Transform3D(Basis(Vector3.BACK, roll) * Basis.from_scale(scl) * rest.basis, rest.origin + d)
	sk.set_bone_pose(int(e[0]), (e[1] as Transform3D) * g)
