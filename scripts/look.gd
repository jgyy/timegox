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
}

const PICKUP_COLORS := {
	"herb": Color("6fe08a"), "lotus": Color("ff7aa8"), "jade": Color("7affe0"), "shard": Color("f6e85c"), "pearl": Color("e8f4ff"),
	"ember": Color("ff8a3a"), "star": Color("c8a0ff"), "sigil": Color("ffe890"),
	"echo": Color("9ae8ff"), "relic": Color("d8e0f0"), "sand": Color("ffd060"), "rune": Color("ffb0f0"),
	"feather_cloud": Color("f0f8ff"), "seal": Color("60f0b0"), "ingot": Color("ffc860"), "peach": Color("ffa0b0"),
	"fallen_star": Color("fff4b0"), "glowcap": Color("ff9a50"), "aurora_shard": Color("70ffc8"), "five_stone": Color("ff70d0"),
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
	th["fog_d"] = th.fog_d * 0.7
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
	col += sun_col * (disc * 2.5 + halo) * LIGHT0_ENERGY;
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
	// low haze band hugging the horizon (desert dust, spore mist)
	if (haze > 0.0) {
		float hb = exp(-abs(y - 0.02) * 14.0) * (0.75 + 0.25 * fbm(d.xz * 3.0 + TIME * 0.02));
		col = mix(col, hor * 1.05, hb * haze * 0.6);
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
	env.fog_sky_affect = 0.25
	env.fog_aerial_perspective = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 0.9
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 0.6)
	env.set_glow_level(2, 1.0)
	env.set_glow_level(3, 0.6)
	env.set_glow_level(4, 0.3)
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.04
	env.adjustment_contrast = 1.08
	env.adjustment_brightness = 1.0
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
	l.rotation_degrees = Vector3(-46, -35, 0)
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

## Apply a theme's colours to an existing sun + fill pair.
static func apply_lights(name: String, s: DirectionalLight3D, f: DirectionalLight3D = null) -> void:
	var th := theme(name)
	s.light_color = th.sun
	s.light_energy = th.sun_e
	if f != null:
		f.light_color = Color(th.sky_top).lerp(Color(0.7, 0.8, 1.0), 0.5)
