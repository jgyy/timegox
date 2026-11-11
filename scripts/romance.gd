class_name Romance
extends RefCounted
## Courtship (the Thundering Pots release): more that can pass between Lin Feng and Yue Ling than the
## story asks for.  The Lotus release (bonds.gd) gave her closeness, heart-to-hearts, wishes and a
## future of her own choosing; none of that is changed.  This is what the player may add to it, from
## her page (Esc > Yue Ling), and never has to:
##
##   * **Gifts** (`GIFTS`): twelve things to give her, bought of a pedlar on the spot, found, made or
##     won.  She has tastes: some she loves, some she likes, one or two she does not know what to do
##     with, and she says so.  Each once.
##   * **Hours together** (`OUTINGS`): ten, each to be had only in its own kind of place at its own
##     hour (a town under lanterns, a summit, the water's edge, a tea table indoors, the road at
##     dawn, the dark of a cave, a market, the open country under stars, snow, the sect's own steps).
##     Each is a short scene and one of three things to say: tender, playful or quiet.  What is said
##     most often becomes how the two of them are with each other (`tone`).
##   * **What there is to say** (`ASKS`): three questions, in order, each when the two are close
##     enough and not before: to say it (they are **courting**), to exchange tokens (**promised**),
##     and three bows (**wed**).  She answers as herself: if the road she chose in Part XV is her own,
##     she will be promised, and will not be wed until she is back from it.
##
## Nothing here is needed by any step, trial or ending, and the bot leaves it alone.

const STAGES := ["Walking together", "Courting", "Promised", "Wed"]
const TONES := {"tender": "tender with each other", "playful": "forever teasing each other", "quiet": "easy in each other's silence"}
const LOVE := 4
const LIKE := 2
const MEH := 1
const OUTING := 3

## `cost`: spirit stones, to a pedlar; `item`: something carried (kept, unless `spend`); `need`: a
## thing done first ([what, how much]: Feats.value); `taste`: "love", "like" or "meh".
const GIFTS := {
	"haws": {"n": "A stick of candied haws", "cost": 60, "taste": "love",
		"desc": "Six hawthorn berries on a bamboo skewer, dipped in sugar gone hard as glass. Every child in the land has had one. She has not.",
		"line": "It cracks! It is sour underneath, and then it is not. Why did nobody tell me about this? I have been alive, in a manner of speaking, for nine hundred years."},
	"socks": {"n": "Quilted socks", "cost": 200, "taste": "love",
		"desc": "Two layers of cotton with silk floss between, stitched in a pattern of clouds. The pedlar says they are for grandmothers.",
		"line": "Oh. ...My feet were tied to a post, when you found me. They have been cold ever since and I never said. How did you know? You did not know. You only bought socks. That is worse. That is so much worse.", "face": "tender"},
	"ribbon": {"n": "A hair ribbon", "cost": 300, "taste": "like",
		"desc": "Plain silk, the blue of the sect's roofs, a hand longer than she needs.",
		"line": "Blue. Yours, then, not mine; I shall be going about in your colours. Tie it. No, not like a sack of rice. Give it here."},
	"rouge": {"n": "A pot of rouge", "cost": 400, "taste": "meh",
		"desc": "Safflower red in a porcelain pot the size of a walnut. The pedlar swears by it.",
		"line": "What does one do with it? ...On the face. On purpose. I see. I shall keep it for marking the patients I have already seen. Thank you. I mean that kindly."},
	"kite": {"n": "A red kite", "cost": 500, "taste": "love",
		"desc": "Paper and split bamboo, red all over, with a tail of knotted rag. Not for hanging under. For holding the string of.",
		"line": "A red one. I asked for a red one, years ago, on a road, and you were listening. Something of ours up in the sky, I said. Come on. There is wind. There is always wind if one runs."},
	"needles": {"n": "Nine silver needles", "cost": 1800, "taste": "love",
		"desc": "A physician's set in a roll of indigo cloth: filiform, sharp-round, the long one for the hip. Tushan work, each stamped.",
		"line": "These are balanced. Feel that. The old set I have was the Founder's; it has never once felt like mine. ...You have given a healer her own needles. Do you understand what you have done? I shall never stop."},
	"comb": {"n": "A jade comb", "cost": 2500, "taste": "like",
		"desc": "White jade, carved along the spine with a lotus stem that has no flower on it yet.",
		"line": "No flower. The carver left room. ...It is too fine for a road. I shall wear it anyway and worry about it constantly, which I take to be the purpose of fine things."},
	"mooncake": {"n": "A mooncake", "cost": 150, "taste": "like",
		"desc": "Lotus-seed paste and one salted yolk, stamped on top with the character for round.",
		"line": "Lotus seed. You have given a lotus a cake made of lotus. I am not sure whether that is tender or a kind of cannibalism. Half each. The yolk is mine."},
	"flowers": {"n": "Flowers from a summit", "need": ["summits", 1], "taste": "like",
		"desc": "Whatever was growing by the cairn: a gentian, something yellow, grass. Carried down inside the robe, and somewhat the worse for it.",
		"line": "You climbed a mountain with your hands and came down with weeds. They are crushed. This one is a medicinal for the stomach. I am keeping all of them and you are not to mention it."},
	"poem": {"n": "A poem in his own hand", "need": ["pastimes", 6], "taste": "like",
		"desc": "Four lines of five, written at somebody's table with somebody's brush. The third line does not scan and he knows it.",
		"line": "'Her hands remember more than she.' ...The third line is a foot short. I shall say that every time I read it, which will be often. Do not write me another. I could not bear two."},
	"cricket": {"n": "A cricket won at the mat", "need": ["gamble_wins", 1], "taste": "meh",
		"desc": "A fighting cricket in a clay pot with a lid, a champion, Old Du says, of the autumn season.",
		"line": "He has a torn wing. You won him in a fight? He was in a fight for money? ...There. Go. The wall of the Pear Garden is that way, sir, and it is full of ladies. Do not look at me so, Lin Feng. It was a lovely thought."},
	"duck": {"n": "The small clay duck", "item": "clay_duck", "taste": "love",
		"desc": "Yellow glaze, fits in the palm, squeaks. For the bath of the Son of Heaven. Reject.",
		"line": "You are giving me the duck. Our duck. To be mine. ...I have been given a star, and my own name, and a thread on the Wheel. I want it written down that I cried at the duck."},
}
const GIFT_ORDER := ["haws", "socks", "ribbon", "mooncake", "flowers", "kite", "rouge", "poem", "cricket", "needles", "comb", "duck"]

## `where`: the kind of place and hour (`here`); each option: [id, tone, what he says, what she says]
const OUTINGS := {
	"lanterns": {"n": "Under the lanterns", "where": "town_night", "hint": "In a town, after dark.",
		"lines": [["Narrator", "The lamplighter has been down the street and gone. Under every eave there is a small round light, and under each light, moths. Yue Ling has stopped in the middle of the road with her face turned up."],
			["Yue Ling", "They come every night and it kills some of them and they come. I used to think that was stupid. I am less sure. Look how warm it is, from here."]],
		"options": [["tender", "tender", "\"Then stand in it. I will keep the moths off.\"", "You cannot keep moths off. ...You are trying. You are actually waving your sleeve. Stop, stop, I am warm, I am quite warm now."],
			["playful", "playful", "\"You are standing in the road. There is a cart.\"", "There is not a cart. There has not been a cart in an hour. You only wanted me to take your arm. ...Well. There might be a cart."],
			["quiet", "quiet", "Say nothing. Stand beside her under the light.", "...Yes. Like that. You are the only person I know who can be quiet at somebody without it being a question."]]},
	"summit": {"n": "On the cairn", "where": "summit", "hint": "On the very top of a peak.",
		"lines": [["Narrator", "The top, and nothing above it. The wind has taken Yue Ling's hair out of its ribbon and she has let it. She is counting the stones on the cairn, moving her lips."],
			["Yue Ling", "Forty-one. Forty-one people came all the way up here and wanted somebody to know. I like them. I like every one of them. Put ours on together; I want to feel it settle."]],
		"options": [["tender", "tender", "\"One stone. Both hands on it.\"", "Both hands on it. There. Forty-two, and it is the only one on this mountain that two people set down. Whoever counts them next will not know. I shall."],
			["playful", "playful", "\"Yours goes underneath. I am taller.\"", "You are a hand taller and you have been unbearable about it since the bamboo forest. Mine goes on top. I am older. By nine hundred years. Kneel."],
			["quiet", "quiet", "Hand her the stone, and look where she is looking.", "...There is the sect. There is the pond. I can see everywhere I have ever been afraid, from here, and all of it is small. Thank you for not pointing."]]},
	"water": {"n": "At the water's edge", "where": "water", "hint": "Beside water, anywhere.",
		"lines": [["Narrator", "Yue Ling has taken off her shoes without asking anybody and is standing in the shallows up to the ankle, holding her hem in one fist, looking down at her own feet through the water as if they were a letter."],
			["Yue Ling", "I was woven beside water. I woke beside water. It is the one place I have never had to wonder whether I am real; it is cold, and that is me it is being cold at. Come in. It is horrible."]],
		"options": [["tender", "tender", "Take off your boots. Stand in it with her.", "You hate it. Your whole face is hating it. And you are staying. ...That is the thing about you. I do not think you know it is a thing."],
			["playful", "playful", "\"A sovereign does not paddle.\" Splash her.", "You have splashed a physician. You will regret it in your joints at sixty. HAH. And there, and THERE. Sovereign. Look at you. You look like a drowned broom."],
			["quiet", "quiet", "Sit on the bank and mind her shoes.", "You are minding my shoes. Nobody has ever minded anything of mine. ...Do not tell me they are only shoes. I know what they are."]]},
	"tea": {"n": "Over tea going cold", "where": "indoors", "hint": "Indoors, at somebody's table.",
		"lines": [["Narrator", "A table, two cups, a pot that was hot when it came. Outside there is weather, or a street. Yue Ling has both hands round her cup and has not drunk from it; she is using it, plainly, as a small stove."],
			["Yue Ling", "We never sit. Have you noticed? There is always a road, or a lord of something. I should like, once, to be bored with you. I think I should be very good at it."]],
		"options": [["tender", "tender", "\"Then let us be bored. Pour.\"", "Pour, he says. ...This is it, then. This is what the others have, the ones in the houses. A pot and nothing to say. I did not know it would feel like being let off something."],
			["playful", "playful", "\"I am bored already. It is your conversation.\"", "My conversation has healed three plagues and talked a goddess off a mountain. Yours consists of 'mm' and reports about bandits. Drink your tea. Wretch."],
			["quiet", "quiet", "Refill her cup when it is cold. Say nothing.", "...That is the third time you have filled it and I have not drunk one. You have noticed, and you fill it anyway, because it is warm to hold. I see you, Lin Feng."]]},
	"dawn": {"n": "The road at first light", "where": "wild_dawn", "hint": "Out in the open country, as the sun comes up.",
		"lines": [["Narrator", "Grey, then not grey. The dew is on everything and the birds have begun arguing. Yue Ling is a pace ahead, as she always is at this hour, and she has started, without knowing it, to hum."],
			["Yue Ling", "...Was I? I was. It is yours, you know. The thing you whistle on the steps. I have had it in my head for years and I have never once got the end right."]],
		"options": [["tender", "tender", "Whistle the end for her.", "So it goes down. I had it going up. ...It goes down, and then it stops, on the note it started on. Of course it does. It is a broom's tune. It comes back to the top step."],
			["playful", "playful", "\"There is no end. I make it up each morning.\"", "You make it up. I have spent eleven years trying to learn a tune that does not exist. That is the most you thing I have ever heard. Do it again. Differently. I dare you."],
			["quiet", "quiet", "Let her hum. Fall into step.", "...You are walking in time to it. You do not know you are. Do not stop; I have just found the end."]]},
	"cave": {"n": "In the dark", "where": "cave", "hint": "Under the ground.",
		"lines": [["Narrator", "The lamp has guttered, or been let gutter. In the dark of the cave there is the drip, and the sound of two people breathing, and after a while Yue Ling's voice, a good deal nearer than he had thought she was."],
			["Yue Ling", "I am not frightened. I want that understood. I was kept in the dark for some time, once, and I find I have opinions about it, that is all. ...Is that your sleeve?"]],
		"options": [["tender", "tender", "\"That is my hand. Take it.\"", "...It is warm. You are always warm; I have wondered whether it is the root or only you. Do not light the lamp yet. I have never been in the dark with somebody on my side before."],
			["playful", "playful", "\"That is a bat.\"", "It is NOT a bat, bats do not wear hemp, and if you make that noise again I shall heal you so thoroughly you will not sit down for a week. ...Keep hold. Of the bat."],
			["quiet", "quiet", "Find her hand in the dark. Say nothing.", "...There. Good. You did not ask if I was all right. Everybody asks. Then one has to be."]]},
	"market": {"n": "Through the market", "where": "town_day", "hint": "In a town, by day.",
		"lines": [["Narrator", "A street of stalls, and Yue Ling going down it like a magistrate. She has picked up, weighed and put down a melon, a bolt of blue cloth and somebody's baby. The baby has been pronounced sound."],
			["Yue Ling", "I never want any of it. I only like that it is here, and that they shout. Nine hundred years by a pond, Lin Feng. Nobody shouts by a pond. Buy something. Anything. I want to watch you haggle."]],
		"options": [["tender", "tender", "Buy the blue cloth. Give it to her.", "You paid what he asked. You did not haggle at all; you only looked at me and paid. He will dine out on that for a month. ...It is the blue of the roofs at home. You saw me put it down slowly."],
			["playful", "playful", "Haggle for the melon. Lose badly.", "He has sold you one melon for the price of four and thrown in a compliment to your wife. I am not your... he was not to know. Carry the melon. Carry it with dignity. Dearest."],
			["quiet", "quiet", "Walk beside her and carry what she picks up.", "You have a melon, a cabbage and a goose, and you have not asked why. ...Neither have I. I think I only wanted to see my things in somebody's arms."]]},
	"stars": {"n": "Under the Silver River", "where": "wild_night", "hint": "Out in the open country, at night.",
		"lines": [["Narrator", "No roof, no lamp. The Silver River from one side of the dark to the other, and on either bank of it the two stars everybody knows. Yue Ling is lying on her back in the grass with her hands behind her head."],
			["Yue Ling", "One night a year, on a bridge of magpies. We mended that river ourselves, you and I. I have always thought it a poor bargain. I should have held out for more nights. I should hold out for all of them."]],
		"options": [["tender", "tender", "\"You have all of them. Ask me for something harder.\"", "...All of them. He says it as if it were a bowl of rice. Very well. Something harder. Be here in the morning. And the one after. That is all. It turns out that is the whole of it."],
			["playful", "playful", "\"The Weaver had a loom to get back to. What is your excuse?\"", "My excuse is asleep in a satchel and is called forty patients. I should make a terrible Weaver. I would cross the bridge on the wrong night out of sheer bad temper. Move over. You have the soft grass."],
			["quiet", "quiet", "Lie down an arm's length off, and look up.", "...An arm's length. You measured it. Come here, you ridiculous creature; there is no bridge to cross. There is only grass."]]},
	"snow": {"n": "In the snow", "where": "cold", "hint": "In the cold country, where the snow lies.",
		"lines": [["Narrator", "Snow, the dry kind that squeaks. Yue Ling has stopped to look at her own breath. She breathes out, and watches it, and does it again, with the attention of somebody checking a pulse."],
			["Yue Ling", "It shows. In the cold. I never get tired of that. I was thread, Lin Feng; thread does not breathe. Every winter I come up here in my head and make sure. Look. There I am again."]],
		"options": [["tender", "tender", "Breathe out beside her. Let the two clouds meet.", "...They have gone into one. You cannot tell which was whose. I am going to think about that for a long while and I should be obliged if you would not explain it to me."],
			["playful", "playful", "Put snow down the back of her collar.", "!!! You. I. That is COLD, that is, oh, you will pay for that in this life and the next eleven. Run. I am a healer. I know exactly where the kidneys are."],
			["quiet", "quiet", "Take off your cloak and put it round her.", "I am not cold. I was not. ...I am keeping it. It smells of the kitchen at home, still. After all the realms. How does it still smell of the kitchen?"]]},
	"steps": {"n": "On the nine hundred and ninety-nine steps", "where": "sect", "hint": "At home, in the sect's own courts.",
		"lines": [["Narrator", "The east steps, in the hour when nobody uses them. A broom is leaning where a broom has always leaned. Yue Ling sits down on the third step from the top, tucks her feet under her, and looks at him expectantly."],
			["Yue Ling", "Go on. I have never seen it. Everybody has seen it; the cooks, the Elder, the gate disciples. I have walked the four realms with the sweeper of the Azure Cloud Sect and I have never once watched him sweep."]],
		"options": [["tender", "tender", "Sweep the steps. All of them. Properly.", "...You do the edges first. Nobody does the edges first. And you do not hurry, and you do not once look up to see whether I am watching. So that is who held the sky. I knew. I only wanted to see it done."],
			["playful", "playful", "Hand her the broom.", "Me? I am a guest. I am a founding relic. I... it goes like this? Like THIS? You did this for three years and nobody gave you a medal? There is a knack. Do not tell me there is a knack. Show me."],
			["quiet", "quiet", "Sit down on the step beside her instead.", "...Not today, then. Good. They have been swept every day for nine hundred years; they will keep. This will not. Sit closer. The stone is cold and you are not."]]},
}
const OUTING_ORDER := ["steps", "tea", "market", "lanterns", "water", "dawn", "stars", "summit", "cave", "snow"]

## The three questions, in order.  `bond`: how close the two must be; `more`: what else
## ([what, how much, in words]); each option [id, tone, what he does].
const ASKS := {
	"confess": {"n": "Say it", "stage": 0, "bond": 24, "more": [["outings", 2, "two hours spent together"]],
		"ask": "There is a thing that has been true for some time, and has not been said. How will you say it?",
		"options": [["plain", "tender", "Plainly. \"I love you. I have for years.\""], ["joke", "playful", "\"I have a report to make about my heart. It is short.\""], ["hand", "quiet", "Say nothing. Hold out a hand, and wait."]],
		"reply": {
			"plain": [["Yue Ling", "...Years. He says years, as if I had not been counting them. I know, Lin Feng. I knew before you did; I am a physician, I can hear a heart from across a room. I only wanted it said in a voice. Say it again. Slower.", "nod"]],
			"joke": [["Yue Ling", "A report. Of course it is a report. Well: received, and witnessed, and the answer is yes, and the answer was yes at the bamboo forest when you cut me down and apologised for the rope. Idiot. Come here.", "laugh"]],
			"hand": [["Yue Ling", "...You are not going to say it. You are going to stand there with your hand out like somebody feeding a deer. ...It is working. Do not move. I am deciding to take it, and I want to remember having decided.", "nod"]]},
		"after": [["Narrator", "Nothing is different afterwards, and everything is in a slightly different place, the way a room is when somebody has opened the shutters. They walk on. She has his sleeve in two fingers, as if it might be taken back."]]},
	"tokens": {"n": "Exchange tokens", "stage": 1, "bond": 42, "more": [["gifts", 3, "three things given her"]],
		"ask": "Promised people carry something of each other's. She has, pressed in the back of her needle-case, a lotus petal that has not faded in nine hundred years. What will you give her to keep?",
		"options": [["pin", "tender", "The jade pin from your hair: the one thing you came up the steps with."], ["straw", "playful", "A straw from the first broom, tied in a ring."], ["thread", "quiet", "A red thread, knotted once, with nothing said about it."]],
		"reply": {
			"pin": [["Yue Ling", "That is your mother's. It is all there was in the basket. Lin Feng, I cannot... No. I can. I am taking it, and I am putting it where the petal was, and you are having the petal. It was the first thing I ever had that was nobody's but mine.", "kneel"]],
			"straw": [["Yue Ling", "A ring. Of broom. I have been given a ring of broom by a Primordial Sovereign. ...It fits. It scratches. I am never taking it off. Give me your hand; you are having a petal that outlasted a dynasty, and you are to keep it flat.", "laugh"]],
			"thread": [["Yue Ling", "A red thread. I had none, you know. On the Wheel. I was not born, so the Old Man under the Moon never tied me to anybody. And you have just... with a knot. Out of your own sleeve. Hold still. Here is my petal. Now we are in the book.", "grieve"]]},
		"after": [["Narrator", "She wears it where it can be seen. Within a week every cook, novice and gate disciple on Azure Cloud Mountain has noticed, and has agreed, by the usual means, that nobody is to say anything to the Elder, who noticed first."]]},
	"wed": {"n": "Three bows", "stage": 2, "bond": 64, "more": [],
		"ask": "Granny Wen has had a red cloth in the bottom of her chest for sixteen years, against the day. One bow to heaven and earth, one to those who raised you, one to each other. Who shall stand witness?",
		"options": [["granny", "tender", "Granny Wen, in her own front room in Qingshi."], ["everyone", "playful", "The whole sect, the six hearths, and anybody who can find a seat."], ["moon", "quiet", "Nobody. The two of you, and the moon over the lotus pond."]],
		"reply": {
			"granny": [["Narrator", "Granny Wen's front room, with the table pushed back. She has put on the jacket she was married in, which no longer closes, and she cries from the first bow to the last, loudly, and corrects their posture."],
				["Yue Ling", "One to heaven and earth. One to her, who raised you on gruel. And one... look at me, Lin Feng. Not at the floor. I was woven to be a key. I am bowing to you because I have decided to. Lower. She is watching.", "bow"]],
			"everyone": [["Narrator", "They fill the great court and the steps and both walls. The horse-folk have brought a sheep; Tushan has brought a bell; the Lantern Hearth has brought the band, who do not know anything slow. The Elder gives her away, on the ground that he is the only one old enough."],
				["Yue Ling", "Four hundred people. You asked FOUR HUNDRED... there is a Dragon King in the third row eating sunflower seeds. Bow. Bow, you impossible person, before I laugh and ruin it. Heaven and earth. The Elder. And you. Oh, and you.", "bow"]],
			"moon": [["Narrator", "The lotus pond, where she woke with a name and nothing else. No red cloth, no table. The moon is in the water twice, once where it is and once where the lotus leaves let it through."],
				["Yue Ling", "Heaven and earth: there they are. Those who raised us: yours is asleep in Qingshi, and mine is this pond. And each other. ...Nobody saw. That is right. Everything else we have ever done, the whole world watched. This one is ours.", "bow"]]},
		"after": [["Narrator", "The Annals of the Azure Cloud Sect have a new line that evening, in Archivist Lan's smallest hand, under the entry for the day. It is three characters long. She blotted it twice."]]},
}
const ASK_ORDER := ["confess", "tokens", "wed"]

static func stage(g) -> int:
	return int(g.romance.get("stage", 0))

static func stage_name(g) -> String:
	return STAGES[clampi(stage(g), 0, STAGES.size() - 1)]

static func gifts_given(g) -> int:
	return (g.romance.get("gifts", {}) as Dictionary).size()

static func outings_had(g) -> int:
	return (g.romance.get("outings", {}) as Dictionary).size()

## How the two of them are with each other: the tone taken most often ("" before any).
static func tone(g) -> String:
	var best := ""
	var bn := 0
	for t in ["tender", "playful", "quiet"]:
		var n := int((g.romance.get("tone", {}) as Dictionary).get(t, 0))
		if n > bn:
			bn = n
			best = t
	return best

static func _lean(g, t: String) -> void:
	if not g.romance.has("tone"):
		g.romance["tone"] = {}
	g.romance.tone[t] = int(g.romance.tone.get(t, 0)) + 1

# ---------------------------------------------------------------- gifts
## Why gift `id` cannot be given now ("" if it can).
static func gift_blocked(g, id: String) -> String:
	var gf: Dictionary = GIFTS[id]
	if (g.romance.get("gifts", {}) as Dictionary).has(id):
		return "Given already."
	if gf.has("cost") and g.stones < int(gf.cost):
		return "The pedlar wants %d spirit stones for it." % int(gf.cost)
	if gf.has("item") and int(g.inv.get(str(gf.item), 0)) < 1:
		return "It has to be found first."
	if gf.has("need") and Feats.value(g, [str(gf.need[0]), 0]) < float(gf.need[1]):
		return {"summits": "It grows on a summit: stand on one first.", "pastimes": "He has not done enough of the things of the land to have a line worth writing (six of them).",
			"gamble_wins": "It has to be won at Old Du's mat."}.get(str(gf.need[0]), "Not yet.")
	return ""

## Give it: what she says, and how much closer it brings them.
static func give(g, id: String) -> Array:
	if gift_blocked(g, id) != "":
		return []
	var gf: Dictionary = GIFTS[id]
	if gf.has("cost"):
		g.stones -= int(gf.cost)
	if not g.romance.has("gifts"):
		g.romance["gifts"] = {}
	g.romance.gifts[id] = str(gf.taste)
	var worth: int = {"love": LOVE, "like": LIKE, "meh": MEH}[str(gf.taste)]
	Bonds.add(g, worth, "a gift")
	g.note("Gave Yue Ling %s" % str(gf.n).to_lower())
	g.toast({"love": "She loves it", "like": "She likes it", "meh": "She does not know what to do with it"}[str(gf.taste)])
	var l: Array = ["Yue Ling", str(gf.line)]
	if str(gf.taste) == "love":
		l.append("cheer")
	return [["Narrator", str(gf.desc)], l]

# ---------------------------------------------------------------- hours together
## Whether the kind of place and hour an outing wants is where they are now (`ctx`: main.gd body_ctx).
static func here(where: String, ctx: Dictionary) -> bool:
	var h := float(ctx.get("hour", 12.0))
	var night: bool = h >= 19.5 or h < 5.0
	match where:
		"town_night":
			return bool(ctx.get("town", false)) and night and not bool(ctx.get("indoors", false))
		"town_day":
			return bool(ctx.get("town", false)) and not night and not bool(ctx.get("indoors", false))
		"summit":
			return bool(ctx.get("summit", false))
		"water":
			return bool(ctx.get("water", false)) and not bool(ctx.get("indoors", false))
		"indoors":
			return bool(ctx.get("indoors", false)) and not bool(ctx.get("cave", false))
		"wild_dawn":
			return bool(ctx.get("wild", false)) and h >= 5.0 and h < 7.5
		"wild_night":
			return bool(ctx.get("wild", false)) and night
		"cave":
			return bool(ctx.get("cave", false))
		"cold":
			return bool(ctx.get("cold", false)) and not bool(ctx.get("indoors", false))
		"sect":
			return str(ctx.get("area", "")) == "sect" and not bool(ctx.get("indoors", false))
	return false

## The hours that can be had here and now.
static func outings_here(g, ctx: Dictionary) -> Array:
	var out: Array = []
	for id in OUTING_ORDER:
		if not (g.romance.get("outings", {}) as Dictionary).has(id) and here(str(OUTINGS[id].where), ctx):
			out.append(id)
	return out

## One was had, and `oid` was what he said: her answer, as lines.
static func take_outing(g, id: String, oid: String) -> Array:
	if not g.romance.has("outings"):
		g.romance["outings"] = {}
	for o in OUTINGS[id].options:
		if str(o[0]) == oid:
			g.romance.outings[id] = oid
			_lean(g, str(o[1]))
			Bonds.add(g, OUTING, "an hour together")
			g.note("An hour with Yue Ling: %s" % str(OUTINGS[id].n).to_lower())
			return [["Yue Ling", str(o[3])]]
	return []

# ---------------------------------------------------------------- what there is to say
## The question that comes next ("" when all three have been asked).
static func next_ask(g) -> String:
	return ASK_ORDER[stage(g)] if stage(g) < ASK_ORDER.size() else ""

## Why it cannot be asked yet ("" if it can).
static func ask_blocked(g, id: String) -> String:
	var a: Dictionary = ASKS[id]
	if not g.companion:
		return "She is not beside you."
	if stage(g) != int(a.stage):
		return "Not yet."
	if int(g.bond) < int(a.bond):
		return "Not yet: the two of you are not close enough (closeness %d of %d)." % [int(g.bond), int(a.bond)]
	for m in a.more:
		var have := gifts_given(g) if str(m[0]) == "gifts" else outings_had(g)
		if have < int(m[1]):
			return "Not yet: it wants %s first (%d so far)." % [str(m[2]), have]
	if id == "wed":
		if str(g.future) == "":
			return "Not yet: she has no thread on the Wheel to tie, until the end of Part XV."
		if str(g.future) == "wander":
			return "She has chosen a road of her own, and means to come back from it. \"Ask me then,\" she says. \"I shall say yes. I want to have been somewhere first.\""
	return ""

## Asked, and `oid` was how: what is said, as lines; the two are a stage further on.
static func take_ask(g, id: String, oid: String) -> Array:
	if ask_blocked(g, id) != "":
		return []
	var a: Dictionary = ASKS[id]
	if not a.reply.has(oid):
		return []
	for o in a.options:
		if str(o[0]) == oid:
			_lean(g, str(o[1]))
	g.romance["stage"] = int(a.stage) + 1
	g.romance[id] = oid
	Bonds.add(g, 5, str(a.n).to_lower())
	g.toast("Yue Ling and %s: %s" % ["Lin Feng", STAGES[int(a.stage) + 1]])
	g.note("Yue Ling and Lin Feng: %s" % STAGES[int(a.stage) + 1])
	if id == "wed":
		g.grant_yue_outfit("redbride")
	return (a.reply[oid] as Array) + (a.after as Array)

## What being promised, and wed, gives her in battle: somebody to come home to (her health).
static func mod(g) -> float:
	return 1.0 + 0.03 * float(stage(g))

## What the last page says of the two of them ([] if nothing was ever said).
static func epilogue(g) -> Array:
	match stage(g):
		1:
			return [["Narrator", "It was said, between the two of them, once, on a road; and neither of them was ever heard to say it again, having no need to."]]
		2:
			return [["Narrator", "She wears a token of his and he keeps a lotus petal flat in the back of a book. Promised people are patient. They have the time."]]
		3:
			var how := {"tender": "They are tender with each other, in the way of people who know what it cost.", "playful": "They have not stopped teasing each other for one day since, and the novices take notes.",
				"quiet": "They are easy in each other's silence, and can sit a whole evening without a word and call it conversation."}
			return [["Narrator", "And Lin Feng and Yue Ling were wed, with three bows. " + str(how.get(tone(g), "Nobody who knew them was surprised."))]]
	return []

## The page's summary line.
static func summary(g) -> String:
	var t := tone(g)
	return "%s%s      %d of %d gifts given      %d of %d hours had together" % [stage_name(g), (", " + str(TONES[t])) if t != "" else "", gifts_given(g), GIFT_ORDER.size(), outings_had(g), OUTING_ORDER.size()]
