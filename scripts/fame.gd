class_name Fame
extends RefCounted
## Fame (the Lost Horse release): the higher he climbs, the more people know his face.
##
## Renown (trials.gd) is what Lin Feng has done.  **Fame is what he is**: it follows his cultivation,
## realm by realm (`rank`: six standings, from nobody in particular to somebody the children play at
## being), and what it changes is who comes up to him.
##
##   * In a town, **people walk up to him and go where he goes** (`crowd`: nobody at first, six at the
##     last): townsfolk in the bodies of the country, who fall in behind him along the way he came, stop
##     when he stops, and say what people say (`LINES`, by standing).  They are drawn, not stood in the
##     land: nobody is blocked by an admirer, and the bot does not know they are there.
##   * **They bring things** (`gift`): with one of them at his elbow, Enter takes what is being held
##     out: once a day a town, something small, a little better the better he is known.
##   * It is said when his standing rises, and the menu says what it is.
##
## With no window there is no crowd and nothing is given: the headless run is the same journey.

## the realm (Data.realm_of) at which each standing begins
const REALMS := [0, 2, 5, 9, 14, 20]
const NAMES := ["Nobody in particular", "A name in the valley", "Spoken of on the road", "Known in every town", "A living legend", "Somebody the children play at being"]
## how many walk up to him in a town
const CROWD := [0, 1, 2, 3, 4, 6]
## what is said when it rises
const RISES := ["", "Somebody in the market said your name, and somebody else knew who was meant.", "They have begun to tell it on the road, and to get it wrong.",
	"There is not a town in the land where a stranger could ask for you and not be pointed the way.", "People who have never seen you describe you to one another, taller.",
	"In every lane there is a child with a stick for a sword being you, and another who has to be the monster."]
## what they say, by standing (from the first that has a crowd)
const LINES := [
	[],
	["Is that the sweeper from the sect?", "I heard he fights. He doesn't look it.", "My cousin says he put down Iron Fang."],
	["It's him. I'm nearly sure it's him.", "Go on, ask him. You ask him.", "He's shorter than they said.", "Walk behind him a bit. Just to say we did."],
	["Master Lin! Master Lin, over here!", "My mother will never believe this.", "Would you look at my boy's arm? He fell out of a tree.", "Is the lady with him the healer? It is. It is!", "I named the ox after you. I hope that's all right."],
	["Don't crowd him. I said don't crowd him. I'm not crowding him.", "They say he stood on a lake once and never got his feet wet.", "Touch his sleeve for luck. Not like that.", "I walked from Tushan to see this.", "He looked at me. Did you see? He looked."],
	["I'm being him. You're the monster.", "Grandfather wants a shrine built. He's picked the hill.", "Say something. Anything. We'll write it down.", "Is it true you sweep your own step still?", "The whole street's out. Somebody mind the shop.", "Bless the baby? Just hold her a moment, then."],
]
## what they hold out, by standing: [item or "stones", how many (stones: a factor of what a foe of his level pays)]
const GIFTS := [[], [], [["hp_pill", 1]], [["hp_pill", 1], ["stones", 1.0]], [["hp_pill", 2], ["qi_pill", 1], ["stones", 2.0]], [["hp_pill", 2], ["qi_pill", 2], ["stones", 3.0]]]
const GIVERS := ["A dyer with blue hands", "Somebody's grandmother", "A boy pushed forward by his friends", "A carter who has left his cart", "A girl with a basket", "An old soldier", "A cook, still in her apron"]
const GIVES := ["presses it into your hands and is gone before you can say anything", "holds it out with both hands and looks at the ground", "says it is nothing, it is only what was in the house",
	"says to take it, for the road, and that the road has been long", "will not hear of being thanked"]
## how near a town's middle (tiles) is still the town
const REACH := 26

static func rank(g) -> int:
	var r := 0
	var realm := Data.realm_of(int(g.level))
	for i in REALMS.size():
		if realm >= int(REALMS[i]):
			r = i
	return r

static func name_of(g) -> String:
	return str(NAMES[rank(g)])

static func crowd(g) -> int:
	return int(CROWD[rank(g)])

## The town (Data.TOWNS id) whose middle is within reach of `tile` in realm `layer`, or "".
static func town_near(layer: String, tile: Vector2i) -> String:
	for tw in Data.TOWNS:
		if Data.layer_of(str(tw.area)) != layer:
			continue
		var c: Vector2i = Atlas.to_world(str(tw.area), tw.pos)
		if maxi(absi(c.x - tile.x), absi(c.y - tile.y)) <= REACH:
			return str(tw.id)
	return ""

## The k-th thing said behind him, at his standing.
static func line(g, k: int) -> String:
	var ls: Array = LINES[rank(g)]
	return "" if ls.is_empty() else str(ls[absi(k) % ls.size()])

## Whether somebody in `town` has something for him today.
static func gift_due(g, town: String) -> bool:
	return town != "" and not (GIFTS[rank(g)] as Array).is_empty() and int(g.fan_day.get(town, -1)) != int(g.day)

## What is being held out in `town` is taken: {who, how, what} told of it, or {} (nothing today).
static func gift(g, town: String) -> Dictionary:
	if not gift_due(g, town):
		return {}
	g.fan_day[town] = int(g.day)
	g.fan_gifts += 1
	var k := absi(hash("%s:%d" % [town, int(g.day)]))
	var what: Array = []
	for gf in GIFTS[rank(g)]:
		if str(gf[0]) == "stones":
			var st := int(round(float(Data.enemy_stones(int(g.level), false)) * float(gf[1])))
			g.stones += st
			what.append("%d spirit stones" % st)
		else:
			g.inv[str(gf[0])] = int(g.inv.get(str(gf[0]), 0)) + int(gf[1])
			what.append("%s x%d" % [str(Data.ITEMS[str(gf[0])].n), int(gf[1])])
	g.note("Given something in the street at %s" % town)
	return {"who": str(GIVERS[k % GIVERS.size()]), "how": str(GIVES[(k / 7) % GIVES.size()]), "what": ", ".join(what)}
