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
		"disciple": ["folk_disciple", "folk_disciple_f"], "servant": ["folk_youth", "folk_maiden"]},
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
	"farmer": {"day": [[5.3, "field", "hoe", "hoe"], [11.3, "home", "in", ""], [12.8, "field", "gather|hoe", "hoe"], [17.3, "well", "drink", "dipper"], [18.2, "home", "in", ""]],
		"go_hold": "hoe", "dye": [[0.08, 0.1, 0.22, 0.28, 0.33], [0.06, 0.1, 0.55, 0.6], 0.35, 1.0]},
	"fisher": {"day": [[4.8, "shore", "fish", "rod"], [10.6, "market", "call|offer|talk", "basket"], [13.2, "shore", "fish", "rod"], [18.0, "inn", "drink|laugh", "cup"], [19.6, "home", "in", ""]],
		"go_hold": "rod", "dye": [[0.52, 0.56, 0.6, 0.08], [0.1, 0.12, 0.58], 0.35, 1.0]},
	"merchant": {"day": [[6.5, "market", "call|talk|offer|wave", ""], [11.9, "tea", "eat", "bowl"], [12.9, "market", "talk|call|point|think", ""], [18.3, "tea", "drink|laugh", "cup"], [20.5, "home", "in", ""]],
		"dye": [[0.0, 0.97, 0.75, 0.6, 0.85, 0.05], [0.12, 0.55, 0.6, 0.0], 0.55, 1.0]},
	"porter": {"day": [[5.7, "market", "lift", ""], [7.1, "gate", "lift", ""], [8.5, "market", "lift", ""], [9.9, "workshop", "lift", ""], [11.5, "inn", "eat", "bowl"],
			[12.5, "gate", "lift", ""], [14.1, "market", "lift", ""], [15.7, "gate", "lift", ""], [17.3, "inn", "sit_bench|drink", "cup"], [19.0, "home", "in", ""]],
		"walk": "carry", "go_hold": "pole", "dye": [[0.08, 0.1, 0.12, 0.55], [0.06, 0.08], 0.3, 1.0]},
	"child": {"day": [[7.1, "school", "read", "book"], [11.1, "home", "in", ""], [13.1, "square", "dance|clap|laugh", ""], [15.8, "field", "kite|clap|dance", ""], [18.0, "home", "in", ""]],
		"walk": "run", "dye": [[0.0, 0.08, 0.15, 0.3, 0.55, 0.62, 0.9], [0.12, 0.15, 0.95], 0.6, 1.05]},
	"elder": {"day": [[5.7, "square", "sword_dance|gaze", ""], [7.5, "bench", "sit_bench|think", ""], [10.9, "home", "in", ""], [13.9, "tea", "drink|think", "cup"], [16.4, "bench", "doze|sit_bench", ""], [17.9, "home", "in", ""]],
		"dye": [[0.07, 0.6, 0.8, 0.1], [0.08, 0.0], 0.25, 0.95]},
	"monk": {"day": [[4.6, "shrine", "pray", ""], [6.5, "shrine", "sweep", "broom"], [8.9, "market", "pray|offer", "bowl"], [11.5, "shrine", "eat", "bowl"], [12.9, "shrine", "pray|strike", ""], [16.9, "square", "sweep", "broom"], [18.9, "home", "in", ""]],
		"dye": []},
	"guard": {"day": [[6.0, "gate", "idle|look", ""], [11.9, "inn", "eat", "bowl"], [12.9, "gate", "idle|look", ""], [18.5, "home", "in", ""]], "dye": []},
	"watchman": {"day": [[5.1, "home", "in", ""], [18.7, "patrol", "bang|call", "gong"]], "round": "patrol", "go_hold": "lantern", "dye": []},
	"scholar": {"day": [[6.7, "school", "read|write", "book"], [11.7, "tea", "eat", "bowl"], [12.9, "square", "write|read|think", "book"], [17.4, "tea", "drink|play_flute", "cup"], [20.3, "home", "in", ""]],
		"dye": [[0.58, 0.62, 0.66, 0.5], [0.6, 0.62, 0.0], 0.35, 1.0]},
	"cook": {"day": [[5.1, "kitchen", "stir|chop", "ladle"], [10.4, "market", "call|offer", "basket"], [11.4, "kitchen", "stir", "ladle"], [15.0, "kitchen", "chop|stir", "axe"], [21.3, "home", "in", ""]],
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
	"disciple": ["Disciple", "Disciple"], "servant": ["Steward", "Steward"]}

## the bodies that are women and girls (for names and words)
const FEM := ["folk_farmwife", "folk_shopwife", "folk_girl", "folk_grandma", "folk_maiden", "folk_disciple_f", "folk_jiaoren"]
## the bodies that are children and elders
const KID := ["folk_boy", "folk_girl"]
const OLD := ["folk_grandpa", "folk_grandma"]

# ---------------------------------------------------------------- who lives where
static var _towns := {}
static var _astar := {}

## The tile at the heart of town `tid` (a world tile of its realm).
static func heart(tid: String) -> Vector2i:
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
	var t: Dictionary = TOWNS[tid]
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
			out.append(p)
			i += 1
	_towns[key] = out
	return out

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
	var area: String = TOWNS[tid].area
	var out := {}
	for e in wd.ents:
		if str(e.get("area", "")) != area:
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
	var area: String = TOWNS[tid].area
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
				if maxi(absi(door.x - c.x), absi(door.y - c.y)) > RADIUS + 8:
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
		# (enough places for a town's worth of people: the next kind of place too, if there are few)
		if out.size() >= 6:
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
	var area: String = TOWNS[tid].area
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
	if bool(p.night) and str(TOWNS[str(p.town)].race) == "shade":
		pool.append_array(SHADE_LINES)
	var race := str(TOWNS[str(p.town)].race)
	if PEOPLE_LINES.has(race):
		pool.append_array(PEOPLE_LINES[race])
	pool.append_array(LINES.get(str(p.role), LINES.youth))
	pool.append_array(HOUR_LINES.get(Clock.part(h), []))
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
		return ["Hello!", "It's him!", "Can you fly?"][int(p.seed) % 3]
	var opts: Array = GREETINGS.get(Clock.part(Clock.hour(g)), ["Hello!"])
	var s: String = str(opts[int(p.seed) % opts.size()])
	# (the hero's own family name, as the player chose it: a Label3D does not go through UI.named)
	return s.replace("%s", ("Lord " + str(g.hero.get("family", "Lin"))) if g.realm() >= 4 else "young master") if s.contains("%s") else s

## Whether townsperson `p` is of kind `role` ("child" means any child of the towns).
static func is_role(p: Dictionary, role: String) -> bool:
	return bool(p.kid) if role == "child" else str(p.role) == role

static func hongbao_line(p: Dictionary) -> String:
	return str(HONGBAO_LINES[int(p.seed) % HONGBAO_LINES.size()])

## What Lin Feng says to a townsperson for a step of the story, what they say back, the news of it
## and what it costs (Part XVI: red paper from the merchants, a fish for the reunion table, red envelopes for the
## children, the lantern riddles).
const ERRANDS := {
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
	"alchemist": ["stir", "ladle", "read"], "smith": ["hammer", "hammer", "doze"], "archivist": ["read|write", "book", "read"],
	"cook_zhou": ["stir|chop", "ladle", "doze"], "sweeper_bai": ["sweep", "", "doze"], "bell_shen": ["sweep|strike", "", "doze"],
	"gardener_ruan": ["gather", "", "doze"], "disciple_mei": ["read|sword_dance", "", "meditate"], "disciple_han": ["sword_dance", "", "meditate"],
	"farmer_lao": ["hoe|gather", "", "doze"], "child_hua": ["dance|clap", "", "doze"], "tofu_sun": ["stir", "ladle", "doze"], "scholar_wang": ["read|write", "book", "read"],
	"carpenter_gu": ["hammer|chop", "hammer", "doze"], "herb_lan": ["gather", "", "doze"], "watchman_zhou": ["doze", "", "bang|call"],
	"tea_seller_pan": ["drink|call", "cup", "doze"], "dyer_su": ["stir|weave", "", "doze"], "monk_huiming": ["pray", "", "pray"], "granny_gu": ["sit_bench|doze", "", "doze"],
	"porter_niu": ["lift", "", "doze"], "little_dou": ["dance|clap", "", "doze"], "fishwife_lu": ["call|offer", "", "doze"], "boatwright_gao": ["hammer", "hammer", "doze"],
	"shrine_hua": ["pray|sweep", "", "pray"], "carp_boy_yu": ["fish", "rod", "doze"], "caster_wei": ["hammer", "hammer", "doze"], "carver_shi": ["hammer", "hammer", "doze"],
	"charcoal_tan": ["chop", "axe", "doze"], "well_keeper_zhaya": ["lift|drink", "", "doze"], "cook_aysha": ["stir", "ladle", "doze"],
	"star_reader_kumar": ["read", "book", "stargaze"], "camel_boy_temur": ["toss", "", "doze"], "storyteller_wu": ["talk|laugh|point", "", "doze"],
	"postmaster_lu": ["write", "", "doze"], "cartographer_pei": ["write|read", "book", "read"], "weaver_liu": ["weave", "", "doze"], "granny_wen": ["sit_bench|weave", "", "doze"],
	"teacher_qin": ["read", "book", "doze"], "teacher_ren": ["read", "book", "doze"], "noodle_he": ["stir", "ladle", "doze"], "lamplighter_bo": ["sweep", "", "touch"],
	"archer_kong": ["archery", "", "doze"], "fisher": ["fish", "rod", "fish"], "innkeeper_bao": ["call|talk", "", "doze"], "innkeeper_dong": ["call|talk", "", "doze"],
	"innkeeper_lou": ["call|talk", "", "doze"], "innkeeper": ["talk|call", "", "doze"], "auntie_rong": ["stir|call", "ladle", "doze"], "clerk_wei": ["write", "", "doze"],
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
