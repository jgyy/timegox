class_name Habits
extends RefCounted
## The hours of the wild (the Hundred Works release): monsters keep hours too.
##
## Until this release a pack of wolves stood in its clearing at noon exactly as it stood there at
## midnight.  Now every kind of monster has a **habit** (when it is abroad) and, by the clock
## (clock.gd), an **activity** (what it is doing this hour), and both are seen in the land and felt
## in the battle:
##
##   day      birds, apes, qilin, carp, growing things: up with the dawn chorus, feeding morning and
##            afternoon, resting through the heat of noon, flocking to roost at dusk, asleep at night
##   night    ghosts, moths, spiders, foxes, wisps of the dark, everything dead: asleep in whatever
##            shade there is by day, stirring at dusk, hunting from evening until the small hours,
##            and gathering to revel at midnight
##   dusk     the hunters of the half-light (wolves and tigers, serpents, scorpions, crabs, mantises):
##            they hunt at dawn and at dusk, feed by morning and evening, and sleep at noon and in
##            the dead of night
##   tide     the things with no day of their own (golems, slimes, bandits who post a watch, spirits
##            of fire and water): they keep watch by day and drift by night, and never truly sleep
##
## What an activity does (ACTS):
##
##   asleep    the pack lies down and does not wander; walk in on it and the party moves before
##             anything is on its feet (and the sword in the land, F, still reels it)
##   hunting   the pack ranges wide and fast and sees the party first: it is in its strength, its
##             blows land harder and, unless the party struck first in the land, it moves first; it
##             is worth more to beat
##   basking   slow in the heat: it moves last and hits a little softer
##   gathered  roosting or revelling together: each stands up to a good deal more, and is worth more
##
## Taken over a whole day the wild is no easier than it was when it kept no hours: what is gained on
## a pack asleep is paid for on one met hunting or gathered.  It is a reason to look at the clock
## before walking into a wood, not a discount.
##   foraging, on watch, drifting: as before
##
## The story holds the clock here and there, and the wild is held with it: for the nine days the sun
## stood at noon (Part IX) nothing of the night ever woke, and on the last night of the year
## (Part XVI) nothing of the night ever slept.
##
## Everything is a pure function of the hour and the monster, so the bot, the tests and the
## screenshots see the same wild.  Bosses keep no hours: they wait for the story.

const HABITS := {
	"day": {"n": "of the day", "desc": "abroad by day, asleep at night"},
	"night": {"n": "of the night", "desc": "asleep by day, hunting after dark"},
	"dusk": {"n": "of the half-light", "desc": "hunting at dawn and dusk, asleep at noon and in the dead of night"},
	"tide": {"n": "of no hour", "desc": "on watch by day, drifting by night, never asleep"},
}
const HABIT_ORDER := ["day", "night", "dusk", "tide"]

## what each shape of monster is by nature (a species may say otherwise: OWN)
const BY_SHAPE := {
	"bird": "day", "phoenix": "day", "ape": "day", "qilin": "day", "carp": "day", "plant": "day", "mushroom": "night",
	"mammoth": "day", "magpie": "day", "sun_crow": "day", "tortoise": "day", "mantis": "dusk", "ray": "day",
	"wraith": "night", "moth": "night", "spider": "night", "fox": "night", "jiangshi": "night", "demon": "night",
	"jade_rabbit": "night", "jelly": "night",
	"beast": "dusk", "tiger": "dusk", "serpent": "dusk", "scorpion": "dusk", "crab": "dusk", "dragon": "dusk",
	"golem": "tide", "blob": "tide", "humanoid": "tide", "storm": "tide", "tome": "tide", "hundun": "tide", "wisp": "tide",
	"warden": "tide", "queen": "tide", "oxhead": "night", "horseface": "night", "bifang": "day", "kaiming": "day", "ox": "day",
}
## an element decides for the shapes that could be anything: a wisp of the dark is a thing of the
## night, a wisp of fire one of the day
const WISP_BY_ELEM := {"dark": "night", "fire": "day", "thunder": "day", "wood": "day", "water": "tide", "earth": "tide", "phys": "tide"}
## species that keep hours of their own, against their shape
const OWN := {
	# (the Lost Horse release: the tide keeps the tide's hours)
	"tide_horse": "tide", "tide_mare": "tide", "spring_colt": "tide",
	"bamboo_wolf": "dusk", "bandit": "tide", "ash_moth": "dusk", "spark_swallow": "day", "smoke_hound": "night",
	"drowned_ember": "night", "damp_smoke": "night", "wildfire_sprite": "tide",
}

## What a pack may be doing: the word for it, a line for the hint and the bestiary, how it stands in
## the land ([how far it ranges, how fast, the share of the time it is on the move]) and what it
## changes in a battle.
const ACTS := {
	"sleep": {"n": "asleep", "word": "Asleep", "hint": "Asleep: walk in and the party moves first",
		"range": [0.0, 0.0, 0.0], "lie": true, "first": "party", "col": Color("9ab0e0")},
	"rouse": {"n": "stirring", "word": "Stirring", "hint": "Just waking, and hungry: slow to move, but it stands up to more",
		"range": [0.5, 0.5, 0.3], "spd": 0.8, "hp": 1.08, "col": Color("c8c0e0")},
	"forage": {"n": "foraging", "word": "Foraging", "hint": "Feeding: it has not seen you",
		"range": [1.0, 1.0, 0.62], "col": Color("b8e0a0")},
	"hunt": {"n": "hunting", "word": "Hunting", "hint": "Hunting: it hits harder and moves first unless you strike first (F or G); worth more",
		"range": [1.9, 1.9, 0.9], "atk": 1.15, "hp": 1.12, "first": "foe", "exp": 1.15, "run": true, "col": Color("ff8a6a")},
	"bask": {"n": "resting in the heat", "word": "Resting", "hint": "Resting through the heat: it moves last and hits a little softer",
		"range": [0.3, 0.4, 0.15], "atk": 0.95, "spd": 0.7, "col": Color("f0d890")},
	"gather": {"n": "gathered", "word": "Gathered", "hint": "Gathered together: each stands up to a good deal more, and is worth more",
		"range": [1.0, 0.6, 1.0], "hp": 1.2, "exp": 1.1, "ring": true, "col": Color("d8a8ff")},
	"watch": {"n": "on watch", "word": "On watch", "hint": "On watch: as ready as it will ever be",
		"range": [0.8, 0.8, 0.5], "col": Color("e0e0e0")},
	"drift": {"n": "drifting", "word": "Drifting", "hint": "Drifting with the night: slow to turn, hard to put down",
		"range": [1.4, 0.5, 0.9], "spd": 0.9, "hp": 1.08, "col": Color("a8d0e8")},
}

## What each habit does in each part of the day (Clock.part).
const DAYS := {
	"day": {"dawn": "forage", "morning": "forage", "noon": "bask", "afternoon": "forage", "dusk": "gather", "evening": "sleep", "night": "sleep", "late night": "sleep"},
	"night": {"dawn": "sleep", "morning": "sleep", "noon": "sleep", "afternoon": "sleep", "dusk": "rouse", "evening": "hunt", "night": "gather", "late night": "hunt"},
	"dusk": {"dawn": "hunt", "morning": "forage", "noon": "sleep", "afternoon": "bask", "dusk": "hunt", "evening": "forage", "night": "sleep", "late night": "sleep"},
	"tide": {"dawn": "watch", "morning": "watch", "noon": "watch", "afternoon": "watch", "dusk": "watch", "evening": "drift", "night": "drift", "late night": "drift"},
}

## The habit of monster `id` (a Data.ENEMIES key).
static func habit(id: String) -> String:
	if OWN.has(id):
		return str(OWN[id])
	var d: Dictionary = Data.ENEMIES.get(id, {})
	var shape := str(d.get("shape", "")).get_slice(":", 0)
	if shape == "wisp":
		return str(WISP_BY_ELEM.get(str(d.get("elem", "")), "tide"))
	if shape == "person":
		return "tide"
	return str(BY_SHAPE.get(shape, "tide"))

## What a monster of habit `hb` is doing at hour `h` (0..24).
static func act_at(hb: String, h: float) -> String:
	return str(DAYS.get(hb, DAYS.tide).get(Clock.part(h), "watch"))

## What monster `id` is doing by the clock of game state `g` (bosses keep no hours: "watch").
static func act(g, id: String) -> String:
	if bool(Data.ENEMIES.get(id, {}).get("boss", false)):
		return "watch"
	return act_at(habit(id), Clock.hour(g))

## What the pack `group` (an "enemy" entity's group: [{id, lv}...]) is doing: its leader decides.
static func act_of_group(g, group: Array) -> String:
	if group.is_empty():
		return "watch"
	return act(g, str(group[0].id))

static func info(a: String) -> Dictionary:
	return ACTS.get(a, ACTS.watch)

## A number an activity changes in battle ("atk", "hp", "spd", "exp"): 1 if it has nothing to say.
static func mod(a: String, key: String) -> float:
	return float(info(a).get(key, 1.0))

## Who has the first round because of the hour ("party", "foe" or "").
static func first(a: String) -> String:
	return str(info(a).get("first", ""))

## "Wolf: of the half-light (hunting at dawn and dusk, asleep at noon and in the dead of night). Now: hunting."
static func line(g, id: String) -> String:
	var hb := habit(id)
	return "A creature %s: %s. Now: %s." % [str(HABITS[hb].n), str(HABITS[hb].desc), str(info(act(g, id)).n)]

## The hours (whole, 0..23) at which a monster of habit `hb` is asleep, as "22-4, 11-13" for the bestiary.
static func sleeps(hb: String) -> String:
	var spans: Array = []
	var start := -1
	for i in 49:
		var asleep := act_at(hb, float(i % 24) + 0.5) == "sleep" and i < 48
		if asleep and start < 0:
			start = i
		elif not asleep and start >= 0:
			if i - start < 24 and start < 24:
				spans.append("%d-%d" % [start % 24, i % 24])
			start = -1
	# a night's sleep that began before midnight is one span, not two
	var out: Array = []
	for s in spans:
		if not out.has(s) and not (str(s).begins_with("0-") and spans.any(func(o): return str(o).ends_with("-" + str(s).get_slice("-", 1)) and o != s)):
			out.append(s)
	return "never" if out.is_empty() else ", ".join(out)
