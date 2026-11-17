class_name Crime
extends RefCounted
## The law of the land (the Open Net release): anybody can be struck down, and somebody always answers for it.
##
## **Anybody who stands in the land can be killed by a hero strong enough** (`might`, `strike`): the people
## of the towns, whoever is found indoors, whoever answers for a town, the people of the story, the Elder
## himself.  F, facing somebody, asks first ("Sheathe it" is the first answer).  A child is never struck
## (`CHILD`): the sword does not leave the sheath.  Somebody too strong for him puts him on his back, and
## that is a crime too, for the one he drew on saw it.
##
## **What was seen is answered for** (`witnesses`, `record`): a price is put on his head in the town that
## hears of the region (`Weal.town_of`), by what was done and to whom.  While it stands (`standing`):
## the town's counters ask more, nobody there hires him, rides with him or trusts him with a bag
## (`shut`, asked in the pure functions that offer those things), and **the watch** comes for him once a
## day in the town's own streets (`watch_due`): pay the price, go with them (`serve`: days in a circle
## drawn on the ground), run (`flee`), or draw on the watch (`watch_group`, `resisted`, `taken`).  A price
## heavy enough makes him an **outlaw** in every town, and brings **bounty-takers** out of the reeds once a
## day in the wild (`hunt_due`, `hunters`).  What nobody saw is not answered for, and is not forgotten
## either: the town is the poorer in peace and the Way he walks is weighed by it.
##
## **The dead stay dead, and the story goes on without them** (`dead`, `mute`): where somebody of the story
## stood there is a mound and a tablet (`grave`, built from code and drawn in their place; nothing is
## moved in the world), whatever step needed a word with them is done at the grave with their lines
## unsaid, and a counter they kept is kept by whoever came after, at a worse price.  One of the people of
## the towns is gone from the street until somebody new has taken the place (`MOURN` days).
##
## Everything here is a pure function of the game state.  The state kept: `g.slain` (id -> {n, day, area,
## town, seen, might}), `g.bounty` (town -> spirit stones), `g.crimes` (the last of what is charged),
## `g.watch_day`, `g.hunter_day`, `g.hunted`, `g.served`, `g.bounty_paid`.  The bot draws on nobody and
## is wanted nowhere, so its journey is the same; **no step, trial's only way or ending needs a crime**,
## and no step is stopped by a price on his head: it only costs more.

## days until somebody new has taken the place of one of the people of the towns
const MOURN := 5
## he must be this many levels above somebody to strike them down
const EDGE := 1
## nobody is seen from further off than this (tiles), by day and after dark
const SEEN_DAY := 7
const SEEN_NIGHT := 4

## What can be charged: what the bill says, the price (spirit stones, and so many more for each great
## realm he has reached: a cultivator's bill is written by people who know what he can pay), and how
## much it weighs on the Way he walks.
const CRIMES := {
	"kill": {"n": "A killing", "base": 1500, "realm": 600, "bill": "for the killing of %s"},
	"kin": {"n": "The killing of one of his own sect", "base": 3000, "realm": 900, "bill": "for the killing of %s, of his own sect"},
	"office": {"n": "The killing of somebody who answers for a town", "base": 5000, "realm": 1500, "bill": "for the killing of %s, who answered for the town"},
	"assault": {"n": "Drawing on somebody", "base": 300, "realm": 120, "bill": "for drawing a sword on %s"},
	"watch": {"n": "Drawing on the watch", "base": 2500, "realm": 800, "bill": "for cutting down the watch of %s"},
	"flight": {"n": "Running from the watch", "base": 200, "realm": 80, "bill": "for running from the watch of %s"},
	"forbidden": {"n": "A forbidden art", "base": 4000, "realm": 1500, "bill": "for an art the precepts forbid, %s"},
	# the Unpicked Road release (trifles.gd): what was somebody's, pocketed while somebody looked
	"theft": {"n": "Walking off with what was somebody's", "base": 60, "realm": 25, "bill": "for walking off with %s"},
}
## how many of the charges are remembered on the page
const KEEP := 24
## a price this heavy (and so much more a great realm) makes him an outlaw in every town
const OUTLAW := 6000
const OUTLAW_REALM := 2000
## and one this heavy brings bounty-takers out into the wild
const HUNT := 2500
const HUNT_REALM := 800
## what a day in the circle is counted as, towards a price served and not paid
const DAY_WORTH := 400
const DAY_REALM := 60
const SERVE_MAX := 9

## What the three standings are called, and what the page says of each.
const STANDINGS := [
	{"n": "A clean name", "col": Color("a8d8a0"), "desc": "No price on his head in any town, and nobody dead by his hand. Doors open as they always did."},
	{"n": "Wanted", "col": Color("e8b040"), "desc": "A bill with his face on it hangs in at least one town. There nobody hires him, a broken thing costs more, and the watch comes once a day; and the sect's counters ask a quarter more."},
	{"n": "Outlaw", "col": Color("d84a3a"), "desc": "His bill hangs at every gate in the land. Every town treats him as a wanted man, and bounty-takers follow him into the wild."},
]

## What a wanted man cannot do in a town where his bill hangs, and what is said.
const SHUT := {
	"work": "\"There is a bill at the gate with your face on it. I have read it twice. No.\" The door is not slammed; it is simply shut.",
	"fare": "They look at the driver, and then at the bill on the gatepost, and decide that they will walk.",
	"bag": "\"The town's seal, in a hand the town has a price on? Go and see the watch first. They are looking for you.\"",
	"coach": "\"The coach carries the post. The post does not travel with a man whose bill is nailed to my own door.\"",
	"gift": "\"The chest takes nothing from a hand the town is still owed for. Settle with the watch, and then come back.\"",
}

## People nobody could mistake for an easy mark: how many levels of cultivation stand behind each
## (everybody else is weighed by `might`).
const MIGHT := {"elder": 66, "smith": 24, "alchemist": 22, "treasurer": 18, "granny_wen": 1, "master_discipline": 48, "master_outer": 44,
	"dicer_du": 3}
## titles that mean cultivation, and what each adds
const TITLED := {"Elder": 12, "Patriarch": 14, "Master": 8, "Abbot": 8, "Immortal": 16, "General": 6, "King": 6, "Lord": 6, "Lady": 4, "Sage": 10, "Keeper": 3, "Captain": 4,
	"Founder": 16, "Echo": 12, "Marshal": 6, "Emperor": 4, "Empress": 4, "Queen": 6, "Monk": 4, "Hermit": 6, "Judge": 5}
## roles of the people of the towns who carry something
const ARMED := {"guard": 8, "watchman": 6, "huntsman": 5, "hunter": 5, "disciple": 7, "monk": 6, "hermit": 9, "woodcutter": 3,
	# (the Tall People release: nobody of the Great People has cultivated a day, and nobody has needed to)
	"giant": 14}
## children of the story whose names do not say so (their bodies are a child's: art/characters)
const CHILD := ["stableboy_shitou", "camel_boy_temur", "ox_herd_niu", "ship_boy_ah_fu", "furnace_boy", "li_bai", "zeng_shen"]
## might is never past this, whatever the titles
const MIGHT_MAX := 110

# ---------------------------------------------------------------- how strong somebody is
static var _story_lv := {}

## The level the story expects of the hero when step `sid` is reached (the last breakthrough before it).
static func story_level(sid: String) -> int:
	if sid == "":
		return 0
	if _story_lv.has(sid):
		return int(_story_lv[sid])
	var lv := 0
	var at := Data.step_index(sid)
	for i in mini(at, Data.STEPS.size()):
		var s: Dictionary = Data.STEPS[i]
		if str(s.kind) == "breakthrough":
			lv = int(s.to)
	_story_lv[sid] = lv
	return lv

## Whether `e` is somebody (a person standing in the land: of the story, of a town, of a house).
static func is_person(e: Dictionary) -> bool:
	return str(e.get("kind", "")) in ["npc", "folk"]

## Whether `e` is a child (never struck).
static func is_child(e: Dictionary) -> bool:
	if str(e.get("kind", "")) == "folk":
		return bool((e.p as Dictionary).get("kid", false))
	var a := str(e.get("asset", ""))
	if str(e.get("id", "")) in CHILD or a in CHILD:
		return true
	return a in Folk.KID or str(e.get("n", "")).contains("Aged") or str(e.get("n", "")).begins_with("Little ")

## How many levels of cultivation stand behind `e`: he must be `EDGE` above it to strike them down.
static func might(e: Dictionary) -> int:
	var id := str(e.get("id", ""))
	if MIGHT.has(id):
		return int(MIGHT[id])
	if str(e.get("kind", "")) == "folk":
		var p: Dictionary = e.p
		return int(ARMED.get(str(p.role), 0)) + int(p.seed) % 3
	var m := 0
	var asset := str(e.get("asset", ""))
	var plain := asset.begins_with("folk_")
	if e.has("office"):
		# whoever answers for a town has the town's guard at the door
		m = 30
	elif e.has("trade") or id.begins_with("settler:") or id.begins_with("who:"):
		m = 1 + absi(hash(id)) % 4
	else:
		var v: Array = e.get("vis", ["", ""])
		m = story_level(str(v[0]))
		if plain:
			m = mini(m, 6) + absi(hash(id)) % 3
		else:
			m += 3
	var nm := str(e.get("n", ""))
	for t in TITLED:
		if nm.contains(str(t)):
			m += int(TITLED[t])
			break
	return clampi(m, 0, MIGHT_MAX)

## Whether he is strong enough to strike `e` down.
static func can_kill(g, e: Dictionary) -> bool:
	return is_person(e) and not is_child(e) and int(g.level) >= might(e) + EDGE

## What is said of how the two of them stand, before he draws.
static func weigh(g, e: Dictionary) -> String:
	if is_child(e):
		return "A child. The sword does not leave the sheath, and nothing he could tell himself would make it."
	var m := might(e)
	if int(g.level) >= m + EDGE + 10:
		return "It would be over before %s had seen the blade. There is nothing here that could stop him. That is the whole of the matter, and it settles nothing." % str(e.n)
	if int(g.level) >= m + EDGE:
		return "He is the stronger: %s has the cultivation of %s at most. It would be done in a breath, and stay done." % [str(e.n), Data.level_name(maxi(0, m))]
	return "%s is not somebody he can put down: there is the cultivation of %s or better behind that stillness. If he draws he will be on his back, and it will have been seen." % [str(e.n), Data.level_name(mini(Data.MAX_LEVEL, m))]

# ---------------------------------------------------------------- who saw
## How far off somebody sees what is done, at the hour of `g`.
static func sight(g) -> int:
	return SEEN_NIGHT if Clock.is_night(Clock.hour(g)) else SEEN_DAY

## How many people saw what was done at `tile` of world `wd` (not counting `but`, the one it was done
## to): whoever of the story and the houses stands within sight (`shown`: whether an entity is in the
## land now), and the people of the towns who are out.
static func witnesses(g, wd: Dictionary, tile: Vector2i, but: String = "", shown: Callable = Callable()) -> int:
	var n := 0
	var r := sight(g)
	for e in wd.get("ents", []):
		if str(e.kind) != "npc" or str(e.id) == but or dead(g, str(e.id)):
			continue
		var d := maxi(absi(int(e.pos.x) - tile.x), absi(int(e.pos.y) - tile.y))
		if d > r or (shown.is_valid() and not bool(shown.call(e))):
			continue
		n += 1
	if wd.has("owner") and not wd.has("level"):
		var area := Atlas.owner_id(wd, tile)
		for p in Folk.of_area(wd, area):
			if str(p.id) == but or gone(g, str(p.id)):
				continue
			var st := Folk.state(wd, p, float(g.clock))
			if not bool(st.vis):
				continue
			if (st.at as Vector2).distance_to(Vector2(tile) + Vector2(0.5, 0.5)) <= float(r):
				n += 1
	return n

# ---------------------------------------------------------------- the dead
## Whether `id` was struck down by him.
static func slain(g, id: String) -> bool:
	return g.slain.has(id)

## Whether one of the people of the towns is gone from the street (struck down, and nobody new yet).
static func gone(g, id: String) -> bool:
	return g.slain.has(id) and int(g.day) - int(g.slain[id].day) < MOURN

## Whether somebody new stands where one of the people of the towns was struck down.
static func replaced(g, id: String) -> bool:
	return g.slain.has(id) and id.begins_with("folk:") and not gone(g, id)

## Whether a grave stands where `id` stood (somebody of the story, of a house or of an office: for good).
static func dead(g, id: String) -> bool:
	return g.slain.has(id) and not id.begins_with("folk:")

## How many are dead by his hand (`seen_only`: of those, the ones somebody saw).
static func count(g, seen_only: bool = false) -> int:
	var n := int(g.watch_slain)
	for id in g.slain:
		n += int(g.slain[id].get("seen_n", 1 if bool(g.slain[id].seen) else 0)) if seen_only else int(g.slain[id].get("times", 1))
	return n

## What the counter of somebody of the story costs once they are dead by his hand and somebody else keeps
## it: a quarter more, as whoever came after says (`heir_line`).  1 for the living.
static func heir_k(g, id: String) -> float:
	return HEIR_K if not g.slain.is_empty() and dead(g, id) else 1.0

const HEIR_K := 1.25

## What is said at the place where `e` stood.
static func grave_line(g, e: Dictionary) -> String:
	var rec: Dictionary = g.slain.get(str(e.id), {})
	var nm := str(rec.get("n", e.get("n", "somebody")))
	var days := int(g.day) - int(rec.get("day", g.day))
	var when := "this morning's earth" if days <= 0 else ("earth %d day%s old" % [days, "" if days == 1 else "s"] if days < 30 else "earth the grass has taken")
	if bool(rec.get("seen", false)):
		return "A mound of %s, and a tablet: %s. Under the name somebody has cut, smaller, who did it. It is his name." % [when, nm]
	return "A mound of %s, and a tablet: %s. Nothing is cut under the name. Lin Feng knows what would be." % [when, nm]

## What whoever keeps a dead person's counter says before they serve him.
static func heir_line(g, e: Dictionary) -> String:
	var nm := str(g.slain.get(str(e.id), {}).get("n", e.get("n", "")))
	return "Somebody else keeps what %s kept, and does not look up. \"It is a quarter more now. You know why.\"" % nm

## A conversation with the lines of the dead unsaid: where somebody he struck down would have spoken
## there is one line of what is there instead.  Everybody else says what they said.
static func mute(g, lines: Array) -> Array:
	if g.slain.is_empty():
		return lines
	var names := {}
	for id in g.slain:
		if not str(id).begins_with("folk:") and not str(id).begins_with("res:") and not str(id).begins_with("apt:"):
			names[str(g.slain[id].n)] = true
	if names.is_empty():
		return lines
	var out: Array = []
	var told := {}
	for ln in lines:
		var sp := str(ln[0])
		var who := ""
		for nm in names:
			if sp == nm or sp.begins_with(str(nm) + ",") or str(nm).begins_with(sp + ","):
				who = str(nm)
				break
		if who == "":
			out.append(ln)
		elif not told.has(who):
			told[who] = true
			out.append(["Narrator", "%s does not answer. There is a mound where the answer would have come from, and what was to have been said here is not said by anybody." % who])
	return out

# ---------------------------------------------------------------- the price on his head
static func _price(g, what: String, k: float = 1.0) -> int:
	var c: Dictionary = CRIMES[what]
	return int(round(float(int(c.base) + int(c.realm) * int(g.realm())) * k / 10.0)) * 10

## Charge him with `what` in town `tid` (a town of weal.gd), done to `who`: the price goes on his head
## there and the bill is written.  Returns the price.
static func record(g, what: String, tid: String, who: String, k: float = 1.0) -> int:
	if not Weal.TOWNS.has(tid) or not CRIMES.has(what):
		return 0
	var n := _price(g, what, k)
	g.bounty[tid] = int(g.bounty.get(tid, 0)) + n
	g.crimes.append({"what": what, "town": tid, "day": int(g.day), "n": n, "who": who})
	while g.crimes.size() > KEEP:
		g.crimes.pop_front()
	g.weal_n += 1
	var tn := str(Weal.TOWNS[tid].n).trim_prefix("the ")
	g.toast("A price on your head in %s: %d spirit stones" % [tn, int(g.bounty[tid])])
	g.note("Wanted in %s %s: %d spirit stones" % [tn, str(CRIMES[what].bill) % who, n])
	return n

## The price on his head in town `tid`.
static func price(g, tid: String) -> int:
	return int(g.bounty.get(tid, 0))

## Everything on his head, in every town.
static func heat(g) -> int:
	var n := 0
	for t in g.bounty:
		n += int(g.bounty[t])
	return n

## Whether his bill hangs at every gate: a price heavy enough, or an art the precepts forbid found out.
static func outlaw(g) -> bool:
	return Taboo.marked(g) or heat(g) >= OUTLAW + OUTLAW_REALM * int(g.realm())

## How he stands in town `tid`: 0 a clean name there, 1 wanted, 2 an outlaw.
static func standing(g, tid: String) -> int:
	if outlaw(g):
		return 2
	return 1 if price(g, tid) > 0 else 0

## How he stands in the land at large (the worst of it).
static func worst(g) -> int:
	if outlaw(g):
		return 2
	return 1 if heat(g) > 0 else 0

## Whether nothing at all is held against him: nobody dead, no bill, no forbidden art.
static func clean(g) -> bool:
	# (a bill paid or served is no bill: somebody who drew once, was put on his back and settled with the watch
	# was told "a clean name" by the page of the Law and "not clean" at every trial, for good.  What stays is
	# what the trial names: somebody dead, a bill that hangs, the shelf ever opened)
	return g.slain.is_empty() and int(g.watch_slain) == 0 and heat(g) == 0 and g.taboo.is_empty()

## Why `what` (a key of SHUT) cannot be done in region `area` ("" if it can).
static func shut(g, area: String, what: String) -> String:
	if g.bounty.is_empty() and not Taboo.marked(g):
		return ""
	if not SHUT.has(what) or standing(g, Weal.town_of(area)) == 0:
		return ""
	return str(SHUT[what])

## A number his standing changes in town `tid` ("price": what the sect's counters ask; "mend": what a
## broken thing costs there).  1 with a clean name.
static func mod(g, tid: String, key: String) -> float:
	if g.bounty.is_empty() and g.slain.is_empty() and not Taboo.marked(g):
		return 1.0
	var k := 1.0
	if key == "price" or key == "mend":
		# (the sect's counters have heard of a bill wherever it hangs)
		var st := standing(g, tid)
		if tid == "sect" and st == 0 and heat(g) > 0:
			st = 1
		k = [1.0, 1.25, 1.5][st]
		# (and where somebody who kept a counter is dead by his hand, whoever came after asks more)
		for id in g.slain:
			if str(g.slain[id].town) == tid and not str(id).begins_with("folk:"):
				k *= 1.25
				break
	return k

## The town that answers for what is done in region `area`: its own, else the first that hears of it.
static func town_for(area: String) -> String:
	var t := Weal.town_of(area)
	if t != "":
		return t
	var h: Array = Weal.hears(area)
	return str(h[0]) if not h.is_empty() else ""

# ---------------------------------------------------------------- drawing on somebody
## He draws on `e`, with `seen` people looking on (not counting `e`).  Returns {how: "child" | "slain" |
## "thrown", lines, price}.  Somebody struck down is dead for good; somebody too strong puts him on his
## back, and saw it.
static func strike(g, e: Dictionary, seen: int) -> Dictionary:
	var id := str(e.id)
	var nm := str(e.n)
	var area := str(e.get("area", g.area))
	var tid := town_for(area)
	if not is_person(e) or is_child(e) or g.slain.has(id) and not replaced(g, id):
		return {"how": "child", "lines": [["Narrator", weigh(g, e)]], "price": 0}
	var m := might(e)
	if int(g.level) < m + EDGE:
		# too strong for him: he is put down, and it was seen by the one he drew on
		g.hp[0] = maxf(1.0, float(g.hp[0]) * 0.25)
		g.thrown += 1
		var p0 := record(g, "assault", tid, nm)
		Weal.act(g, tid, "drawn")
		return {"how": "thrown", "price": p0, "lines": [
			["Narrator", "The sword is a hand's width out of the sheath when Lin Feng finds that he is looking at the sky. %s has not moved from where they stood. There is a foot, not unkindly, on his wrist." % nm],
			[nm, "Put it away. I shall say what I saw to whoever asks me, and somebody will ask."]]}
	var what := "kill"
	if e.has("office"):
		what = "office"
	elif area == "sect" and not str(e.get("asset", "")).begins_with("folk_") and str(e.get("kind", "")) == "npc":
		what = "kin"
	# (somebody new in the place of one of the street, struck down in turn: what was seen before was still seen)
	var was: Dictionary = g.slain.get(id, {})
	g.slain[id] = {"n": nm, "day": int(g.day), "area": area, "town": tid, "seen": seen > 0 or bool(was.get("seen", false)), "might": m, "kind": str(e.kind),
		"times": int(was.get("times", 0)) + 1, "seen_n": int(was.get("seen_n", 0)) + (1 if seen > 0 else 0)}
	g.slain_n += 1
	# (the same person stands elsewhere later in the story under another id (qiu_ye, qiu_ye_grave, ...): dead there too)
	if str(e.kind) == "npc" and not (id.begins_with("res:") or id.begins_with("apt:") or id.begins_with("who:") or id.begins_with("settler:")):
		for a2 in Data.AREAS:
			for o in Data.AREAS[a2].get("npcs", []):
				if str(o.n) == nm and str(o.id) != id and not g.slain.has(str(o.id)):
					var rec2: Dictionary = (g.slain[id] as Dictionary).duplicate()
					rec2["area"] = str(a2)
					rec2["town"] = ""
					rec2["times"] = 0
					rec2["seen_n"] = 0
					rec2["alias"] = id
					g.slain[str(o.id)] = rec2
	# the purse: what somebody of that standing carries
	var purse := 20 + 35 * m
	g.stones += purse
	Weal.act(g, tid, "slain")
	var lines: Array = [["Narrator", "It is one stroke, and there is no fight in it. %s is standing, and then is not. It takes less time than deciding to. The land does not stop; a bird goes on with what it was saying." % nm]]
	var p1 := 0
	if seen > 0:
		p1 = record(g, what, tid, nm, 1.0 + float(m) / 30.0)
		lines.append(["Narrator", "It was seen. %s: somebody is running, and somebody else is standing very still with a hand over a child's eyes. By nightfall there will be a bill at the gate." % ("One pair of eyes" if seen == 1 else "%d pairs of eyes" % seen)])
	else:
		g.crimes.append({"what": what, "town": tid, "day": int(g.day), "n": 0, "who": nm})
		while g.crimes.size() > KEEP:
			g.crimes.pop_front()
		lines.append(["Narrator", "Nobody saw. There will be no bill for this one. There will be a mound, and a town that locks its doors a little earlier, and one person in the land who knows why."])
	lines.append(["Narrator", "In the sleeve: %d spirit stones. He counts them, since he has taken them." % purse])
	if bool(g.companion):
		lines.append(["Yue Ling", "...Lin Feng. I am not going to ask you why. I am going to remember that I did not have to, once." if g.slain_n <= 1 else "That is %d. I am still here. I do not know for how much longer that will be true, and neither do you." % g.slain_n, "", "sorrow"])
		g.bond = maxi(0, int(g.bond) - 4)
	var hid := Cultures.of_area(area)
	if hid != "":
		g.hearth[hid] = maxi(0, int(g.hearth.get(hid, 0)) - 6)
	g.note("Struck down %s%s" % [nm, "" if seen > 0 else ", and nobody saw"])
	return {"how": "slain", "lines": lines, "price": p1, "purse": purse}

# ---------------------------------------------------------------- the watch
## The watch that is due to come for him in region `area` now: {tid, n, price} or {} (no bill in this
## town, not the town's own streets, or they have been already today).
static func watch_due(g, area: String) -> Dictionary:
	if g.bounty.is_empty() and not Taboo.marked(g):
		return {}
	var tid := Weal.town_of(area)
	if tid == "" or str(Weal.TOWNS[tid].area) != area or int(g.watch_day.get(tid, -1)) == int(g.day):
		return {}
	var owed := price(g, tid)
	if outlaw(g):
		owed = heat(g)
	if owed <= 0:
		return {}
	return {"tid": tid, "n": str(Weal.TOWNS[tid].n).trim_prefix("the "), "price": owed}

## What the watch says as it comes up.
static func watch_lines(g, w: Dictionary) -> Array:
	return [["Narrator", "Three of the watch of %s come up the street abreast, not quickly. The one in the middle has a bill in his hand, and looks from it to Lin Feng and back like a man checking a weight." % str(w.n)],
		["Captain of the Watch", "That is you. %d spirit stones, it says. You may pay it, and I shall tear this up in front of you. You may come with us, and sit it out. Or you may do the other thing, and I shall be sorry, and so will you." % int(w.price)]]

## How many days in the circle a price of `owed` is.
static func days_for(g, owed: int) -> int:
	return clampi(int(ceil(float(owed) / float(DAY_WORTH + DAY_REALM * int(g.realm())))), 1, SERVE_MAX)

static func _clear(g, w: Dictionary) -> void:
	if outlaw(g) or int(w.price) >= heat(g):
		g.bounty.clear()
	else:
		g.bounty.erase(str(w.tid))
	g.watch_day[str(w.tid)] = int(g.day)
	g.weal_n += 1

## Pay the price to the watch: false if he has not got it.
static func pay(g, w: Dictionary) -> bool:
	if int(g.stones) < int(w.price):
		return false
	g.stones -= int(w.price)
	g.bounty_paid += int(w.price)
	_clear(g, w)
	g.note("Paid %d spirit stones to the watch of %s, and saw the bill torn up" % [int(w.price), str(w.n)])
	return true

## Go with the watch (`hard`: taken, having drawn on them and lost: twice the days and half of what he
## carries).  The days pass in a circle drawn on the ground.  Returns the days.
static func serve(g, w: Dictionary, hard: bool = false) -> int:
	var days := days_for(g, int(w.price)) * (2 if hard else 1)
	days = mini(days, SERVE_MAX * 2)
	g.day += days
	# (an hour the story is holding is not moved: clock.gd)
	if Clock.frozen(g) == "":
		g.clock = 7.0 * 60.0
	g.served += days
	if hard:
		g.stones = int(g.stones) / 2
	g.heal_full()
	_clear(g, w)
	g.note("%d day%s in the circle at %s%s" % [days, "" if days == 1 else "s", str(w.n), ", taken sword in hand" if hard else ""])
	return days

## What is told of the days served.
static func serve_lines(g, w: Dictionary, days: int, hard: bool = false) -> Array:
	var out: Array = []
	if hard:
		out.append(["Narrator", "He wakes on swept earth with his head ringing and his purse half its weight. Somebody has drawn a circle round him with the butt of a spear."])
	out.append(["Narrator", "There is no cell in %s. There is a circle scratched on the ground by the gate, as there was in King Wen's time, and nobody set to guard it. Everybody who passes looks to see whether he is still inside. For %d day%s he is." % [str(w.n), days, "" if days == 1 else "s"]])
	out.append(["Captain of the Watch", "That is the last of it. I have rubbed the line out with my foot; you may step where you like. The bill is burned. What people remember is not mine to burn."])
	return out

## He runs: the watch does not catch him today, and the bill is the heavier for it.
static func flee(g, w: Dictionary) -> int:
	g.watch_day[str(w.tid)] = int(g.day)
	return record(g, "flight", str(w.tid), str(w.n))

## The watch he fights if he draws on them: three, about as strong as he is (a cultivator's bill is
## served by people who can serve it).
static func watch_group(g) -> Array:
	var lv := clampi(int(g.level) - 1, 1, Data.MAX_LEVEL)
	return [{"id": "watch_spear", "lv": lv}, {"id": "watch_captain", "lv": mini(Data.MAX_LEVEL, lv + 1)}, {"id": "watch_spear", "lv": lv}]

## He drew on the watch and won: three more dead in the street, seen by everybody, and no watch today.
static func resisted(g, w: Dictionary) -> int:
	g.watch_day[str(w.tid)] = int(g.day)
	g.watch_slain += 3
	Weal.act(g, str(w.tid), "slain", 3)
	return record(g, "watch", str(w.tid), str(w.n), 3.0)

# ---------------------------------------------------------------- the bounty-takers
## Whether bounty-takers are due to find him in region `area` now (once a day, in the wild, with a
## price heavy enough on his head or a forbidden art found out).
static func hunt_due(g, area: String) -> bool:
	if g.bounty.is_empty() and not Taboo.marked(g):
		return false
	if int(g.hunter_day) == int(g.day) or area == "sect":
		return false
	var tid := Weal.town_of(area)
	if tid != "" and str(Weal.TOWNS[tid].area) == area:
		return false
	return Taboo.marked(g) or heat(g) >= HUNT + HUNT_REALM * int(g.realm())

## Who comes: bounty-takers, one more for every time they have failed (four at most); or, for an art
## the precepts forbid, three enforcers of the Righteous League, who are stronger than he is.
static func hunters(g) -> Array:
	var out: Array = []
	if Taboo.marked(g):
		var lv := mini(Data.MAX_LEVEL, int(g.level) + 2)
		for i in 3:
			out.append({"id": "league_enforcer", "lv": lv, "atk": 1.15})
		return out
	var lv2 := mini(Data.MAX_LEVEL, int(g.level) + 1)
	for i in mini(4, 2 + int(g.hunted)):
		out.append({"id": "bounty_taker", "lv": lv2})
	return out

static func hunt_lines(g) -> Array:
	if Taboo.marked(g):
		return [["Narrator", "Three figures in the grey of the Righteous League are standing in the road ahead, a sword's length apart, and have been for some time. They do not carry a bill. For what he has done there is no price."],
			["Enforcer of the League", "Lin Feng of the Azure Cloud. You have sat to an art the precepts forbid, and it was seen. Kneel, and it is burned out of you here. Stand, and it is burned out of you all the same."]]
	return [["Narrator", "A man steps out of the reeds ahead with a folded bill in his belt, and another behind, and they have plainly done this before. Neither of them is angry. It is a trade."],
		["Bounty-Taker", "%d spirit stones, the gates say. A third of that is mine. Nothing in it for either of us if you make it difficult; but they always do." % heat(g)]]

## The bounty-takers found him today (whatever came of it).
static func hunted_today(g) -> void:
	g.hunter_day = int(g.day)

## He beat them: they will bring one more next time.
static func hunt_won(g) -> void:
	g.hunted += 1

## He lost to them: carried to the nearest gate where a bill hangs, and everything is served at once.
static func hunt_lost(g) -> Dictionary:
	var best := ""
	for t in g.bounty:
		if best == "" or int(g.bounty[t]) > int(g.bounty[best]):
			best = str(t)
	if best == "":
		best = "sect"
	return {"tid": best, "n": str(Weal.TOWNS[best].n).trim_prefix("the "), "price": maxi(1, heat(g))}

# ---------------------------------------------------------------- what is told
## What somebody in the street of a town says to a wanted man ("" with a clean name there).
const STREET := [
	["", ""],
	["I have seen your face today already, %s. On a board. Excuse me.", "The watch went by not an hour ago. I am only saying. I did not say anything to them."],
	["...", "We have nothing. We know nothing. Please. The children are indoors."],
]
static func line(g, town: String, seed_: int) -> String:
	if g.bounty.is_empty() and not Taboo.marked(g):
		return ""
	var st := standing(g, Weal.of_folk(town))
	return str(STREET[st][absi(seed_) % 2])

## "Wanted in Qingshi Village (2400), Cloudfoot (300)" or "a clean name".
static func text(g) -> String:
	if heat(g) == 0:
		# (found out at a forbidden art there is no price, and his name hangs at every gate: it read "a clean name")
		if Taboo.marked(g):
			return "outlaw: a walker of the forbidden, with no price to pay"
		return "a clean name" if g.slain.is_empty() and int(g.watch_slain) == 0 else "no bill at any gate"
	var parts: Array = []
	for tid in Weal.ORDER:
		if price(g, tid) > 0:
			parts.append("%s (%d)" % [str(Weal.TOWNS[tid].n).trim_prefix("the "), price(g, tid)])
	return ("outlaw: " if outlaw(g) else "wanted in ") + ", ".join(parts)

## What the end says of it (for the journey that has blood on it).
static func epilogue(g) -> Array:
	var out: Array = []
	if g.slain.is_empty() and int(g.watch_slain) == 0:
		return out
	var named: Array = []
	for id in g.slain:
		if not str(id).begins_with("folk:") and not g.slain[id].has("alias"):
			named.append(str(g.slain[id].n))
	if not named.is_empty():
		out.append("There is a mound where %s stood, and %s. Nobody tends them who does not know whose hand it was." % [str(named[0]), "no other" if named.size() == 1 else ("one other like it" if named.size() == 2 else "%d others like it" % (named.size() - 1))])
	if heat(g) > 0:
		out.append("His bill still hangs at the gates, a little more faded every spring. Nobody has taken it down, and nobody has collected.")
	elif int(g.served) > 0:
		out.append("He stood %d day%s in a circle scratched on the ground, and stepped out of it when he was told he might. People remember that he stayed in." % [int(g.served), "" if int(g.served) == 1 else "s"])
	return out

# ---------------------------------------------------------------- what stands where somebody stood
## A mound of earth and a name-tablet, built from code: drawn where somebody he struck down stood.
static func grave(seen: bool) -> Node3D:
	var n := Node3D.new()
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color("6a5038")
	earth.roughness = 1.0
	var mound := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.62
	sm.height = 0.7
	sm.radial_segments = 12
	sm.rings = 6
	mound.mesh = sm
	mound.scale = Vector3(1.0, 0.7, 1.45)
	mound.position = Vector3(0, 0.05, 0.15)
	mound.material_override = earth
	n.add_child(mound)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("8a8880") if seen else Color("7a766c")
	stone.roughness = 0.95
	var slab := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.78, 0.09)
	slab.mesh = bm
	slab.position = Vector3(0, 0.39, -0.62)
	slab.rotation = Vector3(deg_to_rad(-4.0), 0, deg_to_rad(1.5))
	slab.material_override = stone
	n.add_child(slab)
	var cap := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.44, 0.07, 0.14)
	cap.mesh = cm
	cap.position = Vector3(0, 0.8, -0.62)
	cap.material_override = stone
	n.add_child(cap)
	if seen:
		# what somebody cut under the name, in red
		var red := StandardMaterial3D.new()
		red.albedo_color = Color("a8281e")
		var cut := MeshInstance3D.new()
		var qm := BoxMesh.new()
		qm.size = Vector3(0.2, 0.05, 0.02)
		cut.mesh = qm
		cut.position = Vector3(0, 0.22, -0.57)
		cut.material_override = red
		n.add_child(cut)
	# three sticks of incense somebody else left, burned down
	var ash := StandardMaterial3D.new()
	ash.albedo_color = Color("3a342e")
	for i in 3:
		var st := MeshInstance3D.new()
		var cy := CylinderMesh.new()
		cy.top_radius = 0.008
		cy.bottom_radius = 0.008
		cy.height = 0.16
		cy.radial_segments = 4
		st.mesh = cy
		st.position = Vector3(-0.07 + 0.07 * float(i), 0.1, -0.44)
		st.material_override = ash
		n.add_child(st)
	return n
