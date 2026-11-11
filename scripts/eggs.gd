class_name Eggs
extends RefCounted
## Things nobody told you to look for (the Thundering Pots release).  Twelve of them: no step of the
## story names one, no notice on the board asks for one, and the page that lists them (Esc > Feats,
## under The Unasked) shows a question mark and half a hint until each is found.  Each says a few
## lines when it is found, is kept in `Game.eggs`, and some give something (an outfit, a hidden tune,
## a duck).
##
## Most are a state of the world looked at now and then (`poll`); a few are told by whoever sees them
## happen (`find`, from the title screen, the field of war, the songbook, a conversation, a bell).

const EGGS := {
	"old_code": {"n": "The Old Code", "hint": "Older than the sect: up, up, and so on. Where the journey has not yet begun.",
		"lines": [["Narrator", "In the cupboard under the stair, behind the buckets, where it has been the whole time: the robe he swept in, patched until there is more patch than robe, and the first broom."],
			["Yue Ling", "You kept it? ...Of course you kept it. Put it on. No, the broom too. There. That is the most frightening cultivator I have ever seen.", "laugh"]]},
	"namesake": {"n": "A Name Already Taken", "hint": "Some names were somebody's first.",
		"lines": []},
	"midnight_summit": {"n": "The Third Watch, the Very Top", "hint": "Be on a summit when the day turns.",
		"lines": [["Narrator", "Midnight, on the very top, and nothing above but the Silver River from one edge of the world to the other. A star comes away from it and falls, slowly, the way a thing falls that has all night."],
			["Yue Ling", "Do not wish out loud. ...I have made mine. It was not for me.", "nod"]], "stones": 888},
	"good_listener": {"n": "The Good Listener", "hint": "Somebody has more to say than anybody has ever stayed to hear.",
		"lines": [["Narrator", "Twelve times. Nobody has ever stayed for all of it before. There is a silence in which a person finds out they have nothing left to say, and is surprised how pleasant it is."],
			["Yue Ling", "You have heard everything they know. That is a thing people give only once. Be careful with it.", "nod"]], "renown": 3},
	"thirty_sixth": {"n": "The Thirty-Sixth Stratagem", "hint": "Of the thirty-six, the last is the best. Master Sun did not write it.",
		"lines": [["Narrator", "Three drums running the host has given ground, in good order, with its flags up. From the far side of the field comes the sound of eight thousand soldiers wondering what to do with an enemy that will not stay to be beaten."],
			["Yue Ling", "Of the thirty-six stratagems, running away is the best. Tan Daoji said it of a general he despised. I notice he said it from a long way off.", "laugh"]]},
	"sweeper_still": {"n": "Still the Sweeper", "hint": "Go and see the Elder as you were, when you are no longer what you were.",
		"lines": [["Elder Qing Xuan", "Sixty realms up, and he comes to me in the robe with the patched elbows. Hm. Do you know, I have kept the roster of this sect for seventy years, and under 'sweeper' it has only ever had the one name. I never crossed it out.", "nod"],
			["Elder Qing Xuan", "The east steps want doing. No hurry. They have waited this long."]], "renown": 5},
	"all_songs": {"n": "The Tune Nobody Wrote Down", "hint": "Ask the songbook for everything in it.",
		"lines": [["Narrator", "At the back of the songbook, after the last tune, there is one more leaf. Nobody wrote it. It is what a boy whistles through his teeth with a broom in his hands, on a cold morning, on the nine hundred and ninety-nine steps of the Azure Cloud Sect."],
			["Yue Ling", "That is the one you do when you think nobody is listening. I have been listening for years.", "nod"]]},
	"night_kite": {"n": "Seen from the Loom", "hint": "Fly when only the Weaver is awake to see it.",
		"lines": [["Narrator", "A paper swallow going over the land in the dead of night, lit from above by nothing but the Silver River. On the far bank of it, at her loom, somebody looks up, and for a moment the shuttle stops."],
			["Yue Ling", "She waved. I am nearly sure she waved. Wave back, you have a hand free. ...No you have not. I will do it.", "wave"]]},
	"idle": {"n": "Doing Nothing", "hint": "The hardest thing in the Dao. Stand there.",
		"lines": [["Yue Ling", "Are you asleep? Standing up? ...No. You are only standing. I did not know you could. The Old Master says the sage does nothing, and nothing is left undone. I always thought that was an excuse.", "think"],
			["Narrator", "A long while of nothing at all. A beetle crosses the path. The land goes on without being saved for some minutes, and seems none the worse."]]},
	"clay_duck": {"n": "The Duck", "hint": "Somewhere under Qingshi, something yellow.",
		"lines": [["Narrator", "At the back of the dark, on a ledge, where no kiln in the land could have put it: a small duck of fired clay, glazed yellow. Pressed, it squeaks. Under the base, in a potter's scratch: for the bath of the Son of Heaven. Reject."],
			["Yue Ling", "It is the most beautiful thing I have ever seen. We are keeping it. This is not a discussion.", "cheer"]]},
	"full_moon": {"n": "The Rabbit in the Moon", "hint": "Look up, the fifteenth night.",
		"lines": [["Narrator", "The fifteenth night, and the moon full. On it, quite plainly, for anybody who stops to look: a rabbit, upright, pounding something in a mortar. It does not stop. It has not stopped in four thousand years. Tonight, for the length of one breath, it looks down."],
			["Yue Ling", "It is the elixir, Chang'e says. He is nearly finished. He has been nearly finished since the Xia.", "nod"]], "item": "qi_pill"},
	"bell_nine": {"n": "Nine Strokes", "hint": "A bell rung once is the hour. Rung nine times it is something else.",
		"lines": [["Narrator", "Nine strokes on the one bell, one after another, by somebody with no reason to. Nine is the number of Heaven. Somewhere a long way up, a clerk of the Celestial Court starts awake at his desk, finds nothing in the ledger, and writes: bell. cause unknown. sweeper suspected."]], "renown": 2},
}
const ORDER := ["old_code", "namesake", "midnight_summit", "good_listener", "thirty_sixth", "sweeper_still", "all_songs", "night_kite", "idle", "clay_duck", "full_moon", "bell_nine"]

## The old code, on the title screen before anything begins: up up down down left right left right.
const CODE := ["up", "up", "down", "down", "left", "right", "left", "right"]
## Names that were somebody's first (family or given, as the creation screen cleans them): who it
## was, and what is said the first morning.
const NAMESAKES := {
	"Wukong": "Granny Wen looked at the name a long time. The last Wukong, she said, ate a whole orchard of peaches that were not his and had to be sat on by a mountain. She gave him an extra bowl anyway, in case it ran in the name.",
	"Nezha": "The last Nezha, said Granny Wen, quarrelled with a dragon at seven and was rebuilt out of lotus root. She has kept this one away from the river ever since, to be on the safe side.",
	"Mulan": "The last of that name, said Granny Wen, went to the wars in her father's place for twelve years and nobody in her tent once knew. She said it as if it were a recommendation.",
	"Erlang": "The last Erlang had a third eye and a dog that bit the sun, said Granny Wen. This one has two eyes and no dog, and she considers it a mercy.",
	"Libai": "The last Li Bai, said Granny Wen, drowned trying to embrace the moon in a river, drunk, and wrote better than anybody has since. She has watered the wine in this house ever since the naming.",
	"Jiang": "The Grand Duke Jiang fished with a straight hook, said Granny Wen, three feet above the water, and caught a king. She has always thought the name a patient one.",
	"Laozi": "The Old Master rode out of the western pass on an ox and was not seen again, said Granny Wen, and left five thousand words at the gate because the keeper would not let him by without. She hopes this one writes home oftener.",
	"Hanxin": "The last Han Xin crawled between a bully's legs sooner than fight him, said Granny Wen, and afterwards led the armies of Han. She told the story whenever the boy came home with a split lip.",
	"Zhuge": "The last Zhuge borrowed a hundred thousand arrows from his enemy with boats of straw, said Granny Wen. She has counted the spoons after every visit since the naming.",
	"Yu": "Yu the Great passed his own door three times in thirteen years of taming the flood and did not go in, said Granny Wen. She thinks it a fine name, and a poor example.",
}

## the title's keys so far, and whether the old code has been keyed since the last journey began
static var keyed: Array = []
static var code_done := false
## how long the hero has stood on one tile (for "idle"), and where
static var _still := 0.0
static var _still_tile := Vector2i(-1, -1)
static var _last_t := 0.0
## what `poll` is told about the world by whoever has one (world.gd): whether the hero stands on a
## summit, and whether he is in the air
static var on_summit := false
static var gliding := false
static var busy := false

## A key on the title screen.
static func title_key(act: String) -> bool:
	keyed.append(act)
	while keyed.size() > CODE.size():
		keyed.pop_front()
	if keyed == CODE and not code_done:
		code_done = true
		return true
	return false

static func found(g, id: String) -> bool:
	return g.eggs.has(id)

## Something was found: told, kept, and what it gives given.  `extra` lines are said first.
static func find(g, id: String, extra: Array = []) -> bool:
	if g.eggs.has(id) or not EGGS.has(id):
		return false
	var e: Dictionary = EGGS[id]
	g.eggs[id] = g.playtime
	g.toast("Found: %s" % str(e.n))
	g.note("Found, unasked: %s" % str(e.n))
	var lines: Array = extra.duplicate()
	for l in e.lines:
		# (Yue Ling speaks only if she is there)
		if str(l[0]) != "Yue Ling" or g.companion:
			lines.append(l)
	if not lines.is_empty():
		g.egg_pending.append(lines)
	if e.has("stones"):
		g.stones += int(e.stones)
		g.toast("+%d spirit stones" % int(e.stones))
	if e.has("renown"):
		g.add_renown(int(e.renown))
	if e.has("item"):
		g.add_item(str(e.item))
	g.grant_earned("egg", id)
	return true

## The name the hero was given, if it was somebody's first ("" if not).
static func namesake(g) -> String:
	for k in [str(g.hero.get("given", "")), str(g.hero.get("family", "")), str(g.hero.get("family", "")) + str(g.hero.get("given", "")).to_lower()]:
		if NAMESAKES.has(k):
			return k
	return ""

## Looked at now and then (Feats.poll): the things that are a state of the world.
static func poll(g) -> void:
	var dt: float = clampf(g.playtime - _last_t, 0.0, 5.0)
	_last_t = g.playtime
	if code_done:
		# (keyed on the title before this journey began; the next journey wants it keyed again)
		code_done = false
		find(g, "old_code")
	var nk := namesake(g)
	if nk != "" and g.step >= 1:
		find(g, "namesake", [["Narrator", str(NAMESAKES[nk])]])
	var h := Clock.hour(g)
	if on_summit and (h >= 23.0 or h < 1.0):
		find(g, "midnight_summit")
	if gliding and h >= 0.0 and h < 3.5 and g.companion:
		find(g, "night_kite")
	if g.inv.get("clay_duck", 0) > 0:
		find(g, "clay_duck")
	if g.day % 30 == 15 and (h >= 20.0 or h < 3.0) and not busy and g.step > 3:
		find(g, "full_moon")
	# doing nothing: three minutes on one tile with nothing going on
	if g.tile == _still_tile and not busy:
		_still += dt
		if _still >= 180.0 and g.step > 3:
			find(g, "idle")
	else:
		_still = 0.0
		_still_tile = g.tile

## Somebody named has been spoken to (main.talk_npc): the twelfth time with the same person.
static func talked(g, npc: String) -> void:
	g.npc_talks[npc] = int(g.npc_talks.get(npc, 0)) + 1
	if int(g.npc_talks[npc]) >= 12 and npc != "elder":
		find(g, "good_listener")
	if npc == "elder" and str(g.outfit) == "sweeper" and g.level >= 60:
		find(g, "sweeper_still")

## A thing of the land has been used (props.gd): the ninth stroke on one bell.
static func used(g, kind: String, times: int) -> void:
	if kind == "bell" and times >= 9:
		find(g, "bell_nine")

## The page's line for one: its name once found, a question mark and its hint until then.
static func label(g, id: String) -> String:
	return str(EGGS[id].n) if g.eggs.has(id) else "?  " + str(EGGS[id].hint)
