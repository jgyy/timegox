class_name Yezi
extends RefCounted
## Leaves (the Two Roads release): the card games of the land.  A pack is forty leaves of stiff paper, eight of
## each of the five phases (wood, fire, earth, thunder, water), numbered one to eight; a master may paint a
## ninth of one phase, which is theirs, and is won from them once.
##
## Two games are played with it, at any tea-house table:
##
##   The Round            five leaves in the hand.  One leads a leaf and the other answers it.  A phase that
##                        overcomes the other takes the trick whatever is written on either (water puts out
##                        fire, fire burns wood, wood breaks earth, earth buries thunder, thunder runs through
##                        water).  Two leaves of one phase: the higher takes it.  A phase and the one it bears,
##                        where neither overcomes (water and wood, fire and earth ...): the higher takes it, and it
##                        counts double, since one fed the other.  Two with nothing between them: the higher.  Whoever took it draws first and leads.  Seven points is the game.
##   Three in the Morning seven leaves each, three deals.  Each sets three leaves down as the morning and keeps
##                        four for the evening, and the evening must be worth more than the morning, or the
##                        monkeys are furious and both piles are lost.  Mornings are counted against each
##                        other, then evenings.  Whoever has taken more piles after three deals has the table.
##
## Nothing is staked.  Whoever loses pays for the tea (`tea`), to the house: nobody ever leaves a table of leaves
## richer in stones, so there is no playing it for a living.  What a win is worth is the win, the word that goes
## round a town, and a master's painted leaf the first time.
##
## Nothing is random that cannot be played again: every deal is drawn from the journey's own count of hands
## (`Game.card_n`) and who sits opposite, so the same journey is dealt the same leaves, and the tests can play
## ten thousand hands.  Everything here is pure: `start`, `lay`, `set_down` take a state and move it on; the
## screen (leaves.gd) only draws it and takes the leaf.  A step may ask that so many hands be won
## (`"kind": "cards"`); the bot plays `best` and, outside such a step, never sits down.

const PHASES := ["wood", "fire", "earth", "thunder", "water"]
## the colour a leaf of each phase is painted
const COLS := {"wood": Color("5aa860"), "fire": Color("d85a3a"), "earth": Color("c8a050"), "thunder": Color("9a7ad8"), "water": Color("4a8ac8")}
const HAND := 5
const TARGET := 7
const MORNING := 3
const EVENING := 4
const SEVEN := 7
const DEALS := 3
const GAMES := {
	"round": {"n": "The Round", "desc": "Five leaves in the hand; one leads, one answers. A phase that overcomes the other takes the trick whatever is written on it. The same phase, or two with nothing between them: the higher leaf. A phase and the one it bears (water and wood, fire and earth): the higher leaf, and it counts double. Seven points is the game."},
	"morning": {"n": "Three in the Morning", "desc": "Seven leaves, three deals. Set three down as the morning and keep four for the evening; the evening must be worth more, or the monkeys are furious and both are lost. Morning is counted against morning, evening against evening: a morning taken is three acorns, an evening four. Most acorns after three deals has the table."},
}
const GAME_ORDER := ["round", "morning"]

## Who can be sat down with by name: where they are found (`at`: an office's counter, or somebody who stands in the
## land), the game they keep, how well they play it (0 plays the biggest leaf they hold, 1 the least leaf that
## wins, 2 counts what has gone), the leaf they painted (a phase; rank nine), and what they say.
const MASTERS := {
	"du_outer": {"n": "Hall Master Du", "at": "treasurer", "area": "sect", "game": "round", "skill": 0, "leaf": "earth",
		"sit": "Two hundred and six disciples and one pack between them, and it is mine. I confiscated it. I am, strictly, guarding it. Cut.",
		"won": "Ha. No, do not apologise. I count rice all day. It is restful to count something that does not complain about the portion.",
		"lost": "I led the eight. I always lead the eight. Bao has told me so for nine years. Take the leaf, child, I painted it for whoever stopped me."},
	"zhen_lantern": {"n": "Auntie Zhen of the Lantern Stall", "at": "warden_yanggu", "area": "yanggu", "game": "round", "skill": 1, "leaf": "fire",
		"sit": "Before dawn the Market belongs to whoever is awake, and that is me and the Warden, and the Warden cannot play. Sit. Mind the wax.",
		"won": "You answer too honestly. A leaf is not a question you are obliged to answer with your best. Keep one back. Keep it back from me, next time.",
		"lost": "Well. Forty years at this table, and I am out-waited by somebody who sweeps. Here: the red nine. I painted it by my own lantern, so the red is not quite true."},
	"ban_netloft": {"n": "Old Ban of the Net-Loft", "at": "harbour_longmen", "area": "longmen", "game": "morning", "skill": 1, "leaf": "water",
		"sit": "We play it in the loft while the nets dry. Three for the morning, four for the night. The river plays it too: it gives in spring and takes in autumn and the fools are surprised twice a year.",
		"won": "You fed the morning and starved the night. It is the commonest way to drown. Come back when the nets are up again.",
		"lost": "Hm. You gave the morning just enough to stop it shouting. That is how a toll is set, did you know? Take the blue nine. It has been in the river once and came back."},
	"rong_pits": {"n": "Forewoman Rong of the Pits", "at": "guild_tushan", "area": "tushan", "game": "round", "skill": 2, "leaf": "thunder",
		"sit": "I know what has been poured and what is left in the crucible. It is the same trick with forty leaves. Do not expect to be given anything.",
		"won": "The earth eight went in your third trick. You forgot it had gone. I did not. That is the whole of the game, and of casting.",
		"lost": "You counted. Nobody counts. They play what is in the hand as if the pack began this morning. Here. The violet nine. Do not lead it."},
	"ju_gong": {"n": "Ju Gong", "at": "ju_gong", "area": "silk", "game": "morning", "skill": 2, "leaf": "wood",
		"sit": "Three in the morning and four at night: furious. Four in the morning and three at night: delighted. Seven acorns either way. Sit down, and let us see which you are.",
		"won": "You were so anxious not to be the monkey that you were the keeper, and a bad one. Nothing was at stake, and you counted as if something were. Again?",
		"lost": "There. Neither the name nor the thing was altered, and you made use of their joy and their fury. You may have the green nine. The monkeys painted it. Do not ask with what."},
}
const MASTER_ORDER := ["du_outer", "zhen_lantern", "ban_netloft", "rong_pits", "ju_gong"]

## What somebody of the towns who plays (the role `leafer`, folk.gd) says as they sit, win and lose.
const FOLK_SIT := ["Sit, sit. The loser pours. That is the only rule nobody has ever argued with.", "A hand? I have been waiting an hour for somebody who has not already lost to me today.",
	"Mind the tea. No, play. I can mind the tea and take your leaves both."]
const FOLK_WON := ["Ha! The pot is yours to fill. I take mine strong.", "You play like somebody with a road to get back to. The leaves can tell.", "Again tomorrow. Bring whoever taught you. I should like to beat them too."]
const FOLK_LOST := ["Well. I pour. It has happened before, though not, I think, this year.", "You kept the water back three tricks. I saw it and still walked into it. Pour for yourself; my hand is shaking.",
	"Beaten at my own table, by a cultivator. They will not let me forget it before the new year."]

const ASK := "A table of leaves: will you sit?"
const WHO_ASK := "Leaves: who will you sit down with?"

# ---------------------------------------------------------------- the leaves
## A leaf is phase * 10 + rank (rank one to nine: nine is painted).
static func leaf(ph: String, rank: int) -> int:
	return PHASES.find(ph) * 10 + rank

static func phase(c: int) -> String:
	return PHASES[int(c / 10) % PHASES.size()]

static func rank(c: int) -> int:
	return c % 10

static func name_of(c: int) -> String:
	return "%s %d" % [str(Phases.NAMES[phase(c)]), rank(c)]

## How leaf `a` stands to leaf `b`: "quells" (a's phase overcomes b's), "quelled", "feeds" (one of the two bears
## the other and neither overcomes: the higher takes it, double), "apart" (nothing between them: the higher) or "same".
static func stands(a: int, b: int) -> String:
	var pa := phase(a)
	var pb := phase(b)
	if pa == pb:
		return "same"
	if str(Phases.QUELLS[pa]) == pb:
		return "quells"
	if str(Phases.QUELLS[pb]) == pa:
		return "quelled"
	# (fire is borne by wood and burns it: where one overcomes the other, that is what counts)
	if str(Phases.FEEDS[pa]) == pb or str(Phases.FEEDS[pb]) == pa:
		return "feeds"
	return "apart"

## Whether the leaf that was led takes the trick against the leaf that answered it (a tie is the leader's).
static func lead_takes(led: int, ans: int) -> bool:
	match stands(led, ans):
		"quells":
			return true
		"quelled":
			return false
	return rank(led) >= rank(ans)

## What a trick of these two leaves is worth to whoever takes it.
static func worth(a: int, b: int) -> int:
	return 2 if stands(a, b) == "feeds" else 1

static func _u(n: int, salt: int) -> float:
	var h := (n * 2654435761 + salt * 40503 + 1543) & 0x7fffffff
	h = ((h ^ (h >> 15)) * 2246822519) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 3266489917) & 0x7fffffff
	return float(h ^ (h >> 16)) / 2147483648.0

## The pack as it lies for hand `n` against `foe`: the same hand of the same journey is the same pack.
static func pack(n: int, foe: String) -> Array:
	var d: Array = []
	for p in PHASES.size():
		for r in range(1, 9):
			d.append(p * 10 + r)
	var salt := absi(hash(foe)) % 9973
	for i in range(d.size() - 1, 0, -1):
		var j := mini(i, int(_u(n * 41 + i, salt) * float(i + 1)))
		var tmp = d[i]
		d[i] = d[j]
		d[j] = tmp
	return d

# ---------------------------------------------------------------- who is sat with
## Somebody to play: a master by id, or one of the people of the towns (`folk:<town>:<k>`), who plays the Round
## on odd days and Three in the Morning on even ones, as well as their seed makes them.
static func foe(id: String, p: Dictionary = {}) -> Dictionary:
	if MASTERS.has(id):
		var m: Dictionary = MASTERS[id].duplicate()
		m["id"] = id
		m["master"] = true
		return m
	var seed_ := int(p.get("seed", absi(hash(id)) % 1000))
	return {"id": id, "n": str(p.get("n", "A Leaf-Player")), "game": "", "skill": seed_ % 2, "master": false,
		"sit": FOLK_SIT[seed_ % FOLK_SIT.size()], "won": FOLK_WON[seed_ % FOLK_WON.size()], "lost": FOLK_LOST[seed_ % FOLK_LOST.size()]}

## The game `f` plays today.
static func game_of(g, f: Dictionary) -> String:
	if str(f.game) != "":
		return str(f.game)
	return GAME_ORDER[(int(g.day) + int(absi(hash(str(f.id))) % 2)) % 2]

## The masters found at `at` (an office's counter, or somebody who stands in the land).
static func at(where: String) -> Array:
	var out: Array = []
	for id in MASTER_ORDER:
		if str(MASTERS[id].at) == where:
			out.append(id)
	return out

## What the loser pays the house for the tea.
static func tea(g) -> int:
	return 20 + 4 * int(g.level)

## Why he cannot sit down with `id` now ("" if he can): the tea must be in his purse, and somebody beaten today
## will not play again until tomorrow (a master; the people of the towns play all day).
static func blocked(g, id: String) -> String:
	if int(g.stones) < tea(g):
		return "The loser pours, and a pot is %d spirit stones. Nobody sits down who could not pour." % tea(g)
	var rec: Dictionary = g.cards.get(id, {})
	if MASTERS.has(id) and int(rec.get("beat_day", -1)) == int(g.day):
		return "\"Not twice in a day. I am going to sit here and work out what you did.\""
	return ""

# ---------------------------------------------------------------- a hand
## A hand begun: of `game`, against `f` (see `foe`), dealt from the journey's count of hands; `painted` is the
## painted leaf he brought (0 for none: it takes the place of the least leaf he is dealt).
static func start(g, f: Dictionary, game: String = "", painted: int = 0) -> Dictionary:
	if game == "":
		game = game_of(g, f)
	var st := {"game": game, "foe": f, "n": int(g.card_n), "me": [], "foe_hand": [], "deck": [], "pts": 0, "foe_pts": 0, "over": "", "log": [],
		"lead": "me", "led": -1, "seen": {}, "tricks": 0, "last": {}, "deal": 0, "morning": [], "painted": painted, "tea": tea(g)}
	if game == "round":
		st.deck = pack(int(g.card_n), str(f.id))
		for k in HAND:
			st.me.append(st.deck.pop_back())
			st.foe_hand.append(st.deck.pop_back())
		# who leads the first trick turns on the hand's number, so that it is not always the guest
		st.lead = "me" if int(g.card_n) % 2 == 0 else "foe"
		_paint(st)
		if st.lead == "foe":
			_foe_leads(st)
	else:
		_deal_seven(st)
		_paint(st)
	return st

## The painted leaf he brought takes the place of the least leaf of his first hand.
static func _paint(st: Dictionary) -> void:
	if int(st.painted) <= 0:
		return
	var low := 0
	for k in st.me.size():
		if rank(int(st.me[k])) < rank(int(st.me[low])):
			low = k
	st.me[low] = int(st.painted)

static func _deal_seven(st: Dictionary) -> void:
	var d := pack(int(st.n) * 7 + int(st.deal), str(st.foe.id))
	st.me = []
	st.foe_hand = []
	for k in SEVEN:
		st.me.append(d.pop_back())
		st.foe_hand.append(d.pop_back())
	st.me.sort()
	st.morning = []

# ---------------------------------------------------------------- the Round
static func _note(st: Dictionary, s: String) -> void:
	(st.log as Array).append(s)

static func _see(st: Dictionary, c: int) -> void:
	st.seen[c] = true

## How many leaves nobody has yet seen played could overcome `c` (what a player who counts asks).
static func _threat(st: Dictionary, c: int, own: Array) -> int:
	var n := 0
	for p in PHASES.size():
		for r in range(1, 9):
			var o := p * 10 + r
			if not st.seen.has(o) and not own.has(o) and not lead_takes(c, o):
				n += 1
	return n

## The leaf somebody of `skill` leads from `hand`.
static func lead_of(st: Dictionary, hand: Array, skill: int) -> int:
	var best := int(hand[0])
	if skill <= 0:
		for c in hand:
			if rank(int(c)) > rank(best) or (rank(int(c)) == rank(best) and int(c) < best):
				best = int(c)
		return best
	if skill == 1:
		# the middle of the hand: neither the best leaf nor the worst
		var s: Array = hand.duplicate()
		s.sort_custom(func(a, b): return rank(int(a)) < rank(int(b)) or (rank(int(a)) == rank(int(b)) and int(a) < int(b)))
		return int(s[s.size() / 2])
	# counts: the leaf the fewest leaves still out could take, and of those the lowest (the high ones are kept
	# for answering)
	var bt := 1 << 30
	for c in hand:
		var th := _threat(st, int(c), hand)
		if th < bt or (th == bt and (rank(int(c)) < rank(best) or (rank(int(c)) == rank(best) and int(c) < best))):
			bt = th
			best = int(c)
	return best

## The leaf somebody of `skill` answers `led` with from `hand`.
static func answer_of(_st: Dictionary, hand: Array, led: int, skill: int) -> int:
	var best := int(hand[0])
	if skill <= 0:
		for c in hand:
			if rank(int(c)) > rank(best) or (rank(int(c)) == rank(best) and int(c) < best):
				best = int(c)
		return best
	# the least leaf that takes it (one that counts double first, for whoever counts); with none, the least leaf
	var win := -1
	var wk := 1 << 30
	var low := int(hand[0])
	for c in hand:
		var ci := int(c)
		if rank(ci) < rank(low) or (rank(ci) == rank(low) and ci < low):
			low = ci
		if not lead_takes(led, ci):
			var k := rank(ci) * 10 + (0 if stands(led, ci) == "quelled" else 5)
			if skill >= 2 and worth(led, ci) == 2:
				k -= 100
			if k < wk or (k == wk and ci < win):
				wk = k
				win = ci
	return win if win >= 0 else low

static func _foe_leads(st: Dictionary) -> void:
	var c := lead_of(st, st.foe_hand, int(st.foe.skill))
	(st.foe_hand as Array).erase(c)
	st.led = c
	_see(st, c)

## He lays leaf `c` of his hand: leading, it is answered; answering, the trick is settled.  Then whoever took it
## draws first and leads, and if that is the other side their leaf is on the table when this returns.
static func lay(st: Dictionary, c: int) -> void:
	if str(st.over) != "" or str(st.game) != "round" or not (st.me as Array).has(c):
		return
	(st.me as Array).erase(c)
	_see(st, c)
	var led: int
	var ans: int
	var mine_led: bool = str(st.lead) == "me"
	if mine_led:
		led = c
		ans = answer_of(st, st.foe_hand, c, int(st.foe.skill))
		(st.foe_hand as Array).erase(ans)
		_see(st, ans)
	else:
		led = int(st.led)
		ans = c
	var leader_takes := lead_takes(led, ans)
	var i_take := leader_takes == mine_led
	var w := worth(led, ans)
	if i_take:
		st.pts = int(st.pts) + w
	else:
		st.foe_pts = int(st.foe_pts) + w
	st.tricks = int(st.tricks) + 1
	st.last = {"led": led, "ans": ans, "mine_led": mine_led, "mine": i_take, "worth": w, "how": stands(led, ans)}
	_note(st, told(st.last, str(st.foe.n)))
	# draw: whoever took it first
	for who in (["me", "foe"] if i_take else ["foe", "me"]):
		if not (st.deck as Array).is_empty():
			(st.me if who == "me" else st.foe_hand).append(st.deck.pop_back())
	st.led = -1
	st.lead = "me" if i_take else "foe"
	if int(st.pts) >= TARGET or int(st.foe_pts) >= TARGET or (st.me as Array).is_empty():
		if int(st.pts) == int(st.foe_pts):
			st.over = "won" if i_take else "lost"
		else:
			st.over = "won" if int(st.pts) > int(st.foe_pts) else "lost"
		return
	if not i_take:
		_foe_leads(st)

## What happened in a trick, in a line.
static func told(l: Dictionary, foe_n: String) -> String:
	var a := name_of(int(l.led))
	var b := name_of(int(l.ans))
	var who := "You" if bool(l.mine) else foe_n
	var verb := "take" if bool(l.mine) else "takes"
	var why := ""
	match str(l.how):
		"quells":
			why = "%s overcomes %s" % [str(Phases.NAMES[phase(int(l.led))]).to_lower(), str(Phases.NAMES[phase(int(l.ans))]).to_lower()]
		"quelled":
			why = "%s overcomes %s" % [str(Phases.NAMES[phase(int(l.ans))]).to_lower(), str(Phases.NAMES[phase(int(l.led))]).to_lower()]
		"feeds":
			why = "one feeds the other, the higher leaf, and it counts double"
		_:
			why = "the higher leaf"
	return "%s on %s: %s %s it (%s)." % [b, a, who, verb, why]

# ---------------------------------------------------------------- Three in the Morning
static func sum(leaves: Array) -> int:
	var s := 0
	for c in leaves:
		s += rank(int(c))
	return s

## The three leaves somebody of `skill` sets down as the morning, of seven.  0: the most the morning can be given while the evening is still worth more (three
## acorns bought with four); 1: the three in the middle; 2: weighed, as `best_morning` weighs them.
static func morning_of(hand: Array, skill: int) -> Array:
	var s: Array = hand.duplicate()
	s.sort_custom(func(a, b): return rank(int(a)) < rank(int(b)) or (rank(int(a)) == rank(int(b)) and int(a) < int(b)))
	if skill == 1:
		return [s[1], s[2], s[3]] if sum([s[1], s[2], s[3]]) < sum([s[0], s[4], s[5], s[6]]) else [s[0], s[1], s[2]]
	if skill >= 2:
		return _weighed(s)
	var best: Array = [s[0], s[1], s[2]]
	var bs := -1
	for i in SEVEN:
		for j in range(i + 1, SEVEN):
			for k in range(j + 1, SEVEN):
				var m := rank(int(s[i])) + rank(int(s[j])) + rank(int(s[k]))
				if m > bs and m < sum(s) - m:
					bs = m
					best = [s[i], s[j], s[k]]
	return best

## Whether three leaves of his hand may be set down as the morning: the evening must be worth more.
static func may_set(st: Dictionary, three: Array) -> bool:
	if three.size() != MORNING:
		return false
	for c in three:
		if not (st.me as Array).has(c):
			return false
	return sum(three) < sum(st.me) - sum(three)

## He sets `three` leaves down as the morning; the other side has set theirs; the piles are counted.  A pile
## that is level is nobody's; a morning taken is three acorns and an evening four.  After three deals whoever has
## more acorns has the table (level: the keeper of it).
static func set_down(st: Dictionary, three: Array) -> void:
	if str(st.over) != "" or str(st.game) != "morning" or three.size() != MORNING:
		return
	var fm: Array = morning_of(st.foe_hand, int(st.foe.skill))
	var mine_m := sum(three)
	var mine_e := sum(st.me) - mine_m
	var foe_m := sum(fm)
	var foe_e := sum(st.foe_hand) - foe_m
	var furious := mine_m >= mine_e
	var took := 0
	var gave := 0
	if furious:
		gave = MORNING + EVENING
	else:
		took = MORNING * int(mine_m > foe_m) + EVENING * int(mine_e > foe_e)
		gave = MORNING * int(foe_m > mine_m) + EVENING * int(foe_e > mine_e)
	st.pts = int(st.pts) + took
	st.foe_pts = int(st.foe_pts) + gave
	st.last = {"m": mine_m, "e": mine_e, "fm": foe_m, "fe": foe_e, "took": took, "gave": gave, "furious": furious, "foe_morning": fm}
	if furious:
		_note(st, "Your morning is %d and your evening %d. The monkeys are furious: both piles are lost." % [mine_m, mine_e])
	else:
		var res := "nothing taken either way"
		if took > 0 or gave > 0:
			res = "%d acorn%s yours, %d theirs" % [took, "" if took == 1 else "s", gave]
		_note(st, "Morning %d against %d, evening %d against %d: %s." % [mine_m, foe_m, mine_e, foe_e, res])
	st.deal = int(st.deal) + 1
	if int(st.deal) >= DEALS:
		st.over = "won" if int(st.pts) > int(st.foe_pts) else "lost"
		return
	_deal_seven(st)

# ---------------------------------------------------------------- what is best
## The leaf to lay now in the Round (what the bot lays, and what the table would whisper): answering, the least
## leaf that takes it, one that counts double first; leading, the leaf the fewest leaves still out could take.
static func best(st: Dictionary) -> int:
	if (st.me as Array).is_empty():
		return -1
	if str(st.lead) == "me":
		return lead_of(st, st.me, 2)
	return answer_of(st, st.me, int(st.led), 2)

## The three leaves to set down in Three in the Morning: each pile weighed by how likely it is to be taken and
## what it is worth (a morning three acorns, an evening four).
static func best_morning(st: Dictionary) -> Array:
	return _weighed(st.me)

static func _weighed(hand: Array) -> Array:
	var s: Array = hand.duplicate()
	s.sort_custom(func(a, b): return rank(int(a)) < rank(int(b)) or (rank(int(a)) == rank(int(b)) and int(a) < int(b)))
	var total := sum(s)
	var best_m: Array = [s[0], s[1], s[2]]
	var bk := -1.0
	for i in SEVEN:
		for j in range(i + 1, SEVEN):
			for k in range(j + 1, SEVEN):
				var m := rank(int(s[i])) + rank(int(s[j])) + rank(int(s[k]))
				var e := total - m
				if m >= e:
					continue
				var score := float(MORNING) * clampf((float(m) - M_LO) / M_SPAN, 0.0, 1.0) + float(EVENING) * clampf((float(e) - E_LO) / E_SPAN, 0.0, 1.0)
				if score > bk:
					bk = score
					best_m = [s[i], s[j], s[k]]
	return best_m

## what a morning and an evening have to be worth to be likely to take their pile (found by playing ten thousand
## deals against keepers of every skill)
const M_LO := 6.0
const M_SPAN := 9.0
const E_LO := 15.0
const E_SPAN := 9.0

## A whole hand played by `best` on both of his turns: "won" or "lost" (what the tests and the bot's reckoning use).
static func play_out(g, f: Dictionary, game: String = "") -> Dictionary:
	var st := start(g, f, game)
	var guard := 0
	while str(st.over) == "" and guard < 64:
		guard += 1
		if str(st.game) == "round":
			lay(st, best(st))
		else:
			set_down(st, best_morning(st))
	return st

# ---------------------------------------------------------------- when it is over
## The hand is over: the count moves on, the tea is paid by whoever lost (his, to the house: nothing is ever paid
## to him), it is remembered who beat whom, and a master beaten for the first time gives the leaf they painted.
## Returns what is said: [[speaker, line], ...].
static func finish(g, st: Dictionary) -> Array:
	var f: Dictionary = st.foe
	var id := str(f.id)
	var won := str(st.over) == "won"
	g.card_n = int(g.card_n) + 1
	g.card_hands = int(g.card_hands) + 1
	var rec: Dictionary = g.cards.get(id, {"won": 0, "lost": 0})
	var lines: Array = []
	if won:
		g.card_wins = int(g.card_wins) + 1
		g.card_streak = int(g.card_streak) + 1
		g.card_best = maxi(int(g.card_best), int(g.card_streak))
		g.step_cards = int(g.step_cards) + 1
		rec["won"] = int(rec.get("won", 0)) + 1
		rec["beat_day"] = int(g.day)
		lines.append([str(f.n), str(f.lost)])
		if bool(f.get("master", false)) and not g.leaves.has(id):
			g.leaves[id] = true
			var item := "leaf_" + id
			g.inv[item] = int(g.inv.get(item, 0)) + 1
			lines.append(["Narrator", "Lin Feng is given %s: a ninth leaf of %s, painted by hand, to take the place of the least leaf he is dealt (Esc > Leaves)." % [str(Data.ITEMS[item].n), str(Phases.NAMES[str(f.leaf)]).to_lower()]])
	else:
		g.card_streak = 0
		rec["lost"] = int(rec.get("lost", 0)) + 1
		var pay := mini(int(g.stones), int(st.tea))
		g.stones = int(g.stones) - pay
		g.card_tea = int(g.card_tea) + pay
		lines.append([str(f.n), str(f.won)])
		lines.append(["Narrator", "The loser pours. Lin Feng pays %d spirit stones for the pot." % pay])
	g.cards[id] = rec
	return lines

## The painted leaves he has won, as leaves: [[master id, leaf], ...] in the masters' order.
static func painted(g) -> Array:
	var out: Array = []
	for id in MASTER_ORDER:
		if g.leaves.has(id):
			out.append([id, leaf(str(MASTERS[id].leaf), 9)])
	return out

## The painted leaf he carries to the table now (0 for none).
static func carried(g) -> int:
	var id := str(g.leaf)
	if id == "" or not g.leaves.has(id) or not MASTERS.has(id):
		return 0
	return leaf(str(MASTERS[id].leaf), 9)

## Masters beaten at least once.
static func beaten(g) -> int:
	var n := 0
	for id in MASTER_ORDER:
		if int(g.cards.get(id, {}).get("won", 0)) > 0:
			n += 1
	return n

static func summary(g) -> String:
	if int(g.card_hands) <= 0:
		return "He has never sat down to a hand of leaves."
	return "%d hands of leaves, %d won; %d of %d masters beaten; %d spirit stones of tea poured." % [int(g.card_hands), int(g.card_wins), beaten(g), MASTER_ORDER.size(), int(g.card_tea)]
