class_name Trials
extends RefCounted
## Many roads (Part XIII's release): the battles that carry the main story forward are guarded, and
## there is more than one way past each of them.
##
## A **trial** stands in front of a boss the story cannot go on without (the lord of every chapter,
## the eight Gate Generals of Part XIII and Chiyou at the heart of their formation).  Nobody
## unprepared is allowed to fight it, and it fights harder than the bosses before it (its `might`:
## health and attack multipliers).  Each trial has several **paths**, and each path asks for
## something different (its `needs`):
##
##   might    your own cultivation: a level, cultivation full at the peak of a realm, a tempered sword,
##            the branches of the Nine Heavens root
##   craft    an item made at Alchemist Mo's cauldron or Smith Tie's forge (RECIPES) from the essences
##            monsters leave behind, things found on the quests and spirit stones
##   wealth   spirit stones, paid
##   respect  renown: the respect of the world, earned from bosses, trials and the deeds townsfolk ask
##            of a cultivator (DEEDS)
##   dao      walking a Dao (Part XI), and how far
##   peoples  the standing of one of the peoples of the realms
##   relic    an item that has to be found or won, carried or given up
##
## The path chosen shapes the battle (its `boon`) and is remembered: the Journal and the Annals list
## the trials passed and how, and the ending names the road a player walked most.  Requirements are
## arrays: ["lv", n], ["peak", n], ["temper", n], ["ranks", n], ["item", id, n], ["give", id, n],
## ["stones", n], ["renown", n], ["dao", id or "", tier], ["standing", race, n], ["friends", n],
## ["gates", n], and (Fates and Faces, fate.gd) ["fate", thread, [states]] (a fated encounter ended
## up in one of those states) and ["bonds", n] (so many of the five stand with Lin Feng).  "give" and "stones" are paid when the path is taken (once: a lost battle does not
## charge again, see Game.paid).
##
## Everything here takes the game state `g` as an argument (the Game autoload in play, a game state
## of their own in the tests).

const KINDS := {
	"might": {"n": "By might", "col": Color("f0c860"), "what": "your own cultivation and your blade"},
	"craft": {"n": "By craft", "col": Color("5fd6a4"), "what": "something made at the cauldron or the forge"},
	"wealth": {"n": "By wealth", "col": Color("e8a040"), "what": "spirit stones"},
	"respect": {"n": "By respect", "col": Color("f08ab0"), "what": "the respect of the world"},
	"dao": {"n": "By the Dao", "col": Color("a8c8ff"), "what": "the road you walk"},
	"peoples": {"n": "By friendship", "col": Color("8ae0c0"), "what": "the friendship of a people"},
	"relic": {"n": "By a relic", "col": Color("c8a8ff"), "what": "something found and kept"},
	# Fates and Faces: somebody whose life Lin Feng changed comes to help (fate.gd)
	"bond": {"n": "By an old bond", "col": Color("f0a8d8"), "what": "somebody whose fate you shaped"},
	# the Lotus release (Part XV): the two of them, side by side (bonds.gd)
	"heart": {"n": "Side by side", "col": Color("ff9ac0"), "what": "how close you and Yue Ling have come"},
	# the Living Land release (Part XVI): the people of the towns (folk.gd), who remember the old ways
	"folk": {"n": "By the people", "col": Color("ffb060"), "what": "the towns that remember the old ways"},
	# the Spring Thunder release (Part XVII): the land Lin Feng opened with his own sword (impact.gd)
	"land": {"n": "By the land", "col": Color("9ad870"), "what": "the land you have opened with your own blade"},
	# the New Fire release (Part XVIII): the hearths of the land that call the hero a guest (cultures.gd)
	"hearth": {"n": "By the hearths", "col": Color("f0a060"), "what": "the hearths of the land that call you a guest"},
	# the Hundred Works release (Part XIX): what Lin Feng has built with his own hands (works.gd)
	"works": {"n": "By the works", "col": Color("7ab8d8"), "what": "what you have built with your own hands"},
	# the Hollow Hills release (Part XX): the caves Lin Feng has gone to the very back of (caves.gd)
	"delve": {"n": "By the dark", "col": Color("8ad0c8"), "what": "the caves you have gone to the very back of"},
	# the Hundred Arms release (Part XXI): the Daos of arms Lin Feng has learned to Adept (arms.gd)
	"arms": {"n": "By the hand", "col": Color("dce8ff"), "what": "the weapons whose Dao you have learned"},
	# the High Roads release (peaks.gd): the summits stood on
	"heights": {"n": "By the heights", "col": Color("f4f8ff"), "what": "the summits you have stood on"},
	# the Thundering Pots release: the host that was raised (war.gd), and the airs of the land (music.gd)
	"host": {"n": "By the host", "col": Color("e0705a"), "what": "the companies that came when they were asked"},
	"song": {"n": "By the song", "col": Color("c8a0e8"), "what": "the airs of the land you have learned"},
	# the Lost Horse release: what was lost to and gone on from (dooms.gd), and what the choices left standing (marks.gd)
	"loss": {"n": "By the loss", "col": Color("9ab8c8"), "what": "the things that could not be beaten, which you lost to and went on from"},
	"mark": {"n": "By what stands", "col": Color("f0c8a0"), "what": "the things your choices left standing in the land, gone and looked at"},
}
const KIND_ORDER := ["might", "craft", "wealth", "respect", "dao", "peoples", "relic", "bond", "heart", "folk", "land", "hearth", "works", "delve", "arms", "heights", "host", "song", "loss", "mark"]

## How a trial boss fights by default when a path has nothing to say: [health, attack] multipliers.
const MIGHT := [1.5, 1.15]
## A trial boss brought this low is enraged: its blows land harder for the rest of the battle.
const ENRAGE_AT := 0.35
const ENRAGE := 1.2

# ---------------------------------------------------------------- essences: what monsters leave behind
## Every foe defeated in an ordinary battle may leave a little of its element behind (bosses always
## do, three times over); alchemists and smiths work these essences, and townsfolk ask for them.
const ESSENCE := {"wood": "ess_wood", "fire": "ess_fire", "water": "ess_water", "earth": "ess_earth", "thunder": "ess_thunder", "dark": "ess_dark", "phys": "ess_metal"}
const ESSENCE_ORDER := ["ess_wood", "ess_fire", "ess_water", "ess_earth", "ess_thunder", "ess_dark", "ess_metal"]
const ESS_DROP := 0.4
const ESS_BOSS := 3

static func essence_of(elem: String) -> String:
	return str(ESSENCE.get(elem, ""))

## The element an essence item belongs to (its colour on screen).
static func elem_of(ek: String) -> String:
	for el in ESSENCE:
		if ESSENCE[el] == ek:
			return el
	return "phys"

# ---------------------------------------------------------------- renown: the respect of the world
## Renown is never spent.  It grows with every boss (RENOWN_BOSS), every trial passed (RENOWN_TRIAL),
## every keepsake given to one of the peoples (RENOWN_GIFT) and every deed done for somebody who asked.
const RENOWN_BOSS := 2
const RENOWN_TRIAL := 4
const RENOWN_GIFT := 2
const RENOWN_TITLES := [[0, "Unknown"], [30, "Noticed"], [80, "Respected"], [160, "Renowned"], [280, "Famed"], [420, "Revered"], [600, "Legendary"]]

static func renown_title(n: int) -> String:
	var out := str(RENOWN_TITLES[0][1])
	for rt in RENOWN_TITLES:
		if n >= int(rt[0]):
			out = str(rt[1])
	return out

# ---------------------------------------------------------------- crafting
const STATIONS := {"alchemist": "Alchemist Mo's cauldron", "smith": "Smith Tie's forge"}
## What can be made, where, from what (`in`: item -> count, and spirit stones), listed at the station
## once the story reaches `after`, for the trial in `for` (and no longer once that trial is passed).
const RECIPES := {
	"smoke_pellet": {"at": "alchemist", "in": {"ess_wood": 2, "herb": 1}, "stones": 30, "after": "s_hunt1", "for": "iron_fang"},
	"grounding_rod": {"at": "smith", "in": {"ess_thunder": 3, "jade": 2}, "stones": 250, "after": "s_hunt4", "for": "thunder_roc"},
	"thunder_seal": {"at": "alchemist", "in": {"ess_thunder": 6, "shard": 2}, "stones": 600, "after": "s_hunt5", "for": "demon_lord"},
	"tide_ward": {"at": "alchemist", "in": {"ess_water": 5, "pearl": 2}, "stones": 1500, "after": "s_vo_hunt", "for": "inferno_lord"},
	"unmaking_sigil": {"at": "smith", "in": {"ess_metal": 6, "sigil": 2}, "stones": 3000, "after": "s_ce_hunt", "for": "heavenly_emperor"},
	"bearer_incense": {"at": "alchemist", "in": {"ess_dark": 6, "relic": 2}, "stones": 4000, "after": "s_gv_hunt", "for": "founder_qing"},
	"rune_lantern": {"at": "alchemist", "in": {"ess_dark": 8, "rune": 2}, "stones": 6000, "after": "s_or_hunt", "for": "hollow_heaven"},
	"court_seal": {"at": "smith", "in": {"ess_earth": 5, "seal": 2}, "stones": 8000, "after": "s_ct_hunt", "for": "registrar_siming"},
	"forget_ink": {"at": "alchemist", "in": {"ess_water": 8, "peach": 2}, "stones": 10000, "after": "s_gd_hunt", "for": "jade_ledger"},
	"glowcap_lantern": {"at": "alchemist", "in": {"ess_fire": 5, "glowcap": 2}, "stones": 12000, "after": "s_fu_hunt", "for": "vermilion_bird"},
	"five_lens": {"at": "smith", "in": {"ess_dark": 8, "five_stone": 2}, "stones": 16000, "after": "s_ch_hunt", "for": "hundun"},
	"memory_abacus": {"at": "smith", "in": {"ess_earth": 5, "memory_pearl": 2}, "stones": 18000, "after": "s_kr_hunt", "for": "horse_face"},
	"mercy_lotus": {"at": "alchemist", "in": {"ess_fire": 5, "ess_dark": 5, "wheel_spoke": 2}, "stones": 24000, "after": "s_wh_hunt", "for": "king_yama"},
	"tea_smoke": {"at": "alchemist", "in": {"ess_water": 6, "tea_bud": 2}, "stones": 26000, "after": "s_te_hunt", "for": "thread_matron"},
	"loom_scissors": {"at": "smith", "in": {"ess_earth": 5, "ess_thunder": 4, "shuttle": 2}, "stones": 34000, "after": "s_lm_hunt", "for": "qianxian"},
	"marshal_orders": {"at": "alchemist", "in": {"ess_thunder": 4, "ess_earth": 3, "magpie_plume": 2}, "stones": 40000, "after": "s_mg_hunt", "for": "crow_marshal"},
	"peach_talisman": {"at": "alchemist", "in": {"ess_wood": 8, "kunlun_peach": 2}, "stones": 48000, "after": "s_jp_hunt", "for": "xiwangmu"},
	"rain_charm": {"at": "alchemist", "in": {"ess_wood": 5, "ess_earth": 3, "rain_stone": 2}, "stones": 56000, "after": "s_mf_hunt", "for": "bifang"},
	"moon_mirror": {"at": "smith", "in": {"ess_water": 5, "ess_thunder": 4, "osmanthus": 2}, "stones": 64000, "after": "s_gh_hunt", "for": "xihe"},
	"yu_plan": {"at": "alchemist", "in": {"ess_water": 6, "ess_dark": 3, "xirang": 2}, "stones": 76000, "after": "s_df_hunt", "for": "gun"},
	"dyke_charm": {"at": "alchemist", "in": {"ess_water": 8, "ess_earth": 4, "pillar_stone": 2}, "stones": 84000, "after": "s_bz_hunt", "for": "gonggong"},
	"heaven_prop": {"at": "smith", "in": {"ess_metal": 5, "ess_earth": 4, "gate_key": 2}, "stones": 92000, "after": "s_cg_hunt", "for": "chong"},
	"root_lantern": {"at": "alchemist", "in": {"ess_dark": 6, "ess_fire": 4, "soul_tally": 2}, "stones": 100000, "after": "s_yd_hunt", "for": "li"},
	"dew_flask": {"at": "alchemist", "in": {"ess_wood": 6, "pearl_dew": 2}, "stones": 110000, "after": "s_fz_hunt", "for": "tianwu"},
	"fleet_compass": {"at": "smith", "in": {"ess_dark": 6, "ess_earth": 4, "xufu_log": 2}, "stones": 120000, "after": "s_gx_hunt", "for": "xu_fu"},
	# ---- Part XIII: keys for the Eight Gates, and the elixir that sends a war god home
	"drought_fan": {"at": "alchemist", "in": {"ess_fire": 8, "noon_ember": 2}, "stones": 120000, "after": "s_p13_gates", "for": "yu_shi"},
	"clear_mirror": {"at": "smith", "in": {"ess_metal": 8, "jingwei_stone": 2}, "stones": 140000, "after": "s_p13_gates", "for": "red_banner"},
	"kui_drumstick": {"at": "smith", "in": {"ess_earth": 8, "wind_bell": 2}, "stones": 130000, "after": "s_p13_gates", "for": "kui_drum"},
	# ---- Part XIV: a mirror in which a debt can see whether it was ever owed
	"settled_mirror": {"at": "smith", "in": {"ess_dark": 8, "ess_metal": 6, "wheel_spoke": 2}, "stones": 200000, "after": "s_p14_judge", "for": "nie"},
	# ---- Part XV: a shuttle that weaves back what is unwoven, and a key that opens by leaving open
	"lotus_shuttle": {"at": "alchemist", "in": {"ess_wood": 8, "ess_water": 4, "pressed_petal": 3}, "stones": 220000, "after": "s_p15_memories", "for": "unweaver"},
	"open_key": {"at": "smith", "in": {"ess_metal": 8, "ess_dark": 5, "pressed_petal": 2}, "stones": 240000, "after": "s_p15_memories", "for": "lock_warden"},
	# ---- Part XVI (the Living Land release): red, fire and noise
	"thunder_cracker": {"at": "alchemist", "in": {"ess_fire": 8, "thunder_bamboo": 2}, "stones": 260000, "after": "s_p16_rally", "for": "xi_beast"},
	# the New Fire release (Part XVIII): a drill of summer wood, made the way Suiren made his
	# the Hundred Works release (Part XIX): the belt and nine sticks Mozi laid in front of a king
	"defence_models": {"at": "smith", "in": {"ess_wood": 8, "ess_metal": 6, "catalpa_timber": 1}, "stones": 360000, "after": "s_p19_cogs", "for": "cloud_ladder"},
	# the Hollow Hills release (Part XX): a clay bell for the Lamb of the Earth, and the traveller's torch
	"lamb_bell": {"at": "alchemist", "in": {"ess_earth": 8, "ess_water": 6, "earth_basket": 1}, "stones": 240000, "after": "s_p20_moles", "for": "fen_yang"},
	# the Hundred Arms release (Part XXI): peaches for an ape, one scabbard for two swords, and a cock of wood
	"ape_fruit": {"at": "alchemist", "in": {"ess_wood": 8, "ess_water": 6, "bamboo_switch": 1}, "stones": 250000, "after": "s_p21_ape", "for": "yuan_gong"},
	# Part XXII: green bamboo that cracks in the fire, and a king's jade slip ground smooth
	"crackle_bamboo": {"at": "alchemist", "in": {"ess_earth": 8, "ess_water": 6, "salt_bag": 1}, "stones": 260000, "after": "s_p22_xiao", "for": "shanxiao"},
	"blank_slip": {"at": "smith", "in": {"ess_earth": 8, "ess_fire": 6, "merit_slip": 1}, "stones": 270000, "after": "s_p22_yue", "for": "dongyue"},
	"mated_scabbard": {"at": "smith", "in": {"ess_water": 8, "ess_metal": 6, "old_hilt": 1}, "stones": 250000, "after": "s_p21_dragons", "for": "sword_dragons"},
	"wooden_cock": {"at": "smith", "in": {"ess_wood": 8, "ess_fire": 6, "challenge_tally": 1}, "stones": 250000, "after": "s_p21_zhao", "for": "king_zhao"},
	"pine_torch": {"at": "smith", "in": {"ess_fire": 6, "ess_wood": 6, "cave_rubbing": 1}, "stones": 240000, "after": "s_p20_shades", "for": "wangliang"},
	"fire_drill": {"at": "smith", "in": {"ess_wood": 8, "ess_fire": 6, "apricot_wood": 2}, "stones": 340000, "after": "s_p18_valley", "for": "zhurong"},
	# the Spring Thunder release (Part XVII)
	"warm_brazier": {"at": "alchemist", "in": {"ess_fire": 8, "ess_wood": 6}, "stones": 300000, "after": "s_p17_ice", "for": "qing_nu"},
	"taisui_charm": {"at": "smith", "in": {"ess_earth": 8, "ess_metal": 6, "thunder_egg": 1}, "stones": 320000, "after": "s_p17_thunder", "for": "taisui"},
	"hearth_lantern": {"at": "smith", "in": {"ess_fire": 6, "ess_metal": 5, "thunder_bamboo": 2}, "stones": 280000, "after": "s_p16_hunt", "for": "nian"},
	"homing_elixir": {"at": "alchemist", "in": {"ess_wood": 5, "ess_fire": 5, "ess_water": 5, "ess_earth": 5, "ess_metal": 5, "autumn_leaf": 1}, "stones": 300000, "after": "s_p13_gates", "for": "chiyou"},
}

## What a recipe costs in spirit stones: Alchemist Mo's are cheaper with the Hag's apprentice at his
## side (fate.gd, Liu Ying).
static func recipe_stones(id: String, g) -> int:
	var r: Dictionary = RECIPES[id]
	var k := 1.0 - (Fate.mo_discount(g) if str(r.at) == "alchemist" else 0.0)
	# (the water-bellows, works.gd: a furnace blown by the river burns less)
	return int(round(int(r.get("stones", 0)) * k * Works.mod(g, "recipe")))

static func can_craft(id: String, g) -> bool:
	var r: Dictionary = RECIPES[id]
	if g.stones < recipe_stones(id, g):
		return false
	for k in r.in:
		if int(g.inv.get(k, 0)) < int(r.in[k]):
			return false
	return true

## Make one: the inputs and the stones are used up.  Returns whether it was made.
static func craft(id: String, g) -> bool:
	if not can_craft(id, g):
		return false
	var r: Dictionary = RECIPES[id]
	g.stones -= recipe_stones(id, g)
	for k in r.in:
		g.inv[k] = int(g.inv.get(k, 0)) - int(r.in[k])
	g.inv[id] = int(g.inv.get(id, 0)) + 1
	return true

## The recipes a station offers now: the story has reached them, their trial is still ahead, and the
## thing they make is not already in hand.
static func recipes_at(station: String, g) -> Array:
	var out: Array = []
	for id in RECIPES:
		var r: Dictionary = RECIPES[id]
		if str(r.at) != station or not g.reached(str(r.after)) or g.trials.has(str(r.get("for", ""))):
			continue
		if int(g.inv.get(id, 0)) > 0:
			continue
		out.append(id)
	return out

## "4 Thunder Essence (have 2), 2 Thunder Shard (have 4), 600 spirit stones (have 1,250)"
static func recipe_text(id: String, g) -> String:
	var r: Dictionary = RECIPES[id]
	var parts: Array = []
	for k in r.in:
		parts.append("%d %s (have %d)" % [int(r.in[k]), Data.ITEMS[k].n, int(g.inv.get(k, 0))])
	if int(r.get("stones", 0)) > 0:
		parts.append("%s spirit stones (have %s)%s" % [_num(recipe_stones(id, g)), _num(g.stones), " (Liu Ying's price)" if recipe_stones(id, g) < int(r.stones) else ""])
	return ", ".join(parts)

# ---------------------------------------------------------------- deeds: what townsfolk ask for
## A deed is asked once the story reaches `after`, by a townsperson who stays where they are for the
## rest of the game.  Bring what they want (`want`: item -> count) and talk to them: they take it,
## pay what they can, and the world thinks a little better of Lin Feng.
const DEEDS := {
	"deed_cook": {"npc": "cook_zhou", "area": "sect", "after": "s_hunt1", "want": {"ess_wood": 3}, "renown": 8, "stones": 60,
		"ask": "The winter cabbage will not pickle without a little wood in the brine. Three Wood Essences, and the whole sect eats sour cabbage till spring.",
		"thanks": "There. Smell that. That is a winter that will not taste of nothing."},
	"deed_bell": {"npc": "bell_shen", "area": "sect", "after": "s_elder2", "want": {"ess_metal": 3}, "renown": 8, "stones": 90,
		"ask": "The bell cracked the winter you came to us. Three Metal Essences would heal the crack. Bandit iron will do; it is all one to a bell.",
		"thanks": "Listen. LISTEN. ...Well, you will hear it at dawn. It sounds like a bell again."},
	"deed_gate": {"npc": "gate_wu", "area": "sect", "after": "s_elder3", "want": {"ess_water": 4}, "renown": 10, "stones": 150,
		"ask": "The warding pool by the gate has gone green and still. Four Water Essences from the frost beasts would wake it up.",
		"thanks": "It is moving again. The frogs are furious. Thank you, senior brother."},
	"deed_han": {"npc": "disciple_han", "area": "sect", "after": "s_elder4", "want": {"ess_thunder": 4}, "renown": 10, "stones": 200,
		"ask": "I want a sparring post that hits back. Four Thunder Essences wound into the wood, and the juniors will finally learn to duck.",
		"thanks": "It hit me. It actually hit me. This is the best day of my life."},
	"deed_courier": {"npc": "courier_ma", "area": "mountain", "after": "s_elder5", "want": {"ess_dark": 4}, "renown": 10, "stones": 240,
		"ask": "Something follows the night couriers on the north road. Old Wu says a charm of Yin Essence hides a rider from the dead. Four would do for all of us.",
		"thanks": "Nobody followed me last night. Or if they did, they followed somebody else. Thank you."},
	"deed_noodle": {"npc": "noodle_he", "area": "mountain", "after": "s_vo_hunt", "want": {"ess_fire": 4}, "renown": 10, "stones": 300,
		"ask": "Forty years my stove has had a fire-spirit in it, and last week it went out. Four Fire Essences from the volcano would light a new one.",
		"thanks": "Oh, it is a fierce little thing. It already hates the ladle. Noodles are free for you, forever."},
	"deed_pei": {"npc": "cartographer_pei", "area": "mountain", "after": "s_ce_hunt", "want": {"ess_metal": 4}, "renown": 10, "stones": 400,
		"ask": "My compass needle has forgotten north. Metal remembers; four Metal Essences, and it will point true again.",
		"thanks": "North! There you are. Now everything else is merely wrong, instead of impossible."},
	"deed_storyteller": {"npc": "storyteller_wu", "area": "mountain", "after": "s_vd_hunt", "want": {"star": 1}, "renown": 10, "stones": 500,
		"ask": "Thirty years I have told the story of the falling star, and never held one. Bring me one real Star Fragment and I will tell it right for once.",
		"thanks": "It is warm. Nobody ever said they are warm. Come on Thursday; the story is longer now."},
	"deed_mei": {"npc": "disciple_mei", "area": "sect", "after": "s_ml_hunt", "want": {"echo": 1}, "renown": 10, "stones": 800,
		"ask": "They say an Echo Shard from the Mirror Lake shows you who you would have been. I only want one look. Just one.",
		"thanks": "...She was a cook. I was a cook, in the other life. I think I would have liked it. Thank you."},
	"deed_priestess": {"npc": "priestess_yun", "area": "mountain", "after": "s_gv_hunt", "want": {"ess_dark": 5}, "renown": 12, "stones": 1200,
		"ask": "The restless dead walk the pilgrims' road at night since the Sword Graveyard woke. Five Yin Essences for the wayside shrines would quiet them.",
		"thanks": "The shrines are lit. The dead have somewhere to sit down now. So do the pilgrims."},
	"deed_xiaoqing": {"npc": "xiao_qing", "area": "sect", "after": "s_cs_hunt", "want": {"ess_wood": 5}, "renown": 12, "stones": 2000,
		"ask": "I planted a cloud-pine from a seed the Warden gave me and it will not wake. Five Wood Essences, please, before the Elder notices I killed it.",
		"thanks": "It is growing sideways. Into the clouds. I think that is correct for a cloud-pine?"},
	"deed_kang": {"npc": "caravan_kang", "area": "mountain", "after": "s_fg_hunt", "want": {"ess_fire": 5}, "renown": 12, "stones": 3000,
		"ask": "The road west is cold since the forges in heaven went quiet. Five Fire Essences for the caravan braziers, and my drivers stop deserting.",
		"thanks": "Warm hands, full wagons. The Caravanserai drinks to you tonight."},
	"deed_wei": {"npc": "clerk_wei", "area": "mountain", "after": "s_du_hunt", "want": {"ess_earth": 5}, "renown": 12, "stones": 4000,
		"ask": "I want to give back what I took for the Court. The farms on the south road lost their soil in the dust storms. Five Earth Essences would mend the worst field.",
		"thanks": "The farmer did not recognise me. That is the best thing that has happened to me in eleven years."},
	"deed_shitou": {"npc": "stableboy_shitou", "area": "mountain", "after": "s_au_hunt", "want": {"ess_water": 5}, "renown": 12, "stones": 5000,
		"ask": "The horses won't drink from the trough since the steppe herds stampeded past. Five Water Essences would sweeten it. Please. They are thirsty.",
		"thanks": "They are drinking! Even the grey one, who hates everything."},
	"deed_ruan": {"npc": "gardener_ruan", "area": "sect", "after": "s_mp_hunt", "want": {"ess_fire": 6}, "renown": 12, "stones": 7000,
		"ask": "Frost in the herb beds three nights running. Six Fire Essences buried under the paths would keep the roots warm through the winter.",
		"thanks": "Steam is coming up through the gravel. The ginseng is smug. It will be unbearable."},
	"deed_postmaster": {"npc": "postmaster_lu", "area": "mountain", "after": "s_sp_hunt", "want": {"ess_dark": 6}, "renown": 14, "stones": 9000,
		"ask": "Letters for the dead keep arriving at my station, and the Yellow Springs will not take them without a seal of Yin. Six Yin Essences, and the dead get their post.",
		"thanks": "Delivered. Every one. One of them wrote back, would you believe it."},
	"deed_granny_wen": {"npc": "granny_wen", "area": "village", "after": "s_vl_hunt", "want": {"ess_wood": 6}, "renown": 14, "stones": 11000,
		"ask": "The mulberries behind the house are dying, Feng'er, the ones you used to climb. Six Wood Essences in the roots, and they might see you married.",
		"thanks": "Look at them. Leafing out in autumn like fools. Just like you. Sit down, I am making soup."},
	"deed_tofu": {"npc": "tofu_sun", "area": "village", "after": "s_te_hunt", "want": {"ess_earth": 6}, "renown": 14, "stones": 13000,
		"ask": "My millstone cracked clean through. A stone mason says six Earth Essences will knit it. The village eats tofu or it eats nothing.",
		"thanks": "It grinds! Listen to it grind. The whole village will smell of beans by noon."},
	"deed_pan": {"npc": "tea_seller_pan", "area": "yanggu", "after": "s_yg_hunt", "want": {"ess_water": 6}, "renown": 14, "stones": 18000,
		"ask": "Nine days of noon cooked my spring. Six Water Essences and it might run cold again. Hot tea is wonderful; hot water to make it with is not.",
		"thanks": "Cold! Sweet and cold! Your tea is free in Yanggu for the rest of your life, which I hear is long."},
	"deed_dou": {"npc": "little_dou", "area": "yanggu", "after": "s_mf_hunt", "want": {"ess_thunder": 5}, "renown": 14, "stones": 20000,
		"ask": "I want to make a lantern that flashes like lightning for the festival. Five Thunder Essences. I will not set anything on fire. Probably.",
		"thanks": "IT FLASHES. Watchman Zhou already confiscated it twice. Best festival ever."},
	"deed_gao": {"npc": "boatwright_gao", "area": "longmen", "after": "s_dg_hunt", "want": {"ess_wood": 7}, "renown": 16, "stones": 26000,
		"ask": "The flood took every seasoned plank I had. Seven Wood Essences would season green timber in a day. The ferry needs a hull by spring.",
		"thanks": "Hear that hull ring? Seasoned, sweet and dry. She'll float for forty years."},
	"deed_rong": {"npc": "auntie_rong", "area": "tushan", "after": "s_ts_hunt", "want": {"ess_metal": 7}, "renown": 16, "stones": 30000,
		"ask": "The casting pits want good metal for the new temple bells, and the mines are flooded. Seven Metal Essences, and Tushan rings again.",
		"thanks": "The first bell is cooling now. We will ring it for you. It will be very loud."},
	"deed_luan": {"npc": "egg_warden_luan", "area": "juntian", "after": "s_jt_hunt", "want": {"ess_fire": 7}, "renown": 16, "stones": 36000,
		"ask": "The nursery's warming stones went cold in the storm, and there are forty eggs in the cellar. Seven Fire Essences, quickly, please.",
		"thanks": "Warm. All forty. One of them is already tapping. Every Yumin who hatches this year will know your name."},
	"deed_little_bei": {"npc": "little_bei", "area": "ninesprings", "after": "s_ns_hunt", "want": {"ess_water": 7}, "renown": 16, "stones": 40000,
		"ask": "My grandmother cried her last pearl for my naming day and has no tears left. Seven Water Essences, and she says she can cry again. She wants to cry at my wedding.",
		"thanks": "She cried. She is crying now, at you. Those are pearls, you may keep them."},
	"deed_zhi_ma": {"npc": "zhi_ma", "area": "youdu", "after": "s_yd_hunt", "want": {"ess_dark": 7}, "renown": 16, "stones": 44000,
		"ask": "My paper goods are for the dead, and the dead want them black as ink. Seven Yin Essences for the dye, and every shade in Youdu gets a new coat this winter.",
		"thanks": "Look at that black. You could fall into it. The dead will be insufferably smart."},
	"deed_ban": {"npc": "shipwright_ban", "area": "penglai", "after": "s_pl_hunt", "want": {"ess_metal": 8}, "renown": 18, "stones": 52000,
		"ask": "Landfall builds boats again and has no nails. Eight Metal Essences make a keg of nails. Two thousand years we waited for a reason to sail.",
		"thanks": "Nails! A whole keg! The first keel goes down tomorrow, and it will have your name on it."},
	"deed_furnace_boy": {"npc": "furnace_boy", "area": "fangzhang", "after": "s_fz_hunt", "want": {"ess_fire": 8}, "renown": 18, "stones": 56000,
		"ask": "The immortals' furnaces went cold the day the elixir furnace walked off. Eight Fire Essences and I can light one, and maybe they will let me stay as an apprentice.",
		"thanks": "It is lit! He Xiangu looked at it and nodded. She NODDED."},
	"deed_mist_fisher": {"npc": "mist_fisher", "area": "yingzhou", "after": "s_yz_hunt", "want": {"ess_water": 8}, "renown": 18, "stones": 60000,
		"ask": "The fish went with the sea, and the sea came back without them. Eight Water Essences in the shallows, and the little fish come home first.",
		"thanks": "Silver in the shallows. They came back. Everything does, now. You saw to that."},
}

## The deed a townsperson asks now ("" if none): the first, in order, that the story has reached and
## Lin Feng has not done.
static func deed_of(npc_id: String, g) -> String:
	for id in DEEDS:
		var d: Dictionary = DEEDS[id]
		if str(d.npc) == npc_id and not g.deeds.has(id) and g.reached(str(d.after)):
			return id
	return ""

## The region somebody lives in ("" if nowhere).
static func npc_area(id: String) -> String:
	for a in Data.AREAS:
		for n in Data.AREAS[a].get("npcs", []):
			if str(n.id) == id:
				return a
	return ""

## A townsperson's name by id.
static func npc_name(id: String) -> String:
	for a in Data.AREAS:
		for n in Data.AREAS[a].get("npcs", []):
			if str(n.id) == id:
				return str(n.n)
	return id

static func deed_ready(id: String, g) -> bool:
	var d: Dictionary = DEEDS[id]
	for k in d.want:
		if int(g.inv.get(k, 0)) < int(d.want[k]):
			return false
	return true

static func want_text(id: String, g) -> String:
	var d: Dictionary = DEEDS[id]
	var parts: Array = []
	for k in d.want:
		parts.append("%d %s (have %d)" % [int(d.want[k]), Data.ITEMS[k].n, int(g.inv.get(k, 0))])
	return ", ".join(parts)

# ---------------------------------------------------------------- Part XIII: the Eight Gates
## The Gate Generals of the Qimen formation round Chiyou (Part XIII), in the order of the old diagrams.
## Any GATES_NEEDED of them open the lock; every gate opened beyond that takes GATE_WEAKEN off Chiyou.
const GATES := ["xingtian", "yu_shi", "liang", "bronze_brothers", "red_banner", "mast_goblin", "fetter_maple", "kui_drum"]
const GATE_NAMES := {"xingtian": "the Gate of Opening", "yu_shi": "the Gate of Alarm", "liang": "the Gate of Rest", "bronze_brothers": "the Gate of Death",
	"red_banner": "the Gate of Sight", "mast_goblin": "the Gate of Closing", "fetter_maple": "the Gate of Life", "kui_drum": "the Gate of Harm"}
const GATE_STEP := "s_p13_gates"
const GATES_NEEDED := 4
const GATE_WEAKEN := 0.06

static func is_gate(boss: String) -> bool:
	return GATES.has(boss)

## The region a boss stands in ("" if none).
static func boss_area(boss: String) -> String:
	for a in Data.AREAS:
		for b in Data.AREAS[a].get("bosses", []):
			if str(b.id) == boss:
				return a
	return ""

# ---------------------------------------------------------------- the trials
const TRIALS := {
	# ---- Part I
	"iron_fang": {"might": [1.3, 1.1],
		"why": "Iron Fang never fights alone. His bandits hold the ridge above the camp with crossbows, and they have watched the road for a week. Walk up it unprepared and you will look like a hedgehog before you see him.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "Smoke-pellets", "needs": [["give", "smoke_pellet", 1]], "boon": {"foe_atk": 0.8, "foe_hp": 0.85},
				"desc": "Alchemist Mo can roll smoke-pellets from a spirit herb and a little wood essence. Bandits who cannot see cannot aim.",
				"line": "Lin Feng cracks a smoke-pellet on the rocks. The ridge vanishes in green smoke, forty crossbows loose at nothing, and Iron Fang comes down alone, coughing."},
			{"id": "wealth", "kind": "wealth", "n": "Buy off his lieutenants", "needs": [["stones", 150]], "boon": {"foe_hp": 0.8},
				"desc": "Bandits are paid by the job. A purse of spirit stones left on the right rock will empty half the ridge.",
				"line": "The purse is gone from the rock by noon, and so is half the ridge. The ones who stayed look embarrassed about it."},
			{"id": "might", "kind": "might", "n": "Walk up the middle of the road", "needs": [["lv", 2]], "boon": {},
				"desc": "Late Qi Condensation and nothing else: let them see you coming, and let them wonder why you are not afraid.",
				"line": "Lin Feng walks up the middle of the road. The crossbows follow him all the way, and not one of them fires."},
		]},
	"thunder_roc": {"might": [1.4, 1.1],
		"why": "The Thunder Roc rides the storm it makes. On its own crag it is never struck by its own lightning, and anything that climbs up to it always is.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A grounding rod of frost jade", "needs": [["item", "grounding_rod", 1]], "boon": {"no_heavy": true, "foe_hp": 0.85},
				"desc": "Frost Jade drinks lightning. Smith Tie can set two of the jades you brought down from Frostpeak in a rod bound with thunder essence: drive it into the crag, and the storm goes into the rod instead of you.",
				"line": "Lin Feng drives the grounding rod into the crag. The next bolt comes down, and goes into the jade, and the jade glows blue and hums."},
			{"id": "respect", "kind": "respect", "n": "The sword ancestor's word", "needs": [["renown", 30]], "boon": {"taken": 0.85, "assist": 0.02},
				"desc": "The old sword ghost of Thunder Valley will stand on the crag with you, if the world has started to say your name.",
				"line": "The sword ghost of Thunder Valley comes up the crag at Lin Feng's shoulder, his old sword humming in the storm."},
			{"id": "wealth", "kind": "wealth", "n": "A storm-cloak from the caravans", "needs": [["stones", 900]], "boon": {"foe_atk": 0.85},
				"desc": "The salt caravans that cross Thunder Valley sell cloaks of oiled silk that lightning slides off. They are very expensive and they smell terrible.",
				"line": "The storm-cloak smells of tallow and old rain. The first bolt slides off it into the rock, and Lin Feng laughs."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 11], ["temper", 3]], "boon": {},
				"desc": "Cultivation full at Late Nascent Soul and a sword tempered three times: enough to stand in the storm and be struck.",
				"line": "Lin Feng climbs the crag in the open, and lets the storm find him."},
		]},
	"inferno_lord": {"might": [1.4, 1.1],
		"why": "Chi Yan is the last flame of the Blood Moon, and the volcano is his body now. Every vent in the mountain breathes when he breathes, and the air at the crater would cook a man where he stood.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A tide-pearl ward", "needs": [["item", "tide_ward", 1]], "boon": {"weak_k": 1.9, "foe_hp": 0.85},
				"desc": "Two Dragon Pearls from the sunken halls, sealed in water essence: the sea remembers where it lives, and carries it with you into the fire.",
				"line": "The tide-pearl ward opens round Lin Feng like a bubble of cold sea, and the crater's breath hisses off it."},
			{"id": "respect", "kind": "respect", "n": "Sage Huo Rong opens the vents", "needs": [["renown", 65]], "boon": {"taken": 0.85, "assist": 0.02},
				"desc": "Sage Huo Rong knows the old cooling vents of the volcano. She will open them for a cultivator whose name she has heard of.",
				"line": "Far down the mountain Sage Huo Rong opens the old vents one by one, and the crater draws a long cool breath."},
			{"id": "wealth", "kind": "wealth", "n": "Cooling-stones from the fire sage's store", "needs": [["stones", 4500]], "boon": {"foe_atk": 0.85, "foe_hp": 0.85},
				"desc": "The fire sage's disciples sell cooling-stones by the cartload to anybody who needs to stand in a volcano. Nobody ever buys a cartload.",
				"line": "A cartload of cooling-stones goes into the crater ahead of Lin Feng, steaming, and the lava sulks."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 14], ["temper", 5]], "boon": {},
				"desc": "Cultivation full at Late Deity Transformation and a sword tempered five times.",
				"line": "Lin Feng walks into the crater with his own qi wrapped round him like armour, and the heat finds nothing to hold on to."},
		]},
	"founder_qing": {"might": [1.4, 1.1],
		"why": "Twenty bearers came to Founder Qing Lian's grave and not one reached it alive. She will be certain you are not the Emperor wearing a new face, and she was the greatest sword of her age.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "Incense of the twenty bearers", "needs": [["item", "bearer_incense", 1]], "boon": {"foe_atk": 0.8, "taken": 0.85},
				"desc": "Two Saint Relics burned with Yin essence make an incense the dead know. In its smoke the Founder will see your own face, and nobody else's.",
				"line": "The incense of the twenty bearers rises over the grave, and in the smoke Founder Qing Lian sees a sweeper's face, and lowers her sword a little."},
			{"id": "respect", "kind": "respect", "n": "The sword saints stand witness", "needs": [["renown", 120]], "boon": {"assist": 0.02, "taken": 0.85},
				"desc": "The saints of the graveyard will stand witness for a cultivator the world respects, and the Founder listens to her saints.",
				"line": "All round the grave the sword saints rise from their barrows and stand witness, and the Founder sees them."},
			{"id": "wealth", "kind": "wealth", "n": "Mend the saints' barrows", "needs": [["stones", 15000]], "boon": {"foe_hp": 0.8},
				"desc": "The barrows of the sword saints have been robbed and broken for a thousand years. Pay to mend every one, and the Founder will know what kind of heir has come.",
				"line": "Every barrow in the graveyard is mended by dawn, and the Founder walks the rows of them before she draws."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 20], ["temper", 7]], "boon": {},
				"desc": "Cultivation full at Late Dao Merging and a sword tempered seven times. She will want to see what the sect taught you.",
				"line": "Lin Feng salutes the Founder's grave with his sword, and she salutes back."},
		]},
	"registrar_siming": {"might": [1.4, 1.1],
		"why": "Grand Registrar Si Ming wrote every name the tribulations took for ten thousand years, and every seal of the Jade Court still answers to his brush. In his court the walls themselves are clerks.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A counter-seal of the Jade Court", "needs": [["item", "court_seal", 1]], "boon": {"no_heavy": true, "foe_hp": 0.8},
				"desc": "Two of the old Court's Jade Seals cut backwards on Smith Tie's wheel with earth essence: every stamp the Registrar makes, it unmakes.",
				"line": "Lin Feng presses the counter-seal on the court's great door, and every stamp on it lifts off and flutters away."},
			{"id": "respect", "kind": "respect", "n": "Scribe Wen Yu and the clerks testify", "needs": [["renown", 165]], "boon": {"assist": 0.025, "taken": 0.85},
				"desc": "The runaway scribe and the clerks who still stamp debts will put down their brushes for a cultivator the whole land respects.",
				"line": "One by one the clerks of the Jade Court put down their brushes, and Scribe Wen Yu reads out every name they have saved."},
			{"id": "wealth", "kind": "wealth", "n": "Buy up the Court's last debts", "needs": [["stones", 30000]], "boon": {"foe_hp": 0.75},
				"desc": "Every debt the Registrar still keeps can be bought and torn up. There are a great many of them.",
				"line": "Lin Feng buys every debt still on the Registrar's desk and tears them up in front of him, one at a time."},
			{"id": "might", "kind": "might", "n": "Strength the ink cannot hold", "needs": [["lv", 26], ["temper", 8]], "boon": {},
				"desc": "Late True Immortal and a sword tempered eight times: too much of a cultivator to be written down.",
				"line": "The Registrar writes Lin Feng's name in the ledger, and the ink will not stay on the page."},
		]},
	"vermilion_bird": {"might": [1.4, 1.1],
		"why": "Zhu Que's fire has gone wrong. It burns cold and it burns everything it touches, and the Southern Pillar is cracking in the frost of it.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "An ember-cap lantern", "needs": [["item", "glowcap_lantern", 1]], "boon": {"foe_atk": 0.85, "no_heavy": true},
				"desc": "Two Ember Glowcaps from the vale, steeped in fire essence, hold a warm flame: show her what her fire used to be.",
				"line": "Lin Feng holds up the ember-cap lantern, and Zhu Que stares at the warm little flame as if she has forgotten what it is."},
			{"id": "respect", "kind": "respect", "n": "Bai Hu speaks for you", "needs": [["renown", 210]], "boon": {"assist": 0.025, "taken": 0.85},
				"desc": "Bai Hu of the Western Pillar owes you his life, and will come south for a cultivator whose name the world speaks with respect.",
				"line": "Out of the west comes Bai Hu at a run, and the white tiger stands at Lin Feng's side in the cold fire."},
			{"id": "wealth", "kind": "wealth", "n": "A fortune in spirit coal", "needs": [["stones", 45000]], "boon": {"foe_hp": 0.8},
				"desc": "Feed her a mountain of spirit coal, and some of her cold fire may remember how to be warm.",
				"line": "A mountain of spirit coal goes into the vale, and a quarter of Zhu Que's cold fire turns red again."},
			{"id": "might", "kind": "might", "n": "Strength to stand in cold fire", "needs": [["lv", 29], ["ranks", 14]], "boon": {},
				"desc": "Late Dao Ancestor, and fourteen ranks of the Nine Heavens root awake.",
				"line": "Lin Feng walks into the cold fire, and lets it touch him, as he said he would."},
		]},
	"horse_face": {"might": [1.4, 1.1],
		"why": "Horse-Face counts every soul that passes on an abacus of teeth, and nothing passes him uncounted. To fight him you must first get to him, and the Yellow Springs are deep.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "An abacus of river pearls", "needs": [["item", "memory_abacus", 1]], "boon": {"no_heavy": true, "foe_hp": 0.8},
				"desc": "Two River Pearls of Memory strung on an abacus with earth essence: every soul it counts, it remembers by name. Show him a better way to count.",
				"line": "Lin Feng holds up the pearl abacus, and Horse-Face stops counting for the first time in an age to look at it."},
			{"id": "respect", "kind": "respect", "n": "The fisherman of the Stone Forest", "needs": [["renown", 260]], "boon": {"taken": 0.85, "assist": 0.025},
				"desc": "The old fisherman of the Stone Forest will row you out to Horse-Face's ford, for somebody whose name is worth the trip.",
				"line": "The fisherman's boat noses into the ford, and every cormorant of the Stone Forest dives at Horse-Face's abacus."},
			{"id": "wealth", "kind": "wealth", "n": "The ferry-fare of the counted", "needs": [["stones", 60000]], "boon": {"foe_atk": 0.85, "foe_hp": 0.85},
				"desc": "Pay the fares of the souls he is holding at the ford, and he has fewer to count and less to fight for.",
				"line": "Lin Feng pays the fare of every lantern in the ford, and they drift on, and Horse-Face loses count."},
			{"id": "might", "kind": "might", "n": "Too strong to be counted", "needs": [["lv", 32], ["ranks", 16]], "boon": {},
				"desc": "Late Primordial Sovereign, and sixteen ranks of the Nine Heavens root awake.",
				"line": "Horse-Face counts Lin Feng, and counts him again, and gets a different number every time."},
		]},
	"thread_matron": {"might": [1.4, 1.1],
		"why": "The Thread Matron has hemmed every border between the hills and the sea, and her web is strung across the terraces. Nobody who has touched it has ever got loose.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A smoke of Dragon-Well tea", "needs": [["item", "tea_smoke", 1]], "boon": {"foe_atk": 0.8, "foe_hp": 0.85},
				"desc": "Two Dragon-Well Tea Buds roasted over water essence give a smoke that makes silk slip: her web will not hold you while it lasts.",
				"line": "The tea-smoke drifts across the terraces, and every strand of the web it touches goes slack and smells wonderful."},
			{"id": "respect", "kind": "respect", "n": "The tea-pickers cut the web", "needs": [["renown", 310]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The pickers of the Cloud-Tea Terraces will climb the web with their knives for somebody the whole land respects.",
				"line": "Up the terraces come the tea-pickers with their little curved knives, singing, and the web comes down strand by strand."},
			{"id": "wealth", "kind": "wealth", "n": "Buy her finished borders", "needs": [["stones", 80000]], "boon": {"foe_hp": 0.8},
				"desc": "Buy every border she has finished, at her own price, and burn them. She will have less to defend.",
				"line": "Lin Feng buys a cartload of borders and burns them on the terrace, and the Matron howls."},
			{"id": "might", "kind": "might", "n": "Strength the web cannot hold", "needs": [["lv", 35], ["ranks", 18]], "boon": {},
				"desc": "Late Samsara Transcendence, and eighteen ranks of the Nine Heavens root awake.",
				"line": "Lin Feng walks into the web, and it stretches round him, and stretches, and breaks."},
		]},
	"crow_marshal": {"might": [1.4, 1.1],
		"why": "The Crow Marshal holds the broken bridge with a hundred crows and an order nobody can countermand, because everybody who could give him another is gone.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "New orders, sealed in plumes", "needs": [["item", "marshal_orders", 1]], "boon": {"no_heavy": true, "foe_hp": 0.8},
				"desc": "Two Bridge Plumes from the magpies, bound with thunder and earth essence into a commander's seal: a soldier with no orders cannot refuse new ones.",
				"line": "Lin Feng hands the Marshal a set of orders sealed in magpie plumes, and half the crows on the rail break ranks to read them."},
			{"id": "respect", "kind": "respect", "n": "Old Que and the magpies", "needs": [["renown", 350]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Old Que of the magpies will bring the whole flock to the broken bridge for a cultivator the world respects.",
				"line": "The sky goes black and white with magpies, ten thousand of them, and the crows on the rail suddenly look very few."},
			{"id": "wealth", "kind": "wealth", "n": "Back pay for the crow-guards", "needs": [["stones", 100000]], "boon": {"foe_atk": 0.85, "foe_hp": 0.85},
				"desc": "The crow-guards have not been paid since the Court fell. Pay them, and see how many still guard the bridge.",
				"line": "Lin Feng pays the crow-guards two years' wages, and a good third of them fly off home."},
			{"id": "might", "kind": "might", "n": "Leave of your own", "needs": [["lv", 38], ["ranks", 20]], "boon": {},
				"desc": "Late Boundless Heart, and twenty ranks of the Nine Heavens root awake: leave enough to cross any bridge.",
				"line": "Lin Feng walks out onto the broken bridge with no leave but his own."},
		]},
	"bifang": {"might": [1.4, 1.1],
		"why": "Wherever Bifang's one foot comes down the millet bursts into flame, and the Scorched Plains are dry enough to burn to the sea.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A charm of the rain-stones", "needs": [["item", "rain_charm", 1]], "boon": {"no_heavy": true, "foe_hp": 0.8},
				"desc": "Two of the Rain-Stones the dust devil scattered, set in wood and earth essence: wherever you stand, the ground stays damp.",
				"line": "Lin Feng sets down the rain-charm, and a soft rain begins over the dyke road, and Bifang's next step only hisses."},
			{"id": "respect", "kind": "respect", "n": "The farmers of the plain", "needs": [["renown", 400]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Farmer Tian and the millet-growers will turn out with buckets and wet sacks for a cultivator the land respects.",
				"line": "Out of every village on the plain come the farmers with buckets and wet sacks, and the fires go out behind Lin Feng as fast as Bifang lights them."},
			{"id": "wealth", "kind": "wealth", "n": "Buy the whole harvest", "needs": [["stones", 140000]], "boon": {"foe_hp": 0.8},
				"desc": "Buy the plain's whole harvest and have it carted away first. An omen of fire with nothing left to burn is only a crane.",
				"line": "Carts of millet roll off the plain all morning, and Bifang finds less and less to announce."},
			{"id": "might", "kind": "might", "n": "Faster than the fire", "needs": [["lv", 41], ["temper", 8]], "boon": {},
				"desc": "Late Star River Crossing and a sword tempered eight times: catch the crane before the fire catches up.",
				"line": "Lin Feng runs the dyke road faster than the fire can follow."},
			{"id": "bond", "kind": "bond", "n": "Tala's cloud-horses", "needs": [["fate", "tala", ["well", "bought"]]], "boon": {"assist": 0.025, "taken": 0.85},
				"desc": "The horse-folk owe you a well. Tala's riders know how to run a fire-bird ragged: in circles, until it has no fire left to drop.",
				"line": "Tala's horse-folk come over the burnt millet at a gallop, whooping, and Bifang has forty riders to chase instead of one."},
		]},
	"gun": {"might": [1.4, 1.1],
		"why": "Gun stole the swelling earth from heaven to stop the flood, and he is still building his wall in the middle of it. Every clod he presses into place grows a mountain, and you have to get through them to reach him.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "Yu's plan of the channels", "needs": [["item", "yu_plan", 1]], "boon": {"no_heavy": true, "foe_hp": 0.8},
				"desc": "Two Clods of Swelling Earth and the water and Yin essence of the flood, worked into a plan of the channels his son dug: show Gun the other way.",
				"line": "Lin Feng unrolls the plan of the channels on the wall, and Gun stops pressing earth to read his son's handwriting."},
			{"id": "respect", "kind": "respect", "n": "The keepers of the dykes", "needs": [["renown", 450]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Bo Yi and the keepers of Yu's old dykes will dig through Gun's wall for a cultivator the land respects.",
				"line": "Bo Yi and the dyke-keepers come wading through the flood with shovels, and start cutting channels through the swelling wall."},
			{"id": "wealth", "kind": "wealth", "n": "Ten thousand diggers", "needs": [["stones", 180000]], "boon": {"foe_hp": 0.8, "foe_atk": 0.9},
				"desc": "Hire ten thousand diggers from Longmen and Tushan to cut the channels before Gun can raise his wall.",
				"line": "Ten thousand diggers cut through the swelling earth by nightfall, and the flood starts to go where it is told."},
			{"id": "might", "kind": "might", "n": "Through the wall", "needs": [["lv", 44], ["ranks", 22]], "boon": {},
				"desc": "Late Sun-Moon Harmony, and twenty-two ranks of the Nine Heavens root awake.",
				"line": "Lin Feng goes through Gun's wall the way water goes through sand."},
		]},
	"chong": {"might": [1.4, 1.1],
		"why": "Chong has held heaven up for four thousand years with his bare hands. He cannot hear, he cannot let go, and the weight of the sky is behind every blow he strikes.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "The Dao of the Sword", "needs": [["dao", "sword", 0]], "boon": {"weak_k": 1.9, "first": true},
				"desc": "A blade has one direction: forward. Walk the Sword (change at any Dao Stele) and Chong will see a cultivator who has never once put anything down.",
				"line": "Lin Feng raises his sword the way Chong raises his hands, and the giant sees him for the first time."},
			{"id": "peoples", "kind": "peoples", "n": "The celestial foxes", "needs": [["standing", "tianhu", 50]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "If the foxes of Changhe call you Friend, they will hold up a corner of heaven while Chong fights you. A jar of peach-blossom wine helps.",
				"line": "A hundred foxes leap onto the edge of heaven and push, and for a moment Chong's arms stop shaking."},
			{"id": "craft", "kind": "craft", "n": "A prop of the Gate's keys", "needs": [["item", "heaven_prop", 1]], "boon": {"foe_hp": 0.75, "no_heavy": true},
				"desc": "Two Keys of the Gate of Heaven forged into a prop with metal and earth essence: set it under heaven, and Chong can lower one hand.",
				"line": "Lin Feng sets the prop under the sky beside Chong, and the giant lowers one hand, very slowly, for the first time in four thousand years."},
			{"id": "might", "kind": "might", "n": "Strength to hold the sky", "needs": [["lv", 47], ["ranks", 23]], "boon": {},
				"desc": "Late Mountain-River Oneness, and twenty-three ranks of the Nine Heavens root awake.",
				"line": "Lin Feng puts his own hands flat against heaven beside Chong's, and pushes."},
		]},
	"tianwu": {"might": [1.45, 1.1],
		"why": "Tianwu has eight heads and every one of them gives orders to the others. A god who kept the stopper of the sea cannot be reasoned with eight ways at once.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A flask of pearl-tree dew", "needs": [["item", "dew_flask", 1]], "boon": {"foe_atk": 0.8, "foe_hp": 0.85},
				"desc": "Two Drops of Dew from the dying pearl trees, in a flask of wood essence: one sip calms a head. There are eight heads.",
				"line": "Lin Feng tosses the dew flask into the air, and four of Tianwu's heads lunge for it at once, and fall quiet."},
			{"id": "peoples", "kind": "peoples", "n": "The immortals of the isles", "needs": [["standing", "xian", 50]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "If the immortals of the isles call you Friend, He Xiangu and Zhang Guolao will come down from Fangzhang to argue with Tianwu's heads for you.",
				"line": "He Xiangu and Zhang Guolao walk out onto the cliff and start arguing with two of the heads each, and the heads argue back."},
			{"id": "wealth", "kind": "wealth", "n": "Eight tributes, one for each head", "needs": [["stones", 240000]], "boon": {"foe_hp": 0.8},
				"desc": "A god of eight heads expects eight tributes, and each head counts the others'. Pay all eight.",
				"line": "Eight tributes are laid on the cliff, and eight heads start counting, and only six of them are still angry."},
			{"id": "might", "kind": "might", "n": "One voice louder than eight", "needs": [["lv", 50], ["ranks", 24]], "boon": {},
				"desc": "Late Three Realms Concord, and twenty-four ranks of the Nine Heavens root awake.",
				"line": "Lin Feng tells Tianwu to be quiet, once, and all eight heads stop to look at him."},
			{"id": "bond", "kind": "bond", "n": "Liu Ying's antidote", "needs": [["fate", "liu_ying", ["physician", "alchemist"]]], "boon": {"assist": 0.02, "taken": 0.8},
				"desc": "The Hag's apprentice knows every poison on the isles and the answer to each. Tianwu's eight heads breathe venom; she has eight antidotes ready.",
				"line": "Liu Ying uncorks eight little bottles at once, and the venom from Tianwu's eight mouths turns to steam in the air."},
		]},
	"demon_lord": {"might": [1.5, 1.15],
		"why": "Xu Mo's palace drinks blood from the moon. Inside its walls the Demon Lord heals faster than a blade can cut, and his aura alone has broken three sects. Nobody has ever walked into the throne hall and walked out again.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A Thunder-Seal Talisman", "needs": [["item", "thunder_seal", 1]], "boon": {"weak_k": 1.9, "no_heavy": true},
				"desc": "Thunder breaks demons, and a talisman sealed with thunder breaks their palaces. Alchemist Mo knows the formula, if you bring the thunder and the shards to hold it.",
				"line": "Lin Feng slaps the Thunder-Seal on the throne-hall door. Lightning runs through the palace's veins, and for one battle it cannot feed its lord."},
			{"id": "respect", "kind": "respect", "n": "The sect stands behind you", "needs": [["renown", 45]], "boon": {"taken": 0.8, "assist": 0.02},
				"desc": "Elder Qing Xuan will raise the Azure Cloud Formation over the Blood Moon Palace, if the sect's elders agree the sweeper is worth it. Help enough people and they will.",
				"line": "On the ridge behind him the elders of Azure Cloud raise their swords, and the formation comes down over the palace like a lid of blue light."},
			{"id": "wealth", "kind": "wealth", "n": "The Demon-Binding Net", "needs": [["stones", 2400]], "boon": {"foe_hp": 0.75},
				"desc": "Smith Tie keeps a net of cold iron forged to hold a demon king. It was never sold, because nobody could ever pay for it.",
				"line": "The Demon-Binding Net goes over the throne like a shroud, and the Demon Lord rises from it a quarter weaker and very angry."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 11], ["temper", 4]], "boon": {},
				"desc": "Cultivation full to the brim at Late Nascent Soul and a sword tempered four times: enough, perhaps, to stand against him with nothing else.",
				"line": "Lin Feng walks into the throne hall alone, at the very peak of his strength, and the Demon Lord laughs. He will not laugh for long."},
		]},
	# ---- Part II
	"heavenly_emperor": {"might": [1.5, 1.15],
		"why": "The Jade Emperor of Ruin sits on a throne of stolen lightning, and every soldier of the Court who ever fell still marches in his honour guard. Strike at him and a thousand ghosts strike back.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A counter-sigil of the Gate", "needs": [["item", "unmaking_sigil", 1]], "boon": {"foe_hp": 0.75, "no_heavy": true},
				"desc": "Four Heaven Sigils unsealed the Gate. Two of them, beaten backwards on Smith Tie's anvil with metal essence, will unseal the Emperor's honour guard.",
				"line": "The counter-sigil flares, and the honour guard of dead soldiers lays down its spears, one rank after another, and goes home."},
			{"id": "respect", "kind": "respect", "n": "The Dragon King sends the tide", "needs": [["renown", 95]], "boon": {"assist": 0.025, "taken": 0.85},
				"desc": "The Azure Dragon King owes the boy who freed him. If the world knows that boy's name, the King will send the tide up the stairs of heaven.",
				"line": "Far below the Gate the sea draws in its breath, and the tide comes up the stairs of heaven with the Dragon King riding it."},
			{"id": "wealth", "kind": "wealth", "n": "Buy back the honour guard's pay-books", "needs": [["stones", 9000]], "boon": {"foe_hp": 0.75, "foe_atk": 0.9},
				"desc": "The Court never paid its dead soldiers. Pay them, every one, and see how many still march for the Emperor.",
				"line": "Lin Feng pays out nine thousand stones, a coin for every ghost, and three ranks of the honour guard take their wages and leave."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 17], ["temper", 6]], "boon": {},
				"desc": "Cultivation full at Late Void Refinement and a sword tempered six times.",
				"line": "Lin Feng climbs the last stair alone, and the throne of lightning turns to look at him."},
		]},
	# ---- Part III
	"hollow_heaven": {"might": [1.5, 1.15],
		"why": "The Hollow Heaven is not a beast but a hunger: the space the Court carved out of the sky to keep its harvest in. It swallows techniques whole, and it has never once been full.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A Rune-Lantern of the Origin", "needs": [["item", "rune_lantern", 1]], "boon": {"foe_hp": 0.7, "weak_k": 1.9},
				"desc": "Two Origin Runes in a lantern of Yin essence give a light the Hollow cannot swallow, and in that light you can see where it is thin.",
				"line": "The Rune-Lantern opens in Lin Feng's hand, and in its light the Hollow Heaven has edges, and seams, and one place where it is thinner than paper."},
			{"id": "respect", "kind": "respect", "n": "The Keepers hold the sky shut", "needs": [["renown", 140]], "boon": {"taken": 0.8, "assist": 0.02},
				"desc": "The Keeper of the Mirror Lake, the Gravekeeper and the Ferryman of Years will hold the sky shut behind you, for somebody the world respects.",
				"line": "Behind Lin Feng three old keepers take hold of the edges of the sky, and the Hollow cannot pull it any wider."},
			{"id": "wealth", "kind": "wealth", "n": "An hour bought from the Ferryman", "needs": [["stones", 22000]], "boon": {"foe_hp": 0.8, "first": true},
				"desc": "The Ferryman of the River of Years will sell you an hour that never happened, for a price. Use it to strike first.",
				"line": "The Ferryman counts the stones twice and hands Lin Feng an hour. He spends the first of it before the Hollow knows he is there."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 23], ["temper", 8]], "boon": {},
				"desc": "Cultivation full at Late Mahayana and a sword tempered eight times, as far as Smith Tie's forge can take it.",
				"line": "Lin Feng steps into the Hollow with nothing but his own strength, which is the one thing it has never been able to swallow."},
		]},
	# ---- Part IV
	"jade_ledger": {"might": [1.5, 1.15],
		"why": "The Jade Ledger writes the name of everyone who strikes it into its pages. Strike it often enough and you belong to it, like everybody else in it.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "Ink of the Unwritten", "needs": [["item", "forget_ink", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Immortal Peach steeped in water essence makes an ink that unwrites whatever it touches. Every page it spills on comes up blank.",
				"line": "Lin Feng throws the ink, and the first hundred pages of the Ledger go blank, names and debts and all, with a sound like a sigh."},
			{"id": "respect", "kind": "respect", "n": "The nineteen bearers speak for you", "needs": [["renown", 190]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The Nineteen you freed from their names will stand beside a cultivator whose own name the world speaks with respect.",
				"line": "Nineteen bearers of the root step out of the Peach Garden and stand at Lin Feng's back, and each of them has a score to settle."},
			{"id": "wealth", "kind": "wealth", "n": "Pay off the Ledger's debts", "needs": [["stones", 45000]], "boon": {"foe_hp": 0.75, "foe_atk": 0.85},
				"desc": "Half the names in the Ledger are there for debts. Pay them, and the Ledger has half as much to hold.",
				"line": "Forty-five thousand spirit stones pour across the Ledger's pages, and debt after debt is struck out in the Court's own red."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 26], ["ranks", 14]], "boon": {},
				"desc": "Cultivation full at Late True Immortal, and fourteen ranks of the Nine Heavens root awake.",
				"line": "Lin Feng opens the Ledger at his own page, crosses his name out, and steps into the fight."},
		]},
	# ---- Part V
	"hundun": {"might": [1.5, 1.15],
		"why": "Hundun has no face, so it has no weakness you can see; it has no ears, so it cannot hear a plea; and it is the oldest thing in the world.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A Five-Coloured Lens", "needs": [["item", "five_lens", 1]], "boon": {"weak_k": 1.9, "foe_hp": 0.8},
				"desc": "Two of Nuwa's stones ground into a lens on Smith Tie's wheel, bound in Yin essence: look through it, and even a thing without a face has a weakness.",
				"line": "Through the Five-Coloured Lens Hundun is all colours at once, and one of them flinches when the light touches it."},
			{"id": "respect", "kind": "respect", "n": "The four wardens answer", "needs": [["renown", 235]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Bai Hu, Zhu Que, Xuan Wu and the Dragon King hold the corners of the sky. They will lend a claw to a cultivator the whole world respects.",
				"line": "At the four corners of the world the wardens roar, and the chaos is pinned between them like a sheet between four hands."},
			{"id": "wealth", "kind": "wealth", "n": "Nuwa's last stones", "needs": [["stones", 70000]], "boon": {"foe_hp": 0.75},
				"desc": "The desert nomads keep the last five-coloured stones Nuwa did not use. They sell them only for a fortune, and only to someone who means to use them.",
				"line": "Lin Feng sets Nuwa's last stones in a ring round the chaos, and a quarter of it is mended into sky before it can move."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 29], ["ranks", 16]], "boon": {},
				"desc": "Cultivation full at Late Dao Ancestor, and sixteen ranks of the Nine Heavens root awake.",
				"line": "Lin Feng walks into the formless sea with his eyes open, because the oldest thing in the world has never met anyone who did."},
		]},
	# ---- Part VI
	"king_yama": {"might": [1.5, 1.15],
		"why": "King Yama judges every soul that comes to the Wheel, and he has judged Lin Feng already. His page in the Book of Life and Death lies open on the desk, and the brush is wet.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A paper lotus of mercy", "needs": [["item", "mercy_lotus", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Folded from Spokes of the Wheel and burned with fire and Yin, a paper lotus carries a plea for mercy where no living voice can go.",
				"line": "The paper lotus burns on the steps of the Hall of Judgement, and for a moment even King Yama's brush is still."},
			{"id": "respect", "kind": "respect", "n": "The Thousand Unforgotten testify", "needs": [["renown", 285]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The souls you remembered at the Yellow Springs will speak for you at the Wheel, if your name is worth speaking for.",
				"line": "A thousand voices rise from the Naihe Bridge, each of them saying Lin Feng's name, and the Judge has to listen to every one."},
			{"id": "wealth", "kind": "wealth", "n": "A thousand souls' ferry-fare", "needs": [["stones", 100000]], "boon": {"foe_atk": 0.8, "foe_hp": 0.8},
				"desc": "Pay the ferry-fare of a thousand souls who could not afford it, and see how kindly the Wheel turns for you.",
				"line": "A hundred thousand stones go into the ferryman's box, and a thousand grateful souls cross over singing. Yama scowls at the noise."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 32], ["ranks", 18]], "boon": {},
				"desc": "Cultivation full at Late Primordial Sovereign, and eighteen ranks of the Nine Heavens root awake.",
				"line": "Lin Feng takes the wet brush out of King Yama's hand and puts it down on the desk, very gently."},
			{"id": "bond", "kind": "bond", "n": "Qiu Ye at your side", "needs": [["fate", "qiu_ye", ["brother", "turning"]]], "boon": {"assist": 0.025, "taken": 0.85},
				"desc": "Qiu Ye walked his father to the Naihe Bridge. He knows the Wheel's courts from the queue, and he has nothing left to fear from them.",
				"line": "Qiu Ye walks into King Yama's court beside Lin Feng with his grandfather's sword drawn, and does not bow."},
		]},
	# ---- Part VII
	"qianxian": {"might": [1.55, 1.15],
		"why": "Qianxian, the Thousand-Thread, has sewn herself into every roof in Qingshi. Cut her and the village bleeds; leave her and she sews the rest of the world.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "Silver scissors of the Loom", "needs": [["item", "loom_scissors", 1]], "boon": {"foe_hp": 0.7, "weak_k": 1.9},
				"desc": "Two Shuttles of the Loom forged into scissors with earth and thunder essence cut a thread without cutting what it is sewn to.",
				"line": "The silver scissors snip, and a hundred threads fall away from Qingshi's roofs without so much as a torn tile."},
			{"id": "respect", "kind": "respect", "n": "All of Qingshi pulls the threads", "needs": [["renown", 330]], "boon": {"assist": 0.035, "taken": 0.85},
				"desc": "Granny Wen's village will pull out the threads with its own hands, if the orphan it raised has become someone the world respects.",
				"line": "The whole of Qingshi climbs onto its roofs and starts pulling threads, Granny Wen shouting orders from the well."},
			{"id": "wealth", "kind": "wealth", "n": "Every bolt of her silk", "needs": [["stones", 140000]], "boon": {"foe_hp": 0.75, "foe_atk": 0.85},
				"desc": "Buy every bolt of silk she has woven, at her price. A weaver whose work is sold has less reason to keep weaving.",
				"line": "Lin Feng buys every bolt. Qianxian counts the stones, and a quarter of her threads go slack while she does."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 35], ["ranks", 20]], "boon": {},
				"desc": "Cultivation full at Late Samsara Transcendence, and twenty ranks of the Nine Heavens root awake.",
				"line": "Lin Feng climbs the threads hand over hand to the top of the Loom, and Qianxian stops weaving to watch him come."},
			{"id": "bond", "kind": "bond", "n": "Fang Hu and the village watch", "needs": [["fate", "hu", ["watchman", "guardian", "disciple"]]], "boon": {"assist": 0.025, "taken": 0.85},
				"desc": "Iron Fang's son grew up in the village the Weaver stitched shut. He knows every thread of hers that runs through Qingshi, and where to cut.",
				"line": "Fang Hu comes up the Loom's stair with the village watch behind him, cutting threads with his father's iron hand."},
		]},
	# ---- Part VIII
	"xiwangmu": {"might": [1.55, 1.15],
		"why": "The Queen Mother of the West keeps the peaches of immortality and the plague-stars of heaven, and she does not hold audiences with sweepers.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A peach-pit talisman", "needs": [["item", "peach_talisman", 1]], "boon": {"no_heavy": true, "foe_hp": 0.75},
				"desc": "Peach wood wards off every plague-star, and the pit of a Kunlun peach steeped in wood essence wards off the Queen Mother herself, a little.",
				"line": "The peach-pit talisman glows at Lin Feng's throat, and the plague-stars wheel away from it like startled birds."},
			{"id": "respect", "kind": "respect", "n": "The Cowherd and the Weaver ask for you", "needs": [["renown", 370]], "boon": {"taken": 0.8, "assist": 0.025},
				"desc": "Niu Lang and Zhi Nu will ask the Queen Mother to hear a cultivator whose name is spoken with respect from the ferry to the stars.",
				"line": "The Cowherd and the Weaver walk into the Jasper Pool hand in hand, and the Queen Mother cannot quite look at them."},
			{"id": "wealth", "kind": "wealth", "n": "A tribute fit for Kunlun", "needs": [["stones", 190000]], "boon": {"foe_hp": 0.75, "foe_atk": 0.85},
				"desc": "The Queen Mother has refused every tribute for three thousand years. She has never been offered one this large.",
				"line": "The tribute is laid at the edge of the Jasper Pool. The Queen Mother sniffs at it, and does not entirely refuse."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 38], ["ranks", 22]], "boon": {},
				"desc": "Cultivation full at Late Boundless Heart, and twenty-two ranks of the Nine Heavens root awake.",
				"line": "Lin Feng walks into the audience hall without an audience, and sits down where the petitioners kneel."},
		]},
	# ---- Part IX
	"xihe": {"might": [1.55, 1.2],
		"why": "Xihe, Mother of Suns, drives the chariot of the last sun. She lost nine children to an archer, and she will not lose the tenth to anyone, least of all a stranger with a sword.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "An osmanthus moon-mirror", "needs": [["item", "moon_mirror", 1]], "boon": {"foe_atk": 0.8, "no_heavy": true},
				"desc": "Moon-osmanthus pressed into silver with water and thunder essence makes a mirror that shows a sun her own face, cooled.",
				"line": "Lin Feng raises the moon-mirror, and Xihe sees herself in it, pale and tired, and her fire falters."},
			{"id": "respect", "kind": "respect", "n": "Chang'e and the Dawn Market vouch for you", "needs": [["renown", 420]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Chang'e of the Moon Palace and the whole of the Dawn Market will vouch for a cultivator the world respects.",
				"line": "Chang'e comes down a moonbeam, and the lantern-makers of Yanggu light every lantern they own at once."},
			{"id": "wealth", "kind": "wealth", "n": "Lamp-oil for a sun", "needs": [["stones", 250000]], "boon": {"foe_hp": 0.75, "foe_atk": 0.9},
				"desc": "Even a sun's chariot runs on something. Buy every spirit lamp between Yanggu and the sea and pour them on her road.",
				"line": "A quarter of a million stones' worth of spirit lamps burn on the road to Guanghan, and Xihe's chariot slows to look."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 41], ["ranks", 23]], "boon": {},
				"desc": "Cultivation full at Late Star River Crossing, and twenty-three ranks of the Nine Heavens root awake: every tribulation survived and every Founder's cave opened.",
				"line": "Lin Feng stands in the road of the sun, and does not move out of it."},
		]},
	# ---- Part X
	"gonggong": {"might": [1.6, 1.2],
		"why": "Gonggong broke the pillar of the sky with his head once. He has been looking for something else to break ever since, and here you are.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A charm of swelling earth", "needs": [["item", "dyke_charm", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Two Stones of Mount Buzhou set in a charm of water and earth essence raise a dyke wherever they are thrown, even across a flood god.",
				"line": "Lin Feng throws the charm, and a dyke of living earth rises across the black lake between him and the flood."},
			{"id": "respect", "kind": "respect", "n": "Every river you calmed rises with you", "needs": [["renown", 480]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "He Bo, the Carp of the Dragon Gate and every river spirit between Longmen and the sea will rise for a cultivator the world respects.",
				"line": "Up the river road come He Bo and the carp and the river spirits of the north, and the flood god finds himself surrounded by water that is not his."},
			{"id": "wealth", "kind": "wealth", "n": "Ten thousand carts of stone", "needs": [["stones", 330000]], "boon": {"foe_hp": 0.75, "foe_atk": 0.85},
				"desc": "Buy ten thousand carts of stone from Tushan's quarries and pile them round the broken pillar, so there is nothing left for Gonggong to break.",
				"line": "Ten thousand carts of Tushan stone stand round the pillar, and Gonggong charges them, and the pillar holds."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 44], ["ranks", 24]], "boon": {},
				"desc": "Cultivation full at Late Sun-Moon Harmony, and twenty-four ranks of the Nine Heavens root awake: every tribulation survived and every Founder's cave opened.",
				"line": "Lin Feng stands between Gonggong and the pillar, which is the only thing left in the world that is harder than his head."},
		]},
	# ---- Part XI: the Daos and the peoples count now
	"li": {"might": [1.6, 1.2],
		"why": "Li has pressed the earth down for four thousand years with an iron weight. He will not lift it for a stranger, he will not lift it for a sword, and nothing in the Nine Springs can make him.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "The Dao of Formations", "needs": [["dao", "formation", 0]], "boon": {"weak_k": 1.9, "taken": 0.8},
				"desc": "The land keeps its shape because it is allowed to. Walk the road of Formations (change at any Dao Stele) and Li will see a cultivator who understands what he has been holding.",
				"line": "Lin Feng lays out the eight trigrams on the floor of the inner gate, and Li looks down at them for a long time."},
			{"id": "peoples", "kind": "peoples", "n": "The shades of Youdu stand with you", "needs": [["standing", "shade", 50]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "If the shades of the Dark Capital call you Friend, they will stand at your back at the inner gate. A gift of ancestor incense goes a long way with them.",
				"line": "Every lantern in Youdu comes down the street behind Lin Feng, carried by a shade who calls him friend."},
			{"id": "craft", "kind": "craft", "n": "A root-lantern of the Dark Capital", "needs": [["item", "root_lantern", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Soul-Tallies burned in a lantern of fire and Yin essence light the roots of the Jianmu, and the earth Li presses down remembers it can rise.",
				"line": "The root-lantern lights the underside of the world, and the earth under Li's weight stirs like a sleeper."},
			{"id": "might", "kind": "might", "n": "At the peak of your strength", "needs": [["peak", 47], ["dao", "", 2]], "boon": {},
				"desc": "Cultivation full at Late Mountain-River Oneness, and Master of the Dao you walk.",
				"line": "Lin Feng puts his shoulder under the iron weight beside Li's, and lifts."},
			{"id": "bond", "kind": "bond", "n": "Xu Lan's lantern", "needs": [["fate", "xu_lan", ["forgiving", "just"]]], "boon": {"assist": 0.025, "taken": 0.85},
				"desc": "Xu Lan settled her father's shade in Youdu herself. The Dark Capital's lanterns answer to the one who carried his.",
				"line": "Xu Lan lifts her father's empty soul-lantern, and every lantern in the Dark Capital turns its light on Li."},
		]},
	# ---- Part XII
	"xu_fu": {"might": [1.6, 1.2],
		"why": "Xu Fu cannot be stopped: that is his curse. The immortals have tried, and the sea, and his own ship. Two thousand years of being unstoppable have made him very hard to hurt.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "The Compassionate Heart", "needs": [["dao", "heart", 1]], "boon": {"taken": 0.8, "foe_atk": 0.85},
				"desc": "Only a heart that knows how to ask for help can ask him what he would like. Walk the Compassionate Heart as an Adept or better.",
				"line": "Lin Feng does not draw his sword first. He asks Xu Fu what he would like, and it is the first time in two thousand years anyone has."},
			{"id": "peoples", "kind": "peoples", "n": "Kin of the Thousand Children", "needs": [["standing", "qianzi", 100]], "boon": {"assist": 0.035, "taken": 0.85},
				"desc": "If Landfall calls you Kin, its fishermen will row out to the lip of the Ruins behind you. A handful of mainland earth is the gift they long for.",
				"line": "Out of the dark come the boats of Landfall, every one of them rowing for the lip, shouting the names of the Thousand."},
			{"id": "craft", "kind": "craft", "n": "A compass of the Lost Fleet", "needs": [["item", "fleet_compass", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Two pages of Xu Fu's own log, bound into a compass with Yin and earth essence, point the way home, and he cannot look away from it.",
				"line": "The compass needle swings round and points west, home, and Xu Fu cannot take his eyes off it."},
			{"id": "wealth", "kind": "wealth", "n": "Buy back the Lost Fleet", "needs": [["stones", 420000]], "boon": {"foe_hp": 0.75},
				"desc": "The sixty ships of the Lost Fleet lie on the sea floor, still owned by the Court's creditors. Buy them back for the Thousand Children.",
				"line": "Lin Feng buys back sixty wrecks, and Xu Fu, who has never once been bought anything, does not know where to look."},
		]},
	# ---- Part XIII: the Eight Gates of the Qimen formation round Chiyou
	"xingtian": {"might": [1.3, 1.1],
		"why": "Xingtian lost his head to the Yellow Emperor's sword and kept fighting, with eyes in his chest and a mouth in his belly. He has held the Gate of Opening since, and he has never once been tired.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "The Dao of the Sword", "needs": [["dao", "sword", 1]], "boon": {"weak_k": 1.9, "first": true},
				"desc": "Xingtian respects nothing but a blade. Walk the Sword as an Adept or better.",
				"line": "Lin Feng salutes with his sword, and the headless giant salutes back with his axe."},
			{"id": "peoples", "kind": "peoples", "n": "Kin of the celestial foxes", "needs": [["standing", "tianhu", 100]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The foxes know a door in every gate. If they call you Kin, they will show you the one in this.",
				"line": "Hu Xiao opens a door in the Gate of Opening that was not there a moment ago, and a dozen foxes pour through it after Lin Feng."},
			{"id": "wealth", "kind": "wealth", "n": "Pixiu's gold, given back", "needs": [["stones", 150000]], "boon": {"foe_hp": 0.75},
				"desc": "The gold Pixiu swallowed belonged to the Gate. Give back its worth in spirit stones and the Gate remembers whose side it is on.",
				"line": "The stones ring on the threshold, and the Gate of Opening opens a crack of its own accord."},
		]},
	"yu_shi": {"might": [1.3, 1.1],
		"why": "Yu Shi, the Rain Master, drowned the Yellow Emperor's army at Zhuolu for Chiyou. He keeps the Gate of Alarm in a rain so heavy that the drops are louder than thunder.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "Free Wandering", "needs": [["dao", "wander", 1]], "boon": {"foe_atk": 0.8, "first": true},
				"desc": "The rain cannot fall on what will not stay still. Walk Free Wandering as an Adept or better.",
				"line": "Lin Feng walks between the raindrops, and the Rain Master cannot find him to drown him."},
			{"id": "peoples", "kind": "peoples", "n": "Kin of the Feathered Folk", "needs": [["standing", "yumin", 100]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The Yumin fly above every rain. If they call you Kin, they will carry the storm's clouds away on their wings.",
				"line": "A flight of Yumin comes down out of the sun and beats the rain clouds apart with their wings."},
			{"id": "craft", "kind": "craft", "n": "The fan of Nuba's drought", "needs": [["item", "drought_fan", 1]], "boon": {"no_heavy": true, "foe_hp": 0.75},
				"desc": "Nuba dried the Rain Master's storm at Zhuolu. A fan of Noon Embers and fire essence holds a little of her drought.",
				"line": "One sweep of the drought-fan, and the rain at the Gate of Alarm turns to steam."},
		]},
	"liang": {"might": [1.3, 1.1],
		"why": "Liang, a goblin of the black water, was set at the Gate of Rest to lull anyone who comes to sleep, and then to drown them in their dreams.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "The Compassionate Heart", "needs": [["dao", "heart", 1]], "boon": {"taken": 0.8, "foe_atk": 0.85},
				"desc": "A heart awake to others does not sleep when it is told to. Walk the Compassionate Heart as an Adept or better.",
				"line": "Liang sings his lullaby, and Lin Feng hums along, because he is thinking of Granny Wen, and he does not fall asleep."},
			{"id": "peoples", "kind": "peoples", "n": "Kin of the Pearl-Weepers", "needs": [["standing", "jiaoren", 100]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The Jiaoren sing louder than any goblin. If they call you Kin, they will sing you awake.",
				"line": "The Pearl-Weepers of Tearwater sing from the shore, and the goblin's lullaby drowns in their song."},
			{"id": "relic", "kind": "relic", "n": "Pour the springs back", "needs": [["give", "spring_water", 2]], "boon": {"foe_hp": 0.8, "foe_atk": 0.85},
				"desc": "Two Vials of the Nine Springs, the water the Jianmu drinks, poured into the goblin's pool: he cannot drown anyone in water that wants to rise.",
				"line": "Lin Feng pours the springs' own water into Liang's pool, and it rises, bright and cold, and wakes everything it touches."},
		]},
	"bronze_brothers": {"might": [1.3, 1.1],
		"why": "Eighty-one brothers had Chiyou, with bronze heads and iron brows, who ate sand and stones. The last of them hold the Gate of Death shoulder to shoulder, and they have never once retreated.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "The Dao of Formations", "needs": [["dao", "formation", 1]], "boon": {"weak_k": 1.9, "taken": 0.8},
				"desc": "A formation of eighty-one is still a formation. Walk Formations as an Adept or better and you will see the gap in their line.",
				"line": "Lin Feng counts the brothers, and the gaps between them, and steps into the one that is the Gate of Death's own life."},
			{"id": "peoples", "kind": "peoples", "n": "Kin of the shades", "needs": [["standing", "shade", 100]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The shades of Youdu know every way through death. If they call you Kin, they will lead you through this gate as well.",
				"line": "The lantern-shades of Youdu walk through the bronze line as if it were fog, and the brothers do not know what to strike."},
			{"id": "respect", "kind": "respect", "n": "A name even the dead respect", "needs": [["renown", 560]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The brothers fought for a war god who was loved by his people. They will stand aside, a little, for somebody the whole world respects.",
				"line": "The nearest brother looks at Lin Feng for a long moment, and then, slowly, half the line steps back."},
		]},
	"red_banner": {"might": [1.3, 1.1],
		"why": "Every autumn a red vapour rose from Chiyou's tomb, and the people called it Chiyou's Banner. Now it has come down out of the sky to burn at the Gate of Sight, and it shows everyone who looks at it the war they fear most.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "The Mirror", "needs": [["dao", "illusion", 1]], "boon": {"foe_atk": 0.8, "weak_k": 1.9},
				"desc": "The moon in the water is still the moon. Walk the Mirror as an Adept or better and the Banner's visions are only reflections.",
				"line": "The Banner shows Lin Feng the war he fears, and he looks at it the way he would look at the moon in a pond."},
			{"id": "craft", "kind": "craft", "n": "A mirror of clear sight", "needs": [["item", "clear_mirror", 1]], "boon": {"foe_hp": 0.75, "no_heavy": true},
				"desc": "Jingwei's stones polished on Smith Tie's wheel with metal essence make a mirror that shows only what is really there.",
				"line": "In the clear mirror the Banner is only a red mist, burning, and very much afraid of going out."},
			{"id": "might", "kind": "might", "n": "Strength enough to look", "needs": [["lv", 52]], "boon": {},
				"desc": "Middle Ten Thousand Waters Return: enough strength to look at the worst war in the world and not flinch.",
				"line": "Lin Feng looks straight into the Banner and does not look away."},
		]},
	"mast_goblin": {"might": [1.3, 1.1],
		"why": "Mei, the goblin of old wood, has lived two thousand years in the mainmast of the Penglai-Seeker, and the formation has made it keeper of the Gate of Closing. It will close on anyone it does not like, and it likes nobody.",
		"paths": [
			{"id": "wealth", "kind": "wealth", "n": "Two thousand years of wages", "needs": [["stones", 160000]], "boon": {"foe_hp": 0.75},
				"desc": "Nobody ever paid the Lost Fleet. Pay the old mast the wages of every sailor who leaned on it, and it may open a little.",
				"line": "Lin Feng pays the mast every sailor's wages, and somewhere in the old wood something that has been clenched for two thousand years lets go."},
			{"id": "relic", "kind": "relic", "n": "The conch of the shifts", "needs": [["item", "shift_horn", 1], ["give", "mainland_earth", 1]], "boon": {"foe_atk": 0.8, "foe_hp": 0.85},
				"desc": "Blow Yu Qiang's conch, and give the goblin a handful of mainland earth: the mast was a tree in Qin once, and it has not smelled home in two thousand years.",
				"line": "The conch sounds the change of the shifts, and the mast smells the mainland earth, and remembers being a tree."},
			{"id": "peoples", "kind": "peoples", "n": "Kin of the Thousand Children", "needs": [["standing", "qianzi", 100]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The Thousand Children are the grandchildren of the Lost Fleet's sailors. If they call you Kin, the old mast will know them.",
				"line": "The fishermen of Landfall come down to the wreck, and the mast hears its sailors' names in their mouths."},
		]},
	"fetter_maple": {"might": [1.3, 1.1],
		"why": "When Chiyou died his fetters were thrown down in the gorge, and grew into the first maples, red as the blood on them. The oldest of them has woken as the keeper of the Gate of Life, and it will not let anyone through to its master.",
		"paths": [
			{"id": "dao", "kind": "dao", "n": "The Cauldron", "needs": [["dao", "alchemy", 1]], "boon": {"foe_hp": 0.8, "taken": 0.85},
				"desc": "Every pill is borrowed time, and every fetter is a promise kept too long. Walk the Cauldron as an Adept or better.",
				"line": "Lin Feng speaks to the fetter-maple as an alchemist speaks to an old root, and it listens, warily."},
			{"id": "peoples", "kind": "peoples", "n": "Kin of the Deathless", "needs": [["standing", "deathless", 100]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The Deathless love anything that ends. If they call you Kin, they will come up the roots and talk the old tree into letting go.",
				"line": "Up through the gorge come the Deathless, singing to the old maple about autumn, and how good it is to let things fall."},
			{"id": "relic", "kind": "relic", "n": "Autumn for the fetters", "needs": [["give", "autumn_leaf", 2]], "boon": {"foe_hp": 0.8, "foe_atk": 0.85},
				"desc": "Two pressed autumn leaves, laid at its roots: a maple that has forgotten how to let its leaves fall can be reminded.",
				"line": "Lin Feng lays the two red leaves at the maple's roots, and for the first time in five thousand years a leaf comes loose from it."},
		]},
	"kui_drum": {"might": [1.3, 1.1],
		"why": "The Yellow Emperor made a drum from the hide of Kui, the one-legged thunder ox, and its beat was heard five hundred li away and broke Chiyou's army. The formation has woken it at the Gate of Harm, and it beats by itself now.",
		"paths": [
			{"id": "might", "kind": "might", "n": "Strength to stand the beat", "needs": [["lv", 52], ["temper", 8]], "boon": {},
				"desc": "Middle Ten Thousand Waters Return and a sword tempered eight times: enough to stand in front of the drum while it beats.",
				"line": "Lin Feng plants his feet in front of the drum and lets it beat at him until it is tired."},
			{"id": "craft", "kind": "craft", "n": "A drumstick of the thunder-beast", "needs": [["item", "kui_drumstick", 1]], "boon": {"no_heavy": true, "foe_hp": 0.75},
				"desc": "Two Storm-Torn Wind Bells forged into a drumstick with earth essence: whoever holds it decides when the drum is struck.",
				"line": "Lin Feng raises the drumstick, and the drum, for the first time in five thousand years, waits to be struck."},
			{"id": "respect", "kind": "respect", "n": "A name the drum will carry", "needs": [["renown", 580]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "The drum was made to carry a name across a battlefield. Bring a name the whole world already knows, and it will beat for you.",
				"line": "The drum beats Lin Feng's name across the land, and from every town on the road somebody answers."},
		]},
	# ---- Part XIV: the reckoning at the heart of the Wheel
	"nie": {"might": [2.2, 1.25],
		"why": "Nie is not a creature but a reckoning: every grudge of every foe Lin Feng put down on the road, every promise half-kept, every thread he cut instead of tying. It is as strong as the road was long, and the road was very long.",
		"paths": [
			{"id": "bond", "kind": "bond", "n": "By the bonds you made", "needs": [["bonds", 3]], "boon": {"assist": 0.035, "taken": 0.8},
				"desc": "At least three of the five whose lives you changed stand with you. Nie is made of debts; it does not know what to do with a debt that was paid in friendship.",
				"line": "They come down the funeral road behind him, the ones he kept faith with, and Nie's many hands do not know which of them to reach for first."},
			{"id": "might", "kind": "might", "n": "Pay it all yourself", "needs": [["peak", 56], ["temper", 8]], "boon": {},
				"desc": "Cultivation full at Late Myriad Daos as One and a sword tempered eight times: strength enough to stand in front of every debt of the journey at once and pay it.",
				"line": "Lin Feng walks into the heart of the Wheel alone and holds out his hands, the way a debtor does who means to pay."},
			{"id": "respect", "kind": "respect", "n": "A name the dead respect", "needs": [["renown", 760]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Half of Nie's grudges belong to the dead, and the dead have heard of you. A name the whole world respects makes even a grudge hesitate.",
				"line": "Lin Feng gives his name at the heart of the Wheel, and half of the voices in Nie fall quiet to listen."},
			{"id": "craft", "kind": "craft", "n": "A mirror of settled debts", "needs": [["item", "settled_mirror", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Smith Tie can forge a mirror from two spokes of the Wheel with dark and metal essence: a debt that sees itself in it remembers whether it was ever owed at all.",
				"line": "Lin Feng holds up the mirror of settled debts, and a great many of Nie's tallies look into it and quietly burn."},
		]},
	# ---- Part XV (the Lotus release): what came for Yue Ling
	"unweaver": {"might": [2.0, 1.2],
		"why": "The Unweaver is the hand that wove every road on the Loom of Borders, turned round to wind thread back onto the spindle. Every stitch it takes is a stitch of Yue Ling, and it is in no hurry.",
		"paths": [
			{"id": "heart", "kind": "heart", "n": "Hand in hand", "needs": [["heart", 2]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Lin Feng and Yue Ling have become dear friends at least. The Unweaver winds back what is loose; what two people hold between them is not loose at all.",
				"line": "Yue Ling takes his hand before the spindle, and the threads the Unweaver pulls at do not come."},
			{"id": "craft", "kind": "craft", "n": "A shuttle of pressed petals", "needs": [["item", "lotus_shuttle", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Alchemist Mo can make a weaver's shuttle of three pressed petals and wood and water essence. Thrown through the Unweaver's hands, it weaves back whatever they unpick.",
				"line": "Lin Feng throws the shuttle of pressed petals through the Unweaver's hundred hands, and they tangle in pink thread."},
			{"id": "bond", "kind": "bond", "n": "Her friends' threads", "needs": [["bonds", 3]], "boon": {"assist": 0.035},
				"desc": "Three of the five people you met on the road stand with you. They have tied threads of their own on her wrists, and the Unweaver cannot find the end of any of them.",
				"line": "The friends' threads on Yue Ling's wrists, green and grey and red and silver, tie the Unweaver's hands in knots."},
			{"id": "might", "kind": "might", "n": "Cut every thread it holds", "needs": [["lv", 59], ["temper", 8]], "boon": {},
				"desc": "Late Kindred cultivation within reach and a sword tempered eight times: fast enough to cut every thread the Unweaver holds before it can wind it.",
				"line": "Lin Feng goes in under the hundred hands, and the sword is quicker than the spindle."},
		]},
	# ---- Part XVI (the Living Land release): the Last Night and the Year Beast
	"xi_beast": {"might": [2.1, 1.25],
		"why": "Xi is the last night of the year, and it has eaten the hours with the light: until the year is driven out the night will not end, and every lamp it swallows makes it longer.",
		"paths": [
			{"id": "relic", "kind": "relic", "n": "Charms of peach wood", "needs": [["give", "peach_charm", 1]], "boon": {"foe_hp": 0.75, "taken": 0.85},
				"desc": "The door gods under the great peach tree gave you two boards of peach wood carved with their names. Everything that comes out of the dark hates peach wood, and Xi is nothing but dark.",
				"line": "Lin Feng nails the peach-wood board to the lantern pole, and Xi recoils from the names on it as from a flame."},
			{"id": "folk", "kind": "folk", "n": "Every gong in the market", "needs": [["rallied", 3]], "boon": {"assist": 0.035},
				"desc": "Three towns remember the old ways, and the word has run down the roads ahead of you: the Dawn Market's stallholders come out with gongs and pans and strike every time Xi does.",
				"line": "Watchman Zhou's gong starts it, and then every pan in Yanggu: Xi cannot hear itself think."},
			{"id": "craft", "kind": "craft", "n": "Thunder-bamboo crackers", "needs": [["item", "thunder_cracker", 1]], "boon": {"foe_hp": 0.7, "weak_k": 1.9},
				"desc": "Alchemist Mo can pack two stalks of thunder bamboo with fire essence into a string of crackers loud enough to drive off a night. The first firecrackers were bamboo thrown on a fire; these are the loudest ever made.",
				"line": "The string of thunder-bamboo crackers goes off at Xi's feet, a hundred bangs in a row, and the Last Night flinches from every one."},
			{"id": "might", "kind": "might", "n": "Cut the night in two", "needs": [["lv", 61], ["temper", 8]], "boon": {},
				"desc": "Middle Kindred Dao and a sword tempered eight times: fast enough to cut a coil of night before it can close round you.",
				"line": "Lin Feng's sword goes through the dark like a lamp through a curtain."},
		]},
	"nian": {"might": [2.3, 1.3],
		"why": "Nian is the year: every fear of the longest year the world has ever had, eaten in its sleep. It has never been this big or this hungry, and it is very hard to frighten something made of fear.",
		"paths": [
			{"id": "folk", "kind": "folk", "n": "Every pot in the land", "needs": [["rallied", 4]], "boon": {"assist": 0.045, "taken": 0.85},
				"desc": "Four towns remember the old ways, and the word has gone down every road. All Qingshi is out in the lane with woks, ladles and a temple bell, and the noise of it goes into Nian like a sword.",
				"line": "Granny Wen raises her ladle, and two hundred pots answer her: the Year Beast staggers in the noise."},
			{"id": "heart", "kind": "heart", "n": "Not alone", "needs": [["heart", 3]], "boon": {"assist": 0.04, "taken": 0.8},
				"desc": "Lin Feng and Yue Ling have become kindred spirits. In a thousand years Nian has never eaten a family that stayed up together, and the two of them have been up together all year.",
				"line": "Yue Ling takes his hand, and Nian, looking for somebody alone in the dark, cannot find anybody."},
			{"id": "craft", "kind": "craft", "n": "The Lantern of Ten Thousand Doors", "needs": [["item", "hearth_lantern", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Smith Tie can raise a great red lantern of bronze and thunder bamboo, hot with fire essence and hard with metal: red, fire and noise all at once, in one light.",
				"line": "The great red lantern swings up over the lane, crackling and blazing, and Nian cannot look at it."},
			{"id": "respect", "kind": "respect", "n": "The name the world knows", "needs": [["renown", 900]], "boon": {"assist": 0.03, "taken": 0.9},
				"desc": "Renown of 900: every family in the land tells the story of the sweeper who swept the sky. Nian has eaten a great many fears, but never one with a name like yours in it.",
				"line": "Nian hears the name Lin Feng in a thousand stories at once, and for the first time in a thousand years it is the one afraid."},
			{"id": "might", "kind": "might", "n": "Drive the year out", "needs": [["lv", 62], ["temper", 8]], "boon": {},
				"desc": "Late Kindred Dao and a sword tempered eight times: strength enough to drive a whole year out of the village by hand.",
				"line": "Lin Feng stands in the lane between the beast and the village, and does not move."},
		]},
	# ---- Part XIX (the Hundred Works release): the ladder that goes up because up is where a ladder goes,
	# the dancer who built herself a heart, and what is left of a founder who never said it was enough
	"cloud_ladder": {"might": [2.4, 1.3],
		"why": "Gongshu Ban built the first cloud ladder for a king, to go over a wall. This one has no king, no wall and no hand on it: every engine in the land is sending it timber, and it is going up because nobody ever built it a reason to stop.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A belt and nine sticks", "needs": [["item", "defence_models", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Smith Tie can copy the models Mozi laid on a table in front of the King of Chu: a belt for a wall and nine slips of catalpa for nine defences. Nine times the ladder came on, and nine times it was turned. Every one of its assaults has an answer, and you will be holding them.",
				"line": "Lin Feng lays the belt on the ground in front of the tower and sets the nine slips on it, one by one, and the Cloud Ladder stops with a wheel in the air, as if it remembered losing."},
			{"id": "works", "kind": "works", "n": "A maker's eye", "needs": [["works", "", 5]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "Five works built with your own hands. Somebody who has cut a mortise knows where a thing is held together, and so where it comes apart: the wedges, the king-post, the one peg everything hangs from.",
				"line": "Lin Feng walks once round the tower, the way Gongshu Ban walks round a baulk of timber, and knows which peg."},
			{"id": "might", "kind": "might", "n": "Cut it at the foot", "needs": [["lv", 70], ["temper", 8]], "boon": {},
				"desc": "Early Skill Become Dao and a sword tempered eight times: a blade that goes through seasoned oak and bronze strapping as an adze goes through pine.",
				"line": "Lin Feng draws at the foot of the tower, where the eight axles meet, and does not look up."},
		]},
	"wooden_magpie": {"might": [2.4, 1.3],
		"why": "Gongshu Ban built it too well to stop: a magpie of bamboo and wood that flew three days, of which Mozi said a linchpin was worth more. It has been on the wind for two thousand years, and every kite in the land that has nowhere left to go has followed it up.",
		"paths": [
			{"id": "relic", "kind": "relic", "n": "Show it how to stop", "needs": [["item", "still_heart", 1]], "boon": {"foe_hp": 0.7, "foe_atk": 0.85},
				"desc": "The stopped escapement from the oldest pit at Tushan: the first one, the piece that lets a machine rest. Hold it up where a thing with one black peg for an eye can see it. It was never given one.",
				"line": "Lin Feng holds up the little toothed wheel, not turning, and the great bird's wingbeat falters, as if it had heard its own name."},
			{"id": "works", "kind": "works", "n": "Find the string", "needs": [["works", "", 6]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "Six works built with your own hands. A kite, however large, was flown on a string once, and somebody who has made things knows where the bridle was tied: the one place the whole bird hangs from.",
				"line": "Lin Feng looks at the Wooden Magpie the way Gongshu Ban looks at a joint, and sees the worn place under the breast where the string was."},
			{"id": "might", "kind": "might", "n": "Out-fly it", "needs": [["lv", 71], ["temper", 8]], "boon": {},
				"desc": "Middle Skill Become Dao and a sword tempered eight times: a flying sword quick enough to stay above a bird that has had two thousand years of practice.",
				"line": "Lin Feng steps on to his sword and goes up into the wind after it."},
		]},
	"the_player": {"might": [2.4, 1.3],
		"why": "Yan Shi made a dancer, took out its heart to save his own neck, and kept it. The Player has filled the hollow with the escapements of every machine in the land, and will not be emptied a second time. It has had three thousand years to practise every movement a body can make.",
		"paths": [
			{"id": "heart", "kind": "heart", "n": "One who was made, to another", "needs": [["heart", 3]], "boon": {"assist": 0.04, "foe_atk": 0.85},
				"desc": "Lin Feng and Yue Ling are kindred spirits at least. She was woven on a loom and woke by a pond with nobody's leave. She will not fight the Player: she will stand in front of it and tell it what the first year of having a heart is like.",
				"line": "Yue Ling steps into the swept circle with her hands open. 'It gets quieter,' she says. 'Not soon. I will not lie to you. But it does.'"},
			{"id": "works", "kind": "works", "n": "Read the joinery", "needs": [["works", "", 7]], "boon": {"foe_hp": 0.7, "taken": 0.85},
				"desc": "Seven works built with your own hands. The Player moves like water, but it is jointed like a cabinet, and by now you can see how a thing is jointed while it is moving.",
				"line": "Lin Feng watches the Player's wrist turn once, and sees the silk cord in it, and the pin."},
			{"id": "might", "kind": "might", "n": "Faster than the dance", "needs": [["lv", 71], ["temper", 8]], "boon": {},
				"desc": "Middle Skill Become Dao and a sword tempered eight times: quick enough to follow a dancer who has not missed a step since the reign of King Mu.",
				"line": "Lin Feng steps into the swept circle, and for the first time in three thousand years the Player has a partner."},
		]},
	"jixin": {"might": [2.5, 1.3],
		"why": "The first master of the oldest pit said he would rest when the work was done, and said it for four thousand years. What is left of him is the Machine Heart: every escapement in the land in one wheel, and at the hub a founder who has forgotten there is such a thing as enough.",
		"paths": [
			{"id": "works", "kind": "works", "n": "Speak as a maker", "needs": [["works", "best", 4]], "boon": {"foe_hp": 0.7, "taken": 0.85},
				"desc": "Four works of one school, built with your own hands: enough to be a journeyman of it. Jixin does not hear cultivators. He hears makers. Tell him, as one who has also not wanted to put the tool down, what it was like to put it down.",
				"line": "Lin Feng holds up his two hands, with the splinters in them. 'I know,' he says. 'It works, and you cannot stop looking at it. I know. Stop anyway.'"},
			{"id": "hearth", "kind": "hearth", "n": "Nine stools and a bench", "needs": [["hearths", 6]], "boon": {"assist": 0.04, "foe_hp": 0.8},
				"desc": "All six hearths of the land call you a guest. Their makers came down into the pit because you asked, and they will do the one thing the Machine Heart cannot bear: sit down, all together, in front of it, and rest.",
				"line": "Auntie Rong sits down first. Then Tie, and Gao, and the lantern-maker, and the keeper of one well. The great wheel shudders, as if at a blow."},
			{"id": "might", "kind": "might", "n": "Stop the wheel by hand", "needs": [["lv", 71], ["temper", 8]], "boon": {},
				"desc": "Middle Skill Become Dao and a sword tempered eight times: a blade to put between the teeth of a wheel as wide as the pit, and an arm to hold it there.",
				"line": "Lin Feng walks down the ramp alone, and sets the flat of his sword against the turning rim."},
		]},
	# ---- Part XX (the Hollow Hills release): what was asleep in the earth, the lady of the Bottomless
	# Cave, the edge of a shadow that asked a question, and what is in a hollow when nothing is
	"fen_yang": {"might": [2.4, 1.3],
		"why": "When the men of Lu dug a well they found a thing like a sheep in an earthen jar, and Confucius said: what is in the earth is the Fenyang. Yu Gong's sons dug one up by accident, with picks, and it is the size of a barn, half awake, and has never seen a light before.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A bell it knows", "needs": [["item", "lamb_bell", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Alchemist Mo can fire a bellwether's bell of the mountain's own clay, with a basket of its earth in the slip. It does not ring; it knocks, like a knuckle on a jar. Every lamb knows the bell it was born behind. This one was born behind the hill.",
				"line": "Lin Feng shakes the clay bell once. It knocks, dull and low, and the Lamb of the Earth turns its great head towards the sound like a ewe that has heard her name."},
			{"id": "delve", "kind": "delve", "n": "One who knocks first", "needs": [["delved", 2]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "Two caves gone to the very back of. Somebody who has walked into the dark on his own feet, and out again, comes into a room under a hill the way a guest does: slowly, with the light held low, and saying who he is.",
				"line": "Lin Feng lowers the torch, stands where it can see him, and says his name to the dark, as Xu Xiake does at the mouth of every cave."},
			{"id": "might", "kind": "might", "n": "Hold it by the horns", "needs": [["lv", 72], ["temper", 8]], "boon": {},
				"desc": "Early Hollow Vessel in the making and a sword tempered eight times: strength to take a thing the weight of a barn by the horns and stand there until it stops being frightened.",
				"line": "Lin Feng sheathes his sword, walks in under the horns, and takes hold."},
		]},
	"white_rat": {"might": [2.4, 1.3],
		"why": "The Rat of the Bottomless Cave has a gold nose, white hair and three hundred years of cultivation, and kept a tablet to her adopted father in her parlour. The casters of Tushan dug through her ceiling after ore. She has their forty miners, their lamps, and a grievance about plaster.",
		"paths": [
			{"id": "delve", "kind": "delve", "n": "A guest who knows the way in", "needs": [["delved", 3]], "boon": {"foe_hp": 0.7, "taken": 0.85},
				"desc": "Three caves gone to the very back of. She has had forty men drop through her roof. Somebody who comes down the shaft a rung at a time, wipes his feet, and remarks on the dripstone is another matter, and will be heard out before anything is thrown.",
				"line": "Lin Feng comes down the last of the rope, wipes his boots on the rock, and says what a fine hall it is. The White-Haired Rat's whiskers go forward."},
			{"id": "hearth", "kind": "hearth", "n": "Whose soup is it", "needs": [["hearths", 6]], "boon": {"assist": 0.04, "foe_hp": 0.8},
				"desc": "All six hearths of the land call you a guest. She fed her prisoners, which makes them guests, which makes her a hostess, which has rules. You know the rules of six tables by now, and exactly what a hostess owes somebody who has eaten at hers.",
				"line": "Lin Feng takes a bowl from the nearest miner, tastes it, and thanks her for it by name. The forty men of Tushan, catching on, all do the same."},
			{"id": "might", "kind": "might", "n": "Faster than a rat", "needs": [["lv", 73], ["temper", 8]], "boon": {},
				"desc": "Middle Hollow Vessel in the making and a sword tempered eight times: quick enough for a creature that has never once been where the blow landed.",
				"line": "Lin Feng draws. The White-Haired Rat sighs, as a lady sighs who had hoped for conversation."},
		]},
	"wangliang": {"might": [2.5, 1.3],
		"why": "Penumbra asked Shadow why it had no will of its own, and Shadow said it waited on something, which waited on something else. The asker is Wangliang: the edge of a shadow, in the deepest hall of a cave that kept every word ever shouted into it. It is so full of other people's voices that it has not heard its own in a thousand years.",
		"paths": [
			{"id": "heart", "kind": "heart", "n": "One voice it has not got", "needs": [["heart", 3]], "boon": {"assist": 0.04, "foe_atk": 0.85},
				"desc": "Lin Feng and Yue Ling are kindred spirits at least. She was woven; nobody ever shouted her name into a cave before she had one. She will stand in front of it and say something that is not an echo of anything, and it will have to stop and listen.",
				"line": "Yue Ling walks out into the middle of the hall and sings one line, of a song she is making up as she goes. For the first time in a thousand years, nothing answers."},
			{"id": "craft", "kind": "craft", "n": "A light that does not flicker", "needs": [["item", "pine_torch", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Smith Tie can make Xu Xiake's own torch: pine heartwood, wire and essence, six hours without a waver. A penumbra is the part of a shadow where the light is not sure. Give it a light that is sure.",
				"line": "Lin Feng holds the torch up at arm's length, and its flame stands as still as a painted one, and the grey edge on the wall draws in, and in, and is a line."},
			{"id": "delve", "kind": "delve", "n": "Count the paces", "needs": [["delved", 4]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "Four caves gone to the very back of. You know by now that a cave has an end, however it sounds. So does a voice. Count your paces aloud, as the traveller does, and do not stop counting whatever answers.",
				"line": "Lin Feng walks towards it counting, four hundred and seven, four hundred and eight, and the echoes, having nothing of his to give back but numbers, fall into step."},
			{"id": "might", "kind": "might", "n": "Cut the edge from the shadow", "needs": [["lv", 73], ["temper", 8]], "boon": {},
				"desc": "Middle Hollow Vessel in the making and a sword tempered eight times: an edge fine enough to pass between a shadow and its own border.",
				"line": "Lin Feng draws, and for a moment there are two shadows on the wall with nothing to cast them."},
		]},
	"xuanpin": {"might": [2.6, 1.3],
		"why": "The valley spirit never dies; it is called the dark female. She is what is in a hollow when nothing is: the use of the jar, the room, the well. The land has filled its hollow places one at a time, all meaning well, and she has gone down to the last of them and taken the water with her. She is not angry. That is the difficulty.",
		"paths": [
			{"id": "relic", "kind": "relic", "n": "What everything leans on", "needs": [["item", "borrowed_shadow", 1]], "boon": {"foe_hp": 0.7, "foe_atk": 0.85},
				"desc": "The shadow's shadow that Wangliang left. Held up, it shows what a thing depends on: the penumbra on the shadow, the shadow on the body. Hold it up to a land. Every village, wheel and furnace in it is leaning on a place where there is nothing. She asked to be shown you know what she is for.",
				"line": "Lin Feng unfolds the grey edge and holds it up, and on the black water, behind the picture of every lit window in the land, there is a second, fainter outline: the well under it."},
			{"id": "delve", "kind": "delve", "n": "Somebody who came to see", "needs": [["delved", 6]], "boon": {"foe_hp": 0.75, "taken": 0.85},
				"desc": "Six caves gone to the very back of, for no better reason than to know how far in they went. She has been dug into, tipped into, walled up and drawn from. Nobody has come down merely to look, and written it down the same night, since a man from Jiangyin with a pine torch.",
				"line": "Lin Feng takes out Xu Xiake's little book and reads her the six entries, paces and all. Xuanpin listens to the end. 'He counted the drips,' she says."},
			{"id": "works", "kind": "works", "n": "A maker of vessels", "needs": [["works", "", 8]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "Eight works built with your own hands. Whoever has made a kiln, a furnace or a bellows has made a hollow on purpose and knows it is the hollow that does the work. Say so, as a maker, to the one it is true of.",
				"line": "Lin Feng holds up his hands. 'A furnace is a hole with a wall round it,' he says. 'I built one. I should have known you then.'"},
			{"id": "might", "kind": "might", "n": "Draw the water by force", "needs": [["lv", 74], ["temper", 8]], "boon": {},
				"desc": "Late Hollow Vessel in the making and a sword tempered eight times. She said: take it from me, if you can. It can be done. She also said what would happen to it afterwards.",
				"line": "Lin Feng steps out on to the black water, and it bears him, and he draws."},
		]},
	# ---- Part XXI (the Hundred Arms release): the first pupil nobody asked for, a pair that cannot find
	# each other, a king who would rather watch than rule, and four thousand blades with no hand
	"yuan_gong": {"might": [2.4, 1.3],
		"why": "The old man in white asked to see the Maiden's sword, broke a bamboo to test her, and went up a tree an ape. He saw one stroke, two thousand years ago, and has made a whole school out of it. He is faster than anything in the marsh and has never once been shown anything else.",
		"paths": [
			{"id": "arms", "kind": "arms", "n": "Something he has not seen", "needs": [["arms", 2]], "boon": {"foe_hp": 0.7, "weak_k": 1.9},
				"desc": "Two Daos of arms learned to Adept. He knows one stroke of one weapon perfectly, and has been waiting two thousand years for somebody to show him a second. An ape that is watching closely is an ape that has stopped moving.",
				"line": "Lin Feng changes hands in the middle of the bow, and the White Ape, who has never seen that done, sits down on his branch to see it done again."},
			{"id": "craft", "kind": "craft", "n": "Peaches before lessons", "needs": [["item", "ape_fruit", 1]], "boon": {"foe_hp": 0.75, "no_heavy": true},
				"desc": "Alchemist Mo can ripen a basket of mountain peaches in an hour and weave the basket of the Maiden's own bamboo. A swordsman of two thousand years is still an ape for as long as it takes to eat one, and a pupil with his mouth full does not strike first.",
				"line": "Lin Feng sets the basket down between them. The old man in white looks at it, and at him, with great dignity, and then is not an old man at all."},
			{"id": "might", "kind": "might", "n": "Quicker than the ape", "needs": [["lv", 75], ["temper", 8]], "boon": {},
				"desc": "Early Hollow Vessel and a sword tempered eight times: the Maiden caught him with the butt of a switch before its tip touched the ground. It can be done. She was sixteen.",
				"line": "Lin Feng draws. Forty gibbons draw forty reeds."},
		]},
	"sword_dragons": {"might": [2.5, 1.3],
		"why": "Gan Jiang cast a pair of swords for the King of Wu, and the metal would not run until Mo Ye, his wife, went into the furnace. The swords were named for them. At the ford they leapt into the river as two dragons, and have gone round each other in the dark under the Gate ever since: each still a sword, and cutting whatever it turns towards.",
		"paths": [
			{"id": "heart", "kind": "heart", "n": "Two who know the way of it", "needs": [["heart", 3]], "boon": {"assist": 0.04, "foe_atk": 0.85},
				"desc": "You and Yue Ling are kindred spirits. Go into the water together, one to each, and walk them in towards one another the way two people carry a long thing through a door: by watching the other end, not your own.",
				"line": "Yue Ling wades in on the red dragon's side without being asked. 'You take him,' she says. 'I know what she is looking for.'"},
			{"id": "craft", "kind": "craft", "n": "One scabbard, two mouths", "needs": [["item", "mated_scabbard", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Smith Tie can make a double scabbard, lined with water essence and bound with a hilt out of the pool itself. A sword that sees its own sheath comes to it. Two that see one sheath made for both may remember what they were made as.",
				"line": "Lin Feng holds the double scabbard out over the water, mouths down, and both dragons turn at once."},
			{"id": "might", "kind": "might", "n": "Part the pair", "needs": [["lv", 76], ["temper", 8]], "boon": {},
				"desc": "Middle Hollow Vessel and a sword tempered eight times: strength to stand between a husband and a wife who have been looking for each other for two thousand years. It is not recommended.",
				"line": "Lin Feng steps into the deep water between the red and the blue."},
		]},
	"king_zhao": {"might": [2.5, 1.3],
		"why": "King Wen of Zhao loved swords. Three thousand swordsmen ate at his gate and fought before him day and night, and a hundred and more died of it each year, and he never tired of watching. He was told about the three swords once, and stayed in his palace three months. Then he forgot. He has had three years to forget in.",
		"paths": [
			{"id": "craft", "kind": "craft", "n": "A cock of wood", "needs": [["item", "wooden_cock", 1]], "boon": {"foe_hp": 0.7, "foe_atk": 0.85},
				"desc": "Smith Tie can carve Ji Xingzi's fighting cock, forty days in training, which in the end stood like a bird of wood, and no other cock would face it. Set it on the mat in front of a man who has watched three thousand fights. It is the only fighter in his hall that is not trying to win.",
				"line": "Lin Feng sets the wooden cock on the mat. The two men fighting stop of themselves. The king leans forward, for the first time in a year."},
			{"id": "arms", "kind": "arms", "n": "All three swords", "needs": [["arms", 4]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "Four Daos of arms learned to Adept. He asked to be shown the lowest sword. Show him four weapons, each perfectly, and put each one down when it is done. By the third he will have begun to see that the putting down is the part he has never watched.",
				"line": "Lin Feng lays the sabre on the mat beside the fan, and takes up the third. King Wen is counting on his fingers, and has gone pale."},
			{"id": "hearth", "kind": "hearth", "n": "Whose sons they are", "needs": [["hearths", 6]], "boon": {"assist": 0.04, "foe_hp": 0.8},
				"desc": "All six hearths of the land call you a guest. Every man at his gate came from one of them. Say the names of the towns, and what is eaten there in winter, and who is sitting up tonight beside a fire with one place empty at it.",
				"line": "Lin Feng begins with Shazhou, and the bread from the wall of the clay oven. Somewhere at the back of the hall, a swordsman puts his hand over his eyes."},
			{"id": "might", "kind": "might", "n": "The sword he already has", "needs": [["lv", 76], ["temper", 8]], "boon": {},
				"desc": "Middle Hollow Vessel and a sword tempered eight times. He asked for the sword of the common man: the one that cuts throats in front and livers behind. He has three thousand of them. Be one more, and the best, and he will have learned nothing.",
				"line": "Lin Feng puts away the fan, and draws."},
		]},
	"wuzhu": {"might": [2.6, 1.3],
		"why": "Every blade the pits poured unasked, and every sword that walked off its rack to join them, in one figure in the long barrow: four thousand edges that nobody made and nobody owns. It has built itself a hand out of what it had, and put Lin Feng's face on it, and wants to be shown everything a hand does. It will know if anything is left out.",
		"paths": [
			{"id": "relic", "kind": "relic", "n": "Read it the three swords", "needs": [["item", "three_swords", 1]], "boon": {"foe_hp": 0.7, "foe_atk": 0.85},
				"desc": "King Wen's scroll, in his own hand. It was never asked what kind of sword it is. Read it the three, slowly: the one whose edge is mountains, the one whose point is brave men, and the one that is no different from a fighting cock. Let four thousand blades hear that there was a choice.",
				"line": "Lin Feng unrolls King Wen's scroll and reads it aloud, in the dark, to four thousand swords. At the sword of the Son of Heaven, the humming stops to listen."},
			{"id": "arms", "kind": "arms", "n": "Everything a hand does", "needs": [["arms", 6]], "boon": {"foe_hp": 0.7, "weak_k": 1.9},
				"desc": "Six Daos of arms learned to Adept. It asked to be shown all of it. Show it: the jian, the staff, the sabre, the spear, whatever you have made your own. And between each and the next, the thing it has never seen, and is made of blades because it has never seen: an open hand.",
				"line": "Lin Feng lays down the sixth weapon and holds up both hands, empty, in front of the polished flat where its face should be."},
			{"id": "hearth", "kind": "hearth", "n": "A rack by every door-flap", "needs": [["hearths", 5]], "boon": {"assist": 0.04, "foe_hp": 0.8},
				"desc": "Five hearths of the land call you a guest. Each has a place where its one weapon hangs: by the door-flap, over the oven, in the boat's locker. Tell four thousand blades that there are that many pegs in the world, and somebody's grandmother watching each.",
				"line": "Lin Feng says: there is a peg by a door-flap on the steppe with nothing on it. It turns its bright flat towards him, slowly."},
			{"id": "might", "kind": "might", "n": "A better edge", "needs": [["lv", 77], ["temper", 8]], "boon": {},
				"desc": "Late Hollow Vessel and a sword tempered eight times. It asked what a hand does. One answer is: this. It is the answer it expects, and the only one that will teach it nothing it does not know.",
				"line": "Lin Feng draws the jian. Four thousand blades turn their points to him, pleased."},
		]},
	# ---- Part XXII: The High Roads
	"shanxiao": {"might": [2.4, 1.3],
		"why": "It has one leg, the wrong number of fingers and nobody to talk to, and it has learned that people come when they are called by name. It has carried off every bag of salt on the south road and every voice it has overheard, and three woodcutters have gone up into the cloud after it. It is faster on one foot than a man on two, and afraid of exactly one thing.",
		"paths": [
			{"id": "heights", "kind": "heights", "n": "Somebody who came up the same way", "needs": [["summits", 2]], "boon": {"foe_hp": 0.7, "weak_k": 1.9},
				"desc": "Two summits stood on. It has watched people fly over its mountain all its life and never once seen one arrive at the top on his hands, out of breath, as it does. A thing that is met on its own ground by its own road stops to look.",
				"line": "Lin Feng comes over the edge of the height on his hands, breathing hard, and the shanxiao, which has only ever been looked down on, sits back on its one heel to stare."},
			{"id": "craft", "kind": "craft", "n": "Green bamboo on the fire", "needs": [["item", "crackle_bamboo", 1]], "boon": {"foe_hp": 0.75, "no_heavy": true},
				"desc": "Alchemist Mo can pack three joints of green bamboo so that they crack in a fire like a string of thunder, as the grandmothers burned them at the New Year. It does the creature no harm. It only cannot bear to be startled, and a thief with its hands over its ears strikes no heavy blow.",
				"line": "Lin Feng lays three green joints on the embers. At the first crack the shanxiao claps both hands to its head and forgets every voice it owns."},
			{"id": "might", "kind": "might", "n": "Quicker than one foot", "needs": [["lv", 78], ["temper", 8]], "boon": {},
				"desc": "Early Sheathed Edge and a sword tempered eight times. It hops faster than a horse runs, uphill, and throws salt. Nobody has caught one since the books were written. It can be done; it will not make it any less lonely.",
				"line": "Lin Feng draws. The shanxiao says, in his own voice, a little out: Lin Feng draws."},
		]},
	"fei_lian": {"might": [2.5, 1.3],
		"why": "The Earl of the Wind blew for Chiyou at Zhuolu and has carried every sail, seed and banner since, and in all that time nobody has asked. This spring there are paper swallows all over his sky, and now grown men hanging underneath. He has drawn his bag shut on every breath from the mountain to the sea, and come to see who is falling through his air without leave.",
		"paths": [
			{"id": "relic", "kind": "relic", "n": "His own knot, handed back", "needs": [["item", "wind_knot", 1]], "boon": {"foe_hp": 0.7, "foe_atk": 0.85},
				"desc": "One of his own cords, with the three knots still in it. Any sailor would undo the first for a breeze. Hand it back to him tied, all three, and he will know that somebody could have taken his wind and did not: it is the nearest thing to being asked that he has had.",
				"line": "Lin Feng holds out a cord of grey silk with three knots in it, untouched. The Earl of the Wind lowers his head to look, and the gale he had been drawing in goes out of him as a sigh."},
			{"id": "heights", "kind": "heights", "n": "One who climbed to the edge", "needs": [["summits", 3]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "Three summits stood on. He despises whatever wants to get somewhere. Somebody who has gone up three mountains by his hands to stand on the top and come down again has plainly not been trying to get anywhere at all.",
				"line": "Fei Lian snuffs at Lin Feng's hands: rock-dust, three mountains of it. Whatever this one wants, it is not to be somewhere else."},
			{"id": "might", "kind": "might", "n": "Against the wind", "needs": [["lv", 79], ["temper", 8]], "boon": {},
				"desc": "Middle Sheathed Edge and a sword tempered eight times: weight enough to stand in what took the roofs off Zhuolu. The Yellow Emperor needed a goddess of drought to do it.",
				"line": "Lin Feng sets his feet. The Earl of the Wind undoes the second knot."},
		]},
	"shan_gui": {"might": [2.5, 1.3],
		"why": "She came late to the top of the mountain, and the one she came to meet was not there, and she has never known whether he had been and gone or had not come. So she keeps every summit in the land in cloud, that nobody may arrive at any of them: for if nobody can, he has not arrived without her. Her leopards lie across the paths.",
		"paths": [
			{"id": "heights", "kind": "heights", "n": "The paths he did not come by", "needs": [["summits", 4]], "boon": {"foe_hp": 0.7, "taken": 0.85},
				"desc": "Four summits stood on. She does not know which top he meant. Somebody who has stood on four of them, and can tell her truthfully that he was on none, has done for her what she has not been able to do for herself in a thousand years: looked.",
				"line": "Lin Feng tells her the four tops he has stood on, by name, and who was on each. She listens to every one as to a door opening on an empty room."},
			{"id": "heart", "kind": "heart", "n": "One who was waited for", "needs": [["heart", 3]], "boon": {"assist": 0.04, "foe_atk": 0.85},
				"desc": "Yue Ling a companion of the heart. She slept in a lotus for three hundred years and somebody did come. She will not tell the Mountain Spirit that he is coming; she will stand beside her, facing down the path, and say what it was like on the day the waiting stopped.",
				"line": "Yue Ling goes and stands beside her, shoulder to shoulder, facing down the path, and says nothing at all for a long time. The red leopard, after a while, lies down across both their feet."},
			{"id": "might", "kind": "might", "n": "Through the cloud", "needs": [["lv", 79], ["temper", 8]], "boon": {},
				"desc": "Middle Sheathed Edge and a sword tempered eight times: enough to part a cloud that a goddess has held together with her two hands for a thousand years. It will be parted. She will see the path. Nobody will be on it.",
				"line": "Lin Feng draws. The cloud comes down to the height of his knees and stays there."},
		]},
	"dongyue": {"might": [2.6, 1.3],
		"why": "Seventy-two kings climbed him to tell Heaven they had succeeded, and he received every one; after the kings the prefects, and after the prefects anybody with a chisel. He is the mountain and cannot go home. Nine days of a goddess's cloud kept everybody off him, and he was glad of it. Now he means to put a lid of stone on his own top.",
		"paths": [
			{"id": "heights", "kind": "heights", "n": "Nine tops, and nothing to report", "needs": [["summits", 9]], "boon": {"foe_hp": 0.7, "weak_k": 1.9},
				"desc": "Nine summits stood on. Everybody who has ever reached his desk has told him what they had done. Somebody who has stood on nine mountains this spring, and has put a stone on each and written his name on none, is a thing he has no form to fill in for.",
				"line": "The Lord of the Eastern Peak asks what Lin Feng has to report. Nine summits, says Yue Ling, for him. And what did he leave on them? A stone. The great brush stops over the register, and does not come down."},
			{"id": "craft", "kind": "craft", "n": "A slip with nothing on it", "needs": [["item", "blank_slip", 1]], "boon": {"foe_hp": 0.75, "foe_atk": 0.85},
				"desc": "Smith Tie can grind one of the old kings' jade slips smooth again, until not a stroke of the report is left. Hand it in at the desk like any other. In two thousand years he has received every kind of announcement but this one.",
				"line": "Lin Feng lays a jade slip on the stone desk. The Lord of the Eastern Peak turns it over, and over again. There is nothing on it. He reads it twice."},
			{"id": "might", "kind": "might", "n": "Move the mountain", "needs": [["lv", 80], ["temper", 8]], "boon": {},
				"desc": "Late Sheathed Edge and a sword tempered eight times. Yu Gong meant to move two mountains with a basket, and Heaven sent giants to do it for him. This is the eldest of the five, and there are no giants.",
				"line": "Lin Feng draws. The Lord of the Eastern Peak writes it down."},
		]},
	# ---- Part XXIII (the Thundering Pots release): the general who obeyed, the lute with lead in it, the king who never
	# lost a charge, and the first pot
	# ---- Part XXIV (the Lost Horse release): the horse nobody was meant to own, and the keeper of both columns
	"hu_steed": {"might": [2.8, 1.3],
		"why": "It is of the line the Hu do not sell. It has thrown nine riders in its own country, and it followed an old mare over the frontier because it was tired of people who were sure of it. It will stand for nobody who comes up the height certain of bringing it down.",
		"paths": [
			{"id": "relic", "kind": "relic", "n": "Four cast shoes", "needs": [["item", "cast_shoe", 4]], "boon": {"foe_hp": 0.7, "foe_atk": 0.85},
				"desc": "The four shoes the old mare cast on the way. Lay them down in front of it. It knows that iron: it walked beside it for three hundred li, of its own will, and was not once led.",
				"line": "Lin Feng lays four worn shoes on the rock and steps back from them. The red ear comes round. It has not been offered a thing with no hand on it before."},
			{"id": "loss", "kind": "loss", "n": "Somebody the tide has moved", "needs": [["falls", 3]], "boon": {"foe_hp": 0.75, "taken": 0.85},
				"desc": "Three battles that could not be won, lost and gone on from. It has thrown nine riders, and every one of them came up the height never having been thrown by anything. Go up as somebody who has.",
				"line": "It breathes him in: salt, and wrack, and the particular quiet of a man who has lately been picked up and put down. It has not smelled that on a rider before."},
			{"id": "mark", "kind": "mark", "n": "What he left standing", "needs": [["marks", 3]], "boon": {"foe_hp": 0.8, "weak_k": 1.8},
				"desc": "Three things your choices left standing, gone and looked at. A horse knows whether whoever is coming up to it has ever gone back to see what became of a thing after he had done with it.",
				"line": "Lin Feng tells it, as one tells a horse anything, about a road and a wall and a tree. The red ear stays on him to the end."},
			{"id": "might", "kind": "might", "n": "Break it", "needs": [["lv", 85], ["temper", 9]], "boon": {},
				"desc": "Middle Great Sound and a sword tempered nine times. Horses are broken. That is the word for it, and nine good riders have tried.",
				"line": "Lin Feng draws. The horse looks at the north, and then, as if it could put it off no longer, at him."},
		]},
	"huofu": {"might": [2.9, 1.3],
		"why": "Huofu has kept the book since there was first something to gain and something to lose: red for the one, black for the other, a line down the middle. Twenty-three in a row in your black column. It has been waiting to see the page turn, and it does not believe a man with that page can come up the hill meaning anything but to add to it.",
		"paths": [
			{"id": "loss", "kind": "loss", "n": "Three in the red", "needs": [["falls", 3]], "boon": {"foe_hp": 0.65, "foe_atk": 0.8},
				"desc": "Three battles that could not be won, lost and gone on from. Show it the red column. Then ask it to put its brush on the place where your losing ended and your choosing began, and watch it try.",
				"line": "\"Three,\" says Lin Feng, \"and here is what came of each.\" The red brush stops over the page. It cannot find where to put the line."},
			{"id": "mark", "kind": "mark", "n": "What stands", "needs": [["marks", 6]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "Six things your choices left standing, gone and looked at. None of them is a gain or a loss. They are only there. Name them to something that has two columns and nowhere to write a thing that is only there.",
				"line": "A road. A bell. A row of houses on legs. Huofu writes each one down, and then sits with both brushes lifted, because neither column will take them."},
			{"id": "might", "kind": "might", "n": "Add to the black column", "needs": [["lv", 86], ["temper", 9]], "boon": {},
				"desc": "Late Great Sound and a sword tempered nine times. It expects exactly this of you. It has the brush wet already.",
				"line": "Lin Feng draws. \"Twenty-four, then,\" says Huofu, with both mouths, and dips the black brush."},
		]},
	"meng_tian": {"might": [2.6, 1.3],
		"why": "Meng Tian built the Wall with three hundred thousand men and never marched without the tally. When a forged letter told him to die he asked only whether the seal was true. Fired in clay and buried with the army, he has half a tally and is keeping the vanguard ready, for an order that is not coming.",
		"paths": [
			{"id": "host", "kind": "host", "n": "A host nobody ordered", "needs": [["companies", 7]], "boon": {"foe_hp": 0.7, "foe_atk": 0.85},
				"desc": "Seven companies in the host, every one of them asked for and none commanded. Let him look down the slope at it. He has led three hundred thousand, and not one of them ever came because he wanted to.",
				"line": "Lady Hao raises one hand, and seven companies who were asked nicely ground their spears. Meng Tian looks for the tally that brought them. There is none."},
			{"id": "relic", "kind": "relic", "n": "Four left halves", "needs": [["item", "tiger_tally", 4]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "The four halves of tiger tallies from the field. Every one is a left half: the half a general keeps. Show him that nobody, anywhere, is holding the right.",
				"line": "Lin Feng lays four bronze half-tigers on the rock, nose to nose. Meng Tian tries each against his own. None of them finishes the writing."},
			{"id": "might", "kind": "might", "n": "Break the Wall", "needs": [["lv", 82], ["temper", 8]], "boon": {},
				"desc": "Middle Leaning on Nothing and a sword tempered eight times. He is six hundred plates of fired clay with a general inside. It has been done to a wall before.",
				"line": "Lin Feng draws. The general of clay orders the left wing to advance, and nobody does."},
		]},
	"gao_jianli": {"might": [2.6, 1.3],
		"why": "Gao Jianli played at the River Yi when Jing Ke went to kill the King of Qin. The king had his eyes put out, kept him to play, and was struck at with a lute full of lead. He missed. He has played the leaded lute ever since, and eight thousand feet keep its time.",
		"paths": [
			{"id": "song", "kind": "song", "n": "A fourth above", "needs": [["airs", 3]], "boon": {"foe_hp": 0.7, "taken": 0.85},
				"desc": "Three airs of the land, learned and sung. He has kept every tune out of that lute for two thousand years because the man he hated liked them. Sing him one the man never heard.",
				"line": "Lin Feng sings the planting song, badly, bent over as it is sung. The rod stops over the strings. \"That is flat,\" says Gao Jianli. \"...Go on.\""},
			{"id": "hearth", "kind": "hearth", "n": "Those who wept at the Yi", "needs": [["hearths", 4]], "boon": {"foe_hp": 0.75, "foe_atk": 0.85},
				"desc": "Four hearths of the land call you a guest. Everybody at the River Yi wept when he played, and he has never forgiven them for letting Jing Ke go. Tell him who is listening now.",
				"line": "Lin Feng names four fires and who sits at them. \"And they would weep?\" asks the blind man. \"They would ask you to supper,\" says Yue Ling."},
			{"id": "might", "kind": "might", "n": "Cut the strings", "needs": [["lv", 83], ["temper", 8]], "boon": {},
				"desc": "Late Leaning on Nothing and a sword tempered eight times. The lute weighs what a mill-stone weighs, and he swings it by ear.",
				"line": "Lin Feng draws. Gao Jianli tilts his head, and says the sword is a fifth sharp."},
		]},
	"xiang_yu": {"might": [2.7, 1.3],
		"why": "Xiang Yu crossed the river with eight thousand sons of Chu and never lost a charge. At Gaixia he heard the songs of Chu on four sides in the night, and by morning stood in front of nobody. He would not cross the Wu River alone. He has fought the field a thousand times since, and has only ever lost it once.",
		"paths": [
			{"id": "song", "kind": "song", "n": "The songs of Chu", "needs": [["airs", 5]], "boon": {"foe_hp": 0.65, "weak_k": 1.9},
				"desc": "Five airs of the land. There is no beating him and there never was. Sing what was sung the first time: not to his soldiers, who have gone, but to him.",
				"line": "Five airs, one song. The Hegemon-King listens to the end. \"The boatman said I could still be a king there,\" he says. \"He did not say I could go home.\""},
			{"id": "host", "kind": "host", "n": "Somebody to look at their fathers", "needs": [["companies", 8]], "boon": {"foe_hp": 0.75, "taken": 0.85},
				"desc": "Eight companies in the host, and every man of them to be sent home alive. He could not face the fathers of eight thousand. Stand in front of him with eight hundred whose fathers you will look in the eye.",
				"line": "\"How many did you bring over?\" asks the Hegemon-King. Eight hundred. \"And how many go back?\" Lady Hao answers: \"I have the roll. All of them.\""},
			{"id": "might", "kind": "might", "n": "Meet the charge", "needs": [["lv", 83], ["temper", 9]], "boon": {},
				"desc": "Late Leaning on Nothing and a sword tempered nine times. His strength plucked up the hills. Nobody has ever stood in front of it and been there afterwards.",
				"line": "Lin Feng draws. The Hegemon-King lets go of the bridle."},
		]},
	"wafu": {"might": [2.8, 1.3],
		"why": "The first thing anybody made was a pot, and the first music was somebody beating on it with a bone to say supper. Then Ling Lun cut a pipe, and a bell was cast to the pipe, and the pot was thrown away as noise. It has been calling for four thousand years. It struck the Yellow Bell once, with its own foot, to be heard.",
		"paths": [
			{"id": "song", "kind": "song", "n": "Answer it", "needs": [["airs", 6]], "boon": {"foe_hp": 0.65, "foe_atk": 0.8},
				"desc": "All six airs of the land. Every one of them was first sung over a pot, to a beat. Sing all six to the beat it is making, and let it find out that it has had a tune the whole time.",
				"line": "Six airs, sung in time to the thunder, and the thunder under them like a keel. The great pot stops, the way a man stops who has just heard his name."},
			{"id": "works", "kind": "works", "n": "A potter's hands", "needs": [["works", "hand", 3]], "boon": {"foe_hp": 0.75, "taken": 0.85},
				"desc": "Three works of the Hand built: the oldest school, fire and clay and cord. It was made by somebody who needed it. Come as somebody who makes things because they are needed.",
				"line": "Lin Feng lays a hand on the cracked rim, as a potter does, to feel where it is thin. Nobody has touched it since it was thrown away."},
			{"id": "might", "kind": "might", "n": "Break the pot", "needs": [["lv", 83], ["temper", 9]], "boon": {},
				"desc": "Late Leaning on Nothing and a sword tempered nine times. It is cracked already. It has been cracked since the Xia, and it is still here.",
				"line": "Lin Feng draws. BOOM, says the pot."},
		]},
	# ---- Part XVIII (the New Fire release): the Lord of the Southern Fire, and the fire nobody sat up with
	"zhurong": {"might": [2.3, 1.3],
		"why": "Zhurong has opened every summer for ten thousand years by giving the land new fire from Suiren's drill, to hearths put out to receive it. Lin Feng has come with six that would not be put out, and asks him to bless the pot.",
		"paths": [
			{"id": "hearth", "kind": "hearth", "n": "Speak for the hearths", "needs": [["hearths", 3]], "boon": {"foe_hp": 0.7, "taken": 0.85},
				"desc": "Three hearths of the land call you a guest: you have eaten their way, carried their fuel, kept their rules. Tell the Lord of Fire whose fires these are, one by one, and what it cost each keeper to hand you a coal.",
				"line": "Lin Feng names the keepers: the midwife, the grandmother in the tent, the cook, the boat-wife, the founder, the lantern-maker. The dragons of flame lift their heads at every name."},
			{"id": "craft", "kind": "craft", "n": "A drill of summer wood", "needs": [["item", "fire_drill", 1]], "boon": {"foe_hp": 0.7, "weak_k": 1.9},
				"desc": "Smith Tie can make a bow-drill of apricot and jujube, bound with wood and fire essence, the way Suiren made his. Turn it in front of the Lord of Fire: you did not come to be given fire. You came knowing how it is made.",
				"line": "Lin Feng sets the spindle to the board and turns it, and a thread of smoke rises in front of the god who thought only he remembered how."},
			{"id": "might", "kind": "might", "n": "Stand in the forge mouth", "needs": [["lv", 67], ["temper", 8]], "boon": {},
				"desc": "Middle Myriad Things cultivation and a sword tempered eight times: a blade that has been through as many fires as his season has days.",
				"line": "Lin Feng walks into the heat with the pot under one arm and his sword in the other hand, and does not put the pot down."},
		]},
	"huilu": {"might": [2.4, 1.3],
		"why": "The new fire was drilled, and six keepers each lit a bonfire of their own from it to show the others the right way, and turned their backs to argue. Six fires nobody sat up with ran together in the dry wind, and went looking for somebody.",
		"paths": [
			{"id": "hearth", "kind": "hearth", "n": "Six lines of buckets", "needs": [["hearths", 5]], "boon": {"assist": 0.04, "foe_hp": 0.8},
				"desc": "Five hearths or more call you a guest. Their people will take a bucket from your hand, whoever is standing next to them: horse-folk beside founders, boat-wives beside lantern-makers, six lines from the well to the fire.",
				"line": "The lines form without anybody giving an order: a bucket goes from a herder to a founder to a river woman to a child of Yanggu, and nobody asks whose turn it is."},
			{"id": "land", "kind": "land", "n": "Kang's firebreak", "needs": [["cleared", 34]], "boon": {"foe_hp": 0.7, "taken": 0.85},
				"desc": "Thirty-four things cleared out of the land's way with your own sword, the brush round the Gathering ground among them. Draw the fire down on to the bare earth you cut, where there is nothing for it to eat.",
				"line": "Lin Feng backs down the hill, step by step, on to the ring of bare earth, and the great bird follows him on to ground where nothing burns."},
			{"id": "might", "kind": "might", "n": "Cut the wind out from under it", "needs": [["lv", 68], ["temper", 8]], "boon": {},
				"desc": "Late Myriad Things cultivation and a sword tempered eight times: a stroke wide enough to take the wind out from under a fire with wings.",
				"line": "Lin Feng draws, and for the width of one stroke there is no wind on the mountain at all."},
		]},
	# ---- Part XVII (the Spring Thunder release): the frost that will not go home, and the lord under the soil
	"qing_nu": {"might": [2.2, 1.25],
		"why": "Qing Nu has laid the frost on the land every winter since there were winters, and taken it home every spring. This year she will not: under her snow, she says, nothing that the long year broke can hurt.",
		"paths": [
			{"id": "land", "kind": "land", "n": "The land made ready", "needs": [["cleared", 16]], "boon": {"foe_hp": 0.7, "taken": 0.85},
				"desc": "Sixteen things the long winter left in the way, cleared with your own sword: the ox whipped, the roads, the channels and the river opened. Show her the land is ready to wake, and that somebody made it ready.",
				"line": "Lin Feng tells the Maiden of Frost every road he opened, every channel, every jam of ice, and her comb goes still in her hair."},
			{"id": "relic", "kind": "relic", "n": "Gou Mang's willow switch", "needs": [["give", "willow_switch", 1]], "boon": {"foe_hp": 0.75, "weak_k": 1.9},
				"desc": "The Lord of Spring's own switch, cut from the first willow that ever came into leaf. Frost has never once won against it.",
				"line": "Lin Feng lays the willow switch on the bench of snow, and green leaves open along it one by one."},
			{"id": "craft", "kind": "craft", "n": "The Brazier of the South Wind", "needs": [["item", "warm_brazier", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Alchemist Mo can make a bronze brazier that breathes out the wet warm wind of the third month, from fire and wood essence. Frost cannot stand in front of it for long.",
				"line": "The brazier breathes out the south wind, and the cavern drips."},
			{"id": "might", "kind": "might", "n": "Melt the frost by hand", "needs": [["lv", 64], ["temper", 8]], "boon": {},
				"desc": "Early Myriad Things cultivation within reach and a sword tempered eight times: hot enough, close enough, to melt a season.",
				"line": "Lin Feng goes into the blue ice with nothing but his sword and his own warm breath."},
		]},
	"taisui": {"might": [2.3, 1.3],
		"why": "Taisui moves under the earth with the year star, and anybody who breaks the ground where he lies has broken it on his head. This spring the whole land was broken open at once, and every blow of it fell on him.",
		"paths": [
			{"id": "folk", "kind": "folk", "n": "The old way of asking", "needs": [["rallied", 5]], "boon": {"assist": 0.04, "taken": 0.85},
				"desc": "Five towns remember the old ways. Every family that remembers lights a stick of incense for Taisui at the start of the year and asks his pardon for the digging. Let them ask it now, all at once.",
				"line": "Two hundred sticks of incense go up at once from five towns, and the smoke settles over the field like an apology."},
			{"id": "craft", "kind": "craft", "n": "A charm of peace with the year", "needs": [["item", "taisui_charm", 1]], "boon": {"foe_hp": 0.7, "no_heavy": true},
				"desc": "Smith Tie can beat earth and metal essence round a thunder egg into a bronze charm with the year's Taisui engraved on it: we know you are there, it says, and we are sorry to have woken you.",
				"line": "Lin Feng holds up the charm, and a dozen of Taisui's eyes read it at once and narrow."},
			{"id": "land", "kind": "land", "n": "Every stone put right", "needs": [["cleared", 24]], "boon": {"foe_hp": 0.75, "taken": 0.9},
				"desc": "Twenty-four obstacles the long winter left, cleared with your own sword and none of it wasted: show Taisui that every blow that fell on his head was for the year and not against him.",
				"line": "Lin Feng tells Taisui of every stone and trunk and chain, and where each one went, and the lord of the year listens."},
			{"id": "respect", "kind": "respect", "n": "A name even the earth knows", "needs": [["renown", 1000]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Renown of 1000: the sweeper who swept the sky, carried the spring and said sorry for it. Even under the ground they have heard.",
				"line": "Taisui hears the name in the roots of every field in the land, and some of his eyes close."},
			{"id": "might", "kind": "might", "n": "Hold the year down", "needs": [["lv", 65], ["temper", 8]], "boon": {},
				"desc": "Middle Myriad Things cultivation and a sword tempered eight times: strength enough to hold a year in its place until it calms down.",
				"line": "Lin Feng plants his feet in the furrow and does not let the field move."},
		]},
	"lock_warden": {"might": [2.2, 1.25],
		"why": "Suo was the part of the Lotus Seal that was always a lock. For three hundred years it took Yue Ling back and made her new whenever a bearer died. It will not let her go now: in the lock, it says, she can never be lost.",
		"paths": [
			{"id": "heart", "kind": "heart", "n": "She chooses to stay", "needs": [["heart", 3]], "boon": {"assist": 0.04, "taken": 0.8},
				"desc": "Lin Feng and Yue Ling have become kindred spirits. A lock is made to keep what would otherwise be lost; nothing is lost that chooses to stay.",
				"line": "Yue Ling steps in front of Lin Feng, between him and the keyhole, and the Warden does not know what to do with somebody who will not be kept."},
			{"id": "craft", "kind": "craft", "n": "The Key of the Open Door", "needs": [["item", "open_key", 1]], "boon": {"foe_hp": 0.7, "weak_k": 1.6},
				"desc": "Smith Tie can beat two pressed petals into a bronze key with metal and dark essence: a key with no lock, that opens by leaving open. The Warden's keyhole will not know what to do with it.",
				"line": "Lin Feng turns the Key of the Open Door in the keyhole of the Warden's heart, and it opens, and stays open."},
			{"id": "respect", "kind": "respect", "n": "A name the world will not forget", "needs": [["renown", 800]], "boon": {"assist": 0.03, "taken": 0.85},
				"desc": "Stand beside her with a name the whole world remembers. The world forgets nobody who stands that close to somebody it cannot forget.",
				"line": "Lin Feng gives his name to the Warden, and hers after it, and a great many voices on the mountain say them back."},
			{"id": "might", "kind": "might", "n": "Break the lock", "needs": [["peak", 59], ["temper", 8]], "boon": {},
				"desc": "Cultivation full at Late Kindred Dao and a sword tempered eight times: strength enough to break a lock the Founder made.",
				"line": "Lin Feng goes at the Warden with nothing but his sword and the road behind him."},
		]},
	# ---- Part XIII: the heart of the formation.  Three roads to the end
	"chiyou": {"might": [2.0, 1.25],
		"why": "Chiyou, war god of the Nine Li, bronze-headed and iron-browed, who ate sand and stone and made the first weapons of metal. He fought the Yellow Emperor through a hundred days of fog. The formation that held him is breaking, and he remembers nothing but the war.",
		"paths": [
			{"id": "sword", "kind": "might", "n": "The Road of the Sword", "needs": [["dao", "", 2], ["peak", 53]], "boon": {"weak_k": 2.0, "first": true},
				"desc": "Master of the Dao you walk, and cultivation full at Late Ten Thousand Waters Return. The Road of the Sword asks nothing of the world; Chiyou meets you at his full strength, as he met the Yellow Emperor.",
				"line": "Lin Feng goes into the heart of the formation alone, as the Yellow Emperor did, with nothing but the road he has walked."},
			{"id": "peoples", "kind": "peoples", "n": "The Road of the Many Peoples", "needs": [["friends", 8], ["renown", 600]], "boon": {"assist": 0.04, "taken": 0.8},
				"desc": "Every people of the realms calls you Friend, and the whole world knows your name. Chiyou fought for the Nine Li, his own people; show him the peoples of four realms standing together without a Court to set them at each other's throats.",
				"line": "Lin Feng goes into the heart of the formation with the envoys of every people of the four realms at his back, and they are all talking at once."},
			{"id": "cauldron", "kind": "craft", "n": "The Road of the Cauldron", "needs": [["item", "homing_elixir", 1]], "boon": {"foe_hp": 0.6, "foe_atk": 0.85},
				"desc": "Alchemist Mo can refine an elixir of coming home from the five essences and an autumn leaf, for a fortune in spirit stones. Chiyou has been dead five thousand years and has never been allowed to go home.",
				"line": "Lin Feng goes into the heart of the formation with the elixir of coming home warm in his hands, and the war god smells the fields of the Nine Li on it."},
		]},
}

# ---------------------------------------------------------------- requirements
static func need_met(n: Array, g, paid: bool = false) -> bool:
	match str(n[0]):
		"lv":
			return g.level >= int(n[1])
		"peak":
			return g.level > int(n[1]) or (g.level == int(n[1]) and g.exp >= g.exp_need() - 0.5)
		"temper":
			return g.temper >= int(n[1])
		"ranks":
			return g.talent_ranks() >= int(n[1])
		"item":
			return int(g.inv.get(str(n[1]), 0)) >= int(n[2])
		"give":
			return paid or int(g.inv.get(str(n[1]), 0)) >= int(n[2])
		"stones":
			return paid or g.stones >= int(n[1])
		"renown":
			return g.renown >= int(n[1])
		"dao":
			if g.dao == "" or (str(n[1]) != "" and g.dao != str(n[1])):
				return false
			return g.dao_tier() >= int(n[2])
		"standing":
			return int(g.standing.get(str(n[1]), 0)) >= int(n[2])
		"friends":
			return friends(g) >= int(n[1])
		"gates":
			return g.gates_open.size() >= int(n[1])
		"fate":
			return str(g.fates.get(str(n[1]), "")) in n[2]
		"bonds":
			return Fate.allies(g) >= int(n[1])
		"heart":
			# the Lotus release: how close Lin Feng and Yue Ling have come (bonds.gd)
			return Bonds.level(g) >= int(n[1])
		"rallied":
			# the Living Land release: the towns reminded of the old ways (Part XVI)
			return g.rallied.size() >= int(n[1])
		"cleared":
			# the Spring Thunder release: the obstacles of the story cleared with the sword (impact.gd)
			return g.cleared.size() >= int(n[1])
		"hearths":
			# the New Fire release: the hearths of the land that call the hero a guest (cultures.gd)
			return Cultures.guests(g) >= int(n[1])
		"works":
			# the Hundred Works release: works built (works.gd), of any school (""), of one, or of the
			# school most built ("best")
			return works_n(g, str(n[1])) >= int(n[2])
		"delved":
			# the Hollow Hills release: caves gone to the very back of (caves.gd)
			return g.delved.size() >= int(n[1])
		"arms":
			# the Hundred Arms release: Daos of arms learned to Adept (arms.gd)
			return Arms.adept(g) >= int(n[1])
		"summits":
			# the High Roads release: summits stood on (peaks.gd)
			return g.summits.size() >= int(n[1])
		"companies":
			# the Thundering Pots release: companies in the host (war.gd)
			return War.companies(g).size() >= int(n[1])
		"airs":
			# the airs of the hearths learned (music.gd)
			return g.airs.size() >= int(n[1])
		"falls":
			# the Lost Horse release: battles that could not be won, lost and gone on from (dooms.gd)
			return g.fallen >= int(n[1])
		"marks":
			# what the choices left standing, looked at (marks.gd)
			return g.marks_seen.size() >= int(n[1])
	return false

## How many works count towards a ["works", school, n] need.
static func works_n(g, school: String) -> int:
	if school == "best":
		return Works.count(g, Works.leading(g)) if Works.leading(g) != "" else 0
	return Works.count(g, school)

## How many peoples of the realms call Lin Feng friend (or kin).
static func friends(g) -> int:
	var k := 0
	for race in g.standing:
		if race != "human" and g.race_tier(race) >= 1:
			k += 1
	return k

static func need_text(n: Array, g) -> String:
	match str(n[0]):
		"lv":
			return "Cultivation of %s (you: %s)" % [Data.level_name(int(n[1])), Data.level_name(g.level)]
		"peak":
			return "Cultivation full at %s, ready to break through" % Data.level_name(int(n[1]))
		"temper":
			return "A sword tempered %d times at Smith Tie's forge (yours: %d)" % [int(n[1]), g.temper]
		"ranks":
			return "%d ranks of the Nine Heavens root awake (yours: %d)" % [int(n[1]), g.talent_ranks()]
		"item", "give":
			var id: String = str(n[1])
			var s := "%s x%d" % [Data.ITEMS[id].n, int(n[2])]
			if RECIPES.has(id):
				s += ", made at " + str(STATIONS[RECIPES[id].at])
			s += ", given up" if str(n[0]) == "give" else ""
			return s + " (you have %d)" % int(g.inv.get(id, 0))
		"stones":
			return "%s spirit stones, paid (you have %s)" % [_num(int(n[1])), _num(g.stones)]
		"renown":
			return "Renown %d, %s (yours: %d)" % [int(n[1]), renown_title(int(n[1])), g.renown]
		"dao":
			var rank: String = str(Data.DAO_RANKS[int(n[2])])
			if str(n[1]) == "":
				return "%s of the Dao you walk" % rank
			return "Walk the %s%s" % [Data.DAOS[str(n[1])].n, (" as %s or better" % rank) if int(n[2]) > 0 else ""]
		"standing":
			var title := "Kin" if int(n[2]) >= Data.KIN else "Friend"
			# (a people whose name already begins with "The": the Thousand Children, the Immortals; as
			# Game.the_race writes it)
			var rn: String = str(Data.RACES[str(n[1])].n)
			return "%s call you %s (standing %d of %d)" % [rn if rn.begins_with("The ") else "The " + rn, title, int(g.standing.get(str(n[1]), 0)), int(n[2])]
		"friends":
			return "%d peoples of the realms call you Friend (now %d)" % [int(n[1]), friends(g)]
		"gates":
			return "%d of the Eight Gates open (now %d)" % [int(n[1]), g.gates_open.size()]
		"fate":
			var th: String = str(n[1])
			var names: Array = []
			for stn in n[2]:
				names.append(str(Fate.state_text(th, str(stn))[0]).to_lower())
			return "%s: %s (now: %s)" % [str(Fate.THREADS[th].n).get_slice(",", 0), " or ".join(names), str(Fate.state_text(th, str(g.fates.get(th, "")))[0]).to_lower()]
		"bonds":
			return "%d of the five you met on the road stand with you (now %d)" % [int(n[1]), Fate.allies(g)]
		"heart":
			return "You and Yue Ling: %s at least (now %s)" % [Bonds.TITLES[int(n[1])], Bonds.title(g)]
		"rallied":
			return "%d towns reminded of the old ways: red, fire and noise (now %d)" % [int(n[1]), g.rallied.size()]
		"cleared":
			return "%d things the long winter left in the way cleared with your sword (now %d)" % [int(n[1]), g.cleared.size()]
		"hearths":
			return "%d hearths of the land that call you a guest (now %d; Esc > Hearths)" % [int(n[1]), Cultures.guests(g)]
		"works":
			var what := "works built" if str(n[1]) == "" else ("works of one school" if str(n[1]) == "best" else "works of %s" % str(Works.SCHOOLS[n[1]].n))
			return "%d %s with your own hands (now %d; Esc > Works)" % [int(n[2]), what, works_n(g, str(n[1]))]
		"delved":
			return "%d caves gone to the very back of (now %d; a cave mouth stands in almost every region)" % [int(n[1]), g.delved.size()]
		"arms":
			return "%d Daos of arms learned to Adept (now %d: win battles with a weapon in hand; Esc > Arms)" % [int(n[1]), Arms.adept(g)]
		"summits":
			return "%d summits stood on (now %d; every region has peaks, marked on the map)" % [int(n[1]), g.summits.size()]
		"companies":
			return "%d companies in the host (now %d: the levy of the hearths, the works, the notice board; Esc > The Host)" % [int(n[1]), War.companies(g).size()]
		"airs":
			return "%d airs of the hearths learned (now %d: somebody at each hearth still sings its own)" % [int(n[1]), g.airs.size()]
		"falls":
			return "%d battles that could not be won, lost and gone on from (now %d)" % [int(n[1]), g.fallen]
		"marks":
			return "%d things your choices left standing, gone and looked at (now %d: Esc > Crossroads says where each stands)" % [int(n[1]), g.marks_seen.size()]
	return str(n)

## Whether path `p` of trial `tid` can be taken now (what it costs is counted as paid if it was).
static func path_met(tid: String, p: Dictionary, g) -> bool:
	var paid: bool = str(g.paid.get(tid, "")) == str(p.id)
	for n in p.needs:
		if not need_met(n, g, paid):
			return false
	return true

static func path(tid: String, pid: String) -> Dictionary:
	for p in TRIALS.get(tid, {}).get("paths", []):
		if str(p.id) == pid:
			return p
	return {}

## The paths of a trial that can be taken now.
static func open_paths(tid: String, g) -> Array:
	var out: Array = []
	for p in TRIALS.get(tid, {}).get("paths", []):
		if path_met(tid, p, g):
			out.append(p)
	return out

## What taking path `p` costs, paid now (stones and things given up).  Once.
static func pay(tid: String, p: Dictionary, g) -> void:
	if str(g.paid.get(tid, "")) == str(p.id):
		return
	for n in p.needs:
		match str(n[0]):
			"give":
				g.inv[str(n[1])] = int(g.inv.get(str(n[1]), 0)) - int(n[2])
			"stones":
				g.stones -= int(n[1])
	g.paid[tid] = str(p.id)

## A path's boon in words.
static func boon_text(b: Dictionary) -> String:
	var parts: Array = []
	if b.has("foe_hp"):
		parts.append("it begins at %d%% of its strength" % int(round(float(b.foe_hp) * 100.0)))
	if b.has("foe_atk"):
		parts.append("its blows land at %d%%" % int(round(float(b.foe_atk) * 100.0)))
	if b.has("taken"):
		parts.append("the party takes %d%% less harm" % int(round((1.0 - float(b.taken)) * 100.0)))
	if b.has("assist"):
		# (2.5% is not 2%: a half per cent is shown)
		var ap := float(b.assist) * 100.0
		parts.append("allies strike it for %s%% of its health every round" % (str(int(round(ap))) if is_equal_approx(ap, round(ap)) else "%.1f" % ap))
	if b.has("weak_k"):
		parts.append("its weakness cuts deeper (x%.1f)" % float(b.weak_k))
	if b.get("no_heavy", false):
		parts.append("its devastating blows are blunted")
	if b.get("first", false):
		parts.append("you strike first")
	if parts.is_empty():
		return "In battle: no help but your own."
	return "In battle: " + ", ".join(parts) + "."

## A whole path, for the choice screen and the Journal: what it is, what it needs (each requirement
## ticked or not) and what it does in battle.
static func path_desc(tid: String, p: Dictionary, g) -> String:
	var paid: bool = str(g.paid.get(tid, "")) == str(p.id)
	var lines: Array = [str(p.desc), ""]
	for n in p.needs:
		lines.append(("[x] " if need_met(n, g, paid) else "[ ] ") + need_text(n, g))
	if paid:
		lines.append("(already paid)")
	lines.append("")
	lines.append(boon_text(p.boon))
	return "\n".join(lines)

## The trial in front of the current quest step, if there is one ("" otherwise): a boss's.
static func trial_of_step(s: Dictionary) -> String:
	if s.is_empty() or str(s.get("kind", "")) != "kill":
		return ""
	return str(s.boss) if TRIALS.has(str(s.boss)) else ""

## The road Lin Feng has walked most often through the trials (an epithet for the ending).
static func favourite_kind(g) -> String:
	var counts := {}
	for tid in g.trials:
		var p := path(str(tid), str(g.trials[tid]))
		if p.is_empty():
			continue
		counts[p.kind] = int(counts.get(p.kind, 0)) + 1
	var best := ""
	var bn := 0
	for k in KIND_ORDER:
		if int(counts.get(k, 0)) > bn:
			bn = int(counts[k])
			best = k
	return best

const EPITHETS := {"might": "the Unbending Sword", "craft": "Master of Cauldron and Forge", "wealth": "the Open Hand", "respect": "Whom the World Respects",
	"dao": "Walker of Many Roads", "peoples": "Friend of the Four Realms", "relic": "Keeper of Old Things", "bond": "Who Kept Faith",
	# (the roads added since had none, and the ending's title read a key that was not there: a player who
	# went through most trials side by side or by the people had a script error for a title)
	"heart": "Who Never Walked Alone", "folk": "Whom the Towns Remember", "land": "Who Opened the Land", "hearth": "Guest of Every Fire",
	"works": "Whose Hands Made It", "delve": "Who Went to the Back of the Cave", "arms": "Whose Hand Is Open",
	"heights": "Who Stood on the Tops", "host": "Whom They Came For", "song": "Who Sang Them Home",
	"loss": "Who Lost and Went On", "mark": "Whose Word Stayed Where It Was Put"}

static func _num(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
