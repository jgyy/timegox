class_name Fauna
extends Node3D
## Ambient wildlife: the small moving things that make a landscape feel alive.
##
## Each Fauna node is one group of animals drawn as a single MultiMesh (one draw call) and moved on
## the CPU every frame with cheap steering, while their wings beat in the vertex shader:
##   birds        flocks that wheel around a roost in wide, banking loops (boids-lite: each bird
##                follows a moving anchor on the loop plus its own wobble, so the flock breathes)
##   cranes       slow, large white birds gliding in a V over open country
##   butterflies  erratic flutter around flower meadows, settling and taking off again
##   dragonflies  darting hover-and-dash flight over water
##   fish         koi and minnows circling just under the water surface, now and then leaping
##   moths        glowing moths spiralling slowly in dark places
##   bats         ghost bats flickering through the Ten Courts
## The vertex shader flaps every vertex whose colour alpha marks it as wing (alpha = 0 body,
## 1 wing), with the hinge at the body's side.  Each region picks its own mix of species.

const KINDS := {
	"sect": [["birds", 1], ["butterflies", 3], ["cranes", 1]],
	"bamboo": [["birds", 2], ["butterflies", 2]],
	"marsh": [["dragonflies", 4], ["birds", 1], ["fish", 2]],
	"frost": [["birds", 1]],
	"thunder": [["birds", 1]],
	"abyss": [["fish", 4]],
	"volcano": [["bats", 1]],
	"celestial": [["cranes", 2], ["butterflies", 2]],
	"mirror": [["dragonflies", 3], ["fish", 3], ["cranes", 1]],
	"grave": [["bats", 2]],
	"time": [["birds", 1]],
	"origin": [["butterflies", 3], ["cranes", 1]],
	"cloudsea": [["cranes", 2], ["birds", 2]],
	"court": [["moths", 2], ["fish", 2]],
	"garden": [["butterflies", 4], ["birds", 1], ["fish", 2]],
	"dunes": [["birds", 1]],
	"fungal": [["moths", 4]],
	"aurora": [["birds", 1]],
	"maple": [["birds", 2], ["butterflies", 2], ["fish", 2], ["cranes", 1]],
	"karst": [["cranes", 2], ["birds", 2], ["fish", 3], ["dragonflies", 2]],
	"lilies": [["butterflies", 4], ["moths", 2]],
	"diyu": [["bats", 2], ["moths", 2]],
	"village": [["birds", 2], ["butterflies", 2], ["dragonflies", 3], ["fish", 2]],
	"tea": [["birds", 2], ["cranes", 2], ["butterflies", 2]],
	"silk": [["moths", 3], ["butterflies", 3], ["birds", 1]],
	"loom": [["butterflies", 3], ["cranes", 1]],
	"starferry": [["fish", 3], ["dragonflies", 2], ["moths", 2]],
	"magpie": [["birds", 4], ["cranes", 2]],
	"starpalace": [["butterflies", 2], ["moths", 3]],
	"jasper": [["cranes", 3], ["butterflies", 3], ["birds", 1]],
	"yanggu": [["birds", 2], ["dragonflies", 1]],
	"millet": [["birds", 1], ["butterflies", 1]],
	"fusang": [["birds", 4], ["cranes", 1], ["fish", 2], ["dragonflies", 2]],
	"guanghan": [["moths", 3], ["cranes", 1]],
	"longmen": [["fish", 4], ["birds", 2], ["cranes", 1], ["dragonflies", 2]],
	"drowned": [["cranes", 3], ["fish", 3], ["dragonflies", 3], ["birds", 1]],
	"tushan": [["birds", 2], ["bats", 1]],
	"buzhou": [["birds", 1], ["bats", 1]],
	"juntian": [["cranes", 3], ["birds", 3]],
	"changhe": [["cranes", 2], ["butterflies", 2]],
	"ninesprings": [["moths", 3], ["bats", 2], ["fish", 2]],
	"youdu": [["bats", 2], ["moths", 2]],
}

const FLAP := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
uniform float speed = 8.0;
uniform float amp = 0.9;
uniform float glow = 0.0;
varying float wing;

void vertex() {
	wing = COLOR.a;
	// every instance flaps with its own phase (INSTANCE_ID), hinged at the body's side
	float ph = TIME * speed + float(INSTANCE_ID) * 1.618;
	float beat = sin(ph) * amp + 0.15;
	float side = sign(VERTEX.x);
	float r = abs(VERTEX.x);
	float a = beat * wing;
	VERTEX.y += sin(a) * r;
	VERTEX.x = side * cos(a) * r;
	COLOR.a = 1.0;
}

void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = COLOR.rgb;
	BACKLIGHT = COLOR.rgb * 0.4 * wing;
	ROUGHNESS = 0.8;
	EMISSION = COLOR.rgb * glow;
}
"""

static var _meshes := {}

var kind := "birds"
var count := 8
var center := Vector3.ZERO
var radius := 10.0
var height := 8.0
var hm := PackedFloat32Array()
var map_w := 0
var map_h := 0
var water: Array = []
var t := 0.0
var seeds: Array = []
var mm: MultiMesh
var mi: MultiMeshInstance3D

## Spawn the region's animals into `root` (called by Terrain3D.build).
static func populate(root: Node3D, grid: PackedByteArray, w: int, h: int, hmap: PackedFloat32Array, theme_name: String, seed_: int) -> void:
	var list: Array = KINDS.get(theme_name, [])
	if list.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 31 + 7
	var T := Terrain3D.T
	# candidate spots: open meadows for fliers, water tiles for fish and dragonflies
	var open: Array = []
	var wet: Array = []
	for y in range(2, h - 2):
		for x in range(2, w - 2):
			var tile := grid[y * w + x]
			if tile == MapGen.WATER:
				wet.append(Vector2i(x, y))
			elif tile == MapGen.FLOOR or tile == MapGen.DECOR:
				open.append(Vector2i(x, y))
	for pair in list:
		var k: String = pair[0]
		var groups: int = int(pair[1]) * (1 + int(w * h / 3000))
		for gi in groups:
			var near_water := k in ["fish", "dragonflies"]
			var pool: Array = wet if near_water else open
			if pool.is_empty():
				continue
			var tile: Vector2i = pool[rng.randi() % pool.size()]
			var f := Fauna.new()
			f.kind = k
			f.hm = hmap
			f.map_w = w
			f.map_h = h
			f.center = Vector3((tile.x + 0.5) * T, Terrain3D.sample(hmap, w, h, (tile.x + 0.5) * T, (tile.y + 0.5) * T), (tile.y + 0.5) * T)
			match k:
				"birds":
					f.count = rng.randi_range(6, 11)
					f.radius = rng.randf_range(12.0, 22.0)
					f.height = rng.randf_range(9.0, 15.0)
				"cranes":
					f.count = rng.randi_range(3, 6)
					f.radius = rng.randf_range(18.0, 30.0)
					f.height = rng.randf_range(12.0, 18.0)
				"butterflies":
					f.count = rng.randi_range(4, 8)
					f.radius = rng.randf_range(2.5, 4.5)
					f.height = 0.9
				"dragonflies":
					f.count = rng.randi_range(3, 6)
					f.radius = rng.randf_range(2.0, 4.0)
					f.height = 0.7
				"fish":
					f.count = rng.randi_range(3, 6)
					f.radius = rng.randf_range(1.2, 2.6)
					f.height = 0.0
					f.center.y = Terrain3D.WATER_Y - 0.18
				"moths":
					f.count = rng.randi_range(5, 9)
					f.radius = rng.randf_range(2.0, 4.0)
					f.height = 1.6
				"bats":
					f.count = rng.randi_range(5, 9)
					f.radius = rng.randf_range(5.0, 9.0)
					f.height = rng.randf_range(4.0, 7.0)
			f.name = "fauna_%s_%d" % [k, gi]
			root.add_child(f)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name) + int(center.x * 13.0 + center.z * 7.0)
	for i in count:
		seeds.append(Vector4(rng.randf() * TAU, rng.randf_range(0.7, 1.3), rng.randf_range(-1.0, 1.0), rng.randf()))
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh_for(kind)
	mm.instance_count = count
	var pal := _palette(kind)
	for i in count:
		mm.set_instance_color(i, pal[i % pal.size()])
	mi = MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if kind in ["butterflies", "dragonflies", "fish", "moths"] else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mi.visibility_range_end = 70.0 if kind in ["birds", "cranes", "bats"] else 32.0
	add_child(mi)
	_step(0.0)

func _process(d: float) -> void:
	if not is_visible_in_tree():
		return
	t += d
	_step(d)

## Move every animal in the group for this frame.
func _step(_d: float) -> void:
	for i in count:
		var s: Vector4 = seeds[i]
		var p := Vector3.ZERO
		var fwd := Vector3.FORWARD
		var bank := 0.0
		var sc := 1.0
		match kind:
			"birds", "cranes", "bats":
				# a banking loop around the roost; each bird rides it at its own offset and
				# altitude, weaving in and out of formation
				var spd := (0.22 if kind == "birds" else (0.12 if kind == "cranes" else 0.4)) * s.y
				var a: float = t * spd + s.x * (0.35 if kind == "cranes" else 1.0)
				var rr := radius * (0.8 + 0.25 * sin(t * 0.3 + s.x * 2.0))
				var wob := Vector3(sin(t * 1.3 + s.x * 5.0), sin(t * 0.9 + s.x * 3.0) * 0.6, cos(t * 1.1 + s.x * 4.0)) * (1.5 if kind != "cranes" else 0.6)
				if kind == "cranes":
					# V formation: trail behind the leader on alternating sides
					var slot := float(i)
					var side := 1.0 if i % 2 == 0 else -1.0
					a = t * spd + 0.0
					var lead := Vector3(cos(a) * rr, height, sin(a) * rr)
					var dir := Vector3(-sin(a), 0, cos(a))
					var lat := dir.cross(Vector3.UP)
					p = lead - dir * ceilf(slot / 2.0) * 1.6 + lat * side * ceilf(slot / 2.0) * 1.3 + wob * 0.3
				else:
					p = Vector3(cos(a) * rr, height + s.z * 2.0, sin(a) * rr) + wob
				var nxt := Vector3(cos(a + 0.05) * rr, p.y, sin(a + 0.05) * rr)
				fwd = (nxt - Vector3(cos(a) * rr, p.y, sin(a) * rr)).normalized()
				bank = -0.35
				sc = 1.0 if kind == "birds" else (2.2 if kind == "cranes" else 0.8)
			"butterflies", "moths":
				# erratic flutter: overlapping sines, with pauses close to the flowers
				var tt := t * (0.6 if kind == "butterflies" else 0.35) + s.x * 7.0
				p = Vector3(sin(tt * 1.3) + sin(tt * 2.9 + s.z) * 0.4, 0.0, cos(tt * 1.1) + cos(tt * 2.3 + s.x) * 0.4) * radius * 0.6
				p.y = height + 0.4 * sin(tt * 3.7 + s.w * 6.0) + 0.25 * sin(tt * 7.1)
				fwd = Vector3(cos(tt * 1.3) * 1.3, 0.0, -sin(tt * 1.1) * 1.1).normalized()
				sc = 0.9 + 0.3 * s.w
			"dragonflies":
				# hover, then dash to a new spot over the water
				var cyc := t * 0.5 * s.y + s.x
				var seg := floorf(cyc)
				var f := cyc - seg
				var k := smoothstep(0.65, 0.85, f)
				var a0 := _h(seg, s.x) * TAU
				var a1 := _h(seg + 1.0, s.x) * TAU
				var p0 := Vector3(cos(a0), 0, sin(a0)) * radius * _h(seg, s.z + 3.0)
				var p1 := Vector3(cos(a1), 0, sin(a1)) * radius * _h(seg + 1.0, s.z + 3.0)
				p = p0.lerp(p1, k) + Vector3(0, height + 0.08 * sin(t * 9.0 + s.x), 0)
				fwd = (p1 - p0).normalized() if (p1 - p0).length() > 0.01 else Vector3.FORWARD
				sc = 0.7
			"fish":
				# lazy circles under the surface; once in a while one leaps in an arc
				var a := t * 0.5 * s.y + s.x
				var rr := radius * (0.6 + 0.4 * s.w)
				p = Vector3(cos(a) * rr, 0, sin(a) * rr)
				fwd = Vector3(-sin(a), 0, cos(a))
				var jump := fmod(t * 0.13 + s.x, 1.0)
				if jump < 0.06 and s.w > 0.5:
					var u := jump / 0.06
					p.y = sin(u * PI) * 0.9
					bank = 0.0
					fwd = (fwd + Vector3(0, cos(u * PI) * 1.2, 0)).normalized()
				sc = 0.8 + 0.5 * s.w
		var basis := Basis.looking_at(fwd if fwd.length() > 0.01 else Vector3.FORWARD, Vector3.UP)
		basis = basis * Basis(Vector3(0, 0, 1), bank)
		mm.set_instance_transform(i, Transform3D(basis.scaled(Vector3.ONE * sc), center + p))

static func _h(a: float, b: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)

static func _palette(k: String) -> Array:
	match k:
		"birds":
			return [Color("3a3440"), Color("4a4038"), Color("5a5048")]
		"cranes":
			return [Color("f4f4f0"), Color("ffffff")]
		"butterflies":
			return [Color("ffd040"), Color("ff8ab0"), Color("80c0ff"), Color("ffffff"), Color("ff7040")]
		"dragonflies":
			return [Color("40d0ff"), Color("60ff90"), Color("ff6040")]
		"fish":
			return [Color("ff8030"), Color("ffffff"), Color("ffc060"), Color("e04020")]
		"moths":
			return [Color("c0ffe0"), Color("ffe0a0"), Color("a0c0ff")]
		"bats":
			return [Color("202838"), Color("303848")]
	return [Color.WHITE]

## Mesh for one animal (body alpha 0, wings alpha 1 so the shader flaps only the wings).
static func mesh_for(k: String) -> ArrayMesh:
	if _meshes.has(k):
		return _meshes[k]
	var b := MB.new()
	var wing := func(span: float, chord: float, sweep: float, tipc: Color, rootc: Color, z0: float) -> void:
		for sd: float in [-1.0, 1.0]:
			var base := b.v.size()
			var pts := [Vector3(0.03 * sd, 0, z0 + chord * 0.5), Vector3(span * sd, 0.0, z0 - sweep), Vector3(span * 0.85 * sd, 0, z0 - sweep - chord * 0.6), Vector3(0.03 * sd, 0, z0 - chord * 0.5)]
			var cols := [rootc, tipc, tipc, rootc]
			for q in 4:
				b.v.append(pts[q])
				b.n.append(Vector3.UP)
				var c: Color = cols[q]
				b.c.append(Color(c.r, c.g, c.b, 1.0 if absf(pts[q].x) > 0.05 else 0.0))
			b.idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var body := func(len_: float, r: float, col: Color) -> void:
		var start := b.v.size()
		b.sph(Vector3(0, 0, 0), Vector3(r, r * 0.8, len_ * 0.5), col)
		for i in range(start, b.v.size()):
			var cc: Color = b.c[i]
			b.c[i] = Color(cc.r, cc.g, cc.b, 0.0)
	var speed := 8.0
	var amp := 0.9
	var glow := 0.0
	match k:
		"birds":
			body.call(0.32, 0.06, Color(0.9, 0.9, 0.9))
			wing.call(0.34, 0.14, 0.06, Color(0.7, 0.7, 0.7), Color(1, 1, 1), 0.0)
			speed = 11.0
		"cranes":
			body.call(0.45, 0.07, Color(1, 1, 1))
			wing.call(0.6, 0.18, 0.08, Color(0.25, 0.25, 0.3), Color(1, 1, 1), 0.0)
			var st := b.v.size()
			b.limb(Vector3(0, 0.02, 0.2), Vector3(0, 0.05, 0.5), 0.02, 0.012, Color(1, 1, 1))
			b.cone(Vector3(0, 0.05, 0.56), 0.012, 0.1, Color(1.0, 0.3, 0.2), Vector3(PI * 0.5, 0, 0), 6)
			for i in range(st, b.v.size()):
				var cc2: Color = b.c[i]
				b.c[i] = Color(cc2.r, cc2.g, cc2.b, 0.0)
			speed = 4.0
			amp = 0.6
		"butterflies":
			body.call(0.08, 0.012, Color(0.3, 0.3, 0.3))
			wing.call(0.09, 0.09, -0.02, Color(1, 1, 1), Color(0.8, 0.8, 0.8), 0.02)
			wing.call(0.07, 0.06, 0.02, Color(0.85, 0.85, 0.85), Color(0.7, 0.7, 0.7), -0.04)
			speed = 16.0
			amp = 1.1
		"dragonflies":
			body.call(0.16, 0.012, Color(1, 1, 1))
			wing.call(0.1, 0.025, 0.0, Color(0.9, 0.95, 1.0), Color(0.9, 0.95, 1.0), 0.03)
			wing.call(0.09, 0.025, 0.0, Color(0.9, 0.95, 1.0), Color(0.9, 0.95, 1.0), -0.01)
			speed = 40.0
			amp = 0.4
		"fish":
			var st2 := b.v.size()
			b.sph(Vector3(0, 0, 0), Vector3(0.05, 0.06, 0.16), Color(1, 1, 1))
			b.cone(Vector3(0, 0, -0.19), 0.06, 0.08, Color(1, 1, 1), Vector3(-PI * 0.5, 0, 0), 6)
			for i in range(st2, b.v.size()):
				var cc3: Color = b.c[i]
				b.c[i] = Color(cc3.r, cc3.g, cc3.b, 0.0)
			wing.call(0.07, 0.04, 0.03, Color(1, 1, 1), Color(1, 1, 1), 0.06)
			speed = 6.0
			amp = 0.5
		"moths":
			body.call(0.06, 0.015, Color(1, 1, 1))
			wing.call(0.08, 0.08, 0.0, Color(1, 1, 1), Color(0.8, 0.8, 0.8), 0.0)
			speed = 12.0
			glow = 0.9
		"bats":
			body.call(0.12, 0.03, Color(1, 1, 1))
			wing.call(0.22, 0.1, -0.04, Color(0.8, 0.8, 0.8), Color(1, 1, 1), 0.0)
			speed = 14.0
			glow = 0.15
	var m := ShaderMaterial.new()
	m.shader = MB._shader(FLAP)
	m.set_shader_parameter("speed", speed)
	m.set_shader_parameter("amp", amp)
	m.set_shader_parameter("glow", glow)
	var mesh := b.build(m)
	_meshes[k] = mesh
	return mesh
