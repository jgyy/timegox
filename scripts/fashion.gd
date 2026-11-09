class_name Fashion
extends RefCounted
## Who Lin Feng is, what he wears and what he rides (the Fates and Faces release).
##
## **Character creation** (create.gd): before the journey begins the player names the sweeper and
## chooses his look (four Blender builds of the same rig, art/characters/lin_feng*.py), the colour of
## his hair, his eyes and his sweeper's robe, and his **origin**: where he came from before the sect
## took him in, which gives him a small strength (and a small weakness), a keepsake, and a few lines of
## his own in the story (Main.origin_lines) and at the end.
##
## **The wardrobe** (Esc > Wardrobe): outfits are earned along the journey (the story, the fated
## encounters of fate.gd, deeds) or bought from Dyer Su at the Dawn Market.  Each recolours his robe,
## its trousers and its trims (Assets.hero_instance), may hang something on him (a hat, a crown,
## pauldrons, a mantle: Models.accessory, on his bones) and carries a small passive (`fx`).
##
## **The stable** (Esc > Stable, R to mount): horses, a qilin and a tiger to ride, and a flying sword,
## a cloud and a sky-barque to stand on.  Riding carries the party over open ground faster (`speed`),
## never indoors, and the bot rides like anyone would.
##
## Passives (`fx`) use the keys Game.boon knows: hp, qi, atk (multipliers, as a fraction added),
## spd (speed, added), miss (the chance a foe strikes air, added), heal, taken (a fraction: -0.05 takes
## five percent less harm), stones, exp and cost (techniques that much cheaper).

# ---------------------------------------------------------------- character creation
const FAMILY := ["Lin", "Bai", "Su", "Xiao", "Mo", "Yun", "Gu", "Shen", "Ye", "Jiang", "Qin", "Lu"]
const GIVEN := ["Feng", "Chen", "Yu", "Xuan", "Ming", "Jing", "Hao", "Lan", "Ze", "Tian", "Wen", "Kai"]
## the name the story knows him by unless the player gives him another (UI.named swaps it on screen)
const DEFAULT_FAMILY := "Lin"
const DEFAULT_GIVEN := "Feng"

const LOOKS := {
	"sweeper": {"n": "The Sweeper", "asset": "lin_feng",
		"desc": "A topknot tied up with a copper crown and a jade pin, a cowlick no pin can hold down, and a stern young mouth: the boy who swept the sect's steps for three years and never once complained out loud."},
	"wanderer": {"n": "The Wanderer", "asset": "lin_feng_wanderer",
		"desc": "Hair in one long braid down the back, tied with a red cord, and an easy smile that has talked him out of more trouble than it has got him into. He looks like somebody who is always about to leave."},
	"wild": {"n": "The Wild Child", "asset": "lin_feng_wild",
		"desc": "Hair that no comb has ever beaten, a grin with a chipped edge to it and a cowlick that stands up in the wind. The sect's elders have given up trying to make him look like a disciple."},
	"scholar": {"n": "The Scholar's Ward", "asset": "lin_feng_scholar",
		"desc": "Short, neatly cropped hair and a calm, thoughtful face that reads before it speaks. He looks younger than he is until he frowns at something, and then he looks like somebody's grandfather."},
}
const LOOK_ORDER := ["sweeper", "wanderer", "wild", "scholar"]

## [name, colour]: the first of each is the colour the story's Lin Feng was built with
const HAIR := [["Ink-black", "1a1a2a"], ["Chestnut", "5a3424"], ["Frost-white", "dfe6ee"], ["Midnight blue", "1e2c5c"], ["Ember red", "8a2a1e"], ["Ash grey", "6c6c76"]]
const EYES := [["Azure", "3a7ae8"], ["Amber", "e0a030"], ["Jade", "2eb07e"], ["Violet", "8a50d0"], ["Ink", "2a2a3a"], ["Crimson", "c03040"]]
## the sweeper's robe: [name, robe, trousers/sash/cape, trims]
const ROBES := [
	["Azure", "3a8ae8", "1e2c50", "e8f0ff"],
	["Crimson", "b8323a", "3a1418", "f0d8a0"],
	["Jade", "2e9a6e", "163a2c", "e8f4e0"],
	["Ink", "2c2e3a", "121318", "c8ccd8"],
	["Ivory", "e8e0cc", "6a5a44", "b8903a"],
	["Violet", "6a48b0", "241840", "e8dcff"],
]

## What he was in Qingshi Village before he climbed the sect's steps at thirteen and asked for a broom
## (the Elder left him there as a baby, with Granny Wen the midwife: Part VI tells why).  `fx` his small
## strength and weakness, `give` what he still carries, and the story gives him a line of his own here
## and there (ORIGIN_LINES).
const ORIGINS := {
	"foundling": {"n": "Granny Wen's Boy", "short": "Granny Wen's boy",
		"desc": "The village midwife raised him on rice gruel and errands: he carried her bag to every birth in the valley and knows every family in Qingshi by its front step. The story as the sect tells it.",
		"fx": {}, "give": {"hp_pill": 1}, "fx_text": "No gift and no burden: the road as the story first told it. One more Healing Pill, from Granny Wen's bag."},
	"fisher": {"n": "Ferry-Hand of Qingshi", "short": "the ferry-hand of Qingshi",
		"desc": "From the age of eight he poled the river ferry below the village and hauled the fishermen's nets for a fish a day. He can read rain by its smell and he is stronger than he looks, and slower than he would like.",
		"fx": {"hp": 0.08, "spd": -1}, "give": {"hp_pill": 2}, "fx_text": "A river-hauler's back: health +8%, but a little slower (speed -1). Two Healing Pills from the fishermen."},
	"scholar": {"n": "Scholar Wang's Pupil", "short": "Scholar Wang's pupil",
		"desc": "Scholar Wang, who failed the Court's examinations nine times, taught him his letters for nothing and then everything else for nothing too. He can read any script on any stone, and he has never once won a fight.",
		"fx": {"qi": 0.08, "cost": 0.04, "hp": -0.05}, "give": {"qi_pill": 1}, "fx_text": "A mind trained on old books: qi +8% and techniques 4% cheaper, but health -5%. One Spirit Qi Pill."},
	"hunter": {"n": "Hunter's Apprentice", "short": "the old hunter's apprentice",
		"desc": "Old Geng, who hunted the edge of the Whispering Bamboo, took him on to carry the game and kept him on because he walked without breaking twigs. When Geng's knees went, the boy climbed the mountain instead.",
		"fx": {"atk": 0.05, "spd": 1, "qi": -0.05}, "give": {}, "fx_text": "A hunter's eye and feet: attack +5% and speed +1, but qi -5%. The old hunter's greens are his to wear."},
	"merchant": {"n": "Runner of the Four Roads", "short": "the runner of the Four Roads",
		"desc": "He ran messages between Qingshi and the caravans at Cloudfoot for copper coins, and learned to count in five currencies and haggle in three dialects. Caravan-Master Kang still says he owes him a donkey.",
		"fx": {"stones": 0.12, "taken": 0.04}, "give": {"stones": 120}, "fx_text": "A trader's luck: spirit stones +12% and 120 to start with, but he takes 4% more harm."},
}
## A line of his own here and there, by origin: the prologue, the Elder's first summons, Granny Wen's
## door in Part VII, and the end (Main.origin_lines appends them to the conversation they are keyed by).
const ORIGIN_LINES := {
	"intro": {
		"foundling": [["Narrator", "Before the broom there was Granny Wen's house in Qingshi Village, and a boy who carried the midwife's bag to every birth in the valley."]],
		"fisher": [["Narrator", "Before the broom there was the river below Qingshi Village, and a ferry-hand who could smell the rain coming before the fishermen saw the clouds."]],
		"scholar": [["Narrator", "Before the broom there was Scholar Wang's schoolroom in Qingshi Village, and a boy who read every book in it twice by the light of one candle."]],
		"hunter": [["Narrator", "Before the broom there was the edge of the Whispering Bamboo, and an old hunter's apprentice who could cross a thicket without breaking a twig."]],
		"merchant": [["Narrator", "Before the broom there were the caravans of the Four Roads at Cloudfoot, and a runner who could count in five currencies and haggle in three dialects."]],
	},
	"s_intro": {
		"fisher": [["Elder Qing Xuan", "You still stand like a ferry-hand, feet apart for the swell. Good. The ground is going to move under you a great deal."]],
		"scholar": [["Elder Qing Xuan", "Wang's pupil. He wrote to me once, you know, to ask whether I would take a boy who reads too much. I said the steps would cure it. They did not, I see."]],
		"hunter": [["Elder Qing Xuan", "Old Geng's apprentice. You came up the steps without a sound, three winters ago. The gate disciples still argue about it."]],
		"merchant": [["Elder Qing Xuan", "Kang the caravan-master sent word you were honest, which from Kang is either praise or a warning. We shall see which."]],
	},
	"s_vl_intro": {
		"fisher": [["Granny Wen the Midwife", "The ferry has not run straight since you left it. The new boy steers like a duck."]],
		"scholar": [["Granny Wen the Midwife", "Scholar Wang reads your name out of every letter the post brings. He pretends it is for the children."]],
		"hunter": [["Granny Wen the Midwife", "Old Geng asks after you every market day. His knees are worse. His stories are longer."]],
		"merchant": [["Granny Wen the Midwife", "Kang came through in spring and asked if you were rich yet. I told him you were a Sovereign. He asked if that pays."]],
	},
	"ending": {
		"foundling": [["Narrator", "In Qingshi Village an old midwife tells anyone who will listen about a basket no bigger than a loaf."]],
		"fisher": [["Narrator", "On the river below Qingshi the ferry still runs, and the fishermen say the current goes gentler where he used to pole."]],
		"scholar": [["Narrator", "In Qingshi Village an old scholar who failed nine examinations has written the only true history of the climb, and every word of it is spelled correctly."]],
		"hunter": [["Narrator", "At the edge of the Whispering Bamboo an old hunter tells his grandchildren that the boy who held up the sky once carried his game."]],
		"merchant": [["Narrator", "At Cloudfoot Caravan-Master Kang tells everyone the ascended Sovereign owes him a donkey, and nobody, anywhere, believes him."]],
	},
}
const ORIGIN_ORDER := ["foundling", "fisher", "scholar", "hunter", "merchant"]

static func default_hero() -> Dictionary:
	return {"family": DEFAULT_FAMILY, "given": DEFAULT_GIVEN, "look": "sweeper", "hair": 0, "eyes": 0, "robe": 0, "origin": "foundling"}

static func full_name(h: Dictionary) -> String:
	return "%s %s" % [str(h.get("family", DEFAULT_FAMILY)), str(h.get("given", DEFAULT_GIVEN))]

## A name the player typed: letters only, a capital first, at most twelve letters ("" if unusable).
static func clean_name(s: String) -> String:
	var out := ""
	for ch in s.strip_edges():
		var c := ch.unicode_at(0)
		if (c >= 65 and c <= 90) or (c >= 97 and c <= 122):
			out += ch
	out = out.substr(0, 12)
	if out == "":
		return ""
	return out.substr(0, 1).to_upper() + out.substr(1).to_lower()

# ---------------------------------------------------------------- outfits
## What can hang on the hero (Models.accessory builds each, on the bone named here).
const ACCESSORY_BONES := {"straw_hat": "head", "jade_crown": "head", "phoenix_crest": "head", "veil_hat": "head",
	"pauldrons": "chest", "feather_mantle": "chest", "star_cloak": "chest", "ink_mask": "head", "dragon_horns": "head"}

## `cols`: robe, trousers/sash/cape and trims ("" keeps the colours chosen at creation); `acc` what it
## hangs on him; `how` how it is earned (a quest step done, a fated encounter, a deed, or bought).
const OUTFITS := {
	"sweeper": {"n": "Sweeper's Robe", "cols": ["", "", ""], "acc": [], "fx": {},
		"desc": "The robe he swept the steps in, in the colours he chose. Patched at both elbows. It still smells faintly of the kitchen.", "how": "Yours from the start."},
	"inner": {"n": "Inner Disciple's Robe", "cols": ["eef2fa", "2a5aa8", "3a8ae8"], "acc": ["jade_crown"], "fx": {"qi": 0.05},
		"desc": "White silk with an azure sash and the sect's cloud on the back, and a small jade crown for the topknot. The Elder had it made the night he broke through to Foundation.", "how": "Given by the Elder when you reach Foundation Establishment.", "step": "s_elder2"},
	"hunter": {"n": "Hunter's Greens", "cols": ["5a7a3a", "3a2a1a", "c8b080"], "acc": ["straw_hat"], "fx": {"spd": 1},
		"desc": "Moss-green hemp, a leather jerkin over it and a broad straw hat against the bamboo's rain: what his mother hunted in, or what she would have.", "how": "Tala of the horse-folk, if you bring her herd home; or the old hunter's apprentice's own.", "fate": ["tala", "herd"], "origin": "hunter"},
	"dragon": {"n": "Dragon-Scale Robe", "cols": ["2a8a8a", "143a46", "e8c050"], "acc": ["dragon_horns"], "fx": {"taken": -0.04},
		"desc": "Sea-green silk woven with the shed scales of the Azure Dragon King, cool in any heat, with a pair of coral horn-combs for the hair. Water runs off it like off a fish.", "how": "A gift of the Azure Dragon King, once he is free of the rift.", "step": "s_dr_king"},
	"phoenix": {"n": "Phoenix-Plume Robe", "cols": ["c8382a", "4a1610", "f0b030"], "acc": ["phoenix_crest", "feather_mantle"], "fx": {"atk": 0.05},
		"desc": "Crimson and gold, with a mantle of ash-phoenix feathers that never quite stop smouldering at the tips. Sage Huo Rong says it suits him. Sage Huo Rong is a liar.", "how": "From Sage Huo Rong, after the Ash Phoenix is quenched.", "step": "s_vo_phoenix"},
	"celestial": {"n": "Heaven-Gate Armour", "cols": ["f0e6c8", "8a6a2a", "f0c850"], "acc": ["pauldrons", "jade_crown"], "fx": {"hp": 0.06},
		"desc": "The white-and-gold harness of the Celestial Gate's last honest guard, who left it on the gate for whoever came to put things right. Heavy pauldrons, a jade crown.", "how": "Left on the Celestial Gate for you, once the Jade Emperor of Ruin falls.", "step": "s_ce_emperor"},
	"immortal": {"n": "Moon-White Immortal Robe", "cols": ["f4f6fa", "b8c4d8", "a8c8ff"], "acc": ["jade_crown"], "fx": {"qi": 0.06, "cost": 0.03},
		"desc": "Every True Immortal is given one, and almost none of them wear it, because it shows every speck of dust. It shows none on him. He is a sweeper.", "how": "Yours when you ascend as a True Immortal.", "step": "s_break8"},
	"ink": {"n": "Night-Ink Robe", "cols": ["2a2438", "0e0c14", "8a6ad8"], "acc": ["ink_mask"], "fx": {"miss": 0.03},
		"desc": "Black as Youdu's ink, with violet trims and a lacquered half-mask the shades wear to walk among the living without frightening anyone. Blows slide off the dark.", "how": "From the Lantern-Magistrate's tailors once the Dark Capital calls you friend; or from the Ashen Brother, if you spare him.", "step": "s_yd_return", "fate": ["qiu_ye", "redeemed"]},
	"brocade": {"n": "Weaver's Brocade", "cols": ["c85a7a", "4a1a2a", "f0d080"], "acc": ["veil_hat"], "fx": {"stones": 0.08},
		"desc": "Rose brocade with clouds woven in gold, and a wide hat with a gauze veil for the dusty roads. Traders take one look at it and lower their prices without being asked.", "how": "Sold by Dyer Su at the Dawn Market.", "buy": 9000, "after": "s_yg_intro"},
	"starlit": {"n": "Star-River Robe", "cols": ["1c2a5c", "0a1028", "e8ecff"], "acc": ["star_cloak"], "fx": {"exp": 0.05},
		"desc": "Midnight-blue silk the Weaver Star spun from the Silver River itself, a cloak of it that keeps a few small stars in its folds. Cultivators who wear it learn faster at night. It is always night somewhere.", "how": "A gift from Zhi Nu, the Weaver Star, after the Silver River is mended.", "step": "s_wv_return"},
	"sea": {"n": "Sea-Wanderer's Coat", "cols": ["1e3a5a", "e8e0cc", "c8302a"], "acc": ["straw_hat"], "fx": {"spd": 1, "heal": 0.05},
		"desc": "A navy sailor's coat over white trousers, a red sash and a sun hat, sewn by the Thousand Children of Landfall from the first sailcloth they wove in two thousand years.", "how": "Sewn by the Thousand Children of Landfall when the sea comes home.", "step": "s_p12_end"},
	"conclave": {"n": "Robe of the Many Peoples", "cols": ["f0ece0", "5a3a8a", "e8b040"], "acc": ["jade_crown", "feather_mantle"], "fx": {"hp": 0.04, "qi": 0.04, "atk": 0.03},
		"desc": "Every people of the realms added something: Yumin feathers at the shoulders, dragon-silk, fox-fire embroidery, a pearl from Tearwater, a shade's black thread, a Landfall sailor's knot. It should not look good. It does.", "how": "From the Conclave of the Realms, when it meets at last.", "step": "s_p13_end"},
}
const OUTFIT_ORDER := ["sweeper", "inner", "hunter", "dragon", "phoenix", "celestial", "immortal", "ink", "brocade", "starlit", "sea", "conclave"]

# ---------------------------------------------------------------- rides
## `kind`: "mount" (ridden astride: "ride"/"ride_idle") or "vehicle" (stood on: "ride_stand");
## `model` what Models.ride builds; `speed` how much faster than running; `seat` where the rider's
## hips go and `pillion` Yue Ling's (mount space, the model's scale included); `how` how it is earned.
const RIDES := {
	"pony": {"n": "Mountain Horse", "kind": "mount", "model": "horse", "speed": 1.15, "seat": Vector3(0, 1.32, 0.02), "pillion": Vector3(0, 1.34, -0.4), "scale": 1.0,
		"desc": "A dun steppe horse with a black mane and a temper, bred by the horse-folk who winter below Thunder Valley. She bites everyone but you. Mostly.", "how": "Tala of the horse-folk, if you find her herd."},
	"sword": {"n": "Flying Sword", "kind": "vehicle", "model": "sword", "speed": 1.25, "seat": Vector3(0, 0.78, 0.25), "pillion": Vector3(0, 0.78, -0.6), "scale": 1.0,
		"desc": "His own jian, grown three paces long under his qi, carrying him a hand's breadth above the road. The first thing every Golden Core learns, and the last thing any of them forgets.", "how": "The Elder teaches you to ride your sword at Golden Core.", "step": "s_elder3"},
	"qilin": {"n": "Azure Qilin", "kind": "mount", "model": "qilin", "speed": 1.3, "seat": Vector3(0, 1.36, 0.0), "pillion": Vector3(0, 1.36, -0.42), "scale": 1.22,
		"desc": "The Azure Qilin of the Celestial Gate, calm now, who chose to carry the one who calmed it. Its hooves do not quite touch the ground, and no flower it steps on ever bends.", "how": "The Azure Qilin, if you let it choose to carry you.", "pick": ["qilin", "ride"]},
	"cloud": {"n": "Auspicious Cloud", "kind": "vehicle", "model": "cloud", "speed": 1.35, "seat": Vector3(0, 0.62, 0.2), "pillion": Vector3(0, 0.62, -0.55), "scale": 1.0,
		"desc": "A five-coloured cloud that comes when an immortal whistles for it. It smells of rain and peaches, and it sulks if you leave it waiting.", "how": "Every True Immortal's first cloud comes to them at the ascension.", "step": "s_break8"},
	"tiger": {"n": "White Tiger of the West", "kind": "mount", "model": "tiger", "speed": 1.4, "seat": Vector3(0, 1.3, -0.08), "pillion": Vector3(0, 1.3, -0.5), "scale": 1.45,
		"desc": "A cub of Bai Hu's own litter, grown in a season to the size of a horse, white as the moon on sand. It purrs like a landslide and is afraid of moths.", "how": "Bai Hu's cub follows you out of the Desert of Fallen Stars.", "step": "s_du_tiger"},
	"barque": {"n": "Sky-Barque of Landfall", "kind": "vehicle", "model": "barque", "speed": 1.45, "seat": Vector3(0, 0.9, 0.5), "pillion": Vector3(0, 0.9, -0.5), "scale": 1.0,
		"desc": "The first keel Landfall laid in two thousand years, finished with Yumin feathers for a sail and Mazu's blessing on the bow, so that it sails on the wind over the land as well as on the sea.", "how": "Built for you by the Thousand Children when the sea comes home.", "step": "s_p12_end"},
}
const RIDE_ORDER := ["pony", "sword", "qilin", "cloud", "tiger", "barque"]

# ---------------------------------------------------------------- lookups
static func look_of(g) -> Dictionary:
	return LOOKS.get(str(g.hero.get("look", "sweeper")), LOOKS.sweeper)

static func origin_of(g) -> Dictionary:
	return ORIGINS.get(str(g.hero.get("origin", "foundling")), ORIGINS.foundling)

## The colours the hero is drawn in: {"robe", "sec", "trim", "hair", "eyes"} as Colors, leaving out
## everything still at the story's own colours (so the default hero is the authored model, untouched).
static func hero_colors(g) -> Dictionary:
	var out := {}
	var h: Dictionary = g.hero
	var hi := clampi(int(h.get("hair", 0)), 0, HAIR.size() - 1)
	var ei := clampi(int(h.get("eyes", 0)), 0, EYES.size() - 1)
	var ri := clampi(int(h.get("robe", 0)), 0, ROBES.size() - 1)
	if hi != 0:
		out["hair"] = Color(HAIR[hi][1])
	if ei != 0:
		out["eyes"] = Color(EYES[ei][1])
	var robe: Array = ROBES[ri]
	var o: Dictionary = OUTFITS.get(str(g.outfit), OUTFITS.sweeper)
	var keys := ["robe", "sec", "trim"]
	for k in 3:
		var oc: String = str(o.cols[k])
		if oc != "":
			out[keys[k]] = Color(oc)
		elif ri != 0:
			out[keys[k]] = Color(str(robe[k + 1]))
	return out

## The sum of one passive over the hero's origin and the outfit he wears (see the keys above).
static func gear(g, key: String) -> float:
	var v := float(origin_of(g).fx.get(key, 0.0))
	v += float(OUTFITS.get(str(g.outfit), OUTFITS.sweeper).fx.get(key, 0.0))
	return v

## A passive in words: "health +8%, speed -1".
static func fx_text(fx: Dictionary) -> String:
	var names := {"hp": "health", "qi": "qi", "atk": "attack", "spd": "speed", "miss": "foes miss", "heal": "healing", "taken": "harm taken",
		"stones": "spirit stones", "exp": "cultivation from battle", "cost": "technique cost"}
	var parts: Array = []
	for k in fx:
		var v := float(fx[k])
		if k == "spd":
			parts.append("%s %+d" % [names[k], int(v)])
		elif k == "cost":
			parts.append("%s -%d%%" % [names[k], int(round(v * 100.0))])
		else:
			parts.append("%s %+d%%" % [names.get(k, k), int(round(v * 100.0))])
	return ", ".join(parts) if not parts.is_empty() else "no passive"

## Whether an outfit can be bought now (Dyer Su), and whether a ride or an outfit is earned by the
## state of the game (quest steps; fated encounters and choices are granted where they happen).
static func outfit_for_sale(id: String, g) -> bool:
	var o: Dictionary = OUTFITS[id]
	return o.has("buy") and not g.outfits.has(id) and g.reached(str(o.get("after", "")))

## The outfits and rides the quest steps done so far have earned (Game.advance grants them as each
## step is done; Game.reset the origin's own).
static func step_rewards(step_id: String) -> Array:
	var out: Array = []
	for id in OUTFITS:
		if str(OUTFITS[id].get("step", "")) == step_id:
			out.append(["outfit", id])
	for id2 in RIDES:
		if str(RIDES[id2].get("step", "")) == step_id:
			out.append(["ride", id2])
	return out

## The fastest ride owned ("" for none): what the bot (and most players) summon.
static func best_ride(g) -> String:
	var best := ""
	var bs := 0.0
	for id in RIDE_ORDER:
		if g.rides.has(id) and float(RIDES[id].speed) > bs:
			bs = float(RIDES[id].speed)
			best = id
	return best
