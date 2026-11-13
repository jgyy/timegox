class_name Weal
extends RefCounted
## How the towns stand (the Answering Land release): what Lin Feng chose and did, weighed town by town.
##
## Before this release a choice left a thing standing in the land (marks.gd) and a line in a later
## conversation (echoes.gd), and the towns went on exactly as they were.  Now every town keeps three
## measures of its own, and they are made of nothing but his journey:
##
##   * **plenty**: whether there is work, trade and something in the pot;
##   * **peace**: whether a door may be left open at night;
##   * **regard**: what the town thinks of him.
##
## Every answer at a crossroads is felt in the towns that answer for the country it was given in
## (TOWNS: a town and the regions round it): mercy is remembered kindly, rigour makes a road safe and
## a name feared, the new works bring trade and the old ways keep a town's own temper, the wide world
## fills a market and the home fire warms the towns of the Rice Hearth.  So is every lord put down
## near a town, every pack cleared from its country, every field of the war, every doom given way
## to; and so is what he does in its own streets: a shift worked, a fare carried, the post brought in,
## a jar broken with the flat of a sword and not paid for, a gift to the town's chest.
##
## What the measures come to is the town's **state** (STATES, worst to best): cold, afraid, lean,
## wary, easy, thriving, festive.  A state is not a label: it changes what things cost at a counter
## and what a shift pays (`mod`), what the people in the street do with their evening (`mood_clip`:
## a festive town dances in its square, a frightened one looks over its shoulder) and what they say
## (`line`), what is hung at every door (`dress`, built from code, on the wall and never on a tile),
## how whoever answers for the town receives him (`word`), and what has become of the people with
## names (`FATES`: Smith Tie with two apprentices or working alone, a boatwright with three hulls on
## the slip or none).  A town that is festive thanks him once (`thank`).
##
## Nothing is thrown for and almost nothing is kept: the measures are worked out from the game state
## whenever they are asked for (and remembered until it changes); the only new state is a small
## ledger of what was done in each town (`Game.weal`).  So the bot, the tests and the page (Esc > The
## Land) all see the same towns.

const MEASURES := ["plenty", "peace", "regard"]
const MEASURE_NAMES := {"plenty": "Plenty", "peace": "Peace", "regard": "Regard"}
## no measure goes past this, either way
const CAP := 9

## The towns that are weighed: their own region, the regions whose news is theirs, and who answers
## for them (offices.gd).  The Drum Tower quarter is Qingshi; Guiyun keeps its own books (hold.gd).
const TOWNS := {
	"sect": {"n": "the Azure Cloud Sect", "area": "sect", "areas": ["sect", "palace", "celestial", "grave", "court"], "office": "master_outer"},
	"cloudfoot": {"n": "Cloudfoot", "area": "mountain", "areas": ["mountain", "mirror", "terraces", "frost", "thunder", "cloudsea", "aurora"], "office": "post_cloudfoot"},
	"qingshi": {"n": "Qingshi Village", "area": "village", "areas": ["village", "bamboo", "silk", "millet", "loom", "garden"], "office": "head_qingshi"},
	"yanggu": {"n": "Yanggu Market", "area": "yanggu", "areas": ["yanggu", "fusang", "maple", "springs", "wheel"], "office": "warden_yanggu"},
	"shazhou": {"n": "Shazhou Oasis", "area": "dunes", "areas": ["dunes", "fungal", "time", "origin", "void", "chaos"], "office": "reeve_well"},
	"longmen": {"n": "Longmen Ferry", "area": "longmen", "areas": ["longmen", "karst", "marsh", "dragon", "drowned"], "office": "harbour_longmen"},
	"tushan": {"n": "Tushan", "area": "tushan", "areas": ["tushan", "volcano", "forge", "buzhou"], "office": "guild_tushan"},
	"featherfall": {"n": "Featherfall", "area": "juntian", "areas": ["juntian", "changhe", "starferry", "magpie", "starpalace", "jasper", "guanghan"], "office": "speaker_featherfall"},
	"tearwater": {"n": "Tearwater", "area": "ninesprings", "areas": ["ninesprings"], "office": "reeve_tearwater"},
	"youdu_city": {"n": "Youdu", "area": "youdu", "areas": ["youdu"], "office": "registrar_youdu"},
	"landfall": {"n": "Landfall", "area": "penglai", "areas": ["penglai", "fangzhang", "yingzhou", "guixu"], "office": "reeve_landfall"},
}
const ORDER := ["sect", "cloudfoot", "qingshi", "yanggu", "shazhou", "longmen", "tushan", "featherfall", "tearwater", "youdu_city", "landfall"]
## the towns the Rice Hearth keeps: where the home fire is
const HOME_TOWNS := ["qingshi", "sect", "cloudfoot"]

## The states of a town, worst to best: what it is called, what is said of it on the page, the
## colour it is written in, and the numbers it changes (`mod`): what a counter asks ("price"), what a
## shift pays ("wage"), what a broken thing costs to make good ("mend").
const STATES := {
	"cold": {"n": "Cold", "col": Color("8aa0b8"), "price": 1.25, "wage": 0.8, "mend": 2.0,
		"desc": "They know his face and do not care for it. Doors are shut a little sooner than they need be, and every counter asks a quarter more."},
	"afraid": {"n": "Afraid", "col": Color("b08a8a"), "price": 1.1, "wage": 0.9, "mend": 1.0,
		"desc": "Nobody is out after dark who can help it. Shutters are barred at dusk, a talisman is pasted on every door, and people in the street look behind them."},
	"lean": {"n": "Lean", "col": Color("b8a878"), "price": 1.15, "wage": 0.8, "mend": 1.0,
		"desc": "The stalls are half bare and the pot is thin. An upturned basket stands by every door, and what there is costs more."},
	"wary": {"n": "Wary", "col": Color("a8a8a0"), "price": 1.05, "wage": 1.0, "mend": 1.0,
		"desc": "Nothing is wrong that anybody will name. They are civil, and count their change."},
	"easy": {"n": "Easy", "col": Color("d8d0b8"), "price": 1.0, "wage": 1.0, "mend": 1.0,
		"desc": "A town going about its day, as it did before anybody had heard of a sweeper."},
	"thriving": {"n": "Thriving", "col": Color("9ad870"), "price": 0.92, "wage": 1.1, "mend": 1.0,
		"desc": "There is work for whoever wants it and a lantern at every door. Counters ask a little less of him, and a shift pays a tenth more."},
	"festive": {"n": "Festive", "col": Color("ffb040"), "price": 0.85, "wage": 1.2, "mend": 0.5,
		"desc": "Lanterns either side of every door and pennants across the lintel. At dusk the square dances, and nobody will let him pay the full price of anything."},
}
const STATE_ORDER := ["cold", "afraid", "lean", "wary", "easy", "thriving", "festive"]
## a measure this low names the town for it, whatever the others are
const LOW := -3
## the three measures together must come to this for a town to thrive, and to this to be festive
## (with none of them below FESTIVE_EACH)
const THRIVE := 7
const FESTIVE := 15
const FESTIVE_EACH := 3
const WARY := -2

## What is done in a town's own streets (the ledger, `act`): which measure it moves, how many of it
## make one point, how far it can move the measure at most, and what the page says of it.
const ACTS := {
	"shift": {"m": "plenty", "per": 2, "max": 2, "why": "shifts worked at the town's trades"},
	"fare": {"m": "plenty", "per": 2, "max": 2, "why": "fares carried in by carriage"},
	"bag": {"m": "regard", "per": 2, "max": 2, "why": "the post brought in, seals whole"},
	"errand": {"m": "regard", "per": 4, "max": 3, "why": "errands run among its people"},
	"gift": {"m": "plenty", "per": 1, "max": 3, "why": "given to the town's chest"},
	"broke": {"m": "regard", "per": -2, "max": 4, "why": "things broken in its streets"},
	"unpaid": {"m": "regard", "per": -1, "max": 3, "why": "things broken and never paid for"},
	"sold": {"m": "plenty", "per": 6, "max": 2, "why": "timber, stone and fish sold on its roads"},
}
## how many lords put down in a town's country make one point of peace, and how many points at most;
## and the same for packs cleared out of it
const LORDS_PER := 4
const LORDS_MAX := 3
const KILLS_PER := 80
const KILLS_MAX := 2
## what the answers at the crossroads can come to in one measure of one town, either way: a town is not
## made or unmade by words alone
const CROSS_MAX := 4
## a gift to the town's chest: what it costs (by realm), and how many a town will take
const GIFT_BASE := 400
const GIFT_REALM := 150
const GIFT_MAX := 3

## What a festive town gives him, once: spirit stones by his realm, and the regard of its hearth.
const THANKS_BASE := 600
const THANKS_REALM := 200

# ---------------------------------------------------------------- which town hears of what
static var _hears := {}
static var _lord_area := {}

## The towns that answer for region `area` (its news is theirs).
static func hears(area: String) -> Array:
	if _hears.is_empty():
		for tid in ORDER:
			for a in TOWNS[tid].areas:
				if not _hears.has(a):
					_hears[a] = []
				_hears[a].append(tid)
	return _hears.get(area, [])

## The town whose own streets region `area` is ("" out in the country).
static func town_of(area: String) -> String:
	for tid in ORDER:
		if str(TOWNS[tid].area) == area:
			return tid
	return ""

## The town of folk.gd's town `ftid` (the Drum Tower quarter is Qingshi; a camp is nobody's).
static func of_folk(ftid: String) -> String:
	if ftid == "drumtower":
		return "qingshi"
	return ftid if TOWNS.has(ftid) else ""

## The town office `oid` answers for ("" for the court and the sect's other masters).
static func of_office(oid: String) -> String:
	for tid in ORDER:
		if str(TOWNS[tid].office) == oid:
			return tid
	return ""

## Where each lord of the story stands (boss -> region), from the steps that send the hero to them.
static func lord_area(boss: String) -> String:
	if _lord_area.is_empty():
		for s in Data.STEPS:
			if str(s.kind) in ["kill", "fall"] and s.has("boss") and s.has("area"):
				_lord_area[str(s.boss)] = str(s.area)
	return str(_lord_area.get(boss, ""))

# ---------------------------------------------------------------- the ledger
## Something done in town `tid` (ACTS), `n` times.
static func act(g, tid: String, what: String, n: int = 1) -> void:
	if tid == "" or not TOWNS.has(tid) or not ACTS.has(what):
		return
	var was := state(g, tid)
	var k := tid + "|" + what
	g.weal[k] = int(g.weal.get(k, 0)) + n
	g.weal_n += 1
	_told(g, tid, was)

static func acts(g, tid: String, what: String) -> int:
	return int(g.weal.get(tid + "|" + what, 0))

## A town whose state has changed is news: a toast, and a line in the annals.
static func _told(g, tid: String, was: String) -> void:
	var now := state(g, tid)
	if now == was:
		return
	g.toast("%s is %s now" % [str(TOWNS[tid].n).trim_prefix("the "), str(STATES[now].n).to_lower()])
	g.note("%s: %s. %s" % [str(TOWNS[tid].n).trim_prefix("the "), str(STATES[now].n), str(STATES[now].desc)])

## Told when the story has moved (a crossroads answered, a lord put down): any town that has changed.
static func poll(g) -> void:
	for tid in ORDER:
		var now := state(g, tid)
		var was := str(g.weal_state.get(tid, "easy"))
		if now != was:
			g.weal_state[tid] = now
			if g.started and not g.finished:
				g.toast("%s is %s now" % [str(TOWNS[tid].n).trim_prefix("the "), str(STATES[now].n).to_lower()])
				g.note("%s: %s. %s" % [str(TOWNS[tid].n).trim_prefix("the "), str(STATES[now].n), str(STATES[now].desc)])

# ---------------------------------------------------------------- the measures
static var _cache := {}
static var _stamp := ""

static func _stamp_of(g) -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [g.get_instance_id(), int(g.step), int(g.weal_n), g.picks.size(), g.boss_done.size(), int(g.kills) / 20, g.war_won.size(), int(g.war_lost), g.falls.size(), g.works.size()]

## What a tilt of a crossroads does to the towns that hear of it: [[measure, points], ...].
static func tilt_marks(tilt: Dictionary) -> Array:
	var out: Array = []
	for sc in tilt:
		var v := int(tilt[sc])
		var n := 2 if absi(v) >= 3 else 1
		match str(sc):
			"heart":
				if v > 0:
					out.append(["regard", n])
				else:
					out.append(["peace", n])
					out.append(["regard", -n])
			"craft":
				if v > 0:
					out.append(["plenty", n])
				else:
					out.append(["peace", 1])
					if n > 1:
						out.append(["plenty", -(n - 1)])
			"reach":
				if v > 0:
					out.append(["plenty", n])
				else:
					out.append(["home", n])
	return out

## Everything that moves the measures of town `tid`: [{m, d, why}], the heaviest first.
static func causes(g, tid: String) -> Array:
	var st := _stamp_of(g)
	if st != _stamp:
		_stamp = st
		_cache = {}
	if _cache.has(tid):
		return _cache[tid]
	var out: Array = []
	var t: Dictionary = TOWNS[tid]
	# what was answered at the crossroads, where the answer was given (the country its mark stands in)
	for cid in Echoes.ORDER:
		var ch := Echoes.chosen(g, cid)
		if ch == "":
			continue
		var o := Echoes.option(cid, ch)
		var where := str(Marks.MARKS.get(cid, {}).get(ch, {}).get("area", ""))
		var near: bool = tid in hears(where)
		for tm in tilt_marks(o.get("tilt", {})):
			var m := str(tm[0])
			var d := int(tm[1])
			if m == "home":
				# the home fire warms the towns of the Rice Hearth, wherever the answer was given
				if tid in HOME_TOWNS:
					out.append({"m": "regard", "d": 1, "why": str(o.log), "x": true})
			elif near:
				out.append({"m": m, "d": d, "why": str(o.log), "x": true})
	# what the scales have made of him is known everywhere
	var hl := Echoes.lean(g, "heart")
	if hl > 0:
		out.append({"m": "regard", "d": 1, "why": "He is known to be merciful."})
	elif hl < 0:
		out.append({"m": "peace", "d": 1, "why": "He is known to be unbending, and the roads are quiet for it."})
		out.append({"m": "regard", "d": -1, "why": "He is known to be unbending, and people step out of his way."})
	if Echoes.lean(g, "craft") > 0:
		out.append({"m": "plenty", "d": 1, "why": "He is of the new works, and the makers follow him."})
	if Echoes.lean(g, "reach") < 0 and tid in HOME_TOWNS:
		out.append({"m": "regard", "d": 1, "why": "He is of the home fire: he comes back."})
	# the lords put down in its country, and the packs cleared out of it
	var lords := 0
	for b in g.boss_done:
		if lord_area(str(b)) in t.areas:
			lords += 1
	if lords >= LORDS_PER:
		out.append({"m": "peace", "d": mini(LORDS_MAX, lords / LORDS_PER), "why": "%d lords put down in its country." % lords})
	var cleared := 0
	for a in t.areas:
		cleared += int(g.weal.get("kills|" + str(a), 0))
	if cleared >= KILLS_PER:
		out.append({"m": "peace", "d": mini(KILLS_MAX, cleared / KILLS_PER), "why": "%d of the wild cleared from its roads." % cleared})
	# the dooms: a town does not forget who stood, or who stepped aside
	for f in g.falls:
		if lord_area(str(f)) in t.areas:
			match str(g.falls[f]):
				"gave":
					out.append({"m": "peace", "d": -1, "why": "He gave way to %s, and it passed this way." % str(Data.ENEMIES[str(f)].n)})
				"struck", "kept":
					out.append({"m": "regard", "d": 1, "why": "He stood in front of %s, and lost, and stood." % str(Data.ENEMIES[str(f)].n)})
	# the war is everybody's: a field won is a quiet night in every town of the land
	if Data.layer_of(str(t.area)) == "surface":
		if g.war_won.size() > 0:
			out.append({"m": "peace", "d": mini(2, g.war_won.size()), "why": "%d fields of the war won." % g.war_won.size()})
		if int(g.war_lost) >= 2:
			out.append({"m": "peace", "d": -1, "why": "Fields of the war lost before they were won."})
		var wk := 0
		for w in g.works:
			wk += 1
		if wk >= 4:
			out.append({"m": "plenty", "d": mini(2, wk / 4), "why": "%d works built in the land." % wk})
	# what he did in its own streets
	for a in ACTS:
		var n := acts(g, tid, str(a))
		var per := int(ACTS[a].per)
		if n <= 0 or n < absi(per):
			continue
		var d := mini(int(ACTS[a].max), n / absi(per)) * (1 if per > 0 else -1)
		out.append({"m": str(ACTS[a].m), "d": d, "why": "%d %s." % [n, str(ACTS[a].why)]})
	# (and his own town on the mountain's shoulder brings trade to the post town below it)
	if tid == "cloudfoot" and Hold.founded(g) and Hold.rank(g) >= 2:
		out.append({"m": "plenty", "d": Hold.rank(g) - 1, "why": "Guiyun sends its carts down through the town."})
	out.sort_custom(func(x, y): return absi(int(x.d)) > absi(int(y.d)))
	_cache[tid] = out
	return out

## Measure `m` of town `tid`: the sum of its causes, kept within CAP.
static func measure(g, tid: String, m: String) -> int:
	var v := 0
	var x := 0
	for c in causes(g, tid):
		if str(c.m) == m:
			if c.has("x"):
				x += int(c.d)
			else:
				v += int(c.d)
	return clampi(v + clampi(x, -CROSS_MAX, CROSS_MAX), -CAP, CAP)

static func total(g, tid: String) -> int:
	return measure(g, tid, "plenty") + measure(g, tid, "peace") + measure(g, tid, "regard")

## The state of town `tid` (STATES).
static func state(g, tid: String) -> String:
	if not TOWNS.has(tid):
		return "easy"
	# (the screenshot tour holds a town in a state for a picture: tour.gd; nothing in the game sets this)
	if g.weal_force.has(tid):
		return str(g.weal_force[tid])
	var pl := measure(g, tid, "plenty")
	var pe := measure(g, tid, "peace")
	var re := measure(g, tid, "regard")
	if re <= LOW:
		return "cold"
	if pe <= LOW:
		return "afraid"
	if pl <= LOW:
		return "lean"
	var sum := pl + pe + re
	if sum >= FESTIVE and mini(pl, mini(pe, re)) >= FESTIVE_EACH:
		return "festive"
	if sum >= THRIVE:
		return "thriving"
	if sum <= WARY:
		return "wary"
	return "easy"

static func rank(g, tid: String) -> int:
	return STATE_ORDER.find(state(g, tid))

## How many towns stand at state `at` or better.
static func count(g, at: String) -> int:
	var n := 0
	var want := STATE_ORDER.find(at)
	for tid in ORDER:
		if rank(g, tid) >= want:
			n += 1
	return n

## The numbers a town's state changes, where the hero is: "price", "wage", "mend" (1.0 anywhere
## that is not a town's own region).
static func mod(g, area: String, key: String) -> float:
	var tid := town_of(area)
	if tid == "":
		return 1.0
	return float(STATES[state(g, tid)].get(key, 1.0))

## A price asked at a counter in region `area`.
static func price(g, area: String, base: int) -> int:
	return maxi(1, int(round(float(base) * mod(g, area, "price"))))

# ---------------------------------------------------------------- gifts, and thanks
static func gift_cost(g) -> int:
	return GIFT_BASE + GIFT_REALM * int(g.realm())

## Why nothing can be given to the chest of town `tid` just now ("" if it can).
static func gift_blocked(g, tid: String) -> String:
	if acts(g, tid, "gift") >= GIFT_MAX:
		return "The chest has had three gifts of you, and the town will not take a fourth: \"We should begin to think it was owed.\""
	if int(g.stones) < gift_cost(g):
		return "It wants %d spirit stones, and you have %d." % [gift_cost(g), int(g.stones)]
	return ""

## Give to the town's chest: stones for the granary, the well-rope and the watch's lamp-oil.
static func give(g, tid: String) -> bool:
	if not TOWNS.has(tid) or gift_blocked(g, tid) != "":
		return false
	g.stones -= gift_cost(g)
	act(g, tid, "gift")
	g.note("Gave to the chest of %s" % str(TOWNS[tid].n).trim_prefix("the "))
	return true

static func thanks_due(g, tid: String) -> bool:
	return TOWNS.has(tid) and state(g, tid) == "festive" and not g.weal.has(tid + "|thanked")

## What a festive town gives him, once.  Returns the stones (0 if there was nothing to give).
static func thank(g, tid: String) -> int:
	if not thanks_due(g, tid):
		return 0
	g.weal[tid + "|thanked"] = 1
	g.weal_n += 1
	var n := THANKS_BASE + THANKS_REALM * int(g.realm())
	g.stones += n
	var hid := Cultures.of_area(str(TOWNS[tid].area))
	if hid != "":
		g.add_hearth(hid, 2)
	g.add_renown(3)
	g.note("%s thanked him: %d spirit stones, and its door open for good" % [str(TOWNS[tid].n).trim_prefix("the "), n])
	return n

## A step of kind "weal" asks that so many towns be left the better for his coming: counted from how
## each stood when the step began (`mark_from`).  A town is the better when its three measures come to
## more than they did; a town that has had every gift it will take of him counts too (nothing more
## can be asked of somebody there).
static func mark_from(g) -> void:
	g.weal_from = {}
	for tid in ORDER:
		g.weal_from[tid] = total(g, tid)

static func is_bettered(g, tid: String) -> bool:
	return total(g, tid) > int(g.weal_from.get(tid, 0)) or (acts(g, tid, "gift") >= GIFT_MAX and measure(g, tid, "plenty") >= CAP)

static func bettered(g) -> int:
	var n := 0
	for tid in ORDER:
		if is_bettered(g, tid):
			n += 1
	return n

## The town such a step would have him give to next: the nearest in the story's own order that he
## has walked into, is not yet the better, and will still take a gift ("" if there is none).
static func wanted(g) -> String:
	for tid in ORDER:
		if not is_bettered(g, tid) and acts(g, tid, "gift") < GIFT_MAX and measure(g, tid, "plenty") < CAP:
			return tid
	return ""

# ---------------------------------------------------------------- what they say
## How whoever answers for a town receives him, by its state (said before anything else at the counter).
const WORDS := {
	"cold": ["You. Say what you came for. The counter is open to everybody; I am told that includes you.", "I have a list of what has been said about you in this town. I shall not read it out. It would take the afternoon."],
	"afraid": ["Keep your voice down, and shut the door behind you. Nobody here opens one twice in an evening if they can help it.", "The watch is doubled and it is not enough. If you have come to do something about it, do it. If not, be gone by dusk."],
	"lean": ["There is not much to show you. There is not much. The granary is at the mark we do not speak of.", "If you are buying, buy. If you are selling, I hope it is something that can be eaten."],
	"wary": ["Well. Here you are. We have heard a good deal, some of it twice and none of it the same way.", "I do not say anything against you. I say only that I count the spoons after everybody now."],
	"easy": [],
	"thriving": ["Sit, sit. There is work for every pair of hands this year, and I have a fair notion whose doing that is.", "The registers have never been so dull. No fires, no feuds, two weddings. I could kiss you, and I am not a kissing person."],
	"festive": ["They are hanging lanterns again. I told them the last ones were still up. They said: then hang them higher. That is your doing.", "Do not try to pay for anything in this town. It embarrasses everybody. It embarrasses me, and I am paid to take money."],
}

## What the people in the street say of how their town stands, by its state.
const STREET := {
	"cold": ["Oh. It's you. ...I have to be somewhere.", "My mother says I am not to talk to you. I am only telling you so you know it is nothing I think myself.", "We heard what you did. Everybody heard. Good day."],
	"afraid": ["Don't stand there in the open! ...No. Nothing. I thought I heard something.", "We bar the door at dusk now. All of us. You would be wise to be indoors yourself.", "They say it passed within a li of the gate, and somebody stood aside for it. I do not say who."],
	"lean": ["Half a bowl today. Half a bowl yesterday. I am becoming very good at halves.", "The stalls open late and shut early. There is nothing on them to guard.", "If you are going towards anywhere with rice in it, I should be glad to hear of it."],
	"wary": ["Good day to you. ...That is all. Good day.", "People say one thing and another about you. I wait and see. I am a great one for waiting and seeing."],
	"thriving": ["Two new stalls by the well since the spring, and neither of them mine, and I am doing well all the same!", "My boy has work. Real work, with a wage. I do not ask how the town came by it. I burn a stick of incense and say your name.", "A lantern at every door this year. We used to share one between three."],
	"festive": ["Come to the square at dusk, %s! Everybody dances. Old Ma dances. It is terrible. You must see it.", "They named a dumpling after you. It is the big one. I am sorry. I voted for the pretty one.", "Nobody has locked a door in this town since the lanterns went up. We have lost the keys, most of us."],
}

## The word whoever answers for town `tid` has for him ("" in an easy town), turning with `i`.
static func word(g, tid: String, i: int) -> String:
	var pool: Array = WORDS.get(state(g, tid), [])
	return "" if pool.is_empty() else str(pool[i % pool.size()])

## What a townsperson of folk.gd town `ftid` says of how the town stands ("" in an easy town), and
## now and then of why: the heaviest thing he did that the town felt.
static func line(g, ftid: String, seed_: int) -> String:
	var tid := of_folk(ftid)
	if tid == "":
		return ""
	var st := state(g, tid)
	var cs := causes(g, tid)
	if seed_ % 3 == 0 and not cs.is_empty():
		var c: Dictionary = cs[seed_ / 3 % mini(3, cs.size())]
		var why := str(c.why)
		if int(c.d) > 0:
			return "They tell it in the street like this: \"%s\" And we are the better for it here. I only say what I hear." % why
		return "They tell it in the street like this: \"%s\" And we have felt it here. I only say what I hear." % why
	var pool: Array = STREET.get(st, [])
	return "" if pool.is_empty() else str(pool[seed_ % pool.size()])

# ---------------------------------------------------------------- what they do
## What somebody standing about in a town does instead of the day's own clip, by the town's state,
## the kind of place they are at and the hour ("" keeps the day's own).  Only what is seen changes:
## where anybody is, and when, is folk.gd's and is the same in every state.
static func mood_clip(st: String, place: String, hour: float, seed_: int, own: String) -> String:
	var evening := hour >= 17.5 and hour < 21.5
	match st:
		"festive":
			if evening and place in ["square", "tea", "inn", "bench", "market", "yard"]:
				return ["dance", "clap", "drink", "dance", "play_flute", "laugh"][seed_ % 6]
		"thriving":
			if place == "market" and seed_ % 3 == 0:
				return ["weigh", "count", "call"][seed_ / 3 % 3]
		"afraid":
			if own in ["idle", "talk", "laugh", "think", "look", "sit_bench", "wave", "clap", "dance"]:
				return ["peer", "look", "peer", "pray"][seed_ % 4]
		"lean":
			if own in ["eat", "laugh", "dance", "clap"]:
				return ["think", "sit_bench", "count"][seed_ % 3]
		"cold":
			if own in ["wave", "laugh", "call", "offer", "clap"]:
				return ["look", "think", "idle"][seed_ % 3]
	return ""

# ---------------------------------------------------------------- the people with names
## What has become of somebody, by what was answered: `npc`, the crossroads and the answers it is
## true of, what is added under their name when he faces them (`tag`) and what they say of it, once
## each time he comes back to them (`line`).  Read through `fate`.
const FATES := [
	{"npc": "smith", "when": ["drawings", ["keep"]], "tag": "with two apprentices", "line": "Two apprentices, since the drawings came down. One of them can read them. The other can lift. Between the two I have nearly one smith, and I am run off my feet."},
	{"npc": "smith", "when": ["drawings", ["burn"]], "tag": "who works alone", "line": "I think of those drawings when the bellows stick. Then I mend the bellows the way my master did. It takes longer. It is mine, at least, when it is done."},
	{"npc": "alchemist", "when": ["garden", ["study"]], "tag": "with a new bed of herbs", "line": "The cuttings from that garden took. All of them. I have a bed of things that should not grow on this mountain, and three of them cure a fever."},
	{"npc": "alchemist", "when": ["garden", ["burn"]], "tag": "who lost a garden", "line": "You burned it. I know why. I have gone through my books for what was in it, and there are eleven I shall never see growing. I do not say you were wrong."},
	{"npc": "farmer_lao", "when": ["bandits", ["mend"]], "tag": "with a hired hand", "line": "One of your bandits hoes my bottom field. He is no good at it. He says nobody ever showed him a thing that grew. He is here before I am every morning."},
	{"npc": "farmer_lao", "when": ["bandits", ["drive"]], "tag": "who bars his door", "line": "They went over the ridge, the ones you drove off. They did not go far. I bar the door at dusk and count the hens at dawn, and so far the count has come right."},
	{"npc": "postmaster_lu", "when": ["roc_egg", ["sell"]], "tag": "with a feather under glass", "line": "The buyer who took that egg paid in three currencies and a feather. I kept the feather. It is as long as the counter. Children come in only to look, and post nothing."},
	{"npc": "boatwright_gao", "when": ["dragon_boon", ["sea"]], "tag": "with three hulls on the slip", "line": "Three hulls on the slip and orders for four more. A safe road for every ship, they tell me somebody asked for. I have taken on my sister's boys and they are both seasick."},
	{"npc": "boatwright_gao", "when": ["dragon_boon", ["rain"]], "tag": "short of orders", "line": "Rain for the valley, was it. Well. The valley is green and nobody wants a boat. I am mending buckets. A man who can build a junk can mend a bucket; it is only the pride that leaks."},
	{"npc": "cartographer_pei", "when": ["cauldron_map", ["copy"]], "tag": "selling rubbings by the hundred", "line": "Rubbings of the cauldron map, forty a week, and every one of them proves my own maps wrong in some new place. I have never been so busy or so ashamed. It is wonderful."},
	{"npc": "caster_wei", "when": ["cauldron_map", ["keep"]], "tag": "keeper of the one map", "line": "It stayed at Tushan. People come nine days to stand in front of it, and I stand beside it and say do not touch. It is the most important thing I have ever said."},
	{"npc": "tofu_sun", "when": ["the_wheel", ["run"]], "tag": "whose mill never stops", "line": "The wheel turns all night and so the stone turns all night, and so I make tofu for three villages and have not slept since the spring. I am rich. Look at my eyes. I am rich."},
	{"npc": "tofu_sun", "when": ["the_wheel", ["down"]], "tag": "who grinds by hand again", "line": "They took the wheel down, and I am back to the hand-stone, a bean at a time. My shoulder remembers it. So does the tofu: it is better. Do not tell anybody I said so."},
	{"npc": "caster_wei", "when": ["the_arms", ["melt"]], "tag": "casting ploughshares", "line": "Halberds in at one end and ploughshares out at the other. I have cast bells all my life and never poured anything that sang as those spearheads did, going down."},
	{"npc": "watchman_zhou", "when": ["the_host", ["home"]], "tag": "with nobody to wake", "line": "The levy went home by the roll, every one. I walk the wall at night and there is nobody on it but me, as it was before. I like it. I only miss having somebody to wake up and complain to."},
	{"npc": "watchman_zhou", "when": ["the_host", ["keep"]], "tag": "with a corporal over him", "line": "A standing host, and so a corporal, and so I am told at what hour to strike the watch I have struck for thirty years. I strike it a little late now. He has not noticed. It is a comfort."},
	{"npc": "fishwife_lu", "when": ["the_tide", ["wall"]], "tag": "with a stall on the wall", "line": "I have a stall on top of the wall of baskets now. The tide comes up, looks at me and goes away again. I sell more fish from up there than I ever did with my feet wet."},
	{"npc": "fishwife_lu", "when": ["the_tide", ["yield"]], "tag": "who lost the low field", "line": "My mother's field is under the water, the low one. You gave it to the tide. ...The crabs that have come up in it are the size of a hat. I am not thanking you. I am telling you the size."},
	{"npc": "tea_seller_pan", "when": ["the_tallies", ["burn"]], "tag": "whose slate is clean", "line": "Half this town owed and now nobody does, and they all sit here and order the good leaf because they can look me in the eye again. Burned tallies. I should have thought of it for my own slate."},
	{"npc": "tea_seller_pan", "when": ["the_tallies", ["collect"]], "tag": "with empty benches", "line": "They paid, to the last notch, the ones who owed. And now they drink water at home. Look at my benches. A debt collected is a customer buried. I do not say it should not have been."},
	{"npc": "porter_niu", "when": ["the_sack", ["share"]], "tag": "with his name on the board", "line": "My name is on the carriers' board, against a strap. Four of us to a load now, and the pay split, and I get home with a back I can stand up in. I did not know my name looked like that."},
	{"npc": "cook_zhou", "when": ["the_sack", ["down"]], "tag": "who cooks for one more", "line": "You are home for supper now, most nights. I have had to find the big pot again. I complained for an hour, and then I cried into the stock, and it was the best I ever made."},
	{"npc": "granny_wen", "when": ["widow", ["kind"]], "tag": "who knows what you told her", "line": "You told that widow he was waiting. I heard. It was a lie, and it was the right one, and I have told a hundred like it at a hundred bedsides. Sit down. You have my trade's hands."},
	{"npc": "storyteller_wu", "when": ["the_echoes", ["write"]], "tag": "with a book of the cave's voices", "line": "You wrote the cave's voices down, and somebody made me a copy. I have forty new stories and every one is true, which is a great hindrance. I have had to learn to tell them straight."},
	{"npc": "well_keeper_zhaya", "when": ["the_hollow", ["cistern"]], "tag": "with water to spare", "line": "A cistern under the hill, for the dry years. I have kept one well for forty years and counted every dipper. Now they send me water. I do not know what to do with a thing I need not count."},
	{"npc": "dyer_su", "when": ["the_kites", ["free"]], "tag": "dyeing kite-silk", "line": "Kites for anybody who can fly one, and every one wants its own colour. I have dyed more silk for the sky this year than for backs. My vats have never been so idle of indigo."},
]

static var _fate_idx := {}

## What has become of named person `npc`, by the journey: {tag, line}, or {} if nothing has.
static func fate(g, npc: String) -> Dictionary:
	if _fate_idx.is_empty():
		for i in FATES.size():
			var id := str(FATES[i].npc)
			if not _fate_idx.has(id):
				_fate_idx[id] = []
			_fate_idx[id].append(i)
	var best := {}
	for i in _fate_idx.get(npc, []):
		var f: Dictionary = FATES[i]
		if Echoes.chosen(g, str(f.when[0])) in f.when[1]:
			best = f
	return best

## What is written under somebody's name when the hero faces them: a named person's fate, or, for
## whoever answers for a town, how the town stands ("" for most people).
static func tag(g, e: Dictionary) -> String:
	var f := fate(g, str(e.get("asset", e.get("id", ""))))
	if f.is_empty():
		f = fate(g, str(e.get("id", "")))
	if not f.is_empty():
		return str(f.tag)
	if e.has("office"):
		var tid := of_office(str(e.office))
		if tid != "" and state(g, tid) != "easy":
			return "of a town that is %s" % str(STATES[state(g, tid)].n).to_lower()
	return ""

# ---------------------------------------------------------------- the page
## One town, for the page: its state, its three measures and the three heaviest reasons.
static func town_text(g, tid: String) -> String:
	var st := state(g, tid)
	var parts: Array = ["%s: %s" % [str(TOWNS[tid].n).trim_prefix("the "), str(STATES[st].n)]]
	parts.append("   plenty %+d   peace %+d   regard %+d" % [measure(g, tid, "plenty"), measure(g, tid, "peace"), measure(g, tid, "regard")])
	var cs := causes(g, tid)
	for i in mini(3, cs.size()):
		parts.append("   %s %s" % ["+" if int(cs[i].d) > 0 else "-", str(cs[i].why)])
	if cs.is_empty():
		parts.append("   Nothing he has done has reached here yet.")
	return "\n".join(parts)

static func summary(g) -> String:
	var by := {}
	for tid in ORDER:
		var st := state(g, tid)
		by[st] = int(by.get(st, 0)) + 1
	var parts: Array = []
	for i in range(STATE_ORDER.size() - 1, -1, -1):
		var st2 := str(STATE_ORDER[i])
		if by.has(st2):
			parts.append("%d %s" % [int(by[st2]), str(STATES[st2].n).to_lower()])
	return "Of eleven towns: " + ", ".join(parts) + "."

## What the end of the story says of the towns (one or two sentences, by how most of them stand).
static func epilogue(g) -> Array:
	var good := count(g, "thriving")
	var bad := 0
	for tid in ORDER:
		if rank(g, tid) < STATE_ORDER.find("easy"):
			bad += 1
	var out: Array = []
	if good >= 6:
		out.append("In %d of the eleven towns there is a lantern at every door that was not there when a sweeper first came down the mountain, and in none of them can anybody quite say when it was hung." % good)
	elif bad >= 4:
		out.append("In %d of the eleven towns the doors are shut a little sooner when his name is said. He knows which. He goes through them by day, and pays for what he breaks." % bad)
	elif good > 0:
		out.append("Some towns are the better for his having passed, and some are as they were, and he has learned that the second is not the smaller gift.")
	return out

# ---------------------------------------------------------------- what is hung at a door
const RED := Color("c8322a")
const GOLD := Color("e8b040")
const PAPER := Color("e8dcc0")
const WOOD := Color("6a4a30")

## What a house of a town in state `st` hangs at its door: built from code, in the door's own space
## (x along the wall, y up from the sill, z out from the wall), `w` the width of the doorway.  It is
## on the wall or over the lintel and never on the ground, so it stands in nobody's way and on no
## tile.  Returns null where a state hangs nothing.
static func dress(st: String, w: float = 1.1, seed_: int = 0) -> Node3D:
	if not st in ["festive", "thriving", "afraid", "lean", "cold"]:
		return null
	var root := Node3D.new()
	var b := MB.new()
	var gl := MB.new()
	var hw := w * 0.5 + 0.22
	match st:
		"festive", "thriving":
			# a paper lantern either side of the door (one, in a town that is only thriving), hung from
			# a peg in the wall; in a festive town a string of pennants across the lintel too
			var sides: Array = [-1.0, 1.0] if st == "festive" else [(-1.0 if seed_ % 2 == 0 else 1.0)]
			for s in sides:
				var top := Vector3(hw * s, 2.05, 0.06)
				b.limb(top, top + Vector3(0, 0, 0.22), 0.015, 0.012, MB.tag(WOOD, MB.WOOD), 4)
				var hang := top + Vector3(0, 0, 0.2)
				b.limb(hang, hang + Vector3(0, -0.14, 0), 0.004, 0.004, MB.tag(Color("3a2a1a"), MB.CLOTH), 3)
				b.lathe(hang + Vector3(0, -0.46, 0), [Vector2(0.045, 0.0), Vector2(0.12, 0.07), Vector2(0.135, 0.16), Vector2(0.12, 0.25), Vector2(0.045, 0.32)], MB.tag(RED, MB.CLOTH), 10)
				b.cyl(hang + Vector3(0, -0.13, 0), 0.05, 0.03, MB.tag(GOLD, MB.METAL), Vector3.ZERO, 8)
				b.cyl(hang + Vector3(0, -0.47, 0), 0.05, 0.03, MB.tag(GOLD, MB.METAL), Vector3.ZERO, 8)
				b.limb(hang + Vector3(0, -0.48, 0), hang + Vector3(0, -0.66, 0), 0.012, 0.003, MB.tag(GOLD, MB.CLOTH), 4)
				gl.ball(hang + Vector3(0, -0.3, 0), 0.19, Color(1.0, 0.55, 0.25, 0.4), true)
			if st == "festive":
				var cols: Array = [RED, GOLD, Color("3a8a5a"), Color("3a6ab8"), PAPER]
				var n := 7
				for i in n:
					var k := (float(i) + 0.5) / float(n)
					var x := lerpf(-hw, hw, k)
					var sag := 0.1 * sin(k * PI)
					var c: Color = cols[(i + seed_) % cols.size()]
					b.leaf(Vector3(x, 2.33 - sag, 0.07), Vector3(x, 2.1 - sag, 0.075), 0.15, MB.tag(c, MB.CLOTH), Vector3(1, 0, 0))
				for i in 8:
					var k0 := float(i) / 8.0
					var k1 := float(i + 1) / 8.0
					b.limb(Vector3(lerpf(-hw, hw, k0), 2.32 - 0.1 * sin(k0 * PI), 0.07), Vector3(lerpf(-hw, hw, k1), 2.32 - 0.1 * sin(k1 * PI), 0.07), 0.004, 0.004, MB.tag(Color("3a2a1a"), MB.CLOTH), 3)
		"afraid":
			# a yellow talisman pasted beside the door, and a branch of peach wood nailed over the lintel
			var s2 := -1.0 if seed_ % 2 == 0 else 1.0
			b.box(Vector3(hw * s2, 1.5, 0.035), Vector3(0.16, 0.42, 0.012), MB.tag(Color("e8c840"), MB.CLOTH))
			b.box(Vector3(hw * s2, 1.58, 0.045), Vector3(0.03, 0.2, 0.006), MB.tag(RED, MB.CLOTH))
			b.box(Vector3(hw * s2, 1.4, 0.045), Vector3(0.09, 0.025, 0.006), MB.tag(RED, MB.CLOTH))
			b.limb(Vector3(-0.3, 2.14, 0.06), Vector3(0.32, 2.2, 0.06), 0.018, 0.01, MB.tag(Color("7a4a3a"), MB.WOOD), 5)
			b.limb(Vector3(0.05, 2.17, 0.06), Vector3(0.2, 2.3, 0.07), 0.008, 0.004, MB.tag(Color("7a4a3a"), MB.WOOD), 4)
		"lean":
			# an empty rice-measure hung mouth down on a peg beside the door
			var s3 := -1.0 if seed_ % 2 == 0 else 1.0
			var at := Vector3(hw * s3, 1.55, 0.06)
			b.limb(at + Vector3(0, 0.16, 0), at + Vector3(0, 0.16, 0.14), 0.012, 0.01, MB.tag(WOOD, MB.WOOD), 4)
			b.lathe(at + Vector3(0, -0.12, 0.13), [Vector2(0.15, 0.0), Vector2(0.14, 0.05), Vector2(0.1, 0.24), Vector2(0.02, 0.27)], MB.tag(Color("b89a62"), MB.WOOD), 10)
		"cold":
			# the door barred: a plank across it at the height of a chest, on two iron staples
			b.box(Vector3(0, 1.1, 0.07), Vector3(w + 0.3, 0.12, 0.045), MB.tag(Color("5a4634"), MB.WOOD))
			for s4 in [-1.0, 1.0]:
				b.box(Vector3((w * 0.5 + 0.06) * s4, 1.1, 0.09), Vector3(0.05, 0.2, 0.03), MB.tag(Color("4a4a52"), MB.METAL))
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not gl.is_empty():
		var gm := MB.mesh_node(root, gl.build(MB.mat_glow()))
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.set_meta("glow", gm)
	return root
