class_name Look
extends RefCounted
## Per-region look: ground palette, sky, fog, lighting, weather and the kind of landmark that fills the map.
## g1/g2/path/wall/water/bg also colour the 2D minimap.

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
}

const PICKUP_COLORS := {
	"herb": Color("6fe08a"), "lotus": Color("ff7aa8"), "jade": Color("7affe0"), "shard": Color("f6e85c"), "pearl": Color("e8f4ff"),
	"ember": Color("ff8a3a"), "star": Color("c8a0ff"), "sigil": Color("ffe890"),
	"echo": Color("9ae8ff"), "relic": Color("d8e0f0"), "sand": Color("ffd060"), "rune": Color("ffb0f0"),
}

static var _anime := {}

## Gacha-anime grade: lift every colour into a bright, clean, saturated pastel range.
static func _pop(c: Color, s_min: float, s_max: float, v_min: float, v_max: float, s_mul: float = 1.15) -> Color:
	var h := c.h
	var sat := clampf(c.s * s_mul + 0.04, s_min, s_max)
	var val := clampf(c.v * 1.08 + 0.04, v_min, v_max)
	return Color.from_hsv(h, sat, val, c.a)

static func theme(name: String) -> Dictionary:
	if _anime.has(name):
		return _anime[name]
	var th: Dictionary = THEMES.get(name, THEMES.bamboo).duplicate()
	for k in ["g1", "g2"]:
		th[k] = _pop(th[k], 0.3, 0.52, 0.48, 0.66)
	th["path"] = _pop(th.path, 0.2, 0.5, 0.6, 0.82)
	th["wall"] = _pop(th.wall, 0.4, 0.8, 0.4, 0.78, 1.3)
	th["water"] = _pop(th.water, 0.5, 0.85, 0.5, 0.85, 1.2)
	th["sky_top"] = _pop(th.sky_top, 0.5, 0.85, 0.45, 0.85, 1.25)
	th["sky_hor"] = _pop(th.sky_hor, 0.25, 0.6, 0.78, 0.95, 1.0)
	th["fog"] = th.sky_hor.lerp(th.g2, 0.25)
	th["fog_d"] = th.fog_d * 0.7
	th["amb"] = th.amb.lerp(Color(0.85, 0.9, 1.0), 0.35)
	th["amb_e"] = clampf(th.amb_e, 0.5, 0.62)
	th["sun"] = th.sun.lerp(Color(1.0, 0.93, 0.82), 0.4)
	th["sun_e"] = clampf(th.sun_e, 0.8, 0.9)
	_anime[name] = th
	return th

## Build an Environment for a theme (sky, fog, ambient light).
static func environment(name: String, fog_scale: float = 1.0) -> Environment:
	var th := theme(name)
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = th.sky_top
	sm.sky_horizon_color = th.sky_hor
	sm.ground_horizon_color = th.sky_hor.darkened(0.2)
	sm.ground_bottom_color = th.fog.darkened(0.45)
	sm.sky_curve = 0.25
	sm.sun_angle_max = 25.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = th.amb
	env.ambient_light_energy = th.amb_e
	env.fog_enabled = true
	env.fog_light_color = th.fog
	env.fog_density = th.fog_d * fog_scale
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.06
	env.adjustment_brightness = 0.95
	return env

static func sun(name: String, shadows: bool = true) -> DirectionalLight3D:
	var th := theme(name)
	var l := DirectionalLight3D.new()
	l.light_color = th.sun
	l.light_energy = th.sun_e
	l.rotation_degrees = Vector3(-52, -35, 0)
	l.shadow_enabled = shadows and DisplayServer.get_name() != "headless"
	l.directional_shadow_max_distance = 60.0
	l.shadow_bias = 0.1
	l.shadow_normal_bias = 2.0
	return l
