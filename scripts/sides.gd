class_name Sides
extends RefCounted
## Upright towns and crooked ones (the Rivers and Lakes release).
##
## Every town of the land was, until now, the same kind of place: somebody answers for it, a watch
## walks it, and a price on a head is a price on a head.  Down the river, where the sects answer for
## the towns (sects.gd), **a town is what its sect is**.  Two are upright (Reedhaven of the Listening
## Reeds, Clearbell under the Hermitage) and two are crooked (Ashmarket of the Black Water Gate,
## Knifegate of the Wolf Banner).  Every other town is plain: nothing here touches it, so every older
## journey is walked as it was.
##
## What a side does, all of it through pure functions of the state:
##   * `mod(g, town, "price")`: an upright town's counters are kinder to somebody of the Righteous
##     Path and dearer to the Demonic; a crooked town's the other way about (creed.gd weighs him).
##   * `lawless(town)`: nobody in a crooked town reads a bill.  A price on his head hangs at no gate
##     there, the watch does not come, and nothing a wanted man is shut out of is shut (crime.gd).
##   * `purse_due` / `take_purse`: in a crooked town somebody lifts a little off him once a day, the
##     first time he speaks to anybody in its streets, unless the town's sect knows him (sects.gd: a
##     guest of the Gate is not robbed) or he walks the Demonic road himself.  By the day and the
##     town, never by lot, and never much: a day's purse is worth less than the road.
##   * `alms_due` / `take_alms`: in an upright town whoever answers for it sees a wounded traveller
##     mended once a day, for nothing.
##   * `LINES`: what the street says in a town of each side; `WORD`: what whoever answers says of it.
##
## No step, trial, notice or ending asks for any of it, and nothing a side shuts or takes may be
## something a step needs: a crooked town costs a little and an upright one gives a little, no more.

const TOWNS := {"reedhaven": "upright", "clearbell": "upright", "ashmarket": "crooked", "knifegate": "crooked"}
const ORDER := ["upright", "plain", "crooked"]
const NAMES := {"upright": "An upright town", "plain": "", "crooked": "A crooked town"}
const DESC := {
	"upright": "Its sect keeps its word. Counters are kinder to the Righteous and dearer to the Demonic; a wounded traveller is mended once a day for nothing; a bill is honoured.",
	"plain": "",
	"crooked": "Its sect keeps its ledger. Counters are kinder to the Demonic and dearer to the Righteous; nobody reads a bill or keeps a watch; a stranger's purse is lighter by evening.",
}
## what a counter asks, by where he stands between the Righteous Path and the Demonic: [Righteous, between, Demonic]
const PRICE := {"upright": [0.9, 1.0, 1.25], "crooked": [1.2, 1.0, 0.85]}
## the share of his stones a cutpurse lifts, and the most it can be for each great realm he has reached
const PURSE_SHARE := 0.004
const PURSE_REALM := 12
## what is said in the street (short: sixty-four letters at most, and of anybody)
const LINES := {
	"upright": ["You will have eaten. Nobody gets past the landing unfed.", "Leave your pack by the door. It will be there. It always is.",
		"A promise here is a debt, and we pay our debts in daylight.", "If you are hurt, say so at the hall. It costs nothing.",
		"We hang no lock on anything. It would insult the street.", "A bill from upriver? Then we shall want both sides of it."],
	"crooked": ["Keep a hand on your purse. Not that one. The other one.", "No names. I did not ask yours. Do not ask mine.",
		"Everything has a price here. That is the honest part.", "The watch? There was one. It was bought, and then it was sold.",
		"A bill on your head? Nobody here reads. Nobody was taught to.", "You look strong. Good. The weak pay for it by the hour."],
}
## what whoever answers for the town says of what kind of town it is
const WORD := {
	"upright": "This is an upright town. I say it plainly so that you may hold us to it. Say if you are hurt; mind what you promise; nobody will rob you and nobody will let you rob.",
	"crooked": "This is a crooked town, and it does not pretend. Nobody will ask what you have done. Somebody will try your purse before dark: take it as a greeting. Those we know are left alone.",
}
const PURSE_SAID := "Somewhere in the crowd a hand has been in his sleeve and out again. %d spirit stones lighter. In %s that is how a stranger is said good morning to."
const ALMS_SAID := "\"Sit. No, sit. There is no charge for this in %s, and I will not be argued with.\" Health and qi are mended."

## The side of town `tid`: "upright", "crooked", or "plain" for every town that was there before.
static func of(tid: String) -> String:
	return str(TOWNS.get(tid, "plain"))

## The side of the town that hears of region `area` ("plain" where no town does).
static func of_area(area: String) -> String:
	return of(Weal.town_of(area))

static func towns_of(side: String) -> Array:
	var out: Array = []
	for tid in TOWNS:
		if str(TOWNS[tid]) == side:
			out.append(tid)
	return out

## Whether nobody in town `tid` reads a bill (crime.gd).
static func lawless(tid: String) -> bool:
	return of(tid) == "crooked"

## A number the side of town `tid` changes for the journey of `g` ("price": what its counters ask).  1 in
## a plain town, and for somebody who stands between the two roads.
static func mod(g, tid: String, key: String) -> float:
	var s := of(tid)
	if s == "plain" or key != "price":
		return 1.0
	var way := Creed.side(g, "virtue")
	return float(PRICE[s][0 if way > 0 else (2 if way < 0 else 1)])

## What a cutpurse of crooked town `tid` lifts off him today (0 if nobody does): once a day a town, not
## from a guest of its sect, and not from somebody of the Demonic road.
static func purse_due(g, tid: String) -> int:
	if of(tid) != "crooked" or int(g.purse_day.get(tid, -1)) == int(g.day):
		return 0
	if Sects.rank(g, Sects.of_town(tid)) >= 1 or Creed.side(g, "virtue") < 0:
		return 0
	return mini(int(float(g.stones) * PURSE_SHARE), PURSE_REALM * (int(g.realm()) + 1))

## The purse is lifted: the stones are gone, and it is not tried again today.  Returns what was said ("" if
## nothing was taken).
static func take_purse(g, tid: String) -> String:
	var n := purse_due(g, tid)
	g.purse_day[tid] = int(g.day)
	if n <= 0:
		return ""
	g.stones -= n
	g.purses_cut = int(g.purses_cut) + 1
	g.note("A cutpurse in %s: %d spirit stones" % [str(Weal.TOWNS[tid].n), n])
	return PURSE_SAID % [n, str(Weal.TOWNS[tid].n)]

## Whether whoever answers for upright town `tid` would see him mended today: he is hurt, and it has not
## been done since morning.
static func alms_due(g, tid: String) -> bool:
	if of(tid) != "upright" or int(g.alms_day.get(tid, -1)) == int(g.day):
		return false
	for i in g.hp.size():
		# (Yue Ling counts once she walks with him)
		if (i == 0 or bool(g.companion)) and float(g.hp[i]) < float(g.max_hp(i)) * 0.6:
			return true
	return false

## He is mended.  Returns what was said ("" if there was nothing to mend).
static func take_alms(g, tid: String) -> String:
	if not alms_due(g, tid):
		return ""
	g.alms_day[tid] = int(g.day)
	g.heal_full()
	g.alms_taken = int(g.alms_taken) + 1
	return ALMS_SAID % str(Weal.TOWNS[tid].n)

## A line of the street in town `tid` for somebody whose seed is `seed` ("" in a plain town).
static func line(tid: String, seed: int) -> String:
	var s := of(tid)
	if s == "plain":
		return ""
	var ls: Array = LINES[s]
	return str(ls[absi(seed) % ls.size()])
