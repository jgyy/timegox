class_name Reckon
extends RefCounted
## The reckoning (the Lost Horse release): the last lords of the story are made of what was chosen.
##
## Every chapter's last lord has been the same for every journey.  The last of all is not.  Before
## the final breakthrough something waits on the mountain above the sect that is **made of the way
## the three scales of the crossroads lean** (echoes.gd): each scale has a lord for either way it can
## lean, and a journey that never leaned at all has one of its own.
##
##   * `due`: who waits.  The lord of the scale that leans furthest, always; and with it the lord of
##     **every other scale that leans far enough to be known for** (Echoes.KNOWN).  A journey of one
##     strong habit meets one; a journey of three meets three, on three heights; a journey that chose
##     evenly, or hardly chose, meets the Unchosen;
##   * each is as strong as the habit that made it (`might`: more for every point the scale leans);
##   * and **every time the other answer was given is a crack in it** (`boon`): the answers that
##     tipped that scale the other way are counted, and each takes a twentieth of its strength, down
##     to three fifths.  Nobody who chose only one way gets any help with what that made of them;
##   * which were faced is remembered (`Game.reckoned`) and told at the end.
##
## The step is of kind `"reckon"`: done when nobody of `due` is left standing.  The seven stand on
## the heights of Azure Cloud Mountain (written with the region, like every lord on a peak) and only
## the ones that are due are there at all.

const STEP := "s_p24_reckon"
## the lord of each scale, by the way it leans; and of none
const LORDS := {"heart": {1: "debt_mercy", -1: "iron_judge"}, "craft": {1: "unkept_engine", -1: "unturned_stone"}, "reach": {1: "doorless_road", -1: "valley_wall"}}
const UNCHOSEN := "the_unchosen"
const ALL := ["debt_mercy", "iron_judge", "unkept_engine", "unturned_stone", "doorless_road", "valley_wall", "the_unchosen"]
## what each is, in a line (the Crossroads page and the ending)
const WHAT := {
	"debt_mercy": "everybody you let go, come back for what mercy cost somebody else",
	"iron_judge": "the judge your unbending made, who has a sentence ready for you",
	"unkept_engine": "every engine you let be built, running with nobody at it",
	"unturned_stone": "every old way you kept, grown too heavy to lift",
	"doorless_road": "the road you gave to everybody, which has forgotten how to arrive",
	"valley_wall": "the wall round everything you kept at home",
	"the_unchosen": "every answer you did not quite give",
}
const END := {
	"debt_mercy": "On the mountain, at the last, Lin Feng met the Debt of Mercy, made of everyone he had let go; and paid it, and would let them go again.",
	"iron_judge": "On the mountain, at the last, Lin Feng met the Iron Judge his own rigour had made, heard its sentence on him, and served it standing.",
	"unkept_engine": "On the mountain, at the last, Lin Feng met the Engine Without a Keeper, made of everything he had let be built; and put a hand on it, and it had hours.",
	"unturned_stone": "On the mountain, at the last, Lin Feng met the Unturned Stone, made of every old way he had kept; and it was lifted, once, to see what was under it, and set down again.",
	"doorless_road": "On the mountain, at the last, Lin Feng met the Road With No Door, made of everywhere he had sent people; and gave it somewhere to arrive.",
	"valley_wall": "On the mountain, at the last, Lin Feng met the Wall Round the Valley, made of everything he had kept at home; and put a gate in it.",
	"the_unchosen": "On the mountain, at the last, Lin Feng met the Unchosen, made of every answer he had not quite given; and gave it one.",
}
## how much stronger than an ordinary lord each is, before the lean is counted: [health, blow]
const MIGHT := [2.2, 1.25]
const MIGHT_PER := 0.06
const CRACK := 0.05
const CRACK_MAX := 0.4

static func is_lord(id: String) -> bool:
	return id in ALL

## Who waits for the journey of `g`, strongest habit first.
static func due(g) -> Array:
	var leans: Array = []
	for sc in Echoes.SCALE_ORDER:
		var v := Echoes.scale(g, sc)
		if absi(v) >= Echoes.LEAN:
			leans.append([absi(v), sc, 1 if v > 0 else -1])
	if leans.is_empty():
		return [UNCHOSEN]
	leans.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
	var out: Array = [str(LORDS[leans[0][1]][leans[0][2]])]
	for k in range(1, leans.size()):
		if int(leans[k][0]) >= Echoes.KNOWN:
			out.append(str(LORDS[leans[k][1]][leans[k][2]]))
	return out

## Those of `due` not yet met and beaten.
static func left(g) -> Array:
	return due(g).filter(func(id): return not g.boss_done.has(id))

## Whether lord `id` stands on the mountain for `g` now.
static func stands(g, id: String) -> bool:
	return g.reached(STEP) and not g.done(STEP) and id in left(g)

## The scale and the way of lord `id`: [scale, sign] (["", 0] for the Unchosen).
static func of(id: String) -> Array:
	for sc in LORDS:
		for sg in LORDS[sc]:
			if str(LORDS[sc][sg]) == id:
				return [sc, int(sg)]
	return ["", 0]

## How strong lord `id` is for `g`: [health, blow] over an ordinary lord's.
static func might(g, id: String) -> Array:
	var o := of(id)
	var lean := 0 if str(o[0]) == "" else absi(Echoes.scale(g, str(o[0])))
	return [float(MIGHT[0]) + MIGHT_PER * float(mini(lean, 20)), float(MIGHT[1])]

## How many answers `g` gave that tipped lord `id`'s scale the other way (for the Unchosen: how many
## crossroads were answered at all).
static func cracks(g, id: String) -> int:
	var o := of(id)
	var n := 0
	for cid in Echoes.ORDER:
		var ch := Echoes.chosen(g, cid)
		if ch == "":
			continue
		if str(o[0]) == "":
			n += 1
			continue
		var tv := int(Echoes.option(cid, ch).get("tilt", {}).get(str(o[0]), 0))
		if tv * int(o[1]) < 0:
			n += 1
	return n if str(o[0]) != "" else n / 4

## What the battle with lord `id` is given for those cracks (a trial's boon: the share of its health it keeps).
static func boon(g, id: String) -> Dictionary:
	return {"foe_hp": 1.0 - minf(CRACK_MAX, CRACK * float(cracks(g, id)))}

## What is said of it on the way up: who it is, how strong, and how cracked.
static func word(g, id: String) -> String:
	var c := cracks(g, id)
	var o := of(id)
	if str(o[0]) == "":
		return "It is %s. Every question you did answer is a place where it is not: %d of them." % [str(WHAT[id]), cracks(g, id) * 4]
	var nm := str(Echoes.SCALES[str(o[0])].pos if int(o[1]) > 0 else Echoes.SCALES[str(o[0])].neg).to_lower()
	if c == 0:
		return "It is %s. You are known as %s, and you never once chose otherwise: there is not a crack in it." % [str(WHAT[id]), nm]
	return "It is %s. You are known as %s; but %d times you chose otherwise, and each is a crack in it." % [str(WHAT[id]), nm, c]

## What the ending tells: a sentence for each that was faced.
static func epilogue(g) -> Array:
	var out: Array = []
	for id in ALL:
		if g.reckoned.has(id):
			out.append(str(END[id]))
	return out
