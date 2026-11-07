class_name Terrain3D
extends RefCounted
## Builds the 3D terrain of an area from its tile grid: a rolling height field with smooth colour
## blending and a procedural ground texture, animated water with foam, theme-specific landmarks
## (two variants each), wind-swayed grass tufts, decorations, horizon silhouettes and sect buildings.

const T := 2.0          # world units per tile
const CH := 12          # tiles per render chunk
const WATER_Y := -0.12

static var _water_mats := {}
static var _ground_mats := {}
static var _protos := {}

const STYLE := {"grass": 0, "mud": 1, "snow": 2, "rock": 3, "tile": 4, "sand": 5, "ash": 6, "crystal": 7, "marble": 8, "glass": 9, "moss": 10, "permafrost": 11, "nebula": 12, "leaves": 13, "lilyfield": 14, "underworld": 15}

static func world_pos(tile: Vector2i) -> Vector3:
	return Vector3((tile.x + 0.5) * T, 0.0, (tile.y + 0.5) * T)

static func hash2(x: int, y: int, salt: float = 0.0) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + salt * 37.719) * 43758.5453, 1.0)

# ---------------------------------------------------------------- shaders
const GROUND := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform int style = 0;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 path_dark : source_color = vec3(0.4, 0.35, 0.3);
uniform vec3 accent : source_color = vec3(1.0, 0.9, 0.6);
uniform float cloud_shadow = 0.0;
varying vec3 wp;
varying vec3 wn;
varying float kind;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 h22(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		s += n2(p) * a;
		p = p * 2.03 + vec2(3.1, 1.7);
		a *= 0.5;
	}
	return s;
}
// distance to the nearest cell edge of a jittered grid (cobbles, flagstones, crystal facets)
vec2 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = h22(i + g) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
		}
	}
	return vec2(d1, d2 - d1);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	kind = COLOR.a;
}

void fragment() {
	vec3 base = COLOR.rgb * tint;
	vec2 uv = wp.xz;
	float big = fbm(uv * 0.08);
	float mid = fbm(uv * 0.45);
	float fine = n2(uv * 7.0);
	vec3 g = base * (0.84 + 0.22 * big + 0.12 * mid);
	float rough = 0.95;
	vec3 emit = vec3(0.0);
	if (style == 0) {
		// grass: clumps, blade speckle and the odd tiny flower
		float blades = h21(floor(uv * 22.0));
		g *= 0.9 + 0.16 * blades + 0.08 * fine;
		g = mix(g, g * vec3(1.08, 1.12, 0.85), smoothstep(0.55, 0.75, mid) * 0.5);
		float fl = step(0.985, h21(floor(uv * 9.0) + 17.0));
		g = mix(g, accent, fl * 0.75 * smoothstep(0.2, 0.0, length(fract(uv * 9.0) - 0.5)));
	} else if (style == 1) {
		// mud: wet dark patches that shine
		float wet = smoothstep(0.5, 0.65, mid);
		g *= 0.85 + 0.2 * fine - 0.18 * wet;
		rough = mix(0.95, 0.25, wet);
	} else if (style == 2) {
		// snow: soft drifts and sparkles
		g = mix(g, vec3(0.97, 0.98, 1.0), 0.35 + 0.25 * mid);
		float sp = step(0.992, h21(floor(uv * 40.0)));
		emit += vec3(sp) * 0.6;
		rough = 0.7;
	} else if (style == 3) {
		// rock: strata and cracks
		vec2 c = cells(uv * 0.9);
		g *= 0.82 + 0.25 * mid - 0.25 * smoothstep(0.06, 0.0, c.y);
		g *= 0.92 + 0.12 * sin(wp.x * 0.7 + mid * 6.0);
	} else if (style == 4) {
		// tiled courtyard: square flagstones with grout
		vec2 tq = fract(uv * 0.5);
		float grout = smoothstep(0.04, 0.0, min(min(tq.x, 1.0 - tq.x), min(tq.y, 1.0 - tq.y)));
		g *= 0.9 + 0.12 * h21(floor(uv * 0.5)) - 0.3 * grout;
		rough = 0.6;
	} else if (style == 5) {
		// sand: wind ripples
		float rip = sin(uv.x * 3.0 + uv.y * 1.2 + mid * 5.0);
		g *= 0.9 + 0.08 * rip + 0.08 * fine;
	} else if (style == 6) {
		// ash: dark soil with glowing magma cracks
		vec2 c2 = cells(uv * 0.6);
		float crack = smoothstep(0.05, 0.0, c2.y) * smoothstep(0.35, 0.6, big);
		g *= 0.8 + 0.2 * fine;
		emit += accent * crack * (0.8 + 0.4 * sin(TIME * 1.5 + uv.x));
	} else if (style == 7) {
		// crystal: faceted glinting floor
		vec2 c3 = cells(uv * 0.7);
		g *= 0.8 + 0.4 * h21(floor(uv * 0.7 + c3.x));
		emit += accent * smoothstep(0.04, 0.0, c3.y) * 0.5;
		rough = 0.3;
	} else if (style == 8) {
		// marble: soft veins
		float vein = smoothstep(0.03, 0.0, abs(sin(uv.x * 0.6 + fbm(uv * 0.5) * 6.0)) - 0.02);
		g = mix(g, g * 0.75, vein * 0.6);
		rough = 0.35;
	} else if (style == 9) {
		// glass: mirror-smooth with faint cracks
		vec2 c4 = cells(uv * 0.35);
		g *= 0.92 + 0.15 * mid;
		g += vec3(smoothstep(0.03, 0.0, c4.y) * 0.25);
		rough = 0.12;
	} else if (style == 10) {
		// moss: soft dark cushions threaded with glowing mycelium that pulses slowly
		vec2 c5 = cells(uv * 0.8);
		float cushion = smoothstep(0.0, 0.5, c5.x);
		g *= 0.75 + 0.3 * cushion + 0.1 * fine;
		float thread = smoothstep(0.035, 0.0, c5.y) * smoothstep(0.3, 0.6, big);
		float pulse = 0.6 + 0.4 * sin(TIME * 1.2 + big * 12.0);
		emit += accent * thread * pulse * 0.9;
		float dots = step(0.97, h21(floor(uv * 6.0))) * smoothstep(0.25, 0.0, length(fract(uv * 6.0) - 0.5));
		emit += accent * dots * 0.8;
		rough = 0.8;
	} else if (style == 11) {
		// permafrost: wind-packed snow over blue ice, with frost cracks and the aurora's sheen
		vec2 c6 = cells(uv * 0.45);
		float ice = smoothstep(0.45, 0.7, mid);
		g = mix(g, vec3(0.96, 0.98, 1.0), 0.3 + 0.2 * big);
		g = mix(g, g * vec3(0.7, 0.85, 1.05), ice * 0.6);
		g -= vec3(0.15, 0.08, 0.0) * smoothstep(0.03, 0.0, c6.y) * ice;
		float sheen = smoothstep(0.6, 1.0, sin(uv.x * 0.15 + TIME * 0.2 + big * 5.0)) * ice;
		emit += vec3(0.2, 0.9, 0.6) * sheen * 0.12;
		float sp2 = step(0.993, h21(floor(uv * 40.0)));
		emit += vec3(sp2) * 0.5;
		rough = mix(0.7, 0.15, ice);
	} else if (style == 12) {
		// nebula glass: dark crystal floor with colours swirling far beneath it
		vec2 c7 = cells(uv * 0.3);
		float sw = fbm(uv * 0.12 + vec2(fbm(uv * 0.2 + TIME * 0.03), fbm(uv * 0.25 - TIME * 0.025)) * 2.0);
		vec3 neb = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + sw * 1.5 + TIME * 0.015));
		g = mix(g * 0.6, neb * 0.45, 0.35 + 0.3 * sw);
		emit += neb * smoothstep(0.55, 0.9, sw) * 0.35;
		g += vec3(smoothstep(0.025, 0.0, c7.y) * 0.1);
		rough = 0.2;
	}
	if (style == 13) {
		// autumn forest floor: two overlapping layers of fallen leaves, each leaf a pointed oval
		// with its own angle, size and colour (crimson, orange, gold, and brown where they have dried)
		float cover_k = smoothstep(0.25, 0.6, mid + 0.15);
		for (int L = 0; L < 2; L++) {
			float sc = L == 0 ? 2.1 : 3.4;
			vec2 q = uv * sc + float(L) * 17.3;
			vec2 id = floor(q);
			for (int yy = -1; yy <= 1; yy++) {
				for (int xx = -1; xx <= 1; xx++) {
					vec2 cid = id + vec2(float(xx), float(yy));
					vec2 rnd = h22(cid);
					if (h21(cid + 5.1) > 0.35 + 0.5 * (1.0 - cover_k)) { continue; }
					vec2 cen = cid + 0.2 + rnd * 0.6;
					float ang = h21(cid + 9.7) * 6.2831;
					vec2 d = q - cen;
					vec2 lp = vec2(cos(ang) * d.x + sin(ang) * d.y, -sin(ang) * d.x + cos(ang) * d.y);
					float len = 0.28 + 0.12 * rnd.x;
					float wid = 0.13 * (1.0 - abs(lp.x / len)) + 0.02;
					float inside = step(abs(lp.x), len) * smoothstep(wid, wid * 0.7, abs(lp.y));
					if (inside > 0.01) {
						float pk = h21(cid + 3.3);
						vec3 lc = pk < 0.3 ? vec3(0.78, 0.2, 0.08) : (pk < 0.6 ? vec3(0.92, 0.48, 0.12) : (pk < 0.85 ? vec3(0.9, 0.72, 0.22) : vec3(0.48, 0.3, 0.16)));
						lc *= 0.8 + 0.25 * rnd.y - 0.15 * smoothstep(0.02, 0.0, abs(lp.y));
						g = mix(g, lc, inside * 0.92);
					}
				}
			}
		}
		g = mix(g, g * vec3(0.8, 0.7, 0.6), smoothstep(0.6, 0.8, big) * 0.4);
	} else if (style == 14) {
		// fields of the Yellow Springs: dusky grass, fallen red petals, golden glints of spring water
		float petal = step(0.965, h21(floor(uv * 7.0) + 3.0)) * smoothstep(0.3, 0.0, length(fract(uv * 7.0) - 0.5));
		g = mix(g, vec3(0.85, 0.12, 0.08), petal * 0.85);
		float glint = smoothstep(0.62, 0.78, fbm(uv * 0.3 + TIME * 0.02)) * smoothstep(0.5, 0.7, mid);
		emit += vec3(1.0, 0.7, 0.25) * glint * 0.25;
	} else if (style == 15) {
		// underworld basalt: dark hexagonal flagstones split by cold blue ghost-fire
		vec2 c8 = cells(uv * 0.75);
		float seam = smoothstep(0.05, 0.0, c8.y);
		g *= 0.75 + 0.3 * h21(floor(uv * 0.75 + c8.x * 5.0)) + 0.1 * fine;
		g -= vec3(0.08) * seam;
		emit += accent * seam * smoothstep(0.4, 0.65, big) * (0.6 + 0.4 * sin(TIME * 2.0 + uv.y * 0.5));
		rough = 0.55;
	}
	// steep slopes shed their soil: bare, cracked rock shows through on hillsides
	float steep = smoothstep(0.93, 0.8, wn.y + (mid - 0.5) * 0.08);
	if (steep > 0.001 && style != 4 && style != 8) {
		vec2 cr = cells(uv * 1.3);
		vec3 rockc = mix(base, vec3(dot(base, vec3(0.33))), 0.6) * (0.78 + 0.3 * fine) - vec3(0.12) * smoothstep(0.05, 0.0, cr.y);
		g = mix(g, rockc, steep * 0.85);
		rough = mix(rough, 0.9, steep);
	}
	// fine relief: a noise gradient bends the normal so light catches clods, ripples and pebbles
	float e = 0.15;
	float hx = fbm(uv * 1.7 + vec2(e, 0.0)) - fbm(uv * 1.7 - vec2(e, 0.0));
	float hz = fbm(uv * 1.7 + vec2(0.0, e)) - fbm(uv * 1.7 - vec2(0.0, e));
	vec3 bump = vec3(-hx, 0.0, -hz) * (style == 9 || style == 12 ? 0.15 : 0.9);
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(bump, 0.0)).xyz);
	// paths: worn cobblestones blended in by vertex alpha with a ragged edge
	float pathk = smoothstep(0.55, 0.25, kind + (mid - 0.5) * 0.35);
	if (pathk > 0.001) {
		vec2 cb = cells(uv * 2.2);
		float stone = smoothstep(0.02, 0.12, cb.y);
		vec3 pc = mix(path_dark, base * (0.9 + 0.2 * h21(floor(uv * 2.2 + cb.x * 3.0))), stone);
		pc *= 0.92 + 0.1 * fine;
		g = mix(g, pc, pathk);
		rough = mix(rough, 0.85, pathk);
	}
	// drifting cloud shadows
	if (cloud_shadow > 0.0) {
		float cs = fbm(uv * 0.018 + vec2(TIME * 0.012, TIME * 0.005));
		g *= 1.0 - cloud_shadow * smoothstep(0.45, 0.7, cs) * 0.35;
	}
	ALBEDO = g;
	ROUGHNESS = rough;
	SPECULAR = 0.3;
	EMISSION = emit;
}
"""

const WATER := """
shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx, depth_draw_always;
uniform vec4 col : source_color = vec4(0.2, 0.4, 0.8, 0.8);
uniform vec3 deep : source_color = vec3(0.05, 0.1, 0.25);
uniform vec3 sky_top : source_color = vec3(0.3, 0.45, 0.8);
uniform vec3 sky_hor : source_color = vec3(0.8, 0.85, 0.95);
uniform float glow = 0.0;
varying vec3 wp;
varying float shore;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
// height of the water surface pattern: two scrolling noise layers crossing each other
float wave_h(vec2 p) {
	return n2(p * 1.4 + vec2(TIME * 0.32, TIME * 0.18)) * 0.6 + n2(p * 3.1 - vec2(TIME * 0.21, -TIME * 0.37)) * 0.4;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	shore = COLOR.a;
	VERTEX.y += sin(wp.x * 1.3 + TIME * 1.2) * 0.025 + sin(wp.z * 1.7 + TIME * 0.9) * 0.02;
}

void fragment() {
	vec2 uv = wp.xz;
	float e = 0.08;
	float hc = wave_h(uv);
	float hx = wave_h(uv + vec2(e, 0.0)) - hc;
	float hz = wave_h(uv + vec2(0.0, e)) - hc;
	vec3 wn = normalize(vec3(-hx * 5.0, 1.0, -hz * 5.0));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	// deeper water away from the shore, shallower and more see-through near it
	vec3 body = mix(deep, col.rgb, 0.3 + 0.35 * shore + 0.15 * hc);
	// reflected sky: horizon colour at grazing angles, zenith colour looking down
	vec3 refl = mix(sky_top, sky_hor, clamp(fres * 1.6, 0.0, 1.0));
	vec3 c = mix(body, refl, clamp(0.06 + fres * 0.55, 0.0, 0.6));
	// waves lapping at the shore: bands of foam running in towards the land
	float lap = sin(shore * 9.0 - TIME * 2.2 + n2(uv * 2.0) * 3.0);
	float foam = smoothstep(0.55, 0.95, shore) * smoothstep(0.2, 0.9, lap) * (0.6 + 0.4 * n2(uv * 6.0 + TIME));
	foam += smoothstep(0.88, 1.0, shore) * 0.5;
	// caustic glints where crests meet
	float glint = smoothstep(0.86, 0.95, hc + n2(uv * 7.0 + TIME * 0.6) * 0.25);
	c = mix(c, vec3(1.0), clamp(foam * 0.75, 0.0, 1.0));
	ALBEDO = c;
	ALPHA = clamp(col.a * (0.75 + 0.25 * (1.0 - shore)) + fres * 0.3 + foam * 0.3, 0.0, 1.0);
	ROUGHNESS = 0.04 + 0.1 * foam;
	METALLIC = 0.15;
	SPECULAR = 0.95;
	EMISSION = col.rgb * glow * (0.7 + 0.3 * hc) + vec3(glint * 0.35);
}
"""

static func _water_mat(col: Color, glow: float, sky: Array = []) -> ShaderMaterial:
	var key := "%s_%f_%s" % [col.to_html(), glow, str(sky)]
	if _water_mats.has(key):
		return _water_mats[key]
	var sh := Shader.new()
	sh.code = WATER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("col", Color(col.r, col.g, col.b, 0.8))
	m.set_shader_parameter("deep", col.darkened(0.7))
	m.set_shader_parameter("glow", glow)
	if sky.size() == 2:
		m.set_shader_parameter("sky_top", sky[0])
		m.set_shader_parameter("sky_hor", sky[1])
	_water_mats[key] = m
	return m

static func ground_mat(theme_name: String) -> ShaderMaterial:
	if _ground_mats.has(theme_name):
		return _ground_mats[theme_name]
	var th := Look.theme(theme_name)
	var sh := Shader.new()
	sh.code = GROUND
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("style", STYLE.get(th.tex, 0))
	m.set_shader_parameter("path_dark", Color(th.path).darkened(0.5))
	var acc := Color("ffe8f0")
	match th.tex:
		"ash":
			acc = Color("ff7020")
		"crystal":
			acc = Color("b080ff")
		"grass":
			acc = Color("ffd0e8") if theme_name != "bamboo" else Color("fff0a0")
		"moss":
			acc = Color("50ffd0")
		"permafrost":
			acc = Color("a0e8ff")
		"nebula":
			acc = Color("ff90e0")
		"leaves":
			acc = Color("e8602a")
		"lilyfield":
			acc = Color("ff3020")
		"underworld":
			acc = Color("40b0ff")
	m.set_shader_parameter("accent", acc)
	# cloud shadows only where there are clouds and a sun to cast them
	m.set_shader_parameter("cloud_shadow", clampf(float(th.clouds) * 1.2, 0.0, 1.0) if float(th.sun_e) > 0.8 else 0.0)
	_ground_mats[theme_name] = m
	return m

# ---------------------------------------------------------------- height field
## Heights at tile corners: (w+1) x (h+1).  Gentle hills from noise, mounds under landmarks,
## shores that slope down into the water and flattened paths.
static func heightmap(grid: PackedByteArray, w: int, h: int, theme_name: String, seed_: int) -> PackedFloat32Array:
	var th := Look.theme(theme_name)
	var amp: float = th.hill
	var noise := FastNoiseLite.new()
	noise.seed = seed_ * 7 + 3
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	# domain-warped broad swells: hills that meander instead of repeating on a grid
	var warp := FastNoiseLite.new()
	warp.seed = seed_ * 13 + 5
	warp.frequency = 0.03
	var broad := FastNoiseLite.new()
	broad.seed = seed_ * 3 + 11
	broad.frequency = 0.02
	broad.fractal_octaves = 2
	var swell := 0.0 if theme_name == "sect" else amp * 0.8
	var hm := PackedFloat32Array()
	hm.resize((w + 1) * (h + 1))
	for cz in h + 1:
		for cx in w + 1:
			var walls := 0
			var water := 0
			var paths := 0
			var cnt := 0
			for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
				var tx: int = cx + d.x
				var ty: int = cz + d.y
				if tx < 0 or ty < 0 or tx >= w or ty >= h:
					continue
				cnt += 1
				match grid[ty * w + tx]:
					MapGen.WALL:
						walls += 1
					MapGen.WATER:
						water += 1
					MapGen.PATH, MapGen.BUILDING:
						paths += 1
			var wx := cx + warp.get_noise_2d(cx, cz) * 6.0
			var wz := cz + warp.get_noise_2d(cz + 57.0, cx - 31.0) * 6.0
			var hv := noise.get_noise_2d(wx, wz) * amp + broad.get_noise_2d(cx, cz) * swell
			if paths > 0:
				hv *= 0.35
			hv += walls * 0.12 * (1.0 + amp)
			if water > 0:
				hv = -0.62 if water == cnt else minf(hv, -0.2)
				if paths >= 2:
					hv = 0.02  # a dry causeway where a path crosses water
			hm[cz * (w + 1) + cx] = hv
	return hm

## bilinear height at a world position
static func sample(hm: PackedFloat32Array, w: int, h: int, x: float, z: float) -> float:
	if hm.is_empty():
		return 0.0
	var fx := clampf(x / T, 0.0, float(w) - 0.001)
	var fz := clampf(z / T, 0.0, float(h) - 0.001)
	var ix := int(fx)
	var iz := int(fz)
	var ax := fx - ix
	var az := fz - iz
	var rw := w + 1
	var h00 := hm[iz * rw + ix]
	var h10 := hm[iz * rw + ix + 1]
	var h01 := hm[(iz + 1) * rw + ix]
	var h11 := hm[(iz + 1) * rw + ix + 1]
	return lerpf(lerpf(h00, h10, ax), lerpf(h01, h11, ax), az)

static func _corner_normal(hm: PackedFloat32Array, w: int, h: int, cx: int, cz: int) -> Vector3:
	var rw := w + 1
	var l := hm[cz * rw + maxi(cx - 1, 0)]
	var r := hm[cz * rw + mini(cx + 1, w)]
	var u := hm[maxi(cz - 1, 0) * rw + cx]
	var d := hm[mini(cz + 1, h) * rw + cx]
	return Vector3(l - r, 2.0 * T, u - d).normalized()

static func _tile_col(tile: int, tx: int, ty: int, th: Dictionary) -> Color:
	var hv := hash2(tx, ty)
	var patch := 0.5 + 0.5 * sin(tx * 0.31 + sin(ty * 0.23) * 2.0) * cos(ty * 0.27 + tx * 0.05)
	match tile:
		MapGen.PATH, MapGen.BUILDING:
			var pc: Color = Color(th.path).darkened(hv * 0.08)
			return Color(pc.r, pc.g, pc.b, 0.0)
		MapGen.WATER:
			var bed: Color = Color(th.water).darkened(0.55).lerp(Color(th.g1), 0.3)
			return Color(bed.r, bed.g, bed.b, 0.6)
		MapGen.WALL:
			var wc: Color = Color(th.g1).darkened(0.12)
			return Color(wc.r, wc.g, wc.b, 1.0)
	var gc: Color = Color(th.g1).lerp(Color(th.g2), patch).darkened(hv * 0.05)
	return Color(gc.r, gc.g, gc.b, 1.0)

## Corner colour: the average of the four touching tiles, then shaded by what is nearby.  Ground
## under a forest edge turns to darker, browner forest floor (leaf litter and shade); ground beside
## water is darker and richer (wet soil).
static func _corner_col(grid: PackedByteArray, w: int, h: int, cx: int, cz: int, th: Dictionary) -> Color:
	var acc := Color(0, 0, 0, 0)
	var n := 0
	var walls := 0
	var water := 0
	var paths := 0
	for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		var tx: int = clampi(cx + d.x, 0, w - 1)
		var ty: int = clampi(cz + d.y, 0, h - 1)
		var t := grid[ty * w + tx]
		acc += _tile_col(t, tx, ty, th)
		n += 1
		if t == MapGen.WALL:
			walls += 1
		elif t == MapGen.WATER:
			water += 1
		elif t == MapGen.PATH or t == MapGen.BUILDING:
			paths += 1
	var c := acc / float(n)
	var a := c.a
	if paths == 0:
		if walls > 0:
			var floor_col := Color(th.g1).darkened(0.32).lerp(Color("5a4630"), 0.25)
			c = c.lerp(floor_col, 0.16 * walls)
		if water > 0 and water < 4:
			c = c.darkened(0.12).lerp(Color(th.water).darkened(0.5), 0.12)
	c.a = a
	return c

# ---------------------------------------------------------------- main entry
## opts: "hm" (corner heights to use instead of this map's own), "open" (part of the open world:
## no skirt or horizon of its own), "buildings" (enterable buildings in local tiles), "area"
static func build(grid: PackedByteArray, w: int, h: int, theme_name: String, seed_: int, opts: Dictionary = {}) -> Node3D:
	var th := Look.theme(theme_name)
	var root := Node3D.new()
	root.name = "terrain_" + str(opts.get("area", theme_name))
	var hm: PackedFloat32Array = opts.hm if opts.has("hm") else heightmap(grid, w, h, theme_name, seed_)
	root.set_meta("hm", hm)
	root.set_meta("w", w)
	root.set_meta("h", h)
	var cw := int(ceil(w / float(CH)))
	var chh := int(ceil(h / float(CH)))
	var water_glow := 1.1 if theme_name in ["volcano", "time", "void", "origin", "abyss", "forge", "fungal", "chaos", "lilies", "diyu"] else 0.0
	var wmat := _water_mat(th.water, water_glow, [th.sky_top, th.sky_hor])
	var gmat := ground_mat(theme_name)
	var rw := w + 1
	# corner colours and normals are shared by the chunks
	var ccol: Array = []
	ccol.resize(rw * (h + 1))
	var cnrm: Array = []
	cnrm.resize(rw * (h + 1))
	for cz in h + 1:
		for cx in w + 1:
			ccol[cz * rw + cx] = _corner_col(grid, w, h, cx, cz, th)
			cnrm[cz * rw + cx] = _corner_normal(hm, w, h, cx, cz)
	for cy in chh:
		for cx in cw:
			var ground := MB.new()
			var water := MB.new()
			for ty in range(cy * CH, mini(h, (cy + 1) * CH)):
				for tx in range(cx * CH, mini(w, (cx + 1) * CH)):
					var tile := grid[ty * w + tx]
					if tile == MapGen.VOID:
						continue
					var x0 := tx * T
					var z0 := ty * T
					var i00 := ty * rw + tx
					var i10 := i00 + 1
					var i01 := i00 + rw
					var i11 := i01 + 1
					ground.quad_n(
						[Vector3(x0, hm[i00], z0), Vector3(x0 + T, hm[i10], z0), Vector3(x0 + T, hm[i11], z0 + T), Vector3(x0, hm[i01], z0 + T)],
						[cnrm[i00], cnrm[i10], cnrm[i11], cnrm[i01]],
						[ccol[i00], ccol[i10], ccol[i11], ccol[i01]])
					if tile == MapGen.WATER:
						var sh := _shore(grid, w, h, tx, ty)
						water.quad4(Vector3(x0, WATER_Y, z0), Vector3(x0 + T, WATER_Y, z0), Vector3(x0 + T, WATER_Y, z0 + T), Vector3(x0, WATER_Y, z0 + T),
							Color(1, 1, 1, sh[0]), Color(1, 1, 1, sh[1]), Color(1, 1, 1, sh[2]), Color(1, 1, 1, sh[3]))
					elif _by_water(grid, w, h, tx, ty):
						# the water plane runs on under the bank, so the shoreline is where the sloping
						# ground meets the water: a curve, not the edge of a square tile
						var fc := Color(1, 1, 1, 1)
						water.quad4(Vector3(x0, WATER_Y, z0), Vector3(x0 + T, WATER_Y, z0), Vector3(x0 + T, WATER_Y, z0 + T), Vector3(x0, WATER_Y, z0 + T), fc, fc, fc, fc)
			if not ground.is_empty():
				var gi := MB.mesh_node(root, ground.build(gmat))
				gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not water.is_empty():
				var wi := MB.mesh_node(root, water.build(wmat))
				wi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# trees, undergrowth, grass, rocks, landmarks: natural placement (see scatter.gd)
	Scatter.populate(root, grid, w, h, hm, theme_name, seed_)
	# stone bridges wherever a road crosses water
	_bridges(root, grid, w, h, hm)
	# birds, butterflies, dragonflies, fish... (see fauna.gd)
	Fauna.populate(root, grid, w, h, hm, theme_name, seed_)
	if not opts.get("open", false):
		_skirt(root, w, h, theme_name, seed_)
		_horizon(root, w, h, theme_name, seed_)
	var roofs := {}
	for bd in opts.get("buildings", []):
		roofs[bd.id] = _house(root, bd, hm, w, h)
	root.set_meta("roofs", roofs)
	if str(opts.get("area", theme_name)) == "sect":
		_sect_props(root, grid, w, h, hm)
	return root

static func _by_water(grid: PackedByteArray, w: int, h: int, tx: int, ty: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx := tx + dx
			var ny := ty + dy
			if nx >= 0 and ny >= 0 and nx < w and ny < h and grid[ny * w + nx] == MapGen.WATER:
				return true
	return false

# ---------------------------------------------------------------- the open world
## Corner heights for world rectangle `r`, written into the world's shared height field (so that
## neighbouring regions meet without a crack) and returned as the region's own (w+1)x(h+1) array.
## Hilliness blends smoothly between regions instead of stepping at the border.
static func world_heights(wd: Dictionary, r: Rect2i) -> PackedFloat32Array:
	var W: int = wd.w
	var H: int = wd.h
	var grid: PackedByteArray = wd.grid
	var owner: PackedByteArray = wd.owner
	var amp_of: Array = []
	var swell_of: Array = []
	for id in wd.ids:
		var spec: Dictionary = Data.AREAS[id]
		var a: float = float(spec.get("hill", Look.theme(spec.theme).hill))
		amp_of.append(a)
		swell_of.append(0.0 if id == "sect" else a * 0.8)
	var noise := FastNoiseLite.new()
	noise.seed = 77
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	var warp := FastNoiseLite.new()
	warp.seed = 135
	warp.frequency = 0.03
	var broad := FastNoiseLite.new()
	broad.seed = 244
	broad.frequency = 0.02
	broad.fractal_octaves = 2
	var out := PackedFloat32Array()
	out.resize((r.size.x + 1) * (r.size.y + 1))
	var ghm: PackedFloat32Array = wd.get("hm", PackedFloat32Array())
	for j in r.size.y + 1:
		for i in r.size.x + 1:
			var cx := r.position.x + i
			var cz := r.position.y + j
			var walls := 0
			var water := 0
			var paths := 0
			var cnt := 0
			for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
				var tx: int = cx + d.x
				var ty: int = cz + d.y
				if tx < 0 or ty < 0 or tx >= W or ty >= H:
					continue
				cnt += 1
				match grid[ty * W + tx]:
					MapGen.WALL:
						walls += 1
					MapGen.WATER:
						water += 1
					MapGen.PATH, MapGen.BUILDING, MapGen.INTERIOR:
						paths += 1
			var amp := 0.0
			var swell := 0.0
			for sy in [-5, 0, 5]:
				for sx in [-5, 0, 5]:
					var ox := clampi(cx + sx, 0, W - 1)
					var oy := clampi(cz + sy, 0, H - 1)
					var o := owner[oy * W + ox]
					amp += amp_of[o]
					swell += swell_of[o]
			amp /= 9.0
			swell /= 9.0
			var wx := cx + warp.get_noise_2d(cx, cz) * 6.0
			var wz := cz + warp.get_noise_2d(cz + 57.0, cx - 31.0) * 6.0
			var hv := noise.get_noise_2d(wx, wz) * amp + broad.get_noise_2d(cx, cz) * swell
			if paths > 0:
				hv *= 0.35
			hv += walls * 0.12 * (1.0 + amp)
			if water > 0:
				hv = -0.62 if water == cnt else minf(hv, -0.2)
				if paths >= 2:
					hv = 0.02
			out[j * (r.size.x + 1) + i] = hv
			if not ghm.is_empty():
				ghm[cz * (W + 1) + cx] = hv
	return out

## Rolling hills beyond the edge of the world and distant mountains on the horizon.
static func world_edge(root: Node3D, w: int, h: int) -> void:
	_skirt(root, w, h, "sect", 7)
	_horizon(root, w, h, "sect", 7)

## the sect's five-storey pagoda (stands on the mountain outside the courtyard wall)
static func pagoda(root: Node3D, pos: Vector3) -> void:
	var b := MB.new()
	var g := MB.new()
	Arch.pagoda(b, g, pos, 5)
	var mi := MB.mesh_node(root, b.build())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	MB.mesh_node(root, g.build(MB.mat_glow()))

## An enterable building: walls, door, floor and furniture as one mesh, the roof as another
## (returned, so the world can lift it away while the hero is inside).
static func _house(root: Node3D, bd: Dictionary, hm: PackedFloat32Array, w: int, h: int) -> Array:
	var r: Rect2i = bd.rect
	var rr := Rect2(r.position.x * T, r.position.y * T, r.size.x * T, r.size.y * T)
	var gy := sample(hm, w, h, rr.get_center().x, rr.get_center().y)
	var b := MB.new()
	var g := MB.new()
	var roof := MB.new()
	var roof_g := MB.new()
	var door := Vector3((bd.door.x + 0.5) * T, 0, (bd.door.y + 0.5) * T)
	var props: Array = []
	for pr in bd.get("props", []):
		props.append([pr[0], Vector3((pr[1].x + 0.5) * T, 0, (pr[1].y + 0.5) * T)])
	var lights := Arch.house(b, g, roof, roof_g, rr, door, str(bd.get("style", "house")), props, int(r.position.x * 7 + r.position.y))
	var mi := MB.mesh_node(root, b.build(MB.mat_scenery()))
	mi.position.y = gy
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not g.is_empty():
		var gi := MB.mesh_node(root, g.build(MB.mat_glow()))
		gi.position.y = gy
	var out: Array = []
	var ri := MB.mesh_node(root, roof.build(MB.mat_scenery()))
	ri.position.y = gy
	ri.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	out.append(ri)
	if not roof_g.is_empty():
		var rg := MB.mesh_node(root, roof_g.build(MB.mat_glow()))
		rg.position.y = gy
		out.append(rg)
	if DisplayServer.get_name() != "headless":
		for lt in lights:
			var l := OmniLight3D.new()
			l.light_color = lt[1]
			l.light_energy = 0.9
			l.omni_range = 6.0
			l.position = (lt[0] as Vector3) + Vector3(0, gy, 0)
			root.add_child(l)
	return out

## foam factor at each corner of a water tile (1 = touches land)
static func _shore(grid: PackedByteArray, w: int, h: int, tx: int, ty: int) -> Array:
	var out: Array = []
	for c in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		var land := 0.0
		for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			var nx: int = tx + c.x + d.x
			var ny: int = ty + c.y + d.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			if grid[ny * w + nx] != MapGen.WATER:
				land = 1.0
		out.append(land)
	return out

## endless rolling ground beyond the map border (a sea of clouds in the Sea of Clouds)
static func _skirt(root: Node3D, w: int, h: int, theme_name: String, seed_: int) -> void:
	var th := Look.theme(theme_name)
	var skirt := MB.new()
	var big := 140.0
	var n := 14
	var noise := FastNoiseLite.new()
	noise.seed = seed_ + 404
	noise.frequency = 0.012
	var x0 := -big
	var z0 := -big
	var x1 := w * T + big
	var z1 := h * T + big
	var cloud := theme_name == "cloudsea"
	var gm: Color = Color(th.g1).darkened(0.1)
	if cloud:
		gm = Color(0.95, 0.97, 1.0)
	var pts := {}
	for j in n + 1:
		for i in n + 1:
			var x := lerpf(x0, x1, i / float(n))
			var z := lerpf(z0, z1, j / float(n))
			# distance outside the playable rectangle
			var dx := maxf(maxf(-x, x - w * T), 0.0)
			var dz := maxf(maxf(-z, z - h * T), 0.0)
			var out := sqrt(dx * dx + dz * dz)
			var y := -0.05 - 0.4 * minf(out / 10.0, 1.0)
			# inside the playable rectangle the skirt drops well below the deepest pond bed: it used
			# to lie flat at -0.05 across the whole map, above the water (-0.12), hiding every pond,
			# lake and river under a sheet of grass
			if out <= 0.0:
				y = -2.0
			if not cloud:
				y += maxf(0.0, out - 12.0) * 0.06 * (1.0 + noise.get_noise_2d(x, z)) * (th.hill + 0.3)
			else:
				y = -3.0 + noise.get_noise_2d(x, z) * 1.5
			pts[Vector2i(i, j)] = Vector3(x, y, z)
	for j in n:
		for i in n:
			var p0: Vector3 = pts[Vector2i(i, j)]
			var p1: Vector3 = pts[Vector2i(i + 1, j)]
			var p2: Vector3 = pts[Vector2i(i + 1, j + 1)]
			var p3: Vector3 = pts[Vector2i(i, j + 1)]
			var nn := (p1 - p0).cross(p3 - p0).normalized()
			if nn.y < 0.0:
				nn = -nn
			var cc := Color(gm.r, gm.g, gm.b, 1.0)
			skirt.quad_n([p0, p1, p2, p3], [nn, nn, nn, nn], [cc, cc, cc, cc])
	var si := MB.mesh_node(root, skirt.build(ground_mat(theme_name) if not cloud else MB.mat_plain()))
	si.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if cloud:
		# billowing cloud banks around the floating island
		var cb := MB.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_
		for i in 70:
			var a := rng.randf() * TAU
			var r := rng.randf_range(0.6, 1.1) * maxf(w, h) * T * 0.75
			var c := Vector3(w * T * 0.5 + cos(a) * r, -2.0 + rng.randf() * 1.5, h * T * 0.5 + sin(a) * r)
			for k in 3:
				cb.sph(c + Vector3(rng.randf_range(-3, 3), rng.randf() * 1.0, rng.randf_range(-3, 3)), Vector3(4.0, 1.6, 3.2) * rng.randf_range(0.7, 1.3), MB.tag(Color(1, 1, 1), MB.CLOTH))
		var ci := MB.mesh_node(root, cb.build(MB.mat_plain()))
		ci.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## distant silhouettes in a ring around the map so the horizon is never empty
static func _horizon(root: Node3D, w: int, h: int, theme_name: String, seed_: int) -> void:
	var th := Look.theme(theme_name)
	var kind: String = th.horizon
	var b := MB.new()
	var g := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 3 + 1
	var cx := w * T * 0.5
	var cz := h * T * 0.5
	var base_r := maxf(w, h) * T * 0.5 + 70.0
	var far := Color(th.fog).lerp(Color(th.wall), 0.35)
	var cnt := 34
	for i in cnt:
		var a := TAU * i / cnt + rng.randf_range(-0.06, 0.06)
		var r := base_r + rng.randf_range(0.0, 40.0)
		var p := Vector3(cx + cos(a) * r, 0, cz + sin(a) * r)
		var s := rng.randf_range(0.7, 1.4)
		var col := MB.tag(far.darkened(rng.randf() * 0.15), MB.STONE)
		match kind:
			"peaks", "glacier", "crags":
				# a massif: a main peak with a lathe profile (concave flanks, sharp summit), a forest
				# band on its lower slopes, a snow cap and two shoulder peaks
				var hh := rng.randf_range(18.0, 40.0) * s
				var rr := hh * rng.randf_range(0.5, 0.7)
				var rock := MB.tag(far.lerp(Color(th.wall).darkened(0.3), 0.25).lerp(Color("7a7880"), 0.3).darkened(rng.randf() * 0.12), MB.STONE)
				b.lathe(p + Vector3(0, -2.0, 0), [Vector2(rr, 0.0), Vector2(rr * 0.62, hh * 0.25), Vector2(rr * 0.38, hh * 0.55), Vector2(rr * 0.16, hh * 0.85), Vector2(0.01, hh)], rock, 9)
				if kind != "crags":
					b.lathe(p + Vector3(0, -2.0 + hh * 0.66, 0), [Vector2(rr * 0.29, 0.0), Vector2(rr * 0.17, hh * 0.18), Vector2(0.01, hh * 0.345)], MB.tag(Color(0.96, 0.97, 1.0), MB.STONE), 9)
				if kind == "peaks":
					b.lathe(p + Vector3(0, -2.0, 0), [Vector2(rr * 1.03, 0.0), Vector2(rr * 0.75, hh * 0.15), Vector2(rr * 0.6, hh * 0.24)], MB.tag(Color(th.g1).darkened(0.35).lerp(far, 0.45), MB.FOLIAGE), 9)
				for k in 2:
					var off := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * rr * rng.randf_range(0.6, 0.9)
					var h2 := hh * rng.randf_range(0.45, 0.7)
					b.lathe(p + off + Vector3(0, -2.0, 0), [Vector2(h2 * 0.55, 0.0), Vector2(h2 * 0.3, h2 * 0.45), Vector2(h2 * 0.12, h2 * 0.85), Vector2(0.01, h2)], rock.darkened(0.06), 8)
			"hills", "dunes", "reef":
				b.sph(p + Vector3(0, -2.0, 0), Vector3(16.0, rng.randf_range(5.0, 12.0), 12.0) * s, col, Vector3(0, a, 0))
			"volcano":
				var vh := rng.randf_range(16.0, 30.0) * s
				b.prim("fr8", MB._xf(p + Vector3(0, vh * 0.5 - 2.0, 0), Vector3(vh * 1.4, vh, vh * 1.4), Vector3.ZERO), col)
				if i % 4 == 0:
					g.ball(p + Vector3(0, vh - 2.0, 0), 3.0 * s, Color(1.0, 0.45, 0.1, 0.6), true)
			"towers", "palace":
				var tw := rng.randf_range(10.0, 26.0) * s
				b.box(p + Vector3(0, tw * 0.5 - 2.0, 0), Vector3(4.0, tw, 4.0) * Vector3(s, 1, s), col, Vector3(0, a, 0))
				b.cone(p + Vector3(0, tw - 1.0, 0), 4.0 * s, 4.0, col.darkened(0.1), Vector3(0, PI / 4 + a, 0), 4)
				if kind == "towers" and i % 3 == 0:
					g.ball(p + Vector3(0, tw * 0.7, 0), 1.0, Color(1.0, 0.2, 0.3, 0.7), true)
			"islands":
				var y := rng.randf_range(8.0, 30.0)
				var ir := rng.randf_range(4.0, 9.0) * s
				b.cone(p + Vector3(0, y - ir * 0.5, 0), ir, ir * 1.6, col, Vector3(PI, rng.randf() * TAU, 0), 6)
				b.cyl(p + Vector3(0, y + 0.3, 0), ir, 0.6, MB.tag(Color(th.g2).lerp(far, 0.4), MB.FOLIAGE), Vector3.ZERO, 8)
			"pillars":
				# Part V: the land under the sky's great pillars (dunes, glaciers or drifting islands)
				if theme_name == "chaos":
					var yc := rng.randf_range(4.0, 30.0)
					var rc := rng.randf_range(4.0, 10.0) * s
					b.cone(p + Vector3(0, yc - rc * 0.5, 0), rc, rc * 1.8, col, Vector3(PI, rng.randf() * TAU, 0), 6)
					g.ball(p + Vector3(0, yc - rc * 0.6, 0), rc * 0.3, Color(1.0, 0.5, 0.8, 0.25), true)
				elif theme_name == "aurora":
					var gh := rng.randf_range(16.0, 34.0) * s
					b.cone(p + Vector3(0, gh * 0.5 - 2.0, 0), gh * 0.65, gh, col, Vector3(0, rng.randf() * TAU, 0), 5)
					b.cone(p + Vector3(0, gh * 0.85 - 2.0, 0), gh * 0.22, gh * 0.32, MB.tag(Color(0.95, 0.97, 1.0), MB.STONE), Vector3(0, rng.randf() * TAU, 0), 5)
				else:
					b.sph(p + Vector3(0, -3.0, 0), Vector3(22.0, rng.randf_range(6.0, 13.0), 14.0) * s, col, Vector3(0, a, 0))
			"mushrooms":
				var mh := rng.randf_range(14.0, 34.0) * s
				var mr := mh * rng.randf_range(0.35, 0.55)
				b.cyl(p + Vector3(0, mh * 0.5 - 2.0, 0), mh * 0.08, mh, col, Vector3.ZERO, 8)
				b.prim("hemi", MB._xf(p + Vector3(0, mh - 2.5, 0), Vector3(mr * 2.0, mr * 0.9, mr * 2.0), Vector3.ZERO), MB.tag(Color(th.wall).lerp(far, 0.55), MB.CLOTH))
				g.disc(p + Vector3(0, mh - 2.6, 0), mr * 0.8, Color(0.4, 1.0, 0.8, 0.25), 12, Color(0.4, 1.0, 0.8, 0.0))
			# ---- Part VI
			"maples":
				# wooded ridges in autumn colours, crowns lit red and gold above the haze
				b.sph(p + Vector3(0, -3.0, 0), Vector3(18.0, rng.randf_range(7.0, 14.0), 13.0) * s, col, Vector3(0, a, 0))
				for k in 5:
					var ta := a + rng.randf_range(-0.5, 0.5)
					var tp := p + Vector3(cos(ta) * rng.randf_range(-10, 10), rng.randf_range(2.0, 7.0) * s, sin(ta) * rng.randf_range(-8, 8))
					var ac: Color = [Color("d8582a"), Color("e89a38"), Color("c8402a"), Color("b8a040")][(i + k) % 4]
					b.sph(tp, Vector3(3.0, 2.4, 3.0) * rng.randf_range(0.7, 1.3), MB.tag(ac.lerp(far, 0.45), MB.FOLIAGE), Vector3.ZERO, true)
				if i % 9 == 0:
					g.box(p + Vector3(0, 6.0, -2.0), Vector3(1.6, 18.0, 0.2), Color(0.85, 0.95, 1.0, 0.35), Vector3(0, a, 0))
			"karst":
				# towers of limestone standing in the mist like a forest of stone
				var kh := rng.randf_range(16.0, 46.0) * s
				var kr := kh * rng.randf_range(0.14, 0.22)
				var lime := MB.tag(far.lerp(Color("c8c8c0"), 0.25).darkened(rng.randf() * 0.1), MB.STONE)
				b.lathe(p + Vector3(0, -3.0, 0), [Vector2(kr * 1.3, 0.0), Vector2(kr, kh * 0.25), Vector2(kr * 0.95, kh * 0.6), Vector2(kr * 0.75, kh * 0.88), Vector2(kr * 0.35, kh), Vector2(0.01, kh * 1.02)], lime, 8)
				b.sph(p + Vector3(0, kh - 3.2, 0), Vector3(kr * 0.6, kr * 0.25, kr * 0.6), MB.tag(Color("5a8a5a").lerp(far, 0.5), MB.FOLIAGE), Vector3.ZERO, true)
				if i % 2 == 0:
					var p2 := p + Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))
					var kh2 := kh * rng.randf_range(0.4, 0.7)
					b.lathe(p2 + Vector3(0, -3.0, 0), [Vector2(kr, 0.0), Vector2(kr * 0.8, kh2 * 0.7), Vector2(kr * 0.3, kh2), Vector2(0.01, kh2 * 1.02)], lime, 7)
			"bridge":
				# low dusk hills under a lantern-lit sky; the Naihe Bridge is added after the ring
				b.sph(p + Vector3(0, -2.5, 0), Vector3(16.0, rng.randf_range(4.0, 9.0), 12.0) * s, col, Vector3(0, a, 0))
				if i % 5 == 0:
					g.ball(p + Vector3(0, rng.randf_range(6.0, 14.0), 0), 0.9, Color(1.0, 0.6, 0.3, 0.6), true)
			"wheel":
				# pagodas and judgement towers of the Ten Courts, lit by ghost-fire
				var ph := rng.randf_range(12.0, 26.0) * s
				for k in 4:
					var pw := (4.0 - k * 0.7) * s
					b.box(p + Vector3(0, -2.0 + ph * (k + 0.5) / 4.0, 0), Vector3(pw, ph / 4.0 * 0.8, pw), col, Vector3(0, a, 0))
					b.prim("cone4", MB._xf(p + Vector3(0, -2.0 + ph * (k + 1) / 4.0, 0), Vector3(pw * 2.2, 1.4, pw * 2.2), Vector3(0, a + PI / 4, 0)), col.darkened(0.15))
				if i % 3 == 0:
					g.ball(p + Vector3(0, ph * 0.7, 0), 1.2, Color(0.3, 0.7, 1.0, 0.6), true)
			_:
				b.sph(p + Vector3(0, -2.0, 0), Vector3(14.0, 8.0, 10.0) * s, col)
	if kind == "bridge":
		_naihe_bridge(b, g, cx, cz, base_r + 30.0, far)
	if kind == "wheel":
		_great_wheel(b, g, cx, cz, base_r + 80.0, far)
	if kind == "pillars":
		_sky_pillars(b, g, cx, cz, base_r + 90.0, theme_name)
	var mi := MB.mesh_node(root, b.build(MB.mat_plain()))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow()))

## The four pillars that hold up the sky (Part V): banded stone columns rising out of sight, ringed
## with glowing seams in the five colours of Nuwa's stones.  One stands on each side of the map.
static func _sky_pillars(b: MB, g: MB, cx: float, cz: float, r: float, theme_name: String) -> void:
	var th := Look.theme(theme_name)
	var stone := Color(th.fog).lerp(Color(th.wall), 0.25).darkened(0.1)
	var five := [Color("ff5050"), Color("ffd040"), Color("50a0ff"), Color("f0f0ff"), Color("b070ff")]
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var p := Vector3(cx + cos(a) * r, 0, cz + sin(a) * r)
		var rad := 9.0
		b.lathe(p + Vector3(0, -4.0, 0), [Vector2(rad * 1.8, 0.0), Vector2(rad * 1.3, 6.0), Vector2(rad, 12.0), Vector2(rad * 0.95, 160.0), Vector2(rad * 1.15, 175.0), Vector2(rad * 1.05, 190.0)], MB.tag(stone, MB.STONE), 12)
		for k in 6:
			var y := 24.0 + k * 24.0
			var c: Color = five[(k + i) % 5]
			b.cyl(p + Vector3(0, y, 0), rad * 1.06, 2.0, MB.tag(stone.darkened(0.2), MB.STONE), Vector3.ZERO, 12)
			g.cyl(p + Vector3(0, y, 0), rad * 1.09, 0.6, Color(c.r, c.g, c.b, 0.55), Vector3.ZERO, 12)

## Part VI: the Naihe Bridge, a long humped stone bridge over the golden spring, lanterns on its rail.
static func _naihe_bridge(b: MB, g: MB, cx: float, cz: float, r: float, far: Color) -> void:
	var c := Vector3(cx + r * 0.7, 0, cz - r * 0.7)
	var axis := Vector3(1, 0, 1).normalized()
	var stone := MB.tag(far.lerp(Color("8a7a70"), 0.35), MB.STONE)
	var n := 24
	for i in n + 1:
		var t := i / float(n) * 2.0 - 1.0
		var p := c + axis * t * 42.0 + Vector3(0, 9.0 * (1.0 - t * t) + 1.0, 0)
		b.box(p, Vector3(4.2, 1.2, 6.0), stone, Vector3(0, -PI / 4, 0))
		if i % 4 == 0:
			g.ball(p + Vector3(0, 2.2, 0), 0.7, Color(1.0, 0.55, 0.25, 0.75), true)
	for k in 5:
		var t2 := (k / 4.0) * 1.6 - 0.8
		var pp := c + axis * t2 * 42.0
		b.box(pp + Vector3(0, 0.5, 0), Vector3(2.4, 8.0 * (1.0 - t2 * t2) + 1.5, 2.4), stone.darkened(0.1), Vector3(0, -PI / 4, 0))

## Part VI: the Wheel of the Six Paths, standing on the horizon taller than the clouds.
static func _great_wheel(b: MB, g: MB, cx: float, cz: float, r: float, far: Color) -> void:
	var c := Vector3(cx - r * 0.6, 0, cz - r * 0.8)
	var rad := 70.0
	var yaw := atan2(cx - c.x, cz - c.z)
	var bs := Basis(Vector3.UP, yaw)
	var stone := MB.tag(far.lerp(Color("4a4a60"), 0.35), MB.STONE)
	var hub := c + Vector3(0, rad + 4.0, 0)
	var segs := 36
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var p0 := hub + bs * Vector3(cos(a0) * rad, sin(a0) * rad, 0)
		var p1 := hub + bs * Vector3(cos(a1) * rad, sin(a1) * rad, 0)
		b.limb(p0, p1, 3.2, 3.2, stone, 6)
	for k in 6:
		var ak := TAU * k / 6.0
		b.limb(hub, hub + bs * Vector3(cos(ak) * rad, sin(ak) * rad, 0), 2.2, 1.6, stone, 6)
		g.ball(hub + bs * Vector3(cos(ak) * rad, sin(ak) * rad, 0), 4.0, Color(0.35, 0.65, 1.0, 0.55), true)
	b.cyl(hub, 7.0, 6.0, stone.darkened(0.15), bs.get_euler() + Vector3(PI / 2, 0, 0), 12)
	g.ball(hub, 9.0, Color(0.4, 0.75, 1.0, 0.35), true)

static func _add_mm(root: Node3D, mesh: Mesh, xf: Array, cols: Array, shadow: bool, vis_end: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = vis_end
	mi.visibility_range_end_margin = 6.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	root.add_child(mi)

# ---------------------------------------------------------------- landmark prototypes
static func _proto(key: String, theme_name: String) -> Mesh:
	if _protos.has(key):
		return _protos[key]
	var th := Look.theme(theme_name)
	var parts := key.split(":")
	var b := MB.new()
	b.ao_floor = 0.0
	b.ao_height = 1.2
	b.ao_strength = 0.35
	var wc: Color = th.wall
	var glow := MB.new()
	var mat: Material = null
	# a Blender-built landmark (art/props) replaces the first procedural variant when present
	if parts[0] == "wall" and Assets.has("props/" + str(th.tree)):
		var pm := MB.as_scenery(Assets.static_mesh("props/" + str(th.tree)))
		_protos[key] = pm
		return pm
	match parts[0]:
		"wall":
			_build_landmark(b, glow, th.tree, wc, th, 0)
		"wall2":
			_build_landmark(b, glow, th.tree, wc, th, 1)
		"decor":
			_build_decor(b, glow, th.decor, th)
			mat = MB.mat_plain()
		"tuft":
			_build_tuft(b, glow, th.tuft, th)
			mat = MB.mat_plain()
		"rock":
			_build_rock(b, th)
		"lily":
			b.disc(Vector3(0, 0.0, 0), 0.42, MB.tag(Color("3f9a5a"), MB.FOLIAGE), 14, MB.tag(Color("2a7a40"), MB.FOLIAGE))
			b.disc(Vector3(0.5, 0.0, 0.3), 0.26, MB.tag(Color("4aa866"), MB.FOLIAGE), 12, MB.tag(Color("2a7a40"), MB.FOLIAGE))
			for i in 8:
				var a := TAU * i / 8.0
				b.leaf(Vector3(0, 0.05, 0), Vector3(cos(a) * 0.2, 0.2, sin(a) * 0.2), 0.08, MB.tag(Color("ffc0dc"), MB.CLOTH), Vector3(-sin(a), 0, cos(a)), MB.tag(Color("ff7ab0"), MB.CLOTH))
			b.ball(Vector3(0, 0.1, 0), 0.05, MB.tag(Color("ffe070"), MB.CLOTH), true)
			glow.ball(Vector3(0, 0.12, 0), 0.25, Color(1.0, 0.7, 0.85, 0.25), true)
			mat = MB.mat_plain()
	if b.is_empty():
		b.ball(Vector3(0, -10, 0), 0.01, Color(0, 0, 0))
	var mesh := b.build(mat if mat != null else MB.mat_scenery())
	glow.add_to(mesh, MB.mat_glow())
	_protos[key] = mesh
	return mesh

## Shrub / pine / leafy canopy: overlapping foliage blobs around a point.
static func _canopy(b: MB, c: Vector3, r: float, col: Color, n: int = 6, seed_f: float = 0.0) -> void:
	b.sph_hi(c, Vector3(r, r * 0.8, r), MB.tag(col, MB.FOLIAGE))
	for i in n:
		var a := TAU * i / n + seed_f
		var off := Vector3(cos(a) * r * 0.65, sin(i * 1.7 + seed_f) * r * 0.25, sin(a) * r * 0.65)
		b.sph(c + off, Vector3.ONE * r * (0.55 + 0.15 * sin(i + seed_f)), MB.tag(col.lightened(0.06 * (i % 3)), MB.FOLIAGE))

static func _build_landmark(b: MB, g: MB, kind: String, wc: Color, th: Dictionary, variant: int) -> void:
	var dark := wc.darkened(0.4)
	var light := wc.lightened(0.3)
	var bark := MB.tag(Color("6a4a2a"), MB.WOOD)
	var stone := MB.tag(wc, MB.STONE)
	var v := variant
	match kind:
		"pine":
			if v == 0:
				b.limb(Vector3(0, -0.1, 0), Vector3(0.05, 2.0, 0), 0.16, 0.06, bark, 8)
				for i in 5:
					var y := 0.9 + i * 0.5
					var r := 0.95 - i * 0.16
					b.cone(Vector3(0, y, 0), r, 0.9, MB.tag(wc.lightened(0.05 * i), MB.FOLIAGE), Vector3(0, i * 0.7, 0), 8)
					b.cone(Vector3(0, y - 0.2, 0), r * 1.05, 0.25, MB.tag(dark, MB.FOLIAGE), Vector3(0, i * 0.7 + 0.3, 0), 8)
				b.cone(Vector3(0, 3.3, 0), 0.2, 0.6, MB.tag(light, MB.FOLIAGE))
			else:
				# windswept mountain pine with flat cloud-like pads
				b.limb(Vector3(0, -0.1, 0), Vector3(0.4, 1.4, 0.1), 0.18, 0.1, bark, 8)
				b.limb(Vector3(0.4, 1.4, 0.1), Vector3(-0.2, 2.3, 0.0), 0.1, 0.05, bark, 8)
				b.limb(Vector3(0.3, 1.2, 0.1), Vector3(1.1, 1.6, 0.2), 0.07, 0.03, bark, 6)
				for p in [Vector3(-0.2, 2.45, 0.0), Vector3(1.15, 1.75, 0.2), Vector3(0.3, 1.9, -0.4), Vector3(-0.5, 1.6, 0.4)]:
					b.sph(p, Vector3(0.7, 0.22, 0.55), MB.tag(wc, MB.FOLIAGE))
					b.sph(p + Vector3(0, 0.12, 0), Vector3(0.5, 0.16, 0.4), MB.tag(light, MB.FOLIAGE))
		"bamboo":
			var stalks := 5 if v == 0 else 3
			for i in stalks:
				var a := i * 1.256 + v * 0.5
				var px := cos(a) * 0.32
				var pz := sin(a) * 0.32
				var hh := 4.0 + (i % 3) * 0.7 - v * 0.8
				var top := Vector3(px + pz * 0.15, hh, pz - px * 0.15)
				b.limb(Vector3(px, 0, pz), top, 0.07, 0.05, MB.tag(wc.lerp(Color("c8e070"), 0.25), MB.WOOD), 8)
				for k in range(1, 6):
					var p := Vector3(px, 0, pz).lerp(top, k / 6.0)
					b.cyl(p, 0.078, 0.05, MB.tag(wc.darkened(0.3), MB.WOOD), Vector3.ZERO, 8)
					if k >= 3:
						for lf in 3:
							var la := a + lf * 2.1 + k
							b.leaf(p, p + Vector3(cos(la) * 0.7, -0.15, sin(la) * 0.7), 0.09, MB.tag(light, MB.FOLIAGE), Vector3.UP, MB.tag(wc.lightened(0.15), MB.FOLIAGE))
			if v == 1:
				for i in 4:
					var a2 := TAU * i / 4.0
					b.cone(Vector3(cos(a2) * 0.6, 0.15, sin(a2) * 0.6), 0.08, 0.3, MB.tag(Color("a8c060"), MB.WOOD), Vector3.ZERO, 6)
		"mangrove":
			b.limb(Vector3(0, 0.6, 0), Vector3(0.1, 2.6, 0.15), 0.22, 0.14, MB.tag(Color("4a3a30"), MB.WOOD), 8)
			for i in 5:
				var a2 := i * 1.26 + 0.4
				b.limb(Vector3(cos(a2) * 0.9, -0.05, sin(a2) * 0.9), Vector3(cos(a2) * 0.15, 1.0, sin(a2) * 0.15), 0.06, 0.1, MB.tag(Color("3a2c26"), MB.WOOD), 6)
			_canopy(b, Vector3(0, 2.8, 0), 1.0 if v == 0 else 0.8, Color("4a5a3a"), 6, v * 1.3)
			for i in 6:
				var a3 := i * 1.05
				var top := Vector3(cos(a3) * 0.9, 2.5, sin(a3) * 0.9)
				b.ribbon([top, top + Vector3(0.05, -0.6, 0), top + Vector3(0, -1.2, 0.05)], [0.05, 0.04, 0.01], Vector3(cos(a3 + 1.5), 0, sin(a3 + 1.5)), MB.tag(Color("6a7a4a"), MB.FOLIAGE))
			g.ball(Vector3(0.6, 1.4, 0.5), 0.06, Color(0.7, 1.0, 0.5, 0.9), true)
		"ice":
			b.sph(Vector3(0, 0.12, 0), Vector3(0.9, 0.28, 0.85), MB.tag(Color("f0f6ff"), MB.STONE))
			var ic := MB.tag(wc.lightened(0.25), MB.CRYSTAL)
			if v == 0:
				b.crystal(Vector3(0, 0.6, 0), 0.4, 3.0, ic, Vector3(0.05, 0, 0.08), 6)
				b.crystal(Vector3(0.45, 0.4, 0.1), 0.28, 1.9, MB.tag(wc.lightened(0.45), MB.CRYSTAL), Vector3(0.1, 0, -0.4), 6)
				b.crystal(Vector3(-0.4, 0.35, -0.1), 0.26, 1.6, MB.tag(wc, MB.CRYSTAL), Vector3(-0.1, 0, 0.45), 6)
			else:
				for i in 6:
					var a := TAU * i / 6.0
					b.crystal(Vector3(cos(a) * 0.4, 0.3, sin(a) * 0.4), 0.18, 1.2 + (i % 3) * 0.4, MB.tag(wc.lightened(0.2 + 0.1 * (i % 2)), MB.CRYSTAL), Vector3(sin(a) * 0.4, 0, -cos(a) * 0.4), 6)
			b.sph(Vector3(0.3, 0.3, 0.4), Vector3(0.35, 0.2, 0.3), MB.tag(Color("ffffff"), MB.STONE))
			g.cone(Vector3(0, 1.6, 0), 0.5, 3.0, Color(0.7, 0.9, 1.0, 0.1), Vector3(0.05, 0, 0.08), 6)
		"crag":
			var rk := MB.tag(wc, MB.STONE)
			if v == 0:
				b.box(Vector3(0, 0.6, 0), Vector3(1.3, 1.2, 1.1), rk, Vector3(0, 0.3, 0))
				b.box(Vector3(0.1, 1.5, 0), Vector3(0.9, 1.2, 0.8), MB.tag(wc.lightened(0.1), MB.STONE), Vector3(0.1, 0.8, 0.1))
				b.box(Vector3(-0.1, 2.3, 0.05), Vector3(0.5, 0.9, 0.5), MB.tag(wc.lightened(0.18), MB.STONE), Vector3(-0.1, 1.2, 0.15))
			else:
				for i in 4:
					b.prim("cyl6", MB._xf(Vector3((i - 1.5) * 0.35, 0.8 + (i % 2) * 0.5, (i % 2) * 0.3), Vector3(0.45, 1.6 + (i % 3) * 0.8, 0.45), Vector3(0, i * 0.4, (i - 1.5) * 0.06)), MB.tag(wc.lightened(0.05 * i), MB.STONE))
			b.limb(Vector3(0.0, 1.0, 0.56), Vector3(0.2, 0.2, 0.58), 0.02, 0.01, MB.tag(Color("3a3848"), MB.STONE), 4)
			g.box(Vector3(0.0, 1.0, 0.58), Vector3(0.05, 0.9, 0.03), Color(0.7, 0.8, 1.0, 0.9), Vector3(0, 0, 0.3))
			g.ball(Vector3(0.0, 1.5, 0.58), 0.12, Color(0.7, 0.8, 1.0, 0.6), true)
		"obelisk":
			b.box(Vector3(0, 0.15, 0), Vector3(1.3, 0.3, 1.3), MB.tag(dark, MB.STONE))
			b.box(Vector3(0, 0.38, 0), Vector3(1.05, 0.16, 1.05), MB.tag(dark.lightened(0.1), MB.STONE))
			if v == 0:
				b.prim("fr8", MB._xf(Vector3(0, 1.9, 0), Vector3(0.9, 3.0, 0.9), Vector3(0, PI / 4, 0)), MB.tag(wc.lightened(0.05), MB.STONE))
				b.cone(Vector3(0, 3.65, 0), 0.32, 0.5, MB.tag(wc.lightened(0.15), MB.STONE), Vector3.ZERO, 4)
				for k in 3:
					g.box(Vector3(0, 1.2 + k * 0.6, 0.41 - k * 0.04), Vector3(0.2, 0.04, 0.02), Color(1.0, 0.25, 0.3, 0.9))
				g.ball(Vector3(0, 4.2, 0), 0.18, Color(1.0, 0.25, 0.3, 1.0), true)
				g.ball(Vector3(0, 4.2, 0), 0.4, Color(1.0, 0.2, 0.3, 0.3), true)
			else:
				# broken pillar with a skull brazier
				b.cyl(Vector3(0, 1.1, 0), 0.38, 1.6, MB.tag(wc.lightened(0.05), MB.STONE), Vector3(0.05, 0, 0.04), 8)
				b.cone(Vector3(0.05, 2.0, 0), 0.38, 0.3, MB.tag(wc.lightened(0.1), MB.STONE), Vector3(0.3, 0, 0.5), 8)
				b.lathe(Vector3(0, 2.0, 0), [Vector2(0.15, 0.0), Vector2(0.35, 0.15), Vector2(0.38, 0.25)], MB.tag(Color("2a1a1a"), MB.METAL), 10)
				g.ball(Vector3(0, 2.4, 0), 0.25, Color(1.0, 0.3, 0.2, 0.8), true)
		"coral":
			var cols := [Color("ff7a8a"), Color("ffa05a"), Color("5ae0c8"), Color("c88aff")]
			var nbr := 6 if v == 0 else 4
			for i in nbr:
				var a4 := i * 1.05 + v
				var cc: Color = cols[(i + v) % 4]
				var tip := Vector3(cos(a4) * 0.7, 1.6 - (i % 3) * 0.3, sin(a4) * 0.7)
				b.limb(Vector3(cos(a4) * 0.15, 0.1, sin(a4) * 0.15), tip, 0.13, 0.06, MB.tag(cc, MB.STONE), 6)
				b.limb(tip * 0.6 + Vector3(0, 0.3, 0), tip * 0.6 + Vector3(cos(a4 + 1) * 0.4, 0.9, sin(a4 + 1) * 0.4), 0.06, 0.03, MB.tag(cc.lightened(0.1), MB.STONE), 6)
				b.ball(tip, 0.12, MB.tag(cc.lightened(0.25), MB.STONE), true)
			if v == 1:
				b.hemi(Vector3(0, 0.0, 0), Vector3(0.9, 0.6, 0.9), MB.tag(Color("e8a0b0"), MB.STONE))
			b.sph(Vector3(0, 0.15, 0), Vector3(0.9, 0.3, 0.9), MB.tag(Color("a8906a"), MB.STONE))
			for i in 5:
				g.ball(Vector3(cos(i * 1.3) * 0.5, 0.5 + i * 0.25, sin(i * 1.3) * 0.5), 0.05, Color(0.5, 1.0, 0.9, 0.8), true)
		"spire":
			var sc := MB.tag(wc.lightened(0.05), MB.STONE)
			if v == 0:
				b.cone(Vector3(0, 1.6, 0), 0.7, 3.2, sc, Vector3(0.05, 0, 0.04), 8)
				b.cone(Vector3(0.7, 0.9, 0.2), 0.4, 1.8, MB.tag(wc, MB.STONE), Vector3(0, 0, -0.3), 8)
				b.cone(Vector3(-0.6, 0.7, -0.2), 0.35, 1.4, MB.tag(wc.darkened(0.1), MB.STONE), Vector3(0, 0, 0.35), 8)
			else:
				b.prim("fr8", MB._xf(Vector3(0, 0.9, 0), Vector3(1.8, 1.8, 1.8), Vector3.ZERO), sc)
				b.disc(Vector3(0, 1.81, 0), 0.48, MB.tag(Color("ff8020"), MB.CRYSTAL), 10)
				g.ball(Vector3(0, 2.0, 0), 0.6, Color(1.0, 0.5, 0.1, 0.45), true)
			g.box(Vector3(0.0, 0.8, 0.5), Vector3(0.1, 1.3, 0.04), Color(1.0, 0.5, 0.1, 0.95), Vector3(0.1, 0, 0.1))
			g.box(Vector3(0.3, 1.8, 0.2), Vector3(0.07, 0.9, 0.04), Color(1.0, 0.6, 0.15, 0.9), Vector3(0, 0.6, 0.2))
		"shard":
			b.box(Vector3(0, 0.15, 0), Vector3(0.9, 0.3, 0.9), MB.tag(dark, MB.STONE), Vector3(0, 0.5, 0))
			if v == 0:
				b.crystal(Vector3(0, 1.45, 0), 0.5, 2.6, MB.tag(Color("8a5ae8"), MB.CRYSTAL), Vector3.ZERO, 4)
			else:
				for i in 3:
					b.crystal(Vector3((i - 1) * 0.35, 1.1 + (i % 2) * 0.4, 0), 0.25, 1.8, MB.tag(Color("a070ff").lerp(Color("6a3ac8"), i * 0.4), MB.CRYSTAL), Vector3(0, 0, (i - 1) * 0.3), 4)
			g.cone(Vector3(0, 2.3, 0), 0.62, 1.6, Color(0.7, 0.5, 1.0, 0.18), Vector3.ZERO, 4)
			for i in 4:
				g.ball(Vector3(cos(i * 1.6) * 0.7, 1.0 + i * 0.5, sin(i * 1.6) * 0.7), 0.06, Color(0.85, 0.7, 1.0, 0.9), true)
		"column":
			var mar := MB.tag(Color("f8f4ff"), MB.STONE)
			var gold := MB.tag(Color("e8c860"), MB.METAL)
			b.box(Vector3(0, 0.15, 0), Vector3(1.0, 0.3, 1.0), MB.tag(Color("f2eefc"), MB.STONE))
			var hh2 := 3.0 if v == 0 else 1.8
			b.cyl(Vector3(0, 0.3 + hh2 * 0.5, 0), 0.3, hh2, mar, Vector3.ZERO, 14)
			for k in 8:
				var a6 := TAU * k / 8.0
				b.cyl(Vector3(cos(a6) * 0.29, 0.3 + hh2 * 0.5, sin(a6) * 0.29), 0.03, hh2, MB.tag(Color("e8e4f0"), MB.STONE), Vector3.ZERO, 4)
			b.cyl(Vector3(0, 0.35, 0), 0.36, 0.1, gold, Vector3.ZERO, 14)
			if v == 0:
				b.cyl(Vector3(0, 3.3, 0), 0.36, 0.12, gold, Vector3.ZERO, 14)
				b.box(Vector3(0, 3.5, 0), Vector3(0.9, 0.22, 0.9), MB.tag(Color("f2eefc"), MB.STONE))
				b.torus(Vector3(0, 3.65, 0), 0.25, 0.03, gold)
			else:
				b.cone(Vector3(0.1, 2.2, 0), 0.32, 0.4, mar, Vector3(0.4, 0, 0.3), 8)
				b.box(Vector3(0.7, 0.2, 0.3), Vector3(0.5, 0.4, 0.35), mar, Vector3(0.2, 0.5, 0.1))
			g.ball(Vector3(0, 0.3, 0), 0.9, Color(1, 1, 1, 0.12), true)
		"mirrorpane":
			b.box(Vector3(0, 0.12, 0), Vector3(1.4, 0.24, 0.5), MB.tag(Color("3a5a78"), MB.STONE))
			var tilt := 0.2 if v == 0 else -0.35
			var ht := 3.4 if v == 0 else 2.4
			b.box(Vector3(0, 0.3 + ht * 0.5, 0), Vector3(1.2, ht, 0.1), MB.tag(Color("d8f0ff"), MB.CRYSTAL), Vector3(0.04, tilt, 0.0))
			b.box(Vector3(0.0, 0.3 + ht * 0.5, -0.02), Vector3(1.32, ht + 0.12, 0.06), MB.tag(Color("4a6a88"), MB.METAL), Vector3(0.04, tilt, 0.0))
			g.box(Vector3(0, 0.3 + ht * 0.5, 0.07), Vector3(1.05, ht - 0.2, 0.03), Color(0.7, 0.92, 1.0, 0.4), Vector3(0.04, tilt, 0.0))
			g.box(Vector3(0.0, 0.3 + ht - 0.05, 0.05), Vector3(1.0, 0.04, 0.04), Color(1, 1, 1, 0.9), Vector3(0.04, tilt, 0.0))
			if v == 1:
				for i in 3:
					b.crystal(Vector3(0.6 - i * 0.4, 0.2, 0.5), 0.12, 0.5, MB.tag(Color("c8ecff"), MB.CRYSTAL), Vector3(0.6, i, 0.3), 4)
		"tombstone":
			var ts := MB.tag(wc.lightened(0.1), MB.STONE)
			b.box(Vector3(0, 0.15, 0), Vector3(1.0, 0.3, 0.6), MB.tag(dark, MB.STONE))
			if v == 0:
				b.box(Vector3(0, 0.95, 0), Vector3(0.7, 1.3, 0.22), ts)
				b.cyl(Vector3(0, 1.6, 0), 0.35, 0.22, ts, Vector3(PI / 2, 0, 0), 14)
				b.box(Vector3(0, 1.0, 0.13), Vector3(0.1, 0.55, 0.04), MB.tag(dark, MB.STONE))
				b.box(Vector3(0, 1.1, 0.13), Vector3(0.36, 0.09, 0.04), MB.tag(dark, MB.STONE))
			else:
				# a saint's sword driven into a stone mound
				b.hemi(Vector3(0, 0.25, 0), Vector3(0.6, 0.5, 0.5), ts)
				b.box(Vector3(0, 1.2, 0), Vector3(0.09, 1.6, 0.02), MB.tag(Color("c8ccd8"), MB.METAL), Vector3(0, 0, 0.12))
				b.box(Vector3(0.1, 1.95, 0), Vector3(0.36, 0.05, 0.06), MB.tag(Color("a08040"), MB.METAL), Vector3(0, 0, 0.12))
				b.ribbon([Vector3(0.12, 2.05, 0), Vector3(0.2, 1.8, 0.05), Vector3(0.15, 1.5, 0.08)], [0.03, 0.04, 0.01], Vector3.RIGHT, MB.tag(Color("a02030"), MB.CLOTH))
			g.ball(Vector3(0, 0.4, 0.4), 0.14, Color(0.6, 0.9, 1.0, 0.5), true)
		"gear":
			b.cyl(Vector3(0, 1.4, 0), 0.22, 2.8, MB.tag(Color("8a6a30"), MB.METAL), Vector3.ZERO, 14)
			b.cyl(Vector3(0, 0.12, 0), 0.65, 0.24, MB.tag(Color("6a4a20"), MB.STONE), Vector3.ZERO, 14)
			var rings := 2 if v == 0 else 3
			for ring in rings:
				var yy := 1.0 + ring * (1.2 if v == 0 else 0.8)
				var rr := 0.8 - ring * 0.12
				b.torus(Vector3(0, yy, 0), rr, 0.09, MB.tag(Color("d8a848"), MB.METAL))
				for i in 10:
					var a5 := TAU * i / 10.0 + ring * 0.3
					b.box(Vector3(cos(a5) * (rr + 0.02), yy, sin(a5) * (rr + 0.02)), Vector3(0.18, 0.12, 0.18), MB.tag(Color("e8b858"), MB.METAL), Vector3(0, -a5, 0))
				for i in 4:
					var a7 := TAU * i / 4.0
					b.box(Vector3(cos(a7) * rr * 0.5, yy, sin(a7) * rr * 0.5), Vector3(rr, 0.05, 0.06), MB.tag(Color("b88838"), MB.METAL), Vector3(0, -a7, 0))
			g.cyl(Vector3(0, 2.9, 0), 0.4, 0.06, Color(1.0, 0.85, 0.4, 0.8), Vector3(PI / 2, 0, 0), 14)
		"monolith":
			b.box(Vector3(0, 0.2, 0), Vector3(1.4, 0.4, 1.4), MB.tag(Color("c8bcd8"), MB.STONE))
			if v == 0:
				b.prim("fr8", MB._xf(Vector3(0, 2.2, 0), Vector3(1.1, 3.6, 0.7), Vector3.ZERO), MB.tag(Color("f4eefc"), MB.STONE))
				g.box(Vector3(0, 2.2, 0.36), Vector3(0.08, 2.4, 0.03), Color(1.0, 0.85, 0.4, 0.95))
				g.box(Vector3(0, 2.8, 0.36), Vector3(0.5, 0.06, 0.03), Color(1.0, 0.85, 0.4, 0.95))
				g.box(Vector3(0, 1.6, 0.36), Vector3(0.36, 0.06, 0.03), Color(1.0, 0.85, 0.4, 0.95))
				g.torus(Vector3(0, 4.3, 0), 0.5, 0.04, Color(1.0, 0.9, 0.6, 0.9))
			else:
				# floating ring-stone
				b.crystal(Vector3(0, 2.4, 0), 0.45, 1.6, MB.tag(Color("f8f0ff"), MB.CRYSTAL), Vector3(0, 0.5, 0), 6)
				b.torus(Vector3(0, 2.4, 0), 0.8, 0.05, MB.tag(Color("e8c860"), MB.METAL), Vector3(0.4, 0, 0.3))
				g.ball(Vector3(0, 2.4, 0), 0.7, Color(1.0, 0.9, 0.7, 0.18), true)
		# ---- Part IV landmarks
		"floatisle":
			# a little island hovering over the ground, roots dangling, with a pine on top
			var y0 := 1.6 if v == 0 else 2.4
			var ir := 0.9 if v == 0 else 0.7
			b.cone(Vector3(0, y0 - 0.6, 0), ir, 1.4, MB.tag(Color("8a7060"), MB.STONE), Vector3(PI, 0.3, 0), 8)
			b.cyl(Vector3(0, y0 + 0.08, 0), ir, 0.18, MB.tag(Color(th.g2), MB.FOLIAGE), Vector3.ZERO, 10)
			for i in 4:
				var a8 := TAU * i / 4.0
				b.ribbon([Vector3(cos(a8) * 0.4, y0 - 0.5, sin(a8) * 0.4), Vector3(cos(a8) * 0.5, y0 - 1.1, sin(a8) * 0.5), Vector3(cos(a8) * 0.45, y0 - 1.5, sin(a8) * 0.45)], [0.03, 0.02, 0.005], Vector3(cos(a8 + 1.5), 0, sin(a8 + 1.5)), MB.tag(Color("6a5040"), MB.WOOD))
			b.limb(Vector3(0.1, y0 + 0.1, 0), Vector3(0.15, y0 + 1.3, 0), 0.08, 0.04, bark, 6)
			for k in 3:
				b.cone(Vector3(0.15, y0 + 0.9 + k * 0.35, 0), 0.6 - k * 0.15, 0.6, MB.tag(wc.lightened(0.08 * k), MB.FOLIAGE), Vector3(0, k, 0), 8)
			b.cone(Vector3(0, 0.25, 0), 0.5, 0.5, MB.tag(Color("a0b8c8"), MB.STONE), Vector3.ZERO, 6)
		"jadepillar":
			var jade := MB.tag(wc.lightened(0.1), MB.CRYSTAL)
			var gold2 := MB.tag(Color("e8c060"), MB.METAL)
			b.box(Vector3(0, 0.2, 0), Vector3(1.1, 0.4, 1.1), MB.tag(Color("d8d0c0"), MB.STONE))
			if v == 0:
				b.cyl(Vector3(0, 2.0, 0), 0.32, 3.2, jade, Vector3.ZERO, 14)
				# a coiling dragon relief as a spiral of balls
				for i in 24:
					var a9 := i * 0.55
					b.ball(Vector3(cos(a9) * 0.34, 0.6 + i * 0.12, sin(a9) * 0.34), 0.07, gold2, true)
				b.lathe(Vector3(0, 3.6, 0), [Vector2(0.5, 0.0), Vector2(0.55, 0.1), Vector2(0.3, 0.25)], gold2, 14)
				b.box(Vector3(0, 3.95, 0), Vector3(0.18, 0.45, 0.18), MB.tag(Color("c83030"), MB.WOOD))
				g.box(Vector3(0, 3.95, 0), Vector3(0.14, 0.4, 0.2), Color(1.0, 0.6, 0.3, 0.85))
			else:
				# hanging lantern post
				b.cyl(Vector3(0, 1.4, 0), 0.1, 2.4, MB.tag(Color("3a2a20"), MB.WOOD), Vector3.ZERO, 8)
				b.box(Vector3(0.35, 2.55, 0), Vector3(0.8, 0.08, 0.08), MB.tag(Color("3a2a20"), MB.WOOD))
				b.lathe(Vector3(0.65, 1.95, 0), [Vector2(0.05, 0.0), Vector2(0.24, 0.12), Vector2(0.26, 0.3), Vector2(0.2, 0.45), Vector2(0.05, 0.52)], MB.tag(Color("e03838"), MB.CLOTH), 12)
				g.ball(Vector3(0.65, 2.2, 0), 0.4, Color(1.0, 0.5, 0.25, 0.5), true)
		"furnace":
			var iron := MB.tag(Color("4a3a30"), MB.METAL)
			var brick := MB.tag(wc.lightened(0.15), MB.STONE)
			if v == 0:
				b.lathe(Vector3.ZERO, [Vector2(0.9, 0.0), Vector2(0.95, 0.4), Vector2(0.8, 1.4), Vector2(0.5, 2.0), Vector2(0.4, 3.2), Vector2(0.45, 3.4)], brick, 10)
				b.cyl(Vector3(0, 1.0, 0), 0.92, 0.12, iron, Vector3.ZERO, 14)
				b.cyl(Vector3(0, 2.0, 0), 0.55, 0.12, iron, Vector3.ZERO, 14)
				b.box(Vector3(0, 0.55, 0.78), Vector3(0.6, 0.6, 0.2), iron)
				g.box(Vector3(0, 0.55, 0.9), Vector3(0.45, 0.45, 0.04), Color(1.0, 0.6, 0.15, 0.95))
				g.ball(Vector3(0, 3.4, 0), 0.45, Color(1.0, 0.5, 0.1, 0.5), true)
			else:
				# anvil on a stump with cooling blades
				b.cyl(Vector3(0, 0.35, 0), 0.45, 0.7, MB.tag(Color("6a4a2a"), MB.WOOD), Vector3.ZERO, 10)
				b.box(Vector3(0, 0.85, 0), Vector3(0.9, 0.3, 0.4), iron)
				b.cone(Vector3(0.6, 0.9, 0), 0.15, 0.4, iron, Vector3(0, 0, -PI / 2), 6)
				for i in 3:
					b.box(Vector3(-0.6 + i * 0.25, 0.9, 0.5), Vector3(0.05, 1.6, 0.012), MB.tag(Color("d8dce8"), MB.METAL), Vector3(0.2, 0, 0.1 * i))
				g.box(Vector3(0, 1.01, 0), Vector3(0.5, 0.02, 0.25), Color(1.0, 0.5, 0.1, 0.8))
		"peach":
			var pb := MB.tag(Color("7a5040"), MB.WOOD)
			b.limb(Vector3(0, -0.1, 0), Vector3(0.15, 1.5, 0), 0.18, 0.11, pb, 8)
			b.limb(Vector3(0.15, 1.4, 0), Vector3(0.8, 2.2, 0.2), 0.1, 0.05, pb, 6)
			b.limb(Vector3(0.15, 1.4, 0), Vector3(-0.6, 2.3, -0.2), 0.1, 0.05, pb, 6)
			var bl := Color("ffb0c8") if v == 0 else Color("ffe0ec")
			_canopy(b, Vector3(0.1, 2.4, 0), 1.0, bl, 7, v * 2.0)
			for i in 6:
				var a10 := TAU * i / 6.0
				b.ball(Vector3(cos(a10) * 0.8, 2.0, sin(a10) * 0.8), 0.09, MB.tag(Color("ff9070"), MB.SKIN), true)
			for i in 6:
				g.ball(Vector3(cos(i * 1.1) * 0.9, 2.5 + sin(i) * 0.4, sin(i * 1.1) * 0.9), 0.05, Color(1.0, 0.85, 0.9, 0.9), true)
		"meteor":
			if v == 0:
				# a fallen star half buried in the sand: dark slag, glass shards, glowing seams
				var slag := MB.tag(Color("4a3a40"), MB.STONE)
				b.sph(Vector3(0, 0.45, 0), Vector3(1.0, 0.75, 0.9), slag, Vector3(0.3, 0.5, 0.1))
				b.sph(Vector3(0.6, 0.3, 0.3), Vector3(0.5, 0.4, 0.45), MB.tag(Color("5a4848"), MB.STONE), Vector3(0, 1.0, 0.2))
				b.torus(Vector3(0, 0.05, 0), 1.25, 0.25, MB.tag(Color(th.g2).darkened(0.1), MB.STONE))
				for i in 6:
					var am := TAU * i / 6.0 + 0.3
					b.crystal(Vector3(cos(am) * 0.7, 0.7 + (i % 2) * 0.2, sin(am) * 0.6), 0.13, 0.9 - (i % 3) * 0.2, MB.tag(Color("fff0c0"), MB.CRYSTAL), Vector3(sin(am) * 0.7, 0, -cos(am) * 0.7), 5)
				for i in 5:
					var a2m := TAU * i / 5.0
					g.box(Vector3(cos(a2m) * 0.75, 0.55, sin(a2m) * 0.68), Vector3(0.5, 0.03, 0.04), Color(1.0, 0.75, 0.35, 0.9), Vector3(0, -a2m, 0.3))
				g.ball(Vector3(0, 1.0, 0), 0.9, Color(1.0, 0.85, 0.5, 0.18), true)
			else:
				# wind-carved sandstone hoodoo with banded layers
				for k in 6:
					var r6 := 0.55 - k * 0.04 + sin(k * 1.7) * 0.12
					var band := Color(wc).lightened(0.05 * (k % 3)).lerp(Color("e8c8a0"), 0.2 * (k % 2))
					b.sph(Vector3(sin(k) * 0.08, 0.35 + k * 0.5, cos(k) * 0.06), Vector3(r6, 0.32, r6 * 0.9), MB.tag(band, MB.STONE), Vector3(0, k * 0.7, 0))
				b.sph(Vector3(0.1, 3.3, 0), Vector3(0.8, 0.25, 0.7), MB.tag(Color(wc).darkened(0.15), MB.STONE), Vector3(0.1, 0.3, 0))
		"glowcap":
			var stem := MB.tag(Color("e8e0d0"), MB.SKIN)
			if v == 0:
				# a cluster of giant glowing mushrooms
				for k in 3:
					var ox: float = [0.0, 0.9, -0.7][k]
					var oz: float = [0.0, 0.4, 0.5][k]
					var hgt: float = [3.2, 2.0, 1.4][k]
					var cr: float = [1.4, 0.9, 0.7][k]
					b.lathe(Vector3(ox, 0, oz), [Vector2(0.28 * cr, 0.0), Vector2(0.2 * cr, hgt * 0.5), Vector2(0.17 * cr, hgt)], stem, 10)
					var capc := Color(wc).lightened(0.1 * k)
					b.lathe(Vector3(ox, hgt - 0.1, oz), [Vector2(0.15, 0.0), Vector2(cr, 0.12), Vector2(cr * 0.95, 0.3), Vector2(cr * 0.6, 0.6), Vector2(0.01, 0.75)], MB.tag(capc, MB.CLOTH), 14)
					for i in 7:
						var ag := TAU * i / 7.0 + k
						var rr := cr * (0.4 + 0.35 * (i % 2))
						g.ball(Vector3(ox + cos(ag) * rr, hgt + 0.3 + (cr - rr) * 0.45, oz + sin(ag) * rr), 0.08 * cr, Color(0.5, 1.0, 0.85, 0.95), true)
					g.disc(Vector3(ox, hgt - 0.12, oz), cr * 0.9, Color(0.4, 1.0, 0.8, 0.35), 16, Color(0.4, 1.0, 0.8, 0.0))
			else:
				# a thicket of thin luminous stalks
				for k in 9:
					var a3g := k * 2.4
					var r3 := 0.15 + (k % 3) * 0.25
					var base := Vector3(cos(a3g) * r3, 0, sin(a3g) * r3)
					var top := base + Vector3(cos(a3g) * 0.2, 1.4 + (k % 4) * 0.45, sin(a3g) * 0.2)
					b.limb(base, top, 0.06, 0.03, stem, 6)
					b.sph(top, Vector3(0.18, 0.1, 0.18), MB.tag(Color(wc).lightened(0.2), MB.CLOTH), Vector3.ZERO, true)
					g.ball(top + Vector3(0, -0.05, 0), 0.12, Color(0.6, 0.9, 1.0, 0.8), true)
		"icespire":
			var ice := MB.tag(Color("c8e8ff"), MB.CRYSTAL)
			if v == 0:
				b.crystal(Vector3(0, 0.0, 0), 0.45, 4.2, ice, Vector3(0.05, 0, 0.04), 6)
				for i in 5:
					var ai := TAU * i / 5.0
					b.crystal(Vector3(cos(ai) * 0.5, 0.0, sin(ai) * 0.5), 0.2, 1.6 + (i % 2) * 0.8, MB.tag(Color("a8d8ff").lightened(0.1 * (i % 3)), MB.CRYSTAL), Vector3(sin(ai) * 0.35, 0, -cos(ai) * 0.35), 5)
				b.sph(Vector3(0, 0.1, 0), Vector3(1.0, 0.3, 0.9), MB.tag(Color("f4f8ff"), MB.STONE), Vector3.ZERO, true)
				g.ball(Vector3(0, 2.2, 0), 1.3, Color(0.5, 1.0, 0.8, 0.12), true)
			else:
				# a snow-laden fir
				b.limb(Vector3(0, -0.1, 0), Vector3(0, 1.0, 0), 0.14, 0.1, MB.tag(Color("5a4030"), MB.WOOD), 6)
				for k in 4:
					var yk := 0.8 + k * 0.7
					b.cone(Vector3(0, yk, 0), 1.2 - k * 0.25, 1.1, MB.tag(Color("3a7a6a").lightened(0.06 * k), MB.FOLIAGE), Vector3(0, k * 0.5, 0), 14)
					b.cone(Vector3(0, yk + 0.22, 0), 0.9 - k * 0.22, 0.55, MB.tag(Color("f4f8ff"), MB.STONE), Vector3(0, k * 0.5 + 0.3, 0), 14)
		"chaosrock":
			if v == 0:
				# a rock island adrift above the ground, veined with light, pebbles in orbit
				var y0 := 1.6
				b.cone(Vector3(0, y0 - 0.5, 0), 1.0, 1.6, MB.tag(Color("3a2a48"), MB.STONE), Vector3(PI, 0.4, 0), 7)
				b.sph(Vector3(0, y0 + 0.15, 0), Vector3(1.05, 0.3, 0.95), MB.tag(Color(th.g2).lightened(0.1), MB.STONE), Vector3(0, 0.2, 0))
				for i in 4:
					var ac := TAU * i / 4.0
					g.box(Vector3(cos(ac) * 0.55, y0 - 0.4, sin(ac) * 0.5), Vector3(0.04, 0.9, 0.03), Color(1.0, 0.5, 0.8, 0.85), Vector3(0, -ac, 0.25))
				for i in 6:
					var ao := TAU * i / 6.0
					b.sph(Vector3(cos(ao) * 1.5, y0 + sin(i * 1.3) * 0.4, sin(ao) * 1.5), Vector3(0.14, 0.11, 0.13), MB.tag(Color("5a4a6a"), MB.STONE), Vector3(i, i, 0), true)
				var five := [Color("ff5050"), Color("ffd040"), Color("50a0ff"), Color("f0f0ff"), Color("303040")]
				for i in 5:
					b.crystal(Vector3(cos(i * 1.256) * 0.45, y0 + 0.3, sin(i * 1.256) * 0.4), 0.09, 0.5, MB.tag(five[i], MB.CRYSTAL), Vector3(0.2 * cos(i), 0, 0.2 * sin(i)), 5)
			else:
				# a five-colour obelisk, each band a stone of Nuwa's
				var cols5 := [Color("ff5050"), Color("ffd040"), Color("50a0ff"), Color("f0f0ff"), Color("383048")]
				for k in 5:
					b.box(Vector3(0, 0.35 + k * 0.62, 0), Vector3(0.75 - k * 0.08, 0.6, 0.75 - k * 0.08), MB.tag(cols5[k], MB.CRYSTAL), Vector3(0, k * 0.3, 0))
					g.box(Vector3(0, 0.66 + k * 0.62, 0), Vector3(0.8 - k * 0.08, 0.03, 0.8 - k * 0.08), Color(cols5[k].r, cols5[k].g, cols5[k].b, 0.7), Vector3(0, k * 0.3, 0))
				b.cone(Vector3(0, 3.5, 0), 0.3, 0.6, MB.tag(Color("fff0d0"), MB.CRYSTAL), Vector3(0, 0, 0), 4)
				g.ball(Vector3(0, 3.65, 0), 0.25, Color(1.0, 0.9, 0.8, 0.22), true)
		# ---- Part VI
		"maple":
			# a moss-grown grave stupa of the sect's dead, with a paper lantern on its step
			var st2 := MB.tag(Color("a8a098"), MB.STONE)
			b.box(Vector3(0, 0.2, 0), Vector3(1.3, 0.4, 1.3), st2, Vector3(0, 0.1, 0))
			b.lathe(Vector3(0, 0.4, 0), [Vector2(0.5, 0.0), Vector2(0.55, 0.5), Vector2(0.42, 0.95), Vector2(0.2, 1.1)], st2, 10)
			for k in 3:
				b.cyl(Vector3(0, 1.25 + k * 0.32, 0), 0.38 - k * 0.09, 0.08, MB.tag(Color("8a8278"), MB.STONE), Vector3.ZERO, 8)
			b.cone(Vector3(0, 2.3, 0), 0.08, 0.5, MB.tag(Color("6a6258"), MB.STONE), Vector3.ZERO, 6)
			b.sph(Vector3(0.2, 0.42, 0.3), Vector3(0.45, 0.08, 0.4), MB.tag(Color("6a8a3a"), MB.FOLIAGE), Vector3.ZERO, true)
			if v == 1:
				b.cyl(Vector3(0.75, 0.6, 0.55), 0.12, 0.3, MB.tag(Color("f0e0b0"), MB.CLOTH), Vector3.ZERO, 8)
				g.ball(Vector3(0.75, 0.6, 0.55), 0.3, Color(1.0, 0.75, 0.35, 0.45), true)
		"karstpeak":
			var lime := MB.tag(Color("b8b8b0"), MB.STONE)
			for k in 4:
				var rr := 0.75 - k * 0.15
				b.prim("cone8", MB._xf(Vector3(0.05 * k, 0.6 + k * 0.85, -0.04 * k), Vector3(rr * 2.0, 1.4, rr * 2.0), Vector3(0.05, k * 0.7, -0.04)), lime if k % 2 == 0 else MB.tag(Color("a0a098"), MB.STONE))
			b.sph(Vector3(0, 3.4, 0), Vector3(0.4, 0.25, 0.35), MB.tag(Color("4a8a4a"), MB.FOLIAGE), Vector3.ZERO, true)
			b.sph(Vector3(0.45, 1.6, 0.2), Vector3(0.3, 0.18, 0.25), MB.tag(Color("5a9a50"), MB.FOLIAGE), Vector3.ZERO, true)
		"stonelantern":
			var gs := MB.tag(Color("8a8070"), MB.STONE)
			if v == 0:
				# a tall stone lantern (ishidoro-like) with a warm flame in its window
				b.cyl(Vector3(0, 0.12, 0), 0.5, 0.24, gs, Vector3.ZERO, 6)
				b.cyl(Vector3(0, 0.9, 0), 0.14, 1.3, gs, Vector3.ZERO, 8)
				b.box(Vector3(0, 1.65, 0), Vector3(0.62, 0.12, 0.62), gs)
				b.box(Vector3(0, 1.95, 0), Vector3(0.44, 0.5, 0.44), MB.tag(Color("6a6050"), MB.STONE))
				b.prim("cone4", MB._xf(Vector3(0, 2.45, 0), Vector3(1.1, 0.5, 1.1), Vector3(0, PI / 4, 0)), gs)
				b.ball(Vector3(0, 2.75, 0), 0.08, gs, true)
				g.box(Vector3(0, 1.95, 0), Vector3(0.46, 0.3, 0.3), Color(1.0, 0.6, 0.25, 0.8))
				g.ball(Vector3(0, 1.95, 0), 0.55, Color(1.0, 0.55, 0.25, 0.25), true)
			else:
				# a weathered memorial gate (pailou) over the funeral road
				var red := MB.tag(Color("a83028"), MB.WOOD)
				for sx in [-0.9, 0.9]:
					b.cyl(Vector3(sx, 1.4, 0), 0.12, 2.8, red, Vector3.ZERO, 8)
					b.cyl(Vector3(sx, 0.15, 0), 0.22, 0.3, gs, Vector3.ZERO, 8)
				b.box(Vector3(0, 2.45, 0), Vector3(2.3, 0.18, 0.24), red)
				b.box(Vector3(0, 2.85, 0), Vector3(2.7, 0.14, 0.5), MB.tag(Color("3a3038"), MB.STONE))
				b.box(Vector3(0, 2.62, 0.13), Vector3(0.6, 0.3, 0.04), MB.tag(Color("e8c060"), MB.METAL))
		"ghostpagoda":
			var dk := MB.tag(Color("2a2a3a"), MB.STONE)
			if v == 0:
				# a narrow pagoda of the Ten Courts, blue ghost-fire hanging from every eave
				for k in 4:
					var wd := 1.1 - k * 0.18
					b.box(Vector3(0, 0.45 + k * 0.85, 0), Vector3(wd * 0.75, 0.7, wd * 0.75), dk, Vector3(0, k * 0.0, 0))
					b.prim("cone4", MB._xf(Vector3(0, 0.88 + k * 0.85, 0), Vector3(wd * 1.6, 0.28, wd * 1.6), Vector3(0, PI / 4, 0)), MB.tag(Color("1a1a28"), MB.STONE))
					for c4 in 4:
						var ca := TAU * c4 / 4.0 + PI / 4
						g.ball(Vector3(cos(ca) * wd * 0.75, 0.72 + k * 0.85, sin(ca) * wd * 0.75), 0.08, Color(0.4, 0.8, 1.0, 0.9), true)
				b.cone(Vector3(0, 4.3, 0), 0.06, 0.8, MB.tag(Color("c8a850"), MB.METAL), Vector3.ZERO, 6)
			else:
				# a judgement pillar wrapped in chains, ghost-fire burning in its brazier
				b.cyl(Vector3(0, 1.5, 0), 0.32, 3.0, dk, Vector3.ZERO, 8)
				for k in 5:
					b.torus(Vector3(0, 0.5 + k * 0.55, 0), 0.36, 0.004, MB.tag(Color("6a6a78"), MB.METAL), Vector3(0.25 * sin(k), 0, 0.2 * cos(k)))
				b.lathe(Vector3(0, 3.0, 0), [Vector2(0.15, 0.0), Vector2(0.5, 0.25), Vector2(0.55, 0.4)], MB.tag(Color("3a3a48"), MB.METAL), 10)
				g.cone(Vector3(0, 3.65, 0), 0.4, 1.0, Color(0.3, 0.7, 1.0, 0.7), Vector3.ZERO, 8)
				g.ball(Vector3(0, 3.6, 0), 0.8, Color(0.3, 0.6, 1.0, 0.2), true)
		_:
			b.sph(Vector3(0, 0.9, 0), Vector3(0.8, 0.9, 0.8), MB.tag(wc, MB.STONE))

static func _build_decor(b: MB, g: MB, kind: String, th: Dictionary) -> void:
	var gc: Color = Color(th.g2).lightened(0.15)
	match kind:
		"flower":
			for i in 5:
				var a := i * 1.3
				var p := Vector3(cos(a) * 0.22, 0.0, sin(a) * 0.22)
				var top := p + Vector3(0, 0.4 + (i % 2) * 0.12, 0)
				b.limb(p, top, 0.012, 0.01, MB.tag(Color("4a9a50"), MB.FOLIAGE), 4)
				b.leaf(p + Vector3(0, 0.1, 0), p + Vector3(0.12, 0.22, 0.05), 0.04, MB.tag(Color("5aaa60"), MB.FOLIAGE))
				var pc: Color = [Color("ff9ac8"), Color("ffe080"), Color("ffffff"), Color("c8a0ff"), Color("ff8080")][i]
				for k in 5:
					var pa := TAU * k / 5.0
					b.leaf(top, top + Vector3(cos(pa) * 0.07, 0.02, sin(pa) * 0.07), 0.04, MB.tag(pc, MB.CLOTH), Vector3(-sin(pa), 0, cos(pa)))
				b.ball(top, 0.022, MB.tag(Color("ffd040"), MB.CLOTH), true)
		"grass":
			for i in 9:
				var a2 := i * 0.7
				var r := 0.05 + (i % 3) * 0.07
				var root := Vector3(cos(a2) * r, 0, sin(a2) * r)
				b.leaf(root, root + Vector3(cos(a2) * 0.18, 0.45 + (i % 4) * 0.08, sin(a2) * 0.18), 0.035, MB.tag(gc.darkened(0.15), MB.FOLIAGE), Vector3(-sin(a2), 0, cos(a2)), MB.tag(gc.lightened(0.2), MB.FOLIAGE))
		"reed":
			for i in 5:
				var a3 := i * 1.26
				var p2 := Vector3(cos(a3) * 0.15, 0, sin(a3) * 0.15)
				b.limb(p2, p2 + Vector3(0.03, 1.0, 0), 0.016, 0.01, MB.tag(Color("7a6a3a"), MB.FOLIAGE), 4)
				b.capsule(p2 + Vector3(0.03, 0.95, 0), p2 + Vector3(0.03, 1.15, 0), 0.035, MB.tag(Color("5a3a22"), MB.CLOTH))
				b.leaf(p2, p2 + Vector3(cos(a3) * 0.25, 0.7, sin(a3) * 0.25), 0.03, MB.tag(Color("8a8a4a"), MB.FOLIAGE))
		"snowrock":
			b.sph(Vector3(0, 0.12, 0), Vector3(0.35, 0.2, 0.3), MB.tag(Color("f4f8ff"), MB.STONE), Vector3.ZERO, true)
			b.sph(Vector3(0.2, 0.08, 0.1), Vector3(0.2, 0.14, 0.18), MB.tag(Color("dce8f8"), MB.STONE), Vector3.ZERO, true)
			b.crystal(Vector3(-0.15, 0.15, 0.1), 0.06, 0.3, MB.tag(Color("c8e8ff"), MB.CRYSTAL), Vector3(0.3, 0, 0.3), 4)
		"pebble":
			b.sph(Vector3(0, 0.1, 0), Vector3(0.3, 0.16, 0.24), MB.tag(Color("6a6878"), MB.STONE), Vector3.ZERO, true)
			b.sph(Vector3(0.25, 0.07, 0.1), Vector3(0.16, 0.1, 0.14), MB.tag(Color("5a5868"), MB.STONE), Vector3.ZERO, true)
			b.sph(Vector3(-0.2, 0.05, 0.15), Vector3(0.1, 0.06, 0.09), MB.tag(Color("7a7888"), MB.STONE), Vector3.ZERO, true)
		"bones":
			var bone := MB.tag(Color("e8e0cc"), MB.STONE)
			b.cyl(Vector3(0, 0.08, 0), 0.04, 0.6, bone, Vector3(0, 0, PI / 2))
			b.ball(Vector3(0.3, 0.08, 0), 0.06, bone, true)
			b.ball(Vector3(-0.3, 0.08, 0), 0.06, bone, true)
			b.cyl(Vector3(0.1, 0.08, 0.15), 0.035, 0.5, MB.tag(Color("d8d0bc"), MB.STONE), Vector3(0, 0.9, PI / 2))
			# skull with dark sockets
			b.sph(Vector3(-0.2, 0.14, -0.1), Vector3(0.12, 0.11, 0.13), MB.tag(Color("f0e8d4"), MB.STONE))
			b.ball(Vector3(-0.24, 0.16, 0.0), 0.03, MB.tag(Color("1a1414"), MB.STONE), true)
			b.ball(Vector3(-0.16, 0.16, 0.0), 0.03, MB.tag(Color("1a1414"), MB.STONE), true)
		"shell":
			b.lathe(Vector3.ZERO, [Vector2(0.2, 0.0), Vector2(0.15, 0.12), Vector2(0.08, 0.24), Vector2(0.0, 0.32)], MB.tag(Color("ffb8c0"), MB.STONE), 10, MB.tag(Color("fff0e8"), MB.STONE))
			b.ball(Vector3(0.2, 0.08, 0.1), 0.1, MB.tag(Color("ffe8d0"), MB.STONE), true)
			b.disc(Vector3(-0.2, 0.02, 0.05), 0.12, MB.tag(Color("f0d0ff"), MB.CRYSTAL), 8)
		"ember":
			b.sph(Vector3(0, 0.1, 0), Vector3(0.3, 0.16, 0.26), MB.tag(Color("2a1410"), MB.STONE), Vector3.ZERO, true)
			g.ball(Vector3(0, 0.2, 0), 0.07, Color(1.0, 0.6, 0.2, 1.0), true)
			g.ball(Vector3(0, 0.2, 0), 0.2, Color(1.0, 0.4, 0.1, 0.3), true)
			g.box(Vector3(0.1, 0.16, 0.0), Vector3(0.2, 0.01, 0.02), Color(1.0, 0.5, 0.1, 0.9), Vector3(0, 0.5, 0))
		"starcrystal":
			b.crystal(Vector3(0, 0.1, 0), 0.12, 0.6, MB.tag(Color("9a6aff"), MB.CRYSTAL), Vector3(0.1, 0, 0.1), 4)
			b.crystal(Vector3(0.2, 0.05, 0.1), 0.08, 0.4, MB.tag(Color("b890ff"), MB.CRYSTAL), Vector3(0.2, 0, -0.4), 4)
			g.ball(Vector3(0, 0.35, 0), 0.3, Color(0.7, 0.5, 1.0, 0.2), true)
		"cloudpuff":
			b.ball(Vector3(0, 0.15, 0), 0.28, MB.tag(Color(1, 1, 1), MB.CLOTH), true)
			b.ball(Vector3(0.25, 0.1, 0.05), 0.2, MB.tag(Color(0.97, 0.97, 1.0), MB.CLOTH), true)
			b.ball(Vector3(-0.22, 0.1, -0.05), 0.2, MB.tag(Color(0.97, 0.97, 1.0), MB.CLOTH), true)
			b.ball(Vector3(0.05, 0.3, 0.05), 0.15, MB.tag(Color(1, 1, 1), MB.CLOTH), true)
		"glassshard":
			b.crystal(Vector3(0, 0.1, 0), 0.1, 0.7, MB.tag(Color("c8ecff"), MB.CRYSTAL), Vector3(0.1, 0, 0.15), 4)
			b.crystal(Vector3(0.18, 0.05, 0.1), 0.07, 0.4, MB.tag(Color("a8d8f8"), MB.CRYSTAL), Vector3(0, 0, -0.5), 4)
			g.ball(Vector3(0, 0.35, 0), 0.28, Color(0.7, 0.95, 1.0, 0.18), true)
		"cog":
			b.torus(Vector3(0, 0.08, 0), 0.22, 0.05, MB.tag(Color("c8984a"), MB.METAL))
			for i in 8:
				var a4 := TAU * i / 8.0
				b.box(Vector3(cos(a4) * 0.26, 0.08, sin(a4) * 0.26), Vector3(0.07, 0.06, 0.07), MB.tag(Color("d8a858"), MB.METAL), Vector3(0, -a4, 0))
			b.cyl(Vector3(0, 0.08, 0), 0.07, 0.1, MB.tag(Color("8a6a30"), MB.METAL))
		"lantern":
			var st := MB.tag(Color("b8b0a0"), MB.STONE)
			b.box(Vector3(0, 0.08, 0), Vector3(0.36, 0.16, 0.36), st)
			b.cyl(Vector3(0, 0.4, 0), 0.06, 0.5, st, Vector3.ZERO, 6)
			b.box(Vector3(0, 0.75, 0), Vector3(0.3, 0.24, 0.3), st)
			b.cone(Vector3(0, 0.98, 0), 0.28, 0.22, st, Vector3(0, PI / 4, 0), 4)
			g.box(Vector3(0, 0.75, 0), Vector3(0.18, 0.15, 0.32), Color(1.0, 0.75, 0.35, 0.9))
			g.box(Vector3(0, 0.75, 0), Vector3(0.32, 0.15, 0.18), Color(1.0, 0.75, 0.35, 0.9))
		"ingot":
			var au := MB.tag(Color("f0c050"), MB.METAL)
			b.prim("fr8", MB._xf(Vector3(0, 0.07, 0), Vector3(0.35, 0.14, 0.2), Vector3.ZERO), au)
			b.prim("fr8", MB._xf(Vector3(0.25, 0.07, 0.12), Vector3(0.3, 0.12, 0.18), Vector3(0, 0.6, 0)), au)
			b.sph(Vector3(-0.2, 0.06, 0.15), Vector3(0.12, 0.06, 0.1), MB.tag(Color("2a2420"), MB.STONE))
		"starglass":
			for i in 4:
				var ag2 := i * 1.7
				b.crystal(Vector3(cos(ag2) * 0.18, 0.02, sin(ag2) * 0.18), 0.05 + (i % 2) * 0.03, 0.25 + (i % 3) * 0.12, MB.tag(Color("fff4d0"), MB.CRYSTAL), Vector3(cos(ag2) * 0.5, 0, sin(ag2) * 0.5), 4)
			b.sph(Vector3(0, 0.03, 0), Vector3(0.3, 0.06, 0.25), MB.tag(Color(th.g2).darkened(0.15), MB.STONE), Vector3.ZERO, true)
			g.ball(Vector3(0, 0.2, 0), 0.3, Color(1.0, 0.9, 0.6, 0.22), true)
		"sporecap":
			for i in 3:
				var asp := i * 2.1
				var p3 := Vector3(cos(asp) * 0.15, 0, sin(asp) * 0.15)
				var hh := 0.2 + i * 0.1
				b.limb(p3, p3 + Vector3(0, hh, 0), 0.025, 0.02, MB.tag(Color("e8e0d0"), MB.SKIN), 5)
				b.sph(p3 + Vector3(0, hh, 0), Vector3(0.09, 0.05, 0.09), MB.tag(Color(th.wall).lightened(0.15 * i), MB.CLOTH), Vector3.ZERO, true)
				g.ball(p3 + Vector3(0, hh + 0.02, 0), 0.07, Color(0.5, 1.0, 0.85, 0.7), true)
		"fivestone":
			var five2 := [Color("ff5050"), Color("ffd040"), Color("50a0ff"), Color("f0f0ff"), Color("403050")]
			for i in 5:
				var af := TAU * i / 5.0
				b.sph(Vector3(cos(af) * 0.2, 0.06, sin(af) * 0.2), Vector3(0.09, 0.07, 0.08), MB.tag(five2[i], MB.CRYSTAL), Vector3(0, af, 0), true)
				g.ball(Vector3(cos(af) * 0.2, 0.1, sin(af) * 0.2), 0.08, Color(five2[i].r, five2[i].g, five2[i].b, 0.35), true)
		"leafpile":
			for i in 14:
				var al := i * 2.39
				var rl := 0.08 + (i % 5) * 0.07
				var lc2: Color = [Color("e0582a"), Color("f0a030"), Color("c83a20"), Color("e8c040")][i % 4]
				b.leaf(Vector3(cos(al) * rl, 0.03 + (i % 3) * 0.02, sin(al) * rl), Vector3(cos(al) * (rl + 0.14), 0.05, sin(al) * (rl + 0.14)), 0.06, MB.tag(lc2, MB.FOLIAGE), Vector3(-sin(al), 0.2, cos(al)))
			b.sph(Vector3(0, 0.03, 0), Vector3(0.3, 0.05, 0.28), MB.tag(Color("a04a20"), MB.FOLIAGE), Vector3.ZERO, true)
		"spiderlily":
			for i in 4:
				var a5 := i * 1.57 + 0.3
				var base5 := Vector3(cos(a5) * 0.15, 0, sin(a5) * 0.15)
				var top5 := base5 + Vector3(0.02, 0.42 + (i % 2) * 0.1, 0)
				b.limb(base5, top5, 0.01, 0.008, MB.tag(Color("4a8040"), MB.FOLIAGE), 4)
				for k in 6:
					var pa := TAU * k / 6.0
					var tip5 := top5 + Vector3(cos(pa) * 0.11, 0.05, sin(pa) * 0.11)
					b.leaf(top5, tip5, 0.02, MB.tag(Color("e02018"), MB.CLOTH), Vector3(-sin(pa), 0, cos(pa)), MB.tag(Color("ff5040"), MB.CLOTH))
					b.limb(top5, top5 + Vector3(cos(pa + 0.5) * 0.13, 0.1, sin(pa + 0.5) * 0.13), 0.003, 0.002, MB.tag(Color("ff3020"), MB.CLOTH), 3)
		"ghostcandle":
			for i in 3:
				var a6 := i * 2.1
				var cp := Vector3(cos(a6) * 0.18, 0, sin(a6) * 0.18)
				var chh := 0.18 + i * 0.07
				b.cyl(cp + Vector3(0, chh * 0.5, 0), 0.04, chh, MB.tag(Color("e8e4d8"), MB.CLOTH), Vector3.ZERO, 8)
				g.cone(cp + Vector3(0, chh + 0.06, 0), 0.03, 0.12, Color(0.4, 0.8, 1.0, 0.9), Vector3.ZERO, 6)
				g.ball(cp + Vector3(0, chh + 0.06, 0), 0.12, Color(0.3, 0.6, 1.0, 0.25), true)
		_:
			b.sph(Vector3(0, 0.1, 0), Vector3(0.25, 0.15, 0.25), MB.tag(gc, MB.FOLIAGE), Vector3.ZERO, true)

## small ground cover scattered over every open tile (sways in the wind)
static func _build_tuft(b: MB, g: MB, kind: String, th: Dictionary) -> void:
	var gc: Color = Color(th.g2)
	match kind:
		"grass", "flowers", "deadgrass":
			var base := gc.darkened(0.2) if kind != "deadgrass" else Color("8a7a50")
			var tip := gc.lightened(0.22) if kind != "deadgrass" else Color("c8b080")
			for i in 7:
				var a := i * 0.9
				var r := 0.03 + (i % 3) * 0.05
				var root := Vector3(cos(a) * r, 0, sin(a) * r)
				b.leaf(root, root + Vector3(cos(a) * 0.12, 0.26 + (i % 3) * 0.06, sin(a) * 0.12), 0.025, MB.tag(base, MB.FOLIAGE), Vector3(-sin(a), 0, cos(a)), MB.tag(tip, MB.FOLIAGE))
			if kind == "flowers":
				b.ball(Vector3(0.05, 0.3, 0.0), 0.035, MB.tag(Color("ffb0d0"), MB.CLOTH), true)
				b.ball(Vector3(-0.07, 0.25, 0.05), 0.03, MB.tag(Color("fff0a0"), MB.CLOTH), true)
		"reed", "kelp":
			var kc := Color("6a7a40") if kind == "reed" else Color("3a8a6a")
			for i in 4:
				var a2 := i * 1.6
				var root2 := Vector3(cos(a2) * 0.06, 0, sin(a2) * 0.06)
				b.leaf(root2, root2 + Vector3(cos(a2) * 0.1, 0.55, sin(a2) * 0.1), 0.03, MB.tag(kc, MB.FOLIAGE), Vector3(-sin(a2), 0, cos(a2)), MB.tag(kc.lightened(0.25), MB.FOLIAGE))
		"snow":
			b.hemi(Vector3(0, 0, 0), Vector3(0.18, 0.08, 0.15), MB.tag(Color("f8fbff"), MB.STONE))
			g.ball(Vector3(0.05, 0.08, 0.0), 0.02, Color(1, 1, 1, 0.9), true)
		"pebble":
			b.sph(Vector3(0, 0.03, 0), Vector3(0.08, 0.05, 0.07), MB.tag(Color("7a7888"), MB.STONE), Vector3.ZERO, true)
			b.sph(Vector3(0.1, 0.02, 0.05), Vector3(0.05, 0.03, 0.04), MB.tag(Color("5a5868"), MB.STONE), Vector3.ZERO, true)
		"ash":
			b.sph(Vector3(0, 0.02, 0), Vector3(0.1, 0.04, 0.08), MB.tag(Color("2a2220"), MB.STONE), Vector3.ZERO, true)
			g.ball(Vector3(0.0, 0.04, 0.0), 0.03, Color(1.0, 0.45, 0.1, 0.9), true)
		"crystal":
			b.crystal(Vector3(0, 0.02, 0), 0.03, 0.18, MB.tag(Color(th.wall).lightened(0.3), MB.CRYSTAL), Vector3(0.2, 0, 0.1), 4)
			b.crystal(Vector3(0.05, 0.02, 0.03), 0.02, 0.12, MB.tag(Color(th.wall).lightened(0.4), MB.CRYSTAL), Vector3(-0.3, 0, 0.2), 4)
		"dunegrass":
			for i in 6:
				var adg := i * 1.05
				var root3 := Vector3(cos(adg) * 0.05, 0, sin(adg) * 0.05)
				b.leaf(root3, root3 + Vector3(cos(adg) * 0.22, 0.32 + (i % 2) * 0.1, sin(adg) * 0.22), 0.018, MB.tag(Color("b89a50"), MB.FOLIAGE), Vector3(-sin(adg), 0, cos(adg)), MB.tag(Color("f0dc98"), MB.FOLIAGE))
		"moss":
			b.hemi(Vector3(0, 0, 0), Vector3(0.14, 0.05, 0.12), MB.tag(Color(th.g2).lightened(0.1), MB.FOLIAGE))
			for i in 3:
				var am2 := i * 2.1
				var tip3 := Vector3(cos(am2) * 0.06, 0.12 + i * 0.03, sin(am2) * 0.06)
				b.limb(Vector3(cos(am2) * 0.04, 0.02, sin(am2) * 0.04), tip3, 0.008, 0.006, MB.tag(Color("a0e0d0"), MB.FOLIAGE), 4)
				g.ball(tip3, 0.025, Color(0.4, 1.0, 0.85, 0.9), true)
		_:
			pass

static func _build_rock(b: MB, th: Dictionary) -> void:
	var rc := MB.tag(Color(th.wall).lerp(Color(0.5, 0.5, 0.52), 0.6), MB.STONE)
	b.sph(Vector3(0, 0.15, 0), Vector3(0.38, 0.28, 0.32), rc, Vector3(0.2, 0.4, 0.1))
	b.sph(Vector3(0.3, 0.1, 0.15), Vector3(0.2, 0.16, 0.18), MB.tag(Color(rc.r, rc.g, rc.b).lightened(0.1), MB.STONE), Vector3(0.1, 1.0, 0))
	b.sph(Vector3(-0.05, 0.3, -0.05), Vector3(0.2, 0.08, 0.18), MB.tag(Color(th.g2).darkened(0.1), MB.FOLIAGE))

# ---------------------------------------------------------------- sect buildings
## Find every run of road tiles with water on both sides and span it with a humped stone bridge.
static func _bridges(root: Node3D, grid: PackedByteArray, w: int, h: int, hm: PackedFloat32Array) -> void:
	var b := MB.new()
	var g := MB.new()
	var is_w := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and grid[y * w + x] == MapGen.WATER
	var done := {}
	for y in h:
		for x in w:
			if grid[y * w + x] != MapGen.PATH or done.has(Vector2i(x, y)):
				continue
			for horiz in [true, false]:
				# water on both sides across the road's direction
				var side_ok := func(px: int, py: int) -> bool:
					return (is_w.call(px, py - 1) and is_w.call(px, py + 1)) if horiz else (is_w.call(px - 1, py) and is_w.call(px + 1, py))
				if not side_ok.call(x, y):
					continue
				var x1 := x
				var y1 := y
				while true:
					var nx := x1 + (1 if horiz else 0)
					var ny := y1 + (0 if horiz else 1)
					if nx >= w or ny >= h or grid[ny * w + nx] != MapGen.PATH or not side_ok.call(nx, ny):
						break
					x1 = nx
					y1 = ny
				for yy in range(y, y1 + 1):
					for xx in range(x, x1 + 1):
						done[Vector2i(xx, yy)] = true
				var a := Vector3((x + 0.5) * T, 0, (y + 0.5) * T) - (Vector3(T, 0, 0) if horiz else Vector3(0, 0, T))
				var e := Vector3((x1 + 0.5) * T, 0, (y1 + 0.5) * T) + (Vector3(T, 0, 0) if horiz else Vector3(0, 0, T))
				a.y = sample(hm, w, h, a.x, a.z)
				e.y = sample(hm, w, h, e.x, e.z)
				Arch.bridge(b, g, a, e, T * 0.95)
				break
	if b.is_empty():
		return
	var mi := MB.mesh_node(root, b.build())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow()))

## a causeway with railings across the lotus pond and a pagoda tower beyond the east wall
## (props stay on tile edges or outside the map so the hero never walks through them)
static func _sect_props(root: Node3D, grid: PackedByteArray, w: int, h: int, hm: PackedFloat32Array) -> void:
	var b := MB.new()
	var g := MB.new()
	var wood := MB.tag(Color("a84a32"), MB.WOOD)
	var gold := MB.tag(Color("e8c860"), MB.METAL)
	# a whitewashed courtyard wall around the sect, open where the roads leave, and a memorial
	# archway over each road just inside its gate
	var gates: Array = []
	for pt in Data.AREAS.sect.portals:
		gates.append(pt.pos)
	var x0 := 0.15 * T
	var x1 := (w - 0.15) * T
	var z0 := 0.15 * T
	var z1 := (h - 0.15) * T
	var sides := [[Vector3(x0, 0, z0), Vector3(x1, 0, z0), "z", 0], [Vector3(x0, 0, z1), Vector3(x1, 0, z1), "z", h - 1], [Vector3(x0, 0, z0), Vector3(x0, 0, z1), "x", 0], [Vector3(x1, 0, z0), Vector3(x1, 0, z1), "x", w - 1]]
	for sd in sides:
		var a: Vector3 = sd[0]
		var e: Vector3 = sd[1]
		var cuts: Array = []
		for gp in gates:
			var gv: Vector2i = gp
			# portals sit one tile inside the border
			if sd[2] == "x" and absi(gv.x - int(sd[3])) <= 1:
				cuts.append((gv.y + 0.5) * T)
			elif sd[2] == "z" and absi(gv.y - int(sd[3])) <= 1:
				cuts.append((gv.x + 0.5) * T)
		cuts.sort()
		var along_x: bool = sd[2] == "z"
		var cur := a
		for cpos in cuts:
			var stop := Vector3(cpos - 2.2, 0, a.z) if along_x else Vector3(a.x, 0, cpos - 2.2)
			Arch.wall_run(b, g, cur, stop)
			cur = Vector3(cpos + 2.2, 0, a.z) if along_x else Vector3(a.x, 0, cpos + 2.2)
		Arch.wall_run(b, g, cur, e)
	for gp2 in gates:
		var gt: Vector2i = gp2
		var gpos := Vector3((gt.x + 0.5) * T, 0, (gt.y + 0.5) * T)
		var side_gate := gt.x <= 1 or gt.x >= w - 2
		var yaw := PI * 0.5 if side_gate else 0.0
		var inward := Vector3(1.0 if gt.x <= 1 else -1.0, 0, 0) if side_gate else Vector3(0, 0, -1.0 if gt.y >= h - 2 else 1.0)
		gpos += inward * 1.2 * T
		gpos.y = sample(hm, w, h, gpos.x, gpos.z) - 0.05
		Arch.pailou(b, g, gpos, yaw, 3.0)
	var mi := MB.mesh_node(root, b.build())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	MB.mesh_node(root, g.build(MB.mat_glow()))
