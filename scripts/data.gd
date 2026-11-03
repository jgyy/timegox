class_name Data
extends RefCounted
## Static game content: realms, skills, enemies, areas, quest chain and dialogue.

const MAX_LEVEL := 18
const REALMS := ["Qi Condensation", "Foundation Establishment", "Golden Core", "Nascent Soul", "Deity Transformation", "Void Refinement", "Dao Merging"]
const STAGES := ["Early", "Middle", "Late"]
const EXP_NEED := [124, 228, 352, 538, 787, 1076, 1490, 1987, 2588, 3416, 4450, 5692, 13200, 17400, 22500, 28800, 36600, 46500]
const ENEMY_EXP := [4, 8, 12, 19, 28, 39, 54, 72, 93, 123, 161, 206, 260, 320, 390, 470, 560, 660]
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
	"abyss": {"n": "Abyssal Tide", "cost": 55, "mult": 2.0, "elem": "water", "tgt": "all", "lv": 12, "who": 0},
	"meteor": {"n": "Meteor Rain", "cost": 65, "mult": 2.3, "elem": "fire", "tgt": "all", "lv": 14, "who": 0},
	"voidcut": {"n": "Void Rending Slash", "cost": 70, "mult": 5.4, "elem": "dark", "tgt": "one", "lv": 15, "who": 0},
	"judgement": {"n": "Celestial Judgement", "cost": 90, "mult": 7.0, "elem": "thunder", "tgt": "one", "lv": 17, "who": 0},
	"needle": {"n": "Jade Needle", "cost": 0, "mult": 1.0, "elem": "wood", "tgt": "one", "lv": 0, "who": 1},
	"rain": {"n": "Spring Rain", "cost": 16, "heal": 0.35, "elem": "water", "tgt": "allies", "lv": 0, "who": 1},
	"lotus_burst": {"n": "Lotus Burst", "cost": 22, "mult": 1.4, "elem": "water", "tgt": "all", "lv": 4, "who": 1},
	"starlight": {"n": "Starlight Rain", "cost": 40, "heal": 0.5, "elem": "water", "tgt": "allies", "lv": 13, "who": 1},
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
	"coral_guard": {"n": "Coral Guard", "elem": "water", "weak": "thunder", "col": Color("e8806a"), "shape": "crab"},
	"kelp_serpent": {"n": "Kelp Serpent", "elem": "wood", "weak": "fire", "col": Color("3f9a6a"), "shape": "serpent"},
	"abyss_jelly": {"n": "Abyss Jelly", "elem": "water", "weak": "thunder", "col": Color("7ad8ff"), "shape": "jelly"},
	"magma_slime": {"n": "Magma Slime", "elem": "fire", "weak": "water", "col": Color("ff6a2a"), "shape": "blob"},
	"ash_salamander": {"n": "Ash Salamander", "elem": "fire", "weak": "water", "col": Color("d2582a"), "shape": "serpent"},
	"ember_sprite": {"n": "Ember Sprite", "elem": "fire", "weak": "water", "col": Color("ffb040"), "shape": "wisp"},
	"void_walker": {"n": "Void Walker", "elem": "dark", "weak": "thunder", "col": Color("7a50c8"), "shape": "wraith"},
	"rift_spider": {"n": "Rift Spider", "elem": "dark", "weak": "fire", "col": Color("5a3a90"), "shape": "spider"},
	"star_eater": {"n": "Star Eater", "elem": "dark", "weak": "thunder", "col": Color("b080ff"), "shape": "jelly"},
	"celestial_guard": {"n": "Celestial Guard", "elem": "phys", "weak": "dark", "col": Color("f0e0a0"), "shape": "humanoid"},
	"thunder_qilin": {"n": "Thunder Qilin", "elem": "thunder", "weak": "earth", "col": Color("ffe8a0"), "shape": "beast"},
	"light_wisp": {"n": "Dawn Wisp", "elem": "phys", "weak": "dark", "col": Color("fffbe0"), "shape": "wisp"},
	# bosses
	"crab_general": {"n": "Armored Crab General", "elem": "water", "weak": "thunder", "col": Color("d0502a"), "shape": "crab", "boss": true},
	"tide_hydra": {"n": "Many-Headed Tide Hydra", "elem": "water", "weak": "thunder", "col": Color("2a9a8a"), "shape": "serpent", "boss": true},
	"cinder_behemoth": {"n": "Cinder Behemoth", "elem": "fire", "weak": "water", "col": Color("c04a1a"), "shape": "golem", "boss": true},
	"star_devourer": {"n": "Star Devourer", "elem": "dark", "weak": "thunder", "col": Color("8a60ff"), "shape": "jelly", "boss": true},
	"lightning_magistrate": {"n": "Lightning Magistrate", "elem": "thunder", "weak": "earth", "col": Color("d8e8ff"), "shape": "storm", "boss": true},
	"siren_queen": {"n": "Siren Queen", "elem": "water", "weak": "thunder", "col": Color("4ac0c8"), "shape": "wraith", "boss": true},
	"dragon_king": {"n": "Azure Dragon King", "elem": "water", "weak": "thunder", "col": Color("3a8ad8"), "shape": "dragon", "boss": true},
	"lava_titan": {"n": "Lava Titan", "elem": "fire", "weak": "water", "col": Color("e0501a"), "shape": "golem", "boss": true},
	"ash_phoenix": {"n": "Ash Phoenix", "elem": "fire", "weak": "water", "col": Color("ff8a2a"), "shape": "phoenix", "boss": true},
	"inferno_lord": {"n": "Inferno Lord Chi Yan", "elem": "fire", "weak": "water", "col": Color("ff3a1a"), "shape": "demon", "boss": true},
	"rift_weaver": {"n": "Rift Weaver", "elem": "dark", "weak": "fire", "col": Color("6a40b0"), "shape": "spider", "boss": true},
	"void_sentinel": {"n": "Void Sentinel", "elem": "dark", "weak": "thunder", "col": Color("4a3a78"), "shape": "golem", "boss": true},
	"chaos_serpent": {"n": "Chaos Serpent", "elem": "dark", "weak": "fire", "col": Color("9a50e0"), "shape": "serpent", "boss": true},
	"heaven_general": {"n": "Heavenly General Tian Wei", "elem": "phys", "weak": "dark", "col": Color("e8d080"), "shape": "demon", "boss": true},
	"azure_qilin": {"n": "Azure Qilin", "elem": "thunder", "weak": "earth", "col": Color("80d0ff"), "shape": "beast", "boss": true},
	"heavenly_emperor": {"n": "Jade Emperor of Ruin", "elem": "thunder", "weak": "dark", "col": Color("fff0a0"), "shape": "phoenix", "boss": true},
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
	var base: int = ENEMY_EXP[mini(lv, ENEMY_EXP.size() - 1)]
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
		"portals": [
			{"to": "thunder", "pos": Vector2i(1, 28), "dest": Vector2i(84, 25), "open": ""},
			{"to": "dragon", "pos": Vector2i(88, 28), "dest": Vector2i(4, 28), "open": "s_break4"},
		],
		"bosses": [
			{"id": "blood_hound", "pos": Vector2i(48, 22), "lv": 11, "req": 11},
			{"id": "general_blood", "pos": Vector2i(32, 12), "lv": 11, "req": 11},
			{"id": "general_shadow", "pos": Vector2i(56, 44), "lv": 11, "req": 11},
			{"id": "demon_lord", "pos": Vector2i(80, 28), "lv": 12, "req": 11},
		],
	},
	"dragon": {
		"n": "Sunken Dragon Palace", "w": 92, "h": 56, "seed": 71, "theme": "abyss", "enemies": 18,
		"pool": [["coral_guard", 12, 13], ["kelp_serpent", 12, 13], ["abyss_jelly", 12, 13]],
		"portals": [
			{"to": "palace", "pos": Vector2i(1, 28), "dest": Vector2i(86, 28), "open": ""},
			{"to": "volcano", "pos": Vector2i(90, 28), "dest": Vector2i(4, 28), "open": "s_dr_king"},
		],
		"npcs": [{"id": "dragon_envoy", "n": "Envoy Ao Lan", "pos": Vector2i(10, 26), "col": Color("6ae0e8"), "vis": ["s_dr_intro", ""]}],
		"bosses": [
			{"id": "crab_general", "pos": Vector2i(34, 14), "lv": 12, "req": 12},
			{"id": "tide_hydra", "pos": Vector2i(46, 28), "lv": 12, "req": 12},
			{"id": "siren_queen", "pos": Vector2i(56, 42), "lv": 13, "req": 13},
			{"id": "dragon_king", "pos": Vector2i(80, 26), "lv": 13, "req": 13},
		],
		"pickups": [
			{"id": "pearl1", "item": "pearl", "pos": Vector2i(22, 44)}, {"id": "pearl2", "item": "pearl", "pos": Vector2i(40, 10)},
			{"id": "pearl3", "item": "pearl", "pos": Vector2i(60, 14)}, {"id": "pearl4", "item": "pearl", "pos": Vector2i(72, 46)},
		],
		"pickup_vis": "s_dr_pearl",
	},
	"volcano": {
		"n": "Ashen Volcano", "w": 94, "h": 56, "seed": 81, "theme": "volcano", "enemies": 18,
		"pool": [["magma_slime", 13, 14], ["ash_salamander", 13, 14], ["ember_sprite", 13, 14]],
		"portals": [
			{"to": "dragon", "pos": Vector2i(1, 28), "dest": Vector2i(86, 28), "open": ""},
			{"to": "void", "pos": Vector2i(92, 28), "dest": Vector2i(4, 28), "open": "s_break5"},
		],
		"npcs": [{"id": "fire_sage", "n": "Sage Chi Rong", "pos": Vector2i(10, 26), "col": Color("ff9a5a"), "vis": ["s_vo_intro", ""]}],
		"bosses": [
			{"id": "lava_titan", "pos": Vector2i(36, 40), "lv": 13, "req": 13},
			{"id": "cinder_behemoth", "pos": Vector2i(48, 24), "lv": 13, "req": 13},
			{"id": "ash_phoenix", "pos": Vector2i(58, 12), "lv": 14, "req": 14},
			{"id": "inferno_lord", "pos": Vector2i(82, 30), "lv": 14, "req": 14},
		],
		"pickups": [
			{"id": "ember1", "item": "ember", "pos": Vector2i(20, 12)}, {"id": "ember2", "item": "ember", "pos": Vector2i(42, 46)},
			{"id": "ember3", "item": "ember", "pos": Vector2i(64, 28)}, {"id": "ember4", "item": "ember", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_vo_collect",
	},
	"void": {
		"n": "Void Rift Expanse", "w": 96, "h": 58, "seed": 91, "theme": "void", "enemies": 20,
		"pool": [["void_walker", 15, 16], ["rift_spider", 15, 16], ["star_eater", 15, 16]],
		"portals": [
			{"to": "volcano", "pos": Vector2i(1, 28), "dest": Vector2i(88, 28), "open": ""},
			{"to": "celestial", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_vd_serpent"},
		],
		"npcs": [{"id": "void_hermit", "n": "Hermit Wu Ji", "pos": Vector2i(10, 26), "col": Color("c0a0ff"), "vis": ["s_vd_intro", ""]}],
		"bosses": [
			{"id": "rift_weaver", "pos": Vector2i(30, 14), "lv": 15, "req": 15},
			{"id": "star_devourer", "pos": Vector2i(40, 30), "lv": 15, "req": 15},
			{"id": "void_sentinel", "pos": Vector2i(52, 44), "lv": 16, "req": 16},
			{"id": "chaos_serpent", "pos": Vector2i(84, 26), "lv": 16, "req": 16},
		],
		"pickups": [
			{"id": "star1", "item": "star", "pos": Vector2i(24, 46)}, {"id": "star2", "item": "star", "pos": Vector2i(44, 12)},
			{"id": "star3", "item": "star", "pos": Vector2i(66, 40)}, {"id": "star4", "item": "star", "pos": Vector2i(78, 12)},
		],
		"pickup_vis": "s_vd_collect",
	},
	"celestial": {
		"n": "Celestial Gate", "w": 98, "h": 58, "seed": 101, "theme": "celestial", "enemies": 20,
		"pool": [["celestial_guard", 16, 17], ["thunder_qilin", 16, 17], ["light_wisp", 16, 17]],
		"portals": [{"to": "void", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""}],
		"npcs": [{"id": "gate_keeper", "n": "Gatekeeper Bai Ze", "pos": Vector2i(10, 26), "col": Color("fff0b0"), "vis": ["s_ce_intro", ""]}],
		"bosses": [
			{"id": "heaven_general", "pos": Vector2i(32, 40), "lv": 16, "req": 16},
			{"id": "lightning_magistrate", "pos": Vector2i(46, 28), "lv": 16, "req": 16},
			{"id": "azure_qilin", "pos": Vector2i(58, 14), "lv": 17, "req": 17},
			{"id": "heavenly_emperor", "pos": Vector2i(88, 28), "lv": 17, "req": 17},
		],
		"pickups": [
			{"id": "sigil1", "item": "sigil", "pos": Vector2i(22, 12)}, {"id": "sigil2", "item": "sigil", "pos": Vector2i(40, 46)},
			{"id": "sigil3", "item": "sigil", "pos": Vector2i(64, 40)}, {"id": "sigil4", "item": "sigil", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_ce_collect",
	},
}

const AREA_CHAIN := ["sect", "bamboo", "marsh", "frost", "thunder", "palace", "dragon", "volcano", "void", "celestial"]

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
	{"id": "s_break4", "kind": "breakthrough", "to": 12, "t": "Endure the Deity Tribulation"},
	# ---- Part II: The Shattered Heavens
	{"id": "s_dr_intro", "kind": "talk", "npc": "dragon_envoy", "area": "dragon", "t": "Seek the Dragon Palace envoy beyond the Blood Moon Palace", "stones": 600},
	{"id": "s_dr_pearl", "kind": "collect", "item": "pearl", "n": 4, "area": "dragon", "t": "Recover 4 Dragon Pearls from the sunken halls"},
	{"id": "s_dr_hunt", "kind": "hunt", "area": "dragon", "n": 28, "t": "Drive off the Dragon Palace's corrupted guardians"},
	{"id": "s_dr_crab", "kind": "kill", "boss": "crab_general", "area": "dragon", "t": "Crack the Armored Crab General"},
	{"id": "s_dr_hydra", "kind": "kill", "boss": "tide_hydra", "area": "dragon", "t": "Cut down the Many-Headed Tide Hydra"},
	{"id": "s_dr_siren", "kind": "kill", "boss": "siren_queen", "area": "dragon", "t": "Silence the Siren Queen"},
	{"id": "s_dr_king", "kind": "kill", "boss": "dragon_king", "area": "dragon", "t": "Free the Azure Dragon King from the rift's grip", "stones": 800},
	{"id": "s_vo_intro", "kind": "talk", "npc": "fire_sage", "area": "volcano", "t": "Find Sage Chi Rong in the Ashen Volcano"},
	{"id": "s_vo_collect", "kind": "collect", "item": "ember", "n": 4, "area": "volcano", "t": "Gather 4 Phoenix Embers"},
	{"id": "s_vo_hunt", "kind": "hunt", "area": "volcano", "n": 28, "t": "Burn back the fire-spawn of the volcano"},
	{"id": "s_vo_titan", "kind": "kill", "boss": "lava_titan", "area": "volcano", "t": "Topple the Lava Titan"},
	{"id": "s_vo_behemoth", "kind": "kill", "boss": "cinder_behemoth", "area": "volcano", "t": "Smother the Cinder Behemoth"},
	{"id": "s_vo_phoenix", "kind": "kill", "boss": "ash_phoenix", "area": "volcano", "t": "Quench the Ash Phoenix"},
	{"id": "s_vo_lord", "kind": "kill", "boss": "inferno_lord", "area": "volcano", "t": "Defeat Inferno Lord Chi Yan", "stones": 1000},
	{"id": "s_break5", "kind": "breakthrough", "to": 15, "t": "Break through to Void Refinement"},
	{"id": "s_vd_intro", "kind": "talk", "npc": "void_hermit", "area": "void", "t": "Speak with the hermit in the Void Rift Expanse"},
	{"id": "s_vd_collect", "kind": "collect", "item": "star", "n": 4, "area": "void", "t": "Collect 4 Star Fragments adrift in the void"},
	{"id": "s_vd_hunt", "kind": "hunt", "area": "void", "n": 30, "t": "Cut down the void-born horrors"},
	{"id": "s_vd_weaver", "kind": "kill", "boss": "rift_weaver", "area": "void", "t": "Sever the Rift Weaver's threads"},
	{"id": "s_vd_devourer", "kind": "kill", "boss": "star_devourer", "area": "void", "t": "Starve the Star Devourer"},
	{"id": "s_vd_sentinel", "kind": "kill", "boss": "void_sentinel", "area": "void", "t": "Shatter the Void Sentinel"},
	{"id": "s_vd_serpent", "kind": "kill", "boss": "chaos_serpent", "area": "void", "t": "Slay the Chaos Serpent", "stones": 1200},
	{"id": "s_ce_intro", "kind": "talk", "npc": "gate_keeper", "area": "celestial", "t": "Approach the Gatekeeper of the Celestial Gate"},
	{"id": "s_ce_collect", "kind": "collect", "item": "sigil", "n": 4, "area": "celestial", "t": "Gather 4 Heaven Sigils to unseal the Gate"},
	{"id": "s_ce_hunt", "kind": "hunt", "area": "celestial", "n": 30, "t": "Cleanse the Celestial Gate of its fallen guardians"},
	{"id": "s_ce_general", "kind": "kill", "boss": "heaven_general", "area": "celestial", "t": "Defeat Heavenly General Tian Wei"},
	{"id": "s_ce_magistrate", "kind": "kill", "boss": "lightning_magistrate", "area": "celestial", "t": "Overturn the Lightning Magistrate's verdict"},
	{"id": "s_ce_qilin", "kind": "kill", "boss": "azure_qilin", "area": "celestial", "t": "Calm the Azure Qilin"},
	{"id": "s_ce_emperor", "kind": "kill", "boss": "heavenly_emperor", "area": "celestial", "t": "Confront the Jade Emperor of Ruin"},
	{"id": "s_break6", "kind": "breakthrough", "to": 18, "t": "Endure the Dao-Merging Tribulation"},
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
	"pearl": {"n": "Dragon Pearl", "desc": "Quest item"},
	"ember": {"n": "Phoenix Ember", "desc": "Quest item"},
	"star": {"n": "Star Fragment", "desc": "Quest item"},
	"sigil": {"n": "Heaven Sigil", "desc": "Quest item"},
}
const TEMPER_COST := [250, 700, 1500, 2800, 4500, 6500, 9000, 12000]

static func pill_price(kind: String, level: int) -> int:
	return (24 + 5 * level) if kind == "hp_pill" else (20 + 4 * level)

# ---------------------------------------------------------------- dialogue
const CHAT := {
	"elder": ["The mountain wind carries the scent of blood. Stay vigilant.", "Cultivation is a marathon, disciple, not a sprint."],
	"alchemist": ["Pills are only borrowed time. Use them wisely.", "Hehe, my furnace never lies."],
	"smith": ["Steel remembers every blow. Bring me stones and I will temper your sword.", "A sword is only as sharp as its wielder's resolve."],
	"yue_ling": ["Let us go, Lin Feng.", "I will keep your wounds in check."],
	"sword_ghost": ["Thunder answers those who do not flinch."],
	"dragon_envoy": ["The tide remembers every promise. Do not break yours.", "Pearls glow brighter near the king's throne."],
	"fire_sage": ["Fire does not hate. It simply consumes. Be the hand that guides it.", "The embers are warm because they remember the Phoenix."],
	"void_hermit": ["There is no up or down here. Only forward.", "Do not stare at the stars too long. They stare back."],
	"gate_keeper": ["The Gate has opened for three. Closed for ten thousand.", "Mind your step. Light is not always kind."],
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
		["Yue Ling", "Lin Feng... the sky. It is not healing. Look, the clouds are cracking like glass."],
		["Narrator", "Beyond the throne of the fallen Demon Lord, a new gate shimmers open: a rift leading down into the sunken halls of the Dragon Palace."],
		["Lin Feng", "Xu Mo was only a warden. Something older has been draining the heavens. Let us follow the rift."],
	],
	"s_dr_intro": [
		["Envoy Ao Lan", "A mortal who has slain the Demon Lord walks into the Dragon Palace? Then the old prophecy was not a lie."],
		["Envoy Ao Lan", "The Azure Dragon King holds the tide that keeps the rift sealed. Something has seized his heart and turned his guards against us."],
		["Envoy Ao Lan", "Recover four Dragon Pearls from the sunken halls. Only their light can break the corruption."],
		["Lin Feng", "Tell me where to start."],
		["Envoy Ao Lan", "Everywhere. The sea has teeth tonight."],
	],
	"pre:crab_general": [
		["Armored Crab General", "Halt, surface-dweller! By the king's order, none pass the Coral Gate!"],
		["Yue Ling", "His shell is thick. Lightning will find the seam."],
	],
	"post:crab_general": [
		["Armored Crab General", "The king... was not... himself... find the Siren..."],
	],
	"pre:tide_hydra": [
		["Many-Headed Tide Hydra", "Nine mouths, nine hungers. Which of you shall feed us first?"],
		["Yue Ling", "Cut one head and two grow. Strike the body, Lin Feng!"],
	],
	"post:tide_hydra": [
		["Lin Feng", "The tide is calmer. The Siren's song grows louder, though."],
	],
	"pre:siren_queen": [
		["Siren Queen", "Sing with me, little swordsman. Sing until your sword forgets your hand."],
		["Yue Ling", "Do not listen to the song, Lin Feng! Strike through it!"],
	],
	"post:siren_queen": [
		["Siren Queen", "He promised us the sun... the Emperor promised us the sun..."],
		["Lin Feng", "The Emperor again. Whoever he is, he has been whispering to everyone."],
	],
	"pre:dragon_king": [
		["Azure Dragon King", "Who disturbs the tide? Ah... the little cultivator. How you have grown."],
		["Azure Dragon King", "I am sorry. I cannot hold the sea back any longer. Run, or fight me with everything you have!"],
	],
	"post:dragon_king": [
		["Azure Dragon King", "You freed me. The rift beneath the volcano feeds on the heavens. Go to the Ashen Volcano, find Sage Chi Rong. Take this pearl as proof."],
		["Yue Ling", "A dragon king in our debt. Not bad for a sweeper."],
	],
	"s_vo_intro": [
		["Sage Chi Rong", "You smell of salt and thunder. The Dragon King sent you. Good."],
		["Sage Chi Rong", "This volcano sleeps above a wound in the world. Phoenix Embers can cauterise it, but the Phoenix itself has gone mad."],
		["Sage Chi Rong", "Gather four Embers. Then deal with the fire-spawn, the Titan, the Phoenix, and the Lord who commands them."],
		["Lin Feng", "A short list."],
		["Sage Chi Rong", "A long list, if you are careless. Do not be careless."],
	],
	"pre:lava_titan": [
		["Lava Titan", "RRRRUMMMMBLE. Stone. Fire. Break."],
		["Yue Ling", "Water will crack that crust, Lin Feng!"],
	],
	"post:lava_titan": [
		["Lin Feng", "It crumbled like a cooling forge. The path up is open."],
	],
	"pre:cinder_behemoth": [
		["Cinder Behemoth", "...embers... cold... feed me... fire..."],
		["Sage Chi Rong", "It is a forge-beast, hollowed by despair. Douse it, quickly!"],
	],
	"post:cinder_behemoth": [
		["Sage Chi Rong", "The ash settles. The Phoenix waits above."],
	],
	"pre:ash_phoenix": [
		["Ash Phoenix", "KREEEE! The sky burns! The sky burns and I burn with it!"],
		["Yue Ling", "It is not malice, it is pain. Put out the fire, Lin Feng!"],
	],
	"post:ash_phoenix": [
		["Ash Phoenix", "Child of the Nine Heavens... the Emperor... pulled the strings... end it..."],
	],
	"pre:inferno_lord": [
		["Inferno Lord Chi Yan", "I am the last flame of the Blood Moon. My master's will burns brighter than your sword."],
		["Lin Feng", "Your master is dead, Chi Yan."],
		["Inferno Lord Chi Yan", "My master is the one above him. Now burn!"],
	],
	"post:inferno_lord": [
		["Inferno Lord Chi Yan", "Ahh... cold... the Emperor... will drain you too..."],
		["Sage Chi Rong", "It is done. The volcano calms. Now, you must break through. The void will not tolerate a Deity as weak as you."],
	],
	"pre:s_break5": [
		["Narrator", "Rivers of flame gather overhead and form a spiralling funnel. The Heavens test the Deity who would pass into the Void."],
	],
	"post:s_break5": [
		["Narrator", "The fire fades into cold starlight. Lin Feng stands in Void Refinement, no longer bound by the weight of the earth."],
		["Sage Chi Rong", "The Void Rift lies beyond the volcano's eastern slope. Find Hermit Wu Ji. He knows the Emperor's name."],
	],
	"s_vd_intro": [
		["Hermit Wu Ji", "You came through the fire. Few do. Sit. There is no hurry in the void."],
		["Hermit Wu Ji", "The Jade Emperor of Ruin was once the first ascended being. He has been consuming the heavens to make himself a god without equals."],
		["Hermit Wu Ji", "Collect four Star Fragments. Forged together, they can pierce the Gate that he guards."],
		["Yue Ling", "And the horrors?"],
		["Hermit Wu Ji", "They are his tears. Cut them down, and cut down the three who shepherd them."],
	],
	"pre:rift_weaver": [
		["Rift Weaver", "Tssss... fresh threads for my loom. Such bright, bright threads..."],
		["Yue Ling", "Fire will burn its silk!"],
	],
	"post:rift_weaver": [
		["Lin Feng", "Its web is gone. The way deeper is clear."],
	],
	"pre:star_devourer": [
		["Star Devourer", "Hungry. Hungry. Your light tastes of dawn."],
		["Hermit Wu Ji", "It swallowed a dozen constellations. Lightning will tear it open!"],
	],
	"post:star_devourer": [
		["Lin Feng", "The stars it swallowed drift free again. Beautiful."],
	],
	"pre:void_sentinel": [
		["Void Sentinel", "INTRUDER. THE EMPEROR'S DECREE: NONE SHALL PASS."],
		["Lin Feng", "Then break the decree, or I will."],
	],
	"post:void_sentinel": [
		["Void Sentinel", "DECREE... FULFILLED... THE GATE... STILL STANDS..."],
	],
	"pre:chaos_serpent": [
		["Chaos Serpent", "Ssssso small, so bright. The Emperor will wear your light as a crown."],
		["Yue Ling", "It feeds on hesitation. Strike first, Lin Feng!"],
	],
	"post:chaos_serpent": [
		["Hermit Wu Ji", "You have done what I could not in a thousand years. The Celestial Gate lies ahead. Be ready for him."],
	],
	"s_ce_intro": [
		["Gatekeeper Bai Ze", "You have the look of someone who has already won, and lost, and won again. Welcome to the Celestial Gate."],
		["Gatekeeper Bai Ze", "Beyond this Gate sits the Jade Emperor of Ruin. His generals, his sacred beast, and his throne guard the way."],
		["Gatekeeper Bai Ze", "Collect four Heaven Sigils to unseal the Gate, and cleanse its fallen guardians."],
		["Lin Feng", "And then?"],
		["Gatekeeper Bai Ze", "Then the heavens decide who deserves them."],
	],
	"pre:heaven_general": [
		["Heavenly General Tian Wei", "Mortal-born. Unworthy. I shall return you to the dust from which you were raised."],
		["Yue Ling", "His armor is blessed. The dark will crack it!"],
	],
	"post:heaven_general": [
		["Heavenly General Tian Wei", "I served the Heavens... not him... forgive me..."],
	],
	"pre:lightning_magistrate": [
		["Lightning Magistrate", "The court is in session. The charge: ascending without leave. The sentence: thunder."],
		["Lin Feng", "I appeal the verdict, with my sword."],
	],
	"post:lightning_magistrate": [
		["Lightning Magistrate", "Case dismissed... the Qilin awaits..."],
	],
	"pre:azure_qilin": [
		["Azure Qilin", "I was a guardian once. Now I only remember the thunder. Forgive me, child."],
	],
	"post:azure_qilin": [
		["Azure Qilin", "Thank you. The Emperor's throne is a mirror. Do not look away."],
		["Yue Ling", "Lin Feng, this is it."],
	],
	"pre:heavenly_emperor": [
		["Jade Emperor of Ruin", "At last, the Nine Heavens root. I have waited a thousand years for you to ripen."],
		["Lin Feng", "I am not fruit to be picked."],
		["Jade Emperor of Ruin", "Every flame I have lit has led you here. Come. Become my crown."],
		["Yue Ling", "I'm with you, always."],
	],
	"post:heavenly_emperor": [
		["Jade Emperor of Ruin", "Impossible... a sweeper... who sweeps even gods aside..."],
		["Narrator", "The Emperor's throne shatters. The heavens above ring like a great bell, then fall silent."],
		["Yue Ling", "It's over. The sky is whole again. Lin Feng, one last trial awaits."],
	],
	"pre:s_break6": [
		["Narrator", "Nine layers of tribulation cloud swallow the sky. The Heavens do not let any being merge with the Dao without trial."],
		["Lin Feng", "Come, then. I have swept these steps for three years. I fear nothing."],
	],
	"post:s_break6": [
		["Narrator", "The final bolt falls and, with it, the last chain between Lin Feng and the Dao. He ascends to Dao Merging, and the heavens open their gates."],
	],
}
