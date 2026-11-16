class_name Closeup
extends RefCounted
## Close-ups (the Tall People release).  A conversation used to be one two-shot from the side that
## leaned towards whoever was speaking.  Now it is cut like a scene:
##
##  * **a line that is acted is a close-up** (`shot`): the speaker's head and shoulders, from a little
##    to one side of whoever is listening, on a longer lens; so is the first thing anybody says in a
##    conversation, and whatever is said last.  Plain lines between them stay on the two-shot, and
##    narration drifts round the scene as it did.  The camera *cuts* between them; it does not fly.
##  * **everybody of the story has one gesture nobody else has** (`SIGNATURE`: eight clips of
##    art/lib/person.py SCENE, carried by the party and lent to anybody): it is what they do the first
##    time they speak in a conversation with nothing else asked of them (`gesture`).
##  * **somebody tall is looked up at** (`frame`): the lens goes to their head, wherever that is, and
##    one of the Great People is shot from below their chin.
##
## Everything here is pure: lines in, a decision out.  The world's camera does the rest
## (World._cutscene), and with no window nobody is watching.

const CLIPS := ["stroke_beard", "sleeve_smile", "fist_palm", "stoop", "shade_eyes", "measure", "arms_cross", "hand_heart"]
## how long each lasts (art/lib/person.py)
const SECONDS := {"stroke_beard": 3.0, "sleeve_smile": 2.6, "fist_palm": 2.2, "stoop": 3.6, "shade_eyes": 3.4, "measure": 3.6, "arms_cross": 3.0, "hand_heart": 2.8}
## the face each is done with (faces.gd)
const FACES := {"stroke_beard": "doubt", "sleeve_smile": "joy", "fist_palm": "resolve", "stoop": "tender", "shade_eyes": "resolve", "measure": "doubt", "arms_cross": "anger", "hand_heart": "sorrow"}
## who does what (a speaker's name as it is written in dialogue, or the words it begins with)
const SIGNATURE := {
	"Lin Feng": "fist_palm", "Yue Ling": "sleeve_smile", "Elder Qing Xuan": "stroke_beard",
	# the Tall People (Part XXXI)
	"Fangfeng": "hand_heart", "Kuafu": "shade_eyes", "The Giant of Longbo": "stoop", "Yan Ying": "arms_cross", "The Man of Zheng": "measure",
	"Big Brother": "stoop", "Big Sister": "stoop",
	# the people of the older chapters, by what they are
	"Granny Wen": "hand_heart", "Smith Tie": "arms_cross", "Li Li": "hand_heart", "Shang Yang": "arms_cross", "Tang of Shang": "stroke_beard",
	"Hua Tuo": "stroke_beard", "Cook Ding": "measure", "Tao Kan": "arms_cross", "Budai": "sleeve_smile",
	"Guan Ning": "arms_cross", "Hua Xin": "shade_eyes", "Wei Ke": "hand_heart", "Feng Xuan": "measure", "Carpenter Gu": "measure",
	"Sai Weng": "stroke_beard", "Mazu": "shade_eyes", "Auntie Zhou": "sleeve_smile", "Clerk Bai": "measure",
}
## the lens of a close-up and how far it stands from a face of a man's size
const FOV := 34.0
const DIST := 1.75

## The gesture that is `who`'s own, or "".
static func signature(who: String) -> String:
	if SIGNATURE.has(who):
		return str(SIGNATURE[who])
	for k in SIGNATURE:
		if who.begins_with(str(k) + ",") or who.begins_with(str(k) + " "):
			return str(SIGNATURE[k])
	return ""

## Whether line `idx` of `lines` is the first its speaker says in the conversation.
static func first_of(lines: Array, idx: int) -> bool:
	var who := str(lines[idx][0])
	for i in idx:
		if str(lines[i][0]) == who:
			return false
	return true

## What the speaker of line `idx` does as it begins: the gesture the line asks for (Data.emote_for), or,
## the first time they speak with nothing asked, their own.
static func gesture(lines: Array, idx: int) -> String:
	if idx < 0 or idx >= lines.size():
		return ""
	var ec: Array = Data.emote_for(lines[idx])
	if str(ec[0]) == "Narrator" or str(ec[0]) != str(lines[idx][0]):
		return str(ec[1])
	# (a gesture the line itself was written with stands; one only read out of its words gives way, the
	# first time somebody speaks, to the gesture that is theirs)
	if (lines[idx] as Array).size() <= 2 and first_of(lines, idx) and signature(str(ec[0])) != "":
		return signature(str(ec[0]))
	return str(ec[1])

## How line `idx` is shot: "wide" (narration), "close" (the speaker alone) or "two" (the pair of them).
static func shot(lines: Array, idx: int) -> String:
	if idx < 0 or idx >= lines.size():
		return "two"
	var who := str(lines[idx][0])
	if who == "Narrator" or who == "":
		return "wide"
	if gesture(lines, idx) != "" or Faces.for_line(lines[idx]) != "" or first_of(lines, idx):
		return "close"
	# (the last word of a conversation is somebody's face)
	if idx == lines.size() - 1:
		return "close"
	return "two"

## Where the camera of a close-up stands and what it looks at: `head` is the top of the speaker's
## neck in the world, `fwd` the way they face, `sc` how big they are drawn (giants.gd), `side` +1 or
## -1 for which shoulder of the listener it looks over.  Returns [position, look-at].
static func frame(head: Vector3, fwd: Vector3, sc: float, side: float) -> Array:
	var f := Vector3(fwd.x, 0, fwd.z)
	if f.length() < 0.01:
		f = Vector3(0, 0, 1)
	f = f.normalized().rotated(Vector3.UP, 0.48 * side)
	var tall := sc > 1.3
	var d := DIST * (1.0 + (sc - 1.0) * 0.55)
	# a giant is looked up at, from where somebody of a man's height would be standing
	var rise := -0.34 * sc if tall else 0.04
	# (the box of words covers the foot of the screen: the face is framed above the middle of it)
	return [head + f * d + Vector3(0, rise, 0), head + Vector3(0, (0.02 if tall else -0.14) * sc, 0)]
