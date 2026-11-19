class_name Seals
extends RefCounted
## The papers of the Daos (the Red Seal release): a certificate for every Dao there is.
##
## For thirty-eight chapters what Lin Feng could do was known to whoever had seen him do it.  The **Hall
## of Seals** has now put a desk beside the post in six towns (`DESKS`, open once the story has brought its
## registrar up the mountain: `OPEN`), and **every one of the seventeen Daos has a paper** (the ids are
## those of rites.gd: the six roads, the eight Daos of arms as `a_<arm>`, the three of the forbidden shelf
## as `t_<id>`):
##
##   * a **road** he has walked or a **weapon** he is an Adept of is *examined*: he performs its rite in
##     front of the desk (rites.gd; with no window it is three lines), pays the fee, and the paper is
##     sealed at the **grade** his standing in that Dao has earned today (`GRADES`, `due`).  A paper can be
##     sat again when he has grown past it;
##   * a **forbidden** Dao cannot be certified, and is not: its paper is an **abjuration**, sealed for
##     somebody whose shelf has never been opened, and **void from the day he sits to that art**
##     (`valid`).  A paper says a thing about him, and stops being a paper when the thing stops being true.
##
## What a paper is for: the lists (lists.gd) admit nobody without one, a purse is a little heavier for every
## paper he holds (`mod`), and the sealed room of an auction house (auction.gd) is opened by three.  A
## step may ask for so many (`"kind": "seal"`), and the bot sits whatever `ready` names.
##
## Nothing here is random.  The Hall seals nothing for a hand a town has a price on (`Crime.SHUT.seal`),
## and nothing for somebody the shelf has marked.

## the step that opens the desks, and the offices that keep one
const OPEN := "s_p39_home"
const DESKS := ["treasurer", "head_qingshi", "post_cloudfoot", "harbour_longmen", "guild_tushan", "warden_yanggu"]
## the grades of a paper, and what a sitting costs (by his level, for each grade of the paper sat)
const GRADES := ["", "Entered", "Proven", "Attested"]
const ABJURED := "Abjured"
const FEE_BASE := 60.0
const FEE_LV := 4.0
## what every paper he holds adds to a purse of the lists, and how many open an auction house's sealed room
const PURSE := 0.02
const ROOM := 3
## who examines
const EXAMINER := "Registrar Yin Wen"

## What the examiner asks of each Dao before the brush is wetted: one line a paper.
const ASKS := {
	"sword": "The Sword Road. Everybody who comes to this desk says they walk it. Show me the part of it that is not the sword.",
	"wander": "Free Wandering. I am to certify that you go where you like. Stand still, then. I want to see whether you can do that too.",
	"heart": "The Compassionate Heart. I shall say something unkind about you, and watch what your face does. I have already said it. Good.",
	"formation": "Formations. Set one out on my desk with what is on my desk. No. The ink-stone stays where it is. That is the examination.",
	"alchemy": "The Cauldron. I do not want a pill. I want you to tell me, before the fire is lit, what this one will fail of.",
	"illusion": "Illusion. Show me something that is not there, and then tell me which of us it fooled. I shall know if you guess.",
	"a_sword": "The straight sword. One cut, at the height of this candle, and the candle is to stay lit. Most people bring me a shorter candle.",
	"a_staff": "The staff. It is the first thing put into a child's hand and the last thing anybody masters. Lean on it. Now do not.",
	"a_sabre": "The sabre. I have certified four people in it and buried two. Show me where it stops. Everybody can show me where it goes.",
	"a_spear": "The spear. The length of it is the whole Dao. Stand at the far end of this room and touch my inkwell without spilling it.",
	"a_fan": "The fan. Open it, and tell me what the wind in this hall was doing before you did. That is all. That is the paper.",
	"a_bow": "The bow. I do not need to see an arrow fly. Draw, and hold, and let down again. I am watching your breath, not the string.",
	"a_whip": "The whip. Take the dust off the top of that scroll. The scroll is the registry of the Hall, and I am fond of it.",
	"a_brush": "The brush. Write your own name. I have failed more people on that than on all the others together.",
	"t_blood": "The art of the blood. I do not certify it. I certify that your shelf is shut. Give me your wrist; I shall know.",
	"t_soul": "The art of the taken soul. This paper says only that you have never sat to it. Look at me while I write that.",
	"t_husk": "The art of the husk. One line, and my seal: never opened. If it ever stops being true the ink knows before I do.",
}

## Every paper there is, in order (rites.gd).
static func order() -> Array:
	return Rites.ORDER

static func kind(id: String) -> String:
	return str(Rites.RITES.get(id, {}).get("kind", ""))

static func key(id: String) -> String:
	return str(Rites.RITES.get(id, {}).get("key", ""))

## What the paper of `id` is called.
static func name_of(id: String) -> String:
	if kind(id) == "taboo":
		return "Abjuration: %s" % Rites.dao_name(id)
	return "Paper of the %s" % Rites.dao_name(id)

## Whether the desks are open to the journey of `g`, and whether `office` keeps one.
static func open(g) -> bool:
	return g.done(OPEN)

static func is_desk(office: String) -> bool:
	return DESKS.has(office)

## The grade the paper of `id` would be sealed at today (0: there is nothing to seal).
static func due(g, id: String) -> int:
	match kind(id):
		"road":
			return clampi(1 + g.dao_tier(key(id)), 1, 3) if g.dao_xp.has(key(id)) else 0
		"arm":
			return clampi(1 + Arms.tier(g, key(id)), 2, 3) if Rites.his(g, id) else 0
		"taboo":
			# (the Sea Floor release: nor is it written afresh for somebody who has knelt for the shelf)
			return 1 if Taboo.depth(g, key(id)) == 0 and not Taboo.marked(g) and not g.taboo.has("atoned") else 0
	return 0

## Whether the paper he holds of `id` still says something true.
static func valid(g, id: String) -> bool:
	if not g.seals.has(id):
		return false
	return kind(id) != "taboo" or Taboo.depth(g, key(id)) == 0

## The grade of the paper he holds of `id` (0 with none, or with one that is void).
static func grade(g, id: String) -> int:
	return int(g.seals[id].grade) if valid(g, id) else 0

static func grade_name(g, id: String) -> String:
	if grade(g, id) == 0:
		return "void" if g.seals.has(id) else ""
	return ABJURED if kind(id) == "taboo" else str(GRADES[grade(g, id)])

## The papers he holds that are good, in order; and how many.
static func held(g) -> Array:
	var out: Array = []
	if g.seals.is_empty():
		return out
	for id in order():
		if valid(g, id):
			out.append(id)
	return out

static func count(g) -> int:
	return held(g).size()

## How many of his papers are of kind `k` ("road", "arm", "taboo").
static func count_of(g, k: String) -> int:
	var n := 0
	for id in held(g):
		if kind(id) == k:
			n += 1
	return n

## What a sitting for the paper of `id` costs today.
static func fee(g, id: String) -> int:
	return int(round((FEE_BASE + FEE_LV * float(g.level)) * float(maxi(1, due(g, id)))))

## Why the paper of `id` cannot be sat for now ("" if it can).  `area`: where the desk is.
static func blocked(g, id: String, area: String = "") -> String:
	if not open(g):
		return "The Hall of Seals keeps no desk here yet."
	if Taboo.marked(g):
		return "\"The Hall seals nothing for a hand the shelf has marked. Go to the Hall of Discipline. Then come back.\""
	if area != "" and Crime.shut(g, area, "seal") != "":
		return Crime.shut(g, area, "seal")
	var d := due(g, id)
	if d == 0:
		match kind(id):
			"road":
				return "It is not a road he has walked."
			"arm":
				return "He is not yet an Adept of it: the Hall examines nobody who is still learning where the edge is."
			_:
				return "\"That shelf has been opened. I do not write what is not so.\""
	if grade(g, id) >= d:
		return "The paper he holds is as high as he stands in it today."
	if int(g.stones) < fee(g, id):
		return "A sitting is %d spirit stones." % fee(g, id)
	return ""

## The paper of `id` is sat for and sealed.  Returns what is said ([] if it could not be).
static func sit(g, id: String, area: String = "") -> Array:
	if blocked(g, id, area) != "":
		return []
	var d := due(g, id)
	var first: bool = not g.seals.has(id)
	g.stones -= fee(g, id)
	g.seals[id] = {"grade": d, "day": int(g.day)}
	g.seals_sat = int(g.seals_sat) + 1
	var gn := ABJURED if kind(id) == "taboo" else str(GRADES[d])
	g.note("%s: %s (%s)" % ["Sealed" if first else "Sealed again", name_of(id), gn])
	var lines: Array = [[EXAMINER, str(ASKS[id])]]
	if kind(id) == "taboo":
		lines.append(["Narrator", "The registrar holds Lin Feng's wrist for the space of three breaths, lets it go, and writes one line. The seal goes on red and square: %s. %s." % [name_of(id), gn]])
	else:
		lines.append(["Narrator", "Lin Feng does what was asked. The registrar watches the whole of it without moving, wets the brush, and writes for some time. The seal goes on red and square: %s. %s." % [name_of(id), gn]])
	return lines

## The paper the bot (or anybody who only wants the next one) would sit for now: the first that can be.
static func ready(g, area: String = "") -> String:
	for id in order():
		if blocked(g, id, area) == "":
			return id
	return ""

## How many papers he could hold in all as he stands today (held, and ready to be sat but for the fee).
static func within_reach(g) -> int:
	var n := 0
	for id in order():
		if valid(g, id) or due(g, id) > 0:
			n += 1
	return n

## What his papers make of the number `key` (1 with none): "purse".
static func mod(g, k: String) -> float:
	if g.seals.is_empty():
		return 1.0
	if k == "purse":
		return 1.0 + PURSE * float(count(g))
	return 1.0

## The page of the menu: one line a paper.
static func text(g) -> String:
	var out: Array = []
	for id in order():
		var gn := grade_name(g, id)
		if gn != "":
			out.append("%s: %s (day %d)" % [name_of(id), gn, int(g.seals[id].day)])
	if out.is_empty():
		return "No paper has been sealed in his name."
	return "\n".join(out)

## What the ending tells of it: one sentence ("" with no paper).
static func epilogue(g) -> String:
	var n := count(g)
	if n == 0:
		return ""
	if n >= 12:
		return "It is told that Lin Feng held %d papers of the Hall of Seals, and that the registrar kept the copies in a box by themselves, and that the box was never asked for." % n
	return "It is told that Lin Feng held %d paper%s of the Hall of Seals, and was never once seen to take one out." % [n, "" if n == 1 else "s"]
