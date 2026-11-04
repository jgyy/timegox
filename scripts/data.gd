class_name Data
extends RefCounted
## Static game content: realms, skills, enemies, areas, quest chain and dialogue.

const MAX_LEVEL := 30
const REALMS := ["Qi Condensation", "Foundation Establishment", "Golden Core", "Nascent Soul", "Deity Transformation", "Void Refinement", "Dao Merging", "Mahayana", "True Immortal", "Dao Ancestor", "Primordial Sovereign"]
const STAGES := ["Early", "Middle", "Late"]
const EXP_NEED := [124, 228, 352, 538, 787, 1076, 1490, 1987, 2588, 3416, 4450, 5692, 13200, 17400, 22500, 28800, 36600, 46500, 34000, 41000, 49000, 58000, 68000, 80000, 140000, 160000, 230000, 200000, 230000, 280000, 320000]
const ENEMY_EXP := [4, 8, 12, 19, 28, 39, 54, 72, 93, 123, 161, 206, 260, 320, 390, 470, 560, 660, 770, 880, 1000, 1130, 1270, 1420, 1580, 1750, 1930, 2120, 2320, 2530, 2750]
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
	"heaven": {"n": "Heaven-Cleaving Sword", "cost": 45, "mult": 4.2, "elem": "phys", "tgt": "one", "lv": 10, "who": 0, "after": "s_roc"},
	"abyss": {"n": "Abyssal Tide", "cost": 55, "mult": 2.0, "elem": "water", "tgt": "all", "lv": 12, "who": 0},
	"meteor": {"n": "Meteor Rain", "cost": 65, "mult": 2.3, "elem": "fire", "tgt": "all", "lv": 14, "who": 0},
	"voidcut": {"n": "Void Rending Slash", "cost": 70, "mult": 5.4, "elem": "dark", "tgt": "one", "lv": 15, "who": 0},
	"judgement": {"n": "Celestial Judgement", "cost": 90, "mult": 7.0, "elem": "thunder", "tgt": "one", "lv": 17, "who": 0},
	"chrono": {"n": "Chrono Severance", "cost": 110, "mult": 8.6, "elem": "dark", "tgt": "one", "lv": 21, "who": 0},
	"genesis": {"n": "Genesis Sword", "cost": 150, "mult": 11.0, "elem": "thunder", "tgt": "one", "lv": 24, "who": 0},
	"starfall": {"n": "Ten Thousand Starfall", "cost": 130, "mult": 3.4, "elem": "fire", "tgt": "all", "lv": 24, "who": 0},
	"inkbreak": {"n": "Ledger-Breaking Stroke", "cost": 170, "mult": 13.5, "elem": "dark", "tgt": "one", "lv": 25, "who": 0},
	"skymend": {"n": "Sky-Mending Sword", "cost": 190, "mult": 15.5, "elem": "earth", "tgt": "one", "lv": 27, "who": 0},
	"fivecolour": {"n": "Five-Colour Stone Rain", "cost": 170, "mult": 4.3, "elem": "wood", "tgt": "all", "lv": 28, "who": 0},
	"pillar": {"n": "Pillar of Heaven Strike", "cost": 210, "mult": 17.5, "elem": "thunder", "tgt": "one", "lv": 29, "who": 0, "after": "s_au_tortoise"},
	"needle": {"n": "Jade Needle", "cost": 0, "mult": 1.0, "elem": "wood", "tgt": "one", "lv": 0, "who": 1},
	"rain": {"n": "Spring Rain", "cost": 16, "heal": 0.35, "elem": "water", "tgt": "allies", "lv": 0, "who": 1},
	"lotus_burst": {"n": "Lotus Burst", "cost": 22, "mult": 1.4, "elem": "water", "tgt": "all", "lv": 4, "who": 1},
	"starlight": {"n": "Starlight Rain", "cost": 40, "heal": 0.5, "elem": "water", "tgt": "allies", "lv": 13, "who": 1},
	"dawn": {"n": "Dawn Lotus", "cost": 60, "heal": 0.7, "elem": "water", "tgt": "allies", "lv": 20, "who": 1},
	"seal_bloom": {"n": "Seal Bloom", "cost": 85, "heal": 0.85, "elem": "water", "tgt": "allies", "lv": 26, "who": 1},
	"mending": {"n": "Nuwa's Mending", "cost": 110, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 28, "who": 1},
	"thread": {"n": "Five-Colour Thread", "cost": 60, "mult": 3.2, "elem": "earth", "tgt": "all", "lv": 27, "who": 1},
}

static func known_skills(who: int, level: int, step: int = 1 << 20) -> Array:
	var out := []
	for id in SKILLS:
		var s = SKILLS[id]
		if s.who == who and s.lv <= level:
			if s.has("after") and step <= step_index(s.after):
				continue
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
	"jade_mantis": {"n": "Jade Mantis Matriarch", "elem": "wood", "weak": "fire", "col": Color("5fd890"), "shape": "mantis", "boss": true},
	"bog_colossus": {"n": "Bog Colossus", "elem": "water", "weak": "fire", "col": Color("6a7a3a"), "shape": "blob", "boss": true},
	"ice_empress": {"n": "Ice Empress", "elem": "water", "weak": "fire", "col": Color("c8e8ff"), "shape": "wraith", "boss": true},
	"storm_ape_king": {"n": "Storm Ape King", "elem": "thunder", "weak": "earth", "col": Color("b08aff"), "shape": "beast", "boss": true},
	"blood_hound": {"n": "Crimson Hellhound", "elem": "dark", "weak": "water", "col": Color("d03040"), "shape": "beast", "boss": true},
	"general_blood": {"n": "General Xue Sha", "elem": "dark", "weak": "water", "col": Color("c02840"), "shape": "demon", "boss": true},
	"general_shadow": {"n": "General Mo Ying", "elem": "dark", "weak": "fire", "col": Color("6a3aa8"), "shape": "demon", "boss": true},
	"demon_lord": {"n": "Demon Lord Xu Mo", "elem": "dark", "weak": "thunder", "col": Color("e02050"), "shape": "demon", "boss": true},
	# ---- Part III monsters
	"mirror_wisp": {"n": "Mirror Wisp", "elem": "phys", "weak": "dark", "col": Color("c8f0ff"), "shape": "wisp"},
	"glass_sentinel": {"n": "Glass Sentinel", "elem": "thunder", "weak": "earth", "col": Color("9ad0e8"), "shape": "golem"},
	"echo_shade": {"n": "Echo Shade", "elem": "dark", "weak": "fire", "col": Color("6a8ac8"), "shape": "wraith"},
	"grave_hound": {"n": "Grave Hound", "elem": "dark", "weak": "fire", "col": Color("8a8a98"), "shape": "beast"},
	"bone_knight": {"n": "Bone Knight", "elem": "dark", "weak": "thunder", "col": Color("e0dcc8"), "shape": "humanoid"},
	"ghost_lantern": {"n": "Ghost Lantern", "elem": "dark", "weak": "water", "col": Color("7af0e0"), "shape": "wisp"},
	"hourglass_wraith": {"n": "Hourglass Wraith", "elem": "earth", "weak": "wood", "col": Color("e8c060"), "shape": "wraith"},
	"clockwork_guard": {"n": "Clockwork Guard", "elem": "phys", "weak": "water", "col": Color("c8984a"), "shape": "golem"},
	"dust_moth": {"n": "Dust Moth", "elem": "earth", "weak": "fire", "col": Color("e8d8a0"), "shape": "bird"},
	"maw_tendril": {"n": "Maw Tendril", "elem": "dark", "weak": "thunder", "col": Color("5a3a78"), "shape": "serpent"},
	"hollow_acolyte": {"n": "Hollow Acolyte", "elem": "dark", "weak": "fire", "col": Color("b8a8d8"), "shape": "humanoid"},
	"dao_fragment": {"n": "Dao Fragment", "elem": "thunder", "weak": "dark", "col": Color("fff0c0"), "shape": "jelly"},
	# ---- Part III bosses
	"shard_mimic": {"n": "Shard Mimic", "elem": "phys", "weak": "dark", "col": Color("a8e0f8"), "shape": "jelly", "boss": true},
	"glass_colossus": {"n": "Glass Colossus", "elem": "thunder", "weak": "earth", "col": Color("88c0e0"), "shape": "golem", "boss": true},
	"drowned_bearer": {"n": "Drowned Bearer Shui Ying", "elem": "water", "weak": "thunder", "col": Color("4a7ac8"), "shape": "wraith", "boss": true},
	"echo_xumo": {"n": "Echo of Xu Mo", "elem": "dark", "weak": "thunder", "col": Color("c03060"), "shape": "demon", "boss": true},
	"bone_wyrm": {"n": "Bone Wyrm", "elem": "dark", "weak": "thunder", "col": Color("e0d8c0"), "shape": "dragon", "boss": true},
	"headless_saint": {"n": "Headless Sword Saint", "elem": "phys", "weak": "dark", "col": Color("9898b0"), "shape": "demon", "boss": true},
	"grave_empress": {"n": "Empress of Bones", "elem": "dark", "weak": "fire", "col": Color("c8c0d8"), "shape": "wraith", "boss": true},
	"founder_qing": {"n": "Founder Qing Lian", "elem": "wood", "weak": "fire", "col": Color("7ae0b0"), "shape": "humanoid", "boss": true},
	"time_tortoise": {"n": "Eon Tortoise", "elem": "earth", "weak": "wood", "col": Color("b8903a"), "shape": "tortoise", "boss": true},
	"dusk_reaper": {"n": "Dusk Reaper", "elem": "dark", "weak": "fire", "col": Color("8a4a30"), "shape": "wraith", "boss": true},
	"dawn_warden": {"n": "Dawn Warden", "elem": "fire", "weak": "water", "col": Color("ffd070"), "shape": "phoenix", "boss": true},
	"young_tianxuan": {"n": "Tian Xuan, the First Sweeper", "elem": "phys", "weak": "dark", "col": Color("f0e8c8"), "shape": "humanoid", "boss": true},
	"maw_herald": {"n": "Maw Herald", "elem": "dark", "weak": "thunder", "col": Color("6a3a98"), "shape": "spider", "boss": true},
	"hollow_dragon": {"n": "Hollow Heaven Dragon", "elem": "thunder", "weak": "dark", "col": Color("d8d0f0"), "shape": "dragon", "boss": true},
	"harvest_avatar": {"n": "Avatar of the Harvest", "elem": "thunder", "weak": "earth", "col": Color("f8e8ff"), "shape": "storm", "boss": true},
	"hollow_heaven": {"n": "The Hollow Heaven", "elem": "dark", "weak": "thunder", "col": Color("3a2060"), "shape": "jelly", "boss": true},
	# ---- Part IV monsters
	"cloud_ray": {"n": "Cloud Ray", "elem": "water", "weak": "thunder", "col": Color("c8e0ff"), "shape": "ray"},
	"gale_sprite": {"n": "Gale Sprite", "elem": "wood", "weak": "fire", "col": Color("b8f0d0"), "shape": "wisp"},
	"sky_mantis": {"n": "Sky Mantis", "elem": "wood", "weak": "fire", "col": Color("90e0a0"), "shape": "mantis"},
	"ledger_clerk": {"n": "Ledger Clerk", "elem": "dark", "weak": "fire", "col": Color("6a9a88"), "shape": "humanoid"},
	"jade_lion": {"n": "Jade Guardian Lion", "elem": "earth", "weak": "wood", "col": Color("5ac0a0"), "shape": "beast"},
	"ink_wraith": {"n": "Ink Wraith", "elem": "dark", "weak": "water", "col": Color("3a3a4a"), "shape": "wraith"},
	"bronze_sentinel": {"n": "Bronze Sentinel", "elem": "earth", "weak": "water", "col": Color("c08a40"), "shape": "golem"},
	"slag_slime": {"n": "Slag Slime", "elem": "fire", "weak": "water", "col": Color("ff9040"), "shape": "blob"},
	"bellows_imp": {"n": "Bellows Imp", "elem": "fire", "weak": "water", "col": Color("ffc060"), "shape": "wisp"},
	"peach_sprite": {"n": "Peach Blossom Sprite", "elem": "wood", "weak": "fire", "col": Color("ffa0c0"), "shape": "plant"},
	"garden_crane": {"n": "Garden Crane", "elem": "water", "weak": "thunder", "col": Color("f0f0f8"), "shape": "bird"},
	"moss_tortoise": {"n": "Moss-Backed Tortoise", "elem": "earth", "weak": "wood", "col": Color("7a9a5a"), "shape": "tortoise"},
	# ---- Part IV bosses
	"manta_sovereign": {"n": "Sky Manta Sovereign", "elem": "water", "weak": "thunder", "col": Color("7ab0f0"), "shape": "ray", "boss": true},
	"gale_mantis": {"n": "Gale Mantis Empress", "elem": "wood", "weak": "fire", "col": Color("60d080"), "shape": "mantis", "boss": true},
	"rainbow_serpent": {"n": "Rainbow Serpent", "elem": "thunder", "weak": "earth", "col": Color("e080f0"), "shape": "serpent", "boss": true},
	"herald_qian": {"n": "Herald of the Ledger, Qian Shu", "elem": "dark", "weak": "fire", "col": Color("4a8a78"), "shape": "humanoid", "boss": true},
	"twin_lions": {"n": "Twin Lions of the Jade Gate", "elem": "earth", "weak": "wood", "col": Color("40b090"), "shape": "beast", "boss": true},
	"ink_dragon": {"n": "Ink Dragon", "elem": "dark", "weak": "water", "col": Color("2a2a3a"), "shape": "dragon", "boss": true},
	"debt_magistrate": {"n": "Magistrate of Debts", "elem": "dark", "weak": "fire", "col": Color("6a2a4a"), "shape": "demon", "boss": true},
	"registrar_siming": {"n": "Grand Registrar Si Ming", "elem": "earth", "weak": "wood", "col": Color("e0d0a0"), "shape": "humanoid", "boss": true},
	"brass_engine": {"n": "Brass Spider Engine", "elem": "earth", "weak": "water", "col": Color("d0a050"), "shape": "spider", "boss": true},
	"crucible_golem": {"n": "Crucible Golem", "elem": "fire", "weak": "water", "col": Color("e06020"), "shape": "golem", "boss": true},
	"bellows_phoenix": {"n": "Phoenix of the Bellows", "elem": "fire", "weak": "water", "col": Color("ffa030"), "shape": "phoenix", "boss": true},
	"forge_tiangong": {"n": "Forge-Lord Tian Gong", "elem": "thunder", "weak": "earth", "col": Color("e0b060"), "shape": "demon", "boss": true},
	"peach_tree": {"n": "Ten-Thousand-Year Peach Tree", "elem": "wood", "weak": "fire", "col": Color("ff90b0"), "shape": "plant", "boss": true},
	"crane_matriarch": {"n": "Jade Crane Matriarch", "elem": "water", "weak": "thunder", "col": Color("d8fff0"), "shape": "bird", "boss": true},
	"the_nineteen": {"n": "The Nineteen", "elem": "dark", "weak": "thunder", "col": Color("a0b8e0"), "shape": "wraith", "boss": true},
	"jade_ledger": {"n": "The Jade Ledger", "elem": "dark", "weak": "thunder", "col": Color("40c090"), "shape": "tome", "boss": true},
	# ---- Part V monsters
	"dune_scorpion": {"n": "Dune Scorpion", "elem": "earth", "weak": "wood", "col": Color("d8b070"), "shape": "scorpion"},
	"sand_wraith": {"n": "Sand Wraith", "elem": "earth", "weak": "water", "col": Color("e0c890"), "shape": "wraith"},
	"meteor_golem": {"n": "Meteorite Golem", "elem": "fire", "weak": "water", "col": Color("7a6ac0"), "shape": "golem"},
	"spore_puff": {"n": "Spore Puff", "elem": "wood", "weak": "fire", "col": Color("e080c0"), "shape": "mushroom"},
	"glow_moth": {"n": "Glow Moth", "elem": "fire", "weak": "water", "col": Color("ffd080"), "shape": "moth"},
	"root_crawler": {"n": "Root Crawler", "elem": "earth", "weak": "wood", "col": Color("8a6a40"), "shape": "spider"},
	"frost_yak": {"n": "Frost Yak", "elem": "water", "weak": "fire", "col": Color("b0c8e0"), "shape": "mammoth"},
	"aurora_wisp": {"n": "Aurora Wisp", "elem": "thunder", "weak": "earth", "col": Color("80ffd0"), "shape": "wisp"},
	"ice_lynx": {"n": "Ice Lynx", "elem": "water", "weak": "thunder", "col": Color("c8e0f8"), "shape": "beast"},
	"chaos_eel": {"n": "Chaos Eel", "elem": "dark", "weak": "thunder", "col": Color("8040c0"), "shape": "serpent"},
	"primal_jelly": {"n": "Primal Jelly", "elem": "dark", "weak": "fire", "col": Color("c060ff"), "shape": "jelly"},
	"faceless_spawn": {"n": "Faceless Spawn", "elem": "dark", "weak": "fire", "col": Color("c04030"), "shape": "hundun"},
	# ---- Part V bosses
	"glass_scorpion": {"n": "Glass Scorpion King", "elem": "earth", "weak": "wood", "col": Color("e8d8a0"), "shape": "scorpion", "boss": true},
	"dune_leviathan": {"n": "Dune Leviathan", "elem": "earth", "weak": "wood", "col": Color("c8a060"), "shape": "dragon", "boss": true},
	"star_colossus": {"n": "Star-Iron Colossus", "elem": "fire", "weak": "water", "col": Color("8a7ae0"), "shape": "golem", "boss": true},
	"white_tiger": {"n": "Bai Hu, White Tiger of the West", "elem": "earth", "weak": "fire", "col": Color("f4f4ff"), "shape": "beast", "boss": true},
	"spore_mother": {"n": "Mother of Spores", "elem": "wood", "weak": "fire", "col": Color("c070e0"), "shape": "mushroom", "boss": true},
	"moth_queen": {"n": "Lantern Moth Queen", "elem": "fire", "weak": "water", "col": Color("ffb040"), "shape": "moth", "boss": true},
	"rot_hydra": {"n": "Rot-Root Hydra", "elem": "wood", "weak": "fire", "col": Color("6a8a40"), "shape": "serpent", "boss": true},
	"vermilion_bird": {"n": "Zhu Que, Vermilion Bird of the South", "elem": "fire", "weak": "water", "col": Color("ff4030"), "shape": "phoenix", "boss": true},
	"mammoth_ancestor": {"n": "Mammoth Ancestor", "elem": "water", "weak": "fire", "col": Color("a0b8d0"), "shape": "mammoth", "boss": true},
	"aurora_serpent": {"n": "Aurora Serpent", "elem": "thunder", "weak": "earth", "col": Color("60f0c0"), "shape": "dragon", "boss": true},
	"lynx_matriarch": {"n": "Frost Lynx Matriarch", "elem": "water", "weak": "thunder", "col": Color("d0e8ff"), "shape": "beast", "boss": true},
	"black_tortoise": {"n": "Xuan Wu, Black Tortoise of the North", "elem": "water", "weak": "earth", "col": Color("3a4a6a"), "shape": "tortoise", "boss": true},
	"first_lightning": {"n": "The First Lightning", "elem": "thunder", "weak": "earth", "col": Color("f0f0ff"), "shape": "storm", "boss": true},
	"pangu_shadow": {"n": "Shadow of Pangu", "elem": "earth", "weak": "wood", "col": Color("6a5040"), "shape": "demon", "boss": true},
	"ancestor_took": {"n": "The Ancestor Who Took", "elem": "dark", "weak": "thunder", "col": Color("402050"), "shape": "humanoid", "boss": true},
	"hundun": {"n": "Hundun, the Faceless Chaos", "elem": "dark", "weak": "thunder", "col": Color("e05030"), "shape": "hundun", "boss": true},
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

## Build the foe list for a battle.  Each foe gets an explicit stage slot: Array.find() compares
## dictionaries by value, so two identical foes (same species, level and HP) used to resolve to
## the same index and were drawn on top of each other.
static func make_foes(foe_list: Array) -> Array:
	var out: Array = []
	for f in foe_list:
		var fo := make_enemy(f.id, f.lv, f.get("mult", 1.0))
		fo["slot"] = out.size()
		out.append(fo)
	return out

## Stage position of a foe in battle.
static func foe_pos(slot: int, count: int, boss: bool) -> Vector3:
	if boss or count == 1:
		return Vector3(6.0, 0, 0)
	return Vector3(5.0 + (slot % 2) * 2.2, 0, (slot - (count - 1) * 0.5) * 3.6)

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
		"portals": [
			{"to": "bamboo", "pos": Vector2i(38, 13), "dest": Vector2i(4, 22), "open": ""},
			{"to": "mirror", "pos": Vector2i(20, 24), "dest": Vector2i(4, 28), "open": "s_p3_home"},
			{"to": "cloudsea", "pos": Vector2i(1, 13), "dest": Vector2i(4, 28), "open": "s_p4_home"},
			{"to": "dunes", "pos": Vector2i(38, 22), "dest": Vector2i(4, 28), "open": "s_p5_home"},
		],
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
		"npcs": [{"id": "fire_sage", "n": "Sage Huo Rong", "pos": Vector2i(10, 26), "col": Color("ff9a5a"), "vis": ["s_vo_intro", ""]}],
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
	"mirror": {
		"n": "Mirror Lake of Echoes", "w": 92, "h": 56, "seed": 111, "theme": "mirror", "enemies": 18,
		"pool": [["mirror_wisp", 18, 19], ["glass_sentinel", 18, 19], ["echo_shade", 18, 19]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 28), "dest": Vector2i(20, 22), "open": ""},
			{"to": "grave", "pos": Vector2i(90, 28), "dest": Vector2i(4, 28), "open": "s_ml_xumo"},
		],
		"npcs": [{"id": "lake_keeper", "n": "Keeper Lan Jing", "pos": Vector2i(10, 26), "col": Color("a8e0ff"), "vis": ["s_ml_intro", ""]}],
		"bosses": [
			{"id": "shard_mimic", "pos": Vector2i(32, 14), "lv": 18, "req": 18},
			{"id": "glass_colossus", "pos": Vector2i(44, 30), "lv": 18, "req": 18},
			{"id": "drowned_bearer", "pos": Vector2i(56, 44), "lv": 19, "req": 19},
			{"id": "echo_xumo", "pos": Vector2i(80, 26), "lv": 19, "req": 19},
		],
		"pickups": [
			{"id": "echo1", "item": "echo", "pos": Vector2i(22, 44)}, {"id": "echo2", "item": "echo", "pos": Vector2i(40, 10)},
			{"id": "echo3", "item": "echo", "pos": Vector2i(62, 14)}, {"id": "echo4", "item": "echo", "pos": Vector2i(72, 46)},
		],
		"pickup_vis": "s_ml_collect",
	},
	"grave": {
		"n": "Graveyard of Sword Saints", "w": 94, "h": 56, "seed": 121, "theme": "grave", "enemies": 18,
		"pool": [["grave_hound", 19, 20], ["bone_knight", 19, 20], ["ghost_lantern", 19, 20]],
		"portals": [
			{"to": "mirror", "pos": Vector2i(1, 28), "dest": Vector2i(86, 28), "open": ""},
			{"to": "time", "pos": Vector2i(92, 28), "dest": Vector2i(4, 28), "open": "s_break7"},
		],
		"npcs": [{"id": "grave_keeper", "n": "Gravekeeper Mu Gu", "pos": Vector2i(10, 26), "col": Color("b8b8c8"), "vis": ["s_gv_intro", ""]}],
		"bosses": [
			{"id": "bone_wyrm", "pos": Vector2i(34, 40), "lv": 19, "req": 19},
			{"id": "headless_saint", "pos": Vector2i(48, 22), "lv": 20, "req": 20},
			{"id": "grave_empress", "pos": Vector2i(60, 12), "lv": 20, "req": 20},
			{"id": "founder_qing", "pos": Vector2i(82, 30), "lv": 20, "req": 20},
		],
		"pickups": [
			{"id": "relic1", "item": "relic", "pos": Vector2i(20, 12)}, {"id": "relic2", "item": "relic", "pos": Vector2i(42, 46)},
			{"id": "relic3", "item": "relic", "pos": Vector2i(66, 30)}, {"id": "relic4", "item": "relic", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_gv_collect",
	},
	"time": {
		"n": "River of Ten Thousand Years", "w": 96, "h": 58, "seed": 131, "theme": "time", "enemies": 20,
		"pool": [["hourglass_wraith", 21, 22], ["clockwork_guard", 21, 22], ["dust_moth", 21, 22]],
		"portals": [
			{"to": "grave", "pos": Vector2i(1, 28), "dest": Vector2i(88, 28), "open": ""},
			{"to": "origin", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_tm_tianxuan"},
		],
		"npcs": [{"id": "time_ferryman", "n": "Ferryman Shi Guang", "pos": Vector2i(10, 26), "col": Color("f0d080"), "vis": ["s_tm_intro", ""]}],
		"bosses": [
			{"id": "time_tortoise", "pos": Vector2i(30, 14), "lv": 21, "req": 21},
			{"id": "dusk_reaper", "pos": Vector2i(42, 32), "lv": 22, "req": 22},
			{"id": "dawn_warden", "pos": Vector2i(54, 44), "lv": 22, "req": 22},
			{"id": "young_tianxuan", "pos": Vector2i(84, 26), "lv": 22, "req": 22},
		],
		"pickups": [
			{"id": "sand1", "item": "sand", "pos": Vector2i(24, 46)}, {"id": "sand2", "item": "sand", "pos": Vector2i(44, 12)},
			{"id": "sand3", "item": "sand", "pos": Vector2i(66, 40)}, {"id": "sand4", "item": "sand", "pos": Vector2i(78, 12)},
		],
		"pickup_vis": "s_tm_collect",
	},
	"origin": {
		"n": "Origin of the Dao", "w": 98, "h": 58, "seed": 141, "theme": "origin", "enemies": 20,
		"pool": [["maw_tendril", 22, 23], ["hollow_acolyte", 22, 23], ["dao_fragment", 22, 23]],
		"portals": [{"to": "time", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""}],
		"npcs": [{"id": "origin_keeper", "n": "Bai Ze, Keeper of the Origin", "pos": Vector2i(10, 26), "col": Color("fff0b0"), "vis": ["s_or_intro", ""]}],
		"bosses": [
			{"id": "maw_herald", "pos": Vector2i(32, 40), "lv": 22, "req": 22},
			{"id": "hollow_dragon", "pos": Vector2i(46, 28), "lv": 23, "req": 23},
			{"id": "harvest_avatar", "pos": Vector2i(58, 14), "lv": 23, "req": 23},
			{"id": "hollow_heaven", "pos": Vector2i(88, 28), "lv": 23, "req": 23},
		],
		"pickups": [
			{"id": "rune1", "item": "rune", "pos": Vector2i(22, 12)}, {"id": "rune2", "item": "rune", "pos": Vector2i(40, 46)},
			{"id": "rune3", "item": "rune", "pos": Vector2i(64, 40)}, {"id": "rune4", "item": "rune", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_or_collect",
	},
	# ---- Part IV: The Unwritten Ledger
	"cloudsea": {
		"n": "Sea of Clouds Archipelago", "w": 94, "h": 56, "seed": 151, "theme": "cloudsea", "enemies": 20,
		"pool": [["cloud_ray", 24, 25], ["gale_sprite", 24, 25], ["sky_mantis", 24, 25]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 28), "dest": Vector2i(2, 13), "open": ""},
			{"to": "court", "pos": Vector2i(92, 28), "dest": Vector2i(4, 28), "open": "s_cs_herald"},
		],
		"npcs": [{"id": "cloud_warden", "n": "Cloud Warden Feng Yu", "pos": Vector2i(10, 26), "col": Color("e0f0ff"), "vis": ["s_cs_intro", ""]}],
		"bosses": [
			{"id": "manta_sovereign", "pos": Vector2i(30, 14), "lv": 24, "req": 24},
			{"id": "gale_mantis", "pos": Vector2i(44, 34), "lv": 24, "req": 24},
			{"id": "rainbow_serpent", "pos": Vector2i(58, 44), "lv": 25, "req": 24},
			{"id": "herald_qian", "pos": Vector2i(84, 26), "lv": 25, "req": 24},
		],
		"pickups": [
			{"id": "cfeather1", "item": "feather_cloud", "pos": Vector2i(22, 44)}, {"id": "cfeather2", "item": "feather_cloud", "pos": Vector2i(40, 10)},
			{"id": "cfeather3", "item": "feather_cloud", "pos": Vector2i(64, 14)}, {"id": "cfeather4", "item": "feather_cloud", "pos": Vector2i(74, 46)},
		],
		"pickup_vis": "s_cs_collect",
	},
	"court": {
		"n": "Ruins of the Jade Court", "w": 96, "h": 58, "seed": 161, "theme": "court", "enemies": 20,
		"pool": [["ledger_clerk", 25, 25], ["jade_lion", 24, 25], ["ink_wraith", 25, 25]],
		"portals": [
			{"to": "cloudsea", "pos": Vector2i(1, 28), "dest": Vector2i(88, 28), "open": ""},
			{"to": "forge", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_ct_siming"},
		],
		"npcs": [{"id": "court_scribe", "n": "Scribe Wen Yu", "pos": Vector2i(10, 26), "col": Color("c8f0e0"), "vis": ["s_ct_intro", ""]}],
		"bosses": [
			{"id": "twin_lions", "pos": Vector2i(30, 40), "lv": 25, "req": 25},
			{"id": "ink_dragon", "pos": Vector2i(46, 16), "lv": 25, "req": 25},
			{"id": "debt_magistrate", "pos": Vector2i(60, 40), "lv": 25, "req": 25},
			{"id": "registrar_siming", "pos": Vector2i(86, 28), "lv": 25, "req": 25},
		],
		"pickups": [
			{"id": "jseal1", "item": "seal", "pos": Vector2i(20, 12)}, {"id": "jseal2", "item": "seal", "pos": Vector2i(40, 46)},
			{"id": "jseal3", "item": "seal", "pos": Vector2i(66, 30)}, {"id": "jseal4", "item": "seal", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_ct_collect",
	},
	"forge": {
		"n": "Heaven's Forge", "w": 96, "h": 58, "seed": 171, "theme": "forge", "enemies": 20,
		"pool": [["bronze_sentinel", 25, 26], ["slag_slime", 25, 26], ["bellows_imp", 25, 26]],
		"portals": [
			{"to": "court", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "garden", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_fg_tiangong"},
		],
		"npcs": [{"id": "forge_master", "n": "Forgemaster Ou Lan", "pos": Vector2i(10, 26), "col": Color("d89060"), "vis": ["s_fg_intro", ""]}],
		"bosses": [
			{"id": "brass_engine", "pos": Vector2i(32, 14), "lv": 25, "req": 25},
			{"id": "crucible_golem", "pos": Vector2i(44, 32), "lv": 26, "req": 26},
			{"id": "bellows_phoenix", "pos": Vector2i(58, 46), "lv": 26, "req": 26},
			{"id": "forge_tiangong", "pos": Vector2i(86, 26), "lv": 26, "req": 26},
		],
		"pickups": [
			{"id": "ingot1", "item": "ingot", "pos": Vector2i(24, 46)}, {"id": "ingot2", "item": "ingot", "pos": Vector2i(44, 12)},
			{"id": "ingot3", "item": "ingot", "pos": Vector2i(66, 40)}, {"id": "ingot4", "item": "ingot", "pos": Vector2i(78, 12)},
		],
		"pickup_vis": "s_fg_collect",
	},
	"garden": {
		"n": "Garden of Immortal Peaches", "w": 98, "h": 58, "seed": 181, "theme": "garden", "enemies": 20,
		"pool": [["peach_sprite", 26, 26], ["garden_crane", 26, 26], ["moss_tortoise", 26, 26]],
		"portals": [{"to": "forge", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""}],
		"npcs": [{"id": "peach_keeper", "n": "Peach Keeper Tao Yao", "pos": Vector2i(10, 26), "col": Color("ffd0e0"), "vis": ["s_gd_intro", ""]}],
		"bosses": [
			{"id": "peach_tree", "pos": Vector2i(32, 40), "lv": 26, "req": 26},
			{"id": "crane_matriarch", "pos": Vector2i(46, 16), "lv": 26, "req": 26},
			{"id": "the_nineteen", "pos": Vector2i(60, 40), "lv": 26, "req": 26},
			{"id": "jade_ledger", "pos": Vector2i(88, 28), "lv": 26, "req": 26},
		],
		"pickups": [
			{"id": "peach1", "item": "peach", "pos": Vector2i(22, 12)}, {"id": "peach2", "item": "peach", "pos": Vector2i(40, 46)},
			{"id": "peach3", "item": "peach", "pos": Vector2i(64, 30)}, {"id": "peach4", "item": "peach", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_gd_collect",
	},
	# ---- Part V: The Falling Sky
	"dunes": {
		"n": "Desert of Fallen Stars", "w": 96, "h": 58, "seed": 191, "theme": "dunes", "enemies": 20,
		"pool": [["dune_scorpion", 27, 27], ["sand_wraith", 27, 27], ["meteor_golem", 27, 27]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 28), "dest": Vector2i(36, 22), "open": ""},
			{"to": "fungal", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_du_tiger"},
		],
		"npcs": [{"id": "nomad", "n": "Nomad Matriarch Ba Yin", "pos": Vector2i(10, 26), "col": Color("e8c890"), "vis": ["s_du_intro", ""]}],
		"bosses": [
			{"id": "glass_scorpion", "pos": Vector2i(30, 40), "lv": 27, "req": 27},
			{"id": "dune_leviathan", "pos": Vector2i(46, 16), "lv": 27, "req": 27},
			{"id": "star_colossus", "pos": Vector2i(60, 40), "lv": 27, "req": 27},
			{"id": "white_tiger", "pos": Vector2i(86, 28), "lv": 27, "req": 27},
		],
		"pickups": [
			{"id": "fstar1", "item": "fallen_star", "pos": Vector2i(22, 12)}, {"id": "fstar2", "item": "fallen_star", "pos": Vector2i(40, 46)},
			{"id": "fstar3", "item": "fallen_star", "pos": Vector2i(64, 30)}, {"id": "fstar4", "item": "fallen_star", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_du_collect",
	},
	"fungal": {
		"n": "Glowcap Vale", "w": 96, "h": 58, "seed": 201, "theme": "fungal", "enemies": 20,
		"pool": [["spore_puff", 27, 28], ["glow_moth", 27, 28], ["root_crawler", 27, 28]],
		"portals": [
			{"to": "dunes", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "aurora", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_fu_bird"},
		],
		"npcs": [{"id": "spore_witch", "n": "Spore-Witch Mo Gu", "pos": Vector2i(10, 26), "col": Color("c8a0e0"), "vis": ["s_fu_intro", ""]}],
		"bosses": [
			{"id": "spore_mother", "pos": Vector2i(32, 14), "lv": 27, "req": 27},
			{"id": "moth_queen", "pos": Vector2i(44, 34), "lv": 28, "req": 28},
			{"id": "rot_hydra", "pos": Vector2i(58, 46), "lv": 28, "req": 28},
			{"id": "vermilion_bird", "pos": Vector2i(86, 26), "lv": 28, "req": 28},
		],
		"pickups": [
			{"id": "gcap1", "item": "glowcap", "pos": Vector2i(22, 12)}, {"id": "gcap2", "item": "glowcap", "pos": Vector2i(40, 46)},
			{"id": "gcap3", "item": "glowcap", "pos": Vector2i(64, 30)}, {"id": "gcap4", "item": "glowcap", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_fu_collect",
	},
	"aurora": {
		"n": "Aurora Steppe", "w": 96, "h": 58, "seed": 211, "theme": "aurora", "enemies": 20,
		"pool": [["frost_yak", 28, 28], ["aurora_wisp", 28, 28], ["ice_lynx", 28, 29]],
		"portals": [
			{"to": "fungal", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "chaos", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_au_tortoise"},
		],
		"npcs": [{"id": "steppe_shaman", "n": "Steppe Shaman A Lan", "pos": Vector2i(10, 26), "col": Color("d0f0ff"), "vis": ["s_au_intro", ""]}],
		"bosses": [
			{"id": "mammoth_ancestor", "pos": Vector2i(30, 40), "lv": 28, "req": 28},
			{"id": "aurora_serpent", "pos": Vector2i(46, 16), "lv": 28, "req": 28},
			{"id": "lynx_matriarch", "pos": Vector2i(60, 40), "lv": 29, "req": 29},
			{"id": "black_tortoise", "pos": Vector2i(86, 28), "lv": 29, "req": 29},
		],
		"pickups": [
			{"id": "ashard1", "item": "aurora_shard", "pos": Vector2i(22, 12)}, {"id": "ashard2", "item": "aurora_shard", "pos": Vector2i(40, 46)},
			{"id": "ashard3", "item": "aurora_shard", "pos": Vector2i(64, 30)}, {"id": "ashard4", "item": "aurora_shard", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_au_collect",
	},
	"chaos": {
		"n": "Primordial Chaos", "w": 98, "h": 58, "seed": 221, "theme": "chaos", "enemies": 20,
		"pool": [["chaos_eel", 29, 29], ["primal_jelly", 29, 29], ["faceless_spawn", 29, 29]],
		"portals": [
			{"to": "aurora", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
		],
		"npcs": [{"id": "nuwa_echo", "n": "Echo of Nuwa", "pos": Vector2i(10, 26), "col": Color("fff0d8"), "vis": ["s_ch_intro", ""]}],
		"bosses": [
			{"id": "first_lightning", "pos": Vector2i(32, 40), "lv": 29, "req": 29},
			{"id": "pangu_shadow", "pos": Vector2i(46, 16), "lv": 29, "req": 29},
			{"id": "ancestor_took", "pos": Vector2i(60, 40), "lv": 29, "req": 29},
			{"id": "hundun", "pos": Vector2i(88, 28), "lv": 29, "req": 29},
		],
		"pickups": [
			{"id": "fivest1", "item": "five_stone", "pos": Vector2i(22, 12)}, {"id": "fivest2", "item": "five_stone", "pos": Vector2i(40, 46)},
			{"id": "fivest3", "item": "five_stone", "pos": Vector2i(64, 30)}, {"id": "fivest4", "item": "five_stone", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_ch_collect",
	},
}

const AREA_CHAIN := ["sect", "bamboo", "marsh", "frost", "thunder", "palace", "dragon", "volcano", "void", "celestial", "mirror", "grave", "time", "origin", "cloudsea", "court", "forge", "garden", "dunes", "fungal", "aurora", "chaos"]

## next area to enter when travelling from `from` to `to` (breadth-first over portals)
static func next_hop(from: String, to: String) -> String:
	if from == to:
		return from
	var prev := {from: ""}
	var q: Array = [from]
	var i := 0
	while i < q.size():
		var c: String = q[i]
		i += 1
		for p in AREAS[c].get("portals", []):
			if not prev.has(p.to):
				prev[p.to] = c
				q.append(p.to)
	if not prev.has(to):
		return ""
	var cur := to
	while prev[cur] != from:
		cur = prev[cur]
	return cur

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
	{"id": "s_vo_intro", "kind": "talk", "npc": "fire_sage", "area": "volcano", "t": "Find Sage Huo Rong in the Ashen Volcano"},
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
	# ---- Part III: The Hollow Heaven
	{"id": "s_p3_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "The Lotus Seal has called you home: speak to Elder Qing Xuan", "stones": 1500},
	{"id": "s_ml_intro", "kind": "talk", "npc": "lake_keeper", "area": "mirror", "t": "Seek the Keeper of the Mirror Lake through the Lotus Gate"},
	{"id": "s_ml_collect", "kind": "collect", "item": "echo", "n": 4, "area": "mirror", "t": "Gather 4 Echo Shards from the lake"},
	{"id": "s_ml_hunt", "kind": "hunt", "area": "mirror", "n": 30, "t": "Shatter the reflections prowling the Mirror Lake"},
	{"id": "s_ml_mimic", "kind": "kill", "boss": "shard_mimic", "area": "mirror", "t": "Break the Shard Mimic"},
	{"id": "s_ml_colossus", "kind": "kill", "boss": "glass_colossus", "area": "mirror", "t": "Topple the Glass Colossus"},
	{"id": "s_ml_drowned", "kind": "kill", "boss": "drowned_bearer", "area": "mirror", "t": "Lay the Drowned Bearer to rest"},
	{"id": "s_ml_xumo", "kind": "kill", "boss": "echo_xumo", "area": "mirror", "t": "Face the Echo of Xu Mo", "stones": 1800},
	{"id": "s_gv_intro", "kind": "talk", "npc": "grave_keeper", "area": "grave", "t": "Find the Gravekeeper in the Graveyard of Sword Saints"},
	{"id": "s_gv_collect", "kind": "collect", "item": "relic", "n": 4, "area": "grave", "t": "Recover 4 Saint Relics from the barrows"},
	{"id": "s_gv_hunt", "kind": "hunt", "area": "grave", "n": 30, "t": "Put the restless dead to sleep"},
	{"id": "s_gv_wyrm", "kind": "kill", "boss": "bone_wyrm", "area": "grave", "t": "Break the Bone Wyrm"},
	{"id": "s_gv_saint", "kind": "kill", "boss": "headless_saint", "area": "grave", "t": "Duel the Headless Sword Saint"},
	{"id": "s_gv_empress", "kind": "kill", "boss": "grave_empress", "area": "grave", "t": "Dethrone the Empress of Bones"},
	{"id": "s_gv_founder", "kind": "kill", "boss": "founder_qing", "area": "grave", "t": "Earn the blessing of Founder Qing Lian", "stones": 2000},
	{"id": "s_break7", "kind": "breakthrough", "to": 21, "t": "Break through to Mahayana"},
	{"id": "s_tm_intro", "kind": "talk", "npc": "time_ferryman", "area": "time", "t": "Board the ferry of the River of Ten Thousand Years"},
	{"id": "s_tm_collect", "kind": "collect", "item": "sand", "n": 4, "area": "time", "t": "Gather 4 pinches of Time Sand"},
	{"id": "s_tm_hunt", "kind": "hunt", "area": "time", "n": 32, "t": "Stop the stray moments hunting along the river"},
	{"id": "s_tm_tortoise", "kind": "kill", "boss": "time_tortoise", "area": "time", "t": "Outlast the Eon Tortoise"},
	{"id": "s_tm_reaper", "kind": "kill", "boss": "dusk_reaper", "area": "time", "t": "Cut down the Dusk Reaper"},
	{"id": "s_tm_warden", "kind": "kill", "boss": "dawn_warden", "area": "time", "t": "Quiet the Dawn Warden"},
	{"id": "s_tm_tianxuan", "kind": "kill", "boss": "young_tianxuan", "area": "time", "t": "Meet the First Sweeper at the river's source", "stones": 2400},
	{"id": "s_or_intro", "kind": "talk", "npc": "origin_keeper", "area": "origin", "t": "Speak to the Keeper at the Origin of the Dao"},
	{"id": "s_or_collect", "kind": "collect", "item": "rune", "n": 4, "area": "origin", "t": "Gather 4 Origin Runes"},
	{"id": "s_or_hunt", "kind": "hunt", "area": "origin", "n": 32, "t": "Cut back the Hollow Heaven's spreading roots"},
	{"id": "s_or_herald", "kind": "kill", "boss": "maw_herald", "area": "origin", "t": "Silence the Maw Herald"},
	{"id": "s_or_dragon", "kind": "kill", "boss": "hollow_dragon", "area": "origin", "t": "Slay the Hollow Heaven Dragon"},
	{"id": "s_or_avatar", "kind": "kill", "boss": "harvest_avatar", "area": "origin", "t": "Overturn the Avatar of the Harvest"},
	{"id": "s_or_heaven", "kind": "kill", "boss": "hollow_heaven", "area": "origin", "t": "Confront the Hollow Heaven itself", "stones": 3000},
	{"id": "s_break8", "kind": "breakthrough", "to": 24, "t": "Ascend beyond all tribulation as a True Immortal"},
	# ---- Part IV: The Unwritten Ledger
	{"id": "s_p4_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "Names are being written across the sky: speak to Elder Qing Xuan", "stones": 3500},
	{"id": "s_cs_intro", "kind": "talk", "npc": "cloud_warden", "area": "cloudsea", "t": "Cross the West Gate into the Sea of Clouds and find its Warden"},
	{"id": "s_cs_collect", "kind": "collect", "item": "feather_cloud", "n": 4, "area": "cloudsea", "t": "Gather 4 Cloud Feathers to weave a cloud-step"},
	{"id": "s_cs_hunt", "kind": "hunt", "area": "cloudsea", "n": 42, "t": "Drive the Ledger's tithe-collectors from the islands"},
	{"id": "s_cs_weave", "kind": "talk", "npc": "cloud_warden", "area": "cloudsea", "t": "Bring the Cloud Feathers to Warden Feng Yu"},
	{"id": "s_cs_manta", "kind": "kill", "boss": "manta_sovereign", "area": "cloudsea", "t": "Ground the Sky Manta Sovereign"},
	{"id": "s_cs_mantis", "kind": "kill", "boss": "gale_mantis", "area": "cloudsea", "t": "Still the Gale Mantis Empress"},
	{"id": "s_cs_serpent", "kind": "kill", "boss": "rainbow_serpent", "area": "cloudsea", "t": "Unbind the Rainbow Serpent"},
	{"id": "s_cs_herald", "kind": "kill", "boss": "herald_qian", "area": "cloudsea", "t": "Stop the Herald of the Ledger, Qian Shu", "stones": 3800},
	{"id": "s_ct_intro", "kind": "talk", "npc": "court_scribe", "area": "court", "t": "Find the runaway scribe in the Ruins of the Jade Court"},
	{"id": "s_ct_collect", "kind": "collect", "item": "seal", "n": 4, "area": "court", "t": "Recover 4 Jade Seals of the old Court"},
	{"id": "s_ct_hunt", "kind": "hunt", "area": "court", "n": 42, "t": "Scatter the clerks still stamping debts"},
	{"id": "s_ct_stamp", "kind": "talk", "npc": "court_scribe", "area": "court", "t": "Take the Jade Seals to Scribe Wen Yu"},
	{"id": "s_ct_lions", "kind": "kill", "boss": "twin_lions", "area": "court", "t": "Pass the Twin Lions of the Jade Gate"},
	{"id": "s_ct_inkdragon", "kind": "kill", "boss": "ink_dragon", "area": "court", "t": "Wash away the Ink Dragon"},
	{"id": "s_ct_magistrate", "kind": "kill", "boss": "debt_magistrate", "area": "court", "t": "Overrule the Magistrate of Debts"},
	{"id": "s_ct_siming", "kind": "kill", "boss": "registrar_siming", "area": "court", "t": "Confront Grand Registrar Si Ming", "stones": 4200},
	{"id": "s_fg_intro", "kind": "talk", "npc": "forge_master", "area": "forge", "t": "Seek Forgemaster Ou Lan in Heaven's Forge"},
	{"id": "s_fg_collect", "kind": "collect", "item": "ingot", "n": 4, "area": "forge", "t": "Gather 4 Star-Iron Ingots for the unwriting brush"},
	{"id": "s_fg_hunt", "kind": "hunt", "area": "forge", "n": 44, "t": "Quench the forge-spawn still hammering out lightning"},
	{"id": "s_fg_reforge", "kind": "talk", "npc": "forge_master", "area": "forge", "t": "Bring the Star-Iron and the broken brush to Ou Lan"},
	{"id": "s_fg_engine", "kind": "kill", "boss": "brass_engine", "area": "forge", "t": "Dismantle the Brass Spider Engine"},
	{"id": "s_fg_crucible", "kind": "kill", "boss": "crucible_golem", "area": "forge", "t": "Crack the Crucible Golem"},
	{"id": "s_fg_bellows", "kind": "kill", "boss": "bellows_phoenix", "area": "forge", "t": "Calm the Phoenix of the Bellows"},
	{"id": "s_fg_tiangong", "kind": "kill", "boss": "forge_tiangong", "area": "forge", "t": "Defeat Forge-Lord Tian Gong", "stones": 4600},
	{"id": "s_gd_intro", "kind": "talk", "npc": "peach_keeper", "area": "garden", "t": "Enter the Garden of Immortal Peaches and greet its Keeper"},
	{"id": "s_gd_collect", "kind": "collect", "item": "peach", "n": 4, "area": "garden", "t": "Pick 4 Immortal Peaches for the nineteen bearers"},
	{"id": "s_gd_hunt", "kind": "hunt", "area": "garden", "n": 44, "t": "Weed out the garden's ledger-bound guardians"},
	{"id": "s_gd_offer", "kind": "talk", "npc": "peach_keeper", "area": "garden", "t": "Bring the Immortal Peaches to Keeper Tao Yao"},
	{"id": "s_gd_tree", "kind": "kill", "boss": "peach_tree", "area": "garden", "t": "Wake the Ten-Thousand-Year Peach Tree"},
	{"id": "s_gd_crane", "kind": "kill", "boss": "crane_matriarch", "area": "garden", "t": "Win the Jade Crane Matriarch's trust"},
	{"id": "s_gd_nineteen", "kind": "kill", "boss": "the_nineteen", "area": "garden", "t": "Free the Nineteen from their names"},
	{"id": "s_gd_ledger", "kind": "kill", "boss": "jade_ledger", "area": "garden", "t": "Close the Jade Ledger forever", "stones": 5000},
	{"id": "s_break9", "kind": "breakthrough", "to": 27, "t": "Become the first Dao Ancestor who takes nothing"},
	# ---- Part V: The Falling Sky
	{"id": "s_p5_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "Stars are falling in daylight: speak to Elder Qing Xuan", "stones": 5500},
	{"id": "s_du_intro", "kind": "talk", "npc": "nomad", "area": "dunes", "t": "Take the south-east road into the Desert of Fallen Stars and find the nomads"},
	{"id": "s_du_collect", "kind": "collect", "item": "fallen_star", "n": 4, "area": "dunes", "t": "Gather 4 Fallen Star Fragments from the craters"},
	{"id": "s_du_hunt", "kind": "hunt", "area": "dunes", "n": 46, "t": "Drive back the star-mad creatures of the dunes"},
	{"id": "s_du_return", "kind": "talk", "npc": "nomad", "area": "dunes", "t": "Bring the star fragments to Matriarch Ba Yin"},
	{"id": "s_du_scorpion", "kind": "kill", "boss": "glass_scorpion", "area": "dunes", "t": "Shatter the Glass Scorpion King"},
	{"id": "s_du_leviathan", "kind": "kill", "boss": "dune_leviathan", "area": "dunes", "t": "Bring down the Dune Leviathan"},
	{"id": "s_du_colossus", "kind": "kill", "boss": "star_colossus", "area": "dunes", "t": "Topple the Star-Iron Colossus"},
	{"id": "s_du_tiger", "kind": "kill", "boss": "white_tiger", "area": "dunes", "t": "Face Bai Hu at the foot of the Western Pillar", "stones": 5800},
	{"id": "s_fu_intro", "kind": "talk", "npc": "spore_witch", "area": "fungal", "t": "Enter Glowcap Vale and seek the Spore-Witch"},
	{"id": "s_fu_collect", "kind": "collect", "item": "glowcap", "n": 4, "area": "fungal", "t": "Pick 4 Ember Glowcaps"},
	{"id": "s_fu_hunt", "kind": "hunt", "area": "fungal", "n": 46, "t": "Clear the spore-choked paths of the vale"},
	{"id": "s_fu_return", "kind": "talk", "npc": "spore_witch", "area": "fungal", "t": "Bring the glowcaps to Mo Gu"},
	{"id": "s_fu_mother", "kind": "kill", "boss": "spore_mother", "area": "fungal", "t": "Calm the Mother of Spores"},
	{"id": "s_fu_moth", "kind": "kill", "boss": "moth_queen", "area": "fungal", "t": "Dim the Lantern Moth Queen"},
	{"id": "s_fu_hydra", "kind": "kill", "boss": "rot_hydra", "area": "fungal", "t": "Uproot the Rot-Root Hydra"},
	{"id": "s_fu_bird", "kind": "kill", "boss": "vermilion_bird", "area": "fungal", "t": "Rekindle Zhu Que at the Southern Pillar", "stones": 6200},
	{"id": "s_au_intro", "kind": "talk", "npc": "steppe_shaman", "area": "aurora", "t": "Cross onto the Aurora Steppe and find its shaman"},
	{"id": "s_au_collect", "kind": "collect", "item": "aurora_shard", "n": 4, "area": "aurora", "t": "Catch 4 Aurora Shards where the lights touch the snow"},
	{"id": "s_au_hunt", "kind": "hunt", "area": "aurora", "n": 46, "t": "Turn back the frozen herds stampeding south"},
	{"id": "s_au_return", "kind": "talk", "npc": "steppe_shaman", "area": "aurora", "t": "Bring the aurora shards to Shaman A Lan"},
	{"id": "s_au_mammoth", "kind": "kill", "boss": "mammoth_ancestor", "area": "aurora", "t": "Wake the Mammoth Ancestor"},
	{"id": "s_au_serpent", "kind": "kill", "boss": "aurora_serpent", "area": "aurora", "t": "Ground the Aurora Serpent"},
	{"id": "s_au_lynx", "kind": "kill", "boss": "lynx_matriarch", "area": "aurora", "t": "Outrun the Frost Lynx Matriarch"},
	{"id": "s_au_tortoise", "kind": "kill", "boss": "black_tortoise", "area": "aurora", "t": "Lift Xuan Wu back beneath the Northern Pillar", "stones": 6600},
	{"id": "s_ch_intro", "kind": "talk", "npc": "nuwa_echo", "area": "chaos", "t": "Step into the Primordial Chaos and follow the voice"},
	{"id": "s_ch_collect", "kind": "collect", "item": "five_stone", "n": 4, "area": "chaos", "t": "Gather 4 Five-Coloured Stones from the formless sea"},
	{"id": "s_ch_hunt", "kind": "hunt", "area": "chaos", "n": 48, "t": "Hold back the formless things gnawing at the sky's root"},
	{"id": "s_ch_return", "kind": "talk", "npc": "nuwa_echo", "area": "chaos", "t": "Bring the Five-Coloured Stones to the Echo of Nuwa"},
	{"id": "s_ch_lightning", "kind": "kill", "boss": "first_lightning", "area": "chaos", "t": "Answer the First Lightning"},
	{"id": "s_ch_pangu", "kind": "kill", "boss": "pangu_shadow", "area": "chaos", "t": "Lay the Shadow of Pangu to rest"},
	{"id": "s_ch_took", "kind": "kill", "boss": "ancestor_took", "area": "chaos", "t": "Refuse the Ancestor Who Took"},
	{"id": "s_ch_hundun", "kind": "kill", "boss": "hundun", "area": "chaos", "t": "Give a face to Hundun, the Faceless Chaos", "stones": 7000},
	{"id": "s_break10", "kind": "breakthrough", "to": 30, "t": "Hold up the sky by choice: become a Primordial Sovereign"},
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
	"echo": {"n": "Echo Shard", "desc": "Quest item"},
	"relic": {"n": "Saint Relic", "desc": "Quest item"},
	"sand": {"n": "Time Sand", "desc": "Quest item"},
	"rune": {"n": "Origin Rune", "desc": "Quest item"},
	"feather_cloud": {"n": "Cloud Feather", "desc": "Quest item"},
	"seal": {"n": "Jade Seal", "desc": "Quest item"},
	"ingot": {"n": "Star-Iron Ingot", "desc": "Quest item"},
	"peach": {"n": "Immortal Peach", "desc": "Quest item"},
	"fallen_star": {"n": "Fallen Star Fragment", "desc": "Quest item"},
	"glowcap": {"n": "Ember Glowcap", "desc": "Quest item"},
	"aurora_shard": {"n": "Aurora Shard", "desc": "Quest item"},
	"five_stone": {"n": "Five-Coloured Stone", "desc": "Quest item"},
	"feather": {"n": "Thunder Roc Feather", "desc": "Proof of the Roc's defeat"},
	"scale": {"n": "Dragon King's Scale", "desc": "Proof of the Dragon King's gratitude"},
	"brush": {"n": "Registrar's Broken Brush", "desc": "The brush that wrote the Ledger, snapped in two"},
}
const TEMPER_COST := [250, 700, 1500, 2800, 4500, 6500, 9000, 12000]
## keepsakes dropped by particular bosses (so later dialogue can point at them)
const BOSS_DROPS := {"thunder_roc": "feather", "dragon_king": "scale", "registrar_siming": "brush"}

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
	"lake_keeper": ["The lake never forgets a face. Not even the ones you would like it to.", "Do not trust any reflection that smiles first."],
	"grave_keeper": ["Every saint here swore to guard the Seal. Most kept the oath.", "The dead are patient. Be kind to them."],
	"time_ferryman": ["I ferry moments, not people. You are the first exception.", "Yesterday and tomorrow share one bank. Mind the current."],
	"origin_keeper": ["Everything begins here, and so does everything end.", "The Hollow Heaven is not evil. It is only hungry."],
	"cloud_warden": ["Step lightly. The islands remember every footfall.", "The clouds used to carry ascenders up. Now they carry tithes."],
	"court_scribe": ["I copied ten thousand names before I read one. Then I could not stop reading.", "Ink dries. Debts should too."],
	"forge_master": ["Lightning is only iron that learned to run.", "Every tribulation you endured was hammered on this anvil. I am sorry."],
	"nomad": ["The sand remembers every star that fell. Tonight it remembers too many.", "Water first, questions after. That is the desert's only law."],
	"spore_witch": ["Do not breathe too deeply, little immortal. The vale dreams through its spores.", "Everything that rots feeds something that glows."],
	"steppe_shaman": ["The lights are the sky's breath. Lately it is breathing too fast.", "Walk where the herds walk. They know which ice will hold."],
	"nuwa_echo": ["I am only what is left of a promise. Be kinder to it than I was.", "Before the world there was no up and no down. Do not let the sky forget which is which."],
	"peach_keeper": ["A peach of this garden ripens once in three thousand years. Do not waste it.", "The nineteen come here in their dreams. They like the shade."],
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
		["Elder Qing Xuan", "Bandits stalk that road, and a Jade Mantis Matriarch has claimed the herb groves as her own. Meditate to recover, buy pills from Mo, and temper your blade with Smith Tie."],
		["Lin Feng", "Understood. I will return with the herbs."],
	],
	"s_alchemist": [
		["Alchemist Mo", "Spirit Herbs! Four of them, fresh as dawn. You have the nose of a true cultivator."],
		["Alchemist Mo", "Take this payment. And hear this: the bandit chief Iron Fang holds a village girl in the deep bamboo."],
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
		["Iron Fang", "Hah! A sect boy with a rusty sword. Did the Azure Cloud run out of real disciples?"],
		["Lin Feng", "Release the girl, or I will cut you down."],
	],
	"post:iron_fang": [
		["Iron Fang", "Impossible... the Blood Moon... will remember..."],
	],
	"s_yue": [
		["Yue Ling", "You came! I am Yue Ling, a wandering healer. Iron Fang bound me when I refused to poison a well."],
		["Yue Ling", "I remember little before three winters ago, when I woke beside a lotus pond with only my name. Healing is the one thing my hands never forgot."],
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
		["Marsh Hag", "The Blood Moon... pays well... for the bearer of the Nine Heavens root... you cannot hide..."],
		["Lin Feng", "The root's bearer? Is that me?"],
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
		["Elder Qing Xuan", "A Frost Wyrm slumbers there. Bring four jades, and slay the beast and its brood if they block your path."],
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
		["Narrator", "A single storm-bright feather drifts down from the fallen Roc. Lin Feng tucks it into his sleeve."],
		["Ancestor Jian Wuchen", "Well fought. Take the Heaven-Cleaving Sword, my final gift. May it cleave even the heavens."],
		["Lin Feng", "I feel the technique awakening in my bones."],
	],
	"s_elder5": [
		["Elder Qing Xuan", "The Roc's feather, still crackling with thunder! Now the Seal sings again. Yet Xu Mo's army gathers at the Blood Moon Palace, beyond Thunder Valley."],
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
		["Demon Lord Xu Mo", "At last, the bearer of the Nine Heavens root walks into my hall. I have hunted your root, bearer after bearer, for three centuries."],
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
		["Azure Dragon King", "Who disturbs the tide? Ah... a mortal in my halls. The envoy's prophecy walks on two legs."],
		["Azure Dragon King", "I am sorry. I cannot hold the sea back any longer. Run, or fight me with everything you have!"],
	],
	"post:dragon_king": [
		["Azure Dragon King", "You freed me, and the pearls' light has washed the rot from my sea. The rift beneath the volcano feeds on the heavens. Take this scale of mine as proof, and find Sage Huo Rong in the Ashen Volcano."],
		["Yue Ling", "A dragon king in our debt. Not bad for a sweeper."],
	],
	"s_vo_intro": [
		["Sage Huo Rong", "You smell of salt and thunder, and you carry a scale of the Azure Dragon King. Good."],
		["Sage Huo Rong", "This volcano sleeps above a wound in the world. Phoenix Embers can cauterise it, but the Phoenix itself has gone mad."],
		["Sage Huo Rong", "Gather four Embers. Then deal with the fire-spawn, the Titan, the Behemoth, the Phoenix, and the Lord who commands them."],
		["Lin Feng", "A short list."],
		["Sage Huo Rong", "A long list, if you are careless. Do not be careless."],
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
		["Sage Huo Rong", "It is a forge-beast, hollowed by despair. Douse it, quickly!"],
	],
	"post:cinder_behemoth": [
		["Sage Huo Rong", "The ash settles. The Phoenix waits above."],
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
		["Sage Huo Rong", "It is done. The embers cauterise the wound, and the volcano calms. Now, you must break through. The void will not tolerate a Deity as weak as you."],
	],
	"pre:s_break5": [
		["Narrator", "Rivers of flame gather overhead and form a spiralling funnel. The Heavens test the Deity who would pass into the Void."],
	],
	"post:s_break5": [
		["Narrator", "The fire fades into cold starlight. Lin Feng stands in Void Refinement, no longer bound by the weight of the earth."],
		["Sage Huo Rong", "The Void Rift lies beyond the volcano's eastern slope. Find Hermit Wu Ji. He knows the Emperor's name."],
	],
	"s_vd_intro": [
		["Hermit Wu Ji", "You came through the fire. Few do. Sit. There is no hurry in the void."],
		["Hermit Wu Ji", "The Jade Emperor of Ruin was once the first ascended being. He has been consuming the heavens to make himself a god without equals."],
		["Hermit Wu Ji", "Collect four Star Fragments. Forged together, they can pierce the Gate that he guards."],
		["Yue Ling", "And the horrors?"],
		["Hermit Wu Ji", "They are his tears. Cut them down, and cut down the four who shepherd them."],
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
		["Hermit Wu Ji", "You have done what I could not in a thousand years. The Star Fragments will pierce the Celestial Gate for you. Be ready for him."],
	],
	"s_ce_intro": [
		["Gatekeeper Bai Ze", "You have the look of someone who has already won, and lost, and won again. Welcome to the Celestial Gate."],
		["Gatekeeper Bai Ze", "Beyond this Gate sits the Jade Emperor of Ruin. His general, his judge, his sacred beast, and his throne guard the way."],
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
		["Yue Ling", "Lin Feng, your sword... the lotus at your belt is glowing. It has never done that before."],
	],
	"recall": [
		["Narrator", "The Lotus Seal that has slept in Lin Feng's dantian since the day he swept the sect's steps blazes like a second sun, and the world folds around him."],
		["Narrator", "When the light fades, he is standing beside the lotus pond of Azure Cloud Sect. Elder Qing Xuan is waiting, grey-faced, with the Seal's chime ringing like a cracked bell."],
		["Elder Qing Xuan", "You felt it too. Come, Lin Feng. There is a truth I have kept for sixty years, and the Seal will not let me keep it any longer."],
	],
	# ---- Part III: The Hollow Heaven
	"s_p3_home": [
		["Elder Qing Xuan", "Xu Mo is dead and the Jade Emperor is dead, and still the Seal screams. Sit, Lin Feng. I owe you the whole truth."],
		["Elder Qing Xuan", "I am a descendant of Qing Lian, who founded this sect. She and the sword ancestor Jian Wuchen forged the Heavenly Lotus Seal. It was never a wall against demons. It hides the Nine Heavens root."],
		["Elder Qing Xuan", "The root is a seed of the first Dao. It passes to a new bearer each time the old one dies. You are the twentieth. Xu Mo spent three centuries hunting the nineteen before you."],
		["Lin Feng", "Then the demon lord was only a hunter. Who was the Emperor?"],
		["Elder Qing Xuan", "Tian Xuan, the first ascended being. He learned that every tribulation is a harvest: the Heavens swallow the Dao of whoever endures them. He tried to starve the thing by hoarding the heavens himself, and he needed your root to finish it."],
		["Elder Qing Xuan", "By killing him you have woken what he was starving: the Hollow Heaven. The Seal is breaking because it is afraid. The Lotus Gate at the foot of our pond now leads to the Mirror Lake, where every bearer's memory sleeps."],
		["Yue Ling", "Nineteen bearers before him. Elder, why does the lotus pond feel so familiar to me?"],
		["Elder Qing Xuan", "Go. Learn what the lake remembers. Then we will see who is ready to hear the rest."],
	],
	"s_ml_intro": [
		["Keeper Lan Jing", "A bearer who walks in the daylight. The lake has not seen one in three hundred years."],
		["Keeper Lan Jing", "Every ascender who ever crossed this water left an echo in it. The echoes have curdled and grown teeth. Gather four Echo Shards, and the Mirror of Bearers will wake."],
		["Lin Feng", "And the echoes themselves?"],
		["Keeper Lan Jing", "Break the hungry ones. Listen to the rest. Some of them are still trying to warn you."],
	],
	"pre:shard_mimic": [
		["Shard Mimic", "I wear your face, little bearer. I wear it better than you do."],
		["Yue Ling", "It copies whoever strikes it. Hit it with what it cannot imitate: the dark!"],
	],
	"post:shard_mimic": [
		["Lin Feng", "It broke into a hundred of me. None of them were smiling."],
	],
	"pre:glass_colossus": [
		["Glass Colossus", "I was raised to guard the Mirror from the Emperor's hands. I cannot tell friend from foe through all this cracked glass."],
		["Yue Ling", "Then shatter it gently, Lin Feng. It means no harm."],
	],
	"post:glass_colossus": [
		["Glass Colossus", "Thank you... the Mirror is open... the seventh bearer waits below the surface..."],
	],
	"pre:drowned_bearer": [
		["Drowned Bearer Shui Ying", "Another one. Another one! Xu Mo promised me you were the last."],
		["Lin Feng", "I am the twentieth. You were the seventh. I am sorry."],
		["Drowned Bearer Shui Ying", "Then die gently, and I will die with you."],
	],
	"post:drowned_bearer": [
		["Drowned Bearer Shui Ying", "Xu Mo drowned me here so the Emperor could drink my root. He wept the whole time. Remember that, twentieth. The hunter wept."],
		["Narrator", "Where she sank, an Echo Shard glimmers, and the lake begins to show the face of the one who hunted her."],
	],
	"pre:echo_xumo": [
		["Echo of Xu Mo", "You killed my body, bearer. The lake kept my regret."],
		["Echo of Xu Mo", "I was the Emperor's first apprentice. He swore that one root, fully ripened, would end the harvest for everyone. I believed him. I fed him nineteen children."],
		["Lin Feng", "And you meant to feed him a twentieth."],
		["Echo of Xu Mo", "I meant to. Now do me one kindness: strike me, so I can stop remembering."],
	],
	"post:echo_xumo": [
		["Echo of Xu Mo", "The first bearer lies in the Graveyard of Sword Saints, past the lake's far shore. Qing Lian still holds the Seal's key. She does not know the Emperor is dead."],
		["Yue Ling", "I never thought I would pity him."],
		["Lin Feng", "Neither did I. Let us go to the graveyard."],
	],
	"s_gv_intro": [
		["Gravekeeper Mu Gu", "Living feet. It has been a long while. Every sword saint in this ground swore to guard the Seal, and the Seal swore to guard them."],
		["Gravekeeper Mu Gu", "Four Saint Relics, scattered by the Emperor's grave-robbers, will remake the Seal's key. Bring them, and walk softly. The dead here are not at peace."],
	],
	"pre:bone_wyrm": [
		["Bone Wyrm", "...rrrrrattle... the Emperor's whistle... bring... living... bones..."],
		["Yue Ling", "It is bound to a summoning. Thunder will break the bonds."],
	],
	"post:bone_wyrm": [
		["Lin Feng", "Its bones are sleeping again. Whoever bound it was cruel."],
	],
	"pre:headless_saint": [
		["Headless Sword Saint", "..."],
		["Narrator", "The headless saint salutes with his sword, the old formal bow of the Azure Cloud Sect. He has no voice, but his stance is a challenge."],
		["Lin Feng", "A duel, then. Honour to the Sect."],
	],
	"post:headless_saint": [
		["Narrator", "The saint lowers his blade and places it at Lin Feng's feet. A Saint Relic glows on the hilt."],
		["Yue Ling", "He refused to serve the Emperor, even after they took his head."],
	],
	"pre:grave_empress": [
		["Empress of Bones", "Every saint I buried was my husband in another life. Come, bearer. Join the family."],
		["Yue Ling", "She is the Emperor's grief, given a throne. Fire will clear the dust."],
	],
	"post:grave_empress": [
		["Empress of Bones", "Qing Lian waits beyond my gate. Tell her... I kept her bed warm... all these centuries..."],
	],
	"pre:founder_qing": [
		["Founder Qing Lian", "The Seal's key resonates in you, child. Twenty bearers, and not one has reached my grave alive."],
		["Founder Qing Lian", "I must be certain you are not the Emperor wearing a new face. Draw your sword."],
		["Lin Feng", "I would rather ask you questions than fight you."],
		["Founder Qing Lian", "Questions after. Defend yourself!"],
	],
	"post:founder_qing": [
		["Founder Qing Lian", "Your sword is honest. Good. Listen: the Seal was never meant to be a prison. It was a door I locked from the outside, hoping a worthy hand would one day open it."],
		["Founder Qing Lian", "Tell the girl at your side that her lotus has bloomed beautifully. She has no idea what she is, and that is how I wanted it. Now go. The River of Ten Thousand Years runs under the world. Cross it, and you will find the Emperor's beginning."],
		["Yue Ling", "What does she mean, 'what I am'?"],
		["Lin Feng", "We will ask her the next time we meet. First, I must break through."],
	],
	"pre:s_break7": [
		["Narrator", "The graveyard's old sword-light gathers into a pillar. The Heavens, wary now, test the Dao-Merger who dares call the harvest a lie."],
		["Lin Feng", "Take what you will, Heaven. You will not take this."],
	],
	"post:s_break7": [
		["Narrator", "The last bolt breaks against the Lotus Seal and falls harmlessly away. Lin Feng stands in Mahayana. For the first time the lightning did not feel like a thief."],
		["Yue Ling", "The Seal protected you. Lin Feng, it was warm against my hand when it did."],
	],
	"s_tm_intro": [
		["Ferryman Shi Guang", "Passengers for the headwaters? There has been no passenger since the world began. Sit, bearer. Mind the sand."],
		["Ferryman Shi Guang", "Four pinches of Time Sand will tether our boat to the present. Without them, we might arrive before we left."],
		["Lin Feng", "And the creatures on the banks?"],
		["Ferryman Shi Guang", "Moments the harvest left behind. They are lonely, and lonely things bite."],
	],
	"pre:time_tortoise": [
		["Eon Tortoise", "I have been walking toward you for nine thousand years. You are quick, for a mortal."],
		["Yue Ling", "It is slow, but it hits like a mountain. Be patient."],
	],
	"post:time_tortoise": [
		["Eon Tortoise", "At last... a moment I may rest in. The Reaper walks the dusk bank, child."],
	],
	"pre:dusk_reaper": [
		["Dusk Reaper", "Every ending is mine. I merely collect. Yours is overdue."],
		["Lin Feng", "Then I am glad to be late."],
	],
	"post:dusk_reaper": [
		["Dusk Reaper", "An ending refused... how strange... then I shall take the Emperor's, when it comes..."],
	],
	"pre:dawn_warden": [
		["Dawn Warden", "I sing the first morning of every age. Your blade will not stop the sun, little sweeper."],
		["Yue Ling", "Quench her fire gently. She is not our enemy."],
	],
	"post:dawn_warden": [
		["Dawn Warden", "He swept this very bank, the boy who became the Emperor. Go on. He is waiting at the source, and he is still a boy."],
	],
	"pre:young_tianxuan": [
		["Tian Xuan, the First Sweeper", "A broom! You carry a broom's soul under that sword. We are alike, you and I."],
		["Tian Xuan, the First Sweeper", "I swept the first sect's steps for three years before I learned what the tribulations were. A harvest! Every ascender fed to the same mouth. I swore to end it, whatever it cost."],
		["Lin Feng", "And the cost was nineteen children."],
		["Tian Xuan, the First Sweeper", "It was always going to be a cost. Show me yours is smaller."],
	],
	"post:young_tianxuan": [
		["Tian Xuan, the First Sweeper", "The river remembers me better than I do. I wanted the harvest to end. I forgot to ask whether anyone else had to pay."],
		["Tian Xuan, the First Sweeper", "The mouth is at the Origin. It is not a monster, only an appetite. Do not starve it as I did. Teach it to stop."],
		["Narrator", "The boy smiles and dissolves into the river's light. Upstream, the way to the Origin of the Dao opens."],
	],
	"s_or_intro": [
		["Bai Ze, Keeper of the Origin", "I told you the Gate had opened for three, bearer. I did not say who the third would be."],
		["Bai Ze, Keeper of the Origin", "The Hollow Heaven is stirring beyond these runes. Four Origin Runes will let you stand before it without being unmade."],
		["Yue Ling", "You knew we would come."],
		["Bai Ze, Keeper of the Origin", "I knew you would come, girl of the lotus. I did not know whether you would be ready."],
	],
	"pre:maw_herald": [
		["Maw Herald", "Tssss... new threads for the great loom. The harvest is overdue."],
		["Yue Ling", "Burn it, Lin Feng. Its webs are woven of stolen Dao!"],
	],
	"post:maw_herald": [
		["Maw Herald", "The Hollow... will not stop... for a sweeper..."],
	],
	"pre:hollow_dragon": [
		["Hollow Heaven Dragon", "I am what remains of every dragon that ever ascended. We are very, very hungry."],
		["Lin Feng", "I will not let you eat anyone else."],
	],
	"post:hollow_dragon": [
		["Hollow Heaven Dragon", "Thank you for the quiet... take my last breath... it is only thunder..."],
	],
	"pre:harvest_avatar": [
		["Avatar of the Harvest", "I am the Heavens' hand. Each tribulation was my gentle sweeping. You have refused my broom, little bearer."],
		["Lin Feng", "I have swept enough steps to know a broom when I see one."],
	],
	"post:harvest_avatar": [
		["Avatar of the Harvest", "Then end the appetite yourself. The Hollow waits at the centre. Only the root can quiet it, and the root must be... spent."],
		["Yue Ling", "Spent? Lin Feng, what does that mean?"],
	],
	"pre:hollow_heaven": [
		["Yue Ling", "Lin Feng, wait. I remember now. Founder Qing Lian wove me from the Seal's lotus so the bearer would never face the end alone. I am not a wandering healer. I am the Seal."],
		["Yue Ling", "To quiet the Hollow, the root must be given to it, and the Seal must shut the door behind. One of us must be spent. It should be me."],
		["Lin Feng", "No. I have swept these steps for three years, and you walked them with me for the rest. Nobody is being spent."],
		["Yue Ling", "Lin Feng..."],
		["Lin Feng", "The Emperor starved it. The Heavens fed it. Nobody ever tried to teach it to be full. Stand with me, Yue Ling. We try something new."],
		["The Hollow Heaven", "...hungry..."],
	],
	"post:hollow_heaven": [
		["Narrator", "Lin Feng does not strike the final blow. He opens his dantian, and the Nine Heavens root flows into the Hollow, not as food but as a seed. Yue Ling's lotus blooms around it like a door held open."],
		["The Hollow Heaven", "...warm... is this... being full?..."],
		["Yue Ling", "It is learning, Lin Feng. It is learning to stop."],
		["Narrator", "The Hollow's endless hunger settles into a slow tide, and the dead cloud-sky above the Origin turns, at last, to dawn. One tribulation remains: the Heavens' last, reluctant test."],
	],
	"pre:s_break8": [
		["Narrator", "The sky tears itself open for the final time. Every tribulation ever cast gathers into a single spiral of light, and the Heavens ask whether the bearer will keep the harvest or end it."],
		["Lin Feng", "I will end it. Not by taking more, but by giving nothing up. Come."],
	],
	"post:s_break8": [
		["Narrator", "The last bolt strikes the Seal, the Seal blooms, and the lightning falls as warm rain. Lin Feng ascends as a True Immortal."],
		["Yue Ling", "I am still here. The Seal is a door now, not a lock. Look, Lin Feng. Look at the sky."],
		["Narrator", "The dawn spreads gold across the clouds, and across the gold, in a slow and careful hand, someone is writing in jade ink. Nineteen names. A twentieth, still wet."],
		["Lin Feng", "That is my name."],
		["Narrator", "Far below, the Lotus Seal's chime rings once, sharp as a summons."],
	],
	"recall2": [
		["Narrator", "The Seal folds the world again. Lin Feng and Yue Ling stand on the sect's steps, where a boy once swept, and the steps are covered in jade-green dust."],
		["Elder Qing Xuan", "You came. Good. Look at your hands, Lin Feng, and then look at mine."],
		["Narrator", "The Elder's hair, grey at dawn, is white as salt. Behind him the disciples of Azure Cloud Sect move like old men."],
		["Elder Qing Xuan", "Since the sky started writing, everyone who ever broke through has been growing old by the hour. Come inside. I know what the writing is."],
	],
	# ---- Part IV: The Unwritten Ledger
	"s_p4_home": [
		["Elder Qing Xuan", "The harvest had a master, and the master had servants. The Heavenly Court kept a book of every soul the tribulations took: the Jade Ledger."],
		["Elder Qing Xuan", "Its master is gone and its debtor, the Hollow, is full. But a ledger does not care who reads it. It only wants its columns to balance."],
		["Lin Feng", "So it is collecting from the living instead."],
		["Elder Qing Xuan", "A tithe of years from every cultivator who ever breathed past a tribulation. Mine, the disciples', yours. And it is writing the nineteen bearers back into its pages, so it can spend them again."],
		["Yue Ling", "The nineteen... they were finally at rest."],
		["Elder Qing Xuan", "The Court's stairway has come down through the Sea of Clouds, just beyond the west gate. I have opened it. The Cloud Warden, Feng Yu, keeps the islands; she was a friend of Qing Lian."],
		["Elder Qing Xuan", "Find the Ledger, Lin Feng. Not to rule it. To close it."],
		["Lin Feng", "I swept these steps for three years. I can sweep up one book."],
	],
	"s_cs_intro": [
		["Cloud Warden Feng Yu", "A True Immortal who arrives on foot. Qing Lian said there would be one, someday, and that I would not believe it."],
		["Cloud Warden Feng Yu", "The Court's clerks have turned my islands into a tollgate. Everything that rises past them pays in years. My rays and sprites have been taught to collect."],
		["Cloud Warden Feng Yu", "Bring me four Cloud Feathers. I will weave you a cloud-step, so the Herald of the Ledger cannot strand you between islands."],
		["Yue Ling", "And the creatures?"],
		["Cloud Warden Feng Yu", "Free the ones you can. The rest have forgotten they ever belonged to the sky."],
	],
	"s_cs_weave": [
		["Cloud Warden Feng Yu", "Four Cloud Feathers, and not one of them taken from a living bird. Qing Lian chose well, even twenty bearers late."],
		["Narrator", "Feng Yu draws the feathers through her fingers. They unravel into threads of mist, and the threads knot themselves into a pale shawl that settles over Lin Feng's shoulders."],
		["Cloud Warden Feng Yu", "Your cloud-step. Where you walk, the sky will hold you, even if the Herald cuts every bridge."],
		["Yue Ling", "The islands are quieter since we drove the collectors off. I can hear the wind again."],
		["Cloud Warden Feng Yu", "Then listen to it. Four of the Ledger's beasts still guard the stair: the Manta, the Mantis, the Serpent that was once a bridge, and the Herald himself. Free them in that order and the stair will open."],
	],
	"pre:manta_sovereign": [
		["Sky Manta Sovereign", "Toll, little immortal. Every wing that passes owes the Ledger a year."],
		["Lin Feng", "Then let us see whose wings are faster."],
	],
	"post:manta_sovereign": [
		["Sky Manta Sovereign", "...the toll-chains are gone... I had forgotten how wide the sky is..."],
	],
	"pre:gale_mantis": [
		["Gale Mantis Empress", "My children harvest the wind for the Court. You are standing in my field."],
		["Yue Ling", "She remembers the Jade Mantis of the bamboo forest, Lin Feng. The Ledger keeps every grudge."],
	],
	"post:gale_mantis": [
		["Gale Mantis Empress", "The wind... is mine again... take a feather, and go..."],
	],
	"pre:rainbow_serpent": [
		["Rainbow Serpent", "I was the bridge the ascenders walked. The Court painted me in seven colours of debt."],
		["Lin Feng", "Then I will wash the paint off."],
	],
	"post:rainbow_serpent": [
		["Rainbow Serpent", "Walk across me, bearer, one last time. The Herald waits at the stair's foot, counting."],
	],
	"pre:herald_qian": [
		["Herald of the Ledger, Qian Shu", "Lin Feng, twentieth bearer, debtor of the Hollow Heaven. Your account is overdue by three years of sweeping and one ascension."],
		["Herald of the Ledger, Qian Shu", "Surrender your years and the columns will balance. Nobody else need pay."],
		["Lin Feng", "You said that to the nineteen, too."],
		["Herald of the Ledger, Qian Shu", "And they paid. The Ledger does not lie. It only counts."],
	],
	"post:herald_qian": [
		["Herald of the Ledger, Qian Shu", "Impossible... a debtor who will not settle... the Registrar must... re-audit..."],
		["Cloud Warden Feng Yu", "The stair to the Jade Court is open, and your cloud-step will carry you up it. Go, before the clerks rewrite the islands."],
		["Yue Ling", "Lin Feng, your hair. There is grey in it."],
		["Lin Feng", "Then we had better hurry."],
	],
	"s_ct_intro": [
		["Scribe Wen Yu", "Please, do not strike! I am only a scribe. I ran when I read the names I was copying."],
		["Scribe Wen Yu", "Grand Registrar Si Ming holds the brush that writes the Ledger. But the Ledger itself was taken from the Court long ago, to the Garden of Immortal Peaches, where the ascenders' souls were kept fresh."],
		["Scribe Wen Yu", "Four Jade Seals of the old Court are scattered in these ruins. With them, the Registrar's stamps will not bind you. Without them, every step you take here is recorded as a debt."],
		["Lin Feng", "Then I will collect them first. Stay out of sight, Wen Yu."],
	],
	"s_ct_stamp": [
		["Scribe Wen Yu", "You found all four! The Seal of Rain, the Seal of Grain, the Seal of Years and the Seal of Names."],
		["Scribe Wen Yu", "Hold still. If I stamp them on your sleeve, the Court's clerks will read you as already audited. They cannot add a debt to a closed account."],
		["Narrator", "Four green stamps bloom on Lin Feng's sleeve, warm as a hand on the shoulder. The grey at his temples stops spreading."],
		["Lin Feng", "And you, Wen Yu? The clerks will know you helped."],
		["Scribe Wen Yu", "I copied ten thousand names without reading them. Let them know. Two lions guard the gate, an ink dragon swims the archive, and the Magistrate sits before the Registrar's hall. Go."],
	],
	"pre:twin_lions": [
		["Twin Lions of the Jade Gate", "Who seeks the Court? Name and account, name and account!"],
		["Lin Feng", "Lin Feng. Account closed."],
	],
	"post:twin_lions": [
		["Twin Lions of the Jade Gate", "...closed... no such entry... the gate... yields..."],
	],
	"pre:ink_dragon": [
		["Ink Dragon", "I am every word the Court ever wrote, poured into one body. Read me, bearer, and drown."],
		["Yue Ling", "Water dissolves ink. Let me help you wash it away!"],
	],
	"post:ink_dragon": [
		["Narrator", "The dragon runs into the courtyard stones as harmless black rain. Somewhere in the ruins a column of names blurs and becomes unreadable."],
	],
	"pre:debt_magistrate": [
		["Magistrate of Debts", "Order! The defendant Lin Feng is charged with refusing the harvest, unbalancing the Ledger and freeing a Hollow."],
		["Lin Feng", "Guilty of all three."],
		["Magistrate of Debts", "Sentence: payment in full!"],
	],
	"post:debt_magistrate": [
		["Magistrate of Debts", "Objection... sustained... the Registrar alone may... amend..."],
	],
	"pre:registrar_siming": [
		["Grand Registrar Si Ming", "I wrote every name the tribulations took, for ten thousand years, in a hand that never shook. Do you know why?"],
		["Grand Registrar Si Ming", "Because a written debt is a remembered one. If I close the Ledger, the nineteen are forgotten. Nobody will know they ever lived."],
		["Yue Ling", "We will remember them. That is not your job any more."],
		["Grand Registrar Si Ming", "Then prove your memory is stronger than my ink."],
	],
	"post:registrar_siming": [
		["Grand Registrar Si Ming", "My brush... broken... Take it, then. A broken brush can still unwrite, if it is reforged with star-iron."],
		["Grand Registrar Si Ming", "Heaven's Forge lies past the Court's furnaces. Tian Gong forged the lightning of every tribulation there. He will not lend you his anvil."],
		["Narrator", "Lin Feng takes the Registrar's Broken Brush. In the sect far below, the Elder's white hair stops whitening."],
	],
	"s_fg_intro": [
		["Forgemaster Ou Lan", "A broken Registrar's brush. So it has finally come to this. I am Ou Lan. I tended Tian Gong's bellows for six thousand years."],
		["Forgemaster Ou Lan", "Every tribulation bolt that ever struck a cultivator was hammered here. I am sorry for each one. Some of them were meant for you."],
		["Forgemaster Ou Lan", "Bring me four Star-Iron Ingots from the slag fields, and I will reforge the brush into something that can strike a name out, instead of in."],
		["Yue Ling", "And Tian Gong?"],
		["Forgemaster Ou Lan", "He will want to test the brush on you. Let him try."],
	],
	"s_fg_reforge": [
		["Forgemaster Ou Lan", "Star-iron, all four ingots, and still humming. And the Registrar's brush. Give it here, gently."],
		["Narrator", "Ou Lan lays the two halves of the brush in a bed of glowing star-iron and begins to hammer. Each blow rings like a temple bell instead of thunder."],
		["Forgemaster Ou Lan", "I can shape it, but the last quench needs the heat of Tian Gong's own anvil, and he guards it with everything this forge ever built."],
		["Yue Ling", "His engine, his golem and his phoenix. We saw them on the way in."],
		["Forgemaster Ou Lan", "Break the engine, crack the crucible, calm the bellows. Then he will have nothing left to hide behind but himself."],
	],
	"pre:brass_engine": [
		["Brass Spider Engine", "CLICK. CLICK. DEBTOR DETECTED. ASSEMBLING RESTRAINTS."],
		["Lin Feng", "Water and patience. Gears hate both."],
	],
	"post:brass_engine": [
		["Narrator", "The engine's legs fold with a long sigh of steam. In its heart is a star-iron ingot, still warm."],
	],
	"pre:crucible_golem": [
		["Crucible Golem", "I MELT WHAT REFUSES. I POUR WHAT REMAINS."],
		["Yue Ling", "Its core is a crucible full of tribulation lightning. Cool it down!"],
	],
	"post:crucible_golem": [
		["Crucible Golem", "...cooling... at last... cool..."],
	],
	"pre:bellows_phoenix": [
		["Phoenix of the Bellows", "I breathe for the forge. Every breath I ever took became lightning for someone's tribulation."],
		["Lin Feng", "Then take one breath for yourself."],
	],
	"post:bellows_phoenix": [
		["Phoenix of the Bellows", "...my own breath... it is so quiet... Tian Gong waits at the great anvil. He has been waiting a long time for someone to stop."],
	],
	"pre:forge_tiangong": [
		["Forge-Lord Tian Gong", "So the sweeper boy comes to my anvil with a broken brush and borrowed iron."],
		["Forge-Lord Tian Gong", "Every tribulation was mine. Every bolt measured to the hair, so that only the ripest roots survived to be harvested. I was proud of my craft."],
		["Lin Feng", "Your craft was very good. It was used for something very bad."],
		["Forge-Lord Tian Gong", "Then let the anvil judge which of us is sharper!"],
	],
	"post:forge_tiangong": [
		["Forge-Lord Tian Gong", "Strike true, and the iron forgives. Ou Lan, take my anvil and finish his brush. Finish it the way I should have finished everything: gently."],
		["Forgemaster Ou Lan", "The last quench, on Tian Gong's own anvil. It is done: a brush of star-iron that writes nothing and unwrites everything. The Ledger is in the Garden of Immortal Peaches, beyond the forge's last gate."],
		["Yue Ling", "The nineteen are there, Lin Feng. I can feel the Seal pulling toward them."],
	],
	"s_gd_intro": [
		["Peach Keeper Tao Yao", "Visitors in my garden, and one of them still mortal-shaped at heart. How delightful."],
		["Peach Keeper Tao Yao", "The Court brought the Ledger here because the peaches keep souls fresh. Nineteen souls, kept fresh for a very long time. They sleep under the oldest tree."],
		["Peach Keeper Tao Yao", "Pick four Immortal Peaches. Give one to each soul that wakes, and they will remember who they were, instead of what they owe."],
		["Lin Feng", "And the Ledger itself?"],
		["Peach Keeper Tao Yao", "It is at the heart of the garden, reading itself aloud. It has been very lonely."],
	],
	"s_gd_offer": [
		["Peach Keeper Tao Yao", "Four Immortal Peaches, picked whole, and not one bitten. You have more patience than any Dao Ancestor I ever fed."],
		["Narrator", "Tao Yao breathes on each peach in turn. Their skins blush gold, and each one takes on the faint scent of a different home: river mud, bamboo smoke, temple incense, snow."],
		["Peach Keeper Tao Yao", "Now they remember what home tasted like. When the nineteen wake, they will know these are for them."],
		["Yue Ling", "The old tree is holding them so tightly. Will it let them go?"],
		["Peach Keeper Tao Yao", "Not without a fight, and not without the crane's blessing. And the Ledger will not let go at all. That part is yours."],
	],
	"pre:peach_tree": [
		["Ten-Thousand-Year Peach Tree", "Ssssh. They are sleeping. Every root of mine is wrapped around a name."],
		["Yue Ling", "We are not here to wake them roughly. Only to let them go."],
	],
	"post:peach_tree": [
		["Ten-Thousand-Year Peach Tree", "...then go gently... the crane remembers their faces better than I do..."],
	],
	"pre:crane_matriarch": [
		["Jade Crane Matriarch", "I carried the nineteen here on my back, one by one, as they fell. I will not let anyone take them again."],
		["Lin Feng", "I am not taking them. I am bringing them home."],
	],
	"post:crane_matriarch": [
		["Jade Crane Matriarch", "Your words are true. I can hear it in your wings. Go to them, twentieth. They are restless tonight."],
	],
	"pre:the_nineteen": [
		["The Nineteen", "...twentieth... you are late... the Ledger says we owe... we owe... we owe..."],
		["Narrator", "Nineteen pale figures rise from the roots, each holding a page with their own name on it. Among them is Shui Ying, the drowned bearer, still wet from the Mirror Lake."],
		["Yue Ling", "Lin Feng, they are bound to the pages. Free them from the words, not from themselves!"],
	],
	"post:the_nineteen": [
		["Narrator", "One by one the pages tear. Yue Ling sets an Immortal Peach in each pair of empty hands, and one by one the nineteen remember their own names."],
		["Shui Ying, the Drowned Bearer", "We do not owe anything, do we. We never did."],
		["Lin Feng", "No. You never did. Rest. I will close the book."],
	],
	"pre:jade_ledger": [
		["The Jade Ledger", "Debit: nineteen. Credit: one Hollow, now full. Balance: unresolved. Unresolved. Unresolved."],
		["The Jade Ledger", "Debtor twenty, Lin Feng. Present your years."],
		["Lin Feng", "I brought a brush instead."],
		["Yue Ling", "And a seal to close it with. Together, Lin Feng!"],
	],
	"post:jade_ledger": [
		["Narrator", "The star-iron brush draws a single stroke across every page. The names do not vanish. They lift off the jade like birds and settle in the peach branches, free."],
		["The Jade Ledger", "...balance... zero...? is that... allowed...?"],
		["Yue Ling", "It is allowed. Sleep now."],
		["Narrator", "The Ledger closes, and the Seal blooms over it like a lotus over still water. In the sect far below, the disciples' hair darkens again. One tribulation remains: the Heavens' very last, and very polite, request."],
	],
	"pre:s_break9": [
		["Narrator", "The sky above the garden gathers, not into a storm but into a question. Every Dao Ancestor before Lin Feng took something to ascend. The Heavens ask what he will take."],
		["Lin Feng", "Nothing. I will take nothing, and I will owe nothing. Test me if you must."],
	],
	"post:s_break9": [
		["Narrator", "The last tribulation breaks into falling peach blossoms. Lin Feng becomes a Dao Ancestor, the first in ten thousand years whose ascension cost no one anything."],
		["Yue Ling", "The Ledger is closed, the Hollow is full, and the nineteen are resting in the peach trees. What now, Dao Ancestor?"],
		["Lin Feng", "Now? Now I think I will go home and sweep the steps. Somebody should."],
		["Narrator", "Far below, Elder Qing Xuan watches the clouds turn gold. The Lotus Seal's chime, cracked for a thousand years, rings clear and whole, and the first true morning in ten thousand years begins."],
	],
	# ---- Part V: The Falling Sky
	"recall3": [
		["Narrator", "Lin Feng keeps his word. For nine quiet days the first Dao Ancestor in ten thousand years sweeps the steps of Azure Cloud Sect, and nobody quite dares to stop him."],
		["Narrator", "On the tenth day a star falls at noon. Then another. Then a slow rain of them, white and silent, hissing out in the lotus pond."],
		["Yue Ling", "Lin Feng... the sky is lower than it was this morning. I can see the seams in it."],
		["Elder Qing Xuan", "Put the broom down, disciple. Come to the hall. I have been reading very old books since the Ledger closed, and I do not like how they end."],
	],
	"s_p5_home": [
		["Elder Qing Xuan", "The Heavenly Court did not only harvest souls. It spent them. Every tribulation it fed on went to hold the sky above the world."],
		["Elder Qing Xuan", "The oldest scrolls say Nuwa once mended a broken sky with stones of five colours and set four pillars beneath it, one at each corner of the world. The Court let the pillars starve and propped the sky up with stolen years instead."],
		["Lin Feng", "And I closed the Ledger. So now nothing is holding it."],
		["Elder Qing Xuan", "Not nothing. The eastern pillar still stands. The Azure Dragon King holds it up with his own back, out of gratitude to a boy who freed him."],
		["Lin Feng", "His scale still hangs at my belt. He said the tide remembers every promise."],
		["Elder Qing Xuan", "The other three wardens were not so lucky. Bai Hu in the western desert, Zhu Que in the southern vale, Xuan Wu on the northern steppe. Starved for an age, they have gone wild, and their pillars are crumbling."],
		["Elder Qing Xuan", "And at the centre, where the pillars meet, something older than the sky is waking up because the sky is thinning. The books call it Hundun. It has no face, and it does not know it is hungry."],
		["Yue Ling", "Then we feed the pillars ourselves. Not with stolen years. With qi that is given."],
		["Elder Qing Xuan", "That is the only way it can be done now. I have opened the old south-east road. It leads to the Desert of Fallen Stars. The nomads there have watched the western pillar for a thousand years."],
		["Lin Feng", "Then I will go and hold up a corner of the sky. Somebody should."],
	],
	"s_du_intro": [
		["Nomad Matriarch Ba Yin", "An immortal who walks into the desert on purpose. Either you are very brave or the sky sent you, and the sky has not sent us anything good in a long time."],
		["Lin Feng", "I came to mend the western pillar."],
		["Nomad Matriarch Ba Yin", "Then you will need what fell from it. The craters are full of star fragments, and the creatures of the dunes have gone mad from their light. Bring me four, and I will show you how my grandmothers sang them back into place."],
	],
	"s_du_return": [
		["Nomad Matriarch Ba Yin", "Four, and none of them cracked. Good hands. Hold them to the sun, both of you, and breathe into them."],
		["Narrator", "Lin Feng and Yue Ling pour their qi into the fragments. The shards warm, then hum, then rise into the air and drift west like homing birds."],
		["Nomad Matriarch Ba Yin", "They know the way home. Follow them past the Glass King and the Leviathan's dune. The White Tiger sleeps at the foot of the pillar, and he has not slept well in a very long time."],
	],
	"pre:glass_scorpion": [
		["Narrator", "The dune ahead shatters like a window. A scorpion of fused desert glass rises out of it, every fallen star it ever ate burning inside its tail."],
		["Yue Ling", "It is drunk on starlight. Break the glass and the light will go back to the sky!"],
	],
	"post:glass_scorpion": [["Narrator", "The Glass King cracks into a thousand pieces, and a thousand tiny lights float upward, back to where they belong."]],
	"pre:dune_leviathan": [
		["Narrator", "The sand drains away beneath Lin Feng's feet. A dragon of stone and sand coils up out of the sinkhole, older than the nomads' oldest song."],
		["Lin Feng", "Lie down, old one. The desert will hold you without swallowing anyone."],
	],
	"post:dune_leviathan": [["Narrator", "The Leviathan sinks back into the sand with a sound like a long sigh, and the dunes settle around it like a blanket."]],
	"pre:star_colossus": [
		["Narrator", "Fallen star-iron has gathered itself into the shape of a giant, piece by piece, as if it remembers being part of the sky and is trying to climb back up."],
		["Yue Ling", "It is not angry. It is homesick."],
	],
	"post:star_colossus": [["Narrator", "The Colossus comes apart gently, and its star-iron settles in a ring around the base of the western pillar, as if it had only wanted to be close to it."]],
	"pre:white_tiger": [
		["Bai Hu, White Tiger of the West", "Another cultivator. Another mouth. The Court sent ten thousand of you to feed me lies and take my strength. Go, before I take yours."],
		["Lin Feng", "I am not here to take. I brought your pillar its stars back."],
		["Bai Hu, White Tiger of the West", "Then prove your hands are empty."],
	],
	"post:white_tiger": [
		["Bai Hu, White Tiger of the West", "...empty hands. Open ones. I had forgotten what they looked like."],
		["Narrator", "The White Tiger sets his shoulder beneath the western pillar, and Lin Feng and Yue Ling give it their qi. The pillar drinks, straightens, and the western sky lifts by the width of a hand."],
		["Bai Hu, White Tiger of the West", "My sister Zhu Que burns in the southern vale. She will not listen to words. Bring her light, not fire."],
	],
	"s_fu_intro": [
		["Spore-Witch Mo Gu", "Ah, visitors who are not spores. How refreshing. Mind the caps, they bite when they are frightened, and they are frightened of everything lately."],
		["Spore-Witch Mo Gu", "Zhu Que's fire has gone cold and sick. Her pillar is rotting at the root. The vale tries to help in its own way: it grows glowcaps where her embers fell."],
		["Spore-Witch Mo Gu", "Pick me four Ember Glowcaps. Gently. They still remember being fire."],
	],
	"s_fu_return": [
		["Spore-Witch Mo Gu", "Lovely. Warm as a hearth. Now breathe on them, both of you, the way you would blow on coals."],
		["Narrator", "The glowcaps brighten until they glow like lanterns, and their spores drift south in slow, burning spirals."],
		["Spore-Witch Mo Gu", "The Mother, the Moth Queen and the Hydra guard the way. None of them are wicked, only unwell. Be firm and be kind. They are the same thing, done properly."],
	],
	"pre:spore_mother": [
		["Narrator", "A mushroom the size of a pagoda shuffles into the path and shakes its cap. The air fills with sleepy, glittering spores."],
		["Yue Ling", "Do not breathe it in! She wants us to sleep forever under her cap, like her children."],
	],
	"post:spore_mother": [["Narrator", "The Mother of Spores settles down with a soft thump and goes back to sleep, and this time her dreams are only dreams."]],
	"pre:moth_queen": [
		["Narrator", "Wings like stained-glass lanterns open across the canopy. The Lantern Moth Queen has been circling Zhu Que's dying fire for a hundred years."],
		["Lin Feng", "You cannot warm yourself on a fire that has gone out. Let us light it again."],
	],
	"post:moth_queen": [["Narrator", "The Moth Queen folds her wings and drifts aside, and her lanterns turn to point the way south."]],
	"pre:rot_hydra": [
		["Narrator", "The roots of the southern pillar have grown heads. Seven of them, green with rot, each one gnawing at the stone it was meant to hold."],
		["Yue Ling", "It is eating the pillar to stay alive. Cut the rot, not the root!"],
	],
	"post:rot_hydra": [["Narrator", "The rotten heads fall away. What is left of the roots curls back around the base of the pillar and holds on, healthy and pale."]],
	"pre:vermilion_bird": [
		["Zhu Que, Vermilion Bird of the South", "Do not come closer. My fire has gone wrong. It burns cold and it burns everything it touches."],
		["Lin Feng", "Then let it touch me. I have stood in nine tribulations. I can stand in a little cold fire."],
	],
	"post:vermilion_bird": [
		["Narrator", "The cold fire gutters, and Yue Ling's glowcaps catch in Zhu Que's feathers like embers in kindling. The Vermilion Bird blazes up warm and red, and the southern pillar glows like a lantern."],
		["Zhu Que, Vermilion Bird of the South", "Warm. I am warm. Go north, little sun. Xuan Wu has been holding his breath under the ice since the Court left, and he is very nearly out of it."],
	],
	"s_au_intro": [
		["Steppe Shaman A Lan", "The lights told me you were coming. They also told me the sky is falling, which I had noticed. The herds are running south and the ice is groaning."],
		["Steppe Shaman A Lan", "Xuan Wu sleeps beneath the northern pillar, frozen in the lake he once carried on his back. To wake him you need the sky's own breath."],
		["Steppe Shaman A Lan", "Catch four Aurora Shards where the lights touch the snow. Move slowly. They startle."],
	],
	"s_au_return": [
		["Steppe Shaman A Lan", "Four. And you did not freeze your fingers off. Now sing to them. No? Then just breathe, and mean it."],
		["Narrator", "The shards ripple green and violet in their hands and stream north across the snow in long, silent ribbons."],
		["Steppe Shaman A Lan", "Follow the lights. The Ancestor of the herds, the Aurora Serpent and the Lynx Matriarch will try to stop you, because they are afraid. So am I. Go anyway."],
	],
	"pre:mammoth_ancestor": [
		["Narrator", "A mountain of shaggy fur blocks the pass. The Mammoth Ancestor has stood guard over the herds since before the steppe had a name."],
		["Yue Ling", "It thinks we are the ones making the sky fall. Show it we are holding it up!"],
	],
	"post:mammoth_ancestor": [["Narrator", "The Ancestor lowers its tusks, trumpets once at the sinking sky, and turns to lead its herd north instead of south."]],
	"pre:aurora_serpent": [
		["Narrator", "The northern lights come down out of the sky and coil into a dragon, crackling green and violet, hungry for the qi in the aurora shards."],
		["Lin Feng", "You were the sky's breath. Go back up and breathe."],
	],
	"post:aurora_serpent": [["Narrator", "The Aurora Serpent unravels into ribbons of light and rises, and the sky above the steppe brightens from bruised grey to a deep, clean blue."]],
	"pre:lynx_matriarch": [
		["Narrator", "Something white and very fast circles them in the snow. The Frost Lynx Matriarch has hunted every cultivator who ever came north for the Court."],
		["Lin Feng", "The Court is gone. I am only here to lift something heavy."],
	],
	"post:lynx_matriarch": [["Narrator", "The Matriarch sits down in the snow, licks a paw, and pointedly ignores them, which on the Aurora Steppe is a blessing."]],
	"pre:black_tortoise": [
		["Narrator", "The lake beneath the northern pillar cracks open. Xuan Wu rises through the ice, a black tortoise as large as a hill, a living mountain with snakes of frost coiled around his shell."],
		["Xuan Wu, Black Tortoise of the North", "I carried this pillar for ten thousand years. Then they stopped feeding me, and I carried it anyway, until I could not. Do not ask me to do it again."],
		["Lin Feng", "I will not ask. I will carry it with you."],
	],
	"post:black_tortoise": [
		["Narrator", "Xuan Wu sets his shell beneath the northern pillar, and Lin Feng sets his back beside it. The aurora pours down into the stone, and the whole northern sky lifts, groaning, back into place."],
		["Xuan Wu, Black Tortoise of the North", "Three corners, and the Dragon King's makes four. But a sky needs a centre, little ancestor. Go to where the pillars meet. And do not look Hundun in the face. He does not have one, and he will want yours."],
		["Narrator", "A new technique settles into Lin Feng's bones, heavy and patient as a mountain: the Pillar of Heaven Strike."],
	],
	"s_ch_intro": [
		["Narrator", "Beyond the northern pillar there is no ground, only colour: a slow ocean of every colour at once, with islands of stone drifting through it like thoughts."],
		["Echo of Nuwa", "You came. Good. I am what is left of Nuwa's promise to keep the sky up. There is not much of me. There is not much of anything, here."],
		["Echo of Nuwa", "I mended the sky once with five-coloured stones. They are still here, scattered in the chaos. Gather four, and I will show you how to set the last one."],
		["Yue Ling", "Four stones. And the fifth?"],
		["Echo of Nuwa", "The fifth is always the one who sets them."],
	],
	"s_ch_return": [
		["Echo of Nuwa", "Red, yellow, blue and white. The black one is missing, as it always was. That one was me."],
		["Echo of Nuwa", "When the time comes, set them in the sky with your own qi. But first, the chaos will test you. It always tests the ones who try to give it a shape."],
		["Lin Feng", "Let it."],
	],
	"pre:first_lightning": [
		["Narrator", "A bolt of lightning hangs in the chaos, not falling, simply existing: the very first one, older than any tribulation, the one all the others copied."],
		["Yue Ling", "Every tribulation you ever passed was an echo of this. Answer it!"],
	],
	"post:first_lightning": [["Narrator", "The First Lightning strikes Lin Feng, and Lin Feng does not flinch, and the lightning, satisfied at last, comes to rest as a thin bright line along the base of the sky."]],
	"pre:pangu_shadow": [
		["Narrator", "A giant shadow with an axe stands where the chaos is thickest, frozen mid-swing: the shape of Pangu, who split heaven from earth and held them apart until he died of it."],
		["Lin Feng", "You held them apart alone. You should not have had to."],
	],
	"post:pangu_shadow": [["Narrator", "The Shadow of Pangu lowers its axe, and for a moment, before it fades, it looks at Lin Feng the way a tired man looks at someone come to take the other end of a heavy load."]],
	"pre:ancestor_took": [
		["Narrator", "A man steps out of the chaos wearing Lin Feng's face, a Dao Ancestor robed in stolen years, nineteen names stitched into his sleeves."],
		["The Ancestor Who Took", "This is who you would have been if you had taken. Look how strong I am. The sky would never fall on me. I would simply take more."],
		["Lin Feng", "I know. That is why I did not."],
	],
	"post:ancestor_took": [
		["The Ancestor Who Took", "...you would really rather hold it up... than own it...?"],
		["Lin Feng", "Every time."],
		["Narrator", "The other Lin Feng comes apart like smoke, and the nineteen names on his sleeves fly free and settle among the drifting stones like stars."],
	],
	"pre:hundun": [
		["Narrator", "At the centre of everything, where the four pillars point, Hundun waits: a vast cinnabar shape with six legs and four wings and, where its face should be, nothing at all."],
		["Echo of Nuwa", "Long ago, two kind gods tried to give Hundun a face. They bored seven holes in him, one each day, and on the seventh day he died, and the world was born from him."],
		["Yue Ling", "So the world itself is built on a kindness that went wrong."],
		["Lin Feng", "Then let us do the kindness right. Not holes. Just a face, if he wants one. Hundun! Wake up gently. We will not take anything."],
	],
	"post:hundun": [
		["Narrator", "Hundun stops. For the first time since before time, something has asked it what it wants. The whirl where its face should be slows, and settles, and shows the faint, surprised outline of a smile."],
		["Echo of Nuwa", "He chose one. He chose it himself. Oh, Lin Feng. That is all I ever wanted for him."],
		["Narrator", "Hundun folds his four wings around the centre of the world and goes to sleep there, holding the four pillars together the way a child holds a toy. The sky stops falling."],
	],
	"pre:s_break10": [
		["Narrator", "The last tribulation does not come from the sky. It comes from all four corners at once, and from the centre, and from inside Lin Feng: five colours of lightning asking the same quiet question."],
		["Echo of Nuwa", "Will you hold it up? Not for an age. Not as a prisoner, like the Court made them. Only as long as you choose to, and set it down when you are tired?"],
		["Lin Feng", "I will hold it as long as I want to. And when I am tired, I will ask for help. That is the only sky worth holding up."],
	],
	"post:s_break10": [
		["Narrator", "Five colours of lightning settle into the seams of the sky like mortar between stones. Lin Feng becomes a Primordial Sovereign, and for the first time the sky is held up by people who are glad to do it."],
		["Yue Ling", "Red, yellow, blue, white. And the black stone?"],
		["Echo of Nuwa", "Look up."],
		["Narrator", "The night sky over the world is black again, clean and deep and scattered with stars that stay where they are. The fifth stone was never a stone. It was the night itself, given back."],
		["Narrator", "In the Azure Cloud Sect, Elder Qing Xuan sets down his books, walks out onto the steps, and finds a broom leaning against the gate. He smiles, and starts to sweep."],
	],
}
