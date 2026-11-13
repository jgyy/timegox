class_name Props
extends RefCounted
## Things to do in the world.  Every region has a few things of its own beside the road (a stone
## bench, a well, a wayside shrine, a temple bell, a qin on a stone table, a fishing spot, a swing,
## a wishing tree...), chosen by its theme, and every piece of furniture in a building can be used
## (pray at an altar, read at a bookshelf, sleep in a bed, stir a cauldron, work an anvil, weave at a
## loom...).  Facing one, Enter: Lin Feng walks up to it and does it, on clips of his own
## (art/lib/person.py INTERACT), with the thing in his hands where he needs one (a rod, a broom, a
## hammer, a ladle, a scroll, a dipper, a stone); the thing answers (the bell swings, the fire
## flares, the fish come up), Yue Ling joins in or watches, and something comes of it: rest, a drink,
## qi, a line of lore, a small find, a little cultivation.  The first time he does each kind of thing
## the world hears of it (renown +1: a pastime).
##
## Outdoor things stand on the forest edge or the shore beside open ground and furniture on the tiles
## it already filled: no tile anybody walks on is taken, so no road changes (the bot uses them only to
## grant Yue Ling's wishes and give back her memories, bonds.gd).

## what each thing is and what doing it means:
##   n      its name; verb: the hint ("Enter: ...")
##   clip   what Lin Feng does (a loop for `dur` seconds, or a one-shot); at: where he does it:
##          "face" (a step up to it), "seat" (on it, turned round to sit facing out, `off` metres
##          from its middle towards him), "before" (sitting in front of it facing it, `off` metres
##          out) or "on" (on its own tile: a cushion)
##   hold   what he holds while he does it; fx: how the thing answers
##   effect what comes of it; comp: what Yue Ling does meanwhile; lines: what is said of it
const KINDS := {
	# ---- outdoors (built here, see model())
	"bench": {"n": "Stone bench", "verb": "Sit and rest", "clip": "sit_bench", "dur": 5.0, "at": "seat", "off": 0.13, "effect": "rest", "comp": "sit_bench",
		"lines": ["Lin Feng sits and watches the road a while.", "The stone is warm from the sun. For a moment nothing needs doing.", "Yue Ling swings her feet and names the clouds."]},
	"well": {"n": "Well", "verb": "Draw water and drink", "clip": "drink", "dur": 2.6, "at": "face", "hold": "dipper", "fx": "splash", "effect": "drink", "comp": "watch",
		"lines": ["The water is cold enough to ache, and tastes of stone.", "Sweet water. Somebody dug this well a very long time ago and dug it well.", "He drinks, and the dipper goes back on its hook for the next traveller."]},
	"shrine": {"n": "Wayside shrine", "verb": "Light incense and pray", "clip": "pray", "dur": 4.5, "at": "face", "fx": "smoke", "effect": "qi", "comp": "pray",
		"lines": ["Three sticks of incense for the earth god of the road. The smoke goes straight up.", "Lin Feng asks nothing in particular, and feels heard anyway.", "Somebody has left a peach here. Lin Feng leaves another beside it."]},
	"bell": {"n": "Bronze bell", "verb": "Strike the bell", "clip": "strike", "dur": 2.4, "at": "face", "fx": "ring", "effect": "lore", "comp": "watch",
		"lines": ["BONG. The note goes out over the land and takes a long time to come back.", "The bell hums for a full minute. Birds lift off three hills away.", "Old Shen would approve: a clean strike, right on the lotus boss."]},
	"drum": {"n": "Great drum", "verb": "Beat the drum", "clip": "strike", "dur": 2.0, "at": "face", "fx": "boom", "effect": "lore", "comp": "laugh",
		"lines": ["DOOM. The drum answers like distant thunder.", "The beat rolls away down the valley like a stone.", "A drum like this once called armies. Today it calls nobody, and that is better."]},
	"qin": {"n": "Qin on a stone table", "verb": "Play the qin", "clip": "play_qin", "dur": 6.0, "at": "before", "off": 0.2, "fx": "notes", "effect": "qi", "comp": "play_flute", "comp_hold": "flute",
		"lines": ["Lin Feng plays Flowing Water, badly, and the stream plays it better beside him.", "A tune his mother hummed. He did not know he still remembered it.", "Yue Ling says it is the worst High Mountains she has ever heard, and asks for it again."]},
	"fishing": {"n": "Fishing spot", "verb": "Fish a while", "clip": "fish", "dur": 6.0, "at": "face", "hold": "rod", "fx": "ripple", "effect": "fish", "comp": "meditate",
		"lines": ["A tug: a silver carp, which he admires and puts back.", "Nothing bites. It is very peaceful not catching anything.", "A fat old fish rises, looks at the hook, and declines."]},
	"swing": {"n": "Swing", "verb": "Take a turn on the swing", "clip": "sit_bench", "dur": 5.0, "at": "seat", "off": -0.12, "fx": "swing", "effect": "rest", "comp": "laugh",
		"lines": ["Higher. Higher. A cultivator of his realm could fly, but this is better.", "The ropes creak like a ship, and the ground swoops away under his feet.", "Yue Ling pushes, and laughs when he yelps."]},
	"wish_tree": {"n": "Wishing tree", "verb": "Throw up a wish ribbon", "clip": "toss", "dur": 2.0, "at": "face", "fx": "ribbon", "effect": "luck", "comp": "pray",
		"lines": ["The red ribbon catches on a high branch: the wish will come true, they say.", "Lin Feng wishes for nothing much. The ribbon flies up anyway.", "Hundreds of ribbons, hundreds of wishes, all fluttering in the same wind."]},
	"stele": {"n": "Inscribed stele", "verb": "Read the inscription", "clip": "touch", "dur": 2.4, "at": "face", "fx": "glow", "effect": "lore", "comp": "watch",
		"lines": ["\"Whoever walks this road, walk it lightly.\" The rest is worn away.", "A list of names, and above them: \"They held the pass.\"", "An old poem about the moon. Somebody has corrected the rhyme in the margin."]},
	"herb_patch": {"n": "Spirit herbs", "verb": "Gather herbs", "clip": "gather", "dur": 2.8, "at": "face", "fx": "sparkle", "effect": "herb", "comp": "gather",
		"lines": ["A sprig of spirit grass, its dew still on it.", "He leaves the roots: they will grow back by the next moon.", "Yue Ling sniffs it and nods: good for the cauldron."]},
	"campfire": {"n": "Campfire", "verb": "Warm your hands", "clip": "warm", "dur": 4.5, "at": "face", "fx": "embers", "effect": "rest", "comp": "warm",
		"lines": ["The fire pops and settles. His fingers come back to life.", "Somebody left this fire laid and dry for the next traveller. He will do the same.", "Smoke and pine resin and the stars coming out."]},
	"stones": {"n": "Training stones", "verb": "Lift the stone lock", "clip": "lift", "dur": 3.0, "at": "face", "hold": "stone_lock", "fx": "dust", "effect": "train", "comp": "laugh",
		"lines": ["The stone lock goes up and stays up. Three years ago it would not have moved.", "He presses it overhead ten times and only the last one shakes.", "The disciples who train here have worn the grips smooth."]},
	"broom": {"n": "Broom and fallen leaves", "verb": "Sweep the leaves", "clip": "sweep", "dur": 5.0, "at": "face", "hold": "broom", "fx": "leaves", "effect": "qi", "comp": "laugh",
		"lines": ["Three years he swept the sect's steps. His hands still know how.", "Sweep, sweep. The mind goes quiet, and the leaves go into a neat heap.", "Yue Ling says he sweeps better than he fights. He takes it as a compliment."]},
	"weiqi": {"n": "Weiqi board", "verb": "Study the game left here", "clip": "sit_bench", "dur": 5.0, "at": "before", "off": 0.42, "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Black is winning, but White has a ladder nobody has seen. He leaves it for them.", "A game left half finished. He resists the urge to play a stone.", "Somebody is very good at this, and somebody else is very stubborn."]},
	"tea": {"n": "Tea table", "verb": "Pour a cup of tea", "clip": "drink", "dur": 2.6, "at": "face", "hold": "cup", "fx": "steam", "effect": "rest", "comp": "drink", "comp_hold": "cup",
		"lines": ["Mountain tea, a little bitter, and good.", "The pot is still warm. Somebody expects company.", "He pours a cup for Yue Ling first, as one should."]},
	"lion": {"n": "Stone lion", "verb": "Rub the lion's head for luck", "clip": "touch", "dur": 2.4, "at": "face", "fx": "glow", "effect": "luck", "comp": "laugh",
		"lines": ["The lion's head is worn bright by a thousand hands.", "A coin in the lion's mouth: somebody's thanks. He leaves it there.", "The lion looks unimpressed. Stone lions always do."]},
	"chimes": {"n": "Wind chimes", "verb": "Set the chimes ringing", "clip": "touch", "dur": 2.4, "at": "face", "fx": "chime", "effect": "qi", "comp": "watch",
		"lines": ["Bronze voices, one after another, then the wind takes them.", "The chimes ring, and something in his qi rings with them.", "Ting, ting, ting. Yue Ling hums the note."]},
	"lantern_st": {"n": "Stone lantern", "verb": "Light the lantern", "clip": "touch", "dur": 2.4, "at": "face", "fx": "light", "effect": "lore", "comp": "watch",
		"lines": ["The lamp takes the flame and the road is a little less dark.", "A moth arrives at once, as if it had been waiting.", "Somebody keeps this lantern trimmed. He trims it too."]},
	"koi": {"n": "Fish pond", "verb": "Feed the fish", "clip": "toss", "dur": 2.0, "at": "face", "fx": "koi", "effect": "qi", "comp": "laugh",
		"lines": ["The crumbs land and the water boils with orange and gold.", "One old carp, very large and very slow, gets nothing and does not mind.", "The fish follow him along the bank, hoping."]},
	# ---- the Lotus release (Part XV): bigger things, built by structures.gd, most of them done side by
	# side.  rise: how far above (or below) the ground he does it; pair: Yue Ling takes the place beside
	# him and does her part there; comp_hold: what she holds; clear: how many tiles round it the forest
	# stands back (only the look of the ground changes)
	"pavilion": {"n": "Pavilion", "verb": "Sit in the pavilion together", "clip": "sit_bench", "dur": 6.0, "at": "seat", "off": 0.05, "rise": Structures.PAVILION_TOP, "pair": true, "effect": "rest", "comp": "sit_bench", "clear": 1,
		"lines": ["They sit in the pavilion and let the land go by. Nobody says anything for a long time, and it is the best conversation of the week.",
			"Somebody has written a poem on the beam: \"I came to see the view and stayed for the company.\" Yue Ling says that is them exactly.",
			"The wind bells under the eaves ring once each, like people saying goodnight.",
			"Yue Ling leans her head on his shoulder for a moment, says the bench is very hard, and does not move."]},
	"watchtower": {"n": "Watchtower", "verb": "Climb up and look out", "clip": "gaze", "dur": 7.0, "at": "climb", "effect": "lore", "comp": "wave", "clear": 1,
		"lines": ["From the top the road runs out of sight both ways, and every bend of it is somewhere he has been.",
			"Far off a column of cooking smoke goes straight up. Somebody is making supper. The world is all right.",
			"Yue Ling waves from the bottom of the ladder, very small, and shouts something the wind takes away.",
			"He finds the sect on the horizon, a white dot on a blue mountain, and is surprised how much he misses it."]},
	"stage": {"n": "Open-air stage", "verb": "Perform a sword form", "clip": "sword_dance", "dur": 6.4, "at": "stage", "rise": Structures.STAGE_TOP, "fx": "blade", "effect": "train", "comp": "clap", "clear": 1,
		"lines": ["Rising cut, turning sweep, the low guard, the thrust. Yue Ling claps every figure as if she had never seen one before.",
			"The stage was built for operas. Today the opera is one sweeper and a sword, and the audience is one healer and three goats.",
			"He finishes the form with the blade dead still. Somewhere behind the painted screen an old actor shouts \"Hao!\"",
			"The boards remember a thousand performances. His is not the best, but it is the most sincere."]},
	"hot_spring": {"n": "Hot spring", "verb": "Soak in the hot spring", "clip": "soak", "dur": 7.0, "at": "on", "rise": -0.42, "pair": true, "fx": "steam", "effect": "sleep", "comp": "soak", "clear": 1,
		"lines": ["The water is hot enough to make him gasp, and then every ache of the road lets go at once.",
			"Steam, stars, and the drip of the bamboo spout. Yue Ling says this is the only medicine she has ever been jealous of.",
			"They soak until their fingers wrinkle. Yue Ling says healers know exactly how long that is. She does not tell him.",
			"A monkey on the rocks watches them very seriously, then gets in at the far side."]},
	"millstone": {"n": "Millstone", "verb": "Push the millstone round", "clip": "push", "dur": 6.6, "at": "circle", "fx": "flour", "effect": "train", "comp": "laugh", "clear": 1,
		"lines": ["Round and round, and the grain goes in grey and comes out white. A donkey would do it faster. A donkey would not do it better.",
			"Three turns and his legs remember the sect's steps. Ten turns and they remember why he left them.",
			"Yue Ling sweeps the flour into the sack as it comes and says they could open a noodle stall.",
			"The miller's widow will find her week's flour ground in the morning, and wonder."]},
	"archery": {"n": "Archery butts", "verb": "Shoot an arrow", "clip": "archery", "dur": 2.6, "at": "face", "hold": "bow", "fx": "arrow", "effect": "train", "comp": "clap", "clear": 1,
		"lines": ["THOK. A finger's width from the gold. Yue Ling says that counts.",
			"The bow is an old horn bow, stiffer than it looks. The arrow goes exactly where he looked, which is a lesson in itself.",
			"Gold! Yue Ling claps, and then asks him to do it again so she can watch properly.",
			"Somebody has carved a tally of hits into the rack. He adds one, small, at the bottom."]},
	"lantern_green": {"n": "Lantern green", "verb": "Dance under the lanterns", "clip": "dance", "dur": 8.0, "at": "on", "pair": true, "fx": "petals", "effect": "luck", "comp": "dance", "clear": 1,
		"lines": ["Nobody plays any music. They dance anyway, under the red lanterns, and the lanterns sway as if somebody did.",
			"He steps on her foot twice. She steps on his three times, on purpose, to stay ahead.",
			"Yue Ling's sleeves go up like wings and come down like rain. He forgets his own feet watching.",
			"The village children watch from the edge of the green and then, one by one, join in."]},
	"kite": {"n": "Kite post", "verb": "Fly a kite", "clip": "kite", "dur": 7.0, "at": "face", "hold": "reel", "effect": "luck", "comp": "laugh", "clear": 0,
		"lines": ["The red swallow kite goes up on the first gust and keeps going until it is a spark against the cloud.",
			"It dips, it dives, he hauls, and it climbs again. Yue Ling says the kite flies better than he does. It is true.",
			"Somebody tied a wish to the kite's tail before him. He lets the string run out so it reaches heaven.",
			"For a while there is nothing in the world but the pull of the string and the shape against the sky."]},
	"armillary": {"n": "Armillary sphere", "verb": "Lie back and watch the stars", "clip": "stargaze", "dur": 7.0, "at": "before", "off": 1.05, "pair": true, "fx": "stars", "effect": "qi", "comp": "stargaze", "clear": 0,
		"lines": ["They lie back in the grass by the bronze rings and name the stars. Hers are better names than the astronomers'.",
			"The Weaver and the Herdboy, either side of the Silver River. Yue Ling says she has met them and they are very nice.",
			"A shooting star. Neither of them says what they wished for, and both of them smile.",
			"The rings of the sphere turn very slowly, as if they were watching the sky too."]},
	"sky_lantern": {"n": "Sky lanterns", "verb": "Let a sky lantern go", "clip": "release", "dur": 3.2, "at": "face", "hold": "sky_lantern", "fx": "sky_lantern", "effect": "luck", "comp": "release", "comp_hold": "sky_lantern", "clear": 0,
		"lines": ["Two lanterns go up together and drift apart, and come together again higher up, and are lost among the stars.",
			"He writes a wish on the paper. She writes one on hers. They promise not to read each other's, and both do.",
			"The lantern rises so slowly it seems to be thinking about it. Then the wind takes it east, towards the sea.",
			"Up and up, a warm orange dot. Somebody far away will look up and see it and not know it was theirs."]},
	"river_lantern": {"n": "Lotus lanterns", "verb": "Set a lantern on the water", "clip": "float_lantern", "dur": 3.0, "at": "face", "fx": "float", "effect": "qi", "comp": "float_lantern", "clear": 0,
		"lines": ["The little lotus lantern turns once in the current, as if bowing, and floats away downstream.",
			"Two lanterns on the dark water, his and hers, drifting side by side for as long as they can see them.",
			"For the dead, the river lanterns. Yue Ling sets hers out for somebody whose name she cannot remember, and cries a little, and does not say why.",
			"The candle gutters, steadies, and goes on. That is all anybody can ask of a candle."]},
	"calligraphy": {"n": "Writing table", "verb": "Write a line of verse", "clip": "write", "dur": 5.0, "at": "face", "hold": "brush", "fx": "ink", "effect": "lore", "comp": "think", "clear": 0,
		"lines": ["\"The road is long; good company shortens it.\" His hand is a sweeper's, but the characters stand up straight.",
			"He writes her name. She takes the brush and writes his underneath, better, and laughs at his face.",
			"One character, written in one breath: home. The ink is still wet when the wind dries it.",
			"\"Mountains do not meet; people do.\" Yue Ling says she will keep that one."]},
	"flute_rock": {"n": "Flute on a rock", "verb": "Play the bamboo flute", "clip": "play_flute", "dur": 6.0, "at": "face", "hold": "flute", "fx": "notes", "effect": "qi", "comp": "dance", "clear": 0,
		"lines": ["A thin, wavering tune, and Yue Ling dances to it as if it were a court orchestra.",
			"Somebody left this flute here for anybody passing to play. He plays the one tune he knows, twice.",
			"The notes go out over the water. A heron lifts its head, decides they are no threat, and goes back to fishing.",
			"Yue Ling takes the flute from him and plays a tune so old the stones seem to know it. She does not know where she learned it."]},
	# ---- furniture (the building draws it; see Architecture._furnish)
	"altar": {"n": "Altar", "verb": "Pray at the altar", "clip": "pray", "dur": 4.5, "at": "face", "fx": "smoke", "effect": "qi", "comp": "pray",
		"lines": ["Incense for the ancestors of the house. The smoke bends towards him and away.", "He bows three times and the candle flames bow back.", "A quiet room, and a quieter heart."]},
	"statue": {"n": "Statue", "verb": "Bow to the founder", "clip": "bow", "dur": 2.0, "at": "face", "fx": "glow", "effect": "lore", "comp": "bow",
		"lines": ["The founder's bronze face is calm. It has seen worse days than this.", "A respectful bow. The statue, for once, seems to approve.", "Somebody keeps the statue polished, all but the nose, which is polished by luck-seekers."]},
	"cushion": {"n": "Meditation cushion", "verb": "Sit and meditate", "clip": "meditate", "dur": 6.0, "at": "on", "fx": "qi", "effect": "qi", "comp": "watch",
		"lines": ["Breathe in for four, out for six. The qi settles like silt in a pool.", "His root hums in the stillness.", "Yue Ling sits a little way off and is quiet for once."]},
	"scroll": {"n": "Calligraphy", "verb": "Look at the calligraphy", "clip": "think", "dur": 2.4, "at": "face", "fx": "", "effect": "lore", "comp": "think",
		"lines": ["\"Water is soft and wins.\" The last stroke runs off the paper.", "One character, written in one breath: Dao.", "The brushwork is wild. The poem is about patience."]},
	"bookshelf": {"n": "Bookshelf", "verb": "Read a while", "clip": "read", "dur": 5.0, "at": "face", "hold": "book", "fx": "", "effect": "lore", "comp": "read", "comp_hold": "book",
		"lines": ["A treatise on the five phases with somebody's arguments in the margins.", "A book of ghost stories. He reads one too many.", "An old almanac: the auspicious days are all in the past."]},
	"shelf": {"n": "Shelf", "verb": "Look over the shelf", "clip": "touch", "dur": 2.2, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Jars of pickles, salt, dried mushrooms, and a jar labelled DO NOT.", "Everything here has been mended at least once.", "A child's carved horse, put up high out of reach."]},
	"table": {"n": "Table", "verb": "Pour a cup of tea", "clip": "drink", "dur": 2.6, "at": "face", "hold": "cup", "fx": "steam", "effect": "rest", "comp": "drink", "comp_hold": "cup",
		"lines": ["Tea in a chipped cup, and very welcome.", "The table has a ring for every cup ever set on it.", "Sit, rest, drink: the oldest courtesy."]},
	"desk": {"n": "Writing desk", "verb": "Read the papers", "clip": "read", "dur": 4.5, "at": "face", "hold": "book", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Accounts, letters, a poem crossed out three times.", "Somebody practises the character for 'eternity' here, over and over.", "Ink still wet. Whoever writes here has just stepped out."]},
	"counter": {"n": "Counter", "verb": "Knock for service", "clip": "touch", "dur": 2.0, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Knock knock. \"Coming!\" says somebody, and doesn't.", "The counter is worn into a dip where a thousand elbows have leaned.", "A cat asleep on the ledger raises one eyelid."]},
	"stool": {"n": "Stool", "verb": "Sit a moment", "clip": "sit_bench", "dur": 4.0, "at": "seat", "off": 0.0, "fx": "", "effect": "rest", "comp": "watch",
		"lines": ["A moment off his feet.", "The stool wobbles. He finds the one way it doesn't.", "Sitting, he notices the room properly for the first time."]},
	"cauldron": {"n": "Cauldron", "verb": "Stir the cauldron", "clip": "stir", "dur": 4.5, "at": "face", "hold": "ladle", "fx": "steam", "effect": "qi", "comp": "watch",
		"lines": ["Clockwise nine times, counter-clockwise nine. The brew turns gold.", "It smells of ginseng and something better not asked about.", "Yue Ling corrects his stirring. He was doing it fine."]},
	"herbs": {"n": "Drying herbs", "verb": "Sort the herbs", "clip": "gather", "dur": 2.8, "at": "face", "fx": "sparkle", "effect": "herb", "comp": "gather",
		"lines": ["Mugwort, angelica, a sprig of something that glows faintly.", "The good leaves in one basket, the bitter in another.", "Yue Ling tells him the names. He forgets half of them at once."]},
	"hearth": {"n": "Hearth", "verb": "Warm your hands", "clip": "warm", "dur": 4.5, "at": "face", "fx": "embers", "effect": "rest", "comp": "warm",
		"lines": ["The embers glow up as if they were glad of him.", "A hearth is a house's heart. This one beats slow and warm.", "He feeds it a log. It thanks him in sparks."]},
	"stove": {"n": "Stove", "verb": "Cook something", "clip": "stir", "dur": 4.5, "at": "face", "hold": "ladle", "fx": "steam", "effect": "drink", "comp": "watch",
		"lines": ["Congee with ginger: the best medicine in the world.", "He burns the first batch and eats the second.", "Yue Ling says it needs salt. It always needs salt."]},
	"anvil": {"n": "Anvil", "verb": "Work the anvil", "clip": "hammer", "dur": 4.0, "at": "face", "hold": "hammer", "fx": "sparks", "effect": "train", "comp": "watch",
		"lines": ["Clang, clang, clang. The iron turns from red to orange to a hoe.", "Hammer, turn, hammer: Smith Tie would only wince a little.", "The rhythm gets into his arms and he finds he cannot stop."]},
	"rack": {"n": "Weapon rack", "verb": "Practise a form", "clip": "attack", "dur": 1.6, "at": "face", "fx": "", "effect": "train", "comp": "watch",
		"lines": ["A spear form, borrowed from the rack: thrust, sweep, guard.", "He puts the halberd back. Swords suit him better.", "The practice sword is heavy and blunt and honest."]},
	"barrel": {"n": "Barrel", "verb": "Have a taste", "clip": "drink", "dur": 2.6, "at": "face", "hold": "dipper", "fx": "", "effect": "drink", "comp": "laugh",
		"lines": ["Rice wine, young and fierce. He coughs.", "Plum wine! Somebody's private store, by the dust on the lid.", "Water, cool and sweet. Rather a disappointment."]},
	"bed": {"n": "Bed", "verb": "Rest a while", "clip": "doze", "dur": 6.0, "at": "seat", "off": 0.5, "fx": "zzz", "effect": "sleep", "comp": "watch",
		"lines": ["He means to rest his eyes a moment. He wakes an hour later, much better.", "A real bed, after so many nights on the road.", "Yue Ling lets him sleep, and keeps watch."]},
	"cabinet": {"n": "Cabinet", "verb": "Look in the cabinet", "clip": "touch", "dur": 2.2, "at": "face", "fx": "", "effect": "find", "comp": "watch",
		"lines": ["Bolts of silk, folded with care.", "A box of letters tied with red string. He puts it back unread.", "Somebody's winter clothes, smelling of camphor."]},
	"loom": {"n": "Loom", "verb": "Weave a few rows", "clip": "weave", "dur": 5.0, "at": "before", "off": 0.78, "fx": "", "effect": "qi", "comp": "watch",
		"lines": ["Shuttle, beater, treadle. The pattern grows by a finger's width.", "He weaves a mistake into it. The weaver will find it and laugh.", "The Weaver of the Star River would weave faster. Not much better."]},
	"lantern": {"n": "Lantern", "verb": "Trim the lantern", "clip": "touch", "dur": 2.0, "at": "face", "fx": "light", "effect": "lore", "comp": "watch",
		"lines": ["The wick trimmed, the flame stands up straight.", "Paper and bamboo and a little light: enough.", "A moth leaves in a huff."]},
	"tub": {"n": "Cedar bath", "verb": "Soak in the bath", "clip": "soak", "dur": 6.0, "at": "on", "rise": 0.12, "fx": "steam", "effect": "sleep", "comp": "watch",
		"lines": ["Hot cedar and steam. Every ache the road ever gave him floats up and away.", "The water smells of pine and something floral the Founder must have liked.", "He soaks until Yue Ling knocks on the screen and asks if he has drowned."]},
	"nest": {"n": "Nest", "verb": "Look into the nest", "clip": "touch", "dur": 2.2, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Woven of cloud-silk and feathers, and still warm.", "A Feathered Folk nest, swept clean and waiting.", "Three blue feathers left as a gift. He leaves them."]},
	# ---- the Hollow Hills release (Part XX): what is done under the ground (caves.gd stands these in
	# niches of the cave walls; cavethings.gd builds them, the rock of them in voxels), each on a clip of
	# its own
	"ore_vein": {"n": "Seam of ore", "verb": "Swing a pick at the seam", "clip": "mine", "dur": 4.8, "at": "face", "hold": "pickaxe", "fx": "sparks", "effect": "ore", "comp": "watch",
		"lines": ["Chank. Chank. The rock gives up a piece the size of a fist, heavy for its size and bright where it broke.", "Whoever worked this seam last left the pick leaning on it, as if stepping out for a moment. The handle is polished by hands.", "Yue Ling holds the lamp and says he swings it like a broom. The seam does not seem to mind."]},
	"drip_pool": {"n": "Drip pool", "verb": "Wash in the drip pool", "clip": "wash", "dur": 3.2, "at": "face", "fx": "splash", "effect": "rest", "comp": "wash",
		"lines": ["One drop every nine heartbeats, for longer than the sect has stood. The pool it has filled is so clear the bottom looks dry.", "The water is cold enough to stop the breath, and tastes of stone and of nothing else at all.", "He washes the road off his face and it comes away grey. Yue Ling says there was a person under there after all."]},
	"cave_painting": {"n": "Painting on the rock", "verb": "Follow the painting with a finger", "clip": "trace", "dur": 4.0, "at": "face", "fx": "glow", "effect": "lore", "comp": "watch",
		"lines": ["Red ochre, older than writing: deer, a river, people holding hands in a row. One of them is waving.", "A hand, stencilled in red: somebody held it to the rock and blew paint round it. His own fits it exactly.", "Hunters, and a great beast, and over them a sun with nine little suns beside it. Nobody has seen that sky for a long time."]},
	"glow_shrooms": {"n": "Foxfire mushrooms", "verb": "Pick the foxfire caps", "clip": "gather", "dur": 2.8, "at": "face", "fx": "sparkle", "effect": "herb", "comp": "gather",
		"lines": ["They go on glowing in the hand, a cold green light with no warmth in it at all.", "He leaves the small ones. Down here a mushroom may be a hundred years getting to the size of a thumb.", "Yue Ling says they are good for fevers and bad for soup. She does not say how she knows about the soup."]},
	"crystal": {"n": "Spirit crystals", "verb": "Lay a hand on the crystals", "clip": "touch", "dur": 2.4, "at": "face", "fx": "glow", "effect": "qi", "comp": "watch",
		"lines": ["The crystals hum under his palm, one note, very low: the note the hill hums when nobody is in it.", "Each one took ten thousand years to grow a finger's length. He takes his hand away rather carefully.", "The light in them moves towards his hand like fish to the side of a pond."]},
	"echo_stone": {"n": "Ringing stone", "verb": "Knock and listen", "clip": "knock", "dur": 2.8, "at": "face", "fx": "ring", "effect": "lore", "comp": "watch",
		"lines": ["Three knocks, and the pillar rings like a bell under water. Something a long way down rings back, a beat late.", "Stone chimes were the first music, they say: somebody knocked on a cave to see if it was hollow, and it sang.", "He lays his ear to it. The hill is full of small sounds: water, settling, and far off something that might be digging."]},
	"squeeze": {"n": "Squeeze in the rock", "verb": "Sidle into the crack", "clip": "squeeze", "dur": 4.8, "at": "face", "fx": "dust", "effect": "find", "comp": "laugh",
		"lines": ["Breath out, belly in, one ear to the rock. At the far end there is a pocket the size of a cupboard, and somebody has been here before.", "The crack takes him as far as the shoulder and then thinks better of it. He comes out backwards, grey to the eyebrows.", "Yue Ling says she could go through there easily. She does not offer to."]},
	"stream_bank": {"n": "Underground stream", "verb": "Pan the gravel", "clip": "pan", "dur": 4.8, "at": "face", "hold": "pan", "fx": "splash", "effect": "luck", "comp": "watch",
		"lines": ["Swirl, tip, swirl. At the bottom of the pan, among the black sand, three flakes the colour of late sun.", "The stream comes out of the dark and goes back into it, and has never once seen the sky. It sounds perfectly content.", "A blind white fish noses the pan, finds it is not food, and goes away without hurrying."]},
	"fossil": {"n": "Shell in the stone", "verb": "Chip round the shell", "clip": "carve", "dur": 3.6, "at": "face", "hold": "chisel", "fx": "dust", "effect": "lore", "comp": "watch",
		"lines": ["A coiled shell as wide as a cartwheel, turned to stone, a week's walk under a mountain. This was the bottom of a sea once.", "\"The sea becomes mulberry fields,\" the old saying goes. Here is the sea, still in the hill, keeping its shape.", "He frees one more turn of the spiral and stops. It has waited this long; the rest can wait for somebody patient."]},
	"dig_spot": {"n": "Soft earth", "verb": "Dig", "clip": "dig", "dur": 4.4, "at": "face", "hold": "spade", "fx": "dust", "effect": "find", "comp": "watch",
		"lines": ["Somebody buried something here in a hurry and marked the place with three stones. Whoever it was never came back for it.", "A spade's depth down: a clay jar, and in the jar, wrapped in oiled silk, what a family thought worth hiding.", "He fills the hole in again afterwards and treads it flat. A hole in a cave floor is a mean thing to leave for the next lamp."]},
	"bat_roost": {"n": "Bat roost", "verb": "Peer up at the roost", "clip": "peer", "dur": 3.2, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Hundreds of them, hung up like dark fruit, shifting and muttering in their sleep. One opens an eye and closes it again.", "The word for bat sounds like the word for good fortune, which is why they are carved on every door. These ones have not been told.", "At dusk they will pour out of the hill like smoke. For now it is the middle of their night, and he keeps his voice down."]},
	"miner_niche": {"n": "Lamp niche", "verb": "Hang a lamp in the niche", "clip": "hang", "dur": 3.0, "at": "face", "fx": "light", "effect": "lore", "comp": "watch",
		"lines": ["A hook, a soot mark above it the shape of a flame, and under it a tally scratched in the rock: somebody's shifts, in fives.", "The lamp takes, and the dark goes back about as far as a man can throw a stone. It has been a long time since this gallery was lit.", "Miners leave a light burning for the one who comes after. He trims the wick, as one should."]},
	"cave_weiqi": {"n": "Stone weiqi board", "verb": "Watch the game", "clip": "think", "dur": 2.4, "at": "face", "fx": "", "effect": "lore", "comp": "think",
		"lines": ["Black to play. It has been Black to play for some time: there is moss on the stones.", "He looks for only a moment. When he looks up, the lamp has burned a finger lower than it should have.", "Two cups beside the board, both empty, both dusty. Whoever was playing did not finish, or has not finished yet."]},
	# ---- and in the houses, which have twice the room now (rooms.gd): twelve new pieces of furniture
	"chest": {"n": "Camphor chest", "verb": "Open the chest", "clip": "open_chest", "dur": 3.0, "at": "face", "fx": "", "effect": "find", "comp": "watch",
		"lines": ["Winter quilts, a wedding robe folded in paper, and under them a string of cash somebody saved a coin at a time.", "The lid comes up on a smell of camphor and thirty winters. He puts everything back the way it lay.", "A child's first shoes, kept. He shuts the lid quietly."]},
	"mirror": {"n": "Bronze mirror", "verb": "Tidy your hair at the mirror", "clip": "comb", "dur": 3.0, "at": "face", "hold": "comb", "fx": "glow", "effect": "luck", "comp": "laugh",
		"lines": ["The bronze shows him a little yellower and a good deal more travelled than he remembers being.", "Three strokes of the comb and the topknot sits straight for the first time in a month.", "Yue Ling watches him fuss and says the road has not cured him of vanity. He says it is respect for the mirror."]},
	"mortar": {"n": "Stone mortar", "verb": "Pound the mortar", "clip": "pound", "dur": 4.0, "at": "face", "hold": "pestle", "fx": "dust", "effect": "herb", "comp": "watch",
		"lines": ["Thump, thump, thump: the sound of every kitchen and every pharmacy in the land, and of the rabbit on the moon.", "Dried root to coarse meal to powder fine as flour. His shoulders will know about it tomorrow.", "Yue Ling says the Jade Rabbit keeps better time. The Jade Rabbit has had longer to practise."]},
	"spinning_wheel": {"n": "Spinning wheel", "verb": "Spin a length of thread", "clip": "spin", "dur": 4.8, "at": "before", "off": 0.55, "fx": "", "effect": "qi", "comp": "watch",
		"lines": ["The wheel hums, the thread runs out between finger and thumb, and for a while there is nothing else in the world.", "His thread comes out thick and thin by turns, like a road through hills. The spinner will smile and use it for a hem.", "One hand turns, the other draws. It is harder than the sword and nobody ever wrote a manual for it."]},
	"abacus": {"n": "Abacus", "verb": "Tot up a column", "clip": "count", "dur": 4.8, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Click, click, click. The ledger says the house is owed nine strings of cash by a man who died in the spring.", "He adds the column three times and gets three sums. The beads are not at fault.", "Rice, salt, lamp oil, a doctor's fee, a red envelope for a wedding: a year of somebody's life, in a column."]},
	"cradle": {"n": "Cradle", "verb": "Rock the cradle", "clip": "rock", "dur": 4.8, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Empty just now, and still warm. He rocks it anyway, and finds he is humming.", "A tiger-head cap on the rail, to frighten off whatever comes for babies in the night. It would frighten him.", "Granny Wen rocked one like this with her foot while she shelled peas. He remembers the sound of the peas."]},
	"wine_jar": {"n": "Wine jar", "verb": "Pour a measure", "clip": "pour", "dur": 3.0, "at": "face", "hold": "jug", "fx": "", "effect": "drink", "comp": "laugh",
		"lines": ["Yellow wine, three winters old, laid down the year somebody's daughter was born.", "He pours a measure and leaves a coin on the lid, which is the custom, and a good one.", "The jar is sealed with clay and red paper, and the paper says: for the day she marries. He pours from the one beside it."]},
	"clothes_stand": {"n": "Clothes stand", "verb": "Hang up your cloak a while", "clip": "hang", "dur": 3.0, "at": "face", "fx": "", "effect": "rest", "comp": "watch",
		"lines": ["The cloak comes off his shoulders and takes the last three days of road with it.", "A robe hung up properly is half way to mended, Granny Wen used to say. She meant people too.", "There is a hat on the other horn that has not been worn for a long while. He does not move it."]},
	"washstand": {"n": "Washstand", "verb": "Wash your face", "clip": "wash", "dur": 3.2, "at": "face", "fx": "splash", "effect": "rest", "comp": "watch",
		"lines": ["Cold water, a rough towel, and the world is a degree more possible.", "Somebody fills this basin every morning for whoever comes. He pours it out on the plants afterwards, as a guest should.", "He comes up out of the towel to find Yue Ling has tied his sleeves in a knot behind him."]},
	"workbench": {"n": "Carver's bench", "verb": "Carve a little", "clip": "carve", "dur": 3.6, "at": "face", "hold": "chisel", "fx": "dust", "effect": "train", "comp": "watch",
		"lines": ["The figure in the vice is half a horse and half still a block. He takes off a curl of wood where the neck will be, and no more.", "Push, turn, blow the dust away, look. The blade goes where the grain lets it; arguing with the grain is how fingers are lost.", "Cook Ding's knife and a carver's chisel are the same tool. He is not Cook Ding yet."]},
	"wall_panel": {"n": "Hollow panel", "verb": "Knock on the panel", "clip": "knock", "dur": 2.8, "at": "face", "fx": "dust", "effect": "find", "comp": "watch",
		"lines": ["Knock, knock, knock: and one of the three sounds like a drum. Behind it, a space a hand deep, and in the space, a purse.", "Every old house has a board that sounds wrong. Most of them are only where the carpenter ran short of timber.", "He listens with his ear to the wood. Mice, and behind the mice, nothing; and behind the nothing, something."]},
	"grain_bin": {"n": "Grain bin", "verb": "Look into the grain bin", "clip": "peer", "dur": 3.2, "at": "face", "fx": "", "effect": "lore", "comp": "watch",
		"lines": ["Full to the second hoop. A house with its bin this full after midwinter has had a good year, and knows it.", "Millet, and a line scratched inside the bin for every harvest. The lines go up a long way.", "A mouse looks back at him from the grain, weighs the odds, and goes on eating."]},
	"window": {"n": "Lattice window", "verb": "Stretch at the window", "clip": "stretch", "dur": 3.2, "at": "face", "fx": "", "effect": "rest", "comp": "watch",
		"lines": ["Up on his toes, fingers laced, every joint from heel to wrist saying its name. Outside, somebody is beating a quilt.", "Roofs, smoke, a kite, the hills. From up here the town looks as if somebody had thought about it.", "He yawns until his jaw cracks. Down in the lane a dog looks up, yawns too, and lies down again."]},
}

## The furniture the game makes usable: the kind of thing it is (KINDS) by the kind of furniture
## (MapGen building props).  The pieces that fill a tile are used from beside them; the rest (on a
## floor anyone walks over: a cushion, a stool, a hanging scroll, a lantern, drying herbs, a statue)
## are used by facing them and never stand in anyone's way.
const FURNITURE := {"altar": "altar", "statue": "statue", "cushion": "cushion", "scroll": "scroll", "bookshelf": "bookshelf", "shelf": "shelf",
	"table": "table", "desk": "desk", "counter": "counter", "stool": "stool", "cauldron": "cauldron", "herbs": "herbs", "hearth": "hearth",
	"stove": "stove", "anvil": "anvil", "rack": "rack", "barrel": "barrel", "bed": "bed", "cabinet": "cabinet", "loom": "loom",
	"lantern": "lantern", "nest": "nest", "tub": "tub",
	# the Hollow Hills release (rooms.gd)
	"chest": "chest", "mirror": "mirror", "mortar": "mortar", "spinning_wheel": "spinning_wheel", "abacus": "abacus", "cradle": "cradle", "wine_jar": "wine_jar",
	"clothes_stand": "clothes_stand", "washstand": "washstand", "workbench": "workbench", "wall_panel": "wall_panel", "grain_bin": "grain_bin", "window": "window"}

## The outdoor things to look for in a region by its theme (the first found a place get one); where
## a theme is not listed, the region takes the common list turned round by its own name.
const COMMON := ["bench", "shrine", "well", "herb_patch", "stele", "wish_tree", "campfire", "lantern_st", "chimes", "tea", "qin", "swing", "fishing", "koi", "lion", "weiqi", "bell", "drum", "stones", "broom"]
const THEMES := {
	"sect": ["bell", "broom", "stones", "qin", "weiqi", "lantern_st", "koi", "bench"],
	"mountain": ["shrine", "bench", "well", "herb_patch", "campfire", "stele"],
	"bamboo": ["qin", "tea", "chimes", "bench", "fishing", "herb_patch"],
	"marsh": ["fishing", "koi", "herb_patch", "shrine", "campfire", "bench"],
	"frost": ["campfire", "shrine", "fishing", "stele", "stones", "bench"],
	"thunder": ["drum", "stele", "shrine", "campfire", "stones", "bench"],
	"palace": ["lion", "lantern_st", "bell", "weiqi", "koi", "bench"],
	"garden": ["koi", "swing", "tea", "wish_tree", "qin", "bench"],
	"village": ["well", "swing", "wish_tree", "bench", "broom", "fishing", "lion"],
	"grave": ["shrine", "lantern_st", "stele", "bell", "chimes", "bench"],
	"forge": ["stones", "campfire", "well", "drum", "bench", "stele"],
	"maple": ["broom", "tea", "qin", "shrine", "bench", "fishing"],
	"terraces": ["tea", "well", "bench", "shrine", "herb_patch", "swing"],
	"springs": ["well", "fishing", "tea", "bench", "shrine", "koi"],
	"silk": ["swing", "tea", "chimes", "wish_tree", "bench", "well"],
	"millet": ["well", "broom", "bench", "shrine", "campfire", "swing"],
	# the realms past the first
	"volcano": ["stones", "stele", "shrine", "drum", "campfire", "bench"],
	"abyss": ["stele", "shrine", "bell", "lantern_st", "stones", "bench"],
	"void": ["stele", "shrine", "lantern_st", "chimes", "weiqi", "bench"],
	"celestial": ["bell", "lion", "lantern_st", "weiqi", "qin", "chimes"],
	"mirror": ["koi", "fishing", "qin", "tea", "chimes", "bench"],
	"time": ["stele", "bell", "weiqi", "shrine", "lantern_st", "bench"],
	"origin": ["stele", "shrine", "herb_patch", "wish_tree", "well", "bench"],
	"cloudsea": ["chimes", "qin", "tea", "lantern_st", "shrine", "bench"],
	"court": ["lion", "lantern_st", "bell", "weiqi", "drum", "bench"],
	"dunes": ["well", "campfire", "shrine", "stele", "stones", "bench"],
	"fungal": ["herb_patch", "campfire", "lantern_st", "shrine", "stele", "bench"],
	"aurora": ["campfire", "chimes", "shrine", "stele", "fishing", "bench"],
	"chaos": ["stele", "shrine", "stones", "drum", "campfire", "bench"],
	"karst": ["fishing", "tea", "qin", "herb_patch", "shrine", "bench"],
	"wheel": ["lantern_st", "bell", "shrine", "stele", "drum", "chimes"],
	"loom": ["chimes", "swing", "tea", "wish_tree", "well", "bench"],
	"starferry": ["lantern_st", "fishing", "wish_tree", "chimes", "shrine", "bench"],
	"magpie": ["wish_tree", "lantern_st", "chimes", "swing", "koi", "bench"],
	"starpalace": ["lantern_st", "bell", "lion", "weiqi", "chimes", "bench"],
	"jasper": ["koi", "tea", "qin", "lion", "chimes", "bench"],
	"yanggu": ["campfire", "drum", "shrine", "stele", "well", "bench"],
	"fusang": ["wish_tree", "shrine", "drum", "campfire", "stele", "bench"],
	"guanghan": ["lantern_st", "qin", "chimes", "wish_tree", "tea", "bench"],
	"longmen": ["fishing", "koi", "stele", "drum", "shrine", "bench"],
	"drowned": ["shrine", "stele", "lantern_st", "bell", "fishing", "bench"],
	"tushan": ["wish_tree", "lantern_st", "tea", "swing", "shrine", "bench"],
	"buzhou": ["stele", "shrine", "stones", "campfire", "drum", "bench"],
	"juntian": ["bell", "drum", "qin", "chimes", "lion", "bench"],
	"changhe": ["lion", "bell", "lantern_st", "drum", "stele", "bench"],
	"ninesprings": ["lantern_st", "well", "shrine", "stele", "chimes", "bench"],
	"youdu": ["lantern_st", "bell", "shrine", "stele", "drum", "lion"],
	"penglai": ["tea", "qin", "koi", "fishing", "herb_patch", "bench"],
	"fangzhang": ["herb_patch", "tea", "qin", "shrine", "fishing", "bench"],
	"yingzhou": ["koi", "fishing", "tea", "chimes", "herb_patch", "bench"],
	"guixu": ["stele", "shrine", "bell", "lantern_st", "fishing", "bench"],
}
## The bigger things of the Lotus release (structures.gd) a region looks for by its theme (or its own
## id), placed after the six above; where neither is listed, LOTUS_COMMON.
const LOTUS := {
	"sect": ["stage", "archery", "calligraphy"], "mountain": ["stage", "watchtower", "pavilion", "kite"], "bamboo": ["flute_rock", "pavilion", "calligraphy"],
	"marsh": ["river_lantern", "watchtower", "flute_rock"], "frost": ["hot_spring", "watchtower", "armillary"], "thunder": ["watchtower", "archery", "kite"],
	"palace": ["stage", "lantern_green", "pavilion"], "garden": ["pavilion", "lantern_green", "kite"], "village": ["millstone", "lantern_green", "kite"],
	"grave": ["sky_lantern", "calligraphy", "pavilion"], "forge": ["millstone", "archery", "watchtower"], "maple": ["pavilion", "sky_lantern", "calligraphy"],
	"terraces": ["millstone", "pavilion", "kite"], "springs": ["river_lantern", "hot_spring", "sky_lantern"], "silk": ["lantern_green", "millstone", "pavilion"],
	"millet": ["millstone", "kite", "watchtower"], "volcano": ["hot_spring", "watchtower", "archery"], "abyss": ["river_lantern", "armillary", "pavilion"],
	"void": ["armillary", "sky_lantern", "watchtower"], "celestial": ["stage", "armillary", "pavilion"], "mirror": ["river_lantern", "flute_rock", "pavilion"],
	"time": ["armillary", "calligraphy", "sky_lantern"], "origin": ["armillary", "pavilion", "flute_rock"], "cloudsea": ["kite", "pavilion", "flute_rock"],
	"court": ["stage", "calligraphy", "archery"], "dunes": ["armillary", "watchtower", "kite"], "fungal": ["hot_spring", "lantern_green", "flute_rock"],
	"aurora": ["hot_spring", "armillary", "archery"], "chaos": ["armillary", "watchtower", "stage"], "karst": ["flute_rock", "pavilion", "river_lantern"],
	"wheel": ["sky_lantern", "river_lantern", "calligraphy"], "loom": ["lantern_green", "kite", "pavilion"], "starferry": ["river_lantern", "armillary", "sky_lantern"],
	"magpie": ["lantern_green", "sky_lantern", "pavilion"], "starpalace": ["armillary", "stage", "calligraphy"], "jasper": ["pavilion", "flute_rock", "hot_spring"],
	"yanggu": ["stage", "millstone", "lantern_green"], "fusang": ["sky_lantern", "kite", "archery"], "guanghan": ["armillary", "pavilion", "flute_rock"],
	"longmen": ["river_lantern", "watchtower", "stage"], "drowned": ["river_lantern", "watchtower", "millstone"], "tushan": ["lantern_green", "calligraphy", "stage"],
	"buzhou": ["watchtower", "armillary", "archery"], "juntian": ["kite", "pavilion", "stage"], "changhe": ["pavilion", "lantern_green", "calligraphy"],
	"ninesprings": ["hot_spring", "river_lantern", "sky_lantern"], "youdu": ["sky_lantern", "stage", "calligraphy"], "penglai": ["pavilion", "flute_rock", "kite"],
	"fangzhang": ["hot_spring", "calligraphy", "pavilion"], "yingzhou": ["river_lantern", "flute_rock", "armillary"], "guixu": ["watchtower", "sky_lantern", "river_lantern"],
}
const LOTUS_COMMON := ["pavilion", "kite", "sky_lantern"]
## outdoor things that stand in the water by the bank; the rest stand on the forest edge
const WATER_KINDS := ["fishing", "koi", "river_lantern"]
## how many outdoor things a region has: six of its theme's, then up to three of the bigger ones
const PER_REGION := 6
const LOTUS_PER := 3
## (a region with fewer good tiles than this also takes the corners of its forest)
const FEW_TILES := 18

## the clips played once (the rest loop for as long as the thing takes)
const ONCE := ["drink", "strike", "gather", "lift", "toss", "touch", "bow", "think", "attack", "offer", "archery", "release", "float_lantern", "clap", "wave", "laugh",
	# the Hollow Hills release
	"wash", "open_chest", "stretch", "knock", "pour", "peer", "hang"]
## what the hero holds for a clip that needs something in his hand (built in held(), the Lotus
## release's in Structures.held; the bow goes in the left hand)
const HELD := ["dipper", "cup", "rod", "broom", "hammer", "ladle", "book", "stone_lock", "flute", "reel", "sky_lantern", "brush", "bow",
	# the Hollow Hills release (cavethings.gd)
	"pickaxe", "spade", "pan", "chisel", "pestle", "jug", "comb"]
const LEFT_HAND := ["bow"]
## the effects (use())
const EFFECTS := ["rest", "drink", "qi", "lore", "fish", "luck", "herb", "train", "find", "sleep", "ore"]
## how the things answer while used (drawn by World._prop_fx; the swing's is the swing going)
const FX := ["splash", "smoke", "ring", "boom", "notes", "ripple", "ribbon", "glow", "sparkle", "sparks", "embers", "dust",
	"leaves", "steam", "chime", "light", "koi", "qi", "zzz", "swing",
	# the Lotus release
	"blade", "flour", "arrow", "petals", "kite", "stars", "sky_lantern", "float", "ink"]
## where a thing is done ("at"): see KINDS; the Lotus release adds "circle" (walked round: the
## millstone) and "climb" (up a ladder to the top and down again: the watchtower), and "stage" (up
## on its boards)
const AT := ["face", "seat", "before", "on", "circle", "climb", "stage"]

static func kind_of(e: Dictionary) -> Dictionary:
	return KINDS.get(str(e.get("prop", "")), {})

## What a thing is called where it stands (a memory's place has a name of its own, bonds.gd).
static func name_of(e: Dictionary) -> String:
	return str(e.get("n", kind_of(e).get("n", "")))

## A line of what is said about doing it: a different one each time.
static func line_for(e: Dictionary, n: int) -> String:
	var lines: Array = kind_of(e).get("lines", [])
	if lines.is_empty():
		return ""
	return str(lines[(n + absi(hash(str(e.id)))) % lines.size()])

# ---------------------------------------------------------------- placement

## The kinds a region looks for, in order.
static func wanted(area: String) -> Array:
	var th: String = str(Data.AREAS[area].get("theme", area))
	if THEMES.has(area):
		return THEMES[area]
	if THEMES.has(th):
		return THEMES[th]
	var k := absi(hash(area)) % COMMON.size()
	return COMMON.slice(k) + COMMON.slice(0, k)

## The bigger things (structures.gd) a region looks for, in order, once its six are placed.
static func wanted_lotus(area: String) -> Array:
	var th: String = str(Data.AREAS[area].get("theme", area))
	if LOTUS.has(area):
		return LOTUS[area]
	return LOTUS.get(th, LOTUS_COMMON)

## Whether a kind is one of the Lotus release's bigger things (built by structures.gd).
static func is_structure(kind: String) -> bool:
	return Structures.KINDS.has(kind)

static func _walkable(t: int) -> bool:
	return t == MapGen.FLOOR or t == MapGen.PATH or t == MapGen.DECOR

## The outdoor things of a realm (Atlas._build, once its ground is final): for each region the kinds
## its theme asks for, each on a forest-edge (or, by the water, a shore) tile of its own land whose
## neighbour is open ground near a road, away from everybody and everything else.  Returns the
## entities ({"kind": "prop", "prop": kind, "pos", "face": the open side, "area", "layer"}).
static func place(grid: PackedByteArray, W: int, H: int, owner: PackedByteArray, sea: PackedByteArray, ids: Array, ents: Array, layer: String) -> Array:
	var taken := {}
	for e in ents:
		var ep: Vector2i = e.pos
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				taken[ep + Vector2i(dx, dy)] = true
		for tt in e.get("tiles", []):
			taken[tt] = true
	# distance (in steps, up to 3) from the nearest road
	var road := PackedByteArray()
	road.resize(W * H)
	road.fill(255)
	var q: Array = []
	for i in W * H:
		if grid[i] == MapGen.PATH:
			road[i] = 0
			q.append(i)
	var head := 0
	while head < q.size():
		var c: int = q[head]
		head += 1
		if road[c] >= 3:
			continue
		var cx := c % W
		var cy := c / W
		for d in MapGen.DIRS:
			var nx: int = cx + d.x
			var ny: int = cy + d.y
			if nx < 0 or ny < 0 or nx >= W or ny >= H:
				continue
			var ni := ny * W + nx
			if road[ni] == 255 and _walkable(grid[ni]):
				road[ni] = road[c] + 1
				q.append(ni)
	# candidate tiles by region: [hash, tile, the open side, water?]; the loose ones (a corner of the
	# forest, a little further from the road) only for a region with too few of the others
	var cands := {}
	var loose := {}
	for k in ids.size():
		cands[k] = []
		loose[k] = []
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var i := y * W + x
			var t := grid[i]
			if (t != MapGen.WALL and t != MapGen.WATER) or sea.size() > 0 and sea[i] == 1 or taken.has(Vector2i(x, y)):
				continue
			var o: int = owner[i]
			if not cands.has(o):
				continue
			for d in MapGen.DIRS:
				var nx2: int = x + d.x
				var ny2: int = y + d.y
				var ni2 := ny2 * W + nx2
				if _walkable(grid[ni2]) and owner[ni2] == o and road[ni2] <= 3:
					var c0 := [absi(hash(Vector3i(x, y, 7))) % 100003, Vector2i(x, y), d, t == MapGen.WATER]
					# a thing in a corner of the forest would be hidden: the tile across should be closed
					var bx: int = x - d.x
					var by: int = y - d.y
					if (t == MapGen.WALL and _walkable(grid[by * W + bx])) or road[ni2] > 2:
						loose[o].append(c0)
					else:
						cands[o].append(c0)
					break
	var out: Array = []
	var all_placed: Array = []
	for k in ids.size():
		var area: String = ids[k]
		var list: Array = cands[k]
		list.sort_custom(func(a, b): return a[0] < b[0])
		var more: Array = loose[k]
		more.sort_custom(func(a, b): return a[0] < b[0])
		if list.size() < FEW_TILES:
			list.append_array(more)
		var used := {}
		var placed: Array = []
		var base_n: int = wanted(area).size()
		var kinds: Array = wanted(area) + wanted_lotus(area)
		for ki in kinds.size():
			var kind: String = kinds[ki]
			# six of the region's own, then the bigger things after them (so the six stand where they
			# always stood)
			if ki < base_n and placed.size() >= PER_REGION:
				continue
			if placed.size() >= PER_REGION + LOTUS_PER:
				break
			var water: bool = WATER_KINDS.has(kind)
			var big := is_structure(kind)
			for c2 in list:
				var tile: Vector2i = c2[1]
				if bool(c2[3]) != water or used.has(tile):
					continue
				# (a building of the Lotus release stands clear of the town's own buildings: the sect's
				# stage once had a shop's signboard standing up through its boards)
				if big and _by_building(grid, W, H, tile, 3):
					continue
				var near := false
				for p in placed:
					if (p as Vector2i).distance_squared_to(tile) < 64:
						near = true
						break
				if near:
					continue
				placed.append(tile)
				used[tile] = true
				out.append({"kind": "prop", "id": "prop:%s:%d" % [area, placed.size()], "prop": kind, "pos": tile, "face": c2[2], "area": area, "layer": layer})
				break
		all_placed.append_array(placed)
	# Part XV: the places of Yue Ling's memories, and the lotus pond where she woke (bonds.gd), on what
	# is left of the edge, after everything else
	var every := {}
	for k2 in ids.size():
		var both: Array = (cands[k2] as Array) + (loose[k2] as Array)
		both.sort_custom(func(a, b): return a[0] < b[0])
		every[k2] = both
	out.append_array(Bonds.place(ids, every, all_placed, layer, out, grid, W, H))
	return out

## Whether a building (its walls or its floor) stands within `r` tiles of `tile`.
static func _by_building(grid: PackedByteArray, W: int, H: int, tile: Vector2i, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var x := tile.x + dx
			var y := tile.y + dy
			if x < 0 or y < 0 or x >= W or y >= H:
				continue
			var t := grid[y * W + x]
			if t == MapGen.BUILDING or t == MapGen.INTERIOR:
				return true
	return false

## The furniture of a realm's buildings (or of one floor) as things to use: [kind, tile, blocks] from
## the building's props, in the realm's (or the floor's) own tiles of `grid` (`w` wide).
static func furniture(props: Array, area: String, layer: String, prefix: String, grid: PackedByteArray, w: int) -> Array:
	var out: Array = []
	for k in props.size():
		var pr: Array = props[k]
		var fk := str(pr[0])
		if not FURNITURE.has(fk):
			continue
		var tile: Vector2i = pr[1]
		var e := {"kind": "prop", "id": "%s:%d" % [prefix, k], "prop": FURNITURE[fk], "pos": tile, "area": area, "layer": layer, "furn": fk}
		if MapGen.is_walkable_tile(grid[tile.y * w + tile.x]):
			# on floor anyone walks over (a cushion, a stool): used by facing it, and never in the way
			# of anyone walking (or of the bot)
			e["walk"] = true
		out.append(e)
	return out

# ---------------------------------------------------------------- what comes of it

## Do it: what comes of using `e` now (Game's state changes here), as the lines to show.
static func use(e: Dictionary, g) -> Array:
	var k := kind_of(e)
	var pid := str(e.id)
	var n: int = int(g.prop_uses.get(pid, 0))
	g.prop_uses[pid] = n + 1
	Eggs.used(g, str(e.get("prop", "")), n + 1)
	Needs.used(g, str(e.get("prop", "")), str(k.get("effect", "")))
	var out: Array = [line_for(e, n)]
	match str(k.get("effect", "")):
		"rest":
			out.append(_restore(g, 0.25, 0.25, "Rested"))
		"drink":
			out.append(_restore(g, 0.3, 0.0, "Refreshed"))
		"qi":
			out.append(_restore(g, 0.0, 0.35, "Calmed"))
		"sleep":
			g.heal_full()
			# after dark a bed is a night's sleep (clock.gd): he wakes at six with the cocks crowing
			if Clock.sleep(g):
				# (the Underclothes release: the hours slept are not then charged to the body as hours awake,
				# survival.gd: a night's own small thirst and hunger, as under the sky)
				if Needs.on(g):
					g.needs_clock = float(g.clock) + float(g.day) * 1440.0
					Needs.give(g, {"hunger": -18.0, "thirst": -20.0, "bladder": -30.0})
				out.append("Slept the night through: woke at the Hour of the Rabbit, health and qi restored")
			else:
				out.append("Slept: health and qi restored")
		"fish":
			out.append(_restore(g, 0.15, 0.2, "A quiet hour"))
		"herb":
			if _ready(g, pid, 600.0):
				g.add_item("ess_wood")
				out.append("Gathered a Wood Essence")
		"ore":
			# a seam gives a piece now and then (earth from one, metal from the next)
			if _ready(g, pid, 600.0):
				var ore := "ess_earth" if absi(hash(pid)) % 2 == 0 else "ess_metal"
				g.add_item(ore)
				out.append("Broke out %s" % ("an Earth Essence" if ore == "ess_earth" else "a Metal Essence"))
		"train":
			# (nothing to teach at the peak of a realm, and the stones' time is not spent then; what they
			# teach counts like any other cultivation, so a stage reached is reached)
			if not g.at_cap() and _ready(g, pid, 600.0):
				var gain := maxi(1, int(g.exp_need() * 0.03))
				g.add_exp(gain)
				out.append("Cultivation +%d" % gain)
		"luck", "find":
			if not g.prop_found.has(pid):
				g.prop_found[pid] = true
				var st := 5 + absi(hash(pid)) % 26
				g.stones += st
				out.append("Found %d spirit stones" % st)
	var kind := str(e.prop)
	# the Hollow Hills release: a thing of the caves done while the story asks for them (Part XX)
	# (the Underclothes release: and a thing of the open land that a "try" step names, the hot spring
	# of Part XXVI; it used to count only the things of the caves, and the step could never be done)
	var cs: Dictionary = g.cur_step() if g.has_method("cur_step") else {}
	if CaveThings.KINDS.has(kind) or (str(cs.get("kind", "")) == "try" and kind in cs.get("things", [])):
		g.step_uses[kind] = true
		g.poll_steps()
	# with Yue Ling there: a wish of hers granted, and a little closer for doing it together (bonds.gd)
	if g.companion:
		out.append_array(Bonds.did_together(g, kind, str(k.get("comp", "watch")) != "watch" or bool(k.get("pair", false))))
	# the first time Lin Feng does each kind of thing, the world hears of it
	if not g.pastimes.has(kind):
		g.pastimes[kind] = true
		g.add_renown(1)
		out.append("A new pastime: %s (%d of %d)" % [str(k.get("verb", kind)).to_lower(), g.pastimes.size(), KINDS.size()])
	return out.filter(func(s): return str(s) != "")

static func _ready(g, pid: String, cool: float) -> bool:
	var last: float = float(g.prop_t.get(pid, -1e9))
	if g.playtime - last < cool:
		return false
	g.prop_t[pid] = g.playtime
	return true

static func _restore(g, hp_k: float, qi_k: float, what: String) -> String:
	var any := false
	for i in g.party_size():
		var h0: float = g.hp[i]
		var q0: float = g.qi[i]
		g.hp[i] = minf(float(g.max_hp(i)), h0 + g.max_hp(i) * hp_k)
		g.qi[i] = minf(float(g.max_qi(i)), q0 + g.max_qi(i) * qi_k)
		any = any or g.hp[i] > h0 + 0.5 or g.qi[i] > q0 + 0.5
	if not any:
		return ""
	if hp_k > 0.0 and qi_k > 0.0:
		return "%s: health and qi restored a little" % what
	return "%s: %s restored a little" % [what, "health" if hp_k > 0.0 else "qi"]

# ---------------------------------------------------------------- models

const WOOD := Color("6a4a30")
const WOOD_L := Color("a87a4a")
const STONE := Color("b0a898")
const STONE_D := Color("7a7468")
const RED := Color("b8382a")
const TILE := Color("2f4a6a")
const BRONZE := Color("8a7038")

## An outdoor thing, standing at the origin of its tile with its front (where it is used from)
## towards +z.  Parts that move are kept as named children: "swing" (the bell, the drum skin, the
## swing seat, the chimes), "flame", "water".
static func model(kind: String, theme: String) -> Node3D:
	if is_structure(kind):
		return Structures.model(kind, theme)
	if CaveThings.KINDS.has(kind):
		return CaveThings.model(kind, theme)
	var root := Node3D.new()
	var b := MB.new()
	var g := MB.new()
	var mv := MB.new()
	var mv_at := Vector3.ZERO
	match kind:
		"bench":
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 0.6, 0.2, 0.05), Vector3(0.22, 0.4, 0.4), MB.tag(STONE_D, MB.STONE))
			b.box(Vector3(0, 0.45, 0.05), Vector3(1.7, 0.12, 0.5), MB.tag(STONE, MB.STONE))
			b.box(Vector3(0, 0.39, 0.05), Vector3(1.62, 0.04, 0.44), MB.tag(STONE_D, MB.STONE))
		"well":
			b.lathe(Vector3.ZERO, [Vector2(0.95, 0.0), Vector2(0.95, 0.7), Vector2(0.78, 0.75), Vector2(0.78, 0.05)], MB.tag(STONE, MB.STONE), 16)
			g.disc(Vector3(0, 0.45, 0), 0.74, Color(0.25, 0.45, 0.6, 0.5), 16)
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 0.85, 1.25, 0), Vector3(0.12, 1.2, 0.12), MB.tag(WOOD, MB.WOOD))
			b.limb(Vector3(-0.9, 1.55, 0), Vector3(0.9, 1.55, 0), 0.07, 0.07, MB.tag(WOOD_L, MB.WOOD), 8)
			b.box(Vector3(0, 1.95, 0), Vector3(2.2, 0.08, 1.1), MB.tag(TILE, MB.STONE), Vector3(0, 0, 0))
			b.box(Vector3(0, 2.05, 0), Vector3(1.6, 0.1, 0.6), MB.tag(TILE.darkened(0.2), MB.STONE))
			b.limb(Vector3(0.2, 1.55, 0.05), Vector3(0.2, 1.0, 0.05), 0.01, 0.01, MB.tag(Color("c8b080"), MB.CLOTH), 4)
			mv.lathe(Vector3.ZERO, [Vector2(0.14, 0.0), Vector2(0.17, 0.22), Vector2(0.16, 0.24)], MB.tag(WOOD_L, MB.WOOD), 10)
			mv_at = Vector3(0.2, 0.8, 0.05)
		"shrine":
			b.box(Vector3(0, 0.35, -0.2), Vector3(1.0, 0.7, 0.8), MB.tag(STONE_D, MB.STONE))
			b.box(Vector3(0, 0.95, -0.2), Vector3(0.8, 0.5, 0.6), MB.tag(STONE, MB.STONE))
			b.box(Vector3(0, 0.95, 0.08), Vector3(0.4, 0.38, 0.06), MB.tag(Color("2a2420"), MB.STONE))
			b.sph(Vector3(0, 0.92, 0.0), Vector3(0.12, 0.16, 0.1), MB.tag(Color("d8c070"), MB.METAL))
			b.box(Vector3(0, 1.28, -0.2), Vector3(1.2, 0.12, 0.95), MB.tag(TILE, MB.STONE))
			b.cone(Vector3(0, 1.45, -0.2), 0.75, 0.32, MB.tag(TILE.darkened(0.15), MB.STONE), Vector3(0, PI / 4, 0), 4)
			b.lathe(Vector3(0, 0.0, 0.55), [Vector2(0.16, 0.0), Vector2(0.2, 0.18), Vector2(0.17, 0.28), Vector2(0.21, 0.3)], MB.tag(BRONZE, MB.METAL), 12)
			for k in 3:
				b.limb(Vector3(-0.05 + k * 0.05, 0.3, 0.55), Vector3(-0.05 + k * 0.05, 0.55, 0.55), 0.006, 0.006, MB.tag(Color("c84a2a"), MB.WOOD), 3)
				g.sph_hi(Vector3(-0.05 + k * 0.05, 0.56, 0.55), Vector3.ONE * 0.02, Color(1.0, 0.55, 0.25, 0.95))
			b.sph(Vector3(0.3, 0.74, 0.15), Vector3(0.07, 0.07, 0.07), MB.tag(Color("f0a070"), MB.CLOTH))
		"bell":
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 1.0, 1.4, -0.2), Vector3(0.2, 2.8, 0.2), MB.tag(RED, MB.WOOD))
			b.box(Vector3(0, 2.85, -0.2), Vector3(2.5, 0.2, 0.3), MB.tag(RED, MB.WOOD))
			b.box(Vector3(0, 3.05, -0.2), Vector3(2.8, 0.12, 0.6), MB.tag(TILE, MB.STONE))
			mv.lathe(Vector3(0, -1.5, 0), [Vector2(0.62, 0.0), Vector2(0.55, 0.15), Vector2(0.5, 0.9), Vector2(0.42, 1.3), Vector2(0.15, 1.45), Vector2(0.05, 1.55)], MB.tag(BRONZE.lerp(Color("4a8a6a"), 0.25), MB.METAL), 20)
			mv.box(Vector3(0, -0.3, 0), Vector3(0.08, 0.6, 0.08), MB.tag(WOOD, MB.WOOD))
			for r in 3:
				mv.torus(Vector3(0, -1.3 + r * 0.35, 0), 0.6 - r * 0.04, 0.02, MB.tag(BRONZE.darkened(0.2), MB.METAL), Vector3.ZERO)
			mv_at = Vector3(0, 2.75, -0.2)
			# the striker: a log hung on two ropes before the bell
			b.limb(Vector3(-0.5, 1.5, 0.75), Vector3(0.5, 1.5, 0.75), 0.11, 0.11, MB.tag(WOOD_L, MB.WOOD), 8)
			for s2: float in [-1.0, 1.0]:
				b.limb(Vector3(s2 * 0.4, 1.5, 0.75), Vector3(s2 * 0.4, 2.85, 0.0), 0.012, 0.012, MB.tag(Color("c8b080"), MB.CLOTH), 4)
		"drum":
			for s: float in [-1.0, 1.0]:
				b.limb(Vector3(s * 0.75, 0.0, -0.1), Vector3(s * 0.55, 1.1, -0.1), 0.06, 0.06, MB.tag(RED, MB.WOOD), 6)
			mv.cyl(Vector3.ZERO, 0.75, 0.6, MB.tag(RED, MB.WOOD), Vector3(PI * 0.5, 0, 0), 20)
			mv.cyl(Vector3(0, 0, 0.31), 0.7, 0.02, MB.tag(Color("e8d8b0"), MB.CLOTH), Vector3(PI * 0.5, 0, 0), 20)
			mv.cyl(Vector3(0, 0, -0.31), 0.7, 0.02, MB.tag(Color("e8d8b0"), MB.CLOTH), Vector3(PI * 0.5, 0, 0), 20)
			for k in 12:
				var a := TAU * k / 12.0
				mv.ball(Vector3(cos(a) * 0.74, sin(a) * 0.74, 0.3), 0.03, MB.tag(Color("d8b050"), MB.METAL))
			mv_at = Vector3(0, 1.1, -0.1)
			b.limb(Vector3(0.35, 0.95, 0.5), Vector3(0.6, 0.6, 0.65), 0.03, 0.03, MB.tag(WOOD_L, MB.WOOD), 5)
		"qin":
			b.box(Vector3(0, 0.25, -0.35), Vector3(1.5, 0.08, 0.6), MB.tag(STONE, MB.STONE))
			for s: float in [-1.0, 1.0]:
				b.box(Vector3(s * 0.6, 0.11, -0.35), Vector3(0.2, 0.22, 0.45), MB.tag(STONE_D, MB.STONE))
			b.box(Vector3(0, 0.33, -0.35), Vector3(1.2, 0.07, 0.2), MB.tag(Color("3a2218"), MB.WOOD))
			for k in 7:
				b.box(Vector3(0, 0.37, -0.42 + k * 0.024), Vector3(1.15, 0.006, 0.006), MB.tag(Color("e8dcc0"), MB.CLOTH))
			b.sph(Vector3(0, 0.06, 0.2), Vector3(0.4, 0.08, 0.35), MB.tag(Color("c8a040"), MB.CLOTH))
		"fishing":
			# in the water: a little wooden jetty's end, reeds and a float
			for s: float in [-1.0, 1.0]:
				b.cyl(Vector3(s * 0.5, -0.15, 0.6), 0.07, 0.8, MB.tag(WOOD, MB.WOOD), Vector3.ZERO, 6)
			b.box(Vector3(0, 0.25, 0.75), Vector3(1.3, 0.08, 0.9), MB.tag(WOOD_L, MB.WOOD))
			for k in 9:
				var a2 := k * 0.9
				b.limb(Vector3(-0.8 + cos(a2) * 0.25, -0.3, -0.4 + sin(a2) * 0.25), Vector3(-0.85 + cos(a2) * 0.32, 0.9 + (k % 3) * 0.15, -0.45 + sin(a2) * 0.3), 0.02, 0.008, MB.tag(Color("7a9a4a"), MB.FOLIAGE), 3)
			mv.ball(Vector3.ZERO, 0.05, MB.tag(Color("e04040"), MB.CLOTH))
			mv.ball(Vector3(0, -0.05, 0), 0.04, MB.tag(Color("f0f0f0"), MB.CLOTH))
			mv_at = Vector3(0.2, Terrain3D.WATER_Y + 0.02, -0.6)
		"swing":
			for s: float in [-1.0, 1.0]:
				b.limb(Vector3(s * 1.0, 0.0, -0.2), Vector3(s * 0.85, 2.6, -0.2), 0.08, 0.07, MB.tag(WOOD, MB.WOOD), 6)
			b.limb(Vector3(-1.1, 2.6, -0.2), Vector3(1.1, 2.6, -0.2), 0.08, 0.08, MB.tag(WOOD, MB.WOOD), 6)
			for s2: float in [-1.0, 1.0]:
				mv.limb(Vector3(s2 * 0.35, 0.0, 0), Vector3(s2 * 0.35, -2.1, 0), 0.012, 0.012, MB.tag(Color("c8b080"), MB.CLOTH), 4)
			mv.box(Vector3(0, -2.12, 0), Vector3(0.85, 0.05, 0.3), MB.tag(WOOD_L, MB.WOOD))
			mv_at = Vector3(0, 2.6, -0.2)
		"wish_tree":
			b.limb(Vector3(0, 0, -0.4), Vector3(0.1, 2.2, -0.4), 0.32, 0.22, MB.tag(Color("5a4030"), MB.WOOD), 8)
			var rng := RandomNumberGenerator.new()
			rng.seed = 404
			for k in 6:
				var a3 := TAU * k / 6.0 + 0.3
				var tip := Vector3(cos(a3) * 1.4, 2.6 + rng.randf() * 0.6, sin(a3) * 1.4 - 0.4)
				b.limb(Vector3(0.1, 2.0, -0.4), tip, 0.14, 0.05, MB.tag(Color("5a4030"), MB.WOOD), 6)
				b.sph(tip + Vector3(0, 0.3, 0), Vector3(0.9, 0.55, 0.9), MB.tag(Color("4a8a4a").lerp(Color("8ab858"), rng.randf()), MB.FOLIAGE), Vector3.ZERO, true)
				for r in 4:
					var rp := Vector3(0.1, 2.0, -0.4).lerp(tip, 0.4 + r * 0.15)
					b.leaf(rp, rp + Vector3(0.03, -0.45, 0.02), 0.05, MB.tag(Color("d8282a"), MB.CLOTH), Vector3(1, 0, 0))
		"stele":
			b.box(Vector3(0, 0.15, -0.1), Vector3(1.2, 0.3, 0.7), MB.tag(STONE_D, MB.STONE))
			b.box(Vector3(0, 1.15, -0.1), Vector3(0.9, 1.8, 0.28), MB.tag(STONE, MB.STONE))
			b.sph(Vector3(0, 2.05, -0.1), Vector3(0.48, 0.18, 0.15), MB.tag(STONE, MB.STONE))
			for k in 5:
				for j in 3:
					b.box(Vector3(-0.22 + j * 0.22, 1.7 - k * 0.24, 0.05), Vector3(0.12, 0.12, 0.02), MB.tag(Color("3a342c"), MB.STONE))
		"herb_patch":
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 909
			for k in 14:
				var hp := Vector3(rng2.randf_range(-0.7, 0.7), 0.0, rng2.randf_range(-0.6, 0.6))
				for l in 4:
					var la := TAU * l / 4.0 + k
					b.leaf(hp, hp + Vector3(cos(la) * 0.2, 0.25 + rng2.randf() * 0.15, sin(la) * 0.2), 0.07, MB.tag(Color("4a9a5a").lerp(Color("8ad070"), rng2.randf()), MB.FOLIAGE), Vector3(-sin(la), 0, cos(la)))
				if k % 3 == 0:
					g.sph_hi(hp + Vector3(0, 0.38, 0), Vector3.ONE * 0.035, Color(0.6, 1.0, 0.7, 0.9))
		"campfire":
			for k in 9:
				var a4 := TAU * k / 9.0
				b.ball(Vector3(cos(a4) * 0.45, 0.06, sin(a4) * 0.45), 0.13, MB.tag(STONE_D, MB.STONE))
			for k2 in 4:
				var a5 := TAU * k2 / 4.0 + 0.4
				b.limb(Vector3(cos(a5) * 0.35, 0.03, sin(a5) * 0.35), Vector3(0, 0.35, 0), 0.05, 0.04, MB.tag(Color("4a3020"), MB.WOOD), 5)
			mv.cone(Vector3(0, 0.25, 0), 0.22, 0.6, Color(1.0, 0.55, 0.15, 0.85), Vector3.ZERO, 8)
			mv.cone(Vector3(0, 0.2, 0), 0.12, 0.38, Color(1.0, 0.9, 0.5, 0.9), Vector3.ZERO, 8)
			for k3 in 2:
				b.box(Vector3(-0.85 + k3 * 1.7, 0.15, -0.2), Vector3(0.25, 0.3, 0.9), MB.tag(Color("5a4030"), MB.WOOD), Vector3(0, 0.2 - k3 * 0.4, 0))
		"stones":
			for k in 3:
				var sp := Vector3(-0.6 + k * 0.6, 0.0, -0.15)
				b.box(sp + Vector3(0, 0.16, 0), Vector3(0.4, 0.32, 0.22), MB.tag(STONE.darkened(k * 0.08), MB.STONE))
				b.torus(sp + Vector3(0, 0.34, 0), 0.12, 0.035, MB.tag(STONE.darkened(k * 0.08), MB.STONE), Vector3(0, 0, PI * 0.5))
			b.box(Vector3(0, 0.02, 0.2), Vector3(2.0, 0.04, 1.2), MB.tag(Color("8a7a60"), MB.WOOD))
		"broom":
			b.limb(Vector3(0.7, 0.0, -0.3), Vector3(0.85, 1.4, -0.45), 0.025, 0.025, MB.tag(WOOD_L, MB.WOOD), 5)
			b.cone(Vector3(0.7, 0.15, -0.3), 0.14, 0.35, MB.tag(Color("c8a860"), MB.HAIR), Vector3(PI, 0, 0), 8)
			var rng3 := RandomNumberGenerator.new()
			rng3.seed = 111
			for k in 26:
				var lp := Vector3(rng3.randf_range(-0.7, 0.4), 0.03 + rng3.randf() * 0.1, rng3.randf_range(-0.5, 0.5))
				b.leaf(lp, lp + Vector3(rng3.randf_range(-0.15, 0.15), 0.02, rng3.randf_range(-0.15, 0.15)), 0.08, MB.tag(Color("c8502a").lerp(Color("e8a030"), rng3.randf()), MB.FOLIAGE), Vector3(0, 1, 0))
		"weiqi":
			b.cyl(Vector3(0, 0.35, -0.3), 0.55, 0.1, MB.tag(STONE, MB.STONE), Vector3.ZERO, 16)
			b.cyl(Vector3(0, 0.15, -0.3), 0.25, 0.3, MB.tag(STONE_D, MB.STONE), Vector3.ZERO, 10)
			b.box(Vector3(0, 0.42, -0.3), Vector3(0.62, 0.04, 0.62), MB.tag(Color("d8b870"), MB.WOOD))
			var rng4 := RandomNumberGenerator.new()
			rng4.seed = 1919
			for k in 22:
				var stp := Vector3(rng4.randi_range(-4, 4) * 0.065, 0.45, rng4.randi_range(-4, 4) * 0.065 - 0.3)
				b.sph(stp, Vector3(0.028, 0.012, 0.028), MB.tag(Color("1a1a1a") if k % 2 == 0 else Color("f0f0e8"), MB.STONE))
			b.box(Vector3(0, 0.2, 0.35), Vector3(0.5, 0.4, 0.4), MB.tag(STONE_D, MB.STONE))
		"tea":
			b.box(Vector3(0, 0.4, -0.3), Vector3(0.9, 0.06, 0.6), MB.tag(WOOD, MB.WOOD))
			for s: float in [-1.0, 1.0]:
				for s2: float in [-1.0, 1.0]:
					b.box(Vector3(s * 0.38, 0.19, -0.3 + s2 * 0.24), Vector3(0.06, 0.38, 0.06), MB.tag(WOOD, MB.WOOD))
			b.lathe(Vector3(0, 0.43, -0.3), [Vector2(0.09, 0.0), Vector2(0.12, 0.08), Vector2(0.08, 0.16), Vector2(0.03, 0.2)], MB.tag(Color("6a3a2a"), MB.STONE), 10)
			for s3: float in [-1.0, 1.0]:
				b.lathe(Vector3(s3 * 0.25, 0.43, -0.2), [Vector2(0.03, 0.0), Vector2(0.04, 0.05)], MB.tag(Color("e8e0d0"), MB.STONE), 8)
			b.sph(Vector3(0, 0.06, 0.25), Vector3(0.3, 0.06, 0.25), MB.tag(Color("c8a040"), MB.CLOTH))
		"lion":
			b.box(Vector3(0, 0.3, -0.2), Vector3(0.9, 0.6, 1.0), MB.tag(STONE_D, MB.STONE))
			b.sph(Vector3(0, 0.95, -0.25), Vector3(0.38, 0.45, 0.5), MB.tag(STONE, MB.STONE))
			b.sph(Vector3(0, 1.45, 0.0), Vector3(0.36, 0.34, 0.34), MB.tag(STONE, MB.STONE))
			for k in 8:
				var a6 := TAU * k / 8.0
				b.ball(Vector3(cos(a6) * 0.32, 1.45 + sin(a6) * 0.32, -0.08), 0.09, MB.tag(STONE.darkened(0.1), MB.STONE))
			b.sph(Vector3(0, 1.38, 0.3), Vector3(0.18, 0.12, 0.12), MB.tag(STONE.lightened(0.1), MB.STONE))
			b.ball(Vector3(0.25, 0.72, 0.25), 0.16, MB.tag(STONE.lightened(0.05), MB.STONE))
			g.sph_hi(Vector3(0, 1.72, 0.05), Vector3(0.2, 0.06, 0.2), Color(1.0, 0.9, 0.6, 0.25))
		"chimes":
			b.limb(Vector3(0, 0, -0.4), Vector3(0, 2.4, -0.4), 0.06, 0.05, MB.tag(WOOD, MB.WOOD), 6)
			b.limb(Vector3(0, 2.3, -0.4), Vector3(0, 2.3, 0.3), 0.04, 0.04, MB.tag(WOOD, MB.WOOD), 6)
			for k in 5:
				mv.limb(Vector3((k - 2) * 0.1, 0.0, 0.0), Vector3((k - 2) * 0.1, -0.35 - (k % 3) * 0.12, 0.0), 0.022, 0.022, MB.tag(BRONZE.lightened(0.15), MB.METAL), 6)
			mv.box(Vector3(0, 0.02, 0), Vector3(0.6, 0.03, 0.06), MB.tag(WOOD_L, MB.WOOD))
			mv_at = Vector3(0, 2.25, 0.25)
		"lantern_st":
			b.box(Vector3(0, 0.12, -0.1), Vector3(0.7, 0.24, 0.7), MB.tag(STONE_D, MB.STONE))
			b.cyl(Vector3(0, 0.7, -0.1), 0.12, 0.95, MB.tag(STONE, MB.STONE), Vector3.ZERO, 8)
			b.box(Vector3(0, 1.22, -0.1), Vector3(0.6, 0.12, 0.6), MB.tag(STONE, MB.STONE))
			b.box(Vector3(0, 1.45, -0.1), Vector3(0.42, 0.36, 0.42), MB.tag(STONE.lightened(0.05), MB.STONE))
			b.cone(Vector3(0, 1.75, -0.1), 0.5, 0.35, MB.tag(STONE_D, MB.STONE), Vector3(0, PI / 4, 0), 4)
			# the flame inside, shown once the lantern has been lit
			mv.box(Vector3.ZERO, Vector3(0.3, 0.24, 0.44), Color(1.0, 0.72, 0.35, 0.85))
			mv.box(Vector3.ZERO, Vector3(0.44, 0.24, 0.3), Color(1.0, 0.72, 0.35, 0.85))
			mv_at = Vector3(0, 1.45, -0.1)
		"koi":
			# in the water: a ring of stepping stones and lily pads round a deeper pool, fish under them
			for k in 7:
				var a7 := TAU * k / 7.0
				b.sph(Vector3(cos(a7) * 0.85, Terrain3D.WATER_Y + 0.02, sin(a7) * 0.7), Vector3(0.22, 0.03, 0.22), MB.tag(Color("3f9a5a"), MB.FOLIAGE))
			for k2 in 5:
				var a8 := TAU * k2 / 5.0 + 0.4
				mv.sph(Vector3(cos(a8) * 0.4, 0.0, sin(a8) * 0.35), Vector3(0.06, 0.04, 0.16), MB.tag([Color("f08030"), Color("f0f0e0"), Color("e04020")][k2 % 3], MB.SCALE), Vector3(0, -a8, 0))
			mv_at = Vector3(0, Terrain3D.WATER_Y - 0.12, 0)
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not g.is_empty():
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not mv.is_empty():
		var mover := Node3D.new()
		mover.name = "mover"
		mover.position = mv_at
		root.add_child(mover)
		var mat: Material = MB.mat_glow() if kind in ["campfire", "lantern_st"] else MB.mat_vc()
		MB.mesh_node(mover, mv.build(mat)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.set_meta("mover", mover)
	return root

## Something in the hero's hand for a clip, in the hand bone's own space (the bone runs from the
## wrist down to the fingers along -y; the palm faces +x for the right hand).
static func held(what: String) -> Node3D:
	# (the Heavy Road release: the felling axe and the sickle, burden.gd)
	var tool := Burden.held(what)
	if tool != null:
		return tool
	var more := Structures.held(what)
	if more != null:
		return more
	more = CaveThings.held(what)
	if more != null:
		return more
	var root := Node3D.new()
	var b := MB.new()
	match what:
		"dipper":
			b.lathe(Vector3(0, -0.02, 0.1), [Vector2(0.05, 0.0), Vector2(0.06, 0.06)], MB.tag(WOOD_L, MB.WOOD), 10)
			b.limb(Vector3(0, -0.08, -0.12), Vector3(0, -0.06, 0.08), 0.012, 0.012, MB.tag(WOOD, MB.WOOD), 5)
		"cup":
			b.lathe(Vector3(0, -0.09, 0.02), [Vector2(0.025, 0.0), Vector2(0.035, 0.05)], MB.tag(Color("e8e0d0"), MB.STONE), 10)
		"rod":
			b.limb(Vector3(0, -0.08, -0.25), Vector3(0, 0.6, 1.9), 0.014, 0.005, MB.tag(Color("8a7a4a"), MB.WOOD), 5)
			b.limb(Vector3(0, 0.6, 1.9), Vector3(0, -1.2, 2.1), 0.002, 0.002, MB.tag(Color("e8e8e8"), MB.CLOTH), 3)
		"broom":
			b.limb(Vector3(0, -0.08, 0.6), Vector3(0, -0.08, -0.9), 0.02, 0.02, MB.tag(WOOD_L, MB.WOOD), 5)
			b.cone(Vector3(0, -0.08, -1.05), 0.13, 0.32, MB.tag(Color("c8a860"), MB.HAIR), Vector3(PI * 0.5, 0, 0), 8)
		"hammer":
			b.limb(Vector3(0, -0.08, -0.08), Vector3(0, -0.08, 0.3), 0.016, 0.016, MB.tag(WOOD, MB.WOOD), 5)
			b.box(Vector3(0, -0.08, 0.34), Vector3(0.07, 0.07, 0.16), MB.tag(Color("44444c"), MB.METAL), Vector3(0, PI * 0.5, 0))
		"ladle":
			b.limb(Vector3(0, -0.08, 0.3), Vector3(0, -0.08, -0.9), 0.016, 0.016, MB.tag(WOOD_L, MB.WOOD), 5)
			b.sph(Vector3(0, -0.08, -0.95), Vector3(0.07, 0.04, 0.07), MB.tag(WOOD, MB.WOOD))
		"book":
			b.box(Vector3(-0.02, -0.12, 0.04), Vector3(0.03, 0.2, 0.28), MB.tag(Color("e8dcc0"), MB.CLOTH))
			b.box(Vector3(-0.035, -0.12, 0.04), Vector3(0.01, 0.21, 0.29), MB.tag(Color("6a2a2a"), MB.CLOTH))
		"stone_lock":
			b.box(Vector3(0, -0.2, 0), Vector3(0.22, 0.2, 0.3), MB.tag(STONE, MB.STONE))
			b.torus(Vector3(0, -0.07, 0), 0.08, 0.025, MB.tag(STONE, MB.STONE), Vector3(0, 0, PI * 0.5))
	if not b.is_empty():
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root
