class_name Mail
extends RefCounted
## The post (the Lost Horse release): letters that find the hero, and bags to carry.
##
## For twenty-four chapters nobody could reach Lin Feng unless he walked up to them.  Now **whoever
## answers for a town keeps the post** (`POSTS`: one counter a region, offices.gd), and three things
## happen at it:
##
##   * **letters arrive** (`LETTERS`): written by the people of the story as it goes on (`after`: a
##     step, and `wait` more steps for the carrier), and most of them **only to the journey that chose
##     a thing** (`needs`: a crossroads and the answer given, echoes.gd), so that what was decided
##     writes back: the bandits set to mending the road send the first day's toll; the ones driven
##     over the pass send a list of names.  A letter is kept at every counter until it is asked for,
##     may have something in it (`gift`), and stays in the satchel to be read again;
##   * **some can be answered** (`reply`: two answers), and the answer brings **another letter**
##     later (`on`: the letter and the answer it follows).  Nothing is tipped by it and nothing
##     needs it;
##   * **the post-bag can be carried** (`bag_offer`, `take_bag`, `deliver`): a counter has a sealed bag
##     for another counter of the same realm once a day, paid for by the road when it is handed over.
##
## No step, trial, notice or ending asks for any of this, "Not today" is the first line at every
## counter, and the bot neither asks for letters nor carries a bag: its journey is the same.

## the counters of the post: whoever answers for a town (offices.gd), one a region
const POSTS := ["treasurer", "head_qingshi", "post_cloudfoot", "reeve_well", "harbour_longmen", "guild_tushan", "warden_yanggu",
	"speaker_featherfall", "reeve_tearwater", "registrar_youdu", "reeve_landfall"]
## how many steps of the story a carrier takes, unless a letter says otherwise
const WAIT := 10
## how many bags can be carried at once, and what one pays a region of road
const BAGS := 3
const BAG_BASE := 30.0
const BAG_LV := 8.0

const LETTERS := {
	# ---- the post itself, and home
	"ge_satchel": {"from": "Postmaster Ge of Cloudfoot", "after": "s_ironfang", "wait": 2,
		"lines": ["To Lin Feng, of the Azure Cloud Sect, wherever met with. The post has opened a satchel in your name. Whatever is addressed to you will be at whichever counter you ask at: mine, Headman Luo's, any of them. Do not ask how. I have run this office thirty years and I do not ask how.",
			"Whoever answers for a town keeps its counter. Most of them also have a sealed bag that wants carrying to another town, and the road pays for that on arrival. I mention it because you appear to walk everywhere anyway."]},
	"wen_first": {"from": "Granny Wen the Midwife", "after": "s_ironfang", "wait": 4, "gift": {"item": "hp_pill", "n": 2},
		"lines": ["They say at the well that you put down Iron Fang. I delivered that one, you know, forty years back. Came out shouting then too. I am not surprised by any of it.",
			"I have put two of Mo's pills in with this. The carrier says medicines are not allowed in the post. The carrier was also one of mine, so they are in the post. Have you eaten?"],
		"reply": {"ask": "Granny Wen asks if you have eaten.", "options": [
			{"id": "eaten", "label": "\"I have eaten.\"", "desc": "It is what one says. She will know exactly what it means."},
			{"id": "truth", "label": "\"Not since yesterday.\"", "desc": "The truth, which she will act on."}]}},
	"wen_eaten": {"from": "Granny Wen the Midwife", "on": ["wen_first", "eaten"], "after": "s_roc",
		"lines": ["\"I have eaten.\" Four words, and the brush pressed too hard on every one. You never could lie on paper, child. Eat something. I am not going to send food again. I am going to sit here and know about it."]},
	"wen_truth": {"from": "Granny Wen the Midwife", "on": ["wen_first", "truth"], "after": "s_roc", "gift": {"item": "hp_pill", "n": 3},
		"lines": ["Not since yesterday! Then here is today, and tomorrow, and the day after, wrapped in a lotus leaf, and the carrier has been told what happens to him if it arrives squashed. Thank you for telling me the truth. Do it again."]},
	# ---- Part XXVI (the Underclothes release): letters about a physician's book, and from the physician
	"book_copy": {"from": "Granny Lou of Qingshi", "needs": ["the_book", "copy"], "wait": 3,
		"lines": ["Lin Feng, the book came to the counter in a blue bag with a stone on it. I cannot read, so the postmaster reads it to me, a page a night. We are at the bear. My knees are at the bear too. I wanted you to know there is an old woman going to the well again who had stopped."]},
	"book_keep": {"from": "Feng Xuan, Steward of Guiyun", "needs": ["the_book", "keep"], "wait": 3,
		"lines": ["For the books: one book, in a blue bag, kept on a shelf by the Hall of the Broom. Value: I have not entered one. Nineteen have swept for it so far. The street has never been cleaner, and two of them set a bone last week, correctly, by lamplight. I find I have opened a new column."]},
	"book_burn": {"from": "Mistress Wu, the Jailer's Wife", "needs": ["the_book", "burn"], "wait": 3,
		"lines": ["I did a thing people will say was terrible. You let me, and did not say it was not. Thank you for that. He came to our door last week and showed my husband the bear, in the street, in front of everybody. Nobody laughed. I think that was his answer."]},
	"hua_last": {"from": "Hua Tuo", "after": "s_p26_book", "wait": 4,
		"lines": ["Cultivator: you sit still a great deal for somebody so young. Do the bird every morning, and the bear when it rains, and get into hot water whenever anybody offers. Every hinge in you will thank me in eighty years. I shall not be there. Wu Pu will. He says he will be a hundred and seventy-one."]},
	# ---- Part XXVII (the Heavy Road release): letters about a sack, and from a man who carries bricks
	"sack_carry": {"from": "Porter Geng of the Maple Gorge", "needs": ["the_sack", "carry"], "wait": 3,
		"lines": ["Lin Feng, they have set posts along the gorge road at the height of a shoulder, so that a load can be rested without being put down. Nobody told us who. We know who. I rest at every one and say your name, which is quicker than a prayer and has done my back more good."]},
	"sack_share": {"from": "Mistress Ruan of the Carriers' Hall", "needs": ["the_sack", "share"], "wait": 3,
		"lines": ["We have a board in the Silk Woods now with every load on it and every back that took a share. Forty names the first month. The governor came and read it through twice and put his own at the bottom, for bricks. I enclose your share of the first quarter. It is small. It is honestly small."],
		"gift": {"stones": 400}},
	"sack_down": {"from": "Auntie Zhou of the Kitchen", "needs": ["the_sack", "down"], "wait": 3,
		"lines": ["There is an old sack hanging by the bamboo gate that you had no business leaving there, child, and I walk past it every market day and it is always empty and I am always glad. You carried enough. Come and eat. I have made too much, as usual, and there is nobody to carry it away."]},
	"tao_last": {"from": "Tao Kan", "after": "s_p27_sack", "wait": 4,
		"lines": ["Sweeper: the granary is roofed. It was your eight stems and my bricks and somebody's sawdust. I hear you have a ring now that holds everything. Good. Take out one thing every morning and carry it a hundred paces, and put it back at night. I will know if you do not. I shall not know how, but I will."]},
	"wen_last": {"from": "Granny Wen the Midwife", "after": "s_p24_riders", "wait": 0,
		"lines": ["They tell me you lost three times this autumn and came home each time on your own feet. Good. I have caught four hundred children in these hands and every one of them fell down before it walked. I never once thought less of the floor."]},
	"yue_note": {"from": "Yue Ling", "after": "s_p12_home", "wait": 0,
		"lines": ["I know you are standing next to me while you read this. I put it in the post at Cloudfoot when you were looking at a horse. Nobody has ever sent me a letter, so I have sent you one, which I think is nearly the same thing.",
			"There is nothing in it. I only wanted to see my own writing come back from somewhere. You may answer or not. I shall be the one reading over your shoulder."],
		"reply": {"ask": "Yue Ling is reading over your shoulder.", "options": [
			{"id": "write", "label": "Write her one back, and post it", "desc": "Properly: sealed, addressed, handed over the counter, to arrive whenever it arrives."},
			{"id": "say", "label": "Turn round and say it", "desc": "She is standing right there."}]}},
	"yue_write": {"from": "Yue Ling", "on": ["yue_note", "write"], "after": "s_p13_home", "wait": 0,
		"lines": ["It came. Eleven days, by way of Longmen, with a thumbprint of somebody's lunch on the corner. I have read it six times and I am keeping the thumbprint. That is the first thing anybody ever sent to me by name."]},
	"yue_say": {"from": "Yue Ling", "on": ["yue_note", "say"], "after": "s_p13_home", "wait": 0,
		"lines": ["You turned round and said it, and I have been thinking about that ever since. So I am writing it down for you, since you will not: what you said, the day, and that the clerk pretended not to listen. Now it is in the post, and it happened."]},
	"du_mat": {"from": "Old Du", "after": "s_p23_home", "wait": 0,
		"lines": ["The mat misses you. The mat misses everybody; that is how the mat works. I write to say the dice have been washed, which they had not been since the old king, and that your luck is exactly what it was. I checked. That is the trouble with it."]},
	"emperor": {"from": "The Son of Heaven", "after": "s_ts_taotie", "wait": 6, "gift": {"stones": 8},
		"lines": ["We write in Our own hand, the Secretariat being one man and he is at his lunch. We are told you looked into the Nine Cauldrons and were civil about what you saw. Few are.",
			"We enclose the surplus of the treasury for the quarter. Do not thank Us. The Empress counted it twice and it is still eight."]},
	"bai_board": {"from": "Clerk Bai", "after": "s_p23_home", "wait": 6,
		"lines": ["A notice was pinned to my board this morning that I did not pin: \"Wanted, the whereabouts of Lin Feng, to be thanked.\" No name, no fee. It is against the rules of the board in four places. I have left it up."]},
	# ---- what was chosen writes back
	"bandits_mend": {"from": "Foreman Kang, lately of Iron Fang's", "needs": ["bandits", "mend"], "gift": {"stones": 120},
		"lines": ["The road is mended to the third bridge. We put a toll-box at it, as the outer disciples said we might, and this is the first day's taking. The men voted. It was not close.",
			"Two of them have asked to stay on as road-wardens when it is done. I told them a bandit knows where a road is weak. I did not think I would ever write that down as a recommendation."]},
	"bandits_drive": {"from": "A man who carried a knife once", "needs": ["bandits", "drive"],
		"lines": ["We wintered over the pass. Eleven did not see the spring. I am not writing to blame you; you did what a sect does. I am writing because nobody else alive knows there were forty of us, and I wanted it in somebody's satchel. Their names are on the back."]},
	"garden_study": {"from": "Alchemist Mo", "needs": ["garden", "study"], "gift": {"item": "qi_pill", "n": 2},
		"lines": ["Three of the hag's roots have taken in my south bed. One of them bit the apprentice. I have named that one after her and moved it nearer the door. The enclosed came out of the blue-flowered kind. Take one, not two. I took two."]},
	"garden_burn": {"from": "Alchemist Mo", "needs": ["garden", "burn"],
		"lines": ["I walked up to the marsh to look at the ashes. You were right, I expect. There was a blue one I should have liked to see open, once, from a safe distance. I mention it only as a man mentions a meal he did not order."]},
	"egg_hatch": {"from": "Grandmother Sarnai", "needs": ["roc_egg", "hatch"],
		"lines": ["It hatched on the night of the first thunder. It eats a sheep every six days and has taken the smoke-hole of my tent for its own. The children ride on the wind it makes. We have not named it; one does not name weather. Come and be looked at by it."]},
	"egg_sell": {"from": "A collector at Cloudfoot", "needs": ["roc_egg", "sell"],
		"lines": ["The egg is in a case of crystal in my upper room, on a cushion, and is much admired. I write because on stormy nights it is warm, and last night it knocked. Twice. You sold it in good faith, and I would be glad of your advice, at your earliest convenience."]},
	"palace_open": {"from": "Sister Ruo, doorkeeper", "needs": ["palace", "open"],
		"lines": ["Two hundred and twelve slept under the Blood Moon's roof last night. A cooper has set up in the hall of mirrors and there are washing-lines across the throne room. Somebody's goat had twins on the dais. You would not know the place. That is the idea, I take it."]},
	"palace_seal": {"from": "Treasurer Bao of the Sect", "needs": ["palace", "seal"],
		"lines": ["Nine lotus seals upon the Blood Moon Palace, to be renewed each year at the winter solstice, in perpetuity. I enclose the account, not for payment. For awareness. Perpetuity is the longest column I keep."]},
	"boon_rain": {"from": "Headman Luo of Qingshi", "needs": ["dragon_boon", "rain"], "gift": {"stones": 200},
		"lines": ["It rained on the third day of the third month, from the east, for exactly as long as the seedlings wanted, and stopped. Old Peng says he has farmed sixty years and never been rained on politely before. The village sends this from the first threshing."]},
	"boon_sea": {"from": "Harbour-Master Zeng of Longmen", "needs": ["dragon_boon", "sea"], "gift": {"stones": 200},
		"lines": ["Not one hull lost between here and Landfall this season. Not one. The widows' fund has had nothing to pay out and does not know what to do with itself, so the wardens voted you a share. The sea is still the sea. But something is holding the door."]},
	"drawings_keep": {"from": "Smith Tie", "needs": ["drawings", "keep"],
		"lines": ["I built one a quarter the size, to see. It walks. It will not carry anything, but it follows the cat all day about the forge, and at night it sits by the banked fire with its legs folded. I had not drawn that part. I do not know who did."]},
	"drawings_burn": {"from": "Smith Tie", "needs": ["drawings", "burn"],
		"lines": ["You were right to burn them. I say so first because of what comes next: I can still see the third sheet when I shut my eyes, and some nights I draw it. In the morning I burn that too. Mostly. I thought you should know there is a mostly."]},
	"widow_truth": {"from": "The Willow Widow", "needs": ["widow", "truth"],
		"lines": ["I have stopped setting out two bowls. It was a hard thing you told me and I was angry until the leaves fell. Now there is one bowl, and I taste what is in it. I wanted you to know that somebody thanked you for it, late."]},
	"widow_kind": {"from": "The Willow Widow", "needs": ["widow", "kind"],
		"lines": ["I set out two bowls every evening, as I always have, and I am happy. I think you were kind to me. I think I may know how kind. Do not write back and tell me. Come and eat the second bowl some time; it only goes to the sparrows."]},
	"axe_give": {"from": "The woodcutters of Qingshi", "needs": ["axe", "give"],
		"lines": ["The axe you brought down never wants sharpening, and whatever it fells at dusk is standing again by morning. We lost a week to one pine before we understood. It is hung over the door of the drum tower now, and we cut with our own."]},
	"wheel_run": {"from": "Headman Luo of Qingshi", "needs": ["the_wheel", "run"],
		"lines": ["The wheel has not stopped since you said it might run. We grind for four villages. Nobody in Qingshi has slept a whole night through in a month, and nobody has gone short of flour. I set these two things down side by side and leave them there."]},
	"wheel_hours": {"from": "Headman Luo of Qingshi", "needs": ["the_wheel", "hours"],
		"lines": ["The gate comes down on the wheel at dusk, by hand, and whoever shuts it has the first flour of the morning. The children fight for the turn. I had thought the rule would be a burden. It has become the thing the day ends with."]},
	"wheel_down": {"from": "Headman Luo of Qingshi", "needs": ["the_wheel", "down"],
		"lines": ["We took the wheel down as you said, and stacked it behind the granary under mats. The women are back at the querns. The stream is very quiet. Nobody has burned the timbers. I notice that nobody has suggested it."]},
	"three_home": {"from": "A widow of Changping", "needs": ["the_three_thousand", "home"],
		"lines": ["A man in old armour came to my door with half a bamboo tally that fits the half over our lintel. He said he was two thousand years late and very sorry. I gave him tea. He did not drink it, but he held the cup a long time. Thank you for sending him."]},
	"three_guard": {"from": "Samira, Reeve of the Sweet Well", "needs": ["the_three_thousand", "guard"],
		"lines": ["Your three thousand walk beside the caravans and have not drawn once. The raiders look at them and remember appointments elsewhere. They frighten the camels less than I feared and the drovers more. I pay them all the same, as agreed. They leave it on the graves."]},
	"tide_wall": {"from": "Market-Warden Shu of Yanggu", "needs": ["the_tide", "wall"], "after": "s_p25_town", "wait": 0,
		"lines": ["The baskets held at the eighth-month bore. Not all; one in nine went out with it, and we have already filled those again. That is the whole trick of the thing, it turns out: it is not a wall, it is a habit. The market sat on dry ground and argued about fish."]},
	"tide_yield": {"from": "Market-Warden Shu of Yanggu", "needs": ["the_tide", "yield"], "after": "s_p25_town", "wait": 0,
		"lines": ["The low fields went under at the bore, as you said to let them, and came up again grey with silt a hand deep. The old men have never seen rice like what is coming up in it. The houses on legs creak in the night. One gets used to living on a thing's leave."]},
	"tide_arrows": {"from": "King Qian", "needs": ["the_tide", "arrows"], "after": "s_p25_town", "wait": 0,
		"lines": ["Three thousand shafts into the face of it, at the top of the bore, as every year. It came on exactly as far as it meant to. The men cheered themselves hoarse. I have begun to think the arrows were never for the tide. Do not tell the men."]},
	"ape_dredge": {"from": "Harbour-Master Zeng of Longmen", "needs": ["the_ape", "dredge"], "wait": 3,
		"lines": ["Something very large went down the new channel on the night of the full moon and out past the bar. It did not hurry. The pilot swears it looked back once at the hills. The Huai has run a hand lower ever since, and clear enough to count the stones."]},
	"ape_chain": {"from": "A boatwoman of the Huai", "needs": ["the_ape", "chain"], "wait": 3,
		"lines": ["The bell under Turtle Mountain rings again when the water is high, as my grandmother said it did. We sleep sound. My youngest asked what is on the other end of the chain and whether it minds. I told her to ask the one who put it there. So: does it?"]},
	"ape_boats": {"from": "A boatwoman of the Huai", "needs": ["the_ape", "boats"], "wait": 3,
		"lines": ["We have built the houses to float, as you said, and moored the fields. When he turns over in his sleep the whole village goes up a span and comes down again and nobody spills the soup now. The children wave at the deep place. Something waves the water back."]},
	"horse_keep": {"from": "Sai Weng", "needs": ["the_horse", "keep"], "wait": 2,
		"lines": ["The horse stands by the tent and nobody rides it. My neighbours say what a waste. They said what a waste the autumn the riders came through and took every man in the valley with a horse under him, too. Then they said what luck. I said: who is to say? I am writing to you because you will not answer either."]},
	"horse_loose": {"from": "Sai Weng", "needs": ["the_horse", "loose"], "wait": 2,
		"lines": ["We took the rails down. It was gone by morning, and my neighbours were sorry for me. Nine days later it came back over the ridge with eleven wild mares behind it. My neighbours are now pleased for me. I have asked them to stop keeping count on my behalf."]},
	"horse_breed": {"from": "Sai Weng", "needs": ["the_horse", "breed"], "after": "s_p25_town", "wait": 0,
		"lines": ["The first foal stood up inside the hour. My son has a book now with lines in it, sire and dam, back to a horse that wandered off. Buyers come from three valleys. He is happier than I have seen him and busier than is good for him. Who is to say."]},
	# ---- Part XXV (the Three Burrows release): letters from Guiyun
	"tally_burn": {"from": "Sawyer Bo of Guiyun", "needs": ["the_tallies", "burn"], "wait": 3,
		"lines": ["The steward wrote this for me; I told him what to put. My tally went in the fire with the rest. I owed for forty posts of pine. I have cut forty more and stacked them behind the hall and told nobody. You are not to tell the steward. He is writing this, so he knows. He says he has not heard."]},
	"tally_collect": {"from": "Goodwife Suyin of Guiyun", "needs": ["the_tallies", "collect"], "wait": 3,
		"lines": ["We paid, Lin Feng. To the notch, at the harvest, as was written. I do not complain of it. It was owed. I write only to say that my boy asked me why the steward counts at our door and not at his own table, and I had no answer for him. Perhaps you have one."]},
	"tally_shares": {"from": "Old Pedlar Jin of Guiyun", "needs": ["the_tallies", "shares"], "wait": 3,
		"lines": ["Forty years on the road and I have never owned anything I could not carry. Now I own a seventy-third part of a mill. I go and look at my part of it most evenings. It is the part that squeaks. I have told them not to oil it."]},
	"door_all": {"from": "A shade, on the wall of Guiyun", "needs": ["the_door", "all"], "wait": 3,
		"lines": ["We keep the night watch, my brother and I. Nobody else can see in the dark, and nobody else wanted it. The living bring us tea we cannot drink and leave it on the wall to go cold. It is the kindest thing that has been done to us since we died. Do not tell them we cannot drink it."]},
	"door_hearth": {"from": "Granny Wen the Midwife", "needs": ["the_door", "hearth"], "wait": 3,
		"lines": ["Child, I have answered for eleven families at your gate this month, and walked up your mountain for four of them, at my age. You asked the hearths to speak. Very well: we are speaking. Next time build your town at the bottom of a hill."]},
	"door_sweep": {"from": "A cock-crower of Guiyun", "needs": ["the_door", "sweep"], "wait": 3,
		"lines": ["I swept my season. Gate to well, well to gate. Nobody asked what I had been, and I had my answer all ready, and it has gone to waste. They have given me the keys of the gate. I open it at cock-crow. I thought you would like to know that I am the cock."]},
	"seat_found": {"from": "First Disciple Ren of the Returning Cloud", "needs": ["the_seat", "found"], "wait": 3,
		"lines": ["Founder: forty-one of us from the Cold Pine have stayed. The others went home to Frostpeak to look for somebody to kneel to. We have swept the street every dawn. The children correct our grip. A sect with no history is a strange thing to be in. Nobody can tell us we are doing it wrong."]},
	"seat_take": {"from": "Han Song", "needs": ["the_seat", "take"], "wait": 3,
		"lines": ["So you sat in it. I did not think you would. I am living in the gatehouse; nobody has told me to go. They kneel to you as they knelt to me, to the same depth. I used to think that depth was respect. Come up some time, Patriarch, and stand where I stood, and tell me what you think it is."]},
	"seat_serve": {"from": "Auntie Zhou", "needs": ["the_seat", "serve"], "wait": 3,
		"lines": ["Eleven of yours came up the steps this spring with their bedding. I asked each of them had they eaten, and every one said yes, Auntie, the steward saw to it. So I fed them again. The Elder goes and reads the roster where their names are. He does not think I see him."]},
}
const ORDER := ["ge_satchel", "wen_first", "wen_eaten", "wen_truth", "bandits_mend", "bandits_drive", "garden_study", "garden_burn", "egg_hatch", "egg_sell",
	"palace_open", "palace_seal", "boon_rain", "boon_sea", "drawings_keep", "drawings_burn", "widow_truth", "widow_kind", "axe_give", "emperor", "yue_note", "yue_write", "yue_say",
	"wheel_run", "wheel_hours", "wheel_down", "three_home", "three_guard", "du_mat", "bai_board", "tide_wall", "tide_yield", "tide_arrows", "ape_dredge", "ape_chain", "ape_boats",
	"horse_keep", "horse_loose", "horse_breed",
	"tally_burn", "tally_collect", "tally_shares", "door_all", "door_hearth", "door_sweep", "seat_found", "seat_take", "seat_serve",
	"book_copy", "book_keep", "book_burn", "hua_last", "sack_carry", "sack_share", "sack_down", "tao_last", "wen_last"]

## The step a letter is written after: its own, or the step of the crossroads it answers.
static func after_of(id: String) -> String:
	var l: Dictionary = LETTERS[id]
	if l.has("after"):
		return str(l.after)
	return str(Echoes.CROSSROADS[str(l.needs[0])].step)

## Whether letter `id` has been written to the journey of `g` and has had time to come.
static func arrived(g, id: String) -> bool:
	var l: Dictionary = LETTERS[id]
	var at := Data.step_index(after_of(id))
	if at < 0 or int(g.step) <= at + int(l.get("wait", WAIT)):
		return false
	if l.has("needs") and Echoes.chosen(g, str(l.needs[0])) != str(l.needs[1]):
		return false
	if l.has("on") and str(g.mail_replies.get(str(l.on[0]), "")) != str(l.on[1]):
		return false
	return true

## The letters waiting at the counter, oldest first; and the ones in the satchel.
static func waiting(g) -> Array:
	var out: Array = []
	for id in ORDER:
		if not g.mail_read.has(id) and arrived(g, id):
			out.append(id)
	return out

static func kept(g) -> Array:
	var out: Array = []
	for id in ORDER:
		if g.mail_read.has(id):
			out.append(id)
	return out

## Letter `id` as it is read out: [[who, words], ...].
static func lines_of(id: String) -> Array:
	var out: Array = []
	for ln in LETTERS[id].lines:
		out.append([str(LETTERS[id].from), str(ln)])
	return out

## Letter `id` is opened: what was in it is taken (the first time).  Returns what to say of that ("" if nothing).
static func open(g, id: String) -> String:
	if g.mail_read.has(id):
		return ""
	g.mail_read[id] = true
	g.note("A letter from %s" % str(LETTERS[id].from))
	var gift: Dictionary = LETTERS[id].get("gift", {})
	if gift.has("stones"):
		g.stones += int(gift.stones)
		return "Enclosed: %d spirit stones" % int(gift.stones)
	if gift.has("item"):
		g.inv[str(gift.item)] = int(g.inv.get(str(gift.item), 0)) + int(gift.get("n", 1))
		return "Enclosed: %s x%d" % [str(Data.ITEMS[str(gift.item)].n), int(gift.get("n", 1))]
	return ""

## Whether letter `id` is still to be answered; and the answering of it.
static func owes_reply(g, id: String) -> bool:
	return LETTERS[id].has("reply") and g.mail_read.has(id) and not g.mail_replies.has(id)

static func reply(g, id: String, oid: String) -> void:
	if not owes_reply(g, id):
		return
	for op in LETTERS[id].reply.options:
		if str(op.id) == oid:
			g.mail_replies[id] = oid
			g.note("Wrote back to %s" % str(LETTERS[id].from))

# ---------------------------------------------------------------- the post-bag
static func is_post(office: String) -> bool:
	return POSTS.has(office)

static func area_of(office: String) -> String:
	return str(Offices.OFFICES[office].area)

## What the bag from counter `from` to counter `to` pays a carrier of level `lv`.
static func bag_pay(lv: int, from: String, to: String) -> int:
	return int(round((BAG_BASE + BAG_LV * float(lv)) * float(Offices.hops(area_of(from), area_of(to)))))

## The bag counter `office` has to be carried today: {from, to, pay, day}, or {} (none: carried one
## from here already today, hands full, or no other counter in this realm).
static func bag_offer(g, office: String) -> Dictionary:
	if not is_post(office) or g.mail_bags.size() >= BAGS or int(g.bag_day.get(office, -1)) == int(g.day):
		return {}
	var others: Array = []
	for o in POSTS:
		if o != office and Data.layer_of(area_of(o)) == Data.layer_of(area_of(office)) and not g.mail_bags.any(func(b): return str(b.from) == office and str(b.to) == o):
			others.append(o)
	if others.is_empty():
		return {}
	var to := str(others[absi(hash("%s:%d" % [office, int(g.day)])) % others.size()])
	return {"from": office, "to": to, "pay": bag_pay(int(g.level), office, to), "day": int(g.day)}

static func take_bag(g, bag: Dictionary) -> void:
	if bag.is_empty() or g.mail_bags.size() >= BAGS:
		return
	g.mail_bags.append(bag)
	g.bag_day[str(bag.from)] = int(g.day)
	g.note("Took the post-bag of %s for %s" % [str(Offices.OFFICES[str(bag.from)].n), str(Offices.OFFICES[str(bag.to)].n)])

## The bags carried for counter `office`; and the handing of them over.  Returns what was paid.
static func bags_for(g, office: String) -> Array:
	return g.mail_bags.filter(func(b): return str(b.to) == office)

static func deliver(g, office: String) -> int:
	var paid := 0
	var keep: Array = []
	for b in g.mail_bags:
		if str(b.to) == office:
			paid += int(b.pay)
			g.bags_done += 1
		else:
			keep.append(b)
	g.mail_bags = keep
	if paid > 0:
		g.stones += paid
		g.wages += paid
		g.note("Handed the post to %s (%d spirit stones)" % [str(Offices.OFFICES[office].n), paid])
	return paid
