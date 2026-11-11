class_name Gamble
extends RefCounted
## Gambling (the Thundering Pots release): Old Du's mat, by the door of the Pear Garden stage in
## Qingshi.  Three games, staked in spirit stones, each as it has been played in the land for as long as
## there have been stones to lose:
##
##   Big and Small   three dice under a bowl.  Eleven to seventeen is big, four to ten is small, and
##                   three of a kind is the house's.  Even money; or call the triple, at thirty to one.
##   Fan-tan         a heap of white beads under a cup, counted off by fours with a bamboo stick.
##                   Stake on what is left over: one, two, three or four (none).  Three to one, less the
##                   house's twentieth.
##   The crickets    two fighting crickets in a clay pot, each with a name and a record.  The favourite
##                   pays less.  The house takes a twentieth of whatever is won.
##
## The house has an edge in all three, as a house does: nobody gets rich here, and "nine of ten who
## gamble lose" is said on the mat itself.  It is a way of spending an evening, a few feats, and a
## thing Yue Ling has opinions about.
##
## Nothing is random that cannot be played again: every throw is drawn from the journey's own count
## of throws (`Game.gamble_n`), so the same journey throws the same dice, the tests can check the odds
## over ten thousand rounds, and the bot (which does not gamble) loses nothing.

const DEALER := "dicer_du"
const ASK := "Old Du's mat: what will you play?"
const BET_ASK := "What will you stake it on?"
const STAKE_ASK := "And how much?"
## the stakes offered (the last is a tenth of what he carries)
const STAKES := [100, 1000, 10000]
## the house keeps this part of a win at fan-tan and the crickets
const CUT := 0.05
const TRIPLE_PAYS := 30

const GAMES := {
	"dice": {"n": "Big and Small", "desc": "Three dice under a bowl. Big is eleven to seventeen, small is four to ten, and three of a kind belongs to the house. Even money on big or small; thirty to one if you call the triple and it comes.",
		"bets": [["big", "Big (11 to 17)"], ["small", "Small (4 to 10)"], ["triple", "Three of a kind"]]},
	"fantan": {"n": "Fan-tan", "desc": "A double handful of white beads under a brass cup. Old Du counts them off by fours with a bamboo stick, slowly, so everybody can see. Stake on what is left at the end: one, two, three, or none, which is called four. Three to one, less a twentieth for the mat.",
		"bets": [["1", "One left"], ["2", "Two left"], ["3", "Three left"], ["4", "None left (four)"]]},
	"crickets": {"n": "The Crickets", "desc": "Two fighting crickets, weighed to the grain and tickled with a straw until they sing. The one that turns away has lost. Each has a record chalked on its pot; the favourite pays less. A twentieth of what is won is the mat's.",
		"bets": [["a", ""], ["b", ""]]},
}
const GAME_ORDER := ["dice", "fantan", "crickets"]

## the crickets of the season: names as their owners give them
const CRICKETS := ["Iron General", "Purple Head", "Old Bronze Tooth", "The Abbot", "Black Whirlwind", "Yellow Linen", "Crab-Shell Green", "Red Sand", "Plum-Blossom Wing", "The Magistrate",
	"Nine Victories", "Small Thunder", "Pot-Breaker", "Jade Hoe", "Never Sings", "The Widow's Boy"]

static func _u(n: int, salt: int) -> float:
	# (a hash of the throw's number: the same throw of the same journey is the same)
	var h := (n * 2654435761 + salt * 40503 + 977) & 0x7fffffff
	h = ((h ^ (h >> 15)) * 2246822519) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 3266489917) & 0x7fffffff
	return float(h ^ (h >> 16)) / 2147483648.0

static func _die(n: int, k: int) -> int:
	return 1 + mini(5, int(_u(n, 11 + k) * 6.0))

## What is on the mat for throw `n`, before anybody has staked anything: the dice that will fall, the
## beads under the cup, and the two crickets with their chances (the crickets can be looked at; the
## dice and the beads cannot).
static func deal(n: int) -> Dictionary:
	var a := int(_u(n, 31) * CRICKETS.size()) % CRICKETS.size()
	var b := (a + 1 + int(_u(n, 37) * (CRICKETS.size() - 1))) % CRICKETS.size()
	var sa := 3.0 + _u(n, 41) * 7.0
	var sb := 3.0 + _u(n, 43) * 7.0
	return {"dice": [_die(n, 0), _die(n, 1), _die(n, 2)], "beads": 37 + int(_u(n, 23) * 60.0),
		"a": CRICKETS[a], "b": CRICKETS[b], "pa": sa / (sa + sb), "win": "a" if _u(n, 47) < sa / (sa + sb) else "b"}

## What a stake on `bet` at `game` pays for each stone staked if it wins (on top of the stake).
static func pays(game: String, bet: String, d: Dictionary) -> float:
	match game:
		"dice":
			return float(TRIPLE_PAYS) if bet == "triple" else 1.0
		"fantan":
			return 3.0 * (1.0 - CUT)
		"crickets":
			var p := float(d.pa) if bet == "a" else 1.0 - float(d.pa)
			return (1.0 / p - 1.0) * (1.0 - CUT)
	return 0.0

## Whether `bet` at `game` wins on deal `d`.
static func wins(game: String, bet: String, d: Dictionary) -> bool:
	match game:
		"dice":
			var dc: Array = d.dice
			var sum := int(dc[0]) + int(dc[1]) + int(dc[2])
			var triple: bool = dc[0] == dc[1] and dc[1] == dc[2]
			if bet == "triple":
				return triple
			return not triple and ((bet == "big" and sum >= 11) or (bet == "small" and sum <= 10))
		"fantan":
			var left := int(d.beads) % 4
			return int(bet) == (4 if left == 0 else left)
		"crickets":
			return str(d.win) == bet
	return false

## The bets of a game as the mat shows them now: [[id, label, what a stone staked would win], ...].
static func bets(g, game: String) -> Array:
	var d := deal(int(g.gamble_n))
	var out: Array = []
	for b in GAMES[game].bets:
		var label := str(b[1])
		if game == "crickets":
			var nm := str(d[str(b[0])])
			var p := float(d.pa) if str(b[0]) == "a" else 1.0 - float(d.pa)
			label = "%s (%d wins in ten)" % [nm, int(round(p * 10.0))]
		out.append([str(b[0]), label, pays(game, str(b[0]), d)])
	return out

## The stakes that can be laid now.
static func stakes(g) -> Array:
	var out: Array = []
	for s in STAKES:
		if g.stones >= int(s):
			out.append(int(s))
	var tenth := int(g.stones / 10)
	if tenth > 0 and not out.has(tenth):
		out.append(tenth)
	return out

## One round: the stake is laid, the bowl is lifted.  Returns {"won", "pay" (stones won or lost),
## "lines" (what happened, to be said)}; the journey's count of throws moves on.
static func play(g, game: String, bet: String, stake: int) -> Dictionary:
	stake = clampi(stake, 0, int(g.stones))
	if stake <= 0 or not GAMES.has(game):
		return {"won": false, "pay": 0, "lines": []}
	var d := deal(int(g.gamble_n))
	g.gamble_n = int(g.gamble_n) + 1
	var won := wins(game, bet, d)
	var pay := int(floor(float(stake) * pays(game, bet, d))) if won else -stake
	g.stones += pay
	g.gamble_rounds += 1
	var lines: Array = []
	match game:
		"dice":
			var dc: Array = d.dice
			var sum := int(dc[0]) + int(dc[1]) + int(dc[2])
			var triple: bool = dc[0] == dc[1] and dc[1] == dc[2]
			lines.append(["Narrator", "Old Du lifts the bowl. %d, %d, %d: %s." % [int(dc[0]), int(dc[1]), int(dc[2]), ("three of a kind, and the house's" if triple else ("%d, big" % sum if sum >= 11 else "%d, small" % sum))]])
			if triple:
				g.gamble_triples += 1
		"fantan":
			var left := int(d.beads) % 4
			lines.append(["Narrator", "The cup comes off %d beads. The bamboo stick takes them away four at a time, four at a time, and at the end there %s left." % [int(d.beads), ["are none", "is one", "are two", "are three"][left]]])
		"crickets":
			var w := str(d[str(d.win)])
			var l := str(d["b" if str(d.win) == "a" else "a"])
			lines.append(["Narrator", "The straw comes away. %s and %s lock jaws, roll, break, and lock again; and then %s turns its back, and %s lifts its wings and sings." % [str(d.a), str(d.b), l, w]])
	if won:
		g.gamble_won += pay
		g.gamble_wins += 1
		g.gamble_streak += 1
		g.gamble_best = maxi(int(g.gamble_best), pay)
		lines.append([name_of(), WIN_LINES[int(g.gamble_rounds) % WIN_LINES.size()] % pay])
		g.toast("+%d spirit stones" % pay)
	else:
		g.gamble_lost += stake
		g.gamble_streak = 0
		lines.append([name_of(), LOSE_LINES[int(g.gamble_rounds) % LOSE_LINES.size()]])
		g.toast("-%d spirit stones" % stake)
	# Yue Ling has opinions, now and then
	if g.companion and int(g.gamble_rounds) % 4 == 1:
		lines.append(["Yue Ling", YUE_LINES[int(g.gamble_rounds / 4) % YUE_LINES.size()]])
	g.note("At Old Du's mat: %s, %s %d spirit stones" % [str(GAMES[game].n), "won" if won else "lost", absi(pay)])
	return {"won": won, "pay": pay, "lines": lines}

static func name_of() -> String:
	return "Old Du of the Three Dice"

const WIN_LINES := ["%d to the gentleman. I pay with a smile; it is the only way to get them back.", "%d. Take it, take it. The stones know the way home to my mat; they have walked it before.",
	"There: %d. You have the luck today. Luck is a guest, mind. It does not unpack.", "%d, and well called. I shall tell everybody. That is not kindness; a winner is the best sign a mat can hang out."]
const LOSE_LINES := ["The mat thanks you. Nine of ten who gamble lose; I have it painted over the door, and nobody reads it.", "Ah. Nearly. Nearly is my best customer.",
	"Mine, I am afraid. Do not look so. A cultivator who has never lost anything has never owned anything.", "The house's. It is nothing personal; the house has a wife and four crickets to feed."]
const YUE_LINES := ["I am not saying anything. I want you to notice how much I am not saying.", "Granny Wen says the only man who wins at a mat is the one who owns the mat. Granny Wen once won a pig at this mat. She does not mention the pig.",
	"The cricket on the left is frightened, Lin Feng. Can you not hear it? ...No. I suppose that is the point of a gambling den: nobody listens.", "One more. I said that for you, to save time."]

## What the mat's page of the journey says.
static func summary(g) -> String:
	if int(g.gamble_rounds) == 0:
		return "Never sat down at Old Du's mat."
	return "%d rounds at Old Du's mat, %d won: %d spirit stones won and %d lost; the best single win %d." % [int(g.gamble_rounds), int(g.gamble_wins), int(g.gamble_won), int(g.gamble_lost), int(g.gamble_best)]
