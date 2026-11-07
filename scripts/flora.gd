class_name Flora
extends RefCounted
## Procedural plants.  Every species is a *recipe* (growth form, size ranges, branching, leaf texture,
## colours) and every call with a different variant number grows a different individual from it, so
## a forest is never one tree copied a thousand times.
##
## Trees grow recursively: a trunk of several bent, tapering segments, then branches that split off
## at random azimuths and recurse with shorter, thinner segments.  Bends are a mix of random "gnarl"
## and phototropism (branches curve back towards the light).  At every branch tip a leaf clump of
## crossing cards is placed; card normals are spherized around the crown, so the canopy lights as one
## soft volume.  Clumps low in the crown and on the shaded side are darkened (baked occlusion).
##
## Growth forms: broad (oak, maple, birch, blossom, acacia, dead), conifer (pine, fir, cypress, snowy
## pine), bamboo clumps, weeping willow, palm, windswept bonsai, mangrove on stilt roots, saguaro
## cactus, giant glowing mushroom, crystal tree, karst bush.  Understorey: bush, flowering bush, fern,
## reeds and cattails, dead bush, snowy bush, kelp, glowshroom cluster, spider lilies, agave, flower
## patch, sapling and fallen log.

const VARIANTS := 5
static var _cache := {}

## h: height range, r: trunk radius range, levels: recursion depth, kids: branches per split,
## angle: branch angle from the parent (radians), ratio: child/parent length, gnarl: random bend,
## up: phototropism, clump: leaf clump size, leaf: texture kind, flat: canopy squash.
const SPECIES := {
	# ---- broad-leaved trees
	"oak": {"form": "broad", "h": [4.6, 6.4], "r": [0.2, 0.3], "levels": 3, "kids": [2, 4], "angle": [0.55, 0.95], "ratio": 0.6, "gnarl": 0.24, "up": 0.3,
		"leaf": "broad", "clump": [1.15, 1.55], "bark": "6a5038", "c1": "4f8a3a", "c2": "86b04a"},
	"autumn_oak": {"form": "broad", "h": [4.4, 6.2], "r": [0.2, 0.28], "levels": 3, "kids": [3, 4], "angle": [0.55, 0.95], "ratio": 0.6, "gnarl": 0.24, "up": 0.3,
		"leaf": "autumn", "clump": [1.1, 1.5], "bark": "5a4232", "c1": "e8a040", "c2": "f0d060"},
	"maple": {"form": "broad", "h": [4.8, 6.8], "r": [0.16, 0.24], "levels": 3, "kids": [3, 4], "angle": [0.45, 0.85], "ratio": 0.62, "gnarl": 0.18, "up": 0.45,
		"leaf": "maple", "clump": [1.0, 1.35], "bark": "4a3a34", "c1": "e04a2a", "c2": "f5a030"},
	"birch": {"form": "broad", "h": [5.6, 7.6], "r": [0.1, 0.15], "levels": 3, "kids": [2, 3], "angle": [0.3, 0.6], "ratio": 0.55, "gnarl": 0.12, "up": 0.6,
		"leaf": "round", "clump": [0.85, 1.05], "bark": "ece8de", "marks": "3a3430", "c1": "86b83e", "c2": "c8d852"},
	"blossom": {"form": "broad", "h": [3.8, 5.2], "r": [0.16, 0.22], "levels": 3, "kids": [3, 4], "angle": [0.6, 1.05], "ratio": 0.62, "gnarl": 0.3, "up": 0.25,
		"leaf": "blossom", "clump": [1.05, 1.4], "bark": "4a3430", "c1": "ffffff", "c2": "fff0f4"},
	"acacia": {"form": "broad", "h": [3.6, 4.8], "r": [0.14, 0.2], "levels": 2, "kids": [3, 4], "angle": [0.7, 1.05], "ratio": 0.75, "gnarl": 0.2, "up": 0.65,
		"leaf": "round", "clump": [1.2, 1.6], "flat": 0.4, "bark": "7a5a40", "c1": "6a8a3a", "c2": "a8a848"},
	"dead": {"form": "broad", "h": [3.6, 5.4], "r": [0.15, 0.24], "levels": 3, "kids": [2, 3], "angle": [0.5, 1.1], "ratio": 0.6, "gnarl": 0.45, "up": 0.15,
		"leaf": "", "bark": "5a5458"},
	"marsh_dead": {"form": "broad", "h": [3.4, 4.8], "r": [0.16, 0.24], "levels": 2, "kids": [3, 4], "angle": [0.6, 1.1], "ratio": 0.65, "gnarl": 0.4, "up": 0.1,
		"leaf": "willow", "moss": true, "clump": [0.9, 1.2], "bark": "3a302c", "c1": "6a7a4a", "c2": "8a8a5a"},
	"ashen": {"form": "broad", "h": [3.0, 4.6], "r": [0.14, 0.22], "levels": 2, "kids": [2, 3], "angle": [0.5, 1.0], "ratio": 0.6, "gnarl": 0.5, "up": 0.2,
		"leaf": "", "bark": "2a2220", "embers": true},
	"peach": {"form": "broad", "h": [3.4, 4.6], "r": [0.15, 0.22], "levels": 3, "kids": [3, 4], "angle": [0.6, 1.0], "ratio": 0.6, "gnarl": 0.3, "up": 0.25,
		"leaf": "broad", "clump": [1.0, 1.3], "fruit": "ffa090", "bark": "5a4034", "c1": "5a9a48", "c2": "8ab858"},
	"ginkgo": {"form": "broad", "h": [5.4, 7.4], "r": [0.16, 0.22], "levels": 3, "kids": [2, 3], "angle": [0.35, 0.7], "ratio": 0.6, "gnarl": 0.14, "up": 0.55,
		"leaf": "ginkgo", "clump": [0.95, 1.25], "bark": "5a4a3a", "c1": "f0c840", "c2": "f8e070"},
	# Part IX: the mulberries of the Fusang valley (dark fruit) and the moon's osmanthus, silver-green
	# with clusters of tiny golden flowers
	"mulberry": {"form": "broad", "h": [4.8, 6.6], "r": [0.2, 0.3], "levels": 3, "kids": [3, 4], "angle": [0.6, 1.0], "ratio": 0.62, "gnarl": 0.3, "up": 0.3,
		"leaf": "broad", "clump": [1.15, 1.5], "fruit": "5a2a4a", "bark": "6a5040", "c1": "3f8a3a", "c2": "7ab048"},
	"osmanthus": {"form": "broad", "h": [3.6, 5.0], "r": [0.15, 0.22], "levels": 3, "kids": [3, 4], "angle": [0.55, 0.95], "ratio": 0.6, "gnarl": 0.22, "up": 0.35,
		"leaf": "round", "clump": [1.0, 1.35], "fruit": "f8c048", "bark": "6a6a78", "c1": "5a7a70", "c2": "a8c0b0"},
	"wisteria": {"form": "wisteria", "h": [3.2, 4.2], "r": [0.16, 0.24], "leaf": "round", "bark": "5a4a40", "c1": "5a8a44", "c2": "7aa050"},
	# ---- conifers
	"pine": {"form": "conifer", "h": [6.0, 8.6], "r": [0.15, 0.22], "whorls": [7, 10], "spread": [1.7, 2.3], "leaf": "needle", "bark": "5a4030", "c1": "2c6644", "c2": "4a8a5a"},
	"fir": {"form": "conifer", "h": [5.0, 7.0], "r": [0.14, 0.2], "whorls": [8, 11], "spread": [1.3, 1.8], "leaf": "needle", "bark": "4a3830", "c1": "28583c", "c2": "3a7050"},
	"cypress": {"form": "conifer", "h": [6.5, 9.0], "r": [0.12, 0.18], "whorls": [9, 12], "spread": [0.7, 1.0], "leaf": "needle", "bark": "5a4436", "c1": "2a5a3a", "c2": "3e6a46"},
	"snowpine": {"form": "conifer", "h": [5.4, 8.0], "r": [0.15, 0.2], "whorls": [7, 10], "spread": [1.5, 2.1], "leaf": "needle", "snow": true, "bark": "4a3a34", "c1": "2a5a4a", "c2": "3a6a5a"},
	# ---- special forms
	"bamboo": {"form": "bamboo", "h": [6.0, 9.5], "culms": [7, 13], "leaf": "bamboo", "bark": "7ab048", "c1": "6aa040", "c2": "a8c858"},
	"willow": {"form": "willow", "h": [3.8, 5.0], "r": [0.24, 0.32], "leaf": "round", "bark": "4a3a2a", "c1": "5a8a3a", "c2": "7aa04a"},
	"palm": {"form": "palm", "h": [4.5, 6.5], "r": [0.14, 0.18], "leaf": "palm", "bark": "8a6a48", "c1": "5a9a40", "c2": "8ab850"},
	"bonsai": {"form": "bonsai", "h": [3.2, 4.6], "r": [0.16, 0.24], "leaf": "needle", "bark": "5a4232", "c1": "3a7048", "c2": "5a9058"},
	"mangrove": {"form": "mangrove", "h": [3.4, 4.6], "r": [0.18, 0.24], "leaf": "round", "bark": "4a3a30", "c1": "3e5a34", "c2": "5a7040"},
	"cactus": {"form": "cactus", "h": [2.6, 4.2], "r": [0.2, 0.28], "bark": "5a8a4a", "c1": "ff8090", "c2": "ffd060"},
	"giant_shroom": {"form": "mushroom", "h": [3.4, 5.6], "r": [0.2, 0.34], "bark": "e8e0f0", "c1": "c070e0", "c2": "60e0d0"},
	"crystal_tree": {"form": "crystal", "h": [3.4, 5.0], "r": [0.1, 0.16], "leaf": "crystal", "bark": "8a70d0", "c1": "c0a0ff", "c2": "80e0ff"},
	"karst_bush": {"form": "broad", "h": [2.0, 2.8], "r": [0.08, 0.12], "levels": 2, "kids": [3, 4], "angle": [0.7, 1.2], "ratio": 0.7, "gnarl": 0.35, "up": 0.3,
		"leaf": "round", "clump": [0.7, 0.95], "bark": "5a4a3a", "c1": "3a7a44", "c2": "6a9a4a"},
	# ---- understorey
	"bush": {"form": "bush", "h": [0.7, 1.2], "leaf": "broad", "c1": "4a8a3e", "c2": "7aa84a"},
	"round_bush": {"form": "bush", "h": [0.6, 1.0], "leaf": "round", "c1": "4a7a40", "c2": "6a9a48"},
	"flowerbush": {"form": "bush", "h": [0.7, 1.1], "leaf": "blossom", "c1": "ffffff", "c2": "ffe0ea"},
	"autumn_bush": {"form": "bush", "h": [0.6, 1.0], "leaf": "maple", "c1": "e05a30", "c2": "f0b040"},
	"snowbush": {"form": "bush", "h": [0.5, 0.9], "leaf": "needle", "snow": true, "c1": "5a7a6a", "c2": "7a9a8a"},
	"fern": {"form": "fern", "h": [0.6, 1.1], "leaf": "frond", "c1": "4a9a44", "c2": "7ab858"},
	"reeds": {"form": "reeds", "h": [1.0, 1.8], "leaf": "bamboo", "c1": "7a9a4a", "c2": "b0b060"},
	"deadbush": {"form": "deadbush", "h": [0.5, 0.9], "bark": "6a5a4a"},
	"kelp": {"form": "kelp", "h": [1.6, 3.2], "leaf": "frond", "c1": "3a8a5a", "c2": "8aa84a"},
	"glowshroom": {"form": "shrooms", "h": [0.3, 0.7], "c1": "d080f0", "c2": "60f0d0"},
	"spiderlily": {"form": "lilies", "h": [0.5, 0.8], "leaf": "lily", "c1": "ffffff", "c2": "fff0f0"},
	"agave": {"form": "agave", "h": [0.5, 0.9], "c1": "6a9a8a", "c2": "a8b878"},
	"lotus": {"form": "lotus", "h": [0.5, 0.9], "c1": "4a9a5a", "c2": "ff9ac0"},
	"flowers": {"form": "flowers", "h": [0.25, 0.45], "c1": "ffffff", "c2": "ffffff"},
	"sapling": {"form": "broad", "h": [1.4, 2.0], "r": [0.04, 0.06], "levels": 2, "kids": [2, 3], "angle": [0.5, 0.8], "ratio": 0.6, "gnarl": 0.2, "up": 0.5,
		"leaf": "broad", "clump": [0.5, 0.7], "bark": "6a5038", "c1": "5a9a44", "c2": "8ab850"},
	"log": {"form": "log", "h": [0.5, 0.7], "r": [0.2, 0.3], "bark": "5a4434", "c1": "5a8a3a", "c2": "7aa04a"},
	"stump": {"form": "stump", "h": [0.4, 0.7], "r": [0.25, 0.35], "bark": "5a4434", "c1": "5a8a3a", "c2": "7aa04a"},
}

## the species that count as undergrowth (no shadows cast, shorter draw distance)
static func is_small(sp: String) -> bool:
	return str(SPECIES.get(sp, {}).get("form", "")) in ["bush", "fern", "reeds", "deadbush", "kelp", "shrooms", "lilies", "agave", "flowers", "log", "stump", "lotus"] or sp == "sapling"

static func _c(hex: String) -> Color:
	return Color(hex)

static func _rr(rng: RandomNumberGenerator, a: Array) -> float:
	return rng.randf_range(float(a[0]), float(a[1]))

## The mesh for one individual: surfaces are bark (toon, outlined), leaf cards and optional glow.
static func mesh(sp: String, variant: int) -> ArrayMesh:
	var key := "%s#%d" % [sp, variant]
	if _cache.has(key):
		return _cache[key]
	var d: Dictionary = SPECIES.get(sp, SPECIES.oak)
	var rng := RandomNumberGenerator.new()
	rng.seed = (hash(sp) & 0xffffff) * 31 + variant * 7919 + 17
	var b := MB.new()
	var g := MB.new()
	var cards := Nature.Cards.new()
	var extra := Nature.Cards.new()
	var extra_kind := ""
	match str(d.form):
		"broad":
			_broad(b, g, cards, rng, d)
		"conifer":
			_conifer(b, cards, extra, rng, d)
			if d.get("snow", false):
				extra_kind = "round"
		"bamboo":
			_bamboo(b, cards, rng, d)
		"willow":
			_willow(b, cards, extra, rng, d)
			extra_kind = "willow"
		"palm":
			_palm(b, cards, rng, d)
		"wisteria":
			_wisteria(b, cards, extra, rng, d)
			extra_kind = "wisteria"
		"lotus":
			_lotus(b, rng, d)
		"bonsai":
			_bonsai(b, cards, rng, d)
		"mangrove":
			_mangrove(b, cards, rng, d)
		"cactus":
			_cactus(b, rng, d)
		"mushroom":
			_giant_mushroom(b, g, rng, d)
		"crystal":
			_crystal_tree(b, g, cards, rng, d)
		"bush":
			_bush(b, cards, extra, rng, d)
			if d.get("snow", false):
				extra_kind = "round"
		"fern":
			_fern(cards, rng, d)
		"reeds":
			_reeds(b, cards, rng, d)
		"deadbush":
			_deadbush(b, rng, d)
		"kelp":
			_kelp(cards, rng, d)
		"shrooms":
			_shrooms(b, g, rng, d)
		"lilies":
			_lilies(cards, rng, d)
		"agave":
			_agave(b, rng, d)
		"flowers":
			_flowers(b, rng, d)
		"log":
			_log(b, cards, rng, d)
		"stump":
			_stump(b, cards, rng, d)
	var m: ArrayMesh
	if b.is_empty():
		b.ball(Vector3(0, -20, 0), 0.01, MB.tag(Color.BLACK, MB.STONE), true)
	m = b.build(MB.mat_plain() if is_small(sp) else MB.mat_scenery())
	var leaf: String = str(d.get("leaf", ""))
	if not cards.is_empty() and leaf != "":
		var lg := 0.0
		if leaf in ["crystal", "spore"]:
			lg = 0.45
		cards.add_to(m, Nature.leaf_mat(leaf, lg))
	if not extra.is_empty():
		extra.add_to(m, Nature.leaf_mat(extra_kind if extra_kind != "" else leaf))
	if not g.is_empty():
		g.add_to(m, MB.mat_glow())
	_cache[key] = m
	return m

# ---------------------------------------------------------------- helpers
## direction rotated `ang` away from `dir`, around it at azimuth `az`
static func _away(dir: Vector3, ang: float, az: float) -> Vector3:
	var bs := MB.basis_y(dir)
	var off := bs.x * cos(az) + bs.z * sin(az)
	return (dir * cos(ang) + off * sin(ang)).normalized()

## Leaf clump of crossing cards at `c`.  `crown` is [centre, radius] for the spherized normals.
static func _clump(cards: Nature.Cards, rng: RandomNumberGenerator, c: Vector3, size: float, crown: Array, col: Color, sway: float, flat: float = 1.0, quads: int = 3) -> void:
	var cc: Vector3 = crown[0]
	var cr: float = maxf(float(crown[1]), 0.5)
	var yaw := rng.randf() * TAU
	for i in quads + 1:
		var ax: Vector3
		var ay: Vector3
		if i < quads:
			var a := yaw + PI * i / quads
			var pitch := rng.randf_range(-0.5, 0.5)
			ax = Vector3(cos(a), 0, sin(a)) * size
			ay = Vector3(-sin(a) * sin(pitch), cos(pitch), cos(a) * sin(pitch)) * size * flat
		else:
			# a roughly horizontal card on top, so the crown is closed when seen from above
			var a2 := yaw + 0.4
			ax = Vector3(cos(a2), rng.randf_range(-0.15, 0.15), sin(a2)) * size
			ay = Vector3(-sin(a2), rng.randf_range(-0.15, 0.15), cos(a2)) * size
		var corners := [c - ax + ay, c + ax + ay, c + ax - ay, c - ax - ay]
		var nr: Array = []
		for q in corners:
			nr.append(((q - cc) / cr + (q - c) / maxf(size, 0.01) * 0.45 + Vector3(0, 0.3, 0)).normalized())
		# baked occlusion: clumps on the inside and underside of the crown are darker
		var out_k := clampf(((c - cc) / cr).dot(Vector3(0.3, 0.9, 0.3).normalized()) * 0.5 + 0.5, 0.0, 1.0)
		var ao := lerpf(0.7, 1.1, out_k)
		var cl := Color(col.r * ao, col.g * ao, col.b * ao)
		cards.quad(c, ax, ay, cl, sway, nr)

static func _leaf_col(rng: RandomNumberGenerator, d: Dictionary) -> Color:
	return _c(d.get("c1", "5a9a40")).lerp(_c(d.get("c2", "8ab850")), rng.randf())

## recursive branch growth (see the class comment)
static func _grow(b: MB, rng: RandomNumberGenerator, d: Dictionary, p: Vector3, dir: Vector3, length: float, r: float, depth: int, tips: Array, bark: Color) -> void:
	var levels: int = int(d.get("levels", 3))
	var segs := 3 if depth == 0 else 2
	var gn: float = float(d.get("gnarl", 0.2))
	var up: float = float(d.get("up", 0.3))
	var cur := p
	var cd := dir
	var r0 := r
	var path: Array = [[cur, r0, cd]]
	for s in segs:
		var sl := length / segs
		var bend := Vector3(rng.randf_range(-gn, gn), rng.randf_range(-gn, gn) * 0.4, rng.randf_range(-gn, gn))
		cd = (cd + bend + Vector3(0, up * 0.3 * (depth + 1) * 0.5, 0)).normalized()
		var nxt := cur + cd * sl
		var r1 := r * (1.0 - (s + 1.0) / segs * 0.38)
		if depth == 0:
			b.limb(cur, nxt, r0, r1, bark, 7)
		elif r0 > 0.02:
			_seg(b, cur, nxt, r0, r1, bark, 5 if r0 > 0.06 else 4)
		path.append([nxt, r1, cd])
		cur = nxt
		r0 = r1
	if depth >= levels or r0 < 0.012:
		tips.append([cur, cd, depth])
		return
	var k0: int = int(d.kids[0])
	var k1: int = int(d.kids[1])
	var kids := rng.randi_range(k0, k1)
	var az0 := rng.randf() * TAU
	for k in kids:
		var leader := k == 0
		var t := 1.0 if leader else rng.randf_range(0.45, 0.95)
		var fi := t * segs
		var i0 := mini(int(fi), segs - 1)
		var f := fi - i0
		var a: Array = path[i0]
		var bb: Array = path[i0 + 1]
		var sp: Vector3 = (a[0] as Vector3).lerp(bb[0], f)
		var sr: float = lerpf(a[1], bb[1], f)
		var ang := rng.randf_range(float(d.angle[0]), float(d.angle[1])) * (0.45 if leader else 1.0)
		var ndir := _away(cd, ang, az0 + TAU * k / kids + rng.randf_range(-0.4, 0.4))
		var nl := length * float(d.get("ratio", 0.6)) * rng.randf_range(0.85, 1.12) * (1.0 if leader else 0.9)
		_grow(b, rng, d, sp, ndir, nl, sr * (0.78 if leader else 0.6), depth + 1, tips, bark)
	# a twig or two along the branch keeps the crown full near the inside
	if depth == levels - 1 and rng.randf() < 0.6:
		var mid: Array = path[1]
		tips.append([mid[0], mid[2], depth + 1])

## a tapered branch segment without end caps (cheaper than MB.limb for the many thin branches)
static func _seg(b: MB, a: Vector3, e: Vector3, r0: float, r1: float, col: Color, sides: int) -> void:
	var d := e - a
	if d.length() < 0.0001:
		return
	var bs := MB.basis_y(d)
	var base := b.v.size()
	var lc := col.srgb_to_linear()
	lc.a = col.a
	for i in sides + 1:
		var ang := TAU * i / sides
		var dirv := bs.x * cos(ang) + bs.z * sin(ang)
		b.v.append(a + dirv * r0)
		b.n.append(dirv)
		b.c.append(lc)
		b.v.append(e + dirv * maxf(r1, 0.004))
		b.n.append(dirv)
		b.c.append(lc)
	for i in sides:
		var k := base + i * 2
		b.idx.append_array([k, k + 2, k + 1, k + 1, k + 2, k + 3])

static func _crown_of(tips: Array) -> Array:
	var c := Vector3.ZERO
	for t in tips:
		c += t[0]
	c /= maxf(tips.size(), 1)
	var r := 0.0
	for t in tips:
		r = maxf(r, (t[0] as Vector3).distance_to(c))
	return [c, r + 0.4]

# ---------------------------------------------------------------- growth forms
static func _broad(b: MB, g: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var bark := MB.tag(_c(d.bark).darkened(rng.randf() * 0.1), MB.WOOD)
	var lean := Vector3(rng.randf_range(-0.12, 0.12), 1.0, rng.randf_range(-0.12, 0.12)).normalized()
	# root flare: a few buttress roots so the trunk sits in the ground
	for i in 4:
		var a := TAU * i / 4.0 + rng.randf_range(-0.3, 0.3)
		b.limb(Vector3(cos(a) * r * 0.2, 0.35, sin(a) * r * 0.2), Vector3(cos(a) * r * 2.4, -0.08, sin(a) * r * 2.4), r * 0.55, r * 0.15, bark, 5)
	var tips: Array = []
	_grow(b, rng, d, Vector3(0, -0.1, 0), lean, h * 0.5, r, 0, tips, bark)
	if d.has("marks"):
		# birch: dark lenticel bands on the white bark
		for i in 9:
			var y := rng.randf_range(0.4, h * 0.45)
			b.cyl(lean * (y / lean.y), r * 0.95 + 0.006, rng.randf_range(0.03, 0.08), MB.tag(_c(d.marks), MB.WOOD), Vector3(0, rng.randf() * TAU, rng.randf_range(-0.1, 0.1)), 7)
	var leaf: String = str(d.get("leaf", ""))
	var crown := _crown_of(tips)
	var flat: float = float(d.get("flat", 1.0))
	if leaf != "":
		for t in tips:
			var tp: Vector3 = t[0]
			var td: Vector3 = t[1]
			var sz := _rr(rng, d.clump) * (0.8 if int(t[2]) > int(d.get("levels", 3)) else 1.0)
			var sway := clampf(tp.y / maxf(h, 0.1), 0.2, 1.0)
			_clump(cards, rng, tp + td * sz * 0.25, sz, crown, _leaf_col(rng, d), sway, flat)
			if rng.randf() < 0.55:
				var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.6), rng.randf_range(-1, 1)) * sz * 0.6
				_clump(cards, rng, tp + off, sz * 0.8, crown, _leaf_col(rng, d), sway, flat, 2)
	if d.get("moss", false):
		# hanging moss beards
		for t in tips:
			if rng.randf() < 0.6:
				var tp2: Vector3 = t[0]
				var ln := rng.randf_range(0.8, 1.6)
				var side := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
				cards.strip([tp2, tp2 + Vector3(0.05, -ln * 0.5, 0), tp2 + Vector3(0, -ln, 0.05)], [0.18, 0.16, 0.08], side, _leaf_col(rng, d).darkened(0.2), [0.5, 0.8, 1.0], [Vector3.UP, Vector3.UP, Vector3.UP])
	if d.has("fruit"):
		for t in tips:
			if rng.randf() < 0.5:
				b.ball((t[0] as Vector3) + Vector3(rng.randf_range(-0.4, 0.4), -0.3, rng.randf_range(-0.4, 0.4)), 0.09, MB.tag(_c(d.fruit), MB.SKIN), true)
	if d.get("embers", false):
		for t in tips:
			if rng.randf() < 0.5:
				g.ball(t[0], 0.08, Color(1.0, 0.45, 0.1, 0.8), true)

static func _conifer(b: MB, cards: Nature.Cards, snow: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var spread := _rr(rng, d.spread)
	var bark := MB.tag(_c(d.bark), MB.WOOD)
	var lean := Vector3(rng.randf_range(-0.05, 0.05), 1.0, rng.randf_range(-0.05, 0.05)).normalized()
	var top := lean * h
	b.limb(Vector3(0, -0.1, 0), top * 0.55, r, r * 0.6, bark, 7)
	b.limb(top * 0.55, top, r * 0.6, r * 0.12, bark, 6)
	for i in 3:
		var a := TAU * i / 3.0 + rng.randf()
		b.limb(Vector3(0, 0.25, 0), Vector3(cos(a) * r * 2.0, -0.06, sin(a) * r * 2.0), r * 0.5, r * 0.15, bark, 5)
	var n := rng.randi_range(int(d.whorls[0]), int(d.whorls[1]))
	var snowy: bool = d.get("snow", false)
	for i in n:
		var t := lerpf(0.16, 0.94, i / float(n - 1)) + rng.randf_range(-0.02, 0.02)
		var y := t * h
		var axis := lean * y
		var rad := spread * pow(1.0 - t, 0.9) + 0.28
		var nb := rng.randi_range(5, 7)
		var az := rng.randf() * TAU
		for k in nb:
			var a := az + TAU * k / nb + rng.randf_range(-0.25, 0.25)
			var dirh := Vector3(cos(a), 0, sin(a))
			var droop := -0.12 - 0.25 * (1.0 - t) + rng.randf_range(-0.08, 0.08)
			var dir := (dirh + Vector3(0, droop, 0)).normalized()
			var ln := rad * rng.randf_range(0.85, 1.1)
			var tip := axis + dir * ln
			if t < 0.75:
				b.limb(axis, tip, r * 0.28 * (1.0 - t), 0.01, bark, 4)
			var side := Vector3(-dirh.z, 0, dirh.x)
			var cnt := 2 if ln > 0.9 else 1
			for j in cnt:
				var f := (j + 1.0) / (cnt + 0.6)
				var pc := axis + dir * ln * f
				var sz := ln * 0.42 + 0.22
				var ax := dir * sz
				var ay := (side * 0.9 + Vector3(0, 0.35, 0)) * sz * 0.85
				var col := _leaf_col(rng, d) * lerpf(0.65, 1.05, t)
				var nr: Array = []
				for q: Vector3 in [pc - ax + ay, pc + ax + ay, pc + ax - ay, pc - ax - ay]:
					nr.append(((q - axis) / maxf(rad, 0.3) + Vector3(0, 0.55, 0)).normalized())
				cards.quad(pc, ax, ay, col, clampf(t + 0.2, 0.2, 1.0), nr)
				if snowy and rng.randf() < 0.7:
					var sc := pc + Vector3(0, 0.1, 0)
					var sax := dir * sz * 0.75
					var say := side * sz * 0.55
					var w := Color(0.95, 0.97, 1.0) * lerpf(0.85, 1.05, t)
					snow.quad(sc, sax, say, w, clampf(t + 0.2, 0.2, 1.0), [Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	# leader tuft
	for k in 3:
		var a2 := TAU * k / 3.0
		var pc2 := top + Vector3(0, -0.25, 0)
		var ax2 := Vector3(cos(a2), 0, sin(a2)) * 0.28
		cards.quad(pc2, ax2, Vector3(0, 0.45, 0), _leaf_col(rng, d), 1.0, [Vector3(cos(a2), 0.6, sin(a2)).normalized(), Vector3(cos(a2), 0.6, sin(a2)).normalized(), Vector3(cos(a2), 0.6, sin(a2)).normalized(), Vector3(cos(a2), 0.6, sin(a2)).normalized()])

static func _bamboo(b: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var culms := rng.randi_range(int(d.culms[0]), int(d.culms[1]))
	var hmax := _rr(rng, d.h)
	for i in culms:
		var a := rng.randf() * TAU
		var rad := sqrt(rng.randf()) * 0.75
		var base := Vector3(cos(a) * rad, -0.05, sin(a) * rad)
		var age := rng.randf()
		var h := hmax * rng.randf_range(0.55, 1.0)
		var lean := Vector3(cos(a) * rad * 0.12 + rng.randf_range(-0.05, 0.05), 1.0, sin(a) * rad * 0.12 + rng.randf_range(-0.05, 0.05)).normalized()
		var bend := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.2, 0.7)
		var col := _c(d.bark).lerp(Color("c8b860"), age * 0.45).darkened(rng.randf() * 0.12)
		var r := rng.randf_range(0.045, 0.075) * (h / hmax + 0.4)
		var nodes := int(h / 0.55)
		var prev := base
		for k in range(1, nodes + 1):
			var t := k / float(nodes)
			var p := base + lean * h * t + bend * t * t
			b.limb(prev, p, r * (1.0 - t * 0.35), r * (1.0 - t * 0.35), MB.tag(col, MB.WOOD), 6)
			b.cyl(p, r * (1.12 - t * 0.35), 0.035, MB.tag(col.darkened(0.3), MB.WOOD), Vector3.ZERO, 6)
			if t > 0.45:
				var n_leaf := 2 if t < 0.9 else 3
				for j in n_leaf:
					var la := rng.randf() * TAU
					var out := Vector3(cos(la), 0, sin(la))
					var sz := rng.randf_range(0.42, 0.62)
					var pc := p + out * sz * 0.8 + Vector3(0, -0.05, 0)
					var ax := out * sz
					var ay := Vector3(-out.z, 0.45, out.x).normalized() * sz * 0.8
					var nn := (out + Vector3(0, 0.6, 0)).normalized()
					cards.quad(pc, ax, ay, _leaf_col(rng, d), t, [nn, nn, nn, nn])
			prev = p
	# fallen sheaths and shoots at the foot of the clump
	for i in 4:
		var a2 := rng.randf() * TAU
		b.cone(Vector3(cos(a2), 0.12, sin(a2)) * rng.randf_range(0.4, 1.0), 0.06, rng.randf_range(0.2, 0.4), MB.tag(Color("a8a058"), MB.WOOD), Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2)), 6)

static func _willow(b: MB, cards: Nature.Cards, strands: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var bark := MB.tag(_c(d.bark), MB.WOOD)
	var top := Vector3(rng.randf_range(-0.3, 0.3), h * 0.55, rng.randf_range(-0.3, 0.3))
	b.limb(Vector3(0, -0.1, 0), top * 0.5 + Vector3(0.1, 0, 0), r, r * 0.85, bark, 8)
	b.limb(top * 0.5 + Vector3(0.1, 0, 0), top, r * 0.85, r * 0.7, bark, 8)
	var tips: Array = []
	var nb := rng.randi_range(5, 7)
	for k in nb:
		var a := TAU * k / nb + rng.randf_range(-0.3, 0.3)
		var out := Vector3(cos(a), 0, sin(a))
		var p1 := top + out * rng.randf_range(0.8, 1.3) + Vector3(0, rng.randf_range(0.6, 1.1), 0)
		var p2 := p1 + out * rng.randf_range(0.8, 1.4) + Vector3(0, rng.randf_range(0.0, 0.4), 0)
		b.limb(top, p1, r * 0.55, r * 0.32, bark, 6)
		b.limb(p1, p2, r * 0.32, r * 0.12, bark, 5)
		tips.append(p1)
		tips.append(p2)
		tips.append(p1.lerp(p2, 0.5) + Vector3(-out.z, 0.1, out.x) * 0.5)
	var crown := [top + Vector3(0, 1.0, 0), 2.6]
	# a soft rounded crown of small leaves...
	for tp in tips:
		_clump(cards, rng, tp + Vector3(0, 0.25, 0), rng.randf_range(0.85, 1.15), crown, _leaf_col(rng, d), 0.6, 0.8, 3)
	_clump(cards, rng, top + Vector3(0, 1.3, 0), 1.2, crown, _leaf_col(rng, d), 0.6, 0.8, 3)
	# ...with thin strands spilling from all over the dome: the further out a strand starts, the
	# lower it starts and the longer it hangs, so the tree has the willow's weeping silhouette
	var n_str := rng.randi_range(22, 30)
	var dome_r := 2.1
	for k in n_str:
		var a := TAU * k / n_str + rng.randf_range(-0.2, 0.2)
		var out2 := Vector3(cos(a), 0, sin(a))
		var rr := dome_r * sqrt(rng.randf_range(0.15, 1.0))
		var rim := top + out2 * rr + Vector3(0, 1.5 * (1.0 - pow(rr / dome_r, 2.0)) + 0.4 + rng.randf_range(-0.2, 0.2), 0)
		var ln := clampf(0.8 + rr * 0.9 + rng.randf_range(-0.3, 0.3), 0.6, rim.y - 0.25)
		var pts := [rim, rim + out2 * 0.15 + Vector3(0, -ln * 0.35, 0), rim + out2 * 0.24 + Vector3(0, -ln * 0.7, 0), rim + out2 * 0.27 + Vector3(0, -ln, 0)]
		var side := Vector3(-out2.z, 0, out2.x).rotated(Vector3.UP, rng.randf_range(-0.5, 0.5))
		var nn := (out2 + Vector3(0, 0.25, 0)).normalized()
		strands.strip(pts, [0.09, 0.1, 0.085, 0.04], side, _leaf_col(rng, d).darkened(rng.randf() * 0.15), [0.5, 0.8, 1.0, 1.2], [nn, nn, nn, nn])

## Wisteria: a low, spreading, twisted trunk under a flat canopy, hung with racemes of flowers.
static func _wisteria(b: MB, cards: Nature.Cards, flowers: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var bark := MB.tag(_c(d.bark), MB.WOOD)
	# two trunks twisting around each other
	for k in 2:
		var prev := Vector3(0, -0.1, 0)
		for i in range(1, 6):
			var t := i / 5.0
			var p := Vector3(sin(t * 5.0 + k * PI) * 0.18, h * 0.7 * t, cos(t * 5.0 + k * PI) * 0.18)
			b.limb(prev, p, r * (1.0 - t * 0.4), r * (1.0 - t * 0.45), bark, 6)
			prev = p
	var top := Vector3(0, h * 0.7, 0)
	var tips: Array = []
	for k in rng.randi_range(5, 7):
		var a := TAU * k / 6.0 + rng.randf_range(-0.3, 0.3)
		var out := Vector3(cos(a), 0, sin(a))
		var tip := top + out * rng.randf_range(1.4, 2.2) + Vector3(0, rng.randf_range(0.1, 0.5), 0)
		_seg(b, top, tip, r * 0.5, r * 0.15, bark, 5)
		tips.append(tip)
		tips.append(top.lerp(tip, 0.55) + Vector3(0, 0.25, 0))
	var crown := [top + Vector3(0, 0.6, 0), 2.4]
	for tp in tips:
		_clump(cards, rng, tp + Vector3(0, 0.15, 0), rng.randf_range(0.8, 1.05), crown, _leaf_col(rng, d), 0.6, 0.55, 3)
	# hanging racemes
	for k in rng.randi_range(18, 26):
		var a2 := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * 2.1
		var st := top + Vector3(cos(a2) * rr, 0.15 + rng.randf_range(-0.1, 0.25), sin(a2) * rr)
		var ln := rng.randf_range(0.6, 1.2)
		var side := Vector3(-sin(a2), 0, cos(a2))
		var nn := Vector3(cos(a2), 0.4, sin(a2)).normalized()
		var tint := Color(1, 1, 1).darkened(rng.randf() * 0.15)
		flowers.strip([st, st + Vector3(0, -ln * 0.5, 0.02), st + Vector3(0, -ln, 0.04)], [0.12, 0.1, 0.05], side, tint, [0.6, 0.9, 1.1], [nn, nn, nn])

## Lotus: round pads floating flat on the water, a few raised on stalks, and pink blooms.
static func _lotus(b: MB, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var pad := MB.tag(_c(d.c1), MB.FOLIAGE)
	for i in rng.randi_range(3, 6):
		var a := rng.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * 0.7
		var rr := rng.randf_range(0.18, 0.34)
		var raised := rng.randf() < 0.3
		var y := rng.randf_range(0.2, 0.45) if raised else 0.02
		if raised:
			b.limb(p + Vector3(0, -0.2, 0), p + Vector3(0, y, 0), 0.012, 0.01, MB.tag(Color("4a8a40"), MB.FOLIAGE), 4)
		b.disc(p + Vector3(0, y, 0), rr, pad, 14, MB.tag(_c(d.c1).darkened(0.25), MB.FOLIAGE), Vector3(rng.randf_range(-0.15, 0.15) if raised else 0.0, 0, 0))
	for i in rng.randi_range(1, 3):
		var a2 := rng.randf() * TAU
		var p2 := Vector3(cos(a2), 0, sin(a2)) * rng.randf_range(0.0, 0.5)
		var top := p2 + Vector3(0, _rr(rng, d.h), 0)
		b.limb(p2 + Vector3(0, -0.2, 0), top, 0.012, 0.01, MB.tag(Color("4a8a40"), MB.FOLIAGE), 4)
		var pc := _c(d.c2)
		for k in 8:
			var pa := TAU * k / 8.0
			var tip := top + Vector3(cos(pa) * 0.12, 0.12 + (k % 2) * 0.03, sin(pa) * 0.12)
			b.leaf(top, tip, 0.06, MB.tag(Color(1, 0.95, 0.97), MB.CLOTH), Vector3(-sin(pa), 0, cos(pa)), MB.tag(pc, MB.CLOTH))
		b.ball(top + Vector3(0, 0.05, 0), 0.03, MB.tag(Color("ffd860"), MB.CLOTH), true)

static func _palm(b: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var bend := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * rng.randf_range(0.6, 1.6)
	var prev := Vector3(0, -0.1, 0)
	var n := 10
	for i in range(1, n + 1):
		var t := i / float(n)
		var p := Vector3(0, h * t, 0) + bend * t * t
		var col := _c(d.bark).darkened(0.12 if i % 2 == 0 else 0.0)
		b.limb(prev, p, r * (1.15 - t * 0.3), r * (1.1 - t * 0.3), MB.tag(col, MB.WOOD), 7)
		prev = p
	var top := prev
	var nf := rng.randi_range(8, 12)
	for k in nf:
		var a := TAU * k / nf + rng.randf_range(-0.2, 0.2)
		var out := Vector3(cos(a), 0, sin(a))
		var ln := rng.randf_range(1.8, 2.6)
		var lift := rng.randf_range(0.2, 0.7)
		var pts: Array = []
		var nr: Array = []
		var sw: Array = []
		for j in 6:
			var t2 := j / 5.0
			pts.append(top + out * ln * t2 + Vector3(0, lift * sin(t2 * PI * 0.8) * 1.2 - t2 * t2 * 1.2, 0))
			nr.append((out * 0.4 + Vector3(0, 1, 0)).normalized())
			sw.append(0.4 + t2 * 0.8)
		cards.strip(pts, [0.06, 0.32, 0.42, 0.42, 0.3, 0.08], Vector3(-out.z, 0, out.x), _leaf_col(rng, d), sw, nr)
	for i in rng.randi_range(2, 4):
		var a2 := rng.randf() * TAU
		b.ball(top + Vector3(cos(a2) * 0.18, -0.2, sin(a2) * 0.18), 0.12, MB.tag(Color("6a5a30"), MB.WOOD), true)

static func _bonsai(b: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var bark := MB.tag(_c(d.bark), MB.WOOD)
	var wind := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
	var pts := [Vector3(0, -0.1, 0)]
	for i in 4:
		var t := (i + 1) / 4.0
		pts.append(Vector3(0, h * 0.7 * t, 0) + wind * sin(t * PI * 1.3) * 0.7 + Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15)))
	for i in 4:
		b.limb(pts[i], pts[i + 1], r * (1.0 - i * 0.2), r * (0.8 - i * 0.18), bark, 7)
	var pads: Array = []
	for k in rng.randi_range(3, 5):
		var from: Vector3 = pts[rng.randi_range(2, 4)]
		var a := rng.randf() * TAU
		var out := Vector3(cos(a), 0, sin(a)).lerp(wind, 0.4).normalized()
		var to := from + out * rng.randf_range(0.8, 1.6) + Vector3(0, rng.randf_range(-0.2, 0.4), 0)
		b.limb(from, to, r * 0.35, r * 0.12, bark, 5)
		pads.append(to)
	pads.append(pts[4] + Vector3(0, 0.2, 0))
	for pc in pads:
		var pr := rng.randf_range(0.7, 1.1)
		for j in 5:
			var a3 := rng.randf() * TAU
			var c := (pc as Vector3) + Vector3(cos(a3) * pr * 0.45, rng.randf_range(0.0, 0.18), sin(a3) * pr * 0.45)
			var ax := Vector3(cos(a3), rng.randf_range(-0.1, 0.1), sin(a3)) * pr * 0.55
			var ay := Vector3(-sin(a3), rng.randf_range(-0.1, 0.1), cos(a3)) * pr * 0.55
			var nn := Vector3(0, 1, 0)
			cards.quad(c, ax, ay, _leaf_col(rng, d) * lerpf(0.75, 1.05, float(j) / 4.0), 0.7, [nn, nn, nn, nn])
		_clump(cards, rng, (pc as Vector3) + Vector3(0, 0.05, 0), pr * 0.7, [pc, pr], _leaf_col(rng, d), 0.7, 0.35, 2)

static func _mangrove(b: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var bark := MB.tag(_c(d.bark), MB.WOOD)
	var knee := Vector3(0, 0.9, 0)
	b.limb(knee, Vector3(rng.randf_range(-0.2, 0.2), h * 0.6, rng.randf_range(-0.2, 0.2)), r, r * 0.7, bark, 7)
	for i in rng.randi_range(5, 8):
		var a := TAU * i / 7.0 + rng.randf_range(-0.2, 0.2)
		var foot := Vector3(cos(a), -0.1, sin(a)) * rng.randf_range(0.8, 1.3)
		var mid := Vector3(cos(a), 0, sin(a)) * 0.6 + Vector3(0, 0.75, 0)
		b.limb(knee + Vector3(cos(a), 0, sin(a)) * 0.1, mid, r * 0.4, r * 0.32, bark, 5)
		b.limb(mid, foot, r * 0.32, r * 0.22, bark, 5)
	var tips: Array = []
	var d2 := {"levels": 2, "kids": [3, 4], "angle": [0.6, 1.0], "ratio": 0.6, "gnarl": 0.3, "up": 0.2}
	_grow(b, rng, d2, Vector3(0, h * 0.55, 0), Vector3.UP, h * 0.35, r * 0.7, 1, tips, bark)
	var crown := _crown_of(tips)
	for t in tips:
		_clump(cards, rng, t[0], rng.randf_range(0.9, 1.2), crown, _leaf_col(rng, d), 0.7, 0.75)

static func _cactus(b: MB, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var col := _c(d.bark)
	var body := MB.tag(col, MB.SCALE)
	b.limb(Vector3(0, -0.1, 0), Vector3(0, h, 0), r, r * 0.92, body, 10)
	b.ball(Vector3(0, h, 0), r * 0.92, body)
	# vertical ribs
	for i in 8:
		var a := TAU * i / 8.0
		b.limb(Vector3(cos(a) * r * 0.9, 0.0, sin(a) * r * 0.9), Vector3(cos(a) * r * 0.85, h, sin(a) * r * 0.85), r * 0.14, r * 0.12, MB.tag(col.lightened(0.08), MB.SCALE), 4)
	for k in rng.randi_range(1, 3):
		var a2 := rng.randf() * TAU
		var out := Vector3(cos(a2), 0, sin(a2))
		var y := rng.randf_range(0.35, 0.65) * h
		var elbow := Vector3(0, y, 0) + out * rng.randf_range(0.5, 0.8)
		var top := elbow + Vector3(0, rng.randf_range(0.6, 1.2), 0)
		var ar := r * 0.6
		b.limb(Vector3(0, y, 0), elbow, ar, ar, body, 8)
		b.limb(elbow, top, ar, ar * 0.92, body, 8)
		b.ball(top, ar * 0.92, body)
		if rng.randf() < 0.6:
			b.ball(top + Vector3(0, ar * 0.9, 0), ar * 0.45, MB.tag(_c(d.c1), MB.CLOTH), true)
	for i in rng.randi_range(2, 4):
		var a3 := rng.randf() * TAU
		b.ball(Vector3(cos(a3) * r * 0.5, h + r * 0.7, sin(a3) * r * 0.5), r * 0.28, MB.tag(_c(d.c2), MB.CLOTH), true)

static func _giant_mushroom(b: MB, g: MB, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var r := _rr(rng, d.r)
	var lean := Vector3(rng.randf_range(-0.25, 0.25), 1.0, rng.randf_range(-0.25, 0.25)).normalized()
	var top := lean * h
	var stem := MB.tag(_c(d.bark), MB.SKIN)
	b.limb(Vector3(0, -0.1, 0), top * 0.5, r * 1.3, r, stem, 9)
	b.limb(top * 0.5, top, r, r * 0.85, stem, 9)
	# ring (annulus) partway up the stem
	b.lathe(top * 0.62, [Vector2(r * 1.1, 0.0), Vector2(r * 2.0, -0.18), Vector2(r * 1.9, -0.22)], MB.tag(_c(d.bark).darkened(0.08), MB.CLOTH), 12)
	var cap_r := h * rng.randf_range(0.32, 0.45)
	var capc := _c(d.c1).lerp(_c(d.c2), rng.randf() * 0.4)
	b.prim("hemi", MB._xf(top, Vector3(cap_r * 2.0, cap_r * rng.randf_range(0.55, 0.8), cap_r * 2.0), Vector3(rng.randf_range(-0.1, 0.1), 0, rng.randf_range(-0.1, 0.1))), MB.tag(capc, MB.CLOTH))
	# gills underneath glow faintly
	g.disc(top + Vector3(0, -0.02, 0), cap_r * 0.95, Color(capc.r, capc.g, capc.b, 0.35), 18, Color(capc.r, capc.g, capc.b, 0.05))
	for i in rng.randi_range(6, 12):
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * cap_r * 0.8
		var sp := top + Vector3(cos(a) * rr, cap_r * 0.62 * sqrt(maxf(0.0, 1.0 - pow(rr / cap_r, 2.0))) + 0.02, sin(a) * rr)
		var sc := _c(d.c2)
		b.sph(sp, Vector3(0.12, 0.04, 0.12) * rng.randf_range(0.7, 1.4), MB.tag(sc.lightened(0.3), MB.CRYSTAL), Vector3.ZERO, true)
		g.ball(sp, 0.12, Color(sc.r, sc.g, sc.b, 0.5), true)

static func _crystal_tree(b: MB, g: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var col := _c(d.bark)
	var tips: Array = []
	var dd := {"levels": 2, "kids": [2, 3], "angle": [0.4, 0.8], "ratio": 0.62, "gnarl": 0.1, "up": 0.4}
	_grow(b, rng, dd, Vector3(0, -0.1, 0), Vector3.UP, h * 0.5, _rr(rng, d.r), 0, tips, MB.tag(col, MB.CRYSTAL))
	var crown := _crown_of(tips)
	for t in tips:
		var tp: Vector3 = t[0]
		b.crystal(tp, 0.12, rng.randf_range(0.5, 0.9), MB.tag(_c(d.c1).lerp(_c(d.c2), rng.randf()), MB.CRYSTAL), Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4)), 6)
		_clump(cards, rng, tp, rng.randf_range(0.7, 1.0), crown, _c(d.c1).lerp(_c(d.c2), rng.randf()), 0.3)
		g.ball(tp, 0.25, Color(_c(d.c2).r, _c(d.c2).g, _c(d.c2).b, 0.25), true)

static func _bush(b: MB, cards: Nature.Cards, snow: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var wdt := h * rng.randf_range(0.9, 1.4)
	var n := rng.randi_range(5, 8)
	var crown := [Vector3(0, h * 0.45, 0), wdt]
	for i in 3:
		var a := rng.randf() * TAU
		b.limb(Vector3(0, -0.05, 0), Vector3(cos(a) * wdt * 0.4, h * 0.5, sin(a) * wdt * 0.4), 0.035, 0.015, MB.tag(Color("5a4a3a"), MB.WOOD), 4)
	for i in n:
		var a2 := TAU * i / n + rng.randf_range(-0.3, 0.3)
		var rr := wdt * rng.randf_range(0.2, 0.6)
		var c := Vector3(cos(a2) * rr, h * rng.randf_range(0.3, 0.75), sin(a2) * rr)
		var sz := h * rng.randf_range(0.45, 0.65)
		_clump(cards, rng, c, sz, crown, _leaf_col(rng, d), 0.35, 1.0, 2)
		if d.get("snow", false) and rng.randf() < 0.7:
			var nn := Vector3.UP
			snow.quad(c + Vector3(0, sz * 0.35, 0), Vector3(sz * 0.6, 0, 0), Vector3(0, 0.05, sz * 0.6), Color(0.95, 0.97, 1.0), 0.3, [nn, nn, nn, nn])
	_clump(cards, rng, Vector3(0, h * 0.8, 0), h * 0.55, crown, _leaf_col(rng, d), 0.45, 1.0, 2)

static func _fern(cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var n := rng.randi_range(6, 10)
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.25, 0.25)
		var out := Vector3(cos(a), 0, sin(a))
		var ln := h * rng.randf_range(0.8, 1.25)
		var rise := rng.randf_range(0.5, 0.9)
		var pts: Array = []
		var nr: Array = []
		var sw: Array = []
		for j in 5:
			var t := j / 4.0
			pts.append(out * ln * t + Vector3(0, ln * rise * sin(t * PI * 0.75) - t * t * ln * 0.25, 0))
			nr.append((Vector3(0, 1, 0) + out * 0.3).normalized())
			sw.append(t * 0.6)
		cards.strip(pts, [0.03, 0.14, 0.17, 0.12, 0.03], Vector3(-out.z, 0, out.x), _leaf_col(rng, d), sw, nr)

static func _reeds(b: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	for i in rng.randi_range(9, 16):
		var a := rng.randf() * TAU
		var base := Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * 0.45
		var hh := h * rng.randf_range(0.6, 1.1)
		var lean := Vector3(cos(a) * 0.25, 1.0, sin(a) * 0.25).normalized()
		var side := Vector3(-sin(a), 0, cos(a))
		var nn := (Vector3(cos(a), 0.5, sin(a))).normalized()
		cards.strip([base, base + lean * hh * 0.5, base + lean * hh + Vector3(cos(a), 0, sin(a)) * 0.15], [0.05, 0.045, 0.01], side, _leaf_col(rng, d), [0.0, 0.5, 1.0], [nn, nn, nn])
		if rng.randf() < 0.3:
			var top := base + lean * hh * 0.9
			b.limb(base, top, 0.012, 0.01, MB.tag(Color("7a8a4a"), MB.WOOD), 4)
			b.cyl(top + Vector3(0, 0.1, 0), 0.04, 0.2, MB.tag(Color("6a4a2a"), MB.CLOTH), Vector3.ZERO, 6)

static func _deadbush(b: MB, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	var bark := MB.tag(_c(d.bark), MB.WOOD)
	for i in rng.randi_range(5, 8):
		var a := rng.randf() * TAU
		var mid := Vector3(cos(a) * h * 0.3, h * rng.randf_range(0.35, 0.6), sin(a) * h * 0.3)
		var tip := mid + Vector3(cos(a + 0.4) * h * 0.4, h * rng.randf_range(0.1, 0.45), sin(a + 0.4) * h * 0.4)
		b.limb(Vector3(0, -0.05, 0), mid, 0.025, 0.014, bark, 4)
		b.limb(mid, tip, 0.014, 0.004, bark, 4)

static func _kelp(cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	for i in rng.randi_range(3, 6):
		var a := rng.randf() * TAU
		var base := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, 0.35)
		var pts: Array = []
		var nr: Array = []
		var sw: Array = []
		var hh := h * rng.randf_range(0.6, 1.1)
		for j in 7:
			var t := j / 6.0
			pts.append(base + Vector3(sin(t * 5.0 + a) * 0.15, hh * t, cos(t * 4.0 + a) * 0.15))
			nr.append(Vector3(cos(a), 0.3, sin(a)).normalized())
			sw.append(t * 1.6)
		cards.strip(pts, [0.06, 0.14, 0.16, 0.16, 0.14, 0.1, 0.03], Vector3(-sin(a), 0, cos(a)), _leaf_col(rng, d), sw, nr)

static func _shrooms(b: MB, g: MB, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	for i in rng.randi_range(3, 7):
		var a := rng.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * 0.4
		var hh := h * rng.randf_range(0.4, 1.0)
		var cr := hh * rng.randf_range(0.35, 0.55)
		var col := _c(d.c1).lerp(_c(d.c2), rng.randf())
		b.limb(p, p + Vector3(rng.randf_range(-0.05, 0.05), hh, rng.randf_range(-0.05, 0.05)), cr * 0.25, cr * 0.2, MB.tag(Color("ece4f0"), MB.SKIN), 6)
		b.prim("hemi", MB._xf(p + Vector3(0, hh, 0), Vector3(cr * 2.0, cr * 0.8, cr * 2.0), Vector3.ZERO), MB.tag(col, MB.CLOTH))
		g.ball(p + Vector3(0, hh, 0), cr * 1.3, Color(col.r, col.g, col.b, 0.3), true)

static func _lilies(cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	for i in rng.randi_range(3, 6):
		var a := rng.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * 0.5
		var hh := h * rng.randf_range(0.75, 1.15)
		for k in 2:
			var yaw := a + k * PI * 0.5
			var ax := Vector3(cos(yaw), 0, sin(yaw)) * hh * 0.5
			var nn := Vector3(cos(yaw + PI * 0.5), 0.6, sin(yaw + PI * 0.5)).normalized()
			cards.quad(p + Vector3(0, hh * 0.5, 0), ax, Vector3(0, hh * 0.5, 0), _leaf_col(rng, d), 0.6, [nn, nn, nn, nn])

static func _agave(b: MB, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var h := _rr(rng, d.h)
	for i in rng.randi_range(9, 14):
		var a := TAU * i / 12.0 + rng.randf_range(-0.2, 0.2)
		var up := rng.randf_range(0.35, 1.0)
		var tip := Vector3(cos(a) * h * (1.1 - up * 0.6), h * up, sin(a) * h * (1.1 - up * 0.6))
		b.limb(Vector3(0, 0.02, 0), tip, 0.07, 0.006, MB.tag(_c(d.c1).lerp(_c(d.c2), rng.randf() * 0.5), MB.SCALE), 5)

static func _flowers(b: MB, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var palette := [Color("ff8ab0"), Color("ffe070"), Color("ffffff"), Color("b0a0ff"), Color("ff7060"), Color("8ad0ff")]
	var main_col: Color = palette[rng.randi() % palette.size()]
	for i in rng.randi_range(5, 10):
		var a := rng.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * 0.5
		var hh := _rr(rng, d.h) * rng.randf_range(0.7, 1.2)
		var top := p + Vector3(rng.randf_range(-0.04, 0.04), hh, rng.randf_range(-0.04, 0.04))
		b.limb(p, top, 0.008, 0.006, MB.tag(Color("4a8a3a"), MB.FOLIAGE), 3)
		var col: Color = main_col if rng.randf() < 0.75 else palette[rng.randi() % palette.size()]
		var fr := rng.randf_range(0.04, 0.07)
		for k in 5:
			var pa := TAU * k / 5.0
			b.leaf(top, top + Vector3(cos(pa) * fr, 0.015, sin(pa) * fr), fr * 0.6, MB.tag(col, MB.CLOTH), Vector3(-sin(pa), 0, cos(pa)), MB.tag(col.lightened(0.25), MB.CLOTH))
		b.ball(top + Vector3(0, 0.01, 0), fr * 0.3, MB.tag(Color("ffd050"), MB.CLOTH), true)
		b.leaf(p + Vector3(0, 0.02, 0), p + Vector3(cos(a) * 0.12, 0.08, sin(a) * 0.12), 0.03, MB.tag(Color("4a9040"), MB.FOLIAGE))

static func _log(b: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var r := _rr(rng, d.r)
	var ln := rng.randf_range(1.6, 2.6)
	var bark := MB.tag(_c(d.bark), MB.WOOD)
	var a := Vector3(-ln * 0.5, r * 0.8, 0)
	var e := Vector3(ln * 0.5, r * 0.7, rng.randf_range(-0.2, 0.2))
	b.limb(a, e, r, r * 0.85, bark, 8)
	b.disc(a, r * 0.95, MB.tag(Color("c8a878"), MB.WOOD), 10, MB.tag(Color("8a6a48"), MB.WOOD), Vector3(0, 0, PI * 0.5))
	b.limb(a.lerp(e, 0.4), a.lerp(e, 0.4) + Vector3(0.2, 0.5, 0.3), r * 0.25, r * 0.08, bark, 5)
	# moss along the top of the log
	for i in 4:
		var p := a.lerp(e, rng.randf_range(0.1, 0.9)) + Vector3(0, r * 0.75, 0)
		_clump(cards, rng, p, rng.randf_range(0.2, 0.32), [p - Vector3(0, r, 0), r * 2.0], _leaf_col(rng, d), 0.1, 0.5, 2)

static func _stump(b: MB, cards: Nature.Cards, rng: RandomNumberGenerator, d: Dictionary) -> void:
	var r := _rr(rng, d.r)
	var h := _rr(rng, d.h)
	var bark := MB.tag(_c(d.bark), MB.WOOD)
	b.limb(Vector3(0, -0.05, 0), Vector3(0, h, 0), r * 1.1, r, bark, 9)
	b.disc(Vector3(0, h, 0), r * 0.95, MB.tag(Color("c8a878"), MB.WOOD), 12, MB.tag(Color("8a6a48"), MB.WOOD))
	for i in 4:
		var a := TAU * i / 4.0 + rng.randf_range(-0.3, 0.3)
		b.limb(Vector3(cos(a) * r * 0.5, h * 0.4, sin(a) * r * 0.5), Vector3(cos(a) * r * 2.0, -0.05, sin(a) * r * 2.0), r * 0.4, r * 0.1, bark, 5)
	_clump(cards, rng, Vector3(r * 0.8, h * 0.5, 0), 0.25, [Vector3(0, h * 0.5, 0), r * 1.5], _leaf_col(rng, d), 0.1, 1.0, 2)
