class_name Data
extends RefCounted
## Static game content: realms, skills, enemies, areas, quest chain and dialogue.

const MAX_LEVEL := 60
const REALMS := ["Qi Condensation", "Foundation Establishment", "Golden Core", "Nascent Soul", "Deity Transformation", "Void Refinement", "Dao Merging", "Mahayana", "True Immortal", "Dao Ancestor", "Primordial Sovereign", "Samsara Transcendence", "Boundless Heart", "Star River Crossing", "Sun-Moon Harmony", "Mountain-River Oneness", "Three Realms Concord", "Ten Thousand Waters Return", "Myriad Daos as One", "Karma Fulfilled", "Kindred Dao"]
const STAGES := ["Early", "Middle", "Late"]
const EXP_NEED := [124, 228, 352, 538, 787, 1076, 1490, 1987, 2588, 3416, 4450, 5692, 13200, 17400, 22500, 28800, 36600, 46500, 34000, 41000, 49000, 58000, 68000, 80000, 140000, 160000, 230000, 200000, 230000, 280000, 225000, 262000, 315000, 360000, 400000, 450000, 470000, 505000, 545000, 580000, 605000, 615000, 650000, 675000, 700000, 705000, 725000, 750000, 775000, 800000, 830000, 520000, 580000, 640000, 400000, 440000, 480000, 330000, 370000, 410000]
const ENEMY_EXP := [4, 8, 12, 19, 28, 39, 54, 72, 93, 123, 161, 206, 260, 320, 390, 470, 560, 660, 770, 880, 1000, 1130, 1270, 1420, 1580, 1750, 1930, 2120, 2320, 2530, 2750, 2980, 3220, 3470, 3730, 4000, 4280, 4580, 4900, 5240, 5600, 5980, 6380, 6800, 7240, 7700, 8170, 8650, 9140, 9640, 10160, 10700, 11250, 11820, 12400, 12990, 13590, 14200, 14820, 15450, 16100]
const ELEM_COLORS := {
	"phys": Color("d8d8e0"), "fire": Color("ff7a45"), "water": Color("5aa9ff"),
	"wood": Color("6fe08a"), "earth": Color("d9a35a"), "thunder": Color("f6e85c"), "dark": Color("b06cff"),
}

static func level_name(l: int) -> String:
	return "%s %s" % [STAGES[l % 3], REALMS[int(l / 3)]]

static func realm_cap(l: int) -> bool:
	return l % 3 == 2 and l < MAX_LEVEL

# ---------------------------------------------------------------- what a realm means (Part XII)
## The major realm of a cultivation level (0 Qi Condensation ... 17 Ten Thousand Waters Return).
static func realm_of(l: int) -> int:
	return int(l / 3)

## Realm suppression: a cultivator a whole realm above another weighs on them (every blow lands harder
## and every blow taken lands softer), two realms above crushes them, and a beast two realms below a
## cultivator will not even fight (Main.interact).  The multiplier on damage dealt by a fighter of
## level `att` to one of level `def`, capped at three realms either way.  Heavenly Tribulations are
## not cultivators and press equally on everyone.
const SUPPRESS := 0.2
const SUPPRESS_CAP := 3
static func suppression(att: int, def: int) -> float:
	var d := clampi(realm_of(att) - realm_of(def), -SUPPRESS_CAP, SUPPRESS_CAP)
	return 1.0 + SUPPRESS * d if d >= 0 else 1.0 / (1.0 + SUPPRESS * -d)

## A pack whose strongest member is this many realms below Lin Feng scatters before his aura.
const AURA_FLEE := 2

## How long a cultivator of each realm lives (years), how the world addresses them, and what the
## realm is like from the inside (the Cultivation page shows it; townsfolk speak to it).
const REALM_INFO := [
	{"life": 120, "title": "young friend", "note": "Qi gathers in the dantian like rain in a pond. A mortal could still beat you in a fair fight, and might."},
	{"life": 200, "title": "young friend", "note": "The qi is poured into a foundation, the way a house is: everything after stands on it."},
	{"life": 500, "title": "Daoist friend", "note": "The qi condenses into a golden core. Lesser beasts can smell it and keep their distance."},
	{"life": 1000, "title": "Daoist friend", "note": "The core cracks and a small self is born inside it, the nascent soul, which can leave the body for a while and come back."},
	{"life": 2000, "title": "senior", "note": "The soul and the body learn to change places. Cultivators of this realm found sects; their names go into the histories."},
	{"life": 5000, "title": "senior", "note": "The body is refined back towards the void it came from. You can feel the seams of the world, if you are careful."},
	{"life": 10000, "title": "elder", "note": "Your Dao and the Dao of the world begin to run together. You can hear the land think."},
	{"life": 20000, "title": "elder", "note": "The great vehicle: carried by the Dao rather than carrying yourself towards it. Most sects have never seen one."},
	{"life": 100000, "title": "Immortal", "note": "Your name would once have been written in the sky. Nobody writes it now; you are an immortal all the same."},
	{"life": 1000000, "title": "Immortal Lord", "note": "Ancestors of the Dao are said to hold up the sky. You know better: the sky holds itself up, if it is asked kindly."},
	{"life": 0, "title": "Sovereign", "note": "The realm of the first things: chaos, the four pillars, the colours of Nuwa's stones. Lifespan stops being a number."},
	{"life": 0, "title": "Venerable", "note": "Death and rebirth turn round you like a wheel round its axle. The dead know your name, and nod."},
	{"life": 0, "title": "Venerable", "note": "No border holds you, and you hold none. Every road is one road."},
	{"life": 0, "title": "Star-Crosser", "note": "You can walk the Silver River from bank to bank. The stars in the water are real, and so are you."},
	{"life": 0, "title": "Star-Crosser", "note": "The sun and the moon take turns in you. Nobody has to have nine days of noon ever again."},
	{"life": 0, "title": "Sage", "note": "The land keeps its own shape inside you, mountains and rivers, and you do not tell it what that shape should be."},
	{"life": 0, "title": "Sage of the Ladder", "note": "Heaven above, earth below and the middle world in your hands, held the way a ladder is held for somebody else."},
	{"life": 0, "title": "Sage of the Ladder", "note": "Every water in the world comes home through you: the rain, the rivers, the sea and the Silver River. Nothing returns empty."},
	{"life": 0, "title": "Sage of Many Roads", "note": "Every road you have walked runs through you at once, and you never have to choose between them. Nobody does. That was the secret all along."},
	# Part XIV: every cause he set moving has met its effect, and nothing is owed either way
	{"life": 0, "title": "Settled One", "note": "Every cause you set moving has come home and been answered. Nothing is owed you and you owe nothing; the threads of other lives still run through yours, but none of them pulls."},
	# Part XV (the Lotus release): nobody reaches the top alone
	{"life": 0, "title": "Kindred Sage", "note": "Nobody ever reached the top of the mountain alone. Everyone who walked beside you is part of your Dao now, and you of theirs; you carry them the way a river carries the sky, and they carry you back."},
]

## Townsfolk notice a cultivator's realm: one of these joins their chat now and then (by realm band:
## 0-1, 2-3, 4-5, 6-8, 9-12, 13 and above).  `%s` is how they address Lin Feng.
const REALM_GREETS := [
	"Morning, %s. Mind the puddles.",
	"A Golden Core? At your age? Forgive me, %s, I will stop staring in a moment.",
	"The air goes still when you come near, %s. Like before a storm. A nice storm.",
	"My grandmother told stories about cultivators like you, %s. They were all made up. You are not.",
	"I bowed before I knew I was going to, %s. My knees decided on their own.",
	"Even the birds go quiet when you pass, %s. Then they start up again, louder, as if they wanted you to hear.",
]
static func realm_band(l: int) -> int:
	var r := realm_of(l)
	if r <= 1:
		return 0
	if r <= 3:
		return 1
	if r <= 5:
		return 2
	if r <= 8:
		return 3
	if r <= 12:
		return 4
	return 5

# ---------------------------------------------------------------- the Nine Heavens root (Part XII)
## Lin Feng's root has nine branches, and each is a talent.  They sleep until something wakes them:
## the first time his qi stirs, every Heavenly Tribulation he survives and every one of the Founder's
## sealed caves on the mountain wakes one rank of a branch, and he chooses which.  `fx` holds what one
## rank adds (Game.talent_mod reads it); a rank-three branch also has a `crown`, a power of its own.
const TALENT_ORDER := ["sword_bone", "thunder_root", "five_phase", "yin_root", "vajra", "qi_sea", "insight", "fortune", "spirit_sense"]
const TALENT_MAX := 3
const TALENT_RANKS := ["asleep", "stirring", "awake", "in full leaf"]
const TALENTS := {
	"sword_bone": {"n": "Sword Bone", "col": Color("e0e8f8"),
		"desc": "A bone that remembers every cut it was ever part of. The plain sword strike and the sword techniques cut deeper with each rank, and so does every technique aimed at a single foe.",
		"per": "Sword Strike and physical techniques +22%, single-target techniques +6%",
		"crown": "Sword intent: Lin Feng's first blow of every battle lands as a critical strike.",
		"fx": {"strike": 0.22, "phys": 0.22, "one": 0.06}},
	"thunder_root": {"n": "Thunder Root", "col": Color("f6e85c"),
		"desc": "The branch that drinks lightning. Thunder techniques strike harder with each rank; at the crown, lightning answers lightning.",
		"per": "thunder techniques +18%",
		"crown": "Thunder answers thunder: a thunder technique that finds a weakness strikes the foe again for half as much.",
		"fx": {"thunder": 0.18}},
	"five_phase": {"n": "Five-Phase Root", "col": Color("8ae0a0"),
		"desc": "Fire, water, wood and earth, turning into one another the way the seasons do. Techniques of all four grow stronger with each rank.",
		"per": "fire, water, wood and earth techniques +12%",
		"crown": "The phases turn: a technique that strikes every foe at once costs a fifth less qi.",
		"fx": {"fire": 0.12, "water": 0.12, "wood": 0.12, "earth": 0.12}},
	"yin_root": {"n": "Yin Root", "col": Color("b890ff"),
		"desc": "The branch that grows towards the dark: the void, the turning of the wheel, the far side of the mirror. Dark techniques strike harder with each rank.",
		"per": "dark techniques +18%",
		"crown": "What the dark takes, it keeps: a dark technique heals Lin Feng for a tenth of the harm it does.",
		"fx": {"dark": 0.18}},
	"vajra": {"n": "Vajra Body", "col": Color("e8b860"),
		"desc": "Flesh tempered like the diamond-thunderbolt of the old sutras. More health and less harm from every blow with each rank.",
		"per": "health +10%, harm taken -5%",
		"crown": "Unbreakable: once in every battle a blow that would fell Lin Feng leaves him standing with one breath.",
		"fx": {"hp": 0.10, "taken": 0.05}},
	"qi_sea": {"n": "Sea of Qi", "col": Color("7ec8ff"),
		"desc": "A dantian as deep as the Eastern Sea. More qi, more qi gathered every turn, and every technique a little cheaper.",
		"per": "qi +10%, +1% qi each turn, techniques cost 3% less",
		"crown": "The tide comes in: once in every battle, when Lin Feng's qi runs low, a third of it floods back.",
		"fx": {"qi": 0.10, "regen": 0.01, "cost": 0.03}},
	"insight": {"n": "Enlightened Mind", "col": Color("ffe0a0"),
		"desc": "Comprehension, the talent the old masters prized above every other: meditation goes deeper, battles teach more and every Dao is learned faster.",
		"per": "meditation +12%, cultivation from battle +6%",
		"crown": "One insight opens three doors: every battle teaches the Dao Lin Feng walks twice as much.",
		"fx": {"med": 0.12, "exp": 0.06}},
	"fortune": {"n": "Heaven's Favour", "col": Color("ffd060"),
		"desc": "Luck, which cultivators pretend not to believe in and all of them want. More spirit stones, more pills found and more blows that land true.",
		"per": "spirit stones +15%, critical strikes +3%, pills found +8%",
		"crown": "Fortune favours the bold: a boss always leaves a third healing pill behind.",
		"fx": {"stones": 0.15, "crit": 0.03, "drop": 0.08}},
	"spirit_sense": {"n": "Spirit Sense", "col": Color("a8f0e0"),
		"desc": "The divine sense that reaches past the eyes. Lin Feng acts sooner and slips more blows with each rank, and from the first rank he can feel the caches other cultivators hid.",
		"per": "speed +2, slip 3% of blows; reveals hidden caches",
		"crown": "Nothing is hidden: Lin Feng moves first in every battle, and foes miss him a little more often.",
		"fx": {"spd": 2.0, "evade": 0.03}},
}

# ---------------------------------------------------------------- skills
# tgt: one | all | ally | allies.  "revive": the heal also raises fallen allies (Lotus of Rebirth and later)
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
	# ---- Part VI
	"wheelcut": {"n": "Six Paths Wheel Slash", "cost": 230, "mult": 19.5, "elem": "dark", "tgt": "one", "lv": 30, "who": 0},
	"lanternrain": {"n": "Ten Thousand Lantern Rain", "cost": 200, "mult": 5.0, "elem": "fire", "tgt": "all", "lv": 31, "who": 0},
	"samsara": {"n": "Samsara Sword", "cost": 260, "mult": 22.5, "elem": "thunder", "tgt": "one", "lv": 32, "who": 0, "after": "s_sp_unforgotten"},
	# ---- Part VII
	"seamcut": {"n": "Seam-Cutting Sword", "cost": 280, "mult": 25.0, "elem": "dark", "tgt": "one", "lv": 33, "who": 0},
	"threadfall": {"n": "Thousand-Thread Rain", "cost": 240, "mult": 5.8, "elem": "wood", "tgt": "all", "lv": 34, "who": 0},
	"boundless": {"n": "Boundless Heart Sword", "cost": 300, "mult": 28.5, "elem": "earth", "tgt": "one", "lv": 35, "who": 0, "after": "s_sk_return"},
	# ---- Part VIII
	"magpiebridge": {"n": "Magpie Bridge Sword", "cost": 320, "mult": 31.5, "elem": "wood", "tgt": "one", "lv": 36, "who": 0},
	"starriver": {"n": "Silver River Torrent", "cost": 280, "mult": 6.6, "elem": "water", "tgt": "all", "lv": 37, "who": 0},
	"reunion": {"n": "Seventh-Night Reunion Sword", "cost": 350, "mult": 35.0, "elem": "thunder", "tgt": "one", "lv": 38, "who": 0, "after": "s_wv_return"},
	# ---- Part IX
	"noonsplit": {"n": "Noon-Splitting Sword", "cost": 370, "mult": 38.5, "elem": "fire", "tgt": "one", "lv": 39, "who": 0},
	"ninesuns": {"n": "Fall of the Nine Suns", "cost": 310, "mult": 7.4, "elem": "earth", "tgt": "all", "lv": 40, "who": 0},
	"tentharrow": {"n": "Tenth Arrow Sword", "cost": 400, "mult": 42.5, "elem": "water", "tgt": "one", "lv": 41, "who": 0, "after": "s_fs_return"},
	# ---- Part X
	"dragongate": {"n": "Dragon Gate Leap", "cost": 420, "mult": 46.5, "elem": "thunder", "tgt": "one", "lv": 42, "who": 0},
	"swelling": {"n": "Swelling Earth Rampart", "cost": 345, "mult": 8.2, "elem": "earth", "tgt": "all", "lv": 43, "who": 0},
	"cauldron": {"n": "Nine Cauldrons Sword", "cost": 450, "mult": 51.0, "elem": "earth", "tgt": "one", "lv": 44, "who": 0, "after": "s_ts_return"},
	# ---- Part XI
	"standing_tree": {"n": "Strike of the Standing Tree", "cost": 470, "mult": 55.0, "elem": "wood", "tgt": "one", "lv": 45, "who": 0},
	"springs_torrent": {"n": "Torrent of the Nine Springs", "cost": 380, "mult": 9.2, "elem": "water", "tgt": "all", "lv": 46, "who": 0},
	"concord": {"n": "Three Realms Concord Sword", "cost": 500, "mult": 60.0, "elem": "thunder", "tgt": "one", "lv": 47, "who": 0, "after": "s_yd_houtu"},
	# ---- Part XII
	"returning_tide": {"n": "Returning Tide Sword", "cost": 520, "mult": 64.0, "elem": "water", "tgt": "one", "lv": 48, "who": 0},
	"isles_rain": {"n": "Rain over the Five Isles", "cost": 410, "mult": 10.2, "elem": "wood", "tgt": "all", "lv": 49, "who": 0},
	"jingwei_stone": {"n": "Jingwei's Stone Sword", "cost": 560, "mult": 70.0, "elem": "earth", "tgt": "one", "lv": 50, "who": 0, "after": "s_yz_return"},
	# the Dao techniques (Part XI): each Dao teaches one once its walker is an Adept (see DAOS)
	"myriad_swords": {"n": "Ten Thousand Swords Return to One", "cost": 440, "mult": 54.0, "elem": "phys", "tgt": "one", "lv": 45, "who": 0, "dao": "sword"},
	"peng_wind": {"n": "Peng's Wind of Ninety Thousand Li", "cost": 350, "mult": 9.0, "elem": "wood", "tgt": "all", "lv": 45, "who": 0, "dao": "wander"},
	"lotus_heart": {"n": "Lotus Heart Sutra", "cost": 160, "heal": 0.8, "elem": "water", "tgt": "allies", "lv": 45, "who": 0, "dao": "heart", "revive": true},
	"bagua_array": {"n": "Eight Trigrams Grand Array", "cost": 340, "mult": 8.8, "elem": "earth", "tgt": "all", "lv": 45, "who": 0, "dao": "formation"},
	"nine_turn": {"n": "Nine-Turn Golden Elixir Fire", "cost": 330, "mult": 8.6, "elem": "fire", "tgt": "all", "lv": 45, "who": 0, "dao": "alchemy"},
	"mirror_moon": {"n": "Mirror-Flower, Water-Moon", "cost": 420, "mult": 52.0, "elem": "dark", "tgt": "one", "lv": 45, "who": 0, "dao": "illusion"},
	"needle": {"n": "Jade Needle", "cost": 0, "mult": 1.0, "elem": "wood", "tgt": "one", "lv": 0, "who": 1},
	"rain": {"n": "Spring Rain", "cost": 16, "heal": 0.35, "elem": "water", "tgt": "allies", "lv": 0, "who": 1},
	"lotus_burst": {"n": "Lotus Burst", "cost": 22, "mult": 1.4, "elem": "water", "tgt": "all", "lv": 4, "who": 1},
	"starlight": {"n": "Starlight Rain", "cost": 40, "heal": 0.5, "elem": "water", "tgt": "allies", "lv": 13, "who": 1},
	"dawn": {"n": "Dawn Lotus", "cost": 60, "heal": 0.7, "elem": "water", "tgt": "allies", "lv": 20, "who": 1},
	"seal_bloom": {"n": "Seal Bloom", "cost": 85, "heal": 0.85, "elem": "water", "tgt": "allies", "lv": 26, "who": 1},
	"mending": {"n": "Nuwa's Mending", "cost": 110, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 28, "who": 1},
	"lantern_ward": {"n": "Spirit Lantern Ward", "cost": 75, "mult": 3.9, "elem": "fire", "tgt": "all", "lv": 30, "who": 1},
	"rebirth": {"n": "Lotus of Rebirth", "cost": 95, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 31, "who": 1, "revive": true},
	"silk_snare": {"n": "Silver Silk Snare", "cost": 85, "mult": 4.6, "elem": "wood", "tgt": "all", "lv": 33, "who": 1},
	"homeward": {"n": "Homeward Lantern", "cost": 105, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 34, "who": 1, "revive": true},
	"starweave": {"n": "Starweave Net", "cost": 95, "mult": 5.3, "elem": "wood", "tgt": "all", "lv": 36, "who": 1},
	"magpie_wing": {"n": "Magpie Wing Ward", "cost": 115, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 37, "who": 1, "revive": true},
	"osmanthus_rain": {"n": "Osmanthus Moon Rain", "cost": 105, "mult": 6.0, "elem": "wood", "tgt": "all", "lv": 39, "who": 1},
	"moon_dew": {"n": "Moon-Dew Ward", "cost": 125, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 40, "who": 1, "revive": true},
	"reed_boat": {"n": "Reed-Boat Blossom", "cost": 115, "mult": 6.6, "elem": "wood", "tgt": "all", "lv": 42, "who": 1},
	"river_mother": {"n": "River-Mother's Ward", "cost": 135, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 43, "who": 1, "revive": true},
	"feather_rain": {"n": "Rain of Phoenix Feathers", "cost": 125, "mult": 7.2, "elem": "wood", "tgt": "all", "lv": 45, "who": 1},
	"jianmu_ward": {"n": "Ward of the Standing Tree", "cost": 145, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 46, "who": 1, "revive": true},
	# ---- Part XII
	"pearl_spray": {"n": "Spray of the Pearl Trees", "cost": 135, "mult": 7.8, "elem": "wood", "tgt": "all", "lv": 48, "who": 1},
	"mazu_lantern": {"n": "Mazu's Red Lantern", "cost": 155, "heal": 1.0, "elem": "water", "tgt": "allies", "lv": 49, "who": 1, "revive": true, "after": "s_p12_shore"},
	"thread": {"n": "Five-Colour Thread", "cost": 60, "mult": 3.2, "elem": "earth", "tgt": "all", "lv": 27, "who": 1},
}

static func known_skills(who: int, level: int, step: int = 1 << 20) -> Array:
	var out := []
	for id in SKILLS:
		var s = SKILLS[id]
		# (a Dao's technique comes from walking that Dao: Game.dao_skills)
		if s.has("dao"):
			continue
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
	"thunder_ape": {"n": "Thunder Ape", "elem": "thunder", "weak": "earth", "col": Color("9a7ad8"), "shape": "ape"},
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
	"thunder_qilin": {"n": "Thunder Qilin", "elem": "thunder", "weak": "earth", "col": Color("ffe8a0"), "shape": "qilin"},
	"light_wisp": {"n": "Dawn Wisp", "elem": "phys", "weak": "dark", "col": Color("fffbe0"), "shape": "wisp"},
	# bosses
	"crab_general": {"n": "Armored Crab General", "elem": "water", "weak": "thunder", "col": Color("d0502a"), "shape": "crab", "boss": true},
	"tide_hydra": {"n": "Many-Headed Tide Hydra", "elem": "water", "weak": "thunder", "col": Color("2a9a8a"), "shape": "serpent", "boss": true},
	"cinder_behemoth": {"n": "Cinder Behemoth", "elem": "fire", "weak": "water", "col": Color("c04a1a"), "shape": "golem", "boss": true},
	"star_devourer": {"n": "Star Devourer", "elem": "dark", "weak": "thunder", "col": Color("8a60ff"), "shape": "jelly", "boss": true},
	"lightning_magistrate": {"n": "Lightning Magistrate", "elem": "thunder", "weak": "earth", "col": Color("d8e8ff"), "shape": "storm", "boss": true},
	"siren_queen": {"n": "Siren Queen", "elem": "water", "weak": "thunder", "col": Color("4ac0c8"), "shape": "wraith", "boss": true},
	"dragon_king": {"n": "Azure Dragon King", "elem": "water", "weak": "thunder", "col": Color("3a8ad8"), "shape": "dragon", "boss": true, "pal": {"sec": Color("e8b030"), "under": Color("f2e2a8"), "mark": Color("16325c"), "acc": Color("ff5a36")}},
	"lava_titan": {"n": "Lava Titan", "elem": "fire", "weak": "water", "col": Color("e0501a"), "shape": "golem", "boss": true},
	"ash_phoenix": {"n": "Ash Phoenix", "elem": "fire", "weak": "water", "col": Color("ff8a2a"), "shape": "phoenix", "boss": true},
	"inferno_lord": {"n": "Inferno Lord Chi Yan", "elem": "fire", "weak": "water", "col": Color("ff3a1a"), "shape": "demon", "boss": true},
	"rift_weaver": {"n": "Rift Weaver", "elem": "dark", "weak": "fire", "col": Color("6a40b0"), "shape": "spider", "boss": true},
	"void_sentinel": {"n": "Void Sentinel", "elem": "dark", "weak": "thunder", "col": Color("4a3a78"), "shape": "golem", "boss": true},
	"chaos_serpent": {"n": "Chaos Serpent", "elem": "dark", "weak": "fire", "col": Color("9a50e0"), "shape": "serpent", "boss": true},
	"heaven_general": {"n": "Heavenly General Tian Wei", "elem": "phys", "weak": "dark", "col": Color("e8d080"), "shape": "demon", "boss": true},
	"azure_qilin": {"n": "Azure Qilin", "elem": "thunder", "weak": "earth", "col": Color("80d0ff"), "shape": "qilin", "boss": true},
	"heavenly_emperor": {"n": "Jade Emperor of Ruin", "elem": "thunder", "weak": "dark", "col": Color("fff0a0"), "shape": "phoenix", "boss": true},
	"iron_fang": {"n": "Iron Fang", "elem": "phys", "weak": "water", "col": Color("c0603a"), "shape": "humanoid", "boss": true},
	"bamboo_spirit": {"n": "Ancient Bamboo Spirit", "elem": "wood", "weak": "fire", "col": Color("4fc07a"), "shape": "plant", "boss": true},
	"marsh_hag": {"n": "Marsh Hag", "elem": "dark", "weak": "fire", "col": Color("7a4a8f"), "shape": "wraith", "boss": true},
	"frost_wyrm": {"n": "Frost Wyrm", "elem": "water", "weak": "thunder", "col": Color("8fd0ff"), "shape": "dragon", "boss": true},
	"thunder_roc": {"n": "Thunder Roc", "elem": "thunder", "weak": "earth", "col": Color("ffe05a"), "shape": "bird", "boss": true},
	"jade_mantis": {"n": "Jade Mantis Matriarch", "elem": "wood", "weak": "fire", "col": Color("5fd890"), "shape": "mantis", "boss": true},
	"bog_colossus": {"n": "Bog Colossus", "elem": "water", "weak": "fire", "col": Color("6a7a3a"), "shape": "blob", "boss": true},
	"ice_empress": {"n": "Ice Empress", "elem": "water", "weak": "fire", "col": Color("c8e8ff"), "shape": "wraith", "boss": true},
	"storm_ape_king": {"n": "Storm Ape King", "elem": "thunder", "weak": "earth", "col": Color("b08aff"), "shape": "ape", "boss": true},
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
	"jade_lion": {"n": "Jade Guardian Lion", "elem": "earth", "weak": "wood", "col": Color("5ac0a0"), "shape": "tiger"},
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
	"twin_lions": {"n": "Twin Lions of the Jade Gate", "elem": "earth", "weak": "wood", "col": Color("40b090"), "shape": "tiger", "boss": true},
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
	"ice_lynx": {"n": "Ice Lynx", "elem": "water", "weak": "thunder", "col": Color("c8e0f8"), "shape": "tiger"},
	"chaos_eel": {"n": "Chaos Eel", "elem": "dark", "weak": "thunder", "col": Color("8040c0"), "shape": "serpent"},
	"primal_jelly": {"n": "Primal Jelly", "elem": "dark", "weak": "fire", "col": Color("c060ff"), "shape": "jelly"},
	"faceless_spawn": {"n": "Faceless Spawn", "elem": "dark", "weak": "fire", "col": Color("c04030"), "shape": "hundun"},
	# ---- Part V bosses
	"glass_scorpion": {"n": "Glass Scorpion King", "elem": "earth", "weak": "wood", "col": Color("e8d8a0"), "shape": "scorpion", "boss": true},
	"dune_leviathan": {"n": "Dune Leviathan", "elem": "earth", "weak": "wood", "col": Color("c8a060"), "shape": "dragon", "boss": true},
	"star_colossus": {"n": "Star-Iron Colossus", "elem": "fire", "weak": "water", "col": Color("8a7ae0"), "shape": "golem", "boss": true},
	"white_tiger": {"n": "Bai Hu, White Tiger of the West", "elem": "earth", "weak": "fire", "col": Color("f4f4ff"), "shape": "tiger", "boss": true, "pal": {"sec": Color("b8bccc"), "under": Color("ffffff"), "mark": Color("1c1c26"), "acc": Color("f0c040")}},
	"spore_mother": {"n": "Mother of Spores", "elem": "wood", "weak": "fire", "col": Color("c070e0"), "shape": "mushroom", "boss": true},
	"moth_queen": {"n": "Lantern Moth Queen", "elem": "fire", "weak": "water", "col": Color("ffb040"), "shape": "moth", "boss": true},
	"rot_hydra": {"n": "Rot-Root Hydra", "elem": "wood", "weak": "fire", "col": Color("6a8a40"), "shape": "serpent", "boss": true},
	"vermilion_bird": {"n": "Zhu Que, Vermilion Bird of the South", "elem": "fire", "weak": "water", "col": Color("ff4030"), "shape": "phoenix", "boss": true, "pal": {"sec": Color("ffb020"), "under": Color("ffd8a0"), "mark": Color("7a0c10"), "acc": Color("fff070")}},
	"mammoth_ancestor": {"n": "Mammoth Ancestor", "elem": "water", "weak": "fire", "col": Color("a0b8d0"), "shape": "mammoth", "boss": true},
	"aurora_serpent": {"n": "Aurora Serpent", "elem": "thunder", "weak": "earth", "col": Color("60f0c0"), "shape": "dragon", "boss": true},
	"lynx_matriarch": {"n": "Frost Lynx Matriarch", "elem": "water", "weak": "thunder", "col": Color("d0e8ff"), "shape": "tiger", "boss": true},
	"black_tortoise": {"n": "Xuan Wu, Black Tortoise of the North", "elem": "water", "weak": "earth", "col": Color("3a4a6a"), "shape": "tortoise", "boss": true, "pal": {"sec": Color("2e5a50"), "under": Color("c8b888"), "mark": Color("c8a050"), "acc": Color("40e0c8")}},
	"first_lightning": {"n": "The First Lightning", "elem": "thunder", "weak": "earth", "col": Color("f0f0ff"), "shape": "storm", "boss": true},
	"pangu_shadow": {"n": "Shadow of Pangu", "elem": "earth", "weak": "wood", "col": Color("6a5040"), "shape": "demon", "boss": true},
	"ancestor_took": {"n": "The Ancestor Who Took", "elem": "dark", "weak": "thunder", "col": Color("402050"), "shape": "humanoid", "boss": true},
	"hundun": {"n": "Hundun, the Faceless Chaos", "elem": "dark", "weak": "thunder", "col": Color("e05030"), "shape": "hundun", "boss": true, "pal": {"sec": Color("f0b830"), "under": Color("ffd890"), "mark": Color("5a1008"), "acc": Color("ffe040")}},
	# ---- Part VI monsters
	"maple_fox": {"n": "Maple Fox Spirit", "elem": "fire", "weak": "water", "col": Color("e8783a"), "shape": "fox"},
	"lost_lantern": {"n": "Lost Soul Lantern", "elem": "dark", "weak": "thunder", "col": Color("ffc860"), "shape": "wisp"},
	"mossback_boar": {"n": "Mossback Boar", "elem": "earth", "weak": "wood", "col": Color("7a6a4a"), "shape": "beast"},
	"river_carp": {"n": "Nine-Bend Carp", "elem": "water", "weak": "thunder", "col": Color("ff9050"), "shape": "carp"},
	"stone_macaque": {"n": "Stone Macaque", "elem": "earth", "weak": "wood", "col": Color("a8a090"), "shape": "ape"},
	"mist_heron": {"n": "Mist Heron", "elem": "wood", "weak": "fire", "col": Color("d8e0e8"), "shape": "bird"},
	"hopping_corpse": {"n": "Hopping Corpse", "elem": "dark", "weak": "fire", "col": Color("5a7a6a"), "shape": "jiangshi"},
	"hungry_ghost": {"n": "Hungry Ghost", "elem": "dark", "weak": "thunder", "col": Color("8a9ab0"), "shape": "wraith"},
	"lily_moth": {"n": "Spider-Lily Moth", "elem": "fire", "weak": "water", "col": Color("e83a3a"), "shape": "moth"},
	"ghost_clerk": {"n": "Clerk of the Dead", "elem": "dark", "weak": "fire", "col": Color("3a4a6a"), "shape": "humanoid"},
	"pool_crab": {"n": "Blood-Pool Crab", "elem": "water", "weak": "thunder", "col": Color("a02a2a"), "shape": "crab"},
	"court_hound": {"n": "Hound of the Ten Courts", "elem": "fire", "weak": "water", "col": Color("4a3040"), "shape": "fox"},
	# ---- Part VI bosses
	"nine_tail_fox": {"n": "Nine-Tailed Fox of the Gorge", "elem": "fire", "weak": "water", "col": Color("ff6a30"), "shape": "fox", "boss": true, "pal": {"sec": Color("c8401a"), "under": Color("fff2e0"), "mark": Color("2a1010"), "acc": Color("7ad8ff")}},
	"waterfall_koi": {"n": "Koi King of the Hanging Falls", "elem": "water", "weak": "thunder", "col": Color("ffb060"), "shape": "carp", "boss": true},
	"willow_widow": {"n": "The Willow Widow", "elem": "wood", "weak": "fire", "col": Color("8ab0a0"), "shape": "wraith", "boss": true},
	"ox_head": {"n": "Ox-Head, Runner of the Ten Courts", "elem": "earth", "weak": "wood", "col": Color("6a3a2a"), "shape": "oxhead", "boss": true},
	"cormorant_king": {"n": "Cormorant Tyrant", "elem": "thunder", "weak": "earth", "col": Color("2a2a30"), "shape": "bird", "boss": true},
	"karst_jiao": {"n": "Jiao of the Nine Bends", "elem": "water", "weak": "thunder", "col": Color("4a9a8a"), "shape": "dragon", "boss": true},
	"stone_sentinel": {"n": "Sentinel of the Stone Forest", "elem": "earth", "weak": "wood", "col": Color("b0aca0"), "shape": "golem", "boss": true},
	"horse_face": {"n": "Horse-Face, Runner of the Ten Courts", "elem": "fire", "weak": "water", "col": Color("8a4a3a"), "shape": "horseface", "boss": true},
	"corpse_patriarch": {"n": "Corpse Patriarch Jiang", "elem": "dark", "weak": "fire", "col": Color("3a5a4a"), "shape": "jiangshi", "boss": true},
	"bridge_serpent": {"n": "Serpent Beneath the Naihe Bridge", "elem": "dark", "weak": "thunder", "col": Color("c04040"), "shape": "serpent", "boss": true},
	"lily_empress": {"n": "Empress of the Red Lilies", "elem": "wood", "weak": "fire", "col": Color("e02a2a"), "shape": "plant", "boss": true},
	"the_unforgotten": {"n": "The Thousand Unforgotten", "elem": "dark", "weak": "thunder", "col": Color("c0c8e0"), "shape": "wraith", "boss": true},
	"karma_mirror": {"n": "Mirror of Karma", "elem": "thunder", "weak": "earth", "col": Color("c8b880"), "shape": "golem", "boss": true},
	"burning_judge": {"n": "Judge of the Burning Court", "elem": "fire", "weak": "water", "col": Color("c03020"), "shape": "demon", "boss": true},
	"wheel_guardian": {"n": "Guardian of the Six Paths", "elem": "earth", "weak": "wood", "col": Color("6a6a7a"), "shape": "tortoise", "boss": true},
	"king_yama": {"n": "King Yama, Lord of the Wheel", "elem": "dark", "weak": "thunder", "col": Color("2a2a4a"), "shape": "humanoid", "boss": true},
	# ---- Part VII: The Unbroken Land
	"thread_moth": {"n": "Silver-Thread Moth", "elem": "wood", "weak": "fire", "col": Color("d8d8f0"), "shape": "moth"},
	"paper_crow": {"n": "Paper Crow", "elem": "phys", "weak": "fire", "col": Color("f0ece0"), "shape": "bird"},
	"silk_bandit": {"n": "Silk-Masked Bandit", "elem": "phys", "weak": "thunder", "col": Color("8a6ab0"), "shape": "humanoid"},
	"tea_beetle": {"n": "Jade Tea Beetle", "elem": "earth", "weak": "fire", "col": Color("4a9a5a"), "shape": "crab"},
	"terrace_serpent": {"n": "Terrace Serpent", "elem": "water", "weak": "earth", "col": Color("5ab0a0"), "shape": "serpent"},
	"hill_sprite": {"n": "Mist-Hill Sprite", "elem": "water", "weak": "thunder", "col": Color("c8f0e8"), "shape": "wisp"},
	"silkworm": {"n": "Ravenous Silkworm", "elem": "wood", "weak": "fire", "col": Color("f0f0e0"), "shape": "blob"},
	"silk_moth": {"n": "Mulberry Moth", "elem": "wood", "weak": "fire", "col": Color("e8d8b0"), "shape": "moth"},
	"cocoon_wraith": {"n": "Cocoon Wraith", "elem": "dark", "weak": "thunder", "col": Color("d0c8e0"), "shape": "wraith"},
	"spindle_imp": {"n": "Spindle Imp", "elem": "earth", "weak": "wood", "col": Color("c0904a"), "shape": "demon"},
	"warp_wraith": {"n": "Warp-Thread Wraith", "elem": "dark", "weak": "thunder", "col": Color("b080e0"), "shape": "wraith"},
	"shuttle_hawk": {"n": "Shuttle Hawk", "elem": "thunder", "weak": "earth", "col": Color("e0c060"), "shape": "bird"},
	"paper_tiger": {"n": "The Paper Tiger of Qingshi", "elem": "fire", "weak": "water", "col": Color("f0a040"), "shape": "tiger", "boss": true},
	"scarecrow_king": {"n": "Scarecrow King of the Paddies", "elem": "wood", "weak": "fire", "col": Color("c8a050"), "shape": "plant", "boss": true},
	"well_spider": {"n": "Spider in the Village Well", "elem": "dark", "weak": "fire", "col": Color("6a6a8a"), "shape": "spider", "boss": true},
	"needle_general": {"n": "Needle General Zhen", "elem": "phys", "weak": "thunder", "col": Color("b8c0d8"), "shape": "humanoid", "boss": true},
	"wind_kite": {"n": "The Great Wind Kite", "elem": "thunder", "weak": "earth", "col": Color("e05040"), "shape": "ray", "boss": true},
	"terrace_dragon": {"n": "Dragon of the Nine Terraces", "elem": "water", "weak": "earth", "col": Color("4ac08a"), "shape": "dragon", "boss": true},
	"hill_golem": {"n": "Tea-Hill Golem", "elem": "earth", "weak": "wood", "col": Color("8a7a5a"), "shape": "golem", "boss": true},
	"thread_matron": {"n": "Thread Matron of the Hills", "elem": "wood", "weak": "fire", "col": Color("c0a0e0"), "shape": "spider", "boss": true},
	"silkworm_queen": {"n": "Silkworm Queen", "elem": "wood", "weak": "fire", "col": Color("f8f0d8"), "shape": "serpent", "boss": true},
	"moth_empress": {"n": "Moth Empress of the Mulberries", "elem": "wood", "weak": "fire", "col": Color("e8c890"), "shape": "moth", "boss": true},
	"mulberry_ent": {"n": "The Old Mulberry", "elem": "wood", "weak": "fire", "col": Color("5a7a3a"), "shape": "plant", "boss": true},
	"thousand_hands": {"n": "Thousand Hands of the Spinning Hall", "elem": "dark", "weak": "thunder", "col": Color("9a6ac0"), "shape": "demon", "boss": true},
	"warp_beast": {"n": "Beast of the Tangled Warp", "elem": "dark", "weak": "thunder", "col": Color("7a5aa8"), "shape": "hundun", "boss": true},
	"spindle_golem": {"n": "Spindle Golem", "elem": "earth", "weak": "wood", "col": Color("c09a5a"), "shape": "golem", "boss": true},
	"shuttle_dragon": {"n": "Shuttle Dragon", "elem": "thunder", "weak": "earth", "col": Color("e8d070"), "shape": "dragon", "boss": true},
	"qianxian": {"n": "Madam Qianxian, Lady of a Thousand Threads", "elem": "wood", "weak": "fire", "col": Color("e0d0ff"), "shape": "spider", "boss": true},
	# ---- Part VIII: The River of Heaven
	"flood_carp": {"n": "Star-Flood Carp", "elem": "water", "weak": "earth", "col": Color("a0c0ff"), "shape": "carp"},
	"reed_wisp": {"n": "Reed-Ford Wisp", "elem": "water", "weak": "earth", "col": Color("c8e8ff"), "shape": "wisp"},
	"ferry_crab": {"n": "Ferry-Post Crab", "elem": "earth", "weak": "wood", "col": Color("6a7aa8"), "shape": "crab"},
	"cloud_ape": {"n": "Cloud-Cliff Ape", "elem": "earth", "weak": "wood", "col": Color("b8b0a8"), "shape": "ape"},
	"bridge_magpie": {"n": "Lost Bridge Magpie", "elem": "wood", "weak": "fire", "col": Color("3a4a7a"), "shape": "magpie", "pal": {"sec": Color("2a6ab0"), "under": Color("f4f4f0"), "mark": Color("141826"), "acc": Color("40e0b0")}},
	"gale_wolf": {"n": "Gale Wolf of the Heights", "elem": "thunder", "weak": "earth", "col": Color("a8b8d0"), "shape": "beast"},
	"star_moth": {"n": "Seven-Star Moth", "elem": "fire", "weak": "water", "col": Color("e0d0ff"), "shape": "moth"},
	"loom_wraith": {"n": "Wraith of the Unwoven Sky", "elem": "dark", "weak": "thunder", "col": Color("8090c8"), "shape": "wraith"},
	"star_qilin": {"n": "Star-Mane Qilin", "elem": "thunder", "weak": "earth", "col": Color("c0c8ff"), "shape": "qilin"},
	"kunlun_tiger": {"n": "Kunlun Snow Tiger", "elem": "water", "weak": "earth", "col": Color("e8e8f0"), "shape": "tiger"},
	"jade_qilin": {"n": "Jade Qilin", "elem": "wood", "weak": "fire", "col": Color("6ad0a0"), "shape": "qilin", "pal": {"sec": Color("e8c050"), "under": Color("f4f0d0"), "mark": Color("1a5a48"), "acc": Color("ff6a3a")}},
	"kunlun_peach_sprite": {"n": "Kunlun Peach-Grove Sprite", "elem": "wood", "weak": "fire", "col": Color("ffb0c0"), "shape": "plant"},
	"silt_jiao": {"n": "Jiao of the Silted Ford", "elem": "water", "weak": "earth", "col": Color("5a7ab0"), "shape": "serpent", "boss": true},
	"reed_widow": {"n": "Widow of the Reed Ford", "elem": "dark", "weak": "thunder", "col": Color("a0a8c8"), "shape": "wraith", "boss": true},
	"carp_sage": {"n": "Old Carp Who Would Not Leap", "elem": "water", "weak": "earth", "col": Color("ffc070"), "shape": "carp", "boss": true},
	"tide_qilin": {"n": "Qilin of the Rising Tide", "elem": "water", "weak": "earth", "col": Color("70a0ff"), "shape": "qilin", "boss": true},
	"cloud_ape_king": {"n": "King of the Cloud Apes", "elem": "earth", "weak": "wood", "col": Color("d8d0c8"), "shape": "ape", "boss": true},
	"storm_magpie": {"n": "Storm-Crowned Magpie", "elem": "thunder", "weak": "earth", "col": Color("3a3a5a"), "shape": "magpie", "boss": true},
	"pier_golem": {"n": "Golem of the Fallen Bridge-Pier", "elem": "earth", "weak": "wood", "col": Color("a8a0a0"), "shape": "golem", "boss": true},
	"crow_marshal": {"n": "Crow Marshal of the Broken Bridge", "elem": "dark", "weak": "thunder", "col": Color("2a2a3a"), "shape": "crowmarshal", "boss": true},
	"seven_star_moth": {"n": "Moth of the Seven Stars", "elem": "fire", "weak": "water", "col": Color("f0e0ff"), "shape": "moth", "boss": true},
	"weaving_frame": {"n": "The Celestial Weaving-Frame", "elem": "earth", "weak": "wood", "col": Color("c8b8f0"), "shape": "golem", "boss": true},
	"hall_qilin": {"n": "Qilin of the Weaving Hall", "elem": "thunder", "weak": "earth", "col": Color("d0d8ff"), "shape": "qilin", "boss": true},
	"river_warden": {"n": "Heavenly Warden of the River", "elem": "phys", "weak": "thunder", "col": Color("c8d0f0"), "shape": "warden", "boss": true},
	"kaiming_beast": {"n": "Kaiming, Beast of the Nine Gates", "elem": "fire", "weak": "water", "col": Color("e8a050"), "shape": "kaiming", "boss": true},
	"blue_birds": {"n": "The Three Blue Birds", "elem": "wood", "weak": "fire", "col": Color("40a0e0"), "shape": "phoenix", "boss": true},
	"white_ape": {"n": "White Ape of Kunlun", "elem": "earth", "weak": "wood", "col": Color("f4f4f8"), "shape": "ape", "boss": true},
	"xiwangmu": {"n": "Xiwangmu, Queen Mother of the West", "elem": "earth", "weak": "wood", "col": Color("e8d8a0"), "shape": "queen", "boss": true},
	# ---- Part IX: The Tenth Sun (sun_crow, jade_rabbit and bifang are Blender shapes of their own)
	"noon_cur": {"n": "Noon-Mad Cur", "elem": "fire", "weak": "water", "col": Color("c87a3a"), "shape": "beast"},
	"noon_cicada": {"n": "Long-Noon Cicada", "elem": "wood", "weak": "fire", "col": Color("7a8a3a"), "shape": "moth"},
	"clay_toad": {"n": "Sunbaked Clay Toad", "elem": "earth", "weak": "wood", "col": Color("b8865a"), "shape": "blob"},
	"plague_locust": {"n": "Plague Locust", "elem": "wood", "weak": "fire", "col": Color("a8a040"), "shape": "mantis"},
	"drought_scorpion": {"n": "Cracked-Earth Scorpion", "elem": "earth", "weak": "wood", "col": Color("c8a060"), "shape": "scorpion"},
	"haze_wisp": {"n": "Heat-Haze Wisp", "elem": "fire", "weak": "water", "col": Color("fff0c0"), "shape": "wisp"},
	"spring_macaque": {"n": "Hot-Spring Macaque", "elem": "water", "weak": "thunder", "col": Color("c8a090"), "shape": "ape"},
	"sun_fledgling": {"n": "Sun-Crow Fledgling", "elem": "fire", "weak": "water", "col": Color("f0a028"), "shape": "sun_crow"},
	"fusang_sprite": {"n": "Fusang Leaf-Sprite", "elem": "wood", "weak": "fire", "col": Color("7ab848"), "shape": "plant"},
	"frost_hare": {"n": "Frost Hare of the Moon", "elem": "water", "weak": "thunder", "col": Color("e0e8f8"), "shape": "jade_rabbit"},
	"moon_toad": {"n": "Three-Legged Moon Toad", "elem": "dark", "weak": "fire", "col": Color("8890b0"), "shape": "blob"},
	"silver_crane": {"n": "Silver Crane of the Long Night", "elem": "thunder", "weak": "earth", "col": Color("d0d8e8"), "shape": "bird"},
	"mirage_fox": {"n": "Mirage Fox of the Dry Well", "elem": "dark", "weak": "thunder", "col": Color("f0b050"), "shape": "fox", "boss": true},
	"sundial_golem": {"n": "Golem of the Stopped Sundial", "elem": "earth", "weak": "wood", "col": Color("c8963a"), "shape": "golem", "boss": true},
	"lantern_dragon": {"n": "The Lantern Dragon Nobody Danced", "elem": "wood", "weak": "fire", "col": Color("e04838"), "shape": "dragon", "boss": true},
	"hanba": {"n": "Hanba, the Drought Fiend", "elem": "fire", "weak": "water", "col": Color("8a9a6a"), "shape": "jiangshi", "boss": true},
	"locust_marquis": {"n": "The Locust Marquis", "elem": "wood", "weak": "fire", "col": Color("b0a030"), "shape": "mantis", "boss": true},
	"dust_devil": {"n": "Dust-Devil of the Dry River", "elem": "earth", "weak": "wood", "col": Color("c08050"), "shape": "storm", "boss": true},
	"well_tortoise": {"n": "Old Tortoise of the Village Well", "elem": "water", "weak": "earth", "col": Color("6a7a5a"), "shape": "tortoise", "boss": true},
	"bifang": {"n": "Bifang, the One-Legged Fire Crane", "elem": "fire", "weak": "water", "col": Color("3a9a8a"), "shape": "bifang", "boss": true, "pal": {"sec": Color("1e6a62"), "under": Color("d8eee8"), "mark": Color("e0302a"), "acc": Color("ff6a2a")}},
	"boiled_crab": {"n": "The Crab Who Bathes in Boiling Springs", "elem": "water", "weak": "thunder", "col": Color("e04a2a"), "shape": "crab", "boss": true},
	"ninth_ember": {"n": "Ember of the Ninth Fallen Sun", "elem": "earth", "weak": "wood", "col": Color("ff8a30"), "shape": "wisp", "boss": true},
	"sun_moth": {"n": "The Moth Who Flew at the Sun", "elem": "thunder", "weak": "earth", "col": Color("f0d070"), "shape": "moth", "boss": true},
	"jinwu": {"n": "Jinwu, the Three-Legged Sun Crow", "elem": "fire", "weak": "water", "col": Color("ff9a20"), "shape": "sun_crow", "boss": true, "pal": {"sec": Color("d8401a"), "under": Color("ffd890"), "mark": Color("3a1006"), "acc": Color("fff27a")}},
	"wu_gang": {"n": "Wu Gang, Woodcutter of the Moon", "elem": "phys", "weak": "thunder", "col": Color("7a8aa8"), "shape": "humanoid", "boss": true},
	"tiangou": {"n": "Tiangou, the Dog Who Eats the Moon", "elem": "dark", "weak": "fire", "col": Color("2a2a38"), "shape": "beast", "boss": true, "pal": {"acc": Color("ffd040")}},
	"mortar_rabbit": {"n": "The Jade Rabbit of the Mortar", "elem": "earth", "weak": "wood", "col": Color("f4f8f0"), "shape": "jade_rabbit", "boss": true, "pal": {"sec": Color("b8e0cc"), "under": Color("ffffff"), "mark": Color("6a8a80"), "acc": Color("30c080")}},
	"xihe": {"n": "Xihe, Mother of the Ten Suns", "elem": "fire", "weak": "water", "col": Color("ff7040"), "shape": "phoenix", "boss": true},
	# ---- Part X: The Nine Cauldrons (river, flood, foundry and the broken pillar)
	"gate_carp": {"n": "Dragon-Gate Carp", "elem": "water", "weak": "earth", "col": Color("e0a030"), "shape": "carp"},
	"eel_bandit": {"n": "River-Rat Eel Bandit", "elem": "dark", "weak": "thunder", "col": Color("3a4a3a"), "shape": "serpent"},
	"silt_crab": {"n": "Silt-Shell Crab", "elem": "earth", "weak": "wood", "col": Color("8a7a5a"), "shape": "crab"},
	"flood_toad": {"n": "Paddy Flood-Toad", "elem": "water", "weak": "earth", "col": Color("6a8a4a"), "shape": "blob"},
	"mud_heron": {"n": "Mud-Wading Heron", "elem": "wood", "weak": "fire", "col": Color("d8d0c0"), "shape": "bird"},
	"rice_wraith": {"n": "Drowned-Rice Wraith", "elem": "dark", "weak": "fire", "col": Color("a8b890"), "shape": "wraith"},
	"slag_golem": {"n": "Slag Golem", "elem": "fire", "weak": "water", "col": Color("6a4a3a"), "shape": "golem"},
	"bronze_hound": {"n": "Bronze Taotie Hound", "elem": "earth", "weak": "wood", "col": Color("a87a3a"), "shape": "beast"},
	"charcoal_wisp": {"n": "Charcoal-Pit Wisp", "elem": "fire", "weak": "water", "col": Color("ff7a3a"), "shape": "wisp"},
	"flood_wolf": {"n": "Black-Water Wolf", "elem": "water", "weak": "earth", "col": Color("2a3a4a"), "shape": "beast"},
	"pillar_sentinel": {"n": "Pillar-Shard Sentinel", "elem": "earth", "weak": "wood", "col": Color("8a8a98"), "shape": "golem"},
	"kun_fry": {"n": "Kun-Fish Fry", "elem": "water", "weak": "thunder", "col": Color("3a5a8a"), "shape": "ray"},
	"sulking_carp": {"n": "The Carp Who Would Not Leap", "elem": "water", "weak": "thunder", "col": Color("f0b040"), "shape": "carp", "boss": true},
	"eel_king": {"n": "Black Eel, King of the River-Rats", "elem": "dark", "weak": "fire", "col": Color("2a2a30"), "shape": "serpent", "boss": true, "pal": {"acc": Color("ffd040")}},
	"drowned_bell": {"n": "The Drowned Temple Bell", "elem": "earth", "weak": "wood", "col": Color("8a7a4a"), "shape": "golem", "boss": true},
	"he_bo": {"n": "He Bo, Earl of the Yellow River", "elem": "water", "weak": "earth", "col": Color("c8a050"), "shape": "warden", "boss": true},
	"toad_matriarch": {"n": "The Toad Who Swallowed the Dykes", "elem": "water", "weak": "earth", "col": Color("5a7a4a"), "shape": "blob", "boss": true},
	"heron_lord": {"n": "Heron Lord of the Drowned Paddies", "elem": "wood", "weak": "fire", "col": Color("e8e4d8"), "shape": "bird", "boss": true},
	"mud_dragon": {"n": "Mud Dragon of the Broken Dyke", "elem": "earth", "weak": "wood", "col": Color("7a5a3a"), "shape": "serpent", "boss": true},
	"gun": {"n": "Gun, Who Stole the Swelling Earth", "elem": "earth", "weak": "wood", "col": Color("d8b040"), "shape": "dragon", "boss": true, "pal": {"under": Color("f0e0b0"), "mark": Color("8a6a2a")}},
	"slag_serpent": {"n": "The Slag Serpent of the Casting Pits", "elem": "fire", "weak": "water", "col": Color("c85a2a"), "shape": "serpent", "boss": true},
	"stone_mother": {"n": "The Stone Mother of Tushan", "elem": "earth", "weak": "wood", "col": Color("a8a098"), "shape": "golem", "boss": true},
	"fangfeng": {"n": "Fangfeng, the Giant Who Came Late", "elem": "earth", "weak": "wood", "col": Color("6a7a5a"), "shape": "humanoid", "boss": true},
	"taotie": {"n": "Taotie, the Glutton on the Cauldron", "elem": "dark", "weak": "thunder", "col": Color("6a4a2a"), "shape": "demon", "boss": true, "pal": {"acc": Color("40d0a0")}},
	"xiu": {"n": "Xiu, Gonggong's Son Who Loved Roads", "elem": "water", "weak": "earth", "col": Color("6a8aa8"), "shape": "wraith", "boss": true},
	"kun": {"n": "Kun of the Northern Darkness", "elem": "water", "weak": "thunder", "col": Color("2a3a6a"), "shape": "ray", "boss": true},
	"xiangliu": {"n": "Xiangliu, the Nine-Headed Minister", "elem": "dark", "weak": "earth", "col": Color("4a6a3a"), "shape": "serpent", "boss": true, "pal": {"acc": Color("c8f040")}},
	"stone_lion": {"n": "The Stone Lion of the Ferry Stage", "elem": "earth", "weak": "wood", "col": Color("b8b0a0"), "shape": "tiger", "boss": true, "pal": {"acc": Color("e0b040")}},
	"carrier_turtle": {"n": "The Turtle Who Carried Gun's Earth", "elem": "earth", "weak": "wood", "col": Color("6a6a4a"), "shape": "tortoise", "boss": true},
	"tushan_fox": {"n": "The White Nine-Tailed Fox of Tushan", "elem": "wood", "weak": "fire", "col": Color("f4f0e8"), "shape": "fox", "boss": true, "pal": {"acc": Color("ff8a40")}},
	"kuafu": {"n": "Kuafu, Who Drank the Rivers Dry", "elem": "fire", "weak": "water", "col": Color("a86a4a"), "shape": "ape", "boss": true},
	"gonggong": {"n": "Gonggong, God of the Flood", "elem": "water", "weak": "earth", "col": Color("1a2a4a"), "shape": "dragon", "boss": true, "pal": {"sec": Color("c83020"), "acc": Color("ff6040")}},
	# ---- Part XI: The Ladder of Heaven (the Nine Heavens above the clouds, the Nine Springs below
	# the roots)
	"cloud_kite": {"n": "Cloud Kite", "elem": "wood", "weak": "thunder", "col": Color("d8e8f8"), "shape": "bird"},
	"thunder_mote": {"n": "Loose Thunder-Mote", "elem": "thunder", "weak": "earth", "col": Color("f0e070"), "shape": "wisp"},
	"rain_serpent": {"n": "Rain Serpent Without a Ledger", "elem": "water", "weak": "earth", "col": Color("5a9ac8"), "shape": "serpent"},
	"gate_lion": {"n": "Gilded Gate-Lion", "elem": "earth", "weak": "wood", "col": Color("d8b050"), "shape": "tiger"},
	"fox_wisp": {"n": "Foxfire Wisp", "elem": "fire", "weak": "water", "col": Color("7ab0ff"), "shape": "wisp"},
	"cloud_soldier": {"n": "Cloud-Armour Soldier Still at His Post", "elem": "phys", "weak": "thunder", "col": Color("b8c0d8"), "shape": "humanoid"},
	"root_worm": {"n": "Root-Gnawer Worm", "elem": "earth", "weak": "wood", "col": Color("8a6a4a"), "shape": "serpent"},
	"blindfish": {"n": "Blind Carp of the Black Water", "elem": "water", "weak": "thunder", "col": Color("c8d0d8"), "shape": "carp"},
	"glow_crab": {"n": "Glow-Shell Cave Crab", "elem": "water", "weak": "earth", "col": Color("3ab0a0"), "shape": "crab"},
	"ghost_soldier": {"n": "Ghost Soldier of Youdu", "elem": "dark", "weak": "fire", "col": Color("5a6a7a"), "shape": "humanoid"},
	"paper_horse": {"n": "Paper Horse Who Ran Away", "elem": "wood", "weak": "fire", "col": Color("f0e8d8"), "shape": "qilin"},
	"lantern_shade": {"n": "Lantern Shade", "elem": "fire", "weak": "water", "col": Color("8ab0d8"), "shape": "wraith"},
	"feilian": {"n": "Feilian, Earl of the Wind", "elem": "wood", "weak": "thunder", "col": Color("c8a868"), "shape": "qilin", "boss": true, "pal": {"mark": Color("4a3a2a"), "acc": Color("80f0c0")}},
	"kui": {"n": "Kui, the One-Legged Thunder Ox", "elem": "thunder", "weak": "earth", "col": Color("7a8898"), "shape": "mammoth", "boss": true, "pal": {"acc": Color("fff070")}},
	"jiufeng": {"n": "Jiufeng, the Nine-Headed Phoenix", "elem": "fire", "weak": "water", "col": Color("e05a3a"), "shape": "phoenix", "boss": true, "pal": {"sec": Color("f0c040")}},
	"leigong": {"n": "Leigong, Duke of Thunder", "elem": "thunder", "weak": "earth", "col": Color("4a5a8a"), "shape": "crowmarshal", "boss": true, "pal": {"acc": Color("fff080")}},
	"pixiu": {"n": "Pixiu, Who Ate the Gold of the Gate", "elem": "earth", "weak": "wood", "col": Color("e0b848"), "shape": "tiger", "boss": true, "pal": {"mark": Color("8a5a1a"), "acc": Color("60e0ff")}},
	"shentu": {"n": "Shentu, Door God of the Peach Tree", "elem": "phys", "weak": "thunder", "col": Color("b83a2a"), "shape": "demon", "boss": true},
	"yulei": {"n": "Yulei, Door God of the Reed Rope", "elem": "phys", "weak": "fire", "col": Color("2a5a4a"), "shape": "warden", "boss": true},
	"chong": {"n": "Chong, Who Lifts Heaven", "elem": "thunder", "weak": "earth", "col": Color("6a88c8"), "shape": "humanoid", "boss": true, "pal": {"sec": Color("e8c860"), "acc": Color("fff4c0")}},
	"root_wyrm": {"n": "The Wyrm Who Gnaws the Jianmu", "elem": "earth", "weak": "wood", "col": Color("6a5a3a"), "shape": "serpent", "boss": true, "pal": {"acc": Color("c8f060")}},
	"wangxiang": {"n": "Wangxiang, Goblin of the Springs", "elem": "water", "weak": "thunder", "col": Color("3a6a6a"), "shape": "ape", "boss": true, "pal": {"acc": Color("ff4030")}},
	"pearl_mother": {"n": "The Weeping Pearl-Mother", "elem": "water", "weak": "earth", "col": Color("d8e0f0"), "shape": "jelly", "boss": true},
	"zhulong": {"n": "Zhulong, the Torch Dragon", "elem": "fire", "weak": "water", "col": Color("c83a2a"), "shape": "dragon", "boss": true, "pal": {"under": Color("f0d0a0"), "acc": Color("fff080")}},
	"bai_wuchang": {"n": "Bai Wuchang, White Impermanence", "elem": "dark", "weak": "fire", "col": Color("e8ecf0"), "shape": "jiangshi", "boss": true, "pal": {"acc": Color("ff5050")}},
	"hei_wuchang": {"n": "Hei Wuchang, Black Impermanence", "elem": "dark", "weak": "fire", "col": Color("2a2a34"), "shape": "jiangshi", "boss": true, "pal": {"acc": Color("e0e0ff")}},
	"tubo": {"n": "Tubo, Earl of the Dark Capital", "elem": "earth", "weak": "wood", "col": Color("5a3a2a"), "shape": "oxhead", "boss": true, "pal": {"acc": Color("ff3020")}},
	"li": {"n": "Li, Who Presses Down the Earth", "elem": "earth", "weak": "wood", "col": Color("5a4a40"), "shape": "golem", "boss": true, "pal": {"acc": Color("ff7a30")}},
	# ---- Part XII: the Isles of the Eastern Sea and the Returning Ruins
	"mirage_wisp": {"n": "Mirage Wisp", "elem": "water", "weak": "earth", "col": Color("e8f0ff"), "shape": "wisp"},
	"stranded_shark": {"n": "Shark Stranded by the Low Tide", "elem": "water", "weak": "thunder", "col": Color("8a98a8"), "shape": "carp", "pal": {"under": Color("f0f0ec"), "acc": Color("e04030")}},
	"sand_crab": {"n": "Sandbar Crab", "elem": "earth", "weak": "wood", "col": Color("d8b878"), "shape": "crab"},
	"cinnabar_toad": {"n": "Cinnabar Toad of the Furnaces", "elem": "fire", "weak": "water", "col": Color("d84a2a"), "shape": "blob"},
	"elixir_crane": {"n": "Crane Who Steals Elixirs", "elem": "wood", "weak": "fire", "col": Color("f4f4ee"), "shape": "bird", "pal": {"sec": Color("1a1a22"), "acc": Color("e02a2a")}},
	"herb_rabbit": {"n": "Herb-Thief Rabbit", "elem": "earth", "weak": "wood", "col": Color("e8e0d0"), "shape": "jade_rabbit"},
	"mist_phantom": {"n": "Phantom of the Sea-Mist", "elem": "dark", "weak": "thunder", "col": Color("b8c8d8"), "shape": "wraith"},
	"bore_horse": {"n": "White Horse of the Tidal Bore", "elem": "water", "weak": "earth", "col": Color("f0f4f8"), "shape": "qilin", "pal": {"sec": Color("a8c8e8"), "acc": Color("60d0ff")}},
	"shell_soldier": {"n": "Shell-Armoured Tide Soldier", "elem": "water", "weak": "thunder", "col": Color("6a8aa0"), "shape": "humanoid"},
	"drowned_sailor": {"n": "Drowned Sailor of the Lost Fleet", "elem": "dark", "weak": "fire", "col": Color("6a7a7a"), "shape": "jiangshi"},
	"abyss_eel": {"n": "Eel of the Bottomless Ravine", "elem": "water", "weak": "thunder", "col": Color("2a3a5a"), "shape": "serpent", "pal": {"acc": Color("60ffd0")}},
	"ruin_sentinel": {"n": "Sentinel of the Sunken Isles", "elem": "earth", "weak": "wood", "col": Color("8a9a8a"), "shape": "golem"},
	"qianliyan": {"n": "Qianliyan, Thousand-Li Eye", "elem": "wood", "weak": "fire", "col": Color("3a8a5a"), "shape": "demon", "boss": true, "pal": {"acc": Color("fff070")}},
	"shunfenger": {"n": "Shunfeng'er, Wind-Following Ear", "elem": "fire", "weak": "water", "col": Color("c83a2a"), "shape": "demon", "boss": true, "pal": {"acc": Color("80e0ff")}},
	"sea_monk": {"n": "The Sea-Monk Who Drowns Fishermen", "elem": "water", "weak": "thunder", "col": Color("5a7a6a"), "shape": "tortoise", "boss": true, "pal": {"sec": Color("3a4a3a"), "acc": Color("ffb040")}},
	"longbo_giant": {"n": "The Giant of Longbo, Who Fishes for Turtles", "elem": "earth", "weak": "wood", "col": Color("a87a5a"), "shape": "ape", "boss": true, "pal": {"sec": Color("4a6a8a"), "acc": Color("f0d060")}},
	"longevity_deer": {"n": "The White Deer of Longevity", "elem": "wood", "weak": "fire", "col": Color("f4f0e4"), "shape": "qilin", "boss": true, "pal": {"sec": Color("d8a850"), "acc": Color("ff5a5a")}},
	"elixir_furnace": {"n": "The Elixir Furnace That Walked Away", "elem": "fire", "weak": "water", "col": Color("b07a3a"), "shape": "golem", "boss": true, "pal": {"acc": Color("ff8a20")}},
	"pearl_tree": {"n": "The Pearl Tree That Will Not Fruit", "elem": "earth", "weak": "thunder", "col": Color("e8eef4"), "shape": "plant", "boss": true, "pal": {"sec": Color("7ab0a0"), "acc": Color("ffe8f0")}},
	"tianwu": {"n": "Tianwu, the Eight-Headed God of the Waters", "elem": "water", "weak": "earth", "col": Color("d8a83a"), "shape": "kaiming", "boss": true, "pal": {"mark": Color("2a4a6a"), "acc": Color("60e0ff")}},
	"wu_zixu": {"n": "Wu Zixu, God of the Tidal Bore", "elem": "water", "weak": "earth", "col": Color("e8ecf0"), "shape": "warden", "boss": true, "pal": {"acc": Color("60c8ff")}},
	"shen": {"n": "Shen, the Mirage Clam-Dragon", "elem": "dark", "weak": "thunder", "col": Color("e0d8e8"), "shape": "dragon", "boss": true, "pal": {"sec": Color("b8a0c8"), "under": Color("fff0f8"), "acc": Color("ff90d0")}},
	"great_ao": {"n": "The Great Ao Who Bears Yingzhou", "elem": "earth", "weak": "wood", "col": Color("6a7a5a"), "shape": "tortoise", "boss": true, "pal": {"sec": Color("4a5a3a"), "acc": Color("a0f0c0")}},
	"yu_qiang": {"n": "Yu Qiang, God of the Northern Sea", "elem": "thunder", "weak": "earth", "col": Color("2a5a6a"), "shape": "crowmarshal", "boss": true, "pal": {"acc": Color("c8ff60")}},
	"drowned_admiral": {"n": "The Admiral of the Lost Fleet", "elem": "dark", "weak": "fire", "col": Color("4a5a6a"), "shape": "wraith", "boss": true, "pal": {"acc": Color("ffd060")}},
	"guixu_stopper": {"n": "The Bronze Stopper of Guixu", "elem": "earth", "weak": "wood", "col": Color("8a6a3a"), "shape": "warden", "boss": true, "pal": {"acc": Color("40ffd0")}},
	"hai_ruo": {"n": "Ruo of the Northern Sea, the Sea Itself", "elem": "water", "weak": "earth", "col": Color("2a6aa8"), "shape": "storm", "boss": true, "pal": {"acc": Color("e8ffff")}},
	"xu_fu": {"n": "Xu Fu, Who Sought the Elixir", "elem": "dark", "weak": "fire", "col": Color("5a4a7a"), "shape": "humanoid", "boss": true, "pal": {"sec": Color("d8c890"), "acc": Color("90ffb0")}},
	# ---- Part XIII: the war-bands of the Eight Gates, woken with the formation round Chiyou
	"jiuli_warrior": {"n": "Warrior of the Nine Li", "elem": "phys", "weak": "fire", "col": Color("b08850"), "shape": "humanoid"},
	"zhuolu_fog": {"n": "Fog of Zhuolu", "elem": "water", "weak": "thunder", "col": Color("a8b4bc"), "shape": "wraith"},
	"bronze_brow": {"n": "Bronze-Browed Brother", "elem": "earth", "weak": "wood", "col": Color("a8783a"), "shape": "humanoid"},
	"fetter_sapling": {"n": "Fetter-Maple Sapling", "elem": "wood", "weak": "fire", "col": Color("c8402a"), "shape": "plant"},
	"banner_ember": {"n": "Ember of Chiyou's Banner", "elem": "fire", "weak": "water", "col": Color("e8402a"), "shape": "wisp"},
	# ---- Part XIII bosses: the Generals of the Eight Gates, and the war god at the heart of them
	"xingtian": {"n": "Xingtian, Who Dances Without a Head", "elem": "phys", "weak": "fire", "col": Color("9a6a3a"), "shape": "golem", "boss": true, "pal": {"acc": Color("ffd060")}},
	"yu_shi": {"n": "Yu Shi, the Rain Master of Zhuolu", "elem": "water", "weak": "earth", "col": Color("5a7a9a"), "shape": "storm", "boss": true, "pal": {"acc": Color("a0e0ff")}},
	"liang": {"n": "Liang, Goblin of the Black Springs", "elem": "water", "weak": "thunder", "col": Color("2a4a5a"), "shape": "jelly", "boss": true, "pal": {"acc": Color("60ffd0")}},
	"bronze_brothers": {"n": "The Bronze-Headed Brothers of Chiyou", "elem": "earth", "weak": "wood", "col": Color("a87a3a"), "shape": "humanoid", "boss": true, "pal": {"acc": Color("ff6a30")}},
	"red_banner": {"n": "Chiyou's Banner, the Red Comet", "elem": "fire", "weak": "water", "col": Color("d8302a"), "shape": "phoenix", "boss": true, "pal": {"acc": Color("ffe080")}},
	"mast_goblin": {"n": "Mei, Goblin of the Old Mast", "elem": "wood", "weak": "fire", "col": Color("7a5a3a"), "shape": "plant", "boss": true, "pal": {"acc": Color("90ffb0")}},
	"fetter_maple": {"n": "The Fetter-Maple of Chiyou", "elem": "wood", "weak": "fire", "col": Color("b8302a"), "shape": "plant", "boss": true, "pal": {"sec": Color("5a3a2a"), "acc": Color("ffd040")}},
	"kui_drum": {"n": "The Drum of Kui's Hide", "elem": "thunder", "weak": "earth", "col": Color("6a5a7a"), "shape": "golem", "boss": true, "pal": {"acc": Color("c8e0ff")}},
	"chiyou": {"n": "Chiyou, War God of the Nine Li", "elem": "phys", "weak": "fire", "col": Color("8a6a3a"), "shape": "oxhead", "boss": true, "pal": {"sec": Color("3a3a42"), "acc": Color("ff4a2a")}},
	"tribulation": {"n": "Heavenly Tribulation", "elem": "thunder", "weak": "none", "col": Color("c8d8ff"), "shape": "storm", "boss": true},
	# ---- Fates and Faces: people met on the road who come to blows with Lin Feng (fate.gd), in their own models
	"qiu_ye": {"n": "Qiu Ye of the Ashen Moon", "elem": "dark", "weak": "thunder", "col": Color("2e5a48"), "shape": "person:qiu_ye", "boss": true},
	"young_fang": {"n": "Young Fang", "elem": "phys", "weak": "water", "col": Color("8a5a34"), "shape": "person:hu_grown", "boss": true},
	"xu_lan": {"n": "Xu Lan of the Blood Moon", "elem": "dark", "weak": "fire", "col": Color("b02848"), "shape": "person:xu_lan", "boss": true},
	"liu_ying": {"n": "Liu Ying, the Poison Saint", "elem": "wood", "weak": "fire", "col": Color("6a8a4a"), "shape": "person:liu_ying", "boss": true},
	# ---- Part XIV: the grudges and debts of the whole journey, and Nie, the Unpaid
	"grudge_wisp": {"n": "Grudge Wisp", "elem": "dark", "weak": "fire", "col": Color("a8385a"), "shape": "wisp"},
	"debt_shade": {"n": "Debt Shade", "elem": "dark", "weak": "thunder", "col": Color("5a5a7a"), "shape": "wraith"},
	"karma_moth": {"n": "Karma Moth", "elem": "earth", "weak": "wood", "col": Color("c8a050"), "shape": "moth"},
	"nie": {"n": "Nie, the Unpaid", "elem": "dark", "weak": "thunder", "col": Color("4a1a3a"), "shape": "hundun", "boss": true, "pal": {"sec": Color("1a0a14"), "acc": Color("ff4a8a"), "mark": Color("e8c050")}},
	# ---- Part XIV: the grudges that stayed where their owners fell (grudges.gd), in their owners' shapes gone to soot
	"grudge_iron_fang": {"n": "Iron Fang's Grudge", "elem": "dark", "weak": "water", "col": Color("5a2a26"), "shape": "humanoid", "boss": true, "grudge": true},
	"grudge_marsh_hag": {"n": "The Marsh Hag's Grudge", "elem": "dark", "weak": "fire", "col": Color("3a2444"), "shape": "wraith", "boss": true, "grudge": true, "pal": {"sec": Color("140a18"), "acc": Color("ff4a7a")}},
	"grudge_headless_saint": {"n": "The Headless Saint's Grudge", "elem": "dark", "weak": "thunder", "col": Color("4a4a5c"), "shape": "demon", "boss": true, "grudge": true},
	"grudge_fangfeng": {"n": "Fangfeng's Grudge", "elem": "earth", "weak": "wood", "col": Color("3c4434"), "shape": "humanoid", "boss": true, "grudge": true},
	"grudge_kui": {"n": "Kui's Grudge", "elem": "thunder", "weak": "earth", "col": Color("3a4252"), "shape": "mammoth", "boss": true, "grudge": true, "pal": {"acc": Color("ff5a7a")}},
	"grudge_admiral": {"n": "The Admiral's Grudge", "elem": "water", "weak": "thunder", "col": Color("28323c"), "shape": "wraith", "boss": true, "grudge": true, "pal": {"sec": Color("10161c"), "acc": Color("ffd060")}},
	# ---- Part XV (the Lotus release): the things that eat forgetting, and the Warden of the Lock
	"loose_thread": {"n": "Loose Thread", "elem": "wood", "weak": "fire", "col": Color("e8a8c8"), "shape": "wisp"},
	"forgetting_moth": {"n": "Moth of Forgetting", "elem": "dark", "weak": "fire", "col": Color("9a9aa8"), "shape": "moth", "pal": {"sec": Color("4a4a58"), "acc": Color("e8e8f0")}},
	"unweaver_shuttle": {"n": "Unweaving Shuttle", "elem": "phys", "weak": "thunder", "col": Color("b8a070"), "shape": "spider"},
	"forgetting_queen": {"n": "The Moth-Queen of Forgetting", "elem": "dark", "weak": "fire", "col": Color("8a8a98"), "shape": "moth", "boss": true, "pal": {"sec": Color("2a2a34"), "acc": Color("f0f0ff")}},
	"unweaver": {"n": "The Unweaver", "elem": "phys", "weak": "thunder", "col": Color("c8b080"), "shape": "spider", "boss": true, "pal": {"sec": Color("3a2a1a"), "acc": Color("ff9ac0")}},
	"lock_warden": {"n": "Suo, Warden of the Lock", "elem": "earth", "weak": "wood", "col": Color("8a7038"), "shape": "golem", "boss": true, "pal": {"sec": Color("2a4a3a"), "acc": Color("ff9ac0"), "mark": Color("e8c860")}},
}

## How many branches of the Nine Heavens root a cultivator who has kept up with the world will have
## woken by level `lv` (Part XII): the first stirring, one for every tribulation survived and one for
## every Founder's cave whose realm has been reached.
static func expected_ranks(lv: int) -> int:
	if lv <= 0:
		return 0
	return 1 + realm_of(lv) + clampi(realm_of(lv) - 1, 0, 9)

## The world grows with the root (Part XII): every foe is a little tougher for each rank a cultivator of
## its level would be expected to have woken, so the branches a player wakes keep pace with the world,
## and a player who neglects them (or the Founder's caves) falls behind it.
const ROOT_HP := 0.03
const ROOT_ATK := 0.025
## and a Heavenly Tribulation tests a woken root harder: +1.5% to its strength for every rank awake
const TRIB_JEALOUSY := 0.015

static func make_enemy(id: String, lv: int, boss_mult: float = 1.0, atk_mult: float = 1.0) -> Dictionary:
	var d: Dictionary = ENEMIES[id]
	var boss: bool = d.get("boss", false)
	var er := expected_ranks(lv)
	var hp := int((60 + 48 * lv) * (1.0 + ROOT_HP * er))
	var a := (7.0 + 4.3 * lv) * (1.0 + ROOT_ATK * er)
	var df := 2.0 + 2.6 * lv
	if boss:
		hp = int(hp * 6.0 * boss_mult)
		# (a trial's boss hits harder too: trials.gd `might`)
		a *= 1.3 * atk_mult
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
		var fo := make_enemy(f.id, f.lv, f.get("mult", 1.0), f.get("atk", 1.0))
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
			{"to": "dunes", "pos": Vector2i(27, 24), "dest": Vector2i(4, 28), "open": "s_p5_home"},
			{"to": "maple", "pos": Vector2i(1, 22), "dest": Vector2i(4, 28), "open": "s_p6_home"},
			{"to": "village", "pos": Vector2i(6, 24), "dest": Vector2i(4, 28), "open": "s_p7_home"},
			{"to": "starferry", "pos": Vector2i(13, 24), "dest": Vector2i(4, 28), "open": "s_p8_home"},
			{"to": "yanggu", "pos": Vector2i(34, 24), "dest": Vector2i(4, 30), "open": "s_p9_home"},
			{"to": "longmen", "pos": Vector2i(12, 1), "dest": Vector2i(4, 30), "open": "s_p10_road"},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "qiu_ye", "n": "Qiu Ye", "pos": Vector2i(23, 12), "col": Color("2e5a48"), "fate": true},
			{"id": "qiu_ye_end", "n": "Qiu Ye", "pos": Vector2i(25, 12), "col": Color("2e5a48"), "asset": "qiu_ye", "fate": true},
			{"id": "gardener_ruan", "n": "Herb-Gardener Ruan", "pos": Vector2i(24, 14), "col": Color("5a8a4a")},
			{"id": "xiao_qing", "n": "Outer Disciple Xiao Qing", "pos": Vector2i(17, 15), "col": Color("7aa0d0"), "vis": ["s_p4_home", ""]},
			{"id": "elder", "n": "Elder Qing Xuan", "pos": Vector2i(20, 4), "col": Color("e8e8ff")},
			{"id": "alchemist", "n": "Alchemist Mo", "pos": Vector2i(7, 8), "col": Color("6fc08a")},
			{"id": "smith", "n": "Smith Tie", "pos": Vector2i(32, 8), "col": Color("d08a5a")},
			{"id": "archivist", "n": "Archivist Lan", "pos": Vector2i(33, 18), "col": Color("a8b8e0"), "hide": ["s_p11_archive", "s_p11_archive"]},
			# Part XI: Archivist Lan down in the Sealed Archive under the library, reading the record of the
			# day the ladder between heaven and earth was cut
			{"id": "archivist_deep", "asset": "archivist", "n": "Archivist Lan", "pos": Vector2i(33, 18), "col": Color("a8b8e0"), "vis": ["s_p11_archive", "s_p11_archive"], "floor": ["library", -1]},
			# the sect's own people: sparring master, pond keeper, cook, the new sweeper, gate warden
			# and bell-ringer
			{"id": "disciple_han", "n": "Senior Brother Han", "pos": Vector2i(31, 3), "col": Color("3a6aa0")},
			{"id": "disciple_mei", "n": "Junior Sister Mei", "pos": Vector2i(13, 18), "col": Color("6aa0c8")},
			{"id": "cook_zhou", "n": "Auntie Zhou the Cook", "pos": Vector2i(4, 3), "col": Color("a85a3a")},
			{"id": "sweeper_bai", "n": "Little Bai the Sweeper", "pos": Vector2i(17, 9), "col": Color("8a8a90"), "vis": ["s_elder2", ""]},
			{"id": "gate_wu", "n": "Gate Disciple Wu", "pos": Vector2i(36, 14), "col": Color("2a3a4a")},
			{"id": "bell_shen", "n": "Old Shen the Bell-Ringer", "pos": Vector2i(24, 10), "col": Color("b8803a")},
		],
		"springs": [Vector2i(20, 13)],
		# Part XI: the Dao Stele in the courtyard, where a cultivator chooses the road they walk
		"steles": [Vector2i(16, 11)],
		# things to find upstairs and below: keepsakes the peoples of the other realms are fond of
		"pickups": [{"id": "cur_incense1", "item": "ancestor_incense", "pos": Vector2i(22, 4), "floor": ["hall", -1], "always": true},
			{"id": "cur_leaf1", "item": "autumn_leaf", "pos": Vector2i(30, 16), "floor": ["library", -1], "always": true},
			{"id": "cur_lotus1", "item": "moon_lotus", "pos": Vector2i(9, 19), "floor": ["dormitory", 1], "always": true}],
		## enterable buildings: rect includes the walls; props are [kind, tile, blocks].  "up"/"down" are
		## the stairs (a floor tile inside) to an "upper" storey or a "cellar", each with its own props
		"buildings": [
			{"id": "hall", "n": "Hall of Azure Clouds", "style": "hall", "rect": Rect2i(14, 1, 13, 7), "door": Vector2i(20, 7),
				"props": [["altar", Vector2i(19, 2), true], ["altar", Vector2i(20, 2), true], ["altar", Vector2i(21, 2), true], ["statue", Vector2i(20, 2), false], ["cushion", Vector2i(17, 5), false], ["cushion", Vector2i(23, 5), false], ["scroll", Vector2i(15, 3), false], ["scroll", Vector2i(25, 3), false]],
				"down": Vector2i(25, 6), "cellar": {"n": "the ancestral crypt", "props": [["altar", Vector2i(19, 2), true], ["altar", Vector2i(20, 2), true], ["altar", Vector2i(21, 2), true], ["statue", Vector2i(20, 2), false], ["cabinet", Vector2i(15, 5), true], ["lantern", Vector2i(17, 3), false], ["lantern", Vector2i(23, 3), false]]}},
			{"id": "pharmacy", "n": "Alchemist's Pharmacy", "style": "alchemist", "rect": Rect2i(3, 7, 9, 5), "door": Vector2i(7, 11),
				"props": [["cauldron", Vector2i(10, 9), true], ["shelf", Vector2i(4, 8), true], ["counter", Vector2i(8, 9), false], ["herbs", Vector2i(4, 10), false]]},
			{"id": "forge", "n": "Smithy", "style": "smithy", "rect": Rect2i(28, 7, 9, 5), "door": Vector2i(32, 11),
				"props": [["hearth", Vector2i(35, 8), true], ["anvil", Vector2i(34, 10), true], ["rack", Vector2i(29, 8), true], ["barrel", Vector2i(29, 10), false]]},
			{"id": "library", "n": "Scripture Library", "style": "library", "rect": Rect2i(27, 15, 10, 6), "door": Vector2i(31, 15),
				"props": [["bookshelf", Vector2i(28, 19), true], ["bookshelf", Vector2i(29, 19), true], ["bookshelf", Vector2i(35, 16), true], ["desk", Vector2i(34, 18), true], ["scroll", Vector2i(28, 16), false]],
				"down": Vector2i(35, 19), "cellar": {"n": "the Sealed Archive", "props": [["bookshelf", Vector2i(28, 17), true], ["bookshelf", Vector2i(30, 19), true], ["desk", Vector2i(32, 17), true], ["cabinet", Vector2i(35, 16), true], ["scroll", Vector2i(28, 16), false], ["lantern", Vector2i(33, 19), false]]}},
			{"id": "kitchen", "n": "Sect Kitchen", "style": "kitchen", "rect": Rect2i(2, 1, 10, 5), "door": Vector2i(7, 5),
				"props": [["stove", Vector2i(3, 2), true], ["stove", Vector2i(5, 2), true], ["table", Vector2i(8, 3), true], ["barrel", Vector2i(10, 2), true], ["shelf", Vector2i(10, 4), false], ["lantern", Vector2i(9, 4), false]]},
			{"id": "training_hall", "n": "Hall of Martial Practice", "style": "dorm", "rect": Rect2i(28, 1, 11, 5), "door": Vector2i(33, 5),
				"props": [["rack", Vector2i(29, 2), true], ["rack", Vector2i(37, 2), true], ["cushion", Vector2i(33, 3), false], ["barrel", Vector2i(37, 4), false], ["scroll", Vector2i(34, 2), false]]},
			{"id": "dormitory", "n": "Disciples' Dormitory", "style": "dorm", "rect": Rect2i(2, 15, 11, 6), "door": Vector2i(7, 15),
				"props": [["bed", Vector2i(3, 17), true], ["bed", Vector2i(3, 19), true], ["bed", Vector2i(11, 17), true], ["bed", Vector2i(11, 19), true], ["table", Vector2i(7, 18), true], ["lantern", Vector2i(6, 19), false]],
				"up": Vector2i(10, 16), "upper": {"n": "the upper dormitory", "props": [["bed", Vector2i(3, 17), true], ["bed", Vector2i(3, 19), true], ["bed", Vector2i(11, 18), true], ["table", Vector2i(7, 17), true], ["lantern", Vector2i(5, 18), false]]}},
		],
	},
	# the mountain around the sect: forests, terraces and the roads to every region (open world hub)
	"mountain": {
		"n": "Azure Cloud Mountain", "w": 180, "h": 160, "seed": 7, "theme": "sect", "enemies": 0, "hill": 2.2,
		"portals": [],
		# Part XV: the Warden of the Lock, under the Founder's Last Cave, where the mountain goes down to
		# the root of the sect's pond
		"bosses": [{"id": "lock_warden", "pos": Vector2i(63, 103), "lv": 59, "req": 59, "vis": ["s_p15_warden", ""]}],
		"springs": [Vector2i(36, 104), Vector2i(146, 40)],
		# trails that join the mountain's people start just north of the sect's north wall
		"start": Vector2i(82, 56),
		# Cloudfoot: the post town where the north road leaves the mountain for the river (a main
		# street up from the sect's north gate and a cross street between the inns)
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "tala_end", "n": "Tala of the Horse-Folk", "pos": Vector2i(106, 32), "col": Color("d8a04a"), "asset": "tala", "fate": true},
			{"id": "courier_ma", "n": "Courier Ma of the Nine Roads", "pos": Vector2i(83, 32), "col": Color("3a6a4a")},
			{"id": "noodle_he", "n": "Granny He of the Noodle Stall", "pos": Vector2i(85, 37), "col": Color("a8503a")},
			{"id": "clerk_wei", "n": "Wei, Who Collected Taxes for the Court", "pos": Vector2i(79, 36), "col": Color("4a4a5a"), "vis": ["s_p5_home", ""]},
			{"id": "cartographer_pei", "n": "Cartographer Pei of Cloudfoot", "pos": Vector2i(91, 25), "col": Color("3e6a5a")},
			{"id": "postmaster_lu", "n": "Postmaster Lu", "pos": Vector2i(70, 25), "col": Color("6a4a3a")},
			{"id": "storyteller_wu", "n": "Old Wu the Storyteller", "pos": Vector2i(70, 41), "col": Color("8a3a3a")},
			{"id": "caravan_kang", "n": "Caravan-Master Kang", "pos": Vector2i(93, 42), "col": Color("a86a3a")},
			{"id": "priestess_yun", "n": "Wayfarer-Priestess Yun", "pos": Vector2i(90, 50), "col": Color("e8e4d8")},
			{"id": "stableboy_shitou", "n": "Shitou the Stable-Boy", "pos": Vector2i(104, 32), "col": Color("8a6a4a")},
			# Part XI: a messenger of the Feathered Folk, come down the Jianmu to see who regrew it
			{"id": "ling_yu", "n": "Ling Yu of the Feathered Folk", "pos": Vector2i(32, 62), "col": Color("8ac0e8"), "race": "yumin", "vis": ["s_p11_archive", "s_p11_tree"]},
		],
		"pickups": [{"id": "cur_leaf3", "item": "autumn_leaf", "pos": Vector2i(74, 26), "floor": ["post_station", 1], "always": true},
			{"id": "cur_wine2", "item": "peach_wine", "pos": Vector2i(74, 40), "floor": ["tale_teahouse", 1], "always": true}],
		# Part XII: the Founder's nine sealed caves round the sect, each opening only to a cultivator of
		# the realm carved on its door; inside, her words (DIALOGUE "abode:<id>"), spirit stones and an
		# awakening of the Nine Heavens root
		"abodes": [
			{"id": "cave_core", "n": "The Cave of the Golden Core", "pos": Vector2i(116, 72), "req": 6, "stones": 150, "motto": "A core is only qi that has decided what it is."},
			{"id": "cave_soul", "n": "The Cave of the Nascent Soul", "pos": Vector2i(92, 91), "req": 9, "stones": 250, "motto": "The small self inside you is the one who will do the work. Be kind to it."},
			{"id": "cave_deity", "n": "The Cave of Deity Transformation", "pos": Vector2i(62, 72), "req": 12, "stones": 350, "motto": "The body is a house. You may visit it."},
			{"id": "cave_void", "n": "The Cave of Void Refinement", "pos": Vector2i(68, 92), "req": 15, "stones": 500, "motto": "Where the world is thin, be careful. Where you are thin, be kind."},
			{"id": "cave_merging", "n": "The Cave of Dao Merging", "pos": Vector2i(110, 94), "req": 18, "stones": 700, "motto": "Your Dao and the world's are one river. Swim with it, never against it, and sometimes across."},
			{"id": "cave_mahayana", "n": "The Cave of the Great Vehicle", "pos": Vector2i(86, 57), "req": 21, "stones": 900, "motto": "A great vehicle carries others, or it is only a large one."},
			{"id": "cave_immortal", "n": "The Cave of the True Immortal", "pos": Vector2i(52, 64), "req": 24, "stones": 1200, "motto": "Immortal only means more time to be wrong. Spend it being right."},
			{"id": "cave_ancestor", "n": "The Cave of the Dao Ancestor", "pos": Vector2i(120, 52), "req": 27, "stones": 1500, "motto": "Everything after this door is yours. Write it on the walls for whoever comes next."},
			{"id": "cave_sovereign", "n": "The Last Cave", "pos": Vector2i(60, 100), "req": 30, "stones": 2000, "motto": "Sweep the steps. Then go and see."},
		],
		# Part XI: the Jianmu, the Standing Tree, grown back overnight on the open ground west of the
		# sect; its trunk is solid ground, its crown is in the Nine Heavens and its roots in the Nine Springs
		"blocks": [Rect2i(30, 50, 9, 9)],
		"landmark": {"kind": "jianmu", "pos": Vector2i(34, 54)},
		"roads": [[Vector2i(82, 57), Vector2i(82, 46), Vector2i(81, 34), Vector2i(83, 22), Vector2i(82, 10)], [Vector2i(58, 36), Vector2i(70, 34), Vector2i(82, 33), Vector2i(96, 35), Vector2i(108, 33)]],
		"buildings": [
			{"id": "post_station", "n": "Cloudfoot Post Station", "style": "inn", "rect": Rect2i(66, 22, 13, 8), "door": Vector2i(78, 26),
				"props": [["counter", Vector2i(72, 23), true], ["table", Vector2i(68, 27), true], ["stool", Vector2i(67, 27), false], ["shelf", Vector2i(75, 23), true], ["barrel", Vector2i(76, 28), true], ["lantern", Vector2i(73, 27), false]],
				"up": Vector2i(67, 23), "upper": {"n": "the letter room", "props": [["shelf", Vector2i(75, 23), true], ["desk", Vector2i(71, 24), true], ["shelf", Vector2i(77, 28), true], ["bed", Vector2i(68, 27), true], ["lantern", Vector2i(73, 27), false]]}},
			{"id": "map_house", "n": "Pei's House of Maps", "style": "library", "rect": Rect2i(87, 22, 10, 8), "door": Vector2i(87, 26),
				"props": [["desk", Vector2i(93, 26), true], ["bookshelf", Vector2i(95, 23), true], ["bookshelf", Vector2i(95, 28), true], ["scroll", Vector2i(89, 23), false], ["lantern", Vector2i(89, 28), false]]},
			{"id": "tale_teahouse", "n": "Teahouse of Ten Thousand Tales", "style": "teahouse", "rect": Rect2i(66, 38, 11, 7), "door": Vector2i(71, 38),
				"props": [["table", Vector2i(68, 41), true], ["stool", Vector2i(67, 41), false], ["table", Vector2i(74, 41), true], ["stool", Vector2i(75, 41), false], ["cushion", Vector2i(70, 43), false], ["lantern", Vector2i(72, 43), false]],
				"up": Vector2i(75, 39), "upper": {"n": "the upper gallery", "props": [["table", Vector2i(69, 40), true], ["table", Vector2i(73, 42), true], ["cushion", Vector2i(71, 41), false], ["lantern", Vector2i(68, 43), false]]}},
			{"id": "caravanserai", "n": "Caravanserai of the Four Roads", "style": "huizhou", "rect": Rect2i(88, 38, 12, 8), "door": Vector2i(93, 38),
				"props": [["barrel", Vector2i(89, 39), true], ["barrel", Vector2i(89, 41), true], ["table", Vector2i(96, 41), true], ["bed", Vector2i(98, 43), true], ["bed", Vector2i(90, 44), true], ["lantern", Vector2i(95, 39), false]]},
			{"id": "road_shrine", "n": "Shrine of Xiu, God of Roads", "style": "shrine", "rect": Rect2i(86, 47, 8, 7), "door": Vector2i(86, 50),
				"props": [["altar", Vector2i(92, 49), true], ["altar", Vector2i(92, 50), true], ["altar", Vector2i(92, 51), true], ["statue", Vector2i(92, 50), false], ["cushion", Vector2i(89, 50), false]]},
			{"id": "post_stables", "n": "Post Stables", "style": "farmhouse", "rect": Rect2i(100, 24, 8, 6), "door": Vector2i(103, 29),
				"props": [["barrel", Vector2i(101, 25), true], ["barrel", Vector2i(106, 25), true], ["rack", Vector2i(104, 25), true]]},
			# Part XV (the Lotus release): the Founder's hermitage below the Last Cave, where she wove Yue Ling
			# out of the Seal's lotus three hundred years ago, and its bathhouse
			{"id": "lotus_hermitage", "n": "The Founder's Hermitage", "style": "hermitage", "rect": Rect2i(68, 101, 11, 8), "door": Vector2i(68, 104),
				"props": [["altar", Vector2i(77, 104), true], ["statue", Vector2i(77, 104), false], ["loom", Vector2i(72, 102), true], ["bookshelf", Vector2i(75, 102), true],
					["cushion", Vector2i(73, 106), false], ["scroll", Vector2i(70, 102), false], ["lantern", Vector2i(74, 105), false], ["cabinet", Vector2i(76, 107), true]]},
			{"id": "lotus_bathhouse", "n": "The Hermitage Bathhouse", "style": "bathhouse", "rect": Rect2i(70, 112, 8, 6), "door": Vector2i(73, 112),
				"props": [["tub", Vector2i(72, 115), true], ["tub", Vector2i(75, 115), true], ["stool", Vector2i(73, 114), false], ["barrel", Vector2i(71, 116), true],
					["shelf", Vector2i(76, 113), true], ["lantern", Vector2i(74, 116), false]]},
		],
	},
	"bamboo": {
		"n": "Whispering Bamboo Forest", "w": 70, "h": 44, "seed": 21, "theme": "bamboo", "enemies": 13,
		"pool": [["bamboo_wolf", 0, 1], ["bandit", 1, 2], ["leaf_sprite", 0, 2]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 22), "dest": Vector2i(36, 13), "open": ""},
			{"to": "marsh", "pos": Vector2i(68, 22), "dest": Vector2i(4, 24), "open": "s_elder2"},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "little_hu", "n": "Little Hu", "pos": Vector2i(41, 10), "col": Color("6a4a30"), "fate": true},{"id": "yue_ling", "n": "Yue Ling", "pos": Vector2i(43, 12), "col": Color("f08ab0"), "vis": ["s_ironfang", "s_yue"]}],
		"bosses": [
			{"id": "jade_mantis", "pos": Vector2i(32, 30), "lv": 1, "req": 1},
			{"id": "iron_fang", "pos": Vector2i(44, 12), "lv": 1, "req": 1},
			# Part XIV: what Iron Fang was owed, standing where he fell (grudges.gd)
			{"id": "grudge_iron_fang", "pos": Vector2i(46, 13), "lv": 55, "req": 54, "vis": ["s_p14_grudges", ""]},
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
		# a fated encounter (fate.gd): there while the story has them there
		"npcs": [{"id": "liu_ying", "n": "Liu Ying", "pos": Vector2i(38, 27), "col": Color("6a7a5a"), "fate": true}, {"id": "liu_ying_end", "n": "Liu Ying", "pos": Vector2i(45, 32), "col": Color("6a7a5a"), "asset": "liu_ying", "fate": true}],
		"pool": [["mire_toad", 3, 4], ["bog_wraith", 4, 5], ["poison_vine", 3, 5]],
		"portals": [
			{"to": "bamboo", "pos": Vector2i(1, 24), "dest": Vector2i(66, 22), "open": ""},
			{"to": "frost", "pos": Vector2i(78, 24), "dest": Vector2i(4, 25), "open": "s_elder3"},
		],
		"bosses": [
			{"id": "bog_colossus", "pos": Vector2i(40, 28), "lv": 4, "req": 4},{"id": "marsh_hag", "pos": Vector2i(66, 10), "lv": 5, "req": 5},
			{"id": "grudge_marsh_hag", "pos": Vector2i(68, 11), "lv": 55, "req": 54, "vis": ["s_p14_grudges", ""]}],
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
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "tala", "n": "Tala of the Horse-Folk", "pos": Vector2i(12, 10), "col": Color("d8a04a"), "fate": true},{"id": "sword_ghost", "n": "Ancestor Jian Wuchen", "pos": Vector2i(14, 10), "col": Color("9ad8ff"), "vis": ["s_swordghost", ""]}],
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
		# a fated encounter (fate.gd): there while the story has them there
		"npcs": [{"id": "xu_lan", "n": "Xu Lan", "pos": Vector2i(50, 23), "col": Color("7a1a2a"), "fate": true}, {"id": "xu_lan_end", "n": "Xu Lan", "pos": Vector2i(46, 23), "col": Color("7a1a2a"), "asset": "xu_lan", "fate": true}],
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
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "xu_lan_lake", "n": "Xu Lan", "pos": Vector2i(11, 24), "col": Color("7a1a2a"), "asset": "xu_lan", "fate": true},{"id": "lake_keeper", "n": "Keeper Lan Jing", "pos": Vector2i(10, 26), "col": Color("a8e0ff"), "vis": ["s_ml_intro", ""]}],
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
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "qiu_ye_grave", "n": "Qiu Ye", "pos": Vector2i(8, 26), "col": Color("2e5a48"), "asset": "qiu_ye", "fate": true},{"id": "grave_keeper", "n": "Gravekeeper Mu Gu", "pos": Vector2i(10, 26), "col": Color("b8b8c8"), "vis": ["s_gv_intro", ""]},
			# Part XV: the Founder's echo, threading a needle beside her own barrow
			{"id": "qing_lian_echo", "n": "Echo of Founder Qing Lian", "pos": Vector2i(80, 33), "col": Color("f0f0f4"), "vis": ["s_p15_founder", ""]}],
		"bosses": [
			{"id": "bone_wyrm", "pos": Vector2i(34, 40), "lv": 19, "req": 19},
			{"id": "headless_saint", "pos": Vector2i(48, 22), "lv": 20, "req": 20},
			{"id": "grudge_headless_saint", "pos": Vector2i(50, 23), "lv": 55, "req": 54, "vis": ["s_p14_grudges", ""]},
			{"id": "grave_empress", "pos": Vector2i(60, 12), "lv": 20, "req": 20},
			{"id": "founder_qing", "pos": Vector2i(82, 30), "lv": 20, "req": 20},
		],
		"pickups": [
			{"id": "relic1", "item": "relic", "pos": Vector2i(20, 12)}, {"id": "relic2", "item": "relic", "pos": Vector2i(42, 46)},
			{"id": "relic3", "item": "relic", "pos": Vector2i(66, 30)}, {"id": "relic4", "item": "relic", "pos": Vector2i(76, 10)},
		],
		"pickup_vis": "s_gv_collect",
		# Part XV: the things that eat forgetting, unpicking the Founder's weave among the graves
		"warband": {"pool": [["loose_thread", 57, 58], ["forgetting_moth", 57, 58], ["unweaver_shuttle", 57, 58]], "n": 8, "vis": "s_p15_judge"},
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
			{"to": "sect", "pos": Vector2i(1, 28), "dest": Vector2i(28, 21), "open": ""},
			{"to": "fungal", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_du_tiger"},
		],
		"npcs": [
			{"id": "navid", "n": "Navid the Sogdian Merchant", "pos": Vector2i(11, 43), "col": Color("8a3a5a")},
			{"id": "farida", "n": "Farida the Star-Glass Blower", "pos": Vector2i(12, 37), "col": Color("3a8ab0")},
			{"id": "nomad", "n": "Nomad Matriarch Ba Yin", "pos": Vector2i(10, 26), "col": Color("e8c890"), "vis": ["s_du_intro", ""]},
			{"id": "cook_aysha", "n": "Auntie Aysha of the Caravanserai", "pos": Vector2i(6, 36), "col": Color("a84a3a")},
			{"id": "well_keeper_zhaya", "n": "Well-Keeper Zhaya", "pos": Vector2i(6, 44), "col": Color("c8a070")},
			{"id": "star_reader_kumar", "n": "Star-Reader Kumar", "pos": Vector2i(20, 38), "col": Color("2e2e6a")},
			{"id": "camel_boy_temur", "n": "Temur the Camel-Boy", "pos": Vector2i(19, 52), "col": Color("8a6a4a")},
		],
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
		# Shazhou Oasis: a caravan town round a sweet well, where the west road comes in off the sand
		"springs": [Vector2i(11, 51)],
		"ponds": [[Vector2i(6, 52), 3]],
		"roads": [[Vector2i(4, 29), Vector2i(12, 31), Vector2i(13, 42), Vector2i(12, 53)]],
		"buildings": [
			{"id": "caravanserai_sz", "n": "Shazhou Caravanserai", "style": "huizhou", "rect": Rect2i(2, 32, 9, 8), "door": Vector2i(10, 35),
				"props": [["table", Vector2i(4, 34), true], ["stool", Vector2i(5, 34), false], ["stove", Vector2i(3, 37), true], ["barrel", Vector2i(8, 38), true], ["lantern", Vector2i(7, 33), false]]},
			{"id": "sweet_well", "n": "The Sweet Well", "style": "shop", "rect": Rect2i(2, 42, 8, 6), "door": Vector2i(9, 44),
				"props": [["barrel", Vector2i(3, 43), true], ["barrel", Vector2i(3, 46), true], ["counter", Vector2i(6, 45), false]]},
			{"id": "star_temple", "n": "Temple of the Fallen Stars", "style": "shrine", "rect": Rect2i(16, 34, 9, 7), "door": Vector2i(16, 37),
				"props": [["altar", Vector2i(23, 36), true], ["altar", Vector2i(23, 37), true], ["altar", Vector2i(23, 38), true], ["statue", Vector2i(23, 37), false], ["scroll", Vector2i(18, 35), false], ["cushion", Vector2i(20, 37), false]]},
			{"id": "camel_yard", "n": "Camel Yard", "style": "farmhouse", "rect": Rect2i(16, 44, 8, 6), "door": Vector2i(16, 46),
				"props": [["barrel", Vector2i(22, 45), true], ["rack", Vector2i(22, 48), true]]},
		],
	},
	"fungal": {
		"n": "Glowcap Vale", "w": 96, "h": 58, "seed": 201, "theme": "fungal", "enemies": 20,
		"pool": [["spore_puff", 27, 28], ["glow_moth", 27, 28], ["root_crawler", 27, 28]],
		"portals": [
			{"to": "dunes", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "aurora", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_fu_bird"},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "liu_ying_vale", "n": "Liu Ying", "pos": Vector2i(8, 26), "col": Color("6a7a5a"), "asset": "liu_ying", "fate": true},{"id": "spore_witch", "n": "Spore-Witch Mo Gu", "pos": Vector2i(10, 26), "col": Color("c8a0e0"), "vis": ["s_fu_intro", ""]}],
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
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "tala_steppe", "n": "Tala of the Horse-Folk", "pos": Vector2i(8, 24), "col": Color("d8a04a"), "asset": "tala", "fate": true},{"id": "steppe_shaman", "n": "Steppe Shaman A Lan", "pos": Vector2i(10, 26), "col": Color("d0f0ff"), "vis": ["s_au_intro", ""]}],
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
	# ---- Part VI: The Turning Wheel
	"maple": {
		"n": "Maple Gorge of Returning Souls", "w": 96, "h": 58, "seed": 231, "theme": "maple", "enemies": 20,
		"pool": [["maple_fox", 30, 30], ["lost_lantern", 30, 30], ["mossback_boar", 30, 30]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 28), "dest": Vector2i(3, 22), "open": ""},
			{"to": "karst", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_mp_ox"},
		],
		"npcs": [{"id": "lantern_monk", "n": "Lantern Monk Jing Kong", "pos": Vector2i(10, 26), "col": Color("e8c070"), "vis": ["s_mp_intro", ""]}],
		"bosses": [
			{"id": "nine_tail_fox", "pos": Vector2i(30, 40), "lv": 30, "req": 30},
			{"id": "waterfall_koi", "pos": Vector2i(46, 16), "lv": 30, "req": 30},
			{"id": "willow_widow", "pos": Vector2i(60, 40), "lv": 30, "req": 30},
			{"id": "ox_head", "pos": Vector2i(86, 28), "lv": 30, "req": 30},
			# Part XIII: a General of the Eight Gates
			{"id": "fetter_maple", "pos": Vector2i(74, 17), "lv": 52, "req": 51, "vis": ["s_p13_gates", ""]},
			# Part XIII: the heart of the Eight Gates, where Chiyou waits
			{"id": "chiyou", "pos": Vector2i(50, 30), "lv": 53, "req": 53, "vis": ["s_p13_chiyou", ""]},
		],
		# Part XIII: a war-band of the Eight Gates marches here once the formation wakes
		"warband": {"pool": [["fetter_sapling", 51, 53], ["jiuli_warrior", 51, 53], ["banner_ember", 51, 53], ["bronze_brow", 51, 53], ["zhuolu_fog", 51, 53]], "n": 8, "vis": "s_p13_home"},
		"pickups": [{"id": "slant1", "item": "soul_lantern", "pos": Vector2i(22, 12)}, {"id": "slant2", "item": "soul_lantern", "pos": Vector2i(40, 46)}, {"id": "slant3", "item": "soul_lantern", "pos": Vector2i(64, 30)}, {"id": "slant4", "item": "soul_lantern", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_mp_collect",
	},
	"karst": {
		"n": "Stone Forest of the Nine Bends", "w": 96, "h": 58, "seed": 241, "theme": "karst", "enemies": 20,
		"pool": [["river_carp", 30, 31], ["stone_macaque", 30, 31], ["mist_heron", 30, 31]],
		"portals": [
			{"to": "maple", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "springs", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_kr_horse"},
		],
		"npcs": [{"id": "fisher", "n": "Cormorant Fisher Old Yu", "pos": Vector2i(10, 26), "col": Color("a0b0a0"), "vis": ["s_kr_intro", ""]}],
		"bosses": [
			{"id": "cormorant_king", "pos": Vector2i(30, 40), "lv": 30, "req": 30},
			{"id": "karst_jiao", "pos": Vector2i(46, 16), "lv": 31, "req": 31},
			{"id": "stone_sentinel", "pos": Vector2i(60, 40), "lv": 31, "req": 31},
			{"id": "horse_face", "pos": Vector2i(86, 28), "lv": 31, "req": 31},
		],
		"pickups": [{"id": "mpearl1", "item": "memory_pearl", "pos": Vector2i(22, 12)}, {"id": "mpearl2", "item": "memory_pearl", "pos": Vector2i(40, 46)}, {"id": "mpearl3", "item": "memory_pearl", "pos": Vector2i(64, 30)}, {"id": "mpearl4", "item": "memory_pearl", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_kr_collect",
	},
	"springs": {
		"n": "Yellow Springs of Red Lilies", "w": 96, "h": 58, "seed": 251, "theme": "lilies", "enemies": 20,
		"pool": [["hopping_corpse", 31, 31], ["hungry_ghost", 31, 31], ["lily_moth", 31, 31]],
		"portals": [
			{"to": "karst", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "wheel", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_sp_unforgotten"},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "qiu_ye_springs", "n": "Qiu Ye", "pos": Vector2i(12, 26), "col": Color("2e5a48"), "asset": "qiu_ye", "fate": true},{"id": "meng_po", "n": "Meng Po of the Naihe Bridge", "pos": Vector2i(10, 26), "col": Color("e0d0c0"), "vis": ["s_sp_intro", ""]}],
		"bosses": [
			{"id": "corpse_patriarch", "pos": Vector2i(30, 40), "lv": 31, "req": 31},
			{"id": "bridge_serpent", "pos": Vector2i(46, 16), "lv": 31, "req": 31},
			{"id": "lily_empress", "pos": Vector2i(60, 40), "lv": 31, "req": 31},
			{"id": "the_unforgotten", "pos": Vector2i(86, 28), "lv": 31, "req": 31},
		],
		"pickups": [{"id": "fherb1", "item": "forget_herb", "pos": Vector2i(22, 12)}, {"id": "fherb2", "item": "forget_herb", "pos": Vector2i(40, 46)}, {"id": "fherb3", "item": "forget_herb", "pos": Vector2i(64, 30)}, {"id": "fherb4", "item": "forget_herb", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_sp_collect",
	},
	"wheel": {
		"n": "Wheel of the Six Paths", "w": 96, "h": 58, "seed": 261, "theme": "diyu", "enemies": 20,
		"pool": [["ghost_clerk", 31, 32], ["pool_crab", 31, 32], ["court_hound", 31, 32]],
		"portals": [
			{"to": "springs", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
		],
		"npcs": [{"id": "judge_cui", "n": "Judge Cui Jue", "pos": Vector2i(10, 26), "col": Color("c8d0e8"), "vis": ["s_wh_intro", ""]}],
		"bosses": [
			{"id": "karma_mirror", "pos": Vector2i(30, 40), "lv": 32, "req": 32},
			{"id": "burning_judge", "pos": Vector2i(46, 16), "lv": 32, "req": 32},
			{"id": "wheel_guardian", "pos": Vector2i(60, 40), "lv": 32, "req": 32},
			{"id": "king_yama", "pos": Vector2i(86, 28), "lv": 32, "req": 32},
			# Part XIV: Nie, the Unpaid, gathers at the heart of the Wheel once the threads are settled
			{"id": "nie", "pos": Vector2i(78, 30), "lv": 56, "req": 55, "vis": ["s_p14_nie", ""]},
		],
		# Part XIV: the grudges and debts of the whole journey swarm round the Wheel
		"warband": {"pool": [["grudge_wisp", 54, 56], ["debt_shade", 54, 56], ["karma_moth", 54, 56]], "n": 8, "vis": "s_p14_judge"},
		"pickups": [{"id": "spoke1", "item": "wheel_spoke", "pos": Vector2i(22, 12)}, {"id": "spoke2", "item": "wheel_spoke", "pos": Vector2i(40, 46)}, {"id": "spoke3", "item": "wheel_spoke", "pos": Vector2i(64, 30)}, {"id": "spoke4", "item": "wheel_spoke", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_wh_collect",
	},
	# ---- Part VII: The Unbroken Land
	"village": {
		"n": "Qingshi Village Below the Mountain", "w": 96, "h": 58, "seed": 271, "theme": "village", "enemies": 18,
		"pool": [["thread_moth", 33, 33], ["paper_crow", 33, 33], ["silk_bandit", 33, 33]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 28), "dest": Vector2i(6, 21), "open": ""},
			{"to": "terraces", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_vl_needle"},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "hu_village", "n": "Fang Hu", "pos": Vector2i(14, 17), "col": Color("6a4a32"), "asset": "hu_grown", "fate": true},
			{"id": "hu_end", "n": "Fang Hu", "pos": Vector2i(15, 26), "col": Color("6a4a32"), "asset": "hu_grown", "fate": true},
			{"id": "teacher_ren", "n": "Old Teacher Ren of the Village School", "pos": Vector2i(31, 33), "col": Color("5a4a6a")},
			{"id": "ox_herd_niu", "n": "Ah Niu the Ox-Herd", "pos": Vector2i(28, 31), "col": Color("8a6a3a")},
			{"id": "granny_wen", "n": "Granny Wen the Midwife", "pos": Vector2i(10, 21), "col": Color("c8b8a0")},
			{"id": "innkeeper", "n": "Innkeeper Fu", "pos": Vector2i(21, 33), "col": Color("d09a5a")},
			{"id": "weaver_liu", "n": "Weaver Liu", "pos": Vector2i(56, 21), "col": Color("b08ad0")},
			{"id": "farmer_lao", "n": "Farmer Lao", "pos": Vector2i(67, 19), "col": Color("6a7a5a")},
			{"id": "child_hua", "n": "Little Hua", "pos": Vector2i(27, 24), "col": Color("e0705a")},
			{"id": "tofu_sun", "n": "Tofu Seller Sun", "pos": Vector2i(43, 27), "col": Color("3a4a7a")},
			{"id": "scholar_wang", "n": "Scholar Wang", "pos": Vector2i(48, 37), "col": Color("e8e4d0")},
			{"id": "carpenter_gu", "n": "Carpenter Gu", "pos": Vector2i(21, 20), "col": Color("8a6a4a")},
			{"id": "herb_lan", "n": "Xiao Lan the Herb-Picker", "pos": Vector2i(37, 20), "col": Color("6a9a5a")},
		],
		"bosses": [
			{"id": "paper_tiger", "pos": Vector2i(30, 40), "lv": 33, "req": 33},
			{"id": "scarecrow_king", "pos": Vector2i(46, 16), "lv": 33, "req": 33},
			{"id": "well_spider", "pos": Vector2i(60, 40), "lv": 33, "req": 33},
			{"id": "needle_general", "pos": Vector2i(86, 28), "lv": 33, "req": 33},
		],
		"pickups": [{"id": "sthread1", "item": "silver_thread", "pos": Vector2i(22, 12)}, {"id": "sthread2", "item": "silver_thread", "pos": Vector2i(40, 46)}, {"id": "sthread3", "item": "silver_thread", "pos": Vector2i(64, 30)}, {"id": "sthread4", "item": "silver_thread", "pos": Vector2i(76, 10)},
			{"id": "cur_wutong2", "item": "wutong_seed", "pos": Vector2i(11, 23), "floor": ["wen_house", -1], "always": true}],
		"pickup_vis": "s_vl_collect",
		"springs": [Vector2i(30, 22)],
		"buildings": [
			{"id": "wen_house", "n": "Granny Wen's House", "style": "house", "rect": Rect2i(6, 19, 9, 6), "door": Vector2i(10, 24),
				"props": [["bed", Vector2i(7, 20), true], ["stove", Vector2i(13, 20), true], ["table", Vector2i(12, 22), true], ["cabinet", Vector2i(7, 23), false], ["lantern", Vector2i(13, 23), false]],
				"down": Vector2i(8, 22), "cellar": {"n": "Granny Wen's root cellar", "props": [["barrel", Vector2i(7, 20), true], ["barrel", Vector2i(13, 20), true], ["shelf", Vector2i(13, 22), true], ["lantern", Vector2i(10, 21), false]]}},
			{"id": "inn", "n": "The Green Stone Inn", "style": "inn", "rect": Rect2i(16, 30, 11, 6), "door": Vector2i(21, 30),
				"props": [["table", Vector2i(18, 32), true], ["stool", Vector2i(17, 32), false], ["table", Vector2i(18, 34), true], ["counter", Vector2i(24, 33), true], ["barrel", Vector2i(25, 31), true], ["barrel", Vector2i(25, 34), false], ["lantern", Vector2i(23, 31), false]]},
			{"id": "village_shrine", "n": "Shrine of the Earth God", "style": "shrine", "rect": Rect2i(34, 5, 9, 7), "door": Vector2i(38, 11),
				"props": [["altar", Vector2i(37, 6), true], ["altar", Vector2i(38, 6), true], ["altar", Vector2i(39, 6), true], ["statue", Vector2i(38, 6), false], ["cushion", Vector2i(38, 8), false], ["scroll", Vector2i(35, 8), false], ["scroll", Vector2i(41, 8), false]]},
			{"id": "weaver_house", "n": "Weaver Liu's Workshop", "style": "house", "rect": Rect2i(52, 19, 9, 6), "door": Vector2i(56, 24),
				"props": [["loom", Vector2i(53, 20), true], ["loom", Vector2i(59, 20), true], ["cabinet", Vector2i(59, 23), false], ["stool", Vector2i(54, 22), false]]},
			{"id": "empty_house", "n": "An Abandoned House", "style": "house", "rect": Rect2i(68, 40, 8, 6), "door": Vector2i(71, 40),
				"props": [["bed", Vector2i(69, 44), true], ["table", Vector2i(73, 43), true], ["stove", Vector2i(74, 44), true], ["shelf", Vector2i(74, 41), false]]},
			{"id": "teahouse", "n": "The Willow Teahouse", "style": "teahouse", "rect": Rect2i(30, 26, 9, 6), "door": Vector2i(34, 26),
				"props": [["table", Vector2i(32, 28), true], ["stool", Vector2i(31, 28), false], ["table", Vector2i(36, 29), true], ["stool", Vector2i(37, 29), false], ["counter", Vector2i(36, 27), true], ["lantern", Vector2i(32, 30), false]]},
			{"id": "tofu_shop", "n": "Sun's Tofu Shop", "style": "shop", "rect": Rect2i(40, 25, 7, 5), "door": Vector2i(43, 25),
				"props": [["counter", Vector2i(42, 27), false], ["barrel", Vector2i(45, 26), true], ["barrel", Vector2i(45, 28), true], ["shelf", Vector2i(41, 28), false]]},
			{"id": "carpentry", "n": "Gu's Carpentry", "style": "huizhou", "rect": Rect2i(16, 14, 8, 5), "door": Vector2i(19, 18),
				"props": [["rack", Vector2i(17, 15), true], ["table", Vector2i(21, 16), true], ["barrel", Vector2i(22, 15), false]]},
			{"id": "farmhouse", "n": "Lao's Farmhouse", "style": "farmhouse", "rect": Rect2i(62, 12, 8, 6), "door": Vector2i(65, 17),
				"props": [["bed", Vector2i(63, 13), true], ["stove", Vector2i(68, 13), true], ["barrel", Vector2i(63, 16), false], ["table", Vector2i(67, 15), true]]},
			{"id": "study", "n": "Scholar Wang's Study", "style": "huizhou", "rect": Rect2i(44, 34, 8, 6), "door": Vector2i(47, 34),
				"props": [["desk", Vector2i(49, 36), true], ["bookshelf", Vector2i(45, 37), true], ["scroll", Vector2i(50, 38), false], ["lantern", Vector2i(45, 35), false]]},
			{"id": "granary", "n": "Village Granary", "style": "farmhouse", "rect": Rect2i(76, 34, 7, 6), "door": Vector2i(79, 34),
				"props": [["barrel", Vector2i(77, 35), true], ["barrel", Vector2i(81, 35), true], ["barrel", Vector2i(77, 38), true], ["barrel", Vector2i(81, 38), true]]},
		],
	},
	"terraces": {
		"n": "Cloud-Tea Terraces", "w": 96, "h": 58, "seed": 281, "theme": "tea", "enemies": 20,
		"pool": [["tea_beetle", 33, 34], ["terrace_serpent", 33, 34], ["hill_sprite", 33, 34]],
		"portals": [
			{"to": "village", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "silk", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_te_matron"},
		],
		"npcs": [{"id": "tea_master", "n": "Tea Master Lu Yu", "pos": Vector2i(9, 25), "col": Color("6ab07a"), "vis": ["s_te_intro", ""]}],
		"bosses": [
			{"id": "wind_kite", "pos": Vector2i(30, 40), "lv": 33, "req": 33},
			{"id": "terrace_dragon", "pos": Vector2i(46, 16), "lv": 34, "req": 34},
			{"id": "hill_golem", "pos": Vector2i(60, 40), "lv": 34, "req": 34},
			{"id": "thread_matron", "pos": Vector2i(86, 28), "lv": 34, "req": 34},
		],
		"pickups": [{"id": "teabud1", "item": "tea_bud", "pos": Vector2i(22, 12)}, {"id": "teabud2", "item": "tea_bud", "pos": Vector2i(40, 46)}, {"id": "teabud3", "item": "tea_bud", "pos": Vector2i(64, 30)}, {"id": "teabud4", "item": "tea_bud", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_te_collect",
		"buildings": [
			{"id": "tea_house", "n": "Tea House of the Nine Terraces", "style": "inn", "rect": Rect2i(6, 22, 9, 7), "door": Vector2i(14, 25),
				"props": [["stove", Vector2i(7, 23), true], ["shelf", Vector2i(12, 23), true], ["table", Vector2i(8, 27), true], ["stool", Vector2i(10, 27), false], ["lantern", Vector2i(12, 27), false]]},
		],
	},
	"silk": {
		"n": "Mulberry Silk Woods", "w": 96, "h": 58, "seed": 291, "theme": "silk", "enemies": 20,
		"pool": [["silkworm", 34, 34], ["silk_moth", 34, 34], ["cocoon_wraith", 34, 34]],
		"portals": [
			{"to": "terraces", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "loom", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_sk_hands"},
		],
		"npcs": [{"id": "can_niang", "n": "Silk Farmer Can Niang", "pos": Vector2i(9, 25), "col": Color("e8d8b0"), "vis": ["s_sk_intro", ""]}],
		"bosses": [
			{"id": "silkworm_queen", "pos": Vector2i(30, 40), "lv": 34, "req": 34},
			{"id": "moth_empress", "pos": Vector2i(46, 16), "lv": 34, "req": 34},
			# Part XV: the queen of the moths that eat forgetting
			{"id": "forgetting_queen", "pos": Vector2i(49, 18), "lv": 58, "req": 57, "vis": ["s_p15_moth", ""]},
			{"id": "mulberry_ent", "pos": Vector2i(60, 40), "lv": 34, "req": 34},
			{"id": "thousand_hands", "pos": Vector2i(86, 28), "lv": 34, "req": 34},
		],
		"pickups": [{"id": "cocoon1", "item": "cocoon", "pos": Vector2i(22, 12)}, {"id": "cocoon2", "item": "cocoon", "pos": Vector2i(40, 46)}, {"id": "cocoon3", "item": "cocoon", "pos": Vector2i(64, 30)}, {"id": "cocoon4", "item": "cocoon", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_sk_collect",
		"buildings": [
			{"id": "silk_house", "n": "Silkworm House", "style": "house", "rect": Rect2i(6, 22, 9, 7), "door": Vector2i(14, 25),
				"props": [["shelf", Vector2i(7, 23), true], ["shelf", Vector2i(7, 27), true], ["loom", Vector2i(12, 23), true], ["herbs", Vector2i(12, 27), false]]},
		],
	},
	"loom": {
		"n": "The Loom of Borders", "w": 96, "h": 58, "seed": 301, "theme": "loom", "enemies": 20,
		"pool": [["spindle_imp", 35, 35], ["warp_wraith", 35, 35], ["shuttle_hawk", 35, 35]],
		"portals": [
			{"to": "silk", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
		],
		"npcs": [{"id": "apprentice_zhi", "n": "Zhi, the Last Weaver-Girl", "pos": Vector2i(10, 26), "col": Color("f0c8e8"), "vis": ["s_lm_intro", ""]}],
		"bosses": [
			{"id": "warp_beast", "pos": Vector2i(30, 40), "lv": 35, "req": 35},
			{"id": "spindle_golem", "pos": Vector2i(46, 16), "lv": 35, "req": 35},
			{"id": "shuttle_dragon", "pos": Vector2i(60, 40), "lv": 35, "req": 35},
			{"id": "qianxian", "pos": Vector2i(86, 28), "lv": 35, "req": 35},
			# Part XV: the hand that winds every thread back to the spindle
			{"id": "unweaver", "pos": Vector2i(83, 31), "lv": 59, "req": 58, "vis": ["s_p15_unweaver", ""]},
		],
		"pickups": [{"id": "shuttle1", "item": "shuttle", "pos": Vector2i(22, 12)}, {"id": "shuttle2", "item": "shuttle", "pos": Vector2i(40, 46)}, {"id": "shuttle3", "item": "shuttle", "pos": Vector2i(64, 30)}, {"id": "shuttle4", "item": "shuttle", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_lm_collect",
	},
	# ---- Part VIII: The River of Heaven
	"starferry": {
		"n": "Starfall Ferry on the Silver River", "w": 96, "h": 58, "seed": 311, "theme": "starferry", "enemies": 20,
		"pool": [["flood_carp", 36, 36], ["reed_wisp", 36, 36], ["ferry_crab", 36, 36]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 28), "dest": Vector2i(13, 21), "open": ""},
			{"to": "magpie", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_sf_qilin"},
		],
		"npcs": [{"id": "niu_lang", "n": "Niu Lang the Cowherd", "pos": Vector2i(9, 25), "col": Color("c8b890"), "vis": ["s_sf_intro", ""]}],
		"bosses": [
			{"id": "silt_jiao", "pos": Vector2i(30, 40), "lv": 36, "req": 36},
			{"id": "reed_widow", "pos": Vector2i(46, 16), "lv": 36, "req": 36},
			{"id": "carp_sage", "pos": Vector2i(60, 40), "lv": 36, "req": 36},
			{"id": "tide_qilin", "pos": Vector2i(86, 28), "lv": 36, "req": 36},
		],
		"pickups": [{"id": "rstar1", "item": "river_star", "pos": Vector2i(22, 12)}, {"id": "rstar2", "item": "river_star", "pos": Vector2i(40, 46)}, {"id": "rstar3", "item": "river_star", "pos": Vector2i(64, 30)}, {"id": "rstar4", "item": "river_star", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_sf_collect",
		"buildings": [
			{"id": "ferry_house", "n": "The Cowherd's Ferry House", "style": "house", "rect": Rect2i(6, 22, 9, 7), "door": Vector2i(14, 25),
				"props": [["bed", Vector2i(7, 23), true], ["stove", Vector2i(12, 23), true], ["table", Vector2i(8, 27), true], ["lantern", Vector2i(12, 27), false]]},
		],
	},
	"magpie": {
		"n": "Heights of the Magpie Bridge", "w": 96, "h": 58, "seed": 321, "theme": "magpie", "enemies": 20,
		"pool": [["cloud_ape", 36, 37], ["bridge_magpie", 36, 37], ["gale_wolf", 36, 37]],
		"portals": [
			{"to": "starferry", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "starpalace", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_mg_marshal"},
		],
		"npcs": [{"id": "que_lao", "n": "Que Lao, the Old Magpie", "pos": Vector2i(10, 26), "col": Color("3a4a7a"), "vis": ["s_mg_intro", ""]}],
		"bosses": [
			{"id": "cloud_ape_king", "pos": Vector2i(30, 40), "lv": 36, "req": 36},
			{"id": "storm_magpie", "pos": Vector2i(46, 16), "lv": 37, "req": 37},
			{"id": "pier_golem", "pos": Vector2i(60, 40), "lv": 37, "req": 37},
			{"id": "crow_marshal", "pos": Vector2i(86, 28), "lv": 37, "req": 37},
		],
		"pickups": [{"id": "plume1", "item": "magpie_plume", "pos": Vector2i(22, 12)}, {"id": "plume2", "item": "magpie_plume", "pos": Vector2i(40, 46)}, {"id": "plume3", "item": "magpie_plume", "pos": Vector2i(64, 30)}, {"id": "plume4", "item": "magpie_plume", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_mg_collect",
	},
	"starpalace": {
		"n": "Palace of the Weaver Star", "w": 96, "h": 58, "seed": 331, "theme": "starpalace", "enemies": 20,
		"pool": [["star_moth", 37, 37], ["loom_wraith", 37, 37], ["star_qilin", 37, 37]],
		"portals": [
			{"to": "magpie", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
			{"to": "jasper", "pos": Vector2i(94, 28), "dest": Vector2i(4, 28), "open": "s_wv_warden"},
		],
		"npcs": [{"id": "zhi_nu", "n": "Zhi Nu, the Weaver Star", "pos": Vector2i(9, 25), "col": Color("c8d0ff"), "vis": ["s_wv_intro", ""]}],
		"bosses": [
			{"id": "seven_star_moth", "pos": Vector2i(30, 40), "lv": 37, "req": 37},
			{"id": "weaving_frame", "pos": Vector2i(46, 16), "lv": 37, "req": 37},
			{"id": "hall_qilin", "pos": Vector2i(60, 40), "lv": 37, "req": 37},
			{"id": "river_warden", "pos": Vector2i(86, 28), "lv": 38, "req": 38},
		],
		"pickups": [{"id": "sthr1", "item": "star_thread", "pos": Vector2i(22, 12)}, {"id": "sthr2", "item": "star_thread", "pos": Vector2i(40, 46)}, {"id": "sthr3", "item": "star_thread", "pos": Vector2i(64, 30)}, {"id": "sthr4", "item": "star_thread", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_wv_collect",
		"buildings": [
			{"id": "weaving_hall", "n": "Hall of the Cloud Loom", "style": "house", "rect": Rect2i(6, 22, 9, 7), "door": Vector2i(14, 25),
				"props": [["loom", Vector2i(7, 23), true], ["loom", Vector2i(7, 27), true], ["shelf", Vector2i(12, 23), true], ["lantern", Vector2i(12, 27), false]]},
		],
	},
	"jasper": {
		"n": "The Jasper Pool of Kunlun", "w": 96, "h": 58, "seed": 341, "theme": "jasper", "enemies": 20,
		"pool": [["kunlun_tiger", 38, 38], ["jade_qilin", 38, 38], ["kunlun_peach_sprite", 38, 38]],
		"portals": [
			{"to": "starpalace", "pos": Vector2i(1, 28), "dest": Vector2i(90, 28), "open": ""},
		],
		"npcs": [{"id": "dong_shuang", "n": "Dong Shuang, Maid of the Jasper Pool", "pos": Vector2i(10, 26), "col": Color("6ad0a0"), "vis": ["s_jp_intro", ""]}],
		"bosses": [
			{"id": "kaiming_beast", "pos": Vector2i(30, 40), "lv": 38, "req": 38},
			{"id": "blue_birds", "pos": Vector2i(46, 16), "lv": 38, "req": 38},
			{"id": "white_ape", "pos": Vector2i(60, 40), "lv": 38, "req": 38},
			{"id": "xiwangmu", "pos": Vector2i(86, 28), "lv": 38, "req": 38},
		],
		"pickups": [{"id": "kpeach1", "item": "kunlun_peach", "pos": Vector2i(22, 12)}, {"id": "kpeach2", "item": "kunlun_peach", "pos": Vector2i(40, 46)}, {"id": "kpeach3", "item": "kunlun_peach", "pos": Vector2i(64, 30)}, {"id": "kpeach4", "item": "kunlun_peach", "pos": Vector2i(76, 10)}],
		"pickup_vis": "s_jp_collect",
		"springs": [Vector2i(48, 30)],
	},
	# ---- Part IX: The Tenth Sun
	# The last market town on the pilgrims' road to the Valley of Sunrise, where it has been noon for nine days.
	# "lanes" are paved strips laid over the ground before the buildings go up (see MapGen.build);
	# the townsfolk are visible for the rest of the game from the moment the road to Yanggu opens.
	"yanggu": {
		"n": "Yanggu, the Dawn Market", "w": 104, "h": 60, "seed": 351, "theme": "yanggu", "enemies": 22,
		"pool": [["noon_cur", 39, 39], ["noon_cicada", 39, 39], ["clay_toad", 39, 39]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 30), "dest": Vector2i(36, 22), "open": ""},
			{"to": "millet", "pos": Vector2i(102, 25), "dest": Vector2i(4, 24), "open": "s_yg_hanba"},
		],
		"npcs": [
			{"id": "archer_kong", "n": "Archery-Master Kong", "pos": Vector2i(32, 27), "col": Color("6a5a3a"), "vis": ["s_yg_intro", ""]},
			{"id": "lantern_xi", "n": "Lantern-Maker Xi", "pos": Vector2i(31, 31), "col": Color("d84a2a"), "vis": ["s_yg_intro", ""]},
			{"id": "ah_mei", "n": "Ah Mei the Lantern-Maker", "pos": Vector2i(12, 35), "col": Color("e05a4a"), "vis": ["s_yg_intro", ""]},
			{"id": "watchman_zhou", "n": "Night-Watchman Lao Zhou", "pos": Vector2i(36, 27), "col": Color("5a6a8a"), "vis": ["s_yg_intro", ""]},
			{"id": "innkeeper_bao", "n": "Innkeeper Bao of the Sleepless Inn", "pos": Vector2i(12, 24), "col": Color("b07a4a"), "vis": ["s_yg_intro", ""]},
			{"id": "tea_seller_pan", "n": "Old Pan the Tea Seller", "pos": Vector2i(25, 35), "col": Color("5a8a5a"), "vis": ["s_yg_intro", ""]},
			{"id": "dyer_su", "n": "Madam Su the Dyer", "pos": Vector2i(41, 35), "col": Color("a05a9a"), "vis": ["s_yg_intro", ""]},
			{"id": "monk_huiming", "n": "Monk Hui Ming of the Sun Shrine", "pos": Vector2i(41, 19), "col": Color("e0a040"), "vis": ["s_yg_intro", ""]},
			{"id": "granny_gu", "n": "Granny Gu, Keeper of the Granary", "pos": Vector2i(57, 18), "col": Color("8a7a6a"), "vis": ["s_yg_intro", ""]},
			{"id": "porter_niu", "n": "Big Niu the Porter", "pos": Vector2i(54, 22), "col": Color("8a6a4a"), "vis": ["s_yg_intro", ""]},
			{"id": "little_dou", "n": "Little Dou", "pos": Vector2i(55, 34), "col": Color("f0a060"), "vis": ["s_yg_intro", ""]},
		],
		"bosses": [
			{"id": "mirage_fox", "pos": Vector2i(61, 49), "lv": 39, "req": 39},
			{"id": "sundial_golem", "pos": Vector2i(59, 30), "lv": 39, "req": 39},
			{"id": "lantern_dragon", "pos": Vector2i(12, 47), "lv": 39, "req": 39},
			{"id": "hanba", "pos": Vector2i(92, 22), "lv": 39, "req": 39},
		],
		"pickups": [{"id": "nember1", "item": "noon_ember", "pos": Vector2i(24, 9)}, {"id": "nember2", "item": "noon_ember", "pos": Vector2i(30, 52)}, {"id": "nember3", "item": "noon_ember", "pos": Vector2i(76, 42)}, {"id": "nember4", "item": "noon_ember", "pos": Vector2i(80, 11)}],
		"pickup_vis": "s_yg_collect",
		# the main street, the crossroads lane, the market square, the east road and three alleys
		"lanes": [Rect2i(2, 29, 64, 2), Rect2i(33, 9, 2, 42), Rect2i(52, 24, 14, 13), Rect2i(66, 25, 36, 2), Rect2i(60, 37, 2, 10), Rect2i(41, 24, 2, 5), Rect2i(57, 22, 2, 2)],
		"buildings": [
			{"id": "sleepless_inn", "n": "The Sleepless Inn", "style": "huizhou", "rect": Rect2i(5, 20, 12, 9), "door": Vector2i(10, 28),
				"props": [["table", Vector2i(8, 23), true], ["stool", Vector2i(7, 23), false], ["table", Vector2i(8, 26), true], ["stool", Vector2i(7, 26), false], ["counter", Vector2i(13, 22), true], ["barrel", Vector2i(15, 21), true], ["barrel", Vector2i(15, 26), false], ["lantern", Vector2i(11, 21), false]]},
			{"id": "archery_hall", "n": "Hall of the Archer Yi", "style": "hall", "rect": Rect2i(18, 18, 13, 11), "door": Vector2i(24, 28),
				"props": [["altar", Vector2i(23, 19), true], ["altar", Vector2i(24, 19), true], ["altar", Vector2i(25, 19), true], ["statue", Vector2i(24, 19), false], ["rack", Vector2i(19, 20), true], ["rack", Vector2i(19, 23), true], ["rack", Vector2i(29, 20), true], ["rack", Vector2i(29, 23), true], ["cushion", Vector2i(24, 22), false], ["barrel", Vector2i(20, 26), true], ["barrel", Vector2i(28, 26), true]]},
			{"id": "sun_shrine", "n": "Shrine of the Morning Sun", "style": "shrine", "rect": Rect2i(36, 15, 11, 9), "door": Vector2i(41, 23),
				"props": [["altar", Vector2i(40, 16), true], ["altar", Vector2i(41, 16), true], ["altar", Vector2i(42, 16), true], ["statue", Vector2i(41, 16), false], ["cushion", Vector2i(39, 19), false], ["cushion", Vector2i(43, 19), false], ["scroll", Vector2i(37, 18), false], ["scroll", Vector2i(45, 18), false]]},
			{"id": "granary", "n": "Yanggu Granary", "style": "farmhouse", "rect": Rect2i(52, 14, 11, 8), "door": Vector2i(57, 21),
				"props": [["barrel", Vector2i(53, 15), true], ["barrel", Vector2i(55, 15), true], ["barrel", Vector2i(59, 15), true], ["barrel", Vector2i(61, 15), true], ["shelf", Vector2i(53, 19), true], ["cabinet", Vector2i(61, 19), false]]},
			{"id": "lantern_shop", "n": "Ah Mei's Lantern Shop", "style": "shop", "rect": Rect2i(7, 32, 10, 8), "door": Vector2i(12, 32),
				"props": [["shelf", Vector2i(8, 33), true], ["shelf", Vector2i(8, 36), true], ["counter", Vector2i(14, 34), true], ["lantern", Vector2i(10, 37), false], ["lantern", Vector2i(13, 37), false], ["table", Vector2i(15, 37), true]]},
			{"id": "crossroads_tea", "n": "Tea House at the Crossroads", "style": "teahouse", "rect": Rect2i(20, 32, 10, 7), "door": Vector2i(25, 32),
				"props": [["table", Vector2i(22, 34), true], ["stool", Vector2i(21, 34), false], ["table", Vector2i(22, 36), true], ["stool", Vector2i(21, 36), false], ["stove", Vector2i(28, 33), true], ["shelf", Vector2i(28, 36), true], ["lantern", Vector2i(26, 37), false]]},
			{"id": "dye_shop", "n": "Madam Su's Cloth and Dye Shop", "style": "shop", "rect": Rect2i(37, 32, 10, 8), "door": Vector2i(41, 32),
				"props": [["loom", Vector2i(38, 33), true], ["loom", Vector2i(38, 36), true], ["shelf", Vector2i(45, 33), true], ["cabinet", Vector2i(45, 37), false], ["counter", Vector2i(43, 35), true]]},
		],
	},
	# cracked drought farmland and withered millet along a dry river, a wayside shrine of Hou Ji
	"millet": {
		"n": "The Scorched Millet Plains", "w": 100, "h": 52, "seed": 361, "theme": "millet", "enemies": 20,
		"pool": [["plague_locust", 39, 40], ["drought_scorpion", 39, 40], ["haze_wisp", 39, 40]],
		"portals": [
			{"to": "yanggu", "pos": Vector2i(1, 24), "dest": Vector2i(98, 25), "open": ""},
			{"to": "fusang", "pos": Vector2i(98, 30), "dest": Vector2i(4, 34), "open": "s_mf_bifang"},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "tala_plains", "n": "Tala of the Horse-Folk", "pos": Vector2i(17, 22), "col": Color("d8a04a"), "asset": "tala", "fate": true},{"id": "farmer_tian", "n": "Old Farmer Tian", "pos": Vector2i(15, 21), "col": Color("8a7a4a"), "vis": ["s_mf_intro", ""]}],
		"bosses": [
			{"id": "locust_marquis", "pos": Vector2i(34, 10), "lv": 39, "req": 39},
			{"id": "dust_devil", "pos": Vector2i(46, 43), "lv": 40, "req": 40},
			{"id": "well_tortoise", "pos": Vector2i(70, 15), "lv": 40, "req": 40},
			{"id": "bifang", "pos": Vector2i(88, 33), "lv": 40, "req": 40},
		],
		"pickups": [{"id": "rstone1", "item": "rain_stone", "pos": Vector2i(20, 42)}, {"id": "rstone2", "item": "rain_stone", "pos": Vector2i(50, 22)}, {"id": "rstone3", "item": "rain_stone", "pos": Vector2i(66, 44)}, {"id": "rstone4", "item": "rain_stone", "pos": Vector2i(84, 8)}],
		"pickup_vis": "s_mf_collect",
		# the farm track from the west gate past the shrine, and the dyke road east
		"lanes": [Rect2i(2, 24, 22, 2), Rect2i(12, 19, 2, 5), Rect2i(56, 30, 42, 2)],
		"buildings": [
			{"id": "houji_shrine", "n": "Wayside Shrine of Hou Ji", "style": "shrine", "rect": Rect2i(8, 12, 9, 7), "door": Vector2i(12, 18),
				"props": [["altar", Vector2i(11, 13), true], ["altar", Vector2i(12, 13), true], ["altar", Vector2i(13, 13), true], ["statue", Vector2i(12, 13), false], ["cushion", Vector2i(12, 15), false], ["herbs", Vector2i(9, 14), false], ["herbs", Vector2i(15, 14), false]]},
			{"id": "tian_farmhouse", "n": "Old Tian's Farmhouse", "style": "house", "rect": Rect2i(22, 30, 9, 6), "door": Vector2i(26, 30),
				"props": [["bed", Vector2i(23, 31), true], ["stove", Vector2i(29, 31), true], ["table", Vector2i(25, 33), true], ["barrel", Vector2i(29, 34), false], ["herbs", Vector2i(23, 34), false]]},
		],
	},
	# hot springs and steaming cliffs round the colossal Fusang mulberry, where the sun-crows roost
	"fusang": {
		"n": "Fusang, the Valley of Sunrise", "w": 88, "h": 64, "seed": 371, "theme": "fusang", "enemies": 20,
		"pool": [["spring_macaque", 40, 40], ["sun_fledgling", 40, 40], ["fusang_sprite", 40, 40]],
		"portals": [
			{"to": "millet", "pos": Vector2i(1, 34), "dest": Vector2i(94, 30), "open": ""},
			{"to": "guanghan", "pos": Vector2i(86, 30), "dest": Vector2i(4, 28), "open": "s_fs_jinwu"},
		],
		"npcs": [{"id": "feng_meng", "n": "Feng Meng, the Last Apprentice", "pos": Vector2i(15, 30), "col": Color("7a6a5a"), "vis": ["s_fs_intro", ""]},
			# Part XII: Mazu, who brings the boats home, waiting with her boat on the pool where the ten suns
			# bathed (its hot spring runs under the hills to the sea)
			{"id": "mazu", "n": "Mazu, Who Brings the Boats Home", "pos": Vector2i(69, 47), "col": Color("d83a3a"), "vis": ["s_p12_home", ""]}],
		"bosses": [
			{"id": "boiled_crab", "pos": Vector2i(36, 16), "lv": 40, "req": 40},
			{"id": "ninth_ember", "pos": Vector2i(52, 6), "lv": 40, "req": 40},
			{"id": "sun_moth", "pos": Vector2i(63, 50), "lv": 40, "req": 40},
			{"id": "jinwu", "pos": Vector2i(59, 36), "lv": 41, "req": 41},
		],
		"pickups": [{"id": "sfeather1", "item": "sun_feather", "pos": Vector2i(22, 14)}, {"id": "sfeather2", "item": "sun_feather", "pos": Vector2i(40, 40)}, {"id": "sfeather3", "item": "sun_feather", "pos": Vector2i(58, 26)}, {"id": "sfeather4", "item": "sun_feather", "pos": Vector2i(72, 56)}],
		"pickup_vis": "s_fs_collect",
		"springs": [Vector2i(44, 30)],
		# the pilgrims' path in from the plains
		"lanes": [Rect2i(2, 34, 16, 2)],
		# the colossal Fusang mulberry towers over the middle of the valley (Terrain3D.fusang_tree);
		# "blocks" keeps the ground under its trunk solid
		"blocks": [Rect2i(49, 38, 7, 6)],
		"landmark": {"kind": "fusang", "pos": Vector2i(52, 41)},
		"buildings": [
			{"id": "archer_hut", "n": "Feng Meng's Hut", "style": "house", "rect": Rect2i(9, 38, 8, 6), "door": Vector2i(13, 38),
				"props": [["bed", Vector2i(10, 42), true], ["rack", Vector2i(15, 39), true], ["rack", Vector2i(15, 42), true], ["table", Vector2i(10, 39), true], ["lantern", Vector2i(13, 42), false]]},
		],
	},
	# a silver night of frost and osmanthus on the moon, the Palace of Vast Cold at its far end
	"guanghan": {
		"n": "Guanghan, the Palace of the Moon", "w": 92, "h": 56, "seed": 381, "theme": "guanghan", "enemies": 20,
		"pool": [["frost_hare", 41, 41], ["moon_toad", 41, 41], ["silver_crane", 41, 41]],
		"portals": [
			{"to": "fusang", "pos": Vector2i(1, 28), "dest": Vector2i(82, 30), "open": ""},
		],
		"npcs": [{"id": "chang_e", "n": "Chang'e of the Moon Palace", "pos": Vector2i(13, 23), "col": Color("e8eeff"), "vis": ["s_gh_intro", ""]}],
		"bosses": [
			{"id": "wu_gang", "pos": Vector2i(30, 12), "lv": 41, "req": 41},
			{"id": "tiangou", "pos": Vector2i(42, 46), "lv": 41, "req": 41},
			{"id": "mortar_rabbit", "pos": Vector2i(64, 20), "lv": 41, "req": 41},
			{"id": "xihe", "pos": Vector2i(84, 30), "lv": 41, "req": 41},
		],
		"pickups": [{"id": "osman1", "item": "osmanthus", "pos": Vector2i(18, 44)}, {"id": "osman2", "item": "osmanthus", "pos": Vector2i(38, 30)}, {"id": "osman3", "item": "osmanthus", "pos": Vector2i(54, 8)}, {"id": "osman4", "item": "osmanthus", "pos": Vector2i(72, 44)}],
		"pickup_vis": "s_gh_collect",
		"springs": [Vector2i(50, 32)],
		# the moonstone causeway up to the palace hall
		"lanes": [Rect2i(66, 29, 16, 2)],
		"buildings": [
			{"id": "change_pavilion", "n": "Pavilion of Vast Cold", "style": "library", "rect": Rect2i(9, 19, 9, 8), "door": Vector2i(13, 26),
				"props": [["shelf", Vector2i(10, 20), true], ["table", Vector2i(16, 20), true], ["cushion", Vector2i(13, 21), false], ["herbs", Vector2i(10, 24), false], ["lantern", Vector2i(16, 24), false]]},
		],
	},
	# ---- Part X: The Nine Cauldrons
	# a ferry town on the river below the Dragon Gate, where the golden carp leap to become dragons
	"longmen": {
		"n": "Longmen, the Dragon Gate Ferry", "w": 100, "h": 60, "seed": 391, "theme": "longmen", "enemies": 22,
		"pool": [["gate_carp", 42, 42], ["eel_bandit", 42, 42], ["silt_crab", 42, 42]],
		"portals": [
			{"to": "sect", "pos": Vector2i(1, 30), "dest": Vector2i(12, 3), "open": ""},
			{"to": "drowned", "pos": Vector2i(98, 30), "dest": Vector2i(4, 29), "open": "s_dg_hebo"},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "hu_longmen", "n": "Fang Hu", "pos": Vector2i(33, 31), "col": Color("6a4a32"), "asset": "hu_grown", "fate": true},
			{"id": "xia_cormorant", "n": "Xia and Her Cormorant", "pos": Vector2i(31, 31), "col": Color("4a6a7a")},
			{"id": "examiner_fan", "n": "Fan, Who Failed the Examinations Nine Times", "pos": Vector2i(25, 31), "col": Color("3a3a5a")},
			{"id": "harbour_yao", "n": "Harbourmistress Jiang Yao", "pos": Vector2i(37, 45), "col": Color("2e5a7a")},
			{"id": "boatwright_gao", "n": "Boatwright Gao", "pos": Vector2i(34, 23), "col": Color("7a5a3a")},
			{"id": "fishwife_lu", "n": "Fishwife Lu", "pos": Vector2i(34, 36), "col": Color("c86a4a")},
			{"id": "lockkeeper_qian", "n": "Lock-Keeper Qian", "pos": Vector2i(41, 11), "col": Color("5a6a7a")},
			{"id": "shrine_hua", "n": "Shrine-Maiden Hua", "pos": Vector2i(17, 37), "col": Color("f0ece4")},
			{"id": "scholar_cen", "n": "Scholar Cen, Who Failed at the Dragon Gate", "pos": Vector2i(22, 12), "col": Color("6a5a8a")},
			{"id": "carp_boy_yu", "n": "Little Yu, Who Feeds the Carp", "pos": Vector2i(45, 25), "col": Color("e0a040")},
			{"id": "innkeeper_dong", "n": "Innkeeper Dong of the Leaping Carp", "pos": Vector2i(11, 23), "col": Color("a85a3a")},
		],
		"bosses": [
			{"id": "sulking_carp", "pos": Vector2i(62, 13), "lv": 42, "req": 42},
			{"id": "eel_king", "pos": Vector2i(72, 47), "lv": 42, "req": 42},
			{"id": "drowned_bell", "pos": Vector2i(64, 37), "lv": 42, "req": 42},
			{"id": "stone_lion", "pos": Vector2i(82, 14), "lv": 42, "req": 42},
			{"id": "he_bo", "pos": Vector2i(90, 30), "lv": 42, "req": 42},
		],
		"pickups": [{"id": "cscale1", "item": "carp_scale", "pos": Vector2i(66, 6)}, {"id": "cscale2", "item": "carp_scale", "pos": Vector2i(76, 22)}, {"id": "cscale3", "item": "carp_scale", "pos": Vector2i(84, 44)}, {"id": "cscale4", "item": "carp_scale", "pos": Vector2i(20, 52)},
			{"id": "cur_pearl3", "item": "night_pearl", "pos": Vector2i(13, 24), "floor": ["carp_inn", 1], "always": true},
			{"id": "cache_lm1", "item": "stones", "n": 1800, "pos": Vector2i(38, 47), "floor": ["harbour_office", -1], "always": true}],
		"pickup_vis": "s_dg_collect",
		"springs": [Vector2i(25, 46)],
		# the river comes down from the Dragon Gate falls and runs past the quay; the main street
		# crosses it on a bridge
		"river": [Vector2i(54, 6), Vector2i(52, 59), 4],
		"lanes": [Rect2i(2, 29, 66, 2), Rect2i(28, 8, 2, 42), Rect2i(45, 10, 2, 40)],
		"blocks": [Rect2i(46, 1, 4, 5), Rect2i(59, 1, 4, 5)],
		"landmark": {"kind": "dragongate", "pos": Vector2i(54, 3)},
		"buildings": [
			{"id": "carp_inn", "n": "The Leaping Carp Inn", "style": "inn", "rect": Rect2i(6, 20, 11, 8), "door": Vector2i(11, 27),
				"props": [["table", Vector2i(8, 22), true], ["stool", Vector2i(9, 22), false], ["table", Vector2i(8, 25), true], ["counter", Vector2i(14, 22), true], ["barrel", Vector2i(15, 25), true], ["lantern", Vector2i(13, 25), false]],
				"up": Vector2i(15, 21), "upper": {"n": "the guest rooms", "props": [["bed", Vector2i(8, 21), true], ["bed", Vector2i(8, 25), true], ["bed", Vector2i(14, 25), true], ["table", Vector2i(11, 23), true], ["lantern", Vector2i(12, 21), false]]}},
			{"id": "river_temple", "n": "Temple of the River Earl", "style": "shrine", "rect": Rect2i(12, 33, 11, 9), "door": Vector2i(17, 33),
				"props": [["altar", Vector2i(16, 40), true], ["altar", Vector2i(17, 40), true], ["altar", Vector2i(18, 40), true], ["statue", Vector2i(17, 40), false], ["cushion", Vector2i(15, 37), false], ["scroll", Vector2i(13, 35), false], ["scroll", Vector2i(21, 35), false]]},
			{"id": "boatyard", "n": "Gao's Boatyard", "style": "dorm", "rect": Rect2i(30, 20, 10, 7), "door": Vector2i(34, 26),
				"props": [["rack", Vector2i(31, 21), true], ["rack", Vector2i(38, 21), true], ["table", Vector2i(37, 24), true], ["barrel", Vector2i(31, 24), false]]},
			{"id": "fish_market", "n": "Longmen Fish Market", "style": "shop", "rect": Rect2i(30, 33, 10, 7), "door": Vector2i(34, 33),
				"props": [["counter", Vector2i(32, 36), false], ["barrel", Vector2i(38, 34), true], ["barrel", Vector2i(38, 37), true], ["shelf", Vector2i(31, 38), true]]},
			{"id": "lock_house", "n": "The Lock-Keeper's House", "style": "house", "rect": Rect2i(38, 8, 7, 6), "door": Vector2i(41, 13),
				"props": [["bed", Vector2i(39, 9), true], ["stove", Vector2i(43, 9), true], ["lantern", Vector2i(43, 12), false]]},
			{"id": "stilt_teahouse", "n": "Teahouse on Stilts", "style": "teahouse", "rect": Rect2i(18, 8, 9, 7), "door": Vector2i(22, 14),
				"props": [["table", Vector2i(20, 10), true], ["stool", Vector2i(19, 10), false], ["table", Vector2i(25, 11), true], ["lantern", Vector2i(24, 9), false]]},
			{"id": "harbour_office", "n": "Harbourmaster's Office", "style": "huizhou", "rect": Rect2i(33, 42, 9, 7), "door": Vector2i(37, 42),
				"props": [["desk", Vector2i(39, 45), true], ["shelf", Vector2i(34, 47), true], ["scroll", Vector2i(34, 43), false], ["lantern", Vector2i(40, 47), false]],
				"down": Vector2i(40, 43), "cellar": {"n": "the flood-record store", "props": [["shelf", Vector2i(34, 44), true], ["shelf", Vector2i(34, 46), true], ["barrel", Vector2i(40, 46), true], ["lantern", Vector2i(37, 44), false]]}},
		],
	},
	# a slow flood over the old rice fields, crossed by Yu's dykes; Gun's walls of growing earth
	"drowned": {
		"n": "The Drowned Fields of Gun", "w": 96, "h": 58, "seed": 401, "theme": "drowned", "enemies": 20,
		"pool": [["flood_toad", 42, 43], ["mud_heron", 42, 43], ["rice_wraith", 42, 43]],
		"portals": [
			{"to": "longmen", "pos": Vector2i(1, 29), "dest": Vector2i(94, 30), "open": ""},
			{"to": "tushan", "pos": Vector2i(94, 29), "dest": Vector2i(4, 30), "open": "s_df_gun"},
		],
		"npcs": [{"id": "bo_yi", "n": "Bo Yi of the Dykes", "pos": Vector2i(12, 35), "col": Color("6a7a5a")}],
		"bosses": [
			{"id": "toad_matriarch", "pos": Vector2i(26, 46), "lv": 42, "req": 42},
			{"id": "heron_lord", "pos": Vector2i(50, 12), "lv": 43, "req": 43},
			{"id": "mud_dragon", "pos": Vector2i(62, 40), "lv": 43, "req": 43},
			{"id": "carrier_turtle", "pos": Vector2i(30, 16), "lv": 43, "req": 43},
			{"id": "gun", "pos": Vector2i(86, 22), "lv": 43, "req": 43},
		],
		"pickups": [{"id": "xirang1", "item": "xirang", "pos": Vector2i(18, 10)}, {"id": "xirang2", "item": "xirang", "pos": Vector2i(42, 24)}, {"id": "xirang3", "item": "xirang", "pos": Vector2i(70, 14)}, {"id": "xirang4", "item": "xirang", "pos": Vector2i(78, 50)}],
		"pickup_vis": "s_df_collect",
		# the dyke road winds across the flood from the ferry road to the hills
		"roads": [[Vector2i(2, 29), Vector2i(18, 27), Vector2i(34, 32), Vector2i(42, 42), Vector2i(58, 46), Vector2i(70, 37), Vector2i(82, 30), Vector2i(93, 29)]],
		"buildings": [
			{"id": "dyke_house", "n": "Bo Yi's Dyke-House", "style": "farmhouse", "rect": Rect2i(8, 32, 9, 6), "door": Vector2i(12, 32),
				"props": [["bed", Vector2i(9, 36), true], ["stove", Vector2i(15, 33), true], ["rack", Vector2i(15, 36), true], ["lantern", Vector2i(9, 33), false]]},
			{"id": "gun_shrine", "n": "Shrine of Gun on Feather Hill", "style": "shrine", "rect": Rect2i(76, 6, 9, 7), "door": Vector2i(80, 12),
				"props": [["altar", Vector2i(79, 7), true], ["altar", Vector2i(80, 7), true], ["altar", Vector2i(81, 7), true], ["statue", Vector2i(80, 7), false], ["cushion", Vector2i(80, 9), false]]},
			{"id": "drowned_farm", "n": "A Drowned Farmstead", "style": "farmhouse", "rect": Rect2i(50, 48, 8, 6), "door": Vector2i(53, 48),
				"props": [["bed", Vector2i(51, 52), true], ["barrel", Vector2i(56, 52), true], ["table", Vector2i(55, 50), true]]},
		],
	},
	# the cauldron-casters' town on Mount Kuaiji, where Yu's Nine Cauldrons were cast
	"tushan": {
		"n": "Tushan, the Town of the Cauldron-Casters", "w": 96, "h": 60, "seed": 411, "theme": "tushan", "enemies": 20,
		"pool": [["slag_golem", 43, 43], ["bronze_hound", 43, 43], ["charcoal_wisp", 43, 43]],
		"portals": [
			{"to": "drowned", "pos": Vector2i(1, 30), "dest": Vector2i(90, 29), "open": ""},
			{"to": "buzhou", "pos": Vector2i(94, 30), "dest": Vector2i(4, 29), "open": "s_ts_taotie"},
		],
		"npcs": [
			{"id": "auntie_rong", "n": "Auntie Rong of the Smelting Pits", "pos": Vector2i(29, 31), "col": Color("a84a2a")},
			{"id": "bell_tuner_gong", "n": "Bell-Tuner Gong", "pos": Vector2i(25, 28), "col": Color("8a6a3a")},
			{"id": "tu_lan", "n": "Tu Lan, Last of the Cauldron-Casters", "pos": Vector2i(11, 21), "col": Color("8a3a2a")},
			{"id": "caster_wei", "n": "Bell-Caster Wei", "pos": Vector2i(46, 23), "col": Color("6a5a4a")},
			{"id": "carver_shi", "n": "Stone-Carver Shi", "pos": Vector2i(24, 39), "col": Color("8a8a80")},
			{"id": "charcoal_tan", "n": "Charcoal-Burner Ah Tan", "pos": Vector2i(10, 39), "col": Color("3a3a3a")},
			{"id": "innkeeper_lou", "n": "Innkeeper Lou of the Late Arrival", "pos": Vector2i(41, 38), "col": Color("a86a5a")},
			{"id": "little_qi", "n": "Little Qi", "pos": Vector2i(18, 32), "col": Color("c8803a")},
		],
		"bosses": [
			{"id": "slag_serpent", "pos": Vector2i(64, 12), "lv": 43, "req": 43},
			{"id": "stone_mother", "pos": Vector2i(62, 48), "lv": 43, "req": 43},
			{"id": "fangfeng", "pos": Vector2i(76, 34), "lv": 44, "req": 44},
			{"id": "grudge_fangfeng", "pos": Vector2i(78, 35), "lv": 55, "req": 54, "vis": ["s_p14_grudges", ""]},
			{"id": "tushan_fox", "pos": Vector2i(58, 24), "lv": 44, "req": 44},
			{"id": "taotie", "pos": Vector2i(88, 30), "lv": 44, "req": 44},
		],
		"pickups": [{"id": "cshard1", "item": "cauldron_shard", "pos": Vector2i(56, 6)}, {"id": "cshard2", "item": "cauldron_shard", "pos": Vector2i(70, 52)}, {"id": "cshard3", "item": "cauldron_shard", "pos": Vector2i(82, 12)}, {"id": "cshard4", "item": "cauldron_shard", "pos": Vector2i(52, 40)},
			{"id": "cur_wine3", "item": "peach_wine", "pos": Vector2i(41, 39), "floor": ["late_inn", -1], "always": true}],
		"pickup_vis": "s_ts_collect",
		"springs": [Vector2i(16, 47)],
		"roads": [[Vector2i(2, 30), Vector2i(14, 31), Vector2i(30, 29), Vector2i(46, 31), Vector2i(58, 30)], [Vector2i(30, 29), Vector2i(30, 17)]],
		# the great bronze cauldron in the casting yard below the hall
		"blocks": [Rect2i(36, 20, 5, 5)],
		"landmark": {"kind": "cauldron", "pos": Vector2i(38, 22)},
		"buildings": [
			{"id": "cauldron_hall", "n": "Hall of the Nine Cauldrons", "style": "hall", "rect": Rect2i(24, 8, 13, 9), "door": Vector2i(30, 16),
				"props": [["cauldron", Vector2i(27, 10), true], ["cauldron", Vector2i(30, 10), true], ["cauldron", Vector2i(33, 10), true], ["cauldron", Vector2i(27, 13), true], ["cauldron", Vector2i(33, 13), true], ["scroll", Vector2i(25, 14), false]]},
			{"id": "foundry", "n": "Tu Lan's Foundry", "style": "smithy", "rect": Rect2i(6, 18, 11, 8), "door": Vector2i(11, 25),
				"props": [["hearth", Vector2i(15, 19), true], ["anvil", Vector2i(13, 22), true], ["rack", Vector2i(7, 19), true], ["barrel", Vector2i(7, 23), false]]},
			{"id": "charcoal_lodge", "n": "Charcoal-Burner's Lodge", "style": "farmhouse", "rect": Rect2i(6, 36, 9, 6), "door": Vector2i(10, 36),
				"props": [["bed", Vector2i(7, 40), true], ["barrel", Vector2i(13, 40), true], ["stove", Vector2i(13, 37), true]]},
			{"id": "carver_shop", "n": "Stone-Carver Shi's Workshop", "style": "huizhou", "rect": Rect2i(20, 36, 9, 7), "door": Vector2i(24, 36),
				"props": [["table", Vector2i(22, 40), true], ["rack", Vector2i(27, 38), true], ["scroll", Vector2i(21, 38), false]]},
			{"id": "late_inn", "n": "Inn of the Late Arrival", "style": "inn", "rect": Rect2i(36, 35, 11, 7), "door": Vector2i(41, 35),
				"props": [["table", Vector2i(38, 38), true], ["stool", Vector2i(37, 38), false], ["counter", Vector2i(44, 37), true], ["barrel", Vector2i(45, 39), true], ["lantern", Vector2i(39, 40), false]],
				"down": Vector2i(45, 36), "cellar": {"n": "the wine cellar", "props": [["barrel", Vector2i(37, 37), true], ["barrel", Vector2i(37, 39), true], ["barrel", Vector2i(43, 40), true], ["shelf", Vector2i(45, 38), true], ["lantern", Vector2i(40, 37), false]]}},
			{"id": "bell_works", "n": "Wei's Bell Works", "style": "dorm", "rect": Rect2i(42, 20, 10, 7), "door": Vector2i(46, 26),
				"props": [["hearth", Vector2i(50, 21), true], ["rack", Vector2i(43, 21), true], ["anvil", Vector2i(49, 24), true]]},
		],
	},
	# the broken pillar of heaven in the far north-west, over a black lake that is listening
	"buzhou": {
		"n": "Mount Buzhou, the Broken Pillar", "w": 96, "h": 58, "seed": 421, "theme": "buzhou", "enemies": 20,
		"pool": [["flood_wolf", 44, 44], ["pillar_sentinel", 44, 44], ["kun_fry", 44, 44]],
		"portals": [
			{"to": "tushan", "pos": Vector2i(1, 29), "dest": Vector2i(90, 30), "open": ""},
		],
		"npcs": [{"id": "yinglong", "n": "Yinglong, Who Dug the Rivers", "pos": Vector2i(10, 35), "col": Color("2a5a6a")}],
		"bosses": [
			{"id": "xiu", "pos": Vector2i(28, 46), "lv": 44, "req": 44},
			{"id": "kun", "pos": Vector2i(44, 12), "lv": 44, "req": 44},
			{"id": "xiangliu", "pos": Vector2i(62, 44), "lv": 44, "req": 44},
			{"id": "kuafu", "pos": Vector2i(58, 8), "lv": 44, "req": 44},
			{"id": "gonggong", "pos": Vector2i(86, 29), "lv": 44, "req": 44},
			# Part XIII: a General of the Eight Gates
			{"id": "kui_drum", "pos": Vector2i(51, 39), "lv": 52, "req": 51, "vis": ["s_p13_gates", ""]},
		],
		# Part XIII: a war-band of the Eight Gates marches here once the formation wakes
		"warband": {"pool": [["bronze_brow", 51, 52], ["jiuli_warrior", 51, 52], ["fetter_sapling", 51, 52]], "n": 6, "vis": "s_p13_home"},
		"pickups": [{"id": "bstone1", "item": "pillar_stone", "pos": Vector2i(22, 12)}, {"id": "bstone2", "item": "pillar_stone", "pos": Vector2i(38, 34)}, {"id": "bstone3", "item": "pillar_stone", "pos": Vector2i(56, 20)}, {"id": "bstone4", "item": "pillar_stone", "pos": Vector2i(76, 48)}],
		"pickup_vis": "s_bz_collect",
		"springs": [Vector2i(48, 30)],
		"roads": [[Vector2i(2, 29), Vector2i(16, 28), Vector2i(34, 30), Vector2i(50, 27), Vector2i(66, 32), Vector2i(84, 29)]],
		# the stump of the pillar of heaven, broken off where Gonggong ran into it
		"blocks": [Rect2i(66, 16, 9, 9)],
		"landmark": {"kind": "buzhou", "pos": Vector2i(70, 20)},
		"buildings": [
			{"id": "dragon_shrine", "n": "Yinglong's Cave-Shrine", "style": "shrine", "rect": Rect2i(6, 32, 10, 7), "door": Vector2i(10, 32),
				"props": [["altar", Vector2i(9, 37), true], ["altar", Vector2i(10, 37), true], ["altar", Vector2i(11, 37), true], ["statue", Vector2i(10, 37), false], ["scroll", Vector2i(7, 34), false], ["lantern", Vector2i(14, 34), false]]},
		],
	},
	# ---- Part XI: The Ladder of Heaven.  Two realms of their own, built like the land (atlas.gd
	# STRATA): the Nine Heavens float above the clouds over the mountain, the Nine Springs lie under
	# its roots.  The Jianmu joins them to the Unbroken Land (LADDERS).
	# Juntian, the Level Heaven: islands in the sky round the crown of the Jianmu, the aerie-town of
	# the Feathered Folk and the Rain Ministry of the dragon-kin
	"juntian": {
		"n": "Juntian, the Level Heaven", "w": 100, "h": 64, "seed": 431, "theme": "juntian", "enemies": 22, "races": ["yumin", "dragon"], "layer": "heaven", "hill": 0.5,
		"pool": [["cloud_kite", 45, 45], ["thunder_mote", 45, 45], ["rain_serpent", 45, 45]],
		"portals": [
			{"to": "changhe", "pos": Vector2i(98, 32), "dest": Vector2i(4, 30), "open": "s_jt_leigong"},
		],
		"npcs": [
			{"id": "ao_xun", "n": "Rain-Clerk Ao Xun", "pos": Vector2i(41, 38), "col": Color("3a7a7a"), "race": "dragon"},
			{"id": "ling_fei", "n": "Ling Fei, Who Cannot Fly", "pos": Vector2i(37, 34), "col": Color("9ab0d8"), "race": "yumin"},
			{"id": "ling_yu_sky", "asset": "ling_yu", "n": "Ling Yu of the Feathered Folk", "pos": Vector2i(19, 30), "col": Color("8ac0e8"), "race": "yumin"},
			{"id": "yu_hua", "n": "Feather-Mother Yu Hua", "pos": Vector2i(35, 24), "col": Color("f0ece0"), "race": "yumin", "floor": ["aerie_tower", 1]},
			{"id": "yu_jian", "n": "Fletcher Yu Jian", "pos": Vector2i(48, 24), "col": Color("8a6a4a"), "race": "yumin"},
			{"id": "egg_warden_luan", "n": "Egg-Warden Luan", "pos": Vector2i(33, 40), "col": Color("a8a8b0"), "race": "yumin"},
			{"id": "que_er", "n": "Little Que'er", "pos": Vector2i(41, 34), "col": Color("a8783a"), "race": "yumin"},
			{"id": "ao_qing", "n": "Cloud-Scribe Ao Qing", "pos": Vector2i(65, 18), "col": Color("c8e8d8"), "race": "dragon"},
			{"id": "ao_run", "n": "Rain-Minister Ao Run", "pos": Vector2i(69, 17), "col": Color("2a6a6a"), "race": "dragon", "floor": ["rain_ministry", -1]},
		],
		"bosses": [
			{"id": "feilian", "pos": Vector2i(56, 47), "lv": 45, "req": 45},
			{"id": "kui", "pos": Vector2i(78, 46), "lv": 45, "req": 45},
			{"id": "grudge_kui", "pos": Vector2i(80, 47), "lv": 55, "req": 54, "vis": ["s_p14_grudges", ""]},
			{"id": "jiufeng", "pos": Vector2i(84, 15), "lv": 46, "req": 46},
			{"id": "leigong", "pos": Vector2i(90, 32), "lv": 46, "req": 46},
			# Part XIII: a General of the Eight Gates
			{"id": "yu_shi", "pos": Vector2i(62, 40), "lv": 52, "req": 51, "vis": ["s_p13_gates", ""]},
		],
		# Part XIII: a war-band of the Eight Gates marches here once the formation wakes
		"warband": {"pool": [["zhuolu_fog", 51, 52], ["jiuli_warrior", 51, 52], ["banner_ember", 51, 52]], "n": 6, "vis": "s_p13_home"},
		"pickups": [{"id": "wbell1", "item": "wind_bell", "pos": Vector2i(22, 14)}, {"id": "wbell2", "item": "wind_bell", "pos": Vector2i(48, 52)}, {"id": "wbell3", "item": "wind_bell", "pos": Vector2i(70, 30)}, {"id": "wbell4", "item": "wind_bell", "pos": Vector2i(86, 51)},
			{"id": "cur_wutong1", "item": "wutong_seed", "pos": Vector2i(50, 22), "floor": ["fletcher_loft", 1], "always": true},
			{"id": "cur_pearl1", "item": "night_pearl", "pos": Vector2i(72, 18), "floor": ["rain_ministry", -1], "always": true},
			{"id": "cache_jt1", "item": "stones", "n": 2600, "pos": Vector2i(34, 43), "floor": ["egg_nursery", -1], "always": true}],
		"pickup_vis": "s_jt_collect",
		"springs": [Vector2i(20, 44)],
		"steles": [Vector2i(42, 30)],
		"roads": [[Vector2i(13, 32), Vector2i(24, 33), Vector2i(34, 32), Vector2i(44, 31), Vector2i(56, 32), Vector2i(70, 33), Vector2i(84, 32), Vector2i(97, 32)], [Vector2i(35, 29), Vector2i(35, 32)], [Vector2i(35, 37), Vector2i(35, 33)], [Vector2i(48, 27), Vector2i(48, 31)], [Vector2i(68, 21), Vector2i(68, 31)]],
		# the crown of the Jianmu rises out of the clouds at the west end of the islands
		"blocks": [Rect2i(3, 28, 8, 9)],
		"landmark": {"kind": "jianmu_crown", "pos": Vector2i(7, 32)},
		"buildings": [
			{"id": "aerie_tower", "n": "The Aerie Tower of Featherfall", "style": "aerie", "rect": Rect2i(30, 20, 11, 9), "door": Vector2i(35, 28),
				"props": [["nest", Vector2i(39, 22), true], ["shelf", Vector2i(39, 26), true], ["cushion", Vector2i(35, 24), false], ["lantern", Vector2i(33, 26), false]],
				"up": Vector2i(32, 22), "upper": {"n": "the top of the Aerie Tower", "props": [["nest", Vector2i(39, 22), true], ["nest", Vector2i(39, 26), true], ["altar", Vector2i(35, 21), true], ["cushion", Vector2i(35, 23), false], ["lantern", Vector2i(31, 26), false]]}},
			{"id": "fletcher_loft", "n": "Yu Jian's Fletching Loft", "style": "shop", "rect": Rect2i(44, 20, 9, 7), "door": Vector2i(48, 26),
				"props": [["rack", Vector2i(51, 22), true], ["table", Vector2i(50, 24), true], ["barrel", Vector2i(45, 24), false]],
				"up": Vector2i(46, 22), "upper": {"n": "the feather loft", "props": [["rack", Vector2i(51, 22), true], ["bed", Vector2i(50, 24), true], ["shelf", Vector2i(45, 24), true], ["lantern", Vector2i(48, 23), false]]}},
			{"id": "egg_nursery", "n": "The Egg-Nursery", "style": "farmhouse", "rect": Rect2i(30, 38, 10, 7), "door": Vector2i(35, 38),
				"props": [["nest", Vector2i(31, 40), true], ["nest", Vector2i(31, 42), true], ["cushion", Vector2i(34, 41), false], ["lantern", Vector2i(36, 40), false]],
				"down": Vector2i(37, 42), "cellar": {"n": "the warm cellar under the nursery", "props": [["nest", Vector2i(31, 40), true], ["nest", Vector2i(31, 42), true], ["nest", Vector2i(36, 39), true], ["lantern", Vector2i(33, 40), false], ["barrel", Vector2i(38, 39), true]]}},
			{"id": "rain_ministry", "n": "The Rain Ministry", "style": "hall", "rect": Rect2i(62, 12, 13, 9), "door": Vector2i(68, 20),
				"props": [["altar", Vector2i(67, 13), true], ["altar", Vector2i(68, 13), true], ["altar", Vector2i(69, 13), true], ["statue", Vector2i(68, 13), false], ["desk", Vector2i(64, 15), true], ["scroll", Vector2i(63, 17), false], ["cushion", Vector2i(68, 17), false]],
				"down": Vector2i(72, 15), "cellar": {"n": "the Archive of Rain", "props": [["bookshelf", Vector2i(63, 14), true], ["bookshelf", Vector2i(63, 16), true], ["bookshelf", Vector2i(63, 18), true], ["desk", Vector2i(68, 15), true], ["scroll", Vector2i(70, 13), false], ["lantern", Vector2i(66, 18), false]]}},
		],
	},
	# Changhe, the Gate of Heaven: the high islands where the gate of the old Court still stands, kept
	# (and played tricks with) by the celestial foxes, and where Chong holds the sky up
	"changhe": {
		"n": "Changhe, the Gate of Heaven", "w": 92, "h": 60, "seed": 441, "theme": "changhe", "enemies": 22, "races": ["tianhu"], "layer": "heaven", "hill": 0.45,
		"pool": [["gate_lion", 45, 46], ["fox_wisp", 46, 46], ["cloud_soldier", 45, 46]],
		"portals": [
			{"to": "juntian", "pos": Vector2i(1, 30), "dest": Vector2i(94, 32), "open": ""},
		],
		"npcs": [
			{"id": "hu_xiao", "n": "Hu Xiao, a Fox of One Tail", "pos": Vector2i(32, 27), "col": Color("e0782a"), "race": "tianhu"},
			{"id": "hu_qingyi", "n": "Hu Qingyi, the Ninth-Tail Matron", "pos": Vector2i(24, 22), "col": Color("f0eef8"), "race": "tianhu", "floor": ["fox_pavilion", 1]},
			{"id": "hu_meier", "n": "Hu Mei'er of the Moon-Wine Shop", "pos": Vector2i(36, 19), "col": Color("e07a3a"), "race": "tianhu"},
			{"id": "gate_fox_hu", "n": "Old Hu the Gate-Fox", "pos": Vector2i(52, 34), "col": Color("6a6a70"), "race": "tianhu"},
		],
		"bosses": [
			{"id": "pixiu", "pos": Vector2i(52, 12), "lv": 46, "req": 46},
			{"id": "shentu", "pos": Vector2i(66, 22), "lv": 46, "req": 46},
			{"id": "yulei", "pos": Vector2i(66, 40), "lv": 46, "req": 46},
			{"id": "chong", "pos": Vector2i(77, 30), "lv": 46, "req": 46},
			# Part XIII: a General of the Eight Gates
			{"id": "xingtian", "pos": Vector2i(59, 17), "lv": 52, "req": 51, "vis": ["s_p13_gates", ""]},
		],
		# Part XIII: a war-band of the Eight Gates marches here once the formation wakes
		"warband": {"pool": [["jiuli_warrior", 51, 52], ["bronze_brow", 51, 52], ["zhuolu_fog", 51, 52]], "n": 6, "vis": "s_p13_home"},
		"pickups": [{"id": "gkey1", "item": "gate_key", "pos": Vector2i(12, 13)}, {"id": "gkey2", "item": "gate_key", "pos": Vector2i(40, 48)}, {"id": "gkey3", "item": "gate_key", "pos": Vector2i(60, 30)}, {"id": "gkey4", "item": "gate_key", "pos": Vector2i(72, 50)},
			{"id": "cur_wine1", "item": "peach_wine", "pos": Vector2i(39, 20), "floor": ["moonwine_shop", 1], "always": true},
			{"id": "cache_cg1", "item": "stones", "n": 2800, "pos": Vector2i(55, 40), "floor": ["gatehouse", -1], "always": true}],
		"pickup_vis": "s_cg_collect",
		"springs": [Vector2i(12, 44)],
		"steles": [Vector2i(30, 33)],
		"roads": [[Vector2i(2, 30), Vector2i(14, 31), Vector2i(28, 30), Vector2i(44, 29), Vector2i(58, 31), Vector2i(72, 30), Vector2i(80, 30)], [Vector2i(23, 25), Vector2i(23, 30)], [Vector2i(36, 23), Vector2i(36, 29)], [Vector2i(54, 35), Vector2i(54, 31)]],
		# the two towers of the Gate of Heaven, the way through them between
		"blocks": [Rect2i(81, 20, 6, 7), Rect2i(81, 34, 6, 7)],
		"landmark": {"kind": "changhe_gate", "pos": Vector2i(84, 30)},
		"buildings": [
			{"id": "fox_pavilion", "n": "Pavilion of the Moon-Foxes", "style": "teahouse", "rect": Rect2i(18, 16, 11, 9), "door": Vector2i(23, 24),
				"props": [["table", Vector2i(25, 19), true], ["stool", Vector2i(26, 19), false], ["cushion", Vector2i(23, 21), false], ["lantern", Vector2i(21, 22), false], ["scroll", Vector2i(27, 18), false]],
				"up": Vector2i(20, 18), "upper": {"n": "the moon terrace of the Pavilion", "props": [["table", Vector2i(25, 20), true], ["cushion", Vector2i(22, 20), false], ["lantern", Vector2i(19, 22), false], ["shelf", Vector2i(27, 22), true]]}},
			{"id": "moonwine_shop", "n": "The Moon-Wine Shop", "style": "shop", "rect": Rect2i(32, 16, 9, 7), "door": Vector2i(36, 22),
				"props": [["counter", Vector2i(36, 18), false], ["barrel", Vector2i(39, 18), true], ["barrel", Vector2i(39, 20), true], ["lantern", Vector2i(33, 20), false]],
				"up": Vector2i(33, 18), "upper": {"n": "the wine loft", "props": [["barrel", Vector2i(39, 18), true], ["bed", Vector2i(38, 21), true], ["lantern", Vector2i(35, 20), false]]}},
			{"id": "gatehouse", "n": "The Old Gatehouse of Changhe", "style": "dorm", "rect": Rect2i(50, 36, 9, 7), "door": Vector2i(54, 36),
				"props": [["rack", Vector2i(51, 38), true], ["table", Vector2i(54, 39), true], ["lantern", Vector2i(52, 41), false]],
				"down": Vector2i(57, 40), "cellar": {"n": "the gatehouse cellar", "props": [["barrel", Vector2i(51, 38), true], ["barrel", Vector2i(51, 40), true], ["shelf", Vector2i(53, 41), true], ["lantern", Vector2i(55, 38), false]]}},
		],
	},
	# The Nine Springs under the roots: caverns where the roots of the Jianmu drink, the black water of
	# the Pearl-Weepers' town and the groves of the Deathless
	"ninesprings": {
		"n": "The Nine Springs beneath the Roots", "w": 96, "h": 62, "seed": 451, "theme": "ninesprings", "enemies": 22, "races": ["jiaoren", "deathless"], "layer": "under", "hill": 0.6,
		"pool": [["root_worm", 46, 46], ["blindfish", 46, 46], ["glow_crab", 46, 46]],
		"portals": [
			{"to": "youdu", "pos": Vector2i(94, 30), "dest": Vector2i(4, 32), "open": "s_ns_zhulong"},
		],
		"npcs": [
			{"id": "bu_lin", "n": "Bu Lin the Fruit-Trader", "pos": Vector2i(35, 28), "col": Color("8a7a3a"), "race": "deathless"},
			{"id": "yao_silk", "n": "Silk-Diver Yao", "pos": Vector2i(38, 25), "col": Color("4ab0b0"), "race": "jiaoren"},
			{"id": "shui_lian", "n": "Pearl-Weaver Shui Lian", "pos": Vector2i(33, 16), "col": Color("6ac0b0"), "race": "jiaoren"},
			{"id": "hai_ge", "n": "Tide-Singer Hai Ge", "pos": Vector2i(48, 28), "col": Color("2a4a8a"), "race": "jiaoren"},
			{"id": "little_bei", "n": "Little Bei", "pos": Vector2i(40, 33), "col": Color("8ad0c8"), "race": "jiaoren"},
			{"id": "bu_si", "n": "Elder Bu Si of the Deathless", "pos": Vector2i(27, 42), "col": Color("b8a060"), "race": "deathless", "floor": ["root_house", 1]},
			{"id": "chang_sheng", "n": "Grove-Keeper Chang Sheng", "pos": Vector2i(20, 50), "col": Color("5a8a3a"), "race": "deathless"},
		],
		"bosses": [
			{"id": "root_wyrm", "pos": Vector2i(62, 12), "lv": 46, "req": 46},
			{"id": "pearl_mother", "pos": Vector2i(70, 27), "lv": 46, "req": 46},
			{"id": "wangxiang", "pos": Vector2i(78, 50), "lv": 47, "req": 47},
			{"id": "zhulong", "pos": Vector2i(88, 30), "lv": 47, "req": 47},
			# Part XIII: a General of the Eight Gates
			{"id": "liang", "pos": Vector2i(69, 16), "lv": 52, "req": 51, "vis": ["s_p13_gates", ""]},
		],
		# Part XIII: a war-band of the Eight Gates marches here once the formation wakes
		"warband": {"pool": [["zhuolu_fog", 51, 52], ["fetter_sapling", 51, 52], ["bronze_brow", 51, 52]], "n": 6, "vis": "s_p13_home"},
		"pickups": [{"id": "svial1", "item": "spring_water", "pos": Vector2i(16, 14)}, {"id": "svial2", "item": "spring_water", "pos": Vector2i(44, 54)}, {"id": "svial3", "item": "spring_water", "pos": Vector2i(80, 14)}, {"id": "svial4", "item": "spring_water", "pos": Vector2i(84, 46)},
			{"id": "cur_pearl2", "item": "night_pearl", "pos": Vector2i(38, 17), "floor": ["pearl_hall", -1], "always": true},
			{"id": "cur_lotus2", "item": "moon_lotus", "pos": Vector2i(46, 20), "floor": ["tide_house", 1], "always": true},
			{"id": "cache_ns1", "item": "stones", "n": 3000, "pos": Vector2i(29, 15), "floor": ["pearl_hall", -1], "always": true}],
		"pickup_vis": "s_ns_collect",
		"springs": [Vector2i(18, 22)],
		"steles": [Vector2i(42, 30)],
		"ponds": [[Vector2i(60, 42), 7]],
		"roads": [[Vector2i(12, 30), Vector2i(24, 31), Vector2i(38, 30), Vector2i(52, 29), Vector2i(66, 30), Vector2i(80, 31), Vector2i(93, 30)], [Vector2i(33, 20), Vector2i(33, 29)], [Vector2i(47, 22), Vector2i(47, 29)], [Vector2i(26, 37), Vector2i(26, 31)]],
		# the roots of the Jianmu come down out of the cavern roof at the west end
		"blocks": [Rect2i(2, 26, 8, 9)],
		"landmark": {"kind": "jianmu_roots", "pos": Vector2i(6, 30)},
		"buildings": [
			{"id": "pearl_hall", "n": "Hall of the Pearl-Weavers", "style": "hall", "rect": Rect2i(28, 12, 12, 8), "door": Vector2i(33, 19),
				"props": [["loom", Vector2i(30, 14), true], ["loom", Vector2i(36, 14), true], ["shelf", Vector2i(29, 17), true], ["lantern", Vector2i(35, 17), false]],
				"down": Vector2i(38, 15), "cellar": {"n": "the pearl vault", "props": [["cabinet", Vector2i(29, 13), true], ["cabinet", Vector2i(31, 13), true], ["barrel", Vector2i(36, 18), true], ["lantern", Vector2i(33, 16), false]]}},
			{"id": "tide_house", "n": "The Tide-Singer's House", "style": "house", "rect": Rect2i(44, 16, 8, 6), "door": Vector2i(47, 21),
				"props": [["bed", Vector2i(50, 18), true], ["stove", Vector2i(45, 19), true], ["lantern", Vector2i(49, 20), false]],
				"up": Vector2i(45, 17), "upper": {"n": "the singing room", "props": [["bed", Vector2i(50, 18), true], ["cushion", Vector2i(48, 19), false], ["lantern", Vector2i(46, 20), false]]}},
			{"id": "root_house", "n": "The House under the Great Root", "style": "farmhouse", "rect": Rect2i(22, 38, 10, 8), "door": Vector2i(26, 38),
				"props": [["table", Vector2i(25, 41), true], ["stove", Vector2i(23, 43), true], ["herbs", Vector2i(30, 43), false]],
				"up": Vector2i(29, 40), "upper": {"n": "the loft under the great root", "props": [["bed", Vector2i(23, 40), true], ["cushion", Vector2i(26, 42), false], ["herbs", Vector2i(30, 43), false], ["lantern", Vector2i(24, 43), false]]}},
		],
	},
	# Youdu, the Dark Capital: the city of the shades under Sovereign Earth, Tubo at its gate and, in
	# the deep beyond, Li pressing the earth down
	"youdu": {
		"n": "Youdu, the Dark Capital", "w": 100, "h": 64, "seed": 461, "theme": "youdu", "enemies": 22, "races": ["shade"], "layer": "under", "hill": 0.35,
		"pool": [["ghost_soldier", 47, 47], ["paper_horse", 47, 47], ["lantern_shade", 47, 47]],
		"portals": [
			{"to": "ninesprings", "pos": Vector2i(1, 32), "dest": Vector2i(90, 30), "open": ""},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "xu_lan_youdu", "n": "Xu Lan", "pos": Vector2i(33, 33), "col": Color("7a1a2a"), "asset": "xu_lan", "fate": true},
			{"id": "lamplighter_bo", "n": "Old Bo the Lamplighter", "pos": Vector2i(35, 34), "col": Color("6a6a7a"), "race": "shade"},
			{"id": "roll_clerk_ning", "n": "Roll-Clerk Ning", "pos": Vector2i(43, 36), "col": Color("4a4a5a"), "race": "shade"},
			{"id": "ming_yi", "n": "Lantern-Magistrate Ming Yi", "pos": Vector2i(28, 20), "col": Color("2a2a3a"), "race": "shade", "floor": ["ward_office", 1]},
			{"id": "zhi_ma", "n": "Zhi Ma the Paper-Horse Maker", "pos": Vector2i(43, 20), "col": Color("f0f0f0"), "race": "shade"},
			{"id": "shade_lan", "n": "Little Lan, Who Lost Her Way", "pos": Vector2i(47, 30), "col": Color("c8d8e8"), "race": "shade"},
			{"id": "houtu", "n": "Houtu, Sovereign Earth", "pos": Vector2i(36, 43), "col": Color("8a6a3a"), "floor": ["earth_palace", -1]},
		],
		"bosses": [
			{"id": "bai_wuchang", "pos": Vector2i(60, 12), "lv": 47, "req": 47},
			{"id": "hei_wuchang", "pos": Vector2i(62, 54), "lv": 47, "req": 47},
			{"id": "tubo", "pos": Vector2i(70, 32), "lv": 47, "req": 47},
			{"id": "li", "pos": Vector2i(90, 32), "lv": 47, "req": 47},
			# Part XIII: a General of the Eight Gates
			{"id": "bronze_brothers", "pos": Vector2i(55, 53), "lv": 52, "req": 51, "vis": ["s_p13_gates", ""]},
		],
		# Part XIII: a war-band of the Eight Gates marches here once the formation wakes
		"warband": {"pool": [["bronze_brow", 51, 52], ["jiuli_warrior", 51, 52], ["banner_ember", 51, 52]], "n": 6, "vis": "s_p13_home"},
		"pickups": [{"id": "stally1", "item": "soul_tally", "pos": Vector2i(14, 12)}, {"id": "stally2", "item": "soul_tally", "pos": Vector2i(20, 54)}, {"id": "stally3", "item": "soul_tally", "pos": Vector2i(64, 22)}, {"id": "stally4", "item": "soul_tally", "pos": Vector2i(86, 50)},
			{"id": "cur_incense2", "item": "ancestor_incense", "pos": Vector2i(40, 21), "floor": ["paper_shop", -1], "always": true},
			{"id": "cur_leaf2", "item": "autumn_leaf", "pos": Vector2i(58, 40), "floor": ["ghost_inn", 1], "always": true},
			{"id": "cache_yd1", "item": "stones", "n": 3200, "pos": Vector2i(32, 40), "floor": ["earth_palace", -1], "always": true}],
		"pickup_vis": "s_yd_collect",
		"springs": [Vector2i(16, 44)],
		"steles": [Vector2i(46, 34)],
		"roads": [[Vector2i(2, 32), Vector2i(16, 33), Vector2i(30, 32), Vector2i(46, 31), Vector2i(60, 33), Vector2i(72, 32), Vector2i(84, 32), Vector2i(94, 32)], [Vector2i(29, 24), Vector2i(29, 31)], [Vector2i(42, 23), Vector2i(42, 30)], [Vector2i(36, 37), Vector2i(36, 33)], [Vector2i(54, 37), Vector2i(54, 33)]],
		# the two towers of the inner gate, the way through them between
		"blocks": [Rect2i(74, 22, 5, 7), Rect2i(74, 37, 5, 7)],
		"landmark": {"kind": "youdu_gate", "pos": Vector2i(76, 32)},
		"buildings": [
			{"id": "ward_office", "n": "Ward Office of the Dark Capital", "style": "huizhou", "rect": Rect2i(24, 16, 11, 8), "door": Vector2i(29, 23),
				"props": [["desk", Vector2i(31, 18), true], ["shelf", Vector2i(33, 20), true], ["scroll", Vector2i(25, 21), false], ["lantern", Vector2i(28, 21), false]],
				"up": Vector2i(26, 18), "upper": {"n": "the magistrate's upper room", "props": [["desk", Vector2i(31, 18), true], ["bookshelf", Vector2i(33, 20), true], ["lantern", Vector2i(25, 21), false], ["cushion", Vector2i(29, 21), false]]}},
			{"id": "paper_shop", "n": "Zhi Ma's Paper-Horse Shop", "style": "shop", "rect": Rect2i(38, 16, 9, 7), "door": Vector2i(42, 22),
				"props": [["counter", Vector2i(41, 18), false], ["shelf", Vector2i(39, 20), true], ["lantern", Vector2i(44, 20), false]],
				"down": Vector2i(45, 18), "cellar": {"n": "the paper store", "props": [["shelf", Vector2i(39, 18), true], ["shelf", Vector2i(39, 20), true], ["barrel", Vector2i(44, 21), true], ["lantern", Vector2i(42, 19), false]]}},
			{"id": "earth_palace", "n": "Palace of Sovereign Earth", "style": "hall", "rect": Rect2i(30, 38, 14, 9), "door": Vector2i(36, 38),
				"props": [["altar", Vector2i(35, 45), true], ["altar", Vector2i(36, 45), true], ["altar", Vector2i(37, 45), true], ["statue", Vector2i(36, 45), false], ["cushion", Vector2i(36, 42), false], ["scroll", Vector2i(31, 41), false]],
				"down": Vector2i(41, 44), "cellar": {"n": "the deep hall of Sovereign Earth", "props": [["altar", Vector2i(35, 45), true], ["altar", Vector2i(36, 45), true], ["altar", Vector2i(37, 45), true], ["cushion", Vector2i(34, 42), false], ["lantern", Vector2i(32, 42), false], ["lantern", Vector2i(40, 41), false]]}},
			{"id": "ghost_inn", "n": "Inn of the Last Lantern", "style": "inn", "rect": Rect2i(50, 38, 10, 7), "door": Vector2i(54, 38),
				"props": [["table", Vector2i(52, 40), true], ["stool", Vector2i(53, 40), false], ["counter", Vector2i(56, 42), true], ["lantern", Vector2i(52, 42), false]],
				"up": Vector2i(57, 40), "upper": {"n": "the lodgings for wandering shades", "props": [["bed", Vector2i(51, 40), true], ["bed", Vector2i(51, 42), true], ["bed", Vector2i(57, 42), true], ["lantern", Vector2i(54, 41), false]]}},
		],
	},
	# ---- Part XII: The Returning Ruins.  A fourth realm (atlas.gd STRATA "sea"): the Isles of the
	# Eastern Sea, out past the edge of the shelf where the sea still is, running east like a river
	# into Guixu.  Mazu's boat joins them to the pool of the suns at Fusang (LADDERS).
	# Penglai: the Isle of the Immortals, hidden in a mirage for two thousand years, and Landfall, the
	# town of the Thousand Children Xu Fu brought from Qin and never came back for
	"penglai": {
		"n": "Penglai, the Isle of the Immortals", "w": 100, "h": 64, "seed": 471, "theme": "penglai", "enemies": 22, "races": ["qianzi", "xian"], "layer": "sea", "hill": 0.45,
		"pool": [["mirage_wisp", 48, 48], ["stranded_shark", 48, 48], ["sand_crab", 48, 48]],
		"portals": [
			{"to": "fangzhang", "pos": Vector2i(98, 32), "dest": Vector2i(4, 30), "open": "s_pl_longbo"},
		],
		"npcs": [
			{"id": "xu_qian", "n": "Headwoman Xu Qian of Landfall", "pos": Vector2i(34, 22), "col": Color("3a5a8a"), "race": "qianzi"},
			{"id": "teacher_qin", "n": "Teacher Qin of the Thousand Names", "pos": Vector2i(38, 24), "col": Color("6a4a3a"), "race": "qianzi"},
			{"id": "lu_dongbin", "n": "Lu Dongbin, the Sword Immortal", "pos": Vector2i(50, 23), "col": Color("e8e4d8"), "race": "xian", "floor": ["drunk_immortal", 1]},
			{"id": "li_tieguai", "n": "Iron-Crutch Li", "pos": Vector2i(41, 30), "col": Color("6a5a4a"), "race": "xian"},
			{"id": "lan_caihe", "n": "Lan Caihe, Who Sings in the Street", "pos": Vector2i(56, 34), "col": Color("6ab0e0"), "race": "xian"},
			{"id": "han_xiangzi", "n": "Han Xiangzi of the Jade Flute", "pos": Vector2i(24, 35), "col": Color("8ac080"), "race": "xian"},
			{"id": "shipwright_ban", "n": "Shipwright Ban", "pos": Vector2i(42, 46), "col": Color("8a5a3a"), "race": "qianzi"},
			{"id": "ah_shui", "n": "Net-Mender Ah Shui", "pos": Vector2i(52, 36), "col": Color("4a7a8a"), "race": "qianzi"},
			{"id": "little_haibao", "n": "Little Haibao", "pos": Vector2i(45, 35), "col": Color("e0a050"), "race": "qianzi"},
			{"id": "pilot_zheng", "n": "Old Pilot Zheng", "pos": Vector2i(17, 28), "col": Color("5a5a6a"), "race": "qianzi"},
			{"id": "diver_yulan", "n": "Pearl-Diver Yu Lan", "pos": Vector2i(66, 36), "col": Color("2a8aa0"), "race": "qianzi"},
			# after the Returning Ruins: Xu Fu comes home to the children he left (Part XII's last scene)
			{"id": "xu_fu_home", "n": "Xu Fu, Who Came Back", "pos": Vector2i(31, 30), "col": Color("8a7a9a"), "race": "qianzi", "vis": ["s_p12_end", ""]},
		],
		"bosses": [
			{"id": "qianliyan", "pos": Vector2i(56, 47), "lv": 48, "req": 48},
			{"id": "shunfenger", "pos": Vector2i(78, 46), "lv": 48, "req": 48},
			{"id": "sea_monk", "pos": Vector2i(84, 15), "lv": 48, "req": 48},
			{"id": "longbo_giant", "pos": Vector2i(90, 32), "lv": 49, "req": 49},
		],
		"pickups": [{"id": "nslip1", "item": "name_slip", "pos": Vector2i(22, 13)}, {"id": "nslip2", "item": "name_slip", "pos": Vector2i(46, 53)}, {"id": "nslip3", "item": "name_slip", "pos": Vector2i(72, 26)}, {"id": "nslip4", "item": "name_slip", "pos": Vector2i(86, 52)},
			{"id": "cur_soil1", "item": "mainland_earth", "pos": Vector2i(38, 41), "floor": ["shipyard", -1], "always": true},
			{"id": "cur_tea1", "item": "cloud_tea", "pos": Vector2i(52, 22), "floor": ["drunk_immortal", 1], "always": true},
			{"id": "cache_pl1", "item": "stones", "n": 3400, "pos": Vector2i(30, 20), "floor": ["names_hall", 1], "always": true},
			# a cache the Thousand Children forgot they hid: only Spirit Sense can feel it
			{"id": "sense_pl1", "item": "stones", "n": 2400, "pos": Vector2i(12, 50), "always": true, "sense": true}],
		"pickup_vis": "s_pl_collect",
		"springs": [Vector2i(20, 44)],
		"steles": [Vector2i(42, 30)],
		"roads": [[Vector2i(13, 32), Vector2i(24, 33), Vector2i(34, 32), Vector2i(44, 31), Vector2i(56, 32), Vector2i(70, 33), Vector2i(84, 32), Vector2i(97, 32)], [Vector2i(34, 27), Vector2i(34, 32)], [Vector2i(48, 27), Vector2i(48, 31)], [Vector2i(62, 29), Vector2i(62, 32)], [Vector2i(35, 37), Vector2i(35, 33)], [Vector2i(49, 37), Vector2i(49, 33)]],
		# the Pavilion of Penglai on its sea-cliff at the west end, where Mazu's boat comes in
		"blocks": [Rect2i(3, 22, 7, 7)],
		"landmark": {"kind": "penglai_pavilion", "pos": Vector2i(6, 25)},
		"buildings": [
			{"id": "names_hall", "n": "Hall of the Thousand Names", "style": "hall", "rect": Rect2i(28, 18, 13, 9), "door": Vector2i(34, 26),
				"props": [["altar", Vector2i(33, 19), true], ["altar", Vector2i(34, 19), true], ["altar", Vector2i(35, 19), true], ["scroll", Vector2i(29, 21), false], ["scroll", Vector2i(39, 21), false], ["cushion", Vector2i(31, 23), false], ["lantern", Vector2i(37, 24), false]],
				"up": Vector2i(30, 20), "upper": {"n": "the gallery of the Thousand Names", "props": [["bookshelf", Vector2i(33, 19), true], ["bookshelf", Vector2i(35, 19), true], ["desk", Vector2i(37, 22), true], ["scroll", Vector2i(39, 24), false], ["lantern", Vector2i(31, 24), false]]}},
			{"id": "drunk_immortal", "n": "Wine-House of the Drunken Immortal", "style": "inn", "rect": Rect2i(44, 19, 10, 8), "door": Vector2i(48, 26),
				"props": [["table", Vector2i(46, 22), true], ["stool", Vector2i(47, 22), false], ["counter", Vector2i(51, 21), true], ["barrel", Vector2i(52, 24), true], ["lantern", Vector2i(45, 24), false]],
				"up": Vector2i(45, 20), "upper": {"n": "the immortal's drinking-room", "props": [["table", Vector2i(50, 21), true], ["cushion", Vector2i(48, 23), false], ["barrel", Vector2i(52, 24), true], ["lantern", Vector2i(46, 24), false]]}},
			{"id": "mazu_temple", "n": "Temple of Mazu, Who Brings the Boats Home", "style": "shrine", "rect": Rect2i(58, 21, 9, 8), "door": Vector2i(62, 28),
				"props": [["altar", Vector2i(61, 22), true], ["altar", Vector2i(62, 22), true], ["altar", Vector2i(63, 22), true], ["statue", Vector2i(62, 22), false], ["lantern", Vector2i(59, 25), false], ["lantern", Vector2i(65, 25), false]]},
			{"id": "shipyard", "n": "Ban's Shipyard on the Sand", "style": "farmhouse", "rect": Rect2i(30, 38, 11, 7), "door": Vector2i(35, 38),
				"props": [["rack", Vector2i(31, 40), true], ["barrel", Vector2i(31, 43), true], ["table", Vector2i(37, 41), true], ["lantern", Vector2i(34, 43), false]],
				"down": Vector2i(39, 43), "cellar": {"n": "the rope store", "props": [["barrel", Vector2i(31, 40), true], ["barrel", Vector2i(31, 42), true], ["shelf", Vector2i(35, 43), true], ["lantern", Vector2i(36, 40), false]]}},
			{"id": "net_house", "n": "The Net-Menders' House", "style": "seahouse", "rect": Rect2i(46, 38, 8, 6), "door": Vector2i(49, 38),
				"props": [["loom", Vector2i(47, 41), true], ["bed", Vector2i(52, 41), true], ["lantern", Vector2i(50, 42), false]]},
		],
	},
	# Fangzhang, the Square-Pot Isle: the immortals' gardens and elixir furnaces, and the pearl trees
	# that drink from the Returning Ruins and are dying as the sea drains
	"fangzhang": {
		"n": "Fangzhang, the Square-Pot Isle", "w": 92, "h": 60, "seed": 481, "theme": "fangzhang", "enemies": 22, "races": ["xian"], "layer": "sea", "hill": 0.6,
		"pool": [["cinnabar_toad", 49, 49], ["elixir_crane", 49, 49], ["herb_rabbit", 49, 49]],
		"portals": [
			{"to": "penglai", "pos": Vector2i(1, 30), "dest": Vector2i(94, 32), "open": ""},
			{"to": "yingzhou", "pos": Vector2i(90, 30), "dest": Vector2i(4, 31), "open": "s_fz_tianwu"},
		],
		"npcs": [
			# a fated encounter (fate.gd): there while the story has them there
			{"id": "liu_ying_isle", "n": "Liu Ying", "pos": Vector2i(32, 34), "col": Color("6a7a5a"), "asset": "liu_ying", "fate": true},
			{"id": "he_xiangu", "n": "He Xiangu of the Lotus", "pos": Vector2i(24, 21), "col": Color("f0c8d8"), "race": "xian", "floor": ["lotus_hall", 1]},
			{"id": "zhang_guolao", "n": "Zhang Guolao, Who Rides Backwards", "pos": Vector2i(38, 18), "col": Color("8a8a7a"), "race": "xian", "floor": ["furnace_house", -1]},
			{"id": "zhongli_quan", "n": "Zhongli Quan of the Fan", "pos": Vector2i(30, 33), "col": Color("c84a2a"), "race": "xian"},
			{"id": "cao_guojiu", "n": "Cao Guojiu, the Court Official Who Resigned", "pos": Vector2i(46, 34), "col": Color("3a3a6a"), "race": "xian"},
			{"id": "furnace_boy", "n": "Furnace-Boy Dan", "pos": Vector2i(40, 27), "col": Color("c87a3a"), "race": "qianzi"},
		],
		"bosses": [
			{"id": "longevity_deer", "pos": Vector2i(52, 12), "lv": 49, "req": 49},
			{"id": "elixir_furnace", "pos": Vector2i(66, 22), "lv": 49, "req": 49},
			{"id": "pearl_tree", "pos": Vector2i(66, 40), "lv": 49, "req": 49},
			{"id": "tianwu", "pos": Vector2i(77, 30), "lv": 49, "req": 49},
		],
		"pickups": [{"id": "pdew1", "item": "pearl_dew", "pos": Vector2i(12, 13)}, {"id": "pdew2", "item": "pearl_dew", "pos": Vector2i(40, 48)}, {"id": "pdew3", "item": "pearl_dew", "pos": Vector2i(58, 30)}, {"id": "pdew4", "item": "pearl_dew", "pos": Vector2i(72, 50)},
			{"id": "cur_soil2", "item": "mainland_earth", "pos": Vector2i(26, 20), "floor": ["lotus_hall", 1], "always": true},
			{"id": "cache_fz1", "item": "stones", "n": 3600, "pos": Vector2i(36, 20), "floor": ["furnace_house", -1], "always": true},
			{"id": "sense_fz1", "item": "stones", "n": 2600, "pos": Vector2i(84, 10), "always": true, "sense": true}],
		"pickup_vis": "s_fz_collect",
		"springs": [Vector2i(12, 44)],
		"steles": [Vector2i(30, 30)],
		"roads": [[Vector2i(2, 30), Vector2i(14, 31), Vector2i(28, 30), Vector2i(44, 29), Vector2i(58, 31), Vector2i(72, 30), Vector2i(89, 30)], [Vector2i(23, 25), Vector2i(23, 30)], [Vector2i(38, 24), Vector2i(38, 29)], [Vector2i(54, 35), Vector2i(54, 31)]],
		"buildings": [
			{"id": "lotus_hall", "n": "He Xiangu's Lotus Hall", "style": "teahouse", "rect": Rect2i(18, 16, 11, 9), "door": Vector2i(23, 24),
				"props": [["table", Vector2i(25, 19), true], ["stool", Vector2i(26, 19), false], ["cushion", Vector2i(23, 21), false], ["herbs", Vector2i(20, 22), false], ["lantern", Vector2i(21, 18), false]],
				"up": Vector2i(20, 18), "upper": {"n": "the lotus terrace", "props": [["table", Vector2i(25, 20), true], ["cushion", Vector2i(22, 20), false], ["herbs", Vector2i(27, 22), false], ["lantern", Vector2i(19, 22), false]]}},
			{"id": "furnace_house", "n": "The House of the Nine Furnaces", "style": "alchemist", "rect": Rect2i(33, 16, 10, 8), "door": Vector2i(38, 23),
				"props": [["cauldron", Vector2i(35, 18), true], ["cauldron", Vector2i(41, 18), true], ["shelf", Vector2i(34, 21), true], ["herbs", Vector2i(40, 21), false]],
				"down": Vector2i(41, 21), "cellar": {"n": "the cellar of cold furnaces", "props": [["cauldron", Vector2i(35, 18), true], ["cauldron", Vector2i(35, 21), true], ["cabinet", Vector2i(40, 18), true], ["lantern", Vector2i(38, 21), false]]}},
			{"id": "herb_lodge", "n": "The Herb-Keepers' Lodge", "style": "house", "rect": Rect2i(50, 36, 9, 7), "door": Vector2i(54, 36),
				"props": [["herbs", Vector2i(51, 38), false], ["table", Vector2i(54, 39), true], ["bed", Vector2i(57, 41), true], ["lantern", Vector2i(52, 41), false]]},
		],
	},
	# Yingzhou, the Isle of Mists: the turtles' isle, where Jingwei has carried stones to the sea for
	# four thousand years and Yu Qiang keeps the turtles' shifts
	"yingzhou": {
		"n": "Yingzhou, the Isle of Mists", "w": 96, "h": 62, "seed": 491, "theme": "yingzhou", "enemies": 22, "races": [], "layer": "sea", "hill": 0.7,
		"pool": [["mist_phantom", 49, 50], ["bore_horse", 49, 50], ["shell_soldier", 49, 50]],
		"portals": [
			{"to": "fangzhang", "pos": Vector2i(1, 31), "dest": Vector2i(88, 30), "open": ""},
			{"to": "guixu", "pos": Vector2i(94, 31), "dest": Vector2i(4, 32), "open": "s_yz_yuqiang"},
		],
		"npcs": [
			{"id": "jingwei", "n": "Jingwei, the Flame Emperor's Daughter", "pos": Vector2i(33, 17), "col": Color("e05a3a")},
			{"id": "gui_lao", "n": "Old Gui, Herald of the Turtles", "pos": Vector2i(47, 22), "col": Color("5a7a5a"), "floor": ["turtle_shrine", 1]},
			{"id": "mist_fisher", "n": "Mist-Fisher Lao Wu", "pos": Vector2i(26, 37), "col": Color("6a7a8a"), "race": "qianzi"},
		],
		"bosses": [
			{"id": "wu_zixu", "pos": Vector2i(62, 12), "lv": 49, "req": 49},
			{"id": "shen", "pos": Vector2i(70, 27), "lv": 50, "req": 50},
			{"id": "great_ao", "pos": Vector2i(78, 50), "lv": 50, "req": 50},
			{"id": "yu_qiang", "pos": Vector2i(88, 31), "lv": 50, "req": 50},
			# Part XIII: a General of the Eight Gates
			{"id": "red_banner", "pos": Vector2i(71, 14), "lv": 52, "req": 51, "vis": ["s_p13_gates", ""]},
		],
		# Part XIII: a war-band of the Eight Gates marches here once the formation wakes
		"warband": {"pool": [["banner_ember", 51, 52], ["zhuolu_fog", 51, 52], ["jiuli_warrior", 51, 52]], "n": 6, "vis": "s_p13_home"},
		"pickups": [{"id": "jstone1", "item": "jingwei_stone", "pos": Vector2i(16, 14)}, {"id": "jstone2", "item": "jingwei_stone", "pos": Vector2i(44, 54)}, {"id": "jstone3", "item": "jingwei_stone", "pos": Vector2i(80, 14)}, {"id": "jstone4", "item": "jingwei_stone", "pos": Vector2i(84, 44)},
			{"id": "cur_tea2", "item": "cloud_tea", "pos": Vector2i(45, 24), "floor": ["turtle_shrine", 1], "always": true},
			{"id": "sense_yz1", "item": "stones", "n": 2800, "pos": Vector2i(10, 52), "always": true, "sense": true}],
		"pickup_vis": "s_yz_collect",
		"springs": [Vector2i(18, 22)],
		"steles": [Vector2i(42, 31)],
		"ponds": [[Vector2i(60, 42), 7]],
		"roads": [[Vector2i(2, 31), Vector2i(14, 32), Vector2i(26, 31), Vector2i(38, 30), Vector2i(52, 31), Vector2i(66, 31), Vector2i(80, 32), Vector2i(93, 31)], [Vector2i(47, 26), Vector2i(47, 30)], [Vector2i(33, 20), Vector2i(33, 30)]],
		"buildings": [
			{"id": "turtle_shrine", "n": "Shrine of the Fifteen Turtles", "style": "shrine", "rect": Rect2i(42, 18, 10, 8), "door": Vector2i(47, 25),
				"props": [["altar", Vector2i(46, 19), true], ["altar", Vector2i(47, 19), true], ["altar", Vector2i(48, 19), true], ["statue", Vector2i(47, 19), false], ["cushion", Vector2i(47, 22), false], ["lantern", Vector2i(44, 23), false]],
				"up": Vector2i(43, 20), "upper": {"n": "the tally-room of the turtles' shifts", "props": [["bookshelf", Vector2i(46, 19), true], ["desk", Vector2i(49, 21), true], ["scroll", Vector2i(44, 23), false], ["lantern", Vector2i(50, 23), false]]}},
		],
	},
	# Guixu, the Returning Ruins: the rim of the ravine without a bottom, the sea floor left bare by
	# the drain, the wrecks of Xu Fu's lost fleet and the drowned summits of Daiyu and Yuanqiao
	"guixu": {
		"n": "Guixu, the Returning Ruins", "w": 100, "h": 64, "seed": 501, "theme": "guixu", "enemies": 22, "races": [], "layer": "sea", "hill": 0.55,
		"pool": [["drowned_sailor", 50, 50], ["abyss_eel", 50, 50], ["ruin_sentinel", 50, 50]],
		"portals": [
			{"to": "yingzhou", "pos": Vector2i(1, 32), "dest": Vector2i(90, 31), "open": ""},
		],
		"npcs": [
			{"id": "steersman_hong", "n": "Steersman Hong of the Lost Fleet", "pos": Vector2i(28, 22), "col": Color("8a9aa8"), "floor": ["wreck_house", 1]},
			{"id": "ship_boy_ah_fu", "n": "Ah Fu, the Ship's Boy Who Never Grew Up", "pos": Vector2i(40, 34), "col": Color("a8b8c0")},
		],
		"bosses": [
			{"id": "drowned_admiral", "pos": Vector2i(60, 12), "lv": 50, "req": 50},
			{"id": "grudge_admiral", "pos": Vector2i(62, 13), "lv": 55, "req": 54, "vis": ["s_p14_grudges", ""]},
			{"id": "guixu_stopper", "pos": Vector2i(62, 54), "lv": 50, "req": 50},
			{"id": "hai_ruo", "pos": Vector2i(70, 32), "lv": 50, "req": 50},
			{"id": "xu_fu", "pos": Vector2i(86, 32), "lv": 50, "req": 50},
			# Part XIII: a General of the Eight Gates
			{"id": "mast_goblin", "pos": Vector2i(44, 17), "lv": 52, "req": 51, "vis": ["s_p13_gates", ""]},
		],
		# Part XIII: a war-band of the Eight Gates marches here once the formation wakes
		"warband": {"pool": [["fetter_sapling", 51, 52], ["zhuolu_fog", 51, 52], ["bronze_brow", 51, 52]], "n": 6, "vis": "s_p13_home"},
		"pickups": [{"id": "xlog1", "item": "xufu_log", "pos": Vector2i(14, 12)}, {"id": "xlog2", "item": "xufu_log", "pos": Vector2i(20, 54)}, {"id": "xlog3", "item": "xufu_log", "pos": Vector2i(64, 22)}, {"id": "xlog4", "item": "xufu_log", "pos": Vector2i(80, 50)},
			{"id": "cache_gx1", "item": "stones", "n": 3800, "pos": Vector2i(30, 20), "floor": ["wreck_house", 1], "always": true},
			{"id": "sense_gx1", "item": "stones", "n": 3000, "pos": Vector2i(52, 58), "always": true, "sense": true}],
		"pickup_vis": "s_gx_collect",
		"springs": [Vector2i(16, 44)],
		"steles": [Vector2i(46, 34)],
		"roads": [[Vector2i(2, 32), Vector2i(16, 33), Vector2i(30, 32), Vector2i(46, 31), Vector2i(60, 33), Vector2i(72, 32), Vector2i(82, 32)], [Vector2i(28, 27), Vector2i(28, 31)]],
		# the lip of the Returning Ruins at the east end: the sea pours over it into the dark
		"blocks": [Rect2i(90, 24, 8, 17)],
		"landmark": {"kind": "guixu_whirl", "pos": Vector2i(94, 32)},
		"buildings": [
			{"id": "wreck_house", "n": "The Wreck of the Flagship Penglai-Seeker", "style": "seahouse", "rect": Rect2i(23, 18, 11, 9), "door": Vector2i(28, 26),
				"props": [["barrel", Vector2i(24, 20), true], ["barrel", Vector2i(24, 22), true], ["table", Vector2i(30, 21), true], ["lantern", Vector2i(27, 24), false]],
				"up": Vector2i(32, 19), "upper": {"n": "the steersman's cabin", "props": [["desk", Vector2i(26, 20), true], ["bed", Vector2i(24, 23), true], ["shelf", Vector2i(31, 23), true], ["lantern", Vector2i(28, 23), false]]}},
		],
	},
}

const AREA_CHAIN := ["sect", "bamboo", "marsh", "frost", "thunder", "palace", "dragon", "volcano", "void", "celestial", "mirror", "grave", "time", "origin", "cloudsea", "court", "forge", "garden", "dunes", "fungal", "aurora", "chaos", "maple", "karst", "springs", "wheel", "village", "terraces", "silk", "loom", "starferry", "magpie", "starpalace", "jasper", "yanggu", "millet", "fusang", "guanghan", "longmen", "drowned", "tushan", "buzhou", "juntian", "changhe", "ninesprings", "youdu", "penglai", "fangzhang", "yingzhou", "guixu"]

## The towns of the Unbroken Land, marked on the world map: the area they stand in, a tile of that
## area's own map at their heart, and what they are.
const TOWNS := [
	{"id": "cloudfoot", "n": "Cloudfoot", "area": "mountain", "pos": Vector2i(82, 34),
		"lore": "The post town at the foot of Azure Cloud Mountain, where the north road leaves for the river. Couriers from all nine roads change horses here, caravans rest in the Caravanserai of the Four Roads, Old Wu tells the same stories every week to the same delighted people, and Cartographer Pei has been redrawing the world in his House of Maps since long before anyone agreed with him."},
	{"id": "qingshi", "n": "Qingshi Village", "area": "village", "pos": Vector2i(30, 28),
		"lore": "The village of green stone below the mountain, where Granny Wen raised an orphan who would grow up to sweep the sect's steps. Rice terraces, a tofu shop, an inn and a shrine to the Earth God; the threads that the Weaver sewed across its roofs are still being picked out of the thatch."},
	{"id": "yanggu", "n": "Yanggu Market", "area": "yanggu", "pos": Vector2i(34, 30),
		"lore": "The Dawn Market, the last town on the pilgrims' road east to the Valley of Sunrise. Its lantern-makers, dyers, tea sellers and watchmen lived through nine days of noon; now the Lantern Dragon leads the festival down the main street every night the moon is full."},
	{"id": "shazhou", "n": "Shazhou Oasis", "area": "dunes", "pos": Vector2i(12, 40),
		"lore": "A caravan town round a sweet well in the Desert of Fallen Stars, where the stars that fell melted the sand into glass and the glass held the water. Water is paid for in stories and stories in water; the Temple of the Fallen Stars keeps the oldest star charts west of the mountain."},
	{"id": "longmen", "n": "Longmen Ferry", "area": "longmen", "pos": Vector2i(28, 30),
		"lore": "The ferry town below the Dragon Gate, where Yu the Great cut the gorge and the golden carp leap the falls each spring to become dragons. Boatwrights, fishwives and lock-keepers live by the river; the flood stele by the River Earl's temple carries a mark for every flood since Yu."},
	{"id": "tushan", "n": "Tushan", "area": "tushan", "pos": Vector2i(28, 28),
		"lore": "The cauldron-casters' town on Mount Kuaiji, home of the clan that cast Yu's Nine Cauldrons. Its casting pits have never gone cold; its bells hang in temples from Longmen to the Jasper Pool, and the Stone Mother, who was Yu's wife, still watches the road from the hill above."},
	# ---- Part XI: the towns of the realms above and below
	{"id": "featherfall", "n": "Featherfall", "area": "juntian", "pos": Vector2i(38, 31),
		"lore": "The aerie-town of the Yumin, the Feathered Folk, on the islands round the crown of the Jianmu. Every Yumin hatches from an egg in the warm cellar of the Egg-Nursery, learns to glide before it can walk, and is told on its first birthday that it can fly, but not far. The Aerie Tower is the tallest thing in heaven that nobody ordered built."},
	{"id": "tearwater", "n": "Tearwater", "area": "ninesprings", "pos": Vector2i(38, 26),
		"lore": "The town of the Jiaoren, the Pearl-Weepers, on the shore of the black water under the roots of the world. Their tears turn to pearls; they weave a silk so fine that water will not wet it; and the Deathless of the root-groves trade them fruit that never spoils for songs that end."},
	{"id": "youdu_city", "n": "Youdu", "area": "youdu", "pos": Vector2i(38, 30),
		"lore": "The Dark Capital at the bottom of the world, the city of the shades, where the souls who are not ready to be reborn keep house under Houtu, Sovereign Earth. Its lanterns never go out, its inns never close and its magistrate has never once been late; Tubo guards the inner gate with three eyes and very bad manners."},
	# ---- Part XII: the town of the Isles of the Eastern Sea
	{"id": "landfall", "n": "Landfall", "area": "penglai", "pos": Vector2i(40, 30),
		"lore": "The town of the Thousand Children on Penglai, where Xu Fu's three thousand boys and girls came ashore from Qin two thousand two hundred years ago and waited for him to come back. Fishermen, net-menders and shipwrights; a Hall of the Thousand Names where every child learns the names by heart; a temple to Mazu; and, up the hill, the immortals, who for two thousand years have been too grand to come down."},
]

## What the land remembers of each region: shown beside the world map, and kept in the Annals once
## Lin Feng has been there.
const REGION_LORE := {
	"mountain": "Azure Cloud Mountain rises in the middle of the Unbroken Land, and every road in the world comes down off its slopes. Pines, cloud and old stone stairs; the post town of Cloudfoot at its northern foot and springs where cultivators sit for days. The Court's maps drew it as a column. It is a mountain.",
	"sect": "The Azure Cloud Sect has kept the mountain for three hundred years: a hall, a library, a smithy, a pharmacy and a lotus pond, and the steps an orphan swept for three years before the sky began to fall. Its gates open on every road of the world.",
	"bamboo": "The Whispering Bamboo Forest east of the sect, where the wind in the stems sounds like people talking just out of earshot. Bandits hid here when the Court still taxed the roads; the bamboo spirit is older than the bandits and older than the Court.",
	"marsh": "The Crimson Marsh: red water over black mud, blood lotuses and the hag who kept them. The old maps squared it into fields, but nobody has ever farmed it, and nobody ever will.",
	"frost": "Frostpeak Caverns, ice-caves in the mountains of the east where the Ice Empress held court. The frost jades grow in the dark like fruit; the caverns breathe out the cold of the winter before the world.",
	"thunder": "Thunder Valley, where storms come to rest between the crags. Ancestor Jian Wuchen died here with his sword raised, and his ghost still teaches the ones who do not flinch.",
	"palace": "The Blood Moon Palace in the far north-east, where the demon lord Xu Mo hunted the bearers of the Nine Heavens root for three hundred years. Its towers are empty now; the moon above it has gone back to being white.",
	"dragon": "The Sunken Dragon Palace on the north coast, coral halls under the sea where the Azure Dragon King was held in the rift's grip until a sect boy freed him. The tide here remembers every promise.",
	"volcano": "The Ashen Volcano along the northern shore: black slopes, rivers of fire and the forge-heat in which the Phoenix's embers wait. Sage Huo Rong keeps a hut where the lava runs slowest.",
	"void": "The Void Rift Expanse, where the land wore thin and the stars show through the ground. Islands of stone drift over nothing; the hermit who lives there says that there is no up or down, only forward.",
	"celestial": "The Celestial Gate at the north-west end of the northern coast, the door the Jade Emperor of Ruin held shut against the world. It opened for Lin Feng, and it has not closed since.",
	"mirror": "Mirror Lake of Echoes, south of the sect, a lake that remembers every face it ever reflected, the nineteen bearers before Lin Feng among them. Do not trust a reflection that smiles first.",
	"grave": "The Graveyard of Sword Saints, where every saint who swore to guard the Lotus Seal was buried with their blade. Founder Qing Lian of the sect lies here, and the swords still hum when a bearer walks past.",
	"time": "The River of Ten Thousand Years, which flows through days instead of miles. Its ferryman carries moments rather than people, and on its banks the first sweeper became the Jade Emperor.",
	"origin": "The Origin of the Dao in the far south, where everything began and the Hollow Heaven waited to swallow it. It is quiet now: white stone, a sky full of slow light, and the place where Yue Ling learned what she was.",
	"cloudsea": "The Sea of Clouds Archipelago, islands in the sky west of the mountain where the Court kept its tollgate for souls going up. The warden still sweeps the clouds; the clouds no longer carry tithes.",
	"court": "The ruins of the Jade Court, where the Heavenly Court's clerks wrote the Ledger of stolen years. Broken pavilions, four jade seals and the brush that wrote every name, snapped in two.",
	"forge": "Heaven's Forge, where every tribulation bolt was hammered on an anvil the size of a hill. Forge-Lord Tian Gong is sorry about all of them.",
	"garden": "The Garden of Immortal Peaches at the top of the western sky, where the nineteen bearers come in their dreams to sit in the shade. A peach here ripens once in three thousand years.",
	"dunes": "The Desert of Fallen Stars, south-east of the mountain, where Bai Hu guarded the western pillar of the sky and the nomads sang fallen stars home. The caravan town of Shazhou grew up round a well that the stars made.",
	"fungal": "Glowcap Vale, a valley of giant mushrooms that glow in the dark where Zhu Que's embers fell. The spore-witch Mo Gu says the vale dreams through its spores; most visitors leave with very strange dreams.",
	"aurora": "The Aurora Steppe, cold grassland under green and violet lights, where the herds run and Xuan Wu held up the northern pillar under the ice. The shamans read the lights as the sky's breath.",
	"chaos": "The Primordial Chaos at the south-east edge of the world, an ocean of every colour where Hundun sleeps holding the four pillars together. Nuwa's five-colour stones still drift through it.",
	"maple": "The Maple Gorge of Returning Souls, down the old funeral road south-west of the sect, where every maple was planted over somebody. Ox-Head kept the road; the lantern monk keeps it now, more kindly.",
	"karst": "The Stone Forest of the Nine Bends, towers of limestone standing in the river mist. The cormorant fisher there fishes for memories, which the river has been thick with since the Wheel stopped.",
	"springs": "The Yellow Springs of Red Lilies, the meadows the dead walk through on the way to rebirth. Meng Po's soup makes them forget; Lin Shan and Su Wan refused it for sixteen years to wait for their son.",
	"wheel": "The Wheel of the Six Paths at the western edge of the world, where every soul turns back towards life. King Yama sits in judgement there, and Judge Cui writes the pages as kindly as he can.",
	"village": "Qingshi Village at the foot of the mountain, the village of green stone where Lin Feng was raised; rice fields, an inn, a tofu shop and a shrine to the Earth God, and the threads the Weaver sewed across its roofs.",
	"terraces": "The Cloud-Tea Terraces climbing the hills south-west of the village, where Tea Master Lu Yu grows the Dragon-Well tea. Tea grows best on land worked by many hands, he says, and so do people.",
	"silk": "The Mulberry Silk Woods, where silkworms spin in the hollow trees and Can Niang keeps the cocoons. Some of the cocoons are breathing; some of them are borders being unpicked.",
	"loom": "The Loom of Borders in the far south-west, where Madam Qianxian wove every border of the Court's world, the old seams of the old map among them. Her apprentice swept it for two hundred years.",
	"starferry": "The Starfall Ferry on the Silver River, south of the sect, where the Cowherd waits on the bank and the river of heaven came down into the world. The ferry still runs; the stars in the water are real.",
	"magpie": "The Heights of the Magpie Bridge, cloud-cliffs where ten thousand magpies nest and build their bridge across the sky each seventh night. A bridge, Que Lao says, is only birds holding on to each other.",
	"starpalace": "The Palace of the Weaver Star at the southern edge of the world, where Zhi Nu weaves the dawn and the dusk. A thread is a road for a needle; a road is a thread for a traveller.",
	"jasper": "The Jasper Pool of Kunlun, high in the south-west, the Queen Mother's garden of immortal peaches and the place where she drew the River of Heaven with her hairpin. Everything here is older than it looks.",
	"yanggu": "Yanggu, the Dawn Market, east of the mountain on the pilgrims' road to the sunrise: lantern-makers, an archer's hall and a sundial that stood still for nine days of noon.",
	"millet": "The Scorched Millet Plains east of Yanggu, the granary of the east, where Old Farmer Tian prays to Hou Ji for a little night and a little rain. The fire crane Bifang walked the dyke road here.",
	"fusang": "Fusang, the Valley of Sunrise, in the far east, round the colossal mulberry where the sun-crows roost and Xihe once bathed her ten children in the hot springs. Feng Meng, Hou Yi's last apprentice, keeps a hut in the valley.",
	"guanghan": "Guanghan, the Palace of the Moon, at the far eastern end of the sun's road, silver frost and osmanthus where Chang'e walks the moon round the sky. The Jade Rabbit sleeps more these days.",
	"longmen": "Longmen, the Dragon Gate, north of the mountain, where the river comes down through a gorge that Yu the Great cut and the carp leap to become dragons. A ferry town of boatwrights, fishwives and lock-keepers; scholars who pass the examinations are said to have leapt the Dragon Gate.",
	"drowned": "The Drowned Fields of Gun, old rice country over which the Flood once stood for nine years behind Gun's walls of swelling earth. Yu drained it with channels instead of walls, and Bo Yi has kept the dykes ever since.",
	"tushan": "Tushan on Mount Kuaiji, where the Tushan clan cast Yu's Nine Cauldrons from the bronze of the nine provinces, and where Yu called every lord of the land to his great assembly. The giant Fangfeng arrived late.",
	"buzhou": "Mount Buzhou in the far north-west, the pillar of heaven that Gonggong broke with his head when he lost the war for the sky; the sky tilted north-west and every river has run east to the sea ever since. A black lake lies at its foot, and it is listening.",
	"juntian": "Juntian, the Level Heaven, the middle field of the Nine Heavens: islands in the sky round the crown of the Jianmu, above a sea of cloud. The Feathered Folk nest here in Featherfall, the dragon-kin keep the Rain Ministry, and since the Court fell the winds and the thunder have been doing whatever they like.",
	"changhe": "Changhe, the Gate of Heaven, at the top of the sky, where the old Court's great gate still stands on the highest islands. The celestial foxes, who cultivated for a thousand years to grow nine tails and climb up here, keep it now, mostly as a joke; and behind it Chong has held heaven up since the day the ladder was cut.",
	"ninesprings": "The Nine Springs beneath the roots of the Jianmu, a cavern country under the Unbroken Land where the roots of the world tree drink. The Pearl-Weepers keep their town of Tearwater on the black water, the Deathless tend their groves, and the Torch Dragon's eye is the only sun there has ever been.",
	"penglai": "Penglai, the first of the Isles of the Immortals in the Eastern Sea, where the sun on the water makes palaces in the air. The Court hid it in a mirage for two thousand years; the Thousand Children of Landfall lived inside it, and the Eight Immortals drank in its wine-house and waited for somebody to come.",
	"fangzhang": "Fangzhang, the Square-Pot Isle, the immortals' garden: terraces of herbs, cold elixir furnaces and the trees of pearl that drink from the Returning Ruins. The old books say a square pot holds more than a round one. The immortals say that is a joke about the Court.",
	"yingzhou": "Yingzhou, the Isle of Mists, which only sometimes admits to being there. The turtles who bear the isles rest their heads under it, Jingwei carries her stones across it to the sea, and Yu Qiang, God of the Northern Sea, keeps the turtles' shifts in a tally-room nobody has dusted for forty thousand years.",
	"guixu": "Guixu, the Returning Ruins, east of everything: the lip of the ravine without a bottom into which every river, every sea and the Silver River pour, and which never fills and never empties. On its slope lie the drowned summits of Daiyu and Yuanqiao, and the wrecks of the fleet that came looking for them.",
	"youdu": "Youdu, the Dark Capital, at the bottom of the world: the city of the shades who are not ready to be reborn, under Houtu, Sovereign Earth. Its lanterns have burned since before the Court; Tubo keeps its gate, and in the deep beyond it Li has pressed the earth down since the ladder was cut.",
}

## The ways between the realms (Part XI): each joins a tile of one region to a tile of another in a
## different realm, `out` being the side a traveller steps off on.  They open at a quest step, like
## the Lotus Seals.  "climb" is the long way up or down the Jianmu; stairs inside buildings are made
## from the buildings themselves (see Atlas).
const LADDERS := [
	{"id": "jianmu_up", "a": ["mountain", Vector2i(34, 59), Vector2i(0, 1)], "b": ["juntian", Vector2i(12, 32), Vector2i(1, 0)],
		"na": "Climb the Jianmu to the Nine Heavens", "nb": "Down the Jianmu to the Unbroken Land", "open": "s_p11_tree", "style": "climb"},
	{"id": "jianmu_down", "a": ["mountain", Vector2i(39, 54), Vector2i(1, 0)], "b": ["ninesprings", Vector2i(11, 30), Vector2i(1, 0)],
		"na": "Down the roots of the Jianmu to the Nine Springs", "nb": "Up the roots to the Unbroken Land", "open": "s_cg_chong", "style": "climb"},
	# Part XII: Mazu's boat, from the pool of the suns at Fusang out to the Isles of the Eastern Sea
	{"id": "sea_boat", "a": ["fusang", Vector2i(72, 49), Vector2i(0, -1)], "b": ["penglai", Vector2i(12, 32), Vector2i(1, 0)],
		"na": "Sail with Mazu to the Isles of the Eastern Sea", "nb": "Sail home to Fusang", "open": "s_p12_shore", "style": "sail"},
]

## The realm a region lies in: "surface" (the Unbroken Land), "heaven", "under" or "sea".
static func layer_of(id: String) -> String:
	return str(AREAS[id].get("layer", "surface")) if AREAS.has(id) else "surface"

## next area to enter when travelling from `from` to `to` (breadth-first over portals and the ladders
## between the realms)
static func next_hop(from: String, to: String) -> String:
	if from == to:
		return from
	var prev := {from: ""}
	var q: Array = [from]
	var i := 0
	while i < q.size():
		var c: String = q[i]
		i += 1
		var outs: Array = []
		for p in AREAS[c].get("portals", []):
			outs.append(p.to)
		for ld in LADDERS:
			if ld.a[0] == c:
				outs.append(ld.b[0])
			elif ld.b[0] == c:
				outs.append(ld.a[0])
		# the sect stands on the mountain: its gates open straight onto it
		if c == "sect":
			outs.append("mountain")
		elif c == "mountain":
			outs.append("sect")
		for nx in outs:
			if not prev.has(nx):
				prev[nx] = c
				q.append(nx)
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
	{"id": "s_f_hu1", "kind": "fate", "npc": "little_hu", "area": "bamboo", "t": "A boy with a kitchen knife is standing over Iron Fang: speak to him"},
	{"id": "s_spirit", "kind": "kill", "boss": "bamboo_spirit", "area": "bamboo", "t": "Calm the Ancient Bamboo Spirit"},
	{"id": "s_break1", "kind": "breakthrough", "to": 3, "t": "Break through to Foundation Establishment (Esc > Breakthrough)"},
	{"id": "s_elder2", "kind": "talk", "npc": "elder", "area": "sect", "t": "Tell the Elder of your breakthrough", "stones": 200},
	{"id": "s_f_qiu1", "kind": "fate", "npc": "qiu_ye", "area": "sect", "t": "Somebody is creeping out of Alchemist Mo's storeroom at night: stop him in the courtyard"},
	{"id": "s_lotus", "kind": "collect", "item": "lotus", "n": 4, "area": "marsh", "t": "Pluck 4 Blood Lotuses in the Crimson Marsh"},
	{"id": "s_hunt2", "kind": "hunt", "area": "marsh", "n": 16, "t": "Purge the marsh of its toxic denizens"},
	{"id": "s_colossus", "kind": "kill", "boss": "bog_colossus", "area": "marsh", "t": "Topple the Bog Colossus"},
	{"id": "s_hag", "kind": "kill", "boss": "marsh_hag", "area": "marsh", "t": "Slay the Marsh Hag"},
	{"id": "s_f_liu1", "kind": "fate", "npc": "liu_ying", "area": "marsh", "t": "Somebody is still in the Marsh Hag's hut: look inside"},
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
	{"id": "s_f_tala1", "kind": "fate", "npc": "tala", "area": "thunder", "t": "A horse-girl is calling for her herd at a gorge in Thunder Valley: find out what happened"},
	{"id": "s_apeking", "kind": "kill", "boss": "storm_ape_king", "area": "thunder", "t": "Subdue the Storm Ape King"},
	{"id": "s_roc", "kind": "kill", "boss": "thunder_roc", "area": "thunder", "t": "Slay the Thunder Roc"},
	{"id": "s_elder5", "kind": "talk", "npc": "elder", "area": "sect", "t": "Return to the Elder with the Roc's feather", "stones": 500},
	{"id": "s_hunt5", "kind": "hunt", "area": "palace", "n": 18, "t": "Cut down the demon vanguard of the Blood Moon Palace"},
	{"id": "s_hound", "kind": "kill", "boss": "blood_hound", "area": "palace", "t": "Slay the Crimson Hellhound"},
	{"id": "s_gen1", "kind": "kill", "boss": "general_blood", "area": "palace", "t": "Defeat General Xue Sha"},
	{"id": "s_gen2", "kind": "kill", "boss": "general_shadow", "area": "palace", "t": "Defeat General Mo Ying"},
	{"id": "s_lord", "kind": "kill", "boss": "demon_lord", "area": "palace", "t": "Defeat Demon Lord Xu Mo"},
	{"id": "s_f_xu1", "kind": "fate", "npc": "xu_lan", "area": "palace", "t": "Somebody is chained in the inner sanctum of the Blood Moon Palace: go and see"},
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
	{"id": "s_f_xu2", "kind": "fate", "npc": "xu_lan_lake", "area": "mirror", "t": "Xu Lan has come to the Mirror Lake, where her father's echo waits: find her on the shore"},
	{"id": "s_ml_mimic", "kind": "kill", "boss": "shard_mimic", "area": "mirror", "t": "Break the Shard Mimic"},
	{"id": "s_ml_colossus", "kind": "kill", "boss": "glass_colossus", "area": "mirror", "t": "Topple the Glass Colossus"},
	{"id": "s_ml_drowned", "kind": "kill", "boss": "drowned_bearer", "area": "mirror", "t": "Lay the Drowned Bearer to rest"},
	{"id": "s_ml_xumo", "kind": "kill", "boss": "echo_xumo", "area": "mirror", "t": "Face the Echo of Xu Mo", "stones": 1800},
	{"id": "s_gv_intro", "kind": "talk", "npc": "grave_keeper", "area": "grave", "t": "Find the Gravekeeper in the Graveyard of Sword Saints"},
	{"id": "s_gv_collect", "kind": "collect", "item": "relic", "n": 4, "area": "grave", "t": "Recover 4 Saint Relics from the barrows"},
	{"id": "s_gv_hunt", "kind": "hunt", "area": "grave", "n": 30, "t": "Put the restless dead to sleep"},
	{"id": "s_f_qiu2", "kind": "fate", "npc": "qiu_ye_grave", "area": "grave", "t": "Qiu Ye is in the Graveyard of Sword Saints: find out why"},
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
	{"id": "s_f_liu2", "kind": "fate", "npc": "liu_ying_vale", "area": "fungal", "t": "Liu Ying is in Glowcap Vale, where a blight is spreading: find her"},
	{"id": "s_fu_return", "kind": "talk", "npc": "spore_witch", "area": "fungal", "t": "Bring the glowcaps to Mo Gu"},
	{"id": "s_fu_mother", "kind": "kill", "boss": "spore_mother", "area": "fungal", "t": "Calm the Mother of Spores"},
	{"id": "s_fu_moth", "kind": "kill", "boss": "moth_queen", "area": "fungal", "t": "Dim the Lantern Moth Queen"},
	{"id": "s_fu_hydra", "kind": "kill", "boss": "rot_hydra", "area": "fungal", "t": "Uproot the Rot-Root Hydra"},
	{"id": "s_fu_bird", "kind": "kill", "boss": "vermilion_bird", "area": "fungal", "t": "Rekindle Zhu Que at the Southern Pillar", "stones": 6200},
	{"id": "s_au_intro", "kind": "talk", "npc": "steppe_shaman", "area": "aurora", "t": "Cross onto the Aurora Steppe and find its shaman"},
	{"id": "s_au_collect", "kind": "collect", "item": "aurora_shard", "n": 4, "area": "aurora", "t": "Catch 4 Aurora Shards where the lights touch the snow"},
	{"id": "s_au_hunt", "kind": "hunt", "area": "aurora", "n": 46, "t": "Turn back the frozen herds stampeding south"},
	{"id": "s_f_tala2", "kind": "fate", "npc": "tala_steppe", "area": "aurora", "t": "Tala's people are trapped in a blizzard pass on the Aurora Steppe: go to them"},
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
	# ---- Part VI: The Turning Wheel
	{"id": "s_p6_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "The dead are queueing at the gate: speak to Elder Qing Xuan", "stones": 7200},
	{"id": "s_mp_intro", "kind": "talk", "npc": "lantern_monk", "area": "maple", "t": "Take the south-west funeral road into the Maple Gorge and find the lantern monk"},
	{"id": "s_mp_collect", "kind": "collect", "item": "soul_lantern", "n": 4, "area": "maple", "t": "Gather 4 Soul Lanterns that drifted from the graves"},
	{"id": "s_mp_hunt", "kind": "hunt", "area": "maple", "n": 58, "t": "Calm the restless things haunting the gorge"},
	{"id": "s_mp_return", "kind": "talk", "npc": "lantern_monk", "area": "maple", "t": "Bring the Soul Lanterns to Monk Jing Kong"},
	{"id": "s_mp_fox", "kind": "kill", "boss": "nine_tail_fox", "area": "maple", "t": "Outwit the Nine-Tailed Fox of the Gorge"},
	{"id": "s_mp_koi", "kind": "kill", "boss": "waterfall_koi", "area": "maple", "t": "Climb the falls to the Koi King"},
	{"id": "s_mp_willow", "kind": "kill", "boss": "willow_widow", "area": "maple", "t": "Free the Willow Widow from her vigil"},
	{"id": "s_mp_ox", "kind": "kill", "boss": "ox_head", "area": "maple", "t": "Stop Ox-Head from dragging the dead back down", "stones": 7600},
	{"id": "s_kr_intro", "kind": "talk", "npc": "fisher", "area": "karst", "t": "Follow the river into the Stone Forest and find the cormorant fisher"},
	{"id": "s_kr_collect", "kind": "collect", "item": "memory_pearl", "n": 4, "area": "karst", "t": "Dive for 4 River Pearls of Memory"},
	{"id": "s_kr_hunt", "kind": "hunt", "area": "karst", "n": 58, "t": "Clear the river bends of creatures drunk on memories"},
	{"id": "s_kr_return", "kind": "talk", "npc": "fisher", "area": "karst", "t": "Bring the River Pearls to Old Yu"},
	{"id": "s_kr_cormorant", "kind": "kill", "boss": "cormorant_king", "area": "karst", "t": "Ground the Cormorant Tyrant"},
	{"id": "s_kr_jiao", "kind": "kill", "boss": "karst_jiao", "area": "karst", "t": "Calm the Jiao of the Nine Bends"},
	{"id": "s_kr_sentinel", "kind": "kill", "boss": "stone_sentinel", "area": "karst", "t": "Wake the Sentinel of the Stone Forest"},
	{"id": "s_kr_horse", "kind": "kill", "boss": "horse_face", "area": "karst", "t": "Turn back Horse-Face at the river's mouth", "stones": 8000},
	{"id": "s_sp_intro", "kind": "talk", "npc": "meng_po", "area": "springs", "t": "Cross into the Yellow Springs and find Meng Po at the Naihe Bridge"},
	{"id": "s_sp_collect", "kind": "collect", "item": "forget_herb", "n": 4, "area": "springs", "t": "Pick 4 Herbs of Forgetting among the red lilies"},
	{"id": "s_sp_hunt", "kind": "hunt", "area": "springs", "n": 60, "t": "Settle the hungry dead crowding the bridge"},
	{"id": "s_f_qiu3", "kind": "fate", "npc": "qiu_ye_springs", "area": "springs", "t": "Qiu Ye's father is in the queue of the dead: find Qiu Ye at the Yellow Springs"},
	{"id": "s_sp_return", "kind": "talk", "npc": "meng_po", "area": "springs", "t": "Bring the Herbs of Forgetting to Meng Po"},
	{"id": "s_sp_patriarch", "kind": "kill", "boss": "corpse_patriarch", "area": "springs", "t": "Lay Corpse Patriarch Jiang to rest"},
	{"id": "s_sp_serpent", "kind": "kill", "boss": "bridge_serpent", "area": "springs", "t": "Drive off the Serpent Beneath the Naihe Bridge"},
	{"id": "s_sp_empress", "kind": "kill", "boss": "lily_empress", "area": "springs", "t": "Bow to the Empress of the Red Lilies"},
	{"id": "s_sp_unforgotten", "kind": "kill", "boss": "the_unforgotten", "area": "springs", "t": "Hear out the Thousand Unforgotten", "stones": 8400},
	{"id": "s_wh_intro", "kind": "talk", "npc": "judge_cui", "area": "wheel", "t": "Descend to the Wheel of the Six Paths and find Judge Cui"},
	{"id": "s_wh_collect", "kind": "collect", "item": "wheel_spoke", "n": 4, "area": "wheel", "t": "Recover 4 broken Spokes of the Wheel"},
	{"id": "s_wh_hunt", "kind": "hunt", "area": "wheel", "n": 60, "t": "Quiet the courts of the dead"},
	{"id": "s_wh_return", "kind": "talk", "npc": "judge_cui", "area": "wheel", "t": "Bring the Spokes to Judge Cui"},
	{"id": "s_wh_mirror", "kind": "kill", "boss": "karma_mirror", "area": "wheel", "t": "Look into the Mirror of Karma"},
	{"id": "s_wh_judge", "kind": "kill", "boss": "burning_judge", "area": "wheel", "t": "Overturn the Judge of the Burning Court"},
	{"id": "s_wh_guardian", "kind": "kill", "boss": "wheel_guardian", "area": "wheel", "t": "Pass the Guardian of the Six Paths"},
	{"id": "s_wh_yama", "kind": "kill", "boss": "king_yama", "area": "wheel", "t": "Ask King Yama why the Wheel stopped", "stones": 9000},
	{"id": "s_break11", "kind": "breakthrough", "to": 33, "t": "Turn the Wheel with your own hands: transcend samsara"},
	# ---- Part VII: The Unbroken Land
	{"id": "s_p7_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "Silver threads across the roads: speak to Elder Qing Xuan", "stones": 9600},
	{"id": "s_vl_intro", "kind": "talk", "npc": "granny_wen", "area": "village", "t": "Take the south road down to Qingshi Village and find Granny Wen in her house"},
	{"id": "s_vl_collect", "kind": "collect", "item": "silver_thread", "n": 4, "area": "village", "t": "Cut 4 Silver Threads stitched across the village"},
	{"id": "s_vl_hunt", "kind": "hunt", "area": "village", "n": 56, "t": "Drive the thread-creatures out of the paddies"},
	{"id": "s_f_hu2", "kind": "fate", "npc": "hu_village", "area": "village", "t": "Iron Fang's son is in Qingshi Village: find him"},
	{"id": "s_vl_return", "kind": "talk", "npc": "granny_wen", "area": "village", "t": "Bring the Silver Threads to Granny Wen"},
	{"id": "s_vl_tiger", "kind": "kill", "boss": "paper_tiger", "area": "village", "t": "Tear down the Paper Tiger"},
	{"id": "s_vl_scarecrow", "kind": "kill", "boss": "scarecrow_king", "area": "village", "t": "Unstuff the Scarecrow King of the Paddies"},
	{"id": "s_vl_spider", "kind": "kill", "boss": "well_spider", "area": "village", "t": "Clear the spider out of the village well"},
	{"id": "s_vl_needle", "kind": "kill", "boss": "needle_general", "area": "village", "t": "Break Needle General Zhen's blockade", "stones": 9800},
	{"id": "s_te_intro", "kind": "talk", "npc": "tea_master", "area": "terraces", "t": "Climb to the Cloud-Tea Terraces and find the tea master in his tea house"},
	{"id": "s_te_collect", "kind": "collect", "item": "tea_bud", "n": 4, "area": "terraces", "t": "Pick 4 Dragon-Well Tea Buds from the high terraces"},
	{"id": "s_te_hunt", "kind": "hunt", "area": "terraces", "n": 58, "t": "Chase the thread-sick creatures off the terraces"},
	{"id": "s_te_return", "kind": "talk", "npc": "tea_master", "area": "terraces", "t": "Bring the Tea Buds to Lu Yu"},
	{"id": "s_te_kite", "kind": "kill", "boss": "wind_kite", "area": "terraces", "t": "Cut the string of the Great Wind Kite"},
	{"id": "s_te_dragon", "kind": "kill", "boss": "terrace_dragon", "area": "terraces", "t": "Wake the Dragon of the Nine Terraces"},
	{"id": "s_te_golem", "kind": "kill", "boss": "hill_golem", "area": "terraces", "t": "Unstitch the Tea-Hill Golem"},
	{"id": "s_te_matron", "kind": "kill", "boss": "thread_matron", "area": "terraces", "t": "Stop the Thread Matron sewing the hills shut", "stones": 10200},
	{"id": "s_sk_intro", "kind": "talk", "npc": "can_niang", "area": "silk", "t": "Enter the Mulberry Silk Woods and find Can Niang at the silkworm house"},
	{"id": "s_sk_collect", "kind": "collect", "item": "cocoon", "n": 4, "area": "silk", "t": "Rescue 4 Soul-Cocoons from the mulberries"},
	{"id": "s_sk_hunt", "kind": "hunt", "area": "silk", "n": 58, "t": "Thin the swarms spinning in the woods"},
	{"id": "s_sk_return", "kind": "talk", "npc": "can_niang", "area": "silk", "t": "Bring the Soul-Cocoons to Can Niang"},
	{"id": "s_sk_queen", "kind": "kill", "boss": "silkworm_queen", "area": "silk", "t": "Starve the Silkworm Queen of stolen souls"},
	{"id": "s_sk_moth", "kind": "kill", "boss": "moth_empress", "area": "silk", "t": "Ground the Moth Empress"},
	{"id": "s_sk_ent", "kind": "kill", "boss": "mulberry_ent", "area": "silk", "t": "Ask the Old Mulberry to let go"},
	{"id": "s_sk_hands", "kind": "kill", "boss": "thousand_hands", "area": "silk", "t": "Still the Thousand Hands of the Spinning Hall", "stones": 10600},
	{"id": "s_lm_intro", "kind": "talk", "npc": "apprentice_zhi", "area": "loom", "t": "Step onto the Loom of Borders and find the last weaver-girl"},
	{"id": "s_lm_collect", "kind": "collect", "item": "shuttle", "n": 4, "area": "loom", "t": "Take 4 Shuttles out of the Loom"},
	{"id": "s_lm_hunt", "kind": "hunt", "area": "loom", "n": 60, "t": "Unravel the Loom's guardians"},
	{"id": "s_lm_return", "kind": "talk", "npc": "apprentice_zhi", "area": "loom", "t": "Bring the Shuttles to Zhi"},
	{"id": "s_lm_beast", "kind": "kill", "boss": "warp_beast", "area": "loom", "t": "Untangle the Beast of the Tangled Warp"},
	{"id": "s_lm_golem", "kind": "kill", "boss": "spindle_golem", "area": "loom", "t": "Topple the Spindle Golem"},
	{"id": "s_lm_dragon", "kind": "kill", "boss": "shuttle_dragon", "area": "loom", "t": "Catch the Shuttle Dragon"},
	{"id": "s_lm_qianxian", "kind": "kill", "boss": "qianxian", "area": "loom", "t": "Face Madam Qianxian at the heart of the Loom", "stones": 11000},
	{"id": "s_break12", "kind": "breakthrough", "to": 36, "t": "Sew nothing shut: open your heart to the Boundless"},
	# ---- Part VIII: The River of Heaven
	{"id": "s_p8_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "Stars in the lotus pond: speak to Elder Qing Xuan", "stones": 11400},
	{"id": "s_sf_intro", "kind": "talk", "npc": "niu_lang", "area": "starferry", "t": "Follow the falling stars down to the Starfall Ferry and find the Cowherd"},
	{"id": "s_sf_collect", "kind": "collect", "item": "river_star", "n": 4, "area": "starferry", "t": "Fish 4 Drowned Stars out of the flooded fields"},
	{"id": "s_sf_hunt", "kind": "hunt", "area": "starferry", "n": 58, "t": "Turn back the creatures riding the star-flood"},
	{"id": "s_sf_return", "kind": "talk", "npc": "niu_lang", "area": "starferry", "t": "Bring the Drowned Stars to Niu Lang"},
	{"id": "s_sf_jiao", "kind": "kill", "boss": "silt_jiao", "area": "starferry", "t": "Drive the Jiao out of the silted ford"},
	{"id": "s_sf_widow", "kind": "kill", "boss": "reed_widow", "area": "starferry", "t": "Hear out the Widow of the Reed Ford"},
	{"id": "s_sf_carp", "kind": "kill", "boss": "carp_sage", "area": "starferry", "t": "Make the Old Carp leap at last"},
	{"id": "s_sf_qilin", "kind": "kill", "boss": "tide_qilin", "area": "starferry", "t": "Calm the Qilin of the Rising Tide", "stones": 11800},
	{"id": "s_mg_intro", "kind": "talk", "npc": "que_lao", "area": "magpie", "t": "Climb the cloud cliffs to the Heights of the Magpie Bridge and find the Old Magpie"},
	{"id": "s_mg_collect", "kind": "collect", "item": "magpie_plume", "n": 4, "area": "magpie", "t": "Gather 4 Bridge Plumes scattered by the storm"},
	{"id": "s_mg_hunt", "kind": "hunt", "area": "magpie", "n": 58, "t": "Clear the heights for the magpies to come home"},
	{"id": "s_mg_return", "kind": "talk", "npc": "que_lao", "area": "magpie", "t": "Bring the Bridge Plumes to Que Lao"},
	{"id": "s_mg_ape", "kind": "kill", "boss": "cloud_ape_king", "area": "magpie", "t": "Wrestle the King of the Cloud Apes off the nests"},
	{"id": "s_mg_storm", "kind": "kill", "boss": "storm_magpie", "area": "magpie", "t": "Bring down the Storm-Crowned Magpie"},
	{"id": "s_mg_golem", "kind": "kill", "boss": "pier_golem", "area": "magpie", "t": "Set the fallen Bridge-Pier back on its feet"},
	{"id": "s_mg_marshal", "kind": "kill", "boss": "crow_marshal", "area": "magpie", "t": "Break the Crow Marshal's blockade of the broken bridge", "stones": 12200},
	{"id": "s_wv_intro", "kind": "talk", "npc": "zhi_nu", "area": "starpalace", "t": "Cross the sky to the Palace of the Weaver Star and find Zhi Nu at her loom"},
	{"id": "s_wv_collect", "kind": "collect", "item": "star_thread", "n": 4, "area": "starpalace", "t": "Catch 4 Threads of Starlight blowing loose from the palace"},
	{"id": "s_wv_hunt", "kind": "hunt", "area": "starpalace", "n": 60, "t": "Drive the unwoven things out of the palace gardens"},
	{"id": "s_wv_return", "kind": "talk", "npc": "zhi_nu", "area": "starpalace", "t": "Bring the Threads of Starlight to Zhi Nu"},
	{"id": "s_wv_moth", "kind": "kill", "boss": "seven_star_moth", "area": "starpalace", "t": "Put out the Moth of the Seven Stars"},
	{"id": "s_wv_frame", "kind": "kill", "boss": "weaving_frame", "area": "starpalace", "t": "Stop the Celestial Weaving-Frame weaving walls"},
	{"id": "s_wv_qilin", "kind": "kill", "boss": "hall_qilin", "area": "starpalace", "t": "Win over the Qilin of the Weaving Hall"},
	{"id": "s_wv_warden", "kind": "kill", "boss": "river_warden", "area": "starpalace", "t": "Pass the Heavenly Warden of the River", "stones": 12600},
	{"id": "s_jp_intro", "kind": "talk", "npc": "dong_shuang", "area": "jasper", "t": "Climb Kunlun to the Jasper Pool and find the Queen Mother's maid"},
	{"id": "s_jp_collect", "kind": "collect", "item": "kunlun_peach", "n": 4, "area": "jasper", "t": "Pick 4 Peaches of Kunlun from the high orchard"},
	{"id": "s_jp_hunt", "kind": "hunt", "area": "jasper", "n": 60, "t": "Quiet the beasts guarding the orchard of immortality"},
	{"id": "s_jp_return", "kind": "talk", "npc": "dong_shuang", "area": "jasper", "t": "Bring the Peaches of Kunlun to Dong Shuang"},
	{"id": "s_jp_kaiming", "kind": "kill", "boss": "kaiming_beast", "area": "jasper", "t": "Open the Nine Gates past Kaiming"},
	{"id": "s_jp_birds", "kind": "kill", "boss": "blue_birds", "area": "jasper", "t": "Answer the Three Blue Birds"},
	{"id": "s_jp_ape", "kind": "kill", "boss": "white_ape", "area": "jasper", "t": "Out-wit the White Ape of Kunlun"},
	{"id": "s_jp_queen", "kind": "kill", "boss": "xiwangmu", "area": "jasper", "t": "Ask the Queen Mother of the West to lay down her hairpin", "stones": 13000},
	{"id": "s_break13", "kind": "breakthrough", "to": 39, "t": "Cross the River of Heaven: become a bridge yourself"},
	# ---- Part IX: The Tenth Sun
	{"id": "s_p9_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "The sun will not set: speak to Elder Qing Xuan", "stones": 13400},
	{"id": "s_yg_intro", "kind": "talk", "npc": "ah_mei", "area": "yanggu", "t": "Take the new south road down to the Dawn Market at Yanggu and find Ah Mei in her lantern shop"},
	{"id": "s_yg_collect", "kind": "collect", "item": "noon_ember", "n": 4, "area": "yanggu", "t": "Gather 4 Noon Embers smouldering in and around the market"},
	{"id": "s_yg_hunt", "kind": "hunt", "area": "yanggu", "n": 64, "t": "Drive the heat-maddened creatures out of the market lanes"},
	{"id": "s_yg_return", "kind": "talk", "npc": "ah_mei", "area": "yanggu", "t": "Bring the Noon Embers to Ah Mei"},
	{"id": "s_yg_fox", "kind": "kill", "boss": "mirage_fox", "area": "yanggu", "t": "Shut the Mirage Fox's water stall at the dry well"},
	{"id": "s_yg_sundial", "kind": "kill", "boss": "sundial_golem", "area": "yanggu", "t": "Calm the Golem of the Stopped Sundial"},
	{"id": "s_yg_dragon", "kind": "kill", "boss": "lantern_dragon", "area": "yanggu", "t": "Dance the Lantern Dragon nobody danced"},
	{"id": "s_yg_hanba", "kind": "kill", "boss": "hanba", "area": "yanggu", "t": "Face Hanba, the Drought Fiend, at the east gate", "stones": 13800},
	{"id": "s_mf_intro", "kind": "talk", "npc": "farmer_tian", "area": "millet", "t": "Follow the east road onto the Scorched Millet Plains and find Old Farmer Tian at the shrine of Hou Ji"},
	{"id": "s_mf_collect", "kind": "collect", "item": "rain_stone", "n": 4, "area": "millet", "t": "Find 4 Rain-Stones the dust devil scattered across the plain"},
	{"id": "s_mf_hunt", "kind": "hunt", "area": "millet", "n": 64, "t": "Drive the locusts and drought-beasts off the millet"},
	{"id": "s_f_tala3", "kind": "fate", "npc": "tala_plains", "area": "millet", "t": "Tala's herd is dying of thirst at the edge of the Millet Plains: go to her"},
	{"id": "s_mf_return", "kind": "talk", "npc": "farmer_tian", "area": "millet", "t": "Bring the Rain-Stones to Old Farmer Tian"},
	{"id": "s_mf_locust", "kind": "kill", "boss": "locust_marquis", "area": "millet", "t": "Scatter the Locust Marquis"},
	{"id": "s_mf_devil", "kind": "kill", "boss": "dust_devil", "area": "millet", "t": "Stop the Dust-Devil spinning in the dry river"},
	{"id": "s_mf_tortoise", "kind": "kill", "boss": "well_tortoise", "area": "millet", "t": "Talk the Old Tortoise out of the village well"},
	{"id": "s_mf_bifang", "kind": "kill", "boss": "bifang", "area": "millet", "t": "Ground Bifang, the One-Legged Fire Crane, on the dyke road", "stones": 14200},
	{"id": "s_fs_intro", "kind": "talk", "npc": "feng_meng", "area": "fusang", "t": "Climb into Fusang, the Valley of Sunrise, and find the old archer"},
	{"id": "s_fs_collect", "kind": "collect", "item": "sun_feather", "n": 4, "area": "fusang", "t": "Gather 4 Sun-Feathers fallen from the Fusang tree"},
	{"id": "s_fs_hunt", "kind": "hunt", "area": "fusang", "n": 62, "t": "Clear the steaming valley of the sun's hangers-on"},
	{"id": "s_fs_return", "kind": "talk", "npc": "feng_meng", "area": "fusang", "t": "Bring the Sun-Feathers to Feng Meng"},
	{"id": "s_fs_crab", "kind": "kill", "boss": "boiled_crab", "area": "fusang", "t": "Haul the Crab out of the bathing springs"},
	{"id": "s_fs_ember", "kind": "kill", "boss": "ninth_ember", "area": "fusang", "t": "Put the Ember of the Ninth Sun back to sleep"},
	{"id": "s_fs_moth", "kind": "kill", "boss": "sun_moth", "area": "fusang", "t": "Turn back the Moth Who Flew at the Sun"},
	{"id": "s_fs_jinwu", "kind": "kill", "boss": "jinwu", "area": "fusang", "t": "Climb the Fusang and coax down Jinwu, the Sun Crow", "stones": 14600},
	{"id": "s_gh_intro", "kind": "talk", "npc": "chang_e", "area": "guanghan", "t": "Walk the sun's road into the night to the Moon Palace and find Chang'e"},
	{"id": "s_gh_collect", "kind": "collect", "item": "osmanthus", "n": 4, "area": "guanghan", "t": "Gather 4 Moon-Osmanthus blossoms from the frost"},
	{"id": "s_gh_hunt", "kind": "hunt", "area": "guanghan", "n": 52, "t": "Drive the long night's restless things from the Moon Palace"},
	{"id": "s_gh_return", "kind": "talk", "npc": "chang_e", "area": "guanghan", "t": "Bring the osmanthus to Chang'e"},
	{"id": "s_gh_wugang", "kind": "kill", "boss": "wu_gang", "area": "guanghan", "t": "Make Wu Gang put down his axe"},
	{"id": "s_gh_tiangou", "kind": "kill", "boss": "tiangou", "area": "guanghan", "t": "Chase Tiangou away from the tired moon"},
	{"id": "s_gh_rabbit", "kind": "kill", "boss": "mortar_rabbit", "area": "guanghan", "t": "Get past the Jade Rabbit and its mortar"},
	{"id": "s_gh_xihe", "kind": "kill", "boss": "xihe", "area": "guanghan", "t": "Face Xihe, Mother of the Ten Suns, on the Moon's throne", "stones": 15000},
	{"id": "s_break14", "kind": "breakthrough", "to": 42, "t": "Stand where the sun's road meets the moon's: Sun-Moon Harmony"},
	# ---- Part X: The Nine Cauldrons
	{"id": "s_p10_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "The maps are wrong: speak to Elder Qing Xuan", "stones": 15400},
	{"id": "s_p10_archive", "kind": "talk", "npc": "archivist", "area": "sect", "t": "Ask Archivist Lan in the Scripture Library what is remembered of the Nine Cauldrons"},
	{"id": "s_p10_road", "kind": "talk", "npc": "cartographer_pei", "area": "mountain", "t": "Take the new north gate down to Cloudfoot and find Cartographer Pei in his House of Maps"},
	{"id": "s_dg_intro", "kind": "talk", "npc": "harbour_yao", "area": "longmen", "t": "Follow the north road down to the river at Longmen and find the Harbourmistress"},
	{"id": "s_dg_collect", "kind": "collect", "item": "carp_scale", "n": 4, "area": "longmen", "t": "Gather 4 Dragon-Gate Scales shed below the falls"},
	{"id": "s_dg_hunt", "kind": "hunt", "area": "longmen", "n": 64, "t": "Clear the flooded quays and riverbanks of Longmen"},
	{"id": "s_f_hu3", "kind": "fate", "npc": "hu_longmen", "area": "longmen", "t": "Fang Hu has heard something about his father at Longmen: find him"},
	{"id": "s_dg_return", "kind": "talk", "npc": "harbour_yao", "area": "longmen", "t": "Bring the Dragon-Gate Scales to Harbourmistress Jiang"},
	{"id": "s_dg_carp", "kind": "kill", "boss": "sulking_carp", "area": "longmen", "t": "Coax the Carp Who Would Not Leap over the Dragon Gate"},
	{"id": "s_dg_eel", "kind": "kill", "boss": "eel_king", "area": "longmen", "t": "Run Black Eel and his river-rats out of the flooded warehouses"},
	{"id": "s_dg_bell", "kind": "kill", "boss": "drowned_bell", "area": "longmen", "t": "Haul the Drowned Temple Bell up out of the river"},
	{"id": "s_dg_lion", "kind": "kill", "boss": "stone_lion", "area": "longmen", "t": "Wake the Stone Lion of the ferry stage out of its bad dream"},
	{"id": "s_dg_hebo", "kind": "kill", "boss": "he_bo", "area": "longmen", "t": "Face He Bo, Earl of the Yellow River, at the ferry stage", "stones": 15800},
	{"id": "s_dg_temple", "kind": "talk", "npc": "shrine_hua", "area": "longmen", "t": "Take He Bo's flood tablet to Shrine-Maiden Hua at the Temple of the River Earl"},
	{"id": "s_df_intro", "kind": "talk", "npc": "bo_yi", "area": "drowned", "t": "Cross the gorge into the Drowned Fields and find the keeper of Yu's dykes"},
	{"id": "s_df_collect", "kind": "collect", "item": "xirang", "n": 4, "area": "drowned", "t": "Gather 4 Clods of Swelling Earth before they grow into walls"},
	{"id": "s_df_hunt", "kind": "hunt", "area": "drowned", "n": 64, "t": "Drive the flood's creatures off the old dykes"},
	{"id": "s_df_return", "kind": "talk", "npc": "bo_yi", "area": "drowned", "t": "Bring the Swelling Earth to Bo Yi"},
	{"id": "s_df_toad", "kind": "kill", "boss": "toad_matriarch", "area": "drowned", "t": "Make the Toad Who Swallowed the Dykes spit out the fields"},
	{"id": "s_df_heron", "kind": "kill", "boss": "heron_lord", "area": "drowned", "t": "Unseat the Heron Lord of the Drowned Paddies"},
	{"id": "s_df_dragon", "kind": "kill", "boss": "mud_dragon", "area": "drowned", "t": "Break the Mud Dragon out of Yu's last channel"},
	{"id": "s_df_turtle", "kind": "kill", "boss": "carrier_turtle", "area": "drowned", "t": "Lift the load off the Turtle Who Carried Gun's Earth"},
	{"id": "s_df_gun", "kind": "kill", "boss": "gun", "area": "drowned", "t": "Stop Gun building his wall of growing earth", "stones": 16200},
	{"id": "s_ts_carver", "kind": "talk", "npc": "carver_shi", "area": "tushan", "t": "Ask Stone-Carver Shi in Tushan to read the marks on He Bo's flood tablet"},
	{"id": "s_ts_intro", "kind": "talk", "npc": "tu_lan", "area": "tushan", "t": "Climb to Tushan, the cauldron-casters' town on Mount Kuaiji, and find Tu Lan in her foundry"},
	{"id": "s_ts_collect", "kind": "collect", "item": "cauldron_shard", "n": 4, "area": "tushan", "t": "Gather 4 Cauldron Shards scattered over the mountain"},
	{"id": "s_ts_hunt", "kind": "hunt", "area": "tushan", "n": 62, "t": "Clear the casting pits and charcoal woods of Tushan"},
	{"id": "s_ts_return", "kind": "talk", "npc": "tu_lan", "area": "tushan", "t": "Bring the Cauldron Shards to Tu Lan"},
	{"id": "s_ts_serpent", "kind": "kill", "boss": "slag_serpent", "area": "tushan", "t": "Cool the Slag Serpent of the casting pits"},
	{"id": "s_ts_mother", "kind": "kill", "boss": "stone_mother", "area": "tushan", "t": "Settle the Stone Mother back on her hill"},
	{"id": "s_ts_fangfeng", "kind": "kill", "boss": "fangfeng", "area": "tushan", "t": "Stop Fangfeng, the Giant Who Came Late, from hurrying"},
	{"id": "s_ts_fox", "kind": "kill", "boss": "tushan_fox", "area": "tushan", "t": "Follow the White Nine-Tailed Fox of Tushan"},
	{"id": "s_ts_taotie", "kind": "kill", "boss": "taotie", "area": "tushan", "t": "Put the Taotie back on its cauldron before it eats the map", "stones": 16600},
	{"id": "s_bz_intro", "kind": "talk", "npc": "yinglong", "area": "buzhou", "t": "Follow the backwards rivers to Mount Buzhou and find Yinglong"},
	{"id": "s_bz_collect", "kind": "collect", "item": "pillar_stone", "n": 4, "area": "buzhou", "t": "Gather 4 Stones of the broken pillar round the black lake"},
	{"id": "s_bz_hunt", "kind": "hunt", "area": "buzhou", "n": 60, "t": "Drive the flood's last creatures from the shores of the black lake"},
	{"id": "s_bz_return", "kind": "talk", "npc": "yinglong", "area": "buzhou", "t": "Bring the stones of Buzhou to Yinglong"},
	{"id": "s_bz_xiu", "kind": "kill", "boss": "xiu", "area": "buzhou", "t": "Show Xiu, who loved roads, where the roads have gone"},
	{"id": "s_bz_kun", "kind": "kill", "boss": "kun", "area": "buzhou", "t": "Turn the Kun of the Northern Darkness back towards the sea"},
	{"id": "s_bz_xiangliu", "kind": "kill", "boss": "xiangliu", "area": "buzhou", "t": "Bind Xiangliu, the Nine-Headed Minister, without spilling a drop"},
	{"id": "s_bz_kuafu", "kind": "kill", "boss": "kuafu", "area": "buzhou", "t": "Stop Kuafu, who drank the rivers dry, drinking the black lake"},
	{"id": "s_bz_gonggong", "kind": "kill", "boss": "gonggong", "area": "buzhou", "t": "Show Gonggong, God of the Flood, the land as it really is", "stones": 17000},
	{"id": "s_break15", "kind": "breakthrough", "to": 45, "t": "Let the land keep its own shape: Mountain-River Oneness"},
	# ---- Part XI: The Ladder of Heaven
	{"id": "s_p11_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "A tree has grown on the mountain in the night: speak to Elder Qing Xuan", "stones": 17400},
	{"id": "s_p11_archive", "kind": "talk", "npc": "archivist_deep", "area": "sect", "t": "Find Archivist Lan in the Sealed Archive, down the stairs inside the Scripture Library"},
	{"id": "s_p11_tree", "kind": "talk", "npc": "ling_yu", "area": "mountain", "t": "Go to the foot of the Jianmu, west of the sect, and meet whoever came down it"},
	{"id": "s_jt_intro", "kind": "talk", "npc": "yu_hua", "area": "juntian", "t": "Climb the Jianmu into the Nine Heavens and find the Feather-Mother at the top of the Aerie Tower"},
	{"id": "s_jt_collect", "kind": "collect", "item": "wind_bell", "n": 4, "area": "juntian", "t": "Gather 4 Storm-Torn Wind Bells blown off the aeries"},
	{"id": "s_jt_hunt", "kind": "hunt", "area": "juntian", "n": 50, "t": "Calm the loose winds and thunder over the islands of Juntian"},
	{"id": "s_jt_return", "kind": "talk", "npc": "yu_hua", "area": "juntian", "t": "Bring the wind bells to Feather-Mother Yu Hua at the top of the Aerie Tower"},
	{"id": "s_jt_minister", "kind": "talk", "npc": "ao_run", "area": "juntian", "t": "Find Rain-Minister Ao Run in the Archive of Rain, below the Rain Ministry"},
	{"id": "s_jt_feilian", "kind": "kill", "boss": "feilian", "area": "juntian", "t": "Catch Feilian, Earl of the Wind, and take back his bag of winds"},
	{"id": "s_jt_kui", "kind": "kill", "boss": "kui", "area": "juntian", "t": "Quiet Kui, the One-Legged Thunder Ox"},
	{"id": "s_jt_jiufeng", "kind": "kill", "boss": "jiufeng", "area": "juntian", "t": "Settle the nine quarrelling heads of Jiufeng"},
	{"id": "s_jt_leigong", "kind": "kill", "boss": "leigong", "area": "juntian", "t": "Face Leigong, Duke of Thunder, who strikes at everything now", "stones": 17800},
	{"id": "s_cg_intro", "kind": "talk", "npc": "hu_qingyi", "area": "changhe", "t": "Cross to Changhe, the Gate of Heaven, and find the Ninth-Tail Matron on the moon terrace of her pavilion"},
	{"id": "s_cg_collect", "kind": "collect", "item": "gate_key", "n": 4, "area": "changhe", "t": "Find the 4 Keys of the Gate the foxes hid as a joke"},
	{"id": "s_cg_hunt", "kind": "hunt", "area": "changhe", "n": 50, "t": "Clear the islands before the Gate of Heaven"},
	{"id": "s_cg_return", "kind": "talk", "npc": "hu_qingyi", "area": "changhe", "t": "Bring the four keys up to Hu Qingyi on the moon terrace"},
	{"id": "s_cg_pixiu", "kind": "kill", "boss": "pixiu", "area": "changhe", "t": "Make Pixiu give back the gold of the Gate"},
	{"id": "s_cg_shentu", "kind": "kill", "boss": "shentu", "area": "changhe", "t": "Get past Shentu, the door god under the peach tree"},
	{"id": "s_cg_yulei", "kind": "kill", "boss": "yulei", "area": "changhe", "t": "Get past Yulei and his rope of reeds"},
	{"id": "s_cg_chong", "kind": "kill", "boss": "chong", "area": "changhe", "t": "Face Chong, who has held heaven up since the ladder was cut", "stones": 18200},
	{"id": "s_ns_intro", "kind": "talk", "npc": "shui_lian", "area": "ninesprings", "t": "Go down the roots of the Jianmu into the Nine Springs and find the Pearl-Weavers of Tearwater"},
	{"id": "s_ns_collect", "kind": "collect", "item": "spring_water", "n": 4, "area": "ninesprings", "t": "Fill 4 Vials at the springs the roots drink from"},
	{"id": "s_ns_hunt", "kind": "hunt", "area": "ninesprings", "n": 50, "t": "Drive the root-gnawers away from the Jianmu"},
	{"id": "s_ns_return", "kind": "talk", "npc": "shui_lian", "area": "ninesprings", "t": "Bring the spring water to Shui Lian in the Hall of the Pearl-Weavers"},
	{"id": "s_ns_elder", "kind": "talk", "npc": "bu_si", "area": "ninesprings", "t": "Climb to the loft of the House under the Great Root and ask Elder Bu Si of the Deathless"},
	{"id": "s_ns_wyrm", "kind": "kill", "boss": "root_wyrm", "area": "ninesprings", "t": "Stop the Wyrm Who Gnaws the Jianmu"},
	{"id": "s_ns_pearl", "kind": "kill", "boss": "pearl_mother", "area": "ninesprings", "t": "Comfort the Weeping Pearl-Mother of the black water"},
	{"id": "s_ns_wangxiang", "kind": "kill", "boss": "wangxiang", "area": "ninesprings", "t": "Catch Wangxiang, the goblin who muddies the springs"},
	{"id": "s_ns_zhulong", "kind": "kill", "boss": "zhulong", "area": "ninesprings", "t": "Face Zhulong, the Torch Dragon, whose eye is the only sun below", "stones": 18600},
	{"id": "s_yd_intro", "kind": "talk", "npc": "ming_yi", "area": "youdu", "t": "Enter Youdu, the Dark Capital, and find the Lantern-Magistrate in the upper room of the Ward Office"},
	{"id": "s_yd_collect", "kind": "collect", "item": "soul_tally", "n": 4, "area": "youdu", "t": "Gather 4 Soul-Tallies blown out of the Dark Capital's rolls"},
	{"id": "s_yd_hunt", "kind": "hunt", "area": "youdu", "n": 50, "t": "Clear the streets of the Dark Capital of runaway spirits"},
	{"id": "s_f_xu3", "kind": "fate", "npc": "xu_lan_youdu", "area": "youdu", "t": "Xu Lan has come to Youdu, where her father's shade is kept: find her"},
	{"id": "s_yd_return", "kind": "talk", "npc": "ming_yi", "area": "youdu", "t": "Bring the soul-tallies up to Magistrate Ming Yi"},
	{"id": "s_yd_houtu", "kind": "talk", "npc": "houtu", "area": "youdu", "t": "Go down to the deep hall under the Palace of Sovereign Earth and meet Houtu"},
	{"id": "s_yd_bai", "kind": "kill", "boss": "bai_wuchang", "area": "youdu", "t": "Stop White Impermanence collecting the living"},
	{"id": "s_yd_hei", "kind": "kill", "boss": "hei_wuchang", "area": "youdu", "t": "Stop Black Impermanence collecting the living"},
	{"id": "s_yd_tubo", "kind": "kill", "boss": "tubo", "area": "youdu", "t": "Get past Tubo, Earl of the Dark Capital, at the inner gate"},
	{"id": "s_yd_li", "kind": "kill", "boss": "li", "area": "youdu", "t": "Face Li, who has pressed the earth down since the ladder was cut", "stones": 19000},
	{"id": "s_p11_end", "kind": "talk", "npc": "elder", "area": "sect", "t": "Climb back up the roots and take Chong's tablet and Li's weight home to the Elder"},
	{"id": "s_break16", "kind": "breakthrough", "to": 48, "t": "Hold the ladder open for every road: Three Realms Concord"},
	# ---- Part XII: The Returning Ruins
	{"id": "s_p12_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "The tide went out and did not come back: speak to Elder Qing Xuan", "stones": 19400},
	{"id": "s_p12_archive", "kind": "talk", "npc": "archivist", "area": "sect", "t": "Ask Archivist Lan in the Scripture Library what the Court hid about the Eastern Sea"},
	{"id": "s_p12_shore", "kind": "talk", "npc": "mazu", "area": "fusang", "t": "Go east to Fusang, where the sun rises out of the sea, and find out where the sea has gone"},
	{"id": "s_pl_intro", "kind": "talk", "npc": "xu_qian", "area": "penglai", "t": "Sail to Penglai and find the Headwoman of Landfall in the Hall of the Thousand Names"},
	{"id": "s_pl_collect", "kind": "collect", "item": "name_slip", "n": 4, "area": "penglai", "t": "Gather 4 Slips of the Thousand Names the drain left on the sandbars"},
	{"id": "s_pl_hunt", "kind": "hunt", "area": "penglai", "n": 50, "t": "Drive the stranded sharks and sandbar crabs back from Landfall's shore"},
	{"id": "s_pl_return", "kind": "talk", "npc": "xu_qian", "area": "penglai", "t": "Bring the name-slips back to Headwoman Xu Qian"},
	{"id": "s_pl_immortal", "kind": "talk", "npc": "lu_dongbin", "area": "penglai", "t": "Climb to the drinking-room of the Wine-House of the Drunken Immortal and ask Lu Dongbin where the sea went"},
	{"id": "s_pl_qianliyan", "kind": "kill", "boss": "qianliyan", "area": "penglai", "t": "Close the eyes of Qianliyan, who watches the sea for somebody else"},
	{"id": "s_pl_shunfeng", "kind": "kill", "boss": "shunfenger", "area": "penglai", "t": "Stop the ears of Shunfeng'er, who listens to the wind for somebody else"},
	{"id": "s_pl_monk", "kind": "kill", "boss": "sea_monk", "area": "penglai", "t": "Drive the Sea-Monk off the fishermen's sandbar"},
	{"id": "s_pl_longbo", "kind": "kill", "boss": "longbo_giant", "area": "penglai", "t": "Stop the Giant of Longbo fishing the turtles off the bare shelf", "stones": 19800},
	{"id": "s_fz_intro", "kind": "talk", "npc": "he_xiangu", "area": "fangzhang", "t": "Cross the sandbar to Fangzhang and find He Xiangu on the terrace of her Lotus Hall"},
	{"id": "s_fz_collect", "kind": "collect", "item": "pearl_dew", "n": 4, "area": "fangzhang", "t": "Gather 4 Drops of Dew from the dying pearl trees"},
	{"id": "s_fz_hunt", "kind": "hunt", "area": "fangzhang", "n": 50, "t": "Chase the toads, cranes and rabbits out of the immortals' gardens"},
	{"id": "s_f_liu3", "kind": "fate", "npc": "liu_ying_isle", "area": "fangzhang", "t": "Liu Ying has come to Fangzhang to study the immortals' elixirs: find her"},
	{"id": "s_fz_return", "kind": "talk", "npc": "he_xiangu", "area": "fangzhang", "t": "Bring the pearl dew up to He Xiangu"},
	{"id": "s_fz_zhang", "kind": "talk", "npc": "zhang_guolao", "area": "fangzhang", "t": "Go down to the cellar of cold furnaces and ask Zhang Guolao, who remembers the Court's sealing"},
	{"id": "s_fz_deer", "kind": "kill", "boss": "longevity_deer", "area": "fangzhang", "t": "Calm the White Deer of Longevity, who has eaten the last ripe herbs"},
	{"id": "s_fz_furnace", "kind": "kill", "boss": "elixir_furnace", "area": "fangzhang", "t": "Catch the Elixir Furnace That Walked Away"},
	{"id": "s_fz_tree", "kind": "kill", "boss": "pearl_tree", "area": "fangzhang", "t": "Quiet the Pearl Tree That Will Not Fruit"},
	{"id": "s_fz_tianwu", "kind": "kill", "boss": "tianwu", "area": "fangzhang", "t": "Face Tianwu, the eight-headed god who kept the stopper of the sea", "stones": 20200},
	{"id": "s_yz_intro", "kind": "talk", "npc": "jingwei", "area": "yingzhou", "t": "Follow the sandbar into the mists of Yingzhou and find the bird who carries stones"},
	{"id": "s_yz_collect", "kind": "collect", "item": "jingwei_stone", "n": 4, "area": "yingzhou", "t": "Gather 4 of the stones Jingwei dropped in the mist"},
	{"id": "s_yz_hunt", "kind": "hunt", "area": "yingzhou", "n": 50, "t": "Clear the phantoms of the sea-mist off the turtles' isle"},
	{"id": "s_yz_return", "kind": "talk", "npc": "jingwei", "area": "yingzhou", "t": "Bring Jingwei her stones"},
	{"id": "s_yz_herald", "kind": "talk", "npc": "gui_lao", "area": "yingzhou", "t": "Climb to the tally-room of the Shrine of the Fifteen Turtles and find Old Gui"},
	{"id": "s_yz_wuzixu", "kind": "kill", "boss": "wu_zixu", "area": "yingzhou", "t": "Face Wu Zixu, who stopped the tide when the sea went"},
	{"id": "s_yz_shen", "kind": "kill", "boss": "shen", "area": "yingzhou", "t": "Wake Shen, the Mirage Clam-Dragon, from her false seas"},
	{"id": "s_yz_ao", "kind": "kill", "boss": "great_ao", "area": "yingzhou", "t": "Steady the Great Ao who bears Yingzhou, thrashing on the dry shelf"},
	{"id": "s_yz_yuqiang", "kind": "kill", "boss": "yu_qiang", "area": "yingzhou", "t": "Face Yu Qiang, God of the Northern Sea, who keeps the turtles' shifts", "stones": 20600},
	{"id": "s_gx_intro", "kind": "talk", "npc": "steersman_hong", "area": "guixu", "t": "Go down the bare sea floor to the Returning Ruins and find the steersman's cabin in the wreck of the flagship"},
	{"id": "s_gx_collect", "kind": "collect", "item": "xufu_log", "n": 4, "area": "guixu", "t": "Gather 4 Pages of Xu Fu's Logbook scattered over the sea floor"},
	{"id": "s_gx_hunt", "kind": "hunt", "area": "guixu", "n": 50, "t": "Clear the drowned sailors and the eels off the rim of the Returning Ruins"},
	{"id": "s_gx_return", "kind": "talk", "npc": "steersman_hong", "area": "guixu", "t": "Bring the logbook pages up to Steersman Hong"},
	{"id": "s_gx_boy", "kind": "talk", "npc": "ship_boy_ah_fu", "area": "guixu", "t": "Find Ah Fu, the ship's boy, on the road to the lip of the Ruins"},
	{"id": "s_gx_admiral", "kind": "kill", "boss": "drowned_admiral", "area": "guixu", "t": "Release the Admiral of the Lost Fleet from his dry ship"},
	{"id": "s_gx_stopper", "kind": "kill", "boss": "guixu_stopper", "area": "guixu", "t": "Stop the Bronze Stopper of Guixu rolling over the sea floor"},
	{"id": "s_gx_ruo", "kind": "kill", "boss": "hai_ruo", "area": "guixu", "t": "Face Ruo of the Northern Sea, the sea itself, rising out of the drain"},
	{"id": "s_gx_xufu", "kind": "kill", "boss": "xu_fu", "area": "guixu", "t": "Face Xu Fu at the lip of the Returning Ruins", "stones": 21000},
	{"id": "s_p12_end", "kind": "talk", "npc": "xu_qian", "area": "penglai", "t": "Sail back to Landfall with Xu Fu and bring him home to the Thousand Children"},
	{"id": "s_break17", "kind": "breakthrough", "to": 51, "t": "Let every water come home: Ten Thousand Waters Return"},
	# ---- Part XIII: The Eight Gates.  Open any four of eight, in any order; then one of three roads to the end
	{"id": "s_p13_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "Bars of gold light stand in all four realms: speak to Elder Qing Xuan", "stones": 21400},
	{"id": "s_p13_archive", "kind": "talk", "npc": "archivist", "area": "sect", "t": "Ask Archivist Lan what the Court built at Zhuolu, and what it locked away"},
	{"id": "s_p13_yinglong", "kind": "talk", "npc": "yinglong", "area": "buzhou", "t": "Go north to Mount Buzhou and ask Yinglong, who fought at Zhuolu, what the war god was"},
	{"id": "s_p13_monk", "kind": "talk", "npc": "lantern_monk", "area": "maple", "t": "Go down the funeral road to the Maple Gorge, where the oldest maples were Chiyou's fetters, and ask the lantern monk"},
	{"id": "s_p13_hunt", "kind": "hunt", "area": "maple", "n": 18, "of": ["jiuli_warrior", "zhuolu_fog", "bronze_brow", "fetter_sapling", "banner_ember"], "t": "Drive Chiyou's war-band back off the funeral road in the Maple Gorge"},
	{"id": "s_p13_gates", "kind": "gates", "n": 4, "area": "maple", "t": "Open any four of the Eight Gates, in the four realms, in any order"},
	{"id": "s_p13_heart", "kind": "talk", "npc": "lantern_monk", "area": "maple", "t": "The lock is broken: go back to the lantern monk in the Maple Gorge"},
	{"id": "s_p13_envoys", "kind": "visits", "npcs": ["yu_hua", "ao_run", "hu_qingyi", "shui_lian", "bu_si", "ming_yi", "xu_qian", "he_xiangu"], "n": 4, "area": "maple", "t": "Before you walk into Zhuolu, carry the Elder's invitations to the leaders of any four of the peoples, in any order"},
	{"id": "s_p13_chiyou", "kind": "kill", "boss": "chiyou", "area": "maple", "t": "Walk into the field of Zhuolu by the road you choose, and face Chiyou", "stones": 21800},
	{"id": "s_p13_end", "kind": "talk", "npc": "elder", "area": "sect", "t": "Go home: the Conclave of the Realms meets at last under the Jianmu"},
	{"id": "s_break18", "kind": "breakthrough", "to": 54, "t": "Walk every road at once: Myriad Daos as One"},
	# ---- Part XIV: The Ripening of Karma.  Every cause comes home: the five threads, then Nie at the Wheel
	{"id": "s_p14_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "The sky over the sect is heavy with something owed: speak to Elder Qing Xuan", "stones": 22000},
	{"id": "s_p14_judge", "kind": "talk", "npc": "judge_cui", "area": "wheel", "t": "Go down the funeral road to the Wheel of the Six Paths and ask Judge Cui what is gathering there"},
	{"id": "s_p14_hunt", "kind": "hunt", "area": "wheel", "n": 16, "of": ["grudge_wisp", "debt_shade", "karma_moth"], "t": "Drive back the grudges and debts swarming round the Wheel"},
	{"id": "s_p14_fates", "kind": "fates", "npcs": ["tala_end", "qiu_ye_end", "hu_end", "xu_lan_end", "liu_ying_end"], "n": 5, "area": "sect", "t": "Settle the five threads of your journey, in any order: Tala, Qiu Ye, Fang Hu, Xu Lan and Liu Ying"},
	{"id": "s_p14_mirror", "kind": "talk", "npc": "judge_cui", "area": "wheel", "t": "Go back down to the Wheel and ask Judge Cui what else the Karma Mirror shows"},
	{"id": "s_p14_grudges", "kind": "grudges", "n": 6, "area": "wheel", "t": "Lay to rest the six grudges that stayed where they fell, in any order (Esc > Journal)", "stones": 12000},
	{"id": "s_p14_nie", "kind": "kill", "boss": "nie", "area": "wheel", "t": "Face Nie, the Unpaid, at the heart of the Wheel", "stones": 22600},
	{"id": "s_p14_end", "kind": "talk", "npc": "elder", "area": "sect", "t": "Go home: every debt is paid, one way or another"},
	{"id": "s_break19", "kind": "breakthrough", "to": 57, "t": "Let every cause meet its effect: Karma Fulfilled"},
	# ---- Part XV: The Thread She Never Had (the Lotus release).  Yue Ling's chapter: give her a past,
	# friends who remember her, and the first line of a life of her own (bonds.gd)
	{"id": "s_p15_home", "kind": "talk", "npc": "elder", "area": "sect", "t": "Nobody can remember Yue Ling's name: speak to Elder Qing Xuan", "stones": 23000},
	{"id": "s_p15_pond", "kind": "share", "spot": "mem:mem_pond", "area": "sect", "t": "Sit with Yue Ling by the lotus pond where she woke, at the foot of the courtyard"},
	{"id": "s_p15_judge", "kind": "talk", "npc": "judge_cui", "area": "wheel", "t": "Go down the funeral road and ask Judge Cui why the Book of Life and Death has no page for her"},
	{"id": "s_p15_hunt", "kind": "hunt", "area": "grave", "n": 16, "of": ["loose_thread", "forgetting_moth", "unweaver_shuttle"], "t": "Drive off the things unpicking the Founder's weave in the Graveyard of Sword Saints"},
	{"id": "s_p15_founder", "kind": "talk", "npc": "qing_lian_echo", "area": "grave", "t": "Find the Founder's echo beside her barrow in the Graveyard of Sword Saints"},
	{"id": "s_p15_loom", "kind": "share", "spot": "furn:mountain:lotus_hermitage:2", "area": "mountain", "t": "Go up to the Founder's Hermitage under the Last Cave on the mountain, and sit with Yue Ling at the loom she was woven on"},
	{"id": "s_p15_memories", "kind": "memories", "n": 6, "area": "grave", "t": "Give Yue Ling back six of the seven memories the Founder pressed where she was happiest, in any order (Esc > Yue Ling)"},
	{"id": "s_p15_moth", "kind": "kill", "boss": "forgetting_queen", "area": "silk", "t": "Find what woke the moths: the Moth-Queen of Forgetting in the Mulberry Silk Woods"},
	{"id": "s_p15_unweaver", "kind": "kill", "boss": "unweaver", "area": "loom", "t": "Stop the Unweaver winding her threads back at the Loom of Borders"},
	{"id": "s_p15_threads", "kind": "threads", "npcs": ["qiu_ye_end", "tala_end", "hu_end", "xu_lan_end", "liu_ying_end", "alchemist", "archivist", "mazu", "meng_po", "smith", "granny_wen"], "n": 5, "area": "sect",
		"t": "Ask five of the people who knew her to tie a thread for Yue Ling, in any order: her friends, Alchemist Mo, Smith Tie, Archivist Lan, Granny Wen, Mazu, Meng Po"},
	{"id": "s_p15_warden", "kind": "kill", "boss": "lock_warden", "area": "mountain", "t": "Face Suo, Warden of the Lock, under the Founder's Last Cave on the mountain", "stones": 23600},
	{"id": "s_p15_name", "kind": "share", "spot": "mem:mem_pond", "area": "sect", "t": "Go back to the lotus pond with Yue Ling: there is a page in the Book of Life and Death with her name on it"},
	{"id": "s_p15_end", "kind": "talk", "npc": "elder", "area": "sect", "t": "Tell the Elder: Yue Ling has written the first line of her life"},
	{"id": "s_break20", "kind": "breakthrough", "to": 60, "t": "Climb the last step together: Kindred Dao"},
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
	"soul_lantern": {"n": "Soul Lantern", "desc": "Quest item"},
	"memory_pearl": {"n": "River Pearl of Memory", "desc": "Quest item"},
	"forget_herb": {"n": "Herb of Forgetting", "desc": "Quest item"},
	"wheel_spoke": {"n": "Spoke of the Wheel", "desc": "Quest item"},
	"silver_thread": {"n": "Silver Thread", "desc": "Quest item"},
	"needle": {"n": "Needle General's Needle", "desc": "Keepsake"},
	"tea_bud": {"n": "Dragon-Well Tea Bud", "desc": "Quest item"},
	"cocoon": {"n": "Soul-Cocoon", "desc": "Quest item"},
	"shuttle": {"n": "Shuttle of the Loom", "desc": "Quest item"},
	"river_star": {"n": "Drowned Star", "desc": "Quest item"},
	"magpie_plume": {"n": "Bridge Plume", "desc": "Quest item"},
	"star_thread": {"n": "Thread of Starlight", "desc": "Quest item"},
	"kunlun_peach": {"n": "Peach of Kunlun", "desc": "Quest item"},
	"magpie_badge": {"n": "Magpie Marshal's Badge", "desc": "The Crow Marshal's badge, given back to the magpies"},
	"noon_ember": {"n": "Noon Ember", "desc": "Quest item"},
	"rain_stone": {"n": "Rain-Stone", "desc": "Quest item"},
	"sun_feather": {"n": "Sun-Feather", "desc": "Quest item"},
	"osmanthus": {"n": "Moon-Osmanthus Blossom", "desc": "Quest item"},
	"tenth_arrow": {"n": "The Tenth Arrow", "desc": "Taken from Hou Yi's quiver so that one sun would live. Never shot"},
	"carp_scale": {"n": "Dragon-Gate Scale", "desc": "Quest item"},
	"xirang": {"n": "Clod of Swelling Earth", "desc": "Quest item"},
	"cauldron_shard": {"n": "Cauldron Shard", "desc": "Quest item"},
	"pillar_stone": {"n": "Stone of Mount Buzhou", "desc": "Quest item"},
	"river_tablet": {"n": "He Bo's Flood Tablet", "desc": "The River Earl's tally of every flood since Yu's day"},
	"cauldron_map": {"n": "Rubbing of the Ninth Cauldron", "desc": "The land as Yu drew it, every bay and bend, before the Court squared it off"},
	# ---- Part XI
	"wind_bell": {"n": "Storm-Torn Wind Bell", "desc": "Quest item"},
	# ---- Part XII
	"name_slip": {"n": "Slip of the Thousand Names", "desc": "A bamboo slip with names on it, carved by one hand: Quest item"},
	"pearl_dew": {"n": "Dew of the Pearl Trees", "desc": "Quest item"},
	"jingwei_stone": {"n": "Jingwei's Stone", "desc": "A pebble from the western hills, worn smooth by a beak: Quest item"},
	"xufu_log": {"n": "Page of Xu Fu's Logbook", "desc": "Quest item"},
	"longbo_hook": {"n": "The Longbo Giant's Hook", "desc": "A fish-hook the size of a plough, bent straight. Old Gui of the turtles will want to see it."},
	"shift_horn": {"n": "Yu Qiang's Conch of the Shifts", "desc": "The horn that calls the turtles to change places under the isles."},
	"half_fruit": {"n": "Xu Fu's Unripe Fruit", "desc": "A pearl-tree fruit picked green two thousand years ago, with one bite out of it."},
	"mainland_earth": {"n": "A Handful of Mainland Earth", "desc": "Soil from the Unbroken Land in a twist of cloth. The Thousand Children have never stood on it."},
	"cloud_tea": {"n": "A Cake of Cloud-Tea", "desc": "Dragon-Well tea from the terraces below the mountain. The immortals of the isles have not tasted new tea for two thousand years."},
	"gate_key": {"n": "Key of the Gate of Heaven", "desc": "Quest item"},
	"spring_water": {"n": "Vial of the Nine Springs", "desc": "Quest item"},
	"soul_tally": {"n": "Soul-Tally of the Dark Capital", "desc": "Quest item"},
	"heaven_tablet": {"n": "Chong's Jade Tablet", "desc": "The tablet Chong held heaven up with for four thousand years. It is lighter than it looks, and heavier than it feels"},
	"earth_weight": {"n": "Li's Iron Weight", "desc": "The weight Li pressed the earth down with since the ladder was cut. Still warm"},
	# keepsakes the peoples of the other realms are fond of (gifts: see RACES)
	"wutong_seed": {"n": "Seed of the Wutong Tree", "desc": "A phoenix-tree seed. The Feathered Folk say a phoenix will only land on a wutong"},
	"night_pearl": {"n": "Night-Shining Pearl", "desc": "It glows in the dark. Dragons cannot leave one alone"},
	"peach_wine": {"n": "Jar of Peach-Blossom Wine", "desc": "Foxes will forgive almost anything for a jar of this"},
	"moon_lotus": {"n": "Pressed Moon Lotus", "desc": "A lotus that opened in moonlight, pressed flat. The Pearl-Weepers have never seen the moon"},
	"autumn_leaf": {"n": "Pressed Autumn Leaf", "desc": "A red maple leaf. The Deathless love anything that ends"},
	"ancestor_incense": {"n": "Ancestor Incense", "desc": "Sweet incense for the dead. The shades can smell it from the bottom of the world"},
	"stones": {"n": "Cache of Spirit Stones", "desc": "Someone's savings"},
	"bell": {"n": "Ox-Head's Iron Bell", "desc": "It once rang every soul down the funeral road"},
	"feather": {"n": "Thunder Roc Feather", "desc": "Proof of the Roc's defeat"},
	"scale": {"n": "Dragon King's Scale", "desc": "Proof of the Dragon King's gratitude"},
	"brush": {"n": "Registrar's Broken Brush", "desc": "The brush that wrote the Ledger, snapped in two"},
	# ---- many roads (trials.gd): the essences monsters leave behind, worked at the cauldron and the forge
	"ess_wood": {"n": "Wood Essence", "desc": "Green qi wrung from a fallen beast of wood. Alchemists, smiths and gardeners want it"},
	"ess_fire": {"n": "Fire Essence", "desc": "A spark that will not go out, left by a beast of fire. Stoves and furnaces love it"},
	"ess_water": {"n": "Water Essence", "desc": "Cold, clear qi left by a beast of water. It sweetens wells and wakes still pools"},
	"ess_earth": {"n": "Earth Essence", "desc": "A heavy grain of qi left by a beast of earth. It knits stone and feeds soil"},
	"ess_thunder": {"n": "Thunder Essence", "desc": "It crackles in the hand. Left by a beast of thunder"},
	"ess_dark": {"n": "Yin Essence", "desc": "Cool, quiet qi left by a creature of the dark. The dead can smell it"},
	"ess_metal": {"n": "Metal Essence", "desc": "Hard bright qi left by a fighter of iron and bone. It remembers its shape"},
	# ... and what they make: the keys to the trials
	"smoke_pellet": {"n": "Smoke-Pellets", "desc": "Spirit herb rolled in wood essence. Crack one and a hillside disappears in green smoke"},
	"grounding_rod": {"n": "Grounding Rod of Frost Jade", "desc": "Two Frost Jades in a rod of thunder essence. Lightning goes into it instead of you"},
	"thunder_seal": {"n": "Thunder-Seal Talisman", "desc": "Thunder Shards sealed in a paper talisman. A demon cannot feed on its palace while it burns"},
	"tide_ward": {"n": "Tide-Pearl Ward", "desc": "Two Dragon Pearls in water essence. It carries a little of the sea wherever you go"},
	"bearer_incense": {"n": "Incense of the Twenty Bearers", "desc": "Saint Relics burned with Yin essence. In its smoke the dead see your own face"},
	"court_seal": {"n": "Counter-Seal of the Jade Court", "desc": "Two Jade Seals cut backwards. Every stamp it touches lifts off the page"},
	"glowcap_lantern": {"n": "Ember-Cap Lantern", "desc": "Ember Glowcaps in fire essence: a warm flame, the way fire used to be"},
	"memory_abacus": {"n": "Abacus of River Pearls", "desc": "Pearls of Memory on an abacus. Everything it counts, it remembers by name"},
	"tea_smoke": {"n": "Smoke of Dragon-Well Tea", "desc": "Tea buds roasted over water essence. Silk will not hold while it lasts"},
	"marshal_orders": {"n": "Orders Sealed in Plumes", "desc": "A commander's seal of magpie plumes. A soldier with no orders cannot refuse new ones"},
	"rain_charm": {"n": "Charm of the Rain-Stones", "desc": "Rain-Stones in wood and earth essence. Wherever it rests, the ground stays damp"},
	"yu_plan": {"n": "Yu's Plan of the Channels", "desc": "The channels Yu dug, drawn in swelling earth and flood-water. A father can read it"},
	"heaven_prop": {"n": "Prop of the Gate's Keys", "desc": "Two Keys of the Gate of Heaven forged into a prop strong enough to hold up the sky for a while"},
	"dew_flask": {"n": "Flask of Pearl-Tree Dew", "desc": "Dew of the pearl trees in wood essence. One sip calms a head"},
	"unmaking_sigil": {"n": "Counter-Sigil of the Gate", "desc": "Two Heaven Sigils beaten backwards on the anvil. It unseals what the Court sealed"},
	"rune_lantern": {"n": "Rune-Lantern of the Origin", "desc": "Its light cannot be swallowed, and in it a hunger shows its seams"},
	"forget_ink": {"n": "Ink of the Unwritten", "desc": "Immortal Peach steeped in water essence. Whatever it touches comes up blank"},
	"five_lens": {"n": "Five-Coloured Lens", "desc": "Ground from two of Nuwa's stones. Through it even a faceless thing has a weakness"},
	"mercy_lotus": {"n": "Paper Lotus of Mercy", "desc": "Folded from Spokes of the Wheel. It carries a plea where no living voice can go"},
	"loom_scissors": {"n": "Silver Scissors of the Loom", "desc": "They cut a thread without cutting what it is sewn to"},
	"peach_talisman": {"n": "Peach-Pit Talisman", "desc": "The pit of a Kunlun peach in wood essence. Plague-stars shy away from it"},
	"moon_mirror": {"n": "Osmanthus Moon-Mirror", "desc": "Silver and moon-osmanthus. It shows a sun her own face, cooled"},
	"dyke_charm": {"n": "Charm of Swelling Earth", "desc": "Two Stones of Mount Buzhou in a charm. Thrown, it raises a dyke across anything"},
	"root_lantern": {"n": "Root-Lantern of the Dark Capital", "desc": "Soul-Tallies burning in fire and Yin. It lights the underside of the world"},
	"fleet_compass": {"n": "Compass of the Lost Fleet", "desc": "Bound from two pages of Xu Fu's log. Its needle points home"},
	"drought_fan": {"n": "Fan of Nuba's Drought", "desc": "Noon Embers in a fan of fire essence. One sweep turns a storm to steam"},
	"clear_mirror": {"n": "Mirror of Clear Sight", "desc": "Polished from Jingwei's stones. It shows only what is really there"},
	"kui_drumstick": {"n": "Drumstick of the Thunder-Beast", "desc": "Whoever holds it decides when the drum of Kui's hide is struck"},
	"settled_mirror": {"n": "Mirror of Settled Debts", "desc": "Two spokes of the Wheel forged into a mirror with dark and metal essence. A debt that looks into it remembers whether it was ever owed"},
	# Part XV (the Lotus release)
	"pressed_petal": {"n": "Pressed Petal", "desc": "A lotus petal the Founder pressed a memory of Yue Ling's into, given back. It smells of whichever summer it was"},
	"lotus_shuttle": {"n": "Shuttle of Pressed Petals", "desc": "A weaver's shuttle Alchemist Mo made of pressed petals and wood essence. Whatever unweaves, it weaves back"},
	"open_key": {"n": "Key of the Open Door", "desc": "Smith Tie's key with no lock: two pressed petals beaten into bronze with metal and dark essence. It opens what is shut by leaving it open"},
	"homing_elixir": {"n": "Elixir of Coming Home", "desc": "Five essences and an autumn leaf, refined for a fortune. It smells of fields a war god has not seen in five thousand years"},
}
const TEMPER_COST := [250, 700, 1500, 2800, 4500, 6500, 9000, 12000]
## keepsakes dropped by particular bosses (so later dialogue can point at them)
const BOSS_DROPS := {"thunder_roc": "feather", "dragon_king": "scale", "registrar_siming": "brush", "ox_head": "bell", "needle_general": "needle", "crow_marshal": "magpie_badge", "jinwu": "tenth_arrow", "he_bo": "river_tablet", "taotie": "cauldron_map", "chong": "heaven_tablet", "li": "earth_weight", "longbo_giant": "longbo_hook", "yu_qiang": "shift_horn", "xu_fu": "half_fruit"}

static func pill_price(kind: String, level: int) -> int:
	return (24 + 5 * level) if kind == "hp_pill" else (20 + 4 * level)

# ---------------------------------------------------------------- daos (Part XI)
## The roads a cultivator may walk now that the Court's one Dao (obedience) is gone.  Lin Feng
## chooses one when the Jianmu grows back and may change roads at any Dao Stele; each keeps its own
## mastery (DAO_TIERS points from battles won while walking it: Novice, Adept, Master), each has a
## passive that grows with mastery (DAO_MODS) and a technique of its own from Adept on, and each is
## honoured by one of the peoples of the realms (RACES).
const DAOS := {
	"sword": {"n": "Dao of the Sword", "motto": "A blade has one direction: forward.", "skill": "myriad_swords", "col": Color("a8d8ff"),
		"desc": "Lin Feng's single-strike techniques hit harder, and his plain sword strike much harder."},
	"wander": {"n": "Dao of Free Wandering", "motto": "The Peng rises on a wind of ninety thousand li, and goes where it likes.", "skill": "peng_wind", "col": Color("b8f0d0"),
		"desc": "Lin Feng acts sooner, and now and then the party slips a blow entirely."},
	"heart": {"n": "Dao of the Compassionate Heart", "motto": "Hold the sky only as long as you choose, and ask for help.", "skill": "lotus_heart", "col": Color("ffb0c8"),
		"desc": "Every heal is stronger, the party takes a little less harm, and Lin Feng's wounds close by themselves."},
	"formation": {"n": "Dao of Formations", "motto": "The land keeps its shape because it is allowed to.", "skill": "bagua_array", "col": Color("e8c870"),
		"desc": "The party takes much less harm from every blow."},
	"alchemy": {"n": "Dao of the Cauldron", "motto": "Every pill is borrowed time. Borrow wisely, and for others.", "skill": "nine_turn", "col": Color("ff9a50"),
		"desc": "Pills do far more good, victories pay more spirit stones and techniques cost less qi."},
	"illusion": {"n": "Dao of the Mirror", "motto": "The moon in the water is still the moon.", "skill": "mirror_moon", "col": Color("c8a8ff"),
		"desc": "Foes strike at reflections and miss, and their weaknesses cut deeper."},
}
const DAO_ORDER := ["sword", "wander", "heart", "formation", "alchemy", "illusion"]
## mastery points needed for each rank (a battle won while walking the Dao is one point, a boss four)
const DAO_TIERS := [0, 12, 40]
const DAO_RANKS := ["Novice", "Adept", "Master"]
## Dao passives by rank (Novice, Adept, Master).  one: Lin Feng's single-target techniques; strike:
## his plain sword strike; spd: his speed; evade: the chance the party slips a blow; heal: heals and
## healing pills; regen: Lin Feng's wounds close by this share of his health each turn; taken: the
## harm the party takes; pill: what pills restore; stones: spirit stones won; qi: technique costs;
## miss: the chance a foe strikes a reflection; weak: how deep a weakness cuts (normally 1.5).
const DAO_MODS := {
	"sword": {"one": [1.15, 1.22, 1.3], "strike": [1.5, 1.6, 1.7]},
	"wander": {"spd": [3.0, 5.0, 7.0], "evade": [0.07, 0.1, 0.14]},
	"heart": {"heal": [1.2, 1.3, 1.4], "regen": [0.03, 0.04, 0.05], "taken": [0.96, 0.94, 0.92]},
	"formation": {"taken": [0.88, 0.84, 0.8]},
	"alchemy": {"pill": [1.6, 1.8, 2.0], "stones": [1.25, 1.35, 1.5], "qi": [0.92, 0.88, 0.85]},
	"illusion": {"miss": [0.07, 0.1, 0.13], "weak": [1.65, 1.75, 1.85]},
}

# ---------------------------------------------------------------- the peoples of the realms (Part XI)
## Who lives above, on and below the land.  Lin Feng's standing with each people grows with the help
## he gives them (quest steps and bosses in their lands) and with gifts of the keepsakes they love,
## and faster if he walks the Dao they honour; as a friend (FRIEND standing) a people grants a boon.
## Their people speak to his Dao in `dao_lines`.
const FRIEND := 50
const KIN := 100
const RACES := {
	"human": {"n": "Humans", "home": "The Unbroken Land", "dao": "sword", "gift": "", "boon": "", "boon_n": "",
		"desc": "The people of the Unbroken Land: farmers, ferrymen, cauldron-casters, sect disciples and cartographers. They hatch from nothing, fly not at all and die too soon, and they are the only people who ever cut the ladder to heaven down and then grew it back.",
		"dao_lines": {}, "thanks": ""},
	"yumin": {"n": "Yumin, the Feathered Folk", "home": "Featherfall, in Juntian", "dao": "wander", "gift": "wutong_seed", "boon": "spd", "boon_n": "Lin Feng acts sooner (+3 speed)",
		"desc": "The Feathered People of the Classic of Mountains and Seas: long heads, feathered bodies, born from eggs. They can fly, but not far, and they think that is the best joke in heaven. They nest round the crown of the Jianmu and honour the Dao of Free Wandering.",
		"dao_lines": {
			"sword": "A sword-walker. You cut straight lines through the sky; we have never understood straight lines. Mind you don't cut the wind.",
			"wander": "You walk the Wandering Dao! Then you already know: you can fly, but not far, and that is more than enough.",
			"heart": "The Heart's Dao. Our elders say a kind heart is a light heart, and a light heart glides further.",
			"formation": "Formations? Up here? Everything you draw, the wind rubs out by morning. We admire the effort.",
			"alchemy": "A cauldron-walker. Can you brew something for wing-ache? Asking for my whole family.",
			"illusion": "The Mirror's Dao. The foxes will like you. We are not sure we do. Is that really you?"},
		"thanks": "A wutong seed! We will plant it on the highest island. If a phoenix ever comes back, it will need somewhere to land."},
	"dragon": {"n": "Dragon-kin of the Rain Ministry", "home": "The Rain Ministry, in Juntian", "dao": "sword", "gift": "night_pearl", "boon": "atk", "boon_n": "Lin Feng hits harder (+6% attack)",
		"desc": "The dragon-kin who kept the rain for the Heavenly Court, a ledger for every cloud. With the Court gone they keep the Rain Ministry out of habit and pride, and honour the Dao of the Sword: one clean stroke, owed and paid.",
		"dao_lines": {
			"sword": "The Sword's Dao. Good. A dragon respects one clean stroke above a thousand clever ones.",
			"wander": "You wander? Rain does not wander. Rain falls where it is owed. ...Or it used to.",
			"heart": "Compassion. The Ministry had a column for it once. Nobody ever filled it in.",
			"formation": "Formations. Order. The Ministry approves, in triplicate.",
			"alchemy": "An alchemist. Dragon blood is not an ingredient, whatever the old recipes say.",
			"illusion": "The Mirror. Dragons do not care for tricks. Show me your true face before you speak."},
		"thanks": "A night-shining pearl. ...You may consider the Ministry in your debt. Do not tell anyone I said that."},
	"tianhu": {"n": "Tianhu, the Celestial Foxes", "home": "Changhe, the Gate of Heaven", "dao": "illusion", "gift": "peach_wine", "boon": "miss", "boon_n": "Foes miss a little more often",
		"desc": "Foxes who cultivated for a thousand years, grew nine tails and climbed into heaven. They keep the old Gate of Heaven mostly as a joke, and honour the Dao of the Mirror: the moon in the water is still the moon.",
		"dao_lines": {
			"sword": "So serious! A sword is only a straight line that forgot how to laugh.",
			"wander": "A wanderer. You could have been a fox, you know, with practice. A thousand years of it.",
			"heart": "The Heart. Oh, how sweet. We shall have to be very careful not to break it.",
			"formation": "Formations! Lovely. Nothing is more fun to walk through backwards.",
			"alchemy": "An alchemist. Do you have anything that tastes like peaches and makes the colours sing?",
			"illusion": "The Mirror's Dao! Are you a fox in disguise? Are WE foxes in disguise? Delicious."},
		"thanks": "Peach-blossom wine! You understand foxes better than foxes do. We forgive you for everything you have not done yet."},
	"jiaoren": {"n": "Jiaoren, the Pearl-Weepers", "home": "Tearwater, in the Nine Springs", "dao": "heart", "gift": "moon_lotus", "boon": "heal", "boon_n": "Every heal is 10% stronger",
		"desc": "The Pearl-Weepers of the black water under the world, whose tears turn to pearls and whose silk water cannot wet. They honour the Dao of the Compassionate Heart, which is why their tears are worth something.",
		"dao_lines": {
			"sword": "A sword. The black water remembers every blade ever dropped in it. Most of them were dropped in grief.",
			"wander": "You wander. The currents wander too, and they always come home.",
			"heart": "You walk the Heart's Dao. Then you know why we weep, and why the tears are worth something.",
			"formation": "Formations. The shades like those. We prefer songs: a song is a formation that moves.",
			"alchemy": "An alchemist. Please do not ask for our tears. Everyone asks for our tears.",
			"illusion": "The Mirror. The black water is a mirror too, but nothing in it is ever a lie."},
		"thanks": "A lotus that opened under the moon? I have never seen the moon. Now I have seen something it touched."},
	"deathless": {"n": "Deathless People", "home": "The root-groves of the Nine Springs", "dao": "alchemy", "gift": "autumn_leaf", "boon": "hp", "boon_n": "Lin Feng is hardier (+8% health)",
		"desc": "The black-skinned Deathless people of the old texts, who eat the fruit of the immortal tree under the roots of the Jianmu, drink from the red spring and never die. They love anything that ends, and honour the Dao of the Cauldron.",
		"dao_lines": {
			"sword": "A sword. We have watched ten thousand swordsmen go by. Every one of them was in a hurry.",
			"wander": "Wandering. When you have for ever, every road is short. Walk slowly anyway.",
			"heart": "The Heart. It breaks, you know. That is what makes it worth having. We would not know.",
			"formation": "Formations. Patience you can see. You would have made a good Deathless.",
			"alchemy": "The Cauldron's Dao! Then you know a pill is only time, folded small. We have too much of it to fold.",
			"illusion": "The Mirror. Illusions fade. Lucky things."},
		"thanks": "A leaf that ended in red. How beautiful. We will keep it for ever, which is exactly the wrong thing to do with it."},
	"shade": {"n": "Shades of Youdu", "home": "Youdu, the Dark Capital", "dao": "formation", "gift": "ancestor_incense", "boon": "taken", "boon_n": "The party takes 6% less harm",
		"desc": "The shades of Youdu, souls not yet ready to be reborn, keeping house in the Dark Capital under Sovereign Earth. They are pale, polite and never late, and honour the Dao of Formations: every lantern in its place.",
		"dao_lines": {
			"sword": "A sword. The living are always holding something sharp. Do sit down.",
			"wander": "Wandering. Half the shades in Youdu wandered here by accident. Mind you can find the way back.",
			"heart": "The Heart. The living feel things so loudly. We can hear you from three streets away.",
			"formation": "Formations! At last, a visitor who understands lines. The magistrate will want to meet you.",
			"alchemy": "An alchemist. An elixir of life is a very rude thing to bring into a city of the dead.",
			"illusion": "The Mirror. In Youdu nobody casts a reflection. You may find that restful."},
		"thanks": "Incense... somebody up there still remembers. Every shade in the street will smell it and feel remembered too."},
	# ---- Part XII: the peoples of the Isles of the Eastern Sea
	"qianzi": {"n": "The Thousand Children of Landfall", "home": "Landfall, on Penglai", "dao": "heart", "gift": "mainland_earth", "boon": "stones", "boon_n": "Lin Feng finds more spirit stones (+10%)",
		"desc": "The grandchildren's grandchildren of the three thousand boys and girls Xu Fu brought from Qin to fetch the elixir, who were left on Penglai when he did not come back. Mortals on the isle of the immortals for two thousand years, inside a mirage nobody could sail out of; they took care of one another because there was nobody else, and honour the Compassionate Heart.",
		"dao_lines": {
			"sword": "A sword. Xu Fu carried a sword. We are not sure we like swords. ...Yours looks used for the right things.",
			"wander": "A wanderer! Oh, tell us where you have been. We have been here. All of us. For two thousand years.",
			"heart": "The Heart's Dao. That is ours, you know. When you are three thousand children on an island, you learn it or you starve.",
			"formation": "Formations. Teacher Qin will want to talk to you about the drainage. Everybody wants to talk to somebody about the drainage.",
			"alchemy": "A cauldron-walker. The immortals up the hill make elixirs. They never once offered us one. Make us a cough syrup and we will love you more.",
			"illusion": "The Mirror's Dao. We lived inside a mirage for two thousand years. You will forgive us if we pinch you."},
		"thanks": "Earth from the mainland. ...Our ancestors walked on this. We will put it in the Hall of the Thousand Names, and the children can touch it on their birthdays."},
	"xian": {"n": "The Immortals of the Isles", "home": "Fangzhang, the Square-Pot Isle", "dao": "wander", "gift": "cloud_tea", "boon": "exp", "boon_n": "every battle teaches a little more (+6% cultivation)",
		"desc": "The immortals who stayed on the Isles of the Eastern Sea when the Court hid them in a mirage: a beggar with an iron crutch, a girl with a lotus, an old man who rides backwards, a drunk with a sword and their friends. They grow elixirs nobody is allowed to eat and honour the Dao of Free Wandering, which, on an island, takes imagination.",
		"dao_lines": {
			"sword": "A sword-walker. Lu Dongbin will want to drink with you. Do not let him pay; he pays in poems.",
			"wander": "Free Wandering! At last, a sensible guest. Where shall we go? Nowhere, it turns out: island. But we can wander in circles together.",
			"heart": "The Compassionate Heart. The Thousand Children will adore you. We are trying to be adorable too, after two thousand years of being aloof. It is hard.",
			"formation": "Formations. Very tidy. Zhang Guolao says the isles are a formation, and the turtles are the pegs. He is old, but he is usually right.",
			"alchemy": "The Cauldron's Dao. Come and see the furnaces. They are cold. Do not touch anything that is still warm.",
			"illusion": "The Mirror. Shen the clam-dragon would have liked you. Everything she ever made was a beautiful lie."},
		"thanks": "Cloud-Tea! New tea! Do you know how long it has been? Han Xiangzi, put the water on. No, the good water. No, the other good water."},
}
const RACE_ORDER := ["human", "yumin", "dragon", "tianhu", "jiaoren", "deathless", "shade", "qianzi", "xian"]

# ---------------------------------------------------------------- dialogue
const CHAT := {
	"elder": ["The mountain wind carries the scent of blood. Stay vigilant.", "Cultivation is a marathon, disciple, not a sprint."],
	"alchemist": ["Pills are only borrowed time. Use them wisely.", "Hehe, my furnace never lies."],
	"smith": ["Steel remembers every blow. Bring me stones and I will temper your sword.", "A sword is only as sharp as its wielder's resolve."],
	"archivist": ["A sweeper who reads! Take anything off the lower shelves. The upper shelves bite.", "Mind the scrolls. Half of them are older than the Elder, and the other half are older than the sect.", "The Lotus Seal's barriers still stand at the borders of lands you have not earned yet. The road goes right up to them."],
	"niu_lang": ["Every seventh night of the seventh month the magpies came. This year the sky was empty, and then the river came down instead.", "The ox is gone now, but I still talk to him. He never minded.", "She weaves the sunsets, you know. That is why they have been grey."],
	"que_lao": ["Ten thousand magpies, wing to wing, and the Weaver walks across our backs. My back remembers every step.", "A bridge is only birds holding on to each other. Never forget that.", "Mind the cliff edge. Cloud is softer than it looks, but not that soft."],
	"zhi_nu": ["I have woven the dawn every morning for ten thousand years. I would like, just once, to watch someone else's.", "A thread is a road for a needle. A road is a thread for a traveller.", "He plays the flute badly. I can hear it from here. I have always been able to."],
	"dong_shuang": ["The peaches ripen once in three thousand years. Do not touch the ones that are humming.", "My lady drew the river with her hairpin because she was afraid. She has been afraid for a very long time.", "Kunlun is the pillar of the west. Everything up here is older than it looks, especially the tigers."],
	# ---- Part X: Cloudfoot, the post town at the foot of the mountain
	"cartographer_pei": ["A map is a promise you make to a stranger: this is where the road goes. The Court broke that promise in every square.", "Six rules of map-making: true scale, true direction, true distance, and the high, the low and the winding, each measured as they are. The Court kept none of them. It kept the squares.", "Every town has its own name for the same river. In Longmen it is the Old Man. In the Drowned Fields it is the Thief. In Yanggu they just call it Tea."],
	"postmaster_lu": ["Letters from all nine roads come through Cloudfoot. I am not supposed to read them. I only know who is in love with whom from the handwriting.", "Granny Wen in Qingshi Village writes to her nephew at the Starfall Ferry every week. He never writes back. I deliver the silence too.", "A letter to the Dawn Market takes four days. To the Jasper Pool, nine. To the Moon Palace nobody has worked out the postage, but Chang'e sends very nice thank-you notes."],
	"storyteller_wu": ["Sit, sit. Today's tale is the Weaver and the Cowherd. Tomorrow, the Ten Suns. The day after, whoever pays.", "Every story I tell, somebody from the sect comes down the mountain a month later and makes it true. I am thinking of telling one about a very large lunch.", "The old tellers said the earth was square because the sky is round, and the two must be different. The old tellers were paid by the Court."],
	"caravan_kang": ["Silk west, jade east, salt both ways. My camels know every road from the Desert of Fallen Stars to the Silk Woods.", "At Shazhou Oasis they charge a cup of water for a story and a story for a cup of water. A fair trade, in the desert.", "The roads bend now. My camels like it. Camels were never fond of right angles."],
	"priestess_yun": ["This is the shrine of Xiu, the Flood God's son, who loved roads so much that he died on one and became the god of them all. Leave him a cup of wine. He was a terrible traveller.", "Pray here before a journey and Xiu will walk a little way with you. He likes the company. He never knows the way.", "The Court gave every road a number. The roads never answered to them."],
	"stableboy_shitou": ["My name means stone. Ma says it was so the gods would think I was not worth stealing.", "The post-horses go up the mountain every morning and down every night. I ride the slowest one. His name is Lightning.", "When I grow up I will fly to the moon and back before supper. First I have to muck out the stables."],
	# ---- Longmen, the Dragon Gate ferry town
	"harbour_yao": ["The flood stele has a mark for every flood since Yu. My great-grandmother's is at the height of my head. Mine is above the roof.", "A ferry is a promise too. You get on at one bank and trust that the other one is still there.", "Pei and I have been arguing by letter for twenty years. One day I will marry him, just to have the last word."],
	"boatwright_gao": ["A boat is a house that has decided to travel. I build them the old way, without a nail, so they bend instead of breaking.", "Pine for the keel, camphor for the hull and a little prayer in the seams. Mostly pine.", "The river took six of my boats this spring. Next spring I will build seven."],
	"fishwife_lu": ["Carp, golden carp, the ones that did not quite make it over! Very lucky! Very fresh! Slightly disappointed!", "Never eat a carp with a pearl in its throat. That one was going to be a dragon.", "My husband was a ferryman for thirty years. He says he crossed the river eleven thousand times and never once stayed on the other side."],
	"lockkeeper_qian": ["Open the lock, shut the lock, let the water down a step at a time. A river is a staircase, if you are patient with it.", "Yu cut the gorge, but my family cut the locks. A smaller miracle, but you can do it on a Tuesday.", "The lock gates are carved with carp going up and dragons coming down. The dragons were my grandfather's idea. He liked a happy ending."],
	"shrine_hua": ["The River Earl used to demand a bride every spring, until Magistrate Ximen Bao asked whether the Earl would rather have his priests, and threw them in. There have been no brides since.", "We feed the river dumplings at the Double Fifth. It seems to like them better than brides. Everybody does.", "The temple bell rings the hours for the boats. While it lay in the river, the whole town was late for everything."],
	"scholar_cen": ["To pass the examinations is to leap the Dragon Gate, they say. I have failed seven times. I am beginning to sympathise with the carp.", "There is no emperor now and no Court, so there are no examinations. I am studying harder than ever. It is the principle of the thing.", "My essay this year was on the virtue of rivers that bend. The examiners would have hated it. I think it is my best."],
	"carp_boy_yu": ["I feed the carp every morning so they are strong enough to jump! This one is Pudding. He is going to be a dragon.", "My name is Yu, like Yu the Great! I have not tamed any floods yet. I tamed a goose.", "When the carp become dragons do they remember me? Ma says a dragon never forgets a free lunch."],
	"innkeeper_dong": ["The Leaping Carp Inn: every room faces the river, and this spring the river faces every room. Mind the buckets.", "Scholars on their way to the examinations used to stay here for luck. Now it is boatmen, and the occasional god.", "The best room is the one at the top. It has been dry for a whole week. I charge extra."],
	"bo_yi": ["Channels, not walls. Yu said it so often I hear it in my sleep. I sleep in a boat.", "I was with him when he passed his own door three times and did not go in. He waved at it. His wife waved back, the first time.", "The fields will be dry by harvest. Not because we stopped the water: because we let it go."],
	# ---- Tushan, the cauldron-casters' town
	"tu_lan": ["A cauldron is a bowl with a duty. It holds the meat for the ancestors and the map for the living.", "Bronze is copper that has made friends with tin. Remember that, when you are lonely.", "My clan has cast here since Yu. The pits never go cold, and neither do the arguments."],
	"caster_wei": ["I cast bells for every temple from Longmen to the Jasper Pool. A good bell is cast once and rings for ever. A bad bell is cast once and argues for ever.", "The secret of a bell is in the cooling. Hurry it and it cracks. The same is true of apprentices.", "When Tu Lan recasts the Ninth Cauldron the whole mountain will ring. I am cutting earplugs for everybody."],
	"carver_shi": ["Stone remembers better than bronze. Bronze can be melted down; a stele only waits.", "I carve the flood marks for the stele at Longmen. Every year they ask me to carve them a little higher. I have started charging by the inch.", "My family has swept the moss off the Stone Mother for a hundred generations. She has never once said thank you, but she smiles a little more each time."],
	"charcoal_tan": ["The casters need charcoal, the charcoal needs wood, the wood needs rain and the rain needs... you see why we pray so much in Tushan.", "Pine charcoal for the bells, oak for the cauldrons, peach-wood for luck. Mostly pine.", "My face is black from the kilns and my heart is gold from the profits. Tu Lan says it is the other way round."],
	"innkeeper_lou": ["The Inn of the Late Arrival, named for Fangfeng, who came late to Yu's assembly. Everyone here is late for something.", "Pilgrims climb the mountain to see the cauldron hall and stay for the noodles. The noodles are not historical, but they are very good.", "Do not mention the giant. When he walks past, the soup slops over."],
	"little_qi": ["My name is Qi, like the boy who was born from the stone. I was born from my ma, which is less interesting.", "I climb the Stone Mother every day. She does not mind. I asked.", "When I grow up I will cast a cauldron so big that the whole world fits in it. Then I will cast a lid."],
	"yinglong": ["I drew every river in the land with my tail. The crooked ones were the days I was tired.", "Do not swim in the black lake. It is not that it is cold. It is that it is listening.", "Yu used to say a river is only a long argument between a mountain and the sea. I always took the sea's side."],
	# ---- Part XI: the peoples of the realms above and below
	"ling_yu": ["We hatch from eggs, glide before we walk, and are told on our first birthday that we can fly, but not far. It is the best joke in heaven.", "The view from the top of the Jianmu is the whole world at once. It makes you very quiet, or very rude. I went for rude.", "Ground-walkers are slower than the stories said, and kinder. Do not tell anybody I said that."],
	"yu_hua": ["Every Yumin chick hears the wind bells before anything else. A bell says: the wind is safe, come out.", "I am four hundred years old and I have flown, at most, a li in a straight line. It was a very good li.", "The Court called us its feathered servants. We called the Court the noise under the clouds."],
	"yu_jian": ["An arrow is a feather that learned to be brave. I fletch mine with my own moulted feathers, which is either very thrifty or very strange.", "Feilian keeps letting the winds out of his bag. My arrows go everywhere except where I aim them.", "A ground-walker who climbed the Jianmu! You must have legs like a mule. No offence. Mules are much respected up here."],
	"egg_warden_luan": ["Shh. The eggs are listening. They hatch when the world sounds safe.", "Eighty-one eggs in the warm cellar, and every one of them has a name already. The names are very long. We have a lot of time.", "A chick peeps at the first face it sees. Mind you are not standing in front of the egg, or it will think you are its mother."],
	"que_er": ["I can fly! ...Not far. But I can!", "Is the ground really made of ground? All of it? Doesn't it get tired?", "When I grow up I am going to fly all the way down to the Unbroken Land and back. In one go. Maybe two goes."],
	"ao_qing": ["Every cloud has a page, every page has a column, and every column must balance. Or it did. Now I write poems in the margins.", "The Minister will not come up from the archive. Dragons sulk the way mountains sit: thoroughly.", "Rain without a signature. It sounds terrible. I think it might be wonderful."],
	"ao_run": ["Ten thousand years of ledgers and not one blot. I am very proud of that. It is the only thing I have ever been proud of, which worries me.", "A dragon who signs his own rain. My grandfather would have swallowed the Ministry whole.", "The Duke drums for my rain now. He is terrible at keeping time. The farmers love him."],
	"hu_qingyi": ["Nine tails, a thousand years to grow them all. Do not ask which is my favourite. All of them, darling.", "We hid the keys of the Gate of Heaven because we thought it would be funny. It was funny. It is still funny.", "The Court called us vermin, then it called us celestial. We are the same foxes, darling. We only got better at climbing."],
	"hu_meier": ["Moon-wine! One cup and you see the moon. Two cups, two moons. Three cups, you are the moon.", "I only have three tails. That is a great many years of not paying attention in class.", "If you meet a fox who looks exactly like you, do not worry. It is probably me."],
	"gate_fox_hu": ["I have kept this gate for six hundred years, ever since the last gatekeeper went home and forgot to tell anybody.", "Pixiu ate the gold off the gatehouse roof. I am trying to look on the bright side. The roof is lighter now.", "A gate is only a hole in a wall that somebody decided to be polite about."],
	"shui_lian": ["When a Jiaoren weeps, the tears turn to pearls. The traders above used to make us cry on purpose. Do not ask how.", "Our silk will not get wet. I wove a sail of it once. The boat sank anyway, out of pure spite.", "The roots of the world tree drink from the Nine Springs. When they are thirsty, the whole cavern sighs."],
	"hai_ge": ["I sing the tides of the black water. There are no tides down here, so I make them up. The water has started listening.", "A song is a formation that moves. The shades never understand that. The Deathless understand it too well.", "Wangxiang keeps muddying the springs. I wrote him a song. He pretends not to like it. He hums it."],
	"little_bei": ["I cried yesterday and it came out as grit! Mama says it is the water. I think I am broken.", "Is the moon like the Torch Dragon's eye? Mama says it is white and kind and nobody owns it.", "When I grow up I am going to swim all the way up a root and look at the sky. Just once."],
	"bu_si": ["I am four thousand and eleven. Or twelve. After the first thousand you stop counting and start guessing.", "The fruit of the immortal tree tastes of nothing, for ever. I would give a great deal for a bad apple.", "Sit down. Whatever you are hurrying towards will still be there. Everything always is, down here."],
	"chang_sheng": ["I tend the groves on the roots. The fruit never spoils, the trees never die and the weeds never stop. A gardener's paradise and a gardener's punishment.", "We trade the Pearl-Weepers our fruit for their songs. A fruit lasts for ever and a song is over in a minute. We get the better bargain.", "My grandmother was here when the ladder was cut. She is still here, in the grove, complaining about the light."],
	"ming_yi": ["Every shade in Youdu has a tally. Every tally has a place. Every place has a lantern. That is a city.", "The living are so untidy. They arrive with all their feelings still attached.", "I have never once been late. There is nothing to be late for down here, which makes it a point of pride."],
	"zhi_ma": ["Paper horses, paper houses, paper servants. The living burn them up above, and down here they arrive for the dead. I make the ones nobody burned.", "One of my horses ran away last week. It is somewhere in the streets, being made of paper at people.", "The best paper is mulberry bark. The worst is a tax form. You would be surprised how many of those come down."],
	"shade_lan": ["I lost my tally. I lost my name. Do you know who I am?", "The lanterns here never go out. I wish one would, just once, so I could see the dark.", "When I go back up to the Wheel, I want to be born somewhere with snow."],
	"houtu": ["Every soul you ever saw buried, I held. Every one of them was somebody's child.", "I am the earth. I do not mind being walked on. It is what I am for.", "Li is my child too, you know. Every god of the earth is. They never call."],
	# ---- Shazhou Oasis in the Desert of Fallen Stars
	"well_keeper_zhaya": ["A cup of the Sweet Well for a story, and a story for a cup. Nobody leaves Shazhou thirsty or bored.", "The well is older than the oasis. The stars that fell here melted the sand into glass, and the glass kept the water in.", "When the sky was falling, the nomads came in from the dunes to drink and watch. Ba Yin says she has never seen so many people looking up."],
	"cook_aysha": ["Lamb noodles, flatbread, and tea with salt in it. Do not make that face; you are in the desert now.", "Every caravan that comes in off the sand gets a bowl before it gets a bed. That is the rule of the caravanserai.", "Kang's camels eat better than his drivers. I have told him. He says the camels complain less."],
	"star_reader_kumar": ["I came from beyond the western mountains to read the stars that fell here. Forty years later I am still reading. They had a great deal to say.", "In my country we call the Dipper the Seven Sages. Since the nine suns rose, there are nine. I have had to rewrite every chart I own.", "Each fallen star left a crater, and each crater a little glass. Hold one up to your eye at night and it shows you where it came from."],
	"camel_boy_temur": ["That one bites, that one spits, and that one does both but only on Tuesdays. I know every camel in the yard.", "When I am grown I will lead a caravan all the way to the sea. Nobody in Shazhou has ever seen the sea. I am going to bring some back in a jar.", "The White Tiger used to sleep at the foot of the pillar. Now he comes to the well at dusk and drinks with the camels. They are not happy about it."],
	# ---- Part IX: the Dawn Market and the road to the moon
	"ah_mei": ["A lantern is a little piece of night you can carry about with you. My mother said that. She never said what to do when there is no night to carry it in.", "The pilgrims used to set out from here at dusk to climb the valley in the dark and watch the sun come up out of the Fusang. From the market you could see their lanterns going away across the plain like a river of little moons.", "Paper, bamboo, a candle and patience. Mostly patience. The candles are melting in their boxes."],
	"watchman_zhou": ["Third watch, and all is... noon. Still noon. I beat the hours anyway. Somebody has to keep count.", "Forty years I have walked these lanes with my gong and my lantern. Nine days now I have walked them in a straw hat. A watchman without a night is just a man with a gong.", "Dry weather, mind your fires! ...That one, at least, I can still shout with a clear conscience."],
	"innkeeper_bao": ["Rooms by the night, two strings of cash. Nobody has paid for a night in nine days, on account of there not being one. I charge by the nap now.", "We used to be the Riverside Inn. I had the sign repainted on the fourth day. It seemed more honest.", "Everyone sleeps with a bowl over their face now. I sell the bowls. Business is business."],
	"tea_seller_pan": ["Hot tea? No? Iced tea, then. I have not got any ice. Hot tea.", "The ice-house keeper came by yesterday and wept into my teapot. Best cup I ever brewed. Bitter, with a long finish.", "In hot weather you drink hot tea, so you sweat, so you cool down. My grandfather swore by it. My grandfather never saw nine days of noon."],
	"dyer_su": ["Everything I dye fades by the afternoon, and it is always the afternoon. This was crimson on the first day. Now I am calling it sunset pink, for the customers.", "Indigo wants a cool vat and a dark cellar. My cellar is full of the innkeeper's guests.", "Sun-bleached silk, very fashionable this season. The whole season has been one very long day."],
	"monk_huiming": ["I chant the morning sutra at dawn and the evening sutra at dusk. For nine days I have chanted only the noon sutra. I am getting very good at it.", "The shrine bell rings by itself whenever the sun moves a hand's breadth. It has been silent for nine days. I listen to it anyway.", "Our shrine honours the Morning Sun, the youngest of Xihe's ten children, the one who was spared. The pilgrims say he was always the shy one."],
	"granny_gu": ["Grain keeps best in the cool and the dark. My granary is the last cool, dark place in Yanggu, and half the market is asleep in it. I charge them in millet.", "Sixty harvests I have kept this granary, and I never once wished for less sun. Be careful what you never once wish for.", "There is a statue of Hou Yi in the Archer's Hall with his bow drawn. The boys climb it, and the girls tell them to get down. That is how Yanggu has always kept time."],
	"porter_niu": ["I carry the pilgrims' baggage across the plain to the valley road, so they are fresh for the night climb. No nights, no pilgrims. I have been carrying my shadow about for practice. It is very light these days.", "I can carry two sacks of millet on each shoulder. I cannot carry the sun. I did ask.", "The farmers from the plains bring what grain is left to Granny Gu. It is a long walk with a very light load."],
	"little_dou": ["Mama says I can play until it gets dark. I have been playing for nine days.", "Want to see my shadow? It is under my feet. It lives there now.", "When I grow up I am going to be an archer like Hou Yi and shoot the sun! ...Only a little bit. Just enough so that it goes to bed."],
	"farmer_tian": ["Plants do not grow in the sun, child. They eat in the sun. They grow in the dark, when nobody is watching. Same as children.", "Every morning I say the same prayer to the Lord of Millet: a little night, please, and a little rain if you have it. Hou Ji was a farmer before he was a god. He knows what I mean.", "Sixty harvests on this plain. Some years too wet, some years too dry. This is the first year it has been too much day."],
	"feng_meng": ["My master could split a hair at a hundred paces. I could split it at ninety-nine. You would not believe how much that one pace weighed.", "An archer's first lesson is to look where you are shooting. The last lesson is to look at what you are shooting. I only ever learned the first one.", "Do not stand under the Fusang with your mouth open. The sun-crows are messy eaters, and everything they drop is hot."],
	"chang_e": ["I swallowed the elixir so that a thief would not have it. Everyone tells the story as though I wanted to fly away. Nobody ever asks whether I wanted to come down.", "The rabbit pounds the elixir, Wu Gang chops the tree, and I walk the moon. We have all been doing the same thing for so long that we forgot it was a choice.", "From up here the world looks very small and very lit. I like to find the lanterns. Every lantern is somebody who is not asleep yet."],
	"granny_wen": ["You still sit like you did at six, all elbows. Eat something.", "I delivered half this valley. I know every one of them by their first cry, and three of them have gone quiet.", "A house is four walls and a door, child. The door is the important part."],
	"innkeeper": ["Rooms are free for anyone who cuts a thread off my roof. Nobody has taken me up on it yet.", "The tea comes down from the terraces. Or it did, before the hills were sewn up."],
	"weaver_liu": ["I weave for a living, and I tell you: whoever is sewing those threads is the best weaver who ever lived. And the angriest.", "Warp holds still, weft goes through. A cloth needs both. So does a village."],
	"tea_master": ["The first cup is for the guest, the second for the friend, the third for the road.", "Tea grows best on land that has been worked by many hands. So do people."],
	"can_niang": ["Silkworms eat for a month and spin for three days. Then they sleep in what they made. I always thought that was sad.", "Mind the cocoons. Some of them are breathing."],
	"apprentice_zhi": ["I swept the Loom for two hundred years. I think I know how you felt, sweeping your steps.", "Every border she ever sewed is written on this Loom. Most of them were kind, once."],
	"yue_ling": ["Let us go, Lin Feng.", "I will keep your wounds in check."],
	# the sect's own people
	"disciple_han": ["Three years I watched you sweep these steps and never once asked your name. I am asking now. Spar with me some morning?", "Footwork first, swordwork after. A blade is only as fast as the feet under it.", "The senior disciples spar at dawn in the Hall of Martial Practice. Sweepers are not invited. ...Come anyway."],
	"disciple_mei": ["The koi in the lotus pond know my footsteps and come to the edge when I walk past. They know you too, but they think you are a broom.", "Senior Brother Lin! Is it true you swept these steps for three years and never once missed a morning? I missed one. I am still sorry.", "I am not feeding the fish extra rice. They are just very round fish."],
	"cook_zhou": ["You came up this mountain thin as a broom handle and you are still thin. Sit. Eat.", "Cultivators think they can live on qi. They cannot. I have buried two who tried. Sit down.", "Good broth is like cultivation: patience, low heat, and never let anyone lift the lid."],
	"sweeper_bai": ["The Elder gave me your old broom. It still sweeps to the left. Did you do that on purpose?", "Three hundred and ninety-one steps. I counted. Did you ever count them?", "When I sweep I pretend the leaves are demons. I am undefeated."],
	"gate_wu": ["No one passes this gate without the Elder's leave. Except you. You come and go like the weather.", "Twenty years on this gate, and the worst thing through it was fog. I am told that is about to change.", "Mind the third step on the east road. It wobbles. I have reported it eleven times."],
	"bell_shen": ["I ring the hours so the mountain remembers what time it is. Somebody has to.", "A bell is struck and then it is quiet. The quiet is the part worth listening to.", "When you first came up the mountain you sat under my tower every evening to hear the bell. You will not remember. I do."],
	# Qingshi Village
	"farmer_lao": ["The rice does not care who rules the sky, so long as somebody remembers to send the rain.", "Granny Wen pulled me into the world too. She still tells everyone I came out complaining.", "A road through the hills all the way to the Loom, they say. My ox does not believe it either."],
	"child_hua": ["Is it true you can fly? Show me. Just a little. Just to the roof.", "When I grow up I am going to be a cultivator and a tofu seller. Both at once.", "Granny Wen says you were a crybaby. I am not a crybaby. I only cry at night."],
	"tofu_sun": ["Fresh tofu! Soft as a cloud, firm as a promise. The Innkeeper buys it all and says it is his own.", "I hear everything at this stall. The weaver is in love, the scholar failed again, and you saved the world. Twice.", "Spirit stones? No, no, a copper is plenty. Heroes always overpay and then prices go up for everybody."],
	"scholar_wang": ["I have failed the imperial examination six times. There is no emperor now, so I am taking it more seriously.", "Read this essay. No, the other one. No, never mind. Your face says enough.", "They say the old gates were stitched by a weaver. I always suspected the world had been edited."],
	"carpenter_gu": ["Half the roofs in this valley had threads through them. Mending the thatch, I keep finding needles.", "A good joint needs no nails. A good village needs no walls. I build doors, mostly.", "Stand back. That beam is heavier than it looks, even for an immortal."],
	"herb_lan": ["Mountain ginseng under the north pines, cloud-moss by the waterfall. Do not tell Alchemist Mo where.", "The herbs grow back faster since the land was made whole again. Everything does.", "I dried some for Granny Wen's knees. She says they taste like old shoes. She is right."],
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
	"nomad": ["The sand remembers every star that fell. Tonight it remembers too many.", "Water first, questions after. That is the desert's only law.", "My grandmothers dug the Sweet Well at Shazhou with their hands, in the glass the stars left. Drink there, and pay Zhaya a story. A good one."],
	"spore_witch": ["Do not breathe too deeply, little immortal. The vale dreams through its spores.", "Everything that rots feeds something that glows."],
	"steppe_shaman": ["The lights are the sky's breath. Lately it is breathing too fast.", "Walk where the herds walk. They know which ice will hold."],
	"nuwa_echo": ["I am only what is left of a promise. Be kinder to it than I was.", "Before the world there was no up and no down. Do not let the sky forget which is which."],
	"lantern_monk": ["A lantern is only a question: where are you going? The dead have forgotten the answer.", "Walk softly in the gorge. Every maple here was planted over someone."],
	"fisher": ["My birds fish for memories now. The river is thick with them, since the Wheel stopped.", "Nine bends, and every one of them remembers a different drowning. Mind your footing."],
	"meng_po": ["Soup? No? Wise. Not yet, little Sovereign. Not yet.", "Forgetting is not the cruel part. Being made to forget by someone who profits from it, that is the cruel part."],
	"qing_lian_echo": ["I am mostly a needle and a habit. Sit, if you like. Habits are good company.", "Every bearer thought he was the hero. Every one of them was right, for a little while. She was the one who stayed.", "I gave her a rose robe. I always meant to give her a better name, and then she chose her own, and it was better than anything I would have thought of."],
	"judge_cui": ["Every soul in the six paths has a page. I wrote most of them. I am trying to write them kindly now.", "The Wheel is not a punishment. It is a door. Doors are meant to open."],
	"peach_keeper": ["A peach of this garden ripens once in three thousand years. Do not waste it.", "The nineteen come here in their dreams. They like the shade."],
	# ---- Part XII: Fusang's shore and the Isles of the Eastern Sea
	"mazu": ["I was a fisherman's daughter once, on an island in the south. I dreamed my father's boat home through a storm, and woke, and kept doing it. That is all a goddess is: somebody who keeps doing it.", "Red is so they can see me from the sea. Nobody ever asks why a goddess wears red. Now you know.", "When the tide comes back, the first boat home gets a lantern lit for it on every cliff from here to the south. I have the lanterns ready."],
	"xu_qian": ["Every headwoman of Landfall has learned the Thousand Names by heart. I can say them in my sleep. My husband says I do.", "The mirage was like living inside a pearl. Beautiful. The same every day. I did not know how tired of beautiful I was until it lifted.", "If you see a boat from the mainland, tell it to come in slowly. We have never had visitors. We will over-feed them."],
	"teacher_qin": ["Name, father's name, village in Qin, age at landing. Three thousand times. The children chant it like a song. It is a song, really.", "The youngest child to land was two. Her name was Ah Lan. Every girl in Landfall has Lan somewhere in her name.", "I teach the children that Qin is a real place. They do not believe me. Can you blame them?"],
	"lu_dongbin": ["I was a scholar once and failed the examinations. Twice. Then I dreamed a whole life in the time it took a pot of millet to cook, and woke up, and stopped caring about examinations.", "My sword cuts ignorance, anger and desire. Mostly it cuts bread.", "Han Xiangzi plays his flute at dawn. Every dawn. For two thousand years. You may wonder why I drink."],
	"li_tieguai": ["My soul went wandering once, and while it was out my disciple burned my body, thinking I was dead. I came back to find a beggar's corpse to live in. I have grown fond of it.", "The gourd holds medicine. Mostly. Ask before you drink from it.", "Two thousand years with the same seven friends, on one island. You learn patience, or you learn to hide."],
	"lan_caihe": ["I sing in the street with one shoe off and a coat in summer. People throw coins. I give them away. It confuses everybody, which is the point.", "Life is a song you sing once. Sing it badly if you must, but sing it.", "The Thousand Children know all my songs. I am thinking of writing a new one. About a sweeper."],
	"han_xiangzi": ["My flute can make flowers open. It cannot make the sea come back. I have tried; the flowers opened.", "I play at dawn because the dawn is the only thing on Penglai that was ever different from one day to the next.", "Listen: that note is the wind over Yingzhou. That one is a turtle snoring. That one is me, out of tune."],
	"shipwright_ban": ["Every boat in Landfall is lying on the sand with its belly showing. I am using the time to scrape the barnacles. You have to be practical about the end of the world.", "My boats were built to sail inside the mirage, round and round. I would like, before I die, to build one that goes somewhere.", "Ban is short for Ban Gong, the carpenter of the gods. My grandmother was ambitious."],
	"ah_shui": ["A net with a hole in it still catches fish. A net that is all holes is a story. I mend the first kind and tell the second.", "When the water went, the nets came up full of things nobody has seen for two thousand years: coins from Qin, a sword, a child's shoe.", "Mend the small holes first. Nobody believes me until they have lost a big fish through a small hole."],
	"little_haibao": ["Are you from the mainland? Is it true the mainland does not move? How do you know where you are?", "Teacher Qin says I am descended from a boy called Haibao who was nine when he landed. I am nine too! We are basically the same person.", "I found a crab with a coin stuck to its back. I named it Emperor."],
	"pilot_zheng": ["Sixty years I piloted boats round the inside of the mirage. You learn every rock. Now the rocks are all standing up out of the sand, and they are much bigger than I thought.", "There is a channel to the east that never dried, where the sea runs into the Ruins. I would not pilot it. I would not pilot it for the Emperor himself.", "Mazu's boat came in through the haze like she knew every shoal. Of course she did. She has been watching us for two thousand years."],
	"diver_yulan": ["I dive for pearls on the reef. Now the reef is in the air, and I walk along it picking them like plums. It feels like cheating.", "The deepest pearls glow. The old divers say they are Jiaoren tears. I said that is a fairy tale, and then a Pearl-Weeper walked through Landfall last week asking for directions.", "Hold your breath long enough and the sea sings to you. It has stopped singing. I hope it is only resting."],
	"xu_fu_home": ["I have a grey hair. I keep looking at it. Two thousand years, and now it is the most interesting thing in the world.", "The Emperor wanted never to end. I wanted to please him. Neither of us thought to ask the children what they wanted.", "Teacher Qin has corrected my calligraphy. My own calligraphy, on my own slips. I did not know I had been doing it wrong for two thousand years."],
	"he_xiangu": ["I ate a pearl-tree peach when I was fourteen and a dream told me to. I have been fourteen in a way ever since. It is less fun than it sounds.", "The lotus I carry grows in mud and comes up clean. Nobody tells you the mud part.", "Cao Guojiu still bows to me every morning as if I were the Empress. I have asked him to stop for two thousand years."],
	"zhang_guolao": ["My donkey folds up like paper and I keep it in my sleeve. You may not see it. It is shy.", "I ride backwards. People laugh. Then the road turns, and they fall off, and I am still looking where I have been.", "I am older than the Court. I watched it come and I watched it go. Neither took very long, from where I sit."],
	"zhongli_quan": ["My fan can raise the dead and turn stones to gold. I mostly use it to cool my tea. Gold is heavy and the dead are argumentative.", "I was a general once. I lost a battle, walked into the mountains and found the Dao. Losing is underrated.", "Lu Dongbin was my student. He will tell you it was the other way round. He is wrong, and drunk."],
	"cao_guojiu": ["I was the Empress's brother and a minister of the Court. One day I looked at what the Court did with its ledgers, and I resigned, and walked into the sea. The sea brought me here.", "These castanets are my old court tablet, broken in two. Clack, clack. That is the sound of a ministry ending.", "If you meet anybody still loyal to the Court, tell them about me. There is life after a ministry."],
	"furnace_boy": ["Furnace-Boy is a title. I have been a boy for two thousand years. Do not ask how; the answer is a pill, and I was told not to touch it.", "Nine furnaces, all cold. I keep polishing them. When they light again, I want them to look nice.", "Master Zhang says an elixir is mostly patience. I said, then I must be the strongest elixir on the island. He laughed for a week."],
	"jingwei": ["Jingwei. Jingwei. That means: I am still here.", "The western hills have a little dip in them now, where I took the stones from. Four thousand years, one beakful at a time. Nobody notices a hill getting smaller.", "The sea is not wicked. It drowned me because I was in a little boat and it was a big sea. I know that now. I still do not like it."],
	"gui_lao": ["Every turtle has a tally, every tally has a shift. Nine tallies have said 'on duty' for forty thousand years. I have been sharpening my brush for the day I write 'resting'.", "I am a turtle too, you know. A small one. I carry the tallies, not an isle. Somebody has to.", "Eh? Speak into the left ear. The right one has been listening for the conch for forty thousand years, and it is tired."],
	"mist_fisher": ["I came over the sandbar from Landfall to fish the mist. You cannot catch anything in it, but you can think. My wife says I think too much.", "Sometimes the mist makes palaces. Sometimes it makes my old boat, sailing upside down. I wave. It waves back.", "Jingwei drops a stone on my head now and then. I think she is saying hello."],
	"steersman_hong": ["Starboard. Steady. ...It is a habit. Two thousand years at the wheel of a ship that does not move.", "Sixty ships out of Langya. Fifty-nine came to Penglai and stayed. One went over the edge. Mine.", "When the sea comes back, she will float again, I think. I would like to bring her home. I do not know where home is any more. Landfall, perhaps."],
	"ship_boy_ah_fu": ["I've been ten for two thousand years. It's mostly fine. You never have to go to bed early, because you never go to bed.", "Master Xu used to tell me stories about the Emperor's palace. Every night the same story, word for word. I know it by heart. So does he. He can't help it.", "When the sea comes back I'm going to learn to swim. I never did. I was going to learn on Penglai."],
	# ---- Part XII: more people in every town
	"xiao_qing": ["I came up the mountain because of the stories about you. Senior Brother Han says the stories are mostly true, and the true parts are worse.", "I sweep the east steps now. Little Bai sweeps the west. We race. The steps have never been so clean.", "Is it true the Founder left caves on the mountain that only open for the right realm? I sat outside the first one for a whole day. It did not open. I am only Qi Condensation."],
	"gardener_ruan": ["Spirit herbs grow best where somebody has been cultivating nearby. The patch under the dormitory window comes up twice as green as the rest.", "Alchemist Mo pays me in pills I never take. I have a jar of them. Do not tell him.", "The Founder planted the first herb bed with her own hands. Three hundred years of weeding since, and I am the eleventh gardener to do it."],
	"clerk_wei": ["I collected the land-tax for the Court for thirty years: so many years per square, payable in years. Then the squares went away, and then the Court. Then I learned to carry noodles.", "Do you know who checked the ledgers? Nobody. I just wrote numbers. I am very sorry about the numbers.", "Granny He pays me in noodles and lets me sit by the stove. It is the first honest work I have ever done, and the soup is better than anything the Court ever served."],
	"noodle_he": ["Noodles: one bowl, one copper, one story. You can skip the copper.", "I have fed every courier on every road for fifty years. You can tell what is happening in the world by what they order. When they all order the big bowl, something has gone wrong somewhere.", "Old Wu steals my best stories and tells them in his teahouse. I steal his and tell them back. Between us we have told the whole world twice."],
	"courier_ma": ["Nine roads, nine kinds of mud. I can tell where a man has been by his boots.", "I carried a letter from Granny Wen in Qingshi to the sect every month for three years. It always said the same thing: is he eating?", "Since the Jianmu grew back I have had to learn to deliver up a tree. The Feathered Folk write very short letters. They can fly, but not far."],
	"ox_herd_niu": ["My ox knows the way home better than I do. Some days I just follow him.", "When the Weaver's threads came down across the roofs, my ox ate one. It is still in him somewhere. He glows a little when he lies down.", "Granny Wen says you used to sit on our fence and watch the clouds as if you were looking for something. Did you find it?"],
	"teacher_ren": ["Forty children, one room, three brushes. We share. It is good practice for life.", "The Court's primers said the earth was square and the sky was round. I have crossed out 'square'. I have not decided what to write instead.", "Every child of Qingshi who goes out into the world signs my register when they come home. Sign it, Lin Feng. There are a great many empty pages."],
	"lantern_xi": ["In the nine days of noon nobody bought a lantern. Now the nights are back and I cannot make them fast enough.", "A lantern is a small sun that agrees to go out when you have finished with it. Very polite. Unlike some suns.", "I made one shaped like a sun-crow for the festival. The real sun-crows came down to look at it and were offended."],
	"archer_kong": ["This hall was built where Hou Yi practised. Every archer in the east comes here once, to stand where he stood.", "First lesson: look where you are shooting. Second lesson: look at what you are shooting. Feng Meng says most archers never learn the second.", "I could teach you to shoot. You would be terrible at it. You fight like somebody who has never wanted to be far away from anything."],
	"farida": ["Star-glass is the sand the falling stars melted. I blow it into cups. Drink from one and you can taste the night it fell.", "My grandmother came from beyond the western desert with a caravan, and stayed for the well. Everybody in Shazhou came for the well.", "When the nomads sang the stars home, some of them left their glass behind. I made a lamp of it. It never quite goes out."],
	"navid": ["Silk east, glass west, stories both ways. I have crossed the desert forty times. The desert has crossed me twice.", "In my country they say the sun is born in the east, in a valley with a great tree. I went to look. It was true. Nobody at home believes me.", "Since the Court fell there are no tolls on the roads. I sell everything for less and somehow make more. Your Court was a very expensive habit."],
	"examiner_fan": ["Nine times I sat the examinations, and nine times I failed. Then the Court fell, there were no more examinations, and I have never been happier.", "They say a scholar who passes has leapt the Dragon Gate. I have watched the carp. They do not leap for a certificate. They leap because they want to be dragons.", "I teach the ferry children to read. No examination, just reading. They are very good at it, and nobody has told them they are supposed to suffer."],
	"xia_cormorant": ["This is Hei. She fishes, I keep the fish. It is not fair, but she has never once complained.", "Before the land moved, the river ran backwards in its sleep. Hei knew. She would not fish for a week.", "Hei likes you. She does not like anybody. Do not move suddenly."],
	"bell_tuner_gong": ["Every bell has one true note and a hundred wrong ones. I file the wrong ones away, a hair at a time.", "Old Shen the bell-ringer at your sect wrote to me about his bell. He says it bows to you now. I have never heard a bell bow. I would like to.", "Tushan bells hang from Longmen to the Jasper Pool. If you ever hear one ring by itself, it is only remembering this town."],
	"auntie_rong": ["The pits have not gone cold since Yu's day. My mother tended them, and hers, back and back. We have never once let the fire out.", "When Tu Lan recast the cauldrons with the land as it really is, our casters cried. We had only ever cast squares.", "Bronze is copper and tin and patience. Mostly patience. The copper and tin are easy to find."],
	"ling_fei": ["I am a Yumin who cannot fly at all. Not even not far. My wings are for show. I am very good at walking.", "Ling Yu is my cousin. She won the race up the Jianmu. I came second, by the stairs, and nobody counted me.", "When you climbed the tree without wings, everybody in Featherfall turned and looked at me. I have never been so pleased in my life."],
	"ao_xun": ["Rain-Clerk, third grade. I copy out where the rain falls. The Minister signs it himself now. It is very irregular. I love it.", "For ten thousand years every cloud needed three signatures. Now it needs one. The other two clerks have taken up gardening.", "The Minister asked me to keep a ledger of things that are not owed. I have started. The first entry is your name."],
	"yao_silk": ["We weave a silk the water cannot wet. You dive in it and come up dry. It is the only way to the bottom of the black water and back.", "Little Bei's songs turn to pearls when she is sad. Lately she has been too happy to cry, and we are running short of pearls, and nobody minds.", "The silk takes a year to weave and a moment to tear. Like everything worth having."],
	"bu_lin": ["Fruit from the immortal tree: it never spoils. It never ripens either. You get used to it.", "I have traded fruit for songs with the Pearl-Weepers for four thousand years. I know every song in Tearwater and can sing none of them.", "Elder Bu Si is my grandfather. Or my great-grandfather. When nobody dies, you stop counting the greats."],
	"roll_clerk_ning": ["Every shade on a tally, every tally on a roll, every roll in order. The Magistrate says order is the one thing the dead can still have. I say it is the one thing I am good at.", "Since you found the four lost tallies there has not been one mistake on the rolls. I have checked eleven times. I will check again.", "Some shades ask to go up to the Wheel at once. Some ask to stay a little longer. Both are allowed now. It was not always so."],
	"lamplighter_bo": ["The lanterns of Youdu have never gone out. I have lit every one of them every night for six hundred years, just in case.", "One lantern for every shade still waiting. I count them as I light them, and every year now the count goes down a little. That is what the lanterns are for.", "When I am ready I will go up to the Wheel too, and somebody else will light the lanterns. I hope they talk to them. I always talk to them."],
	"hu_xiao": ["I have one tail! The Matron says it takes a thousand years to grow all nine. Old Hu says it took him longer, because he kept stopping for naps. Mei'er says it depends how often you laugh. Nobody will tell me the real sums.", "The Matron says the Gate is a joke. I asked what the joke was. She said I would understand when I had more tails.", "I was the one who hid a key of the Gate in the stone lion's mouth! Nobody believed I would. That is why it was funny."],
}

## What people will only tell a cultivator of a high enough realm (Part XII): [minimum level, line].
## Main.talk_npc adds them to the chat once Lin Feng reaches that level, so the higher he climbs the
## more of the world's history the townsfolk let him in on.
## Things people only say once the story has got there (Part XII fixed the sect's townsfolk talking
## about falling stars and Jade Emperors on Lin Feng's first morning): [quest step, line], added to their
## chat once that step is done.
const CHAT_LATER := {
	"archivist": [["s_p7_home", "The old maps drew every realm as its own island, stitched to the next by a gate. Look out of the window now: the roads simply run on."]],
	"disciple_han": [["s_elder2", "The juniors copy your stance now. Badly. Please stop standing like that near them."]],
	"disciple_mei": [["s_p8_home", "The koi have been very spoiled since the stars fell in the pond. I think one of them ate a star."], ["s_p6_home", "Senior Brother Lin! Everyone says you saved the sky. Twice. Is it heavy?"]],
	"cook_zhou": [["s_p4_home", "Immortals still get hungry. I fed four of them this week and every one asked for seconds."]],
	"gate_wu": [["s_p3_home", "Twenty years on this gate. Three demon lords, one Jade Emperor and a great deal of fog."]],
	"bell_shen": [["s_p5_home", "Lately the sky has needed reminding what time it is, too. I ring a little louder."], ["s_p13_home", "Eight bars of gold across the sky, and a dragon in the kitchen. I have rung this bell for forty years and never had such a week."]],
	# Part XIII: the gold bars in the sky, the gates and the Conclave
	"storyteller_wu": [["s_p13_home", "Eight gates and a war god! I have told the tale of Zhuolu for thirty years and always made the fog too short. A hundred days, the Elder says. A HUNDRED."]],
	"noodle_he": [["s_p13_home", "A dragon, a fox and a dead man came to my stall this morning for noodles. Nobody paid. The Conclave, they said. I said the Conclave can pay."]],
}

const CHAT_DEEP := {
	"elder": [[9, "Now that you are a Nascent Soul, I can tell you: my grandmother's grandmother was the Founder. She left nine caves on the mountain. I have opened one. You will open them all."], [24, "An immortal in my courtyard, sweeping. The Founder would laugh until she cried. She never thought the sect would last long enough to have one."], [42, "I used to think the Court was the shape of the world. It was only a very large hat."]],
	"alchemist": [[12, "Between ourselves: half my recipes come from the Founder's own notebook. The other half I made up, and those are the ones that work."], [30, "A Sovereign of the primordial realm buying healing pills from me. My furnace will be insufferable."]],
	"archivist": [[15, "The Sealed Archive has a shelf of letters from the nineteen bearers before you, Lin Feng. Most of them end mid-sentence. When you are ready, read them. They wanted to be read by somebody who got further."], [36, "The Court's maps have a blank square in the far east labelled 'nothing here'. The Court only ever wrote 'nothing here' over things it did not want found."]],
	"bell_shen": [[18, "The bell rings a little differently for you now. Lower. Like it is bowing. Do not tell anybody I said a bell can bow."]],
	"storyteller_wu": [[21, "A Mahayana cultivator listening to my stories! Very well, the true one, then: the sect's first disciple was a sweeper too. The Founder said she wanted somebody who would notice what was under the dust."], [45, "I have started telling your story. I change the ending every week. Nobody minds. They know you have not finished it."]],
	"cartographer_pei": [[27, "Off the record: the Court's survey had a sixth rule of map-making, 'leave out what cannot be taxed'. Look at their map of the east coast. The sea just stops."]],
	"granny_wen": [[18, "The Elder brought you down the mountain to me in a basket no bigger than a loaf. Now the whole valley bows when you walk past, and I keep wanting to tell them about the basket."]],
	"tea_master": [[30, "Tea from the high terraces tastes of the year it was picked. The immortals of the Eastern Isles used to trade for it, they say, before the Court hid the sea. Nobody has tasted that trade in two thousand years."]],
	"feng_meng": [[40, "My master Hou Yi shot nine suns down from the Fusang tree. He could have shot the tenth. He said: leave one, the world will need it. Sometimes I think the bravest arrow is the one you keep."]],
	"lu_dongbin": [[50, "A cultivator of your realm on Penglai. ...We stopped growing, you see. You did not. That is why you could do what we could not."]],
	"zhang_guolao": [[50, "Riding backwards, I can see a long way. The Court was a hiccup. The Ledger was a cough. You, I think, will be a sentence."]],
	"jingwei": [[50, "You are nearly as patient as a bird, now. Nearly."]],
	"houtu": [[48, "Every soul you sent me said thank you. The ones from the Eastern Sea, when they come, will say it in the accent of Qin. I am learning it now."]],
	"yu_hua": [[48, "Our eggs hatch to the sound of wind bells and, since you, to the sound of somebody sweeping the stair of the tree. The chicks think it is a lullaby."]],
}

const DIALOGUE := {
	"s_intro": [
		["Elder Qing Xuan", "Lin Feng. Three years you have swept the steps of Azure Cloud Sect, and three years your qi has refused to stir."],
		["Lin Feng", "Elder, I have tried every method in the scriptures."],
		["Elder Qing Xuan", "The Heavenly Lotus Seal that guards our mountain is failing. Xu Mo, Lord of the Blood Moon Palace, is coming for it."],
		["Elder Qing Xuan", "I sense something sleeping in your dantian. A root of the Nine Heavens, or a curse. Either way, the sect needs strength."],
		["Elder Qing Xuan", "Press Esc, choose Meditate, and let the spirit spring guide your breathing. Reach the Middle stage and return to me."],
		["Lin Feng", "I will not waste this chance.", "kneel"],
	],
	"s_report1": [
		["Elder Qing Xuan", "Your qi flows like a mountain stream at last. Splendid. And it flows from somewhere: something in your dantian has put out a shoot."],
		["Elder Qing Xuan", "The old books say the Nine Heavens root has nine branches, and that they wake one at a time: when the qi first stirs, at every Heavenly Tribulation, and in the nine caves the Founder sealed on this mountain, each of which opens only for a cultivator of its realm. Nobody in three hundred years has opened more than the third. Choose well which branch you wake."],
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
		["Ancestor Jian Wuchen", "Three hundred years I have waited for a disciple whose heart does not tremble at thunder."],
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
		["Sage Huo Rong", "The Void Rift lies beyond the volcano's western slope. Find Hermit Wu Ji. He knows what the Emperor is."],
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
		["Gatekeeper Bai Ze", "Then the heavens decide who deserves them. The Gate has opened for three, in ten thousand years. Remember that number."],
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
		["Yue Ling", "Lin Feng, your sword... and the lotus mark over your dantian, it is glowing. It has never done that before."],
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
		["Yue Ling", "Lin Feng... your dantian. Something green is growing there. A seed that is given is a seed that is planted, and the Hollow's dawn has planted one back in you, with every branch the old root had woken."],
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
		["Narrator", "Far below, Elder Qing Xuan watches the clouds turn gold. The Lotus Seal's chime, cracked since the day it was forged, rings clear and whole, and the first true morning in ten thousand years begins."],
	],
	# ---- Part VI: The Turning Wheel
	"recall4": [
		["Narrator", "For a whole season the mended sky holds. Then comes the night of the Ghost Festival, when the disciples set paper lanterns on the lotus pond to light the dead home."],
		["Narrator", "This year the lanterns do not drift away. They gather at the south-west gate, bobbing on the dark, as if waiting for someone to tell them where to go."],
		["Yue Ling", "Lin Feng... there are people standing among the lanterns. Old disciples, in robes I have only seen in the memorial hall."],
		["Elder Qing Xuan", "My own master is among them. He died forty years ago. He should have been born again long since."],
		["Narrator", "The dead are not haunting the mountain. They are standing in a queue that no longer moves."],
	],
	"s_p6_home": [
		["Elder Qing Xuan", "The Heavenly Court did not only prop up the sky with stolen years. It also turned the Wheel of Rebirth beneath the world. Every soul that went down to the Yellow Springs was weighed, taxed, and sent back up only when the Ledger allowed it."],
		["Lin Feng", "And we closed the Ledger. So the Wheel has stopped."],
		["Elder Qing Xuan", "Stopped, or been stopped. The dead are piling up at the Naihe Bridge, and the overflow is walking back up the old funeral road to the places where they were buried."],
		["Elder Qing Xuan", "That road begins at our own south-west gate. It runs through the Maple Gorge, where this sect has buried its dead for three hundred years, then down the river through the Stone Forest, to the fields of red lilies and the Wheel itself."],
		["Elder Qing Xuan", "And there is something I should have told you when you were small. I did not find you on our steps, Lin Feng. I found you in that gorge, wrapped in a sweeper's cloak, under a maple beside two fresh graves with no names on them."],
		["Lin Feng", "...My parents."],
		["Elder Qing Xuan", "I believe so. Xu Mo's hunters were already searching for the root's twentieth bearer. Whoever those two were, they hid you, and then they led the hunters away. I buried them where I found them."],
		["Elder Qing Xuan", "I left you with the village midwife below the mountain, where no hunter would look for a bearer. When a boy of thirteen climbed our steps three winters ago and asked for a broom, I knew you at once. So, it seems, did the Seal: that was the winter Yue Ling woke beside the pond."],
		["Yue Ling", "If the Wheel has stopped, then they never went on. They might still be waiting somewhere on that road."],
		["Lin Feng", "Then I am going to walk it. If they are standing in that line, I want to see their faces once before they go."],
		["Elder Qing Xuan", "I have unbarred the south-west gate. Take the funeral road, and find the Lantern Monk in the gorge. He has guided the dead down that road since before I was born."],
	],
	"s_mp_intro": [
		["Lantern Monk Jing Kong", "Two living cultivators on the funeral road, walking the wrong way. Amitabha. You must be the boy the Elder found under the maples."],
		["Lantern Monk Jing Kong", "Every soul that leaves this gorge carries a lantern, so it can see the road down. Since the Wheel stopped, the lanterns have been coming back up without them, lost and frightened, and the creatures of the gorge snap at them."],
		["Lantern Monk Jing Kong", "Gather four Soul Lanterns that have drifted from the graves. Bring them to me, and I will show you how to read where they were going."],
	],
	"s_mp_return": [
		["Lantern Monk Jing Kong", "Four lanterns, and none of them blown out. Hold them up, both of you. Look at the flames."],
		["Narrator", "Every flame leans the same way: downhill, towards the river, like grass in a current."],
		["Lantern Monk Jing Kong", "They all want to go down, and something keeps sending them back. The Fox, the Koi King and the Widow have grown fat on lost lanterns. And Ox-Head, the runner of the Ten Courts, stands at the bottom of the gorge with his iron bell."],
		["Lantern Monk Jing Kong", "One more thing. The two nameless graves the Elder told you of are under the oldest maple, past the falls. I tend them. Their lanterns never came back up. I do not know whether that is good news."],
	],
	"pre:nine_tail_fox": [
		["Narrator", "Nine tails of autumn fire fan out between the maple trunks. A fox the size of a pavilion smiles with far too many teeth."],
		["Nine-Tailed Fox of the Gorge", "Lanterns are so sweet, little Sovereign. Each one tastes of a whole life. Do you know how hungry the gorge has been since the Court stopped feeding it?"],
		["Yue Ling", "She is eating the way home. Do not let her charm you, Lin Feng!"],
	],
	"post:nine_tail_fox": [["Narrator", "The Fox's nine tails gutter out one by one, and nine stolen lantern flames float free and drift downhill, towards the river."]],
	"pre:waterfall_koi": [
		["Narrator", "Above the hanging falls a golden carp as long as a dragon boat hangs in the spray, swallowing every lantern that tries to tumble down."],
		["Lin Feng", "Every koi that climbs the falls becomes a dragon. You are trying to climb it on other people's lights."],
	],
	"post:waterfall_koi": [["Narrator", "The Koi King slides back into the pool with a sulky flick of his tail, and the lanterns pour down the falls like a river of stars."]],
	"pre:willow_widow": [
		["Narrator", "Under a weeping willow a woman in grey mourning silk sits combing hair that has grown into the branches. Lanterns hang tangled in it like fruit."],
		["The Willow Widow", "He said he would come back up the road. I am keeping the lights for him. If I let them go, he will not find his way."],
		["Yue Ling", "If you keep them, nobody will find their way. Not even him."],
	],
	"post:willow_widow": [
		["The Willow Widow", "...Then I will go down and look for him myself. Will you untangle me?"],
		["Narrator", "The lanterns slip out of the willow one by one, and the Widow walks after them down the road, lighter with every step."],
	],
	"pre:ox_head": [
		["Narrator", "At the foot of the gorge a giant with the head of an ox blocks the road, an iron bell in one fist and a chain in the other. Every time the bell rings, the dead below turn round and start back up."],
		["Ox-Head, Runner of the Ten Courts", "Back! Back up the road! The Wheel is closed by order of the King. No soul goes down until the King says so!"],
		["Lin Feng", "Then you are the reason the lanterns keep coming back. Put the bell down."],
	],
	"post:ox_head": [
		["Ox-Head, Runner of the Ten Courts", "Hoo... you hit like a falling pillar. Fine. Take the bell. I never liked ringing it. But the King will not open the Wheel because I lost a bell."],
		["Ox-Head, Runner of the Ten Courts", "My brother Horse-Face guards the river mouth. He is stubborner than I am. And he can count."],
		["Narrator", "Lin Feng takes Ox-Head's iron bell. Below the gorge the river bends nine times through a forest of stone, and the lanterns float down it in a long, slow line."],
	],
	"s_kr_intro": [
		["Cormorant Fisher Old Yu", "Mind the cormorants, they peck at qi. Ha. Look at that, they like you."],
		["Cormorant Fisher Old Yu", "The Nine-Bend River runs from the gorge down to the Yellow Springs. It used to carry the dead and nothing else. Now it is thick with memories. The dead are so tired of waiting that they have started dropping them."],
		["Cormorant Fisher Old Yu", "My birds bring them up as pearls. Dive me four River Pearls of Memory, and we will see whose they are."],
	],
	"s_kr_return": [
		["Cormorant Fisher Old Yu", "Four pearls. Hold one to your ear, boy. Go on."],
		["Narrator", "In the pearl a woman is singing a lullaby, and a man is laughing at how badly she sings it. A baby is crying. Somewhere, far off, a bell rings, and hunters are shouting."],
		["Lin Feng", "...I know that song. I have always known it. I thought I made it up."],
		["Cormorant Fisher Old Yu", "Then it is yours, and they dropped it here on purpose, for you to find. The river remembers who it is carrying. Follow it past the Tyrant, the Jiao and the Sentinel. Horse-Face waits where the river meets the springs."],
	],
	"pre:cormorant_king": [
		["Narrator", "A black cormorant with a crown of river-reeds rises from a stone pillar, a bright ring of fishing cord tight around its throat. It has swallowed so many memories it cannot fly straight."],
		["Yue Ling", "Someone collared it and never let it go. Loosen the ring, Lin Feng!"],
	],
	"post:cormorant_king": [["Narrator", "The cord snaps. The Tyrant coughs up a stream of glittering memories into the river and flies off, light and crooked and free."]],
	"pre:karst_jiao": [
		["Narrator", "The river coils into a whirlpool between two towers of stone, and a horned water-dragon rises in the middle of it, eyes white with confusion."],
		["Jiao of the Nine Bends", "So many voices in the water. Whose are they? Are any of them mine?"],
		["Lin Feng", "None of them are yours. Let them pass, and you will hear your own again."],
	],
	"post:karst_jiao": [["Narrator", "The Jiao sinks into the deep pool and goes quiet, listening, and the whirlpool smooths into a long, patient current."]],
	"pre:stone_sentinel": [
		["Narrator", "One of the limestone towers stands up. It has been waiting for ten thousand years for anyone to ask it a question."],
		["Sentinel of the Stone Forest", "Who goes down the river while living?"],
		["Lin Feng", "A son, looking for his parents."],
		["Sentinel of the Stone Forest", "Then prove you can carry them. The dead are heavier than stone."],
	],
	"post:stone_sentinel": [["Narrator", "The Sentinel sits back down with a sound like an avalanche settling, and the river runs a little faster past it, as if a stone had been lifted off its chest."]],
	"pre:horse_face": [
		["Narrator", "Where the river spills into the golden water of the Yellow Springs, a giant with a horse's head stands knee-deep in the current, tallying every passing lantern on an abacus of human teeth."],
		["Horse-Face, Runner of the Ten Courts", "Ten thousand and one, ten thousand and two... I know you. The living one with my brother's bell. The King has not opened the books for rebirth. Every soul is counted and kept."],
		["Lin Feng", "Kept for what?"],
		["Horse-Face, Runner of the Ten Courts", "Ask the King. I only count. Now go back, or be counted."],
	],
	"post:horse_face": [
		["Horse-Face, Runner of the Ten Courts", "Ten thousand and... no. I have lost count. For the first time in ten thousand years, I have lost count. How strange. How restful."],
		["Narrator", "Horse-Face sits down in the river and lets the lanterns float past him uncounted, out across the golden water, towards a field of red flowers and a bridge."],
	],
	"s_sp_intro": [
		["Meng Po of the Naihe Bridge", "Soup, travellers? One bowl, and you forget everything: every grudge, every debt, every face. No? Ah, you are still alive. Sit anyway. The queue is very long."],
		["Meng Po of the Naihe Bridge", "Every soul crosses my bridge, drinks my soup and goes on to the Wheel empty and clean. That was the Court's rule. Empty souls are easier to tax."],
		["Meng Po of the Naihe Bridge", "But your Ledger gave everyone their names back, and now nobody will drink. They would rather wait forever than forget again. I do not blame them."],
		["Meng Po of the Naihe Bridge", "Pick me four Herbs of Forgetting from among the lilies. I want to try a new recipe. A gentler one."],
	],
	"s_sp_return": [
		["Meng Po of the Naihe Bridge", "Good, good. Into the pot. And now the secret: a little of your qi, both of you. Living qi. The Court never let me use any."],
		["Narrator", "The soup turns from grey to gold. It smells of rice and rain and something half-remembered."],
		["Meng Po of the Naihe Bridge", "This bowl lets a soul forget the pain and keep one thing. One face. One song. Whatever it loves most. The Court would have hated it."],
		["Meng Po of the Naihe Bridge", "Two of my guests have refused every bowl for sixteen years. A man and a woman. They said they were waiting for their son to grow up. They are by the bridge. But the Patriarch, the Serpent and the Empress will not let anyone near it."],
	],
	"pre:corpse_patriarch": [
		["Narrator", "A stiff old man in Qing-dynasty robes hops out of the lilies, a yellow talisman fluttering on his forehead, and a hundred hopping corpses hop after him in perfect step."],
		["Corpse Patriarch Jiang", "Discipline! Order! The dead must stand in line! If they will not drink, they will march!"],
		["Yue Ling", "Pull the talisman off, Lin Feng. He has been sealed into that body so long he thinks the seal is him."],
	],
	"post:corpse_patriarch": [["Narrator", "The talisman tears. The old Patriarch sighs, folds up like a dropped robe, and his soul walks off towards Meng Po's pot, rubbing a stiff neck."]],
	"pre:bridge_serpent": [
		["Narrator", "The Naihe Bridge shudders. A red serpent has wound itself around the pillars, and every time a soul steps onto the bridge it shakes them off into the golden water."],
		["Lin Feng", "You are guarding a bridge nobody is allowed to cross. What is the point of that?"],
	],
	"post:bridge_serpent": [["Narrator", "The Serpent uncoils and slides away beneath the lilies, and the bridge stands still and open for the first time since the Wheel stopped."]],
	"pre:lily_empress": [
		["Narrator", "The whole field of spider lilies turns to face Lin Feng at once. Their roots run down to every grave in the world, and they are all of them one flower: the Empress of the Red Lilies."],
		["Empress of the Red Lilies", "Flowers and leaves never meet on my stems. That is the rule of the lily. The dead and the living never meet either. Why are you here, living one?"],
		["Lin Feng", "Because the rule was written by the Court, and the Court is gone."],
	],
	"post:lily_empress": [["Empress of the Red Lilies", "...Then go and meet them. Just this once, the flower and the leaf. I will look away."]],
	"pre:the_unforgotten": [
		["Narrator", "Beside the bridge the dead have gathered into one great shape: a thousand faces in a cloak of memories, every one of them refusing to forget."],
		["The Thousand Unforgotten", "WE WILL NOT DRINK. WE WILL NOT FORGET. THEY TOOK OUR YEARS, THEY TOOK OUR NAMES. WE WILL NOT LET THEM TAKE OUR FACES."],
		["Yue Ling", "Nobody is taking anything any more. Lin Feng, we have to let them be heard before they can be calm."],
	],
	"post:the_unforgotten": [
		["Narrator", "The great shape breaks apart into a thousand tired people, and one by one they come to Meng Po's pot and drink the golden soup, and each of them keeps one thing."],
		["Narrator", "The last two in the line are a man in a sweeper's patched robe and a woman with a jade pin in her hair. They look at Lin Feng for a long time."],
		["Su Wan", "...You have his nose. And my terrible singing voice, I expect."],
		["Lin Shan", "We were told to drink and go on. We said we would wait until we knew you had grown up safe. It has been a very long queue."],
		["Lin Feng", "I grew up. I swept the steps. I held up the sky. I... I do not know what to say to you."],
		["Su Wan", "Then do not say anything yet. Walk with us to the Wheel. We will talk on the way."],
		["Narrator", "Something new settles into Lin Feng's sword-hand, as patient as a parent's grip: the Samsara Sword, which cuts nothing that wants to stay and frees everything that wants to go."],
	],
	"s_wh_intro": [
		["Narrator", "Below the Yellow Springs the Wheel of the Six Paths stands still in a hall without walls: a stone wheel as tall as a mountain, its six spokes cracked, its rim choked with ten thousand waiting souls."],
		["Judge Cui Jue", "A living Sovereign, at the Wheel. I wrote in my book that this would never happen. I have been crossing out a great many things in my book lately."],
		["Judge Cui Jue", "Four spokes of the Wheel were broken when the Court fell, and the pieces were scattered through the Ten Courts. Without them the Wheel cannot turn, even if the King allowed it."],
		["Judge Cui Jue", "Find me the four broken Spokes. I will mend them. Whether the King lets them turn is another question."],
	],
	"s_wh_return": [
		["Judge Cui Jue", "Four spokes. Hold them in place while I write. The Wheel answers to what is written about it."],
		["Narrator", "Judge Cui writes with a brush of white ink, and the cracks in the spokes close like healing skin. The Wheel creaks, and for one moment, every waiting soul looks up."],
		["Judge Cui Jue", "The Mirror, the Burning Judge and the Guardian will try to stop you. They are the King's last instruments. Behind them, the King is waiting. He is not cruel. That is what makes him so hard to argue with."],
	],
	"pre:karma_mirror": [
		["Narrator", "A bronze mirror the size of a gate shows Lin Feng every life he has touched: the sect, the forest, the sky, the Ledger, the Wheel. In the mirror, every one of them is a debt."],
		["Mirror of Karma", "Look at the weight of it. Every good deed binds someone to you. Every rescue is a chain."],
		["Lin Feng", "Then let me show you how to look at it the other way round."],
	],
	"post:karma_mirror": [["Narrator", "The Mirror cracks straight down the middle, and in the crack the debts turn into what they always were: people who are glad to know each other."]],
	"pre:burning_judge": [
		["Narrator", "In the Burning Court a judge with a face of red lacquer sits on a throne of coals, sentencing the dead to burn away whatever the Court once said they owed."],
		["Judge of the Burning Court", "A debt unpaid is a fire unlit! I burn what is owed, so that nothing is owed!"],
		["Yue Ling", "Nobody owes anything any more. Let the fire go out."],
	],
	"post:burning_judge": [["Narrator", "The coals go grey. The Judge takes off his lacquer face, and underneath it he is a very old, very tired clerk who has not slept since the first dynasty."]],
	"pre:wheel_guardian": [
		["Narrator", "A great tortoise with the Wheel's six paths carved into its shell plants itself in front of the axle: gods, men, titans, beasts, hungry ghosts and hells."],
		["Guardian of the Six Paths", "Which path will you send them down, living one? Who decides? The Court decided. The King decided. Will you decide now?"],
		["Lin Feng", "No. I am only going to make sure the door opens. They decide where they go."],
	],
	"post:wheel_guardian": [["Narrator", "The Guardian lowers its head and steps aside, and the six paths carved on its shell begin, very faintly, to glow."]],
	"pre:king_yama": [
		["Narrator", "At the axle of the Wheel a king in black and gold sits with his hand on the brake, the King of the dead, Yama, who has judged every soul since the first one died."],
		["King Yama, Lord of the Wheel", "I stopped it. Yes. Do you know what the Wheel sent them back into, for ten thousand years? A world that harvested them. Every soul I sent up was born to be taxed, tribulated and eaten. I would not do it one more time."],
		["Lin Feng", "The Court is gone. The Ledger is closed. The sky is held up by people who chose to hold it. The world they would be born into is a kind one now."],
		["King Yama, Lord of the Wheel", "So you say. Every cultivator who ever came down here said the world above was kind. Prove it, Sovereign. Prove to me that your world is worth being born into."],
		["Su Wan", "He is our son. He swept the steps for three years without a single grain of qi, and he never once stopped being kind. That is the world he made. Let us go back to it."],
	],
	"post:king_yama": [
		["King Yama, Lord of the Wheel", "...The mother speaks for the world better than the son does. Very well. I take my hand off the brake."],
		["Narrator", "The Wheel of the Six Paths groans, shudders, and begins to turn. Ten thousand lanterns lift from its rim and flow upward like sparks from a fire, each soul keeping one thing it loves."],
		["Lin Shan", "We will be born again soon, somewhere. We will not remember you. But Meng Po's soup lets us keep one thing."],
		["Su Wan", "I am keeping your face. Look for a child who stares at you as if she has known you all her life. That will be me."],
		["Narrator", "Lin Feng's parents step onto the turning Wheel together, holding hands, and are gone in a rush of golden light."],
	],
	"pre:s_break11": [
		["Narrator", "The Wheel is turning, but it turns stiffly, like a mill that has rusted. It needs one more push, and the push must come from someone who could step off the Wheel forever and chooses to stay beside it."],
		["King Yama, Lord of the Wheel", "Turn it, Sovereign. Not as its master. The Court tried that. Turn it as one more soul who is glad it moves."],
		["Lin Feng", "Yue Ling. Will you push with me?"],
		["Yue Ling", "Always. The Founder wove me so that the bearer would never have to push alone."],
	],
	"post:s_break11": [
		["Narrator", "Lin Feng and Yue Ling set their hands to the rim of the Wheel and push. The last tribulation is not lightning: it is every life Lin Feng has touched, turning with him, all at once."],
		["Narrator", "He transcends samsara, not by escaping the Wheel, but by turning it gladly. The Wheel spins freely now, and the queue at the Naihe Bridge is gone."],
		["Judge Cui Jue", "I have written it down. 'The Wheel turns because someone wanted it to.' First true sentence in this book in ten thousand years."],
		["Narrator", "Back on the mountain, on the first morning of spring, a woman from the village below brings her newborn daughter to the sect to be blessed. The baby looks up at Lin Feng with an old, surprised, delighted stare."],
		["Lin Feng", "...Hello again."],
	],
	# ---- Part VII: The Unbroken Land
	"recall5": [
		["Narrator", "Spring comes to Azure Cloud Mountain. The baby with the old, surprised stare is named Little Wan, and the whole sect quarrels over whose turn it is to hold her."],
		["Narrator", "Then, one night, the threads appear: fine silver threads strung across the mountain roads at ankle height, humming like plucked strings. By morning the south road to the village has been sewn shut."],
		["Yue Ling", "Lin Feng... the village below the mountain. Granny Wen is down there. And Little Wan's mother took her home yesterday."],
		["Elder Qing Xuan", "Come to the hall, both of you. I know whose needlework this is."],
	],
	"s_p7_home": [
		["Elder Qing Xuan", "Under the Court the world was never one land. It was a quilt: every realm cut apart and stitched to the next by a gate, so that each could be harvested alone. The gates you walked through as a boy were her seams."],
		["Elder Qing Xuan", "Her name is Qianxian, the Lady of a Thousand Threads, the Court's Weaver. When you turned the Wheel her stitches came undone and the land grew back together. Walk east from our gate now and the bamboo simply runs on into the marsh, and the marsh into the snows."],
		["Lin Feng", "I wondered why a forest ever needed a gate."],
		["Elder Qing Xuan", "She wants her quilt back. She is starting with the mortal lands, where nobody can fight her: the village, the tea terraces, the mulberry woods. And she is spinning new thread from the newly reborn, because a soul just come round the Wheel is the strongest thread there is."],
		["Yue Ling", "Little Wan."],
		["Elder Qing Xuan", "I have cut the threads across our south road. Go down to Qingshi Village and find Granny Wen. She raised you after I left you with her. If any child is missing, she will know which."],
	],
	"s_vl_intro": [
		["Granny Wen the Midwife", "Shut the door, the threads come in on the draught. Let me look at you. Taller. Still all elbows. A Sovereign, they say, and you still wipe your feet on my step."],
		["Lin Feng", "Granny. The Elder says children are being taken."],
		["Granny Wen the Midwife", "Three of them, all born this spring, all born looking at their mothers like they knew them already. The threads came down the chimneys at night and wrapped them up like cocoons, and in the morning they would not wake. Their mothers sit by the cradles, and nobody is home behind the eyes. One of them was Little Wan."],
		["Granny Wen the Midwife", "The threads are still strung all over the village. Cut four of them and bring them to me. A midwife knows how to read a cord: I will tell you where they lead."],
	],
	"s_vl_return": [
		["Granny Wen the Midwife", "Four threads, and all four twisted the same way, sunwise. Uphill. They run up to the tea terraces and on into the mulberry woods."],
		["Granny Wen the Midwife", "And look at the stitching on this one: a needle as thick as a spear went through here. That will be the General who has been standing at the east end of the village since the threads came, letting nobody out."],
		["Yue Ling", "And the paper tiger in the lanes, and the scarecrow that walks at night, and the thing in the well..."],
		["Granny Wen the Midwife", "Paper and straw and a hungry spider, all stitched together and told to keep us in. Go on, then. I did not raise you to leave a mess in my village."],
	],
	"pre:paper_tiger": [
		["Narrator", "A tiger of oiled paper and bamboo prowls the village lanes, painted with a hundred angry eyes. Every eye is a stitched-on thread that pulls it along."],
		["Yue Ling", "It is only paper, Lin Feng. Somebody made it to frighten people."],
		["Lin Feng", "Then it is doing its job very well. Let us unmake it gently."],
	],
	"post:paper_tiger": [["Narrator", "The Paper Tiger folds in on itself like a letter. Inside, written in a child's careful hand, is a single word: 'home'."]],
	"pre:scarecrow_king": [
		["Narrator", "In the flooded paddies a scarecrow in a crown of rice straw rises out of the water, its arms stitched wide, its hat full of silver thread."],
		["Scarecrow King of the Paddies", "I keep the crows off. I keep the people in. I keep everything exactly where it was put. That is what I was made for."],
		["Lin Feng", "You were made to guard the rice, old friend. Not to fence the farmers."],
	],
	"post:scarecrow_king": [["Narrator", "The Scarecrow King's stitches pull loose, and it slumps back into a plain scarecrow, arms spread wide over the paddies, keeping off nothing but birds."]],
	"pre:well_spider": [
		["Narrator", "The village well hums. Something with eight long legs has strung a web from rim to rim, and the bucket hangs wrapped in silk halfway down."],
		["Well Spider", "Water and thread. Thread and water. Everyone comes to the well. Everyone stays."],
		["Yue Ling", "Not this morning, they don't."],
	],
	"post:well_spider": [["Narrator", "The web parts. The bucket drops with a splash, and somewhere in the village a woman laughs for the first time in a week, because she can draw water again."]],
	"pre:needle_general": [
		["Narrator", "At the east end of the village a general in armour of a thousand sewing needles plants a spear the size of a weaver's beam across the road."],
		["Needle General Zhen", "By order of the Lady, this village is finished. Finished cloth does not move. Turn back, Sovereign, or be hemmed in with them."],
		["Lin Feng", "A finished cloth is just a cloth nobody is using any more. These people are not finished."],
	],
	"post:needle_general": [
		["Needle General Zhen", "...The Lady said every stitch I held was a war kept out of a field. I held this road for a thousand years. Was I wrong all that time?"],
		["Lin Feng", "Maybe not, once. But the war is over. Let them walk."],
		["Narrator", "The General lays down his great needle and walks away up the terraces, a free man with nothing to hold. Lin Feng keeps the needle, and gives it to Weaver Liu, who uses it to unpick the last threads from the village roofs."],
	],
	"s_te_intro": [
		["Tea Master Lu Yu", "Sit, sit. Nobody climbs nine terraces without a cup at the top. This is the last of last year's crop, and it will be the last of any crop if those threads stay on my hills."],
		["Tea Master Lu Yu", "She has sewn the terraces up like a quilt. The bushes cannot breathe, the pickers cannot climb, and anyone who drinks tea grown under her threads falls asleep and dreams of being stitched into a border."],
		["Tea Master Lu Yu", "But the Dragon-Well buds on the high terraces grow above the threads. Bring me four, and I will brew something that wakes thread-sleepers."],
	],
	"s_te_return": [
		["Tea Master Lu Yu", "Four buds, and not one of them bruised. You pick like a mortal, Sovereign. I mean that kindly."],
		["Narrator", "The tea is bright green and smells of rain on hot stone. When Yue Ling drinks it, the faint silver lines on her wrists, which neither of them had noticed, fade away."],
		["Yue Ling", "...I was being sewn too. Slowly. The Founder wove me from the Seal, and the Lady can pull on anything woven."],
		["Tea Master Lu Yu", "Then drink a cup every morning until this is over. Now: a kite, a dragon, a golem and the Matron who sews for the Lady. They hold the terraces. Go and take them back."],
	],
	"pre:wind_kite": [
		["Narrator", "Above the third terrace a kite the size of a sail rides the wind, painted like a centipede, its string a silver thread running all the way up into the clouds."],
		["Yue Ling", "It is pulling the threads tight across the whole hillside. Cut the string and they will all go slack!"],
	],
	"post:wind_kite": [["Narrator", "The string parts with a sound like a zither breaking. The Great Wind Kite sails off over the mountains, free, and the threads across the terraces sag to the ground."]],
	"pre:terrace_dragon": [
		["Narrator", "In the spring at the top of the terraces a green dragon lies coiled asleep, wound round and round with silver thread like a bundle of tea."],
		["Lin Feng", "It is not attacking. It has been sewn asleep."],
		["Yue Ling", "Then it will not be happy when it wakes. Be ready."],
	],
	"post:terrace_dragon": [["Narrator", "The Dragon of the Nine Terraces shakes off the last threads, drinks deeply from its spring, and sends a cool rain sweeping down over every terrace on the hill."]],
	"pre:hill_golem": [
		["Narrator", "A golem of terraced earth stands up out of the hillside, tea bushes growing on its shoulders, silver stitches holding its seams together."],
		["Tea-Hill Golem", "THE HILL. MUST. NOT. MOVE."],
	],
	"post:hill_golem": [["Narrator", "The Golem's seams give way, and it lies back down into the hillside as nine neat terraces, a little steeper than before."]],
	"pre:thread_matron": [
		["Narrator", "At the crest of the terraces a spider-woman as big as a house sits on a web strung between the hills, sewing with all eight hands at once."],
		["Thread Matron of the Hills", "The Lady's apprentice, at your service. Every border between here and the sea, I have hemmed. Would you like to see the pattern? It is beautiful. Nobody ever crosses it."],
		["Lin Feng", "That is exactly what is wrong with it."],
	],
	"post:thread_matron": [
		["Thread Matron of the Hills", "Go on into the mulberries, then. The Lady is waiting at the Loom, and she has the children. Three new souls make a very strong warp."],
		["Narrator", "The Matron's web falls apart across the hills, and for the first time since spring, the road up the far side of the terraces is open."],
	],
	"s_sk_intro": [
		["Silk Farmer Can Niang", "Mind your feet, the silkworms have been coming out of the woods all week. Not my silkworms. Hers. They eat mulberry leaves and spin souls."],
		["Silk Farmer Can Niang", "Every newborn the threads took was carried through these woods and wrapped in a cocoon to cure, like silk. Most of the cocoons went on to the Loom. Some were dropped among the mulberries when the swarms fought over them."],
		["Silk Farmer Can Niang", "Find four of the dropped ones. If they are still warm, I can unwind them without hurting what is inside."],
	],
	"s_sk_return": [
		["Silk Farmer Can Niang", "Warm. All four. Give me room."],
		["Narrator", "Can Niang unwinds the cocoons in a bowl of hot water, as gently as any silk. Inside are not babies, but tiny lanterns, each with a newborn soul asleep in its flame. They are the souls of children all over the land who went to sleep this spring and did not wake."],
		["Silk Farmer Can Niang", "The bodies are still in their cradles at home. The souls were taken for thread. These four can go home now. Little Wan's is not among them. Hers went on to the Loom."],
		["Yue Ling", "Then that is where we are going."],
		["Narrator", "Something settles into Lin Feng's sword-hand that is as wide as the land itself: the Boundless Heart Sword, which cuts no border and leaves every door open."],
	],
	"pre:silkworm_queen": [
		["Narrator", "Under the oldest mulberry a silkworm as long as a river barge lifts its pale head, its jaws still green with leaves and its belly glowing with swallowed souls."],
		["Yue Ling", "It is digesting them, Lin Feng. We have to be quick."],
	],
	"post:silkworm_queen": [["Narrator", "The Silkworm Queen curls up and is still, and from her belly a stream of little soul-lanterns floats up and away towards every village in the land."]],
	"pre:moth_empress": [
		["Narrator", "Wings like painted screens open over the canopy. The Moth Empress hangs from the moon, dusting the woods with a powder that makes every path look like a wall."],
		["Moth Empress of the Mulberries", "Why would anyone want to go anywhere? Stay. Stay in the dark, where it is soft."],
	],
	"post:moth_empress": [["Narrator", "The Moth Empress flutters down into the leaves and folds her wings. The powder settles, and the paths through the woods are only paths again."]],
	"pre:mulberry_ent": [
		["Narrator", "The Old Mulberry has grown its roots right through a hundred cocoons and will not let them go. Its bark creaks like an old woman's voice."],
		["The Old Mulberry", "I fed them. I fed every worm in these woods for a thousand years. What I feed, I keep."],
		["Lin Feng", "You fed them so they could become something else. That was always the point of you."],
	],
	"post:mulberry_ent": [["Narrator", "The Old Mulberry's roots loosen, one by one, and a hundred cocoons roll free into the moss. When Lin Feng looks back, the tree is already budding."]],
	"pre:thousand_hands": [
		["Narrator", "In the Spinning Hall at the edge of the woods a figure with a thousand arms works a thousand spinning wheels at once, every wheel turning a soul into thread."],
		["Thousand Hands of the Spinning Hall", "Spin and spin and spin. The Lady needs a warp strong enough to hold the whole world apart. Only the newborn are strong enough."],
		["Yue Ling", "Then you are going to have to manage without."],
	],
	"post:thousand_hands": [["Narrator", "The spinning wheels stop, all thousand at once, in a silence so sudden it rings. Beyond the Hall, the road climbs into a sky striped like cloth on a loom."]],
	"s_lm_intro": [
		["Narrator", "The Loom of Borders fills the sky: a frame as big as a mountain range, its warp threads running down to every corner of the world, its cloth the map of every border the Court ever sewed."],
		["Zhi, the Last Weaver-Girl", "You came up the warp. Nobody comes up the warp. I am Zhi. I swept this Loom for two hundred years, until the Lady made me an apprentice so that I would stop asking why."],
		["Zhi, the Last Weaver-Girl", "She has the three children in the heddle at the top. If she finishes the new warp with them, every border comes back at once: every gate, every seam, every village shut away from every other."],
		["Zhi, the Last Weaver-Girl", "Take four shuttles out of the Loom. Without its shuttles the Loom cannot weave a single new row, and she will have to come down and talk to you."],
	],
	"s_lm_return": [
		["Zhi, the Last Weaver-Girl", "Four shuttles. She can feel it, you know. The whole Loom just went quiet."],
		["Zhi, the Last Weaver-Girl", "She is not cruel. That is the hard part. She sewed the first borders round fields, so that the wars of the immortals would stay out of them. The Court took her borders and made them into pens."],
		["Lin Feng", "Then I will not cut her down. I will ask her to put the needle away."],
		["Zhi, the Last Weaver-Girl", "Her guardians will not let you ask: the Beast in the Warp, the Spindle Golem, the Shuttle Dragon. And then her."],
	],
	"pre:warp_beast": [
		["Narrator", "Where the warp threads cross they have knotted into a beast with no face, only a tangle that grows tighter the harder it struggles."],
		["Yue Ling", "It is the borders themselves, all knotted together. It does not even know what it is."],
	],
	"post:warp_beast": [["Narrator", "Strand by strand the Beast unknots, until there is nothing left but straight threads hanging loose, swinging gently in a wind that blows across the whole world."]],
	"pre:spindle_golem": [
		["Narrator", "A golem built of a thousand spindles rolls out of the Loom's shadow, winding everything it touches round and round its body."],
		["Spindle Golem", "WIND. WIND. WIND IT ALL UP."],
	],
	"post:spindle_golem": [["Narrator", "The Spindle Golem unspools across the floor of the Loom in a hundred bright colours, and everything it had wound up rolls free."]],
	"pre:shuttle_dragon": [
		["Narrator", "A golden dragon shaped like a weaver's shuttle shoots back and forth across the Loom, faster than the eye, trailing a new row of borders behind it."],
		["Lin Feng", "If it never stops, we have to be where it is going."],
	],
	"post:shuttle_dragon": [["Narrator", "Lin Feng catches the Shuttle Dragon mid-flight, and it stops, and blinks, and curls up on the Loom's frame like a cat in a sunny window."]],
	"pre:qianxian": [
		["Narrator", "At the top of the Loom, in a heddle of light, three newborn souls sleep in their lanterns. Above them the Lady of a Thousand Threads lowers herself on a single strand: a woman to the waist, a great silver spider below, every one of her eight hands holding a needle."],
		["Madam Qianxian, Lady of a Thousand Threads", "Do you know what the world looked like before my borders, little sweeper? The immortals fought across it like children kicking through a sand garden. Every war rolled over every field."],
		["Madam Qianxian, Lady of a Thousand Threads", "I sewed fences round the fields. The Court took my fences and called them pens. You cut them all down, and you think the world is free. It is only open. Open to anything."],
		["Lin Feng", "Then let people build their own fences. Walls and a door, like Granny Wen's house. A wall keeps the wind out. A door is what makes it a home and not a prison. You only ever sewed walls."],
		["Madam Qianxian, Lady of a Thousand Threads", "Pretty words. Weave something with them, if you can."],
	],
	"post:qianxian": [
		["Narrator", "The Lady's eight needles fall, one after another, and stick quivering in the Loom. She sits for a long time looking at the three sleeping lanterns."],
		["Madam Qianxian, Lady of a Thousand Threads", "Walls and a door. I suppose I never thought to sew a door. Take them home, Sovereign. Their mothers are waiting."],
		["Narrator", "Yue Ling lifts the three lanterns out of the heddle. The one in the middle burns with an old, surprised, delighted flame."],
		["Zhi, the Last Weaver-Girl", "And the Loom? It holds every border in the world."],
		["Madam Qianxian, Lady of a Thousand Threads", "Leave it to me. I will unpick it. Slowly. It took me ten thousand years to sew; it will take a while to make a world with doors in it."],
	],
	"pre:s_break12": [
		["Narrator", "On the floor of the unravelling Loom, with the whole land spread out below like a cloth with no seams, the Heavens ask Lin Feng one last question: what will you keep out?"],
		["Lin Feng", "Nothing. And I will keep a door open for anyone who knocks."],
		["Yue Ling", "That is not a cultivation method, Lin Feng. That is just being kind."],
		["Lin Feng", "It has always worked so far."],
	],
	"post:s_break12": [
		["Narrator", "The last tribulation does not strike. It knocks, and Lin Feng opens the door. He becomes the first cultivator of the Boundless Heart: a realm with no border, no gate, and no wall but the ones people choose for themselves."],
		["Narrator", "In Qingshi Village, three mothers wake to three babies yawning in their cradles. Granny Wen counts them twice and then sits down on her step and cries, very quietly, because she would never let anyone see."],
		["Madam Qianxian, Lady of a Thousand Threads", "First row unpicked. Nine thousand nine hundred and ninety-nine to go. Zhi, fetch the tea."],
		["Narrator", "And on Azure Cloud Mountain, on the first warm evening of summer, Lin Feng sweeps the steps of the sect while Little Wan watches from the Elder's arms, and every road down the mountain runs on, open, to the edge of the world."],
	],
	# ---- Part VIII: The River of Heaven
	"recall6": [
		["Narrator", "Summer turns. Qingshi Village has three new names in its register, and Little Wan has learned to say 'broom'."],
		["Narrator", "On the seventh night of the seventh month the whole sect climbs the roof of the hall to watch the magpies gather in the sky, the way they have every year since before there was a sect. No magpies come."],
		["Narrator", "Instead, an hour before midnight, the Silver River across the sky spills over. Stars come down like rain. They hiss in the lotus pond, and in the morning the pond is full of drowned stars, still faintly shining."],
		["Yue Ling", "Lin Feng... the river in the sky. It is lower than it was. It is coming down the south road."],
		["Elder Qing Xuan", "To the hall. Both of you. I was afraid of this when Qianxian began unpicking her Loom."],
	],
	"s_p8_home": [
		["Elder Qing Xuan", "Every child in the valley knows the story. The Weaver Star, granddaughter of the Queen Mother of the West, fell in love with a cowherd. The Queen Mother of the West drew her golden hairpin across the sky to part them, and the line she drew became the Silver River."],
		["Elder Qing Xuan", "Once a year, on the seventh night, the magpies of the world fly up and make a bridge of themselves so the lovers can meet. That is the story. What the story does not say is that the river is a border. The oldest border there is."],
		["Lin Feng", "And Qianxian is unpicking every border she ever stitched."],
		["Elder Qing Xuan", "She did not draw this one, but she bound its banks with her thread for ten thousand years. Now the thread is coming out, and the river does not know where to go. It is pouring down the old Sky Road into the world, and the magpies have been scattered by the flood."],
		["Yue Ling", "And the Cowherd? In the story he waits by the river every night."],
		["Elder Qing Xuan", "He still does. There is a ferry on the south road where the Sky Road comes down to earth, and an old herdsman who keeps it. I have opened the road. Go down to the Starfall Ferry and find Niu Lang."],
	],
	"s_sf_intro": [
		["Niu Lang the Cowherd", "Mind the stars, they are still hot. I have been fishing them out of the fields all week. The rice is ruined, and the river is still rising."],
		["Lin Feng", "The Elder says you are the Cowherd. From the story."],
		["Niu Lang the Cowherd", "I am a cowherd, and there is a story. I keep the ferry because this is where the Sky Road touches the ground. Every seventh night I would cross on the magpies' backs. This year there were no magpies, only water."],
		["Niu Lang the Cowherd", "The drowned stars are what is left of the Weaver's sky. If you can fish out four of them I can read them. She always said I read stars better than letters. Then we will know how far up the river has broken."],
	],
	"s_sf_return": [
		["Niu Lang the Cowherd", "Four stars, and they all fell from the same place: the bend of the river under the Magpie Heights. That is where the bridge always stood."],
		["Niu Lang the Cowherd", "The flood has brought things down with it. A jiao has silted up the ford, the reed widow walks the bank again, and the old carp at the weir is too frightened to leap. And something with a horn of light keeps the tide rising at the east end of the fields."],
		["Yue Ling", "We will clear the ford. Will you come with us?"],
		["Niu Lang the Cowherd", "I would only slow you down. Clear the road, and I will follow it. I have been following that road my whole life."],
	],
	"pre:silt_jiao": [
		["Narrator", "In the ford a jiao, a dragon that never finished becoming a dragon, lies coiled in starlit silt, damming the river so the water spreads over the fields."],
		["Jiao of the Silted Ford", "A thousand years I have waited to climb the river into the sky. Now the river has come down to me, and I will not let it leave."],
		["Lin Feng", "Then climb it with us. It is going back up."],
	],
	"post:silt_jiao": [["Narrator", "The Jiao uncoils, and the ford runs clear. As the water drains from the fields it carries the young dragon with it, upstream, towards the sky."]],
	"pre:reed_widow": [
		["Narrator", "In the reeds a woman in a wet white robe stands up to her waist in the flood, calling a name over and over."],
		["Widow of the Reed Ford", "He went to the river to fetch water, and the river took him across. I have waited on this side for so long. Why should anyone be allowed to cross?"],
		["Yue Ling", "Because the river is not supposed to keep anyone. Not him, and not you."],
	],
	"post:reed_widow": [["Narrator", "The Widow lets out a long breath and walks into the water. On the far bank, faint as a reflection, a man is waiting with a bucket. She does not look back."]],
	"pre:carp_sage": [
		["Narrator", "Under the weir an enormous golden carp hangs in the water, whiskers grey with age, glaring at the falls above it."],
		["Old Carp Who Would Not Leap", "Every carp who leaps the Dragon Gate becomes a dragon. Every carp who fails is laughed at by the whole river. For four hundred years I have chosen not to be laughed at."],
		["Lin Feng", "And for four hundred years you have stayed a carp. Shall we see what you can do?"],
	],
	"post:carp_sage": [["Narrator", "Stung, the Old Carp leaps, and clears the weir by a full body-length, and keeps going, up the waterfall of falling stars, and is gone. Somewhere far above, something roars with delight."]],
	"pre:tide_qilin": [
		["Narrator", "At the east end of the fields a qilin made of moonlit water paces the bank, and wherever its hooves fall the tide rises."],
		["Qilin of the Rising Tide", "The river was walled for ten thousand years. Now it is free. I am only helping it go where it likes."],
		["Lin Feng", "A river that goes where it likes is a flood. A river needs banks. Banks are not the same as walls."],
	],
	"post:tide_qilin": [
		["Narrator", "The Qilin bows its head, and the tide goes out with it. Where the water draws back, a road of wet starlit stone climbs towards the clouds."],
		["Niu Lang the Cowherd", "The Sky Road. I have not seen it dry in a year. Go on. The magpies nest on the heights at the top. If any of them are left, Que Lao will know."],
	],
	"s_mg_intro": [
		["Que Lao, the Old Magpie", "Kak! A Sovereign on my cliff, and not a single nest left standing to receive him. Forgive the mess."],
		["Lin Feng", "You are the magpies who make the bridge."],
		["Que Lao, the Old Magpie", "Ten thousand of us, wing to wing, every seventh night since there was a sky. This year the river burst while we were gathering, and the storm threw us to the four winds. The apes took the nests, and something wearing a crow's crown has set itself on the broken bridge."],
		["Que Lao, the Old Magpie", "Gather the bridge plumes the storm tore from us. Four of them. A magpie can find her way home by her own feather."],
	],
	"s_mg_return": [
		["Que Lao, the Old Magpie", "Four plumes. Listen. Can you hear? They are calling to the others. The flock is coming back, one bird at a time."],
		["Que Lao, the Old Magpie", "But we cannot build while the heights are held against us. The Ape King sits in our nests. A magpie that ate the storm wears its lightning for a crown. The great pier of the bridge has fallen and walks about in a temper. And on the bridge itself the Crow Marshal says no bird may cross without leave of the Court."],
		["Yue Ling", "There is no Court any more."],
		["Que Lao, the Old Magpie", "Crows are the last to hear any news. Go and tell him."],
	],
	"pre:cloud_ape_king": [
		["Narrator", "In the ruined nests on the cliff a great ape with a silver back sits on a heap of stolen eggs, cracking walnuts on its knee."],
		["King of the Cloud Apes", "Hoo! The birds built, the birds left, the apes moved in. That is the law of the mountain."],
		["Lin Feng", "The birds were blown away. That is not the same as leaving."],
	],
	"post:cloud_ape_king": [["Narrator", "The Ape King sits back, nursing a bruised pride, and very carefully rolls the eggs back into the nests one by one. Apes, it turns out, can be very gentle when they are embarrassed."]],
	"pre:storm_magpie": [
		["Narrator", "Above the heights a magpie as big as a house rides the thunderheads, a crown of lightning crackling on its head."],
		["Storm-Crowned Magpie", "Kak! I swallowed the storm that scattered us. Now I am the storm. Why would I want to be a bridge again?"],
		["Yue Ling", "Because a bridge is where everyone you love walks across your back. A storm never gets to be that close to anyone."],
	],
	"post:storm_magpie": [["Narrator", "The lightning crown flickers out. The great magpie shrinks with every beat of its wings, until it is an ordinary bird, a little singed, landing on Que Lao's staff."]],
	"pre:pier_golem": [
		["Narrator", "The great stone pier that held up one end of the Magpie Bridge has pulled itself out of the cliff and stomps up and down the heights."],
		["Golem of the Fallen Bridge-Pier", "TEN THOUSAND YEARS I HELD. NOBODY THANKED ME. NOW I WALK WHERE I LIKE."],
		["Lin Feng", "Thank you. Truly. Now will you hold it once more?"],
	],
	"post:pier_golem": [["Narrator", "The Pier stops. Nobody, it seems, has ever said thank you before. It walks back to the cliff edge and sets itself into the rock, very straight, very proud."]],
	"pre:crow_marshal": [
		["Narrator", "On the broken end of the bridge stands a marshal in black lacquered armour with a crow's mask, a halberd across the way, a hundred crows on the rails behind him."],
		["Crow Marshal of the Broken Bridge", "By order of the Heavenly Court, no bird, beast, mortal or star may cross the River of Heaven without leave. Present your leave."],
		["Lin Feng", "The Court fell two years ago. I was there. I can show you where the Ledger used to be."],
		["Crow Marshal of the Broken Bridge", "Then I have no orders. Then I am nobody. Then I will hold this bridge until someone gives me new ones."],
	],
	"post:crow_marshal": [
		["Narrator", "The Crow Marshal lowers his halberd and takes off his badge. Behind him the crows fly up, and among them, wing by wing, come the magpies, more and more, until the sky is black and white with them."],
		["Que Lao, the Old Magpie", "Kak! Kak! Look at them! Not enough for the whole bridge, not yet, but enough to carry you across. Go to the Weaver. She has been alone on the far bank a very long time."],
	],
	"s_wv_intro": [
		["Zhi Nu, the Weaver Star", "You crossed on the magpies. I felt every one of their steps on my loom. Sit, please. Mind the warp; that thread is tomorrow's sunrise."],
		["Lin Feng", "The river is flooding the world below. The Elder says it is because the borders are coming undone."],
		["Zhi Nu, the Weaver Star", "The river is flooding because I stopped weaving its banks. I wove them every night for ten thousand years, and on the seventh night of the seventh month I would stop, and cross, and see him. This year I thought: if I stop weaving altogether, perhaps the river will simply go away."],
		["Zhi Nu, the Weaver Star", "It did not go away. It went down. I have done a foolish thing, Sovereign. Help me catch the threads that have blown loose from my loom, four threads of starlight, and I will begin to mend it."],
	],
	"s_wv_return": [
		["Zhi Nu, the Weaver Star", "Four threads. Enough to weave banks for the river, but only banks this time. Not a wall. I will leave a ford, every seventh night and every other night too."],
		["Zhi Nu, the Weaver Star", "But the palace is still full of things I wove in despair. A moth of my seven stars that eats the light. The weaving-frame my grandmother gave me, weaving walls on its own. The qilin of the hall, who thinks I need protecting. And the Warden of the River, who was set at the palace gate to keep me in."],
		["Zhi Nu, the Weaver Star", "Take this sword-form. I wove it from the night he and I first met. My grandfather never knew I had kept it."],
		["Narrator", "Lin Feng learns the Seventh-Night Reunion Sword."],
	],
	"pre:seven_star_moth": [
		["Narrator", "Above the palace garden a moth with seven stars on its wings drinks the light out of the lanterns one by one."],
		["Yue Ling", "It is eating the stars. All seven of the Weaver's stars."],
		["Lin Feng", "Then let us give them back to her."],
	],
	"post:seven_star_moth": [["Narrator", "The moth bursts into seven sparks, and they rise, and settle back into the sky in the shape of a weaver's shuttle, where they have always been."]],
	"pre:weaving_frame": [
		["Narrator", "In the great hall a loom of white jade and gold weaves on its own, shuttle flying, and everything it weaves is a wall."],
		["The Celestial Weaving-Frame", "CLACK. CLACK. THE GRANDDAUGHTER MUST BE KEPT SAFE. CLACK. SAFE IS INSIDE. INSIDE IS WALLS."],
		["Lin Feng", "She can keep herself safe. Stop."],
	],
	"post:weaving_frame": [["Narrator", "The Weaving-Frame's shuttle drops. Its last row of wall unravels and falls in a heap of light, and Zhi Nu runs her hand along the old frame like a horse she used to ride."]],
	"pre:hall_qilin": [
		["Narrator", "Before the inner hall a qilin of starlight lowers its horn."],
		["Qilin of the Weaving Hall", "I have guarded her since she was a child. A cowherd. A mortal. He will grow old, and she will weep for ten thousand years."],
		["Yue Ling", "Then let her weep. That is hers to choose, not yours."],
	],
	"post:hall_qilin": [["Narrator", "The Qilin lowers its horn and steps aside, and lays its head for a moment on Zhi Nu's shoulder, and goes out into the garden to lie in the sun."]],
	"pre:river_warden": [
		["Narrator", "At the palace gate, where the Sky Road leaves for Kunlun, stands a Heavenly Warden in silver armour, a spear in each hand."],
		["Heavenly Warden of the River", "The Queen Mother set me here on the night she drew the river. The Weaver Star does not leave. The Cowherd does not enter. Those are my orders."],
		["Lin Feng", "Then we will ask the Queen Mother to change them. Let us pass."],
		["Heavenly Warden of the River", "Nobody asks the Queen Mother anything."],
	],
	"post:river_warden": [
		["Narrator", "The Warden plants both spears in the ground and kneels beside them."],
		["Heavenly Warden of the River", "Go to Kunlun, then. Ask her. If she answers you, you will be the first in ten thousand years. Her maid tends the peach orchard by the Jasper Pool; she alone can bring you before the throne."],
	],
	"s_jp_intro": [
		["Dong Shuang, Maid of the Jasper Pool", "You are the Sovereign who turned the Wheel. My lady has been expecting you since the day the river broke. She has not said so. She has been pacing."],
		["Lin Feng", "We have come to ask her to take back the river."],
		["Dong Shuang, Maid of the Jasper Pool", "She cannot take it back. A line drawn with that hairpin stays drawn. But she could draw something else across it, if she wanted to."],
		["Dong Shuang, Maid of the Jasper Pool", "Nobody comes before her empty-handed. Pick four peaches of Kunlun from the high orchard, the ones that ripen once in three thousand years. Not the humming ones."],
	],
	"s_jp_return": [
		["Dong Shuang, Maid of the Jasper Pool", "Four peaches, and not one of them humming. You listen well. My lady will see you."],
		["Dong Shuang, Maid of the Jasper Pool", "But Kunlun keeps its own counsel. Kaiming guards the nine gates with his nine heads. The three blue birds carry her messages and will not let you past until you answer theirs. And the white ape who stole the sword manual of heaven lives in the orchard and thinks every visitor has come to steal it back."],
		["Yue Ling", "And then the Queen Mother herself."],
		["Dong Shuang, Maid of the Jasper Pool", "She will fight you. She fights everyone. She has the teeth of a tiger and the tail of a leopard, and a very long memory. Go gently."],
	],
	"pre:kaiming_beast": [
		["Narrator", "Before the nine gates of Kunlun crouches a tiger the size of a temple, with nine human faces, each one watching a gate."],
		["Kaiming, Beast of the Nine Gates", "Nine gates. Nine questions. Why have you come? Who sent you? What do you carry? What do you want?..."],
		["Lin Feng", "To ask for a bridge. Nobody. Peaches. To go home, eventually."],
		["Kaiming, Beast of the Nine Gates", "...those were four. Answer the other five with your sword."],
	],
	"post:kaiming_beast": [["Narrator", "One by one Kaiming's nine faces close their eyes, satisfied, and the nine gates of Kunlun swing open together."]],
	"pre:blue_birds": [
		["Narrator", "Three blue birds as big as cranes wheel above the Jasper Pool, carrying the Queen Mother's messages in their beaks."],
		["The Three Blue Birds", "We carry her word to the world. What word should we carry back to her?"],
		["Yue Ling", "Tell her we came to ask, not to take."],
	],
	"post:blue_birds": [["Narrator", "The blue birds dip their wings and fly up to the jade palace on the peak, carrying Yue Ling's words. Far above, a gate opens."]],
	"pre:white_ape": [
		["Narrator", "In the orchard a white ape with a scroll stuffed down its belt swings from branch to branch, pelting the travellers with peach stones."],
		["White Ape of Kunlun", "Ha! Another thief come for the Sword Manual of Heaven! It is mine, mine, I stole it fair and square!"],
		["Lin Feng", "Keep it. I have my own swords now. Mostly I sweep with them."],
	],
	"post:white_ape": [["Narrator", "The White Ape is so astonished that anybody would not want the Manual that it sits down in a peach tree and reads it for the first time, and finds it is mostly about patience."]],
	"pre:xiwangmu": [
		["Narrator", "Beside the Jasper Pool, on a throne of white jade, sits the Queen Mother of the West: a woman with a tiger's teeth and a leopard's tail, a golden hairpin in her grey hair."],
		["Xiwangmu, Queen Mother of the West", "I know why you have come. You want me to unsay the river. I drew it to keep my granddaughter in the sky where she belongs, and the cowherd on the earth where he belongs. Everyone where they belong. That is what keeps the world from falling apart."],
		["Lin Feng", "Qianxian said that too, about her borders. She is unpicking them now, one row at a time. The world has not fallen apart."],
		["Xiwangmu, Queen Mother of the West", "Then prove it is strong enough to stand without my lines. Come."],
	],
	"post:xiwangmu": [
		["Narrator", "The Queen Mother sits back on her throne. For a long time she looks at the golden hairpin in her hand."],
		["Xiwangmu, Queen Mother of the West", "A line drawn with this stays drawn. But I suppose nobody ever said I could only draw rivers."],
		["Narrator", "She draws the hairpin across the sky, once, gently, from the Weaver's palace to the Cowherd's ferry. Where it passes, a bridge of light hangs over the river, and the magpies land on it in their thousands, and stay."],
	],
	"pre:s_break13": [
		["Narrator", "On the new bridge over the River of Heaven, with the Cowherd climbing up one end and the Weaver running down the other, the Heavens ask Lin Feng their last question: what will you hold together?"],
		["Lin Feng", "Whatever reaches for each other. That is all a bridge is."],
		["Yue Ling", "Magpies holding on to each other."],
		["Lin Feng", "And people. Mostly people."],
	],
	"post:s_break13": [
		["Narrator", "The tribulation falls on the bridge, and the bridge holds. Lin Feng becomes the first cultivator of the Star River Crossing: a realm that is not a wall or a door, but a way across."],
		["Narrator", "In the middle of the bridge Niu Lang and Zhi Nu meet, and say nothing at all for a long while. Then he plays his flute, badly, and she laughs, and the sunset that evening is the best anyone has seen in a year."],
		["Xiwangmu, Queen Mother of the West", "Every night, then. Not just the seventh. I suppose it will be very noisy."],
		["Narrator", "And on Azure Cloud Mountain the drowned stars rise out of the lotus pond one by one and float home, and Little Wan claps at each of them, and Lin Feng sweeps the steps, and the River of Heaven runs on above it all, full to its banks and no higher, with a bridge across it for anyone who wants to cross."],
	],
	# ---- Part IX: The Tenth Sun
	"recall7": [
		["Narrator", "The bridge holds. All night the magpies sit on it in their thousands, and all night the sect sits on the roof of the hall to watch them, until Little Wan falls asleep in the Elder's beard. It was, as it turned out, the last sunset for nine days."],
		["Narrator", "In the morning the sun comes up over the eastern ridges, as it has every morning since there was a mountain. It climbs to the top of the sky. And there it stops."],
		["Narrator", "On the first day everyone enjoys the long golden afternoon. On the third day nobody can sleep. By the ninth day the lotus pond is steaming, the bamboo has gone yellow at the tips, and the sect's roosters have given up crowing altogether."],
		["Yue Ling", "Lin Feng, look at the sundial in the courtyard. The shadow has not moved since the morning after the bridge. Nine days, and it has not moved at all."],
		["Elder Qing Xuan", "To the hall, both of you, and close the shutters behind you. I have been dreading a morning like this for sixty years. I had rather hoped it would wait until I was dead."],
	],
	"s_p9_home": [
		["Elder Qing Xuan", "When the world was young there were ten suns, and they were children. Their mother was Xihe. Every morning she bathed one of them in the hot springs of the Valley of Sunrise, set him in her chariot at the foot of the Fusang tree, and drove him across the sky, singing all the way."],
		["Elder Qing Xuan", "One child a day, ten days to a week: that is why the old calendars count in tens. Then one morning all ten rose together, to see what would happen. The rivers boiled. The millet burned in the fields."],
		["Elder Qing Xuan", "The archer Hou Yi climbed a mountain and shot nine of them out of the sky. He would have shot the tenth as well, but someone had taken the tenth arrow out of his quiver while he slept, so one sun was left. After that the Heavenly Court took the reins from Xihe. A clerk of the Court drove the last sun along its road, and another wrote every day down in the Ledger."],
		["Lin Feng", "And there is no Court any more."],
		["Elder Qing Xuan", "There has been no Court for two years. Since then the sun has kept to its road out of habit, the way an old cart-horse walks the road home after the carter has died. Nine days ago something frightened it. It climbed as high as it could over the east, and there it has stayed. The east is baking. The west has not seen a dawn in nine days."],
		["Elder Qing Xuan", "And there is worse. Where the nine suns fell there are embers in the ground, and they are waking. If they rise, it will be the age of ten suns again, and there is no Hou Yi now."],
		["Lin Feng", "Good. I was not going to shoot anything out of the sky."],
		["Yue Ling", "And the moon? Who walks the moon, if the Court is gone?"],
		["Elder Qing Xuan", "The moon has a keeper of its own: Chang'e, who has lived alone in the Moon Palace since the archer's day, and never once asked the Court for help. She is walking it round the night side of the world by herself. She will be very tired by now."],
		["Elder Qing Xuan", "Go east, to the Dawn Market at Yanggu, the last town on the pilgrims' road to the Valley of Sunrise. They live closest to the sun, and they will know first if anything changes. I have opened a new gate on the south road. Take water. Take a hat."],
	],
	"s_yg_intro": [
		["Ah Mei the Lantern-Maker", "Lanterns! Lanterns for the night climb, two coppers, three for five! ...Sorry. Habit. Nobody has bought a lantern in nine days. You cannot sell a lantern at noon."],
		["Lin Feng", "We have come about the sun."],
		["Ah Mei the Lantern-Maker", "Everyone in Yanggu has come about the sun. The pilgrims used to buy my lanterns here on their way east, and climb the Valley of Sunrise by night to watch it come up out of the Fusang tree. Now it never comes up, because it never went down."],
		["Ah Mei the Lantern-Maker", "And now little lumps of fire are turning up all over the market: in the wells, in the cellars, in the middle of the street. Noon Embers, the watchman calls them. They never burn out, and they never set anything else alight. They just lie there glowing, as if they were waiting for something."],
		["Ah Mei the Lantern-Maker", "Bring me four, and I will hang them in my best paper lanterns where we can look at them properly. Something about them is wrong, and I want to know what."],
	],
	"s_yg_return": [
		["Ah Mei the Lantern-Maker", "Look at them. Four lanterns, four embers, and every one of them leans the same way, like a flame in a draught, and there is no draught in here. East. Up the valley, towards the Fusang tree."],
		["Ah Mei the Lantern-Maker", "My grandmother said that when the archer shot down the nine suns, they fell all over the east, and the ground kept them warm. I always thought that was why our wells run hot. I never thought they would wake up."],
		["Yue Ling", "Something is calling them."],
		["Ah Mei the Lantern-Maker", "Then go and find out what. But mind the market on your way out; it has gone strange in the heat. A fox has opened a stall at the dry well, selling water that is not there. The sundial in the square has torn itself off its plinth. And my festival dragon has come alive in the yard behind the shop, because nobody ever came to dance it."],
		["Ah Mei the Lantern-Maker", "And at the east gate there is a woman in a green robe, and wherever she stands the wells sink out of sight. The watchman says she is Hanba, the Drought Fiend. I think she looks lonely."],
	],
	"pre:mirage_fox": [
		["Narrator", "By the dry well a fox in a merchant's cap has set up a stall of glittering water jars, and the queue of thirsty townsfolk reaches halfway back to the square. Every jar is full of nothing."],
		["Mirage Fox of the Dry Well", "Cool water! Clear water! One string of cash a dipper! ...It is hardly my fault if it evaporates on the way to your mouth. It is very hot."],
		["Lin Feng", "You are selling water that is not there. In a drought."],
		["Mirage Fox of the Dry Well", "I am selling hope. Hope is the only thing that keeps in this heat."],
	],
	"post:mirage_fox": [["Narrator", "The jars shimmer and vanish, and so does the stall, and so, rather to its own surprise, does half of the fox's tail. It sits in the dust looking sheepish and pays everybody back. The coins, at least, were real."]],
	"pre:sundial_golem": [
		["Narrator", "In the middle of the market square the great bronze sundial has torn itself off its plinth and stamps round and round, trying to drag its own shadow along by force."],
		["Golem of the Stopped Sundial", "NOON. NOON. NOON. FOR NINE DAYS IT HAS BEEN NOON. I AM A SUNDIAL. DO YOU KNOW WHAT THAT DOES TO A SUNDIAL?"],
		["Yue Ling", "It is only trying to do its job."],
		["Lin Feng", "So are we. Put yourself back on your plinth, and we will go and make your shadow move. I promise."],
	],
	"post:sundial_golem": [["Narrator", "The Sundial stops stamping, walks back to its plinth and sets itself down very carefully, facing true north. Its shadow still points straight down at its feet. It waits, the way the whole market is waiting."]],
	"pre:lantern_dragon": [
		["Narrator", "In the yard behind Ah Mei's shop the festival dragon, forty paces of red paper on bamboo ribs, has come alive and thrashes among the drying racks, every scale an unlit lantern."],
		["The Lantern Dragon Nobody Danced", "I WAS MADE FOR THE LANTERN FESTIVAL! A hundred dancers under my belly! Drums! Firecrackers! Children on their fathers' shoulders! ...WHERE IS THE NIGHT? I was promised a night!"],
		["Lin Feng", "Then we will just have to dance you in the daylight."],
	],
	"post:lantern_dragon": [
		["Narrator", "The Lantern Dragon sags into a heap of paper and ribs, puffing smoke from its nostrils. Ah Mei comes out of the shop and pats its great painted head."],
		["Ah Mei the Lantern-Maker", "When the night comes back you will go first down the main street, with every candle lit. I built you, and I promise."],
	],
	"pre:hanba": [
		["Narrator", "At the east gate stands a stiff, dry figure in a dust-green robe and a tasselled hat, arms held out before her as if to keep the world at a distance. A faded paper talisman flutters on her brow, and the ground round her feet has cracked into tiles."],
		["Hanba, the Drought Fiend", "Do not come any closer. Everybody says that to me, so I say it first. I was a daughter of the Yellow Emperor once. When the Rain Master drowned my father's army, I dried the storm out of the sky and won his war for him. After that I could never go home. Wherever I walk, the rain stops."],
		["Hanba, the Drought Fiend", "For five thousand years they have beaten drums at me and pinned talismans on me and cried 'Go north, Goddess, go north!' Then the sun stopped, and the heat called me here the way a hearth calls a cat. For the first time in five thousand years I am not the worst thing in the sky."],
		["Lin Feng", "You are drying up the market's wells."],
		["Hanba, the Drought Fiend", "I know. I cannot help it. Can you?"],
	],
	"post:hanba": [
		["Narrator", "Hanba sinks down against the gatepost, and for a moment the air around her is only warm. Lin Feng unhooks his water gourd and holds it out. She looks at it for a long time before she takes it."],
		["Hanba, the Drought Fiend", "Nobody has ever given me water. They usually throw it."],
		["Ah Mei the Lantern-Maker", "She can sit in my shop until it gets dark. Paper does not mind the dry. Go on, Sovereign: the east road crosses the millet plains, and the plains have been burning longest."],
	],
	"s_mf_intro": [
		["Old Farmer Tian", "If you have come to buy millet, you are nine days late and a harvest early. Sit, sit, there is a little shade on the shrine step. I have nearly finished praying."],
		["Old Farmer Tian", "Every morning I ask the Lord of Millet for the same thing. Hou Ji taught the first farmer which end of the seed goes in the ground; he knows what a field needs. A little night, please, Lord. And a little rain, if you have any to spare."],
		["Lin Feng", "Night? Not rain first?"],
		["Old Farmer Tian", "Plants do not grow in the sun, child. They eat in the sun. They grow in the dark. Dew comes at night. Rain clouds gather in the cool of the evening. No night, no dew; no dew, no rain; no rain, no growing. And look at it all."],
		["Old Farmer Tian", "In the old shrine of the Rain Master by the river there used to be four rain-stones. Set them at the four corners of a field and the clouds come. A dust devil got into the riverbed and scattered them all over the plain. Find me four, and we will see what a little cloud can do."],
	],
	"s_mf_return": [
		["Old Farmer Tian", "Four stones. One at each corner of the field: there, and there, and there, and... there. Now look up. Look! A cloud. A real cloud, the first in nine days."],
		["Narrator", "A small grey cloud gathers over Old Tian's field, hangs there for a while, thinks about it, and gives up. Not one drop falls."],
		["Old Farmer Tian", "Ah. The air is too hot to let go of its water. Rain wants an evening, the way I said. The stones were never the trouble. The sky is."],
		["Old Farmer Tian", "And you will not get east while the plain is like this. The locusts have crowned themselves a Marquis. The dust devil is still spinning in the dry river like a dog chasing its tail. The old tortoise in the village well has dug in and snaps at every bucket. And on the dyke road..."],
		["Yue Ling", "Something with one leg?"],
		["Old Farmer Tian", "Bifang. The fire crane. Wherever it puts its one foot down, a fire starts. When Bifang appears, the old books say, there will be fires in the towns. Well. It is a little late for an omen."],
	],
	"pre:locust_marquis": [
		["Narrator", "Over the withered millet a swarm of locusts hangs in the air in the shape of a man on a throne. At its heart sits a locust the size of a horse, wearing a crown of chewed stalks."],
		["The Locust Marquis", "We are the Marquis of Ten Thousand Mouths. The millet withered, and we came. That is not cruelty, Sovereign. That is lunch."],
		["Lin Feng", "Then lunch is over."],
	],
	"post:locust_marquis": [["Narrator", "The Marquis comes apart into ten thousand ordinary locusts, which seem embarrassed to be seen together and fly off in ten thousand different directions."]],
	"pre:dust_devil": [
		["Narrator", "In the cracked bed of what used to be the river, a whirlwind of red dust spins and spins and never moves on, sucking up everything it touches."],
		["Dust-Devil of the Dry River", "Round and round and round! The river left! It left without me! I was the wind that rippled it every evening, and it dried up and left me spinning in its bed!"],
		["Yue Ling", "It misses the water."],
		["Lin Feng", "Then hold still for a moment, and we will go and bring the water back."],
	],
	"post:dust_devil": [["Narrator", "The Dust-Devil falls with a long, soft sigh, and the red dust settles along the riverbed in the exact shape of the river that used to run there, every bend and every eddy, waiting."]],
	"pre:well_tortoise": [
		["Narrator", "At the bottom of the village well, where the last of the water has turned to warm mud, an old tortoise with moss on its shell has dug itself in and snaps at every bucket that comes down."],
		["Old Tortoise of the Village Well", "Mine. The last mud on the whole plain. I was in this well before there was a village, and I will be in it after the village is gone, if they would only stop taking my mud."],
		["Lin Feng", "If you dig down instead of in, grandfather, I think you will find a good deal more than mud."],
		["Old Tortoise of the Village Well", "Down? ...Nobody ever said down."],
	],
	"post:well_tortoise": [["Narrator", "Grumbling, the Old Tortoise begins to dig down, and down, and down. There is a long silence. Then the well coughs, gurgles and fills to the brim with cold, clear water from somewhere very deep, and the village cheers so loudly that a locust falls out of the sky."]],
	"pre:bifang": [
		["Narrator", "On the dyke road a great crane with blue-green plumage, red markings and a white beak hops from field to field on a single leg. Wherever its foot comes down, the millet bursts into flame."],
		["Bifang, the One-Legged Fire Crane", "Kraa! I am the omen of fire! Wherever I appear, fire follows! ...It used to be very impressive. Now there is fire everywhere already, and nobody even looks up."],
		["Lin Feng", "You are making it worse."],
		["Bifang, the One-Legged Fire Crane", "An omen does not make anything. An omen announces it. ...All right. I make it a little worse."],
	],
	"post:bifang": [
		["Narrator", "Bifang lands on its one leg, wobbles, and for the first time in a thousand years stands on bare earth without setting it alight. It stares down at its foot in astonishment."],
		["Old Farmer Tian", "There, you see? Even an omen can rest. East now, child. The dyke road climbs into the Valley of Sunrise. If there is a reason for all this, it is up there with the tree."],
	],
	"s_fs_intro": [
		["Feng Meng, the Last Apprentice", "Stop there. Hands where I can see them. ...A sword, not a bow. Good. I have seen enough bows pointed at that tree."],
		["Lin Feng", "You are an archer."],
		["Feng Meng, the Last Apprentice", "I was the second-best archer under heaven. The best was my master, Hou Yi, who stood on that ridge and shot nine suns out of the sky. I was there. I carried his quiver. I counted the arrows."],
		["Feng Meng, the Last Apprentice", "That is the Fusang behind me: a mulberry so tall that the sun used to rest in its crown before it set out each morning. The sun-crows still roost in it, the little ones that ride the sun, and their feathers have been falling all week, hot enough to light the grass."],
		["Feng Meng, the Last Apprentice", "Gather four of them for me. A fallen feather tells an archer which way a bird means to fly."],
	],
	"s_fs_return": [
		["Feng Meng, the Last Apprentice", "Four feathers, and not one of them points west. The sun is not stuck. It is afraid. The last time it flew with its brothers, an archer shot nine of them down in front of it. Now it waits at the top of the sky, where no arrow can reach."],
		["Feng Meng, the Last Apprentice", "I know that kind of waiting. You will have heard what I did. When the whole world is grateful to a man, it is very hard to be his second-best. One evening I took a club of peach wood, and I made sure I never would be again. Four thousand years I have carried that, and it has not got any lighter."],
		["Yue Ling", "Why are you telling us?"],
		["Feng Meng, the Last Apprentice", "Because you are going up that tree, and everyone who climbs it carries a bow. Take this instead: the tenth arrow, the one Emperor Yao took from my master's quiver in the night so that one sun would be left. I stole it from Yao's tomb. I thought that one day I would finish what my master began. I am done thinking that."],
		["Feng Meng, the Last Apprentice", "And take the one thing my master tried to teach me that I never had the patience for. You draw the sword like a bow. You hold it like a promise. You never loose it in anger."],
		["Narrator", "Lin Feng learns the Tenth Arrow Sword."],
	],
	"pre:boiled_crab": [
		["Narrator", "In the hottest of the bathing springs, where Xihe once washed her children before their journeys, an enormous crab sits up to its eyestalks in boiling water. It is bright red, and perfectly content."],
		["The Crab Who Bathes in Boiling Springs", "Ahhh. Nine days of the finest bath of my life. Join me? No? Then go away. You are standing in my sun."],
		["Yue Ling", "Lin Feng... I think it has been cooked."],
		["Lin Feng", "I think it likes it. Come out of there, friend. The pilgrims need these springs."],
	],
	"post:boiled_crab": [["Narrator", "Hauled out at last, the Crab sits steaming on the rocks and very slowly turns from red back to its ordinary green. It does not look at anyone. It is a little ashamed of how much it enjoyed itself."]],
	"pre:ninth_ember": [
		["Narrator", "On the cliff above the springs the ground has split open, and something is climbing out of it: a coal the size of a house, white-hot at the heart, the ember of one of the nine suns that Hou Yi shot down."],
		["Ember of the Ninth Fallen Sun", "Mother is singing. Can you hear her? Nine of us asleep in the ground all these years, and now she is singing us up into the sky again."],
		["Lin Feng", "If all ten of you rise, the rivers will boil."],
		["Ember of the Ninth Fallen Sun", "We did not mind, the first time."],
	],
	"post:ninth_ember": [["Narrator", "The Ember dims from white to orange to a sleepy red, sinks back into its crack in the cliff, and the rock closes over it like a blanket. Far underground, eight other fires are still muttering in their sleep."]],
	"pre:sun_moth": [
		["Narrator", "Round the lower branches of the Fusang a moth with wings as wide as a temple roof beats itself against the light, scorched and glittering, trying to fly up to the sun."],
		["The Moth Who Flew at the Sun", "So bright! It has been so bright for so long! For nine days I have flown at it, and it never comes any closer, and it never goes away!"],
		["Yue Ling", "Lin Feng, its wings are burning. It cannot stop."],
		["Lin Feng", "Then we will stop it for a while. Long enough for it to see that there are other lights."],
	],
	"post:sun_moth": [["Narrator", "The great Moth folds its singed wings and settles on a root in the shade of the Fusang, and for the first time in nine days it looks at something that is not the sun: a hot spring, glittering, with the steam rising off it in the light. It seems to find that very interesting indeed."]],
	"pre:jinwu": [
		["Narrator", "At the crown of the Fusang the topmost branch touches the top of the sky, and there the sun hangs, caught in the leaves like a kite in a tree. On the branch beside it clings a crow with three legs and feathers of beaten gold, too bright to look at."],
		["Jinwu, the Three-Legged Sun Crow", "Kaa! Another one! Another one from the archer's valley! I will not come down, and I will not go west. West is where they fall!"],
		["Narrator", "Lin Feng lays the tenth arrow on the branch between them, and steps back from it."],
		["Jinwu, the Three-Legged Sun Crow", "...That is the tenth arrow. That arrow was meant for me."],
		["Lin Feng", "It was never shot. Nobody is going to shoot it."],
		["Jinwu, the Three-Legged Sun Crow", "Then why are you holding a sword?"],
		["Lin Feng", "Habit. Come on, then. Let us shake the fear out of you first, and then we can talk."],
	],
	"post:jinwu": [
		["Narrator", "The Sun Crow tumbles onto the branch, panting sparks, and dwindles until it is no bigger than a rooster. A very bright rooster. With one of its three feet it pushes the tenth arrow back across the branch to Lin Feng."],
		["Jinwu, the Three-Legged Sun Crow", "Keep it. It is the only arrow in the world that ever spared anybody. ...When the Court fell I kept to the road by myself, the way they taught me. Then, nine days ago, I heard my mother singing for the first time in four thousand years. She was not singing to me. She was singing my brothers up out of the ground."],
		["Jinwu, the Three-Legged Sun Crow", "If all ten of us are in the sky, the archer comes back. Everybody knows that. So I flew as high as I could, where no arrow reaches, and I have been waiting for somebody to tell me it is safe. She has gone over the top of the sky, into the night. She has gone to the Moon Palace to ask the moon-lady for the dark, so that there will be room in the sky for all ten of us again."],
		["Narrator", "From far below, at the foot of the tree, an old voice calls up."],
		["Feng Meng, the Last Apprentice", "Then the night is where you are needed, Sovereign. Walk the sun's road across the top of the sky; the moon's road begins where it ends. And if you see her, the lady of the moon... tell her Feng Meng is sorry. Tell her I should never have come for the elixir."],
	],
	"s_gh_intro": [
		["Chang'e of the Moon Palace", "Please do not shout. Sound carries terribly up here, and the rabbit has only just fallen asleep."],
		["Lin Feng", "You are Chang'e."],
		["Chang'e of the Moon Palace", "I am. And you have walked the sun's road across the top of the sky into the night. Nobody has done that since... well. Since Xihe came, nine days ago."],
		["Chang'e of the Moon Palace", "She is in my palace now, on my throne. She wants the night. She says that if I stop walking the moon round the sky there will be room for all ten of her children again, and she will never again have to watch one of them fall. I have told her no nine times, once each night, and each night it is harder to walk."],
		["Chang'e of the Moon Palace", "I have walked the moon round by myself for four thousand years. Now I can barely lift it. The osmanthus up here blooms with a dew that gives back strength, but Wu Gang has been felling the trees in a temper and the blossoms lie scattered over the frost. Gather four for me, and I can walk one more night."],
	],
	"s_gh_return": [
		["Chang'e of the Moon Palace", "Moon-dew, from all four. Thank you. I can feel my feet again."],
		["Lin Feng", "Before we go on: Feng Meng asked me to tell you something. He is sorry. He says he should never have come for the elixir."],
		["Chang'e of the Moon Palace", "...Four thousand years. I used to lie awake up here imagining him climbing the sky with that club, and imagining what I would say to him."],
		["Chang'e of the Moon Palace", "Tell him... no. I will tell him myself, some night when the moon hangs low over the valley. Tell him to look up."],
		["Chang'e of the Moon Palace", "Now. Xihe is not wicked, Sovereign. She is a mother who watched nine of her children fall out of the sky in a single morning. I would have done anything too. But she cannot have the night."],
		["Chang'e of the Moon Palace", "Before you reach her: Wu Gang has stopped chopping the tree and started chopping everything else. Tiangou, the Heavenly Dog, has smelt how tired the moon is and keeps trying to swallow it. And my rabbit has been pounding elixir for nine days without sleep to keep me on my feet. He will think you have come to steal it. Everyone from the archer's valley has, once."],
	],
	"pre:wu_gang": [
		["Narrator", "Among the stumps of the osmanthus grove a woodcutter with a great axe is hacking at everything in reach: the trees, the frost, the palace railings, the silver stones of the moon itself."],
		["Wu Gang, Woodcutter of the Moon", "Three thousand years! Every cut I made in that tree healed over before I could lift the axe again! The Court said: chop until it falls. It never fell. Now the Court is gone and nobody says stop, so I cannot stop!"],
		["Lin Feng", "I sweep the steps of my sect every morning. They never stay clean. I do not sweep them because they will stay clean."],
		["Wu Gang, Woodcutter of the Moon", "Then why?"],
		["Lin Feng", "Because I like the sound the broom makes. Put the axe down, and I will show you what I mean."],
	],
	"post:wu_gang": [["Narrator", "The axe drops into the frost. Wu Gang sits down on a stump and looks at his hands, which have not been empty in three thousand years. After a while he picks up a fallen branch, snaps it in two for kindling, and stops. It seems to surprise him very much."]],
	"pre:tiangou": [
		["Narrator", "A black dog the size of a hill pads across the frost with its eyes on the moon. Every few steps it opens its jaws and takes a bite out of the sky, and the moonlight dims."],
		["Tiangou, the Dog Who Eats the Moon", "Woof. The moon is tired. Tired things are easy to catch. Every dog knows that."],
		["Yue Ling", "Bad dog."],
		["Lin Feng", "Very bad dog."],
	],
	"post:tiangou": [["Narrator", "Far below, in a thousand villages, people are banging pots and pans to frighten the Heavenly Dog off the moon, the way they always have. Up here, Tiangou rolls onto its back in the frost, lets Yue Ling scratch its belly, and burps up a mouthful of moonlight. The moon brightens a little. The dog looks extremely pleased with itself."]],
	"pre:mortar_rabbit": [
		["Narrator", "Under the last standing osmanthus a white rabbit stands on its hind legs over a mortar of green jade, pounding so fast that the pestle is a blur. Its eyes are very red, and not only because it is a rabbit."],
		["The Jade Rabbit of the Mortar", "THIEF! You came up from the archer's valley, I can smell the bowstring on you! The last one who came from there wanted the elixir too!"],
		["Lin Feng", "We only want to help her."],
		["The Jade Rabbit of the Mortar", "That is exactly what he said! Nine days I have pounded! Nine days! I will pound you too!"],
	],
	"post:mortar_rabbit": [
		["Narrator", "The Jade Rabbit sits down in the frost with the pestle still in its paws, blinks twice, and falls asleep sitting up. Chang'e lifts it into her arms."],
		["Chang'e of the Moon Palace", "Nine days, you silly thing. Nobody asked you to. ...Thank you."],
	],
	"pre:xihe": [
		["Narrator", "In the hall of the Moon Palace, where the frost lies thickest, a woman in robes the colour of dawn sits on Chang'e's throne. Her hair is white-gold, her eyes are red from weeping, and the hall is so hot that the frost runs down the pillars like tears."],
		["Xihe, Mother of the Ten Suns", "I know who you are. You are the one who goes about the world asking everybody to let go of things. I let go of nine children in a single morning. Do you know what it is to hear them fall?"],
		["Lin Feng", "No."],
		["Xihe, Mother of the Ten Suns", "No. And now I can have them back. Their embers are waking. Give me the night, and all ten of my children will be in the sky together again, and I will never have to count them."],
		["Narrator", "Lin Feng holds up the tenth arrow."],
		["Lin Feng", "This was meant for your youngest. Somebody took it out of the quiver so that he would live. He is at the top of the sky now, too frightened to move, waiting for his mother to come and fetch him."],
		["Xihe, Mother of the Ten Suns", "...Then I will fetch him when the whole sky is mine. Out of my way, Sovereign."],
		["Narrator", "Xihe rises from the throne and spreads her sleeves, and the light of ten suns pours out of them as wings. The Mother of the Ten Suns is herself the first sun-crow, from whom all the others hatched."],
	],
	"post:xihe": [
		["Narrator", "Xihe folds her burning wings and is a woman again, sitting on the steps of the throne. The heat goes out of the hall in one long breath. When she speaks, it is very quietly."],
		["Xihe, Mother of the Ten Suns", "He is waiting for me?"],
		["Chang'e of the Moon Palace", "He has been waiting for nine days. So have I. There is room in the sky for both of us, Xihe. There always was. We only ever needed to take turns."],
		["Xihe, Mother of the Ten Suns", "And my nine?"],
		["Yue Ling", "The old books say the Dipper has seven stars that anyone can see and two that nobody can, as if the sky had been keeping places for somebody. Let your nine rise at night, where they cannot burn anything: nine stars turning round the pole."],
		["Lin Feng", "And let them count the days, since the Court will not. Every night they will turn a little further round the sky, and everyone below will know what season it is. And you will be able to see them every single night."],
		["Xihe, Mother of the Ten Suns", "...Nine stars, counting the days. They were always very good at counting. They used to count the clouds the whole way across the sky."],
		["Chang'e of the Moon Palace", "Then it is agreed. Not decreed this time: agreed. The sun by day, the moon by night, and nine stars to count them both."],
	],
	"pre:s_break14": [
		["Narrator", "At the edge of the Moon Palace, where the sun's road meets the moon's, the last tribulation gathers. It is not a storm this time but a dawn and a dusk at once: gold on one side of the sky, silver on the other, and Lin Feng standing where they meet."],
		["Lin Feng", "Yue Ling. Which way do I face?"],
		["Yue Ling", "Both. I think that is the whole point."],
	],
	"post:s_break14": [
		["Narrator", "The tribulation falls as light from both sides at once, and Lin Feng holds it, the way a day holds a morning and an evening. He becomes the first cultivator of Sun-Moon Harmony: a realm in which nothing has to win."],
		["Narrator", "In the east Xihe climbs into her chariot at the foot of the Fusang, her youngest son clambers in beside her, and she sings to him the whole way across the sky. That evening, for the first time in nine days, the sun goes down."],
		["Chang'e of the Moon Palace", "My turn."],
		["Narrator", "The moon rises full over the world, and round the pole nine new stars rise in the shape of a ladle and begin, very carefully, to count. In Yanggu Ah Mei sells every lantern she owns, and the Lantern Dragon goes first down the main street. On the ridge above the Fusang, Feng Meng looks up at the moon for a long time, and the moon looks back."],
		["Narrator", "And on Azure Cloud Mountain the sundial's shadow moves again, the lotus pond stops steaming, Little Wan falls asleep at a reasonable hour for the first time in nine days, and Lin Feng sweeps the steps in the cool of the evening, and stops when they are clean enough."],
	],
	# ---- Part X: The Nine Cauldrons
	"recall8": [
		["Narrator", "The sun goes down and the moon comes up, and for a whole month they take turns as politely as two old neighbours at a well. Lin Feng sweeps the steps in the mornings and counts the nine new stars in the evenings, and nothing at all happens. It is wonderful."],
		["Narrator", "Then, one morning, Archivist Lan comes running across the courtyard with a scroll in each hand and her hair still in its nightcap."],
		["Archivist Lan", "Elder! The map is wrong! The great map in the Library, the Court's survey, three hundred years on that wall, and it is wrong! The rivers have moved. The coasts have moved. The bamboo forest has grown a bay. The road to the Dawn Market goes round three bends that were never on any map of mine!"],
		["Elder Qing Xuan", "Then the map is wrong, Archivist, and not the land. Bring it to the hall. Lin Feng, you too. I believe I know what this is, and for once it may be good news. Mostly."],
	],
	"s_p10_home": [
		["Elder Qing Xuan", "Look at the old map. Every province a square. Every border ruled straight, every river bent at right angles to fit inside its square, every coast a line. Did you never think that strange?"],
		["Lin Feng", "I thought that was how maps were."],
		["Elder Qing Xuan", "That was how the Heavenly Court's maps were. When the Court took the sky, it took the land as well. It surveyed the world into squares, so that every square could be taxed in years, and the land, being patient, held the shape it was told to hold. The Weaver sewed the seams. The Court pinned the corners."],
		["Elder Qing Xuan", "Pinned them with the Nine Cauldrons of Yu. When Yu the Great tamed the Flood he cast nine bronze cauldrons and engraved on them the true map of the Nine Provinces: every mountain, every river and every strange beast. Whoever held the cauldrons held the shape of the world. The Court carried them off to the sky and recut the engravings into squares."],
		["Lin Feng", "And now the Court is gone, the Weaver has unpicked her seams, and the sun and the moon take turns..."],
		["Elder Qing Xuan", "And the land has stopped pretending. It is lying down in its own shape again, like a cat let out of a box: rivers finding their old beds, coasts their old bays, roads following the hills instead of the ruler. The world you walked through on your way here is the true one, disciple. It is beautiful."],
		["Yue Ling", "You said mostly good news."],
		["Elder Qing Xuan", "Land that moves floods. Rivers that remember their old beds remember their old floods too. And under the Court's squares there was something Yu never killed, only channelled: Gonggong, the Flood God, who once broke a pillar of heaven with his head. The north is very wet this morning. Ask Archivist Lan what the Library remembers of the cauldrons, and then take the north gate."],
		["Elder Qing Xuan", "We had the Smith knock it through the wall at dawn. The old north wall was only ever there because the Court's map said so."],
	],
	"s_p10_archive": [
		["Archivist Lan", "The cauldrons. Yes. We have one rubbing, taken from the Ninth Cauldron before the Court carried them off. Look: mountains drawn like waves, rivers like dragons, and in the margins every strange creature of every province, so travellers would know what they met on the road. The nine-headed snake. The fish as big as an island. The glutton with no body."],
		["Archivist Lan", "The Court's copy has none of that. Squares, numbers and the tax in years per square. They even squared off the coast."],
		["Lin Feng", "Where are the cauldrons now?"],
		["Archivist Lan", "The rubbing says they were cast at Tushan, on Mount Kuaiji, by the Tushan clan. Their foundry town is still there, past the Dragon Gate at Longmen and over the Drowned Fields. If anyone alive knows what became of the cauldrons, it is a Tushan caster."],
		["Archivist Lan", "And Lin Feng: there is a cartographer at Cloudfoot, the post town below the north gate. Pei. He has written to me every month for twelve years to tell me that the Court's maps are lies. He will be insufferable this morning. Go and let him gloat at you. Nobody knows the north roads better."],
	],
	"s_p10_road": [
		["Cartographer Pei of Cloudfoot", "Ha! HA! Twelve years! Twelve years I wrote to that Library! The Court's maps are lies, the rivers do not bend at right angles, nobody's coast is a straight line! And did anyone listen?"],
		["Lin Feng", "The Archivist says you were right."],
		["Cartographer Pei of Cloudfoot", "Of course I was right. A good map keeps six rules: true scale, true direction, true distance, and the high, the low and the winding, each measured as they are. The Court kept one rule: squares. I have been up all night redrawing the north. Look at it. Look how it curves!"],
		["Cartographer Pei of Cloudfoot", "But I am not only gloating. The ferry at Longmen has stopped sending the post. The river is rising there, three feet a day, and the golden carp have stopped leaping the Dragon Gate. When the carp will not leap, the boatmen say, the river is afraid of something upstream."],
		["Cartographer Pei of Cloudfoot", "Here: the north road, drawn properly. The Lotus Seal on it will open for you; I think it was only ever waiting for someone carrying a true map. Give my regards to Harbourmistress Jiang at Longmen. Tell her I want my maps back."],
	],
	"s_dg_intro": [
		["Harbourmistress Jiang Yao", "If you have come for the ferry, it is not running. If you have come for the post, that is not running either. If you have come to tell me the river is high, I know. I measure it every hour on the flood stele by the temple, and I have run out of stele."],
		["Lin Feng", "Cartographer Pei sends his regards. He wants his maps back."],
		["Harbourmistress Jiang Yao", "Ha. Tell him the river ate them. ...Longmen is a ferry town, Sovereign: a thousand years of boats crossing below the Dragon Gate. Every spring the golden carp swim up from the sea and leap the falls, and the ones that clear the gate become dragons. That is how the river knows it is spring."],
		["Harbourmistress Jiang Yao", "This spring the carp came up the river and stopped below the falls, and sat there, and sulked, and the river has risen every day since. Something upstream is pulling the water back up the gorge, and the carp are afraid to jump into it."],
		["Harbourmistress Jiang Yao", "When a carp tries the gate and falls short, it sheds a golden scale. The river-readers in my family can read the water in them: how high, how fast, and which way the fear is coming from. Bring me four scales from below the falls, and I will read you the river."],
	],
	"s_dg_return": [
		["Harbourmistress Jiang Yao", "Four scales. Hold them to the light... see the rings? Like a tree's. Every ring is a flood. And look here, at the edge: the new rings are wound the wrong way. The river is flowing backwards in its sleep."],
		["Harbourmistress Jiang Yao", "In my great-grandmother's day there was a stele at the Dragon Gate that said: Here Yu cut the mountain and let the river through; do not dam it. The Court took it for its archive. Somebody upstream is damming the river, and has been ever since the land started moving."],
		["Yue Ling", "Who would dam a river?"],
		["Harbourmistress Jiang Yao", "Somebody who remembers when rivers were dammed. The Drowned Fields lie beyond the gorge; that is where the old dykes are. But Longmen is in a mood. The carp-king below the falls will not leap and will not let anyone else leap. Black Eel and his river-rats are looting the flooded warehouses. The temple bell has slid into the river and rings underwater all night."],
		["Harbourmistress Jiang Yao", "And the stone lion of the ferry stage has woken up and will not let anybody past it. Longmen, Sovereign. In a mood."],
		["Harbourmistress Jiang Yao", "And the River Earl himself, He Bo, has come up out of the water at the ferry stage demanding a bride, the way he used to before Magistrate Ximen Bao threw his priests in the river after the last one."],
	],
	"pre:sulking_carp": [
		["Narrator", "In the pool below the Dragon Gate a golden carp the size of a ferry lies in the shallows with its fins folded, glaring at the falls."],
		["The Carp Who Would Not Leap", "I have swum up from the sea for nine hundred years to make this leap, and the river has turned backwards at the top. You want me to jump into that? You jump into that."],
		["Lin Feng", "If I clear the gate, will you try?"],
		["The Carp Who Would Not Leap", "If you clear the gate, I will think about it. First you have to get past me. A carp has its pride."],
	],
	"post:sulking_carp": [["Narrator", "Lin Feng runs up the face of the falls on the light-body and lands on the lip of the Dragon Gate, soaked to the skin. Below, the carp considers this for a long moment, then flicks its tail, leaps, and clears the gate by a hand's breadth. It comes down on the far side as a small, very surprised golden dragon, and all the way down the river the other carp begin to leap."]],
	"pre:eel_king": [
		["Narrator", "In the flooded warehouses by the quay a gang of river-rats is loading a stolen sampan, and round its prow coils a black eel as long as the boat, wearing a magistrate's hat that he has certainly not earned."],
		["Black Eel, King of the River-Rats", "A flood is good for business, little immortal. Everything floats! Everything is salvage!"],
		["Lin Feng", "Everything belongs to somebody."],
		["Black Eel, King of the River-Rats", "Not if it floats."],
	],
	"post:eel_king": [["Narrator", "The Eel King slithers off his sampan into the river with his hat floating after him. His rats sheepishly unload the warehouses, while Fishwife Lu stands on the quay counting every bale back in, out loud."]],
	"pre:drowned_bell": [
		["Narrator", "Below the temple steps the river has risen over the old bronze bell, and it rings under the water, slow and deep, so that every boat on the river shivers in time."],
		["The Drowned Temple Bell", "BONG. The water is in my mouth. BONG. I cannot stop ringing the hours. BONG. Nobody can hear the hours under a river."],
		["Yue Ling", "Then let us get you out of it."],
	],
	"post:drowned_bell": [["Narrator", "Lin Feng and Yue Ling haul the bell up the temple steps between them, streaming water, and hang it back on its beam. It rings once, clear and dry, and all along the quay people stop and look up, because for the first time in a month they know what time it is."]],
	"pre:stone_lion": [
		["Narrator", "On the ferry stage a stone lion as big as a boathouse has climbed down off its plinth and paces the planks, roaring at the river. Its stone mane is green with moss, and the ball under its paw has rolled into the water."],
		["The Stone Lion of the Ferry Stage", "I guard the ferry! I have guarded the ferry for six hundred years! And the river came up over my paws in the night and took my ball, and now I cannot remember which side of the river I am guarding!"],
		["Yue Ling", "It is having a bad dream. Stone lions dream very slowly."],
		["Lin Feng", "Then we will wake it up gently. As gently as you can wake up a boathouse."],
	],
	"post:stone_lion": [["Narrator", "Lin Feng fishes the stone ball out of the shallows and rolls it back under the lion's paw. The lion blinks, climbs back onto its plinth, sits down facing both banks at once, and is stone again, with a slightly embarrassed expression that Boatwright Gao swears was never carved there."]],
	"pre:he_bo": [
		["Narrator", "At the ferry stage the river heaves itself up into the shape of a man in a robe of yellow water, crowned with river-weed, riding a chariot drawn by two white fish."],
		["He Bo, Earl of the Yellow River", "Where is my bride? Every spring for a thousand years Longmen sent me a girl in a painted boat, until that magistrate Ximen Bao threw my priests in after her and asked me whether I would like them instead. Now the river is mine again. I want a bride."],
		["Lin Feng", "Nobody is sending you anybody."],
		["He Bo, Earl of the Yellow River", "Then I will keep the river high until they do."],
	],
	"post:he_bo": [
		["He Bo, Earl of the Yellow River", "...I never wanted the brides. I wanted somebody to come down to the river on purpose. Everyone only ever came to cross it."],
		["Harbourmistress Jiang Yao", "Then come up to the temple on festival days, Earl, and we will feed you dumplings like everybody else's god."],
		["He Bo, Earl of the Yellow River", "...Dumplings?"],
		["Narrator", "He Bo gives Lin Feng the old flood tablet of his office, scored with the height of every flood since Yu's day, and points upstream with a dripping finger. The water is being pulled back up into the Drowned Fields, he says. Somebody there is building a dam out of earth that grows. Take my tablet to my temple first; they will want to read it."],
	],
	"s_dg_temple": [
		["Shrine-Maiden Hua", "The Earl's own flood tablet? He gave it to you? He has never given anybody anything except damp."],
		["Shrine-Maiden Hua", "Every flood since Yu is cut into it, look: one notch for every spring the river came over the quay. Most years one notch. Here, a hundred years with none, when the Court first squared the map and pinned the river in a straight line. And then here, these last months, a notch every day."],
		["Lin Feng", "The land moved, and the water came up."],
		["Shrine-Maiden Hua", "The water always comes up when the land moves; my grandmother said so, and the Earl's tablet says so too. We will keep it in the temple where he can visit it. Dumplings on the Double Fifth, Earl, and a song on the first full moon. That is the new arrangement."],
		["Shrine-Maiden Hua", "The road over the gorge goes on to the Drowned Fields. Take the tablet's rubbing with you, Sovereign. Upriver they have a carver at Tushan who can read old marks the way I read the river. If anyone can tell you what these notches mean, it is Stone-Carver Shi."],
	],
	"s_df_intro": [
		["Bo Yi of the Dykes", "Mind the dyke. It is the only dry thing for a day in any direction, and it is mine."],
		["Bo Yi of the Dykes", "I am Bo Yi. I was a young man when I worked these dykes with Yu, four thousand years ago, and I have been an old man ever since. Yu used to say: you cannot hold water still, you can only give it somewhere to go. We dug channels, not walls, and for four thousand years the fields stayed dry."],
		["Bo Yi of the Dykes", "Now look. The water comes back up the channels every night, and the old earth walls rise out of the flood like loaves in an oven. Swelling Earth. Xirang. Gun's earth."],
		["Lin Feng", "Gun?"],
		["Bo Yi of the Dykes", "Yu's father. Before Yu, Gun tried to stop the Flood. He stole the Xirang, the earth that grows by itself, from the storehouse of heaven, and built walls with it. For nine years the walls grew, and for nine years the water rose behind them, until they broke and drowned everything they had kept dry."],
		["Bo Yi of the Dykes", "Heaven executed him on Feather Hill for the theft. His body did not rot for three years, and when they cut it open, Yu came out."],
		["Bo Yi of the Dykes", "Clods of Xirang are rising out of the water all over the fields. Bring me four before they grow into walls, and we will see whose they are."],
	],
	"s_df_return": [
		["Bo Yi of the Dykes", "Four clods. Feel them: warm, and growing even in your hands. And look at this one. Fingerprints, pressed into the clay. A man's hands, building."],
		["Bo Yi of the Dykes", "Gun's hands. He has come back to finish his dam. Four thousand years dead, and when the land started moving and the water started rising, the first thing he did was come back and try to stop it again. He never learned the other way. He never had the chance."],
		["Yue Ling", "He is trying to help."],
		["Bo Yi of the Dykes", "So he was, the first time. Go gently with him, if you can. But the toad that swallowed the old dykes has swollen up fit to burst, a heron has made himself lord of the drowned paddies, a dragon of mud has broken out of the last of Yu's channels, and the old turtle that carried Gun's earth is still walking in circles with it on its back. You will meet all of them before you meet him."],
	],
	"pre:toad_matriarch": [
		["Narrator", "A toad the size of a farmhouse squats across the dyke road with her cheeks bulging. Every time she swallows, another field goes under."],
		["The Toad Who Swallowed the Dykes", "Glorp. The water was going somewhere. I stopped it. Glorp. Now it is all MINE."],
		["Lin Feng", "Spit it out."],
	],
	"post:toad_matriarch": [["Narrator", "The Toad spits a whole field's worth of water out in one long rush, back down the channel where it belongs, and shrinks to an ordinary, rather embarrassed toad on a lily pad."]],
	"pre:heron_lord": [
		["Narrator", "On a dead tree above the drowned paddies stands a heron as tall as a watchtower, a fish in its beak and a magistrate's sash round its neck."],
		["Heron Lord of the Drowned Paddies", "These are my waters now. I have appointed myself Lord of the Paddies. Every fish pays a tax of one fish."],
		["Yue Ling", "That is just eating them."],
		["Heron Lord of the Drowned Paddies", "That is what a tax is, child. Ask any square on the old map."],
	],
	"post:heron_lord": [["Narrator", "The Heron Lord takes off his sash, looks at it for a while, and flies away north with as much dignity as a wet heron can manage."]],
	"pre:mud_dragon": [
		["Narrator", "The last of Yu's channels has caved in, and out of the slurry rises a dragon made of mud, shedding clods of Xirang from its flanks as it coils."],
		["Lin Feng", "It is made of the walls. Break it, and the channel opens."],
	],
	"post:mud_dragon": [["Narrator", "The Mud Dragon slumps into a long low bank of earth, and through the gap behind it the water begins to run away downhill, chuckling, the way water does when it is going where it wants to."]],
	"pre:carrier_turtle": [
		["Narrator", "On the high bank of the old dyke a turtle the size of a hill plods in a slow circle, an enormous load of earth heaped on its shell, and a horned owl perched on top of the load calls out the way."],
		["The Turtle Who Carried Gun's Earth", "Left... left... a little more... The old texts say that owls and turtles helped Gun carry his earth. Nobody asked us. We were only there. Four thousand years we have carried this load, and nobody ever told us where to put it down."],
		["Lin Feng", "Down. Anywhere. You can put it down now."],
		["The Turtle Who Carried Gun's Earth", "...Can we? Nobody has ever said that. You had better make us."],
	],
	"post:carrier_turtle": [["Narrator", "The load slides off the turtle's shell in one long avalanche and becomes a small new hill beside the dyke, and the turtle stretches out its neck further than it has stretched in four thousand years. The owl hoots once, approvingly, and goes to sleep on the new hill."]],
	"pre:gun": [
		["Narrator", "In the middle of the flood, where the water is deepest, a yellow dragon labours on a wall of growing earth, pressing clods into place with its claws. Its scales are cracked like dry clay, and it does not stop working even to look at them."],
		["Gun, Who Stole the Swelling Earth", "Do not stand there. Carry earth. The water is rising. The water is always rising. If I build the wall high enough, it will stop."],
		["Lin Feng", "Your son did it another way."],
		["Gun, Who Stole the Swelling Earth", "My son? ...Yu? He was born from me after they killed me. I never met him. Did he... did he do well?"],
		["Yue Ling", "He saved the world."],
		["Gun, Who Stole the Swelling Earth", "Then help me build the wall high enough, and I will have saved it too."],
	],
	"post:gun": [
		["Narrator", "The yellow dragon's wall crumbles, and Gun sinks down beside it in the shape of a tired old man covered in clay. Bo Yi wades out through the falling water and sits down beside him."],
		["Bo Yi of the Dykes", "He dug channels, old friend. He let the water go where it wanted to, and then it was not a flood any more, only a river."],
		["Gun, Who Stole the Swelling Earth", "...Channels. Of course. You cannot hold water still. ...He did not get that from me."],
		["Gun, Who Stole the Swelling Earth", "Ask the Tushan casters what became of the cauldrons. When they were stolen, the land forgot its shape, and when the land forgets its shape the water forgets its way. And something under Mount Buzhou has been waiting four thousand years for the water to forget."],
	],
	"s_ts_carver": [
		["Stone-Carver Shi", "A rubbing of He Bo's tablet? Give it here. Spectacles... there. Hm. Hm! Whoever cut these was a river, not a carver. No craft at all. Very honest."],
		["Stone-Carver Shi", "Look how the notches change. Before the Court, they wander, like the river: a flood here, a dry year there. When the Court squared the land, they stop, a hundred years without a flood. The river was pinned so tight it could not even complain."],
		["Stone-Carver Shi", "And here at the end they come every day, all leaning one way, north-west, like grass in a wind. The river is not flooding, Sovereign. It is being pulled. Something in the north-west is pulling every river in the land towards it."],
		["Yue Ling", "The Drowned Fields were the same: the water running backwards up Yu's channels."],
		["Stone-Carver Shi", "Then it is old, and it is big, and it has waited a long time for the map to break. Go and see Tu Lan at the foundry. If anybody can mend a map, it is a Tushan caster."],
	],
	"s_ts_intro": [
		["Tu Lan, Last of the Cauldron-Casters", "Stand back from the pit, it spits. ...Visitors who are not after a bell. You must be the Sovereign. The ferry gossip got here before you did."],
		["Tu Lan, Last of the Cauldron-Casters", "This is Tushan. My clan cast the Nine Cauldrons for Yu, four thousand years ago, from the bronze the governors of the nine provinces brought him as tribute. Each cauldron carried a province: its mountains, its rivers and its strange beasts, so that travellers would know what they met on the road."],
		["Tu Lan, Last of the Cauldron-Casters", "The Court came for them a thousand years ago, carried them up to the sky and recut the engravings into squares. When the Court fell, the cauldrons fell too. All nine, smashed and scattered over Mount Kuaiji like seed."],
		["Tu Lan, Last of the Cauldron-Casters", "I can recast them; my clan kept the moulds. But I need the old engravings, and the only true ones left are on the shards. Bring me four, and I will show you the land the way Yu drew it."],
	],
	"s_ts_return": [
		["Tu Lan, Last of the Cauldron-Casters", "Four shards. Look at the curve of this river, and this coast. No ruler ever touched it. ...It matches. It matches Pei's new map, line for line."],
		["Tu Lan, Last of the Cauldron-Casters", "The land is not breaking, Sovereign. It is remembering. Yu's cauldrons were never a cage; they were a portrait. The Court made a cage of them. Now the cage is broken and the land is going back to looking like itself."],
		["Lin Feng", "Then why is the water rising?"],
		["Tu Lan, Last of the Cauldron-Casters", "Because there is somebody who never wanted the land to have any shape at all. Gonggong. When he lost the war for heaven he ran his head into Mount Buzhou, the pillar of the north-west, and the sky tilted and every river ran east. Yu chained his flood in channels. With the cauldrons broken, Gonggong is pulling the water back towards Buzhou, to drown the map before it can settle."],
		["Tu Lan, Last of the Cauldron-Casters", "Hold out your sword. A caster's blessing: a blade that remembers the weight of nine provinces. Then help me clear the mountain, and I will cast the Ninth Cauldron again, the true way."],
		["Narrator", "A new technique settles into Lin Feng's hands, heavy as bronze and steady as a mountain: the Nine Cauldrons Sword."],
		["Tu Lan, Last of the Cauldron-Casters", "The pits have woken. There is a slag serpent in the casting pits, the Stone Mother has come down off her hill, the giant Fangfeng, who came late to Yu's assembly four thousand years ago, is still hurrying to get here, and the Taotie, the glutton cast on every cauldron as a warning, has come alive in the casting yard and is eating the engravings off the shards."],
		["Tu Lan, Last of the Cauldron-Casters", "Oh, and the white nine-tailed fox of Tushan has come down off the hill to see what all the noise is. She is very old, very polite, and she bites."],
	],
	"pre:slag_serpent": [
		["Narrator", "Out of the casting pit rears a serpent of molten bronze and slag, dripping fire, gnawing on a half-cast bell."],
		["The Slag Serpent of the Casting Pits", "Hot! Hot! Everything is hot and soft and lovely! Why would anyone let it cool into a shape?"],
		["Lin Feng", "Because a bell has to hold its shape to ring."],
	],
	"post:slag_serpent": [["Narrator", "The Slag Serpent cools in the air, slows, and sets into a long bronze bell-rope of a thing, which Tu Lan's apprentices immediately start arguing about how to use."]],
	"pre:stone_mother": [
		["Narrator", "On the hill above Tushan stands a woman of grey stone, one hand raised to shade her eyes as if she is watching a road."],
		["Tu Lan, Last of the Cauldron-Casters", "The Tushan girl. Yu's wife. She waited on that hill while he dug the rivers, and when she saw him digging in the shape of a bear she was so frightened she turned to stone. Their son was born from the stone. Since the cauldrons broke, she has been walking."],
		["The Stone Mother of Tushan", "Have you seen him? A man with a hoe and a limp, who never comes home? He said he would pass the door three times and not come in. He has passed it four thousand times."],
		["Lin Feng", "He finished his work long ago."],
		["The Stone Mother of Tushan", "Then why is the water rising?"],
	],
	"post:stone_mother": [["Narrator", "The Stone Mother sits down on her hill and is still. Then I will wait for the water to go down, she says, the way I always waited. A little moss begins to grow on her shoulder, which seems to comfort her."]],
	"pre:fangfeng": [
		["Narrator", "A giant three spans tall comes striding down the mountain road with his robe flapping behind him, shouting."],
		["Fangfeng, the Giant Who Came Late", "Am I late? AM I LATE? Yu called every lord in the land to the assembly at Kuaiji, and I was late, and they cut off my head! Four thousand years I have been hurrying to get here!"],
		["Yue Ling", "The assembly ended four thousand years ago."],
		["Fangfeng, the Giant Who Came Late", "Then I am VERY late!"],
	],
	"post:fangfeng": [
		["Fangfeng, the Giant Who Came Late", "...They executed me for being late. Is the Court so very strict about time?"],
		["Lin Feng", "There is no Court any more. You can be as late as you like."],
		["Fangfeng, the Giant Who Came Late", "...As late as I like."],
		["Narrator", "The giant lies down on his back on the mountainside and watches the clouds go by, for the first time in four thousand years not hurrying anywhere at all."],
	],
	"pre:tushan_fox": [
		["Narrator", "Through the pines above the casting yard pads a white fox with nine tails, each one tipped with fire, looking back over its shoulder as if it wants to be followed."],
		["Tu Lan, Last of the Cauldron-Casters", "The white fox of Tushan! When Yu came this way at thirty, unmarried and still digging, a white fox with nine tails crossed his path, and the old song says: whoever sees the white fox will be king, and whoever marries in Tushan will prosper. He married my clan's daughter that same year. The fox only comes when something is about to change."],
		["The White Nine-Tailed Fox of Tushan", "Something is about to change. I came to see whether you are the one changing it. Catch me, if you are."],
	],
	"post:tushan_fox": [["Narrator", "The fox lets itself be caught, sniffs Lin Feng's hand, then Yue Ling's, and sits down between them with its nine tails curled round all three. It looks smug. Then it is gone, and nine little flames hang in the air over the casting yard for a moment before they go out."]],
	"pre:taotie": [
		["Narrator", "In the casting yard at the top of the mountain, a monster that is almost all face has climbed out of the bronze: two great eyes, a curling snout, horns, a mouth that goes on and on, and no body at all. It is licking the engravings off the cauldron shards."],
		["Taotie, the Glutton on the Cauldron", "Mountains! Rivers! Delicious! Nine provinces, and I have eaten eight! When I have eaten the ninth there will be no map at all. Only me!"],
		["Tu Lan, Last of the Cauldron-Casters", "The taotie was cast on the cauldrons as a warning against greed. It was meant to be a picture, not a guest!"],
	],
	"post:taotie": [
		["Narrator", "The Taotie shrinks back into the bronze until it is only a curling pattern on a shard again, its eyes rolling sullenly. Tu Lan pours the shards into her crucible, and by evening the Ninth Cauldron stands in the yard once more. On its belly, in raised bronze, is the land: every bay and every bend of it."],
		["Tu Lan, Last of the Cauldron-Casters", "The ninth of nine. Take this rubbing of it to Mount Buzhou and show it to Gonggong. He has never seen the land drawn the way it really is. Perhaps nobody ever showed him."],
	],
	"s_bz_intro": [
		["Yinglong, Who Dug the Rivers", "A traveller at Buzhou. I have not had a visitor since Yu, and he only came to borrow my tail."],
		["Yinglong, Who Dug the Rivers", "I am Yinglong. When Yu dug the rivers, I flew ahead of him and dragged my tail through the mud to show him where they should go. Every river you have ever crossed, I drew first. Now look at them. They are all running backwards, uphill, into this black lake."],
		["Yinglong, Who Dug the Rivers", "Gonggong is beneath it. Long ago he fought Zhuanxu for the throne of heaven and lost, and in his rage he ran his head into Mount Buzhou, the pillar of the north-west. The pillar broke. The sky tilted towards the north-west and the earth towards the south-east, and that is why every river runs east to the sea."],
		["Yinglong, Who Dug the Rivers", "Now he is pulling the water back. If he fills the lake high enough he can lift the broken pillar on the flood and ram it again, and this time there is no Nuwa to mend what breaks. The stones of the old pillar are scattered round the lake. Bring me four, and we will see how badly it is cracked."],
	],
	"s_bz_return": [
		["Yinglong, Who Dug the Rivers", "Four stones of Buzhou. Black, and wet, and every one of them cracked along the same line. He is close."],
		["Lin Feng", "Tu Lan cast the Ninth Cauldron again. This is a rubbing of it: the land, as it really is."],
		["Yinglong, Who Dug the Rivers", "...My rivers. Every one of them, where I drew them. Oh, Sovereign. Show him this. Gonggong has only ever seen the land as a thing to drown or a thing to rule. Nobody ever showed him that it was beautiful."],
		["Yinglong, Who Dug the Rivers", "But first: his son Xiu, who loved roads, has come back to wander the shore. The Kun, the great fish of the northern darkness, has swum up into the lake. And Xiangliu, his minister with nine heads, has been poisoning every spring round Buzhou, so that nothing can grow where the water has been. Nine heads, Sovereign, and each one eats from a different mountain."],
		["Yinglong, Who Dug the Rivers", "And Kuafu, who chased the sun and drank the rivers dry, is lying by the lake, thirsty again."],
	],
	"pre:xiu": [
		["Narrator", "A young man in a dusty travelling cloak walks the shore of the black lake in circles, a pack on his back and a map in his hand that is mostly holes."],
		["Xiu, Gonggong's Son Who Loved Roads", "Which way is the road? There used to be a road. There was always a road. I walked them all when I was alive, every one, and when I died they made me the god of them. And now they have all moved!"],
		["Lin Feng", "They have not moved. They have only stopped being straight."],
	],
	"post:xiu": [["Narrator", "Lin Feng gives Xiu Cartographer Pei's map of the north. Xiu sits down on a rock to read it, laughs, and traces the bends with his finger. Oh, that is much better, he says. You cannot get lost on a road that goes where the land goes. He sets off south, whistling, and travellers still leave him a cup of wine at his shrine in Cloudfoot."]],
	"pre:kun": [
		["Narrator", "The black lake heaves, and a fish rises out of it so large that its back is an island with trees on it: the Kun of the Northern Darkness. When it is ready, the old books say, it becomes the Peng, a bird whose wings are clouds hung across the sky."],
		["Kun of the Northern Darkness", "...Is it time? Is it time to become a bird? The water is so high. I thought this was the sea."],
		["Yue Ling", "It is not the sea. It is a flood. You will know the sea when you get there."],
	],
	"post:kun": [["Narrator", "The Kun sinks, rolls once, and swims away down the river towards the east and the real sea. Weeks later, fishermen at the Starfall Ferry will see a bird whose wings cover the whole sky, and nobody will believe them."]],
	"pre:xiangliu": [
		["Narrator", "Nine heads rise out of the poisoned springs round the lake, each on its own long serpent neck, each with a human face, and all nine of them talk at once."],
		["Xiangliu, the Nine-Headed Minister", "We are Xiangliu, minister to Gonggong. We eat from nine mountains. Wherever we spit, the water turns bitter and nothing grows. Yu killed us once. Our blood was so foul that he dug the ground three times to bury it, and three times it sank."],
		["Lin Feng", "Then let us not spill any."],
		["Xiangliu, the Nine-Headed Minister", "...That is not how this usually goes."],
	],
	"post:xiangliu": [["Narrator", "Lin Feng and Yue Ling tie the nine necks into a knot so complicated that Xiangliu spends the rest of the day untying itself, arguing with itself about which head goes under which. Meanwhile the springs round the lake run clear again."]],
	"pre:kuafu": [
		["Narrator", "A giant with a staff of peach-wood kneels at the edge of the black lake, drinking it. Each swallow lowers the water by a hand's breadth, and each time, the rivers pour more in."],
		["Kuafu, Who Drank the Rivers Dry", "I chased the sun across the world once, and I grew so thirsty that I drank the Yellow River dry, and the Wei after it, and died on the way to the northern lake. My staff grew into a peach forest where I fell. Now there is so much water. I thought, at last, I can drink until I am not thirsty."],
		["Yue Ling", "If you drink the lake, the rivers will keep pouring into you for ever."],
		["Kuafu, Who Drank the Rivers Dry", "Then I will never be thirsty again. Is that not what everyone wants?"],
	],
	"post:kuafu": [["Narrator", "Kuafu sits back on his heels, water running down his beard, and laughs for the first time in a very long time. He plants his peach-wood staff by the lake, and by the time the flood has gone down there are blossoms on it."]],
	"pre:gonggong": [
		["Narrator", "The black lake rises in a single wave, and on its crest stands Gonggong: a man's body on a serpent's tail, hair like red fire, eyes like a storm over the sea. Behind him the stump of Mount Buzhou lifts out of the water, carried on the flood."],
		["Gonggong, God of the Flood", "The map is broken. Good. Let it all wash away: squares, circles, bays, I do not care. I lost heaven because somebody drew a line and put me on the wrong side of it. Water does not stay on any side of any line."],
		["Narrator", "Lin Feng unrolls the rubbing of the Ninth Cauldron."],
		["Lin Feng", "This is the land as it really is. No squares. No lines but the ones the water drew."],
		["Gonggong, God of the Flood", "...The rivers are on it."],
		["Yinglong, Who Dug the Rivers", "Every one. Where we drew them. Where you made them run, the day you broke the pillar."],
		["Gonggong, God of the Flood", "...I made them run east?"],
		["Lin Feng", "Every river in the world runs east because of you. The whole map is your shape."],
		["Gonggong, God of the Flood", "Then let me see whether it can hold me!"],
	],
	"post:gonggong": [
		["Narrator", "Gonggong crashes down into his lake, and the wave goes out of him, and the lake goes still. He looks at the rubbing for a long time."],
		["Gonggong, God of the Flood", "Every river runs east because I broke a mountain in a rage. And they made a land of it. People built ferries on it. Fed carp. Named their children after it."],
		["Yinglong, Who Dug the Rivers", "That is what happens to rage, if somebody digs it a channel."],
		["Gonggong, God of the Flood", "...Then let the water go where it goes. I will not pull it back. Somebody should keep an eye on the north-west, though. It tilts."],
		["Narrator", "The flood runs back down every river at once, east, to the sea, the way it always has. The stump of Mount Buzhou settles into the lake, and Gonggong curls round it and goes to sleep."],
	],
	"pre:s_break15": [
		["Narrator", "The tribulation that gathers over Buzhou is not lightning. It is the land itself: every mountain and river of the Nine Provinces rising round Lin Feng like the engravings on a cauldron, asking to be held in its own shape."],
		["Yue Ling", "What do you do with a map that wants to move?"],
		["Lin Feng", "Nothing. You let it be the land. You only draw it."],
	],
	"post:s_break15": [
		["Narrator", "Lin Feng takes the tribulation into himself the way a river takes the rain, without holding on to it, and becomes the first cultivator of Mountain-River Oneness: a realm in which the land is allowed to be its own shape."],
		["Narrator", "At Tushan, Tu Lan begins casting the other eight cauldrons, and on each one she engraves the land as it really is. At Cloudfoot, Cartographer Pei redraws the world with nothing square in it but the frame, and sends one copy to the Library and another to Longmen, where Harbourmistress Jiang pins it to the flood stele with a note: told you so, from both of us."],
		["Archivist Lan", "The Unbroken Land. That is what I am calling it. Do not argue."],
		["Narrator", "And on Azure Cloud Mountain, in the cool of the evening, Lin Feng walks the new north road down to the river and back again. It bends, and he follows it."],
	],
	# ---- Part XI: The Ladder of Heaven
	"recall9": [
		["Narrator", "The land keeps its own shape, and for a season everybody lets it. Pei's new map goes up in the Library, Harbourmistress Jiang writes rude letters to it, and Lin Feng sweeps the steps in the mornings and walks the new north road in the evenings."],
		["Narrator", "Then, one morning before dawn, the whole mountain shudders. When the sun comes up there is a tree west of the sect that was not there the night before: a trunk wider than the Hall, bark like old bronze, not one branch below the clouds, and roots that have split the hillside open."],
		["Old Shen the Bell-Ringer", "I rang the bell at it. No echo. I shouted at it. No echo. And at noon it casts no shadow. Elder, I have rung bells for forty years, and I do not like a tree that will not echo."],
		["Elder Qing Xuan", "Nor should you, Shen. Lin Feng, come to the hall. I know that tree. Everybody did, once, and then we were made to forget it."],
	],
	"s_p11_home": [
		["Elder Qing Xuan", "That is the Jianmu, the Standing Tree. Before Yu, in the days of the Yellow Emperor, it stood at the middle of the world, and it was a ladder. Gods climbed down it to visit, and people climbed up it to complain."],
		["Elder Qing Xuan", "Then came Zhuanxu, the Yellow Emperor's grandson, who thought heaven and earth had grown too familiar. He sent his grandsons: Chong to lift heaven up and Li to press the earth down, and between them they cut the ladder through. The old books call it the severing of heaven and earth."],
		["Lin Feng", "And the Court made a law of it."],
		["Elder Qing Xuan", "The Court made a whole government of it. One ladder, kept by the Court. One road up it: obedience. The peoples of the heavens were cut off above, the Feathered Folk, the dragon-kin, the celestial foxes; and the peoples under the roots below, the Pearl-Weepers, the Deathless, the shades of Youdu."],
		["Yue Ling", "And now the land has its own shape again, so the tree remembered how to grow."],
		["Elder Qing Xuan", "Just so. Chong is still holding heaven up and Li is still pressing the earth down, four thousand years on, and the old books say they are very tired. Whatever comes down that tree, or up through its roots, will ask you one thing first: what is your Dao?"],
		["Elder Qing Xuan", "The Court allowed one road. There are many: the sword, free wandering, the heart, formations, the cauldron, the mirror. Every people walks one, and none of them is wrong. Choose the road you will walk for now. You may change roads at any Dao Stele. That is the whole point of roads."],
	],
	"s_p11_archive": [
		["Archivist Lan", "Down here, Lin Feng. Mind the third step. This is the Sealed Archive: everything the Court ordered the sect to forget, which we kept, because an archivist who burns books is just a cook with bad taste."],
		["Archivist Lan", "Here: the record of the severing. Chong took heaven, Li took the earth, the ladder was cut at the middle, and the peoples above and below were told the people of the middle were cruel. The people of the middle were told the same of them. Nobody could climb up or down to check."],
		["Lin Feng", "I have been up into the sky before, though. The Court's stair, the Sea of Clouds, the sun's own road."],
		["Archivist Lan", "The Court kept one stair, up to its own door and no further, and only its clerks and its harvest went up it. The Level Heaven is above the Court's heaven, and its gate is not the one you opened on the north coast."],
		["Lin Feng", "Then the first people down the tree will be expecting monsters."],
		["Archivist Lan", "And they will meet you, which will be a great surprise to them. Something came down the trunk at dawn. Old Shen says it had wings and was very rude. Go and be polite at it. The tree stands on the open ground west of the sect."],
	],
	"s_p11_tree": [
		["Ling Yu of the Feathered Folk", "Stay back, ground-walker. ...Oh. You are the one. You smell of tribulation smoke and broom straw. The wind told us somebody down here let the land go, and the next thing we knew there was a ladder."],
		["Ling Yu of the Feathered Folk", "I am Ling Yu of the Yumin, the Feathered Folk. We hatch from eggs, we can fly, though not far, and we nest round the crown of this tree in the Level Heaven. I came down to see if the middle world was as horrible as the stories. You are much shorter than the stories."],
		["Lin Feng", "What is it like up there, now the Court is gone?"],
		["Ling Yu of the Feathered Folk", "Loud. The winds do what they like, the dragon-kin will not rain without a ledger, the Thunder Duke strikes at everything that moves, and our eggs will not hatch in the noise. The Feather-Mother sent me down to find help. I suppose you will do."],
		["Ling Yu of the Feathered Folk", "There is a stair round the trunk, for those without wings. Climb. I will race you to the top, and I will win."],
	],
	"s_jt_intro": [
		["Feather-Mother Yu Hua", "Ling Yu says you climbed the whole Jianmu without wings and only stopped to be sick twice. Welcome to Featherfall, ground-walker, and to Juntian, the Level Heaven: the middle field of the Nine Heavens."],
		["Feather-Mother Yu Hua", "Every Yumin hatches in the warm cellar under the Egg-Nursery, and the first thing a chick hears is the wind bells on the aeries telling it the wind is safe. Since the Court fell the winds have run wild and torn the bells from every tower, and the chicks have stopped hatching."],
		["Lin Feng", "Then I will bring the bells back."],
		["Feather-Mother Yu Hua", "Four of them have fallen among the islands, the big bronze ones from the top of this tower. Bring them home, and clear the loose thunder and the cloud-kites from the islands, so the chicks can hear something besides storms."],
	],
	"s_jt_return": [
		["Feather-Mother Yu Hua", "Four bells. Listen to them... they still ring true. Hang them, Ling Yu. ...And listen to that. The first egg is cracking, down in the cellar."],
		["Feather-Mother Yu Hua", "But hear what the bells say when the wind blows from the east: rain that will not fall, wind that will not settle, thunder that will not stop. The storm is not wild, ground-walker. It is unmanaged. The Rain Ministry has stopped working."],
		["Yue Ling", "Then we ask the Ministry why."],
		["Feather-Mother Yu Hua", "The Rain-Minister sits in the archive under the Ministry hall and will not come up. Dragons sulk magnificently. Go down and ask him. He will not listen to birds."],
	],
	"s_jt_minister": [
		["Rain-Minister Ao Run", "A mortal, in the Archive of Rain. Shut the door. Every cloud in heaven is entered in these ledgers: where it will rain, how much and on whom. For ten thousand years the Court signed every page. Now nobody signs them."],
		["Rain-Minister Ao Run", "So I do not rain. Rain without a signature is not rain, it is only water falling about. And with no rain to carry, Feilian lets the winds out of his bag for fun, and the thunder has nothing to follow, so Kui and the Duke strike whatever they please."],
		["Lin Feng", "Then sign it yourself."],
		["Rain-Minister Ao Run", "...Myself. A dragon, signing his own rain, with no ledger to answer to. ...Ao Qing, fetch me a brush. No, a big one."],
		["Rain-Minister Ao Run", "But catch the winds first, or the rain will only blow sideways. Feilian keeps his bag of winds on the southern islands, Kui stamps in the east, Jiufeng's nine heads cannot agree which way the wind is blowing, and Leigong, Duke of Thunder, sits at the eastern edge of Juntian striking at everything."],
	],
	"pre:feilian": [
		["Narrator", "On the southern islands a creature with a deer's body, a bird's head and a snake's tail lounges on a bulging leather bag, letting out little gusts that knock the cloud-kites over."],
		["Feilian, Earl of the Wind", "The Court used to tell me when to blow and how hard. Now nobody tells me anything. Do you know how much fun it is to blow whenever you like?"],
		["Yue Ling", "The Feathered Folk's eggs will not hatch."],
		["Feilian, Earl of the Wind", "Eggs! Who thinks about eggs? Take the bag from me, then, if you can."],
	],
	"post:feilian": [["Narrator", "Lin Feng ties the neck of the bag of winds shut. Feilian sulks, then grins: the Rain-Minister will need winds to carry his rain, he says, and he can blow on purpose, if somebody asks nicely. Ling Yu asks, very nicely, and the wind over Featherfall drops to a breeze."]],
	"pre:kui": [
		["Narrator", "In the east of Juntian a grey ox with one leg and no horns hops from island to island. Wherever it lands there is lightning, and when it bellows it sounds like thunder rolling round the sky."],
		["Lin Feng", "Kui. The Yellow Emperor made a drum from your hide once."],
		["Kui, the One-Legged Thunder Ox", "And they beat it, and it was heard for five hundred li, and the whole world trembled. Every time I hear thunder I think somebody is beating me again. So I bellow first."],
	],
	"post:kui": [["Narrator", "Kui stops hopping, stands very still on its one leg, and listens. There is no drum. There has not been a drum for four thousand years. It lies down in the clouds with a long sigh like distant thunder, and the eastern islands go quiet."]],
	"pre:jiufeng": [
		["Narrator", "On the northern crags sits a vast bird with nine human heads, on a nest of cloud. Every head is arguing with every other head about which way the wind is blowing."],
		["Jiufeng, the Nine-Headed Phoenix", "North! South! It is not blowing! It is blowing in a circle! Who are you? Nobody asked you! Everybody, attack him! No, everybody attack HER!"],
		["Yue Ling", "Nine heads, and not one of them listening."],
	],
	"post:jiufeng": [["Narrator", "Out of breath, the nine heads fall silent one by one, until only the smallest says, quite calmly, that the wind is blowing from the west now, and it smells of rain. The other eight look at it, and for the first time in a long while, they agree."]],
	"pre:leigong": [
		["Narrator", "At the eastern edge of the Level Heaven, on a ring of drums, sits a blue-skinned god with a bird's face and wings, a chisel in one hand and a mallet in the other. Every few heartbeats he strikes a drum, and lightning splits a cloud somewhere far below."],
		["Leigong, Duke of Thunder", "The Court gave me a list: the wicked, the oath-breakers, the ones who wasted rice. I struck whoever was on the list. Then the list stopped coming. So now I strike everybody, to be fair."],
		["Lin Feng", "That is not fair. That is just loud."],
		["Leigong, Duke of Thunder", "Then you write me a list."],
	],
	"post:leigong": [
		["Leigong, Duke of Thunder", "...No list. Nobody to strike. What is a thunder god for, with nobody to strike?"],
		["Rain-Minister Ao Run", "For rain, Duke. Rain needs thunder ahead of it, to tell the farmers to bring in the washing. I have signed my first page. Will you come and drum for it?"],
		["Narrator", "Leigong lowers his mallet. Then he strikes one drum, gently, and far below over the Unbroken Land the first rain of the new heaven begins to fall, signed by nobody but the dragon who decided it. In Featherfall, between the thunder and the bells, a whole cellar of eggs begins to hatch."],
	],
	"s_cg_intro": [
		["Hu Qingyi, the Ninth-Tail Matron", "Oh, look, a hero. On our terrace. With his sword out. Put it away, darling; nobody up here will fight you before tea. Probably."],
		["Hu Qingyi, the Ninth-Tail Matron", "We are the Tianhu, the celestial foxes. Each of us spent a thousand years growing nine tails to climb up here, and when we arrived we found the Gate of Heaven with nobody left to keep it. A gate with no gatekeeper is a joke waiting for a punchline. So we keep it."],
		["Lin Feng", "I need to go through it."],
		["Hu Qingyi, the Ninth-Tail Matron", "Of course you do. Behind the Gate stands Chong, holding heaven away from the earth, as he has since the ladder was cut. Nuwa's pillars bear its weight, darling; Chong only keeps it out of reach, and the strain has pressed his ears shut. He hears nobody. And we hid the four keys of the Gate, as a joke. You will have to find them. That is the punchline."],
		["Yue Ling", "Hilarious."],
	],
	"s_cg_return": [
		["Hu Qingyi, the Ninth-Tail Matron", "All four keys! You found the one we put in the lion's mouth? We never thought anybody would look there. Very well: the Gate is yours."],
		["Hu Qingyi, the Ninth-Tail Matron", "But listen, little hero, because this part is not a joke. When Chong lifted heaven he swore to hold it until somebody told him it was safe to stop. Nobody ever has. If you go to him, you had better be ready to tell him."],
		["Lin Feng", "Is it safe?"],
		["Hu Qingyi, the Ninth-Tail Matron", "That is what you are going to find out. The door gods still stand before the Gate, and Pixiu has been eating its gold. Mind your purse."],
	],
	"pre:pixiu": [
		["Narrator", "On the gold-roofed island a winged lion with one horn is gnawing the gilded tiles off the gatehouse roof, swallowing them, and looking for more."],
		["Pixiu, Who Ate the Gold of the Gate", "Gold goes in and nothing ever comes out. That is my whole nature. The Court fed me tribute; now I feed myself."],
		["Yue Ling", "Then you are about to have a very bad day."],
	],
	"post:pixiu": [["Narrator", "Pixiu lies down on the bare roof beams looking sorry for itself. It cannot give the gold back, it explains; it never could. But it will guard what is left, if somebody scratches it behind the horn now and then. Old Hu the Gate-Fox says he will see to it."]],
	"pre:shentu": [
		["Narrator", "Under a peach tree before the Gate of Heaven stands a red-faced giant in armour, a rope of reeds coiled at his belt and a tiger crouched at his feet."],
		["Shentu, Door God of the Peach Tree", "I am Shentu. With my brother Yulei I stand under the peach tree and bind every evil spirit that tries to pass, and feed it to the tiger. Are you an evil spirit?"],
		["Lin Feng", "I am a sweeper."],
		["Shentu, Door God of the Peach Tree", "That is exactly what an evil spirit would say."],
	],
	"post:shentu": [["Narrator", "Shentu looks at Lin Feng for a long moment, then at the tiger, which has gone to sleep. Not evil, he says. Only stubborn. He steps aside, and goes to tell his brother."]],
	"pre:yulei": [
		["Narrator", "On the far side of the peach tree stands Shentu's brother, green-faced, holding the other end of the rope of reeds."],
		["Yulei, Door God of the Reed Rope", "My brother is too soft. Every door needs two keepers, one to open it and one to shut it. I am the one who shuts."],
		["Yue Ling", "Doors are meant to open sometimes."],
	],
	"post:yulei": [["Narrator", "Yulei coils his rope and hangs it on the peach tree. A door that opens is still a door, he admits. He pushes, and for the first time in four thousand years the Gate of Heaven swings open, and beyond it, in a pillar of cloud, somebody is holding up the sky."]],
	"pre:chong": [
		["Narrator", "Beyond the Gate stands a giant whose head is lost in the sky. His arms are raised, his palms flat against heaven itself, and his whole body shakes with the weight of it."],
		["Chong, Who Lifts Heaven", "WHO? I cannot hear you. I have not heard anything for four thousand years. My grandfather told me: lift heaven, and hold it, until it is safe to let go. Is it safe? I CANNOT HEAR YOU."],
		["Lin Feng", "Then I will have to show you."],
	],
	"post:chong": [
		["Chong, Who Lifts Heaven", "...I can hear. The wind. A bird. You. Why can I hear?"],
		["Lin Feng", "Because you put your hands down to fight me. And heaven did not fall."],
		["Chong, Who Lifts Heaven", "...It did not fall. The tree. The Jianmu is holding it. My grandfather cut the ladder so heaven would not lean on the earth. But a ladder does not lean. A ladder holds hands."],
		["Narrator", "Chong gives Lin Feng the jade tablet he held heaven up with, still warm after four thousand years. My brother Li presses the earth down at the bottom of the world, he says, and he will not be able to hear either. Go down the roots. Tell him what you told me."],
	],
	"s_ns_intro": [
		["Narrator", "Down the roots of the Jianmu, through the dark, past glowing moss and the sound of water, the roots open into a cavern country under the land. On the shore of a black lake stands a town of shell and silk: Tearwater."],
		["Pearl-Weaver Shui Lian", "A living man from above, in Tearwater. You climbed down the roots? Then you came the way the stories said the monsters would come. You do not look like a monster. You look tired."],
		["Pearl-Weaver Shui Lian", "I am Shui Lian of the Jiaoren, the Pearl-Weepers. When we weep, our tears are pearls; we weave a silk the water cannot wet; and we live here by the black water, where the roots of the world tree drink from the Nine Springs."],
		["Pearl-Weaver Shui Lian", "The springs are going wrong. The tree drinks and drinks, it has grown back so fast, and the springs run thin and bitter, and our children's tears come out as grit. Fill me four vials at the springs among the roots, and I will tell you what the water says."],
	],
	"s_ns_return": [
		["Pearl-Weaver Shui Lian", "Four springs. Taste: bitter, and cold, and something under it like iron. The roots are not only drinking. Something is gnawing them. And the water is being pushed down, as if a great hand were pressing on the whole cavern from below."],
		["Lin Feng", "Li."],
		["Pearl-Weaver Shui Lian", "The one who presses the earth down, at the bottom of everything, under Youdu. The Deathless will know more; they have tended the roots since the ladder was cut. Elder Bu Si lives in the loft of the house under the great root. Go up the stairs, and speak slowly. He has all the time in the world."],
	],
	"s_ns_elder": [
		["Elder Bu Si of the Deathless", "Sit. Sit. I have been waiting for you for four thousand years. Not you, exactly. Somebody. You will do."],
		["Elder Bu Si of the Deathless", "We are the Deathless. We eat the fruit of the immortal tree that grows on the roots of the Jianmu, we drink from the red spring, and we do not die. It sounds pleasant. It is mostly a great deal of waiting."],
		["Elder Bu Si of the Deathless", "When the ladder was cut, Li went down under Youdu to press the earth flat, and he has pressed ever since. Now the tree pushes up and Li pushes down, and the roots are caught between them like a hand in a door, and the creatures of the deep are gnawing at whatever is caught."],
		["Lin Feng", "Then I will go and ask Li to stop."],
		["Elder Bu Si of the Deathless", "Good. But first: a wyrm is gnawing the great root, a goblin is muddying the springs, the Pearl-Mother weeps so hard she is drowning the shore, and the Torch Dragon has shut his eyes, and without them there is no day down here at all. Li has waited four thousand years. He can wait an afternoon."],
	],
	"pre:root_wyrm": [
		["Narrator", "In the dark between the roots a long pale wyrm is coiled round the greatest root of the Jianmu, gnawing at it, and with every bite the whole cavern shivers."],
		["The Wyrm Who Gnaws the Jianmu", "The tree is in my sky. For four thousand years there was no tree, only dark, and the dark was mine. Now there is a root through the middle of it."],
		["Yue Ling", "Then the dark will have to share."],
	],
	"post:root_wyrm": [["Narrator", "The wyrm uncoils and slides away into a crack between two roots. It is cold, it complains, and the root is warm. Chang Sheng the grove-keeper says it may sleep against the root if it stops biting it, and after a while, it does."]],
	"pre:pearl_mother": [
		["Narrator", "Over the black lake drifts a great pale shape like a jellyfish the size of a house, weeping. Every tear is a pearl as big as a fist, and they are piling up so fast they are pushing the water over the shore."],
		["The Weeping Pearl-Mother", "The children's tears come out as grit. So I weep for them. I weep for all of them. Somebody has to."],
		["Lin Feng", "If you drown Tearwater, there will be no children left to weep for."],
	],
	"post:pearl_mother": [["Narrator", "The Pearl-Mother stops weeping long enough to hear Little Bei singing on the shore, and the song is not sad. She drifts back out over the black water, and the pearls she wept settle on the lake bed and glow there, so that Tearwater has a little light of its own."]],
	"pre:wangxiang": [
		["Narrator", "Among the springs a goblin with red eyes, long ears and black claws is splashing mud into every pool, giggling."],
		["Wangxiang, Goblin of the Springs", "Clear water is boring! You can see the bottom! Mud is a mystery! Everybody likes a mystery!"],
		["Yue Ling", "The Pearl-Weepers have to drink it."],
	],
	"post:wangxiang": [["Narrator", "Wangxiang agrees, grudgingly, to keep his mud to one pool, his own, where anybody who likes a mystery can come and look. Hai Ge the Tide-Singer writes a song about it at once, which Wangxiang pretends not to like."]],
	"pre:zhulong": [
		["Narrator", "At the eastern end of the cavern lies a red dragon a thousand li long, with a man's face and his eyes shut. When Zhulong opens his eyes it is day in the deep; when he shuts them it is night. They have been shut for a month."],
		["Zhulong, the Torch Dragon", "Why should I open them? The tree came through the roof of my world without asking. Everything I lit for four thousand years is lit by somebody else's tree now."],
		["Lin Feng", "The Pearl-Weepers have been weeping in the dark."],
		["Zhulong, the Torch Dragon", "Then let them weep. Come closer, and I will open one eye, just for you."],
	],
	"post:zhulong": [["Narrator", "Zhulong opens both eyes, and red daylight floods the Nine Springs, and all along the black water the Pearl-Weepers come out of their houses and look up. The tree did not take your light, Lin Feng tells him; it brought you visitors. The Torch Dragon looks at the crowd on the shore and, for the first time in four thousand years, has the grace to look embarrassed."]],
	"s_yd_intro": [
		["Narrator", "Past the Torch Dragon the cavern drops into a great hollow, and in it lies a city of grey walls and paper lanterns that have never once gone out: Youdu, the Dark Capital, where the shades live who are not yet ready to be reborn."],
		["Lantern-Magistrate Ming Yi", "A living man in the Dark Capital, climbing my stairs. You are not on any roll. Sit down; you are making the lanterns nervous."],
		["Lantern-Magistrate Ming Yi", "I am Ming Yi, magistrate of the Ward Office. Every shade in Youdu is on a roll, on a bamboo tally: who they were, when they came, when they will be ready to go up to the Wheel again. Order, Lin Feng. The dead like order. It is the one thing they can still have."],
		["Lantern-Magistrate Ming Yi", "Since the tree came down through our roof the earth has been heaving and the rolls have scattered. Four tallies are lost in the streets, and four shades do not know who they are. Find them, clear the runaway spirits out of my streets, and then we will talk about why you are here."],
	],
	"s_yd_return": [
		["Lantern-Magistrate Ming Yi", "Four tallies: a ferryman, a weaver, a soldier, and a girl called Lan who has been asking everybody in the street who she is. Thank you. Order is restored, in this room at least."],
		["Lantern-Magistrate Ming Yi", "Now, the heaving. It comes from under the city, from the deep beyond the inner gate, where Li presses the earth down. For four thousand years he pressed steadily. Since the tree came he presses harder, because the tree pushes back. A little harder still and he will crack the floor of the world."],
		["Yue Ling", "Then we go through the inner gate."],
		["Lantern-Magistrate Ming Yi", "Not before you go down to the deep hall under the Palace of Sovereign Earth. Houtu keeps the dead, and she will want to see you. Everybody in this city does what Houtu wants. She wants very little, which is why we all do it."],
	],
	"s_yd_houtu": [
		["Houtu, Sovereign Earth", "Come here, child. Let me look at you. You are the one who closed the Ledger, and then turned the Wheel and let the dead go home. I remember every soul you sent me. They all said the same thing: tell him thank you."],
		["Houtu, Sovereign Earth", "I am Houtu. I am the earth everybody walks on and everybody is buried in. Li presses on me. He has pressed for four thousand years, because his grandfather told him the earth must be kept down, away from heaven. I have never once complained. I should have."],
		["Lin Feng", "Why didn't you?"],
		["Houtu, Sovereign Earth", "Because a mother does not complain about her children. Li is a child of the earth, as you are. Go to him. And take the earth's own blessing on your sword, so that whatever you strike, you strike with the weight of everything that was ever buried kindly."],
		["Narrator", "A new technique settles into Lin Feng's hands, as heavy and as gentle as the earth: the Three Realms Concord Sword."],
		["Houtu, Sovereign Earth", "White and Black Impermanence have been collecting the living by mistake since the rolls scattered, and Tubo guards the inner gate with three eyes and bad manners. Be kind to all of them. They are only doing their jobs, badly."],
	],
	"pre:bai_wuchang": [
		["Narrator", "Through the lantern-lit streets comes a tall pale figure in white, with a long tongue and a tall white hat that reads: one glance and you will be rich. On the end of his chain is a very confused, very alive fishmonger."],
		["Bai Wuchang, White Impermanence", "On the roll, off the roll, the rolls have scattered, so I collect whoever I meet. It is easier. Hold still."],
		["Lin Feng", "That man is alive."],
		["Bai Wuchang, White Impermanence", "Details."],
	],
	"post:bai_wuchang": [["Narrator", "White Impermanence unlocks the fishmonger, who runs all the way back up the roots without stopping. Bai Wuchang tucks his chain away: he will check the rolls before he collects anybody else, now Magistrate Ming has them in order. His hat still promises riches. Nobody has ever taken it up on the offer."]],
	"pre:hei_wuchang": [
		["Narrator", "In the alley behind the inn waits White Impermanence's partner, short and black-robed, with a hat that reads: peace under heaven. His chain is wrapped round three living crab-fishers from Tearwater."],
		["Hei Wuchang, Black Impermanence", "My partner collects the ones who are owed. I collect the ones who are left over. Everyone is left over these days."],
		["Yue Ling", "Not these three."],
	],
	"post:hei_wuchang": [["Narrator", "Black Impermanence lets the crab-fishers go and sits down on the inn step with a sigh. Peace under heaven, his hat says. He has worn it so long that he forgot it was a wish."]],
	"pre:tubo": [
		["Narrator", "At the inner gate of Youdu crouches a monster with a tiger's head, three eyes, horns like knives and the body of a bull, coiled nine times round itself, licking its bloody thumbs."],
		["Tubo, Earl of the Dark Capital", "Nobody passes the inner gate. The living stay up there, the dead stay down here, and the gate stays shut. That was the order I was given when the ladder was cut, and nobody has given me another."],
		["Lin Feng", "Houtu sent me."],
		["Tubo, Earl of the Dark Capital", "...Did she. She never sends anybody. Prove it."],
	],
	"post:tubo": [["Narrator", "Tubo uncoils, one coil at a time, all nine of them, and opens the inner gate with a groan of old iron. Beyond it the cavern floor falls away into a deep red glow, and at the bottom of it a figure kneels with both hands pressed flat against the floor of the world."]],
	"pre:li": [
		["Narrator", "At the bottom of the world, in a pit of red-hot stone, kneels a giant of earth and fire with both palms pressed against the ground. The whole of the Nine Springs shudders each time he pushes."],
		["Li, Who Presses Down the Earth", "DOWN. Keep the earth down, away from heaven. My grandfather said it. My brother holds the sky up and I hold the earth down, and between us there is nothing, nothing, nothing at all."],
		["Lin Feng", "Your brother put his hands down. Heaven did not fall."],
		["Li, Who Presses Down the Earth", "LIES. If I lift my hands the earth will rise up and strike the sky. Come down here and make me."],
	],
	"post:li": [
		["Li, Who Presses Down the Earth", "...My hands. I lifted my hands. The earth did not rise."],
		["Lin Feng", "It is held. The tree holds heaven and earth apart and together at once. That is what a ladder does."],
		["Li, Who Presses Down the Earth", "...Four thousand years. And all it needed was a tree."],
		["Narrator", "Li gives Lin Feng the iron weight he pressed the earth down with, lies back on the warm stone of the world's floor and shuts his eyes, and for the first time since the ladder was cut the Nine Springs are still. Take my weight to the middle of the world, he says. Let the tree carry it. And tell my brother I said hello."],
	],
	"s_p11_end": [
		["Elder Qing Xuan", "Chong's tablet and Li's weight. You went to the top of heaven and the bottom of the earth and brought back the two halves of an order four thousand years old. How do they feel?"],
		["Lin Feng", "Lighter than they should. Heavier than they look."],
		["Elder Qing Xuan", "Then come to the tree. All of us."],
		["Narrator", "They are waiting at the foot of the Jianmu: Ling Yu and the Feather-Mother, Rain-Minister Ao Run with a brush behind his ear, Hu Qingyi and three of her foxes, Shui Lian with Little Bei on her shoulders, old Bu Si, Magistrate Ming with his lantern, and Houtu herself, plainly dressed, standing a little apart."],
		["Elder Qing Xuan", "The ladder was cut so that the realms would not mix, and the Court kept it cut so that every road would run through the Court. The tree will carry the tablet and the weight, Lin Feng. But somebody must stand at its middle, once, and hold all three realms in one breath, so that it knows it is allowed."],
		["Yue Ling", "And that somebody is you. Obviously."],
	],
	"pre:s_break16": [
		["Narrator", "Lin Feng sets Chong's tablet in a fork of the Jianmu's bark and Li's weight between its roots. The tribulation that gathers is three storms at once: wind and thunder from the Nine Heavens, cold water and red stone from the Nine Springs, and from the middle world, nothing but the sound of people waiting."],
		["Yue Ling", "Which way does it come from?"],
		["Lin Feng", "Every way. That is the point of a ladder."],
	],
	"post:s_break16": [
		["Narrator", "Lin Feng holds heaven above him, the earth below him and the middle world in his two hands, the way you hold a ladder steady for somebody else to climb, and becomes the first cultivator of Three Realms Concord: a realm in which every road goes somewhere and every realm can be visited."],
		["Narrator", "Up the trunk go the farmers of Qingshi, to see the clouds from above; down the roots go the Feathered Folk, to see the Torch Dragon's day; and foxes and Pearl-Weepers cross the middle world to drink Old Wu's tea at Cloudfoot and complain about it. Chong and Li meet halfway up the Jianmu, and shake hands, and say nothing for a very long time."],
		["Ling Yu of the Feathered Folk", "You climbed it without wings. I still won the race."],
		["Narrator", "And on Azure Cloud Mountain, in the cool of the evening, Lin Feng sweeps the steps of the sect, and then the first hundred steps of the stair round the Standing Tree, because somebody should, and the tree, very slightly, leans down to let him."],
	],
	# ---- Part XII: inside the Founder's sealed caves (Main.open_abode adds the gift and the words on the wall)
	"abode:cave_core": [
		["Narrator", "Inside, a plain room cut in the rock: a cushion, a lamp that lights itself, and on the wall, in a woman's quick sword-strokes, the beginning of a letter."],
		["Echo of Founder Qing Lian", "To whoever carries the root after me. It has nine branches, and it wakes one at a time. I have left a door on this mountain for each realm you reach. Do not hurry. A root that is hurried snaps."],
	],
	"abode:cave_soul": [
		["Narrator", "Under the Founder's words somebody has scratched, small, with a knife: 'The seventh bearer was here. Nascent Soul at nineteen! Next door next year.' There is no other mark, and the next door was never opened."],
		["Yue Ling", "Xu Mo found him first. ...Then we open the next one for him."],
	],
	"abode:cave_deity": [
		["Narrator", "In the dust of this cave, two sets of footprints, one large and one small, and on the wall in charcoal: 'The twelfth bearer and her brother. We will come back for the next door together.' Nobody did."],
		["Echo of Founder Qing Lian", "The body is a house. You may leave it, and come back, and find the furniture moved. That is all this realm is. Do not let anybody tell you it makes you more than you were."],
	],
	"abode:cave_void": [
		["Narrator", "The Founder's writing here is older and shakier than at the other doors: 'Nobody has opened this door. I check it every spring. Xu Mo hunts every bearer down before the fifth realm. If you are reading this, he has failed at last. Good.'"],
	],
	"abode:cave_merging": [
		["Echo of Founder Qing Lian", "I wove a girl from the Seal's lotus so that the bearer would never face the end alone. If she is with you, tell her I am proud of her. If she is not, go and find her."],
		["Yue Ling", "...She knew I would come this far. She left a cushion for me, Lin Feng. Look. Two cushions."],
	],
	"abode:cave_mahayana": [
		["Echo of Founder Qing Lian", "The Court sends an inspector up the mountain every spring to count our disciples. I let him count. He never once asks what is in the caves. A government that only counts what it can tax will never see a root grow."],
	],
	"abode:cave_immortal": [
		["Echo of Founder Qing Lian", "If you have come this far, the Court is failing, or you are. There is a Ledger in the sky with every year it stole written in it, and every name. I could not close it. Perhaps you can. Perhaps, by the time you read this, you have."],
	],
	"abode:cave_ancestor": [
		["Echo of Founder Qing Lian", "I never went past this realm. I do not know what is behind the last door, and I made it anyway, because a road should not stop just because the person who built it did."],
	],
	"abode:cave_sovereign": [
		["Narrator", "The last cave is empty: no cushion, no lamp, no words. Only a brush and an ink-stone, set out ready. Lin Feng thinks for a long time, then takes up the brush and writes the Founder an answer on her own wall."],
	],
	# ---- Part XII: The Returning Ruins
	"recall10": [
		["Narrator", "Every road goes somewhere now. Farmers from Qingshi climb the Jianmu on rest days to look down on the clouds, Ling Yu races anyone who will race her, and Lin Feng sweeps the steps in the mornings and the first hundred steps of the Standing Tree in the evenings."],
		["Narrator", "Then, one morning in early autumn, a fishing boat comes up the south-east road on an ox-cart, with three fishermen from the east coast sitting in it, still holding their nets."],
		["Old Shen the Bell-Ringer", "Elder! There is a boat at the gate. On a cart. The fishermen say the sea went out last night and did not come back. Every boat on the east coast is sitting on the sand."],
		["Elder Qing Xuan", "Then it has gone somewhere, Shen. Water always goes somewhere. Lin Feng, to the hall. And somebody wake the Archivist."],
	],
	"s_p12_home": [
		["Elder Qing Xuan", "East of the Eastern Sea, says the Liezi, who knows how many hundred million li away, there is a ravine without a bottom. It is called Guixu, the Returning Ruins. Every river in the world, every sea and the Silver River of heaven pour into it, and it never fills and never empties."],
		["Elder Qing Xuan", "Over it stood five mountains: Daiyu, Yuanqiao, Fanghu, Yingzhou and Penglai, the Isles of the Immortals, with palaces of gold and trees of pearl whose fruit stops you growing old. They floated, so the Heavenly Emperor set fifteen great turtles to hold them on their heads, in three shifts of sixty thousand years."],
		["Lin Feng", "And the sea going out has something to do with a fairy tale?"],
		["Elder Qing Xuan", "Everything in this sect has had something to do with a fairy tale, disciple, since the day you picked up a broom. Water goes into Guixu and comes back as cloud and rain and rivers. That is why the sea stays the sea. If it goes out and does not come back, the Returning Ruins have stopped returning."],
		["Elder Qing Xuan", "Ask Archivist Lan what the Court did with the Eastern Sea; she has been in the Sealed Archive since dawn. Then go east to Fusang, where the sun comes up out of the sea, and see for yourself."],
	],
	"s_p12_archive": [
		["Archivist Lan", "The Liezi, the Records of the Grand Historian and a Court memorandum marked 'not to be read'. Sit. A giant of the Kingdom of Longbo once walked out to the isles in a few strides, caught six of the turtles on one line and took them home to tell fortunes with their shells. Daiyu and Yuanqiao drifted north and sank into the Ruins."],
		["Archivist Lan", "Then the First Emperor of Qin sent his magician Xu Fu east with three thousand boys and girls to fetch the elixir of immortality. Xu Fu sailed, came back once without it, sailed again with sixty ships, and was never seen again. The historian says he found a plain with broad marshes and made himself king. The memorandum says otherwise."],
		["Lin Feng", "What does it say?"],
		["Archivist Lan", "That the Court hid the isles in a mirage, so nobody could pick years off a tree while the Court was selling them by the column; and put a bronze stopper in Guixu, so the water of the world would come back only where the Rain Ministry signed for it. Somebody has pulled the stopper out. That is where your sea went."],
		["Archivist Lan", "And Lin Feng: the memorandum has a list of everyone the Court left on the isles. It is very long, and it is in the column marked 'forgotten'. Be kind to them. Nobody has visited in two thousand years."],
	],
	"s_p12_shore": [
		["Narrator", "Past the Fusang tree the valley falls away east, and where the sea should be there is wet sand to the horizon, shining, with boats lying on it like dropped shoes. By the pool where the ten suns used to bathe, a young woman in red sits in a small boat that is somehow still afloat."],
		["Mazu, Who Brings the Boats Home", "You are the sweeper. The fishermen pray to me, and lately they pray about you: let him come and fix the sea. I am Lin Moniang. On the coast they call me Mazu, Grandmother, which I find very ageing. I bring the boats home.", "wave"],
		["Mazu, Who Brings the Boats Home", "There are no boats to bring home now. The sea has not gone, only gone east: past the edge of the shelf it runs like a river into the Returning Ruins. The hot spring under this pool runs beneath the hills to that river, and my boat floats wherever there is water. Get in."],
		["Mazu, Who Brings the Boats Home", "And watch the horizon. My two generals ran away when the tide went: Qianliyan, who sees a thousand li, and Shunfeng'er, who hears every wind. Demons I tamed once, with a red lantern and a great deal of patience. Somebody is paying them to watch the sea."],
		["Narrator", "Mazu lifts the red lantern from the stern and puts it in Yue Ling's hands, and its light settles there like a warm stone: Mazu's Red Lantern, which brings the fallen home as surely as it brings boats.", "Mazu, Who Brings the Boats Home:offer"],
		["Yue Ling", "We will bring it back, Grandmother. And your generals.", "bow"],
	],
	"s_pl_intro": [
		["Narrator", "Out of the haze rises an isle of white cliffs and green terraces, a pavilion on the highest cliff and, along the old shore, a town of blue-tiled houses with every boat in it lying on the sand. A woman with a carved staff is waiting at the door of the biggest hall."],
		["Headwoman Xu Qian of Landfall", "A boat. A boat that floats. From outside. Forgive me, honoured guest: nobody has come from outside in two thousand two hundred years, and we have rehearsed what to say for most of them, and I have forgotten all of it.", "shock"],
		["Headwoman Xu Qian of Landfall", "This is Landfall. We are the Thousand Children: the grandchildren's grandchildren of the three thousand boys and girls Xu Fu brought from Qin to fetch the elixir. He went up the hill to ask the immortals for it, and he did not come back down. We stayed. Where would we go? The mirage let nobody in, or out."],
		["Headwoman Xu Qian of Landfall", "Now the mirage has lifted and the sea has gone, both at once. The drain took our boats, and the Slips of the Thousand Names: every child's name, carved on bamboo, kept in this hall since the landing. Four bundles went out with the water. The sharks it stranded are snapping at the children. Please."],
		["Lin Feng", "I will bring the names home.", "nod"],
	],
	"s_pl_return": [
		["Headwoman Xu Qian of Landfall", "Four bundles. Every name... Teacher Qin, count them! ...All here. Look: the oldest slips are all in one hand. The same hand, three thousand names.", "grieve"],
		["Teacher Qin of the Thousand Names", "Xu Fu's hand. He carved every name himself, the first night ashore, so that none of us would be forgotten. And on the last slip, not a name: I will come back with the elixir, and none of you will ever grow old."],
		["Headwoman Xu Qian of Landfall", "None of us grew old waiting, honoured guest. We grew old in the ordinary way. If you want to know where the sea went, ask the immortals. One of them comes down to drink: Lu Dongbin, upstairs in the wine-house. He has drunk there for two thousand years and never once paid in coin."],
	],
	"s_pl_immortal": [
		["Lu Dongbin, the Sword Immortal", "A guest! And sober! Sit, sit. I am Lu Dongbin. I carry a sword to cut through ignorance, mostly my own. The others are up on Fangzhang being dignified; I prefer the wine down here, and the company.", "laugh"],
		["Lu Dongbin, the Sword Immortal", "Xu Fu came up the hill two thousand years ago and asked for the elixir. We told him the truth: the fruit of the pearl trees does not make you live for ever. It makes you stop. A ripe fruit, eaten when you are ready, lets you stop when you choose. An unripe one just stops you."],
		["Lu Dongbin, the Sword Immortal", "He did not believe us. He stole a green one and bit it, and he has not changed since: not a hair, not a thought. He cannot sleep, he cannot forget the Emperor's orders and he cannot change his mind. The only ripe fruit left grows on Daiyu, which sank into the Returning Ruins."],
		["Lin Feng", "So he pulled out the stopper, to drain the sea down to Daiyu."],
		["Lu Dongbin, the Sword Immortal", "Clever sweeper. Stop him before the sea is gone. Mazu's runaway generals are his lookouts, the Sea-Monk is drowning fishermen on the sandbar for fun, and the Giant of Longbo is wading on the shelf, fishing for turtles. If he catches three more, Penglai sinks. Have a drink first. No? Suit yourself."],
	],
	"pre:qianliyan": [
		["Narrator", "On a crag above the shoals stands a green-faced demon with eyes like lanterns, shading them with one hand and staring east."],
		["Qianliyan, Thousand-Li Eye", "I see you. I saw you leave Fusang. I saw you eat your breakfast. A man with a green fruit pays me in pearls to watch the sea, and I watch it. There is not much sea left to watch."],
		["Yue Ling", "Mazu misses you."],
		["Qianliyan, Thousand-Li Eye", "...Does she? No. Lies. I would have seen it."],
	],
	"post:qianliyan": [["Narrator", "Qianliyan sits down hard on his crag and rubs his eyes, which have not shut for a month. Far away on the mainland, he says quietly, a woman in red is standing on a cliff with a lantern, every night, waiting for boats. He had not looked that way. He looks now."]],
	"pre:shunfenger": [
		["Narrator", "Among the dunes of the bare sea floor a red-faced demon with ears like sails crouches with one hand cupped to the wind."],
		["Shunfeng'er, Wind-Following Ear", "Shh. I hear everything: the sand settling, the turtles groaning, the giant's line in the water, your heart, a bit fast. The man with the green fruit pays me to listen. He says the sea will be gone in a month, and then I can hear the trees on Daiyu."],
		["Lin Feng", "Then listen to this."],
	],
	"post:shunfenger": [["Narrator", "Shunfeng'er sits back in the sand with his ears ringing, and under the ringing he hears something he has ignored for a month: Mazu, on the mainland, calling the names of her boats one by one, every night. He gets up and starts walking west."]],
	"pre:sea_monk": [
		["Narrator", "On the fishermen's sandbar crouches a thing like a great turtle with a shaved man's head, chuckling, holding a fisherman down in the last puddle of the shoal."],
		["The Sea-Monk Who Drowns Fishermen", "Heh. When the sea was deep I had to swim after them. Now they walk right up to me, looking for their boats."],
		["Yue Ling", "Let him go."],
	],
	"post:sea_monk": [["Narrator", "The Sea-Monk lets the fisherman go and slides off into the channel, muttering that it was better sport when there was sea. Old Pilot Zheng says Landfall will remember, and the Sea-Monk will find the shoals rather crowded with nets when the water comes back."]],
	"pre:longbo_giant": [
		["Narrator", "Out on the bare shelf east of Penglai, where the sea was a thousand feet deep, stands a giant up to his ankles in the last of the water, casting a line as thick as a cable. Something vast under the isle groans."],
		["The Giant of Longbo, Who Fishes for Turtles", "Six turtles, my great-great-grandfather caught, in one cast! The Emperor shrank our whole kingdom for it. Now the Court is gone, the shrinking is wearing off, and the sea is down to my ankles. Three more and I beat his record."],
		["Lin Feng", "Three more and Penglai sinks, with the Thousand Children on it."],
		["The Giant of Longbo, Who Fishes for Turtles", "Then they should learn to swim. Out of my light, little fisherman."],
	],
	"post:longbo_giant": [
		["Narrator", "The giant sits down in the shallows with a splash that runs all the way to Landfall, and looks at his great hook, bent straight. Lin Feng takes it from him."],
		["The Giant of Longbo, Who Fishes for Turtles", "...My great-great-grandfather told it as a fishing story. He never said there were people on the islands. He never said they sank."],
		["Narrator", "The giant wades away west, a little smaller with every stride. Beyond the shelf a sandbar the drain has left bare runs east into the haze, towards a square-topped isle, and the way to Fangzhang is open."],
	],
	"s_fz_intro": [
		["He Xiangu of the Lotus", "Lu Dongbin sent you up? He never sends anybody; he forgets. I am He Xiangu. I carry a lotus and keep the gardens of Fangzhang, the Square-Pot Isle: the elixir herbs, the furnaces and the pearl trees."],
		["He Xiangu of the Lotus", "The pearl trees drink from the Returning Ruins through roots a thousand li long. Since the sea started going out they have been drinking nothing, and their leaves fall like coins. Bring me the dew from four of them before it dries, and I will show you what the elixir really is."],
		["Yue Ling", "And the toads in the herb beds?"],
		["He Xiangu of the Lotus", "The furnaces went cold and the cinnabar toads came out of them; the cranes are stealing what pills are left and the rabbits are eating the herbs. Chase them out, if you would. Gently. They are only hungry, like everybody on this isle."],
	],
	"s_fz_return": [
		["Narrator", "He Xiangu lets one drop of the dew fall on a withered lotus. The lotus opens, and then stays exactly as it is: not a petal moves, not in the wind, not when Yue Ling touches it.", "He Xiangu of the Lotus:offer"],
		["He Xiangu of the Lotus", "That is the elixir: water from the Returning Ruins, where every water in the world has been and come back. It does not give you years. It takes away the need for them. Xu Fu wanted it for an emperor who wanted never to end. We said no, not to keep it from Xu Fu, but to keep it from the emperor."],
		["Lin Feng", "And the Court hid you anyway."],
		["He Xiangu of the Lotus", "The Court hid everybody it could not tax. Go down to the cellar of cold furnaces and ask Zhang Guolao. He is the oldest of us, and he was there when the Court came. He sits on his donkey backwards, so mind his back. His front. Whichever."],
	],
	"s_fz_zhang": [
		["Zhang Guolao, Who Rides Backwards", "Sit. I ride backwards so I can see where I have been; you would be amazed how few people look. I was there when the Court came, with ledgers, to put a stopper in Guixu.", "wave"],
		["Zhang Guolao, Who Rides Backwards", "It used to be simple. Every water ran east into the Ruins and came back up, as cloud over the sea, as springs, as the Silver River. Nobody signed for it. The Court wanted it signed for. So it set Tianwu, the god of the waters, to keep a bronze stopper in the Ruins, and water came back only where the Rain Ministry wrote it down."],
		["Lin Feng", "And when the Court fell?"],
		["Zhang Guolao, Who Rides Backwards", "Tianwu kept the stopper anyway, because nobody told him to stop. Then Xu Fu told him the Court had ordered it pulled. Tianwu has eight heads, and not one of them is good at checking orders. So the stopper is out, the water goes in, and nothing comes back but wind. The water has forgotten how to come back by itself."],
		["Zhang Guolao, Who Rides Backwards", "Tianwu is at the east end of the isle, eight heads arguing about whose fault it is. The White Deer has eaten our last ripe herbs, the furnace that walked off is still burning, and the pearl tree at the bottom of the garden has stopped fruiting out of spite. One thing at a time, sweeper. That is the whole secret of immortality."],
	],
	"pre:longevity_deer": [
		["Narrator", "In the high meadow a white deer with antlers like coral is eating the last ripe herbs of the immortals' garden, leaf, root and flower, and growing a little younger with every mouthful."],
		["The White Deer of Longevity", "The garden is dying. Somebody should eat it while it is still good."],
		["Yue Ling", "Somebody should save it."],
	],
	"post:longevity_deer": [["Narrator", "The White Deer stops eating and looks at the bare meadow, and for the first time in a thousand years looks its age. It lies down among the stalks and stays there, keeping the seeds warm, until somebody plants them."]],
	"pre:elixir_furnace": [
		["Narrator", "A bronze furnace taller than a house is stamping across the terraces on three legs, its belly roaring, spilling half-made pills that burn holes in the grass."],
		["The Elixir Furnace That Walked Away", "FED. NOT FED. FED. NOT FED. The fire said: make the elixir. There is no water from the Ruins. So I make everything else. For ever."],
		["Lin Feng", "Then let the fire rest."],
	],
	"post:elixir_furnace": [["Narrator", "Lin Feng banks the furnace's fire the way Alchemist Mo taught him in his first week, ash over the embers, and the furnace kneels on its three legs and goes quiet. Furnace-Boy Dan climbs inside to sleep, which, he says, is what furnaces are for."]],
	"pre:pearl_tree": [
		["Narrator", "At the bottom of the garden stands a tree of white pearl with leaves of jade, rattling like a box of beads, its bare branches lashing at anything that comes near."],
		["The Pearl Tree That Will Not Fruit", "Everything that eats my fruit stops. Stops growing. Stops changing. Stops. Why should I fruit, so that things can stop?"],
		["Yue Ling", "Because some things are tired."],
	],
	"post:pearl_tree": [["Narrator", "The pearl tree goes still, and one green bud opens among its leaves: not a fruit, a flower. He Xiangu says no pearl tree has flowered in two thousand years. Flowers do not stop anything. They only open."]],
	"pre:tianwu": [
		["Narrator", "At the east end of Fangzhang, on a cliff over the drained sea, crouches a tiger the size of a temple with eight human heads, eight legs and eight tails, and every head is shouting at the others."],
		["Tianwu, the Eight-Headed God of the Waters", "The stopper was pulled by order! No, it was stolen! The Court ordered it! The Court is gone! Then who ordered it? HE did! Who is he? The man with the green fruit! Is he the Court? He SAID he was the Court!"],
		["Lin Feng", "Nobody is the Court now."],
		["Tianwu, the Eight-Headed God of the Waters", "...Then who do we obey? ATTACK HIM! Wait. Why?"],
	],
	"post:tianwu": [
		["Tianwu, the Eight-Headed God of the Waters", "...If nobody is the Court, who decides where the water goes?"],
		["Lin Feng", "The water. It always did, until somebody put a stopper in it."],
		["Narrator", "The eight heads look at one another and, for once, say nothing at all. Tianwu lies down across the cliff and points all eight noses east: beyond Yingzhou, at the lip of the Ruins, Xu Fu rolled the stopper away down the sea floor. A sandbar runs north-east into the mist, and the way to Yingzhou is open."],
	],
	"s_yz_intro": [
		["Narrator", "Yingzhou comes out of the mist in pieces: a cliff, a pine, a shrine roof, a long grey shape breathing under the shore. On a rock at the water's old edge sits a girl with red feet, a white beak of a mouth and a pebble in her hand."],
		["Jingwei, the Flame Emperor's Daughter", "Jingwei. Jingwei. That is what I say, so that is what they call me. I was the Flame Emperor's daughter. I went out on the Eastern Sea in a little boat, and the sea drowned me, and I came back as a bird."],
		["Jingwei, the Flame Emperor's Daughter", "For four thousand years I have carried stones and twigs from the western hills and dropped them in the sea, to fill it up, so that it can never drown anybody else. And now look. It is going. It is nearly gone."],
		["Lin Feng", "You don't sound happy."],
		["Jingwei, the Flame Emperor's Daughter", "...If the sea goes by itself, what was I doing? I lost four stones in the mist this morning and I could not even remember why I wanted them. Find them for me. And chase the phantoms out of the mist; they frighten the turtles."],
	],
	"s_yz_return": [
		["Jingwei, the Flame Emperor's Daughter", "My stones. Thank you. Now look over the edge, while the water is low. No, there. Under the isle."],
		["Narrator", "Below the cliff, where the sea has drained away, Yingzhou stands not only on the back of a turtle but on a reef of pebbles and twigs, grey and white and red, packed hard and four thousand years deep."],
		["Jingwei, the Flame Emperor's Daughter", "...I was not filling the sea. I was building something. I never saw it, with the water over it.", "grieve"],
		["Yue Ling", "It could hold the isle. Then the turtles could rest."],
		["Narrator", "Jingwei presses one pebble into Lin Feng's palm, worn smooth as a sword hilt by four thousand years of beaks, and a technique settles into him with it, patient and heavy: Jingwei's Stone Sword.", "Jingwei, the Flame Emperor's Daughter:offer"],
		["Jingwei, the Flame Emperor's Daughter", "I will keep building. Not to fill. To hold. Old Gui at the shrine keeps the turtles' tallies; go up the stairs and shout. He is deaf in one ear and stubborn in the other."],
	],
	"s_yz_herald": [
		["Old Gui, Herald of the Turtles", "Eh? A visitor in the tally-room? I am Gui, herald of the turtles, and these are the tallies of their shifts: fifteen turtles, five isles, three shifts of sixty thousand years. At every shift the God of the Northern Sea blows his conch, and the turtles change places."],
		["Old Gui, Herald of the Turtles", "Then the giant of Longbo took six and two isles sank. Nine turtles were left for three isles, all of them holding at once, and no shift to relieve them. Forty thousand years without a rest. Now the sea has drained and they lie on the dry shelf with the isles on their heads, and they cannot even float."],
		["Lin Feng", "I took the giant's hook from him. Here."],
		["Old Gui, Herald of the Turtles", "...Bent straight. Then nine of us can stop listening for it. But the conch of the shifts belongs to Yu Qiang, God of the Northern Sea, and he has not blown it since the Court told him to wait for orders. He stands at the east end of the isle in a wind of his own.", "grieve"],
		["Old Gui, Herald of the Turtles", "And mind: Wu Zixu, who drove the tidal bore up every river mouth, has stopped the tide, because there is no sea to drive; Shen the clam-dragon, who breathed the mirage that hid us, is breathing false seas to feel better; and the Great Ao who bears Yingzhou is thrashing on the shelf. Mind your feet."],
	],
	"pre:wu_zixu": [
		["Narrator", "On the northern cliffs a pale general in white armour sits a horse made of foam on the bare sand where the tide used to come in, a leather sack slung from his saddle."],
		["Wu Zixu, God of the Tidal Bore", "My king had me sewn into a sack and thrown into the river for telling him the truth, so I became the tide that comes up the river twice a day to tell it again. Now there is no sea. What truth is a tide without water?"],
		["Yue Ling", "The same truth, General. Only quieter."],
	],
	"post:wu_zixu": [["Narrator", "Wu Zixu's horse dissolves into foam, and the foam runs west into the last of the channel and lies there, waiting. When the sea comes back, he says, he will ride the bore up every river again and tell the truth to whoever stands on the bank. He hopes somebody will listen this time."]],
	"pre:shen": [
		["Narrator", "In the mist over the drained bay lies a great pale clam with a dragon's head, breathing out of her shell, and every breath builds a city in the air: towers, markets, a harbour full of ships, and a sea that is not there."],
		["Shen, the Mirage Clam-Dragon", "The Court said: breathe, and hide the isles, and I breathed for two thousand years. Now nobody tells me what to hide, so I breathe what is missing. Isn't it lovely? It's a sea."],
		["Lin Feng", "It isn't a sea. People are walking into it."],
	],
	"post:shen": [["Narrator", "Shen's mirage folds up like a fan and goes back into her shell. When the sea comes home, she says, she will breathe only for fun: palaces over the water at dawn, for fishermen to look at and know they are not real. Every mirage should know it is a mirage."]],
	"pre:great_ao": [
		["Narrator", "On the dry shelf under Yingzhou lies a turtle the size of a hill with the whole isle on its head, its flippers beating the sand for water that is not there."],
		["The Great Ao Who Bears Yingzhou", "...thirsty... forty thousand years... the sea is gone... I cannot put it down... I cannot put it down..."],
		["Lin Feng", "Then let me hold it with you, for a moment."],
	],
	"post:great_ao": [["Narrator", "The Great Ao's thrashing slows and stops. Yue Ling calls down the Spring Rain she learned in her first winter on the mountain, and it falls on the old shell like a blessing, and the turtle sighs, and sees the reef of Jingwei's stones beside its head, and notices for the first time that it is not holding the isle alone."]],
	"pre:yu_qiang": [
		["Narrator", "At the east end of Yingzhou, in a wind of his own, stands a god with a man's face and a bird's body, green snakes hanging from his ears and green snakes under his feet. A great conch hangs at his side."],
		["Yu Qiang, God of the Northern Sea", "The Emperor told me: keep the shifts, and wait for orders. I have waited forty thousand years. The orders are coming. Everybody tells me there are no more orders. That is exactly what somebody would say who wanted me to stop waiting."],
		["Lin Feng", "I am asking you to stop waiting."],
	],
	"post:yu_qiang": [
		["Yu Qiang, God of the Northern Sea", "...Then who will tell me when to blow the conch?"],
		["Lin Feng", "The turtles. They have been telling you for forty thousand years."],
		["Narrator", "Yu Qiang gives Lin Feng the conch of the shifts, and Lin Feng blows it. The sound goes down through the isles into the shelf, and under Penglai, Fangzhang and Yingzhou two turtles out of every three let go, for the first time in forty thousand years, and sleep, while the third and Jingwei's reef hold. Old Gui weeps into his tallies."],
		["Narrator", "Beyond Yingzhou the sea floor slopes down and down to the east, towards a roar like every river in the world at once. The way to the Returning Ruins is open."],
	],
	"s_gx_intro": [
		["Narrator", "The sea floor runs down for a hundred li to the lip of the Returning Ruins: wrecks, drowned forests of coral, whole sunken mountains standing in the open air for the first time since the Yellow Emperor. On a slope lies a great ship of Qin, its stern cabin still dry, and in it sits the ghost of an old sailor, steering nothing."],
		["Steersman Hong of the Lost Fleet", "Starboard... steady... Oh. A living man, on my deck. You are not on the crew list, but then nobody is any more. I am Hong, steersman of the Penglai-Seeker, Xu Fu's flagship: sixty ships out of Langya, two thousand two hundred years ago.", "shock"],
		["Steersman Hong of the Lost Fleet", "He came back down from the isle with a green fruit with a bite out of it and a look in his eyes I did not like, and told me to steer east, to Guixu, where the sunken isles were. I said no ship comes back from Guixu. He said: then it will not have to."],
		["Steersman Hong of the Lost Fleet", "He tore up his logbook on the way down, and the pages are all over the sea floor now the water is gone. Bring them to me. I would like to know, before I go, what he was thinking."],
	],
	"s_gx_return": [
		["Steersman Hong of the Lost Fleet", "Four pages, all in his hand. Listen: 'Day one. Three thousand children ashore. I have carved every name. I will be back before the youngest loses a tooth.'"],
		["Steersman Hong of the Lost Fleet", "'Year forty. I have not grown one grey hair. I cannot sleep. I remember the Emperor's order word for word, and I cannot remember my mother's face.' And the last: 'If I find a ripe fruit, I can finish. I would like to finish.'"],
		["Yue Ling", "He doesn't want to live for ever. He wants to stop being stopped."],
		["Steersman Hong of the Lost Fleet", "Then he is down at the lip of the Ruins, where the summit of Daiyu has come up out of the water, waiting for the last tree to ripen. Ah Fu the ship's boy will show you the way; he never grew up either. Go on. I have a ship to steer."],
	],
	"s_gx_boy": [
		["Ah Fu, the Ship's Boy Who Never Grew Up", "Are you going to see Master Xu? He gave me a bite of the green fruit when I was hungry, two thousand years ago. Just a little bite. So I'm still ten."],
		["Ah Fu, the Ship's Boy Who Never Grew Up", "He isn't wicked, you know. He just can't change his mind. Once he decides something he can't undecide it. He decided to come back with the elixir, so he can't come back without it.", "shake"],
		["Lin Feng", "Then we'll help him find a way to come back."],
		["Ah Fu, the Ship's Boy Who Never Grew Up", "There's things in the way. The Admiral, who still thinks we're at sea. The stopper Master Xu rolled down the slope, which won't stop rolling. And the Sea. The real one: Ruo of the Northern Sea, rising out of the drain. She's very, very angry."],
	],
	"pre:drowned_admiral": [
		["Narrator", "On the northern slope a warship of Qin stands upright on the dry sea floor with every sail set, and on its deck an admiral in rusted armour is shouting orders at a crew of skeletons."],
		["The Admiral of the Lost Fleet", "HOLD COURSE! Steady as she goes! Sixty ships to Penglai for the Emperor's elixir, and we shall not turn back!"],
		["Yue Ling", "Admiral... your ship has not moved for two thousand years."],
	],
	"post:drowned_admiral": [["Narrator", "The Admiral lowers his sword and looks over the rail at the sand for a long time. Then he gives his last order: all hands ashore. The skeletons climb down and walk west across the sea floor in a long, neat line towards Landfall, where somebody's grandchildren's grandchildren may still have their names."]],
	"pre:guixu_stopper": [
		["Narrator", "Up and down the southern slope, like a boulder in a gutter, rolls a plug of bronze as big as a temple, engraved with the Court's seals and a ledger of every river in the world."],
		["The Bronze Stopper of Guixu", "WHERE DO I GO? WHERE DO I GO? I was made to be in a hole. Then I was pulled out. Nobody made me to be out."],
		["Lin Feng", "Then rest. You don't have to go back in."],
	],
	"post:guixu_stopper": [["Narrator", "The Stopper rolls to a halt against a coral reef and lies there ringing softly. It is not going back in, Lin Feng tells it. Nothing is. Under the open sky the ledger engraved on it, every river in the world signed for, begins to fade."]],
	"pre:hai_ruo": [
		["Narrator", "At the lip of the Returning Ruins the last of the sea pours over the edge into a darkness without a bottom, and out of the roar rises a figure of water as tall as the sky, with the whole Eastern Sea in her eyes."],
		["Ruo of the Northern Sea, the Sea Itself", "The River Earl came to me once so proud of his little river, and I showed him how small he was. Now some little man has pulled out my floor, and I am pouring away into the dark, and I am small. I hate being small."],
		["Lin Feng", "He Bo learned to like it."],
	],
	"post:hai_ruo": [["Narrator", "Ruo sinks back into the roar, and for a moment the sea holds still at the lip, listening, while Lin Feng tells her about He Bo at Longmen, who leaves the brides alone now and keeps a small and very happy river. The sea laughs, a wave the size of a province, and goes on pouring; but slower."]],
	"pre:xu_fu": [
		["Narrator", "On the drowned summit of Daiyu, in the open air at the very lip of the Ruins, grows a single tree of pearl with one fruit on it, not yet ripe. Under it stands a man in the robes of a Qin court magician, not a day older than the morning he sailed, holding a green fruit with one bite out of it."],
		["Xu Fu, Who Sought the Elixir", "Another one come to stop me. Everybody has tried: the immortals, the sea, my own ship. I cannot be stopped. That is the trouble. I was stopped two thousand years ago, by this."],
		["Lin Feng", "The children you left are still waiting at Landfall. Their grandchildren's grandchildren."],
		["Xu Fu, Who Sought the Elixir", "I promised them the elixir. I cannot go back without it. I cannot. I have tried to want to, and I cannot."],
	],
	"post:xu_fu": [
		["Narrator", "Xu Fu falls to his knees under the pearl tree. Above him, in the roar of the sea pouring into the dark, the last fruit of Daiyu turns from green to white, ripe at last, and drops into his hands."],
		["Xu Fu, Who Sought the Elixir", "...Ripe. After two thousand years. I could eat it and stop when I choose. I could live as long as I liked."],
		["Yue Ling", "What would you like?"],
		["Xu Fu, Who Sought the Elixir", "...I would like to grow old. I would like to see the children. I would like to finish."],
		["Narrator", "He eats the ripe fruit, and his first grey hair comes in while they watch. He gives Lin Feng the green one with the bite out of it. Behind him the sea goes on pouring over the lip into the dark, and nothing comes back up. The water has forgotten how; somebody will have to remind it."],
	],
	"s_p12_end": [
		["Narrator", "Mazu's boat brings them back along the channel to Penglai at dusk, with Xu Fu sitting in the bow, getting older by the hour and looking at everything. The whole of Landfall is on the sand to meet them."],
		["Headwoman Xu Qian of Landfall", "...You are him. The hand on the slips. You are older than I thought you would be.", "shock"],
		["Xu Fu, Who Came Back", "I am older than I was this morning. I said I would come back with the elixir, and that none of you would grow old. I was wrong. You all grew old. That was the elixir. I just did not know what it looked like.", "kneel"],
		["Teacher Qin of the Thousand Names", "Three thousand names, Master Xu. Every child in Landfall can say them. Will you hear them?", "offer"],
		["Narrator", "He listens to all three thousand, sitting on the floor of the Hall of the Thousand Names. Lin Feng gives the Headwoman the green fruit with the bite out of it, and she buries it under the hall, where nobody will ever eat it. Then everybody looks at Lin Feng, because out to the east the sea is still pouring into the dark."],
		["Mazu, Who Brings the Boats Home", "The Ruins took the sea because they have forgotten how to give it back. The Court wrote every return in a ledger for so long that the water does not remember how to rise by itself."],
		["Yue Ling", "Like the Jianmu, which forgot how to grow. Somebody has to remind it."],
		["Lin Feng", "Then I will go and stand at the lip.", "nod"],
	],
	"pre:s_break17": [
		["Narrator", "Lin Feng stands on the drowned summit of Daiyu at the lip of the Returning Ruins, Jingwei's pebble in his pocket and Yu Qiang's conch at his belt. The tribulation that gathers is every water in the world at once, the rain, the rivers, the springs under the Jianmu's roots and the Silver River of heaven, pouring past him into the dark and asking where home is."],
		["Yue Ling", "Which way does it come back?"],
		["Lin Feng", "Every way. That is what returning is.", "point"],
	],
	"post:s_break17": [
		["Narrator", "Lin Feng lets every water in the world pass through him into the Ruins, holding nothing back and keeping nothing, and in the dark at the bottom of the world the water remembers, and rises: as cloud over the Eastern Sea, as springs under the Jianmu, as the Silver River across the night."],
		["Narrator", "He becomes the first cultivator of Ten Thousand Waters Return: a realm in which everything that goes away can come home."],
		["Narrator", "The tide comes back into Fusang at dawn. Mazu stands on her cliff with her red lantern and two sheepish generals, calling the boats home by name. Wu Zixu rides the bore up every river on the east coast. Rain-Minister Ao Run signs his first page with real sea in it, and Leigong drums for it."],
		["Narrator", "On Penglai, Xu Fu teaches the children of Landfall to sail, slowly, because he is old now and in no hurry. Under the isles two turtles out of every three are asleep, and Jingwei goes on dropping her stones: not to fill the sea, but to hold."],
		["Jingwei, the Flame Emperor's Daughter", "Jingwei. Jingwei. It means: I am still here."],
		["Narrator", "And on Azure Cloud Mountain, in the cool of the evening, Lin Feng sweeps the steps of the sect and the first hundred steps of the Standing Tree, and then goes down to the spring to fill the water jars, because somebody should, and the water comes up out of the ground to meet him."],
	],
	# ---- Part XIII: The Eight Gates
	"recall11": [
		["Narrator", "The tide comes back to Fusang and stays. For a whole autumn nothing goes away that does not come back: the boats, the rain, the swallows, Ling Yu after every race, and the Archivist's library books."],
		["Narrator", "So the peoples of the four realms agree to come to Azure Cloud Mountain and sit down together under the Jianmu: the first Conclave of the Realms, with no Court at the head of the table, because there is no head of the table."],
		["Narrator", "On the eve of it, while the Feathered Folk are landing on the sect's roofs and the dragon-kin are arguing with the cook, eight pillars of gold light go up at once, far away, in all four realms."],
		["Old Shen the Bell-Ringer", "Elder! The sky has bars on it. Gold ones, eight of them. The foxes say there is one at the Gate of Heaven, and the Pearl-Weepers have sent word of one in the Springs.", "shock"],
		["Elder Qing Xuan", "Eight. Of course it is eight. Lin Feng, to the hall. And somebody ask the Feathered Folk to get off my roof."],
	],
	"s_p13_home": [
		["Elder Qing Xuan", "When the Yellow Emperor fought Chiyou at Zhuolu, the war god of the Nine Li filled the field with a fog that lasted a hundred days, and the Emperor's army could not find its own feet."],
		["Elder Qing Xuan", "So the Mysterious Lady of the Nine Heavens came down and taught the Emperor the art of the Eight Gates: Opening, Rest, Life, Harm, Closing, Sight, Alarm and Death. A formation in which every gate is a different road, and only some of them lead out."],
		["Lin Feng", "And with it he won."],
		["Elder Qing Xuan", "With it, and a drum made from a thunder-ox, and a daughter who dried up the rain. Chiyou died, and the Court, which was not yet the Court, buried him under a lock of eight gates so that his war would never wake. The lock answered to the Court. The Court is gone."],
		["Elder Qing Xuan", "Every water comes home through you now, disciple. It seems the dead would like to as well. Ask the Archivist what the Court wrote about Zhuolu. Then I would like you to stop a war that ended five thousand years ago.", "point"],
	],
	"s_p13_archive": [
		["Archivist Lan", "Zhuolu. The Court's file runs to forty boxes and is marked 'victory'. Sit. It says the Eight Gates were set round Chiyou's grave and then scattered over the world, two to a realm, so that nobody could ever stand at all eight at once."],
		["Archivist Lan", "Each gate has a general, or a guardian, or a thing that used to be one, and each answers to something different. The Gate of Opening to a blade, or to gold. The Gate of Rest to a heart that will not sleep. The Gate of Death to a formation, or to a name even the dead respect. Eight pages of very small writing."],
		["Lin Feng", "Then I have to open all eight?", "think"],
		["Archivist Lan", "No. That is the clever part, and the Court never wrote it down: I found it in the Lady's own war-book, which the Court used to prop up a table. A lock of eight gates breaks when half of them stand open. Any half. Open the four whose locks you can answer, in whatever order you like."],
		["Archivist Lan", "And then, says the book, there are three roads into the heart: the road of the sword, the road of the many, and the road of the cauldron. I do not know what that means. The lantern monk in the Maple Gorge might. The oldest maples there were Chiyou's fetters once."],
	],
	"s_p13_yinglong": [
		["Narrator", "Below the broken pillar of Buzhou, Yinglong lies coiled round a spring he dug himself, his great wings folded. He opens one eye when Lin Feng says the name Zhuolu, and does not close it again."],
		["Yinglong, Who Dug the Rivers", "I was there. The Emperor sent me against Chiyou when the fog would not lift. I stored up the waters and dug channels for them, so the fog had somewhere to go. And then I killed him. Nobody ever asks me about that part."],
		["Lin Feng", "What was he?", "think"],
		["Yinglong, Who Dug the Rivers", "A smith. The first. He found the copper in the hills and made ploughs of it before he ever made an axe. His people were starving and the Emperor's people had the river. That is what the war was about. The histories say it was about virtue."],
		["Yinglong, Who Dug the Rivers", "After it I could never fly back up to heaven; the weight of it, they say. I went south and made rain for farmers instead. If he wakes, little cultivator, tell him the rivers I dug water the Nine Li's old fields now. He would want to know.", "grieve"],
	],
	"s_p13_monk": [
		["Lantern Monk Jing Kong", "You came down the funeral road with your eyes open. Good. Look at the old maples: they are red in spring now, and red in summer. They were red when they were iron, too."],
		["Lantern Monk Jing Kong", "When Chiyou died they struck the fetters off him and threw them down here, and the fetters grew into the first maples, red with his blood. Every autumn since, something has walked under them in the fog. It used to walk like a soldier. Lately it walks like a man looking for the way home."],
		["Lin Feng", "The Archivist says there are three roads into the heart of the lock."],
		["Lantern Monk Jing Kong", "Every lock has three keys: the hand that forces it, the friend who is let in, and the smith who makes the key. Open four of the eight gates first, wherever they stand. Then come back, and I will light you the way down."],
		["Lantern Monk Jing Kong", "But first, the funeral road. His war-band has come up out of the fog onto it, and the dead cannot get past them to the Wheel. Drive them back, please. Gently, if you can; they think it is still the war."],
		["Yue Ling", "Four gates in four realms. We have walked further for less.", "laugh"],
	],
	"s_p13_heart": [
		["Narrator", "The fourth gate falls, and far away in the Maple Gorge the fog lifts all at once, like a cloth pulled off a table. Under the oldest maples lies a field that was not there before, trampled and silent, with five thousand years of autumn leaves on it."],
		["Lantern Monk Jing Kong", "Zhuolu. They buried the battlefield with him. The lock is broken, and the heart is open."],
		["Lantern Monk Jing Kong", "Choose your road before you walk down there. Go alone, with only the road you have walked, as the Yellow Emperor did. Or go with every people you have helped at your back. Or go with something made by hand that he has wanted for five thousand years. He will know which before you say a word."],
		["Lin Feng", "And whichever road I take, he is waiting at the end of it.", "nod"],
		["Lantern Monk Jing Kong", "Every road ends somewhere. That is what makes it a road."],
		["Yue Ling", "Whatever road we take, the Conclave should be called first. If a war god is going to stop fighting after five thousand years, the peoples ought to be there to see it."],
		["Lantern Monk Jing Kong", "Then take the Elder's invitations round. He has written one for every people, and he has written them very politely, which for him is a great effort."],
	],
	# Part XIII: the invitations to the Conclave, any four of the eight leaders, in any order
	"visit:yu_hua": [
		["Feather-Mother Yu Hua", "An invitation? To sit down? The Yumin do not sit, Lin Feng, we perch. ...We will perch at your Conclave. All of us. Warn the cook.", "laugh"],
		["Feather-Mother Yu Hua", "Our oldest songs remember Chiyou's fog: a hundred days when no Yumin could see to fly. If you are going to talk to him, ask him to keep it to himself."],
	],
	"visit:ao_run": [
		["Rain-Minister Ao Run", "The Ministry has a file on Yu Shi, the Rain Master who drowned an emperor's army. It is very thick and every page of it is wet. We will come, and we will bring the file."],
		["Rain-Minister Ao Run", "The dragon-kin fought for the Yellow Emperor at Zhuolu; Yinglong dug the channels that drained the fog. It will be interesting, to sit across a table from the other side at last."],
	],
	"visit:hu_qingyi": [
		["Hu Qingyi, the Ninth-Tail Matron", "A Conclave with no head of the table. How deliciously confusing. The foxes accept, on condition that nobody asks us to sit still.", "laugh"],
		["Hu Qingyi, the Ninth-Tail Matron", "My grandmother's grandmother saw Chiyou once, from a long way off. She said he laughed like a bell cracking and that he was kind to animals. Nobody remembers that part."],
	],
	"visit:shui_lian": [
		["Pearl-Weaver Shui Lian", "We will come up out of the dark for it. We have never seen a council held in daylight. Will there be weeping? We are very good at weeping."],
		["Pearl-Weaver Shui Lian", "The old songs say the Nine Li were river people, like us. When they lost, the water took their names. We still sing some of them; we could sing them to him."],
	],
	"visit:bu_si": [
		["Elder Bu Si of the Deathless", "We do not die, so we are always the last to arrive anywhere. We will try to be early. It will be a novelty."],
		["Elder Bu Si of the Deathless", "Chiyou is dead and does not know it. We are alive and cannot stop. Perhaps the two of us should sit together at your Conclave and compare notes.", "think"],
	],
	"visit:ming_yi": [
		["Lantern-Magistrate Ming Yi", "The shades accept. We will bring our own lanterns and our own minutes, which will be more accurate than the Archivist's. Tell her I said so."],
		["Lantern-Magistrate Ming Yi", "Chiyou's soul never came down to Youdu to be registered. Five thousand years outstanding. I have a form for him, if he would like to fill it in at last."],
	],
	"visit:xu_qian": [
		["Headwoman Xu Qian of Landfall", "Landfall, at a council of the realms. Two thousand years ago we were three thousand children nobody wanted. Of course we will come. Master Xu wants to come too; he likes meetings now."],
		["Headwoman Xu Qian of Landfall", "Teacher Qin says the Nine Li were the first people the Court ever wrote out of history. We know how that feels. Tell the war god we kept our names."],
	],
	"visit:he_xiangu": [
		["He Xiangu of the Lotus", "The immortals of the isles at a council with farmers, fishermen and shades. Two thousand years ago we would have been offended. We will come, and we will be quiet, which will be good for us."],
		["He Xiangu of the Lotus", "Lu Dongbin met Chiyou's Banner once, in the sky over the sea. He says it was the saddest light he ever saw. Bring the war god something kind, if you can."],
	],
	"pre:chiyou": [
		["Narrator", "In the middle of the field of Zhuolu, under a sky that has not been blue in five thousand years, stands a giant in bronze with the horns of an ox, iron brows and an axe in each of four hands. His eyes are open. They have been open the whole time."],
		["Chiyou, War God of the Nine Li", "Another army of the Yellow Emperor. Another hundred days of fog. I have dreamed this battle every night since I died. In the dream I never win, and I never stop."],
		["Lin Feng", "The Yellow Emperor is gone, and so is his Court. I came to ask what you want."],
		["Chiyou, War God of the Nine Li", "WANT? I want my people. I want the Nine Li. I want to go home. But first I want to fight, because I do not remember how to do anything else."],
	],
	"post:chiyou": [["Narrator", "The war god goes down on one knee in the trampled field, and the axes fall out of his hands into five thousand years of leaves."]],
	"pre:xingtian": [
		["Narrator", "Before the Gate of Opening, under a sky gone gold, dances a giant with no head: eyes in his chest, a mouth in his belly, a shield in one hand and an axe in the other."],
		["Xingtian, Who Dances Without a Head", "The Emperor took my head and I kept fighting. I will keep fighting until the sky falls. It nearly did, I hear. Pity."],
	],
	"post:xingtian": [
		["Narrator", "Xingtian stops dancing. Very slowly he sets down his shield and his axe, and the Gate of Opening swings wide behind him."],
		["Xingtian, Who Dances Without a Head", "...Five thousand years. My feet hurt."],
	],
	"pre:yu_shi": [
		["Narrator", "Rain falls at the Gate of Alarm so hard that every drop is a drumbeat. In the middle of it stands an old man with a bowl, tipping out a storm."],
		["Yu Shi, the Rain Master of Zhuolu", "I drowned an emperor's army once, for a friend. Nobody has asked me to stop since. Have you come to ask?"],
	],
	"post:yu_shi": [["Narrator", "The Rain Master tips his bowl upright, and the rain stops, and over the Gate of Alarm there is a rainbow, which seems to embarrass him."]],
	"pre:liang": [
		["Narrator", "At the Gate of Rest the black water lies perfectly still, and a soft voice sings from under it, a lullaby so gentle that Yue Ling yawns."],
		["Liang, Goblin of the Black Springs", "Sleep. Everyone sleeps here. Nobody wakes. It is very restful. Sleep..."],
	],
	"post:liang": [["Narrator", "The goblin's song breaks off in a gurgle, and the black water at the Gate of Rest begins, for the first time in five thousand years, to flow."]],
	"pre:bronze_brothers": [
		["Narrator", "Across the Gate of Death stands a wall of bronze heads and iron brows: the last of Chiyou's eighty-one brothers, shoulder to shoulder, chewing gravel."],
		["The Bronze-Headed Brothers of Chiyou", "WE HOLD. WE HOLD THE GATE. WE HAVE HELD IT SINCE ZHUOLU. WHAT DAY IS IT?"],
	],
	"post:bronze_brothers": [
		["Narrator", "One by one the brothers sit down in the road. The Gate of Death stands open behind them, and it turns out to lead only to a quiet field where the grass is long."],
		["The Bronze-Headed Brothers of Chiyou", "...Is he down there? Our brother? Tell him we held."],
	],
	"pre:red_banner": [
		["Narrator", "Over the Gate of Sight a red comet hangs low enough to touch, and in its light Lin Feng sees the war he fears most: Azure Cloud Mountain burning, and Yue Ling not there."],
		["Chiyou's Banner, the Red Comet", "Look. LOOK. This is what a war is. Every war. Look at it and tell me you will still walk in."],
	],
	"post:red_banner": [["Narrator", "The Red Comet dims to an ember and the vision goes out with it. Yue Ling is standing right there, frowning at him. The Gate of Sight opens on a perfectly ordinary sunset."]],
	"pre:mast_goblin": [
		["Narrator", "Beside the wreck of the Penglai-Seeker the old mainmast has grown a face, and arms, and a very bad temper, and the Gate of Closing hangs from its yard like a sail."],
		["Mei, Goblin of the Old Mast", "CLOSED. Closed, closed, closed. I held up a sail for two thousand years and nobody ever said thank you. Everything is closed."],
	],
	"post:mast_goblin": [["Narrator", "The old mast creaks, and something in the wood that has been clenched for two thousand years lets go. The Gate of Closing opens with the sound of a sail filling."]],
	"pre:fetter_maple": [
		["Narrator", "High in the gorge stands the oldest maple of all, its trunk still shaped like a shackle and red as the day it was forged. Its branches close across the Gate of Life like fingers."],
		["The Fetter-Maple of Chiyou", "I held him. I was made to hold him. If I let go, what am I?"],
	],
	"post:fetter_maple": [["Narrator", "The fetter-maple's branches open, and its leaves begin to fall, red and gold, for the first time in five thousand years. Beyond it the Gate of Life stands open, and smells of spring."]],
	"pre:kui_drum": [
		["Narrator", "On the slope below the broken pillar a great drum of grey hide beats by itself, and every beat is a thunderclap. The ground jumps. Yue Ling's hair stands on end."],
		["Narrator", "It was made to break an army's heart. It does not know how to do anything else."],
	],
	"post:kui_drum": [["Narrator", "The drum gives one last soft beat, like a heart settling, and goes quiet. The Gate of Harm opens behind it on the long road north."]],
	"s_p13_end": [
		["Narrator", "The gold bars fade from the sky one by one, and the Conclave of the Realms meets at last, under the Jianmu, on the sect's practice ground, because it is the only place flat enough for a dragon to sit down."],
		["Elder Qing Xuan", "Nobody sits at the head of the table, because there is no head. Nobody keeps a ledger, because there is no ledger. Somebody will have to keep the minutes, though. Archivist?"],
		["Archivist Lan", "I have kept minutes since the Court burned its own. Pass me the brush. Rain-Minister, you are dripping on the treaty."],
		["Rain-Minister Ao Run", "It is a treaty about rain. It ought to be wet."],
		["Hu Qingyi, the Ninth-Tail Matron", "The foxes propose that the Conclave meet every autumn, and that it never decide anything important, so that everybody keeps coming back to argue."],
		["Lantern-Magistrate Ming Yi", "The shades second it. We have all the time in the world, and nothing at all to do with it."],
	],
	"pre:s_break18": [
		["Narrator", "Lin Feng stands at the foot of the Jianmu with every road he has walked behind him: the steps of the sect, the bamboo forest, the Ladder of Heaven, the bare sea floor, the field of Zhuolu. The tribulation that gathers is all of them at once, every road asking which one he will choose."],
		["Yue Ling", "Which one?"],
		["Lin Feng", "I don't have to choose. That was the secret all along.", "laugh"],
	],
	"post:s_break18": [
		["Narrator", "Every road Lin Feng has walked runs through him at once, and none of them is the only right one, and the tribulation, finding nothing in him to divide, thins out into a clear autumn sky."],
		["Narrator", "He becomes the first cultivator of Myriad Daos as One: a realm in which every road leads somewhere worth going."],
		["Narrator", "The Conclave of the Realms sits down for the first time under the Jianmu, and argues happily about everything. Nobody is in charge of it. Auntie Zhou feeds everybody."],
	],
	# ---- Part XIV: The Ripening of Karma
	"recall12": [
		["Narrator", "The first Conclave goes on for nine days, and on the tenth everybody goes home. The sect is very quiet. Lin Feng sweeps the steps in the evening, and the broom keeps catching on something that is not there."],
		["Narrator", "It is a thread. Then a dozen of them: fine as spider silk and warm, running from his wrists out over the edge of the mountain in every direction, and every one of them pulling, very gently, south-west."],
		["Yue Ling", "Lin Feng, your hands. There is something tied to them.", "shock"],
		["Lin Feng", "To both of us. Look at yours."],
	],
	"s_p14_home": [
		["Elder Qing Xuan", "Cause and effect. Every cultivator who climbs far enough meets them at last: everything you set moving on the road comes home, the good and the bad, and asks to be settled."],
		["Elder Qing Xuan", "Most of the threads are light. A herb you picked, a bell you mended. But a few of them were people, and those are heavy, because you changed which way their lives ran."],
		["Lin Feng", "Tala and her herd. Qiu Ye. Iron Fang's boy. Xu Mo's daughter. The girl in the Hag's hut.", "think"],
		["Elder Qing Xuan", "And at the far end of every thread that was cut instead of tied, something has been feeding. The old books call it Nie: the shadow of everything owed and never paid. It gathers where debts are reckoned."],
		["Yue Ling", "The Wheel of the Six Paths."],
		["Elder Qing Xuan", "Go down the funeral road and ask Judge Cui what is waiting there. Then go and find your five. Whatever you made of them, they are part of you now, and they are going to be part of what happens.", "point"],
	],
	"s_p14_judge": [
		["Narrator", "The Wheel turns slowly, the way it should. But round its rim something has settled like soot: a darkness made of tally-slips and broken oaths and the ends of a thousand quarrels."],
		["Judge Cui Jue", "Every grudge the dead cannot carry over the bridge, they leave here, and the Wheel grinds it small. It has always been so. But this year the grudges have learned to stand up."],
		["Judge Cui Jue", "Look into the Karma Mirror. Your five threads run straight into the heart of it, and something is pulling on them from the other end. Nie. It is as old as the first unpaid debt, and you have been feeding it all the way up the mountain."],
		["Lin Feng", "Every foe I put down. Every promise I made in a hurry."],
		["Judge Cui Jue", "And every one you kept. It cannot eat those. Thin out the grudges round the rim before they find the funeral road; then go and settle your threads. A debt that is paid cannot be eaten.", "nod"],
	],
	"s_p14_mirror": [
		["Judge Cui Jue", "Your five are settled, one way or another. Good. Now look into the Mirror again, and look past them."],
		["Narrator", "In the Karma Mirror the Wheel turns and the soot round its rim is thinner. But six threads of it never come to the Wheel at all: they run back up the funeral road and away across the world, and every one ends somewhere Lin Feng remembers."],
		["Narrator", "The bamboo below the sect. The red water of the marsh. The graves of the sword saints. A dry riverbed under Tushan. The aeries of Juntian. A wreck on the slope of the Returning Ruins."],
		["Judge Cui Jue", "Most of what the dead are owed comes down here, and the Wheel grinds it small. These six would not come. Their owners have gone over the bridge, but what they were owed is still owed, and it has taken root where they fell. Nie drinks from all six."],
		["Lin Feng", "Iron Fang. The Marsh Hag. The Headless Saint. Fangfeng. Kui. The Admiral. I put every one of them down.", "think"],
		["Judge Cui Jue", "And never asked them anything. Go to each where it fell. A grudge does not listen until it has spent itself, so it will fight you; when it is spent, ask it what it was owed. Pay it if you can. Whatever you leave unpaid, Nie will be holding when you come back.", "point"],
		["Yue Ling", "Six fights with six people we already beat once."],
		["Lin Feng", "We beat them. That part is done. It's the asking that was left over."],
	],
	# the grudges that stayed (grudges.gd): their last words before the fight and once they are spent;
	# the choice of what to do about each follows the "post:" lines
	"pre:grudge_iron_fang": [
		["Iron Fang's Grudge", "The sweeper. You swept me off this road once. Has the sect sent you back to sweep up what's left?"],
		["Lin Feng", "I came to ask what you were owed."],
		["Iron Fang's Grudge", "Then hold out your hands the way I held out mine at that gate, and see how far asking gets you."],
	],
	"post:grudge_iron_fang": [
		["Narrator", "The grudge comes apart like wet paper. Under it, sitting in the bamboo litter with his knees drawn up, is a boy of twelve with a gap where a tooth should be."],
		["Iron Fang's Grudge", "They never tested me. Not even with the stone. The gate disciple looked at my father's patched sleeves and sent me down the steps, and I never knew if there was anything in me to test."],
	],
	"pre:grudge_marsh_hag": [
		["The Marsh Hag's Grudge", "Another bright young root come for my lotuses. They are not for sale. They were never for sale. Nobody ever paid for them."],
		["Yue Ling", "She's reading out names. Settlers' names, and sums of money."],
		["The Marsh Hag's Grudge", "Thirty-six families and not one copper. Pay or drown, cultivator. Those are the terms."],
	],
	"post:grudge_marsh_hag": [
		["Narrator", "The red water stills. The grudge sits down on the bank among the blood lotuses: a stooped woman in a wet shawl with a ledger open on her knees, running her finger down a list that never ends."],
		["The Marsh Hag's Grudge", "I kept them alive a whole winter on lotus-root and willow bark. The Court sent them, and the Court never paid, and when the water took them nobody came to say sorry. I don't even remember my own name. It was at the top of the ledger once."],
	],
	"pre:grudge_headless_saint": [
		["Narrator", "Among the graves of the sword saints a figure without a head salutes Lin Feng in the old way: sword raised, heels together. The bow is perfect. It is the bow Lin Feng learned on the steps of the sect."],
		["Yue Ling", "He doesn't want to hurt you. He just has nothing to say it with except the sword."],
		["Lin Feng", "Then I'll answer the same way. Sword Saint, I am of your school."],
	],
	"post:grudge_headless_saint": [
		["Narrator", "The saint lowers his blade, kneels, and writes in the grave-dust with one finger, slowly, like a man who has not held a brush in a thousand years."],
		["Narrator", "A name, his own, in the old script. Beneath it, smaller: Why was it taken down?"],
	],
	"pre:grudge_fangfeng": [
		["Fangfeng's Grudge", "STOP. STOP AND LISTEN. There's a village under the dyke and the water is coming and I have to tell somebody!"],
		["Yue Ling", "It thinks the flood is still coming. It has been standing in that breach for four thousand years."],
		["Lin Feng", "Then let's help it put the water down first."],
	],
	"post:grudge_fangfeng": [
		["Narrator", "The giant's grudge goes down on one knee in the dry riverbed and, for the first time in four thousand years, lets go of the water that is not there. It is panting like a man who has run a very long way."],
		["Fangfeng's Grudge", "I was late. I know I was late. They were cutting off my head before I could tell them why."],
	],
	"pre:grudge_kui": [
		["Narrator", "The thunderhead over the aeries comes down on one leg with a sound like the first beat of a war drum, and every wind bell in Juntian rings at once."],
		["Kui's Grudge", "BOOM. BOOM. Before you can beat me, I beat you. BOOM."],
		["Yue Ling", "It isn't angry. It's frightened. Every thunderclap still sounds like the drum to it."],
	],
	"post:grudge_kui": [
		["Narrator", "The thunder-ox's grudge settles on the cloud like a tired animal, its one leg folded under it, its great sides heaving. Far off in the Eastern Sea, something it remembers smells of salt."],
		["Kui's Grudge", "I used to bellow because I was happy. Now I bellow first. Before the drum."],
	],
	"pre:grudge_admiral": [
		["Narrator", "On the tilted deck of the wrecked flagship a shadow in an admiral's coat stands at the wheel, holding a course for a shore it will never reach. When it turns it has no face, only the shape of somebody listening very hard."],
		["The Admiral's Grudge", "You came from the east. From the isles. Did you see her? A girl of eleven with a red ribbon. They called the names on the beach. Did anybody call hers?"],
		["Lin Feng", "I'll tell you what I know. But you'll have to let go of the wheel first."],
	],
	"post:grudge_admiral": [
		["Narrator", "The Admiral's grudge lets go of the wheel. It has never let go of it before, and its hands do not know what to do."],
		["The Admiral's Grudge", "Lingbo. Eleven years old. She had a red ribbon, and she was afraid of the sea. I told her she would be home within the year."],
	],
	"pre:nie": [
		["Narrator", "At the heart of the Wheel, where the six paths meet, the soot of a thousand grudges stands up and becomes a shape: no face, many hands, and in every hand a tally of something Lin Feng owes."],
		["Nie, the Unpaid", "Three thousand foes you put down on the road up. Did you ever ask what any of them was owed? I asked. I remember every one."],
		["Yue Ling", "It is speaking with their voices. The bamboo wolves. The bandits. The Hag."],
		["Lin Feng", "Then let them speak. I will pay what I can, and stand for the rest."],
	],
	"post:nie": [
		["Narrator", "Nie comes apart the way a quarrel does when somebody finally says sorry: not all at once, but thread by thread, each tally burning down to a grey ash that the Wheel takes in and grinds and turns, at last, into something new."],
		["Judge Cui Jue", "Paid. Or forgiven, which in my courts comes to the same thing. Go home, Lin Feng. The Wheel will take it from here."],
		["Yue Ling", "The threads on my wrists are gone. No. Not gone. They just do not pull any more."],
	],
	"s_p14_end": [
		["Elder Qing Xuan", "I watched the sky over the Wheel clear from the gate. Every thread on the mountain went slack at once, like a bell rope when the ringing stops."],
		["Elder Qing Xuan", "Whatever you made of your five, it is done now and it is yours. That is what a cultivator becomes at the end of the road: not stronger, only settled."],
		["Lin Feng", "Then I think it is time I was settled too.", "nod"],
	],
	"pre:s_break19": [
		["Narrator", "Lin Feng sits on the bottom step of the sect, where he sat the day he came, with every thread of the journey lying slack across his knees. The tribulation that gathers is not lightning: it is every face he met on the road, waiting to hear what he will say."],
		["Yue Ling", "What will you say?"],
		["Lin Feng", "Thank you, mostly. And I am sorry, to some. And goodbye to nobody."],
	],
	"post:s_break19": [
		["Narrator", "Every cause he set moving has met its effect, and nothing is owed either way. The faces nod, one by one, and go back to their own roads."],
		["Narrator", "He becomes the first cultivator of Karma Fulfilled: a realm in which the threads of other lives still run through yours, and none of them pulls."],
		["Narrator", "The Conclave of the Realms meets every autumn after that, under the Jianmu, and argues happily about everything. Nobody is in charge of it. Auntie Zhou feeds everybody."],
		["Narrator", "And on Azure Cloud Mountain, in the cool of the evening, Lin Feng sweeps the steps of the sect, which are the first steps of every road, because somebody should."],
	],
	# ---- Part XV: The Thread She Never Had (the Lotus release; bonds.gd)
	"recall13": [
		["Narrator", "For nine days after the last tribulation nothing on Azure Cloud Mountain is owed to anybody, and Lin Feng sleeps the way he has not slept since he was six."],
		["Narrator", "On the tenth morning Disciple Han brings the Elder's tea and sets out two cups. He stops with the pot in the air and frowns at the second one."],
		["Disciple Han", "Elder, forgive me. Who is the second cup for?"],
		["Yue Ling", "It is for me, Han. It has been for me every morning for ten years.", "shock"],
		["Narrator", "Han looks at her and smiles politely, the way you smile at a guest whose name you are sure you ought to know."],
	],
	"s_p15_home": [
		["Elder Qing Xuan", "Sit, both of you. No, Yue Ling, sit. I mean you most of all. Forgive an old man: this morning, for the space of a breath, I could not remember your name, and I have known it longer than anybody living."],
		["Yue Ling", "Everybody is doing it, Elder. The cook gave me a bowl and then asked if I was lost. The cats still know me. I am clinging to the cats.", "laugh"],
		["Elder Qing Xuan", "When every thread in the world went slack at the Wheel, one thing had no thread to go slack. You were woven, child, not born. Everything you did on the road was counted in Lin Feng's column, because the Seal was his."],
		["Elder Qing Xuan", "While there were debts, the world needed you to help carry them. Now there are none, and the world is very tidy. It is putting away what it has no use for. Gently. But it is putting you away."],
		["Lin Feng", "Then we stop it.", "shake"],
		["Elder Qing Xuan", "You cannot stop tidiness, Lin Feng. I have tried for sixty years with this study. But a thing that has a place does not get put away. She needs a place in the world that is hers: a page in the Book of Life and Death."],
		["Elder Qing Xuan", "Sit with her by the lotus pond where she woke, first. Then go down the funeral road to Judge Cui. If anybody can find a page for somebody who was never born, it is the clerk of the dead.", "point"],
		["Yue Ling", "The pond. Yes. I would like to see it while I still remember it.", "nod"],
	],
	"s_p15_judge": [
		["Judge Cui Jue", "Lin Feng. And... a moment... Yue Ling. I had to look twice. You are fading out of the Karma Mirror, healer, like breath off bronze.", "shock"],
		["Judge Cui Jue", "The Book of Life and Death has a page for everybody who was ever born, and for nobody else. You were woven by the Founder out of the Seal's own lotus. There is nothing to write you on."],
		["Yue Ling", "Then write me in the margin. I do not take up much room."],
		["Judge Cui Jue", "Ha. The margins are full of my notes. But listen. A page is not made; it is grown. Three things grow one: a past that is your own, people who remember you and tie their threads to yours, and a first line you write yourself.", "think"],
		["Judge Cui Jue", "Your past was not lost, healer. Every time a bearer died, the Seal was unwoven and woven again, and what you remembered was pressed out of you like a flower in a book. The Founder kept the pressings. Ask her where."],
		["Lin Feng", "The Founder has been dead for three hundred years."],
		["Judge Cui Jue", "So is half my staff. Go to her barrow in the Graveyard of Sword Saints. But hurry: something has been unpicking the old weave there, and feeding on what comes loose. Moths with no faces and threads that walk.", "point"],
	],
	"s_p15_founder": [
		["Narrator", "Beside the Founder's barrow, where Lin Feng once earned her blessing with a sword, a woman in white sits on the grass threading a needle against the light. She is not quite there. Neither, these days, is Yue Ling."],
		["Echo of Founder Qing Lian", "There you are. I gave you a rose robe because I thought you would grow into it. You have.", "nod"],
		["Yue Ling", "Founder. Mother? I do not know what to call you."],
		["Echo of Founder Qing Lian", "Call me Qing Lian. Mother is a name you earn by staying, and I did not stay. I wove you so that the bearer would never face the end alone, and then I died and left you to do it twenty times.", "grieve"],
		["Echo of Founder Qing Lian", "Every time a bearer died, the Seal came apart and was woven again, and you came up out of the pond with your name and nothing else. I could not bear to throw the rest away. So I pressed it."],
		["Echo of Founder Qing Lian", "What you remembered of each of them, I pressed where the two of you had been happiest: a flute stone, a jetty of lanterns, a kite post on the tea hills, a green under lanterns. Seven pressings are still whole. The rest have been eaten."],
		["Lin Feng", "By the moths.", "think"],
		["Echo of Founder Qing Lian", "By what woke them. When the Seal became a door, the part of it that was a lock was left with nothing to keep shut. It calls itself the Warden now, and it is unweaving her thread by thread, to take her back into the lock where she can never be lost."],
		["Echo of Founder Qing Lian", "Give her back five of the pressings. Ask the people who knew her to tie a thread for her. Then the Warden will have to come out and face you, because she will be too much a person to be a key.", "point"],
		["Yue Ling", "Will you be here when we come back?"],
		["Echo of Founder Qing Lian", "I am an echo, child. Mostly a needle and a habit. But I will try."],
	],
	"pre:forgetting_queen": [
		["Narrator", "In the mulberry woods the silk moths have gone grey and silent. In the middle of them sits their queen, as big as a cart, with a face like a blank page."],
		["The Moth-Queen of Forgetting", "So many little names. So many little days. Give them to me, healer, and nobody will ever hurt you by forgetting them. Nothing hurts once it is gone."],
		["Yue Ling", "Moths go to the light. It is the one thing they cannot forget. Fire, Lin Feng!", "point"],
	],
	"post:forgetting_queen": [
		["Narrator", "The queen falls apart into a snow of grey scales, and out of the scales, all over the woods, come the things the moths had eaten: a child's song, the smell of rain on a roof, a woodcutter's laugh."],
		["Yue Ling", "That laugh was Ah Zhu's. I know it was. She is still in there somewhere, Lin Feng.", "laugh"],
	],
	"pre:unweaver": [
		["Narrator", "On the Loom of Borders, where every thread of every road was once woven, something with a hundred thin hands is winding thread back onto a spindle as big as a tree. Every thread is pink. Every thread is hers."],
		["The Unweaver", "Every thread that was ever spun runs back to a spindle. I am the hand that winds it home. Hold still, little weave. I am only taking you back, stitch by stitch."],
		["Yue Ling", "Not one more stitch.", "shake"],
	],
	"post:unweaver": [
		["Narrator", "The Unweaver's hundred hands go slack, and the threads it was winding run out of the spindle like water: hundreds of them, fine and pink, and every one of them finds its way back to Yue Ling's wrists."],
		["Yue Ling", "They are mine. Lin Feng, look. They are coming back.", "shock"],
	],
	"pre:lock_warden": [
		["Narrator", "Under the Founder's Last Cave, where the mountain goes down to the root of the sect's pond, the Warden waits: a shape of bronze leaves and lotus petals, with a keyhole where its heart should be."],
		["Suo, Warden of the Lock", "Three hundred years I kept the door. Three hundred years she came back to me, every time, and I made her new. Now the door stands open and nobody needs a lock. Give her back. In the lock she will never be forgotten, never be tidied away, never be lost again."],
		["Yue Ling", "In the lock I would never be anything at all. I would rather be forgotten as myself than kept as something else."],
		["Lin Feng", "You heard her.", "nod"],
	],
	"post:lock_warden": [
		["Suo, Warden of the Lock", "...A door that is held open by somebody who chooses to stand in it. I never thought of that. I was only ever made to think about shutting."],
		["Narrator", "The Warden unlocks itself. Leaf by bronze leaf it comes apart and goes down into the pond as lotus seeds, and the last thing to go is the keyhole, which closes."],
		["Yue Ling", "It was only frightened. Like me. Like everybody.", "grieve"],
	],
	"s_p15_end": [
		["Elder Qing Xuan", "Yue Ling. Yue Ling, Yue Ling. I have said it a hundred times this morning to be sure of it, and it stays. Welcome home, child. Properly, this time.", "bow"],
		["Yue Ling", "The cook gave me two bowls this morning and called me by my name, and then scolded me for being thin. It was the best thing that has ever happened to me.", "laugh"],
		["Elder Qing Xuan", "And you, Lin Feng. There is something new in your qi. Every cultivator I ever taught climbed alone; the books say that is what the path is. You have been climbing with somebody beside you the whole way, and it shows."],
		["Elder Qing Xuan", "One more tribulation, I think. The last one is always a mirror. Go and look into it together.", "point"],
	],
	"pre:s_break20": [
		["Narrator", "The last tribulation does not come down out of the sky. It comes up out of the lotus pond: two reflections, his and hers, standing on the water and waiting to see whether the two of them will agree."],
		["Yue Ling", "Together, then. Do not step on my feet."],
		["Lin Feng", "No promises."],
	],
	"post:s_break20": [
		["Narrator", "The reflections bow to each other and go down into the pond, and the pond is only a pond again, with lotuses on it and two people standing at its edge."],
		["Narrator", "Lin Feng becomes the first cultivator of Kindred Dao. Nobody, the old books say, reaches the top of the mountain alone. He finds the books were right, and that it was never meant as a warning."],
		["Narrator", "And on Azure Cloud Mountain, in the cool of the evening, two people sweep the steps of the sect together, and argue about the right way to hold a broom, and neither of them is ever forgotten again."],
	],
	# the people who tie a thread for her (step s_p15_threads, any four, in any order)
	"thread:qiu_ye_end": [
		["Qiu Ye", "Yue Ling? Of course I remember her. She stitched my arm in the Graveyard when I was too proud to say it hurt, and told me pride was very bad for wounds."],
		["Qiu Ye", "Here. The House of Qiu ties a thread for a guest who is family. My grandmother would have tied it tighter. Hold out your wrist, healer."],
		["Narrator", "Qiu Ye ties a green silk thread round Yue Ling's wrist, very correctly, with the knot the old houses of Cloudfoot use, and bows."],
	],
	"thread:tala_end": [
		["Tala of the Horse-Folk", "The healer with the rose sleeves! She sat up all night with my grey mare when the foal came wrong. The herd remembers her better than they remember me."],
		["Tala of the Horse-Folk", "The horse-folk tie a hair from the herd's oldest mare round a friend's wrist, so the herd always knows them by smell. It is not very romantic. It works."],
		["Narrator", "Tala braids a long grey horsehair round Yue Ling's wrist, and somewhere on the steppe an old mare lifts her head and whickers."],
	],
	"thread:hu_end": [
		["Fang Hu", "She was there when I stood over my father with a kitchen knife. I remember her better than I remember him, almost. She did not say anything. She just made sure I ate."],
		["Fang Hu", "Village custom: you tie a red thread on somebody's wrist at New Year for luck. It is not New Year. She can have it early."],
		["Narrator", "Fang Hu ties a red cotton thread round her wrist with big clumsy fingers, and is embarrassed, and grins anyway."],
	],
	"thread:xu_lan_end": [
		["Xu Lan", "She was the first person after the chains who looked at me as if I were not my father's daughter. I have never thanked her for that."],
		["Xu Lan", "My mother's people tied a silver thread for somebody they meant to see again. Silver, for the moon. I have kept one for a long time, waiting for somebody to give it to."],
		["Narrator", "Xu Lan ties a fine silver thread round Yue Ling's wrist, and for a moment looks very much younger than she is."],
	],
	"thread:liu_ying_end": [
		["Liu Ying", "The other healer. The one who sorts her herbs wrong and gets them right anyway. I have been jealous of her for years. Do not tell her."],
		["Liu Ying", "A herb-wife ties a thread of dyed hemp round a colleague's wrist: green for a healer, so the sick know who to trust. Hold still. I am not going to poison you."],
		["Narrator", "Liu Ying ties a green hemp thread round Yue Ling's wrist with the precision of somebody who measures doses in grains."],
	],
	"thread:alchemist": [
		["Alchemist Mo", "Remember her? She corrected my Spring Rain Pill in front of the whole hall in the first week. I have never forgiven her. It was a much better pill."],
		["Alchemist Mo", "There. A thread from the sect's own herb bundles: the red one we tie on a remedy that works. She is a remedy that works."],
		["Narrator", "Mo ties the red string round her wrist with the same knot he ties on every bundle in the storeroom, and pretends to have something in his eye."],
	],
	"thread:archivist": [
		["Archivist Lan", "I have her in the Annals. Every chapter. 'And Yue Ling, the healer.' I wrote it a hundred times and never once asked where she came from. An archivist's sin."],
		["Archivist Lan", "Scholars tie a thread of blue silk round a scroll that must not be lost. I suppose a person can be a scroll."],
		["Narrator", "Archivist Lan ties a blue silk scroll-thread round Yue Ling's wrist, and writes something in the margin of his ledger, and underlines it twice."],
	],
	"thread:mazu": [
		["Mazu, Who Brings the Boats Home", "I bring every boat home, Lin Feng. Every one that was ever lost. I did not know there was a girl who had been lost twenty times, and every time came home by herself."],
		["Mazu, Who Brings the Boats Home", "The fisherwives tie a red thread on the mast so I can find the boat in a storm. I will find her, now. Wherever she goes."],
		["Narrator", "Mazu ties a red mast-thread round Yue Ling's wrist, and out on the pool of the suns every boat at its mooring turns, just a little, to face her."],
	],
	"thread:smith": [
		["Smith Tie", "The healer? She set my arm when a billet slipped, and told me if I ever quenched a blade with that arm again she would set it the other way round. I believed her."],
		["Smith Tie", "Smiths tie a strip of quenched bronze wire on an apprentice who has stood a whole day at the forge. She stood more days than any of them."],
		["Narrator", "Smith Tie twists a fine bronze wire round Yue Ling's wrist with tongs, very gently for a man with hands like anvils, and nods once, the way he nods at a good blade."],
	],
	"thread:granny_wen": [
		["Granny Wen", "Feng'er's healer girl! She sat with me a whole night when my chest was bad, the year of the threads, and sang me that old song about the boat. My own mother used to sing it."],
		["Granny Wen", "In Qingshi we tie a red thread on a girl who has eaten at our table three times. She has eaten at mine thirty. Give me your wrist, child, and stop growing thin."],
		["Narrator", "Granny Wen ties a red thread round Yue Ling's wrist with a village knot, and then, because she cannot help herself, presses a steamed bun into her other hand."],
	],
	"thread:meng_po": [
		["Meng Po of the Naihe Bridge", "Oh, I remember her. I remember everybody, child; it is my curse and my soup. She came over my bridge twenty times without ever being dead, and she never once took the soup."],
		["Meng Po of the Naihe Bridge", "This is the thread I tie on a soul I am sorry to see go. I have never tied it on somebody coming back. Hold still."],
		["Narrator", "Meng Po ties a thread of red-lily fibre round Yue Ling's wrist, and pats her hand, and offers her soup out of habit, and laughs when she says no."],
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
		["Elder Qing Xuan", "Nuwa did not set her pillars at the corners of the world, whatever the Court's maps say. She ringed the tear in the sky, at its south-east edge, so the 'western' pillar stands in a desert south-east of us, and the books still call it west."],
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
		["Narrator", "At the centre of the four pillars, where they all point, Hundun waits: a vast cinnabar shape with six legs and four wings and, where its face should be, nothing at all."],
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

## How the end is told for the road Lin Feng took into the heart of the Eight Gates (Part XIII): the
## Road of the Sword, of the Many Peoples or of the Cauldron (trials.gd TRIALS.chiyou).  Main.dao_dialogue
## adds these to the conversation they are keyed by.
const ROUTE_LINES := {
	"post:chiyou": {
		"sword": [
			["Chiyou, War God of the Nine Li", "...You did not bring an army. The Emperor brought an army, and a drum, and a goddess. You brought a sword and a road. That was a better fight than I ever had at Zhuolu."],
			["Lin Feng", "It is over. It was over five thousand years ago. You can stop now."],
			["Narrator", "Chiyou laughs, a sound like a bell cracking, and lies down in the field, and for the first time since he died he closes his eyes. The fog does not come back."],
		],
		"peoples": [
			["Narrator", "Behind Lin Feng the envoys of the four realms are still arguing: the dragon-kin with the foxes, the shades with the Deathless, the Feathered Folk with everybody. Not one of them has drawn a weapon on any of the others."],
			["Chiyou, War God of the Nine Li", "...They quarrel, and nobody dies. Nobody gives the orders, and still they came. The Nine Li were like this, before the Emperor: nine tribes and no king, arguing round one fire."],
			["Hu Qingyi, the Ninth-Tail Matron", "There is room at the fire, war god. We are holding a Conclave, and nobody is in charge of it. You would fit in perfectly."],
			["Narrator", "Chiyou looks at the quarrelling peoples for a long time. Then he picks up one of his axes, very carefully, and holds it out to Lin Feng handle first."],
		],
		"cauldron": [
			["Narrator", "Lin Feng holds out the elixir of coming home. It smells of millet fields and river mud and the smoke of nine villages' cooking fires, five thousand years gone."],
			["Chiyou, War God of the Nine Li", "...That is the Nine Li. That is home. Nobody has let me smell it since the fog."],
			["Narrator", "He drinks it and grows lighter, and the bronze of him turns to autumn leaves from the feet up, red and gold, and blows away east towards the plains where the Nine Li lived. The last thing to go is his smile."],
		],
	},
	"s_p13_end": {
		"sword": [["Narrator", "Chiyou's axes hang in the Hall of Azure Clouds beside the Founder's broken sword. Every disciple who passes them stops fighting, for a moment, whatever they were fighting about."]],
		"peoples": [["Chiyou, War God of the Nine Li", "The Nine Li second it. Also, I would like some of that soup.", "laugh"], ["Narrator", "The war god of the Nine Li sits at the Conclave as the envoy of a people who have been gone five thousand years, and argues with everybody, and is very happy."]],
		"cauldron": [["Narrator", "In the Maple Gorge the oldest maples turn gold for the first time, not red. The lantern monk says something walked out of the gorge at dawn, east, without looking back."]],
	},
	"post:s_break18": {
		"sword": [["Narrator", "In the field of Zhuolu the grass grows back over the old war, and a sword-stroke is cut in the rock there that nobody else has ever been able to match."]],
		"peoples": [["Narrator", "In the field of Zhuolu the peoples of the four realms plant a maple for every one of them, and the war god of the Nine Li waters them himself."]],
		"cauldron": [["Narrator", "Out on the eastern plains, where the Nine Li lived, the millet comes up thicker every year, and nobody knows why but Alchemist Mo, who will not say."]],
	},
}

## Lines the Dao Lin Feng walks adds to a conversation (Part XI): the Elder's answer when he chooses,
## what Chong and Li make of the way he fought them, and how the story is told afterwards.
const DAO_LINES := {
	"dao_chosen": {
		"sword": [["Elder Qing Xuan", "The Sword. Of course. Three years with a broom taught you to put everything you have into one stroke."], ["Yue Ling", "Just do not cut the tree down by accident."]],
		"wander": [["Elder Qing Xuan", "Free Wandering: Zhuangzi's road. The Peng rises on the wind and the little dove laughs at it. Be the Peng, disciple, and never laugh at the dove."], ["Yue Ling", "I will pack lightly, then."]],
		"heart": [["Elder Qing Xuan", "The Compassionate Heart. You have walked it since the day you refused to take the sky. Now you will know its name."], ["Yue Ling", "Then I will keep yours company."]],
		"formation": [["Elder Qing Xuan", "Formations. The land keeps its shape because it is allowed to, and so does a battle, and so does a city. A careful road."], ["Yue Ling", "Careful. That will be new."]],
		"alchemy": [["Elder Qing Xuan", "The Cauldron. Alchemist Mo will be unbearable. Every pill is borrowed time, disciple: borrow it for others."], ["Yue Ling", "I will carry the pills. You carry the bill."]],
		"illusion": [["Elder Qing Xuan", "The Mirror. The moon in the water is still the moon. Only be sure, when you trick the world, that you never trick yourself."], ["Yue Ling", "Is that really you? ...Just checking."]],
	},
	"post:chong": {
		"sword": [["Chong, Who Lifts Heaven", "You fight like a man with one direction. Good. Heaven has had enough of people with no direction at all."]],
		"wander": [["Chong, Who Lifts Heaven", "You fought like the wind, never where I struck. Go where you like, little Peng. Heaven is wide now."]],
		"heart": [["Chong, Who Lifts Heaven", "You held back. I felt it. Four thousand years, and the first person to touch me was gentle about it."]],
		"formation": [["Chong, Who Lifts Heaven", "Every blow in its place, like the stones of a wall. You would have made a good minister of heaven. Do not."]],
		"alchemy": [["Chong, Who Lifts Heaven", "You fought on borrowed time and paid it all back. My grandfather would have hated you. I like you."]],
		"illusion": [["Chong, Who Lifts Heaven", "I struck at you nine times and hit the sky every time. A good trick. Heaven needs more people who are hard to pin down."]],
	},
	"post:li": {
		"sword": [["Li, Who Presses Down the Earth", "One stroke, all the way down. The earth respects that. So do I."]],
		"wander": [["Li, Who Presses Down the Earth", "You never stood still long enough to be pressed. Perhaps that is the whole trick of it."]],
		"heart": [["Li, Who Presses Down the Earth", "You could have crushed me. You lifted me. ...My grandfather never lifted anybody."]],
		"formation": [["Li, Who Presses Down the Earth", "Every step placed like a foundation stone. You build. I only ever pressed."]],
		"alchemy": [["Li, Who Presses Down the Earth", "You mended yourself and me with the same hand. The Deathless will like you."]],
		"illusion": [["Li, Who Presses Down the Earth", "I pressed down on a reflection the whole fight. Is everything I pressed for four thousand years a reflection too?"]],
	},
	"post:xu_fu": {
		"sword": [["Xu Fu, Who Sought the Elixir", "You fought with one direction, the way I lived. The difference is that you can still turn round."]],
		"wander": [["Xu Fu, Who Sought the Elixir", "You were never where I struck. I have stood in one place for two thousand years. Teach the children that, if you teach them anything."]],
		"heart": [["Xu Fu, Who Sought the Elixir", "You held back every blow. Why? ...Because I am somebody's ancestor. I had forgotten that."]],
		"formation": [["Xu Fu, Who Sought the Elixir", "Every step placed, like the names on the slips. I carved them in order too, once."]],
		"alchemy": [["Xu Fu, Who Sought the Elixir", "A cauldron-walker. Then you know what I did not: no elixir is worth anything unless it is shared."]],
		"illusion": [["Xu Fu, Who Sought the Elixir", "I struck at reflections all fight. I have been chasing one for two thousand years. It was the same one."]],
	},
	"post:yu_qiang": {
		"sword": [["Yu Qiang, God of the Northern Sea", "One stroke and no orders. ...It is a strange feeling, being told nothing and agreeing anyway."]],
		"wander": [["Yu Qiang, God of the Northern Sea", "A wind of your own, like mine. Mine only ever blew where the Court pointed it. Yours goes where it likes."]],
		"heart": [["Yu Qiang, God of the Northern Sea", "You asked me how the turtles were before you asked me anything else. Nobody has asked me that in forty thousand years."]],
		"formation": [["Yu Qiang, God of the Northern Sea", "Three isles, nine turtles, shifts of three. You see it too: a formation is only a kindness that has been counted."]],
		"alchemy": [["Yu Qiang, God of the Northern Sea", "Rest is the oldest medicine. You fight like somebody who knows that."]],
		"illusion": [["Yu Qiang, God of the Northern Sea", "Every blow I struck found a mirror. Like waiting for orders: all reflection, no light."]],
	},
	"post:s_break17": {
		"sword": [["Narrator", "Later they will tell it as the story of the swordsman who cut nothing at all, and opened the way between three worlds with one clean stroke of kindness, and then put his sword away and let the sea come home."]],
		"wander": [["Narrator", "Later they will tell it as the story of the wanderer who went up to heaven and down to the dead and out to the edge of the sea and was home for supper, the way the Peng flies, on a wind of ninety thousand li."]],
		"heart": [["Narrator", "Later they will tell it as the story of the cultivator whose Dao was his heart, who held three realms up only as long as he chose, asked for help, got it, and taught an old magician to grow old."]],
		"formation": [["Narrator", "Later they will tell it as the story of the master of formations who drew no lines at all, only a ladder and a shift for the turtles, and let everybody climb it and everybody rest."]],
		"alchemy": [["Narrator", "Later they will tell it as the story of the cultivator of the cauldron who borrowed time from heaven and earth and paid it back, with interest, to everybody, and found the elixir was only water coming home."]],
		"illusion": [["Narrator", "Later they will tell it as the story of the cultivator of the mirror who showed heaven and earth their reflections in each other, so that neither ever again forgot what the other looked like. Even the mirage of Penglai learned it was a mirage."]],
	},
}
# ---------------------------------------------------------------- cutscene gestures (Part XII)
## The gestures every Blender character can play in a conversation (art/lib/person.py GESTURES, and the
## bow they already had).  A line of dialogue may name one as a third element: ["Speaker", "text",
## "kneel"]; a narrator's line may direct somebody present: ["Narrator", "text", "Speaker:offer"].
## Otherwise emote_for reads one from the words, and most lines are only talk.
const EMOTES := ["nod", "shake", "point", "wave", "laugh", "grieve", "think", "kneel", "offer", "shock", "bow"]
## what whoever is listening does when the speaker makes a gesture
const EMOTE_REPLY := {"offer": "bow", "wave": "wave", "kneel": "bow", "grieve": "nod", "laugh": "nod", "bow": "bow"}

static func _starts(low: String, words: Array) -> bool:
	for wd in words:
		if low.begins_with(wd):
			return true
	return false

static func _has(low: String, words: Array) -> bool:
	for wd in words:
		if low.contains(wd):
			return true
	return false

## [who, gesture] for a line of dialogue: the speaker (or, for a directed narrator's line, the person it
## names) and what they do as the line begins; gesture "" for plain talk.
static func emote_for(line: Array) -> Array:
	var who := str(line[0])
	if line.size() > 2:
		var cue := str(line[2])
		if cue.contains(":"):
			return [cue.get_slice(":", 0), cue.get_slice(":", 1)]
		return [who, cue]
	if who == "Narrator":
		return [who, ""]
	var low := str(line[1]).to_lower().strip_edges()
	if _starts(low, ["thank"]) or low.contains("thank you"):
		return [who, "bow"]
	if _has(low, ["haha", "hah!", "heh", "hehe", "ha! "]) or low.begins_with("ha!"):
		return [who, "laugh"]
	if _starts(low, ["no.", "no,", "no!", "never", "lies", "nobody passes"]):
		return [who, "shake"]
	if _has(low, ["i weep", "weeping", "my tears", "i miss", "never came back", "did not come back", "could save none", "i am sorry", "i'm sorry"]):
		return [who, "grieve"]
	if _starts(low, ["welcome", "greetings", "hello", "a guest", "a visitor", "a boat", "a living man", "oh, look"]):
		return [who, "wave"]
	if _has(low, ["take this", "take it", "for you.", "here.", "here,", "bring them to me", "i give you"]):
		return [who, "offer"]
	if _starts(low, ["...", "eh?", "what?", "wait"]) or low.contains("?!"):
		return [who, "shock" if low.contains("!") else "think"]
	if _starts(low, ["yes", "good.", "good,", "very well", "of course", "just so", "indeed", "agreed", "understood", "splendid", "then i will", "then we"]):
		return [who, "nod"]
	if _has(low, ["go east", "go west", "go north", "go south", "go down", "go up", "climb", "look over", "look:", "over there", "beyond the", "at the east end", "at the west end"]):
		return [who, "point"]
	if low.ends_with("?") and low.length() < 140:
		return [who, "think"]
	return [who, ""]

## Quest scenes in which one of the peoples of the realms first meets Lin Feng: the speaker adds what
## their people think of the Dao he walks (RACES dao_lines).
const DAO_GREETS := ["s_p11_tree", "s_jt_intro", "s_jt_minister", "s_cg_intro", "s_ns_intro", "s_ns_elder", "s_yd_intro", "s_pl_intro", "s_pl_immortal", "s_fz_intro"]
