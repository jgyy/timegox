class_name Sunder
extends RefCounted
## The Small Fish release: what a blow does to the land grows with the realm of whoever strikes it.
##
## Until this release the sword (F) reached the same four tiles at Qi Condensation and at the last realm
## there is (impact.gd).  Now a blow has a **weight**, seven of them (`RANKS`), by the great realm he has
## reached (`might`): the edge of a blade cuts what is in front of it; a felling stroke takes the tree
## behind that one too; a cleaving stroke opens a lane; at Nascent Soul the stone under the trees breaks
## and the ground cracks; at Void Refinement the blow is five tiles wide; and a True Immortal who strikes
## in earnest parts a wood eight tiles deep and leaves a crater where he stood.
##
## What is broken is **state, and it is drawn only**: `Game.scars` (a tile -> what was done to it and on
## what day), read from the grid and the height field alone (`what`), so the bot and the tests break the
## same land without drawing it.  **No tile changes**: a felled wood is still a wood nobody walks
## through (stumps and trunks bar the way as well as trees did), a crater is a hollow in the drawing and
## the ground under it is as high as it was.  So nothing here is a way round the story, no map moves,
## and a scar mends by itself (`MEND` days lived: the land of a cultivation world mends quickly, a
## crater less quickly than a tree).
##
## And because he can, he need not: **H** changes how hard he means to strike (`Game.hand`: no harder
## than rank so-and-so; -1 is all he has).  The story asks for both: a step of kind `"sunder"` counts
## the things broken since it began (`n`), or, with `"max"`, the *blows* that broke something and no
## more than `max` things (the hand held back: the lesson of Part XXXVI).
##
## The people of the first reach (packs struck first, obstacles of the story, the things people leave
## about) are struck exactly as they always were (`Impact.reach`): only the land answers the rest.

## rank -> what such a blow is called, how many tiles deep it goes, how far to either side, whether the
## rock breaks, whether the open ground cracks, and whether it leaves a crater
const RANKS := [
	{"n": "a single cut", "deep": 1, "wide": 0, "rock": false, "ground": false, "crater": false, "said": "One thing, and nothing behind it. Nobody strikes this lightly by accident."},
	{"n": "the edge of a blade", "deep": 2, "wide": 1, "rock": false, "ground": false, "crater": false, "said": "It cuts what is in front of it."},
	{"n": "a felling stroke", "deep": 3, "wide": 1, "rock": false, "ground": false, "crater": false, "said": "The tree behind the tree goes too."},
	{"n": "a cleaving stroke", "deep": 4, "wide": 1, "rock": true, "ground": false, "crater": false, "said": "It opens a lane, and the rock in the lane."},
	{"n": "a stroke that breaks stone", "deep": 5, "wide": 1, "rock": true, "ground": true, "crater": false, "said": "The ground it crosses is cracked like a dry field."},
	{"n": "a stroke that shakes the hill", "deep": 6, "wide": 2, "rock": true, "ground": true, "crater": false, "said": "Five tiles wide. Things a long way off fall over."},
	{"n": "a stroke that parts the wood", "deep": 8, "wide": 2, "rock": true, "ground": true, "crater": true, "said": "A wood has a road through it, and where he stood is a hollow."},
]
## the great realm (Data.realm_of) each rank is reached at: Qi Condensation, Foundation Establishment,
## Golden Core, Nascent Soul, Void Refinement, True Immortal.  (The first, a single cut, is below what
## anybody strikes without meaning to: it is only ever the hand held back.)
const REALM_AT := [0, 0, 1, 2, 3, 5, 8]
## what can be done to a tile, what it is called, and the days lived it takes to mend
const KINDS := {
	"tree": {"n": "trees felled", "one": "a stand of trees felled", "mend": 1},
	"rock": {"n": "rocks broken", "one": "a crag broken", "mend": 2},
	"ground": {"n": "tiles of ground cracked", "one": "the ground cracked", "mend": 2},
	"crater": {"n": "craters", "one": "a crater", "mend": 4},
}
const ORDER := ["tree", "rock", "ground", "crater"]

# ---------------------------------------------------------------- how hard
## The heaviest blow his realm can strike (0..5).
static func might(g) -> int:
	var r: int = int(g.realm())
	var out := 0
	for k in REALM_AT.size():
		if r >= int(REALM_AT[k]):
			out = k
	return out

## The blow he strikes now: all he has, or no harder than he has set his hand (`Game.hand`).
static func rank(g) -> int:
	var m := might(g)
	var hd: int = int(g.hand)
	return m if hd < 0 else mini(m, hd)

## H: the next weight of the hand, lighter each time, and round again to all he has.  Returns what to say.
static func cycle(g) -> String:
	var r := rank(g)
	var m := might(g)
	g.hand = -1 if r == 0 else r - 1
	var now := rank(g)
	return "%s: %s. %s%s" % ["All he has" if int(g.hand) < 0 else "The hand held back", str(RANKS[now].n), str(RANKS[now].said), "" if now < m else " (H: lighter)"]

static func text(g) -> String:
	var r := rank(g)
	return "%s%s" % [str(RANKS[r].n).capitalize(), "" if r >= might(g) else " (held back: he could strike %s)" % str(RANKS[might(g)].n)]

# ---------------------------------------------------------------- where
## The tiles a blow of weight `r` reaches, relative to where he stands facing `f`, nearest first.  At
## the edge of a blade (the second weight) these are exactly the four of `Impact.reach`.
static func reach(f: Vector2i, r: int) -> Array:
	var rk: Dictionary = RANKS[clampi(r, 0, RANKS.size() - 1)]
	var side := Vector2i(-f.y, f.x)
	var out: Array = []
	for k in range(1, int(rk.deep) + 1):
		var wd: int = int(rk.wide) if k < int(rk.deep) else 0
		out.append(f * k)
		for j in range(1, wd + 1):
			out.append(f * k + side * j)
			out.append(f * k - side * j)
	return out

## What a blow of weight `r` does to `tile` of world `wd`, reached from `from` ("" for nothing): read
## from the grid and the height field alone.  The streets of a town and the paths are not broken (he
## holds his hand there whatever he is), nor is anything indoors or under the ground.
static func what(wd: Dictionary, from: Vector2i, tile: Vector2i, r: int) -> String:
	if wd.is_empty() or not wd.has("grid") or str(wd.get("kind", "")) == "floor":
		return ""
	var w := int(wd.w)
	var h := int(wd.h)
	if tile.x < 1 or tile.y < 1 or tile.x >= w - 1 or tile.y >= h - 1:
		return ""
	var rk: Dictionary = RANKS[clampi(r, 0, RANKS.size() - 1)]
	var c: int = wd.grid[tile.y * w + tile.x]
	if c == MapGen.WALL:
		return "tree"
	if c != MapGen.FLOOR and c != MapGen.DECOR:
		return ""
	var area := Atlas.owner_id(wd, tile)
	if area == Atlas.HUB or Music.town_at(area, tile) != "":
		return ""
	if bool(rk.rock) and Peaks.rise(wd, float(tile.x) + 0.5, float(tile.y) + 0.5) > Peaks.STEEP * 2.0:
		return "rock"
	if bool(rk.ground) and c == MapGen.FLOOR:
		return "ground"
	return ""

static func key(layer: String, tile: Vector2i) -> String:
	return "%s|%d|%d" % [layer, tile.x, tile.y]

## What lies broken on `tile` today ("" if nothing, or it has mended).
static func scar(g, layer: String, tile: Vector2i) -> String:
	var k := key(layer, tile)
	if not g.scars.has(k):
		return ""
	var sc: Array = g.scars[k]
	if int(g.day) - int(sc[1]) >= int(KINDS[str(sc[0])].mend):
		return ""
	return str(sc[0])

## Forget what has mended (asked now and then, so that the list does not grow for ever).
static func mend(g) -> void:
	for k in g.scars.keys():
		var sc: Array = g.scars[k]
		if int(g.day) - int(sc[1]) >= int(KINDS[str(sc[0])].mend):
			g.scars.erase(k)

# ---------------------------------------------------------------- the blow
## He strikes, standing on `from` and facing `f`: what the land has lost by it.  Returns
## {"rank", "n" (things newly broken), "tiles": [[tile, kind]], "crater": tile or null}.  A tile that
## already lies broken is not broken again.  A step of kind "sunder" hears of it.
static func blow(g, layer: String, wd: Dictionary, from: Vector2i, f: Vector2i) -> Dictionary:
	var r := rank(g)
	var out := {"rank": r, "n": 0, "tiles": [], "crater": null}
	if f == Vector2i.ZERO:
		return out
	for dt in reach(f, r):
		var tl: Vector2i = from + dt
		var kd := what(wd, from, tl, r)
		if kd == "" or scar(g, layer, tl) != "":
			continue
		g.scars[key(layer, tl)] = [kd, int(g.day)]
		g.sundered[kd] = int(g.sundered.get(kd, 0)) + 1
		(out.tiles as Array).append([tl, kd])
		out.n = int(out.n) + 1
	# (a blow that parts the wood leaves a hollow in front of where he stood, if that is open ground)
	if bool(RANKS[r].crater) and int(out.n) > 0:
		var ct: Vector2i = from + f
		# (the Higher Sky release: a hollow that already lies there is not dug again, nor counted again)
		if (what(wd, from, ct, r) == "ground" or scar(g, layer, ct) == "ground") and scar(g, layer, ct) != "crater":
			g.scars[key(layer, ct)] = ["crater", int(g.day)]
			g.sundered["crater"] = int(g.sundered.get("crater", 0)) + 1
			out.crater = ct
	if int(out.n) > 0:
		g.sunder_n += 1
		if r == 0 and int(out.n) == 1:
			g.sunder_light += 1
		var s: Dictionary = g.cur_step()
		# (the Unblunted Knife release: a step that names a country counts what is broken in that country)
		if not s.is_empty() and str(s.kind) == "sunder" and (not s.has("area") or Atlas.owner_id(wd, from) == str(s.area)):
			if s.has("max"):
				if int(out.n) <= int(s.max):
					g.step_sunder += 1
			else:
				g.step_sunder += int(out.n)
			g.poll_steps()
		if g.scars.size() > 600:
			mend(g)
	return out

## How many things he has broken in all.
static func total(g) -> int:
	var n := 0
	for k in g.sundered:
		n += int(g.sundered[k])
	return n

## What is said of a blow (one line for the toast), "" if it broke nothing.
static func told(res: Dictionary) -> String:
	if int(res.n) <= 0:
		return ""
	var by := {}
	for tk in res.tiles:
		by[str(tk[1])] = int(by.get(str(tk[1]), 0)) + 1
	var parts: Array = []
	for kd in ORDER:
		if by.has(kd):
			parts.append("%d %s" % [int(by[kd]), str(KINDS[kd].n)] if int(by[kd]) > 1 else str(KINDS[kd].one))
	if res.crater != null:
		parts.append("a hollow where he stood")
	return "%s: %s" % [str(RANKS[int(res.rank)].n).capitalize(), ", ".join(parts)]

# ---------------------------------------------------------------- drawn only
## What a broken tile looks like: cracked ground (a web of dark lines and a few lifted plates) or a
## crater (a ring of thrown earth round a scorched hollow).  Trees and rocks are the land's own
## (impact.gd fells and shatters what really stands there).
static func model(kind: String, seed_: int, earth: Color) -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 7919 + 13
	var b := MB.new()
	var dark := MB.tag(earth.darkened(0.55), MB.STONE)
	var clod := MB.tag(earth.darkened(0.2), MB.STONE)
	if kind == "crater":
		# the hollow: a dark dish a hand above the ground, and the earth thrown up round it
		b.cyl(Vector3(0, 0.03, 0), 1.25, 0.04, MB.tag(earth.darkened(0.7), MB.STONE), Vector3.ZERO, 14)
		b.cyl(Vector3(0, 0.05, 0), 0.7, 0.03, MB.tag(Color("1c1814"), MB.STONE), Vector3.ZERO, 12)
		for i in 16:
			var a := TAU * float(i) / 16.0 + rng.randf_range(-0.1, 0.1)
			var rr := 1.3 + rng.randf_range(-0.08, 0.2)
			var sz := rng.randf_range(0.22, 0.42)
			b.sph(Vector3(cos(a) * rr, sz * 0.35, sin(a) * rr), Vector3(sz, sz * 0.7, sz * 0.8), clod, Vector3(rng.randf() * 0.6, a, 0))
		for i in 9:
			var a2 := rng.randf() * TAU
			var r2 := rng.randf_range(1.7, 2.6)
			var s2 := rng.randf_range(0.08, 0.18)
			b.box(Vector3(cos(a2) * r2, s2 * 0.5, sin(a2) * r2), Vector3(s2 * 1.4, s2, s2), clod, Vector3(rng.randf(), rng.randf() * 3.0, rng.randf()))
	if kind == "crater" or kind == "ground":
		# cracks running out from the middle, each of two or three straight pieces
		var n := 7 if kind == "crater" else 5
		for i in n:
			var a3 := TAU * float(i) / float(n) + rng.randf_range(-0.3, 0.3)
			var p := Vector3(cos(a3), 0, sin(a3)) * (1.1 if kind == "crater" else 0.1)
			for _k in 3:
				var ln := rng.randf_range(0.35, 0.6)
				var q := p + Vector3(cos(a3), 0, sin(a3)) * ln
				b.box((p + q) * 0.5 + Vector3(0, 0.025, 0), Vector3(0.05, 0.02, ln), dark, Vector3(0, PI / 2.0 - a3, 0))
				p = q
				a3 += rng.randf_range(-0.6, 0.6)
		if kind == "ground":
			for i in 4:
				var a4 := rng.randf() * TAU
				var r4 := rng.randf_range(0.25, 0.8)
				b.box(Vector3(cos(a4) * r4, 0.05, sin(a4) * r4), Vector3(0.34, 0.07, 0.26), clod, Vector3(rng.randf_range(-0.25, 0.25), a4, rng.randf_range(-0.2, 0.2)))
	MB.mesh_node(root, b.build(MB.mat_plain()), Vector3.ZERO)
	return root
