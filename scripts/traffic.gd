class_name Traffic
extends RefCounted
## What goes along the roads (the Rivers and Lakes release).
##
## The high road has joined the towns since the Lost Horse release (roads.gd), and nothing went along it
## but him.  Now **every road of every realm that has towns carries traffic**: ten kinds of vehicle
## (`KINDS`), each going from one end of its stretch of road to the other, standing a while and coming
## back, at its own pace:
##
##   ox_cart      a two-wheeled cart of turnips and sacks behind an ox, the carter on the bench
##   wagon        a felt-topped caravan wagon behind a pair of horses
##   coach        the post-coach, lacquered blue, which runs by night too
##   salt_wagon   four wheels and a tarpaulin behind two oxen, the slowest thing on the road
##   barrow       the one-wheeled barrow of the plains with a sail set on it, pushed
##   handcart     a pedlar's handcart, pulled by its shafts
##   sedan        a curtained chair on two poles between two bearers
##   packtrain    three laden pack-horses on a lead
##   rider        a courier at a canter with a satchel of the post, who rides by night
##   banner_cart  a sect's cart with its banner up (only in the Rivers and Lakes: sects.gd)
##
## **Nothing is placed in the world and nothing is thrown for.**  The fleet of a realm (`fleet`) is
## read from its roads the first time it is asked: so many vehicles to a stretch by its length, the
## kind of each from the stretch and its number.  Where a vehicle is (`where`) is a function of the
## fleet and the clock alone: the day-vehicles go by the hours of daylight that have passed
## (`daylight`), so that at dusk each stands where it had got to, lantern lit, and goes on at dawn; the
## coach and the courier go by the clock itself.  A cart does not drive into a raid on the road
## (raids.gd `blocked`): it is held a few tiles short of it until the raid is broken or the watch ends.
##
## They are drawn by the world round where he is (`World._traffic_tick`: only with a window, only the
## ones near enough to be made out), wait for him if he stands in the road, and are in nobody's way:
## the bot's journey is the same.

const KINDS := {
	"ox_cart": {"n": "an ox-cart", "pace": 1.0, "w": 5, "night": false, "ride": "ox_cart", "crew": [["folk_farmer", Vector3(-0.38, 1.48, 0.7), "sit_bench"]]},
	"wagon": {"n": "a caravan wagon", "pace": 1.6, "w": 3, "night": false, "ride": "wagon", "crew": [["folk_merchant", Vector3(-0.45, 1.54, 1.5), "sit_bench"], ["folk_youth", Vector3(0.45, 1.54, 1.5), "sit_bench"]]},
	"coach": {"n": "the post-coach", "pace": 2.4, "w": 2, "night": true, "ride": "carriage", "high": true, "crew": [["folk_guard", Vector3(-0.38, 1.7, 1.3), "sit_bench"]]},
	"salt_wagon": {"n": "a salt wagon", "pace": 0.8, "w": 2, "night": false, "crew": [["folk_porter", Vector3(-0.4, 1.5, 1.55), "sit_bench"]]},
	"barrow": {"n": "a sailing barrow", "pace": 0.9, "w": 4, "night": false, "crew": [["folk_farmer", Vector3(0, 0, -1.55), "walk"]]},
	"handcart": {"n": "a pedlar's handcart", "pace": 0.85, "w": 4, "night": false, "crew": [["folk_merchant", Vector3(0, 0, 1.75), "walk"]]},
	"sedan": {"n": "a sedan chair", "pace": 1.1, "w": 2, "night": false, "crew": [["folk_porter", Vector3(0, 0, 1.75), "walk"], ["folk_porter", Vector3(0, 0, -1.75), "walk"]]},
	"packtrain": {"n": "a pack-train", "pace": 1.2, "w": 3, "night": false, "crew": [["folk_herder", Vector3(0.5, 0, 2.6), "walk"]]},
	"rider": {"n": "a courier of the post", "pace": 3.2, "w": 2, "night": true, "high": true, "crew": [["folk_youth", Vector3(0, 1.18, -0.1), "sit_bench"]]},
	"banner_cart": {"n": "a sect's banner-cart", "pace": 1.3, "w": 4, "night": false, "only": "lakes", "crew": [["folk_guard", Vector3(0, 1.42, 0.75), "sit_bench"]]},
}
const ORDER := ["ox_cart", "wagon", "coach", "salt_wagon", "barrow", "handcart", "sedan", "packtrain", "rider", "banner_cart"]
## tiles of road to a vehicle, and the most a stretch carries
const SPACING := 55
const MOST := 5
## the least stretch that carries anything (tiles)
const LEAST := 24
## seconds a vehicle stands at each end before it turns round
const REST := 40.0
## how far short of a raid on the road a vehicle is held (tiles)
const HELD := 4
## what the driver of each says when he is stopped in front of (sixty-four letters at most)
const SAID := {
	"ox_cart": "Turnips for market. Mind the ox; he is thinking.", "wagon": "Felt and tea from the sand road. We stop for wells only.",
	"coach": "The post, friend. Stand clear: she keeps to the hour.", "salt_wagon": "Salt. Forty jin a sack, and every jin of it taxed twice.",
	"barrow": "The wind does half. I only steer and swear.", "handcart": "Needles, thread, a comb? No? Then mind my wheel.",
	"sedan": "Make way. No, we may not say who is in it.", "packtrain": "Three horses and each thinks she is the first.",
	"rider": "Post! Post! Out of the road!", "banner_cart": "The sect's own cart. Look at the banner, then look away.",
}

static var _fleets := {}

static func forget() -> void:
	_fleets = {}

## The hours of daylight that have passed on the clock of `g` since the first midnight (minutes): what a
## day-vehicle has had to travel in.
static func daylight(clock: float) -> float:
	var day_len := (Clock.DUSK - Clock.DAWN) * 60.0
	var days := floorf(clock / Clock.DAY)
	var m := fposmod(clock, Clock.DAY)
	return days * day_len + clampf(m - Clock.DAWN * 60.0, 0.0, day_len)

## The vehicles of realm `layer`: [{id, kind, line (index into the road's lines), len, off, pace}].  Read from the
## roads once; a realm with no towns has no road and no traffic.
static func fleet(layer: String) -> Array:
	if _fleets.has(layer):
		return _fleets[layer]
	var out: Array = []
	if not layer.begins_with("f:"):
		var lines: Array = Roads.of(layer).get("lines", [])
		var pool: Array = []
		for k in ORDER:
			if str(KINDS[k].get("only", layer)) == layer:
				for _w in int(KINDS[k].w):
					pool.append(k)
		for li in lines.size():
			var ln: Dictionary = lines[li]
			var n: int = (ln.pts as Array).size()
			if n < LEAST:
				continue
			var lane: bool = bool(ln.get("lane", false))
			var many := clampi(n / SPACING + (0 if lane else 1), 1, MOST)
			for i in many:
				var h := absi(hash("%s|%d|%d" % [layer, li, i]))
				var kind: String = pool[(li * 7 + i * 5 + h % 3) % pool.size()]
				# (a realm's own kind of vehicle, a sect's banner-cart, leads on every stretch of its high road)
				for ko in ORDER:
					if KINDS[ko].has("only") and str(KINDS[ko].only) == layer and i == 0 and not lane:
						kind = ko
				# (the coach and the courier keep to the high road between towns)
				if lane and bool(KINDS[kind].get("high", false)):
					kind = "ox_cart" if i % 2 == 0 else "handcart"
				out.append({"id": "%s:%d:%d" % [layer, li, i], "kind": kind, "line": li, "len": n, "off": float(h % 9973) / 9973.0, "pace": float(KINDS[kind].pace), "seed": h})
	_fleets[layer] = out
	return out

## How far along its stretch vehicle `v` is at `clock` (the game's clock, minutes) and `playtime` (seconds):
## {"k": tiles from the stretch's first end (fractional), "fwd": going from the first end to the last,
## "moving": under way}.  `blocked`: tiles of the road a raid stands on.
static func along(v: Dictionary, clock: float, playtime: float, blocked: Dictionary = {}) -> Dictionary:
	var kd: Dictionary = KINDS[str(v.kind)]
	var night_ok: bool = bool(kd.night)
	# seconds this vehicle has had to travel in
	var tsec := playtime if night_ok else daylight(clock) / Clock.DAY_RATE
	var span := float(int(v.len) - 1)
	var leg := span / float(v.pace) + REST
	var ph := fposmod(tsec + float(v.off) * 2.0 * leg, 2.0 * leg)
	var fwd := ph < leg
	var u := ph if fwd else ph - leg
	var run := span / float(v.pace)
	var k := clampf(u / run, 0.0, 1.0) * span
	if not fwd:
		k = span - k
	var moving := u < run and (night_ok or not Clock.is_night(fposmod(clock, Clock.DAY) / 60.0))
	if not blocked.is_empty():
		var pts: Array = Roads.of(str(v.id).get_slice(":", 0)).lines[int(v.line)].pts
		for bi in pts.size():
			if not blocked.has(pts[bi]):
				continue
			# (held short of the raid on the side it was coming from)
			if fwd and k > float(bi - HELD) and k < float(bi + 1):
				k = maxf(0.0, float(bi - HELD))
				moving = false
			elif not fwd and k < float(bi + HELD) and k > float(bi - 1):
				k = minf(span, float(bi + HELD))
				moving = false
	return {"k": k, "fwd": fwd, "moving": moving}

## Where vehicle `v` is: {"pos": tiles (fractional, the middle of a tile is +0.5), "dir": the way it faces,
## "moving", "tile": the tile it is on}.
static func where(v: Dictionary, clock: float, playtime: float, blocked: Dictionary = {}) -> Dictionary:
	var pts: Array = Roads.of(str(v.id).get_slice(":", 0)).lines[int(v.line)].pts
	var a := along(v, clock, playtime, blocked)
	var i := clampi(int(floor(float(a.k))), 0, pts.size() - 2)
	var f := clampf(float(a.k) - float(i), 0.0, 1.0)
	var p0 := Vector2(pts[i]) + Vector2(0.5, 0.5)
	var p1 := Vector2(pts[i + 1]) + Vector2(0.5, 0.5)
	# (the way it faces is taken over a few tiles, so that it does not twitch at every corner of the paving)
	var j0 := clampi(i - 2, 0, pts.size() - 1)
	var j1 := clampi(i + 3, 0, pts.size() - 1)
	var dir := (Vector2(pts[j1]) - Vector2(pts[j0])).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(1, 0)
	if not bool(a.fwd):
		dir = -dir
	return {"pos": p0.lerp(p1, f), "dir": dir, "moving": bool(a.moving), "tile": pts[i + (1 if f >= 0.5 else 0)]}

## The vehicles of realm `layer` within `reach` tiles of `at`, with where each is.
static func near(layer: String, at: Vector2, reach: float, clock: float, playtime: float, blocked: Dictionary = {}) -> Array:
	var out: Array = []
	for v in fleet(layer):
		var w := where(v, clock, playtime, blocked)
		if absf(w.pos.x - at.x) <= reach and absf(w.pos.y - at.y) <= reach:
			out.append({"v": v, "w": w})
	return out

## How many of each kind go along the roads of realm `layer`.
static func census(layer: String) -> Dictionary:
	var out := {}
	for v in fleet(layer):
		out[str(v.kind)] = int(out.get(str(v.kind), 0)) + 1
	return out
