class_name Needs
extends RefCounted
## Survival (the Thundering Pots release): the body the Dao is cultivated in.  **Off unless it is turned
## on** (Esc > The Body, or `--survival`): the story as it was first told asks nothing of the stomach.
## Turned on, Lin Feng and Yue Ling have seven needs, each from 0 (desperate) to 100 (content), that run
## down by the clock of the land (clock.gd) and are answered out in the world:
##
##   rest        a bed (an inn, a house, a cellar cot) fills it; a bench, a fire and meditation help;
##               sleeping rough under the sky fills most of it and costs comfort
##   hunger      eat: food bought of the cooks and innkeepers of the land, fish caught, herbs gathered,
##               something cooked at a stove; or forage, in the wild, slowly
##   thirst      a well, a tea table, a spring; the water gourd between them (refilled wherever one drinks)
##   bladder     \  outdoors, away from the towns, a step off the road; in a town, only where there is a
##   bowels      /  privy out the back (an inn, a house, a barracks)
##   comfort     sitting down, a fire, hot tea, a bed, a bath; the road wears it away, and the cold and
##               the night faster
##   cleanliness a hot spring, a cedar bath, a washstand, a drip pool, or any water one stands beside
##
## A need that is low costs something in battle (`mod`); one that reaches nothing takes matters into
## its own hands (`tick`): he sleeps where he stands, or does not get behind the tree in time.  Nobody
## dies of it.  And a cultivator needs less: every great realm slows them all, down to two fifths
## (the old books call it bigu, leaving off grain).  Kept well, all seven, there is a small reward.
##
## Nothing here is random, and nothing but `Game.needs`, `Game.survival` and the gourd keeps state.

const ORDER := ["rest", "hunger", "thirst", "bladder", "bowels", "comfort", "clean"]
## `rate`: how much runs down in an hour of the land's clock; `low` what it is called when it is low
const NEEDS := {
	"rest": {"n": "Rest", "rate": 4.6, "col": Color("8a9ad8"), "low": "worn out", "ok": "rested"},
	"hunger": {"n": "Hunger", "rate": 5.2, "col": Color("e0a050"), "low": "famished", "ok": "fed"},
	"thirst": {"n": "Thirst", "rate": 7.0, "col": Color("5ab0e8"), "low": "parched", "ok": "watered"},
	"bladder": {"n": "Bladder", "rate": 9.0, "col": Color("e8d860"), "low": "bursting", "ok": "easy"},
	"bowels": {"n": "Bowels", "rate": 4.4, "col": Color("a8784a"), "low": "griping", "ok": "easy"},
	"comfort": {"n": "Comfort", "rate": 3.0, "col": Color("e88aa8"), "low": "sore and chilled", "ok": "at ease"},
	"clean": {"n": "Cleanliness", "rate": 2.4, "col": Color("8ad8c0"), "low": "filthy", "ok": "clean"},
}
const LOW := 25.0
const WELL := 60.0
## a great realm slows every need by this much, down to FLOOR of the rate
const BIGU := 0.022
const FLOOR := 0.4
const GOURD := 5

## what can be eaten: how much each answers, and what it costs of a cook
const FOOD := {
	"steamed_bun": {"hunger": 30.0, "price": 12},
	"dried_meat": {"hunger": 45.0, "thirst": -8.0, "price": 30},
	"noodle_bowl": {"hunger": 65.0, "thirst": 10.0, "comfort": 12.0, "price": 45},
	"tea_egg": {"hunger": 18.0, "comfort": 4.0, "price": 8},
}
const FOOD_ORDER := ["steamed_bun", "tea_egg", "dried_meat", "noodle_bowl"]
## who sells it (the cooks, innkeepers and stall-keepers of the land)
const COOKS := ["cook_zhou", "noodle_he", "innkeeper", "tofu_sun", "cook_aysha", "tea_seller_pan", "fishwife_lu", "innkeeper_bao"]
const FOOD_ASK := "Something to eat for the road?"

## what a thing of the land (props.gd: its kind, else its effect) does for the body
const BY_KIND := {
	"hot_spring": {"clean": 100.0, "comfort": 40.0, "rest": 10.0}, "tub": {"clean": 100.0, "comfort": 35.0}, "washstand": {"clean": 45.0}, "drip_pool": {"clean": 60.0},
	"mirror": {"clean": 6.0}, "stove": {"hunger": 55.0, "comfort": 10.0}, "barrel": {"hunger": 12.0}, "wine_jar": {"thirst": 15.0, "comfort": 12.0, "bladder": -10.0},
	"tea": {"thirst": 40.0, "comfort": 15.0, "bladder": -8.0}, "table": {"thirst": 35.0, "comfort": 10.0, "bladder": -8.0}, "well": {"thirst": 100.0, "bladder": -10.0},
	"campfire": {"comfort": 30.0, "rest": 8.0}, "hearth": {"comfort": 30.0, "rest": 8.0}, "koi": {"comfort": 6.0}, "clothes_stand": {"comfort": 8.0},
}
const BY_EFFECT := {
	"sleep": {"rest": 100.0, "comfort": 45.0}, "rest": {"rest": 14.0, "comfort": 16.0}, "drink": {"thirst": 100.0, "bladder": -10.0},
	"fish": {"hunger": 40.0}, "herb": {"hunger": 14.0}, "qi": {"comfort": 6.0},
}

## what is said when a need gets the better of him (Yue Ling's line is said only if she is there)
const COLLAPSE := {
	"rest": [["Narrator", "Lin Feng's knees decide the matter. He sits down where he is, and is asleep before he has finished sitting. When he wakes, the light has moved a long way and there is a cloak over him that is not his."],
		["Yue Ling", "Six hours. I kept the flies off. A sovereign of however many realms it is, snoring in a ditch. I have told nobody. Yet.", "laugh"]],
	"hunger": [["Narrator", "The road tilts. Lin Feng has not eaten since he cannot remember when, and the body, which was never consulted about the Dao, has sent in its account."],
		["Yue Ling", "Sit. Eat this. It is the last of mine and I do not want to hear about it. You held up the sky, and you cannot remember supper.", "refuse"]],
	"thirst": [["Narrator", "His tongue has gone to leather and there is a ringing in his ears that is not a bell. Yue Ling has the stopper out of her own gourd before he has worked out what is wrong."],
		["Yue Ling", "All of it. Slowly. ...The Old Master says the highest good is like water. He meant, I think, that one should drink some.", "nod"]],
	"bladder": [["Narrator", "There are things no cultivation base can hold back for ever. Lin Feng does not, quite, reach the tree."],
		["Yue Ling", "I saw nothing. I was looking at that cloud. It is a very interesting cloud. ...There is a stream down there, when you are ready.", "laugh"]],
	"bowels": [["Narrator", "There is a moment of great stillness, as before a tribulation, and then it is clear to Lin Feng that he has left a certain matter a quarter of an hour too long."],
		["Yue Ling", "I am going to walk ahead, a good way ahead, and pick herbs, facing north. Take all the time you need. Take the soap.", "shrug"]],
}
## what she says of the body, now and then, when all is well or something is low
const YUE_LOW := {
	"rest": "You are walking with your eyes shut. There is an inn. I am not carrying you past it.",
	"hunger": "That was your stomach. I thought it was a tiger. Eat something before it frightens the horses.",
	"thirst": "Your lips are cracked. Drink. I did not heal half the land to watch you dry out like a persimmon.",
	"bladder": "You have been shifting from foot to foot for a li. There is a perfectly good tree. I will look at the view.",
	"bowels": "You have gone the colour of old tofu. Go. I will count the clouds. Slowly.",
	"comfort": "You are sore, and cold, and pretending not to be. Sit down by a fire. That is an order from your physician.",
	"clean": "I say this as somebody who loves you. Downwind. Until there is a bath.",
}

static func on(g) -> bool:
	return bool(g.survival)

## Begin: every need content, three buns and a full gourd.
static func begin(g) -> void:
	g.survival = true
	g.needs = {}
	for k in ORDER:
		g.needs[k] = 85.0
	g.inv["steamed_bun"] = int(g.inv.get("steamed_bun", 0)) + 3
	g.gourd = GOURD
	g.needs["since"] = g.day
	g.needs_fell = {}
	g.needs_clock = float(g.clock) + float(g.day) * 1440.0
	g.note("Survival: the body asks for what it asks for")

static func end(g) -> void:
	g.survival = false
	g.note("Survival put aside")

static func value(g, k: String) -> float:
	return float(g.needs.get(k, 100.0)) if on(g) else 100.0

static func lowest(g) -> String:
	var out := ""
	var lo := 999.0
	for k in ORDER:
		if value(g, k) < lo:
			lo = value(g, k)
			out = k
	return out

## How fast the needs of somebody of this realm run down, against a mortal's.
static func pace(g) -> float:
	return maxf(FLOOR, 1.0 - BIGU * float(g.realm()))

## Change needs by `d` ({need: by}); nothing goes under 0 or over 100.
static func give(g, d: Dictionary) -> void:
	if not on(g):
		return
	for k in d:
		if NEEDS.has(k):
			g.needs[k] = clampf(float(g.needs.get(k, 100.0)) + float(d[k]), 0.0, 100.0)

## The clock has moved `hours`: every need runs down (the road, the night and the cold wear comfort
## faster: `rough`), and a need at nothing takes matters into its own hands.  Returns what happened
## (the needs that collapsed), having said it.
static func pass_time(g, hours: float, rough: float = 1.0) -> Array:
	var out: Array = []
	if not on(g) or hours <= 0.0:
		return out
	var k0 := pace(g)
	for k in ORDER:
		var r := float(NEEDS[k].rate) * k0 * hours
		if k == "comfort":
			r *= rough
		g.needs[k] = maxf(0.0, float(g.needs.get(k, 100.0)) - r)
	for k2 in ["rest", "hunger", "thirst", "bladder", "bowels"]:
		if float(g.needs[k2]) <= 0.0:
			out.append(k2)
			_collapse(g, k2)
	return out

static func _collapse(g, k: String) -> void:
	var lines: Array = []
	for l in COLLAPSE[k]:
		if str(l[0]) != "Yue Ling" or g.companion:
			lines.append(l)
	g.egg_pending.append(lines)
	g.needs_fell[k] = int(g.needs_fell.get(k, 0)) + 1
	match k:
		"rest":
			# asleep where he stood: six hours gone, rested somewhat, and stiff
			g.needs["rest"] = 55.0
			give(g, {"comfort": -30.0, "clean": -8.0})
			Clock.set_hour(g, fposmod(Clock.hour(g) + 6.0, 24.0))
		"hunger":
			g.needs["hunger"] = 30.0
			g.hp[0] = maxf(1.0, g.hp[0] * 0.5)
		"thirst":
			g.needs["thirst"] = 35.0
			g.qi[0] = g.qi[0] * 0.5
		"bladder":
			g.needs["bladder"] = 100.0
			give(g, {"clean": -45.0, "comfort": -25.0})
		"bowels":
			g.needs["bowels"] = 100.0
			give(g, {"clean": -70.0, "comfort": -35.0})
	g.note("The body had its way: %s" % str(NEEDS[k].low))
	g.toast("%s: %s" % [str(NEEDS[k].n), str(NEEDS[k].low)])

## Called as the game goes (game.gd): the needs follow the land's clock, however it moves.
static func tick(g, rough: float = 1.0) -> void:
	if not on(g):
		return
	var now := float(g.clock) + float(g.day) * 1440.0
	var dm := now - float(g.needs_clock)
	g.needs_clock = now
	# (a clock set by the story, or a night slept through, is at most a night's worth of wanting)
	if dm <= 0.0 or dm > 720.0:
		return
	pass_time(g, dm / 60.0, rough)

## A thing of the land has been used (props.gd).
static func used(g, kind: String, effect: String) -> void:
	if not on(g):
		return
	var d: Dictionary = BY_KIND.get(kind, BY_EFFECT.get(effect, {}))
	give(g, d)
	if d.has("thirst") and float(d.thirst) >= 35.0:
		g.gourd = GOURD

## What a low need costs in battle, and what keeping well gives: a multiplier for "atk", "qi" and
## "taken", a number added for "spd".  1 (or 0) with survival off.
static func mod(g, key: String) -> float:
	if not on(g):
		return 0.0 if key == "spd" else 1.0
	var well := true
	for k in ORDER:
		well = well and value(g, k) >= WELL
	match key:
		"atk":
			return (0.88 if value(g, "hunger") < LOW else 1.0) * (0.9 if value(g, "rest") < LOW else 1.0) * (1.03 if well else 1.0)
		"qi":
			return (0.9 if value(g, "thirst") < LOW else 1.0) * (0.92 if value(g, "clean") < LOW else 1.0)
		"taken":
			return 1.08 if value(g, "comfort") < LOW else (0.97 if well else 1.0)
		"spd":
			return (-2.0 if value(g, "rest") < LOW else 0.0) + (-1.0 if value(g, "bladder") < LOW or value(g, "bowels") < LOW else 0.0)
	return 1.0

## How the body is, in a word.
static func state(g) -> String:
	if not on(g):
		return "not asked after"
	var low: Array = []
	for k in ORDER:
		if value(g, k) < LOW:
			low.append(str(NEEDS[k].low))
	if low.is_empty():
		var well := true
		for k2 in ORDER:
			well = well and value(g, k2) >= WELL
		return "well kept: attack +3%, harm taken -3%" if well else "well enough"
	return ", ".join(low)

# ---------------------------------------------------------------- what can be done about it
## `ctx`: where he stands ({"indoors", "town", "water", "wild", "night", "privy"}: main.gd body_ctx).
## Each action: {"id", "label", "enabled", "why"}.
static func actions(g, ctx: Dictionary) -> Array:
	var out: Array = []
	out.append({"id": "toggle", "label": "Survival: on (turn it off)" if on(g) else "Survival: off (turn it on)", "enabled": true, "why": ""})
	if not on(g):
		return out
	for fid in FOOD_ORDER:
		var n := int(g.inv.get(fid, 0))
		out.append({"id": "eat:" + fid, "label": "Eat: %s x%d" % [str(Data.ITEMS[fid].n), n], "enabled": n > 0, "why": "None left. The cooks and innkeepers of the land sell it."})
	out.append({"id": "drink", "label": "Drink from the gourd (%d of %d)" % [int(g.gourd), GOURD], "enabled": int(g.gourd) > 0, "why": "The gourd is empty. It fills wherever you drink: a well, a tea table, a spring."})
	var can_go: bool = bool(ctx.get("wild", false)) or bool(ctx.get("privy", false))
	out.append({"id": "relieve", "label": "Step aside" if not bool(ctx.get("privy", false)) else "Use the privy out the back", "enabled": can_go,
		"why": "Not in the street. Out of town, or somewhere with a privy: an inn, a house, a barracks."})
	out.append({"id": "wash", "label": "Wash", "enabled": bool(ctx.get("water", false)), "why": "There is no water here to wash in. A stream, a pond, a well; or a bath, which is better."})
	out.append({"id": "sleep", "label": "Sleep rough, here", "enabled": bool(ctx.get("wild", false)) and not bool(ctx.get("indoors", false)), "why": "Not here. Out in the open country; or find a bed."})
	out.append({"id": "forage", "label": "Forage a while", "enabled": bool(ctx.get("wild", false)) and not bool(ctx.get("indoors", false)), "why": "There is nothing to forage in a street or under a roof."})
	return out

## Do it.  Returns what is said of it ("" if it could not be done).
static func act(g, id: String, ctx: Dictionary) -> String:
	if id == "toggle":
		if on(g):
			end(g)
			return "The body is put aside: the story as it was first told."
		begin(g)
		return "Survival: seven needs, by the clock. Three buns and a full gourd to begin with."
	for a in actions(g, ctx):
		if str(a.id) == id and not bool(a.enabled):
			return ""
	if id.begins_with("eat:"):
		var fid := id.trim_prefix("eat:")
		g.inv[fid] = int(g.inv.get(fid, 0)) - 1
		var f: Dictionary = FOOD[fid].duplicate()
		f.erase("price")
		give(g, f)
		give(g, {"bowels": -6.0})
		return "Eaten: %s." % str(Data.ITEMS[fid].n)
	match id:
		"drink":
			g.gourd = int(g.gourd) - 1
			give(g, {"thirst": 45.0, "bladder": -8.0})
			return "A long pull at the gourd."
		"relieve":
			give(g, {"bladder": 100.0, "bowels": 100.0})
			if not bool(ctx.get("privy", false)):
				give(g, {"clean": -4.0})
				return "A step off the road, behind a tree. Yue Ling takes a great interest in the horizon."
			return "The privy out the back. There is a sprig of mugwort hung in it, as there ought to be."
		"wash":
			give(g, {"clean": 55.0, "comfort": 6.0})
			return "Cold water, hands and face and neck. Not a bath; a great deal better than nothing."
		"sleep":
			give(g, {"rest": 70.0, "comfort": -22.0, "clean": -6.0})
			Clock.set_hour(g, 6.0)
			g.needs_clock = float(g.clock) + float(g.day) * 1440.0
			give(g, {"hunger": -18.0, "thirst": -20.0, "bladder": -30.0})
			return "Slept under the sky, on the cloak, with a root in the back. It is morning, and everything aches a little."
		"forage":
			give(g, {"hunger": 26.0, "thirst": 18.0, "comfort": -6.0, "rest": -4.0})
			Clock.set_hour(g, fposmod(Clock.hour(g) + 0.75, 24.0))
			g.needs_clock = float(g.clock) + float(g.day) * 1440.0
			return "Wild yam, a handful of sour berries, water out of a leaf. Three quarters of an hour, and nobody is full."
	return ""

## What somebody careful would do now ("" if nothing needs doing or nothing can be done): the bot.
static func advice(g, ctx: Dictionary) -> String:
	if not on(g):
		return ""
	var acts := {}
	for a in actions(g, ctx):
		acts[str(a.id)] = bool(a.enabled)
	if value(g, "thirst") < 45.0 and acts.get("drink", false):
		return "drink"
	if value(g, "hunger") < 45.0:
		for fid in ["noodle_bowl", "dried_meat", "steamed_bun", "tea_egg"]:
			if acts.get("eat:" + fid, false):
				return "eat:" + fid
		if acts.get("forage", false):
			return "forage"
	if value(g, "thirst") < 30.0 and acts.get("forage", false):
		return "forage"
	if (value(g, "bladder") < 40.0 or value(g, "bowels") < 40.0) and acts.get("relieve", false):
		return "relieve"
	if value(g, "clean") < 40.0 and acts.get("wash", false):
		return "wash"
	if value(g, "rest") < 30.0 and acts.get("sleep", false):
		return "sleep"
	return ""

## The page's words for one need.
static func text(g, k: String) -> String:
	var v := value(g, k)
	return "%s: %d  (%s)" % [str(NEEDS[k].n), int(round(v)), str(NEEDS[k].low) if v < LOW else str(NEEDS[k].ok)]
