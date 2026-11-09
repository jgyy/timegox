class_name Nature
extends RefCounted
## Shared look of living things in the landscape: foliage cards, grass, bark and the textures they use.
##
## Trees used to be a few solid blobs per region, stamped on every tile.  Now every canopy is made of
## many small "leaf cards": quads textured with a cluster of leaves that is painted here, pixel by
## pixel, from code (broad leaves, needles, maple stars, blossoms, willow strands, bamboo blades, fern
## fronds and more).  The card shader then gives them what solid blobs never had:
##   * alpha-cut silhouettes, so a canopy has a ragged, leafy outline and dappled shadows;
##   * "spherized" normals baked by Flora (pointing out of the canopy), so a whole crown is lit like
##     one soft volume instead of a pile of flat planes;
##   * translucency, so leaves glow when the sun is behind them;
##   * layered wind (a slow gust front that rolls across the map plus per-leaf flutter);
##   * per-instance colour from MultiMesh, so no two trees in a forest share exactly the same hue.
## Grass uses its own shader (root-to-tip gradient, dry and lush patches, gusts).  No image files are
## involved anywhere: every texture is generated when the game starts.

const LEAF_KINDS := ["broad", "needle", "maple", "blossom", "willow", "bamboo", "round", "frond", "snow", "crystal", "spore", "lily", "palm", "autumn", "ginkgo", "wisteria"]
const TEX := 128

static var _tex := {}
static var _mats := {}
static var _grass_mats := {}

# ---------------------------------------------------------------- shaders
const LEAF := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx, depth_draw_opaque;
uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float wind = 1.0;
uniform float translucency = 0.55;
uniform float cut = 0.42;
uniform float glow = 0.0;
uniform float bright = 1.75;
uniform float near_fade = 5.5;
global uniform vec3 hero_pos;
// the Living Land release (clock.gd): how dark it is; leaves lit by the sun stop glowing at night
global uniform float night_k;
uniform vec3 sun_tint : source_color = vec3(1.0, 0.96, 0.85);
varying vec3 wp;
varying float sway;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	sway = COLOR.a;
	// slow gust fronts roll across the whole map; leaves flutter on top of them
	float front = sin(dot(wp.xz, vec2(0.045, 0.03)) - TIME * 0.7) * 0.5 + 0.5;
	float gust = 0.35 + front * front * 0.9;
	float ph = wp.x * 0.37 + wp.z * 0.29 + wp.y * 0.5;
	float flutter = sin(TIME * 4.3 + ph * 3.1) * 0.35 + sin(TIME * 7.1 + ph * 5.3) * 0.15;
	vec3 push = vec3(sin(TIME * 1.1 + ph * 0.4), 0.0, cos(TIME * 0.9 + ph * 0.3) * 0.6);
	VERTEX += (push * gust * 0.09 + vec3(flutter * 0.025, flutter * 0.02, flutter * 0.02)) * sway * wind;
	COLOR.a = 1.0;
}

void fragment() {
	vec4 t = texture(leaf_tex, UV);
	// foliage right in front of the camera dissolves in a dither pattern, so a canopy beside the
	// road never blots out the hero
	float cam_d = -VERTEX.z;
	float keep = smoothstep(near_fade, near_fade + 2.5, cam_d);
	// ordered (Bayer) dither: an even screen-door pattern instead of noisy static
	int bx = int(mod(FRAGCOORD.x, 4.0));
	int by = int(mod(FRAGCOORD.y, 4.0));
	const float bay[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	float dth = (bay[bx + by * 4] + 0.5) / 16.0;
	// and so does any leaf between the follow camera and the hero
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 seg = hero_pos - cam;
	float l2 = max(dot(seg, seg), 0.001);
	float tt = dot(w - cam, seg) / l2;
	if (tt > 0.0 && tt < 0.97) {
		float dd = length(w - (cam + seg * tt));
		keep = min(keep, max(smoothstep(1.2, 2.6, dd), 1.0 - smoothstep(0.6, 1.4, (1.0 - tt) * sqrt(l2))));
	}
	if (keep < 0.999 && dth > keep) {
		discard;
	}
	// undo the back-face normal flip: a canopy is shaded as one volume, front or back
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec3 c = COLOR.rgb * t.rgb * bright * (1.0 - 0.3 * night_k);
	ALBEDO = c;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = cut;
	BACKLIGHT = c * sun_tint * translucency * (1.0 - 0.6 * night_k);
	ROUGHNESS = 0.75;
	SPECULAR = 0.25;
	EMISSION = c * glow * (0.7 + 0.3 * sin(TIME * 1.3 + wp.x * 0.7 + wp.z)) * (1.0 - 0.7 * night_k);
}
"""

## Grass blades: vertex alpha is the height along the blade (0 root, 1 tip).
const GRASS := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
uniform vec3 root_col : source_color = vec3(0.18, 0.32, 0.14);
uniform vec3 tip_col : source_color = vec3(0.62, 0.8, 0.38);
uniform vec3 dry_col : source_color = vec3(0.78, 0.72, 0.42);
uniform float dry = 0.25;
uniform float wind = 1.0;
uniform float glow = 0.0;
varying float hgt;
varying vec3 wp;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	hgt = COLOR.a;
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float front = sin(dot(wp.xz, vec2(0.06, 0.04)) - TIME * 0.9) * 0.5 + 0.5;
	float bend = hgt * hgt * (0.12 + 0.28 * front * front);
	float ph = wp.x * 0.8 + wp.z * 0.6;
	VERTEX.x += (sin(TIME * 2.2 + ph) * 0.35 + 0.65 * front) * bend * wind;
	VERTEX.z += cos(TIME * 1.7 + ph * 1.3) * bend * 0.5 * wind;
	VERTEX.y -= bend * 0.25 * wind;
	// soft grass lighting: normals lean up so a meadow shades like a carpet, not like cards
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.75));
}

// (and grass by night: no sunlit glow)
global uniform float night_k;

void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	float patchy = n2(wp.xz * 0.11) * 0.65 + n2(wp.xz * 0.37) * 0.35;
	vec3 tip = mix(tip_col, dry_col, smoothstep(1.0 - dry, 1.15 - dry * 0.6, patchy));
	vec3 c = mix(root_col, tip, smoothstep(0.0, 1.0, hgt)) * COLOR.rgb;
	c *= 0.92 + 0.16 * h21(floor(wp.xz * 9.0));
	ALBEDO = c;
	BACKLIGHT = c * 0.45 * hgt * (1.0 - 0.6 * night_k);
	ROUGHNESS = 0.9;
	EMISSION = c * glow * hgt * (1.0 - 0.7 * night_k);
}
"""

# ---------------------------------------------------------------- materials
static func headless() -> bool:
	return DisplayServer.get_name() == "headless"

## Card material for one kind of leaf texture.  `glow` makes it faintly emissive (spores, crystal).
static func leaf_mat(kind: String, glow: float = 0.0) -> ShaderMaterial:
	var key := "%s_%.2f" % [kind, glow]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = MB._shader(LEAF)
	if not headless():
		m.set_shader_parameter("leaf_tex", leaf_tex(kind))
	m.set_shader_parameter("glow", glow)
	# textures that carry their own colours are not brightened (they would bloom out)
	m.set_shader_parameter("bright", 1.0 if kind in ["blossom", "lily", "crystal", "wisteria"] else 1.75)
	m.set_shader_parameter("translucency", 0.75 if kind in ["blossom", "maple", "autumn", "willow", "bamboo"] else 0.55)
	m.set_shader_parameter("cut", 0.36 if kind in ["needle", "willow", "snow"] else 0.42)
	_mats[key] = m
	return m

## Grass material per region: root/tip/dry colours follow the region's ground palette.
static func grass_mat(theme_name: String) -> ShaderMaterial:
	if _grass_mats.has(theme_name):
		return _grass_mats[theme_name]
	var th := Look.theme(theme_name)
	var m := ShaderMaterial.new()
	m.shader = MB._shader(GRASS)
	var g1: Color = th.g1
	var g2: Color = th.g2
	var base := g1.darkened(0.5)
	var tip := Color.from_hsv(g2.h, minf(g2.s * 1.35 + 0.08, 1.0), minf(g2.v * 1.12, 1.0))
	var dry := tip.lerp(Color("c8b070"), 0.55)
	var dryness := 0.25
	var glow := 0.0
	match str(th.get("tuft", "grass")):
		"deadgrass", "dunegrass":
			dryness = 0.75
			tip = Color(th.path).lerp(Color("c8b070"), 0.5)
		"snow":
			tip = Color("e8f0f8")
			base = Color(th.g1).darkened(0.3)
			dry = Color("ffffff")
		"moss":
			glow = 0.35
			tip = Color(th.wall).lerp(Color("70ffd0"), 0.4)
		"crystal":
			glow = 0.3
			tip = Color(th.wall).lightened(0.3)
		"flowers":
			dryness = 0.1
	match theme_name:
		"maple":
			dryness = 0.55
			dry = Color("e0a050")
		"lilies":
			dryness = 0.35
			dry = Color("c86040")
		"diyu":
			glow = 0.2
			tip = Color("70a0c0")
	m.set_shader_parameter("root_col", base)
	m.set_shader_parameter("tip_col", tip)
	m.set_shader_parameter("dry_col", dry)
	m.set_shader_parameter("dry", dryness)
	m.set_shader_parameter("glow", glow)
	_grass_mats[theme_name] = m
	return m

# ---------------------------------------------------------------- texture painting
## A leaf-cluster texture, painted once and cached.  RGB is a near-white shading map (the card's
## vertex colour supplies the hue) except for blossoms and lilies, which carry their own colours.
static func leaf_tex(kind: String) -> ImageTexture:
	if _tex.has(kind):
		return _tex[kind]
	var p := Painter.new(TEX)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) & 0x7fffffff
	match kind:
		"broad", "round", "autumn":
			_paint_cluster(p, rng, kind)
		"needle", "snow":
			_paint_needles(p, rng, kind == "snow")
		"maple":
			_paint_cluster(p, rng, "maple")
		"blossom":
			_paint_blossom(p, rng)
		"willow":
			_paint_strands(p, rng)
		"bamboo":
			_paint_bamboo(p, rng)
		"frond", "palm":
			_paint_frond(p, rng, kind == "palm")
		"crystal":
			_paint_shards(p, rng)
		"spore":
			_paint_spores(p, rng)
		"lily":
			_paint_lily(p, rng)
		"ginkgo":
			_paint_cluster(p, rng, "ginkgo")
		"wisteria":
			_paint_wisteria(p, rng)
		_:
			_paint_cluster(p, rng, "broad")
	var img := p.image()
	var t := ImageTexture.create_from_image(img)
	_tex[kind] = t
	return t

## Leaves radiating from the middle of the card along little twigs (deciduous canopies).
static func _paint_cluster(p: Painter, rng: RandomNumberGenerator, kind: String) -> void:
	var s := float(p.size)
	var c := Vector2(s * 0.5, s * 0.5)
	var twig := Color(0.45, 0.36, 0.3, 1.0)
	var n_twigs := 7
	var tips: Array = []
	for i in n_twigs:
		var a := TAU * i / n_twigs + rng.randf_range(-0.3, 0.3)
		var e := c + Vector2(cos(a), sin(a)) * s * rng.randf_range(0.28, 0.4)
		p.line(c, e, 2.2, twig)
		tips.append([e, a])
	var count := 70 if kind != "maple" else 34
	for i in count:
		var tw: Array = tips[rng.randi() % tips.size()]
		var along := rng.randf_range(0.2, 1.05)
		var base: Vector2 = c.lerp(tw[0], along)
		var a: float = tw[1] + rng.randf_range(-1.3, 1.3)
		var size := s * rng.randf_range(0.09, 0.14) * (1.25 if kind == "maple" else 1.0)
		var shade := rng.randf_range(0.72, 1.0) * lerpf(0.88, 1.0, along)
		var col := Color(shade, shade, shade)
		if kind == "autumn":
			col = Color(shade, shade * rng.randf_range(0.65, 1.0), shade * rng.randf_range(0.55, 0.8))
		var shape := "broad"
		if kind == "round":
			shape = "round"
		elif kind == "maple":
			shape = "maple"
		elif kind == "ginkgo":
			shape = "fan"
			col = Color(shade, shade * rng.randf_range(0.85, 1.0), shade * rng.randf_range(0.55, 0.75))
		p.leaf(base, a, size, size * (0.42 if shape == "broad" else 0.8), shape, col)

## Pine and fir sprays: a central twig with dense needles on both sides (optional snow on top).
static func _paint_needles(p: Painter, rng: RandomNumberGenerator, snowy: bool) -> void:
	var s := float(p.size)
	for k in 5:
		var a := -PI * 0.5 + (k - 2) * 0.45 + rng.randf_range(-0.1, 0.1)
		var root := Vector2(s * 0.5, s * 0.92)
		var tip := root + Vector2(cos(a), sin(a)) * s * rng.randf_range(0.62, 0.82)
		p.line(root, tip, 2.5, Color(0.42, 0.34, 0.28))
		var steps := 34
		for i in steps:
			var t := i / float(steps)
			var q := root.lerp(tip, t)
			var ln := s * 0.12 * (1.0 - t * 0.6)
			for sd: float in [-1.0, 1.0]:
				var na := a + sd * rng.randf_range(0.7, 1.1)
				var e := q + Vector2(cos(na), sin(na)) * ln
				var sh := rng.randf_range(0.7, 1.0)
				p.line(q, e, 1.5, Color(sh, sh, sh))
			if snowy and i % 3 == 0:
				p.blob(q + Vector2(0, -3), s * 0.035 * (1.0 - t * 0.5), Color(1.0, 1.0, 1.0))

## Blossoms with their own petal colours over a few leaves.
static func _paint_blossom(p: Painter, rng: RandomNumberGenerator) -> void:
	var s := float(p.size)
	var c := Vector2(s * 0.5, s * 0.5)
	for i in 6:
		var a := TAU * i / 6.0 + rng.randf_range(-0.2, 0.2)
		p.line(c, c + Vector2(cos(a), sin(a)) * s * 0.38, 2.4, Color(0.4, 0.3, 0.28))
	for i in 18:
		var a2 := rng.randf() * TAU
		var q := c + Vector2(cos(a2), sin(a2)) * s * rng.randf_range(0.08, 0.36)
		p.leaf(q, a2, s * 0.1, s * 0.045, "broad", Color(0.45, 0.62, 0.35))
	for i in 46:
		var a3 := rng.randf() * TAU
		var r := s * sqrt(rng.randf()) * 0.4
		var q2 := c + Vector2(cos(a3), sin(a3)) * r
		var pink := Color(1.0, rng.randf_range(0.72, 0.88), rng.randf_range(0.82, 0.92))
		if rng.randf() < 0.18:
			pink = Color(1.0, 0.96, 0.96)
		p.flower(q2, s * rng.randf_range(0.045, 0.065), pink, Color(1.0, 0.85, 0.45), rng.randf() * TAU)

## Long hanging willow strands (used on tall vertical cards).
static func _paint_strands(p: Painter, rng: RandomNumberGenerator) -> void:
	var sz := float(p.size)
	for k in 4:
		var x := sz * (0.14 + 0.24 * k) + rng.randf_range(-4, 4)
		var top := Vector2(x, 0)
		var bot := Vector2(x + rng.randf_range(-6, 6), sz * rng.randf_range(0.85, 1.0))
		p.line(top, bot, 1.2, Color(0.55, 0.5, 0.35))
		var n := 14
		for i in n:
			var t := (i + 0.5) / n
			var q := top.lerp(bot, t)
			var sd := 1.0 if i % 2 == 0 else -1.0
			var a := PI * 0.5 + sd * rng.randf_range(0.3, 0.55)
			var sh := rng.randf_range(0.75, 1.0)
			p.leaf(q, a, sz * 0.1, sz * 0.03, "broad", Color(sh, sh, sh * 0.95))

## Bamboo: slender lanceolate leaves fanning from a few twigs.
static func _paint_bamboo(p: Painter, rng: RandomNumberGenerator) -> void:
	var s := float(p.size)
	for k in 4:
		var root := Vector2(s * rng.randf_range(0.3, 0.7), s * rng.randf_range(0.55, 0.8))
		var a0 := -PI * 0.5 + rng.randf_range(-0.8, 0.8)
		var tip := root + Vector2(cos(a0), sin(a0)) * s * 0.35
		p.line(root, tip, 1.6, Color(0.6, 0.62, 0.4))
		for i in 7:
			var q := root.lerp(tip, (i + 1) / 8.0)
			var a := a0 + (1.0 if i % 2 == 0 else -1.0) * rng.randf_range(0.5, 1.2) + PI * 0.15
			var sh := rng.randf_range(0.75, 1.0)
			p.leaf(q, a, s * rng.randf_range(0.2, 0.28), s * 0.035, "lance", Color(sh, sh, sh))

## A pinnate frond (ferns and palms): a rib up the middle, leaflets shrinking towards the tip.
static func _paint_frond(p: Painter, rng: RandomNumberGenerator, palm: bool) -> void:
	var s := float(p.size)
	var root := Vector2(s * 0.5, s)
	var tip := Vector2(s * 0.5, 0)
	p.line(root, tip, 3.0 if palm else 2.0, Color(0.6, 0.55, 0.4))
	var n := 26 if palm else 22
	for i in n:
		var t := (i + 0.5) / n
		var q := root.lerp(tip, t)
		var ln := s * (0.46 if palm else 0.36) * sin(PI * (0.12 + t * 0.88)) * (1.0 - t * 0.35)
		for sd: float in [-1.0, 1.0]:
			var a := -PI * 0.5 + sd * (1.05 if palm else 1.2)
			var sh := rng.randf_range(0.78, 1.0)
			p.leaf(q, a, ln, s * (0.025 if palm else 0.035), "lance" if palm else "broad", Color(sh, sh, sh))

## Crystal shards for void and origin trees: hard-edged facets that glint.
static func _paint_shards(p: Painter, rng: RandomNumberGenerator) -> void:
	var s := float(p.size)
	var c := Vector2(s * 0.5, s * 0.55)
	for i in 26:
		var a := -PI * 0.5 + rng.randf_range(-1.4, 1.4)
		var q := c + Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.1, 0.25)) * s
		var sh := rng.randf_range(0.7, 1.3)
		p.leaf(q, a, s * rng.randf_range(0.12, 0.3), s * 0.05, "shard", Color(sh, sh, sh * 1.1))

## Glowing spore heads (fungal undergrowth).
static func _paint_spores(p: Painter, rng: RandomNumberGenerator) -> void:
	var s := float(p.size)
	for i in 40:
		var q := Vector2(rng.randf_range(0.12, 0.88), rng.randf_range(0.1, 0.9)) * s
		var r := s * rng.randf_range(0.02, 0.06)
		p.line(q, q + Vector2(0, r * 3.0), 1.2, Color(0.8, 0.8, 0.85))
		p.blob(q, r, Color(1.2, 1.2, 1.2))

## Red spider lilies: curled crimson petals and long stamens (Part VI's Yellow Springs).
static func _paint_lily(p: Painter, rng: RandomNumberGenerator) -> void:
	var s := float(p.size)
	for k in 3:
		var c := Vector2(s * (0.25 + 0.25 * k), s * rng.randf_range(0.28, 0.4))
		p.line(c, Vector2(c.x + rng.randf_range(-6, 6), s), 2.0, Color(0.35, 0.55, 0.3))
		for i in 6:
			var a := TAU * i / 6.0 + rng.randf_range(-0.2, 0.2)
			p.leaf(c, a, s * 0.11, s * 0.025, "lance", Color(1.0, 0.16, 0.12))
		for i in 7:
			var a2 := -PI * 0.5 + (i - 3) * 0.32
			var e := c + Vector2(cos(a2), sin(a2)) * s * 0.17
			p.line(c, e, 1.0, Color(1.0, 0.3, 0.25))
			p.blob(e, 2.2, Color(1.0, 0.85, 0.4))

## Wisteria: drooping racemes of violet pea-flowers, darker at the tips, on pale stems.
static func _paint_wisteria(p: Painter, rng: RandomNumberGenerator) -> void:
	var s := float(p.size)
	for k in 5:
		var x := s * (0.12 + 0.19 * k) + rng.randf_range(-5, 5)
		var top := Vector2(x, s * rng.randf_range(0.0, 0.08))
		var bot := Vector2(x + rng.randf_range(-6, 6), s * rng.randf_range(0.75, 0.98))
		p.line(top, bot, 1.0, Color(0.6, 0.7, 0.45))
		var n := 18
		for i in n:
			var t := (i + 0.5) / n
			var q := top.lerp(bot, t) + Vector2(rng.randf_range(-3, 3) * (1.0 - t * 0.5), 0)
			var r := s * 0.04 * (1.0 - t * 0.55)
			var c := Color(0.82, 0.7, 1.0).lerp(Color(0.5, 0.32, 0.8), t)
			p.blob(q, r, c)
		for j in 3:
			var lq := top.lerp(bot, rng.randf_range(0.0, 0.2))
			p.leaf(lq, rng.randf_range(-0.6, 0.6) + (0.0 if j % 2 == 0 else PI), s * 0.12, s * 0.03, "lance", Color(0.55, 0.75, 0.4))

## Small RGBA float canvas with anti-aliased stamps.  Painting into a float buffer keeps overlapping
## leaves blending properly; `image()` converts once at the end.
class Painter:
	var size: int
	var buf := PackedFloat32Array()

	func _init(sz: int) -> void:
		size = sz
		buf.resize(sz * sz * 4)
		buf.fill(0.0)

	func _put(x: int, y: int, col: Color, a: float) -> void:
		if x < 0 or y < 0 or x >= size or y >= size or a <= 0.0:
			return
		var i := (y * size + x) * 4
		var oa := buf[i + 3]
		buf[i] = lerpf(buf[i], col.r, a)
		buf[i + 1] = lerpf(buf[i + 1], col.g, a)
		buf[i + 2] = lerpf(buf[i + 2], col.b, a)
		buf[i + 3] = oa + (1.0 - oa) * a

	## anti-aliased thick line (twigs, stems, needles)
	func line(a: Vector2, b: Vector2, width: float, col: Color) -> void:
		var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * (width + 1.0)
		var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * (width + 1.0)
		var ab := b - a
		var l2 := maxf(ab.length_squared(), 0.0001)
		for y in range(int(lo.y), int(hi.y) + 1):
			for x in range(int(lo.x), int(hi.x) + 1):
				var pp := Vector2(x + 0.5, y + 0.5)
				var t := clampf((pp - a).dot(ab) / l2, 0.0, 1.0)
				var d := (pp - (a + ab * t)).length()
				var wd := width * 0.5 * (1.0 - t * 0.5)
				_put(x, y, col, clampf(wd - d + 0.5, 0.0, 1.0))

	## soft round dab (snow, spores, stamens)
	func blob(cn: Vector2, r: float, col: Color) -> void:
		for y in range(int(cn.y - r - 1), int(cn.y + r + 2)):
			for x in range(int(cn.x - r - 1), int(cn.x + r + 2)):
				var d := Vector2(x + 0.5, y + 0.5).distance_to(cn)
				var k := clampf(r - d + 0.5, 0.0, 1.0)
				var sh := 1.0 - 0.25 * clampf(d / maxf(r, 0.001), 0.0, 1.0)
				_put(x, y, Color(col.r * sh, col.g * sh, col.b * sh), k)

	## One leaf from `base` pointing along angle `a`.  Shapes: broad, lance, round, maple, shard.
	## Shading: a darker midrib, darker rim, lighter tip, so leaves read individually.
	func leaf(base: Vector2, a: float, length: float, width: float, shape: String, col: Color) -> void:
		var dir := Vector2(cos(a), sin(a))
		var side := Vector2(-dir.y, dir.x)
		var reach := maxf(length, width) + 2.0
		var cn := base + dir * length * 0.5
		for y in range(int(cn.y - reach), int(cn.y + reach) + 1):
			for x in range(int(cn.x - reach), int(cn.x + reach) + 1):
				var q := Vector2(x + 0.5, y + 0.5) - base
				var u := q.dot(dir) / maxf(length, 0.001)
				var v := q.dot(side)
				var half := 0.0
				match shape:
					"broad":
						half = width * pow(maxf(sin(PI * clampf(u, 0.0, 1.0)), 0.0), 0.8) * (1.0 - 0.25 * u)
					"lance":
						half = width * pow(maxf(sin(PI * clampf(u, 0.0, 1.0)), 0.0), 1.4)
					"round":
						half = width * sqrt(maxf(0.0, 1.0 - pow(u * 2.0 - 1.0, 2.0)))
					"fan":
						# ginkgo: a narrow stalk opening into a wide fan with a notched edge
						half = width * 0.12 if u < 0.35 else width * (0.12 + 1.1 * pow((u - 0.35) / 0.65, 0.6)) * (1.0 - 0.25 * smoothstep(0.92, 1.0, u) * absf(sin(v * 0.3)))
					"shard":
						half = width * (1.0 - absf(u * 2.0 - 0.6)) if u >= 0.0 and u <= 1.0 else 0.0
					"maple":
						# five pointed lobes around the leaf's centre
						var lc := Vector2(x + 0.5, y + 0.5) - cn
						var ang := atan2(lc.dot(side), lc.dot(dir))
						var rr := length * 0.5 * (0.55 + 0.45 * pow(absf(cos(ang * 2.5)), 0.6))
						var dd := lc.length()
						var k := clampf(rr - dd + 0.5, 0.0, 1.0)
						if k > 0.0:
							var vein := 1.0 - 0.18 * clampf(1.0 - absf(sin(ang * 2.5)) * 6.0, 0.0, 1.0)
							var sh := (0.8 + 0.2 * dd / maxf(rr, 0.001)) * vein
							_put(x, y, Color(col.r * sh, col.g * sh, col.b * sh), k)
						continue
				if u < 0.0 or u > 1.0:
					continue
				var k2 := clampf(half - absf(v) + 0.5, 0.0, 1.0)
				if k2 <= 0.0:
					continue
				var rib := 1.0 - 0.22 * exp(-pow(v / maxf(width * 0.12, 0.6), 2.0))
				var rim := 1.0 - 0.18 * clampf(1.0 - (half - absf(v)) / maxf(width * 0.35, 0.5), 0.0, 1.0)
				var sh2 := rib * rim * (0.85 + 0.15 * u)
				_put(x, y, Color(col.r * sh2, col.g * sh2, col.b * sh2), k2)

	## a five-petal flower with a coloured heart
	func flower(cn: Vector2, r: float, petal: Color, heart: Color, rot: float) -> void:
		for y in range(int(cn.y - r - 1), int(cn.y + r + 2)):
			for x in range(int(cn.x - r - 1), int(cn.x + r + 2)):
				var q := Vector2(x + 0.5, y + 0.5) - cn
				var ang := atan2(q.y, q.x) + rot
				var rr := r * (0.6 + 0.4 * absf(cos(ang * 2.5)))
				var d := q.length()
				var k := clampf(rr - d + 0.5, 0.0, 1.0)
				if k <= 0.0:
					continue
				var t := d / maxf(r, 0.001)
				var col := heart.lerp(petal, smoothstep(0.15, 0.4, t))
				col = col.darkened(0.15 * smoothstep(0.7, 1.0, t))
				_put(x, y, col, k)

	func image() -> Image:
		var data := PackedByteArray()
		data.resize(size * size * 4)
		# average leaf colour: transparent texels take it so mip levels do not fringe dark
		var avg := Vector3.ZERO
		var wsum := 0.0
		for i in size * size:
			var a := buf[i * 4 + 3]
			if a > 0.5:
				avg += Vector3(buf[i * 4], buf[i * 4 + 1], buf[i * 4 + 2]) / a
				wsum += 1.0
		avg = avg / maxf(wsum, 1.0)
		for i in size * size:
			var a := buf[i * 4 + 3]
			for ch in 3:
				var cv := buf[i * 4 + ch] / a if a > 0.02 else avg[ch]
				data[i * 4 + ch] = int(clampf(cv, 0.0, 1.0) * 255.0)
			data[i * 4 + 3] = int(clampf(a, 0.0, 1.0) * 255.0)
		# Mip chain built by hand: plain averaging thins thin needles and twigs until they fall under
		# the alpha cut and whole crowns vanish in the distance.  Each level keeps coverage by mixing
		# the average alpha with the maximum of the four parent texels.
		var all := data.duplicate()
		var prev := data
		var sz := size
		while sz > 1:
			var nsz := sz / 2
			var lvl := PackedByteArray()
			lvl.resize(nsz * nsz * 4)
			for y in nsz:
				for x in nsz:
					var acc := [0.0, 0.0, 0.0]
					var asum := 0.0
					var amax := 0
					for o in [0, 1, sz, sz + 1]:
						var j: int = ((y * 2) * sz + x * 2 + o) * 4
						var aa := prev[j + 3]
						amax = maxi(amax, aa)
						asum += aa
						for ch in 3:
							acc[ch] += float(prev[j + ch]) * (aa + 8)
					var k := (y * nsz + x) * 4
					var wsum2 := asum + 32.0
					for ch in 3:
						lvl[k + ch] = int(clampf(acc[ch] / wsum2, 0.0, 255.0))
					lvl[k + 3] = int(clampf(asum * 0.25 * 1.15 + amax * 0.3, 0.0, 255.0))
			all.append_array(lvl)
			prev = lvl
			sz = nsz
		return Image.create_from_data(size, size, true, Image.FORMAT_RGBA8, all)

# ---------------------------------------------------------------- card geometry
## Builder for UV-mapped foliage cards.  Vertex colour = leaf tint (linear) with alpha = sway weight;
## normals are supplied by the caller (Flora spherizes them around the canopy).
class Cards:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()

	func is_empty() -> bool:
		return v.is_empty()

	func tri_count() -> int:
		return idx.size() / 3

	## quad centred on `cn` spanned by half-axes `ax` (U) and `ay` (V); `nrm` per corner
	func quad(cn: Vector3, ax: Vector3, ay: Vector3, col: Color, sway: float, nrm: Array, uv_rect: Rect2 = Rect2(0, 0, 1, 1)) -> void:
		var base := v.size()
		var lc := col.srgb_to_linear()
		var corners := [cn - ax + ay, cn + ax + ay, cn + ax - ay, cn - ax - ay]
		var uvs := [uv_rect.position, Vector2(uv_rect.end.x, uv_rect.position.y), uv_rect.end, Vector2(uv_rect.position.x, uv_rect.end.y)]
		for i in 4:
			v.append(corners[i])
			n.append(nrm[i])
			c.append(Color(lc.r, lc.g, lc.b, sway))
			uv.append(uvs[i])
		idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	## a bent strip from `pts` (the V axis runs along it), `widths` per point, flat in `side`
	func strip(pts: Array, widths: Array, side: Vector3, col: Color, sways: Array, normals: Array) -> void:
		var base := v.size()
		var lc := col.srgb_to_linear()
		var cnt := pts.size()
		for i in cnt:
			var t := i / float(cnt - 1)
			var s: Vector3 = side.normalized() * float(widths[i])
			for k in 2:
				var sd := -1.0 if k == 0 else 1.0
				v.append(pts[i] + s * sd)
				n.append(normals[i])
				c.append(Color(lc.r, lc.g, lc.b, float(sways[i])))
				uv.append(Vector2(0.0 if k == 0 else 1.0, 1.0 - t))
		for i in cnt - 1:
			var k2 := base + i * 2
			idx.append_array([k2, k2 + 2, k2 + 1, k2 + 1, k2 + 2, k2 + 3])

	## append another card builder's geometry, transformed
	func merge(o: Cards, xf: Transform3D) -> void:
		var base := v.size()
		var nb := xf.basis.inverse().transposed()
		for i in o.v.size():
			v.append(xf * o.v[i])
			n.append((nb * o.n[i]).normalized())
			c.append(o.c[i])
			uv.append(o.uv[i])
		for i in o.idx:
			idx.append(base + i)

	func add_to(mesh: ArrayMesh, mat: Material) -> void:
		if v.is_empty():
			return
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
