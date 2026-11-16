class_name Arks
extends RefCounted
## The spirit arks (the Cloud Keel release): the ships of the cultivators, and the fifth realm they reach.
##
## A junk (ships.gd) goes from harbour to harbour over water.  An ark has no water under her: her keel
## is spirit-wood and she sits on the air above the weather, so she goes where no junk can: up to the
## Nine Heavens, out to the Isles, and over the edge of the chart to **the Far Countries** of the Liezi
## (atlas.gd STRATA "far": Huaxu, Zhongbei, Gumang, Fuluo), which "neither boat nor cart nor the feet
## can reach".  The arks are Huaxu's; they stopped coming when the sea began to drain away at the
## Returning Ruins and the air after it, and come again once the sea has come home (`OPEN`: the end of
## Part XII).
##
## `DOCKS` are towns with somebody at a counter (offices.gd); at each an ark lies **moored in the air**
## (models.gd `ark`, drawn with the region `HOVER` metres up, over the roofs, above open ground: `berth`; she stands on no
## tile), others cross the sky of every realm she sails (world.gd `_arks_tick`: drawn only), and the
## counter sells a **passage** to the other docks (`offers`, `sail`): a fare by the leagues, the hours
## of the crossing passing, a few lines of what it was like (`TALES`), and the hero set down where the
## town's road begins.
##
## An ark calls only where the journey has already been (`Game.seen`), except her home mooring at
## Lightfoot, which is how the Far Countries are reached at all; and nobody below the Golden Core can
## stand her deck (`REALM`).  Nothing of the story is asked for in the Far Countries, so an ark is
## never a way round it.  No step, trial, notice or ending asks for a passage and the bot takes none.

const DOCKS := {
	"cloudfoot": {"n": "Cloudfoot", "office": "post_cloudfoot", "area": "mountain", "town": "cloudfoot"},
	"tushan": {"n": "Tushan", "office": "guild_tushan", "area": "tushan", "town": "tushan"},
	"featherfall": {"n": "Featherfall", "office": "speaker_featherfall", "area": "juntian", "town": "featherfall"},
	"landfall": {"n": "Landfall", "office": "reeve_landfall", "area": "penglai", "town": "landfall"},
	"lightfoot": {"n": "Lightfoot", "office": "moorer_lightfoot", "area": "huaxu", "town": "lightfoot", "home": true},
	"fourstreams": {"n": "Fourstreams", "office": "reeve_fourstreams", "area": "zhongbei", "town": "fourstreams"},
}
const ORDER := ["cloudfoot", "tushan", "featherfall", "landfall", "lightfoot", "fourstreams"]
## the step after which the arks come again
const OPEN := "s_p12_end"
## the great realm (Data.REALMS) below which nobody can stand the deck: the Golden Core
const REALM := 2
## how far it is through the air (leagues), each way
const LEAGUES := {"cloudfoot|tushan": 30, "cloudfoot|featherfall": 60, "cloudfoot|landfall": 150, "cloudfoot|lightfoot": 900, "cloudfoot|fourstreams": 1000,
	"tushan|featherfall": 70, "tushan|landfall": 180, "tushan|lightfoot": 880, "tushan|fourstreams": 980,
	"featherfall|landfall": 160, "featherfall|lightfoot": 900, "featherfall|fourstreams": 1000,
	"landfall|lightfoot": 1050, "landfall|fourstreams": 1150, "lightfoot|fourstreams": 120}
const FARE_BASE := 80.0
const FARE_LEAGUE := 1.5
const FARE_LV := 6.0
## seconds of the clock a league takes (a junk takes half as long again)
const LEAGUE_SECS := 1.0
## how high over the ground an ark lies at her mooring, and how high the ones under way cross (metres)
const HOVER := 25.0
const CRUISE := 62.0
## the ground an ark at her mooring lies over (tiles from her middle, across and along)
const BERTH_W := 2
const BERTH_L := 4

## What the crossing was like: told once the lines are cast off, before the other mooring.
const TALES := {
	"sky": ["The ark lets go of the ground the way a hand lets go of a rail, and the town tilts and is small. Nobody aboard holds on to anything. Lin Feng holds on to the shrouds and is not corrected.",
		"They sail the top of the weather, a white floor from one edge of the world to the other, with the sun on it. Now and then a mountain comes up through it like a rock at low tide, and the helmsman goes round.",
		"There is no sound of water, and it takes him half a day to know that that is what is missing. The hull creaks all the same. Yue Ling says a ship that did not creak would be showing off."],
	"edge": ["Past the last headland the sea under them goes the grey of slate, then the grey of nothing, and then there is a line, and after the line no sea. The crew do not look down. Lin Feng does, once.",
		"For a night and a day there is nothing under the keel at all, and stars on every side, and below. The ark-master eats her rice at the tiller. 'It is only the same sky,' she says. 'You have never minded it overhead.'",
		"On the third morning there is a cloud that stays where it is, and under it land that is on nobody's chart: green, and unhurried, and with no smoke of war over any part of it. The deckhands coil down as if it were anywhere."],
	"far": ["Between the Far Countries the ark goes low and slow, her shadow sliding over fields that nobody has fenced. People look up and wave with whatever they are holding.",
		"The helmsman steers by a hill shaped like a jar, and lets the tiller go for an hour at a time. In the Far Countries, she says, the wind has never once changed its mind."],
}

## The dock whose counter `office` is ("" if it is none).
static func dock_of(office: String) -> String:
	for id in ORDER:
		if str(DOCKS[id].office) == office:
			return str(id)
	return ""

## The dock of region `area` ("" if no ark lies there).
static func dock_in(area: String) -> String:
	for id in ORDER:
		if str(DOCKS[id].area) == area:
			return str(id)
	return ""

## Whether region `area` lies in a land only an ark reaches (nothing of the story is asked for there, and
## nobody is ever sent there: weal.gd `wanted`).
static func beyond(area: String) -> bool:
	return Data.layer_of(area) == "far"

static func leagues(a: String, b: String) -> int:
	return int(LEAGUES.get("%s|%s" % [a, b], LEAGUES.get("%s|%s" % [b, a], 0)))

static func fare(lg: int, lv: int) -> int:
	return int(round(FARE_BASE + FARE_LEAGUE * float(lg) + FARE_LV * float(lv)))

## Why no ark will take the hero of `g` aboard ("" if one will): they have not come back yet, or he
## cannot stand the deck.
static func blocked(g) -> String:
	if not g.done(OPEN):
		return "No ark has moored here in living memory. While the sea drains away at the Returning Ruins the air drains after it, and no keel of cloud can hold a course. The roster is kept all the same."
	if int(g.realm()) < REALM:
		return "Above the weather the air is thin and the qi is not. Nobody below the %s can stand an ark's deck." % str(Data.REALMS[REALM])
	return ""

## Whether an ark will put in at dock `id` for the journey of `g`: where he has been, and her own home.
static func open_to(g, id: String) -> bool:
	var d: Dictionary = DOCKS[id]
	return bool(d.get("home", false)) or g.seen.has(str(d.area))

## Where an ark will carry the hero of `g` from the counter of `office`: [{from, to, n, leagues, fare, hours, kind}].
static func offers(g, office: String) -> Array:
	var from := dock_of(office)
	var out: Array = []
	if from == "" or blocked(g) != "":
		return out
	for id in ORDER:
		if id == from or not open_to(g, id):
			continue
		var lg := leagues(from, id)
		var fa := beyond(str(DOCKS[from].area))
		var fb := beyond(str(DOCKS[id].area))
		out.append({"from": from, "to": str(id), "n": str(DOCKS[id].n), "leagues": lg, "fare": fare(lg, int(g.level)),
			"hours": snappedf(lg * LEAGUE_SECS / 60.0, 0.1), "kind": "far" if fa and fb else ("edge" if fa != fb else "sky")})
	return out

## The lines of the crossing for `offer`, for the n-th passage of the journey.
static func tale(offer: Dictionary, n: int) -> Array:
	var ls: Array = TALES[str(offer.kind)]
	if str(offer.kind) == "edge":
		# (over the edge of the chart takes all three: the line, the night with nothing under her, the landfall;
		# told the other way round coming home)
		var all: Array = ls.duplicate()
		if not beyond(str(DOCKS[str(offer.to)].area)):
			all = [str(ls[1]), str(ls[0])]
		return all
	return [str(ls[n % ls.size()])]

## The passage is taken: the fare is paid and the hours pass.  True if he could pay and there is
## somewhere to be set down.
static func sail(g, offer: Dictionary) -> bool:
	if offer.is_empty() or blocked(g) != "" or g.stones < int(offer.fare) or quay(str(offer.to)).x < 0:
		return false
	g.stones -= int(offer.fare)
	g.ark_voyages += 1
	Clock.advance(g, float(offer.leagues) * LEAGUE_SECS / Clock.rate(float(g.clock)))
	g.note("Took the ark from %s to %s (%d leagues, %d spirit stones)" % [str(DOCKS[str(offer.from)].n), str(offer.n), int(offer.leagues), int(offer.fare)])
	return true

## The tile he is set down on at dock `id`: where its town's road begins (roads.gd).
static func quay(id: String) -> Vector2i:
	var d: Dictionary = DOCKS[id]
	return Roads.of(Data.layer_of(str(d.area))).at.get(str(d.town), Vector2i(-1, -1))

## Where an ark lies moored in the air at dock `id` in realm data `wd`: the middle of the nearest ground
## to the quay with no house, wing, wood or peak under her and nothing tall of the story standing below
## (Vector2i(-1, -1) if there is none within reach).  She hangs over it; no tile is taken.
static func berth(wd: Dictionary, id: String) -> Vector2i:
	if not _berths.has(id):
		_berths[id] = _find_berth(wd, id)
	return _berths[id]

static var _berths := {}

## (for the tests, and when a realm is made again)
static func forget() -> void:
	_berths = {}

static func _find_berth(wd: Dictionary, id: String) -> Vector2i:
	var q := quay(id)
	if q.x < 0:
		return q
	var W: int = wd.w
	var H: int = wd.h
	# (what stands tall enough to matter to a hull in the air: what a choice left standing, a work, a lord)
	var held := {}
	for e in wd.ents:
		if e.has("pos") and str(e.kind) in ["mark", "machine", "hold", "boss", "ladder"]:
			held[e.pos] = true
	for rad in range(4, 60):
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				if maxi(absi(dx), absi(dy)) != rad:
					continue
				var p := q + Vector2i(dx, dy)
				var ok := true
				for ay in range(-BERTH_L, BERTH_L + 1):
					for ax in range(-BERTH_W, BERTH_W + 1):
						var t := p + Vector2i(ax, ay)
						if t.x < 1 or t.y < 1 or t.x >= W - 1 or t.y >= H - 1:
							ok = false
							break
						var k: int = wd.grid[t.y * W + t.x]
						if (k != MapGen.FLOOR and k != MapGen.PATH and k != MapGen.DECOR and k != MapGen.WATER) or held.has(t):
							ok = false
							break
						if Peaks.rise(wd, float(t.x) + 0.5, float(t.y) + 0.5) > 2.0:
							ok = false
							break
					if not ok:
						break
				if ok:
					return p
	return Vector2i(-1, -1)

## Where the ark that is under way over realm `layer` is at clock time `t` (seconds): {pos (tiles, from
## `mid`), yaw} on a slow figure of eight `reach` tiles wide round `mid`; drawn only.
static func under_way(mid: Vector2, reach: float, t: float, k: int) -> Dictionary:
	var a := t * 0.012 + float(k) * 2.4
	var p := mid + Vector2(sin(a) * reach, sin(a * 2.0) * reach * 0.45)
	var v := Vector2(cos(a) * reach, cos(a * 2.0) * reach * 0.9)
	return {"pos": p, "yaw": atan2(v.x, v.y)}
