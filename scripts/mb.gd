class_name MB
extends RefCounted
## Mesh builder: merges primitive shapes (box, sphere, cylinder, cone, torus, capsule, lathe, ribbon...)
## into one ArrayMesh with per-vertex colours.  Every 3D model in the game is generated with this at runtime.
##
## The alpha channel of a vertex colour selects a *surface class* for the shared toon shader
## (cloth, metal, skin, foliage, hair, stone, crystal).  Use `MB.tag(col, MB.METAL)` to set it.
## The shader turns each class into a procedural texture (weave, brushed metal, bark, grain...),
## so the game has textured-looking surfaces with no image files at all.

var v := PackedVector3Array()
var n := PackedVector3Array()
var c := PackedColorArray()
var idx := PackedInt32Array()
## optional automatic ambient occlusion: darken vertices near the model's feet
var ao_floor := -INF
var ao_height := 0.6
var ao_strength := 0.0

# ---------------------------------------------------------------- surface classes (stored in vertex alpha)
const CLOTH := 1.0
const STONE := 0.9
const METAL := 0.8
const WOOD := 0.7
const SKIN := 0.6
const CRYSTAL := 0.5
const FOLIAGE := 0.4
const SCALE := 0.3
const HAIR := 0.2

static var _protos := {}
static var _mat_vc: ShaderMaterial = null
static var _mat_vc_plain: ShaderMaterial = null
static var _mat_outline: ShaderMaterial = null
static var _mat_scenery: ShaderMaterial = null
static var _mat_scenery_plain: ShaderMaterial = null

## Cel-shaded vertex-colour material with procedural per-class surface textures, wind sway for
## foliage, rim light and a soft colour lift.  Used for every solid model in the game.
const TOON := """
shader_type spatial;
render_mode diffuse_toon, specular_toon;
uniform vec3 rim_col : source_color = vec3(1.0, 0.92, 0.85);
uniform float wind = 1.0;
uniform float detail = 1.0;
varying vec3 wpos;
varying vec3 opos;
varying vec3 onrm;
varying float cls;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float h31(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}
float fbm(vec3 p) {
	float s = 0.0;
	float a = 0.5;
	for (int k = 0; k < 3; k++) {
		s += vnoise(p) * a;
		p *= 2.03;
		a *= 0.5;
	}
	return s;
}
bool is_cls(float a, float target) { return abs(a - target) < 0.05; }

// see-through: scenery standing between the follow camera and the hero dissolves in a dither
global uniform vec3 hero_pos;
uniform float occlude = 0.0;
float occ_keep(vec3 vview, vec2 fc, mat4 inv_view) {
	vec3 w = (inv_view * vec4(vview, 1.0)).xyz;
	vec3 cam = (inv_view * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 seg = hero_pos - cam;
	float l2 = max(dot(seg, seg), 0.001);
	float t = dot(w - cam, seg) / l2;
	if (t <= 0.0 || t >= 0.97) {
		return 1.0;
	}
	float d = length(w - (cam + seg * t));
	float short_of_hero = (1.0 - t) * sqrt(l2);
	float k = smoothstep(1.0, 2.2, d);
	k = max(k, 1.0 - smoothstep(0.6, 1.4, short_of_hero));
	return k;
}
float bayer4(vec2 fc) {
	int x = int(mod(fc.x, 4.0));
	int y = int(mod(fc.y, 4.0));
	const float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}
bool occ_discard(vec3 vview, vec2 fc, mat4 inv_view) {
	if (occlude <= 0.0) {
		return false;
	}
	float keep = occ_keep(vview, fc, inv_view);
	return keep < 0.999 && bayer4(fc) > keep;
}

void vertex() {
	cls = COLOR.a;
	opos = VERTEX;
	onrm = NORMAL;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (is_cls(cls, 0.4) && wind > 0.0) {
		// foliage sways in the wind, more at the top of the model
		float hgt = max(VERTEX.y, 0.0);
		float ph = wpos.x * 0.35 + wpos.z * 0.27;
		float sway = sin(TIME * 1.7 + ph) * 0.6 + sin(TIME * 3.1 + ph * 2.3) * 0.25;
		VERTEX.x += sway * hgt * 0.035 * wind;
		VERTEX.z += cos(TIME * 1.3 + ph) * hgt * 0.025 * wind;
	}
}

void fragment() {
	if (occ_discard(VERTEX, FRAGCOORD.xy, INV_VIEW_MATRIX)) {
		discard;
	}
	vec3 col = COLOR.rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, 1.06);
	float rough = 1.0;
	float spec = 0.15;
	float rim = 0.5;
	float rim_t = 0.5;
	vec3 emit = vec3(0.0);
	vec3 p = opos * 6.0 * detail;
	if (is_cls(cls, 1.0)) {
		// cloth: fine woven pattern and soft folds
		float weave = sin(opos.x * 140.0) * sin(opos.y * 140.0 + opos.z * 140.0);
		float folds = fbm(vec3(opos.x * 3.0, opos.y * 9.0, opos.z * 3.0));
		col *= 0.9 + 0.035 * weave + 0.16 * folds;
		rim = 0.45;
	} else if (is_cls(cls, 0.9)) {
		// stone: layered grain, speckles and darker cracks
		float g = fbm(p * 0.8);
		float sp = step(0.86, h31(floor(opos * 40.0)));
		float crack = smoothstep(0.02, 0.0, abs(fbm(p * 0.5 + 3.1) - 0.5));
		col *= 0.78 + 0.38 * g - 0.18 * crack + 0.08 * sp;
		rim = 0.25;
	} else if (is_cls(cls, 0.8)) {
		// metal: brushed streaks and a bright specular band
		float br = vnoise(vec3(opos.x * 2.0, opos.y * 90.0, opos.z * 2.0));
		col *= 0.85 + 0.25 * br;
		rough = 0.25;
		spec = 0.9;
		rim = 0.8;
		rim_t = 0.2;
	} else if (is_cls(cls, 0.7)) {
		// wood: rings and long grain
		float ring = sin((length(opos.xz) * 30.0) + fbm(p) * 6.0);
		float grain = vnoise(vec3(opos.x * 12.0, opos.y * 1.5, opos.z * 12.0));
		col *= 0.8 + 0.1 * ring + 0.2 * grain;
		rim = 0.3;
	} else if (is_cls(cls, 0.6)) {
		// skin: warm subsurface tint, very smooth
		col = mix(col, col * vec3(1.06, 0.95, 0.92), 0.5);
		rim = 0.7;
		rim_t = 0.75;
		emit = col * 0.06;
	} else if (is_cls(cls, 0.5)) {
		// crystal: facets glitter and glow from inside
		float fac = h31(floor(opos * 10.0));
		col *= 0.85 + 0.35 * fac;
		rough = 0.1;
		spec = 1.0;
		rim = 1.0;
		rim_t = 0.0;
		emit = col * (0.25 + 0.2 * sin(TIME * 2.0 + wpos.y * 3.0));
	} else if (is_cls(cls, 0.4)) {
		// foliage: leafy clumps, light shining through the edges
		float leaf = fbm(p * 1.4);
		col *= 0.72 + 0.5 * leaf;
		rim = 0.7;
		rim_t = 0.9;
		emit = col * 0.05;
	} else if (is_cls(cls, 0.3)) {
		// scales: overlapping plate pattern
		vec2 q = vec2(opos.x + opos.z, opos.y) * 18.0;
		q.x += mod(floor(q.y), 2.0) * 0.5;
		float sc = length(fract(q) - vec2(0.5, 0.2));
		col *= 0.78 + 0.35 * smoothstep(0.6, 0.2, sc);
		rough = 0.45;
		spec = 0.5;
		rim = 0.6;
	} else if (is_cls(cls, 0.2)) {
		// hair: strands and an anime-style highlight ring
		float strand = vnoise(vec3(opos.x * 70.0, opos.y * 4.0, opos.z * 70.0));
		col *= 0.8 + 0.3 * strand;
		float band = smoothstep(0.05, 0.0, abs(onrm.y - 0.45)) * 0.35;
		col += vec3(band);
		spec = 0.6;
		rough = 0.4;
		rim = 0.55;
	}
	ALBEDO = col * 0.9;
	ROUGHNESS = rough;
	SPECULAR = spec;
	RIM = rim;
	RIM_TINT = rim_t;
	EMISSION = emit;
}
"""

## Ink outline drawn as a second pass with front faces culled (the "inverted hull" trick).
const OUTLINE := """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;
uniform float width = 0.018;
uniform vec4 ink : source_color = vec4(0.07, 0.05, 0.1, 1.0);
varying float thin;
// see-through: scenery standing between the follow camera and the hero dissolves in a dither
global uniform vec3 hero_pos;
uniform float occlude = 0.0;
float occ_keep(vec3 vview, vec2 fc, mat4 inv_view) {
	vec3 w = (inv_view * vec4(vview, 1.0)).xyz;
	vec3 cam = (inv_view * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 seg = hero_pos - cam;
	float l2 = max(dot(seg, seg), 0.001);
	float t = dot(w - cam, seg) / l2;
	if (t <= 0.0 || t >= 0.97) {
		return 1.0;
	}
	float d = length(w - (cam + seg * t));
	float short_of_hero = (1.0 - t) * sqrt(l2);
	float k = smoothstep(1.0, 2.2, d);
	k = max(k, 1.0 - smoothstep(0.6, 1.4, short_of_hero));
	return k;
}
float bayer4(vec2 fc) {
	int x = int(mod(fc.x, 4.0));
	int y = int(mod(fc.y, 4.0));
	const float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}
bool occ_discard(vec3 vview, vec2 fc, mat4 inv_view) {
	if (occlude <= 0.0) {
		return false;
	}
	float keep = occ_keep(vview, fc, inv_view);
	return keep < 0.999 && bayer4(fc) > keep;
}

void vertex() {
	// thin double-sided geometry (ribbons, leaves, wings) has its class alpha nudged off the
	// 0.1 grid; an inverted hull cannot outline it, so it is skipped
	thin = step(0.15, abs(fract(COLOR.a * 10.0 + 0.5) - 0.5));
	// keep the ink line a similar thickness on screen: thinner in close-ups, a little bolder far away
	float depth = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
	float k = clamp(depth / 9.0, 0.32, 1.35);
	VERTEX += NORMAL * width * k * (1.0 - thin);
}
void fragment() {
	if (thin > 0.5 || occ_discard(VERTEX, FRAGCOORD.xy, INV_VIEW_MATRIX)) {
		discard;
	}
	ALBEDO = mix(ink.rgb, COLOR.rgb * 0.22, 0.45);
}
"""

## Characters and monsters (the rigged Blender assets) get their own shading, after the anime
## look of games such as Genshin Impact and Guilty Gear Xrd (see README, References):
## * a soft two-tone cel ramp of the key light on a half-Lambert term, with the received shadow
##   folded into the same ramp, instead of Godot's hard toon terminator;
## * shadows that are *tinted* rather than grey: warm rose for skin, cool lavender for cloth and
##   fur, so a shadowed face never looks dirty;
## * the ambient light toned down (it used to double every colour into neon) and a key light that
##   keeps a lit surface close to its painted colour;
## * a thin rim only on the side facing the light, toon specular bands on metal, crystal and
##   wet scales, and an "angel ring" highlight across hair;
## * ink lines coloured from the surface under them (dark rose under skin, deep blue under a blue
##   robe) and drawn thinner, like coloured line art (ACTOR_OUTLINE).
const ACTOR := """
shader_type spatial;
render_mode cull_back;
uniform float key = 0.82;
uniform float amb = 0.55;
uniform float detail = 1.0;
varying float cls;
varying vec3 opos;
varying vec3 onrm;
varying vec3 shade_tint;
varying float spec_k;
varying float shin;
varying float rim_k;
varying float ring;

float h31(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}
float fbm(vec3 p) {
	float s = 0.0;
	float a = 0.5;
	for (int k = 0; k < 3; k++) {
		s += vnoise(p) * a;
		p *= 2.03;
		a *= 0.5;
	}
	return s;
}
bool is_cls(float a, float target) { return abs(a - target) < 0.05; }

void vertex() {
	cls = COLOR.a;
	opos = VERTEX;
	onrm = NORMAL;
}

void fragment() {
	vec3 col = COLOR.rgb;
	// the filmic tonemapper works per channel and pushes saturated dyes further: ease them first
	col = mix(vec3(dot(col, vec3(0.3, 0.59, 0.11))), col, 0.84);
	shade_tint = vec3(0.6, 0.58, 0.78);
	spec_k = 0.0;
	shin = 30.0;
	rim_k = 0.32;
	ring = 0.0;
	if (is_cls(cls, 1.0)) {
		// cloth: a faint weave and soft tonal variation, never a pattern you notice first
		float weave = sin(opos.x * 160.0) * sin(opos.y * 160.0 + opos.z * 160.0);
		float folds = fbm(vec3(opos.x * 3.0, opos.y * 8.0, opos.z * 3.0) * detail);
		col *= 0.95 + 0.02 * weave + 0.08 * folds;
	} else if (is_cls(cls, 0.6)) {
		// skin: smooth, warm rose shadows
		shade_tint = vec3(0.98, 0.66, 0.64);
		rim_k = 0.45;
	} else if (is_cls(cls, 0.2)) {
		// hair and fur: fine strands, a cool deep shadow and the anime highlight ring
		float strand = vnoise(vec3(opos.x * 90.0, opos.y * 5.0, opos.z * 90.0));
		col *= 0.9 + 0.16 * strand;
		shade_tint = vec3(0.52, 0.52, 0.72);
		ring = smoothstep(0.08, 0.0, abs(onrm.y - 0.42 + 0.05 * sin(atan(onrm.x, onrm.z) * 14.0))) * step(0.0, onrm.z + 0.35);
		rim_k = 0.28;
	} else if (is_cls(cls, 0.8)) {
		// metal: brushed, with a sharp specular band
		float br = vnoise(vec3(opos.x * 2.0, opos.y * 80.0, opos.z * 2.0));
		col *= 0.85 + 0.25 * br;
		shade_tint = vec3(0.42, 0.42, 0.55);
		spec_k = 1.1;
		shin = 48.0;
		rim_k = 0.5;
	} else if (is_cls(cls, 0.5)) {
		// crystal (eyes, gems): bright facets that glow a little from inside
		float fac = h31(floor(opos * 10.0));
		col *= 0.92 + 0.2 * fac;
		spec_k = 1.0;
		shin = 70.0;
		EMISSION = col * 0.18;
	} else if (is_cls(cls, 0.3)) {
		// scales: overlapping plates, a wet sheen
		vec2 q = vec2(opos.x + opos.z, opos.y) * 18.0;
		q.x += mod(floor(q.y), 2.0) * 0.5;
		float sc = length(fract(q) - vec2(0.5, 0.2));
		col *= 0.84 + 0.22 * smoothstep(0.6, 0.2, sc);
		spec_k = 0.22;
		shin = 60.0;
	} else if (is_cls(cls, 0.9)) {
		// horn, bone, claw, stone
		float g = fbm(opos * 5.0 * detail);
		col *= 0.88 + 0.2 * g;
		shade_tint = vec3(0.58, 0.55, 0.66);
		// matte: a hard toon highlight on horn, bone and stone read as plastic
		spec_k = 0.0;
	} else if (is_cls(cls, 0.7)) {
		// wood: long grain
		float grain = vnoise(vec3(opos.x * 12.0, opos.y * 1.5, opos.z * 12.0));
		col *= 0.86 + 0.18 * grain;
		shade_tint = vec3(0.62, 0.55, 0.62);
	} else if (is_cls(cls, 0.4)) {
		float leaf = fbm(opos * 8.0);
		col *= 0.82 + 0.3 * leaf;
		shade_tint = vec3(0.55, 0.65, 0.7);
	}
	ALBEDO = col;
	// the ambient term is what turned lit robes neon: keep only part of it
	AO = amb;
	AO_LIGHT_AFFECT = 0.0;
	ROUGHNESS = 0.8;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	vec3 lc = LIGHT_COLOR / PI;
	if (LIGHT_IS_DIRECTIONAL) {
		// soft two-tone ramp: the terminator sits a little past the half-Lambert midpoint and the
		// received shadow joins the same ramp, so cast shadows read as part of the cel shading
		float h = ndl * 0.5 + 0.5;
		float lit = smoothstep(0.44, 0.52, h) * smoothstep(0.15, 0.65, ATTENUATION);
		vec3 ramp = mix(shade_tint * 0.52, vec3(1.0), lit);
		DIFFUSE_LIGHT += lc * ramp * key;
		// a thin rim of light on the lit side only
		float fr = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float rim = smoothstep(0.6, 0.68, fr) * smoothstep(0.05, 0.45, ndl) * lit;
		SPECULAR_LIGHT += lc * ALBEDO * rim * rim_k;
		// toon specular band (metal, crystal, scales) and the hair highlight ring
		vec3 hv = normalize(VIEW + LIGHT);
		float sp = pow(max(dot(NORMAL, hv), 0.0), shin);
		SPECULAR_LIGHT += lc * smoothstep(0.42, 0.5, sp) * spec_k * lit * 0.6;
		SPECULAR_LIGHT += lc * ALBEDO * ring * (0.35 + 0.45 * lit) * 0.6;
	} else {
		// lanterns and spell lights: a soft wrapped Lambert
		float l = clamp(ndl * 0.6 + 0.4, 0.0, 1.0);
		DIFFUSE_LIGHT += lc * l * ATTENUATION;
	}
}
"""

## Coloured ink lines for characters and monsters: the line takes the hue of the surface under it,
## darkened and a little more saturated, and is thinner than the scenery's outline.
const ACTOR_OUTLINE := """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;
uniform float width = 0.0105;
varying float thin;
void vertex() {
	thin = step(0.15, abs(fract(COLOR.a * 10.0 + 0.5) - 0.5));
	float depth = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
	float k = clamp(depth / 7.0, 0.3, 1.5);
	VERTEX += NORMAL * width * k * (1.0 - thin);
}
void fragment() {
	if (thin > 0.5) {
		discard;
	}
	vec3 c = COLOR.rgb;
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	vec3 sat = clamp(mix(vec3(l), c, 1.4), 0.0, 1.0);
	ALBEDO = mix(vec3(0.05, 0.035, 0.07), sat * 0.3, 0.7);
}
"""

static var _mat_actor: ShaderMaterial = null
static var _mat_actor_plain: ShaderMaterial = null

## cel material for characters and monsters, with coloured ink lines
static func mat_actor() -> Material:
	if _mat_actor == null:
		_mat_actor = ShaderMaterial.new()
		_mat_actor.shader = _shader(ACTOR)
		var ol := ShaderMaterial.new()
		ol.shader = _shader(ACTOR_OUTLINE)
		ol.render_priority = -1
		_mat_actor.next_pass = ol
	return _mat_actor

## the same without lines (eyes, thin cloth, fine detail)
static func mat_actor_plain() -> Material:
	if _mat_actor_plain == null:
		_mat_actor_plain = ShaderMaterial.new()
		_mat_actor_plain.shader = mat_actor().shader
	return _mat_actor_plain

static var _mat_glow: StandardMaterial3D = null
static var _mat_glass: StandardMaterial3D = null
static var _mat_aura: ShaderMaterial = null

## Fresnel aura: glows at the silhouette and fades to nothing where it faces the camera, so an aura
## sphere reads as a soft halo instead of a solid ball.  Colour alpha controls intensity.
const AURA := """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;
uniform float power = 2.6;
uniform float pulse = 1.0;
void fragment() {
	float f = 1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float a = pow(f, power) * 1.6 + 0.02;
	a *= 0.85 + 0.15 * sin(TIME * 2.5 * pulse);
	ALBEDO = COLOR.rgb * a * COLOR.a * 2.0;
}
"""

static func _proto(key: String) -> Array:
	if _protos.has(key):
		return _protos[key]
	var m: PrimitiveMesh
	match key:
		"box":
			m = BoxMesh.new()
		"sph":
			var s := SphereMesh.new()
			s.radial_segments = 12
			s.rings = 6
			m = s
		"sph_hi":
			var sh := SphereMesh.new()
			sh.radial_segments = 20
			sh.rings = 10
			m = sh
		"sph_lo":
			var s2 := SphereMesh.new()
			s2.radial_segments = 8
			s2.rings = 4
			m = s2
		"hemi":
			var hs := SphereMesh.new()
			hs.radial_segments = 16
			hs.rings = 5
			hs.is_hemisphere = true
			m = hs
		"cap":
			var cp := CapsuleMesh.new()
			cp.radius = 0.25
			cp.height = 1.0
			cp.radial_segments = 12
			cp.rings = 3
			m = cp
		"cyl8":
			var cy := CylinderMesh.new()
			cy.radial_segments = 8
			cy.rings = 1
			m = cy
		"cyl4":
			var c4 := CylinderMesh.new()
			c4.radial_segments = 4
			c4.rings = 1
			m = c4
		"cyl6":
			var c6b := CylinderMesh.new()
			c6b.radial_segments = 6
			c6b.rings = 1
			m = c6b
		"cyl14":
			var c14 := CylinderMesh.new()
			c14.radial_segments = 14
			c14.rings = 1
			m = c14
		"cyl24":
			var c24 := CylinderMesh.new()
			c24.radial_segments = 24
			c24.rings = 1
			m = c24
		"fr8":
			var fr := CylinderMesh.new()
			fr.top_radius = 0.28
			fr.radial_segments = 10
			fr.rings = 1
			m = fr
		"fr14":
			var fr2 := CylinderMesh.new()
			fr2.top_radius = 0.3
			fr2.radial_segments = 16
			fr2.rings = 2
			m = fr2
		"cone8":
			var co := CylinderMesh.new()
			co.top_radius = 0.0
			co.radial_segments = 8
			co.rings = 1
			m = co
		"cone4":
			var c5 := CylinderMesh.new()
			c5.top_radius = 0.0
			c5.radial_segments = 4
			c5.rings = 1
			m = c5
		"cone6":
			var c7 := CylinderMesh.new()
			c7.top_radius = 0.0
			c7.radial_segments = 6
			c7.rings = 1
			m = c7
		"cone14":
			var c6 := CylinderMesh.new()
			c6.top_radius = 0.0
			c6.radial_segments = 14
			c6.rings = 1
			m = c6
		"torus":
			var t := TorusMesh.new()
			t.inner_radius = 0.42
			t.outer_radius = 0.5
			t.rings = 20
			t.ring_segments = 6
			m = t
		"torus_hi":
			var th := TorusMesh.new()
			th.inner_radius = 0.42
			th.outer_radius = 0.5
			th.rings = 36
			th.ring_segments = 8
			m = th
		"prism":
			var pr := PrismMesh.new()
			m = pr
		_:
			# a cylinder or cone of any other number of sides (a drum of 20, a column of 10, a spire of
			# 5): these used to fall through to a box, so round drums, hall columns and spires were drawn
			# square.  Built here at the documented unit height, the height the box gave them, so they
			# keep their size and simply turn round.
			var sides := key.trim_prefix("cyl").trim_prefix("cone")
			if (key.begins_with("cyl") or key.begins_with("cone")) and sides.is_valid_int() and int(sides) >= 3:
				var cn := CylinderMesh.new()
				cn.radial_segments = int(sides)
				cn.rings = 1
				cn.height = 1.0
				if key.begins_with("cone"):
					cn.top_radius = 0.0
				m = cn
			else:
				m = BoxMesh.new()
	var arr := m.get_mesh_arrays()
	var out := [arr[Mesh.ARRAY_VERTEX], arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_INDEX]]
	_protos[key] = out
	return out

## Colour with a surface class in its alpha (see the class constants above).
static func tag(col: Color, cls: float) -> Color:
	return Color(col.r, col.g, col.b, cls)

## Linear colour for flat double-sided geometry: the class alpha is nudged by -0.025 so the
## outline pass knows to skip it (the toon shader's class test tolerates the offset).
static func _thin(col: Color) -> Color:
	var lc := col.srgb_to_linear()
	lc.a = maxf(0.0, col.a - 0.025)
	return lc

func _shade(p: Vector3, col: Color) -> Color:
	if ao_strength <= 0.0 or ao_floor == -INF:
		return col
	var k := clampf((p.y - ao_floor) / ao_height, 0.0, 1.0)
	var f := lerpf(1.0 - ao_strength, 1.0, k)
	return Color(col.r * f, col.g * f, col.b * f, col.a)

## Add a unit primitive transformed by `xf` (prototypes have unit size: box 1x1x1, sphere diameter 1,
## cylinder/cone radius 0.5 and height 1, torus outer diameter 1; except that the standard cylinders and
## cones, cyl4/6/8/14/24 and cone4/6/8/14, are Godot's own meshes and two units tall, the height every
## model built on them was shaped with).
func prim(key: String, xf: Transform3D, col: Color) -> void:
	var p := _proto(key)
	var pv: PackedVector3Array = p[0]
	var pn: PackedVector3Array = p[1]
	var pi: PackedInt32Array = p[2]
	var base := v.size()
	var nb := xf.basis.inverse().transposed()
	var lc := col.srgb_to_linear()
	lc.a = col.a
	var ao := ao_strength > 0.0 and ao_floor != -INF
	for i in pv.size():
		var wp := xf * pv[i]
		v.append(wp)
		n.append((nb * pn[i]).normalized())
		c.append(_shade(wp, lc) if ao else lc)
	for i in pi:
		idx.append(base + i)

static func _xf(pos: Vector3, size: Vector3, rot: Vector3) -> Transform3D:
	var b := Basis.from_euler(rot) if rot != Vector3.ZERO else Basis.IDENTITY
	b = b.scaled(size)
	return Transform3D(b, pos)

## Basis whose Y axis points along `dir` (for limbs, horns, branches).
static func basis_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	if y.length() < 0.001:
		return Basis.IDENTITY
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)

func box(pos: Vector3, size: Vector3, col: Color, rot: Vector3 = Vector3.ZERO) -> void:
	prim("box", _xf(pos, size, rot), col)

func sph(pos: Vector3, radii: Vector3, col: Color, rot: Vector3 = Vector3.ZERO, lo: bool = false) -> void:
	prim("sph_lo" if lo else "sph", _xf(pos, radii * 2.0, rot), col)

## smooth high-resolution ellipsoid (faces, heads, big bodies)
func sph_hi(pos: Vector3, radii: Vector3, col: Color, rot: Vector3 = Vector3.ZERO) -> void:
	prim("sph_hi", _xf(pos, radii * 2.0, rot), col)

func hemi(pos: Vector3, radii: Vector3, col: Color, rot: Vector3 = Vector3.ZERO) -> void:
	prim("hemi", _xf(pos, Vector3(radii.x * 2.0, radii.y, radii.z * 2.0), rot), col)

func ball(pos: Vector3, r: float, col: Color, lo: bool = false) -> void:
	prim("sph_lo" if lo else "sph", _xf(pos, Vector3(r, r, r) * 2.0, Vector3.ZERO), col)

## cylinder, pos is the centre
func cyl(pos: Vector3, r: float, h: float, col: Color, rot: Vector3 = Vector3.ZERO, seg: int = 8) -> void:
	prim("cyl%d" % seg, _xf(pos, Vector3(r * 2.0, h, r * 2.0), rot), col)

## cone with its base at the bottom, pos is the centre of the height
func cone(pos: Vector3, r: float, h: float, col: Color, rot: Vector3 = Vector3.ZERO, seg: int = 8) -> void:
	prim("cone%d" % seg, _xf(pos, Vector3(r * 2.0, h, r * 2.0), rot), col)

## torus lying flat (axis = y)
func torus(pos: Vector3, r: float, thick: float, col: Color, rot: Vector3 = Vector3.ZERO, hi: bool = false) -> void:
	prim("torus_hi" if hi else "torus", _xf(pos, Vector3(r * 2.0, thick * 25.0, r * 2.0), rot), col)

## capsule (rounded limb) between two points
func capsule(a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d := b - a
	var len := d.length()
	var bs := basis_y(d).scaled(Vector3(r * 4.0, (len + r * 2.0), r * 4.0))
	prim("cap", Transform3D(bs, (a + b) * 0.5), col)

## tapered cylinder from point `a` (radius r0) to point `b` (radius r1); builds its own ring geometry
func limb(a: Vector3, b: Vector3, r0: float, r1: float, col: Color, seg: int = 8, col1: Color = Color(0, 0, 0, -1)) -> void:
	var d := b - a
	if d.length() < 0.0001:
		return
	var bs := basis_y(d)
	var cb := col if col1.a < 0.0 else col1
	var base := v.size()
	var lc0 := col.srgb_to_linear()
	lc0.a = col.a
	var lc1 := cb.srgb_to_linear()
	lc1.a = cb.a
	var slope := (r0 - r1) / d.length()
	for i in seg + 1:
		var ang := TAU * i / seg
		var dirv := bs.x * cos(ang) + bs.z * sin(ang)
		var nrm := (dirv + bs.y * slope).normalized()
		var p0 := a + dirv * r0
		var p1 := b + dirv * r1
		v.append(p0)
		n.append(nrm)
		c.append(_shade(p0, lc0))
		v.append(p1)
		n.append(nrm)
		c.append(_shade(p1, lc1))
	for i in seg:
		var k := base + i * 2
		# clockwise when seen from outside (Godot's front-face winding)
		idx.append_array([k, k + 2, k + 1, k + 1, k + 2, k + 3])
	# end caps as small balls keep joints round
	if r1 > 0.01:
		ball(b, r1, cb, true)

## surface of revolution around the Y axis.  `prof` is a list of Vector2(radius, height).
func lathe(center: Vector3, prof: Array, col: Color, seg: int = 14, col_top: Color = Color(0, 0, 0, -1), squash: Vector2 = Vector2.ONE) -> void:
	if prof.size() < 2:
		return
	var base := v.size()
	var ct := col if col_top.a < 0.0 else col_top
	var y0: float = prof[0].y
	var y1: float = prof[prof.size() - 1].y
	for j in prof.size():
		var pr: Vector2 = prof[j]
		var k := clampf((pr.y - y0) / maxf(0.0001, y1 - y0), 0.0, 1.0)
		var cc := col.lerp(ct, k)
		var lc := cc.srgb_to_linear()
		lc.a = cc.a
		var prev: Vector2 = prof[maxi(0, j - 1)]
		var nxt: Vector2 = prof[mini(prof.size() - 1, j + 1)]
		var tng := nxt - prev
		for i in seg + 1:
			var ang := TAU * i / seg
			var dirv := Vector3(cos(ang) * squash.x, 0.0, sin(ang) * squash.y)
			var p := center + dirv * pr.x + Vector3(0, pr.y, 0)
			var nrm := (Vector3(cos(ang), 0, sin(ang)) * tng.y - Vector3(0, tng.x, 0)).normalized()
			v.append(p)
			n.append(nrm)
			c.append(_shade(p, lc))
	var row := seg + 1
	for j in prof.size() - 1:
		for i in seg:
			var a0 := base + j * row + i
			var b0 := a0 + row
			idx.append_array([a0, a0 + 1, b0, a0 + 1, b0 + 1, b0])

## Flat double-sided strip through a list of points (hair strands, ribbons, tails, sword trails).
## `widths` gives the half-width at each point; `side` is the direction the strip spreads in.
func ribbon(pts: Array, widths: Array, side: Vector3, col: Color, col_end: Color = Color(0, 0, 0, -1)) -> void:
	if pts.size() < 2:
		return
	var ce := col if col_end.a < 0.0 else col_end
	var base := v.size()
	var cnt := pts.size()
	for i in cnt:
		var p: Vector3 = pts[i]
		var wdt: float = widths[mini(i, widths.size() - 1)]
		var tng: Vector3 = (pts[mini(i + 1, cnt - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var nrm := tng.cross(side).normalized()
		if nrm.length() < 0.01:
			nrm = Vector3.UP
		var cc := col.lerp(ce, i / float(cnt - 1))
		var lc := _thin(cc)
		for s in [-1.0, 1.0]:
			var q: Vector3 = p + side.normalized() * wdt * s
			v.append(q)
			n.append(nrm)
			c.append(_shade(q, lc))
	for i in cnt - 1:
		var k := base + i * 2
		idx.append_array([k, k + 2, k + 1, k + 1, k + 2, k + 3])
		idx.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])

## Leaf / petal / feather: a pointed double-sided blade from `root` towards `tip`.
func leaf(root: Vector3, tip: Vector3, wdt: float, col: Color, side: Vector3 = Vector3.ZERO, col_tip: Color = Color(0, 0, 0, -1)) -> void:
	var d := tip - root
	var s := side
	if s == Vector3.ZERO:
		s = d.cross(Vector3.UP)
		if s.length() < 0.01:
			s = Vector3.RIGHT
	var mid := root + d * 0.45 + Vector3(0, d.length() * 0.06, 0)
	ribbon([root, mid, tip], [wdt * 0.15, wdt, 0.0], s, col, col_tip)

## n-sided flat fan (discs, rune circles, flower faces), lying in the XZ plane at `center`
func disc(center: Vector3, r: float, col: Color, seg: int = 16, col_rim: Color = Color(0, 0, 0, -1), rot: Vector3 = Vector3.ZERO) -> void:
	var cr := col if col_rim.a < 0.0 else col_rim
	var bs := Basis.from_euler(rot)
	var base := v.size()
	var lc := _thin(col)
	var lr := _thin(cr)
	v.append(center)
	n.append(bs * Vector3.UP)
	c.append(lc)
	for i in seg + 1:
		var ang := TAU * i / seg
		v.append(center + bs * Vector3(cos(ang) * r, 0, sin(ang) * r))
		n.append(bs * Vector3.UP)
		c.append(lr)
	for i in seg:
		idx.append_array([base, base + 1 + i, base + 2 + i])
		idx.append_array([base, base + 2 + i, base + 1 + i])

## Arc of a ring in the XZ plane, from angle a0 to a1 (radians), with width `wdt` (rune bands, crescents).
func arc(center: Vector3, r: float, wdt: float, a0: float, a1: float, col: Color, seg: int = 16, rot: Vector3 = Vector3.ZERO) -> void:
	var bs := Basis.from_euler(rot)
	var base := v.size()
	var lc := _thin(col)
	for i in seg + 1:
		var ang := lerpf(a0, a1, i / float(seg))
		var dir := Vector3(cos(ang), 0, sin(ang))
		v.append(center + bs * (dir * (r - wdt * 0.5)))
		v.append(center + bs * (dir * (r + wdt * 0.5)))
		n.append(bs * Vector3.UP)
		n.append(bs * Vector3.UP)
		c.append(lc)
		c.append(lc)
	for i in seg:
		var k := base + i * 2
		idx.append_array([k, k + 2, k + 1, k + 1, k + 2, k + 3])
		idx.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])

## Faceted gem / crystal cluster point (double pyramid with `sides` faces).
func crystal(pos: Vector3, r: float, h: float, col: Color, rot: Vector3 = Vector3.ZERO, sides: int = 6) -> void:
	var key := "cone%d" % sides if sides in [4, 6, 8, 14] else "cone6"
	prim(key, _xf(pos + Basis.from_euler(rot) * Vector3(0, h * 0.35, 0), Vector3(r * 2.0, h * 0.7, r * 2.0), rot), col)
	prim(key, _xf(pos - Basis.from_euler(rot) * Vector3(0, h * 0.15, 0), Vector3(r * 2.0, h * 0.3, r * 2.0), rot + Vector3(PI, 0, 0)), col.darkened(0.15))

## flat horizontal quad of colour `col` at height y
func quad(x0: float, z0: float, x1: float, z1: float, y: float, col: Color) -> void:
	var base := v.size()
	v.append(Vector3(x0, y, z0))
	v.append(Vector3(x1, y, z0))
	v.append(Vector3(x1, y, z1))
	v.append(Vector3(x0, y, z1))
	var lc := col.srgb_to_linear()
	lc.a = col.a
	for i in 4:
		n.append(Vector3.UP)
		c.append(lc)
	idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

func quad4(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, c0: Color, c1: Color, c2: Color, c3: Color) -> void:
	var base := v.size()
	var nn := (p1 - p0).cross(p3 - p0).normalized()
	if nn.y < 0:
		nn = -nn
	v.append(p0)
	v.append(p1)
	v.append(p2)
	v.append(p3)
	for i in 4:
		n.append(nn)
	for cc in [c0, c1, c2, c3]:
		c.append(_thin(cc))
	idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

## quad with explicit per-corner normals (smooth terrain)
func quad_n(p: Array, nr: Array, cols: Array) -> void:
	var base := v.size()
	for i in 4:
		v.append(p[i])
		n.append(nr[i])
		var lc: Color = cols[i].srgb_to_linear()
		lc.a = cols[i].a
		c.append(lc)
	idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

## append another builder's geometry (optionally transformed)
func merge(o: MB, xf: Transform3D = Transform3D.IDENTITY) -> void:
	var base := v.size()
	var nb := xf.basis.inverse().transposed()
	for i in o.v.size():
		v.append(xf * o.v[i])
		n.append((nb * o.n[i]).normalized())
		c.append(o.c[i])
	for i in o.idx:
		idx.append(base + i)

func is_empty() -> bool:
	return v.is_empty()

func tri_count() -> int:
	return idx.size() / 3

func build(mat: Material = null) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if v.is_empty():
		return mesh
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(0, mat if mat != null else mat_vc())
	return mesh

## append this builder as an extra surface of an existing mesh
func add_to(mesh: ArrayMesh, mat: Material) -> void:
	if v.is_empty():
		return
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(mesh.get_surface_count() - 1, mat)

# ---------------------------------------------------------------- materials
static func _shader(code: String) -> Shader:
	var sh := Shader.new()
	sh.code = code
	return sh

## toon material with an ink outline pass (characters, monsters, landmarks)
static func mat_vc() -> Material:
	if _mat_vc == null:
		_mat_vc = ShaderMaterial.new()
		_mat_vc.shader = _shader(TOON)
		_mat_vc.next_pass = mat_outline()
	return _mat_vc

## toon material without an outline (small props, decorations, distant scenery)
static func mat_plain() -> Material:
	if _mat_vc_plain == null:
		_mat_vc_plain = ShaderMaterial.new()
		_mat_vc_plain.shader = mat_vc().shader
	return _mat_vc_plain

## toon + outline for scenery (trees, rocks, landmarks, buildings): dissolves where it stands
## between the follow camera and the hero
static func mat_scenery() -> Material:
	if _mat_scenery == null:
		_mat_scenery = ShaderMaterial.new()
		_mat_scenery.shader = mat_vc().shader
		_mat_scenery.set_shader_parameter("occlude", 1.0)
		var ol := ShaderMaterial.new()
		ol.shader = mat_outline().shader
		ol.render_priority = -1
		ol.set_shader_parameter("occlude", 1.0)
		_mat_scenery.next_pass = ol
	return _mat_scenery

static func mat_scenery_plain() -> Material:
	if _mat_scenery_plain == null:
		_mat_scenery_plain = ShaderMaterial.new()
		_mat_scenery_plain.shader = mat_vc().shader
		_mat_scenery_plain.set_shader_parameter("occlude", 1.0)
	return _mat_scenery_plain

## the same mesh with its toon surfaces swapped for the see-through scenery materials
static func as_scenery(m: Mesh) -> Mesh:
	var out: Mesh = m.duplicate()
	for i in out.get_surface_count():
		var mat := out.surface_get_material(i)
		if mat == mat_vc():
			out.surface_set_material(i, mat_scenery())
		elif mat == mat_plain():
			out.surface_set_material(i, mat_scenery_plain())
	return out

static func mat_outline() -> ShaderMaterial:
	if _mat_outline == null:
		_mat_outline = ShaderMaterial.new()
		_mat_outline.shader = _shader(OUTLINE)
		_mat_outline.render_priority = -1
	return _mat_outline

## unshaded additive-looking glow (colour alpha controls intensity)
static func mat_glow() -> StandardMaterial3D:
	if _mat_glow == null:
		_mat_glow = StandardMaterial3D.new()
		_mat_glow.vertex_color_use_as_albedo = true
		_mat_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat_glow.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_glow.no_depth_test = false
	return _mat_glow

## fresnel halo (auras, gem glows, spell orbs)
static func mat_aura() -> ShaderMaterial:
	if _mat_aura == null:
		_mat_aura = ShaderMaterial.new()
		_mat_aura.shader = _shader(AURA)
	return _mat_aura

## translucent shiny glass
static func mat_glass() -> StandardMaterial3D:
	if _mat_glass == null:
		_mat_glass = StandardMaterial3D.new()
		_mat_glass.vertex_color_use_as_albedo = true
		_mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_glass.roughness = 0.15
		_mat_glass.metallic = 0.4
		_mat_glass.rim_enabled = true
		_mat_glass.rim = 0.6
		_mat_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _mat_glass

static func emissive(col: Color, energy: float = 1.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m

static func mesh_node(parent: Node, mesh: Mesh, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	if parent != null:
		parent.add_child(mi)
	return mi
