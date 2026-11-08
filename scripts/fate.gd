class_name Fate
extends RefCounted
## Fated encounters (the Fates and Faces release): five people whose lives Lin Feng changes along the
## road, met again and again from Part I to Part XIV, each with a story of their own and a choice at
## every meeting that decides what becomes of them.
##
## A thread's **chapters** are quest steps of kind "fate" (Data.STEPS): Lin Feng talks to the person,
## the chapter plays the variant written for the thread's **state** (what the earlier choices made of
## them; "*" for any), then a choice opens (FateText.CHAPTERS: each option says what it does and costs,
## may need something, may cost something, may give something, may be fought out, and may end in a
## second choice once the battle is won).  The option taken becomes the thread's state, and the
## Fates page (Esc > Fates) keeps a line for it.  The fifth meeting of every thread is in Part XIV,
## in any order (a step of kind "fates"): friends come to the last battle (a trial path "By the bonds
## you made" and allies who strike Nie every round), enemies have been reached by Nie and are fought.
##
## Choices matter on the road too: a thread in the right state opens a path through one of the
## trials (`BONDS`: "By an old bond"), the Hag's apprentice makes Alchemist Mo's recipes cheaper,
## Tala's herd gives a horse, Qiu Ye an outfit, and the ending tells what became of all five.

const THREADS := {
	"tala": {"n": "Tala of the Horse-Folk", "col": Color("d8a04a"), "intro": "A girl of the horse-folk whose herd was penned by starving apes in Thunder Valley."},
	"qiu_ye": {"n": "Qiu Ye, the Second Son", "col": Color("5ab08a"), "intro": "The proud outer disciple the sweeper outpaced, son of a ruined house of Cloudfoot."},
	"hu": {"n": "Hu, the Bandit's Son", "col": Color("c87a4a"), "intro": "Iron Fang's son, who stood over his father's body with a kitchen knife."},
	"xu_lan": {"n": "Xu Lan, the Moon's Daughter", "col": Color("d0405a"), "intro": "Demon Lord Xu Mo's daughter, found in silver chains in the Blood Moon Palace."},
	"liu_ying": {"n": "Liu Ying, the Hag's Apprentice", "col": Color("8ac06a"), "intro": "A girl the Marsh Hag bought in a famine, sorting poisons in the hut when the Hag fell."},
}
const THREAD_ORDER := ["tala", "qiu_ye", "hu", "xu_lan", "liu_ying"]

## The chapters of each thread, in order: [step id (a "fate" step, or the Part XIV meeting), npc id].
const PATH := {
	"tala": [["s_f_tala1", "tala"], ["s_f_tala2", "tala_steppe"], ["s_f_tala3", "tala_plains"], ["s_f_tala4", "tala_end"]],
	"qiu_ye": [["s_f_qiu1", "qiu_ye"], ["s_f_qiu2", "qiu_ye_grave"], ["s_f_qiu3", "qiu_ye_springs"], ["s_f_qiu4", "qiu_ye_end"]],
	"hu": [["s_f_hu1", "little_hu"], ["s_f_hu2", "hu_village"], ["s_f_hu3", "hu_longmen"], ["s_f_hu4", "hu_end"]],
	"xu_lan": [["s_f_xu1", "xu_lan"], ["s_f_xu2", "xu_lan_lake"], ["s_f_xu3", "xu_lan_youdu"], ["s_f_xu4", "xu_lan_end"]],
	"liu_ying": [["s_f_liu1", "liu_ying"], ["s_f_liu2", "liu_ying_vale"], ["s_f_liu3", "liu_ying_isle"], ["s_f_liu4", "liu_ying_end"]],
}
## Part XIV: the step in which the five threads are settled, in any order
const FINALE_STEP := "s_p14_fates"

## The final states in which somebody stands with Lin Feng at the Wheel (and those in which nobody
## stands anywhere any more).
const ALLY := ["ally", "redeemed"]
const GONE := ["fallen"]
## States in which the person has left the place they were met (fled, expelled, sworn vengeance, or
## simply taken somewhere else: a boy led down to the village, a girl to the sect's cells or to Mo's
## pharmacy): they are not found standing there afterwards.
const AWAY := ["expelled", "beaten", "doubt", "possessed", "wild", "jailed", "foe", "hunted", "heir", "rival", "dealer", "fallen", "fugitive",
	"village", "sect", "prisoner", "ward", "apprentice", "home"]

## A choice in the right state opens a path through a trial later on (trials.gd kind "bond").
const BONDS := {
	"bifang": ["tala", ["well", "bought"]],
	"king_yama": ["qiu_ye", ["brother", "turning"]],
	"qianxian": ["hu", ["watchman", "guardian", "disciple"]],
	"li": ["xu_lan", ["forgiving", "just"]],
	"tianwu": ["liu_ying", ["physician", "alchemist"]],
}
## Liu Ying at Alchemist Mo's side: his recipes cost this much fewer spirit stones.
const APPRENTICE_STATES := ["apprentice", "bold", "careful", "physician", "alchemist", "ally"]
const MO_DISCOUNT := 0.15

## The small choices of the road (Game.picks): an id, the step after which it is asked, the question,
## the options and what is said after each.
## Each is asked once, in Main after the step's own dialogue.
const PICKS := {
	"qilin": {"step": "s_ce_qilin", "ask": "The Azure Qilin bows its head to you. Will you ride it?",
		"options": [
			{"id": "ride", "label": "Let it carry you", "desc": "The qilin chose you: it will carry the party wherever the roads run (the Azure Qilin, a ride). The Celestial Gate's herd will miss it.", "log": "Let the Azure Qilin choose to carry him."},
			{"id": "free", "label": "Send it home to its herd", "desc": "The qilin was the Gate's prisoner too. Send it home to the herd of the Jasper Pool; the world will hear of it (renown), and so will the qilin's kin.", "log": "Sent the Azure Qilin home to its herd."},
		],
		"after": {
			"ride": [["Narrator", "The qilin kneels on its forelegs, the way it has seen horses do in pictures, and waits. Its hooves do not quite touch the ground."], ["Yue Ling", "It is purring. Do qilin purr?"]],
			"free": [["Narrator", "The qilin looks at Lin Feng for a long moment, then turns and goes up into the clouds over the Gate, west, towards Kunlun, without touching a single step."], ["Yue Ling", "Somewhere a herd is going to be very surprised."]],
		}},
}

# ---------------------------------------------------------------- state
static func state(g, thread: String) -> String:
	return str(g.fates.get(thread, ""))

static func is_ally(g, thread: String) -> bool:
	return state(g, thread) in ALLY

## How many of the five stand with Lin Feng.
static func allies(g) -> int:
	var n := 0
	for th in THREAD_ORDER:
		if is_ally(g, th):
			n += 1
	return n

## The thread a chapter step or a person belongs to ("" for none).
static func thread_of_step(sid: String) -> String:
	for th in PATH:
		for ch in PATH[th]:
			if str(ch[0]) == sid:
				return th
	return ""

static func thread_of_npc(npc: String) -> String:
	for th in PATH:
		for ch in PATH[th]:
			if str(ch[1]) == npc:
				return th
	return ""

## The chapter played when meeting `npc` (its step id).
static func chapter_of_npc(npc: String) -> String:
	for th in PATH:
		for ch in PATH[th]:
			if str(ch[1]) == npc:
				return str(ch[0])
	return ""

## The variant of a chapter for the thread's state now ({} if it has none).
static func variant(g, sid: String) -> Dictionary:
	var ch: Dictionary = FateText.CHAPTERS.get(sid, {})
	if ch.is_empty():
		return {}
	var by: Dictionary = ch.by
	var st := state(g, thread_of_step(sid))
	return by.get(st, by.get("*", {}))

static func option(v: Dictionary, id: String) -> Dictionary:
	for o in v.get("options", []):
		if str(o.id) == id:
			return o
	return {}

## Whether a person stands where they were met: from their chapter on, until the thread's next
## chapter begins, and not once they have fled, been sent away or fallen.
static func present(g, npc: String) -> bool:
	var th := thread_of_npc(npc)
	if th == "":
		return true
	var st := state(g, th)
	var path: Array = PATH[th]
	for k in path.size():
		if str(path[k][1]) != npc:
			continue
		if k == path.size() - 1:
			# the Part XIV meeting: there from the settling of the threads on, unless fallen
			return g.reached(FINALE_STEP) and not st in GONE
		var sid := str(path[k][0])
		var next := FINALE_STEP if k + 1 == path.size() - 1 else str(path[k + 1][0])
		if not g.reached(sid) or g.reached(next):
			return false
		# met and gone: nobody stands about after a chapter that sent them away
		return not (g.done(sid) and st in AWAY)
	return true

# ---------------------------------------------------------------- what an option needs, costs and gives
static func need_met(n: Array, g) -> bool:
	match str(n[0]):
		"rides":
			return g.rides.size() >= int(n[1])
		_:
			return Trials.need_met(n, g)

static func option_ok(g, o: Dictionary) -> bool:
	for n in o.get("need", []):
		if not need_met(n, g):
			return false
	return true

## What an option needs and gives, in words, for the choice screen.
static func option_text(g, o: Dictionary) -> String:
	var parts: Array = []
	for n in o.get("need", []):
		var t := "%d of your rides" % int(n[1]) if str(n[0]) == "rides" else Trials.need_text(n, g)
		if str(n[0]) == "rides":
			t = "A ride of your own (you have %d)" % g.rides.size()
		parts.append(("[x] " if need_met(n, g) else "[ ] ") + t)
	var gv: Dictionary = o.get("gain", {})
	var gets: Array = []
	if gv.has("ride"):
		gets.append("a ride: the " + str(Fashion.RIDES[gv.ride].n))
	if gv.has("outfit"):
		gets.append("an outfit: the " + str(Fashion.OUTFITS[gv.outfit].n))
	if int(gv.get("stones", 0)) > 0:
		gets.append("%d spirit stones" % int(gv.stones))
	if int(gv.get("renown", 0)) > 0:
		gets.append("renown +%d" % int(gv.renown))
	for k in gv.get("items", {}):
		gets.append("%d %s" % [int(gv.items[k]), Data.ITEMS[k].n])
	if not gets.is_empty():
		parts.append("Brings: " + ", ".join(gets) + ".")
	if o.has("battle"):
		parts.append("It will come to a fight.")
	return "\n".join(parts)

static func pay(g, o: Dictionary) -> void:
	var p: Dictionary = o.get("pay", {})
	g.stones -= int(p.get("stones", 0))
	for k in p.get("items", {}):
		g.inv[k] = int(g.inv.get(k, 0)) - int(p.items[k])

static func gain(g, o: Dictionary) -> void:
	var gv: Dictionary = o.get("gain", {})
	if gv.has("ride"):
		g.grant_ride(str(gv.ride))
	if gv.has("outfit"):
		g.grant_outfit(str(gv.outfit))
	if int(gv.get("stones", 0)) > 0:
		g.stones += int(gv.stones)
		g.toast("+%d spirit stones" % int(gv.stones))
	if int(gv.get("renown", 0)) > 0:
		g.add_renown(int(gv.renown))
	for k in gv.get("items", {}):
		g.add_item(str(k), int(gv.items[k]))
		g.toast("Obtained %d %s" % [int(gv.items[k]), Data.ITEMS[k].n])

## Take option `o` in thread `thread`: its state, a line on the Fates page, what it gives.
static func take(g, thread: String, o: Dictionary) -> void:
	g.fates[thread] = str(o.then)
	var log: Array = g.fate_log.get(thread, [])
	log.append(str(o.get("log", "")))
	g.fate_log[thread] = log
	gain(g, o)
	var title: String = str(FateText.STATES.get(thread, {}).get(str(o.then), [str(o.then)])[0])
	g.toast("%s: %s" % [str(THREADS[thread].n).get_slice(",", 0), title])
	g.note("Fate of %s: %s" % [str(THREADS[thread].n).get_slice(",", 0), title])

## The recipe discount Liu Ying's place at Alchemist Mo's side gives (0 if none).
static func mo_discount(g) -> float:
	return MO_DISCOUNT if state(g, "liu_ying") in APPRENTICE_STATES else 0.0

## A thread's state in words: [title, description].
static func state_text(thread: String, st: String) -> Array:
	if st == "":
		return ["Not yet met", "Somewhere ahead on the road."]
	return FateText.STATES.get(thread, {}).get(st, [st.capitalize(), ""])

## What the ending tells of a thread (its final state's epilogue, "" if none).
static func epilogue(g, thread: String) -> String:
	return str(FateText.EPILOGUE.get(thread, {}).get(state(g, thread), ""))
