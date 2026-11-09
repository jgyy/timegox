class_name Clock
extends RefCounted
## The hours of the day (the Living Land release).  The world keeps a clock now: the sun rises in the
## east and sets in the west, the sky goes through dawn, day, dusk and a moonlit night, lanterns and
## windows glow after dark, and the people of the towns (folk.gd) live by it: up at dawn, at work by
## day, home at dusk and asleep at night, while the watchmen walk the streets calling the watches.
##
## The clock counts minutes of the day (`Game.clock`, 0..1440) and days (`Game.day`).  By day it runs
## at a minute of the day for every second of play and by night twice as fast, so a whole day takes
## a little under twenty minutes of play and a night about four and a half.  The hours are the twelve
## double-hours of the old reckoning, each named for its animal: the Hour of the Rat is midnight.
##
## The story can stop it (in Part IX the sun stood at noon for nine days, and now it does on screen
## too) or set it (Part XVI's New Year's Eve).  Everything here is a pure function of the game state
## `g` (the Game autoload in play, a game state of its own in the tests), so the bot, the tests and
## the screenshots all see the same hour.

const DAY := 1440.0
## a new game begins at seven in the morning: the Hour of the Dragon
const START := 7.0 * 60.0
## minutes of the day per second of play, by day and by night
const DAY_RATE := 1.0
const NIGHT_RATE := 2.0
## the night runs from dusk to dawn (hours)
const DUSK := 19.5
const DAWN := 5.0
## sunrise and sunset (the sun is up between them)
const RISE := 5.6
const SET := 18.9
## the twelve double-hours: [animal, branch]; the Hour of the Rat runs from 23:00 to 1:00
const SHICHEN := [["Rat", "Zi"], ["Ox", "Chou"], ["Tiger", "Yin"], ["Rabbit", "Mao"], ["Dragon", "Chen"], ["Snake", "Si"],
	["Horse", "Wu"], ["Goat", "Wei"], ["Monkey", "Shen"], ["Rooster", "You"], ["Dog", "Xu"], ["Pig", "Hai"]]
## the watches of the night the watchmen call (geng): first to fifth, from 19:00 to 5:00
const WATCHES := ["first", "second", "third", "fourth", "fifth"]

## How strongly each region's sky follows the hours: 1 is the whole of day and night; less for the
## places whose light is not the sun's (the void, the chaos before the world, the land of the dead, the
## caverns under the roots, the Moon Palace, the River of Time).  Missing themes follow fully.
const CYCLE := {"void": 0.35, "chaos": 0.3, "origin": 0.5, "time": 0.4, "celestial": 0.6, "diyu": 0.45, "lilies": 0.6,
	"guanghan": 0.35, "ninesprings": 0.55, "youdu": 0.4, "starpalace": 0.5, "abyss": 0.55, "palace": 0.6, "loom": 0.7}

## Minutes of the day per second of play at minute `m`.
static func rate(m: float) -> float:
	var h := fposmod(m, DAY) / 60.0
	return NIGHT_RATE if h >= DUSK or h < DAWN else DAY_RATE

## The hour (0..24, fractional) on the clock of `g`.
static func hour(g) -> float:
	return fposmod(float(g.clock), DAY) / 60.0

## Why the clock stands still, or "" while it runs: in Part IX the sun would not set for nine days
## (from the Elder's word until Xihe falls).
static func frozen(g) -> String:
	if g.reached("s_p9_home") and not g.done("s_gh_xihe"):
		return "noon"
	# Part XVI: Xi has eaten the hours with the light, and the last night of the year will not end
	# until the year itself is driven out (from the reunion dinner until Nian is gone)
	if g.done("s_p16_eve") and not g.done("s_p16_nian"):
		return "night"
	return ""

## Advance the clock of `g` by `d` seconds of play.
static func advance(g, d: float) -> void:
	var fr := frozen(g)
	if fr == "noon":
		g.clock = 12.0 * 60.0
		return
	if fr == "night":
		return
	var before: float = g.clock
	g.clock = before + d * rate(before)
	while g.clock >= DAY:
		g.clock -= DAY
		g.day += 1

## Set the clock of `g` to hour `h` (0..24); passing midnight on the way starts a new day.
static func set_hour(g, h: float) -> void:
	var m := fposmod(h, 24.0) * 60.0
	if m < float(g.clock):
		g.day += 1
	g.clock = m

## Hours the story sets when a step is done (step id -> hour).  When Xihe and Chang'e agree to take
## turns, the sun goes down for the first time in nine days.
## Part XVI: the reunion dinner ends at nine on New Year's Eve; the vigil runs to ten to midnight;
## Nian goes and the old year with it, and the new one dawns; the bell is rung at sunrise; once the
## lantern riddles are guessed it is the evening of the Lantern Festival, and every lantern is lit.
const STORY_HOURS := {"s_gh_xihe": 18.6, "s_p16_eve": 21.2, "s_p16_vigil": 23.8, "s_p16_nian": 5.4, "s_p16_dawn": 6.3, "s_p16_riddles": 19.8}

static func story_hour(g, sid: String) -> void:
	if STORY_HOURS.has(sid):
		set_hour(g, float(STORY_HOURS[sid]))

## A night's sleep in a bed: from dusk on (or in the small hours) Lin Feng sleeps until six in the
## morning.  Returns whether the night went by.
static func sleep(g) -> bool:
	var h := hour(g)
	if h < DUSK - 1.0 and h >= 4.0:
		return false
	set_hour(g, 6.0)
	return true

## The double-hour (0 = Rat .. 11 = Pig) at hour `h`.
static func shichen(h: float) -> int:
	return int(fposmod(h + 1.0, 24.0) / 2.0) % 12

## "Hour of the Dragon"
static func shichen_name(h: float) -> String:
	return "Hour of the %s" % SHICHEN[shichen(h)][0]

## "7:20"
static func hm(h: float) -> String:
	var mins := int(floor(fposmod(h, 24.0) * 60.0))
	return "%d:%02d" % [int(mins / 60), mins % 60]

## Which watch of the night it is (0..4), or -1 by day.
static func watch(h: float) -> int:
	if h >= 19.0:
		return int((h - 19.0) / 2.0)
	if h < 5.0:
		return int((h + 5.0) / 2.0)
	return -1

## What part of the day it is, for people's words: "dawn", "morning", "noon", "afternoon", "dusk",
## "evening", "night", "late night".
static func part(h: float) -> String:
	if h < 4.0:
		return "late night"
	if h < 6.5:
		return "dawn"
	if h < 11.0:
		return "morning"
	if h < 13.5:
		return "noon"
	if h < 17.5:
		return "afternoon"
	if h < 19.5:
		return "dusk"
	if h < 22.0:
		return "evening"
	return "night"

static func is_night(h: float) -> bool:
	return h >= DUSK or h < DAWN

## How much daylight there is (0 at night, 1 by day), easing through dawn and dusk.
static func daylight(h: float) -> float:
	var up := smoothstep(RISE - 0.9, RISE + 1.2, h)
	var down := 1.0 - smoothstep(SET - 0.9, SET + 0.9, h)
	return clampf(minf(up, down), 0.0, 1.0)

## How warm the light is: 1 at sunrise and sunset, 0 at noon and in the dead of night.
static func golden(h: float) -> float:
	var a := 1.0 - clampf(absf(h - (RISE + 0.5)) / 1.5, 0.0, 1.0)
	var b := 1.0 - clampf(absf(h - (SET - 0.2)) / 1.7, 0.0, 1.0)
	return maxf(a, b)

## The light of the sky at hour `h`: [pitch, yaw] in degrees for the directional light, its energy
## scale and whether it is the moon.  The sun comes up in the east (light travelling west), stands in
## the south at noon and goes down in the west; at night the moon stands high in the south-west.
static func light_angles(h: float) -> Array:
	if h >= RISE - 0.4 and h <= SET + 0.6:
		var k := clampf((h - (RISE - 0.4)) / ((SET + 0.6) - (RISE - 0.4)), 0.0, 1.0)
		var elev := 4.0 + 58.0 * sin(k * PI)
		var yaw := 90.0 - 180.0 * k
		# near the horizon the sun fades out before the moon takes over
		var e := smoothstep(0.0, 0.12, k) * (1.0 - smoothstep(0.88, 1.0, k))
		return [-elev, yaw, 0.25 + 0.75 * e, false]
	# the moon's arc: up from the east after dusk, high at midnight, down to the west before dawn
	var nk := fposmod(h - (SET + 0.6), 24.0) / (24.0 - ((SET + 0.6) - (RISE - 0.4)))
	var melev := 30.0 + 26.0 * sin(clampf(nk, 0.0, 1.0) * PI)
	var myaw := 60.0 - 120.0 * clampf(nk, 0.0, 1.0)
	var me := smoothstep(0.0, 0.1, nk) * (1.0 - smoothstep(0.9, 1.0, nk))
	return [-melev, myaw, 0.2 + 0.8 * me, true]

## "Hour of the Dragon, 7:20, the third day"
static func text(g) -> String:
	var h := hour(g)
	return "%s, %s, day %d" % [shichen_name(h), hm(h), int(g.day)]
