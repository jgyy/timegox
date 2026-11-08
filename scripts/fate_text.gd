class_name FateText
extends RefCounted
## The words of the fated encounters (fate.gd): every chapter's variants (keyed by the thread's state,
## "*" for any), its choice and what follows each option; what each state means (for the Fates page);
## how each thread ends (the epilogue told before the ending); and what each person says afterwards.
## Built from the storyline files by hand-checked merging; the tests check it against Fate.PATH.

const CHAPTERS := {
	"s_f_tala1": {
		"n": "A Herd in the Storm",
		"by": {
			"*": {
				"lines": [
					[
						"Narrator",
						"A girl comes down the scree at a run, a horn bow across her back and a long black braid tied with red cords flying behind her. Her fur-trimmed coat is soaked with storm-rain. She stops a sword's length from Lin Feng and looks him up and down."
					],
					[
						"Tala of the Horse-Folk",
						"You are the sect boy who has been killing storm-things all morning. The old ghost says you do not flinch at thunder. I am Tala. My people winter below the valley and breed cloud-horses, and as of two nights ago we have none."
					],
					[
						"Tala of the Horse-Folk",
						"The Roc's storms drove every deer and goat out of the valley, and the apes are starving. They came down on our camp, drove the whole herd into their gorge and rolled boulders across the mouth like a pen. Forty-one horses. They mean to eat them one by one.",
						"point"
					],
					[
						"Batu",
						"I went in after them last night. I nearly had the grey colt. Then an ape sat on me."
					],
					[
						"Yue Ling",
						"Two ribs broken and a third cracked. Lie still, Batu, or I will sit on you myself. Lin Feng, I saw those apes on the ridge. Their bones show through their fur. They are not wicked. They are hungry."
					],
					[
						"Lin Feng",
						"Why come to me, and not to your own people?"
					],
					[
						"Tala of the Horse-Folk",
						"My father is holding the camp together with both hands, and my brother is lying on a horse blanket. You are the only one in this valley with a sword who is not a ghost. My grandmother says asking twice is begging. So I am asking once."
					]
				],
				"ask": "How will you get the herd out of the apes' gorge?",
				"options": [
					{
						"id": "drive",
						"label": "Go in and drive the apes off",
						"desc": "Go into the gorge with Tala, break the apes' wall, fight off the apes and the storm hawks circling for scraps, and bring all forty-one horses home. The herd goes back to the horse-folk; the apes go back up the cliffs as hungry as before.",
						"log": "Drove the starving apes out of their gorge and brought the horse-folk's herd home.",
						"then": "driven",
						"battle": [
							[
								"thunder_ape",
								10
							],
							[
								"thunder_ape",
								10
							],
							[
								"storm_hawk",
								9
							]
						],
						"gain": {
							"ride": "pony"
						},
						"after": [
							[
								"Narrator",
								"The apes break and scatter up the cliffs, howling, and forty-one cloud-horses, grey and dun and white as storm cloud, come out of the gorge at a run and do not stop until they reach the camp."
							],
							[
								"Tala of the Horse-Folk",
								"Forty-one. Every one. ...That dun mare has bitten my father, my mother, my grandmother and Batu twice. She let you touch her nose. So she is yours. Do not argue; she will bite you too, and I will laugh.",
								"offer"
							],
							[
								"Yue Ling",
								"The apes went up those cliffs very hungry, Lin Feng."
							],
							[
								"Lin Feng",
								"I know. I have not ended their hunger. I have only sent it somewhere else."
							]
						]
					},
					{
						"id": "feed",
						"label": "Buy grain for the apes",
						"desc": "Spend 150 spirit stones on millet from the farms at the valley mouth and leave it on the cliff path, so the apes can eat and let the horses go. Nobody bleeds, man, horse or ape; the farmers are paid, and the apes have their winter's food.",
						"log": "Paid for the apes' winter grain, and the herd came home.",
						"then": "fed",
						"need": [
							[
								"stones",
								150
							]
						],
						"pay": {
							"stones": 150
						},
						"gain": {
							"ride": "pony",
							"renown": 6
						},
						"after": [
							[
								"Narrator",
								"Lin Feng and Yue Ling carry sacks of millet up the cliff path all afternoon. At dusk the apes come down, sniff, and fall on the grain, and not one of them looks up as forty-one cloud-horses walk out of the gorge behind them."
							],
							[
								"Tala of the Horse-Folk",
								"You fed the thieves. My father will call it foolish. My grandmother will call it cheaper than a war. I have not decided yet.",
								"think"
							],
							[
								"Tala of the Horse-Folk",
								"The dun mare bites everyone in my family. She let you touch her nose, so she is yours. Your sect people will call her a mountain horse. She is a steppe horse. Do not let her hear them.",
								"offer"
							],
							[
								"Batu",
								"She bit me twice. You will have to bring her back to visit, so I can watch her bite you.",
								"laugh"
							]
						]
					},
					{
						"id": "free",
						"label": "Open the pen and let them run",
						"desc": "Break open the apes' wall without a fight and let the herd run where it will: north, out of the storms, towards the steppe. Nobody bleeds and nothing is paid, but the horse-folk lose their herd to the open grass, and Tala loses her horses.",
						"log": "Broke open the apes' pen and let the herd run north to the steppe, nobody's but its own.",
						"then": "free",
						"gain": {
							"renown": 2
						},
						"after": [
							[
								"Narrator",
								"Lin Feng waits until the apes are squabbling on the far ridge, then cuts through their wall, and forty-one cloud-horses pour out of the gorge and away north into the rain. On the crest a dun mare stops, looks back once at him, and is gone."
							],
							[
								"Tala of the Horse-Folk",
								"You fool! You sect fool! That was our herd! That was our winter, and our salt, and Batu's first saddle, running away over the hill!",
								"shock"
							],
							[
								"Lin Feng",
								"Bring them home, and the apes come back for them. Fight the apes, and the apes starve. I would rather the horses chose."
							],
							[
								"Tala of the Horse-Folk",
								"...My grandmother says the herd always knows where the grass will be. She says it every time something goes wrong. I hate it when she is right before anything has even happened.",
								"think"
							]
						]
					}
				]
			}
		}
	},
	"s_f_tala2": {
		"n": "The Long Winter",
		"by": {
			"driven": {
				"lines": [
					[
						"Narrator",
						"In a pass on the Aurora Steppe the snow comes sideways out of a slate-grey sky. The horse-folk's herd stands in a ring, nose to tail, with the foals inside it, and outside the ring the ice lynxes walk in slow circles. A rider breaks away and gallops down."
					],
					[
						"Tala of the Horse-Folk",
						"Sect boy! They told me at the last camp you were an Ancestor now. You look the same. Taller. You have a gift for turning up just when my horses are about to be eaten.",
						"wave"
					],
					[
						"Tala of the Horse-Folk",
						"The apes came back the next autumn, hungrier than before. They took Batu's foal out of the pen in the night, the little bay he raised by hand. So we came north. My grandmother says you cannot argue with a hungry mouth; you can only move it further off."
					],
					[
						"Tala of the Horse-Folk",
						"Then the sky began to sag, and the north forgot to have a summer. The wind keeps the snow thin on the grass up here, so the horses can live. But the hares are gone, the lynxes are starving too, and tonight they mean to take the foals.",
						"point"
					],
					[
						"Yue Ling",
						"Look at the ridge, Lin Feng. There is a den under the rocks, and cubs in it. That is why they are so bold."
					],
					[
						"Batu",
						"Let me shoot them, Tala. They are not getting another foal of mine. Not one."
					],
					[
						"Lin Feng",
						"Put the bow down, Batu. Let me look first."
					]
				],
				"ask": "The lynxes are circling the foals. What will you do?",
				"options": [
					{
						"id": "hunt",
						"label": "Drive off the lynxes",
						"desc": "Stand between the lynxes and the foals and fight them off, and the frost yak that comes blundering down the pass behind them. The foals live through the night; the lynxes go back into the storm to their cubs with nothing.",
						"log": "Fought the starving lynxes away from the horse-folk's foals in the blizzard pass.",
						"then": "guardian",
						"battle": [
							[
								"ice_lynx",
								27
							],
							[
								"ice_lynx",
								27
							],
							[
								"frost_yak",
								26
							]
						],
						"gain": {
							"outfit": "hunter"
						},
						"after": [
							[
								"Narrator",
								"The lynxes melt back into the snow, and the frost yak goes bellowing off down the pass. Inside the ring the foals stand pressed against their mothers, steaming, alive."
							],
							[
								"Batu",
								"Not this time. Not one of them. Did you see, Tala? Not one!"
							],
							[
								"Tala of the Horse-Folk",
								"Here. Summer greens and a straw hat. I sewed them for the hunt in the reed country, and then the summer never came. Wear them when the grass comes back. I mean to be there to see it.",
								"offer"
							]
						]
					},
					{
						"id": "lead",
						"label": "Lead the herd through the storm",
						"desc": "Ride the dun mare out ahead of the herd and lead it through the blizzard by night, with Tala beside you, to the sheltered grass beyond the pass. It needs a ride of your own and a steady nerve; the lynxes go hungry, but nobody bleeds.",
						"log": "Led the herd through the blizzard by night on the dun mare, with Tala riding at his knee.",
						"then": "rider",
						"need": [
							[
								"rides",
								1
							]
						],
						"gain": {
							"outfit": "hunter",
							"ride": "pony",
							"renown": 6
						},
						"after": [
							[
								"Narrator",
								"All night they ride into the white, Lin Feng on the dun mare and Tala at his knee, and the herd follows the sound of the mare's bell. At dawn the pass opens on a hollow where the wind has swept the grass bare."
							],
							[
								"Tala of the Horse-Folk",
								"She led them as much as you did. She has been waiting a whole year for somebody to ask her.",
								"laugh"
							],
							[
								"Tala of the Horse-Folk",
								"Here. Summer greens and a straw hat. I sewed them for the hunt in the reed country, and then the summer never came. Wear them when the grass comes back. I mean to see you in them.",
								"offer"
							]
						]
					},
					{
						"id": "leave",
						"label": "Let the steppe take its due",
						"desc": "Do nothing, and let the lynxes take the weakest foals, as the steppe always has. The herd will live, and so will the lynx cubs in their den under the ridge; but foals will die tonight that a sword could have saved, and Tala will watch it.",
						"log": "Let the lynxes take the weakest foals, as the steppe always has, and the lynx cubs lived.",
						"then": "steppe",
						"gain": {
							"renown": 2
						},
						"after": [
							[
								"Narrator",
								"Lin Feng puts up his sword. Before dawn the lynxes take two foals from the edge of the ring and carry them up to the den under the ridge, and the crying under the rocks stops."
							],
							[
								"Batu",
								"You let them! You are a cultivator, and you let them, like the apes!",
								"shock"
							],
							[
								"Tala of the Horse-Folk",
								"Hush, Batu. He is right, and I know it. My grandmother would say the same: the weak foals feed the lynxes, and the lynxes keep the herd strong. I only wanted him to be the one person who would not.",
								"grieve"
							]
						]
					}
				]
			},
			"fed": {
				"lines": [
					[
						"Narrator",
						"In a pass on the Aurora Steppe the snow comes sideways out of a slate-grey sky. The horse-folk's herd stands in a ring, nose to tail, with the foals inside it, and outside the ring the ice lynxes walk in slow circles. A rider breaks away and gallops down."
					],
					[
						"Tala of the Horse-Folk",
						"Sect boy! They say you are an Ancestor now. You look the same. Taller. You have a gift for turning up just when my horses are about to be eaten.",
						"wave"
					],
					[
						"Tala of the Horse-Folk",
						"The apes never troubled us again. Batu takes a sack of millet up the cliff path every autumn, and they wait for him on the rocks like old aunties. But the winter did. When the sky began to sag, the snow came down into the valley to the horses' bellies."
					],
					[
						"Tala of the Horse-Folk",
						"So we came north, where the wind keeps the snow thin on the grass; it is the old way, in a bad winter. But the hares are gone, the lynxes are starving too, and tonight they mean to take the foals.",
						"point"
					],
					[
						"Yue Ling",
						"Look at the ridge, Lin Feng. There is a den under the rocks, and cubs in it. That is why they are so bold."
					],
					[
						"Lin Feng",
						"The apes were hungry too, once."
					],
					[
						"Tala of the Horse-Folk",
						"I knew you would say that. I cannot buy millet for lynxes, sect boy. Lynxes do not eat millet."
					]
				],
				"ask": "The lynxes are circling the foals. What will you do?",
				"options": [
					{
						"id": "hunt",
						"label": "Drive off the lynxes",
						"desc": "Stand between the lynxes and the foals and fight them off, and the frost yak that comes blundering down the pass behind them. The foals live through the night; the lynxes go back into the storm to their cubs with nothing.",
						"log": "Fought the starving lynxes away from the horse-folk's foals in the blizzard pass.",
						"then": "guardian",
						"battle": [
							[
								"ice_lynx",
								27
							],
							[
								"ice_lynx",
								27
							],
							[
								"frost_yak",
								26
							]
						],
						"gain": {
							"outfit": "hunter"
						},
						"after": [
							[
								"Narrator",
								"The lynxes melt back into the snow, and the frost yak goes bellowing off down the pass. Inside the ring the foals stand pressed against their mothers, steaming, alive."
							],
							[
								"Tala of the Horse-Folk",
								"Last time you paid for my horses with spirit stones. This time you paid with your sword. I think I like you better when it costs you something.",
								"laugh"
							],
							[
								"Tala of the Horse-Folk",
								"Here. Summer greens and a straw hat. I sewed them for the hunt in the reed country, and then the summer never came. Wear them when the grass comes back. I mean to be there to see it.",
								"offer"
							]
						]
					},
					{
						"id": "lead",
						"label": "Lead the herd through the storm",
						"desc": "Ride the dun mare out ahead of the herd and lead it through the blizzard by night, with Tala beside you, to the sheltered grass beyond the pass. It needs a ride of your own and a steady nerve; the lynxes go hungry, but nobody bleeds.",
						"log": "Led the herd through the blizzard by night on the dun mare, with Tala riding at his knee.",
						"then": "rider",
						"need": [
							[
								"rides",
								1
							]
						],
						"gain": {
							"outfit": "hunter",
							"ride": "pony",
							"renown": 6
						},
						"after": [
							[
								"Narrator",
								"All night they ride into the white, Lin Feng on the dun mare and Tala at his knee, and the herd follows the sound of the mare's bell. At dawn the pass opens on a hollow where the wind has swept the grass bare."
							],
							[
								"Tala of the Horse-Folk",
								"No blood and no stones this time. Only a sect boy on a bad-tempered mare, going first. My grandmother says that is all leading ever is.",
								"laugh"
							],
							[
								"Tala of the Horse-Folk",
								"Here. Summer greens and a straw hat. I sewed them for the hunt in the reed country, and then the summer never came. Wear them when the grass comes back. I mean to see you in them.",
								"offer"
							]
						]
					},
					{
						"id": "leave",
						"label": "Let the steppe take its due",
						"desc": "Do nothing, and let the lynxes take the weakest foals, as the steppe always has. The herd will live, and so will the lynx cubs in their den under the ridge; but foals will die tonight that a sword could have saved, and Tala will watch it.",
						"log": "Let the lynxes take the weakest foals, as the steppe always has, and the lynx cubs lived.",
						"then": "steppe",
						"gain": {
							"renown": 2
						},
						"after": [
							[
								"Narrator",
								"Lin Feng puts up his sword. Before dawn the lynxes take two foals from the edge of the ring and carry them up to the den under the ridge, and the crying under the rocks stops."
							],
							[
								"Tala of the Horse-Folk",
								"You fed the apes, and now you feed the lynxes. With my foals, this time.",
								"grieve"
							],
							[
								"Tala of the Horse-Folk",
								"No. That was unfair, and I know it. The weak foals feed the lynxes, and the lynxes keep the herd strong; my grandmother would say so. I only wanted you to be the one person who would not."
							]
						]
					}
				]
			},
			"free": {
				"lines": [
					[
						"Narrator",
						"In a pass on the Aurora Steppe the snow comes sideways out of a slate-grey sky. A wild herd sixty strong stands in a ring, nose to tail, with the foals inside it, and the ice lynxes walk in slow circles outside. A rider on a bare-backed grey gallops down."
					],
					[
						"Tala of the Horse-Folk",
						"You! The sect boy who opened the gorge! I have wanted to shout at you properly for a whole year, and now I have to ask you for help instead. They say you are an Ancestor. You look the same. Taller.",
						"point"
					],
					[
						"Tala of the Horse-Folk",
						"The herd ran north the way you sent it and found grass under the snow up here, where the wind keeps it thin. Wild horses joined it, and my people followed. We do not own them now. We run beside them. My father calls it poverty; my grandmother, the oldest way."
					],
					[
						"Tala of the Horse-Folk",
						"The dun mare who looked back at you is the lead mare now. She still bites me. But the hares are gone in this winter that will not end, the lynxes are starving, and tonight they mean to take the foals."
					],
					[
						"Yue Ling",
						"Look at the ridge, Lin Feng. There is a den under the rocks, and cubs in it. That is why they are so bold."
					],
					[
						"Lin Feng",
						"And the herd belongs to nobody now. Not even to you."
					],
					[
						"Tala of the Horse-Folk",
						"Nobody. So nobody has to save it. That is what free means up here: it means nobody comes. ...I am asking anyway."
					]
				],
				"ask": "The lynxes are circling the foals. What will you do?",
				"options": [
					{
						"id": "hunt",
						"label": "Drive off the lynxes",
						"desc": "Stand between the lynxes and the wild foals and fight them off, and the frost yak that comes blundering down the pass behind them. The foals live through the night; the lynxes go back into the storm to their cubs with nothing.",
						"log": "Fought the starving lynxes away from the wild herd's foals in the blizzard pass.",
						"then": "guardian",
						"battle": [
							[
								"ice_lynx",
								27
							],
							[
								"ice_lynx",
								27
							],
							[
								"frost_yak",
								26
							]
						],
						"gain": {
							"outfit": "hunter"
						},
						"after": [
							[
								"Narrator",
								"The lynxes melt back into the snow, and the frost yak goes bellowing off down the pass. Inside the ring the wild foals stand pressed against their mothers, steaming, alive."
							],
							[
								"Tala of the Horse-Folk",
								"You set them free, and now you have fought for them. My grandmother says a free herd needs no guardian. I think everything free needs one, now and then.",
								"nod"
							],
							[
								"Tala of the Horse-Folk",
								"Here. Summer greens and a straw hat. I sewed them for the hunt in the reed country, and then the summer never came. Wear them when the grass comes back. I mean to be there to see it.",
								"offer"
							]
						]
					},
					{
						"id": "lead",
						"label": "Lead the herd through the storm",
						"desc": "Ride out ahead of the wild herd on whatever carries you and lead it through the blizzard by night, with Tala beside you, to the sheltered grass beyond the pass. It needs a ride of your own and a steady nerve; the lynxes go hungry, but nobody bleeds.",
						"log": "Led the wild herd through the blizzard by night, and the dun mare came back to him.",
						"then": "rider",
						"need": [
							[
								"rides",
								1
							]
						],
						"gain": {
							"outfit": "hunter",
							"ride": "pony",
							"renown": 6
						},
						"after": [
							[
								"Narrator",
								"All night they ride into the white. Out of the dark the dun mare comes to walk at Lin Feng's knee, and the wild herd follows her. At dawn the pass opens on a hollow where the wind has swept the grass bare, and the mare does not go back."
							],
							[
								"Tala of the Horse-Folk",
								"She chose you once in the gorge, and again tonight. I cannot give you a horse that belongs to nobody. But I can stop pretending she is not yours.",
								"nod"
							],
							[
								"Tala of the Horse-Folk",
								"And these: summer greens and a straw hat. I sewed them for the hunt in the reed country, and then the summer never came. Wear them when the grass comes back. I mean to see you in them, on her.",
								"offer"
							]
						]
					},
					{
						"id": "leave",
						"label": "Let the steppe take its due",
						"desc": "Do nothing, and let the lynxes take the weakest foals, as the steppe has always done with wild herds. The herd will live, and so will the lynx cubs in their den under the ridge; but foals will die tonight that a sword could have saved, and Tala will watch it.",
						"log": "Let the lynxes take the wild herd's weakest foals, as the steppe always has, and the lynx cubs lived.",
						"then": "steppe",
						"gain": {
							"renown": 2
						},
						"after": [
							[
								"Narrator",
								"Lin Feng puts up his sword. Before dawn the lynxes take two foals from the edge of the ring and carry them up to the den under the ridge, and the crying under the rocks stops."
							],
							[
								"Tala of the Horse-Folk",
								"Nobody's herd, so nobody comes. I said it myself. I did not think you would agree with me.",
								"grieve"
							],
							[
								"Tala of the Horse-Folk",
								"The weak foals feed the lynxes, and the lynxes keep the herd strong. It is the oldest way, and you are right, and I will hate you for it until the spring. If there is a spring."
							]
						]
					}
				]
			}
		}
	},
	"s_f_tala3": {
		"n": "Water for the Herd",
		"by": {
			"guardian": {
				"lines": [
					[
						"Narrator",
						"At the edge of the Scorched Millet Plains, where the dry river runs out into cracked earth, a herd of cloud-horses stands head-down in the white noon. Tala sits on the shrine step beside Old Farmer Tian, her braid pinned up off her neck, watching them."
					],
					[
						"Tala of the Horse-Folk",
						"Sect boy. They call you Sovereign in the market; I will not. The foals you fought the lynxes for in the winter pass are yearlings now. Look at them. You saved them from teeth so that they could die of thirst at the edge of a millet field.",
						"point"
					],
					[
						"Tala of the Horse-Folk",
						"Every autumn we bring horses to the Dawn Market to trade for tea and salt. Then the sun stopped, and the river went into the ground. The town wells belong to the grain merchants; their oxen died in the heat, and they want the whole herd for their caravans."
					],
					[
						"Yue Ling",
						"And they will water the horses the moment they own them, and not a moment before. They are waiting for the price to fall. Every day without water, it falls a little further."
					],
					[
						"Batu",
						"The elders say sell. The children are hungry, and silver is better than bones. Grandmother says there was a horse-folk well on the old drove road once, with a horse's head cut in the stone, but the dust has had it for fifty years."
					],
					[
						"Lin Feng",
						"And what do you say, Tala?"
					],
					[
						"Tala of the Horse-Folk",
						"I say I was born on a horse, and I will not be the one who sells them. And I say the children are hungry. I say both, all night, and neither of them listens.",
						"think"
					]
				],
				"ask": "Water for the herd, or millet for the people?",
				"options": [
					{
						"id": "dig",
						"label": "Dig out the buried well",
						"desc": "Help Tala dig out the horse-folk's old well on the drove road, buried by fifty years of dust, and wake it with four Water Essences. It costs the essences and a day of digging under the noon sun; the horse-folk get a well nobody can sell them.",
						"log": "Dug out the horse-folk's buried well with Tala and woke it with four Water Essences.",
						"then": "well",
						"need": [
							[
								"item",
								"ess_water",
								4
							]
						],
						"pay": {
							"items": {
								"ess_water": 4
							}
						},
						"gain": {
							"renown": 8
						},
						"after": [
							[
								"Narrator",
								"They dig through the endless noon, Tala with a horn spade and Lin Feng with his hands, until a ring of old stones shows in the dust, a horse's head cut in its curb. Lin Feng drops four Water Essences into the dark, and far below something wakes and climbs."
							],
							[
								"Tala of the Horse-Folk",
								"Water. Our water. My grandmother's grandmother drank from this, and nobody can sell it to us, ever. First the lynxes, now the sun: I have stopped counting what we owe you, sect boy. It was getting embarrassing.",
								"laugh"
							],
							[
								"Tala of the Horse-Folk",
								"That one-legged fire-bird has been burning our grazing along the dyke road. When you go after it, look behind you. Nobody rides in circles like the horse-folk."
							]
						]
					},
					{
						"id": "buy",
						"label": "Buy them a well in the market",
						"desc": "Pay the grain merchants 30,000 spirit stones for the water rights of their well by the east gate, made over to the horse-folk for good. The herd drinks tonight; the merchants grow rich on the herd they meant to buy cheap, and Yanggu talks of it for years.",
						"log": "Bought the horse-folk the water of a Yanggu well, for good, from the merchants who wanted their herd.",
						"then": "bought",
						"need": [
							[
								"stones",
								30000
							]
						],
						"pay": {
							"stones": 30000
						},
						"gain": {
							"renown": 6
						},
						"after": [
							[
								"Narrator",
								"The grain merchants count the stones twice and sign the deed with very bad grace. By what should have been evening the herd is drinking at the east gate well, and the merchants who wanted it cheap stand in the street and watch."
							],
							[
								"Tala of the Horse-Folk",
								"A whole well, in the middle of their market, for more stones than my people have seen in a hundred years. My grandmother is going to sit on that wellhead every morning and smile at them.",
								"laugh"
							],
							[
								"Tala of the Horse-Folk",
								"That one-legged fire-bird has been burning our grazing along the dyke road. When you go after it, sect boy, look behind you. Nobody rides in circles like the horse-folk."
							]
						]
					},
					{
						"id": "sell",
						"label": "Let them sell the herd",
						"desc": "Let the horse-folk sell their herd to the grain merchants, as the elders have decided, so that their children eat through the drought. It costs nothing but the herd: the horses will live, pulling carts on the market roads, and Tala will not be the same.",
						"log": "Let the horse-folk sell their herd to Yanggu's caravans, and took the share Tala pressed on him.",
						"then": "sold",
						"gain": {
							"stones": 8000
						},
						"after": [
							[
								"Narrator",
								"The merchants lead the herd away to the caravan lines in strings of six, and at their troughs the horses drink at last. The horse-folk carry sacks of millet back to their tents, and that night the children eat until they fall asleep."
							],
							[
								"Tala of the Horse-Folk",
								"Your share. Take it. Those yearlings are alive because of you, so you own a piece of every one of them, and I will not carry all this silver by myself.",
								"offer"
							],
							[
								"Yue Ling",
								"She is not giving you money, Lin Feng. She is giving you half of something heavy."
							]
						]
					}
				]
			},
			"rider": {
				"lines": [
					[
						"Narrator",
						"At the edge of the Scorched Millet Plains, where the dry river runs out into cracked earth, a herd of cloud-horses stands head-down in the white noon. Tala sits on the shrine step beside Old Farmer Tian, her braid pinned up off her neck, watching them."
					],
					[
						"Tala of the Horse-Folk",
						"Sect boy, and the dun mare, still putting up with you. They call you Sovereign in the market; I will not. In the winter you led us through a blizzard. I wish there were a storm to lead us through now. There is only the sun, and it does not move.",
						"wave"
					],
					[
						"Tala of the Horse-Folk",
						"Every autumn we bring horses to the Dawn Market to trade for tea and salt. Then the sun stopped, and the river went into the ground. The town wells belong to the grain merchants; their oxen died in the heat, and they want the whole herd for their caravans."
					],
					[
						"Yue Ling",
						"And they will water the horses the moment they own them, and not a moment before. They are waiting for the price to fall. Every day without water, it falls a little further."
					],
					[
						"Batu",
						"The elders say sell. The children are hungry, and silver is better than bones. Grandmother says there was a horse-folk well on the old drove road once, with a horse's head cut in the stone, but the dust has had it for fifty years."
					],
					[
						"Lin Feng",
						"And what do you say, Tala?"
					],
					[
						"Tala of the Horse-Folk",
						"I say I was born on a horse, and I will not be the one who sells them. And I say the children are hungry. I say both, all night, and neither of them listens.",
						"think"
					]
				],
				"ask": "Water for the herd, or millet for the people?",
				"options": [
					{
						"id": "dig",
						"label": "Dig out the buried well",
						"desc": "Help Tala dig out the horse-folk's old well on the drove road, buried by fifty years of dust, and wake it with four Water Essences. It costs the essences and a day of digging under the noon sun; the horse-folk get a well nobody can sell them.",
						"log": "Dug out the horse-folk's buried well with Tala and woke it with four Water Essences.",
						"then": "well",
						"need": [
							[
								"item",
								"ess_water",
								4
							]
						],
						"pay": {
							"items": {
								"ess_water": 4
							}
						},
						"gain": {
							"renown": 8
						},
						"after": [
							[
								"Narrator",
								"They dig through the endless noon, Tala with a horn spade and Lin Feng with his hands, until a ring of old stones shows in the dust, a horse's head cut in its curb. Lin Feng drops four Water Essences into the dark, and far below something wakes and climbs."
							],
							[
								"Tala of the Horse-Folk",
								"Water. Our water. My grandmother's grandmother drank from this, and nobody can sell it to us, ever. In the winter you went first through the snow, and today you went first into the dust. Do you even know how to go second, sect boy?",
								"laugh"
							],
							[
								"Tala of the Horse-Folk",
								"That one-legged fire-bird has been burning our grazing along the dyke road. When you go after it, look behind you. Nobody rides in circles like the horse-folk."
							]
						]
					},
					{
						"id": "buy",
						"label": "Buy them a well in the market",
						"desc": "Pay the grain merchants 30,000 spirit stones for the water rights of their well by the east gate, made over to the horse-folk for good. The herd drinks tonight; the merchants grow rich on the herd they meant to buy cheap, and Yanggu talks of it for years.",
						"log": "Bought the horse-folk the water of a Yanggu well, for good, from the merchants who wanted their herd.",
						"then": "bought",
						"need": [
							[
								"stones",
								30000
							]
						],
						"pay": {
							"stones": 30000
						},
						"gain": {
							"renown": 6
						},
						"after": [
							[
								"Narrator",
								"The grain merchants count the stones twice and sign the deed with very bad grace. By what should have been evening the herd is drinking at the east gate well, the dun mare first because she insists, and the merchants stand in the street and watch."
							],
							[
								"Tala of the Horse-Folk",
								"A whole well, in the middle of their market, for more stones than my people have seen in a hundred years. My grandmother is going to sit on that wellhead every morning and smile at them.",
								"laugh"
							],
							[
								"Tala of the Horse-Folk",
								"That one-legged fire-bird has been burning our grazing along the dyke road. When you go after it, sect boy, look behind you. Nobody rides in circles like the horse-folk."
							]
						]
					},
					{
						"id": "sell",
						"label": "Let them sell the herd",
						"desc": "Let the horse-folk sell their herd to the grain merchants, as the elders have decided, so that their children eat through the drought. It costs nothing but the herd: the horses will live, pulling carts on the market roads, and Tala will not be the same.",
						"log": "Let the horse-folk sell their herd to Yanggu's caravans, and took the share Tala pressed on him.",
						"then": "sold",
						"gain": {
							"stones": 8000
						},
						"after": [
							[
								"Narrator",
								"The merchants lead the herd away to the caravan lines in strings of six, and at their troughs the horses drink at last. The horse-folk carry sacks of millet back to their tents, and that night the children eat until they fall asleep."
							],
							[
								"Tala of the Horse-Folk",
								"Your share. Take it. You led them through the snow, so you own a piece of every one of them, and I will not carry all this silver by myself.",
								"offer"
							],
							[
								"Tala of the Horse-Folk",
								"And keep the dun mare away from the caravan lines. If she sees where they have gone, she will try to bring them back. So would I.",
								"grieve"
							]
						]
					}
				]
			},
			"steppe": {
				"lines": [
					[
						"Narrator",
						"At the edge of the Scorched Millet Plains, where the dry river runs out into cracked earth, a herd of cloud-horses stands head-down in the white noon. Tala sits on the shrine step beside Old Farmer Tian, and she does not get up when she sees Lin Feng."
					],
					[
						"Tala of the Horse-Folk",
						"Sect boy. In the winter you let the steppe take its due, and the lynxes took the weak ones, and the ones that are left are strong. Look at them. Strong does not matter now. Nothing lives without water.",
						"point"
					],
					[
						"Tala of the Horse-Folk",
						"Every autumn we bring horses to the Dawn Market to trade for tea and salt. Then the sun stopped, and the river went into the ground. The town wells belong to the grain merchants; their oxen died in the heat, and they want the whole herd for their caravans."
					],
					[
						"Yue Ling",
						"And they will water the horses the moment they own them, and not a moment before. They are waiting for the price to fall. Every day without water, it falls a little further."
					],
					[
						"Batu",
						"The elders say sell. The children are hungry, and silver is better than bones. Grandmother says there was a horse-folk well on the old drove road once, with a horse's head cut in the stone, but the dust has had it for fifty years."
					],
					[
						"Lin Feng",
						"And what do you say, Tala?"
					],
					[
						"Tala of the Horse-Folk",
						"I say I was born on a horse, and I will not be the one who sells them. And I say the children are hungry. I say both, all night, and neither of them listens.",
						"think"
					]
				],
				"ask": "Water for the herd, or millet for the people?",
				"options": [
					{
						"id": "dig",
						"label": "Dig out the buried well",
						"desc": "Help Tala dig out the horse-folk's old well on the drove road, buried by fifty years of dust, and wake it with four Water Essences. It costs the essences and a day of digging under the noon sun; the horse-folk get a well nobody can sell them.",
						"log": "Dug out the horse-folk's buried well with Tala and woke it with four Water Essences.",
						"then": "well",
						"need": [
							[
								"item",
								"ess_water",
								4
							]
						],
						"pay": {
							"items": {
								"ess_water": 4
							}
						},
						"gain": {
							"renown": 8
						},
						"after": [
							[
								"Narrator",
								"They dig through the endless noon, Tala with a horn spade and Lin Feng with his hands, until a ring of old stones shows in the dust, a horse's head cut in its curb. Lin Feng drops four Water Essences into the dark, and far below something wakes and climbs."
							],
							[
								"Tala of the Horse-Folk",
								"Water. Our water. My grandmother's grandmother drank from this, and nobody can sell it to us, ever. In the winter you would not lift a hand for the weak ones. Today you dug with both. I do not understand you, sect boy, but I am glad.",
								"think"
							],
							[
								"Tala of the Horse-Folk",
								"That one-legged fire-bird has been burning our grazing along the dyke road. When you go after it, look behind you. Nobody rides in circles like the horse-folk."
							]
						]
					},
					{
						"id": "buy",
						"label": "Buy them a well in the market",
						"desc": "Pay the grain merchants 30,000 spirit stones for the water rights of their well by the east gate, made over to the horse-folk for good. The herd drinks tonight; the merchants grow rich on the herd they meant to buy cheap, and Yanggu talks of it for years.",
						"log": "Bought the horse-folk the water of a Yanggu well, for good, from the merchants who wanted their herd.",
						"then": "bought",
						"need": [
							[
								"stones",
								30000
							]
						],
						"pay": {
							"stones": 30000
						},
						"gain": {
							"renown": 6
						},
						"after": [
							[
								"Narrator",
								"The grain merchants count the stones twice and sign the deed with very bad grace. By what should have been evening the herd is drinking at the east gate well, and the merchants who wanted it cheap stand in the street and watch."
							],
							[
								"Tala of the Horse-Folk",
								"You would not draw your sword for two foals in the snow, and now you pay a fortune for the whole herd. My grandmother says a cultivator's mind is like mountain weather. I am starting to believe her.",
								"think"
							],
							[
								"Tala of the Horse-Folk",
								"That one-legged fire-bird has been burning our grazing along the dyke road. When you go after it, sect boy, look behind you. Nobody rides in circles like the horse-folk."
							]
						]
					},
					{
						"id": "sell",
						"label": "Let them sell the herd",
						"desc": "Let the horse-folk sell their herd to the grain merchants, as the elders have decided, so that their children eat through the drought. It costs nothing but the herd: the horses will live, pulling carts on the market roads, and Tala will not be the same.",
						"log": "Let the horse-folk sell their herd to Yanggu's caravans, and took the share Tala pressed on him.",
						"then": "sold",
						"gain": {
							"stones": 8000
						},
						"after": [
							[
								"Narrator",
								"The merchants lead the herd away to the caravan lines in strings of six, and at their troughs the horses drink at last. The horse-folk carry sacks of millet back to their tents, and that night the children eat until they fall asleep."
							],
							[
								"Tala of the Horse-Folk",
								"In the winter you let the steppe take its due. Well, it has taken it. Here is your share of the price, sect boy. Take it. I will not carry all this silver by myself.",
								"offer"
							],
							[
								"Yue Ling",
								"She is not giving you money, Lin Feng. She is giving you half of something heavy."
							]
						]
					}
				]
			}
		}
	},
	"s_f_tala4": {
		"n": "The Herd Comes Home",
		"by": {
			"well": {
				"lines": [
					[
						"Narrator",
						"The street outside the Post Stables at Cloudfoot is full of horses: grey, dun and white cloud-horses steaming in the mountain air, and forty horse-folk riders in fur-trimmed coats with horn bows across their backs. Shitou the stable-boy has given up counting."
					],
					[
						"Tala of the Horse-Folk",
						"Word came up the steppe road that you were riding to the Wheel against something made of old debts. So here we are: the whole herd, and every rider who can sit a horse. The well on the drove road has not run dry once since you woke it."
					],
					[
						"Batu",
						"I have my own bow now. Tala says I can come if I stay at the back. I am not going to stay at the back."
					],
					[
						"Yue Ling",
						"Tala, do you know what waits at the Wheel? It is made of everything anyone was ever owed and never paid. It will know every one of you by name."
					],
					[
						"Tala of the Horse-Folk",
						"Then let it look for our names. It will find them paid in full. My grandmother says a debt is a horse you have not yet ridden home. The horse-folk pay what they owe, and we pay it at a gallop.",
						"laugh"
					],
					[
						"Tala of the Horse-Folk",
						"Well, Lin Feng? There. I have said your name at last, so you know I mean it. Will you have us?"
					]
				],
				"ask": "Will the horse-folk ride with you to the Wheel?",
				"options": [
					{
						"id": "ride",
						"label": "Ride to the Wheel together",
						"desc": "Take Tala, her forty riders and the whole herd with you to the Wheel of the Six Paths, to ride against Nie the Unpaid. They come of their own free will; some of them may not ride home again, and Tala knows it.",
						"log": "Rode for the Wheel with Tala, her forty riders and the herd that drinks at the buried well.",
						"then": "ally",
						"after": [
							[
								"Lin Feng",
								"Then ride with me, all of you. But at the Wheel the herd keeps to the open ground, Tala, and whatever happens, the horses go home."
							],
							[
								"Tala of the Horse-Folk",
								"That was always the plan, sect boy. ...Lin Feng. I will get used to it.",
								"nod"
							],
							[
								"Narrator",
								"Tala whistles once. Forty riders swing into the saddle together, the herd wheels in the street like a flock of starlings, and Shitou the stable-boy cheers until he falls off the fence."
							]
						]
					}
				]
			},
			"bought": {
				"lines": [
					[
						"Narrator",
						"The street outside the Post Stables at Cloudfoot is full of horses: grey, dun and white cloud-horses steaming in the mountain air, and forty horse-folk riders in fur-trimmed coats with horn bows across their backs. Shitou the stable-boy has given up counting."
					],
					[
						"Tala of the Horse-Folk",
						"Word came up the steppe road that you were riding to the Wheel against something made of old debts. So here we are: the whole herd, and every rider who can sit a horse."
					],
					[
						"Tala of the Horse-Folk",
						"Every morning since you bought us that well, my grandmother has sat on the wellhead at the east gate and smiled at the grain merchants. It is the happiest I have ever seen her.",
						"laugh"
					],
					[
						"Batu",
						"I have my own bow now. Tala says I can come if I stay at the back. I am not going to stay at the back."
					],
					[
						"Yue Ling",
						"Tala, do you know what waits at the Wheel? It is made of everything anyone was ever owed and never paid. It will know every one of you by name."
					],
					[
						"Tala of the Horse-Folk",
						"Then let it look. It will find a well in Yanggu paid for in full, and a people come to pay you back. My grandmother says a debt is a horse you have not yet ridden home. The horse-folk pay what they owe, at a gallop."
					],
					[
						"Tala of the Horse-Folk",
						"Well, Lin Feng? There. I have said your name at last, so you know I mean it. Will you have us?"
					]
				],
				"ask": "Will the horse-folk ride with you to the Wheel?",
				"options": [
					{
						"id": "ride",
						"label": "Ride to the Wheel together",
						"desc": "Take Tala, her forty riders and the whole herd with you to the Wheel of the Six Paths, to ride against Nie the Unpaid. They come of their own free will; some of them may not ride home again, and Tala knows it.",
						"log": "Rode for the Wheel with Tala, her forty riders and the herd that drinks at the market well.",
						"then": "ally",
						"after": [
							[
								"Lin Feng",
								"Then ride with me, all of you. But at the Wheel the herd keeps to the open ground, Tala. Whatever happens, the horses go home to that well."
							],
							[
								"Tala of the Horse-Folk",
								"That was always the plan, sect boy. ...Lin Feng. I will get used to it.",
								"nod"
							],
							[
								"Narrator",
								"Tala whistles once. Forty riders swing into the saddle together, the herd wheels in the street like a flock of starlings, and Shitou the stable-boy cheers until he falls off the fence."
							]
						]
					}
				]
			},
			"sold": {
				"lines": [
					[
						"Narrator",
						"Tala waits by the Post Stables alone, in a coat too fine for the steppe, with silver on her bridle and no herd behind her. She is watching the post-horses go up the mountain road as if she were counting them."
					],
					[
						"Tala of the Horse-Folk",
						"We ate well this year, sect boy. Every child in the camp is fat. My grandmother has new boots. I have more silver than my father ever saw. And I cannot sleep."
					],
					[
						"Tala of the Horse-Folk",
						"Some of the herd still pull the grain merchants' carts on the Dawn Market road. I go and look at them. The grey colt Batu nearly died for is grown now, in the third team. He does not know me any more. Or he does, and he is being polite.",
						"grieve"
					],
					[
						"Yue Ling",
						"Something has been whispering to you, has it not? At night, about what you owe."
					],
					[
						"Tala of the Horse-Folk",
						"A voice like a merchant counting. It says I sold my family to feed my family, and that the sum will never come out. You call it Nie? It is right, is it not? It does not come out."
					],
					[
						"Lin Feng",
						"And your riders?"
					],
					[
						"Tala of the Horse-Folk",
						"At home on the steppe, with their silver. A rider without a horse is only somebody standing in a field. I came by myself. I do not even know what I came to ask you."
					]
				],
				"ask": "Buy back her herd, or lift the debt off her?",
				"options": [
					{
						"id": "buyback",
						"label": "Buy back what is left of it",
						"desc": "Pay the Yanggu grain merchants 40,000 spirit stones for every horse of Tala's herd still in their harness, and send them home to the steppe. Her riders will follow her to the Wheel; the merchants will grumble, and buy oxen.",
						"log": "Bought back what was left of Tala's herd from the caravans, and her riders came to the Wheel.",
						"then": "ally",
						"need": [
							[
								"stones",
								40000
							]
						],
						"pay": {
							"stones": 40000
						},
						"after": [
							[
								"Narrator",
								"It takes four days and more stones than the merchants have ever counted at one sitting. On the fifth morning twenty-nine cloud-horses come into Cloudfoot with harness-galls on their shoulders, and behind them the horse-folk riders, whooping."
							],
							[
								"Tala of the Horse-Folk",
								"The grey knew me. He put his head on my shoulder and would not take it off. ...Now I owe you, Lin Feng, and that is a debt I know how to carry. The horse-folk pay at a gallop.",
								"nod"
							],
							[
								"Yue Ling",
								"Listen. The whispering has stopped, has it not?"
							],
							[
								"Tala of the Horse-Folk",
								"It has. Let it come and say it to my face at the Wheel."
							]
						]
					},
					{
						"id": "absolve",
						"label": "Tell her she chose rightly",
						"desc": "Tell Tala that she chose her people over the horses, that it was right, and that the sum was never hers to make come out. It costs nothing; but she will not ride to the Wheel. She will go home to the steppe.",
						"log": "Told Tala she was right to choose her people over the herd, and she went home to the steppe.",
						"then": "parted",
						"after": [
							[
								"Lin Feng",
								"You chose the children over the horses, Tala. That was not a debt. It was the right choice, and it was yours to make. Let the voice count. You do not have to."
							],
							[
								"Tala of the Horse-Folk",
								"...Right. Everybody else says necessary. Nobody has said right. ...I am not coming to the Wheel, Lin Feng. I think I need to go home and learn how to sleep again.",
								"grieve"
							],
							[
								"Tala of the Horse-Folk",
								"I will wait here at the stables until you come back from it. Then I am riding north. Win, sect boy. Then come to the steppe, and I will show it to you with nothing trying to eat it.",
								"wave"
							]
						]
					}
				]
			}
		}
	},
	"s_f_qiu1": {
		"n": "The Second Son",
		"by": {
			"*": {
				"lines": [
					[
						"Narrator",
						"Past midnight the courtyard is white with frost. In the pharmacy Alchemist Mo sleeps sitting up among the marsh-poisoned, and somebody is easing his storeroom door shut: a young man in dark green and silver, a red lacquer pill box in his hand."
					],
					[
						"Qiu Ye",
						"Of course. Of everyone on this mountain, the sweeper. Should you not be asleep in your new white robe? Foundation in a season. The whole outer court talks of nothing else.",
						"shake"
					],
					[
						"Lin Feng",
						"Qiu Ye. That is one of Mo's Foundation Pills."
					],
					[
						"Qiu Ye",
						"Here. Read it, since you mean to judge me anyway. My father's hand: reach Foundation by the new year, or do not trouble to come home. He underlined the last part. Twice.",
						"offer"
					],
					[
						"Yue Ling",
						"A Foundation Pill forces open a body that is not ready. It can tear the meridians. Qiu Ye, is any letter worth that?"
					],
					[
						"Qiu Ye",
						"I was ready. For two years I was the best of the outer disciples. Then a boy with a broom walked past me in one season, and tonight they gave him the white robe. So tell me, sweeper. What is a second son for?"
					]
				],
				"ask": "Qiu Ye holds a stolen pill. What will you do?",
				"options": [
					{
						"id": "report",
						"label": "Take him to the Elder",
						"desc": "Wake Elder Qing Xuan and set the boy and the pill in front of him. Theft from the pharmacy means expulsion: Qiu Ye will be sent down the mountain at dawn, and the Elder will write to his father to say why.",
						"log": "Took Qiu Ye to the Elder with the stolen pill, and he was sent down the mountain at dawn.",
						"then": "expelled",
						"after": [
							[
								"Elder Qing Xuan",
								"A Foundation Pill, from Mo's own shelves, while Mo sat up with the poisoned. Qiu Ye, there is no place for you on this mountain after tonight. You will go at first light."
							],
							[
								"Qiu Ye",
								"Yes, Elder. Write to my father yourself. He will want it in a hand he respects.",
								"bow"
							],
							[
								"Narrator",
								"He goes at dawn, down the steps Lin Feng swept for three years, his grandfather's jian on his back. He does not look back once. It looks as if not looking back costs him a great deal."
							]
						]
					},
					{
						"id": "secret",
						"label": "Keep his secret",
						"desc": "Let him go back to bed with the pill, and say nothing to Mo or to the Elder. He keeps his place and his chance; Mo will count his shelves in the morning, come up one pill short, and blame his own tired hands.",
						"log": "Kept Qiu Ye's secret, and the stolen pill went back to the dormitory in his sleeve.",
						"then": "secret",
						"after": [
							[
								"Qiu Ye",
								"Do not wait for thanks. You did not do this for me. You did it so that you could feel kind."
							],
							[
								"Lin Feng",
								"Perhaps. Go to bed, Qiu Ye. And do not swallow it before you are ready."
							],
							[
								"Narrator",
								"In the morning Alchemist Mo counts his shelves twice, scratches his head and blames the marsh fumes. Qiu Ye does not meet Lin Feng's eye for a month."
							]
						]
					},
					{
						"id": "share",
						"label": "Pay Mo for the pill",
						"desc": "Wake Alchemist Mo and pay for the pill out of the two hundred spirit stones the Elder gave you tonight. The pill becomes Qiu Ye's, bought and not stolen; your purse is two hundred lighter, and the proudest boy in the sect owes the sweeper.",
						"log": "Paid Alchemist Mo for the stolen pill; Qiu Ye refused it, then took it, and swore to repay every stone.",
						"then": "shared",
						"need": [
							[
								"stones",
								200
							]
						],
						"pay": {
							"stones": 200
						},
						"after": [
							[
								"Narrator",
								"Mo, woken, counts the two hundred stones twice, looks from one boy to the other, and decides he would rather not know."
							],
							[
								"Qiu Ye",
								"I do not want it. Not from you. Take it back.",
								"shake"
							],
							[
								"Lin Feng",
								"Then pay me back. Every stone, as slowly as you like."
							],
							[
								"Qiu Ye",
								"Every stone. On my grandfather's sword. Do not tell anyone, and do not look at me like that. ...Thank you.",
								"bow"
							]
						]
					}
				]
			}
		}
	},
	"s_f_qiu2": {
		"n": "A Saint's Sword",
		"by": {
			"expelled": {
				"lines": [
					[
						"Narrator",
						"Between the barrows somebody is pulling swords out of the saints' graves and tying them in a bundle like firewood. A lacquered half-mask hangs at his belt, the mark of the Ashen Moon. The high ponytail under the silver crown is Qiu Ye's."
					],
					[
						"Qiu Ye",
						"The sweeper, putting the dead to bed. You handed me to the Elder, then killed Xu Mo and an Emperor besides. Xu Mo's last disciples sleep in ditches now, and call themselves the Ashen Moon. I sleep in the ditch beside them."
					],
					[
						"Qiu Ye",
						"The Elder wrote to my father. My father wrote back to the Elder, not to me. The Ashen Moon never asks what your father thinks of you. It only asks what you will pay."
					],
					[
						"Yue Ling",
						"Those are the saints' own swords. They swore to guard the Seal, and the Seal swore to guard them. You are robbing the people who kept your sect alive."
					],
					[
						"Qiu Ye",
						"My sect. The one that sent me down its steps at dawn with the whole outer court watching. The Ashen Moon pays by the weight of qi in a blade, and saints are very heavy."
					],
					[
						"Lin Feng",
						"Put them back, Qiu Ye. These graves have been robbed once already, by the Emperor's men."
					]
				],
				"ask": "Qiu Ye is robbing the saints' graves. What now?",
				"options": [
					{
						"id": "fight",
						"label": "Take the swords back",
						"desc": "Draw and take the saints' swords back by force. He will fight you for them, lose, and flee into the barrows; the saints keep their blades, and Qiu Ye keeps one more reason to hate you.",
						"log": "Fought Qiu Ye for the saints' swords and won them back; he fled, hating Lin Feng more than ever.",
						"then": "beaten",
						"battle": [
							[
								"qiu_ye",
								19
							]
						],
						"after": [
							[
								"Narrator",
								"Qiu Ye goes down in the grave-dust, and is up again faster than he should be. The Ashen Moon's arts are quick. They do not say what they cost."
							],
							[
								"Qiu Ye",
								"First the Elder's hall, now the grave-dirt. I am keeping count, sweeper. Keep count with me."
							],
							[
								"Narrator",
								"He is gone between the barrows before Yue Ling can reach him. Lin Feng lays the swords back on their graves one by one, and the humming in the ground grows quieter."
							]
						]
					},
					{
						"id": "hand",
						"label": "Offer him your hand",
						"desc": "Keep your sword sheathed and hold out your hand, as to an old fellow disciple. He will not take it; but he may leave the swords, and the Ashen Moon will want to know why he came back empty-handed.",
						"log": "Offered Qiu Ye his hand among the barrows; he refused it, but left the saints' swords behind.",
						"then": "doubt",
						"after": [
							[
								"Qiu Ye",
								"Your hand. In front of the dead. You have had everything else of mine, sweeper. Now you want my grudge as well?",
								"shake"
							],
							[
								"Narrator",
								"He does not take it. But he looks at it for a long moment, like a word he once knew, and when he goes he leaves the bundle of swords lying on the saints' graves."
							],
							[
								"Yue Ling",
								"He hesitated, Lin Feng. Did you see? He hesitated."
							]
						]
					}
				]
			},
			"secret": {
				"lines": [
					[
						"Narrator",
						"At an opened barrow Qiu Ye kneels with an inner disciple's jade token at his belt and a black sword across his knees. The chains it was buried in lie broken in the dirt. The sword is humming, and he is listening to it."
					],
					[
						"Qiu Ye",
						"I swallowed the pill on the last night of the old year. The bell rang for my Foundation at dawn. My father wrote one word: good. I carried that word in my sleeve until the paper fell apart."
					],
					[
						"Qiu Ye",
						"And every day since, I have known it was not mine. Your silence bought me a jade token, sweeper. So I came here for something that would make me worth it."
					],
					[
						"Yue Ling",
						"That sword was buried in chains for a reason. Its qi is wrong, Qiu Ye. It is not giving you strength. It is drinking yours."
					],
					[
						"Qiu Ye",
						"It talks to me. It says I am owed. Do you know, nobody has ever told me that before?"
					],
					[
						"Lin Feng",
						"Owed what?"
					],
					[
						"Qiu Ye",
						"Everything you have, sweeper. It is a very generous sword."
					]
				],
				"ask": "The sword says Qiu Ye is owed. What will you do?",
				"options": [
					{
						"id": "break",
						"label": "Break the sword",
						"desc": "Take the black sword from him and break it across the barrow stone. The dead who were buried as its guard will rise to defend it, and Qiu Ye will have to hear what is left of him without its voice.",
						"log": "Broke the whispering sword across its barrow, laid its guardians to rest, and freed Qiu Ye of it.",
						"then": "freed",
						"battle": [
							[
								"bone_knight",
								19
							],
							[
								"ghost_lantern",
								19
							],
							[
								"bone_knight",
								18
							]
						],
						"after": [
							[
								"Narrator",
								"The halves of the black sword go dull and cold, and the bone knights fold back into their barrow like tired men going to bed. Qiu Ye is still on his knees."
							],
							[
								"Qiu Ye",
								"It is so quiet. Is it this quiet for everyone? How do you stand it?"
							],
							[
								"Yue Ling",
								"You get used to your own voice. It takes a while. It is kinder than that one was."
							],
							[
								"Qiu Ye",
								"Mine is not kind. Mine keeps saying thief. ...It is right, too.",
								"grieve"
							]
						]
					},
					{
						"id": "keep",
						"label": "Let him keep it",
						"desc": "Let him keep the sword. It is his choice and his grave-robbery, and the sect will hear nothing of it from you; but the whisper goes wherever he goes, and from now on it will choose his roads.",
						"log": "Let Qiu Ye keep the whispering sword, and watched him walk off between the barrows, listening.",
						"then": "possessed",
						"after": [
							[
								"Qiu Ye",
								"You see? You understand. A man keeps what he finds. You found a whole root of the Nine Heavens, sweeper, and nobody ever made you give it back."
							],
							[
								"Narrator",
								"He walks off between the barrows with the black sword on his shoulder and his head a little on one side, the way a man walks when someone is talking in his ear."
							],
							[
								"Yue Ling",
								"Lin Feng. It was not his own voice telling him where to go."
							]
						]
					}
				]
			},
			"shared": {
				"lines": [
					[
						"Narrator",
						"Among the barrows Qiu Ye is practising alone, his grandfather's jian bright in the grave-light, and the saints' swords hum in the ground around him as if they were keeping time."
					],
					[
						"Qiu Ye",
						"Lin Feng. Two hundred stones, every one, and a little over for the inconvenience. I paid you back by midwinter. A Qiu does not forget a debt."
					],
					[
						"Qiu Ye",
						"Your pill is still in my sleeve. I never swallowed it. Every night I wanted to, I trained instead. Foundation came on the ninth day of the new year. Nine days late. But it was mine."
					],
					[
						"Yue Ling",
						"Nine days. Did your father let you come home?"
					],
					[
						"Qiu Ye",
						"My father keeps his word. It is the one thing the house of Qiu still has to keep."
					],
					[
						"Qiu Ye",
						"So. No elders, no rankings, no pity. A true duel, to first blood, among the saints. I want to know exactly how far behind you I am."
					]
				],
				"ask": "Qiu Ye asks for a true duel. How will you fight?",
				"options": [
					{
						"id": "duel",
						"label": "Duel him honestly",
						"desc": "Give him the duel he asked for, honestly, to first blood and no further. He will most likely lose, and he will know exactly by how much; you will both walk away with a cut and no grudge.",
						"log": "Duelled Qiu Ye honestly among the saints' swords, to first blood, and they parted friends.",
						"then": "friend",
						"battle": [
							[
								"qiu_ye",
								19
							]
						],
						"after": [
							[
								"Narrator",
								"Qiu Ye looks at the thin red line on his sleeve for a long time. Then he laughs, short and surprised, like a man hearing a joke in a language he has only just learned."
							],
							[
								"Qiu Ye",
								"Further than I hoped. Not as far as I feared. I can work with that.",
								"laugh"
							],
							[
								"Lin Feng",
								"Same time next year?",
								"laugh"
							],
							[
								"Qiu Ye",
								"Next year I will be closer. Bring a better sword."
							]
						],
						"gain": {
							"stones": 200
						}
					},
					{
						"id": "yield",
						"label": "Let him win",
						"desc": "Drop your guard at the last moment and let his blade find you first. He will believe the win is his and walk taller for it; but he will be building on a victory he did not earn, and he will tell people.",
						"log": "Let Qiu Ye win their duel among the barrows on purpose, and Qiu Ye believed the win was his.",
						"then": "flattered",
						"after": [
							[
								"Narrator",
								"Qiu Ye's jian draws a thin red line across Lin Feng's forearm. He stares at it, then at his own blade. Then he laughs aloud, and the saints' swords hum along with him."
							],
							[
								"Qiu Ye",
								"I did it. I beat the sweeper who killed the Jade Emperor. Wait until my father hears. Wait until everyone hears.",
								"laugh"
							],
							[
								"Yue Ling",
								"That was kind, Lin Feng. I hope it was kind."
							]
						],
						"gain": {
							"stones": 200
						}
					}
				]
			}
		}
	},
	"s_f_qiu3": {
		"n": "The Queue at the Bridge",
		"by": {
			"beaten": {
				"lines": [
					[
						"Narrator",
						"Halfway down the queue of the dead, Qiu Ye has drawn a circle of ash among the red lilies. A grey old man in a lord's faded robes stands inside it, and Qiu Ye is winding a red thread from a spirit tablet round the old man's wrist."
					],
					[
						"Qiu Ye",
						"Stay back, sweeper. You beat me once among the barrows. You will not do it here. This is my father and my house, and you have no part in either."
					],
					[
						"Qiu Ye",
						"He died alone in the house at Cloudfoot with the gate barred, and the Wheel will not take him. Good. The Ashen Moon has an art for that: my blood, a tablet with our name on it, and he serves the house forever. The house of Qiu never dies."
					],
					[
						"Lord Qiu's Shade",
						"Expelled. Masked. And now my own son would keep me like a dog at the gate. Do as you like. You always have."
					],
					[
						"Yue Ling",
						"Lin Feng, a bound shade never reaches the Wheel, not when it turns again, not ever. He will stand in that tablet until the wood rots, and then in the rot."
					],
					[
						"Lin Feng",
						"Somewhere in this queue there may be two people I have never met. I would give anything for one word from them. Qiu Ye, yours is standing right in front of you.",
						"point"
					]
				],
				"ask": "Qiu Ye means to bind his father's shade. What now?",
				"options": [
					{
						"id": "stop",
						"label": "Cut the binding",
						"desc": "Step into the ash circle and cut the red thread before it is tied. His father goes back to wait in the queue like everyone else; Qiu Ye will fight you for him, lose, and never forgive you for it.",
						"log": "Cut the binding at the bridge and beat Qiu Ye; he escaped, swearing to destroy all Lin Feng loves.",
						"then": "foe",
						"battle": [
							[
								"qiu_ye",
								32
							]
						],
						"after": [
							[
								"Narrator",
								"The red thread parts. The old shade steps out of the ash circle without a glance at his son and takes his place in the queue again, as if he had only stood aside to let a cart go by."
							],
							[
								"Qiu Ye",
								"You took him. The last thing my house had, and you took it. Hear me, sweeper: everything you love. The sect, the steps, the girl at your side. Everything."
							],
							[
								"Narrator",
								"He is gone into the lilies before Lin Feng can answer, and the red flowers close behind him like a mouth."
							],
							[
								"Yue Ling",
								"He will come back. People who swear like that always come back."
							]
						]
					},
					{
						"id": "farewell",
						"label": "Help him say goodbye",
						"desc": "Sheathe your sword and offer to help him do it properly instead: incense, bows, the walk to the bridge. His father goes on unbound, and the house of Qiu will live or die by its last son; it will cost Qiu Ye the last of his pride.",
						"log": "Helped Qiu Ye say goodbye to his father properly at the bridge, and the second son broke.",
						"then": "turning",
						"after": [
							[
								"Narrator",
								"Qiu Ye stares at Lin Feng for a long time. Then he lets the thread fall. It takes until the golden light dims: incense from Yue Ling's satchel, three bows, the tablet burned, and the long walk to the foot of the Naihe Bridge."
							],
							[
								"Lord Qiu's Shade",
								"I forgive you nothing. Not the theft, not the mask, not the thread. But you held your grandfather's sword better than he ever did. I saw it once, when you were nine, and I never said so."
							],
							[
								"Narrator",
								"Qiu Ye stands very straight for as long as he can. Then he folds over his grandfather's sword and weeps like a much younger boy, and the old man waits beside him until he has finished."
							],
							[
								"Qiu Ye",
								"When you go down to the King, sweeper, I am coming with you. I know every court of this place from the queue, and there is nothing left down here that I am afraid of."
							]
						]
					}
				]
			},
			"possessed": {
				"lines": [
					[
						"Narrator",
						"Halfway down the queue of the dead, Qiu Ye has drawn a circle of ash among the red lilies, and a grey old man in a lord's faded robes stands in it. The black sword from the barrow hums in Qiu Ye's hand. A red thread runs from its hilt to the old man's wrist."
					],
					[
						"Qiu Ye",
						"You let me keep it, sweeper. Remember that. It led me out of the sect in spring and into the Ashen Moon by summer, and it has taught me more than any elder ever did."
					],
					[
						"Qiu Ye",
						"My father died alone in the house at Cloudfoot with the gate barred, and the Wheel will not take him. Good. The sword knows an Ashen Moon art: my blood, a tablet with our name on it, and he serves the house forever. The house of Qiu never dies."
					],
					[
						"Lord Qiu's Shade",
						"An inner disciple of the Azure Cloud, and you threw it away for a voice in a sword. Now you would keep me like a dog at the gate. Do as you like. You always have."
					],
					[
						"Yue Ling",
						"Lin Feng, a bound shade never reaches the Wheel, not when it turns again, not ever. And it is the sword doing the binding, not him. Listen to it."
					],
					[
						"Lin Feng",
						"Somewhere in this queue there may be two people I have never met. I would give anything for one word from them. Qiu Ye, yours is standing right in front of you.",
						"point"
					]
				],
				"ask": "Qiu Ye means to bind his father's shade. What now?",
				"options": [
					{
						"id": "stop",
						"label": "Cut the binding",
						"desc": "Step into the ash circle and cut the red thread before it is tied. His father goes back to wait in the queue like everyone else; Qiu Ye will fight you for him, lose, and never forgive you for it.",
						"log": "Cut the binding at the bridge and beat Qiu Ye; he escaped, swearing to destroy all Lin Feng loves.",
						"then": "foe",
						"battle": [
							[
								"qiu_ye",
								32
							]
						],
						"after": [
							[
								"Narrator",
								"The red thread parts. The old shade steps out of the ash circle without a glance at his son and takes his place in the queue again, as if he had only stood aside to let a cart go by."
							],
							[
								"Qiu Ye",
								"You took him. The last thing my house had, and you took it. Hear me, sweeper: everything you love. The sect, the steps, the girl at your side. Everything."
							],
							[
								"Narrator",
								"He is gone into the lilies before Lin Feng can answer, the black sword still humming on his back, and the red flowers close behind him like a mouth."
							],
							[
								"Yue Ling",
								"He will come back. People who swear like that always come back."
							]
						]
					},
					{
						"id": "farewell",
						"label": "Help him say goodbye",
						"desc": "Sheathe your sword and offer to help him do it properly instead: incense, bows, the walk to the bridge. His father goes on unbound, and the house of Qiu will live or die by its last son; it will cost Qiu Ye the last of his pride.",
						"log": "Helped Qiu Ye say goodbye to his father properly at the bridge, and the second son broke.",
						"then": "turning",
						"after": [
							[
								"Narrator",
								"Qiu Ye stares at Lin Feng for a long time. Then he throws the black sword into the golden water, still whispering, and watches it sink. Incense, three bows, and the long walk down the queue to the bridge's foot."
							],
							[
								"Lord Qiu's Shade",
								"I forgive you nothing. Not the sword, not the mask, not the thread. But you held your grandfather's sword better than he ever did. I saw it once, when you were nine, and I never said so."
							],
							[
								"Narrator",
								"Qiu Ye stands very straight for as long as he can. Then he folds over his grandfather's sword and weeps like a much younger boy, and the old man waits beside him until he has finished."
							],
							[
								"Qiu Ye",
								"When you go down to the King, sweeper, I am coming with you. I know every court of this place from the queue, and there is nothing left down here that I am afraid of."
							]
						]
					}
				]
			},
			"doubt": {
				"lines": [
					[
						"Narrator",
						"Far back in the queue of the dead, among the red lilies, Qiu Ye stands beside a grey old man in a lord's faded robes. Neither of them is speaking. By the look of it, neither has spoken for days."
					],
					[
						"Qiu Ye",
						"Sweeper. You held out your hand among the barrows, and I would not take it. I left the swords, though. Then I left the Ashen Moon, and then I found I had nowhere left to leave. I have sold my sword to caravans ever since."
					],
					[
						"Qiu Ye",
						"Word came down the caravan roads that my father had died, alone in the house at Cloudfoot with the gate barred. I came down the funeral road to see him off. I have told him everything, standing here. He has not said one word."
					],
					[
						"Narrator",
						"The old man looks at the bridge, at the lilies, at Lin Feng and at Yue Ling. He does not look at his son."
					],
					[
						"Yue Ling",
						"You came all this way, and he will not even look at you?"
					],
					[
						"Qiu Ye",
						"He is a Qiu. We are very good at not looking at things. I did not look at your sweeper for three years."
					]
				],
				"ask": "A father who will not speak. What will you do?",
				"options": [
					{
						"id": "walk",
						"label": "Walk them to the bridge",
						"desc": "Walk father and son down the long queue to the foot of the Naihe Bridge, as the living see a traveller off, and stand between them until one of them speaks. It will take the rest of the day, and your own search must wait.",
						"log": "Walked Qiu Ye and his father to the Naihe Bridge, and father and son spoke at last.",
						"then": "brother",
						"after": [
							[
								"Narrator",
								"It is a long walk down the queue. Halfway, the old man asks Lin Feng whether the sect still serves that bitter tea. At the foot of the bridge, at last, he turns to his son."
							],
							[
								"Lord Qiu's Shade",
								"You left the saints' swords on their graves. You told me so on the second day. A Qiu who puts back what he took is more than I ever managed to raise."
							],
							[
								"Qiu Ye",
								"...Father.",
								"kneel"
							],
							[
								"Narrator",
								"They talk until the golden light dims. Afterwards Qiu Ye comes back through the lilies and says, to nobody in particular, that when Lin Feng goes down to the King he is going too."
							]
						]
					},
					{
						"id": "leave",
						"label": "Leave them to it",
						"desc": "Leave father and son to find their own words, and go on with your own search down the queue. It is their grief, not yours to manage; but with nobody standing between them, neither of them may ever speak first.",
						"log": "Left Qiu Ye and his father to find their own words, and went on with his own search.",
						"then": "distant",
						"after": [
							[
								"Lin Feng",
								"This is between the two of you, Qiu Ye. I am sorry."
							],
							[
								"Qiu Ye",
								"Of course. You have your own to find. Everybody does."
							],
							[
								"Narrator",
								"When Lin Feng looks back from the lilies, father and son are standing exactly as he left them, a step apart, both looking at the bridge."
							]
						]
					}
				]
			},
			"freed": {
				"lines": [
					[
						"Narrator",
						"Far back in the queue of the dead, among the red lilies, Qiu Ye stands beside a grey old man in a lord's faded robes. Neither of them is speaking. By the look of it, neither has spoken for days."
					],
					[
						"Qiu Ye",
						"Sweeper. It has been quiet in my head since the graveyard. You broke that sword and left me alone with my own voice, and my own voice kept saying thief. So I went to the Elder and told him about the pill."
					],
					[
						"Qiu Ye",
						"He took back my jade token and set me among the outer disciples again. I wrote to my father and told him all of it. He never answered. Then Postmaster Lu sent word up the mountain that he had died."
					],
					[
						"Qiu Ye",
						"I came down the funeral road to see him off. I have told him everything again, standing here. Not one word back. A Qiu, and a thief, and he heard it from the thief himself."
					],
					[
						"Yue Ling",
						"You told the truth when nobody would ever have known. That is not nothing, Qiu Ye."
					],
					[
						"Qiu Ye",
						"Tell him that. He will not hear it from me."
					]
				],
				"ask": "A father who will not speak. What will you do?",
				"options": [
					{
						"id": "walk",
						"label": "Walk them to the bridge",
						"desc": "Walk father and son down the long queue to the foot of the Naihe Bridge, as the living see a traveller off, and stand between them until one of them speaks. It will take the rest of the day, and your own search must wait.",
						"log": "Walked Qiu Ye and his father to the Naihe Bridge, and father and son spoke at last.",
						"then": "brother",
						"after": [
							[
								"Narrator",
								"It is a long walk down the queue. At the foot of the bridge the old man speaks at last, to the bridge rather than to his son."
							],
							[
								"Lord Qiu's Shade",
								"Your letter was by my bed when I died. I read it nine times. Your grandfather never once told the truth when a lie would serve. Neither did I. You are the first Qiu in three generations who has."
							],
							[
								"Qiu Ye",
								"Is that pride, Father? From you it is very hard to tell."
							],
							[
								"Lord Qiu's Shade",
								"It is all you are going to get. Take it. Then go down to the King with your sweeper, and do not bow to him. A Qiu never bowed to a king who kept him waiting."
							]
						]
					},
					{
						"id": "leave",
						"label": "Leave them to it",
						"desc": "Leave father and son to find their own words, and go on with your own search down the queue. It is their grief, not yours to manage; but with nobody standing between them, neither of them may ever speak first.",
						"log": "Left Qiu Ye and his father to find their own words, and went on with his own search.",
						"then": "distant",
						"after": [
							[
								"Lin Feng",
								"This is between the two of you, Qiu Ye. I am sorry."
							],
							[
								"Qiu Ye",
								"Of course. Go and find your own. I have been confessing to a silent man for a week. I can manage another day."
							],
							[
								"Narrator",
								"When Lin Feng looks back from the lilies, father and son are standing exactly as he left them, a step apart, both looking at the bridge."
							]
						]
					}
				]
			},
			"friend": {
				"lines": [
					[
						"Narrator",
						"Far back in the queue of the dead, among the red lilies, Qiu Ye stands beside a grey old man in a lord's faded robes. Neither of them is speaking. By the look of it, neither has spoken for days."
					],
					[
						"Qiu Ye",
						"Lin Feng. I still have the scar from the graveyard. I show it to the juniors and tell them who gave it to me. They never believe me, which does wonders for my reputation.",
						"laugh"
					],
					[
						"Qiu Ye",
						"Postmaster Lu sent word up the mountain that my father had died, alone in the house at Cloudfoot. I came down the funeral road to see him off. I have told him everything, standing here. He has not said a word."
					],
					[
						"Qiu Ye",
						"Nine days late. He kept his word: I was not to come home, so I did not. Two proud men with a gate between them, and now there is a bridge instead."
					],
					[
						"Yue Ling",
						"He has not left your side, though. Not once, in all these days."
					],
					[
						"Qiu Ye",
						"He has not left his place in the queue. With my father, there was always a difference."
					]
				],
				"ask": "A father who will not speak. What will you do?",
				"options": [
					{
						"id": "walk",
						"label": "Walk them to the bridge",
						"desc": "Walk father and son down the long queue to the foot of the Naihe Bridge, as the living see a traveller off, and stand between them until one of them speaks. It will take the rest of the day, and your own search must wait.",
						"log": "Walked Qiu Ye and his father to the Naihe Bridge, and father and son spoke at last.",
						"then": "brother",
						"after": [
							[
								"Narrator",
								"It is a long walk down the queue. Halfway, the old man asks Yue Ling whether his son still holds a sword like a man swatting flies. She says no. He grunts, and at the foot of the bridge he turns."
							],
							[
								"Lord Qiu's Shade",
								"I opened the gate on the tenth day of the new year. I sat beside it until the lamp went out. You never came."
							],
							[
								"Qiu Ye",
								"You told me not to. I thought you meant it. I thought you always meant it.",
								"grieve"
							],
							[
								"Narrator",
								"They talk until the golden light dims. When it is done, Qiu Ye tells Lin Feng that he knows every court of this place from the queue, and that when Lin Feng goes down to the King, he is coming."
							]
						]
					},
					{
						"id": "leave",
						"label": "Leave them to it",
						"desc": "Leave father and son to find their own words, and go on with your own search down the queue. It is their grief, not yours to manage; but with nobody standing between them, neither of them may ever speak first.",
						"log": "Left Qiu Ye and his father to find their own words, and went on with his own search.",
						"then": "distant",
						"after": [
							[
								"Lin Feng",
								"This is between the two of you, Qiu Ye. I am sorry."
							],
							[
								"Qiu Ye",
								"Of course. You have your own to find. Go on. I am used to waiting at gates."
							],
							[
								"Narrator",
								"When Lin Feng looks back from the lilies, father and son are standing exactly as he left them, a step apart, both looking at the bridge."
							]
						]
					}
				]
			},
			"flattered": {
				"lines": [
					[
						"Narrator",
						"Far back in the queue of the dead, among the red lilies, Qiu Ye stands beside a grey old man in a lord's faded robes. Neither of them is speaking. By the look of it, neither has spoken for days."
					],
					[
						"Qiu Ye",
						"Lin Feng! The man I beat among the saints' swords. I tell everyone. Most of them believe me.",
						"laugh"
					],
					[
						"Qiu Ye",
						"I wrote to my father the day after. I beat the sweeper who killed the Jade Emperor, I wrote. He sent back one line: a Qiu does not boast, and a Qiu does not lie. Then nothing, ever again."
					],
					[
						"Qiu Ye",
						"Postmaster Lu sent word that he had died, alone in the house at Cloudfoot. I came down to see him off, and he will not say a word to me. He thinks I lied to him. Can you imagine?"
					],
					[
						"Yue Ling",
						"Lin Feng. Perhaps there is something he ought to hear from you."
					]
				],
				"ask": "A father who will not speak. What will you do?",
				"options": [
					{
						"id": "walk",
						"label": "Walk them to the bridge",
						"desc": "Walk father and son down the long queue to the foot of the Naihe Bridge and stand between them until one speaks. The old man thinks his son lied about your duel; you will have to tell him the truth, in front of his son.",
						"log": "Told Lord Qiu the truth about the duel at the bridge, and father and son spoke at last.",
						"then": "brother",
						"after": [
							[
								"Narrator",
								"At the foot of the bridge Lin Feng tells the old man the truth, in front of his son: that he dropped his guard on purpose among the barrows, and that Qiu Ye never knew."
							],
							[
								"Qiu Ye",
								"...You let me win.",
								"shock"
							],
							[
								"Lord Qiu's Shade",
								"So my son did not lie to me. His friend lied to him, out of kindness, which is worse and better. Come here, boy. A fool, and nine days late, and honest. Come here."
							],
							[
								"Narrator",
								"Father and son talk until the golden light dims. Afterwards Qiu Ye punches Lin Feng in the shoulder, twice and hard, and says he is coming down to the King with him, and will not hear otherwise."
							]
						]
					},
					{
						"id": "leave",
						"label": "Leave them to it",
						"desc": "Leave father and son to find their own words, and go on with your own search down the queue. It is their grief, not yours; but the old man will go on believing his son lied, and his son will go on believing he won.",
						"log": "Left Qiu Ye and his father to find their own words, and went on with his own search.",
						"then": "distant",
						"after": [
							[
								"Lin Feng",
								"This is between the two of you, Qiu Ye. I am sorry."
							],
							[
								"Qiu Ye",
								"Of course. Go on. I will tell him again how I beat you. Perhaps this time he will believe me."
							],
							[
								"Narrator",
								"When Lin Feng looks back from the lilies, father and son are standing exactly as he left them, a step apart, both looking at the bridge."
							]
						]
					}
				]
			}
		}
	},
	"s_f_qiu4": {
		"n": "The Ashen Brother",
		"by": {
			"foe": {
				"lines": [
					[
						"Narrator",
						"At dusk the last disciples of the Ashen Moon come over the sect wall in their lacquered half-masks, a dozen at most, and stop there. Qiu Ye walks in alone through the open gate, as if he still had the right. Something moves behind his eyes that is not him."
					],
					[
						"Qiu Ye",
						"Sweeper. I swore at the bridge I would come for everything you love. It took me longer than I meant. Something found me on the road and showed me the way. It keeps very good accounts."
					],
					[
						"Qiu Ye",
						"It says you owe me a father, a house and a name. It says you have been taking from me since the night you caught me in this courtyard, and that a debt nobody pays can always be collected."
					],
					[
						"Yue Ling",
						"Look at his eyes, Lin Feng. That is Nie looking out of them. It has his grudge in its hands, and it is pulling."
					],
					[
						"Lin Feng",
						"Then we settle it here, Qiu Ye, you and I. The sect stays out of it."
					],
					[
						"Qiu Ye",
						"You do not get to choose what is collected, sweeper. Draw."
					]
				],
				"ask": "Nie looks out of Qiu Ye's eyes. What now?",
				"options": [
					{
						"id": "face",
						"label": "Face him",
						"desc": "Meet him sword to sword in the courtyard where it began, before Nie's shadow can turn him on the sect. He will not stop until one of you is down; when he is, you will have to decide what he is owed.",
						"log": "Met Qiu Ye sword to sword in the sect courtyard where it all began.",
						"then": "",
						"battle": [
							[
								"qiu_ye",
								55
							]
						],
						"follow": {
							"lines": [
								[
									"Narrator",
									"Qiu Ye goes down on the flagstones where he once stood with a stolen pill in his hand. The thing behind his eyes thins like ink in water, and on the wall the masks begin, quietly, to leave."
								],
								[
									"Qiu Ye",
									"Go on, then. It is what I would do. It is what my father would have done. Collect."
								],
								[
									"Yue Ling",
									"Nie is going out of him, Lin Feng. Whatever you do now, it is Qiu Ye who will feel it, not the shadow."
								]
							],
							"ask": "Qiu Ye lies beaten on the flagstones. What is he owed?",
							"options": [
								{
									"id": "spare",
									"label": "Spare him",
									"desc": "Sheathe your sword and hold out your hand. Nie loses its grip on him and he lives; but he will have to live with what he swore and did, and the sect he came to burn will have to live with him.",
									"log": "Spared Qiu Ye on the flagstones, and the shadow went out of his eyes for good.",
									"then": "redeemed",
									"after": [
										[
											"Narrator",
											"Lin Feng holds out his hand. Qiu Ye looks at it for a long time, then takes it, and something like soot lifts off him and drifts west, towards the Wheel, thinner than it came."
										],
										[
											"Qiu Ye",
											"You should have ended it. ...No. I am glad you did not. That is the worst of it."
										],
										[
											"Narrator",
											"He unties the lacquered half-mask and lays it on the flagstones. Then he asks, very stiffly, whether a man who swore to destroy everything Lin Feng loves may walk beside him to the Wheel."
										],
										[
											"Yue Ling",
											"Yes. He may.",
											"nod"
										]
									],
									"gain": {
										"outfit": "ink"
									}
								},
								{
									"id": "end",
									"label": "End it",
									"desc": "End it here, in the courtyard where it began. Nie loses him the only certain way, and nothing of the house of Qiu will ever come for you again; nor will anything of Qiu Ye, for good or for ill.",
									"log": "Ended Qiu Ye in the sect courtyard, and Nie's shadow died with him.",
									"then": "fallen",
									"after": [
										[
											"Narrator",
											"It is quick. Lin Feng sees to that. The shadow goes out of Qiu Ye's eyes a moment before the rest of him does, and for that moment he looks seventeen again."
										],
										[
											"Qiu Ye",
											"Grandfather's sword. Do not let them hang it in a hall. It hates halls."
										],
										[
											"Yue Ling",
											"He was so tired, Lin Feng. At the very end, he was only tired.",
											"grieve"
										]
									]
								}
							]
						}
					}
				]
			},
			"turning": {
				"lines": [
					[
						"Narrator",
						"Gate Disciple Wu has let him as far as the courtyard and no further: a young man in dark green and silver, a bundle under his arm, his grandfather's jian unbuckled and laid on the flagstones at his feet."
					],
					[
						"Qiu Ye",
						"Sweeper. I have come to ask to be let back in. I know what I did, and what I wore while I did it. I do not ask for a robe. I will take a broom, if the Elder will give me one."
					],
					[
						"Qiu Ye",
						"Since the bridge I have not slept well. My father said one true thing to me, and it keeps me awake. This month something came whispering at my door with my old grudges, offering them back with interest. I told it I had paid them."
					],
					[
						"Elder Qing Xuan",
						"A sect is not a ledger, but it has a memory. If he comes back, Lin Feng, it will be because someone this sect trusts stands for him. I will not take him on his own word."
					],
					[
						"Yue Ling",
						"He said goodbye to his father properly. I was there. That is not nothing."
					],
					[
						"Qiu Ye",
						"Whatever you decide. I will not ask twice. A Qiu does not ask twice."
					]
				],
				"ask": "Will you stand for Qiu Ye before the Elder?",
				"options": [
					{
						"id": "vouch",
						"label": "Vouch for him",
						"desc": "Stand for him before the Elder, with your own name as his surety. He will sweep the steps and earn the rest back slowly; and if he ever falls again, the sect will remember who let him in.",
						"log": "Vouched for Qiu Ye before the Elder, and the second son came home to sweep the steps.",
						"then": "redeemed",
						"gain": {
							"outfit": "ink"
						},
						"after": [
							[
								"Elder Qing Xuan",
								"Then from today he is a sweeper of this sect. Three hundred and ninety-one steps, Qiu Ye. Lin Feng never missed a morning.",
								"nod"
							],
							[
								"Qiu Ye",
								"Then take these: the Ashen Moon's black robe and half-mask. The lantern monk in the gorge chanted over them for seven nights, until nothing was left in them but cloth. I am done hiding my face.",
								"offer"
							],
							[
								"Narrator",
								"At dawn there are two sweepers on the steps, one small and one proud. By noon the proud one has asked where Nie is gathering, and whether a sweeper may come and help."
							]
						]
					},
					{
						"id": "refuse",
						"label": "Refuse to vouch",
						"desc": "Tell the Elder you cannot stand for him. The sect keeps its gate shut to the Ashen Moon and nobody can call you careless with it; Qiu Ye goes down the mountain once more, and this time it is your doing.",
						"log": "Would not vouch for Qiu Ye, and he went down the mountain without asking twice.",
						"then": "parted",
						"after": [
							[
								"Qiu Ye",
								"That is fair. I would not have vouched for me either.",
								"nod"
							],
							[
								"Narrator",
								"He buckles on his grandfather's sword, bows once to the Elder and once to Lin Feng, and goes down the steps. This time, at the top of the last flight, he looks back."
							]
						]
					}
				]
			},
			"brother": {
				"lines": [
					[
						"Narrator",
						"Qiu Ye is waiting by the spirit spring in the courtyard with his grandfather's jian across his knees and a whetstone in his hand. He has plainly been there some time, and would like it to look as if he has not."
					],
					[
						"Qiu Ye",
						"Sweeper. Since the bridge I have been waiting for you to need something. You never do, so I have had to invent it. Something is gathering at the Wheel, they say. Something made of debts."
					],
					[
						"Qiu Ye",
						"I know that road better than you. I stood in that queue a week with my father, and I walked him to the bridge with you beside me. I would like to walk it with you once more."
					],
					[
						"Yue Ling",
						"He has been sharpening that sword since the Conclave. Auntie Zhou says he has worn out three whetstones."
					],
					[
						"Lin Feng",
						"It will not be a duel, Qiu Ye. Nie remembers everything anybody ever owed."
					],
					[
						"Qiu Ye",
						"Good. So do I. I owe you a walk to the bridge, and a Qiu pays his debts.",
						"nod"
					]
				],
				"ask": "Qiu Ye means to stand with you at the Wheel.",
				"options": [
					{
						"id": "together",
						"label": "Go to the Wheel together",
						"desc": "Take him down the funeral road with you to stand against Nie at the Wheel. He will be in the thick of it at your side, and whatever Nie holds of the house of Qiu, he will have to meet it face to face.",
						"log": "Took Qiu Ye down the funeral road to stand with him against Nie at the Wheel.",
						"then": "ally",
						"after": [
							[
								"Qiu Ye",
								"I take the left. I have always taken the left. You never noticed, because you were looking at the steps."
							],
							[
								"Narrator",
								"They go down the funeral road three abreast, Yue Ling in the middle, and the gate disciples who remember the proud boy and the sweeper stop their work to watch them go."
							]
						]
					}
				]
			},
			"distant": {
				"lines": [
					[
						"Narrator",
						"A sedan chair with the crest of the house of Qiu new-painted on its door waits at the sect gate. In the courtyard Qiu Ye, head of his house now, greets Lin Feng with a perfect bow."
					],
					[
						"Qiu Ye",
						"Lord Sweeper. The minutes of the Conclave reached Cloudfoot. My congratulations on Myriad Daos as One. The house of Qiu sends its regards, and a box of tea rather better than the sect deserves.",
						"bow"
					],
					[
						"Qiu Ye",
						"I have mended the roof at Cloudfoot and paid the house's creditors, every one. My father would have hated the colour I painted the gate. I find I can live with that."
					],
					[
						"Yue Ling",
						"We have missed you, Qiu Ye. Ever since the bridge."
					],
					[
						"Qiu Ye",
						"Have you? You were busy, as I recall. Everyone has their own queue to stand in. Forgive me. That was ungracious, and the head of a house should never be ungracious."
					]
				],
				"ask": "Qiu Ye is courteous and far away. What will you do?",
				"options": [
					{
						"id": "ask",
						"label": "Ask him to stand with you",
						"desc": "Ask him plainly, as an equal, to come to the Wheel and stand against Nie with you, and say what you should have said at the bridge. It costs your pride, not his; and at your side he will be in danger.",
						"log": "Asked Qiu Ye, as an equal, to stand with him at the Wheel, and owned the day at the bridge.",
						"then": "ally",
						"after": [
							[
								"Lin Feng",
								"I should have walked with you at the bridge. I went looking for my own and left you alone with yours. Will you come to the Wheel, Qiu Ye? Not for me. With me."
							],
							[
								"Qiu Ye",
								"...You took your time."
							],
							[
								"Narrator",
								"He sends the sedan chair home empty and walks down the funeral road beside them, and somewhere in the Maple Gorge he stops calling Lin Feng 'Lord Sweeper'."
							]
						]
					},
					{
						"id": "let",
						"label": "Let him go home",
						"desc": "Thank him for the tea and let him go home to Cloudfoot and his mended roof. He has built a life without you in it, and you respect that; he will not be at the Wheel, and you will never know if he would have come.",
						"log": "Thanked Qiu Ye for the tea, and let him go home to Cloudfoot.",
						"then": "parted",
						"after": [
							[
								"Qiu Ye",
								"Then I take my leave, Lord Sweeper. If you are ever in Cloudfoot, the gate is a colour my father would have hated. You cannot miss it.",
								"bow"
							],
							[
								"Narrator",
								"The sedan chair goes down the mountain at a stately pace. Lin Feng watches it until it is a speck among the pines. It does not stop, and nobody inside it looks back."
							]
						]
					}
				]
			}
		}
	},
	"s_f_hu1": {
		"n": "The Bandit's Son",
		"by": {
			"*": {
				"lines": [
					[
						"Narrator",
						"Morning in the bamboo. The crossbowmen have gone from the ridge in the night, and Iron Fang lies on a reed mat by a cold cook-fire. He died of his wounds before dawn. His iron tooth shows, as if he were about to laugh."
					],
					[
						"Narrator",
						"Over him stands a boy of ten in patched brown, his hair uncombed, holding a kitchen knife out in both hands like a sword."
					],
					[
						"Little Hu",
						"You killed my father. He said a sect boy with a rusty sword did it, and he laughed about that half the night. Then he stopped laughing.",
						"point"
					],
					[
						"Yue Ling",
						"Lin Feng, this is Hu. When the men forgot me at the post by the water butt, he brought me rice. He is ten years old."
					],
					[
						"Little Hu",
						"When he was twelve he climbed your sect's steps, and they sent him down the same day for having no root. He lost a tooth fighting at your gate and had an iron one made. He said nobody would ever send us down any steps again."
					],
					[
						"Narrator",
						"In the hut behind the boy a gourd of marsh venom hangs from the rafter, still stoppered with wax. The boy does not look at it. Yue Ling does."
					],
					[
						"Lin Feng",
						"I did kill him. I fought him to free her, and I never once thought about who was waiting at his fire. I am thinking about it now.",
						"kneel"
					]
				],
				"ask": "What becomes of Iron Fang's son?",
				"options": [
					{
						"id": "village",
						"label": "Take him to Granny Wen",
						"desc": "Carry him down to Qingshi, to the midwife who raised you. He gets a roof, a stove and a fierce old woman, and grows up the bandit's son among farmers his father's men once robbed. Granny Wen gets one more mouth to feed.",
						"log": "Took Little Hu down to Granny Wen in Qingshi, to grow up by the stove where Lin Feng grew up.",
						"then": "village",
						"after": [
							[
								"Narrator",
								"They bury Iron Fang under the bamboo. Before the earth goes in, Little Hu pulls the iron gauntlet off his father's right hand. It comes up past his elbow."
							],
							[
								"Narrator",
								"At dusk Granny Wen opens her door in Qingshi, looks at the boy and the knife and the gauntlet, and sets another bowl on the table without asking a single question."
							],
							[
								"Little Hu",
								"I am still going to kill you. When I am bigger.",
								"point"
							],
							[
								"Lin Feng",
								"Then eat. She does not let anybody kill anybody on an empty stomach."
							]
						]
					},
					{
						"id": "sect",
						"label": "Bring him to the sect",
						"desc": "Take him up the mountain to sweep the steps, as you did. The Elder will grumble and find him a broom. He will sweep the stair his father was sent down for want of a root, and see the man who killed his father every day.",
						"log": "Brought Little Hu up the mountain to sweep the very steps his father had once been sent down.",
						"then": "sect",
						"after": [
							[
								"Narrator",
								"They bury Iron Fang under the bamboo. Before the earth goes in, Little Hu pulls the iron gauntlet off his father's right hand. It comes up past his elbow."
							],
							[
								"Narrator",
								"At the sect gate the Elder looks at the boy for a long time, then hands him a broom. 'Top to bottom,' he says. 'Every morning. The bottom is the hardest part.'"
							],
							[
								"Little Hu",
								"I will sweep them. And when I am strong enough, I will kill you on them."
							],
							[
								"Lin Feng",
								"Sweep them first. It took me three years to learn what they were for."
							]
						]
					},
					{
						"id": "go",
						"label": "Let him go",
						"desc": "Step back and let him run. He takes his knife, his father's gauntlet and his grudge into the bamboo, alone or with what is left of the crossbowmen, and nobody will tell him what his father was except the men who followed him.",
						"log": "Let Little Hu run into the bamboo with a kitchen knife, his father's gauntlet and a sworn grudge.",
						"then": "wild",
						"after": [
							[
								"Narrator",
								"Little Hu snatches the iron gauntlet off his father's hand and runs. At the edge of the bamboo he turns, the gauntlet up past his elbow."
							],
							[
								"Little Hu",
								"Remember my face, sect boy! I will remember yours, and I will come back for you when I am big!",
								"point"
							],
							[
								"Narrator",
								"Lin Feng buries Iron Fang alone. Yue Ling leaves a bowl of rice on the grave, the way the boy used to leave one by her post."
							],
							[
								"Yue Ling",
								"He was kind to me when it would have cost him nothing to be cruel. I hope the bamboo is kind to him.",
								"grieve"
							]
						]
					}
				]
			}
		}
	},
	"s_f_hu2": {
		"n": "Iron in the Village",
		"by": {
			"village": {
				"lines": [
					[
						"Narrator",
						"Behind a barricade of carts by the Earth God's shrine stands the village watch: four farmers with rakes, and the youngest of them, Fang Hu, with an iron gauntlet that nearly fits him now and his wild hair tied back with string."
					],
					[
						"Fang Hu",
						"You cut the threads off the roofs. Good. Now take me with you. I have stood behind these carts every night since the moths came down the chimneys, and Granny will not let me past the well."
					],
					[
						"Granny Wen the Midwife",
						"He sleeps in your old corner by the stove and eats like you did. When he was small he asked me every morning whether today was the day he killed you. Now he only asks on your birthday."
					],
					[
						"Fang Hu",
						"I still might. But not while things in silk masks walk past the cradles. Let me fight beside you once. Then I will know what you are, and what he was up against."
					],
					[
						"Yue Ling",
						"The boy who brought me rice. You have grown into your father's shoulders, Hu."
					]
				],
				"ask": "Where does Fang Hu stand tonight?",
				"options": [
					{
						"id": "fight",
						"label": "Fight beside him",
						"desc": "Take him into the lanes against a silk-masked bandit, a paper crow and a thread moth, and let him fight at your side. He will learn what a real fight costs, and Granny Wen will never forgive you if he comes home cut.",
						"log": "Took Fang Hu into the lanes of Qingshi, and he fought beside Lin Feng against the Weaver's creatures.",
						"then": "watchman",
						"battle": [
							[
								"silk_bandit",
								33
							],
							[
								"paper_crow",
								33
							],
							[
								"thread_moth",
								32
							]
						],
						"after": [
							[
								"Narrator",
								"When the last paper crow comes apart, Fang Hu is breathing hard, with a cut on his cheek and a new dent in the gauntlet. He looks at Lin Feng for a long moment."
							],
							[
								"Fang Hu",
								"You were holding back. You fight like a man who has done this so often he is tired of it. Was it like that with him?"
							],
							[
								"Lin Feng",
								"No. With him I was frightened the whole time."
							],
							[
								"Fang Hu",
								"...Good. I mean, I am glad he frightened you."
							]
						]
					},
					{
						"id": "guard",
						"label": "Send him to guard the cradles",
						"desc": "Send him to keep watch at the houses of the three sleeping newborns, Little Wan's among them. No glory and no fighting, only long nights on doorsteps beside mothers who cannot sleep. He will be furious, and the cradles will be safe.",
						"log": "Sent Fang Hu to guard the doors of Qingshi's sleeping newborns, Little Wan's among them.",
						"then": "guardian",
						"after": [
							[
								"Fang Hu",
								"Babies. You came all the way down the mountain to make me a nursemaid.",
								"shake"
							],
							[
								"Lin Feng",
								"One of those cradles matters to me more than I can tell you. I am giving you the one thing I would trust to nobody else."
							],
							[
								"Narrator",
								"That night Fang Hu sits on Little Wan's doorstep with the gauntlet across his knees, and every paper crow that dives at the door goes home in pieces."
							]
						]
					}
				]
			},
			"sect": {
				"lines": [
					[
						"Narrator",
						"Out of the rice comes a young man in outer-disciple grey, very out of breath, an iron gauntlet on his right hand and his wild hair tied back with broom twine. It is Fang Hu, the boy Lin Feng brought up the mountain to sweep."
					],
					[
						"Fang Hu",
						"I followed you down. Without leave. The Elder will have my hide. I swept your steps every morning, top to bottom, the steps they sent my father down, and then the Elder tested me and found a root as thin as a hair."
					],
					[
						"Fang Hu",
						"A thin root still drinks. But nobody will teach the sword to a bandit's son. They hand me a broom and look at the gauntlet. You are the only one who never looks at the gauntlet."
					],
					[
						"Yue Ling",
						"He means it, Lin Feng. He practises behind the kitchens with a broom handle. I have bandaged both his hands twice."
					],
					[
						"Fang Hu",
						"Teach me. I want to know how a sweeper with a rusty sword beat Iron Fang. Then I will decide what to do with knowing it.",
						"kneel"
					]
				],
				"ask": "Will you teach Fang Hu the sword?",
				"options": [
					{
						"id": "teach",
						"label": "Teach him the sword",
						"desc": "Take him as your own student here among the paddies, and answer to the Elder for his leaving without leave. You put a sword in the hand of the son of the man you killed, and teach him every way you know to use it.",
						"log": "Taught Fang Hu the sword in the paddies of Qingshi: Iron Fang's son, learning from his father's killer.",
						"then": "disciple",
						"after": [
							[
								"Narrator",
								"Lin Feng teaches him between the paddies until dusk: the stance, the breath, the first cut. Fang Hu is clumsy and stubborn and does not complain once."
							],
							[
								"Fang Hu",
								"Show me the cut you used on him."
							],
							[
								"Lin Feng",
								"No. I will teach you every cut I know but that one."
							],
							[
								"Yue Ling",
								"He will look for it anyway. That is what students are for."
							]
						]
					},
					{
						"id": "own",
						"label": "Tell him to find his own road",
						"desc": "Refuse to teach him, and tell him a sword learned to answer one man is a short sword. He leaves the sect to wander and find his own teachers, owing you nothing, and you will not know what he learns or what he means to do with it.",
						"log": "Refused to teach Fang Hu and told him to find his own road; he walked out of the sect to look for it.",
						"then": "seeker",
						"after": [
							[
								"Fang Hu",
								"My own road. My father had one of those. It went down your steps and into the bamboo."
							],
							[
								"Lin Feng",
								"Then do not take his, and do not take mine. The land has grown back together, Hu. There are roads now that did not exist when they turned him away."
							],
							[
								"Narrator",
								"Fang Hu stands in the paddy a long time. Then he bows, very stiffly. Tomorrow he will take a road the threads have only just let go of, and he will not tell anyone which."
							]
						]
					}
				]
			},
			"wild": {
				"lines": [
					[
						"Narrator",
						"In the lane by the tofu shop highwaymen are loading the village's rice onto a cart, some in silk masks, moving like sleepwalkers. Their leader wears no mask, only an iron gauntlet. It is Fang Hu, the boy Lin Feng let run into the bamboo."
					],
					[
						"Fang Hu",
						"Sect boy. You got tall. I told you I would remember your face."
					],
					[
						"Fang Hu",
						"On the hill roads they call me Young Fang. We came down when the threads fell, because a village that cannot run is a village that pays. Half my men woke up with silk over their faces. The other half are still mine."
					],
					[
						"Yue Ling",
						"Hu. You brought me rice once, when it would have cost you nothing to be cruel. These people have nothing left but their rice."
					],
					[
						"Fang Hu",
						"And my father bled out on a mat while you walked off with her. Draw, sect boy. I have been practising on milestones since the day you let me go.",
						"point"
					],
					[
						"Lin Feng",
						"Put the rice back first. Whatever you are owed, it is not theirs to pay."
					]
				],
				"ask": "Young Fang will not put the rice back.",
				"options": [
					{
						"id": "fight",
						"label": "Fight Young Fang",
						"desc": "Fight him in the lane among the rice sacks, in front of the village he came to rob. You will beat the son as you beat the father, and whatever you decide afterwards, every door in Qingshi will have watched you do it.",
						"log": "Fought Young Fang among the rice sacks of Qingshi and beat him, as Lin Feng once beat his father.",
						"then": "",
						"battle": [
							[
								"young_fang",
								33
							]
						],
						"follow": {
							"lines": [
								[
									"Narrator",
									"Young Fang goes down among the spilled rice with his gauntlet dented, and does not get up. The silk-masked men stand quite still, waiting for orders that do not come."
								],
								[
									"Fang Hu",
									"Go on, then. Finish it. You finished him."
								],
								[
									"Yue Ling",
									"The elders are coming down the lane with the ox rope, Lin Feng. Whatever you do, do it before they get here."
								]
							],
							"ask": "What becomes of Young Fang?",
							"options": [
								{
									"id": "spare",
									"label": "Spare him and let him go",
									"desc": "Send the elders back up the lane and let him go free, with the rice left behind. He keeps his freedom, his grudge and his gauntlet, and Qingshi will remember that you let the man who robbed it walk away.",
									"log": "Spared Young Fang in the lanes of Qingshi and let him go before the elders came with the ox rope.",
									"then": "spared",
									"after": [
										[
											"Fang Hu",
											"Twice. You have let me go twice now. I do not understand you, sect boy.",
											"shake"
										],
										[
											"Lin Feng",
											"Nobody is taking you anywhere today. Sit there until you do understand. Then go somewhere that is not a village."
										],
										[
											"Narrator",
											"Young Fang stays where he is in the spilled rice, nursing his dented gauntlet, while Farmer Lao counts his sacks back in and says nothing to Lin Feng at all, which in Qingshi is worse than shouting."
										]
									]
								},
								{
									"id": "jail",
									"label": "Hand him to the elders",
									"desc": "Bind him and give him to the village elders, who will send him to the county magistrate in chains. Qingshi gets its justice and its rice back; he gets a cell, and a long time to think about whose hand put him there.",
									"log": "Handed Young Fang to the elders of Qingshi, who sent him to the county magistrate in chains.",
									"then": "jailed",
									"after": [
										[
											"Narrator",
											"The elders bind him with the ox rope. Young Fang does not struggle. He only watches Lin Feng over their shoulders, all the way up the lane."
										],
										[
											"Fang Hu",
											"My father robbed roads, and you killed him. I robbed a village, and you chain me. You are getting gentler, sect boy."
										],
										[
											"Lin Feng",
											"It was going to be chains or another grave under the bamboo. I could not dig another one."
										]
									]
								}
							]
						}
					}
				]
			}
		}
	},
	"s_f_hu3": {
		"n": "What My Father Was",
		"by": {
			"watchman": {
				"lines": [
					[
						"Narrator",
						"On a flooded quay a ferry guard in a harbour coat sits on a bollard with an iron gauntlet in his lap. It is Fang Hu, who fought beside Lin Feng in the lanes of Qingshi."
					],
					[
						"Fang Hu",
						"After the threads, Granny said the village watch was too small for me. Harbourmistress Jiang took me on for the ferries. I have been pulling drunks and carp out of the river all spring."
					],
					[
						"Fang Hu",
						"Last week Black Eel's rats came through the warehouses, and one of them knew me by the gauntlet. An old man with a crossbow scar. He used to hold the ridge above my father's camp."
					],
					[
						"Fang Hu",
						"He said my father took the Blood Moon's stones and a gourd of marsh venom to pour in your sect's wells. He laughed when he said it, as if it were a good joke."
					],
					[
						"Narrator",
						"Yue Ling looks at Lin Feng and says nothing. She is the one who was tied to the post by the water butt."
					],
					[
						"Fang Hu",
						"You were there. Tell me plainly, Lin Feng. Did he deserve to die?"
					]
				],
				"ask": "Did Iron Fang deserve to die?",
				"options": [
					{
						"id": "truth",
						"label": "Tell him the truth",
						"desc": "Tell him all of it: the Blood Moon's stones, the venom, Yue Ling tied up for refusing to pour it, and that he never poured it himself. He loses the father he was proud of and gets the real one, who is heavier to carry.",
						"log": "Told Fang Hu the truth at Longmen: the venom his father took, and the venom he never poured.",
						"then": "truth",
						"after": [
							[
								"Lin Feng",
								"It is true. He took their stones and their venom, and he tied Yue Ling to a post because she would not pour it for him. And all the while she was tied there, he never once poured it himself.",
								"nod"
							],
							[
								"Yue Ling",
								"Some nights he sat by the water butt with the gourd in his hands and said nothing. I think he wanted somebody to stop him."
							],
							[
								"Lin Feng",
								"Did he deserve to die? No. He deserved a gate that opened when he was twelve. But I would fight him again tomorrow to free her, and I am sorry for both."
							],
							[
								"Fang Hu",
								"...That is worse than the old man's joke. And better. Let me sit here a while."
							]
						]
					},
					{
						"id": "lie",
						"label": "Tell him his father was brave",
						"desc": "Tell him the old rat is lying: his father took no coin from the Blood Moon and died bravely, fighting for his men. He keeps a father to be proud of, built on your word. If he ever learns otherwise, he learns you lied too.",
						"log": "Told Fang Hu at Longmen that the old bandit lied, and that his father died brave and clean.",
						"then": "lie",
						"after": [
							[
								"Lin Feng",
								"The old man is lying. Your father never took a coin from the Blood Moon. He fought me like a tiger for his men, and he died as he lived."
							],
							[
								"Narrator",
								"Yue Ling turns and looks at the river for a long time. She does not say anything at all."
							],
							[
								"Fang Hu",
								"I knew it. I knew it. Thank you, Lin Feng.",
								"bow"
							],
							[
								"Narrator",
								"He gets up off the bollard lighter than he sat down, and the gauntlet hangs at his side like something to be proud of."
							]
						]
					}
				]
			},
			"guardian": {
				"lines": [
					[
						"Narrator",
						"On a flooded quay a ferry guard in a harbour coat sits on a bollard with an iron gauntlet in his lap. It is Fang Hu, whom Lin Feng set to guard Little Wan's door in Qingshi through the nights of the threads."
					],
					[
						"Fang Hu",
						"After a season of guarding cradles I could guard anything. Harbourmistress Jiang took me on for the ferries. She says I am the only guard she has who has never once fallen asleep."
					],
					[
						"Fang Hu",
						"Last week Black Eel's rats came through the warehouses, and one of them knew me by the gauntlet. An old man with a crossbow scar. He used to hold the ridge above my father's camp."
					],
					[
						"Fang Hu",
						"He said my father took the Blood Moon's stones and a gourd of marsh venom to pour in your sect's wells. He laughed when he said it, as if it were a good joke."
					],
					[
						"Narrator",
						"Yue Ling looks at Lin Feng and says nothing. She is the one who was tied to the post by the water butt."
					],
					[
						"Fang Hu",
						"You were there. Tell me plainly, Lin Feng. Did he deserve to die?"
					]
				],
				"ask": "Did Iron Fang deserve to die?",
				"options": [
					{
						"id": "truth",
						"label": "Tell him the truth",
						"desc": "Tell him all of it: the Blood Moon's stones, the venom, Yue Ling tied up for refusing to pour it, and that he never poured it himself. He loses the father he was proud of and gets the real one, who is heavier to carry.",
						"log": "Told Fang Hu the truth at Longmen: the venom his father took, and the venom he never poured.",
						"then": "truth",
						"after": [
							[
								"Lin Feng",
								"It is true. He took their stones and their venom, and he tied Yue Ling to a post because she would not pour it for him. And all the while she was tied there, he never once poured it himself.",
								"nod"
							],
							[
								"Yue Ling",
								"Some nights he sat by the water butt with the gourd in his hands and said nothing. I think he wanted somebody to stop him."
							],
							[
								"Lin Feng",
								"Did he deserve to die? No. He deserved a gate that opened when he was twelve. But I would fight him again tomorrow to free her, and I am sorry for both."
							],
							[
								"Fang Hu",
								"...That is worse than the old man's joke. And better. Let me sit here a while."
							]
						]
					},
					{
						"id": "lie",
						"label": "Tell him his father was brave",
						"desc": "Tell him the old rat is lying: his father took no coin from the Blood Moon and died bravely, fighting for his men. He keeps a father to be proud of, built on your word. If he ever learns otherwise, he learns you lied too.",
						"log": "Told Fang Hu at Longmen that the old bandit lied, and that his father died brave and clean.",
						"then": "lie",
						"after": [
							[
								"Lin Feng",
								"The old man is lying. Your father never took a coin from the Blood Moon. He fought me like a tiger for his men, and he died as he lived."
							],
							[
								"Narrator",
								"Yue Ling turns and looks at the river for a long time. She does not say anything at all."
							],
							[
								"Fang Hu",
								"I knew it. I knew it. Thank you, Lin Feng.",
								"bow"
							],
							[
								"Narrator",
								"He gets up off the bollard lighter than he sat down, and the gauntlet hangs at his side like something to be proud of."
							]
						]
					}
				]
			},
			"disciple": {
				"lines": [
					[
						"Narrator",
						"On a flooded quay a young swordsman in a travel-stained disciple's coat sits on a bollard with an iron gauntlet in his lap. It is Fang Hu, whom Lin Feng taught the sword in the paddies of Qingshi."
					],
					[
						"Fang Hu",
						"Teacher. I have been walking the rivers to practise what you showed me. Every cut but one, as you said. I am still looking for the one."
					],
					[
						"Fang Hu",
						"Last week Black Eel's rats came through the warehouses, and one of them knew me by the gauntlet. An old man with a crossbow scar. He used to hold the ridge above my father's camp."
					],
					[
						"Fang Hu",
						"He said my father took the Blood Moon's stones and a gourd of marsh venom to pour in your sect's wells. He laughed when he said it, as if it were a good joke."
					],
					[
						"Narrator",
						"Yue Ling looks at Lin Feng and says nothing. She is the one who was tied to the post by the water butt."
					],
					[
						"Fang Hu",
						"You were there. Tell me plainly, Teacher. Did he deserve to die?"
					]
				],
				"ask": "Did Iron Fang deserve to die?",
				"options": [
					{
						"id": "truth",
						"label": "Tell him the truth",
						"desc": "Tell him all of it: the Blood Moon's stones, the venom, Yue Ling tied up for refusing to pour it, and that he never poured it himself. He loses the father he was proud of and gets the real one, who is heavier to carry.",
						"log": "Told Fang Hu the truth at Longmen: the venom his father took, and the venom he never poured.",
						"then": "truth",
						"after": [
							[
								"Lin Feng",
								"It is true. He took their stones and their venom, and he tied Yue Ling to a post because she would not pour it for him. And all the while she was tied there, he never once poured it himself.",
								"nod"
							],
							[
								"Yue Ling",
								"Some nights he sat by the water butt with the gourd in his hands and said nothing. I think he wanted somebody to stop him."
							],
							[
								"Lin Feng",
								"Did he deserve to die? No. He deserved a gate that opened when he was twelve. But I would fight him again tomorrow to free her, and I am sorry for both."
							],
							[
								"Fang Hu",
								"...That is worse than the old man's joke. And better. Let me sit here a while."
							]
						]
					},
					{
						"id": "lie",
						"label": "Tell him his father was brave",
						"desc": "Tell him the old rat is lying: his father took no coin from the Blood Moon and died bravely, fighting for his men. He keeps a father to be proud of, built on your word. If he ever learns otherwise, he learns you lied too.",
						"log": "Told Fang Hu at Longmen that the old bandit lied, and that his father died brave and clean.",
						"then": "lie",
						"after": [
							[
								"Lin Feng",
								"The old man is lying. Your father never took a coin from the Blood Moon. He fought me like a tiger for his men, and he died as he lived."
							],
							[
								"Narrator",
								"Yue Ling turns and looks at the river for a long time. She does not say anything at all."
							],
							[
								"Fang Hu",
								"I knew it. I knew it. Thank you, Teacher.",
								"bow"
							],
							[
								"Narrator",
								"He gets up off the bollard lighter than he sat down, and the gauntlet hangs at his side like something to be proud of."
							]
						]
					}
				]
			},
			"seeker": {
				"lines": [
					[
						"Narrator",
						"On a flooded quay a young swordsman in a travel-stained coat sits on a bollard with an iron gauntlet in his lap. It is Fang Hu, whom Lin Feng sent off from Qingshi to find his own road."
					],
					[
						"Fang Hu",
						"I found a road. It went along a great many rivers. I learned the spear from a boatman and the staff from a monk, and not one thing from you, as you asked."
					],
					[
						"Fang Hu",
						"Last week Black Eel's rats came through the warehouses, and one of them knew me by the gauntlet. An old man with a crossbow scar. He used to hold the ridge above my father's camp."
					],
					[
						"Fang Hu",
						"He said my father took the Blood Moon's stones and a gourd of marsh venom to pour in your sect's wells. He laughed when he said it, as if it were a good joke."
					],
					[
						"Narrator",
						"Yue Ling looks at Lin Feng and says nothing. She is the one who was tied to the post by the water butt."
					],
					[
						"Fang Hu",
						"So I will ask you one thing after all. You were there. Did he deserve to die?"
					]
				],
				"ask": "Did Iron Fang deserve to die?",
				"options": [
					{
						"id": "truth",
						"label": "Tell him the truth",
						"desc": "Tell him all of it: the Blood Moon's stones, the venom, Yue Ling tied up for refusing to pour it, and that he never poured it himself. He loses the father he was proud of and gets the real one, who is heavier to carry.",
						"log": "Told Fang Hu the truth at Longmen: the venom his father took, and the venom he never poured.",
						"then": "truth",
						"after": [
							[
								"Lin Feng",
								"It is true. He took their stones and their venom, and he tied Yue Ling to a post because she would not pour it for him. And all the while she was tied there, he never once poured it himself.",
								"nod"
							],
							[
								"Yue Ling",
								"Some nights he sat by the water butt with the gourd in his hands and said nothing. I think he wanted somebody to stop him."
							],
							[
								"Lin Feng",
								"Did he deserve to die? No. He deserved a gate that opened when he was twelve. But I would fight him again tomorrow to free her, and I am sorry for both."
							],
							[
								"Fang Hu",
								"...That is worse than the old man's joke. And better. Let me sit here a while."
							]
						]
					},
					{
						"id": "lie",
						"label": "Tell him his father was brave",
						"desc": "Tell him the old rat is lying: his father took no coin from the Blood Moon and died bravely, fighting for his men. He keeps a father to be proud of, built on your word. If he ever learns otherwise, he learns you lied too.",
						"log": "Told Fang Hu at Longmen that the old bandit lied, and that his father died brave and clean.",
						"then": "lie",
						"after": [
							[
								"Lin Feng",
								"The old man is lying. Your father never took a coin from the Blood Moon. He fought me like a tiger for his men, and he died as he lived."
							],
							[
								"Narrator",
								"Yue Ling turns and looks at the river for a long time. She does not say anything at all."
							],
							[
								"Fang Hu",
								"I knew it. I knew it. Thank you, Lin Feng.",
								"bow"
							],
							[
								"Narrator",
								"He gets up off the bollard lighter than he sat down, and the gauntlet hangs at his side like something to be proud of."
							]
						]
					}
				]
			},
			"spared": {
				"lines": [
					[
						"Narrator",
						"In a flooded warehouse a gang of river-rats is passing bales out of a window into a stolen sampan. The one giving orders wears an iron gauntlet and no mask. It is Young Fang, whom Lin Feng spared in the lanes of Qingshi."
					],
					[
						"Fang Hu",
						"Sect boy. Of course. The whole world is flooding, and you still turn up wherever I am working."
					],
					[
						"Fang Hu",
						"Black Eel pays by the bale and asks no questions. You let me go in Qingshi, so I went. This is where the road went."
					],
					[
						"Yue Ling",
						"Every bale in that boat belongs to somebody the flood has already robbed, Hu."
					],
					[
						"Fang Hu",
						"Everybody was robbed by somebody. My father was honest for twelve years, and they still sent him down the steps."
					],
					[
						"Narrator",
						"Along the quay the magistrate's men are going from warehouse to warehouse with chains. Up at the harbour office, Harbourmistress Jiang is counting her oarsmen and coming up short."
					]
				],
				"ask": "What will you do with Young Fang?",
				"options": [
					{
						"id": "offer",
						"label": "Vouch for him at the harbour",
						"desc": "Put your own name behind him with Harbourmistress Jiang for an honest place on her ferries; it takes a name the river respects. Black Eel loses his best hand, and if Young Fang steals again, it is your word Longmen will remember.",
						"log": "Vouched for Young Fang to Harbourmistress Jiang, and he left Black Eel's rats for an honest oar.",
						"then": "ferryman",
						"need": [
							[
								"renown",
								200
							]
						],
						"after": [
							[
								"Harbourmistress Jiang Yao",
								"A river-rat. On my ferries. On your word. ...Very well, Sovereign. Your word has held up a sky. It can hold up one boy."
							],
							[
								"Harbourmistress Jiang Yao",
								"Listen to me, Fang. A ferry is a promise. People get on at one bank and trust you that the other bank is still there. Be the other bank."
							],
							[
								"Fang Hu",
								"...I have never had work that did not end in running."
							],
							[
								"Harbourmistress Jiang Yao",
								"This one ends in rowing. Boatwright Gao will show you which end of the oar goes in the water."
							]
						]
					},
					{
						"id": "turn",
						"label": "Turn him in",
						"desc": "Take him by the collar to the magistrate's men on the quay. The warehouses get their bales back and Longmen has one thief fewer, and he goes to a cell knowing you spared him once only to hand him over later.",
						"log": "Turned Young Fang over to the magistrate's men at Longmen, though Lin Feng had spared him in Qingshi.",
						"then": "jailed",
						"after": [
							[
								"Fang Hu",
								"You spared me in Qingshi so you could do this here? You could have saved us both the walk.",
								"shake"
							],
							[
								"Lin Feng",
								"In Qingshi I hoped you would choose another road. You chose this one, and other people are paying for it."
							],
							[
								"Narrator",
								"The magistrate's men lead him up the quay in chains. He does not look back once, which is worse than if he had."
							]
						]
					}
				]
			},
			"jailed": {
				"lines": [
					[
						"Narrator",
						"On the roof of a drowned warehouse a young man with an iron gauntlet is directing river-rats like a general, a broken shackle still on one ankle. It is Young Fang, whom Lin Feng handed to the elders of Qingshi."
					],
					[
						"Fang Hu",
						"The magistrate's jail had a very old lock and a very old guard. I left them both asleep."
					],
					[
						"Fang Hu",
						"Black Eel wears a magistrate's hat. I wore a magistrate's chains. Now I run his rats. Everything floats, sect boy. Even a bandit's son."
					],
					[
						"Yue Ling",
						"Hu, come down. Every time you run, the next cell gets smaller."
					],
					[
						"Fang Hu",
						"Somebody robbed my father at the top of your steps, and nobody ever gave him anything back. Come on, then. Let us see if you can catch me twice."
					]
				],
				"ask": "Young Fang will not come quietly.",
				"options": [
					{
						"id": "fight",
						"label": "Fight Young Fang again",
						"desc": "Fight him on the warehouse roofs above the flood. You will beat him and scatter his rats, but the river here is wide and fast and full of boats, and he knows every one of them better than you do.",
						"log": "Beat Young Fang on the warehouse roofs of Longmen, and watched him escape down the flood once more.",
						"then": "foe",
						"battle": [
							[
								"young_fang",
								43
							]
						],
						"after": [
							[
								"Narrator",
								"Lin Feng's last blow knocks him off the roof. Young Fang hits the water, comes up beside a passing sampan, and is gone downstream before anyone can throw a rope."
							],
							[
								"Fang Hu",
								"Missed me again, sect boy! Next time I come to you, somewhere you cannot leave!",
								"wave"
							],
							[
								"Yue Ling",
								"He means the village, Lin Feng."
							]
						]
					}
				]
			}
		}
	},
	"s_f_hu4": {
		"n": "The Iron Gauntlet",
		"by": {
			"truth": {
				"lines": [
					[
						"Narrator",
						"In the lane below Granny Wen's house Fang Hu is waiting with a pack on his back, his father's gauntlet freshly oiled."
					],
					[
						"Fang Hu",
						"Nie came to me three nights ago, in my father's voice. It told me about the stones and the gourd of venom, and that you killed him, and that I should hate you for it."
					],
					[
						"Fang Hu",
						"I said: I know. Lin Feng told me himself, on a quay at Longmen, the spring the river ran backwards. After that it had nothing left to say."
					],
					[
						"Fang Hu",
						"Before I came I went up to the bamboo and cut all of it into his stone. The steps, the tooth, the venom, the post by the water butt, and the gourd he never poured. It is a very crowded stone."
					],
					[
						"Yue Ling",
						"Then he is remembered whole. That is more than most people get.",
						"nod"
					],
					[
						"Fang Hu",
						"Let me come to the Wheel. Not for him, and not for you. I know what he was. I would like to find out what I am."
					]
				],
				"ask": "Fang Hu asks to stand with you at the Wheel.",
				"options": [
					{
						"id": "together",
						"label": "Fight together",
						"desc": "Take him with you to the Wheel of the Six Paths to stand against Nie the Unpaid. He goes knowing the whole truth about his father and about you, and if the shadow wins, it will take him along with everyone else.",
						"log": "Took Fang Hu to the Wheel to fight Nie, knowing the whole truth about his father and about Lin Feng.",
						"then": "ally",
						"after": [
							[
								"Fang Hu",
								"When it is over, come up to the bamboo with me and read the stone. You are the only one left who can tell me if I got it right."
							],
							[
								"Lin Feng",
								"I will. And I will sweep the leaves off it while I am there.",
								"nod"
							],
							[
								"Narrator",
								"Fang Hu flexes his father's gauntlet, and for the first time it looks as if it belongs to his hand."
							]
						]
					}
				]
			},
			"ferryman": {
				"lines": [
					[
						"Narrator",
						"Fang Hu has come up from Longmen in a harbour coat that smells of river, an oar over one shoulder and his father's gauntlet on his hand."
					],
					[
						"Fang Hu",
						"Harbourmistress Jiang gave me three days' leave and a lecture. She says a ferryman who misses his crossing had better have a good reason. I told her I had the best one on the river."
					],
					[
						"Fang Hu",
						"Nie came to me on the night ferry, in my father's voice, out of the black water. It said you spared me to own me, and vouched for me to chain me to an oar."
					],
					[
						"Fang Hu",
						"I told it I have not stolen so much as a fish since you put your name behind me, and nobody owns a ferryman but the river. It did not like that."
					],
					[
						"Yue Ling",
						"The boy who brought me rice. Now he brings people across rivers."
					],
					[
						"Fang Hu",
						"So let me take you across this one. You got me on at one bank. I will see you to the other.",
						"offer"
					]
				],
				"ask": "Fang Hu offers to see you to the other bank.",
				"options": [
					{
						"id": "together",
						"label": "Fight together",
						"desc": "Take him to the Wheel of the Six Paths to stand against Nie with you. He gives up his wages and risks his neck on your word, the same word that got him his oar, and if he falls there, Longmen loses a ferryman.",
						"log": "Took Fang Hu the ferryman to fight Nie at the Wheel, on the word that had once won him his oar.",
						"then": "ally",
						"after": [
							[
								"Fang Hu",
								"Harbourmistress Jiang says if I get killed she will dock it from my wages."
							],
							[
								"Lin Feng",
								"Then we had better both come back. I still owe her a ferry fare."
							],
							[
								"Narrator",
								"Fang Hu laughs, a big laugh from the whole chest, and Lin Feng thinks he has heard it somewhere before, in the bamboo, a long time ago."
							]
						]
					}
				]
			},
			"lie": {
				"lines": [
					[
						"Narrator",
						"Fang Hu is waiting in the middle of the lane with his father's gauntlet already raised. He has the face of someone who has not slept in days."
					],
					[
						"Fang Hu",
						"Nie came to me in my father's voice. It told me about the stones, the gourd of venom, the healer tied to the post by the water butt. Every word the old rat said at Longmen."
					],
					[
						"Fang Hu",
						"Then it told me the worst part. That you stood on that quay, looked me in the eye and lied to me."
					],
					[
						"Yue Ling",
						"I was there too, Hu. I stood by and let him say it. If there is a debt, half of it is mine.",
						"grieve"
					],
					[
						"Fang Hu",
						"I carried that lie like a lantern. I told it in every inn on the river. I told it to his grave. Draw your sword, Lin Feng. You owe me that much truth.",
						"point"
					]
				],
				"ask": "Fang Hu will have his answer with the gauntlet.",
				"options": [
					{
						"id": "face",
						"label": "Face him",
						"desc": "Fight him in the lane, because he will not hear a word until he has hit something. He is stronger now than his father ever was, and angrier, and whatever you say afterwards you will be saying to a man you have just beaten.",
						"log": "Fought Fang Hu in a lane of Qingshi after Nie's whisper told him that Lin Feng had lied.",
						"then": "",
						"battle": [
							[
								"young_fang",
								55
							]
						],
						"follow": {
							"lines": [
								[
									"Narrator",
									"Fang Hu ends on his knees in the dust, the gauntlet cracked across the knuckles, breathing like a bellows. He does not get up, and he does not look away."
								],
								[
									"Fang Hu",
									"Well? You owe me one true thing. Why did you lie?"
								]
							],
							"ask": "What do you owe Fang Hu?",
							"options": [
								{
									"id": "why",
									"label": "Tell him why you lied",
									"desc": "Tell him the truth about the lie: that you meant to spare him shame, that it was not yours to choose for him, and the half of the story Nie left out. He may never forgive you, but he will have all of it.",
									"log": "Told Fang Hu why Lin Feng had lied about his father, and he came to the Wheel to fight beside him.",
									"then": "ally",
									"after": [
										[
											"Lin Feng",
											"Because you stood on that quay with your whole life ahead of you, and I did not want the last thing he gave you to be shame. That was yours to carry or put down, not mine to choose. I was wrong.",
											"bow"
										],
										[
											"Lin Feng",
											"And here is the half Nie did not tell you. He had that gourd for days and days, and he never poured a drop of it."
										],
										[
											"Fang Hu",
											"...It did not tell me that. It only keeps the debts."
										],
										[
											"Fang Hu",
											"I will come to the Wheel. Not because I forgive you. Because I want to see that thing's face when it loses."
										]
									]
								},
								{
									"id": "walk",
									"label": "Let him walk away",
									"desc": "Offer no reasons and no defence, and let him go. He goes his own way with the whole hard truth about his father and none of yours. He will not fight for Nie, but he will not stand beside you at the Wheel either.",
									"log": "Gave Fang Hu no reasons for the lie, and let him go his own way alone.",
									"then": "parted",
									"after": [
										[
											"Lin Feng",
											"Anything I say now will sound like another excuse. Go, Hu. I am sorry."
										],
										[
											"Fang Hu",
											"So am I."
										],
										[
											"Narrator",
											"He stands looking down the east road, where the Needle General once stood, with the gauntlet hanging at his side like something he has not yet decided whether to keep."
										]
									]
								}
							]
						}
					}
				]
			},
			"foe": {
				"lines": [
					[
						"Narrator",
						"Smoke rises over the east end of Qingshi. Young Fang has come back with forty crossbows, as many as his father ever had, and they hold the road where the Needle General once stood."
					],
					[
						"Fang Hu",
						"I told you, sect boy. Somewhere you cannot leave. The elders here tied me up with their ox rope and handed me to a magistrate. Now they can watch me empty their granary."
					],
					[
						"Fang Hu",
						"After Longmen a voice found me in the reeds, in my father's voice. It said every debt is owed. It told me where to find men, and where to find you."
					],
					[
						"Yue Ling",
						"That voice is not your father, Hu. It is every debt nobody ever paid, wearing his face. It does not care what becomes of you."
					],
					[
						"Lin Feng",
						"Let the village be. You came here for me. You always did."
					]
				],
				"ask": "Young Fang has come for what he says he is owed.",
				"options": [
					{
						"id": "face",
						"label": "Face him",
						"desc": "Fight him at the east end of the village, with his crossbows on the ridge and the villagers behind their doors. You will break his band. What becomes of him after, you will have to decide with all of Qingshi watching.",
						"log": "Fought Young Fang and his forty crossbows at the east end of Qingshi, and broke his band.",
						"then": "",
						"battle": [
							[
								"young_fang",
								55
							]
						],
						"follow": {
							"lines": [
								[
									"Narrator",
									"His crossbowmen scatter into the paddies. Young Fang lies in the road with his father's gauntlet split open, still reaching for a knife."
								],
								[
									"Fang Hu",
									"Do it, then. Like you did him. Then Nie can have both of us and call it even."
								]
							],
							"ask": "What becomes of Young Fang?",
							"options": [
								{
									"id": "spare",
									"label": "Spare him",
									"desc": "Take the knife out of his hand and spare him one last time. Qingshi will want him gone or worse, and he must come back and mend what he broke under the eyes of everyone he frightened. Nie loses the blade it sharpened.",
									"log": "Spared Young Fang one last time; he turned his back on Nie and swore to mend what his bandits broke.",
									"then": "redeemed",
									"after": [
										[
											"Lin Feng",
											"No. The feud ends here, and you are still in it. Get up, Hu. There is a fence to mend, and you broke it.",
											"offer"
										],
										[
											"Fang Hu",
											"...You never called me by my name before. Only she ever did."
										],
										[
											"Narrator",
											"He sits in the road a long time. Then he takes off the split gauntlet, sets it down in the dust, and picks up a broken fence-post instead."
										],
										[
											"Fang Hu",
											"The fence can wait until after the Wheel. That thing used my father's voice on me. I want to be there when it stops talking."
										]
									]
								},
								{
									"id": "end",
									"label": "End it",
									"desc": "Strike the last blow and end the feud the way it began, with a body in the dust. Qingshi will never have to fear him again, and the boy who once brought Yue Ling rice goes under the bamboo beside his father.",
									"log": "Ended Young Fang at the east end of Qingshi, and buried him under the bamboo beside his father.",
									"then": "fallen",
									"after": [
										[
											"Narrator",
											"Lin Feng does it cleanly, which is the only mercy left. Young Fang dies looking up at the sky, his hand still in his father's gauntlet."
										],
										[
											"Yue Ling",
											"He brought me rice. Lin Feng, he brought me rice.",
											"grieve"
										],
										[
											"Narrator",
											"They carry him up to the bamboo and bury him beside Iron Fang. Two graves, father and son, and Lin Feng sweeps the leaves off both before he goes."
										]
									]
								}
							]
						}
					}
				]
			},
			"jailed": {
				"lines": [
					[
						"Narrator",
						"Smoke rises over the east end of Qingshi. Young Fang has come with forty crossbows, as many as his father ever had, and there is still a magistrate's shackle on one wrist."
					],
					[
						"Fang Hu",
						"You spared me in Qingshi and handed me over at Longmen. Then a voice came through the wall of my cell, in my father's voice, and the lock fell open."
					],
					[
						"Fang Hu",
						"It said you keep accounts, sect boy. So here is mine. This is the village you grew up in. Now you will know what it is like when somebody comes for your home."
					],
					[
						"Yue Ling",
						"That voice is not your father, Hu. It is every debt nobody ever paid, wearing his face. It does not care what becomes of you."
					],
					[
						"Lin Feng",
						"Leave the village out of it. You came for me. Here I am."
					]
				],
				"ask": "Young Fang has come for what he says he is owed.",
				"options": [
					{
						"id": "face",
						"label": "Face him",
						"desc": "Fight him at the east end of the village, with his crossbows on the ridge and the villagers behind their doors. You will break his band. What becomes of him after, you will have to decide with all of Qingshi watching.",
						"log": "Fought Young Fang and his forty crossbows at the east end of Qingshi, and broke his band.",
						"then": "",
						"battle": [
							[
								"young_fang",
								55
							]
						],
						"follow": {
							"lines": [
								[
									"Narrator",
									"His crossbowmen scatter into the paddies. Young Fang lies in the road with his father's gauntlet split open, still reaching for a knife."
								],
								[
									"Fang Hu",
									"Do it, then. Like you did him. Then Nie can have both of us and call it even."
								]
							],
							"ask": "What becomes of Young Fang?",
							"options": [
								{
									"id": "spare",
									"label": "Spare him",
									"desc": "Take the knife out of his hand and spare him one last time. Qingshi will want him gone or worse, and he must come back and mend what he broke under the eyes of everyone he frightened. Nie loses the blade it sharpened.",
									"log": "Spared Young Fang one last time; he turned his back on Nie and swore to mend what his bandits broke.",
									"then": "redeemed",
									"after": [
										[
											"Lin Feng",
											"No. I sent you to a cell once, and it sent you back worse. Get up, Hu. There is a fence to mend, and you broke it.",
											"offer"
										],
										[
											"Fang Hu",
											"...You never called me by my name before. Only she ever did."
										],
										[
											"Narrator",
											"He sits in the road a long time. Then he takes off the split gauntlet, sets it down in the dust, and picks up a broken fence-post instead."
										],
										[
											"Fang Hu",
											"The fence can wait until after the Wheel. That thing used my father's voice on me. I want to be there when it stops talking."
										]
									]
								},
								{
									"id": "end",
									"label": "End it",
									"desc": "Strike the last blow and end the feud the way it began, with a body in the dust. Qingshi will never have to fear him again, and the boy who once brought Yue Ling rice goes under the bamboo beside his father.",
									"log": "Ended Young Fang at the east end of Qingshi, and buried him under the bamboo beside his father.",
									"then": "fallen",
									"after": [
										[
											"Narrator",
											"Lin Feng does it cleanly, which is the only mercy left. Young Fang dies looking up at the sky, his hand still in his father's gauntlet."
										],
										[
											"Yue Ling",
											"He brought me rice. Lin Feng, he brought me rice.",
											"grieve"
										],
										[
											"Narrator",
											"They carry him up to the bamboo and bury him beside Iron Fang. Two graves, father and son, and Lin Feng sweeps the leaves off both before he goes."
										]
									]
								}
							]
						}
					}
				]
			}
		}
	},
	"s_f_xu1": {
		"n": "The Moon's Daughter",
		"by": {
			"*": {
				"lines": [
					[
						"Narrator",
						"Behind Xu Mo's throne, past a door sealed with his own blood, is a room the size of a well with one window on the moon. On its floor sits a girl as pale as paper, a crimson streak in her black hair, silver chains on both wrists bolted to the wall."
					],
					[
						"Xu Lan",
						"So he is dead. I felt the moon let go of him. You must be the bearer. He talked about you the way farmers talk about rain: always coming, never here yet."
					],
					[
						"Lin Feng",
						"Who are you?"
					],
					[
						"Xu Lan",
						"Xu Lan, his daughter. Nineteen years in this room. After every hunt he came in, sat where you are standing and poured the moon's blood into me, all the red the hunt had left in him. Silver keeps it in. So did I."
					],
					[
						"Yue Ling",
						"Lin Feng, there are bells on the lower stairs. The sect's elders are coming up, and they have sworn to burn out the Blood Moon to the last drop, and every bloodline that carries it."
					],
					[
						"Xu Lan",
						"Then decide quickly, bearer. They will not ask what I have done. Only whose I am."
					]
				],
				"ask": "What will you do with Xu Mo's daughter?",
				"options": [
					{
						"id": "surrender",
						"label": "Hand her to the elders",
						"desc": "Leave her in her chains and give her up to the sect's elders. Your word that she has harmed nobody keeps her from the fire, but she goes into a cell under the Hall, in silver, for as long as the moon's blood is in her, and she will know who put her there.",
						"log": "Gave Xu Mo's daughter up to the sect's elders, who kept her in silver under the Hall.",
						"then": "prisoner",
						"after": [
							[
								"Lin Feng",
								"She has harmed nobody. Hold her if you must, elders. Do not burn her."
							],
							[
								"Narrator",
								"The elders in white, a brazier carried up the stairs between two disciples, look from the sweeper who killed Xu Mo to the chained girl for a long time. Then they send the brazier back down and bring out a chain of their own."
							],
							[
								"Xu Lan",
								"Nineteen years in my father's silver, and now in yours. A new owner, bearer. I hope the window is bigger."
							],
							[
								"Yue Ling",
								"It was that or the brazier, Lin Feng. I keep telling myself so."
							]
						]
					},
					{
						"id": "free",
						"label": "Break her chains",
						"desc": "Cut her chains and show her the servants' stair before the elders arrive. She walks out free into a world that would burn her if it heard her name, and one day the sect will learn that a demon lord's blood walked past the sweeper who killed him.",
						"log": "Cut Xu Lan's chains and showed her the servants' stair before the elders came.",
						"then": "fugitive",
						"after": [
							[
								"Narrator",
								"The silver parts at one stroke of the Heaven-Cleaving Sword. The cuff on her left wrist stays where it is; there is no time to cut it, and the bells are already on the stair."
							],
							[
								"Xu Lan",
								"Nobody has ever opened a door for me. I do not know which way the world is."
							],
							[
								"Lin Feng",
								"Down, away from the bells. And do not tell anyone whose daughter you are.",
								"point"
							],
							[
								"Xu Lan",
								"I will not tell anyone anything. I may not even tell myself."
							]
						]
					},
					{
						"id": "vouch",
						"label": "Vouch for her to the Elder",
						"desc": "Stand between her and the elders and give your name for hers before Elder Qing Xuan. The renown of the sweeper who killed Xu Mo buys her a place at the sect as the Elder's ward, under watch, a silver cuff on her wrist; if she ever turns, it is on you.",
						"log": "Vouched for Xu Lan before Elder Qing Xuan, who took her as his ward, under watch.",
						"then": "ward",
						"need": [
							[
								"renown",
								30
							]
						],
						"after": [
							[
								"Elder Qing Xuan",
								"A demon lord's daughter, on the word of a sweeper. The others will say I have gone soft in my old age. They have been saying it for sixty years.",
								"think"
							],
							[
								"Elder Qing Xuan",
								"She will live at the sect under my eye, with one cuff of silver until the moon's blood is out of her. If she runs, Lin Feng, you will be the one I send after her."
							],
							[
								"Xu Lan",
								"A cuff instead of a wall. That is more than my father ever gave me.",
								"bow"
							]
						]
					}
				]
			}
		}
	},
	"s_f_xu2": {
		"n": "Her Father's Echo",
		"by": {
			"prisoner": {
				"lines": [
					[
						"Narrator",
						"Past the shattered reflections a girl kneels at the edge of the Mirror Lake, a length of broken silver hanging from one wrist, talking to the water as if it were a door that might open."
					],
					[
						"Xu Lan",
						"Bearer. You handed me to your elders, and they kept me in silver under their Hall. The night the sky cracked, the silver cracked with it. Everybody was looking up. Nobody was looking at me."
					],
					[
						"Xu Lan",
						"I have been a beggar since, and a thief, and a girl in a ditch. Everyone who learned my name reached for a sword. Then I heard that the Mirror Lake keeps an echo of everyone who ever crossed it. It keeps his."
					],
					[
						"Lin Feng",
						"Your father's echo. What do you want with it?"
					],
					[
						"Xu Lan",
						"What any daughter wants from her father: to be taught. He poured the moon's blood into me and never once showed me how to pour it out. If the world will only ever see his blood in me, I may as well learn to use it."
					],
					[
						"Yue Ling",
						"Lin Feng, look at the water round her knees. It is turning red.",
						"point"
					]
				],
				"ask": "Xu Lan wants her father's echo to teach her",
				"options": [
					{
						"id": "stop",
						"label": "Stop her",
						"desc": "Stand between her and the lake and fight her before the echo can teach her anything. Beaten, she will flee untaught but not unmarked, and the sect will hunt her as a demon lord's heir; she will remember who stood in her way.",
						"log": "Fought Xu Lan on the shore before her father's echo could teach her; she fled, and the sect hunts her.",
						"then": "hunted",
						"battle": [
							[
								"xu_lan",
								18
							]
						],
						"after": [
							[
								"Narrator",
								"Beaten, she goes into the reeds like a startled heron, and the red drains slowly out of the water where she knelt."
							],
							[
								"Xu Lan",
								"You took my father, bearer, and now you take his voice. Your sect will come after me again. Tell them to bring more than you."
							],
							[
								"Yue Ling",
								"She fights like someone who has only ever been fought. I wish somebody had taught her anything else."
							]
						]
					},
					{
						"id": "let",
						"label": "Let her speak to him",
						"desc": "Stand aside and let her wade out to her father's echo before you face it. He will teach her what the moon's blood can do, and she will leave the lake with his arts in her hands and his reasons in her ears; the sect will not thank you for it.",
						"log": "Let Xu Lan wade out to her father's echo, and she came back from the water with his arts.",
						"then": "heir",
						"after": [
							[
								"Narrator",
								"She wades out until the lake is at her chin, and somewhere under the surface a quiet voice begins to speak. When she comes back the streak in her hair is redder, and she will not look at Lin Feng."
							],
							[
								"Xu Lan",
								"He said he was sorry. He said it nineteen times, once for each of them. Then he showed me how the moon is poured."
							],
							[
								"Xu Lan",
								"He said you would come and strike him, and that he would thank you for it. Go on, then, bearer. I have what I came for."
							]
						]
					}
				]
			},
			"fugitive": {
				"lines": [
					[
						"Narrator",
						"In a reed hut on the shore lives a young woman who mends nets: a straw hat pulled low, a silver cuff on one wrist, and a crimson streak in her hair that she has tried, without much luck, to dye black."
					],
					[
						"Xu Lan",
						"Bearer. You cut my chains in the Blood Moon Palace and told me not to say whose daughter I was. I have not said it once. Here I am the girl who mends nets, and the fishermen pay me in fish."
					],
					[
						"Xu Lan",
						"Then the lake began to talk in his voice. Every night, under the boards of my hut: I believed him, I believed him. The fish will not bite. I cannot sleep."
					],
					[
						"Lin Feng",
						"You want him silenced."
					],
					[
						"Xu Lan",
						"I want to do it myself. Once, with my own hand. Let him see who struck him, and know that I am nothing of his."
					],
					[
						"Yue Ling",
						"It is still your father out there, Xu Lan, or what the lake kept of him. Whatever you strike, you will carry home."
					]
				],
				"ask": "Xu Lan wants to strike her father's echo herself",
				"options": [
					{
						"id": "first",
						"label": "Let her strike first",
						"desc": "Take her with you when you face the echo and let her strike the first blow before your sword does the rest. She will have silenced him with her own hand, which may free her of him or bind her in a new way; the lake will remember her face beside his.",
						"log": "Promised Xu Lan the first blow against her father's echo, to strike with her own hand.",
						"then": "unbound",
						"after": [
							[
								"Xu Lan",
								"Thank you. When he rises out of the water, do not stop me. And do not let me stop myself."
							],
							[
								"Narrator",
								"She takes the gutting knife from her belt and sits on the step of the hut to sharpen it, slowly, not once looking at the lake."
							],
							[
								"Yue Ling",
								"I will stand beside her when it comes. Somebody ought to."
							]
						]
					},
					{
						"id": "for",
						"label": "Do it for her",
						"desc": "Tell her to stay ashore and strike the echo for her yourself. She keeps her hands clean of her father, even of what the lake kept of him, and may sleep again under her own roof; but once more his fate is settled by somebody else's hand, not hers.",
						"log": "Kept Xu Lan ashore and promised to silence her father's echo for her.",
						"then": "sheltered",
						"after": [
							[
								"Xu Lan",
								"...You are right. If I struck him once I would want to strike him again, and again, until I was him."
							],
							[
								"Xu Lan",
								"Go, then. I will be here mending nets. When the lake stops talking, I will know."
							],
							[
								"Yue Ling",
								"She will be listening to the water all night, Lin Feng. Let us not keep her waiting."
							]
						]
					}
				]
			},
			"ward": {
				"lines": [
					[
						"Narrator",
						"On the shore, past the last of the shattered reflections, Xu Lan is waiting with a sect sword across her knees, the silver cuff bright on her wrist."
					],
					[
						"Xu Lan",
						"Bearer. You vouched for me, and the Elder has kept me at the sect under his eye ever since. This morning he told me who my father hunted for: the Emperor, his own master. Then he sent me after you, to face what the lake kept of him. He calls it my test."
					],
					[
						"Xu Lan",
						"The disciples step off the path when I pass. The kitchen gives me my rice in a bowl nobody else uses. I am very tired of being watched, bearer."
					],
					[
						"Lin Feng",
						"Then what do you want?"
					],
					[
						"Xu Lan",
						"To go alone. If I face him with the twentieth bearer at my side, they will all say you did it for me. Let me go first, by myself. Or come with me, if you do not trust the Elder's judgement. Or mine."
					],
					[
						"Yue Ling",
						"The echoes here bite, Lin Feng. But so does being watched every hour of every day."
					]
				],
				"ask": "Xu Lan asks to face her father's echo alone",
				"options": [
					{
						"id": "trust",
						"label": "Let her go alone",
						"desc": "Let her go out to her father's echo by herself, as the Elder's test asks, while you deal with the rest of the lake. If she comes back it will be on her own feet, and the sect will have to believe it; if the echo turns her, nobody will be there to stop it.",
						"log": "Let Xu Lan face her father's echo alone, as the Elder's test asked.",
						"then": "trusted",
						"after": [
							[
								"Xu Lan",
								"Thank you. That is the first time anyone has let me out of their sight on purpose.",
								"bow"
							],
							[
								"Narrator",
								"She walks out along the broken glass of the shore, a small red figure against the silver water, and does not look back."
							],
							[
								"Yue Ling",
								"If she does not come back, the Elder will ask you why. I would rather she came back."
							]
						]
					},
					{
						"id": "guard",
						"label": "Go with her",
						"desc": "Refuse to let her face the echo alone, and walk out beside her. She will be safe from whatever the lake kept of him, and the sect will say the bearer held her hand; she will be grateful, and she will not forget that you did not trust her.",
						"log": "Went with Xu Lan to face her father's echo, and did not leave her side.",
						"then": "guarded",
						"after": [
							[
								"Xu Lan",
								"So the Elder's watch has a second pair of eyes. Very well. Walk on my left. That is the side the cuff is on."
							],
							[
								"Lin Feng",
								"I am not here to watch you. He was a demon lord, and you are nineteen."
							],
							[
								"Yue Ling",
								"Nobody should have to face a father like that alone, Xu Lan. Least of all his daughter."
							]
						]
					}
				]
			}
		}
	},
	"s_f_xu3": {
		"n": "The Shade of Xu Mo",
		"by": {
			"hunted": {
				"lines": [
					[
						"Narrator",
						"In a street of grey walls a living girl walks where no living girl should, a cut silver chain swinging at her wrist. In her hands is one of the Dark Capital's lanterns, and its flame is the colour of an old wound."
					],
					[
						"Xu Lan",
						"You again. At the lake you stood between me and my father's voice, and your sect has hunted me from one end of the land to the other ever since. I have become very hard to kill, bearer. I learned it running from you."
					],
					[
						"Xu Lan",
						"This is his soul-lantern. He came down when the Wheel turned and would not go up: too heavy, the tally says. I am carrying him home to the palace, and under a red moon he will be strong again, and so will I."
					],
					[
						"Lin Feng",
						"He fed nineteen children to the Emperor. His hunters ran my mother and father into their graves in the Maple Gorge."
					],
					[
						"Xu Lan",
						"And the sects have burned every Blood Moon acolyte they could find, and their children, for being his. Nobody ever asked me which I would rather be. So I chose."
					],
					[
						"Yue Ling",
						"Lin Feng, the lanterns along the street are turning red, one after another. She is pouring the moon into all of them."
					]
				],
				"ask": "Xu Lan is carrying her father's shade out of Youdu",
				"options": [
					{
						"id": "stop",
						"label": "Stop her",
						"desc": "Fight her in the street before she can reach the roots with her father's lantern. She knows the moon's blood now, and even beaten she may slip away with his soul-lantern to the palace in the north-east; from then on she will be your enemy.",
						"log": "Fought Xu Lan in the streets of Youdu, and she escaped up the roots with her father's soul-lantern.",
						"then": "foe",
						"battle": [
							[
								"xu_lan",
								47
							]
						],
						"after": [
							[
								"Narrator",
								"Beaten, she pours the moon's blood into every lantern in the street at once, and in the red glare nobody can see a thing. When it fades she is gone, and so is Xu Mo's lantern."
							],
							[
								"Magistrate Ming Yi",
								"A shade taken off the roll by the living, in my own street. There is no form for that. I shall have to write one."
							],
							[
								"Yue Ling",
								"She will take him north-east, to the palace. Where else would a daughter take her father home?"
							]
						]
					}
				]
			},
			"heir": {
				"lines": [
					[
						"Narrator",
						"At the end of a street of grey walls Lin Feng finds a living girl in a dark red robe sewn with moons, lifting a lantern down from its hook as gently as if it were asleep."
					],
					[
						"Xu Lan",
						"Bearer. At the lake you let me speak to him, and he taught me how the moon is poured. Then you struck him. I have had a long time to decide which of those to thank you for."
					],
					[
						"Xu Lan",
						"This is his soul-lantern. He came down when the Wheel turned and would not go up: too heavy, the tally says. I am carrying him home to the palace, and under a red moon he will be my father again."
					],
					[
						"Lin Feng",
						"He fed nineteen children to the Emperor. His hunters ran my mother and father into their graves in the Maple Gorge."
					],
					[
						"Xu Lan",
						"He wept when he told me. He believed one more root would end the harvest, and the harvest did end. Now the sects burn his acolytes and their children for being his. Somebody has to be the Blood Moon for them."
					],
					[
						"Yue Ling",
						"Lin Feng, every lantern on this street is turning red.",
						"point"
					]
				],
				"ask": "Xu Lan is carrying her father's shade out of Youdu",
				"options": [
					{
						"id": "stop",
						"label": "Stop her",
						"desc": "Fight her in the street before she can reach the roots with her father's lantern. She has his arts now, and even beaten she may slip away with his soul-lantern to the palace in the north-east; from then on she will be your enemy.",
						"log": "Fought Xu Lan in the streets of Youdu, and she escaped up the roots with her father's soul-lantern.",
						"then": "foe",
						"battle": [
							[
								"xu_lan",
								47
							]
						],
						"after": [
							[
								"Narrator",
								"Beaten, she flings the moon's blood into every lantern in the street, and in the red glare nobody can see a thing. When it fades she is gone up the roots, and Xu Mo's lantern with her."
							],
							[
								"Magistrate Ming Yi",
								"Removed from the roll by next of kin, without a form, in the middle of my street. I shall have to invent a form. I shall enjoy that less than you would think."
							],
							[
								"Yue Ling",
								"He taught her well at the lake. I wish he had taught her anything else."
							]
						]
					}
				]
			},
			"unbound": {
				"lines": [
					[
						"Narrator",
						"Old Bo lights a lantern every night for each shade in the Dark Capital still waiting to go up. One of them burns a sullen red. Xu Lan stands before it, the silver cuff on her wrist, and beside her waits Magistrate Ming Yi with a bamboo tally."
					],
					[
						"Xu Lan",
						"Bearer. At the lake you let me strike the first blow, and I did, and he thanked me for it. I have not been able to hate him properly since. Then a paper horse came to my hut with the Magistrate's summons."
					],
					[
						"Magistrate Ming Yi",
						"Xu Mo, once a demon lord. He came down when the Wheel turned and would not go up: too heavy, says the tally. When a shade will not choose, the roll asks the family, and Miss Xu is all the family he has."
					],
					[
						"Xu Lan",
						"He can go up to the Wheel, drink Meng Po's soup and be born again remembering nothing. Or he can go to King Yama's court and answer for the nineteen first. The roll says it is mine to say. I want you to say it."
					],
					[
						"Lin Feng",
						"Why me?"
					],
					[
						"Xu Lan",
						"Because he hunted you as he hunted them. And the shades say his hunters drove a man and a woman into the Maple Gorge, and that they had a son. If anyone alive has the right to say, it is their son."
					],
					[
						"Yue Ling",
						"She is not asking you to choose for her, Lin Feng. She is asking you to carry it with her."
					]
				],
				"ask": "What should become of Xu Mo's shade?",
				"options": [
					{
						"id": "forgive",
						"label": "Let him go to the Wheel",
						"desc": "Tell her to let him go up to the Wheel, drink Meng Po's soup and be born again remembering nothing. The nineteen, and your parents, will never hear him answer for them; but she will be free of him, and somewhere a child will be born without his weight.",
						"log": "Told Xu Lan to let her father go to the Wheel, and she sent him up to be born remembering nothing.",
						"then": "forgiving",
						"after": [
							[
								"Narrator",
								"Xu Lan opens the lantern's little door. The red flame steadies, pales to white and goes up through the cavern roof like a spark from a fire, towards the Wheel."
							],
							[
								"Xu Lan",
								"He did not look back. He did not know to. Somewhere, one day soon, a baby will cry with no idea what it used to be."
							],
							[
								"Magistrate Ming Yi",
								"Tally closed: gone up, forgiven, by the family. The lantern is yours, Miss Xu. The empty ones always go to the family.",
								"offer"
							]
						]
					},
					{
						"id": "judge",
						"label": "Let him be judged",
						"desc": "Tell her to send him to King Yama's court to answer for the nineteen children, and for the two in the Maple Gorge, before he is born again. He will remember every face while Judge Cui writes it down; it is justice, and it will be neither quick nor kind.",
						"log": "Told Xu Lan to send her father to be judged for the nineteen children, and she sent him to King Yama.",
						"then": "just",
						"after": [
							[
								"Narrator",
								"Xu Lan opens the lantern's little door. The red flame wavers, then sets off along the dark street towards the Wheel and the King at its axle, slowly, the way a man walks to a court."
							],
							[
								"Xu Lan",
								"He will remember them all now, and their names too, this time. Judge Cui will see to it. He writes kindly, they say, but he writes everything."
							],
							[
								"Magistrate Ming Yi",
								"Tally closed: sent to judgement, by the family. The lantern is yours, Miss Xu. The empty ones always go to the family.",
								"offer"
							]
						]
					}
				]
			},
			"sheltered": {
				"lines": [
					[
						"Narrator",
						"Old Bo lights a lantern every night for each shade in the Dark Capital still waiting to go up. One of them burns a sullen red. Xu Lan stands before it, the silver cuff on her wrist, and beside her waits Magistrate Ming Yi with a bamboo tally."
					],
					[
						"Xu Lan",
						"Bearer. At the lake you struck him for me, and that night the water was quiet and I slept till noon. I thought it was finished. Then a paper horse came to my hut with the Magistrate's summons."
					],
					[
						"Magistrate Ming Yi",
						"Xu Mo, once a demon lord. He came down when the Wheel turned and would not go up: too heavy, says the tally. When a shade will not choose, the roll asks the family, and Miss Xu is all the family he has."
					],
					[
						"Xu Lan",
						"He can go up to the Wheel, drink Meng Po's soup and be born again remembering nothing. Or he can go to King Yama's court and answer for the nineteen first. The roll says it is mine to say. I want you to say it."
					],
					[
						"Lin Feng",
						"Why me?"
					],
					[
						"Xu Lan",
						"Because he hunted you as he hunted them. And the shades say his hunters drove a man and a woman into the Maple Gorge, and that they had a son. If anyone alive has the right to say, it is their son."
					],
					[
						"Yue Ling",
						"She is not asking you to choose for her, Lin Feng. She is asking you to carry it with her."
					]
				],
				"ask": "What should become of Xu Mo's shade?",
				"options": [
					{
						"id": "forgive",
						"label": "Let him go to the Wheel",
						"desc": "Tell her to let him go up to the Wheel, drink Meng Po's soup and be born again remembering nothing. The nineteen, and your parents, will never hear him answer for them; but she will be free of him, and somewhere a child will be born without his weight.",
						"log": "Told Xu Lan to let her father go to the Wheel, and she sent him up to be born remembering nothing.",
						"then": "forgiving",
						"after": [
							[
								"Narrator",
								"Xu Lan opens the lantern's little door. The red flame steadies, pales to white and goes up through the cavern roof like a spark from a fire, towards the Wheel."
							],
							[
								"Xu Lan",
								"He did not look back. He did not know to. Somewhere, one day soon, a baby will cry with no idea what it used to be."
							],
							[
								"Magistrate Ming Yi",
								"Tally closed: gone up, forgiven, by the family. The lantern is yours, Miss Xu. The empty ones always go to the family.",
								"offer"
							]
						]
					},
					{
						"id": "judge",
						"label": "Let him be judged",
						"desc": "Tell her to send him to King Yama's court to answer for the nineteen children, and for the two in the Maple Gorge, before he is born again. He will remember every face while Judge Cui writes it down; it is justice, and it will be neither quick nor kind.",
						"log": "Told Xu Lan to send her father to be judged for the nineteen children, and she sent him to King Yama.",
						"then": "just",
						"after": [
							[
								"Narrator",
								"Xu Lan opens the lantern's little door. The red flame wavers, then sets off along the dark street towards the Wheel and the King at its axle, slowly, the way a man walks to a court."
							],
							[
								"Xu Lan",
								"He will remember them all now, and their names too, this time. Judge Cui will see to it. He writes kindly, they say, but he writes everything."
							],
							[
								"Magistrate Ming Yi",
								"Tally closed: sent to judgement, by the family. The lantern is yours, Miss Xu. The empty ones always go to the family.",
								"offer"
							]
						]
					}
				]
			},
			"trusted": {
				"lines": [
					[
						"Narrator",
						"Old Bo lights a lantern every night for each shade in the Dark Capital still waiting to go up. One of them burns a sullen red. Xu Lan stands before it, the silver cuff on her wrist, and beside her waits Magistrate Ming Yi with a bamboo tally."
					],
					[
						"Xu Lan",
						"Bearer. At the lake you let me face him alone, and I came back on my own feet. The Elder offered to take off the cuff, and I kept it. Now the Magistrate has sent for me, and the Elder let me come alone."
					],
					[
						"Magistrate Ming Yi",
						"Xu Mo, once a demon lord. He came down when the Wheel turned and would not go up: too heavy, says the tally. When a shade will not choose, the roll asks the family, and Miss Xu is all the family he has."
					],
					[
						"Xu Lan",
						"He can go up to the Wheel, drink Meng Po's soup and be born again remembering nothing. Or he can go to King Yama's court and answer for the nineteen first. The roll says it is mine to say. I want you to say it."
					],
					[
						"Lin Feng",
						"Why me?"
					],
					[
						"Xu Lan",
						"Because he hunted you as he hunted them. And the shades say his hunters drove a man and a woman into the Maple Gorge, and that they had a son. If anyone alive has the right to say, it is their son."
					],
					[
						"Yue Ling",
						"She is not asking you to choose for her, Lin Feng. She is asking you to carry it with her."
					]
				],
				"ask": "What should become of Xu Mo's shade?",
				"options": [
					{
						"id": "forgive",
						"label": "Let him go to the Wheel",
						"desc": "Tell her to let him go up to the Wheel, drink Meng Po's soup and be born again remembering nothing. The nineteen, and your parents, will never hear him answer for them; but she will be free of him, and somewhere a child will be born without his weight.",
						"log": "Told Xu Lan to let her father go to the Wheel, and she sent him up to be born remembering nothing.",
						"then": "forgiving",
						"after": [
							[
								"Narrator",
								"Xu Lan opens the lantern's little door. The red flame steadies, pales to white and goes up through the cavern roof like a spark from a fire, towards the Wheel."
							],
							[
								"Xu Lan",
								"He did not look back. He did not know to. Somewhere, one day soon, a baby will cry with no idea what it used to be."
							],
							[
								"Magistrate Ming Yi",
								"Tally closed: gone up, forgiven, by the family. The lantern is yours, Miss Xu. The empty ones always go to the family.",
								"offer"
							]
						]
					},
					{
						"id": "judge",
						"label": "Let him be judged",
						"desc": "Tell her to send him to King Yama's court to answer for the nineteen children, and for the two in the Maple Gorge, before he is born again. He will remember every face while Judge Cui writes it down; it is justice, and it will be neither quick nor kind.",
						"log": "Told Xu Lan to send her father to be judged for the nineteen children, and she sent him to King Yama.",
						"then": "just",
						"after": [
							[
								"Narrator",
								"Xu Lan opens the lantern's little door. The red flame wavers, then sets off along the dark street towards the Wheel and the King at its axle, slowly, the way a man walks to a court."
							],
							[
								"Xu Lan",
								"He will remember them all now, and their names too, this time. Judge Cui will see to it. He writes kindly, they say, but he writes everything."
							],
							[
								"Magistrate Ming Yi",
								"Tally closed: sent to judgement, by the family. The lantern is yours, Miss Xu. The empty ones always go to the family.",
								"offer"
							]
						]
					}
				]
			},
			"guarded": {
				"lines": [
					[
						"Narrator",
						"Old Bo lights a lantern every night for each shade in the Dark Capital still waiting to go up. One of them burns a sullen red. Xu Lan stands before it, the silver cuff on her wrist, and beside her waits Magistrate Ming Yi with a bamboo tally."
					],
					[
						"Xu Lan",
						"Bearer. At the lake you would not let me face him alone. I was angry with you for a month, and then glad, which was worse. Now the Magistrate has sent for me, and the Elder sent me down after you."
					],
					[
						"Magistrate Ming Yi",
						"Xu Mo, once a demon lord. He came down when the Wheel turned and would not go up: too heavy, says the tally. When a shade will not choose, the roll asks the family, and Miss Xu is all the family he has."
					],
					[
						"Xu Lan",
						"He can go up to the Wheel, drink Meng Po's soup and be born again remembering nothing. Or he can go to King Yama's court and answer for the nineteen first. The roll says it is mine to say. I want you to say it."
					],
					[
						"Lin Feng",
						"Why me?"
					],
					[
						"Xu Lan",
						"Because he hunted you as he hunted them. And the shades say his hunters drove a man and a woman into the Maple Gorge, and that they had a son. If anyone alive has the right to say, it is their son."
					],
					[
						"Yue Ling",
						"She is not asking you to choose for her, Lin Feng. She is asking you to carry it with her."
					]
				],
				"ask": "What should become of Xu Mo's shade?",
				"options": [
					{
						"id": "forgive",
						"label": "Let him go to the Wheel",
						"desc": "Tell her to let him go up to the Wheel, drink Meng Po's soup and be born again remembering nothing. The nineteen, and your parents, will never hear him answer for them; but she will be free of him, and somewhere a child will be born without his weight.",
						"log": "Told Xu Lan to let her father go to the Wheel, and she sent him up to be born remembering nothing.",
						"then": "forgiving",
						"after": [
							[
								"Narrator",
								"Xu Lan opens the lantern's little door. The red flame steadies, pales to white and goes up through the cavern roof like a spark from a fire, towards the Wheel."
							],
							[
								"Xu Lan",
								"He did not look back. He did not know to. Somewhere, one day soon, a baby will cry with no idea what it used to be."
							],
							[
								"Magistrate Ming Yi",
								"Tally closed: gone up, forgiven, by the family. The lantern is yours, Miss Xu. The empty ones always go to the family.",
								"offer"
							]
						]
					},
					{
						"id": "judge",
						"label": "Let him be judged",
						"desc": "Tell her to send him to King Yama's court to answer for the nineteen children, and for the two in the Maple Gorge, before he is born again. He will remember every face while Judge Cui writes it down; it is justice, and it will be neither quick nor kind.",
						"log": "Told Xu Lan to send her father to be judged for the nineteen children, and she sent him to King Yama.",
						"then": "just",
						"after": [
							[
								"Narrator",
								"Xu Lan opens the lantern's little door. The red flame wavers, then sets off along the dark street towards the Wheel and the King at its axle, slowly, the way a man walks to a court."
							],
							[
								"Xu Lan",
								"He will remember them all now, and their names too, this time. Judge Cui will see to it. He writes kindly, they say, but he writes everything."
							],
							[
								"Magistrate Ming Yi",
								"Tally closed: sent to judgement, by the family. The lantern is yours, Miss Xu. The empty ones always go to the family.",
								"offer"
							]
						]
					}
				]
			}
		}
	},
	"s_f_xu4": {
		"n": "The Blood Moon Reborn",
		"by": {
			"foe": {
				"lines": [
					[
						"Narrator",
						"For the first time since Xu Mo fell, the moon over the north-east is red. In the ruined throne hall of the Blood Moon Palace, Xu Lan sits on her father's throne with his soul-lantern burning at her feet."
					],
					[
						"Narrator",
						"Behind her stands a shadow that belongs to nobody, and it leans down to her ear like a clerk reading out a sum."
					],
					[
						"Xu Lan",
						"Bearer. In Youdu you fought me for my father's lantern, and I took it anyway. He has taught me every night since, from inside it. He is a patient teacher. He has nothing else to do."
					],
					[
						"Xu Lan",
						"A voice came to me out of the dark. It calls itself Nie the Unpaid. It says the world owes me a father, nineteen years in silver and a name nobody will speak, and that you are what the world owes. It is very good at sums."
					],
					[
						"Yue Ling",
						"Lin Feng, that shadow is the same as the one gathering at the Wheel. It is wearing her the way she wears his power."
					],
					[
						"Lin Feng",
						"Your father believed somebody else's sums for three hundred years, Xu Lan."
					],
					[
						"Xu Lan",
						"Then at last I am my father's daughter. Come, bearer. Let the moon judge us both."
					]
				],
				"ask": "Xu Lan wears her father's power under a red moon",
				"options": [
					{
						"id": "face",
						"label": "Face her",
						"desc": "Fight Xu Lan in her father's throne hall, under the red moon, with Nie's shadow at her back. She has the moon's blood and her father's arts and means to end you; when it is over, what becomes of her will be yours to decide.",
						"log": "Fought Xu Lan under the red moon in her father's throne hall.",
						"then": "",
						"battle": [
							[
								"xu_lan",
								56
							]
						],
						"follow": {
							"lines": [
								[
									"Narrator",
									"Xu Lan lies on the cracked floor where her father fell. The soul-lantern has rolled from her hand, and the shadow behind her has thinned to a smudge, waiting to see what is owed."
								],
								[
									"Xu Lan",
									"Go on. He told me how it ends. The bearer stands over the Blood Moon, and the heavens choose well."
								],
								[
									"Yue Ling",
									"The moon's blood is going out of her, Lin Feng. Whatever you decide, decide it before Nie does."
								]
							],
							"ask": "Xu Lan lies beaten under the red moon",
							"options": [
								{
									"id": "spare",
									"label": "Spare her",
									"desc": "Put up your sword and let her live, and offer her a place at the Wheel against the shadow that whispered to her. The sects will say you let a demon lord's heir walk free, and she may never thank you; but the debt Nie counted on will go unpaid.",
									"log": "Spared Xu Lan in her father's throne hall, and she carried his lantern to the Wheel to fight Nie.",
									"then": "redeemed",
									"after": [
										[
											"Xu Lan",
											"...He never spared anyone. Not once in three hundred years. I did not know it was allowed."
										],
										[
											"Narrator",
											"The shadow behind her frays like smoke in a draught and slips away west, one debt short. Overhead the moon pales from red to rose to white."
										],
										[
											"Xu Lan",
											"I will carry his lantern to the Wheel. He should have gone there long ago. And if Nie is waiting there, I would like a word with it."
										],
										[
											"Yue Ling",
											"So would we. Walk with us."
										]
									]
								},
								{
									"id": "end",
									"label": "End it",
									"desc": "Finish her here under the red moon, so that nothing of the Blood Moon walks into the last battle at Nie's back. The sects will call it justice and sleep easier; it will not bring back the nineteen or your parents, and Xu Mo's line will end on your sword.",
									"log": "Ended Xu Lan in her father's throne hall, and the last of the Blood Moon went out.",
									"then": "fallen",
									"after": [
										[
											"Xu Lan",
											"Nineteen children, and me. Twenty. He always swore the twentieth would be the last."
										],
										[
											"Narrator",
											"Lin Feng's sword comes down once. The red goes out of the moon, and out of the streak in her hair, and the shadow slides away west towards the Wheel as if a debt had been paid."
										],
										[
											"Yue Ling",
											"We will bury her under the window of her old room, where she can see the moon. It is white again. Somebody should tell her.",
											"grieve"
										]
									]
								}
							]
						}
					}
				]
			},
			"forgiving": {
				"lines": [
					[
						"Narrator",
						"The moon over the Blood Moon Palace is white. Washing hangs between its towers, turnips grow in the parade ground, and the throne hall is full of the Blood Moon's orphans: acolytes' sons, huntsmen's daughters, the old cook's grandchildren."
					],
					[
						"Xu Lan",
						"Bearer! Welcome to my father's house. I have filled it with everybody the sects would have burned for being his. They are mostly very loud.",
						"wave"
					],
					[
						"Xu Lan",
						"In Youdu you told me to let him go up and be forgotten. I did. I cannot forget him for myself, but I can see to it that nobody here inherits him. Nobody in this house pours the moon into anybody."
					],
					[
						"Xu Lan",
						"Something whispers at the gate at night. It calls itself Nie and says the world owes me. I told it the world owes these children breakfast, and shut the gate."
					],
					[
						"Yue Ling",
						"Nie is gathering at the Wheel of the Six Paths: every unpaid debt of the road, made into one shadow."
					],
					[
						"Xu Lan",
						"Then let me pay one of my father's. I will stand beside you at the Wheel, bearer, if you will have me."
					]
				],
				"ask": "Xu Lan asks to stand with you at the Wheel",
				"options": [
					{
						"id": "together",
						"label": "Fight together",
						"desc": "Take her to the Wheel of the Six Paths to stand against Nie at your side, with her father's empty lantern and the moon's blood she has turned to other uses. The refuge must keep itself for a few days, and the sects will not like seeing her among your allies.",
						"log": "Took Xu Lan to the Wheel to stand against Nie, her father's empty lantern in her hand.",
						"then": "ally",
						"after": [
							[
								"Xu Lan",
								"Good. The cook's eldest can mind the turnips. I will bring his lantern. It is empty, but it remembers the way to the Wheel."
							],
							[
								"Lin Feng",
								"It is not your debt, Xu Lan."
							],
							[
								"Xu Lan",
								"No. That is why I want to pay it."
							],
							[
								"Yue Ling",
								"Then the Blood Moon goes to the Wheel at last. On our side."
							]
						]
					}
				]
			},
			"just": {
				"lines": [
					[
						"Narrator",
						"The moon over the Blood Moon Palace is white. Its throne hall is full of the Blood Moon's orphans, acolytes' sons, huntsmen's daughters, the old cook's grandchildren, and on its pillars nineteen names are painted, low enough for children to read."
					],
					[
						"Xu Lan",
						"Bearer! Welcome to my father's house. I have filled it with everybody the sects would have burned for being his. They are mostly very loud.",
						"wave"
					],
					[
						"Xu Lan",
						"In Youdu you told me to send him to be judged, and I did. Judge Cui sent me a copy of the verdict, with all their names in it. I painted them up so the children would know them better than they know his."
					],
					[
						"Xu Lan",
						"Something whispers at the gate at night. It calls itself Nie and says the world owes me. I told it the world owes these children breakfast, and shut the gate."
					],
					[
						"Yue Ling",
						"Nie is gathering at the Wheel of the Six Paths: every unpaid debt of the road, made into one shadow."
					],
					[
						"Xu Lan",
						"His debts were judged, and they were his. But I would like to pay one anyway, by choice. Let me stand beside you at the Wheel, bearer."
					]
				],
				"ask": "Xu Lan asks to stand with you at the Wheel",
				"options": [
					{
						"id": "together",
						"label": "Fight together",
						"desc": "Take her to the Wheel of the Six Paths to stand against Nie at your side, with her father's empty lantern and the moon's blood she has turned to other uses. The refuge must keep itself for a few days, and the sects will not like seeing her among your allies.",
						"log": "Took Xu Lan to the Wheel to stand against Nie, her father's empty lantern in her hand.",
						"then": "ally",
						"after": [
							[
								"Xu Lan",
								"Good. The cook's eldest can mind the little ones. I will bring his lantern. It is empty, but it remembers the way to the Wheel."
							],
							[
								"Lin Feng",
								"The verdict was his, Xu Lan. Not yours."
							],
							[
								"Xu Lan",
								"I know. That is why I can choose to carry some of it."
							],
							[
								"Yue Ling",
								"Then the Blood Moon goes to the Wheel at last. On our side."
							]
						]
					}
				]
			}
		}
	},
	"s_f_liu1": {
		"n": "The Hag's Apprentice",
		"by": {
			"*": {
				"lines": [
					[
						"Narrator",
						"In the Hag's hut, on stilts over the red water, a girl in a green-grey robe sits on the floor among a hundred little jars, sorting them into two rows. She wears an apron of herb pockets and her hair in two loops, and she does not look up."
					],
					[
						"Liu Ying",
						"Don't touch the black jars. Don't touch the white ones either; they're worse. So she's dead. Good. She had me halfway through a letter to the Blood Moon about a sweeper with a strange root. I write a good hand. She never learned."
					],
					[
						"Lin Feng",
						"Who are you, to write her letters?"
					],
					[
						"Liu Ying",
						"Liu Ying. My family sold me to her at six, in the famine year, for a sack of millet. That book has every plant in the marsh in it, and two lines under each: what it kills, and what it cures. I know it by heart."
					],
					[
						"Yue Ling",
						"Iron Fang wanted me to pour a gourd of marsh venom into the sect's well. I would not. Somebody did, and a dozen disciples are lying in Alchemist Mo's infirmary."
					],
					[
						"Liu Ying",
						"Toad venom. I milked the toads and waxed the gourds shut, and I never asked who they were for. Steep your lotuses in copper, not iron, or the antidote turns. She taught me that too."
					],
					[
						"Narrator",
						"Liu Ying lays one hand flat on the grimoire, bound in toad-skin and fat with pressed flowers. It is hers now, she says, and the hut, and the lotuses, which die if nobody weeds them. Unless they have come to take those too."
					]
				],
				"ask": "What becomes of the Hag's apprentice?",
				"options": [
					{
						"id": "mo",
						"label": "Take her to Alchemist Mo",
						"desc": "Take her and the grimoire up the mountain to Alchemist Mo. She gets a roof and a teacher, and grinds the antidote beside the dozen disciples her venom poisoned, and the Hag's lotus beds are left to the marsh.",
						"log": "Took Liu Ying to Alchemist Mo, to brew the antidote for the venom she had milked herself.",
						"then": "apprentice",
						"after": [
							[
								"Liu Ying",
								"Alchemist Mo. Does he lock his cabinets? He should, if I'm coming."
							],
							[
								"Narrator",
								"She packs the jars into her basket, the grimoire on top, and blows out the Hag's lamp. At the door she stops and looks back at the lotus beds in the red water."
							],
							[
								"Liu Ying",
								"Somebody will have to come back and weed them. Not me. Somebody."
							]
						]
					},
					{
						"id": "home",
						"label": "Burn the book, take her home",
						"desc": "Burn the Hag's grimoire in her own stove and walk Liu Ying home to the village that sold her. The poisons go up in smoke, and so does every cure the Hag ever knew, the secret of the blood lotuses among them.",
						"log": "Burned the Hag's grimoire and took Liu Ying home to the family that sold her in a famine.",
						"then": "home",
						"after": [
							[
								"Narrator",
								"Lin Feng feeds the grimoire into the Hag's stove page by page, and Liu Ying says the name of every plant as it curls: what it killed, and what it cured."
							],
							[
								"Liu Ying",
								"So. Now nobody knows how to grow a blood lotus but the lotus. My village is past the southern sands, where the mushrooms glow at night. They sold me for a sack of millet. I hope it lasted them the winter."
							],
							[
								"Yue Ling",
								"They will be glad to see you."
							],
							[
								"Liu Ying",
								"You don't know that. Neither do I. Walk me there anyway."
							]
						]
					},
					{
						"id": "keep",
						"label": "Leave her the hut and the book",
						"desc": "Let her keep the grimoire and the hut, as she wants. The blood lotuses keep their keeper and the marsh its herb-wife, and she keeps the Hag's customers too, bandits and Blood Moon men, alone at fourteen.",
						"log": "Left Liu Ying the Hag's hut and grimoire, as she wished, alone in the Crimson Marsh.",
						"then": "witch",
						"after": [
							[
								"Liu Ying",
								"Good. Somebody has to keep the lotuses. They sulk if you look away for a week, and the next sweeper with a dozen poisoned friends will need them."
							],
							[
								"Lin Feng",
								"And when the bandits come to buy venom?"
							],
							[
								"Liu Ying",
								"Then I'll sell it to them, or I won't. It's my book now."
							],
							[
								"Narrator",
								"When they look back from the duckboards she is sorting the jars again, black and white, into two rows of her own."
							]
						]
					}
				]
			}
		}
	},
	"s_f_liu2": {
		"n": "Spores and Cures",
		"by": {
			"apprentice": {
				"lines": [
					[
						"Narrator",
						"Under a glowcap as wide as a threshing floor, nineteen of the Spore-Witch's gatherers lie asleep on mats, smiling, with grey down on their lips. Liu Ying kneels among them in a sect apprentice's sash, with a mortar in her lap."
					],
					[
						"Liu Ying",
						"Spore-blight. The Mother of Spores breathes sleep on anything cold and frightened, and they breathed it in. They dream they're warm while grey caps grow in their lungs. Mo sent me for glowcaps for his lanterns. I found this."
					],
					[
						"Lin Feng",
						"Can you wake them?"
					],
					[
						"Liu Ying",
						"With toad venom, cut the Hag's way: one drop wakes the heart, two stop it. Mo keeps her grimoire locked in his cabinet, the way I told him to, but I know page ninety by heart."
					],
					[
						"Liu Ying",
						"Or with six Wood Essences, steeped in glowcap ash. Green qi breaks the caps slowly, over three days, and nobody's heart stops but the caps'. I haven't got six Wood Essences. Apprentices get paid in advice."
					],
					[
						"Yue Ling",
						"One drop or two, judged by eye, nineteen times."
					],
					[
						"Liu Ying",
						"By eye. That's what medicine is, mostly. You brought me to Mo, sweeper, so you can choose."
					]
				],
				"ask": "How will the sleepers be woken?",
				"options": [
					{
						"id": "poison",
						"label": "Use the Hag's venom",
						"desc": "Let her brew the waking-draught with the Hag's toad venom. The sleepers wake within the hour, but the waking dose and the killing dose are one drop apart, and she must judge all nineteen by eye.",
						"log": "Let Liu Ying wake the spore-sleepers with the Hag's venom; eighteen woke, and one heart stopped.",
						"then": "bold",
						"after": [
							[
								"Narrator",
								"She works down the mats with a glass rod, a drop on each tongue. Eighteen sleepers wake coughing up grey dust. The nineteenth, an old charcoal-burner with a weak heart, sighs once and does not wake."
							],
							[
								"Liu Ying",
								"Eighteen. By tomorrow I'd have lost all nineteen. I know that. I'll know it every night, too.",
								"grieve"
							],
							[
								"Yue Ling",
								"Every healer carries one. Carry it, and do not let it stop your hands."
							]
						]
					},
					{
						"id": "essence",
						"label": "Give her six Wood Essences",
						"desc": "Give her six Wood Essences for the slow cure. No heart is gambled on a drop, but the sleepers lie three more days with caps growing in their lungs, and six essences go into her pot instead of your pack.",
						"log": "Gave Liu Ying six Wood Essences for the slow cure, and all nineteen sleepers woke on the third day.",
						"then": "careful",
						"need": [
							[
								"item",
								"ess_wood",
								6
							]
						],
						"pay": {
							"items": {
								"ess_wood": 6
							}
						},
						"after": [
							[
								"Narrator",
								"For three days green steam rises under the great glowcap, and Liu Ying sleeps sitting up between the mats. On the third morning the sleepers wake one by one, thin and hoarse, and every one of them alive."
							],
							[
								"Liu Ying",
								"Nineteen. Slow, and nothing died but the caps. I didn't know I'd like slow. Don't tell Mo; he'll want me to do everything this way for ever."
							]
						]
					}
				]
			},
			"home": {
				"lines": [
					[
						"Narrator",
						"On the vale road Liu Ying is waiting with an empty basket and grey dust on her sleeves. Below the vale, where the mushrooms glow at night, her family's village lies asleep in its doorways, smiling."
					],
					[
						"Liu Ying",
						"Spore-blight. The Mother of Spores breathes sleep on anything cold and frightened, and the wind brings it down to us. They dream they're warm while grey caps grow in their lungs. My mother. My father. The neighbours who watched them sell me."
					],
					[
						"Liu Ying",
						"There was a waking-draught on page ninety of the Hag's book. You burned page ninety, sweeper. I remember half of it, and half a dose is a poison."
					],
					[
						"Lin Feng",
						"Then tell me what you need."
					],
					[
						"Yue Ling",
						"Healing Pills would mend their lungs enough to wake them today. Or there is a slower way. They dream of warmth because they are cold, and glowcap smoke is warm. It would take days, and it would have to be learned."
					],
					[
						"Liu Ying",
						"Pills today, or three days of lessons while the millet rots in the field. The last bad harvest, they sold me. Choose, then. You're good at choosing for me."
					]
				],
				"ask": "How will her village be woken?",
				"options": [
					{
						"id": "pills",
						"label": "Give her four Healing Pills",
						"desc": "Give her four Healing Pills to grind into the village well. Her people wake by nightfall and call her their healer, though the cure in her hands is the sect's, and she cannot make another.",
						"log": "Gave Liu Ying four Healing Pills, and her village woke by nightfall and called her its healer.",
						"then": "healer",
						"need": [
							[
								"item",
								"hp_pill",
								4
							]
						],
						"pay": {
							"items": {
								"hp_pill": 4
							}
						},
						"after": [
							[
								"Narrator",
								"She grinds the pills into the well bucket and goes from door to door with a ladle. By nightfall the village is awake and coughing grey, and her mother is holding her by both sleeves and will not let go."
							],
							[
								"Liu Ying",
								"They're calling me their healer. With your pills. I couldn't make one of them if you paid me."
							],
							[
								"Lin Feng",
								"Alchemist Mo says pills are only borrowed time. They have lent you some. Use it."
							]
						]
					},
					{
						"id": "teach",
						"label": "Stay and teach her",
						"desc": "Stay three days while Yue Ling teaches her to wake the sleepers with glowcap smoke and warmth. She learns a cure no book ever held, but the village sleeps through its harvest, and the millet rots in the field.",
						"log": "Stayed while Yue Ling taught Liu Ying the glowcap cure; her village woke, but the harvest rotted.",
						"then": "learner",
						"after": [
							[
								"Narrator",
								"For three days and nights they keep glowcap embers smouldering by every sleeper, and Yue Ling shows her how to read a sleeping face for the moment it turns towards the warmth. On the third night the village wakes."
							],
							[
								"Liu Ying",
								"The millet rotted while they slept. It'll be a hungry winter. The last hungry winter, they sold a child."
							],
							[
								"Liu Ying",
								"This winter they have somebody who knows which roots you can dig out of the snow. Nobody is getting sold."
							]
						]
					}
				]
			},
			"witch": {
				"lines": [
					[
						"Narrator",
						"Where the Spore-Witch's people live in hollow mushroom stalks, a queue of gatherers with grey dust on their lips waits in front of a girl with a basket. She is selling little black jars, one to a family, for whatever they have."
					],
					[
						"Liu Ying",
						"Sweeper. You left me a hut and a book, and look, I'm a merchant. Rot-bane. A spoonful at the foot of the Mother of Spores, and by morning she's dead, and every cap in the vale with her, and the sleep stops."
					],
					[
						"Yue Ling",
						"Every cap? The glowcaps too? They are the only kindling the vale has left for Zhu Que's fire."
					],
					[
						"Liu Ying",
						"Every cap. Poison doesn't read. Their children are asleep with grey caps growing in their lungs, and the Spore-Witch tells them to be patient. I don't tell anybody to be patient. I sell what works."
					],
					[
						"Lin Feng",
						"And it would work. That is the trouble."
					],
					[
						"Liu Ying",
						"Everything in that book works. That was always the trouble. So, sweeper: are you going to stop me, or are you going to buy?",
						"point"
					]
				],
				"ask": "What will you do about the rot-bane?",
				"options": [
					{
						"id": "stop",
						"label": "Stop her by force",
						"desc": "Fight her for the rot-bane and burn every jar. The vale keeps its glowcaps and Zhu Que her last kindling, but the gatherers lose the only cure anyone would sell them, and she is beaten in front of her customers.",
						"log": "Fought Liu Ying for her rot-bane in Glowcap Vale and burned it in front of her customers.",
						"then": "rival",
						"battle": [
							[
								"liu_ying",
								27
							]
						],
						"after": [
							[
								"Narrator",
								"The rot-bane burns with a thin green flame. The gatherers drift back to their stalks without a word, and Liu Ying picks herself up out of the mushroom litter very carefully, as if nothing hurts."
							],
							[
								"Liu Ying",
								"You beat me with a sword. Swords are easy; you only have to be stronger. With poison you have to be cleverer. Next time I'll be cleverer."
							],
							[
								"Yue Ling",
								"She meant to help them, Lin Feng. In her way."
							],
							[
								"Lin Feng",
								"I know. That is what frightens me about her way."
							]
						]
					},
					{
						"id": "buy",
						"label": "Buy her whole stock",
						"desc": "Pay her six thousand spirit stones for every jar, and pour the lot away where it can harm nothing. The vale keeps its glowcaps and she keeps her pride, and learns that a cultivator pays more for poison than a village.",
						"log": "Bought up Liu Ying's rot-bane for six thousand spirit stones, and she learned who pays best.",
						"then": "dealer",
						"need": [
							[
								"stones",
								6000
							]
						],
						"pay": {
							"stones": 6000
						},
						"gain": {
							"items": {
								"ess_dark": 3
							}
						},
						"after": [
							[
								"Liu Ying",
								"Six thousand. The whole vale couldn't scrape together six hundred. Here, the Yin Essence I cut it with, three jars. I don't give change.",
								"offer"
							],
							[
								"Narrator",
								"She counts the stones twice and ties them into her apron pockets one by one, and looks at Lin Feng the way the Hag must once have looked at a bright young root."
							],
							[
								"Liu Ying",
								"Poor people pay in turnips. I've been selling to the wrong customers."
							]
						]
					}
				]
			}
		}
	},
	"s_f_liu3": {
		"n": "The Elixir of Fangzhang",
		"by": {
			"bold": {
				"lines": [
					[
						"Narrator",
						"Under a dying pearl tree on the garden terraces, its jade leaves dropping like coins, Liu Ying sits with a mouldering scroll across her knees and her apprentice's sash from the sect, much mended, round her waist."
					],
					[
						"Liu Ying",
						"Sweeper. I waded out over the sandbars with my basket on my head for these herb beds, and look what the furnace-masters left lying in the House of the Nine Furnaces. The elixir. The real one, not Xu Fu's green fruit."
					],
					[
						"Liu Ying",
						"There's no ripe fruit left, so they brewed it from the heart-pearl, where a pearl tree keeps every drop of the Ruins it ever drank. Drawing it kills the tree. Cut ten thousand times, a drop stops a dying man for an hour: long enough to sew him up."
					],
					[
						"Liu Ying",
						"In the vale I judged nineteen doses by eye and got one wrong. I still see the charcoal-burner every night. With this I could have stopped him for an hour, and tried again."
					],
					[
						"Lin Feng",
						"And the tree?"
					],
					[
						"He Xiangu of the Lotus",
						"Draw out its heart and it dies today instead of next year. Or never, if you bring the sea home, as Lu Dongbin thinks you will. It is one of the old ones. It remembers Xu Fu coming up the hill."
					],
					[
						"Yue Ling",
						"An hour for every dying patient, against a tree that has stood two thousand years. I do not know the answer, Lin Feng."
					]
				],
				"ask": "Will she take the pearl tree's heart?",
				"options": [
					{
						"id": "forbid",
						"label": "Medicine is for the living",
						"desc": "Tell her medicine is for the living, the tree among them, and leave its heart where it is. The pearl tree lives to see the sea come home, and the dying she might have stopped for an hour will die.",
						"log": "Told Liu Ying that medicine is for the living, and the old pearl tree kept its heart.",
						"then": "physician",
						"after": [
							[
								"Liu Ying",
								"Medicine is for the living. You sound like Yue Ling. Fine. I'll be quicker with a needle, and I'll lose the ones I lose, like every healer before me."
							],
							[
								"He Xiangu of the Lotus",
								"Thank you. Come back when the sea does, and it will give you dew for nothing. So will I."
							],
							[
								"Narrator",
								"Liu Ying copies the recipe out in small, neat characters all the same. Then she looks at the tree for a long time, and tears the copy into pieces too small even for her to put back together."
							]
						]
					},
					{
						"id": "help",
						"label": "Help her brew it",
						"desc": "Help her draw out the heart-pearl and brew the immortals' elixir, cut ten thousand times. A pearl tree that remembers Xu Fu dies today, and she carries an hour of stopped time for every dying patient she meets.",
						"log": "Helped Liu Ying brew the immortals' elixir from a pearl tree's heart, and the old tree died.",
						"then": "alchemist",
						"after": [
							[
								"Narrator",
								"When Lin Feng draws the heart-pearl out, every jade leaf on the tree falls at once, like a purse of coins emptied on the terrace. The pearl in his palm is cold and perfectly still."
							],
							[
								"He Xiangu of the Lotus",
								"Two thousand years, and it never once fruited for an emperor. Brew it well, at least.",
								"grieve"
							],
							[
								"Liu Ying",
								"Ten thousand doses, an hour each. I'll paint a jade leaf on every one. Somebody ought to remember this tree, and it may as well be the people it keeps alive."
							]
						]
					}
				]
			},
			"careful": {
				"lines": [
					[
						"Narrator",
						"Under a dying pearl tree on the garden terraces, its jade leaves dropping like coins, Liu Ying sits with a mouldering scroll across her knees and her apprentice's sash from the sect, much mended, round her waist."
					],
					[
						"Liu Ying",
						"Sweeper. I waded out over the sandbars with my basket on my head for these herb beds, and look what the furnace-masters left lying in the House of the Nine Furnaces. The elixir. The real one, not Xu Fu's green fruit."
					],
					[
						"Liu Ying",
						"There's no ripe fruit left, so they brewed it from the heart-pearl, where a pearl tree keeps every drop of the Ruins it ever drank. Drawing it kills the tree. Cut ten thousand times, a drop stops a dying man for an hour: long enough to sew him up."
					],
					[
						"Liu Ying",
						"In the vale you paid six Wood Essences so I wouldn't gamble a heart on a drop, and nobody died of my cure. I've been careful ever since. So I'm asking you first. That's careful."
					],
					[
						"Lin Feng",
						"And the tree?"
					],
					[
						"He Xiangu of the Lotus",
						"Draw out its heart and it dies today instead of next year. Or never, if you bring the sea home, as Lu Dongbin thinks you will. It is one of the old ones. It remembers Xu Fu coming up the hill."
					],
					[
						"Yue Ling",
						"An hour for every dying patient, against a tree that has stood two thousand years. I do not know the answer, Lin Feng."
					]
				],
				"ask": "Will she take the pearl tree's heart?",
				"options": [
					{
						"id": "forbid",
						"label": "Medicine is for the living",
						"desc": "Tell her medicine is for the living, the tree among them, and leave its heart where it is. The pearl tree lives to see the sea come home, and the dying she might have stopped for an hour will die.",
						"log": "Told Liu Ying that medicine is for the living, and the old pearl tree kept its heart.",
						"then": "physician",
						"after": [
							[
								"Liu Ying",
								"Medicine is for the living. You sound like Yue Ling. Fine. I'll be quicker with a needle, and I'll lose the ones I lose, like every healer before me."
							],
							[
								"He Xiangu of the Lotus",
								"Thank you. Come back when the sea does, and it will give you dew for nothing. So will I."
							],
							[
								"Narrator",
								"Liu Ying copies the recipe out in small, neat characters all the same. Then she looks at the tree for a long time, and tears the copy into pieces too small even for her to put back together."
							]
						]
					},
					{
						"id": "help",
						"label": "Help her brew it",
						"desc": "Help her draw out the heart-pearl and brew the immortals' elixir, cut ten thousand times. A pearl tree that remembers Xu Fu dies today, and she carries an hour of stopped time for every dying patient she meets.",
						"log": "Helped Liu Ying brew the immortals' elixir from a pearl tree's heart, and the old tree died.",
						"then": "alchemist",
						"after": [
							[
								"Narrator",
								"When Lin Feng draws the heart-pearl out, every jade leaf on the tree falls at once, like a purse of coins emptied on the terrace. The pearl in his palm is cold and perfectly still."
							],
							[
								"He Xiangu of the Lotus",
								"Two thousand years, and it never once fruited for an emperor. Brew it well, at least.",
								"grieve"
							],
							[
								"Liu Ying",
								"Ten thousand doses, an hour each. I'll paint a jade leaf on every one. Somebody ought to remember this tree, and it may as well be the people it keeps alive."
							]
						]
					}
				]
			},
			"healer": {
				"lines": [
					[
						"Narrator",
						"Under a dying pearl tree on the garden terraces, its jade leaves dropping like coins, Liu Ying sits with a mouldering scroll across her knees and a healer's red cord in her hair, the kind her village ties on whoever it sends for at night."
					],
					[
						"Liu Ying",
						"Sweeper. My village sends me everywhere now; I waded out over the sandbars for these herb beds. And look what the furnace-masters left lying in the House of the Nine Furnaces. The elixir. The real one."
					],
					[
						"Liu Ying",
						"There's no ripe fruit left, so they brewed it from the heart-pearl, where a pearl tree keeps every drop of the Ruins it ever drank. Drawing it kills the tree. Cut ten thousand times, a drop stops a dying man for an hour: long enough to sew him up."
					],
					[
						"Liu Ying",
						"Your four pills woke my village below the vale. Then they ran out, and people went on dying of ordinary things: fevers, falls, babies the wrong way round. One pearl is ten thousand doses. It would never run out."
					],
					[
						"Lin Feng",
						"And the tree?"
					],
					[
						"He Xiangu of the Lotus",
						"Draw out its heart and it dies today instead of next year. Or never, if you bring the sea home, as Lu Dongbin thinks you will. It is one of the old ones. It remembers Xu Fu coming up the hill."
					],
					[
						"Yue Ling",
						"An hour for every dying patient, against a tree that has stood two thousand years. I do not know the answer, Lin Feng."
					]
				],
				"ask": "Will she take the pearl tree's heart?",
				"options": [
					{
						"id": "forbid",
						"label": "Medicine is for the living",
						"desc": "Tell her medicine is for the living, the tree among them, and leave its heart where it is. The pearl tree lives to see the sea come home, and the dying she might have stopped for an hour will die.",
						"log": "Told Liu Ying that medicine is for the living, and the old pearl tree kept its heart.",
						"then": "physician",
						"after": [
							[
								"Liu Ying",
								"Medicine is for the living. You sound like Yue Ling. Fine. I'll be quicker with a needle, and I'll lose the ones I lose, like every healer before me."
							],
							[
								"He Xiangu of the Lotus",
								"Thank you. Come back when the sea does, and it will give you dew for nothing. So will I."
							],
							[
								"Narrator",
								"Liu Ying copies the recipe out in small, neat characters all the same. Then she looks at the tree for a long time, and tears the copy into pieces too small even for her to put back together."
							]
						]
					},
					{
						"id": "help",
						"label": "Help her brew it",
						"desc": "Help her draw out the heart-pearl and brew the immortals' elixir, cut ten thousand times. A pearl tree that remembers Xu Fu dies today, and she carries an hour of stopped time for every dying patient she meets.",
						"log": "Helped Liu Ying brew the immortals' elixir from a pearl tree's heart, and the old tree died.",
						"then": "alchemist",
						"after": [
							[
								"Narrator",
								"When Lin Feng draws the heart-pearl out, every jade leaf on the tree falls at once, like a purse of coins emptied on the terrace. The pearl in his palm is cold and perfectly still."
							],
							[
								"He Xiangu of the Lotus",
								"Two thousand years, and it never once fruited for an emperor. Brew it well, at least.",
								"grieve"
							],
							[
								"Liu Ying",
								"Ten thousand doses, an hour each. I'll paint a jade leaf on every one. Somebody ought to remember this tree, and it may as well be the people it keeps alive."
							]
						]
					}
				]
			},
			"learner": {
				"lines": [
					[
						"Narrator",
						"Under a dying pearl tree on the garden terraces, its jade leaves dropping like coins, Liu Ying sits with a mouldering scroll across her knees and her apron pockets stuffed with cuttings, every one wrapped in damp moss the way Yue Ling showed her."
					],
					[
						"Liu Ying",
						"Sweeper. Yue Ling taught me that warmth is a medicine, and I haven't stopped learning since; I waded out over the sandbars for these herb beds. And look what the furnace-masters left lying about. The elixir."
					],
					[
						"Liu Ying",
						"There's no ripe fruit left, so they brewed it from the heart-pearl, where a pearl tree keeps every drop of the Ruins it ever drank. Drawing it kills the tree. Cut ten thousand times, a drop stops a dying man for an hour: long enough to sew him up."
					],
					[
						"Liu Ying",
						"Nobody in my village was sold that hungry winter; we lived on roots I dug out of the snow. I've learned all I can from things that grow. This grows. It only has to die first."
					],
					[
						"Lin Feng",
						"And the tree?"
					],
					[
						"He Xiangu of the Lotus",
						"Draw out its heart and it dies today instead of next year. Or never, if you bring the sea home, as Lu Dongbin thinks you will. It is one of the old ones. It remembers Xu Fu coming up the hill."
					],
					[
						"Yue Ling",
						"I taught you to read a sleeping face for the warmth. I never taught you to weigh a tree against a life. I do not know how, Lin Feng."
					]
				],
				"ask": "Will she take the pearl tree's heart?",
				"options": [
					{
						"id": "forbid",
						"label": "Medicine is for the living",
						"desc": "Tell her medicine is for the living, the tree among them, and leave its heart where it is. The pearl tree lives to see the sea come home, and the dying she might have stopped for an hour will die.",
						"log": "Told Liu Ying that medicine is for the living, and the old pearl tree kept its heart.",
						"then": "physician",
						"after": [
							[
								"Liu Ying",
								"Medicine is for the living. You sound like Yue Ling. Fine. I'll be quicker with a needle, and I'll lose the ones I lose, like every healer before me."
							],
							[
								"He Xiangu of the Lotus",
								"Thank you. Come back when the sea does, and it will give you dew for nothing. So will I."
							],
							[
								"Narrator",
								"Liu Ying copies the recipe out in small, neat characters all the same. Then she looks at the tree for a long time, and tears the copy into pieces too small even for her to put back together."
							]
						]
					},
					{
						"id": "help",
						"label": "Help her brew it",
						"desc": "Help her draw out the heart-pearl and brew the immortals' elixir, cut ten thousand times. A pearl tree that remembers Xu Fu dies today, and she carries an hour of stopped time for every dying patient she meets.",
						"log": "Helped Liu Ying brew the immortals' elixir from a pearl tree's heart, and the old tree died.",
						"then": "alchemist",
						"after": [
							[
								"Narrator",
								"When Lin Feng draws the heart-pearl out, every jade leaf on the tree falls at once, like a purse of coins emptied on the terrace. The pearl in his palm is cold and perfectly still."
							],
							[
								"He Xiangu of the Lotus",
								"Two thousand years, and it never once fruited for an emperor. Brew it well, at least.",
								"grieve"
							],
							[
								"Liu Ying",
								"Ten thousand doses, an hour each. I'll paint a jade leaf on every one. Somebody ought to remember this tree, and it may as well be the people it keeps alive."
							]
						]
					}
				]
			},
			"rival": {
				"lines": [
					[
						"Narrator",
						"On a terrace of the immortals' gardens a bronze pot is boiling over a fire that never went out: Liu Ying has stolen a lantern of it from the furnace that walked away. Three old men in faded Court silk watch the pot and take notes."
					],
					[
						"Liu Ying",
						"Sweeper. You beat me in Glowcap Vale with a sword, and I said next time I'd be cleverer. This is cleverer: a poison that stops a man where he stands, simmered in a fire that has never once gone out."
					],
					[
						"Liu Ying",
						"These gentlemen are the Court's last loyalists. They keep its calendar and wait for it to come back, and they want something that will stop the bearer of the Nine Heavens root. I'd have brewed it for nothing."
					],
					[
						"Yue Ling",
						"The Court harvested the root's bearers, nineteen of them before him. You are brewing its last harvest, Liu Ying."
					],
					[
						"Liu Ying",
						"I'm brewing the best poison anybody ever made. Who drinks it is their business. That was the old woman's rule, and now it's mine."
					],
					[
						"Lin Feng",
						"Then I am making it my business."
					]
				],
				"ask": "What of the poison in the stolen fire?",
				"options": [
					{
						"id": "stop",
						"label": "Spill the poison",
						"desc": "Fight her at the pot and spill the poison before it is done. The loyalists lose their weapon and scatter, but she gets away over the drained sea, and from today the grudge between you is no longer a game.",
						"log": "Spilled Liu Ying's poison for the Court's last loyalists; she escaped Fangzhang on a stolen crane.",
						"then": "foe",
						"battle": [
							[
								"liu_ying",
								50
							]
						],
						"after": [
							[
								"Narrator",
								"The pot goes over and the poison hisses into the herb beds, where nothing will grow for a year. On one knee, Liu Ying flicks a pill into the air, and a crane who steals elixirs swoops down for it."
							],
							[
								"Liu Ying",
								"Keep the fire, sweeper. I'll find another. There's always another fire, and always somebody who'll pay to be rid of you."
							],
							[
								"Narrator",
								"She is on the crane's back before the smoke clears, and away east over the drained sea. The old men in Court silk have already scattered like the rabbits from the herb beds."
							]
						]
					}
				]
			},
			"dealer": {
				"lines": [
					[
						"Narrator",
						"On a terrace of the immortals' gardens a bronze pot is boiling over a fire that never went out: Liu Ying has stolen a lantern of it from the furnace that walked away. Three old men in faded Court silk watch the pot and take notes."
					],
					[
						"Liu Ying",
						"Sweeper! My best customer. In Glowcap Vale you paid six thousand for a basket of rot-bane and taught me who to sell to: not villages, people with gold. This is a poison that stops a man where he stands."
					],
					[
						"Liu Ying",
						"These gentlemen are the Court's last loyalists. They pay in the old square gold, and they want something that will stop the bearer of the Nine Heavens root. It isn't personal. It's very well paid."
					],
					[
						"Liu Ying",
						"And don't look at me like that. Every famine somebody sells a child, and with Court gold I buy them first, before the next hag can. I've bought eleven."
					],
					[
						"Yue Ling",
						"Eleven children, bought with a poison meant for him."
					],
					[
						"Lin Feng",
						"Then buy the twelfth with something else."
					]
				],
				"ask": "What of the poison in the stolen fire?",
				"options": [
					{
						"id": "stop",
						"label": "Spill the poison",
						"desc": "Fight her at the pot and spill the poison before it is done. The loyalists lose their weapon and scatter, but she gets away over the drained sea, and from today the grudge between you is no longer a game.",
						"log": "Spilled Liu Ying's poison for the Court's last loyalists; she escaped Fangzhang on a stolen crane.",
						"then": "foe",
						"battle": [
							[
								"liu_ying",
								50
							]
						],
						"after": [
							[
								"Narrator",
								"The pot goes over and the poison hisses into the herb beds, where nothing will grow for a year. On one knee, Liu Ying flicks a pill into the air, and a crane who steals elixirs swoops down for it."
							],
							[
								"Liu Ying",
								"Keep the fire, sweeper. I'll find another. There's always another fire, and always somebody who'll pay to be rid of you."
							],
							[
								"Narrator",
								"She is on the crane's back before the smoke clears, and away east over the drained sea. The old men in Court silk have already scattered like the rabbits from the herb beds."
							]
						]
					}
				]
			}
		}
	},
	"s_f_liu4": {
		"n": "The Poison Saint",
		"by": {
			"physician": {
				"lines": [
					[
						"Narrator",
						"The Hag's old hut in the Crimson Marsh has a new roof and a queue on the duckboards: a ferryman with a cough, a bandit with an arrow in him, a mother with twins. The poison hedge is cut back, and the blood lotuses are weeded."
					],
					[
						"Liu Ying",
						"Sweeper. On Fangzhang you told me medicine is for the living. So I came back to the one place where the old woman had nobody left to heal, and the living were here all along. They just wouldn't knock on a witch's door."
					],
					[
						"Liu Ying",
						"I milk the toads by the drop now, for failing hearts, not by the gourd for bandits. Same toads. Same venom. It was always the same knowledge. It only needed somebody to ask it the other question."
					],
					[
						"Lin Feng",
						"Has Nie been here? He has been to everyone whose life I touched."
					],
					[
						"Liu Ying",
						"A shadow made of grudges, whispering that you killed the woman who fed me for eight years. I gave him something for his nerves. Grudges are wounds gone bad: you cut, you clean, you let them bleed honest."
					],
					[
						"Yue Ling",
						"Then he is a wound, and wounds are our work. We should have asked you along years ago."
					],
					[
						"Liu Ying",
						"I'm coming to the Wheel. Yue Ling can't sew up everybody, and I want a look at an unhealed grudge from the inside."
					]
				],
				"ask": "Will Liu Ying come to the Wheel?",
				"options": [
					{
						"id": "together",
						"label": "Bring her to the Wheel",
						"desc": "Take Liu Ying to the Wheel of the Six Paths as a second healer for the last battle. Her clinic shuts its door for the first time in a year, and the queue on the duckboards goes home to wait.",
						"log": "Took Liu Ying to the Wheel of the Six Paths as a healer, and her marsh clinic shut its door.",
						"then": "ally",
						"after": [
							[
								"Narrator",
								"She hangs a board on the door in her small, neat hand: 'Gone to the Wheel. Back soon. Do not touch the black jars.'"
							],
							[
								"Liu Ying",
								"Or the white ones. They're worse."
							],
							[
								"Yue Ling",
								"Two healers, then. I have wanted somebody to argue about doses with for years."
							]
						]
					}
				]
			},
			"alchemist": {
				"lines": [
					[
						"Narrator",
						"The Hag's old hut in the Crimson Marsh has a new roof and a queue on the duckboards. On the shelf over the stove, where the Hag kept her black jars, stands one lacquered box with a jade leaf painted on the lid."
					],
					[
						"Liu Ying",
						"Sweeper. The pearl tree's heart you helped me draw on Fangzhang: ten thousand doses. I've used three. A woodcutter under a fallen pine, a girl with the boiling fever, and a bandit, because he was dying too."
					],
					[
						"Liu Ying",
						"Three alive who would have died, and one tree dead that would have lived. I don't know if that's a fair price. He Xiangu writes to say it was one of the old ones. She writes it every time."
					],
					[
						"Lin Feng",
						"Has Nie been here? He has been to everyone whose life I touched."
					],
					[
						"Liu Ying",
						"He whispered that you killed the woman who fed me for eight years, and let me kill a tree for my pride. I told him I do my own killing, thank you, and my own being sorry. He didn't like that.",
						"shake"
					],
					[
						"Yue Ling",
						"Then he is a wound, and wounds are our work. We should have asked you along years ago."
					],
					[
						"Liu Ying",
						"I'm coming to the Wheel. If anybody falls there I can stop them for an hour, and an hour is long enough for Yue Ling to reach them."
					]
				],
				"ask": "Will Liu Ying come to the Wheel?",
				"options": [
					{
						"id": "together",
						"label": "Bring her to the Wheel",
						"desc": "Take Liu Ying and her box of stopped hours to the Wheel of the Six Paths for the last battle. The clinic shuts its door while she is gone, and whoever falls ill in the marsh must wait for her.",
						"log": "Took Liu Ying and her box of stopped hours to the Wheel, and her marsh clinic shut its door.",
						"then": "ally",
						"after": [
							[
								"Narrator",
								"She tucks the lacquered box into her apron between the toad venom and the bandages, and hangs a board on the door: 'Gone to the Wheel. Back soon. Do not touch the black jars.'"
							],
							[
								"Liu Ying",
								"Or the white ones. They're worse."
							],
							[
								"Yue Ling",
								"Two healers and a box of stopped hours. I have wanted somebody to argue about doses with for years."
							]
						]
					}
				]
			},
			"foe": {
				"lines": [
					[
						"Narrator",
						"The Hag's old hut has sunk to its knees in the red water, and round it the poison hedge has grown into a garden: monkshood, heartbreak grass, blood-lotus root, every bed labelled once, in a small neat hand, with what it kills."
					],
					[
						"Liu Ying",
						"Sweeper. They call me the Poison Saint now; the Court's old men did, before they died of something. You left me this hut and a book at fourteen, and you never once came back to ask how that was going."
					],
					[
						"Lin Feng",
						"No. I never did. I am asking now."
					],
					[
						"Narrator",
						"Behind her, where her shadow ought to be, stands something taller, made of every debt the journey left unpaid. Nie the Unpaid has been whispering in her ear, and she has been listening."
					],
					[
						"Liu Ying",
						"Nie asked first. He tells me everything you owe. The old woman who fed me eight years: you cut her down and walked off with her lotuses. The vale. Fangzhang. He says debts like that get paid in something that lasts."
					],
					[
						"Yue Ling",
						"He is made of grudges, Liu Ying. He will use you up and leave you labelled, like one of your flowers."
					],
					[
						"Liu Ying",
						"Then let's find out what kills him. I've a whole garden of things to try. You first.",
						"point"
					]
				],
				"ask": "The Poison Saint bars the way",
				"options": [
					{
						"id": "face",
						"label": "Face the Poison Saint",
						"desc": "Fight Liu Ying among her poison beds, with Nie's shadow at her back and every flower in the garden turned to a weapon. When it is over, her life will be in your hands and nobody else's.",
						"log": "Faced Liu Ying, the Poison Saint, in the Hag's old garden, with Nie's shadow at her back.",
						"then": "",
						"battle": [
							[
								"liu_ying",
								55
							]
						],
						"follow": {
							"lines": [
								[
									"Narrator",
									"Liu Ying lies among her own flowers with her apron torn and her little jars rolling in the red mud. Nie's shadow slides off her like water off a lotus leaf and goes back towards the Wheel without her."
								],
								[
									"Liu Ying",
									"There's an antidote for everything in this garden. I wrote them all down once, on the other side of the labels. Then I stopped writing that side."
								],
								[
									"Yue Ling",
									"She was fourteen when we left her here, Lin Feng. Sorting jars on the floor.",
									"grieve"
								]
							],
							"ask": "What becomes of the Poison Saint?",
							"options": [
								{
									"id": "spare",
									"label": "Spare her",
									"desc": "Leave her alive in her garden, with every poison in it and the other side of the labels still in her head. Nie loses his blade, and the marsh keeps the one person who knows both halves of every plant.",
									"log": "Spared the Poison Saint among her flowers, and left her the other side of the labels to write.",
									"then": "redeemed",
									"after": [
										[
											"Liu Ying",
											"You're leaving me here again. With all of it."
										],
										[
											"Lin Feng",
											"Yes. And this time I will come back and ask how it is going."
										],
										[
											"Narrator",
											"When they look back from the duckboards she is sitting up among the beds with a brush, turning the first label over to write on the other side."
										]
									]
								},
								{
									"id": "end",
									"label": "End it",
									"desc": "Strike the last blow. No poison will leave this garden again, and no cure will either: everything the Hag knew, and everything Liu Ying learned, goes into the red water with her.",
									"log": "Ended the Poison Saint in the Hag's old garden, and everything she knew went with her.",
									"then": "fallen",
									"after": [
										[
											"Narrator",
											"It is quick. Afterwards Lin Feng burns the garden, and the smoke is sweet, and the toads fall silent for a li around."
										],
										[
											"Lin Feng",
											"I left her here at fourteen. That was the first blow, and it was mine.",
											"grieve"
										],
										[
											"Yue Ling",
											"Then carry it to the Wheel yourself, Lin Feng. Do not let Nie carry it in your place."
										]
									]
								}
							]
						}
					}
				]
			}
		}
	}
}

const STATES := {
	"tala": {
		"driven": [
			"The Herd Driven Home",
			"Lin Feng drove the starving apes out of their gorge and brought all forty-one horses home to the horse-folk."
		],
		"fed": [
			"The Apes Fed",
			"Lin Feng bought the apes a winter's grain, and they let the horse-folk's herd walk out of the gorge."
		],
		"free": [
			"The Herd Set Free",
			"Lin Feng opened the apes' pen, and the herd ran north towards the steppe, nobody's but its own."
		],
		"guardian": [
			"Guardian of the Foals",
			"Lin Feng fought the starving lynxes away from the foals in a blizzard pass on the Aurora Steppe."
		],
		"rider": [
			"Rider in the Blizzard",
			"Lin Feng led the herd through the blizzard by night, with Tala riding at his knee."
		],
		"steppe": [
			"The Steppe's Due",
			"Lin Feng let the lynxes take the weakest foals; the herd and the lynx cubs lived, and Tala grieved."
		],
		"well": [
			"The Buried Well",
			"Lin Feng and Tala dug out the horse-folk's old well on the drove road and woke it with water essence."
		],
		"bought": [
			"A Well in the Market",
			"Lin Feng bought the horse-folk the water of a Yanggu well, for good, from the merchants who wanted their herd."
		],
		"sold": [
			"The Herd Sold",
			"The horse-folk sold their herd to Yanggu's caravans to feed their children, and Tala pressed a share on Lin Feng."
		],
		"ally": [
			"Riders at the Wheel",
			"Tala's riders and their cloud-horses ride with Lin Feng against Nie the Unpaid at the Wheel."
		],
		"parted": [
			"Home to the Steppe",
			"Lin Feng told Tala she chose rightly; she laid the herd's debt down and went home to the steppe."
		]
	},
	"qiu_ye": {
		"expelled": [
			"Sent Down the Mountain",
			"Lin Feng took him to the Elder with the stolen pill; he was expelled, and left at dawn without looking back."
		],
		"secret": [
			"A Secret Kept",
			"Lin Feng said nothing of the stolen Foundation Pill, and Qiu Ye kept both the pill and his place."
		],
		"shared": [
			"In the Sweeper's Debt",
			"Lin Feng paid Alchemist Mo for the pill; Qiu Ye took it, humiliated, and swore to repay every stone."
		],
		"beaten": [
			"Beaten Among Barrows",
			"He fought Lin Feng for the saints' swords, lost, and fled into the barrows hating him twice over."
		],
		"doubt": [
			"A Hand Refused",
			"He would not take Lin Feng's hand among the barrows, but he left the saints' swords on their graves."
		],
		"freed": [
			"Free of the Sword",
			"Lin Feng broke the whispering sword; now Qiu Ye has only his own voice to listen to."
		],
		"possessed": [
			"The Sword's Voice",
			"He kept the cursed sword from the saint's barrow, and now it tells him where to go."
		],
		"friend": [
			"First Blood, No Grudge",
			"An honest duel among the saints' swords, honestly lost, and the start of a friendship."
		],
		"flattered": [
			"A Borrowed Victory",
			"Lin Feng let him win their duel among the barrows, and he believes the win was his."
		],
		"foe": [
			"Sworn Enemy",
			"Stopped from binding his father's shade at the bridge, he swore to destroy all that Lin Feng loves."
		],
		"turning": [
			"Turning Back",
			"He said goodbye to his father properly at the Naihe Bridge, heard one true thing, and broke."
		],
		"brother": [
			"Brother in All but Blood",
			"Lin Feng and Yue Ling walked him and his father to the bridge, and father and son spoke at last."
		],
		"distant": [
			"Courteous and Cool",
			"Lin Feng left father and son alone at the bridge, and Qiu Ye never quite forgave the absence."
		],
		"redeemed": [
			"Redeemed",
			"Given one more chance by the sweeper he envied, he took it, and stands with Lin Feng at the Wheel."
		],
		"fallen": [
			"Fallen",
			"Qiu Ye died in the sect courtyard where it all began, and Nie's shadow died with him."
		],
		"ally": [
			"At Lin Feng's Side",
			"Qiu Ye stands with Lin Feng against Nie at the Wheel, as an equal and by his own choice."
		],
		"parted": [
			"Parted Ways",
			"Qiu Ye went home alone to the house of Qiu at Cloudfoot, and their roads ran apart."
		]
	},
	"hu": {
		"village": [
			"Raised by Granny Wen",
			"Little Hu went down to Qingshi to grow up in Granny Wen's house, in Lin Feng's old corner by the stove."
		],
		"sect": [
			"Sweeping the steps",
			"Little Hu sweeps the sect's steps every morning, the same steps his father was sent down for want of a root."
		],
		"wild": [
			"Into the bamboo",
			"Little Hu ran into the bamboo with his father's gauntlet and a grudge, swearing to come back for Lin Feng."
		],
		"watchman": [
			"Fought beside you",
			"Fang Hu fought beside Lin Feng in the lanes of Qingshi and saw what his father had been up against."
		],
		"guardian": [
			"Keeper of the cradles",
			"Fang Hu kept the doors of Qingshi's sleeping newborns through the nights of the threads, Little Wan's among them."
		],
		"disciple": [
			"Lin Feng's student",
			"Fang Hu learned the sword from Lin Feng: every cut but the one that killed his father."
		],
		"seeker": [
			"His own road",
			"Fang Hu left the sect to find a road that was neither Lin Feng's nor his father's."
		],
		"spared": [
			"Spared in Qingshi",
			"Young Fang, beaten in the lanes of Qingshi, was let go before the elders came with the ox rope."
		],
		"jailed": [
			"In a magistrate's chains",
			"Young Fang went to a magistrate's cell by Lin Feng's hand, and has not forgotten whose hand it was."
		],
		"truth": [
			"Told the truth",
			"Fang Hu knows what his father was: the venom he took for the Blood Moon, and the venom he never poured."
		],
		"lie": [
			"Told a kind lie",
			"Lin Feng told Fang Hu his father died brave and clean, and Fang Hu believed every word of it."
		],
		"ferryman": [
			"Ferryman of Longmen",
			"On Lin Feng's word, Young Fang left Black Eel's rats for an honest oar on the Longmen ferries."
		],
		"foe": [
			"Sworn foe",
			"Young Fang broke out of his cell, ran Black Eel's rats, and slipped away from Lin Feng down the flood."
		],
		"ally": [
			"Ally at the Wheel",
			"Fang Hu goes to the Wheel of the Six Paths to stand beside Lin Feng against Nie the Unpaid."
		],
		"parted": [
			"Parted ways",
			"Fang Hu has the truth about his father and about the lie, and none of Lin Feng's reasons. He will not come to the Wheel."
		],
		"redeemed": [
			"Mending fences",
			"Spared a last time, Young Fang goes to the Wheel against Nie, and after it home to mend what his bandits broke."
		],
		"fallen": [
			"Under the bamboo",
			"Young Fang lies under the bamboo beside his father, the feud ended the way it began."
		]
	},
	"xu_lan": {
		"prisoner": [
			"Prisoner of the sect",
			"Given up to the sect's elders, she sits in silver in a cell under the Hall."
		],
		"fugitive": [
			"A fugitive",
			"Her chains cut, she slipped away before the elders came, and tells nobody whose daughter she is."
		],
		"ward": [
			"A ward under watch",
			"Elder Qing Xuan keeps her at the sect on Lin Feng's word, a silver cuff still on her wrist."
		],
		"hunted": [
			"Hunted",
			"Driven from her father's echo, she runs from the sect's hunters, the moon's blood untaught in her."
		],
		"heir": [
			"Her father's heir",
			"Her father's echo taught her how the moon's blood is poured, and she left the lake with his arts."
		],
		"unbound": [
			"Given the first blow",
			"Lin Feng gave her the first blow at her father's echo, to strike with her own hand."
		],
		"sheltered": [
			"Sheltered",
			"Lin Feng silenced her father's echo for her, and she mends nets on the lake shore in peace."
		],
		"trusted": [
			"Trusted",
			"Lin Feng let her face her father's echo alone, as the Elder's test asked."
		],
		"guarded": [
			"Guarded",
			"Lin Feng would not let her face her father's echo alone, and walked out beside her."
		],
		"foe": [
			"An enemy",
			"She escaped Youdu with her father's soul-lantern to raise the Blood Moon again in the north-east."
		],
		"forgiving": [
			"Forgave her father",
			"She let her father's shade go up to the Wheel, to be born again remembering nothing."
		],
		"just": [
			"Had her father judged",
			"She sent her father's shade to King Yama's court to answer for the nineteen children."
		],
		"ally": [
			"At your side",
			"She keeps her father's palace as a refuge for his orphans, and fights Nie beside Lin Feng."
		],
		"redeemed": [
			"Spared",
			"Beaten and spared under the red moon, she carries her father's lantern to the Wheel to fight Nie."
		],
		"fallen": [
			"Fallen",
			"She died in her father's throne hall under the red moon, the last of the Blood Moon's line."
		]
	},
	"liu_ying": {
		"apprentice": [
			"Mo's Apprentice",
			"Liu Ying grinds herbs at Alchemist Mo's cauldron, beside the disciples her toad venom once poisoned."
		],
		"home": [
			"Gone Home",
			"Lin Feng burned the Hag's grimoire and took Liu Ying home to the village that sold her for millet."
		],
		"witch": [
			"Witch of the Marsh",
			"Liu Ying kept the Hag's hut, grimoire and lotuses, and the Hag's customers still come knocking."
		],
		"bold": [
			"The Bold Cure",
			"Liu Ying woke eighteen of nineteen spore-sleepers with the Hag's venom; the nineteenth's heart stopped."
		],
		"careful": [
			"The Careful Cure",
			"Liu Ying woke all nineteen spore-sleepers slowly, with Lin Feng's Wood Essences instead of venom."
		],
		"healer": [
			"The Village Healer",
			"Lin Feng's pills woke Liu Ying's village, and the people who sold her call her their healer now."
		],
		"learner": [
			"Yue Ling's Pupil",
			"Yue Ling taught Liu Ying the glowcap cure; her village woke, lost its harvest, and sold nobody."
		],
		"rival": [
			"The Rival",
			"Beaten in Glowcap Vale before her customers, Liu Ying swore to be cleverer than Lin Feng's sword."
		],
		"dealer": [
			"Dealer in Poisons",
			"Lin Feng bought out Liu Ying's rot-bane, and she learned that the rich pay best for poison."
		],
		"physician": [
			"The Physician",
			"Liu Ying left the old pearl tree its heart, and heals the living with what is still alive."
		],
		"alchemist": [
			"The Alchemist",
			"A pearl tree died for Liu Ying's elixir: ten thousand doses, each an hour of stopped time for the dying."
		],
		"foe": [
			"Sworn Foe",
			"Liu Ying escaped Fangzhang on a thieving crane, and her grudge with Lin Feng stopped being a game."
		],
		"ally": [
			"Healer at the Wheel",
			"Liu Ying shut her marsh clinic to stand at the Wheel of the Six Paths as a healer beside Yue Ling."
		],
		"redeemed": [
			"The Other Side",
			"Spared among her poison beds, Liu Ying turned the labels over to write what each flower cures."
		],
		"fallen": [
			"Fallen",
			"The Poison Saint died in the Hag's old garden, and everything she knew went into the red water."
		]
	}
}

const EPILOGUE := {
	"tala": {
		"ally": "On the Aurora Steppe the horse-folk's herd runs a hundred strong. Every spring Tala turns the yearlings loose with the wild herds and keeps only the ones that come back, and nearly all of them come back.",
		"parted": "Tala keeps a single dun foal on the Aurora Steppe and no herd at all. Each autumn she rides to the Dawn Market to stand by the caravan lines, where an old grey still lifts his head at her whistle; then she rides home, and sleeps."
	},
	"qiu_ye": {
		"redeemed": "After the Wheel, Qiu Ye sweeps the sect's three hundred and ninety-one steps every dawn, badly at first and then well. The juniors whisper that the stern new sweeper is a fallen prince. He lets them.",
		"fallen": "The house of Qiu ends with its second son, on the flagstones where he once stood with a stolen pill. Lin Feng buries him at Cloudfoot beside his father, with his grandfather's sword, which hated halls.",
		"ally": "Qiu Ye stands at Lin Feng's left at the Wheel when Nie comes, then goes home to Cloudfoot and the house of Qiu. Every autumn he climbs up to the Conclave and demands a duel, to first blood. He keeps a tally.",
		"parted": "Qiu Ye keeps the house of Qiu at Cloudfoot alone, and keeps it well. Every new year a letter comes up the mountain in his sharp hand, three lines long and perfectly polite, and Lin Feng answers every one."
	},
	"hu": {
		"ally": "Fang Hu comes home from the Wheel with his father's gauntlet dented and his own name whole. Every spring he climbs into the bamboo, and he and Lin Feng sweep the leaves off Iron Fang's stone together.",
		"parted": "Fang Hu never comes back to Qingshi. Now and then a boatman speaks of a young swordsman with an iron gauntlet who guards travellers on the hill roads for nothing, and will not say his father's name.",
		"redeemed": "Young Fang rebuilds the east end of Qingshi post by post, and by spring the children call him Hu. His father's split gauntlet hangs over Granny Wen's door, where it holds up the washing line.",
		"fallen": "Two graves stand under the bamboo where the bandit camp was, father and son. Lin Feng sweeps them every spring, and some years he finds a bowl of rice on the smaller one that nobody admits to leaving."
	},
	"xu_lan": {
		"ally": "The moon over the north-east stays white. Xu Lan keeps her father's palace as a home for every child the sects would have burned for his blood, and none of them is ever taught to pour the moon.",
		"redeemed": "Xu Lan opens her father's lantern at the Wheel and walks home without him. She mends the palace roof one tile a day, in no hurry at all, and the moon over it stays white.",
		"fallen": "Xu Lan lies under the window of the room where her father kept her, where the moon comes past at night. It is white. Each Ghost Festival the sect sets one lantern more on the pond, and nobody says whose."
	},
	"liu_ying": {
		"ally": "Back from the Wheel, Liu Ying keeps the old hut in the Crimson Marsh as a clinic, and the queue on the duckboards never quite ends. Every jar on her shelves is labelled twice: what it kills, and what it cures.",
		"redeemed": "The poison garden in the Crimson Marsh still grows, but every label in it has two sides now. People come to Liu Ying at last, a few and then many, and she never tells anybody to be patient.",
		"fallen": "The Hag's hut stands empty in the Crimson Marsh again. The blood lotuses still come up every spring in the red water, and nobody is left who knows which of them heal and which of them kill."
	}
}

const CHAT := {
	"tala": [
		"Batu says his ribs only hurt when he laughs, so I have stopped being funny. Our mother says I never started.",
		"My grandmother says a horse is never owned, only kept, and only for as long as it agrees. She says the same about grandchildren.",
		"The old sword ghost watched the whole business from his rock and said nothing. Batu swears he winked. Ghosts do not wink, Batu."
	],
	"tala_steppe": [
		"Up here the wind takes the snow off the grass, and the horses do the rest. Down in the valleys it lies to their bellies, and no horse can dig through that.",
		"Shaman A Lan reads the lights as the sky's breath. My grandmother reads them as weather. They are both right more often than I would like.",
		"A foal is on its feet an hour after it is born and running by morning. It has to be. The steppe has never once waited for anybody to be ready."
	],
	"tala_plains": [
		"We trade horses at the Dawn Market for tea, salt and needles. My grandmother says the tea was never worth the horses. She drinks it all day anyway.",
		"Old Farmer Tian prays to the Lord of Millet. I pray to the grass. Between the two of us, we have most of the plain covered.",
		"Batu has grown a head taller than me since the gorge in Thunder Valley. He says it was the broken ribs knitting. Our mother says it was the eating."
	],
	"tala_end": [
		"Shitou's slowest post-horse is called Lightning. I have never met a horse so pleased with himself. I would like to be Lightning for one day.",
		"My grandmother says nobody ever looked back from a galloping horse. She has never galloped in her life. She looks back all the time.",
		"Yue Ling asked me what free means to the horse-folk. I told her: a horse that comes back when you whistle, and could have chosen not to."
	],
	"qiu_ye": [
		"This jian was my grandfather's. He was an inner disciple here when the sect still had twelve elders. My father was sent home at seventeen. I do not mean to be.",
		"Three years you swept round my feet in the practice yard. I knew your name the whole time. I made a point of never using it.",
		"Do not talk to me about that night. I know exactly what I owe, and to whom. I am still working out how to stand it."
	],
	"qiu_ye_grave": [
		"Every sword in this ground belonged to someone who swore to guard the Seal. Grandfather used to say a sword remembers its oath long after the hand forgets it.",
		"The Gravekeeper lets me stay if I sweep the paths between the barrows. I sweep them badly. He says the dead do not mind.",
		"I came here to find out what I am worth. The saints have not said. They are very good at keeping quiet."
	],
	"qiu_ye_springs": [
		"My father stood in this queue for a week and complained about his place in it every single day. A Qiu to the last. So, it seems, am I.",
		"The red lilies never have flowers and leaves at the same time, Meng Po says. Fathers and sons are the same. I learned it too late, or just in time. I have not decided which.",
		"I keep a stick of incense lit by the bridge. Nobody asked me to. Somebody ought to, for the ones whose sons did not come."
	],
	"qiu_ye_end": [
		"This courtyard is smaller than I remembered. Everything I envied is smaller than I remembered, except the steps. The steps are exactly as long.",
		"Grandfather's sword has been carried by an inner disciple, by a son the sect sent home, and by a thief. It does not seem to mind which. I am trying to learn that from it.",
		"You were the sweeper and I was the second son. It took me far too long to see they are the same job: keep going, and expect nobody to notice."
	],
	"little_hu": [
		"In winter he restrung the crossbows by the fire and hummed the whole time, badly. Nobody on the ridge dared tell him. I told him. He laughed.",
		"The gauntlet is too big. I will grow into it. He said I would grow into everything.",
		"I am not crying. It is the bamboo. It makes everybody's eyes run."
	],
	"hu_village": [
		"This gauntlet nearly fits now. When I was small it came up past my elbow, and I slept with it on anyway.",
		"The silk-masks dream out loud. One mumbled all night about a wife and a wheat field. He came here to rob, and now the threads make him guard the place.",
		"Qingshi smells of rice-smoke and wet stone. My father grew up in a village like this. He said the worst of a village is that everyone knows what you were refused."
	],
	"hu_longmen": [
		"When the carp clear the Dragon Gate they come down dragons, and nobody asks what the carp was before. I like that about this river.",
		"River air rusts iron. I oil the gauntlet every night. I could stop. I do not stop.",
		"Everyone on this quay is running from something upstream. The water, mostly. Some of us are running from older things."
	],
	"hu_end": [
		"Nie came to me in my father's voice. It got his words right and his laugh wrong. He laughed with his whole chest, like a door banging open.",
		"Everyone who meets me finds out whose son I am, sooner or later. I used to hate that. Now I think it is only the first half of the sentence.",
		"The bamboo has grown over the old camp. You would never know forty crossbows held that ridge. It is very quiet up there now."
	],
	"xu_lan": [
		"Nineteen years I watched the moon go past that window, and it was always red. Look at it now. I never knew it came in white.",
		"After a hunt he would sit where you are standing and say nothing at all, and pour the red into me until he could breathe again. Then he went to bed.",
		"Do not look at the silver like that. It is the only thing in this palace that ever kept its word to me."
	],
	"xu_lan_lake": [
		"When I lean over the water the lake shows me his face, and then mine. They are not as different as I would like.",
		"Nineteen children. I am nineteen. Some nights I count them on my fingers, run out of fingers and start again.",
		"Keeper Lan Jing says every face that bends over this lake leaves a little of its light in it. I wonder what mine is leaving."
	],
	"xu_lan_youdu": [
		"The Magistrate gave me the lantern. The empty ones go to the family, he says. It weighs nothing at all. I had not expected that.",
		"Down here nobody steps off the path when I pass. The dead have no idea whose daughter I am, and would not mind if they did.",
		"I asked the Magistrate whether any of the nineteen are waiting down here. He said none of them are. He said it kindly, the way you tell a child."
	],
	"xu_lan_end": [
		"The moon over the palace is white. I still go out at night to check. It is an old habit, for a girl who only ever had one window.",
		"When this is over I am going to make the throne hall a kitchen. It has the best chimney in the north-east, and nobody will ever sit on that chair again.",
		"Nie whispers like a ledger: owed, owed, owed. My father listened to a voice like that for three hundred years. I have stopped listening."
	],
	"liu_ying": [
		"Black jars kill. White jars kill slower. Green jars are for coughs. She mixed them up once, on purpose, for a man who owed her money.",
		"Blood lotus: eat the root and you are dead by morning; steep the petals and you live to complain about it. Everything is like that, if you ask it properly.",
		"She never told me her name. I asked once. She said names were for people somebody calls."
	],
	"liu_ying_vale": [
		"Glowcaps are good to eat, if you don't mind dreaming you're a candle for a week.",
		"The Mother of Spores isn't wicked. She's a mother. She puts everybody to bed, tired or not.",
		"I breathed one of the vale's dreams. I was warm, and somebody was calling me in for supper. I woke up furious. Nobody ever called me in for supper."
	],
	"liu_ying_isle": [
		"Cinnabar toads. Every elixir an emperor ever drank had cinnabar in it, and every emperor who drank one is dead. Draw your own conclusions.",
		"The immortals grow herbs here I'd only ever seen pressed flat in a book. Alive, they smell of pepper and old rain.",
		"They say a pearl tree takes a thousand years to grow its heart. I've never waited a thousand years for anything. I barely wait for tea."
	],
	"liu_ying_end": [
		"Every plant in this marsh is two plants: what it kills, and what it cures. You only have to read the label twice.",
		"Shennong tasted a hundred herbs and was poisoned seventy times in one day. That is how anybody ever learned anything.",
		"She kept the blood lotuses when there was nobody left to heal. I used to think she was mad. Now I think she was waiting for somebody to knock."
	]
}
