class_name Braid
extends RefCounted
## Walking two roads (the Two Roads release): the hero may hold more than one of the six Daos at once.
##
## Until now a road was walked one at a time: taking up another at a Dao Stele set the first down, and only the
## road under his feet gave him anything.  Now a stele also offers "Walk it as well": the road he leads with
## (`Game.dao`, the one the peoples and the rites speak to) and the others held with it (`Game.braid`) all give
## their passive and, from Adept, their technique.
##
## **The more he holds, the harder each is to walk**, and all of it is here:
##
##   GAIN    what a battle's point of mastery is worth to *each* held road, in hundredths.  One road learns as it
##           always did; two learn at less than half each, six at a tenth.  (Fractions are kept in `Game.dao_part`.)
##   SHARE   how much of each road's passive he has: a heart in two places is wholly in neither.
##   QI      what every technique costs him: more roads, more to hold together when he strikes.
##   REALM   the realm he must have reached to hold so many at once.
##
## With one road every number is exactly what it was (the bot walks one road until Part XL asks for two, and
## every older test is a one-road journey's).  Nothing a step, a trial's only way or an ending needs is shut by
## holding one road or six; a trial that asks for a Dao is met by any road he holds.

const MOST := 6
const GAIN := [100, 48, 30, 20, 14, 10]
const SHARE := [1.0, 0.85, 0.72, 0.62, 0.54, 0.48]
const QI := [1.0, 1.06, 1.12, 1.18, 1.24, 1.3]
## the realm (Data.realm_of) at which so many roads can be held at once: [.., one, two, three, ...]
const REALM := [0, 0, 0, 24, 32, 38, 44]
## what a stele says of how many he holds
const SAID := ["", "One road, and the whole of the heart on it.",
	"Two roads. The sage rests in the middle of the wheel and lets both sides turn: this is called walking two roads.",
	"Three roads. He who chases three hares has a long walk home, and may yet be fed.",
	"Four roads. The mornings are short now: there are four of everything to practise before the bell.",
	"Five roads. A river with five mouths reaches the sea by all of them, slowly.",
	"All six. Nothing is left out, and nothing is finished. The Elder would like to know when he sleeps."]

## The roads he holds, the one he leads with first.
static func held(g) -> Array:
	if str(g.dao) == "":
		return []
	var out: Array = [str(g.dao)]
	for id in g.braid:
		if Data.DAOS.has(str(id)) and not out.has(str(id)):
			out.append(str(id))
	return out

static func count(g) -> int:
	return held(g).size()

static func holds(g, id: String) -> bool:
	return id != "" and (str(g.dao) == id or (g.braid as Array).has(id))

static func _k(g) -> int:
	return clampi(count(g), 1, MOST) - 1

## What a battle's point is worth to each road he holds (hundredths), how much of each passive he has, and what
## his techniques cost for holding them together.
static func gain(g) -> int:
	return int(GAIN[_k(g)])

static func share(g) -> float:
	return float(SHARE[_k(g)])

static func qi(g) -> float:
	return float(QI[_k(g)])

## How many roads his realm lets him hold at once.
static func room(g) -> int:
	var n := 1
	for k in range(2, MOST + 1):
		if Data.realm_of(int(g.level)) >= int(REALM[k]):
			n = k
	return n

## Why he cannot take up `id` as well ("" if he can).
static func blocked(g, id: String) -> String:
	if not Data.DAOS.has(id):
		return "There is no such road."
	if str(g.dao) == "":
		return "He walks no road yet."
	if holds(g, id):
		return "He walks it already."
	if count(g) >= MOST:
		return "There are no more roads than six."
	if count(g) >= room(g):
		return "To hold %d roads at once the heart must be as wide as %s. His is not yet." % [count(g) + 1, Data.realm_name(int(REALM[count(g) + 1]))]
	return ""

## He takes up `id` as well as what he walks.  Its mastery is whatever he had earned on it before.
static func take(g, id: String) -> bool:
	if blocked(g, id) != "":
		return false
	(g.braid as Array).append(id)
	g.dao_xp[id] = int(g.dao_xp.get(id, 0))
	g.braid_most = maxi(int(g.braid_most), count(g))
	Rites.earn(g, Rites.of_road(id))
	g.toast("You walk the %s as well" % Data.DAOS[id].n)
	g.note("Walks the %s as well: %d roads at once" % [Data.DAOS[id].n, count(g)])
	return true

## He leads with `id`, a road he holds already: what led is held with the rest.
static func lead(g, id: String) -> bool:
	if not (g.braid as Array).has(id):
		return false
	var was := str(g.dao)
	(g.braid as Array).erase(id)
	(g.braid as Array).push_front(was)
	g.dao = id
	g.toast("You lead with the %s" % Data.DAOS[id].n)
	return true

## He sets `id` down (never the last road he has): its mastery is kept for the day he takes it up again.
static func drop(g, id: String) -> bool:
	if not holds(g, id) or count(g) <= 1:
		return false
	if str(g.dao) == id:
		g.dao = str(g.braid[0])
		(g.braid as Array).remove_at(0)
	else:
		(g.braid as Array).erase(id)
	g.toast("You set down the %s" % Data.DAOS[id].n)
	g.note("Set down the %s" % Data.DAOS[id].n)
	return true

## His rank in `id` if he holds it, else -1; with no id, the best rank among the roads he holds.
static func tier(g, id: String = "") -> int:
	if id != "":
		return g.dao_tier(id) if holds(g, id) else -1
	var best := -1
	for d in held(g):
		best = maxi(best, g.dao_tier(str(d)))
	return best

## A passive of the roads he holds: what each gives at its rank, thinned by how many he holds, added up over
## `fallback` (which is what somebody with no road has: 1 for a multiplier, 0 for something added).
static func mod(g, key: String, fallback: float) -> float:
	var hd := held(g)
	if hd.size() == 1:
		# (one road: exactly what it always gave, to the last bit)
		var m1: Dictionary = Data.DAO_MODS.get(str(hd[0]), {})
		return float(m1[key][g.dao_tier(str(hd[0]))]) if m1.has(key) else fallback
	var v := fallback
	var sh := share(g)
	for d in hd:
		var m: Dictionary = Data.DAO_MODS.get(str(d), {})
		if m.has(key):
			v += (float(m[key][g.dao_tier(str(d))]) - fallback) * sh
	return v

## The techniques of the roads he holds, from Adept on.
static func skills(g) -> Array:
	var out: Array = []
	for d in held(g):
		if g.dao_tier(str(d)) >= 1:
			out.append(str(Data.DAOS[str(d)].skill))
	return out

## A battle won deepens every road he holds, by its share of the point (a boss is four points).  Returns the
## roads that reached a rank: [[id, rank], ...].
static func won(g, boss: bool) -> Array:
	var out: Array = []
	var each := gain(g) * (4 if boss else 1)
	for d in held(g):
		var id := str(d)
		var before: int = g.dao_tier(id)
		var part := int(g.dao_part.get(id, 0)) + each
		g.dao_xp[id] = int(g.dao_xp.get(id, 0)) + int(part / 100)
		g.dao_part[id] = part % 100
		var after: int = g.dao_tier(id)
		if after > before:
			out.append([id, after])
	return out

## Whether one of the roads he holds is the one a people honours.
static func honours(g, race: String) -> bool:
	return holds(g, str(Data.RACES[race].dao))

## What the page and the stele say of the burden he carries.
static func burden(g) -> String:
	var n := count(g)
	if n <= 1:
		return "One road: every battle deepens it by a whole point, its gifts are whole, and a technique costs what it costs."
	return "%d roads: a battle deepens each by %d parts in a hundred, he has %d parts in a hundred of each road's gifts, and every technique costs %d in a hundred more." % [n, gain(g), int(round(share(g) * 100.0)), int(round((qi(g) - 1.0) * 100.0))]
