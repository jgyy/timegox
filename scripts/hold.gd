class_name Hold
extends RefCounted
## A town of one's own (the Three Burrows release): Guiyun, on the east shoulder of Azure Cloud Mountain.
##
## Until this release everything Lin Feng did for a town was done for somebody else's: he worked a
## shift in it, carried its post, was followed down its street.  Now there is one that is **his to
## answer for**.  "Where Shun lived," says the old book, "in a year there was a hamlet, in two a town,
## in three a capital": people come to live beside somebody they trust, and the ground they come to
## was waste the day before.
##
##   * **The ground** is eleven tiles by nine of open slope, found once and written here (`AREA`,
##     `AT`); `place` stands the plots, the steward and the settlers on it when the realm is made,
##     after the peaks and the camps and before the late war-bands and the marks, so that those keep
##     off it and nothing older moves.  Nothing of it is drawn until it stands (`key`), like a mark.
##   * **The wall** is the outermost ring of the ground (`wall_tiles`): thirty-three lengths of rammed
##     earth that stand, and are in the way, once the wall is built, with the Cloud Gate in the middle
##     of the south side and a postern east and west (`GATES`), which are walked through.
##   * **Plots** (`PLOTS`, in `ORDER`): twelve things to build, each paid for in spirit stones at the
##     steward, each a model built from code (`model`), each bringing a few households with it
##     (`homes`), room for more (`room`), and sometimes something else: the market half as much
##     again in dues, the granary a faster growth, the wall and the drill ground a watch that marches
##     with the host (war.gd), the Hall of the Broom disciples.
##   * **People** are asked to come (`settle`): the people of the road and of the towns, one family
##     and its kin at a time, while there is room for them; and when there is room the town **grows
##     by itself**, a little every day (`grown`).
##   * **Dues** (`due`, `chest`, `take`): every household pays a little a day into the steward's
##     chest, which holds five days and no more: a town left to itself does not pile up a fortune.
##   * **Rank** (`rank`): a hamlet, a town at fifty households and a market, a city at a hundred and a
##     wall.  **Power** (`power`) is what the rest of the land counts: households, walls, a watch, a
##     sect.
##   * What was answered at the chapter's three crossroads (echoes.gd: the tallies, the door, the seat)
##     changes the numbers here (`mod`) and what flies over the hall, and opens four more ends of the
##     story (cultures.gd).
##
## Everything takes the game state `g` as an argument, like works.gd; nothing here is random, and the
## bot and the tests never need the models.

const AREA := "mountain"
## the corner of the ground, in the region's own tiles, and its size
const AT := Vector2i(153, 88)
const SIZE := Vector2i(11, 9)
const NAME := "Guiyun"
const STEWARD := "feng_xuan"
## the step whose doing founds the town (the steward is found sitting on the ground it will stand on)
const FOUND_STEP := "s_p25_feng"

## households a family asked to come brings with it (itself and its kin), and what the town grows by a
## day when there is room (twice that with a granary), up to so many in all
const PER_SETTLER := 4
const GROW := 2
const GROW_MAX := 30
## what a household pays a day, and how many days the chest holds
const DUE := 30
const CHEST_DAYS := 5
## households and what else a rank asks: [households, plot]
const RANKS := [[0, ""], [1, "hall"], [50, "market"], [100, "wall"]]
const RANK_NAMES := ["Waste Ground", "Guiyun Hamlet", "Guiyun Town", "Guiyun of the Hundred Households"]
## the old words for them: ju, yi, du
const RANK_WORDS := ["", "a hamlet", "a town", "a city"]

## The plots: `at` (where on the ground), `cost` (spirit stones), `homes` (households that come with
## it), `room` (households it makes room for), `power`, `needs` (households before it can be built),
## `n`, `desc` (what is read on it) and `ask` (what the steward says it is for).
const PLOTS := {
	"hall": {"n": "The Steward's Hall", "at": Vector2i(5, 1), "cost": 0, "homes": 4, "room": 12, "power": 1,
		"ask": "A roof to keep the tallies under.",
		"desc": "Three bays of rammed earth under a roof of reed thatch, a long table, and a chest with two locks of which the steward has one key and the town the other. Over the door, in charcoal, because nobody has yet been trusted to carve it: Guiyun, Where the Cloud Comes Home."},
	"well": {"n": "The Sweet Well", "at": Vector2i(3, 3), "cost": 1200, "homes": 2, "room": 8, "power": 0,
		"ask": "Nobody stays where the water is carried.",
		"desc": "A ring of fitted stone and a sweep to lift the bucket, sunk forty feet through the shoulder of the mountain to the same vein that feeds the sect's pond. The water is cold enough to hurt the teeth. The first bucket of every morning is poured back, for whoever is under there."},
	"homes1": {"n": "The First Row", "at": Vector2i(1, 1), "cost": 2400, "homes": 6, "room": 20, "power": 0,
		"ask": "Walls for the families who came with nothing but a name they had heard.",
		"desc": "Six doors under one roof-line, built in nine days by the people who were to live behind them. No two doorposts are the same height. Every lintel has a sprig of the mountain's own pine over it, renewed when it browns."},
	"granary": {"n": "The Granary on Stone Feet", "at": Vector2i(1, 3), "cost": 3600, "homes": 2, "room": 10, "power": 1,
		"ask": "When the granaries are full, said Guan Zhong, the people know what manners are.",
		"desc": "A round bin of wattle and clay on nine stone mushrooms, with a hat of thatch and a ladder that is taken away at night. The feet are to keep out rats. On the door somebody has scratched a line from the old song: big rat, big rat, do not eat our millet."},
	"market": {"n": "The Morning Market", "at": Vector2i(7, 3), "cost": 6000, "homes": 6, "room": 10, "power": 1, "needs": 30,
		"ask": "A town is a place that somebody from somewhere else has a reason to walk to.",
		"desc": "Four posts, an awning of oiled cloth, and a steelyard hung from the middle beam whose weights are kept in the steward's chest and brought out at dawn. Pedlars of the road lay their mats in its shade. What is weighed here is weighed the same for everybody: that is the whole of its charter."},
	"homes2": {"n": "The Second Row", "at": Vector2i(9, 1), "cost": 5000, "homes": 8, "room": 24, "power": 0, "needs": 30,
		"ask": "The first row has cousins.",
		"desc": "Eight doors, two storeys, tiled with what the kiln at Qingshi called seconds. The upper windows look over the wall to the sea of clouds. Rents are paid in the autumn, in grain, and the steward has been told how much is enough."},
	"inn": {"n": "The Returning Cloud Inn", "at": Vector2i(9, 3), "cost": 7000, "homes": 4, "room": 12, "power": 1, "needs": 40,
		"ask": "A lord is known by his guests. Somewhere must be found to put them.",
		"desc": "A yard, a stable for six, and a long room with a stove at each end. Lord Mengchang kept three thousand guests at Xue and turned away nobody, not the one who could only crow like a cock nor the one who could only steal like a dog; and both, on one night, were what saved him. The sign shows a cloud with its bags packed, coming back."},
	"smithy": {"n": "The Smithy", "at": Vector2i(7, 1), "cost": 8000, "homes": 3, "room": 8, "power": 2, "needs": 40,
		"ask": "Hoes first. Then hinges. Then, if it must be, spearheads.",
		"desc": "A hearth, a leather bellows and an anvil that came up the mountain on a sledge behind four oxen. Smith Tie's second apprentice keeps it, and makes hoes, hinges, well-chains and the pins of cart-wheels. There is a rack at the back for spearheads. It is not empty. It has never been emptied either."},
	"drill": {"n": "The Drill Ground", "at": Vector2i(9, 5), "cost": 9000, "homes": 2, "room": 6, "power": 3, "needs": 50,
		"ask": "A watch that has stood together once will stand together twice.",
		"desc": "A square of beaten earth with a rack of practice spears and a drum on a post. The watch of Guiyun stands to here at dawn: a hundred who were woodcutters and pedlars the year before, and who keep their dressing as people do who chose the person on either side of them."},
	"school": {"n": "The Hall of the Broom", "at": Vector2i(3, 1), "cost": 11000, "homes": 3, "room": 8, "power": 2, "needs": 50,
		"ask": "Somebody will ask to be taught. Better there is a door to knock on than a hillside to be followed about.",
		"desc": "One room with a swept floor, mats in rows, and beside the door a rack of nine brooms worn to different lengths. Whoever would learn anything here sweeps the street of Guiyun for a season first. The children of the town do it without being asked, having gathered that it is how one becomes somebody."},
	"homes3": {"n": "The Third Row", "at": Vector2i(1, 5), "cost": 12000, "homes": 10, "room": 30, "power": 0, "needs": 60,
		"ask": "They are sleeping in the market. It is time.",
		"desc": "Ten doors round a yard with a persimmon tree in it, planted the day the first beam went up. The families here came from five countries and agree about nothing but the tree, which is nobody's and is watered by all of them, some days twice."},
	"wall": {"n": "The Earth Wall and the Cloud Gate", "at": Vector2i(6, 8), "cost": 14000, "homes": 0, "room": 10, "power": 4, "needs": 70,
		"ask": "Not to keep anybody out. So that those inside can sleep with both eyes shut.",
		"desc": "A gate-tower of two storeys in a wall of rammed earth as thick as a cart is long, raised a hand's breadth a day by everybody in the town, each household its own length. The gate is shut at the second watch and opened at cock-crow, and the man who opens it was taken on because he can crow."},
}
const ORDER := ["hall", "well", "homes1", "granary", "market", "homes2", "inn", "smithy", "drill", "school", "homes3", "wall"]

## The ways through the wall: the Cloud Gate in the middle of the south side, and a postern in the east
## and the west.  The wall's own plot (`PLOTS.wall.at`) is the length beside the Cloud Gate, which
## carries the gate-tower over the open tile next to it.
const GATES := [Vector2i(5, 8), Vector2i(0, 4), Vector2i(10, 4)]

## The lengths of the wall: [where on the ground, which way it runs, whether it is a corner], for
## every tile of the outermost ring that is not a gate.
static func wall_tiles() -> Array:
	var out: Array = []
	for y in SIZE.y:
		for x in SIZE.x:
			var o := Vector2i(x, y)
			var edge_x := x == 0 or x == SIZE.x - 1
			var edge_y := y == 0 or y == SIZE.y - 1
			if (edge_x or edge_y) and not GATES.has(o):
				out.append([o, Vector2i(1, 0) if edge_y else Vector2i(0, 1), edge_x and edge_y])
	return out

## Who comes to live there as the town fills: [households it takes, name, a body of the towns, colour,
## where on the ground, what they say...].
const SETTLERS := [
	[10, "Sawyer Bo", "folk_farmer", Color("6a5a3a"), Vector2i(2, 2),
		"I cut for the sect's kitchen eleven years and slept under the cart. This is the first door I have ever shut from the inside.",
		"The steward asked what rent I thought was fair. Nobody has asked me what I thought since my mother asked what I wanted for supper.",
		"Pine for the posts, elm for the sills. I told them. They wrote it down. They WROTE IT DOWN."],
	[24, "Goodwife Suyin", "folk_farmwife", Color("9a5a4a"), Vector2i(4, 4),
		"We came for the name. We stayed for the well. A name does not come up cold in a bucket.",
		"Three families from three valleys draw at one well, and nobody has pushed anybody in. I am told that is rare.",
		"My boy sweeps the street with the others. He thinks it is a game with a sect at the end of it. Perhaps it is."],
	[40, "Old Pedlar Jin", "folk_merchant", Color("b08a3a"), Vector2i(6, 4),
		"Forty years I have laid my mat down in other people's markets. Here they asked me where the market ought to go.",
		"The weights are honest. I checked. I have checked every morning for a month. It is beginning to upset me.",
		"A town on a mountain, a day from anywhere. Nobody comes here by accident. That is good custom: they have all already decided."],
	[60, "Granny Pei", "folk_grandma", Color("8a7a8a"), Vector2i(8, 2),
		"I have buried a husband in the river country and a son in the sand. I shall be buried here, and I have picked the place, and it has a view.",
		"They ask whose town it is. I say: whose is the street? Whoever swept it this morning.",
		"When there were ten doors we all knew whose dog was barking. Now there are sixty. It is still the same dog."],
	[80, "Scholar Wen Qi", "folk_scholar", Color("4a5a7a"), Vector2i(4, 6),
		"I am writing the gazetteer of Guiyun. It has one chapter. I add a line to it most days.",
		"Shun ploughed at Mount Li, and in a year there was a hamlet where he lived, in two a town, in three a capital. I have been counting. We are behind Shun. Not by much.",
		"A place becomes a town on the day somebody born in it is rude about it. I am waiting. The eldest of them is four."],
	[100, "Captain of the Gate", "folk_guard", Color("5a5a6a"), Vector2i(6, 6),
		"A hundred households, and I know the knock of every one of them. The gate opens at cock-crow. I am the cock.",
		"Nobody has tried the wall. I walk it every night to make sure it still wants to be one.",
		"They asked if I could fight. I said I could crow. The steward laughed for a long time, and then gave me the keys."],
]

# ---------------------------------------------------------------- state
## Whether the town has been founded: the steward's first step is done.
static func founded(g) -> bool:
	return g.done(FOUND_STEP)

static func _built(g) -> Dictionary:
	return g.hold.get("built", {})

## Whether plot `id` is built (the hall stands from the founding).
static func built(g, id: String) -> bool:
	return founded(g) and (id == "hall" or _built(g).has(id))

static func built_count(g) -> int:
	var n := 0
	for id in ORDER:
		if built(g, id):
			n += 1
	return n

## The day the town was founded on (the day it is first asked, if the story was begun past it).
static func _day0(g) -> int:
	if not g.hold.has("day0"):
		g.hold["day0"] = int(g.day)
		g.hold["taken"] = int(g.day)
	return int(g.hold.day0)

## The town is founded (the step is done): the day is remembered.
static func found(g) -> void:
	_day0(g)
	g.toast("Founded: %s, on the east shoulder of the mountain" % NAME)
	g.note("Founded %s" % NAME)

## What the answers at the chapter's crossroads do to the town's numbers (echoes.gd): "settler"
## (households a family brings), "grow" (what it grows by a day), "due" (what a household pays),
## "room" (room for households), "power".
static func mod(g, key: String) -> float:
	var out := 1.0
	var tally := Echoes.chosen(g, "the_tallies")
	var door := Echoes.chosen(g, "the_door")
	var seat := Echoes.chosen(g, "the_seat")
	match key:
		"settler":
			# (debts burned in the square: a family brings a cousin's family with it)
			if tally == "burn":
				out *= 1.25
		"grow":
			if tally == "burn":
				out *= 1.5
			elif tally == "collect":
				out *= 0.5
			if door == "all":
				out *= 1.5
		"due":
			if tally == "burn":
				out *= 0.85
			elif tally == "collect":
				out *= 1.3
			elif tally == "shares":
				out *= 1.15
		"room":
			if door == "all":
				out *= 1.15
		"power":
			if seat == "take":
				out *= 1.3
			elif seat == "found":
				out *= 1.15
			if door == "sweep":
				out *= 1.1
	return out

## How many families have been asked to come, and came.
static func settlers(g) -> int:
	return (g.hold.get("settlers", {}) as Dictionary).size()

## Room for households: what the plots built make between them.
static func room(g) -> int:
	var n := 0
	for id in ORDER:
		if built(g, id):
			n += int(PLOTS[id].room)
	return int(round(n * mod(g, "room")))

## How many households the town has grown by of itself since it was founded: a couple a day while
## there is somewhere to put them (twice that with a granary), and no more than thirty in all.
## (the Underclothes release: what it grows by is added day by day at the rate of that day, granary and
## answers as they stood then; it used to be every day since the founding at today's rate, so that a
## granary built late doubled the past, and collecting the tallies took households back off the town)
static func grown(g) -> int:
	if not founded(g):
		return 0
	_accrue(g)
	return mini(GROW_MAX, int(floor(float(g.hold.get("grown_f", 0.0)))))

static func _accrue(g) -> void:
	var d0 := int(g.hold.get("grow_day", _day0(g)))
	var today := int(g.day)
	if today > d0:
		var rate := GROW * (2.0 if built(g, "granary") else 1.0) * mod(g, "grow")
		g.hold["grown_f"] = minf(float(GROW_MAX), float(g.hold.get("grown_f", 0.0)) + float(today - d0) * rate)
	if today != d0 or not g.hold.has("grow_day"):
		g.hold["grow_day"] = today

## The town has grown overnight, or been built on: its rank is news when it rises, and a step of the
## town that is waiting on it is looked at again (game.gd asks every second and a half).
static func tick(g) -> void:
	if not founded(g):
		return
	var was := int(g.hold.get("told", rank(g)))
	var now := rank(g)
	if now != was:
		g.hold["told"] = now
		_risen(g, was)
		var st: Dictionary = g.cur_step()
		if not st.is_empty() and str(st.kind) == "hold":
			g.poll_steps()

## The households that would live there if there were room for all of them.
static func wanting(g) -> int:
	if not founded(g):
		return 0
	var n := 0
	for id in ORDER:
		if built(g, id):
			n += int(PLOTS[id].homes)
	return n + int(round(settlers(g) * PER_SETTLER * mod(g, "settler"))) + grown(g)

## The households of the town.
static func households(g) -> int:
	return mini(room(g), wanting(g))

## 0 waste ground, 1 a hamlet, 2 a town, 3 a city.
static func rank(g) -> int:
	if not founded(g):
		return 0
	var r := 1
	var h := households(g)
	for k in range(2, RANKS.size()):
		if h >= int(RANKS[k][0]) and built(g, str(RANKS[k][1])):
			r = k
		else:
			break
	return r

static func rank_name(g) -> String:
	return str(RANK_NAMES[rank(g)])

## What the town still wants before it is of rank `r` ("" if it is).
static func rank_lack(g, r: int) -> String:
	if rank(g) >= r:
		return ""
	var want: Array = RANKS[clampi(r, 0, RANKS.size() - 1)]
	var out: Array = []
	if households(g) < int(want[0]):
		out.append("%d households (now %d, room for %d)" % [int(want[0]), households(g), room(g)])
	if str(want[1]) != "" and not built(g, str(want[1])):
		out.append(str(PLOTS[str(want[1])].n))
	return " and ".join(out)

## The disciples of the Hall of the Broom: one household in ten sends somebody, once it is built, and
## more once the town has a sect of its own (the third crossroads).
static func disciples(g) -> int:
	if not built(g, "school"):
		return 0
	var k := 0.1
	match sect(g):
		"found":
			k = 0.2
		"take":
			k = 0.3
		"serve":
			k = 0.15
	return int(floor(households(g) * k))

## What the town counts for in the land: a point for every ten households, what its plots are worth,
## a point for every ten disciples, by whatever the crossroads made of it.
static func power(g) -> int:
	if not founded(g):
		return 0
	var n := households(g) / 10.0 + disciples(g) / 10.0
	for id in ORDER:
		if built(g, id):
			n += float(PLOTS[id].power)
	return int(floor(n * mod(g, "power")))

## Whether the watch of Guiyun stands to (war.gd: a company of the host).
static func watch(g) -> bool:
	return built(g, "drill") and built(g, "wall")

# ---------------------------------------------------------------- the sect (the third crossroads)
## "" until the seat is answered for; then "found" (a sect of his own at Guiyun), "take" (the seat of
## the Cold Pine) or "serve" (a branch hall of the Azure Cloud).
static func sect(g) -> String:
	return Echoes.chosen(g, "the_seat")

const SECT_NAMES := {"found": "the Returning Cloud Sect", "take": "the Cold Pine Sect", "serve": "the Guiyun Hall of the Azure Cloud Sect"}
const SECT_TITLES := {"found": "Founder of the Returning Cloud", "take": "Patriarch of the Cold Pine", "serve": "Hall Master of Guiyun"}

static func sect_name(g) -> String:
	return str(SECT_NAMES.get(sect(g), ""))

static func sect_title(g) -> String:
	return str(SECT_TITLES.get(sect(g), ""))

# ---------------------------------------------------------------- building
## Why plot `id` cannot be built now ("" if it can).
static func blocked(g, id: String) -> String:
	if not founded(g):
		return "There is no town yet."
	if not PLOTS.has(id):
		return "Nobody has drawn that."
	if built(g, id):
		return "It stands already."
	var p: Dictionary = PLOTS[id]
	if households(g) < int(p.get("needs", 0)):
		return "Not until there are %d households (now %d)." % [int(p.needs), households(g)]
	if g.stones < cost(g, id):
		return "It wants %d spirit stones (you have %d)." % [cost(g, id), g.stones]
	return ""

static func cost(_g, id: String) -> int:
	return int(PLOTS[id].cost)

## The plots that are not built yet, in the order they are drawn up in.
static func unbuilt(g) -> Array:
	return ORDER.filter(func(id): return not built(g, id))

## The next plot that could be built now ("" if none can).
static func next(g) -> String:
	for id in unbuilt(g):
		if blocked(g, id) == "":
			return id
	return ""

## Build plot `id`: true if it was built.
static func build(g, id: String) -> bool:
	if blocked(g, id) != "":
		return false
	var was := rank(g)
	g.stones -= cost(g, id)
	if not g.hold.has("built"):
		g.hold["built"] = {}
	g.hold.built[id] = true
	g.hold["spent"] = int(g.hold.get("spent", 0)) + cost(g, id)
	g.toast("Built at %s: %s (%d households, room for %d)" % [NAME, str(PLOTS[id].n), households(g), room(g)])
	g.note("Built %s at %s" % [str(PLOTS[id].n), NAME])
	_risen(g, was)
	g.hold["told"] = rank(g)
	g.poll_steps()
	return true

static func _risen(g, was: int) -> void:
	var now := rank(g)
	if now > was:
		g.toast("%s is %s now: %s" % [NAME, str(RANK_WORDS[now]), str(RANK_NAMES[now])])
		g.note("%s became %s (%d households)" % [NAME, str(RANK_WORDS[now]), households(g)])
		g.add_renown(now)

# ---------------------------------------------------------------- people
## Whether somebody known as `who` could be asked to come: the town is founded, they have not been
## asked, and there is room for the households they would bring.
static func can_settle(g, who: String) -> bool:
	return founded(g) and not (g.hold.get("settlers", {}) as Dictionary).has(who) and wanting(g) < room(g)

## Why nobody more can be asked just now ("" if somebody can).
static func full_text(g) -> String:
	if not founded(g):
		return "There is no town yet."
	if wanting(g) >= room(g):
		return "There is not a roof left in %s (%d households, room for %d): build first." % [NAME, households(g), room(g)]
	return ""

## A family comes to live at Guiyun (and its kin with it): true if it is new.  A step of the story
## that asks for settlers (`force`) finds room for them whether or not there is a roof yet: they
## build their own.
static func settle(g, who: String, name: String, force: bool = false) -> bool:
	if not founded(g) or (g.hold.get("settlers", {}) as Dictionary).has(who):
		return false
	if not force and wanting(g) >= room(g):
		return false
	var was := rank(g)
	if not g.hold.has("settlers"):
		g.hold["settlers"] = {}
	g.hold.settlers[who] = name
	g.note("%s came to live at %s" % [name, NAME])
	_risen(g, was)
	# (the Answering Land release: and the rank is told once: the next day's reckoning used to tell it again,
	# and pay the renown of it twice)
	g.hold["told"] = rank(g)
	return true

## Who of the people of the towns and the road may be asked: anybody grown who has no post to keep.
const NOT_ASKED := ["guard", "soldier", "disciple", "watchman", "servant", "monk"]

static func may_ask(p: Dictionary) -> bool:
	return not bool(p.get("kid", false)) and not (str(p.get("role", "")) in NOT_ASKED)

## What somebody says who has been asked to come (by the trade they follow).
const YES := {
	"woodcutter": "A town with no timber in it yet? Then it wants a woodcutter before it wants anything. I will bring my brother and the saw.",
	"herbalist": "Is there a north slope? Then there is everything I need but a roof. My sister's family will come too. She does not know it yet.",
	"angler": "Is there water? A well. Hm. I have never fished a well. I shall come and look at it for a year or two.",
	"pedlar": "I have walked past ten thousand doors. Nobody has ever offered me one. Say the name of the place again, slowly.",
	"hunter": "Somebody will have to keep the boar out of your beans. I will come when the snow does, and bring the dogs.",
	"pilgrim": "I have been walking to a mountain for nine years. It had not occurred to me that I might live on one. Yes.",
	"hermit": "A town. With people in it. ...How far apart are the houses? I shall take the last one. I shall not come to the meetings.",
	"": "At Guiyun? Where the debts are written small? My cousins have been talking of nothing else. We will come before the harvest.",
}

static func yes_line(p: Dictionary) -> String:
	return str(YES.get(str(p.get("role", "")), YES[""]))

# ---------------------------------------------------------------- dues
## What the town pays into the steward's chest in a day.
static func due(g) -> int:
	return int(round(households(g) * DUE * (1.5 if built(g, "market") else 1.0) * mod(g, "due")))

## What is in the chest: so many days' dues since it was last emptied, five at most.
static func chest(g) -> int:
	if not founded(g):
		return 0
	_day0(g)
	var days := clampi(int(g.day) - int(g.hold.get("taken", g.day)), 0, CHEST_DAYS)
	return days * due(g)

## Empty the chest: the spirit stones taken.
static func take(g) -> int:
	var n := chest(g)
	g.hold["taken"] = int(g.day)
	if n > 0:
		g.stones += n
		g.hold["dues"] = int(g.hold.get("dues", 0)) + n
		g.toast("The chest of %s: +%d spirit stones" % [NAME, n])
		g.note("Took %d spirit stones of dues at %s" % [n, NAME])
	return n

# ---------------------------------------------------------------- what the story asks
## Whether what a step of kind "hold" asks is so: `need` is ["built", n] (so many plots), ["plot",
## id], ["rank", r] or ["households", n].
static func need_met(g, need: Array) -> bool:
	match str(need[0]):
		"built":
			return built_count(g) >= int(need[1])
		"plot":
			return built(g, str(need[1]))
		"rank":
			return rank(g) >= int(need[1])
		"households":
			return households(g) >= int(need[1])
	return false

## How far along it is: [now, wanted].
static func need_progress(g, need: Array) -> Array:
	match str(need[0]):
		"built":
			return [mini(built_count(g), int(need[1])), int(need[1])]
		"plot":
			return [1 if built(g, str(need[1])) else 0, 1]
		"rank":
			# (the Underclothes release: a rank wants its plot too, so the count stops one short of the
			# households until the market or the wall stands: it used to read 50/50 with no market)
			var want := int(RANKS[int(need[1])][0])
			var have := mini(households(g), want)
			var plot := str(RANKS[int(need[1])][1]) if (RANKS[int(need[1])] as Array).size() > 1 else ""
			if plot != "" and not built(g, plot):
				have = mini(have, want - 1)
			return [have, want]
		"households":
			return [mini(households(g), int(need[1])), int(need[1])]
	return [0, 1]

## The plot a step of kind "hold" is waiting for somebody to build ("" if building is not what it
## lacks, or nothing can be built yet): the bot builds this.
static func wanted(g, need: Array) -> String:
	if need_met(g, need):
		return ""
	if str(need[0]) == "plot":
		return str(need[1]) if blocked(g, str(need[1])) == "" else ""
	return next(g)

## A journey begun past the founding (the bot's --bot-start, the tests): the town is as far along as
## the steps behind step `idx` would have left it: founded, the plots their "hold" steps asked for
## built, the families their errands asked for come.
static func catch_up(g, idx: int) -> void:
	if Data.step_index(FOUND_STEP) < 0 or idx <= Data.step_index(FOUND_STEP):
		return
	_day0(g)
	if not g.hold.has("built"):
		g.hold["built"] = {}
	if not g.hold.has("settlers"):
		g.hold["settlers"] = {}
	for i in idx:
		var st: Dictionary = Data.STEPS[i]
		var came := 0
		if str(st.kind) == "folk" and bool(Folk.ERRANDS.get(str(st.id), {}).get("settle", false)):
			came = int(st.n)
		elif str(st.kind) == "visits" and bool(st.get("settle", false)):
			came = int(st.n)
		for k in came:
			g.hold.settlers["%s:%d" % [str(st.id), k]] = "A family of the road"
		if str(st.kind) == "hold":
			for id in ORDER:
				if need_met(g, st.need):
					break
				g.hold.built[id] = true

# ---------------------------------------------------------------- what is read of it
static func summary(g) -> String:
	if not founded(g):
		return "No town yet."
	return "%s: %d households (room for %d), %d of %d plots built, power %d" % [rank_name(g), households(g), room(g), built_count(g), ORDER.size(), power(g)]

## The Town page (Esc > Town).
static func text(g) -> String:
	if not founded(g):
		return "Where Shun lived, in a year there was a hamlet, in two a town, in three a capital.\n\nYou answer for no town yet. (The story comes to it in Part XXV.)"
	var out := "%s, on the east shoulder of Azure Cloud Mountain\n\n" % rank_name(g)
	out += "Households: %d  (room for %d; %d families asked to come, %d grown of itself)\n" % [households(g), room(g), settlers(g), grown(g)]
	out += "Dues: %d spirit stones a day; in the chest now: %d  (it holds %d days; the steward, Feng Xuan, keeps it)\n" % [due(g), chest(g), CHEST_DAYS]
	out += "Power: %d" % power(g)
	if watch(g):
		out += "  -  the Watch of Guiyun marches with the host"
	out += "\n"
	if built(g, "school"):
		out += "Disciples of the Hall of the Broom: %d" % disciples(g)
		if sect(g) != "":
			out += "  -  %s (you: %s)" % [sect_name(g), sect_title(g)]
		out += "\n"
	var nx := rank(g) + 1
	if nx < RANKS.size():
		out += "To be %s: %s\n" % [str(RANK_WORDS[nx]), rank_lack(g, nx)]
	out += "\nBuilt:\n"
	for id in ORDER:
		if built(g, id):
			out += "  %s\n" % str(PLOTS[id].n)
	var todo := unbuilt(g)
	if not todo.is_empty():
		out += "\nDrawn up, not built (speak to the steward):\n"
		for id2 in todo:
			var why := blocked(g, id2)
			out += "  %s  -  %d spirit stones%s\n" % [str(PLOTS[id2].n), cost(g, id2), "" if why == "" else "  (%s)" % why]
	return out

## What the ending says of the town (one line, or none if there is none).
static func epilogue(g) -> Array:
	if not founded(g):
		return []
	var out: Array = []
	match rank(g):
		1:
			out.append("On the east shoulder of the mountain there is a hamlet called Guiyun, of %d households, where nobody was sent and everybody came." % households(g))
		2:
			out.append("On the east shoulder of the mountain there is a town called Guiyun, of %d households and one honest steelyard, a day from anywhere, and never short of people who have decided to walk there." % households(g))
		3:
			out.append("On the east shoulder of the mountain stands Guiyun of the Hundred Households, behind a wall each family raised its own length of. Its gate opens at cock-crow, and the man who opens it crows.")
	match sect(g):
		"found":
			out.append("Over its Hall of the Broom hangs the board of the Returning Cloud Sect, %d disciples, the youngest sect in the land and the only one whose first lesson is a street." % disciples(g))
		"take":
			out.append("On Frostpeak the Cold Pine Sect has a patriarch who is seldom there, and %d disciples who sweep, now, because he said so." % disciples(g))
		"serve":
			out.append("The Hall of the Broom is a hall of the Azure Cloud, and sends its %d disciples up the nine hundred steps every spring, and they come back knowing how to sweep them." % disciples(g))
	return out

# ---------------------------------------------------------------- where it stands
## The tile of the ground at `off`, in the region's own tiles.
static func tile(off: Vector2i) -> Vector2i:
	return AT + off

## Where the steward stands: in front of the hall (Data.AREAS writes him there; the tests compare).
const STEWARD_AT := Vector2i(5, 2)

## Stand the plots and the settlers on the ground (realm `layer` only if it has the region): entities
## of kind "hold" (`plot`), the settlers ("npc" with `hold`: the households it takes) and the steward,
## who is written with the region like everybody else (Data.AREAS, "late", with `"hold": true`: stood
## here and not with the region's other late-comers, which are stood before the peaks are laid out).  The ground was
## found open, with nothing within three tiles of it, in the release that added it; a plot whose tile
## is no longer open is left out (the tests would say so).  Added to `ents`.
static func place(grid: PackedByteArray, W: int, ids: Array, ents: Array, layer: String) -> void:
	if not ids.has(AREA):
		return
	for id in ORDER:
		if id == "wall":
			continue
		var q := Atlas.to_world(AREA, tile(PLOTS[id].at))
		if not MapGen.is_walkable_tile(grid[q.y * W + q.x]):
			continue
		ents.append({"kind": "hold", "id": "hold:" + id, "plot": id, "pos": q, "area": AREA, "layer": layer, "late": true})
	# the wall: every length of it is of the one plot, and stands when that is built (`seg`: which way it
	# runs, whether it is a corner, whether it is the length that carries the gate-tower)
	for wt in wall_tiles():
		var wq := Atlas.to_world(AREA, tile(wt[0]))
		if not MapGen.is_walkable_tile(grid[wq.y * W + wq.x]):
			continue
		var main: bool = wt[0] == PLOTS.wall.at
		ents.append({"kind": "hold", "id": "hold:wall" if main else "hold:wall:%d_%d" % [(wt[0] as Vector2i).x, (wt[0] as Vector2i).y], "plot": "wall", "seg": [wt[1], wt[2], main],
			"pos": wq, "area": AREA, "layer": layer, "late": true})
	for n in Data.AREAS[AREA].get("npcs", []):
		if n.has("hold"):
			ents.append({"kind": "npc", "id": str(n.id), "n": str(n.n), "pos": Atlas.to_world(AREA, n.pos), "col": n.col, "vis": n.get("vis", ["", ""]), "area": AREA, "layer": layer, "late": true})
	for i in SETTLERS.size():
		var sv: Array = SETTLERS[i]
		ents.append({"kind": "npc", "id": "settler:%d" % i, "n": str(sv[1]), "asset": str(sv[2]), "col": sv[3], "pos": Atlas.to_world(AREA, tile(sv[4])),
			"area": AREA, "layer": layer, "late": true, "vis": ["", ""], "hold": int(sv[0]), "lines": sv.slice(5)})

## Whether hold entity `e` (a plot, or a settler) is in the world of `g`.
static func stands(g, e: Dictionary) -> bool:
	if e.has("plot"):
		return built(g, str(e.plot))
	return founded(g) and households(g) >= int(e.get("hold", 0))

## What plot entity `e` is just now: "" while it is not built, else a word that changes only if what
## stands there does (the world builds its model again when it does).
static func key(g, e: Dictionary) -> String:
	if not built(g, str(e.plot)):
		return ""
	return "%s:%d:%s" % [str(e.plot), rank(g), sect(g) if str(e.plot) in ["hall", "school"] else ""]

## What is written over plot entity `e` (a length of the wall that is not the gate's has no name of its own).
static func name_of(e: Dictionary) -> String:
	if e.has("seg") and not bool(e.seg[2]):
		return ""
	return str(PLOTS[str(e.plot)].n)

## The model of plot entity `e` in a town of rank `r` whose sect is `sc`.
static func model_of(e: Dictionary, r: int, sc: String) -> Node3D:
	if e.has("seg"):
		var root := Node3D.new()
		var b := MB.new()
		var g := MB.new()
		_wall(b, g, Vector3.ZERO, e.seg[0], bool(e.seg[1]), bool(e.seg[2]), r)
		MB.mesh_node(root, b.build(MB.mat_vc()))
		if not g.is_empty():
			MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return root
	return model(str(e.plot), r, sc)

static func desc_of(_g, e: Dictionary) -> String:
	return str(PLOTS[str(e.plot)].desc)

# ---------------------------------------------------------------- what it looks like
const EARTH := Color("b8a486")
const EARTH_DARK := Color("8a7458")
const PLASTER := Color("e8e0cc")
const TIMBER := Color("6a4a30")
const TIMBER_DARK := Color("3e2c1e")
const THATCH := Color("a89462")
const TILE := Color("5a6470")
const GLAZE := Color("3e6a5c")
const STONE := Color("8a8478")
const RED := Color("b83a2a")
const SECT_COLS := {"": Color("d8c8a0"), "found": Color("f0f0f8"), "take": Color("2a5a48"), "serve": Color("3a8ae8")}

## The colour of a roof by the town's rank: thatch for a hamlet, grey tile for a town, glazed green
## for a city.
static func _roof_col(r: int) -> Color:
	return MB.tag(THATCH if r <= 1 else (TILE if r == 2 else GLAZE), MB.FOLIAGE if r <= 1 else MB.STONE)

## A house: walls `w` by `d` and `hgt` high on a stone footing, a door on the south side, a gabled
## roof with its ridge along x.
static func _house(b: MB, at: Vector3, w: float, d: float, hgt: float, wall: Color, roof: Color, door: bool = true) -> void:
	b.box(at + Vector3(0, 0.08, 0), Vector3(w + 0.12, 0.16, d + 0.12), MB.tag(STONE, MB.STONE))
	b.box(at + Vector3(0, 0.16 + hgt * 0.5, 0), Vector3(w, hgt, d), wall)
	for sx in [-1.0, 1.0]:
		b.box(at + Vector3(sx * (w * 0.5 - 0.04), 0.16 + hgt * 0.5, d * 0.5 + 0.01), Vector3(0.1, hgt, 0.06), MB.tag(TIMBER, MB.WOOD))
	b.box(at + Vector3(0, 0.16 + hgt - 0.05, d * 0.5 + 0.01), Vector3(w, 0.1, 0.06), MB.tag(TIMBER, MB.WOOD))
	if door:
		b.box(at + Vector3(0, 0.16 + 0.5, d * 0.5 + 0.02), Vector3(0.46, 1.0, 0.05), MB.tag(TIMBER_DARK, MB.WOOD))
	b.prim("prism", MB._xf(at + Vector3(0, 0.16 + hgt + 0.5, 0), Vector3(w + 0.6, 1.0, d + 0.7), Vector3.ZERO), roof)
	b.box(at + Vector3(0, 0.16 + hgt + 1.02, 0), Vector3(w + 0.66, 0.08, 0.14), MB.tag(TIMBER_DARK, MB.WOOD))

static func _stick(b: MB, a: Vector3, c: Vector3, r: float, col: Color) -> void:
	b.limb(a, c, r, r, col, 5)

## One length of the wall at `off`: rammed earth a tile long, running `along`, with merlons; a corner
## is a squat tower; the `main` length also carries the Cloud Gate over the open tile to its west
## (two posts, a lintel, an upper room and a roof, the leaves standing open, a lantern each side).
static func _wall(b: MB, g: MB, off: Vector3, along: Vector2i, corner: bool, main: bool, r: int) -> void:
	var ew := MB.tag(EARTH, MB.STONE)
	var ed := MB.tag(EARTH_DARK, MB.STONE)
	if corner:
		b.box(off + Vector3(0, 1.2, 0), Vector3(2.0, 2.4, 2.0), ed)
		b.prim("prism", MB._xf(off + Vector3(0, 2.75, 0), Vector3(2.5, 0.7, 2.5), Vector3.ZERO), _roof_col(maxi(r, 2)))
		return
	var lx := along.x != 0
	b.box(off + Vector3(0, 0.9, 0), Vector3(2.0, 1.8, 0.9) if lx else Vector3(0.9, 1.8, 2.0), ew)
	b.box(off + Vector3(0, 0.12, 0), Vector3(2.0, 0.24, 1.1) if lx else Vector3(1.1, 0.24, 2.0), ed)
	for k in 2:
		var t := -0.5 + k * 1.0
		b.box(off + (Vector3(t, 1.96, 0.28) if lx else Vector3(0.28, 1.96, t)), Vector3(0.5, 0.32, 0.34) if lx else Vector3(0.34, 0.32, 0.5), ew)
	if not main:
		return
	var c := off + Vector3(-2.0, 0, 0)
	for sx in [-1.0, 1.0]:
		b.box(c + Vector3(sx * 0.88, 1.25, 0), Vector3(0.3, 2.5, 1.2), ed)
		b.box(c + Vector3(sx * 0.62, 1.0, 0.75), Vector3(0.06, 2.0, 0.66), MB.tag(RED.darkened(0.3), MB.WOOD), Vector3(0, sx * 0.5, 0))
		g.sph(c + Vector3(sx * 0.88, 2.1, 0.68), Vector3(0.12, 0.17, 0.12), Color(1.0, 0.7, 0.34))
	b.box(c + Vector3(0, 2.62, 0), Vector3(2.4, 0.26, 1.4), MB.tag(TIMBER_DARK, MB.WOOD))
	b.box(c + Vector3(0, 3.25, 0), Vector3(2.0, 1.0, 1.0), MB.tag(PLASTER, MB.STONE))
	b.box(c + Vector3(0, 3.25, 0.51), Vector3(0.5, 0.44, 0.03), MB.tag(Color("2a2420"), MB.WOOD))
	b.prim("prism", MB._xf(c + Vector3(0, 4.15, 0), Vector3(2.9, 0.8, 1.8), Vector3.ZERO), _roof_col(maxi(r, 2)))
	b.box(c + Vector3(0, 2.62, 0.72), Vector3(0.9, 0.2, 0.04), MB.tag(Color("2a1c14"), MB.WOOD))

## The model of plot `id` in a town of rank `r` whose sect is `sc` ("" if none).
static func model(id: String, r: int = 1, sc: String = "") -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	var m := MB.new()
	var pivot := Vector3.ZERO
	var move := ""
	var wall := MB.tag(EARTH if r <= 1 else PLASTER, MB.STONE)
	var roof := _roof_col(r)
	var wd := MB.tag(TIMBER, MB.WOOD)
	var wdd := MB.tag(TIMBER_DARK, MB.WOOD)
	var st := MB.tag(STONE, MB.STONE)
	match id:
		"hall":
			_house(b, Vector3.ZERO, 3.0, 1.9, 1.5 if r <= 1 else 1.8, wall, roof)
			# (the steps, and the board over the door)
			b.box(Vector3(0, 0.06, 1.2), Vector3(1.2, 0.12, 0.4), st)
			b.box(Vector3(0, 1.36 if r <= 1 else 1.6, 1.0), Vector3(0.9, 0.24, 0.05), MB.tag(Color("2a1c14"), MB.WOOD))
			# (a banner on a pole: plain until there is a sect, then its colour)
			_stick(b, Vector3(1.75, 0, 0.9), Vector3(1.75, 3.4, 0.9), 0.04, wdd)
			m.box(Vector3(0.3, 0.0, 0), Vector3(0.6, 0.9, 0.02), MB.tag(SECT_COLS.get(sc, SECT_COLS[""]), MB.CLOTH))
			pivot = Vector3(1.75, 2.85, 0.9)
			move = "rock"
			if r >= 3:
				for sx in [-1.0, 1.0]:
					g.sph(Vector3(sx * 0.75, 1.3, 1.06), Vector3(0.12, 0.16, 0.12), Color(1.0, 0.72, 0.36))
		"well":
			b.lathe(Vector3.ZERO, [Vector2(0.62, 0.0), Vector2(0.62, 0.6), Vector2(0.5, 0.62), Vector2(0.48, 0.2)], st, 10)
			b.disc(Vector3(0, 0.22, 0), 0.48, MB.tag(Color("2a4a5a"), MB.CRYSTAL), 10)
			_stick(b, Vector3(-0.9, 0, 0.2), Vector3(-0.9, 1.9, 0.2), 0.06, wd)
			_stick(b, Vector3(-1.9, 1.3, 0.2), Vector3(0.4, 2.25, 0.2), 0.04, wd)
			_stick(b, Vector3(0.4, 2.25, 0.2), Vector3(0.3, 0.9, 0.1), 0.012, wdd)
			b.lathe(Vector3(0.3, 0.7, 0.1), [Vector2(0.1, 0.0), Vector2(0.14, 0.22)], wd, 8)
			b.sph(Vector3(-1.9, 1.3, 0.2), Vector3(0.16, 0.16, 0.16), st, Vector3.ZERO, true)
		"homes1", "homes2", "homes3":
			var two := id != "homes1" and r >= 2
			var hh := 1.25 if not two else 2.3
			_house(b, Vector3(0, 0, -0.1), 2.9, 1.5, hh, wall, roof, false)
			var doors := 3 if id == "homes1" else 4
			for k in doors:
				var x := -1.1 + 2.2 * k / float(doors - 1)
				b.box(Vector3(x, 0.16 + 0.45, 0.67), Vector3(0.34, 0.9, 0.05), wdd)
				if two:
					b.box(Vector3(x, 0.16 + 1.7, 0.67), Vector3(0.3, 0.34, 0.04), MB.tag(Color("2a2420"), MB.WOOD))
				# (a sprig of pine over every lintel)
				b.sph(Vector3(x, 0.16 + 0.98, 0.7), Vector3(0.12, 0.05, 0.04), MB.tag(Color("3a6a3a"), MB.FOLIAGE), Vector3.ZERO, true)
			if id == "homes3":
				# (the persimmon tree in the yard)
				_stick(b, Vector3(0.2, 0, 1.25), Vector3(0.25, 1.3, 1.2), 0.07, wdd)
				b.sph(Vector3(0.25, 1.75, 1.2), Vector3(0.7, 0.55, 0.65), MB.tag(Color("4a7a3a"), MB.FOLIAGE))
				for k2 in 5:
					g.ball(Vector3(0.25 + cos(k2 * 1.9) * 0.5, 1.6 + 0.12 * (k2 % 3), 1.2 + sin(k2 * 1.9) * 0.45), 0.07, Color(1.0, 0.5, 0.15))
			if id == "homes2" and r >= 2:
				_stick(b, Vector3(-1.6, 1.3, 0.8), Vector3(1.6, 1.3, 0.8), 0.012, wdd)
				for k3 in 4:
					b.box(Vector3(-1.1 + k3 * 0.7, 1.08, 0.8), Vector3(0.36, 0.42, 0.02), MB.tag([Color("d8d0c0"), Color("7a8ab0"), Color("c87a6a"), Color("e8e0d0")][k3], MB.CLOTH))
		"granary":
			for k4 in 9:
				var a4 := TAU * k4 / 9.0
				b.lathe(Vector3(cos(a4) * 0.85, 0, sin(a4) * 0.85) if k4 < 8 else Vector3.ZERO, [Vector2(0.1, 0.0), Vector2(0.09, 0.42), Vector2(0.24, 0.5), Vector2(0.0, 0.56)], st, 6)
			b.lathe(Vector3(0, 0.56, 0), [Vector2(1.1, 0.0), Vector2(1.2, 0.9), Vector2(1.1, 1.7)], MB.tag(EARTH, MB.STONE), 12)
			b.lathe(Vector3(0, 2.2, 0), [Vector2(1.5, 0.0), Vector2(0.8, 0.6), Vector2(0.0, 1.0)], MB.tag(THATCH, MB.FOLIAGE), 12)
			b.box(Vector3(0, 1.5, 1.14), Vector3(0.5, 0.6, 0.06), wdd)
			_stick(b, Vector3(-0.2, 0, 1.7), Vector3(-0.2, 1.3, 1.2), 0.03, wd)
			_stick(b, Vector3(0.2, 0, 1.7), Vector3(0.2, 1.3, 1.2), 0.03, wd)
			for k5 in 4:
				_stick(b, Vector3(-0.2, 0.25 + k5 * 0.3, 1.6 - k5 * 0.115), Vector3(0.2, 0.25 + k5 * 0.3, 1.6 - k5 * 0.115), 0.022, wd)
		"market":
			for sx2 in [-1.2, 1.2]:
				for sz2 in [-0.8, 0.8]:
					_stick(b, Vector3(sx2, 0, sz2), Vector3(sx2, 2.0, sz2), 0.06, wd)
			b.prim("prism", MB._xf(Vector3(0, 2.25, 0), Vector3(3.0, 0.5, 2.2), Vector3.ZERO), MB.tag(Color("b8703a") if r <= 2 else RED, MB.CLOTH))
			_stick(b, Vector3(-1.2, 1.95, 0), Vector3(1.2, 1.95, 0), 0.04, wdd)
			# (the steelyard on the middle beam, and mats of goods under it)
			_stick(b, Vector3(0, 1.95, 0), Vector3(0, 1.5, 0), 0.01, wdd)
			_stick(b, Vector3(-0.5, 1.5, 0), Vector3(0.5, 1.5, 0), 0.02, MB.tag(Color("b8863a"), MB.METAL))
			b.lathe(Vector3(-0.45, 1.1, 0), [Vector2(0.0, 0.0), Vector2(0.18, 0.04), Vector2(0.2, 0.1)], MB.tag(Color("b8863a"), MB.METAL), 8)
			b.sph(Vector3(0.4, 1.36, 0), Vector3(0.07, 0.1, 0.07), MB.tag(Color("4a4a52"), MB.METAL), Vector3.ZERO, true)
			for k6 in 3:
				b.box(Vector3(-0.8 + k6 * 0.8, 0.03, 0.3), Vector3(0.6, 0.04, 0.8), MB.tag([Color("c8b070"), Color("a84a3a"), Color("6a8a5a")][k6], MB.CLOTH))
				for k7 in 3:
					b.sph(Vector3(-0.95 + k6 * 0.8 + k7 * 0.15, 0.12, 0.2 + 0.2 * (k7 % 2)), Vector3(0.09, 0.08, 0.09), MB.tag([Color("d8a040"), Color("e8e0c8"), Color("5a8a3a")][(k6 + k7) % 3], MB.FOLIAGE), Vector3.ZERO, true)
		"inn":
			_house(b, Vector3(-0.2, 0, -0.2), 2.4, 1.6, 2.2 if r >= 2 else 1.5, wall, roof)
			# (the sign: a cloud coming back; a lantern each side of the door; a hitching rail)
			_stick(b, Vector3(1.25, 0, 0.9), Vector3(1.25, 2.3, 0.9), 0.04, wdd)
			_stick(b, Vector3(1.25, 2.2, 0.9), Vector3(1.75, 2.2, 0.9), 0.025, wdd)
			m.box(Vector3(0.0, -0.3, 0), Vector3(0.5, 0.42, 0.04), MB.tag(Color("e8e0cc"), MB.WOOD))
			m.sph(Vector3(0.0, -0.28, 0.03), Vector3(0.16, 0.09, 0.01), MB.tag(Color("7a9ac8"), MB.CLOTH), Vector3.ZERO, true)
			pivot = Vector3(1.55, 2.2, 0.9)
			move = "rock"
			for sx3 in [-0.6, 0.2]:
				g.sph(Vector3(sx3, 1.2, 0.68), Vector3(0.1, 0.14, 0.1), Color(1.0, 0.66, 0.3))
			_stick(b, Vector3(-1.5, 0.7, 1.2), Vector3(-0.3, 0.7, 1.2), 0.035, wd)
			for sx4 in [-1.5, -0.3]:
				_stick(b, Vector3(sx4, 0, 1.2), Vector3(sx4, 0.7, 1.2), 0.04, wd)
		"smithy":
			_house(b, Vector3(-0.3, 0, -0.3), 2.2, 1.5, 1.4, MB.tag(EARTH_DARK, MB.STONE), roof)
			b.box(Vector3(1.1, 0.7, -0.3), Vector3(0.5, 1.4, 0.5), st)
			b.box(Vector3(1.1, 2.2, -0.3), Vector3(0.34, 1.7, 0.34), st)
			g.sph(Vector3(1.1, 0.75, 0.0), Vector3(0.16, 0.12, 0.06), Color(1.0, 0.45, 0.12))
			b.box(Vector3(0.9, 0.3, 0.9), Vector3(0.3, 0.6, 0.3), wdd)
			b.box(Vector3(0.9, 0.68, 0.9), Vector3(0.5, 0.16, 0.2), MB.tag(Color("4a4a52"), MB.METAL))
			for k8 in 4:
				_stick(b, Vector3(-1.2 + k8 * 0.16, 0, 0.75), Vector3(-1.2 + k8 * 0.16, 1.5, 0.6), 0.018, wd)
				b.cone(Vector3(-1.2 + k8 * 0.16, 1.6, 0.59), 0.03, 0.2, MB.tag(Color("9a9aa4"), MB.METAL))
		"drill":
			b.box(Vector3(0, 0.015, 0), Vector3(3.0, 0.03, 3.0), MB.tag(Color("a89070"), MB.STONE))
			# (the drum on its post, the rack of practice spears, and four pennons at the corners)
			_stick(b, Vector3(-1.0, 0, -1.0), Vector3(-1.0, 1.1, -1.0), 0.06, wd)
			b.cyl(Vector3(-1.0, 1.35, -1.0), 0.36, 0.3, MB.tag(RED, MB.WOOD), Vector3(PI * 0.5, 0, 0), 12)
			b.disc(Vector3(-1.0, 1.35, -0.84), 0.33, MB.tag(Color("e8dcc0"), MB.CLOTH), 12, Color(0, 0, 0, -1), Vector3(PI * 0.5, 0, 0))
			for sx5 in [0.3, 1.3]:
				_stick(b, Vector3(sx5, 0, -1.2), Vector3(sx5, 1.2, -1.2), 0.04, wd)
			_stick(b, Vector3(0.3, 1.15, -1.2), Vector3(1.3, 1.15, -1.2), 0.03, wd)
			for k9 in 6:
				_stick(b, Vector3(0.38 + k9 * 0.17, 0, -1.0), Vector3(0.38 + k9 * 0.17, 1.9, -1.24), 0.015, wd)
			for c in [[-1.4, 1.4], [1.4, 1.4], [1.4, -1.4]]:
				_stick(b, Vector3(c[0], 0, c[1]), Vector3(c[0], 1.6, c[1]), 0.025, wdd)
				b.leaf(Vector3(c[0], 1.55, c[1]), Vector3(c[0] + 0.45, 1.4, c[1]), 0.18, MB.tag(RED, MB.CLOTH))
		"school":
			_house(b, Vector3(0, 0, -0.2), 2.6, 1.7, 1.6, wall, roof)
			b.box(Vector3(0, 1.5, 0.68), Vector3(1.0, 0.26, 0.05), MB.tag(SECT_COLS.get(sc, Color("2a1c14")) if sc != "" else Color("2a1c14"), MB.WOOD))
			# (the rack of nine brooms beside the door, worn to different lengths)
			_stick(b, Vector3(0.7, 0.9, 0.75), Vector3(1.6, 0.9, 0.75), 0.025, wd)
			for k10 in 9:
				var bx := 0.74 + k10 * 0.1
				var bl := 0.5 + 0.045 * ((k10 * 5) % 9)
				_stick(b, Vector3(bx, 0.9 - bl, 0.78), Vector3(bx, 1.0, 0.78), 0.012, wd)
				b.cone(Vector3(bx, 0.9 - bl - 0.08, 0.78), 0.05, 0.2, MB.tag(THATCH, MB.FOLIAGE), Vector3(PI, 0, 0), 5)
			for k11 in 3:
				b.box(Vector3(-0.9 + k11 * 0.5, 0.03, 1.2), Vector3(0.4, 0.04, 0.5), MB.tag(Color("b8a070"), MB.CLOTH))
		"wall":
			# (as the gallery shows it: the Cloud Gate between the lengths either side of it; in the land
			# every length is its own, `model_of`)
			_wall(b, g, Vector3(2.0, 0, 0), Vector2i(1, 0), false, true, r)
			_wall(b, g, Vector3(4.0, 0, 0), Vector2i(1, 0), false, false, r)
			_wall(b, g, Vector3(-2.0, 0, 0), Vector2i(1, 0), false, false, r)
			_wall(b, g, Vector3(-4.0, 0, 0), Vector2i(1, 0), false, false, r)
		_:
			b.box(Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8), wd)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc()))
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not m.is_empty():
		var mv := MB.mesh_node(root, m.build(MB.mat_vc()), pivot)
		root.set_meta(move, mv)
	return root
