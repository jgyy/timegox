class_name Marks
extends RefCounted
## What the choices built (the Lost Horse release): every crossroads leaves its answer standing in the land.
##
## Until this release a crossroads (echoes.gd) changed numbers and conversations: what was chosen was
## *said* for the rest of the story, and nothing of it could be walked up to.  Now each answer **stands
## somewhere**: the forty men set to mend the bamboo road left a corduroy road and their mallets beside
## it, and the forty driven over the pass left a cold fire and a row of graves; the Blood Moon Palace
## sealed is nine stones and a barred gate, and opened is a gate with lanterns and washing on a line.
##
##   * MARKS: for each crossroads, for each answer, **what stands, where, and what is read on it**: a
##     thing built from code (`model`), in the region the answer touched, on open ground that is found
##     when the world is made (`place`, after everything else: no older map moves).  Some answers
##     stand as more than one thing (`k`): a sea-wall is eight lengths of wall, a field of graves
##     twelve mounds;
##   * some answers leave **somebody** there too (`who`): a road-mender, a keeper, a widow, with a body
##     of the towns and words of their own, who is only in the world of somebody who chose that way;
##   * SIGNS: what the **three scales** do to every region once one leans: a wayside shrine or a board
##     of edicts for mercy and rigour, a wind-pump or a mossed stele for the new works and the old
##     ways, a milestone hung with the colours of far peoples or a hearth-cairn for the wide world and
##     the home fire.  One of each, in every region of the land, as soon as the land knows him by it.
##
## Nothing here is drawn until it stands (`key`): the model of an answer never given is never built,
## and the bot and the tests ask only `stands`.  A mark looked at is remembered (`Game.marks_seen`).

const WOOD := Color("7a5a38")
const WOOD_DARK := Color("4a3626")
const WOOD_PALE := Color("b89868")
const STONE := Color("8a8478")
const STONE_DARK := Color("5a564e")
const MOSS := Color("5a7a48")
const BRONZE := Color("b8863a")
const IRON := Color("4a4a52")
const CLAY := Color("b0785a")
const PAPER := Color("f0e8d0")
const RED := Color("c8302a")
const WATER := Color("4a8ab0")
const STRAW := Color("d8c070")
const ASH := Color("3a3632")

## What each answer of each crossroads leaves standing: `area`, `m` (the model and what it is made
## with), `n` (its name over it), `desc` (what is read there), `k` (how many of it; 1 if not given)
## and `who` (somebody who stands by it: [name, a body of the towns, colour, what they say...]); `near`
## (a tile of the region: it stands on the open ground nearest that, not wherever the draw falls).
const MARKS := {
	"bandits": {
		"mend": {"area": "bamboo", "m": ["road"], "k": 5, "n": "The Menders' Road", "desc": "Split logs laid side by side across the soft ground, pegged at both ends, with a mallet left on the last of them by somebody who meant to come back for it. Forty men who robbed this road built it. It is not straight, and it has not sunk.",
			"who": ["Road-Mender Hou", "folk_farmer", Color("6a5a3a"), "Forty of us threw our knives in the bamboo. All forty are still in the valley. You count the ones who stayed; I count the logs.", "A road wants mending every spring. I used to think that was a reason not to build one."]},
		"drive": {"area": "bamboo", "m": ["fire", false], "k": 3, "n": "A Cold Camp", "desc": "A ring of stones with wet ash in it, and bamboo cut for a lean-to that was never finished. They stopped here one night on the way to the pass. Whoever swept the ash together afterwards did it with his hands."},
	},
	"garden": {
		"study": {"area": "marsh", "m": ["beds", Color("7a4a8a")], "k": 4, "n": "The Lifted Beds", "desc": "The beds the Hag's poisons were lifted from, root and all, with a slip of bamboo left in each and a cutting or two coming up again: what it was, what it does, how much of it is medicine. Alchemist Mo's hand. The plants are in pots on his windowsill. The last slip in every row says: not yet known."},
		"burn": {"area": "marsh", "m": ["fire", false, true], "k": 4, "n": "The Salted Ground", "desc": "Black stalks and white salt. Nothing has grown here since the garden was burned, not even marsh-grass, and the frogs go round it."},
	},
	"roc_egg": {
		"hatch": {"area": "thunder", "m": ["nest", Color("f0e0a0")], "n": "The Roc's Perch", "desc": "A post as thick as a man, driven in beside the tents, with the bark worn off the top by something heavy that lands on it. The horse-folk hang a strip of meat on it at dusk. By morning it is gone, and there is a feather a yard long in the grass.",
			"who": ["Egg-Mother Oyun", "folk_grandma", Color("b06a3a"), "It hatched in my coat. It thinks I am a roc. I have stopped arguing.", "She comes back when it thunders. The children run out, not in."]},
		"leave": {"area": "thunder", "m": ["nest", Color("c8d8e8")], "n": "The Storm's Nest", "desc": "The nest, where it was, on the scorched rock. The shell is in pieces, from the inside. Whatever came out of it learned the storm from the storm."},
		"sell": {"area": "mountain", "m": ["frame", "cage"], "n": "The Collector's Cage", "desc": "A cage of gilt bamboo on a stand at the edge of Cloudfoot, big enough for an ox, empty: the collector had it made before he knew the egg would never hatch. The egg sits on his shelf and stopped ticking long ago. No roc flies in the valley."},
	},
	"palace": {
		"seal": {"area": "palace", "m": ["gate", false, Color("5a2a2a")], "k": 1, "n": "The Nine Seals", "desc": "A gate of black timber, barred, with nine lotus seals across the bar and a stele beside it in the Elder's own hand: here was the Blood Moon Palace. Let it be nothing else. The seals have not weathered at all."},
		"open": {"area": "palace", "m": ["gate", true, Color("a83a2a")], "k": 1, "n": "The Open Palace", "desc": "The same gate with the bar taken off and burned, a lantern on each post, and a line of washing strung from the left one to a pillar of the hall. Somebody has chalked a hopscotch on the flagstones where the altar was.",
			"who": ["Widow Tao of the Palace", "folk_farmwife", Color("8a4a5a"), "Eleven families in the east wing, and a goat. The goat has the throne room. Nobody else wanted it.", "They say blood was spilled here. I say I have scrubbed it, and it came up."]},
	},
	"dragon_boon": {
		"rain": {"area": "village", "m": ["frame", "dragon"], "n": "The Rain Pole", "desc": "A carved dragon on a pole in the fields, facing east, with a bowl under its chin. Every spring the bowl is found full on the morning the planting begins, and nobody has seen the rain that filled it."},
		"sea": {"area": "longmen", "m": ["beacon"], "n": "The Dragon's Sea-Mark", "desc": "A tower of stacked stone with a pearl-coloured light at the top that burns with no oil. Boats steer by it down the gorge to the sea, and the boatmen say the water under its beam lies flat in any weather."},
	},
	"drawings": {
		"keep": {"area": "village", "m": ["bench"], "n": "The Spider on the Bench", "desc": "A bench under an awning with the drawings pinned to a board, grey with thumb-marks, and beside it eight brass legs and no body yet. Gongshu Ban has built it four times. It walked the fourth time, into the pond."},
		"burn": {"area": "forge", "m": ["fire", false], "n": "Where the Drawings Burned", "desc": "A scorch on Heaven's own floor, in the shape of a sheet of paper, that the forge's smiths step round. One corner did not burn. It shows a single joint, and nobody has been able to say what it joined."},
	},
	"nineteen": {
		"stele": {"area": "mountain", "m": ["stele", STONE, false], "n": "The Stele of the Nineteen", "desc": "Nineteen names, in the order they went, copied in stone from the jade strips in the wall of the ancestral hall. The stone stands where the road comes up to the sect, so that nobody arrives without passing them. Disciples touch the last name for luck before the examinations. It is worn smooth."},
		"wind": {"area": "garden", "m": ["flags", 9], "n": "The Nineteen Strips", "desc": "Nineteen strips of white silk on a cord at the edge of the Garden, with nothing written on them. The jade went over the edge, into the wind, and the silk was hung so that there would be something to see moving."},
	},
	"ancestor": {
		"strike": {"area": "grave", "m": ["stele", STONE_DARK, true], "n": "The Struck Tablet", "desc": "A stone in the row of the lineage, cracked across, with nothing on it. The lacquered tablet in the hall was planed smooth and taken down; this is the gap, kept among the dead. The place is still swept. Nobody can say why, or by whom."},
		"truth": {"area": "grave", "m": ["stele", STONE, false, true], "n": "The Tablet and What Is Under It", "desc": "His name, his dates, his titles, copied from the tablet in the hall; and under them, in a sweeper's wandering hand, what he took and from whom. It is the only tablet in the row that tells the truth, and the only one visitors stop at."},
	},
	"widow": {
		"truth": {"area": "maple", "m": ["tree", Color("9aa86a"), false], "n": "The Bare Willow", "desc": "The willow on the bank, with no ribbon on it and no lamp under it. She put the light out the day she was told, and left the lamp on the stone. It is still there, dry."},
		"kind": {"area": "maple", "m": ["tree", Color("9aa86a"), true], "n": "The Waiting Willow", "desc": "The willow on the bank, hung with red, and a lamp lit under it every dusk. She crossed long ago. Somebody on this bank lights it for her still, and does not say who."},
	},
	"crows": {
		"pardon": {"area": "magpie", "m": ["bridge", Color("2a2a34")], "n": "The Crows' Span", "desc": "One arch of the bridge is black. The crows built it beside the magpies, feather laid on feather, and it is the arch that does not sway. Lovers crossing step on it first, for luck, and the crows pretend not to see."},
		"banish": {"area": "magpie", "m": ["frame", "perch"], "n": "The Empty Roost", "desc": "A dead tree at the edge of the Heights with a thousand perching-places worn into it, and not one bird. The magpies will not roost here. On the seventh night the bridge is a little shorter than it was."},
	},
	"axe": {
		"give": {"area": "bamboo", "m": ["frame", "axe"], "n": "The Axe That Never Dulls", "desc": "A chopping block at the edge of the woodcutters' yard with an old axe sunk in it. It has never been ground. Each cutter takes it for a day in turn, and the stack of cordwood behind is as long as the yard."},
		"leave": {"area": "guanghan", "m": ["tree", Color("e8e0b0"), false, true], "n": "The Cassia, Uncut", "desc": "The cassia of the moon, whole. The cut that Wu Gang made every day and that closed every night has closed for the last time, with the axe-head grown into it like a nail in an old gatepost."},
	},
	"cauldron_map": {
		"copy": {"area": "longmen", "m": ["board", Color("2a2a2a")], "n": "The Map Board", "desc": "A board under a little roof with a rubbing pasted to it: black, with the rivers and roads of the whole land in white. Yu's map. Children put their finger on Longmen and trace the way to the sea. There is one of these in every town now.",
			"who": ["Carter Shen", "folk_merchant", Color("5a6a4a"), "I used to ask the way at every ferry and be lied to at half. Now I look at the board. The ferrymen are sour about it.", "Tushan is further than I thought, and the sea is nearer. A map is a rude thing."]},
		"keep": {"area": "tushan", "m": ["gate", false, BRONZE], "n": "The Founders' Screen", "desc": "A screen of bronze lattice the founders of Tushan have set before the Nine Cauldrons. Behind it the cauldrons stand under their great lid, in the dark. One may know the map is there. One may not take a rubbing. The founders say a map that everybody has is a road that every army has."},
	},
	"furnace": {
		"free": {"area": "fangzhang", "m": ["furnace", true], "n": "Three Footprints", "desc": "Three scorched prints in the turf, a pace apart, going down to the shore and not coming back. Grass will not grow in them. A hermit says he saw it on the sand at dawn, facing the water, as if deciding."},
		"return": {"area": "fangzhang", "m": ["furnace", false], "n": "The Furnace, Chained", "desc": "The Elixir Furnace on its three legs, back on its terrace, with a chain of white jade from each leg to a ring in the rock. It burns as well as it ever did. Now and then one foot lifts, an inch, and is set down again."},
	},
	"the_wheel": {
		"run": {"area": "village", "m": ["lamp_post"], "n": "The Lamp of the Night Shift", "desc": "A lamp on a post on the path to the wheel, lit at dusk for the watch that minds it through the night. Qingshi is never quite dark now. The owls have moved up the hill."},
		"hours": {"area": "village", "m": ["frame", "bell"], "n": "The Sluice Bell", "desc": "A bell in a frame by the mill-race. It is rung at dawn when the gate is lifted and at dusk when it is let down, by hand, and between the two rings the wheel is nobody's business but the water's."},
		"down": {"area": "village", "m": ["stack"], "n": "The Stacked Wheel", "desc": "The timber of the wheel, numbered joint by joint and stacked under thatch. Gongshu Ban comes and looks at it. He has not asked for it back, and nobody has burned a stick of it."},
	},
	"the_player": {
		"keep": {"area": "dunes", "m": ["figure", Color("c8a070"), 1, true], "n": "The Player's Stage", "desc": "Six boards on trestles in the sand and a curtain on a string. It plays at dusk to whoever comes: one dancer, lacquer and leather, who bows to the caravans as they pass and is bowed to."},
		"maker": {"area": "dunes", "m": ["bench"], "n": "Yan Shi's Bench", "desc": "A bench in the lee of a dune, with a figure of lacquer and leather lying on it under a cloth, and tools laid out in a row. The cloth rises and falls. Yan Shi said keep it, at once, and has been mending its hands ever since."},
		"still": {"area": "dunes", "m": ["mound", Color("c8a070")], "n": "Where the Player Stands", "desc": "A heap of sand against a long box stood on end at the caravan halt, and a wooden hand set upright before it, the fingers a little curled. What is in the box has its painted eyes open. Nobody plays it."},
	},
	"the_works": {
		"hand": {"area": "tushan", "m": ["stele", STONE, false, true], "n": "The Rule of the Hand", "desc": "Cut in stone at the gate of Tushan: let no engine do what nobody here can still do without it. Under it, a row of hand-tools on pegs, oiled, for anybody to prove it by."},
		"wheel": {"area": "tushan", "m": ["frame", "bell"], "n": "The Keepers' Bell", "desc": "The bell that gives every engine in the land its hours. It is rung at Tushan, and answered from town to town down the roads, and the wheels stop one after another like lamps going out along a street."},
		"dao": {"area": "tushan", "m": ["stele", Color("7ac8a0"), false], "n": "The Stone of the Whole Heart", "desc": "A plain green stone with one line on it: the cook's knife, nineteen years, never sharpened. Apprentices are sat in front of it on their first day and asked what it means, and on their last."},
		"ask": {"area": "terraces", "m": ["beds", Color("6a9a4a")], "k": 3, "n": "The Gardener's Rows", "desc": "Cabbage rows on a terrace, watered by hand from a pitcher, as the old man of Hanyin waters his in Qingshi. The makers come out from Tushan to ask him things. He goes on watering. Some of them stay a season."},
	},
	"the_mountain": {
		"road": {"area": "village", "m": ["road"], "n": "Yu Gong's Road", "desc": "The road to a tunnel a cart wide, cut through the first of Yu Gong's two mountains, with both left standing. Yu Gong's sons keep it. There is a stone at the top of the cut where the old man sits and looks at what he did not move."},
		"dig": {"area": "village", "m": ["stack", true], "n": "The Baskets Going By", "desc": "A heap of loose rock and a line of baskets on poles, waiting for the next pair of shoulders to carry them to the sea. The nearer mountain is lower than it was, by a hand's breadth. The sons of the sons are born already."},
		"leave": {"area": "village", "m": ["cairn", Color("6a9a4a")], "n": "The Last Basket", "desc": "One basket of earth, set down at the foot of the nearer mountain and never emptied. Grass has seeded in it. Yu Gong lifts his hat to the mountain when he passes, and something up among the rocks is seen to nod."},
	},
	"the_echoes": {
		"home": {"area": "karst", "m": ["flags", 7], "n": "The Quiet Mouth", "desc": "The cave mouth, with one echo in it. Shout your name, and it gives you your name, once. The ten thousand others went home, each to the voice that lost it, and all over the land that year people woke saying something they had forgotten they once said."},
		"keep": {"area": "karst", "m": ["flags", 5, RED], "n": "The Listening Rope", "desc": "A rope across the cave mouth, hung with red rags, and beyond it the dark. Stand at the rope and listen. Ten thousand voices, all at once, very far off, like a market heard from a hill."},
		"write": {"area": "karst", "m": ["board", PAPER], "k": 3, "n": "Xu Xiake's Leaves", "desc": "Sheets pinned up to dry on a board at the cave mouth, every one covered edge to edge: a child calling a dog, a man selling pears, somebody's last word. Xu Xiake is on the nine-thousandth. He has started to recognise voices."},
	},
	"the_hollow": {
		"empty": {"area": "mountain", "m": ["gate", false, STONE], "n": "A Blank Stone", "desc": "A face of dressed stone in the mountainside that might be a door, with no handle and no name on it. Nobody who passes knows what is behind it. Nothing is. That is what it is for."},
		"open": {"area": "mountain", "m": ["gate", true, STONE], "n": "The Quiet Door", "desc": "A door in the mountainside standing open, and a row of shoes outside it: straw sandals, a soldier's boots, a child's slippers. Inside nobody speaks. People come out looking as if they have slept.",
			"who": ["Shoe-Minder Jing", "folk_monk", Color("8a8a78"), "Wang Zhi keeps the door. I mind the shoes. Nobody has ever taken the wrong pair.", "A magistrate came, and a thief, the same morning. They went in. They came out. I did not ask."]},
		"cistern": {"area": "mountain", "m": ["well"], "k": 2, "n": "The Mountain's Cistern", "desc": "A stone head-work and a sluice where the Hollow has been filled, with a mark cut for each dry year and how far the water fell. Three marks. The fields below were green in all three."},
	},
	"the_pupils": {
		"all": {"area": "marsh", "m": ["posts", 7], "n": "The Open Yard", "desc": "Bamboo stakes driven in a ring in the marsh, each cut a hundred times at a hundred heights. Anybody may come. A fisherman's girl is the best of them this year, and nobody will say so to her face."},
		"sweep": {"area": "marsh", "m": ["rack", "broom"], "n": "The Year of Sweeping", "desc": "A rack of brooms at the edge of the Maiden's yard, each with a name and a date burned into the handle. A pupil sweeps a year in their own town, and hangs the broom here on the first day. It is exchanged for a bamboo switch, and most ask to have the broom back."},
		"none": {"area": "marsh", "m": ["mound", Color("9a9a8a")], "n": "The Ape's Bamboo", "desc": "One stalk of bamboo, split from top to bottom by a single stroke, standing over a mound of marsh earth. The Maiden's method is under it. In a banyan above, an old white ape, her last pupil, shows the small ones how to peel fruit. She comes and cuts nothing."},
	},
	"the_three_thousand": {
		"home": {"area": "palace", "m": ["board", RED], "n": "The Tally Wall", "desc": "Three hundred pegs in a wall, where three hundred tallies hung, each with a dead man's name and village. Every one was taken down in three days. A swordsman took one, and walked, and gave it to a mother, and stayed to mend her roof."},
		"guard": {"area": "dunes", "m": ["rack", "sword"], "n": "The Peace-Bonded Rack", "desc": "A rack at the caravan halt where the guards hang their swords, each tied into its sheath with a red cord. The wage is the same whether a cord is broken or not. There is a tally of broken cords all the same. It has four marks on it."},
		"judge": {"area": "palace", "m": ["frame", "cangue"], "k": 3, "n": "The Judgement Posts", "desc": "A post with a wooden collar hung on it, and under the collar a paper: who, whom, where, what was awarded. Some of the papers say pardoned. Most do not. The posts go on down the road to every village that lost somebody."},
	},
	"the_arms": {
		"melt": {"area": "tushan", "m": ["frame", "bell"], "n": "The Bell of Four Thousand Blades", "desc": "A bell cast from swords, hung at the gate of Tushan; its twin is at the gate of Qingshi. Its note is a little flat. The ploughshares went to the valleys and the pots to the kitchens; the bell stayed where it was cast, because it was agreed the founders should hear what became of their trade."},
		"rack": {"area": "silk", "m": ["rack", "spear"], "n": "The Mulberry Woods' Rack", "desc": "One rack, in the open, by the well, with the hamlet's arms on it and a keeper's name on a board above. One spear. Everybody knows it is there, and whose turn it is to oil it, and so does everybody's neighbour."},
		"school": {"area": "mountain", "m": ["posts", 5, true], "n": "The School of the Broom", "desc": "A yard on the mountain with eight weapons on its racks and a row of brooms before them. The first year is the broom. The masters say the stroke is the same; the pupils say the masters want the yard swept."},
		"bury": {"area": "grave", "m": ["mound", IRON], "k": 8, "n": "The Field of Names", "desc": "A small mound with a wooden slip in it, and on the slip a name: not of a man, of a sword. Frost-on-the-River. Third Brother. The One My Father Carried. One is buried a day. The rows are getting long, and every one is visited."},
	},
	"the_voices": {
		"fire": {"area": "silk", "m": ["fire", true], "n": "The Place Kept at the Fire", "desc": "A camp fire with one flat stone more round it than there are people, and a dish of salt on the stone. Late, something one-legged sits there with its back to the light and listens to the talk, and says nothing in anybody's voice but its own."},
		"bamboo": {"area": "silk", "m": ["stack"], "k": 3, "n": "Green Bamboo for the Fire", "desc": "Green bamboo cut in joints and stacked by the path, as the grandmothers stacked it. It bursts in the fire like thunder. On the height, something that cannot bear to be startled keeps its distance, and its hunger."},
		"drive": {"area": "silk", "m": ["lamp_post", true], "k": 5, "n": "The Torch Line", "desc": "A burned-out torch on a stake, one of a line that goes up over the ridge. It went, that night, ahead of the fire. The voices came back in the morning. Beyond the ridge, where there are no fires, travellers say they hear children calling, and do not answer."},
	},
	"the_kites": {
		"ask": {"area": "thunder", "m": ["frame", "chime"], "n": "The Asking Chimes", "desc": "A frame of wind-chimes on the launching-rock. A flier rings them and waits. If they ring back, the Earl of the Wind has said yes. Some days they hang dead still in a gale, and nobody flies."},
		"free": {"area": "thunder", "m": ["frame", "kite"], "k": 3, "n": "Kites of the Valley", "desc": "A cloud-kite on its pole, drying, patched in three colours of cloth. Every valley has the pattern now. A boy of nine flew from here to the river last week and was beaten for it, and then asked how."},
		"climbers": {"area": "thunder", "m": ["cairn", Color("60a8d8")], "n": "The Climbers' Mark", "desc": "A cairn at the foot of the rock with a blue rag on it. The wind bears up whoever has climbed to where he leaps from, and drops whoever was carried. Fliers add a stone on the way up, for the hands they came by."},
	},
	"the_tops": {
		"cairn": {"area": "mountain", "m": ["cairn", Color("d8d8d8")], "k": 2, "n": "The Nameless Cairn", "desc": "A heap of stones, each carried up by somebody. No name on any. The seventy-two kings' steles were taken back down and stand at the foot, where children read them to practise their characters."},
		"steps": {"area": "mountain", "m": ["steps"], "k": 5, "n": "Duke Xie's Steps", "desc": "A flight of the nine thousand, cut square, with a chain for the hand. Grandmothers go up it now in the fourth month, a few steps a day, and sell tea to each other at the landings."},
		"shut": {"area": "mountain", "m": ["gate", false, Color("6a6a7a")], "n": "The Gate at the Last Bend", "desc": "A gate across the path where it turns for the summit. It has no lock. Nobody opens it. The Lord of the Eastern Peak sends for whom he wants, and it has been a long time."},
	},
	"the_clay": {
		"stand": {"area": "millet", "m": ["figure", CLAY, 3], "k": 5, "n": "Soldiers in the Millet", "desc": "Clay soldiers standing in the crop, to the waist in it by midsummer. The farmers plough round them and hang their lunch on the spears. Sparrows nest in a helmet. No two of the faces are alike."},
		"home": {"area": "terraces", "m": ["figure", CLAY, 1], "n": "The Soldier Who Came Home", "desc": "A clay soldier at the foot of the tea terraces, facing the lane. The name in his collar was a terrace name. An old woman says he has her grandfather's ears, and brings him a cup of tea at New Year, and takes it away cold."},
		"kiln": {"area": "millet", "m": ["stack", false, CLAY], "k": 4, "n": "Tiles of Mount Li", "desc": "Stacks of roof-tile and brick the colour of the clay host, and jars in rows. Good clay, well fired twice. On the underside of one tile in a hundred there is still the print of an eyebrow."},
	},
	"the_lute": {
		"melt": {"area": "longmen", "m": ["frame", "lute"], "n": "The Lightened Lute", "desc": "A lute on a stand under an awning on the height above the ferry, and a blind man's stool. He plays in the evening. It is not good yet. The boatmen stop poling to listen anyway, and drift, and are late."},
		"keep": {"area": "longmen", "m": ["frame", "towrope"], "n": "The Tow-Path Beat", "desc": "A post on the tow-path, grooved by rope, where the haulers rest. They pull to the beat of a leaded lute now, one note a step, and the boats come up the Dragon Gate a day sooner. Nobody would call it music. Nobody is out of time."},
		"break": {"area": "longmen", "m": ["mound", IRON], "n": "The Broken Lute", "desc": "Splinters of a lute and a lump of lead on a rock above the ferry, left where they fell. The new one is seasoning, and will not be ready for ten years. He comes up some evenings and sits by the old one, and hums."},
	},
	"the_host": {
		"home": {"area": "village", "m": ["board", PAPER], "n": "The Roll, Read and Nailed Up", "desc": "The roll of the levy, every name with a stroke through it, nailed to a board on the drill ground: gone home. The stroke is in Lady Hao's hand. There is not one name without it."},
		"keep": {"area": "village", "m": ["flags", 6, RED], "n": "Banners of the Standing Host", "desc": "Company banners on the drill ground, six to a line, and under them at every hour somebody standing guard over a village that has never been attacked. The inn does well. The girls of Qingshi have stopped going to the well alone."},
		"band": {"area": "village", "m": ["frame", "drum"], "n": "The Drum of the Six Hearths", "desc": "A great drum on a stand before the Drum Tower, with six strips of cloth tied to its frame, one from each hearth. It is beaten once a year, when the six come to sing together, and for the rest it keeps the rain off a family of swallows."},
	},
	# ---- Part XXIV (the Lost Horse release)
	"the_tide": {
		"wall": {"area": "yanggu", "m": ["wall", STONE], "k": 6, "n": "King Qian's Sea-Wall", "desc": "Baskets of bamboo filled with stone, stacked and staked, a wall as high as a house between the market and the bore. The tide breaks on it every eighth month and goes back. Behind it the low fields have been sown for the first time in a hundred years."},
		"yield": {"area": "yanggu", "m": ["hut", true], "k": 6, "n": "Houses That Stand Up to Be Counted", "desc": "A house on legs, with a boat tied to one of them. When the bore comes the low ground is the tide's, as it always was, and the families sit on their own doorsteps with their feet drawn up and watch their fields being salted, and fish out of the window."},
		"arrows": {"area": "yanggu", "m": ["butt"], "k": 6, "n": "The Three Thousand Arrows", "desc": "An iron arrow the length of a man, shot into the mud of the foreshore and rusted there. The crossbowmen stand to every eighth month and loose at the crest. The tide has not been seen to notice. The crossbowmen have become very good."},
	},
	"the_ape": {
		"chain": {"area": "drowned", "m": ["pillar"], "k": 1, "n": "The Pillar under Turtle Mountain", "desc": "An iron pillar sunk in the rock, and from it a chain, each link the size of a millstone, going down into the water. At the end of it is a bell, and the bell is through his nose. On still nights it rings, once, as something turns over."},
		"dredge": {"area": "drowned", "m": ["channel"], "k": 5, "n": "The New Cut of the Huai", "desc": "A straight channel with a sluice of timber, and clear water going down it to the sea. Nine of these, one for each year Gun's wall stood. The fields either side are drowning less every year. Something long-armed was seen going down the cut at dawn, with the current, not looking back."},
		"boats": {"area": "drowned", "m": ["boat"], "k": 5, "n": "The Floating Village", "desc": "A flat boat with a house on it, a hen-coop on the house, and a bed of beans in a trough along the gunwale. The river is the ape's. The people live on top of it, and rise when he rises, and tell their children he is the reason they can all swim."},
	},
	"the_horse": {
		"keep": {"area": "aurora", "m": ["paddock", true], "n": "The Black Horse's Paddock", "desc": "A paddock of birch rails by the old man's tent, and in it a horse that will never be ridden to war, cropping grass. The boy with the stiff leg brings it water. Neither of them was taken when the riders came for the others."},
		"loose": {"area": "aurora", "m": ["paddock", false], "n": "The Open Rails", "desc": "A paddock with its rails taken down and stacked. The herd runs where it runs. Some years it comes back with strangers in it, and some years fewer, and the old man says the same thing either way."},
		"breed": {"area": "aurora", "m": ["board", WOOD_PALE], "n": "The Stud Book of the Frontier", "desc": "A board under a felt roof with the lines of every horse of the frontier painted on it: sire, dam, foal. Fortune is to be bred for, the fathers say. The old man has added, at the bottom, in charcoal: so far."},
	},
	# ---- Part XXV (the Three Burrows release): the three answers that made Guiyun what it is, on the mountain
	# round it (and one on Frostpeak)
	# Part XXVII (the Heavy Road release): what is done with the sack
	"the_sack": {
		"carry": {"area": "maple", "m": ["posts", 5], "k": 3, "n": "Rest-Posts of the Gorge Road", "desc": "Posts of maple set along the gorge road, each with a crosspiece at the height of a shoulder, so that somebody under a load can rest it without setting it down. The tops are worn pale already. Nobody has carved a name on any of them, and every porter who uses one says the same one.",
			"who": ["Porter Geng", "folk_porter", Color("7a6a50"), "You lean back, so, and the post takes it, and you stand there with your hands free like a lord. Thirty years I carried salt up this gorge and never once had my hands free on the road. I did not know what to do with them the first time. I scratched my nose.", "They say whoever had these set carries everybody's load and would not put it down when a monk said to. A fool, then, and may that fool live for ever."]},
		"share": {"area": "silk", "m": ["board", WOOD_PALE], "k": 2, "n": "The Carriers' Board", "desc": "A board of pale wood under a little roof at the edge of the Silk Woods, ruled in columns: the load, where it is going, what it weighs, and a row of names against each, one to a strap. At the bottom, in a governor's square hand, a hundred bricks, daily, one name.",
			"who": ["Mistress Ruan of the Carriers' Hall", "folk_shopwife", Color("8a6a4a"), "Every load on the board has four names or six, never one. That was the rule we were given: no strap without a shoulder, no shoulder without its name written. People read down it to see who carried what for whom. It is the most honest thing in the south, and I keep it.", "A boy came last week with his grandmother's whole house on a barrow and nobody to help. He had nine names against it by noon. He cannot read. He stood and looked at them all the same."]},
		"down": {"area": "bamboo", "m": ["shrine"], "n": "The Sack by the Gate", "desc": "A little roofed stand by the road into the Whispering Bamboo, with an old hemp sack hanging in it by its cord, empty, and a bench in front. Whoever comes home along this road stops and looks into it, finds nothing there, and goes on with their shoulders an inch lower.",
			"who": ["Old Mother Shi", "folk_grandma", Color("8a7a6a"), "My son went off to be a cultivator and came back carrying the troubles of four provinces, and thin. I brought him here and made him look in the sack. He said, there is nothing in it. I said, no. He slept two days.", "It is only a sack. The sweeper left it. They say the sweeper carried the sky, and then one day set everything down at home and went in to supper. I never heard of anything so sensible from anybody young."]},
	},
	# Part XXVIII (the Answering Land release): what is owed for a kindness
	"the_knot": {
		"nothing": {"area": "fusang", "m": ["cairn", STRAW], "n": "The Cairn Where He Put It Down", "desc": "A small cairn in the long grass of the Valley of Sunrise, and round it a patch where every stem stands straight and none is tied. On the top stone somebody has left a single knot of grass, undone, the stems smoothed flat with a thumb.",
			"who": ["Tanner Hou's Widow", "folk_farmwife", Color("8a7a5a"), "My father stopped coming to the field. Eleven years he went out at night and came in with green hands, and would not say. Then one morning he slept till noon, and ate two bowls, and played with the children.", "He told me somebody had said it was finished when it was done. He said it as if it were the best news he had ever had in his life. I have thought about it since. I think I owe rather less than I supposed, to rather more people."]},
		"ledger": {"area": "village", "m": ["board", PAPER], "n": "The Book of Kindnesses", "desc": "A board under a little roof in Qingshi with a book chained to it, ruled in four columns: what was done, by whom, for whom, and answered. Most of the last column is filled in. The first entry is in an old man's hand and has a line drawn through it very firmly.",
			"who": ["Book-Keeper Mu", "folk_scholar", Color("5a6a8a"), "People come to write down what was done for them, and then they stand reading what was done for everybody else. A man found his own name in it last week, nine times, in nine hands. He had no idea. He sat down on the step.", "Some say a kindness written down is a kindness spoiled. I say a kindness that nobody knows where to return goes sour in the house. I rule the columns. I do not judge the entries."]},
		"onward": {"area": "bamboo", "m": ["shrine"], "n": "The Open Box", "desc": "A little roofed stand at the edge of the Whispering Bamboo with a wooden box in it, the lid propped open with a twig and a few yellow petals in the bottom. Whoever passes puts something in for whoever comes next: a rice-cake, a needle, a pair of sandals, once a goat.",
			"who": ["Yang Bao's Mother", "folk_shopwife", Color("c8a848"), "It was the box he kept the bird in. He set it here himself and said it was for strangers. I thought it would be empty in a day. It has never once been empty, and I have never once seen anybody fill it.", "I took a comb out of it in the spring, when ours broke. I put in a jar of plums. I do not know who had the plums. That is the whole of the arrangement, and it is the only one in this country that has never gone wrong."]},
	},
	# Part XXVI (the Underclothes release): what becomes of the Blue Bag Book
	"the_book": {
		"copy": {"area": "village", "m": ["board", PAPER], "k": 2, "n": "The Book on the Counter", "desc": "A board under a little roof beside the road, with pages of Hua Tuo's book pasted to it under oiled paper: the five frolics drawn in five strokes each, the place for the needle in a headache, how to set a wrist. Somebody has written beside the page on the knife, in another hand: ask first.",
			"who": ["Granny Lou the Bonesetter", "folk_grandma", Color("8a7a6a"), "I set my grandson's wrist by the page on the left, at midnight, with nobody else to ask. It has healed straight. I come and read the page on the right every morning so that I shall be ready for whatever he breaks next.", "People say a book of physic in every town is a danger. I say they have never been alone with a child screaming and a page to read by the lamp."]},
		"keep": {"area": "mountain", "near": Hold.AT + Vector2i(14, 9), "m": ["shrine"], "n": "The Shelf of the Blue Bag Book", "desc": "A little roofed stand by the Hall of the Broom with a book in a blue bag on it, a broom leaning against one post and a bench in front. Whoever has swept the street of Guiyun for a season may sit on the bench and read, and somebody who knows will come and sit beside them.",
			"who": ["Novice Tang of the Hall of the Broom", "folk_youth", Color("6a8aa8"), "I swept for a season to be allowed to sit here. I thought it was a test. It was not. By the end of the season I knew where every crack in the street was, and that is the first thing the book says: know the ground before you touch it.", "I have read as far as the bear. I am not allowed to read the page on the knife until somebody has watched me set a bone. That is fair. I would not let me either."]},
		"burn": {"area": "millet", "m": ["fire", false], "n": "The Brazier at the Jail Door", "desc": "A ring of stones on the plain where the camp of Wei stood, with the ash of a book in it that nobody has swept away. The jail is gone. Herbalists come past on their way to somewhere and stand here a moment, as at a grave, and then go on, and teach somebody something.",
			"who": ["Old Turnkey Wu", "folk_grandpa", Color("6a5a4a"), "I would not take the book. The law said whoever kept a prisoner's writing was a party to his crime. So I said no, through the bars, and my wife said yes, and then she burned it. Between us we did the worst thing either of us could have done alone.", "He forgave us both before the ashes were cold. I have not forgiven myself. That is the difference between a physician and a turnkey."]},
	},
	"the_tallies": {
		"burn": {"area": "mountain", "near": Hold.AT + Vector2i(-5, 4), "m": ["fire", false], "n": "Where the Tallies Burned", "desc": "A ring of stones with wet ash in it, a stone's throw from the town, swept round and left. Every debt of Guiyun's first winter went up here in a basket. Nobody has built on the place. In the ash, some mornings, there is a handful of millet that was not there the night before.",
			"who": ["Old Mother Qiu", "folk_grandma", Color("8a6a5a"), "I said it was a waste of good bamboo. I say it still. I come and say it to the ashes every morning, so that they do not think themselves too fine.", "My tally was the longest in the basket. Nine notches. I had counted on being in debt to somebody till I died; it is a kind of company. Now I owe nobody, and I have had to make friends."]},
		"collect": {"area": "mountain", "near": Hold.AT + Vector2i(-5, 4), "m": ["board", PAPER], "n": "The Posted Accounts", "desc": "A board under a little roof with the accounts of Guiyun pasted to it, household by household: owed, paid, the day. Every line has a stroke through it. The paper is renewed each harvest, in the same hand, and there has never been a line without its stroke. People pass it on the other side of the road."},
		"shares": {"area": "mountain", "near": Hold.AT + Vector2i(-5, 4), "m": ["pump"], "n": "The Mill of Shares", "desc": "Six sails of matting on a frame of poles, turning in the wind off the sea of clouds, and under them a stone that grinds the town's millet. Along the mill-house wall is a row of half-tallies, nailed up: each household's debt, become its share. The toll is a handful in the hundred, and the miller is whoever's turn it is."},
	},
	"the_door": {
		"all": {"area": "mountain", "near": Hold.AT + Vector2i(5, 13), "m": ["lamp_post"], "k": 5, "n": "Lanterns on the Road In", "desc": "A red lantern on a post, one of a line that runs down the mountain from the Cloud Gate, lit at dusk by whoever came in last. They are for those still on the road: the winged, the scaled, the ones who walk at night and would rather not be seen arriving. The oil is paid for out of the chest, under the heading: guests."},
		"hearth": {"area": "mountain", "near": Hold.AT + Vector2i(5, 13), "m": ["flags", 6], "n": "The Stone of Six Sureties", "desc": "A milestone on the road in, and over it a cord hung with six strips of cloth, one in the colour of each hearth of the land. Whoever comes with the word of a hearth ties a thread to that hearth's strip and goes up. The strips are thick with threads. Beside the stone, in the grass, somebody has slept."},
		"sweep": {"area": "mountain", "near": Hold.AT + Vector2i(5, 13), "m": ["rack", "broom"], "k": 3, "n": "Brooms at the Road's End", "desc": "A rack of brooms where the road reaches the town, for whoever has just arrived. One is taken, and the street is swept from the gate to the well, and after a season of it there is a door. Nobody is asked anything. The brooms are worn to different lengths, and the shortest is always gone first."},
	},
	"the_seat": {
		"found": {"area": "mountain", "near": Hold.AT + Vector2i(16, 4), "m": ["gate", true, Color("d8d0c0")], "n": "The Gate of the Returning Cloud", "desc": "Two posts and a lintel of new timber on the path above the town, with a lantern on each and a line of washing between: the gate of a sect that has no wall yet to put it in. Forty-one pine-green coats were folded and left here, the night the others went home. Most were collected. A few are still on the line, bleaching.",
			"who": ["First Disciple Ren", "folk_youth", Color("d8d0c0"), "I was eleven years in the Cold Pine and never once asked a question. Here I asked where the brooms were, and somebody told me. It was like being handed a cup of water.", "The founder says the first lesson is a street. I have swept it four hundred times. I think the second lesson is also the street. I have not asked. I am saving the question."]},
		"take": {"area": "frost", "m": ["posts", 7], "k": 3, "n": "The Kneeling Ground of the Cold Pine", "desc": "A ring of practice stakes in the snow below Frostpeak, each worn smooth at the height of a man's hands. Three hundred stand here at dawn, as they have for sixty years, and face south now, toward the town at whose gate they knelt, where the Patriarch is. The snow inside the ring is trodden to ice. Nobody has yet thought to sweep it."},
		"serve": {"area": "mountain", "near": Hold.AT + Vector2i(16, 4), "m": ["board", Color("2a2a2a")], "n": "The Board of the First Gate", "desc": "A board under a little roof where the path from Guiyun meets the nine hundred and ninety-nine steps: black, split with age, and across it in one stroke of white the character for cloud, as the sect's founder wrote it. It hung over the first gate. The Elder had it dusted and sent down, and has not spoken of it."},
	},
}

## What a leaning scale stands in every region: for each scale, for the way it leans, a model, a name
## and what is read on it.
const SIGNS := {
	"heart": {
		1: {"m": ["shrine"], "n": "A Wayside Table", "desc": "A table under a little roof with a jar of water on it, a ladle, and a bowl of something left for whoever is hungrier than whoever left it. It was not here before. People do this now, on roads Lin Feng has walked, as if it were the custom."},
		-1: {"m": ["frame", "cangue"], "n": "A Board of Edicts", "desc": "A post with a board of edicts and a wooden collar hung on it, ready. Nothing is posted that was not always the law. It is only that everybody along this road has heard what is done to those who break it, and by whom."},
	},
	"craft": {
		1: {"m": ["pump"], "n": "A Wind-Pump", "desc": "Six sails of matting on a frame of poles, turning, and a chain of buckets lifting water into a ditch. Somebody here saw one in the next valley and built it from memory. It squeaks. The field below it has not been carried to in a year."},
		-1: {"m": ["stele", MOSS, false], "n": "An Old Stone, Set Upright Again", "desc": "A stone of the old kings' time that had lain on its face in the grass for a thousand years. Somebody has stood it up and cleaned the moss out of the characters. They say: as it was done, so do."},
	},
	"reach": {
		1: {"m": ["flags", 5], "n": "A Milestone of Many Colours", "desc": "A milestone with the distances to places nobody here has been, and tied to it the colours of the peoples who pass: a feather of the winged, a scale, a strip of fox-silk, a cord of pearl-thread. Strangers leave them. They are not strangers long."},
		-1: {"m": ["fire", true], "n": "A Hearth-Cairn", "desc": "A ring of stones with a fire in it that somebody from the nearest house keeps in. It burns for somebody from one valley whose name went out and came back larger. Travellers warm their hands and are told, at length, whose fire it is."},
	},
}

# ---------------------------------------------------------------- what stands
## The answer of crossroads `cid` that stands at mark entity `e` for `g` ("" if none does there): the
## one chosen, if it stands in this region and is made of at least this many things.
static func answer(g, e: Dictionary) -> String:
	var ch := Echoes.chosen(g, str(e.cross))
	if ch == "" or not MARKS.get(str(e.cross), {}).has(ch):
		return ""
	var mk: Dictionary = MARKS[str(e.cross)][ch]
	return ch if str(mk.area) == str(e.area) and int(e.get("i", 0)) < int(mk.get("k", 1)) else ""

## Whether mark entity `e` stands in the world of game state `g`.
static func stands(g, e: Dictionary) -> bool:
	return key(g, e) != ""

## What mark entity `e` is in the world of `g` just now: "" while nothing stands there, otherwise a
## word that changes only if what stands there does (the world builds its model again when it does).
static func key(g, e: Dictionary) -> String:
	if e.has("scale"):
		var l := Echoes.lean(g, str(e.scale))
		return "" if l == 0 else "%s:%d" % [str(e.scale), l]
	var an := answer(g, e)
	return "" if an == "" else str(e.cross) + ":" + an

## The entry for mark entity `e` as it stands for `g` ({} if nothing does).
static func spec(g, e: Dictionary) -> Dictionary:
	if e.has("scale"):
		var l := Echoes.lean(g, str(e.scale))
		return SIGNS[str(e.scale)].get(l, {})
	var an := answer(g, e)
	return {} if an == "" else MARKS[str(e.cross)][an]

static func name_of(g, e: Dictionary) -> String:
	return str(spec(g, e).get("n", ""))

static func desc_of(g, e: Dictionary) -> String:
	return str(spec(g, e).get("desc", ""))

## How many things stand in the land of `g` because of what was chosen (of the realm entities `ents`).
static func standing(g, ents: Array) -> int:
	var n := 0
	for e in ents:
		if e.kind == "mark" and stands(g, e):
			n += 1
	return n

## How many crossroads answers have something standing for them in all, and how many things that is.
static func totals() -> Array:
	var a := 0
	var n := 0
	for cid in MARKS:
		for oid in MARKS[cid]:
			a += 1
			n += int(MARKS[cid][oid].get("k", 1))
	return [a, n]

## The places crossroads `cid` needs: region -> how many things the largest of its answers there is.
static func sites(cid: String) -> Dictionary:
	var out := {}
	for oid in MARKS.get(cid, {}):
		var mk: Dictionary = MARKS[cid][oid]
		out[str(mk.area)] = maxi(int(out.get(str(mk.area), 0)), int(mk.get("k", 1)))
	return out

## The id of the first thing answer `oid` of crossroads `cid` stands as.
static func id_of(cid: String, oid: String) -> String:
	return "mark:%s:%s" % [cid, str(MARKS[cid][oid].area)]

## What looking at mark `id` is remembered as: all the lengths of one wall are one thing looked at.
static func seen_key(id: String) -> String:
	return ":".join(id.split(":").slice(0, 3))

## Somebody who stands by a mark: whether they are in the world of `g`.
static func who_stands(g, e: Dictionary) -> bool:
	return Echoes.chosen(g, str(e.pick[0])) == str(e.pick[1])

# ---------------------------------------------------------------- where it stands
## Stand every mark and sign of the realm on open ground of its region: reachable, with open ground
## all round it (so it is in nobody's way), three tiles from anything else, off the roads and off the
## rock of the peaks.  All the answers of one crossroads share their ground in a region (only one of
## them ever stands), and an answer that is several things stands in a row where there is room for
## one (every other tile, so the row can be walked through).  A seeded draw, so the same every time;
## added to `ents`.
## The crossroads of a later release whose marks are stood after the late bands of an older one
## (`"warband5"`, `"warband6"`), in a second pass (`after_bands`): a mark stood before them would take
## ground a band of an older map stood on, and the band would move.
const AFTER_BANDS := ["the_book", "the_sack", "the_knot"]

static func place(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, ids: Array, ents: Array, layer: String, reach: Dictionary, peaks: Array, camps: Dictionary, after_bands: bool = false) -> void:
	var near := {}
	for e in ents:
		for et in (e.tiles if e.kind == "seal" else ([e.pos] if e.has("pos") else [])):
			_claim(near, et, 3)
	for area in camps:
		_claim(near, camps[area], 7)
	# (the tiles that can be walked to, region by region, once: not the whole realm again for each)
	var mine: Array = []
	for _k0 in ids.size():
		mine.append([])
	for p0 in reach:
		var q0: Vector2i = p0
		if q0.x >= 2 and q0.y >= 2 and q0.x < W - 2 and q0.y < H - 2:
			(mine[owner[q0.y * W + q0.x]] as Array).append(q0)
	for k in ids.size():
		var area: String = ids[k]
		var want: Array = []
		# (the signs of the scales first: one of each in every region, whatever else is crowded out)
		if area != Atlas.HUB and not after_bands:
			for sc in Echoes.SCALE_ORDER:
				want.append({"id": "sign:%s:%s" % [area, sc], "scale": sc, "k": 1, "who": []})
		for cid in Echoes.ORDER:
			if AFTER_BANDS.has(cid) != after_bands:
				continue
			var st := sites(cid)
			if st.has(area):
				var who: Array = []
				var wme := {"id": "mark:%s:%s" % [cid, area], "cross": cid, "k": int(st[area])}
				for oid in MARKS[cid]:
					if str(MARKS[cid][oid].area) == area and MARKS[cid][oid].has("who"):
						who.append([oid, MARKS[cid][oid].who])
					# (the Three Burrows release: an answer may say whereabouts in its region it stands, `near`,
					# a tile of the region: the open ground nearest it is taken, and nothing is drawn by lot)
					if str(MARKS[cid][oid].area) == area and MARKS[cid][oid].has("near"):
						wme["near"] = Atlas.to_world(area, MARKS[cid][oid].near)
				wme["who"] = who
				want.append(wme)
		var cset := {}
		if want.is_empty():
			continue
		for p in mine[k]:
			var q: Vector2i = p
			var g0: int = grid[q.y * W + q.x]
			if g0 != MapGen.FLOOR and g0 != MapGen.DECOR:
				continue
			var open := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var g1: int = grid[(q.y + dy) * W + q.x + dx]
					if not MapGen.is_walkable_tile(g1) or g1 == MapGen.INTERIOR:
						open = false
			if not open:
				continue
			var on_rock := false
			for pk in peaks:
				if str(pk.area) == area and Vector2(q - (pk.c as Vector2i)).length() < float(pk.r) + 1.5:
					on_rock = true
			if not on_rock:
				cset[q] = true
		var cands: Array = cset.keys()
		cands.sort()
		if cands.is_empty():
			continue
		# (out in the open first: ground with nothing built or growing thick within two tiles of it)
		var wide := {}
		for q4 in cands:
			var clear := true
			for dy4 in range(-2, 3):
				for dx4 in range(-2, 3):
					var q5: Vector2i = (q4 as Vector2i) + Vector2i(dx4, dy4)
					if q5.x < 0 or q5.y < 0 or q5.x >= W or q5.y >= H:
						clear = false
						continue
					var g4: int = grid[q5.y * W + q5.x]
					if not MapGen.is_walkable_tile(g4) or g4 == MapGen.INTERIOR:
						clear = false
			if clear:
				wide[q4] = true
		var wcands: Array = wide.keys()
		wcands.sort()
		var rng := RandomNumberGenerator.new()
		rng.seed = int(Data.AREAS[area].seed) * 613 + 29
		for wm in want:
			var n: int = int(wm.k)
			var row: Array = []
			var dir := Vector2i.ZERO
			# a row of n, every other tile, in one of the four directions, if the region has room for one
			var tries := 0
			if wm.has("near"):
				# the nearest open ground to where it was asked to stand, a row in whichever direction fits
				var by_d: Array = cands.duplicate()
				var nr: Vector2i = wm.near
				by_d.sort_custom(func(a, b2): return (a - nr).length_squared() < (b2 - nr).length_squared() or ((a - nr).length_squared() == (b2 - nr).length_squared() and a < b2))
				for c0 in by_d:
					for d0 in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
						var ok0 := true
						for i0 in n:
							var q0b: Vector2i = (c0 as Vector2i) + d0 * (i0 * 2)
							if near.has(q0b) or not cset.has(q0b):
								ok0 = false
								break
						if ok0:
							for i1 in n:
								row.append((c0 as Vector2i) + d0 * (i1 * 2))
							dir = d0
							break
					if not row.is_empty():
						break
			while row.is_empty() and tries < 900:
				tries += 1
				var in_wide: bool = tries <= 500 and not wcands.is_empty()
				var c: Vector2i = wcands[rng.randi() % wcands.size()] if in_wide else cands[rng.randi() % cands.size()]
				var d: Vector2i = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)][rng.randi() % 4]
				var ok := true
				for i in n:
					var q2: Vector2i = c + d * (i * 2)
					if near.has(q2) or not (wide.has(q2) if in_wide else cset.has(q2)):
						ok = false
						break
				if ok:
					for i2 in n:
						row.append(c + d * (i2 * 2))
					dir = d
			if row.is_empty():
				# no room for a row: the first where there is room, and the rest as near it as can be
				for c3 in cands:
					if not near.has(c3):
						row.append(c3)
						break
				while not row.is_empty() and row.size() < n:
					var best := Vector2i(-1, -1)
					var bd := 1.0e9
					for c2 in cands:
						if near.has(c2) or row.has(c2):
							continue
						var close := false
						for r0 in row:
							close = close or maxi(absi(c2.x - r0.x), absi(c2.y - r0.y)) < 2
						if close:
							continue
						var dd := Vector2(c2 - (row[0] as Vector2i)).length()
						if dd < bd:
							bd = dd
							best = c2
					if best.x < 0 or bd > 30.0:
						break
					row.append(best)
			for i3 in row.size():
				var me := {"kind": "mark", "id": str(wm.id) if i3 == 0 else "%s:%d" % [str(wm.id), i3], "pos": row[i3], "area": area, "layer": layer, "late": true, "i": i3, "line": dir}
				for f in ["cross", "scale"]:
					if wm.has(f):
						me[f] = wm[f]
				ents.append(me)
			for r1 in row:
				_claim(near, r1, 2)
			# somebody who stands by it (for an answer that leaves somebody)
			if not row.is_empty():
				var anchor: Vector2i = row[0]
				for wh in wm.who:
					for d2 in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
						var wp: Vector2i = anchor + (Vector2i(d2.y, d2.x) if dir.y != 0 else d2)
						var taken := false
						for e2 in ents:
							if e2.has("pos") and e2.pos == wp and str(e2.get("layer", layer)) == layer:
								taken = true
						if not taken:
							var wl: Array = wh[1]
							ents.append({"kind": "npc", "id": "who:%s:%s" % [str(wm.cross), str(wh[0])], "n": str(wl[0]), "asset": str(wl[1]), "col": wl[2], "pos": wp,
								"area": area, "layer": layer, "late": true, "vis": ["", ""], "pick": [str(wm.cross), str(wh[0])], "lines": wl.slice(3)})
							break

static func _claim(near: Dictionary, at: Vector2i, r: int) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			near[at + Vector2i(dx, dy)] = true

# ---------------------------------------------------------------- what it looks like
static func _stick(b: MB, a: Vector3, c: Vector3, r: float, col: Color) -> void:
	b.limb(a, c, r, r, col, 5)

## The model of what stands for `sp` (an entry of MARKS or SIGNS); `i` is which of its `k` this is, so
## that no two of a row are quite alike.
static func model(sp: Dictionary, i: int = 0) -> Node3D:
	var root := Node3D.new()
	var b := MB.new()
	var m := MB.new()
	var g := MB.new()
	var pivot := Vector3.ZERO
	var move := ""
	var a: Array = sp.get("m", ["cairn"])
	var w := MB.tag(WOOD, MB.WOOD)
	var wd := MB.tag(WOOD_DARK, MB.WOOD)
	var wp := MB.tag(WOOD_PALE, MB.WOOD)
	var st := MB.tag(STONE, MB.STONE)
	var h := Terrain3D.hash2(i, 13 + a.size(), 3.0)
	match str(a[0]):
		"stele":
			# a slab on a plinth; broken across, or with smaller writing newly cut under the old
			var sc := MB.tag(a[1], MB.STONE)
			b.box(Vector3(0, 0.12, 0), Vector3(1.0, 0.24, 0.6), MB.tag(STONE_DARK, MB.STONE))
			if a.size() > 2 and bool(a[2]):
				b.box(Vector3(0, 0.75, 0), Vector3(0.7, 1.0, 0.16), sc)
				b.box(Vector3(0.25, 0.2, 0.5), Vector3(0.7, 0.16, 0.6), sc, Vector3(0.1, 0.5, 0.2))
				b.box(Vector3(0, 0.8, 0.085), Vector3(0.3, 0.6, 0.01), MB.tag(Color("2a2826"), MB.STONE))
			else:
				b.box(Vector3(0, 1.2, 0), Vector3(0.7, 1.9, 0.16), sc)
				b.hemi(Vector3(0, 2.15, 0), Vector3(0.35, 0.3, 0.08), sc)
				for r in 6:
					b.box(Vector3(0, 1.85 - r * 0.2, 0.085), Vector3(0.42 - 0.05 * (r % 2), 0.05, 0.01), MB.tag(Color("3a3632"), MB.STONE))
				if a.size() > 3 and bool(a[3]):
					for r2 in 4:
						b.box(Vector3(0, 0.62 - r2 * 0.09, 0.085), Vector3(0.5, 0.03, 0.01), MB.tag(RED.darkened(0.3), MB.STONE))
		"cairn":
			for k in 11:
				var ang := TAU * k / 6.0 + h
				var ring := 0.5 if k < 6 else (0.25 if k < 10 else 0.0)
				var y := 0.14 if k < 6 else (0.4 if k < 10 else 0.64)
				b.sph(Vector3(cos(ang) * ring, y, sin(ang) * ring), Vector3(0.26, 0.18, 0.24) * (1.0 - 0.02 * k), MB.tag(STONE.darkened(0.12 * Terrain3D.hash2(k, i, 5.0)), MB.STONE), Vector3(0, ang, 0), true)
			_stick(b, Vector3(0, 0.6, 0), Vector3(0.05, 1.6, 0), 0.02, wd)
			b.box(Vector3(0.2, 1.42, 0), Vector3(0.34, 0.24, 0.012), MB.tag(a[1], MB.CLOTH), Vector3(0, 0, -0.12))
		"gate":
			# two posts, a lintel and a roof; shut and barred, or open with lanterns and a line of washing
			var gc := MB.tag(a[2], MB.WOOD)
			for sx in [-1.0, 1.0]:
				_stick(b, Vector3(sx, 0, 0), Vector3(sx, 2.5, 0), 0.11, gc)
				b.box(Vector3(sx, 0.12, 0), Vector3(0.36, 0.24, 0.36), st)
			b.box(Vector3(0, 2.4, 0), Vector3(2.6, 0.16, 0.2), gc)
			b.box(Vector3(0, 2.72, 0), Vector3(3.0, 0.1, 0.7), MB.tag(Color("3a3a40"), MB.STONE), Vector3(0.0, 0, 0))
			b.box(Vector3(0, 2.84, 0), Vector3(2.4, 0.1, 0.4), MB.tag(Color("3a3a40"), MB.STONE))
			if bool(a[1]):
				for sx2 in [-1.0, 1.0]:
					b.box(Vector3(sx2 * 1.45, 1.2, -0.5), Vector3(0.08, 2.2, 0.9), MB.tag(Color(a[2]).darkened(0.25), MB.WOOD), Vector3(0, sx2 * 0.5, 0))
					g.ball(Vector3(sx2 * 1.0, 2.05, 0.2), 0.16, Color(1.0, 0.7, 0.3, 0.85), true)
				_stick(b, Vector3(-1.0, 1.7, 0), Vector3(1.0, 1.6, 0.6), 0.012, MB.tag(Color("c8b080"), MB.CLOTH))
				for c3 in 4:
					b.box(Vector3(-0.6 + c3 * 0.4, 1.4, 0.12 + c3 * 0.12), Vector3(0.28, 0.42, 0.012), MB.tag([PAPER, Color("7a9ac8"), Color("d89a9a"), Color("9ac89a")][c3], MB.CLOTH), Vector3(0, 0.28, 0))
			else:
				b.box(Vector3(0, 1.15, 0), Vector3(1.9, 2.3, 0.1), MB.tag(Color(a[2]).darkened(0.25), MB.WOOD))
				b.box(Vector3(0, 1.2, 0.08), Vector3(2.1, 0.16, 0.1), MB.tag(IRON, MB.METAL))
				for c4 in 5:
					b.box(Vector3(-0.72 + c4 * 0.36, 1.2, 0.14), Vector3(0.12, 0.7, 0.012), MB.tag(Color("e8c84a"), MB.CLOTH))
		"road":
			# split logs laid across, pegged; a mallet left on the last
			for k2 in 7:
				_stick(b, Vector3(-0.85, 0.07, -0.9 + k2 * 0.3), Vector3(0.85, 0.07 + 0.02 * (k2 % 2), -0.9 + k2 * 0.3 + 0.06 * (h - 0.5)), 0.085, w if k2 % 3 != 0 else wp)
			for sx3 in [-0.95, 0.95]:
				_stick(b, Vector3(sx3, 0, -0.95), Vector3(sx3, 0.3, -0.95), 0.04, wd)
				_stick(b, Vector3(sx3, 0, 0.95), Vector3(sx3, 0.3, 0.95), 0.04, wd)
			if i == 0:
				_stick(b, Vector3(0.2, 0.18, 0.5), Vector3(0.7, 0.24, 0.9), 0.025, wp)
				b.box(Vector3(0.2, 0.22, 0.5), Vector3(0.3, 0.18, 0.18), wd, Vector3(0, 0.7, 0))
		"fire":
			# a ring of stones: burning (a dish of salt beside it), or cold, with charred stalks if the ground was salted
			for k3 in 8:
				var a3 := TAU * k3 / 8.0
				b.sph(Vector3(cos(a3) * 0.55, 0.09, sin(a3) * 0.55), Vector3(0.16, 0.11, 0.15), st, Vector3(0, a3, 0), true)
			if bool(a[1]):
				for k4 in 4:
					var a4 := TAU * k4 / 4.0 + 0.4
					_stick(b, Vector3(cos(a4) * 0.4, 0.05, sin(a4) * 0.4), Vector3(-cos(a4) * 0.1, 0.3, -sin(a4) * 0.1), 0.05, wd)
				g.ball(Vector3(0, 0.3, 0), 0.24, Color(1.0, 0.55, 0.2, 0.75), true)
				g.ball(Vector3(0.03, 0.55, 0), 0.13, Color(1.0, 0.8, 0.35, 0.6), true)
				b.sph(Vector3(0.95, 0.1, 0.2), Vector3(0.28, 0.08, 0.26), st, Vector3.ZERO, true)
				b.sph(Vector3(0.95, 0.18, 0.2), Vector3(0.1, 0.03, 0.1), MB.tag(Color("f4f0e8"), MB.STONE), Vector3.ZERO, true)
			else:
				b.sph(Vector3(0, 0.04, 0), Vector3(0.42, 0.05, 0.42), MB.tag(ASH, MB.STONE), Vector3.ZERO, true)
				_stick(b, Vector3(-0.2, 0.03, 0.1), Vector3(0.25, 0.08, -0.1), 0.04, MB.tag(Color("1a1816"), MB.WOOD))
				if a.size() > 2 and bool(a[2]):
					b.sph(Vector3(0, 0.02, 0), Vector3(1.2, 0.025, 1.1), MB.tag(Color("e8e4dc"), MB.STONE), Vector3.ZERO, true)
					for k5 in 6:
						var a5 := TAU * k5 / 6.0 + h * 3.0
						_stick(b, Vector3(cos(a5) * 0.9, 0, sin(a5) * 0.9), Vector3(cos(a5) * 0.95, 0.5 + 0.3 * Terrain3D.hash2(k5, i, 9.0), sin(a5) * 0.85), 0.03, MB.tag(Color("1a1816"), MB.WOOD))
				else:
					for k6 in 3:
						_stick(b, Vector3(-1.1 + k6 * 0.16, 0, -0.6), Vector3(-0.7 + k6 * 0.05, 1.0, -0.2), 0.03, MB.tag(Color("7a9a5a"), MB.WOOD))
		"beds":
			# three raised beds with a slip of bamboo at the head of each row
			for r3 in 3:
				b.box(Vector3(0, 0.1, -0.7 + r3 * 0.7), Vector3(1.9, 0.2, 0.46), MB.tag(Color("4a3a2a"), MB.STONE))
				for p in 6:
					var px := -0.8 + p * 0.32
					b.cone(Vector3(px, 0.4 + 0.08 * Terrain3D.hash2(p, r3 + i, 2.0), -0.7 + r3 * 0.7), 0.11, 0.2, MB.tag(Color(a[1]).lerp(Color("5a8a4a"), Terrain3D.hash2(p, r3, 4.0) * 0.7), MB.FOLIAGE), Vector3.ZERO, 6)
				b.box(Vector3(-1.0, 0.36, -0.7 + r3 * 0.7), Vector3(0.03, 0.36, 0.1), MB.tag(PAPER, MB.WOOD))
		"nest":
			# a great nest of sticks on a post, with shell in it
			_stick(b, Vector3(0, 0, 0), Vector3(0, 1.5, 0), 0.16, wd)
			b.torus(Vector3(0, 1.6, 0), 0.75, 0.016, w)
			b.torus(Vector3(0, 1.75, 0), 0.85, 0.014, wp)
			for k7 in 9:
				var a7 := TAU * k7 / 9.0
				_stick(b, Vector3(cos(a7) * 0.85, 1.62, sin(a7) * 0.85), Vector3(cos(a7 + 1.4) * 0.8, 1.8, sin(a7 + 1.4) * 0.8), 0.03, w)
			b.hemi(Vector3(0.1, 1.62, 0), Vector3(0.3, 0.36, 0.3), MB.tag(a[1], MB.STONE))
			b.sph(Vector3(-0.3, 1.7, 0.2), Vector3(0.16, 0.05, 0.2), MB.tag(a[1], MB.STONE), Vector3(0.4, 0.3, 0), true)
			b.leaf(Vector3(0.9, 0.02, 0.4), Vector3(1.6, 0.06, 0.7), 0.12, MB.tag(Color("d8d8e8"), MB.HAIR))
		"frame":
			# two posts and a bar, and what hangs from it
			var what := str(a[1])
			if what in ["bell", "drum", "chime", "lute", "kite", "cage", "towrope"]:
				for sx4 in [-0.8, 0.8]:
					_stick(b, Vector3(sx4, 0, 0), Vector3(sx4, 2.1, 0), 0.07, w)
				_stick(b, Vector3(-0.95, 2.05, 0), Vector3(0.95, 2.05, 0), 0.06, wd)
			match what:
				"bell":
					pivot = Vector3(0, 2.0, 0)
					m.lathe(Vector3(0, -1.1, 0), [Vector2(0.44, 0.0), Vector2(0.4, 0.3), Vector2(0.34, 0.75), Vector2(0.2, 0.95), Vector2(0.05, 1.0)], MB.tag(BRONZE, MB.METAL), 12)
					m.torus(Vector3(0, -0.06, 0), 0.08, 0.02, MB.tag(BRONZE.darkened(0.3), MB.METAL), Vector3(PI * 0.5, 0, 0))
					move = "rock"
				"drum":
					Machines._cyl(b, Vector3(0, 1.2, 0), 0.62, 0.5, MB.tag(RED.darkened(0.15), MB.WOOD), Vector3(PI * 0.5, 0, 0), 14)
					Machines._cyl(b, Vector3(0, 1.2, 0.26), 0.56, 0.02, MB.tag(Color("e8dcc0"), MB.CLOTH), Vector3(PI * 0.5, 0, 0), 14)
					var hc := [Color("3a8a4a"), Color("c8302a"), Color("d8b040"), Color("e8e8e8"), Color("2a3a5a"), Color("8a4ab0")]
					for k8 in 6:
						b.box(Vector3(-0.75 + k8 * 0.3, 1.85, 0.03), Vector3(0.1, 0.4, 0.012), MB.tag(hc[k8], MB.CLOTH))
				"chime":
					for k9 in 7:
						var cx := -0.6 + k9 * 0.2
						_stick(b, Vector3(cx, 2.0, 0), Vector3(cx, 1.75, 0), 0.006, MB.tag(Color("c8b080"), MB.CLOTH))
						_stick(b, Vector3(cx, 1.75, 0), Vector3(cx, 1.75 - 0.3 - 0.07 * k9, 0), 0.025, MB.tag(BRONZE.lightened(0.2), MB.METAL))
				"lute":
					b.box(Vector3(0, 1.0, 0), Vector3(1.3, 0.1, 0.34), MB.tag(Color("5a2a1a"), MB.WOOD), Vector3(0, 0, 0.12))
					for k10 in 5:
						_stick(b, Vector3(-0.6, 1.0, -0.12 + k10 * 0.06), Vector3(0.6, 1.14, -0.12 + k10 * 0.06), 0.004, MB.tag(Color("e8e0c0"), MB.METAL))
					b.box(Vector3(0, 2.2, 0), Vector3(2.0, 0.04, 1.0), MB.tag(Color("8a6a4a"), MB.CLOTH), Vector3(0.12, 0, 0))
					b.box(Vector3(0, 0.25, 0.7), Vector3(0.36, 0.5, 0.36), wd)
				"kite":
					b.ribbon([Vector3(-1.1, 1.7, 0.02), Vector3(0, 2.0, 0.3), Vector3(1.1, 1.7, 0.02)], [0.5, 0.75, 0.5], Vector3(0, -1, 0.2), MB.tag([Color("e86a9a"), Color("60a8d8"), Color("e8c84a")][i % 3], MB.CLOTH))
					_stick(b, Vector3(0, 2.0, 0.3), Vector3(0, 1.0, 0.1), 0.012, wp)
				"cage":
					for k11 in 12:
						var a11 := TAU * k11 / 12.0
						var bend := 0.5 if k11 in [0, 1, 11] else 0.0
						_stick(b, Vector3(cos(a11) * 0.7, 0.3, sin(a11) * 0.7), Vector3(cos(a11) * (0.7 + bend), 1.9, sin(a11) * (0.7 + bend)), 0.018, MB.tag(Color("d8b040"), MB.METAL))
					b.torus(Vector3(0, 0.3, 0), 0.72, 0.012, MB.tag(Color("d8b040"), MB.METAL))
					b.leaf(Vector3(0.2, 0.32, 0.1), Vector3(0.9, 0.36, 0.4), 0.1, MB.tag(Color("d8d8e8"), MB.HAIR))
				"towrope":
					_stick(b, Vector3(-0.8, 1.2, 0), Vector3(-2.2, 0.1, 0.5), 0.03, MB.tag(Color("c8b080"), MB.CLOTH))
					b.torus(Vector3(-0.8, 1.2, 0), 0.1, 0.02, MB.tag(Color("c8b080"), MB.CLOTH))
					b.box(Vector3(0.3, 0.25, 0.5), Vector3(0.9, 0.5, 0.3), wd)
				"dragon":
					_stick(b, Vector3(0, 0, 0), Vector3(0, 2.4, 0), 0.08, w)
					b.sph(Vector3(0.25, 2.45, 0), Vector3(0.4, 0.2, 0.18), MB.tag(Color("3a8a7a"), MB.SCALE))
					b.cone(Vector3(0.05, 2.7, 0.08), 0.04, 0.24, MB.tag(Color("e8dcc0"), MB.STONE), Vector3(0, 0, 0.3), 6)
					b.cone(Vector3(0.05, 2.7, -0.08), 0.04, 0.24, MB.tag(Color("e8dcc0"), MB.STONE), Vector3(0, 0, 0.3), 6)
					for k12 in 6:
						b.torus(Vector3(0, 2.2 - k12 * 0.3, 0), 0.13, 0.02, MB.tag(Color("3a8a7a"), MB.SCALE))
					b.lathe(Vector3(0.6, 0.0, 0), [Vector2(0.14, 0.0), Vector2(0.1, 0.7), Vector2(0.3, 0.8), Vector2(0.32, 0.9)], st, 10)
					b.sph(Vector3(0.6, 0.88, 0), Vector3(0.27, 0.02, 0.27), MB.tag(WATER, MB.CRYSTAL), Vector3.ZERO, true)
				"axe":
					Machines._cyl(b, Vector3(0, 0.3, 0), 0.45, 0.6, wd, Vector3.ZERO, 10)
					_stick(b, Vector3(0.05, 0.6, 0), Vector3(0.6, 1.4, 0.1), 0.035, wp)
					b.box(Vector3(0.02, 0.68, 0), Vector3(0.1, 0.22, 0.34), MB.tag(Color("d8dce4"), MB.METAL), Vector3(0, 0, 0.5))
					for k13 in 8:
						_stick(b, Vector3(-1.4, 0.1 + 0.2 * (k13 / 4), -0.6 + 0.36 * (k13 % 4)), Vector3(-0.7, 0.1 + 0.2 * (k13 / 4), -0.6 + 0.36 * (k13 % 4)), 0.1, wp)
				"perch":
					_stick(b, Vector3(0, 0, 0), Vector3(0.1, 2.8, 0), 0.14, MB.tag(Color("3a3430"), MB.WOOD))
					for k14 in 7:
						var a14 := TAU * k14 / 7.0 * 2.4
						var y14 := 1.1 + k14 * 0.24
						_stick(b, Vector3(0.05, y14, 0), Vector3(cos(a14) * (1.3 - k14 * 0.1), y14 + 0.4, sin(a14) * (1.3 - k14 * 0.1)), 0.04, MB.tag(Color("3a3430"), MB.WOOD))
				"cangue":
					_stick(b, Vector3(0, 0, 0), Vector3(0, 2.2, 0), 0.07, wd)
					b.box(Vector3(0, 1.75, 0.06), Vector3(0.8, 0.6, 0.04), wp)
					for k15 in 4:
						b.box(Vector3(0, 1.92 - k15 * 0.11, 0.085), Vector3(0.6, 0.03, 0.01), MB.tag(Color("2a2826"), MB.STONE))
					b.box(Vector3(0.25, 1.0, 0.1), Vector3(0.7, 0.7, 0.06), w, Vector3(0, 0, 0.3))
					b.sph(Vector3(0.25, 1.0, 0.1), Vector3(0.14, 0.14, 0.05), MB.tag(Color("1a1816"), MB.WOOD), Vector3.ZERO, true)
		"beacon":
			b.lathe(Vector3.ZERO, [Vector2(0.9, 0.0), Vector2(0.75, 1.2), Vector2(0.6, 2.6), Vector2(0.7, 2.7), Vector2(0.7, 2.85)], st, 10, MB.tag(STONE.lightened(0.15), MB.STONE))
			for k16 in 4:
				var a16 := TAU * k16 / 4.0
				_stick(b, Vector3(cos(a16) * 0.55, 2.85, sin(a16) * 0.55), Vector3(cos(a16) * 0.55, 3.5, sin(a16) * 0.55), 0.04, wd)
			b.cone(Vector3(0, 3.75, 0), 0.8, 0.5, MB.tag(Color("3a4a5a"), MB.STONE), Vector3.ZERO, 8)
			g.ball(Vector3(0, 3.15, 0), 0.3, Color(0.85, 0.95, 1.0, 0.9), true)
		"bench":
			b.box(Vector3(0, 0.75, 0), Vector3(1.8, 0.08, 0.7), wp)
			for sx5 in [-0.8, 0.8]:
				for sz in [-0.28, 0.28]:
					_stick(b, Vector3(sx5, 0, sz), Vector3(sx5, 0.75, sz), 0.04, wd)
			b.box(Vector3(0, 1.5, -0.4), Vector3(1.4, 0.9, 0.04), w)
			b.box(Vector3(0, 1.5, -0.37), Vector3(1.1, 0.7, 0.01), MB.tag(PAPER.darkened(0.12), MB.CLOTH))
			for k17 in 4:
				_stick(b, Vector3(-0.6 + k17 * 0.36, 0.82, 0.0), Vector3(-0.5 + k17 * 0.36, 0.84, 0.3), 0.03, MB.tag(BRONZE, MB.METAL))
			b.sph(Vector3(0.5, 0.92, -0.1), Vector3(0.3, 0.13, 0.18), MB.tag(Color("c8a070"), MB.CLOTH), Vector3.ZERO, true)
			b.box(Vector3(0, 2.2, 0), Vector3(2.2, 0.04, 1.3), MB.tag(Color("8a6a4a"), MB.CLOTH), Vector3(0.14, 0, 0))
			for sx6 in [-1.0, 1.0]:
				_stick(b, Vector3(sx6, 0, 0.6), Vector3(sx6, 2.1, 0.6), 0.04, wd)
				_stick(b, Vector3(sx6, 0, -0.6), Vector3(sx6, 2.3, -0.6), 0.04, wd)
		"flags":
			# a cord between two poles hung with strips; or a line of banners
			var n: int = int(a[1])
			var one: bool = a.size() > 2
			_stick(b, Vector3(-1.4, 0, 0), Vector3(-1.4, 2.4, 0), 0.045, wd)
			_stick(b, Vector3(1.4, 0, 0), Vector3(1.4, 2.4, 0), 0.045, wd)
			_stick(b, Vector3(-1.4, 2.3, 0), Vector3(1.4, 2.3, 0), 0.01, MB.tag(Color("c8b080"), MB.CLOTH))
			var fc := [Color("f4f0e8"), Color("e86a5a"), Color("60a8d8"), Color("e8c84a"), Color("7ac8a0"), Color("b88ad8"), Color("f0a050")]
			for k18 in n:
				var fx := -1.25 + 2.5 * (k18 + 0.5) / float(n)
				var col: Color = a[2] if one else (fc[0] if n >= 7 else fc[(k18 + i) % fc.size()])
				b.box(Vector3(fx, 2.3 - (0.42 if one else 0.3), 0.01 * (k18 % 2)), Vector3(0.9 * 2.5 / float(n) if one else 0.16, 0.84 if one else 0.6 + 0.2 * Terrain3D.hash2(k18, i, 6.0), 0.012), MB.tag(col, MB.CLOTH), Vector3(0, 0, 0.06 * sin(k18 * 1.7)))
			if not one and n < 7:
				b.box(Vector3(0, 0.35, 0), Vector3(0.36, 0.7, 0.26), st)
				b.hemi(Vector3(0, 0.7, 0), Vector3(0.18, 0.12, 0.13), st)
		"tree":
			# a willow or a cassia: a leaning trunk, a hanging crown, ribbons or an axe-head grown in
			var lc := MB.tag(a[1], MB.FOLIAGE)
			b.limb(Vector3(0, 0, 0), Vector3(0.2, 1.7, 0), 0.24, 0.16, wd, 8)
			b.limb(Vector3(0.2, 1.7, 0), Vector3(-0.5, 2.9, 0.3), 0.15, 0.07, wd, 6)
			b.limb(Vector3(0.2, 1.7, 0), Vector3(0.9, 2.8, -0.3), 0.13, 0.06, wd, 6)
			for k19 in 12:
				var a19 := TAU * k19 / 12.0
				var top := Vector3(0.15 + cos(a19) * 1.0, 3.0, sin(a19) * 1.0)
				b.ribbon([top, top + Vector3(cos(a19) * 0.5, -0.9, sin(a19) * 0.5), top + Vector3(cos(a19) * 0.6, -2.0, sin(a19) * 0.6)], [0.22, 0.2, 0.06], Vector3(-sin(a19), 0, cos(a19)), lc)
				if bool(a[2]) and k19 % 2 == 0:
					b.box(top + Vector3(cos(a19) * 0.58, -1.6, sin(a19) * 0.58), Vector3(0.05, 0.5, 0.012), MB.tag(RED, MB.CLOTH), Vector3(0, -a19, 0))
			b.sph(Vector3(0.15, 3.0, 0), Vector3(1.15, 0.5, 1.15), lc)
			if a.size() > 3 and bool(a[3]):
				b.box(Vector3(0.36, 1.0, 0.1), Vector3(0.16, 0.2, 0.06), MB.tag(Color("d8dce4"), MB.METAL), Vector3(0, 0.3, 0.2))
			else:
				b.box(Vector3(1.2, 0.12, 0.6), Vector3(0.7, 0.24, 0.5), st)
				if not bool(a[2]):
					b.box(Vector3(1.2, 0.27, 0.6), Vector3(0.3, 0.05, 0.2), MB.tag(RED.darkened(0.2), MB.CLOTH))
		"bridge":
			var bc := MB.tag(a[1], MB.HAIR)
			for k20 in 9:
				var u := (k20 - 4) / 4.0
				b.box(Vector3(u * 1.7, 0.2 + 0.9 * (1.0 - u * u), 0), Vector3(0.46, 0.14, 1.1), bc, Vector3(0, 0, -u * 0.7))
				if k20 % 2 == 0:
					for sz2 in [-0.5, 0.5]:
						_stick(b, Vector3(u * 1.7, 0.25 + 0.9 * (1.0 - u * u), sz2), Vector3(u * 1.7, 0.75 + 0.9 * (1.0 - u * u), sz2), 0.03, bc)
			for sz3 in [-0.5, 0.5]:
				b.ribbon([Vector3(-1.7, 0.72, sz3), Vector3(0, 1.62, sz3), Vector3(1.7, 0.72, sz3)], [0.03, 0.03, 0.03], Vector3(0, 1, 0), bc)
		"furnace":
			# the Elixir Furnace on three legs, chained; or only the prints it left
			if bool(a[1]):
				for k21 in 3:
					b.sph(Vector3(-0.8 + k21 * 0.8, 0.02, 0.3 * (k21 % 2)), Vector3(0.3, 0.02, 0.36), MB.tag(Color("1a1816"), MB.STONE), Vector3.ZERO, true)
					g.ball(Vector3(-0.8 + k21 * 0.8, 0.05, 0.3 * (k21 % 2)), 0.1, Color(1.0, 0.45, 0.15, 0.5), true)
			else:
				b.lathe(Vector3(0, 0.6, 0), [Vector2(0.3, 0.0), Vector2(0.62, 0.3), Vector2(0.66, 0.8), Vector2(0.4, 1.2), Vector2(0.46, 1.3)], MB.tag(BRONZE, MB.METAL), 12)
				for k22 in 3:
					var a22 := TAU * k22 / 3.0
					_stick(b, Vector3(cos(a22) * 0.4, 0.7, sin(a22) * 0.4), Vector3(cos(a22) * 0.6, 0, sin(a22) * 0.6), 0.07, MB.tag(BRONZE.darkened(0.2), MB.METAL))
					_stick(b, Vector3(cos(a22) * 0.6, 0.12, sin(a22) * 0.6), Vector3(cos(a22) * 1.5, 0.05, sin(a22) * 1.5), 0.03, MB.tag(Color("e8f0e8"), MB.CRYSTAL))
					b.torus(Vector3(cos(a22) * 1.5, 0.06, sin(a22) * 1.5), 0.12, 0.02, MB.tag(Color("e8f0e8"), MB.CRYSTAL))
				g.ball(Vector3(0, 1.0, 0.62), 0.16, Color(1.0, 0.5, 0.2, 0.8), true)
		"lamp_post":
			_stick(b, Vector3(0, 0, 0), Vector3(0, 2.0, 0), 0.05, wd)
			_stick(b, Vector3(0, 1.9, 0), Vector3(0.4, 1.9, 0), 0.03, wd)
			if a.size() > 1 and bool(a[1]):
				b.cone(Vector3(0, 2.15, 0), 0.09, 0.3, MB.tag(Color("1a1816"), MB.WOOD), Vector3(PI, 0, 0), 6)
			else:
				b.lathe(Vector3(0.4, 1.45, 0), [Vector2(0.06, 0.0), Vector2(0.16, 0.1), Vector2(0.16, 0.34), Vector2(0.06, 0.42)], MB.tag(RED, MB.CLOTH), 8)
				g.ball(Vector3(0.4, 1.66, 0), 0.13, Color(1.0, 0.75, 0.35, 0.85), true)
		"stack":
			# timber numbered and stacked under thatch; or a heap of spoil and baskets; or tiles and jars
			if a.size() > 2:
				for k23 in 3:
					b.box(Vector3(-0.6 + k23 * 0.6, 0.3, 0), Vector3(0.5, 0.6, 0.8), MB.tag(Color(a[2]).darkened(0.1 * k23), MB.STONE))
				for k24 in 4:
					b.lathe(Vector3(-0.75 + k24 * 0.5, 0.0, 0.9), [Vector2(0.1, 0.0), Vector2(0.2, 0.2), Vector2(0.16, 0.42), Vector2(0.08, 0.48)], MB.tag(Color(a[2]).lightened(0.1), MB.STONE), 8)
			elif a.size() > 1 and bool(a[1]):
				b.hemi(Vector3(0, 0, 0), Vector3(1.0, 0.8, 0.9), MB.tag(Color("6a5a48"), MB.STONE))
				for k25 in 3:
					b.lathe(Vector3(1.2, 0.0, -0.5 + k25 * 0.5), [Vector2(0.14, 0.0), Vector2(0.24, 0.3), Vector2(0.26, 0.34)], MB.tag(STRAW, MB.WOOD), 8)
				_stick(b, Vector3(1.2, 0.36, -0.6), Vector3(1.2, 0.4, 0.6), 0.025, wp)
			else:
				for k26 in 9:
					_stick(b, Vector3(-0.9, 0.12 + 0.2 * (k26 / 3), -0.3 + 0.3 * (k26 % 3)), Vector3(0.9, 0.12 + 0.2 * (k26 / 3), -0.3 + 0.3 * (k26 % 3)), 0.09, w if k26 % 2 == 0 else wp)
				b.box(Vector3(0, 0.95, 0), Vector3(2.1, 0.08, 1.2), MB.tag(STRAW, MB.FOLIAGE), Vector3(0.12, 0, 0))
		"figure":
			# standing figures of clay (or one of lacquer on six boards, with a curtain)
			var fc2 := MB.tag(a[1], MB.STONE)
			var cnt: int = int(a[2])
			for k27 in cnt:
				var fx2 := (k27 - (cnt - 1) * 0.5) * 0.8
				var fz := 0.3 * (k27 % 2)
				b.limb(Vector3(fx2, 0, fz), Vector3(fx2, 0.9, fz), 0.2, 0.16, fc2, 8)
				b.limb(Vector3(fx2, 0.9, fz), Vector3(fx2, 1.45, fz), 0.2, 0.14, MB.tag(Color(a[1]).darkened(0.12), MB.STONE), 8)
				b.ball(Vector3(fx2, 1.66, fz), 0.15, fc2)
				b.sph(Vector3(fx2, 1.82, fz - 0.03), Vector3(0.07, 0.07, 0.07), MB.tag(Color(a[1]).darkened(0.3), MB.STONE), Vector3.ZERO, true)
				if cnt > 1 and (k27 + i) % 2 == 0:
					_stick(b, Vector3(fx2 + 0.24, 0, fz + 0.1), Vector3(fx2 + 0.24, 2.3, fz + 0.1), 0.02, wd)
			if a.size() > 3:
				b.box(Vector3(0, 0.0, 0), Vector3(2.2, 0.16, 1.4), wp)
				_stick(b, Vector3(-1.1, 0, -0.7), Vector3(-1.1, 2.3, -0.7), 0.04, wd)
				_stick(b, Vector3(1.1, 0, -0.7), Vector3(1.1, 2.3, -0.7), 0.04, wd)
				b.box(Vector3(0, 1.5, -0.7), Vector3(2.2, 1.5, 0.02), MB.tag(Color("7a2a3a"), MB.CLOTH))
		"mound":
			b.hemi(Vector3(0, 0, 0), Vector3(0.7, 0.4, 0.55), MB.tag(Color("6a5a48"), MB.STONE))
			b.box(Vector3(0, 0.45, -0.6), Vector3(0.14, 0.9, 0.04), MB.tag(Color(a[1]).lightened(0.1), MB.WOOD), Vector3(0.06 * (h - 0.5), 0, 0.1 * (h - 0.5)))
			if a[1] == IRON:
				b.sph(Vector3(0.3, 0.42, 0.1), Vector3(0.2, 0.07, 0.16), MB.tag(Color("6a6a70"), MB.METAL), Vector3(0, h, 0), true)
		"board":
			# a board under a little roof, with what is pasted or pegged to it
			for sx7 in [-0.9, 0.9]:
				_stick(b, Vector3(sx7, 0, 0), Vector3(sx7, 2.2, 0), 0.06, wd)
			b.box(Vector3(0, 1.35, 0), Vector3(1.8, 1.2, 0.06), w)
			b.box(Vector3(0, 1.35, 0.04), Vector3(1.5, 0.95, 0.01), MB.tag(a[1], MB.CLOTH))
			if a[1] == Color("2a2a2a"):
				b.ribbon([Vector3(-0.7, 1.7, 0.05), Vector3(-0.2, 1.3, 0.05), Vector3(0.1, 1.5, 0.05), Vector3(0.7, 1.0, 0.05)], [0.02, 0.03, 0.02, 0.04], Vector3(0, 1, 0), MB.tag(Color("f4f0e8"), MB.CLOTH))
			elif a[1] == RED:
				for k28 in 15:
					b.box(Vector3(-0.6 + (k28 % 5) * 0.3, 1.65 - (k28 / 5) * 0.3, 0.07), Vector3(0.06, 0.2, 0.03), wp)
			else:
				for k29 in 7:
					b.box(Vector3(0, 1.72 - k29 * 0.12, 0.05), Vector3(1.2 - 0.15 * (k29 % 3), 0.03, 0.01), MB.tag(Color("2a2826"), MB.STONE))
			b.box(Vector3(0, 2.3, 0.1), Vector3(2.2, 0.06, 0.7), MB.tag(Color("3a3a40"), MB.STONE), Vector3(0.25, 0, 0))
		"posts":
			# practice stakes in a ring (with brooms before them for a school that starts with the broom)
			var pn: int = int(a[1])
			for k30 in pn:
				var a30 := TAU * k30 / float(pn)
				_stick(b, Vector3(cos(a30) * 1.1, 0, sin(a30) * 1.1), Vector3(cos(a30) * 1.1, 1.5 + 0.4 * Terrain3D.hash2(k30, 3, 2.0), sin(a30) * 1.1), 0.06, MB.tag(Color("9ab060"), MB.WOOD))
				b.torus(Vector3(cos(a30) * 1.1, 0.9, sin(a30) * 1.1), 0.065, 0.008, MB.tag(Color("c8d090"), MB.WOOD))
			if a.size() > 2:
				for k31 in 4:
					_stick(b, Vector3(-0.45 + k31 * 0.3, 0, 0), Vector3(-0.45 + k31 * 0.3, 1.4, 0.2), 0.02, wp)
					b.cone(Vector3(-0.45 + k31 * 0.3, 0.16, 0.02), 0.12, 0.32, MB.tag(STRAW, MB.FOLIAGE), Vector3.ZERO, 6)
		"rack":
			for sx8 in [-0.9, 0.9]:
				_stick(b, Vector3(sx8, 0, 0), Vector3(sx8, 1.7, 0), 0.06, wd)
			_stick(b, Vector3(-1.0, 1.6, 0), Vector3(1.0, 1.6, 0), 0.04, w)
			_stick(b, Vector3(-1.0, 0.4, 0), Vector3(1.0, 0.4, 0), 0.04, w)
			for k32 in 6:
				var rx := -0.75 + k32 * 0.3
				match str(a[1]):
					"broom":
						_stick(b, Vector3(rx, 0.3, 0.1), Vector3(rx, 1.9, 0.02), 0.02, wp)
						b.cone(Vector3(rx, 0.2, 0.12), 0.11, 0.36, MB.tag(STRAW, MB.FOLIAGE), Vector3.ZERO, 6)
					"sword":
						b.box(Vector3(rx, 1.0, 0.06), Vector3(0.07, 1.1, 0.03), MB.tag(Color("2a2a34"), MB.WOOD))
						b.torus(Vector3(rx, 1.4, 0.06), 0.06, 0.012, MB.tag(RED, MB.CLOTH), Vector3(PI * 0.5, 0, 0))
					_:
						_stick(b, Vector3(rx, 0.05, 0.1), Vector3(rx, 2.3 - 0.3 * (k32 % 2), 0.02), 0.022, wp)
						b.cone(Vector3(rx, 2.4 - 0.3 * (k32 % 2), 0.02), 0.04, 0.24, MB.tag(Color("d8dce4"), MB.METAL), Vector3.ZERO, 6)
			b.box(Vector3(0, 1.95, 0), Vector3(0.9, 0.2, 0.03), wp)
		"well":
			b.lathe(Vector3.ZERO, [Vector2(0.8, 0.0), Vector2(0.8, 0.6), Vector2(0.62, 0.6), Vector2(0.62, 0.2)], st, 12)
			b.sph(Vector3(0, 0.42, 0), Vector3(0.6, 0.02, 0.6), MB.tag(WATER, MB.CRYSTAL), Vector3.ZERO, true)
			b.box(Vector3(1.2, 0.5, 0), Vector3(0.16, 1.0, 0.9), MB.tag(STONE_DARK, MB.STONE))
			for k33 in 3:
				b.box(Vector3(1.29, 0.8 - k33 * 0.2, 0), Vector3(0.01, 0.03, 0.5), MB.tag(PAPER, MB.STONE))
		"steps":
			for k34 in 6:
				b.box(Vector3(0, 0.1 + k34 * 0.2, -0.9 + k34 * 0.36), Vector3(1.6, 0.2 + k34 * 0.4, 0.36), MB.tag(STONE.lightened(0.04 * (k34 % 2)), MB.STONE))
			for sx9 in [-0.9, 0.9]:
				_stick(b, Vector3(sx9, 0, -1.0), Vector3(sx9, 0.9, -1.0), 0.04, st)
				_stick(b, Vector3(sx9, 1.2, 1.0), Vector3(sx9, 2.1, 1.0), 0.04, st)
				_stick(b, Vector3(sx9, 0.85, -1.0), Vector3(sx9, 2.05, 1.0), 0.015, MB.tag(IRON, MB.METAL))
		"shrine":
			for sx10 in [-0.5, 0.5]:
				for sz4 in [-0.3, 0.3]:
					_stick(b, Vector3(sx10, 0, sz4), Vector3(sx10, 1.5, sz4), 0.035, wd)
			b.box(Vector3(0, 0.7, 0), Vector3(1.1, 0.06, 0.7), wp)
			b.box(Vector3(0, 1.58, 0.0), Vector3(1.5, 0.05, 1.0), MB.tag(STRAW, MB.FOLIAGE), Vector3(0.2, 0, 0))
			b.lathe(Vector3(-0.25, 0.73, 0), [Vector2(0.1, 0.0), Vector2(0.17, 0.16), Vector2(0.13, 0.34), Vector2(0.07, 0.38)], MB.tag(CLAY, MB.STONE), 8)
			b.lathe(Vector3(0.25, 0.73, 0.05), [Vector2(0.06, 0.0), Vector2(0.15, 0.08)], MB.tag(Color("e8e4d8"), MB.STONE), 8)
			b.ball(Vector3(0.25, 0.82, 0.05), 0.06, MB.tag(Color("f0d8a0"), MB.CLOTH), true)
			for k35 in 3:
				b.ball(Vector3(0.0 + k35 * 0.06, 0.78, -0.22), 0.035, MB.tag([Color("f0a0b0"), Color("f0e080"), Color("f4f0e8")][k35], MB.FOLIAGE), true)
		"pump":
			# a wind-pump: a frame of poles, six sails of matting turning, a trough
			for sx11 in [-0.5, 0.5]:
				_stick(b, Vector3(sx11, 0, -0.4), Vector3(0, 2.6, 0), 0.05, wd)
				_stick(b, Vector3(sx11, 0, 0.4), Vector3(0, 2.6, 0), 0.05, wd)
			b.box(Vector3(0.9, 0.1, 0), Vector3(1.2, 0.2, 0.4), w)
			b.box(Vector3(0.9, 0.18, 0), Vector3(1.1, 0.04, 0.3), MB.tag(WATER, MB.CRYSTAL))
			pivot = Vector3(0, 2.6, 0.12)
			for k36 in 6:
				var a36 := TAU * k36 / 6.0
				_stick(m, Vector3.ZERO, Vector3(cos(a36) * 1.3, sin(a36) * 1.3, 0), 0.025, wp)
				m.box(Vector3(cos(a36) * 0.85, sin(a36) * 0.85, 0.02), Vector3(0.7, 0.36, 0.012), MB.tag(STRAW, MB.CLOTH), Vector3(0, 0, a36))
			move = "spin"
		"wall":
			# a length of sea-wall: bamboo baskets of stone, stacked and staked
			for r4 in 3:
				for c5 in 3 - (r4 % 2):
					b.sph(Vector3(-0.7 + c5 * 0.7 + 0.35 * (r4 % 2), 0.3 + r4 * 0.5, 0), Vector3(0.4, 0.3, 0.5 - 0.06 * r4), MB.tag(Color(a[1]).darkened(0.1 * Terrain3D.hash2(c5, r4 + i, 3.0)), MB.STONE), Vector3.ZERO, true)
			for k37 in 4:
				_stick(b, Vector3(-0.9 + k37 * 0.6, 0, 0.5), Vector3(-0.9 + k37 * 0.6, 1.7, 0.36), 0.04, wd)
		"hut":
			# a house on legs with a boat tied to one of them
			for sx12 in [-0.7, 0.7]:
				for sz5 in [-0.6, 0.6]:
					_stick(b, Vector3(sx12, 0, sz5), Vector3(sx12, 1.3, sz5), 0.06, wd)
			b.box(Vector3(0, 1.36, 0), Vector3(1.8, 0.1, 1.6), w)
			b.box(Vector3(0, 1.95, -0.1), Vector3(1.5, 1.1, 1.2), wp)
			b.box(Vector3(0.2, 1.85, 0.51), Vector3(0.4, 0.8, 0.02), wd)
			b.prim("prism", MB._xf(Vector3(0, 2.85, -0.1), Vector3(1.9, 0.7, 1.6), Vector3.ZERO), MB.tag(STRAW, MB.FOLIAGE))
			_stick(b, Vector3(0.9, 0, 0.9), Vector3(0.75, 1.36, 0.75), 0.03, wd)
			b.sph(Vector3(1.5, 0.12, 0.2), Vector3(0.3, 0.14, 0.75), wd, Vector3(0, 0.2 + h, 0), true)
		"butt":
			# an iron arrow the length of a man, shot into the mud at a slant
			var ic := MB.tag(Color("7a4a3a").lerp(IRON, 0.5), MB.METAL)
			var lean := Vector3(0.5 - h, 0, 0.3)
			_stick(b, Vector3(0, 0, 0), Vector3(0, 1.9, 0) + lean, 0.035, ic)
			for k38 in 3:
				var a38 := TAU * k38 / 3.0
				b.leaf(Vector3(0, 1.5, 0) + lean * 0.8, Vector3(cos(a38) * 0.22, 1.95, sin(a38) * 0.22) + lean, 0.07, MB.tag(Color("d8d0c0"), MB.HAIR))
			b.sph(Vector3(0, 0.03, 0), Vector3(0.5, 0.04, 0.4), MB.tag(Color("4a4238"), MB.STONE), Vector3.ZERO, true)
		"pillar":
			b.lathe(Vector3.ZERO, [Vector2(1.1, 0.0), Vector2(0.9, 0.3), Vector2(0.4, 0.4), Vector2(0.34, 3.0), Vector2(0.44, 3.1), Vector2(0.3, 3.4)], MB.tag(IRON, MB.METAL), 10)
			for k39 in 7:
				b.torus(Vector3(0.5 + k39 * 0.34, maxf(0.14, 1.5 - k39 * 0.26), 0.1 * (k39 % 2)), 0.2, 0.03, MB.tag(Color("6a4a3a") if k39 % 3 == 0 else IRON, MB.METAL), Vector3(PI * 0.5 * (k39 % 2), 0, 0.6))
			b.lathe(Vector3(3.0, 0.0, 0), [Vector2(0.26, 0.0), Vector2(0.22, 0.2), Vector2(0.1, 0.42)], MB.tag(BRONZE, MB.METAL), 10)
		"channel":
			# a length of the new cut: two banks, clear water, a sluice of timber
			for sz6 in [-0.7, 0.7]:
				b.box(Vector3(0, 0.12, sz6), Vector3(2.2, 0.24, 0.36), MB.tag(Color("6a5a48"), MB.STONE))
			b.box(Vector3(0, 0.1, 0), Vector3(2.2, 0.1, 1.1), MB.tag(WATER, MB.CRYSTAL))
			if i % 3 == 0:
				for sz7 in [-0.6, 0.6]:
					_stick(b, Vector3(0, 0, sz7), Vector3(0, 1.3, sz7), 0.06, wd)
				_stick(b, Vector3(0, 1.25, -0.7), Vector3(0, 1.25, 0.7), 0.05, w)
				b.box(Vector3(0, 0.75, 0), Vector3(0.06, 0.6, 1.1), wp)
		"boat":
			# a flat boat with a house on it, a hen-coop, a trough of beans
			b.box(Vector3(0, 0.16, 0), Vector3(2.4, 0.3, 1.0), wd)
			b.box(Vector3(-1.35, 0.2, 0), Vector3(0.5, 0.2, 0.7), wd, Vector3(0, 0, 0.3))
			b.box(Vector3(1.35, 0.2, 0), Vector3(0.5, 0.2, 0.7), wd, Vector3(0, 0, -0.3))
			b.box(Vector3(-0.2, 0.75, 0), Vector3(1.2, 0.9, 0.8), wp)
			b.prim("prism", MB._xf(Vector3(-0.2, 1.4, 0), Vector3(1.4, 0.4, 1.0), Vector3.ZERO), MB.tag(STRAW, MB.FOLIAGE))
			b.box(Vector3(0.85, 0.48, 0.1), Vector3(0.4, 0.34, 0.4), w)
			b.box(Vector3(0, 0.4, 0.46), Vector3(1.8, 0.14, 0.12), MB.tag(Color("4a3a2a"), MB.STONE))
			for k40 in 6:
				b.cone(Vector3(-0.75 + k40 * 0.3, 0.6, 0.46), 0.07, 0.24, MB.tag(Color("5a9a4a"), MB.FOLIAGE), Vector3.ZERO, 6)
			b.sph(Vector3(0, 0.02, 0), Vector3(1.9, 0.02, 1.2), MB.tag(WATER, MB.CRYSTAL), Vector3.ZERO, true)
		"paddock":
			# birch rails round a lame horse cropping grass; or the rails taken down and stacked
			var bc2 := MB.tag(Color("e8e4d8"), MB.WOOD)
			if bool(a[1]):
				for k41 in 8:
					var a41 := TAU * k41 / 8.0
					var a42 := TAU * (k41 + 1) / 8.0
					var p0 := Vector3(cos(a41) * 1.7, 0, sin(a41) * 1.7)
					var p1 := Vector3(cos(a42) * 1.7, 0, sin(a42) * 1.7)
					_stick(b, p0, p0 + Vector3(0, 1.0, 0), 0.05, bc2)
					if k41 != 2:
						_stick(b, p0 + Vector3(0, 0.85, 0), p1 + Vector3(0, 0.85, 0), 0.03, bc2)
						_stick(b, p0 + Vector3(0, 0.45, 0), p1 + Vector3(0, 0.45, 0), 0.03, bc2)
				var hc2 := MB.tag(Color("7a5236"), MB.HAIR)
				b.sph(Vector3(0, 0.95, 0), Vector3(0.62, 0.32, 0.28), hc2)
				b.limb(Vector3(0.5, 1.05, 0), Vector3(0.95, 0.5, 0), 0.16, 0.11, hc2, 6)
				b.sph(Vector3(1.05, 0.36, 0), Vector3(0.2, 0.11, 0.1), hc2, Vector3(0, 0, -0.6))
				for lg in [[0.4, 0.14, 0.0], [0.4, -0.14, 0.0], [-0.42, 0.14, 0.0], [-0.42, -0.14, 0.25]]:
					_stick(b, Vector3(lg[0], 0.8, lg[1]), Vector3(lg[0] + lg[2], 0.0 + lg[2] * 0.6, lg[1]), 0.055, hc2)
				b.ribbon([Vector3(-0.6, 1.05, 0), Vector3(-0.85, 0.7, 0), Vector3(-0.8, 0.3, 0)], [0.07, 0.08, 0.02], Vector3(0, 0, 1), MB.tag(Color("2a1c14"), MB.HAIR))
				b.lathe(Vector3(1.2, 0.0, 0.6), [Vector2(0.14, 0.0), Vector2(0.2, 0.26)], wd, 8)
			else:
				for k43 in 6:
					_stick(b, Vector3(-1.1, 0.08 + 0.12 * (k43 / 3), -0.2 + 0.2 * (k43 % 3)), Vector3(1.1, 0.08 + 0.12 * (k43 / 3), -0.2 + 0.2 * (k43 % 3)), 0.035, bc2)
				for k44 in 3:
					var a44 := TAU * k44 / 3.0 + 0.5
					_stick(b, Vector3(cos(a44) * 1.7, 0, sin(a44) * 1.7), Vector3(cos(a44) * 1.7, 1.0, sin(a44) * 1.7), 0.05, bc2)
				for k45 in 5:
					b.torus(Vector3(-0.4 + k45 * 0.5, 0.015, 1.0 + 0.2 * (k45 % 2)), 0.1, 0.003, MB.tag(Color("3a3228"), MB.STONE))
		_:
			b.box(Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8), w)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc()))
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not m.is_empty():
		var mv := MB.mesh_node(root, m.build(MB.mat_vc()), pivot)
		root.set_meta(move, mv)
	return root
