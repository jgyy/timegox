class_name Retreats
extends RefCounted
## Places of peace (the Unblunted Knife release): where he can rest, and cultivate, and be let alone.
## "I sit down and forget everything."
##
## **Nothing is placed in the world for them**: a place of peace is somewhere the land already has (`at`,
## read from the realm alone): **the very top of any peak** (peaks.gd leaves that tile for whoever climbs),
## **the back of any cave** (within two tiles of where its cache lay), and **any pavilion** (a roof with no
## walls: props.gd), faced.  So no map moves, and the bot and the tests find them without drawing anything.
##
## **M**, standing in one ("Not now" first).  How quiet it is (`peace`, four steps: `LEVELS`) is read from
## how far the nearest pack that is up and about is, whether a beast that keeps watch is at his heel
## (pets.gd), and what he has opened of the Channel of Stillness (channels.gd); a place with something hunting
## in earshot is troubled, and nothing can be done in it.  What can be done (`ACTS`):
##   **sit and forget** (`sit`): two hours; he is mended, he cultivates as a long meditation would have him
##     (more the quieter it is), the beast at his heel trusts him more, and **the first sitting of each day
##     in each place is an insight** (channels.gd), two the first time he ever sits there;
##   **sleep until dawn** (`sleep`): the night passes, he is mended, and a body with needs is rested;
##   **work at a craft** (crafts.gd): what he makes comes out a grade better for every step of quiet.
## He is drawn sitting on a mat laid on that tile while it lasts (`Retreats.mat`: built from code, stood on
## no tile).  New step kind "retreat" (`n` sittings since the step began; `where`: in a place of that kind;
## `"new": true`: in places he had never sat in).  The bot sits only inside such a step.
## **A new kind of place** needs a case in `at`, a line in `KINDS` and three in `LINES`.

const KINDS := {
	"summit": {"n": "a summit", "word": "Nothing is higher than this for a long way. The wind has been here before him and has left nothing lying about."},
	"deep": {"n": "the back of a cave", "word": "No day comes this far in. Water is counting somewhere, and has not lost its place in a thousand years."},
	"pavilion": {"n": "a pavilion", "word": "A roof and no walls. Whoever built it wished to be out of the rain and in everything else."},
}
const LEVELS := ["Troubled", "Quiet", "Still", "Deep peace"]
## how near (tiles) a pack that is up and about troubles a place, and how far off it must be for stillness
const NEAR := 5
const FAR := 12
const SIT_HOURS := 2.0
## what a sitting is worth in seconds of meditation, a step of quiet
const SIT_SECONDS := 40.0
const DAWN := 6.0
const ASK := "A place of peace"
const NOWHERE := "There is no peace to be had here. The top of a peak, the back of a cave, a pavilion: those are places."
const LINES := {
	"summit": ["He sits. For a while he hears the wind, and then he hears with it. When he gets up the shadows have moved round the cairn.",
		"He sits, and forgets to count the breaths, and then forgets he was to count them. A hawk goes by below him.",
		"\"I have lost myself,\" said the man of the south wall. \"Do you understand?\" On the top of a mountain it is not difficult."],
	"deep": ["He sits in the dark until it stops being a thing he is in. A drop falls. It is some time before the next one.",
		"He sits. Without light there is no edge to where he ends, and after a while he stops looking for one.",
		"\"Do not listen with the ear.\" There is nothing to listen to with it. He listens with what is left."],
	"pavilion": ["He sits under the roof with the country open on every side. A swallow comes in at one side and goes out at the other.",
		"He sits. Somebody carved a line on the post, long ago, and he reads it once and then lets it go.",
		"Rain comes across the valley, reaches the eaves, and goes on. He was not waiting for it and does not see it leave."],
}

static var _cache := {}

## The place of peace he is standing in on tile `tile` of realm or floor `wd` ({} if it is none): {"id",
## "kind", "n"}.  `faced`: the thing in front of him, if any.
static func at(wd: Dictionary, tile: Vector2i, faced: Dictionary = {}) -> Dictionary:
	if wd.is_empty():
		return {}
	if Caves.is_cave(wd):
		var key := "%s:%d" % [str(wd.get("area", "")), int(wd.get("level", -1))]
		if not _cache.has(key):
			_cache[key] = Vector2i(-99, -99)
			for e in wd.ents:
				if str(e.get("id", "")).begins_with("cave_cache:"):
					_cache[key] = e.pos
					break
		var c: Vector2i = _cache[key]
		if maxi(absi(tile.x - c.x), absi(tile.y - c.y)) <= 2:
			return {"id": "deep:" + key, "kind": "deep", "n": "the back of " + str(Caves.spec(str(wd.get("area", "")), int(wd.get("level", -1))).get("n", "the cave"))}
		return {}
	if str(wd.get("kind", "")) == "floor":
		return {}
	var pk := Peaks.summit_at(wd, tile)
	if not pk.is_empty():
		return {"id": str(pk.id), "kind": "summit", "n": "the top of " + str(pk.n)}
	if str(faced.get("kind", "")) == "prop" and str(faced.get("prop", "")) == "pavilion":
		return {"id": "pav:" + str(faced.id), "kind": "pavilion", "n": "the pavilion"}
	return {}

## How quiet a place is for him now (0 troubled to 3 deep peace).  `pack_dist`: tiles to the nearest pack that
## is up and about (a big number if there is none).
static func peace(g, pack_dist: int) -> int:
	if pack_dist <= NEAR:
		return 0
	var p := 1
	if pack_dist > FAR:
		p += 1
	if Pets.watch(g):
		p += 1
	p += int(Channels.add(g, "peace"))
	return clampi(p, 1, 3)

## He sits and forgets, in place `r` at quiet `p`.  Returns the lines to tell ([] if it is troubled).
static func sit(g, r: Dictionary, p: int) -> Array:
	if r.is_empty() or p <= 0:
		return []
	var id := str(r.id)
	var first_ever: bool = not g.retreats.has(id)
	var first_today: bool = int(g.sat_day.get(id, -1)) != int(g.day)
	var n := int(g.retreats.get(id, 0))
	g.retreats[id] = n + 1
	g.sittings = int(g.sittings) + 1
	Clock.set_hour(g, Clock.hour(g) + SIT_HOURS)
	g.sat_day[id] = int(g.day)
	g.heal_full()
	var lines: Array = [str(LINES[str(r.kind)][n % (LINES[str(r.kind)] as Array).size()])]
	var gain: float = g.med_rate(false) * SIT_SECONDS * float(p) * Channels.mod(g, "sit")
	if int(g.level) < Data.MAX_LEVEL and not Data.realm_cap(int(g.level)):
		g.add_exp(gain)
		lines.append("%s. Cultivation +%d." % [str(LEVELS[p]), int(gain)])
	else:
		lines.append("%s." % str(LEVELS[p]))
	if first_today:
		var got := Channels.learn(g, (2 if first_ever else 1) + int(Channels.add(g, "insight")), "sitting at " + str(r.n))
		if got > 0:
			lines.append("Insight: +%d (Esc > The Channels)." % got)
	Pets.sat(g)
	Needs.give(g, {"rest": 20.0, "comfort": 10.0})
	g.note("Sat and forgot at %s" % str(r.n))
	var s: Dictionary = g.cur_step()
	if not s.is_empty() and str(s.kind) == "retreat" and (not s.has("where") or str(s.where) == str(r.kind)) and (not bool(s.get("new", false)) or first_ever):
		g.step_did["retreat"] = int(g.step_did.get("retreat", 0)) + 1
		g.poll_steps()
	return lines

## He sleeps there until dawn.  Returns the lines to tell.
static func sleep(g, r: Dictionary, p: int) -> Array:
	if r.is_empty() or p <= 0:
		return []
	Clock.set_hour(g, DAWN)
	g.heal_full()
	g.slept = int(g.slept) + 1
	Needs.give(g, {"rest": 100.0, "comfort": 20.0})
	g.note("Slept at %s" % str(r.n))
	return ["He sleeps at %s, and nothing comes. It is dawn. (%s)" % [str(r.n), Clock.text(g)]]

## How many different places he has sat in.
static func count(g) -> int:
	return g.retreats.size()

## The mat he sits on, drawn on the tile while he sits: rush matting, and a stick of incense in a stone.
static func mat() -> Node3D:
	var root := Node3D.new()
	var g := MB.new()
	g.box(Vector3(0, 0.02, 0), Vector3(0.9, 0.04, 0.9), MB.tag(Color("b8a060"), MB.CLOTH))
	g.box(Vector3(0, 0.045, 0), Vector3(0.78, 0.012, 0.78), MB.tag(Color("a08a4a"), MB.CLOTH))
	g.cyl(Vector3(0.0, 0.06, 0.62), 0.07, 0.08, MB.tag(Color("8a8a88"), MB.STONE), Vector3.ZERO, 8)
	g.cyl(Vector3(0.0, 0.2, 0.62), 0.008, 0.22, Color("6a3a2a"), Vector3.ZERO, 5)
	MB.mesh_node(root, g.build(MB.mat_plain()))
	var e := MB.new()
	e.cyl(Vector3(0.0, 0.315, 0.62), 0.012, 0.012, Color("ff8a3a"), Vector3.ZERO, 5)
	MB.mesh_node(root, e.build(MB.mat_glow()))
	return root

## What is said of the places he has sat in, for the page.
static func text(g) -> String:
	if g.retreats.is_empty():
		return "He has not sat anywhere yet. The top of any peak, the back of any cave and any pavilion is a place of peace (M)."
	var by := {"summit": 0, "deep": 0, "pavilion": 0}
	for id in g.retreats:
		var k := "deep" if str(id).begins_with("deep:") else ("pavilion" if str(id).begins_with("pav:") else "summit")
		by[k] = int(by[k]) + 1
	return "He has sat and forgotten %d time%s, in %d place%s (summits %d, caves %d, pavilions %d), and slept out %d night%s." % [int(g.sittings), "" if int(g.sittings) == 1 else "s", g.retreats.size(),
		"" if g.retreats.size() == 1 else "s", int(by.summit), int(by.deep), int(by.pavilion), int(g.slept), "" if int(g.slept) == 1 else "s"]
