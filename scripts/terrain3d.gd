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

const STYLE := {"grass": 0, "mud": 1, "snow": 2, "rock": 3, "tile": 4, "sand": 5, "ash": 6, "crystal": 7, "marble": 8, "glass": 9}

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
varying vec3 wp;
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
	}
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

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	shore = COLOR.a;
	VERTEX.y += sin(wp.x * 1.3 + TIME * 1.2) * 0.025 + sin(wp.z * 1.7 + TIME * 0.9) * 0.02;
}

void fragment() {
	vec2 uv = wp.xz;
	float w1 = sin(uv.x * 2.3 + TIME * 1.4) * sin(uv.y * 2.1 + TIME * 1.1);
	float w2 = n2(uv * 1.5 + vec2(TIME * 0.3, TIME * 0.2)) - 0.5;
	float w3 = n2(uv * 3.7 - vec2(TIME * 0.25, -TIME * 0.35)) - 0.5;
	// ripple normals
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(w2 * 0.35 + w1 * 0.1, 0.0, w3 * 0.35, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 c = mix(deep, col.rgb, 0.55 + 0.25 * w1 + 0.3 * fres);
	// caustic sparkle and shoreline foam
	float sparkle = smoothstep(0.42, 0.5, w2 + w3) * 0.6;
	float foam = smoothstep(0.35, 0.95, shore + w3 * 0.6) * (0.6 + 0.4 * sin(TIME * 2.0 + uv.x * 3.0));
	c = mix(c, vec3(1.0), clamp(foam * 0.8 + sparkle * 0.3, 0.0, 1.0));
	ALBEDO = c;
	ALPHA = clamp(col.a + fres * 0.25 + foam * 0.3, 0.0, 1.0);
	ROUGHNESS = 0.06;
	METALLIC = 0.2;
	SPECULAR = 0.9;
	EMISSION = col.rgb * glow * (0.7 + 0.3 * w1) + vec3(sparkle * 0.15);
}
"""

static func _water_mat(col: Color, glow: float) -> ShaderMaterial:
	var key := "%s_%f" % [col.to_html(), glow]
	if _water_mats.has(key):
		return _water_mats[key]
	var sh := Shader.new()
	sh.code = WATER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("col", Color(col.r, col.g, col.b, 0.8))
	m.set_shader_parameter("deep", col.darkened(0.7))
	m.set_shader_parameter("glow", glow)
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
	m.set_shader_parameter("accent", acc)
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
			var hv := noise.get_noise_2d(cx, cz) * amp
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

static func _corner_col(grid: PackedByteArray, w: int, h: int, cx: int, cz: int, th: Dictionary) -> Color:
	var acc := Color(0, 0, 0, 0)
	var n := 0
	for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		var tx: int = clampi(cx + d.x, 0, w - 1)
		var ty: int = clampi(cz + d.y, 0, h - 1)
		var c := _tile_col(grid[ty * w + tx], tx, ty, th)
		acc += c
		n += 1
	return acc / float(n)

# ---------------------------------------------------------------- main entry
static func build(grid: PackedByteArray, w: int, h: int, theme_name: String, seed_: int) -> Node3D:
	var th := Look.theme(theme_name)
	var root := Node3D.new()
	root.name = "terrain_" + theme_name
	var hm := heightmap(grid, w, h, theme_name, seed_)
	root.set_meta("hm", hm)
	root.set_meta("w", w)
	root.set_meta("h", h)
	var cw := int(ceil(w / float(CH)))
	var chh := int(ceil(h / float(CH)))
	var wall_proto := _proto("wall:" + theme_name, theme_name)
	var wall_proto2 := _proto("wall2:" + theme_name, theme_name)
	var decor_proto := _proto("decor:" + theme_name, theme_name)
	var tuft_proto := _proto("tuft:" + theme_name, theme_name)
	var rock_proto := _proto("rock:" + theme_name, theme_name)
	var lily_proto: Mesh = null
	if theme_name in ["sect", "garden", "marsh"]:
		lily_proto = _proto("lily:" + theme_name, theme_name)
	var water_glow := 1.1 if theme_name in ["volcano", "time", "void", "origin", "abyss", "forge"] else 0.0
	var wmat := _water_mat(th.water, water_glow)
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
			var wall_x: Array = []
			var wall_c: Array = []
			var wall2_x: Array = []
			var wall2_c: Array = []
			var dec_x: Array = []
			var dec_c: Array = []
			var tuft_x: Array = []
			var tuft_c: Array = []
			var rock_x: Array = []
			var rock_c: Array = []
			var lily_x: Array = []
			var lily_c: Array = []
			for ty in range(cy * CH, mini(h, (cy + 1) * CH)):
				for tx in range(cx * CH, mini(w, (cx + 1) * CH)):
					var tile := grid[ty * w + tx]
					var x0 := tx * T
					var z0 := ty * T
					var hv := hash2(tx, ty)
					var i00 := ty * rw + tx
					var i10 := i00 + 1
					var i01 := i00 + rw
					var i11 := i01 + 1
					ground.quad_n(
						[Vector3(x0, hm[i00], z0), Vector3(x0 + T, hm[i10], z0), Vector3(x0 + T, hm[i11], z0 + T), Vector3(x0, hm[i01], z0 + T)],
						[cnrm[i00], cnrm[i10], cnrm[i11], cnrm[i01]],
						[ccol[i00], ccol[i10], ccol[i11], ccol[i01]])
					var cxw := x0 + T * 0.5
					var czw := z0 + T * 0.5
					var gy := (hm[i00] + hm[i10] + hm[i01] + hm[i11]) * 0.25
					match tile:
						MapGen.WATER:
							var sh := _shore(grid, w, h, tx, ty)
							water.quad4(Vector3(x0, WATER_Y, z0), Vector3(x0 + T, WATER_Y, z0), Vector3(x0 + T, WATER_Y, z0 + T), Vector3(x0, WATER_Y, z0 + T),
								Color(1, 1, 1, sh[0]), Color(1, 1, 1, sh[1]), Color(1, 1, 1, sh[2]), Color(1, 1, 1, sh[3]))
							if lily_proto != null and hv > 0.7:
								lily_x.append(Transform3D(Basis.from_euler(Vector3(0, hv * TAU, 0)), Vector3(cxw + (hash2(tx, ty, 3.0) - 0.5), WATER_Y + 0.02, czw + (hash2(tx, ty, 4.0) - 0.5))))
								lily_c.append(Color.WHITE)
						MapGen.DECOR:
							if decor_proto != null:
								var ox := (hash2(tx, ty, 1.0) - 0.5) * 1.2
								var oz := (hash2(tx, ty, 2.0) - 0.5) * 1.2
								var s := 0.8 + hash2(tx, ty, 3.0) * 0.6
								dec_x.append(Transform3D(Basis.from_euler(Vector3(0, hv * TAU, 0)).scaled(Vector3(s, s, s)), Vector3(cxw + ox, gy, czw + oz)))
								dec_c.append(Color(Color.WHITE.darkened(hash2(tx, ty, 4.0) * 0.25), 1.0))
						MapGen.WALL:
							var s2 := 0.85 + hash2(tx, ty, 5.0) * 0.55
							var sy := s2 * (0.9 + hash2(tx, ty, 6.0) * 0.4)
							var b2 := Basis.from_euler(Vector3((hash2(tx, ty, 7.0) - 0.5) * 0.12, hv * TAU, (hash2(tx, ty, 8.0) - 0.5) * 0.12)).scaled(Vector3(s2, sy, s2))
							var xf := Transform3D(b2, Vector3(cxw + (hash2(tx, ty, 9.0) - 0.5) * 0.5, gy - 0.05, czw + (hash2(tx, ty, 10.0) - 0.5) * 0.5))
							var wcol := Color(Color.WHITE.darkened(hash2(tx, ty, 11.0) * 0.3), 1.0)
							if hash2(tx, ty, 12.0) < 0.35:
								wall2_x.append(xf)
								wall2_c.append(wcol)
							else:
								wall_x.append(xf)
								wall_c.append(wcol)
							# boulders at the foot of the landmark
							if hash2(tx, ty, 13.0) > 0.55 and rock_proto != null:
								var rs := 0.5 + hash2(tx, ty, 14.0) * 0.7
								rock_x.append(Transform3D(Basis.from_euler(Vector3(0, hash2(tx, ty, 15.0) * TAU, 0)).scaled(Vector3(rs, rs * 0.8, rs)), Vector3(x0 + hash2(tx, ty, 16.0) * T, gy, z0 + hash2(tx, ty, 17.0) * T)))
								rock_c.append(Color.WHITE)
						MapGen.FLOOR:
							if tuft_proto != null:
								var nt := 1 + int(hash2(tx, ty, 20.0) * 2.4)
								for k in nt:
									if hash2(tx, ty, 21.0 + k) < 0.7:
										var px := x0 + 0.2 + hash2(tx, ty, 22.0 + k) * (T - 0.4)
										var pz := z0 + 0.2 + hash2(tx, ty, 25.0 + k) * (T - 0.4)
										var ts := 0.7 + hash2(tx, ty, 28.0 + k) * 0.7
										tuft_x.append(Transform3D(Basis.from_euler(Vector3(0, hash2(tx, ty, 31.0 + k) * TAU, 0)).scaled(Vector3(ts, ts, ts)), Vector3(px, sample(hm, w, h, px, pz), pz)))
										tuft_c.append(Color(Color.WHITE.darkened(hash2(tx, ty, 34.0 + k) * 0.2), 1.0))
			if not ground.is_empty():
				var gi := MB.mesh_node(root, ground.build(gmat))
				gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not water.is_empty():
				var wi := MB.mesh_node(root, water.build(wmat))
				wi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not wall_x.is_empty():
				_add_mm(root, wall_proto, wall_x, wall_c, true, 95.0)
			if not wall2_x.is_empty():
				_add_mm(root, wall_proto2, wall2_x, wall2_c, true, 95.0)
			if not rock_x.is_empty():
				_add_mm(root, rock_proto, rock_x, rock_c, true, 60.0)
			if not dec_x.is_empty():
				_add_mm(root, decor_proto, dec_x, dec_c, false, 50.0)
			if not tuft_x.is_empty():
				_add_mm(root, tuft_proto, tuft_x, tuft_c, false, 38.0)
			if not lily_x.is_empty():
				_add_mm(root, lily_proto, lily_x, lily_c, false, 60.0)
	_skirt(root, w, h, theme_name, seed_)
	_horizon(root, w, h, theme_name, seed_)
	if theme_name == "sect":
		_sect_buildings(root, grid, w, h, th, hm)
		_sect_props(root, grid, w, h, hm)
	return root

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
				var hh := rng.randf_range(18.0, 40.0) * s
				b.cone(p + Vector3(0, hh * 0.5 - 2.0, 0), hh * 0.6, hh, col, Vector3(0, rng.randf() * TAU, 0), 6)
				if kind != "crags":
					b.cone(p + Vector3(0, hh * 0.86 - 2.0, 0), hh * 0.18, hh * 0.3, MB.tag(Color(0.96, 0.97, 1.0), MB.STONE), Vector3(0, rng.randf() * TAU, 0), 6)
				b.cone(p + Vector3(rng.randf_range(-8, 8), hh * 0.3 - 2.0, rng.randf_range(-8, 8)), hh * 0.4, hh * 0.6, col.darkened(0.05), Vector3.ZERO, 6)
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
			_:
				b.sph(p + Vector3(0, -2.0, 0), Vector3(14.0, 8.0, 10.0) * s, col)
	var mi := MB.mesh_node(root, b.build(MB.mat_plain()))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow()))

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
	var mesh := b.build(mat)
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
		_:
			pass

static func _build_rock(b: MB, th: Dictionary) -> void:
	var rc := MB.tag(Color(th.wall).lerp(Color(0.5, 0.5, 0.52), 0.6), MB.STONE)
	b.sph(Vector3(0, 0.15, 0), Vector3(0.38, 0.28, 0.32), rc, Vector3(0.2, 0.4, 0.1))
	b.sph(Vector3(0.3, 0.1, 0.15), Vector3(0.2, 0.16, 0.18), MB.tag(Color(rc.r, rc.g, rc.b).lightened(0.1), MB.STONE), Vector3(0.1, 1.0, 0))
	b.sph(Vector3(-0.05, 0.3, -0.05), Vector3(0.2, 0.08, 0.18), MB.tag(Color(th.g2).darkened(0.1), MB.FOLIAGE))

# ---------------------------------------------------------------- sect buildings
static func _sect_buildings(root: Node3D, grid: PackedByteArray, w: int, h: int, th: Dictionary, hm: PackedFloat32Array) -> void:
	var seen := {}
	for y in h:
		for x in w:
			if grid[y * w + x] != MapGen.BUILDING or seen.has(Vector2i(x, y)):
				continue
			var x1 := x
			while x1 + 1 < w and grid[y * w + x1 + 1] == MapGen.BUILDING:
				x1 += 1
			var y1 := y
			while y1 + 1 < h and grid[(y1 + 1) * w + x] == MapGen.BUILDING:
				y1 += 1
			for yy in range(y, y1 + 1):
				for xx in range(x, x1 + 1):
					seen[Vector2i(xx, yy)] = true
			var r := Rect2(x * T, y * T, (x1 - x + 1) * T, (y1 - y + 1) * T)
			_building(root, r, sample(hm, w, h, r.get_center().x, r.get_center().y))

static func _building(root: Node3D, r: Rect2, gy: float) -> void:
	var b := MB.new()
	var g := MB.new()
	var cx := r.position.x + r.size.x * 0.5
	var cz := r.position.y + r.size.y * 0.5
	var wall_h := 2.6
	var stone := MB.tag(Color("a8a4b0"), MB.STONE)
	var plaster := MB.tag(Color("efe4c8"), MB.CLOTH)
	var lacquer := MB.tag(Color("b83a2a"), MB.WOOD)
	var roof_c := MB.tag(Color("3a6a8a"), MB.STONE)
	var gold := MB.tag(Color("e8c860"), MB.METAL)
	# terrace with steps
	b.box(Vector3(cx, 0.25, cz), Vector3(r.size.x + 0.8, 0.5, r.size.y + 0.8), stone)
	b.box(Vector3(cx, 0.52, cz), Vector3(r.size.x + 0.6, 0.06, r.size.y + 0.6), MB.tag(Color("c8c4d0"), MB.STONE))
	for k in 3:
		b.box(Vector3(cx, 0.08 + k * 0.16, r.end.y + 0.95 - k * 0.22), Vector3(1.8, 0.16, 0.25), stone)
	# walls with timber framing and lattice windows
	b.box(Vector3(cx, 0.5 + wall_h * 0.5, cz), Vector3(r.size.x - 0.2, wall_h, r.size.y - 0.2), plaster)
	b.box(Vector3(cx, 0.6, cz), Vector3(r.size.x - 0.15, 0.2, r.size.y - 0.15), lacquer)
	b.box(Vector3(cx, 0.5 + wall_h - 0.12, cz), Vector3(r.size.x - 0.15, 0.24, r.size.y - 0.15), lacquer)
	# pillars on every side
	var step := 2.0
	var nx := int(r.size.x / step)
	for i in range(nx + 1):
		var px := r.position.x + 0.1 + (r.size.x - 0.2) * i / float(maxi(nx, 1))
		for zz in [r.end.y - 0.05, r.position.y + 0.05]:
			b.cyl(Vector3(px, 0.5 + wall_h * 0.5, zz), 0.13, wall_h, lacquer, Vector3.ZERO, 8)
			b.box(Vector3(px, 0.58, zz), Vector3(0.34, 0.12, 0.34), stone)
			b.box(Vector3(px, 0.5 + wall_h - 0.05, zz), Vector3(0.36, 0.1, 0.36), gold)
	var nz := int(r.size.y / step)
	for i in range(nz + 1):
		var pz := r.position.y + 0.1 + (r.size.y - 0.2) * i / float(maxi(nz, 1))
		for xx in [r.position.x + 0.05, r.end.x - 0.05]:
			b.cyl(Vector3(xx, 0.5 + wall_h * 0.5, pz), 0.13, wall_h, lacquer, Vector3.ZERO, 8)
	# door with studs and a name plaque
	b.box(Vector3(cx, 1.45, r.end.y - 0.08), Vector3(1.2, 1.9, 0.1), MB.tag(Color("6a2a1a"), MB.WOOD))
	for k in 3:
		for s in [-1, 1]:
			b.ball(Vector3(cx + 0.3 * s, 1.0 + k * 0.4, r.end.y - 0.02), 0.035, gold, true)
	b.box(Vector3(cx, 2.65, r.end.y + 0.02), Vector3(1.0, 0.36, 0.06), MB.tag(Color("1a2a4a"), MB.WOOD))
	b.box(Vector3(cx, 2.65, r.end.y + 0.05), Vector3(0.85, 0.24, 0.02), gold)
	for s in [-1, 1]:
		var wx: float = cx + 1.6 * s
		b.box(Vector3(wx, 1.9, r.end.y - 0.07), Vector3(0.8, 0.8, 0.06), lacquer)
		for k in 3:
			b.box(Vector3(wx, 1.65 + k * 0.25, r.end.y - 0.03), Vector3(0.7, 0.03, 0.03), lacquer)
			b.box(Vector3(wx - 0.25 + k * 0.25, 1.9, r.end.y - 0.03), Vector3(0.03, 0.7, 0.03), lacquer)
		g.box(Vector3(wx, 1.9, r.end.y - 0.05), Vector3(0.7, 0.7, 0.02), Color(1.0, 0.85, 0.5, 0.75))
	# tiered roof: hip roof + upturned corner eaves + ridge ornaments
	var roof_y := 0.5 + wall_h
	b.box(Vector3(cx, roof_y + 0.1, cz), Vector3(r.size.x + 1.0, 0.2, r.size.y + 1.0), MB.tag(Color("5a2a22"), MB.WOOD))
	var tiers := 2 if r.size.y > 6.0 else 1
	for t in tiers:
		var sx := (r.size.x + 1.6) * (1.0 - t * 0.35)
		var sz := (r.size.y + 1.6) * (1.0 - t * 0.35)
		var hh := 1.4 if t == 0 else 1.0
		var yy := roof_y + 0.2 + hh * 0.5 + t * 1.25
		b.prim("cone4", Transform3D(Basis.from_euler(Vector3(0, PI / 4, 0)).scaled(Vector3(sx * 1.4142, hh, sz * 1.4142)), Vector3(cx, yy, cz)), MB.tag(Color("3a6a8a").lerp(Color("2a4a6a"), t * 0.5), MB.STONE))
		# roof tile rows
		for k in 4:
			var f := (k + 1) / 5.0
			b.box(Vector3(cx, yy - hh * 0.5 + hh * f * 0.95, cz + sz * 0.5 * (1.0 - f) + 0.02), Vector3(sx * (1.0 - f) + 0.1, 0.05, 0.06), MB.tag(Color("2a5070"), MB.STONE))
		# eave trim and upturned corners
		b.box(Vector3(cx, yy - hh * 0.5, cz + sz * 0.5), Vector3(sx, 0.1, 0.12), gold)
		b.box(Vector3(cx, yy - hh * 0.5, cz - sz * 0.5), Vector3(sx, 0.1, 0.12), gold)
		for ex in [-1, 1]:
			for ez in [-1, 1]:
				var cp := Vector3(cx + sx * 0.5 * ex, yy - hh * 0.5, cz + sz * 0.5 * ez)
				b.limb(cp, cp + Vector3(0.45 * ex, 0.5, 0.45 * ez), 0.1, 0.04, roof_c, 6)
				b.ball(cp + Vector3(0.45 * ex, 0.55, 0.45 * ez), 0.07, gold, true)
				# hanging wind chime
				g.ball(cp + Vector3(0.1 * ex, -0.35, 0.1 * ez), 0.06, Color(1.0, 0.85, 0.4, 0.7), true)
	var top_y := roof_y + 0.2 + 1.4 + (tiers - 1) * 1.25
	b.cyl(Vector3(cx, top_y + 0.15, cz), 0.06, 0.4, gold, Vector3.ZERO, 8)
	b.ball(Vector3(cx, top_y + 0.4, cz), 0.16, gold, true)
	for s in [-1, 1]:
		b.limb(Vector3(cx + 0.3 * s, top_y - 0.05, cz), Vector3(cx + 0.55 * s, top_y + 0.35, cz), 0.06, 0.02, gold, 6)
	# lanterns
	for sx2 in [r.position.x + 0.2, r.end.x - 0.2]:
		b.lathe(Vector3(sx2, 2.05, r.end.y + 0.15), [Vector2(0.06, 0.0), Vector2(0.2, 0.1), Vector2(0.22, 0.25), Vector2(0.17, 0.4), Vector2(0.06, 0.46)], MB.tag(Color("e04a3a"), MB.CLOTH), 12)
		b.ribbon([Vector3(sx2, 2.05, r.end.y + 0.15), Vector3(sx2, 1.8, r.end.y + 0.15)], [0.03, 0.01], Vector3.RIGHT, MB.tag(Color("f0c850"), MB.CLOTH))
		g.ball(Vector3(sx2, 2.28, r.end.y + 0.15), 0.42, Color(1.0, 0.45, 0.2, 0.3), true)
	var mi := MB.mesh_node(root, b.build())
	mi.position.y = gy
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var gi := MB.mesh_node(root, g.build(MB.mat_glow()))
	gi.position.y = gy
	if DisplayServer.get_name() != "headless":
		for sx3 in [r.position.x + 0.2, r.end.x - 0.2]:
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.6, 0.3)
			l.light_energy = 0.8
			l.omni_range = 5.0
			l.position = Vector3(sx3, gy + 2.3, r.end.y + 0.4)
			root.add_child(l)

## a causeway with railings across the lotus pond and a pagoda tower beyond the east wall
## (props stay on tile edges or outside the map so the hero never walks through them)
static func _sect_props(root: Node3D, grid: PackedByteArray, w: int, h: int, hm: PackedFloat32Array) -> void:
	var b := MB.new()
	var g := MB.new()
	var wood := MB.tag(Color("a84a32"), MB.WOOD)
	var gold := MB.tag(Color("e8c860"), MB.METAL)
	# railings along every path tile that crosses water
	for y in h:
		for x in w:
			if grid[y * w + x] != MapGen.PATH:
				continue
			for s in [-1, 1]:
				var nx: int = x + s
				if nx < 0 or nx >= w or grid[y * w + nx] != MapGen.WATER:
					continue
				var ex: float = (x + 0.5 + 0.48 * s) * T
				var gy := sample(hm, w, h, (x + 0.5) * T, (y + 0.5) * T)
				for k in 2:
					b.cyl(Vector3(ex, gy + 0.35, (y + k) * T), 0.06, 0.7, wood, Vector3.ZERO, 6)
					b.ball(Vector3(ex, gy + 0.74, (y + k) * T), 0.07, gold, true)
				b.box(Vector3(ex, gy + 0.62, (y + 0.5) * T), Vector3(0.07, 0.07, T), wood)
				b.box(Vector3(ex, gy + 0.3, (y + 0.5) * T), Vector3(0.05, 0.05, T), wood)
	# five-storey pagoda beyond the east wall
	var pp := Vector3((w + 3.5) * T, -0.3, 5.0 * T)
	for k in 5:
		var s2 := 2.6 - k * 0.38
		b.box(pp + Vector3(0, 0.6 + k * 1.3, 0), Vector3(s2, 1.0, s2), MB.tag(Color("efe4c8"), MB.CLOTH))
		b.box(pp + Vector3(0, 0.25 + k * 1.3, 0), Vector3(s2 + 0.1, 0.15, s2 + 0.1), wood)
		b.prim("cone4", Transform3D(Basis.from_euler(Vector3(0, PI / 4, 0)).scaled(Vector3((s2 + 1.2) * 1.4142, 0.6, (s2 + 1.2) * 1.4142)), pp + Vector3(0, 1.35 + k * 1.3, 0)), MB.tag(Color("2a4a6a"), MB.STONE))
		for ex2 in [-1, 1]:
			for ez in [-1, 1]:
				var c := pp + Vector3((s2 + 1.2) * 0.5 * ex2, 1.05 + k * 1.3, (s2 + 1.2) * 0.5 * ez)
				b.limb(c, c + Vector3(0.25 * ex2, 0.3, 0.25 * ez), 0.06, 0.02, MB.tag(Color("2a4a6a"), MB.STONE), 4)
				g.ball(c + Vector3(0, -0.2, 0), 0.07, Color(1.0, 0.8, 0.4, 0.8), true)
		for s3 in [-1, 1]:
			g.box(pp + Vector3(-s2 * 0.5 - 0.01, 0.6 + k * 1.3, 0.4 * s3), Vector3(0.02, 0.5, 0.3), Color(1.0, 0.85, 0.5, 0.8))
	b.cyl(pp + Vector3(0, 7.6, 0), 0.05, 1.4, gold, Vector3.ZERO, 6)
	for k in 4:
		b.torus(pp + Vector3(0, 7.2 + k * 0.25, 0), 0.16 - k * 0.025, 0.012, gold)
	var mi := MB.mesh_node(root, b.build())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	MB.mesh_node(root, g.build(MB.mat_glow()))
