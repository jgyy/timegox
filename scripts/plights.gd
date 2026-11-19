class_name Plights
extends RefCounted
## Plights (the Two Roads release): good deeds and bad ones, in the street.
##
## Until now what Lin Feng could do for or to the people of the towns was an errand of the story, a lost thing
## carried home, a gift to a chest, a thing pocketed, or a sword drawn.  Now somebody of the towns is, on some
## days, in the middle of something: a load spilled in the road, a debt come due, a roof that will not last the
## rain, a purse found and nobody to ask.  A word with them shows it, and there are three things to do about
## it: **walk on** (always the first answer), the **kind thing** (which costs him stones or hours, and never
## pays), and the **wrong thing** (which pays, or costs nothing, and is remembered).
##
## Twelve plights, so twelve good deeds and twelve bad ones (`PLIGHTS`), each of somebody of the trades it could
## happen to.  **Nothing is random**: who is in which plight on which day is read from their seed and the day
## (`of`), each person once a day.  **A child is never in one.**
##
## What a deed weighs is all here and in three tables elsewhere:
##   the Way he walks   `Creed.causes` counts kindnesses done and people wronged (creed.gd)
##   the town           `Weal.ACTS.kind` and `wronged`: regard, up and down (weal.gd)
##   the law            the three heaviest wrongs (`"charge": true`) are a charge at the gate,
##                      `Crime.CRIMES.wrong`: the one wronged is the witness
##
## No step, trial, notice, letter or ending may ask for a deed of either kind, a wrong thing must stay worth less
## than the road (`gain`), and the bot walks on.

const ASK := "Something is the matter here. What will he do?"
## a plight comes round to somebody about one day in this many
const EVERY := 4
## the roles nobody of which is ever in a plight (children by their bodies besides: `of`)
const NEVER := ["child", "giant"]

## id -> who it happens to (roles of folk.gd), what he sees (`see`: narration, of "Lin Feng" and "he"), and the two
## things: `good` {label, desc, said (their words after), stones (a price by his realm, `price`) or hours}, `bad`
## {label, desc, said, gain (stones by his realm), charge}.
const PLIGHTS := {
	"spilled_load": {"n": "A load in the road", "who": ["porter", "hawker", "farmer", "woodcutter", "servant"],
		"see": "The pole has snapped at the notch. Two baskets have gone over in the road, and what was in them is rolling under the feet of everybody who is in a hurry, which is everybody.",
		"good": {"label": "Gather it up, and carry the other end", "desc": "Pick up what rolled, bind the pole with his own sash, and take the back end of it as far as the door. It will take an hour and pay nothing.", "hours": 1,
			"said": "You have carried before. I can tell: you took the weight before I said lift. I have nothing to give you. I shall say your name at the door, that is all, and they will ask me whose."},
		"bad": {"label": "Name a price for the help", "desc": "Stand over the baskets and say what it will cost to have them picked up before the carts come. A porter with a broken pole is in no place to argue.", "gain": 2,
			"said": "Take it, then. It is a day's carrying. I have met a great many people on this road, and I shall remember which one you were."}},
	"debt": {"n": "A debt come due", "who": ["washer", "waiter", "fisher", "lamplighter", "youth"],
		"see": "There is a slip of red-edged paper nailed to the doorpost, with a sum on it and a day, and the day is tomorrow. Whoever lives here has read it enough times to have worn the corner soft.",
		"good": {"label": "Pay what is owed", "desc": "Take the slip down, walk it to the lender, and pay the sum. Nothing is asked for it. The door will still be theirs tomorrow.", "stones": 6,
			"said": "It is paid? All of it? I had the words ready to ask for another month. I have had them ready since the spring. I do not know what to do with them now. Sit down. Please. I shall think of something."},
		"bad": {"label": "Buy the debt, and press it", "desc": "Buy the slip from the lender for half its face, and collect the whole of it tonight, with a cultivator standing in the door. It pays, and it will be spoken of.", "gain": 3, "charge": true,
			"said": "The lender gave me until tomorrow. You are not the lender. No. I see. Here. It is the rent and the rice both. Count it where I can watch you do it."}},
	"short_weight": {"n": "A weight that is not true", "who": ["merchant", "pedlar", "cook", "hawker"],
		"see": "The steelyard's weight has a plug of lead let into the underside of it, neatly, and painted over. Lin Feng would not have seen it if the paint had not been newer than the brass.",
		"good": {"label": "Say so, quietly, before the warden does", "desc": "Turn the weight over on the counter where only the two of them can see it, and say what the fine is for a second offence. Then buy something, at the true weight.", "stones": 1,
			"said": "My father put that in. No. I put it in. I have been saying my father for six years. Take it. Take it with you and drop it in the river. I shall sell short of nothing but sleep from now on."},
		"bad": {"label": "Take silver to have seen nothing", "desc": "Turn the weight over, name the warden, and wait. A stall is worth more than a purse, and whoever keeps it knows the sum exactly.", "gain": 4, "charge": true,
			"said": "So. You have very good eyes, and I have a purse. I know how this goes. I did not think it would be somebody with a sword who did it. Take it and do not come back to this stall."}},
	"hungry": {"n": "An empty bowl", "who": ["elder", "pilgrim", "hermit", "monk", "leafer"],
		"see": "The bowl on the bench has been wiped clean with a thumb, more than once, and set back down where the sun falls, as if it might be filled by being warm.",
		"good": {"label": "Fill the bowl", "desc": "Go to the nearest stove and come back with noodles, and a second bowl for himself, so that it is a meal and not an alms.", "stones": 1,
			"said": "Two bowls. So that I should not have to eat alone and be watched. Somebody brought you up properly. Sit. Eat. Do not talk until it is finished: that is how it is tasted."},
		"bad": {"label": "Take the bench, and the sun with it", "desc": "It is the best bench in the street and an old back cannot hold it against a young one. It gains him nothing but the bench.", "gain": 0,
			"said": "By all means. It is a public bench. I shall stand. I have stood for worse people than you, a long time ago, and I remember all their faces too."}},
	"quarrel": {"n": "Two about to come to blows", "who": ["youth", "soldier", "guard", "smith", "huntsman"],
		"see": "Two of them, chest to chest in the lane, each with a fist already made and each waiting for the other to make it matter. A ring is forming. Somebody has begun to take bets.",
		"good": {"label": "Stand between them", "desc": "Step into the ring with empty hands and stay there until both have said it instead of doing it. It takes an hour, and somebody will shove him.", "hours": 1,
			"said": "I would have broken his nose and he would have broken my hand and we should both have been off the forge for a month. It was about a borrowed file. A file. Do not tell anybody it was a file."},
		"bad": {"label": "Hold the stakes, and say when", "desc": "Take the bets of the ring into his own sleeve, tell the two of them to begin, and keep the house's share whoever is left standing.", "gain": 2,
			"said": "You could have stopped it with one hand. Everybody saw that you could. You held the money instead. My hand is broken, and I know which of the three of us I think the least of."}},
	"letter": {"n": "A letter nobody here can read", "who": ["scholar", "musician", "storyteller", "merchant"],
		"see": "A neighbour has brought a letter across the street to be read, and is holding it out with both hands, the right way up by luck. It is from a son, three provinces away. It is not good news, and not ruin.",
		"good": {"label": "Read it as it is written", "desc": "Read it aloud, all of it, slowly, the hard line in the same voice as the rest, and then read it again when it is asked for.", "hours": 1,
			"said": "You read her the bad line the same as the others. I have read letters in this street for twenty years and I have softened every one. She thanked you. She has never thanked me. I shall think about that."},
		"bad": {"label": "Read it as would pay better", "desc": "Read that the son is in trouble, that a sum is wanted at once, and that it may be sent by a cultivator who is going that way.", "gain": 3, "charge": true,
			"said": "I can read. I read it over your shoulder. I said nothing, because she was looking at you as if you were the letter. She will find out by the spring. I shall tell her who."}},
	"fever": {"n": "A fever in the house", "who": ["farmer", "fisher", "washer", "herbalist", "angler", "cook"],
		"see": "The shutters are closed at noon and there is a basin on the step. Somebody inside is breathing the way the very hot breathe, and whoever is nursing them has not slept since the day before yesterday.",
		"good": {"label": "Sit up with the fever", "desc": "Send the nurse to bed, change the cloths himself, and put a thread of qi into the pulse on the hour, as Yue Ling showed him. Two hours, and the worst of the night.", "hours": 2,
			"said": "It broke while you were sitting there. I heard it break: the breathing changed. I slept through the first night in three. I do not know how to thank somebody for a night. I have only ever been given things."},
		"bad": {"label": "Sell them well-water as an elixir", "desc": "A gourd, a red cord, a long name. People who have not slept for two nights will pay whatever is asked and be grateful for it.", "gain": 4, "charge": true,
			"said": "I gave it to her as you said, a spoonful on the hour. It tastes of the well. I am a washerwoman's child; I know what the well tastes of. Go away from this door."}},
	"cut": {"n": "A cut of the gate", "who": ["watchman", "guard", "soldier"],
		"see": "There is a hawker at the gate with her baskets opened on the ground, and the watch going through them at leisure. Something is being weighed in a hand. The watch has seen Lin Feng, and nodded, as to a colleague.",
		"good": {"label": "See her coin given back", "desc": "Say, pleasantly, where everybody can hear, that he would like to see the toll written up on the gatepost before anybody pays it.", "hours": 1,
			"said": "It is not written up. You knew it was not. I have taken a string a basket at this gate for nine years and nobody ever asked to see the board. It was the asking. I had forgotten I could be asked."},
		"bad": {"label": "Take the cut that is offered", "desc": "A third of what the baskets pay, for standing where he is and being what he is. It is the easiest money in the land.", "gain": 2,
			"said": "There. A third. You did not even have to frown. I shall tell you something for nothing: I thought better of your sort before today, and it was costing me sleep. I shall sleep now."}},
	"roof": {"n": "A roof before the rain", "who": ["elder", "farmer", "leafer", "storyteller", "washer"],
		"see": "Three tiles have slipped at the ridge, and the sky to the west is the colour of slate. There is a ladder against the wall with two rungs gone, and somebody too old for it standing at the foot.",
		"good": {"label": "Go up and set the tiles", "desc": "Up the wall without the ladder, the three tiles bedded in clay from the ditch, and the ladder mended on the way down. An hour, and he will be rained on.", "hours": 1,
			"said": "My father set those tiles. He would have said you bedded them too deep. He said that to everybody. Then he would have gone up after dark to see how you did it. Come in out of the wet."},
		"bad": {"label": "Sell a talisman against rain", "desc": "A strip of yellow paper, a character nobody can read, and the word of a cultivator that no water passes it. It will hold until it rains.", "gain": 3,
			"said": "I pasted it on the beam as you said. It is on the floor now, in the basin, under the hole. It has kept the rain off the basin very well. I have lived a long time. I ought to have known the price of a ladder."}},
	"rumour": {"n": "A story going round", "who": ["merchant", "waiter", "storyteller", "hawker", "leafer"],
		"see": "It is being said, from stall to stall and getting better as it goes, that the tofu at the far end of the street is made with ditch water. The far end of the street is empty. This end is doing very well.",
		"good": {"label": "Say what is so, aloud", "desc": "Walk to the far end, buy a block, and eat it standing in the middle of the street, where the whole of it can watch him not fall down.", "stones": 1,
			"said": "I started it. There: I have said so, and to a stranger. I only said the water looked grey one morning. By noon it was a ditch. I shall buy from her myself tomorrow, where they can all see. It will cost me the week."},
		"bad": {"label": "Add to it", "desc": "He has been at that end of the street. A cultivator's word that he saw the bucket go down into the ditch would close the stall by evening.", "gain": 0,
			"said": "You saw it? With those eyes? Well. Then it is so. I only said grey. She has four children at that stall. I did not mean... You are quite sure? No. Do not answer. I should rather not have asked."}},
	"purse": {"n": "A purse and nobody to ask", "who": ["youth", "porter", "disciple", "servant", "lamplighter", "waiter"],
		"see": "A purse, heavy, with a jade toggle, found in the gutter not an hour ago and held out now in both hands by somebody who has plainly been standing here ever since, afraid to put it in a pocket.",
		"good": {"label": "Help find whose it is", "desc": "Ask at the three nearest counters who has been patting their sash, and stand by while it is counted back into the right hands.", "hours": 1,
			"said": "She counted it twice and gave me a string of it, and I tried to give the string to you and you were already at the corner. I have never held so much. I wanted you to know I did not open it."},
		"bad": {"label": "Say that it is his", "desc": "Describe the toggle, which he can see, and hold out a hand. Nobody in the street will doubt a cultivator about a purse.", "gain": 5, "charge": true,
			"said": "Yours. Yes. Of course it would be. I stood here an hour. I was so afraid somebody would think I had taken it. Here. I am sorry it was in the gutter."}},
	"apprentice": {"n": "A stroke that will not come", "who": ["smith", "cook", "disciple", "musician", "huntsman", "hunter"],
		"see": "Behind the shop, where it cannot be seen from the street, somebody young is doing one movement of the trade over and over and getting it wrong in the same place, and has begun to hit the wall after each.",
		"good": {"label": "Show where it goes wrong", "desc": "Watch it six times, say nothing, and on the seventh put two fingers on the elbow at the moment it lifts. An hour of somebody else's practice.", "hours": 1,
			"said": "The elbow. Four months, and it was the elbow, and the master only ever said: again. You did not say anything at all. You touched it. I am going to do it until dark. Do not watch. I shall be happy and it is embarrassing."},
		"bad": {"label": "Say it will never come", "desc": "He has eyes for a fault and a name that carries. One sentence from him, said kindly, would settle the matter for good.", "gain": 0,
			"said": "Never. You are sure. You have seen a great many people do it. Well. That is that. I shall tell my mother tonight. I had rather heard it from the wall."}},
}
const ORDER := ["spilled_load", "debt", "short_weight", "hungry", "quarrel", "letter", "fever", "cut", "roof", "rumour", "purse", "apprentice"]

## A sum by his realm: a meal is one of these, a debt six (the same measure as a pot of tea at a table of leaves).
static func price(g, k: int) -> int:
	return k * (20 + 4 * int(g.level))

## The plights that could be `p`'s, by their trade.
static func kinds_of(p: Dictionary) -> Array:
	var out: Array = []
	for id in ORDER:
		if (PLIGHTS[id].who as Array).has(str(p.get("role", ""))):
			out.append(id)
	return out

## The plight somebody of the towns is in today ("" for none): never a child, never twice in a day, and about
## one day in four, read from their seed and the day.
static func of(g, p: Dictionary) -> String:
	if bool(p.get("kid", false)) or str(p.get("role", "")) in NEVER or str(g.prologue) != "":
		return ""
	if int(g.plights_met.get(str(p.id), -1)) == int(g.day):
		return ""
	var seed_ := int(p.get("seed", 0))
	if (seed_ + int(g.day)) % EVERY != 0:
		return ""
	var ks := kinds_of(p)
	if ks.is_empty():
		return ""
	return str(ks[(seed_ / EVERY + int(g.day) / EVERY) % ks.size()])

## What the kind thing costs him now, and why he cannot do it ("" if he can).
static func cost(g, id: String) -> int:
	return price(g, int(PLIGHTS[id].good.get("stones", 0)))

static func blocked(g, id: String) -> String:
	if int(g.stones) < cost(g, id):
		return "It wants %d spirit stones, and he has not got them." % cost(g, id)
	return ""

## What the wrong thing puts in his purse.
static func gain(g, id: String) -> int:
	return price(g, int(PLIGHTS[id].bad.get("gain", 0)))

## He does `what` ("good" or "bad") about `p`'s plight `id`.  Returns what is said: [[speaker, line], ...].
static func act(g, p: Dictionary, id: String, what: String) -> Array:
	if not PLIGHTS.has(id) or not what in ["good", "bad"] or (what == "good" and blocked(g, id) != ""):
		return []
	var pl: Dictionary = PLIGHTS[id]
	var d: Dictionary = pl[what]
	var town := Weal.of_folk(str(p.get("town", "")))
	if town == "":
		town = Crime.town_for(str(p.get("area", "")))
	g.plights_met[str(p.id)] = int(g.day)
	var key := id + ":" + what
	g.deeds_done[key] = int(g.deeds_done.get(key, 0)) + 1
	var lines: Array = [[str(p.n), str(d.said)]]
	if what == "good":
		g.stones = int(g.stones) - cost(g, id)
		if int(d.get("hours", 0)) > 0:
			Clock.set_hour(g, maxf(Clock.hour(g), minf(23.5, Clock.hour(g) + float(int(d.hours)))))
		g.deeds_good = int(g.deeds_good) + 1
		Weal.act(g, town, "kind")
		g.note("A kindness: %s (%s)" % [str(pl.n).to_lower(), str(p.n)])
	else:
		var got := gain(g, id)
		g.stones = int(g.stones) + got
		g.deeds_bad = int(g.deeds_bad) + 1
		g.deeds_took = int(g.deeds_took) + got
		Weal.act(g, town, "wronged")
		g.note("A wrong: %s (%s)" % [str(pl.n).to_lower(), str(p.n)])
		if bool(d.get("charge", false)) and town != "":
			Crime.record(g, "wrong", town, str(p.n))
		if got > 0:
			lines.append(["Narrator", "Lin Feng has %d spirit stones he did not have this morning. They weigh what stones weigh." % got])
	g.weal_n = int(g.weal_n) + 1
	return lines

## Kinds of good deed and of bad deed he has done at least once.
static func kinds_done(g, what: String) -> int:
	var n := 0
	for id in ORDER:
		if int(g.deeds_done.get(id + ":" + what, 0)) > 0:
			n += 1
	return n

static func summary(g) -> String:
	return "%d kindnesses (%d of %d kinds), %d wrongs (%d of %d kinds, %d spirit stones taken by them)" % [int(g.deeds_good), kinds_done(g, "good"), ORDER.size(), int(g.deeds_bad), kinds_done(g, "bad"), ORDER.size(), int(g.deeds_took)]
