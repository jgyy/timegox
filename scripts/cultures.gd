class_name Cultures
extends RefCounted
## The Six Hearths of the Unbroken Land (the New Fire release): the peoples of the land itself, each
## with a hearth of its own, a way of greeting, a table, a festival, a thing nobody does and a way of
## keeping fire.
##
## Part XI gave the realms above and below their peoples (Data.RACES: the Yumin, the Jiaoren, the
## shades...).  The towns of the land were all one people until now, in the same robes with the same
## names, saying the same things.  They are six:
##
##   the Rice Hearth of the valley (Qingshi, Cloudfoot and the sect's own kitchens),
##   the Felt Hearth of the horse-folk (the tents below Thunder Valley),
##   the Sweet-Well Hearth of the sand roads (Shazhou Oasis),
##   the Boat Hearth of the river (Longmen Ferry),
##   the Casting Hearth of the bronze-founders (Tushan),
##   and the Lantern Hearth of the Dawn Market (Yanggu).
##
## A hearth is carried through the whole game:
##
## * **Who the hero is** (create.gd): besides the look and the trade in Qingshi, the player chooses the
##   hearth where the hero spent the year away that every child of Qingshi is sent on at twelve.  It
##   gives a keepsake, a small gift of its own, kinship with that people from the first day, and the
##   **beginning** of the game: the story opens three years before the Elder's summons, on the last
##   morning at that hearth (`start`), in its own town, with its own keeper to say goodbye to.
## * **Standing** (Game.hearth): a first word with each of a hearth's townsfolk, sitting down with its
##   keeper, and what is done for it in the story make the hero a *guest* and then *kin* of that
##   hearth; each has a gift for its guests (`guest_fx`, the keys of Fashion.gear).
## * **The towns** (folk.gd): each hearth's people have their own names, their own dress
##   (art/characters/folk_*.py), their own hails in the street and their own things to say.
## * **Trials** (trials.gd, "By the hearths"): the lords of Part XVIII can be passed by the hearths that
##   call the hero a guest.
## * **The ending** (ENDINGS): when the last tribulation is passed the player chooses where the hero's
##   own fire is to be kept, among the ends the journey has earned.
##
## Nothing here is drawn from one living people.  Each hearth is put together from the old customs of
## the lands the story's myths come from (the changing of the fire with the seasons, the cold food,
## the fire on the boat that is never let out, the hearth-ring of the felt tent, the casting pit that
## has never gone cold, lamps for the dead), and the README says which.

## standing at which a hearth calls the hero a guest, and kin
const GUEST := 6
const KIN := 12
## what standing is earned by: a first word with one of its townsfolk, sitting with its keeper or one
## of its named people for the first time, and a step of the story done for it (Data.STEPS "hearth")
const TALK := 1
const SIT := 2
const DEED := 4

const ORDER := ["valley", "steppe", "sand", "river", "forge", "dawn"]

const HEARTHS := {
	"valley": {"n": "the Rice Hearth", "people": "the Valley Folk", "short": "of the Rice Hearth", "col": Color("7ab85a"),
		"home": "Qingshi Village", "towns": ["qingshi", "cloudfoot", "sect"], "areas": ["village", "mountain", "sect", "bamboo", "terraces", "silk", "mirror"],
		"keeper": "granny_wen", "keeper_area": "village", "kin": ["granny_wen", "noodle_he", "tofu_sun", "farmer_lao", "tea_master"],
		"hail": ["Eaten yet?", "Have you eaten?", "Come in, come in!"], "greet": "Have you eaten?", "gesture": "nod",
		"dish": "rice gruel with pickled mustard and a salted duck egg", "drink": "green tea from the terraces",
		"festival": "Qingming, when the graves are swept and the kites cut loose",
		"fire": "a brick stove with the Stove God's picture over it, banked every night and never asked to go out",
		"taboo": "Never stand your chopsticks upright in the rice: that is how it is offered to the dead.",
		"custom": "A guest is asked whether they have eaten before they are asked their name, and the right answer is always no.",
		"desc": "Stayed. Some children never take the year away: Granny Wen needed somebody to carry her bag, and the valley is a people too, with its rice, its tea, its stoves and its graves. The road as the story first told it.",
		"fx": {}, "give": {"hp_pill": 1}, "fx_text": "Kin of the Rice Hearth from the first day. One more Healing Pill, wrapped in a lotus leaf.",
		"guest_fx": {"heal": 0.03}, "guest_text": "healing +3%",
		"keepsake": "a lotus leaf of sticky rice, still warm",
		"start": Vector2i(14, 24),
		"prologue": [
			["Narrator", "Three years before the Elder's summons. Qingshi Village, below Azure Cloud Mountain, on the morning after the spring rain."],
			["Narrator", "At twelve every child of Qingshi is sent away for a year, to eat at somebody else's hearth and find out whose bread they like. Lin Feng never went. Granny Wen needed somebody to carry her bag."],
			["Narrator", "Now Lin Feng is thirteen, and the bag is packed for a different road: up the mountain, to ask the sect for a broom. Say goodbye to Granny Wen first. (Arrow keys to walk, Enter to speak.)"],
		],
		"farewell": [
			["Granny Wen the Midwife", "Have you eaten? No. You never have. Sit. Gruel, a duck egg, and the mustard you pretend not to like."],
			["Granny Wen the Midwife", "Every other child in this village went off at twelve to somebody else's table and came home full of other people's words. You stayed and carried my bag to forty births. Do you know what that makes you?"],
			["Lin Feng", "Tired, Granny."],
			["Granny Wen the Midwife", "It makes you the only one in the valley who has seen everybody arrive. Remember that up there, when the cultivators tell you where they come from. Everybody arrives the same way. Yelling."],
			["Granny Wen the Midwife", "Here. Sticky rice in a lotus leaf. Do not stand your chopsticks in it. Go on, before I think of a reason to keep you."],
		],
		"lines": ["Have you eaten? You look as if you haven't. Nobody who climbs that mountain ever has.", "The Stove God sees everything that goes on in a kitchen. That is why ours is always tidy on the twenty-third.",
			"Tea first, talk after. That's the rule in the valley, %s. In the sand they do it the other way round and it takes all day.",
			"My grandmother's grave is up by the terraces. We sweep it at Qingming and tell her the news. She never liked the news."],
		"ending": [["Narrator", "In Qingshi Village the stove in Granny Wen's kitchen has not gone out in sixty years, and it has a second picture over it now, next to the Stove God's: somebody with a broom."]],
	},
	"steppe": {"n": "the Felt Hearth", "people": "the Horse-Folk", "short": "of the Felt Hearth", "col": Color("d8a04a"),
		"home": "the tents below Thunder Valley", "towns": [], "areas": ["thunder", "millet", "frost"],
		"keeper": "sarnai", "keeper_area": "thunder", "kin": ["sarnai", "batu", "tala", "tala_plains", "tala_end", "stableboy_shitou"],
		"hail": ["Is your herd fat?", "Good grass to you!", "Hold the dog!"], "greet": "Are your horses fat?", "gesture": "wave",
		"dish": "boiled mutton eaten off the knife, and dried curds as hard as river stones", "drink": "salted milk tea, and mare's milk in summer",
		"festival": "the summer gathering, with the long horse race the children ride",
		"fire": "a ring of three stones in the middle of the tent, fed with dried dung; the youngest son inherits it, and is called the keeper of the fire",
		"taboo": "Never step on the threshold of a tent, and never point your feet or a knife at the fire.",
		"custom": "A guest is handed a bowl with both hands and takes it with the right, the left under the elbow; the first drops are flicked to the sky, the earth and the fire.",
		"desc": "Tala's grandmother took the child in for a year among the horse-folk who winter below Thunder Valley: a felt tent, forty horses, a dog with opinions, and a sky that goes all the way down to the ground on every side.",
		"fx": {"spd": 1, "qi": -0.03}, "give": {"hp_pill": 1}, "fx_text": "A year in the saddle: speed +1, but a dantian that never sat still, qi -3%. Kin of the Felt Hearth from the first day.",
		"guest_fx": {"spd": 1}, "guest_text": "speed +1",
		"keepsake": "a blue silk scarf, tied to the hilt",
		"start": Vector2i(0, 0),
		"prologue": [
			["Narrator", "Three years before the Elder's summons. The tents of the horse-folk, in the grass below Thunder Valley, on the morning the herds move to the summer pasture."],
			["Narrator", "At twelve every child of Qingshi is sent away for a year, to eat at somebody else's hearth and find out whose bread they like. Lin Feng's year was spent here, in Grandmother Sarnai's tent, among forty horses."],
			["Narrator", "The year is over. The road home goes south; the mountain with the sect on it stands behind the village. Say goodbye to Grandmother Sarnai first. (Arrow keys to walk, Enter to speak.)"],
		],
		"farewell": [
			["Grandmother Sarnai", "Are your horses fat? Ha. You have no horses. You have a dun mare who bites, and she is mine, and she will miss you, which is more than she does for me."],
			["Grandmother Sarnai", "Sit. Not there, that is the men's side. A year and you still sit down like a farmer. Tea. Both hands. Flick it: sky, earth, fire. Good."],
			["Lin Feng", "Grandmother, why does the youngest keep the fire?"],
			["Grandmother Sarnai", "Because the eldest ride away. Somebody has to be at home when they come back wrong. You are going up a mountain to learn to fly, child. Remember who keeps the fire for the people who fly."],
			["Grandmother Sarnai", "Here. A blue scarf, the colour of the sky nobody owns. Tie it where your hand goes. And do not step on my threshold on the way out, or I will know."],
		],
		"lines": ["Are your horses fat, %s? No horse? Then I am sorry for you, and so is my dog.", "The fire in the tent belongs to the youngest. The eldest get the horses and the weather.",
			"We do not ask a guest's name for three days. By then we know it, or it does not matter.",
			"The valley people shut their fire in a brick box. No wonder it sulks. Ours sits in the middle and looks at everybody."],
		"ending": [["Narrator", "Below Thunder Valley the horse-folk tie a blue scarf to the smoke-hole of every new tent, for the one who learned to sit on the right side of the fire and then went and held up the sky."]],
	},
	"sand": {"n": "the Sweet-Well Hearth", "people": "the Sand-Road Folk", "short": "of the Sweet-Well Hearth", "col": Color("e0b060"),
		"home": "Shazhou Oasis", "towns": ["shazhou"], "areas": ["dunes"],
		"keeper": "cook_aysha", "keeper_area": "dunes", "kin": ["cook_aysha", "navid", "farida", "nomad", "well_keeper_zhaya", "star_reader_kumar", "camel_boy_temur", "caravan_kang"],
		"hail": ["Peace on your road!", "Shade to you!", "Water before words!"], "greet": "Peace on your road, and shade at the end of it.", "gesture": "offer",
		"dish": "flatbread from the wall of the clay oven, with mutton, apricots and too much cumin", "drink": "water first, always; then black tea with a lump of rock sugar held in the teeth",
		"festival": "the Night of the Falling Stars, when every lamp in the oasis is put out to count them",
		"fire": "a clay oven shaped like a jar, built into the caravanserai wall; it is lit once, when the house is built, and fed by every caravan that passes",
		"taboo": "Never waste water in front of somebody, and never ask a traveller where they are going before they have drunk.",
		"custom": "Bread is torn, never cut, and never laid upside down; a guest who brings news is fed before one who brings silver.",
		"desc": "Caravan-Master Kang took the child west for a year with the camels, to Shazhou, where Auntie Aysha's caravanserai feeds every road in the world out of one clay oven and water is paid for in stories.",
		"fx": {"stones": 0.08, "hp": -0.03}, "give": {"stones": 80}, "fx_text": "A year of bargaining in three tongues: spirit stones +8%, and 80 to start with, but thinner for the sun, health -3%. Kin of the Sweet-Well Hearth from the first day.",
		"guest_fx": {"stones": 0.04}, "guest_text": "spirit stones +4%",
		"keepsake": "a bead of star-glass on a cord",
		"start": Vector2i(0, 0),
		"prologue": [
			["Narrator", "Three years before the Elder's summons. Shazhou Oasis, in the Desert of Fallen Stars, in the cool of the morning before the caravan loads."],
			["Narrator", "At twelve every child of Qingshi is sent away for a year, to eat at somebody else's hearth and find out whose bread they like. Lin Feng's year was spent here, turning bread on the wall of Auntie Aysha's oven."],
			["Narrator", "The year is over, and Kang's camels leave for the east at noon. Say goodbye to Auntie Aysha first. (Arrow keys to walk, Enter to speak.)"],
		],
		"farewell": [
			["Auntie Aysha of the Caravanserai", "Peace on your road. Drink. No, drink first, then talk. A year under my roof and you still open your mouth before you have wet it."],
			["Auntie Aysha of the Caravanserai", "You burned forty loaves in the first month and none in the last. That is all anybody can ask of a year. Tear this one; do not cut it. Who cuts bread cuts the hand that made it."],
			["Lin Feng", "Auntie, has the oven truly never gone out?"],
			["Auntie Aysha of the Caravanserai", "Not since my grandmother's grandmother lit it. Every caravan puts one stick in. There is wood in that fire from places that are not on any map now. So when you are far away and cold, remember there is a fire with your stick in it."],
			["Auntie Aysha of the Caravanserai", "Here. Farida blew it for you from a fallen star. Do not sell it. Kang will tell you to sell it. Kang would sell his own beard."],
		],
		"lines": ["Peace on your road, %s. Have you drunk? Then you may tell me the news.", "The oven has wood in it from forty countries. That is why the bread tastes of everywhere.",
			"In the valley they ask whether you have eaten. Here we ask whether you have drunk. Eat without water and see how far you get.",
			"On the Night of the Falling Stars we put out every lamp. The children count. The old ones remember what each star was called before it fell."],
		"ending": [["Narrator", "In Shazhou the caravans still put one stick each into Auntie Aysha's oven, and the masters tell the new boys which stick came from the mountain where the sky is held up, though by now nobody could possibly know."]],
	},
	"river": {"n": "the Boat Hearth", "people": "the River Folk", "short": "of the Boat Hearth", "col": Color("5aa0c8"),
		"home": "Longmen Ferry", "towns": ["longmen"], "areas": ["longmen", "karst", "marsh", "dragon"],
		"keeper": "fishwife_lu", "keeper_area": "longmen", "kin": ["fishwife_lu", "boatwright_gao", "harbour_yao", "lockkeeper_qian", "xia_cormorant", "carp_boy_yu", "fisher"],
		"hail": ["Fair wind!", "Smooth water!", "Mind the boom!"], "greet": "Smooth water and a fair wind.", "gesture": "wave",
		"dish": "river fish steamed whole with ginger, and never, ever turned over", "drink": "yellow rice wine warmed in the stern",
		"festival": "the fifth day of the fifth month, when the dragon boats race and the rice dumplings go into the water",
		"fire": "a clay pot of charcoal in the stern of every boat, carried aboard from the mother's boat on the wedding day and never let out while the boat floats",
		"taboo": "Never turn the fish over on the plate, and never say the word for it either: a boat turns over the same way.",
		"custom": "Children are born on the boat and wear a gourd on their backs until they can swim; a guest steps aboard right foot first and sits where the boat sits lowest.",
		"desc": "A year on the water with Fishwife Lu's family at Longmen, below the Dragon Gate: sleeping in the bilge, a gourd tied on for the first month, and a charcoal pot in the stern that has to be kept alight through any weather.",
		"fx": {"hp": 0.05, "atk": -0.02}, "give": {"hp_pill": 2}, "fx_text": "A year at the oar: health +5%, though a sword is not an oar, attack -2%. Two Healing Pills. Kin of the Boat Hearth from the first day.",
		"guest_fx": {"taken": -0.02}, "guest_text": "harm taken -2%",
		"keepsake": "a child's swimming-gourd, long outgrown",
		"start": Vector2i(0, 0),
		"prologue": [
			["Narrator", "Three years before the Elder's summons. Longmen Ferry, below the Dragon Gate, in the mist before the boats go out."],
			["Narrator", "At twelve every child of Qingshi is sent away for a year, to eat at somebody else's hearth and find out whose bread they like. Lin Feng's year was spent here, on Fishwife Lu's boat, keeping the charcoal alight in the stern."],
			["Narrator", "The year is over, and the up-river barge leaves with the tide. Say goodbye to Fishwife Lu first. (Arrow keys to walk, Enter to speak.)"],
		],
		"farewell": [
			["Fishwife Lu", "Smooth water. Right foot first, that's it. A year ago you came aboard left foot first and I nearly threw you back."],
			["Fishwife Lu", "Eat. The top side only. When that's gone we lift the bone out, we don't... do the other thing. You know the word. Don't say the word."],
			["Lin Feng", "I kept the pot alight in the storm, Auntie. All night."],
			["Fishwife Lu", "You did. With your own jacket over it and the rain coming sideways. My mother's fire, and her mother's. That's forty years a boat's been warm because of people who sat up. Now it's forty years and a night, and the night's yours."],
			["Fishwife Lu", "Here. Your gourd. You don't need it, you swim like an eel now. Keep it anyway. Everybody ought to have one thing that would hold them up."],
		],
		"lines": ["Smooth water, %s. Right foot first if you're coming aboard.", "A boat with no fire in the stern is driftwood with opinions.",
			"We eat the top of the fish and lift out the bone. I'm not saying why. You know why.",
			"On the fifth of the fifth every boat on the river races, and the losers say the dragon wanted somebody else to win."],
		"ending": [["Narrator", "At Longmen the river folk carry fire to a new boat from the mother's boat, as they always have, and Fishwife Lu's boat has mothered half the fleet. She says the storm night is in every one of them."]],
	},
	"forge": {"n": "the Casting Hearth", "people": "the Bronze-Founders", "short": "of the Casting Hearth", "col": Color("d07848"),
		"home": "Tushan", "towns": ["tushan"], "areas": ["tushan", "volcano", "forge"],
		"keeper": "auntie_rong", "keeper_area": "tushan", "kin": ["auntie_rong", "bell_tuner_gong", "tu_lan", "caster_wei", "carver_shi", "charcoal_tan", "smith"],
		"hail": ["Hot metal!", "Strong bellows!", "Mind the pour!"], "greet": "May your metal run clean.", "gesture": "nod",
		"dish": "millet cakes baked on the lid of the furnace, with pickled radish and a great deal of salt", "drink": "barley tea by the bucket, for the sweat",
		"festival": "the Day of the First Pour, when the year's first bell is cast and every child strikes it once",
		"fire": "the casting pit, lit by Yu's own founders and never once let go cold; a founder who dies is carried round it three times",
		"taboo": "Never whistle at the furnace, and never speak of rain on a pouring day.",
		"custom": "Nobody is called a founder until they have fed the pit through a whole night; a guest is given the bellows before they are given a seat.",
		"desc": "A year at the smelting pits of Tushan with Auntie Rong, among the clan that cast Yu's Nine Cauldrons: carrying charcoal, pumping bellows, and learning that a fire four thousand years old does not care how tired you are.",
		"fx": {"atk": 0.04, "spd": -1}, "give": {"qi_pill": 1}, "fx_text": "A year at the bellows: attack +4%, but a founder's heavy tread, speed -1. One Spirit Qi Pill. Kin of the Casting Hearth from the first day.",
		"guest_fx": {"atk": 0.02}, "guest_text": "attack +2%",
		"keepsake": "a bronze bell no bigger than a thumb, cast wrong and kept",
		"start": Vector2i(0, 0),
		"prologue": [
			["Narrator", "Three years before the Elder's summons. Tushan, the town of the cauldron-casters on Mount Kuaiji, on the morning after a pour."],
			["Narrator", "At twelve every child of Qingshi is sent away for a year, to eat at somebody else's hearth and find out whose bread they like. Lin Feng's year was spent here, feeding charcoal to a fire that was lit before there were emperors."],
			["Narrator", "The year is over, and the bell-cart goes down the mountain today. Say goodbye to Auntie Rong first. (Arrow keys to walk, Enter to speak.)"],
		],
		"farewell": [
			["Auntie Rong of the Smelting Pits", "May your metal run clean. Don't sit. Take the bellows. Ten strokes. There. Now you can sit; that's manners here."],
			["Auntie Rong of the Smelting Pits", "Millet cake. It's burnt on one side because you put it on the hot side of the lid. A year, and you still can't tell the hot side of a lid."],
			["Lin Feng", "The bell I cast came out wrong, Auntie. It only has one note and it's the wrong one."],
			["Auntie Rong of the Smelting Pits", "Everybody's first bell comes out wrong. We don't melt them. You fed the pit through the long night in the eleventh month when three grown men fell asleep. A bell's a bell. A night's a night. You're a founder."],
			["Auntie Rong of the Smelting Pits", "Take it with you. When somebody up that mountain tells you a thing has to be perfect to be worth keeping, ring it at them."],
		],
		"lines": ["Clean metal to you, %s. Here, take the bellows a moment. No, that's the welcome.", "The pit has never been cold. Not in the flood, not in the nine days of noon. Somebody always sat up.",
			"We don't whistle at the furnace. It whistles back, and then you've a cracked mould and a week's work on the floor.",
			"On the Day of the First Pour every child in Tushan hits the new bell once. If it cracks, well, better a child than a temple."],
		"ending": [["Narrator", "In Tushan there is a bell no bigger than a thumb hanging over the mouth of the casting pit, with one note, the wrong one. The founders ring it before every pour. They say it has never spoiled one."]],
	},
	"dawn": {"n": "the Lantern Hearth", "people": "the Dawn-Market Folk", "short": "of the Lantern Hearth", "col": Color("f08a5a"),
		"home": "Yanggu, the Dawn Market", "towns": ["yanggu"], "areas": ["yanggu", "fusang", "maple"],
		"keeper": "lantern_xi", "keeper_area": "yanggu", "kin": ["lantern_xi", "ah_mei", "watchman_zhou", "tea_seller_pan", "dyer_su", "granny_gu", "innkeeper_bao"],
		"hail": ["First light to you!", "Bright morning!", "Trim your wick!"], "greet": "First light to you.", "gesture": "bow",
		"dish": "sesame cakes hot from the drum oven before sunrise, and sweet rice balls on lantern nights", "drink": "tea so early it is still dark in the cup",
		"festival": "the Lantern Festival, when the Lantern Dragon goes down the main street and every riddle has a prize",
		"fire": "the shrine lamp of the Sun, from which the lamplighters take a taper every dusk; no house in Yanggu strikes its own light",
		"taboo": "Never blow a lamp out with your breath; pinch it, or lower the wick, and say thank you.",
		"custom": "The market opens before the sun so that the first sale of the day is made by lamplight; the first customer is never haggled with.",
		"desc": "A year in Lantern-Maker Xi's workshop at Yanggu, the last town before the Valley of Sunrise: splitting bamboo, pasting paper, and getting up two hours before the sun because the Dawn Market does.",
		"fx": {"qi": 0.05, "hp": -0.03}, "give": {"qi_pill": 1}, "fx_text": "A year of small flames tended: qi +5%, and too many nights awake, health -3%. One Spirit Qi Pill. Kin of the Lantern Hearth from the first day.",
		"guest_fx": {"exp": 0.03}, "guest_text": "cultivation from battle +3%",
		"keepsake": "a paper lantern folded flat, with a riddle inside it",
		"start": Vector2i(0, 0),
		"prologue": [
			["Narrator", "Three years before the Elder's summons. Yanggu, the Dawn Market, two hours before sunrise, with every stall already lit."],
			["Narrator", "At twelve every child of Qingshi is sent away for a year, to eat at somebody else's hearth and find out whose bread they like. Lin Feng's year was spent here, pasting paper on to bamboo in Lantern-Maker Xi's workshop."],
			["Narrator", "The year is over, and the pilgrims' cart goes west at first light. Say goodbye to Lantern-Maker Xi first. (Arrow keys to walk, Enter to speak.)"],
		],
		"farewell": [
			["Lantern-Maker Xi", "First light to you. It is not light yet. That is the point of saying it."],
			["Lantern-Maker Xi", "Sesame cake. Eat it hot. You have made four hundred lanterns in my shop and the first three hundred were crooked, and I sold every one, because a crooked lantern lights a street as well as a straight one."],
			["Lin Feng", "Master Xi, why does nobody here strike their own light?"],
			["Lantern-Maker Xi", "Because a flame you struck yourself is yours, and you can let it go out. A flame you were handed, you owe to the one who handed it. The whole town is one fire that has been passed along. You have been holding a piece of it for a year."],
			["Lantern-Maker Xi", "Here. Folded flat. There is a riddle in it; do not read it until you need a light. And pinch your lamps, child. Never blow."],
		],
		"lines": ["First light to you, %s. We say it in the dark. That's when you need it.", "Nobody in Yanggu strikes a light of their own. Every lamp in town was handed on from the shrine.",
			"Pinch a flame out and thank it. Blow it out and my mother will come back from the dead to slap you.",
			"On lantern night the riddles hang from every eave. The Lantern Dragon reads them all and guesses none. Dragons are bad at riddles."],
		"ending": [["Narrator", "In Yanggu a crooked lantern hangs first in the row over Lantern-Maker Xi's door, and on festival nights the Lantern Dragon stops under it for a moment before it goes on down the street."]],
	},
}

## Where the hero's own fire is kept when the sky is held: the ends of the story (the New Fire
## release).  `needs` what the journey must have earned for it ("home": always; "guests" hearths that
## call the hero a guest; "peoples" peoples of the realms that call the hero friend; "heart" closeness
## with Yue Ling); `title` what the results screen calls the ending; `sky` the tint of its last shot;
## `lines` how the story closes ("%home%" is the town of the hero's own hearth).
const ENDINGS := {
	"azure": {"n": "The Azure Cloud", "label": "Stay on the mountain", "sub": "The sweeper keeps the sect's fire",
		"desc": "The sect raised a sweeper into the one who holds up the sky. Stay on Azure Cloud Mountain, take the Elder's seat when he lays it down, and keep the kitchen fire Auntie Zhou has never once let out.",
		"needs": [], "sky": Color(1.0, 1.0, 1.0),
		"lines": [["Narrator", "Lin Feng stays. In time the old Elder lays down his seat, and the sect has a master who still sweeps the steps every morning before anybody is up, because nobody has ever been able to stop it."],
			["Narrator", "Auntie Zhou's kitchen fire never goes out. Disciples come from every hearth in the land now, and each is asked the same first question at the gate: have you eaten?"]]},
	"home": {"n": "The Fire at Home", "label": "Go home", "sub": "Back to the hearth that fed you",
		"desc": "Somebody kept a fire for the one who flew. Go down the mountain and home to the hearth of your own people, and be the one who sits up with it now.",
		"needs": [["home"]], "sky": Color(1.0, 0.86, 0.7),
		"lines": [["Narrator", "Lin Feng goes down the mountain with a broom over one shoulder and Yue Ling beside, and comes home to %home%, to the fire that was kept."],
			["Narrator", "The one who holds up the sky sits up with it now, on the long nights, so that the old ones can sleep. The sky, it turns out, can be held from anywhere. A hearth has to be sat beside."]]},
	"road": {"n": "The Road of Six Fires", "label": "Take the road", "sub": "A guest at every hearth, a keeper of none",
		"desc": "Five hearths or more call you a guest. Belong to all of them: walk the roads between with a coal in a pot, and carry fire from each to the next, the way the caravans carry news.",
		"needs": [["guests", 5]], "sky": Color(0.86, 0.92, 1.0),
		"lines": [["Narrator", "Lin Feng takes the road. A pot of coals rides at the saddle, and at every hearth in the land one coal is left and one is taken, so that in a few years there is no fire anywhere that has not a little of every other in it."],
			["Narrator", "The horse-folk say the sweeper is theirs, and so do the founders, the river and the sand. They are all right. Yue Ling keeps count of the arguments and says it is the best thing anybody ever started."]]},
	"open": {"n": "The Open Door", "label": "Open the gate", "sub": "One hearth for every people",
		"desc": "Four hearths call you a guest and four peoples of the realms call you friend. Take the gate off the sect, and build one great hearth in the courtyard where anybody at all may sit: the horse-folk and the shades, the founders and the Feathered Folk.",
		"needs": [["guests", 4], ["peoples", 4]], "sky": Color(1.0, 0.94, 0.8),
		"lines": [["Narrator", "Lin Feng takes the gate of the Azure Cloud Sect off its hinges, and Smith Tie beats the hinges into a fire-ring for the great courtyard, and the fire lit in it has a coal from every hearth in the three realms."],
			["Narrator", "A Yumin and a horse-herder argue over it about the right way to make tea. A shade of Youdu and a founder of Tushan sit up with it at night. Nobody is asked where they come from until they have eaten. That is the whole of the rule."]]},
	"lotus": {"n": "The Lotus Hearth", "label": "Build a house with her", "sub": "A small fire, for two",
		"desc": "You and Yue Ling have come as close as two people come. Leave the sky to hold itself for an afternoon at a time, and build one small house with one small fire in it, by the pond where she wakes.",
		"needs": [["heart", 3]], "sky": Color(1.0, 0.82, 0.9),
		"lines": [["Narrator", "By the lotus pond below the mountain there is a house with one room and one stove, built by somebody who can hold up the sky and still got the chimney wrong twice."],
			["Narrator", "Yue Ling lights the fire in the mornings. Lin Feng banks it at night. It is the smallest hearth in the Unbroken Land, and on a clear evening its smoke goes straight up, and every other fire in the land can see it."]]},
}
const ENDING_ORDER := ["azure", "home", "road", "open", "lotus"]

# ---------------------------------------------------------------- lookups
## The hearth a region belongs to ("" for the wild places and the other realms).
static func of_area(area: String) -> String:
	for id in ORDER:
		if area in HEARTHS[id].areas:
			return id
	return ""

## The hearth of a town of the people of the land (folk.gd TOWNS; "" for the towns of other realms).
static func of_town(tid: String) -> String:
	for id in ORDER:
		if tid in HEARTHS[id].towns:
			return id
	return ""

## The hearth a named person belongs to ("" for most).
static func of_npc(npc: String) -> String:
	for id in ORDER:
		if npc in HEARTHS[id].kin:
			return id
	return ""

## The hearth the hero spent the year away at (character creation).
static func own(g) -> String:
	var id := str(g.hero.get("hearth", "valley"))
	return id if HEARTHS.has(id) else "valley"

## 0 a stranger, 1 a guest, 2 kin.
static func tier(g, id: String) -> int:
	var n := int(g.hearth.get(id, 0))
	return 2 if n >= KIN else (1 if n >= GUEST else 0)

static func tier_name(t: int) -> String:
	return ["Stranger", "Guest", "Kin"][clampi(t, 0, 2)]

## How many hearths call the hero a guest (or kin).
static func guests(g) -> int:
	var k := 0
	for id in ORDER:
		if tier(g, id) >= 1:
			k += 1
	return k

## The sum of one passive (the keys of Fashion.gear) over the hearths: the gift of the hero's own
## hearth (`fx`), and what each hearth gives its guests (`guest_fx`; kin have half as much again).
static func gear(g, key: String) -> float:
	var v := float(HEARTHS[own(g)].fx.get(key, 0.0))
	for id in ORDER:
		var t := tier(g, id)
		if t >= 1 and HEARTHS[id].guest_fx.has(key):
			var gv := float(HEARTHS[id].guest_fx[key])
			# (a whole number stays whole: speed)
			v += gv if (t < 2 or absf(gv) >= 1.0) else gv * 1.5
	return v

## Earn standing with a hearth; returns the tier newly reached (0 if none).
static func earn(g, id: String, n: int) -> int:
	if not HEARTHS.has(id) or n <= 0:
		return 0
	var before := tier(g, id)
	g.hearth[id] = mini(int(g.hearth.get(id, 0)) + n, KIN)
	var after := tier(g, id)
	return after if after > before else 0

## What is said when a hearth first calls the hero a guest, or kin.
static func welcome(id: String, t: int) -> String:
	var h: Dictionary = HEARTHS[id]
	if t >= 2:
		return "%s call you kin: there is a place at %s that is yours (%s, half as much again)" % [str(h.people), str(h.n), str(h.guest_text)]
	return "%s call you a guest of %s (%s)" % [str(h.people), str(h.n), str(h.guest_text)]

## A line of a hearth's own for one of its townsfolk (`k` picks among them).
static func line(id: String, k: int) -> String:
	var ls: Array = HEARTHS[id].lines
	return str(ls[posmod(k, ls.size())])

## What somebody of a hearth calls out in the street (`k` picks among them).
static func hail(id: String, k: int) -> String:
	var hs: Array = HEARTHS[id].hail
	return str(hs[posmod(k, hs.size())])

## The Felt Hearth's fire, as it stands by its keeper in the grass below Thunder Valley: three hearth
## stones with a fire of argal between them, a kettle on it, and behind it a curved windbreak of white
## felt on a lattice, with a blue scarf tied to its pole.
static func camp() -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	var felt := MB.tag(Color("e8e0cc"), MB.CLOTH)
	var wood := MB.tag(Color("7a5a38"), MB.WOOD)
	# the windbreak: an arc of felt panels behind the fire, lattice showing at the foot
	for k in 9:
		# (close at her back, inside her own tile, so nobody who walks up to her has it in the way)
		var a := -1.0 + 2.0 * float(k) / 8.0
		var c := Vector3(sin(a) * 1.05, 0.0, -cos(a) * 1.05 - 0.1)
		b.box(c + Vector3(0, 0.5, 0), Vector3(0.27, 0.78, 0.06), felt, Vector3(0, -a, 0))
		b.box(c + Vector3(0, 0.08, 0), Vector3(0.27, 0.16, 0.045), wood, Vector3(0, -a, 0))
		b.box(c + Vector3(0, 0.91, 0), Vector3(0.28, 0.05, 0.08), MB.tag(Color("8a2a3a"), MB.CLOTH), Vector3(0, -a, 0))
	b.limb(Vector3(0, 0, -1.2), Vector3(0, 2.1, -1.2), 0.04, 0.028, wood, 6)
	b.box(Vector3(0.16, 1.92, -1.2), Vector3(0.34, 0.2, 0.02), MB.tag(Color("3a6ac8"), MB.CLOTH), Vector3(0, 0, -0.25))
	# the three stones, the fire and the kettle
	for k2 in 3:
		var a2 := TAU * float(k2) / 3.0 + 0.5
		b.sph(Vector3(0.55 + sin(a2) * 0.24, 0.08, -0.45 + cos(a2) * 0.24), Vector3(0.13, 0.1, 0.12), MB.tag(Color("6a6460"), MB.STONE))
	b.sph(Vector3(0.55, 0.27, -0.45), Vector3(0.15, 0.12, 0.15), MB.tag(Color("3a3432"), MB.STONE))
	b.limb(Vector3(0.67, 0.3, -0.45), Vector3(0.83, 0.4, -0.45), 0.025, 0.016, MB.tag(Color("3a3432"), MB.STONE), 5)
	g.sph(Vector3(0.55, 0.11, -0.45), Vector3(0.1, 0.08, 0.1), Color(1.0, 0.62, 0.25, 0.95))
	g.ball(Vector3(0.55, 0.16, -0.45), 0.36, Color(0.5, 0.7, 1.0, 0.14), true)
	MB.mesh_node(root, b.build(MB.mat_vc()))
	MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

# ---------------------------------------------------------------- the beginning
## The beginning (cultures.gd): where the hero stands on the last morning at the hearth: open ground
## six steps' walk from the hearth's keeper `keeper` in region `area` (the same tile every time).
static func start_tile(area: String, keeper: String) -> Vector2i:
	var lw: Dictionary = Atlas.world_of(Data.layer_of(area))
	var kp := Atlas.to_world(area, Vector2i(20, 8))
	var taken := {}
	for e in lw.ents:
		taken[e.pos] = true
		if e.kind == "npc" and str(e.id) == keeper and str(e.get("area", "")) == area:
			kp = e.pos
	var lw_w: int = int(lw.w)
	var lw_h: int = int(lw.h)
	var dist := {kp: 0}
	var q: Array = [kp]
	var qi := 0
	var best := kp
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		var dc: int = dist[c]
		if dc >= 6 and not taken.has(c) and lw.grid[c.y * lw_w + c.x] != MapGen.INTERIOR:
			return c
		if dc >= 2 and not taken.has(c):
			best = c
		for d in MapGen.DIRS:
			var nb: Vector2i = c + d
			if nb.x < 0 or nb.y < 0 or nb.x >= lw_w or nb.y >= lw_h or dist.has(nb) or (taken.has(nb) and nb != kp):
				continue
			if not MapGen.is_walkable_tile(lw.grid[nb.y * lw_w + nb.x]):
				continue
			dist[nb] = dc + 1
			q.append(nb)
	return best

# ---------------------------------------------------------------- the ends of the story
static func ending_need_met(n: Array, g) -> bool:
	match str(n[0]):
		"home":
			return true
		"guests":
			return guests(g) >= int(n[1])
		"peoples":
			return Trials.friends(g) >= int(n[1])
		"heart":
			return Bonds.level(g) >= int(n[1])
	return false

static func ending_need_text(n: Array, g) -> String:
	match str(n[0]):
		"guests":
			return "%d hearths that call you a guest (yours: %d)" % [int(n[1]), guests(g)]
		"peoples":
			return "%d peoples of the realms that call you friend (yours: %d)" % [int(n[1]), Trials.friends(g)]
		"heart":
			return "You and Yue Ling: %s at least (now %s)" % [Bonds.TITLES[int(n[1])], Bonds.title(g)]
	return ""

static func ending_open(id: String, g) -> bool:
	for n in ENDINGS[id].needs:
		if not ending_need_met(n, g):
			return false
	return true

## The ends the journey has earned, in order (the Azure Cloud is always among them).
static func endings_open(g) -> Array:
	return ENDING_ORDER.filter(func(id): return ending_open(id, g))

## The ending chosen ("azure" until one is).
static func ending_of(g) -> String:
	var id := str(g.ending)
	return id if ENDINGS.has(id) else "azure"

## How the story closes for the ending chosen, and what the hero's own hearth says of it.
static func ending_lines(g) -> Array:
	var out: Array = []
	var home := str(HEARTHS[own(g)].home)
	for ln in ENDINGS[ending_of(g)].lines:
		out.append([str(ln[0]), str(ln[1]).replace("%home%", home)])
	out.append_array(HEARTHS[own(g)].ending)
	return out
