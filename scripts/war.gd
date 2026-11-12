class_name War
extends RefCounted
## Warfare (the Thundering Pots release): the host, and the field battles it fights.
##
## **The host** is raised, not recruited: a company comes in from every hearth of the land that the
## hero asks (the levy of Part XXIII), the sect sends its outer disciples, and two of the Hundred
## Works put a company in the field by themselves (the repeating crossbow, the south-pointing
## chariot).  A company is a hundred men of one arm: **foot** (spears), **bows**, **horse**, or
## **drums** (who fight with nothing but noise, and are what an air of the land is sounded on).
##
## **A field battle** is fought by drums, a dozen at most.  On each the scouts say what the other
## host means to do (unless the dust hides it), and the host is given one order:
##
##   advance   the foot go in             good against bows and against a host standing to listen
##   volley    the bows shoot             good against a spear wall and against horse coming on
##   charge    the horse go in            ruinous to bows; ruined by a spear wall
##   hold      the spear wall             breaks a charge and an advance; arrows find it
##   feint     give ground, flags up      an advance or a charge strikes air, and the next drum is yours
##   sound     the airs of the land       no blow: it is the other host's heart that is struck at
##   lead      the hero in the front rank twice a battle
##
## A host breaks when its heart does (morale at nothing) or when too few are left standing.  Nothing
## here is random and nothing keeps state between drums but the dictionary `start` returns, so the
## bot, the tests and the screen (warfield.gd) all fight the same battle.

const ARMS := ["foot", "bow", "horse"]
const ARM_NAMES := {"foot": "Foot", "bow": "Bows", "horse": "Horse", "drum": "Drums"}
const MAX_DRUMS := 12
const LEADS := 2

## the companies there are: `arm`, how it comes (`how`), and what brings it: `levy` (the keeper of a
## hearth, asked in the levy step), `step` (a step of the story done), `work` (a work built), `job`
## (a commission of the notice board done)
const COMPANIES := {
	"sect": {"n": "Outer Disciples of Azure Cloud", "arm": "foot", "col": Color("3a8ae8"), "step": "s_p23_sun",
		"how": "The Elder sends the outer disciples, when Master Sun has seen them drill.", "desc": "Sixty who have swept and forty who have not, in blue, with practice spears. They keep their dressing better than any company in the host, having been shouted at about straight lines since they were twelve."},
	"valley": {"n": "Ploughmen of the Rice Hearth", "arm": "foot", "col": Color("6a9a4a"), "levy": "granny_wen",
		"how": "Asked of Granny Wen, at the Rice Hearth.", "desc": "The men of Qingshi and Cloudfoot with hoes rehafted as spears, and straw capes against arrows, which do not help, and which nobody can persuade them to take off."},
	"steppe": {"n": "Riders of the Felt Hearth", "arm": "horse", "col": Color("8a2a3a"), "levy": "sarnai",
		"how": "Asked of Grandmother Sarnai, at the Felt Hearth.", "desc": "A hundred of the horse-folk on the dun horses that bite. They consider a battle on foot a kind of accident, and a spear wall an act of bad manners."},
	"sand": {"n": "Camel Archers of the Well", "arm": "bow", "col": Color("c8a050"), "levy": "cook_aysha",
		"how": "Asked of Cook Aysha, at the Sweet-Well Hearth.", "desc": "Caravan guards from Shazhou, who shoot from the saddle of a kneeling camel and are paid, by old custom, in water. They have asked for it in advance."},
	"river": {"n": "Haulers of the Boat Hearth", "arm": "foot", "col": Color("3a6a8a"), "levy": "fishwife_lu",
		"how": "Asked of Fishwife Lu, at the Boat Hearth.", "desc": "Tow-path men from Longmen with boat-hooks, who pull together because that is the only way they have ever done anything. When they push, the same."},
	"forge": {"n": "Founders' Crossbows of Tushan", "arm": "bow", "col": Color("8a4a2a"), "levy": "auntie_rong",
		"how": "Asked of Auntie Rong, at the Casting Hearth.", "desc": "Casters of Tushan with crossbows whose locks they cast themselves, in bronze, to a tolerance. Every bolt is the same length. They would be ashamed otherwise."},
	"dawn": {"n": "Lantern Drummers of Yanggu", "arm": "drum", "col": Color("e87a2a"), "levy": "lantern_xi",
		"how": "Asked of Lantern-Maker Xi, at the Lantern Hearth.", "desc": "The band that plays the Lantern Dragon down the main street: drums, gongs, a reed horn. They have never been to a war. They have been to a great many festivals, which they say are louder."},
	"crossbows": {"n": "The Repeating Crossbows", "arm": "bow", "col": Color("7a6a4a"), "work": "crossbow",
		"how": "Comes of itself, when the repeating crossbow has been built (the Hundred Works).", "desc": "Ten bolts to a magazine and a lever to work it: the Chancellor's crossbow, built from the drawing. It does not shoot far, or straight. It shoots often."},
	"chariots": {"n": "The South-Pointing Chariots", "arm": "horse", "col": Color("9a7a3a"), "work": "chariot",
		"how": "Comes of itself, when the south-pointing chariot has been built (the Hundred Works).", "desc": "War chariots with the little wooden man on each, whose arm points south whichever way the horses run. In fog, in smoke, in the dust of eight thousand feet, they know where the line is."},
	"hunters": {"n": "Hunters of the High Roads", "arm": "bow", "col": Color("5a6a3a"), "job": "job_hunters", "scouts": true,
		"how": "For a commission of the notice board in Qingshi.", "desc": "The hunters of the camps of the road, forty-five of them, who came in by themselves when they heard. They do not stand in ranks. They are, however, somewhere ahead of the host, and no dust hides anything from them."},
	"players": {"n": "The Pear Garden Players", "arm": "drum", "col": Color("1e6a5a"), "job": "job_stage",
		"how": "For a commission of the notice board in Qingshi.", "desc": "The stage company of Qingshi in full paint, with the big drum off the stage cart. They have died in a hundred battles, nightly, and got up for the next act. They find the real thing under-rehearsed."},
	# the Three Burrows release (hold.gd): `hold`: comes when the hero's own town has a wall and a drill ground
	"guiyun": {"n": "The Watch of Guiyun", "arm": "foot", "col": Color("d8c8a0"), "hold": true,
		"how": "Comes of itself, when Guiyun has a wall and a drill ground (Esc > Town).", "desc": "A hundred who were woodcutters, pedlars and tea-pickers the year before, with spears from their own smithy. They are not well drilled. They chose who stands on either side of them, and no drill-master has ever found a way to put that in."},
}
const ORDER := ["sect", "valley", "steppe", "sand", "river", "forge", "dawn", "crossbows", "chariots", "hunters", "players", "guiyun"]

## the orders: `need` what the host must have to give it
const ORDERS := {
	"advance": {"n": "Advance", "sign": "the fish-scale", "need": "foot", "desc": "The foot go in, shield to shoulder. Good against bows and against a host that stands to listen; a spear wall stops it, and a host that gives ground lets it strike air."},
	"volley": {"n": "Volley", "sign": "the crane's wing", "need": "bow", "desc": "The bows shoot, rank by rank. Arrows find a spear wall standing still, and horse coming on over open ground; men already at push of pike are hard to pick out."},
	"charge": {"n": "Charge", "sign": "the arrowhead", "need": "horse", "desc": "The horse go in. Ruinous to bows and to anybody singing; a spear wall ruins them instead."},
	"hold": {"n": "Hold", "sign": "the square", "need": "", "desc": "The spear wall, and nobody moves. A charge breaks on it and an advance spends itself. Arrows find it, and a song finds it standing with nothing to do but listen."},
	"feint": {"n": "Give ground", "sign": "the long snake", "need": "", "desc": "Back forty paces in good order, flags up. An advance or a charge strikes air, and whoever struck it is out of their ground: the next drum, everything of yours tells half as much again. It costs a little heart to turn the back."},
	"sound": {"n": "Sound the airs", "sign": "songs on four sides", "need": "air", "desc": "No blow is struck. The drums and every throat in the host sound the airs of the land, and it is the other host's heart that is struck at: hardest when they stand to listen, least when they are already shouting."},
	"lead": {"n": "Go in front", "sign": "the banner forward", "need": "lead", "desc": "Lin Feng goes in the front rank himself. Wherever he is, it tells like a company and a half, and the host takes heart. Twice a battle; it costs him."},
}
const ORDER_IDS := ["advance", "volley", "charge", "hold", "feint", "sound", "lead"]

## how much of what an order does gets through, by what the other host is doing: DEAL[mine][theirs]
const DEAL := {
	"advance": {"advance": 1.0, "volley": 1.4, "charge": 1.0, "hold": 0.5, "feint": 0.3, "sound": 1.3, "lead": 0.9},
	"volley": {"advance": 0.8, "volley": 1.0, "charge": 1.5, "hold": 1.25, "feint": 0.9, "sound": 1.2, "lead": 0.8},
	"charge": {"advance": 1.0, "volley": 2.0, "charge": 1.0, "hold": 0.35, "feint": 0.3, "sound": 1.5, "lead": 0.9},
	"lead": {"advance": 1.0, "volley": 1.2, "charge": 1.0, "hold": 0.8, "feint": 0.4, "sound": 1.2, "lead": 1.0},
	"sound": {"advance": 0.5, "volley": 0.8, "charge": 0.5, "hold": 1.5, "feint": 1.3, "sound": 1.0, "lead": 0.6},
}
## how hard each arm strikes (a man's worth a drum), the horse a spear wall costs a charge, what a
## drum of holding gives back to the heart and what a feint costs it, what being drawn out is worth
## to the other side, and how much heart a hundredth of the host lost takes
const STRIKE := {"advance": 0.3, "volley": 0.26, "charge": 0.5}
const WALL_COST := 0.12
const HOLD_HEART := 3.0
const FEINT_HEART := 3.0
const DRAWN := 1.5
const LOSS_HEART := 1.4
const BREAK_MEN := 0.18
const NEAR_BROKEN := 0.3
const SOUND_BASE := 5.0
const SOUND_AIR := 2.6
const SOUND_DRUM := 3.0
const LEAD_MEN := 150.0
const LEAD_HEART := 8.0
const LEAD_COST := 0.2
## each time a field is lost the other host comes back so much the weaker (it has marched, too)
const TIRED := 0.9

## The fields.  `foe`: the other host's men by arm; `heart`: its morale; `plan`: what it does, drum
## by drum (round again when it runs out); `dust`: the drums on which the scouts cannot say (unless
## the hunters are out in front); `deaf`: how little of a song it hears (1 everything);
## `rule`: something this field does that others do not; `story`: fought in the story, or on the
## drill ground at Qingshi for practice (`after`: the step that opens it).
const BATTLES := {
	"lishan": {"n": "The Field under Mount Li", "foe_n": "The Clay Host, the Vanguard of the Left", "story": true, "area": "millet", "tune": "clay",
		"foe": {"foot": 420, "bow": 80, "horse": 60}, "heart": 100.0, "deaf": 0.7,
		"plan": ["advance", "advance", "hold", "charge", "advance", "volley", "hold", "advance"], "dust": [],
		"desc": "Six hundred of fired clay in ranks of four, as they stood in the pits: mostly foot, a file of kneeling archers, a few horse. They do not tire and they do not hurry, and they do everything by the count.",
		"won": "The left vanguard of Mount Li stands where it stopped, between one step and the next, and the dust comes down on it."},
	"river": {"n": "The Bank at Longmen", "foe_n": "The Clay Host, the Chariots of the Centre", "story": true, "area": "longmen", "tune": "clay", "rule": "river",
		"foe": {"foot": 360, "bow": 160, "horse": 200}, "heart": 105.0, "deaf": 0.6,
		"plan": ["volley", "charge", "charge", "hold", "volley", "charge", "advance", "hold", "charge", "volley"], "dust": [2, 6],
		"desc": "The centre of the pits: chariots four abreast, crossbows kneeling between them. Master Sun has drawn the host up with its back to the river, where no book says to: a man with water behind him has nowhere to run to, and knows it. The host cannot give ground here. It does not break while it holds.",
		"won": "With the river at its heels the levy did not go back a step, having nowhere to step to. The chariots of Mount Li stand axle-deep in the shallows, pointing every way but south."},
	"gaixia": {"n": "Gaixia", "foe_n": "The Hegemon-King and the Eight Thousand", "story": true, "area": "dunes", "tune": "war", "rule": "song",
		"foe": {"foot": 480, "bow": 160, "horse": 260}, "heart": 130.0, "deaf": 1.9,
		"plan": ["charge", "advance", "charge", "hold", "advance", "charge", "volley", "hold", "charge", "advance", "hold", "hold"], "dust": [1, 4, 8],
		"desc": "Eight thousand of clay with a king of flesh in front, who has never lost a charge and has lost every war. No host in the land can break this one by killing it: it is the last field of somebody who has fought it a thousand times. But they were men of Chu before they were clay, and the levy knows six airs.",
		"won": "From four sides, in the dusk, six airs that are all the same song. One by one the eight thousand of Mount Li ground their halberds, the way a man does who has just heard his mother's kitchen. By the third verse the Hegemon-King stands in front of nobody."},
	# ---- the drill ground at Qingshi: Master Sun's three lessons, fought with blunted spears
	"drill1": {"n": "First Lesson: the Spear Wall", "foe_n": "Master Sun's Blue Flags", "story": false, "after": "s_p23_sun", "tune": "war",
		"foe": {"foot": 120, "bow": 0, "horse": 240}, "heart": 70.0, "deaf": 1.0,
		"plan": ["charge", "charge", "hold", "charge"], "dust": [],
		"desc": "Half the levy under blue flags, mostly horse, who will charge until they are stopped. \"Know the other and know yourself,\" says Master Sun, \"and in a hundred battles you will not be in peril. Begin by knowing a horse.\"",
		"won": "Master Sun counts the blue flags on the ground and says nothing, which the levy is learning to hear as praise."},
	"drill2": {"n": "Second Lesson: the Empty Fort", "foe_n": "Master Sun's Blue Flags", "story": false, "after": "s_p23_lishan", "tune": "war",
		"foe": {"foot": 300, "bow": 200, "horse": 60}, "heart": 85.0, "deaf": 1.0,
		"plan": ["hold", "volley", "hold", "advance", "volley", "hold"], "dust": [1, 3],
		"desc": "The blue flags stand and shoot and will not come out. \"All war is deception,\" says Master Sun. \"When able, seem unable; when near, seem far. He who stands behind a wall has told you everything. Tell him something.\"",
		"won": "\"The supreme excellence,\" says Master Sun, picking a blunted arrow out of his sleeve, \"is to break the other without fighting. That was not it. It was, however, adequate.\""},
	"drill3": {"n": "Third Lesson: Know the Other", "foe_n": "Master Sun Himself", "story": false, "after": "s_p23_river", "tune": "war",
		"foe": {"foot": 320, "bow": 220, "horse": 220}, "heart": 110.0, "deaf": 0.9,
		"plan": ["feint", "charge", "volley", "hold", "advance", "feint", "charge", "sound", "volley", "advance"], "dust": [0, 2, 5, 7],
		"desc": "Master Sun takes the blue flags himself, and the dust is his. \"Water has no constant shape,\" he says, \"and war no constant form. I shall not tell you what I am going to do. Nobody will again.\"",
		"won": "Master Sun rolls up the thirteen chapters and holds them out. \"You have read the other one,\" he says. \"The one I could not write down. Keep these for somebody who has not.\""},
}
const BATTLE_ORDER := ["lishan", "river", "gaixia", "drill1", "drill2", "drill3"]

## the regions the clay host is abroad in while Part XXIII is being played (music.gd, the world)
const ABROAD := ["millet", "longmen", "dunes", "village"]
const ABROAD_FROM := "s_p23_home"
const ABROAD_TO := "s_p23_end"

# ---------------------------------------------------------------- the host
## The companies in the host now.
static func companies(g) -> Array:
	var out: Array = []
	for id in ORDER:
		var c: Dictionary = COMPANIES[id]
		if g.host.has(id) or (c.has("work") and Works.has(g, str(c.work))) or (c.has("step") and g.done(str(c.step))) or (c.has("job") and Jobs.is_done(g, str(c.job))) or (c.has("hold") and Hold.watch(g)):
			out.append(id)
	return out

static func has(g, id: String) -> bool:
	return companies(g).has(id)

## A company comes in (the levy): true if it is new.
static func raise(g, id: String) -> bool:
	if not COMPANIES.has(id) or g.host.has(id):
		return false
	g.host[id] = true
	g.toast("The host: %s come in" % str(COMPANIES[id].n))
	g.note("%s joined the host" % str(COMPANIES[id].n))
	return true

## The company a keeper of a hearth sends ("" if none).
static func levy_of(npc: String) -> String:
	for id in ORDER:
		if str(COMPANIES[id].get("levy", "")) == npc:
			return id
	return ""

## The men of the host by arm: {"foot", "bow", "horse", "drum"}.
static func muster(g) -> Dictionary:
	var out := {"foot": 0, "bow": 0, "horse": 0, "drum": 0}
	for id in companies(g):
		out[str(COMPANIES[id].arm)] += 100
	return out

static func scouts(g) -> bool:
	for id in companies(g):
		if bool(COMPANIES[id].get("scouts", false)):
			return true
	return false

## How hard the airs of the land strike at a heart: the airs known and the drums to sound them on.
static func sound_power(g) -> float:
	return SOUND_BASE + SOUND_AIR * g.airs.size() + SOUND_DRUM * (float(muster(g).drum) / 100.0)

static func abroad(g, area: String) -> bool:
	return ABROAD.has(area) and g.reached(ABROAD_FROM) and not g.done(ABROAD_TO)

static func open(g, id: String) -> bool:
	var b: Dictionary = BATTLES[id]
	return bool(b.story) or g.done(str(b.get("after", "")))

# ---------------------------------------------------------------- a battle
## The state a battle begins in.
static func start(g, id: String) -> Dictionary:
	var b: Dictionary = BATTLES[id]
	var m := muster(g)
	var tired := pow(TIRED, float(g.war_tries.get(id, 0)))
	var foe := {}
	for a in ARMS:
		foe[a] = float(b.foe.get(a, 0)) * tired
	var mine := {"foot": float(m.foot), "bow": float(m.bow), "horse": float(m.horse)}
	return {"id": id, "drum": 0, "over": "", "rule": str(b.get("rule", "")),
		"me": {"men": mine, "start": _total(mine), "heart": 100.0, "drawn": false, "drums": float(m.drum) / 100.0},
		"foe": {"men": foe, "start": _total(foe), "heart": float(b.heart) * tired, "heart0": float(b.heart) * tired, "drawn": false},
		"sound": sound_power(g), "airs": g.airs.size(), "deaf": float(b.get("deaf", 1.0)), "leads": LEADS, "scouts": scouts(g), "level": g.level,
		"feints": 0, "log": [], "last": {}}

static func _total(men: Dictionary) -> float:
	var n := 0.0
	for a in ARMS:
		n += float(men.get(a, 0.0))
	return n

## What the other host does on the drum now beginning.
static func foe_order(st: Dictionary) -> String:
	var plan: Array = BATTLES[st.id].plan
	var o := str(plan[int(st.drum) % plan.size()])
	# an arm that is gone cannot be ordered: the foot stand instead
	var need := str(ORDERS[o].need)
	if need in ARMS and float(st.foe.men[need]) < 1.0:
		return "advance" if float(st.foe.men.foot) >= 1.0 and o != "advance" else "hold"
	return o

## What the scouts say of it ("" if the dust hides it).
static func intent(st: Dictionary) -> String:
	var dust: Array = BATTLES[st.id].dust
	if dust.has(int(st.drum) % (BATTLES[st.id].plan as Array).size()) and not bool(st.scouts):
		return ""
	return foe_order(st)

## Whether the host can be given order `o` now, and if not, why ("" if it can).
static func blocked(st: Dictionary, o: String) -> String:
	match str(ORDERS[o].need):
		"foot", "bow", "horse":
			if float(st.me.men[str(ORDERS[o].need)]) < 1.0:
				return "No %s left in the host." % str(ARM_NAMES[str(ORDERS[o].need)]).to_lower()
		"air":
			if int(st.airs) < 1 and float(st.me.drums) < 1.0:
				return "The host knows no air of the land, and has no drums to sound one on."
		"lead":
			if int(st.leads) < 1:
				return "He has gone in front twice already."
	if o == "feint" and str(st.rule) == "river":
		return "The river is behind the host: there is no ground to give."
	return ""

static func orders(st: Dictionary) -> Array:
	return ORDER_IDS.filter(func(o): return blocked(st, o) == "")

## What one side's order does to the other: {"men": men felled, "heart": heart struck at directly}.
static func _deal(st: Dictionary, side: String, o: String, their: String) -> Dictionary:
	var me: Dictionary = st[side]
	var out := {"men": 0.0, "heart": 0.0}
	var k := float(DEAL.get(o, {}).get(their, 0.0))
	if bool(st["foe" if side == "me" else "me"].drawn):
		k *= DRAWN
	match o:
		"advance":
			out.men = float(me.men.foot) * float(STRIKE.advance) * k
		"volley":
			out.men = float(me.men.bow) * float(STRIKE.volley) * k
		"charge":
			out.men = float(me.men.horse) * float(STRIKE.charge) * k
		"lead":
			# (only the hero leads: a tenth of the host's foot goes in with him)
			out.men = (LEAD_MEN * (0.6 + 0.4 * float(st.level) / float(Data.MAX_LEVEL)) + float(me.men.foot) * 0.08) * float(STRIKE.advance) * k
		"sound":
			if side == "me":
				out.heart = float(st.sound) * k * float(st.deaf)
			else:
				out.heart = 9.0 * k
	return out

## Take `n` men off a host: from the arm that was in the way first (the foot, unless the order put
## another in front), the rest in proportion.
static func _lose(men: Dictionary, n: float, front: String) -> float:
	var left := n
	var lost := 0.0
	for a in [front] + ARMS:
		if left <= 0.0:
			break
		var take := minf(float(men[a]), left * (0.7 if a == front else 1.0))
		men[a] = float(men[a]) - take
		left -= take
		lost += take
	return lost

static func _front(o: String) -> String:
	return {"volley": "bow", "charge": "horse"}.get(o, "foot")

## One drum: the host is given `mine`, the other host does what it does.  The state moves on; what
## happened is in `st.last` (for the screen) and in words at the end of `st.log`.
static func step(st: Dictionary, mine: String) -> void:
	if str(st.over) != "":
		return
	var their := foe_order(st)
	var a := _deal(st, "me", mine, their)
	var b := _deal(st, "foe", their, mine)
	var me: Dictionary = st.me
	var foe: Dictionary = st.foe
	# a spear wall costs a charge some of its horse
	if mine == "charge" and their == "hold":
		b.men += float(me.men.horse) * WALL_COST
	if their == "charge" and mine == "hold":
		a.men += float(foe.men.horse) * WALL_COST
	var lost_foe := _lose(foe.men, float(a.men), _front(their))
	var lost_me := _lose(me.men, float(b.men), _front(mine))
	foe.heart = float(foe.heart) - float(a.heart) - lost_foe / maxf(1.0, float(foe.start)) * 100.0 * LOSS_HEART
	me.heart = float(me.heart) - float(b.heart) - lost_me / maxf(1.0, float(me.start)) * 100.0 * LOSS_HEART
	# what the orders do to the heart of whoever gave them
	for pr in [[me, mine], [foe, their]]:
		match str(pr[1]):
			"hold":
				pr[0].heart = float(pr[0].heart) + HOLD_HEART
			"feint":
				pr[0].heart = float(pr[0].heart) - FEINT_HEART
			"sound":
				pr[0].heart = float(pr[0].heart) + 3.0
			"lead":
				pr[0].heart = float(pr[0].heart) + LEAD_HEART
	me.heart = minf(float(me.heart), 100.0)
	foe.heart = minf(float(foe.heart), float(foe.heart0))
	# who was drawn out of their ground this drum
	me.drawn = their == "feint" and mine in ["advance", "charge", "lead"]
	foe.drawn = mine == "feint" and their in ["advance", "charge"]
	if mine == "lead":
		st.leads = int(st.leads) - 1
	st.feints = int(st.feints) + 1 if mine == "feint" else 0
	st.last = {"mine": mine, "their": their, "lost_me": lost_me, "lost_foe": lost_foe, "heart_foe": float(a.heart), "heart_me": float(b.heart)}
	st.log.append(_told(st, mine, their, lost_me, lost_foe, float(a.heart)))
	st.drum = int(st.drum) + 1
	# the end: a heart gone, too few standing, or the last drum
	var foe_broke: bool = float(foe.heart) <= 0.0 or (_total(foe.men) <= float(foe.start) * BREAK_MEN and str(st.rule) != "song")
	var me_broke: bool = float(me.heart) <= 0.0 or _total(me.men) <= float(me.start) * BREAK_MEN
	# (with the river behind it a host that holds does not break: it has nowhere to break to)
	if me_broke and str(st.rule) == "river" and mine == "hold" and _total(me.men) > float(me.start) * BREAK_MEN:
		me_broke = false
		me.heart = maxf(float(me.heart), 6.0)
	if foe_broke and (not me_broke or float(me.heart) >= float(foe.heart)):
		st.over = "won"
	elif me_broke:
		st.over = "lost"
	elif int(st.drum) >= MAX_DRUMS:
		# the last drum, and neither heart gone: the field is the host's only if the other host is all
		# but broken (standing behind a wall all day holds nothing)
		st.over = "won" if float(foe.heart) / float(foe.heart0) < NEAR_BROKEN and float(me.heart) / 100.0 > float(foe.heart) / float(foe.heart0) and str(st.rule) != "song" else "lost"

static func _told(st: Dictionary, mine: String, their: String, lost_me: float, lost_foe: float, heart: float) -> String:
	var k := float(DEAL.get(mine, {}).get(their, 1.0))
	var how := ""
	match mine:
		"hold":
			how = "The wall held." if their in ["advance", "charge"] else ("Arrows found the wall." if their == "volley" else "The host stood.")
		"feint":
			how = "They struck air, and are out of their ground." if their in ["advance", "charge"] else "The host gave ground for nothing."
		"sound":
			how = "The airs went over the field, and they stood and heard them." if k >= 1.2 else ("The airs were lost in the shouting." if k <= 0.6 else "The airs went over the field.")
		_:
			how = "It told." if k >= 1.3 else ("It broke on them." if k <= 0.5 else "It was even.")
	var out := "Drum %d: %s against their %s. %s" % [int(st.drum) + 1, str(ORDERS[mine].n).to_lower(), str(ORDERS[their].n).to_lower(), how]
	out += " Lost %d; they lost %d" % [int(round(lost_me)), int(round(lost_foe))]
	if heart > 0.5:
		out += " and %d of their heart" % int(round(heart))
	return out + "."

## How good order `o` would be against what the scouts say (the higher the better): what the bot
## asks, and what the screen shows as a hint.  Nothing is changed.
static func worth(st: Dictionary, o: String) -> float:
	var their := intent(st)
	if their == "":
		# (the dust: the plainest thing the other host does is its first order of all)
		their = "advance"
	var c: Dictionary = st.duplicate(true)
	# (as if the scouts were right)
	var a := _deal(c, "me", o, their)
	var b := _deal(c, "foe", their, o)
	if o == "charge" and their == "hold":
		b.men += float(c.me.men.horse) * WALL_COST
	if their == "charge" and o == "hold":
		a.men += float(c.foe.men.horse) * WALL_COST
	var gain := float(a.heart) + float(a.men) / maxf(1.0, float(c.foe.start)) * 100.0 * LOSS_HEART
	var loss := float(b.heart) + float(b.men) / maxf(1.0, float(c.me.start)) * 100.0 * LOSS_HEART
	# (what is asked is whose heart goes first: each as a part of what is left of it)
	var v := gain / maxf(1.0, float(c.foe.heart)) - loss / maxf(1.0, float(c.me.heart)) * 1.1
	match o:
		"hold":
			v += 0.02
		"feint":
			# (what being out of their ground will be worth on the next drum, if it is not already so)
			v += (0.09 if their in ["advance", "charge"] and not bool(c.foe.drawn) else -0.08)
		"lead":
			v -= 0.03
	# a field that only a song can win is sung over
	if str(st.rule) == "song" and o == "sound":
		v += 0.1
	return v

## The order the bot (and Master Sun, asked) would give.
static func best(st: Dictionary) -> String:
	var out := "hold"
	var bv := -99.0
	for o in orders(st):
		var v := worth(st, o)
		if v > bv:
			bv = v
			out = o
	return out

## A whole battle fought by `best` (the tests, and the bot's forecast): "won" or "lost", and the
## state it ended in.
static func play(g, id: String) -> Dictionary:
	var st := start(g, id)
	while str(st.over) == "":
		step(st, best(st))
	return st

## A battle is over: kept, counted, told.
static func record(g, st: Dictionary, given: Dictionary) -> void:
	for o in given:
		g.war_orders[o] = int(g.war_orders.get(o, 0)) + int(given[o])
	var id := str(st.id)
	if str(st.over) == "won":
		if not g.war_won.has(id) or int(st.drum) < int(g.war_won[id]):
			g.war_won[id] = int(st.drum)
		g.note("Held the field: %s, in %d drums" % [str(BATTLES[id].n), int(st.drum)])
		g.add_renown(4 if bool(BATTLES[id].story) else 2)
	else:
		g.war_lost += 1
		g.war_tries[id] = int(g.war_tries.get(id, 0)) + 1
		g.note("Driven from the field: %s" % str(BATTLES[id].n))

## The host's page: a company's line and what is known of it.
static func label(g, id: String) -> String:
	return ("%s  (%s)" % [str(COMPANIES[id].n), str(ARM_NAMES[str(COMPANIES[id].arm)]).to_lower()]) if has(g, id) else "?  " + str(ARM_NAMES[str(COMPANIES[id].arm)])

static func text(g, id: String) -> String:
	var c: Dictionary = COMPANIES[id]
	if not has(g, id):
		return "Not yet in the host.\n\n" + str(c.how)
	return str(c.desc) + "\n\nA hundred %s. %s" % [str(ARM_NAMES[str(c.arm)]).to_lower(), str(c.how)]
