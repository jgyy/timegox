class_name Ships
extends RefCounted
## The sea lanes (the Lost Horse release): two lands, and ships between them.
##
## The world is two lands: the Unbroken Land, and the Isles of the Eastern Sea out past the edge of the
## shelf (atlas.gd STRATA "sea").  Until now the only way between them was Mazu's boat from the pool of
## the suns at Fusang, once, for the story.  Now **there are harbours** (`HARBOURS`: Longmen Ferry under
## the Dragon Gate, Yanggu Market on the eastern shore, Landfall on Penglai), a **junk moored in each**
## (models.gd `junk`, drawn with the region and standing on nothing: no tile is taken), and at the
## counter of each a **passage to the others** (`offers`, `sail`): a fare by the leagues, the hours of
## the voyage passing, a few lines of what the crossing was like (`TALES`), and the hero set down on
## the quay at the other end.
##
## A ship goes only where the journey has already been (`Game.seen`), and to the Isles only once the
## story has opened the sea (`needs`): it must never be a way round the story.  No step asks for a
## voyage and the bot takes none.

const HARBOURS := {
	"longmen": {"n": "Longmen Ferry", "office": "harbour_longmen", "area": "longmen", "town": "longmen"},
	"yanggu": {"n": "Yanggu Market", "office": "warden_yanggu", "area": "yanggu", "town": "yanggu"},
	"landfall": {"n": "Landfall", "office": "reeve_landfall", "area": "penglai", "town": "landfall", "needs": "s_p12_shore"},
}
const ORDER := ["longmen", "yanggu", "landfall"]
## how far it is by water (leagues), each way
const LEAGUES := {"longmen|yanggu": 40, "yanggu|landfall": 90, "longmen|landfall": 125}
const FARE_BASE := 30.0
const FARE_LEAGUE := 2.0
const FARE_LV := 3.0
## seconds of the clock a league takes
const LEAGUE_SECS := 1.5

## What the crossing was like: told once the lines are cast off, before the other quay.
const TALES := {
	"river": ["The junk goes down the Yellow River on the current with her sails furled, between banks of loess the colour of a lion. Yue Ling sits in the bow and counts the herons until she has lost count twice.",
		"Below the last gorge the river opens like a hand, and the water under the keel goes from yellow to green to a blue with no bottom to it. The master lights a stick of incense for Mazu and does not explain."],
	"coast": ["They keep the land on one side all day: salt-pans, a fishing fleet under brown sails, a pagoda on a headland that nobody aboard can name. At dusk the batten sails go the red of the sky behind them.",
		"The helmsman steers by a star he calls the Weaver and a smell he calls the shore. In the night the sea is full of cold green fire where the hull cuts it, and Yue Ling leans over the rail and trails her hand in it."],
	"open": ["A day out the land is gone, and for the first time in the whole journey there is nothing that wants anything of Lin Feng in any direction. He stands at the rail a long while and finds he does not know what to do with his hands.",
		"On the third morning there is a cloud that does not move, and under it, by noon, a line of green: the Isles. The crew, who have seen it two hundred times, come to the rail anyway.",
		"The swell out here comes from somewhere with no name, long and slow as breathing. The junk climbs each one and goes down the far side, and the cook does not spill a drop."],
}

static func harbour_of(office: String) -> String:
	for id in ORDER:
		if str(HARBOURS[id].office) == office:
			return str(id)
	return ""

static func leagues(a: String, b: String) -> int:
	return int(LEAGUES.get("%s|%s" % [a, b], LEAGUES.get("%s|%s" % [b, a], 0)))

static func fare(lg: int, lv: int) -> int:
	return int(round(FARE_BASE + FARE_LEAGUE * float(lg) + FARE_LV * float(lv)))

## Whether a ship will put in at harbour `id` for the journey of `g`.
static func open_to(g, id: String) -> bool:
	var h: Dictionary = HARBOURS[id]
	return g.seen.has(str(h.area)) and (not h.has("needs") or g.done(str(h.needs)))

## Where a ship will carry the hero of `g` from the counter of `office`: [{to, n, leagues, fare, hours, kind}].
static func offers(g, office: String) -> Array:
	var from := harbour_of(office)
	var out: Array = []
	if from == "" or (HARBOURS[from].has("needs") and not g.done(str(HARBOURS[from].needs))):
		return out
	for id in ORDER:
		if id == from or not open_to(g, id):
			continue
		var lg := leagues(from, id)
		var across: bool = Data.layer_of(str(HARBOURS[from].area)) != Data.layer_of(str(HARBOURS[id].area))
		out.append({"from": from, "to": str(id), "n": str(HARBOURS[id].n), "leagues": lg, "fare": fare(lg, int(g.level)),
			"hours": snappedf(lg * LEAGUE_SECS / 60.0, 0.1), "kind": "open" if across else ("river" if from == "longmen" or id == "longmen" else "coast")})
	return out

## The lines of the crossing for `offer`, for the n-th voyage of the journey.
static func tale(offer: Dictionary, n: int) -> Array:
	var out: Array = []
	var kinds: Array = [str(offer.kind)]
	if str(offer.kind) == "open" and (str(offer.from) == "longmen" or str(offer.to) == "longmen"):
		kinds = ["river", "open"]
	for k in kinds:
		var ls: Array = TALES[k]
		out.append(str(ls[n % ls.size()]))
	return out

## The passage is taken: the fare is paid and the hours pass.  True if he could pay.
static func sail(g, offer: Dictionary) -> bool:
	if offer.is_empty() or g.stones < int(offer.fare):
		return false
	g.stones -= int(offer.fare)
	g.voyages += 1
	Clock.advance(g, float(offer.leagues) * LEAGUE_SECS)
	g.note("Took ship from %s to %s (%d leagues, %d spirit stones)" % [str(HARBOURS[str(offer.from)].n), str(offer.n), int(offer.leagues), int(offer.fare)])
	return true

## The tile of the quay at harbour `id`: where its town's road begins (roads.gd).
static func quay(id: String) -> Vector2i:
	var h: Dictionary = HARBOURS[id]
	return Roads.of(Data.layer_of(str(h.area))).at.get(str(h.town), Vector2i(-1, -1))

## Where a junk can lie at harbour `id` in realm data `wd`: the middle of the open water nearest the
## quay with water all round it (Vector2i(-1, -1) if there is none within reach).
static func mooring(wd: Dictionary, id: String) -> Vector2i:
	var q := quay(id)
	if q.x < 0:
		return q
	var W: int = wd.w
	var H: int = wd.h
	var sea: PackedByteArray = wd.get("sea", PackedByteArray())
	var wet := func(p: Vector2i) -> bool:
		if p.x < 0 or p.y < 0 or p.x >= W or p.y >= H:
			return false
		return wd.grid[p.y * W + p.x] == MapGen.WATER or (not sea.is_empty() and sea[p.y * W + p.x] == 1)
	for rad in range(5, 70):
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				if maxi(absi(dx), absi(dy)) != rad:
					continue
				var p := q + Vector2i(dx, dy)
				var ok := true
				for ay in range(-4, 5):
					for ax in range(-2, 3):
						ok = ok and wet.call(p + Vector2i(ax, ay))
				if ok:
					return p
	return Vector2i(-1, -1)
