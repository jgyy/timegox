class_name Data
extends RefCounted
## Static game content: realms, skills, enemies, areas, quest chain and dialogue.

const MAX_LEVEL := 12
const REALMS := ["Qi Condensation", "Foundation Establishment", "Golden Core", "Nascent Soul", "Deity Transformation"]
const STAGES := ["Early", "Middle", "Late"]
const EXP_NEED := [124, 228, 352, 538, 787, 1076, 1490, 1987, 2588, 3416, 4450, 5692]
const ENEMY_EXP := [4, 8, 12, 19, 28, 39, 54, 72, 93, 123, 161, 206]
const ELEM_COLORS := {
	"phys": Color("d8d8e0"), "fire": Color("ff7a45"), "water": Color("5aa9ff"),
	"wood": Color("6fe08a"), "earth": Color("d9a35a"), "thunder": Color("f6e85c"), "dark": Color("b06cff"),
}

static func level_name(l: int) -> String:
	return "%s %s" % [STAGES[l % 3], REALMS[int(l / 3)]]

static func realm_cap(l: int) -> bool:
	return l % 3 == 2 and l < MAX_LEVEL

# ---------------------------------------------------------------- skills
# tgt: one | all | ally | allies
const SKILLS := {
	"strike": {"n": "Sword Strike", "cost": 0, "mult": 1.0, "elem": "phys", "tgt": "one", "lv": 0, "who": 0},
	"azure": {"n": "Azure Wind Slash", "cost": 7, "mult": 1.6, "elem": "wood", "tgt": "one", "lv": 0, "who": 0},
	"flame": {"n": "Crimson Flame Palm", "cost": 12, "mult": 1.25, "elem": "fire", "tgt": "all", "lv": 1, "who": 0},
	"frost": {"n": "Frost Lotus Blade", "cost": 14, "mult": 2.1, "elem": "water", "tgt": "one", "lv": 3, "who": 0},
	"thunder": {"n": "Nine Heavens Thunder", "cost": 22, "mult": 2.8, "elem": "thunder", "tgt": "one", "lv": 6, "who": 0},
	"quake": {"n": "Mountain Quake", "cost": 26, "mult": 1.7, "elem": "earth", "tgt": "all", "lv": 8, "who": 0},
	"heaven": {"n": "Heaven-Cleaving Sword", "cost": 45, "mult": 4.2, "elem": "phys", "tgt": "one", "lv": 10, "who": 0},
	"needle": {"n": "Jade Needle", "cost": 0, "mult": 1.0, "elem": "wood", "tgt": "one", "lv": 0, "who": 1},
	"rain": {"n": "Spring Rain", "cost": 16, "heal": 0.35, "elem": "water", "tgt": "allies", "lv": 0, "who": 1},
	"lotus_burst": {"n": "Lotus Burst", "cost": 22, "mult": 1.4, "elem": "water", "tgt": "all", "lv": 4, "who": 1},
}

static func known_skills(who: int, level: int) -> Array:
	var out := []
	for id in SKILLS:
		var s = SKILLS[id]
		if s.who == who and s.lv <= level:
			out.append(id)
	return out

# ---------------------------------------------------------------- stats
static func max_hp(level: int) -> int:
	return 80 + 45 * level

static func max_qi(level: int) -> int:
	return 40 + 18 * level

static func atk(level: int) -> int:
	return 12 + 7 * level

static func defense(level: int) -> int:
	return 4 + 3 * level

static func speed(level: int) -> int:
	return 10 + level

# ---------------------------------------------------------------- enemies
# shape: beast humanoid wisp blob wraith plant dragon bird demon storm
const ENEMIES := {
	"bamboo_wolf": {"n": "Bamboo Wolf", "elem": "wood", "weak": "fire", "col": Color("7aa860"), "shape": "beast"},
	"bandit": {"n": "Mountain Bandit", "elem": "phys", "weak": "water", "col": Color("a8825a"), "shape": "humanoid"},
	"leaf_sprite": {"n": "Leaf Sprite", "elem": "wood", "weak": "fire", "col": Color("9be07a"), "shape": "wisp"},
	"mire_toad": {"n": "Mire Toad", "elem": "water", "weak": "fire", "col": Color("5f8f4a"), "shape": "blob"},
	"bog_wraith": {"n": "Bog Wraith", "elem": "dark", "weak": "water", "col": Color("6a5a8a"), "shape": "wraith"},
	"poison_vine": {"n": "Poison Vine", "elem": "wood", "weak": "fire", "col": Color("8f4fa8"), "shape": "plant"},
	"frost_wolf": {"n": "Frost Wolf", "elem": "water", "weak": "fire", "col": Color("a8d8f0"), "shape": "beast"},
	"ice_golem": {"n": "Ice Golem", "elem": "water", "weak": "thunder", "col": Color("7fb8e8"), "shape": "blob"},
	"snow_wraith": {"n": "Snow Wraith", "elem": "water", "weak": "fire", "col": Color("d8ecff"), "shape": "wraith"},
	"storm_hawk": {"n": "Storm Hawk", "elem": "thunder", "weak": "earth", "col": Color("e8d85a"), "shape": "bird"},
	"thunder_ape": {"n": "Thunder Ape", "elem": "thunder", "weak": "earth", "col": Color("9a7ad8"), "shape": "beast"},
	"spark_wisp": {"n": "Spark Wisp", "elem": "thunder", "weak": "water", "col": Color("fff08a"), "shape": "wisp"},
	"blood_acolyte": {"n": "Blood Acolyte", "elem": "dark", "weak": "water", "col": Color("b03a4a"), "shape": "humanoid"},
	"bone_soldier": {"n": "Bone Soldier", "elem": "dark", "weak": "thunder", "col": Color("d8d0b8"), "shape": "humanoid"},
	"shadow_fiend": {"n": "Shadow Fiend", "elem": "dark", "weak": "fire", "col": Color("5a3a8a"), "shape": "wraith"},
	# bosses
	"iron_fang": {"n": "Iron Fang", "elem": "phys", "weak": "water", "col": Color("c0603a"), "shape": "humanoid", "boss": true},
	"bamboo_spirit": {"n": "Ancient Bamboo Spirit", "elem": "wood", "weak": "fire", "col": Color("4fc07a"), "shape": "plant", "boss": true},
	"marsh_hag": {"n": "Marsh Hag", "elem": "dark", "weak": "fire", "col": Color("7a4a8f"), "shape": "wraith", "boss": true},
	"frost_wyrm": {"n": "Frost Wyrm", "elem": "water", "weak": "thunder", "col": Color("8fd0ff"), "shape": "dragon", "boss": true},
	"thunder_roc": {"n": "Thunder Roc", "elem": "thunder", "weak": "earth", "col": Color("ffe05a"), "shape": "bird", "boss": true},
	"jade_mantis": {"n": "Jade Mantis Matriarch", "elem": "wood", "weak": "fire", "col": Color("5fd890"), "shape": "beast", "boss": true},
	"bog_colossus": {"n": "Bog Colossus", "elem": "water", "weak": "fire", "col": Color("6a7a3a"), "shape": "blob", "boss": true},
	"ice_empress": {"n": "Ice Empress", "elem": "water", "weak": "fire", "col": Color("c8e8ff"), "shape": "wraith", "boss": true},
	"storm_ape_king": {"n": "Storm Ape King", "elem": "thunder", "weak": "earth", "col": Color("b08aff"), "shape": "beast", "boss": true},
	"blood_hound": {"n": "Crimson Hellhound", "elem": "dark", "weak": "water", "col": Color("d03040"), "shape": "beast", "boss": true},
	"general_blood": {"n": "General Xue Sha", "elem": "dark", "weak": "water", "col": Color("c02840"), "shape": "demon", "boss": true},
	"general_shadow": {"n": "General Mo Ying", "elem": "dark", "weak": "fire", "col": Color("6a3aa8"), "shape": "demon", "boss": true},
	"demon_lord": {"n": "Demon Lord Xu Mo", "elem": "dark", "weak": "thunder", "col": Color("e02050"), "shape": "demon", "boss": true},
	"tribulation": {"n": "Heavenly Tribulation", "elem": "thunder", "weak": "none", "col": Color("c8d8ff"), "shape": "storm", "boss": true},
}

static func make_enemy(id: String, lv: int, boss_mult: float = 1.0) -> Dictionary:
	var d: Dictionary = ENEMIES[id]
	var boss: bool = d.get("boss", false)
	var hp := 60 + 48 * lv
	var a := 7.0 + 4.3 * lv
	var df := 2.0 + 2.6 * lv
	if boss:
		hp = int(hp * 6.0 * boss_mult)
		a *= 1.3
		df *= 1.1
	return {
		"id": id, "name": d.n, "side": "foe", "lv": lv, "boss": boss,
		"hp": hp, "maxhp": hp, "qi": 0, "maxqi": 0, "atk": a, "def": df,
		"spd": 8 + lv, "elem": d.elem, "weak": d.weak, "col": d.col, "shape": d.shape,
		"skills": [], "turns": 0, "flash": 0.0, "shake": 0.0, "dead": false, "fade": 1.0,
	}

static func enemy_exp(lv: int, boss: bool) -> int:
	var base: int = ENEMY_EXP[mini(lv, 11)]
	return base * (4 if boss else 1)

static func enemy_stones(lv: int, boss: bool) -> int:
	return (5 + 3 * lv) * (6 if boss else 1)

# ---------------------------------------------------------------- areas
# `vis` = [from_step_id, until_step_id] (either may be ""): visible when quest reached `from`
# and has not yet completed `until`.  `open` = step id that must be completed for a portal to work.
const AREAS := {
	"sect": {
		"n": "Azure Cloud Sect", "w": 40, "h": 26, "seed": 11, "theme": "sect", "enemies": 0,
		"portals": [{"to": "bamboo", "pos": Vector2i(38, 13), "dest": Vector2i(4, 22), "open": ""}],
		"npcs": [
			{"id": "elder", "n": "Elder Qing Xuan", "pos": Vector2i(20, 5), "col": Color("e8e8ff")},
			{"id": "alchemist", "n": "Alchemist Mo", "pos": Vector2i(8, 15), "col": Color("6fc08a")},
			{"id": "smith", "n": "Smith Tie", "pos": Vector2i(31, 15), "col": Color("d08a5a")},
		],
		"springs": [Vector2i(20, 13)],
	},
	"bamboo": {
		"n": "Whispering Bamboo Forest", "w": 70, "h": 44, "seed": 21, "theme": "bamboo", "enemies": 13,
		"pool": [["bamboo_wolf", 0, 1], ["bandit", 1, 2], ["leaf_sprite", 0, 2]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 22), "dest": Vector2i(36, 13), "open": ""},
			{"to": "marsh", "pos": Vector2i(68, 22), "dest": Vector2i(4, 24), "open": "s_elder2"},
		],
		"npcs": [{"id": "yue_ling", "n": "Yue Ling", "pos": Vector2i(43, 12), "col": Color("f08ab0"), "vis": ["s_ironfang", "s_yue"]}],
		"bosses": [
			{"id": "jade_mantis", "pos": Vector2i(32, 30), "lv": 1, "req": 1},
			{"id": "iron_fang", "pos": Vector2i(44, 12), "lv": 1, "req": 1},
			{"id": "bamboo_spirit", "pos": Vector2i(60, 34), "lv": 2, "req": 2},
		],
		"pickups": [
			{"id": "herb1", "item": "herb", "pos": Vector2i(15, 8)}, {"id": "herb2", "item": "herb", "pos": Vector2i(30, 36)},
			{"id": "herb3", "item": "herb", "pos": Vector2i(52, 16)}, {"id": "herb4", "item": "herb", "pos": Vector2i(62, 8)},
		],
		"pickup_vis": "s_herbs",
	},
	"marsh": {
		"n": "Crimson Marsh", "w": 80, "h": 48, "seed": 31, "theme": "marsh", "enemies": 14,
		"pool": [["mire_toad", 3, 4], ["bog_wraith", 4, 5], ["poison_vine", 3, 5]],
		"portals": [
			{"to": "bamboo", "pos": Vector2i(1, 24), "dest": Vector2i(66, 22), "open": ""},
			{"to": "frost", "pos": Vector2i(78, 24), "dest": Vector2i(4, 25), "open": "s_elder3"},
		],
		"bosses": [
			{"id": "bog_colossus", "pos": Vector2i(40, 28), "lv": 4, "req": 4},{"id": "marsh_hag", "pos": Vector2i(66, 10), "lv": 5, "req": 5}],
		"pickups": [
			{"id": "lotus1", "item": "lotus", "pos": Vector2i(20, 38)}, {"id": "lotus2", "item": "lotus", "pos": Vector2i(38, 8)},
			{"id": "lotus3", "item": "lotus", "pos": Vector2i(54, 40)}, {"id": "lotus4", "item": "lotus", "pos": Vector2i(70, 30)},
		],
		"pickup_vis": "s_lotus",
	},
	"frost": {
		"n": "Frostpeak Caverns", "w": 80, "h": 50, "seed": 41, "theme": "frost", "enemies": 14,
		"pool": [["frost_wolf", 6, 7], ["ice_golem", 7, 8], ["snow_wraith", 6, 8]],
		"portals": [
			{"to": "marsh", "pos": Vector2i(1, 25), "dest": Vector2i(74, 24), "open": ""},
			{"to": "thunder", "pos": Vector2i(78, 25), "dest": Vector2i(4, 25), "open": "s_elder4"},
		],
		"bosses": [
			{"id": "ice_empress", "pos": Vector2i(36, 22), "lv": 7, "req": 7},{"id": "frost_wyrm", "pos": Vector2i(66, 40), "lv": 8, "req": 8}],
		"pickups": [
			{"id": "jade1", "item": "jade", "pos": Vector2i(18, 10)}, {"id": "jade2", "item": "jade", "pos": Vector2i(34, 42)},
			{"id": "jade3", "item": "jade", "pos": Vector2i(52, 8)}, {"id": "jade4", "item": "jade", "pos": Vector2i(70, 16)},
		],
		"pickup_vis": "s_jade",
	},
	"thunder": {
		"n": "Thunder Valley", "w": 90, "h": 50, "seed": 51, "theme": "thunder", "enemies": 15,
		"pool": [["storm_hawk", 9, 10], ["thunder_ape", 10, 11], ["spark_wisp", 9, 11]],
		"portals": [
			{"to": "frost", "pos": Vector2i(1, 25), "dest": Vector2i(74, 25), "open": ""},
			{"to": "palace", "pos": Vector2i(88, 25), "dest": Vector2i(4, 28), "open": "s_elder5"},
		],
		"npcs": [{"id": "sword_ghost", "n": "Ancestor Jian Wuchen", "pos": Vector2i(14, 10), "col": Color("9ad8ff"), "vis": ["s_swordghost", ""]}],
		"bosses": [
			{"id": "storm_ape_king", "pos": Vector2i(60, 12), "lv": 10, "req": 10},{"id": "thunder_roc", "pos": Vector2i(78, 25), "lv": 11, "req": 11}],
		"pickups": [
			{"id": "shard1", "item": "shard", "pos": Vector2i(30, 40)}, {"id": "shard2", "item": "shard", "pos": Vector2i(48, 10)},
			{"id": "shard3", "item": "shard", "pos": Vector2i(64, 38)}, {"id": "shard4", "item": "shard", "pos": Vector2i(40, 24)},
		],
		"pickup_vis": "s_shards",
	},
	"palace": {
		"n": "Blood Moon Palace", "w": 90, "h": 56, "seed": 61, "theme": "palace", "enemies": 16,
		"pool": [["blood_acolyte", 11, 11], ["bone_soldier", 11, 11], ["shadow_fiend", 11, 11]],
		"portals": [{"to": "thunder", "pos": Vector2i(1, 28), "dest": Vector2i(84, 25), "open": ""}],
		"bosses": [
			{"id": "blood_hound", "pos": Vector2i(48, 22), "lv": 11, "req": 11},
			{"id": "general_blood", "pos": Vector2i(32, 12), "lv": 11, "req": 11},
			{"id": "general_shadow", "pos": Vector2i(56, 44), "lv": 11, "req": 11},
			{"id": "demon_lord", "pos": Vector2i(80, 28), "lv": 12, "req": 11},
		],
	},
}

const AREA_CHAIN := ["sect", "bamboo", "marsh", "frost", "thunder", "palace"]

# ---------------------------------------------------------------- quest chain
# kind: talk (npc) | level (lv) | collect (item,n) | kill (boss) | breakthrough
const STEPS := [
	{"id": "s_intro", "kind": "talk", "npc": "elder", "area": "sect", "t": "Speak to Elder Qing Xuan"},
	{"id": "s_meditate", "kind": "level", "lv": 1, "t": "Cultivate to Middle Qi Condensation (Esc > Meditate)"},
	{"id": "s_report1", "kind": "talk", "npc": "elder", "area": "sect", "t": "Report your progress to the Elder", "stones": 120},
	{"id": "s_herbs", "kind": "collect", "item": "herb", "n": 4, "area": "bamboo", "t": "Gather 4 Spirit Herbs in the Bamboo Forest"},
	{"id": "s_alchemist", "kind": "talk", "npc": "alchemist", "area": "sect", "t": "Deliver the herbs to Alchemist Mo", "stones": 150},
	{"id": "s_hunt1", "kind": "hunt", "area": "bamboo", "n": 14, "t": "Cull the beasts and bandits of the Bamboo Forest"},
	{"id": "s_mantis", "kind": "kill", "boss": "jade_mantis", "area": "bamboo", "t": "Hunt the Jade Mantis Matriarch"},
	{"id": "s_ironfang", "kind": "kill", "boss": "iron_fang", "area": "bamboo", "t": "Defeat the bandit chief Iron Fang"},
	{"id": "s_yue", "kind": "talk", "npc": "yue_ling", "area": "bamboo", "t": "Speak to the captive girl"},
	{"id": "s_spirit", "kind": "kill", "boss": "bamboo_spirit", "area": "bamboo", "t": "Calm the Ancient Bamboo Spirit"},
	{"id": "s_break1", "kind": "breakthrough", "to": 3, "t": "Break through to Foundation Establishment (Esc > Breakthrough)"},
	{"id": "s_elder2", "kind": "talk", "npc": "elder", "area": "sect", "t": "Tell the Elder of your breakthrough", "stones": 200},
	{"id": "s_lotus", "kind": "collect", "item": "lotus", "n": 4, "area": "marsh", "t": "Pluck 4 Blood Lotuses in the Crimson Marsh"},
	{"id": "s_hunt2", "kind": "hunt", "area": "marsh", "n": 16, "t": "Purge the marsh of its toxic denizens"},
	{"id": "s_colossus", "kind": "kill", "boss": "bog_colossus", "area": "marsh", "t": "Topple the Bog Colossus"},
	{"id": "s_hag", "kind": "kill", "boss": "marsh_hag", "area": "marsh", "t": "Slay the Marsh Hag"},
	{"id": "s_antidote", "kind": "talk", "npc": "alchemist", "area": "sect", "t": "Bring the lotuses to Alchemist Mo", "stones": 300},
	{"id": "s_break2", "kind": "breakthrough", "to": 6, "t": "Break through to Golden Core"},
	{"id": "s_elder3", "kind": "talk", "npc": "elder", "area": "sect", "t": "Seek the Elder's counsel", "stones": 300},
	{"id": "s_jade", "kind": "collect", "item": "jade", "n": 4, "area": "frost", "t": "Recover 4 Frost Jades in Frostpeak Caverns"},
	{"id": "s_hunt3", "kind": "hunt", "area": "frost", "n": 16, "t": "Drive back the frost beasts"},
	{"id": "s_empress", "kind": "kill", "boss": "ice_empress", "area": "frost", "t": "Challenge the Ice Empress"},
	{"id": "s_wyrm", "kind": "kill", "boss": "frost_wyrm", "area": "frost", "t": "Slay the Frost Wyrm"},
	{"id": "s_break3", "kind": "breakthrough", "to": 9, "t": "Break through to Nascent Soul"},
	{"id": "s_elder4", "kind": "talk", "npc": "elder", "area": "sect", "t": "Present the Frost Jades to the Elder", "stones": 400},
	{"id": "s_swordghost", "kind": "talk", "npc": "sword_ghost", "area": "thunder", "t": "Seek the sword ancestor in Thunder Valley"},
	{"id": "s_shards", "kind": "collect", "item": "shard", "n": 4, "area": "thunder", "t": "Gather 4 Thunder Shards"},
	{"id": "s_hunt4", "kind": "hunt", "area": "thunder", "n": 16, "t": "Thin the storm creatures of Thunder Valley"},
	{"id": "s_apeking", "kind": "kill", "boss": "storm_ape_king", "area": "thunder", "t": "Subdue the Storm Ape King"},
	{"id": "s_roc", "kind": "kill", "boss": "thunder_roc", "area": "thunder", "t": "Slay the Thunder Roc"},
	{"id": "s_elder5", "kind": "talk", "npc": "elder", "area": "sect", "t": "Return to the Elder with the Roc's feather", "stones": 500},
	{"id": "s_hunt5", "kind": "hunt", "area": "palace", "n": 18, "t": "Cut down the demon vanguard of the Blood Moon Palace"},
	{"id": "s_hound", "kind": "kill", "boss": "blood_hound", "area": "palace", "t": "Slay the Crimson Hellhound"},
	{"id": "s_gen1", "kind": "kill", "boss": "general_blood", "area": "palace", "t": "Defeat General Xue Sha"},
	{"id": "s_gen2", "kind": "kill", "boss": "general_shadow", "area": "palace", "t": "Defeat General Mo Ying"},
	{"id": "s_lord", "kind": "kill", "boss": "demon_lord", "area": "palace", "t": "Defeat Demon Lord Xu Mo"},
	{"id": "s_break4", "kind": "breakthrough", "to": 12, "t": "Endure the Ascension Tribulation"},
]

static func step_index(id: String) -> int:
	for i in STEPS.size():
		if STEPS[i].id == id:
			return i
	return -1

# ---------------------------------------------------------------- items & shop
const ITEMS := {
	"hp_pill": {"n": "Healing Pill", "desc": "Restores 40% HP"},
	"qi_pill": {"n": "Spirit Qi Pill", "desc": "Restores 50% Qi"},
	"herb": {"n": "Spirit Herb", "desc": "Quest item"},
	"lotus": {"n": "Blood Lotus", "desc": "Quest item"},
	"jade": {"n": "Frost Jade", "desc": "Quest item"},
	"shard": {"n": "Thunder Shard", "desc": "Quest item"},
}
const TEMPER_COST := [250, 700, 1500, 2800, 4500]

static func pill_price(kind: String, level: int) -> int:
	return (24 + 5 * level) if kind == "hp_pill" else (20 + 4 * level)

# ---------------------------------------------------------------- dialogue
const CHAT := {
	"elder": ["The mountain wind carries the scent of blood. Stay vigilant.", "Cultivation is a marathon, disciple, not a sprint."],
	"alchemist": ["Pills are only borrowed time. Use them wisely.", "Hehe, my furnace never lies."],
	"smith": ["Steel remembers every blow. Bring me stones and I will temper your sword.", "A sword is only as sharp as its wielder's resolve."],
	"yue_ling": ["Let us go, Lin Feng.", "I will keep your wounds in check."],
	"sword_ghost": ["Thunder answers those who do not flinch."],
}

const DIALOGUE := {
	"s_intro": [
		["Elder Qing Xuan", "Lin Feng. Three years you have swept the steps of Azure Cloud Sect, and three years your qi has refused to stir."],
		["Lin Feng", "Elder, I have tried every method in the scriptures."],
		["Elder Qing Xuan", "The Heavenly Lotus Seal that guards our mountain is failing. Xu Mo, Lord of the Blood Moon Palace, is coming for it."],
		["Elder Qing Xuan", "I sense something sleeping in your dantian. A root of the Nine Heavens, or a curse. Either way, the sect needs strength."],
		["Elder Qing Xuan", "Press Esc, choose Meditate, and let the spirit spring guide your breathing. Reach the Middle stage and return to me."],
		["Lin Feng", "I will not waste this chance."],
	],
	"s_report1": [
		["Elder Qing Xuan", "Your qi flows like a mountain stream at last. Splendid."],
		["Elder Qing Xuan", "Alchemist Mo requires four Spirit Herbs from the Whispering Bamboo Forest, east of the gate."],
		["Elder Qing Xuan", "Bandits stalk that road. Meditate to recover, buy pills from Mo, and temper your blade with Smith Tie."],
		["Lin Feng", "Understood. I will return with the herbs."],
	],
	"s_alchemist": [
		["Alchemist Mo", "Spirit Herbs! Four of them, fresh as dawn. You have the nose of a true cultivator."],
		["Alchemist Mo", "Take these pills. And hear this: the bandit chief Iron Fang holds a village girl in the deep bamboo."],
		["Lin Feng", "Then I shall free her."],
	],
	"pre:jade_mantis": [
		["Jade Mantis Matriarch", "Intruder in my grove. My scythes have not tasted a cultivator in a decade."],
	],
	"post:jade_mantis": [
		["Lin Feng", "That was close. The forest is quieter already."],
	],
	"pre:bog_colossus": [
		["Bog Colossus", "GRRRRRM. Mud. Hunger. Mud."],
		["Lin Feng", "It is a puppet of poison qi. Burn it down."],
	],
	"post:bog_colossus": [
		["Yue Ling", "The marsh spirits are settling. The Hag's seat is within reach."],
	],
	"pre:ice_empress": [
		["Ice Empress", "Mortals who track warmth into my palace deserve the longest winter."],
	],
	"post:ice_empress": [
		["Ice Empress", "Winter... ends... but the moon... stays red..."],
	],
	"pre:storm_ape_king": [
		["Storm Ape King", "Ooooh! A tiny sword! Let me bend it like a reed!"],
	],
	"post:storm_ape_king": [
		["Lin Feng", "The valley winds are calming. The Roc's perch lies ahead."],
	],
	"pre:blood_hound": [
		["Narrator", "A hound the size of a barn rises from a pool of blood, its three heads snarling in unison."],
		["Yue Ling", "Cerberus-kin! Watch its breath, Lin Feng!"],
	],
	"post:blood_hound": [
		["Yue Ling", "The path to the generals is open."],
	],
	"pre:iron_fang": [
		["Iron Fang", "Hah! A sweeper boy with a sword. Did the Azure Cloud run out of real disciples?"],
		["Lin Feng", "Release the girl, or I will cut you down."],
	],
	"post:iron_fang": [
		["Iron Fang", "Impossible... the Blood Moon... will remember..."],
	],
	"s_yue": [
		["Yue Ling", "You came! I am Yue Ling, a wandering healer. Iron Fang bound me when I refused to poison a well."],
		["Yue Ling", "The bamboo grove is wailing. Something ancient has been twisted by demonic qi."],
		["Lin Feng", "Then let us calm it together."],
		["Yue Ling", "Yue Ling joins your party. Her Spring Rain mends the wounded."],
	],
	"pre:bamboo_spirit": [
		["Bamboo Spirit", "Shhhhh... the roots remember the red moon... they command me to crush you..."],
		["Yue Ling", "It is in pain, Lin Feng. Strike true, and end its torment."],
	],
	"post:bamboo_spirit": [
		["Bamboo Spirit", "Thank you, child of the Nine Heavens root... the crimson marsh... beware the hag who feeds there."],
		["Lin Feng", "My qi is overflowing. I feel the walls of Qi Condensation straining. A breakthrough is near."],
	],
	"pre:s_break1": [
		["Narrator", "Dark clouds coil above your head. The Heavens test those who would step beyond the mortal realm."],
	],
	"post:s_break1": [
		["Narrator", "Lightning fades. Your dantian condenses into a solid foundation. You are now a Foundation Establishment cultivator."],
	],
	"s_elder2": [
		["Elder Qing Xuan", "Foundation Establishment already? Heaven forgive me, I misjudged you."],
		["Elder Qing Xuan", "The Alchemist's patients are poisoned with marsh venom. The antidote requires Blood Lotuses from the Crimson Marsh."],
		["Elder Qing Xuan", "The path beyond the bamboo is now open to you. Beware the Marsh Hag."],
	],
	"pre:marsh_hag": [
		["Marsh Hag", "Kehehe... fresh qi wanders into my bog. Come closer, little cultivator."],
		["Yue Ling", "Her curses are dark-aspected. Water and fire will cut through her mist."],
	],
	"post:marsh_hag": [
		["Marsh Hag", "The Blood Moon... pays well... for the seal's bearer... you cannot hide..."],
		["Lin Feng", "The seal's bearer? Is that me?"],
		["Yue Ling", "Let us bring the lotuses back first. Answers can wait."],
	],
	"s_antidote": [
		["Alchemist Mo", "Blood Lotuses! The antidote will brew by nightfall. You have saved a dozen disciples."],
		["Alchemist Mo", "Take this stipend. And Lin Feng... your aura is leaking like a cracked jar. Break through before you push further."],
	],
	"pre:s_break2": [
		["Narrator", "Your foundation trembles. A golden core begins to spin within your dantian as thunder gathers."],
	],
	"post:s_break2": [
		["Narrator", "The core condenses, radiant as a miniature sun. You are now a Golden Core cultivator."],
	],
	"s_elder3": [
		["Elder Qing Xuan", "Golden Core! In my youth I needed forty years for what you have done in a season."],
		["Elder Qing Xuan", "The Frostpeak Caverns hold Frost Jades, the only material capable of reinforcing the Lotus Seal."],
		["Elder Qing Xuan", "A Frost Wyrm slumbers there. Bring three jades, and slay the beast and its brood if they block your path."],
	],
	"pre:frost_wyrm": [
		["Frost Wyrm", "Who dares enter my glacier? Your warmth offends me."],
		["Lin Feng", "We only need the jades, and your death if you insist."],
	],
	"post:frost_wyrm": [
		["Frost Wyrm", "The Demon Lord... promised me spring... he lied..."],
		["Yue Ling", "Xu Mo has been recruiting every great beast in the realm."],
	],
	"pre:s_break3": [
		["Narrator", "Beneath the frozen sky your golden core cracks open, and a tiny infant of pure qi opens its eyes."],
	],
	"post:s_break3": [
		["Narrator", "Your Nascent Soul awakens, laughing in the lightning. You are now a Nascent Soul cultivator."],
	],
	"s_elder4": [
		["Elder Qing Xuan", "The jades will hold the Seal for a few more months. But you must deal with the source: the Demon Lord."],
		["Elder Qing Xuan", "To face him you need a sword technique worthy of the Nine Heavens. An ancestor of our sect still lingers in Thunder Valley."],
		["Elder Qing Xuan", "Go. The way is open."],
	],
	"s_swordghost": [
		["Ancestor Jian Wuchen", "Three thousand years I have waited for a disciple whose heart does not tremble at thunder."],
		["Ancestor Jian Wuchen", "Gather four Thunder Shards from the valley, then slay the Roc that has made the storm its throne."],
		["Ancestor Jian Wuchen", "Do this, and I will pass on the Heaven-Cleaving Sword."],
		["Lin Feng", "I will earn it, Ancestor."],
	],
	"pre:thunder_roc": [
		["Thunder Roc", "SKREEEE! The storm is mine! Fall, little soul!"],
	],
	"post:thunder_roc": [
		["Ancestor Jian Wuchen", "Well fought. Take the Heaven-Cleaving Sword, my final gift. May it cleave even the heavens."],
		["Lin Feng", "I feel the technique awakening in my bones."],
	],
	"s_elder5": [
		["Elder Qing Xuan", "The Roc's feather! Now the Seal sings again. Yet Xu Mo's army gathers at the Blood Moon Palace, beyond Thunder Valley."],
		["Elder Qing Xuan", "Go, Lin Feng. Take his generals, then take his head. The sect's fate rests on your blade."],
		["Yue Ling", "I will be at your side to the end."],
	],
	"pre:general_blood": [
		["General Xue Sha", "A mortal-born sweeper in my lord's halls? How delightful. I shall drink you dry."],
	],
	"post:general_blood": [
		["General Xue Sha", "My blood... returns to the moon..."],
	],
	"pre:general_shadow": [
		["General Mo Ying", "You cannot strike what has no body, little sword."],
		["Yue Ling", "Fire dispels shadow, Lin Feng. Burn him out!"],
	],
	"post:general_shadow": [
		["General Mo Ying", "Light... how unbearable..."],
		["Lin Feng", "Only the Demon Lord remains."],
	],
	"pre:demon_lord": [
		["Demon Lord Xu Mo", "At last, the bearer of the Nine Heavens root walks into my hall. I have hunted you for three centuries."],
		["Lin Feng", "Your hunt ends here, Xu Mo."],
		["Demon Lord Xu Mo", "Then let the heavens judge us both!"],
	],
	"post:demon_lord": [
		["Demon Lord Xu Mo", "Impossible... a sweeper... a child... Hahaha... the heavens... choose well..."],
		["Yue Ling", "It is over. Lin Feng, look at the sky!"],
	],
	"pre:s_break4": [
		["Narrator", "Nine layers of tribulation cloud swallow the sky. The Heavens do not let any being ascend without trial."],
		["Lin Feng", "Come, then. I have swept these steps for three years. I fear nothing."],
	],
	"post:s_break4": [
		["Narrator", "The final bolt falls and, with it, the shackles of the mortal realm. Lin Feng ascends to Deity Transformation."],
	],
}
