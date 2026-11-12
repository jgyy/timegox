class_name Offices
extends RefCounted
## Who is in charge, and what there is to do for a wage (the Lost Horse release).
##
## The land had one elder, six keepers of hearth fires and a notice board.  It was run, as far as
## anybody could see, by nobody.  Now:
##
##   * **every town has somebody who answers for it** (OFFICES): a headman, a postmaster, a
##     harbour-master, a reeve of the well, a guild-mistress, a market-warden; the roost-speaker of
##     the Feathered Folk, the pearl-reeve of Tearwater, a registrar of arrivals in Youdu; and the
##     sect has its **hall masters** under the Elder: discipline, the outer court, the treasury.  Each
##     sits in the building their office is kept in, in a body of their country, and says what the
##     town is short of this year;
##   * **the Son of Heaven and his Empress** keep a small, poor, very correct court in the Cauldron
##     Hall of Tushan, because whoever holds the Nine Cauldrons is the Son of Heaven and nobody has
##     wanted them moved.  He reigns.  The hearths rule.  He has got used to it;
##   * **a town has trades, and they can be worked at** (TRADES): whoever is found indoors in an inn, a
##     shop, an office, a workshop, a tea-house, a library, a shrine, a hall, a bath-house or a home
##     will take a pair of hands for a shift.  A shift takes hours of the day, pays spirit stones by
##     what the hero's realm is worth to the town, is thanked at the town's hearth the first time, and
##     can be had once a day in each town.  Nothing in the story asks for one, and the bot declines.
##
## Officials are stood by `Rooms.residents` before anybody else in their building.  Everything takes
## the game state `g` as an argument, like trials.gd.

## Who answers for what: `area` and the building (`in`) they are found in, a body, and what they say.
const OFFICES := {
	# ---- the sect: the hall masters under the Elder
	"master_discipline": {"n": "Hall Master Shen of Discipline", "area": "sect", "in": "training_hall", "asset": "folk_guard", "lines": [
		"The Elder forgives. Somebody has to keep the list of what was forgiven. Nine hundred and ninety-nine steps, and I know who skipped which.",
		"A disciple who is never punished learns that rules are weather. A disciple who is always punished learns the same thing. It is a narrow road and I walk it in a bad temper.",
		"I had three years of a sweeper's reports on my desk. Never late, never early, the steps always done from the top. I have nothing against that sweeper. It is very irritating."]},
	"master_outer": {"n": "Hall Master Du of the Outer Court", "area": "sect", "in": "library", "asset": "folk_scholar", "lines": [
		"Two hundred and six outer disciples, forty beds short, and every one of them certain of being a Founder by spring. I count rice. Somebody must.",
		"The inner court asks me for the gifted ones. I send the stubborn ones. In nine years nobody has noticed the difference, and I have stopped expecting them to.",
		"Every child who climbs the steps is tested now, whatever their sleeves look like. It has doubled my work and I would not go back."]},
	"treasurer": {"n": "Treasurer Bao of the Sect", "area": "sect", "in": "hall", "asset": "folk_merchant", "lines": [
		"The sect owns a mountain, a bell, four thousand scrolls and a debt to the tofu-seller of Qingshi that is older than I am. I pay the tofu-seller first.",
		"Spirit stones come up the mountain in ones and go down it in thousands. I have explained this to the Elder. The Elder said it was like water, and went to look at a pine.",
		"When a disciple breaks through there is a feast. When a disciple fails there is a quieter feast. I should like to be consulted about either."]},
	# ---- the towns of the land
	"head_qingshi": {"n": "Headman Luo of Qingshi", "area": "village", "in": "drum_tower", "asset": "folk_grandpa", "lines": [
		"Nineteen roofs when I was made headman, and a quarter with a drum tower since. Nobody voted for the drum. It arrived, and then we needed a tower to keep it in.",
		"A headman settles three things: whose ox, whose water, whose daughter. Everything else in Qingshi is settled by Granny Wen, and I sign it.",
		"Have you eaten? Then sit. The harvest is fair, the road is mended, and somebody has been telling the children they can fly. I should like a word with that person."]},
	"post_cloudfoot": {"n": "Postmaster Ge of Cloudfoot", "area": "mountain", "in": "post_station", "asset": "folk_porter", "lines": [
		"Every letter for the sect stops here, and every excuse from it. I could tell you who writes home and who only says so. I do not. That is the whole of the trade.",
		"Twelve horses, nine riders, and a mountain that eats a pair of boots a month. Cloudfoot is not a town. It is a breath taken before the steps.",
		"A postmaster is mayor of whatever is waiting. Today that is four pilgrims, a coffin, and a goose addressed to nobody."]},
	"reeve_well": {"n": "Samira, Reeve of the Sweet Well", "area": "dunes", "in": "sweet_well", "asset": "folk_oasis_f", "lines": [
		"Peace on your road, and shade at the end of it. I keep the count of the well: so many skins a caravan, so many a camel, none for a man who has fouled water anywhere between here and the sea.",
		"The caravan-masters think they rule Shazhou. They rule the road. The road ends at my rope.",
		"In a dry year I am the most hated woman in the sands, and in a wet year nobody remembers my name. I pray for the second and prepare for the first."]},
	"harbour_longmen": {"n": "Harbour-Master Zeng of Longmen", "area": "longmen", "in": "harbour_office", "asset": "folk_fisher", "lines": [
		"Which way is the water going? Good. Then you know as much as I do, and I have the office. Every hull that comes up the Gate pays me a copper and a piece of news.",
		"The haulers have a guild, the ferrymen have a guild, the carp have the right of way. I sit between the three and write down who hit whom.",
		"They ask why Longmen has no walls. The river comes through twice a year and takes the measure of everything we have built. We build what it lets us keep."]},
	"guild_tushan": {"n": "Guild-Mistress Hu of the Founders", "area": "tushan", "in": "bell_works", "asset": "folk_founder", "lines": [
		"What are you making? Everybody here is making something. The guild decides what it is made of, who may pour it, and what it may be called when it cracks.",
		"There are nine cauldrons in the hall and a Son of Heaven sitting beside them. We cast the cauldrons. Draw what you like from that; the guild has, for four hundred years.",
		"An apprentice asked me whether a bell is finished when it is poured or when it is rung. I made her forewoman. She is insufferable, and the bells are better."]},
	"warden_yanggu": {"n": "Market-Warden Shu of Yanggu", "area": "yanggu", "in": "crossroads_tea", "asset": "folk_merchant", "lines": [
		"Is your lamp lit? Mine is never out. A market that opens before dawn wants a warden who does not sleep, and I have not, properly, since my father held the post.",
		"I weigh the weights. Every scale in Yanggu is true on the day I test it, and I test them on a day nobody knows. They know. It is always the fourth.",
		"We have no soldiers in Yanggu. We have a band, a king of the salt shore who does not live here, and me. Of the three the band is the most use in a riot."]},
	# ---- the towns of the other realms
	"speaker_featherfall": {"n": "Roost-Speaker Lan Ge", "area": "juntian", "in": "rain_ministry", "asset": "folk_yumin", "lines": [
		"The Feathered Folk do not have a mayor. We have whoever is listened to when everybody is shouting, and this year, to my sorrow, it is me.",
		"The Ministry sends the rain down by the ledger. I am asked, weekly, why it fell on a wedding. I say the ledger is older than the bride.",
		"A town that floats has one law: mind the edge. Everything else we argue about, on the wing, at the top of our voices."]},
	"reeve_tearwater": {"n": "Pearl-Reeve Ao Lin", "area": "ninesprings", "in": "pearl_hall", "asset": "folk_jiaoren", "lines": [
		"Every pearl in Tearwater was wept by somebody, and I keep the roll of who, and for what. It is the saddest register in the four realms and the most beautifully kept.",
		"They made me reeve because I do not cry easily. It is a great handicap in trade and a great help at meetings.",
		"The roots of the world come down through my ceiling. I have complained to nobody, there being nobody above them to complain to."]},
	"registrar_youdu": {"n": "Registrar Bo of Arrivals", "area": "youdu", "in": "ward_office", "asset": "folk_shade", "lines": [
		"Name, village, and what you died of. No? Then you are a visitor, and that is the other book, which is very much thinner.",
		"The Dark Capital is the best-run city there is. Nobody here is in a hurry, and nobody has anywhere else to be. I recommend it to every magistrate above.",
		"I have entered kings and I have entered their cooks. The cooks ask about their families. The kings ask whether there has been some mistake."]},
	"reeve_landfall": {"n": "Harbour-Reeve Tang of Landfall", "area": "penglai", "in": "net_house", "asset": "folk_fisher", "lines": [
		"The Headwoman keeps the names. I keep the boats, which is the same list with holes in it.",
		"Two thousand years on an island and we still build every hull as if it were to carry three thousand children home. It is a habit. It has kept the yards busy.",
		"The immortals up the hill are no trouble. They do not eat, they do not vote, and once a century one of them asks what year it is."]},
	# ---- the Son of Heaven and his Empress, where the Nine Cauldrons are
	"emperor": {"n": "The Son of Heaven", "area": "tushan", "in": "cauldron_hall", "asset": "folk_scholar", "lines": [
		"We are the Son of Heaven. You need not kneel; the floor is cold, and the last man who knelt had to be helped up by the Empress. Whoever holds the Nine Cauldrons holds the Mandate, and nobody has wanted them moved.",
		"We reign. The hearths rule. It was explained to our great-grandfather with great courtesy by six old women, and no Son of Heaven has had to raise a tax or an army since. We are told we are much loved. We have very little evidence either way.",
		"A king on the salt shore sends us one shell a year, a matriarch of the horse-folk one foal, the founders of this town their best bell and their worst. We send back a calendar. It is the one thing a throne is for: somebody must say what day it is.",
		"They say a sweeper mended the sky. We should have liked to be asked. We should not have known what to do; but it is the custom to ask."]},
	"empress": {"n": "The Empress", "area": "tushan", "in": "cauldron_hall", "asset": "folk_maiden", "lines": [
		"He is the Son of Heaven. I am the one who knows where the seal is kept, which of the nine cauldrons leaks, and what the founders are owed for the roof.",
		"A court is a household that may not move house. Forty people, four hundred years of ceremony, and an income of gifts. I have turned the outer robes twice.",
		"When the bells of the land rang flat, he wept for a day and then proclaimed a new pitch. The proclamation was wrong by a quarter-tone. Nobody has told him, and nobody is going to.",
		"If you want a thing done, child, ask a hearth. If you want it remembered, come to us. We are very good at remembering; it is all we have been let do."]},
}
const ORDER := ["master_discipline", "master_outer", "treasurer", "head_qingshi", "post_cloudfoot", "reeve_well", "harbour_longmen", "guild_tushan", "warden_yanggu",
	"speaker_featherfall", "reeve_tearwater", "registrar_youdu", "reeve_landfall", "emperor", "empress"]

## The trades of a town, by what the ground floor of a house is used for (rooms.gd USES): what the
## shift is, how many hours of the day it takes, what it pays (a share of `wage`), and what is said
## when it is done.
const TRADES := {
	"inn": {"n": "Wash pots and carry water at the inn", "hours": 3, "pay": 1.0, "done": "Forty bowls, nine pots, and a cauldron that somebody has been cooking the same soup in since the spring. Your hands smell of it for the rest of the day."},
	"shop": {"n": "Mind the counter", "hours": 3, "pay": 1.1, "done": "You sell a comb, a paper of needles and, by mistake, the master's own lunch. The shop-hand says it is the best morning they have had this month."},
	"office": {"n": "Copy the registers", "hours": 4, "pay": 1.3, "done": "Births, deaths, and who owes whom a pig. By the fourth hour your characters have begun to look like the clerk's, which the clerk says is not a compliment to either of you."},
	"workshop": {"n": "Work the bellows and fetch", "hours": 3, "pay": 1.2, "done": "You are trusted with the bellows, the broom, and nothing sharp. At the end of it the journeyman lets you hold the tongs for a moment, the way one lets a child hold a baby."},
	"teahouse": {"n": "Carry the pots round", "hours": 2, "pay": 0.8, "done": "First pot for washing the cups, second for drinking, third for talking. You carry forty of each and hear every piece of news in the town, twice, with different endings."},
	"library": {"n": "Shelve and dust", "hours": 3, "pay": 1.0, "done": "Every scroll back where it belongs, which is behind the one where you would expect it. You find a pressed flower in a treatise on drainage, and put it back."},
	"shrine": {"n": "Sweep the court and trim the lamps", "hours": 2, "pay": 0.7, "done": "It is a court like any other court, and a broom like any other broom. The acolyte watches you do the steps from the top down and asks, quite seriously, where you trained."},
	"hall": {"n": "Stand at the door and carry messages", "hours": 3, "pay": 1.0, "done": "Nine messages, of which six are the same message going the other way. You are thanked by everybody for the three."},
	"home": {"n": "Chop wood, draw water, mend what is broken", "hours": 2, "pay": 0.7, "done": "A woodpile, two buckets, a hinge and a long account of the neighbours. You are given a bowl of something hot over the wage, and it is the better half of the pay."},
	"bath": {"n": "Stoke the fires and carry towels", "hours": 2, "pay": 0.9, "done": "Hot to the left, very hot to the right. By the end of the shift you are cleaner than you have been in a year, mostly by accident."},
}
const TRADE_ORDER := ["home", "inn", "shop", "office", "workshop", "teahouse", "library", "shrine", "hall", "bath"]

## The officials found in building `bld` of region `area`, in the order they are stood.
static func seated(area: String, bld: String) -> Array:
	var out: Array = []
	for id in ORDER:
		if str(OFFICES[id].area) == area and str(OFFICES[id]["in"]) == bld:
			out.append(id)
	return out

## What a shift is worth to a town: more for a hero of a higher realm (a cultivator's hour is dear),
## never a fortune (a day of shifts is a fraction of what an hour of the road pays).
static func wage(g, use: String) -> int:
	return int(round((30.0 + 14.0 * float(g.level)) * float(TRADES.get(use, {}).get("pay", 1.0))))

## Why a shift of trade `use` cannot be worked in town `town` just now ("" if it can).
static func blocked(g, use: String, town: String) -> String:
	if not TRADES.has(use):
		return "There is no work here for a stranger's hands."
	if int(g.shift_day.get(town, -1)) == int(g.day):
		return "One shift a day in a town: come back tomorrow, when they have forgotten how you fold a towel."
	var h := Clock.hour(g)
	if h < 6.0 or h >= 20.0:
		return "Nobody is hiring at this hour. Come back by daylight."
	return ""

## Work a shift of `use` in `town` (a region id): the hours go, the wage is paid, the town's hearth
## thanks a first shift at each trade.  Returns what is said of it ("" if it could not be worked).
static func work(g, use: String, town: String) -> String:
	if blocked(g, use, town) != "":
		return ""
	var t: Dictionary = TRADES[use]
	Clock.set_hour(g, minf(23.5, Clock.hour(g) + float(t.hours)))
	var pay := wage(g, use)
	g.stones += pay
	g.shift_day[town] = int(g.day)
	var first: bool = not g.shifts.has(use)
	g.shifts[use] = int(g.shifts.get(use, 0)) + 1
	var hid := Cultures.of_area(town)
	if first and hid != "":
		g.add_hearth(hid, 1)
	g.toast("A shift worked: +%d spirit stones" % pay)
	g.note("Worked a shift: %s (%d spirit stones)" % [str(t.n).to_lower(), pay])
	return str(t.done)

## How many shifts have been worked, and at how many trades.
static func worked(g) -> Array:
	var n := 0
	for k in g.shifts:
		n += int(g.shifts[k])
	return [n, g.shifts.size()]
