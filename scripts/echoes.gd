class_name Echoes
extends RefCounted
## Crossroads and their echoes (the Hundred Works release): choices that the whole story remembers.
##
## Before this release a choice mattered where it was made: five people met on the road (fate.gd), one
## qilin, a Dao, a hearth.  Now there is a **crossroads** in almost every part of the story: a
## question asked once, after a lord has fallen or a thing has been found, with two or three answers
## and no way to take it back.  Each answer
##
##   * gives or costs something there and then (stones, renown, essences, a people's regard);
##   * **tips a scale** (SCALES): mercy against rigour, the new works against the old ways, the wide
##     world against the home fire.  A scale that leans far enough changes how the world meets Lin
##     Feng for the rest of the game (LEANS): packs give up what they guard or open the battle afraid, the makers ask
##     less, a hearth or a people warms faster, his name travels further;
##   * **echoes**: later conversations, sometimes ten chapters later, have lines that are only said
##     to somebody who chose that way (`echo`: a dialogue key -> the lines for each answer).  The
##     bandits spared in the Bamboo Forest are on the wall of Qingshi the night Nian comes; the
##     drawings carried out of Heaven's Forge are on Gongshu Ban's bench in Part XIX;
##   * is told at the end (`end`), with what the scales made of him.
##
## The three crossroads of Part XIX are the heaviest: what Qingshi does with a wheel that never
## stops, whether a made thing may keep the heart it made itself, and what the land is to do with its
## machines, which only a maker of that school may answer in that school's way (works.gd).
##
## The Crossroads page (Esc > Crossroads) keeps every answer, the scales, and each echo as it comes.
## Everything takes the game state `g` as an argument, like trials.gd.

const SCALES := {
	"heart": {"n": "Mercy and Rigour", "pos": "Merciful", "neg": "Unbending", "col": Color("ff9ac0"),
		"pos_text": "A beaten pack gives up what it was guarding sooner than die for it: battles pay a tenth more spirit stones, and essences are left more often.",
		"neg_text": "The wild has heard what you do: packs open the battle afraid, a little of their strength already gone."},
	"craft": {"n": "New Works and Old Ways", "pos": "Of the New Works", "neg": "Of the Old Ways", "col": Color("7ab8d8"),
		"pos_text": "The makers of the land count you one of them: every work costs a quarter fewer spirit stones.",
		"neg_text": "The hearths know you keep the old ways: whatever you do for a hearth counts for more."},
	"reach": {"n": "The Wide World and the Home Fire", "pos": "Of the Wide World", "neg": "Of the Home Fire", "col": Color("9ad870"),
		"pos_text": "The peoples of the realms have heard you belong to nobody: their regard comes a quarter faster.",
		"neg_text": "Your name goes out from one valley and comes back larger: every deed and every trial earns more renown."},
}
const SCALE_ORDER := ["heart", "craft", "reach"]
## how far a scale must lean before the world treats Lin Feng differently, and before it names him for it
const LEAN := 3
const KNOWN := 6
## what a leaning scale does (the numbers the game asks for through `lean_mod`)
## (a merciful name: what a beaten pack gives up, and how much more often it leaves an essence)
const YIELD_STONES := 1.1
const YIELD_DROP := 0.06
const FEAR_HP := 0.94
const WORKS_STONES := 0.75
const HEARTH_MORE := 1
const REGARD_MORE := 1.25
const RENOWN_MORE := 1

## The crossroads, in the order the story reaches them.
const CROSSROADS := {
	"bandits": {"step": "s_ironfang", "part": "I", "n": "Iron Fang's men",
		"ask": "Iron Fang is down, and forty hungry men have thrown their knives in the bamboo. What is to be done with them?",
		"options": [
			{"id": "mend", "label": "Set them to mend the forest road", "tilt": {"heart": 2}, "gain": {"renown": 3},
				"desc": "They broke the road; let them mend it, under the eye of the outer disciples, and eat at the sect's back door until it is done. The valley will hear of it (renown).",
				"log": "Set Iron Fang's men to mending the road they had robbed."},
			{"id": "drive", "label": "Drive them out of the valley", "tilt": {"heart": -2}, "gain": {"stones": 90},
				"desc": "Bandits are bandits. Take what they stole (spirit stones) and see them over the pass with nothing. Where they go after that is no concern of the sect's.",
				"log": "Drove Iron Fang's men over the pass with nothing."},
		],
		"after": {
			"mend": [["Narrator", "Forty men look at the sweeper, and then at the broken corduroy of the forest road, and one of them, slowly, picks up a log."], ["Yue Ling", "They are terrible at it. Look at that one. He is holding the mallet by the wrong end."]],
			"drive": [["Narrator", "They go up the pass in a line, not looking back, with their hands empty. At the top one of them stops, as if he might say something. Then he goes on."], ["Yue Ling", "It is fair. I only wonder where a man goes, who has nothing and has just been shown he cannot take it."]],
		},
		"echo": {
			"s_vl_intro": {
				"mend": [["Granny Wen the Midwife", "Those road-menders of yours finished the bamboo road years ago and never went home. Six of them farm the terraces above my house now. One married my niece. He still holds a mallet by the wrong end."]],
				"drive": [["Granny Wen the Midwife", "We had hungry men through here the winter after you cleared the bamboo. Knives, no shoes. We fed three and buried two. I never did learn who turned them out with nothing."]],
			},
			"pre:nian": {
				"mend": [["Narrator", "On the wall of Qingshi, among the farmers with their pots and pans, stand six big men with mallets, who once took orders from Iron Fang and tonight take them from Granny Wen."]],
				"drive": [["Narrator", "The wall of Qingshi is thinly manned tonight. There are gaps where, in another year, six more strong backs might have stood."]],
			},
		},
		"end": {"mend": "Iron Fang's men mended the road they had robbed, and stayed to farm beside it.", "drive": "Iron Fang's men went over the pass with nothing, and the valley never asked where."}},

	"garden": {"step": "s_hag", "part": "I", "n": "The Hag's garden",
		"ask": "Behind the Marsh Hag's hut is her garden: nine beds of poison, tended for sixty years. What becomes of it?",
		"options": [
			{"id": "study", "label": "Dig it up for Alchemist Mo", "tilt": {"craft": 2}, "gain": {"items": {"ess_wood": 3, "ess_dark": 3}},
				"desc": "Every poison is a medicine somebody has not understood yet. Carry the roots home in wet moss (wood and dark essences) and let the alchemist learn what she knew.",
				"log": "Carried the Marsh Hag's poison garden home to Alchemist Mo."},
			{"id": "burn", "label": "Burn it where it stands", "tilt": {"craft": -2}, "gain": {"renown": 3},
				"desc": "Some knowledge is better lost. Fire the beds and salt the ash, the way the marsh villages have always dealt with a witch's ground. They will thank you (renown).",
				"log": "Burned the Marsh Hag's poison garden and salted the ash."},
		],
		"after": {
			"study": [["Narrator", "It takes until dusk: nine beds, lifted root by root into wet moss. The marsh watches the two of them go with its whole garden on their backs."], ["Yue Ling", "Do not lick your fingers. I mean it. Not for a week."]],
			"burn": [["Narrator", "The beds burn green, then violet, then with no colour at all, and the smoke lies down along the water instead of rising."], ["Yue Ling", "Sixty years of somebody's work. It was wicked work. I still do not like watching sixty years burn."]],
		},
		"echo": {
			"s_antidote": {
				"study": [["Alchemist Mo", "And the roots from her garden. I have had the first bed in pots for three days. Do you know she had bred a wolfsbane that cures the fever it causes? I have been an alchemist forty years and I feel like an apprentice."]],
				"burn": [["Alchemist Mo", "You burned her garden, I hear. Well. It was the safe thing. I will only say that I shall spend the rest of my life wondering what was in the seventh bed."]],
			},
			"pre:poison_mother": {
				"study": [["Narrator", "Lin Feng knows this smell. It grew in the seventh bed of a garden in the marsh, and Alchemist Mo has had a pot of it on his windowsill for years, and a salve made from it in the bottom of Lin Feng's pack."]],
				"burn": [["Narrator", "Lin Feng knows this smell. It grew once in a garden in the marsh, in the seventh bed, and he watched it burn, and nobody alive now knows what it was for."]],
			},
		},
		"end": {"study": "The Hag's garden grows in pots on Alchemist Mo's windowsill, and has cured more people than it ever killed.", "burn": "The Hag's garden was burned and salted, and what she knew went with it."}},

	"roc_egg": {"step": "s_roc", "part": "I", "n": "The Thunder Roc's egg",
		"ask": "In the Thunder Roc's nest, under the wreck of her wing, there is one egg, warm, the size of a cooking pot. What do you do?",
		"options": [
			{"id": "hatch", "label": "Carry it down to the horse-folk", "tilt": {"heart": 2}, "gain": {"renown": 2},
				"desc": "The horse-folk raise eagles. They may know how to raise this. It is a long way down the valley with a hot egg inside your robe.",
				"log": "Carried the Thunder Roc's egg down to the tents of the horse-folk."},
			{"id": "leave", "label": "Leave it to the storm", "tilt": {"craft": -1, "reach": 1},
				"desc": "The valley made the roc and the valley will make another or it will not. It is not a sweeper's business to decide which storms have children.",
				"log": "Left the Thunder Roc's egg in the nest, to the storm."},
			{"id": "sell", "label": "Sell it at Cloudfoot", "tilt": {"heart": -2}, "gain": {"stones": 400},
				"desc": "A collector at Cloudfoot will pay four hundred spirit stones for a roc's egg and not ask where its mother is. A sword wants tempering.",
				"log": "Sold the Thunder Roc's egg to a collector at Cloudfoot."},
		],
		"after": {
			"hatch": [["Narrator", "It ticks, faintly, all the way down the valley, like a kettle thinking about boiling."], ["Yue Ling", "If it hatches inside your robe I am not helping. ...I am helping a little."]],
			"leave": [["Narrator", "The wind is already rebuilding the nest round it, straw by straw, the way it must have built the first one."], ["Yue Ling", "The storm looked after the last one. It did not do so badly, until us."]],
			"sell": [["Narrator", "The collector weighs it in both hands, holds it to a candle, and counts out four hundred stones without a word. He has a shelf of such things. None of them tick."], ["Yue Ling", "...It was warm, Lin Feng."]],
		},
		"echo": {
			"s_p18_sarnai": {
				"hatch": [["Grandmother Sarnai", "And you are the one who brought us the storm-chick. It sits on the smoke-ring of Batu's tent and eats a sheep a month. The children ride it when they think I am not looking. I am always looking."]],
				"leave": [["Grandmother Sarnai", "There is a young roc in the valley again. It hatched by itself in a storm, the herders say, and was raised by nobody. It takes a foal now and then. We do not grudge it. It was here first."]],
				"sell": [["Grandmother Sarnai", "There has been no roc in the valley since the old one fell. The eagles have no one to be afraid of and have grown fat. A sky with nothing large in it is a poor sky, child."]],
			},
			"pre:leigong": {
				"hatch": [["Narrator", "Far below, small as a swallow, something storm-grey turns on the wind over the tents of the horse-folk, and the Duke of Thunder's eye follows it a moment, almost fondly."]],
				"sell": [["Narrator", "The Duke of Thunder looks down a long while at the valley that bears his name, where nothing of his has flown for years."]],
			},
		},
		"end": {"hatch": "The Thunder Roc's chick grew up on the smoke-ring of a herder's tent, and the children of the horse-folk ride it.", "leave": "A roc hatched by itself in a storm, raised by nobody, and the valley has its thunder again.",
			"sell": "A roc's egg sits on a collector's shelf at Cloudfoot. It stopped ticking long ago."}},

	"palace": {"step": "s_lord", "part": "I", "n": "The Blood Moon Palace",
		"ask": "Xu Mo is gone, and the Blood Moon Palace stands empty with its gates open. The Elder has left it to you. What becomes of it?",
		"options": [
			{"id": "seal", "label": "Seal it, as the ancestors would", "tilt": {"craft": -2, "reach": -1}, "gain": {"renown": 4},
				"desc": "Nine lotus seals on the gates and a stele in front telling what was done here, so that nobody forgets and nobody goes in. It is the old way, and every sect in the land will approve (renown).",
				"log": "Sealed the Blood Moon Palace with nine seals and a stele."},
			{"id": "open", "label": "Open it to whoever has nowhere", "tilt": {"craft": 2, "reach": 2}, "gain": {"stones": 200},
				"desc": "It is a great many roofs. The demon lord's conscripts, the valley's strays and the people the war unhoused could winter there, and pay a little for it (spirit stones). Nobody has ever done such a thing with a demon's house.",
				"log": "Opened the Blood Moon Palace to whoever had nowhere to go."},
		],
		"after": {
			"seal": [["Narrator", "The ninth seal closes with a sound like a held breath let go. The red light goes out of the windows, one by one, from the top."], ["Yue Ling", "Good. ...I think good. It is strange to lock up a house and feel as if you have buried it."]],
			"open": [["Narrator", "The first family comes up the road at dusk with a handcart, stops at the gate, and stands there. A child goes in first. Children always go in first."], ["Yue Ling", "Somebody will have to tell them which rooms not to open. I will make a list. It will be a long list."]],
		},
		"echo": {
			"pre:echo_xumo": {
				"seal": [["Echo of Xu Mo", "You sealed my house. Nine seals. I felt each one. It is very tidy of you, sweeper. You people have always preferred a locked door to an answered question."]],
				"open": [["Echo of Xu Mo", "There are children in my house. I can hear them from here: they have found the echo in the long gallery. In nine hundred years it never occurred to me that the gallery was for that."]],
			},
			"s_p14_home": {
				"seal": [["Elder Qing Xuan", "The seals on the Blood Moon Palace are holding, by the way. I go and look at them each spring. A thing shut away is not a thing settled, but it is quiet, and at my age I value quiet."]],
				"open": [["Elder Qing Xuan", "The village in the Blood Moon Palace has sent us its first disciple, by the way. A girl. Born in Xu Mo's own bedchamber, her mother tells me, with great satisfaction."]],
			},
		},
		"end": {"seal": "The Blood Moon Palace stands sealed behind nine lotuses, and the Elder looks at the seals each spring.", "open": "The Blood Moon Palace is a village now, and its children play in the demon lord's long gallery."}},

	"dragon_boon": {"step": "s_dr_king", "part": "II", "n": "The Dragon King's boon",
		"ask": "The Azure Dragon King is free, and a dragon pays his debts. He offers one boon, and says to choose with care: he will not be asked twice.",
		"options": [
			{"id": "rain", "label": "Rain for the valley, every spring", "tilt": {"reach": -2}, "gain": {"renown": 3},
				"desc": "Ask for what the farmers of Qingshi ask the sky for every year: rain on the terraces when the rice is set, for as long as there is a Dragon King. Home will remember it (renown).",
				"log": "Asked the Dragon King for rain on the valley's fields every spring."},
			{"id": "sea", "label": "A safe road for every ship", "tilt": {"reach": 2}, "gain": {"stones": 300},
				"desc": "Ask for people you will never meet: that no ship which keeps to the sea-roads be taken by storm. The harbour guilds pay well for news like that (spirit stones).",
				"log": "Asked the Dragon King for a safe road over the sea for every ship."},
		],
		"after": {
			"rain": [["Azure Dragon King", "Rain. For one valley. I offered you the sea and you ask me to water a garden. ...I had forgotten that this is what people are like. It shall rain, sweeper. It shall rain exactly enough."]],
			"sea": [["Azure Dragon King", "Not for yourself, and not for your own. For strangers in boats. Hm. Granted, and gladly: I was growing tired of wrecks. They get into the coral."]],
		},
		"echo": {
			"s_mf_intro": {
				"rain": [["Old Farmer Tian", "They say that even in this, with the sun nailed up, it rained on Qingshi at the setting of the rice. One valley in the whole land. Somebody there has a friend in the water."]],
				"sea": [["Old Farmer Tian", "My son went for a sailor rather than starve here. He writes that in all this drought not one ship has been lost on the sea-roads. Not one. He says the sailors pour wine over the side for a sweeper nobody has met."]],
			},
			"s_p12_home": {
				"rain": [["Elder Qing Xuan", "The sea is no friend of ours, child. You asked its king for rain once, and he gave it, and the bargain ended there. Go carefully."]],
				"sea": [["Elder Qing Xuan", "You will find the sea knows your name. Every pilot between here and the isles sails on a promise you were given, and sailors do not forget who their luck belongs to."]],
			},
		},
		"end": {"rain": "It rains on Qingshi every spring at the setting of the rice, exactly enough, by a dragon's word.", "sea": "No ship that keeps the sea-roads has been lost since, and sailors pour wine over the side for a sweeper they never met."}},

	"drawings": {"step": "s_fg_engine", "part": "IV", "n": "The engine's drawings",
		"ask": "Inside the wreck of the Brass Spider Engine is a case of drawings: every gear of it, in Heaven's own hand. Nothing like it exists below. What do you do with them?",
		"options": [
			{"id": "keep", "label": "Carry them down to Smith Tie", "tilt": {"craft": 3}, "gain": {"stones": 500},
				"desc": "Heaven built this to count mortals. Mortals might build it to do something better. Tie will pay for the bronze-work alone (spirit stones), and will not sleep for a month.",
				"log": "Carried the drawings of the Brass Spider Engine down to Smith Tie."},
			{"id": "burn", "label": "Put them in the forge", "tilt": {"craft": -3}, "gain": {"renown": 4},
				"desc": "A thing that walks by itself and counts people is a thing nobody should know how to build. Feed the case to Heaven's own fire. The old sects will call it wisdom (renown).",
				"log": "Burned the drawings of the Brass Spider Engine in Heaven's own forge."},
		],
		"after": {
			"keep": [["Narrator", "The case is lighter than it looks. The drawings are on something that is not quite silk, in ink that is not quite black, and every line is the same width from one end to the other."], ["Yue Ling", "Tie is going to cry. He is going to unroll the first one and cry on it, and then shout at us for letting him."]],
			"burn": [["Narrator", "They do not burn like paper. They curl, and each line glows a moment after the sheet has gone, so that for a breath the whole engine hangs in the fire, drawn in light."], ["Yue Ling", "There. Now nobody can make another. ...Somebody made the first without any drawings at all, of course."]],
		},
		"echo": {
			"pre:forge_tiangong": {
				"keep": [["Forge-Lord Tian Gong", "You have my drawings in your pack. I can smell the ink. Thief. ...No. Apprentice. Nobody steals a drawing who does not mean to build."]],
				"burn": [["Forge-Lord Tian Gong", "You burned my drawings. Forty years of them. I felt the forge take them. You are afraid of what hands can do, little sweeper. So am I. It never once stopped me."]],
			},
			"s_p19_forge": {
				"keep": [["Forgemaster Ou Lan", "You carried its drawings down to the smith, I am told. Good. Then somebody below knows where its linchpin is, which is more than Heaven ever troubled to write on the thing itself."]],
				"burn": [["Forgemaster Ou Lan", "You burned its drawings in my own fire; I watched the lines hang in the flame. I thought at the time it was wisdom. It means that tonight nobody alive knows how the thing is put together, and we must take it apart by guessing."]],
			},
			"s_p19_ban": {
				"keep": [["Gongshu Ban", "Tie showed me the drawings you brought down out of Heaven. I have had them on my bench a month. Whoever drew them never once held a chisel: every joint is perfect and not one of them could be cut. I have been correcting them. It is the happiest I have been in years."]],
				"burn": [["Gongshu Ban", "Tie tells me you once burned a case of Heaven's own drawings sooner than carry them down. I should like to be angry. But I have built a thing or two I wish I had burned first. We will talk about that, you and I."]],
			},
		},
		"end": {"keep": "Heaven's drawings lie on a carpenter's bench, corrected in charcoal by a man who has held a chisel.", "burn": "The drawings of the Brass Spider Engine burned in Heaven's forge, each line glowing a moment after the page was gone."}},

	"nineteen": {"step": "s_gd_nineteen", "part": "IV", "n": "The names of the Nineteen",
		"ask": "The Nineteen are free of their names, and the names are left over: nineteen strips of jade, warm, with nobody attached. What should be done with them?",
		"options": [
			{"id": "stele", "label": "Set them in the wall of the sect", "tilt": {"reach": -2}, "gain": {"renown": 3},
				"desc": "Let them be remembered where their sect can see them: nineteen strips of jade in the wall of the ancestral hall, and incense on the days that matter.",
				"log": "Set the names of the Nineteen in the wall of the ancestral hall."},
			{"id": "wind", "label": "Give them to the wind", "tilt": {"reach": 2, "heart": 1},
				"desc": "They spent three thousand years pinned to those names. Throw the jade off the edge of the garden and let each name fall wherever in the world it likes.",
				"log": "Gave the names of the Nineteen to the wind over the edge of the Garden."},
		],
		"after": {
			"stele": [["Narrator", "Nineteen strips of jade go into the pack, wrapped in a sleeve, and are heavier than nineteen strips of jade should be."], ["Yue Ling", "They will like the hall. It is quiet, and old Shen rings the bell on time."]],
			"wind": [["Narrator", "They fall slowly, turning, catching the light, and do not all fall the same way. One goes east. Three go north together. One drops straight down, in a hurry."], ["Yue Ling", "That one knew exactly where it was going."]],
		},
		"echo": {
			"pre:king_yama": {
				"stele": [["King Yama, Lord of the Wheel", "Nineteen names are missing from my book and present in your wall. I have let it stand. A wall is a kind of book, and yours is better kept than mine has been."]],
				"wind": [["King Yama, Lord of the Wheel", "Nineteen names came down on my Wheel out of a clear sky, like hail, in nineteen different places. My clerks are still finding them. I gather that was you."]],
			},
			"s_p17_home": {
				"stele": [["Elder Qing Xuan", "Tomorrow I light incense at the nineteen strips in the hall wall, as I do each year. The jade is still warm. I have stopped being surprised by it."]],
				"wind": [["Elder Qing Xuan", "A farmer at Longmen ploughed up a strip of warm jade this winter with a name on it nobody could read. He has built it a little shrine. That makes eleven found. The other eight, I suppose, did not wish to be."]],
			},
		},
		"end": {"stele": "Nineteen strips of warm jade are set in the wall of the ancestral hall, and incense is lit to them.", "wind": "The names of the Nineteen fell wherever they liked, and eleven little shrines stand where farmers ploughed them up."}},

	"ancestor": {"step": "s_ch_took", "part": "V", "n": "The Ancestor Who Took",
		"ask": "The Ancestor Who Took has been refused, and his tablet still stands in the sect's hall, third from the left, with incense in front of it. What is done with it?",
		"options": [
			{"id": "strike", "label": "Strike his name from the lineage", "tilt": {"heart": -3}, "gain": {"renown": 4},
				"desc": "He stole from his own descendants for a thousand years. Take the tablet down, plane the name off it and burn the shavings. Let the gap in the row say what he was.",
				"log": "Struck the Ancestor Who Took from the lineage of the sect."},
			{"id": "truth", "label": "Leave it, with the truth written under it", "tilt": {"heart": 3},
				"desc": "He was theirs, and what he did was theirs too. Leave the tablet where it stands and carve under it, in plain characters, what he took and from whom. Incense or not, as each sees fit.",
				"log": "Left the Ancestor's tablet standing, with what he did carved under it."},
		],
		"after": {
			"strike": [["Narrator", "The plane takes the name off in one long curl of old lacquer. The wood underneath is pale, and looks very new."], ["Yue Ling", "The row looks like a mouth with a tooth out. I suppose that is the point."]],
			"truth": [["Narrator", "It takes Lin Feng a whole evening with a small chisel. He is not a carver; the characters wander. Nobody who reads them will mistake what they say."], ["Yue Ling", "He will hate that much more than being forgotten. Good."]],
		},
		"echo": {
			"pre:nie": {
				"strike": [["Nie, the Unpaid", "You planed a name out of your own lineage. I felt that debt fall into my hands unpaid, like all the rest. You do not settle accounts, sweeper. You tear out the page."]],
				"truth": [["Nie, the Unpaid", "There is a tablet in your hall with a debt carved under it in a bad hand. I have looked for my share of it and there is none. Somebody wrote it down. That is all I ever asked of anybody."]],
			},
		},
		"end": {"strike": "There is a gap in the row of tablets in the ancestral hall, third from the left, and the juniors are told why.", "truth": "A tablet stands in the ancestral hall with the truth carved under it in a sweeper's wandering hand."}},

	"widow": {"step": "s_mp_willow", "part": "VI", "n": "The Willow Widow",
		"ask": "The Willow Widow has let go of the bank. She asks one thing before she crosses: did he wait for her on the other side, the husband she waited sixty years for? Lin Feng has seen the ferry lists. He did not.",
		"options": [
			{"id": "truth", "label": "Tell her the truth", "tilt": {"heart": -1, "reach": 1},
				"desc": "He drank the soup and went on at once, sixty years ago, as almost everybody does. She waited for a man who had already forgotten how to wait. She asked, and she is owed an answer.",
				"log": "Told the Willow Widow that her husband had not waited."},
			{"id": "kind", "label": "Tell her he is waiting", "tilt": {"heart": 2},
				"desc": "It is a short crossing, and she will drink the soup herself on the other side and need no answers after that. Let her cross it glad.",
				"log": "Told the Willow Widow that her husband was waiting on the far bank."},
		],
		"after": {
			"truth": [["The Willow Widow", "...Ah. No. Of course he did not. He never could sit still, that man. He would not even wait for the rice to finish."], ["Narrator", "She laughs, once, the way a rope laughs when the weight comes off it, and walks down to the ferry by herself."]],
			"kind": [["The Willow Widow", "Then I have kept him long enough. Sixty years! He will be impossible about it."], ["Narrator", "She goes down to the ferry almost running, tidying her hair. Lin Feng watches the boat all the way across, and does not look at Yue Ling."]],
		},
		"echo": {
			"pre:reed_widow": {
				"truth": [["Widow of the Reed Ford", "You are the one who told the Willow Widow the truth. It came down the river with the ferrymen. Good. Then I will have it from you too, plain, whatever it is."]],
				"kind": [["Widow of the Reed Ford", "You are the one who sent the Willow Widow over smiling. It came down the river with the ferrymen. I will thank you not to be kind to me, young man. I can tell when I am being managed."]],
			},
		},
		"end": {"truth": "The Willow Widow crossed knowing, and laughing, by herself.", "kind": "The Willow Widow crossed tidying her hair, to a husband who was not there, and never knew it."}},

	"crows": {"step": "s_mg_marshal", "part": "VIII", "n": "The Crow Marshal's flock",
		"ask": "The Crow Marshal has fallen, and ten thousand crows who held the broken bridge on his orders sit along the bank of the River of Heaven, waiting to be told what they are now.",
		"options": [
			{"id": "pardon", "label": "Bridge-builders, with the magpies", "tilt": {"heart": 2, "reach": 1},
				"desc": "A crow can carry a twig as well as a magpie. Let them work beside the birds they blockaded, wing to wing, until the bridge stands. The magpies will not like it.",
				"log": "Set the Crow Marshal's flock to building the bridge beside the magpies."},
			{"id": "banish", "label": "Banished from the River of Heaven", "tilt": {"heart": -2}, "gain": {"renown": 4},
				"desc": "They kept two lovers apart for a marshal's pride. Let no crow roost within sight of the River again. The magpies will sing of it for a hundred years (renown).",
				"log": "Banished the Crow Marshal's flock from the River of Heaven."},
		],
		"after": {
			"pardon": [["Narrator", "For a long moment nothing moves. Then one crow, an old one with a white feather, hops down the bank, picks up a twig, and carries it out along the broken span with enormous dignity."], ["Yue Ling", "The magpies are pretending not to see. All ten thousand of them. It is the loudest silence I have ever heard."]],
			"banish": [["Narrator", "They go up all at once, like a cloak thrown off, and the sky over the River of Heaven is black with them, and then it is not, and it is very quiet."], ["Yue Ling", "They only did as they were told. ...So did everybody we have ever fought, I know. I know."]],
		},
		"echo": {
			"pre:jinwu": {
				"pardon": [["Jinwu, the Three-Legged Sun Crow", "My cousins on the River of Heaven carry twigs beside magpies now, and are insufferable about it. They say a sweeper told them a crow could build. Nobody ever told a crow that before."]],
				"banish": [["Jinwu, the Three-Legged Sun Crow", "My cousins came east to me from the River of Heaven with nowhere to roost. Ten thousand of them, in my tree. You sent them. I have not forgotten whose word it was."]],
			},
		},
		"end": {"pardon": "Crows and magpies build the bridge together each seventh month now, and quarrel the whole time.", "banish": "No crow roosts within sight of the River of Heaven, and the magpies sing of it."}},

	"axe": {"step": "s_gh_wugang", "part": "IX", "n": "Wu Gang's axe",
		"ask": "Wu Gang has put down his axe: three thousand years old, and it has never needed sharpening. He does not want it back. What becomes of an axe that cuts anything and never dulls?",
		"options": [
			{"id": "give", "label": "Take it down to the woodcutters", "tilt": {"craft": 2, "reach": 1}, "gain": {"renown": 2},
				"desc": "The woodcutters of Qingshi go through three axe-heads a winter. One axe that never dulls, passed from hand to hand, would keep a village warm for ever.",
				"log": "Carried Wu Gang's axe down to the woodcutters of Qingshi."},
			{"id": "leave", "label": "Leave it in the cassia", "tilt": {"craft": -2},
				"desc": "An axe that cuts anything is not a tool; it is a temptation with a handle. Drive it into the cassia tree, which closes over every wound, and let the tree keep it.",
				"log": "Left Wu Gang's axe in the cassia tree on the moon."},
		],
		"after": {
			"give": [["Wu Gang, Woodcutter of the Moon", "Tell them not to hurry. It will cut whatever they put in front of it, and that is not always a kindness. I never once chose what to cut. Let them choose."]],
			"leave": [["Wu Gang, Woodcutter of the Moon", "Yes. Let the tree have it. Three thousand years it has been trying to swallow that axe a little at a time. It has earned it."]],
		},
		"echo": {
			"s_p16_home": {
				"give": [["Elder Qing Xuan", "The woodcutters ask me to tell you the Moon Axe has gone round every house in Qingshi twice this winter, and there is firewood stacked to the eaves. They have cut nothing they did not need. I asked. They looked at me as if I were simple."]],
				"leave": [["Elder Qing Xuan", "It has been a hard winter for firewood in Qingshi. The woodcutters broke four axe-heads on the frozen oak. They say nothing, but I think they have heard there was once an axe that would not have broken."]],
			},
			"s_p19_gardener": {
				"give": [["The Gardener of Hanyin", "I know about the Moon Axe. An axe that does all the work, in a village that has still never cut one tree too many. So it can be done. I did not say it could not be done. I said it was rare, and that nobody tries."]],
				"leave": [["The Gardener of Hanyin", "You are the one who left the Moon Axe in the tree. Then you understand me already, and I do not know why you have come to argue."]],
			},
		},
		"end": {"give": "The Moon Axe goes from house to house in Qingshi each winter, and has never cut one tree too many.", "leave": "The cassia tree on the moon has closed over Wu Gang's axe at last."}},

	"cauldron_map": {"step": "s_ts_taotie", "part": "X", "n": "The map on the cauldrons",
		"ask": "The Taotie is back on its cauldron and the map of the nine provinces is whole: every river, pass and ford in the land, cast in bronze by Yu the Great. The founders of Tushan have kept it to themselves for four thousand years. They ask what you think.",
		"options": [
			{"id": "copy", "label": "Take rubbings for every town", "tilt": {"reach": 3, "craft": 1}, "gain": {"stones": 800},
				"desc": "A map nobody can read is a lump of bronze. Ink the cauldrons, take rubbings, and send one to every town with a road. The caravan-masters will pay for the first copies (spirit stones).",
				"log": "Took rubbings of Yu's map from the Nine Cauldrons for every town in the land."},
			{"id": "keep", "label": "Let it stay at Tushan", "tilt": {"reach": -3}, "gain": {"renown": 4},
				"desc": "Yu gave it to the founders to keep. Whoever holds the map of every ford holds the land, and for four thousand years nobody has, because nobody could get at it. The founders will honour you (renown).",
				"log": "Left Yu's map on the Nine Cauldrons, in the keeping of the founders of Tushan."},
		],
		"after": {
			"copy": [["Narrator", "The first rubbing comes off the bronze like a skin: black, and on it in white every river in the land, finer than any brush could draw."], ["Yue Ling", "Look. There is our mountain. It is the size of a sesame seed. I am not sure how I feel about that."]],
			"keep": [["Narrator", "The founders lower the great lid back over the ninth cauldron, all six of them on the chain, and the map goes into the dark it has been in since Yu."], ["Yue Ling", "Some things are safer as a secret. ...I only wish safe and useful were the same thing more often."]],
		},
		"echo": {
			"s_p13_home": {
				"copy": [["Elder Qing Xuan", "One thing in our favour. Every town in the land has Yu's map on its wall now, thanks to you, and so every town knows where the Eight Gates have opened and which road is still clear. The news is three days ahead of the war."]],
				"keep": [["Elder Qing Xuan", "The Gates have opened in eight places, and no town knows where the other seven are. There is one map that would show them, and it is under a bronze lid at Tushan, where you and the founders agreed it should stay."]],
			},
			"s_p18_kang": {
				"copy": [["Caravan-Master Kang", "I found the crossing-place on the rubbing you sent round. Yu marked it: the one spot in the land where a road from every province meets. Four thousand years on a cauldron, and it turns out to be a cabbage field at Cloudfoot."]],
				"keep": [["Caravan-Master Kang", "I have chosen the ground by guesswork and forty years of sore feet. There is a map that would have told me in a moment. I hear it is very safe."]],
			},
		},
		"end": {"copy": "Yu's map hangs on a wall in every town, and children find their own village on it with one finger.", "keep": "Yu's map lies under its bronze lid at Tushan, as safe as it has been for four thousand years."}},

	"furnace": {"step": "s_fz_furnace", "part": "XII", "n": "The furnace that walked away",
		"ask": "The Elixir Furnace is caught: three bronze legs folded under it, steaming sulkily. It walked off, it says, in a voice like a kettle, because in nine hundred years nobody asked it whether it wished to make elixirs. The immortals want it back.",
		"options": [
			{"id": "free", "label": "Let it walk", "tilt": {"heart": 2, "craft": -1},
				"desc": "It was made, and it was never asked. Open your hands and let it go where a furnace goes. The immortals of Fangzhang will have to learn to light their own fires.",
				"log": "Let the Elixir Furnace walk away from Fangzhang."},
			{"id": "return", "label": "Carry it home to its masters", "tilt": {"craft": 2, "heart": -1}, "gain": {"items": {"hp_pill": 4, "qi_pill": 2}},
				"desc": "A furnace is for making elixirs, and a great many sick people are waiting on what this one makes. Carry it back. The immortals will be generous (pills).",
				"log": "Carried the Elixir Furnace home to the immortals of Fangzhang."},
		],
		"after": {
			"free": [["Narrator", "It stands up on its three legs, steams once, thoughtfully, and stumps off along the shore. It does not seem to know where it is going. It seems delighted about that."], ["Yue Ling", "...I was made for something too. Nobody asked me either. Go on, furnace."]],
			"return": [["Narrator", "It does not struggle. It folds its legs tighter and lets itself be carried, heavy and warm, and says nothing at all, all the way up the hill."], ["Yue Ling", "It is for making elixirs. I know. ...I am for something too, Lin Feng. I should like, some day, to be asked."]],
		},
		"echo": {
			"pre:the_player": {
				"free": [["The Player", "There is a furnace walking the shore of an island in the east. The gulls told the kites and the kites told me. Somebody opened his hands and let it go. I have wanted to meet him."]],
				"return": [["The Player", "There was a furnace once that walked away, and somebody carried it back to its work. The kites told me. It makes excellent elixirs. It has not spoken since. I have wanted to meet him too."]],
			},
		},
		"end": {"free": "An elixir furnace walks the shore of Fangzhang on three legs, making nothing, perfectly content.", "return": "The Elixir Furnace is back on its hearth at Fangzhang. It makes excellent elixirs, and has not spoken since."}},

	# ---- Part XIX: the Machine Heart
	"the_wheel": {"step": "s_p19_mites", "part": "XIX", "n": "The wheel at Qingshi",
		"ask": "Gongshu Ban's wheel grinds the valley's rice in a tenth of the time, and at night, with nobody at it, things have got into it. Qingshi has come out to the mill-race in the dark and wants to be told what to do with its wheel.",
		"options": [
			{"id": "run", "label": "Let it run, night and day", "tilt": {"craft": 3}, "gain": {"stones": 3000},
				"desc": "A wheel does not get tired. Post a watch on it, grease it, and let the river work while the valley sleeps: twice the rice, and time for everything else (the valley pays its share in spirit stones). Whatever comes to live in it can be dealt with as it comes.",
				"log": "Told Qingshi to let the wheel run night and day, with a watch on it."},
			{"id": "hours", "label": "By day it turns; at dusk the gate comes down", "tilt": {"craft": 1, "reach": -1}, "gain": {"renown": 4},
				"desc": "The valley has hours. Let the wheel have them too: the sluice opened at dawn by whoever is first up, and shut at dusk by whoever is last home, so that somebody's hand is always the reason it turns. The valley will talk of it (renown).",
				"log": "Told Qingshi to give the wheel hours: opened at dawn, shut at dusk, by hand."},
			{"id": "down", "label": "Take it down", "tilt": {"craft": -3}, "gain": {"items": {"catalpa_timber": 2}},
				"desc": "The valley ground its rice by hand for a thousand years and was not unhappy. Lift the wheel out of the race, stack the timber (two baulks of the catalpa are yours), and let the old gardener be right.",
				"log": "Told Qingshi to take the wheel down and stack the timber."},
		],
		"after": {
			"run": [["Farmer Lao", "Night and day. And one of us to sit up with it. Well, we sat up with the new fire. I suppose a wheel is not so different. It is only colder company."], ["Narrator", "The wheel goes on turning in the dark, with a lantern hung beside it now, and a boy with a grease-pot who is trying very hard to stay awake."]],
			"hours": [["Farmer Lao", "Opened by the first up and shut by the last home. Hah. Then it will be my wife who opens it and my son who shuts it, till the end of time."], ["Narrator", "The sluice-gate comes down. The wheel slows, drips, and stands. In the quiet, for the first time in a month, Qingshi can hear its own river."]],
			"down": [["Farmer Lao", "Down. After a month of white rice by noon. ...No, you are right. My father ground by hand and so did his. I only wish I had never found out how long it took."], ["Narrator", "It takes the whole village until dawn. The wheel comes out of the race in eight pieces and is stacked against the mill wall, where it looks like nothing but good timber."]],
		},
		"echo": {
			"s_p19_tushan": {
				"run": [["Auntie Rong of the Smelting Pits", "And you told Qingshi to let theirs run all night, I hear. So you will not be telling me to stop mine. Good. Then tell me instead why my founders have forgotten how to sit down."]],
				"hours": [["Auntie Rong of the Smelting Pits", "I hear Qingshi shuts its wheel at dusk now, by hand, on your say. Hm. Mine have no gate. Nobody thought a hammer would need to be told when to go to bed."]],
				"down": [["Auntie Rong of the Smelting Pits", "You had Qingshi pull theirs down. Do not look at my hammers like that, sweeper. A mill is a mill. This is the pit that cast Yu's cauldrons, and it will be worked however it can be worked."]],
			},
			"s_p19_end": {
				"run": [["Elder Qing Xuan", "The wheel at Qingshi has not stopped since you told them to let it run, and there is a rota for sitting up with it, which the children fight over. They have given it a name. I am told it is not a respectful name."]],
				"hours": [["Elder Qing Xuan", "I walked down to Qingshi at dusk to see the sluice shut. The whole village stops to watch. Nobody told them to. It has become the thing they do at the end of a day, like looking at the sky."]],
				"down": [["Elder Qing Xuan", "The timber of the wheel is still stacked against the mill wall at Qingshi. Nobody has burned it. Farmer Lao oils it each autumn. He says it is in case. He does not say in case of what."]],
			},
		},
		"end": {"run": "The wheel at Qingshi runs night and day, with a child sitting up beside it and a name that is not respectful.", "hours": "The wheel at Qingshi is opened at dawn and shut at dusk by hand, and the whole village stops to watch.",
			"down": "The timber of Qingshi's wheel is stacked against the mill wall, and oiled each autumn, in case."}},

	"the_player": {"step": "s_p19_player", "part": "XIX", "n": "The Player's heart",
		"ask": "The Player lies in the sand with its chest open. Inside, where Yan Shi left a hollow, is a heart it built for itself out of the escapements of every machine in the land: it ticks. It asks whether it may keep it.",
		"options": [
			{"id": "keep", "label": "It is yours. You made it", "tilt": {"heart": 3, "craft": 1},
				"desc": "Nobody is given a heart with leave to use it. It made this one itself, badly, out of what it could find, and that is the only way anybody ever has. Close its chest and help it up.",
				"log": "Told the Player its heart was its own, and helped it up."},
			{"id": "maker", "label": "That is for your maker to say", "tilt": {"reach": -1, "heart": -1},
				"desc": "It is Yan Shi's work, and Yan Shi is standing there. A thing that is made answers to who made it. Step back and let the old artificer decide.",
				"log": "Left the Player's heart to Yan Shi, who made it."},
			{"id": "still", "label": "Take it out", "tilt": {"heart": -3, "craft": -1}, "gain": {"renown": 5},
				"desc": "That heart is every stopped loom and sleepless founder in the land. Lift it out and give the escapements back to the machines they came from. The Player will be a wonder of wood and lacquer again, and nothing more (renown).",
				"log": "Took the heart out of the Player and gave its pieces back to the machines."},
		],
		"after": {
			"keep": [["The Player", "Mine. ...It runs a little fast. I think that is what you call being glad."], ["Yue Ling", "It runs fast for a long time. You get used to it. Come and sit up; I will show you how to breathe as if you needed to."]],
			"maker": [["Yan Shi the Artificer", "Mine to say. Yes. I took it apart once in front of a king to save my own neck. I suppose I have the right. ...I find I do not want the right. Get up, child. Keep it. I should like to hear what you think of me."]],
			"still": [["Narrator", "It comes out in Lin Feng's two hands, still ticking, and then, piece by piece, not. The Player's painted eyes stay open. They are very well painted."], ["Yue Ling", "..."], ["Yue Ling", "I know why. I know every reason why. Do not ask me to talk about it tonight."]],
		},
		"echo": {
			"pre:jixin": {
				"keep": [["Narrator", "At the edge of the firelight a slight lacquered figure has come up the hill by itself, and stands with one hand flat on its own chest, listening, as the great thing in the pit turns towards it."]],
				"maker": [["Narrator", "Yan Shi has come up the hill behind them, an old man out of breath, with the Player carrying his tool-roll and steadying him by the elbow."]],
				"still": [["Narrator", "Yan Shi has come up the hill behind them, alone, carrying a long box with a painted face in it. He does not look at Lin Feng. He has brought it, he says, because it ought to see."]],
			},
		},
		"end": {"keep": "The Player kept the heart it made, which runs a little fast, and has opened a school of dancing at Shazhou.", "maker": "Yan Shi gave the Player back its heart, and it tells him every day exactly what it thinks of him.",
			"still": "The Player stands in a long box at Shazhou, a wonder of wood and lacquer, with its painted eyes open."}},

	"the_works": {"step": "s_p19_heart", "part": "XIX", "n": "What the land does with its machines",
		"ask": "The Machine Heart is quiet, and the makers of six towns are standing in the casting yard at Tushan with their hands empty, looking at you. Somebody has to say what the land does with its machines now. Only what you have built with your own hands can you speak for.",
		"options": [
			{"id": "hand", "label": "The hand first", "need": [["works", "hand", 3]], "tilt": {"craft": -2, "reach": -1},
				"desc": "Speak as a maker of the old tools. Let no machine do what nobody living can still do by hand: every miller able to grind, every founder able to blow a fire with his own lungs, and the machine a helper to somebody who does not need it.",
				"log": "Answered for the Hand: no machine does what nobody can still do without it."},
			{"id": "wheel", "label": "The wheel, kept by hours", "need": [["works", "wheel", 3]], "tilt": {"craft": 3},
				"desc": "Speak as a builder of engines. Build them, and build more: but every engine has a keeper with a name, a gate that shuts, and hours, like a shop or a temple. A machine with nobody answerable for it is a stray.",
				"log": "Answered for the Wheel: build, and give every engine a keeper, a gate and hours."},
			{"id": "dao", "label": "The Dao in the tool", "need": [["works", "dao", 3]], "tilt": {"craft": 1, "reach": 2},
				"desc": "Speak as an artificer of the Dao. Cook Ding's knife never dulled in nineteen years because he was not cutting: he was following. Teach the makers that. A tool used with the whole heart takes no heart from its user.",
				"log": "Answered for the Art: a tool used with the whole heart takes none from its user."},
			{"id": "ask", "label": "It is not mine to say. Ask the gardener", "tilt": {"heart": 1},
				"desc": "You have not built enough of any school to speak for it (three works of one school would do). Send for the old man of Hanyin, who has thought about one well-sweep for sixty years, and let the makers argue it out with him.",
				"log": "Left the question to the makers and the Gardener of Hanyin."},
		],
		"after": {
			"hand": [["Auntie Rong of the Smelting Pits", "Every founder to blow a pit with his own lungs once a year. They will curse you. ...I shall go first. I want to see whether I still can."], ["Gongshu Ban", "A machine for people who do not need it. That is the hardest brief anybody ever gave me. I accept."]],
			"wheel": [["Gongshu Ban", "A keeper, a gate and hours. I have built ten thousand things and not one of them had a door to shut. I thought a door was an admission the thing was dangerous. Well. It is. Carve my name on the wheel at Qingshi; I will keep that one myself."], ["Mozi", "And when the keeper dies? ...No, do not answer. Somebody will have to think about it every generation. Perhaps that is the answer."]],
			"dao": [["Mozi", "Following, not cutting. I have spent my life measuring what a thing is good for, and you tell me it depends on who is holding it. It is most inconvenient. I believe it is also true."], ["Gongshu Ban", "I knew a wheelwright once who said he could not teach his own son the trick of it: not too slow, not too fast, the hand finds it and the heart answers. I thought he was a bad teacher."]],
			"ask": [["The Gardener of Hanyin", "Me? I carry a pitcher. I have never built so much as a gate. ...Sit down, all of you. If I am to talk to carpenters I shall want tea, and it will take as long as it takes."], ["Narrator", "They are still talking when the moon comes up: a gardener, a carpenter, a man in straw sandals and five tired makers, and nobody has yet agreed with anybody."]],
		},
		"echo": {
			"s_p19_silk": {
				"hand": [["Silk Farmer Can Niang", "The hand first, they tell me you said. Then you have spoken for every woman who ever threw a shuttle, whether you knew it or not. I shall weave you a sash. By hand. It will take a month and you will wait for it."]],
				"wheel": [["Silk Farmer Can Niang", "A keeper, a gate and hours. Well, a loom has always had a keeper: she is sitting at it. It is only that nobody ever wrote her name on the beam. I shall write mine tonight."]],
				"dao": [["Silk Farmer Can Niang", "The whole heart in the tool. Hm. Watch a girl weave in her third year, when her hands have stopped asking her head. You did not need a sage for that, child. You needed an aunt."]],
				"ask": [["Silk Farmer Can Niang", "And you sent them all to ask an old man with a pitcher. Men! Nine days they talked. Did one of them think to ask a weaver? We settled the question of machines a thousand years ago. The answer is: only while I am watching."]],
			},
			"s_p19_gardener2": {
				"hand": [["The Gardener of Hanyin", "They tell me you said no machine should do what nobody can still do by hand. That is not what I said, sixty years ago. It is better. I only said no."]],
				"wheel": [["The Gardener of Hanyin", "A keeper, a gate and hours. Hm. Then it is not a machine any more; it is a mule. I have nothing against mules. You have to know one's name to work it."]],
				"dao": [["The Gardener of Hanyin", "The whole heart in the tool, so there is none left over for the tool to take. I have carried this pitcher that way for sixty years and never knew it had a name."]],
				"ask": [["The Gardener of Hanyin", "You sent a yard full of carpenters to ask an old man who waters cabbages. We talked for nine days. I lost, I think. I have never enjoyed anything so much."]],
			},
			"post:s_break24": {
				"hand": [["Narrator", "And what the storm leaves in Lin Feng's hands, when it has gone, is nothing: two empty palms with a sweeper's calluses on them, that could make a fire, a cord or a roof out of whatever they were given."]],
				"wheel": [["Narrator", "And what the storm leaves, when it has gone, is a sound from far below, small and regular: a wheel on a river, turning, with somebody awake beside it."]],
				"dao": [["Narrator", "And when the storm has gone the sword is back in its sheath, and Lin Feng cannot remember drawing it or putting it away: only that for a while there was no edge between the blade, the hand and the sky."]],
				"ask": [["Narrator", "And when the storm has gone there is nothing changed at all, except that Lin Feng is quite sure, for the first time, that he does not need to be the one who answers."]],
			},
		},
		"end": {"hand": "The land keeps its machines as helpers to people who do not need them, and every founder blows a pit by lung once a year.", "wheel": "Every engine in the land has a keeper with a name, a gate that shuts, and hours.",
			"dao": "The makers of the land are taught to follow and not to cut, and their tools take nothing from them.", "ask": "The makers and the Gardener of Hanyin are still arguing about machines, and have never enjoyed anything so much."}},
}
const ORDER := ["bandits", "garden", "roc_egg", "palace", "dragon_boon", "drawings", "nineteen", "ancestor", "widow", "crows", "axe", "cauldron_map", "furnace",
	"the_wheel", "the_player", "the_works"]

# ---------------------------------------------------------------- the crossroads
static func option(id: String, oid: String) -> Dictionary:
	for o in CROSSROADS.get(id, {}).get("options", []):
		if str(o.id) == oid:
			return o
	return {}

## What was chosen at crossroads `id` ("" if it has not been reached).
static func chosen(g, id: String) -> String:
	return str(g.picks.get(id, ""))

## The crossroads waiting to be answered now: its step is done and nothing has been chosen.
static func waiting(g) -> String:
	for id in ORDER:
		if not g.picks.has(id) and g.done(str(CROSSROADS[id].step)):
			return id
	return ""

## Whether option `o` can be taken (the last question of Part XIX may only be answered for a school
## by somebody who has built three works of it).
static func option_ok(g, o: Dictionary) -> bool:
	for n in o.get("need", []):
		if str(n[0]) == "works":
			if Works.count(g, str(n[1])) < int(n[2]):
				return false
		elif not Trials.need_met(n, g):
			return false
	return true

## What an option needs and gives, in words, for the choice screen.
static func option_text(g, o: Dictionary) -> String:
	var parts: Array = [str(o.desc)]
	for n in o.get("need", []):
		if str(n[0]) == "works":
			parts.append("%s %d works of %s (you have %d)" % ["[x]" if option_ok(g, o) else "[ ]", int(n[2]), str(Works.SCHOOLS[n[1]].n), Works.count(g, str(n[1]))])
	var tips: Array = []
	for sc in o.get("tilt", {}):
		var v := int(o.tilt[sc])
		tips.append(str(SCALES[sc].pos if v > 0 else SCALES[sc].neg).to_lower().trim_prefix("of "))
	if not tips.is_empty():
		parts.append("Leans towards: " + ", ".join(tips) + ".")
	return "\n".join(parts)

## Take option `oid` at crossroads `id`: remembered, its scales tipped, what it gives given.
static func take(g, id: String, oid: String) -> void:
	var o := option(id, oid)
	if o.is_empty() or g.picks.has(id):
		return
	var before := {}
	for sc in SCALE_ORDER:
		before[sc] = lean(g, sc)
	g.picks[id] = oid
	for sc in o.get("tilt", {}):
		g.scales[sc] = int(g.scales.get(sc, 0)) + int(o.tilt[sc])
	Fate.gain(g, o)
	g.note("Crossroads (%s): %s" % [str(CROSSROADS[id].n), str(o.log)])
	for sc in SCALE_ORDER:
		var now := lean(g, sc)
		if now != before[sc] and now != 0:
			var nm := str(SCALES[sc].pos if now > 0 else SCALES[sc].neg)
			g.toast("The land knows you now: %s" % nm)
			g.note("Known as %s: %s" % [nm, str(SCALES[sc].pos_text if now > 0 else SCALES[sc].neg_text)])

# ---------------------------------------------------------------- the scales
## Where scale `sc` stands: what the crossroads tipped, and what the five fated encounters added
## (every one of them who stands with Lin Feng is a point of mercy; every one who fell, one of rigour).
static func scale(g, sc: String) -> int:
	var v := int(g.scales.get(sc, 0))
	if sc == "heart":
		for th in Fate.THREAD_ORDER:
			var st := Fate.state(g, th)
			if st in Fate.ALLY:
				v += 1
			elif st in Fate.GONE:
				v -= 1
	elif sc == "reach":
		# (the qilin: kept to ride over every road, or sent home to its own herd)
		if str(g.picks.get("qilin", "")) == "ride":
			v += 1
		elif str(g.picks.get("qilin", "")) == "free":
			v -= 1
	return v

## Which way a scale leans: 1, -1, or 0 while it has not leaned far enough to matter.
static func lean(g, sc: String) -> int:
	var v := scale(g, sc)
	return 1 if v >= LEAN else (-1 if v <= -LEAN else 0)

## What the land calls him for a scale ("" while it does not lean).
static func name_of(g, sc: String) -> String:
	var l := lean(g, sc)
	if l == 0:
		return ""
	var nm := str(SCALES[sc].pos if l > 0 else SCALES[sc].neg)
	return nm if absi(scale(g, sc)) < KNOWN else nm + ", and known for it"

static func merciful(g) -> bool:
	return lean(g, "heart") > 0

static func feared(g) -> bool:
	return lean(g, "heart") < 0

## The numbers a leaning scale changes: "works_stones" (what a work costs), "regard" (how fast a
## people's regard grows), "hearth" (added to what is done for a hearth), "renown" (added to a deed's
## or a trial's renown), "open_hp" (the share of its health a pack opens a battle with), "stones" and
## "drop" (what a beaten pack gives up to somebody known to spare).
static func lean_mod(g, key: String) -> float:
	match key:
		"works_stones":
			return WORKS_STONES if lean(g, "craft") > 0 else 1.0
		"hearth":
			return float(HEARTH_MORE) if lean(g, "craft") < 0 else 0.0
		"regard":
			return REGARD_MORE if lean(g, "reach") > 0 else 1.0
		"renown":
			return float(RENOWN_MORE) if lean(g, "reach") < 0 else 0.0
		"open_hp":
			return FEAR_HP if feared(g) else 1.0
		"stones":
			return YIELD_STONES if merciful(g) else 1.0
		"drop":
			return YIELD_DROP if merciful(g) else 0.0
	return 1.0

# ---------------------------------------------------------------- echoes
## The lines conversation `key` gains from the crossroads behind it (in the order of the story).
static func lines(g, key: String) -> Array:
	var out: Array = []
	for id in ORDER:
		var ch := chosen(g, id)
		if ch == "":
			continue
		var by: Dictionary = CROSSROADS[id].get("echo", {}).get(key, {})
		if by.has(ch):
			out.append_array(by[ch])
	return out

## Conversation `key` with its echoes: `base` and then whatever the crossroads add; each echo is
## remembered (the Crossroads page lists them as they come).
static func told(g, key: String, base: Array) -> Array:
	var extra := lines(g, key)
	if extra.is_empty():
		return base
	for id in ORDER:
		var ch := chosen(g, id)
		if ch != "" and CROSSROADS[id].get("echo", {}).get(key, {}).has(ch):
			g.echoed["%s|%s" % [id, key]] = true
	var out: Array = base.duplicate()
	out.append_array(extra)
	return out

## How many echoes of crossroads `id` have been heard, and how many its choice has in all.
static func heard(g, id: String) -> Array:
	var ch := chosen(g, id)
	var n := 0
	var of := 0
	for key in CROSSROADS[id].get("echo", {}):
		if CROSSROADS[id].echo[key].has(ch):
			of += 1
			if g.echoed.has("%s|%s" % [id, key]):
				n += 1
	return [n, of]

## What the ending tells of the crossroads: one sentence for each that was answered.
static func epilogue(g) -> Array:
	var out: Array = []
	for id in ORDER:
		var ch := chosen(g, id)
		if ch != "" and CROSSROADS[id].get("end", {}).has(ch):
			out.append(str(CROSSROADS[id].end[ch]))
	return out

## What the scales made of him, for the ending: "Merciful, of the New Works, of the Home Fire".
static func names(g) -> String:
	var out: Array = []
	for sc in SCALE_ORDER:
		var nm := name_of(g, sc)
		if nm != "":
			out.append(nm if out.is_empty() else nm.left(1).to_lower() + nm.substr(1))
	return ", ".join(out)

## The text beside the list on the Crossroads page.
static func text(g, id: String) -> String:
	var c: Dictionary = CROSSROADS[id]
	var ch := chosen(g, id)
	if ch == "":
		return "Part %s.  Somewhere ahead on the road." % str(c.part)
	var o := option(id, ch)
	var h := heard(g, id)
	var parts: Array = ["Part %s." % str(c.part), "", str(c.ask), "", "You chose: %s." % str(o.label), str(o.log)]
	if int(h[1]) > 0:
		parts.append("")
		parts.append("Echoes heard: %d of %d." % [int(h[0]), int(h[1])])
	parts.append("")
	parts.append("In the end: " + str(c.get("end", {}).get(ch, "")))
	return "\n".join(parts)
