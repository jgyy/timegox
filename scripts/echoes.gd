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
			"s_p28_home": {
				"mend": [["Elder Qing Xuan", "The eggs are from the Bamboo Forest. The man who left them mends the road there. He was a bandit once, he told Old Shen, and somebody gave him a mattock instead of a beating. He would not say who. He did not need to."]],
				"drive": [["Elder Qing Xuan", "And there is a note from over the ridge, unsigned, in a rough hand: 'We have a village now. No thanks to you. Tell the sweeper we remember which way he pointed.' I do not know what to make of it. I think they are proud."]],
			},
			# Part XXVII (the Heavy Road release)
			"s_p27_tao": {
				"mend": [["Tao Kan, Who Carries Bricks", "They tell me you once set forty bandits to mending a road with their own hands, when you were hardly more than a boy. Then you knew this already, and forgot it when you learned to fly. Most do."]],
				"drive": [["Tao Kan, Who Carries Bricks", "They tell me you once drove forty bandits out of a valley when you were hardly more than a boy. I should have put baskets on their backs. A man who is carrying something has no hand free for a knife."]],
			},
			# Part XXV (the Three Burrows release)
			"done:s_p25_cutters": {
				"mend": [["Narrator", "Behind the woodcutters, unasked, come nine of Road-Mender Hou's forty with mallets over their shoulders. They lay the lane from the hall to where the well will be in one afternoon. They know how a place begins, they say: they have been one."]],
				"drive": [["Feng Xuan", "There was a camp of forty on the bamboo road once, I am told, who might have known how to raise a roof-beam. They went over the pass. We shall manage with three."]],
			},
			# Part XXIV (the Lost Horse release)
			"s_p24_home": {
				"mend": [["Elder Qing Xuan", "Iron Fang's road-menders, do you remember? You did not beat them into it. You beat Iron Fang, and then you said a thing about a road, and it is the thing you said that is still there. I have been thinking about that."]],
				"drive": [["Elder Qing Xuan", "Iron Fang's men, do you remember? You beat them, and you drove them out, and that was the end of it as far as the valley knew. I have wondered since whether a thing is finished because one has won it."]],
			},
			# Part XXI (the Hundred Arms release)
			"s_p21_home": {
				"mend": [["Elder Qing Xuan", "One thing more. Iron Fang's men, the forty you set to mend the forest road. The morning the racks emptied, they came up the mountain in a body and laid forty knives on the gate-step, and asked to have them melted. They said they had felt them move in the night."]],
				"drive": [["Elder Qing Xuan", "One thing more. Iron Fang's men, the forty you drove out of the valley. I am told they are at a king's gate in the east, with a place at his table, and that the best of them has killed eleven. I do not say it to reproach you. I say it because you will meet them."]],
			},
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
			# Part XXIV (the Lost Horse release)
			"s_p24_weng": {
				"hatch": [["Sai Weng", "You are the one who brought the roc's egg down to the tents. It sits on a tent in Thunder Valley and hunts as far as this. It takes a lamb a month and it has kept the wolves off ever since. The neighbours called that luck, and bad luck, by turns, depending on whose lamb."]],
				"leave": [["Sai Weng", "You are the one who left the roc's egg to the storm. It hatched. Something flies over this steppe now that was taught by nobody, and the herds look up. I do not say you were wrong. I say I look up too."]],
				"sell": [["Sai Weng", "You are the one who sold the roc's egg at Cloudfoot. We heard. The horse-folk do not sell a thing that is not yet born. I mention it only so that you know I know, and we can leave it there."]],
			},
			"s_p22_lie": {
				"hatch": [["Master Lie, Who Rode the Wind", "There is a young roc over this valley most mornings, hatched by somebody's patience, the horse-folk say. It has been walking, this week. Walking! It looks at the sky the way I do."]],
				"leave": [["Master Lie, Who Rode the Wind", "There was an egg on this height once that somebody had the sense to leave alone. It hatched by itself and the bird is grown. It sits on the far rim now with its wings shut, waiting, as I am."]],
				"sell": [["Master Lie, Who Rode the Wind", "They tell me a roc's egg from this valley went to a collector. A pity. I should have liked a bird to ask. A bird would know where the wind had gone, and would not have had to be told why."]],
			},
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
			# (the Heavy Road release: a king of the dead holds court in that house in Part XXI, and nobody
			# said how he came to be in a house that was sealed, or given away)
			"s_p21_aysha": {
				"seal": [["Auntie Aysha of the Caravanserai", "They say you put nine seals on that house. He did not break one. He and his three thousand have been dead too long for a seal to notice them; they went in as a draught goes in."]],
				"open": [["Auntie Aysha of the Caravanserai", "They say you gave that house to people with nowhere to go. They are there still, in the outer courts, with their doors barred at night. He took the great hall and the inner yards and did not ask whose they were."]],
			},
			# Part XXV (the Three Burrows release)
			"s_p25_door": {
				"open": [["Yue Ling", "You opened the Blood Moon Palace to whoever had nowhere. There are children playing hopscotch where its altar was. It is the same question, Lin Feng. Only this time you will be living next door to the answer."]],
				"seal": [["Yue Ling", "You sealed the Blood Moon Palace with nine seals, and the seals are on its gates still. That was a door kept shut on something. This is a door to be opened to somebody. I do not think the one tells you about the other."]],
			},
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
			# Part XXIV (the Lost Horse release)
			"s_p24_qian": {
				"rain": [["King Qian", "They say the Dragon King owed you a boon and you spent it on rain for one valley. A farmer's wish. I do not sneer; I was a salt-boiler's son. But do not look to him for help with my tide. You have been paid."]],
				"sea": [["King Qian", "They say the Dragon King owed you a boon and you spent it on a safe road for every ship. My captains bless you. It is his sea-road, mind, and this is his tide; do not think the one is any use against the other. He keeps his accounts apart."]],
			},
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
			# Part XX (the Hollow Hills release)
			"s_p20_wang": {
				"give": [["Lin Feng", "Wang Zhi. There is an axe among the woodcutters of the valley that came down from the moon; it has felled one tree for ten thousand years and never dulled. I gave it to them myself. I think they would lend it to a man who has waited as long as the tree."]],
				"leave": [["Lin Feng", "I knew a man once who chopped at one tree for ten thousand years, and I left him his axe, because the chopping was all he had. You have a better thing than he has, Wang Zhi. You can stop."]],
			},
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
			# Part XX (the Hollow Hills release)
			"done:s_p20_rubbings": {
				"copy": [["Yue Ling", "Rubbings. Like the ones you had taken from the Nine Cauldrons for every town in the land. He will not need his hand held about paper going where it is wanted."]],
				"keep": [["Yue Ling", "Rubbings. You would not let them take any from the Nine Cauldrons, do you remember? You said some things should be gone to. I think he would agree with you, and then take one anyway."]],
			},
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
			# Part XX (the Hollow Hills release)
			"s_p20_home": {
				"run": [["Elder Qing Xuan", "And the wheel at Qingshi has not stopped since the day you said it need not. I do not blame it for the wells. I only notice that a thing which never rests wants feeding, and that what it is fed is dug."]],
				"hours": [["Elder Qing Xuan", "The wheels stand at night, as you settled it, and I had thought that was the end of the matter. But a wheel that rests still eats by day, and what it eats is dug. We gave the machines hours. We forgot to give the spades any."]],
				"down": [["Elder Qing Xuan", "You had the wheel at Qingshi taken down, and I thought the valley would dig less for it. It digs more: they pound by hand again, and want new pestles, new mortars, a new kiln to fire them. It was never the wheel, Lin Feng. It is us."]],
			},
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
			# Part XXI (the Hundred Arms release)
			"pre:wuzhu": {
				"keep": [["Yue Ling", "It has made itself a hand, Lin Feng, the way the Player made itself a heart. You told the Player: it is yours, you made it. I do not think this one wants to be told that. It wants to be told what to do with it."]],
				"maker": [["Yue Ling", "You sent the Player to its maker with the heart it built, to ask if it might keep it. This one has built a hand, and there is nobody to send it to. It came to you because you are the nearest thing to a maker it could find."]],
				"still": [["Yue Ling", "You took out the heart the Player made for itself. I have never quite forgiven that. Do not take this hand off it, Lin Feng. Show it what the hand is for. That is harder, and it is what was owed the last time."]],
			},
			# Part XX (the Hollow Hills release)
			"pre:xuanpin": {
				"keep": [["Yue Ling", "Lin Feng. The Player had a hollow in its chest where a heart was meant to go, and it filled it itself, and you said: keep it. I thought that was the whole of the lesson. I think she is the other half. Some hollows are not waiting for anything."]],
				"maker": [["Yue Ling", "You told the Player its heart was for its maker to say. Who made her? Nobody. There is nobody to send her to. This time it really is ours to answer."]],
				"still": [["Yue Ling", "You took the heart out of the Player and left it hollow, and I did not speak to you for a day. I have been wrong about that for a month and I only now see how. Look at her. That is what a hollow is, when it is let be."]],
			},
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
			# Part XXI (the Hundred Arms release)
			"s_p21_ou": {
				"hand": [["Ou Yezi the Swordsmith", "They tell me you ruled that nothing be made by engine that a hand cannot still make. Good. It was a hand that turned each of those ladles. If it had been a wheel I could have stopped the wheel. I do not know how to stop a wrist."]],
				"wheel": [["Ou Yezi the Swordsmith", "They tell me every engine in this town has a keeper, a gate and hours, by your ruling. So I looked for the keeper of this. There is none. It runs when it likes. It is the first thing I have seen here that nobody put a name on."]],
				"dao": [["Ou Yezi the Swordsmith", "Follow, do not cut: they have it carved over the yard gate, and say it was your ruling. Well. The bronze is being followed. That is what you are looking at. It was never said where it might want to go."]],
				"ask": [["Ou Yezi the Swordsmith", "They tell me you would not rule on the machines, and sent the makers to an old gardener who would not use a well-sweep. I should like to have met him. He would have looked at this heap and said: I told you. And he would have been ashamed to be right."]],
			},
			# Part XX (the Hollow Hills release)
			"s_p20_tushan": {
				"hand": [["Auntie Rong of the Smelting Pits", "You told us: nothing by machine that we cannot still do by hand. So I had them sink this shaft by hand, to remember how. They remembered the digging. Nobody remembered the shoring. That part was always the old men's, and I did not think to ask one."]],
				"wheel": [["Auntie Rong of the Smelting Pits", "A keeper, a gate and hours, you said, for every engine. There is a keeper on every hammer in this town with her name on it. Nobody put a name on the mine. A hole is not an engine, we thought. Well. It has been working day and night without a gate, like the worst of them."]],
				"dao": [["Auntie Rong of the Smelting Pits", "Follow, do not cut: you had us all saying it. And the casters follow the bronze now, I will give you that. But down there they were not following the seam. They were chasing it. I know the difference in a man's back from across a yard, and I said nothing, because the ore was good."]],
				"ask": [["Auntie Rong of the Smelting Pits", "Nine days the makers argued with that old gardener, and do you know the one thing he said that nobody wrote down? He asked where it all came from. The bronze. Nobody answered him. We thought it was a gardener's question."]],
			},
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
	# ---- Part XX (the Hollow Hills release): what an empty place is for, asked three times
	"the_mountain": {"step": "s_p20_fen", "part": "XX", "n": "Yu Gong's mountains",
		"ask": "The Lamb of the Earth is asleep again in its round room, and Yu Gong has stopped the whole line of baskets to hear you. Two mountains stand between his door and the south road. He has ninety years, sons without end, and half the valley's afternoons. What would you do, if they were yours?",
		"options": [
			{"id": "road", "label": "Cut a road through, and leave the mountain", "tilt": {"reach": 3, "craft": 1},
				"desc": "He never wanted the mountains gone; he wanted to stop going round them. A tunnel the width of a cart is a hollow made on purpose and kept open by everybody who uses it. Dig that, and carry what comes out all the way to the sea.",
				"log": "Told Yu Gong to cut a road through his mountains, and leave them standing."},
			{"id": "dig", "label": "Dig on. You said you would", "tilt": {"craft": 2, "heart": -1}, "gain": {"renown": 4},
				"desc": "He gave his word to two mountains in front of his whole family, and a thing done every day by people who do not stop is done. Let him finish. But every basket goes to the sea of Bo again, a year there and back, and never into a hole (renown).",
				"log": "Told Yu Gong to dig on, and carry every basket to the sea."},
			{"id": "leave", "label": "Leave them. Somebody lives there", "tilt": {"craft": -2, "heart": 2},
				"desc": "There was a room in the mountain and something asleep in it, and seven hundred li of hill he has never seen the inside of. Put the baskets down. A man of ninety may go round a mountain a few more times.",
				"log": "Asked Yu Gong to leave his mountains where they are."},
		],
		"after": {
			"road": [["Yu Gong, the Foolish Old Man", "A hole through it. The size of a cart. ...Ninety years, and I was trying to take away the whole of a thing when all I wanted was a piece of nothing in the middle of it. Do not tell the man at the river bend. No. Tell him. He has waited long enough to be right about something."]],
			"dig": [["Yu Gong, the Foolish Old Man", "To the sea of Bo. Every basket. A year there and back, as my grandfather did it. Yes. I let them hurry me, and it was my own mountain. We dig on, lads! And the first one I catch tipping into a swallow-hole carries double."]],
			"leave": [["Yu Gong, the Foolish Old Man", "Put them down. Put the baskets down. ...I never thought to hear myself say it. It is very quiet, is it not, with nobody walking. I shall have to have the gatepost recarved. I do not know what to. Give me a day or two."]],
		},
		"echo": {
			"s_p22_xie": {
				"road": [["Duke Xie of the Toothed Clogs", "You are the one who had a road cut through Yu Gong's mountains instead of moving them! I walked it in the autumn. A good road. It goes round the things worth looking at, which is more than mine do."]],
				"dig": [["Duke Xie of the Toothed Clogs", "You are the one who let the old man go on digging. I have seen his two mountains; they are a hand lower than they were. I thought: there is somebody who understands that a hill is only a thing in the way."]],
				"leave": [["Duke Xie of the Toothed Clogs", "You are the one who had Yu Gong's mountains left where they stood. I ought to have expected trouble from you. ...No, no. Sit down. A man with three hundred axes should talk to one like you at least once."]],
			},
			"s_p20_gong2": {
				"road": [["Yu Gong, the Foolish Old Man", "The heading is forty paces in already. We found two more rooms and went round both, and my eldest knocked first each time. He says it is manners. I say it is sense. We are both pleased."]],
				"dig": [["Yu Gong, the Foolish Old Man", "The first baskets will be at the sea by midsummer. It is slow. It was always meant to be slow; that was the part the story was about, and I was the one who forgot it."]],
				"leave": [["Yu Gong, the Foolish Old Man", "I had the gatepost recarved. It says: Yu Gong, who went round. The children think it is very dull. I walked round the west mountain yesterday, the long way, and saw a valley I had not known was there."]],
			},
		},
		"end": {"road": "Yu Gong's grandsons walk to the south road through a tunnel a cart wide, and the two mountains stand where they stood.", "dig": "Yu Gong digs on, and every basket of his mountains goes to the sea of Bo, a year there and back.",
			"leave": "Yu Gong's gatepost reads: who went round. He has seen three valleys he did not know were there."}},
	"the_echoes": {"step": "s_p20_wangliang", "part": "XX", "n": "The ten thousand echoes",
		"ask": "The Penumbra is folded in your hand, and the Cave of Ten Thousand Echoes is filling again, gently, with every word that was ever shouted into it: names, prices, songs, a mother calling a child in. Each of them was somebody. Xu Xiake says he only measures. What is to be done with them?",
		"options": [
			{"id": "home", "label": "Let them go home", "tilt": {"heart": 3, "reach": 1},
				"desc": "Stand in the mouth of the cave and let them out, a voice at a time, into the wind over the karst. A word that has waited a hundred years to be heard should be heard by somebody, even if it is only a fisherman who hears his father call him in to supper.",
				"log": "Let the ten thousand echoes out of the cave, to go home."},
			{"id": "keep", "label": "Let the cave keep them", "tilt": {"reach": -2, "heart": 1},
				"desc": "This is what the cave is for. It has kept them safe longer than any family keeps a name. Clear the passages so that it has room again, ask the karst folk to shout a little less, and leave ten thousand voices where they were put.",
				"log": "Left the ten thousand echoes in the keeping of their cave."},
			{"id": "write", "label": "Write them down", "tilt": {"craft": 2, "reach": 2}, "gain": {"renown": 5},
				"desc": "A traveller with a brush is sitting right there. Let Xu Xiake stay a season and write down every one that will say itself slowly enough, and send the book to the Scripture Library. A cave you did not write down, you did not go into (renown).",
				"log": "Set Xu Xiake to write down the ten thousand echoes."},
		],
		"after": {
			"home": [["Narrator", "They go out past him like swallows at dusk, each one saying itself once. Down on the shingle, an old man with a cormorant on his arm puts down his pole, and turns his head, and answers."], ["Yue Ling", "He said: coming. Lin Feng. He said: coming, Father."]],
			"keep": [["Xu Xiake the Traveller", "Leave them. Yes. I have taken a rubbing off every wall I ever found, and never once thought the wall might prefer to keep it. I shall mark this one on my map with a circle, which means: go in quietly."]],
			"write": [["Xu Xiake the Traveller", "All of them? Ten thousand? ...I have paper for four hundred. Fisherman! Have you a boy who can run to Longmen for paper? And ink. And a lamp. And tell my wife, if anyone is going as far as Jiangyin, that it will be the spring after next."]],
		},
		"echo": {
			"s_p22_ziqi": {
				"home": [["Zhong Ziqi the Woodcutter", "You sent the ten thousand echoes home, they say, each to its own mouth. Then these are new ones. I thought so; they have no dust on them. Somebody is collecting again who has not heard it was settled."]],
				"keep": [["Zhong Ziqi the Woodcutter", "You left the ten thousand echoes in their cave, they say, to be visited. Then this is something that could not find the cave. It is keeping what it hears on a hillside, in the rain, with no roof."]],
				"write": [["Zhong Ziqi the Woodcutter", "You had the ten thousand echoes written down, they say. I cannot read. But I have wondered since whether a voice in a book still knows whose it was. These up the slope do not."]],
			},
			"done:s_p20_delve": {
				"home": [["Xu Xiake the Traveller", "It echoes again, the big one. I went back to hear. You shout your name and it gives you your name, an afternoon long, and nothing else. I had not known how much I wanted that."]],
				"keep": [["Xu Xiake the Traveller", "The karst folk have put a rope across the big mouth with red rags on it, and they take their hats off going past. It is the best-kept cave in the land now, and nobody goes into it at all. I am trying to decide how I feel."]],
				"write": [["Xu Xiake the Traveller", "Six hundred and twelve so far. The boy holds the lamp and I write. Most of them are people calling other people to come and eat. I have begun to think that is what most of everything is."]],
			},
			"pre:xuanpin": {
				"home": [["Xuanpin, the Valley Spirit", "You let the voices out of the cave in the karst. I felt it empty. It was the first room in the land to be given back to me in a year, and you did it only to be kind to them. You did not know I was in it."]],
				"keep": [["Xuanpin, the Valley Spirit", "You left the voices in the cave in the karst, and cleared it so they had room. That was nearly right. A full thing given room is not an empty thing. But it was nearer than anybody else has come."]],
				"write": [["Xuanpin, the Valley Spirit", "You are having the voices in the karst cave written down, one by one, so that the cave may be emptied without anything being lost. It is a maker's answer. I do not despise it. It is how a jar would be emptied by somebody who loved the wine."]],
			},
		},
		"end": {"home": "The Cave of Ten Thousand Echoes gives back one voice at a time again, and an old fisherman of the karst heard his father call him in.", "keep": "The karst folk take their hats off passing the Cave of Ten Thousand Echoes, where every voice is still kept.",
			"write": "Xu Xiake's Book of Ten Thousand Echoes is in the Scripture Library; most of it is people calling each other to come and eat."}},
	"the_hollow": {"step": "s_p20_spirit", "part": "XX", "n": "The Hollow of the Mountain",
		"ask": "The Valley Spirit has gone back up into the wells and caves of the land, and left you the hall she waited in: a hollow under Azure Cloud Mountain larger than the sect that stands on it, dry now, dark, and perfectly still. It is the biggest empty place in the world. She said: say what it is to be.",
		"options": [
			{"id": "empty", "label": "Nothing. Shut the door and leave it", "tilt": {"craft": -3, "reach": -1},
				"desc": "It is to be empty. That is the whole of what it is for. Wall up the shaft beside the weiqi board with one loose stone, tell the Elder and nobody else, and let there be one place in the land that is not for anything.",
				"log": "Left the Hollow of the Mountain empty, and shut the door."},
			{"id": "open", "label": "A place anybody may come and be quiet in", "tilt": {"reach": 2, "heart": 2},
				"desc": "Cut the steps wider, hang one lamp at the bottom, and let it be known in six towns that under the mountain there is a hall where nobody will ask you for anything. Bring nothing down. Take nothing up. Wang Zhi can keep the door; he is used to waiting.",
				"log": "Opened the Hollow of the Mountain to anybody who needs a quiet place."},
			{"id": "cistern", "label": "A cistern for the land's dry years", "tilt": {"craft": 3, "heart": -1}, "gain": {"renown": 5},
				"desc": "A hollow that size, under the highest ground in the province, with a channel cut to each of six towns: the land need never have a dry autumn again. Gongshu Ban would have it lined by the spring. It would be full, of course. That is what a cistern is (renown).",
				"log": "Gave the Hollow of the Mountain to the land for a cistern."},
		],
		"after": {
			"empty": [["Yue Ling", "Nothing. You, who cannot pass a leaf on a step. ...Yes. Shut it. I will help you carry the stone. And then I want you to promise me you will never, ever go down to see whether it needs sweeping."], ["Lin Feng", "I promise. It is going to be very hard."]],
			"open": [["Wang Zhi the Woodcutter", "Keep a door, and let folk in to sit and do nothing? I have had some practice at sitting and doing nothing, I am told. Four hundred years of it. I will do it. I had rather keep a door than have nowhere to go through one."]],
			"cistern": [["Yue Ling", "It is a good answer. The towns will bless you. ...It will be full, Lin Feng. She gave you the one empty place and you have thought of something to put in it. No, I am not angry. I only wanted somebody to have said it."]],
		},
		"echo": {
			# Part XXI (the Hundred Arms release)
			"s_p21_end": {
				"empty": [["Elder Qing Xuan", "You shut the door on the hall under the mountain and left it empty, and I thought it hard of you at the time. I have just hung forty swords on forty pegs and shut the armoury. It is the same act. I see that now."]],
				"open": [["Elder Qing Xuan", "The hall under the mountain that you left open for anybody to be quiet in: three of the king's swordsmen are down there now. They came up the road last night. They have not said anything, and nobody has asked them to."]],
				"cistern": [["Elder Qing Xuan", "The hall under the mountain is filling, as you meant it to, against the dry years. I went down to look. It is very still, and deep, and useful, and nobody needs it today. I thought: that is what the armoury ought to be."]],
			},
			"s_p20_end": {
				"empty": [["Elder Qing Xuan", "And you have shut it, and left it empty, and told only me. I shall tell my successor on my deathbed, and he will think I am wandering. Good. It is the only secret this sect has that is worth keeping, and it is the secret that there is nothing there."]],
				"open": [["Elder Qing Xuan", "And it is to be open: a hall to be quiet in, for anybody. There were eleven people on the steps this morning, Lin Feng, from four towns. A founder. A woman with a baby. They went down, and came up an hour later, and not one of them could tell me what they had done."]],
				"cistern": [["Elder Qing Xuan", "And it is to be a cistern. Ban was here before breakfast with an ink-line. It is wise; I cannot fault it; the land will drink for a thousand years. I only find that I keep walking over to the well-head and listening, as if there were something I had meant to ask it first."]],
			},
			"post:s_break25": {
				"empty": [["Narrator", "And under the well-head, under the courtyard, under the whole weight of the mountain, there is a great dark room with nothing in it, and the door shut; and it holds the sect up as a breath holds up a singer."]],
				"open": [["Narrator", "And far below them a lamp is burning at the foot of a stair, and a woodcutter is asleep beside it with his new axe across his knees, and somebody from a town three days off is sitting in the dark beyond the light, not doing anything at all."]],
				"cistern": [["Narrator", "And far below them the water of six towns lies in the dark, deep and still and safe, lined with Gongshu Ban's best stone; and it is hard to say, from the well-head, whether what one hears down there is fullness or only the place where an emptiness was."]],
			},
		},
		"end": {"empty": "Under Azure Cloud Mountain there is a hall larger than the sect, with nothing in it, and the door shut.", "open": "Anybody may go down under Azure Cloud Mountain and be quiet; Wang Zhi the woodcutter keeps the door.",
			"cistern": "The Hollow of the Mountain is the cistern of six towns, and the land has not had a dry autumn since."}},
	# ---- Part XXI (the Hundred Arms release): what a weapon is for, asked three times
	"the_pupils": {"step": "s_p21_ape", "part": "XXI", "n": "The Maiden's method",
		"ask": "The White Ape is in his banyan, forty gibbons have put down forty reeds, and a runner has come from Qingshi: with a blade in every thatch, will the Maiden come north and teach the valley what she taught an army? She says it is yours to answer. You have just shown her first pupil the rest of the lesson. Who is to be taught?",
		"options": [
			{"id": "all", "label": "Whoever asks", "tilt": {"reach": 3, "craft": 1}, "gain": {"renown": 4},
				"desc": "A method that is small and easy should not be a secret. If every hand in the land is going to have a blade in it this winter, let every hand know where the edge is, and how to stop. An untaught sword is the dangerous kind (renown).",
				"log": "Asked the Maiden of Yue to teach whoever asks."},
			{"id": "sweep", "label": "Whoever has swept a year first", "tilt": {"reach": -2, "heart": 1},
				"desc": "She learned in a forest, striking at things because she liked it. He learned on nine hundred steps with a broom. Let her teach anybody who has first done a year of some plain work with a long handle, in their own town, where their grandmother can watch.",
				"log": "Asked the Maiden of Yue to teach those who have swept a year."},
			{"id": "none", "label": "Nobody. Let it end with the ape", "tilt": {"craft": -2, "heart": 2},
				"desc": "She taught an army once and saw what was done with it. The old ape had it two thousand years and it only made him lonely. Let the method stay in the marsh with the one pupil who has finally understood it, and let the valley take its blades down.",
				"log": "Asked the Maiden of Yue to teach nobody more."},
		],
		"after": {
			"all": [["The Maiden of Yue", "Whoever asks. Very well. I shall start with stopping, this time, and get to striking in the second year, if any of them are still there. The army had it the other way about. It was the king's idea."]],
			"sweep": [["The Maiden of Yue", "A year with a broom. Ha. He has been sitting up there since noon being wise, and you have just told forty gibbons to sweep the marsh. I should like to see that. Yes. Send me the ones who have blisters in the right place."]],
			"none": [["The Maiden of Yue", "Nobody. ...I have wanted somebody to say that to me since the summer the army marched. I could not say it to myself; it felt like meanness. Tell them in Qingshi that I am a girl who likes hitting things, and that it is not a trade."]],
		},
		"echo": {
			# Part XXV (the Three Burrows release)
			"s_p25_seat": {
				"all": [["Yue Ling", "The Maiden of Yue teaches whoever asks, because you said she should. Now there are three hundred asking, and it is you they are asking."]],
				"sweep": [["Yue Ling", "The Maiden of Yue takes nobody who has not swept a year. You said that. I notice what you called the hall."]],
				"none": [["Yue Ling", "You let the Maiden's art end with her. And here are three hundred who want teaching, and a hall with no name on it. It is the same question, come back larger."]],
			},
			"visit:s_p21_masters:yue_maiden": {
				"all": [["The Maiden of Yue", "Sixty came, the first week. I had them stand still holding a switch until noon. Forty came back the next day, and those I shall teach. The twenty were the ones I was afraid of."]],
				"sweep": [["The Maiden of Yue", "The first one came yesterday: a ferry-boy from Longmen who has poled a boat since he was nine. He said, is a pole a broom? I said it was a better one. He already knows where his feet are."]],
				"none": [["The Maiden of Yue", "They have stopped sending. The old one teaches the small ones to peel fruit now, with great ceremony. It is the same stroke. I have decided not to tell him."]],
			},
			"s_p21_sarnai": {
				"all": [["Grandmother Sarnai", "And I hear a girl in the south is to teach the sword to anyone who asks. Hm. Well. Better taught than not, with boys. But I would want to see who does the asking."]],
				"sweep": [["Grandmother Sarnai", "And I hear a girl in the south will teach nobody who has not done a year's plain work first. Now that is a woman who has raised boys, or ought to."]],
				"none": [["Grandmother Sarnai", "And I hear a girl in the south was asked to teach the valley the sword, and you told her no. Good. I wish somebody had said it to the archer before he got as far as us."]],
			},
		},
		"end": {"all": "The Maiden of Yue teaches whoever asks, and begins with a year of standing still.", "sweep": "The Maiden of Yue teaches those who have done a year of plain work with a long handle; a ferry-boy of Longmen was the first.",
			"none": "The Maiden's method stays in the marsh, with an old white ape who teaches the young ones to peel fruit."}},
	"the_three_thousand": {"step": "s_p21_zhao", "part": "XXI", "n": "The three thousand",
		"ask": "King Wen has put his crown down on the mat beside five broken tallies, and in the yards of the red palace three thousand swordsmen are waiting to hear what they are now. In the old book they went to their quarters and killed themselves, and the book thought that the end of it. What becomes of them?",
		"options": [
			{"id": "home", "label": "Home, each with a tally to return", "tilt": {"heart": 3, "reach": -1},
				"desc": "Every one of them is somebody's. Give each a broken tally from the sand and send him to find the family of the man it was cut for, and say what happened, and stay as long as he is let. Then he may go to his own.",
				"log": "Sent the three thousand home, each with a dead man's tally to return."},
			{"id": "guard", "label": "To the caravans: paid the same if they never draw", "tilt": {"reach": 2, "craft": 1}, "gain": {"renown": 5},
				"desc": "Eleven caravans went out of Shazhou this month with no guard. Here are three thousand who know one end of a sword from the other. Auntie Aysha's bargain: a guard is paid the same whether he draws or not, and thought more of if he does not (renown).",
				"log": "Hired the three thousand to guard the caravans, paid the same if they never draw."},
			{"id": "judge", "label": "Each answers for the men he killed", "tilt": {"heart": -3}, "gain": {"renown": 4},
				"desc": "A hundred and more a year, for three years, for a king's amusement and a place at his table. Nobody held their hands. Count the tallies, name the dead, and let each man be judged in the town of the man he killed (renown).",
				"log": "Sent each of the three thousand to be judged where his dead came from."},
		],
		"after": {
			"home": [["Narrator", "It takes three days to give out the tallies. The swordsmen take them without a word, each looking for a mark he knows. The one with the horse cut on it is taken by a big scarred man who looks at it, and sits down in the sand, and cannot be got up for an hour."]],
			"guard": [["The Swordsman in Scholar's Dress", "Paid the same if they never draw. Now that is better than my ending. I only made a king ashamed. You have made three thousand men useful, which lasts longer. I shall put it in the book. I shall say I thought of it."]],
			"judge": [["King Wen of Zhao, Who Loved Swords", "And I? They fought because I liked to see it. If each of them answers for his dead, then I answer for all three hundred. ...Yes. Write my name first. I had thought the worst of it was that I was bored."]],
		},
		"echo": {
			# Part XXV (the Three Burrows release)
			"s_p25_tally": {
				"home": [["Yue Ling", "The three thousand went home each with a tally to give back at a grave. You did not burn those, and you did not collect on them. You had them carried."]],
				"guard": [["Yue Ling", "The three thousand are paid the same whether they draw or not. You have never been somebody who thought a debt was only a sum."]],
				"judge": [["Yue Ling", "You had the three thousand answer each for his own dead, one at a time. You have counted to the notch before now."]],
			},
			"visit:s_p21_masters:cook_aysha": {
				"home": [["Auntie Aysha of the Caravanserai", "My porter's boy came back, the one of fifteen. He had a slip of wood, and went on through to a village past the salt flats with it, and was gone a month. He does not talk about it. He does not touch his grandfather's sword either."]],
				"guard": [["Auntie Aysha of the Caravanserai", "I have forty of the king's men on my caravans now. The masters complained they were paying for swords that never came out. I said: yes. That is what you are paying for. Count your camels."]],
				"judge": [["Auntie Aysha of the Caravanserai", "They held the judging here for the Shazhou dead, under my awning. Seven men. I gave them water first, the accused too. Water is not a verdict. But I will say the town slept that night, for the first time since the boys left."]],
			},
			"pre:wuzhu": {
				"home": [["Wuzhu, the Masterless Edge", "You sent three thousand men home with the tallies of the dead. We heard it; edges hear such things. Each of those men had a hand, and you found a use for it that was not us. Find us one."]],
				"guard": [["Wuzhu, the Masterless Edge", "You sent three thousand swords to walk beside camels and be paid for staying in the sheath. We heard it. We did not understand it. A sword that is paid not to cut. Explain it to us. We have time."]],
				"judge": [["Wuzhu, the Masterless Edge", "You had three thousand men judged for what their swords did. We heard it. Nobody judged the swords. Nobody ever does. We should like to be judged. It would mean somebody thought we had done it."]],
			},
		},
		"end": {"home": "Three thousand swordsmen went home by way of the families of the men they killed, each with half a tally.", "guard": "The caravans of the sand road are guarded by the king's three thousand, who are paid the same whether they draw or not.",
			"judge": "The three thousand were judged in the towns their dead came from, and King Wen's name was written first."}},
	"the_arms": {"step": "s_p21_wuzhu", "part": "XXI", "n": "The arms of the land",
		"ask": "Four thousand blades lie on the floor of the long barrow with their points to the wall, and there is a sword in every thatch from Qingshi to the sand. Ou Yezi will do with them whatever he is told; the six hearths have each sent somebody to hear it. What is done with the arms of the land?",
		"options": [
			{"id": "melt", "label": "Melt them: ploughshares, bells and pots", "tilt": {"craft": -3, "heart": 2},
				"desc": "It was good bronze before it was an edge. Let the pits of Tushan run the other way for a winter: every blade nobody made goes back to the mould and comes out as a thing with a use on an ordinary day. The sect keeps its forty, on their pegs.",
				"log": "Had the unasked blades of the land melted into ploughshares, bells and pots."},
			{"id": "rack", "label": "One rack at every hearth, and a keeper", "tilt": {"reach": -3, "craft": 1},
				"desc": "The horse-folk have always done it: one bow to a tent, by the door-flap, where the grandmother sees who takes it down. Give every hearth in the land one rack, in the open, and a keeper with a name. What does not fit on the rack goes back to the fire.",
				"log": "Gave every hearth one rack for its arms, in the open, and a keeper."},
			{"id": "school", "label": "A school: every weapon, and the broom first", "tilt": {"reach": 2, "craft": 2}, "need": [["arms", 3]], "gain": {"renown": 6},
				"desc": "They got up because nobody had told them what they were for. Then tell them, and tell the hands too: a yard on the mountain where anybody may learn any of the eight, after a year with a broom. Only somebody who has learned three himself can promise that (renown).",
				"log": "Founded a school of arms on the mountain, where the broom is learned first."},
			{"id": "bury", "label": "Bury them, each with a name", "tilt": {"heart": 1, "craft": -1},
				"desc": "The sword saints were laid down with their blades and a tablet over each, and their swords lay quiet for a thousand years. Give every one of the four thousand a name and a place in the ground. It will take Mu Gu the rest of his life. He has already said yes.",
				"log": "Had the four thousand blades buried, each under a name."},
		],
		"after": {
			"melt": [["Narrator", "The first of them goes into the crucible at Tushan before the week is out. It comes out a bell. Bell-Caster Wei strikes it once, in the yard, and every caster in the town puts down what he is holding to listen to something that was going to be a sword."]],
			"rack": [["Narrator", "The racks go up within the month: over Auntie Aysha's oven, in the stern locker of the ferry, under the lantern-row at Yanggu. Each has one weapon on it and a name cut beside it, and the name is never a young man's."]],
			"school": [["Narrator", "The yard is marked out below the kitchen, eight racks along the wall and a row of brooms by the gate. The first to ask for a place is a big scarred man from the east, who holds his broom at first exactly as if it were a sword, and is told so, kindly, by a girl of ten."]],
			"bury": [["Gravekeeper Mu Gu", "Four thousand. I have a chisel and a good eye and perhaps thirty years. I shall not finish. But I shall name one a day, and say it aloud, and the apprentice I have not got yet can do the rest. You have given me a reason to find one."]],
		},
		"echo": {
			"s_p23_hao": {
				"melt": [["Lady Hao", "They tell me you melted the arms of the land into ploughshares. Then I am to make a host of ploughmen holding ploughshares. Hm. I have done it with less. Bronze was dear, in my day."]],
				"rack": [["Lady Hao", "There is a rack at every hearth, they tell me, and a keeper for it. Good. Then every company comes with one man who knows which end of a spear is which. I shall make him a sergeant."]],
				"school": [["Lady Hao", "Your school sent me six instructors this morning. Every one of them began by sweeping my drill ground. I do not understand it, but the ground has never been so level."]],
				"bury": [["Lady Hao", "You buried the arms of the land with names on them, I hear, and now you want a host. I shall not dig them up. A thing buried with a name should stay. We shall rehaft the hoes."]],
			},
			"s_p22_home": {
				"melt": [["Elder Qing Xuan", "The ploughs you had made of all those blades are in the ground by now, and the valley sown. A good spring for the roads to shut, with every hand wanted in a field. Nobody has had time to be frightened."]],
				"rack": [["Elder Qing Xuan", "Every hearth has its one rack now, and its keeper. The keeper at Cloudfoot tells me nobody has asked for so much as a spear. Whatever is on the mountain, the people of the road do not think it is a thing one takes a spear to."]],
				"school": [["Elder Qing Xuan", "Your school has nineteen pupils and eleven brooms. They swept the upper road yesterday as far as the cloud, came out below where they went in, and swept it again. I have told them it is good practice."]],
				"bury": [["Elder Qing Xuan", "The barrow is closed and the grass is on it. Four thousand edges under the ground, and now the tops of the mountains gone into the sky. The land is putting a good deal away this year."]],
			},
			"done:s_p21_racks": {
				"melt": [["Narrator", "The three blades go into Granny Wen's handcart, to be taken to Tushan with the rest. One farmer asks if his might come back as a hoe. He is told it will come back as whatever the valley is short of, and he says: then a hoe."]],
				"rack": [["Narrator", "One of the three is hung on the new rack by the well, with Granny Wen's name cut beside it. The other two go in the cart for the fire. The farmer whose blade was kept looks rather proud, and is told to stop."]],
				"school": [["Narrator", "The three blades are wrapped in straw for the mountain, and each farmer is given a broom in exchange, which they take for a joke until Granny Wen explains that it is not one. Her grandson has already asked how old one must be."]],
				"bury": [["Narrator", "The three blades are laid in the cart for the Graveyard, and Granny Wen has each farmer say a name for his before it goes. One calls his after his ox. Nobody laughs. It is written down as given."]],
			},
			"s_p21_ou2": {
				"melt": [["Ou Yezi the Swordsmith", "Ploughshares. I have unmade more this month than I made in my life, and every one came out of the mould glad. I did not know bronze could be glad. Forty years I have been a smith, and I am only now learning the trade from the other end."]],
				"rack": [["Ou Yezi the Swordsmith", "One to a hearth, and a keeper. I cast the pegs for the racks myself. Plain work. A peg is a thing made to have a weapon hung on it and not taken down, and I find I am better at pegs than I ever was at swords."]],
				"school": [["Ou Yezi the Swordsmith", "A school, and brooms first. I shall come up and see it. I never once met the people my swords were for; I met kings. I should like to stand at the back of a yard and watch a child be told she is holding it wrong."]],
				"bury": [["Ou Yezi the Swordsmith", "Named and buried. That is how they did it with mine, in the end: Zhanlu has a grave somewhere, I am told, and a tablet. I have sent Mu Gu my small chisel. It cuts a clean character, and I shall not need it for marks any more."]],
			},
			"post:s_break26": {
				"melt": [["Narrator", "Down in the valley, a bell that was nearly a sword rings the hour from the gate of Qingshi, and is a little flat, and nobody would have it otherwise."]],
				"rack": [["Narrator", "Down in the valley, by the well at Qingshi, one blade hangs on one peg in the open, and Granny Wen, shelling beans in her doorway, can see it from where she sits."]],
				"school": [["Narrator", "Below the kitchen, in the new yard, somebody has left a broom leaning on the first of the eight racks. It is the right way up. That is the only rule the school has written down so far."]],
				"bury": [["Narrator", "In the Graveyard of Sword Saints, Mu Gu cuts the day's name, says it aloud over a new small mound, and listens. Nothing hums. He goes in to his tea."]],
			},
		},
		"end": {"melt": "The unasked blades of the land were melted, and the first of them is a bell at Tushan.", "rack": "Every hearth has one rack for its arms, in the open, and the name beside it is never a young man's.",
			"school": "There is a school of arms below the kitchen of the Azure Cloud Sect, where the broom is learned first.", "bury": "Gravekeeper Mu Gu names one unmade sword a day and buries it, and has taken an apprentice."}},
	# ---- Part XXII: The High Roads.  What a voice, the air and the top of a mountain are for.
	"the_voices": {"step": "s_p22_xiao", "part": "XXII", "n": "The thief of voices",
		"ask": "The shanxiao sits in its ring of salt with a pedlar's bell in both hands, and at the foot of the height the woodcutters of the south road have come up with torches to see what has been calling them. It is afraid of them, and they of it. Zhong Ziqi, who hears what is meant, says he heard only that it is lonely, and that this is not his to settle. What is done with it?",
		"options": [
			{"id": "fire", "label": "A place at the camp fires", "tilt": {"heart": 3, "reach": 1}, "gain": {"renown": 4},
				"desc": "It stole salt because salt is what a fire has that a mountain has not. Give it a place at the fires of the road: a pinch left out on a flat stone, nobody to laugh at its foot, and its own cracked voice to use. A thing that is spoken to has less need to borrow (renown).",
				"log": "Asked the camps of the road to leave salt out for the shanxiao, and a place by the fire."},
			{"id": "bamboo", "label": "Green bamboo at every fire, as it always was", "tilt": {"craft": -3, "reach": -1}, "gain": {"items": {"ess_earth": 3, "ess_wood": 3}},
				"desc": "The grandmothers knew what to do. Three joints of green bamboo on every fire at dusk, to crack and keep it up its mountain; and it keeps its height, its salt and its bell, and nobody goes up there. It is the old bargain, and nobody was ever hurt by it (essences).",
				"log": "Had green bamboo burned at every camp, as the grandmothers did, and left the shanxiao its height."},
			{"id": "drive", "label": "Over the ridge with it, and the voices given back", "tilt": {"heart": -3}, "gain": {"stones": 400},
				"desc": "Three men went up into the cloud after their mothers' voices. A thing that does that, whatever it meant by it, does not stay on a road with children on it. The cutters have torches. Let it go over the ridge to where there are no fires to come to (spirit stones, from the camps).",
				"log": "Had the shanxiao driven over the ridge by torchlight."},
		],
		"after": {
			"fire": [["Zhong Ziqi the Woodcutter", "A place by the fire. Then it wants a name, and not one of ours. ...It says: Bell. Very well. Bell, this is the salt. That is the fire. You sit on that side of it, and nobody laughs. High mountains, Bell."]],
			"bamboo": [["Zhong Ziqi the Woodcutter", "Green bamboo. My grandmother will be pleased, wherever she is; she always said the young cutters had grown careless. He will hear it crack and know the road is shut to him, and I shall hear him know it. That is mine to carry. Go on."]],
			"drive": [["Zhong Ziqi the Woodcutter", "Over the ridge. ...I heard what it called as it went. It called my name, the way my mother never did. It had practised. I shall not tell the others that. Take your stones, cultivator. The road is safe."]],
		},
		"echo": {
			"s_p23_kuang": {
				"fire": [["Music-Master Kuang", "There is something at the camp fire by the ferry that sings along in other people's voices, a little out. One leg, they say. It has the haulers' call nearly right. I have been correcting it. It is a quick study."]],
				"bamboo": [["Music-Master Kuang", "They burn green bamboo at the camp by the ferry every night. Crack, crack. It keeps something off, they say. It keeps me awake. But it is in time, I will give them that."]],
				"drive": [["Music-Master Kuang", "A pedlar told me you gave a great many people back their own voices, up in the silk woods. I should like to know how. I have been trying to give one man back his for a week."]],
			},
			"done:s_p22_hermits": {
				"fire": [["Yue Ling", "The second hermit had a bell hung on his cairn. He says something small with one leg brought it up last week, set it down, said, quite clearly, in nobody's voice at all, for the top, and went away again on its hands and its foot."]],
				"bamboo": [["Yue Ling", "The second hermit hears bamboo cracking at every camp below him at dusk. He says it is a comfortable sound, like a village. He also says something sits on its own height across the valley and listens to it, every evening, until the last fire is out."]],
				"drive": [["Yue Ling", "The second hermit asked what the torches were for, the other night. I told him. He said nothing for a while. Then he said a mountain with nothing on it that calls your name is a quieter mountain, and went back to looking."]],
			},
			"s_p22_xie2": {
				"fire": [["Duke Xie of the Toothed Clogs", "And my axemen have a one-legged cook's boy who seasons everything twice. They would not part with him. He answers to Bell and has not borrowed a voice since."]],
				"bamboo": [["Duke Xie of the Toothed Clogs", "And my axemen burn bamboo at dusk like their grandmothers and sleep like their grandfathers. I have written a poem about the sound. It is not good, but it is accurate."]],
				"drive": [["Duke Xie of the Toothed Clogs", "And my axemen sleep sound, and nobody calls them. One of them told me he misses it. His wife's voice, a little out. He said it was better than nothing. I did not put that in a poem."]],
			},
		},
		"end": {
			"fire": "There is a flat stone by every fire on the south road with a pinch of salt on it, and no woodcutter under fifty can tell you why. The wood comes down from the heights by itself.",
			"bamboo": "Bamboo cracks at dusk at every camp of the south road, as it did in the grandmothers' time, and on its own height something keeps a bell and a wall of salt and comes no nearer.",
			"drive": "Nothing calls anybody by name in the Mulberry Silk Woods now. The cutters say the nights are longer for it.",
		}},
	"the_kites": {"step": "s_p22_lian", "part": "XXII", "n": "Whose the air is",
		"ask": "The Earl of the Wind stands with his bag open, and every kite in Thunder Valley is up. He has been in the air since before there were hands to make string, and nobody has ever once asked him whether they might. Master Lie says he asked, and took silence for yes, and is no longer sure that was honest. The horse-folk's children are waiting below with their reels to hear what you say. Whose is the air?",
		"options": [
			{"id": "ask", "label": "His. Ask first, every time", "tilt": {"craft": -2, "heart": 1}, "gain": {"items": {"ess_thunder": 4}},
				"desc": "A pinch of incense and a word to the Earl before any kite goes up, as a fisherman speaks to the river: may I. It costs nothing, and it is true. He was here first. Some days he will say no, and on those days nobody flies (essences, of his own giving).",
				"log": "Asked that nobody fly without first asking the Earl of the Wind."},
			{"id": "free", "label": "Nobody's. Let whoever can, fly", "tilt": {"reach": 3, "craft": 1}, "gain": {"renown": 4},
				"desc": "Wind goes; he said so himself. A thing that only goes cannot be owned, even by an earl. Let every child and pedlar in the land hang a swallow in it, and let Duke Xie's three hundred carry the pattern to every valley they cut a road to (renown).",
				"log": "Said the air is nobody's, and had the pattern of the cloud-kite carried to every valley."},
			{"id": "climbers", "label": "Theirs who climbed to it", "tilt": {"reach": -2, "craft": 1}, "gain": {"stones": 500},
				"desc": "A kite flown from a field is a toy on a string. A kite opened on a top you reached with your hands is the way down from something. Let the Earl bear up those who have come as far as they can by themselves, and nobody else; it is what he liked in Master Lie (spirit stones, from the horse-folk).",
				"log": "Asked the Earl of the Wind to bear up only those who had climbed to where they leapt from."},
		],
		"after": {
			"ask": [["Fei Lian, Earl of the Wind", "Asked. Hm. Asked! Every time? ...I shall say no on the fifth day of every month, on principle, and when I am out of temper. The rest of the time: yes. You may tell the small ones yes. Do not tell them I smiled. I am an earl."]],
			"free": [["Fei Lian, Earl of the Wind", "Nobody's. I said that. I said wind GOES, and you have hung my own word round my neck like the bag. ...Very well. I blew for Chiyou and lost; I can lose to a sweeper. Tell them to make the tails longer. A swallow with a short tail is an insult to both of us."]],
			"climbers": [["Fei Lian, Earl of the Wind", "Those who have climbed. Yes. YES. They arrive at the edge with nothing left, and step off, and want nothing but not to fall. That I can carry all day. That weighs what Master Lie weighed. The ones in the fields may keep their string."]],
		},
		"echo": {
			"done:s_p22_down": {
				"ask": [["Han Yu, Who Cannot Get Down", "You spoke to the air before we left the rock. I heard you: may I. Sir, in thirty years at court I never once heard a man ask leave of anything he was strong enough to take. I shall put that in too."]],
				"free": [["Han Yu, Who Cannot Get Down", "There are two children down there with kites exactly like yours. One of them waved. I waved back, sir. I have not waved at anybody since I passed the examinations."]],
				"climbers": [["Han Yu, Who Cannot Get Down", "I did not climb for this, you understand; I climbed to see a view. I hope the gentleman who owns the wind will overlook it. He seems to be overlooking it. I shall not look down to check."]],
			},
			"done:s_p22_long": {
				"ask": [["Narrator", "On the way down something keeps pace alongside for a moment, at the edge of sight: a stag's flank, a leopard's spots. It had been asked. It seems to have wished to see what it had said yes to."]],
				"free": [["Narrator", "On the way down Lin Feng passes, well below him and to the left, a pedlar under a patched swallow with his whole street on his back, going the other way and singing."]],
				"climbers": [["Narrator", "The air under the kite is different from this height: firmer, like a hand. Nobody is flying from the fields today. Whoever is up, is up from somewhere."]],
			},
		},
		"end": {
			"ask": "Nobody in the land opens a kite without a word to the Earl first, and on the fifth of the month nobody opens one at all. The children say he is a grumpy old thing. They say it fondly.",
			"free": "There is a paper swallow in every sky from the sand to the sea, and a pedlar can cross three valleys in a morning. The Earl of the Wind has been heard to complain about the tails.",
			"climbers": "A kite is opened only from somewhere one has climbed to. There are fewer in the sky, and every one of them is on its way down from something.",
		}},
	"the_tops": {"step": "s_p22_yue", "part": "XXII", "n": "What a summit is for",
		"ask": "It is dawn on Sun-Viewing Peak. The Lord of the Eastern Peak has watched the sun come up for the first time since the first king stood in front of it, and the steles have stopped on the eighteen bends, and below them Duke Xie's three hundred are leaning on their axes with every pilgrim, hermit and woodcutter of the road behind them, looking up. The Lord says he is the mountain and cannot go home; let somebody who can come down again say it. What is the top of a mountain for?",
		"options": [
			{"id": "cairn", "label": "A stone on the cairn, and no name on it", "tilt": {"heart": 2, "craft": -2}, "gain": {"renown": 5},
				"desc": "Anybody may come up, on their hands, and put one stone on the heap, and say nothing, and go down. The steles go back to the foot, where a name belongs: among the people who knew whose it was. It is how the tops were kept before there were kings (renown).",
				"log": "Said that a summit is for a stone on the cairn with no name on it, and had the steles taken back down."},
			{"id": "steps", "label": "Duke Xie's nine thousand steps", "tilt": {"craft": 3, "reach": 2}, "gain": {"stones": 800},
				"desc": "The old, the lame and the six-year-old have as much right to a sunrise as a cultivator. Cut the steps, hang the chain, and let everybody arrive. The Lord will have more company than he likes; but nobody who has been carried up a mountain on his own two feet ever came to boast (spirit stones, from the pilgrims' purse).",
				"log": "Said that a summit is for whoever can be got to it, and let Duke Xie cut his nine thousand steps."},
			{"id": "shut", "label": "For the mountain. Nobody, unless sent for", "tilt": {"heart": -3, "reach": -1}, "gain": {"items": {"ess_earth": 4, "ess_wood": 4}},
				"desc": "He has received for two thousand years, and was glad of nine days' cloud. Let him have his top. Put a gate at the last bend, and let the Lord of the Eastern Peak open it to whom he pleases, when he pleases. It is orderly, and it is quiet, and it is entirely fair (essences, from his own slopes).",
				"log": "Said that a summit is the mountain's own, and had a gate put at the last bend."},
		],
		"after": {
			"cairn": [["The Lord of the Eastern Peak", "A stone. No name. And they say nothing? Not even: I have succeeded? ...I shall be able to hear the wind. I had forgotten there was one up here. Take the prefect's bridge down first. It offends me most."]],
			"steps": [["The Lord of the Eastern Peak", "Nine thousand. With a chain. So I am to be a staircase. ...A six-year-old, you say. Who has not succeeded at anything. Hm. Those I never received. Not one. Send the small ones up first, then, before I change my mind."]],
			"shut": [["The Lord of the Eastern Peak", "A gate. Mine to open. ...I ought to thank you. I do thank you. It is only that I find I had rather expected you to argue. Go down, sweeper. I shall send for you. Probably I shall send for you."]],
		},
		"echo": {
			"done:s_p22_pilgrims": {
				"cairn": [["Yue Ling", "The oldest of them has a stone in her sleeve from her own doorstep. She has carried it four hundred li. She says she was always going to leave it up there, and is glad it will not have to stand next to a prefect."]],
				"steps": [["Yue Ling", "The oldest of them cannot climb any more; her knees. She has been coming to the foot for six years to look up. I told her about the steps. She did not say anything. She began, quite slowly, to put her shoes on."]],
				"shut": [["Yue Ling", "The oldest of them took it very well. She said she had never needed the top, only the going. But she looked up at it for some time after, the way one looks at a door one has always been able to walk through."]],
			},
			"s_p22_end": {
				"cairn": [["Elder Qing Xuan", "And nothing on the top but stones nobody signed. Qing Lian would have approved. She never put her name on anything she built; I had to find out which caves were hers by the draught."]],
				"steps": [["Elder Qing Xuan", "And nine thousand steps going up Sun-Viewing Peak. I hope the Duke knows who is going to be asked to sweep them. ...No. I shall send novices. You have swept enough."]],
				"shut": [["Elder Qing Xuan", "And a gate on the great peak. Well. He is an old thing and has earned his quiet. But I notice, Lin Feng, that you gave a mountain what you would not have taken for yourself."]],
			},
			"s_p23_home": {
				"cairn": [["Elder Qing Xuan", "The pilgrims who were on the tops this morning say the cairns hummed. Every one of them, all at once, a hair flat. Stones nobody signed, and they have an ear."]],
				"steps": [["Elder Qing Xuan", "There were four hundred people on Duke Xie's steps at dawn when it rang. They say the chain sang with it, the whole nine thousand, flat, like a string on a bad lute."]],
				"shut": [["Elder Qing Xuan", "The Lord of the Eastern Peak has sent down, through his gate, for the first time since you gave it him. One line: which of you has moved my note?"]],
			},
			"post:s_break27": {
				"cairn": [["Narrator", "On the cairn of the Lookout, that evening, there is one stone more. It has no broom scratched on it. It has nothing scratched on it at all."]],
				"steps": [["Narrator", "From the fork of the pine he can see them already, a pale line going up the great peak: the first three hundred steps, and on the lowest a very small figure sitting down to rest."]],
				"shut": [["Narrator", "From the fork of the pine the great peak is very clean against the evening, with nobody on it. A light is lit at the top, behind the new gate: one lamp, for one desk."]],
			},
		},
		"end": {
			"cairn": "The steles stand at the foot of Sun-Viewing Peak, where their owners' grandchildren can read them. On the top there is a heap of stones, a little higher every year, and nobody has ever said a word beside it.",
			"steps": "Nine thousand steps go up Sun-Viewing Peak, with a chain, and at dawn there are grandmothers on the top, and children asleep on their fathers' backs. The Lord of the Eastern Peak is said to receive the six-year-olds in person.",
			"shut": "There is a gate at the last of the eighteen bends, and it is not often opened. The Lord of the Eastern Peak watches the sun rise alone, and has let it be known that he is entirely content.",
		}},
	# ---- Part XXIII (the Thundering Pots release): what is done with what was made to obey, with a thing made
	# out of hatred, and with a host that has nothing left to fight
	"the_clay": {"step": "s_p23_meng", "part": "XXIII", "n": "What is done with the clay",
		"ask": "Four hundred soldiers of fired clay are standing in the millet where they stopped, and the general who kept them ready has put down his arm. Every one of them has somebody's face. The ploughmen of the levy want to know what is to be done with them before the spring sowing; they are standing in a good field. Meng Tian has said he will give the order, whatever it is. It is the last one he means to give.",
		"options": [
			{"id": "stand", "label": "Leave them standing, and sow round them", "tilt": {"heart": 2, "craft": -1}, "gain": {"renown": 4},
				"desc": "They were men's faces before they were a king's army. Let them stand in the millet with the crop coming up round their knees, facing every way, and let whoever ploughs there learn to go round. In a generation the children will have names for them (renown).",
				"log": "Left the soldiers of Mount Li standing in the millet, to be sown round."},
			{"id": "home", "label": "Carry each to the village its face came from", "tilt": {"reach": 2, "heart": 1}, "gain": {"stones": 800},
				"desc": "The potters scratched a name inside every collar; the foremen made them. Read the names. Somewhere in the land there is a village for each, and a shrine with room in it. It will take the levy a season of carting, and nobody will be paid (the carters' thanks).",
				"log": "Had the soldiers of Mount Li carried, each to the village named in his collar."},
			{"id": "kiln", "label": "Back to the kiln: tiles, jars and bricks", "tilt": {"craft": 2, "heart": -2}, "gain": {"items": {"ess_earth": 5}},
				"desc": "It is good clay, well fired, and the land wants roofs. Break them, grind them for grog, and fire them again as something a living person can use. The faces go. A face that was only ever a king's copy of somebody is not that somebody (essences, from the grinding).",
				"log": "Had the soldiers of Mount Li broken up and fired again as tiles and jars."},
		],
		"after": {
			"stand": [["Meng Tian, General of the Clay Host", "Stand easy. ...I have never given that order. I did not know it was one. Stand easy, all of you, and let the millet come up. I shall stand with them. It is a better wall than the one I built; it keeps nothing out."]],
			"home": [["Meng Tian, General of the Clay Host", "By name. To his village. Three hundred thousand men built my Wall and I do not know the name of one. You will find them inside the collar, on the left. The potters were made to sign, so that a bad one could be traced and punished. Use it for this instead."]],
			"kiln": [["Meng Tian, General of the Clay Host", "Tiles. ...Yes. It is sound. A roof is more use than a rank. I ask only that mine be the first broken, and that somebody make a brush-pot of it. I invented the brush, you know. I should like to hold one that is used for letters home."]],
		},
		"echo": {
			"s_p23_river": {
				"stand": [["Lady Hao", "The ploughmen have a song about the clay men in the millet already. It is not respectful. It has eleven verses. I have had to forbid it on the march, and I hum it myself."]],
				"home": [["Lady Hao", "Nine carts went out yesterday with clay men lying in straw, each to a village. The carters argued over who should take the one with the scar through his eyebrow. They have all decided he is from their own."]],
				"kiln": [["Lady Hao", "The barracks has a new roof. The men look up at it, at night. Nobody says anything. It keeps the rain off. I notice that nobody has asked to sleep under the corner tile, the one with part of an ear on it."]],
			},
			"s_p23_hao2": {
				"stand": [["Master Sun", "I walked through your millet field on the way here. Four hundred sentries, and a sparrow nesting in one helmet. It is the only army I have ever seen that improved a landscape."]],
				"home": [["Master Sun", "A village on my road has a clay soldier in its shrine now, with incense in front of him and a name-board. They have the wrong name, I am fairly sure. They are very happy with him."]],
				"kiln": [["Master Sun", "I drank from a jar on the road that had, in the glaze, the mark of a thumb. Some potter's, two thousand years ago, or some soldier's. One cannot tell any more. That was, I take it, the point."]],
			},
		},
		"end": {
			"stand": "Four hundred soldiers of clay stand in the millet under Mount Li, facing every way, and the plough goes round them. Each has a name the children gave it. The sparrows have the helmets.",
			"home": "In four hundred villages of the land there is a soldier of fired clay in the shrine, with a name-board and a bowl of rice. Some of the names are right.",
			"kiln": "The roofs of the Drum Tower quarter are tiled with what was once the vanguard of the left. They keep the rain off. Nobody remembers a face.",
		}},
	"the_lute": {"step": "s_p23_gao", "part": "XXIII", "n": "The lute with lead in it",
		"ask": "The lute lies on the rock between two blind men. It is a good instrument, of paulownia, five strings, and it has a bar of lead run into the belly that Gao Jianli put there to kill a king with. It has not carried a tune in two thousand years; it has only kept time for an army. He says it is the one thing he has ever made that was entirely his. Music-Master Kuang has his hand on it and is waiting, and has turned his face towards you.",
		"options": [
			{"id": "melt", "label": "Melt the lead out, and let him play", "tilt": {"heart": 2, "craft": 1}, "gain": {"renown": 4},
				"desc": "A little heat, carefully, through the sound-hole, and the lead runs out like water. What is left is a lute that has been ill for a long time. Kuang will sit with him while it learns to speak again. It will take a winter, and the first tunes will be bad (renown).",
				"log": "Had the lead melted out of Gao Jianli's lute, and left him with Music-Master Kuang to learn it again."},
			{"id": "keep", "label": "Leave it as it is. It is his", "tilt": {"craft": -2, "reach": 1}, "gain": {"stones": 600},
				"desc": "He made it, and he has a right to what he made, and a right to his anger: the king is dead, but the eyes are still out. Let it be a lute that will not sing. Only let it keep time for something else. The haulers of Longmen want a drum for the tow-path (the haulers' thanks).",
				"log": "Left Gao Jianli his leaded lute as it was, and found it work on the tow-path at Longmen."},
			{"id": "break", "label": "Break it, and cut him another", "tilt": {"craft": 2, "heart": -1}, "gain": {"items": {"ess_wood": 5}},
				"desc": "Some things cannot be mended because they were never broken: they were made for one purpose and it was a killing. Break it on the rock. There is paulownia at Longmen, and Boatwright Gao knows wood. A new lute owes nothing to anybody (essences, from the old wood).",
				"log": "Had Gao Jianli's leaded lute broken on the rock, and a new one cut for him at Longmen."},
		],
		"after": {
			"melt": [["Gao Jianli of the Leaded Lute", "It is light. I had forgotten it was light. ...It sounds like a sick child. Do not tell me it will mend; I can hear that it will. That is the trouble with ears. One cannot go on not knowing things."]],
			"keep": [["Gao Jianli of the Leaded Lute", "Mine. Yes. And they want it on the tow-path, to pull to? Forty men, hauling a boat up a river, to MY beat. ...I have kept time for eight thousand who could not hear me. Forty who can. I find I am afraid of it."]],
			"break": [["Gao Jianli of the Leaded Lute", "Break it, then. No. Give it here. I shall. ...There. It made its best sound going. Paulownia wants ten years to season, sweeper. I have the time. I am surprised to find I have the time."]],
		},
		"echo": {
			"s_p23_gaixia": {
				"melt": [["Music-Master Kuang", "He is behind the east company with the lute across his knees. He will not play; it is not well yet. He says he will listen, and tell them afterwards what they did wrong. He means it kindly."]],
				"keep": [["Music-Master Kuang", "Hear that, under the east company? That is the leaded lute, on a cart, keeping their time. He asked to come. It cannot carry the tune. It carries everything else."]],
				"break": [["Music-Master Kuang", "He is with the east company, with nothing in his hands at all, singing. Badly. A man who has only ever played has no notion how to breathe. I have never heard anything I liked so much."]],
			},
			"s_p23_bell": {
				"melt": [["Ling Lun, Who Cut the Pipes", "There is a small bar of lead on my bench that came out of a lute. I have been asked to put it in the bell. I shall not; lead sours bronze. I have put it under the bell-frame, where it can hear."]],
				"keep": [["Ling Lun, Who Cut the Pipes", "The haulers of Longmen have sent word that they are pulling to a new beat, and making a third better time upriver. They did not say whose. I know whose. I can hear it from here, and it is exactly on the count."]],
				"break": [["Ling Lun, Who Cut the Pipes", "A blind man came to my door for the length of a lute's string. I gave it him in millet grains, laid end to end. He counted them twice with his fingers and said I was a grain out. He was right."]],
			},
		},
		"end": {
			"melt": "On the height above Longmen two blind men play in the evenings, a qin and a lute. The lute has only this year stopped sounding like something getting over an illness. The ferrymen rest their poles to listen.",
			"keep": "The haulers of Longmen pull to the beat of a lute with lead in it, struck by a blind man on the bank who has never once played them a tune and never once missed the count.",
			"break": "There is a lute seasoning in Boatwright Gao's loft at Longmen that will not be ready for ten years. A blind man comes every week to knock on it and listen. He says it is coming on.",
		}},
	"the_host": {"step": "s_p23_hao2", "part": "XXIII", "n": "What becomes of a host",
		"ask": "The companies of the host stand on the drill ground at Qingshi: ploughmen, horse-folk, camel archers, haulers, founders, the band. They have held three fields. They can form a square, and they can sing six airs that are one song, and they have not been home since the tenth month. Lady Hao has the roll in her hand, every name on it, and Master Sun has closed his book. The Yellow Bell is hung. Nothing is coming. What becomes of a host?",
		"options": [
			{"id": "home", "label": "Home, every one, by the roll", "tilt": {"reach": -3, "heart": 2}, "gain": {"renown": 6},
				"desc": "Read the roll aloud, each name and each village, and let each man answer and go. The banners to the hearths that sent them; the spears rehafted as hoes. A land that keeps no host must be asked again next time, and may say no. That is what makes it a land worth asking (renown).",
				"log": "Read the roll and sent the levy home, every one, to the hearths that sent them."},
			{"id": "keep", "label": "A standing host, quartered at the Drum Tower", "tilt": {"reach": 3, "heart": -2}, "gain": {"stones": 1500},
				"desc": "The clay was not the last thing that will ever march. Keep a company of each arm under the Drum Tower, paid, drilled, and led by somebody who knows the roll by heart. It will be there when it is wanted. It will also be there when it is not, and a host with nothing to do finds something (the Drum Tower's first tithe).",
				"log": "Kept a standing host at the Drum Tower of Qingshi."},
			{"id": "band", "label": "Keep the song, not the spears", "tilt": {"craft": 3, "reach": 1}, "gain": {"items": {"ess_metal": 4, "ess_wood": 4}},
				"desc": "What won at Gaixia was not a spear. Send the spears home and keep the band: let the companies meet at the Pear Garden every year on the day the bell was hung, from all six hearths, and sing. A thing that has learned to sing together can be asked to stand together (what the companies left at the stage door).",
				"log": "Sent the spears home and kept the song: the six hearths to sing together at Qingshi every year."},
		],
		"after": {
			"home": [["Lady Hao", "By the roll. Yes. I shall read it myself; I know how each is said. It will take until dark. Sweeper: thirteen thousand of mine went home from the Qiang campaign and nobody read their names. I have wanted to do this for three thousand years. Stand there and listen to all of it."]],
			"keep": [["Lady Hao", "A standing host. I led one; I know what it is for and what it turns into. Then it shall have a rule: it marches on a whole tally, and the other half is held by the six hearths together, not by any king. I will see to that before I go back under my hill."]],
			"band": [["Lady Hao", "Hah! Keep the band. My husband's generals would have had a fit. ...Do it. I took the Tu-fang with drums and never told them how. Let them come once a year and sing, and let anybody who means the land harm come and count how many know the words."]],
		},
		"echo": {
			# Part XXV (the Three Burrows release)
			"done:s_p25_watch": {
				"home": [["Lady Hao", "I sent the levy home by the roll, on your word, and was sorry to. This is the first hundred I have seen since that I should have been sorrier to send."]],
				"keep": [["Lady Hao", "I have a company of each arm at the Drum Tower who stand guard because they are paid to. Bring these down some day and let mine look at them. It might shame them. I should enjoy that."]],
				"band": [["Lady Hao", "The host kept its song and put up its spears. These have spears and no song. I shall send up a drum-major with nothing to do, who would walk up a mountain for a hundred people that can keep step."]],
			},
			# Part XXIV (the Lost Horse release)
			"pre:the_riders": {
				"home": [["Narrator", "The levy of the six hearths went home by the roll, every one. There is no host to send for. Lin Feng finds, standing in the grass, that he would not send for it if there were."]],
				"keep": [["Narrator", "The standing host is at the Drum Tower of Qingshi, nineteen days' march from here. A company of each arm, well drilled. Lin Feng looks at what is coming, and does the sum, and is glad for the first time that they are nineteen days away."]],
				"band": [["Narrator", "Somewhere a long way south the six hearths are singing together, as they do now once a year. A rider in the third rank is humming. It is not one of theirs. It is near enough that Lin Feng wonders who taught whom, and when."]],
			},
			"s_p23_end": {
				"home": [["Elder Qing Xuan", "The outer disciples came up the steps last night, forty of them, in step, and fell out of it on the third flight without anybody telling them. I was glad to see it. They had been soldiers quite long enough."]],
				"keep": [["Elder Qing Xuan", "I hear there is a host at the Drum Tower now, with a rule and half a tally. Forty of them are mine. I have asked for them back at the turn of each season, to sweep. A soldier who has never swept is a danger to everybody."]],
				"band": [["Elder Qing Xuan", "The outer disciples came home singing something with a boat-haul in it and a camel. They have been forbidden it in the library. They sing it on the steps; it is, I admit, a good rhythm for a broom."]],
			},
			"post:s_break28": {
				"home": [["Narrator", "On the roads below the mountain that evening there are small parties going six ways, with hoes on their shoulders that have been spears. None of them is in step. From high enough up, it looks like a hand opening."]],
				"keep": [["Narrator", "From the pine the Drum Tower of Qingshi can just be seen, with a watch-fire on it, and a figure walking the wall with a roll under one arm, reading it over, as some people say their prayers."]],
				"band": [["Narrator", "From the pine, on the evening wind, something comes up out of the valley that might be six songs or one. It is ragged. It is a quarter-tone warm of true, like the bell. It goes on a long time."]],
			},
		},
		"end": {
			"home": "The land keeps no host. When it wants one it asks, hearth by hearth, and the keepers of the six fires say yes or no as they see fit. So far they have said yes.",
			"keep": "A host stands at the Drum Tower of Qingshi, a company of each arm, and marches on a whole tally whose other half lies in six pieces at six hearths. It has not marched. It drills, and it grumbles, and it is there.",
			"band": "Every year on the day the Yellow Bell was hung, the companies come in to the Pear Garden from six hearths without a spear among them, and sing. It can be heard at the sect. People who mean the land harm are said to have come to listen, and gone home thoughtful.",
		}},
	# ---- Part XXIV (the Lost Horse release): three questions asked after losing, each of which changes the
	# shape of a country (marks.gd: what the answer leaves standing is walked up to)
	"the_tide": {"step": "s_p24_tide", "part": "XXIV", "n": "The shore at Yanggu",
		"ask": "The bore cannot be beaten; it has gone over you three times. King Qian has tried a wall, and arrows, and waits to hear it from you: what is the shore at Yanggu to do about a tide that cannot be stopped?",
		"options": [
			{"id": "wall", "label": "A wall of many baskets", "tilt": {"craft": 3}, "gain": {"renown": 4},
				"desc": "Not one wall: ten thousand bamboo baskets of stone, staked, each giving a little. Build it a fourth time, the way he has learned to. The low fields behind it could be sown (renown).",
				"log": "Had the sea-wall at Yanggu built a fourth time, of bamboo baskets filled with stone."},
			{"id": "yield", "label": "Give it the low fields", "tilt": {"reach": -2, "heart": 2}, "gain": {"hearth": {"dawn": 3}},
				"desc": "The foreshore is the tide's and always was. Move the houses up on to legs, tie a boat to every one, and let the bore have what it comes for. The Lantern Hearth will remember who said they need not fight it (regard of the Dawn-Market Folk).",
				"log": "Gave the low fields of Yanggu to the tide, and had the houses of the shore put up on legs."},
			{"id": "arrows", "label": "Shoot it, every year", "tilt": {"heart": -3}, "gain": {"stones": 2400},
				"desc": "It cannot be beaten. It can be defied. Let the five hundred stand to at every bore and loose their three thousand arrows at the crest, so that nobody on this shore ever learns to kneel to it. The king pays for a second volley out of his own chest (spirit stones).",
				"log": "Had the crossbows of Yanggu shoot three thousand arrows into the tide at the crest, every eighth month."},
		],
		"after": {
			"wall": [["King Qian", "Baskets. Yes. I thought so, the third time, and did not trust it, because it was not grand. A king wants one great stone. Very well: every household weaves ten. I shall weave the first, badly, where they can see me do it."]],
			"yield": [["King Qian", "Give it the fields. I have held the shore below this market for thirty years and nobody has ever said that to my face. My engineers will weep. My fishermen have been building on stilts behind my back since my father's time, and they will say nothing at all, very loudly."]],
			"arrows": [["King Qian", "Ha! Again. And again next year. It is perfectly useless and I have never in my life wanted anything so much. Sound the drum. If we cannot be the stronger we shall at least not be the politer."]],
		},
		"echo": {
			"s_p24_qian2": {
				"wall": [["King Qian", "The first hundred paces of wall are up. A child pushed on it yesterday and it moved, and I nearly had him flogged, and then I understood that it is supposed to. I am learning my own shore at sixty."]],
				"yield": [["King Qian", "Nine houses are up on their legs already. An old woman has asked whether the bore might be persuaded to come a little further and do her cabbage bed; she says it has never had salt on it and is nothing but slugs."]],
				"arrows": [["King Qian", "The crossbowmen have asked for a banner. I said, what device? They said: a wave, with an arrow in it. Not through it. In it. I have never been prouder of anything so foolish."]],
			},
			"s_p24_end": {
				"wall": [["Elder Qing Xuan", "They tell me there is a new sea-wall at Yanggu that gives when it is pushed. I have been trying for forty years to teach disciples that, with a broom. I shall send them to look at a wall."]],
				"yield": [["Elder Qing Xuan", "They tell me a whole shore at Yanggu has stood up on stilts and let the sea in under it, on your word. Lin Feng: you. I should have liked to see your face when you said it."]],
				"arrows": [["Elder Qing Xuan", "They tell me five hundred crossbows shoot the sea every autumn at Yanggu, on your word. That does not sound to me like somebody who has learned to lose. It sounds like you. I find I am not sorry."]],
			},
		},
		"end": {
			"wall": "At Yanggu the sea-wall of ten thousand baskets gave a hand's breadth to every bore, and stood.",
			"yield": "At Yanggu the houses stand on legs, and the tide comes in under them and is thanked for the salt.",
			"arrows": "At Yanggu they shoot the tide every year. It has never been turned. Nobody born there has ever knelt.",
		}},
	"the_ape": {"step": "s_p24_ape", "part": "XXIV", "n": "The Ape of the Huai",
		"ask": "Wuzhiqi cannot be beaten: Great Yu could only chain him. He sits at the foot of Turtle Mountain with the Huai round his feet, and Bo Yi has the iron for a new chain, and is waiting. What is to be done about the Ape of the Huai?",
		"options": [
			{"id": "chain", "label": "Chain him again, as Yu did", "tilt": {"heart": -2, "craft": -2}, "gain": {"renown": 5},
				"desc": "It held for four thousand years. Forge the links, put the bell through his nose, and set the pillar back under Turtle Mountain. It is what the old books say was done, and every town on the river will sleep (renown).",
				"log": "Had Wuzhiqi chained again under Turtle Mountain, with a bell through his nose, as Yu did."},
			{"id": "dredge", "label": "Cut the river a road, and let him go to the sea", "tilt": {"heart": 2, "craft": 2}, "gain": {"hearth": {"river": 3}},
				"desc": "Yu did not beat the flood either; he gave it somewhere to go. Cut nine channels, one for each year Gun's wall stood, with the iron for sluices, and leave the ape his river all the way down to the sea. The Boat Hearth will dig with you (regard of the River Folk).",
				"log": "Had nine channels cut for the Huai with the iron of the chain, and let Wuzhiqi go down to the sea."},
			{"id": "boats", "label": "It is his river. Learn to float", "tilt": {"reach": 2, "craft": -1}, "gain": {"stones": 2000},
				"desc": "He was here before the river had a name. Let the Drowned Fields be drowned, and put every house on a hull. Bo Yi can sell the iron (spirit stones). People have lived on water before, and travelled further for it.",
				"log": "Left the Huai to Wuzhiqi, and had the people of the Drowned Fields build their houses on boats."},
		],
		"after": {
			"chain": [["Bo Yi of the Dykes", "As Yu did. Well, it is what I asked the iron for. He will let us, you know. That is the worst of it. He let Gengchen. He holds his neck out like an ox, and looks at you while you do it."]],
			"dredge": [["Bo Yi of the Dykes", "Channels. With my chain-iron for sluice gates. Yu said it so often I hear it in my sleep. Gun would say: of course. Nine cuts. I shall need every boat-hand on the river and I shall not have to ask twice."]],
			"boats": [["Bo Yi of the Dykes", "Four thousand years I have given water somewhere to go, and you tell me to give it everything. Hm. My knees have been saying it for some time. Very well. I shall want a boat with a proper bed in it."]],
		},
		"echo": {
			"s_p24_boyi2": {
				"chain": [["Bo Yi of the Dykes", "The bell is in. He did not make a sound. On still nights now it rings once, and every dog in the Drowned Fields lies down. I have done this twice. I do not wish to live long enough to do it a third time."]],
				"dredge": [["Bo Yi of the Dykes", "The first cut was opened at dawn. He went down it. He did not hurry; he looked at the sluice as he passed, the way a man looks at a gate somebody has at last thought to put in a wall. The fields are draining."]],
				"boats": [["Bo Yi of the Dykes", "Thirty hulls afloat, and a hen-coop on every one. He came and looked, with his neck right out, over the roofs. A child threw him a bean-cake. I am told he ate it. I am told many things, lately."]],
			},
			"s_p24_end": {
				"chain": [["Elder Qing Xuan", "And the ape is chained again. It is what I should have done. I say so because I notice you do not look as if you thought that settled it."]],
				"dredge": [["Elder Qing Xuan", "And you let the ape go, and gave the river a road. Yu's own answer, to a thing Yu did not dare apply it to. I shall be thinking about that after you are an Immortal and I am a tablet."]],
				"boats": [["Elder Qing Xuan", "And a whole country has gone to live on boats, with an ape for a landlord. I do not understand it. I am told they are cheerful. I have stopped expecting to understand what you leave behind you."]],
			},
		},
		"end": {
			"chain": "Under Turtle Mountain the Ape of the Huai is chained again, and his bell rings once on still nights.",
			"dredge": "The Huai runs to the sea by nine channels, and the Drowned Fields of Gun are called the New Fields.",
			"boats": "In the Drowned Fields a village floats, and its children say the ape is why they can all swim.",
		}},
	"the_horse": {"step": "s_p24_weng2", "part": "XXIV", "n": "The old man's horse",
		"ask": "The black horse broke Sai Weng's son and saved him from the riders. It stands behind the tent, and the whole frontier will do with its luck as the old man does with his. He has asked you to say. What is to be done with a horse like that?",
		"options": [
			{"id": "keep", "label": "Keep it by the tent, and never ride it", "tilt": {"reach": -3, "heart": 1}, "gain": {"hearth": {"dawn": 3}},
				"desc": "It came, and it is here. Put rails round it by the old man's door, and let the boy water it. Whatever is home is to be kept, lame or dangerous or neither. The Felt Hearth will understand that at once (regard of the Horse-Folk).",
				"log": "Told Sai Weng to keep the black horse by his tent, unridden."},
			{"id": "loose", "label": "Take down the rails. Let it run", "tilt": {"reach": 3, "craft": -1}, "gain": {"renown": 5},
				"desc": "It was never his. It came over the frontier and it may go back over it, and bring what it brings. A people who shut nothing in will be heard of a long way off (renown).",
				"log": "Told Sai Weng to take down his rails and let the black horse run."},
			{"id": "breed", "label": "Breed from it, and write down the lines", "tilt": {"craft": 3, "heart": -1}, "gain": {"stones": 2600},
				"desc": "Luck that walks in can be kept in the blood. Put it to the frontier mares, keep a stud book, and in ten years let every tent have a horse like it. The tents will pay well to be first (spirit stones).",
				"log": "Told Sai Weng to breed from the black horse, and keep a stud book of the frontier."},
		],
		"after": {
			"keep": [["Sai Weng", "By the tent. Where I can see it and it can see the north. Good. A thing need not be of any use to be one's own. My son will spoil it."], ["Weng the Younger", "I have already begun."]],
			"loose": [["Sai Weng", "Rails down. Yes. It will go, and the neighbours will come and say what a loss, and I shall say: how do you know? And for once, sweeper, I shall not know either. I am looking forward to it."]],
			"breed": [["Sai Weng", "A stud book. Sire, dam, foal. You want to write luck down and get more of it. I shall keep your book. And I shall write at the bottom of every page: so far."], ["Weng the Younger", "He will, too."]],
		},
		"echo": {
			"s_p24_end": {
				"keep": [["Elder Qing Xuan", "And the horse stays at the old man's door, unridden. A sweeper's answer. I kept you three years with a broom for no better reason than that you had come to it."]],
				"loose": [["Elder Qing Xuan", "And the horse runs loose. The old man will have enjoyed that. He has wanted for forty years to not know what happens next, and been too sensible to arrange it."]],
				"breed": [["Elder Qing Xuan", "And the frontier is to breed from it, by the book. You have never liked leaving a good thing to chance. I only say: the old man is right about the bottom of the page."]],
			},
			"post:s_break29": {
				"keep": [["Narrator", "On the frontier a black horse stands in a paddock of birch rails with its red ear turned to the north, and a boy with a stiff leg is carrying it water it does not need."]],
				"loose": [["Narrator", "On the frontier a paddock stands with its rails down, and some nights there are hoofbeats past the old man's tent, and some mornings a strange foal in the herd."]],
				"breed": [["Narrator", "On the frontier there is a board with the lines of forty horses painted on it, and at the foot of it, in an old man's charcoal: so far."]],
			},
		},
		"end": {
			"keep": "On the frontier a black horse grew old in a paddock by a tent, never ridden, and the paddock is kept.",
			"loose": "On the frontier the herds run without rails, and the horse-folk have stopped calling it luck either way.",
			"breed": "On the frontier every tent has a horse of the black one's line, and at the foot of each stud book: so far.",
		}},
	# ---- Part XXV (the Three Burrows release): a town's debts, a town's gate, and whose name is over its hall
	# ---- Part XXVI (the Underclothes release): what becomes of the book of a physician who was put in chains for it
	"the_sack": {"step": "s_p27_sack", "part": "XXVII", "n": "The Cloth Sack",
		"ask": "Budai's sack is on the ground, and everything Lin Feng has ever carried for anybody is in it: a broom, a seal, a town, the sky. A king has just set his pagoda down. The monk is waiting. What comes after?",
		"options": [
			{"id": "carry", "label": "Pick it up again, all of it", "tilt": {"heart": 3, "reach": 2}, "gain": {"renown": 6},
				"desc": "It is heavy and it is his, because nobody else's back was there. He will go on carrying whatever anybody hands him, for as long as there is a road, and know to the jin what it weighs (renown).",
				"log": "Picked the sack up again, and went on carrying for whoever asked."},
			{"id": "share", "label": "Put a strap on it for every shoulder", "tilt": {"craft": 3, "reach": 1}, "gain": {"stones": 9000},
				"desc": "No load in the land carried by one back again: a board in every town with what is to be moved and a name against every strap. Something new, which carriers will pay their dues into gladly (spirit stones).",
				"log": "Shared the sack out: a strap for every shoulder, and a name against each."},
			{"id": "down", "label": "Leave it by his own gate, empty", "tilt": {"reach": -3, "craft": -2, "heart": -1}, "gain": {"hearth": {"valley": 3}},
				"desc": "He has carried enough. Let each thing go back to whoever it belongs to, as it did before there was a sweeper to hand it to, and let the sack hang empty by the road home (the regard of the Rice Hearth).",
				"log": "Left the sack hanging empty by the gate, and went in to supper."},
		],
		"after": {
			"carry": [["Narrator", "Lin Feng bends his knees, as Tao Kan taught him, gets a shoulder under the sack and stands up. It is exactly as heavy as it was. Budai claps his hands like a child at a conjuror."], ["Budai, the Cloth-Sack Monk", "Hah! And off it goes, on a back! That is the other half of the teaching, and nobody ever waits to see it. Here: a seed, for your smith's ring. It will hold all that, and you will carry it anyway. I know your kind. I am your kind."]],
			"share": [["Narrator", "Lin Feng takes the cord off the neck of the sack and begins to plait it into straps: two, four, a great many. Budai watches with his head on one side, and then starts handing him more cord out of the sack, which seems to have a good deal."], ["Budai, the Cloth-Sack Monk", "I never thought of that. Three hundred years with one sack and one shoulder, and I never once thought of that. Take a seed for your smith's ring, clever sweeper. And put a strap on the ring too, if you can find where."]],
			"down": [["Narrator", "Lin Feng looks into the sack a long time. Then he tips it up. What falls out is nothing: every thing in it has gone home already, and had only been waiting to be let. He folds the sack over his arm, like a cloak on a warm day."], ["Budai, the Cloth-Sack Monk", "Ahh. Most people need to be very old before they find it was empty. Here is the seed for your smith's ring. It holds everything, so naturally it is only given to somebody with nothing left to put in it. Go home. Eat something."]],
		},
		"echo": {
			"s_p28_wei": {
				"carry": [["Wei Ke, General of Jin", "They say you are the one who picked up a monk's sack and has not put it down. Then you will understand a general. I carry four thousand men, and I may not set one of them down either."]],
				"share": [["Wei Ke, General of Jin", "They say you are the one who put a strap on a load for every shoulder. I should like that done with a battle. Mine has one shoulder under it, and the shoulder is tired."]],
				"down": [["Wei Ke, General of Jin", "They say you are the one who set a great load down at his own gate and went in to supper. I envy you. A general sets nothing down until somebody takes it from him."]],
			},
			"s_p27_end": {
				"carry": [["Elder Qing Xuan", "And I hear you picked the monk's sack up again. Of course you did. I have watched you pick up everything that was ever put down near you since you were thirteen. I used to think it a fault. I think now it is simply what you weigh."]],
				"share": [["Elder Qing Xuan", "And I hear there is a board in the Silk Woods with a name against every strap. Smith Tie has put his on it, for charcoal, and so, I am told, has Auntie Zhou, for forty buckets. I have been wondering what an Elder might decently carry."]],
				"down": [["Elder Qing Xuan", "And I hear there is an empty sack hanging by the bamboo gate. I went down and looked in it. There was nothing there. I have not slept so well since I was made Elder, and I cannot tell you why."]],
			},
		},
		"end": {
			"carry": "On the roads of the land there are posts at the height of a shoulder, and a sweeper who carries what he is handed and knows what it weighs, and has never yet said that it was too much.",
			"share": "In every town of the south there is a board with the loads of the day on it, and a name against every strap, and nobody in that country has carried anything alone since.",
			"down": "By the gate of the Whispering Bamboo an old hemp sack hangs empty, and whoever comes home along that road looks into it, and goes on lighter.",
		}},
	# ---- Part XXVIII (the Answering Land release): what is owed for a kindness
	"the_knot": {"step": "s_p28_knot", "part": "XXVIII", "n": "The Knotted Grass",
		"ask": "An old man has tied grass in the dark for four nights to pay a general who has forgotten what he did. A sparrow carried four rings across the sky. The dead cannot rest for owing. What is owed for a kindness?",
		"options": [
			{"id": "nothing", "label": "Nothing. It was finished when it was done", "tilt": {"heart": 2, "reach": -2}, "gain": {"renown": 6},
				"desc": "A kindness is not a loan. Whoever did it has forgotten, and was right to. Let the old man straighten his back and go home, and let nobody in the land lie awake for what they were given (renown).",
				"log": "Said that a kindness is finished when it is done, and sent the old man home."},
			{"id": "ledger", "label": "Write it down, so that it can be paid", "tilt": {"craft": 3, "heart": -1}, "gain": {"stones": 9500},
				"desc": "Thanks that have nowhere to go turn into grass tied in the dark. A book in every town, then: what was done, by whom, for whom, and a line to strike it through when it is answered. Something new (spirit stones).",
				"log": "Had the kindnesses of the land written in a book, each with a line to strike it through."},
			{"id": "onward", "label": "It is owed to the next stranger", "tilt": {"reach": 3, "heart": 2}, "gain": {"hearth": {"dawn": 3}},
				"desc": "The general cannot be paid; he does not know he is owed. So pay somebody else, who will not know why either, and let it go on down the road until nobody can find where it began (the regard of the Lantern Hearth).",
				"log": "Said that a kindness is owed onward, to the next stranger on the road."},
		],
		"after": {
			"nothing": [["Narrator", "The old man's hands stop. He looks at the knot he has half made for a long moment, and then, very slowly, he pulls the stems apart and smooths them straight. It is the first knot he has untied that had tripped nobody."], ["The Old Man in the Grass", "Finished when it was done. Eleven years I have been owing, and nobody thought to tell me the account was closed the day it was opened. Help me up. My daughter's children are waiting, and I have been a long time in this field."]],
			"ledger": [["Narrator", "Lin Feng takes out a brush. The old man watches him write it down: a concubine, a father's two orders, the one that was followed, a bolt of cloth, four nights of grass. When it is on the page he reads it over twice, moving his lips."], ["The Old Man in the Grass", "There. It is somewhere. I may stop carrying it about in my hands. Draw the line through it, sweeper, where it says paid. No: give me the brush. I should like to draw that line myself."]],
			"onward": [["Narrator", "The old man laughs, a dry sound like grass in wind. He finishes the knot he is tying, and then walks ten paces down the field, to a place where no army has ever stood or will, and ties another, for nobody."], ["The Old Man in the Grass", "Somebody will come along this row one day in trouble, and something will trip whatever is after him, and he will never know. That is better than a general. Go on, sweeper. I have a deal of field to do, and it is all for strangers now."]],
		},
		"echo": {
			"s_p28_end": {
				"nothing": [["Elder Qing Xuan", "And I hear you told a dead man that nothing was owed. I went and told the woman with the persimmons the same. She said: then I shall send them because I like to. I had no answer to that. I do not think there is one."]],
				"ledger": [["Elder Qing Xuan", "And I hear there is to be a book in every town with the kindnesses in it. Old Shen has begun ours. My name is on the first page, against a thing I did forty years ago for the wrong reason. He has left a very long line for the answer."]],
				"onward": [["Elder Qing Xuan", "And I hear you told a dead man to pay a stranger. I carried the persimmons down to the outer court and gave them to forty disciples who had not earned them. They will owe somebody. Let them find out whom."]],
			},
		},
		"end": {
			"nothing": "In the Valley of Sunrise there is a field where the grass stands straight, and a cairn where an old man put down what he owed. People who pass it sleep that night as they have not since they were children.",
			"ledger": "In every town of the land there is a book of what was done for whom, and most of its lines are struck through, and people read it on winter evenings the way they used to read the almanac.",
			"onward": "Along the roads of the land the grass is tied here and there in knots, at the height of an ankle, by nobody anybody has seen. Now and then something that was chasing somebody falls over.",
		}},
	"the_book": {"step": "s_p26_book", "part": "XXVI", "n": "The Blue Bag Book",
		"ask": "Hua Tuo's book is in the jailer's wife's hands over a brazier: the powder, the needle, the knife and the five frolics, everything he knows. It will save lives. It put him in chains. What becomes of it?",
		"options": [
			{"id": "copy", "label": "Copy it out for every counter of the post", "tilt": {"craft": 3, "reach": 2}, "gain": {"renown": 6},
				"desc": "A copy on the counter of every post office in the land, for whoever can read and wants to. Some hands will be clumsy and some will be wicked, and a great many will be a grandmother's at midnight with nobody else to ask (renown).",
				"log": "Had the Blue Bag Book copied out for every counter of the post."},
			{"id": "keep", "label": "Keep it at the Hall of the Broom", "tilt": {"craft": -2, "reach": -3}, "gain": {"hearth": {"valley": 3}},
				"desc": "One copy, in Guiyun, where it can be watched over. Whoever wants it must come and sweep the street a season, and then sit with it and be taught it by somebody who knows. Slower and safer, and one fire away from ashes (the regard of the Rice Hearth).",
				"log": "Kept the Blue Bag Book at the Hall of the Broom, for whoever sweeps."},
			{"id": "burn", "label": "Let her burn it", "tilt": {"heart": 3, "craft": -2}, "gain": {"renown": 2},
				"desc": "As she said: what did it do for him? Let what he knows stay in him, and pass from hand to hand the old way, from somebody to somebody. No physician will be put in chains for a page again. A great deal will be lost (a little renown).",
				"log": "Let the jailer's wife burn the Blue Bag Book."},
		],
		"after": {
			"copy": [["Hua Tuo", "Every counter of the post. Some fool in a river town will read the page on the knife and try it on his brother. And some grandmother will read the page on the frolics and still be going to the well at ninety. I have done the sum all night. It comes out on the grandmother's side."], ["Narrator", "Mistress Wu puts the book into Lin Feng's hands, and then, after a moment, puts her own hand flat on the cover, as if to keep it warm."]],
			"keep": [["Hua Tuo", "A street to sweep first. Good. Anybody who will sweep a street for a season to learn how to set a bone is somebody I should have liked to teach. It will be slow. Medicine is slow. Only sickness is in a hurry."], ["Narrator", "The book goes up the mountain in its blue bag on Yue Ling's back. At Guiyun the steward clears a shelf for it, and then a room, and then, without being asked, enters it in the accounts as the most valuable thing the town owns."]],
			"burn": [["Narrator", "The blue bag goes into the brazier first, and then the book, a handful of pages at a time. Hua Tuo watches from the step. When the page on the frolics goes in he says, quite quietly, the tiger, the deer, the bear, the ape, the bird, and that is all."], ["Mistress Wu, the Jailer's Wife", "He is not angry. That is the worst of it. He says he will have to teach it all again, to people, one at a time, the old way. He says it as if it were good news."]],
		},
		"echo": {
			# Part XXVII (the Heavy Road release)
			"s_p27_seed": {
				"copy": [["Chan Master Zhichang", "There is a physician's book on the counter of the post below, by the way, with a stone on it. The prefect read it in an afternoon. I have set him to carrying water for the sick of the village. He is on the second page, in his arms."]],
				"keep": [["Chan Master Zhichang", "They tell me a physician's book is kept at your town behind a broom, and must be swept for. Whoever thought of that has understood about scrolls. I should like to send you a prefect."]],
				"burn": [["Chan Master Zhichang", "They tell me you let a physician's book be burned, and that he teaches it by hand now. The prefect was horrified. I told him it was the only one of all his ten thousand that had ever been carried."]],
			},
			"done:s_p26_herbs": {
				"copy": [["Hua Tuo", "One of them has a copy already: it came to the counter at Longmen, and she read the page on the needle on the boat. She has it wrong in three places. I am delighted. Nobody gets anything wrong that they have not read."]],
				"keep": [["Hua Tuo", "They asked where the book was. I said: at Guiyun, behind a broom. One of them went straight there and is sweeping. The other two are staying here, to see whether I am worth the sweeping."]],
				"burn": [["Hua Tuo", "They asked where the book was. I said: in me, and now in you, a little. It is a smaller book than it was. It is the only kind that has never been taken off anybody at a gate."]],
			},
			"s_p26_end": {
				"copy": [["Elder Qing Xuan", "There is a copy of a physician's book on the post counter in Qingshi, they tell me, with a stone on it against the wind. The postmaster says it is the most borrowed thing he has ever had on the counter, and the only one ever brought back."]],
				"keep": [["Elder Qing Xuan", "And the book is at Guiyun, behind a broom. Good. A thing that must be swept for is a thing that will be read properly. I have three hundred years of scriptures here that nobody ever had to sweep for, and you see what they taught me about sitting."]],
				"burn": [["Elder Qing Xuan", "I hear the book was burned, and that he did not mind. I mind, a little. But I have kept a library for seventy years, and I have also seen what a book can be made to say by somebody who has only read it. Let it be taught, then, the old way."]],
			},
		},
		"end": {
			"copy": "On the counter of every post office in the land there is a book in a blue bag, held down with a stone against the wind, and it is the most borrowed thing in any town.",
			"keep": "At Guiyun there is a room with a book in a blue bag in it, and a broom by the door, and anybody who has swept the street a season may come and sit with it.",
			"burn": "Hua Tuo's book was burned at the door of a jail, and everything in it is taught still, by somebody to somebody, in the old way, and nobody has ever been put in chains for a page.",
		}},
	"the_tallies": {"step": "s_p25_tally", "part": "XXV", "n": "The tallies of Guiyun",
		"ask": "Every household of Guiyun owes the chest for seed, timber and its first winter. The Great Rat kept the tallies better than the town did, and now they lie in a basket in the square with everybody looking at them. What is to be done with the debts?",
		"options": [
			{"id": "burn", "label": "Burn them, here, where they can see", "tilt": {"heart": 3}, "gain": {"renown": 6, "hearth": {"valley": 3}},
				"desc": "As Feng Xuan did at Xue. Nobody in Guiyun owes anybody for having come. The chest will be the poorer for it every day, for good; and people who hear what was done with the basket will walk a long way to live behind such a gate (renown; a family asked brings more of its kin and the town grows faster; lower dues).",
				"log": "Had the tallies of Guiyun burned in the square."},
			{"id": "collect", "label": "Collect them, to the last notch", "tilt": {"heart": -3, "reach": -1}, "gain": {"stones": 9000},
				"desc": "A debt is a debt, and a town that begins by forgiving one will be asked to forgive everything after. Every tally is called in at the harvest, in full. The chest fills. Fewer will come to a town that is known to count (spirit stones now, and higher dues; the town grows more slowly of itself).",
				"log": "Had every debt of Guiyun collected to the notch."},
			{"id": "shares", "label": "Make each debt a share in a mill", "tilt": {"craft": 3}, "gain": {"stones": 3000},
				"desc": "Neither forgiven nor called in: turned. Each household's tally becomes its share in a mill on the windy shoulder above the well, built with what is owed, whose toll pays the chest for ever. Nobody is the poorer, nobody is let off, and there is a wheel going round (some spirit stones now; steadier dues).",
				"log": "Turned the debts of Guiyun into shares in a mill."},
		],
		"after": {
			"burn": [["Narrator", "The basket goes up in the middle of the square like dry reeds. Nobody cheers. An old woman at the back says, quite loudly, that it is a waste of good bamboo, and then sits down on the well-kerb and cries."], ["Feng Xuan", "I have now done this twice. The first time I was sure. This time I watched somebody else be sure, and it is a better fire. I shall enter it: forgiven, in full. I shall leave the column blank where the sum should go."]],
			"collect": [["Feng Xuan", "To the notch. Very well. I shall do it myself, door by door, with the half-tally in my hand. I shall be civil, and they will pay. They will also stop telling me things. I say so only that it may be in the accounts."], ["Yue Ling", "Nobody in the square is looking at us any more. They are looking at their own doors."]],
			"shares": [["Feng Xuan", "A mill. Their debt, going round. Forty years of books, and I never once thought to make a thing out of a sum. It is neither mercy nor rigour. It is carpentry. I shall want a new kind of column."], ["Narrator", "The half-tallies are nailed in a row along the mill-house wall before there is a mill-house. Children learn their own family's notches by counting from the left."]],
		},
		"echo": {
			# Part XXVII (the Heavy Road release)
			"s_p27_cart": {
				"burn": [["The Charcoal Seller", "They say there is a town up your mountain where the tallies were burned in the square. I did not believe it. A place where what is owed is let go. I have been owed for forty years by people with papers."]],
				"collect": [["The Charcoal Seller", "They say in your town every debt is collected to the notch, and written up where all can read it. Good. I can bear a hard price. It is a price nobody will show me that I cannot carry."]],
				"shares": [["The Charcoal Seller", "They say in your town a debt is a share in a mill. If the palace had taken a share in my kiln instead of my cart, I should be a rich man, and it would have had charcoal every winter for forty years."]],
			},
			# Part XXVI (the Underclothes release)
			"s_p26_book": {
				"burn": [["Yue Ling", "You burned the tallies of Guiyun once, in the square, and it was a better fire than anybody expected. This is a different fire, Lin Feng. A tally is a debt. This is a cure."]],
				"collect": [["Yue Ling", "You collected the tallies of Guiyun to the notch. Everything owed, everything paid. She is asking you whether a cure can be owed too."]],
				"shares": [["Yue Ling", "You turned the tallies of Guiyun into a mill, once: neither burned nor called in. Perhaps there is a third thing to do with a book, too."]],
			},
			"done:s_p25_town": {
				"burn": [["Feng Xuan", "One thing more, for the books. Eleven households have paid what they owed. Nobody asked; the tallies are ash. They left it on my table at night, in grain, with no name. I have had to open a column for it. I have called it: the other half."]],
				"collect": [["Feng Xuan", "One thing more, for the books. The chest is full. They pay on the day, to the grain, and wait while I count. Nobody has asked me in to tea since the harvest. I had not known that I should miss being asked."]],
				"shares": [["Feng Xuan", "One thing more, for the books. The mill ground its first sack this morning, and every household came out to watch its own debt go round. Sawyer Bo has worked out that he owns one tooth of the great wheel. He has marked it."]],
			},
			"s_p25_end": {
				"burn": [["Elder Qing Xuan", "I hear there was a fire in your square, early on, and that the whole town's debts went up in it. The steward's old trick. It is not a trick when the one who does it could have used the money."]],
				"collect": [["Elder Qing Xuan", "I hear your chest is full, and every door paid to the notch. It is honest. I only say that I have sat seventy years under a roof nobody paid for by the notch, and it has not leaked more than other roofs."]],
				"shares": [["Elder Qing Xuan", "I hear your people's debts go round in a mill and grind their own flour. You never could leave a thing as either one or the other. I stopped thinking that a fault some years ago."]],
			},
		},
		"end": {
			"burn": "In Guiyun there is a bare place in the square where nothing is built, and the old tell the young what was burned there, and the young do not quite believe it.",
			"collect": "In Guiyun every debt was paid to the notch, and the chest has never wanted for anything, and the steward takes his tea alone.",
			"shares": "In Guiyun a mill turns above the well, and every household can show you the tooth of the wheel that is its own.",
		}},
	"the_door": {"step": "s_p25_door", "part": "XXV", "n": "The gate of Guiyun",
		"ask": "The terraces are coming up the road, and behind them people of every hearth and of none: Feathered Folk with a hand-cart, shades who walk at night. The Cloud Gate is not built yet, and something must be cut over it. Who may live at Guiyun?",
		"options": [
			{"id": "all", "label": "Whoever knocks", "tilt": {"reach": 3}, "gain": {"renown": 5},
				"desc": "No question at the gate but the kitchen's: have you eaten? The winged, the scaled, the dead who walk at night, the one nobody will speak for. It will be a strange town, and a loud one, and there will be more of it (renown; room for more households, and the town grows faster of itself).",
				"log": "Had it cut over the gate of Guiyun: whoever knocks."},
			{"id": "hearth", "label": "Whoever a hearth will answer for", "tilt": {"reach": -3, "heart": 1}, "gain": {"hearth": {"valley": 3, "river": 2, "steppe": 2}},
				"desc": "Anybody may come whom one of the six hearths of the land will speak for: a keeper's word, a neighbour's. Every village in the valley has always done it so. Those nobody will speak for go on up the road. The hearths will not forget having been asked (regard of three hearths).",
				"log": "Had it cut over the gate of Guiyun: whoever a hearth will answer for."},
			{"id": "sweep", "label": "Whoever sweeps the street a season", "tilt": {"craft": -3, "heart": 1}, "gain": {"renown": 3},
				"desc": "The sect's own way, older than its walls: nobody is asked where they come from, and nobody is given a door until they have swept the street from the gate to the well for one season. Most stay. Whoever will not hold a broom was not coming here to live (renown; the town counts for more in the land).",
				"log": "Had it cut over the gate of Guiyun: whoever sweeps the street a season."},
		],
		"after": {
			"all": [["Feng Xuan", "\"Whoever knocks.\" Two words. The carver is pleased. I am less so, being the one who must find them all a roof; but I notice I have already begun to count beds."], ["Narrator", "The two shades of Youdu come out from under their tarpaulin at dusk and are given the night watch on the unfinished wall, which nobody else wanted. They are the best at it that Guiyun will ever have."]],
			"hearth": [["Feng Xuan", "A word from a hearth. The old way, then. I shall write to the six keepers tonight and tell them their word is good at our gate. They will like that more than they will say."], ["Narrator", "The Feathered Folk wait three days on the road beside their hand-cart. On the fourth Granny Wen comes up from Qingshi herself, out of breath, looks them over, says she delivered a child with shoulders like that once, and that they will do."]],
			"sweep": [["Feng Xuan", "A broom. Naturally. I ought to have known what you would hang over a gate. I shall order forty, and find somebody to make more."], ["Narrator", "By the first frost the street of Guiyun is the cleanest road in the Unbroken Land, swept twice a day by tea-pickers, two shades, a family with wings, and one very old cock-crower who will not be told that it is not his turn."]],
		},
		"echo": {
			# Part XXVI (the Underclothes release)
			"done:s_p26_dawn": {
				"all": [["Wu Pu", "And at Guiyun, they tell me, the two shades on the wall do the bird at midnight, where nobody can see them, because the gate says whoever knocks and they did not like to knock on the morning."]],
				"hearth": [["Wu Pu", "And at Guiyun every hearth that answered for a family sends somebody to the square at dawn, so as not to be outdone by the other five. It is the best-attended frolic in the land, and the most competitive."]],
				"sweep": [["Wu Pu", "And at Guiyun they sweep the street first, and then do the bear with the brooms still in their hands. The master says it is the first improvement anybody has made to his frolics in forty years."]],
			},
			"done:s_p25_rogues": {
				"all": [["Feng Xuan", "As for these: the gate says whoever knocks. They did not knock. They came over the wall. I have told them to go out and come in again properly, and they are standing in a line."]],
				"hearth": [["Feng Xuan", "As for these: who will answer for them? ...I shall. Do not look at me so. I stood at a lord's gate once with a sword and no fish, and nobody spoke for me. I am a hearth of one."]],
				"sweep": [["Feng Xuan", "As for these: there are brooms. The dog-thief has asked for the one by the granary. I have said yes, and that I shall count the grain every night; and he said he would think the less of me if I did not."]],
			},
			"done:s_p25_city": {
				"all": [["Narrator", "On the gate-tower, over the arch, in characters a hand high: WHOEVER KNOCKS. The knocker is worn bright already."]],
				"hearth": [["Narrator", "On the gate-tower, over the arch, hang six small boards, one from each hearth of the land. Room has been left for a seventh."]],
				"sweep": [["Narrator", "On the gate-tower, over the arch, where another town would have its name, somebody has hung a broom."]],
			},
		},
		"end": {
			"all": "Over the gate of Guiyun it says: whoever knocks. Nobody now remembers that it was once a question.",
			"hearth": "Over the gate of Guiyun hang the boards of six hearths, and anybody one of them will speak for is let in, and a great many letters are written.",
			"sweep": "Over the gate of Guiyun hangs a broom. Its street is the cleanest in the land, and nobody who lives on it was ever asked where they came from.",
		}},
	"the_seat": {"step": "s_p25_seat", "part": "XXV", "n": "The seat over the hall",
		"ask": "Han Song is beaten, and three hundred disciples of the Cold Pine stand at the Cloud Gate with no master. The Hall of the Broom has a bare lintel. A sect is a name over a door and somebody who answers to it. Whose name goes over the door?",
		"options": [
			{"id": "found", "label": "A gate of your own: the Returning Cloud", "tilt": {"craft": 3, "reach": 1}, "gain": {"renown": 8},
				"desc": "A new name that nobody has heard: the Returning Cloud Sect, founded at Guiyun, whose first lesson is a street. The three hundred may stay if they will begin again at the beginning, with a broom. Some will. The youngest sect in the land, and yours from the first stone (renown; more of the town sends its children to the hall).",
				"log": "Founded the Returning Cloud Sect at Guiyun."},
			{"id": "take", "label": "Take the Cold Pine's seat", "tilt": {"heart": -3, "reach": 2}, "gain": {"stones": 8000},
				"desc": "He said it himself: they follow whoever beat the master. Take his seat, his name, his mountain and his three hundred, all in one evening: an old sect with halls on Frostpeak and sixty years of discipline in its hands, and a patriarch nobody asked for (spirit stones from its treasury; the most disciples; the town counts for much more in the land).",
				"log": "Took the seat of the Cold Pine Sect."},
			{"id": "serve", "label": "Hang the Azure Cloud's board", "tilt": {"craft": -3, "reach": -2, "heart": 1}, "gain": {"hearth": {"valley": 4}},
				"desc": "There is a name over you already, and you have never stepped out from under it. The Hall of the Broom becomes a hall of the Azure Cloud Sect, and its children go up the nine hundred and ninety-nine steps in the spring. The three hundred are sent home to choose a master of their own. You stay what you were (regard of the Rice Hearth).",
				"log": "Hung the board of the Azure Cloud over the Hall of the Broom."},
		],
		"after": {
			"found": [["Narrator", "The board is cut that night from a plank of persimmon. THE RETURNING CLOUD. The paint is still wet when the first of the three hundred takes off his pine-green coat, folds it, and asks where the brooms are kept."], ["Feng Xuan", "A sect with no history. I shall begin one. Volume one, page one: on the first day the founder was asked what the first lesson was, and pointed at the street."]],
			"take": [["Narrator", "Three hundred kneel in the rain, all to the same depth. It is done in a breath. Lin Feng stands before them holding four tablets of black lacquer and feels the weight of each. None of them is heavy. That is the worst of it."], ["Yue Ling", "They did not look up. Not one. Lin Feng, they would have knelt to anybody who came down that mountain. I do not think they have seen yet who it was."]],
			"serve": [["Narrator", "A disciple is sent up the nine hundred and ninety-nine steps for a board, and comes down with the oldest the sect has: black, split, taken off a gate two rebuildings ago. The Elder has sent no message with it. He has only had it dusted."], ["Feng Xuan", "A branch hall. Then there is somebody over you still, and my accounts go up the mountain once a year to be looked at. I find I do not mind. I was never easy keeping the books of somebody nobody could ask."]],
		},
		"echo": {
			# Part XXVI (the Underclothes release)
			"s_p26_end": {
				"found": [["Elder Qing Xuan", "And at the Returning Cloud they do the frolics before the first lesson, I hear, in the street. A sect of yours that begins by getting up. I wish I had thought of it seventy years ago."]],
				"take": [["Elder Qing Xuan", "And on Frostpeak, I hear, three hundred who stood in the snow for sixty years are being taught to look behind them like a deer. Han Song comes out of the gatehouse to watch. He says nothing. He has started doing the bear."]],
				"serve": [["Elder Qing Xuan", "And your hall at Guiyun sends its children up the steps to us in the spring, and this spring they did the frolics in our courtyard before they had put their bedding down. I watched from the window. I did the bird."]],
			},
			"done:s_p25_hermits": {
				"found": [["Feng Xuan", "One of them asked what the Returning Cloud teaches. I said: we have not found out. He said it was the first honest answer he had had from a sect, and unpacked."]],
				"take": [["Feng Xuan", "One of them asked whose the three hundred drilling on Frostpeak were. I said: the Patriarch's. He asked where the Patriarch was. I pointed at you. He looked for some time."]],
				"serve": [["Feng Xuan", "One of them was a disciple of the Azure Cloud forty years ago, and left over a quarrel about a broom. He has read the board over the door twice. He says he will stay until he has won the quarrel."]],
			},
			"s_p25_end": {
				"found": [["Elder Qing Xuan", "And a sect of your own. I had the gate disciples bring me word the hour the board went up. I am not hurt, child. I am an old man whose pupil has a gate; there is nothing better to be. Only teach them to sweep before you teach them anything, or I shall come down there."]],
				"take": [["Elder Qing Xuan", "And Patriarch of the Cold Pine. I knew Han Song when we were young and he was only proud. Three hundred who kneel to whoever won. Be careful of that, child. It is very quiet in front of people who are kneeling. One begins to take the quiet for agreement."]],
				"serve": [["Elder Qing Xuan", "And you sent up for a board. I gave you the old one, from the first gate. I sent no message with it, because I could not think of one that an old man can say aloud. It is said now. The board says it."]],
			},
			"post:s_break30": {
				"found": [["Narrator", "In the Hall of the Broom a child of the Returning Cloud Sect, six years old, is showing a hermit of ninety how to hold the short broom. The hermit is taking it very well."]],
				"take": [["Narrator", "On Frostpeak three hundred in pine-green are sweeping the snow off a courtyard that will be white again by noon, because the new Patriarch said to; and for the first time in sixty years one of them has asked why."]],
				"serve": [["Narrator", "Up the nine hundred and ninety-nine steps go eleven children of Guiyun with their bedding on their backs. At the top the gate disciple asks each of them the one question, and each of them has."]],
			},
		},
		"end": {
			"found": "At Guiyun there is a sect called the Returning Cloud, which has no history yet and a very clean street.",
			"take": "On Frostpeak the Cold Pine has a patriarch who beat the last one, and three hundred who are learning, slowly, to look up.",
			"serve": "At Guiyun the Hall of the Broom hangs the Azure Cloud's oldest board, and sends its children up the steps every spring.",
		}},
}
const ORDER := ["bandits", "garden", "roc_egg", "palace", "dragon_boon", "drawings", "nineteen", "ancestor", "widow", "crows", "axe", "cauldron_map", "furnace",
	"the_wheel", "the_player", "the_works", "the_mountain", "the_echoes", "the_hollow",
	"the_pupils", "the_three_thousand", "the_arms",
	"the_voices", "the_kites", "the_tops",
	"the_clay", "the_lute", "the_host",
	"the_tide", "the_ape", "the_horse",
	"the_tallies", "the_door", "the_seat",
	"the_book",
	"the_sack",
	"the_knot"]

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
		else:
			# (the Hundred Arms release: any other need a trial's path could have, in the trials' own words)
			parts.append("%s %s" % ["[x]" if Trials.need_met(n, g) else "[ ]", Trials.need_text(n, g)])
	var tips: Array = []
	for sc in o.get("tilt", {}):
		var v := int(o.tilt[sc])
		tips.append(str(SCALES[sc].pos if v > 0 else SCALES[sc].neg).to_lower().trim_prefix("of "))
	if not tips.is_empty():
		parts.append("Leans towards: " + ", ".join(tips) + ".")
	return "\n".join(parts)

## What answer `oid` of crossroads `id` leaves standing in the land (marks.gd), in words ("" if nothing).
static func stands_text(id: String, oid: String) -> String:
	var mk: Dictionary = Marks.MARKS.get(id, {}).get(oid, {})
	if mk.is_empty():
		return ""
	return "%s, in %s" % [str(mk.n), str(Data.AREAS[str(mk.area)].n)]

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
	# (the Answering Land release, weal.gd: the towns that hear of the answer are changed by it)
	Weal.poll(g)

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
	if stands_text(id, ch) != "":
		parts.append("")
		parts.append("It stands in the land: %s." % stands_text(id, ch))
	parts.append("")
	parts.append("In the end: " + str(c.get("end", {}).get(ch, "")))
	return "\n".join(parts)
