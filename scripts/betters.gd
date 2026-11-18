class_name Betters
extends RefCounted
## Those above him (the Higher Sky release): foes several realms over his head, and what losing to one costs.
##
## For thirty-seven chapters whoever stood in the road was about as strong as Lin Feng was, and a battle
## had three ends: the foe fell; he woke in the infirmary and tried again; or (dooms.gd) it was a thing
## nobody beats and nothing was taken for it.  A **better** is a fourth thing: *somebody*, a cultivator
## `over` whole realms above whatever he is on the day they meet (`"better": true` in Data.ENEMIES).
## They can be beaten.  They mostly are not.  And losing is **not** the infirmary and not the end:
##
##   * the battle is fought in earnest; when the party is down, or he gives way (the fifth line of the
##     battle menu), its outcome is `"bested"`, he is not carried home and no death is counted;
##   * **something is taken** (`COST`): a share of his spirit stones, days of his life (the land does not
##     wait: days lived, so packs grow and stipends fall due), the town that hears of that country thinks
##     the less of its peace (`Weal.ACTS.bested`), and a **wound** that weighs on a number (`mod`) until
##     it is mended;
##   * and **the story goes another way**: a step with `"if": [better, "up" | "down"]` is only walked by
##     the journey on that branch (`on_branch`, `skip`: Game.advance steps over the others).  "down" is
##     having lost (or given way); "up" is having won, or, for a better who is `bow`ed to, having given
##     way: there is one in the story it is right not to fight.  The other two take a lowered sword for
##     what Goujian's and Sun Bin's was taken for: he is a groom, or lamed, all the same, only standing.
##
## **He can be watched first** (`watch`: Enter in front of him, "Walk on" the first answer; four hours,
## once a day, three times at most): every watch closes one realm of the gap, for knowing where a man's
## guard opens is worth a realm.  The bot watches nobody, and loses.
##
## **And met again** (`again`): a better who was lost to stands where he stood, and may be asked for
## another bout whenever he is found.  Winning then gives back what can be given back (the stones, the
## wound) but not the branch: what was done after losing was done.
##
## A better of the story is a step of kind `"dare"` (`boss`), done whichever way the bout goes.  Nothing
## here is random, and nothing a wound weighs on may be something a step needs.

## The betters: realms above him on the day they meet, how hard a lord of that level they are
## (`mult` health, `atk`: what a trial gives its lord, trials.gd `might`, and nobody here has a boon), whether giving way is the right answer (`bow`), and the words of the watch.
const BETTERS := {
	"fuchai": {"over": 4, "mult": 4.0, "atk": 1.3, "bow": false,
		"watch": ["He drills three hundred men from the saddle and corrects one of them. It is the right one.",
			"He eats standing. He does not once look at the door, and everybody who comes through it he has already seen.",
			"When he strikes he has decided an hour ago. Whatever is done in front of him, he is answering something earlier."]},
	"pang_juan": {"over": 5, "mult": 4.0, "atk": 1.35, "bow": false,
		"watch": ["He counts. Tents, fires, hoofprints. He has a number for the camp before he has seen a single man in it.",
			"He is quickest when he thinks he is winning. He leaves his baggage behind to be quicker still.",
			"He reads what is written for him to read, by whatever light there is. He cannot leave a thing unread."]},
	"lian_po": {"over": 4, "mult": 4.5, "atk": 1.3, "bow": true,
		"watch": ["He stands in the middle of the lane with his thumbs in his belt. People go round by the ditch.",
			"He has forty wounds, all in front. He will tell anybody the day and the field of each.",
			"He says the same sentence to every carter: what has a tongue ever taken that a spear did not take first?"]},
}
const ORDER := ["fuchai", "pang_juan", "lian_po"]

## how many times one of them can be watched, the hours a watch takes, and the realms each closes
const WATCH_MAX := 3
const WATCH_HOURS := 4.0
## the health the party is left with after losing (a share of each one's own)
const LEFT := 0.25

## What losing to each costs: `stones` (the share of what he has on him), `days` (of his life, at
## once), `wound` (its name) and what the wound weighs on (`mods`: a number -> a multiplier, asked
## through `mod`), the step that mends it (`mend`: done on the "down" branch), and what is said of it
## on the Load page and under his name.  Giving way to somebody who is `bow`ed to costs half the stones
## and nothing else; giving way to the others costs what losing costs.
const COST := {
	"fuchai": {"stones": 0.5, "days": 3, "wound": "A groom of Wu", "mods": {"wage": 0.75}, "mend": "s_p38_gall",
		"tag": "three days in the stables of Wu, and half of what he carried"},
	"pang_juan": {"stones": 0.2, "days": 1, "wound": "The knee", "mods": {"atk": 0.92, "spd": 0.85}, "mend": "s_p38_maling",
		"tag": "a knee that will tell him the weather for the rest of his life"},
	"lian_po": {"stones": 0.25, "days": 0, "wound": "Put down in the lane", "mods": {"price": 1.15}, "mend": "s_p38_thorns",
		"tag": "put on his back in a lane with a town looking on"},
}

const HOW := {"won": "won", "lost": "fought to the end and lost", "gave": "gave way"}

static func is_better(id: String) -> bool:
	return bool(Data.ENEMIES.get(id, {}).get("better", false))

## How many realms above him `id` stands today: `over`, less one for every time he has been watched.
static func gap(g, id: String) -> int:
	return maxi(1, int(BETTERS[id].over) - int(g.watched.get(id, 0)))

## The level `id` is met at: his own level on the day they first come to blows and `over` realms (kept,
## so somebody who goes away and grows can come back), less a realm for every watch.
static func level(g, id: String) -> int:
	var base := int(g.bested[id].base) if g.bested.has(id) else int(g.level) + 3 * int(BETTERS[id].over)
	return base - 3 * mini(int(g.watched.get(id, 0)), int(BETTERS[id].over) - 1)

## What every realm of the gap past the first makes of a better's health and of his blow.  A level is a
## small thing in this land (a few parts in a hundred) and the weight of a realm stops at three
## (Data.SUPPRESS_CAP); somebody four realms up would otherwise be a lord like any other.
const HP_REALM := 1.5
const ATK_REALM := 1.3

## How hard `id` is today: [health, blow], as multiples of a lord of his level.
static func might(g, id: String) -> Array:
	var k := float(maxi(0, (level(g, id) - int(g.level)) / 3 - 1))
	return [float(BETTERS[id].mult) * pow(HP_REALM, k), float(BETTERS[id].atk) * pow(ATK_REALM, k)]

## The foe handed to the battle.
static func foe(g, id: String) -> Dictionary:
	var m := might(g, id)
	return {"id": id, "lv": level(g, id), "mult": float(m[0]), "atk": float(m[1])}

# ---------------------------------------------------------------- watching
## Why he cannot be watched now ("" if he can): only so many times, and once a day.
static func watch_blocked(g, id: String) -> String:
	if int(g.watched.get(id, 0)) >= WATCH_MAX:
		return "There is nothing more to be learned of him by looking."
	if int(g.watch_on.get(id, -1)) == int(g.day):
		return "He has been watched today. A man is not the same thing twice in one day; come back tomorrow."
	return ""

## He is watched: four hours go by, and one realm of the gap is closed.  Returns what was seen.
static func watch(g, id: String) -> String:
	if watch_blocked(g, id) != "":
		return ""
	var k := int(g.watched.get(id, 0))
	g.watched[id] = k + 1
	var m := float(g.clock) + WATCH_HOURS * 60.0
	while m >= Clock.DAY:
		m -= Clock.DAY
		g.day += 1
	g.clock = m
	# (the Red Seal release: "once a day" is the day the watch ends on: written before the hours were added, a
	# watch begun in the evening ended tomorrow, and all three fitted into one night)
	g.watch_on[id] = int(g.day)
	g.note("Watched %s (%d of %d)" % [str(Data.ENEMIES[id].n), k + 1, WATCH_MAX])
	return str(BETTERS[id].watch[k])

# ---------------------------------------------------------------- the bout
## Which way the story went at `id`: "" (not met), "up" or "down".
static func branch(g, id: String) -> String:
	if not g.bested.has(id):
		return ""
	var how := str(g.bested[id].first)
	if how == "won" or (how == "gave" and bool(BETTERS[id].bow)):
		return "up"
	return "down"

## Whether the journey walks step `s`: a step with no `if` is everybody's.
static func on_branch(g, s: Dictionary) -> bool:
	if not s.has("if"):
		return true
	return branch(g, str(s["if"][0])) == str(s["if"][1])

## The first step at or after `i` that this journey walks.
static func skip(g, i: int) -> int:
	while i < Data.STEPS.size() and not on_branch(g, Data.STEPS[i]):
		i += 1
	return i

## What losing takes of `stones` spirit stones.
static func taken(id: String, how: String, stones: int) -> int:
	var share := float(COST[id].stones) * (0.5 if how == "gave" and bool(BETTERS[id].bow) else 1.0)
	return int(floor(float(stones) * share))

## The bout with `id` is over: `how` is "won", "lost" or "gave".  The first bout decides the branch;
## a later one can only give back.  Returns what is told of it (one line, "" if nothing changed).
static func over(g, id: String, how: String, area: String = "") -> String:
	var first: bool = not g.bested.has(id)
	if first:
		g.bested[id] = {"first": how, "base": int(g.level) + 3 * int(BETTERS[id].over), "day": int(g.day), "took": 0, "wound": false, "bouts": 0}
	var b: Dictionary = g.bested[id]
	b.bouts = int(b.bouts) + 1
	b["last"] = how
	if how == "won":
		var back := int(b.took)
		g.stones += back
		b.took = 0
		b.wound = false
		g.bettered += 1
		var up_by := maxi(1, (level(g, id) - int(g.level)) / 3)
		g.note("Beat %s, who was %d realm%s above" % [str(Data.ENEMIES[id].n), up_by, "" if up_by == 1 else "s"])
		g.weal_n += 1
		return "" if back == 0 else "What was taken is counted back into his hands: %d spirit stones." % back
	# lost, or gave way: something is taken, and it is not the infirmary
	var c: Dictionary = COST[id]
	var took := taken(id, how, int(g.stones))
	g.stones -= took
	b.took = int(b.took) + took
	g.overmatched += 1
	if how == "gave":
		g.bowed += 1
	var up: bool = first and how == "gave" and bool(BETTERS[id].bow)
	if not up:
		b.wound = true
		g.day += int(c.days)
		var town := Weal.town_of(area) if area != "" else ""
		if town != "":
			Weal.act(g, town, "bested")
	for i in g.party_size():
		g.hp[i] = maxf(g.hp[i], float(g.max_hp(i)) * LEFT)
	g.weal_n += 1
	g.note("Lost to %s (%s): %s" % [str(Data.ENEMIES[id].n), str(HOW[how]), "nothing was held against it" if up else str(c.tag)])
	return "%d spirit stones are taken." % took if took > 0 else ""

# ---------------------------------------------------------------- what is carried afterwards
## Whether the wound `id` left is still on him: until the step that mends it is done, or he wins.
static func wounded(g, id: String) -> bool:
	if not g.bested.has(id) or not bool(g.bested[id].wound):
		return false
	return not g.done(str(COST[id].mend))

## The wounds on him now (ids of betters).
static func wounds(g) -> Array:
	var out: Array = []
	for id in ORDER:
		if wounded(g, id):
			out.append(id)
	return out

## What his wounds make of the number `key` (1 with none): "atk", "spd", "wage", "price".
static func mod(g, key: String) -> float:
	if g.bested.is_empty():
		return 1.0
	var m := 1.0
	for id in ORDER:
		if wounded(g, id):
			m *= float(COST[id].mods.get(key, 1.0))
	return m

## Whether he may ask `id` for another bout: lost to, and still standing.  Somebody the story itself brings
## him back to (Pang Juan, under the tree: the step that mends the wound is a "kill") is met again there and
## nowhere else: beaten early, he would be gone from the land with the step that needs him still to do.
static func again(g, id: String) -> bool:
	if not g.bested.has(id) or str(g.bested[id].get("last", "")) == "won" or g.boss_done.has(id):
		return false
	# (the Red Seal release: somebody rightly given way to is not "met again": a second bow used to wound him
	# and shame the town for the right answer; and nobody is asked again before the story has been back to
	# whoever sent him, or it is told of stones that are already home)
	if branch(g, id) == "up" or not g.done(str(COST[id].mend)):
		return false
	var ms: Dictionary = Data.STEPS[Data.step_index(str(COST[id].mend))]
	return not (str(ms.kind) == "kill" and str(ms.get("boss", "")) == id)

## How many betters of the story he has stood in front of, and how many he has beaten.
static func met(g) -> int:
	return g.bested.size()

static func beaten(g) -> int:
	var n := 0
	for id in g.bested:
		if str(g.bested[id].get("last", "")) == "won":
			n += 1
	return n

## What is shown under his name while a wound is on him.
static func tags(g) -> Array:
	var out: Array = []
	for id in wounds(g):
		out.append(str(COST[id].wound))
	return out

## What the ending tells of it: one sentence.
static func epilogue(g) -> String:
	if g.bested.is_empty():
		return ""
	var up := 0
	var down := 0
	for id in ORDER:
		match branch(g, id):
			"up":
				up += 1
			"down":
				down += 1
	if down == 0:
		return "Of the three who stood above him, it is told that Lin Feng was beaten by none, and that he said afterwards it had taught him less than losing would have."
	if up == 0:
		return "Of the three who stood above him, it is told that Lin Feng lost to every one, paid what each took, and was seen the next morning on the same road."
	return "Of the three who stood above him, it is told that Lin Feng lost to %s and not to %s, and could say which had been the better day." % ["one" if down == 1 else "two", "one" if up == 1 else "two"]
