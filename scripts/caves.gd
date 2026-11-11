class_name Caves
extends RefCounted
## The Hollow Hills: real caves under every region of the world (the Hollow Hills release, Part XX).
##
## Somewhere on open ground in every region there is a cave mouth, and under it a cave made of voxels
## (voxel.gd): chambers with roofs of their own, joined by passages that climb, drop and fork; a few
## so low that the hero goes bent; pillars where a stalactite met its stalagmite; shafts open to the
## sky with the daylight coming down them; pools; seams of ore and crystal in the walls; and things
## to do that are done nowhere else (props.gd: swing a pick at a vein, wash in a drip pool, follow a
## painting older than the sect with the fingertips, sidle through a squeeze, pan the gravel of an
## underground stream, hang a lamp where the last miner hung his).
##
## A cave is a small world of its own, like a cellar (atlas.gd `_floor`): its own tiles, its own people
## and things, a mouth to go in by and the same mouth to come out.  It is laid out in tiles first (which
## is all the game's rules, the bot and a server without a screen ever need: `layout`), and only when
## somebody walks in is the rock itself made, four voxels to a tile's side (`volume`, `build`).
## Everything is drawn from the region's own seed: the same cave every time, on every machine.
##
## The caves of the story (Part XX) are the same caves with more in them (OWN): somebody living there,
## something to find, a lord at the bottom, a second gallery below the first.

const T := Terrain3D.T
const V := Voxel.S
const P := Voxel.PER_TILE
## the volume is NY cells tall (27 m); the floor's level 0 is BASE cells up it
const NY := 54
const BASE := 10
## a passage this low or lower (cells) is gone through bent double (the "duck" clip)
const LOW := 4

## how a cave looks, by the theme of the region over it (voxel.gd palette; `kinds`: what is found in it)
const LOOKS := {
	"": {"rock": Color("6e6a66"), "pale": Color("b8b0a0"), "earth": Color("6a563e"), "gem": Color("58c8e8"), "glow": Color("7ae8a0"), "ore": Color("c8923a"), "light": Color(0.55, 0.8, 1.0)},
	"sect": {"rock": Color("6a7078"), "pale": Color("c0c4c8"), "gem": Color("6ab8ff"), "light": Color(0.5, 0.75, 1.0)},
	"mountain": {"rock": Color("70706c"), "gem": Color("6ab8ff")},
	"bamboo": {"rock": Color("5e6a58"), "earth": Color("5a5236"), "glow": Color("a0f070"), "gem": Color("8ae8a0"), "light": Color(0.6, 1.0, 0.6)},
	"marsh": {"rock": Color("4e5648"), "earth": Color("3e3a2a"), "glow": Color("b0e040"), "gem": Color("a8d060"), "light": Color(0.7, 0.9, 0.4)},
	"frost": {"rock": Color("7a8894"), "pale": Color("d8e8f4"), "gem": Color("a8e8ff"), "glow": Color("c8f0ff"), "earth": Color("8a9aa8"), "moss": Color("9ab8c8"), "light": Color(0.7, 0.9, 1.0), "ice": true},
	"thunder": {"rock": Color("5a5868"), "gem": Color("f0e060"), "glow": Color("d0c8ff"), "ore": Color("9a9ab0"), "light": Color(1.0, 0.95, 0.5)},
	"ruins": {"rock": Color("6a6258"), "pale": Color("a89c88"), "gem": Color("b080ff"), "light": Color(0.75, 0.55, 1.0)},
	"volcano": {"rock": Color("5e4a44"), "band": Color("42302c"), "pale": Color("8a6e5e"), "earth": Color("54403a"), "gem": Color("ff8a40"), "glow": Color("ff6a2a"), "ore": Color("d85a2a"), "moss": Color("7a4a2e"), "sand": Color("6a5a50"), "light": Color(1.0, 0.6, 0.3), "ember": true},
	"dunes": {"rock": Color("a88a5e"), "band": Color("8a6a44"), "pale": Color("d8c498"), "earth": Color("b89a68"), "gem": Color("60d8c8"), "moss": Color("8a8a4a"), "light": Color(1.0, 0.85, 0.6)},
	"cloudsea": {"rock": Color("a8b4c4"), "band": Color("8a98b0"), "pale": Color("e8eef8"), "earth": Color("b8c0d0"), "gem": Color("ffe8a0"), "glow": Color("c8e0ff"), "moss": Color("b8d8c8"), "light": Color(0.9, 0.95, 1.0), "jade": true},
	"forge": {"rock": Color("625a56"), "band": Color("463e3a"), "gem": Color("ffb040"), "glow": Color("ff7a30"), "ore": Color("e0a040"), "moss": Color("6a5a3a"), "light": Color(1.0, 0.7, 0.35), "ember": true},
	"jade": {"rock": Color("5a7a6a"), "band": Color("3e5e50"), "pale": Color("b8e0c8"), "gem": Color("80f0b0"), "light": Color(0.5, 1.0, 0.75)},
	"sea": {"rock": Color("54606a"), "pale": Color("c8d0c8"), "earth": Color("a89a78"), "gem": Color("60c8ff"), "glow": Color("60f0e0"), "light": Color(0.4, 0.9, 1.0)},
	"under": {"rock": Color("4e4e60"), "band": Color("36364c"), "pale": Color("8a8aa0"), "earth": Color("46424e"), "gem": Color("9a7aff"), "glow": Color("60ffd0"), "moss": Color("3a6a6a"), "light": Color(0.6, 0.55, 1.0)},
}
## themes that share a look
const LOOK_OF := {"village": "bamboo", "silk": "bamboo", "garden": "bamboo", "maple": "bamboo", "loom": "bamboo", "lake": "marsh", "karst": "marsh", "longmen": "marsh",
	"glacier": "frost", "aurora": "frost", "buzhou": "frost", "storm": "thunder", "tushan": "forge", "yanggu": "volcano", "inferno": "volcano",
	"palace": "jade", "court": "jade", "juntian": "cloudsea", "changhe": "cloudsea", "moon": "cloudsea", "star": "cloudsea",
	"coast": "sea", "reef": "sea", "penglai": "sea", "guixu": "sea", "fusang": "sea", "isles": "sea",
	"ninesprings": "under", "youdu": "under", "abyss": "under", "bridge": "under", "wheel": "under"}

## the names of the caves (one each, in the order of the regions)
const NAME_A := ["Dripstone", "Whispering", "Cold-Lamp", "Swallow", "Stone-Milk", "Echoing", "Hidden-Stream", "Cricket", "Moon-Window", "Sleeping-Bat", "Old-Root", "Blind-Fish", "Salt-Flower"]
const NAME_B := ["Hollow", "Grotto", "Gallery", "Cave", "Sky-Well", "Under-Hall", "Cellar of the Hill"]

## What only a cave of the story has (Part XX), by region.  size: its tiles; rooms: how many chambers;
## n: its name; at: where on the region's own map its mouth should stand (the nearest place that will
## do); things: extra things to do (props.gd kinds), beyond those every cave has; foes: packs [[id,
## lv0, lv1], ...], how many, and the step they appear with; lower: a second gallery under the first,
## reached by a shaft in its deepest chamber (itself a cave: the same keys).
## Who and what the story puts in a cave is written with the region in Data.AREAS, like everybody
## else, with "cave": -1 (or -2, the lower gallery) and "stand": "deep" (the chamber furthest from the
## mouth), "mid", "near" or "any": `world` stands them.
const OWN := {
	# the Bamboo-Root Hollow under the Bamboo Forest: where Xu Xiake is measuring, and the stone-milk drips
	"bamboo": {"n": "Bamboo-Root Hollow", "size": Vector2i(40, 30), "rooms": 7, "at": Vector2i(24, 16),
		"foes": {"pool": [["cave_cricket", 72, 73], ["blind_newt", 72, 73], ["drip_wisp", 72, 73]], "n": 8, "vis": "s_p20_xu"}},
	# Rotten-Axe Cave on the mountain: a weiqi board, and a woodcutter who stopped to watch; and under it
	# the hollow the mountain is built round, where the Valley Spirit is
	"mountain": {"n": "Rotten-Axe Cave", "size": Vector2i(38, 28), "rooms": 6, "at": Vector2i(109, 21), "things": ["cave_weiqi"],
		"foes": {"pool": [["cave_cricket", 72, 73], ["stone_bat", 72, 73]], "n": 4, "vis": "s_p20_delve"},
		"lower": {"n": "The Hollow of the Mountain", "size": Vector2i(40, 30), "rooms": 6, "things": ["cave_painting"],
			"foes": {"pool": [["kept_voice", 73, 74], ["hollow_one", 73, 74]], "n": 8, "vis": "s_p20_wang"}}},
	# the North Mountain diggings above Qingshi: Yu Gong's adit, which has broken into something older
	"village": {"n": "Yu Gong's Adit", "size": Vector2i(42, 30), "rooms": 7, "at": Vector2i(49, 11),
		"foes": {"pool": [["dig_mole", 72, 73], ["blind_newt", 72, 73], ["stone_bat", 72, 73]], "n": 8, "vis": "s_p20_gong"}},
	# the mines of Tushan: the casters' old workings, gone deeper than anybody signed for
	"tushan": {"n": "The Old Workings of Tushan", "size": Vector2i(44, 32), "rooms": 8, "at": Vector2i(54, 50),
		"foes": {"pool": [["ore_gnawer", 73, 74], ["dig_mole", 73, 74], ["lamp_ghost", 73, 74]], "n": 8, "vis": "s_p20_tushan"},
		"lower": {"n": "The Bottomless Gallery", "size": Vector2i(38, 28), "rooms": 5,
			"foes": {"pool": [["ore_gnawer", 73, 74], ["lamp_ghost", 73, 74], ["stone_bat", 73, 74]], "n": 5, "vis": "s_p20_tushan"}}},
	# the karst country: the longest cave Xu Xiake ever measured, and what answers in it
	"karst": {"n": "The Cave of Ten Thousand Echoes", "size": Vector2i(46, 32), "rooms": 8, "at": Vector2i(39, 29),
		"foes": {"pool": [["kept_voice", 73, 74], ["stone_bat", 73, 74], ["drip_wisp", 73, 74]], "n": 8, "vis": "s_p20_karst"}},
}

## the things to do in a cave (props.gd), in the order a cave takes them; a cave has `PER_CAVE` of them
const THINGS := ["ore_vein", "drip_pool", "cave_painting", "glow_shrooms", "crystal", "echo_stone", "squeeze", "stream_bank", "fossil", "dig_spot", "bat_roost", "miner_niche"]
const PER_CAVE := 5

static var _layouts := {}
static var _volumes := {}

static func look_of(theme: String) -> Dictionary:
	var out: Dictionary = (LOOKS[""] as Dictionary).duplicate()
	var key := theme if LOOKS.has(theme) else str(LOOK_OF.get(theme, ""))
	for k in LOOKS.get(key, {}):
		out[k] = LOOKS[key][k]
	return out

## The id of a region's cave as a floor of its realm (level -1), and of its lower gallery (-2).
static func fid(area: String, level: int = -1) -> String:
	return "f:%s:cave:%d" % [area, level]

static func is_cave(wd: Dictionary) -> bool:
	return wd.get("cave", false)

## What a region's cave is: its own entry of OWN (or of its `lower`, for level -2) over what every
## cave has.  Empty if there is no such cave.
static func spec(area: String, level: int = -1) -> Dictionary:
	if not Data.AREAS.has(area):
		return {}
	var own: Dictionary = OWN.get(area, {})
	if level == -2:
		if not own.has("lower"):
			return {}
		own = own.lower
	var a: Dictionary = Data.AREAS[area]
	var idx: int = Data.AREAS.keys().find(area)
	var seed_: int = int(a.get("seed", 7)) * 131 + 977 + (5003 if level == -2 else 0)
	var out := {"area": area, "level": level, "seed": seed_, "theme": str(a.get("theme", "")),
		"n": "%s %s" % [NAME_A[idx % NAME_A.size()], NAME_B[(idx / NAME_A.size() + idx * 3) % NAME_B.size()]],
		"size": Vector2i(38 + (seed_ % 4) * 2, 30 + (seed_ / 7 % 3) * 2), "rooms": 6 + seed_ % 3}
	for k in own:
		out[k] = own[k]
	return out

# ---------------------------------------------------------------- the lay of a cave, in tiles

static func _hash(x: int, y: int, s: int) -> float:
	var n := (x * 374761393) ^ (y * 668265263) ^ (s * 1274126177)
	n = (n ^ (n >> 13)) * 1103515245
	return float((n ^ (n >> 16)) & 0xffff) / 65535.0

## The lay of the cave of `area` (cached): w, h, grid (MapGen tiles: INTERIOR floor, BUILDING rock),
## lv (the floor's level in cells above BASE, per tile), ceil (the roof's height above the floor, in
## cells), room (which chamber a tile belongs to, -1 a passage, -2 rock), water (1 a pool), rooms
## [{c, rx, ry, lv, ceil, far}], entry (the tile of the way out), arrive (where one comes in), spots
## (free-standing places, deepest first: [tile, room]), niches ([tile, facing, room]: places in the
## wall), shafts (rooms open to the sky), down (the tile of the shaft to the lower gallery, if any).
static func layout(area: String, level: int = -1) -> Dictionary:
	var key := fid(area, level)
	if _layouts.has(key):
		return _layouts[key]
	var sp := spec(area, level)
	var w: int = sp.size.x
	var h: int = sp.size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = int(sp.seed)
	var open := PackedByteArray()
	open.resize(w * h)
	var room := PackedInt32Array()
	room.resize(w * h)
	room.fill(-2)
	var rooms: Array = []
	# ---- chambers: the first by the south edge (the mouth is in its south wall), the rest spread out
	var n_rooms: int = int(sp.rooms)
	var first := {"c": Vector2i(clampi(w / 2 + rng.randi_range(-w / 5, w / 5), 6, w - 7), h - 6), "rx": 3.2, "ry": 2.4, "lv": 5, "ceil": 9}
	rooms.append(first)
	var tries := 0
	while rooms.size() < n_rooms and tries < 3000:
		tries += 1
		# (the longer it takes to find room for another chamber, the smaller the chamber looked for)
		var shrink := 1.0 - 0.3 * float(tries) / 3000.0
		var rx := rng.randf_range(3.0, 5.6) * shrink
		var ry := rng.randf_range(2.6, 4.4) * shrink
		var c := Vector2i(rng.randi_range(int(rx) + 3, w - int(rx) - 4), rng.randi_range(int(ry) + 3, h - int(ry) - 5))
		var ok := true
		for r0 in rooms:
			var dd: Vector2 = Vector2(c - (r0.c as Vector2i))
			if absf(dd.x) < rx + float(r0.rx) + 2.0 and absf(dd.y) < ry + float(r0.ry) + 2.0:
				ok = false
				break
		if ok:
			rooms.append({"c": c, "rx": rx, "ry": ry, "lv": 5, "ceil": int(clampf(7.0 + (rx + ry) * 1.6 + rng.randf_range(-1.0, 3.0), 8.0, 22.0))})
	for ri in rooms.size():
		var r: Dictionary = rooms[ri]
		var rc: Vector2i = r.c
		for y in range(int(rc.y - r.ry - 1), int(rc.y + r.ry + 2)):
			for x in range(int(rc.x - r.rx - 1), int(rc.x + r.rx + 2)):
				if x < 2 or y < 2 or x >= w - 2 or y >= h - 2:
					continue
				var ux := (x - rc.x) / float(r.rx)
				var uy := (y - rc.y) / float(r.ry)
				# a warped ellipse: lobes and bays, never a drawn oval
				var warp := 1.0 + 0.3 * (_hash(x, y, int(sp.seed) + ri) - 0.5) + 0.18 * sin(atan2(uy, ux) * 3.0 + ri * 1.7)
				if ux * ux + uy * uy <= warp:
					open[y * w + x] = 1
					room[y * w + x] = ri
	# ---- passages: each chamber joined to the nearest already joined (so every one can be reached),
	# then a loop or two so that there is more than one way round
	var joined := [0]
	var links: Array = []
	while joined.size() < rooms.size():
		var best := [1e9, -1, -1]
		for a in joined:
			for b in rooms.size():
				if joined.has(b):
					continue
				var dl := Vector2((rooms[a].c as Vector2i) - (rooms[b].c as Vector2i)).length()
				if dl < best[0]:
					best = [dl, a, b]
		joined.append(best[2])
		links.append([best[1], best[2]])
	for _k in 1 + rooms.size() / 4:
		var a2 := rng.randi_range(1, rooms.size() - 1)
		var b2 := rng.randi_range(1, rooms.size() - 1)
		if a2 != b2 and not links.has([a2, b2]) and not links.has([b2, a2]):
			links.append([a2, b2])
	var low := PackedByteArray()
	low.resize(w * h)
	var path_of: Array = []
	for ln in links:
		var p: Vector2i = rooms[ln[0]].c
		var q: Vector2i = rooms[ln[1]].c
		var is_low: bool = rng.randf() < 0.3 and int(ln[0]) != 0 and int(ln[1]) != 0
		var path: Array = []
		var guard := 0
		while p != q and guard < 400:
			guard += 1
			var d := q - p
			var step := Vector2i.ZERO
			# mostly towards the other chamber along the longer way, sometimes sideways: it wanders
			if rng.randf() < 0.24:
				step = Vector2i(0, signi(d.y) if d.y != 0 else (1 if rng.randf() < 0.5 else -1)) if absi(d.x) >= absi(d.y) else Vector2i(signi(d.x) if d.x != 0 else (1 if rng.randf() < 0.5 else -1), 0)
			elif absi(d.x) >= absi(d.y):
				step = Vector2i(signi(d.x), 0)
			else:
				step = Vector2i(0, signi(d.y))
			var np := p + step
			if np.x < 2 or np.y < 2 or np.x >= w - 2 or np.y >= h - 3:
				continue
			p = np
			if open[p.y * w + p.x] == 0:
				open[p.y * w + p.x] = 1
				room[p.y * w + p.x] = -1
				if is_low:
					low[p.y * w + p.x] = 1
			path.append(p)
		path_of.append(path)
	# ---- levels: each chamber a little above or below the one it was joined from, the passages
	# sloping between; then smoothed until no two tiles side by side differ by more than one cell
	var lv_of := {0: 5}
	for li in links.size():
		var ln2: Array = links[li]
		if lv_of.has(ln2[1]):
			continue
		var reach: int = clampi((path_of[li] as Array).size() / 2, 1, 6)
		lv_of[ln2[1]] = clampi(int(lv_of.get(ln2[0], 5)) + rng.randi_range(-reach, reach), 0, 12)
	var lv := PackedInt32Array()
	lv.resize(w * h)
	lv.fill(5)
	for i in w * h:
		if room[i] >= 0:
			lv[i] = int(lv_of.get(room[i], 5))
	for li2 in links.size():
		var pa: Array = path_of[li2]
		var l0 := int(lv_of.get(links[li2][0], 5))
		var l1 := int(lv_of.get(links[li2][1], 5))
		for k in pa.size():
			var pt: Vector2i = pa[k]
			if room[pt.y * w + pt.x] == -1:
				lv[pt.y * w + pt.x] = int(round(lerpf(l0, l1, float(k + 1) / float(pa.size() + 1))))
	for _it in 40:
		var moved := false
		for y2 in range(1, h - 1):
			for x2 in range(1, w - 1):
				var i2 := y2 * w + x2
				if open[i2] == 0:
					continue
				for dn in [1, w]:
					var j: int = i2 + dn
					if open[j] == 0:
						continue
					var df: int = lv[i2] - lv[j]
					if df > 1:
						lv[i2] -= 1
						moved = true
					elif df < -1:
						lv[j] -= 1
						moved = true
		if not moved:
			break
	for ri2 in rooms.size():
		rooms[ri2].lv = int(lv_of.get(ri2, 5))
	# ---- roofs: a dome over every chamber (highest over its middle), a low arch over a passage
	var ceil_ := PackedInt32Array()
	ceil_.resize(w * h)
	for y3 in h:
		for x3 in w:
			var i3 := y3 * w + x3
			if open[i3] == 0:
				continue
			if room[i3] >= 0:
				var r3: Dictionary = rooms[room[i3]]
				var u := Vector2((x3 - r3.c.x) / float(r3.rx), (y3 - r3.c.y) / float(r3.ry)).length()
				ceil_[i3] = maxi(7, int(round(float(r3.ceil) * (1.0 - 0.45 * clampf(u, 0.0, 1.0) * clampf(u, 0.0, 1.0)))))
			else:
				ceil_[i3] = LOW if low[i3] == 1 else 6 + int(_hash(x3, y3, int(sp.seed)) * 2.0)
	# ---- the way out: a notch in the south wall of the first chamber
	var arrive: Vector2i = first.c
	while arrive.y + 1 < h - 2 and open[(arrive.y + 1) * w + arrive.x] == 1:
		arrive.y += 1
	var entry := arrive + Vector2i(0, 1)
	# ---- how far each open tile is from the mouth (in steps): the deepest chamber is the furthest
	var dist := _flood(open, w, h, arrive)
	var far_room := 0
	for ri3 in rooms.size():
		var rc3: Vector2i = rooms[ri3].c
		rooms[ri3]["far"] = int(dist.get(rc3, 0))
		if int(rooms[ri3].far) > int(rooms[far_room].far):
			far_room = ri3
	# ---- pools: a few tiles under water at the edge of a chamber or two, where it cuts nothing off
	var water := PackedByteArray()
	water.resize(w * h)
	var n_open := dist.size()
	for ri4 in range(1, rooms.size()):
		if rng.randf() > 0.55 or float(rooms[ri4].rx) < 3.0:
			continue
		var rc4: Vector2i = rooms[ri4].c
		var side := Vector2i(1 if rng.randf() < 0.5 else -1, 0) if rng.randf() < 0.6 else Vector2i(0, -1)
		var seed_t := rc4 + side * int(float(rooms[ri4].rx if side.x != 0 else rooms[ri4].ry) - 1.0)
		var blob: Array = []
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var t := seed_t + Vector2i(dx, dy)
				if t.x > 1 and t.y > 1 and t.x < w - 2 and t.y < h - 2 and room[t.y * w + t.x] == ri4 and _hash(t.x, t.y, 91) < 0.75 and t != rc4:
					blob.append(t)
		if blob.size() < 2:
			continue
		for t2 in blob:
			open[t2.y * w + t2.x] = 0
		if _flood(open, w, h, arrive).size() == n_open - blob.size():
			for t3 in blob:
				water[t3.y * w + t3.x] = 1
			n_open -= blob.size()
		else:
			for t4 in blob:
				open[t4.y * w + t4.x] = 1
	dist = _flood(open, w, h, arrive)
	# ---- places: free-standing ones (all eight tiles round them open, so standing something there
	# closes no way), deepest first; and niches in the walls of the chambers, facing in
	var spots: Array = []
	var niches: Array = []
	for y5 in range(2, h - 2):
		for x5 in range(2, w - 2):
			var i5 := y5 * w + x5
			var t5 := Vector2i(x5, y5)
			if open[i5] == 1 and room[i5] >= 0 and t5 != arrive:
				var all8 := true
				for dy5 in range(-1, 2):
					for dx5 in range(-1, 2):
						if open[(y5 + dy5) * w + x5 + dx5] == 0:
							all8 = false
				if all8 and absi(x5 - arrive.x) + absi(y5 - arrive.y) > 2:
					spots.append([-int(dist.get(t5, 0)), t5, room[i5]])
			elif open[i5] == 0 and water[i5] == 0 and t5 != entry:
				var faces: Array = []
				for d5 in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
					var n5: Vector2i = t5 + d5
					if open[n5.y * w + n5.x] == 1 and room[n5.y * w + n5.x] >= 0:
						faces.append(d5)
				if faces.size() == 1:
					var f5: Vector2i = faces[0]
					niches.append([-int(dist.get(t5 + f5, 0)), t5, f5, room[(t5.y + f5.y) * w + t5.x + f5.x]])
	spots.sort()
	niches.sort()
	# ---- shafts open to the sky (not over the mouth's chamber), and pillars: a free place or two in
	# the bigger chambers filled floor to roof
	var shafts: Array = []
	for ri6 in range(1, rooms.size()):
		# (a gallery under another cave has none: there is a cave over it, not the sky)
		if level == -1 and float(rooms[ri6].rx) >= 3.4 and ri6 != far_room and shafts.size() < 2 and rng.randf() < 0.7:
			shafts.append(ri6)
	var pillars: Array = []
	for s6 in spots:
		var t6: Vector2i = s6[1]
		var r6: int = s6[2]
		if r6 == 0 or float(rooms[r6].rx) < 3.6 or pillars.size() >= 3 or (t6.x * 7 + t6.y * 13 + int(sp.seed)) % 6 != 0 or t6 == (rooms[r6].c as Vector2i):
			continue
		var apart := true
		for p6 in pillars:
			if maxi(absi(p6.x - t6.x), absi(p6.y - t6.y)) < 4:
				apart = false
		if apart:
			pillars.append(t6)
	# flr: the tiles that have a floor and a roof of their own (walked on, under water, or a pillar's)
	var flr := open.duplicate()
	for i7 in w * h:
		if water[i7] == 1:
			flr[i7] = 1
	for p7 in pillars:
		open[p7.y * w + p7.x] = 0
	flr[entry.y * w + entry.x] = 1
	# (the way out stands on a tile of floor, like a flight of stairs)
	open[entry.y * w + entry.x] = 1
	lv[entry.y * w + entry.x] = lv[arrive.y * w + arrive.x]
	ceil_[entry.y * w + entry.x] = 6
	var grid := PackedByteArray()
	grid.resize(w * h)
	for i6 in w * h:
		grid[i6] = MapGen.INTERIOR if open[i6] == 1 else MapGen.BUILDING
	var out := {"w": w, "h": h, "grid": grid, "lv": lv, "ceil": ceil_, "room": room, "water": water, "flr": flr, "rooms": rooms, "entry": entry, "arrive": arrive,
		"spots": spots, "niches": niches, "shafts": shafts, "far_room": far_room, "dist": dist, "seed": int(sp.seed), "pillars": pillars, "alcoves": {}, "down": Vector2i(-1, -1)}
	_layouts[key] = out
	return out

## How many steps each open tile is from `from` (only the tiles that can be reached).
static func _flood(open: PackedByteArray, w: int, h: int, from: Vector2i) -> Dictionary:
	var dist := {from: 0}
	var q: Array = [from]
	var qi := 0
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or open[n.y * w + n.x] == 0 or dist.has(n):
				continue
			dist[n] = int(dist[c]) + 1
			q.append(n)
	return dist

# ---------------------------------------------------------------- a cave as a world of its own

## Take a free-standing place of the lay `lay` for something that fills its tile: the deepest left
## ("deep"), the nearest ("near"), one about half way ("mid") or the next ("any"); places already
## taken, and the tiles round them, are skipped.  Returns the tile, or (-1, -1) when none is left.
static func _take(lay: Dictionary, taken: Dictionary, how: String) -> Vector2i:
	var free: Array = []
	for s in lay.spots:
		var t: Vector2i = s[1]
		var ok := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if taken.has(t + Vector2i(dx, dy)):
					ok = false
		if ok:
			free.append(t)
	if free.is_empty():
		return Vector2i(-1, -1)
	var pick: Vector2i = free[0]
	match how:
		"near":
			pick = free[free.size() - 1]
		"mid":
			pick = free[free.size() / 2]
		"any":
			pick = free[(free.size() * 3 / 10 + taken.size() * 7) % free.size()]
	taken[pick] = true
	return pick

## The cave of `area` (or its lower gallery) as a floor of realm `layer`, with its people and things;
## `mouth` is the tile of the realm the way in stands on (for the lower gallery: the upper cave's own
## offset), and the way in itself is added to `ents` (the realm's, or the upper cave's).
static func world(area: String, layer: String, mouth: Vector2i, ents: Array, level: int = -1, parent_fid: String = "", top_mouth: Vector2i = Vector2i.ZERO) -> Dictionary:
	var sp := spec(area, level)
	var lay := layout(area, level)
	var w: int = lay.w
	var h: int = lay.h
	var id := fid(area, level)
	var grid: PackedByteArray = (lay.grid as PackedByteArray).duplicate()
	var fents: Array = []
	var taken := {lay.arrive: true}
	for pl in lay.pillars:
		taken[pl] = true
	var origin: Vector2i = mouth - (lay.entry as Vector2i)
	var from_layer := layer if level == -1 else parent_fid
	# the way out (and the way in, on the land or in the gallery above)
	fents.append({"kind": "ladder", "id": "cave:%s:%d:back" % [area, level], "n": "Up to the daylight" if level == -1 else "Climb back up", "pos": lay.entry,
		"area": area, "layer": id, "to_layer": from_layer, "to_tile": Vector2i.ZERO, "open": "", "style": "cave_out" if level == -1 else "cave_up", "dir": 1})
	# who and what the story put here
	var here: Dictionary = Data.AREAS[area]
	for n in here.get("npcs", []):
		if int(n.get("cave", 0)) != level:
			continue
		var nt := _take(lay, taken, str(n.get("stand", "any")))
		if nt.x >= 0:
			fents.append({"kind": "npc", "id": n.id, "n": n.n, "pos": nt, "col": n.col, "vis": n.get("vis", ["", ""]), "area": area, "layer": id, "late": true})
	for b in here.get("bosses", []):
		if int(b.get("cave", 0)) != level:
			continue
		var bt := _take(lay, taken, str(b.get("stand", "deep")))
		if bt.x >= 0:
			fents.append({"kind": "boss", "id": "boss_" + str(b.id), "enemy": b.id, "pos": bt, "lv": b.lv, "req": b.req, "vis": b.get("vis", ["", ""]), "area": area, "layer": id, "late": true})
	# a second gallery under this one: a shaft in the floor of the deepest chamber
	if sp.has("lower"):
		var dt := _take(lay, taken, "deep")
		if dt.x >= 0:
			lay.down = dt
			fents.append({"kind": "ladder", "id": "cave:%s:%d:down" % [area, level], "n": "Down to " + str(sp.lower.n), "pos": dt,
				"area": area, "layer": id, "to_layer": fid(area, level - 1), "to_tile": Vector2i.ZERO, "open": "", "style": "cave_down", "dir": -1})
	for pk in here.get("pickups", []):
		if int(pk.get("cave", 0)) != level:
			continue
		var pt := _take(lay, taken, str(pk.get("stand", "any")))
		if pt.x >= 0:
			fents.append({"kind": "pickup", "id": pk.id, "item": pk.item, "pos": pt, "vis": pk.get("vis", ["", ""]), "area": area, "layer": id, "late": true})
	# something left at the very back for whoever comes this far: a cache of spirit stones
	var ct := _take(lay, taken, "deep")
	if ct.x >= 0:
		var lvl: int = 1
		for pe in Data.AREAS[area].get("pool", []):
			lvl = maxi(lvl, int(pe[1]))
		fents.append({"kind": "pickup", "id": "cave_cache:%s:%d" % [area, level], "item": "stones", "n": 30 + lvl * 12, "pos": ct, "vis": ["", ""], "area": area, "layer": id})
	# the things to do: in niches of the walls, facing in, a chamber apart from each other where they can be
	var kinds: Array = (sp.get("things", []) as Array).duplicate()
	var start: int = Data.AREAS.keys().find(area) * 5 + (7 if level == -2 else 0)
	var k0 := 0
	while kinds.size() < PER_CAVE + (sp.get("things", []) as Array).size() and k0 < THINGS.size():
		var kd: String = THINGS[(start + k0) % THINGS.size()]
		k0 += 1
		if not kinds.has(kd):
			kinds.append(kd)
	var used_rooms := {}
	var alcoves := {}
	var ki := 0
	for pass_ in 2:
		for nc in lay.niches:
			if ki >= kinds.size():
				break
			var nt2: Vector2i = nc[1]
			var face: Vector2i = nc[2]
			if alcoves.has(nt2) or taken.has(nt2 + face) or (pass_ == 0 and used_rooms.has(nc[3])):
				continue
			var near_other := false
			for at2 in alcoves:
				if maxi(absi(at2.x - nt2.x), absi(at2.y - nt2.y)) < 3:
					near_other = true
			if near_other or nt2 + face == lay.arrive:
				continue
			used_rooms[nc[3]] = true
			alcoves[nt2] = face
			# (a niche has a floor at the level of the ground before it, and a low roof)
			lay.flr[nt2.y * w + nt2.x] = 1
			lay.lv[nt2.y * w + nt2.x] = lay.lv[(nt2.y + face.y) * w + nt2.x + face.x]
			lay.ceil[nt2.y * w + nt2.x] = 6
			fents.append({"kind": "prop", "id": "cave_thing:%s:%d:%d" % [area, level, ki], "prop": str(kinds[ki]), "pos": nt2, "face": face, "area": area, "layer": id, "cave": true})
			ki += 1
	lay.alcoves = alcoves
	# what lives here: packs on free ground in the chambers beyond the first
	var foes: Dictionary = sp.get("foes", {})
	if foes.is_empty() and level == -1:
		var pool: Array = Data.AREAS[area].get("pool", [])
		if not pool.is_empty():
			foes = {"pool": pool, "n": 3, "vis": ""}
	if not foes.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = int(sp.seed) * 31 + 5
		for fi in int(foes.n):
			var ft := _take(lay, taken, "any")
			if ft.x < 0:
				break
			var group: Array = []
			for _g in rng.randi_range(2, 3):
				var pe2: Array = foes.pool[rng.randi() % (foes.pool as Array).size()]
				group.append({"id": pe2[0], "lv": rng.randi_range(int(pe2[1]), int(pe2[2]))})
			fents.append({"kind": "enemy", "id": "cave:%s:%d:e%d" % [area, level, fi], "pos": ft, "group": group, "vis": [str(foes.get("vis", "")), ""], "area": area, "layer": id, "late": true})
	var owner := PackedByteArray()
	owner.resize(w * h)
	return {"layer": id, "kind": "floor", "cave": true, "parent": layer, "up": from_layer, "bld": "cave", "bld_n": str(sp.n), "floor_n": "", "level": level, "area": area,
		"w": w, "h": h, "origin": origin, "realm_mouth": mouth if level == -1 else top_mouth, "grid": grid, "owner": owner, "sea": PackedByteArray(), "ids": [area], "idx": {area: 0},
		"ents": fents, "buildings": [], "start": lay.arrive, "floors": {}, "y": 0.0, "props": [], "stairs": lay.entry, "style": "cave"}

## Stand a cave mouth in every region of realm `layer` and add the caves under them to `floors`.  A
## mouth stands on open ground of its region that can be reached (`reach`), six tiles from anybody and
## anything, with open ground on all eight sides (it closes no way) and three tiles of it to the south,
## where the way in is: a seeded draw, so the same every time; a cave of the story stands as near its
## `at` (a tile of the region's own map) as it can.
static func place(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, ids: Array, ents: Array, layer: String, reach: Dictionary, floors: Dictionary) -> void:
	var near := {}
	for e in ents:
		if e.kind == "seal":
			for st in e.tiles:
				for dy0 in range(-3, 4):
					for dx0 in range(-3, 4):
						near[st + Vector2i(dx0, dy0)] = true
			continue
		if not e.has("pos"):
			continue
		var rr := 3 if e.kind in ["enemy", "prop", "spring"] else 5
		for dy in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				near[e.pos + Vector2i(dx, dy)] = true
	var by_region := {}
	for p in reach:
		if near.has(p) or p.x < 2 or p.y < 2 or p.x >= W - 2 or p.y >= H - 4:
			continue
		var g: int = grid[p.y * W + p.x]
		if g != MapGen.FLOOR and g != MapGen.DECOR:
			continue
		var ok := true
		for dy2 in range(-1, 4):
			for dx2 in range(-1, 2):
				var g2: int = grid[(p.y + dy2) * W + p.x + dx2]
				if g2 != MapGen.FLOOR and g2 != MapGen.DECOR and g2 != MapGen.PATH:
					ok = false
		if not ok:
			continue
		var o: int = owner[p.y * W + p.x]
		if not by_region.has(o):
			by_region[o] = []
		by_region[o].append(p)
	for k in ids.size():
		var area: String = ids[k]
		var cands: Array = by_region.get(k, [])
		if cands.is_empty() or spec(area).is_empty():
			continue
		cands.sort()
		var sp := spec(area)
		var mouth: Vector2i = cands[(int(sp.seed) * 7919) % cands.size()]
		if sp.has("at"):
			var want := Atlas.to_world(area, sp.at)
			var bd := 1 << 30
			for c in cands:
				var dd: int = (c - want).length_squared()
				if dd < bd:
					bd = dd
					mouth = c
		var fw := world(area, layer, mouth, ents)
		var lay := layout(area)
		fw.ents[0].to_tile = mouth + Vector2i(0, 1)
		ents.append({"kind": "ladder", "id": "cave:%s" % area, "n": "Into " + str(sp.n), "pos": mouth, "area": area, "layer": layer,
			"to_layer": fw.layer, "to_tile": lay.arrive, "open": "", "style": "cave", "dir": -1, "theme": str(sp.theme)})
		floors[fw.layer] = fw
		if sp.has("lower"):
			var fw2 := world(area, layer, (fw.origin as Vector2i) + (lay.down as Vector2i), ents, -2, str(fw.layer), mouth)
			fw2.ents[0].to_tile = (lay.down as Vector2i) + Vector2i(0, 1)
			for e2 in fw.ents:
				if str(e2.id) == "cave:%s:-1:down" % area:
					e2.to_tile = layout(area, -2).arrive
			floors[fw2.layer] = fw2

# ---------------------------------------------------------------- the rock itself, in voxels

## The floor's level under a point of a cave (in the cave's own tiles, fractional), in cells: the
## levels of the four tiles round it, blended, so that a slope is a flight of half-metre steps.
static func _level(lay: Dictionary, fx: float, fz: float) -> float:
	var w: int = lay.w
	var h: int = lay.h
	var gx := fx - 0.5
	var gz := fz - 0.5
	var x0 := clampi(int(floor(gx)), 0, w - 2)
	var z0 := clampi(int(floor(gz)), 0, h - 2)
	var tx := clampf(gx - x0, 0.0, 1.0)
	var tz := clampf(gz - z0, 0.0, 1.0)
	var lv: PackedInt32Array = lay.lv
	var flr: PackedByteArray = lay.flr
	var sum := 0.0
	var wt := 0.0
	for k in 4:
		var i := (z0 + (k >> 1)) * w + x0 + (k & 1)
		if flr[i] == 1:
			var wk := (tx if (k & 1) == 1 else 1.0 - tx) * (tz if (k >> 1) == 1 else 1.0 - tz)
			sum += float(lv[i]) * wk
			wt += wk
	return sum / wt if wt > 0.0 else 5.0

## The height of the cave's floor (metres above the bottom of its volume) under a point of it (metres
## from its corner): where someone walking there stands.
static func floor_y(lay: Dictionary, x: float, z: float) -> float:
	return (BASE + int(round(_level(lay, x / T, z / T)))) * V

## The roof over a point of the cave, in cells above the floor (the hero bends under a low one).
static func headroom(lay: Dictionary, tile: Vector2i) -> int:
	if tile.x < 0 or tile.y < 0 or tile.x >= int(lay.w) or tile.y >= int(lay.h):
		return 99
	var c: int = lay.ceil[tile.y * int(lay.w) + tile.x]
	return c if c > 0 else 99

## The volume of the cave of `area` (cached while it is the one being walked in; `drop` forgets it).
static func volume(area: String, level: int = -1) -> Dictionary:
	var key := fid(area, level)
	if _volumes.has(key):
		return _volumes[key]
	var lay := layout(area, level)
	var sp := spec(area, level)
	var lk := look_of(str(sp.theme))
	var w: int = lay.w
	var h: int = lay.h
	var nx := w * P
	var nz := h * P
	var vol := Voxel.make(nx, NY, nz)
	var d: PackedByteArray = vol.d
	var lo: PackedInt32Array = vol.lo
	var hi: PackedInt32Array = vol.hi
	var ceil_: PackedInt32Array = lay.ceil
	var water: PackedByteArray = lay.water
	var seed_: int = lay.seed
	var noise := FastNoiseLite.new()
	noise.seed = seed_
	noise.frequency = 0.09
	noise.fractal_octaves = 2
	# strata: the rock lies in courses, tilted a little, a darker one every few cells
	for z in nz:
		for x in nx:
			var base := (z * nx + x) * NY
			var tilt := int(float(x) * 0.07 + float(z) * 0.04 + noise.get_noise_2d(x * 0.5, z * 0.5) * 2.0)
			for y in NY:
				if ((y + tilt) % 7) >= 5:
					d[base + y] = Voxel.BAND + 1
	# how open each tile is (1 walked on or a niche or the notch of the way out, 0 rock), and its roof
	var op := PackedFloat32Array()
	op.resize(w * h)
	var cl := PackedFloat32Array()
	cl.resize(w * h)
	for ty in h:
		for tx in w:
			var i := ty * w + tx
			if lay.flr[i] == 1:
				op[i] = 1.0
				cl[i] = float(ceil_[i]) if ceil_[i] > 0 else 8.0
	var fl_cache := PackedInt32Array()
	fl_cache.resize(nx * nz)
	for z2 in nz:
		var fz := (z2 + 0.5) / P
		for x2 in nx:
			var fx := (x2 + 0.5) / P
			# openness and roof, blended between the four tiles round the column
			var gx := fx - 0.5
			var gz := fz - 0.5
			var x0 := clampi(int(floor(gx)), 0, w - 2)
			var z0 := clampi(int(floor(gz)), 0, h - 2)
			var ax := clampf(gx - x0, 0.0, 1.0)
			var az := clampf(gz - z0, 0.0, 1.0)
			var i00 := z0 * w + x0
			var o := lerpf(lerpf(op[i00], op[i00 + 1], ax), lerpf(op[i00 + w], op[i00 + w + 1], ax), az)
			var nv := noise.get_noise_2d(x2, z2)
			if o + nv * 0.16 < 0.5:
				continue
			var cw := 0.0
			var cs := 0.0
			for k in 4:
				var ii := i00 + (k & 1) + (k >> 1) * w
				if op[ii] > 0.0:
					var wk := (ax if (k & 1) == 1 else 1.0 - ax) * (az if (k >> 1) == 1 else 1.0 - az)
					cw += wk
					cs += cl[ii] * wk
			var roof := cs / maxf(cw, 0.001)
			# the walls lean in towards the roof: near the edge of the open the roof comes down
			roof *= clampf((o + nv * 0.16 - 0.5) * 3.2 + 0.42, 0.42, 1.0)
			var fl := BASE + int(round(_level(lay, fx, fz)))
			var tile := Vector2i(int(fx), int(fz))
			var wet: bool = water[tile.y * w + tile.x] == 1
			if wet:
				fl -= 2
			var top := fl + maxi(int(round(roof + nv * 1.6 + noise.get_noise_2d(x2 * 3.1 + 40.0, z2 * 3.1) * 1.2)), LOW if ceil_[tile.y * w + tile.x] == LOW else 5)
			top = mini(top, NY - 2)
			var c := z2 * nx + x2
			var b2 := c * NY
			for y2 in range(fl, top):
				d[b2 + y2] = 0
			lo[c] = fl
			hi[c] = top
			fl_cache[c] = fl
			# what the floor is: trodden earth in the passages and the middles, sand under water, moss by it
			var fm := Voxel.EARTH if noise.get_noise_2d(x2 * 2.0 + 9.0, z2 * 2.0) > -0.25 else -1
			if wet:
				fm = Voxel.SAND
			elif lk.get("ice", false) and noise.get_noise_2d(x2 * 1.3, z2 * 1.3 + 70.0) > 0.2:
				fm = Voxel.ICE
			elif lk.get("jade", false):
				fm = Voxel.JADE if fm == Voxel.EARTH else -1
			if fm >= 0 and fl > 0:
				d[b2 + fl - 1] = fm + 1
	vol.d = d
	vol.lo = lo
	vol.hi = hi
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 7 + 3
	# ---- the way out: a ramp of steps up through the south wall, towards the daylight
	var et: Vector2i = lay.entry
	for sx in P:
		for sz in P * 2:
			var cx := et.x * P + sx
			var cz := et.y * P + sz
			if cz >= nz:
				continue
			var fl2 := BASE + int(lay.lv[(et.y - 1) * w + et.x]) + sz / 2
			Voxel.fill(vol, cx, cz, 0, fl2, Voxel.ROCK)
			Voxel.carve(vol, cx, cz, fl2, mini(fl2 + 6, NY - 1))
			# (the last cells of it are the daylight itself, on the gallery under the land; on the one
			# below, the dark the rope hangs in)
			if sz == P * 2 - 1 and cz + 1 < nz:
				Voxel.fill(vol, cx, cz + 1, fl2, mini(fl2 + 6, NY - 1), Voxel.DAY if int(sp.level) == -1 else Voxel.COAL)
	# ---- shafts open to the sky over the middle of a chamber
	for ri in lay.shafts:
		var r: Dictionary = lay.rooms[ri]
		var sc := Vector2i(r.c.x * P + 2, r.c.y * P + 2)
		for dz in range(-3, 4):
			for dx in range(-3, 4):
				if dx * dx + dz * dz <= 7 + int(_hash(dx, dz, seed_) * 3.0):
					var cc := (sc.y + dz) * nx + sc.x + dx
					if sc.x + dx > 0 and sc.y + dz > 0 and sc.x + dx < nx and sc.y + dz < nz and vol.hi[cc] > vol.lo[cc]:
						Voxel.carve(vol, sc.x + dx, sc.y + dz, vol.hi[cc], NY)
	# ---- dripstone: stalactites from the roof anywhere, stalagmites from the floor off the trodden
	# way (the corners of tiles and the niches' edges), pillars where the two met
	var n_drip := (nx * nz) / 46
	for _k in n_drip:
		var x3 := rng.randi_range(2, nx - 3)
		var z3 := rng.randi_range(2, nz - 3)
		var c3 := z3 * nx + x3
		if vol.hi[c3] <= vol.lo[c3] or vol.hi[c3] >= NY - 1:
			continue
		var room_h: int = vol.hi[c3] - vol.lo[c3]
		var len := rng.randi_range(1, maxi(1, mini(room_h - 6, 7)))
		if room_h - len < 5:
			len = maxi(0, room_h - 5)
		if len > 0:
			Voxel.fill(vol, x3, z3, vol.hi[c3] - len, vol.hi[c3], Voxel.PALE)
			if len >= 4:
				for dd in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
					var c4: int = (z3 + int(dd.y)) * nx + x3 + int(dd.x)
					if vol.hi[c4] > vol.lo[c4] and vol.hi[c4] < NY - 1:
						Voxel.fill(vol, x3 + dd.x, z3 + dd.y, vol.hi[c4] - len / 2, vol.hi[c4], Voxel.PALE)
		# a stalagmite under it, if nobody walks there: off the middle of its tile
		var sub := Vector2i(x3 % P, z3 % P)
		var edge := sub.x == 0 or sub.y == 0 or sub.x == P - 1 or sub.y == P - 1
		var tile3 := Vector2i(x3 / P, z3 / P)
		if edge and rng.randf() < 0.45 and lay.water[tile3.y * w + tile3.x] == 0 and lay.ceil[tile3.y * w + tile3.x] > 7 and not _on_way(lay, tile3):
			Voxel.fill(vol, x3, z3, vol.lo[c3], vol.lo[c3] + rng.randi_range(1, 3), Voxel.PALE)
	for pt in lay.pillars:
		_pillar(vol, pt, rng)
	# ---- veins and growths: a seam of ore round an ore niche, crystal in the walls, glow-moss on roofs
	for at in lay.alcoves:
		var cxa: int = at.x * P + 2
		var cza: int = at.y * P + 2
		for _j in 26:
			var vx := cxa + rng.randi_range(-4, 4)
			var vz := cza + rng.randi_range(-4, 4)
			var vy := BASE + int(lay.lv[at.y * w + at.x]) + rng.randi_range(0, 7)
			Voxel.paint(vol, vx, vz, vy, vy + rng.randi_range(1, 2), Voxel.ORE if (at.x + at.y) % 2 == 0 else Voxel.GEM)
	var n_glow := (nx * nz) / 30
	for _g in n_glow:
		var x5 := rng.randi_range(1, nx - 2)
		var z5 := rng.randi_range(1, nz - 2)
		var c5 := z5 * nx + x5
		if vol.hi[c5] > vol.lo[c5] and vol.hi[c5] < NY - 1:
			var what := Voxel.GLOW if rng.randf() < 0.7 else Voxel.GEM
			if lk.get("ember", false):
				what = Voxel.EMBER if rng.randf() < 0.5 else Voxel.COAL
			elif lk.get("ice", false):
				what = Voxel.ICE
			if rng.randf() < 0.5:
				Voxel.paint(vol, x5, z5, vol.hi[c5], vol.hi[c5] + 1, what)
			else:
				# low on a wall: the first solid cell beside the air at knee height
				for dd2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var c6: int = (z5 + int(dd2.y)) * nx + x5 + int(dd2.x)
					if vol.hi[c6] <= vol.lo[c6]:
						Voxel.paint(vol, x5 + dd2.x, z5 + dd2.y, vol.lo[c5] + 1, vol.lo[c5] + rng.randi_range(2, 4), what if what != Voxel.GLOW else Voxel.MOSS)
						break
	# moss and sand round the pools
	for ty2 in h:
		for tx2 in w:
			if water[ty2 * w + tx2] == 1:
				for mz in range(-2, P + 2):
					for mx in range(-2, P + 2):
						var cx2 := tx2 * P + mx
						var cz2 := ty2 * P + mz
						if cx2 > 0 and cz2 > 0 and cx2 < nx and cz2 < nz:
							var c7 := cz2 * nx + cx2
							if vol.hi[c7] > vol.lo[c7] and vol.lo[c7] > 0:
								Voxel.paint(vol, cx2, cz2, vol.lo[c7] - 1, vol.lo[c7], Voxel.MOSS if water[(cz2 / P) * w + cx2 / P] == 0 else Voxel.SAND)
	# the shaft to the gallery below: a hole in the floor with a rim of pale stone
	if lay.down.x >= 0:
		var dc := Vector2i(lay.down.x * P + 2, lay.down.y * P + 2)
		for dz2 in range(-2, 2):
			for dx2 in range(-2, 2):
				var c8 := (dc.y + dz2) * nx + dc.x + dx2
				var rim := dx2 == -2 or dz2 == -2 or dx2 == 1 or dz2 == 1
				if rim:
					Voxel.fill(vol, dc.x + dx2, dc.y + dz2, vol.lo[c8], vol.lo[c8] + 1, Voxel.PALE)
				else:
					Voxel.carve(vol, dc.x + dx2, dc.y + dz2, 1, vol.lo[c8])
					Voxel.paint(vol, dc.x + dx2, dc.y + dz2, 0, 1, Voxel.COAL)
	_volumes.clear()
	_volumes[key] = vol
	return vol

## Is tile `t` one that a passage runs through, or the tile people arrive on (so nothing grows there)?
static func _on_way(lay: Dictionary, t: Vector2i) -> bool:
	return lay.room[t.y * int(lay.w) + t.x] == -1 or t == lay.arrive

static func _pillar(vol: Dictionary, t: Vector2i, rng: RandomNumberGenerator) -> void:
	var cx := t.x * P + 2
	var cz := t.y * P + 2
	for dz in range(-2, 2):
		for dx in range(-2, 2):
			var c := (cz + dz) * int(vol.nx) + cx + dx
			if vol.hi[c] <= vol.lo[c]:
				continue
			var corner := (dx == -2 or dx == 1) and (dz == -2 or dz == 1)
			if corner:
				# thick at foot and head, waisted between
				Voxel.fill(vol, cx + dx, cz + dz, vol.lo[c], vol.lo[c] + rng.randi_range(1, 3), Voxel.PALE)
				Voxel.fill(vol, cx + dx, cz + dz, vol.hi[c] - rng.randi_range(1, 3), vol.hi[c], Voxel.PALE)
			else:
				Voxel.fill(vol, cx + dx, cz + dz, vol.lo[c], vol.hi[c], Voxel.PALE)

static func drop() -> void:
	_volumes.clear()

# ---------------------------------------------------------------- drawing a cave

## Build cave world `fw` under `root` (the corner of its tiles, the bottom of its volume): the rock,
## the water of its pools, the daylight in its shafts and its mouth, and lights.
static func build(root: Node3D, fw: Dictionary) -> void:
	var area: String = fw.area
	var level: int = fw.level
	var lay := layout(area, level)
	var sp := spec(area, level)
	var lk := look_of(str(sp.theme))
	var t0 := Time.get_ticks_usec()
	var vol := volume(area, level)
	var t1 := Time.get_ticks_usec()
	# (in pieces of six tiles a side: the renderer lights a mesh with its eight nearest lamps and no more)
	var pal := Voxel.palette(lk)
	var faces := 0
	var cn := 6 * P
	for cz in range(0, int(vol.nz), cn):
		for cx in range(0, int(vol.nx), cn):
			var res := Voxel.mesh(vol, pal, null, Rect2i(cx, cz, cn, cn))
			if res.mesh != null:
				var mi := MB.mesh_node(root, res.mesh)
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				faces += int(res.faces)
	root.set_meta("faces", faces)
	if OS.has_environment("AZ_PROFILE"):
		print("[profile] cave %s: volume %d ms, mesh %d ms, %d faces" % [fw.layer, (t1 - t0) / 1000, (Time.get_ticks_usec() - t1) / 1000, faces])
	var w: int = lay.w
	var h: int = lay.h
	var g := MB.new()
	var lights: Array = []
	var light_col: Color = lk.light
	# pools: still water a little under the floor, glowing faintly from below
	var wcol: Color = Color(lk.gem).lerp(Color(0.1, 0.3, 0.4), 0.6)
	for ty in h:
		for tx in w:
			if lay.water[ty * w + tx] == 1:
				var wy := (BASE + int(lay.lv[ty * w + tx])) * V - 0.35
				g.quad(tx * T - 0.6, ty * T - 0.6, (tx + 1) * T + 0.6, (ty + 1) * T + 0.6, wy, Color(wcol.r, wcol.g, wcol.b, 0.5))
				if (tx + ty) % 3 == 0:
					lights.append([Vector3((tx + 0.5) * T, wy + 0.6, (ty + 0.5) * T), light_col, 0.7, 6.0])
	# daylight: down every shaft, and in at the mouth
	var day := Color(1.0, 0.95, 0.8)
	for ri in lay.shafts:
		var r: Dictionary = lay.rooms[ri]
		var c := Vector3((r.c.x + 0.6) * T, 0, (r.c.y + 0.6) * T)
		var fy := floor_y(lay, c.x, c.z)
		g.cyl(Vector3(c.x, fy + (NY * V - fy) * 0.5, c.z), 1.15, NY * V - fy, Color(day.r, day.g, day.b, 0.07), Vector3.ZERO, 12)
		g.disc(Vector3(c.x, fy + 0.06, c.z), 1.5, Color(day.r, day.g, day.b, 0.22), 16, Color(day.r, day.g, day.b, 0.0))
		g.disc(Vector3(c.x, NY * V - 0.2, c.z), 1.7, Color(0.75, 0.88, 1.0, 0.95), 12, Color(0.75, 0.88, 1.0, 0.5), Vector3(PI, 0, 0))
		lights.append([Vector3(c.x, fy + 3.0, c.z), day, 1.6, 11.0])
	var ec := Vector3((lay.entry.x + 0.5) * T, 0, (lay.entry.y + 2.0) * T - 0.3)
	var ey := floor_y(lay, ec.x, (lay.arrive.y + 0.5) * T)
	if level == -1:
		lights.append([Vector3(ec.x, ey + 2.4, ec.z - 2.6), day, 1.4, 9.0])
	else:
		# a rope down from the gallery above, in a faint light
		g.cyl(Vector3(ec.x, ey + 4.0, ec.z - 2.4), 0.04, 8.0, Color(0.85, 0.75, 0.5, 0.9), Vector3.ZERO, 5)
		lights.append([Vector3(ec.x, ey + 2.4, ec.z - 2.6), light_col, 1.0, 8.0])
	# a glow in every chamber (the crystal and the moss light it), stronger in the deepest
	for ri2 in lay.rooms.size():
		var r2: Dictionary = lay.rooms[ri2]
		var c2 := Vector3((r2.c.x + 0.5) * T, 0, (r2.c.y + 0.5) * T)
		lights.append([Vector3(c2.x, floor_y(lay, c2.x, c2.z) + minf(float(r2.ceil) * V * 0.6, 3.2), c2.z), light_col, 1.3 if ri2 != int(lay.far_room) else 1.9, 7.0 + float(r2.rx) * 2.6])
	# the shaft down glows from below
	if lay.down.x >= 0:
		lights.append([Vector3((lay.down.x + 0.5) * T, floor_y(lay, (lay.down.x + 0.5) * T, (lay.down.y + 0.5) * T) - 0.5, (lay.down.y + 0.5) * T), light_col, 1.2, 5.0])
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if DisplayServer.get_name() != "headless":
		for lt in lights:
			var l := OmniLight3D.new()
			l.light_color = lt[1]
			l.light_energy = lt[2]
			l.omni_range = lt[3]
			l.omni_attenuation = 1.3
			l.position = lt[0]
			root.add_child(l)

## The air in a cave: dark, cool and a little blue, with a mist that hides the far end of a chamber.
static func environment(theme: String) -> Environment:
	var lk := look_of(theme)
	var lc: Color = lk.light
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.01, 0.014)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.62).lerp(lc, 0.35)
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.03, 0.045).lerp(lc * 0.08, 0.5)
	env.fog_density = 0.028
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.1
	return env

## A cave's own map for the corner of the screen: rock dark, floor pale, water blue.
static func minimap(fw: Dictionary) -> ImageTexture:
	var lay := layout(str(fw.area), int(fw.level))
	var w: int = lay.w
	var h: int = lay.h
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var i := y * w + x
			var c := Color(0.07, 0.07, 0.09)
			if lay.water[i] == 1:
				c = Color(0.16, 0.38, 0.52)
			elif lay.grid[i] == MapGen.INTERIOR:
				c = Color(0.5, 0.46, 0.4).lerp(Color(0.78, 0.74, 0.66), clampf(float(lay.lv[i]) / 12.0, 0.0, 1.0))
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

# ---------------------------------------------------------------- the mouth of a cave, on the land

## The mouth of a cave as it stands on the land: a shoulder of the region's own rock, in voxels, with
## a dark way in on its south face and a breath of the cave's light in it.
static func mouth_model(theme: String) -> Node3D:
	var root := Node3D.new()
	var lk := look_of(theme)
	var cells: Array = []
	for z in range(-4, 4):
		for x in range(-5, 5):
			var r := Vector2(x + 0.5, (z + 0.5) * 1.2).length()
			var top := int(round(6.2 - r * 1.05 + _hash(x, z, 17) * 1.4))
			for y in maxi(top, 0):
				# the way in: a slot two cells wide through the south face, four high
				if x >= -1 and x <= 0 and z >= -1 and y < 4:
					continue
				var m := Voxel.ROCK
				if (y + x / 3) % 4 == 3:
					m = Voxel.BAND
				if y == top - 1 and _hash(x, z, 3) < 0.45:
					m = Voxel.MOSS
				cells.append([Vector3i(x, y, z), m])
	# the dark inside, and a sill
	for x2 in range(-1, 1):
		cells.append([Vector3i(x2, 0, -2), Voxel.COAL])
		cells.append([Vector3i(x2, 1, -2), Voxel.COAL])
		cells.append([Vector3i(x2, 2, -2), Voxel.COAL])
		cells.append([Vector3i(x2, 3, -2), Voxel.COAL])
	var mi := Voxel.model(cells, Voxel.palette(lk), MB.mat_plain())
	root.add_child(mi)
	var g := MB.new()
	var lc: Color = lk.light
	g.quad4(Vector3(-0.5, 0.05, 2.0), Vector3(0.5, 0.05, 2.0), Vector3(0.5, 1.9, -0.4), Vector3(-0.5, 1.9, -0.4), Color(lc.r, lc.g, lc.b, 0.0), Color(lc.r, lc.g, lc.b, 0.0), Color(lc.r, lc.g, lc.b, 0.3), Color(lc.r, lc.g, lc.b, 0.3))
	MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

## How many tiles of floor all the caves of the world have (for the tests and the README).
static func total_tiles() -> int:
	var n := 0
	for area in Data.AREAS:
		for level in [-1, -2]:
			if spec(area, level).is_empty():
				continue
			var lay := layout(area, level)
			for i in int(lay.w) * int(lay.h):
				if lay.grid[i] == MapGen.INTERIOR:
					n += 1
	return n
