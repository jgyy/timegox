class_name Grudges
extends RefCounted
## The grudges that stayed (Part XIV, the Fates and Faces release).  Most of what the dead are owed
## comes down the funeral road to the Wheel of the Six Paths, and the Wheel grinds it small; six of the
## foes Lin Feng put down on the road left a grudge that would not come.  Each stands where its owner
## fell, in the owner's own shape gone to soot, and Nie drinks from all six.
##
## Judge Cui shows them in the Karma Mirror (step "s_p14_mirror"); the next step (kind "grudges") asks
## for all six, in any order.  A grudge does not listen until it has spent itself, so each is fought
## first (a boss of the region it fell in, Data.ENEMIES with "grudge"); then it says what it was owed,
## and a choice opens: pay it (spirit stones, something kept from the road, a name the world respects),
## let somebody Lin Feng kept faith with answer it (fate.gd: only if their thread went that way), or
## leave it to the Wheel.  Options use fate.gd's shape (need, pay, gain, then, after) and its helpers.
##
## It matters: every grudge laid to rest takes something off Nie and every one left unpaid feeds it
## (`nie_mult`), Nie says which of them it carries, and the ending tells what came of each.

const STEP := "s_p14_grudges"
const ORDER := ["grudge_iron_fang", "grudge_marsh_hag", "grudge_headless_saint", "grudge_fangfeng", "grudge_kui", "grudge_admiral"]
## How a grudge was settled: "eased" (somebody answered it), "paid" (Lin Feng paid it) or "unpaid".
const SETTLED := ["eased", "paid"]
## Nie's health: +NIE_UNPAID for every grudge left to the Wheel, -NIE_SETTLED for every one at rest.
const NIE_UNPAID := 0.15
const NIE_SETTLED := 0.04
## A grudge fights as hard as a trial's boss ([health, attack] multipliers, as trials.gd MIGHT)
const MIGHT := [1.6, 1.15]
## The friends' states (fate.gd ALLY): who can be asked to answer a grudge
const FRIEND := ["ally", "redeemed"]

const GRUDGES := {
	"grudge_iron_fang": {"of": "iron_fang", "who": "Iron Fang", "col": Color("c0603a"),
		"ask": "Iron Fang's grudge: what was he owed?",
		"options": [
			{"id": "son", "label": "Let his son answer him", "need": [["fate", "hu", FRIEND]], "then": "eased", "gain": {"renown": 14},
				"desc": "Fang Hu stands with you at the end of the road. Let the son say to the father what the son has to say.",
				"log": "Let Fang Hu answer his father's grudge.",
				"after": [["Fang Hu", "Father. I know what they did to you at that gate, and I know what you did after. Both of them are mine to carry now, and I'm carrying them."],
					["Iron Fang's Grudge", "...You have your mother's ears. Don't let anybody send a child down those steps, boy."],
					["Fang Hu", "Nobody gets sent down the steps any more. I'll see to it."],
					["Narrator", "The boy with the gap in his teeth looks up at the man his son became, and grins, and is gone."]],
				"epilogue": "Fang Hu hung his father's iron gauntlet by the sect gate. Every spring he stands under it while the children who climb are tested, the ones with patched sleeves first."},
			{"id": "test", "label": "Test him at last", "need": [["stones", 30000]], "pay": {"stones": 30000}, "then": "paid", "gain": {"renown": 10},
				"desc": "Lay the sect's testing stone in his hands, years too late, and pay for testers at the gate so that every child who climbs is tested, whatever their father wears (30,000 spirit stones to the sect's treasury).",
				"log": "Put the testing stone in Iron Fang's hands at last.",
				"after": [["Narrator", "The testing stone warms in his small hands, and a thread of light, thin as a hair, runs up through it. There was something in him. There always was."],
					["Iron Fang's Grudge", "Huh. Would you look at that."],
					["Narrator", "He is still looking at it when he goes."]],
				"epilogue": "Every child who climbs the steps of Azure Cloud Sect is tested now, whatever their sleeves look like. The testing stone by the gate is called Iron Fang's Stone, and only the Elder remembers why."},
			{"id": "wheel", "label": "Let the Wheel grind it small", "then": "unpaid",
				"desc": "He poisoned the sect's wells and kept a healer bound. Leave his grudge to the Wheel, which grinds every grudge small in the end. A grudge left unpaid feeds Nie.",
				"log": "Left Iron Fang's grudge to the Wheel.",
				"after": [["Narrator", "The boy looks at Lin Feng for a long moment. Then he gets up and walks away into the bamboo, south-west, towards the Wheel, without looking back."]]},
		]},
	"grudge_marsh_hag": {"of": "marsh_hag", "who": "the Marsh Hag", "col": Color("7a4a8f"),
		"ask": "The Marsh Hag's grudge: what was she owed?",
		"options": [
			{"id": "name", "label": "Let Liu Ying give her name back", "need": [["fate", "liu_ying", FRIEND]], "then": "eased", "gain": {"renown": 14},
				"desc": "Liu Ying stands with you, and she grew up in the hut with the Hag's grimoire. Its first page is in a hand younger than the rest.",
				"log": "Let Liu Ying give the Marsh Hag her name back.",
				"after": [["Liu Ying", "Shen Lu. I must have read the first page of her grimoire a hundred times as a child: 'Shen Lu, herb-wife of the Crimson Marsh settlement. Cures given on credit, to be paid at harvest.'"],
					["The Marsh Hag's Grudge", "Shen Lu. Yes. That was a good name. I was proud of it, once."],
					["Liu Ying", "I'll put it back over the hut door. And the cures. Somebody should still be giving them on credit."],
					["Narrator", "The old woman closes the ledger, and for the first time in three hundred years she does not open it again."]],
				"epilogue": "There is a sign over the hut door in the Crimson Marsh again: Shen Lu, herb-wife. Cures on credit. The herb-wife inside is young and very stern, and never sends a bill."},
			{"id": "pay", "label": "Pay the settlers' bill", "need": [["stones", 40000]], "pay": {"stones": 40000}, "then": "paid", "gain": {"renown": 10},
				"desc": "Count the Court's debt out onto her ledger: a winter of cures for thirty-six families, with three hundred years' interest (40,000 spirit stones). The Court is gone; somebody has to pay it.",
				"log": "Paid the Marsh Hag the settlers' bill.",
				"after": [["Narrator", "Lin Feng counts the stones out onto the ledger one by one, and one by one the names on it go grey and quiet, the way a bill does when it is paid."],
					["The Marsh Hag's Grudge", "Paid in full. I never thought I would see those words in my own book."]],
				"epilogue": "The blood lotuses of the Crimson Marsh flower white now. The herb-wives of the villages say a cure picked there never fails, and leave a copper on the bank for it."},
			{"id": "wheel", "label": "Let the Wheel grind it small", "then": "unpaid",
				"desc": "She sold venom for the wells and young roots to the Blood Moon. Her grudge can go to the Wheel with everybody else's. A grudge left unpaid feeds Nie.",
				"log": "Left the Marsh Hag's grudge to the Wheel.",
				"after": [["Narrator", "The Hag's grudge closes the ledger very gently, as if she had expected nothing else, and sinks into the red water with it."]]},
		]},
	"grudge_headless_saint": {"of": "headless_saint", "who": "the Headless Saint", "col": Color("9898b0"),
		"ask": "The Headless Saint's grudge: what was he owed?",
		"options": [
			{"id": "bow", "label": "Let Qiu Ye make the bow", "need": [["fate", "qiu_ye", FRIEND]], "then": "eased", "gain": {"renown": 14},
				"desc": "Qiu Ye stands with you, and the old houses of Cloudfoot still teach the saint's bow, the true one, with the sword low. Let a son of Cloudfoot show him it was never forgotten.",
				"log": "Let Qiu Ye bow to the Headless Saint.",
				"after": [["Qiu Ye", "Master. The House of Qiu taught me this before I could walk. Sword low. Heels together. Like this."],
					["Narrator", "The headless saint corrects Qiu Ye's elbow by a finger's breadth, as he must have done for ten thousand students, and is satisfied, and is gone."]],
				"epilogue": "Qiu Ye teaches the old bow at the sect with the sword held low, and tells every class whose bow it was. He is very strict about elbows."},
			{"id": "tablet", "label": "Put his name back on the tablets", "need": [["renown", 450]], "then": "paid", "gain": {"renown": 10},
				"desc": "The ancestral hall will not restore a name the sect took down long ago unless somebody the whole world listens to asks it to. You could be that somebody.",
				"log": "Asked for the Headless Saint's name to go back on the sect's tablets.",
				"after": [["Lin Feng", "It goes back on the tablets this autumn, beside the Founder's, where it was."],
					["Narrator", "The saint bows once more, the deep bow that is only for teachers, and the bow goes on for a moment after he is gone."]],
				"epilogue": "The first tablet in the ancestral hall of Azure Cloud Sect bears two names again, the founder's and the Headless Sword Saint's, and the disciples who learn the old bow are told whose it was."},
			{"id": "wheel", "label": "Let the Wheel grind it small", "then": "unpaid",
				"desc": "The Emperor he refused is long gone, and a name is a small thing to leave on the ground. A grudge left unpaid feeds Nie.",
				"log": "Left the Headless Saint's grudge to the Wheel.",
				"after": [["Narrator", "The saint rubs the characters out with the flat of his hand, bows, and fades between the graves. Nobody returns the bow."]]},
		]},
	"grudge_fangfeng": {"of": "fangfeng", "who": "Fangfeng", "col": Color("6a7a5a"),
		"ask": "Fangfeng's grudge: what was he owed?",
		"options": [
			{"id": "ask", "label": "Ask him why he was late", "then": "eased", "gain": {"renown": 12},
				"desc": "Nobody ever did. It will cost nothing but the time it takes to hear a giant tell a long story about a dyke.",
				"log": "Asked Fangfeng why he was late.",
				"after": [["Lin Feng", "Why were you late, Fangfeng?"],
					["Fangfeng's Grudge", "There was a village called Low Willow under the dyke on the Kuai, and the dyke burst in the night. I stood in the breach till they had mended it. Two hundred and six people. I counted them as they carried the baskets. Two hundred and six."],
					["Narrator", "He tells all of it, every basket and every name he heard shouted in the dark, and when he has finished he simply is not there any more, the way a man is not there who has gone home."]],
				"epilogue": "A shrine stands on the dyke at Low Willow to a giant who came late. The village children are allowed to be late for anything once, if they had a good reason, and somebody always asks them what it was."},
			{"id": "shrine", "label": "Raise him a shrine on the dyke", "need": [["stones", 25000]], "pay": {"stones": 25000}, "then": "paid", "gain": {"renown": 10},
				"desc": "Pay the masons of Tushan to raise a shrine to Fangfeng on the dyke he held, with his reason cut in the stone for every traveller to read (25,000 spirit stones).",
				"log": "Raised a shrine to Fangfeng on the dyke at Low Willow.",
				"after": [["Narrator", "The masons cut the story deep. The giant's grudge reads every word over their shoulders, nodding, and is gone before the last character is finished."]],
				"epilogue": "A shrine stands on the dyke at Low Willow to a giant who came late, with his reason cut deep in the stone for everybody to read."},
			{"id": "wheel", "label": "Let the Wheel grind it small", "then": "unpaid",
				"desc": "Yu's judgement was Yu's, and it is four thousand years old. Leave it to the Wheel. A grudge left unpaid feeds Nie.",
				"log": "Left Fangfeng's grudge to the Wheel.",
				"after": [["Narrator", "The giant gets up very slowly, goes back to the breach in a dyke that is not there, and puts his shoulder to water that drained away four thousand years ago."]]},
		]},
	"grudge_kui": {"of": "kui", "who": "Kui", "col": Color("7a8898"),
		"ask": "Kui's grudge: what was it owed?",
		"options": [
			{"id": "home", "label": "Carry it home to Liubo", "need": [["rides", 3]], "then": "eased", "gain": {"renown": 14},
				"desc": "Liubo lies far out in the Eastern Sea, past where any ox can hop. With three rides of your own you can carry it home in stages, over the clouds and the sea, and let it stand in the surf again.",
				"log": "Carried Kui's grudge home to Liubo.",
				"after": [["Narrator", "It takes three days. On the morning of the fourth, off the black sands of Liubo, the grudge of Kui steps into the surf on its one leg and stands there. Then, very quietly, it bellows."],
					["Narrator", "It is the first time in five thousand years. The sky over the Eastern Sea rings like a bell, and it does not sound like a drum at all."]],
				"epilogue": "Sailors in the Eastern Sea say that on clear mornings off Liubo the sky rings like a bell, and that it means fair weather."},
			{"id": "unstring", "label": "Unstring the last of the drum", "need": [["item", "ess_thunder", 6]], "pay": {"items": {"ess_thunder": 6}}, "then": "paid", "gain": {"renown": 10},
				"desc": "The drum's last skin still hangs in the Rain Ministry. Pay the dragon-kin six thunder essences to draw the thunder out of it for good, and the hide can rest.",
				"log": "Had the last of Kui's drum unstrung.",
				"after": [["Narrator", "The dragon-kin take the old drumskin down and let the thunder run out of it like water, and somewhere over the aeries an ox-shaped cloud lies down and does not get up."]],
				"epilogue": "The Rain Ministry has no drum any more. The dragon-kin call the rain with a bell, and say it comes more gently."},
			{"id": "wheel", "label": "Let the Wheel grind it small", "then": "unpaid",
				"desc": "It has thrown its thunder at Juntian for five thousand years. Leave it to the Wheel. A grudge left unpaid feeds Nie.",
				"log": "Left Kui's grudge to the Wheel.",
				"after": [["Narrator", "The grudge gets up on its one leg, the first beat of a drum that is not there rolls over the aeries, and it is a thunderhead again."]]},
		]},
	"grudge_admiral": {"of": "drowned_admiral", "who": "the Admiral", "col": Color("4a5a6a"),
		"ask": "The Admiral's grudge: what was he owed?",
		"options": [
			{"id": "log", "label": "Read him her name from Xu Fu's log", "need": [["item", "xufu_log", 1]], "then": "eased", "gain": {"renown": 14},
				"desc": "Xu Fu's logbook lists every child rowed ashore at Penglai, with the boat and the hour. The pages you gathered off the sea floor may have hers on them.",
				"log": "Read the Admiral his daughter's name from Xu Fu's log.",
				"after": [["Lin Feng", "Third boat, second hour after dawn: Han Lingbo, eleven, of the flagship. Carried ashore by the bosun because she would not step into the water. Knew the Thousand Names by heart before the first winter was out."],
					["The Admiral's Grudge", "She would not step into the water. No. She never would."],
					["Narrator", "The Admiral laughs, once, a father's laugh; and the flagship, which has listed on the slope of the Ruins for two thousand years, very slowly settles level."]],
				"epilogue": "At every Landing Day the Hall of the Thousand Names reads one more name than it used to: the Admiral's, who came after his daughter at last."},
			{"id": "landfall", "label": "Bring his wheel to Landfall", "need": [["stones", 30000]], "pay": {"stones": 30000}, "then": "paid", "gain": {"renown": 10},
				"desc": "Pay the boatwrights of Landfall to raise the flagship's wheel out of the Ruins and hang it in the Hall of the Thousand Names, where his daughter's name is read every Landing Day (30,000 spirit stones).",
				"log": "Brought the Admiral's wheel home to Landfall.",
				"after": [["Narrator", "The boatwrights raise the flagship's wheel out of the Ruins and hang it in the Hall of the Thousand Names. On Landing Day, when the names are read, a shadow by the wheel stands very straight at the name Han Lingbo."]],
				"epilogue": "The wheel of the First Emperor's flagship hangs in the Hall of the Thousand Names at Landfall, and on Landing Day the children take turns to steer it."},
			{"id": "wheel", "label": "Let the Wheel grind it small", "then": "unpaid",
				"desc": "He chose the Emperor's errand over his daughter, and that is his to carry. Leave it to the Wheel. A grudge left unpaid feeds Nie.",
				"log": "Left the Admiral's grudge to the Wheel.",
				"after": [["Narrator", "The Admiral's grudge takes the flagship's wheel again. The wreck creaks, and holds its course for a shore it will never reach."]]},
		]},
}

static func is_grudge(id: String) -> bool:
	return GRUDGES.has(id)

static func option(id: String, oid: String) -> Dictionary:
	for o in GRUDGES.get(id, {}).get("options", []):
		if str(o.id) == oid:
			return o
	return {}

## What became of grudge `id`: "eased", "paid", "unpaid" or "" (not yet met).
static func state(g, id: String) -> String:
	var oid := str(g.grudges.get(id, ""))
	return str(option(id, oid).get("then", "")) if oid != "" else ""

static func settled(g) -> int:
	var n := 0
	for id in ORDER:
		if state(g, id) in SETTLED:
			n += 1
	return n

static func unpaid(g) -> int:
	var n := 0
	for id in ORDER:
		if state(g, id) == "unpaid":
			n += 1
	return n

## Nie's health against what was done with the six (1.0 before any).
static func nie_mult(g) -> float:
	return 1.0 + NIE_UNPAID * unpaid(g) - NIE_SETTLED * settled(g)

## The grudges left to the Wheel, by who they were ("Iron Fang, Kui").
static func unpaid_names(g) -> String:
	var out: Array = []
	for id in ORDER:
		if state(g, id) == "unpaid":
			out.append(str(GRUDGES[id].who))
	return ", ".join(out)

## What the narrator sees in Nie's many hands before its trial ("" before any grudge was met).
static func nie_line(g) -> String:
	if g.grudges.is_empty():
		return ""
	var up := unpaid(g)
	var pct := int(round(absf(nie_mult(g) - 1.0) * 100.0))
	if up == 0:
		return "Not one of the six grudges that stayed is among Nie's many hands. Nie is smaller than Judge Cui feared (health -%d%%)." % pct
	var known := "Among Nie's many hands Lin Feng knows %d: %s, the grudges he left to the Wheel." % [up, unpaid_names(g)]
	if nie_mult(g) > 1.0:
		return known + " They came here instead, and Nie is the heavier for them (health +%d%%)." % pct
	return known + " But the ones he laid to rest are not there, and Nie is the lighter for them (health -%d%%)." % pct

## Take option `o` for grudge `id`: it is remembered, what it costs was paid on the choice screen,
## what it brings comes now.
static func take(g, id: String, o: Dictionary) -> void:
	g.grudges[id] = str(o.id)
	Fate.gain(g, o)
	var how := {"eased": "laid to rest", "paid": "paid", "unpaid": "left to the Wheel"}
	g.toast("%s: %s (%d of %d)" % [Data.ENEMIES[id].n, how.get(str(o.then), str(o.then)), g.grudges.size(), ORDER.size()])
	g.note("%s %s" % [Data.ENEMIES[id].n, how.get(str(o.then), str(o.then))])

## What the ending tells of the six (one line for every grudge laid to rest).
static func epilogues(g) -> Array:
	var out: Array = []
	for id in ORDER:
		var ep := str(option(id, str(g.grudges.get(id, ""))).get("epilogue", ""))
		if ep != "":
			out.append(ep)
	return out
