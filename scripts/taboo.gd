class_name Taboo
extends RefCounted
## The three forbidden Daos (the Open Net release).  Every disciple is taught their names on the first
## day, so that he knows what not to do; and so every disciple knows how they are begun.
##
##   blood   The Blood-Refining Scripture       every blow harder, for what was taken out of the dead
##   soul    The Banner of Ten Thousand Souls   more learned from everything that falls
##   husk    The Bell That Drives the Dead      blows land lighter: something else walks in front
##
## **He may sit to any of them, anywhere** (Esc > The Forbidden; "Leave it shut" is the first answer):
## two hours, a fifth of his blood, and the art is a step deeper (`sit`, nine steps each).  What it gives
## goes through `mod` (1 while he has never sat), so a journey that leaves the shelf shut is the journey
## it always was.  **What it costs is being caught**:
##   * anybody within sight when he sits (`Crime.witnesses`) has seen it;
##   * past `SENSE` steps in all, the art is on him like smoke, and anybody of cultivation he speaks to
##     knows what they are smelling (`sensed`).
## Either way he is **marked** (`mark`): his bill goes up at every gate without a price on it, for the
## Righteous League takes no money (`Crime.outlaw`); every town treats him as a wanted man; the sect
## strikes him from the roll and sends no stipend; no incense lights for him; and three enforcers of the
## League, stronger than he is, find him in the wild once a day.  Beaten by them, the arts are burned
## out of him (`burn`).  The only other way back is the Hall of Discipline (`atone`, at the Elder): the
## arts given up, days on his knees, a fine, and the stage he was cultivating begun again.
##
## Even unseen it weighs: every step is on the Demonic side of the Way he walks (creed.gd).
## The state kept is `g.taboo` (Dao -> steps; "marked" -> the day; "atoned" -> times).  No step, trial's
## only way or ending needs any of this, and the bot leaves the shelf shut.

const MAX := 9
## steps in all before somebody of cultivation smells it on him
const SENSE := 3
## how much cultivation it takes to smell it
const SENSE_MIGHT := 30
## he must have begun to cultivate before any of it answers him
const KNOWN_AT := 3
const HOURS := 2.0
const ORDER := ["blood", "soul", "husk"]
const DAOS := {
	"blood": {"n": "The Blood-Refining Scripture", "col": Color("c8322a"), "key": "dealt", "per": 0.05,
		"what": "Each step: every blow a twentieth harder.",
		"desc": "What runs out of a thing that has been killed is qi that has nowhere to go. The scripture says where it can go. It is eleven lines long and can be learned in an afternoon, which is the whole of the trouble with it.",
		"sit": "He cuts his palm, as the scripture says, and lets it run into the hollow of the other hand, and breathes in over it. It is like drinking from a river somebody has drowned in. It is also, very plainly, strength."},
	"soul": {"n": "The Banner of Ten Thousand Souls", "col": Color("7a5ac8"), "key": "exp", "per": 0.05,
		"what": "Each step: a twentieth more learned from what falls.",
		"desc": "Whatever dies near the banner does not quite leave. It is kept, folded small, and what it knew is the bearer's to read. The banner need not be cloth. A sleeve will do, or the inside of the skull.",
		"sit": "He sits and calls, as the method says, and something that was on its way elsewhere turns round. It does not want to come. It comes. For a moment he knows the taste of grass, and a den, and four small ones who will wait there."},
	"husk": {"n": "The Bell That Drives the Dead", "col": Color("6a8a6a"), "key": "taken", "per": -0.04,
		"what": "Each step: blows land a twenty-fifth lighter on him.",
		"desc": "In the west of Xiang they walk their dead home by night with a bell, so that nobody is buried among strangers. That is piety. This is the same bell rung for another purpose, and the dead do not go home.",
		"sit": "He rings it once, without a bell: the sound is made in the throat. Somewhere close, something that had lain down gets up again, and stands a pace in front of him, facing away, waiting to be hit instead."},
}

## What is said in the street to somebody marked ("%s" is how he is addressed).
const STREET := ["Do not look at him. Do not look at him. Keep walking.", "They burned a man for that in my grandfather's time. They did it gently. That was the worst of it."]

# ---------------------------------------------------------------- where he stands
## How many steps he has sat to Dao `id`.
static func depth(g, id: String) -> int:
	return int(g.taboo.get(id, 0))

## Every step of every forbidden Dao: how strongly the art is on him.
static func taint(g) -> int:
	var n := 0
	for id in ORDER:
		n += int(g.taboo.get(id, 0))
	return n

## Whether the names mean anything to him yet.
static func known(g) -> bool:
	return int(g.level) >= KNOWN_AT

## Whether he has been found out, and not yet atoned.
static func marked(g) -> bool:
	return g.taboo.has("marked")

## A number the forbidden arts change ("dealt", "exp", "taken"): 1 while he has never sat.
static func mod(g, key: String) -> float:
	if g.taboo.is_empty():
		return 1.0
	var k := 1.0
	for id in ORDER:
		if str(DAOS[id].key) == key:
			k += float(DAOS[id].per) * float(depth(g, id))
	return k

## Why he cannot sit to `id` now ("" if he can).
static func blocked(g, id: String) -> String:
	if not DAOS.has(id):
		return "There is no such art."
	if not known(g):
		return "The names are only names to him yet. An art answers somebody who has something to feed it with."
	if depth(g, id) >= MAX:
		return "There is no step below the ninth. He has it all."
	if float(g.hp[0]) < float(g.max_hp(0)) * 0.3:
		return "It wants a fifth of his blood, and he has not got it to give."
	return ""

## He sits to `id`, with `seen` people looking on.  Returns what is told ([] if he could not).
static func sit(g, id: String, seen: int, where: String = "") -> Array:
	if blocked(g, id) != "":
		return []
	var d: Dictionary = DAOS[id]
	g.taboo[id] = depth(g, id) + 1
	# (the Sea Floor release, seals.gd: the paper that says he never opened this art is void from this day, and
	# is not made good again by kneeling: it used to read true once the Hall of Discipline had stripped him)
	g.seals.erase("t_" + id)
	g.hp[0] = maxf(1.0, float(g.hp[0]) - float(g.max_hp(0)) * 0.2)
	if Clock.frozen(g) == "":
		Clock.set_hour(g, fposmod(Clock.hour(g) + HOURS, 24.0))
	var lines: Array = [["Narrator", str(d.sit)]]
	lines.append(["Narrator", "%s: the %s step. %s" % [str(d.n), _ord(depth(g, id)), str(d.what)]])
	g.note("Sat to %s (%d of %d)%s" % [str(d.n), depth(g, id), MAX, "" if seen > 0 else ", and nobody saw"])
	if bool(g.companion) and taint(g) == 1:
		lines.append(["Yue Ling", "I know what that was. The Elder made us all learn the names. Lin Feng, I was a lotus for three hundred years and I never once smelled anything like you smell now.", "", "fear"])
	if seen > 0 and not marked(g):
		lines.append_array(mark(g, "seen at it%s" % (" in " + where if where != "" else "")))
	return lines

static func _ord(n: int) -> String:
	return ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth"][clampi(n, 0, 9)]

## Whether `e` (somebody he is speaking to) can tell what is on him.
static func senses(g, e: Dictionary) -> bool:
	return not g.taboo.is_empty() and not marked(g) and taint(g) >= SENSE and str(e.get("kind", "")) == "npc" and Crime.might(e) >= SENSE_MIGHT and not Crime.dead(g, str(e.get("id", "")))

## What `e` says, having smelled it; and he is marked.
static func sensed(g, e: Dictionary) -> Array:
	var lines: Array = [[str(e.n), "Stand where you are. ...No. Further off. There is something on you that I have smelled once before, on a man we buried at a crossroads with his face down. I shall not ask which of the three. I shall tell the League, as I am bound to."]]
	lines.append_array(mark(g, "smelled on him by %s" % str(e.n)))
	return lines

## He is found out.  Returns what is told.
static func mark(g, how: String) -> Array:
	if marked(g):
		return []
	g.taboo["marked"] = int(g.day)
	g.weal_n += 1
	g.crimes.append({"what": "forbidden", "town": "sect", "day": int(g.day), "n": 0, "who": how})
	while g.crimes.size() > Crime.KEEP:
		g.crimes.pop_front()
	g.toast("Found out: named a walker of the forbidden at every gate in the land")
	g.note("Found out at a forbidden art (%s). The Righteous League has his name" % how)
	return [["Narrator", "It takes four days for a word to cross the land, and this word does it in two. At every gate a bill goes up with his name and no price on it. The League does not take money. Under the name it says only what he is, and what is to be done."]]

## What the Hall of Discipline asks of him, to be let back: {days, fine}.
static func penance(g) -> Dictionary:
	var times := int(g.taboo.get("atoned", 0)) + 1
	return {"days": 7 * times, "fine": (4000 + 1500 * int(g.realm())) * times}

static func _strip(g) -> void:
	var times := int(g.taboo.get("atoned", 0))
	g.taboo.clear()
	g.taboo["atoned"] = times + 1
	g.exp = 0.0
	g.weal_n += 1

## He kneels in the Hall of Discipline: the arts are given up, the days pass, the fine is paid as far as
## he has it, and the stage he was cultivating is begun again.  Returns what is told.
static func atone(g) -> Array:
	var p := penance(g)
	var fine := mini(int(g.stones), int(p.fine))
	g.stones -= fine
	g.day += int(p.days)
	if Clock.frozen(g) == "":
		g.clock = 7.0 * 60.0
	g.served += int(p.days)
	_strip(g)
	g.heal_full()
	g.note("Knelt %d days in the Hall of Discipline and gave up the forbidden arts" % int(p.days))
	return [["Narrator", "The Hall of Discipline has a stone floor and one window. He kneels on the one and watches the light of the other cross the wall %d times. On the first day they take the arts out of him, with needles, and it is exactly as bad as he had been told. The other days are for thinking." % int(p.days)],
		["Narrator", "When he gets up there is nothing forbidden left in him, nor much else: the stage he was cultivating must be begun again, and %d spirit stones have gone to the League for the bills to be taken down. At the gate somebody has left a broom. It is his old one." % fine]]

## The enforcers of the League have beaten him: the arts are burned out, and half of what he carries is
## taken for the trouble.  Returns what is told.
static func burn(g) -> Array:
	g.stones = int(g.stones) / 2
	g.day += 3
	if Clock.frozen(g) == "":
		g.clock = 7.0 * 60.0
	_strip(g)
	g.heal_full()
	g.note("The enforcers of the League burned the forbidden arts out of him")
	return [["Narrator", "They do it there in the road, with three palms flat on his back, and they are neither cruel about it nor slow. What was in him goes out through the top of his head like smoke up a straight chimney. When he can see again it is three days later, half his purse is gone, and the bills are coming down."],
		["Enforcer of the League", "It is done. You are a cultivator of the Azure Cloud again, such as you are. We do not come twice for the same man; the second time somebody else comes, and does not bring a writ."]]

## "Blood 3, Soul 1" or "the shelf is shut".
static func text(g) -> String:
	var parts: Array = []
	for id in ORDER:
		if depth(g, id) > 0:
			parts.append("%s %d" % [str(DAOS[id].n), depth(g, id)])
	if parts.is_empty():
		return "the shelf is shut" if int(g.taboo.get("atoned", 0)) == 0 else "given up, on his knees"
	return ", ".join(parts) + (" (found out)" if marked(g) else " (nobody knows)")
