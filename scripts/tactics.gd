class_name Tactics
## How a foe chooses what to do with its turn (the Iron Pestle release).  Until now every foe in the
## land fought the same way: a blow at somebody drawn by lot, four times in ten at whoever was worst
## hurt.  Now each fights as what it is.  A jelly still strikes whatever is in front of it.  A wolf
## goes for the one that is bleeding, and for the one its pack is already on.  A fox, a ghost or a
## demon sees who is a blow from falling and finishes them, and knows who has been mending the others.
## A soldier, a warden or a lord does all of that, takes the mark another of its company has called,
## and, hurt and with company still standing, steps back behind them and guards instead of spending
## itself.
##
## Everything here is a pure function of the fighters, of what the battle remembers (`mem`) and of two
## numbers the battle draws (`r1`, `r2`, each 0..1), so the tests can ask what any foe would do with
## any party in front of it.  The battle says aloud what was chosen and why: a foe that is clever
## should be seen to be.

## how a kind of foe thinks
enum {MINDLESS, INSTINCT, CUNNING, TACTICIAN}
const WORDS := ["mindless", "by instinct", "cunning", "a tactician"]
const HINTS := [
	"It strikes at whatever is in front of it.",
	"It goes for the one that is bleeding, and for the one its pack is already on.",
	"It finishes whoever is a blow from falling, and goes for whoever has been mending the others.",
	"It finishes the faltering, silences the mender, takes the mark its company calls, and guards when it is hurt.",
]
## the wits of every shape a foe is drawn in (a shape not listed fights by instinct; a `person:` and a
## lord are tacticians)
const WIT := {
	"blob": MINDLESS, "jelly": MINDLESS, "plant": MINDLESS, "mushroom": MINDLESS, "golem": MINDLESS, "wisp": MINDLESS,
	"storm": MINDLESS, "moth": MINDLESS, "tome": MINDLESS, "hundun": MINDLESS,
	"beast": INSTINCT, "tiger": INSTINCT, "serpent": INSTINCT, "bird": INSTINCT, "spider": INSTINCT, "crab": INSTINCT,
	"scorpion": INSTINCT, "mantis": INSTINCT, "carp": INSTINCT, "ray": INSTINCT, "ox": INSTINCT, "mammoth": INSTINCT,
	"tortoise": INSTINCT, "jade_rabbit": INSTINCT, "magpie": INSTINCT, "sun_crow": INSTINCT,
	"fox": CUNNING, "wraith": CUNNING, "demon": CUNNING, "jiangshi": CUNNING, "ape": CUNNING, "dragon": CUNNING,
	"phoenix": CUNNING, "qilin": CUNNING, "bifang": CUNNING, "kaiming": CUNNING, "frost_maiden": CUNNING,
	"humanoid": TACTICIAN, "warden": TACTICIAN, "queen": TACTICIAN, "oxhead": TACTICIAN, "horseface": TACTICIAN,
	"crowmarshal": TACTICIAN,
	# (the Turned Face release: a toad and a centipede strike at what moves; an owl picks the weakest out of the dark)
	"toad": INSTINCT, "centipede": INSTINCT, "owl": CUNNING,
}
## The Turned Face release: the arts of three kinds of body sculpted for it.  A foe that is not a lord, of one of
## these shapes, uses its art on every third turn of its own (its third, sixth, ...: nothing is thrown for it)
## instead of a plain blow: `to` "one" (whoever its wits would have struck) or "all", at `mult` of a blow, with
## an effect of its own (`fx`: Fx3D.coins, venom, screech) and the cast clip; `said` names it in the log.
const ARTS := {
	"toad": {"n": "Gold Tongue", "to": "one", "mult": 1.35, "fx": "coins", "said": "%s spits a fountain of cash at %s: the Gold Tongue!"},
	"centipede": {"n": "Hundred Steps of Venom", "to": "all", "mult": 0.7, "fx": "venom", "said": "%s rears and every leg strikes at once: the Hundred Steps of Venom!"},
	"owl": {"n": "Screech in the Dark", "to": "all", "mult": 0.6, "fx": "screech", "said": "%s mantles and screeches: a cry nobody in the land can bear!"},
}

## The art a foe uses on this turn of its own ({} for a plain blow): a lord never, and only every third turn.
static func art_of(f: Dictionary) -> Dictionary:
	if bool(f.get("boss", false)) or not ARTS.has(str(f.get("shape", ""))):
		return {}
	return ARTS[str(f.shape)] if int(f.get("turns", 0)) % 3 == 0 and int(f.get("turns", 0)) > 0 else {}

## how often (of r2) a foe of each wit does the clever thing when it is there to be done
const FINISH := [0.0, 0.0, 0.8, 1.0]
const MENDER := [0.0, 0.0, 0.5, 0.6]
const PACK := [0.0, 0.6, 0.5, 0.65]
const WEAKEST := [0.0, 0.5, 0.45, 0.5]
const BRACE := [0.0, 0.0, 0.5, 0.7]
## a foe guards under this share of its health, once a battle, and a guarded foe takes this share of a blow
const BRACE_AT := 0.35
const BRACE_TAKEN := 0.5
## a blow is taken for a finishing one when what it is expected to do is this much of what the victim has left
const FINISH_K := 0.9

## The wits of foe `f` (a battle's fighter, or anything with `shape` and `boss`).
static func wit(f: Dictionary) -> int:
	if bool(f.get("boss", false)) or bool(f.get("doom", false)):
		return TACTICIAN
	var sh := str(f.get("shape", ""))
	if sh.begins_with("person:"):
		return TACTICIAN
	return int(WIT.get(sh, INSTINCT))

## The wits of the kind of foe `id` (Data.ENEMIES), for the bestiary.
static func wit_of(id: String) -> int:
	var d: Dictionary = Data.ENEMIES.get(id, {})
	return wit({"shape": d.get("shape", ""), "boss": d.get("boss", false), "doom": d.get("doom", false)})

static func word(id: String) -> String:
	return WORDS[wit_of(id)]

static func hint(id: String) -> String:
	return HINTS[wit_of(id)]

## What a plain blow of `f` is expected to do to `t` (no luck in it, no crown, no Dao).
static func blow(f: Dictionary, t: Dictionary) -> float:
	return maxf(1.0, float(f.atk) - float(t.def) * 0.5) * Data.suppression(int(f.lv), int(t.lv))

## What the battle remembers for the foes: the round, who of the party mended in which round
## (`mended`: idx -> round), who each kind of foe last went for this round (`struck`: foe id, or "*"
## for the mark a tactician called -> the party member's idx) and who has guarded (`braced`: slot).
static func memory() -> Dictionary:
	return {"round": 0, "mended": {}, "struck": {}, "braced": {}}

## A new round: the marks of the last one are forgotten.
static func new_round(mem: Dictionary, round_no: int) -> void:
	mem.round = round_no
	mem.struck = {}

static func _alive_idx(party: Array, idx: int) -> int:
	for i in party.size():
		if int(party[i].idx) == idx:
			return i
	return -1

## What foe `f` does with its turn: {"act": "strike" or "brace", "to": which of `party` (the living),
## "why": "" (nothing in particular), "finish", "mender", "pack", "mark" or "weak"}.  `allies` are the
## living foes (with `f` among them).
static func choose(f: Dictionary, party: Array, allies: Array, mem: Dictionary, r1: float, r2: float) -> Dictionary:
	var w := wit(f)
	var slot := int(f.get("slot", 0))
	if w >= CUNNING and not bool(f.get("boss", false)) and not bool(f.get("doom", false)) and not mem.braced.has(slot) \
			and allies.size() > 1 and float(f.hp) < float(f.maxhp) * BRACE_AT and r2 < float(BRACE[w]):
		return {"act": "brace", "to": -1, "why": "brace"}
	var lot := clampi(int(r1 * float(party.size())), 0, party.size() - 1)
	if w == MINDLESS or party.size() < 2:
		return {"act": "strike", "to": lot, "why": ""}
	# whoever a blow would fell (the nearest to falling, if there are two)
	if r2 < float(FINISH[w]):
		var fin := -1
		for i in party.size():
			if float(party[i].hp) <= blow(f, party[i]) * FINISH_K and (fin < 0 or float(party[i].hp) < float(party[fin].hp)):
				fin = i
		if fin >= 0:
			return {"act": "strike", "to": fin, "why": "finish"}
	# whoever mended the others this round or the last
	if r2 < float(MENDER[w]):
		for idx in mem.mended:
			var mi := _alive_idx(party, int(idx))
			if mi >= 0 and int(mem.mended[idx]) >= int(mem.round) - 1:
				return {"act": "strike", "to": mi, "why": "mender"}
	# whoever the pack is already on (a tactician: whoever its company has called)
	if r2 < float(PACK[w]):
		var key := "*" if w == TACTICIAN else str(f.get("id", ""))
		if mem.struck.has(key):
			var pi := _alive_idx(party, int(mem.struck[key]))
			if pi >= 0:
				return {"act": "strike", "to": pi, "why": "mark" if w == TACTICIAN else "pack"}
	# whoever is worst hurt
	if r2 < float(WEAKEST[w]):
		var low := 0
		for i in party.size():
			if float(party[i].hp) / float(party[i].maxhp) < float(party[low].hp) / float(party[low].maxhp):
				low = i
		if float(party[low].hp) < float(party[low].maxhp):
			return {"act": "strike", "to": low, "why": "weak"}
	return {"act": "strike", "to": lot, "why": ""}

## What the battle remembers once `f` has gone for the party member whose idx is `idx`.
static func struck(mem: Dictionary, f: Dictionary, idx: int) -> void:
	mem.struck["*" if wit(f) == TACTICIAN else str(f.get("id", ""))] = idx

## What is said of a choice ("%s" the foe, then the victim).
const SAID := {
	"": "%s attacks %s.",
	"weak": "%s goes for %s, who is hurt.",
	"finish": "%s sees %s falter, and goes for the finish.",
	"mender": "%s goes for %s, who has been mending the others.",
	"pack": "%s follows the pack onto %s.",
	"mark": "%s takes the mark called on %s.",
}
const BRACE_SAID := "%s draws back behind the others and guards."
