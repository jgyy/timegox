class_name Clash
extends RefCounted
## Things that share ground (the Answering Land release): what stands where, how much ground it covers, and
## an audit of every realm for two things in one place.
##
## Everything in the land is stood on a tile, and almost everything is drawn within its own tile; what
## is not (a lord of the size of a dragon, a row of things a choice left standing, a plot of the hero's
## town, a machine) covers the tiles round it too (`REACH`).  `stood` is the ground a region's view keeps
## clear of scattered rocks, bushes, logs and stumps.  `audit` finds, without drawing anything:
##
##   * two things on one tile at the same point of the story (`same`);
##   * something stood on water, in a wall or inside a house's wall (`ground`);
##   * a thing that breaks (havoc.gd) where something else stands (`breaks`);
##   * a townsperson whose day sends them to stand on something (`folk`);
##   * two things whose models, as they are drawn, come into one another's ground (`reach`: footprints are
##     measured from the models themselves, below the height of a head).
##
## Nothing is moved off its tile to mend a clash: every map, and the bot's road over it, is where it was.
## A person or a thing to find that stands in the footprint of something bigger is **drawn** a step aside
## (`nudge`, at most NUDGE_MAX metres, never off its own tile); what a nudge cannot mend is reported.
## The tests run the audit and expect nothing.

## how far round its own tile a kind of thing is kept clear of scatter (tiles)
const REACH := {"boss": 1, "hold": 1, "machine": 1, "mark": 1, "npc": 0, "pickup": 0, "prop": 0}
## the kinds that stand still on a tile and are drawn there
const STANDS := ["npc", "boss", "pickup", "prop", "mark", "hold", "machine", "stele", "abode", "spring", "ladder", "obstacle"]
## what stands no higher than this (metres) is what somebody can walk into: a roof's eave or a tree's crown
## over a neighbour's head is not a clash
const HEAD := 1.7
## a person, and a thing lying on the ground to be found: how much ground each covers (metres from its middle)
const PERSON := 0.36
const SMALL := 0.3
## two footprints may come this close (metres) before they are said to share ground
const SLACK := 0.12
## how far a person or a thing to find may be drawn from the middle of its own tile to stand clear
const NUDGE_MAX := 0.85
## the small things that step aside for the big ones
const STEPS_ASIDE := ["npc", "pickup"]

# ---------------------------------------------------------------- footprints
static var _foot := {}

## How far from its own middle the model under `n` reaches along the ground, counting only what stands
## below HEAD: read from the vertices of everything drawn there (nothing is rendered).
static func footprint(n: Node3D) -> float:
	var m := 0.0
	var stack: Array = [[n, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var nd: Node = it[0]
		var xf: Transform3D = it[1]
		if nd is Node3D and nd != n:
			xf = xf * (nd as Node3D).transform
		if nd is MeshInstance3D and (nd as MeshInstance3D).mesh != null:
			var mesh: Mesh = (nd as MeshInstance3D).mesh
			for si in mesh.get_surface_count():
				var arr: Array = mesh.surface_get_arrays(si)
				if arr.is_empty() or arr[Mesh.ARRAY_VERTEX] == null:
					continue
				for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					var c := xf * v
					if c.y < HEAD and c.y > 0.08:
						m = maxf(m, Vector2(c.x, c.z).length())
		for ch in nd.get_children():
			stack.append([ch, xf])
	return m

## How much ground entity `e` covers (metres from the middle of its tile), measured once for each kind of
## thing from the model it is drawn with.
static func extent(e: Dictionary) -> float:
	var key := ""
	match str(e.kind):
		"npc":
			return PERSON
		"pickup", "spring", "stele", "abode", "obstacle", "ladder":
			return SMALL
		"boss":
			# (a lord is as wide as its shape is drawn: a general a person's width, a dragon a dragon's)
			var en: Dictionary = Data.ENEMIES.get(str(e.get("enemy", "")), {})
			var shape := str(en.get("shape", "humanoid"))
			if shape.begins_with("person:"):
				return PERSON + 0.1
			var bk := "boss:" + shape
			if not _foot.has(bk):
				var bn: Node3D = Models.monster(shape, en.get("col", Color.WHITE), true, str(e.get("enemy", "")))
				_foot[bk] = clampf(footprint(bn) if bn != null else 0.6, 0.4, 3.0)
				if bn != null:
					bn.free()
			return float(_foot[bk])
		"hold":
			# (a length of the town's wall is its own shape)
			key = "hold:" + (str(e.id) if e.has("seg") else str(e.get("plot", "")))
		"machine":
			key = "machine:" + str(e.get("work", ""))
		"prop":
			key = "prop:" + str(e.get("prop", ""))
		"mark":
			var ms: Dictionary = Marks.MARKS.get(str(e.get("cross", "")), {})
			# (whichever answer is chosen stands there: the widest of them)
			var widest := 0.0
			for oid in ms:
				if str(ms[oid].get("area", "")) == str(e.get("area", "")):
					var mk := "mark:" + str(ms[oid].m)
					if not _foot.has(mk):
						var mn := Marks.model(ms[oid], 0)
						_foot[mk] = footprint(mn)
						mn.free()
					widest = maxf(widest, float(_foot[mk]))
			return widest
	if key == "":
		return SMALL
	if not _foot.has(key):
		var n: Node3D = null
		match str(e.kind):
			"hold":
				n = Hold.model_of(e, 3, "found") if (e.has("seg") or Hold.PLOTS.has(str(e.get("plot", "")))) else null
			"machine":
				n = Machines.model(str(e.work))
			"prop":
				n = Props.model(str(e.prop), "village") if Props.KINDS.has(str(e.get("prop", ""))) else null
		_foot[key] = footprint(n) if n != null else SMALL
		if n != null:
			n.free()
	return float(_foot[key])

## The ground region `area` keeps clear of scatter, in the tiles of its own view (`r`: the view's rectangle
## in the realm): where anything stands, and the tiles a big thing reaches.
static func stood(wd: Dictionary, area: String, r: Rect2i) -> Dictionary:
	var out := {}
	for e in wd.ents:
		if not e.has("pos") or str(e.get("area", "")) != area or not str(e.kind) in STANDS:
			continue
		var rr := int(REACH.get(str(e.kind), 0))
		for dy in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				out[(e.pos as Vector2i) - r.position + Vector2i(dx, dy)] = true
	for b in Havoc.of_area(wd, area):
		out[(b.tile as Vector2i) - r.position] = true
	if wd.get("camps", {}).has(area):
		var c: Vector2i = wd.camps[area]
		for dy2 in range(-1, 2):
			for dx2 in range(-1, 2):
				out[c - r.position + Vector2i(dx2, dy2)] = true
	return out

## The steps of the story over which entity `e` is in the land: [from, until) as step indices.
static func span(e: Dictionary) -> Array:
	var from := 0
	var until := 1 << 30
	var vis = e.get("vis", ["", ""])
	if vis is Array and (vis as Array).size() >= 2:
		if str(vis[0]) != "":
			from = maxi(0, Data.step_index(str(vis[0])))
		if str(vis[1]) != "":
			until = Data.step_index(str(vis[1])) + 1
	elif vis is String and str(vis) != "":
		from = maxi(0, Data.step_index(str(vis)))
	if str(e.kind) == "boss" and until == 1 << 30:
		# a lord is gone when the step that sends the hero to him is done
		for i in Data.STEPS.size():
			var s: Dictionary = Data.STEPS[i]
			if str(s.kind) in ["kill", "fall"] and "boss_" + str(s.get("boss", "")) == str(e.id):
				until = i + 1
	return [from, until]

static func _overlap(a: Dictionary, b: Dictionary) -> bool:
	var sa := span(a)
	var sb := span(b)
	return int(sa[0]) < int(sb[1]) and int(sb[0]) < int(sa[1])

## Whether two things on one tile are meant to be: the answers of one crossroads share their ground
## (only the one chosen is ever built), a person the story moves has several entries, and a thing to
## find lies where its keeper stands only if the story puts it in their hands.
static func _meant(a: Dictionary, b: Dictionary) -> bool:
	if str(a.kind) == "mark" and str(b.kind) == "mark" and str(a.get("cross", "")) == str(b.get("cross", "")):
		return true
	if bool(a.get("fate", false)) and bool(b.get("fate", false)):
		return true
	if str(a.get("asset", a.id)) == str(b.get("asset", b.id)) and str(a.kind) == "npc" and str(b.kind) == "npc":
		return true
	# (a statue stands on its altar)
	if a.has("furn") and b.has("furn") and (str(a.furn) == "statue" or str(b.furn) == "statue"):
		return true
	return false

# ---------------------------------------------------------------- stepping aside
static var _solved := {}

## Everything among `ents` (the things of one realm, or of one floor) that comes into something else's
## ground: {"nudge": {id: Vector2 metres}, "left": [{what, at, a, b, by}]}.  Remembered by `key`.
static func solve(key: String, ents: Array) -> Dictionary:
	var ck := "%s|%d" % [key, ents.size()]
	if _solved.has(ck):
		return _solved[ck]
	var nudge := {}
	var left: Array = []
	var at := {}
	var stand: Array = []
	for e in ents:
		if e.has("pos") and str(e.kind) in STANDS:
			stand.append(e)
			if not at.has(e.pos):
				at[e.pos] = []
			at[e.pos].append(e)
	for e in stand:
		# two things on one tile
		for o in at[e.pos]:
			if str(o.id) <= str(e.id) or _meant(e, o) or not _overlap(e, o):
				continue
			var small: Dictionary = e if str(e.kind) in STEPS_ASIDE else o
			var big: Dictionary = o if small == e else e
			if str(small.kind) == "pickup" and not str(big.kind) in STEPS_ASIDE:
				var hh := hash(str(small.id)) % 4
				nudge[str(small.id)] = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)][hh] * 0.62
			else:
				left.append({"what": "same", "at": e.pos, "a": str(e.id), "b": str(o.id), "by": 0.0})
		# footprints
		var ra := extent(e)
		if ra <= 1.0:
			continue
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				if dx == 0 and dy == 0:
					continue
				for o in at.get((e.pos as Vector2i) + Vector2i(dx, dy), []):
					if _meant(e, o) or not _overlap(e, o) or (str(e.kind) == "hold" and str(o.kind) == "hold"):
						continue
					var rb := extent(o)
					if rb > ra or (rb == ra and str(o.id) < str(e.id)):
						continue
					var dist := Vector2(dx, dy).length() * Terrain3D.T
					var by := ra + rb - dist
					if by <= SLACK:
						continue
					if str(o.kind) in STEPS_ASIDE and by + 0.06 <= NUDGE_MAX:
						var was: Vector2 = nudge.get(str(o.id), Vector2.ZERO)
						nudge[str(o.id)] = (was + Vector2(dx, dy).normalized() * (by + 0.06)).limit_length(NUDGE_MAX)
					else:
						left.append({"what": "reach", "at": e.pos, "a": str(e.id), "b": str(o.id), "by": by})
	_solved[ck] = {"nudge": nudge, "left": left}
	return _solved[ck]

## How far entity `e` is drawn from the middle of its tile so as to stand clear (metres, x and z).
static func nudge(key: String, ents: Array, e: Dictionary) -> Vector3:
	if not str(e.get("kind", "")) in STEPS_ASIDE:
		return Vector3.ZERO
	var v: Vector2 = solve(key, ents).nudge.get(str(e.get("id", "")), Vector2.ZERO)
	return Vector3(v.x, 0.0, v.y)

## Everything in realm data `wd` that shares ground: [{what, at, a, b}].
static func audit(wd: Dictionary) -> Array:
	var out: Array = (solve(str(wd.get("layer", "")), wd.ents).left as Array).duplicate()
	var W := int(wd.w)
	var at := {}
	var ents: Array = []
	for e in wd.ents:
		if e.has("pos") and str(e.kind) in STANDS:
			ents.append(e)
	for e in ents:
		var p: Vector2i = e.pos
		if not at.has(p):
			at[p] = []
		at[p].append(e)
		var g := int(wd.grid[p.y * W + p.x])
		if (g == MapGen.WATER or g == MapGen.BUILDING) and str(e.kind) in ["npc", "boss", "pickup", "hold", "machine", "stele", "abode"]:
			out.append({"what": "ground", "at": p, "a": str(e.id), "b": str(g)})
	# what breaks, and where the people of the towns stand
	var areas := {}
	for e in ents:
		areas[str(e.get("area", ""))] = true
	for a in areas:
		if a == "" or not Data.AREAS.has(a):
			continue
		for b in Havoc.of_area(wd, a):
			for o in at.get(b.tile, []):
				if not bool(o.get("late", false)):
					out.append({"what": "breaks", "at": b.tile, "a": str(b.id), "b": str(o.id)})
		for fp in Folk.of_area(wd, a):
			for sg in Folk.day_of(wd, fp):
				if str(sg.kind) != "stay" or bool(sg.get("in", false)):
					continue
				var ft := Vector2i(floori((sg.at as Vector2).x), floori((sg.at as Vector2).y))
				for o in at.get(ft, []):
					if str(o.kind) in ["npc", "boss", "prop", "mark", "hold", "machine", "stele", "abode"] and int(span(o)[0]) == 0 and int(span(o)[1]) == 1 << 30 and not bool(o.get("late", false)):
						out.append({"what": "folk", "at": ft, "a": str(fp.id), "b": str(o.id)})
	return out
