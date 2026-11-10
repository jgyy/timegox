class_name Bonds
extends RefCounted
## Yue Ling (the Lotus release, Part XV).  She has walked beside Lin Feng since the bamboo forest, and
## this is the part of the game that is hers.
##
##   * **Closeness** (`Game.bond`): what the two of them have been through together, in five steps
##     from Companion to Heart's Companion.  It grows with every heart-to-heart, every wish of hers
##     granted, every thing done side by side (props.gd: a pavilion, a dance, a kite, the stars) and
##     every memory given back to her in Part XV.
##   * **Heart-to-hearts** (`TALKS`): when the story has given her something to say (one at least in
##     every chapter), "Yue Ling wants to talk" and T (or Esc > Yue Ling) opens it: a conversation and
##     a reply chosen by the player.  With nothing to talk about, T gets a word about wherever they are
##     (`REGION`).
##   * **Her heart** (`Game.heart`): every reply leans her towards one of three futures (`FUTURES`):
##     to walk beside him as his Dao companion, to stay as the lotus of the mountain, or to go out and
##     find a road of her own.  At the end of Part XV she chooses, and the ending tells it.
##   * **Her wishes** (`WISHES`): small things she would like to do with him (sit on a bench, ring a
##     bell, watch the stars, dance under lanterns), opened as the story goes; doing that kind of thing
##     anywhere with her there grants one.
##   * **Part XV, the Thread She Never Had**: woven, not born, she has no thread on the Wheel; now every
##     debt is settled the world is tidying her away.  The Founder pressed what she remembered of the
##     nineteen bearers into the places she was happiest (`MEMORIES`): find six of the seven, fight
##     off what is eating them, and give them back to her.

# ---------------------------------------------------------------- closeness
const LEVELS := [0, 10, 24, 42, 64]
const TITLES := ["Companion", "Trusted Friend", "Dear Friend", "Kindred Spirit", "Heart's Companion"]
## what doing something side by side, a wish and a memory are worth
const SHARED := 1
const WISH := 3
const MEMORY := 4
## a thing done together counts towards closeness once for every kind of thing, and again after
## this long (seconds of game time)
const SHARED_AGAIN := 1800.0

static func level(g) -> int:
	var lv := 0
	for k in LEVELS.size():
		if int(g.bond) >= LEVELS[k]:
			lv = k
	return lv

static func title(g) -> String:
	return TITLES[level(g)]

## Closeness grows; a new step is news.
static func add(g, n: int, why: String = "") -> void:
	if n <= 0:
		return
	var before := level(g)
	g.bond = int(g.bond) + n
	var after := level(g)
	if after > before:
		g.toast("Yue Ling: %s" % TITLES[after])
		g.note("Yue Ling and Lin Feng: %s%s" % [TITLES[after], (" (" + why + ")") if why != "" else ""])

## How far to the next step ("" at the last).
static func next_text(g) -> String:
	var lv := level(g)
	if lv >= LEVELS.size() - 1:
		return ""
	return "%d of %d to %s" % [int(g.bond) - LEVELS[lv], LEVELS[lv + 1] - LEVELS[lv], TITLES[lv + 1]]

# ---------------------------------------------------------------- her heart: three futures
const FUTURES := {
	"companion": {"n": "His Dao companion", "short": "walks beside him by choice", "col": Color("f08ab0"), "what": "to walk beside Lin Feng as his Dao companion, not because a seal was woven so, but because she chose to",
		"epilogue": "Yue Ling walks beside Lin Feng still, as his Dao companion, and has a page of her own in the Book of Life and Death. It is mostly about him. She says that is her business."},
	"lotus": {"n": "The lotus of the mountain", "short": "keeps the mountain's door", "col": Color("8ae0c0"), "what": "to stay on Azure Cloud Mountain as the lotus of its pond, keeper of the door the Seal became, rooted and free at once",
		"epilogue": "Yue Ling keeps the lotus pond of Azure Cloud Sect. Disciples who sit by it come away calmer, and the old ones say a healer in rose comes out of the water on spring nights to scold anybody who is not sleeping enough."},
	"wander": {"n": "A road of her own", "short": "walks a road of her own", "col": Color("f0c860"), "what": "to go out into the world as the wandering healer she once only pretended to be, and make threads of her own",
		"epilogue": "Yue Ling wanders the four realms as a healer, and comes home to the sect every spring with a basket of strange herbs and a hundred new friends. Lin Feng sweeps the steps for her coming, every year, a day early."},
}
const FUTURE_ORDER := ["companion", "lotus", "wander"]

static func lean(g, key: String, n: int) -> void:
	if not FUTURES.has(key) or n <= 0:
		return
	g.heart[key] = int(g.heart.get(key, 0)) + n

## "Leans her heart towards ...": future `key`'s name to go mid-sentence (its first letter lower
## case, so "his Dao companion" keeps its Dao); `none` when `key` is no future.
static func toward(key: String, none: String = "nothing in particular") -> String:
	var n := str(FUTURES.get(key, {}).get("n", none))
	return n.substr(0, 1).to_lower() + n.substr(1)

## The future her heart leans towards most (the first of FUTURE_ORDER on a tie, "" before any).
static func leaning(g) -> String:
	var best := ""
	var bn := 0
	for k in FUTURE_ORDER:
		if int(g.heart.get(k, 0)) > bn:
			bn = int(g.heart.get(k, 0))
			best = k
	return best

# ---------------------------------------------------------------- heart-to-hearts
## Each opens once the step `after` is done: her lines, a question, and the replies Lin Feng can give
## (`lean`: which future it leans her towards, `bond`: closeness, `after`: what is said next).
const TALKS := [
	{"id": "t_lotus", "after": "s_spirit", "lines": [
		["Yue Ling", "Lin Feng. Can I ask you something silly? When you look at me, do I look like somebody who has a family?"],
		["Lin Feng", "You look like somebody who should have a very large one. With a lot of aunts."],
		["Yue Ling", "I woke beside a lotus pond three winters ago with my name and nothing else. No village, no mother, no reason. Just Yue Ling, and hands that knew how to set a bone."],
		["Yue Ling", "Sometimes I think I made the name up on the spot. Moon and bell. It sounded like somebody I would like to be."]],
		"ask": "What do you say about her name?",
		"options": [
			{"id": "mine", "label": "\"It suits you. Keep it.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then you chose well. It suits you. Whoever you were before, I am glad I met this one."], ["Yue Ling", "...That was very smooth for a sweeper. Say it again when I am not covered in bandit soot."]]},
			{"id": "pond", "label": "\"Let's find that pond one day.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "One day we will find that pond, and ask it."], ["Yue Ling", "Ponds are terrible at answering questions. But yes. I would like that."]]},
			{"id": "new", "label": "\"Then make up the rest too.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "If you made up the name, make up the rest. A village, a mother, a reason. Who is going to stop you?"], ["Yue Ling", "A healer from a village of healers whose mother was a famous herbalist and whose reason is very mysterious. Yes. That will do nicely."]]}]},
	{"id": "t_hands", "after": "s_antidote", "lines": [
		["Yue Ling", "The Hag's poisons were beautiful, Lin Feng. I hate that I could see that. Every one of them was a cure turned inside out."],
		["Yue Ling", "My hands knew the antidote before my head did. They always know. As if they belonged to somebody who studied for a hundred years."],
		["Lin Feng", "Maybe they did."],
		["Yue Ling", "Then I would like to meet her and ask her why she left me her hands and not her name."]],
		"ask": "What do you say about her hands?",
		"options": [
			{"id": "trust", "label": "\"I trust those hands with my life.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Whoever they belonged to, I trust them with my life. I have done it four times this week."], ["Yue Ling", "Five. You did not notice the fifth. That is how good they are."]]},
			{"id": "teach", "label": "\"Teach the sect's healers.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Alchemist Mo would give an arm to learn what your hands know. Well, a finger."], ["Yue Ling", "I would teach them. If I stayed somewhere long enough to teach anything."]]},
			{"id": "world", "label": "\"The world needs those hands.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Every village we pass has somebody sick and nobody to help. Those hands could go anywhere."], ["Yue Ling", "Anywhere. That is a big word for a girl who has only seen a bamboo forest and a swamp."]]}]},
	{"id": "t_winter", "after": "s_elder4", "lines": [
		["Narrator", "In Frostpeak's caverns, by a fire that gives more smoke than heat, Yue Ling sits with her knees drawn up."],
		["Yue Ling", "I counted three winters since the pond. Today I counted again and got four. I have lost a winter somewhere, Lin Feng."],
		["Lin Feng", "Maybe you slept through one. I have slept through a few lectures."],
		["Yue Ling", "I dreamed of snow on a lotus pond. A man with a sword sitting by it, waiting for me to wake up. He looked so sad. I think he was the one who lost the winter."]],
		"ask": "What do you say about her dream?",
		"options": [
			{"id": "here", "label": "\"Nobody will wait for you alone again.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Whoever he was, nobody is going to sit waiting by a pond for you again. If you sleep, I will be the one who wakes you."], ["Yue Ling", "By shouting, I expect."], ["Lin Feng", "By cooking. You always wake up for food."]]},
			{"id": "ask", "label": "\"Ask the Elder about it.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "The Elder knows every pond on the mountain. Ask him."], ["Yue Ling", "The Elder looks at me sometimes as if he knows something and is waiting for me to ask the right question. I do not know the question yet."]]},
			{"id": "go", "label": "\"Dreams are roads. Follow it.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "My mother said a dream is a road your feet have not found yet."], ["Yue Ling", "Then my feet are going to have a very long walk."]]}]},
	{"id": "t_chains", "after": "s_f_xu1", "lines": [
		["Yue Ling", "When we found Xu Lan in those silver chains, I could not breathe for a moment. I know what it is to be tied to a post and called property."],
		["Yue Ling", "Iron Fang used to say I was lucky. 'A healer is worth her weight in rice, girl.' As if being worth something were the same as being free."],
		["Lin Feng", "You are not anybody's property now."],
		["Yue Ling", "No. But sometimes I wonder if I am still tied to something, only with a longer rope."]],
		"ask": "What do you say about the rope?",
		"options": [
			{"id": "cut", "label": "\"Then I'll help you cut it.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "If there is a rope, we will find where it is tied and cut it together."], ["Yue Ling", "And if it is tied to you?"], ["Lin Feng", "Then I will untie it, and you can decide whether to walk away."]]},
			{"id": "root", "label": "\"Some ropes are roots.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Not every rope is a chain. A tree is tied to the ground. It does not feel trapped."], ["Yue Ling", "Trees do not get to see the sea, Lin Feng."]]},
			{"id": "run", "label": "\"Go wherever you like. I mean it.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "You can walk away from this road any day you like. I mean it."], ["Yue Ling", "I know. That is exactly why I stay."]]}]},
	{"id": "t_dragon", "after": "s_dr_king", "lines": [
		["Narrator", "The Azure Dragon King swims up out of the rift and away into the deep, and the whole sunken palace sighs as the water clears."],
		["Yue Ling", "He thanked you, Lin Feng. A dragon king. He looked at me as well, as if he knew me, and bowed lower than he bowed to you."],
		["Lin Feng", "Maybe dragons have better manners than sweepers."],
		["Yue Ling", "Maybe. Or maybe a bearer before you freed him once too, and I was there, and only the dragon remembers."]],
		"ask": "What do you say?",
		"options": [
			{"id": "ask", "label": "\"Then we'll ask him, one day. Together.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then one day we come back down here and ask him, the two of us."], ["Yue Ling", "You want to go back into a sunken palace full of hydras to ask a dragon a personal question. You are a very strange sweeper."]]},
			{"id": "honour", "label": "\"Then the sea honours you. That's no small thing.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Then the whole sea honours you. That is a better family tree than most of the sect has."], ["Yue Ling", "The sea as an aunt. I like that."]]},
			{"id": "swim", "label": "\"Then go and find out. Swim after him.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "You could go after him and ask. Dragons like the curious."], ["Yue Ling", "Not today. Today I want to stand somewhere dry. But one day, yes."]]}]},
	{"id": "t_sky", "after": "s_ce_emperor", "lines": [
		["Narrator", "Above the Celestial Gate the sky is cracked like old porcelain. Yue Ling will not stop looking at it."],
		["Yue Ling", "When the Emperor fell, the Seal at your waist went warm against my hand. Not your hand. Mine. Why would it do that?"],
		["Lin Feng", "Maybe it likes you better."],
		["Yue Ling", "Everything likes me better than you, Lin Feng, it is not a high bar. But this was different. It felt like... recognising somebody across a market."]],
		"ask": "What do you say about the Seal?",
		"options": [
			{"id": "share", "label": "\"Then we carry it together.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then it is both of ours. We carry it together."], ["Yue Ling", "Lin Feng, it is a very heavy seal, and you are giving away half of it as if it were a dumpling."]]},
			{"id": "elder", "label": "\"The Elder will know.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "We are going home soon. The Elder will know what it means."], ["Yue Ling", "He will know. Whether he will tell us is a different question."]]},
			{"id": "free", "label": "\"Whatever it is, you are still you.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Whatever it recognised, you are still the girl who threw a pot at Iron Fang's head."], ["Yue Ling", "It was a very good pot. I miss that pot."]]}]},
	{"id": "t_nineteen", "after": "s_ml_xumo", "lines": [
		["Narrator", "The Mirror Lake is still at last. In the water, if you look long enough, the nineteen bearers stand in a row, waiting, the way people wait for a boat."],
		["Yue Ling", "Lin Feng, look at the fourth one. And the ninth. There is somebody standing behind each of them, a little to the left. A girl in rose."],
		["Yue Ling", "It is me. In every reflection. Standing exactly where I stand now, beside you."],
		["Lin Feng", "Then you were never alone either."]],
		"ask": "What do you say?",
		"options": [
			{"id": "left", "label": "\"Stand a little to the left of me, then. Always.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then stand there. A little to the left. It suits you."], ["Yue Ling", "You are very bad at being solemn at a haunted lake, Lin Feng."], ["Lin Feng", "I know."]]},
			{"id": "keep", "label": "\"The lake keeps them. Let it keep you too.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "The lake keeps all of them. It is keeping you too, somewhere. That is not nothing."], ["Yue Ling", "Kept in a lake. I would rather be kept in a person."]]},
			{"id": "step", "label": "\"Then step out of the reflection. Be in the front.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Twenty times a little to the left. Stand in front, for once. See what it is like."], ["Yue Ling", "In front. It is very bright. I am not sure I like it. Ask me again later."]]}]},
	{"id": "t_seal", "after": "s_or_heaven", "lines": [
		["Narrator", "The Origin is quiet now: white stone, slow light. Yue Ling sits on the edge of the place where the Hollow Heaven was, and does not look at him."],
		["Yue Ling", "I am the Seal, Lin Feng. The Founder wove me out of its lotus so that the bearer would never face the end alone. Twenty bearers. I walked beside every one of them, and forgot every one."],
		["Yue Ling", "Everything I thought was mine was a stitch in a pattern somebody else drew. Even liking you. Even that might be the weave."],
		["Lin Feng", "Yue Ling..."],
		["Yue Ling", "So I am going to ask you once, and you must not be kind about it. Do you still want me beside you, now you know what I am?"]],
		"ask": "What do you tell her?",
		"options": [
			{"id": "you", "label": "\"Not the Seal. You.\"", "lean": "companion", "bond": 4, "after": [["Lin Feng", "I never wanted the Seal beside me. I wanted the girl who throws pots. If that was the weave, the weave has very good taste."], ["Narrator", "She laughs so suddenly that it comes out half a sob, and leans her shoulder against his, and stays there."]]},
			{"id": "home", "label": "\"You came from our mountain. That's family.\"", "lean": "lotus", "bond": 3, "after": [["Lin Feng", "You were made on our mountain, by our Founder, out of our pond. That does not make you a tool. It makes you family."], ["Yue Ling", "Family. The sect's oldest relative, and I look twenty. The disciples will have to bow to me."]]},
			{"id": "choose", "label": "\"Weave or not, choose for yourself now.\"", "lean": "wander", "bond": 3, "after": [["Lin Feng", "Maybe the weave chose before. Nobody is weaving now. Whatever you choose from today, it is yours."], ["Yue Ling", "Mine. I do not even know what I want for supper, Lin Feng."], ["Lin Feng", "Then start with supper."]]}]},
	{"id": "t_ageless", "after": "s_p4_home", "lines": [
		["Yue Ling", "Everybody who ever survived a tribulation is ageing by the hour. Disciple Han has grey in his beard. The Elder can hardly stand."],
		["Yue Ling", "And I have not changed at all. Not a line. The Ledger has no column for things that were never born."],
		["Lin Feng", "That is good news, surely."],
		["Yue Ling", "Is it? Everybody I love is going to get old, Lin Feng, and I will stand at the end of every bed looking exactly like this."]],
		"ask": "What do you say?",
		"options": [
			{"id": "grey", "label": "\"Then I'll get old slowly, for you.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then I will cultivate until I am very, very hard to kill, and get old so slowly you will not notice."], ["Yue Ling", "You will still go grey first. I am going to laugh at you."]]},
			{"id": "keep", "label": "\"Someone has to remember us all.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Somebody has to remember all of us. The sect would be lucky if it were you."], ["Yue Ling", "The sect's memory. I would keep it in a very untidy drawer."]]},
			{"id": "live", "label": "\"Then live everything, while you can.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then do everything. See everything. Make the time count, since you have so much of it."], ["Yue Ling", "That is a very cultivator thing to say. I like it more than I should."]]}]},
	{"id": "t_peach", "after": "s_gd_nineteen", "lines": [
		["Narrator", "The nineteen wake under the peach trees with their names back in their mouths, and one by one they walk out of the Garden into the dawn."],
		["Yue Ling", "None of them looked at me, Lin Feng. Not one. I walked beside every one of them and they walked straight past."],
		["Yue Ling", "I suppose that is fair. I did not remember them either. We are even. It does not feel even."]],
		"ask": "What do you say?",
		"options": [
			{"id": "see", "label": "\"I see you. That has to count for something.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "I see you. Every day. That has to count for something against nineteen."], ["Yue Ling", "It counts for a great deal more than nineteen, actually. Do not let it go to your head."]]},
			{"id": "later", "label": "\"They'll remember. Names come back slowly.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "They have only just got their own names back. Give them time. Yours will come to them."], ["Yue Ling", "Maybe at a festival, one day, one of them will look up and frown and say: wait."]]},
			{"id": "own", "label": "\"Then make memories nobody can walk past.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then make some memories of your own. Ones nobody can walk past."], ["Yue Ling", "Loud ones. With fireworks. Yes."]]}]},
	{"id": "t_mend", "after": "s_p5_home", "lines": [
		["Yue Ling", "Nuwa mended the sky with stones of five colours, Lin Feng. Do you think she did it because she had to, or because she could not bear to see it broken?"],
		["Lin Feng", "Is there a difference?"],
		["Yue Ling", "I think there is. I mend people because my hands know how. I do not know yet whether I would do it if they did not."]],
		"ask": "What do you say about mending?",
		"options": [
			{"id": "me", "label": "\"You mended me before you knew me.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "The first thing you ever did for me, tied to a post, was tell me where Iron Fang's guards slept. Your hands were tied. You did it anyway."], ["Yue Ling", "...I had forgotten that. You remember it?"], ["Lin Feng", "I remember everything you do. It is a sweeper's habit."]]},
			{"id": "duty", "label": "\"Mending is what keeps the world up.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Whatever the reason, somebody has to hold the sky up. It might as well be people who care."], ["Yue Ling", "Pillars do not get to care, Lin Feng. They only get to stand."]]},
			{"id": "find", "label": "\"Find out. Mend what you choose.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then find out. Mend what you choose to mend, and leave what you choose to leave."], ["Yue Ling", "That sounds very free and very lonely."]]}]},
	{"id": "t_ancestors", "after": "s_p6_home", "lines": [
		["Narrator", "The dead are queueing at the sect's gate. Every one of them is going home to somebody."],
		["Yue Ling", "I watched the queue all morning. Every ghost had a name to give the gatekeeper, and a village, and somebody's grandmother."],
		["Yue Ling", "If I died, Lin Feng, which queue would I stand in? There is no village for things that were woven."]],
		"ask": "What do you tell her?",
		"options": [
			{"id": "mine", "label": "\"Mine. You'd queue for my house.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Mine. You would give my name at the gate, and they would send you to my house, and I would be very cross that you died."], ["Yue Ling", "You would make me congee. Ghosts can eat congee, I asked."]]},
			{"id": "sect", "label": "\"The sect's. The Founder's line.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "You are the Founder's work. That makes you of her line, and her line is the sect. You have more ancestors than anybody."], ["Yue Ling", "A whole hall of tablets. I shall haunt it."]]},
			{"id": "make", "label": "\"Make a village. Start it.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then start one. Somebody started every village there is."], ["Yue Ling", "A village of one healer and whatever stray dogs follow her. I have seen worse villages."]]}]},
	{"id": "t_mother", "after": "s_p7_home", "lines": [
		["Yue Ling", "We are going to Qingshi Village, Lin Feng. Your village. You never talk about it."],
		["Lin Feng", "There is not much to say. A river, some mulberries, a temple with a leaking roof. My mother hummed while she worked. I was six when the fever came."],
		["Yue Ling", "What did she hum?"],
		["Lin Feng", "I do not know. Something about a boat. I have tried for years to remember the rest."],
		["Yue Ling", "...Something about a boat. Lin Feng, I think I know it."]],
		"ask": "What do you do?",
		"options": [
			{"id": "sing", "label": "Ask her to sing it.", "lean": "companion", "bond": 4, "after": [["Narrator", "She sings it, very softly: a boat on a river, a lantern in the bow, a child asleep under a coat. He has not heard it in fourteen years. He does not trust himself to say anything, so he does not."], ["Yue Ling", "One of the bearers must have sung it to me. Or your mother learned it from the same place. Songs travel."]]},
			{"id": "temple", "label": "\"Sing it at the village temple.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Sing it at the village temple, when we get there. The old women will know the rest."], ["Yue Ling", "Old women always know the rest. It is their great power."]]},
			{"id": "later", "label": "\"Not yet. I'm not ready.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Not yet. One day. Not on the road."], ["Yue Ling", "Then I will keep it for you. I am good at keeping things. It is the forgetting I am bad at."]]}]},
	{"id": "t_bridge", "after": "s_p8_home", "lines": [
		["Yue Ling", "The Weaver and the Herdboy. One night a year on a bridge of magpies, and the rest of the year a whole river of stars between them."],
		["Yue Ling", "Would you do it? Wait a year for one night?"],
		["Lin Feng", "For the right person? I swept steps for three years for a sect that did not know my name."],
		["Yue Ling", "That is not an answer. That is a complaint about the sect."]],
		"ask": "Answer her properly.",
		"options": [
			{"id": "yes", "label": "\"For you? I'd build the bridge myself.\"", "lean": "companion", "bond": 4, "after": [["Lin Feng", "For you I would not wait for magpies. I would build the bridge myself, and badly, and walk across anyway."], ["Narrator", "Yue Ling does not answer. She takes his hand on the old Sky Road, and does not let go until the Ferry."]]},
			{"id": "home", "label": "\"I'd rather nobody had to wait.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "I would rather build a world where nobody has to wait by a river at all."], ["Yue Ling", "That is a very big, very sensible answer. I wanted a small silly one."]]},
			{"id": "free", "label": "\"Love that waits is still love.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "A year apart and one night together is still love. Maybe the best kind: nobody is caged."], ["Yue Ling", "Hm. I will think about that one for a long time."]]}]},
	{"id": "t_noon", "after": "s_p9_home", "lines": [
		["Yue Ling", "Nine days of noon. I have not slept properly since the sun stopped. I keep thinking about the Mother of Suns, sending her children out one by one, every morning, for ever."],
		["Yue Ling", "Do you think she ever wanted one of them to stay home?"]],
		"ask": "What do you say?",
		"options": [
			{"id": "stay", "label": "\"Every mother does.\"", "lean": "companion", "bond": 2, "after": [["Lin Feng", "Every mother does. Mine used to hide my sandals so I could not run off to the river."], ["Yue Ling", "And you went barefoot."], ["Lin Feng", "And I went barefoot."]]},
			{"id": "duty", "label": "\"Someone has to light the world.\"", "lean": "lotus", "bond": 3, "after": [["Lin Feng", "Somebody has to light the world. She raised them for it. Staying home would be its own kind of sadness."], ["Yue Ling", "You sound like the Elder. It is very annoying, because you are right."]]},
			{"id": "go", "label": "\"The best ones come back at night.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "She sends them out and they come back every night. That is not losing them. That is the whole point."], ["Yue Ling", "Out every morning, home every night. Yes. I would like a life like that."]]}]},
	{"id": "t_maps", "after": "s_p10_home", "lines": [
		["Yue Ling", "Cartographer Pei says the Court's maps are all wrong: squares where the land is round, rivers drawn straight because it was tidier."],
		["Yue Ling", "I think I am a map like that, Lin Feng. Somebody drew me very neatly, and the real me is all curves and swamps and places nobody has named."]],
		"ask": "What do you say?",
		"options": [
			{"id": "draw", "label": "\"Let me learn the real map.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then let me learn the real one. Every swamp. I am good with swamps, ask the Marsh Hag."], ["Yue Ling", "The Marsh Hag is dead, Lin Feng."], ["Lin Feng", "Exactly."]]},
			{"id": "land", "label": "\"The land doesn't need a map.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "The land does not care what the map says. It just goes on being itself."], ["Yue Ling", "Like a mountain. Yes. I could be a mountain about it."]]},
			{"id": "name", "label": "\"Name the places yourself.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then go and name the places yourself. Pei would lend you a brush."], ["Yue Ling", "The Bay of Yue Ling. The Mountains of Lin Feng Is Very Slow. I will need a lot of ink."]]}]},
	{"id": "t_choice", "after": "s_p11_home", "lines": [
		["Yue Ling", "You chose a Dao today. Just like that: the Elder said six roads and you picked one, and you could change it at any stele you like."],
		["Yue Ling", "I have never chosen anything, Lin Feng. Not my name, not my hands, not my road. I was made to walk yours."],
		["Lin Feng", "You chose to stay, after the Origin."],
		["Yue Ling", "Did I? Or was that the weave, too? I cannot tell from the inside. That is the worst part."]],
		"ask": "What do you say?",
		"options": [
			{"id": "proof", "label": "\"You argue with me. The weave wouldn't.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "You argue with me about everything. Salt. Stars. My stance. No seal ever woven would bother."], ["Yue Ling", "...That is the most romantic thing anybody has ever said to me and it was about salt."]]},
			{"id": "stele", "label": "\"Then choose at a stele, like me.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "There is a stele in the courtyard. Choose a road. Any road. See how it feels."], ["Yue Ling", "I touched it this morning, when nobody was looking. It went warm, and showed me a lotus. I do not think that is one of the six."]]},
			{"id": "time", "label": "\"There'll be a day you choose. I'll wait.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "One day something will happen that is only yours to choose, and you will know it. I will wait for that day with you."], ["Yue Ling", "Promise?"], ["Lin Feng", "Promise."]]}]},
	{"id": "t_heaven", "after": "s_jt_leigong", "lines": [
		["Narrator", "Above the aeries of Juntian the thunder stops, and the Feathered Folk come out of their towers to look at a sky that is, for once, only a sky."],
		["Yue Ling", "We are standing in heaven, Lin Feng. Actual heaven. When I was a girl, or whatever I was, I thought heaven would be quiet."],
		["Yue Ling", "It is full of birds arguing about whose turn it is to sweep the terraces. I have never liked anywhere so much."]],
		"ask": "What do you say?",
		"options": [
			{"id": "here", "label": "\"Heaven is wherever you're arguing with me.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Heaven is wherever you are arguing with me about something unimportant."], ["Yue Ling", "That is the worst line anybody has ever said in heaven. Say it again."]]},
			{"id": "home", "label": "\"Our sect is louder. And it's home.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "The sect is louder than this, and it has worse food, and it is home."], ["Yue Ling", "Home is louder than heaven. I am going to embroider that on something."]]},
			{"id": "stay", "label": "\"Stay a while. The birds would have you.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Stay a while, if you like. The Feathered Folk would adopt you by the end of the week."], ["Yue Ling", "They have already offered. Twice. I said I would think about it."]]}]},
	{"id": "t_sea", "after": "s_p12_home", "lines": [
		["Yue Ling", "The sea has gone, Lin Feng, and the first thing I thought was: but I never saw it."],
		["Yue Ling", "Three hundred years of bearers and not one of them took me to the sea. Or they did, and I forgot. I do not know which is worse."]],
		"ask": "What do you say?",
		"options": [
			{"id": "take", "label": "\"I'll take you when it comes back.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "When the sea comes back, the very first morning, I will take you down to it, and you can stand in it up to your knees and complain that it is cold."], ["Yue Ling", "I will complain. I will complain magnificently."]]},
			{"id": "pond", "label": "\"Our pond is a small sea.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "The sect's pond is a very small sea. It has fish. It has a tide when the Elder wades in."], ["Yue Ling", "Lin Feng. That is not the same, and you know it is not the same, and I love you a little for saying it anyway."]]},
			{"id": "sail", "label": "\"Mazu has a boat. Go and see.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Mazu has a boat that goes to the edge of the world. Go and see where it went."], ["Yue Ling", "Alone? No. With you. But I like that you said go."]]}]},
	{"id": "t_xufu", "after": "s_gx_xufu", "lines": [
		["Narrator", "Xu Fu sits on the lip of the Returning Ruins with his three thousand children's names in his lap, and weeps, and the sea starts to come home."],
		["Yue Ling", "He sailed away to find a cure for death, Lin Feng, and found three thousand children instead, and never once noticed which one was the cure."],
		["Yue Ling", "I keep thinking about it. Everybody is looking for something to make them last for ever. Nobody looks at what is right in front of them, lasting."]],
		"ask": "What do you say?",
		"options": [
			{"id": "front", "label": "\"I'm looking. At what's in front of me.\"", "lean": "companion", "bond": 4, "after": [["Lin Feng", "I am looking at what is in front of me."], ["Narrator", "She does not say anything for the whole walk back to Landfall, but she walks very close, and she is smiling at the sand."]]},
			{"id": "children", "label": "\"The Thousand Children were his for ever.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "His children were his for ever, and he did not know it. Landfall is what lasts."], ["Yue Ling", "A town is a kind of for ever. Yes. I could live with that kind."]]},
			{"id": "cure", "label": "\"There's no cure. Just going on.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "There is no cure. There is just going on, and seeing as much as you can on the way."], ["Yue Ling", "Going on. Yes. That is the only immortality I want."]]}]},
	{"id": "t_war", "after": "s_p13_home", "lines": [
		["Yue Ling", "Eight gates and a war god behind them. I am frightened, Lin Feng. I am not supposed to be. Seals do not get frightened."],
		["Yue Ling", "But the war god's grave makes my hands shake. As if one of the bearers fell in a war, and I sat with him at the end."]],
		"ask": "What do you say?",
		"options": [
			{"id": "hold", "label": "Take her hands until they stop shaking.", "lean": "companion", "bond": 3, "after": [["Narrator", "He takes her hands and holds them until they stop. It takes a long time. Neither of them minds."], ["Yue Ling", "Better. Do not tell the Elder I needed that."]]},
			{"id": "stay", "label": "\"Stay at the sect this time.\"", "lean": "lotus", "bond": 1, "after": [["Lin Feng", "Stay at the sect for this one. Nobody would blame you."], ["Yue Ling", "I would blame me. Ask me something else."]]},
			{"id": "brave", "label": "\"Frightened is how the brave feel.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Frightened is how brave feels from the inside. Nobody told you that, because nobody tells anybody."], ["Yue Ling", "Then I am very, very brave at the moment."]]}]},
	{"id": "t_threads", "after": "s_p14_home", "lines": [
		["Narrator", "Threads on his wrists, fine as spider silk, running out over the edge of the mountain. Yue Ling holds up her own wrists in the evening light and turns them over."],
		["Yue Ling", "Nothing. Not one thread. You have hundreds, Lin Feng. Iron Fang, the Hag, the boy with the knife, every ghost in the queue. I was there for all of it, and none of it is tied to me."],
		["Yue Ling", "The Elder says a thread is a cause that comes home. I suppose nothing I did ever counted as mine. It all went in your column."],
		["Lin Feng", "That cannot be right."],
		["Yue Ling", "It is very tidy, though. The Wheel does like things tidy."]],
		"ask": "What do you say?",
		"options": [
			{"id": "tie", "label": "Tie a thread from your own wrist to hers.", "lean": "companion", "bond": 4, "after": [["Narrator", "He pulls a thread from his sleeve, a plain red cotton one, and ties one end round his wrist and the other round hers. It is not karma. It is cotton. She does not take it off."], ["Yue Ling", "That is not how it works, Lin Feng."], ["Lin Feng", "It is how it works now."]]},
			{"id": "count", "label": "\"Everything I did, you did with me.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Half of every thread on my wrists is yours. I will tell the Wheel so myself."], ["Yue Ling", "The Wheel will say it has no column for that."]]},
			{"id": "own", "label": "\"Then let's go and make you some.\"", "lean": "wander", "bond": 3, "after": [["Lin Feng", "Then when this is over we go and make you some. Threads of your own. A whole wrist of them."], ["Yue Ling", "A whole wrist. I would rattle when I walked."]]}]},
	# ---- Part XV: on the road to a page of her own
	{"id": "t_page", "after": "s_p15_judge", "lines": [
		["Narrator", "On the funeral road back from the Wheel, Yue Ling walks a little ahead, and keeps looking at her hands as if they might not be there."],
		["Yue Ling", "A page in the Book of Life and Death. Do you know what that means, Lin Feng? It means one day there would be a last line on it. I would be able to die."],
		["Lin Feng", "You say that as if it were a gift."],
		["Yue Ling", "It is. Everything that lives can die. That is how you know it was alive. Twenty times I came back out of that pond and none of it was ever mine to lose."]],
		"ask": "What do you say?",
		"options": [
			{"id": "long", "label": "\"Then we make it a very long page.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then we make it a very long page. So long Judge Cui has to send for more paper."], ["Yue Ling", "He would complain. He would complain beautifully. I would like to hear it."]]},
			{"id": "here", "label": "\"Whatever's on it, write it here, at home.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Whatever goes on it, let most of it happen here. On the mountain. With us."], ["Yue Ling", "A page full of the sect. Sweeping, and arguing with Mo, and cats. It would be a very good page."]]},
			{"id": "full", "label": "\"Fill it with everywhere.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then fill it with everywhere. Every road, every town, every sea you never saw."], ["Yue Ling", "It would need a map in the margin."]]}]},
	{"id": "t_qinglian", "after": "s_p15_founder", "lines": [
		["Yue Ling", "She said mother is a name you earn by staying. Lin Feng, she made me and then she died. Was that leaving? She could not help it."],
		["Yue Ling", "And then I think of your mother humming in the mulberries, and the fever, and you at six. She did not choose to go either. You still miss her."],
		["Lin Feng", "Every day."],
		["Yue Ling", "Then maybe staying is not about being there. Maybe it is about being missed."]],
		"ask": "What do you say?",
		"options": [
			{"id": "missed", "label": "\"You'd be missed. By me, first.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "If you went, you would be missed every day by somebody who swept the steps for three years without ever being missed once. I know what it costs. I would pay it."], ["Yue Ling", "Do not say things like that when I am already crying about my mother, Lin Feng. It is not fair."]]},
			{"id": "mother", "label": "\"Call her mother. She'd like it.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Call her mother anyway. She is a needle and a habit, she said. Habits like to be called by their names."], ["Yue Ling", "Mother Qing Lian. It sounds like a temple. She would hate it. I am going to say it every time."]]},
			{"id": "go", "label": "\"Then be the one who comes back.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then be somebody who goes away and comes back. Every time. That is a kind of staying too."], ["Yue Ling", "Out every morning, home every night. You keep giving me that. I think I am starting to want it."]]}]},
	{"id": "t_loom", "after": "s_p15_loom", "lines": [
		["Narrator", "They come out of the hermitage through the round moon gate into the evening. Yue Ling stops in the middle of the gate, as if she were a picture in a frame."],
		["Yue Ling", "She built the door round, Lin Feng. A round door has no top and no bottom. You cannot tell from the shape of it whether you are coming in or going out."],
		["Yue Ling", "I think she meant it for me. I think she knew I would have to decide which."]],
		"ask": "What do you say?",
		"options": [
			{"id": "through", "label": "\"Walk through it with me. Either way.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Walk through it with me, then. In or out. We can decide on the other side."], ["Yue Ling", "That is cheating. I accept."]]},
			{"id": "in", "label": "\"In. This is a house that wants somebody in it.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "In, I think. It is a house that has been waiting three hundred years for somebody to come in."], ["Yue Ling", "It does have a very good bath."]]},
			{"id": "out", "label": "\"Out. Doors are for going through.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Out. A door is for going through, not for standing in."], ["Yue Ling", "And coming back through. Do not forget the coming back."]]}]},
	{"id": "t_twenty", "after": "s_p15_memories", "lines": [
		["Yue Ling", "Ah Zhu and her terrible flute. Old Jiang and his lanterns. Bai Shan who could not sleep. Chun and her kite. They are mine now, Lin Feng. I can feel them, like stones in a pocket."],
		["Yue Ling", "And all of them are gone. Every person I ever loved before you is three hundred years dead. I got them back just in time to miss them."],
		["Lin Feng", "Is it worse? Having them back?"],
		["Yue Ling", "No. No, it is much better. Grief is only love with nowhere to go. Now it has somewhere."]],
		"ask": "What do you say?",
		"options": [
			{"id": "share", "label": "\"Tell me about them. All of them.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then tell me about them. Every one. On the road, at night, whenever you want. I want to know who walked here before me."], ["Yue Ling", "It will take a very long time."], ["Lin Feng", "Good."]]},
			{"id": "tablets", "label": "\"Put their names in the ancestral hall.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Twenty bearers. The sect should have twenty tablets for them in the ancestral hall, and you should be the one who lights the incense."], ["Yue Ling", "Twenty tablets. Twenty-one, one day. Not soon."]]},
			{"id": "graves", "label": "\"Visit where they're buried.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then go and find where they are buried, every one, and tell them you remember."], ["Yue Ling", "A pilgrimage. Twenty graves. I would like that very much."]]}]},
	{"id": "t_moths", "after": "s_p15_moth", "lines": [
		["Yue Ling", "The Moth-Queen said nothing hurts once it is gone. She believed it, Lin Feng. She was trying to be kind."],
		["Yue Ling", "And I was tempted. For a breath. No more waking in the reeds with nothing. No more missing people I cannot remember. Just... quiet."],
		["Lin Feng", "And now?"],
		["Yue Ling", "Now I have Ah Zhu's terrible flute in my head and I would not give it up for all the quiet in the world."]],
		"ask": "What do you say?",
		"options": [
			{"id": "keep", "label": "\"Keep every terrible flute. I'll help carry them.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Keep all of it. If it gets heavy, hand me some. I carried a broom for three years; I can carry a flute."], ["Yue Ling", "It is a very heavy flute, emotionally."]]},
			{"id": "rest", "label": "\"Quiet is allowed too, sometimes. At home.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "You can have quiet without forgetting. That is what home is for: the pond, the steps, the evening."], ["Yue Ling", "Quiet with everything still in it. Yes. That is a different thing."]]},
			{"id": "more", "label": "\"Then go and get more to remember.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then go and get more of it. More flutes. More people. More things nobody should forget."], ["Yue Ling", "A collector of terrible flutes. That could be my title."]]}]},
	{"id": "t_wrist", "after": "s_p15_threads", "lines": [
		["Narrator", "Green silk, grey horsehair, red cotton, red mast-thread, blue scroll-silk: Yue Ling keeps turning her wrist over to look at them, as if they might have gone while she was not watching."],
		["Yue Ling", "They remembered me, Lin Feng. Mo remembered the pill I corrected. Fang Hu remembered I made him eat. Nobody remembered me as the Seal. They remembered me as me."],
		["Yue Ling", "I did not know that was possible. I thought everything I did belonged to whoever carried the root."]],
		"ask": "What do you say?",
		"options": [
			{"id": "mine", "label": "\"It was always you. I just got the credit.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "It was always you. Half the things people thank me for, you did while I was busy hitting something."], ["Yue Ling", "More than half."], ["Lin Feng", "More than half."]]},
			{"id": "family", "label": "\"That's what a family is. People who remember you.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "That is all a family is. People who remember what you did for them, and tie something on your wrist about it."], ["Yue Ling", "A very large, very strange family. With a horse in it."]]},
			{"id": "more", "label": "\"Imagine how many more you'll have.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Five threads in a month. Imagine a year. Imagine ten."], ["Yue Ling", "I would have to wear them on both arms. And my ankles. I would jingle."]]}]},
	{"id": "t_after", "after": "s_p15_warden", "lines": [
		["Narrator", "Lotus seeds are still drifting down into the pond where the Warden went. Yue Ling sits on the edge of the Last Cave's step with her chin on her knees."],
		["Yue Ling", "It only wanted to keep me safe. Three hundred years of keeping. I think it loved me, in the way a box loves what is in it."],
		["Yue Ling", "Lin Feng. Promise me something. Whatever I write on that page tomorrow, do not keep me. Not like that. Not even to keep me safe."]],
		"ask": "What do you promise?",
		"options": [
			{"id": "never", "label": "\"Never. I'll walk beside you, not in front.\"", "lean": "companion", "bond": 4, "after": [["Lin Feng", "Never. I will walk beside you, not in front of you and not behind you, for as long as you want somebody beside you."], ["Yue Ling", "That might be a very long time, sweeper."], ["Lin Feng", "I have time."]]},
			{"id": "door", "label": "\"The door stays open. Always.\"", "lean": "lotus", "bond": 3, "after": [["Lin Feng", "The sect's door is open. It always will be. Go out of it, come back through it, sit on its step. Nobody will ever lock it again."], ["Yue Ling", "An open door. Yes. That is what a home is, I think. Not walls. A door somebody leaves open for you."]]},
			{"id": "free", "label": "\"Go wherever your page goes.\"", "lean": "wander", "bond": 3, "after": [["Lin Feng", "Go wherever the page takes you. I will not hold the string. I learned that from a kite."], ["Yue Ling", "From Chun's kite. You remembered."]]}]},
	{"id": "t_feast", "after": "s_p15_feast", "lines": [
		["Narrator", "Late, when the lanterns are guttering and Auntie Zhou has finally sat down, Yue Ling finds Lin Feng sitting on the edge of the stage with his sword across his knees."],
		["Yue Ling", "Forty-one people sang to me tonight, Lin Feng. Forty-one. Disciple Han cried. The cat sat on my lap for an hour and would not move."],
		["Yue Ling", "For three hundred years I was the thing that kept somebody else alive. Tonight they had a party because I am."],
		["Lin Feng", "Happy birthday, Yue Ling."]],
		"ask": "What do you say next?",
		"options": [
			{"id": "every", "label": "\"Every year. I'll remember the date.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Every year, on this night. I will remember the date. I will make you eat two bowls of noodles."], ["Yue Ling", "You will burn the noodles."], ["Lin Feng", "I will burn them with love."]]},
			{"id": "here", "label": "\"The sect will never forget it now.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "The sect will never forget it now. Han will tell the new disciples about the night the healer was born."], ["Yue Ling", "He will get it wrong. He will say there was a dragon."], ["Lin Feng", "There should have been a dragon."]]},
			{"id": "next", "label": "\"Where do you want your next birthday?\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Where do you want your next one? Penglai? The moon? The bottom of the sea?"], ["Yue Ling", "All three. In that order."]]}]},
	# ---- Part XVI (the Living Land release): her first New Year, and the night that would not end
	{"id": "t_newyear", "after": "s_p16_kitchen", "lines": [
		["Yue Ling", "Lin Feng, every New Year before this one I was somewhere else. Some years I was a girl in a village nobody remembers. Some years I was a lotus in the pond, and the snow fell on me."],
		["Yue Ling", "I can remember the snow. I cannot remember anybody ever putting a dumpling in my bowl."],
		["Lin Feng", "Auntie Zhou will put twelve in your bowl. You will not be able to stop her."],
		["Yue Ling", "Good. I want to be fed until I complain. I want to complain about it to somebody who laughs."],
		], "ask": "What do you promise her for the New Year?",
		"options": [
			{"id": "bowl", "label": "\"I'll fill your bowl myself.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "I will fill your bowl myself, and laugh every time you complain."], ["Yue Ling", "That is a very specific vow. I accept it."]]},
			{"id": "snow", "label": "\"We'll watch the snow together.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "We will watch the snow from the steps, together, with something hot."], ["Yue Ling", "From the steps. Like the lotus, but warmer. Yes."]]},
			{"id": "towns", "label": "\"Every town's New Year with you.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "We will see how every town does it: lanterns in Yanggu, bells in Tushan, carp in the windows at Longmen."], ["Yue Ling", "Every town in one week? Lin Feng, that is the best idea you have ever had."]]},
		]},
	{"id": "t_hunger", "after": "s_p16_lean", "lines": [
		["Yue Ling", "I knew a winter like that once. The ninth bearer's village, before he was a ferryman. The Lean Month came, and his mother gave him her rice and said she had eaten already."],
		["Yue Ling", "She had not eaten already. I knew, and he knew, and nobody said so. That is what I remember: the three of us at the table, all pretending, so that the pretending would be enough."],
		["Lin Feng", "Granny Wen used to do that. Every winter. I always knew."]],
		"ask": "What do you say about the hungry winters?",
		"options": [
			{"id": "never", "label": "\"Nobody goes hungry on our mountain.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Then nobody goes hungry on our mountain again. Not while Auntie Zhou has a stove."], ["Yue Ling", "Not while she has a stove. That is a vow I believe."]]},
			{"id": "share", "label": "\"I'll always say I've eaten.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "If there is ever only one bowl, I will say I have eaten already."], ["Yue Ling", "And I will know, and I will not say so. That is how it works, isn't it?"]]},
			{"id": "feed", "label": "\"Then let's feed every village.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then in spring we carry rice to every village that had a lean month."], ["Yue Ling", "Every village? That is a lot of rice. I will start a list."]]},
		]},
	{"id": "t_lastnight", "after": "s_p16_xi", "lines": [
		["Yue Ling", "The night is not moving, Lin Feng. The stars have been in the same place for hours. Is this what it was like, the nine days of noon? Only dark?"],
		["Lin Feng", "At noon nobody could sleep. Tonight nobody wants to."],
		["Yue Ling", "I do not mind it. That is the strange part. If the night will not end, then we only have more of it."],
		], "ask": "What do you say to her in the long night?",
		"options": [
			{"id": "stay", "label": "\"Then let's not waste it.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Then let us not waste it."], ["Yue Ling", "...You have become dangerously good at saying things, sweeper."]]},
			{"id": "home", "label": "\"Everybody home first.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Let us get everybody home first. Then we can have all the night we want."], ["Yue Ling", "Everybody home. Yes. That is what tonight is for."]]},
			{"id": "stars", "label": "\"Name me the stars.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "While they hold still, name me some stars."], ["Yue Ling", "That one is the Sweeper. That one is the Dumpling. That one is you, being slow."]]},
		]},
	{"id": "t_newday", "after": "s_p16_dawn", "lines": [
		["Yue Ling", "Lin Feng. It is a new year, and I am in it. Last New Year I was a lotus nobody remembered. Now I have a page, and a bowl, and a door with my name spelt wrong on it."],
		["Yue Ling", "What do people do on the first morning of a year? I want to do it properly."],
		["Lin Feng", "They put on new clothes, they go round wishing everybody a good one, and they do not sweep, whatever happens."],
		["Yue Ling", "Then I am wearing red, and you are coming with me, and if you so much as look at a broom I am telling Little Bai."]],
		"ask": "What do you say on the first morning of her first year?",
		"options": [
			{"id": "red", "label": "\"Red suits you.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Red suits you."], ["Yue Ling", "Everything suits me today. It is my first morning. I could wear a cabbage."]]},
			{"id": "round", "label": "\"Let's go round the sect.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Let us go round the sect, then. Everybody. Auntie Zhou first, or she will never forgive us."], ["Yue Ling", "Auntie Zhou first. Then everybody. Then Auntie Zhou again, for seconds."]]},
			{"id": "out", "label": "\"And then down the mountain.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "And then down the mountain, to see how the towns did it."], ["Yue Ling", "Every town's first morning. Yes. Bring the red envelopes."]]},
		]},
	# ---- Part XVII (the Spring Thunder release): spring, the first thunder and Qingming
	{"id": "t_spring", "after": "s_p17_goumang", "lines": [
		["Yue Ling", "Lin Feng, I have been every season, but never on purpose. Some springs I was a girl in a village. Some I was a lotus under the ice, waiting. I always woke up in spring. I never once saw it come."],
		["Yue Ling", "I want to see it come this year. All of it. The first green, the first frog, the first swallow. I want to be there when it gets here, and say hello."],
		["Lin Feng", "Then we will carry it in ourselves, since it is too tired to walk."]],
		"ask": "What do you promise her about the spring?",
		"options": [
			{"id": "first", "label": "\"We'll see every first thing together.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Every first thing. The first green, the first frog, the first swallow. Together."], ["Yue Ling", "I am going to keep a list. You are not allowed to see anything first without me."]]},
			{"id": "pond", "label": "\"We'll watch the pond thaw.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Then we will sit by your pond every morning until the ice goes."], ["Yue Ling", "And the lotus comes up. Mine. It will be very proud of itself."]]},
			{"id": "follow", "label": "\"We'll follow it across the land.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Spring goes north a day's walk at a time. We could walk with it."], ["Yue Ling", "All the way north. Yes. I want to see where it ends up."]]},
		]},
	{"id": "t_thunder", "after": "s_p17_thunder", "lines": [
		["Yue Ling", "When the thunder rolled, everything under the ground woke up at once. I felt it in my feet. Seeds, worms, beetles, the frogs in the paddies, all of them stretching."],
		["Yue Ling", "Lin Feng, I think I woke up too. Not the way I used to, by a pond, new and empty. Like somebody who has slept a long time in her own bed and remembers everything, and is glad."],
		["Lin Feng", "Then good morning, Yue Ling."]],
		"ask": "What do you say to her, the morning after the first thunder?",
		"options": [
			{"id": "glad", "label": "\"I'm glad it's you who woke.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "I am glad it was you who woke up. Out of everything."], ["Yue Ling", "Out of every beetle in the land? That is a very high compliment."]]},
			{"id": "bed", "label": "\"Your own bed. On our mountain.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Your own bed, on our mountain. That is where you woke."], ["Yue Ling", "On our mountain. I like how you say it. Our."]]},
			{"id": "go", "label": "\"Then where shall we go first?\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Awake, then. So where first?"], ["Yue Ling", "Everywhere the thunder reached. That is all of it. We had better start early."]]},
		]},
	{"id": "t_soil", "after": "s_p17_taisui", "lines": [
		["Yue Ling", "Lin Feng. You said sorry to the ground. To a thing under the ground with a hundred eyes that wanted to eat the village, you said: we are sorry to be digging, and we will be careful."],
		["Yue Ling", "When I was the Seal, every bearer before you broke something to get where he was going. Mountains, doors, people. Not one of them ever said sorry to the thing he broke."],
		["Lin Feng", "I was a sweeper for three years. You learn to say sorry to the floor."]],
		"ask": "What do you tell her about the things you broke this spring?",
		"options": [
			{"id": "careful", "label": "\"I'll be more careful with you than with anything.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "Whatever I break, I will never be careless with you."], ["Yue Ling", "You are already the least careless person I know. It is very annoying. Thank you."]]},
			{"id": "mend", "label": "\"Everything we broke, we'll mend.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "Everything we broke this spring we will mend: the roads, the channels, the bridge at Longmen."], ["Yue Ling", "And Taisui's sleep. We owe him a quiet year."]]},
			{"id": "light", "label": "\"Walk lightly, wherever we go.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "Then we walk lightly, wherever we go next. Leave nothing broken behind us."], ["Yue Ling", "Walk lightly. Yes. That is a good rule for a road."]]},
		]},
	{"id": "t_qingming", "after": "s_p17_graves", "lines": [
		["Yue Ling", "Lin Feng. Qingming is for sweeping the graves of the people who came before you. I have none. The Founder was not my mother, not really. The bearers were not my family. I am the first of mine."],
		["Yue Ling", "Who will sweep for me, one day? Do you think anybody will?"],
		["Lin Feng", "..."]],
		"ask": "What do you tell her?",
		"options": [
			{"id": "me", "label": "\"I will. Every year.\"", "lean": "companion", "bond": 3, "after": [["Lin Feng", "I will. Every year, for as long as there are years, and then I will haunt somebody into doing it."], ["Yue Ling", "You would make a terrible ghost. You would apologise to everybody you frightened."]]},
			{"id": "sect", "label": "\"The whole sect will.\"", "lean": "lotus", "bond": 2, "after": [["Lin Feng", "The whole sect will. Little Bai will sweep it every morning. He sweeps everything."], ["Yue Ling", "Little Bai will sweep it whether I am in it or not. That is very comforting."]]},
			{"id": "first", "label": "\"You'll be the first of a long line.\"", "lean": "wander", "bond": 2, "after": [["Lin Feng", "You are the first of yours. There will be a great many people one day who sweep a grave and say: she was the first."], ["Yue Ling", "The first of a long line. Then I had better do something worth sweeping for."]]},
		]},
]

static func talk(id: String) -> Dictionary:
	for tk in TALKS:
		if str(tk.id) == id:
			return tk
	return {}

static func talk_option(id: String, oid: String) -> Dictionary:
	for o in talk(id).get("options", []):
		if str(o.id) == oid:
			return o
	return {}

## where in the quest chain each talk's and wish's step stands (Data.step_index is a search)
static var _idx := {}

static func _done(g, sid: String) -> bool:
	if not _idx.has(sid):
		_idx[sid] = Data.step_index(sid)
	return int(g.step) > int(_idx[sid])

## The heart-to-heart she wants to have now: the oldest one the story has opened that has not been
## had ("" for none).  Only while she is with him.
static func talk_ready(g) -> String:
	if not g.companion:
		return ""
	for tk in TALKS:
		if not g.talks.has(str(tk.id)) and _done(g, str(tk.after)):
			return str(tk.id)
	return ""

## How many heart-to-hearts the story has opened so far.
static func talks_open(g) -> int:
	var n := 0
	for tk in TALKS:
		if _done(g, str(tk.after)):
			n += 1
	return n

## A reply given: remembered, and what it means for her heart and their closeness.
static func take_talk(g, id: String, o: Dictionary) -> void:
	g.talks[id] = str(o.id)
	lean(g, str(o.get("lean", "")), 2)
	add(g, int(o.get("bond", 1)), "a heart-to-heart")
	g.note("A heart-to-heart with Yue Ling: %s" % str(o.label))

# ---------------------------------------------------------------- what she says about where they are
const REGION := {
	"sect": "Home. The steps look shorter every time we come back. You keep sweeping them, that is why.",
	"mountain": "Cloudfoot smells of noodles and horses. I could live on that smell.",
	"bamboo": "This is where you found me. I still flinch at the sound of a crossbow, but the bamboo sings now.",
	"marsh": "The marsh is quieter since the Hag. The frogs have started telling each other jokes again.",
	"frost": "My breath freezes before it leaves my mouth. Lend me your sleeve, sweeper.",
	"thunder": "Every hair on my arms is standing up. If I start glowing, push me in a river.",
	"palace": "The Blood Moon Palace has more stairs than the sect. Somebody really wanted to be looked up to.",
	"dragon": "We are walking on the bottom of the sea, Lin Feng, and nobody is drowning. I will never get used to it.",
	"volcano": "Ash in my hair, ash in my tea. The Ashen Volcano is very committed to its name.",
	"void": "Do not let go of my hand here. I mean it. There is nothing underneath.",
	"celestial": "So this is where the Heavens kept their gate. It is smaller than I expected. Arrogant people often are.",
	"mirror": "The lake shows me a different face every time. I am trying to decide which one I like.",
	"grave": "Ten thousand swords and every one of them was somebody's. Walk softly here.",
	"time": "The river runs both ways at once. I keep remembering tomorrow and forgetting yesterday.",
	"origin": "Everything started here. Including, it turns out, me.",
	"cloudsea": "We are walking on clouds and I am worried about my shoes. Is that strange?",
	"court": "Every stone here was a judgement. I keep wanting to apologise to the floor.",
	"forge": "Every bolt of lightning that ever struck you was hammered here. I want to kick the anvils.",
	"garden": "The peaches smell like the first day of spring. I keep stealing one. Do not tell the Keeper.",
	"dunes": "The sand sings at night. The nomads say it is the fallen stars asking the way home.",
	"fungal": "Everything here glows. Even my sleeves. I look like a festival.",
	"aurora": "The sky is breathing green and red. I did not know the sky could be this beautiful and this cold.",
	"chaos": "Nothing here has decided what it is yet. I know the feeling.",
	"maple": "The maples are red all year round here. The lantern monk says they remember.",
	"karst": "Stone trees, a whole forest of them. Nobody planted them and nobody will cut them. I like that.",
	"springs": "The red lilies bloom where the dead cross over. I keep looking for somebody I know.",
	"wheel": "The Wheel turns so slowly. Every soul that ever lived went round it. Every one but me.",
	"village": "Your village. Your river. I can see you here at six, barefoot, being trouble.",
	"terraces": "The tea pickers sing in a round, hill to hill. I want to learn every song.",
	"silk": "The silkworms are so loud when they eat. A whole forest, chewing.",
	"loom": "The Loom of Borders. Every thread a road. I am trying not to look for mine.",
	"starferry": "The river is full of stars. I put my hand in and one of them nibbled it.",
	"magpie": "Magpies everywhere. They keep looking at us as if they know something.",
	"starpalace": "The Weaver's palace. Everything is woven, even the doors. I feel very at home and very strange.",
	"jasper": "The Queen Mother's pool. I have never seen water so green, or so proud of itself.",
	"yanggu": "The Dawn Market! Lin Feng, they are selling candied hawthorn and I have no money, which is your fault.",
	"millet": "The millet is coming back. The farmers have started arguing about the weather again. That is how you know.",
	"fusang": "The sun tree. Its leaves are warm to the touch, like a cheek.",
	"guanghan": "The moon palace is so cold and so quiet. I would not want to live here. I would want to visit often.",
	"longmen": "Carp jumping at the Dragon Gate, all day, every day. Most of them fall back. They keep jumping.",
	"drowned": "Fields under water and frogs in the furrows. The farmers row to their rice now.",
	"tushan": "The cauldron-casters' town. Everybody here has burnt eyebrows and very loud opinions.",
	"buzhou": "The broken pillar. Look how high it went, Lin Feng. It held up heaven once.",
	"juntian": "We are standing in heaven. Literally. The Feathered Folk keep asking if I have wings under my sleeves.",
	"changhe": "The Gate of Heaven, and foxes everywhere. One of them stole my hairpin and gave it back with a flower.",
	"ninesprings": "The roots of the Jianmu drink from these springs. It is so quiet down here you can hear them swallow.",
	"youdu": "The Dark Capital. The shades are very polite. They keep offering me lanterns.",
	"penglai": "The Isle of the Immortals! It smells of salt and wine and somebody's cooking. I love it already.",
	"fangzhang": "The immortals' gardens. Every herb I have ever read about, growing in rows like cabbages.",
	"yingzhou": "The mists keep making shapes of people I almost remember. I wish they would stop. I wish they would stay.",
	"guixu": "The Returning Ruins. Everything that was ever lost ends up here. I keep looking at the sea floor for my winter.",
}
## when she has nothing to say about where they are (or is somewhere upstairs or in a cellar)
const IDLE := ["Mm? No, nothing. I just like walking beside you.", "You have a leaf in your hair. No, leave it, it suits you.",
	"Are you hungry? I am hungry. I am always hungry when you look that serious.", "Shall we sit somewhere? Anywhere. A bench, a rock, a pavilion. Your choice.",
	"I was counting your scars earlier. You have three new ones this month. Be more careful, please."]

## A word from her (T with no heart-to-heart waiting): about where they are, or something idle.
static func chat(g, area: String, n: int) -> String:
	var opts: Array = []
	if REGION.has(area):
		opts.append(REGION[area])
	opts.append(IDLE[(n + absi(hash(area))) % IDLE.size()])
	var w := wishes_open(g)
	if not w.is_empty():
		opts.append(str(wish(str(w[0])).ask))
	return str(opts[n % opts.size()])

# ---------------------------------------------------------------- her wishes
const WISHES := [
	{"id": "w_bench", "after": "s_yue", "kind": "bench", "ask": "Can we sit somewhere a while? My feet still think they are tied to a post.", "done": "Her feet stop thinking about the post. She says thank you to the bench, formally."},
	{"id": "w_tea", "after": "s_antidote", "kind": "tea", "ask": "Pour me a cup of tea somewhere? A real one, not marsh water.", "done": "She holds the cup in both hands and closes her eyes, and for once has nothing to say."},
	{"id": "w_bell", "after": "s_elder3", "kind": "bell", "ask": "I want to hear one of those great temple bells up close. Right underneath. Is that allowed?", "done": "She stands under the bell until the very last of the hum is gone, then asks him to do it again."},
	{"id": "w_fish", "after": "s_dr_intro", "kind": "fishing", "ask": "Teach me to fish? I have healed fishermen but I have never caught anything.", "done": "She catches nothing. She is delighted. She says the fish were all very rude."},
	{"id": "w_qin", "after": "s_p3_home", "kind": "qin", "ask": "Play the qin for me somewhere, and I will play the flute. I think I know how. I think I always knew.", "done": "His qin and her flute find each other on the third phrase, and do not lose each other again."},
	{"id": "w_swing", "after": "s_p4_home", "kind": "swing", "ask": "There are swings in the villages. I have never been on one. Push me? No, you go first, I want to watch.", "done": "She pushes him so high he yelps, and laughs until she has to sit down."},
	{"id": "w_koi", "after": "s_p5_home", "kind": "koi", "ask": "Can we feed the fish in a pond somewhere? The fat old ones. I like the fat old ones.", "done": "The fattest old carp takes crumbs from her fingers. She names him after the Elder."},
	{"id": "w_pavilion", "after": "s_p6_home", "kind": "pavilion", "ask": "Sit with me in one of those pavilions in the hills. The ones people build only for looking at things.", "done": "They look at things. It is a very good afternoon."},
	{"id": "w_lantern", "after": "s_p7_home", "kind": "sky_lantern", "ask": "Let's send up a sky lantern. One each. We can write wishes and not tell.", "done": "Two lanterns go up together. She will not tell him what she wrote. He finds out years later."},
	{"id": "w_stars", "after": "s_p8_home", "kind": "armillary", "ask": "Lie in the grass with me one night and name the stars? I want to know which ones are real.", "done": "She names the stars. All of them are real, she says, especially the ones she made up."},
	{"id": "w_dance", "after": "s_p9_home", "kind": "lantern_green", "ask": "Dance with me under lanterns. Somewhere with a green and red lanterns on strings. Do not pull that face.", "done": "He pulls the face. He dances anyway. She says he is getting better, which is a lie, kindly told."},
	{"id": "w_spring", "after": "s_p10_home", "kind": "hot_spring", "ask": "A hot spring, Lin Feng. I have healed a thousand aches and never once soaked one away. Find me a hot spring.", "done": "She soaks until her fingers wrinkle, and declares hot springs her favourite thing in four realms."},
	{"id": "w_kite", "after": "s_p11_home", "kind": "kite", "ask": "Fly a kite with me. A red one. I want to see something of ours up in the sky.", "done": "The red kite goes so high they lose it in the sun. She says it went home."},
	{"id": "w_stage", "after": "s_p12_home", "kind": "stage", "ask": "I have never once seen you show off. Do the sword form on a stage somewhere. I will clap.", "done": "She claps every figure, and shouts \"Hao!\" at the end like an old opera-goer, and makes him bow."},
	{"id": "w_river", "after": "s_p13_home", "kind": "river_lantern", "ask": "Set a lantern on the water with me, for everyone who did not come home from the wars.", "done": "Two lanterns drift away on the dark water. She stands watching long after they are gone."},
]

static func wish(id: String) -> Dictionary:
	for w in WISHES:
		if str(w.id) == id:
			return w
	return {}

## The wishes she has now: opened by the story and not yet granted.
static func wishes_open(g) -> Array:
	var out: Array = []
	for w in WISHES:
		if not g.wishes.has(str(w.id)) and _done(g, str(w.after)):
			out.append(str(w.id))
	return out

## Lin Feng has done a thing of kind `kind` (props.gd) with Yue Ling there: a wish of hers granted,
## and (once for every kind, and again after a while) a little closer.  The lines to show.
static func did_together(g, kind: String, joined: bool) -> Array:
	var out: Array = []
	if not g.companion:
		return out
	for w in WISHES:
		if str(w.kind) == kind and not g.wishes.has(str(w.id)) and _done(g, str(w.after)):
			g.wishes[str(w.id)] = true
			out.append(str(w.done))
			out.append("Yue Ling's wish granted (%d of %d)" % [g.wishes.size(), WISHES.size()])
			add(g, WISH, "a wish of hers")
			g.add_renown(1)
			g.note("Granted Yue Ling's wish: " + str(w.ask))
			break
	if joined:
		var last: float = float(g.shared.get(kind, -1e9))
		if g.playtime - last >= SHARED_AGAIN:
			g.shared[kind] = g.playtime
			add(g, SHARED, "done together")
	return out

# ---------------------------------------------------------------- Part XV: the memories the Founder pressed
const MEMORY_STEP := "s_p15_memories"
const MEMORIES_NEEDED := 6
## the lotus pond where she woke, on the sect's mountain: where Part XV begins and ends
const POND := "mem_pond"
## the loom in the Founder's hermitage on which she was woven (a piece of its furniture)
const LOOM := "furn:mountain:lotus_hermitage:2"
## the open-air stage on the mountain below the Jianmu, where the sect holds her naming feast
const FEAST := "kind:mountain:stage"
## the pressed petal each memory gives back (the Unweaver's craft path and the Warden's key use them)
const PETAL := "pressed_petal"
## The memories: the region, a tile of it to look near (the nearest place a thing of that kind can
## stand), the thing it is (props.gd/structures.gd), its name, the bearer it belongs to, the lines when
## Lin Feng comes to it, the foes eating it, the remembered scene (they do the thing together while it
## is told), her question and Lin Feng's answers (`lean`, `after`).
const MEMORIES := {
	"mem_flute": {"area": "bamboo", "near": Vector2i(30, 30), "prop": "flute_rock", "n": "Ah Zhu's flute stone", "bearer": "Ah Zhu, the third bearer",
		"col": Color("8ac06a"),
		"lines": [["Yue Ling", "This rock. Lin Feng, I have sat on this rock. There was a girl with a bamboo flute and a woodcutter's axe, and she played so badly the birds left."],
			["Narrator", "Grey moths with no faces are crawling over the stone, and where they crawl the moss forgets to be green."]],
		"battle": [["forgetting_moth", 57], ["forgetting_moth", 57], ["loose_thread", 57]],
		"scene": [["Narrator", "Three hundred years ago, the third bearer of the Seal was a woodcutter's daughter called Ah Zhu, who carried an axe in one hand and a flute in the other and was afraid of nothing except silence."],
			["Narrator", "She taught the healer at her side to play, on this rock, every evening for a summer. The healer was good at it at once. Ah Zhu was never good at it at all, and never stopped."],
			["Yue Ling", "\"Play it again, Yue Ling. You make it sound like the forest is happy.\" She said that. She said my name. I had a name even then, Lin Feng."],
			["Narrator", "Lin Feng plays Ah Zhu's tune on the flute that has waited on the rock for three hundred years, exactly as badly as Ah Zhu did, and Yue Ling dances to it, laughing, and the bamboo leans in to listen."]],
		"ask": "The last note wobbles away into the bamboo, and Yue Ling stops dancing. What do you say?",
		"options": [
			{"id": "play", "label": "\"Play it for me too. Every evening.\"", "lean": "companion", "after": [["Yue Ling", "Every evening? You will get very tired of one tune, Lin Feng."], ["Lin Feng", "Ah Zhu didn't."]]},
			{"id": "forest", "label": "\"The forest remembers her through you.\"", "lean": "lotus", "after": [["Yue Ling", "Then I will come back here and play it for the forest, now and then, so it does not forget either."]]},
			{"id": "learn", "label": "\"Learn every tune in the world.\"", "lean": "wander", "after": [["Yue Ling", "Every tune in the world. Ah Zhu would have liked that. She only ever knew three."]]}]},
	"mem_lanterns": {"area": "springs", "near": Vector2i(40, 28), "prop": "river_lantern", "n": "Old Jiang's lantern jetty", "bearer": "Old Jiang, the ninth bearer",
		"col": Color("8ab0e8"),
		"lines": [["Yue Ling", "A jetty and lotus lanterns, here, where the dead cross over. I know this. An old ferryman, Lin Feng, with hands like rope, and every year on the fifteenth of the seventh month..."],
			["Narrator", "Loose threads of light are unspooling from the jetty's posts, and something with soft grey wings is eating them."]],
		"battle": [["loose_thread", 57], ["forgetting_moth", 57], ["loose_thread", 58]],
		"scene": [["Narrator", "The ninth bearer was a ferryman called Jiang, who had already lost his wife to the river when the Seal came to him. He was sixty, and slow, and very kind, and he did not want to be anybody's hero."],
			["Narrator", "Every year on the night of hungry ghosts he walked down the funeral road to the Yellow Springs and set a lotus lantern on the water for her, and the healer set one beside it, for whoever she had forgotten."],
			["Yue Ling", "\"Two lanterns, so neither of them goes alone.\" That was what he said. Every year. Eleven years."],
			["Narrator", "Two lanterns go out on the Yellow Springs now, Lin Feng's and Yue Ling's, side by side among the red lilies, and for a moment the dark water carries a third beside them before it lets them go."]],
		"ask": "The lanterns drift out of sight. What do you say?",
		"options": [
			{"id": "two", "label": "\"Two lanterns. Neither goes alone.\"", "lean": "companion", "after": [["Yue Ling", "Neither goes alone. Old Jiang would have liked you. He would have made you row."]]},
			{"id": "keep", "label": "\"We'll come back every seventh month.\"", "lean": "lotus", "after": [["Yue Ling", "Every seventh month. A lantern for him, and one for his wife. Somebody should keep the date."]]},
			{"id": "more", "label": "\"Set one for everyone you've lost.\"", "lean": "wander", "after": [["Yue Ling", "That would be a great many lanterns, Lin Feng. The Springs would look like the Silver River."]]}]},
	"mem_kite": {"area": "terraces", "near": Vector2i(30, 24), "prop": "kite", "n": "Chun's kite post", "bearer": "Chun, the twelfth bearer",
		"col": Color("e8c860"),
		"lines": [["Yue Ling", "A kite post on the tea hills. A girl, Lin Feng, a tea-picker, with a red kite she made herself out of a festival banner."],
			["Narrator", "The kites leaning on the post are going grey from the edges in, as if somebody were rubbing them out."]],
		"battle": [["unweaver_shuttle", 57], ["forgetting_moth", 57], ["forgetting_moth", 57]],
		"scene": [["Narrator", "The twelfth bearer was Chun, a tea-picker of fourteen, who became a cultivator because the Seal fell into her basket one morning with the tea leaves. She never quite believed it was real."],
			["Narrator", "At Qingming she flew a red kite off the top terrace, and the healer held the reel, and they let the string run out until the kite was a speck over the next province."],
			["Yue Ling", "\"Cut the string, Yue Ling. Then it can go wherever it likes.\" And I did. And she cried and laughed at once, the way only fourteen-year-olds can."],
			["Narrator", "Lin Feng flies the red kite off the post now, and Yue Ling holds his sleeve and watches it climb."]],
		"ask": "The kite is a red speck against the clouds. What do you do?",
		"options": [
			{"id": "hold", "label": "Hold the string with her.", "lean": "companion", "after": [["Narrator", "She puts her hand over his on the string, and they bring the kite down together, slowly, the way you bring something home."]]},
			{"id": "tie", "label": "Tie it to the post, to fly here for ever.", "lean": "lotus", "after": [["Yue Ling", "So it always flies over these hills. Chun would like that. Every picker would look up and see it."]]},
			{"id": "cut", "label": "Cut the string, as Chun did.", "lean": "wander", "after": [["Narrator", "He cuts the string. The red kite goes up and away over the next province, and Yue Ling laughs and cries at once, like a fourteen-year-old."]]}]},
	"mem_dance": {"area": "magpie", "near": Vector2i(30, 24), "prop": "lantern_green", "n": "Wen Shu's lantern green", "bearer": "Wen Shu, the fifteenth bearer",
		"col": Color("f08ab0"),
		"lines": [["Yue Ling", "Red lanterns on strings. Lin Feng, this was a wedding. A scholar called Wen Shu married the girl from the next village on the seventh night of the seventh month, here, under the magpies."],
			["Narrator", "The lanterns over the green are going out one by one, and in the dark between them something is unpicking the strings."]],
		"battle": [["unweaver_shuttle", 58], ["loose_thread", 57], ["forgetting_moth", 57]],
		"scene": [["Narrator", "The fifteenth bearer was Wen Shu, a poor scholar who failed the examinations four times and wrote love poems on the backs of his answer sheets. He was the only bearer who ever married."],
			["Narrator", "At his wedding the healer danced. She danced with the bride, and with the bride's grandmother, and with Wen Shu, and with nobody in particular, until the lanterns burned down."],
			["Yue Ling", "\"You dance like somebody who has never been sad, Yue Ling.\" And I said, I have been sad, I just do not remember it. And he wrote that down. He wrote everything down."],
			["Narrator", "Under the lanterns of the green Yue Ling dances again, and this time she pulls Lin Feng in after her."]],
		"ask": "The last lantern sways overhead. What do you say?",
		"options": [
			{"id": "again", "label": "\"Dance with me at ours, then.\"", "lean": "companion", "after": [["Yue Ling", "At ours? Lin Feng, was that... did you just..."], ["Lin Feng", "I said dance. Nobody said anything else. Yet."]]},
			{"id": "every", "label": "\"Come back every Qixi and dance here.\"", "lean": "lotus", "after": [["Yue Ling", "Every Qixi. For Wen Shu and his bride. The magpies would expect it now."]]},
			{"id": "world", "label": "\"Dance at every wedding in four realms.\"", "lean": "wander", "after": [["Yue Ling", "Every wedding in four realms. I would never sleep. I would be very happy."]]}]},
	"mem_stars": {"area": "starferry", "near": Vector2i(30, 24), "prop": "armillary", "n": "Xing Yao's armillary", "bearer": "Xing Yao, the eighteenth bearer",
		"col": Color("a8c8ff"),
		"lines": [["Yue Ling", "Bronze rings. An old woman with ink on her fingers who never once slept before dawn. She was the Court's astronomer, Lin Feng, until she was the bearer."],
			["Narrator", "The rings of the armillary have stopped turning. Something with a hundred grey threads for legs is wrapped round them, pulling the stars out of the bronze."]],
		"battle": [["unweaver_shuttle", 58], ["unweaver_shuttle", 57], ["loose_thread", 58]],
		"scene": [["Narrator", "The eighteenth bearer was Xing Yao, who had mapped every star in the Court's sky and found eleven the Court had not put there. They dismissed her for it. The Seal came to her the same year."],
			["Narrator", "She lay in the grass by her armillary every clear night and taught the healer the stars: which were real, which were the Court's, which were somebody's soul on the way home."],
			["Yue Ling", "\"That one is yours, Yue Ling. I have named it. Nobody else will know which it is.\" And she pointed, and I have forgotten which, and I have looked for it every night since without knowing why."],
			["Narrator", "Lin Feng and Yue Ling lie back in the grass by the turning rings, and she finds it: a small star, a little to the left of the Weaver, slightly pink."]],
		"ask": "She has found her star. What do you say?",
		"options": [
			{"id": "beside", "label": "\"Which one is next to it?\"", "lean": "companion", "after": [["Yue Ling", "That one. Small and blue and slightly crooked."], ["Lin Feng", "Mine, then."], ["Yue Ling", "...Yes. Yours."]]},
			{"id": "name", "label": "\"Tell the Archivist. Put it in the Annals.\"", "lean": "lotus", "after": [["Yue Ling", "The Annals. A star with my name in the sect's own book. Xing Yao would be furious it took this long."]]},
			{"id": "map", "label": "\"Map the rest of the sky, like she did.\"", "lean": "wander", "after": [["Yue Ling", "The eleven stars the Court did not put there. I could find them. I could find out whose they are."]]}]},
	"mem_mill": {"area": "yanggu", "near": Vector2i(30, 30), "prop": "millstone", "n": "Fat Bao's millstone", "bearer": "Fat Bao, the seventeenth bearer",
		"col": Color("d8a04a"),
		"lines": [["Yue Ling", "Lin Feng. I pushed this millstone. For a whole summer. A noodle-maker called Bao, who was very fat and very cheerful and fed the whole market for nothing on festival days."],
			["Narrator", "Flour is blowing off the stone as grey dust, and in it things like moths are feeding on the smell of noodles that is still in the wood."]],
		"battle": [["forgetting_moth", 58], ["loose_thread", 57], ["unweaver_shuttle", 57]],
		"scene": [["Narrator", "The seventeenth bearer was Bao, a noodle-maker of the Dawn Market, who took the Seal because he thought it was a very ornate noodle cutter and kept it because the healer who came with it could knead."],
			["Narrator", "They ran his stall for a summer, the healer pushing the millstone and Bao pulling noodles a fathom long, and every beggar in Yanggu ate."],
			["Yue Ling", "\"Nobody fights well hungry, Yue Ling. Feed them first, save the world after.\" He was the wisest of all twenty and he never once read a book."],
			["Narrator", "Lin Feng pushes Bao's millstone round now, and Yue Ling sweeps up the flour, and a beggar child at the edge of the market watches with enormous hope."]],
		"ask": "The flour is ground. What do you do?",
		"options": [
			{"id": "cook", "label": "Cook noodles together for the market.", "lean": "companion", "after": [["Narrator", "They cook until dark. His noodles break; hers are a fathom long. The beggar child eats four bowls and falls asleep under the stall."]]},
			{"id": "give", "label": "Give the flour to the stall that took Bao's place.", "lean": "lotus", "after": [["Yue Ling", "His stall is still here. A granddaughter of somebody's apprentice. She feeds the beggars on festival days. Nobody told her to. It just stayed."]]},
			{"id": "teach", "label": "\"Feed them first. Take that everywhere.\"", "lean": "wander", "after": [["Yue Ling", "Feed them first, save the world after. Yes. I will take that everywhere I go."]]}]},
	"mem_spring": {"area": "frost", "near": Vector2i(30, 24), "prop": "hot_spring", "n": "Bai Shan's hot spring", "bearer": "Bai Shan, the sixth bearer",
		"col": Color("8ae0d0"),
		"lines": [["Yue Ling", "Steam in the snow. A soldier, Lin Feng. Bai Shan, the sixth bearer, home from a war nobody remembers, who could not sleep."],
			["Narrator", "The hot spring has gone cold at the edges. Grey moths sit in the frost on the rocks, drinking the warmth out of the water."]],
		"battle": [["forgetting_moth", 57], ["unweaver_shuttle", 58], ["loose_thread", 57]],
		"scene": [["Narrator", "The sixth bearer was Bai Shan, a soldier who came home from the border with a sword he never drew again and a silence he never broke. He had not slept in a year when the Seal found him."],
			["Narrator", "The healer sat with him in this spring under Frostpeak every night of a whole winter, saying nothing, until one night he fell asleep with his head on the rocks, and she kept the snow off him till morning."],
			["Yue Ling", "\"Thank you for not asking.\" That was all he ever said to me. Five words, the whole winter. They were the best five words I ever got."],
			["Narrator", "Steam rises round the two of them in the spring now, and the snow comes down very softly, and nobody asks anybody anything."]],
		"ask": "The snow falls on the steam. What do you say?",
		"options": [
			{"id": "nothing", "label": "Say nothing. Stay.", "lean": "companion", "after": [["Narrator", "He says nothing. After a long time she says, \"Thank you for not asking,\" and laughs, and he laughs, and the snow keeps coming down."]]},
			{"id": "rest", "label": "\"Every soldier should have a place like this.\"", "lean": "lotus", "after": [["Yue Ling", "A place to come home to and not be asked anything. The sect could be that, for people. I could help it be."]]},
			{"id": "find", "label": "\"Find the others who can't sleep.\"", "lean": "wander", "after": [["Yue Ling", "There are so many of them, Lin Feng. Every war leaves a Bai Shan. I could go and sit with them."]]}]},
}
## (by the bearer each was pressed for, third to eighteenth)
const MEMORY_ORDER := ["mem_flute", "mem_spring", "mem_lanterns", "mem_kite", "mem_dance", "mem_mill", "mem_stars"]

static func memory(id: String) -> Dictionary:
	return MEMORIES.get(id, {})

static func memory_option(id: String, oid: String) -> Dictionary:
	for o in memory(id).get("options", []):
		if str(o.id) == oid:
			return o
	return {}

## Whether memory `id` can be given back now: the memories step is the one in hand and it is not
## given back yet.
static func memory_ready(g, id: String) -> bool:
	var s: Dictionary = g.cur_step()
	return not s.is_empty() and str(s.kind) == "memories" and MEMORIES.has(id) and not g.memories.has(id)

## A memory given back: remembered with what Lin Feng said, a pressed petal of it, her heart and
## their closeness.
static func take_memory(g, id: String, o: Dictionary) -> void:
	g.memories[id] = str(o.id)
	g.add_item(PETAL)
	lean(g, str(o.get("lean", "")), 3)
	add(g, MEMORY, "a memory given back")
	g.toast("A memory given back: %s (%d of %d)" % [str(memory(id).bearer), g.memories.size(), MEMORIES_NEEDED])
	g.note("Gave Yue Ling back her memory of %s" % str(memory(id).bearer))

# ---------------------------------------------------------------- the lotus pond: where it begins and ends
## Kind "share" steps: Lin Feng and Yue Ling at the pond, and a choice.  The first leans her heart; the
## last is hers to make (FUTURES), with the one her heart leans to marked.
const SHARES := {
	# ---- Part XVII (the Spring Thunder release): the dragon's head day, the first thunder, Qingming
	"s_p17_haircut": {"lines": [
		["Narrator", "On the second day of the second month the barbers of Qingshi set up their stools in the lane with a basin and a razor and a kettle, because on the day the dragon raises its head everybody has their hair cut for luck, and the barbers have been waiting a month."],
		["Narrator", "The queue is long. Yue Ling takes the shears from the youngest barber, very politely, sits Lin Feng down on the bench and starts on him herself, to cheers."],
		["Yue Ling", "Hold still. A haircut on the dragon's day is a whole year's luck. A bad haircut on the dragon's day is a whole year's luck and everybody laughing at you. Do you want a dragon's luck or a sweeper's?"]],
		"ask": "How do you want it cut?",
		"options": [
			{"id": "trust", "label": "\"However you like. I trust you.\"", "lean": "companion", "after": [["Lin Feng", "However you like. I trust you."], ["Yue Ling", "That was a mistake. A lovely mistake. Hold still."], ["Narrator", "It comes out rather well, apart from one piece at the back that she swears is on purpose."]]},
			{"id": "same", "label": "\"Just like the old sweeper's.\"", "lean": "lotus", "after": [["Lin Feng", "Like it was when I swept the steps. Short. Nothing to get caught in a broom."], ["Yue Ling", "The sweeper's cut. Yes. The mountain should have its sweeper back for a day."]]},
			{"id": "road", "label": "\"Something for the road.\"", "lean": "wander", "after": [["Lin Feng", "Something that will not need cutting again for a long way."], ["Yue Ling", "A traveller's cut. Short at the sides, long enough on top for the wind. You are already halfway down the road, aren't you?"]]},
		]},
	"s_p17_thunder": {"lines": [
		["Narrator", "Lei Gong stretches the five new drumheads over his frames, each with a thunder egg set in the middle like a jewel, and hands Lin Feng the second mallet. The rain is still falling, soft and warm, over the whole of the Unbroken Land."],
		["Lei Gong, Duke of Thunder", "Not hard. That is the secret everybody gets wrong. The first thunder of spring is not to frighten anybody. It is to wake them. Strike it the way you would knock on the door of somebody you love, early in the morning."],
		["Narrator", "Lin Feng and Yue Ling strike the drum together, once. The thunder goes out over the land like a door opening: across the paddies of Qingshi, the terraces, the millet plains, the river at Longmen, and everywhere it goes, everything asleep in the ground turns over and wakes."]],
		"ask": "As the thunder rolls away over the land, what do you wish for?",
		"options": [
			{"id": "us", "label": "That everything wakes beside somebody", "lean": "companion", "after": [["Yue Ling", "That everything wakes up beside somebody. That is a very you wish."], ["Lei Gong, Duke of Thunder", "That is a very good wish. I shall drum it into the next one."]]},
			{"id": "home", "label": "That the mountain wakes green", "lean": "lotus", "after": [["Yue Ling", "The mountain green again. The pond full of frogs. Yes."], ["Lei Gong, Duke of Thunder", "Green it is. I will send the next roll over your sect, sweeper, and rattle your Elder's windows."]]},
			{"id": "far", "label": "That it reaches every road", "lean": "wander", "after": [["Yue Ling", "Every road in the land, waking up at once, and all of them going somewhere."], ["Lei Gong, Duke of Thunder", "Every road. I can do that. It is a great deal of thunder, but I have new drums."]]},
		]},
	"s_p17_graves": {"lines": [
		["Narrator", "On Qingming the whole land goes out to the graves with brooms and willow, food and paper money, and sweeps the winter off the people who came before them. Lin Feng and Yue Ling go down the funeral road to the Maple Gorge, to the old maple where the Elder found a baby wrapped in a sweeper's cloak between two graves."],
		["Narrator", "The two graves had no names when the Elder dug them. Somebody has since carved them in the stone, small and straight: Lin Shan. Su Wan. Lin Feng carved them himself, the year after the Wheel, and has never told anybody."],
		["Yue Ling", "I'll sweep. You talk to them. That is how it is done. You tell them the year."]],
		"ask": "What do you tell your parents about the year?",
		"options": [
			{"id": "her", "label": "\"I brought somebody to meet you.\"", "lean": "companion", "after": [["Lin Feng", "Father. Mother. I brought somebody to meet you properly. This is Yue Ling. She is the reason I made it through the year."], ["Yue Ling", "...Good afternoon. He is very good with a broom. You raised him well, for the short time you had."]]},
			{"id": "home", "label": "\"I came home, like you wanted.\"", "lean": "lotus", "after": [["Lin Feng", "I came home. Every time. Even from the moon. I think that is what you would have wanted most."], ["Yue Ling", "They would. Anybody would."]]},
			{"id": "world", "label": "\"The world you gave me is still here.\"", "lean": "wander", "after": [["Lin Feng", "The world you led the hunters away to save is still here. I have seen most of it now. It is very large, and some of it is on fire, and it is worth it."], ["Yue Ling", "And we are going to see the rest. Tell them that too."]]},
		]},
	"s_p17_teacup": {"lines": [
		["Narrator", "The tea table on the terraces looks out over the whole valley: the new green of the paddies, the river at Longmen, the smoke of Qingshi's chimneys, and the mountain behind it all with cloud on its shoulders. Lin Feng heats the water to just below the boil, the way the tea master showed him, and pours it over the six buds."],
		["Yue Ling", "They are opening. Look. They are standing up in the cup like they have just woken."],
		["Lin Feng", "The first tea of the year. The tea master says you drink it in three sips: the first for the winter you came through, the second for the spring you are in, and the third for whoever you are drinking it with."]],
		"ask": "Who is the third sip for?",
		"options": [
			{"id": "her", "label": "\"For you.\"", "lean": "companion", "after": [["Lin Feng", "The third is for you. Obviously."], ["Yue Ling", "Obviously. And mine is for you. That is how three sips becomes two cups."]]},
			{"id": "home", "label": "\"For the mountain and everyone on it.\"", "lean": "lotus", "after": [["Lin Feng", "For the mountain, and everybody on it. The Elder, Auntie Zhou, Little Bai and his frog."], ["Yue Ling", "And the frog. Yes. Especially the frog."]]},
			{"id": "road", "label": "\"For whoever we meet next.\"", "lean": "wander", "after": [["Lin Feng", "For whoever we meet next, wherever the road goes."], ["Yue Ling", "Then we had better keep some leaves back for them. The road is long."]]},
		]},
	"s_p17_kite": {"lines": [
		["Narrator", "On Qingming afternoon the sky over Qingshi is full of kites: swallows, centipedes, butterflies, a dragon forty feet long that takes six boys to hold. At the kite post above the village Yue Ling has a red one shaped like a lotus, with her name painted on its tail in Little Bai's handwriting."],
		["Yue Ling", "At Qingming you fly your kite as high as it will go, and then you cut the string. It carries the bad luck of the year away with it, and whoever finds it is supposed to burn it, not keep it."],
		["Lin Feng", "And if somebody keeps it?"],
		["Yue Ling", "Then they get our bad luck, and serve them right for not reading the rules."]],
		"ask": "The string is cut. What do you watch it carry away?",
		"options": [
			{"id": "fear", "label": "Every time you were afraid for her", "lean": "companion", "after": [["Lin Feng", "Every time I thought you were gone. Every one of them, on a red lotus kite."], ["Yue Ling", "That is a great deal of fear for one kite. It is going very high, though. Look at it go."]]},
			{"id": "winter", "label": "The long winter", "lean": "lotus", "after": [["Lin Feng", "The long winter. The frost, the ice, the dark. All of it."], ["Yue Ling", "And here we are in spring, on our own hill, with nothing to carry but the kite string."]]},
			{"id": "road", "label": "Nothing: it is going where we go next", "lean": "wander", "after": [["Lin Feng", "Nothing. It is just going ahead of us, to see where we go next."], ["Yue Ling", "East. It is going east. ...Lin Feng, it is going towards the sea."]]},
		]},
	# ---- Part XVI (the Living Land release): the last sweeping, the reunion dinner, the vigil and the first dawn
	"s_p16_couplets": {"lines": [
		["Narrator", "The Scripture Library smells of ink and cold stone. Yue Ling unrolls the red paper the merchants sold them across the desk, weighs the ends down with two of Archivist Lan's heaviest books, and grinds the ink herself, very seriously."],
		["Yue Ling", "Two lines for the sides of the gate and four characters for over it. Every door in the land has them. They say what the household hopes for in the new year. Archivist Lan says your handwriting looks like a chicken walked through a puddle."],
		["Lin Feng", "Archivist Lan has never seen a chicken walk through a puddle. It is beautiful."]],
		"ask": "What do you write over the sect's gate?",
		"options": [
			{"id": "together", "label": "\"Two Brushes, One Spring\"", "lean": "companion", "after": [["Lin Feng", "Two brushes, one spring. You write half."], ["Yue Ling", "...I will write the half on the right. It is the better half. Do not argue."]]},
			{"id": "home", "label": "\"The Door Is Always Open\"", "lean": "lotus", "after": [["Lin Feng", "The door is always open. Anybody who comes up the mountain, whatever they are."], ["Yue Ling", "The door is always open. The Founder would have liked that. She made a door once, after all."]]},
			{"id": "roads", "label": "\"Every Road Comes Home\"", "lean": "wander", "after": [["Lin Feng", "Every road comes home. Even the long ones."], ["Yue Ling", "Especially the long ones. I am putting a little boat in the corner. Nobody will notice."]]},
		]},
	"s_p16_lanterns": {"lines": [
		["Narrator", "On the fifteenth night of the first month the Dawn Market hangs every lantern it has ever made: rabbits, carp, dragons, lotuses, a lantern shaped like the sun that it is a little embarrassed about. Riddles hang from their tassels, and the whole market walks under them guessing."],
		["Narrator", "Somebody remembers that the sweeper does sword forms on stages now. By the time Lin Feng has been told, the whole of Yanggu is standing round the stage at the crossroads with sweet dumplings in their hands, waiting."],
		["Yue Ling", "Tangyuan: round, sweet, one for every person at the table. It means everybody is together. I ate eleven. Go on. They are all waiting for you."]],
		"ask": "Under every lantern in Yanggu, who is the sword form for?",
		"options": [
			{"id": "her", "label": "\"For Yue Ling, who saw her first year in.\"", "lean": "companion", "after": [["Lin Feng", "This one is for Yue Ling, who saw her first year in."], ["Narrator", "The market cheers, and somebody hangs a lantern shaped like a lotus over her head, and she lets it stay."]]},
			{"id": "town", "label": "\"For the Dawn Market, that kept its lamps lit.\"", "lean": "lotus", "after": [["Lin Feng", "For the Dawn Market, that kept its lamps lit when the Last Night came for them."], ["Narrator", "Night-Watchman Lao Zhou strikes his gong once, very loudly, and pretends there is something in his eye."]]},
			{"id": "road", "label": "\"For the roads, all of them.\"", "lean": "wander", "after": [["Lin Feng", "For every road out of this town, and everybody coming home along them."], ["Narrator", "The caravan hands cheer loudest. Yue Ling is already reading the riddles on the lanterns pointing east."]]},
		]},
	"s_p16_sweep": {"lines": [
		["Narrator", "The last sweeping of the year sweeps out the bad luck and nothing else: on New Year's Day itself nobody sweeps at all, or the good luck goes out with the dust. Lin Feng takes the old broom from beside the courtyard steps. His hands know it before he does."],
		["Yue Ling", "Three years you swept these steps. What did you think about, all that time?"],
		["Lin Feng", "The leaves. Whether there would be rice at supper. Whether anybody would ever look at me the way the Elder looked at the disciples who could fly."],
		["Yue Ling", "And now everybody looks at you like that."],
		["Lin Feng", "Little Bai doesn't. He looks at me as if I might take his broom back."],
		], "ask": "What do you sweep out with the old year?",
		"options": [
			{"id": "fear", "label": "\"The fear. All of it.\"", "lean": "companion", "after": [["Lin Feng", "The fear. The whole year of it. Every time I thought you were gone."], ["Yue Ling", "Then sweep hard. I am not going anywhere, and I would like the courtyard to know it."]]},
			{"id": "leaves", "label": "\"Just the leaves.\"", "lean": "lotus", "after": [["Lin Feng", "Just the leaves. The rest I want to keep, even the bad parts. They were ours."], ["Yue Ling", "Then we sweep the leaves, and keep the rest in a box under the bed."]]},
			{"id": "dust", "label": "\"The dust of every road.\"", "lean": "wander", "after": [["Lin Feng", "The dust of every road we walked, so the next ones can start clean."], ["Yue Ling", "You are already thinking about the next roads. Good. So am I."]]},
		]},
	"s_p16_eve": {"lines": [
		["Narrator", "On New Year's Eve the whole sect squeezes into the kitchen, because the hall is too cold and Auntie Zhou refuses to carry forty dishes across the courtyard in the snow. The Elder sits between Alchemist Mo and Smith Tie, who are not speaking. Little Bai has been given the chicken's head and is very proud of it."],
		["Narrator", "Zao Jun sits on the stove with a bowl of his own. Nobody mentions that there is a god at dinner."],
		["Yue Ling", "Lin Feng. This is my first. My first New Year's Eve. Everybody keeps putting dumplings in my bowl and I do not know how to make them stop."],
		["Lin Feng", "You don't. That is the whole point. There is a coin in one of them, for luck."],
		["Yue Ling", "...I think I swallowed it."],
		], "ask": "What do you wish her for her first year?",
		"options": [
			{"id": "with", "label": "\"Every year, with me.\"", "lean": "companion", "after": [["Lin Feng", "That there are a great many more of these, and that I am sitting next to you at all of them."], ["Yue Ling", "That is two wishes. You are only allowed one. I will allow it."], ["Narrator", "Then the kitchen door bangs open on the snow, and a courier from Yanggu falls in out of the cold: the lanterns of the Dawn Market are going out, one by one, and something long and dark is eating them."]]},
			{"id": "home", "label": "\"A home that is yours.\"", "lean": "lotus", "after": [["Lin Feng", "A home that is yours. This one, if you want it. Somewhere with your name on the door."], ["Yue Ling", "There is a door with my name on it. Little Bai painted it this morning. He spelt it wrong."], ["Narrator", "Then the kitchen door bangs open on the snow, and a courier from Yanggu falls in out of the cold: the lanterns of the Dawn Market are going out, one by one, and something long and dark is eating them."]]},
			{"id": "far", "label": "\"Somewhere new every spring.\"", "lean": "wander", "after": [["Lin Feng", "Somewhere new every spring, and somewhere warm to come home to every New Year."], ["Yue Ling", "Then I wish you the same. We can argue about where."], ["Narrator", "Then the kitchen door bangs open on the snow, and a courier from Yanggu falls in out of the cold: the lanterns of the Dawn Market are going out, one by one, and something long and dark is eating them."]]},
		]},
	"s_p16_vigil": {"lines": [
		["Narrator", "Granny Wen's house is small, warm and full of neighbours, because every family in Qingshi decided at once that the old woman should not keep the vigil alone, and then all decided to bring their own stools."],
		["Granny Wen the Midwife", "Nobody sleeps tonight. Not the children, not the old, not the cat. That is the rule. Nian has never eaten a house that stayed awake together."],
		["Yue Ling", "Is that why everybody stays up? Not for the year at all. For each other."],
		["Granny Wen the Midwife", "Clever girl. He was never clever. He was good, which is rarer."],
		["Narrator", "The candles burn down. Somebody's grandfather tells the story of the beggar and the bamboo, wrongly, and is corrected by four people at once. Out in the dark above the terraces, the mountain begins, very slowly, to move."],
		], "ask": "What do you tell Granny Wen about Yue Ling?",
		"options": [
			{"id": "mine", "label": "\"She is the one I walk with.\"", "lean": "companion", "after": [["Lin Feng", "She is the one I walk with, Granny. All the way."], ["Granny Wen the Midwife", "I know. I knew when you came through the door. Sit up straight, both of you. Nian is coming."]]},
			{"id": "family", "label": "\"She is family now.\"", "lean": "lotus", "after": [["Lin Feng", "She is family, Granny. Yours too, if you will have her."], ["Granny Wen the Midwife", "I had her the moment she shelled my beans without being asked. Here, hold this ladle. Nian is coming."]]},
			{"id": "free", "label": "\"She goes where she likes.\"", "lean": "wander", "after": [["Lin Feng", "She goes where she likes, Granny. Tonight she likes it here."], ["Granny Wen the Midwife", "A good answer. The best ones always come home for New Year. Now: pots, everybody. Nian is coming."]]},
		]},
	"s_p16_dawn": {"lines": [
		["Narrator", "The first dawn of the new year comes up over the sea of clouds pink and gold, and the whole sect is out on the steps to see it, red-eyed and full of dumplings. Old Shen the Bell-Ringer hands Lin Feng the beam of the great bell."],
		["Old Shen the Bell-Ringer", "A hundred and eight strikes on New Year's morning: one for every trouble a person can have. I have rung them forty years, and my arms are old. You and the girl ring them this year."],
		["Narrator", "They ring them together, a hundred and eight, and on the last one every lantern on the mountain goes out by itself, because it is day and they are not needed, and the Kitchen God goes up the chimney at last with sugar on his lips."],
		], "ask": "On the last strike, what do you wish for?",
		"options": [
			{"id": "us", "label": "A year with her in it", "lean": "companion", "after": [["Yue Ling", "You said it out loud. You are supposed to wish in your head."], ["Lin Feng", "I wanted the bell to hear."]]},
			{"id": "mountain", "label": "A quiet year on the mountain", "lean": "lotus", "after": [["Yue Ling", "A quiet year. Do you think the world will let us have one?"], ["Lin Feng", "No. But I am allowed to wish."]]},
			{"id": "roads", "label": "New roads in spring", "lean": "wander", "after": [["Yue Ling", "New roads. Then we start in spring. I have already packed."], ["Lin Feng", "It is New Year's morning."], ["Yue Ling", "I packed fast."]]},
		]},
	"s_p15_loom": {"lines": [
		["Narrator", "The Founder's Hermitage stands under the Last Cave as if it had been waiting: white walls, a round moon gate, and inside, under three hundred years of dust, a loom strung with thread the colour of lotus petals."],
		["Yue Ling", "I know this room. Not the way I knew the pond. The way you know the inside of your own eyelids."],
		["Yue Ling", "She wove me here, Lin Feng. Row by row. Sit down at it. No, you. I want to watch somebody else do it for once. I'll guide your hands."],
		["Narrator", "He sits at the loom, and she stands behind him with her hands over his on the shuttle, and the treadles remember a rhythm neither of them was taught."],
		["Yue Ling", "I can feel where she was tired, and where she sang, and where she cried because she knew she would not live to see me finished. And here, third row from the end: a mistake. She left it in on purpose."],
		["Yue Ling", "Weavers do that, so the cloth is not perfect and the gods are not jealous. So I was never perfect either. Good."]],
		"ask": "Yue Ling's hands are over yours on the shuttle. What do you weave?",
		"options": [
			{"id": "both", "label": "Weave the two colours together", "lean": "companion", "desc": "Rose and blue, over and under, the one holding the other.",
				"after": [["Narrator", "Rose and blue, over and under, for an hour, and the cloth grows by a hand's breadth. Neither of them says anything. Neither of them needs to."], ["Yue Ling", "Look. That thread is you. You are very crooked."], ["Lin Feng", "You are holding my hands."]]},
			{"id": "finish", "label": "Finish the Founder's last row", "lean": "lotus", "desc": "The row she never lived to weave, on the loom where she wove it.",
				"after": [["Narrator", "They weave the last row the Founder left, and tie it off, and the cloth she began three hundred years ago is finished at last."], ["Yue Ling", "This place could be a home again. Somebody should sweep it."], ["Lin Feng", "I know somebody."]]},
			{"id": "road", "label": "Weave something new: a road", "lean": "wander", "desc": "Not a copy of what she was: a band that runs off the edge of the loom.",
				"after": [["Narrator", "They weave a band of pattern that starts at her own edge and runs straight off the side of the loom, unfinished on purpose."], ["Yue Ling", "A road with no end in the cloth. I like it. It goes somewhere."]]}]},
	"s_p15_pond": {"lines": [
		["Narrator", "The lotus pond at the foot of the sect's courtyard, in the evening. Yue Ling sets a lotus lantern on the water, and then another, and watches them go."],
		["Yue Ling", "This is where I woke. Three winters before you found me. Well, four. Or three hundred. I sat up in the reeds with lotus petals in my hair and my name in my mouth, and that was the first thing I ever knew."],
		["Yue Ling", "Something is happening to me, Lin Feng. This morning Disciple Mei walked past me and said, 'Good morning, Elder's guest.' She has known me for ten years. She looked through me as if I were a window."],
		["Yue Ling", "And this."],
		["Narrator", "She holds out her hand. A petal comes away from her palm, pink and translucent, and floats down onto the water among the lanterns."],
		["Yue Ling", "Every debt is paid and every cause has met its effect, and I was never anybody's cause. The world is tidying me away. Gently. The way you put a book back on a shelf."]],
		"ask": "Yue Ling is losing petals. What do you promise her?",
		"options": [
			{"id": "remember", "label": "\"I'll remember you for both of us.\"", "lean": "companion", "desc": "Whatever the world forgets, he will not.",
				"after": [["Lin Feng", "Then the world can forget whatever it likes. I will remember you for both of us. Every day. Out loud, if I have to."], ["Yue Ling", "You will annoy everybody in the sect."], ["Lin Feng", "Good."]]},
			{"id": "mountain", "label": "\"This mountain is your home. It won't let you go.\"", "lean": "lotus", "desc": "She was made here, of this pond. The mountain will hold on to her.",
				"after": [["Lin Feng", "You were made on this mountain, out of this pond. The mountain does not forget its own. Neither does the sect. We will hold on."], ["Yue Ling", "Hold on very tight, then. I am slippery."]]},
			{"id": "past", "label": "\"Then let's go and find you a past.\"", "lean": "wander", "desc": "If she has no past of her own, they will go and get it back.",
				"after": [["Lin Feng", "If the world has no page for you, we go out and find what you were and bring it back. All of it. Every bearer."], ["Yue Ling", "That is twenty bearers and three hundred years, Lin Feng."], ["Lin Feng", "I have time. So do you."]]}]},
	"s_p15_feast": {"lines": [
		["Narrator", "The sect decides, without asking anybody, that a person who has just been written into the Book of Life and Death has just been born, and that a person who has just been born must have a naming feast."],
		["Narrator", "Auntie Zhou cooks for three days. The disciples hang lanterns from every eave. Alchemist Mo brews something he refuses to name. The Elder makes a speech and forgets the end of it on purpose, so that everybody laughs."],
		["Yue Ling", "Lin Feng. They want a performance. Everybody does something at a naming feast: a song, a poem. They are all looking at you."],
		["Lin Feng", "I do not sing."],
		["Yue Ling", "You do a sword form on a stage. I asked you once. Now the whole sect is asking."],
		["Narrator", "The whole sect has carried its tables out to the old open-air stage on the mountain, below the Jianmu. He climbs onto it under the red lanterns with his old sword, and the whole of Azure Cloud Sect goes quiet to watch."]],
		"ask": "The whole sect is watching. Who do you dedicate the form to?",
		"options": [
			{"id": "her", "label": "To Yue Ling, out loud", "lean": "companion", "desc": "In front of everybody.",
				"after": [["Lin Feng", "This one is for Yue Ling. Who chose."], ["Narrator", "The courtyard erupts. Yue Ling hides her face in her sleeves and is seen, by at least forty witnesses, to be smiling."]]},
			{"id": "sect", "label": "To the sect, her family", "lean": "lotus", "desc": "Hers, and his.",
				"after": [["Lin Feng", "For the sect, which is her family, and mine."], ["Narrator", "The Elder wipes his eyes and claims it is the incense. There is no incense."]]},
			{"id": "road", "label": "To every road she has not walked yet", "lean": "wander", "desc": "There are a great many.",
				"after": [["Lin Feng", "For every road she has not walked yet."], ["Yue Ling", "Then it will have to be a very long form."], ["Narrator", "It is. Nobody leaves."]]}]},
	"s_p15_name": {"lines": [
		["Narrator", "The lotus pond again, at dawn. Judge Cui's runner has come up the funeral road in the night with a book wrapped in yellow silk: the Book of Life and Death, open at a page that was not there yesterday."],
		["Narrator", "It is blank except for a name, written in a hand Lin Feng knows, because it is his own: Yue Ling. Every memory given back, every thread tied by a friend, every thing done side by side has gone into the ink."],
		["Yue Ling", "Judge Cui says the first line of a life is the one you write yourself. Everything after it, the world helps with."],
		["Yue Ling", "I have been woven for three hundred years, Lin Feng. Twenty bearers. I have walked every road somebody else chose. This is the first thing that has ever been only mine."],
		["Narrator", "She holds the brush over the page, and her hand, which has set ten thousand bones without shaking, shakes."]],
		"ask": "Yue Ling writes the first line of her life. What will she be?",
		"future": true},
}

## a share spot is a thing's id, or "kind:<region>:<kind>": the first thing of that kind in that region
## (the mountain's open-air stage, wherever the land put it)
static func spot_is(spot: String, e: Dictionary) -> bool:
	if spot.begins_with("kind:"):
		var parts := spot.split(":")
		return str(e.get("kind", "")) == "prop" and not e.has("furn") and str(e.get("area", "")) == parts[1] and str(e.get("prop", "")) == parts[2] and not e.has("memory")
	return str(e.get("id", "")) == spot

## Where a shared scene happened, as the Annals tell it ("Yue Ling and Lin Feng: Kindred Spirit (at the
## loom she was woven on)").  Every share used to be put down as "by the lotus pond".
const SHARE_PLACES := {"s_p15_pond": "by the lotus pond", "s_p15_name": "by the lotus pond", "s_p15_loom": "at the loom she was woven on",
	"s_p15_feast": "at her naming feast", "s_p16_sweep": "sweeping out the old year", "s_p16_eve": "at the reunion dinner",
	"s_p16_vigil": "keeping the vigil", "s_p16_dawn": "at the first dawn of the year", "s_p16_lanterns": "at the Lantern Festival", "s_p16_couplets": "writing the New Year couplets",
	"s_p17_haircut": "on the day the dragon raised its head", "s_p17_thunder": "drumming the first thunder", "s_p17_teacup": "over the first tea of spring",
	"s_p17_graves": "at the graves on Qingming", "s_p17_kite": "flying the Qingming kite"}

static func share_place(sid: String) -> String:
	return str(SHARE_PLACES.get(sid, "side by side"))

## The thing a share spot names among `ents` ({} if none).
static func find_spot(ents: Array, spot: String) -> Dictionary:
	for e in ents:
		if spot_is(spot, e):
			return e
	return {}

## The lines the last share closes with, by the future she chose and whether it was the one her heart
## leaned to.
const FUTURE_AFTER := {
	"companion": [["Narrator", "She writes: Yue Ling, who walks beside Lin Feng because she chose to."], ["Yue Ling", "There. Now the weave can go and weave somebody else. This one is spoken for."],
		["Narrator", "A thread, red as cotton and fine as silk, runs out of the page and ties itself round her wrist, and the other end round his."]],
	"lotus": [["Narrator", "She writes: Yue Ling, the lotus of Azure Cloud Mountain, who keeps its door open."], ["Yue Ling", "I was made here. I would like to be from here, as well. There is a difference, and it is everything."],
		["Narrator", "The pond answers: every lotus on it opens at once, at dawn, which lotuses do not do, and the whole sect comes out to see."]],
	"wander": [["Narrator", "She writes: Yue Ling, a wandering healer, who goes where she is needed and comes home in spring."], ["Yue Ling", "I said I was a wandering healer the day we met. It was a lie. Now it is the truest thing I have ever written."],
		["Narrator", "The ink dries, and for the first time since the Wheel, no petal falls from her hand. She is solid all the way through, and laughing."]],
}
const HEART_YES := [["Yue Ling", "You knew. You always knew which way I would go, before I did. Thank you for not saying."]]
const HEART_NO := [["Yue Ling", "It is not what I expected to write. That is how I know it is mine."]]

## The future she chose ("" before Part XV's end).
static func future(g) -> String:
	return str(g.future)

## She writes the first line of her life: remembered, and told of.
static func choose_future(g, key: String) -> void:
	g.future = key
	add(g, 6, "the first line of her life")
	g.toast("Yue Ling: %s" % str(FUTURES[key].n))
	g.note("Yue Ling chose her own road: %s" % str(FUTURES[key].n))

## What the ending tells of her.
static func epilogues(g) -> Array:
	var out: Array = []
	if future(g) != "":
		out.append(str(FUTURES[future(g)].epilogue))
	if g.memories.size() >= MEMORIES.size():
		out.append("Every one of the seven memories the Founder pressed was given back. Yue Ling can name all twenty bearers she walked beside, and does, every year, on the night of the lotus lanterns.")
	return out

## Whether tile `t` is the deck of a bridge: a road tile with water on both sides across it, under
## the humped stone bridge (terrain3d.gd), whose arch stands higher than the ground it is drawn over.
static func _bridge_deck(grid: PackedByteArray, W: int, H: int, t: Vector2i) -> bool:
	if grid.is_empty() or t.x < 1 or t.y < 1 or t.x >= W - 1 or t.y >= H - 1 or grid[t.y * W + t.x] != MapGen.PATH:
		return false
	var wet := func(x: int, y: int) -> bool:
		return grid[y * W + x] == MapGen.WATER
	return (wet.call(t.x - 1, t.y) and wet.call(t.x + 1, t.y)) or (wet.call(t.x, t.y - 1) and wet.call(t.x, t.y + 1))

# ---------------------------------------------------------------- where the memories stand
## The places of the memories (and of the pond) in a realm: each a thing to do (props.gd) standing on
## the forest edge or the bank nearest the tile its memory names, never on a tile anybody walks over and
## clear of everything else.  `cands` holds each region's candidate tiles ([hash, tile, open side,
## water?], as Props.place gathers them), `placed` the things already standing.
static func place(ids: Array, cands: Dictionary, placed_all: Array, layer: String, others: Array = [], grid: PackedByteArray = PackedByteArray(), W: int = 0, H: int = 0) -> Array:
	var out: Array = []
	var spots := {}
	for mid in MEMORIES:
		spots[mid] = MEMORIES[mid]
	spots[POND] = {"area": "sect", "near": Vector2i(20, 21), "prop": "river_lantern", "n": "The lotus pond where she woke"}
	for mid2 in spots:
		var sp: Dictionary = spots[mid2]
		var k: int = ids.find(str(sp.area))
		if k < 0:
			continue
		var want := Atlas.to_world(str(sp.area), sp.near)
		var water: bool = Props.WATER_KINDS.has(str(sp.prop))
		var big := Props.is_structure(str(sp.prop)) and not grid.is_empty()
		var best = null
		# the nearest free place at least four tiles from every other thing; failing that, the region's
		# own thing of that kind becomes the memory's place; failing that, two tiles will do
		for gap in [16, 4]:
			var bd := 1 << 30
			for c in cands.get(k, []):
				if bool(c[3]) != water:
					continue
				var tile: Vector2i = c[1]
				if big and Props._by_building(grid, W, H, tile, 3):
					continue
				# (a lantern set from the bank, not from a bridge: on the humped bridge's tile the two of
				# them stood inside its arch, she with her head through the deck)
				if water and _bridge_deck(grid, W, H, tile + (c[2] as Vector2i)):
					continue
				var near := false
				for p in placed_all:
					if (p as Vector2i).distance_squared_to(tile) < gap:
						near = true
						break
				if near:
					continue
				var dd: int = tile.distance_squared_to(want)
				if dd < bd:
					bd = dd
					best = c
			if best != null:
				break
			if gap == 16:
				var same = null
				for o in others:
					if str(o.get("area", "")) == str(sp.area) and str(o.get("prop", "")) == str(sp.prop) and not o.has("memory") and not o.has("furn"):
						same = o
						break
				if same != null:
					same["id"] = "mem:" + mid2
					same["memory"] = mid2
					same["n"] = str(sp.n)
					break
		if best == null:
			continue
		placed_all.append(best[1])
		out.append({"kind": "prop", "id": "mem:" + mid2, "prop": str(sp.prop), "memory": mid2, "n": str(sp.n), "pos": best[1], "face": best[2], "area": str(sp.area), "layer": layer})
	return out
