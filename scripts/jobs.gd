class_name Jobs
extends RefCounted
## Commissions (the Thundering Pots release): the notice board in the market square of Qingshi.
## Eighteen notices that anybody may take down: no step of the story waits on one (though one step
## asks that a few be done, any of them), each is taken from Clerk Bai, done out in the land, and
## reported to him for what it pays: spirit stones, a little renown, and now and then something
## that is not money (an outfit, a company for the host).
##
## A notice asks for one thing (`need`):
##   ["have", {item: n}]      bring them (they are handed over)
##   ["kills", [ids], n]      bring down so many of these creatures, counted from when it was taken
##   ["more", what, n]        so many more of something than when it was taken (Feats.value: summits,
##                            flights, caves, trees felled, people spoken with, things of the land done)
##   ["reach", what, n]       be somebody who has done so much of it, whenever it was done
##   ["folk", role, n]        speak with so many of one kind of the people of the towns and the road
##   ["war", battle]          hold a field (war.gd)
## `after`: the step of the story that puts it on the board.  Nothing keeps state but `Game.jobs`
## (id -> "taken" or "done") and `Game.job_base` (what was so when it was taken).

const CLERK := "clerk_bai"
const ASK := "The notice board of Qingshi: what will you take down?"

const JOBS := {
	"job_firewood": {"n": "Firewood for the Kiln", "by": "Potter Tao", "after": "s_vl_intro", "need": ["more", "felled", 6], "stones": 1500, "renown": 2,
		"ask": "The kiln eats a cartload a firing and my boy has run off to be a cultivator. Six trees, felled, anywhere. I will fetch them. I only cannot swing the axe any more.", "thanks": "Six. Clean cuts, too. If cultivation fails you there is a living in this."},
	"job_moths": {"n": "Moths in the Silk", "by": "Weaver Liu", "after": "s_vl_intro", "need": ["kills", ["thread_moth", "paper_crow", "silk_bandit"], 8], "stones": 2400, "renown": 2,
		"ask": "Thread-moths in the mulberries again, and paper crows after them, and bandits after those. Eight of the lot, any eight, and I can leave a bolt on the rack overnight.", "thanks": "I left one out last night to see. It is still there. It has never been still there."},
	"job_brine": {"n": "Brine for the Tofu", "by": "Tofu Seller Sun", "after": "s_vl_intro", "need": ["have", {"ess_water": 3}], "stones": 2000, "renown": 2,
		"ask": "Curd will not set without bittern, and the salt-carriers have not come since the trouble on the road. Three Water Essences will set a month of tofu.", "thanks": "It set! Firm as a doorstep. Take a block. Take two; you look like somebody who forgets to eat."},
	"job_letters": {"n": "News for the Road", "by": "Clerk Bai", "after": "s_vl_intro", "need": ["more", "folk_talk", 6], "stones": 1800, "renown": 3,
		"ask": "The board is only as good as what is on it, and I cannot leave the board. Speak with six people you have not spoken with, anywhere, towns or road, and tell me what they said. That is all news is.", "thanks": "A woodcutter with a cold and a pedlar who has raised his prices. Hm. Yes. That goes up. People like to know they are not the only ones."},
	"job_cairns": {"n": "The Surveyor's Cairns", "by": "Cartographer Pei", "after": "s_p22_first", "need": ["more", "summits", 3], "stones": 12000, "renown": 4,
		"ask": "I have drawn a hundred and thirty-nine peaks and stood on none of them. Three summits, any three you have not been up, and tell me whether my heights are right. I suspect I have flattered them.", "thanks": "Lower than I drew them, all three? I knew it. A mountain always looks taller to a man with a pen."},
	"job_kites": {"n": "Kites for the Fifteenth", "by": "the children of Qingshi", "after": "s_p22_leap", "need": ["more", "glides", 3], "stones": 6000, "renown": 3,
		"ask": "(In a child's hand, with a drawing of a swallow.) FLY THREE TIMES WHERE WE CAN SEE. we will pay you. we have nine coppers and a frog.", "thanks": "(The nine coppers are counted out with great ceremony. The frog, after a vote, is retained.)"},
	"job_well": {"n": "What Is Down There", "by": "Granny Gu", "after": "s_p20_delve", "need": ["more", "delved", 1], "stones": 9000, "renown": 3,
		"ask": "Every hole in this land goes somewhere and I am too old to find out where. Go to the very back of one you have not been to the back of. Then come and tell me what was there, slowly, with the frightening parts.", "thanks": "And then? ...And THEN? Hm. I should have liked more bats. But you tell it well."},
	"job_masks": {"n": "Fox Masks for the Festival", "by": "Tailor Qiao", "after": "s_vl_intro", "need": ["have", {"ess_fire": 3, "ess_wood": 2}], "stones": 3000, "renown": 2,
		"ask": "Thirty fox masks for the fifteenth night, and the lacquer wants fire in it to dry before then, and the wood wants to remember it was alive. Three Fire Essences, two Wood. There will be a mask over, and something to go with it.", "thanks": "Thirty, dry, and not one cracked. The one over is yours, and the robe I cut to go with it. Wear it pushed up, on the side. A fox mask worn straight is bad manners; the foxes say so."},
	"job_stage": {"n": "A General for the Stage", "by": "the Pear Garden players", "after": "s_vl_intro", "need": ["reach", "worn", 5], "stones": 5000, "renown": 4,
		"ask": "WANTED: one who can wear a costume as if it were clothes. Our general has gone for a soldier. Applicants to have been seen about in five different outfits at least. No singing required. Please, no singing.", "thanks": "He stands like a general. He walks like a sweeper. We can work with the first. The green and gold is yours; and when the host marches, so do we. We have our own drum."},
	"job_hunters": {"n": "Word to the Hunters", "by": "Lady Hao", "after": "s_p23_sun", "need": ["folk", "hunter", 3], "stones": 15000, "renown": 4,
		"ask": "A host that cannot see is a host that is ambushed. There are hunters at every camp on the road who know this country as I know a chariot. Speak with three of them. Do not order them. Ask.", "thanks": "Forty-five came in last night, by ones, without a sound. My sentries are mortified. Good. They will scout for us; I have put the sentries under them to learn."},
	"job_lesson": {"n": "Master Sun's First Lesson", "by": "Master Sun", "after": "s_p23_sun", "need": ["war", "drill1"], "stones": 10000, "renown": 3,
		"ask": "The drill ground, any morning. Half the levy under blue flags, with horse. Stop them. I shall not say how. If I said how you would know one answer, and I want you to know the question.", "thanks": "A spear wall. Yes. It is in the first chapter. Most people have to be ridden over once before they read the first chapter."},
	"job_chapters": {"n": "The Thirteen Chapters", "by": "Master Sun", "after": "s_p23_river", "need": ["war", "drill3"], "stones": 40000, "renown": 6, "item": "thirteen_chapters",
		"ask": "The third lesson is against myself, and I shall hide what I am doing. I have never set it for anybody. The King of Wu asked, and I gave him the palace ladies to drill instead, which he liked less.", "thanks": "Take the book. No: I know it by heart, and the heart is where it ought to be kept. A general who has to look it up has already lost."},
	"job_teahouse": {"n": "Tunes for the Teahouse", "by": "the Willow Teahouse", "after": "s_vl_intro", "need": ["reach", "heard", 12], "stones": 4000, "renown": 2,
		"ask": "Our player knows four tunes and the customers know all four. Somebody who has been about the land and heard twelve, to hum them to her. She has a quick ear and a slow memory; bring patience.", "thanks": "She has nine of the twelve already and is arguing with you about the tenth. The tea is on the house. The argument is extra."},
	"job_pastimes": {"n": "The Idle Hour", "by": "Old Teacher Ren", "after": "s_vl_intro", "need": ["more", "pastimes", 3], "stones": 2500, "renown": 2,
		"ask": "My pupils believe a cultivator does nothing but fight. Do three things of the land you have never done: fish, strike a bell, sit on a swing, I do not mind. Then come and tell the class. It will do them more good than the Analects.", "thanks": "\"He sat on a swing.\" Thirty children, struck dumb. One has asked whether the swing was a spiritual treasure. I said yes."},
	"job_tally": {"n": "The Year's Tally", "by": "the Shrine of the Earth God", "after": "s_vl_intro", "need": ["reach", "bosses", 50], "stones": 20000, "renown": 5,
		"ask": "The Earth God's ledger wants a line for every lord of the land that has been quieted, and the god's clerk is behind. One who has brought down fifty to come and be counted. Bring your own brush.", "thanks": "Fifty and more. The clerk has run out of column. He is ruling a new page with the air of a man whose god has just been promoted."},
	"job_mill": {"n": "A Maker for the Mill-Race", "by": "Carpenter Gu", "after": "s_p19_ban", "need": ["reach", "works", 4], "stones": 14000, "renown": 3,
		"ask": "Master Ban's wheel wants looking at by somebody who has built four works with his own hands and still has ten fingers. I have built a great deal, and have nine.", "thanks": "A cracked float, third from the top. I walked past it for a month. You looked for one breath. That is the difference between making a thing and knowing it."},
	"job_instructor": {"n": "An Instructor at Arms", "by": "Lady Hao", "after": "s_p23_sun", "need": ["reach", "arms", 3], "stones": 18000, "renown": 4,
		"ask": "I have ploughmen holding spears like hoes. I want one who has learned three weapons properly, to show them that a spear is not a hoe. It is, I grant, very like one. That is the trouble.", "thanks": "They hold them like spears. They still plant their feet like ploughmen, which I have decided to call a stance."},
	"job_dresses": {"n": "Something for Her", "by": "Little Hua", "after": "s_vl_intro", "need": ["reach", "yue_outfits", 3], "stones": 3000, "renown": 2,
		"ask": "(In careful characters.) Big sister Yue Ling has had ONE dress as long as I have known her and I am SEVEN. Somebody is to see that she has three. I will be checking.", "thanks": "(Little Hua inspects all three, front and back, and pronounces them acceptable. The fee is paid by Granny Wen, who is trying not to laugh.)"},
}
const ORDER := ["job_firewood", "job_moths", "job_brine", "job_letters", "job_pastimes", "job_teahouse", "job_masks", "job_stage", "job_dresses", "job_tally",
	"job_mill", "job_well", "job_cairns", "job_kites", "job_hunters", "job_lesson", "job_instructor", "job_chapters"]

static func state(g, id: String) -> String:
	return str(g.jobs.get(id, ""))

static func is_done(g, id: String) -> bool:
	return state(g, id) == "done"

static func done_count(g) -> int:
	var n := 0
	for id in g.jobs:
		if str(g.jobs[id]) == "done":
			n += 1
	return n

## On the board now: its step reached, and not yet done.
static func posted(g, id: String) -> bool:
	return g.reached(str(JOBS[id].after)) and g.done(str(JOBS[id].after)) and not is_done(g, id)

## [so far, asked for]
static func progress(g, id: String) -> Array:
	var nd: Array = JOBS[id].need
	var base: Dictionary = g.job_base.get(id, {})
	match str(nd[0]):
		"have":
			var have := 0
			var want := 0
			for k in nd[1]:
				want += int(nd[1][k])
				have += mini(int(nd[1][k]), int(g.inv.get(k, 0)))
			return [have, want]
		"kills":
			var n := 0
			for k in nd[1]:
				n += int(g.felled_kind.get(k, 0)) - int(base.get(k, 0))
			return [mini(n, int(nd[2])), int(nd[2])]
		"more":
			return [mini(int(Feats.value(g, [str(nd[1]), 0]) - float(base.get("v", 0.0))), int(nd[2])), int(nd[2])]
		"reach":
			return [mini(int(Feats.value(g, [str(nd[1]), 0])), int(nd[2])), int(nd[2])]
		"folk":
			return [mini((base.get("met", {}) as Dictionary).size(), int(nd[2])), int(nd[2])]
		"war":
			return [1 if g.war_won.has(str(nd[1])) else 0, 1]
	return [0, 1]

static func ready(g, id: String) -> bool:
	var p := progress(g, id)
	return state(g, id) == "taken" and int(p[0]) >= int(p[1])

static func take(g, id: String) -> void:
	if state(g, id) != "":
		return
	g.jobs[id] = "taken"
	var nd: Array = JOBS[id].need
	var base := {}
	match str(nd[0]):
		"kills":
			for k in nd[1]:
				base[k] = int(g.felled_kind.get(k, 0))
		"more":
			base["v"] = Feats.value(g, [str(nd[1]), 0])
		"folk":
			base["met"] = {}
	g.job_base[id] = base
	g.note("Took down a notice: %s" % str(JOBS[id].n))

## Reported: what was asked for is handed over, and what it pays is paid.
static func finish(g, id: String) -> bool:
	if not ready(g, id):
		return false
	var j: Dictionary = JOBS[id]
	if str(j.need[0]) == "have":
		for k in j.need[1]:
			g.inv[k] = int(g.inv.get(k, 0)) - int(j.need[1][k])
	g.jobs[id] = "done"
	g.stones += int(j.get("stones", 0))
	g.toast("Commission done: +%d spirit stones, +%d renown" % [int(j.get("stones", 0)), int(j.get("renown", 0))])
	g.note("A commission done: %s" % str(j.n))
	g.add_renown(int(j.get("renown", 0)))
	if j.has("item"):
		g.add_item(str(j.item))
		g.toast("Obtained %s" % str(Data.ITEMS[str(j.item)].n))
	g.grant_earned("job", id)
	for cid in War.ORDER:
		if str(War.COMPANIES[cid].get("job", "")) == id:
			g.toast("The host: %s come in" % str(War.COMPANIES[cid].n))
	g.poll_steps()
	return true

## One of the people of the towns or the road has been spoken with (main.talk_folk): a notice that
## asks for their kind counts them.
static func folk_talked(g, p: Dictionary) -> void:
	for id in g.jobs:
		if str(g.jobs[id]) != "taken" or str(JOBS[id].need[0]) != "folk" or not Folk.is_role(p, str(JOBS[id].need[1])):
			continue
		g.job_base[id]["met"][str(p.id)] = true

## What the board says of a notice.
static func text(g, id: String) -> String:
	var j: Dictionary = JOBS[id]
	var p := progress(g, id)
	var st := state(g, id)
	var out := "Posted by %s.\n\n\"%s\"\n\n" % [str(j.by), str(j.ask)]
	out += "It pays %d spirit stones and %d renown" % [int(j.get("stones", 0)), int(j.get("renown", 0))]
	for rw in Fashion.earned_by("job", id):
		out += ", and something to wear"
	for cid in War.ORDER:
		if str(War.COMPANIES[cid].get("job", "")) == id:
			out += ", and a company for the host"
	out += ".\n"
	if st == "taken":
		out += "Taken down: %d of %d." % [int(p[0]), int(p[1])]
	return out

static func label(g, id: String) -> String:
	var st := state(g, id)
	var p := progress(g, id)
	if st == "taken":
		return ("Report: %s" if int(p[0]) >= int(p[1]) else "%s") % str(JOBS[id].n)
	return str(JOBS[id].n)
