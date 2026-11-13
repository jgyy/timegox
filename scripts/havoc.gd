class_name Havoc
extends RefCounted
## Things that break (the Living Land release).  The towns are full of the things people own and
## leave about: jars of pickles and oil by the inn's wall, crates and baskets of greens outside the
## shops, barrels by the smithy, haystacks, woodpiles and handcarts by the farmhouses, stacks of pots,
## lanterns on poles at the shrine.  Lin Feng can break them: F swings his sword (a cut in front of
## him breaks whatever it meets, cuts the grass and shakes the leaves), and a ride at the gallop
## goes straight through them; on foot he only jostles them.  A thing that breaks really breaks: it
## comes apart into rigid bodies (shards, planks, staves, logs that roll, cabbages that bounce) that
## fly from the blow, tumble on the ground under them (a height field sampled from the terrain) and
## are kicked about by the party walking through them, then fade.  Fights in the land leave their
## mark too: the ground where a battle was won is scorched and littered with stones for a few hours,
## and in the battle arena a heavy blow throws up chunks of the floor and burns a scar into it.
##
## The people notice.  The owner of a thing broken on purpose is paid for it (the price of a jar is
## small, but it is paid); one smashed by a galloping horse gets a piece of the owner's mind instead;
## and the townsfolk round about start and stare.  By the next dawn the owner has mended it.  Out in
## the wild, a crate left at a camp may hold a few spirit stones.
##
## What breaks and where is fixed (made from the town's map), and what is broken is game state
## (Game.broken: id -> the minute it broke), so the bot and the tests see the same world; only the
## flying pieces are physics, and they are drawn and simulated only on screen.

## what breaks: its name, the pieces it comes apart into and their colour, how many, a burst of
## dust and bits of it, and whether it is only jostled (not broken) by somebody walking into it
const KINDS := {
	"jar": {"n": "jar of pickles", "piece": "shard", "col": Color("b8744a"), "n_p": 7, "puff": Color("d8c890")},
	"crate": {"n": "crate", "piece": "plank", "col": Color("b08850"), "n_p": 6, "puff": Color("c8a878")},
	"barrel": {"n": "barrel", "piece": "stave", "col": Color("8a5a34"), "n_p": 7, "puff": Color("a88a60")},
	"basket": {"n": "basket of greens", "piece": "veg", "col": Color("6aa040"), "n_p": 6, "puff": Color("c0a06a")},
	"hay": {"n": "haystack", "piece": "straw", "col": Color("d8b860"), "n_p": 6, "puff": Color("e8d080")},
	"woodpile": {"n": "woodpile", "piece": "log", "col": Color("8a6038"), "n_p": 6, "puff": Color("a8885a")},
	"cart": {"n": "handcart", "piece": "plank", "col": Color("9a7048"), "n_p": 6, "puff": Color("b89868")},
	"pots": {"n": "stack of pots", "piece": "shard", "col": Color("c88a5a"), "n_p": 8, "puff": Color("d8a880")},
	"lantern_pole": {"n": "lantern", "piece": "paper", "col": Color("e05a3a"), "n_p": 4, "puff": Color("f0c070")},
	# the floor of the battle arena, thrown up by a heavy blow
	"rubble": {"n": "rubble", "piece": "rock", "col": Color("8a8478"), "n_p": 6, "puff": Color("b0a898")},
}
## what stands round the walls of each kind of building
const BY_STYLE := {"inn": ["barrel", "jar", "barrel"], "teahouse": ["jar", "pots"], "shop": ["crate", "basket", "pots"], "farmhouse": ["hay", "woodpile", "cart"],
	"smithy": ["barrel", "woodpile", "crate"], "house": ["jar", "woodpile", "basket"], "huizhou": ["jar", "crate", "basket"], "dorm": ["crate", "barrel"],
	"shrine": ["lantern_pole", "jar"], "hall": ["lantern_pole", "lantern_pole"], "kitchen": ["jar", "barrel", "woodpile"], "library": ["crate"],
	"alchemist": ["jar", "pots"], "seahouse": ["basket", "barrel"], "aerie": ["basket", "crate"]}
## the price of a thing broken on purpose: so many spirit stones, and so many more for each realm
## Lin Feng has reached (a cultivator's purse is deeper, and so is the shame)
const PRICE := 5
const PRICE_REALM := 3
## a thing broken by a fight or a ride is mended by the next dawn (the hour it is mended)
const MEND_HOUR := 6.0
## the scars a battle leaves on the land last this many minutes of the clock
const SCAR_MINUTES := 240.0

# ---------------------------------------------------------------- where things stand
static var _placed := {}

## The breakable things of region `area` in realm data `wd`: [{id, kind, tile, yaw, town, area}],
## a few round the walls of every building of every town in it (outside, off the roads, never by a
## door or anything else, and only where there is open ground round them so no lane is blocked).
static func of_area(wd: Dictionary, area: String) -> Array:
	var key := "%s|%s" % [str(wd.get("layer", "")), area]
	if _placed.has(key):
		return _placed[key]
	var out: Array = []
	var taken := {}
	for e in wd.ents:
		# (Part XVII's obstacles, impact.gd, and the people and things that came later in the story, "late",
		# came after these were set out: they leave them where they were)
		if str(e.get("area", "")) != area or e.kind == "obstacle" or e.get("late", false):
			continue
		taken[e.pos] = true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			taken[e.pos + d] = true
	for tid in Folk.towns_in(area):
		var c := Folk.heart(tid)
		var bi := 0
		for bd in wd.buildings:
			if str(bd.area) != area:
				continue
			var r: Rect2i = bd.rect
			if maxi(absi(r.get_center().x - c.x), absi(r.get_center().y - c.y)) > Folk.RADIUS + 4:
				continue
			var door: Vector2i = bd.door
			var kinds: Array = BY_STYLE.get(str(bd.get("style", "house")), ["jar", "crate"])
			var made := 0
			# walk round the outside of the walls, starting somewhere of the building's own
			var ring: Array = []
			for x in range(r.position.x - 1, r.end.x + 1):
				ring.append(Vector2i(x, r.position.y - 1))
				ring.append(Vector2i(x, r.end.y))
			for y in range(r.position.y, r.end.y):
				ring.append(Vector2i(r.position.x - 1, y))
				ring.append(Vector2i(r.end.x, y))
			var start := absi(hash(str(bd.id))) % maxi(1, ring.size())
			for k in ring.size():
				if made >= 2:
					break
				var p: Vector2i = ring[(start + k * 5) % ring.size()]
				if taken.has(p) or p.distance_squared_to(door) <= 9 or not _open(wd, p, area):
					continue
				var kind: String = kinds[(bi + made) % kinds.size()]
				var out_d := Vector2(p - r.get_center())
				out.append({"id": "brk:%s:%d" % [area, out.size()], "kind": kind, "tile": p, "yaw": atan2(out_d.x, out_d.y) + PI, "town": tid, "area": area, "bld": bd.id})
				for d2 in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					taken[p + d2] = true
				made += 1
			bi += 1
	_placed[key] = out
	return out

## Whether a thing may stand at `p`: open ground of the region (not a road), with open ground round
## it, so nobody's way is ever blocked by a woodpile.
static func _open(wd: Dictionary, p: Vector2i, area: String) -> bool:
	if p.x < 1 or p.y < 1 or p.x >= int(wd.w) - 1 or p.y >= int(wd.h) - 1:
		return false
	var g: int = wd.grid[p.y * int(wd.w) + p.x]
	if g != MapGen.FLOOR and g != MapGen.DECOR:
		return false
	if Atlas.owner_id(wd, p) != area:
		return false
	var open_n := 0
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q: Vector2i = p + d
		var gq: int = wd.grid[q.y * int(wd.w) + q.x]
		if MapGen.is_walkable_tile(gq) and gq != MapGen.INTERIOR:
			open_n += 1
	return open_n >= 3

## The tiles of region `area` with something on them (tile -> the thing).
static func tiles(wd: Dictionary, area: String) -> Dictionary:
	var key := "tiles|%s|%s" % [str(wd.get("layer", "")), area]
	if _placed.has(key):
		return _placed[key]
	var out := {}
	for b in of_area(wd, area):
		out[b.tile] = b
	_placed[key] = out
	return out

## The thing standing on tile `p` of realm `wd`, or {}.
static func at_tile(wd: Dictionary, p: Vector2i) -> Dictionary:
	return tiles(wd, Atlas.owner_id(wd, p)).get(p, {})

# ---------------------------------------------------------------- broken and mended
## The minute of the whole game (days and the clock) in `g`.
static func now(g) -> float:
	return float(g.day) * 1440.0 + float(g.clock)

## Whether thing `b` lies broken (it is mended at the first MEND_HOUR after it broke).
static func is_broken(g, b: Dictionary) -> bool:
	if not g.broken.has(b.id):
		return false
	var at: float = float(g.broken[b.id])
	var mend: float = (floorf((at - MEND_HOUR * 60.0) / 1440.0) + 1.0) * 1440.0 + MEND_HOUR * 60.0
	if now(g) >= mend:
		g.broken.erase(b.id)
		return false
	return true

## The owner of a thing in a town: one of its people (folk.gd), the same one every time.
static func owner_of(wd: Dictionary, b: Dictionary) -> Dictionary:
	var ppl: Array = Folk.people(wd, str(b.town))
	return ppl[absi(hash(str(b.id))) % ppl.size()] if not ppl.is_empty() else {}

## Break thing `b` (`why`: "strike", Lin Feng's sword; "ride", a gallop through it; "battle", a fight
## beside it).  Remembered in `g`; returns what is said of it (the owner's words, a price paid).
static func smash(g, wd: Dictionary, b: Dictionary, why: String) -> Array:
	if is_broken(g, b):
		return []
	g.broken[b.id] = now(g)
	g.smashed += 1
	var out: Array = []
	var k: Dictionary = KINDS[str(b.kind)]
	var ow := owner_of(wd, b)
	var who: String = str(ow.get("n", "Somebody"))
	# (the Answering Land release, weal.gd: a town remembers what is broken in its streets, and a town
	# that is cold to him asks double for it)
	var area := str(b.get("area", ""))
	var wtid := Weal.town_of(area)
	match why:
		"strike":
			var price: int = maxi(1, int(round(float(PRICE + PRICE_REALM * int(g.realm())) * Weal.mod(g, area, "mend"))))
			Weal.act(g, wtid, "broke")
			if g.stones >= price:
				g.stones -= price
				out.append("%s's %s: you pay %d spirit stones for it" % [who, str(k.n), price])
			else:
				Weal.act(g, wtid, "unpaid")
				out.append("%s: \"My %s! And not a stone to pay for it, %s?\"" % [who, str(k.n), str(g.address())])
		"ride":
			out.append("%s: \"Mind where you ride, %s! My %s!\"" % [who, str(g.address()), str(k.n)])
		_:
			pass
	return out

# ---------------------------------------------------------------- the things themselves
## The 3D model of a breakable thing (procedural, a few hundred triangles).
static func model(kind: String) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	var wood := MB.tag(Color("9a7048"), MB.WOOD)
	var dark := MB.tag(Color("5a3a22"), MB.WOOD)
	match kind:
		"jar":
			b.lathe(Vector3.ZERO, [Vector2(0.16, 0.0), Vector2(0.26, 0.18), Vector2(0.27, 0.36), Vector2(0.17, 0.56), Vector2(0.12, 0.62), Vector2(0.14, 0.66)], MB.tag(Color("a8643a"), MB.STONE), 12)
			b.lathe(Vector3(0, 0.66, 0), [Vector2(0.15, 0.0), Vector2(0.13, 0.05), Vector2(0.02, 0.08)], MB.tag(Color("6a4a2a"), MB.WOOD), 10)
			b.torus(Vector3(0, 0.42, 0), 0.265, 0.012, MB.tag(Color("e0c890"), MB.CLOTH))
		"crate":
			b.box(Vector3(0, 0.3, 0), Vector3(0.62, 0.6, 0.62), MB.tag(Color("b08850"), MB.WOOD))
			for y in [0.05, 0.55]:
				b.box(Vector3(0, y, 0), Vector3(0.66, 0.08, 0.66), dark)
			b.box(Vector3(0, 0.3, 0.315), Vector3(0.08, 0.6, 0.02), dark, Vector3(0, 0, 0.78))
		"barrel":
			b.lathe(Vector3.ZERO, [Vector2(0.22, 0.0), Vector2(0.27, 0.2), Vector2(0.28, 0.36), Vector2(0.27, 0.52), Vector2(0.22, 0.72)], MB.tag(Color("8a5a34"), MB.WOOD), 14)
			for y2 in [0.1, 0.62]:
				b.torus(Vector3(0, y2, 0), 0.272, 0.018, MB.tag(Color("4a4a50"), MB.METAL))
			b.cyl(Vector3(0, 0.72, 0), 0.21, 0.02, dark, Vector3.ZERO, 14)
		"basket":
			b.lathe(Vector3.ZERO, [Vector2(0.18, 0.0), Vector2(0.26, 0.24), Vector2(0.27, 0.3)], MB.tag(Color("c0a06a"), MB.WOOD), 12)
			for i in 5:
				var a := i * TAU / 5.0
				b.sph(Vector3(cos(a) * 0.12, 0.3, sin(a) * 0.12), Vector3(0.09, 0.08, 0.09), MB.tag(Color("6aa040") if i % 2 == 0 else Color("e8a030"), MB.FOLIAGE))
		"hay":
			b.lathe(Vector3.ZERO, [Vector2(0.55, 0.0), Vector2(0.6, 0.35), Vector2(0.45, 0.8), Vector2(0.18, 1.05), Vector2(0.02, 1.15)], MB.tag(Color("d8b860"), MB.FOLIAGE), 12)
			b.limb(Vector3(0, 0.9, 0), Vector3(0, 1.35, 0), 0.025, 0.02, wood, 4)
		"woodpile":
			for i2 in 6:
				var row := int(i2 / 3)
				var x := (i2 % 3 - 1) * 0.2 + row * 0.1
				b.cyl(Vector3(x, 0.09 + row * 0.17, 0), 0.09, 0.7, MB.tag(Color("8a6038"), MB.WOOD), Vector3(PI * 0.5, 0, 0), 8)
		"cart":
			b.box(Vector3(0, 0.45, 0), Vector3(0.7, 0.08, 1.0), wood)
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.34 * s, 0.56, 0), Vector3(0.04, 0.2, 1.0), wood)
				b.cyl(Vector3(0.4 * s, 0.32, 0.1), 0.3, 0.05, dark, Vector3(0, 0, PI * 0.5), 12)
				b.limb(Vector3(0.28 * s, 0.48, -0.5), Vector3(0.32 * s, 0.62, -1.05), 0.025, 0.02, wood, 4)
			b.sph(Vector3(0, 0.6, 0.1), Vector3(0.28, 0.12, 0.38), MB.tag(Color("6aa040"), MB.FOLIAGE))
		"pots":
			for i3 in 3:
				var p := Vector3(-0.18 + i3 * 0.18, 0.0, 0.05 * (i3 % 2))
				b.lathe(p, [Vector2(0.08, 0.0), Vector2(0.13, 0.12), Vector2(0.1, 0.22), Vector2(0.11, 0.25)], MB.tag(Color("c88a5a"), MB.STONE), 10)
			b.lathe(Vector3(0.0, 0.25, 0.02), [Vector2(0.07, 0.0), Vector2(0.11, 0.1), Vector2(0.08, 0.18), Vector2(0.09, 0.2)], MB.tag(Color("b0703a"), MB.STONE), 10)
		"lantern_pole":
			b.limb(Vector3(0, 0, 0), Vector3(0, 2.1, 0), 0.04, 0.03, dark, 5)
			b.limb(Vector3(0, 2.0, 0), Vector3(0.45, 2.05, 0), 0.02, 0.02, dark, 4)
			b.lathe(Vector3(0.45, 1.5, 0), [Vector2(0.05, 0.0), Vector2(0.15, 0.08), Vector2(0.16, 0.22), Vector2(0.12, 0.34), Vector2(0.05, 0.38)], MB.tag(Color("e05a3a"), MB.CLOTH), 10)
			g.ball(Vector3(0.45, 1.68, 0), 0.32, Color(1.0, 0.55, 0.28, 0.4), true)
	MB.mesh_node(root, b.build(MB.mat_vc()))
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

# ---------------------------------------------------------------- the pieces (rigid bodies)
static var _piece_mesh := {}

## The mesh of one piece and the size of its box: [mesh, Vector3 size, round (a log or a cabbage
## rolls)].
static func _piece(kind: String, col: Color) -> Array:
	var key := "%s|%s" % [kind, col.to_html(false)]
	if _piece_mesh.has(key):
		return _piece_mesh[key]
	var b := MB.new()
	var size := Vector3(0.2, 0.05, 0.2)
	var rolls := false
	match kind:
		"shard":
			size = Vector3(0.2, 0.04, 0.16)
			b.box(Vector3.ZERO, size, MB.tag(col, MB.STONE), Vector3(0, 0.3, 0))
		"plank":
			size = Vector3(0.6, 0.04, 0.12)
			b.box(Vector3.ZERO, size, MB.tag(col, MB.WOOD))
		"stave":
			size = Vector3(0.12, 0.66, 0.04)
			b.box(Vector3.ZERO, size, MB.tag(col, MB.WOOD))
		"veg":
			size = Vector3(0.16, 0.16, 0.16)
			rolls = true
			b.sph(Vector3.ZERO, Vector3(0.09, 0.08, 0.09), MB.tag(col, MB.FOLIAGE))
		"straw":
			size = Vector3(0.36, 0.1, 0.24)
			b.sph(Vector3.ZERO, Vector3(0.2, 0.06, 0.13), MB.tag(col, MB.FOLIAGE))
		"log":
			size = Vector3(0.18, 0.7, 0.18)
			rolls = true
			b.cyl(Vector3.ZERO, 0.09, 0.7, MB.tag(col, MB.WOOD), Vector3.ZERO, 8)
		"paper":
			size = Vector3(0.3, 0.3, 0.3)
			b.lathe(Vector3(0, -0.15, 0), [Vector2(0.05, 0.0), Vector2(0.15, 0.08), Vector2(0.16, 0.22), Vector2(0.05, 0.3)], MB.tag(col, MB.CLOTH), 8)
		"rock":
			size = Vector3(0.34, 0.26, 0.3)
			b.sph(Vector3.ZERO, Vector3(0.19, 0.14, 0.17), MB.tag(col, MB.STONE))
	var out := [b.build(MB.mat_vc()), size, rolls]
	_piece_mesh[key] = out
	return out

## A patch of ground for flying pieces to land on: a height field `half` metres either side of `at`,
## sampled from `ground` (a Callable taking a world point and returning the height there).
static func ground_patch(at: Vector3, ground: Callable, half: int = 8) -> StaticBody3D:
	var sb := StaticBody3D.new()
	var hs := HeightMapShape3D.new()
	var n := half * 2 + 1
	hs.map_width = n
	hs.map_depth = n
	var data := PackedFloat32Array()
	data.resize(n * n)
	var base := Vector3(round(at.x), 0.0, round(at.z))
	for zi in n:
		for xi in n:
			data[zi * n + xi] = float(ground.call(base + Vector3(xi - half, 0.0, zi - half)))
	hs.map_data = data
	var cs := CollisionShape3D.new()
	cs.shape = hs
	sb.add_child(cs)
	sb.position = base
	return sb

## Thing `kind` comes apart at `at`: its pieces fly from the blow (`dir`, horizontal) and tumble on
## the ground (`ground`, see ground_patch, or null for a flat floor at `at.y`), then fade.  Returns
## the node holding it all (it frees itself).
static func burst(parent: Node3D, kind: String, at: Vector3, dir: Vector3, ground, power: float = 1.0, col_over: Color = Color(0, 0, 0, 0)) -> Node3D:
	var root := Node3D.new()
	root.name = "debris"
	parent.add_child(root)
	if ground is Callable:
		root.add_child(ground_patch(at, ground))
	else:
		var fl := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = WorldBoundaryShape3D.new()
		fl.add_child(cs)
		fl.position = Vector3(0, at.y, 0)
		root.add_child(fl)
	var k: Dictionary = KINDS.get(kind, {"piece": "rock", "col": Color("8a8478"), "n_p": 6, "puff": Color("a8a090")})
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(at.snapped(Vector3.ONE * 0.1)) + kind)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.85
	pm.bounce = 0.28
	var d := Vector3(dir.x, 0.0, dir.z)
	d = d.normalized() if d.length() > 0.01 else Vector3(0, 0, 1)
	var bodies: Array = []
	for i in int(k.n_p):
		var col: Color = k.col if col_over.a <= 0.0 else col_over
		if kind == "basket":
			col = Color("6aa040") if i % 2 == 0 else Color("e8a030")
		elif kind in ["jar", "pots", "crate", "barrel", "cart"]:
			col = col.darkened(rng.randf_range(0.0, 0.25))
		var pc: Array = _piece(str(k.piece), col)
		var rb := RigidBody3D.new()
		rb.mass = 0.5 if not pc[2] else 0.8
		rb.physics_material_override = pm
		var cs2 := CollisionShape3D.new()
		if pc[2] and str(k.piece) == "veg":
			var sp := SphereShape3D.new()
			sp.radius = 0.085
			cs2.shape = sp
		elif pc[2]:
			var cy := CylinderShape3D.new()
			cy.radius = 0.09
			cy.height = 0.7
			cs2.shape = cy
		else:
			var bx := BoxShape3D.new()
			bx.size = pc[1]
			cs2.shape = bx
		rb.add_child(cs2)
		var mi := MeshInstance3D.new()
		mi.mesh = pc[0]
		rb.add_child(mi)
		root.add_child(rb)
		var sp_a := rng.randf_range(-1.1, 1.1)
		var out_v := d.rotated(Vector3.UP, sp_a) * rng.randf_range(2.0, 4.6) * power
		rb.position = at + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.25, 0.7), rng.randf_range(-0.2, 0.2))
		rb.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		rb.linear_velocity = out_v + Vector3(0, rng.randf_range(2.2, 4.4) * power, 0)
		rb.angular_velocity = Vector3(rng.randf_range(-9, 9), rng.randf_range(-9, 9), rng.randf_range(-9, 9))
		bodies.append(rb)
	Fx3D.dust(parent, at + Vector3(0, 0.3, 0), k.puff)
	Fx3D.dust(parent, at + Vector3(0, 0.5, 0) + d * 0.4, k.puff)
	# the pieces lie a while where they fell, then sink away
	var tw := root.create_tween()
	tw.tween_interval(7.0)
	for rb2 in bodies:
		tw.parallel().tween_property(rb2, "scale", Vector3.ONE * 0.01, 1.2)
	tw.tween_callback(root.queue_free)
	return root

## A battle's mark on the ground at `at`: a scorched patch with cracks running out of it, draped over
## the ground (`ground` a Callable giving the height at a point, or null for flat at `at.y`).
static var _scar_mat: StandardMaterial3D = null
static func scar(at: Vector3, radius: float, ground, col: Color = Color(0.07, 0.05, 0.04, 0.8)) -> MeshInstance3D:
	if _scar_mat == null:
		_scar_mat = StandardMaterial3D.new()
		_scar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_scar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_scar_mat.vertex_color_use_as_albedo = true
		_scar_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_scar_mat.render_priority = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(at.snapped(Vector3.ONE * 0.1)))
	var hy := func(p: Vector3) -> float:
		return (float(ground.call(p)) if ground is Callable else at.y) + 0.06
	var vs := PackedVector3Array()
	var cs := PackedColorArray()
	var edge := Color(col.r, col.g, col.b, 0.0)
	var c := Vector3(at.x, hy.call(at), at.z)
	var segs := 16
	var rs: Array = []
	for i in segs:
		rs.append(radius * rng.randf_range(0.7, 1.0))
	for i in segs:
		var a0 := i * TAU / segs
		var a1 := (i + 1) * TAU / segs
		var mid0 := at + Vector3(cos(a0), 0, sin(a0)) * float(rs[i]) * 0.6
		var mid1 := at + Vector3(cos(a1), 0, sin(a1)) * float(rs[(i + 1) % segs]) * 0.6
		var out0 := at + Vector3(cos(a0), 0, sin(a0)) * float(rs[i])
		var out1 := at + Vector3(cos(a1), 0, sin(a1)) * float(rs[(i + 1) % segs])
		mid0.y = hy.call(mid0)
		mid1.y = hy.call(mid1)
		out0.y = hy.call(out0)
		out1.y = hy.call(out1)
		vs.append_array([c, mid0, mid1, mid0, out0, out1, mid0, out1, mid1])
		cs.append_array([col, col, col, col, edge, edge, col, edge, col])
	# cracks running out of it
	for j in 7:
		var a := rng.randf() * TAU
		var q0 := at + Vector3(cos(a), 0, sin(a)) * radius * 0.5
		var q1 := at + Vector3(cos(a + rng.randf_range(-0.25, 0.25)), 0, sin(a + rng.randf_range(-0.25, 0.25))) * radius * rng.randf_range(1.3, 1.9)
		q0.y = hy.call(q0)
		q1.y = hy.call(q1)
		var side := Vector3(-sin(a), 0, cos(a)) * 0.08
		vs.append_array([q0 - side, q0 + side, q1])
		cs.append_array([col, col, edge])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_COLOR] = cs
	var nrm := PackedVector3Array()
	nrm.resize(vs.size())
	nrm.fill(Vector3.UP)
	arr[Mesh.ARRAY_NORMAL] = nrm
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	am.surface_set_material(0, _scar_mat)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
