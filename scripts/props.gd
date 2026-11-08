class_name Props
extends RefCounted
## Things to do in the world.  Every region has a few things of its own beside the road (a stone
## bench, a well, a wayside shrine, a temple bell, a qin on a stone table, a fishing spot, a swing,
## a wishing tree...), chosen by its theme, and every piece of furniture in a building can be used
## (pray at an altar, read at a bookshelf, sleep in a bed, stir a cauldron, work an anvil, weave at a
## loom...).  Facing one, Enter: Lin Feng walks up to it and does it, on clips of his own
## (art/lib/person.py INTERACT), with the thing in his hands where he needs one (a rod, a broom, a
## hammer, a ladle, a scroll, a dipper, a stone); the thing answers (the bell swings, the fire
## flares, the fish come up), Yue Ling joins in or watches, and something comes of it: rest, a drink,
## qi, a line of lore, a small find, a little cultivation.  The first time he does each kind of thing
## the world hears of it (renown +1: a pastime).
##
## Outdoor things stand on the forest edge or the shore beside open ground and furniture on the tiles
## it already filled: no tile anybody walks on is taken, so no road changes (and the bot, which never
## uses them, plays exactly the same game).

## what each thing is and what doing it means:
##   n      its name; verb: the hint ("Enter: ...")
##   clip   what Lin Feng does (a loop for `dur` seconds, or a one-shot); at: where he does it:
##          "face" (a step up to it), "seat" (on it, turned round to sit facing out, `off` metres
##          from its middle towards him), "before" (sitting in front of it facing it, `off` metres
##          out) or "on" (on its own tile: a cushion)
##   hold   what he holds while he does it; fx: how the thing answers
##   effect what comes of it; comp: what Yue Ling does meanwhile; lines: what is said of it
const KINDS := {
	# ---- outdoors (built here, see model())
	"bench": {"n": "Stone bench", "verb": "Sit and rest", "clip": "sit_bench", "dur": 5.0, "at": "seat", "off": 0.13, "effect": "rest", "comp": "sit_bench",
		"lines": ["Lin Feng sits and watches the road a while.", "The stone is warm from the sun. For a moment nothing needs doing.", "Yue Ling swings her feet and names the clouds."]},
	"well": {"n": "Well", "verb": "Draw water and drink", "clip": "drink", "dur": 2.6, "at": "face", "hold": "dipper", "fx": "splash", "effect": "drink", "comp": "watch",
		"lines": ["The water is cold enough to ache, and tastes of stone.", "Sweet water. Somebody dug this well a very long time ago and dug it well.", "He drinks, and the dipper goes back on its hook for the next traveller."]},
	"shrine": {"n": "Wayside shrine", "verb": "Light incense and pray", "clip": "pray", "dur": 4.5, "at": "face", "fx": "smoke", "effect": "qi", "comp": "pray",
		"lines": ["Three sticks of incense for the earth god of the road. The smoke goes straight up.", "Lin Feng asks nothing in particular, and feels heard anyway.", "Somebody has left a peach here. Lin Feng leaves another beside it."]},
	"bell": {"n": "Bronze bell", "verb": "Strike the bell", "clip": "strike", "dur": 2.4, "at": "face", "fx": "ring", "effect": "lore", "comp": "watch",
		"lines": ["BONG. The note goes out over the land and takes a long time to come back.", "The bell hums for a full minute. Birds lift off three hills away.", "Old Shen would approve: a clean strike, right on the lotus boss."]},
	"drum": {"n": "Great drum", "verb": "Beat the drum", "clip": "strike", "dur": 2.0, "at": "face", "fx": "boom", "effect": "lore", "comp": "laugh",
		"lines": ["DOOM. The drum answers like distant thunder.", "The beat rolls away down the valley like a stone.", "A drum like this once called armies. Today it calls nobody, and that is better."]},
	"qin": {"n": "Qin on a stone table", "verb": "Play the qin", "clip": "play_qin", "dur": 6.0, "at": "before", "off": 0.2, "fx": "notes", "effect": "qi", "comp": "meditate",
		"lines": ["Lin Feng plays Flowing Water, badly, and the stream plays it better beside him.", "A tune his mother hummed. He did not know he still remembered it.", "Yue Ling says it is the worst High Mountains she has ever heard, and asks for it again."]},
	"fishing": {"n": "Fishing spot", "verb": "Fish a while", "clip": "fish", "dur": 6.0, "at": "face", "hold": "rod", "fx": "ripple", "effect": "fish", "comp": "meditate",
		"lines": ["A tug: a silver carp, which he admires and puts back.", "Nothing bites. It is very peaceful not catching anything.", "A fat old fish rises, looks at the hook, and declines."]},
	"swing": {"n": "Swing", "verb": "Take a turn on the swing", "clip": "sit_bench", "dur": 5.0, "at": "seat", "off": -0.12, "fx": "swing", "effect": "rest", "comp": "laugh",
		"lines": ["Higher. Higher. A cultivator of his realm could fly, but this is better.", "The ropes creak like a ship, and the ground swoops away under his feet.", "Yue Ling pushes, and laughs when he yelps."]},
	"wish_tree": {"n": "Wishing tree", "verb": "Throw up a wish ribbon", "clip": "toss", "dur": 2.0, "at": "face", "fx": "ribbon", "effect": "luck", "comp": "pray",
		"lines": ["The red ribbon catches on a high branch: the wish will come true, they say.", "Lin Feng wishes for nothing much. The ribbon flies up anyway.", "Hundreds of ribbons, hundreds of wishes, all fluttering in the same wind."]},
	"stele": {"n": "Inscribed stele", "verb": "Read the inscription", "clip": "touch", "dur": 2.4, "at": "face", "fx": "glow", "effect": "lore", "comp": "watch",
		"lines": ["\"Whoever walks this road, walk it lightly.\" The rest is worn away.", "A list of names, and above them: \"They held the pass.\"", "An old poem about the moon. Somebody has corrected the rhyme in the margin."]},
	"herb_patch": {"n": "Spirit herbs", "verb": "Gather herbs", "clip": "gather", "dur": 2.8, "at": "face", "fx": "sparkle", "effect": "herb", "comp": "gather",
		"lines": ["A sprig of spirit grass, its dew still on it.", "He leaves the roots: they will grow back by the next moon.", "Yue Ling sniffs it and nods: good for the cauldron."]},
	"campfire": {"n": "Campfire", "verb": "Warm your hands", "clip": "warm", "dur": 4.5, "at": "face", "fx": "embers", "effect": "rest", "comp": "warm",
		"lines": ["The fire pops and settles. His fingers come back to life.", "Somebody left this fire laid and dry for the next traveller. He will do the same.", "Smoke and pine resin and the stars coming out."]},
	"stones": {"n": "Training stones", "verb": "Lift the stone lock", "clip": "lift", "dur": 3.0, "at": "face", "hold": "stone_lock", "fx": "dust", "effect": "train", "comp": "laugh",
		"lines": ["The stone lock goes up and stays up. Three years ago it would not have moved.", "He presses it overhead ten times and only the last one shakes.", "The disciples who train here have worn the grips smooth."]},
	"broom": {"n": "Broom and fallen leaves", "verb": "Sweep the leaves", "clip": "sweep", "dur": 5.0, "at": "face", "hold": "broom", "fx": "leaves", "effect": "qi", "comp": "laugh",
		"lines": ["Three years he swept the sect's steps. His hands still know how.", "Sweep, sweep. The mind goes quiet, and the leaves go into a neat heap.", "Yue Ling says he sweeps better than he fights. He takes it as a compliment."]},
	"weiqi": {"n": "Weiqi board", "verb": "Study the game left here", "clip": "sit_bench", "dur": 5.0, "at": "before", "off": 0.42, "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Black is winning, but White has a ladder nobody has seen. He leaves it for them.", "A game left half finished. He resists the urge to play a stone.", "Somebody is very good at this, and somebody else is very stubborn."]},
	"tea": {"n": "Tea table", "verb": "Pour a cup of tea", "clip": "drink", "dur": 2.6, "at": "face", "hold": "cup", "fx": "steam", "effect": "rest", "comp": "drink",
		"lines": ["Mountain tea, a little bitter, and good.", "The pot is still warm. Somebody expects company.", "He pours a cup for Yue Ling first, as one should."]},
	"lion": {"n": "Stone lion", "verb": "Rub the lion's head for luck", "clip": "touch", "dur": 2.4, "at": "face", "fx": "glow", "effect": "luck", "comp": "laugh",
		"lines": ["The lion's head is worn bright by a thousand hands.", "A coin in the lion's mouth: somebody's thanks. He leaves it there.", "The lion looks unimpressed. Stone lions always do."]},
	"chimes": {"n": "Wind chimes", "verb": "Set the chimes ringing", "clip": "touch", "dur": 2.4, "at": "face", "fx": "chime", "effect": "qi", "comp": "watch",
		"lines": ["Bronze voices, one after another, then the wind takes them.", "The chimes ring, and something in his qi rings with them.", "Ting, ting, ting. Yue Ling hums the note."]},
	"lantern_st": {"n": "Stone lantern", "verb": "Light the lantern", "clip": "touch", "dur": 2.4, "at": "face", "fx": "light", "effect": "lore", "comp": "watch",
		"lines": ["The lamp takes the flame and the road is a little less dark.", "A moth arrives at once, as if it had been waiting.", "Somebody keeps this lantern trimmed. He trims it too."]},
	"koi": {"n": "Fish pond", "verb": "Feed the fish", "clip": "toss", "dur": 2.0, "at": "face", "fx": "koi", "effect": "qi", "comp": "laugh",
		"lines": ["The crumbs land and the water boils with orange and gold.", "One old carp, very large and very slow, gets nothing and does not mind.", "The fish follow him along the bank, hoping."]},
	# ---- furniture (the building draws it; see Architecture._furnish)
	"altar": {"n": "Altar", "verb": "Pray at the altar", "clip": "pray", "dur": 4.5, "at": "face", "fx": "smoke", "effect": "qi", "comp": "pray",
		"lines": ["Incense for the ancestors of the house. The smoke bends towards him and away.", "He bows three times and the candle flames bow back.", "A quiet room, and a quieter heart."]},
	"statue": {"n": "Statue", "verb": "Bow to the founder", "clip": "bow", "dur": 2.0, "at": "face", "fx": "glow", "effect": "lore", "comp": "bow",
		"lines": ["The founder's bronze face is calm. It has seen worse days than this.", "A respectful bow. The statue, for once, seems to approve.", "Somebody keeps the statue polished, all but the nose, which is polished by luck-seekers."]},
	"cushion": {"n": "Meditation cushion", "verb": "Sit and meditate", "clip": "meditate", "dur": 6.0, "at": "on", "fx": "qi", "effect": "qi", "comp": "watch",
		"lines": ["Breathe in for four, out for six. The qi settles like silt in a pool.", "His root hums in the stillness.", "Yue Ling sits a little way off and is quiet for once."]},
	"scroll": {"n": "Calligraphy", "verb": "Look at the calligraphy", "clip": "think", "dur": 2.4, "at": "face", "fx": "", "effect": "lore", "comp": "think",
		"lines": ["\"Water is soft and wins.\" The last stroke runs off the paper.", "One character, written in one breath: Dao.", "The brushwork is wild. The poem is about patience."]},
	"bookshelf": {"n": "Bookshelf", "verb": "Read a while", "clip": "read", "dur": 5.0, "at": "face", "hold": "book", "fx": "", "effect": "lore", "comp": "read",
		"lines": ["A treatise on the five phases with somebody's arguments in the margins.", "A book of ghost stories. He reads one too many.", "An old almanac: the auspicious days are all in the past."]},
	"shelf": {"n": "Shelf", "verb": "Look over the shelf", "clip": "touch", "dur": 2.2, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Jars of pickles, salt, dried mushrooms, and a jar labelled DO NOT.", "Everything here has been mended at least once.", "A child's carved horse, put up high out of reach."]},
	"table": {"n": "Table", "verb": "Pour a cup of tea", "clip": "drink", "dur": 2.6, "at": "face", "hold": "cup", "fx": "steam", "effect": "rest", "comp": "drink",
		"lines": ["Tea in a chipped cup, and very welcome.", "The table has a ring for every cup ever set on it.", "Sit, rest, drink: the oldest courtesy."]},
	"desk": {"n": "Writing desk", "verb": "Read the papers", "clip": "read", "dur": 4.5, "at": "face", "hold": "book", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Accounts, letters, a poem crossed out three times.", "Somebody practises the character for 'eternity' here, over and over.", "Ink still wet. Whoever writes here has just stepped out."]},
	"counter": {"n": "Counter", "verb": "Knock for service", "clip": "touch", "dur": 2.0, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Knock knock. \"Coming!\" says somebody, and doesn't.", "The counter is worn into a dip where a thousand elbows have leaned.", "A cat asleep on the ledger raises one eyelid."]},
	"stool": {"n": "Stool", "verb": "Sit a moment", "clip": "sit_bench", "dur": 4.0, "at": "seat", "off": 0.0, "fx": "", "effect": "rest", "comp": "watch",
		"lines": ["A moment off his feet.", "The stool wobbles. He finds the one way it doesn't.", "Sitting, he notices the room properly for the first time."]},
	"cauldron": {"n": "Cauldron", "verb": "Stir the cauldron", "clip": "stir", "dur": 4.5, "at": "face", "hold": "ladle", "fx": "steam", "effect": "qi", "comp": "watch",
		"lines": ["Clockwise nine times, counter-clockwise nine. The brew turns gold.", "It smells of ginseng and something better not asked about.", "Yue Ling corrects his stirring. He was doing it fine."]},
	"herbs": {"n": "Drying herbs", "verb": "Sort the herbs", "clip": "gather", "dur": 2.8, "at": "face", "fx": "sparkle", "effect": "herb", "comp": "gather",
		"lines": ["Mugwort, angelica, a sprig of something that glows faintly.", "The good leaves in one basket, the bitter in another.", "Yue Ling tells him the names. He forgets half of them at once."]},
	"hearth": {"n": "Hearth", "verb": "Warm your hands", "clip": "warm", "dur": 4.5, "at": "face", "fx": "embers", "effect": "rest", "comp": "warm",
		"lines": ["The embers glow up as if they were glad of him.", "A hearth is a house's heart. This one beats slow and warm.", "He feeds it a log. It thanks him in sparks."]},
	"stove": {"n": "Stove", "verb": "Cook something", "clip": "stir", "dur": 4.5, "at": "face", "hold": "ladle", "fx": "steam", "effect": "drink", "comp": "watch",
		"lines": ["Congee with ginger: the best medicine in the world.", "He burns the first batch and eats the second.", "Yue Ling says it needs salt. It always needs salt."]},
	"anvil": {"n": "Anvil", "verb": "Work the anvil", "clip": "hammer", "dur": 4.0, "at": "face", "hold": "hammer", "fx": "sparks", "effect": "train", "comp": "watch",
		"lines": ["Clang, clang, clang. The iron turns from red to orange to a hoe.", "Hammer, turn, hammer: Smith Tie would only wince a little.", "The rhythm gets into his arms and he finds he cannot stop."]},
	"rack": {"n": "Weapon rack", "verb": "Practise a form", "clip": "attack", "dur": 1.6, "at": "face", "fx": "", "effect": "train", "comp": "watch",
		"lines": ["A spear form, borrowed from the rack: thrust, sweep, guard.", "He puts the halberd back. Swords suit him better.", "The practice sword is heavy and blunt and honest."]},
	"barrel": {"n": "Barrel", "verb": "Have a taste", "clip": "drink", "dur": 2.6, "at": "face", "hold": "dipper", "fx": "", "effect": "drink", "comp": "laugh",
		"lines": ["Rice wine, young and fierce. He coughs.", "Plum wine! Somebody's private store, by the dust on the lid.", "Water, cool and sweet. Rather a disappointment."]},
	"bed": {"n": "Bed", "verb": "Rest a while", "clip": "doze", "dur": 6.0, "at": "seat", "off": 0.5, "fx": "zzz", "effect": "sleep", "comp": "watch",
		"lines": ["He means to rest his eyes a moment. He wakes an hour later, much better.", "A real bed, after so many nights on the road.", "Yue Ling lets him sleep, and keeps watch."]},
	"cabinet": {"n": "Cabinet", "verb": "Look in the cabinet", "clip": "touch", "dur": 2.2, "at": "face", "fx": "", "effect": "find", "comp": "watch",
		"lines": ["Bolts of silk, folded with care.", "A box of letters tied with red string. He puts it back unread.", "Somebody's winter clothes, smelling of camphor."]},
	"loom": {"n": "Loom", "verb": "Weave a few rows", "clip": "weave", "dur": 5.0, "at": "before", "off": 0.78, "fx": "", "effect": "qi", "comp": "watch",
		"lines": ["Shuttle, beater, treadle. The pattern grows by a finger's width.", "He weaves a mistake into it. The weaver will find it and laugh.", "The Weaver of the Star River would weave faster. Not much better."]},
	"lantern": {"n": "Lantern", "verb": "Trim the lantern", "clip": "touch", "dur": 2.0, "at": "face", "fx": "light", "effect": "lore", "comp": "watch",
		"lines": ["The wick trimmed, the flame stands up straight.", "Paper and bamboo and a little light: enough.", "A moth leaves in a huff."]},
	"nest": {"n": "Nest", "verb": "Look into the nest", "clip": "touch", "dur": 2.2, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Woven of cloud-silk and feathers, and still warm.", "A Feathered Folk nest, swept clean and waiting.", "Three blue feathers left as a gift. He leaves them."]},
}

## The furniture the game makes usable: the kind of thing it is (KINDS) by the kind of furniture
## (MapGen building props).  The pieces that fill a tile are used from beside them; the rest (on a
## floor anyone walks over: a cushion, a stool, a hanging scroll, a lantern, drying herbs, a statue)
## are used by facing them and never stand in anyone's way.
const FURNITURE := {"altar": "altar", "statue": "statue", "cushion": "cushion", "scroll": "scroll", "bookshelf": "bookshelf", "shelf": "shelf",
	"table": "table", "desk": "desk", "counter": "counter", "stool": "stool", "cauldron": "cauldron", "herbs": "herbs", "hearth": "hearth",
	"stove": "stove", "anvil": "anvil", "rack": "rack", "barrel": "barrel", "bed": "bed", "cabinet": "cabinet", "loom": "loom",
	"lantern": "lantern", "nest": "nest"}

## The outdoor things to look for in a region by its theme (the first found a place get one); where
## a theme is not listed, the region takes the common list turned round by its own name.
const COMMON := ["bench", "shrine", "well", "herb_patch", "stele", "wish_tree", "campfire", "lantern_st", "chimes", "tea", "qin", "swing", "fishing", "koi", "lion", "weiqi", "bell", "drum", "stones", "broom"]
const THEMES := {
	"sect": ["bell", "broom", "stones", "qin", "weiqi", "lantern_st", "koi", "bench"],
	"mountain": ["shrine", "bench", "well", "herb_patch", "campfire", "stele"],
	"bamboo": ["qin", "tea", "chimes", "bench", "fishing", "herb_patch"],
	"marsh": ["fishing", "koi", "herb_patch", "shrine", "campfire", "bench"],
	"frost": ["campfire", "shrine", "fishing", "stele", "stones", "bench"],
	"thunder": ["drum", "stele", "shrine", "campfire", "stones", "bench"],
	"palace": ["lion", "lantern_st", "bell", "weiqi", "koi", "bench"],
	"garden": ["koi", "swing", "tea", "wish_tree", "qin", "bench"],
	"village": ["well", "swing", "wish_tree", "bench", "broom", "fishing", "lion"],
	"grave": ["shrine", "lantern_st", "stele", "bell", "chimes", "bench"],
	"forge": ["stones", "campfire", "well", "drum", "bench", "stele"],
	"maple": ["broom", "tea", "qin", "shrine", "bench", "fishing"],
	"terraces": ["tea", "well", "bench", "shrine", "herb_patch", "swing"],
	"springs": ["well", "fishing", "tea", "bench", "shrine", "koi"],
	"silk": ["swing", "tea", "chimes", "wish_tree", "bench", "well"],
	"millet": ["well", "broom", "bench", "shrine", "campfire", "swing"],
	# the realms past the first
	"volcano": ["stones", "stele", "shrine", "drum", "campfire", "bench"],
	"abyss": ["stele", "shrine", "bell", "lantern_st", "stones", "bench"],
	"void": ["stele", "shrine", "lantern_st", "chimes", "weiqi", "bench"],
	"celestial": ["bell", "lion", "lantern_st", "weiqi", "qin", "chimes"],
	"mirror": ["koi", "fishing", "qin", "tea", "chimes", "bench"],
	"time": ["stele", "bell", "weiqi", "shrine", "lantern_st", "bench"],
	"origin": ["stele", "shrine", "herb_patch", "wish_tree", "well", "bench"],
	"cloudsea": ["chimes", "qin", "tea", "lantern_st", "shrine", "bench"],
	"court": ["lion", "lantern_st", "bell", "weiqi", "drum", "bench"],
	"dunes": ["well", "campfire", "shrine", "stele", "stones", "bench"],
	"fungal": ["herb_patch", "campfire", "lantern_st", "shrine", "stele", "bench"],
	"aurora": ["campfire", "chimes", "shrine", "stele", "fishing", "bench"],
	"chaos": ["stele", "shrine", "stones", "drum", "campfire", "bench"],
	"karst": ["fishing", "tea", "qin", "herb_patch", "shrine", "bench"],
	"wheel": ["lantern_st", "bell", "shrine", "stele", "drum", "chimes"],
	"loom": ["chimes", "swing", "tea", "wish_tree", "well", "bench"],
	"starferry": ["lantern_st", "fishing", "wish_tree", "chimes", "shrine", "bench"],
	"magpie": ["wish_tree", "lantern_st", "chimes", "swing", "koi", "bench"],
	"starpalace": ["lantern_st", "bell", "lion", "weiqi", "chimes", "bench"],
	"jasper": ["koi", "tea", "qin", "lion", "chimes", "bench"],
	"yanggu": ["campfire", "drum", "shrine", "stele", "well", "bench"],
	"fusang": ["wish_tree", "shrine", "drum", "campfire", "stele", "bench"],
	"guanghan": ["lantern_st", "qin", "chimes", "wish_tree", "tea", "bench"],
	"longmen": ["fishing", "koi", "stele", "drum", "shrine", "bench"],
	"drowned": ["shrine", "stele", "lantern_st", "bell", "fishing", "bench"],
	"tushan": ["wish_tree", "lantern_st", "tea", "swing", "shrine", "bench"],
	"buzhou": ["stele", "shrine", "stones", "campfire", "drum", "bench"],
	"juntian": ["bell", "drum", "qin", "chimes", "lion", "bench"],
	"changhe": ["lion", "bell", "lantern_st", "drum", "stele", "bench"],
	"ninesprings": ["lantern_st", "well", "shrine", "stele", "chimes", "bench"],
	"youdu": ["lantern_st", "bell", "shrine", "stele", "drum", "lion"],
	"penglai": ["tea", "qin", "koi", "fishing", "herb_patch", "bench"],
	"fangzhang": ["herb_patch", "tea", "qin", "shrine", "fishing", "bench"],
	"yingzhou": ["koi", "fishing", "tea", "chimes", "herb_patch", "bench"],
	"guixu": ["stele", "shrine", "bell", "lantern_st", "fishing", "bench"],
}
## outdoor things that stand in the water by the bank; the rest stand on the forest edge
const WATER_KINDS := ["fishing", "koi"]
## how many outdoor things a region has
const PER_REGION := 6

## the clips played once (the rest loop for as long as the thing takes)
const ONCE := ["drink", "strike", "gather", "lift", "toss", "touch", "bow", "think", "attack", "offer"]
## what the hero holds for a clip that needs something in his hand (built in held())
const HELD := ["dipper", "cup", "rod", "broom", "hammer", "ladle", "book", "stone_lock"]
## the effects (use())
const EFFECTS := ["rest", "drink", "qi", "lore", "fish", "luck", "herb", "train", "find", "sleep"]
## how the things answer while used (drawn by World._prop_fx; the swing's is the swing going)
const FX := ["splash", "smoke", "ring", "boom", "notes", "ripple", "ribbon", "glow", "sparkle", "sparks", "embers", "dust",
	"leaves", "steam", "chime", "light", "koi", "qi", "zzz", "swing"]

static func kind_of(e: Dictionary) -> Dictionary:
	return KINDS.get(str(e.get("prop", "")), {})

## A line of what is said about doing it: a different one each time.
static func line_for(e: Dictionary, n: int) -> String:
	var lines: Array = kind_of(e).get("lines", [])
	if lines.is_empty():
		return ""
	return str(lines[(n + absi(hash(str(e.id)))) % lines.size()])

# ---------------------------------------------------------------- placement

## The kinds a region looks for, in order.
static func wanted(area: String) -> Array:
	var th: String = str(Data.AREAS[area].get("theme", area))
	if THEMES.has(area):
		return THEMES[area]
	if THEMES.has(th):
		return THEMES[th]
	var k := absi(hash(area)) % COMMON.size()
	return COMMON.slice(k) + COMMON.slice(0, k)

static func _walkable(t: int) -> bool:
	return t == MapGen.FLOOR or t == MapGen.PATH or t == MapGen.DECOR

## The outdoor things of a realm (Atlas._build, once its ground is final): for each region the kinds
## its theme asks for, each on a forest-edge (or, by the water, a shore) tile of its own land whose
## neighbour is open ground near a road, away from everybody and everything else.  Returns the
## entities ({"kind": "prop", "prop": kind, "pos", "face": the open side, "area", "layer"}).
static func place(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, sea: PackedByteArray, ids: Array, ents: Array, layer: String) -> Array:
	var taken := {}
	for e in ents:
		var ep: Vector2i = e.pos
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				taken[ep + Vector2i(dx, dy)] = true
		for tt in e.get("tiles", []):
			taken[tt] = true
	# distance (in steps, up to 3) from the nearest road
	var road := PackedByteArray()
	road.resize(W * H)
	road.fill(255)
	var q: Array = []
	for i in W * H:
		if grid[i] == MapGen.PATH:
			road[i] = 0
			q.append(i)
	var head := 0
	while head < q.size():
		var c: int = q[head]
		head += 1
		if road[c] >= 3:
			continue
		var cx := c % W
		var cy := c / W
		for d in MapGen.DIRS:
			var nx: int = cx + d.x
			var ny: int = cy + d.y
			if nx < 0 or ny < 0 or nx >= W or ny >= H:
				continue
			var ni := ny * W + nx
			if road[ni] == 255 and _walkable(grid[ni]):
				road[ni] = road[c] + 1
				q.append(ni)
	# candidate tiles by region: [hash, tile, the open side, water?]; the loose ones (a corner of the
	# forest, a little further from the road) only for a region with too few of the others
	var cands := {}
	var loose := {}
	for k in ids.size():
		cands[k] = []
		loose[k] = []
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var i := y * W + x
			var t := grid[i]
			if (t != MapGen.WALL and t != MapGen.WATER) or sea.size() > 0 and sea[i] == 1 or taken.has(Vector2i(x, y)):
				continue
			var o: int = owner[i]
			if not cands.has(o):
				continue
			for d in MapGen.DIRS:
				var nx2: int = x + d.x
				var ny2: int = y + d.y
				var ni2 := ny2 * W + nx2
				if _walkable(grid[ni2]) and owner[ni2] == o and road[ni2] <= 3:
					var c0 := [absi(hash(Vector3i(x, y, 7))) % 100003, Vector2i(x, y), d, t == MapGen.WATER]
					# a thing in a corner of the forest would be hidden: the tile across should be closed
					var bx: int = x - d.x
					var by: int = y - d.y
					if (t == MapGen.WALL and _walkable(grid[by * W + bx])) or road[ni2] > 2:
						loose[o].append(c0)
					else:
						cands[o].append(c0)
					break
	var out: Array = []
	for k in ids.size():
		var area: String = ids[k]
		var list: Array = cands[k]
		list.sort_custom(func(a, b): return a[0] < b[0])
		var more: Array = loose[k]
		more.sort_custom(func(a, b): return a[0] < b[0])
		if list.size() < PER_REGION * 3:
			list.append_array(more)
		var used := {}
		var placed: Array = []
		for kind in wanted(area):
			if placed.size() >= PER_REGION:
				break
			var water: bool = WATER_KINDS.has(kind)
			for c2 in list:
				var tile: Vector2i = c2[1]
				if bool(c2[3]) != water or used.has(tile):
					continue
				var near := false
				for p in placed:
					if (p as Vector2i).distance_squared_to(tile) < 64:
						near = true
						break
				if near:
					continue
				placed.append(tile)
				used[tile] = true
				out.append({"kind": "prop", "id": "prop:%s:%d" % [area, placed.size()], "prop": kind, "pos": tile, "face": c2[2], "area": area, "layer": layer})
				break
	return out

## The furniture of a realm's buildings (or of one floor) as things to use: [kind, tile, blocks] from
## the building's props, in the realm's (or the floor's) own tiles of `grid` (`w` wide).
static func furniture(props: Array, area: String, layer: String, prefix: String, grid: PackedByteArray, w: int) -> Array:
	var out: Array = []
	for k in props.size():
		var pr: Array = props[k]
		var fk := str(pr[0])
		if not FURNITURE.has(fk):
			continue
		var tile: Vector2i = pr[1]
		var e := {"kind": "prop", "id": "%s:%d" % [prefix, k], "prop": FURNITURE[fk], "pos": tile, "area": area, "layer": layer, "furn": fk}
		if MapGen.is_walkable_tile(grid[tile.y * w + tile.x]):
			# on floor anyone walks over (a cushion, a stool): used by facing it, and never in the way
			# of anyone walking (or of the bot)
			e["walk"] = true
		out.append(e)
	return out

# ---------------------------------------------------------------- what comes of it

## Do it: what comes of using `e` now (Game's state changes here), as the lines to show.
static func use(e: Dictionary, g) -> Array:
	var k := kind_of(e)
	var pid := str(e.id)
	var n: int = int(g.prop_uses.get(pid, 0))
	g.prop_uses[pid] = n + 1
	var out: Array = [line_for(e, n)]
	match str(k.get("effect", "")):
		"rest":
			out.append(_restore(g, 0.25, 0.25, "Rested"))
		"drink":
			out.append(_restore(g, 0.3, 0.0, "Refreshed"))
		"qi":
			out.append(_restore(g, 0.0, 0.35, "Calmed"))
		"sleep":
			g.heal_full()
			out.append("Slept: health and qi restored")
		"fish":
			out.append(_restore(g, 0.15, 0.2, "A quiet hour"))
		"herb":
			if _ready(g, pid, 600.0):
				g.add_item("ess_wood")
				out.append("Gathered a Wood Essence")
		"train":
			if _ready(g, pid, 600.0) and not g.at_cap():
				var gain := maxi(1, int(g.exp_need() * 0.03))
				g.exp = minf(g.exp + gain, float(g.exp_need()))
				out.append("Cultivation +%d" % gain)
		"luck", "find":
			if not g.prop_found.has(pid):
				g.prop_found[pid] = true
				var st := 5 + absi(hash(pid)) % 26
				g.stones += st
				out.append("Found %d spirit stones" % st)
	# the first time Lin Feng does each kind of thing, the world hears of it
	var kind := str(e.prop)
	if not g.pastimes.has(kind):
		g.pastimes[kind] = true
		g.add_renown(1)
		out.append("A new pastime: %s (%d of %d)" % [str(k.get("verb", kind)).to_lower(), g.pastimes.size(), KINDS.size()])
	return out.filter(func(s): return str(s) != "")

static func _ready(g, pid: String, cool: float) -> bool:
	var last: float = float(g.prop_t.get(pid, -1e9))
	if g.playtime - last < cool:
		return false
	g.prop_t[pid] = g.playtime
	return true

static func _restore(g, hp_k: float, qi_k: float, what: String) -> String:
	var any := false
	for i in g.party_size():
		var h0: float = g.hp[i]
		var q0: float = g.qi[i]
		g.hp[i] = minf(float(g.max_hp(i)), h0 + g.max_hp(i) * hp_k)
		g.qi[i] = minf(float(g.max_qi(i)), q0 + g.max_qi(i) * qi_k)
		any = any or g.hp[i] > h0 + 0.5 or g.qi[i] > q0 + 0.5
	if not any:
		return ""
	if hp_k > 0.0 and qi_k > 0.0:
		return "%s: health and qi restored a little" % what
	return "%s: %s restored a little" % [what, "health" if hp_k > 0.0 else "qi"]

# ---------------------------------------------------------------- models

const WOOD := Color("6a4a30")
const WOOD_L := Color("a87a4a")
const STONE := Color("b0a898")
const STONE_D := Color("7a7468")
const RED := Color("b8382a")
const TILE := Color("2f4a6a")
const BRONZE := Color("8a7038")

## An outdoor thing, standing at the origin of its tile with its front (where it is used from)
## towards +z.  Parts that move are kept as named children: "swing" (the bell, the drum skin, the
## swing seat, the chimes), "flame", "water".
static func model(kind: String, theme: String) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	var mv := MB.new()
	var mv_at := Vector3.ZERO
	match kind:
		"bench":
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 0.6, 0.2, 0.05), Vector3(0.22, 0.4, 0.4), MB.tag(STONE_D, MB.STONE))
			b.box(Vector3(0, 0.45, 0.05), Vector3(1.7, 0.12, 0.5), MB.tag(STONE, MB.STONE))
			b.box(Vector3(0, 0.39, 0.05), Vector3(1.62, 0.04, 0.44), MB.tag(STONE_D, MB.STONE))
		"well":
			b.lathe(Vector3.ZERO, [Vector2(0.95, 0.0), Vector2(0.95, 0.7), Vector2(0.78, 0.75), Vector2(0.78, 0.05)], MB.tag(STONE, MB.STONE), 16)
			g.disc(Vector3(0, 0.45, 0), 0.74, Color(0.25, 0.45, 0.6, 0.5), 16)
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 0.85, 1.25, 0), Vector3(0.12, 1.2, 0.12), MB.tag(WOOD, MB.WOOD))
			b.limb(Vector3(-0.9, 1.55, 0), Vector3(0.9, 1.55, 0), 0.07, 0.07, MB.tag(WOOD_L, MB.WOOD), 8)
			b.box(Vector3(0, 1.95, 0), Vector3(2.2, 0.08, 1.1), MB.tag(TILE, MB.STONE), Vector3(0, 0, 0))
			b.box(Vector3(0, 2.05, 0), Vector3(1.6, 0.1, 0.6), MB.tag(TILE.darkened(0.2), MB.STONE))
			b.limb(Vector3(0.2, 1.55, 0.05), Vector3(0.2, 1.0, 0.05), 0.01, 0.01, MB.tag(Color("c8b080"), MB.CLOTH), 4)
			mv.lathe(Vector3.ZERO, [Vector2(0.14, 0.0), Vector2(0.17, 0.22), Vector2(0.16, 0.24)], MB.tag(WOOD_L, MB.WOOD), 10)
			mv_at = Vector3(0.2, 0.8, 0.05)
		"shrine":
			b.box(Vector3(0, 0.35, -0.2), Vector3(1.0, 0.7, 0.8), MB.tag(STONE_D, MB.STONE))
			b.box(Vector3(0, 0.95, -0.2), Vector3(0.8, 0.5, 0.6), MB.tag(STONE, MB.STONE))
			b.box(Vector3(0, 0.95, 0.08), Vector3(0.4, 0.38, 0.06), MB.tag(Color("2a2420"), MB.STONE))
			b.sph(Vector3(0, 0.92, 0.0), Vector3(0.12, 0.16, 0.1), MB.tag(Color("d8c070"), MB.METAL))
			b.box(Vector3(0, 1.28, -0.2), Vector3(1.2, 0.12, 0.95), MB.tag(TILE, MB.STONE))
			b.cone(Vector3(0, 1.45, -0.2), 0.75, 0.32, MB.tag(TILE.darkened(0.15), MB.STONE), Vector3(0, PI / 4, 0), 4)
			b.lathe(Vector3(0, 0.0, 0.55), [Vector2(0.16, 0.0), Vector2(0.2, 0.18), Vector2(0.17, 0.28), Vector2(0.21, 0.3)], MB.tag(BRONZE, MB.METAL), 12)
			for k in 3:
				b.limb(Vector3(-0.05 + k * 0.05, 0.3, 0.55), Vector3(-0.05 + k * 0.05, 0.55, 0.55), 0.006, 0.006, MB.tag(Color("c84a2a"), MB.WOOD), 3)
				g.sph_hi(Vector3(-0.05 + k * 0.05, 0.56, 0.55), Vector3.ONE * 0.02, Color(1.0, 0.55, 0.25, 0.95))
			b.sph(Vector3(0.3, 0.74, 0.15), Vector3(0.07, 0.07, 0.07), MB.tag(Color("f0a070"), MB.CLOTH))
		"bell":
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 1.0, 1.4, -0.2), Vector3(0.2, 2.8, 0.2), MB.tag(RED, MB.WOOD))
			b.box(Vector3(0, 2.85, -0.2), Vector3(2.5, 0.2, 0.3), MB.tag(RED, MB.WOOD))
			b.box(Vector3(0, 3.05, -0.2), Vector3(2.8, 0.12, 0.6), MB.tag(TILE, MB.STONE))
			mv.lathe(Vector3(0, -1.5, 0), [Vector2(0.62, 0.0), Vector2(0.55, 0.15), Vector2(0.5, 0.9), Vector2(0.42, 1.3), Vector2(0.15, 1.45), Vector2(0.05, 1.55)], MB.tag(BRONZE.lerp(Color("4a8a6a"), 0.25), MB.METAL), 20)
			mv.box(Vector3(0, -0.3, 0), Vector3(0.08, 0.6, 0.08), MB.tag(WOOD, MB.WOOD))
			for r in 3:
				mv.torus(Vector3(0, -1.3 + r * 0.35, 0), 0.6 - r * 0.04, 0.02, MB.tag(BRONZE.darkened(0.2), MB.METAL), Vector3.ZERO)
			mv_at = Vector3(0, 2.75, -0.2)
			# the striker: a log hung on two ropes before the bell
			b.limb(Vector3(-0.5, 1.5, 0.75), Vector3(0.5, 1.5, 0.75), 0.11, 0.11, MB.tag(WOOD_L, MB.WOOD), 8)
			for s2: float in [-1.0, 1.0]:
				b.limb(Vector3(s2 * 0.4, 1.5, 0.75), Vector3(s2 * 0.4, 2.85, 0.0), 0.012, 0.012, MB.tag(Color("c8b080"), MB.CLOTH), 4)
		"drum":
			for s: float in [-1.0, 1.0]:
				b.limb(Vector3(s * 0.75, 0.0, -0.1), Vector3(s * 0.55, 1.1, -0.1), 0.06, 0.06, MB.tag(RED, MB.WOOD), 6)
			mv.cyl(Vector3.ZERO, 0.75, 0.6, MB.tag(RED, MB.WOOD), Vector3(PI * 0.5, 0, 0), 20)
			mv.cyl(Vector3(0, 0, 0.31), 0.7, 0.02, MB.tag(Color("e8d8b0"), MB.CLOTH), Vector3(PI * 0.5, 0, 0), 20)
			mv.cyl(Vector3(0, 0, -0.31), 0.7, 0.02, MB.tag(Color("e8d8b0"), MB.CLOTH), Vector3(PI * 0.5, 0, 0), 20)
			for k in 12:
				var a := TAU * k / 12.0
				mv.ball(Vector3(cos(a) * 0.74, sin(a) * 0.74, 0.3), 0.03, MB.tag(Color("d8b050"), MB.METAL))
			mv_at = Vector3(0, 1.1, -0.1)
			b.limb(Vector3(0.35, 0.95, 0.5), Vector3(0.6, 0.6, 0.65), 0.03, 0.03, MB.tag(WOOD_L, MB.WOOD), 5)
		"qin":
			b.box(Vector3(0, 0.25, -0.35), Vector3(1.5, 0.08, 0.6), MB.tag(STONE, MB.STONE))
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 0.6, 0.11, -0.35), Vector3(0.2, 0.22, 0.45), MB.tag(STONE_D, MB.STONE))
			b.box(Vector3(0, 0.33, -0.35), Vector3(1.2, 0.07, 0.2), MB.tag(Color("3a2218"), MB.WOOD))
			for k in 7:
				b.box(Vector3(0, 0.37, -0.42 + k * 0.024), Vector3(1.15, 0.006, 0.006), MB.tag(Color("e8dcc0"), MB.CLOTH))
			b.sph(Vector3(0, 0.06, 0.2), Vector3(0.4, 0.08, 0.35), MB.tag(Color("c8a040"), MB.CLOTH))
		"fishing":
			# in the water: a little wooden jetty's end, reeds and a float
			for s: float in [-1.0, 1.0]:
				b.cyl(Vector3(s * 0.5, -0.15, 0.6), 0.07, 0.8, MB.tag(WOOD, MB.WOOD), Vector3.ZERO, 6)
			b.box(Vector3(0, 0.25, 0.75), Vector3(1.3, 0.08, 0.9), MB.tag(WOOD_L, MB.WOOD))
			for k in 9:
				var a2 := k * 0.9
				b.limb(Vector3(-0.8 + cos(a2) * 0.25, -0.3, -0.4 + sin(a2) * 0.25), Vector3(-0.85 + cos(a2) * 0.32, 0.9 + (k % 3) * 0.15, -0.45 + sin(a2) * 0.3), 0.02, 0.008, MB.tag(Color("7a9a4a"), MB.FOLIAGE), 3)
			mv.ball(Vector3.ZERO, 0.05, MB.tag(Color("e04040"), MB.CLOTH))
			mv.ball(Vector3(0, -0.05, 0), 0.04, MB.tag(Color("f0f0f0"), MB.CLOTH))
			mv_at = Vector3(0.2, Terrain3D.WATER_Y + 0.02, -0.6)
		"swing":
			for s: float in [-1.0, 1.0]:
				b.limb(Vector3(s * 1.0, 0.0, -0.2), Vector3(s * 0.85, 2.6, -0.2), 0.08, 0.07, MB.tag(WOOD, MB.WOOD), 6)
			b.limb(Vector3(-1.1, 2.6, -0.2), Vector3(1.1, 2.6, -0.2), 0.08, 0.08, MB.tag(WOOD, MB.WOOD), 6)
			for s2: float in [-1.0, 1.0]:
				mv.limb(Vector3(s2 * 0.35, 0.0, 0), Vector3(s2 * 0.35, -2.1, 0), 0.012, 0.012, MB.tag(Color("c8b080"), MB.CLOTH), 4)
			mv.box(Vector3(0, -2.12, 0), Vector3(0.85, 0.05, 0.3), MB.tag(WOOD_L, MB.WOOD))
			mv_at = Vector3(0, 2.6, -0.2)
		"wish_tree":
			b.limb(Vector3(0, 0, -0.4), Vector3(0.1, 2.2, -0.4), 0.32, 0.22, MB.tag(Color("5a4030"), MB.WOOD), 8)
			var rng := RandomNumberGenerator.new()
			rng.seed = 404
			for k in 6:
				var a3 := TAU * k / 6.0 + 0.3
				var tip := Vector3(cos(a3) * 1.4, 2.6 + rng.randf() * 0.6, sin(a3) * 1.4 - 0.4)
				b.limb(Vector3(0.1, 2.0, -0.4), tip, 0.14, 0.05, MB.tag(Color("5a4030"), MB.WOOD), 6)
				b.sph(tip + Vector3(0, 0.3, 0), Vector3(0.9, 0.55, 0.9), MB.tag(Color("4a8a4a").lerp(Color("8ab858"), rng.randf()), MB.FOLIAGE), Vector3.ZERO, true)
				for r in 4:
					var rp := Vector3(0.1, 2.0, -0.4).lerp(tip, 0.4 + r * 0.15)
					b.leaf(rp, rp + Vector3(0.03, -0.45, 0.02), 0.05, MB.tag(Color("d8282a"), MB.CLOTH), Vector3(1, 0, 0))
		"stele":
			b.box(Vector3(0, 0.15, -0.1), Vector3(1.2, 0.3, 0.7), MB.tag(STONE_D, MB.STONE))
			b.box(Vector3(0, 1.15, -0.1), Vector3(0.9, 1.8, 0.28), MB.tag(STONE, MB.STONE))
			b.sph(Vector3(0, 2.05, -0.1), Vector3(0.48, 0.18, 0.15), MB.tag(STONE, MB.STONE))
			for k in 5:
				for j in 3:
					b.box(Vector3(-0.22 + j * 0.22, 1.7 - k * 0.24, 0.05), Vector3(0.12, 0.12, 0.02), MB.tag(Color("3a342c"), MB.STONE))
		"herb_patch":
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 909
			for k in 14:
				var hp := Vector3(rng2.randf_range(-0.7, 0.7), 0.0, rng2.randf_range(-0.6, 0.6))
				for l in 4:
					var la := TAU * l / 4.0 + k
					b.leaf(hp, hp + Vector3(cos(la) * 0.2, 0.25 + rng2.randf() * 0.15, sin(la) * 0.2), 0.07, MB.tag(Color("4a9a5a").lerp(Color("8ad070"), rng2.randf()), MB.FOLIAGE), Vector3(-sin(la), 0, cos(la)))
				if k % 3 == 0:
					g.sph_hi(hp + Vector3(0, 0.38, 0), Vector3.ONE * 0.035, Color(0.6, 1.0, 0.7, 0.9))
		"campfire":
			for k in 9:
				var a4 := TAU * k / 9.0
				b.ball(Vector3(cos(a4) * 0.45, 0.06, sin(a4) * 0.45), 0.13, MB.tag(STONE_D, MB.STONE))
			for k2 in 4:
				var a5 := TAU * k2 / 4.0 + 0.4
				b.limb(Vector3(cos(a5) * 0.35, 0.03, sin(a5) * 0.35), Vector3(0, 0.35, 0), 0.05, 0.04, MB.tag(Color("4a3020"), MB.WOOD), 5)
			mv.cone(Vector3(0, 0.25, 0), 0.22, 0.6, Color(1.0, 0.55, 0.15, 0.85), Vector3.ZERO, 8)
			mv.cone(Vector3(0, 0.2, 0), 0.12, 0.38, Color(1.0, 0.9, 0.5, 0.9), Vector3.ZERO, 8)
			for k3 in 2:
				b.box(Vector3(-0.85 + k3 * 1.7, 0.15, -0.2), Vector3(0.25, 0.3, 0.9), MB.tag(Color("5a4030"), MB.WOOD), Vector3(0, 0.2 - k3 * 0.4, 0))
		"stones":
			for k in 3:
				var sp := Vector3(-0.6 + k * 0.6, 0.0, -0.15)
				b.box(sp + Vector3(0, 0.16, 0), Vector3(0.4, 0.32, 0.22), MB.tag(STONE.darkened(k * 0.08), MB.STONE))
				b.torus(sp + Vector3(0, 0.34, 0), 0.12, 0.035, MB.tag(STONE.darkened(k * 0.08), MB.STONE), Vector3(0, 0, PI * 0.5))
			b.box(Vector3(0, 0.02, 0.2), Vector3(2.0, 0.04, 1.2), MB.tag(Color("8a7a60"), MB.WOOD))
		"broom":
			b.limb(Vector3(0.7, 0.0, -0.3), Vector3(0.85, 1.4, -0.45), 0.025, 0.025, MB.tag(WOOD_L, MB.WOOD), 5)
			b.cone(Vector3(0.7, 0.15, -0.3), 0.14, 0.35, MB.tag(Color("c8a860"), MB.HAIR), Vector3(PI, 0, 0), 8)
			var rng3 := RandomNumberGenerator.new()
			rng3.seed = 111
			for k in 26:
				var lp := Vector3(rng3.randf_range(-0.7, 0.4), 0.03 + rng3.randf() * 0.1, rng3.randf_range(-0.5, 0.5))
				b.leaf(lp, lp + Vector3(rng3.randf_range(-0.15, 0.15), 0.02, rng3.randf_range(-0.15, 0.15)), 0.08, MB.tag(Color("c8502a").lerp(Color("e8a030"), rng3.randf()), MB.FOLIAGE), Vector3(0, 1, 0))
		"weiqi":
			b.cyl(Vector3(0, 0.35, -0.3), 0.55, 0.1, MB.tag(STONE, MB.STONE), Vector3.ZERO, 16)
			b.cyl(Vector3(0, 0.15, -0.3), 0.25, 0.3, MB.tag(STONE_D, MB.STONE), Vector3.ZERO, 10)
			b.box(Vector3(0, 0.42, -0.3), Vector3(0.62, 0.04, 0.62), MB.tag(Color("d8b870"), MB.WOOD))
			var rng4 := RandomNumberGenerator.new()
			rng4.seed = 1919
			for k in 22:
				var stp := Vector3(rng4.randi_range(-4, 4) * 0.065, 0.45, rng4.randi_range(-4, 4) * 0.065 - 0.3)
				b.sph(stp, Vector3(0.028, 0.012, 0.028), MB.tag(Color("1a1a1a") if k % 2 == 0 else Color("f0f0e8"), MB.STONE))
			b.box(Vector3(0, 0.2, 0.35), Vector3(0.5, 0.4, 0.4), MB.tag(STONE_D, MB.STONE))
		"tea":
			b.box(Vector3(0, 0.4, -0.3), Vector3(0.9, 0.06, 0.6), MB.tag(WOOD, MB.WOOD))
			for s: float in [-1.0, 1.0]:
				for s2: float in [-1.0, 1.0]:
					b.box(Vector3(s * 0.38, 0.19, -0.3 + s2 * 0.24), Vector3(0.06, 0.38, 0.06), MB.tag(WOOD, MB.WOOD))
			b.lathe(Vector3(0, 0.43, -0.3), [Vector2(0.09, 0.0), Vector2(0.12, 0.08), Vector2(0.08, 0.16), Vector2(0.03, 0.2)], MB.tag(Color("6a3a2a"), MB.STONE), 10)
			for s3: float in [-1.0, 1.0]:
				b.lathe(Vector3(s3 * 0.25, 0.43, -0.2), [Vector2(0.03, 0.0), Vector2(0.04, 0.05)], MB.tag(Color("e8e0d0"), MB.STONE), 8)
			b.sph(Vector3(0, 0.06, 0.25), Vector3(0.3, 0.06, 0.25), MB.tag(Color("c8a040"), MB.CLOTH))
		"lion":
			b.box(Vector3(0, 0.3, -0.2), Vector3(0.9, 0.6, 1.0), MB.tag(STONE_D, MB.STONE))
			b.sph(Vector3(0, 0.95, -0.25), Vector3(0.38, 0.45, 0.5), MB.tag(STONE, MB.STONE))
			b.sph(Vector3(0, 1.45, 0.0), Vector3(0.36, 0.34, 0.34), MB.tag(STONE, MB.STONE))
			for k in 8:
				var a6 := TAU * k / 8.0
				b.ball(Vector3(cos(a6) * 0.32, 1.45 + sin(a6) * 0.32, -0.08), 0.09, MB.tag(STONE.darkened(0.1), MB.STONE))
			b.sph(Vector3(0, 1.38, 0.3), Vector3(0.18, 0.12, 0.12), MB.tag(STONE.lightened(0.1), MB.STONE))
			b.ball(Vector3(0.25, 0.72, 0.25), 0.16, MB.tag(STONE.lightened(0.05), MB.STONE))
			g.sph_hi(Vector3(0, 1.72, 0.05), Vector3(0.2, 0.06, 0.2), Color(1.0, 0.9, 0.6, 0.25))
		"chimes":
			b.limb(Vector3(0, 0, -0.4), Vector3(0, 2.4, -0.4), 0.06, 0.05, MB.tag(WOOD, MB.WOOD), 6)
			b.limb(Vector3(0, 2.3, -0.4), Vector3(0, 2.3, 0.3), 0.04, 0.04, MB.tag(WOOD, MB.WOOD), 6)
			for k in 5:
				mv.limb(Vector3((k - 2) * 0.1, 0.0, 0.0), Vector3((k - 2) * 0.1, -0.35 - (k % 3) * 0.12, 0.0), 0.022, 0.022, MB.tag(BRONZE.lightened(0.15), MB.METAL), 6)
			mv.box(Vector3(0, 0.02, 0), Vector3(0.6, 0.03, 0.06), MB.tag(WOOD_L, MB.WOOD))
			mv_at = Vector3(0, 2.25, 0.25)
		"lantern_st":
			b.box(Vector3(0, 0.12, -0.1), Vector3(0.7, 0.24, 0.7), MB.tag(STONE_D, MB.STONE))
			b.cyl(Vector3(0, 0.7, -0.1), 0.12, 0.95, MB.tag(STONE, MB.STONE), Vector3.ZERO, 8)
			b.box(Vector3(0, 1.22, -0.1), Vector3(0.6, 0.12, 0.6), MB.tag(STONE, MB.STONE))
			b.box(Vector3(0, 1.45, -0.1), Vector3(0.42, 0.36, 0.42), MB.tag(STONE.lightened(0.05), MB.STONE))
			b.cone(Vector3(0, 1.75, -0.1), 0.5, 0.35, MB.tag(STONE_D, MB.STONE), Vector3(0, PI / 4, 0), 4)
			# the flame inside, shown once the lantern has been lit
			mv.box(Vector3.ZERO, Vector3(0.3, 0.24, 0.44), Color(1.0, 0.72, 0.35, 0.85))
			mv.box(Vector3.ZERO, Vector3(0.44, 0.24, 0.3), Color(1.0, 0.72, 0.35, 0.85))
			mv_at = Vector3(0, 1.45, -0.1)
		"koi":
			# in the water: a ring of stepping stones and lily pads round a deeper pool, fish under them
			for k in 7:
				var a7 := TAU * k / 7.0
				b.sph(Vector3(cos(a7) * 0.85, Terrain3D.WATER_Y + 0.02, sin(a7) * 0.7), Vector3(0.22, 0.03, 0.22), MB.tag(Color("3f9a5a"), MB.FOLIAGE))
			for k2 in 5:
				var a8 := TAU * k2 / 5.0 + 0.4
				mv.sph(Vector3(cos(a8) * 0.4, 0.0, sin(a8) * 0.35), Vector3(0.06, 0.04, 0.16), MB.tag([Color("f08030"), Color("f0f0e0"), Color("e04020")][k2 % 3], MB.SCALE), Vector3(0, -a8, 0))
			mv_at = Vector3(0, Terrain3D.WATER_Y - 0.12, 0)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not mv.is_empty():
		var mover := Node3D.new()
		mover.name = "mover"
		mover.position = mv_at
		root.add_child(mover)
		var mat: Material = MB.mat_glow() if kind in ["campfire", "lantern_st"] else MB.mat_vc()
		MB.mesh_node(mover, mv.build(mat)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.set_meta("mover", mover)
	return root

## Something in the hero's hand for a clip, in the hand bone's own space (the bone runs from the
## wrist down to the fingers along -y; the palm faces +x for the right hand).
static func held(what: String) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	match what:
		"dipper":
			b.lathe(Vector3(0, -0.02, 0.1), [Vector2(0.05, 0.0), Vector2(0.06, 0.06)], MB.tag(WOOD_L, MB.WOOD), 10)
			b.limb(Vector3(0, -0.08, -0.12), Vector3(0, -0.06, 0.08), 0.012, 0.012, MB.tag(WOOD, MB.WOOD), 5)
		"cup":
			b.lathe(Vector3(0, -0.09, 0.02), [Vector2(0.025, 0.0), Vector2(0.035, 0.05)], MB.tag(Color("e8e0d0"), MB.STONE), 10)
		"rod":
			b.limb(Vector3(0, -0.08, -0.25), Vector3(0, 0.6, 1.9), 0.014, 0.005, MB.tag(Color("8a7a4a"), MB.WOOD), 5)
			b.limb(Vector3(0, 0.6, 1.9), Vector3(0, -1.2, 2.1), 0.002, 0.002, MB.tag(Color("e8e8e8"), MB.CLOTH), 3)
		"broom":
			b.limb(Vector3(0, -0.08, 0.6), Vector3(0, -0.08, -0.9), 0.02, 0.02, MB.tag(WOOD_L, MB.WOOD), 5)
			b.cone(Vector3(0, -0.08, -1.05), 0.13, 0.32, MB.tag(Color("c8a860"), MB.HAIR), Vector3(PI * 0.5, 0, 0), 8)
		"hammer":
			b.limb(Vector3(0, -0.08, -0.08), Vector3(0, -0.08, 0.3), 0.016, 0.016, MB.tag(WOOD, MB.WOOD), 5)
			b.box(Vector3(0, -0.08, 0.34), Vector3(0.07, 0.07, 0.16), MB.tag(Color("44444c"), MB.METAL), Vector3(0, PI * 0.5, 0))
		"ladle":
			b.limb(Vector3(0, -0.08, 0.3), Vector3(0, -0.08, -0.9), 0.016, 0.016, MB.tag(WOOD_L, MB.WOOD), 5)
			b.sph(Vector3(0, -0.08, -0.95), Vector3(0.07, 0.04, 0.07), MB.tag(WOOD, MB.WOOD))
		"book":
			b.box(Vector3(-0.02, -0.12, 0.04), Vector3(0.03, 0.2, 0.28), MB.tag(Color("e8dcc0"), MB.CLOTH))
			b.box(Vector3(-0.035, -0.12, 0.04), Vector3(0.01, 0.21, 0.29), MB.tag(Color("6a2a2a"), MB.CLOTH))
		"stone_lock":
			b.box(Vector3(0, -0.2, 0), Vector3(0.22, 0.2, 0.3), MB.tag(STONE, MB.STONE))
			b.torus(Vector3(0, -0.07, 0), 0.08, 0.025, MB.tag(STONE, MB.STONE), Vector3(0, 0, PI * 0.5))
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root
