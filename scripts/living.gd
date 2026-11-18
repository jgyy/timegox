class_name Living
## What the people of the towns work for (the Iron Pestle release).  Until now a townsperson had a day,
## a trade and a rank in it, and no reason for any of them.  Now everybody grown has a living: what the
## day's work pays (by the trade, by how good they have become at it, by how their town stands today),
## what the day costs (rice, a roof, the mouths at home), what is put by, and **what it is being put by
## for**: an ox, a roof before the rains, a daughter's chest, a boat that is not rented.  When the thing
## is bought they say so, and begin on the next.  Those who cultivate (the sect's outer disciples, the
## monks, the pilgrims and hermits of the road) are not paid in coppers: they count layers of Qi
## Condensation, contribution points towards a Foundation pill, sutras, mornings on the summit.
##
## Nothing here keeps state.  A purse is a pure function of who somebody is (their seed and trade) and
## of the days lived (`Almanac.now`), reckoned at the rank they held on each of those days and at an
## ordinary town's prices, so that **nothing that happens to a town re-prices the past**; only what
## today's work pays (`wage`) moves with how the town stands now.  The bot, the tests and the screen all
## see the same purse.
##
## And they are a little quicker than they were (`smart`): somebody asked the way knows it (where in
## their own country whoever the story wants is standing, or which road leads to another), warns of the
## pack that hunts at this hour, and sees a wound or a back bent double before they see a cultivator.

## coppers a day for a steady hand of each trade, in a town that stands easy
const PAY := {
	"farmer": 34, "fisher": 38, "merchant": 70, "porter": 30, "guard": 48, "watchman": 36, "scholar": 44, "cook": 46,
	"washer": 26, "youth": 22, "lamplighter": 28, "smith": 64, "servant": 24, "soldier": 40, "musician": 36, "waiter": 30,
	"huntsman": 42, "giant": 56, "leafer": 24, "hawker": 32, "storyteller": 34, "woodcutter": 32, "herbalist": 40, "angler": 30, "pedlar": 44, "hunter": 40, "elder": 20,
}
const PAY_OTHER := 28
## what each of the five places in a trade (Almanac.craft_rank) is paid, of a steady hand's wage
const RANK_K := [0.6, 0.8, 1.0, 1.3, 1.7]
## what the day's work pays today by how the town stands (weal.gd): the past is never reckoned by this
const STATE_K := {"cold": 0.7, "afraid": 0.8, "lean": 0.85, "wary": 0.95, "easy": 1.0, "thriving": 1.15, "festive": 1.25}
## rice and a roof for one, and for each mouth at home besides
const KEEP := 12
const KEEP_MOUTH := 3
## of what a day leaves over, the share that reaches the jar (the rest is the year: cloth, salt, the temple,
## a feast day), and the share of a day's saving that each day before the journey is reckoned to have left
const SAVE := 0.5
const BEFORE := 0.15
## the trades whose people cultivate instead of saving
const CULTIVATORS := ["disciple", "monk", "pilgrim", "hermit"]

## What people save for: [what it is called in their mouth, coppers].  Each has three of their own, drawn
## from their trade's and everybody's by their seed, in order.
const GOALS := {
	"farmer": [["an ox of my own", 2400], ["the strip of land by the stream", 5200], ["seed that is not borrowed", 700]],
	"fisher": [["a boat that is not rented", 3600], ["a net with no knots of my father's in it", 600], ["a share in the drying racks", 1500]],
	"angler": [["a boat that is not rented", 3600], ["a rod of spotted bamboo", 500]],
	"merchant": [["a stall with a roof on it", 4200], ["a second mule", 2800], ["the debt to my wife's brother", 1900]],
	"pedlar": [["a mule, so the pole can come off my shoulder", 2800], ["a stall that stays where it is put", 4200]],
	"porter": [["a handcart", 1300], ["my own pole and ropes, not the guild's", 400], ["a room that is not shared", 1700]],
	"smith": [["an anvil of my own", 3900], ["the master's mark, which costs a feast", 2200], ["good charcoal for a winter", 900]],
	"cook": [["a cookshop with my name over it", 5200], ["a cleaver of folded steel", 800]],
	"waiter": [["a share in the house", 3000], ["a suit of clothes nobody has spilt on", 450]],
	"leafer": [["a pack painted on silk, not paper", 900], ["a table by the stove that is mine by right", 1600]],
	"hawker": [["a barrow with a wheel that does not sing", 1300], ["a stall that stays where it is put", 4200]],
	"storyteller": [["a tea-house with a platform in it", 4800], ["a fan that has not been mended", 300]],
	"washer": [["a copper boiler", 1200], ["a line under a roof for the rains", 600]],
	"guard": [["a mail coat that was not somebody's last", 2600], ["a plot outside the wall", 3400]],
	"soldier": [["my discharge, which is bought", 3000], ["a plot outside the wall", 3400]],
	"watchman": [["a lantern with glass in it", 500], ["a day post, when I am old", 2000]],
	"lamplighter": [["a ladder that does not sway", 350], ["oil laid in for the winter", 900]],
	"scholar": [["the fee for the examination", 3200], ["the Nine Classics, not copied by my own hand", 2400], ["paper for a year", 600]],
	"musician": [["a qin with all seven strings its own", 2700], ["a place in a troupe", 1500]],
	"servant": [["my bond, bought back", 3000], ["a chest with a lock", 400]],
	"youth": [["an apprentice's fee", 1600], ["a pair of shoes that were made for me", 300]],
	"huntsman": [["a bow of horn", 1800], ["a pair of hounds", 1400]],
	"hunter": [["a bow of horn", 1800], ["a winter's salt for the meat", 500]],
	"woodcutter": [["an axe of the smith's best", 900], ["a donkey for the loads", 2000]],
	"herbalist": [["a drying shed", 1500], ["the physician's own book, copied", 1100]],
	"giant": [["a bed made to my length", 1400], ["a house with a door I do not stoop at", 5200]],
	"elder": [["my burial, as I want it", 1500], ["something to leave each of the grandchildren", 1200]],
	"": [["my daughter's bride-chest", 1800], ["my son's schooling", 2200], ["a tiled roof before the rains", 1500], ["my mother's burial, as she wanted it", 1300],
		["the physician's bill", 600], ["a winter's rice laid in", 500], ["the debt at the rice shop", 800]],
}

## What they say of it: by how far along they are.  {goal} what it is, {left} days still to go, {saved}
## coppers put by towards it, {price} what it costs, {wage} today's takings, {keep} what today costs,
## {had} the last thing they bought.  Each must fit the dialogue box and read of anybody.
const LINES := {
	"start": [
		"I am putting by for {goal}. {price} coppers. I have {saved}. Do not do the sum for me, %s, I have done it.",
		"{wage} coppers today, and {keep} of them eaten before dark. What is left goes in the jar for {goal}. The jar is patient.",
		"{goal}: that is what all this is for. {left} {days} of it yet, if nobody falls ill and nothing breaks.",
	],
	"mid": [
		"Half of {goal} is in a jar under my bed and the other half is still in other people's purses. {left} {days}, I make it.",
		"{saved} coppers of {price}. I count them on the first of the month, and not oftener; it does them no good to be looked at.",
		"I take {wage} a day now and it costs me {keep} to stand here taking it. The difference is {goal}, in {left} {days}.",
	],
	"near": [
		"{left} {days}, %s. {left}! Then {goal} is mine and paid for, and nobody can come and ask for it back.",
		"I have gone to look at it twice this week. {goal}. {saved} of {price} coppers. I do not buy tea any more.",
		"Ask me again in {left} {days} and I will not be standing here. I will be standing next to {goal}.",
	],
	"next": [
		"I bought it, %s: {had}. Paid, all of it, in coppers I earned. Now it is {goal}, and {left} {days} more.",
		"{had} is done and paid for. You would think I would sit down. I looked at it for an evening, and then I thought: {goal}.",
	],
	"behind": [
		"{wage} coppers today and the day costs {keep}. I am not saving for {goal} this month; I am standing still, and working to do it.",
		"The town is thin and so is the work. I take what there is, and a second thing after dark. {goal} can wait; the rice cannot.",
	],
	"done": [
		"Everything I worked for is bought and paid for, %s. I come out in the morning all the same. What else would the morning be for?",
		"I have what I wanted. Nobody tells you that the wanting was the good part. I am thinking of something else to want.",
	],
}

## What those who cultivate say: {layer} the layer of Qi Condensation, {days} days at it, {points} and
## {need} contribution points, {n} what a monk, a pilgrim or a hermit counts.
const CULT_LINES := {
	"disciple": [
		"The {layer} layer of Qi Condensation. Two hundred breaths before the dawn bell, every dawn, {days} days. I counted; counting is most of it.",
		"The {layer} layer. The next one does not come from wanting it. I have tried wanting it. It comes from the two hundred breaths.",
		"I sweep the steps for contribution points and I breathe on them for the {layer} layer. The steps are very clean and I am very slow.",
	],
	"disciple_peak": [
		"The ninth layer, and it will not move: that wants a Foundation pill, and a pill wants three hundred points. I have {points}. I carry water.",
		"{points} points of {need}. Four a day for the water and the steps. It is not cultivation. It is what cultivation costs.",
	],
	"disciple_found": [
		"Foundation Establishment, senior. I carried water for the pill and then I sat for nine days. Nobody tells you about the water.",
		"I broke through. The juniors ask how. I say: {days} days, and they look at me as if I were keeping the trick back.",
	],
	"monk": [
		"{n} times through the sutra. I do not know that it is nearer the end; a wheel has no end. It is rounder than it was.",
		"I beg at {keep} doors a day and am given at most of them. The bowl is the practice. The rice is only what the bowl is for.",
	],
	"pilgrim": [
		"{n} mornings I have gone up. The mountain has not got lower. I have stopped expecting it to; that took the first hundred.",
		"Up at dawn, down by dark, {n} times. Somebody asked what I get. Legs. And a thing I had not got when I began, without a name.",
	],
	"hermit": [
		"{n} days of sitting. On a good one I get a hundred breaths with nobody in them. This is not a good one: you are here.",
		"I came up to cultivate and found it was mostly wood, water and the roof. {n} days. The sitting is what is left when those are done.",
	],
}

const ORDINALS := ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth"]
## contribution points a Foundation pill costs, and what a day of water and steps earns
const PILL_POINTS := 300
const POINTS_DAY := 4

static func _seed(p: Dictionary) -> int:
	return absi(int(p.get("seed", 0)))

## Has `p` a living to speak of?  (Children have not; nor has whoever cultivates.)
static func works(p: Dictionary) -> bool:
	return not bool(p.get("kid", false)) and not cultivates(p)

static func cultivates(p: Dictionary) -> bool:
	return str(p.get("role", "")) in CULTIVATORS and not bool(p.get("kid", false))

## The mouths at home besides their own (the old and the young keep nobody).
static func mouths(p: Dictionary) -> int:
	if bool(p.get("old", false)) or str(p.get("role", "")) in ["youth", "servant", "elder"]:
		return 0
	return (_seed(p) / 13) % 4

## What a day costs `p`: rice and a roof, and the mouths at home.
static func keep(p: Dictionary) -> int:
	return KEEP + KEEP_MOUTH * mouths(p)

## What the day's work pays a hand of rank `rank` in `p`'s trade where the town stands `state`.
static func wage_at(p: Dictionary, rank: int, state: String = "easy") -> int:
	var base := float(PAY.get(str(p.get("role", "")), PAY_OTHER))
	return int(round(base * float(RANK_K[clampi(rank, 0, RANK_K.size() - 1)]) * float(STATE_K.get(state, 1.0))))

## What today's work pays `p`: by the rank they hold now and how their town stands now.
static func wage(p: Dictionary, g) -> int:
	return wage_at(p, Almanac.craft_rank(p, g), _state(p, g))

static func _state(p: Dictionary, g) -> String:
	if str(g.prologue) != "":
		return "easy"
	var wt := Weal.of_folk(str(p.get("town", "")))
	if wt == "" and Folk.is_camp(str(p.get("town", ""))):
		wt = Weal.town_of(str(p.get("area", "")))
	return Weal.state(g, wt) if wt != "" else "easy"

## Everything `p` has ever put by, to day `days` of the journey (Almanac.now): what they came with, and
## what each day left over at the rank they held that day, in an ordinary town.  Never less than nothing,
## and never reckoned by how the town stands today.
static func earned(p: Dictionary, days: float) -> int:
	if not works(p):
		return 0
	var s := _seed(p)
	var start := s % 4
	var pace := 5.0 + float((s / 7) % 9)
	# what they came with: the days before the journey, at half a day's leavings each
	var tot := float((s % 4) * (40 + (s / 11) % 50) + 10) * maxf(0.0, float(wage_at(p, start) - keep(p))) * SAVE * BEFORE
	# and the days of the journey, a rank at a time (Almanac.craft_rank rises a place every `pace` days
	# after the first)
	var d := 0.0
	var rank := start
	while d < days:
		var until := days
		if rank < RANK_K.size() - 1:
			until = minf(days, 1.0 + pace * float(rank - start + 1))
		tot += (until - d) * maxf(0.0, float(wage_at(p, rank) - keep(p))) * SAVE
		d = until
		rank = mini(rank + 1, RANK_K.size() - 1)
	return int(tot)

## The three things `p` saves for, in order: [what, coppers].
static func goals(p: Dictionary) -> Array:
	var s := _seed(p)
	var own: Array = GOALS.get(str(p.get("role", "")), [])
	var any: Array = GOALS[""]
	# (their trade's first, then everybody's, then their trade's again: no thing twice)
	var cand: Array = []
	for k in own.size():
		cand.append(own[(s + k) % own.size()])
	var mixed: Array = []
	for k in any.size():
		var a: Array = any[(s / 3 + k) % any.size()]
		if k == 0 and not cand.is_empty():
			mixed.append(cand.pop_front())
		mixed.append(a)
		if k == 0 and not cand.is_empty():
			mixed.append(cand.pop_front())
	return mixed.slice(0, 3)

## Where `p` stands with it: {goal, price, saved (towards this one), left (days at today's rank in an
## ordinary town; -1 if the day leaves nothing over), had (the last thing bought, "" if none), done (all
## three bought), wage, keep (today's), stage: "start", "mid", "near", "next", "behind" or "done"}.
static func purse(p: Dictionary, g) -> Dictionary:
	var out := {"goal": "", "price": 0, "saved": 0, "left": -1, "had": "", "done": false, "wage": 0, "keep": 0, "stage": "done", "bought": 0}
	if not works(p):
		return out
	var tot := earned(p, Almanac.now(g))
	var gl := goals(p)
	out.wage = wage(p, g)
	out.keep = keep(p)
	var k := 0
	while k < gl.size() and tot >= int(gl[k][1]):
		tot -= int(gl[k][1])
		out.had = str(gl[k][0])
		k += 1
	out.bought = k
	if k >= gl.size():
		out.done = true
		return out
	out.goal = str(gl[k][0])
	out.price = int(gl[k][1])
	out.saved = tot
	var net := wage_at(p, Almanac.craft_rank(p, g)) - keep(p)
	if net > 0:
		out.left = int(ceil(float(out.price - tot) / (float(net) * SAVE)))
	var share := float(tot) / float(out.price)
	if int(out.wage) <= int(out.keep) or net <= 0:
		out.stage = "behind"
	elif k > 0 and share < 0.2:
		out.stage = "next"
	elif share >= 0.8:
		out.stage = "near"
	elif share >= 0.3:
		out.stage = "mid"
	else:
		out.stage = "start"
	return out

## Is `p` working past the day's end just now: behind, or within a few days of what they want?  (Only
## what their hands do changes, world.gd: where they are is the day's own.)
static func pressed(p: Dictionary, g) -> bool:
	if not works(p):
		return false
	var pu := purse(p, g)
	return str(pu.stage) == "behind" or (str(pu.stage) == "near" and int(pu.left) >= 0 and int(pu.left) <= 6)

## What somebody pressed does with their hands in an idle hour instead of the day's own clip ("" keeps it).
static func late_clip(p: Dictionary, g, own: String, hour: float) -> String:
	if not (hour >= 17.5 and hour < 21.5) or not own in ["drink", "laugh", "sit_bench", "talk", "idle", "eat", "clap", "dance"]:
		return ""
	if not pressed(p, g):
		return ""
	return ["count", "sew", "carry", "weigh"][_seed(p) % 4]

# ---------------------------------------------------------------- those who cultivate
## Where a cultivator of the towns stands: {layer 1..9, peak (at the ninth and waiting on a pill),
## found (Foundation Establishment), points, days, n (what a monk, a pilgrim, a hermit counts)}.
static func cultivation(p: Dictionary, g) -> Dictionary:
	var s := _seed(p)
	var now := Almanac.now(g)
	var days := (s % 5) * (50 + (s / 11) % 60) + 30 + int(now)
	var pace := 6.0 + float((s / 5) % 8)
	var start := 1 + s % 6
	var raw := start + int(floor(now / pace))
	var layer := mini(9, raw)
	# (the days since the ninth layer was reached are days of water and steps)
	var at_nine := maxf(0.0, now - pace * float(9 - start))
	var points := mini(PILL_POINTS, int((s % 7) * 12 + at_nine * POINTS_DAY)) if layer >= 9 else (s % 7) * 12
	return {"layer": layer, "peak": layer >= 9 and points < PILL_POINTS, "found": layer >= 9 and points >= PILL_POINTS, "points": points, "days": days,
		"n": days * (3 if str(p.get("role", "")) == "monk" else 1)}

## The realm a disciple of the towns is in, in the words of the sect.
static func realm_word(p: Dictionary, g) -> String:
	var c := cultivation(p, g)
	if bool(c.found):
		return "Early Foundation Establishment"
	return "Qi Condensation, the %s layer" % ORDINALS[int(c.layer) - 1]

# ---------------------------------------------------------------- what is said
static func _fill(s: String, d: Dictionary) -> String:
	for k in d:
		s = s.replace("{%s}" % str(k), str(d[k]))
	return s

## What `p` says of their living or their cultivation ("" for a child); `n` turns the lines over.
static func line(p: Dictionary, g, n: int = 0) -> String:
	if bool(p.get("kid", false)):
		return ""
	var s := _seed(p)
	if cultivates(p):
		var c := cultivation(p, g)
		var key := str(p.role)
		if key == "disciple":
			key = "disciple_found" if bool(c.found) else ("disciple_peak" if bool(c.peak) else "disciple")
		var pool: Array = CULT_LINES[key]
		return _fill(str(pool[(s + n) % pool.size()]), {"layer": ORDINALS[int(c.layer) - 1], "days": c.days, "points": c.points, "need": PILL_POINTS, "n": c.n, "keep": 7 + s % 9})
	var pu := purse(p, g)
	var pool2: Array = LINES[str(pu.stage)]
	var left := str(pu.left) if int(pu.left) >= 0 else "more"
	return _fill(str(pool2[(s + n) % pool2.size()]), {"goal": pu.goal, "days": "day" if int(pu.left) == 1 else "days", "left": left, "saved": pu.saved, "price": pu.price, "wage": pu.wage, "keep": pu.keep, "had": pu.had})

## What is written under their name when he faces them.
static func tag(p: Dictionary, g) -> String:
	if bool(p.get("kid", false)):
		return ""
	if cultivates(p):
		if str(p.role) == "disciple":
			return realm_word(p, g)
		return "%d days on the way" % int(cultivation(p, g).days)
	var pu := purse(p, g)
	if bool(pu.done):
		return "%s: wants for nothing" % Almanac.craft_word(p, g)
	if int(pu.left) < 0 or str(pu.stage) == "behind":
		return "%s: %d coppers a day, and the day costs %d" % [Almanac.craft_word(p, g), int(pu.wage), int(pu.keep)]
	return "%s: saving for %s (%d day%s)" % [Almanac.craft_word(p, g), str(pu.goal), int(pu.left), "" if int(pu.left) == 1 else "s"]

# ---------------------------------------------------------------- quicker than they were
const COMPASS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

## Which way tile `to` lies from tile `from`, in words (north is up the map).
static func bearing(from: Vector2i, to: Vector2i) -> String:
	var d := Vector2(to - from)
	if d.length() < 0.5:
		return "here"
	var a := fposmod(atan2(d.y, d.x), TAU)
	return COMPASS[int(round(a / (TAU / 8.0))) % 8]

## How far, as somebody of the street says it (a tile is about two paces).
static func paces(from: Vector2i, to: Vector2i) -> String:
	var n := int(Vector2(to - from).length() * 2.0)
	if n < 12:
		return "a few steps"
	if n < 40:
		return "a stone's throw"
	if n < 120:
		return "%d paces or so" % (int(n / 10.0) * 10)
	return "a good walk, %d paces and more" % (int(n / 50.0) * 50)

const WAY_HERE := ["%s? %s of here, %s. You cannot miss it; people do, but you cannot.", "You want %s. Go %s, %s. Tell them who sent you; it will do you no good, but tell them.",
	"%s: %s, %s. I pass that way every day and have never had a reason to stop."]
const WAY_THERE := ["%s is not in this country, %s. That is %s. Take the road for %s and ask again there.", "%s? You are a long way out, %s: that is in %s. The way goes by %s."]
const WAY_NEXT := ["%s is not in this country, %s. That is %s, and the road goes straight to it.", "%s? Not here, %s: in %s, the next country over."]
const HUNT_WARN := ["Mind yourself %s of here, %s: the %s hunts at this hour, and it has seen people before.", "If you are going %s, %s, go wide. The %s is out hunting; we keep the children in."]
const HURT_LINES := ["You are bleeding, %s. Sit down before you fall down; I have seen bigger than you do both.", "That wants binding, %s. A spring or a night's rest: I am no physician, but I have eyes."]
const LADEN_LINES := ["Set some of that down, %s, before your back sets it down for you. There is a storehouse on the mountain, they say.", "I carry for a living and I would not carry that, %s. Not at one go."]

## What somebody who has their wits about them says to him now, if anything is worth saying ("" if not).
## `ctx`: `hurt` (he is under half his health), `laden` (Load.tier 2 or more), `at` (where they stand),
## `want` ({n, area, pos (a tile, or absent if it is not in this realm)}: whoever or whatever the step of
## the story wants, {} if nothing with a place), `hunt` ({n, pos}: the nearest pack of their country that
## is hunting now, {} if none).  `n` turns what is noticed over, so that it is not always the same thing.
static func smart(p: Dictionary, g, ctx: Dictionary, n: int = 0) -> String:
	if bool(p.get("kid", false)):
		return ""
	var s := _seed(p)
	var addr := str(g.address())
	var at: Vector2i = ctx.get("at", Vector2i.ZERO)
	var said: Array = []
	if bool(ctx.get("hurt", false)):
		said.append(str(HURT_LINES[(s + n) % HURT_LINES.size()]) % addr)
	var want: Dictionary = ctx.get("want", {})
	if not want.is_empty() and str(want.get("n", "")) != "":
		if str(want.area) == str(p.get("area", "")) and want.has("pos"):
			said.append(str(WAY_HERE[(s + n) % WAY_HERE.size()]) % [str(want.n), bearing(at, want.pos), paces(at, want.pos)])
		elif str(want.area) != str(p.get("area", "")) and Data.AREAS.has(str(want.area)) and Data.AREAS.has(str(p.get("area", ""))):
			var hop := Data.next_hop(str(p.area), str(want.area))
			if hop == str(want.area) or hop == "" or not Data.AREAS.has(hop):
				said.append(str(WAY_NEXT[(s + n) % WAY_NEXT.size()]) % [str(want.n), addr, str(Data.AREAS[str(want.area)].n)])
			else:
				said.append(str(WAY_THERE[(s + n) % WAY_THERE.size()]) % [str(want.n), addr, str(Data.AREAS[str(want.area)].n), str(Data.AREAS[hop].n)])
	var hunt: Dictionary = ctx.get("hunt", {})
	if not hunt.is_empty():
		said.append(str(HUNT_WARN[(s + n) % HUNT_WARN.size()]) % [bearing(at, hunt.pos), addr, str(hunt.n)])
	if bool(ctx.get("laden", false)):
		said.append(str(LADEN_LINES[(s + n) % LADEN_LINES.size()]) % addr)
	if said.is_empty():
		return ""
	return str(said[n % said.size()])
