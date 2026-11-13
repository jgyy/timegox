class_name Folk
extends RefCounted
## The people of the land (the Living Land release).  Every town is lived in now: a couple of hundred
## farmers, fishermen, merchants, porters, cooks, washerwomen, scholars, monks, guards, watchmen,
## lamplighters, grandparents, children and the sect's own outer disciples, each with a name, a home
## and a day of their own.  They get up at dawn, walk to their work along the streets (A* over the
## town's tiles, the roads preferred), do it there on clips of their own (art/lib/person.py: hoeing,
## fishing, calling their wares, carrying a shoulder pole, chopping wood, stirring a pot, sweeping,
## reading, praying; lent to every person by Assets.lend_clips) with the tool in their hands, eat at
## noon, sit over tea in the evening and go home at dusk; at night only the watchmen are out, with a
## lantern and a gong, calling the watches (and in Youdu, the city of the shades, the night is the
## day).  Face one and press Enter and they talk: about their work, the hour, the weather of their
## lives, and what the world says of Lin Feng.
##
## Nothing here keeps state.  A person's day is a timeline built once from their town's map (where
## they stay, what they do there, and the walks between), and where they are is a pure function of
## the clock (Clock, Game.clock), so the bot, the tests and the screenshots all see the same street.
## The 3D world (world.gd) draws the people near the hero and moves them aside when he walks through.

## walking pace (metres a second) and how far off people are still drawn (metres)
const SPEED := 1.25
const SEE := 52.0
## tiles round a town's heart its people live and work in
const RADIUS := 24
## a person's place in the plan is reached so many minutes after they set out at least
const MIN_STAY := 4.0

## The towns and who lives in them: the region, a tile of its own map at the heart of the town, the
## people of the realms they belong to (their bodies), how many of each kind, and whether they live
## by night (Youdu).  The sect counts as a town: its outer disciples keep its courtyards.
const TOWNS := {
	"sect": {"n": "the Azure Cloud Sect", "area": "sect", "at": Vector2i(20, 12), "race": "human",
		"roles": {"disciple": 10, "servant": 2, "lamplighter": 1, "watchman": 1}},
	"cloudfoot": {"n": "Cloudfoot", "area": "mountain", "at": Vector2i(82, 34), "race": "human",
		"roles": {"merchant": 4, "porter": 4, "farmer": 3, "child": 3, "elder": 2, "cook": 1, "guard": 2, "watchman": 1, "lamplighter": 1, "youth": 2, "scholar": 1}},
	"qingshi": {"n": "Qingshi Village", "area": "village", "at": Vector2i(30, 28), "race": "human",
		"roles": {"farmer": 7, "child": 4, "elder": 3, "washer": 2, "fisher": 1, "monk": 1, "cook": 1, "youth": 2, "watchman": 1, "merchant": 2}},
	# the Thundering Pots release: Qingshi has grown a second quarter, east of Lao's farm, round the Drum Tower:
	# the levy's barracks, the Hall of the Twelve Pipes, the tailor's, the Pear Garden stage and the kiln
	"drumtower": {"n": "the Drum Tower quarter of Qingshi", "area": "village", "at": Vector2i(79, 19), "race": "human", "reach": 14,
		"roles": {"soldier": 6, "musician": 4, "merchant": 3, "porter": 2, "child": 2, "elder": 2, "guard": 1, "watchman": 1, "lamplighter": 1, "cook": 1, "scholar": 1, "youth": 2}},
	"yanggu": {"n": "Yanggu", "area": "yanggu", "at": Vector2i(34, 30), "race": "human",
		"roles": {"merchant": 6, "porter": 3, "cook": 2, "child": 3, "elder": 2, "monk": 1, "guard": 2, "watchman": 1, "lamplighter": 2, "youth": 3, "scholar": 1, "washer": 2}},
	"shazhou": {"n": "Shazhou Oasis", "area": "dunes", "at": Vector2i(12, 40), "race": "desert",
		"roles": {"merchant": 4, "porter": 4, "child": 2, "elder": 2, "cook": 1, "guard": 2, "watchman": 1, "washer": 2}},
	"longmen": {"n": "Longmen", "area": "longmen", "at": Vector2i(28, 30), "race": "human",
		"roles": {"fisher": 6, "porter": 3, "merchant": 3, "child": 3, "elder": 2, "cook": 1, "guard": 1, "watchman": 1, "washer": 2}},
	"tushan": {"n": "Tushan", "area": "tushan", "at": Vector2i(28, 28), "race": "human",
		"roles": {"smith": 6, "merchant": 2, "child": 3, "elder": 2, "cook": 1, "guard": 1, "watchman": 1, "farmer": 2, "monk": 1}},
	"featherfall": {"n": "Featherfall", "area": "juntian", "at": Vector2i(38, 31), "race": "yumin",
		"roles": {"merchant": 3, "youth": 4, "child": 3, "elder": 2, "scholar": 2, "watchman": 1, "cook": 1}},
	"tearwater": {"n": "Tearwater", "area": "ninesprings", "at": Vector2i(38, 26), "race": "jiaoren",
		"roles": {"fisher": 4, "washer": 4, "merchant": 2, "child": 2, "elder": 2, "watchman": 1, "cook": 1}},
	"youdu_city": {"n": "Youdu", "area": "youdu", "at": Vector2i(38, 30), "race": "shade", "night": true,
		"roles": {"merchant": 4, "scholar": 3, "porter": 3, "elder": 2, "monk": 2, "guard": 2, "lamplighter": 2}},
	"landfall": {"n": "Landfall", "area": "penglai", "at": Vector2i(40, 30), "race": "human",
		"roles": {"fisher": 6, "washer": 3, "child": 4, "elder": 2, "merchant": 2, "youth": 2, "watchman": 1}},
}

## The bodies of each people for each kind of person (art/characters/folk_*.py); a kind missing
## from a people's list is drawn with its people's own body.
const BODIES := {
	"human": {"farmer": ["folk_farmer", "folk_farmwife"], "fisher": ["folk_fisher"], "merchant": ["folk_merchant", "folk_shopwife"],
		"porter": ["folk_porter", "folk_youth"], "child": ["folk_boy", "folk_girl"], "elder": ["folk_grandpa", "folk_grandma"],
		"monk": ["folk_monk"], "guard": ["folk_guard"], "watchman": ["folk_guard", "folk_grandpa"], "scholar": ["folk_scholar"],
		"cook": ["folk_cook"], "washer": ["folk_farmwife", "folk_maiden"], "youth": ["folk_youth", "folk_maiden"],
		"lamplighter": ["folk_youth", "folk_maiden"], "smith": ["folk_porter", "folk_youth"],
		"disciple": ["folk_disciple", "folk_disciple_f"], "servant": ["folk_youth", "folk_maiden"],
		# the people of the road (the High Roads release)
		"woodcutter": ["folk_porter", "folk_youth", "folk_farmer"], "herbalist": ["folk_farmwife", "folk_maiden", "folk_grandma"], "angler": ["folk_fisher", "folk_grandpa"],
		"pedlar": ["folk_merchant", "folk_porter", "folk_shopwife"], "hunter": ["folk_guard", "folk_youth"], "pilgrim": ["folk_monk", "folk_grandma", "folk_scholar"],
		"hermit": ["folk_grandpa", "folk_monk", "folk_scholar"],
		# the levy and the players (the Thundering Pots release)
		"soldier": ["folk_guard", "folk_youth", "folk_farmer", "folk_porter"], "musician": ["folk_scholar", "folk_maiden", "folk_youth", "folk_grandpa"]},
	"desert": {"merchant": ["folk_nomad", "folk_shopwife"], "porter": ["folk_nomad", "folk_porter"], "guard": ["folk_guard", "folk_nomad"],
		"child": ["folk_boy", "folk_girl"], "elder": ["folk_grandpa", "folk_grandma"], "cook": ["folk_cook"], "washer": ["folk_maiden", "folk_farmwife"],
		"watchman": ["folk_nomad"], "_": ["folk_nomad"]},
	"yumin": {"child": ["folk_boy", "folk_girl"], "_": ["folk_yumin"]},
	"jiaoren": {"child": ["folk_boy", "folk_girl"], "_": ["folk_jiaoren"]},
	"shade": {"_": ["folk_shade"]},
}

## What each kind of person does with the day: [hour, place, what they do there ("a|b" by turns,
## "in" indoors and out of sight), what they hold].  `walk` is how they go between places (a porter
## carries a shoulder pole) and `go_hold` what they carry on the way; `round` makes a stay a round of
## the town (the watchman's patrol, the lamplighter's lamps) instead of one spot.  Hues are the dyes
## their clothes come in ([robe hues], [secondary hues], saturation, value): empty keeps the model's
## own colours (the sect's blue, a monk's grey, a guard's red).
const ROLES := {
	"farmer": {"day": [[5.3, "field", "hoe|dig", "hoe"], [11.3, "home", "in", ""], [12.8, "field", "gather|hoe", "hoe"], [17.3, "well", "drink|wash", "dipper"], [18.2, "home", "in", ""]],
		"go_hold": "hoe", "dye": [[0.08, 0.1, 0.22, 0.28, 0.33], [0.06, 0.1, 0.55, 0.6], 0.35, 1.0]},
	"fisher": {"day": [[4.8, "shore", "fish", "rod"], [10.6, "market", "call|offer|talk", "basket"], [13.2, "shore", "fish", "rod"], [18.0, "inn", "drink|laugh", "cup"], [19.6, "home", "in", ""]],
		"go_hold": "rod", "dye": [[0.52, 0.56, 0.6, 0.08], [0.1, 0.12, 0.58], 0.35, 1.0]},
	"merchant": {"day": [[6.5, "market", "call|talk|offer|wave|count", ""], [11.9, "tea", "eat", "bowl"], [12.9, "market", "talk|call|point|think|count", ""], [18.3, "tea", "drink|laugh", "cup"], [20.5, "home", "in", ""]],
		"dye": [[0.0, 0.97, 0.75, 0.6, 0.85, 0.05], [0.12, 0.55, 0.6, 0.0], 0.55, 1.0]},
	"porter": {"day": [[5.7, "market", "lift", ""], [7.1, "gate", "lift", ""], [8.5, "market", "lift", ""], [9.9, "workshop", "lift", ""], [11.5, "inn", "eat", "bowl"],
			[12.5, "gate", "lift", ""], [14.1, "market", "lift", ""], [15.7, "gate", "lift", ""], [17.3, "inn", "sit_bench|drink", "cup"], [19.0, "home", "in", ""]],
		"walk": "carry", "go_hold": "pole", "dye": [[0.08, 0.1, 0.12, 0.55], [0.06, 0.08], 0.3, 1.0]},
	"child": {"day": [[7.1, "school", "read", "book"], [11.1, "home", "in", ""], [13.1, "square", "dance|clap|laugh", ""], [15.8, "field", "kite|clap|dance", ""], [18.0, "home", "in", ""]],
		"walk": "run", "dye": [[0.0, 0.08, 0.15, 0.3, 0.55, 0.62, 0.9], [0.12, 0.15, 0.95], 0.6, 1.05]},
	"elder": {"day": [[5.7, "square", "sword_dance|gaze|stretch", ""], [7.5, "bench", "sit_bench|think", ""], [10.9, "home", "in", ""], [13.9, "tea", "drink|think", "cup"], [16.4, "bench", "doze|sit_bench", ""], [17.9, "home", "in", ""]],
		"dye": [[0.07, 0.6, 0.8, 0.1], [0.08, 0.0], 0.25, 0.95]},
	"monk": {"day": [[4.6, "shrine", "pray", ""], [6.5, "shrine", "sweep", "broom"], [8.9, "market", "pray|offer", "bowl"], [11.5, "shrine", "eat", "bowl"], [12.9, "shrine", "pray|strike", ""], [16.9, "square", "sweep", "broom"], [18.9, "home", "in", ""]],
		"dye": []},
	"guard": {"day": [[6.0, "gate", "idle|look", ""], [11.9, "inn", "eat", "bowl"], [12.9, "gate", "idle|look", ""], [18.5, "home", "in", ""]], "dye": []},
	"watchman": {"day": [[5.1, "home", "in", ""], [18.7, "patrol", "bang|call", "gong"]], "round": "patrol", "go_hold": "lantern", "dye": []},
	"scholar": {"day": [[6.7, "school", "read|write", "book"], [11.7, "tea", "eat", "bowl"], [12.9, "square", "write|read|think", "book"], [17.4, "tea", "drink|play_flute", "cup"], [20.3, "home", "in", ""]],
		"dye": [[0.58, 0.62, 0.66, 0.5], [0.6, 0.62, 0.0], 0.35, 1.0]},
	"cook": {"day": [[5.1, "kitchen", "stir|chop|pound", "ladle"], [10.4, "market", "call|offer", "basket"], [11.4, "kitchen", "stir|pour", "ladle"], [15.0, "kitchen", "chop|stir", "axe"], [21.3, "home", "in", ""]],
		"dye": []},
	"washer": {"day": [[6.3, "shore", "gather", ""], [9.5, "home", "in", ""], [10.7, "square", "weave|toss", ""], [13.4, "shore", "gather", ""], [16.4, "market", "talk|laugh", "basket"], [18.3, "home", "in", ""]],
		"go_hold": "basket", "dye": [[0.0, 0.05, 0.85, 0.92, 0.3, 0.55], [0.55, 0.6, 0.1], 0.45, 1.05]},
	"youth": {"day": [[6.1, "woodpile", "chop", "axe"], [8.9, "workshop", "hammer|lift", "hammer"], [11.9, "inn", "eat", "bowl"], [13.1, "field", "hoe|gather", "hoe"], [16.7, "square", "talk|laugh|archery", ""],
			[19.1, "inn", "drink|laugh", "cup"], [21.5, "home", "in", ""]],
		"dye": [[0.3, 0.35, 0.55, 0.6, 0.08, 0.95], [0.1, 0.6, 0.05], 0.45, 1.0]},
	"lamplighter": {"day": [[4.8, "lamps", "touch", "taper"], [6.3, "home", "in", ""], [17.7, "lamps", "touch|release", "taper"], [20.1, "home", "in", ""]],
		"round": "lamps", "go_hold": "lantern", "dye": [[0.05, 0.08, 0.95], [0.1, 0.12], 0.55, 1.0]},
	"smith": {"day": [[5.9, "forge", "hammer", "hammer"], [11.7, "inn", "eat", "bowl"], [12.9, "forge", "hammer|lift", "hammer"], [18.5, "inn", "drink|laugh", "cup"], [20.4, "home", "in", ""]],
		"dye": [[0.05, 0.07, 0.6], [0.06, 0.08], 0.3, 0.9]},
	"disciple": {"day": [[5.1, "square", "sweep", "broom"], [6.7, "yard", "sword_dance", ""], [11.3, "kitchen", "eat", "bowl"], [12.5, "library", "read|write", "book"],
			[14.9, "yard", "sword_dance|archery", ""], [17.7, "kitchen", "eat", "bowl"], [18.9, "hall", "pray|meditate", ""], [20.3, "home", "in", ""]], "dye": []},
	"servant": {"day": [[5.0, "kitchen", "chop|stir", "axe"], [8.0, "square", "sweep", "broom"], [10.5, "well", "lift", ""], [12.0, "kitchen", "stir", "ladle"],
			[15.0, "yard", "sweep|toss", "broom"], [18.0, "kitchen", "stir|eat", "ladle"], [21.0, "home", "in", ""]], "go_hold": "pole", "walk": "carry",
		"dye": [[0.08, 0.1, 0.55], [0.06, 0.6], 0.3, 1.0]},
	# ---- the Thundering Pots release: the levy at drill on the open ground (spear and bow on the clips the
	# sect's disciples drill with), on the gate by turns, in the barracks at night; and the players of the
	# Pear Garden, who rehearse in the square, play at the tea-house and are heard all down the street
	"soldier": {"day": [[5.4, "yard", "sword_dance|stretch|archery", ""], [8.2, "gate", "idle|look", ""], [11.4, "inn", "eat", "bowl"], [12.6, "yard", "archery|sword_dance|lift", ""], [16.4, "square", "talk|laugh|clap", ""],
			[18.4, "inn", "drink|laugh", "cup"], [20.8, "home", "in", ""]],
		"dye": [[0.0, 0.02, 0.98], [0.08, 0.06], 0.5, 0.85]},
	"musician": {"day": [[6.8, "square", "play_flute|strike|clap", ""], [9.6, "tea", "play_flute|think", ""], [11.8, "tea", "eat", "bowl"], [13.0, "square", "strike|dance|play_flute", ""], [16.6, "bench", "play_flute|write", "book"],
			[18.6, "tea", "play_flute|drink|laugh", "cup"], [21.4, "home", "in", ""]],
		"dye": [[0.45, 0.12, 0.85, 0.95], [0.12, 0.6], 0.5, 1.0]},
	# ---- the people of the road (the High Roads release): nobody goes indoors, for there is no indoors;
	# at night they sit by the camp's fire and sleep sitting up
	"woodcutter": {"day": [[5.4, "wood", "chop", "axe"], [11.4, "camp", "eat", "bowl"], [12.7, "wood", "chop|lift|stretch", "axe"], [17.2, "camp", "chop|lift", "axe"], [18.8, "camp", "warm|drink|laugh", "cup"], [21.6, "camp", "doze", ""]],
		"walk": "carry", "go_hold": "pole", "dye": [[0.08, 0.1, 0.3], [0.06, 0.08], 0.3, 0.95]},
	"herbalist": {"day": [[5.0, "meadow", "gather|dig", ""], [9.4, "crag", "gather|peer", ""], [12.0, "camp", "eat", "bowl"], [13.2, "wood", "gather|peer", ""], [17.4, "camp", "pound|count", ""], [19.4, "camp", "warm|drink", "cup"],
			[21.2, "camp", "doze", ""]],
		"go_hold": "basket", "dye": [[0.3, 0.35, 0.28, 0.12], [0.1, 0.55], 0.35, 1.0]},
	"angler": {"day": [[4.7, "water", "fish", "rod"], [11.6, "camp", "eat|stir", "bowl"], [13.4, "water", "fish", "rod"], [18.4, "camp", "warm|drink|laugh", "cup"], [21.0, "camp", "doze", ""]],
		"go_hold": "rod", "dye": [[0.52, 0.56, 0.6, 0.08], [0.1, 0.12, 0.58], 0.3, 1.0]},
	"pedlar": {"day": [[6.0, "road", "call|offer|count", ""], [12.0, "camp", "eat", "bowl"], [13.0, "road", "call|wave|count", ""], [18.2, "camp", "count|drink|laugh", "cup"], [21.3, "camp", "doze", ""]],
		"round": "road", "walk": "carry", "go_hold": "pole", "dye": [[0.0, 0.97, 0.75, 0.6, 0.05], [0.12, 0.55, 0.0], 0.5, 1.0]},
	"hunter": {"day": [[4.4, "meadow", "archery|peer|look", ""], [9.8, "wood", "trace|peer|look", ""], [12.4, "camp", "eat", "bowl"], [13.8, "meadow", "archery|look|stretch", ""], [18.6, "camp", "warm|laugh|drink", "cup"],
			[21.8, "camp", "doze", ""]],
		"dye": [[0.08, 0.3, 0.1], [0.07, 0.3], 0.3, 0.85]},
	"pilgrim": {"day": [[5.2, "camp", "pray", ""], [6.4, "peak", "pray|gaze|stretch", ""], [11.4, "camp", "eat", "bowl"], [12.8, "road", "pray|think", ""], [16.2, "crag", "touch|pray", ""], [19.0, "camp", "warm|drink", "cup"],
			[21.4, "camp", "doze", ""]],
		"dye": [[0.1, 0.12, 0.6], [0.08, 0.0], 0.25, 0.95]},
	"hermit": {"day": [[4.6, "peak", "meditate", ""], [8.6, "peak", "gaze|stretch|think", ""], [11.8, "peak", "eat", "bowl"], [13.0, "peak", "play_flute|read|write", "book"], [17.2, "peak", "gaze|meditate", ""], [19.6, "peak", "stargaze", ""],
			[22.4, "peak", "doze", ""]],
		"dye": [[0.58, 0.1, 0.0], [0.6, 0.0], 0.15, 0.95]},
}

## where each kind of place may be found, best first: building styles (the doorstep outside), things
## to do (a tile beside them), or open ground ("open:<from>-<to>" tiles from the heart, "path" for a
## road, "shore" for beside the water)
const PLACES := {
	"home": ["house", "farmhouse", "huizhou", "dorm", "seahouse", "aerie", "inn", "shop", "hall"],
	"field": ["open:9-22"],
	"square": ["open:0-7"],
	"yard": ["open:3-11"],
	"market": ["shop", "teahouse", "path:2-10", "open:2-9"],
	"tea": ["teahouse", "inn", "huizhou", "open:0-7"],
	"inn": ["inn", "teahouse", "huizhou", "open:0-7"],
	"kitchen": ["kitchen", "inn", "teahouse", "open:2-8"],
	"school": ["library", "huizhou", "hall", "open:0-7"],
	"library": ["library", "hall", "open:0-7"],
	"hall": ["hall", "shrine", "open:0-7"],
	"shrine": ["shrine", "prop:shrine", "prop:bell", "hall", "open:0-8"],
	"gate": ["path:13-22", "open:13-21"],
	"workshop": ["smithy", "shop", "dorm", "farmhouse", "open:3-10"],
	"forge": ["smithy", "dorm", "farmhouse", "open:3-10"],
	"woodpile": ["farmhouse", "house", "open:6-14"],
	"bench": ["prop:bench", "prop:weiqi", "prop:tea", "prop:swing", "prop:campfire", "open:0-8"],
	"well": ["prop:well", "shore", "open:0-6"],
	"shore": ["shore", "open:8-20"],
	"patrol": ["path:8-16", "open:6-14"],
	"lamps": ["prop:lantern_st", "path:3-12", "open:3-10"],
	# the places of the road (the High Roads release): round the camp's fire, the forest's edge, open
	# country, the road, the water, the foot of the crag and its very top
	"camp": ["ring"],
	"wood": ["wood", "open:6-16"],
	"meadow": ["open:10-22"],
	"road": ["path:4-24", "open:8-20"],
	"water": ["shore", "open:6-18"],
	"crag": ["crag", "open:6-14"],
	"peak": ["peak", "crag", "open:6-14"],
}

const FAMILY := ["Wang", "Li", "Zhang", "Liu", "Chen", "Yang", "Zhao", "Huang", "Zhou", "Wu", "Xu", "Sun", "Hu", "Zhu", "Gao", "Lin", "He", "Guo", "Ma", "Luo",
	"Liang", "Song", "Zheng", "Xie", "Han", "Tang", "Feng", "Yu", "Dong", "Xiao", "Cheng", "Cao", "Yuan", "Deng", "Peng", "Pan", "Du", "Dai", "Jiang", "Qian"]
const GIVEN_M := ["Bao", "Hu", "Shan", "Ming", "Gang", "Jun", "Feng", "Tie", "Shi", "Wen", "Kang", "An", "Lei", "Bin", "Cheng", "Da", "Shun", "Fu"]
const GIVEN_F := ["Mei", "Lan", "Hua", "Ying", "Juan", "Xia", "Yun", "Qin", "Zhen", "Fang", "Li", "Yan", "Hong", "Ping", "Xiu", "Cui", "Yue", "Ling"]
const KIDS := ["Dou", "Bao", "Niu", "Pang", "Shu", "Ya", "Xi", "Tuan", "Qiu", "Mao", "Gou", "Huan", "Tao", "Le", "Duo", "Mi"]
const DHARMA := ["Jingkong", "Huineng", "Zhiyuan", "Wuxin", "Jueming", "Hongren", "Daoxin", "Fazang", "Yuanjue", "Mingshan"]
const TITLES := {"farmer": ["Farmer", "Farmer"], "fisher": ["Fisherman", "Fisherwoman"], "merchant": ["Merchant", "Shopkeeper"], "porter": ["Porter", "Porter"],
	"monk": ["Brother", "Sister"], "guard": ["Guard", "Guard"], "watchman": ["Watchman", "Watchwoman"], "scholar": ["Scholar", "Scholar"], "cook": ["Cook", "Cook"],
	"washer": ["Brother", "Auntie"], "youth": ["Brother", "Sister"], "lamplighter": ["Lamplighter", "Lamplighter"], "smith": ["Caster", "Caster"],
	"disciple": ["Disciple", "Disciple"], "servant": ["Steward", "Steward"],
	"woodcutter": ["Woodcutter", "Woodcutter"], "herbalist": ["Herb-Gatherer", "Herb-Gatherer"], "angler": ["Old Angler", "Angler"], "pedlar": ["Pedlar", "Pedlar"],
	"hunter": ["Hunter", "Huntress"], "pilgrim": ["Pilgrim", "Pilgrim"], "hermit": ["Hermit", "Hermit"],
	"soldier": ["Levy-Man", "Levy-Woman"], "musician": ["Player", "Player"]}

## the bodies that are women and girls (for names and words)
const FEM := ["folk_farmwife", "folk_shopwife", "folk_girl", "folk_grandma", "folk_maiden", "folk_disciple_f", "folk_jiaoren",
	"folk_oasis_f", "folk_boatwoman", "folk_lantern_f", "folk_herder_f"]
## The Six Hearths (cultures.gd, the New Fire release): the dress of each hearth of the land
## (art/characters/folk_*.py), worn by about half of its grown men ("m") or women ("f"), or by everybody
## of one trade ("m:smith"); and the names its people go by where they are not the valley's.
const HEARTH_BODIES := {
	"sand": {"f": "folk_oasis_f"},
	"river": {"f": "folk_boatwoman", "f:washer": "folk_boatwoman", "f:merchant": "folk_boatwoman", "f:fisher": "folk_boatwoman"},
	"forge": {"m:smith": "folk_founder", "m:porter": "folk_founder"},
	"dawn": {"f": "folk_lantern_f"},
}
const HEARTH_NAMES := {
	"sand": {"m": ["Rustam", "Darab", "Bahram", "Yusuf", "Anush", "Sartak", "Varaz", "Kamran", "Zurab", "Mihr", "Tarkhan", "Ormuz"],
		"f": ["Shirin", "Laleh", "Parvana", "Roshan", "Anahit", "Zarina", "Gulnar", "Mahin", "Soraya", "Nilufar", "Tamina", "Yasmin"]},
}
## the bodies that are children and elders
const KID := ["folk_boy", "folk_girl"]
const OLD := ["folk_grandpa", "folk_grandma"]

# ---------------------------------------------------------------- who lives where
static var _towns := {}
static var _astar := {}

# ---------------------------------------------------------------- the people of the road
## The High Roads release: the land between the towns is lived in too.  At the foot of the highest
## peak of every region there is a camp (a ring of stones, a fire, a lean-to), and the people of it
## have days of their own like anybody's: a woodcutter at the forest's edge, a gatherer of herbs
## under the crag, somebody fishing, a pedlar walking the road with a pole of goods, a hunter, a
## pilgrim who goes up to the summit every morning, and a hermit who never comes down from it.
## At dusk they come in to the fire, and sleep sitting up beside it.  They are made, moved and
## talked to by everything that makes, moves and talks to the people of the towns: a camp is a town
## with no houses (`town`), whose heart is where Atlas put it (`place_camps`).
const CAMP_ROLES := {"woodcutter": 1, "herbalist": 1, "angler": 1, "pedlar": 1, "hunter": 1, "pilgrim": 1, "hermit": 1}
## the people of the camps of each realm that is not the land's own, and of the sands
const CAMP_RACE := {"heaven": "yumin", "under": "jiaoren", "dunes": "desert", "youdu": "shade"}

static func is_camp(tid: String) -> bool:
	return tid.begins_with("camp_")

## The camp of region `area` in realm data `wd` ("" if it has none).
static func camp_of(wd: Dictionary, area: String) -> String:
	return ("camp_" + area) if (wd.get("camps", {}) as Dictionary).has(area) else ""

## What a town or a camp is: its name, region, people and who lives in it.
static func town(tid: String) -> Dictionary:
	if TOWNS.has(tid):
		return TOWNS[tid]
	var area := tid.trim_prefix("camp_")
	var spec: Dictionary = Data.AREAS.get(area, {})
	var race: String = str(CAMP_RACE.get(area, CAMP_RACE.get(Data.layer_of(area), "human")))
	return {"n": "the road through " + str(spec.get("n", area)), "area": area, "race": race, "roles": CAMP_ROLES, "camp": true}

## Where the camps of a realm stand: for each region with a peak, open ground a little way from the
## foot of its highest one, with room round it, nearest the road if there is one.  Called when the
## realm is built (Atlas._build), after the peaks; returns {region: tile}.
static func place_camps(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, ids: Array, ents: Array, reach: Dictionary, peaks: Array) -> Dictionary:
	var out := {}
	var near := {}
	for e in ents:
		for et in (e.tiles if e.kind == "seal" else ([e.pos] if e.has("pos") else [])):
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					near[(et as Vector2i) + Vector2i(dx, dy)] = true
	var best_h := {}
	for pk in peaks:
		if float(pk.h) > float(best_h.get(pk.area, {"h": 0.0}).h):
			best_h[pk.area] = pk
	for area in best_h:
		var pk2: Dictionary = best_h[area]
		var c: Vector2i = pk2.c
		var me: int = ids.find(area)
		var want := float(int(pk2.r) + 7)
		var best := Vector2i(-1, -1)
		var bs := -1.0e9
		var reach_r := int(pk2.r) + 22
		for y in range(maxi(3, c.y - reach_r), mini(H - 3, c.y + reach_r + 1)):
			for x in range(maxi(3, c.x - reach_r), mini(W - 3, c.x + reach_r + 1)):
				var p := Vector2i(x, y)
				if owner[y * W + x] != me or near.has(p) or not reach.has(p) or grid[y * W + x] != MapGen.FLOOR:
					continue
				var d := Vector2(p - c).length()
				if d < float(pk2.r) + 3.0:
					continue
				var open_n := 0
				var roads := 0
				for dy2 in range(-2, 3):
					for dx2 in range(-2, 3):
						var g: int = grid[(y + dy2) * W + x + dx2]
						if MapGen.is_walkable_tile(g) and g != MapGen.INTERIOR:
							open_n += 1
						if g == MapGen.PATH:
							roads += 1
				if open_n < 19 or roads > 6:
					continue
				var sc := -absf(d - want) + float(open_n) * 0.1 + Terrain3D.hash2(x, y, 41.0) * 0.5
				if sc > bs:
					bs = sc
					best = p
		if best.x >= 0:
			out[area] = best
	return out

## The tile at the heart of town `tid` (a world tile of its realm).
static func heart(tid: String) -> Vector2i:
	if is_camp(tid):
		var area := tid.trim_prefix("camp_")
		return Atlas.world_of(Data.layer_of(area)).camps[area]
	var t: Dictionary = TOWNS[tid]
	return Atlas.to_world(str(t.area), t.at)

## The towns standing in region `area`.
static func towns_in(area: String) -> Array:
	var out: Array = []
	for tid in TOWNS:
		if str(TOWNS[tid].area) == area:
			out.append(tid)
	return out

## The people of town `tid` in realm data `wd` (Atlas.world_of: its grid, its buildings, its things):
## made once, in a fixed order, from the town's own seed.
static func people(wd: Dictionary, tid: String) -> Array:
	var key := "%s|%s" % [str(wd.get("layer", "")), tid]
	if _towns.has(key):
		return _towns[key]
	var t: Dictionary = town(tid)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("folk:" + tid)
	var out: Array = []
	var used_names := {}
	var i := 0
	var roles: Dictionary = t.roles
	for role in roles:
		for k in int(roles[role]):
			var body := _body(str(t.race), role, rng)
			var p := {"id": "folk:%s:%d" % [tid, i], "town": tid, "area": t.area, "role": role, "body": body, "seed": rng.randi() % 1000,
				"fem": body in FEM, "kid": body in KID, "old": body in OLD, "night": bool(t.get("night", false))}
			p.n = _name(p, rng, used_names)
			p.dye = _dye(role, rng)
			_hearth_dress(p, used_names)
			out.append(p)
			i += 1
	_towns[key] = out
	return out

## The Six Hearths (cultures.gd): person `p` in the dress and under a name of their own hearth.  Decided
## from the seed they already have, so nobody else in the town changes for it.
static func _hearth_dress(p: Dictionary, used: Dictionary) -> void:
	var hid := Cultures.of_town(str(p.town))
	if hid == "" or bool(p.kid) or bool(p.old):
		return
	var sx := "f" if bool(p.fem) else "m"
	var hb: Dictionary = HEARTH_BODIES.get(hid, {})
	if hb.has(sx + ":" + str(p.role)):
		p.body = str(hb[sx + ":" + str(p.role)])
	elif hb.has(sx) and int(p.seed) % 2 == 0 and not str(p.role) in ["monk", "guard", "disciple"]:
		p.body = str(hb[sx])
	var hn: Dictionary = HEARTH_NAMES.get(hid, {})
	if hn.has(sx) and str(p.role) != "monk":
		var pool: Array = hn[sx]
		var tt: Array = TITLES.get(str(p.role), ["Brother", "Sister"])
		for k in pool.size():
			var n := "%s %s" % [str(tt[1] if bool(p.fem) else tt[0]), str(pool[(int(p.seed) + k) % pool.size()])]
			if not used.has(n):
				used[n] = true
				p.n = n
				break

static func _body(race: String, role: String, rng: RandomNumberGenerator) -> String:
	var b: Dictionary = BODIES.get(race, BODIES.human)
	var opts: Array = b.get(role, b.get("_", BODIES.human.get(role, ["folk_youth"])))
	return str(opts[rng.randi() % opts.size()])

static func _name(p: Dictionary, rng: RandomNumberGenerator, used: Dictionary) -> String:
	var n := ""
	for tries in 8:
		var fam: String = FAMILY[rng.randi() % FAMILY.size()]
		var fem: bool = p.fem
		if p.kid:
			n = "Little " + str(KIDS[rng.randi() % KIDS.size()])
		elif p.old:
			n = ("Granny " if fem else "Grandpa ") + fam
		elif p.role == "monk":
			n = ("Sister " if fem else "Brother ") + str(DHARMA[rng.randi() % DHARMA.size()])
		elif p.role == "disciple":
			n = "Disciple %s %s" % [fam, str((GIVEN_F if fem else GIVEN_M)[rng.randi() % 18])]
		elif p.role == "washer":
			n = ("Auntie " if fem else "Uncle ") + fam
		else:
			var tt: Array = TITLES.get(str(p.role), ["Brother", "Sister"])
			n = "%s %s" % [str(tt[1] if fem else tt[0]), fam]
		if not used.has(n):
			break
	used[n] = true
	return n

## [robe dye, secondary dye] as [hue, saturation, value scale] (Vector3), or [] to keep the model's own.
static func _dye(role: String, rng: RandomNumberGenerator) -> Array:
	var d: Array = ROLES[role].get("dye", [])
	if d.is_empty():
		return []
	var ha: Array = d[0]
	var hb: Array = d[1]
	var sat: float = float(d[2])
	var val: float = float(d[3])
	var a := Vector3(float(ha[rng.randi() % ha.size()]) + rng.randf_range(-0.02, 0.02), clampf(sat + rng.randf_range(-0.12, 0.12), 0.05, 0.9), val * rng.randf_range(0.85, 1.12))
	var b := Vector3(float(hb[rng.randi() % hb.size()]) + rng.randf_range(-0.02, 0.02), clampf(sat * 0.8 + rng.randf_range(-0.1, 0.1), 0.05, 0.9), val * rng.randf_range(0.8, 1.1))
	# quantised, so a town shares a few dozen materials (MB.mat_dyed)
	a = Vector3(snappedf(fposmod(a.x, 1.0), 0.02), snappedf(a.y, 0.05), snappedf(a.z, 0.05))
	b = Vector3(snappedf(fposmod(b.x, 1.0), 0.02), snappedf(b.y, 0.05), snappedf(b.z, 0.05))
	return [a, b]

# ---------------------------------------------------------------- the places of a town
## The tiles round town `tid` a person may stand on: walkable ground of the town's own region,
## outside every building.
static func _free(wd: Dictionary, p: Vector2i, area: String) -> bool:
	if p.x < 0 or p.y < 0 or p.x >= int(wd.w) or p.y >= int(wd.h):
		return false
	var g: int = wd.grid[p.y * int(wd.w) + p.x]
	if g == MapGen.INTERIOR or not MapGen.is_walkable_tile(g):
		return false
	return Atlas.owner_id(wd, p) == area

## Tiles where people never stand still: in front of a door, a thing to do, a stair, a seal, a boss,
## somebody's own tile.
static func _taken(wd: Dictionary, tid: String) -> Dictionary:
	var key := "taken|%s|%s" % [str(wd.get("layer", "")), tid]
	if _towns.has(key):
		return _towns[key]
	var area: String = town(tid).area
	var out := {}
	for e in wd.ents:
		# (Part XVII's obstacles, impact.gd, and the people and things that came later in the story, "late",
		# stand for a chapter: the people of the towns keep the places they had before them)
		if str(e.get("area", "")) != area or e.kind == "obstacle" or e.get("late", false):
			continue
		out[e.pos] = true
		if e.kind in ["npc", "prop", "ladder", "boss", "seal", "stele", "abode"]:
			for d in MapGen.DIRS:
				out[e.pos + d] = true
	for bd in wd.buildings:
		if str(bd.area) == area:
			out[bd.door] = true
	_towns[key] = out
	return out

## Every candidate tile for place `kind` in town `tid`: [tile, facing yaw] pairs, best kind first.
static func _spots(wd: Dictionary, tid: String, kind: String) -> Array:
	var key := "spots|%s|%s|%s" % [str(wd.get("layer", "")), tid, kind]
	if _towns.has(key):
		return _towns[key]
	var area: String = town(tid).area
	var c := heart(tid)
	var taken := _taken(wd, tid)
	# (only places that can be walked to from the heart of the town: a doorstep cut off by water is
	# nobody's doorstep)
	for bt in Havoc.tiles(wd, area):
		taken[bt] = true
	var reach := _reach(wd, tid)
	var out: Array = []
	for src in PLACES.get(kind, ["open:0-8"]):
		var s := str(src)
		if s.begins_with("open:") or s.begins_with("path:") or s == "shore":
			var lo := 0
			var hi := 20
			if s != "shore":
				var rg := s.get_slice(":", 1)
				lo = int(rg.get_slice("-", 0))
				hi = int(rg.get_slice("-", 1))
			for y in range(c.y - hi, c.y + hi + 1):
				for x in range(c.x - hi, c.x + hi + 1):
					var p := Vector2i(x, y)
					var dd := maxi(absi(x - c.x), absi(y - c.y))
					if dd < lo or dd > hi or taken.has(p) or not reach.has(p):
						continue
					var g: int = wd.grid[y * int(wd.w) + x]
					if s.begins_with("path:") and g != MapGen.PATH:
						continue
					if s == "shore":
						var wet := Vector2i.ZERO
						for d in MapGen.DIRS:
							var q: Vector2i = p + d
							if q.x >= 0 and q.y >= 0 and q.x < int(wd.w) and q.y < int(wd.h) and wd.grid[q.y * int(wd.w) + q.x] == MapGen.WATER:
								wet = d
						if wet == Vector2i.ZERO:
							continue
						out.append([p, atan2(float(wet.x), float(wet.y))])
						continue
					if s.begins_with("open:"):
						# open ground: a tile with open ground round it, not a road (unless nothing else)
						var open_n := 0
						for d2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
							if _free(wd, p + d2, area):
								open_n += 1
						if open_n < 6:
							continue
					var to_c := Vector2(c - p)
					out.append([p, atan2(to_c.x, to_c.y) if to_c.length() > 0.5 else Terrain3D.hash2(x, y, 5.0) * TAU])
		elif s == "ring":
			# round the fire of a camp, facing it
			for k in 8:
				var a := TAU * float(k) / 8.0
				var q0 := c + Vector2i(int(round(cos(a))), int(round(sin(a))))
				if reach.has(q0) and not taken.has(q0) and q0 != c:
					out.append([q0, atan2(float(c.x - q0.x), float(c.y - q0.y))])
		elif s == "wood":
			# the forest's edge: open ground with a tree beside it, facing the tree
			for y0 in range(c.y - RADIUS, c.y + RADIUS + 1):
				for x0 in range(c.x - RADIUS, c.x + RADIUS + 1):
					var p0 := Vector2i(x0, y0)
					if maxi(absi(x0 - c.x), absi(y0 - c.y)) < 4 or taken.has(p0) or not reach.has(p0):
						continue
					for d0 in MapGen.DIRS:
						var t0: Vector2i = p0 + d0
						if t0.x >= 0 and t0.y >= 0 and t0.x < int(wd.w) and t0.y < int(wd.h) and wd.grid[t0.y * int(wd.w) + t0.x] == MapGen.WALL:
							out.append([p0, atan2(float(d0.x), float(d0.y))])
							break
		elif s == "peak" or s == "crag":
			# the very top of the region's peaks, looking out; or the foot of one, facing the rock
			for pk0 in Peaks.of_area(wd, area):
				var pc: Vector2i = pk0.c
				if s == "peak":
					for d1 in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(2, 0)]:
						var q1: Vector2i = pc + d1
						if reach.has(q1):
							var away := Vector2(c - pc)
							out.append([q1, atan2(away.x, away.y) + float(d1.x) * 0.6 - float(d1.y) * 0.4])
				else:
					var rr := int(pk0.r) + 2
					for y1 in range(pc.y - rr, pc.y + rr + 1):
						for x1 in range(pc.x - rr, pc.x + rr + 1):
							var p1 := Vector2i(x1, y1)
							var up := Peaks.at(wd, p1)
							if up < 0.15 or up > 1.6 or taken.has(p1) or not reach.has(p1):
								continue
							var to_p := Vector2(pc - p1)
							out.append([p1, atan2(to_p.x, to_p.y)])
		elif s.begins_with("prop:"):
			var pk := s.get_slice(":", 1)
			for e in wd.ents:
				if e.kind != "prop" or str(e.get("area", "")) != area or str(e.get("prop", "")) != pk or e.has("furn"):
					continue
				if maxi(absi(e.pos.x - c.x), absi(e.pos.y - c.y)) > RADIUS + 6:
					continue
				for d3 in MapGen.DIRS:
					var q2: Vector2i = e.pos + d3 * 2
					if reach.has(q2) and not taken.has(q2):
						out.append([q2, atan2(float(-d3.x), float(-d3.y))])
		else:
			# a building of that style: its doorstep, a step out from the door
			for bd in wd.buildings:
				if str(bd.area) != area or str(bd.get("style", "")) != s:
					continue
				var door: Vector2i = bd.door
				# (a quarter of a larger town keeps to its own streets: `reach`)
				if maxi(absi(door.x - c.x), absi(door.y - c.y)) > int(town(tid).get("reach", RADIUS + 8)):
					continue
				for d4 in MapGen.DIRS:
					var q3: Vector2i = door + d4
					if not (bd.rect as Rect2i).has_point(q3) and reach.has(q3):
						# one or two steps out, so they never stand in the doorway itself, and a step either
						# side along the front, so a shop's people stand in a row and not on one tile
						var q4: Vector2i = q3 + d4
						var st: Vector2i = q4 if reach.has(q4) and not taken.has(q4) else q3
						var side := Vector2i(-d4.y, d4.x)
						for sd in [Vector2i.ZERO, side * 2, -side * 2]:
							var q6: Vector2i = st + sd
							if reach.has(q6) and (sd == Vector2i.ZERO or not taken.has(q6)):
								out.append([q6, atan2(float(-d4.x), float(-d4.y)), str(bd.id)])
						break
		# (enough places for a town's worth of people: the next kind of place too, if there are few;
		# a summit has room for few, and whoever is sent to one goes to it)
		if out.size() >= 6 or (s == "peak" and not out.is_empty()):
			break
	if out.is_empty():
		var any: Vector2i = c
		for q5 in reach:
			any = q5
			break
		out.append([any, 0.0])
	_towns[key] = out
	return out

## The tiles of town `tid` that can be walked to from its heart (its A* grid's open ground, flooded
## from the free tile nearest the heart).
static func _reach(wd: Dictionary, tid: String) -> Dictionary:
	var key := "reach|%s|%s" % [str(wd.get("layer", "")), tid]
	if _towns.has(key):
		return _towns[key]
	var g := _grid(wd, tid)
	var ast: AStarGrid2D = g[0]
	var rect: Rect2i = g[1]
	var c := heart(tid)
	var start := Vector2i(-1, -1)
	for r in 12:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var p := c + Vector2i(dx, dy)
				if start.x < 0 and rect.has_point(p) and not ast.is_point_solid(p):
					start = p
		if start.x >= 0:
			break
	var out := {}
	if start.x >= 0:
		out[start] = true
		var q: Array = [start]
		var i := 0
		while i < q.size():
			var cur: Vector2i = q[i]
			i += 1
			for d in MapGen.DIRS:
				var n: Vector2i = cur + d
				if rect.has_point(n) and not out.has(n) and not ast.is_point_solid(n):
					out[n] = true
					q.append(n)
	_towns[key] = out
	return out

## One place of kind `kind` for person `p` (its index in the candidates comes from the person's seed,
## so a town's people spread out over its fields and its doorsteps).
static func _place(wd: Dictionary, p: Dictionary, kind: String, salt: int) -> Array:
	var sp := _spots(wd, str(p.town), kind)
	var pick: Array = sp[(int(p.seed) * 7 + salt * 13) % sp.size()]
	return pick

# ---------------------------------------------------------------- the walks between
## The town's A* grid: walkable tiles of its region round its heart (roads cheap, open ground dearer,
## the insides of buildings shut: people go home to the door).
static func _grid(wd: Dictionary, tid: String) -> Array:
	var key := "%s|%s" % [str(wd.get("layer", "")), tid]
	if _astar.has(key):
		return _astar[key]
	var area: String = town(tid).area
	var c := heart(tid)
	var r := RADIUS + 8
	var rect := Rect2i(c - Vector2i(r, r), Vector2i(r * 2 + 1, r * 2 + 1)).intersection(Rect2i(0, 0, int(wd.w), int(wd.h)))
	var a := AStarGrid2D.new()
	a.region = rect
	a.cell_size = Vector2.ONE
	a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	a.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	a.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	a.update()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var p := Vector2i(x, y)
			if not _free(wd, p, area):
				a.set_point_solid(p, true)
			elif wd.grid[y * int(wd.w) + x] != MapGen.PATH:
				a.set_point_weight_scale(p, 1.7)
	# (and round the jars and woodpiles people leave by their walls, havoc.gd, never through them)
	for bt in Havoc.tiles(wd, area):
		if rect.has_point(bt) and not a.is_point_solid(bt):
			a.set_point_weight_scale(bt, 10.0)
	var out := [a, rect]
	_astar[key] = out
	return out

## The way from tile `a` to tile `b` in town `tid`: tile centres (float tiles), eased round the corners.
static func route(wd: Dictionary, tid: String, a: Vector2i, b: Vector2i) -> PackedVector2Array:
	var g := _grid(wd, tid)
	var ast: AStarGrid2D = g[0]
	var rect: Rect2i = g[1]
	var pts := PackedVector2Array()
	if a == b:
		pts.append(Vector2(a) + Vector2(0.5, 0.5))
		pts.append(Vector2(b) + Vector2(0.5, 0.5))
		return pts
	# (no way there: an empty route, and the walk is made out of sight, "round the back way"; a
	# straight line used to take people through the walls of houses)
	if not rect.has_point(a) or not rect.has_point(b) or ast.is_point_solid(a) or ast.is_point_solid(b):
		return pts
	var ids: Array[Vector2i] = ast.get_id_path(a, b)
	if ids.is_empty():
		return pts
	var raw := PackedVector2Array()
	for q in ids:
		raw.append(Vector2(q) + Vector2(0.5, 0.5))
	if raw.size() <= 2:
		return raw
	# one round of corner-cutting (Chaikin): the walk follows a curve, not the grid's right angles
	pts.append(raw[0])
	for i in raw.size() - 1:
		pts.append(raw[i].lerp(raw[i + 1], 0.25))
		pts.append(raw[i].lerp(raw[i + 1], 0.75))
	pts.append(raw[raw.size() - 1])
	return pts

static func route_len(pts: PackedVector2Array) -> float:
	if pts.size() < 2:
		# the back way round: a walk of a minute or two, out of sight
		return 90.0
	var l := 0.0
	for i in range(1, pts.size()):
		l += pts[i].distance_to(pts[i - 1])
	return l * Terrain3D.T

## Minutes of the clock a walk of `metres` takes when it sets out at minute `m` (the night runs the
## clock faster, so a walk by night takes more of it).
static func walk_minutes(metres: float, m: float) -> float:
	return metres / SPEED * Clock.rate(m)

# ---------------------------------------------------------------- a person's day
## The day of person `p`: a list of segments covering a whole day from the first thing in the plan,
## each {a, b (minutes), kind "stay" or "walk", at (float tile), yaw, clip, hold, in (indoors), pts}.
static func day_of(wd: Dictionary, p: Dictionary) -> Array:
	if p.has("segs"):
		return p.segs
	var role: Dictionary = ROLES[str(p.role)]
	var plan: Array = role.day
	var night_town: bool = p.night
	var stays: Array = []
	for i in plan.size():
		var e: Array = plan[i]
		var h := float(e[0])
		if night_town:
			# Youdu: the shades keep the night as other towns keep the day
			h = fposmod(h + 12.0, 24.0)
		var pl := _place(wd, p, str(e[1]), i)
		var st := {"m": h * 60.0, "kind": str(e[1]), "tile": pl[0], "yaw": float(pl[1]), "clip": str(e[2]), "hold": str(e[3]),
			# (a little room of their own: two people sent to one spot stand side by side, not inside each other)
			"nudge": Vector2(Terrain3D.hash2(int(p.seed), i, 1.0) - 0.5, Terrain3D.hash2(int(p.seed), i, 2.0) - 0.5) * 0.7}
		if str(e[1]) == str(role.get("round", "-")):
			# a round of the town: four stops of its kind, walked in turn
			var wps: Array = []
			var sp := _spots(wd, str(p.town), str(e[1]))
			for k in 4:
				var pick: Array = sp[(int(p.seed) * 5 + k * (sp.size() / 4 + 1)) % sp.size()]
				if not wps.has(pick[0]):
					wps.append(pick[0])
			st.round = wps
		stays.append(st)
	stays.sort_custom(func(x, y): return float(x.m) < float(y.m))
	var segs: Array = []
	var n := stays.size()
	var t := float(stays[0].m)
	var start := t
	var cur: Vector2i = stays[0].tile
	for i in n:
		var st2: Dictionary = stays[i]
		var nx: Dictionary = stays[(i + 1) % n]
		var next_m := float(nx.m) + (1440.0 if i + 1 >= n else 0.0)
		while next_m <= float(st2.m):
			next_m += 1440.0
		var at_in: bool = str(st2.clip) == "in"
		if st2.has("round"):
			var wps2: Array = st2.round
			var k2 := 0
			cur = wps2[0]
			while true:
				var pause := 7.0 + float(int(p.seed) % 5)
				var stay := {"a": t, "b": t + pause, "kind": "stay", "at": Vector2(cur) + Vector2(0.5, 0.5), "yaw": Terrain3D.hash2(cur.x, cur.y, 9.0) * TAU,
					"clip": st2.clip, "hold": st2.hold, "in": false}
				segs.append(stay)
				t += pause
				var nk := (k2 + 1) % wps2.size()
				var pts := route(wd, str(p.town), cur, wps2[nk])
				var w_m := walk_minutes(route_len(pts), t)
				var back := walk_minutes(route_len(route(wd, str(p.town), wps2[nk], nx.tile)), t + w_m)
				if t + w_m + back + pause > next_m or wps2.size() < 2 or pts.size() < 2:
					break
				segs.append({"a": t, "b": t + w_m, "kind": "walk", "pts": pts, "len": route_len(pts), "in": false})
				t += w_m
				k2 = nk
				cur = wps2[k2]
		else:
			cur = st2.tile
		var pts2 := route(wd, str(p.town), cur, nx.tile)
		var l2 := route_len(pts2)
		var w2 := walk_minutes(l2, next_m - l2 / SPEED)
		var depart := maxf(t + MIN_STAY, next_m - w2)
		if not st2.has("round"):
			segs.append({"a": t, "b": depart, "kind": "stay", "at": Vector2(cur) + Vector2(0.5, 0.5) + (st2.nudge as Vector2), "yaw": float(st2.yaw), "clip": st2.clip, "hold": st2.hold, "in": at_in})
		elif depart > t:
			segs.append({"a": t, "b": depart, "kind": "stay", "at": Vector2(cur) + Vector2(0.5, 0.5), "yaw": 0.0, "clip": st2.clip, "hold": st2.hold, "in": false})
		if cur != nx.tile:
			segs.append({"a": depart, "b": depart + w2, "kind": "walk", "pts": pts2, "len": l2, "in": pts2.size() < 2})
			t = depart + w2
		else:
			t = depart
	p.segs = segs
	p.start = start
	return segs

## Where person `p` is and what they are doing at minute `m` of the day: {vis (out of doors), at
## (float tile), yaw, walk (on the move), clip, hold, seg}.
static func state(wd: Dictionary, p: Dictionary, m: float) -> Dictionary:
	var segs := day_of(wd, p)
	var start: float = p.start
	var mm := m
	while mm < start:
		mm += 1440.0
	while mm >= start + 1440.0:
		mm -= 1440.0
	# a busy day may run a little over: yesterday's last walk is still under way this early
	var over: float = float(segs[segs.size() - 1].b) - (start + 1440.0)
	if over > 0.0 and mm < start + over:
		mm += 1440.0
	var sg: Dictionary = segs[segs.size() - 1]
	for s in segs:
		if mm < float(s.b):
			sg = s
			break
	if sg.kind == "walk" and bool(sg.in):
		return {"vis": false, "at": sg.pts[0] if (sg.pts as PackedVector2Array).size() > 0 else Vector2.ZERO, "yaw": 0.0, "walk": true, "clip": "walk", "hold": "", "seg": sg, "left": float(sg.b) - mm}
	if sg.kind == "walk":
		var pts: PackedVector2Array = sg.pts
		var k := clampf((mm - float(sg.a)) / maxf(0.001, float(sg.b) - float(sg.a)), 0.0, 1.0)
		var want := k * route_len(pts) / Terrain3D.T
		var at := pts[0]
		var dir := Vector2(0, 1)
		for i in range(1, pts.size()):
			var l := pts[i].distance_to(pts[i - 1])
			if want <= l or i == pts.size() - 1:
				dir = (pts[i] - pts[i - 1]).normalized() if l > 0.0001 else dir
				at = pts[i - 1].lerp(pts[i], clampf(want / maxf(l, 0.0001), 0.0, 1.0))
				break
			want -= l
		var role: Dictionary = ROLES[str(p.role)]
		return {"vis": true, "at": at, "yaw": atan2(dir.x, dir.y), "walk": true, "clip": str(role.get("walk", "walk")), "hold": str(role.get("go_hold", "")), "seg": sg, "left": float(sg.b) - mm}
	var clips := str(sg.clip).split("|")
	var ci := int((mm - float(sg.a)) / 9.0 + float(p.seed)) % clips.size()
	return {"vis": not bool(sg.in), "at": sg.at, "yaw": float(sg.yaw), "walk": false, "clip": clips[ci], "hold": str(sg.hold), "seg": sg, "left": float(sg.b) - mm}

## Everybody of the towns in region `area` (of realm data `wd`).
static func of_area(wd: Dictionary, area: String) -> Array:
	var out: Array = []
	for tid in towns_in(area):
		out.append_array(people(wd, tid))
	# (and the people of the road, the High Roads release)
	var cid := camp_of(wd, area)
	if cid != "":
		out.append_array(people(wd, cid))
	return out

## The towns and the camp of region `area`: everywhere in it somebody lives.
static func homes_in(wd: Dictionary, area: String) -> Array:
	var out := towns_in(area)
	var cid := camp_of(wd, area)
	if cid != "":
		out.append(cid)
	return out

## The person standing on (or walking through) tile `tile` of the realm in `wd` at minute `m`, or {}
## (someone indoors is nowhere).  Used for "face one and press Enter".
static func at_tile(wd: Dictionary, tile: Vector2i, m: float, want: Callable = Callable()) -> Dictionary:
	var area := Atlas.owner_id(wd, tile)
	var best := {}
	var bd := 0.75
	var wanted := false
	for p in of_area(wd, area):
		var st := state(wd, p, m)
		if not st.vis:
			continue
		var d := (st.at as Vector2).distance_to(Vector2(tile) + Vector2(0.5, 0.5))
		if d >= 0.75:
			continue
		# (when two stand close, the one an errand of the story still needs is the one he means)
		var w: bool = want.is_valid() and bool(want.call(p))
		if (w and not wanted) or (w == wanted and d < bd):
			bd = d
			best = p
			wanted = w
	return best

# ---------------------------------------------------------------- what they say
## Words for every kind of person ("%s" is how they address Lin Feng).
const LINES := {
	"farmer": ["The rice wants water and my back wants rest. The rice wins, it always wins.", "Plant on the right day and the land does the rest. Plant on the wrong day and you do the rest.",
		"My grandfather farmed this field, and his grandfather. None of them ever met a cultivator who stopped to talk. Good day to you, %s.",
		"See that cloud? Rain by evening. My knee says so, and my knee is never wrong.", "Hoe, hoe, hoe. Somebody has to feed the immortals' disciples."],
	"fisher": ["Fish bite at dawn and at dusk. In between they sit on the bottom and laugh at us.", "Calm water today. The river is in a good mood; I'd best not ask it for too much.",
		"Fresh carp! Well, fresh this morning. Fresh enough for you, %s.", "My father fished this bank. He said the river talks if you are quiet enough. I'm still waiting."],
	"merchant": ["Silk from the south, tea from the hills, needles from Tushan! For you, %s, a price that would make my mother weep.", "Business is good when the roads are open. The roads have been open a while now. Thank you for that.",
		"Look, don't touch. Touch, buy. Buy, and I'll throw in a smile.", "Three coppers. Two for you. Fine, take it, take it, you're ruining me."],
	"porter": ["One more load and then noodles. One more load and then noodles.", "Mind your back, %s! Big load coming through.", "A shoulder pole is a bridge with two ends and me in the middle.",
		"The caravan's late again. The caravan is always late. I'm the only thing on this road that's ever on time."],
	"child": ["Are you a real cultivator? Can you fly? Fly! Fly now!", "I'm not allowed past the well. I go past the well all the time.", "Teacher says if we learn the thousand characters we can read anything. I know forty.",
		"Play with us! You can be the dragon. You have to be the dragon, you're the biggest.", "My kite went up higher than the temple roof and nobody believed me."],
	# the people of the road (the High Roads release)
	"woodcutter": ["Take the dead wood and the crooked wood. The straight ones have somewhere to be in a hundred years.", "An axe wants a hundred strokes a day or it sulks. So does a woodcutter.",
		"I knew a man once who stopped to watch two old fellows play weiqi in a cave. You have heard that one? Then you know why I do not stop.",
		"Listen. Hear it? No? Neither do I. That is what I come up here for, %s.", "Wood warms you three times: cutting it, carrying it, and burning it. The carrying is the one nobody sings about."],
	"herbalist": ["This one for fevers, this one for sleep, this one I do not know yet. I will know by the evening, one way or the other.", "The good roots grow where the going is bad. I have never once found ginseng beside a road.",
		"Do not pull it. Dig round it, lift it, thank it. Then it works.", "The Divine Farmer tasted a hundred herbs in a day and was poisoned seventy times. I taste one a day. I intend to be old.",
		"The higher the crag, the stronger the leaf. And the thinner the gatherer. Look at me."],
	"angler": ["I have fished this water for thirty years with a straight hook. I am not here for the fish, %s.", "They say the Grand Duke fished three feet above the water, and what he caught was a king. I would settle for a carp.",
		"Shh. No, it has gone. It was never there. Sit down anyway.", "The fish know the hour better than the watchman. Dawn and dusk. The rest of the day is for thinking.",
		"A line in the water is a question. You do not always want the answer on the bank beside you, flapping."],
	"pedlar": ["Needles, thread, salt, a comb, a mirror no bigger than your thumb! I carry a whole street on one shoulder.", "The road between two towns is the only place where neither of them can tell me the price.",
		"I have sold the same kettle in six valleys. Bought it back in four. It is a good kettle.", "You want news? News is free. It is the salt that costs, %s.",
		"Forty li today. My legs say fifty. My legs have always been liars."],
	"hunter": ["Downwind and quiet. No, the other downwind.", "I take what the hills can spare, and I ask first. You would be surprised how often the answer is no.",
		"There is a pack that sleeps through the noon in that hollow. I leave them their noon; they leave me my nights.", "A bow is half a year in the making and one breath in the using. I think about that a good deal, up here.",
		"Tracks, %s. Two days old. Something that walks like a man and is not one. I would go round, myself."],
	"pilgrim": ["Up before the sun, to the top by the time it is over the ridge, down by noon. Every day. The mountain has not noticed yet.", "It is not the top one goes for. It is the going. But I notice everybody stops at the top.",
		"I am walking to all the great mountains before I die. I have done one. It was this one.", "The cairn up there? Put a stone on it when you pass. Nobody knows who put the first.",
		"My knees pray on the way up and curse on the way down. Heaven, I am told, hears both."],
	"soldier": ["Left foot. They say left foot and forty of us put down forty different feet. Lady Hao has stopped shouting about it. That is worse.", "I came with a hoe and they put a point on it. It is still a hoe. I have told nobody. It digs a very fine latrine.",
		"Master Sun says the best battle is the one nobody fights. I said, then why are we up before the cocks? He wrote that down. I do not know if it was a compliment, %s.",
		"The camel men will not march behind the horse-folk and the horse-folk will not march in front of the haulers. We go out in a ring now. It turns out a ring has a name, and it is in the book.",
		"My mother sent a straw cape and a note. Wear it. The note is longer than that, but that is what it says."],
	"musician": ["Six airs, and they are all one song. I have played forty years and never noticed. The blind master heard it in a breath. I was a little put out.", "A drum is honest. You cannot play a drum flat. You can only play it late, and I have never been late in my life, whatever the stage manager tells you.",
		"We have died in a hundred battles on that stage, %s, nightly, and got up for the next act. I mean to tell the clay ones how it is done.", "The bell was a hair flat for a month and I retuned everything I own to it, out of politeness. Now it is right again and I am a hair flat. That is a musician's life.",
		"Somebody under the hill is keeping time with us in the evenings. One beat, on the first of the bar. It is never wrong. The flautist wants to know if it is in the guild."],
	"hermit": ["Somebody came up. Well. Sit, since you have. The view is not mine to charge for.", "I came up for a season, forty years ago. It has been a long season.",
		"Below they ask what I do all day. I look. It takes all day.", "The clouds come to me now. When I was young I went to them.",
		"You climbed with your hands, %s? Good. Those who fly up never see what the mountain is made of."],
	"elder": ["In my day the roads were full of bandits and the bandits were full of manners.", "Sit a while, %s. Young people are always walking somewhere. Where is everybody walking?",
		"I've seen sixty springs. This one is the best. I say that every spring.", "Weiqi is like life. You think you're surrounding them, and they're surrounding you."],
	"monk": ["Amituofo. The sweeping is the practice, and the leaves are the teachers.", "May your road be smooth, %s, and when it isn't, may you be.", "Every bowl of rice holds the work of a hundred hands. Eat slowly."],
	"guard": ["Move along. Kindly. Move along kindly.", "Quiet watch. I like a quiet watch.", "Gate opens at dawn, shuts at dusk. Unless you're %s, apparently. Then it opens whenever."],
	"watchman": ["Dry weather, mind your fires! The %s watch, and all is well!", "Lock your doors, bank your stoves, and mind your fires!", "I walk the streets while they sleep. Somebody has to hear the town breathe."],
	"scholar": ["The ancients say: to know the road, ask the one walking back. You've walked back a great deal, %s.", "I write letters for those who can't. Mostly love letters. Mostly to the same girl.",
		"Five times I sat the examinations. Five times I failed. I am thinking of becoming a poet instead, which requires only failing beautifully."],
	"cook": ["Taste this. No, taste it. Too much salt? There is no such thing as too much salt.", "The stove is lit before the sun and goes out after the moon. So do I.", "Dumplings at noon! Steamed buns at dusk! Complaints never!"],
	"washer": ["Scrub, rinse, wring, hang. If the river were soap I'd be a rich woman.", "Did you hear? Old Zhou's son is courting the dyer's girl. Don't tell anybody. Tell everybody.",
		"Mind the washing, %s. If you walk through it you're washing it again."],
	"youth": ["Off to the fields, then the forge, then the fields. Tomorrow I'll be rich and the day after I'll be tired.", "My master says I've got good hands and no sense. Half right is a start.",
		"Is it true you've fought dragons? Just the one? Still, that's one more than me."],
	"lamplighter": ["One lamp at a time. You'd be surprised how much dark one lamp can hold back.", "At dusk I light them, at dawn I put them out. In between I sleep like a cat.",
		"The children follow me round at dusk. They think I'm lighting the stars."],
	"smith": ["Hear that ring? That's a good casting. The bad ones go thunk.", "The pits have been hot since Yu the Great. We'd hate to be the ones who let them cool.", "Bronze is patient. Bronze waits for you to be ready."],
	"disciple": ["Senior Brother Lin! Forgive me, I mean... Lord Lin? What do we call you now?", "I swept the steps this morning. I thought of you. Everybody who sweeps them thinks of you.",
		"Sword form, sword form, rice, sword form, scripture, rice, bed. I've never been happier.", "They say you were the sweeper once. I'm the sweeper now. There's hope for me."],
	"servant": ["The sect eats like an army and leaves like a storm. Lucky I like cooking for armies.", "Water from the well, firewood from the shed, and back again. The mountain is very tall today."],
}
## words for the hour (by Clock.part)
const HOUR_LINES := {
	"dawn": ["You're up early, %s. Even the roosters are still yawning.", "First light. The best part of the day: nobody has done anything wrong yet."],
	"morning": ["A fine morning. Too fine to waste talking. Well, a little talking.", "Morning, %s! Eaten yet?"],
	"noon": ["Noon already? Then it's time to eat. Have you eaten?", "Hot one today. Stay in the shade, %s."],
	"afternoon": ["The long part of the afternoon, when the work is half done and the other half looks longer.", "Afternoon, %s."],
	"dusk": ["Lamps soon. Then supper. Then sleep. The best three words in the world.", "Look at that sky. Even the immortals would stop for a sky like that."],
	"evening": ["Evening, %s. The tea house is still open, if you're thirsty.", "Long day. Good day. Home now."],
	"night": ["Late to be about, %s. The streets are the watchman's now.", "Shh. The whole town's asleep, and I'm only half awake."],
	"late night": ["Who's there? Oh, it's you. Mind the dark, %s.", "Can't sleep either? The night's very big tonight."],
}
## the shades of Youdu, whose day is the night
const SHADE_LINES := ["Good evening. That is to say, good morning. We keep the hours backwards here; the living find it restful.", "The lanterns of Youdu never go out. Neither do we. It is only our names that went out.",
	"I am waiting until I am ready to be born again. Some of us have been waiting a very long time. The waiting is rather pleasant.", "You are warm, %s. We can feel it from across the street."]
const PEOPLE_LINES := {
	"yumin": ["We glide down to market and walk home. Nobody has ever invented a way to glide up.", "Mind the feathers, ground-walker. %s, forgive me. Old habits."],
	"jiaoren": ["If I cry it is only to pay the rent. Pearls are pearls.", "The black water is calm tonight. It is always night down here; we judge by the springs."],
}

## What person `p` says to Lin Feng now: a line of their own, now and then a word for the hour, the
## talk of the town about what he has done, or what the realm he has reached does to people.
static func line(p: Dictionary, g) -> String:
	var addr: String = g.address()
	var h := Clock.hour(g)
	var n := int(g.folk_talk.get(str(p.id), 0))
	var pool: Array = []
	if bool(p.night) and str(town(str(p.town)).race) == "shade":
		pool.append_array(SHADE_LINES)
	var race := str(town(str(p.town)).race)
	if PEOPLE_LINES.has(race):
		pool.append_array(PEOPLE_LINES[race])
	pool.append_array(LINES.get(str(p.role), LINES.youth))
	pool.append_array(HOUR_LINES.get(Clock.part(h), []))
	# the Six Hearths (cultures.gd): the first thing anybody says to a stranger is their own hearth's
	# way of saying hello, and after that its customs come up as often as their trade does
	var hid := Cultures.of_town(str(p.town))
	if hid != "":
		pool.append_array(Cultures.HEARTHS[hid].lines)
		if n == 0 and not new_year(g) and Clock.frozen(g) == "":
			pool = [str(Cultures.HEARTHS[hid].lines[int(p.seed) % (Cultures.HEARTHS[hid].lines as Array).size()])]
	if new_year(g):
		# New Year's Day: everybody has the same thing to say, and says it
		pool = (CHILD_NEW_YEAR if bool(p.kid) else NEW_YEAR_LINES).duplicate()
	elif Clock.frozen(g) == "night":
		pool = ["Bang it! Louder! Nian's coming!", "The night won't end. So we won't stop. That's how it works, isn't it?", "Stay with somebody tonight, %s. Nobody alone. That's the rule."]
	var s: String = str(pool[(int(p.seed) + n * 3) % pool.size()])
	# the talk of the town: the latest boss Lin Feng put down, now and then
	if n % 3 == 2:
		var last := ""
		for i in range(g.timeline.size() - 1, -1, -1):
			var tx: String = str(g.timeline[i].text)
			if tx.begins_with("Defeated "):
				last = tx.trim_prefix("Defeated ")
				break
		if last != "":
			s = "Is it true what they say? %s, beaten, and by you! The whole town has been talking of nothing else." % last
	if s.contains("%s"):
		if s.contains("The %s watch"):
			var wt := Clock.watch(h)
			s = s.replace("The %s watch", "The %s watch" % (Clock.WATCHES[wt] if wt >= 0 else "day"))
		if s.contains("%s"):
			s = s.replace("%s", addr)
	return s

# ---------------------------------------------------------------- Part XVI: the New Year
## the town each of the people Lin Feng reminds of the old ways belongs to (s_p16_rally)
const RALLY_TOWN := {"granny_wen": "qingshi", "watchman_zhou": "yanggu", "postmaster_lu": "cloudfoot", "lockkeeper_qian": "longmen",
	"caster_wei": "tushan", "well_keeper_zhaya": "shazhou"}
const NEW_YEAR_LINES := ["A good new year to you, %s! May you prosper!", "Every door in town is red this morning. Look at it! We haven't had a red door in three years.",
	"Did you hear us last night? That was all of us, every pot in the house. My arms still ache.", "Happy new year! Have you eaten? Have a dumpling. Have two.",
	"The old year's gone up the chimney with the Kitchen God. Good riddance to it, and welcome to this one."]
const CHILD_NEW_YEAR := ["I've got new clothes! Red ones! Look!", "I stayed up all night! Well, nearly all night.", "Granny says if you sweep today you sweep the luck away, so I'm not sweeping anything all year."]
const HONGBAO_LINES := ["A red envelope? For me? Thank you! Happy new year, big brother cultivator!", "Ooh. Ooh! I'm going to buy a whole sugar figure. A dragon. No, two dragons!",
	"Thank you! I'll keep it under my pillow. That's where you keep luck.", "Mother! Mother! The sweeper gave me a red envelope! The real one! The sky one!"]

## What a townsperson says as Lin Feng goes by: a word for the hour, his name or his title.
const GREETINGS := {"dawn": ["Up early!", "Morning!"], "morning": ["Morning, %s!", "Good morning!"], "noon": ["Eaten yet?", "Hot one!"],
	"afternoon": ["Afternoon!", "%s!"], "dusk": ["Evening!", "Lamps soon!"], "evening": ["Evening, %s.", "Good evening!"],
	"night": ["Late, isn't it?", "Mind the dark!"], "late night": ["Who's there?", "Can't sleep?"]}

static func greeting(p: Dictionary, g) -> String:
	if new_year(g):
		return "Happy new year!"
	if Clock.frozen(g) == "night":
		return "Louder!" if int(p.seed) % 2 == 0 else "Bang it!"
	if bool(p.kid):
		return ["Hello!", "It's %s!" % ("her" if Fashion.fem(g.hero) else "him"), "Can you fly?"][int(p.seed) % 3]
	# the Six Hearths (cultures.gd): every other grown person hails in their own hearth's way
	var hid := Cultures.of_town(str(p.town))
	if hid != "" and int(p.seed) % 2 == 1:
		return Cultures.hail(hid, int(p.seed) / 2)
	var opts: Array = GREETINGS.get(Clock.part(Clock.hour(g)), ["Hello!"])
	var s: String = str(opts[int(p.seed) % opts.size()])
	# (the hero's own family name, as the player chose it: a Label3D does not go through UI.named)
	var fem: bool = Fashion.fem(g.hero)
	return s.replace("%s", (("Lady " if fem else "Lord ") + str(g.hero.get("family", "Lin"))) if g.realm() >= 4 else ("young mistress" if fem else "young master")) if s.contains("%s") else s

## Whether townsperson `p` is of kind `role` ("child" means any child of the towns).
static func is_role(p: Dictionary, role: String) -> bool:
	return bool(p.kid) if role == "child" else str(p.role) == role

## Whether townsperson `p` lives where step `s` asks for its people (Part XVIII: an errand among the
## people of one hearth names its town; the older errands are for anybody's).
static func in_town(p: Dictionary, s: Dictionary) -> bool:
	return not s.has("town") or str(p.town) == str(s.town)

static func hongbao_line(p: Dictionary) -> String:
	return str(HONGBAO_LINES[int(p.seed) % HONGBAO_LINES.size()])

## What Lin Feng says to a townsperson for a step of the story, what they say back, the news of it
## and what it costs (Part XVI: red paper from the merchants, a fish for the reunion table, red envelopes for the
## children, the lantern riddles).
const ERRANDS := {
	# Part XXV (hold.gd): the people of the road asked to come and live in the town that is the hero's own
	# (`settle`: whoever is asked comes, with their kin)
	"s_p25_cutters": {"ask": "There is open ground on the east shoulder of Azure Cloud Mountain, and four posts in it. It wants somebody who knows timber. Will you come and live there?", "price": 0, "toast": "%s will come to Guiyun", "settle": true,
		"lines": ["Four posts? Who set them? ...Never mind. I can see from here they are wrong. Yes. I shall bring my brother and the long saw. Somebody must.",
			"Live in a house. I have built forty and slept in none. Is it true there are no debts written yet? Then I shall come before they think of some.",
			"On the sect's mountain? That is good pine, the east shoulder. Nobody has been let cut it in three hundred years. ...You are letting me. I shall be there before you are.",
			"A town with nothing in it yet. Then whoever comes first says where the lane goes. I have opinions about lanes. I shall come."]},
	"s_p25_pedlars": {"ask": "There is a town called Guiyun on the east shoulder of the mountain, with a well and a granary and nobody to buy salt from. Will you lay your mat there?", "price": 0, "toast": "%s will lay a mat at Guiyun", "settle": true,
		"lines": ["A town with no pedlar in it? There is no such thing. There is only a town that the pedlars have not found. Where did you say?",
			"I have walked past ten thousand doors and nobody ever offered me one. Say the name again, slowly. I want to hear what it sounds like when it is where I live.",
			"Is there a steelyard? Whose? ...The steward's, and he lets it be checked? I shall come and check it. I shall come and check it every morning for the rest of my life.",
			"Salt, needles, thread, a little news. That is a town, that is: it is only that the houses hold still. Yes. My knees will thank you."]},
	# Part XXVI: the herbalists of the road, asked to go and learn from the physician at the springs while there is time
	"s_p26_pilgrims": {"ask": "An old man below Qingshi teaches five beasts at dawn, the tiger, the deer, the bear, the ape and the bird, so that the body does not rust. Will you carry them to the shrines you pass?", "price": 0, "toast": "%s will carry the five frolics along the road",
		"lines": ["Five beasts at every shrine? I walk a thousand li a year and my knees have filed a complaint at each of them. ...The bear, you say. Show me the bear again.",
			"I carry the sutras, the incense and my grandmother's bones. Five animals weigh less than any of those. Yes. I shall do the deer at the Western Peak and see who joins in.",
			"A pilgrim who stops walking is a man sitting in a temple. I know that one already. The ape I like: you reach for what is not there and it turns out to be the next step.",
			"At the shrines they ask us to pray for the sick. Now I shall be able to tell them to stand up first. They will be offended, and better by the spring."]},
	"s_p26_fish": {"ask": "The cook of the court at Tushan is to feed the keepers of all six hearths at one table, and an ox is not enough. Will you take him your catch?", "price": 0, "toast": "%s will take the catch to Tushan",
		"lines": ["Six hearths at one table? They will argue about the fish. They always argue about the fish. ...Tell him to cook it plainly and they will argue less. I shall bring the carp.",
			"The cook who cut the ox without touching a bone? Then he will not waste my fish. I have never once given a fish to a man who would not waste it. I shall go and watch him.",
			"I have kept a pool of eels for the day somebody asked. Nobody ever asked. ...Yes. Yes, I shall bring them. Mind your feet in the kitchen; one of them is called Old Minister and bites.",
			"Fish for the court. My grandmother sold fish at the gate of the court for forty years and was never let in. I shall go in by the kitchen door and tell her so at the Qingming."]},
	# Part XXVII (the Heavy Road release): Tao Kan's thrift, asked of the woodcutters of the road
	"s_p27_ends": {"ask": "The governor in the Silk Woods wants what woodcutters throw on the fire: the sawdust, and the butt-ends of the bamboo. Will you keep yours for him?", "price": 0, "toast": "%s will keep the sawdust and the butt-ends",
		"lines": ["Sawdust? He wants my sawdust? ...He is the one with the full granary. I had rather not understand a man like that and do what he says than understand my neighbours and starve. I shall keep it.",
			"The butt-ends make a good fire. But there is a deal of wood about, and I never knew a governor ask for rubbish without a reason. In sacks, you say. By the door.",
			"My father kept everything. String, nails, the feet off a broken pot. We laughed at him. When he died we found a use for all of it inside the year. Tell the governor yes.",
			"I have carried wood forty years and never once thought about what fell off the saw. It weighs something, I suppose. Everything does. Very well: his it is."]},
	"s_p26_herbs": {"ask": "There is a physician at the hot springs of Glowcap Vale who opens people without hurting them, and he is old. Will you go and learn from him while there is time?", "price": 0, "toast": "%s will go to the springs to learn",
		"lines": ["Hua Tuo? At the springs? I walked three hundred li to see him once and he had gone the day before. ...I am going now. Do not stop me to talk.",
			"Opens them without hurting them. I have heard that. I have also heard a great many things about a great many physicians. I shall go and see whether this one sweats when he works. The good ones do.",
			"Learn? At my age? ...My hands are not as steady as they were. Perhaps that is the reason to go: to learn the part of it that is not in the hands.",
			"He makes them get into the water first? In their underclothes? Then he knows what he is about. Half of any cure is getting the patient to stop pretending. Yes. I shall go."]},
	"s_p25_herbs": {"ask": "Guiyun has sixty households now and nobody who can set a bone. There is a north slope above it that has never been picked over. Will you come?", "price": 0, "toast": "%s will come to Guiyun", "settle": true,
		"lines": ["Never picked over? On a mountain with a sect on it? They gather nothing but dew up there. ...I shall want a drying-rack facing south and to be left alone. Yes.",
			"Sixty households. That is four broken bones a year, a difficult birth, and somebody who has eaten the wrong mushroom. You have been lucky so far. I shall come before the luck goes.",
			"Is there water? Good water? Then I can make most of what they will need. The rest is telling them to lie down, and nobody listens to that from a neighbour. They may from a stranger.",
			"I have been watching your smoke from here. More of it every month. I wondered when somebody would come and ask. I have had my basket packed since the spring."]},
	"s_p25_hermits": {"ask": "There is a hall at Guiyun with nine brooms in it and a board over the door, and children in it wanting to be taught. Will you come down?", "price": 0, "toast": "%s will teach at the Hall of the Broom", "settle": true,
		"lines": ["Come down. To a town. With children in it. ...What do they want to be taught? Everything? Hm. That is at least the right thing to want. One season. I shall see.",
			"I came up here forty years ago because nobody would listen. You say there is a room full of people who have asked to. I do not believe you. I shall come and look.",
			"Brooms. I heard about the brooms. It is the only sensible thing I have heard of a school in my lifetime. Who thought of it? No, do not tell me. I shall come and disagree with him.",
			"A hall. With a door, that I could shut? And nobody minds if I say nothing for a week? Then yes. The young learn most from somebody who is plainly not trying to teach them."]},
	# Part XXIII: the players of the Drum Tower quarter, asked to teach the levy the airs of the land
	"s_p23_songs": {"ask": "The levy can march to a song and cannot sing one. Will you teach the companies the airs of the six hearths, of an evening?", "price": 0, "toast": "%s will teach the levy to sing",
		"lines": ["Teach ploughmen to sing? They sing already. They sing like a gate. ...Yes, very well. I have taught worse. I have taught an examiner's nephew.",
			"The airs, every one of them, to the whole host. In a week. Do you know how long it took me to learn to breathe? Never mind. Tell them to bring their own tea.",
			"I shall want the horse-folk at the front, where I can see them. They hum. One cannot stop a hummer; one can only aim him.",
			"For the host? Of course. Nobody ever asked a player to help win a war. They ask us afterwards to say who won it. I should like, once, to have been there."]},
	"s_p16_paper": {"ask": "Red paper, for the New Year couplets on the sect's doors. As much as you can spare.", "price": 120, "toast": "Red paper bought from %s",
		"lines": ["Red paper! The first anybody has asked for all year. Take the whole roll. No, take two. Somebody should have a New Year.", "Red paper, gold edges, the good stuff from Tushan. For the sweeper who swept the sky, a third off.",
			"For couplets? Then you'll want this too: a sheet of gold paper for the Fu on the door. Upside down, mind. The luck's arrived, see?", "I'd forgotten I had it. It was under the jars of nothing we've been selling all year. Here. Happy new year, early."]},
	"s_p16_fish": {"ask": "A fish for the reunion table, so the year has more than enough. The best you have, please.", "price": 80, "toast": "A New Year's fish bought from %s",
		"lines": ["A carp from below the Dragon Gate: one that didn't jump. Don't let them finish it at the table, mind. Leave some over for next year. That's the whole point.",
			"For the reunion dinner? Then you want the one with the red tail. Luckiest fish in Longmen, and it knows it.",
			"Every year, more than enough: that's what the fish is for. This one was more than enough trouble to catch. Take it, take it.",
			"I kept it in the tank all week for somebody who'd ask nicely. Head to the guests, tail to the host, and nobody turns it over.",
			"The river gave back everything it took from us this year. The least I can do is give you its best fish. A good new year, sweeper.",
			"Twice as heavy as last year's, and last year's was a good one. That's a sign, that is."]},
	"s_p16_riddles": {"ask": "A riddle on your lantern? Let me try it.", "price": 0, "toast": "Guessed %s's lantern riddle",
		"lines": ["\"Red outside, a fire inside, it walks on a stick and never takes a step.\" A lantern, you say? First time! A sweet dumpling for that.",
			"\"It has a hundred teeth and never bites, and it works every morning and never tires.\" A broom! They said the sweeper would get that one.",
			"\"Round as the moon, eaten on the fifteenth, sweet in the middle.\" Tangyuan, yes. You'll be eating them tonight. Take two.",
			"\"Everybody waits up for it, it comes in one night, and nobody sees it arrive.\" The New Year! The last one to guess that was a scholar from Tushan, and he took an hour.",
			"\"Pasted on the door upside down, so that it has arrived.\" Fu, the luck! You had it before I'd finished. Have a sugar figure.",
			"\"The sun's sister, out all night, with a different face every evening.\" The moon. Chang'e would be pleased with you. Keep the lantern, it's yours."]},
	"s_p16_hongbao": {"ask": "A good new year to you. Here: for luck.", "price": 0, "toast": "A red envelope for %s", "lines": HONGBAO_LINES},
	"s_p16_elders": {"ask": "A good new year, Grandfather. Grandmother. Long life, and good health in it.", "price": 0, "toast": "New Year respects paid to %s",
		"lines": ["Long life? I have had a long life, young man. What I want is a short winter. Still: thank you. Here, take a sweet.",
			"Kneel, kneel, a little bow is enough, you'll ruin your trousers. A good new year to you too. Come back next year and I'll still be here. I always am.",
			"In my day the young ones came round with oranges. You came round with nothing and I don't mind at all. Sit a while.",
			"Good health in it! At my age I'll take the health and you can keep the long life. Happy new year, child.",
			"Another year! I've seen eighty of them. This one began with dragons and ended with dumplings. That's the right way round."]},
	# Part XVIII (the New Fire release, cultures.gd): the ways of three of the Six Hearths, done their way
	"s_p18_valley": {"ask": "Have you eaten? ...No, wait. That is yours to ask.", "price": 0, "toast": "Ate cold gruel at %s's table",
		"lines": ["Have you eaten? No? Good. Sit. It's cold, mind. The stove's been sulking for three days and I've given up coaxing it.",
			"Have you eaten? You have not. Nobody who says yes is telling the truth. Here: gruel, mustard, half a duck egg. Cold, and no worse for it.",
			"Eat first. Then tell me why the sweeper is going round the village at supper time asking for cold rice. Is it a cultivation thing?",
			"My mother kept the cold-food day every year. Fire out, cold rice, and she'd say: now you know what it's for. I thought she was only being difficult.",
			"Have you eaten? Sit down. Don't stand your chopsticks in it, there's a good child. You were always doing that. Granny Wen used to slap your hand.",
			"Cold. I know. I held the pot over the fire an hour and it came off the way it went on. Eat it anyway; the mustard is the good part.",
			"You'll have a bowl with us. Don't argue. A person who leaves a Qingshi kitchen empty takes the luck with them, and we haven't much to spare this month."]},
	# Part XIX (the Hundred Works release): a sack carried down to Gongshu Ban's mill, and a load shouldered
	# on the well-road now that the wooden oxen have walked off
	"s_p19_farm": {"ask": "Going down to the new mill? I will carry a sack with you.", "price": 0, "toast": "Carried a sack to the mill with %s",
		"lines": ["Take that end. It's nothing, a sack; I used to carry four. Used to pound them too, half the night. Now I carry one down the hill and it's flour before I've got my breath.",
			"Have you eaten? Then eat this; it's the new rice. White as a tooth. My mother would have wept. ...I don't know if she'd have wept for joy, mind.",
			"You know what I did yesterday afternoon? Nothing. I sat on the wall. I've never sat on that wall in forty years. I didn't know what to do with my feet.",
			"The children run down to watch it turn. They used to run away when it was time to pound. I can't decide if that's better.",
			"My wife says the house is too quiet without the pestle. I said, then sing. She said, at nothing? You can't sing at nothing.",
			"Old Hanyin down in the cabbages won't have it near him. We laugh at him. Then at night we lie and listen to it going round, and nobody laughs.",
			"It never gets tired, that's the thing. I keep waiting for it to get tired. You get used to a mill that sighs now and then."]},
	"s_p19_ferry": {"ask": "The paddle-boats are gone. Shall I take the other pole?", "price": 0, "toast": "Poled a boat across with %s",
		"lines": ["Smooth water. Right foot first, sit low, and when I say push, push. Not before. Before is how you meet the pile.",
			"A pole! I have not had a pole in my hands since the spring. Look at that: the callus is still there. The hand remembers what the head was glad to forget.",
			"Six paddle-boats, all gone upriver in a night. My husband says good riddance. He said it very quietly, mind; he was the one who wanted them.",
			"You push and I steer. Feel that? That is the current taking her head. A wheel never told me that. A wheel just went.",
			"Mind the fish. No, do not turn it over; lift the bone. And do not say the word. We are in the middle of the river."]},
	"s_p19_lamps": {"ask": "First light to you. Shall I trim one with you, by hand?", "price": 0, "toast": "Lit a lamp by hand with %s",
		"lines": ["First light to you. Trim it square, not to a point; a point smokes. My mother would have boxed my ears for that wick.",
			"Pinch the taper, do not blow it. There. You see the difference? That lantern there goes round by itself, and I have not looked at it once since you lit this.",
			"The paper horses were a marvel for a week. Then I noticed they never get anywhere. A flame at least gets shorter.",
			"No haggling over the oil, it is the first sale. And none over the wick either. You may haggle over the tea afterwards, like a civilised person."]},
	"s_p19_founders": {"ask": "The river's bellows are stopped for the day. Shall I take the other handle?", "price": 0, "toast": "Blew a pit by lung with %s",
		"lines": ["May your metal run clean. Take that handle. Down together, up together, and do not whistle; you know better than that by now.",
			"By lung! Auntie Rong's order, one day in the year. I thought she had gone soft in the head. Feel that, though. You can feel the fire answer. The river never told me it answered.",
			"My grandfather blew this pit for fifty years and was deaf in one ear from it. He would laugh himself sick to see us doing it for a holiday.",
			"Slower. It is not a race; the bronze does not care how tired you are. There. Hear it? When the note drops, it is ready. I had forgotten there was a note."]},
	"s_p19_porters": {"ask": "The oxen have walked off into the sand. Shall I take a load with you?", "price": 0, "toast": "Shouldered a load with %s",
		"lines": ["Take the left pole, mountain friend. I have not carried since the wooden oxen came. Look at my shoulder. Soft as a merchant's.",
			"Forty oxen of wood, and one night they all stood up and walked west. With the panniers on! Aysha says a thing that never eats is bound to want something else.",
			"Have you drunk? Drink first. ...I had forgotten that, do you know? The oxen never drank. A month, and I had forgotten to ask a man if he had drunk.",
			"There is a song for this hill. Step, step, breathe; step, step, curse. My father taught me the first verse and I made up the rest."]},
	# Part XX (the Hollow Hills release): a basket of Yu Gong's mountain, a prop set at the pit-head, the
	# first water of a well that has come back, and a boat bailed out now the river is up
	# ---- Part XXI (the Hundred Arms release)
	# Part XXII: the people of the road (the High Roads release): what calls the woodcutters, what the anglers
	# saw float by, what the hermits watched go up, and the pilgrims told that the tops are there again
	"s_p22_cutters": {"ask": "Something has been calling the cutters by name at night. Whose voice did you hear?", "price": 0, "toast": "Heard from %s whose voice it was",
		"lines": ["My wife's. From up the slope, clear as a bell: come to bed. She is in Qingshi with her mother. And she has never in her life told me to come to bed; she tells me to mind my boots. I pulled the blanket over my head and counted my axe-strokes till dawn.",
			"The foreman's. Calling the tally, the way he does. I very nearly answered: here. I had my mouth open. Then I remembered he lost his front teeth at the New Year and whistles on every name, and this one did not whistle.",
			"My brother's. He went up for wood six winters ago in the snow and we found the sledge. It had his voice, and it had my name, and it put them together the wrong way round. He never called me by it. He called me Second.",
			"A child's. I have no child. It said my name and then it said: carry me. I am a strong man and I have never been so frightened of anything so small. In the morning the salt was gone and there was one footprint in the ash. The left.",
			"I did not hear a voice. I heard my own axe, up on the height, chopping, at midnight, with my axe lying beside me. The rhythm was right. Whatever it is has been listening to me work. I find I mind that more than the salt."]},
	"s_p22_anglers": {"ask": "Have you seen anything come down the water these last days that was not a fish?", "price": 0, "toast": "Heard from %s what came down the stream",
		"lines": ["Paper. Good paper, folded like a little boat, with writing. I let it go by. A man who fishes with a straight hook does not go grabbing at other people's letters. It bumped my float, mind, and I took that as a bite, and I was pleased for a moment.",
			"A will. I read a little of it, I confess. It left a horse to a nephew and a library to nobody, because, it said, nobody deserved it. Very fine hand. It got less fine towards the bottom, as though the table were moving.",
			"Poems, I think. Short lines. I cannot read, but I know the shape of a poem when it floats past; it has more edge to it than a letter. I dried one on a rock. I am using it to wrap bait. Do not look at me like that, it is good paper.",
			"Seven of them, one behind another, like ducklings. All addressed the same way; I had the pedlar read me the top line. To posterity. I do not know the gentleman. I put them back in the water. They seemed to know where they were going.",
			"A leaf with writing on. Not paper: a fig leaf, a big one, and the writing scratched with a thorn. It said only: are you coming. I have had that leaf in my hat three days. I do not know why I cannot throw it away."]},
	"s_p22_hermits": {"ask": "You have been up here the whole time. What have you seen go by?", "price": 0, "toast": "Heard from %s what went up the great peak",
		"lines": ["Shut? Were the tops shut? There was cloud. There is often cloud. I sat in it. ...What I did see, three nights running, was lights on the great peak above your sect. Going up, in a line, very slowly. Too slowly for men. I thought: somebody is moving house.",
			"A week ago, nothing. That was pleasant. Since then, stones. Tall ones, with writing on, walking up the eighteen bends by torchlight with nobody carrying the torches. I have been a hermit for forty years to get away from people's names, and now they come up by themselves.",
			"Smoke. Not cook-fire smoke: the heavy kind, from paper. It hangs in the gullies over there and mutters. When the wind is right I can make out words. All under heaven is at peace. It has been saying that for two thousand years and has not once looked down to check.",
			"You climbed. Good. I knew somebody had; the mountain changes its mind about a person who comes up that way. As for what went by: a great many things in a great hurry to be at the top of something. They went straight past me. I am only at the top of this.",
			"Kites! I have seen kites. In my sky, at my age. A pedlar went by yesterday at the height of my knees, singing. I did not know what to do. I waved. ...And at night, on the big one over there: torches, and stones walking. I liked the pedlar better."]},
	"s_p22_pilgrims": {"ask": "The tops are there again. All of them. You can go up.", "price": 0, "toast": "Told %s the tops were back",
		"lines": ["Are they? Good. I went up this morning anyway, as far as there was, and came down, and said my prayer at the bottom to the place where the top would have been. It heard, I think. It is not so particular as people suppose.",
			"I knew. My knees told me before you did: they began to complain a bend earlier than they have all week, which means the mountain has got longer again. Thank you for coming to say so. People do not usually come and tell a pilgrim things. They sell him things.",
			"Back? They never went, young master. A top is not a thing that can be taken away; it is only where the going stops. Nine days I went up into that cloud and nine days I stopped somewhere. That was the top, each time. You will see it when you are older and slower.",
			"Then I shall take my stone up tomorrow. I have one from my own doorstep, four hundred li off. I was beginning to think I should have to carry it home again, and I did not know how to explain that to the doorstep.",
			"Thank Heaven. Not for my sake; I should have gone on trying until I died, and enjoyed it. For the hermit's. He has not said so, but I think he was lonely up there with nobody arriving out of breath to be told to sit down."]},
	"s_p21_cast": {"ask": "Pouring? I will stand by the mould and watch your hands.", "price": 0, "toast": "Stood at the mould with %s",
		"lines": ["It was to be a bell. Look at it. I did not turn my wrist. ...I did. I felt it go. My brother-in-law has the next yard and a temper, and I was thinking of him, and it ran long.",
			"A ploughshare, the order said. That is no ploughshare. I have poured forty years and never once made a thing I did not mean. Do not tell Auntie Rong. She will know by the sound of it anyway.",
			"The old man by the big pit says the edge is in the bronze already. Then what am I for? ...To take away what is not edge, he says. I liked it better when I thought I put things in.",
			"My mother cast cauldrons. A cauldron feeds forty. I have just made a thing that feeds nobody, without deciding to, and it is the best pour I have done this year. That is what frightens me.",
			"Watch the channel, not my face. There. It wants to go thin. You have to lean on it to make it stay a pot. Since when did bronze want things?"]},
	"s_p21_nets": {"ask": "That net is cut clean through. Give me the other needle.", "price": 0, "toast": "Mended a net with %s",
		"lines": ["Hold that end. Tighter. ...Cut like that, in one line, there is no fraying to work from. It is as if the net had been told a thing so sharply it forgot it was a net.",
			"Nine nets. My grandfather said never put a net in the ford reach, and he never said why, and I thought he was an old fool. He was an old fool. But he was right about the reach.",
			"You tie a good knot for somebody who flies. Sweepers do, I suppose: brooms want binding. Have you eaten? There is fish. There is nothing but fish. We cannot catch it, but we have it.",
			"A man and his wife, the story goes, and she went in the furnace for him, and he named a sword after her. I said to my husband: do not name anything after me. Mend the net.",
			"There. That will hold a carp. It will not hold whatever is in the pool, but nothing will, and a net does not have to hold everything to be worth mending."]},
	"s_p21_porters": {"ask": "That camel wants loading and you are a hand short. Which side?", "price": 0, "toast": "Loaded a camel with %s",
		"lines": ["Near side, and mind his teeth. ...My brother went. Six years a guard and never drew once, and proud of it, and then a man came through saying a king would pay him to. He had been waiting to be asked, I think. All that not drawing.",
			"My husband. He left me the shop and took the sword off the wall where it had hung since the wedding. I had dusted it every week. I thought I was dusting an ornament.",
			"The boy was fifteen. He took his grandfather's blade while the old man slept. The grandfather has not slept since. He sits in the door with the empty scabbard across his knees and looks east.",
			"Eleven caravans with no guard, and do you know, not one was robbed? The robbers have all gone to be swordsmen too. Auntie says that is the funniest thing in the whole business, and she is not laughing.",
			"Pull that girth. Good. You carry a great many weapons for somebody who loads a camel properly. Most that carry one cannot. I have noticed it before and never known what to make of it."]},
	"s_p21_racks": {"ask": "It has been decided what is done with the blades. Shall we get yours down?", "price": 0, "toast": "Took a blade down out of the thatch with %s",
		"lines": ["It is in the thatch over the door. I put it there the night the wheel was stopped, I do not know why. I have not slept under it well. Mind the ladder; the third rung is my brother's work.",
			"Take it. Take it. My wife will not walk under the lintel with it up there; she has been going round by the pigsty for a month. I never drew it. I only liked knowing.",
			"I thought: if the neighbour has one, I had better. And he thought the same of me, it turns out, the same night. We found out yesterday, over the wall, and neither of us could look at the other.",
			"There. Lighter already, the whole house. Granny Wen said it would be. She said a roof knows what is in it. Have you eaten? Come in, now that a person can.",
			"My boy cried when I said it was going. He is seven. He had named it. That was when I knew it had to go, if you want the truth: when I heard that it had a name."]},
	"s_p20_carry": {"ask": "Going down with a basket? I will take one beside you.", "price": 0, "toast": "Carried a basket of the mountain with %s",
		"lines": ["Take the one with the red cord, it sits better. Have you eaten? ...I had my afternoons, since the wheel, and nothing to put in them. Then the old man asked. You cannot say no to ninety.",
			"He carried me on his shoulders when I was four. Now I carry his mountain. It comes out even, I reckon, by the time I am ninety myself.",
			"Down the swallow-hole with it. Much nearer than the sea. ...You look like my wife when I say that. She used to take the children to watch the swallows there. She has not said anything. That is how I know.",
			"The lads who went in the adit came out white as tofu and will not say what they saw. My cousin says a sheep. A sheep! He has kept sheep all his life and was not white about those.",
			"It is good, carrying. You know where you are with a basket. I did not know where I was with an afternoon."]},
	"s_p20_shore": {"ask": "Auntie Rong wants the pit-head propped before anyone goes down. Shall I take the maul?", "price": 0, "toast": "Set a prop at the pit-head with %s",
		"lines": ["May your metal run clean. Hold her plumb. Plumb! When I strike, do not flinch; the wedge knows if you flinch.",
			"My brother is down there. Second shift. I am not thinking about it. I am thinking about this prop, and then the next prop.",
			"We went too fast. Everybody knew. You could hear the roof talking. But the ore was coming out like rice out of a sack, and nobody wants to be the one who says stop.",
			"My grandfather would not go down without knocking on the first timber three times. For the neighbours, he said. We laughed. Knock on it, will you, before I drive this."]},
	"s_p20_wells": {"ask": "There is water in the well again. Shall I take the rope with you?", "price": 0, "toast": "Drew the first water with %s",
		"lines": ["Have you drunk? No: today I can say it and mean it. Haul, mountain friend! Feel that? That is a full bucket. I had forgotten the weight of one.",
			"The first dipper on the ground. For the well. The second to the camels, because they did not complain. The third is yours.",
			"Aysha knew it was low. She never said. She let the rope out a hand at a time and looked every caravan in the eye. I should not like to play dice with that woman.",
			"It tastes of somewhere cold. Somewhere a long way down, with no sun in it. I do not know why that should make it sweeter, and it does."]},
	"s_p20_boats": {"ask": "She is afloat again and half full of autumn. Shall I take the other bailer?", "price": 0, "toast": "Bailed out a boat with %s",
		"lines": ["Smooth water. Scoop and throw, scoop and throw, and mind you throw it downwind. There. Ha! That was not downwind.",
			"All autumn she sat on the mud with her ribs showing like a starved dog. I came down every morning to look. You do not know you love a boat until you see her on the mud.",
			"The river is at my grandfather's mark. He cut it the year he married. I thought it would never see water again, and I had begun to wonder what a fisherman is on a dry river.",
			"Mind the fish. Do not turn it over, and do not say the word; we are afloat, and I mean to stay so."]},
	"s_p18_sand": {"ask": "One stick for the oven from every caravan. Shall I carry one with you?", "price": 0, "toast": "Carried a stick to the oven with %s",
		"lines": ["A stick for Aysha's oven? From the mountain? Then carry it on the left shoulder, friend. The right is for goods you mean to sell.",
			"One stick each, and you say where it is from when you lay it in. I say Samarkand every time. I have never been to Samarkand. The oven does not mind.",
			"Have you drunk? Drink first. Then lift. A man who carries wood in this sun on an empty skin is a man we carry afterwards.",
			"Every caravan, one stick. There was none all winter, you know. Not one caravan. I used to curse the loads. I never thought I would miss a load."]},
	"s_p18_dawn": {"ask": "First light to you. I'll be your first sale, at your price.", "price": 60, "toast": "Was %s's first customer of the day",
		"lines": ["First light! At my price? You know the rule, then. Take it, take it, and may everybody after you be half as easy.",
			"The first sale by lamplight sets the luck for the day. Mind you, by these lamps I can hardly see what I'm selling you. It may be a fan. Let us both hope it is a fan.",
			"No haggling? On the first? Somebody raised you properly. Here, and one extra, which is not a discount, it is a custom, there is a difference.",
			"First light to you too. I was about to light a second lamp to see the first one by. Whatever is wrong with the fire, do hurry up and mend it.",
			"At my price! I had a speech ready and everything. Well. Take it. You have ruined my morning in the pleasantest way.",
			"The first customer is never argued with. The second pays for it. Stay and watch the second, if you like; it is the best show in the market."]},
	# Part XVII (the Spring Thunder release): the sowing, and Qingming kites
	"s_p17_sow": {"ask": "The ground's open at last. Can I help with the sowing?", "price": 0, "toast": "Helped %s with the sowing",
		"lines": ["Help? From the sweeper? Then take the basket and walk behind me. Scatter, don't throw. You're feeding the field, not fighting it.",
			"Seed rice in the warm water two nights, then into the mud. Mind the edges. My grandfather said the edges are where the field remembers you.",
			"Ten days and it's green, twenty and it's rows. The best part is now, though, before it's anything. All promise, no weeds.",
			"You whipped the ox? Then this field's yours too, a bit. Here: you plant this corner, and in autumn you can come and argue with me about it.",
			"I thought we'd never sow this year. The ground rang like a bell. Look at it now. Soft as a bun. Put your hand in it, go on.",
			"Mind the frogs. They're back. Everything's back. My wife cried this morning over a frog. I didn't. I had something in my eye.",
			"Beans in this row, sweeper, then millet, then beans again. The beans feed the ground and the millet feeds us. That's the whole of farming. The rest is weather."]},
	"s_p17_kites": {"ask": "It's Qingming! Shall we fly your kite?", "price": 0, "toast": "Flew a kite with %s",
		"lines": ["Higher! Higher! It's a swallow, see, so it has to be the highest, or the real swallows will laugh at it.",
			"Mine's a centipede. It has thirty legs. I painted every one. Don't let it touch the tree. Don't let it TOUCH the TREE.",
			"Now we cut the string and the bad luck flies away with it! ...Can we cut it a bit later? I like this kite.",
			"Granny says the kites are for the people who've gone. So they can see we're all right. Wave at them! Wave!",
			"It's going over the river! Run! RUN!",
			"You hold it. You hold it and I'll hold you, in case it pulls you into the sky. Cultivators fly, don't they? Is that how?",
			"Mine's a butterfly with a whistle in it. Listen! When it's high enough it sings. Granny says the dead like the singing ones best.",
			"Can you make it go higher with qi? Just a little? I won't tell anybody. Everybody already knows you can fly."]},
	"s_p16_report": {"ask": "The Kitchen God is writing his report to Heaven. What was your year like?", "price": 0, "toast": "%s's year, for the Kitchen God's report",
		"lines": ["The low field flooded in spring and we planted it again in summer, and it came good. Tell him that. Tell him we planted it again.",
			"My son went to Tushan to cast bells and came back with a wife. I had to sell the pig for the wedding. Put down the wife. Leave out the pig.",
			"Nine days of noon cracked the paddies like old pots. The whole village carried water at night. Nobody asked us to. Write that down.",
			"The threads came across the roofs and we pulled them out of the thatch for a month. My hands still find them. It was a hard year and we are still here.",
			"My mother died in the autumn, and the child came in the winter. I don't know what that adds up to. Tell him it was a year.",
			"Too much rain, then too little, then a tree in the night. But the tea came good on the terraces, and the cabbages were enormous. Enormous.",
			"Bandits in the spring, a flood in summer, cultivators every week. And the sweeper came home a hero. That one's the best part. Put it first."]},
}

## What townsperson `p` answers to errand `sid`.
static func errand_line(sid: String, p: Dictionary) -> String:
	var ls: Array = ERRANDS[sid].lines
	return str(ls[int(p.seed) % ls.size()])

## New Year's Day, from the first dawn of the year until the Elder has been wished a good one.
static func new_year(g) -> bool:
	return g.done("s_p16_nian") and not g.done("s_p16_end")

## Whether the people of town `tid` are out in the street making noise: the long last night of the
## year in a town that remembers the old ways.
static func noisy(g, tid: String) -> bool:
	if Clock.frozen(g) != "night":
		return false
	for npc in RALLY_TOWN:
		if str(RALLY_TOWN[npc]) == tid and g.rallied.has(npc):
			return true
	return false

## The dye a townsperson wears now: a child's new red clothes on New Year's Day, else their own.
static func dye_now(p: Dictionary, g) -> Array:
	if bool(p.kid) and new_year(g):
		return [Vector3(0.0, 0.75, 1.0), Vector3(0.12, 0.7, 1.05)]
	return p.get("dye", [])

## Put dye `dy` on model `m` (an empty one takes it off).
static func apply_dye(m: Node3D, dy: Array) -> void:
	for mi in m.get_meta("meshes", []):
		var msh: MeshInstance3D = mi
		for si in msh.mesh.get_surface_count():
			var sm: Material = msh.mesh.surface_get_material(si)
			if sm == MB.mat_actor() or sm == MB.mat_actor_plain():
				msh.set_surface_override_material(si, null if dy.is_empty() else MB.mat_dyed(dy[0], dy[1], sm == MB.mat_actor_plain()))

# ---------------------------------------------------------------- the named townsfolk at their work
## What the people with names do all day at their own place (the smith at his anvil, the cook at her
## stove): [the day's work (by turns), what they hold, the night].  Their place never changes (the
## story finds them there), they only work at it, turn to Lin Feng when he comes near, and the ones
## who sleep nod off at their post after dark (a word wakes them).
const POSTS := {
	# the Hollow Hills release (Part XX): the traveller writing up his day, the old man digging, the wise one
	# thinking it over, and a woodcutter who is only watching
	"xu_xiake": ["write|peer|point", "", "doze"], "yu_gong": ["dig|carry", "spade", "doze"], "zhi_sou": ["think|shrug", "", "doze"], "wang_zhi": ["peer|think", "", "peer"],
	"alchemist": ["stir", "ladle", "read"], "smith": ["hammer", "hammer", "doze"], "archivist": ["read|write", "book", "read"],
	"cook_zhou": ["stir|chop", "ladle", "doze"], "sweeper_bai": ["sweep", "", "doze"], "bell_shen": ["sweep|strike", "", "doze"],
	"gardener_ruan": ["gather", "", "doze"], "disciple_mei": ["read|sword_dance", "", "meditate"], "disciple_han": ["sword_dance", "", "meditate"],
	"farmer_lao": ["hoe|gather", "", "doze"], "child_hua": ["dance|clap", "", "doze"], "tofu_sun": ["stir", "ladle", "doze"], "scholar_wang": ["read|write", "book", "read"],
	"carpenter_gu": ["hammer|chop", "hammer", "doze"], "herb_lan": ["gather", "", "doze"], "watchman_zhou": ["doze", "", "bang|call"],
	"tea_seller_pan": ["drink|call", "cup", "doze"], "dyer_su": ["stir|weave", "", "doze"], "monk_huiming": ["pray", "", "pray"], "granny_gu": ["sit_bench|doze", "", "doze"],
	"porter_niu": ["lift", "", "doze"], "little_dou": ["dance|clap", "", "doze"], "fishwife_lu": ["call|offer", "", "doze"], "boatwright_gao": ["hammer", "hammer", "doze"],
	"shrine_hua": ["pray|sweep", "", "pray"], "carp_boy_yu": ["fish", "rod", "doze"], "caster_wei": ["hammer|pound", "hammer", "doze"], "carver_shi": ["carve|hammer", "chisel", "doze"],
	"charcoal_tan": ["chop|dig", "axe", "doze"], "well_keeper_zhaya": ["lift|drink|pour", "", "doze"], "cook_aysha": ["stir", "ladle", "doze"],
	"star_reader_kumar": ["read", "book", "stargaze"], "camel_boy_temur": ["toss", "", "doze"], "storyteller_wu": ["talk|laugh|point", "", "doze"],
	"postmaster_lu": ["write", "", "doze"], "cartographer_pei": ["write|read", "book", "read"], "weaver_liu": ["weave|spin", "", "doze"], "granny_wen": ["sit_bench|spin", "", "doze"],
	"teacher_qin": ["read", "book", "doze"], "teacher_ren": ["read", "book", "doze"], "noodle_he": ["stir", "ladle", "doze"], "lamplighter_bo": ["sweep", "", "touch"],
	"archer_kong": ["archery", "", "doze"], "fisher": ["fish", "rod", "fish"], "innkeeper_bao": ["call|talk", "", "doze"], "innkeeper_dong": ["call|talk", "", "doze"],
	"innkeeper_lou": ["call|talk", "", "doze"], "innkeeper": ["talk|call", "", "doze"], "auntie_rong": ["stir|call", "ladle", "doze"], "clerk_wei": ["write|count", "", "doze"],
	"courier_ma": ["lift", "", "doze"], "zao_jun": ["drink", "cup", "drink"], "ox_herd_niu": ["toss|gather", "", "doze"], "lantern_xi": ["weave", "", "touch"], "examiner_fan": ["read|write", "book", "doze"],
	"xia_cormorant": ["fish", "rod", "doze"], "bell_tuner_gong": ["strike|hammer", "hammer", "doze"], "shipwright_ban": ["hammer", "hammer", "doze"],
	"furnace_boy": ["lift|hammer", "hammer", "doze"], "stableboy_shitou": ["sweep|toss", "broom", "doze"],
}

## What named townsperson `id` is doing at hour `h`: [clip, what they hold], or [] if they keep still.
static func post(id: String, h: float) -> Array:
	if not POSTS.has(id):
		return []
	var pd: Array = POSTS[id]
	var night := h >= 21.5 or h < 5.0
	var clips := str(pd[2] if night else pd[0]).split("|")
	var ci := int(h * 60.0 / 9.0 + float(hash(id) % 7)) % clips.size()
	return [clips[ci], "" if night else str(pd[1])]

# ---------------------------------------------------------------- what they hold
## Something in a townsperson's hand, in the hand bone's own space (Props.held's convention: the bone
## runs from the wrist down to the fingers along -y, the palm faces +x for the right hand).
static func held(what: String) -> Node3D:
	match what:
		"hoe", "axe", "pole", "basket", "bowl", "lantern", "gong", "taper":
			pass
		_:
			return Props.held(what)
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	var wood := MB.tag(Color("7a5634"), MB.WOOD)
	var light := MB.tag(Color("b08a58"), MB.WOOD)
	match what:
		"hoe":
			b.limb(Vector3(0, -0.08, 0.55), Vector3(0, -0.08, -1.0), 0.018, 0.018, light, 5)
			b.box(Vector3(0, -0.2, -1.02), Vector3(0.05, 0.26, 0.14), MB.tag(Color("6a6a72"), MB.METAL))
		"axe":
			b.limb(Vector3(0, -0.08, 0.4), Vector3(0, -0.08, -0.45), 0.017, 0.017, light, 5)
			b.box(Vector3(0, -0.16, -0.42), Vector3(0.03, 0.2, 0.12), MB.tag(Color("7a7a84"), MB.METAL))
		"pole":
			# a shoulder pole with a basket hanging at either end
			b.limb(Vector3(-0.15, 0.05, 0.0) + Vector3(0, 0, -0.9), Vector3(-0.15, 0.05, 0.0) + Vector3(0, 0, 0.9), 0.02, 0.02, light, 5)
			for z in [-0.85, 0.85]:
				var top := Vector3(-0.15, 0.05, z)
				b.limb(top, top + Vector3(0.1, -0.55, 0), 0.004, 0.004, MB.tag(Color("6a5a40"), MB.CLOTH), 3)
				b.lathe(top + Vector3(0.12, -0.85, 0), [Vector2(0.14, 0.0), Vector2(0.2, 0.22), Vector2(0.21, 0.3)], MB.tag(Color("c0a06a"), MB.WOOD), 10)
				b.sph(top + Vector3(0.12, -0.55, 0), Vector3(0.17, 0.06, 0.17), MB.tag(Color("6aa04a"), MB.FOLIAGE))
		"basket":
			b.lathe(Vector3(0.05, -0.22, 0.0), [Vector2(0.1, 0.0), Vector2(0.15, 0.14), Vector2(0.16, 0.18)], MB.tag(Color("c0a06a"), MB.WOOD), 10)
			b.sph(Vector3(0.05, -0.05, 0.0), Vector3(0.13, 0.05, 0.13), MB.tag(Color("d8a040"), MB.FOLIAGE))
			b.torus(Vector3(0.05, -0.04, 0.0), 0.14, 0.012, MB.tag(Color("a08050"), MB.WOOD), Vector3(PI * 0.5, 0, 0))
		"bowl":
			b.lathe(Vector3(0.04, -0.08, 0.04), [Vector2(0.03, 0.0), Vector2(0.065, 0.045)], MB.tag(Color("e8e4d8"), MB.STONE), 10)
			b.sph(Vector3(0.04, -0.04, 0.04), Vector3(0.055, 0.015, 0.055), MB.tag(Color("f4f0e0"), MB.CLOTH))
		"lantern":
			# hung from a short stick: paper on a bamboo frame, glowing after dark
			b.limb(Vector3(0, -0.08, 0.0), Vector3(0, -0.08, 0.45), 0.01, 0.01, light, 4)
			b.lathe(Vector3(0, -0.32, 0.45), [Vector2(0.05, 0.0), Vector2(0.12, 0.06), Vector2(0.13, 0.16), Vector2(0.1, 0.24), Vector2(0.04, 0.27)], MB.tag(Color("e05a3a"), MB.CLOTH), 10)
			g.ball(Vector3(0, -0.18, 0.45), 0.2, Color(1.0, 0.6, 0.3, 0.45), true)
		"gong":
			# a small gong in the left hand (the stick is the right hand's: taper)
			b.cyl(Vector3(0.05, -0.12, 0.0), 0.16, 0.025, MB.tag(Color("c8a040"), MB.METAL), Vector3(0, 0, PI * 0.5), 14)
			b.limb(Vector3(0, -0.06, 0.0), Vector3(0.05, 0.02, 0.0), 0.006, 0.006, MB.tag(Color("8a3a2a"), MB.CLOTH), 3)
		"taper":
			b.limb(Vector3(0, -0.08, -0.05), Vector3(0, -0.08, 0.6), 0.008, 0.006, light, 4)
			g.ball(Vector3(0, -0.08, 0.64), 0.06, Color(1.0, 0.7, 0.3, 0.7), true)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not g.is_empty():
		var gm := MB.mesh_node(root, g.build(MB.mat_glow()))
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.set_meta("glow", gm)
	return root

## Which hand a thing is held in.
static func hand_of(what: String) -> String:
	return "hand.L" if what in ["lantern", "gong", "basket", "bowl"] else "hand.R"

# ---------------------------------------------------------------- their bodies
## A townsperson's model: their body (art/characters/folk_*), dyed, with the party's clips lent.
static func model(p: Dictionary) -> Node3D:
	var rel := "characters/" + str(p.body)
	if not Assets.has(rel):
		return Models.person(Color(0.5, 0.5, 0.6), Color("2a2a3a"), {"hair": "bun"})
	var m := Assets.instance(rel)
	m.set_meta("kind", "person")
	Assets.lend_clips(m)
	var dy: Array = p.get("dye", [])
	if not dy.is_empty():
		apply_dye(m, dy)
	m.set_meta("dye", dy)
	return m
