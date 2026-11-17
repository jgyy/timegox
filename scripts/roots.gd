class_name Roots
extends RefCounted
## The spirit root (the Uncarved Block release).  Every child who climbs the nine hundred and ninety-nine
## steps lays a hand on the testing stone by the gate, and the stone says which of the five phases the
## qi will take in them: one, or two, or three, or four, or all five.
##
##  * **The fewer, the quicker.**  One phase is a Heavenly Root: nothing is spilled, and the sect has
##    waited a generation for it.  Three is a True Root, the ordinary sort, and the number every other
##    is measured against (every number here is 1 for it: the bot's journey and every older test are
##    a True Root's).  Five is the Whole Round, which the roll calls a waste root: the qi is poured
##    five ways and each cup is a fifth full.
##  * **And the more, the later.**  A great vessel is a long time finishing.  Past `BLOOM` realms the
##    round closes: a root of four or five phases learns faster than it did, and a blow of any phase
##    finds no gap in it.  One phase stays what it always was: a blade, with a flat.
##  * **Everybody has an opinion.**  The stone's word is on the roll, and the roll is read: the people
##    of the towns answer it by what they are (`said`: nine kinds of witness, manners.gd, five roots),
##    the people of the story who have known him longest each have a word of their own (`NAMED`), a
##    few conversations of the story are told differently (`AT`), and the sect's own counters and its
##    stipend are kinder to a root it is proud of (`mod`: "price", "stipend").
##
## The root is chosen when the hero is made (create.gd: how many phases, and which leads; the rest
## follow round the generating order, wood to fire to earth to thunder to water) and never changes:
## nothing in the land washes a root.  It is kept in `Game.hero` ("root": 1..5, "root_el"); a hero made
## before this release has a True Root led by wood.  Everything here is pure.
##
## The stone measures the five phases only.  The nine branches of the Nine Heavens root (Part XII)
## woke later and the stone has no face for them; the dark and the plain blow belong to no phase.

## the generating round: each feeds the next (what the old books call metal, the sect calls thunder:
## the struck bell)
const ELEMS := ["wood", "fire", "earth", "thunder", "water"]
const ELEM_N := {"wood": "Wood", "fire": "Fire", "earth": "Earth", "thunder": "Thunder", "water": "Water"}
## what a root of so many phases is called on the roll, and in the street
const KINDS := {
	1: {"n": "Heavenly Root", "street": "a Heavenly Root", "col": Color("ffe9a0"),
		"desc": "One phase and nothing else. The stone lights in a single colour to the top. Nothing is spilled: every breath goes the one way. The sect has such a child once in a generation, and tells the other sects."},
	2: {"n": "Twin Root", "street": "a Twin Root", "col": Color("b8e0ff"),
		"desc": "Two phases, one feeding the other. The stone lights in two colours that do not quarrel. An inner disciple's root: quick, and with somewhere to turn when the first way is shut."},
	3: {"n": "True Root", "street": "a True Root", "col": Color("c8e8c0"),
		"desc": "Three phases. The stone lights in three bands, none of them to the top. It is what most of the roll has. Nobody is sent down for it and nobody is sent for; it is given a broom, and time."},
	4: {"n": "Mixed Root", "street": "a mixed root", "col": Color("d8c8a8"),
		"desc": "Four phases, each thinned by the other three. The stone lights low and muddy. The sect keeps such a child if there is a bed. Slow at first; the old books add, in a smaller hand, that it is slow to stop."},
	5: {"n": "Root of the Whole Round", "street": "a waste root", "col": Color("e0d8f0"),
		"desc": "All five phases. The stone barely lights at all, in every colour at once. The roll calls it a waste root: the qi is poured five ways. The round is also whole, with no phase missing, and nobody has yet found out what that is for."},
}
## realms (Data.REALMS) before a wide root has grown into itself
const BLOOM := 6
## by number of phases (index 0 is one phase).  exp: what is learned from what falls and from sitting;
## own: techniques of a phase in the root; other: techniques of a phase the root lacks; taken: the
## harm of every blow; price: what the sect's own counters ask; stipend: what the roll sends.
const MODS := {
	"exp": [1.2, 1.1, 1.0, 0.94, 0.88],
	"own": [1.18, 1.1, 1.0, 1.0, 1.0],
	"other": [0.92, 0.96, 1.0, 1.0, 1.0],
	"taken": [1.05, 1.02, 1.0, 0.98, 0.96],
	"price": [0.9, 0.95, 1.0, 1.04, 1.08],
	"stipend": [1.3, 1.15, 1.0, 0.9, 0.8],
}
## ... and once the round has closed (past BLOOM realms)
const LATE := {
	"exp": [1.2, 1.1, 1.0, 1.05, 1.12],
	"taken": [1.05, 1.02, 1.0, 0.95, 0.9],
}

# ---------------------------------------------------------------- what he was measured as
## How many phases (1..5).
static func count(g) -> int:
	return clampi(int(g.hero.get("root", 3)), 1, 5)

## The phase that leads.
static func lead(g) -> String:
	var e := str(g.hero.get("root_el", "wood"))
	return e if ELEMS.has(e) else "wood"

## The phases of a root of `n` led by `first`: round the generating order.
static func elems_of(n: int, first: String) -> Array:
	var out: Array = []
	var i := maxi(0, ELEMS.find(first))
	for k in clampi(n, 1, 5):
		out.append(ELEMS[(i + k) % ELEMS.size()])
	return out

static func elems(g) -> Array:
	return elems_of(count(g), lead(g))

static func has(g, elem: String) -> bool:
	return elems(g).has(elem)

static func kind_name(g) -> String:
	return str(KINDS[count(g)].n)

## "a Twin Root of Fire and Earth".
static func title_of(n: int, first: String) -> String:
	var ns: Array = []
	for e in elems_of(n, first):
		ns.append(str(ELEM_N[e]))
	if n >= 5:
		return str(KINDS[5].n)
	var last := str(ns.pop_back())
	return "%s of %s" % [str(KINDS[n].n), last if ns.is_empty() else ", ".join(ns) + " and " + last]

static func title(g) -> String:
	return title_of(count(g), lead(g))

## Whether the round has closed in him.
static func bloomed(g) -> bool:
	return int(g.realm()) >= BLOOM

# ---------------------------------------------------------------- what it does
## A number of the root (1 for a True Root, always).
static func mod(g, key: String) -> float:
	var n := count(g)
	if n == 3 or not MODS.has(key):
		return 1.0
	if bloomed(g) and LATE.has(key):
		return float(LATE[key][n - 1])
	return float(MODS[key][n - 1])

## How much harder (or softer) a technique of phase `elem` lands for the root.
static func power(g, elem: String) -> float:
	if not ELEMS.has(elem):
		return 1.0
	return mod(g, "own") if has(g, elem) else mod(g, "other")

## What the page says of it.
static func text(g) -> String:
	var n := count(g)
	var out := str(KINDS[n].desc)
	if n == 3:
		return out + "\n\nIt changes nothing: it is the root the land is measured by."
	var bits: Array = []
	for k in ["exp", "own", "other", "taken", "price", "stipend"]:
		var v := mod(g, k)
		if is_equal_approx(v, 1.0):
			continue
		var pc := int(round(absf(v - 1.0) * 100.0))
		match k:
			"exp":
				bits.append("learns %d%% %s" % [pc, "faster" if v > 1.0 else "slower"])
			"own":
				bits.append("its own phases strike %d%% harder" % pc)
			"other":
				bits.append("the phases it lacks strike %d%% softer" % pc)
			"taken":
				bits.append("every blow lands %d%% %s on him" % [pc, "heavier" if v > 1.0 else "lighter"])
			"price":
				bits.append("the sect's counters ask %d%% %s" % [pc, "less" if v < 1.0 else "more"])
			"stipend":
				bits.append("the roll sends %d%% %s" % [pc, "more" if v > 1.0 else "less"])
	out += "\n\nNow: " + "; ".join(bits) + "."
	if n >= 4:
		out += " The round has closed." if bloomed(g) else " (A wide root is slow to close: at %s it will have.)" % str(Data.REALMS[BLOOM])
	return out

# ---------------------------------------------------------------- what people make of it
## What a witness of each kind (manners.gd) says to a root of each number ("%s" is how he is addressed),
## and what they do with their hands as they say it.
const SAID := {
	"hand": [
		["One colour, clear to the top, they say. My cousin carried water at the sect the year you were measured. He says the elders stood up. All of them. %s, I have never seen an elder stand up for anything."],
		["Two phases, is it? That is a good root. A root that gets a room of its own and meat on feast days. I do not say it to flatter. I say it because I carried the meat."],
		["Three. Same as my sister's boy, and he is a clerk at Cloudfoot now and has his health. Nobody ever stopped in the road to look at a True Root, %s. It is restful. You will find that."],
		["Four, they told us. And yet here you are, with a sword on. I had a mule like that. Everybody said sell it. It was the only one that got up the pass in the snow."],
		["A waste root. That is the word on the roll, %s, I did not choose it. Five ways at once. I was sorry when I heard. Then I heard the rest of what you have done, and I stopped knowing what to be."],
	],
	"kid": [
		["Is it true the stone went all GOLD? All of it? Did it hurt? My brother says if I had one colour I would not have to learn my characters. I would STILL not have to. Is that true?"],
		["Two colours! Which two? I would have red and the thunder one. You cannot choose? Who chooses? ...Nobody? That is a stupid way to do it."],
		["My mother says you have the ordinary kind. Three. I said that cannot be right, you can FLY. She said the ordinary kind can fly if it sweeps long enough. I do not want to sweep."],
		["Four is more than three. So you have MORE than the others. Why does everybody say it like it is less? Grown people cannot count."],
		["You got ALL of them! Five! I only have two marbles and Ah Bao has five and he always wins. ...They said it is the worst one? Then they are playing it wrong."],
	],
	"giant": [
		["One phase. Among us a child that can only lift is a lifter, and nobody asks it to weave. Your people are surprised by this every generation. It is a long way down to you, %s, but the news still arrives."],
		["Two phases, little cousin. A thing with two legs stands. We have always thought your elders made too much of one and too little of two. But we think you make too much of most things."],
		["Three, they say. Three stones make a hearth: two will not hold a pot. I do not know why your sect gives such a root a broom. I would give it a pot."],
		["Four phases. A table. You could set a meal on a root like that, %s. Your stone-readers want everything to be a spear. Some things are for putting other things on."],
		["All five, and they called it waste. Hah. Down there you measure what a thing is quickest at. Up here we ask what it can carry. The whole round carries the whole round. Sit down. I want to look at you."],
	],
	"elder": [
		["A Heavenly Root. I saw one other, when I was a boy: a girl, water only. She was a Golden Core at nineteen and dead at thirty, of never once having been bad at anything. Mind that, %s."],
		["Two phases. In my day they said: one to go by, one to come back by. It is the root I would have asked for. I was not asked. I got my knees instead, and those are going."],
		["A True Root, like the rest of us who had one at all. You will hear it called ordinary. I have been ordinary for eighty years, %s, and I recommend it. It keeps."],
		["Four. They nearly sent you down, I expect. They nearly sent my brother down for the same. He outlived every one of the bright ones and was still splitting his own wood at ninety."],
		["The whole round. Waste, they wrote. I am old enough to remember when the roll had another word for it, in the margin, before somebody tidied the margin away. It said: wait."],
	],
	"watch": [
		["Heavenly Root. We were told to salute, and to keep the petitioners off you. I have saluted. The petitioners I cannot do much about; there is one behind you now. Good day, %s."],
		["Twin Root, by the roll. That is officer stock, in the sect's way of reckoning. Pass, %s. I only stand at a gate. I know which side of it the roll would have put me."],
		["True Root. Same as the men on this gate, the two of us that were tested. It will do. Nobody writes songs about the third watch, and the third watch is why there is a town here in the morning."],
		["Mixed Root. I will be plain, %s: when the bill came round with your name I expected less. I have stopped expecting things off a roll. It is the same with recruits."],
		["Waste root, it says. We had orders once to turn such children back at the foot of the steps, to save them the climb. I turned back a good many. I think about that now, when I see you go by."],
	],
	"trade": [
		["For a Heavenly Root? Take it, take it. No, I will not hear of a price, the whole street will know by noon that you stopped at my stall. ...Well. If you insist. But I shall tell them you did not."],
		["A Twin Root gets the good scale, %s, the one I keep under the cloth. I am not ashamed of it. A merchant is a man who knows what things are, and tells the customer after."],
		["True Root, same as the trade. We have a saying: three strings to a purse, and it shuts. I will serve you as I serve anybody, which is honestly, and after whoever was here first."],
		["A mixed root. I will tell you what I tell my boy: mixed goods sell slow and sell steady. It is the fine single wares that sit on the shelf waiting for a prince who does not come."],
		["They say a waste root, and they say it of the one who cleared the road my stock comes in by. I have been trying to price that all morning, %s. I cannot. Have a pear."],
	],
	"learned": [
		["One phase. The Classic says the highest good is like water; it does not say like water only. But you will have had better readers than me tell you what you are, %s, and none of them will have asked."],
		["Twin Root. Yin and yang are two. Heaven and earth are two. A couplet is two lines. I have never understood why the sects prize one above it. One line is not a poem; it is a remark."],
		["A True Root. Three: heaven, earth and whoever stands between them. You are the commonest character in the dictionary, %s, and it is the one every other is written with."],
		["Four phases. The scholars call it a mixed root as one says a mixed metaphor. But I have read the old registers, and the long lives are all in that column. Nobody quotes a register."],
		["The whole round. Do you know that the oldest copy does not say waste? The character is the one for a field left fallow. Somebody read it wrongly four hundred years ago, and you have all been living in his mistake."],
	],
	"holy": [
		["A single phase. Amitabha. It is a great gift and I shall pray for you, %s. People pray for the poor and forget the gifted. The gifted have further to fall and softer people round them."],
		["Two phases. The left hand and the right, and what they do when they are put together. I can show you, if you have forgotten. It costs nothing and is done like this."],
		["Three. The Buddha, the teaching, the brothers. I do not think the stone knows that. I think the stone only counts. But it is a pleasant thing to be handed by an accident."],
		["Four phases, and they frowned at it. The abbot says a bowl with four dents holds the same rice. He says it of his own bowl, which he will not let us replace."],
		["Five. They told you waste. %s, I sweep a hall that is empty in the middle, and the emptiness is the part people come for. I would not be quick to say what a thing with room in it is good for."],
	],
	"cult": [
		["Senior. I, that is. We drew lots to see who would speak to you if you came this way. I lost. I mean I won. The stone has your palm-print in it still. We are not allowed to touch it. We all have."],
		["A Twin Root, Senior. Mine is three. I ask the Twin Roots how it feels, and they say it does not feel like anything. I think that is the most unfair part. They should at least be able to tell."],
		["True Root, as mine is. They gave you a broom. They gave me a broom. Then you did all that. Senior, you have made it very hard for the rest of us to blame the stone."],
		["Four, Senior? Truly? There is a boy in my dormitory with four who cries at night. May I tell him? I should like to tell him. I will not say who told me. He would not believe me."],
		["The waste... the Whole Round, Senior. Forgive me. We are taught the first word and you have made us learn the second. The instructors have stopped using you as an example. They do not say of what."],
	],
}
const SAID_CLIP := {
	"hand": ["bow", "nod", "nod", "think", "shake"], "kid": ["cheer", "point", "shake", "think", "cheer"],
	"giant": ["nod", "nod", "think", "nod", "laugh"], "elder": ["think", "nod", "nod", "think", "think"],
	"watch": ["bow", "bow", "nod", "think", "shake"], "trade": ["bow", "bow", "nod", "think", "offer"],
	"learned": ["think", "think", "nod", "think", "point"], "holy": ["bow", "offer", "nod", "nod", "bow"],
	"cult": ["bow", "bow", "nod", "kneel", "bow"],
}

## How townsperson `p` answers his root: {line, clip}.  `kind` is what they are (Manners.kind_of).
static func said(g, kind: String, seed0: int = 0) -> Dictionary:
	var k := kind if SAID.has(kind) else "hand"
	var n := count(g)
	var ls: Array = SAID[k][n - 1]
	return {"line": str(ls[absi(seed0) % ls.size()]).replace("%s", str(g.address())), "clip": str(SAID_CLIP[k][n - 1])}

## The people of the story who have known him longest: one line each for each root, said among their
## other words once the story has begun (`from`: the step after which they have it to say).
const NAMED := {
	"elder": {"n": "Elder Qing Xuan", "lines": [
		"I held the stone the day you were measured, child. One colour, to the top. I had to sit down. And then I gave you a broom, as I give everyone, and three of the council did not speak to me for a year.",
		"Two colours came up under your hand, child, and I thought: good. Not so bright that we shall ruin it. I have seen what a sect does to a child it is proud of. I gave you the broom to hide you in.",
		"Three bands, none to the top. I have held that stone for nine hundred children, and that is what it shows for seven hundred of them. I remember yours because you looked at it as if it had been rude.",
		"Four colours, low. The registrar had his brush on the line that sends a child down. I said there was a bed. There was not. I gave you mine for a month and told nobody. Do not look like that. It was a hard bed.",
		"The stone hardly lit, child. All five, like dawn before it is any colour. The council voted. I was outvoted. I gave you a broom, because nobody votes on who sweeps, and then I waited to be proved right."]},
	"smith": {"n": "Smith Tie", "lines": [
		"One phase. Pure ore. I will say what I say of pure ore: it takes an edge like nothing else, and it has no forgiveness in it. Mind how you are quenched.",
		"Two phases is a good billet. Iron for the back, steel for the edge. I have been welding the two for forty years, and the weld is the strongest part.",
		"A True Root. Three-fold steel: that is what every decent blade in this shop is. I do not know why the sect talks of it as if it were the least they could do. It is what I do on purpose.",
		"Four phases. A mixed bloom, we would call it. You do not throw a mixed bloom on the heap. You fold it. And fold it. It is only that most people have somewhere to be.",
		"A waste root, they wrote. I have a bin of what the mines call waste: every metal there is, fused. Nobody will buy it. Last winter I made a bell of it, for a joke. Come and hear the joke."]},
	"yue_ling": {"n": "Yue Ling", "lines": [
		"I asked the Elder what a Heavenly Root feels like from inside, Lin Feng, since you never say. He said: like being the only one who cannot see why the others are slow. I think that is why you are kind. You had to learn it.",
		"A Twin Root. Do you know what the herb garden sisters say of you? That you are the only disciple with two phases who ever asked a three how she did it. I was the three. I have not forgotten.",
		"We have the same root, Lin Feng, you and I: three bands, none to the top. I used to mind. Then I noticed that everything I can heal, I can heal because I was slow enough to watch it happen.",
		"Four, and they nearly sent you down. I have read the stone's ledger; healers may. Next to your line somebody has written, later, in different ink: we were wrong. It is not the Elder's hand. I do not know whose.",
		"They say waste root in the refectory when they think you cannot hear, Lin Feng. I hear. I have five jars on my shelf, one for each phase, and nothing I make that is worth making uses fewer than all of them."]},
}

## What `id` has to say of his root ("" if they have no word of their own).
static func word(g, id: String) -> String:
	if not NAMED.has(id):
		return ""
	return str(NAMED[id].lines[count(g) - 1])

## Lines some conversations of the story gain for the root he has: a dialogue key -> for each number
## of phases, the lines added at the end.  (Fetched with everything else through Echoes.told.)
const AT := {
	"s_p35_home": [
		[["Elder Qing Xuan", "You went up that stone in one colour, child. You will not know what it is to be turned back at a gate. That is why I am sending you: so that somebody tells you."]],
		[["Elder Qing Xuan", "You were two colours on that stone, child. Close enough to the top to be let in and far enough from it to remember the gate. Go and ask on the boy's behalf."]],
		[["Elder Qing Xuan", "You were three bands on that stone, child, and I gave you a broom. He is five, and the rule gives him nothing. There are two steps between you. Go and find out how high they are."]],
		[["Elder Qing Xuan", "You were four on that stone, child, and the brush was on the line. I remember who moved it. So do you. He has one more colour than you had. Go and find out what one colour is worth."]],
		[["Elder Qing Xuan", "You were five on that stone, child, as he is. They voted then, too. I have kept the tally of that vote in my sleeve for all these years. Go and find out whether I should burn it or frame it."]],
	],
	"s_p35_gate": [
		[["Zeng Shen", "They say you were one colour, to the top. I do not think you can know what I am asking. But you came down the steps to hear it, and the ones who are like you do not come down. So I will ask."]],
		[["Zeng Shen", "They say you were two colours. That is nearly the best. I thought somebody like you would only tell me to try harder. You have not said it yet. I have been waiting for it."]],
		[["Zeng Shen", "They say you were three, and swept. Three is what I prayed for, on the way up. I did not ask for one. I only asked for enough to be let stay. I think I asked too quietly."]],
		[["Zeng Shen", "They say you were four, and that somebody moved a brush. Nobody has moved it for me. I do not say it to complain. I only want to know whether it was the root that kept you, or the hand."]],
		[["Zeng Shen", "They say you were five. As I am. And that they call you Senior now. The registrar told me so himself, while he was writing me down as waste. He did not seem to notice he had said both."]],
	],
}

static func told(g, key: String) -> Array:
	if not AT.has(key):
		return []
	return AT[key][count(g) - 1]
