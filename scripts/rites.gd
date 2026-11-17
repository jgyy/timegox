class_name Rites
extends RefCounted
## The rites of the Daos (the Uncarved Block release).  There are seventeen Daos in the land: the six
## roads (Data.DAOS), the eight Daos of arms (arms.gd) and the three on the forbidden shelf (taboo.gd).
## Until now a Dao was a line on a page and a number in a battle.  Each has a rite now:
##
##  * **a form nobody else has** (`clip`: "rite_<id>" in art/lib/person.py RITES, on the hero's models
##    only: held poses eased by `_keyed`, like the blows of the Eight Arms);
##  * **a thing it is done with** (`prop`: built from code here, stood where the form wants it: in front
##    of him, at his feet, over his head; some of it moves, `tick`);
##  * **a scene** (`beats`: narration, each with where the camera stands: `CAMS`), played the first time
##    the Dao is truly his (a road when it is first walked, a weapon's when he is first an Adept of it,
##    a forbidden one when he first sits to it) and again whenever he asks (Esc > Root & Rites, or at a
##    Dao Stele).
##
## A rite changes no number.  `Game.rites` (id -> times performed) is all the state there is;
## `Game.rite_due` is what is waiting to be played when he is next standing in the world with nothing
## else going on (Main._rite_scene).  A step may ask for one (`"kind": "rite"`: `n` rites performed
## since it began: any of his), and a trial may be passed "By the rite" (`["rites", n]`: so many Daos
## whose rite he has performed).  The bot performs the rite of whatever it walks (`_rite_step`).
##
## **People answer the Dao he walks, and the one he does not** (`said`: nine kinds of witness,
## manners.gd, by the road he walks or "none" if he walks none yet; `ARM_SAID` for the Dao of the
## weapon in his hand once he is an Adept of it; `NAMED` for the people who have known him longest).
## The street's words for the forbidden shelf are taboo.gd's and are not repeated here: nobody in the
## street can see a forbidden art until he is marked.
##
## A new Dao needs an entry in `RITES` (and so a clip, a prop, three beats), and a line for every kind
## in `SAID` if it is a road.  The tests check every Dao has one and no two share a clip or a prop.

const ROADS := ["sword", "wander", "heart", "formation", "alchemy", "illusion"]
## where the camera of a beat stands: [how far in front (+) or behind (-) of him, how far to his
## right, how high, what it looks at ("head", "chest", "feet", "prop", "sky"), lens]; "orbit" turns
## slowly round him at that distance
const CAMS := {
	"wide": [5.6, 2.4, 2.0, "chest", 52.0], "low": [2.6, 0.9, 0.35, "head", 46.0], "face": [1.5, 0.55, 1.5, "head", 34.0],
	"top": [0.6, 0.0, 7.5, "feet", 50.0], "back": [-3.6, 1.2, 2.2, "prop", 50.0], "prop": [2.9, -1.3, 1.25, "prop", 36.0],
	"orbit": [4.6, 0.0, 1.9, "chest", 48.0], "sky": [3.4, -1.0, 0.5, "sky", 58.0], "far": [9.0, 3.5, 3.4, "chest", 40.0],
}
## how long a form lasts (art/lib/person.py RITE_T)
const SECONDS := 4.6

## id -> kind ("road", "arm", "taboo"), key (the Dao's id in its own table), n (what the rite is
## called), clip, prop (what `prop` builds), at (where the prop stands: [forward, right, up]), col,
## face (faces.gd), fx (what the air does as it ends), beats ([text, camera]).
const RITES := {
	# ------------------------------------------------------------ the six roads
	"sword": {"kind": "road", "key": "sword", "n": "Nine Swords Bow to One", "clip": "rite_sword", "prop": "sword_wheel", "at": [0.0, 0.0, 0.0], "face": "resolve", "fx": "slash",
		"beats": [
			["Lin Feng lifts two fingers before his brow, as a child is taught to on the first morning, and for once does not think about his feet. Behind his shoulders the air begins to have edges.", "low"],
			["Nine blades of pale light open behind him like the ribs of a fan. None of them is his sword. They are every stroke he has made with it, kept, and they have all been pointing the same way.", "back"],
			["He lets the hand fall, and they bow, point down, to the one in the scabbard. A blade has one direction. He had thought that was a limit. It is only an address.", "wide"]]},
	"wander": {"kind": "road", "key": "wander", "n": "A Feather Let Go", "clip": "rite_wander", "prop": "peng_feather", "at": [0.9, 0.3, 1.5], "face": "joy", "fx": "leaves",
		"beats": [
			["A feather longer than he is tall lies across his two hands: grey above, white beneath. It weighs what a held breath weighs. Somewhere north of the north sea there is a bird that has not missed it.", "prop"],
			["He opens his arms. He does not throw it. The wind that has been waiting ninety thousand li for somebody to stop holding on takes it up, and turns it once, as one turns a thing over to look at it.", "orbit"],
			["It goes where it likes. He watches it out of sight and finds he is standing on his toes, and that nothing at all has been decided about where he will be tomorrow. He laughs out loud.", "sky"]]},
	"heart": {"kind": "road", "key": "heart", "n": "A Lamp Held Low", "clip": "rite_heart", "prop": "lotus_lamp", "at": [0.55, 0.0, 0.62], "face": "tender", "fx": "heal",
		"beats": [
			["He goes down on one knee, because the thing is done at the height of a child, or of somebody lying ill. A lamp in the shape of a lotus sits in his cupped hands. It is not bright. It was never meant to be seen by.", "face"],
			["He holds it out, low, to nobody. The petals open one at a time. Whatever is hurt within a stone's throw of that light knows where it is, the way one knows in the dark which way the door is.", "prop"],
			["His arms ache already. That is the whole of the art: the sky can be held only as long as one chooses, and then somebody must be asked. He does not put the lamp down yet.", "wide"]]},
	"formation": {"kind": "road", "key": "formation", "n": "Eight Flags Planted", "clip": "rite_formation", "prop": "bagua_field", "at": [0.0, 0.0, 0.0], "face": "resolve", "fx": "rings",
		"beats": [
			["He sinks into the horse stance and puts both palms flat to the ground, as a physician lays a hand on a chest. The land has a pulse. Nearly all of formation-craft is finding it before one begins to draw.", "low"],
			["Eight flags stand up out of the earth around him, one to each quarter and each corner, and between them the eight trigrams lie down in lines of light: three whole, three broken, and the six that are neither.", "top"],
			["Nothing is shut in. That is what the young ones get wrong. The lines only say where things already are, firmly, and the land keeps its shape because it is allowed to.", "far"]]},
	"alchemy": {"kind": "road", "key": "alchemy", "n": "Nine Turns of the Lid", "clip": "rite_alchemy", "prop": "cauldron", "at": [0.75, 0.0, 0.0], "face": "doubt", "fx": "sparks",
		"beats": [
			["A cauldron on three legs, no bigger than a rice pot, with a fire under it that he fans with the flat of his hand. He bends to listen. A furnace is not watched. It is listened to, like a sleeping child.", "prop"],
			["He lifts the lid a finger's width, nine times, and nine times lets it down. Each time a little of what is wrong with the pill goes out with the steam. Nobody has found a quicker way. Many have died of looking.", "face"],
			["On the ninth it rises of itself: one pill, round, the colour of a lit window. He catches it over his head. Borrowed time, every grain of it. He already knows who he will give it to.", "low"]]},
	"illusion": {"kind": "road", "key": "illusion", "n": "The Moon Taken Out of the Water", "clip": "rite_illusion", "prop": "moon_mirror", "at": [0.95, 0.0, 0.0], "face": "doubt", "fx": "vortex",
		"beats": [
			["A mirror of bronze stands before him on nothing, and in it a moon, though it is not night. He puts one hand over his own eyes. It is the first thing the foxes teach: you cannot fool what you are looking at.", "prop"],
			["With the other hand he reaches into the mirror to the wrist and takes the moon out. It is cold and has weight. Behind him a second Lin Feng, who has not moved at all, goes on standing where he stood.", "back"],
			["He lets it go and it hangs there, a hand's breadth from the glass. The moon in the water is still the moon. Which of the two of him is breathing is, for a moment, an open question.", "orbit"]]},
	# ------------------------------------------------------------ the eight Daos of arms
	"a_sword": {"kind": "arm", "key": "sword", "n": "Laid Along the Line", "clip": "rite_a_sword", "prop": "plumb_line", "at": [0.85, 0.0, 0.0], "face": "resolve", "fx": "glimmer",
		"beats": [
			["A thread hangs in the air before him with a lead weight on the end of it, quite still. It is the only truly straight thing he has ever seen, and a carpenter's child could have shown it to him.", "prop"],
			["He salutes with the jian upright before his face, and then lays the blade out level at the full reach of his arm, edge to the thread, so near that the thread parts the light on the steel and is not touched.", "low"],
			["He holds it there. Two edges, so that it cuts the one who holds it wrongly. The weight does not swing. For as long as he can keep his arm from shaking, he is holding it rightly.", "wide"]]},
	"a_staff": {"kind": "arm", "key": "staff", "n": "The Last Step Swept", "clip": "rite_a_staff", "prop": "leaf_ring", "at": [0.0, 0.0, 0.0], "face": "calm", "fx": "leaves",
		"beats": [
			["Leaves lie all round him, as they lay every morning for three years on nine hundred and ninety-nine steps. He takes the staff in both hands as he took the broom, low, and does not hurry.", "top"],
			["One sweep to the left and one to the right, and the leaves are in a ring, and he is in the middle of it. Not one was chosen and not one was missed. A broom does not choose which leaf.", "wide"],
			["He plants the staff and folds his hands on the top of it and rests his chin there, as the old sweeper did who taught him. He had thought those were the years before his cultivation began.", "face"]]},
	"a_sabre": {"kind": "arm", "key": "sabre", "n": "One Cut, and the Back Turned", "clip": "rite_a_sabre", "prop": "bamboo_stake", "at": [1.25, 0.0, 0.0], "face": "anger", "fx": "cross",
		"beats": [
			["A stake of green bamboo as thick as a wrist stands in the ground. He takes the sabre up behind his head in both hands and stands so, for longer than is comfortable, until there is nothing left in him but the one thing.", "low"],
			["It comes down. There is no sound to speak of. He has turned his back before the upper half begins to slide, because a man who looks to see whether his cut went home is already making the second.", "prop"],
			["The stake falls in two behind him. The second cut is an apology for the first. He has nothing to apologise for, this once, and stands breathing, with the red cloth still swinging at the pommel.", "back"]]},
	"a_spear": {"kind": "arm", "key": "spear", "n": "Through the Eye of a Coin", "clip": "rite_a_spear", "prop": "hung_coin", "at": [2.1, 0.0, 0.0], "face": "resolve", "fx": "glimmer",
		"beats": [
			["A copper cash hangs on a thread at the height of his heart, turning a little. The square hole in it is narrower than the spear's point is wide. He draws the shaft back to his hip and looks at the hole only.", "prop"],
			["He does not thrust. He walks the point out, heel, hip, shoulder, hand, the whole of him arriving along the wood, as slowly as a door is closed on a sleeper. A thousand days, the masters say. This is what they were for.", "low"],
			["The point stands in the hole and has not touched the copper. The coin has stopped turning. The point arrives; the rest of the spear is how; and the rest of the spear is him.", "wide"]]},
	"a_fan": {"kind": "arm", "key": "fan", "n": "The Candle Not Put Out", "clip": "rite_a_fan", "prop": "candle", "at": [1.0, 0.0, 0.0], "face": "joy", "fx": "vortex",
		"beats": [
			["A candle burns on a stand in front of him. He flicks the iron fan open a hand's breadth from the flame, thirteen ribs at once, hard enough to turn a blade. The flame leans over. It does not go out.", "prop"],
			["He turns on his toes with the fan at arm's length, and the wind of it goes round the candle on both sides and meets again behind. It has been told, courteously, that there is somebody here.", "orbit"],
			["He shuts the fan against his palm. The flame stands up straight. Be elsewhere, politely: he had thought the saying was about his feet. It is about what one refuses to blow out on the way past.", "face"]]},
	"a_bow": {"kind": "arm", "key": "bow", "n": "The Arrow Kept", "clip": "rite_a_bow", "prop": "straw_butt", "at": [6.0, 0.0, 0.0], "face": "sorrow", "fx": "glimmer",
		"beats": [
			["A butt of rice straw stands at the far end of the ground. He sets his feet across the line of it, raises the bow and draws to the ear. The sinew of a roc sings very quietly when it is at full stretch.", "wide"],
			["He holds. The breath goes out of him and he does not loose. Something in his stance is wrong, the left shoulder a hair too high, and he would hit all the same, and that is the reason he does not shoot.", "face"],
			["He lets the string down by inches and bows to the target, as an archer does who has missed. When the archer misses he looks for the cause in himself. It is quicker to look before.", "back"]]},
	"a_whip": {"kind": "arm", "key": "whip", "n": "Nine Reeds, None Broken", "clip": "rite_a_whip", "prop": "nine_reeds", "at": [1.7, 0.0, 0.0], "face": "calm", "fx": "splash",
		"beats": [
			["Nine reeds stand in a row before him, such as grow at the edge of any pond. He whirls the chain once round his head, nine rods of steel with a dart on the end, and it sounds like a flock getting up.", "low"],
			["He lets it out. It cannot be made to go where it is told. It goes between the first reed and the second, and back between the second and the third, to the ninth, and lies among them like a path.", "prop"],
			["Not one is bent. He draws the chain home hand over hand and it comes out as it went in. The soft overcomes the hard; ask water. He had been asking steel, and steel had not known.", "wide"]]},
	"a_brush": {"kind": "arm", "key": "brush", "n": "The Character for One", "clip": "rite_a_brush", "prop": "hung_scroll", "at": [1.15, 0.0, 0.0], "face": "calm", "fx": "glimmer",
		"beats": [
			["A length of white paper hangs before him from nothing, with a weight at the foot to keep it from the wind. He puts his left hand behind his back and lifts the iron brush. The cinnabar on it has never dried.", "prop"],
			["One stroke, left to right, at the full reach of his arm: pressed in, drawn, lifted. The character for one. It is the first a child is given and the last a master is satisfied with.", "low"],
			["He looks at it for some time with the brush raised, as a man looks who means to add something. Then he lowers the brush. A character is finished when nothing can be added.", "face"]]},
	# ------------------------------------------------------------ the forbidden shelf
	"t_blood": {"kind": "taboo", "key": "blood", "n": "The Cup Made of a Hand", "clip": "rite_t_blood", "prop": "blood_bowl", "at": [0.5, 0.0, 0.0], "face": "anger", "fx": "soot",
		"beats": [
			["He kneels to it. The scripture is eleven lines long and the first is: kneel. A bowl of black lacquer stands on the ground at his knees, and he does not remember bringing it.", "top"],
			["He draws two fingers across his palm and makes a cup of the hand, and bends his head over it and breathes in. The colour goes up his wrist under the skin like ink up a wick.", "face"],
			["It is strength. That is the whole of the trouble with it. He throws his head back, and for one breath the sweeper who came up the mountain is nowhere in his face.", "low"]]},
	"t_soul": {"kind": "taboo", "key": "soul", "n": "The Banner Raised", "clip": "rite_t_soul", "prop": "soul_banner", "at": [0.45, 0.55, 0.0], "face": "fear", "fx": "soot",
		"beats": [
			["A pole of black wood is in his right hand, and from it hangs a length of something that is not quite cloth. It stirs. There is no wind. He lifts it over his head as one lifts a lantern, to see who is there.", "low"],
			["With the other hand he beckons, once, as one beckons a child across a road. Something that was on its way elsewhere turns round. It does not want to come. It is written into the banner like a knot into a cord.", "prop"],
			["He knows the taste of grass, and a den, and four small ones who will wait there. He takes a step back from his own arm. The banner has more in it than it had, and is no heavier.", "orbit"]]},
	"t_husk": {"kind": "taboo", "key": "husk", "n": "The Bell Without a Bell", "clip": "rite_t_husk", "prop": "corpse_bell", "at": [1.5, 0.0, 0.0], "face": "anger", "fx": "soot",
		"beats": [
			["He holds his right hand up by his ear and shakes it from the wrist, as the corpse-walkers of the west do who bring the dead home. There is a bell there, of green bronze. The sound is made in the throat.", "face"],
			["A pace in front of him a figure of yellow paper, cut in the shape of a man, gets up off the ground and stands with its back to him. He points, stiffly, with two fingers. It takes one step where he points.", "prop"],
			["That was piety once: so that nobody should be buried among strangers. It is the same bell. He lowers his hand, and the thing in front of him goes on standing, waiting to be hit instead.", "back"]]},
}
const ORDER := ["sword", "wander", "heart", "formation", "alchemy", "illusion", "a_sword", "a_staff", "a_sabre", "a_spear", "a_fan", "a_bow", "a_whip", "a_brush", "t_blood", "t_soul", "t_husk"]

# ---------------------------------------------------------------- which are his
static func of_road(dao: String) -> String:
	return dao if RITES.has(dao) and str(RITES[dao].kind) == "road" else ""

static func of_arm(arm: String) -> String:
	return "a_" + arm if RITES.has("a_" + arm) else ""

static func of_taboo(id: String) -> String:
	return "t_" + id if RITES.has("t_" + id) else ""

## What the Dao of rite `id` is called.
static func dao_name(id: String) -> String:
	var r: Dictionary = RITES.get(id, {})
	match str(r.get("kind", "")):
		"road":
			return str(Data.DAOS[r.key].n)
		"arm":
			return str(Arms.WEAPONS[r.key].dao.n)
		"taboo":
			return str(Taboo.DAOS[r.key].n)
	return ""

static func colour(id: String) -> Color:
	var r: Dictionary = RITES.get(id, {})
	match str(r.get("kind", "")):
		"road":
			return Data.DAOS[r.key].col
		"arm":
			return Arms.WEAPONS[r.key].col
		"taboo":
			return Taboo.DAOS[r.key].col
	return Color.WHITE

## Whether the Dao of rite `id` is his to perform now: a road he has walked, a weapon he is an Adept
## of, a forbidden art he has sat to.
static func his(g, id: String) -> bool:
	var r: Dictionary = RITES.get(id, {})
	match str(r.get("kind", "")):
		"road":
			return g.dao_xp.has(str(r.key))
		"arm":
			return g.arms.has(str(r.key)) and Arms.tier(g, str(r.key)) >= 1
		"taboo":
			return Taboo.depth(g, str(r.key)) > 0
	return false

## Every rite that is his, in order.
static func mine(g) -> Array:
	var out: Array = []
	for id in ORDER:
		if his(g, id):
			out.append(id)
	return out

## The rite he would perform if asked for one: of the road he walks, else of the weapon in his hand,
## else the first that is his ("" if none is).
static func ready(g) -> String:
	if of_road(str(g.dao)) != "" and his(g, str(g.dao)):
		return str(g.dao)
	var a := of_arm(Arms.held(g))
	if a != "" and his(g, a):
		return a
	var m := mine(g)
	return "" if m.is_empty() else str(m[0])

## How many Daos he has performed the rite of.
static func done(g) -> int:
	var n := 0
	for id in g.rites:
		if RITES.has(str(id)) and int(g.rites[id]) > 0:
			n += 1
	return n

## A Dao has become his: its rite waits to be played (once).
static func earn(g, id: String) -> void:
	if not RITES.has(id) or g.rites.has(id) or g.rite_due.has(id):
		return
	g.rite_due.append(id)

## The rite of `id` has been performed.  Returns the lines of its scene.
static func perform(g, id: String) -> Array:
	if not RITES.has(id):
		return []
	var first: bool = not g.rites.has(id) or int(g.rites[id]) == 0
	g.rites[id] = int(g.rites.get(id, 0)) + 1
	g.rite_n = int(g.rite_n) + 1
	if first:
		g.note("Performed %s, the rite of the %s" % [str(RITES[id].n), dao_name(id)])
	return scene(id)

## The lines of the scene of rite `id` (narration: so told of "Lin Feng" and "he").
static func scene(id: String) -> Array:
	var out: Array = []
	for bt in RITES[id].beats:
		out.append(["Narrator", str(bt[0])])
	return out

## The camera of beat `k` of rite `id` (an entry of CAMS).
static func cam(id: String, k: int) -> Array:
	var bs: Array = RITES[id].beats
	return CAMS[str(bs[clampi(k, 0, bs.size() - 1)][1])]

static func cam_name(id: String, k: int) -> String:
	var bs: Array = RITES[id].beats
	return str(bs[clampi(k, 0, bs.size() - 1)][1])

static func text(g) -> String:
	return "%d of %d rites performed." % [done(g), ORDER.size()]

# ---------------------------------------------------------------- what people make of the Dao he walks
## What a witness of each kind says to the road he walks ("none": he walks none yet).
const SAID := {
	"none": {
		"hand": "No road yet, they say. Well. I had no trade till I was twenty. I carried things. You find out what you are for by being handed things, %s.",
		"kid": "You have not GOT a Dao? But you are a cultivator. That is like a dog that has not got a bark. When do you get it? Can you choose a loud one?",
		"giant": "No road under you yet, little cousin. Good. We walk about for forty years before we say what we are. You people choose at fifteen and are surprised to be wrong.",
		"elder": "Walking no Dao at all, are you. Then you can still hear advice. Make the most of it, %s. Once a young person has a Way, there is no telling them anything.",
		"watch": "No Dao on the roll for you. We like that on a gate: a man with no Way yet does what the post needs. Later they all have opinions.",
		"trade": "No Dao yet? Then you are still buying, %s. I like a customer who has not made up his mind. Look as long as you please. The ones who know what they want haggle.",
		"learned": "You walk no road yet. The Master said: at fifteen I set my heart on learning, and he did not say on what. He left it out on purpose. I have built a whole lecture on that gap.",
		"holy": "No Way yet. Then sit a while. The hall is full of people who chose one in a hurry, and are here to ask whether it can be changed.",
		"cult": "Senior has not chosen a road? The instructors say one must, by Foundation. I have lain awake over it. If you have not, then perhaps there is no hurry. May I say you said so?"},
	"sword": {
		"hand": "The Sword's Dao. I thought so; you walk as if the road were shorter than it is. Mind the cart, %s. It does not know about your road.",
		"kid": "The SWORD one! That is the best one. Do the thing with the fingers. ...Nothing happened. Do it properly. Bao's uncle says they fly. Make it fly!",
		"giant": "A sword-walker. One direction. We had a cousin like that; he walked into the sea. He was right about the direction. It was only that the land stopped.",
		"elder": "The Dao of the Sword. My father's too. He was never wrong and never at home. I do not say the two go together, %s. I only buried him.",
		"watch": "Sword Dao. Good. Something that goes forward. Half our trouble on this gate is clever people; I will take a straight one gladly. Pass.",
		"trade": "A sword-walker never haggles. Straight to the price, pays, gone. I should like it better if it did not feel like being cut. Here. No, that is the price.",
		"learned": "The Sword. One stroke, no revisions. I envy you. I have rewritten the same memorial eleven times, and each draft was a perfectly good place to stop.",
		"holy": "The Dao of the Sword. We have a blade in the hall too, in the hand of the one who guards the door. It is there to cut what one is tied by. Very seldom anybody else.",
		"cult": "Senior walks the Sword. Half my dormitory chose it after you did. The instructor says we chose you and not the sword, and will find out the difference at the first real blow."},
	"wander": {
		"hand": "The Wandering Dao. So you will be gone by morning, %s. That is nothing against you. The swallows are the same, and we are glad of them.",
		"kid": "You can go ANYWHERE? Without asking? I am not allowed past the well. Take me. Only to the bridge. I will be back before she counts us.",
		"giant": "Free Wandering. A great bird and a small bird both call their flight far. Your sage laughed at the small one. We never thought that kind, from so tall a book.",
		"elder": "A wanderer. I meant to go and see the sea, you know. Sixty years I meant it. Go and look at it for me, %s, and do not come back to tell me. I should mind.",
		"watch": "Wandering Dao. Then I shall not ask your business, since you have none. I write: passing through. I write it for clouds too, when the captain wants the book filled.",
		"trade": "A wanderer buys light and never twice. Bad customers, the best talkers. Sit down, %s. Tell me what they are paying for salt in the west and I will knock something off.",
		"learned": "Free and easy wandering. The first chapter. Everybody quotes the bird, and nobody the last line of it: that the perfect man has no self. One can see why. It is not restful.",
		"holy": "The Wandering Dao. We have brothers who walk, with a bowl, and never sleep twice in a place. It is harder than the hall. In the hall, one can hide.",
		"cult": "Senior walks Free Wandering. The registrar hates it: he cannot put a wanderer on a duty roster. He has you down for the east wall on the ninth. He says you will not come. He is hoping."},
	"heart": {
		"hand": "The Heart's Dao. Then you will know what to do about my wife's cough, %s. No? Only to stop and listen to it? ...Well. Nobody has done that either.",
		"kid": "My mother says you have the kind one. Does it hurt, being kind? Bao says it does. He gave me half his cake once and then he looked at it all afternoon.",
		"giant": "Compassion, little cousin. You take care where you put your feet. We know that Dao. We have had to walk it since the first of you were built under us.",
		"elder": "The Compassionate Heart. You will be tired, then. I nursed three of my own to the end and I know that tiredness. Sit, %s. Nobody ever tells the one who carries to sit.",
		"watch": "Heart Dao. I will tell you what we see on a gate: the ones who walk it are robbed first. And the town they are robbed in is ashamed, after. That is worth a good deal, to a watch.",
		"trade": "The Heart's Dao. Then I will not sell you this one, %s. It is not good. Take that one. ...I do not know why I said that. I have had this one on the stall a month.",
		"learned": "Compassion. Mencius has the child at the well: anybody who saw it would start forward. He does not say anybody would get there. That part he left to people like you.",
		"holy": "The Heart's Dao. Then there is nothing I can tell you, and a bowl I can give you. The one teaches the other. Eat, %s. You have the look of somebody who fed three others first.",
		"cult": "Senior walks the Heart. The herb garden sisters say it is the one road nobody is ever a Master of in their own opinion. I thought that was sad. They said it was the test."},
	"formation": {
		"hand": "Formations. Then tell me why my roof leaks only over the bed, %s. No, do not laugh. A man who knows where things ought to stand is a man I want in my house.",
		"kid": "You draw lines and things CANNOT get out? Draw one round my sister. She would not even know. She never looks down.",
		"giant": "The Dao of Formations. You set small stones so that large things keep off. We have noticed, little cousin. We step round. It would be rude to show you we need not.",
		"elder": "Formations. A patient man's road. You will like it better at seventy, %s, when you have seen which of your lines the rain kept and which it laughed at.",
		"watch": "Formation Dao. Now that is a cultivator a watch can talk to. Come and look at the west gate. No, truly. We have argued for a year about where the second lantern goes.",
		"trade": "Formations. You will see it at once, then: my stall stands where three lanes meet, and it took me nine years to be let stand here. I never drew a line. I only would not move.",
		"learned": "The Dao of Formations. The Changes in eight signs. I have read it for thirty years and can tell you what every line means and not one thing it is about.",
		"holy": "Formations. The hall is built on one: door to the south, bell to the east. I do not think it keeps anything out. I think it tells whoever comes in where to put their sorrow down.",
		"cult": "Senior walks Formations. We were set to copy the Bagua Array from the wall. Mine came out with nine sides. The instructor looked at it for a long time, and then asked me not to stand in it."},
	"alchemy": {
		"hand": "The Cauldron's Dao. I knew it; you smell of smoke, %s, and not wood smoke. Have you one for a back? Not to mend it. Only so that I can stop thinking about it.",
		"kid": "You make PILLS? Is there one that makes you tall? Is there one for sums? ...Then what are they FOR?",
		"giant": "A cauldron-walker. Your pills are very small. One of ours took a jar of them once for a headache. He said it was like being argued with by a great many ants.",
		"elder": "The Dao of the Cauldron. Every pill is borrowed, the saying goes. I have borrowed a good many, %s. I am not sorry. I only wish I had asked at the time what the interest was.",
		"watch": "Cauldron Dao. Declare what is in the gourd, please. Not for the duty. The last alchemist through here had something in his that got out, and we had two days of a blue goat.",
		"trade": "An alchemist! Sit down. What do you pay for cinnabar? No, what do you really pay. ...I see. Then we can do business, %s, because somebody has been robbing you.",
		"learned": "The Cauldron. Ge Hong wrote three hundred chapters on it and died, they say, looking as if asleep, and light as an empty robe. One could wish he had said which chapter did it.",
		"holy": "The Dao of the Cauldron. The brothers take no pills, by the rule. The abbot keeps one in his sleeve all the same, for other people's last hours. He says that is a different rule.",
		"cult": "Senior walks the Cauldron. I burnt the refining hall floor last month. Only a little. The instructor said every alchemist has, and showed me the place where you did. It has a railing round it."},
	"illusion": {
		"hand": "The Mirror's Dao. Then how do I know it is you, %s? ...Because you look tired. That is clever of me. Nobody bothers to make a false thing look tired.",
		"kid": "Do me! Make another me! Then HE can go to school. ...It would only stand there? That is all I do at school.",
		"giant": "The Mirror. You make a second small one where there was one. Little cousin, from up here it was never easy to tell you apart. Now you are only being unkind.",
		"elder": "The Mirror's Dao. I see my husband in the yard some mornings, and he is fourteen years dead. I do not need telling it is not him, %s. I should thank you not to mend it.",
		"watch": "Mirror Dao. I am to count you once, the captain says, however many of you come through. I have counted one. If there are more of you I do not wish to be told.",
		"trade": "The Mirror. I will have the coin on the board, please, %s, where I can ring it. Nothing against you. I ring my own mother's. It is how we say good morning.",
		"learned": "The Mirror. The butterfly, and the man who woke. The schools argue which was dreaming. I think the master's point was that the butterfly did not lie awake over it.",
		"holy": "The Dao of the Mirror. All things are as a dream, a bubble, a shadow: we chant that at dawn. You will forgive us for finding your art less remarkable than the fox-folk do.",
		"cult": "Senior walks the Mirror. Is this Senior? The foxes sent a reflection to the lecture hall once, as a joke. It took notes for a month. It is still the best set of notes we have."},
}
const SAID_CLIP := {
	"none": "shrug", "sword": "nod", "wander": "wave", "heart": "bow", "formation": "think", "alchemy": "point", "illusion": "shake",
}

## How a witness of `kind` answers the road he walks: {line, clip}.
static func said(g, kind: String) -> Dictionary:
	var d := str(g.dao) if SAID.has(str(g.dao)) else "none"
	var k := kind if SAID[d].has(kind) else "hand"
	return {"line": str(SAID[d][k]).replace("%s", str(g.address())), "clip": str(SAID_CLIP[d])}

## What anybody says to the Dao of the weapon in his hand, once he is an Adept of it.
const ARM_SAID := {
	"sword": "A jian, and carried as if it weighed nothing. The gentleman of arms, my grandfather called it. He said you can tell a household by whether the jian on the wall has ever been down.",
	"staff": "That is a broom handle, %s. Do not tell me it is not; I have swept this street thirty years. ...An Adept, of that? Then I have been armed all my life and nobody said.",
	"sabre": "That is a bandit's sabre. I know the red cloth. I do not ask how you came by it, %s. I only notice that the road through the bamboo has been quiet since somebody did.",
	"spear": "A spear taller than the one who carries it. A hundred days for the sabre, they say, and a thousand for that. You do not look as if you had a thousand days to spare.",
	"fan": "An iron fan. You could shade yourself with that, %s, or break my arm. I like a weapon a person can also be polite with. There ought to be more of them.",
	"bow": "A horn bow. Strung, too. My uncle shot. He said the trouble with a bow is that whatever goes wrong has gone wrong before the arrow leaves, and so one cannot blame the arrow.",
	"whip": "A chain. Nine links. I have seen a carter with a whip take a fly off a mule's ear. He said it is all in not minding where the far end goes. He was a restful man.",
	"brush": "Is that a brush? Of iron? Then write me my name, %s. Nobody ever has. ...In the air will do. I shall remember where it was.",
}

static func arm_said(g) -> String:
	var a := Arms.held(g)
	if not ARM_SAID.has(a) or Arms.tier(g, a) < 1:
		return ""
	return str(ARM_SAID[a]).replace("%s", str(g.address()))

## The people of the story who have known him longest, on the road he walks (or none).
const NAMED := {
	"elder": {
		"none": "You walk no Dao yet, child, and you ask me which. I shall not say. I chose mine to please my master, and it was forty years before I could tell whether I liked it.",
		"sword": "The Sword. I thought it would be, since the first morning you held a broom like one. Keep the broom, child. A sword only knows how to arrive.",
		"wander": "Free Wandering. So the sect will see you at festivals. Good. A mountain needs somebody who comes back to it by choice; the rest of us only never left.",
		"heart": "The Heart. It is the one road I have never walked and always been walked over by. Be kinder to yourself than you are to the rest of us, child. It is the same art.",
		"formation": "Formations. Then you will have noticed the sect's own array is a hair out, at the north-east flag. I set it so, sixty years ago. Something ought to be able to get in.",
		"alchemy": "The Cauldron. Then I shall stop hiding the good cinnabar. Borrow wisely, child. I have outlived everybody I ever made a pill for, and I count them when I cannot sleep.",
		"illusion": "The Mirror. I did not expect it of you. You were always the worst liar in the outer court. Perhaps that is what the road is for: to learn what you cannot do without one."},
	"smith": {
		"none": "No Dao yet. Then do not ask me for a blade made to one. I will make you a plain one, and you can ruin it finding out.",
		"sword": "Sword Dao. Then the jian is the right length and you may stop asking me. It is the arm that is short. Arms grow. Steel does not.",
		"wander": "A wanderer. So you want it light, and want it yesterday, and will not be here to collect it. I know your kind. I have a shelf of them, paid for.",
		"heart": "The Heart's Dao, and you come to a smith. Sense. Somebody must make the needle. I will draw you one finer than a hair, and you will tell nobody I can.",
		"formation": "Formations. Flags need ferrules, and plates need casting true. Do you know how true? I do. Your formation-masters draw a circle and send it to me to be made round.",
		"alchemy": "A cauldron-walker. Three legs, a belly, a lid that seats. I cast the one you burnt the floor with. It was sound. I went and looked, afterwards, to be sure.",
		"illusion": "Mirrors. I polish bronze for the fox-folk, did you know? Forty days a face. They look in it once and say: yes, that is not us. And pay."},
	"yue_ling": {
		"none": "You have not chosen a road, Lin Feng. I am glad. I was a lotus for three hundred years, and nobody asked a lotus what it meant to be. One simply opened.",
		"sword": "The Sword's Dao. I shall need more thread. I do not mind. It is only that a straight line goes through things, Lin Feng, and I am the one who sees the far side.",
		"wander": "Free Wandering. Then I shall learn to pack. I have rooted in one pond for three hundred years, Lin Feng. Do not think I am being dragged. I am finding out what legs are for.",
		"heart": "You walk the Heart, as I do, and you are worse at stopping than I am. One of us must learn to rest, Lin Feng, and it cannot be the patient. I shall draw lots.",
		"formation": "Formations. You draw the lines and I stand inside them, and I have never once been touched. I ought to thank you. I find I want, a little, to see what is outside.",
		"alchemy": "The Cauldron. So now there are two of us who think a thing can be mended with enough care. Somebody should warn the world, Lin Feng. It will not be let alone.",
		"illusion": "The Mirror's Dao. I can always tell which is you, Lin Feng. The reflection stands better. Do not look like that. It is why I like the other one."},
}

## What `id` has to say of the road he walks ("" if they have no word of their own).
static func word(g, id: String) -> String:
	if not NAMED.has(id):
		return ""
	var d := str(g.dao) if NAMED[id].has(str(g.dao)) else "none"
	return str(NAMED[id][d])

# ---------------------------------------------------------------- the thing each is done with
const _WOOD := Color("6a4a30")
const _BRONZE := Color("7a9a80")
const _PAPER := Color("ece6d2")
const _IRON := Color("5a5e66")

static func _rod(b: MB, a: Vector3, c: Vector3, r: float, col: Color) -> void:
	b.limb(a, c, r, r, col, 5)

## The thing rite `id` is done with: a node standing at the hero's feet, facing as he faces (+Z is in
## front of him).  A child called "move" is what `tick` moves; "move2" a second such.
static func prop(id: String) -> Node3D:
	var root := Node3D.new()
	if not RITES.has(id):
		return root
	var r: Dictionary = RITES[id]
	var col: Color = colour(id)
	var b := MB.new()    # what stands still
	var g := MB.new()    # what glows
	var m := MB.new()    # what moves
	var mg := MB.new()   # what moves and glows
	var m2 := MB.new()   # a second thing that moves
	var pivot := Vector3.ZERO
	var pivot2 := Vector3.ZERO
	var wd := MB.tag(_WOOD, MB.WOOD)
	var br := MB.tag(_BRONZE, MB.METAL)
	var ir := MB.tag(_IRON, MB.METAL)
	var pp := MB.tag(_PAPER, MB.CLOTH)
	match str(r.prop):
		"sword_wheel":
			# nine blades of light fanned behind the shoulders
			pivot = Vector3(0, 1.55, -0.45)
			for k in 9:
				var a := deg_to_rad(-72.0 + 18.0 * k)
				var dir := Vector3(sin(a), cos(a), 0)
				mg.limb(dir * 0.35, dir * 1.45, 0.045, 0.004, Color(col.r, col.g, col.b, 0.8), 4)
				mg.box(dir * 0.33, Vector3(0.16, 0.025, 0.03), Color(1, 1, 1, 0.8), Vector3(0, 0, -a))
		"peng_feather":
			# one great feather, grey above and white beneath
			pivot = Vector3(0, 0, 0)
			_rod(m, Vector3(-0.85, 0, 0), Vector3(0.85, 0.06, 0), 0.012, MB.tag(Color("e8e4d8"), MB.CLOTH))
			for k in 14:
				var x := -0.7 + 0.11 * k
				var w := 0.3 * sin(PI * (k + 1.5) / 16.0) + 0.05
				m.leaf(Vector3(x, 0.01, 0), Vector3(x + 0.12, 0.0, w), 0.1, MB.tag(Color("8a94a0"), MB.CLOTH), Vector3.ZERO, MB.tag(Color("d8dce4"), MB.CLOTH))
				m.leaf(Vector3(x, 0.01, 0), Vector3(x + 0.12, 0.0, -w), 0.1, MB.tag(Color("f0eee8"), MB.CLOTH), Vector3.ZERO, MB.tag(Color("c8ccd4"), MB.CLOTH))
		"lotus_lamp":
			# a lamp in the shape of a lotus, to be held in two hands
			b.hemi(Vector3(0, 0.0, 0), Vector3(0.09, 0.05, 0.09), MB.tag(Color("5a8a5a"), MB.FOLIAGE), Vector3(PI, 0, 0))
			for k in 8:
				var a2 := TAU * k / 8.0
				var d2 := Vector3(sin(a2), 0, cos(a2))
				m.leaf(d2 * 0.04 + Vector3(0, 0.02, 0), d2 * 0.17 + Vector3(0, 0.13, 0), 0.09, MB.tag(col, MB.CLOTH), Vector3.ZERO, MB.tag(Color("fff0f4"), MB.CLOTH))
			g.ball(Vector3(0, 0.08, 0), 0.05, Color(1.0, 0.86, 0.6, 0.9), true)
			g.ball(Vector3(0, 0.08, 0), 0.22, Color(1.0, 0.8, 0.6, 0.25), true)
		"bagua_field":
			# eight flags and the eight trigrams between them, on the ground
			for k in 8:
				var a3 := TAU * k / 8.0
				var d3 := Vector3(sin(a3), 0, cos(a3))
				_rod(b, d3 * 2.3, d3 * 2.3 + Vector3(0, 1.3, 0), 0.02, wd)
				b.quad4(d3 * 2.3 + Vector3(0, 1.28, 0), d3 * 2.3 + Vector3(0, 0.92, 0), d3.rotated(Vector3.UP, 0.16) * 2.36 + Vector3(0, 0.98, 0), d3.rotated(Vector3.UP, 0.16) * 2.36 + Vector3(0, 1.22, 0),
					MB.tag(col, MB.CLOTH), MB.tag(col, MB.CLOTH), MB.tag(col.darkened(0.2), MB.CLOTH), MB.tag(col.darkened(0.2), MB.CLOTH))
				# the trigram of this quarter: three lines, whole or broken by the bits of k
				for j in 3:
					var rr := 1.2 + 0.2 * j
					if (k >> j) & 1 == 1:
						mg.arc(Vector3(0, 0.03, 0), rr, 0.07, a3 - 0.28, a3 + 0.28, Color(col.r, col.g, col.b, 0.85), 6)
					else:
						mg.arc(Vector3(0, 0.03, 0), rr, 0.07, a3 - 0.28, a3 - 0.05, Color(col.r, col.g, col.b, 0.85), 3)
						mg.arc(Vector3(0, 0.03, 0), rr, 0.07, a3 + 0.05, a3 + 0.28, Color(col.r, col.g, col.b, 0.85), 3)
			g.torus(Vector3(0, 0.03, 0), 2.0, 0.03, Color(col.r, col.g, col.b, 0.6))
			g.torus(Vector3(0, 0.03, 0), 0.9, 0.025, Color(col.r, col.g, col.b, 0.6))
		"cauldron":
			# a cauldron on three legs with a fire under it; the lid lifts, and a pill
			for k in 3:
				var a4 := TAU * k / 3.0
				_rod(b, Vector3(sin(a4) * 0.2, 0.0, cos(a4) * 0.2), Vector3(sin(a4) * 0.16, 0.34, cos(a4) * 0.16), 0.03, br)
			b.lathe(Vector3(0, 0.3, 0), [Vector2(0.1, 0.0), Vector2(0.24, 0.1), Vector2(0.27, 0.24), Vector2(0.22, 0.36), Vector2(0.24, 0.4)], br, 12)
			for sx in [-1.0, 1.0]:
				b.torus(Vector3(0.25 * sx, 0.66, 0), 0.06, 0.015, br, Vector3(0, 0, PI / 2))
			g.ball(Vector3(0, 0.1, 0), 0.12, Color(1.0, 0.55, 0.2, 0.8), true)
			g.cone(Vector3(0, 0.18, 0), 0.08, 0.2, Color(1.0, 0.8, 0.3, 0.7))
			pivot = Vector3(0, 0.72, 0)
			m.hemi(Vector3.ZERO, Vector3(0.24, 0.07, 0.24), br)
			m.ball(Vector3(0, 0.08, 0), 0.035, br)
			pivot2 = Vector3(0, 0.6, 0)
			m2.ball(Vector3.ZERO, 0.045, Color(1.0, 0.82, 0.45))
		"moon_mirror":
			# a bronze mirror standing on nothing, and the moon that is taken out of it
			b.disc(Vector3(0, 1.35, 0), 0.42, MB.tag(Color("c8d4e0"), MB.METAL), 20, MB.tag(Color("8a98a8"), MB.METAL), Vector3(PI / 2, 0, 0))
			b.torus(Vector3(0, 1.35, 0), 0.43, 0.035, br, Vector3(PI / 2, 0, 0), true)
			g.disc(Vector3(0, 1.35, -0.01), 0.3, Color(col.r, col.g, col.b, 0.35), 16, Color(col.r, col.g, col.b, 0.0), Vector3(-PI / 2, 0, 0))
			pivot = Vector3(0, 1.35, -0.02)
			mg.ball(Vector3.ZERO, 0.13, Color(0.95, 0.95, 1.0, 0.95), true)
			mg.ball(Vector3.ZERO, 0.28, Color(0.8, 0.8, 1.0, 0.22), true)
		"plumb_line":
			# a thread with a lead weight on it, hung from nothing
			_rod(b, Vector3(0, 2.2, 0), Vector3(0, 0.62, 0), 0.004, Color("f0f0f0"))
			b.cone(Vector3(0, 0.5, 0), 0.045, 0.14, ir, Vector3(PI, 0, 0))
			b.cyl(Vector3(0, 0.6, 0), 0.03, 0.05, ir)
			g.ball(Vector3(0, 1.38, 0), 0.03, Color(col.r, col.g, col.b, 0.7), true)
		"leaf_ring":
			# fallen leaves, swept into a ring round him
			for k in 46:
				var a5 := TAU * k / 46.0 + 0.3 * sin(k * 2.1)
				var rr2 := 1.5 + 0.22 * sin(k * 1.7)
				var c5: Color = [Color("c8742a"), Color("d8a038"), Color("8a4a24"), Color("b85a2a")][k % 4]
				var p5 := Vector3(sin(a5) * rr2, 0.03 + 0.02 * (k % 3), cos(a5) * rr2)
				m.leaf(p5, p5 + Vector3(0.14 * cos(k * 3.3), 0.01, 0.14 * sin(k * 3.3)), 0.07, MB.tag(c5, MB.FOLIAGE))
		"bamboo_stake":
			# a green bamboo as thick as a wrist; the upper half slides off the cut
			var gr := MB.tag(Color("6a9a4a"), MB.WOOD)
			b.cyl(Vector3(0, 0.45, 0), 0.05, 0.9, gr)
			for k in 2:
				b.torus(Vector3(0, 0.3 + 0.35 * k, 0), 0.052, 0.008, MB.tag(Color("4a7a34"), MB.WOOD))
			pivot = Vector3(0, 0.9, 0)
			m.cyl(Vector3(0, 0.4, 0), 0.05, 0.8, gr)
			m.torus(Vector3(0, 0.25, 0), 0.052, 0.008, MB.tag(Color("4a7a34"), MB.WOOD))
			m.torus(Vector3(0, 0.6, 0), 0.052, 0.008, MB.tag(Color("4a7a34"), MB.WOOD))
			m.disc(Vector3(0, 0.0, 0), 0.05, MB.tag(Color("d8e0b0"), MB.WOOD), 8)
		"hung_coin":
			# a copper cash on a thread, at the height of the heart
			_rod(b, Vector3(0, 2.3, 0), Vector3(0, 1.38, 0), 0.003, Color("f0f0f0"))
			pivot = Vector3(0, 1.3, 0)
			m.torus(Vector3.ZERO, 0.06, 0.022, MB.tag(Color("b87a3a"), MB.METAL), Vector3(0, 0, PI / 2), true)
			for k in 4:
				var a6 := TAU * k / 4.0
				m.box(Vector3(0, sin(a6) * 0.03, cos(a6) * 0.03), Vector3(0.012, 0.012 if k % 2 == 0 else 0.07, 0.07 if k % 2 == 0 else 0.012), MB.tag(Color("8a5a2a"), MB.METAL))
		"candle":
			# a candle on a stand; the flame leans and does not go out
			_rod(b, Vector3(0, 0, 0), Vector3(0, 1.0, 0), 0.02, ir)
			b.cyl(Vector3(0, 0.02, 0), 0.14, 0.04, ir)
			b.cyl(Vector3(0, 1.0, 0), 0.08, 0.02, ir)
			b.cyl(Vector3(0, 1.1, 0), 0.025, 0.2, MB.tag(Color("f0e8d0"), MB.CLOTH))
			pivot = Vector3(0, 1.2, 0)
			mg.cone(Vector3(0, 0.06, 0), 0.03, 0.12, Color(1.0, 0.8, 0.35, 0.95))
			mg.ball(Vector3(0, 0.05, 0), 0.14, Color(1.0, 0.7, 0.3, 0.25), true)
		"straw_butt":
			# a butt of rice straw on a trestle, with no arrow in it
			for sx2 in [-1.0, 1.0]:
				_rod(b, Vector3(0, 0, 0.45 * sx2), Vector3(0.25, 1.5, 0.3 * sx2), 0.035, wd)
				_rod(b, Vector3(0.6, 0, 0.3 * sx2), Vector3(0.25, 1.5, 0.3 * sx2), 0.035, wd)
			b.cyl(Vector3(0.12, 1.1, 0), 0.55, 0.22, MB.tag(Color("d8c070"), MB.CLOTH), Vector3(0, 0, PI / 2), 14)
			b.disc(Vector3(0.0, 1.1, 0), 0.4, MB.tag(Color("ece0b0"), MB.CLOTH), 14, MB.tag(Color("c8b060"), MB.CLOTH), Vector3(0, 0, PI / 2))
			b.disc(Vector3(-0.005, 1.1, 0), 0.12, MB.tag(Color("b03a2a"), MB.CLOTH), 10, MB.tag(Color("b03a2a"), MB.CLOTH), Vector3(0, 0, PI / 2))
		"nine_reeds":
			# nine reeds in a row across his way; they sway and are not broken
			for k in 9:
				var z := -0.8 + 0.2 * k
				var bend := 0.05 * sin(k * 1.9)
				m.limb(Vector3(0, 0, z), Vector3(bend, 1.2 + 0.1 * (k % 3), z + bend), 0.012, 0.005, MB.tag(Color("7a9a4a"), MB.FOLIAGE), 4)
				m.sph(Vector3(bend, 1.24 + 0.1 * (k % 3), z + bend), Vector3(0.02, 0.09, 0.02), MB.tag(Color("6a4a2a"), MB.FOLIAGE))
			b.sph(Vector3(0, 0.0, 0), Vector3(0.35, 0.03, 1.1), MB.tag(Color("5a7a6a"), MB.STONE))
		"hung_scroll":
			# white paper hung from nothing, with a weight at the foot; the stroke appears on it
			b.box(Vector3(0, 1.5, 0), Vector3(0.012, 1.3, 0.9), pp)
			_rod(b, Vector3(0, 2.16, -0.48), Vector3(0, 2.16, 0.48), 0.02, wd)
			_rod(b, Vector3(0, 0.84, -0.48), Vector3(0, 0.84, 0.48), 0.025, wd)
			pivot = Vector3(-0.012, 1.55, 0)
			m.box(Vector3.ZERO, Vector3(0.006, 0.07, 0.66), MB.tag(Color("b8281e"), MB.CLOTH))
			m.box(Vector3(0, 0.012, 0.3), Vector3(0.006, 0.1, 0.1), MB.tag(Color("b8281e"), MB.CLOTH))
		"blood_bowl":
			# a bowl of black lacquer at his knees
			b.lathe(Vector3(0, 0.0, 0), [Vector2(0.06, 0.0), Vector2(0.16, 0.05), Vector2(0.2, 0.11)], MB.tag(Color("181214"), MB.STONE), 12)
			b.disc(Vector3(0, 0.09, 0), 0.17, MB.tag(Color("7a1410"), MB.CLOTH), 12)
			pivot = Vector3(0, 0.1, 0)
			mg.ball(Vector3.ZERO, 0.09, Color(col.r, col.g, col.b, 0.5), true)
			for k in 5:
				var a7 := TAU * k / 5.0
				mg.limb(Vector3(sin(a7) * 0.1, 0, cos(a7) * 0.1), Vector3(sin(a7 + 0.6) * 0.16, 0.55 + 0.08 * k, cos(a7 + 0.6) * 0.16), 0.012, 0.002, Color(col.r, col.g, col.b, 0.7), 4)
		"soul_banner":
			# a pole of black wood and a length of something that is not quite cloth
			_rod(b, Vector3(0, 0, 0), Vector3(0, 2.7, 0), 0.025, MB.tag(Color("1a1620"), MB.WOOD))
			_rod(b, Vector3(0, 2.6, 0), Vector3(0, 2.6, -0.5), 0.015, MB.tag(Color("1a1620"), MB.WOOD))
			pivot = Vector3(0, 2.6, -0.25)
			m.ribbon([Vector3(0, 0, 0), Vector3(0.05, -0.5, 0), Vector3(-0.05, -1.0, 0), Vector3(0.04, -1.5, 0)], [0.5, 0.5, 0.46, 0.3], Vector3(0, 0, 1), MB.tag(Color("241c34"), MB.CLOTH), MB.tag(col.darkened(0.5), MB.CLOTH))
			for k in 5:
				mg.ball(Vector3(0.03, -0.25 - 0.26 * k, 0.14 * sin(k * 2.3)), 0.05, Color(0.85, 0.85, 1.0, 0.6), true)
		"corpse_bell":
			# a figure of yellow paper cut in the shape of a man, and a talisman on its brow
			pivot = Vector3(0, 0, 0)
			var yl := MB.tag(Color("d8c060"), MB.CLOTH)
			m.box(Vector3(0, 0.95, 0), Vector3(0.36, 0.6, 0.01), yl)
			m.disc(Vector3(0, 1.42, 0), 0.14, yl, 10, yl, Vector3(PI / 2, 0, 0))
			for sx3 in [-1.0, 1.0]:
				m.box(Vector3(0.11 * sx3, 0.34, 0), Vector3(0.12, 0.66, 0.01), yl)
				m.box(Vector3(0.3 * sx3, 1.05, 0), Vector3(0.24, 0.1, 0.01), yl, Vector3(0, 0, -0.5 * sx3))
			m.box(Vector3(0, 1.42, -0.012), Vector3(0.07, 0.2, 0.004), MB.tag(Color("b8281e"), MB.CLOTH))
			g.ball(Vector3(0, 0.05, 0), 0.3, Color(col.r, col.g, col.b, 0.2), true)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc()))
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not m.is_empty() or not mg.is_empty():
		var mv := Node3D.new()
		mv.name = "move"
		mv.position = pivot
		root.add_child(mv)
		if not m.is_empty():
			MB.mesh_node(mv, m.build(MB.mat_vc()))
		if not mg.is_empty():
			MB.mesh_node(mv, mg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mv.set_meta("home", pivot)
	if not m2.is_empty():
		var mv2 := Node3D.new()
		mv2.name = "move2"
		mv2.position = pivot2
		root.add_child(mv2)
		MB.mesh_node(mv2, m2.build(MB.emissive(Color(1.0, 0.82, 0.45), 2.0)))
		mv2.set_meta("home", pivot2)
	root.set_meta("rite", id)
	return root

## Move what moves of the prop of rite `id`: `k` is how far through the form he is (0..1, turning
## over with each beat), `t` the time since the rite began.
static func tick(root: Node3D, id: String, k: float, t: float) -> void:
	if root == null or not RITES.has(id):
		return
	var mv := root.get_node_or_null("move") as Node3D
	var mv2 := root.get_node_or_null("move2") as Node3D
	var home: Vector3 = mv.get_meta("home", Vector3.ZERO) if mv != null else Vector3.ZERO
	var e := smoothstep(0.25, 0.7, k)
	match str(RITES[id].prop):
		"sword_wheel":
			mv.scale = Vector3.ONE * lerpf(0.05, 1.0, smoothstep(0.1, 0.5, k))
			mv.rotation = Vector3(0, 0, PI * smoothstep(0.62, 0.95, k))
		"peng_feather":
			mv.position = home + Vector3(0, 1.6 * e * e + 0.08 * sin(t * 1.7), 0.9 * e)
			mv.rotation = Vector3(0.5 * sin(t * 0.9) * e, TAU * e, 0.3 * sin(t * 1.3))
		"lotus_lamp":
			mv.scale = Vector3(lerpf(0.55, 1.15, e), 1.0, lerpf(0.55, 1.15, e))
			root.position.y = float(root.get_meta("y0", root.position.y)) + 0.0
		"bagua_field":
			mv.scale = Vector3.ONE * lerpf(0.2, 1.0, smoothstep(0.15, 0.6, k))
			mv.rotation.y = t * 0.12
		"cauldron":
			# the lid lifted nine times a form; the pill rises on the last
			mv.position = home + Vector3(0, 0.06 * absf(sin(k * PI * 9.0)) * (1.0 if k < 0.8 else 0.0) + 0.5 * smoothstep(0.8, 0.95, k), 0)
			mv.rotation.z = 0.5 * smoothstep(0.8, 0.95, k)
			if mv2 != null:
				mv2.position = (mv2.get_meta("home") as Vector3) + Vector3(-0.3 * smoothstep(0.8, 1.0, k), 1.35 * smoothstep(0.78, 1.0, k), 0)
				mv2.visible = k > 0.76
		"moon_mirror":
			mv.position = home + Vector3(0, 0.04 * sin(t * 1.4), -0.5 * e)
		"leaf_ring":
			mv.scale = Vector3(lerpf(1.5, 1.0, e), 1.0, lerpf(1.5, 1.0, e))
			mv.rotation.y = 0.6 * (1.0 - e)
		"bamboo_stake":
			var f := smoothstep(0.56, 0.95, k)
			mv.position = home + Vector3(0, -0.12 * f, 0.18 * f)
			mv.rotation.x = 1.35 * f * f
		"hung_coin":
			mv.rotation.y = t * 2.2 * (1.0 - smoothstep(0.5, 0.8, k))
		"candle":
			mv.rotation.z = 1.0 * sin(clampf((k - 0.22) / 0.4, 0.0, 1.0) * PI)
		"nine_reeds":
			mv.rotation.x = 0.1 * sin(t * 2.0) * smoothstep(0.3, 0.6, k) * (1.0 - smoothstep(0.8, 1.0, k))
		"hung_scroll":
			mv.scale = Vector3(1.0, 1.0, maxf(0.001, smoothstep(0.34, 0.6, k)))
			mv.position = home + Vector3(0, 0, 0.33 * (1.0 - smoothstep(0.34, 0.6, k)))
		"blood_bowl":
			mv.scale = Vector3(1.0, lerpf(0.05, 1.0, e), 1.0)
			mv.rotation.y = t * 0.8
		"soul_banner":
			mv.rotation = Vector3(0.12 * sin(t * 1.1), 0, 0.1 * sin(t * 0.7))
		"corpse_bell":
			var up := smoothstep(0.3, 0.55, k)
			mv.rotation.x = -PI / 2 * (1.0 - up)
			mv.position = home + Vector3(0, 0.02, 0.35 * smoothstep(0.7, 0.9, k))
