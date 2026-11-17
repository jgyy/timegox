class_name Phases
extends RefCounted
## The Five Hands release: a blow of one of the five phases does to the land what that phase does.
##
## Until this release fire, water, wood, earth and thunder were five colours of the same number: a
## fire technique and a water technique took different amounts off a foe and left the wood they were
## thrown in exactly as it was.  Now the blow he strikes in the land (F) can carry a phase (**K** turns
## his hand to the next one; the plain blade is always the first, and is what it always was), and the
## land answers as what it is:
##
## |          | a wood            | open ground          | water                 |
## | fire     | it burns (and the stand next to it catches) | scorched | a bank of steam |
## | water    | drenched (and will not burn) | a standing pool | a swell      |
## | wood     | in blossom        | grass and flowers to the knee | lotus leaves |
## | earth    | boulders heaved up among the roots | a ridge of raised stone | a gravel bar |
## | thunder  | a trunk riven and smoking | a branch of fused glass | it crackles, and runs |
##
## And the phases meet as the old round has them meet.  A phase **quells** the one it overcomes: water
## on anything burning leaves steam and nothing burning; wood breaks a ridge into a mossy bank; earth
## buries a seam of glass; thunder runs through everything wet that touches.  A phase is **fed** by the
## one that bears it: fire in blossom or tall grass is a blaze that takes two stands, not one; earth
## thrown on what is scorched bakes hard as a kiln floor; thunder into raised stone leaves a lodestone
## humming; water after thunder comes down as rain that stays; and wood where it is wet is a grove.
##
## What is done is **state, and it is drawn only**: `Game.touched` (a tile -> what, and the day), read
## from the grid alone (`ground_of`), so the bot and the tests turn the same land without drawing it.
## **No tile changes**: a burning wood is still a wood nobody walks through, a pool is drawn on ground
## that is walked as it was, a ridge bars nobody.  Nothing here is a way round the story, and
## everything mends by days lived.  Packs, obstacles and what people leave about are struck by the
## blade exactly as they were (`Impact.reach`): only the land answers the phase.

## the five, in the order the hand turns through them (the round that bears: each feeds the next)
const ORDER := ["wood", "fire", "earth", "thunder", "water"]
## phase -> the phase it bears (wood feeds fire, fire leaves earth, ...)
const FEEDS := {"wood": "fire", "fire": "earth", "earth": "thunder", "thunder": "water", "water": "wood"}
## phase -> the phase it overcomes (the weaknesses every foe of the land already has)
const QUELLS := {"water": "fire", "fire": "wood", "wood": "earth", "earth": "thunder", "thunder": "water"}
const NAMES := {"": "The plain blade", "wood": "Wood", "fire": "Fire", "earth": "Earth", "thunder": "Thunder", "water": "Water"}
const SAID := {
	"": "No phase in it: it cuts, and that is all.",
	"wood": "What it touches grows. Water feeds it; it breaks raised stone.",
	"fire": "What it touches burns. Blossom and tall grass feed it; it is put out by water.",
	"earth": "What it touches is raised. Ash and scorched ground feed it; it buries what thunder left.",
	"thunder": "What it touches is riven. Raised stone feeds it; it runs through everything wet.",
	"water": "What it touches is drenched. Thunder brings it down as rain; it puts out what burns.",
}
## what a phase does to each kind of ground
const BASE := {
	"fire": {"tree": "burn", "ground": "scorch", "water": "steam"},
	"water": {"tree": "drench", "ground": "pool", "water": "swell"},
	"wood": {"tree": "bloom", "ground": "sprout", "water": "lotus"},
	"earth": {"tree": "heave", "ground": "ridge", "water": "bar"},
	"thunder": {"tree": "riven", "ground": "glass", "water": "arc"},
}
## what is left when a phase quells the one it overcomes, and what comes of a phase fed by the one that
## bears it (by the phase that was struck with)
const QUELLED := {"water": "steam", "wood": "moss", "earth": "mound", "thunder": "arc"}
const FED := {"fire": "blaze", "earth": "kiln", "thunder": "lode", "water": "rain", "wood": "grove"}
## what can lie on a tile: the phase it is of, what it is called, and the days lived it takes to mend
const KINDS := {
	"burn": {"el": "fire", "n": "stands of trees burning", "one": "a stand of trees set burning", "mend": 2},
	"scorch": {"el": "fire", "n": "tiles of ground scorched", "one": "the ground scorched", "mend": 2},
	"steam": {"el": "fire", "n": "banks of steam", "one": "a bank of steam", "mend": 1},
	"blaze": {"el": "fire", "n": "blazes", "one": "a blaze", "mend": 3},
	"drench": {"el": "water", "n": "stands of trees drenched", "one": "a stand of trees drenched", "mend": 1},
	"pool": {"el": "water", "n": "pools", "one": "a pool left standing", "mend": 2},
	"swell": {"el": "water", "n": "swells", "one": "the water heaped up", "mend": 1},
	"rain": {"el": "water", "n": "tiles of rain", "one": "rain brought down that stays", "mend": 2},
	"bloom": {"el": "wood", "n": "stands of trees in blossom", "one": "a stand of trees in blossom", "mend": 3},
	"sprout": {"el": "wood", "n": "tiles of grass and flowers", "one": "grass and flowers to the knee", "mend": 3},
	"lotus": {"el": "wood", "n": "rafts of lotus", "one": "a raft of lotus leaves", "mend": 3},
	"grove": {"el": "wood", "n": "groves", "one": "a grove", "mend": 4},
	"moss": {"el": "wood", "n": "mossy banks", "one": "a ridge broken into a mossy bank", "mend": 3},
	"heave": {"el": "earth", "n": "stands of trees heaved", "one": "boulders heaved up among the roots", "mend": 3},
	"ridge": {"el": "earth", "n": "ridges", "one": "a ridge of raised stone", "mend": 3},
	"bar": {"el": "earth", "n": "gravel bars", "one": "a gravel bar", "mend": 2},
	"kiln": {"el": "earth", "n": "tiles baked hard", "one": "the ground baked hard as a kiln floor", "mend": 4},
	"mound": {"el": "earth", "n": "mounds", "one": "a seam of glass buried", "mend": 2},
	"riven": {"el": "thunder", "n": "trunks riven", "one": "a trunk riven", "mend": 2},
	"glass": {"el": "thunder", "n": "seams of glass", "one": "a branch of fused glass", "mend": 3},
	"arc": {"el": "thunder", "n": "tiles of water crackling", "one": "the water crackling", "mend": 1},
	"lode": {"el": "thunder", "n": "lodestones", "one": "a lodestone left humming", "mend": 4},
}
## how many more tiles a fire catches from where it was set (a blaze twice as many), and how far
## thunder runs through what is wet
const CATCH := 2
const RUN := 10
const SIDES := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

# ---------------------------------------------------------------- the hand
## K: the next phase of the hand (plain, then the five in the bearing round).  Returns what to say.
static func cycle(g) -> String:
	var i := ORDER.find(str(g.phase))
	g.phase = "" if i == ORDER.size() - 1 else str(ORDER[i + 1])
	return text(g)

static func text(g) -> String:
	return "%s. %s" % [str(NAMES[str(g.phase)]), str(SAID[str(g.phase)])]

# ---------------------------------------------------------------- the land
static func key(layer: String, tile: Vector2i) -> String:
	return "%s|%d|%d" % [layer, tile.x, tile.y]

## What kind of ground `tile` is to a phase: "tree", "ground", "water" or "" (nothing a phase is turned
## on: the streets of a town, indoors, under the ground, and anything but the woods of the mountain at
## the middle of the land).
static func ground_of(wd: Dictionary, tile: Vector2i) -> String:
	if wd.is_empty() or not wd.has("grid") or str(wd.get("kind", "")) == "floor":
		return ""
	var w := int(wd.w)
	var h := int(wd.h)
	if tile.x < 1 or tile.y < 1 or tile.x >= w - 1 or tile.y >= h - 1:
		return ""
	var c: int = wd.grid[tile.y * w + tile.x]
	var area := Atlas.owner_id(wd, tile)
	if Music.town_at(area, tile) != "":
		return ""
	if c == MapGen.WALL:
		return "tree"
	# (the mountain at the middle of the land is where everybody arrives: its woods answer, its paths and waters do not)
	if area == Atlas.HUB:
		return ""
	if c == MapGen.WATER:
		return "water"
	if c == MapGen.FLOOR or c == MapGen.DECOR:
		return "ground"
	return ""

## What lies on `tile` today ("" if nothing, or it has mended).
static func on(g, layer: String, tile: Vector2i) -> String:
	var k := key(layer, tile)
	if not g.touched.has(k):
		return ""
	var st: Array = g.touched[k]
	if int(g.day) - int(st[1]) >= int(KINDS[str(st[0])].mend):
		return ""
	return str(st[0])

static func mend(g) -> void:
	for k in g.touched.keys():
		var st: Array = g.touched[k]
		if int(g.day) - int(st[1]) >= int(KINDS[str(st[0])].mend):
			g.touched.erase(k)

## What a blow of phase `el` makes of `tile`, given what lies on it now: [kind, how they met ("",
## "quell" or "feed")], or [] if nothing comes of it (no such ground, or the same thing lies there).
static func meet(g, layer: String, wd: Dictionary, tile: Vector2i, el: String) -> Array:
	return come(on(g, layer, tile), el, ground_of(wd, tile))

## The same, of ground of kind `gr` ("tree", "ground", "water") on which `cur` lies ("" for nothing): the
## rule itself, with no land in it (a battle's ground is marked by it too).
static func come(cur: String, el: String, gr: String) -> Array:
	if gr == "" or not BASE.has(el):
		return []
	if cur != "":
		var was := str(KINDS[cur].el)
		if str(FEEDS[was]) == el:
			return [] if cur == str(FED[el]) else [str(FED[el]), "feed"]
		if str(QUELLS[el]) == was:
			return [str(QUELLED[el]), "quell"]
		if was == el:
			return []
		# (what lies there overcomes what he struck with: the blow is spent.  Fire on what is wet dries it)
		if str(QUELLS[was]) == el:
			return ["steam", ""] if el == "fire" and cur != "steam" else []
	var kd := str(BASE[el][gr])
	return [] if kd == cur else [kd, ""]

static func _lay(g, layer: String, tile: Vector2i, kd: String, how: String, out: Dictionary) -> void:
	g.touched[key(layer, tile)] = [kd, int(g.day)]
	g.phased[kd] = int(g.phased.get(kd, 0)) + 1
	(out.tiles as Array).append([tile, kd, how])
	out.n = int(out.n) + 1
	if how != "":
		out[how] = int(out.get(how, 0)) + 1
		g.reacts[how] = int(g.reacts.get(how, 0)) + 1

## He strikes with phase `el`, standing on `from` and facing `f`: what the land makes of it.  The blow
## reaches as far as a blow of his weight reaches (`Sunder.reach`: the hand held back holds this back
## too).  Returns {"el", "n" (tiles changed), "tiles": [[tile, kind, how]], "quell", "feed"}.  `dry`:
## only say what would come of it.
static func cast(g, layer: String, wd: Dictionary, from: Vector2i, f: Vector2i, el: String, dry: bool = false) -> Dictionary:
	var out := {"el": el, "n": 0, "tiles": [], "quell": 0, "feed": 0}
	if f == Vector2i.ZERO or not BASE.has(el):
		return out
	if dry:
		for dt in Sunder.reach(f, Sunder.rank(g)):
			var m0: Array = meet(g, layer, wd, from + dt, el)
			if not m0.is_empty():
				(out.tiles as Array).append([from + dt, m0[0], m0[1]])
				out.n = int(out.n) + 1
				if str(m0[1]) != "":
					out[str(m0[1])] = int(out[str(m0[1])]) + 1
		return out
	var lit: Array = []
	var ran: Array = []
	for dt in Sunder.reach(f, Sunder.rank(g)):
		var tl: Vector2i = from + dt
		var m: Array = meet(g, layer, wd, tl, el)
		if m.is_empty():
			continue
		_lay(g, layer, tl, str(m[0]), str(m[1]), out)
		if str(m[0]) in ["burn", "blaze"]:
			lit.append([tl, CATCH * (2 if str(m[0]) == "blaze" else 1)])
		elif str(m[0]) == "arc":
			ran.append(tl)
	# a fire catches the stands next to it that are not wet: so many, nearest first, and no further
	for lt in lit:
		var left := int(lt[1])
		for sd in SIDES:
			var nb: Vector2i = (lt[0] as Vector2i) + sd
			if left <= 0:
				break
			if ground_of(wd, nb) == "tree" and on(g, layer, nb) in ["", "bloom", "grove"]:
				_lay(g, layer, nb, "burn", "", out)
				left -= 1
	# thunder runs through everything wet that touches: water, pools, rain, a drenched wood
	var seen := {}
	var left2 := RUN
	while not ran.is_empty() and left2 > 0:
		var at: Vector2i = ran.pop_front()
		for sd2 in SIDES:
			var nb2: Vector2i = at + sd2
			if seen.has(nb2) or left2 <= 0:
				continue
			seen[nb2] = true
			var cur := on(g, layer, nb2)
			if cur == "arc":
				continue
			if ground_of(wd, nb2) == "water" or (cur != "" and str(KINDS[cur].el) == "water"):
				_lay(g, layer, nb2, "arc", "", out)
				ran.append(nb2)
				left2 -= 1
	if int(out.n) > 0:
		g.phase_n += 1
		g.phases_used[el] = int(g.phases_used.get(el, 0)) + 1
		var s: Dictionary = g.cur_step()
		if not s.is_empty() and str(s.kind) == "phase" and (not s.has("el") or str(s.el) == el) and (not s.has("area") or Atlas.owner_id(wd, from) == str(s.area)):
			# (a step counts blows, not tiles: one for each that came to what it asks)
			if not s.has("react") or int(out.get(str(s.react), 0)) > 0:
				g.step_phase += 1
			g.poll_steps()
		if g.touched.size() > 700:
			mend(g)
	return out

## How many of the five he has turned on the land at all.
static func turned(g) -> int:
	return g.phases_used.size()

## What is said of a blow (one line for the toast), "" if nothing came of it.
static func told(res: Dictionary) -> String:
	if int(res.n) <= 0:
		return ""
	var by := {}
	var order: Array = []
	for tk in res.tiles:
		if not by.has(str(tk[1])):
			order.append(str(tk[1]))
		by[str(tk[1])] = int(by.get(str(tk[1]), 0)) + 1
	var parts: Array = []
	for kd in order:
		parts.append("%d %s" % [int(by[kd]), str(KINDS[kd].n)] if int(by[kd]) > 1 else str(KINDS[kd].one))
	var how := ""
	if int(res.get("feed", 0)) > 0:
		how = " (fed by what lay there)"
	elif int(res.get("quell", 0)) > 0:
		how = " (it overcame what lay there)"
	return "%s: %s%s" % [str(NAMES[str(res.el)]), ", ".join(parts), how]

## The colour a tree that stands on a tile so touched is drawn (multiplied into its own), or white.
static func tree_tint(kind: String) -> Color:
	match kind:
		"burn", "blaze":
			return Color(0.32, 0.2, 0.14)
		"riven":
			return Color(0.42, 0.4, 0.42)
		"drench":
			return Color(0.62, 0.74, 0.86)
		"bloom":
			return Color(1.25, 0.82, 0.95)
		"grove":
			return Color(0.75, 1.2, 0.7)
		"heave":
			return Color(0.88, 0.84, 0.74)
	return Color(1, 1, 1)

# ---------------------------------------------------------------- drawn only
## What a touched tile looks like, standing at the middle of the tile on the ground.  A child called
## "flick" is what flickers (flames, a crackle); one called "rise" is what drifts up (steam, smoke).
static func model(kind: String, seed_: int, earth: Color, grass: Color) -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 6007 + 5
	var b := MB.new()
	var gl := MB.new()
	var fl := MB.new()
	var up := MB.new()
	var char_ := MB.tag(Color("1c1814"), MB.STONE)
	var stone := MB.tag(earth.lerp(Color("8a8478"), 0.6), MB.STONE)
	match kind:
		"burn", "blaze", "scorch":
			var big := 1.7 if kind == "blaze" else 1.0
			b.disc(Vector3(0, 0.03, 0), 0.95, MB.tag(Color("1e1a16"), MB.STONE), 12, MB.tag(earth.darkened(0.6), MB.STONE))
			if kind == "scorch":
				for i in 7:
					var a := rng.randf() * TAU
					var r := rng.randf_range(0.2, 0.8)
					b.box(Vector3(cos(a) * r, 0.06, sin(a) * r), Vector3(0.05, 0.1, 0.02), char_, Vector3(rng.randf_range(-0.5, 0.5), a, 0))
					gl.ball(Vector3(cos(a) * r * 0.8, 0.05, sin(a) * r * 0.8), 0.045, Color(1.0, 0.45, 0.12, 0.8), true)
			else:
				for i in 6:
					var a2 := TAU * float(i) / 6.0 + rng.randf_range(-0.3, 0.3)
					var r2 := rng.randf_range(0.15, 0.75)
					var hgt := rng.randf_range(0.7, 1.5) * big
					var at := Vector3(cos(a2) * r2, 0.25 + rng.randf() * 1.6, sin(a2) * r2)
					fl.cone(at + Vector3(0, hgt * 0.5, 0), 0.2 * big, hgt, Color(1.0, 0.5, 0.12, 0.75), Vector3.ZERO, 6)
					fl.cone(at + Vector3(0, hgt * 0.32, 0), 0.11 * big, hgt * 0.6, Color(1.0, 0.86, 0.35, 0.9), Vector3.ZERO, 5)
				gl.ball(Vector3(0, 1.0, 0), 1.1 * big, Color(1.0, 0.5, 0.15, 0.16), true)
				for i in 4:
					up.ball(Vector3(rng.randf_range(-0.5, 0.5), 2.6 + 0.5 * i, rng.randf_range(-0.5, 0.5)), 0.38 + 0.08 * i, Color(0.2, 0.2, 0.22, 0.32), true)
		"steam":
			for i in 6:
				up.ball(Vector3(rng.randf_range(-0.7, 0.7), 0.4 + 0.35 * i, rng.randf_range(-0.7, 0.7)), 0.4 + 0.07 * i, Color(0.95, 0.96, 1.0, 0.26), true)
		"drench", "pool", "rain", "swell":
			var wet := MB.tag(Color(0.28, 0.42, 0.56), MB.METAL)
			if kind != "swell":
				b.disc(Vector3(0, 0.025, 0), 0.9 if kind != "drench" else 0.6, wet, 14, MB.tag(Color(0.2, 0.3, 0.38), MB.METAL))
				for i in 3:
					b.disc(Vector3(rng.randf_range(-0.8, 0.8), 0.028, rng.randf_range(-0.8, 0.8)), rng.randf_range(0.15, 0.3), wet, 8)
			else:
				for i in 3:
					b.torus(Vector3(0, 0.12, 0), 0.35 + 0.28 * i, 0.05, MB.tag(Color(0.7, 0.86, 1.0), MB.METAL), Vector3(PI * 0.5, 0, 0))
			if kind == "rain" or kind == "drench":
				for i in 16:
					var px := rng.randf_range(-0.9, 0.9)
					var pz := rng.randf_range(-0.9, 0.9)
					var py := rng.randf_range(0.3, 3.2)
					fl.box(Vector3(px, py, pz), Vector3(0.012, 0.22, 0.012), Color(0.75, 0.88, 1.0, 0.7))
			if kind == "rain":
				for i in 4:
					up.ball(Vector3(rng.randf_range(-0.6, 0.6), 3.6, rng.randf_range(-0.6, 0.6)), 0.6, Color(0.5, 0.54, 0.62, 0.5), true)
		"sprout", "grove", "bloom", "lotus", "moss":
			var g1 := MB.tag(grass.lightened(0.12), MB.FOLIAGE)
			var cols := [Color("f0a0c0"), Color("f8e070"), Color("f4f0f0"), Color("c0a0f0")]
			if kind == "lotus":
				for i in 5:
					var a3 := rng.randf() * TAU
					var r3 := rng.randf_range(0.1, 0.7)
					b.disc(Vector3(cos(a3) * r3, Terrain3D.WATER_Y + 0.03, sin(a3) * r3), rng.randf_range(0.16, 0.3), MB.tag(Color("3a8a4a"), MB.FOLIAGE), 9)
				b.sph(Vector3(0.1, Terrain3D.WATER_Y + 0.16, 0.0), Vector3(0.1, 0.12, 0.1), MB.tag(Color("f4b0cc"), MB.FOLIAGE))
			elif kind == "moss":
				for i in 5:
					b.sph(Vector3(-0.8 + 0.4 * i, 0.14, rng.randf_range(-0.15, 0.15)), Vector3(0.3, 0.22, 0.28), MB.tag(Color("5a7a44"), MB.FOLIAGE), Vector3(0, rng.randf() * 3.0, 0))
					b.box(Vector3(-0.8 + 0.4 * i + 0.1, 0.07, 0.25), Vector3(0.18, 0.12, 0.14), stone, Vector3(0.3, rng.randf() * 3.0, 0.2))
			else:
				var n := 26 if kind == "grove" else (10 if kind == "bloom" else 18)
				for i in n:
					var px2 := rng.randf_range(-0.9, 0.9)
					var pz2 := rng.randf_range(-0.9, 0.9)
					var hh := rng.randf_range(0.3, 0.6) * (1.5 if kind == "grove" else 1.0)
					if kind != "bloom":
						b.cone(Vector3(px2, hh * 0.5, pz2), 0.05, hh, g1, Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2)), 4)
					if i % 2 == 0 or kind == "bloom":
						var fy := hh + 0.02 if kind != "bloom" else rng.randf_range(1.4, 3.0)
						b.sph(Vector3(px2, fy, pz2), Vector3.ONE * (0.05 if kind != "bloom" else 0.16), MB.tag(cols[i % 4] if kind != "bloom" else Color("f8c0d8"), MB.FOLIAGE))
				if kind == "grove":
					for i in 3:
						var sx := rng.randf_range(-0.6, 0.6)
						var sz := rng.randf_range(-0.6, 0.6)
						b.cyl(Vector3(sx, 0.5, sz), 0.035, 1.0, MB.tag(Color("6a5034"), MB.WOOD), Vector3.ZERO, 5)
						b.sph(Vector3(sx, 1.15, sz), Vector3(0.32, 0.36, 0.32), MB.tag(grass.darkened(0.1), MB.FOLIAGE))
		"ridge", "heave", "bar", "kiln", "mound":
			if kind == "kiln":
				b.disc(Vector3(0, 0.03, 0), 0.98, MB.tag(Color("a85a3a"), MB.STONE), 10, MB.tag(Color("7a4028"), MB.STONE))
				for i in 6:
					var a4 := TAU * float(i) / 6.0 + rng.randf_range(-0.2, 0.2)
					b.box(Vector3(cos(a4) * 0.45, 0.04, sin(a4) * 0.45), Vector3(0.03, 0.015, 0.8), MB.tag(Color("4a2618"), MB.STONE), Vector3(0, PI / 2.0 - a4, 0))
			elif kind == "mound":
				b.sph(Vector3(0, 0.05, 0), Vector3(0.8, 0.3, 0.7), MB.tag(earth.darkened(0.25), MB.STONE))
			else:
				var cnt := 5 if kind == "ridge" else 4
				for i in cnt:
					var px3 := (-0.8 + 1.6 * float(i) / float(cnt - 1)) if kind == "ridge" else rng.randf_range(-0.7, 0.7)
					var pz3 := rng.randf_range(-0.15, 0.15) if kind == "ridge" else rng.randf_range(-0.7, 0.7)
					var hh2 := rng.randf_range(0.35, 0.8) if kind != "bar" else rng.randf_range(0.1, 0.18)
					var base_y := Terrain3D.WATER_Y if kind == "bar" else 0.0
					if kind == "bar":
						b.sph(Vector3(px3, base_y + 0.02, pz3), Vector3(0.34, hh2, 0.3), stone)
					else:
						b.box(Vector3(px3, hh2 * 0.5, pz3), Vector3(0.36, hh2, 0.34), stone, Vector3(rng.randf_range(-0.15, 0.15), rng.randf() * 3.0, rng.randf_range(-0.15, 0.15)))
						b.box(Vector3(px3 + 0.2, 0.06, pz3 + 0.25), Vector3(0.18, 0.12, 0.16), MB.tag(earth.darkened(0.3), MB.STONE), Vector3(0.3, rng.randf() * 3.0, 0))
		"riven", "glass", "arc", "lode":
			if kind == "glass" or kind == "lode":
				var p := Vector3.ZERO
				for br in 5:
					var a5 := TAU * float(br) / 5.0 + rng.randf_range(-0.3, 0.3)
					p = Vector3.ZERO
					for _s in 3:
						var ln := rng.randf_range(0.25, 0.42)
						var q := p + Vector3(cos(a5), 0, sin(a5)) * ln
						b.box((p + q) * 0.5 + Vector3(0, 0.035, 0), Vector3(0.07, 0.04, ln), MB.tag(Color("9ad8d0"), MB.METAL), Vector3(0, PI / 2.0 - a5, 0))
						p = q
						a5 += rng.randf_range(-0.7, 0.7)
				b.disc(Vector3(0, 0.03, 0), 0.3, char_, 8)
			if kind == "lode":
				for i in 3:
					var a6 := TAU * float(i) / 3.0 + 0.5
					b.cone(Vector3(cos(a6) * 0.25, 0.45, sin(a6) * 0.25), 0.16, 0.9, MB.tag(Color("3a3c48"), MB.METAL), Vector3(0.15 * cos(a6), 0, 0.15 * sin(a6)), 5)
				gl.ball(Vector3(0, 0.7, 0), 0.6, Color(0.75, 0.8, 1.0, 0.18), true)
			if kind == "riven":
				b.disc(Vector3(0, 0.03, 0), 0.6, char_, 8)
				for i in 3:
					up.ball(Vector3(rng.randf_range(-0.2, 0.2), 2.0 + 0.5 * i, rng.randf_range(-0.2, 0.2)), 0.3, Color(0.25, 0.25, 0.28, 0.3), true)
			if kind != "glass":
				# the crackle: a few bent threads of light
				var base2 := Terrain3D.WATER_Y + 0.08 if kind == "arc" else 0.3
				for i in 4:
					var p2 := Vector3(rng.randf_range(-0.6, 0.6), base2, rng.randf_range(-0.6, 0.6))
					for _s2 in 3:
						var q2 := p2 + Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.0, 0.25) if kind == "arc" else rng.randf_range(0.2, 0.7), rng.randf_range(-0.3, 0.3))
						fl.limb(p2, q2, 0.012, 0.008, Color(0.9, 0.95, 1.0, 0.95), 3)
						p2 = q2
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_plain()), Vector3.ZERO)
	if not gl.is_empty():
		MB.mesh_node(root, gl.build(MB.mat_glow()), Vector3.ZERO).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not fl.is_empty():
		var fn := MB.mesh_node(root, fl.build(MB.mat_glow()), Vector3.ZERO)
		fn.name = "flick"
		fn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not up.is_empty():
		var un := MB.mesh_node(root, up.build(MB.mat_glow()), Vector3.ZERO)
		un.name = "rise"
		un.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root
