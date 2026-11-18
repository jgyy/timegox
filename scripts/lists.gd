class_name Lists
extends RefCounted
## The lists (the Red Seal release): tournaments he can enter, and what is said across a ring.
##
## A **meet** (`MEETS`) is called at the counter of a town: eight entrants, three bouts (`ROUNDS`), each a
## battle fought **alone** (Yue Ling is at the rail, and says so) against one named rival (`RIVALS`), who
## is met at his own level on the day and a little over.  The lists admit nobody without the papers the
## meet asks for (seals.gd: `papers`, and for the Meet of the Eight Arms a paper of a weapon's Dao), and
## the fee is paid once.
##
## **Losing a bout is not the infirmary**: its outcome is `"out"` (Battle._out): he is out of the meet at
## the place that round is worth, nobody is carried home, no death is counted and nothing is taken but
## the fee he paid to enter.  Winning all three is first place.  Either way the meet is *finished*, a purse
## is paid by place, by how the crowd took to him and by the papers he holds, and a step of kind `"meet"`
## is done however it went.  A meet is called again every `AGAIN` days for whoever wants a better place.
##
## **Words** (`WORDS`): in a bout of the lists the battle menu has a fifth line, where Flee was a fourth.  One thing may be said a
## turn, each thing once a bout, and saying it does not cost the turn.  What it does depends on who it
## is said to (`TEMPERS`: a rival is hot, proud, cold or merry): a needle makes a hot man swing wide and
## a cold one smile; praise disarms the proud and is wasted on the merry; a boast puts weight in his own
## blow and must be made good (`settle`: a boast that wins is the crowd's, one that loses halves the
## purse).  `word` is pure, and `best_word` is what the bot says.  The rival talks too (`jeers`), and has
## something to say when it is over; what was said across the ring comes back by post (mail.gd).
##
## Nothing here is random and nothing a meet shuts is something another step needs.

## The step that opens the lists, and how many days pass before a meet is called again.
const OPEN := "s_p39_home"
const AGAIN := 30
## The bouts of a meet: how far over his own level each rival is met, how much of a single foe's health and
## blow he has (he fights alone: the lists are not a pack), and the place a loss in that round is worth.
const ROUNDS := [
	{"n": "the round of eight", "over": 0, "mult": 5.0, "atk": 1.15, "place": 8},
	{"n": "the round of four", "over": 1, "mult": 6.5, "atk": 1.25, "place": 4},
	{"n": "the last bout", "over": 3, "mult": 3.2, "atk": 1.2, "place": 2},
]
## what a place pays of a meet's purse
const SHARE := {1: 1.0, 2: 0.5, 4: 0.25, 8: 0.1}
const PLACES := {1: "first", 2: "second", 4: "among the last four", 8: "among the eight"}
## how far the crowd can lean, and what each step of it is worth of the purse
const CROWD_MAX := 3
const CROWD_K := 0.08

const MEETS := {
	"outer": {"n": "The Lists of the Outer Court", "office": "treasurer", "area": "sect", "papers": 1, "of": "",
		"fee": 1500, "purse": 12000, "rivals": ["list_meng", "list_bai_lu", "list_han_yue"],
		"desc": "Eight names off the Roll of the Outer Court, drawn from a rice bowl, in the practice yard with the whole kitchen watching. Nobody has ever been hurt in it who did not deserve to be."},
	"arms": {"n": "The Meet of the Eight Arms", "office": "warden_yanggu", "area": "yanggu", "papers": 1, "of": "arm",
		"fee": 3000, "purse": 24000, "rivals": ["list_tong", "list_yue_nu", "deng_xi"],
		"desc": "Held on the lantern green of the Dawn Market since before the nine days of noon. Every entrant shows a paper of the weapon in his hand. The lantern-makers bet on it, and have opinions."},
	"schools": {"n": "The Meet of the Hundred Schools", "office": "guild_tushan", "area": "tushan", "papers": 3, "of": "",
		"fee": 5000, "purse": 40000, "rivals": ["list_kong", "hui_shi", "gongsun_long"],
		"desc": "On the casting floor of Tushan, between the pits, once the bronze is poured. Every school that has a name sends somebody to defend it. The casters come for the arguments and stay for the blows."},
}
const ORDER := ["outer", "arms", "schools"]

## The rivals: what they are like across a ring (`temper`), what they say at the start of the first, third
## and fifth rounds (`jeers`), and when it is over (`won`: he beat them; `lost`: they beat him).
const RIVALS := {
	"list_meng": {"temper": "hot", "jeers": ["Three years sweeping and they let you in the bowl? I drew you. I asked to draw you.", "Is that the form? I had heard it was better. I had heard a great deal.", "Stand still and I shall explain where you went wrong!"],
		"won": "I talked through the whole of it, did I not. Hall Master Du says I would be further on if I talked less. He says it often.", "lost": "There! Write that on the Roll. Write it large. No. Write it the usual size. I find I do not want it large."},
	"list_bai_lu": {"temper": "cold", "jeers": ["Good morning, Junior Brother.", "You are leaning on your front foot.", "Still leaning."],
		"won": "You stopped leaning in the fourth exchange. I wondered whether you would. Thank you for the bout.", "lost": "You hurried. I do not hurry. That is all that happened here; do not make a story of it."},
	"list_han_yue": {"temper": "proud", "jeers": ["Six years first on the Roll. I have bowed to nobody I had not measured. I have measured you.", "The Elder is watching. He has never watched one of mine before. I notice that.", "I am not going to be the step you stood on."],
		"won": "Then it is measured. First on the Roll for six years, and second from today. I shall bow now. I find I know how.", "lost": "Measured, and found a little short. You will be told it was close. It was not. Come back in a month."},
	"list_tong": {"temper": "merry", "jeers": ["A cultivator! Wonderful. I teach spear to dyers' sons. Mind the green, they have just raked it.", "Ha! You see that? That is the one I cannot get the dyers' sons to do.", "If I win I shall never hear the end of it. If you win, neither shall you."],
		"won": "Beaten by a paper with legs! No, no, well fought. Come and eat. The lantern-makers will want to tell you what you did wrong.", "lost": "Well, well. A spear-master of a market town. I shall dine on it for a year. Do not look so stricken; you were very nearly good."},
	"list_yue_nu": {"temper": "cold", "jeers": ["I learned from a white ape in a bamboo wood. It did not talk either.", "The door, and then the tiger. You are still at the door.", "..."],
		"won": "The ape would have liked that. It struck me with a bamboo twig for three years before I could say as much.", "lost": "It is like opening a door, and like a tiger. You were all tiger. Go and find where the door is."},
	"deng_xi": {"temper": "merry", "jeers": ["I can prove you have won already. I can also prove you have lost. Which would you like? The second is cheaper.", "My client says that was a foul. I am my client. I withdraw it; it was beautifully done.", "Both things can be allowed. That is my whole teaching, and it has never once got me out of the way of a blow."],
		"won": "A just verdict. I shall appeal it, naturally, and argue the other side, and lose. Both things can be allowed. A coat for the lesson?", "lost": "There. And had you won, I had the speech ready for that too. It was the better speech. I am sorry you will not hear it."},
	"list_kong": {"temper": "proud", "jeers": ["I am Kong Chuan, of the sixth generation from the Master. I am here to rectify a name. Yours, I think.", "A gentleman does not contend. Where he must, it is in archery, and he bows before and after. I have bowed.", "The Master said: is it not a pleasure. He was not being struck at the time."],
		"won": "Then the name was right and I had it wrong. It is a pleasure to learn that. I am told it is. I shall know by evening.", "lost": "The name is rectified. Be what your paper says you are. It is harder than winning it, and I do not always manage."},
	"hui_shi": {"temper": "merry", "jeers": ["I have five carts of books and a friend who laughs at all of them. Shall we see which of us the sun sets on at noon?", "An egg has feathers. You will see what I mean when it hatches. Mind your left.", "Take half of a stick each day and ten thousand generations will not see the end of it. This bout, now, I am less sure of."],
		"won": "Oh, well struck. Zhuang Zhou will be unbearable. He says I lean on a tree and mutter. I shall go and lean on one, and tell it.", "lost": "There: the south has no limit and has a limit. You found the limit. Come and argue it over wine. I only ever fight to get to the wine."},
	"gongsun_long": {"temper": "cold", "jeers": ["A white horse is not a horse. A certified swordsman is not a swordsman. I shall show you the second; the first took me a book.", "Hard, and white. Two things. You strike at the stone, and there is no stone there.", "What your paper names and what stands here are not one thing. I am waiting to meet either."],
		"won": "Then the name and the thing were one, this once. I had said it could not be. I shall have to write another chapter. Do not look pleased; I dislike writing.", "lost": "You brought the paper into the ring. The man who earned it stayed outside. Next time, send him in, and leave the horse."},
}

## What can be said across a ring: the name on the menu, and what it is.
const WORDS := {
	"needle": {"n": "Needle him", "desc": "Say the thing about his form that he hopes nobody has noticed."},
	"boast": {"n": "Name the blow", "desc": "Tell the crowd what is about to happen. It puts weight in the arm, and it must be made good."},
	"praise": {"n": "Praise him", "desc": "Say the true thing about how good he is, aloud, in front of everybody."},
}
const WORD_ORDER := ["needle", "boast", "praise"]
## What each does to each temper: `atk` what it makes of the rival's blow, `open` of what a blow does to him,
## `mine` of Lin Feng's own blow, `crowd` how the rail takes it, and what is said back.
const TEMPERS := {
	"hot": {
		"needle": {"atk": 1.15, "open": 1.3, "mine": 1.0, "crowd": 1, "say": "%s goes red to the ears, and comes on swinging wide."},
		"boast": {"atk": 1.1, "open": 1.05, "mine": 1.12, "crowd": 0, "say": "%s shouts something back that the rail cannot make out, and neither can he."},
		"praise": {"atk": 1.0, "open": 1.0, "mine": 1.0, "crowd": 0, "say": "%s takes it for mockery, and is not sure, and it troubles him."}},
	"proud": {
		"needle": {"atk": 1.1, "open": 0.95, "mine": 1.0, "crowd": -1, "say": "%s does not answer. The rail does not like it said to him, and lets it be known."},
		"boast": {"atk": 1.05, "open": 1.0, "mine": 1.12, "crowd": 0, "say": "%s inclines his head a finger's width, as to somebody who has named his own measure."},
		"praise": {"atk": 0.85, "open": 1.15, "mine": 1.0, "crowd": 1, "say": "%s had an answer ready for anything but that. His guard comes down a hand while he looks for one."}},
	"cold": {
		"needle": {"atk": 1.0, "open": 1.0, "mine": 0.95, "crowd": -1, "say": "%s smiles a little. It was heard, and weighed, and it weighed nothing. Lin Feng's own arm is the heavier for having said it."},
		"boast": {"atk": 1.0, "open": 1.12, "mine": 1.12, "crowd": 1, "say": "%s looks, for the first time, at the place that was named. The rail leans in."},
		"praise": {"atk": 0.95, "open": 1.0, "mine": 1.0, "crowd": 0, "say": "%s says: yes. It is not vanity. It was simply correct, and has been filed."}},
	"merry": {
		"needle": {"atk": 0.95, "open": 1.0, "mine": 1.0, "crowd": 1, "say": "%s roars with laughter, repeats it to the rail, and improves it."},
		"boast": {"atk": 1.0, "open": 1.0, "mine": 1.12, "crowd": 1, "say": "%s claps, and offers odds on it to the front row."},
		"praise": {"atk": 1.05, "open": 0.95, "mine": 1.0, "crowd": 0, "say": "%s says he knows, he knows, and is so pleased that he gets better."}},
}
## what he says: one line a word (told through Voice like anything else he says)
const SAID := {
	"needle": "Lin Feng says, pleasantly, where the other's weight is, and has been since the bow.",
	"boast": "Lin Feng says to the rail which blow it will be, and from which side.",
	"praise": "Lin Feng says, loud enough for the back row, the best true thing there is to say of the other's hands.",
}
## Yue Ling at the rail, at the second round of a bout
const RAIL := ["Yue Ling, from the rail: \"His left! No. His other left. I shall be quiet.\"",
	"Yue Ling, from the rail: \"I am not allowed in. I asked. I asked twice.\"",
	"Yue Ling, from the rail: \"You are doing the thing with your shoulder. I say this with love.\""]
## what a boast unpaid makes of the purse
const BOAST_LOST := 0.5

# ---------------------------------------------------------------- the meets
static func open(g) -> bool:
	return g.done(OPEN)

## The meet called at the counter of `office` ("" if none).
static func at(office: String) -> String:
	for id in ORDER:
		if str(MEETS[id].office) == office:
			return id
	return ""

## Whether `id` is one of the people of the lists.
static func is_rival(id: String) -> bool:
	return RIVALS.has(id)

## Where he stands in meet `id`: {} (never entered), or {round, day, place, crowd, best, times}.
static func state(g, id: String) -> Dictionary:
	return g.meets.get(id, {})

## Whether he is in meet `id` now (entered, and neither out nor first).
static func entered(g, id: String) -> bool:
	return g.meets.has(id) and int(g.meets[id].place) == 0

## Whether meet `id` has been fought to an end at least once; and the best place he has had in it.
static func finished(g, id: String) -> bool:
	return g.meets.has(id) and int(g.meets[id].best) > 0

static func best(g, id: String) -> int:
	return int(g.meets[id].best) if g.meets.has(id) else 0

## How many meets he has fought to an end; and how many he has been first in.
static func fought(g) -> int:
	var n := 0
	for id in g.meets:
		if int(g.meets[id].best) > 0:
			n += 1
	return n

static func firsts(g) -> int:
	var n := 0
	for id in g.meets:
		if int(g.meets[id].best) == 1:
			n += 1
	return n

## Why he cannot enter meet `id` now ("" if he can).
static func blocked(g, id: String) -> String:
	var m: Dictionary = MEETS[id]
	if not open(g):
		return "No meet has been called."
	if entered(g, id):
		return "His name is on the board already."
	if g.meets.has(id) and int(g.day) - int(g.meets[id].day) < AGAIN:
		return "The meet is over for this month. It is called again in %d days." % (AGAIN - (int(g.day) - int(g.meets[id].day)))
	if Crime.shut(g, str(m.area), "lists") != "":
		return Crime.shut(g, str(m.area), "lists")
	if Seals.count(g) < int(m.papers):
		return "The lists admit nobody without %s of the Hall of Seals (he holds %d)." % ["a paper" if int(m.papers) == 1 else "%d papers" % int(m.papers), Seals.count(g)]
	if str(m.of) != "" and Seals.count_of(g, str(m.of)) < 1:
		return "This meet wants a paper of the Dao of a weapon."
	if int(g.stones) < int(m.fee):
		return "The fee is %d spirit stones." % int(m.fee)
	return ""

## His name goes on the board of meet `id`.
static func enter(g, id: String) -> bool:
	if blocked(g, id) != "":
		return false
	g.stones -= int(MEETS[id].fee)
	var was: Dictionary = g.meets.get(id, {})
	g.meets[id] = {"round": 0, "day": int(g.day), "place": 0, "crowd": 0, "best": int(was.get("best", 0)), "times": int(was.get("times", 0)) + 1, "said": was.get("said", {})}
	g.note("Entered %s" % str(MEETS[id].n))
	return true

## The rival of his next bout in meet `id` ("" if he is not in it).
static func rival(g, id: String) -> String:
	if not entered(g, id):
		return ""
	return str(MEETS[id].rivals[int(g.meets[id].round)])

## The foe handed to the battle for round `r` of meet `id`.
static func foe(g, id: String, r: int) -> Dictionary:
	var rd: Dictionary = ROUNDS[r]
	return {"id": str(MEETS[id].rivals[r]), "lv": int(g.level) + int(rd.over), "mult": float(rd.mult), "atk": float(rd.atk)}

## What place `p` of meet `id` pays somebody the crowd leans `crowd` towards, who holds his papers.
static func purse(g, id: String, p: int, crowd: int, boast_lost: bool = false) -> int:
	var k := float(SHARE.get(p, 0.0)) * (1.0 + CROWD_K * float(clampi(crowd, -CROWD_MAX, CROWD_MAX))) * Seals.mod(g, "purse")
	if boast_lost:
		k *= BOAST_LOST
	return int(round(float(MEETS[id].purse) * k))

## A bout of meet `id` is over: `won`, how the rail leaned by the end of it (`crowd`), and what was said in it
## (`said`: word -> true).  Returns the lines told of it.
static func bout_over(g, id: String, won: bool, crowd: int = 0, said: Dictionary = {}) -> Array:
	if not entered(g, id):
		return []
	var st: Dictionary = g.meets[id]
	var r := int(st.round)
	var rid := str(MEETS[id].rivals[r])
	var lines: Array = []
	st.crowd = clampi(int(st.crowd) + settle(crowd, said, won), -CROWD_MAX, CROWD_MAX)
	for w in said:
		st.said[rid] = str(w)
		g.said_to[rid] = str(w)
		g.words_said = int(g.words_said) + 1
	g.bouts = int(g.bouts) + 1
	lines.append([str(Data.ENEMIES[rid].n), str(RIVALS[rid].won if won else RIVALS[rid].lost)])
	var place := 0
	if won:
		g.bouts_won = int(g.bouts_won) + 1
		st.round = r + 1
		if r + 1 >= ROUNDS.size():
			place = 1
	else:
		place = int(ROUNDS[r].place)
	if place > 0:
		var pay := purse(g, id, place, int(st.crowd), not won and said.has("boast"))
		st.place = place
		st.best = place if int(st.best) == 0 else mini(int(st.best), place)
		st.day = int(g.day)
		g.stones += pay
		g.purses = int(g.purses) + pay
		g.weal_n += 1
		g.note("%s: %s (%d spirit stones)" % [str(MEETS[id].n), str(PLACES[place]), pay])
		lines.append(["Narrator", "%s is over for Lin Feng: %s of eight. The purse is counted out on the board, %d spirit stones%s." % [str(MEETS[id].n), str(PLACES[place]), pay, crowd_text(int(st.crowd))]])
		if not won and said.has("boast"):
			lines.append(["Narrator", "He had told the rail which blow it would be. The rail remembers, and the purse is the lighter by half for it."])
	else:
		lines.append(["Narrator", "His name is moved a column to the right on the board. %s is next: %s." % [str(Data.ENEMIES[str(MEETS[id].rivals[r + 1])].n), str(ROUNDS[r + 1].n)]])
	return lines

static func crowd_text(c: int) -> String:
	if c >= 2:
		return ", and the rail threw in more"
	if c <= -2:
		return ", and the rail kept its hands in its sleeves"
	return ""

# ---------------------------------------------------------------- words
static func temper(rid: String) -> String:
	return str(RIVALS.get(rid, {}).get("temper", "cold"))

## What saying `w` to rival `rid` does: {atk, open, mine, crowd, say}.
static func word(rid: String, w: String) -> Dictionary:
	return TEMPERS[temper(rid)][w]

## How the rail has leaned by the end of a bout in which `said` was said and `crowd` came of it: a boast made
## good is the crowd's (one more), a boast that lost is held against him (two less).
static func settle(crowd: int, said: Dictionary, won: bool) -> int:
	if said.has("boast"):
		return crowd + (1 if won else -2)
	return crowd

## The one thing worth saying to `rid` (what the bot says): whatever opens him widest for what it costs.
static func best_word(rid: String) -> String:
	var bw := ""
	var bv := 1.0
	for w in WORD_ORDER:
		var e: Dictionary = word(rid, w)
		var v := float(e.open) * float(e.mine) / float(e.atk)
		if v > bv + 0.001:
			bv = v
			bw = w
	return bw

## What rival `rid` says as round `round_no` of a bout begins ("" on the even rounds, and when he has run out).
static func jeer(rid: String, round_no: int) -> String:
	if round_no % 2 == 0 or not RIVALS.has(rid):
		return ""
	var k := (round_no - 1) / 2
	var js: Array = RIVALS[rid].jeers
	return str(js[k]) if k < js.size() else ""

## The page of the menu: one line a meet.
static func text(g) -> String:
	var out: Array = []
	for id in ORDER:
		var m: Dictionary = MEETS[id]
		if not g.meets.has(id):
			out.append("%s: not entered" % str(m.n))
		elif entered(g, id):
			out.append("%s: in it, %s next (%s)" % [str(m.n), str(Data.ENEMIES[rival(g, id)].n), str(ROUNDS[int(g.meets[id].round)].n)])
		else:
			out.append("%s: %s of eight" % [str(m.n), str(PLACES[best(g, id)])])
	out.append("%d bouts, %d won; %d things said across a ring; %d spirit stones in purses" % [int(g.bouts), int(g.bouts_won), int(g.words_said), int(g.purses)])
	return "\n".join(out)

## What the ending tells of it ("" if he never stood in a ring).
static func epilogue(g) -> String:
	if fought(g) == 0:
		return ""
	if firsts(g) >= 3:
		return "It is told that Lin Feng was first in every meet that was called in his day, and that the board at Tushan still has his name at the top, where nobody has liked to wipe it."
	if firsts(g) == 0:
		return "It is told that Lin Feng entered the lists and was never first in them, and that he went back the next month, which the towns thought the better story."
	return "It is told that Lin Feng was first in %s of the three meets, and could tell anybody who asked exactly how he had lost the other%s." % ["one" if firsts(g) == 1 else "two", "s" if firsts(g) == 1 else ""]
