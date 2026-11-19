class_name Giants
extends RefCounted
## The Great People (the Tall People release).  The old books put a Country of Great People east of the
## sea, and the giants of Longbo beyond it, of whom one let down a line and carried off six of the turtles
## that held the Isles up; there were Fangfeng, one joint of whose bones filled a cart, and Kuafu, who ran
## after the sun.  The land had lords drawn twice a man's height already.  Now it has a people that size:
##
##  * **they live in the towns** (folk.gd: the role `giant`, appended to the end of a town's `roles`, so
##    everybody before them keeps their name and seed): one or two in every town of the Unbroken Land and
##    three at Landfall, with a day of their own (the heavy work nobody else can do), a body sculpted for
##    it (art/characters/folk_giant.py, folk_giantess.py), a title and their own lines;
##  * **they are a people of the realms** (Data.RACES.daren): standing, a keepsake they love, a boon;
##  * **everybody of theirs is drawn at SCALE** (`of_folk`, `of_npc`, `of_foe`: the people of the towns,
##    the people of the story named in NAMED, a lord whose enemy says `"giant": true`), moves at a giant's
##    pace (`pace`: the same clips, slower, so that a stride twice as long covers the same ground) and is
##    looked up at (the label over the head, the conversation camera);
##  * **the houses were built for them too**: Arch.WALL_H, DOOR_CLEAR, WALL2_H and GATE_CLEAR clear
##    HEIGHT (`fits`, checked by the tests for every style of house).  Nothing is placed in the world for
##    any of this: no entity, so no map moves.
##
## A giant bends to speak to somebody half their height (the clip `stoop`, lent to everybody), and
## whoever is small says so (`LINES_SMALL`).

## how many times a man's height one of the Great People stands, and what that comes to in metres
const SCALE := 2.0
const MAN := 1.76
const HEIGHT := SCALE * MAN
## what a lintel, a ceiling or the beam of a gate must clear: the crown of the head and a topknot
const CLEAR := HEIGHT + 0.2
const ROLE := "giant"
const RACE := "daren"
const BODIES := ["folk_giant", "folk_giantess"]
## the people of the story who are of the Great People (their entity id or `asset`)
const NAMED := ["fangfeng", "kuafu", "longbo_angler"]
## how many of them live in each town (folk.gd TOWNS says the same: the tests compare)
const TOWNS := {"cloudfoot": 1, "qingshi": 2, "drumtower": 1, "yanggu": 2, "shazhou": 1, "longmen": 2, "tushan": 2, "landfall": 3, "lightfoot": 1, "fourstreams": 1, "reedhaven": 1, "clearbell": 1, "ashmarket": 1, "knifegate": 2, "shuttlereef": 1, "redbranch": 1, "lampdeep": 1}

## How big person `p` of the towns (folk.gd) is drawn.
static func of_folk(p: Dictionary) -> float:
	return SCALE if str(p.get("role", "")) == ROLE else 1.0

## How big somebody of the story is drawn (an entity of kind "npc").
static func of_npc(e: Dictionary) -> float:
	return SCALE if str(e.get("asset", e.get("id", ""))) in NAMED or str(e.get("id", "")) in NAMED else 1.0

## Whether enemy `id` is one of the Great People (a lord drawn as a person at their full height).
static func of_foe(id: String) -> bool:
	return bool(Data.ENEMIES.get(id, {}).get("giant", false))

## How fast the clips of somebody drawn at `sc` are played: a giant's stride is twice a man's, and
## covers the same ground in the same time at about half the beat.
static func pace(sc: float) -> float:
	return 1.0 if sc <= 1.01 else 1.0 / sqrt(sc) * 0.82

## How high the head of somebody drawn at `sc` is (for a label, a mark, a camera).
static func head(sc: float) -> float:
	return 1.5 * sc

## Whether the houses of the land let one of them in: every door, both storeys that are walked in,
## and the gates of the towns.
static func fits() -> bool:
	return Arch.DOOR_CLEAR >= CLEAR and Arch.WALL_H >= CLEAR and Arch.WALL2_H >= CLEAR and Arch.GATE_CLEAR >= CLEAR

## What the Great People of the towns say (folk.gd LINES.giant is the same list).
const LINES := ["Mind your feet, %s. No, I mean mind mine. I can't see you past my own knees.",
	"They raised every lintel in the town the year my grandmother came. She cried. Then she hit her head on the old gate, for the last time.",
	"I carry the ridge-beam, six of them carry the other end, and we all get the same wage. I eat for six. It works out.",
	"A well is forty days for four men or six for me. They pay me in dumplings. I count in dumplings now.",
	"You are the cultivator. They say you could lift this town. I could lift this town. Neither of us does. That's manners.",
	"Small folk think we look down on them. We do. There is nowhere else to look."]
## what somebody small says of them, now and then
const LINES_SMALL := ["Big Brother lifted our ox out of the ditch with one hand. With the other he was eating.",
	"The door? Twice my height. You should have seen the old one. My grandfather bent double for a guest he liked."]
