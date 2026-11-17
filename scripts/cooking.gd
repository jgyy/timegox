class_name Cooking
extends RefCounted
## The Small Fish release: a meal is cooked, from laying the fire to licking the bowl.
##
## With a pot on his back (`cook_pot`, of Smith Tie and the pedlars of the road) and what the land gave
## him (toil.gd: a carp, herbs, mushrooms, a yam), **B** in the open, on his feet, with free ground in
## front of him: "Not now" first, then what he has the makings of.  The whole of it is done in front
## of the player, twelve things one after another (`STAGES`), each on a clip the party already carries:
## deadfall is gathered and laid, a spark is struck, the fire is fanned up, water is poured, the board
## comes out and things are cut, they go into the pot one at a time, it comes to the boil, it is
## stirred (or not), salted, tasted, ladled out, and eaten, by both of them.
##
## **The pot is physics** (`step`: a function of the state and the seconds, nothing thrown for): the fire
## burns up towards what it is fed and fanned and dies as its wood goes; the water takes heat from the
## flame by how hot the flame is over it and loses it to the air (Newton's law, both ways), by how much
## water and how much is in it; at the boil what more heat arrives goes off as steam; under a lid the
## steam is pressure, and when the pressure is more than the lid weighs the lid hops and lets it go
## (the Thundering Pots of Part XXIII did the same, less politely); a stirred pot turns, its surface
## dishes by the square of how fast (omega squared r squared over two g), and it runs down by itself
## when the ladle is lifted; and what is in the pot is done by the heat it has had, not by the clock.
##
## **How much it is stirred is the player's** (Enter or Space while it simmers: a turn of the ladle).
## A stew wants turning or it catches; a small fish wants leaving alone, and comes apart at the second
## poke.  That is the whole of the old saying the chapter is named for, and it is the only skill here.
## A meal that came out right mends more (`heal`); one that did not is still eaten.
##
## Nothing is placed in the world: the fire is drawn on the free tile in front of him while it burns and
## is gone when he gets up (kitchen.gd draws it; with no window the meal is three lines).  The story
## asks for it with a step of kind `"cook"` (`n` meals since it began; `dish`: of that kind; `"good":
## true`: that came out right).  The bot cooks what the step wants, turned as it should be.

## what the pot is, and what is bought with it
const POT := "cook_pot"

## dish -> what goes in (goods of load.gd), how many turns of the ladle it wants (`stir`: least, most),
## how much of the party's health and qi it mends when it comes out right, what it does for the body
## (needs.gd), the colour of the broth, and what is said (right; wrong, by too few turns and too many)
const RECIPES := {
	"small_fish": {"n": "A Small Fish, Simmered Whole", "needs": {"carp": 1, "herb_bundle": 1}, "stir": [0, 1], "heal": 0.6, "body": {"hunger": 60.0, "comfort": 15.0}, "col": Color("d8c8a0"),
		"ask": "A carp, a little of what grows low, water, and nothing done to it that need not be.",
		"lines": ["The fish lies whole in the bowl, and the broth is clear to the bottom. He has done almost nothing, and it took all his attention.",
			"It comes out of the pot in one piece, eyes gone white, skin unbroken. Somebody once said a great country should be governed like this.",
			"Whole. He lifts it with two fingers under the head and the flat of the ladle under the tail, as one lifts something asleep."],
		"under": ["It is whole, and raw along the spine. He had the fire too low and lost his nerve. It goes back in, and is eaten late."],
		"over": ["He looked in once too often. There is no fish in the pot now: there is fish in the broth, all through it, and a great many bones.",
			"Turned twice, and the second time it came apart along every seam it had. It tastes of carp. It looks like something a river left."]},
	"mushroom_broth": {"n": "Broth of the Forest's Edge", "needs": {"mushrooms": 2, "herb_bundle": 1}, "stir": [1, 3], "heal": 0.45, "body": {"hunger": 45.0, "thirst": 20.0, "comfort": 10.0}, "col": Color("a88a5a"),
		"ask": "Two handfuls of mushrooms and something green: turned once or twice, so that the bottom does not catch.",
		"lines": ["Brown, clear and smelling of the inside of a wood after rain. The mushrooms have kept their shape and given up everything else.",
			"A broth the colour of weak tea that tastes of a great deal more. He drinks the last of it out of the ladle.",
			"It wants nothing. He adds nothing. That has taken him longer to learn than the Nine Swords."],
		"under": ["Nobody turned it, and the bottom of the pot has kept a share for itself, black. What was above that is good."],
		"over": ["Stirred to a brown porridge. It is hot and there is plenty of it, and nobody will ask what was in it."]},
	"yam_stew": {"n": "Yam and Carp, Stewed Thick", "needs": {"wild_yam": 2, "mushrooms": 1, "carp": 1}, "stir": [2, 5], "heal": 1.0, "body": {"hunger": 95.0, "comfort": 25.0}, "col": Color("c89a58"),
		"ask": "Yam, a carp cut across, a mushroom or two: a thick pot, and a thick pot must be kept moving.",
		"lines": ["Thick enough to stand the ladle in. The yam has gone soft at the edges and thickened everything, as yam will if it is kept moving.",
			"It is the kind of pot a porter dreams of on the third pass of the day. He eats until the ladle scrapes.",
			"Every piece is done and none is burned, which with yam is a matter of not walking away. He did not walk away."],
		"under": ["The yam sat on the bottom and stuck there, and the pot will want sand and an hour at the stream. The top half was good."],
		"over": ["Beaten to a paste. It could mend a wall. It is, he finds, quite good on a wall of bread."]},
	"herb_congee": {"n": "Thin Gruel with Bitter Herbs", "needs": {"herb_bundle": 2}, "stir": [1, 4], "heal": 0.25, "body": {"hunger": 30.0, "thirst": 25.0}, "col": Color("b8c890"),
		"ask": "Herbs, water and patience. What the road eats when the road has nothing.",
		"lines": ["Green, thin and honest. It is what there was, cooked as well as what there was can be.",
			"Bitter on the tongue and warm all the way down. The herbalists of the road live on it and look none the worse.",
			"He has eaten worse at tables with cloths on them."],
		"under": ["It has caught a little. Bitter herbs, burnt, are not improved; but they are not much harmed either."],
		"over": ["Stirred until it gave up being anything. Green water, warm. He drinks it."]},
}
const ORDER := ["small_fish", "mushroom_broth", "yam_stew", "herb_congee"]

## the twelve things done, in order: what it is called, the clip (art/lib/person.py INTERACT: every one
## is already on the party), the seconds, what is held (Props.held), what Yue Ling does, what the fire
## is fed to (`fire`: the flame it burns up towards, 0..1), whether the lid is on, and what is said
const STAGES := [
	{"id": "lay", "n": "Laying the fire", "clip": "gather", "dur": 3.2, "hold": "", "comp": "gather", "fire": 0.0, "lid": false, "said": "Deadfall, dry grass, three stones for the pot to stand on."},
	{"id": "light", "n": "Striking a spark", "clip": "strike", "dur": 2.4, "hold": "flint", "comp": "watch", "fire": 0.25, "lid": false, "said": "Flint on the back of the knife, into the grass. It takes at the third."},
	{"id": "fan", "n": "Fanning it up", "clip": "fan", "dur": 3.0, "hold": "fan_leaf", "comp": "warm", "fire": 0.9, "lid": false, "said": "Fanned low and from the side, until the sticks have it and it will go by itself."},
	{"id": "water", "n": "Pouring the water", "clip": "pour", "dur": 3.0, "hold": "gourd", "comp": "watch", "fire": 0.9, "lid": false, "said": "Water from the gourd, to two fingers under the rim. The pot ticks as it takes the heat."},
	{"id": "chop", "n": "Cutting", "clip": "chop", "dur": 4.2, "hold": "kitchen_knife", "comp": "watch", "fire": 0.8, "lid": true, "said": "The board across his knees. Everything the same size, so that everything is done at once."},
	{"id": "add", "n": "Into the pot", "clip": "toss", "dur": 3.6, "hold": "", "comp": "watch", "fire": 0.8, "lid": false, "said": "In, one piece at a time, from low down, so that nothing splashes that should stay in."},
	{"id": "boil", "n": "Bringing it to the boil", "clip": "warm", "dur": 5.0, "hold": "", "comp": "warm", "fire": 1.0, "lid": true, "said": "The lid on. It mutters, then it rattles, and steam puts a finger out from under the rim."},
	{"id": "simmer", "n": "Simmering", "clip": "stir", "dur": 6.5, "hold": "ladle", "comp": "sit_bench", "fire": 0.45, "lid": false, "said": "A stick pulled out of the fire to bring it down. Now: how much is it to be stirred? (Enter: turn the ladle)"},
	{"id": "season", "n": "Salting", "clip": "squeeze", "dur": 2.2, "hold": "", "comp": "watch", "fire": 0.35, "lid": false, "said": "Salt from the twist of paper, between finger and thumb, from high up so that it falls everywhere."},
	{"id": "taste", "n": "Tasting", "clip": "drink", "dur": 2.6, "hold": "ladle", "comp": "watch", "fire": 0.3, "lid": false, "said": "The ladle, blown on. He looks at nothing while he tastes, as cooks do."},
	{"id": "serve", "n": "Ladling it out", "clip": "serve", "dur": 3.4, "hold": "ladle", "comp": "clap", "fire": 0.2, "lid": false, "said": "Two bowls. The first to whoever is not the cook."},
	{"id": "eat", "n": "Eating", "clip": "eat", "dur": 4.5, "hold": "bowl", "comp": "eat", "fire": 0.1, "lid": false, "said": "They eat without talking, which is the only thing a cook wants to hear."},
]
const SIMMER := 7

static func total_seconds() -> float:
	var s := 0.0
	for st in STAGES:
		s += float(st.dur)
	return s

# ---------------------------------------------------------------- the pot (pure physics)
const AIR := 18.0
const FLAME := 820.0
const G := 9.8
## heat into the water from a full flame, per second and per degree of difference, for a pot with
## nothing but its own iron (the more in it, the slower)
const K_IN := 0.0128
## heat lost to the air, per second and per degree
const K_OUT := 0.012
## what a lid weighs, as the pressure that lifts it; how fast steam builds under it at a full boil, and
## how fast it leaks round the rim
const LID_W := 1.0
const K_STEAM := 1.6
const K_LEAK := 0.25
## how fast the fire comes to what it is fed, and how fast wood is burned at a full flame (a laid fire
## is 1.0 of wood)
const K_FIRE := 1.4
const BURN := 0.012
## how fast a stirred pot comes to the speed of the ladle, and how fast it runs down
const K_STIR := 2.6
const K_DRAG := 0.9
## the radius of the pot (metres), for the dish of the surface
const POT_R := 0.26
## seconds at a full simmer for a pot to be done
const DONE_S := 11.0

## A cold pot on a laid fire: nothing lit, no water.
static func pot() -> Dictionary:
	return {"wood": 0.0, "fire": 0.0, "T": AIR, "water": 0.0, "pieces": 0, "done": 0.0, "spin": 0.0, "turn": 0.0, "press": 0.0, "lid_y": 0.0, "lid_v": 0.0, "hops": 0, "steam": 0.0, "boiled": false}

## The pot `s` after `dt` seconds, driven by `drive`: {"fire": what the flame is fed to (0..1), "fan":
## is it being fanned, "lid": is the lid on, "stir": turns of the ladle a second (0 for none)}.  Pure:
## the same state and the same seconds give the same pot.
static func step(s: Dictionary, dt: float, drive: Dictionary) -> Dictionary:
	var o := s.duplicate()
	var feed := float(drive.get("fire", 0.0)) * (1.25 if bool(drive.get("fan", false)) else 1.0)
	# a fire with no wood under it burns towards nothing
	if float(o.wood) <= 0.0:
		feed = 0.0
	o.fire = clampf(float(o.fire) + (feed - float(o.fire)) * (1.0 - exp(-dt * K_FIRE)), 0.0, 1.25)
	o.wood = maxf(0.0, float(o.wood) - float(o.fire) * BURN * dt)
	# the water: heat in by how hot the flame is over it, out to the air; the more in the pot the slower
	var mass := 0.35 + float(o.water) + 0.12 * float(int(o.pieces))
	var T := float(o.T)
	var dT := (float(o.fire) * K_IN * (FLAME - T) - K_OUT * (T - AIR)) / mass
	T += dT * dt
	var over := 0.0
	if float(o.water) > 0.0 and T > 100.0:
		# at the boil the rest goes off as steam
		over = (T - 100.0) / maxf(dt, 1e-6)
		T = 100.0
		o.boiled = true
	o.T = T
	o.steam = clampf((T - 55.0) / 45.0, 0.0, 1.0) * (1.0 if float(o.water) > 0.0 else 0.0)
	# under the lid, steam is pressure; more than the lid weighs, and the lid hops and lets it go
	var lid := bool(drive.get("lid", false))
	if lid:
		o.press = maxf(0.0, float(o.press) + (clampf(over / 8.0, 0.0, 1.0) * K_STEAM - K_LEAK * float(o.press)) * dt)
		if float(o.press) > LID_W and float(o.lid_y) <= 0.0:
			o.lid_v = sqrt(2.0 * G * 0.03 * float(o.press))
			o.press = float(o.press) * 0.35
			o.hops = int(o.hops) + 1
	else:
		o.press = 0.0
	if float(o.lid_y) > 0.0 or float(o.lid_v) > 0.0:
		o.lid_v = float(o.lid_v) - G * dt
		o.lid_y = float(o.lid_y) + float(o.lid_v) * dt
		if float(o.lid_y) <= 0.0:
			# it lands and rings: a third of the speed comes back, until it is too little to see
			o.lid_y = 0.0
			o.lid_v = -float(o.lid_v) * 0.3 if float(o.lid_v) < -0.25 else 0.0
	# the ladle: the pot comes to its speed, and runs down when it is lifted
	var want := float(drive.get("stir", 0.0)) * TAU
	if want != 0.0:
		o.spin = float(o.spin) + (want - float(o.spin)) * (1.0 - exp(-dt * K_STIR))
	else:
		o.spin = float(o.spin) * exp(-dt * K_DRAG)
	o.turn = float(o.turn) + float(o.spin) * dt
	# done by the heat it has had
	if int(o.pieces) > 0:
		o.done = minf(1.2, float(o.done) + clampf((T - 70.0) / 30.0, 0.0, 1.0) * dt / DONE_S)
	return o

## How far the middle of a turning pot lies below its rim (metres): the free surface of a liquid
## turning at `spin` radians a second in a pot of radius POT_R.
static func dish(spin: float) -> float:
	return spin * spin * POT_R * POT_R / (2.0 * G)

## The pot at the end of stage `k`, cooked from cold with `pokes` turns of the ladle at the simmer (what
## the screen shows frame by frame, worked out in thirty steps a second: the tests and the bot ask).
static func run(pokes: int, upto: int = STAGES.size()) -> Dictionary:
	var s := pot()
	for k in mini(upto, STAGES.size()):
		s = enter(s, k, 3)
		var st: Dictionary = STAGES[k]
		var n := int(round(float(st.dur) * 30.0))
		for i in n:
			var stir := 0.0
			if k == SIMMER and pokes > 0:
				# each turn of the ladle is a second of stirring, spread along the simmer
				var ph := float(i) / float(n) * float(pokes)
				stir = 0.8 if ph - floorf(ph) < minf(1.0, float(pokes) * 30.0 / float(n)) else 0.0
			s = step(s, 1.0 / 30.0, {"fire": float(st.fire), "fan": str(st.id) == "fan", "lid": bool(st.lid), "stir": stir})
	return s

## What beginning stage `k` does to the pot at once: wood laid, water poured, `pieces` things put in.
static func enter(s: Dictionary, k: int, pieces: int) -> Dictionary:
	var o := s.duplicate()
	match str(STAGES[k].id):
		"lay":
			o.wood = 1.0
		"water":
			# (cold water into hot iron: the two come to one heat between them)
			o.T = (minf(float(o.T), 300.0) * 0.35 + AIR * 0.8) / 1.15
			o.water = 0.8
		"add":
			o.pieces = pieces
	return o

# ---------------------------------------------------------------- the rules
## How many pieces of dish `id` go into the pot.
static func pieces_of(id: String) -> int:
	var n := 0
	for k in RECIPES[id].needs:
		n += int(RECIPES[id].needs[k])
	return n

## What dish `id` still wants that he has not got: good -> how many.
static func missing(g, id: String) -> Dictionary:
	var out := {}
	for k in RECIPES[id].needs:
		var short := int(RECIPES[id].needs[k]) - int(g.inv.get(str(k), 0))
		if short > 0:
			out[str(k)] = short
	return out

## Why dish `id` cannot be cooked now ("" if it can).
static func blocked(g, id: String) -> String:
	if not RECIPES.has(id):
		return "There is no such dish."
	if int(g.inv.get(POT, 0)) <= 0:
		return "Nothing to cook in (%s: the pedlars of the road sell one, and Smith Tie)." % str(Data.ITEMS[POT].n).to_lower()
	var ms := missing(g, id)
	if not ms.is_empty():
		var parts: Array = []
		for k in ms:
			parts.append("%d %s" % [int(ms[k]), str(Data.ITEMS[str(k)].n).to_lower()])
		return "%s wants %s more." % [str(RECIPES[id].n), ", ".join(parts)]
	return ""

## The dishes he has the makings of now.
static func ready(g) -> Array:
	var out: Array = []
	for id in ORDER:
		if blocked(g, id) == "":
			out.append(id)
	return out

## How dish `id` comes out with `pokes` turns of the ladle: "good", "under" or "over".
static func outcome(id: String, pokes: int) -> String:
	var st: Array = RECIPES[id].stir
	return "under" if pokes < int(st[0]) else ("over" if pokes > int(st[1]) else "good")

## The turns of the ladle the dish wants (what the bot gives it).
static func ideal(id: String) -> int:
	return int(RECIPES[id].stir[0])

## Dish `id` has been cooked with `pokes` turns of the ladle: what went into it is gone, the party is
## mended by it, the body fed, and a step that asked for a meal hears of it.  Returns the lines to tell.
static func done(g, id: String, pokes: int) -> Array:
	var rc: Dictionary = RECIPES[id]
	for k in rc.needs:
		g.inv[str(k)] = int(g.inv.get(str(k), 0)) - int(rc.needs[k])
		if int(g.inv[str(k)]) <= 0:
			g.inv.erase(str(k))
	var how := outcome(id, pokes)
	var n: int = int(g.cooked.get(id, 0))
	g.cooked[id] = n + 1
	g.cooked_n += 1
	var told: Array = rc.lines if how == "good" else rc[how]
	var out: Array = [str(told[n % told.size()])]
	var share := float(rc.heal) * (1.0 if how == "good" else 0.5)
	if how == "good":
		g.cooked_good += 1
	for i in g.party_size():
		g.hp[i] = minf(float(g.max_hp(i)), float(g.hp[i]) + float(g.max_hp(i)) * share)
		g.qi[i] = minf(float(g.max_qi(i)), float(g.qi[i]) + float(g.max_qi(i)) * share)
	out.append("%s: %s (health and qi mended by %d%%)" % [str(rc.n), {"good": "as it should be", "under": "caught on the bottom", "over": "stirred to pieces"}[how], int(round(share * 100.0))])
	if Needs.on(g):
		Needs.give(g, rc.body)
	var s: Dictionary = g.cur_step()
	if not s.is_empty() and str(s.kind) == "cook" and (not s.has("dish") or str(s.dish) == id) and (how == "good" or not bool(s.get("good", false))):
		g.step_cook += 1
		g.poll_steps()
	return out

## The dish a "cook" step wants, or the first there is.
static func wanted(s: Dictionary) -> String:
	return str(s.get("dish", ORDER[0]))
