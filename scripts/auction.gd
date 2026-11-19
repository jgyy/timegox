class_name Auction
extends RefCounted
## The auction houses (the Red Seal release): three rooms where things are sold to whoever will give most.
##
## A **house** (`HOUSES`) is kept at the counter of a town.  Every day it has four **lots** drawn from its
## own catalogue **by the day** (never by lot: the same day shows the same four to every journey), the
## fourth in its **sealed room**, which three papers of the Hall of Seals open (seals.gd) and where the
## curios are: things that do nothing, of which there is one each, and which stay sold.
##
## **Bidding is against three people who are there every day** (`bidders`), each of whom has decided
## before he came in what a lot is worth to them (`ceiling`: a share of its value, by the day).  A bid is
## answered at once by whoever would still go higher; a bid nobody will top **wins, and is what is paid**.
## So some days a lot goes for little more than half its worth, and some days somebody in the room wants
## it more than it is worth and the right answer is "Let it go", which is always the first one.
##
## **A sealed bid can be left by post** (`post_bid`, at any counter of the post: mail.gd) on a lot of
## *tomorrow's* sale in a house of a town he has walked into: the stones go into the bag, and when the day
## has come the lot is his if nobody in the room would have gone higher (it waits at any counter, as a
## parcel), or the stones come back.
##
## Nothing sold here can be sold on for more: pills, essences, household things, curios.  Nothing is
## random.  A step may ask that a lot be won (`"kind": "bid"`); the bot takes the lot that goes cheapest.

const OPEN := "s_p39_home"
## the lots a house shows a day, and which of them is in the sealed room
const LOTS := 4
const SEALED := 3
## where bidding opens (a share of a lot's value), the size of a raise, and the range of what somebody in the
## room will go to
const RESERVE := 0.5
const STEP := 0.05
const LOW := 0.55
const SPAN := 0.75

const HOUSES := {
	"qingshi": {"n": "The Lantern Room of Qingshi", "office": "head_qingshi", "area": "village", "crier": "Auctioneer Hu",
		"desc": "The upper floor of the drum tower on the evenings the drum is not wanted. Benches, a lantern for each lot, and Auctioneer Hu, who was a fishmonger and sells a jade carp exactly as he sold a real one.",
		"cat": [["hp_pill", 3], ["qi_pill", 2], ["bead_curtain", 1], ["mirror_cloth", 1], ["water_jar", 1], ["incense_burner", 1], ["orchid", 1], ["oil_lamp", 1], ["house_broom", 1], ["ess_wood", 2], ["ess_earth", 2]],
		"curios": ["curio_inkstone", "curio_gourd"],
		"bidders": [["Granny Wen's Niece", "\"%d. It is for my aunt. Do not look at me like that, it is.\""], ["Tofu-Seller Dou", "\"%d, and I am robbing myself.\""], ["a pedlar from Cloudfoot", "A hand goes up at the back: %d."]]},
	"longmen": {"n": "The Tide Hammer of Longmen", "office": "harbour_longmen", "area": "longmen", "crier": "Hammer-Wife Jiang",
		"desc": "A net-loft over the quay. The lots come up the ladder in fish baskets and the hammer is a caulking mallet. Everything is sold before the tide turns, because the buyers have boats.",
		"cat": [["hp_pill", 4], ["qi_pill", 3], ["ess_water", 3], ["ess_thunder", 2], ["ess_metal", 2], ["ess_wood", 2], ["ess_fire", 2], ["water_jar", 1], ["oil_lamp", 1]],
		"curios": ["curio_carp", "curio_tally"],
		"bidders": [["Lock-Keeper Min", "\"%d.\" He does not look up from his pipe."], ["a boatwright's widow", "\"%d. My husband would have gone higher. He always did.\""], ["a factor of the coast trade", "\"%d, on account.\""]]},
	"tushan": {"n": "The Cauldron Room of Tushan", "office": "guild_tushan", "area": "tushan", "crier": "Assay-Master Luan",
		"desc": "The guild's weighing room, with the great scale pushed against the wall. Assay-Master Luan rings every bronze lot with his knuckle before he sells it, and tells the room the note, and nobody has ever caught him wrong.",
		"cat": [["hp_pill", 5], ["qi_pill", 4], ["ess_fire", 3], ["ess_earth", 3], ["ess_metal", 3], ["ess_dark", 2], ["ess_thunder", 2], ["incense_burner", 1], ["mirror_cloth", 1]],
		"curios": ["curio_bell", "curio_horse"],
		"bidders": [["a caster of the Third Pit", "\"%d. I know what went into it.\""], ["Guild-Widow Shan", "\"%d.\" She has not moved her fan."], ["an agent of the court", "\"The Cauldron Hall will say %d.\""]]},
}
const ORDER := ["qingshi", "longmen", "tushan"]
## what a thing is worth before the realm is counted (a house asks by what the buyer has become)
const VALUE := {"hp_pill": 14, "qi_pill": 18, "bead_curtain": 26, "mirror_cloth": 24, "water_jar": 20, "incense_burner": 30, "orchid": 22, "oil_lamp": 24, "house_broom": 16,
	"ess_wood": 22, "ess_fire": 22, "ess_water": 22, "ess_earth": 22, "ess_thunder": 24, "ess_dark": 30, "ess_metal": 24,
	"curio_inkstone": 260, "curio_gourd": 220, "curio_carp": 300, "curio_tally": 280, "curio_bell": 320, "curio_horse": 360}
const CURIOS := ["curio_inkstone", "curio_gourd", "curio_carp", "curio_tally", "curio_bell", "curio_horse"]

static func open(g) -> bool:
	return g.done(OPEN)

## The house kept at the counter of `office` ("" if none).
static func at(office: String) -> String:
	for id in ORDER:
		if str(HOUSES[id].office) == office:
			return id
	return ""

static func _u(house: String, day: int, k: int, salt: int) -> float:
	return float(absi(hash("%s|%d|%d|%d" % [house, day, k, salt])) % 10007) / 10007.0

## What `n` of `item` are worth to somebody of level `lv`.
static func value(item: String, n: int, lv: int) -> int:
	return int(VALUE.get(item, 20)) * n * (1 + Data.realm_of(lv))

static func key(house: String, day: int, k: int) -> String:
	return "%s:%d:%d" % [house, day, k]

## The lots of `house` on `day`: [{k, item, n, value, open, step, sealed, sold}].
static func lots_on(g, house: String, day: int) -> Array:
	var h: Dictionary = HOUSES[house]
	var out: Array = []
	var cat: Array = h.cat
	var first := absi(hash("%s|%d" % [house, day])) % cat.size()
	for k in LOTS:
		var item := ""
		var n := 1
		if k == SEALED:
			# the sealed room: the curio of the day that he has not got; when he has both, the best of the catalogue
			var cs: Array = h.curios
			for j in cs.size():
				var c := str(cs[(day + j) % cs.size()])
				# (the Two Roads release: a curio won by a sealed bid and still lying at the post is his already:
				# there is only the one of each)
				if item == "" and int(g.inv.get(c, 0)) == 0 and not g.parcels.any(func(pc): return str(pc.get("item", "")) == c):
					item = c
			if item == "":
				item = "ess_dark"
				n = 3
		else:
			var e: Array = cat[(first + k * 2 + (day % 2)) % cat.size()]
			item = str(e[0])
			n = int(e[1])
		var v := value(item, n, int(g.level))
		out.append({"k": k, "item": item, "n": n, "value": v, "open": int(ceil(float(v) * RESERVE)), "step": maxi(1, int(round(float(v) * STEP))),
			"sealed": k == SEALED, "sold": g.lots.has(key(house, day, k))})
	return out

static func lots(g, house: String) -> Array:
	return lots_on(g, house, int(g.day))

## What bidder `i` of `house` will go to for lot `k` of `day`, worth `v`; and the most anybody will.
static func ceiling(house: String, day: int, k: int, i: int, v: int) -> int:
	return int(floor(float(v) * (LOW + SPAN * _u(house, day, k, i))))

static func top(house: String, day: int, k: int, v: int) -> Array:
	var best := 0
	var who := 0
	for i in (HOUSES[house].bidders as Array).size():
		var c := ceiling(house, day, k, i, v)
		if c > best:
			best = c
			who = i
	return [best, who]

## Where the bidding on a lot of today stands: what was last called (its opening price if nobody has).
static func standing(g, house: String, lot: Dictionary) -> int:
	return int(g.lot_at.get(key(house, int(g.day), int(lot.k)), int(lot.open) - int(lot.step)))

## The least he may bid next on `lot`; and that, raised `steps` more.
static func next_bid(g, house: String, lot: Dictionary, steps: int = 1) -> int:
	return standing(g, house, lot) + int(lot.step) * maxi(1, steps)

## Why he cannot bid on `lot` of `house` today ("" if he can).
static func blocked(g, house: String, lot: Dictionary) -> String:
	if not open(g):
		return "The room is not open."
	if Crime.shut(g, str(HOUSES[house].area), "room") != "":
		return Crime.shut(g, str(HOUSES[house].area), "room")
	if bool(lot.sold):
		return "Sold."
	if bool(lot.sealed) and Seals.count(g) < Seals.ROOM:
		return "The sealed room is opened by %d papers of the Hall of Seals (he holds %d)." % [Seals.ROOM, Seals.count(g)]
	if int(g.stones) < next_bid(g, house, lot):
		return "The next call is %d spirit stones." % next_bid(g, house, lot)
	return ""

## He calls `amount` on `lot` of `house`.  Returns {} (it could not be called), or {won, at, who, say}: `won`
## and what he paid, or who topped him and at what.
static func bid(g, house: String, lot: Dictionary, amount: int) -> Dictionary:
	if blocked(g, house, lot) != "" or amount < next_bid(g, house, lot) or amount > int(g.stones):
		return {}
	var day := int(g.day)
	var k := int(lot.k)
	var t := top(house, day, k, int(lot.value))
	var bd: Array = HOUSES[house].bidders[int(t[1])]
	if amount >= int(t[0]):
		_won(g, house, lot, amount)
		return {"won": true, "at": amount, "who": "", "say": "\"%d. Any more? Then it is the cultivator's.\" The hammer comes down." % amount}
	var at := mini(int(t[0]), amount + int(lot.step))
	g.lot_at[key(house, day, k)] = at
	return {"won": false, "at": at, "who": str(bd[0]), "say": "%s: %s" % [str(bd[0]), str(bd[1]) % at]}

static func _won(g, house: String, lot: Dictionary, paid: int) -> void:
	g.stones -= paid
	g.lots[key(house, int(g.day), int(lot.k))] = paid
	g.inv[str(lot.item)] = int(g.inv.get(str(lot.item), 0)) + int(lot.n)
	g.lots_won = int(g.lots_won) + 1
	g.lot_spent = int(g.lot_spent) + paid
	g.lot_saved = int(g.lot_saved) + int(lot.value) - paid
	# (the Two Roads release: a step that sends him to one room is not done by a lot won in another)
	if str(g.cur_step().get("house", house)) == house:
		g.step_bid = int(g.step_bid) + 1
	g.note("Bought at %s: %s x%d (%d spirit stones)" % [str(HOUSES[house].n), str(Data.ITEMS[str(lot.item)].n), int(lot.n), paid])

## The least that wins `lot` today: the first call he may make that nobody will top.
static func to_win(g, house: String, lot: Dictionary) -> int:
	var c := int(top(house, int(g.day), int(lot.k), int(lot.value))[0])
	var b := next_bid(g, house, lot)
	while b < c:
		b += int(lot.step)
	return b

## The lot of `house` that goes cheapest today among those he may bid on and can pay for ({} if none).
static func cheapest(g, house: String) -> Dictionary:
	var best := {}
	var bw := 0
	for lot in lots(g, house):
		if blocked(g, house, lot) != "":
			continue
		var w := to_win(g, house, lot)
		if w <= int(g.stones) and (best.is_empty() or w < bw):
			best = lot
			bw = w
	return best

# ---------------------------------------------------------------- sealed bids, by post
## Why a sealed bid of `amount` cannot be left for lot `k` of tomorrow's sale at `house` ("" if it can).
static func post_blocked(g, house: String, k: int, amount: int) -> String:
	if not open(g):
		return "The rooms are not open."
	if not g.seen.has(str(HOUSES[house].area)):
		return "He has never stood in that room, and the house takes no bid from a stranger."
	# (the Sea Floor release: a room shut to a wanted man at its door is shut to his bid in the post-bag too)
	if Crime.shut(g, str(HOUSES[house].area), "room") != "":
		return Crime.shut(g, str(HOUSES[house].area), "room")
	if k == SEALED and Seals.count(g) < Seals.ROOM:
		return "The sealed room is opened by %d papers." % Seals.ROOM
	for b in g.sealed_bids:
		if str(b.house) == house and int(b.day) == int(g.day) + 1 and int(b.k) == k:
			return "A bid of his is in the bag for that lot already."
	if amount > int(g.stones):
		return "He has not %d spirit stones to put in the bag." % amount
	return ""

## A sealed bid goes into the post: the stones go with it.
static func post_bid(g, house: String, k: int, amount: int) -> bool:
	if post_blocked(g, house, k, amount) != "":
		return false
	g.stones -= amount
	g.sealed_bids.append({"house": house, "day": int(g.day) + 1, "k": k, "amount": amount})
	g.note("Left a sealed bid for %s (%d spirit stones)" % [str(HOUSES[house].n), amount])
	return true

## The sealed bids whose day has come are opened: a lot won waits as a parcel (mail.gd), and the stones of a
## bid that lost come back.  Returns what is told of each.
static func settle(g) -> Array:
	var out: Array = []
	var keep: Array = []
	for b in g.sealed_bids:
		if int(b.day) > int(g.day):
			keep.append(b)
			continue
		var house := str(b.house)
		var lot: Dictionary = lots_on(g, house, int(b.day))[int(b.k)]
		var c := int(top(house, int(b.day), int(b.k), int(lot.value))[0])
		if int(b.amount) >= c and not g.lots.has(key(house, int(b.day), int(b.k))):
			g.lots[key(house, int(b.day), int(b.k))] = int(b.amount)
			g.parcels.append({"item": str(lot.item), "n": int(lot.n), "from": str(HOUSES[house].n)})
			g.lots_won = int(g.lots_won) + 1
			g.lot_spent = int(g.lot_spent) + int(b.amount)
			g.lot_saved = int(g.lot_saved) + int(lot.value) - int(b.amount)
			if str(g.cur_step().get("house", house)) == house:
				g.step_bid = int(g.step_bid) + 1
			out.append("%s: your sealed bid of %d took the lot. It is in the post: %s x%d." % [str(HOUSES[house].n), int(b.amount), str(Data.ITEMS[str(lot.item)].n), int(lot.n)])
		else:
			g.stones += int(b.amount)
			out.append("%s: your sealed bid of %d was not the highest in the room (it went at %d). The stones are returned." % [str(HOUSES[house].n), int(b.amount), c])
	g.sealed_bids = keep
	return out

## How many curios he has.
static func curios(g) -> int:
	var n := 0
	for c in CURIOS:
		if int(g.inv.get(c, 0)) > 0:
			n += 1
	return n

static func text(g) -> String:
	return "%d lots bought for %d spirit stones (%s%d against what they were worth); %d of %d curios; %d sealed bids in the post" % [int(g.lots_won), int(g.lot_spent), "+" if int(g.lot_saved) >= 0 else "", int(g.lot_saved), curios(g), CURIOS.size(), g.sealed_bids.size()]
