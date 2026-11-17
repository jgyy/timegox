class_name Almanac
extends RefCounted
## The almanac (the Ordered House release).  The days were counted before; now they have names, and
## things happen in them that are not Lin Feng's doing.
##
## **The date.**  A year is twelve months of thirty days, four seasons and twenty-four solar terms; the
## journey begins on the second day of the second month (the Dragon Raises Its Head) of the Year of
## the Wood Dragon.  The date is `Game.day` plus `Game.cal`, an offset the story moves forward when a
## chapter is set on a day of the year (Part XVI's New Year's Eve, the Lantern Festival, Qingming):
## weeks on the road that nobody played.  `STORY_DATES` holds them, beside Clock.STORY_HOURS.
##
## **What the days do**, on the side of the people:
##  * the Roll of the Outer Court: eight fellow disciples of Azure Cloud cultivate whether or not he
##    does, each at a pace of their own (`ROLL`, `rival_level`); where he stands among them decides the
##    stipend the sect sends him on the first of every month (`stipend`, `poll`);
##  * every grown townsperson rises in what they do as the days go by (`craft_rank`, `craft_line`):
##    new to it, learning, a steady hand, a master, the best in the street;
##  * the season is in what people say (`season_line`), and the feast days are kept (`festival`).
## and on the side of the wild:
##  * a pack that is left alone grows (`stage`, `grown`): from the day it was first met, or last put
##    down, it settles (a level), breeds (another head) and grows old (two levels, an elder at its
##    head, a harder blow).  What it is worth grows with it.  Lords keep no calendar.
##
## Everything here is a pure function of the game state `g`; the only state kept is `g.cal`,
## `g.pack_day` (pack -> the day its clock began), `g.cal_month` (the last month a stipend came for) and
## `g.roll_told`.  Nothing is thrown for.

const MONTH := 30
const YEAR := 360
## the journey's first morning: the 2nd day of the 2nd month (day index 31 of the year)
const EPOCH := 31
const MONTHS := ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth", "Eleventh", "Twelfth"]
const SEASONS := ["spring", "summer", "autumn", "winter"]
## the sixty-year cycle is five phases by twelve animals; year one is a Wood Dragon year
const PHASES := ["Wood", "Wood", "Fire", "Fire", "Earth", "Earth", "Metal", "Metal", "Water", "Water"]
const ANIMALS := ["Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig", "Rat", "Ox", "Tiger", "Rabbit"]
## the twenty-four solar terms, fifteen days each, from the first day of the first month
const TERMS := ["Start of Spring", "Rain Water", "Waking of Insects", "Spring Equinox", "Clear and Bright", "Grain Rain",
	"Start of Summer", "Grain Buds", "Grain in Ear", "Summer Solstice", "Lesser Heat", "Greater Heat",
	"Start of Autumn", "End of Heat", "White Dew", "Autumn Equinox", "Cold Dew", "Frost's Descent",
	"Start of Winter", "Lesser Snow", "Greater Snow", "Winter Solstice", "Lesser Cold", "Greater Cold"]
## the feast days: [month, day, name, what the street says of it]
const FESTIVALS := [
	[1, 1, "New Year's Day", "A good new year to you, %s! Have you eaten? Nobody sweeps today; you would sweep the luck out."],
	[1, 15, "the Lantern Festival", "Every lantern in the street is lit tonight, %s, and there is a riddle hung on each. I have guessed two. I was told both."],
	[2, 2, "the Dragon Raises Its Head", "Second of the second: the dragon lifts its head, and everybody gets a haircut. Look at mine. No, do not."],
	[3, 5, "Qingming", "We swept the graves this morning, %s, and ate cold food beside them. Grandfather would have complained about the cold food."],
	[5, 5, "the Double Fifth", "Mugwort over the door and rice in a leaf, %s. The boats race at noon. My cousin is in the red one, and cannot swim."],
	[7, 7, "the Night of Sevens", "The Weaver crosses to the Herd-Boy tonight on a bridge of magpies. Have you seen a magpie today, %s? No. Nobody has. There you are."],
	[7, 15, "the Ghost Festival", "We float lamps on the water tonight for the ones with nobody to float them. Do not whistle after dark, %s. Not tonight."],
	[8, 15, "Mid-Autumn", "The moon is at its roundest tonight, %s. We eat cakes and look at it. My mother counts who is at the table. She always counts."],
	[9, 9, "the Double Ninth", "Ninth of the ninth: climb something high, %s, with dogwood in your hair, and drink to whoever is not there to climb it."],
	[12, 8, "Laba", "Eight-treasure porridge today, %s, from eight households' pots. The beggar at the gate had three bowls. So did the magistrate."],
	[12, 30, "New Year's Eve", "Everybody home tonight, %s, and the lamp left burning till morning. Whoever is on the road, we set a bowl for."],
]
## what the street says of the season, when it is nobody's feast day
const SEASON_LINES := {
	"spring": ["The willows are out. My knees said so a week before the willows did.", "Seed is in. Now we wait, and pretend we are not looking at the sky.", "The swallows are back under the eaves, %s. Same pair. She scolds him the same."],
	"summer": ["Hot enough to cook rice on the step. Do not sit there, %s; I have rice on it.", "The cicadas started this week. They will stop when the heat does, and not before.", "We sleep on the roof this month. You hear everybody's quarrels. It is as good as a play."],
	"autumn": ["Harvest is in, and the bins are counted. Ask me in spring whether it was enough.", "The geese went over last night, going south. You could hear them from indoors.", "Persimmons on every sill, %s, getting sweet. Take one. Not that one."],
	"winter": ["The water-jar froze over in the night. I broke the ice with the ladle and the ladle broke.", "Short days. We mend what broke in the long ones.", "The stove eats wood like a guest, %s. Come in, or go out, but shut the door."],
}

## Days of the year the story sets when a step is done: step id -> [month, day].  The calendar moves
## forward to the next such day (never back): weeks on the road nobody played.
const STORY_DATES := {
	# Part XVI: the reunion dinner is eaten on the last night of the year; the riddles are guessed on the fifteenth
	"s_p16_eve": [12, 30], "s_p16_riddles": [1, 15],
	# Part XVII: the first thunder is drummed at the Waking of Insects, the graves are swept at Qingming
	"s_p17_eggs": [2, 2], "s_p17_willow": [3, 5],
	# Part XXIX: the crane comes down on the pillar at the Double Ninth, when people climb high
	"s_p29_feast": [9, 9],
	# Part XXXII: the half-mirror is cried at market on the fifteenth of the first month, under the lanterns
	"s_p32_market": [1, 15],
}

# ---------------------------------------------------------------- the date
## The count of days since the first day of the first month of year one.
static func index(g) -> int:
	return maxi(0, int(g.day) - 1 + int(g.cal) + EPOCH)

static func year(g) -> int:
	return index(g) / YEAR + 1

## 1..12
static func month(g) -> int:
	return (index(g) % YEAR) / MONTH + 1

## 1..30
static func dom(g) -> int:
	return index(g) % MONTH + 1

static func season(g) -> String:
	return SEASONS[(month(g) - 1) / 3]

static func term(g) -> String:
	return TERMS[(index(g) % YEAR) / 15]

## "Wood Dragon"
static func year_name(g) -> String:
	var y := year(g) - 1
	return "%s %s" % [PHASES[y % 10], ANIMALS[y % 12]]

## "3rd of the Second Month"
static func short(g) -> String:
	var d := dom(g)
	return "%d%s of the %s Month" % [d, _th(d), MONTHS[month(g) - 1]]

## "The 3rd of the Second Month, Year of the Wood Dragon: spring, Waking of Insects"
static func text(g) -> String:
	return "The %s, Year of the %s: %s, %s" % [short(g), year_name(g), season(g), term(g)]

static func _th(d: int) -> String:
	if d % 100 >= 11 and d % 100 <= 13:
		return "th"
	return ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][d % 10]

## The feast day it is today ([month, day, name, line]), or [] on an ordinary day.
static func festival(g) -> Array:
	var m := month(g)
	var d := dom(g)
	for f in FESTIVALS:
		if int(f[0]) == m and int(f[1]) == d:
			return f
	return []

## The next feast day and how many days off it is: [name, days].
static func next_festival(g) -> Array:
	var today := index(g) % YEAR
	var best := YEAR + 1
	var name := ""
	for f in FESTIVALS:
		var at := (int(f[0]) - 1) * MONTH + int(f[1]) - 1
		var off := posmod(at - today, YEAR)
		if off == 0:
			off = YEAR
		if off < best:
			best = off
			name = str(f[2])
	return [name, best]

## The story sets the day of the year (STORY_DATES): the calendar moves forward to it.
static func story_date(g, sid: String) -> void:
	if not STORY_DATES.has(sid):
		return
	var md: Array = STORY_DATES[sid]
	var at := (int(md[0]) - 1) * MONTH + int(md[1]) - 1
	g.cal = int(g.cal) + posmod(at - index(g) % YEAR, YEAR)
	# (the weeks the story skipped are not months the sect owes a stipend for)
	g.cal_month = index(g) / MONTH

## What the street says of the day: the feast if it is one, else the season (`seed` picks the line).
static func season_line(g, seed_: int) -> String:
	var f := festival(g)
	if not f.is_empty():
		return str(f[3])
	var pool: Array = SEASON_LINES[season(g)]
	# (main.gd asks with a seed that is a multiple of three whenever it is a grown person's turn to speak of
	# the season: of three lines only the first was ever said, so the thirds are counted too)
	return str(pool[(absi(seed_) + absi(seed_) / 3) % pool.size()])

# ---------------------------------------------------------------- the days, as a number
## The days of the journey as a number with the hour in it (day 3 at noon is 3.5).  Not the calendar:
## what grows by the day grows by days lived, and the weeks the story skips are not counted.
static func now(g) -> float:
	return float(g.day) + float(g.clock) / Clock.DAY

# ---------------------------------------------------------------- the people: the Roll of the Outer Court
## Eight who came up the mountain in the same years he did.  `lv`: where each stood on the journey's first
## morning; `pace`: days to a stage; `cap`: where each one's road ends; `word`: what is said of them.
const ROLL := [
	{"n": "Senior Brother Han Yue", "lv": 7, "pace": 2.2, "cap": 62, "word": "First on the roll for six years. He bows to nobody he has not measured."},
	{"n": "Senior Sister Bai Lu", "lv": 6, "pace": 1.9, "cap": 80, "word": "She does not hurry. She has never been seen to stop, either."},
	{"n": "Brother Shi Dun", "lv": 4, "pace": 3.4, "cap": 44, "word": "Slow as a millstone, and grinds as fine. He was three years at the first stage."},
	{"n": "Sister Qiu Tang", "lv": 3, "pace": 1.6, "cap": 70, "word": "Came up the mountain barefoot with a letter nobody could read. Nobody has asked twice."},
	{"n": "Brother Meng Zhi", "lv": 3, "pace": 2.8, "cap": 36, "word": "He would be further on if he talked less about how far on he is."},
	{"n": "Sister Luo Ying", "lv": 2, "pace": 2.4, "cap": 54, "word": "Sweeps her own cell and three others. She thinks nobody has noticed."},
	{"n": "Brother Pang Hu", "lv": 1, "pace": 4.5, "cap": 24, "word": "Eats for four and meditates for half of one. The kitchen loves him."},
	{"n": "Little Sister An", "lv": 0, "pace": 1.3, "cap": 96, "word": "The youngest on the roll, and the one the Elder watches when he thinks nobody sees."},
]

## The level fellow disciple `i` of the roll has reached by now.
static func rival_level(g, i: int) -> int:
	var r: Dictionary = ROLL[i]
	return mini(int(r.cap), int(r.lv) + int(floor(maxf(0.0, now(g) - 1.0) / float(r.pace))))

## The roll as it stands: [{n, lv, hero, word}], the furthest on first (he stands above an equal).
static func roll(g) -> Array:
	var out: Array = [{"n": g.hero_name(), "lv": int(g.level), "hero": true, "word": ""}]
	for i in ROLL.size():
		out.append({"n": str(ROLL[i].n), "lv": rival_level(g, i), "hero": false, "word": str(ROLL[i].word)})
	out.sort_custom(func(a, b): return int(a.lv) > int(b.lv) or (int(a.lv) == int(b.lv) and bool(a.hero) and not bool(b.hero)))
	return out

## His place on the roll: 1 is first of nine.
static func place(g) -> int:
	var rl := roll(g)
	for i in rl.size():
		if bool(rl[i].hero):
			return i + 1
	return rl.size()

## What the sect sends on the first of the month, by his place on the roll and his realm: the first
## three places draw the full stipend, the last three a third of it.  Worth less than the road.
static func stipend(g) -> int:
	var pl := place(g)
	var k := 1.0 if pl <= 3 else (0.6 if pl <= 6 else 0.34)
	# (creed.gd: half as much again to who keeps the precepts, nothing to a rogue cultivator)
	# (the Open Net release: an outlaw, or somebody found out at a forbidden art, is struck from the roll)
	if Crime.outlaw(g):
		return 0
	return int(round((30.0 + 22.0 * float(g.realm())) * k * Creed.mod(g, "stipend") * Roots.mod(g, "stipend")))

## What a day has brought: the stipend when a month has turned, and word of whoever on the roll has
## reached a new great realm.  Called when the day changes (Game._process) and never asks the screen.
static func poll(g) -> Array:
	var out: Array = []
	if not bool(g.started) or str(g.prologue) != "":
		return out
	var mi := index(g) / MONTH
	if int(g.cal_month) < 0:
		g.cal_month = mi
	elif mi > int(g.cal_month):
		g.cal_month = mi
		var st := stipend(g)
		g.stones += st
		if st > 0:
			g.stipends += 1
		if st <= 0:
			# (an outlaw is struck from the roll whatever rule he keeps: he was told he was a rogue cultivator)
			out.append("The first of the %s Month: no stipend comes. %s" % [MONTHS[month(g) - 1], "His name has been struck from the roll" if Crime.outlaw(g) else "The sect sends nothing to a rogue cultivator"])
		else:
			out.append("The first of the %s Month: the sect's stipend, %d spirit stones (%s on the roll)" % [MONTHS[month(g) - 1], st, _place_word(place(g))])
	for i in ROLL.size():
		var rm := Data.realm_of(rival_level(g, i))
		var key := str(i)
		if not g.roll_told.has(key):
			g.roll_told[key] = rm
		elif rm > int(g.roll_told[key]):
			g.roll_told[key] = rm
			out.append("Word from the mountain: %s has broken through to %s" % [str(ROLL[i].n), Data.REALMS[rm]])
	for t in out:
		g.toast(str(t))
		g.note(str(t))
	return out

static func _place_word(p: int) -> String:
	return ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth"][clampi(p - 1, 0, 8)]

## What somebody of the sect says of the roll: who is just ahead of him, or just behind.
static func roll_line(g) -> String:
	var rl := roll(g)
	var pl := place(g)
	if pl > 1:
		var a: Dictionary = rl[pl - 2]
		return "%s stands just above you on the roll now: %s. %s" % [str(a.n), Data.level_name(int(a.lv)), str(a.word)]
	var b: Dictionary = rl[1]
	return "First on the roll. %s is next, at %s, and has not stopped. %s" % [str(b.n), Data.level_name(int(b.lv)), str(b.word)]

# ---------------------------------------------------------------- the people: a trade is learned by the day
const CRAFT := ["new to it", "learning", "a steady hand", "a master", "the best in the street"]
const CRAFT_LINES := [
	["%d days at it, %s, and I have stopped cutting myself. Mostly. Ask me again at the new moon.", "They let me sweep up and watch. %d days of watching. I am very good at watching."],
	["%d days now. The master has stopped taking the work out of my hands to do it again. He still looks.", "I spoiled less this month than last, %s. That is how you count it, at %d days."],
	["%d days at this, %s. My hands know it now; I can think about supper while they work.", "They send the new ones to me to be shown. %d days ago I was the new one."],
	["%d days, and I have two learners of my own. They are terrible. So was I. I do not tell them that.", "People ask for me by name now, %s. It took %d days, and one very bad winter."],
	["Best in the street, they say. It is only %d days of doing the same thing and minding it, %s.", "%d days. I could do it in the dark. I have: the lamp went out and nobody could tell which was the dark one."],
]

## Where grown townsperson `p` stands in what they do (0..4), by the days gone by: each begins
## somewhere of their own and rises at a pace of their own.  Children do not have a trade yet.
static func craft_rank(p: Dictionary, g) -> int:
	if bool(p.get("kid", false)):
		return 0
	var s := absi(int(p.get("seed", 0)))
	var start := s % 4
	var pace := 5.0 + float((s / 7) % 9)
	return mini(CRAFT.size() - 1, start + int(floor(maxf(0.0, now(g) - 1.0) / pace)))

## The days `p` has been at it: what they began with, and the days of the journey.
static func craft_days(p: Dictionary, g) -> int:
	var s := absi(int(p.get("seed", 0)))
	return (s % 4) * (40 + (s / 11) % 50) + 10 + int(now(g))

static func craft_word(p: Dictionary, g) -> String:
	return CRAFT[craft_rank(p, g)]

## What `p` says of how long they have been at it.
static func craft_line(p: Dictionary, g) -> String:
	var pool: Array = CRAFT_LINES[craft_rank(p, g)]
	var s := str(pool[absi(int(p.get("seed", 0))) % pool.size()])
	return s.replace("%d", str(craft_days(p, g)))

# ---------------------------------------------------------------- the wild: a pack left alone grows
## days alone before a pack settles, breeds, grows old
const GROW_DAYS := [1.0, 2.5, 5.0]
const STAGES := [
	{"n": "", "word": "", "lv": 0, "more": 0, "atk": 1.0, "col": Color("c8c8c8")},
	{"n": "settled", "word": "settled in", "lv": 1, "more": 0, "atk": 1.0, "col": Color("d8c890"),
		"say": "This pack has had the ground to itself for a day and more, and has settled in: a level stronger."},
	{"n": "bred", "word": "a brood", "lv": 1, "more": 1, "atk": 1.0, "col": Color("e0a860"),
		"say": "Nobody has troubled this pack for days, and it has bred: a level stronger, and one more of them."},
	{"n": "old", "word": "grown old here", "lv": 2, "more": 1, "atk": 1.1, "col": Color("e07050"),
		"say": "This pack has grown old where it stands: two levels stronger, an elder at its head, and a harder blow."},
]

## How far pack `e` (an entity with a `group`) has grown (0..3).  Its clock begins the first time anybody
## asks, and again whenever it is put down (`put_down`).
static func stage(g, e: Dictionary) -> int:
	var id := str(e.get("id", ""))
	if id == "":
		return 0
	if not g.pack_day.has(id):
		g.pack_day[id] = now(g)
		return 0
	return stage_of(now(g) - float(g.pack_day[id]))

static func stage_of(days: float) -> int:
	var st := 0
	for k in GROW_DAYS.size():
		if days >= float(GROW_DAYS[k]):
			st = k + 1
	return st

## A pack has been beaten: its clock begins again.
static func put_down(g, id: String) -> void:
	g.pack_day[id] = now(g)

## The group pack `e` fights as, at the stage it has reached: every head so many levels up (never past
## the last level there is), and from a brood on one head more (an elder, when it has grown old).
static func grown(g, e: Dictionary) -> Array:
	return grown_at(e.get("group", []), stage(g, e))

static func grown_at(group: Array, st: int) -> Array:
	if st <= 0 or group.is_empty():
		return group
	var info: Dictionary = STAGES[st]
	var out: Array = []
	for f in group:
		var f2: Dictionary = (f as Dictionary).duplicate()
		f2["lv"] = mini(Data.MAX_LEVEL, int(f.lv) + int(info.lv))
		# (an old pack's harder blow is given once, in the battle: battle.gd)
		out.append(f2)
	for k in int(info.more):
		if out.size() >= 5:
			break
		var el: Dictionary = (out[0] as Dictionary).duplicate()
		el["elder"] = st >= 3
		out.append(el)
	return out

## How the wild of region `area` stands, from the packs he knows of there: [stage, packs grown].
static func wild(g, wd: Dictionary, area: String) -> Array:
	var worst := 0
	var n := 0
	for e in wd.get("ents", []):
		if str(e.get("kind", "")) != "enemy" or str(e.get("area", "")) != area or not g.pack_day.has(str(e.id)):
			continue
		var st := stage_of(now(g) - float(g.pack_day[str(e.id)]))
		if st > 0:
			n += 1
		worst = maxi(worst, st)
	return [worst, n]

const WILD_WORDS := ["quiet", "stirring", "breeding", "overrun"]
