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

## (the New Fire release: `asset_f` the same look on a woman's frame, art/characters/lin_feng_f*.py, and
## `desc_f` what it looks like on her; the rest of a look's words are told of her by UI.she)
const LOOKS := {
	"sweeper": {"n": "The Sweeper", "asset": "lin_feng", "asset_f": "lin_feng_f",
		"desc_f": "Hair pinned up in a knot with a jade pin through it, a cowlick no pin can hold down, and a level, serious mouth: the girl who swept the sect's steps for three years and never once complained out loud.",
		"desc": "A topknot tied up with a copper crown and a jade pin, a cowlick no pin can hold down, and a stern young mouth: the boy who swept the sect's steps for three years and never once complained out loud."},
	"wanderer": {"n": "The Wanderer", "asset": "lin_feng_wanderer", "asset_f": "lin_feng_f_wanderer",
		"desc_f": "Hair in one long braid down the back, tied with a red cord, and an easy smile that has talked her out of more trouble than it has got her into. She looks like somebody who is always about to leave.",
		"desc": "Hair in one long braid down the back, tied with a red cord, and an easy smile that has talked him out of more trouble than it has got him into. He looks like somebody who is always about to leave."},
	"wild": {"n": "The Wild Child", "asset": "lin_feng_wild", "asset_f": "lin_feng_f_wild",
		"desc_f": "Hair that no comb has ever beaten, a grin with a chipped edge to it and a cowlick that stands up in the wind. The sect's elders have given up trying to make her look like a disciple.",
		"desc": "Hair that no comb has ever beaten, a grin with a chipped edge to it and a cowlick that stands up in the wind. The sect's elders have given up trying to make him look like a disciple."},
	"scholar": {"n": "The Scholar's Ward", "asset": "lin_feng_scholar", "asset_f": "lin_feng_f_scholar",
		"desc_f": "Long straight hair and a calm, thoughtful face that reads before it speaks. She looks younger than she is until she frowns at something, and then she looks like somebody's grandmother.",
		"desc": "Short, neatly cropped hair and a calm, thoughtful face that reads before it speaks. He looks younger than he is until he frowns at something, and then he looks like somebody's grandfather."},
}
const LOOK_ORDER := ["sweeper", "wanderer", "wild", "scholar"]
## Who the sweeper is (the New Fire release): a young man or a young woman.  The story is the same
## story; it calls her she (UI.she), the juniors call her Senior Sister, and Granny Wen raised a girl.
const BODIES := {"m": {"n": "A young man", "desc": "The sweeper of the story as it was first told: Lin Feng, a boy of thirteen when he climbed the steps, sixteen now."},
	"f": {"n": "A young woman", "desc": "The sweeper of the story, and the story is hers: Lin Feng, a girl of thirteen when she climbed the steps, sixteen now. The world calls her she, the juniors call her Senior Sister, and nothing else about the road is any easier."}}
const BODY_ORDER := ["m", "f"]

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
		"desc_f": "Scholar Wang, who failed the Court's examinations nine times, taught her her letters for nothing and then everything else for nothing too. She can read any script on any stone, and she has never once won a fight.",
		"fx": {"qi": 0.08, "cost": 0.04, "hp": -0.05}, "give": {"qi_pill": 1}, "fx_text": "A mind trained on old books: qi +8% and techniques 4% cheaper, but health -5%. One Spirit Qi Pill."},
	"hunter": {"n": "Hunter's Apprentice", "short": "the old hunter's apprentice",
		"desc": "Old Geng, who hunted the edge of the Whispering Bamboo, took him on to carry the game and kept him on because he walked without breaking twigs. When Geng's knees went, the boy climbed the mountain instead.",
		"desc_f": "Old Geng, who hunted the edge of the Whispering Bamboo, took her on to carry the game and kept her on because she walked without breaking twigs. When Geng's knees went, the girl climbed the mountain instead.",
		"fx": {"atk": 0.05, "spd": 1, "qi": -0.05}, "give": {}, "fx_text": "A hunter's eye and feet: attack +5% and speed +1, but qi -5%. The old hunter's greens come with the trade."},
	"merchant": {"n": "Runner of the Four Roads", "short": "the runner of the Four Roads",
		"desc": "He ran messages between Qingshi and the caravans at Cloudfoot for copper coins, and learned to count in five currencies and haggle in three dialects. Caravan-Master Kang still says he owes him a donkey.",
		"desc_f": "She ran messages between Qingshi and the caravans at Cloudfoot for copper coins, and learned to count in five currencies and haggle in three dialects. Caravan-Master Kang still says she owes him a donkey.",
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
	return {"family": DEFAULT_FAMILY, "given": DEFAULT_GIVEN, "body": "m", "look": "sweeper", "hair": 0, "eyes": 0, "robe": 0, "origin": "foundling", "hearth": "valley"}

## Whether the hero `h` (Game.hero, or the choices of the creation screen) is a woman.
static func fem(h: Dictionary) -> bool:
	return str(h.get("body", "m")) == "f"

## The Blender model of look `look_id` for the hero's body.
static func look_asset(look_id: String, is_fem: bool) -> String:
	var lk: Dictionary = LOOKS.get(look_id, LOOKS.sweeper)
	return str(lk.asset_f) if is_fem else str(lk.asset)

## What the hero did in Qingshi before the broom, told of a young man or a young woman (the lines
## where another man is spoken of as well are written out for her: `desc_f`).
static func origin_desc(id: String, is_fem: bool) -> String:
	var o: Dictionary = ORIGINS.get(id, ORIGINS.foundling)
	if not is_fem:
		return str(o.desc)
	return str(o.desc_f) if o.has("desc_f") else Voice.her(str(o.desc))

static func look_desc(look_id: String, is_fem: bool) -> String:
	var lk: Dictionary = LOOKS.get(look_id, LOOKS.sweeper)
	return str(lk.desc_f) if is_fem else str(lk.desc)

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
	"pauldrons": "chest", "feather_mantle": "chest", "star_cloak": "chest", "ink_mask": "head", "dragon_horns": "head",
	# the Thundering Pots release: what the new outfits (and Yue Ling's) hang on them
	"war_helm": "head", "lamellar": "chest", "flute_sash": "chest", "clay_knot": "head", "back_banners": "chest", "rain_cape": "chest",
	"scholar_cap": "head", "fur_collar": "chest", "prayer_beads": "chest", "kite_tails": "chest", "head_lamp": "head", "back_broom": "chest",
	"opera_mask": "head", "fox_mask": "head", "flower_wreath": "head", "hair_ribbons": "head", "moon_pin": "head", "healer_satchel": "chest"}

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
	# ---- the Thundering Pots release: fourteen more, earned by the story (`step`), bought of Tailor Qiao in
	# Qingshi (`buy`, `at`), or given for a feat (`feat`, feats.gd), a commission of the notice board
	# (`job`, jobs.gd) or something found that nobody was told to look for (`egg`, eggs.gd)
	"levy": {"n": "Levy Captain's Lamellar", "cols": ["7a2a22", "2a2420", "c8a050"], "acc": ["war_helm", "lamellar"], "fx": {"hp": 0.05, "taken": -0.03},
		"desc": "Six hundred small plates of lacquered hide laced with red cord, a helmet with a pheasant's tail in it, and under them a farmer's jacket. Lady Hao had it laced the night the six hearths came in. It creaks. She says a host should hear its captain coming.", "how": "Laced for you by Lady Hao, when the levy of the six hearths has come in.", "step": "s_p23_levy"},
	"pipes": {"n": "Robe of the Twelve Pipes", "cols": ["d8c890", "5a4a2a", "3a7a5a"], "acc": ["flute_sash"], "fx": {"qi": 0.06, "cost": 0.03},
		"desc": "Bamboo-yellow silk with a green hem, and a flute of the valley of Xiexi thrust through the sash where a sword ought to go. Ling Lun cut the cloth the way a pipe is cut: to a length that is right, and cannot be argued with.", "how": "Cut for you by Ling Lun, when you can sing the airs of the land back to him.", "step": "s_p23_airs"},
	"clay": {"n": "Clay Soldier's Tunic", "cols": ["a8765a", "5a4032", "d8c8b0"], "acc": ["clay_knot"], "fx": {"taken": -0.05},
		"desc": "The long belted tunic of the foot of Mount Li, in the colours they were painted before the paint flaked: madder, and a neckcloth of bone white, and the topknot tied to the right as the ranks tied theirs. One of the eight thousand left it folded on the field. Inside the collar somebody has scratched a name, which the First Emperor's foremen made every potter do.", "how": "Left folded on the field for you, when the pots are quiet.", "step": "s_p23_end"},
	"marshal": {"n": "Grand Marshal's Crimson", "cols": ["a81e22", "1e1a1a", "e8c050"], "acc": ["war_helm", "pauldrons", "back_banners"], "fx": {"atk": 0.05, "hp": 0.04},
		"desc": "A crimson surcoat over black, gilded shoulders, and four small flags at the back as generals wear them on the stage, so that the hindmost rank can see which way the general is facing. Master Sun says that is all a general's dress is for.", "how": "For the feat The Field Is Held: win three field battles.", "feat": "war_three"},
	"rain": {"n": "Straw Rain-Cape", "cols": ["8a7a4a", "3a4a3a", "d8c080"], "acc": ["straw_hat", "rain_cape"], "fx": {"heal": 0.06},
		"desc": "A cape of layered rice straw and a hat to match, what the ploughmen of the valley wear from the Grain Rain to the Great Heat. Water runs off it into the boots. \"A bamboo staff and straw sandals beat a horse,\" says the song; \"in a cape of straw, in mist and rain, let a life go by.\"", "how": "Sold by Tailor Qiao in Qingshi.", "buy": 4000, "after": "s_vl_intro", "at": "tailor_qiao"},
	"exam": {"n": "Examination Blue", "cols": ["2a4a8a", "e8e4d8", "1a1a2a"], "acc": ["scholar_cap"], "fx": {"exp": 0.04},
		"desc": "The round-collared blue gown of a candidate, and the black gauze cap with two stiff wings that he hopes to be allowed to keep. Scholar Wang wore one like it into the examination hall nine times. Tailor Qiao has let this one out at the shoulders, for a candidate who carries a sword.", "how": "Sold by Tailor Qiao in Qingshi.", "buy": 6000, "after": "s_vl_intro", "at": "tailor_qiao"},
	"newyear": {"n": "New Year Red", "cols": ["c8281e", "3a1410", "f0c850"], "acc": [], "fx": {"stones": 0.06},
		"desc": "Red from collar to hem, with the character for good fortune in gold on the back, upside down, so that fortune has arrived. Nobody who sees it can bring himself to give short weight.", "how": "Sold by Tailor Qiao in Qingshi.", "buy": 8000, "after": "s_vl_intro", "at": "tailor_qiao"},
	"fur": {"n": "Steppe Fur Coat", "cols": ["8a6a4a", "4a3424", "e8e0d0"], "acc": ["fur_collar"], "fx": {"hp": 0.04, "taken": -0.02},
		"desc": "Sheepskin with the wool inside and a collar of fox, cut long for the saddle and belted with a rope of horsehair, as the horse-folk below Thunder Valley wear from the first frost. It smells of smoke and of horse, and no wind has yet found the way in.", "how": "Sold by Tailor Qiao in Qingshi.", "buy": 12000, "after": "s_vl_intro", "at": "tailor_qiao"},
	"pilgrim": {"n": "Pilgrim's White", "cols": ["ece8dc", "8a8478", "b88a3a"], "acc": ["prayer_beads", "straw_hat"], "fx": {"qi": 0.05, "heal": 0.04},
		"desc": "Undyed hemp, a string of a hundred and eight wooden beads worn smooth, and the broad hat that is all the roof a pilgrim owns. Every temple on the way up stamps the hem in red. His has nine stamps, one for each top he has stood on.", "how": "For the feat Nine Cairns: stand on nine summits.", "feat": "summits_nine"},
	"swallow": {"n": "Swallow-Tail Jacket", "cols": ["2a2a3a", "e8e8f0", "c83a2a"], "acc": ["kite_tails"], "fx": {"spd": 1, "miss": 0.02},
		"desc": "A short black jacket with a white breast and two long tails of ribbon at the back that stream in any air at all. The children who fly kites below Qingshi sewed it for him, to match the kite. From the ground, they say, nobody can tell which is which.", "how": "For the feat Master Lie Nods: fly a hundred metres in one flight.", "feat": "glide_far"},
	"delver": {"n": "Lamp-Black Delver's Coat", "cols": ["3a3630", "1a1816", "e8a040"], "acc": ["head_lamp"], "fx": {"taken": -0.03, "stones": 0.04},
		"desc": "Oiled leather the colour of a lamp's own smoke, and a small brass lamp strapped to the brow in the way of the salt-well men of the south. Xu Xiake wore out two of these. It keeps off the drip, and it finds what was dropped.", "how": "For the feat The Ground Is Hollow: go to the very back of six caves.", "feat": "delve_six"},
	"broom": {"n": "The Broom Immortal's Patches", "cols": ["6a7a8a", "4a3a2a", "c8b070"], "acc": ["back_broom"], "fx": {"exp": 0.03, "spd": 1},
		"desc": "The robe he swept the steps in, kept, and patched until there is more patch than robe, with the old broom slung across the back where other men carry a sword. Nobody gave it to him. It was in the cupboard the whole time.", "how": "Not earned. Remembered.", "egg": "old_code"},
	"opera": {"n": "Painted Face of the Pear Garden", "cols": ["1e6a5a", "c8a030", "f0f0f0"], "acc": ["opera_mask", "back_banners"], "fx": {"atk": 0.04, "miss": 0.02},
		"desc": "The green and gold of a stage general, four flags at the back, and the face painted on a mask of lacquered paper: red for the loyal, black for the upright, white for the ones to watch. This one is red. The players of Qingshi's stage insisted.", "how": "From the players of the Pear Garden stage in Qingshi, for a commission of the notice board.", "job": "job_stage"},
	"fox": {"n": "Fox-Fire Festival Robe", "cols": ["e87a2a", "f4f0e8", "2a2a2a"], "acc": ["fox_mask"], "fx": {"miss": 0.04},
		"desc": "Persimmon orange over white, and a fox's face in painted wood, worn pushed up on the side of the head as the Tianhu's children wear theirs on festival nights. In it he is a little hard to look at straight, the way a thing seen from the corner of the eye is.", "how": "From Tailor Qiao, for a commission of the notice board.", "job": "job_masks"},
}
const OUTFIT_ORDER := ["sweeper", "inner", "hunter", "dragon", "phoenix", "celestial", "immortal", "ink", "brocade", "starlit", "sea", "conclave",
	"rain", "exam", "newyear", "fur", "pilgrim", "swallow", "delver", "broom", "fox", "opera", "levy", "pipes", "marshal", "clay"]

# ---------------------------------------------------------------- Yue Ling's wardrobe
## The Thundering Pots release: Yue Ling has clothes of her own (Esc > Wardrobe > hers).  `cols` her
## dress, its sash and skirt, and its trims ("" keeps the rose she woke in); `acc` what hangs on her;
## `fx` a small passive of her own (hp, qi, atk, spd, heal: Game.yue_gear).  `bond` how close the two
## must be before she will wear it for him (bonds.gd), `step` the step of the story that gives it,
## `buy` Tailor Qiao's price, `feat` the feat that earns it.
const YUE_OUTFITS := {
	"lotus": {"n": "Lotus Rose", "cols": ["", "", ""], "acc": [], "fx": {},
		"desc": "The rose dress she woke in beside the pond, with the ribbon in her hair. She has mended the hem eleven times and will not hear of another.", "how": "Hers from the start."},
	"healer": {"n": "Healer's White", "cols": ["f2f0ea", "5a8a7a", "c83a3a"], "acc": ["healer_satchel"], "fx": {"heal": 0.06},
		"desc": "White linen that shows every stain, on purpose, a green apron, and the satchel of the wandering physicians with its red cord. Granny Wen cut it down from her own.", "how": "Granny Wen's, once the two of you are friends.", "bond": 10},
	"plum": {"n": "Plum Blossom in Snow", "cols": ["f4f0f4", "8a2a4a", "e86a8a"], "acc": ["flower_wreath"], "fx": {"qi": 0.05},
		"desc": "White with a wine-red skirt and a sprig of winter plum in the hair: the flower that opens in the snow, before any leaf. She says it is only a dress. She wore it the first morning she did not look over her shoulder.", "how": "She wears it once the two of you are close.", "bond": 25},
	"moon": {"n": "Moon-Palace Silver", "cols": ["d8e0f0", "6a78a8", "f4f6ff"], "acc": ["moon_pin"], "fx": {"qi": 0.04, "spd": 1},
		"desc": "Silver-grey gauze over blue, and a crescent of white jade in the hair. Chang'e sent it down by the Jade Rabbit with a note: it has not been worn in four thousand years, and it would like to dance.", "how": "Sent down by Chang'e, when the two of you are closer than close.", "bond": 45},
	"willow": {"n": "Willow Green", "cols": ["8ac878", "3a5a3a", "f0e8a0"], "acc": ["hair_ribbons"], "fx": {"hp": 0.05},
		"desc": "The green of the first week of spring, with long yellow ribbons that do what the wind tells them. The colour, she says, of something that has decided to come back.", "how": "Sold by Tailor Qiao in Qingshi.", "buy": 5000, "after": "s_vl_intro"},
	"redbride": {"n": "Festival Scarlet", "cols": ["c82a2a", "5a1418", "f0c850"], "acc": ["flower_wreath", "hair_ribbons"], "fx": {"atk": 0.05},
		"desc": "Scarlet and gold for the fifteenth night, flowers in the hair, ribbons to the knee. Little Hua of Qingshi says it is a bride's dress. Yue Ling says it is not, and has gone the colour of it.", "how": "Sold by Tailor Qiao in Qingshi.", "buy": 9000, "after": "s_vl_intro"},
	"snowfur": {"n": "Snow-Country Furs", "cols": ["e8e4dc", "7a6a5a", "b8c8d8"], "acc": ["fur_collar"], "fx": {"hp": 0.04, "heal": 0.03},
		"desc": "Quilted white with a collar of hare, what the women of Frostpeak wear to break the ice on the well. A thing of the pond has no business being cold, she says, and pulls the collar up.", "how": "Sold by Tailor Qiao in Qingshi.", "buy": 11000, "after": "s_vl_intro"},
	"surgeon": {"n": "Field Surgeon's Blue", "cols": ["3a5a8a", "e8e4d8", "c83a3a"], "acc": ["healer_satchel", "hair_ribbons"], "fx": {"heal": 0.08, "hp": 0.03},
		"desc": "Indigo cotton with the sleeves tied back, a white apron and the satchel: what she wore behind the levy's centre, where they carried the hurt of both hosts. She did not ask which side a man had stood on. Clay mends with rice glue, it turns out, and patience.", "how": "Hers when the levy of the six hearths has come in.", "step": "s_p23_levy"},
	"dancer": {"n": "Pear Garden Dancer's Sleeves", "cols": ["f0a8c0", "6a3a8a", "f4f0ff"], "acc": ["flower_wreath"], "fx": {"spd": 2},
		"desc": "Water sleeves three times the length of an arm, made to be thrown and caught, in peach and violet. Ling Lun says a dancer is the only instrument that tunes itself.", "how": "Cut for her by Ling Lun, with the Robe of the Twelve Pipes.", "step": "s_p23_airs"},
	"star": {"n": "Her Own Star", "cols": ["2a2a5c", "0e1030", "f0e8a0"], "acc": ["moon_pin", "hair_ribbons"], "fx": {"qi": 0.06, "atk": 0.04},
		"desc": "Midnight blue with one small gold star embroidered over the heart, the one the Archivist wrote into the Annals under her name. She sewed the star herself. It is a little crooked, and she will not have it straightened.", "how": "For the feat Two Under One Kite: fly thirty flights together.", "feat": "glide_thirty"},
}
const YUE_ORDER := ["lotus", "healer", "plum", "moon", "willow", "redbride", "snowfur", "surgeon", "dancer", "star"]

## The colours Yue Ling is drawn in ({"robe", "sec", "trim"}; empty for the dress she woke in).
static func yue_colors(g) -> Dictionary:
	var out := {}
	var o: Dictionary = YUE_OUTFITS.get(str(g.yue_outfit), YUE_OUTFITS.lotus)
	var keys := ["robe", "sec", "trim"]
	for k in 3:
		if str(o.cols[k]) != "":
			out[keys[k]] = Color(str(o.cols[k]))
	return out

## One passive of the dress Yue Ling wears.
static func yue_gear(g, key: String) -> float:
	return float(YUE_OUTFITS.get(str(g.yue_outfit), YUE_OUTFITS.lotus).fx.get(key, 0.0))

## The dresses of hers the journey has earned so far that she does not yet have: by how close the two
## are, and by the steps of the story done (Game.poll_wardrobe gives them).
static func yue_earned(g) -> Array:
	var out: Array = []
	for id in YUE_ORDER:
		var o: Dictionary = YUE_OUTFITS[id]
		if g.yue_outfits.has(id):
			continue
		if (o.has("bond") and g.bond >= int(o.bond)) or (o.has("step") and g.done(str(o.step))):
			out.append(id)
	return out

## What Tailor Qiao has for Yue Ling now.
static func yue_for_sale(id: String, g) -> bool:
	var o: Dictionary = YUE_OUTFITS[id]
	return o.has("buy") and not g.yue_outfits.has(id) and g.companion and g.reached(str(o.get("after", "")))

## The outfits a feat, a commission or a find gives (`kind`: "feat", "job" or "egg"): [["outfit", id]]
## for his, [["yue", id]] for hers.
static func earned_by(kind: String, id: String) -> Array:
	var out: Array = []
	for oid in OUTFIT_ORDER:
		if str(OUTFITS[oid].get(kind, "")) == id:
			out.append(["outfit", oid])
	for yid in YUE_ORDER:
		if str(YUE_OUTFITS[yid].get(kind, "")) == id:
			out.append(["yue", yid])
	return out

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
	# ---- carriages (the Lost Horse release): `kind` "carriage": driven sitting down, with `seats` (where
	# each sitter's seat is: the hero's, Yue Ling's, and then whoever is being carried, offices.gd `fares`);
	# bought (`buy`: spirit stones) of whoever answers for a town (`at`: an office)
	"ox_cart": {"n": "Two-Wheeled Ox-Cart", "kind": "carriage", "model": "ox_cart", "speed": 1.08, "scale": 1.0, "seat": Vector3(-0.38, 1.48, 0.7), "pillion": Vector3(0.38, 1.48, 0.7),
		"seats": [Vector3(-0.38, 1.48, 0.7), Vector3(0.38, 1.48, 0.7), Vector3(-0.38, 1.48, -0.5), Vector3(0.38, 1.48, -0.5)], "buy": 6000, "at": "head_qingshi",
		"desc": "Two wheels as high as a man's chest, a bed of elm planks, a bench across the front and an ox who has done this road every market day for eleven years and sees no reason to hurry now. It seats four, if two of them do not mind the turnips.", "how": "Headman Luo of Qingshi will sell you the village's second-best."},
	"wagon": {"n": "Caravan Wagon of the Sand Road", "kind": "carriage", "model": "wagon", "speed": 1.2, "scale": 1.0, "seat": Vector3(-0.45, 1.54, 1.5), "pillion": Vector3(0.45, 1.54, 1.5),
		"seats": [Vector3(-0.45, 1.54, 1.5), Vector3(0.45, 1.54, 1.5), Vector3(-0.45, 1.54, 0.3), Vector3(0.45, 1.54, 0.3), Vector3(-0.45, 1.54, -0.9), Vector3(0.45, 1.54, -0.9)], "buy": 25000, "at": "reeve_well",
		"desc": "Four wheels, a hooped tilt of red felt against the sun, water-skins slung along both sides and two benches under the cover. Built at Shazhou for a road with nothing on it for nine days. It seats six, and the last caravan to use it left a dried fig in every crack.", "how": "Samira, Reeve of the Sweet Well, sells them at Shazhou."},
	"carriage": {"n": "Post-Carriage of Cloudfoot", "kind": "carriage", "model": "carriage", "speed": 1.3, "scale": 1.0, "seat": Vector3(-0.38, 1.7, 1.3), "pillion": Vector3(0.38, 1.7, 1.3),
		"seats": [Vector3(-0.38, 1.7, 1.3), Vector3(0.38, 1.7, 1.3), Vector3(-0.4, 1.56, -0.95), Vector3(0.4, 1.56, -0.95)], "buy": 40000, "at": "post_cloudfoot",
		"desc": "A closed body of black lacquer on leather springs, a blue curtain, a lantern at each corner of the roof and a box for the driver. The post runs one to the capital that is not there any more. It seats four: two on the box, and two inside who will tell you they are not being sick.", "how": "Postmaster Ge of Cloudfoot will part with one, for a price."},
}
const RIDE_ORDER := ["pony", "sword", "qilin", "cloud", "tiger", "barque", "ox_cart", "wagon", "carriage"]

## How many a ride seats (two for a beast, a sword or a cloud: the hero and one behind).
static func seats(id: String) -> int:
	return (RIDES.get(id, {}).get("seats", [0, 0]) as Array).size()

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

## The sum of one passive over the hero's origin, the outfit he wears (see the keys above) and the
## hearths of the land (cultures.gd: the gift of his own, and what each gives its guests).
static func gear(g, key: String) -> float:
	var v := float(origin_of(g).fx.get(key, 0.0)) + Cultures.gear(g, key)
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

## Who sells an outfit that is sold (Dyer Su at the Dawn Market, or Tailor Qiao in Qingshi).
static func seller(id: String) -> String:
	return str(OUTFITS[id].get("at", "dyer_su"))

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
