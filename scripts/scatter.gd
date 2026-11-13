class_name Scatter
extends RefCounted
## Natural placement of everything that grows or lies on the ground.
##
## The old terrain put one landmark (one of two meshes) on every blocked tile and one tuft on most
## open tiles, so a forest read as a grid of identical stamps.  Placement now follows simple ecology:
##
##   * Distance fields over the tile grid: how deep a blocked tile is inside its forest (edge, then
##     interior), how far an open tile is from the forest, from water and from the road.
##   * Forest edges get shrubs and young, smaller trees; the interior gets the tallest trees, and
##     sometimes two of them sharing a tile.  Trees lean slightly and vary in size with depth.
##   * "Grove" noise: every species in a region has its own low-frequency noise field, so species
##     form natural stands (a patch of birches, then pines) instead of a uniform salt-and-pepper mix.
##   * Each instance picks one of several grown variants (Flora.VARIANTS) and gets its own hue,
##     brightness, yaw, tilt and scale.
##   * Open ground: dense wind-blown grass whose density follows a meadow noise and thins near
##     roads; ferns and fallen logs at the forest edge; reeds at the shore; flowers in meadows;
##     boulders and scree where a rockiness noise is high.
##   * Built landmarks (obelisks, columns, tombstones, Blender props) are still used where a region
##     is built rather than grown, mixed with natural species at a per-region ratio.
## Everything is instanced through MultiMesh per 12x12-tile chunk with per-layer draw distances.

const CH := 12
const GRASS_VARIANTS := 4

## canopy / under (forest edge) / ground (open-ground cover) species with weights; land = share of
## blocked tiles that keep the region's built landmark; rocks = rock recipes; rock_p = rock density;
## grass = grass density multiplier; cover = open-ground cover chance.
const ECO := {
	"sect": {"canopy": [["pine", 3], ["bonsai", 2], ["blossom", 1], ["fir", 1], ["ginkgo", 0.6]], "under": [["bush", 3], ["round_bush", 2], ["flowerbush", 1], ["fern", 1]],
		"ground": [["flowers", 2], ["fern", 1]], "land": 0.15, "rocks": ["boulder", "scree", "slab"], "rock_p": 0.05, "grass": 1.0, "cover": 0.07},
	"bamboo": {"canopy": [["bamboo", 6], ["oak", 0.7], ["fir", 0.4]], "under": [["fern", 3], ["bush", 1], ["sapling", 1]],
		"ground": [["fern", 2], ["flowers", 0.6]], "land": 0.2, "rocks": ["boulder", "scree"], "rock_p": 0.04, "grass": 1.1, "cover": 0.1, "logs": 0.03},
	"marsh": {"canopy": [["mangrove", 3], ["marsh_dead", 2], ["willow", 1.5]], "under": [["reeds", 3], ["fern", 1], ["deadbush", 1]],
		"ground": [["reeds", 2], ["fern", 1]], "land": 0.25, "rocks": ["slab", "scree"], "rock_p": 0.03, "grass": 0.8, "cover": 0.12, "logs": 0.03},
	"frost": {"canopy": [["snowpine", 4], ["fir", 0.5]], "under": [["snowbush", 3]], "ground": [["snowbush", 1]],
		"land": 0.4, "rocks": ["boulder", "spire", "scree"], "rock_p": 0.07, "grass": 0.45, "cover": 0.04},
	"thunder": {"canopy": [["dead", 1], ["bonsai", 1]], "under": [["deadbush", 2], ["round_bush", 1]], "ground": [["deadbush", 1]],
		"land": 0.55, "rocks": ["spire", "boulder", "slab", "scree"], "rock_p": 0.12, "grass": 0.6, "cover": 0.04},
	"palace": {"canopy": [["dead", 2]], "under": [["deadbush", 1]], "ground": [["deadbush", 0.5]],
		"land": 0.7, "rocks": ["slab", "scree"], "rock_p": 0.04, "grass": 0.0, "cover": 0.02},
	"abyss": {"canopy": [["kelp", 2]], "under": [["kelp", 3]], "ground": [["kelp", 1]],
		"land": 0.55, "rocks": ["boulder", "scree"], "rock_p": 0.06, "grass": 0.0, "cover": 0.1},
	"volcano": {"canopy": [["ashen", 2]], "under": [["deadbush", 1]], "ground": [["deadbush", 0.5]],
		"land": 0.6, "rocks": ["spire", "boulder", "scree"], "rock_p": 0.1, "grass": 0.0, "cover": 0.03},
	"void": {"canopy": [["crystal_tree", 2]], "under": [["glowshroom", 1]], "ground": [["glowshroom", 0.5]],
		"land": 0.6, "rocks": ["crystal", "spire"], "rock_p": 0.06, "grass": 0.0, "cover": 0.03},
	"celestial": {"canopy": [["blossom", 2], ["bonsai", 1], ["cypress", 1], ["wisteria", 1]], "under": [["flowerbush", 2], ["round_bush", 1]], "ground": [["flowers", 2]],
		"land": 0.6, "rocks": ["slab"], "rock_p": 0.02, "grass": 0.0, "cover": 0.05},
	"mirror": {"canopy": [["birch", 2], ["willow", 1]], "under": [["reeds", 1], ["round_bush", 1]], "ground": [["reeds", 1], ["flowers", 0.5]],
		"land": 0.55, "rocks": ["slab", "boulder"], "rock_p": 0.03, "grass": 0.7, "cover": 0.05},
	"grave": {"canopy": [["dead", 3], ["cypress", 1.5]], "under": [["deadbush", 2], ["fern", 0.5]], "ground": [["deadbush", 1]],
		"land": 0.55, "rocks": ["slab", "boulder", "scree"], "rock_p": 0.05, "grass": 0.6, "cover": 0.05},
	"time": {"canopy": [["acacia", 1], ["dead", 1]], "under": [["deadbush", 2], ["agave", 1]], "ground": [["agave", 1]],
		"land": 0.6, "rocks": ["slab", "boulder"], "rock_p": 0.04, "grass": 0.5, "cover": 0.04},
	"origin": {"canopy": [["crystal_tree", 1], ["blossom", 1]], "under": [["flowerbush", 1]], "ground": [["flowers", 1]],
		"land": 0.55, "rocks": ["crystal", "slab"], "rock_p": 0.03, "grass": 0.0, "cover": 0.04},
	"cloudsea": {"canopy": [["bonsai", 3], ["pine", 1], ["birch", 1]], "under": [["bush", 2], ["fern", 1]], "ground": [["flowers", 1.5], ["fern", 0.5]],
		"land": 0.15, "rocks": ["boulder", "slab"], "rock_p": 0.03, "grass": 1.0, "cover": 0.06},
	"court": {"canopy": [["cypress", 2], ["bonsai", 1], ["willow", 0.6], ["ginkgo", 1.2], ["wisteria", 0.8]], "under": [["round_bush", 2]], "ground": [["flowers", 0.5]],
		"land": 0.6, "rocks": ["slab"], "rock_p": 0.02, "grass": 0.7, "cover": 0.03},
	"forge": {"canopy": [["ashen", 1]], "under": [["deadbush", 1]], "ground": [["deadbush", 0.4]],
		"land": 0.65, "rocks": ["boulder", "spire", "scree"], "rock_p": 0.08, "grass": 0.0, "cover": 0.02},
	"garden": {"canopy": [["peach", 3], ["blossom", 2], ["willow", 0.8], ["wisteria", 1.2]], "under": [["flowerbush", 3], ["bush", 1]], "ground": [["flowers", 3], ["fern", 0.5]],
		"land": 0.3, "rocks": ["boulder", "slab"], "rock_p": 0.02, "grass": 1.1, "cover": 0.12},
	"dunes": {"canopy": [["palm", 2], ["cactus", 2], ["acacia", 1]], "under": [["agave", 2], ["deadbush", 2]], "ground": [["agave", 1], ["deadbush", 1]],
		"land": 0.2, "rocks": ["slab", "boulder", "spire"], "rock_p": 0.05, "grass": 0.45, "cover": 0.04},
	"fungal": {"canopy": [["giant_shroom", 4]], "under": [["glowshroom", 3], ["fern", 1]], "ground": [["glowshroom", 2], ["fern", 0.5]],
		"land": 0.4, "rocks": ["boulder", "scree"], "rock_p": 0.03, "grass": 0.9, "cover": 0.12},
	"aurora": {"canopy": [["snowpine", 3], ["fir", 1]], "under": [["snowbush", 2]], "ground": [["snowbush", 0.6]],
		"land": 0.4, "rocks": ["boulder", "spire", "scree"], "rock_p": 0.06, "grass": 0.45, "cover": 0.03},
	"chaos": {"canopy": [["crystal_tree", 1]], "under": [["glowshroom", 1]], "ground": [["glowshroom", 0.4]],
		"land": 0.6, "rocks": ["crystal", "spire"], "rock_p": 0.05, "grass": 0.0, "cover": 0.03},
	# ---- Part VI
	"maple": {"canopy": [["maple", 5], ["autumn_oak", 2], ["ginkgo", 1.5], ["pine", 1], ["birch", 1]], "under": [["autumn_bush", 3], ["fern", 1], ["bush", 1], ["sapling", 0.6]],
		"ground": [["autumn_bush", 1], ["fern", 1], ["flowers", 0.5]], "land": 0.0, "rocks": ["boulder", "slab", "scree"], "rock_p": 0.06, "grass": 1.0, "cover": 0.1, "logs": 0.04},
	"karst": {"canopy": [["karst_bush", 2], ["bamboo", 1.2], ["bonsai", 1], ["willow", 1]], "under": [["fern", 2], ["bush", 2], ["reeds", 0.6]],
		"ground": [["fern", 1], ["flowers", 0.6]], "land": 0.0, "karst": 0.55, "rocks": ["boulder", "slab", "scree"], "rock_p": 0.05, "grass": 1.1, "cover": 0.08, "logs": 0.02},
	"lilies": {"canopy": [["willow", 2], ["dead", 1], ["cypress", 0.6]], "under": [["spiderlily", 4], ["reeds", 1]], "ground": [["spiderlily", 4], ["reeds", 0.4]],
		"land": 0.2, "rocks": ["slab", "boulder"], "rock_p": 0.03, "grass": 0.8, "cover": 0.22},
	"diyu": {"canopy": [["dead", 2], ["crystal_tree", 0.6], ["cypress", 1]], "under": [["deadbush", 1], ["spiderlily", 0.6]], "ground": [["spiderlily", 0.6], ["deadbush", 0.4]],
		"land": 0.4, "rocks": ["spire", "slab", "boulder"], "rock_p": 0.06, "grass": 0.5, "cover": 0.05},
	# ---- Part VII
	"village": {"canopy": [["willow", 2], ["oak", 2], ["peach", 1.5], ["bamboo", 1.5], ["ginkgo", 0.6]], "under": [["bush", 3], ["flowerbush", 1], ["reeds", 1]],
		"ground": [["flowers", 2], ["fern", 0.6]], "land": 0.0, "rocks": ["boulder", "slab"], "rock_p": 0.03, "grass": 1.1, "cover": 0.08, "logs": 0.02},
	"tea": {"canopy": [["pine", 2], ["bonsai", 2], ["fir", 1], ["bamboo", 1]], "under": [["round_bush", 6], ["bush", 1]],
		"ground": [["round_bush", 2], ["flowers", 0.5]], "land": 0.0, "rocks": ["boulder", "slab", "scree"], "rock_p": 0.04, "grass": 1.0, "cover": 0.16},
	"silk": {"canopy": [["oak", 4], ["willow", 1], ["autumn_oak", 1], ["birch", 1]], "under": [["bush", 3], ["fern", 2], ["sapling", 1]],
		"ground": [["fern", 1.5], ["flowers", 1]], "land": 0.0, "rocks": ["boulder", "scree"], "rock_p": 0.03, "grass": 1.0, "cover": 0.1, "logs": 0.03},
	"loom": {"canopy": [["wisteria", 3], ["blossom", 2], ["crystal_tree", 1]], "under": [["flowerbush", 3], ["round_bush", 1]],
		"ground": [["flowers", 2]], "land": 0.35, "rocks": ["slab", "crystal"], "rock_p": 0.02, "grass": 0.5, "cover": 0.06},
	# ---- Part VIII
	"starferry": {"canopy": [["willow", 3], ["pine", 1], ["birch", 1]], "under": [["reeds", 4], ["bush", 2], ["sapling", 1]],
		"ground": [["fern", 1], ["flowers", 0.8]], "land": 0.04, "rocks": ["boulder", "pebbles"], "rock_p": 0.03, "grass": 1.1, "cover": 0.08, "logs": 0.02},
	"magpie": {"canopy": [["pine", 4], ["bonsai", 2], ["fir", 1]], "under": [["round_bush", 3], ["bush", 2]],
		"ground": [["fern", 1], ["flowers", 0.5]], "land": 0.1, "rocks": ["karst", "spire", "slab"], "rock_p": 0.07, "grass": 0.8, "cover": 0.1},
	"starpalace": {"canopy": [["crystal_tree", 2], ["wisteria", 2], ["blossom", 1]], "under": [["flowerbush", 3], ["round_bush", 2]],
		"ground": [["flowers", 2]], "land": 0.35, "rocks": ["crystal", "slab"], "rock_p": 0.03, "grass": 0.5, "cover": 0.06},
	"jasper": {"canopy": [["peach", 4], ["blossom", 2], ["pine", 1], ["ginkgo", 1]], "under": [["flowerbush", 3], ["bush", 1]],
		"ground": [["flowers", 2.5], ["fern", 0.5]], "land": 0.05, "rocks": ["boulder", "slab", "crystal"], "rock_p": 0.04, "grass": 1.0, "cover": 0.08},
	# ---- Part IX: scorched riverside willows in the market, withered millet and dead trees on the
	# plain, mulberries round the Fusang, silver osmanthus groves on the moon
	"yanggu": {"canopy": [["willow", 2], ["acacia", 2], ["ginkgo", 1], ["dead", 0.6]], "under": [["deadbush", 2], ["bush", 1], ["agave", 1]],
		"ground": [["deadbush", 1], ["agave", 0.5]], "land": 0.12, "rocks": ["boulder", "slab"], "rock_p": 0.03, "grass": 0.45, "cover": 0.05},
	"millet": {"canopy": [["dead", 4], ["acacia", 0.7], ["autumn_oak", 0.6]], "under": [["deadbush", 3], ["agave", 1]],
		"ground": [["deadbush", 1.5], ["agave", 0.4]], "land": 0.0, "rocks": ["slab", "boulder", "scree"], "rock_p": 0.05, "grass": 0.7, "cover": 0.1, "logs": 0.02},
	"fusang": {"canopy": [["mulberry", 4], ["pine", 1], ["bonsai", 1], ["ginkgo", 0.6]], "under": [["fern", 3], ["bush", 2], ["round_bush", 1]],
		"ground": [["fern", 1.5], ["flowers", 1]], "land": 0.05, "rocks": ["boulder", "slab", "karst"], "rock_p": 0.06, "grass": 1.1, "cover": 0.1, "logs": 0.02},
	"guanghan": {"canopy": [["osmanthus", 4], ["snowpine", 1], ["crystal_tree", 0.6]], "under": [["snowbush", 2], ["round_bush", 1]],
		"ground": [["snowbush", 0.6], ["flowers", 0.4]], "land": 0.2, "rocks": ["crystal", "slab", "boulder"], "rock_p": 0.04, "grass": 0.45, "cover": 0.05},
	# ---- Part X: willows and cliff pines along the river, drowned willows and reeds over the flood,
	# smoke-dark pines and cypress round the foundries, and dead pines on the broken mountain
	"longmen": {"canopy": [["willow", 3], ["pine", 2], ["bonsai", 1], ["karst_bush", 1]], "under": [["reeds", 2], ["bush", 2], ["fern", 1]],
		"ground": [["reeds", 1], ["flowers", 0.6]], "land": 0.08, "rocks": ["karst", "boulder", "slab"], "rock_p": 0.06, "grass": 0.9, "cover": 0.09, "logs": 0.02},
	"drowned": {"canopy": [["willow", 3], ["marsh_dead", 2], ["mulberry", 1]], "under": [["reeds", 4], ["bush", 1]],
		"ground": [["reeds", 2], ["flowers", 0.3]], "land": 0.1, "rocks": ["slab", "scree"], "rock_p": 0.02, "grass": 0.8, "cover": 0.14, "logs": 0.04},
	"tushan": {"canopy": [["pine", 3], ["cypress", 2], ["ashen", 1], ["dead", 0.5]], "under": [["bush", 2], ["deadbush", 1], ["round_bush", 1]],
		"ground": [["deadbush", 0.6], ["flowers", 0.3]], "land": 0.15, "rocks": ["boulder", "slab", "spire"], "rock_p": 0.08, "grass": 0.7, "cover": 0.06},
	"buzhou": {"canopy": [["dead", 2], ["snowpine", 1], ["fir", 1]], "under": [["deadbush", 2], ["snowbush", 1]],
		"ground": [["deadbush", 0.5]], "land": 0.45, "rocks": ["spire", "boulder", "slab", "scree"], "rock_p": 0.12, "grass": 0.5, "cover": 0.04},
	# ---- Part XI: cloud-pines, blossom and floating islets in the Level Heaven, peach and wisteria by
	# the Gate of Heaven, giant glowing mushrooms and crystal trees under the roots, cypress and dead
	# trees among the spider lilies of the Dark Capital
	"juntian": {"canopy": [["pine", 3], ["bonsai", 2], ["blossom", 1], ["birch", 1]], "under": [["round_bush", 2], ["flowerbush", 1], ["fern", 1]],
		"ground": [["flowers", 1.5], ["fern", 0.4]], "land": 0.2, "rocks": ["boulder", "slab"], "rock_p": 0.04, "grass": 1.0, "cover": 0.08},
	"changhe": {"canopy": [["peach", 2], ["wisteria", 2], ["ginkgo", 1], ["bonsai", 1]], "under": [["flowerbush", 2], ["round_bush", 1]],
		"ground": [["flowers", 2], ["fern", 0.3]], "land": 0.25, "rocks": ["slab", "crystal"], "rock_p": 0.04, "grass": 0.8, "cover": 0.08},
	"ninesprings": {"canopy": [["giant_shroom", 3], ["crystal_tree", 1.5], ["dead", 1]], "under": [["glowshroom", 3], ["fern", 1], ["deadbush", 1]],
		"ground": [["glowshroom", 2], ["fern", 0.5]], "land": 0.35, "rocks": ["spire", "boulder", "crystal"], "rock_p": 0.1, "grass": 0.3, "cover": 0.12},
	"youdu": {"canopy": [["dead", 2], ["cypress", 2], ["crystal_tree", 0.6]], "under": [["deadbush", 2], ["spiderlily", 1]],
		"ground": [["spiderlily", 1], ["deadbush", 0.5]], "land": 0.35, "rocks": ["slab", "spire"], "rock_p": 0.06, "grass": 0.25, "cover": 0.06},
	# ---- Part XII: sea-pines, blossom and white cliffs on Penglai; peach, ginkgo and herbs in the
	# immortals' gardens of Fangzhang; wind-bent pines and bare crags in the mists of Yingzhou; coral and
	# kelp left standing on the bare sea floor at the Returning Ruins
	"penglai": {"canopy": [["pine", 3], ["blossom", 2], ["cypress", 1], ["bonsai", 1]], "under": [["round_bush", 2], ["flowerbush", 1], ["fern", 1]],
		"ground": [["flowers", 1.0], ["fern", 0.4]], "land": 0.3, "rocks": ["boulder", "slab"], "rock_p": 0.06, "grass": 0.8, "cover": 0.08},
	"fangzhang": {"canopy": [["peach", 3], ["ginkgo", 2], ["wisteria", 1], ["bonsai", 1]], "under": [["flowerbush", 2], ["round_bush", 1], ["fern", 1]],
		"ground": [["flowers", 2], ["fern", 0.5]], "land": 0.25, "rocks": ["slab", "boulder"], "rock_p": 0.05, "grass": 1.0, "cover": 0.1},
	"yingzhou": {"canopy": [["pine", 3], ["bonsai", 2], ["dead", 1]], "under": [["fern", 2], ["round_bush", 1]],
		"ground": [["fern", 1], ["flowers", 0.3]], "land": 0.45, "rocks": ["spire", "boulder", "slab"], "rock_p": 0.14, "grass": 0.6, "cover": 0.1},
	"guixu": {"canopy": [["kelp", 3], ["dead", 1], ["mangrove", 0.5]], "under": [["kelp", 3], ["deadbush", 1]],
		"ground": [["kelp", 1]], "land": 0.4, "rocks": ["boulder", "slab", "scree"], "rock_p": 0.1, "grass": 0.2, "cover": 0.05},
}

static var _grass := {}

static func eco(theme_name: String) -> Dictionary:
	return ECO.get(theme_name, ECO.bamboo)

static func h(x: int, y: int, salt: float) -> float:
	return Terrain3D.hash2(x, y, salt)

## 4-neighbour distance (in tiles) from every tile to the nearest tile that matches `pred`, capped.
static func distance_field(grid: PackedByteArray, w: int, hh: int, targets: Array, cap: int) -> PackedInt32Array:
	var d := PackedInt32Array()
	d.resize(w * hh)
	d.fill(cap)
	var q: Array = []
	for i in w * hh:
		if grid[i] in targets:
			d[i] = 0
			q.append(i)
	var head := 0
	while head < q.size():
		var i: int = q[head]
		head += 1
		var x := i % w
		var y := i / w
		var nd := d[i] + 1
		if nd >= cap:
			continue
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = x + o.x
			var ny: int = y + o.y
			if nx < 0 or ny < 0 or nx >= w or ny >= hh:
				continue
			var j := ny * w + nx
			if d[j] > nd:
				d[j] = nd
				q.append(j)
	return d

## weighted species pick biased by each species' own grove noise at (x, y)
static func pick(list: Array, groves: Array, x: float, y: float, r: float) -> String:
	if list.is_empty():
		return ""
	var tot := 0.0
	var ws: Array = []
	for i in list.size():
		var g: FastNoiseLite = groves[i % groves.size()]
		var bias := 1.0 + 2.2 * maxf(0.0, g.get_noise_2d(x, y) + 0.1)
		var wgt := float(list[i][1]) * bias
		ws.append(wgt)
		tot += wgt
	var t := r * tot
	for i in list.size():
		t -= float(ws[i])
		if t <= 0.0:
			return str(list[i][0])
	return str(list[list.size() - 1][0])

static func _tint(x: int, y: int, salt: float, amount: float) -> Color:
	var v := 1.0 + (h(x, y, salt) - 0.5) * amount
	var hr := (h(x, y, salt + 1.0) - 0.5) * amount * 0.6
	var hb := (h(x, y, salt + 2.0) - 0.5) * amount * 0.6
	return Color(clampf(v + hr, 0.5, 1.5), clampf(v, 0.5, 1.5), clampf(v + hb, 0.5, 1.5), 1.0)

class Layer:
	var mesh: Mesh
	var xf: Array = []
	var col: Array = []
	var shadow := false
	var vis := 60.0

static func _add(layers: Dictionary, key: String, mesh_fn: Callable, xf: Transform3D, col: Color, shadow: bool, vis: float) -> void:
	if not layers.has(key):
		var l := Layer.new()
		l.mesh = mesh_fn.call()
		l.shadow = shadow
		l.vis = vis
		layers[key] = l
	var ly: Layer = layers[key]
	ly.xf.append(xf)
	ly.col.append(col)

static func _flush(root: Node3D, layers: Dictionary) -> void:
	var made := {}
	for k in layers:
		var ly: Layer = layers[k]
		if ly.mesh != null and not ly.xf.is_empty():
			made[k] = Terrain3D._add_mm(root, ly.mesh, ly.xf, ly.col, ly.shadow, ly.vis)
	# the Sword's Wake (impact.gd): the things noted in this chunk learn the instance that draws them
	for e in _pending:
		e["mmi"] = made.get(e.key)
	_pending = []

## The Sword's Wake (the Spring Thunder release, impact.gd): what grows or lies on each tile of the
## region being populated, so a blow can find it: local tile -> [{kind ("tree", "plant" or "rock"),
## the layer key, the instance index "i", and after the chunk is flushed its MultiMeshInstance3D
## "mmi"}].  populate() leaves it on the root as meta "nature".
static var _reg := {}
static var _pending: Array = []
## the rocks a blow can break (scree, pebbles and the karst towers are left be)
const BREAKS := ["boulder", "slab", "spire", "crystal"]

static func _note(kind: String, tx: int, ty: int, layers: Dictionary, key: String) -> void:
	var ly: Layer = layers[key]
	var e := {"kind": kind, "key": key, "i": ly.xf.size() - 1}
	var t := Vector2i(tx, ty)
	if not _reg.has(t):
		_reg[t] = []
	_reg[t].append(e)
	_pending.append(e)

static func _xf(pos: Vector3, yaw: float, s: float, tilt: Vector2 = Vector2.ZERO, sy: float = 1.0) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(tilt.x, yaw, tilt.y)).scaled(Vector3(s, s * sy, s)), pos)

# ---------------------------------------------------------------- main entry
static func populate(root: Node3D, grid: PackedByteArray, w: int, hh: int, hm: PackedFloat32Array, theme_name: String, seed_: int) -> void:
	var th := Look.theme(theme_name)
	var e := eco(theme_name)
	var T := Terrain3D.T
	var wall_d := distance_field(grid, w, hh, [MapGen.FLOOR, MapGen.PATH, MapGen.DECOR, MapGen.WATER, MapGen.BUILDING], 6)
	var open_d := distance_field(grid, w, hh, [MapGen.WALL], 5)
	var water_d := distance_field(grid, w, hh, [MapGen.WATER], 4)
	var path_d := distance_field(grid, w, hh, [MapGen.PATH, MapGen.BUILDING], 4)
	var groves: Array = []
	for i in 6:
		var gn := FastNoiseLite.new()
		gn.seed = seed_ * 17 + i * 101
		gn.frequency = 0.07
		groves.append(gn)
	var meadow := FastNoiseLite.new()
	meadow.seed = seed_ * 5 + 9
	meadow.frequency = 0.09
	var rocky := FastNoiseLite.new()
	rocky.seed = seed_ * 11 + 4
	rocky.frequency = 0.11
	var canopy: Array = e.canopy
	var under: Array = e.under
	var ground: Array = e.ground
	var rocks: Array = e.rocks
	var land: float = float(e.land)
	var karst: float = float(e.get("karst", 0.0))
	var grass_k: float = float(e.grass)
	var cover: float = float(e.cover)
	var rock_p: float = float(e.rock_p)
	var logs: float = float(e.get("logs", 0.0))
	var tuft_kind: String = str(th.get("tuft", "grass"))
	var real_grass := tuft_kind in ["grass", "deadgrass", "dunegrass", "snow", "moss", "flowers", "reed"] and grass_k > 0.0
	var lily_ok := theme_name in ["sect", "garden", "marsh", "mirror", "lilies", "karst"]
	_settled = []
	_reg = {}
	_pending = []
	# direction from a forest-edge tile towards the open ground beside it
	_open_dir = func(tx: int, ty: int) -> Vector2i:
		for o in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			var nx: int = tx + o.x
			var ny: int = ty + o.y
			if nx >= 0 and ny >= 0 and nx < w and ny < hh and grid[ny * w + nx] in [MapGen.FLOOR, MapGen.DECOR, MapGen.PATH]:
				return o
		return Vector2i(0, 1)
	var cw := int(ceil(w / float(CH)))
	var chh := int(ceil(hh / float(CH)))
	for cy in chh:
		for cx in cw:
			var layers := {}
			for ty in range(cy * CH, mini(hh, (cy + 1) * CH)):
				for tx in range(cx * CH, mini(w, (cx + 1) * CH)):
					var i := ty * w + tx
					var tile := grid[i]
					var x0 := tx * T
					var z0 := ty * T
					var gx := func(fx: float, fz: float) -> Vector3:
						var px := x0 + fx * T
						var pz := z0 + fz * T
						return Vector3(px, Terrain3D.sample(hm, w, hh, px, pz), pz)
					match tile:
						MapGen.WALL:
							_wall_tile(layers, tx, ty, wall_d[i], gx, theme_name, canopy, under, rocks, groves, land, karst, rocky)
						MapGen.FLOOR:
							# the High Roads (peaks.gd): a crag has no meadow on it, only what clings there
							var hi0 := i + ty
							var c_lo := minf(minf(hm[hi0], hm[hi0 + 1]), minf(hm[hi0 + w + 1], hm[hi0 + w + 2]))
							var c_hi := maxf(maxf(hm[hi0], hm[hi0 + 1]), maxf(hm[hi0 + w + 1], hm[hi0 + w + 2]))
							if c_hi - c_lo > 1.15:
								_crag_tile(layers, tx, ty, gx, theme_name, canopy, rocks, groves, c_hi - c_lo)
								continue
							_floor_tile(layers, tx, ty, open_d[i], water_d[i], path_d[i], gx, theme_name, under, ground, rocks, groves, meadow, rocky, grass_k, cover, rock_p, logs, real_grass, tuft_kind)
						MapGen.DECOR:
							var dp := Terrain3D._proto("decor:" + theme_name, theme_name)
							if dp != null:
								var s := 0.8 + h(tx, ty, 3.0) * 0.6
								_add(layers, "decor", func(): return dp, _xf(gx.call(0.5 + (h(tx, ty, 1.0) - 0.5) * 0.6, 0.5 + (h(tx, ty, 2.0) - 0.5) * 0.6), h(tx, ty, 0.0) * TAU, s), _tint(tx, ty, 4.0, 0.25), false, 50.0)
							if real_grass:
								_grass_at(layers, tx, ty, gx, theme_name, 2, 0.9)
						MapGen.WATER:
							if lily_ok and theme_name != "lilies" and h(tx, ty, 18.0) > 0.82 and water_d[i] == 0 and open_d[i] >= 2:
								var lv := int(h(tx, ty, 19.0) * Flora.VARIANTS)
								var lpos := Vector3(x0 + T * 0.5, Terrain3D.WATER_Y - 0.01, z0 + T * 0.5)
								_add(layers, "flora:lotus#%d" % lv, func(): return Flora.mesh("lotus", lv), _xf(lpos, h(tx, ty, 20.0) * TAU, 0.9 + h(tx, ty, 21.0) * 0.5), Color.WHITE, false, 55.0)
							elif lily_ok and h(tx, ty, 0.0) > 0.72 and water_d[i] == 0:
								var lp := Terrain3D._proto("lily:" + theme_name, theme_name)
								var pos := Vector3(x0 + T * 0.5 + (h(tx, ty, 3.0) - 0.5), Terrain3D.WATER_Y + 0.02, z0 + T * 0.5 + (h(tx, ty, 4.0) - 0.5))
								_add(layers, "lily", func(): return lp, _xf(pos, h(tx, ty, 5.0) * TAU, 0.8 + h(tx, ty, 6.0) * 0.5), Color.WHITE, false, 60.0)
							if open_d[i] >= 1 and _shore(grid, w, hh, tx, ty) and h(tx, ty, 7.0) < 0.35 and theme_name not in ["volcano", "forge", "void", "chaos", "abyss"]:
								var sp := "reeds" if theme_name != "lilies" else "spiderlily"
								var v := int(h(tx, ty, 8.0) * Flora.VARIANTS)
								var rp: Vector3 = gx.call(h(tx, ty, 9.0), h(tx, ty, 10.0))
								rp.y = maxf(rp.y, Terrain3D.WATER_Y - 0.1)
								_add(layers, "flora:%s#%d" % [sp, v], func(): return Flora.mesh(sp, v), _xf(rp, h(tx, ty, 11.0) * TAU, 0.8 + h(tx, ty, 12.0) * 0.5), _tint(tx, ty, 13.0, 0.2), false, 55.0)
							if theme_name == "abyss" and h(tx, ty, 14.0) < 0.25:
								var kv := int(h(tx, ty, 15.0) * Flora.VARIANTS)
								_add(layers, "flora:kelp#%d" % kv, func(): return Flora.mesh("kelp", kv), _xf(gx.call(0.5, 0.5), h(tx, ty, 16.0) * TAU, 1.0), _tint(tx, ty, 17.0, 0.2), false, 55.0)
			_flush(root, layers)
	root.set_meta("nature", _reg)
	_reg = {}

static func _shore(grid: PackedByteArray, w: int, hh: int, tx: int, ty: int) -> bool:
	for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = tx + o.x
		var ny: int = ty + o.y
		if nx >= 0 and ny >= 0 and nx < w and ny < hh and grid[ny * w + nx] != MapGen.WATER:
			return true
	return false

static func _tree(layers: Dictionary, sp: String, tx: int, ty: int, salt: float, pos: Vector3, scale: float) -> void:
	var v := int(h(tx, ty, salt) * Flora.VARIANTS) % Flora.VARIANTS
	var small := Flora.is_small(sp)
	var tilt := Vector2((h(tx, ty, salt + 1.0) - 0.5) * 0.12, (h(tx, ty, salt + 2.0) - 0.5) * 0.12)
	var col := _tint(tx, ty, salt + 3.0, 0.22 if not small else 0.3)
	_add(layers, "flora:%s#%d" % [sp, v], func(): return Flora.mesh(sp, v), _xf(pos, h(tx, ty, salt + 4.0) * TAU, scale, tilt), col, not small, 55.0 if small else 115.0)
	if sp not in ["log", "stump", "lotus", "kelp"]:
		_note("plant" if small else "tree", tx, ty, layers, "flora:%s#%d" % [sp, v])

static func _wall_tile(layers: Dictionary, tx: int, ty: int, depth: int, gx: Callable, theme_name: String, canopy: Array, under: Array, rocks: Array, groves: Array, land: float, karst: float, rocky: FastNoiseLite) -> void:
	var r0 := h(tx, ty, 40.0)
	# now and then a dwelling stands at the forest edge, facing the open ground (see architecture.gd)
	if depth == 1 and Arch.SETTLE.has(theme_name) and h(tx, ty, 200.0) < 0.03 and _settle_ok(tx, ty):
		var kinds: Array = Arch.SETTLE[theme_name]
		var kind: String = kinds[int(h(tx, ty, 201.0) * kinds.size()) % kinds.size()]
		var v := int(h(tx, ty, 202.0) * 3.0)
		var face: Vector2i = _open_dir.call(tx, ty) if _open_dir.is_valid() else Vector2i(0, 1)
		var yaw := atan2(float(face.x), float(face.y))
		var pos: Vector3 = gx.call(0.5, 0.5)
		pos.y -= 0.08
		_add(layers, "bld:%s#%d" % [kind, v], func(): return Arch.settlement_mesh(kind, v, theme_name), Transform3D(Basis(Vector3.UP, yaw), pos), Color.WHITE, true, 130.0)
		_settled.append(Vector2i(tx, ty))
		return
	# built landmarks (the region's identity) at the chosen share, but none crowding a thing to do
	if r0 < land and not _by_clearing(tx, ty, 1):
		var key := "wall:" if h(tx, ty, 12.0) >= 0.35 else "wall2:"
		var lp := Terrain3D._proto(key + theme_name, theme_name)
		var s2 := 0.85 + h(tx, ty, 5.0) * 0.55
		var sy := 0.9 + h(tx, ty, 6.0) * 0.4
		var pos: Vector3 = gx.call(0.5 + (h(tx, ty, 9.0) - 0.5) * 0.25, 0.5 + (h(tx, ty, 10.0) - 0.5) * 0.25)
		pos.y -= 0.05
		_add(layers, "land:" + key, func(): return lp, _xf(pos, h(tx, ty, 0.0) * TAU, s2, Vector2((h(tx, ty, 7.0) - 0.5) * 0.12, (h(tx, ty, 8.0) - 0.5) * 0.12), sy), _tint(tx, ty, 11.0, 0.3), true, 100.0)
		if depth <= 1 and not under.is_empty() and h(tx, ty, 41.0) < 0.5:
			var usp := pick(under, groves, tx, ty, h(tx, ty, 42.0))
			_tree(layers, usp, tx, ty, 43.0, gx.call(h(tx, ty, 44.0), h(tx, ty, 45.0)), 0.8 + h(tx, ty, 46.0) * 0.5)
		return
	# karst towers rise out of the interior of Part VI's stone forest
	if karst > 0.0 and depth >= 2 and h(tx, ty, 47.0) < karst:
		var kv := int(h(tx, ty, 48.0) * Rocks.VARIANTS)
		var kp: Vector3 = gx.call(0.5, 0.5)
		kp.y -= 0.2
		_add(layers, "rock:karst#%d" % kv, func(): return Rocks.mesh("karst", kv, theme_name), _xf(kp, h(tx, ty, 49.0) * TAU, 0.8 + h(tx, ty, 50.0) * 0.6), _tint(tx, ty, 51.0, 0.15), true, 140.0)
		return
	if canopy.is_empty():
		return
	if depth <= 1:
		# forest edge: undergrowth and young trees
		if not under.is_empty():
			var usp2 := pick(under, groves, tx, ty, h(tx, ty, 52.0))
			_tree(layers, usp2, tx, ty, 53.0, gx.call(0.25 + h(tx, ty, 54.0) * 0.5, 0.25 + h(tx, ty, 55.0) * 0.5), 0.9 + h(tx, ty, 56.0) * 0.6)
		if h(tx, ty, 57.0) < 0.62:
			var sp := pick(canopy, groves, tx, ty, h(tx, ty, 58.0))
			_tree(layers, sp, tx, ty, 59.0, gx.call(0.3 + h(tx, ty, 60.0) * 0.4, 0.3 + h(tx, ty, 61.0) * 0.4), 0.55 + h(tx, ty, 62.0) * 0.3)
	else:
		var sp2 := pick(canopy, groves, tx, ty, h(tx, ty, 63.0))
		var sc := 0.82 + 0.1 * mini(depth, 4) + h(tx, ty, 64.0) * 0.3
		_tree(layers, sp2, tx, ty, 65.0, gx.call(0.3 + h(tx, ty, 66.0) * 0.4, 0.3 + h(tx, ty, 67.0) * 0.4), sc)
		if h(tx, ty, 68.0) < 0.3:
			var sp3 := pick(canopy, groves, tx + 3, ty + 1, h(tx, ty, 69.0))
			_tree(layers, sp3, tx, ty, 70.0, gx.call(h(tx, ty, 71.0), h(tx, ty, 72.0)), sc * 0.75)
	# rocky outcrops among the trees
	if not rocks.is_empty() and rocky.get_noise_2d(tx, ty) > 0.25 and h(tx, ty, 73.0) < 0.35:
		var rk: String = rocks[int(h(tx, ty, 74.0) * rocks.size()) % rocks.size()]
		if rk == "scree":
			rk = "boulder"
		var rv := int(h(tx, ty, 75.0) * Rocks.VARIANTS)
		_add(layers, "rock:%s#%d" % [rk, rv], func(): return Rocks.mesh(rk, rv, theme_name), _xf(gx.call(h(tx, ty, 76.0), h(tx, ty, 77.0)), h(tx, ty, 78.0) * TAU, 0.8 + h(tx, ty, 79.0) * 0.9), _tint(tx, ty, 80.0, 0.15), true, 80.0)
		if rk in BREAKS:
			_note("rock", tx, ty, layers, "rock:%s#%d" % [rk, rv])

static var _settled: Array = []
static var _open_dir := Callable()

## keep dwellings apart: at most one within 9 tiles of another
static func _settle_ok(tx: int, ty: int) -> bool:
	for p in _settled:
		if absi((p as Vector2i).x - tx) + absi((p as Vector2i).y - ty) < 9:
			return false
	# not right beside a thing to do, facing its clearing
	return not _by_clearing(tx, ty, 2)

## The forest-edge tiles the things to do stand on (props.gd), in the grid being populated: world.gd
## sets them for a region's view and clears them after, and nothing built crowds them.
static var clearings: Dictionary = {}

## The tiles of the grid being populated that something stands on (the Answering Land release): a person, a
## lord, a thing to find, a thing a choice left standing, a plot of the hero's town, a machine, something that
## breaks, and the ground a big one of them covers.  world.gd sets them for a region's view and clears them
## after; grass grows there as anywhere, and no rock, bush, log or stump is scattered through whoever stands.
static var stood: Dictionary = {}

static func _by_clearing(tx: int, ty: int, r: int) -> bool:
	if clearings.is_empty():
		return false
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if clearings.has(Vector2i(tx + dx, ty + dy)):
				return true
	return false

static func _floor_tile(layers: Dictionary, tx: int, ty: int, to_wall: int, to_water: int, to_path: int, gx: Callable, theme_name: String, under: Array, ground: Array, rocks: Array, groves: Array, meadow: FastNoiseLite, rocky: FastNoiseLite, grass_k: float, cover: float, rock_p: float, logs: float, real_grass: bool, tuft_kind: String) -> void:
	var mv := meadow.get_noise_2d(tx, ty) * 0.5 + 0.5
	# grass: thick in meadows and along forest edges, thin beside the road
	if real_grass:
		var dens := grass_k * (1.5 + 3.5 * mv) * (0.45 if to_path <= 1 else 1.0) * (1.3 if to_wall == 1 else 1.0)
		_grass_at(layers, tx, ty, gx, theme_name, int(dens + h(tx, ty, 20.0)), 1.0 + (0.25 if to_wall == 1 else 0.0) + mv * 0.25)
	elif tuft_kind not in ["none", ""] and grass_k >= 0.0:
		var tp := Terrain3D._proto("tuft:" + theme_name, theme_name)
		if tp != null:
			var nt := 1 + int(h(tx, ty, 20.0) * 2.4)
			for k in nt:
				if h(tx, ty, 21.0 + k) < 0.7:
					var ts := 0.7 + h(tx, ty, 28.0 + k) * 0.7
					_add(layers, "tuft", func(): return tp, _xf(gx.call(0.1 + h(tx, ty, 22.0 + k) * 0.8, 0.1 + h(tx, ty, 25.0 + k) * 0.8), h(tx, ty, 31.0 + k) * TAU, ts), _tint(tx, ty, 34.0 + k, 0.2), false, 40.0)
	if to_path == 0 or stood.has(Vector2i(tx, ty)):
		return
	# forest-edge undergrowth spills onto open ground
	if to_wall == 1 and not under.is_empty() and h(tx, ty, 81.0) < 0.28:
		var usp := pick(under, groves, tx, ty, h(tx, ty, 82.0))
		_tree(layers, usp, tx, ty, 83.0, gx.call(0.15 + h(tx, ty, 84.0) * 0.7, 0.15 + h(tx, ty, 85.0) * 0.7), 0.7 + h(tx, ty, 86.0) * 0.5)
	elif to_water == 1 and h(tx, ty, 87.0) < 0.3 and theme_name not in ["volcano", "forge", "void", "chaos", "abyss", "dunes"]:
		var wsp := "reeds" if theme_name != "lilies" else "spiderlily"
		_tree(layers, wsp, tx, ty, 88.0, gx.call(h(tx, ty, 89.0), h(tx, ty, 90.0)), 0.8 + h(tx, ty, 91.0) * 0.5)
	elif not ground.is_empty() and h(tx, ty, 92.0) < cover * (0.4 + 1.4 * mv) and to_path >= 2:
		var gsp := pick(ground, groves, tx, ty, h(tx, ty, 93.0))
		_tree(layers, gsp, tx, ty, 94.0, gx.call(0.15 + h(tx, ty, 95.0) * 0.7, 0.15 + h(tx, ty, 96.0) * 0.7), 0.75 + h(tx, ty, 97.0) * 0.6)
	# fallen logs and stumps near the forest
	if logs > 0.0 and to_wall <= 2 and to_path >= 2 and h(tx, ty, 98.0) < logs:
		var lsp := "log" if h(tx, ty, 99.0) < 0.6 else "stump"
		_tree(layers, lsp, tx, ty, 100.0, gx.call(0.5, 0.5), 0.8 + h(tx, ty, 101.0) * 0.4)
	# rocks gather where the rockiness noise is high, and scree along the forest foot
	if not rocks.is_empty():
		var rn := rocky.get_noise_2d(tx, ty) * 0.5 + 0.5
		if h(tx, ty, 102.0) < rock_p * (0.3 + 2.0 * rn) * (1.6 if to_wall == 1 else 1.0):
			var rk: String = rocks[int(h(tx, ty, 103.0) * rocks.size()) % rocks.size()]
			if rk in ["spire", "karst"] and to_path <= 2:
				rk = "boulder"
			var rv := int(h(tx, ty, 104.0) * Rocks.VARIANTS)
			var rs := (0.35 + h(tx, ty, 105.0) * 0.5) if rk != "scree" else (0.8 + h(tx, ty, 105.0) * 0.8)
			_add(layers, "rock:%s#%d" % [rk, rv], func(): return Rocks.mesh(rk, rv, theme_name), _xf(gx.call(h(tx, ty, 106.0), h(tx, ty, 107.0)), h(tx, ty, 108.0) * TAU, rs), _tint(tx, ty, 109.0, 0.15), rk != "scree", 70.0)
			if rk in BREAKS:
				_note("rock", tx, ty, layers, "rock:%s#%d" % [rk, rv])
		elif h(tx, ty, 110.0) < 0.05 and theme_name not in ["celestial", "court", "palace"]:
			var pv := int(h(tx, ty, 111.0) * Rocks.VARIANTS)
			_add(layers, "rock:pebbles#%d" % pv, func(): return Rocks.mesh("pebbles", pv, theme_name), _xf(gx.call(h(tx, ty, 112.0), h(tx, ty, 113.0)), h(tx, ty, 114.0) * TAU, 1.0), _tint(tx, ty, 115.0, 0.2), false, 40.0)

## A tile of a mountain's flank: bare rock, with a boulder lodged on it now and then and, where the
## slope allows, one of the region's own trees holding on (smaller the steeper it stands).
static func _crag_tile(layers: Dictionary, tx: int, ty: int, gx: Callable, theme_name: String, canopy: Array, rocks: Array, groves: Array, drop: float) -> void:
	if stood.has(Vector2i(tx, ty)):
		return
	var r := h(tx, ty, 131.0)
	if r < 0.1 and not rocks.is_empty():
		var rv := int(h(tx, ty, 132.0) * Rocks.VARIANTS)
		_add(layers, "rock:boulder#%d" % rv, func(): return Rocks.mesh("boulder", rv, theme_name), _xf(gx.call(h(tx, ty, 133.0), h(tx, ty, 134.0)) - Vector3(0, 0.25, 0), h(tx, ty, 135.0) * TAU, 0.45 + h(tx, ty, 136.0) * 0.7), _tint(tx, ty, 137.0, 0.15), true, 90.0)
	elif r < 0.17 and drop < 3.2 and not canopy.is_empty():
		var sp := pick(canopy, groves, tx, ty, h(tx, ty, 138.0))
		_tree(layers, sp, tx, ty, 139.0, gx.call(0.2 + h(tx, ty, 140.0) * 0.6, 0.2 + h(tx, ty, 141.0) * 0.6) - Vector3(0, 0.2, 0), 0.45 + h(tx, ty, 142.0) * 0.3)

static func _grass_at(layers: Dictionary, tx: int, ty: int, gx: Callable, theme_name: String, count: int, scale: float) -> void:
	for k in count:
		var gv := int(h(tx, ty, 120.0 + k) * GRASS_VARIANTS)
		var s := scale * (0.75 + h(tx, ty, 130.0 + k) * 0.6)
		var pos: Vector3 = gx.call(0.05 + h(tx, ty, 140.0 + k) * 0.9, 0.05 + h(tx, ty, 150.0 + k) * 0.9)
		_add(layers, "grass#%d" % gv, func(): return grass_mesh(theme_name, gv), _xf(pos, h(tx, ty, 160.0 + k) * TAU, s), _tint(tx, ty, 170.0 + k, 0.25), false, 36.0)

## A clump of curved, tapering grass blades.  Vertex alpha = height along the blade (the grass
## shader bends tips more than roots).  Taller, sparser blades for dry grass; short ones for moss.
static func grass_mesh(theme_name: String, variant: int) -> ArrayMesh:
	var key := "%s#%d" % [theme_name, variant]
	if _grass.has(key):
		return _grass[key]
	var th := Look.theme(theme_name)
	var kind: String = str(th.get("tuft", "grass"))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var idx := PackedInt32Array()
	var blades := 14
	var hmin := 0.28
	var hmax := 0.6
	var wid := 0.04
	match kind:
		"deadgrass", "dunegrass":
			blades = 9
			hmin = 0.4
			hmax = 0.85
			wid = 0.03
		"snow":
			blades = 8
			hmin = 0.12
			hmax = 0.28
		"moss":
			blades = 16
			hmin = 0.1
			hmax = 0.26
			wid = 0.05
		"reed":
			blades = 10
			hmin = 0.5
			hmax = 1.0
			wid = 0.035
	if theme_name in ["maple", "lilies"]:
		hmax *= 1.15
	for b in blades:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.32
		var base := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var hh := rng.randf_range(hmin, hmax)
		var face := rng.randf() * TAU
		var out := Vector3(cos(face), 0, sin(face))
		var lean := out * rng.randf_range(0.05, 0.25) * hh
		var side := Vector3(-out.z, 0, out.x)
		var shade := rng.randf_range(0.85, 1.12)
		var start := v.size()
		var segs := 4
		for s in segs + 1:
			var t := s / float(segs)
			var p := base + Vector3(0, hh * t, 0) + lean * t * t
			var ww := wid * (1.0 - t) * (1.0 if s < segs else 0.0) + 0.002
			var nrm := (out + Vector3(0, 0.4, 0)).normalized()
			for sd: float in [-1.0, 1.0]:
				v.append(p + side * ww * sd)
				n.append(nrm)
				c.append(Color(shade, shade, shade, t))
		for s in segs:
			var k := start + s * 2
			idx.append_array([k, k + 2, k + 1, k + 1, k + 2, k + 3])
	# a few flowers in flowery meadows
	if kind == "flowers" or (kind == "grass" and theme_name in ["sect", "garden", "cloudsea"] and variant == 0):
		pass
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	m.surface_set_material(0, Nature.grass_mat(theme_name))
	_grass[key] = m
	return m

## A ring of varied trees and rocks around a battle arena (replaces the two-mesh landmark ring).
static func arena_ring(parent: Node3D, theme_name: String, radius: float, count: int, seed_: int) -> void:
	var e := eco(theme_name)
	var layers := {}
	var groves: Array = []
	for i in 6:
		var gn := FastNoiseLite.new()
		gn.seed = seed_ + i * 31
		gn.frequency = 0.25
		groves.append(gn)
	var land: float = float(e.land)
	for i in count:
		var a := TAU * i / count + (h(i, seed_, 1.0) - 0.5) * 0.25
		var r := radius + h(i, seed_, 2.0) * 7.0
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		var tx := i * 7 + seed_
		var ty := i * 3
		if h(i, seed_, 3.0) < land or (e.canopy as Array).is_empty():
			var key := "wall:" if h(i, seed_, 4.0) > 0.4 else "wall2:"
			var lp := Terrain3D._proto(key + theme_name, theme_name)
			_add(layers, "land:" + key, func(): return lp, _xf(pos, h(i, seed_, 5.0) * TAU, 0.9 + h(i, seed_, 6.0) * 0.6), _tint(tx, ty, 7.0, 0.25), true, 200.0)
		elif float(e.get("karst", 0.0)) > 0.0 and h(i, seed_, 8.0) < 0.4:
			var kv := int(h(i, seed_, 9.0) * Rocks.VARIANTS)
			_add(layers, "rock:karst#%d" % kv, func(): return Rocks.mesh("karst", kv, theme_name), _xf(pos * 1.2, h(i, seed_, 10.0) * TAU, 1.0 + h(i, seed_, 11.0) * 0.5), Color.WHITE, true, 200.0)
		else:
			var sp := pick(e.canopy, groves, cos(a) * 9.0, sin(a) * 9.0, h(i, seed_, 12.0))
			var v := int(h(i, seed_, 13.0) * Flora.VARIANTS)
			_add(layers, "flora:%s#%d" % [sp, v], func(): return Flora.mesh(sp, v), _xf(pos, h(i, seed_, 14.0) * TAU, 0.9 + h(i, seed_, 15.0) * 0.5), _tint(tx, ty, 16.0, 0.22), true, 200.0)
		# undergrowth and rocks between the trees
		if not (e.under as Array).is_empty() and h(i, seed_, 17.0) < 0.8:
			var us := pick(e.under, groves, sin(a) * 9.0, cos(a) * 9.0, h(i, seed_, 18.0))
			var uv := int(h(i, seed_, 19.0) * Flora.VARIANTS)
			var up := Vector3(cos(a + 0.12) * (r - 3.0), 0, sin(a + 0.12) * (r - 3.0))
			_add(layers, "flora:%s#%d" % [us, uv], func(): return Flora.mesh(us, uv), _xf(up, h(i, seed_, 20.0) * TAU, 0.9 + h(i, seed_, 21.0) * 0.5), _tint(tx, ty, 22.0, 0.25), false, 200.0)
		if not (e.rocks as Array).is_empty() and h(i, seed_, 23.0) < 0.35:
			var rk: String = e.rocks[int(h(i, seed_, 24.0) * (e.rocks as Array).size()) % (e.rocks as Array).size()]
			var rv := int(h(i, seed_, 25.0) * Rocks.VARIANTS)
			var rp := Vector3(cos(a - 0.15) * (r - 4.5), 0, sin(a - 0.15) * (r - 4.5))
			_add(layers, "rock:%s#%d" % [rk, rv], func(): return Rocks.mesh(rk, rv, theme_name), _xf(rp, h(i, seed_, 26.0) * TAU, 0.6 + h(i, seed_, 27.0) * 0.6), Color.WHITE, true, 200.0)
	_flush(parent, layers)
