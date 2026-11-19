class_name Deeps
extends RefCounted
## The floor of the Eastern Sea (the Sea Floor release): a seventh realm (atlas.gd STRATA "deeps"), and the
## places of it that are there to be found.
##
## **Sights** (`SIGHTS`, six a country, written with their region in Data.AREAS "sights": entities of kind
## "sight"): a wreck, a rib of the Kun, a bell on its side, the Tail-Gate itself.  A sight is *found* by
## coming within FIND tiles of it (`Deeps.found`, from World when he stops on a tile), which is told once and
## kept (`Game.sights`: id -> day); Enter in front of one says what it is.  Each is a model built from code
## (`model`), no wider at the ground than a tile and a half.  New step kind "sights" (`n` of them found in
## `area`, whenever they were found): ask for fewer than a country has.  The bot goes to the nearest it has
## not found (`nearest`).  No trial, notice, letter or ending asks for one.
##
## **The sea overhead** (`dress`): the realm is dressed with the water above it (a bright rippled ceiling
## SURFACE_Y metres up, shafts of light coming down through it over every country but the Northern Dark)
## and the dark the floor falls away into at its edges.  Drawn only.

const FIND := 2
const SURFACE_Y := 46.0
const LAYER := "deeps"
const AREAS := ["jiaoshi", "shanhu", "beiming", "weilu"]

const SIGHTS := {
	# ---- Jiaoshi, the weaving-rooms
	"sunk_junk": {"n": "The Junk That Sank with Her Lamps Lit", "area": "jiaoshi", "m": "wreck",
		"desc": "A trading junk lying on her side in the sand, mast and all. Every lamp on her is still in its bracket. The Jiaoren hung a float in each, long ago, out of something like politeness, and they are lit still."},
	"weeping_rock": {"n": "The Rock Where the First Tear Fell", "area": "jiaoshi", "m": "rock",
		"desc": "A black rock with one hollow in its top the size of a thumb, and in the hollow a pearl too big to have been wept by anybody now living. Every Jiaoren child is brought here once and told: it is allowed."},
	"kelp_cathedral": {"n": "The Kelp That Reaches the Light", "area": "jiaoshi", "m": "kelp",
		"desc": "A stand of kelp so old that its heads are lost in the brightness overhead. The stems are as thick as a man. Standing among them is like standing in the nave of something, with the roof moving."},
	"pearl_bed": {"n": "The Bed of Unstrung Pearls", "area": "jiaoshi", "m": "clams",
		"desc": "A hollow of white sand set with shells, each a little open, each with a pearl. This is where what is wept and not sold is put. It is not a treasury. It is nearer to being a graveyard, and nearer still to a diary."},
	"drowned_stele": {"n": "The Stele of the People Who Stayed", "area": "jiaoshi", "m": "stele",
		"desc": "A stele with two columns of names. The left is those who went down to the Nine Springs when the sea grew salt. The right is those who stayed. The right is a little longer. At the foot somebody has cut: neither was wrong."},
	"anchor_field": {"n": "The Field of Lost Anchors", "area": "jiaoshi", "m": "anchors",
		"desc": "Anchors, forty or fifty, of stone and of iron, each with its cable going straight up and ending. Every ship that ever cut and ran from a storm over this ground left one. They lean the same way, like wheat."},
	# ---- Shanhu, the coral forest
	"coral_arch": {"n": "The Arch That Took Nine Hundred Years", "area": "shanhu", "m": "arch",
		"desc": "Two red trees that grew toward one another for nine hundred years and met. The Kiln-Master's grandfather's grandfather lowered the nets. Nobody has ever raised them. It is the one thing in Redbranch that is not for anything."},
	"iron_net_wreck": {"n": "The Net That Was Never Raised", "area": "shanhu", "m": "net",
		"desc": "An iron net with a tree grown so far through it that the links are inside the branches. Whoever sank it did not come back for it. The tree does not seem to have minded being forgotten."},
	"giant_clam": {"n": "The Clam That Has Seen Three Dynasties", "area": "shanhu", "m": "clam",
		"desc": "A clam wider than a door, open a hand's breadth, with a mantle the blue of a kingfisher. It closes when a shadow crosses it, slowly, with the air of something that has been disappointed before."},
	"white_grove": {"n": "The Grove That Went White", "area": "shanhu", "m": "bones",
		"desc": "A stand of coral gone white from the tips to the root, perfect in every branch, like a forest in frost. It was red in the spring. Nobody burns from here. The Kiln-Master says it is not dead until he says so."},
	"sunk_bell": {"n": "The Bell That Says One Note", "area": "shanhu", "m": "bell",
		"desc": "A temple bell of bronze, lying on its side where some ship lost it. The current goes through it. It has been sounding one note, too low to hear and just high enough to feel in the teeth, since before the sect was founded."},
	"crab_market": {"n": "The Market the Crabs Keep", "area": "shanhu", "m": "market",
		"desc": "A flat rock set out with rows of small things: a button, a coin of a king nobody remembers, a glass bead, a tooth. The crabs bring them and arrange them and take them away again. Nothing is ever bought."},
	# ---- Beiming, the Northern Dark
	"kun_rib": {"n": "A Rib of the Kun", "area": "beiming", "m": "rib",
		"desc": "A rib, standing out of the sand in a curve taller than a pagoda. It is one rib. The Kun shed it, the lamp-trimmers say, as a stag sheds a horn, when it was young and small. They have looked for the other. It has not shed the other."},
	"black_smoker": {"n": "The Chimneys of the Warm Vent", "area": "beiming", "m": "smoker",
		"desc": "Chimneys of black stone that the floor has built for itself, with water coming out of them too hot to touch and thick as smoke. Things live on them that have never needed the sun and have never heard of it."},
	"ice_that_burns": {"n": "The Ice That Burns", "area": "beiming", "m": "ice",
		"desc": "A mound of white ice lying on the sea floor, where no ice should be, with a small blue flame standing on it that the water does not put out. A summer insect was brought here once to be shown. It did not believe it either."},
	"lantern_fish_shoal": {"n": "The Stair of Lantern-Fish", "area": "beiming", "m": "shoal",
		"desc": "A shoal of lantern-fish that hangs in one place, in a slow spiral, each with its light, like a stair going up into the dark with a lamp on every step. Nobody knows what they are waiting for. They part for him, and close."},
	"yu_statue": {"n": "Yu, Who Passed His Own Door", "area": "beiming", "m": "statue",
		"desc": "A stone man with a spade over his shoulder and a plumb-line in his hand, walking, with the legs worn thin. He is looking back over his shoulder at something. It is said to be his own door. He does not turn round."},
	"caved_well": {"n": "The Caved-In Well", "area": "beiming", "m": "well",
		"desc": "A ring of old brick, an arm across, standing on the floor of the sea with a broken rail round it. It was a well. The sea came up and round it and over it. Down the middle of it hangs a rope, and tied to that, another."},
	# ---- Weilu, the Tail-Gate
	"tail_gate": {"n": "The Lip of the Tail-Gate", "area": "weilu", "m": "gate",
		"desc": "Two lips of rock, and between them nothing: the sea goes down there and is never less. A stone thrown in does not fall so much as leave. He stands a long time. It is the only thing he has ever seen that is not on the way to somewhere."},
	"silt_fan": {"n": "The Hand Across the Mouth", "area": "weilu", "m": "fan",
		"desc": "A fan of brown silt spread from the west like the fingers of a hand, ridge and hollow, each ridge the dust of one river. He can tell his own. It is the reddest. It is the colour of the cleft on Cold Mountain."},
	"river_mouths": {"n": "Where Every River Is Seen", "area": "weilu", "m": "pillar",
		"desc": "A pillar of rock with a flat top. From it the mouths of the rivers can be seen, far up and small and bright, like stars looked at from the bottom of a well. A frog has scratched a tally on the stone. It stops at a hundred."},
	"guns_wall": {"n": "The Last of Gun's Wall", "area": "weilu", "m": "wall",
		"desc": "A length of rampart, nine paces, of an earth that is warm to the hand and has no seam in it. Gun's wall, or the end of it, brought down by the first flood it failed to hold. It has grown a little since. It is still trying."},
	"last_cauldron": {"n": "The Cauldron That Fell in the River", "area": "weilu", "m": "cauldron",
		"desc": "A bronze tripod half in the silt, mouth up, with a map cast on its side of a country with nine provinces. One of Yu's nine was lost in a river, the histories say. The histories did not say where the river took it."},
	"whale_fall": {"n": "The Fall of a Whale", "area": "weilu", "m": "whale",
		"desc": "The bones of a whale, laid along the floor as it came to rest, and on every bone a garden: white things, red things, things with feathers. One death, and a town has lived on it for fifty years. Nobody in it knows what a whale was."},
}
## the kinds of model there are (anything else is the fall of a whale)
const MODELS := ["wreck", "rock", "kelp", "clams", "stele", "anchors", "arch", "net", "clam", "bones", "bell", "market", "rib", "smoker", "ice", "shoal", "statue", "well", "gate", "fan", "pillar", "wall", "cauldron"]
const ORDER := ["sunk_junk", "weeping_rock", "kelp_cathedral", "pearl_bed", "drowned_stele", "anchor_field",
	"coral_arch", "iron_net_wreck", "giant_clam", "white_grove", "sunk_bell", "crab_market",
	"kun_rib", "black_smoker", "ice_that_burns", "lantern_fish_shoal", "yu_statue", "caved_well",
	"tail_gate", "silt_fan", "river_mouths", "guns_wall", "last_cauldron", "whale_fall"]

## The sights of region `area`.
static func in_area(area: String) -> Array:
	return ORDER.filter(func(id): return str(SIGHTS[id].area) == area)

## How many sights have been found (in region `area`, or anywhere).
static func found_in(g, area: String = "") -> int:
	var n := 0
	for id in g.sights:
		if area == "" or str(SIGHTS.get(str(id), {}).get("area", "")) == area:
			n += 1
	return n

## He has stopped on tile `at` of realm `wd`: the sights within FIND tiles that he had not found are found.
## Returns their ids (told once, by whoever called).
static func found(g, wd: Dictionary, at: Vector2i) -> Array:
	var out: Array = []
	if not _is_deeps(wd):
		return out
	for e in sights_of(wd):
		var sid := str(e.sight)
		if g.sights.has(sid):
			continue
		var d: Vector2i = (e.pos as Vector2i) - at
		if maxi(absi(d.x), absi(d.y)) <= FIND:
			g.sights[sid] = int(g.day)
			g.note("Found %s" % str(SIGHTS[sid].n))
			out.append(sid)
	return out

static var _of := {}
static func _is_deeps(wd: Dictionary) -> bool:
	return (wd.get("ids", []) as Array).has(AREAS[0])

## The sight entities of realm `wd` (made once).
static func sights_of(wd: Dictionary) -> Array:
	if not _is_deeps(wd):
		return []
	if not _of.has("ents"):
		_of["ents"] = (wd.ents as Array).filter(func(e): return str(e.kind) == "sight")
	return _of["ents"]

## The sight of region `area` (or of any, "") nearest tile `at` that has not been found: its entity, or {}.
static func nearest(g, wd: Dictionary, at: Vector2i, area: String = "") -> Dictionary:
	var best := {}
	var bd := 1 << 30
	for e in sights_of(wd):
		if g.sights.has(str(e.sight)) or (area != "" and str(e.area) != area):
			continue
		var d: Vector2i = (e.pos as Vector2i) - at
		var dd := d.x * d.x + d.y * d.y
		if dd < bd:
			bd = dd
			best = e
	return best

## What is said in front of sight `id`.
static func lines(id: String) -> Array:
	var sg: Dictionary = SIGHTS[id]
	return [["Narrator", "%s. %s" % [str(sg.n), str(sg.desc)]]]

## The page (Esc > The Sea Floor): for each country, its sights (a name if found, else nothing but that
## there is one).
static func page(g) -> Array:
	var out: Array = []
	for a in AREAS:
		var rows: Array = []
		for id in in_area(a):
			rows.append({"id": id, "n": str(SIGHTS[id].n) if g.sights.has(id) else "(a place nobody has stood in since it sank)", "found": g.sights.has(id)})
		out.append({"area": a, "n": str(Data.AREAS[a].n), "seen": g.seen.has(a), "rows": rows, "found": found_in(g, a)})
	return out

# ---------------------------------------------------------------- what is drawn
## The model of sight `id`: built from code, standing on the middle of its tile.
static func model(id: String) -> Node3D:
	var root := Node3D.new()
	var sg: Dictionary = SIGHTS[id]
	var b := MB.new()
	var g := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var stone := MB.tag(Color("5a5e66"), MB.STONE)
	var dark := MB.tag(Color("2a2c34"), MB.STONE)
	var wood := MB.tag(Color("5a4630"), MB.WOOD)
	var bone := MB.tag(Color("e4dfd0"), MB.STONE)
	var bronze := MB.tag(Color("5a7a5a"), MB.METAL)
	var iron := MB.tag(Color("4a4a52"), MB.METAL)
	var red := MB.tag(Color("c8483a"), MB.STONE)
	match str(sg.m):
		"wreck":
			# a hull on her side, a mast leaning, and a lit float at every bracket
			var hull := MB.tag(Color("9a8258"), MB.WOOD)
			var deck := MB.tag(Color("b8a070"), MB.WOOD)
			b.sph(Vector3(0, 0.8, 0), Vector3(2.5, 1.05, 1.15), hull, Vector3(0, 0.3, 0.5))
			b.box(Vector3(0.2, 1.45, 0.1), Vector3(3.8, 0.12, 1.5), deck, Vector3(0, 0.3, 0.5))
			for i in 6:
				b.box(Vector3(-1.6 + 0.65 * i, 0.95 + 0.06 * i, 0.72 - 0.19 * i), Vector3(0.08, 1.3, 0.1), MB.tag(Color("6a5638"), MB.WOOD), Vector3(0, 0.3, 0.5))
			# the mast, leaning, with what is left of a ribbed sail of matting on its yards
			b.limb(Vector3(0.2, 1.1, 0), Vector3(2.4, 7.4, -1.4), 0.14, 0.07, wood, 6)
			var sail := MB.tag(Color("d8c898"), MB.CLOTH)
			for i in 5:
				var k := 0.35 + 0.13 * i
				var pm := Vector3(0.2, 1.1, 0).lerp(Vector3(2.4, 7.4, -1.4), k)
				b.limb(pm + Vector3(-0.5, 0.0, -1.3), pm + Vector3(0.4, 0.1, 1.5), 0.035, 0.03, wood, 4)
				if i < 4 and i != 2:
					b.quad4(pm + Vector3(-0.5, 0.0, -1.3), pm + Vector3(0.4, 0.1, 1.5), pm + Vector3(0.68, 0.92, 1.32), pm + Vector3(-0.22, 0.82, -1.48), sail, sail, sail, sail)
					b.quad4(pm + Vector3(0.4, 0.1, 1.5), pm + Vector3(-0.5, 0.0, -1.3), pm + Vector3(-0.22, 0.82, -1.48), pm + Vector3(0.68, 0.92, 1.32), sail, sail, sail, sail)
			b.box(Vector3(-1.9, 1.75, 0.3), Vector3(1.0, 1.2, 1.2), hull, Vector3(0, 0.3, 0.5))
			b.box(Vector3(-1.9, 2.4, 0.3), Vector3(1.2, 0.1, 1.4), deck, Vector3(0, 0.3, 0.5))
			for i in 7:
				g.ball(Vector3(-2.1 + 0.75 * i, 1.95 + 0.3 * sin(i * 1.7), 0.9 - 0.12 * i), 0.14, Color(0.8, 1.0, 0.65, 0.95), true)
				b.torus(Vector3(-2.1 + 0.75 * i, 1.95 + 0.3 * sin(i * 1.7), 0.9 - 0.12 * i), 0.15, 0.015, iron, Vector3(PI / 2, 0, 0))
		"rock":
			b.sph(Vector3(0, 0.7, 0), Vector3(1.3, 1.0, 1.1), dark)
			b.sph(Vector3(0.7, 0.4, 0.5), Vector3(0.8, 0.6, 0.7), dark)
			b.cyl(Vector3(0, 1.66, 0), 0.16, 0.06, stone, Vector3.ZERO, 8)
			g.ball(Vector3(0, 1.76, 0), 0.1, Color(1.0, 0.97, 0.92, 0.95), true)
		"kelp":
			for i in 7:
				var a := TAU * i / 7.0 + 0.3
				var r := 0.7 + 0.9 * rng.randf()
				var base := Vector3(cos(a) * r, 0, sin(a) * r)
				var top := base + Vector3(sin(i * 2.3) * 0.8, 9.0 + 3.0 * rng.randf(), cos(i * 1.9) * 0.8)
				b.limb(base, top, 0.2, 0.06, MB.tag(Color("3a6a3a"), MB.FOLIAGE), 6)
				for j in 7:
					var p := base.lerp(top, 0.15 + 0.12 * j)
					b.leaf(p, p + Vector3(cos(a + j) * 0.9, 0.5, sin(a + j) * 0.9), 0.3, MB.tag(Color("4a8a4a"), MB.FOLIAGE), Vector3.ZERO, MB.tag(Color("9ab85a"), MB.FOLIAGE))
		"clams":
			g.disc(Vector3(0, 0.03, 0), 2.3, Color(1, 1, 0.95, 0.25), 16, Color(1, 1, 0.95, 0.0))
			for i in 11:
				var a2 := TAU * i / 11.0
				var r2 := 0.6 + 1.5 * rng.randf()
				var p2 := Vector3(cos(a2) * r2, 0.08, sin(a2) * r2)
				b.hemi(p2, Vector3(0.22, 0.1, 0.18), MB.tag(Color("d8d0c0"), MB.STONE), Vector3(0, a2, 0))
				b.hemi(p2 + Vector3(0, 0.1, 0), Vector3(0.22, 0.1, 0.18), MB.tag(Color("f0e8dc"), MB.STONE), Vector3(-0.9, a2, 0))
				g.ball(p2 + Vector3(0, 0.1, 0), 0.05, Color(1.0, 0.96, 0.9, 0.95), true)
		"stele":
			b.box(Vector3(0, 0.15, 0), Vector3(1.5, 0.3, 0.8), stone)
			b.box(Vector3(0, 1.5, 0), Vector3(1.1, 2.4, 0.26), MB.tag(Color("6a7078"), MB.STONE))
			b.sph(Vector3(0, 2.72, 0), Vector3(0.6, 0.22, 0.16), stone)
			for i in 9:
				b.box(Vector3(-0.28, 2.4 - 0.2 * i, 0.135), Vector3(0.3, 0.05, 0.01), dark)
				if i < 8 or true:
					b.box(Vector3(0.26, 2.4 - 0.2 * i, 0.135), Vector3(0.34, 0.05, 0.01), dark)
			b.box(Vector3(0.26, 0.55, 0.135), Vector3(0.34, 0.05, 0.01), dark)
		"anchors":
			for i in 8:
				var a3 := TAU * i / 8.0 + 0.2
				var r3 := 0.3 + 2.0 * rng.randf()
				var p3 := Vector3(cos(a3) * r3, 0, sin(a3) * r3)
				var tip := p3 + Vector3(0.35, 1.3 + 0.5 * rng.randf(), 0.1)
				b.limb(p3, tip, 0.06, 0.05, iron if i % 3 else stone, 5)
				b.limb(p3 + Vector3(-0.4, 0.2, 0), p3 + Vector3(0.4, 0.2, 0), 0.05, 0.05, iron if i % 3 else stone, 5)
				b.torus(tip, 0.1, 0.02, iron, Vector3(PI / 2, 0, 0))
				b.limb(tip, tip + Vector3(0.1, 5.0 + 3.0 * rng.randf(), 0.05), 0.012, 0.004, MB.tag(Color("8a7a5a"), MB.CLOTH), 3)
		"arch":
			for sx in [-1.0, 1.0]:
				var prev := Vector3(sx * 2.2, 0, 0)
				for i in 7:
					var k := float(i + 1) / 7.0
					var nx := Vector3(sx * 2.2 * (1.0 - k * k), 4.2 * sin(k * PI * 0.5), 0.15 * sin(i * 2.0))
					b.limb(prev, nx, 0.34 - 0.03 * i, 0.3 - 0.03 * i, red, 7)
					if i % 2 == 0:
						b.limb(nx, nx + Vector3(sx * 0.7, 0.8, 0.5 * (1 if i % 4 else -1)), 0.12, 0.03, red, 5, MB.tag(Color("f0b0a0"), MB.STONE))
					prev = nx
		"net":
			b.limb(Vector3(0, 0, 0), Vector3(0.1, 3.4, 0), 0.3, 0.12, red, 7)
			for i in 6:
				var a4 := TAU * i / 6.0
				b.limb(Vector3(0.05, 1.2 + 0.3 * i, 0), Vector3(cos(a4) * 1.5, 2.2 + 0.4 * i, sin(a4) * 1.5), 0.13, 0.03, red, 5, MB.tag(Color("f0b0a0"), MB.STONE))
			for lv in 5:
				b.torus(Vector3(0, 0.5 + 0.6 * lv, 0), 1.1 - 0.06 * lv, 0.025, iron, Vector3.ZERO)
			for i in 10:
				var a5 := TAU * i / 10.0
				b.limb(Vector3(cos(a5) * 1.1, 0.4, sin(a5) * 1.1), Vector3(cos(a5) * 0.8, 3.0, sin(a5) * 0.8), 0.018, 0.018, iron, 3)
		"clam":
			b.hemi(Vector3(0, 0.1, 0), Vector3(1.5, 0.7, 1.1), MB.tag(Color("b8b0a0"), MB.STONE), Vector3(PI, 0, 0))
			b.hemi(Vector3(0, 0.55, -0.25), Vector3(1.5, 0.7, 1.1), MB.tag(Color("c8c0b0"), MB.STONE), Vector3(-0.45, 0, 0))
			for i in 9:
				b.sph(Vector3(-1.2 + 0.3 * i, 0.5, 0.75 + 0.08 * sin(i * 2.0)), Vector3(0.17, 0.12, 0.16), MB.tag(Color("2a8ac8"), MB.CLOTH))
			g.ball(Vector3(0, 0.55, 0.2), 0.22, Color(1.0, 0.98, 0.92, 0.9), true)
		"bones":
			for i in 6:
				var a6 := TAU * i / 6.0 + 0.4
				var r6 := 0.4 + 1.6 * rng.randf()
				var p6 := Vector3(cos(a6) * r6, 0, sin(a6) * r6)
				var h6 := 1.6 + 1.6 * rng.randf()
				b.limb(p6, p6 + Vector3(0, h6, 0), 0.16, 0.07, bone, 6)
				for j in 4:
					var aj := a6 + j * 1.6
					var q := p6 + Vector3(0, h6 * (0.4 + 0.15 * j), 0)
					b.limb(q, q + Vector3(cos(aj) * 0.7, 0.6, sin(aj) * 0.7), 0.07, 0.02, bone, 5)
		"bell":
			b.lathe(Vector3(0, 0.95, 0), [Vector2(1.0, -1.1), Vector2(0.86, -0.7), Vector2(0.8, 0.2), Vector2(0.6, 0.75), Vector2(0.2, 0.95)], bronze, 14, MB.tag(Color("3a5a4a"), MB.METAL), Vector2.ONE)
			b.torus(Vector3(0, 2.0, 0), 0.2, 0.05, bronze, Vector3(PI / 2, 0, 0))
			b.sph(Vector3(0.9, 0.2, 0.9), Vector3(0.6, 0.25, 0.5), MB.tag(Color("c8c0a0"), MB.STONE))
			root.set_meta("tilt", Vector3(0, 0, 1.35))
		"market":
			b.cyl(Vector3(0, 0.25, 0), 2.0, 0.5, stone, Vector3.ZERO, 10)
			for i in 5:
				for j in 4:
					var p7 := Vector3(-1.0 + 0.5 * i, 0.53, -0.75 + 0.5 * j)
					var c7: Color = [Color("c8b060"), Color("7ab8d8"), Color("e8e4d8"), Color("b85a4a"), Color("6a8a5a")][(i + j * 2) % 5]
					b.cyl(p7, 0.06, 0.03, MB.tag(c7, MB.METAL), Vector3.ZERO, 6)
			for i in 4:
				var a8 := TAU * i / 4.0 + 0.6
				b.sph(Vector3(cos(a8) * 1.6, 0.6, sin(a8) * 1.6), Vector3(0.2, 0.1, 0.16), MB.tag(Color("a8483a"), MB.SCALE - 0.1))
		"rib":
			var prev2 := Vector3(-1.2, 0, 0)
			for i in 12:
				var k2 := float(i + 1) / 12.0
				var nx2 := Vector3(-1.2 + 2.6 * k2 * k2, 13.0 * sin(k2 * PI * 0.55), 0.0)
				b.limb(prev2, nx2, 0.5 - 0.035 * i, 0.47 - 0.035 * i, bone, 7)
				prev2 = nx2
			b.sph(Vector3(-1.2, 0.2, 0), Vector3(0.9, 0.4, 0.8), MB.tag(Color("c8c0a8"), MB.STONE))
		"smoker":
			for i in 5:
				var a9 := TAU * i / 5.0
				var r9 := 0.3 + 0.9 * rng.randf()
				var h9 := 1.8 + 2.4 * rng.randf()
				var p9 := Vector3(cos(a9) * r9, 0, sin(a9) * r9)
				b.lathe(p9, [Vector2(0.5, 0.0), Vector2(0.36, h9 * 0.5), Vector2(0.22, h9), Vector2(0.16, h9 + 0.1)], dark, 7, MB.tag(Color("4a3a30"), MB.STONE))
				for j in 4:
					g.ball(p9 + Vector3(0.1 * sin(j * 2.0), h9 + 0.4 + 0.7 * j, 0.1 * cos(j * 2.0)), 0.2 + 0.12 * j, Color(0.12, 0.1, 0.1, 0.5), true)
				g.ball(p9 + Vector3(0, h9 + 0.05, 0), 0.12, Color(1.0, 0.5, 0.2, 0.8), true)
		"ice":
			b.sph(Vector3(0, 0.4, 0), Vector3(1.6, 0.7, 1.3), MB.tag(Color("e8f4ff"), MB.CRYSTAL))
			b.crystal(Vector3(0.5, 0.9, 0.2), 0.3, 0.8, MB.tag(Color("d8ecff"), MB.CRYSTAL), Vector3(0.2, 0, 0.3))
			b.crystal(Vector3(-0.6, 0.8, -0.2), 0.25, 0.6, MB.tag(Color("d8ecff"), MB.CRYSTAL), Vector3(-0.2, 0, -0.2))
			g.cone(Vector3(0, 1.45, 0), 0.22, 0.7, Color(0.4, 0.6, 1.0, 0.85), Vector3.ZERO, 8)
			g.cone(Vector3(0, 1.35, 0), 0.12, 0.4, Color(0.85, 0.95, 1.0, 0.95), Vector3.ZERO, 8)
		"shoal":
			for i in 26:
				var a10 := i * 0.62
				var p10 := Vector3(cos(a10) * (1.6 - 0.02 * i), 0.8 + 0.42 * i, sin(a10) * (1.6 - 0.02 * i))
				b.sph(p10, Vector3(0.18, 0.07, 0.05), MB.tag(Color("4a5a78"), MB.SCALE - 0.1), Vector3(0, -a10, 0))
				g.ball(p10 + Vector3(-sin(a10) * 0.24, 0.08, cos(a10) * 0.24), 0.05, Color(0.8, 1.0, 0.55, 0.95), true)
			b.sph(Vector3(0, 0.12, 0), Vector3(0.9, 0.16, 0.9), stone)
		"statue":
			b.box(Vector3(0, 0.2, 0), Vector3(1.4, 0.4, 1.0), stone)
			b.limb(Vector3(-0.2, 0.4, 0.15), Vector3(-0.1, 1.5, 0.05), 0.13, 0.16, stone, 6)
			b.limb(Vector3(0.3, 0.4, -0.2), Vector3(0.1, 1.5, -0.05), 0.13, 0.16, stone, 6)
			b.sph(Vector3(0, 2.1, 0), Vector3(0.42, 0.7, 0.3), stone)
			b.ball(Vector3(-0.05, 3.05, 0.02), 0.24, stone)
			b.cone(Vector3(-0.05, 3.3, 0.02), 0.42, 0.2, stone, Vector3.ZERO, 10)
			b.limb(Vector3(0.35, 2.5, 0), Vector3(0.6, 2.0, 0.3), 0.09, 0.08, stone, 5)
			b.limb(Vector3(-0.3, 2.5, 0), Vector3(-0.6, 2.9, -0.5), 0.09, 0.08, stone, 5)
			b.limb(Vector3(-0.75, 1.9, 0.5), Vector3(-0.5, 3.6, -0.9), 0.04, 0.04, wood, 5)
			b.box(Vector3(-0.47, 3.75, -1.0), Vector3(0.3, 0.36, 0.04), iron, Vector3(0.6, 0, 0))
			b.limb(Vector3(0.6, 2.0, 0.3), Vector3(0.6, 0.9, 0.3), 0.008, 0.008, dark, 3)
			b.cone(Vector3(0.6, 0.8, 0.3), 0.06, 0.2, iron, Vector3(PI, 0, 0), 6)
		"well":
			b.torus(Vector3(0, 0.55, 0), 0.75, 0.2, MB.tag(Color("8a5a48"), MB.STONE), Vector3.ZERO, true)
			b.cyl(Vector3(0, 0.28, 0), 0.9, 0.56, MB.tag(Color("7a5040"), MB.STONE), Vector3.ZERO, 12)
			b.cyl(Vector3(0, 0.57, 0), 0.6, 0.02, MB.tag(Color("08080c"), MB.STONE), Vector3.ZERO, 12)
			for i in 5:
				var a11 := TAU * i / 7.0
				b.limb(Vector3(cos(a11) * 1.15, 0, sin(a11) * 1.15), Vector3(cos(a11) * 1.15, 0.9, sin(a11) * 1.15), 0.04, 0.04, wood, 4)
				if i < 4:
					var a12 := TAU * (i + 1) / 7.0
					b.limb(Vector3(cos(a11) * 1.15, 0.85, sin(a11) * 1.15), Vector3(cos(a12) * 1.15, 0.85, sin(a12) * 1.15), 0.03, 0.03, wood, 4)
			b.limb(Vector3(0, 0.6, 0), Vector3(0.05, 7.0, 0.02), 0.02, 0.02, MB.tag(Color("c8b078"), MB.CLOTH), 4)
			for i in 6:
				b.ball(Vector3(0.01 * i, 1.2 + 1.0 * i, 0), 0.045, MB.tag(Color("a89058"), MB.CLOTH), true)
		"gate":
			for sx in [-1.0, 1.0]:
				b.sph(Vector3(sx * 1.9, 0.9, 0), Vector3(1.0, 1.7, 2.2), dark, Vector3(0, 0, -0.25 * sx))
				b.sph(Vector3(sx * 1.6, 2.6, 0.3), Vector3(0.7, 1.2, 1.4), stone, Vector3(0, 0, -0.5 * sx))
			b.box(Vector3(0, 0.03, 0), Vector3(1.9, 0.04, 3.4), MB.tag(Color("020306"), MB.STONE))
			for i in 6:
				g.arc(Vector3(0, 0.07 + 0.01 * i, 0), 0.25 + 0.14 * i, 0.03, i * 1.1, i * 1.1 + 4.4, Color(0.5, 0.75, 0.9, 0.5 - 0.06 * i), 14)
		"fan":
			for i in 7:
				var a13 := -0.9 + 0.3 * i
				var c13: Color = Color("8a7650").lerp(Color("b85a3a"), 1.0 if i == 3 else 0.12 * float(i % 3))
				b.sph(Vector3(sin(a13) * 1.5, 0.12, -cos(a13) * 1.5 + 1.2), Vector3(0.24, 0.2, 1.5), MB.tag(c13, MB.STONE), Vector3(0, -a13, 0))
			b.sph(Vector3(0, 0.2, 1.6), Vector3(0.9, 0.3, 0.7), MB.tag(Color("7a6848"), MB.STONE))
		"pillar":
			b.lathe(Vector3.ZERO, [Vector2(1.5, 0.0), Vector2(1.1, 1.2), Vector2(0.9, 3.4), Vector2(1.2, 4.4), Vector2(1.25, 4.6)], stone, 9, dark)
			b.cyl(Vector3(0, 4.62, 0), 1.2, 0.06, MB.tag(Color("7a7e86"), MB.STONE), Vector3.ZERO, 9)
			for i in 12:
				b.box(Vector3(-0.4 + 0.07 * i, 2.0, 0.98), Vector3(0.02, 0.2, 0.02), bone)
			for i in 9:
				g.ball(Vector3(-2.0 + 4.0 * rng.randf(), 9.0 + 6.0 * rng.randf(), -2.0 + 4.0 * rng.randf()), 0.07, Color(0.9, 0.95, 1.0, 0.9), true)
		"wall":
			for i in 6:
				var hh := 2.6 - 0.34 * i - 0.3 * rng.randf()
				b.box(Vector3(-2.2 + 0.88 * i, hh * 0.5, 0), Vector3(0.9, hh, 1.1 - 0.06 * i), MB.tag(Color("c89a4a").darkened(0.06 * (i % 3)), MB.STONE), Vector3(0, 0.03 * (i % 3 - 1), 0))
			b.sph(Vector3(2.3, 0.2, 0.3), Vector3(0.7, 0.3, 0.6), MB.tag(Color("c89a4a"), MB.STONE))
			g.disc(Vector3(0, 0.04, 0.9), 1.6, Color(1.0, 0.75, 0.35, 0.2), 12, Color(1.0, 0.75, 0.35, 0.0))
		"cauldron":
			b.lathe(Vector3(0, 0.75, 0), [Vector2(0.5, -0.5), Vector2(1.0, -0.2), Vector2(1.08, 0.4), Vector2(0.95, 0.7), Vector2(1.05, 0.78)], bronze, 12, MB.tag(Color("3a5a48"), MB.METAL))
			for i in 3:
				var a14 := TAU * i / 3.0 + 0.5
				b.limb(Vector3(cos(a14) * 0.7, 0.4, sin(a14) * 0.7), Vector3(cos(a14) * 0.8, -0.3, sin(a14) * 0.8), 0.14, 0.1, bronze, 6)
			for sx2 in [-1.0, 1.0]:
				b.torus(Vector3(sx2 * 0.95, 1.7, 0), 0.22, 0.05, bronze, Vector3(0, PI / 2, 0))
			for i in 9:
				b.box(Vector3(-0.5 + 0.12 * i, 1.0 + 0.1 * sin(i * 1.3), 1.07 - 0.02 * absf(i - 4.0)), Vector3(0.09, 0.09 + 0.05 * (i % 3), 0.02), MB.tag(Color("8ab08a"), MB.METAL))
			root.set_meta("tilt", Vector3(0.22, 0, 0.12))
		_:
			# the bones of a whale laid along the floor, and a garden on every one
			b.sph(Vector3(-2.2, 0.5, 0), Vector3(0.9, 0.5, 0.6), bone)
			b.limb(Vector3(-2.9, 0.3, 0.2), Vector3(-1.4, 0.2, 0.3), 0.08, 0.05, bone, 5)
			b.limb(Vector3(-1.6, 0.4, 0), Vector3(2.6, 0.25, 0), 0.14, 0.06, bone, 6)
			for i in 8:
				var x := -1.2 + 0.42 * i
				var rr := 0.95 - 0.07 * i
				for sz2 in [-1.0, 1.0]:
					b.limb(Vector3(x, 0.4, 0), Vector3(x, 0.4 + rr, sz2 * rr * 0.7), 0.05, 0.04, bone, 5)
					b.limb(Vector3(x, 0.4 + rr, sz2 * rr * 0.7), Vector3(x, 0.1, sz2 * rr * 1.05), 0.04, 0.02, bone, 5)
				var c15: Color = [Color("e8e0d8"), Color("c8483a"), Color("e89ab0"), Color("f0d060")][i % 4]
				b.cone(Vector3(x, 0.55 + rr, 0.1 * (i % 3 - 1)), 0.09, 0.3, MB.tag(c15, MB.FOLIAGE), Vector3.ZERO, 6)
				g.ball(Vector3(x + 0.1, 0.5, 0.2 * (i % 2)), 0.04, Color(c15.r, c15.g, c15.b, 0.9), true)
	# a little light lies round every one of them, so that it can be made out across the floor
	g.disc(Vector3(0, 0.05, 0), 2.7, Color(0.75, 1.0, 0.95, 0.14), 18, Color(0.75, 1.0, 0.95, 0.0))
	var body := Node3D.new()
	body.name = "body"
	body.rotation = root.get_meta("tilt", Vector3.ZERO)
	if str(sg.m) == "bell":
		body.position = Vector3(0, 0.95, 0)
	# (the longest of them are drawn a little under life size, so that each keeps to its own ground)
	if str(sg.m) in ["wreck", "gate"] or not str(sg.m) in MODELS:
		body.scale = Vector3.ONE * 0.9
	root.add_child(body)
	if not b.is_empty():
		MB.mesh_node(body, b.build())
	if not g.is_empty():
		MB.mesh_node(body, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

const SURFACE := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
uniform vec3 lit : source_color = vec3(0.75, 1.0, 0.95);
uniform vec3 deep : source_color = vec3(0.05, 0.3, 0.45);
uniform float dim = 1.0;
varying vec3 wp;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wp.xz * 0.045;
	float t = TIME * 0.25;
	float a = n(p + vec2(t, t * 0.6)) + 0.5 * n(p * 2.3 - vec2(t * 1.3, t));
	float b = n(p * 1.4 - vec2(t * 0.7, -t)) + 0.5 * n(p * 3.1 + vec2(t, t * 1.7));
	float c = pow(1.0 - abs(a - b), 9.0);
	ALBEDO = mix(deep, lit, clamp(0.25 + c * 1.4, 0.0, 1.0)) * dim;
	ALPHA = 0.92;
}
"""

## The dressing of the realm: the water overhead, the light that comes down through it, and the dark its
## floor falls away into.
static func dress(root: Node3D, wd: Dictionary) -> void:
	var W: int = wd.w
	var H: int = wd.h
	var T := Terrain3D.T
	var far := 700.0
	# the dark beyond the edge of the floor
	var ab := MB.new()
	var up := Vector3.UP
	var dk := Color(0.01, 0.03, 0.06)
	ab.quad_n([Vector3(-far, -34.0, -far), Vector3(W * T + far, -34.0, -far), Vector3(W * T + far, -34.0, H * T + far), Vector3(-far, -34.0, H * T + far)], [up, up, up, up], [dk, dk, dk, dk])
	MB.mesh_node(root, ab.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Terrain3D._undersides(root, wd, 10.0, 30.0, Color("3a4448"), true)
	# the surface, seen from underneath
	var sm := ShaderMaterial.new()
	sm.shader = MB._shader(SURFACE)
	var sb := MB.new()
	var dn := Vector3.DOWN
	var wh := Color(1, 1, 1, 1)
	sb.quad_n([Vector3(-far, SURFACE_Y, -far), Vector3(-far, SURFACE_Y, H * T + far), Vector3(W * T + far, SURFACE_Y, H * T + far), Vector3(W * T + far, SURFACE_Y, -far)], [dn, dn, dn, dn], [wh, wh, wh, wh])
	var smi := MB.mesh_node(root, sb.build(sm))
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smi.name = "surface"
	# shafts of light coming down through it, over every country but the Northern Dark
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var owner: PackedByteArray = wd.owner
	var ids: Array = wd.ids
	var sea: PackedByteArray = wd.sea
	var lb := MB.new()
	var n := 0
	var tries := 0
	while n < 420 and tries < 6000:
		tries += 1
		var tx := rng.randi_range(2, W - 3)
		var tz := rng.randi_range(2, H - 3)
		if sea[tz * W + tx] == 1:
			continue
		var a := str(ids[owner[tz * W + tx]])
		if a == "beiming" or (a == "weilu" and rng.randf() < 0.6):
			continue
		n += 1
		var x := (tx + rng.randf()) * T
		var z := (tz + rng.randf()) * T
		var wdt := rng.randf_range(0.5, 1.8)
		var lean := Vector3(rng.randf_range(2.0, 5.0), 0, rng.randf_range(-1.5, 1.5))
		var top := Vector3(x, SURFACE_Y, z) + lean
		var bot := Vector3(x, 0.5, z)
		var side := Vector3(cos(n * 1.7), 0, sin(n * 1.7)) * wdt
		var c0 := Color(0.75, 1.0, 0.9, 0.11)
		var c1 := Color(0.75, 1.0, 0.9, 0.0)
		lb.quad4(top - side, top + side, bot + side * 1.6, bot - side * 1.6, c0, c0, c1, c1)
	var lmi := MB.mesh_node(root, lb.build(MB.mat_glow()))
	lmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lmi.name = "shafts"
