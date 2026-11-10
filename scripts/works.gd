class_name Works
extends RefCounted
## The Hundred Works (the Hundred Works release): the things people make, from the first fire-drill to
## a chariot that always points south, and what Lin Feng chooses to make of them.
##
## A cultivation world is not only swords and qi.  Somebody dug the wells, hung the bells and built
## the boats, and in the old books the makers are remembered beside the sages: Suiren who drilled
## fire, Lu Ban the carpenter, Mozi who built a wooden kite and then said a linchpin was worth more,
## Du Shi who set a river to blow his furnaces, Ma Jun and the south-pointing chariot, Zhuge Liang's
## wooden ox.  This file is their eighteen **works**, in three **schools**:
##
##   hand    the oldest things, that nobody can take from you: the fire-drill, knotted cords, the
##           sling, the kiln, the stone adze, the hide coat (they make the *wanderer* hardier)
##   wheel   machinery, wood and bronze and falling water: the well-sweep, the water trip-hammer, the
##           water-bellows, the repeating crossbow, the south-pointing chariot, the wooden ox (they
##           make the *towns* richer and the forge and the market cheaper)
##   dao     the arts of qi worked into a thing: the spirit-gathering array, cinnabar talismans, the
##           eight-trigram furnace, paper servants, the heaven-watching mirror, formation flags (they
##           make the *cultivator* deeper)
##
## A work is **built** from the Works page (Esc > Works) once the story has reached it (`after`), the
## work before it in its school stands, and Lin Feng has the **know-how** and the spirit stones.
## Know-how is never bought: it is what he has learned by looking, one for every kind of creature in
## the bestiary (a lord counts there too), every lord defeated and every thing of the land tried, two for
## every deed done and every one of the Founder's caves opened, one for every obstacle cleared.  A whole playthrough earns
## enough for about two schools of the three, so **which to build is a choice**, and it is one the
## land remembers: what stands in the towns (the machines are there to be seen and looked at,
## machines.gd), what the people say, which roads open through the trials of Part XIX ("By the
## works"), and how the last question of that chapter can be answered (echoes.gd).
##
## Everything here takes the game state `g` as an argument (the Game autoload in play, a game state
## of their own in the tests), like trials.gd.

const SCHOOLS := {
	"hand": {"n": "The Hand", "col": Color("d8b070"), "motto": "What the hand knows, nobody can carry off.",
		"what": "the oldest tools: fire, cord, stone, clay and hide", "maker": "a maker of the old tools"},
	"wheel": {"n": "The Wheel", "col": Color("7ab8d8"), "motto": "Let the river do it.",
		"what": "machinery: wood, bronze and falling water", "maker": "a builder of engines"},
	"dao": {"n": "The Art", "col": Color("c8a0f0"), "motto": "The Dao is in the tool, if you put it there.",
		"what": "qi worked into a thing: arrays, talismans and furnaces", "maker": "an artificer of the Dao"},
}
const SCHOOL_ORDER := ["hand", "wheel", "dao"]
const TIERS := 6
## what each tier costs: know-how, and spirit stones
const TIER_KNOW := [6, 16, 32, 56, 90, 130]
const TIER_STONES := [60, 500, 3000, 15000, 60000, 150000]
## the story step each tier waits for (the first is there from the first hunt)
const TIER_AFTER := ["s_hunt1", "s_p3_home", "s_p5_home", "s_p9_home", "s_p13_home", "s_p17_home"]

## The works.  `key` is what it changes (see `mod` and `add`), `v` by how much, `does` says so in
## words, `site` is where it stands in the land once built: [region, tile of that region's own map].
const WORKS := {
	# ---- the Hand
	"fire_kit": {"school": "hand", "tier": 0, "n": "Fire-Drill and Tinder", "key": "hp", "v": 1.04, "site": ["mountain", Vector2i(77, 56)],
		"does": "A hot meal every night on the road: the party's health is a twenty-fifth greater.",
		"desc": "A spindle, a hearth-board, a bow and a horn of dry fungus. Suiren saw a bird peck sparks out of a tree and thought: I could do that. Everything since has been a footnote. With a fire of your own, any bare hillside is a camp, and nobody who has eaten hot food goes into a fight as he would have gone in cold."},
	"cords": {"school": "hand", "tier": 1, "n": "Knotted Cords", "key": "exp", "v": 1.04, "site": ["village", Vector2i(42, 15)],
		"does": "Every battle teaches a little more (+4% cultivation).",
		"desc": "Before there was writing, the old books say, people governed by knotting cords: a big knot for a big matter, a small knot for a small one. A fight tied into a cord can be told over again, slowly, the next morning, and learned from twice."},
	"sling": {"school": "hand", "tier": 2, "n": "Sling and River Stones", "key": "ambush", "v": 0.05, "site": ["bamboo", Vector2i(21, 22)],
		"does": "A pack struck first in the land loses another twentieth of its health.",
		"desc": "A strip of plaited hemp and a bag of stones the river has already rounded. The shepherds of the hills have brought down wolves with it since before there were swords, from further off than a sword can argue."},
	"kiln": {"school": "hand", "tier": 3, "n": "Clay Kiln and Sealed Jars", "key": "pill", "v": 1.15, "site": ["village", Vector2i(45, 47)],
		"does": "Pills kept in sealed clay restore 15% more.",
		"desc": "A beehive of clay with a fire under it, and jars that ring when you flick them. A pill that has sat a month in a cloth bag is half dust and half regret. In a sealed jar it is as the alchemist made it."},
	"adze": {"school": "hand", "tier": 4, "n": "Stone Adze", "key": "blows", "v": 1.0, "site": ["mountain", Vector2i(97, 47)],
		"does": "Whatever stands in the road (a trunk, a rockfall, a jam of ice) takes one blow fewer to clear.",
		"desc": "Jade-hard greenstone ground to an edge on wet sandstone, a month's work, hafted in a crook of ash. The first roads were cut with these. A sword opens a man; an adze opens a country."},
	"hide_coat": {"school": "hand", "tier": 5, "n": "Hide Coat and Bone Needle", "key": "taken", "v": 0.95, "site": ["thunder", Vector2i(26, 15)],
		"does": "The party takes a twentieth less harm.",
		"desc": "The horse-folk sew three layers of hide with a needle of crane bone and sinew that swells when it is wet, so the seams close in the rain. It is not armour. It has simply turned more blows than most armour, because nobody takes it off."},
	# ---- the Wheel
	"well_sweep": {"school": "wheel", "tier": 0, "n": "Well-Sweep", "key": "price", "v": 0.92, "site": ["village", Vector2i(17, 22)],
		"does": "With water to spare the gardens grow more herbs: pills cost 8% less everywhere.",
		"desc": "A long pole on a post, a stone lashed to the short end and a bucket hung from the long. Pull down, let go, and the stone lifts the water for you: a hundred furrows in a day where a pitcher waters one. An old gardener south of the Han refused to use one. He had his reasons."},
	"trip_hammer": {"school": "wheel", "tier": 1, "n": "Water Trip-Hammer", "key": "temper", "v": 0.85, "site": ["mountain", Vector2i(68, 57)],
		"does": "The river does the smith's heavy work: tempering the sword costs 15% less.",
		"desc": "A wheel in the stream, a shaft with pegs in it, and a hammer the pegs lift and let fall, all day, all night, for nothing. The books say one does the work of ten men husking rice. Smith Tie says it does the work of ten apprentices and none of the complaining."},
	"water_bellows": {"school": "wheel", "tier": 2, "n": "Water-Bellows", "key": "recipe", "v": 0.85, "site": ["tushan", Vector2i(33, 34)],
		"does": "A furnace blown by the river: whatever is made at the cauldron or the forge costs 15% fewer spirit stones.",
		"desc": "Prefect Du Shi set a water-wheel to push and pull the bellows of his furnaces, and the histories say the people got great benefit for little labour. A fire that is blown evenly burns hotter on less charcoal, and never gets tired at the wrong moment."},
	"crossbow": {"school": "wheel", "tier": 3, "n": "Repeating Crossbow", "key": "volley", "v": 0.04, "site": ["mountain", Vector2i(73, 48)],
		"does": "Yue Ling opens every battle with a volley: each foe of a pack loses 4% of its health before anybody moves.",
		"desc": "A box of bolts on top of the stock and a lever under it: push, pull, and it has shot and strung itself again. Ten bolts in the time it takes to say so. It is not accurate. With ten bolts it does not need to be."},
	"chariot": {"school": "wheel", "tier": 4, "n": "South-Pointing Chariot", "key": "wary", "v": 1.0, "site": ["dunes", Vector2i(21, 31)],
		"does": "It cannot be turned round: a hunting pack never takes the party by surprise.",
		"desc": "A wooden figure on a cart with its arm held out, and a train of gears between the wheels and the figure, so that however the cart turns, the arm still points south. No lodestone: only counting. The Yellow Emperor's found the way out of Chiyou's fog."},
	"wooden_ox": {"school": "wheel", "tier": 5, "n": "Wooden Ox and Gliding Horse", "key": "stones", "v": 1.12, "site": ["longmen", Vector2i(26, 39)],
		"does": "Nothing worth carrying is left on the field: battles pay 12% more spirit stones.",
		"desc": "A walking barrow on four legs that carries a year of one man's grain twenty li a day and wants no fodder. The Chancellor who built them fed an army over mountains with them. The drawings were lost, and found, and lost, which is what happens to drawings."},
	# ---- the Art
	"array": {"school": "dao", "tier": 0, "n": "Spirit-Gathering Array", "key": "med", "v": 1.08, "site": ["mountain", Vector2i(101, 56)],
		"does": "The qi of the place leans towards whoever sits down: cultivation in meditation comes 8% faster.",
		"desc": "Eight jade pegs set in the ground on the eight trigrams and a ninth in the middle to sit on. It makes nothing and moves nothing. It only asks the qi of the hillside, very politely, to come this way, and qi is easily led."},
	"talismans": {"school": "dao", "tier": 1, "n": "Cinnabar Talismans", "key": "cost", "v": 0.95, "site": ["mountain", Vector2i(61, 56)],
		"does": "Half the working is already written down: every technique costs a twentieth less qi.",
		"desc": "Yellow paper, a brush of wolf hair, and cinnabar ground in the hour of the Horse. A technique drawn beforehand needs only to be finished, not begun, the way a letter needs only a signature."},
	"furnace": {"school": "dao", "tier": 2, "n": "Eight-Trigram Furnace", "key": "drop", "v": 0.08, "site": ["volcano", Vector2i(38, 33)],
		"does": "It draws the essence out of what falls near it: monsters leave essences more often.",
		"desc": "Three legs, eight windows, and a lid cast with the trigrams in their Later Heaven order. An ordinary furnace burns what you put in it. This one persuades it, and a thing that has been persuaded gives up more than a thing that has been burnt."},
	"paper_servants": {"school": "dao", "tier": 3, "n": "Paper Servants", "key": "heavy", "v": 0.9, "site": ["yanggu", Vector2i(30, 40)],
		"does": "They stand in front, a hand high and perfectly brave: a lord's devastating blows land a tenth softer.",
		"desc": "Cut from one sheet, folded once, breathed on. They stand a hand high, bow, and do what they are shown, which is very little, very carefully: mostly, to stand between. They cannot be shown anything cruel: paper has no stomach for it and comes apart."},
	"mirror": {"school": "dao", "tier": 4, "n": "Heaven-Watching Mirror", "key": "doze", "v": 0.1, "site": ["mountain", Vector2i(65, 32)],
		"does": "It shows what sleeps and how deeply: a pack caught asleep loses a tenth of its health before it wakes.",
		"desc": "Bronze, tin and a year of polishing, set in a ring that turns with the stars. The astronomers use the like to watch Heaven. Turned downward, it shows which shapes on the hillside are breathing slowly."},
	"flags": {"school": "dao", "tier": 5, "n": "Formation Flags", "key": "weak", "v": 0.1, "site": ["frost", Vector2i(25, 22)],
		"does": "Five flags, five phases, and the ground itself leans on a foe's weakness: it cuts deeper (+0.1).",
		"desc": "Five small flags in the five colours, planted before a fight in the order in which the phases overcome one another: wood parts earth, earth dams water, water quenches fire, fire melts metal, metal cuts wood. The fight then happens somewhere that agrees with you."},
}
const ORDER := ["fire_kit", "cords", "sling", "kiln", "adze", "hide_coat", "well_sweep", "trip_hammer", "water_bellows", "crossbow", "chariot", "wooden_ox",
	"array", "talismans", "furnace", "paper_servants", "mirror", "flags"]
## keys whose works add to a number; all the others multiply it
const ADDS := ["ambush", "volley", "drop", "doze", "weak"]

## the three answers to the last question of Part XIX (echoes.gd CROSSROADS "the_works"), by school
const WAYS := {"hand": "The hand first", "wheel": "The wheel, kept by hours", "dao": "The Dao in the tool"}

# ---------------------------------------------------------------- state
static func has(g, id: String) -> bool:
	return g.works.has(id)

## How many works stand (of one school, or of all).
static func count(g, school: String = "") -> int:
	if school == "":
		return g.works.size()
	var n := 0
	for id in g.works:
		if str(WORKS.get(id, {}).get("school", "")) == school:
			n += 1
	return n

## The school Lin Feng has built most of ("" with nothing built; the earlier school wins a tie).
static func leading(g) -> String:
	var best := ""
	var top := 0
	for sc in SCHOOL_ORDER:
		var n := count(g, sc)
		if n > top:
			top = n
			best = sc
	return best

## What the makers of the land call him.
static func title(g) -> String:
	var n := count(g)
	if n == 0:
		return "No maker yet"
	var sc := leading(g)
	var rank := "Apprentice" if n < 4 else ("Journeyman" if n < 8 else ("Master" if n < 12 else "Grand Master"))
	return "%s of %s" % [rank, str(SCHOOLS[sc].n)]

# ---------------------------------------------------------------- know-how
## What Lin Feng has learned by looking: never spent on anything but works.
static func know_earned(g) -> int:
	return g.bestiary.size() + g.boss_done.size() + g.prop_found.size() + g.cleared.size() + 2 * g.deeds.size() + 2 * g.abodes.size()

static func know_spent(g) -> int:
	var n := 0
	for id in g.works:
		if WORKS.has(id):
			n += int(TIER_KNOW[int(WORKS[id].tier)])
	return n

static func know(g) -> int:
	return know_earned(g) - know_spent(g)

static func cost_know(id: String) -> int:
	return int(TIER_KNOW[int(WORKS[id].tier)])

## (the makers ask a quarter less of somebody the land knows for the new works: echoes.gd)
static func cost_stones(g, id: String) -> int:
	return int(round(int(TIER_STONES[int(WORKS[id].tier)]) * Echoes.lean_mod(g, "works_stones")))

## The work before `id` in its school ("" for the first).
static func before(id: String) -> String:
	var w: Dictionary = WORKS[id]
	for o in ORDER:
		if str(WORKS[o].school) == str(w.school) and int(WORKS[o].tier) == int(w.tier) - 1:
			return o
	return ""

## Whether the story has reached a work (it is listed on the Works page from then on).
static func known(g, id: String) -> bool:
	return g.reached(str(TIER_AFTER[int(WORKS[id].tier)]))

## Why `id` cannot be built now ("" if it can).
static func blocked(g, id: String) -> String:
	if not WORKS.has(id):
		return "No such work."
	if has(g, id):
		return "Already built."
	if not known(g, id):
		return "Nobody in the land knows how yet."
	var b := before(id)
	if b != "" and not has(g, b):
		return "First: %s." % str(WORKS[b].n)
	if know(g) < cost_know(id):
		return "Know-how %d of %d: look at more of the world." % [know(g), cost_know(id)]
	if g.stones < cost_stones(g, id):
		return "%d spirit stones of %d." % [g.stones, cost_stones(g, id)]
	return ""

static func can_build(g, id: String) -> bool:
	return blocked(g, id) == ""

## Build `id`: paid for, remembered with the day it was built, and the makers hear of it.
static func build(g, id: String) -> bool:
	if not can_build(g, id):
		return false
	g.stones -= cost_stones(g, id)
	g.works[id] = int(g.day)
	g.toast("Built: %s" % str(WORKS[id].n))
	g.note("Built the %s (%s)" % [str(WORKS[id].n), str(SCHOOLS[WORKS[id].school].n)])
	g.poll_steps()
	return true

## The works that could be built now, in the order of the list.
static func buildable(g) -> Array:
	var out: Array = []
	for id in ORDER:
		if can_build(g, id):
			out.append(id)
	return out

# ---------------------------------------------------------------- what the works do
## A number the works multiply ("exp", "stones", "pill", "price", "temper", "recipe", "med", "hp",
## "cost", "taken", "heavy"): 1 with nothing built.  (No work shortens the waiting: what a rest or a
## road takes is the same for every maker.)
static func mod(g, key: String) -> float:
	var v := 1.0
	for id in g.works:
		var w: Dictionary = WORKS.get(id, {})
		if str(w.get("key", "")) == key and not key in ADDS:
			v *= float(w.v)
	return v

## A number the works add to ("ambush", "volley", "drop", "doze", "weak"): 0 with nothing built.
static func add(g, key: String) -> float:
	var v := 0.0
	for id in g.works:
		var w: Dictionary = WORKS.get(id, {})
		if str(w.get("key", "")) == key and key in ADDS:
			v += float(w.v)
	return v

## What a pill costs with the works that stand (Data.pill_price is the price without them).
static func pill_price(g, kind: String, level: int) -> int:
	return maxi(1, int(round(Data.pill_price(kind, level) * mod(g, "price"))))

## What the next tempering of the sword costs.
static func temper_cost(g) -> int:
	return int(round(int(Data.TEMPER_COST[mini(g.temper, Data.TEMPER_COST.size() - 1)]) * mod(g, "temper")))

## How many blows an obstacle of the story takes (never fewer than one).
static func blows(g, hits: int) -> int:
	return maxi(1, hits - (1 if has(g, "adze") else 0))

# ---------------------------------------------------------------- the page
## One line for the list: "[x] Well-Sweep", "[ ] Stone Adze  40 know-how", "    ?".
static func label(g, id: String) -> String:
	var w: Dictionary = WORKS[id]
	if has(g, id):
		return "[x] " + str(w.n)
	if not known(g, id):
		return "      (not yet known)"
	return "[ ] " + str(w.n)

## The text beside the list for work `id`.
static func text(g, id: String) -> String:
	var w: Dictionary = WORKS[id]
	if not known(g, id) and not has(g, id):
		return "Nobody in the land knows how to make this yet. The story will bring it."
	var parts: Array = [str(w.desc), "", str(w.does)]
	if has(g, id):
		parts.append("")
		parts.append("Built on day %d. It stands in %s: go and look at it." % [int(g.works[id]), str(Data.AREAS[w.site[0]].n)])
	else:
		parts.append("")
		parts.append("Costs %d know-how and %d spirit stones." % [cost_know(id), cost_stones(g, id)])
		var why := blocked(g, id)
		parts.append("Enter: build it." if why == "" else why)
	return "\n".join(parts)

## The ids of the machines that stand in the land for the story, whatever was built: Gongshu Ban's
## wheel at Qingshi, from the step in which he is met (Part XIX).
const STORY_SITES := {"ban_wheel": {"n": "Gongshu Ban's Water-Wheel", "site": ["village", Vector2i(14, 37)], "after": "s_p19_ban", "model": "water_wheel",
	"desc": "An undershot wheel twice the height of a man, turning in the mill-race with a sound like slow applause. It drives a shaft, and the shaft drives whatever Gongshu Ban hangs on it this week. Nobody is standing at it. It does not seem to mind."}}

## Every machine that can stand in the land: [entity id, key, region, tile].
static func sites() -> Array:
	var out: Array = []
	for id in ORDER:
		out.append(["work_" + id, id, str(WORKS[id].site[0]), WORKS[id].site[1]])
	for sid in STORY_SITES:
		out.append(["work_" + sid, sid, str(STORY_SITES[sid].site[0]), STORY_SITES[sid].site[1]])
	return out

## Whether the machine `key` stands in the land of game state `g`.
static func stands(g, key: String) -> bool:
	if STORY_SITES.has(key):
		return g.reached(str(STORY_SITES[key].after))
	return has(g, key)

static func site_name(key: String) -> String:
	return str(STORY_SITES[key].n) if STORY_SITES.has(key) else str(WORKS.get(key, {}).get("n", ""))

static func site_desc(key: String) -> String:
	if STORY_SITES.has(key):
		return str(STORY_SITES[key].desc)
	var w: Dictionary = WORKS.get(key, {})
	return "%s\n%s" % [str(w.get("desc", "")), str(w.get("does", ""))]
