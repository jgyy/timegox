class_name Pets
extends RefCounted
## Beasts kept (the Unblunted Knife release).  "Ji Xingzi was training a fighting cock for the king.  After
## forty days: other cocks crow, and it does not change.  Seen from afar it is like a cock of wood."
##
## **A beast of the land can be asked to stay.**  When one of the land's own packs (`Wilds.native`: not a
## war-band, not raiders, never a lord) is beaten or runs from his realm, and one of it is of a kind that can
## be kept (`SHAPES`, by the shape it is drawn in) and he has what that kind eats on him (`diet`: a good of
## load.gd) and room (`room`), it is asked (`Main.offer_tame`: "Let it go" first).  The food is given, and the
## beast is his: it has a name, the body and colours of what it was (`Models.monster`, drawn smaller, at his
## heel: `World._pet_tick`, drawn only), and **trust** (`bond`, five steps: `TIERS`) that grows by being fed
## (once a day), by battles won beside him and by sitting with him in a place of peace.
##
## What a beast is for (`L`, or Esc > Hands & Beasts; "Leave them be" first):
##   **battle**: the one at his heel strikes one foe at the start of every round (`blow`: a share of his own
##     attack by its kind and its trust; `Battle._pet_strike`), in every battle that is not fought alone;
##   **gathering**: it is sent out (`send`), is gone four hours of the clock, and comes back with what its
##     kind has a nose for (`collect`: a good of the land, more of it the more it trusts him; counted, never
##     thrown for); while it is out it is not at his heel;
##   **carrying**: what its back takes is added to his own (`carry`, asked by `Load.cap`);
##   **watching**: some kinds make a place of peace one step more peaceful (`watch`, asked by retreats.gd).
##
## **Everything is 0 or 1 with no beast kept**, the bot keeps one only inside a step of kind "tame" and sends
## it only inside a step of kind "fetch", and nothing here is random.  A beast is never taken in a town's
## streets, never from a cave, and nobody's beast dies: one that is let go walks back into its own country.
## New step kinds "tame" (`n` beasts asked to stay since the step began; `area`, `of` as a hunt has them)
## and "fetch" (`n` times a beast has come back with something since it began).
## **A new shape that can be kept** needs a line in `SHAPES` (a diet and a nose that are goods of
## `Load.GOODS`).

const SHAPES := {
	"beast": {"kind": "a hound of the hills", "diet": "carp", "fang": 1.0, "nose": "wild_yam", "back": 6.0, "watch": true, "word": "It sleeps with one ear up."},
	"tiger": {"kind": "a great cat", "diet": "carp", "fang": 1.4, "nose": "carp", "back": 10.0, "watch": false, "word": "It is not tame. It has decided."},
	"fox": {"kind": "a fox", "diet": "carp", "fang": 0.8, "nose": "mushrooms", "back": 0.0, "watch": true, "word": "It knows where everything is, and tells him some of it."},
	"ape": {"kind": "an ape", "diet": "mushrooms", "fang": 0.9, "nose": "herb_bundle", "back": 12.0, "watch": false, "word": "It carries things, and has opinions about how they are packed."},
	"bird": {"kind": "a bird of the heights", "diet": "carp", "fang": 0.7, "nose": "herb_bundle", "back": 0.0, "watch": true, "word": "It sees him before he sees it. It sees everything before he does."},
	"magpie": {"kind": "a magpie", "diet": "herb_bundle", "fang": 0.5, "nose": "jade_rough", "back": 0.0, "watch": true, "word": "It brings back whatever shines. Now and then the thing is worth something."},
	"serpent": {"kind": "a serpent", "diet": "carp", "fang": 1.1, "nose": "mushrooms", "back": 0.0, "watch": false, "word": "It lies in the sun on whatever he has just put down."},
	"ox": {"kind": "an ox", "diet": "herb_bundle", "fang": 0.8, "nose": "wild_yam", "back": 30.0, "watch": false, "word": "It walks at the pace it walks at. So, shortly, does he."},
	"tortoise": {"kind": "a tortoise", "diet": "herb_bundle", "fang": 0.5, "nose": "ore_lump", "back": 16.0, "watch": false, "word": "It has not hurried in two hundred years and sees no reason to begin."},
	"jade_rabbit": {"kind": "a rabbit", "diet": "herb_bundle", "fang": 0.4, "nose": "herb_bundle", "back": 0.0, "watch": true, "word": "It is afraid of everything, and is therefore never surprised."},
	"crab": {"kind": "a crab", "diet": "carp", "fang": 0.9, "nose": "carp", "back": 4.0, "watch": false, "word": "It goes where he goes, by a different route."},
}
const NAMES := ["Mote", "Burr", "Ash", "Pebble", "Reed", "Soot", "Dew", "Thistle", "Ember", "Moss", "Flint", "Plum"]
## trust: where each step begins, and what it is called
const TIER_AT := [0.0, 20.0, 45.0, 75.0, 100.0]
const TIERS := ["Wary", "Fed", "Follows", "Devoted", "Of One Heart"]
const BOND_MAX := 100.0
const BOND_FED := 8.0
const BOND_WON := 1.0
const BOND_SAT := 5.0
const BOND_BACK := 3.0
## how many he may keep before the chart gives more (channels.gd)
const ROOM := 2
const ROOM_MAX := 4
## hours of the clock a beast sent to gather is gone
const GATHER_HOURS := 4.0
## what the beast at his heel strikes with: a share of his own attack (`fang` times this, by trust)
const BLOW := [0.3, 0.4, 0.5, 0.6, 0.7]
## how big a beast is drawn at his heel (of the size its kind is drawn in the land: something over half)
const SCALE := 0.62
const ASK := "The beasts he keeps"

static func room(g) -> int:
	return mini(ROOM_MAX, ROOM + int(Channels.add(g, "pet_room")))

## The shape entry of foe `foe_id` if it is of a kind that can be kept ({} if not).
static func kind_of(foe_id: String) -> Dictionary:
	if not Data.ENEMIES.has(foe_id):
		return {}
	var d: Dictionary = Data.ENEMIES[foe_id]
	if bool(d.get("boss", false)) or bool(d.get("doom", false)) or bool(d.get("better", false)):
		return {}
	return SHAPES.get(str(d.shape), {})

static func tier_of(bond: float) -> int:
	var t := 0
	for k in TIER_AT.size():
		if bond >= float(TIER_AT[k]):
			t = k
	return t

static func tier(pet: Dictionary) -> int:
	return tier_of(float(pet.get("bond", 0.0)))

static func traits(pet: Dictionary) -> Dictionary:
	return SHAPES[str(pet.shape)]

## Whether beast `pet` is out gathering now.
static func away(g, pet: Dictionary) -> bool:
	return not (pet.get("out", {}) as Dictionary).is_empty()

## The beast at his heel ({} if he keeps none, or it is out).
static func heel(g) -> Dictionary:
	var i := int(g.pet)
	if i < 0 or i >= g.pets.size():
		return {}
	var p: Dictionary = g.pets[i]
	return {} if away(g, p) else p

## Which of a beaten pack would stay, if any: {"foe", "food"} or {}.  Pure: the pack (`e`: the entity,
## `group`: who was in it), what he has on him, and how many he keeps.
static func offer(g, e: Dictionary, group: Array) -> Dictionary:
	if str(g.prologue) != "" or not Wilds.native(e) or g.pets.size() >= room(g):
		return {}
	for m in group:
		var k := kind_of(str(m.id))
		if k.is_empty() or int(g.inv.get(str(k.diet), 0)) <= 0:
			continue
		if g.pets.any(func(p): return str(p.foe) == str(m.id)):
			continue
		return {"foe": str(m.id), "food": str(k.diet)}
	return {}

## What is said as one of them does not run.
static func seen_line(foe_id: String) -> String:
	var k := kind_of(foe_id)
	return "The rest are gone. One %s has not run. It is standing at the edge of what was the fight, looking at the %s in his pack." % [
		str(Data.ENEMIES[foe_id].n).to_lower(), str(Data.ITEMS[str(k.diet)].n).to_lower()]

## The beast is asked to stay: its food is given, and it is his.  Returns the beast ({} if it cannot be).
static func tame(g, foe_id: String) -> Dictionary:
	var k := kind_of(foe_id)
	if k.is_empty() or g.pets.size() >= room(g) or int(g.inv.get(str(k.diet), 0)) <= 0:
		return {}
	g.inv[str(k.diet)] = int(g.inv[str(k.diet)]) - 1
	if int(g.inv[str(k.diet)]) <= 0:
		g.inv.erase(str(k.diet))
	var seq := int(g.pets_n)
	g.pets_n = seq + 1
	var pet := {"k": seq, "foe": foe_id, "shape": str(Data.ENEMIES[foe_id].shape), "n": str(NAMES[seq % NAMES.size()]), "bond": BOND_FED, "day": int(g.day), "fed": int(g.day), "wins": 0, "loads": 0, "out": {}}
	g.pets.append(pet)
	if heel(g).is_empty():
		g.pet = g.pets.size() - 1
	g.note("%s, %s, stays" % [str(pet.n), str(k.kind)])
	var s: Dictionary = g.cur_step()
	if not s.is_empty() and str(s.kind) == "tame":
		g.step_did["tame"] = int(g.step_did.get("tame", 0)) + 1
		g.poll_steps()
	return pet

static func _trust(g, pet: Dictionary, n: float) -> void:
	pet["bond"] = minf(BOND_MAX, float(pet.bond) + n * Channels.mod(g, "pet_bond"))

## Why beast `i` cannot be fed now ("" if it can).
static func feed_why(g, i: int) -> String:
	if i < 0 or i >= g.pets.size():
		return "There is no such beast."
	var p: Dictionary = g.pets[i]
	if away(g, p):
		return "%s is out gathering." % str(p.n)
	if int(p.fed) == int(g.day):
		return "%s has eaten today." % str(p.n)
	if int(g.inv.get(str(traits(p).diet), 0)) <= 0:
		return "He has no %s, and it eats nothing else from a hand." % str(Data.ITEMS[str(traits(p).diet)].n).to_lower()
	return ""

static func feed(g, i: int) -> bool:
	if feed_why(g, i) != "":
		return false
	var p: Dictionary = g.pets[i]
	var food := str(traits(p).diet)
	g.inv[food] = int(g.inv[food]) - 1
	if int(g.inv[food]) <= 0:
		g.inv.erase(food)
	p["fed"] = int(g.day)
	var before := tier(p)
	_trust(g, p, BOND_FED)
	if tier(p) > before:
		g.toast("%s: %s" % [str(p.n), str(TIERS[tier(p)])])
	return true

## Beast `i` is called to his heel (or sent from it: i < 0).
static func bring(g, i: int) -> bool:
	if i >= g.pets.size() or (i >= 0 and away(g, g.pets[i])):
		return false
	g.pet = i
	return true

## Beast `i` is let go: it walks back into its own country.
static func let_go(g, i: int) -> bool:
	if i < 0 or i >= g.pets.size():
		return false
	g.note("%s was let go" % str(g.pets[i].n))
	g.pets.remove_at(i)
	if int(g.pet) == i:
		g.pet = -1
	elif int(g.pet) > i:
		g.pet = int(g.pet) - 1
	return true

## What the beast at his heel strikes for before the foe's guard is taken off (0 with none).
static func blow(g) -> float:
	var p := heel(g)
	if p.is_empty():
		return 0.0
	return float(Data.atk(int(g.level))) * float(traits(p).fang) * float(BLOW[tier(p)]) * Channels.mod(g, "pet_atk")

## A battle was won with a beast at his heel: it trusts him a little more.
static func won(g) -> void:
	var p := heel(g)
	if p.is_empty():
		return
	p["wins"] = int(p.wins) + 1
	_trust(g, p, BOND_WON)

## He sat in a place of peace with a beast at his heel.
static func sat(g) -> void:
	var p := heel(g)
	if not p.is_empty():
		_trust(g, p, BOND_SAT)

## What the beast at his heel adds to what his own back takes, in jin (0 with none).
static func carry(g) -> float:
	var p := heel(g)
	return 0.0 if p.is_empty() else float(traits(p).back) * (0.5 + 0.125 * float(tier(p)))

## Whether the beast at his heel keeps watch (a place of peace is one step quieter for it).
static func watch(g) -> bool:
	var p := heel(g)
	return not p.is_empty() and bool(traits(p).watch)

# ---------------------------------------------------------------- gathering
## Why beast `i` cannot be sent to gather now ("" if it can).
static func send_why(g, i: int) -> String:
	if i < 0 or i >= g.pets.size():
		return "There is no such beast."
	var p: Dictionary = g.pets[i]
	if away(g, p):
		return "%s is out already." % str(p.n)
	if Clock.frozen(g) != "":
		return "It will not leave his heel while the sky stands still."
	return ""

## Beast `i` is sent out to gather: gone GATHER_HOURS of the clock.
static func send(g, i: int, area: String) -> bool:
	if send_why(g, i) != "":
		return false
	var p: Dictionary = g.pets[i]
	p["out"] = {"until": Almanac.now(g) + GATHER_HOURS / 24.0, "area": area}
	g.note("%s was sent out to gather" % str(p.n))
	return true

## How many pieces beast `pet` brings back.
static func haul(g, pet: Dictionary) -> int:
	return 1 + tier(pet) / 2 + int(Channels.add(g, "pet_nose"))

## The beasts that are back: what each brought is put on his back, and said.  Returns the lines.
static func collect(g) -> Array:
	var lines: Array = []
	for p in g.pets:
		var o: Dictionary = p.get("out", {})
		if o.is_empty() or (Almanac.now(g) < float(o.until) and Clock.frozen(g) == ""):
			continue
		p["out"] = {}
		var good := str(traits(p).nose)
		var n := haul(g, p)
		g.add_item(good, n)
		p["loads"] = int(p.get("loads", 0)) + 1
		g.fetched = int(g.fetched) + n
		_trust(g, p, BOND_BACK)
		lines.append("%s is back, with %d %s." % [str(p.n), n, str(Data.ITEMS[good].n).to_lower()])
		var s: Dictionary = g.cur_step()
		if not s.is_empty() and str(s.kind) == "fetch":
			g.step_did["fetch"] = int(g.step_did.get("fetch", 0)) + 1
	if not lines.is_empty():
		g.poll_steps()
	return lines

## Hours until beast `pet` is back (0 if it is not out).
static func back_in(g, pet: Dictionary) -> float:
	var o: Dictionary = pet.get("out", {})
	return 0.0 if o.is_empty() else maxf(0.0, (float(o.until) - Almanac.now(g)) * 24.0)

## The first beast that could be sent now (-1 if none).
static func sendable(g) -> int:
	for i in g.pets.size():
		if send_why(g, i) == "":
			return i
	return -1

static func title(pet: Dictionary) -> String:
	return "%s, %s" % [str(pet.n), str(traits(pet).kind)]

## What is said of beast `pet`, for the choice and the page.
static func text(g, pet: Dictionary) -> String:
	var k := traits(pet)
	var parts: Array = ["%s (was %s). %s: trust %d of %d." % [str(k.kind).substr(0, 1).to_upper() + str(k.kind).substr(1), str(Data.ENEMIES[str(pet.foe)].n).to_lower(), str(TIERS[tier(pet)]), int(pet.bond), int(BOND_MAX)]]
	parts.append("Eats %s. Strikes for %d%% of his blow; has a nose for %s (%d a time)%s%s." % [str(Data.ITEMS[str(k.diet)].n).to_lower(), int(round(float(k.fang) * float(BLOW[tier(pet)]) * 100.0)),
		str(Data.ITEMS[str(k.nose)].n).to_lower(), haul(g, pet), "; carries %d jin" % int(float(k.back) * (0.5 + 0.125 * float(tier(pet)))) if float(k.back) > 0.0 else "", "; keeps watch" if bool(k.watch) else ""])
	if away(g, pet):
		parts.append("Out gathering: back in about %.1f hours." % back_in(g, pet))
	parts.append(str(k.word))
	return " ".join(parts)

## The beast as it is drawn at his heel: the body and colours of what it was, smaller.
static func model(pet: Dictionary) -> Node3D:
	var d: Dictionary = Data.ENEMIES[str(pet.foe)]
	var m := Models.monster(str(d.shape), d.col, false, str(pet.foe))
	m.scale = Vector3.ONE * SCALE
	var root := Node3D.new()
	root.add_child(m)
	root.set_meta("m", m)
	return root
