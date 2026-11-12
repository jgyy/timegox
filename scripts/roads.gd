class_name Roads
extends RefCounted
## The high roads (the Lost Horse release): a road between the towns, for things on wheels.
##
## Every region had its own paths, laid by its own seed, and they stopped where it stopped: a cart
## bought at Qingshi was driven to Cloudfoot over grass.  Now **the towns of each realm are joined by a
## road** (`of(layer)`): from the middle of every town (Data.TOWNS) to its nearest neighbours, over the
## open ground between, keeping to the paths the regions already have where they go the right way,
## round the peaks, the houses and whatever stands in the land.
##
## **Nothing in the world is moved for it.**  The road is not written into the grid: it is a set of
## tiles kept beside the realm (`tiles`), worked out the first time somebody asks (never when the
## world is built, so no map, pack or peak is anywhere but where it was), which
##   * is **paved** in the land (`mesh`: setts between kerbs, ruts worn along it, a milestone every so
##     often), laid on the ground of each region ag the region is drawn;
##   * is **drawn on the map** (`lines`: town to town);
##   * is **what a carriage is for**: on the road (or any path) a thing on wheels goes `ON_ROAD` times
##     ag fast, and off it `OFF_ROAD` (a horse, a sword or a cloud goes ag it always did);
##   * carries the **post-coach** (`coach_offers`, `ride_coach`): from the counter of a town, for a
##     fare, to any other town of the realm already walked into, if no closed seal stands on the road
##     between.  The hours it takes pass.
##
## The bot owns no carriage and takes no coach: nothing here is asked of the headless run but by the tests.

## how much faster a carriage is on the road, and how much slower off it
const ON_ROAD := 1.3
const OFF_ROAD := 0.85
## what ground costs the road-maker: an old path is cheap, a road already laid cheaper still
const W_PATH := 1.0
const W_OPEN := 2.6
const W_ROAD := 0.55
const W_PEAK := 9.0
const W_THING := 30.0
## the land a road is looked for in: the box of the realm's towns and this much round it
const MARGIN := 48
## a milestone every so many tiles
const MILE := 16
## the coach: what it costs (a base, and so much a tile), and how many seconds of the clock a tile takes
const COACH_BASE := 20.0
const COACH_TILE := 0.35
const COACH_SECS := 0.2

static var _nets := {}

## The road net of realm `layer`: {tiles: {Vector2i: true}, lines: [{a, b, pts: Array[Vector2i]}],
## at: {town id: Vector2i}}.  Worked out once.
static func of(layer: String) -> Dictionary:
	if not _nets.has(layer):
		_nets[layer] = _lay(Atlas.world_of(layer), layer)
	return _nets[layer]

## (for the tests, and when a realm is made again)
static func forget() -> void:
	_nets = {}

static func on(layer: String, tile: Vector2i) -> bool:
	return (of(layer).tiles as Dictionary).has(tile)

## How fast a ride of kind `kind` goes over `tile` of realm data `wd` (a factor of its own speed).
static func pace(wd: Dictionary, kind: String, tile: Vector2i) -> float:
	if kind != "carriage" or wd.get("kind", "") == "floor":
		return 1.0
	var t: int = wd.grid[tile.y * int(wd.w) + tile.x]
	if t == MapGen.PATH or on(str(wd.get("layer", "surface")), tile):
		return ON_ROAD
	return OFF_ROAD

static func _roadable(t: int) -> bool:
	return t == MapGen.FLOOR or t == MapGen.PATH

## The open tile nearest `c` a road can begin on.
static func _foot(wd: Dictionary, c: Vector2i, taken: Dictionary) -> Vector2i:
	var W: int = wd.w
	var H: int = wd.h
	for rad in 24:
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				if maxi(absi(dx), absi(dy)) != rad:
					continue
				var p := c + Vector2i(dx, dy)
				if p.x < 1 or p.y < 1 or p.x >= W - 1 or p.y >= H - 1 or taken.has(p):
					continue
				if _roadable(wd.grid[p.y * W + p.x]):
					return p
	return Vector2i(-1, -1)

static func _lay(wd: Dictionary, layer: String) -> Dictionary:
	var net := {"tiles": {}, "lines": [], "at": {}}
	var towns: Array = []
	for tw in Data.TOWNS:
		if Data.layer_of(str(tw.area)) == layer:
			towns.append(tw)
	if towns.is_empty():
		return net
	var W: int = wd.w
	var H: int = wd.h
	var grid: PackedByteArray = wd.grid
	# what stands in the land (a road goes round it): everything but the packs, which move
	var things := {}
	for e in wd.ents:
		if e.has("pos") and e.kind != "enemy" and e.kind != "seal":
			things[e.pos] = true
	var lo := Vector2i(W, H)
	var hi := Vector2i.ZERO
	for tw in towns:
		var c: Vector2i = _foot(wd, Atlas.to_world(str(tw.area), tw.pos), things)
		if c.x < 0:
			continue
		net.at[str(tw.id)] = c
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var ids: Array = net.at.keys()
	if ids.is_empty():
		return net
	# and a lane out from the road to where travellers arrive in every other region of the realm
	var stops := {}
	for rid in wd.ids:
		if town_of(str(rid)) != "" or str(rid) == "sect":
			continue
		var arr: Array = MapGen.arrival_tiles(str(rid))
		if arr.is_empty():
			continue
		var sp: Vector2i = _foot(wd, Atlas.to_world(str(rid), arr[0]), things)
		if sp.x >= 0:
			stops[str(rid)] = sp
			lo = Vector2i(mini(lo.x, sp.x), mini(lo.y, sp.y))
			hi = Vector2i(maxi(hi.x, sp.x), maxi(hi.y, sp.y))
	var box := Rect2i(Vector2i(maxi(1, lo.x - MARGIN), maxi(1, lo.y - MARGIN)), Vector2i.ZERO)
	box.end = Vector2i(mini(W - 1, hi.x + MARGIN), mini(H - 1, hi.y + MARGIN))
	var ag := AStarGrid2D.new()
	ag.region = box
	ag.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	ag.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	ag.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	ag.update()
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var t: int = grid[y * W + x]
			var p := Vector2i(x, y)
			if not _roadable(t):
				ag.set_point_solid(p, true)
			elif things.has(p):
				ag.set_point_weight_scale(p, W_THING)
			else:
				ag.set_point_weight_scale(p, W_PATH if t == MapGen.PATH else W_OPEN)
	for pk in wd.get("peaks", []):
		var pc: Vector2i = pk.c
		var pr: int = pk.r
		for py in range(pc.y - pr, pc.y + pr + 1):
			for px in range(pc.x - pr, pc.x + pr + 1):
				var pt := Vector2i(px, py)
				if box.has_point(pt) and not ag.is_point_solid(pt):
					var rise := Peaks.rise_of(pk, float(px) + 0.5, float(py) + 0.5)
					if rise > Peaks.STEEP:
						ag.set_point_solid(pt, true)
					elif rise > 0.2:
						ag.set_point_weight_scale(pt, W_PEAK)
	# which towns to join: the least road that joins them all (each to the nearest already joined),
	# and then one more between the two nearest that are not yet neighbours, so that there is a way round
	var joined: Array = [ids[0]]
	var pairs: Array = []
	while joined.size() < ids.size():
		var best: Array = []
		var bd := 1e18
		for a in joined:
			for b in ids:
				if joined.has(b):
					continue
				var dd := Vector2(net.at[a]).distance_to(Vector2(net.at[b]))
				if dd < bd:
					bd = dd
					best = [a, b]
		pairs.append(best)
		joined.append(best[1])
	if ids.size() >= 4:
		var extra: Array = []
		var ed := 1e18
		for i in ids.size():
			for j in i:
				if pairs.any(func(pr): return (pr[0] == ids[i] and pr[1] == ids[j]) or (pr[0] == ids[j] and pr[1] == ids[i])):
					continue
				var d2 := Vector2(net.at[ids[i]]).distance_to(Vector2(net.at[ids[j]]))
				if d2 < ed:
					ed = d2
					extra = [ids[j], ids[i]]
		if not extra.is_empty():
			pairs.append(extra)
	for pr in pairs:
		var path: Array = ag.get_id_path(net.at[pr[0]], net.at[pr[1]])
		if path.size() < 2:
			continue
		for p in path:
			net.tiles[p] = true
			ag.set_point_weight_scale(p, W_ROAD)
		net.lines.append({"a": str(pr[0]), "b": str(pr[1]), "pts": path})
	# the lanes: each region's arrival joined to the nearest thing already on the road (a town, or a
	# region joined before it), the nearest regions first, so that a far one goes by way of a near one
	var hubs := {}
	for id in net.at:
		hubs[id] = net.at[id]
	var left: Array = stops.keys()
	while not left.is_empty():
		var bs := ""
		var bh := ""
		var bdist := 1e18
		for sid in left:
			for hid in hubs:
				var d3 := Vector2(stops[sid]).distance_to(Vector2(hubs[hid]))
				if d3 < bdist:
					bdist = d3
					bs = sid
					bh = hid
		left.erase(bs)
		var lp: Array = ag.get_id_path(hubs[bh], stops[bs])
		if lp.size() < 2:
			continue
		# (a lane ends where it meets a road already laid: the rest of the way is that road)
		var cut := 0
		for k in lp.size():
			if net.tiles.has(lp[k]):
				cut = k
		lp = lp.slice(cut)
		if lp.size() < 2:
			hubs[bs] = stops[bs]
			continue
		for p2 in lp:
			net.tiles[p2] = true
			ag.set_point_weight_scale(p2, W_ROAD)
		net.lines.append({"a": bh, "b": bs, "pts": lp, "lane": true})
		hubs[bs] = stops[bs]
	return net

## The towns the road joins town `id` to, and the way between two towns along it (tiles), or [].
static func neighbours(layer: String, id: String) -> Array:
	var out: Array = []
	for ln in of(layer).lines:
		if ln.get("lane", false):
			continue
		if str(ln.a) == id:
			out.append(str(ln.b))
		elif str(ln.b) == id:
			out.append(str(ln.a))
	return out

static func route(layer: String, a: String, b: String) -> Array:
	var net := of(layer)
	if not net.at.has(a) or not net.at.has(b) or a == b:
		return []
	var prev := {a: ""}
	var q: Array = [a]
	var i := 0
	while i < q.size():
		var c: String = q[i]
		i += 1
		for nb in neighbours(layer, c):
			if not prev.has(nb):
				prev[nb] = c
				q.append(nb)
	if not prev.has(b):
		return []
	var out: Array = []
	var cur := b
	while str(prev[cur]) != "":
		var from := str(prev[cur])
		for ln in net.lines:
			if not ln.get("lane", false) and ((str(ln.a) == from and str(ln.b) == cur) or (str(ln.b) == from and str(ln.a) == cur)):
				var seg: Array = (ln.pts as Array).duplicate()
				if str(ln.a) == from:
					seg.reverse()
				out.append_array(seg)
				break
		cur = from
	out.reverse()
	return out

## The town of region `area`, if it has one ("" if none).
static func town_of(area: String) -> String:
	for tw in Data.TOWNS:
		if str(tw.area) == area:
			return str(tw.id)
	return ""

static func town(id: String) -> Dictionary:
	for tw in Data.TOWNS:
		if str(tw.id) == id:
			return tw
	return {}

static func coach_fare(tiles: int, lv: int) -> int:
	return int(round(COACH_BASE + COACH_TILE * float(tiles) + 2.0 * float(lv)))

## Where the post-coach will take the hero of `g` from region `area`: [{to, n, tiles, fare, hours, at}],
## nearest first.  `shut` are the tiles of the seals that are closed (the caller knows which).
static func coach_offers(g, area: String, shut: Dictionary = {}) -> Array:
	var from := town_of(area)
	var layer := Data.layer_of(area)
	var out: Array = []
	if from == "" or not of(layer).at.has(from):
		return out
	for id in of(layer).at:
		if id == from or not g.seen.has(str(town(id).area)):
			continue
		var way := route(layer, from, id)
		if way.is_empty() or way.any(func(p): return shut.has(p)):
			continue
		out.append({"to": str(id), "n": str(town(id).n), "tiles": way.size(), "fare": coach_fare(way.size(), int(g.level)),
			"hours": snappedf(way.size() * COACH_SECS / 60.0, 0.1), "at": of(layer).at[id]})
	out.sort_custom(func(a, b): return int(a.tiles) < int(b.tiles))
	return out

## The coach is taken: the fare is paid and the hours pass.  Returns where it sets him down
## (Vector2i(-1, -1) if he cannot pay).
static func ride_coach(g, offer: Dictionary) -> Vector2i:
	if offer.is_empty() or g.stones < int(offer.fare):
		return Vector2i(-1, -1)
	g.stones -= int(offer.fare)
	g.coaches += 1
	Clock.advance(g, float(offer.tiles) * COACH_SECS)
	g.note("Took the post-coach to %s (%d spirit stones)" % [str(offer.n), int(offer.fare)])
	return offer.at

## The paving of the road where it crosses rectangle `r` of realm `layer` (tiles), ag a node whose
## origin is the corner of `r`.  `ground` gives the height of the land at a point of the realm (x, z in
## metres from the realm's own corner).  null if no road crosses it.
static func mesh(layer: String, r: Rect2i, ground: Callable) -> Node3D:
	var net := of(layer)
	var b := MB.new()
	var n := 0
	var T := Terrain3D.T
	var sett := MB.tag(Color("9a9082"), MB.STONE)
	var sett2 := MB.tag(Color("8a8174"), MB.STONE)
	var kerb := MB.tag(Color("6e675c"), MB.STONE)
	var rut := MB.tag(Color("7c7366"), MB.STONE)
	var dirt := MB.tag(Color("8a7458"), MB.STONE)
	var dirt2 := MB.tag(Color("7c684e"), MB.STONE)
	var o := Vector3(r.position.x * T, 0.0, r.position.y * T)
	var at := func(x: float, z: float, lift: float) -> Vector3:
		return Vector3(x, float(ground.call(x, z)) + lift, z) - o
	for ln in net.lines:
		var pts: Array = ln.pts
		for i in pts.size():
			var p: Vector2i = pts[i]
			if not r.has_point(p):
				continue
			n += 1
			var x0 := p.x * T
			var z0 := p.y * T
			var hv := Terrain3D.hash2(p.x, p.y, 3.0)
			if ln.get("lane", false):
				# a lane: beaten earth, a little narrower than the tile, and nothing else
				var lm := T * 0.1
				var lc: Color = dirt if hv > 0.45 else dirt2
				b.quad4(at.call(x0 + lm, z0 + lm, 0.05), at.call(x0 + T - lm, z0 + lm, 0.05), at.call(x0 + T - lm, z0 + T - lm, 0.05), at.call(x0 + lm, z0 + T - lm, 0.05), lc, lc, lc, lc)
				continue
			# the high road: a kerb a little wider than the tile, the setts inside it
			var e := T * 0.14
			b.quad4(at.call(x0 - e, z0 - e, 0.05), at.call(x0 + T + e, z0 - e, 0.05), at.call(x0 + T + e, z0 + T + e, 0.05), at.call(x0 - e, z0 + T + e, 0.05), kerb, kerb, kerb, kerb)
			var m := -T * 0.06
			var sc: Color = sett if hv > 0.45 else sett2
			b.quad4(at.call(x0 + m, z0 + m, 0.075), at.call(x0 + T - m, z0 + m, 0.075), at.call(x0 + T - m, z0 + T - m, 0.075), at.call(x0 + m, z0 + T - m, 0.075), sc, sc, sc, sc)
			# the ruts of the wheels, along the way it runs
			var prev: Vector2i = pts[maxi(0, i - 1)]
			var next: Vector2i = pts[mini(pts.size() - 1, i + 1)]
			var dir := next - prev
			if dir.x != 0 and dir.y == 0:
				for k in [0.24, 0.76]:
					b.quad4(at.call(x0, z0 + T * (k - 0.025), 0.09), at.call(x0 + T, z0 + T * (k - 0.025), 0.09), at.call(x0 + T, z0 + T * (k + 0.025), 0.09), at.call(x0, z0 + T * (k + 0.025), 0.09), rut, rut, rut, rut)
			elif dir.y != 0 and dir.x == 0:
				for k2 in [0.24, 0.76]:
					b.quad4(at.call(x0 + T * (k2 - 0.025), z0, 0.09), at.call(x0 + T * (k2 + 0.025), z0, 0.09), at.call(x0 + T * (k2 + 0.025), z0 + T, 0.09), at.call(x0 + T * (k2 - 0.025), z0 + T, 0.09), rut, rut, rut, rut)
			# a milestone on the kerb, every so often: a squared stone with a red-painted cap
			if i % MILE == MILE / 2 and dir.x * dir.y == 0 and dir != Vector2i.ZERO:
				var side := Vector3(T * 0.6, 0, 0) if dir.x == 0 else Vector3(0, 0, T * 0.6)
				var foot: Vector3 = at.call(x0 + T * 0.5 + side.x, z0 + T * 0.5 + side.z, 0.0)
				b.box(foot + Vector3(0, 0.3, 0), Vector3(0.2, 0.6, 0.2), MB.tag(Color("a8a094"), MB.STONE))
				b.box(foot + Vector3(0, 0.63, 0), Vector3(0.24, 0.07, 0.24), MB.tag(Color("a83c30"), MB.STONE))
	if n == 0:
		return null
	var root := Node3D.new()
	root.name = "road"
	var mi := MeshInstance3D.new()
	mi.mesh = b.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return root
