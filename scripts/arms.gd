class_name Arms
## The Eight Arms (the Hundred Arms release): the weapons the hero can carry, and the Dao of each.
##
## `axis`, `edge`: how a weapon lies in the hand while it is used (the way its length and its edge
## point, in the model's space with the arm hanging: the line a jian is held on, unless it says
## otherwise); `carry`: the same for a weapon that is carried differently from how it is used (a spear
## and a staff stand upright beside their bearer, a bow hangs by the leg) - `Arms.tick` eases between
## the two as an action begins and ends.
##
## A sweeper comes up the mountain with a broom and is given a sword.  The land has more to fight with
## than that, and the old books give every weapon a temper of its own: the jian is the gentleman of
## arms, the sabre their courage, the spear their king, the staff their grandfather.  Lin Feng can carry
## any one of eight (Esc > Arms): each is a model built from code (art/lib/arms.py), hung on the sword
## bone of whichever look the player gave him, **struck with in its own way** (a clip of its own for the
## plain blow, in battle and in the open land with F) and **walked as a Dao of its own**:
##
##   * a battle won with a weapon in the hand deepens that weapon's Dao (a lord's four times as much),
##     Novice to Adept to Master, each weapon keeping its own mastery;
##   * every rank strengthens what that weapon alone does (`mods`): the sabre's one heavy stroke, the
##     spear that goes through a guard, the staff that sweeps every foe, the fan that is never where
##     the blow lands, the bow that looses first, the whip that binds, the brush that marks;
##   * an Adept is taught the weapon's own technique (`art`), with a clip of its own.
##
## The Dao of a weapon is walked beside the Dao of the road (Data.DAOS), not instead of it.  The staff
## is the hero's own broom handle and is his from the first morning; the others are won from those
## who carried them (`step`: the quest step that gives it; Game.advance grants them like outfits).
## Trials can be passed "By the hand" (`["arms", n]`: Daos of arms mastered to Adept), Part XXI asks for
## battles won with particular weapons (a hunt with `"arm"`), and two of the ends of the story are open
## only to somebody who has, or has not, learned to put a weapon down (cultures.gd).

## battles won with a weapon in the hand for each rank (a lord counts four)
const TIERS := [0, 15, 90]

## `mods` by rank (Novice, Adept, Master).  strike: the plain blow; one: single-target techniques;
## crit: added chance of a true blow; spd: speed; pierce: the share of a foe's guard the plain blow and
## single techniques ignore; sweep: the share of the plain blow every other foe takes; evade: the chance
## the party slips a blow; qi: technique costs; first: the hero's first blow of a battle; bind: what a
## struck foe's attack is multiplied by (once a foe); mark: how much more a struck foe takes from
## everything after (once a foe).
const WEAPONS := {
	"sword": {"n": "The Jian", "zh": "the jian", "model": "jian", "clip": "attack", "art": "art_jian", "skill": "arm_one_line", "col": Color("a8d8ff"),
		"desc": "The sect's own: three feet of straight steel with two edges and a point, a blue-green stone in the guard. The old books call it the gentleman of arms, because it can do everything and insists on nothing.",
		"how": "Given with the grey robe, the first morning.",
		"dao": {"n": "Dao of the Straight Edge", "motto": "Two edges, so that it cuts the one who holds it wrongly.",
			"desc": "Lin Feng's blows land true more often, and his plain strike is a little keener."},
		"mods": {"crit": [0.05, 0.08, 0.12], "strike": [1.08, 1.14, 1.2]},
		"axis": Vector3(0, -0.75, 0.66), "edge": Vector3(0, -0.66, -0.75)},
	"staff": {"n": "The Sweeper's Staff", "zh": "the staff", "model": "staff", "clip": "arm_staff", "art": "art_staff", "skill": "arm_sweep", "col": Color("e8d8a0"),
		"desc": "The handle of the broom he swept the nine hundred steps with, of white waxwood, shod with iron at both ends by Smith Tie for a joke. The grandfather of arms: every other weapon is a stick with something added.",
		"how": "His own broom handle. It was always a staff.",
		"dao": {"n": "Dao of the Level Staff", "motto": "A broom does not choose which leaf.",
			"desc": "The plain blow sweeps on through every other foe for a share of its strength."},
		"mods": {"sweep": [0.34, 0.44, 0.55], "strike": [0.94, 0.97, 1.0]},
		"axis": Vector3(0, -0.75, 0.66), "edge": Vector3(0, -0.66, -0.75), "carry": [Vector3(0, 0.99, 0.12), Vector3(0, -0.12, 0.99)]},
	"sabre": {"n": "Iron Fang's Sabre", "zh": "the sabre", "model": "sabre", "clip": "arm_sabre", "art": "art_sabre", "skill": "arm_tiger", "col": Color("ff9a70"), "step": "s_ironfang",
		"desc": "The bandit chief's broad sabre, one edge and a heavy back, with a red cloth through the ring of the pommel. The courage of arms: it has one thing to say and says it with the whole body.",
		"how": "Taken from Iron Fang in the Whispering Bamboo.",
		"dao": {"n": "Dao of the Single Stroke", "motto": "The second cut is an apology for the first.",
			"desc": "The plain blow falls far heavier; the weight of it makes Lin Feng a little slower to act."},
		"mods": {"strike": [1.32, 1.46, 1.6], "spd": [-2.0, -2.0, -1.0]},
		"axis": Vector3(0, -0.75, 0.66), "edge": Vector3(0, -0.66, -0.75)},
	"spear": {"n": "The Armoury Spear", "zh": "the spear", "model": "spear", "clip": "arm_spear", "art": "art_spear", "skill": "arm_dragon", "col": Color("ff6a5a"), "step": "s_elder3",
		"desc": "A waxwood spear from the sect's armoury, taller than its bearer, with a red horsehair tassel under the head to blur the point. The king of arms: a hundred days for the sabre, the masters say, a thousand for the spear.",
		"how": "The Elder's leave to the armoury, at Golden Core.",
		"dao": {"n": "Dao of the Long Reach", "motto": "The point arrives; the rest of the spear is how.",
			"desc": "The plain blow and every single-target technique go through part of a foe's guard."},
		"mods": {"pierce": [0.4, 0.65, 0.9], "strike": [1.06, 1.1, 1.14]},
		"axis": Vector3(0, -0.75, 0.66), "edge": Vector3(0, -0.66, -0.75), "carry": [Vector3(0, 0.99, 0.12), Vector3(0, -0.12, 0.99)]},
	"fan": {"n": "The Empress's Fan", "zh": "the iron fan", "model": "fan", "clip": "arm_fan", "art": "art_fan", "skill": "arm_wind", "col": Color("b8f0ff"), "step": "s_empress",
		"desc": "Thirteen ribs of cold iron and a leaf of blue silk: the Ice Empress held court behind it. Shut, it is a truncheon; open, a shield, a blade and a remark. It has never once been hurried.",
		"how": "Left on the ice by the Ice Empress of Frostpeak.",
		"dao": {"n": "Dao of the Folding Wind", "motto": "Be elsewhere, politely.",
			"desc": "Now and then the party slips a blow entirely, and techniques cost a little less qi."},
		"mods": {"evade": [0.05, 0.08, 0.11], "qi": [0.95, 0.92, 0.89]},
		"axis": Vector3(0, -0.75, 0.66), "edge": Vector3(1, 0, 0)},
	"bow": {"n": "The Roc-Sinew Bow", "zh": "the bow", "model": "bow", "clip": "arm_bow", "art": "art_bow", "skill": "arm_unshot", "col": Color("ffe08a"), "step": "s_roc",
		"desc": "A recurve of horn and mulberry, strung by the horse-folk with a sinew of the Thunder Roc. Archery was one of the six arts a gentleman learned, and the only one the old masters said was a way of finding fault with oneself.",
		"how": "Strung by the horse-folk when the Thunder Roc fell.",
		"dao": {"n": "Dao of the Unloosed Arrow", "motto": "When the archer misses, he looks for the cause in himself.",
			"desc": "Lin Feng acts sooner, and his first blow of every battle lands far harder."},
		"mods": {"spd": [3.0, 5.0, 7.0], "first": [1.4, 1.65, 1.9]},
		"axis": Vector3(-1, 0, 0), "edge": Vector3(0, 1, 0), "carry": [Vector3(0, 0.96, 0.28), Vector3(0, 0.28, -0.96)]},
	"whip": {"n": "The Nine-Link Whip", "zh": "the chain whip", "model": "whip", "clip": "arm_whip", "art": "art_whip", "skill": "arm_bends", "col": Color("d0a0ff"), "step": "s_lord",
		"desc": "Nine rods of steel joined by rings, a dart at the end and a red flag to follow it by, made from the chains of the Blood Moon Palace. A soft weapon: it cannot be made to go where it is told, only allowed.",
		"how": "Nine links of the chains of the Blood Moon Palace.",
		"dao": {"n": "Dao of the Nine Bends", "motto": "The soft overcomes the hard; ask water.",
			"desc": "A foe struck with the plain blow is bound: its attack is weakened for the rest of the battle."},
		"mods": {"bind": [0.9, 0.86, 0.82], "strike": [1.0, 1.04, 1.08]},
		"axis": Vector3(0, -0.75, 0.66), "edge": Vector3(0, -0.66, -0.75)},
	"brush": {"n": "The Judge's Brush", "zh": "the judge's brush", "model": "brush", "clip": "arm_brush", "art": "art_brush", "skill": "arm_stroke", "col": Color("ff7a7a"), "step": "s_dr_king",
		"desc": "An iron brush as long as a forearm, its hair forged to a point, with a drop of cinnabar that never dries: the Dragon King's registrar signed the tides with it. It strikes where a physician would put a needle.",
		"how": "The Azure Dragon King's thanks.",
		"dao": {"n": "Dao of the Written Stroke", "motto": "A character is finished when nothing can be added.",
			"desc": "A foe struck with the plain blow is marked: everything that strikes it afterwards cuts deeper."},
		"mods": {"mark": [1.1, 1.15, 1.2], "strike": [0.96, 1.0, 1.04]},
		"axis": Vector3(0, -0.75, 0.66), "edge": Vector3(0, -0.66, -0.75)},
}
const ORDER := ["sword", "staff", "sabre", "spear", "fan", "bow", "whip", "brush"]
## what the hero has in his hands the first morning
const FIRST := ["sword", "staff"]

# ---------------------------------------------------------------- mastery
## Lin Feng's rank in a weapon's Dao (0 Novice, 1 Adept, 2 Master); the one in his hand by default.
static func tier(g, id: String = "") -> int:
	if id == "":
		id = held(g)
	var xp := int(g.arm_xp.get(id, 0))
	var t := 0
	for k in TIERS.size():
		if xp >= int(TIERS[k]):
			t = k
	return t

## The weapon in the hero's hand.
static func held(g) -> String:
	var id := str(g.arm)
	return id if WEAPONS.has(id) else "sword"

## A passive of the weapon in his hand at his rank in its Dao, or `fallback` if it has none.
static func mod(g, key: String, fallback: float) -> float:
	var w: Dictionary = WEAPONS[held(g)]
	if not w.mods.has(key):
		return fallback
	return float(w.mods[key][tier(g)])

## Daos of arms at Adept or above: what the trials and the ends of the story count.
static func adept(g) -> int:
	var n := 0
	for id in ORDER:
		if tier(g, id) >= 1:
			n += 1
	return n

static func masters(g) -> int:
	var n := 0
	for id in ORDER:
		if tier(g, id) >= 2:
			n += 1
	return n

## The technique of the weapon in his hand, once he is an Adept of its Dao.
static func skills(g) -> Array:
	return [str(WEAPONS[held(g)].skill)] if tier(g) >= 1 else []

## The clip a technique is performed with ("" for the ordinary hand seal).
static func art_of(skill_id: String) -> String:
	for id in ORDER:
		if str(WEAPONS[id].skill) == skill_id:
			return str(WEAPONS[id].art)
	return ""

## The weapons the quest step `step_id` gives (Game.advance grants them).
static func step_rewards(step_id: String) -> Array:
	var out: Array = []
	for id in ORDER:
		if str(WEAPONS[id].get("step", "")) == step_id:
			out.append(id)
	return out

## What a rank gives, in words: "plain blow +32%, speed -2".
static func mods_text(id: String, t: int) -> String:
	var names := {"strike": "plain blow", "one": "single techniques", "crit": "true blows", "spd": "speed", "pierce": "guard ignored", "sweep": "sweeps every other foe for",
		"evade": "blows slipped", "qi": "technique cost", "first": "first blow of a battle", "bind": "a struck foe's attack", "mark": "a struck foe takes"}
	var parts: Array = []
	var m: Dictionary = WEAPONS[id].mods
	for k in m:
		var v := float(m[k][t])
		match str(k):
			"spd":
				parts.append("%s %+d" % [names[k], int(v)])
			"crit", "evade":
				parts.append("%s +%d%%" % [names[k], int(round(v * 100.0))])
			"pierce", "sweep":
				parts.append("%s %d%%" % [names[k], int(round(v * 100.0))])
			_:
				parts.append("%s %+d%%" % [names[k], int(round((v - 1.0) * 100.0))])
	return ", ".join(parts)

# ---------------------------------------------------------------- in the hand
## The model of a weapon standing on its grip (art/lib/arms.py), or a plain rod if it was never built.
static func model(id: String) -> Node3D:
	var rel := "weapons/%s" % str(WEAPONS.get(id, WEAPONS.sword).model)
	if Assets.has(rel):
		return Assets.instance(rel)
	var mb := MB.new()
	mb.cyl(Vector3(0, 0.4, 0), 0.015, 0.9, MB.tag(Color("c8d0e0"), MB.METAL))
	var n := Node3D.new()
	MB.mesh_node(n, mb.build(MB.mat_plain()))
	return n

## Hang weapon `id` on a person model's sword bone (replacing whatever hung there): it lies along the
## line a jian is held on (or its own `axis`), so every clip carries it, and a clip that needs both
## hands shrinks the bone and puts it away.  False if the model has no sword bone.
static func attach(m: Node3D, id: String) -> bool:
	if m == null or not WEAPONS.has(id):
		return false
	var sks := m.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return false
	var sk := sks[0] as Skeleton3D
	var bi := sk.find_bone("sword")
	if bi < 0:
		return false
	var old := sk.get_node_or_null("arm_in_hand")
	if old != null:
		sk.remove_child(old)
		old.queue_free()
	var ba := BoneAttachment3D.new()
	ba.bone_name = "sword"
	ba.name = "arm_in_hand"
	sk.add_child(ba)
	var w: Dictionary = WEAPONS[id]
	var rest := sk.get_bone_global_rest(bi)
	var y: Vector3 = (w.axis as Vector3).normalized()
	var x: Vector3 = y.cross((w.edge as Vector3).normalized()).normalized()
	var z := x.cross(y).normalized()
	var node := model(id)
	node.name = "arm_model"
	node.transform = rest.affine_inverse() * Transform3D(Basis(x, y, z), rest.origin + y * float(w.get("slide", 0.0)))
	ba.add_child(node)
	m.set_meta("arm", id)
	# how it is carried between blows, as a turn of the sword bone (see `tick`)
	m.remove_meta("arm_carry")
	m.set_meta("arm_k", 1.0)
	sk.set_bone_pose_rotation(bi, sk.get_bone_rest(bi).basis.get_rotation_quaternion())
	if w.has("carry"):
		var cy: Vector3 = (w.carry[0] as Vector3).normalized()
		var cx: Vector3 = cy.cross((w.carry[1] as Vector3).normalized()).normalized()
		var rel := Basis(cx, cy, cx.cross(cy).normalized()) * Basis(x, y, z).inverse()
		var par := sk.get_bone_parent(bi)
		var pinv := sk.get_bone_global_rest(par).basis.inverse() if par >= 0 else Basis.IDENTITY
		m.set_meta("arm_carry", [sk, bi, sk.get_bone_rest(bi).basis.get_rotation_quaternion(), (pinv * rel * rest.basis).get_rotation_quaternion()])
		sk.set_bone_pose_rotation(bi, m.get_meta("arm_carry")[3])
	return true

## the actions a weapon is held for use in (anything else, it is carried)
const IN_USE := ["attack", "victory", "sword_dance", "cast"]

## Ease a carried weapon between the way it is carried and the way it is used (once a frame, from
## Assets.animate): `act` is the action the model is in the middle of ("" for none).
static func tick(m: Node3D, dt: float, act: String) -> void:
	if not m.has_meta("arm_carry"):
		return
	var c: Array = m.get_meta("arm_carry")
	if not is_instance_valid(c[0]):
		return
	var want := 0.0 if (act in IN_USE or act.begins_with("arm_") or act.begins_with("art_")) else 1.0
	var k := float(m.get_meta("arm_k", 1.0))
	if k == want:
		return
	k = move_toward(k, want, dt * 9.0)
	m.set_meta("arm_k", k)
	(c[0] as Skeleton3D).set_bone_pose_rotation(int(c[1]), (c[2] as Quaternion).slerp(c[3] as Quaternion, smoothstep(0.0, 1.0, k)))

## The weapon hung on a model ("" for none).
static func attached(m: Node3D) -> String:
	return str(m.get_meta("arm", "")) if m != null else ""

## The clip of the plain blow with the weapon a model carries ("attack" for the jian and for anybody
## who carries none), if the model has it.
static func strike_clip(m: Node3D) -> String:
	var id := attached(m)
	if id == "":
		return "attack"
	var c := str(WEAPONS[id].clip)
	return c if Assets.has_clip(m, c) else "attack"
