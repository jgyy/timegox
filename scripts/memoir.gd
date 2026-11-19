class_name Memoir
extends RefCounted
## In their own words (the Higher Sky release): the story told in the first person by the people it is about.
##
## For thirty-seven chapters the story was told by a narrator who stood a little behind Lin Feng's
## shoulder and called him "he".  Nobody in it ever said "I" for longer than a line of dialogue.  A
## **page** is one of the three people the story is about (`who`: the hero, Yue Ling, Elder Qing Xuan)
## saying, afterwards and in the first person, what a chapter was from where they stood.
##
##   * a page is written when its step is done (`after`; `written`, asked from Game.advance), once;
##   * some pages belong to one branch of the story only (`if`: a better and the way the bout went,
##     betters.gd): somebody who lost to Fuchai writes a different page from somebody who did not;
##   * with a window it is read out as a scene the next time he stands free (Main._page_scene), and
##     any page written can be read again on Esc > In Their Own Words; with no window it is only
##     written, so the bot's journey is what it was;
##   * a page of somebody who is dead by his hand is never written (crime.gd: the dead stay dead).
##
## **How they are written.**  Lin Feng says "I" and never says what he is (the hero is a man or a woman:
## nothing here may say which).  Yue Ling writes *to* him: "you".  The Elder says "the child".  Every
## line fits the dialogue box, and is spoken by its writer under the name they stand by, so that
## `Crime.mute` can tell the dead from the living.  A page changes no number and nothing asks for one.

const WHO := {"lin": "Lin Feng", "yue": "Yue Ling", "elder": "Elder Qing Xuan"}
## whose death (an entity id) keeps a page from being written
const WHO_ENT := {"elder": "elder", "yue": "yue_ling"}

const PAGES := {
	"p01_broom": {"n": "The Broom", "who": "lin", "after": "s_break1", "lines": [
		"I swept the steps of Azure Cloud Sect for three years before anybody asked me to do anything else. I want that written first, because everything after it sounds like somebody else.",
		"The Elder sent me into the bamboo for herbs. I came back with herbs, a bandit's sabre, and a girl who had been tied to a post and was angrier about it than frightened.",
		"I did not know what a Nine Heavens root was. I knew the broom. I still think the broom was the better teacher: it never once told me I was special."]},
	"p01_post": {"n": "The Post in the Bamboo", "who": "yue", "after": "s_yue", "lines": [
		"You cut the rope and then stood there holding the two ends as if you ought to give them back to somebody.",
		"I have been asked since what I thought of you, that first day. I thought: this one apologises to bandits. I thought: I had better go along, or it will be dead by the marsh.",
		"I did not think anything else. I want you to know that. Everything else I thought came later, and slowly, and was my own."]},
	"p01_gate": {"n": "What I Did Not Tell", "who": "elder", "after": "s_break4", "lines": [
		"I have been asked why I kept the child sweeping. The answer I gave was humility. The true answer is that a sweeper is not looked at, and I knew who was looking.",
		"I sent a child of sixteen against the Blood Moon Palace with a herb-knife and a girl I did not then understand. I would do it again. I do not expect to be forgiven for that, and have not asked.",
		"When the tribulation came down I stood at the hall door and counted. I have counted nineteen of those. This was the first I counted to the end."]},
	"p02_emperor": {"n": "The Emperor's Chair", "who": "lin", "after": "s_break6", "lines": [
		"There was a dragon under the sea in chains, and I let him out because the chains looked like the ones on the post in the bamboo. That is the whole of my reasoning. People have since written essays about it.",
		"The Jade Emperor fell. I was there, and I am told I did it. What I remember is how tired he looked, and that the chair was too big for anybody.",
		"Afterwards the sky had a crack in it. Nobody tells you, when you are told to climb, that the thing at the top is holding something up."]},
	"p03_hollow": {"n": "A Sky with Nobody In It", "who": "yue", "after": "s_break8", "lines": [
		"You asked me, at the Mirror Lake, why I would not look in it. I said the light was bad. The light was very good.",
		"We stood at the Founder's grave among all those swords and you read the stone twice. I knew the hand that cut it. I did not yet know why.",
		"Heaven was hollow, the Elder said, and everybody looked up. I looked at you. You were working out who would have to sweep it."]},
	"p04_ledger": {"n": "My Name in Jade Ink", "who": "lin", "after": "s_break9", "lines": [
		"Somebody had been writing names in a ledger, and mine was the twentieth. The nineteen before me were children. I met them. They had been waiting in an orchard for somebody to tell them it was over.",
		"I am not a clever person. But I can tell when a sum has been done on people, and I found I minded it more than I had minded the Emperor.",
		"We closed the book. I said I would go home and sweep the steps, and I meant it, and for a while I did."]},
	"p05_sky": {"n": "Counting Stars at Noon", "who": "elder", "after": "s_break10", "lines": [
		"The stars fell at noon. I had read that the Court propped the sky with stolen years. I had not thought through what would happen when an honest child stopped the stealing.",
		"The dragon the child freed held the eastern pillar up out of plain gratitude. I have taught the precepts for seventy years, and that is the best argument for kindness I have ever seen, and it was made by a fish.",
		"I am an old man who was wrong about the size of things. I say so here because the child will not say it for me."]},
	"p06_maple": {"n": "Two Graves under a Maple", "who": "lin", "after": "s_break11", "lines": [
		"The Elder told me where he found me: under a maple in the gorge, beside two graves with no names on them. He told me on the night the dead stood in a queue at our gate, which is the kind of timing he has.",
		"I turned the Wheel so that the dead could go on. I looked for two faces in that queue the whole time. I would not have known them. I looked anyway.",
		"I do not know who they were. I know somebody dug two graves properly, with a baby to carry. I have decided that is enough to know about a person."]},
	"p07_thread": {"n": "Unpicking", "who": "yue", "after": "s_break12", "lines": [
		"The Weaver had sewn the world into squares so that each could be harvested by itself. You unpicked one seam and the whole land lay down like a dog that has been let off a chain.",
		"She was spinning the newly born into thread. Little Wan was on the spindle. I have never seen you angry before or since, and I hope I never do again. You were very quiet.",
		"Afterwards there were no gates. You walked from the sect to the sea to see if it was true, and came back and told me, as if I had not walked beside you the whole way."]},
	"p08_river": {"n": "The Night No Magpies Came", "who": "lin", "after": "s_break13", "lines": [
		"On the seventh night of the seventh month we all climbed on the hall roof to watch the magpies make their bridge. None came. The river in the sky came instead, into our lotus pond.",
		"It is the oldest border there is: one stroke of a hairpin between two people. I have broken a great many borders. That was the only one I was ashamed to be late for.",
		"Yue Ling stood on the bridge when it held, and did not say anything, and I did not ask. I have learned which of her silences are doors and which are walls."]},
	"p09_sun": {"n": "Nine Days of Noon", "who": "elder", "after": "s_break14", "lines": [
		"The sun stood still for nine days. The millet scorched in the east and it was night without end in the west, and the child went to speak to the sun's mother. Not to fight her. To speak.",
		"I had trained a sword. I had not noticed, in all those mornings of sweeping, that I was also training somebody who asks a frightened thing what frightened it.",
		"The sun and the moon agreed to take turns. It is the most sensible treaty I know of, and it was written by two people who are not yet thirty."]},
	"p10_map": {"n": "The Map Was Wrong", "who": "lin", "after": "s_break15", "lines": [
		"Archivist Lan came running in her nightcap to say the great map was wrong. The rivers had moved. I said perhaps the map had been wrong, and the rivers were only now allowed to say so.",
		"The Court had pinned the land flat with nine cauldrons, so that every square could be taxed in years. We took the pins out. Land that is let lie in its own shape floods. Nobody mentions that part of freedom.",
		"So I learned about dykes from a man who had been drowning for four thousand years for building them badly. He was a good teacher. The ones who got it wrong usually are."]},
	"p11_ladder": {"n": "Climbing Up to Complain", "who": "yue", "after": "s_break16", "lines": [
		"A tree came up in the night west of the sect, wider than the hall. The Elder said people used to climb it to complain to the gods, and you said: good. You said it like somebody finding a broom where it ought to be.",
		"There were heavens above and springs below, and people in all of them, and every one of them had been told the others were dangerous.",
		"You swept the first hundred steps of it every evening. I asked why. You said somebody was going to slip. That is all there is to you, and it is a great deal."]},
	"p12_tide": {"n": "The Sea Went Out", "who": "lin", "after": "s_break17", "lines": [
		"A fishing boat came up our road on an ox-cart. The sea had gone out in the night and not come back. I have been told many strange things at that gate, and that was the one that made me put the broom down.",
		"East of the east there is a ravine with no bottom that everything pours into and that never fills. I stood on the edge of it. It did not feel like an ending. It felt like a breath being held.",
		"Everything that goes in comes back. I have had that explained to me by sages. I understood it when the tide came in over my shoes."]},
	"p13_gates": {"n": "No Head of the Table", "who": "elder", "after": "s_break18", "lines": [
		"The peoples of four realms met on our mountain with no Court at the head of the table, because there was no head of the table. I had the benches made round. It was the child's idea. I took the credit for a week.",
		"Eight gates of gold light went up over a war god's grave. The child was told to open four. I am told the choice of which four said a good deal. I have not asked which, and I know.",
		"I taught that power is climbed. I watched it being set down in the middle of a table, between the dishes, for whoever needed it passed to them."]},
	"p14_karma": {"n": "Threads on My Wrists", "who": "lin", "after": "s_break19", "lines": [
		"I found threads on my wrists one evening, fine as spider silk and warm, all pulling south-west. Everything I had set moving had come to be settled. Most of it was light. A few of the threads were people.",
		"There was a boy with a kitchen knife once, and a thief in a storeroom, and a girl calling for her horses. I had done something about each in a hurry and gone on. Each of them had gone on being a person.",
		"Whatever fed on the debts nobody paid, at the Wheel, it had my face on it for a moment. I did not strike that first. I am told that is why the rest went as it did."]},
	"p15_woven": {"n": "The Second Cup", "who": "yue", "after": "s_break20", "lines": [
		"Disciple Han set out the tea and frowned at the second cup and asked who it was for. It had been mine for ten years.",
		"I was woven, not born. The Founder made me out of the Seal's own lotus so that whoever carried the root would not face the end alone. Everything I did went into your column. When nothing was owed any more, the world began to put me away.",
		"You went and found six things that had happened to me and nobody else, and gave them back, and people remembered my name. I had never had a thread. You tied one. I have not thanked you, and this is not that either."]},
	"p16_year": {"n": "Red Paper", "who": "lin", "after": "s_break21", "lines": [
		"It was the first New Year the world had had time for. I had saved it a great many times by then, and had never once seen what it does when left alone for an evening. It makes dumplings.",
		"Something that eats the old year came down, and a night that would not end. We drove it out with red paper and noise. I have fought gods. I had more help that night than in any of those, and most of it was under ten.",
		"I stayed up for the vigil. Yue Ling fell asleep on my shoulder at the third watch, and I did not move until dawn, and my arm has never been the same."]},
	"p17_spring": {"n": "Spring Does Not Come by Itself", "who": "elder", "after": "s_break22", "lines": [
		"Spring does not come by itself. The ox must be whipped, the frost sent home, the first thunder drummed up. I knew the rites from books. The child knew them from having cleared the ground.",
		"At Qingming the child swept two graves in the Maple Gorge with no names on them, and set out three cups, and did not speak.",
		"I stood a long way back. There are things a teacher is for and things a teacher is in the way of, and it has taken me until now to tell them apart."]},
	"p18_fire": {"n": "One Coal from Each", "who": "yue", "after": "s_break23", "lines": [
		"The fire of the whole land was tired, and could not be put out and lit new, because every hearth had sworn never to let its own die. So you went and begged a coal from each. Begged. You could have taken them.",
		"Six hearths, six tables. You sat at each and ate what was put in front of you, and I watched an old woman in a felt tent decide about you over a bowl of milk tea.",
		"When the six coals were one fire I saw your face in the light of it. You looked like somebody who has been let in."]},
	"p19_works": {"n": "The Well-Sweep", "who": "lin", "after": "s_break24", "lines": [
		"The land began to make things: wheels that ground a valley's rice, hammers that never tired. They did not stop when people went home. An old gardener would not use a well-sweep and would not say he was wrong.",
		"I was asked three times what should be done with the machines. I had opinions. Then I built one with my own hands and had fewer.",
		"There was a dancer out in the sand that somebody had once taken apart in front of a king. It had been building itself a heart out of clockwork. I knew something about being made for a purpose and wanting a heart anyway. She was standing next to me."]},
	"p20_hollow": {"n": "What a Hollow Is For", "who": "elder", "after": "s_break25", "lines": [
		"The works ate ore, and the land dug for it, and tipped what it dug into the nearest hole. The wells went dry. A well is a hollow that water comes to. I had read that sentence fifty times and never once been thirsty reading it.",
		"The child went down into every cave in the land. I am told there is a woodcutter under one hill who has been watching a single game of weiqi since before the sect stood. The child sat and watched a few moves.",
		"What is an empty place for? I gave lectures on it. The child came back with wet boots and said: it is for what comes to it. I have stopped giving the lecture."]},
	"p21_arms": {"n": "Eight Weapons", "who": "lin", "after": "s_break26", "lines": [
		"What was dug was smelted, what was smelted was cast, and what came out of the moulds was blades. Nobody had ordered them. The racks in our armoury were empty and the boys were shooting at each other's hats.",
		"I have carried eight weapons since the Dragon Palace. I went to the people who knew what each was for. The best of them was an archer whose last lesson was how not to shoot.",
		"I was asked what a weapon is for. I have used one every day of this story, and it was the hardest question anybody put to me in it."]},
	"p22_roads": {"n": "Why Nobody Arrived", "who": "yue", "after": "s_break27", "lines": [
		"You climbed every mountain in the land hand over hand, and then came down each one under a kite, grinning. I have known you through the fall of heaven. I had not seen you grin before.",
		"There are people who live between the towns: a woodcutter, a herb-gatherer, a hermit who would rather not. You learned all their names. You always learn the names.",
		"A man on the height in Thunder Valley had ridden the wind once and was waiting for it to come back. You sat with him. You said afterwards that waiting well is a skill, and looked at me, and I pretended not to see."]},
	"p23_host": {"n": "Companies of a Hundred", "who": "lin", "after": "s_break28", "lines": [
		"I had fought alone, or with her, for twenty-two chapters of my life. Then somebody handed me companies of a hundred, each of them somebody's whole village, and a drum.",
		"One order to a drumbeat. Nothing in it is luck. If it goes wrong it is because I read the dust wrong, and a hundred people are a hundred people.",
		"I won those fields. I do not like having won them. I would like that written down next to the victories, in the same size of letter."]},
	"p24_horse": {"n": "The First Thing I Lost To", "who": "lin", "after": "s_break29", "lines": [
		"There was a tide, and I drew on it. Yue Ling says my face was a study. It went over us and on up the beach and set us down among the driftwood, quite gently, with a crab in my sleeve.",
		"I had not lost before. Not properly. I had been knocked down and carried home and had got up and won. This was different: there was no second time in which it would go better.",
		"An old man on the frontier lost a horse once and would not say if that was bad luck. I thought he was being clever. He was being accurate."]},
	"p25_town": {"n": "Eleven Tiles by Nine", "who": "elder", "after": "s_break30", "lines": [
		"The child answers for a town now: eleven tiles by nine on the east shoulder of the mountain. I went to look at it. There is a steward, and lanes, and a family who came because they were asked.",
		"I governed a sect for seventy years by standing at the top of some steps. The child governs by going to the steward's table and asking what is needed and then paying for it.",
		"I asked whose name was to be over the hall. I will not write the answer here. But I slept well that night, for the first time since the stars fell."]},
	"p26_springs": {"n": "Sitting in Hot Water", "who": "yue", "after": "s_break31", "lines": [
		"The whole land had sat still too long, and a physician was putting the sick into hot springs and having them move like bears and cranes. You were very bad at the crane.",
		"You sat in a spring up on a peak for an hour with your hair wet and did nothing at all, and I thought: there. That is what all of it was for. Not the sky. This.",
		"A book of his was nearly burned, and you were angrier about the book than about most of the gods. I have stopped being surprised by what you are angry about. It is always the right thing."]},
	"p27_sack": {"n": "Sixty Jin", "who": "lin", "after": "s_break32", "lines": [
		"I can carry sixty jin. A little more for each great realm, which nobody tells you is what the realms are for. I found that out by carrying timber up a hill until my knees spoke.",
		"There was an old man burning charcoal whose cart was taken for half a bolt of gauze, and a monk with a cloth sack who set it down whenever he was asked what the Way was.",
		"I was given a ring at the end of it that holds a great deal. I still carry the first load on my back. You should know what a thing weighs before you are excused from the weight."]},
	"p28_grass": {"n": "Still Going On Somewhere", "who": "elder", "after": "s_break33", "lines": [
		"Everything the child ever did is still going on somewhere. A general won a field because of a kindness he had forgotten. An old man knotted the grass under his enemy's horse.",
		"The towns are weighed now, each by what the journey did in its streets. I looked at the tally for Qingshi. It is not all to the good. The child read it standing up, and went down to the village the same day.",
		"I have been owed, in my life, for a few kindnesses. I had thought it vulgar to keep count. I see now that the land keeps it for you, whether you are vulgar or not."]},
	"p29_chimney": {"n": "Where a Thing Belongs", "who": "yue", "after": "s_break34", "lines": [
		"A man was told his chimney was crooked and his firewood too near it, and thanked nobody, and after the fire he feasted the neighbours who had carried water. Nobody set a place for the one who had warned him.",
		"You spent that season moving other people's furniture. A mirror that looked at a bed. A bed in a line with a door. People are particular. You were more patient about it than you were with the Jade Emperor.",
		"I know which side of the mat I sit on. I have known for some time. I am only telling you that I know."]},
	"p30_net": {"n": "Three Sides Open", "who": "lin", "after": "s_break35", "lines": [
		"I am strong enough now that anybody I meet on a road is alive because I have not decided otherwise. That is not a comfortable thing to know about yourself at a noodle stall.",
		"A king once found a fowler with nets on four sides and took three of them down. Anything that wanted to go left could go left. I thought about that for the whole of a chapter.",
		"A lawgiver was turned from an inn door by his own law. A judge bound his own hands. I went and looked at the forbidden shelf, to know where it was, and left it shut. I want that on the record too."]},
	"p31_shoe": {"n": "Who a Door Is Cut For", "who": "elder", "after": "s_break36", "lines": [
		"There is a people twice our height. They had been coming into our towns for years, bending. Nobody had thought about the doors. A man once cut his feet to fit a pair of shoes, and we had been asking that of them.",
		"The child had every lintel in the land raised. It took a season. I am short, and it cost me nothing, which I believe is the point.",
		"I asked one of them how the old doors had been. He said: we got used to it. I have heard that sentence all my life and never once heard what it costs."]},
	"p32_mirror": {"n": "Two Halves", "who": "yue", "after": "s_break37", "lines": [
		"A husband and wife broke a mirror in two when their country fell, and each kept half, to know the other by. That was the season's story. You told it to me badly, twice, and then stopped in the middle the third time.",
		"There are things one of us has done that the other minds. You found that out. You found out, too, that some can be put right and some can only be said.",
		"I was made to be half of something. I have decided to be a whole thing that chooses to stand next to another whole thing. It comes to nearly the same, to look at. It is not the same at all."]},
	"p33_pestle": {"n": "An Iron Bar and a River Stone", "who": "lin", "after": "s_break38", "lines": [
		"An old woman was grinding an iron pestle down to a needle on a stone by a river. A boy who would be a great poet saw her and went back to school. That is the story. I went and found the stone.",
		"Everything I have, I was given: the root, the Seal, her. That season I learned what a hand knows that nobody gave it. It knows about one thing, and only after about the ten-thousandth time.",
		"People work for something. A bowl, a roof, a daughter's dowry. I had saved the sky and never once asked the noodle-seller what he was saving for. He told me. It took an hour and was worth it."]},
	"p34_road": {"n": "Sleeves Kept Light", "who": "elder", "after": "s_break39", "lines": [
		"The land is full of small things a hand could close on. A comb on a sill. A coin in the road, new every morning. The child could take the lot and nobody could say a word.",
		"A governor was brought gold by night and told nobody would know. He counted four who knew: heaven, earth, the giver, himself. I taught that story for years as a lesson in fear. It is a lesson in arithmetic.",
		"I watched the child carry a dropped shoe the length of Qingshi to a door and knock. That is the whole of the precepts. I could have saved a great deal of paper."]},
	"p35_block": {"n": "What the Stone Says", "who": "lin", "after": "s_break40", "lines": [
		"There is a stone at the gate that measures a spirit root, and what it says of mine I will not write, because it does not matter and that took me a chapter to learn.",
		"A boy made verses at five and was led from door to door until there were none left in him. A man lost both feet for saying a stone was jade, and was right. The stone at the gate measures. It does not know.",
		"Every Dao I walk has a form now, and I can stand in a field and do it for nobody. I had never done anything for nobody before. It is the nearest I have come to sweeping since I put the broom down."]},
	"p36_fish": {"n": "Turned Once", "who": "yue", "after": "s_break41", "lines": [
		"You can part a wood with one stroke now. I watched you learn, that season, to take one stalk and leave the one beside it. It was much the harder thing and you swore more.",
		"You cooked a small fish. You turned it once. It came apart the first three times because you could not leave it alone, and I ate all three and said they were good, and they were not.",
		"A strong hand is for stopping. I did not tell you that. Auntie Zhou did, with a ladle, in the kitchen door. I only want it written that I had been thinking it for nine years."]},
	"p37_round": {"n": "Forty Techniques", "who": "lin", "after": "s_break42", "lines": [
		"The pines under our east wall burned for a night and forty of us threw everything we knew at it. I threw the most. I am fairly sure I made it worse. It went out because it rained.",
		"A man carried firewood to put out a fire. A minister sent his flood next door and called that skill. A cook burned the one log in the province that could sing. Each had something in his hand and never asked what it meets.",
		"There is green under the burnt pines already, a finger high. I knelt in it next to the Elder with my sleeves tied back. Neither of us said anything clever. It was one of the better mornings."]},
	# ---- Part XXXVIII: A Sky Above the Sky.  The chapter is told in pages as much as in conversation, and which
	# pages are written depends on how each bout went (betters.gd)
	"p38_word": {"n": "There Is Always a Higher Sky", "who": "elder", "after": "s_p38_home", "lines": [
		"Three have come down who are above the child. Not gods. I could have borne gods. People, who started where we all start and simply went further.",
		"I have told every disciple for seventy years that above each sky there is a sky. I find I told it as a comfort to the weak. I never thought I would have to say it to the strongest thing I ever raised.",
		"I did not say: you will lose. I said: go and meet them. It is the most frightened I have been since the tribulation, and I poured the tea without spilling it."]},
	"p38_fuchai_down_lin": {"n": "The Stables of Wu", "who": "lin", "after": "s_p38_fuchai", "if": ["fuchai", "down"], "lines": [
		"I lost. I want to say it plainly, in my own hand, before anybody says it kindly. He stood realms above me and it took him less time than it takes to tell.",
		"I was not carried home. I was handed a fork. For three days I mucked out the stables of the King of Wu, and held his stirrup when he mounted, and half of everything I carried went into a chest with his seal on it.",
		"I will tell you what the worst of it was. I was good at it. Three years with a broom. He looked at the yard on the second morning and said: this one has done it before. And I was proud. I was proud, in his stable, of that."]},
	"p38_fuchai_down_yue": {"n": "What I Did for Three Days", "who": "yue", "after": "s_p38_fuchai", "if": ["fuchai", "down"], "lines": [
		"They did not want me. I was told so. A king keeps grooms; he has no use for whatever I am. So for three days I sat on the wall outside and watched you carry water.",
		"I have seen you beaten bloody and I have seen you hold up the sky. I had never seen you take an order from somebody who did not care if you lived. You said: yes. You said it properly. I bit through my sleeve.",
		"When you came out you smelled of horse and you would not look at me. I am writing this so that you know I was not ashamed of you for one breath of it. I was ashamed of the wall I sat on."]},
	"p38_fuchai_up_lin": {"n": "The Day I Did Not Lose", "who": "lin", "after": "s_p38_spared", "if": ["fuchai", "up"], "lines": [
		"He decides an hour before he strikes. That is the whole secret, and it is not much of one. Whatever you do in front of him he is answering something earlier. If you know the hour, there is a door in it.",
		"I beat a king who stood realms above me. People will say: the root. It was not the root. It was standing in a yard being looked through by his grooms until I had seen what there was to see.",
		"Goujian asked me how it felt. I said I did not know yet. He said that was the right answer, and that he had spent twenty years finding out what the other one felt like."]},
	"p38_pang_down_lin": {"n": "The Knee", "who": "lin", "after": "s_p38_pang", "if": ["pang_juan", "down"], "lines": [
		"He did not kill me. He is not a man who wastes a thing he might want to look at later. He did to my knee what he once did to both of his fellow student's, and wiped the blade, and said I would walk.",
		"I walk. It tells me when it is going to rain. I strike a little less hard than I did and I am slower to the first blow, and I know exactly by how much, because I have counted.",
		"I had thought being beaten was a thing that happened to you on a day. It is a thing you carry up stairs afterwards."]},
	"p38_pang_down_yue": {"n": "Fewer Fires", "who": "yue", "after": "s_p38_stoves", "if": ["pang_juan", "down"], "lines": [
		"I bound the knee. I have mended you more times than I have counted, and it was the first time what I closed did not close all the way. I said it would. I do not lie to you often. I am writing down that I did.",
		"The man in the cart told you to cook. A hundred thousand fires the first night, fifty thousand the next, thirty the third, so that somebody counting would think you were running away.",
		"You lit two fires, and sat by the second with your leg out straight, and laughed for the first time since. You said: he counts. You said it the way you used to say where the broom was kept."]},
	"p38_pang_up_lin": {"n": "A General Who Counts", "who": "lin", "after": "s_p38_cart", "if": ["pang_juan", "up"], "lines": [
		"He counts everything. Fires, tents, hoofprints. I let him count me, and showed him a little less than there was. He had a number for me before we began, and the number was wrong.",
		"I beat him. He stood realms above me, and was quicker, and better read. He lost because he was certain. I have been certain. I know that door from the inside.",
		"Sun Bin did not thank me. He looked at my knees, both of them, for some time, and then asked whether I would push the cart as far as the turning."]},
	"p38_lian_down_lin": {"n": "On My Back in a Lane", "who": "lin", "after": "s_p38_lian", "if": ["lian_po", "down"], "lines": [
		"I could have gone round by the ditch. Everybody goes round by the ditch. He is an old general with forty wounds who wants to be told he matters, and I drew a sword on that.",
		"He put me on my back in the lane with a town looking on. That is not the part I mind. The part I mind is that I picked the fight, and that the wolves heard two tigers at it and came down that night.",
		"Lin Xiangru once faced a king down over a piece of jade and then turned his carriage aside for this same man. I had heard that as a story about meekness. It is a story about knowing which fights are yours."]},
	"p38_lian_down_yue": {"n": "The Ditch", "who": "yue", "after": "s_p38_lian", "if": ["lian_po", "down"], "lines": [
		"I said: go round. I said it twice. You have listened to me about gods and seas and what to do with heaven, and you would not listen to me about a ditch.",
		"It was not him you were fighting. You had stood under three of them by then and you wanted, very badly, to stand in a road and have it be yours. I know. I have wanted to be let through a door too.",
		"I am not angry now. I was. I went and helped an old woman pick up her onions out of the lane while you lay there, and she said: yours? And I said yes, and it was not all pride."]},
	"p38_lian_up_lin": {"n": "Thorns", "who": "lin", "after": "s_p38_rods", "if": ["lian_po", "up"], "how": ["lian_po", ["gave"]], "lines": [
		"I put up my sword and went round by the ditch. He shouted after me. It was the hardest stroke I have made in thirty-eight chapters and it does not look like anything.",
		"He came to the mouth of the cave stripped to the waist with a bundle of thorn rods on his back, and knelt, and asked to be beaten. An old man with forty wounds, all in front.",
		"I did not beat him. I gave him tea. It turns out that not everybody who stands above you is in your way. Some of them are only standing there, hoping to be asked in."]},
	# (the Red Seal release: the journey that beat him writes of that, and not of a ditch it never went by)
	"p38_lian_won_lin": {"n": "Thorns, All the Same", "who": "lin", "after": "s_p38_rods", "if": ["lian_po", "up"], "how": ["lian_po", ["won"]], "lines": [
		"I beat him. In his own lane, with the carters looking on. It was the best fighting I have done and I knew before he had finished falling that it was the wrong thing to have been good at.",
		"He came to the mouth of the cave stripped to the waist with a bundle of thorn rods on his back, and knelt, and asked to be beaten. An old man with forty wounds, all in front.",
		"I did not beat him a second time. I gave him tea. The minister went round by the ditch for ten years and got a friend. I went through, and got a lane. I can count."]},
	"p38_low": {"n": "Why the Sea Is King", "who": "yue", "after": "s_p38_end", "lines": [
		"The sea is king of a hundred valleys because it lies below them. The Elder read you that, and you nodded as if you had always known, and you had not. You learned it this season, from below, and I watched.",
		"I have followed somebody who could not lose. I did not know until now that I had been waiting to see what you were when you could.",
		"You are the same. That is all I have to report. You came back, each time, and asked the next person their name. I had hoped. It is another thing to know."]},
	# ---- Part XXXIX: The Name That Can Be Named (the Red Seal release)
	"p39_ring": {"n": "What I Said in the Yard", "who": "lin", "after": "s_p39_outer", "lines": [
		"I said something across a ring today. I had never done that. I have fought things with nine heads and never once told one of them what I thought of its footwork.",
		"It worked, or it did not: I am not writing about that. I am writing that I had it ready. It was sitting there, whole, with an edge on it. I have been polite for nine years and it turns out I was keeping a list.",
		"Yue Ling says everybody has a list. She says the difference is whether you read it out. I think the difference is who you read it to. I should not like to read mine to somebody it would stay with."]},
	"p39_paper": {"n": "A Paper with My Name on It", "who": "yue", "after": "s_p39_end", "lines": [
		"You carried the first three as if they were hot. I watched you put them inside your robe, and take them out, and put them in your sleeve instead. You have never owned anything you were afraid of creasing.",
		"I thought it would change you. That is the truth, and I am writing it here because I did not say it. I thought somebody told in red ink what he is might begin to be that, and stop being the other things.",
		"You kept the blank one. Of all of them. I knew then. I have a paper too, you know, and mine says Proven, and I looked at it tonight, and I find I like yours better."]},
	"p39_last": {"n": "The Top Ten Steps", "who": "elder", "after": "s_break44", "lines": [
		"The child has a blank paper with a seal on it, and I have a broom. I swept the top ten steps this evening. It took me an hour, and the corners are still wrong. I have ruled this mountain for seventy years and I cannot sweep it.",
		"A registrar asked me what the child is. I have had a month to think. The child is whoever did the steps before I was awake, every morning, for three years, when nobody was keeping a column. Everything since has been a guest in that house.",
		"I am an old man, and I was certified today, by a boy, in nothing. I should like it known that I have never held a grade I was prouder of."]},
	# ---- Part XL: Three in the Morning (the Two Roads release)
	"p40_leaves": {"n": "The Loser Pours", "who": "lin", "after": "s_p40_du", "lines": [
		"I sat down at a table today to play at something. I am trying to remember when I last did a thing that nothing depended on. I think I was nine, and it was a stream, and a boat made of a leaf.",
		"I was bad at it for the whole of the first hand, and nobody died. Hall Master Du told me I was holding the leaves like a sword. I was. I do not know another way to hold anything.",
		"Then I waited, instead of striking, and it came to me. I won by doing less. I have written that down so that I can look at it again, because I do not yet believe it."]},
	"p40_two": {"n": "Two Buckets", "who": "yue", "after": "s_p40_two", "lines": [
		"You came away from the stele walking as you do with two full buckets, and I knew before you said a word. You have a second road on you. You did not set the first one down. I have never seen you not set a thing down.",
		"I have had two all my life, you know. The needle and the lotus. Nobody at Azure Cloud called it two roads, because nobody called what I did a road at all. I was the girl who slept. I mended, and I pricked.",
		"So I shall tell you what nobody told me. Neither of them will forgive you for the other. You do not need them to. You only need to stop promising each of them the morning."]},
	"p40_last": {"n": "Seven Either Way", "who": "elder", "after": "s_break45", "lines": [
		"The child played me at leaves on the top step, and I lost, and I swept. It took me until dusk. I am told the corners are better than last month. I am told this by Du, who has no right to an opinion on corners.",
		"I made a rule seventy years ago: one heart, one road. I made it because I had seen a boy tear himself in two trying to be a swordsman for his father and a healer for his mother. I did not make it because it was true.",
		"The child walks two, and is whole, and slower, and does not ask me which is the road. An old keeper of monkeys says it is seven acorns either way. I have been furious about three in the morning for most of my life. I should like, tonight, to be delighted."]},
	# Part XLI (the Rivers and Lakes release)
	"p41_bowl": {"n": "The Bowl at the Landing", "who": "lin", "after": "s_p41_boat", "lines": [
		"They put a bowl in my hands before the boat had stopped. I looked for whoever I was to thank, and there was nobody: only a landing full of people getting on with it.",
		"I have been fed by Granny Wen because I was hers, and by the mountain because I swept it. I had never been fed by people who did not yet know whether I was worth it. They were finding out by watching me eat.",
		"I ate all of it. I looked at who had not got one. I did not know I was being read. I should like to think I would have done the same if I had."]},
	"p41_crooked": {"n": "Robbed, and Told So", "who": "yue", "after": "s_p41_black", "lines": [
		"You were robbed at the gate of Ashmarket and you laughed. I want that written down by somebody other than you. The boy looked you in the eye with his hand in your sleeve, and you laughed, and he gave some of it back.",
		"I have slept a hundred years in an upright sect, and been lied to by it every one of them, kindly, for my own good. Nobody in that black town told me anything that was not so. I did not like it there. I should not like you to think that I did.",
		"But I shall tell you what I learned in it. I had thought upright and honest were one word. They are two. You are both. Most places manage one."]},
	"p41_last": {"n": "Not Seen Off", "who": "lin", "after": "s_break46", "lines": [
		"Nobody saw us off. Four sects, a month of my life, and the landing was empty when the boat pulled out. Yue Ling minded for a mile. I minded for about as long as it takes to say so.",
		"I have wanted to be needed since I was six years old with a broom too tall for me. This month I was needed by everybody at once. It is like being the only dry stone in a ford. Everything stands on you, and nothing stays.",
		"The water is back. They have forgotten me already; I could see them doing it from the boat. I think that is the best work I have done. I should not like to have to do it often."]},
	"p38_last": {"n": "In My Own Hand", "who": "lin", "after": "s_break43", "lines": [
		"These pages were her idea. She said a story told only from over somebody's shoulder is a story about a back. So here is the front of it.",
		"I am Lin Feng. I swept steps. I was handed a root I did not earn and a companion I did not deserve, and I climbed until there was nobody above me, and then three people walked down a mountain and there was.",
		"There is always a higher sky. I used to hear that as a warning. I hear it now as company."]},
}
const ORDER := ["p01_post", "p01_broom", "p01_gate", "p02_emperor", "p03_hollow", "p04_ledger", "p05_sky", "p06_maple", "p07_thread", "p08_river", "p09_sun", "p10_map", "p11_ladder", "p12_tide",
	"p13_gates", "p14_karma", "p15_woven", "p16_year", "p17_spring", "p18_fire", "p19_works", "p20_hollow", "p21_arms", "p22_roads", "p23_host", "p24_horse", "p25_town", "p26_springs", "p27_sack",
	"p28_grass", "p29_chimney", "p30_net", "p31_shoe", "p32_mirror", "p33_pestle", "p34_road", "p35_block", "p36_fish", "p37_round",
	"p38_word", "p38_fuchai_down_lin", "p38_fuchai_down_yue", "p38_fuchai_up_lin", "p38_pang_down_lin", "p38_pang_down_yue", "p38_pang_up_lin",
	"p38_lian_down_lin", "p38_lian_down_yue", "p38_lian_up_lin", "p38_lian_won_lin", "p38_low", "p38_last", "p39_ring", "p39_paper", "p39_last", "p40_leaves", "p40_two", "p40_last", "p41_bowl", "p41_crooked", "p41_last"]

static var _by_step := {}

## The pages whose step is `sid`.
static func after(sid: String) -> Array:
	if _by_step.is_empty():
		for id in ORDER:
			var k := str(PAGES[id].after)
			if not _by_step.has(k):
				_by_step[k] = []
			_by_step[k].append(id)
	return _by_step.get(sid, [])

## Whether page `id` is one this journey writes: its writer is alive (and, for Yue Ling, with him), and
## it is of the branch the story took.
static func open(g, id: String) -> bool:
	var p: Dictionary = PAGES[id]
	var who := str(p.who)
	if WHO_ENT.has(who) and Crime.dead(g, str(WHO_ENT[who])):
		return false
	if who == "yue" and not bool(g.companion):
		return false
	if p.has("if") and Betters.branch(g, str(p["if"][0])) != str(p["if"][1]):
		return false
	# (the Red Seal release: and a page may be of how the first bout went: he bowed, or he won)
	if p.has("how") and not str(g.bested.get(str(p.how[0]), {}).get("first", "")) in p.how[1]:
		return false
	return true

## A step has just been done (Game.advance, before the step counter is read again): the pages that
## follow the step just finished are written.  Returns how many.
static func written(g) -> int:
	var n := 0
	# (the step that was just done is the one before the first this journey walks next; a branch stepped over
	# writes nothing, because its pages name the other branch)
	var i := int(g.step) - 1
	while i >= 0 and not Betters.on_branch(g, Data.STEPS[i]):
		i -= 1
	if i < 0:
		return 0
	for id in after(str(Data.STEPS[i].id)):
		if not g.pages.has(id) and open(g, id):
			g.pages[id] = int(g.day)
			g.page_due.append(id)
			n += 1
	return n

## The pages written so far, in the order of the book.
static func book(g) -> Array:
	return ORDER.filter(func(id): return g.pages.has(id))

## Page `id` as a conversation: every line said by its writer.
static func lines(_g, id: String) -> Array:
	var out: Array = []
	var p: Dictionary = PAGES[id]
	for ln in p.lines:
		out.append([str(WHO[str(p.who)]), str(ln)])
	return out

## Who wrote page `id`, as the book's list names them.
static func by(id: String) -> String:
	return str(WHO[str(PAGES[id].who)])
