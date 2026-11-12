class_name Look
extends RefCounted
## Per-region look: ground palette, sky, fog, lighting, weather and the kind of landmark that fills the map.
## g1/g2/path/wall/water/bg also colour the 2D minimap.
##
## Sky is a custom shader (gradient, sun disc and halo, drifting fbm clouds, stars, aurora), the
## environment adds bloom, filmic tonemapping and depth fog, and every theme carries extra keys for
## the terrain shader (ground texture style, grass tufts, horizon silhouettes).

const THEMES := {
	"sect": {"g1": Color("5f9a6a"), "g2": Color("6aa874"), "path": Color("c9b88a"), "wall": Color("2f6a45"), "water": Color("3a78b8"), "bg": Color("0b1020"),
		"sky_top": Color("3a5a9a"), "sky_hor": Color("c8b0d8"), "fog": Color("b8b0d0"), "fog_d": 0.010, "sun": Color("fff0d0"), "sun_e": 1.1, "amb": Color("8090b0"), "amb_e": 0.7, "weather": "petals", "tree": "pine", "decor": "flower"},
	"bamboo": {"g1": Color("4c8a56"), "g2": Color("559560"), "path": Color("b8a878"), "wall": Color("2d7a3a"), "water": Color("3a78b8"), "bg": Color("08140c"),
		"sky_top": Color("2a5a48"), "sky_hor": Color("a8d8a0"), "fog": Color("8cc096"), "fog_d": 0.018, "sun": Color("f4ffd0"), "sun_e": 1.0, "amb": Color("80a890"), "amb_e": 0.75, "weather": "leaves", "tree": "bamboo", "decor": "grass"},
	"marsh": {"g1": Color("5a5a3c"), "g2": Color("63623f"), "path": Color("7a6a4a"), "wall": Color("3a2a22"), "water": Color("4a3a5a"), "bg": Color("140c10"),
		"sky_top": Color("2a1a30"), "sky_hor": Color("9a6a70"), "fog": Color("7a5a64"), "fog_d": 0.030, "sun": Color("ffb0a0"), "sun_e": 0.8, "amb": Color("8a7080"), "amb_e": 0.7, "weather": "bubbles", "tree": "mangrove", "decor": "reed"},
	"frost": {"g1": Color("b4cce0"), "g2": Color("c2d6e8"), "path": Color("9ab4cc"), "wall": Color("6a9ac8"), "water": Color("2a4a8a"), "bg": Color("0a1018"),
		"sky_top": Color("2a4a7a"), "sky_hor": Color("c0e0f8"), "fog": Color("b8d4ec"), "fog_d": 0.020, "sun": Color("e0f0ff"), "sun_e": 1.0, "amb": Color("9ab4d8"), "amb_e": 0.9, "weather": "snow", "tree": "ice", "decor": "snowrock"},
	"thunder": {"g1": Color("52505e"), "g2": Color("5c5a6a"), "path": Color("72707e"), "wall": Color("2a2838"), "water": Color("2a3a6a"), "bg": Color("0a0a14"),
		"sky_top": Color("14142a"), "sky_hor": Color("5a5a8a"), "fog": Color("484868"), "fog_d": 0.022, "sun": Color("c8c8ff"), "sun_e": 0.8, "amb": Color("6a6a9a"), "amb_e": 0.8, "weather": "rain", "tree": "crag", "decor": "pebble"},
	"palace": {"g1": Color("40202c"), "g2": Color("4a2432"), "path": Color("602838"), "wall": Color("200c18"), "water": Color("6a1020"), "bg": Color("100408"),
		"sky_top": Color("200610"), "sky_hor": Color("8a2030"), "fog": Color("501828"), "fog_d": 0.024, "sun": Color("ff6a6a"), "sun_e": 0.9, "amb": Color("8a4a5a"), "amb_e": 0.8, "weather": "motes_red", "tree": "obelisk", "decor": "bones"},
	"abyss": {"g1": Color("1f5a78"), "g2": Color("256680"), "path": Color("c8b890"), "wall": Color("1a8a8a"), "water": Color("0c2a5a"), "bg": Color("041018"),
		"sky_top": Color("04202e"), "sky_hor": Color("2a8aa8"), "fog": Color("1a6a8a"), "fog_d": 0.030, "sun": Color("a8ffff"), "sun_e": 0.9, "amb": Color("5aa0b8"), "amb_e": 0.9, "weather": "bubbles_up", "tree": "coral", "decor": "shell"},
	"volcano": {"g1": Color("4a2a22"), "g2": Color("54302a"), "path": Color("7a4a32"), "wall": Color("24100c"), "water": Color("e0501a"), "bg": Color("140604"),
		"sky_top": Color("280a04"), "sky_hor": Color("e0602a"), "fog": Color("8a3a1a"), "fog_d": 0.024, "sun": Color("ff9a5a"), "sun_e": 1.0, "amb": Color("a06a50"), "amb_e": 0.8, "weather": "embers", "tree": "spire", "decor": "ember"},
	"void": {"g1": Color("2a1e4a"), "g2": Color("32245a"), "path": Color("4a3a7a"), "wall": Color("120a2a"), "water": Color("6a2aa8"), "bg": Color("06020e"),
		"sky_top": Color("08041a"), "sky_hor": Color("4a2a88"), "fog": Color("2a1a52"), "fog_d": 0.020, "sun": Color("b890ff"), "sun_e": 0.8, "amb": Color("7a60b8"), "amb_e": 0.85, "weather": "stars", "tree": "shard", "decor": "starcrystal"},
	"celestial": {"g1": Color("d8d4e8"), "g2": Color("e4e0f2"), "path": Color("f0d890"), "wall": Color("b8a8d8"), "water": Color("8ab8f0"), "bg": Color("1a2040"),
		"sky_top": Color("5a7ac8"), "sky_hor": Color("fff0c0"), "fog": Color("f0e8d8"), "fog_d": 0.012, "sun": Color("fff4d0"), "sun_e": 1.3, "amb": Color("c8c8e8"), "amb_e": 0.95, "weather": "light", "tree": "column", "decor": "cloudpuff"},
	# ---- Part III
	"mirror": {"g1": Color("5a7a98"), "g2": Color("6a8aa8"), "path": Color("d0e4f0"), "wall": Color("a8d0e8"), "water": Color("2a5a98"), "bg": Color("06101a"),
		"sky_top": Color("102a50"), "sky_hor": Color("a0d0f0"), "fog": Color("7aa8c8"), "fog_d": 0.016, "sun": Color("e8f4ff"), "sun_e": 1.0, "amb": Color("90b8d8"), "amb_e": 0.9, "weather": "glints", "tree": "mirrorpane", "decor": "glassshard"},
	"grave": {"g1": Color("3c3c40"), "g2": Color("464648"), "path": Color("78747a"), "wall": Color("5a5660"), "water": Color("2a3a3a"), "bg": Color("08080a"),
		"sky_top": Color("0a0a12"), "sky_hor": Color("5a5a70"), "fog": Color("3a3a48"), "fog_d": 0.026, "sun": Color("a8b8d8"), "sun_e": 0.7, "amb": Color("70708a"), "amb_e": 0.75, "weather": "wisps", "tree": "tombstone", "decor": "bones"},
	"time": {"g1": Color("7a5a2a"), "g2": Color("86642e"), "path": Color("c8a050"), "wall": Color("5a4020"), "water": Color("e8b848"), "bg": Color("141004"),
		"sky_top": Color("2a1a08"), "sky_hor": Color("e8b060"), "fog": Color("a07a3a"), "fog_d": 0.018, "sun": Color("ffd890"), "sun_e": 1.1, "amb": Color("c8a070"), "amb_e": 0.85, "weather": "sand", "tree": "gear", "decor": "cog"},
	"origin": {"g1": Color("8a7ab8"), "g2": Color("9a8ac8"), "path": Color("e8c880"), "wall": Color("c8b8f0"), "water": Color("a8d8ff"), "bg": Color("201830"),
		"sky_top": Color("301a58"), "sky_hor": Color("ffe0f0"), "fog": Color("e8d0f0"), "fog_d": 0.014, "sun": Color("fff0d8"), "sun_e": 0.95, "amb": Color("a898d0"), "amb_e": 0.7, "weather": "light", "tree": "monolith", "decor": "cloudpuff"},
	# ---- Part IV
	"cloudsea": {"g1": Color("8ab8a0"), "g2": Color("9ac8b0"), "path": Color("f0e8d0"), "wall": Color("6a9a7a"), "water": Color("e8f0ff"), "bg": Color("182840"),
		"sky_top": Color("3a78d0"), "sky_hor": Color("e8f4ff"), "fog": Color("dce8f4"), "fog_d": 0.012, "sun": Color("fff8e8"), "sun_e": 1.15, "amb": Color("b0c8e8"), "amb_e": 0.9, "weather": "clouds", "tree": "floatisle", "decor": "cloudpuff"},
	"court": {"g1": Color("3a6a5a"), "g2": Color("447664"), "path": Color("d8c8a0"), "wall": Color("2a8a6a"), "water": Color("2a6a8a"), "bg": Color("061410"),
		"sky_top": Color("0a2a28"), "sky_hor": Color("8ad0b0"), "fog": Color("5a9a88"), "fog_d": 0.018, "sun": Color("e8fff0"), "sun_e": 0.95, "amb": Color("80b0a0"), "amb_e": 0.8, "weather": "lanterns", "tree": "jadepillar", "decor": "lantern"},
	"forge": {"g1": Color("5a4a3a"), "g2": Color("645240"), "path": Color("a08050"), "wall": Color("3a2a1a"), "water": Color("ffc040"), "bg": Color("120a04"),
		"sky_top": Color("1a1008"), "sky_hor": Color("d08a3a"), "fog": Color("7a5a30"), "fog_d": 0.022, "sun": Color("ffd0a0"), "sun_e": 1.0, "amb": Color("a88060"), "amb_e": 0.8, "weather": "sparks", "tree": "furnace", "decor": "ingot"},
	"garden": {"g1": Color("6a9a5a"), "g2": Color("78a866"), "path": Color("e8d8b8"), "wall": Color("c86a8a"), "water": Color("6ab0d8"), "bg": Color("201018"),
		"sky_top": Color("6a5ab0"), "sky_hor": Color("ffd8e0"), "fog": Color("f0d0dc"), "fog_d": 0.012, "sun": Color("fff0e0"), "sun_e": 1.1, "amb": Color("c8b0c8"), "amb_e": 0.85, "weather": "petals", "tree": "peach", "decor": "flower"},
	# ---- Part V
	"dunes": {"g1": Color("d0a868"), "g2": Color("dcb474"), "path": Color("f0dcb0"), "wall": Color("b07a48"), "water": Color("4ab8c8"), "bg": Color("201408"),
		"sky_top": Color("2a4a90"), "sky_hor": Color("ffd8a0"), "fog": Color("f0c890"), "fog_d": 0.014, "sun": Color("fff0c8"), "sun_e": 1.2, "amb": Color("d0b090"), "amb_e": 0.85, "weather": "sandstorm", "tree": "meteor", "decor": "starglass"},
	"fungal": {"g1": Color("3a3a5a"), "g2": Color("44446a"), "path": Color("8a7aa8"), "wall": Color("c070e0"), "water": Color("40e0c0"), "bg": Color("0a0814"),
		"sky_top": Color("100a28"), "sky_hor": Color("6a4aa0"), "fog": Color("4a3a78"), "fog_d": 0.022, "sun": Color("c8b0ff"), "sun_e": 0.7, "amb": Color("8070c0"), "amb_e": 0.8, "weather": "spores", "tree": "glowcap", "decor": "sporecap"},
	"aurora": {"g1": Color("c8d8ec"), "g2": Color("d4e2f2"), "path": Color("a8bcd8"), "wall": Color("5a8ac0"), "water": Color("1a3a6a"), "bg": Color("040a18"),
		"sky_top": Color("061030"), "sky_hor": Color("3a5a98"), "fog": Color("6a88b8"), "fog_d": 0.014, "sun": Color("d0e8ff"), "sun_e": 0.8, "amb": Color("8aa8d8"), "amb_e": 0.9, "weather": "aurora_snow", "tree": "icespire", "decor": "snowrock"},
	"chaos": {"g1": Color("4a3a6a"), "g2": Color("54447a"), "path": Color("e8d8a0"), "wall": Color("e05030"), "water": Color("ff80c0"), "bg": Color("0a0410"),
		"sky_top": Color("1a0830"), "sky_hor": Color("c06090"), "fog": Color("6a3a7a"), "fog_d": 0.016, "sun": Color("fff0e0"), "sun_e": 0.9, "amb": Color("a080c0"), "amb_e": 0.8, "weather": "chaos", "tree": "chaosrock", "decor": "fivestone"},
	# ---- Part VI
	"maple": {"g1": Color("8a8a48"), "g2": Color("9a9450"), "path": Color("c8a878"), "wall": Color("d8582a"), "water": Color("3a88a8"), "bg": Color("1a0c06"),
		"sky_top": Color("3a6ab0"), "sky_hor": Color("ffd8a8"), "fog": Color("e8b890"), "fog_d": 0.012, "sun": Color("ffe0b0"), "sun_e": 1.15, "amb": Color("c8a890"), "amb_e": 0.85, "weather": "maple_leaves", "tree": "maple", "decor": "leafpile"},
	"karst": {"g1": Color("5a9a5a"), "g2": Color("64a864"), "path": Color("d0c8a8"), "wall": Color("a8a8a0"), "water": Color("40a8a0"), "bg": Color("061410"),
		"sky_top": Color("4a7aa0"), "sky_hor": Color("e0ecec"), "fog": Color("c8dcdc"), "fog_d": 0.012, "sun": Color("f8f8e8"), "sun_e": 1.0, "amb": Color("a0c0c0"), "amb_e": 0.85, "weather": "river_mist", "tree": "karstpeak", "decor": "pebble"},
	"lilies": {"g1": Color("6a6a3a"), "g2": Color("78703e"), "path": Color("d8b870"), "wall": Color("d02a20"), "water": Color("e8b840"), "bg": Color("140804"),
		"sky_top": Color("3a1a48"), "sky_hor": Color("f0a060"), "fog": Color("c87a5a"), "fog_d": 0.018, "sun": Color("ffb878"), "sun_e": 0.95, "amb": Color("b08070"), "amb_e": 0.8, "weather": "lily_souls", "tree": "stonelantern", "decor": "spiderlily"},
	"diyu": {"g1": Color("2a2a3a"), "g2": Color("323244"), "path": Color("7a7890"), "wall": Color("3a3a58"), "water": Color("40c0ff"), "bg": Color("04040a"),
		"sky_top": Color("06060e"), "sky_hor": Color("2a3a5a"), "fog": Color("1a2238"), "fog_d": 0.022, "sun": Color("90b0ff"), "sun_e": 0.75, "amb": Color("6878a8"), "amb_e": 0.8, "weather": "ghostfire", "tree": "ghostpagoda", "decor": "ghostcandle"},
	# ---- Part VII
	"village": {"g1": Color("6a9a48"), "g2": Color("7aa850"), "path": Color("c8b088"), "wall": Color("4a7a3a"), "water": Color("6ab0c0"), "bg": Color("0c1408"),
		"sky_top": Color("3a6ac0"), "sky_hor": Color("e8f0d8"), "fog": Color("d0e0c8"), "fog_d": 0.011, "sun": Color("fff4dc"), "sun_e": 1.15, "amb": Color("b0c8a8"), "amb_e": 0.85, "weather": "petals", "tree": "pine", "decor": "flower"},
	"tea": {"g1": Color("4a9a40"), "g2": Color("5aaa48"), "path": Color("d0b890"), "wall": Color("2e6a2a"), "water": Color("5ab0a8"), "bg": Color("061008"),
		"sky_top": Color("4a7ab8"), "sky_hor": Color("e8f4f0"), "fog": Color("d8ece4"), "fog_d": 0.014, "sun": Color("fffae8"), "sun_e": 1.05, "amb": Color("a8c8b8"), "amb_e": 0.85, "weather": "river_mist", "tree": "pine", "decor": "grass"},
	"silk": {"g1": Color("7a8a40"), "g2": Color("88984a"), "path": Color("d8c49a"), "wall": Color("4a6a2a"), "water": Color("5a9a90"), "bg": Color("0e1006"),
		"sky_top": Color("5a6ab0"), "sky_hor": Color("ffe8c8"), "fog": Color("f0dcc0"), "fog_d": 0.013, "sun": Color("fff0d0"), "sun_e": 1.1, "amb": Color("c8b898"), "amb_e": 0.85, "weather": "light", "tree": "peach", "decor": "flower"},
	"loom": {"g1": Color("a890c0"), "g2": Color("b8a0cc"), "path": Color("f0e0f4"), "wall": Color("7a5aa8"), "water": Color("e0b0ff"), "bg": Color("0c0614"),
		"sky_top": Color("2a1a58"), "sky_hor": Color("ffd8a0"), "fog": Color("d8b8e0"), "fog_d": 0.014, "sun": Color("fff0d8"), "sun_e": 1.0, "amb": Color("b8a0d0"), "amb_e": 0.85, "weather": "glints", "tree": "column", "decor": "cloudpuff"},
	# ---- Part VIII: a starlit river ford, cloud cliffs, the Weaver's night palace, Kunlun's jade pool
	"starferry": {"g1": Color("4a7a68"), "g2": Color("568a72"), "path": Color("c8c0a0"), "wall": Color("2e5a4a"), "water": Color("a8c8ff"), "bg": Color("060a14"),
		"sky_top": Color("10183a"), "sky_hor": Color("8a7ab8"), "fog": Color("5a6a98"), "fog_d": 0.014, "sun": Color("d8e0ff"), "sun_e": 0.9, "amb": Color("8898c8"), "amb_e": 0.85, "weather": "glints", "tree": "ferrypost", "decor": "grass"},
	"magpie": {"g1": Color("7a9a88"), "g2": Color("88a894"), "path": Color("e0dcd0"), "wall": Color("5a7a6a"), "water": Color("c0d8f0"), "bg": Color("0a1018"),
		"sky_top": Color("3a5aa0"), "sky_hor": Color("f0e8f0"), "fog": Color("e0e4f0"), "fog_d": 0.016, "sun": Color("fff8f0"), "sun_e": 1.05, "amb": Color("b8c4d8"), "amb_e": 0.85, "weather": "river_mist", "tree": "magpienest", "decor": "cloudpuff"},
	"starpalace": {"g1": Color("6a70b0"), "g2": Color("7a80c0"), "path": Color("e8ecff"), "wall": Color("4a4a8a"), "water": Color("c8d0ff"), "bg": Color("06061a"),
		"sky_top": Color("0a0a30"), "sky_hor": Color("6a5aa8"), "fog": Color("7a78b8"), "fog_d": 0.012, "sun": Color("e8e8ff"), "sun_e": 0.95, "amb": Color("9a98d0"), "amb_e": 0.85, "weather": "glints", "tree": "starpillar", "decor": "cloudpuff"},
	"jasper": {"g1": Color("5aa080"), "g2": Color("68b08c"), "path": Color("f0ecd8"), "wall": Color("3a7a5a"), "water": Color("70e0c0"), "bg": Color("061410"),
		"sky_top": Color("3a78c0"), "sky_hor": Color("fff0e0"), "fog": Color("e0f0e8"), "fog_d": 0.012, "sun": Color("fff8e8"), "sun_e": 1.1, "amb": Color("b0d0c0"), "amb_e": 0.85, "weather": "petals", "tree": "jadepeach", "decor": "flower"},
	# ---- Part IX: a market town under a white-hot noon, cracked drought fields, the steaming valley
	# of the Fusang under a blazing dawn, and the frost and osmanthus of the moon's silver night
	"yanggu": {"g1": Color("b0a068"), "g2": Color("bcac74"), "path": Color("ece0c4"), "wall": Color("8a8a4a"), "water": Color("78c0c8"), "bg": Color("1a1408"),
		"sky_top": Color("8ab4e8"), "sky_hor": Color("fffaec"), "fog": Color("f8f0dc"), "fog_d": 0.012, "sun": Color("fffcf0"), "sun_e": 1.3, "amb": Color("e0d4b8"), "amb_e": 0.95, "weather": "heat_haze", "tree": "stonelantern", "decor": "lantern"},
	"millet": {"g1": Color("c8a858"), "g2": Color("d4b468"), "path": Color("ecd8a8"), "wall": Color("8a6a3a"), "water": Color("8ab8b0"), "bg": Color("201408"),
		"sky_top": Color("6a98d8"), "sky_hor": Color("fff2d0"), "fog": Color("f0dcb0"), "fog_d": 0.014, "sun": Color("fff0d0"), "sun_e": 1.25, "amb": Color("d8c090"), "amb_e": 0.9, "weather": "heat_haze", "tree": "crag", "decor": "grass"},
	"fusang": {"g1": Color("5a9a48"), "g2": Color("6aa852"), "path": Color("e8cc90"), "wall": Color("3a6a2a"), "water": Color("70d8c8"), "bg": Color("0a1408"),
		"sky_top": Color("e89848"), "sky_hor": Color("ffe4a8"), "fog": Color("f0d8a8"), "fog_d": 0.016, "sun": Color("ffd890"), "sun_e": 1.25, "amb": Color("d0c098"), "amb_e": 0.9, "weather": "steam", "tree": "pine", "decor": "flower"},
	"guanghan": {"g1": Color("a8b8d0"), "g2": Color("b8c8e0"), "path": Color("eef4ff"), "wall": Color("6a7aa8"), "water": Color("c0d8ff"), "bg": Color("060a18"),
		"sky_top": Color("0a1030"), "sky_hor": Color("4a5a98"), "fog": Color("6a78a8"), "fog_d": 0.012, "sun": Color("d0dcff"), "sun_e": 0.85, "amb": Color("98a8d8"), "amb_e": 0.9, "weather": "osmanthus", "tree": "column", "decor": "snowrock"},
	# ---- Part X: the ochre river below the Dragon Gate, the grey flood over the rice fields, the
	# smoke and bronze-glow of the casters' mountain, and the storm over the broken pillar
	"longmen": {"g1": Color("7a9a58"), "g2": Color("88a662"), "path": Color("dcc8a0"), "wall": Color("3e6a3a"), "water": Color("4e8a80"), "bg": Color("141008"),
		"sky_top": Color("5a88c0"), "sky_hor": Color("ece4cc"), "fog": Color("d8d0b8"), "fog_d": 0.013, "sun": Color("fff4e0"), "sun_e": 1.1, "amb": Color("b0b098"), "amb_e": 0.85, "weather": "river_mist", "tree": "ferrypost", "decor": "reed"},
	"drowned": {"g1": Color("6a8a58"), "g2": Color("789862"), "path": Color("b8a888"), "wall": Color("3a5a3a"), "water": Color("7a9a90"), "bg": Color("0a100c"),
		"sky_top": Color("5a6a80"), "sky_hor": Color("c8ccd0"), "fog": Color("a8b0b0"), "fog_d": 0.02, "sun": Color("e8ecf0"), "sun_e": 0.85, "amb": Color("8a9898"), "amb_e": 0.85, "weather": "rain", "tree": "mangrove", "decor": "reed"},
	"tushan": {"g1": Color("7a6a4a"), "g2": Color("86764e"), "path": Color("c8b090"), "wall": Color("4a3a2a"), "water": Color("ff9a40"), "bg": Color("140a06"),
		"sky_top": Color("6a7a98"), "sky_hor": Color("e8c8a0"), "fog": Color("c8a888"), "fog_d": 0.017, "sun": Color("ffe0b8"), "sun_e": 1.0, "amb": Color("a89078"), "amb_e": 0.85, "weather": "sparks", "tree": "furnace", "decor": "ingot"},
	"buzhou": {"g1": Color("4a5658"), "g2": Color("56625e"), "path": Color("9aa0a0"), "wall": Color("2a3438"), "water": Color("1e2e40"), "bg": Color("06080c"),
		"sky_top": Color("1a2438"), "sky_hor": Color("6a7890"), "fog": Color("5a6878"), "fog_d": 0.022, "sun": Color("d0d8e8"), "sun_e": 0.8, "amb": Color("6a7888"), "amb_e": 0.8, "weather": "rain", "tree": "crag", "decor": "pebble"},
	# ---- Part XI: the bright high air of the Level Heaven over a sea of cloud, the violet-and-gold
	# dusk at the Gate of Heaven, the teal glow of the caverns under the roots (lit red from the east
	# by the Torch Dragon's eye) and the ghost-fire of the Dark Capital
	"juntian": {"g1": Color("8ac0a0"), "g2": Color("9ad0b0"), "path": Color("f4ecd8"), "wall": Color("5a9a80"), "water": Color("d8ecff"), "bg": Color("142848"),
		"sky_top": Color("2a68d8"), "sky_hor": Color("f4f8ff"), "fog": Color("e4ecf8"), "fog_d": 0.01, "sun": Color("fffaf0"), "sun_e": 1.2, "amb": Color("c0d4f0"), "amb_e": 0.9, "weather": "clouds", "tree": "floatisle", "decor": "cloudpuff"},
	"changhe": {"g1": Color("a8a0c8"), "g2": Color("b8b0d4"), "path": Color("f4e4b8"), "wall": Color("8a7ab8"), "water": Color("e0d8ff"), "bg": Color("1a1430"),
		"sky_top": Color("4a3a98"), "sky_hor": Color("ffd8a0"), "fog": Color("e8d0d8"), "fog_d": 0.012, "sun": Color("fff0c8"), "sun_e": 1.05, "amb": Color("c8b8e0"), "amb_e": 0.85, "weather": "light", "tree": "jadepillar", "decor": "cloudpuff"},
	"ninesprings": {"g1": Color("2a4a48"), "g2": Color("325450"), "path": Color("6a8a80"), "wall": Color("1a3a38"), "water": Color("1a4a5a"), "bg": Color("020808"),
		"sky_top": Color("040a0c"), "sky_hor": Color("1a3a3a"), "fog": Color("143032"), "fog_d": 0.022, "sun": Color("ffa070"), "sun_e": 0.8, "amb": Color("5a8a88"), "amb_e": 0.85, "weather": "spores", "tree": "glowcap", "decor": "sporecap"},
	"youdu": {"g1": Color("2e3240"), "g2": Color("363a4a"), "path": Color("7a7e90"), "wall": Color("22263a"), "water": Color("3a6aa8"), "bg": Color("030308"),
		"sky_top": Color("05050c"), "sky_hor": Color("1e2440"), "fog": Color("1a1e30"), "fog_d": 0.02, "sun": Color("a0b0ff"), "sun_e": 0.75, "amb": Color("6a74a0"), "amb_e": 0.8, "weather": "ghostfire", "tree": "ghostpagoda", "decor": "ghostcandle"},
	# ---- Part XII: the pearl-white cliffs and blue tiles of Penglai in a haze of mirage, the herb
	# terraces and cold furnaces of Fangzhang in golden afternoon, the grey-green mists of Yingzhou, and
	# the bare sea floor at the lip of the Returning Ruins under a darkening violet sky
	"penglai": {"g1": Color("8ab89a"), "g2": Color("9ac6a6"), "path": Color("f0e4c8"), "wall": Color("4a8a7a"), "water": Color("4aa8c0"), "bg": Color("0c2030"),
		"sky_top": Color("3a7ac8"), "sky_hor": Color("f8e8d8"), "fog": Color("e8e0e0"), "fog_d": 0.014, "sun": Color("fff4e0"), "sun_e": 1.15, "amb": Color("b0c8d8"), "amb_e": 0.9, "weather": "light", "tree": "column", "decor": "shell"},
	"fangzhang": {"g1": Color("8aa860"), "g2": Color("98b46a"), "path": Color("e8d8a8"), "wall": Color("4a7a3a"), "water": Color("5ab0a8"), "bg": Color("101a0c"),
		"sky_top": Color("5a8ad0"), "sky_hor": Color("ffe8b0"), "fog": Color("f0e0b8"), "fog_d": 0.012, "sun": Color("fff0c0"), "sun_e": 1.2, "amb": Color("c8c8a0"), "amb_e": 0.9, "weather": "petals", "tree": "jadepeach", "decor": "flower"},
	"yingzhou": {"g1": Color("6a8a7a"), "g2": Color("769684"), "path": Color("c8ccc0"), "wall": Color("3a5a50"), "water": Color("4a7a8a"), "bg": Color("0a1414"),
		"sky_top": Color("6a7a88"), "sky_hor": Color("dce4e4"), "fog": Color("c8d4d4"), "fog_d": 0.03, "sun": Color("e8f0f0"), "sun_e": 0.85, "amb": Color("98aaa8"), "amb_e": 0.9, "weather": "clouds", "tree": "crag", "decor": "pebble"},
	"guixu": {"g1": Color("8a8070"), "g2": Color("968c7a"), "path": Color("c8b890"), "wall": Color("4a5a5a"), "water": Color("1a3a6a"), "bg": Color("06060e"),
		"sky_top": Color("1a1440"), "sky_hor": Color("c87a6a"), "fog": Color("7a6a78"), "fog_d": 0.018, "sun": Color("ffc8a0"), "sun_e": 0.95, "amb": Color("8a80a0"), "amb_e": 0.85, "weather": "rain", "tree": "coral", "decor": "shell"},
}

## terrain extras per theme: hill amplitude, ground texture style, tuft kind, horizon silhouette,
## sky features (stars / aurora / cloud cover)
const EXTRA := {
	"sect": {"hill": 0.35, "tex": "grass", "tuft": "grass", "horizon": "peaks", "clouds": 0.55},
	"bamboo": {"hill": 0.55, "tex": "grass", "tuft": "grass", "horizon": "peaks", "clouds": 0.4},
	"marsh": {"hill": 0.3, "tex": "mud", "tuft": "reed", "horizon": "hills", "clouds": 0.8},
	"frost": {"hill": 0.7, "tex": "snow", "tuft": "snow", "horizon": "glacier", "clouds": 0.5, "aurora": 1.0},
	"thunder": {"hill": 0.8, "tex": "rock", "tuft": "pebble", "horizon": "crags", "clouds": 0.95},
	"palace": {"hill": 0.4, "tex": "tile", "tuft": "none", "horizon": "towers", "clouds": 0.7, "stars": 0.6},
	"abyss": {"hill": 0.5, "tex": "sand", "tuft": "kelp", "horizon": "reef", "clouds": 0.0},
	"volcano": {"hill": 0.9, "tex": "ash", "tuft": "ash", "horizon": "volcano", "clouds": 0.7},
	"void": {"hill": 0.6, "tex": "crystal", "tuft": "crystal", "horizon": "islands", "clouds": 0.1, "stars": 1.0, "aurora": 0.6},
	"celestial": {"hill": 0.2, "tex": "marble", "tuft": "none", "horizon": "palace", "clouds": 0.7},
	"mirror": {"hill": 0.25, "tex": "glass", "tuft": "grass", "horizon": "peaks", "clouds": 0.4, "stars": 0.3},
	"grave": {"hill": 0.45, "tex": "mud", "tuft": "deadgrass", "horizon": "hills", "clouds": 0.85, "stars": 0.5},
	"time": {"hill": 0.6, "tex": "sand", "tuft": "deadgrass", "horizon": "dunes", "clouds": 0.3},
	"origin": {"hill": 0.3, "tex": "marble", "tuft": "crystal", "horizon": "islands", "clouds": 0.6, "stars": 0.4, "aurora": 0.5},
	"cloudsea": {"hill": 0.5, "tex": "grass", "tuft": "grass", "horizon": "islands", "clouds": 0.9},
	"court": {"hill": 0.2, "tex": "tile", "tuft": "grass", "horizon": "palace", "clouds": 0.5, "stars": 0.7},
	"forge": {"hill": 0.6, "tex": "rock", "tuft": "ash", "horizon": "volcano", "clouds": 0.6},
	"garden": {"hill": 0.45, "tex": "grass", "tuft": "flowers", "horizon": "peaks", "clouds": 0.5},
	"dunes": {"hill": 0.95, "tex": "sand", "tuft": "dunegrass", "horizon": "pillars", "clouds": 0.15, "haze": 0.8, "rays": 0.6},
	"fungal": {"hill": 0.45, "tex": "moss", "tuft": "moss", "horizon": "mushrooms", "clouds": 0.3, "stars": 0.9, "moon": 0.8, "haze": 0.5},
	"aurora": {"hill": 0.6, "tex": "permafrost", "tuft": "snow", "horizon": "pillars", "clouds": 0.2, "stars": 1.0, "aurora": 1.6, "moon": 1.0},
	"chaos": {"hill": 0.5, "tex": "nebula", "tuft": "crystal", "horizon": "pillars", "clouds": 0.0, "stars": 1.0, "aurora": 0.6, "nebula": 1.0},
	"maple": {"hill": 0.9, "tex": "leaves", "tuft": "grass", "horizon": "maples", "clouds": 0.5, "rays": 0.5, "haze": 0.4},
	"karst": {"hill": 0.55, "tex": "grass", "tuft": "grass", "horizon": "karst", "clouds": 0.7, "haze": 0.35},
	"lilies": {"hill": 0.35, "tex": "lilyfield", "tuft": "grass", "horizon": "bridge", "clouds": 0.4, "stars": 0.5, "moon": 0.7, "haze": 0.6, "rays": 0.4},
	"diyu": {"hill": 0.4, "tex": "underworld", "tuft": "crystal", "horizon": "wheel", "clouds": 0.0, "stars": 0.4, "haze": 0.5},
	"village": {"hill": 0.35, "tex": "grass", "tuft": "grass", "horizon": "peaks", "clouds": 0.55, "rays": 0.4},
	"tea": {"hill": 1.3, "tex": "grass", "tuft": "grass", "horizon": "karst", "clouds": 0.6, "haze": 0.45},
	"silk": {"hill": 0.6, "tex": "leaves", "tuft": "grass", "horizon": "hills", "clouds": 0.4, "rays": 0.6, "haze": 0.3},
	"loom": {"hill": 0.4, "tex": "marble", "tuft": "flowers", "horizon": "palace", "clouds": 0.5, "stars": 0.6, "aurora": 0.5},
	"starferry": {"hill": 0.3, "tex": "grass", "tuft": "grass", "horizon": "hills", "clouds": 0.3, "stars": 1.0, "moon": 0.9, "haze": 0.5},
	"magpie": {"hill": 1.4, "tex": "grass", "tuft": "grass", "horizon": "karst", "clouds": 0.9, "haze": 0.4, "rays": 0.4},
	"starpalace": {"hill": 0.4, "tex": "marble", "tuft": "flowers", "horizon": "palace", "clouds": 0.3, "stars": 1.0, "aurora": 0.4, "nebula": 0.5},
	"jasper": {"hill": 0.9, "tex": "grass", "tuft": "flowers", "horizon": "peaks", "clouds": 0.6, "rays": 0.6, "haze": 0.3},
	# sun_pitch / sun_yaw: where the light comes from (default -46, -35).  In the east the sun hangs
	# high over the Fusang; on the moon the light is low silver moonlight from the west
	"yanggu": {"hill": 0.25, "tex": "sand", "tuft": "deadgrass", "horizon": "hills", "clouds": 0.08, "rays": 0.9, "haze": 0.6, "sun_pitch": -64.0, "sun_yaw": 75.0},
	"millet": {"hill": 0.2, "tex": "cracked", "tuft": "deadgrass", "horizon": "dunes", "clouds": 0.05, "rays": 0.6, "haze": 0.95, "sun_pitch": -62.0, "sun_yaw": 80.0},
	"fusang": {"hill": 1.5, "tex": "grass", "tuft": "grass", "horizon": "karst", "clouds": 0.35, "rays": 1.0, "haze": 0.55, "sun_pitch": -38.0, "sun_yaw": 90.0},
	"guanghan": {"hill": 0.5, "tex": "permafrost", "tuft": "snow", "horizon": "palace", "clouds": 0.15, "stars": 1.0, "moon": 1.0, "haze": 0.3, "sun_pitch": -32.0, "sun_yaw": -100.0},
	"longmen": {"hill": 1.1, "tex": "grass", "tuft": "grass", "horizon": "karst", "clouds": 0.5, "haze": 0.45, "rays": 0.5},
	"drowned": {"hill": 0.25, "tex": "mud", "tuft": "reed", "horizon": "hills", "clouds": 0.9, "haze": 0.5},
	"tushan": {"hill": 1.2, "tex": "rock", "tuft": "grass", "horizon": "peaks", "clouds": 0.5, "haze": 0.5, "rays": 0.4},
	"buzhou": {"hill": 1.0, "tex": "rock", "tuft": "pebble", "horizon": "crags", "clouds": 0.95, "haze": 0.4},
	"juntian": {"hill": 0.5, "tex": "grass", "tuft": "grass", "horizon": "islands", "clouds": 0.75, "rays": 0.5, "sun_pitch": -52.0},
	"changhe": {"hill": 0.45, "tex": "marble", "tuft": "flowers", "horizon": "palace", "clouds": 0.6, "stars": 0.4, "rays": 0.6, "sun_pitch": -24.0, "sun_yaw": -70.0},
	"ninesprings": {"hill": 0.6, "tex": "moss", "tuft": "moss", "horizon": "mushrooms", "clouds": 0.0, "stars": 0.8, "haze": 0.6, "sun_pitch": -30.0, "sun_yaw": 90.0},
	"youdu": {"hill": 0.35, "tex": "underworld", "tuft": "crystal", "horizon": "towers", "clouds": 0.0, "stars": 0.5, "haze": 0.5},
	"penglai": {"hill": 0.45, "tex": "grass", "tuft": "grass", "horizon": "palace", "clouds": 0.45, "rays": 0.7, "haze": 0.55, "sun_pitch": -40.0, "sun_yaw": 80.0},
	"fangzhang": {"hill": 0.6, "tex": "grass", "tuft": "flowers", "horizon": "karst", "clouds": 0.4, "rays": 0.6, "haze": 0.35, "sun_pitch": -34.0},
	"yingzhou": {"hill": 0.7, "tex": "rock", "tuft": "grass", "horizon": "karst", "clouds": 0.9, "haze": 0.9},
	"guixu": {"hill": 0.55, "tex": "sand", "tuft": "kelp", "horizon": "reef", "clouds": 0.3, "stars": 0.6, "haze": 0.4, "sun_pitch": -18.0, "sun_yaw": -90.0},
}

const PICKUP_COLORS := {
	"thunder_bamboo": Color("7ac85a"), "peach_charm": Color("e05a4a"), "plum_sprig": Color("f4a6c4"),
	"thunder_egg": Color("9ab0e8"), "willow_sprig": Color("9ae070"), "spring_tea": Color("b8e07a"),
	"apricot_wood": Color("e0a060"), "argal": Color("b8a070"),
	# Part XIX: the carpenters' wood, and the pieces the Player shed
	"catalpa_timber": Color("d8b070"), "player_part": Color("f0e8d8"),
	# Part XXI: an unasked blank, a bamboo switch, a spent arrow, an empty hilt, a tally, a name-tablet
	"sword_blank": Color("5a5e6a"), "bamboo_switch": Color("7ac060"), "spent_arrow": Color("e8dcc0"), "old_hilt": Color("b89a50"), "challenge_tally": Color("c8a070"), "saint_tablet": Color("d8d0b8"),
	# Part XXII: road salt, the Earl's knotted cords, a scholar's farewells and the kings' jade slips
	"cast_shoe": Color("8a8a94"), "bore_shell": Color("f0d8c8"), "chain_link": Color("4a4a52"), "muster_slip": Color("e8dcc0"),
	"bell_shard": Color("d8c060"), "tiger_tally": Color("c8a050"), "pitch_pipe": Color("c8d080"), "chu_banner": Color("c84a3a"), "clay_duck": Color("f0d040"),
	"salt_bag": Color("e8e4dc"), "wind_knot": Color("9aa8b8"), "thrown_letter": Color("f0e8d0"), "merit_slip": Color("d8ecd8"),
	# Part XX: stone-milk, a basket of the mountain, a miner's lamp, a rubbing from a cave wall
	"stone_milk": Color("f0f4f8"), "earth_basket": Color("b89858"), "miner_lamp": Color("ffc860"), "cave_rubbing": Color("3a3a44"),
	"herb": Color("6fe08a"), "lotus": Color("ff7aa8"), "jade": Color("7affe0"), "shard": Color("f6e85c"), "pearl": Color("e8f4ff"),
	"ember": Color("ff8a3a"), "star": Color("c8a0ff"), "sigil": Color("ffe890"),
	"echo": Color("9ae8ff"), "relic": Color("d8e0f0"), "sand": Color("ffd060"), "rune": Color("ffb0f0"),
	"feather_cloud": Color("f0f8ff"), "seal": Color("60f0b0"), "ingot": Color("ffc860"), "peach": Color("ffa0b0"),
	"fallen_star": Color("fff4b0"), "glowcap": Color("ff9a50"), "aurora_shard": Color("70ffc8"), "five_stone": Color("ff70d0"),
	"soul_lantern": Color("ffc860"), "memory_pearl": Color("c0f0ff"), "forget_herb": Color("e8d090"), "wheel_spoke": Color("b0b8ff"), "silver_thread": Color("e8e8ff"), "tea_bud": Color("8ae060"), "cocoon": Color("fff4d8"), "shuttle": Color("e8c860"), "needle": Color("c8d0e0"),
	"river_star": Color("fff4c0"), "magpie_plume": Color("e8f0ff"), "star_thread": Color("c8d0ff"), "kunlun_peach": Color("ffa8b8"), "magpie_badge": Color("2a2a3a"),
	"noon_ember": Color("ff9a30"), "rain_stone": Color("8ab8e8"), "sun_feather": Color("ffd040"), "osmanthus": Color("ffd070"), "tenth_arrow": Color("c8a878"),
	"carp_scale": Color("ffc840"), "xirang": Color("c8a060"), "cauldron_shard": Color("d89a4a"), "pillar_stone": Color("8a9ab8"), "river_tablet": Color("a8c0a0"), "cauldron_map": Color("d8b070"),
	"wind_bell": Color("c8e0ff"), "gate_key": Color("f0d070"), "spring_water": Color("70e8f0"), "soul_tally": Color("c8b8e8"),
	"heaven_tablet": Color("b0f0d0"), "earth_weight": Color("8a7a6a"),
	"wutong_seed": Color("c8a050"), "night_pearl": Color("e8f8ff"), "peach_wine": Color("ffa0b8"), "moon_lotus": Color("f0e8ff"), "autumn_leaf": Color("e85a2a"), "ancestor_incense": Color("d8c090"), "stones": Color("90ffd0"),
	"name_slip": Color("e8d8a0"), "pearl_dew": Color("e8fff8"), "jingwei_stone": Color("d87a5a"), "xufu_log": Color("d8c8a8"), "mainland_earth": Color("a87a4a"), "cloud_tea": Color("7ac87a"),
}

static var _anime := {}
static var _sky_shader: Shader = null

## Anime grade: lift every colour into a bright, clean pastel range, but keep the ground calmer than
## the sky so characters stay readable against it.
static func _pop(c: Color, s_min: float, s_max: float, v_min: float, v_max: float, s_mul: float = 1.15) -> Color:
	var h := c.h
	var sat := clampf(c.s * s_mul + 0.04, s_min, s_max)
	var val := clampf(c.v * 1.08 + 0.04, v_min, v_max)
	return Color.from_hsv(h, sat, val, c.a)

static func theme(name: String) -> Dictionary:
	if _anime.has(name):
		return _anime[name]
	var th: Dictionary = THEMES.get(name, THEMES.bamboo).duplicate()
	var raw_g1: Color = th.g1
	for k in ["g1", "g2"]:
		th[k] = _pop(th[k], 0.22, 0.44, 0.42, 0.6, 1.05)
	th["path"] = _pop(th.path, 0.16, 0.42, 0.56, 0.78)
	th["wall"] = _pop(th.wall, 0.35, 0.72, 0.38, 0.74, 1.2)
	th["water"] = _pop(th.water, 0.45, 0.8, 0.5, 0.85, 1.15)
	th["sky_top"] = _pop(th.sky_top, 0.45, 0.8, 0.4, 0.82, 1.2)
	th["sky_hor"] = _pop(th.sky_hor, 0.2, 0.55, 0.78, 0.95, 1.0)
	th["fog"] = th.sky_hor.lerp(th.g2, 0.25)
	# clear air: fog only hints at distance instead of veiling the whole view
	th["fog_d"] = th.fog_d * 0.3
	th["amb"] = th.amb.lerp(Color(0.85, 0.9, 1.0), 0.35)
	th["amb_e"] = clampf(th.amb_e, 0.5, 0.62)
	th["sun"] = th.sun.lerp(Color(1.0, 0.93, 0.82), 0.4)
	th["sun_e"] = clampf(th.sun_e, 0.85, 0.95)
	th["g_dark"] = raw_g1.darkened(0.2)
	var ex: Dictionary = EXTRA.get(name, EXTRA.bamboo)
	for k in ex:
		th[k] = ex[k]
	for k2 in ["stars", "aurora", "nebula", "moon", "haze", "rays"]:
		if not th.has(k2):
			th[k2] = 0.0
	_anime[name] = th
	return th

# ---------------------------------------------------------------- sky
const SKY := """
shader_type sky;
uniform vec3 top : source_color = vec3(0.2, 0.35, 0.7);
uniform vec3 hor : source_color = vec3(0.8, 0.75, 0.9);
uniform vec3 ground : source_color = vec3(0.3, 0.3, 0.35);
uniform vec3 sun_col : source_color = vec3(1.0, 0.95, 0.85);
uniform float clouds = 0.5;
uniform float stars = 0.0;
uniform float aurora = 0.0;
uniform float sun_size = 0.035;
uniform float nebula = 0.0;
uniform float moon = 0.0;
uniform float haze = 0.0;
uniform float rays = 0.0;
// the Living Land release: at night the light in the sky is the moon (clock.gd)
uniform float night = 0.0;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int k = 0; k < 5; k++) {
		s += n2(p) * a;
		p = p * 2.02 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

void sky() {
	vec3 d = EYEDIR;
	float y = d.y;
	// layered gradient: horizon band, zenith, and a darker ground below the horizon
	float up = clamp(y, 0.0, 1.0);
	vec3 col = mix(hor, top, pow(up, 0.55));
	col = mix(col, hor * 1.08, exp(-abs(y) * 28.0) * 0.6);
	if (y < 0.0) {
		col = mix(hor * 0.9, ground, clamp(-y * 3.0, 0.0, 1.0));
	}
	// sun disc and halo
	vec3 sd = normalize(LIGHT0_DIRECTION);
	float sdot = dot(d, sd);
	float disc = smoothstep(1.0 - sun_size * 0.03, 1.0 - sun_size * 0.02, sdot);
	float halo = pow(max(sdot, 0.0), 180.0) * 0.6 + pow(max(sdot, 0.0), 12.0) * 0.18;
	vec3 dcol = sun_col;
	if (night > 0.0) {
		// a pale moon with soft grey seas, a small cold halo, and brighter than its light would say
		vec2 mp2 = (d - sd).xz * 95.0;
		dcol = mix(sun_col, vec3(0.93, 0.95, 1.0) * (0.7 + 0.3 * n2(mp2 * 1.2 + 3.0)), night);
		halo *= 1.0 - 0.7 * night;
		disc *= 1.0 + 2.2 * night;
	}
	col += (dcol * disc * 2.5 + sun_col * halo) * LIGHT0_ENERGY;
	// god rays: soft radial streaks fanning out from the sun
	if (rays > 0.0) {
		vec3 rx = normalize(cross(sd, vec3(0.0, 1.0, 0.0)));
		vec3 ry = cross(rx, sd);
		float ang = atan(dot(d, ry), dot(d, rx));
		float streak = 0.5 + 0.5 * sin(ang * 23.0 + sin(ang * 7.0 + TIME * 0.1) * 2.0);
		col += sun_col * pow(max(sdot, 0.0), 6.0) * streak * rays * 0.35 * LIGHT0_ENERGY;
	}
	// nebula: slow swirls of every colour (the Primordial Chaos)
	if (nebula > 0.0) {
		vec2 np = d.xz / (abs(y) + 0.3) * 0.9;
		float sw = fbm(np + vec2(fbm(np * 1.3 + TIME * 0.01), fbm(np * 1.7 - TIME * 0.012)) * 2.5);
		vec3 ncol = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + sw * 1.6 + TIME * 0.01));
		float nm = smoothstep(0.35, 0.85, sw) * (0.55 + 0.45 * smoothstep(-0.2, 0.6, y));
		col = mix(col, col * 0.4 + ncol * 0.75, nm * nebula * 0.8);
		col += ncol * pow(fbm(np * 4.0), 6.0) * nebula * 0.6;
	}
	// a pale moon opposite the sun, with soft maria
	if (moon > 0.0) {
		vec3 md = normalize(vec3(-sd.x, abs(sd.y) * 0.6 + 0.35, -sd.z));
		float mdot = dot(d, md);
		float mdisc = smoothstep(0.9991, 0.9994, mdot);
		vec2 mp = (d - md).xz * 60.0;
		float maria = 0.75 + 0.25 * n2(mp * 1.5);
		col = mix(col, vec3(0.95, 0.96, 1.0) * maria, mdisc * moon);
		col += vec3(0.6, 0.7, 1.0) * pow(max(mdot, 0.0), 300.0) * 0.5 * moon;
	}
	// stars (only on the upper dome, faded by cloud cover)
	if (stars > 0.0 && y > 0.0) {
		vec2 sp = d.xz / (y + 0.35) * 160.0;
		vec2 cell = floor(sp);
		float r = h21(cell);
		vec2 cp = fract(sp) - 0.5 - (vec2(h21(cell + 3.1), h21(cell + 7.7)) - 0.5) * 0.6;
		float tw = 0.6 + 0.4 * sin(TIME * (1.0 + r * 3.0) + r * 40.0);
		float st = smoothstep(0.09, 0.0, length(cp)) * step(0.88, r) * tw;
		col += vec3(0.9, 0.92, 1.0) * st * stars * smoothstep(0.0, 0.25, y);
	}
	// aurora ribbons
	if (aurora > 0.0 && y > 0.05) {
		vec2 ap = d.xz / (y + 0.2);
		float band = sin(ap.x * 1.8 + fbm(ap * 0.8 + TIME * 0.05) * 6.0);
		float a = smoothstep(0.75, 1.0, band) * smoothstep(0.05, 0.35, y) * smoothstep(0.9, 0.4, y);
		col += mix(vec3(0.2, 1.0, 0.6), vec3(0.6, 0.3, 1.0), fbm(ap + 4.0)) * a * aurora * 0.55;
	}
	// clouds on a virtual plane, drifting slowly
	if (clouds > 0.0 && y > 0.0) {
		vec2 cp = d.xz / (y + 0.12) * 1.4 + vec2(TIME * 0.012, TIME * 0.004);
		float cn = fbm(cp);
		float cov = smoothstep(1.0 - clouds * 0.62, 1.0 - clouds * 0.62 + 0.28, cn);
		float lit = clamp(fbm(cp + sd.xz * 0.15) - cn + 0.55, 0.0, 1.0);
		vec3 ccol = mix(hor * 0.75 + vec3(0.06), mix(vec3(1.0), sun_col, 0.35) * 1.05, lit);
		col = mix(col, ccol, cov * smoothstep(0.0, 0.18, y) * 0.92);
	}
	// a high, thin layer of cirrus streaks above the cumulus, sheared by the wind
	if (clouds > 0.0 && y > 0.05) {
		vec2 hp = d.xz / (y + 0.05) * vec2(0.35, 1.6) + vec2(TIME * 0.02, 0.0);
		float ci = fbm(hp + vec2(fbm(hp * 0.5) * 2.0, 0.0));
		float cir = smoothstep(0.55, 0.85, ci) * smoothstep(0.05, 0.3, y) * clouds * 0.35;
		col = mix(col, mix(vec3(1.0), sun_col, 0.5), cir);
	}
	// sunset rim light: cloud edges facing a low sun glow warm
	if (clouds > 0.0 && y > 0.0 && sd.y < 0.35) {
		float low = smoothstep(0.35, 0.05, sd.y);
		col += sun_col * pow(max(sdot, 0.0), 4.0) * low * clouds * 0.25 * smoothstep(0.0, 0.2, y);
	}
	// low haze band hugging the horizon (desert dust, spore mist)
	if (haze > 0.0) {
		float hb = exp(-abs(y - 0.02) * 14.0) * (0.75 + 0.25 * fbm(d.xz * 3.0 + TIME * 0.02));
		col = mix(col, hor * 1.05, hb * haze * 0.3);
	}
	COLOR = col;
}
"""

static func sky_material(name: String) -> ShaderMaterial:
	var th := theme(name)
	if _sky_shader == null:
		_sky_shader = Shader.new()
		_sky_shader.code = SKY
	var m := ShaderMaterial.new()
	m.shader = _sky_shader
	m.set_shader_parameter("top", th.sky_top)
	m.set_shader_parameter("hor", th.sky_hor)
	m.set_shader_parameter("ground", th.fog.darkened(0.45))
	m.set_shader_parameter("sun_col", th.sun)
	m.set_shader_parameter("clouds", th.clouds)
	m.set_shader_parameter("stars", th.stars)
	m.set_shader_parameter("aurora", th.aurora)
	m.set_shader_parameter("nebula", th.nebula)
	m.set_shader_parameter("moon", th.moon)
	m.set_shader_parameter("haze", th.haze)
	m.set_shader_parameter("rays", th.rays)
	return m

# ---------------------------------------------------------------- the hours (the Living Land release)
## A theme's own colours are its day.  Dawn and dusk warm the horizon and the light, and night turns the
## sky deep blue, puts the moon and the stars in it and dims the land, all scaled by how much the place
## follows the sun (Clock.CYCLE).  Night is never black: the toon shading keeps people readable by
## moonlight, and the lanterns and windows glow (MB.set_night).
const NIGHT_TOP := Color(0.03, 0.045, 0.12)
const NIGHT_HOR := Color(0.13, 0.17, 0.33)
const NIGHT_FOG := Color(0.1, 0.13, 0.25)
const NIGHT_AMB := Color(0.52, 0.62, 1.0)
const MOON_COL := Color(0.74, 0.82, 1.0)
const DUSK_HOR := Color(1.0, 0.58, 0.4)
const DUSK_TOP := Color(0.34, 0.33, 0.62)
const DUSK_SUN := Color(1.0, 0.6, 0.34)
const DUSK_FOG := Color(0.98, 0.7, 0.55)

## Everything that changes with the hour for theme `name` at hour `h` (0..24): sky colours, fog,
## ambient light, the light in the sky (colour, energy, angles, whether it is the moon), stars, how
## dark it is (`night`) and the exposure.
static func at_hour(name: String, h: float) -> Dictionary:
	var th := theme(name)
	var k := float(Clock.CYCLE.get(name, 1.0))
	var night := (1.0 - Clock.daylight(h)) * k
	var gold := Clock.golden(h) * k
	var la: Array = Clock.light_angles(h)
	var moon: bool = la[3]
	var top: Color = (th.sky_top as Color).lerp(DUSK_TOP, gold * 0.5)
	top = top.lerp((th.sky_top as Color).darkened(0.75).lerp(NIGHT_TOP, 0.65), night)
	var hor: Color = (th.sky_hor as Color).lerp(DUSK_HOR, gold * 0.62)
	hor = hor.lerp((th.sky_hor as Color).darkened(0.72).lerp(NIGHT_HOR, 0.6), night)
	var fog: Color = (th.fog as Color).lerp(DUSK_FOG, gold * 0.4).lerp(NIGHT_FOG, night * 0.85)
	var sun_c: Color = (th.sun as Color).lerp(DUSK_SUN, gold * 0.75)
	var sun_e: float = float(th.sun_e) * float(la[2])
	if moon:
		sun_c = MOON_COL
		sun_e = float(th.sun_e) * 0.42 * float(la[2])
	# a place half out of the sun's reach keeps some of its own light
	sun_c = (th.sun as Color).lerp(sun_c, k)
	sun_e = lerpf(float(th.sun_e), sun_e, k)
	var ex: Dictionary = EXTRA.get(name, {})
	var pitch: float = la[0]
	var yaw: float = la[1]
	if not moon and ex.has("sun_pitch"):
		# a sky with a sun of its own (the Fusang's high sun, the low light on the moon) keeps it by day
		pitch = float(ex.sun_pitch)
		yaw = float(ex.get("sun_yaw", yaw))
	# a little morning mist in the valleys
	var mist := smoothstep(4.5, 6.0, h) * (1.0 - smoothstep(7.0, 9.0, h)) * k
	return {"top": top, "hor": hor, "fog": fog, "amb": (th.amb as Color).lerp(NIGHT_AMB, night), "amb_e": lerpf(float(th.amb_e), 0.4, night),
		"sun": sun_c, "sun_e": sun_e, "pitch": pitch, "yaw": yaw, "moon": moon, "night": night, "gold": gold,
		"stars": maxf(float(th.stars), night * 0.95), "moon_disc": moon and float(th.moon) <= 0.0, "exposure": lerpf(1.05, 1.2, night),
		"fog_d": float(th.fog_d) * (1.0 + 1.6 * mist + 0.3 * night)}

## Apply the hour to an environment made by environment() and to its sun and fill lights.
static func apply_hour(env: Environment, s: DirectionalLight3D, f: DirectionalLight3D, name: String, h: float, fog_scale: float = 1.0) -> Dictionary:
	var lk := at_hour(name, h)
	if env != null and env.sky != null:
		var m := env.sky.sky_material as ShaderMaterial
		if m != null:
			m.set_shader_parameter("top", lk.top)
			m.set_shader_parameter("hor", lk.hor)
			m.set_shader_parameter("ground", (lk.fog as Color).darkened(0.45))
			m.set_shader_parameter("sun_col", lk.sun)
			m.set_shader_parameter("stars", lk.stars)
			m.set_shader_parameter("night", float(lk.night) if lk.moon else 0.0)
			# a sky with a moon of its own (the moon's palace, the starry ferry) hides the light's disc at night
			m.set_shader_parameter("sun_size", 0.035 * (1.0 + 0.5 * float(lk.night)) if not lk.moon or lk.moon_disc else 0.0004)
	if env != null:
		env.fog_light_color = lk.fog
		env.fog_density = float(lk.fog_d) * fog_scale
		env.ambient_light_color = lk.amb
		env.ambient_light_energy = lk.amb_e
		env.tonemap_exposure = lk.exposure
	if s != null:
		s.light_color = lk.sun
		s.light_energy = lk.sun_e
		s.rotation_degrees = Vector3(lk.pitch, lk.yaw, 0.0)
	if f != null:
		var th := theme(name)
		f.light_color = Color(th.sky_top).lerp(Color(0.7, 0.8, 1.0), 0.5).lerp(MOON_COL, float(lk.night))
		f.light_energy = lerpf(0.28, 0.18, float(lk.night))
	return lk

## Build an Environment for a theme (sky, fog, ambient light, bloom, grade).
static func environment(name: String, fog_scale: float = 1.0) -> Environment:
	var th := theme(name)
	var env := Environment.new()
	var sky := Sky.new()
	sky.sky_material = sky_material(name)
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = th.amb
	env.ambient_light_energy = th.amb_e
	env.fog_enabled = true
	env.fog_light_color = th.fog
	env.fog_density = th.fog_d * fog_scale
	env.fog_sky_affect = 0.1
	env.fog_aerial_perspective = 0.0
	# low valley mist: fog that thickens below a height and thins above it (river gorges, marsh)
	if float(th.get("mist", 0.0)) > 0.0:
		env.fog_height = 0.6
		env.fog_height_density = float(th.mist) * fog_scale
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	# glow only on genuinely bright things (spells, lanterns, the sun), never as a veil over the
	# whole frame: a high threshold, additive blend and no wide blur levels
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_strength = 0.8
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 0.5)
	env.set_glow_level(2, 0.6)
	env.set_glow_level(3, 0.0)
	env.set_glow_level(4, 0.0)
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.12
	env.adjustment_brightness = 1.0
	return env

## The air in a cellar (Part XI): dark, close and warm, lit only by lanterns; no sky.
static func cellar_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.012, 0.01)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.7, 0.55)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.045, 0.035)
	env.fog_density = 0.02
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.05
	env.adjustment_contrast = 1.1
	return env

## Re-tint an existing environment (title and meditation screens use custom skies).
static func tint_sky(env: Environment, top: Color, hor: Color, fog: Color = Color(0, 0, 0, 0), stars: float = -1.0) -> void:
	var m := env.sky.sky_material as ShaderMaterial
	if m == null:
		return
	m.set_shader_parameter("top", top)
	m.set_shader_parameter("hor", hor)
	if stars >= 0.0:
		m.set_shader_parameter("stars", stars)
	if fog.a > 0.0:
		env.fog_light_color = fog

static func sun(name: String, shadows: bool = true) -> DirectionalLight3D:
	var th := theme(name)
	var l := DirectionalLight3D.new()
	l.light_color = th.sun
	l.light_energy = th.sun_e
	l.rotation_degrees = sun_angles(name)
	l.shadow_enabled = shadows and DisplayServer.get_name() != "headless"
	l.directional_shadow_max_distance = 55.0
	l.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	l.shadow_bias = 0.06
	l.shadow_normal_bias = 1.6
	l.shadow_blur = 1.5
	return l

## A soft cool fill light from the opposite side so shadowed faces never go flat.
static func fill(name: String) -> DirectionalLight3D:
	var th := theme(name)
	var l := DirectionalLight3D.new()
	l.light_color = Color(th.sky_top).lerp(Color(0.7, 0.8, 1.0), 0.5)
	l.light_energy = 0.28
	l.rotation_degrees = Vector3(-25, 150, 0)
	l.shadow_enabled = false
	l.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	return l

## Where a theme's light comes from (degrees): most regions share one afternoon sun; Part IX's
## eastern regions have it standing high over the Fusang and the moon has low light from the west.
static func sun_angles(name: String) -> Vector3:
	var ex: Dictionary = EXTRA.get(name, {})
	return Vector3(float(ex.get("sun_pitch", -46.0)), float(ex.get("sun_yaw", -35.0)), 0.0)

## Apply a theme's colours to an existing sun + fill pair.
static func apply_lights(name: String, s: DirectionalLight3D, f: DirectionalLight3D = null) -> void:
	var th := theme(name)
	s.light_color = th.sun
	s.light_energy = th.sun_e
	s.rotation_degrees = sun_angles(name)
	if f != null:
		f.light_color = Color(th.sky_top).lerp(Color(0.7, 0.8, 1.0), 0.5)
