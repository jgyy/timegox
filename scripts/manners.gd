class_name Manners
extends RefCounted
## The Unpicked Road release: people answer what is done in front of them.  Until now a blade swung
## in the street made everybody start alike (world.gd `_folk_start`), a body walked into stepped
## out of the way without a word, and nobody had an opinion about a cultivator hopping about the
## market like a boy.  Here is who answers what, and how:
##
##   a deed       strike (a blade swung near them), jump, land (a leap that comes down beside them),
##                bump (walked into), bump_ride (ridden into), bump_laden (walked into under a load),
##                and what is done with the small things (trifles.gd): buy, pilfer (somebody's own
##                pocketed in front of them), altar (an offering taken), whose (a lost thing picked
##                up: they know whose it is), wild (a thing of nobody's), back (put back), play
##   a witness    one of nine kinds, by what they are (`kind_of`): kid, elder, watch, trade,
##                learned, holy, cult (a disciple), giant, hand (everybody who works with theirs)
##
## `answer` is pure: the deed, the witness, how he is addressed and a count that turns the lines over.
## It returns who speaks, a line short enough to be said over a head in the street, and the gesture it
## is said with (a clip everybody has, or one the party lends).  **It decides nothing**: what a deed
## costs is the business of whoever counts it (trifles.gd, crime.gd, weal.gd).  With no window nobody
## is drawn answering, and the bot's journey is the same.
##
## A new deed needs a line under "any" at least; a new kind of witness a line in `kind_of`.

const TRADE := ["merchant", "cook", "waiter", "smith", "fisher", "pedlar"]
const WATCH := ["guard", "watchman", "soldier"]
const LEARNED := ["scholar", "musician"]
const HOLY := ["monk", "pilgrim", "hermit"]
const KINDS := ["kid", "elder", "watch", "trade", "learned", "holy", "cult", "giant", "hand"]
## how far (in tiles) a deed in the street is seen
const SIGHT := 5

## deed -> kind of witness (or "any") -> [lines].  {a}: how he is addressed; {thing}; {who}: whose it
## is; {town}.
const LINES := {
	"strike": {
		"kid": ["Do it again! Do the one that goes round!", "Is it sharp? Is it very sharp? Can it cut a hair?"],
		"elder": ["In my day a blade was drawn at something, {a}.", "Mind the washing line. It has done you no harm."],
		"watch": ["Sheathe it in the street, {a}, if you please.", "Steel out inside the gate? I shall have to write that down."],
		"trade": ["Not over the stall! Not over the stall!", "If that touches my awning, {a}, it is bought."],
		"learned": ["The form is sound. The place is not.", "Ah. I had heard the wind did that, and not believed it."],
		"holy": ["The grass was not your enemy, {a}.", "Namo. And what had the air done?"],
		"cult": ["Senior! Was that the seventh form? Slower, I beg you!", "The wrist. I saw it. I shall never get the wrist."],
		"giant": ["A little knife. You swing it well, small one.", "Careful. You will cut yourself, at that height."],
		"hand": ["Whoa! Easy there, {a}!", "I have a field wants mowing, if you are at a loose end."],
		"any": ["Heavens! Mind that!", "A sword, here? At this hour?"],
	},
	"jump": {
		"kid": ["Higher! Go higher! I can nearly do that!", "Look! Look! Like a frog! Like a GREAT frog!"],
		"elder": ["And at your realm, {a}. Well, well.", "My knees hurt to watch it. Go on, though."],
		"watch": ["No law against it. I looked, once.", "Mind the eaves, {a}. They were tiled this spring."],
		"trade": ["If you land in the pears, {a}, they are sold.", "A cultivator in the air is bad for trade. Everybody looks up."],
		"learned": ["Lightness of body. The classics put it more gravely.", "So that is the Cloud-Stepping art. I had pictured it taller."],
		"holy": ["The ground will have you back. It always does.", "Up, and down again. That is most of the sutra."],
		"cult": ["Senior is practising light-body in the STREET.", "Nine feet clear! I counted. I am going to tell everybody."],
		"giant": ["That is nearly up to my belt. Well done.", "Ha! Again, small one. You almost saw my face."],
		"hand": ["Spry! I could do that once, with nothing on my back.", "What is up there, then? Anything worth having?"],
		"any": ["Well jumped!", "Now what was that for?"],
	},
	"land": {
		"kid": ["You jumped right OVER it! Do me next!", "Ha! You nearly landed on my foot!"],
		"elder": ["Out of the sky, at my age! Give a body warning.", "I thought the roof had come down."],
		"watch": ["Halt! ...Oh. It is you, {a}. Use the road.", "Come down gently in a town, {a}. People spill things."],
		"trade": ["My heart! And my eggs, very nearly!", "Feet first into the market. Buy something, at least."],
		"holy": ["You arrive like a thought. Sit a moment.", "Softly, softly. The ants live here too."],
		"giant": ["Something small fell by my boot. Oh, it is you.", "Mind my toes, small one. They are a long way from my eyes."],
		"any": ["Aiya! Where did you come from?", "Out of the air! My word."],
	},
	"bump": {
		"kid": ["Ow! You walked into me! You are as hard as a wall!", "Hey! I was standing here first!"],
		"elder": ["Steady, steady. I do not mend as I did.", "Young legs. Look where they are taking you, {a}."],
		"watch": ["Easy. Nobody is chasing you, {a}. I should know.", "Mind how you go. That was the watch you walked into."],
		"trade": ["Careful! That is a day's takings in this basket.", "You will have my wares in the road, {a}."],
		"learned": ["I beg your pardon. No: you beg mine, I think.", "My place! You have lost me my place in the page."],
		"holy": ["No harm. We were both where the other was going.", "Peace. The road is wide enough for two."],
		"cult": ["Senior! Forgive me, I was in your way!", "I did not see you, Senior. I was counting breaths."],
		"giant": ["Hm? Did something touch my knee?", "Oh! Are you hurt, small one? You hit me quite hard, for you."],
		"hand": ["Oi! Eyes in front, {a}!", "Mind out! I have had a long day already."],
		"any": ["Oof! Look where you are going!", "Mind yourself!"],
	},
	"bump_ride": {
		"kid": ["The horse nearly ATE me!", "You are not allowed to gallop here. My granny says."],
		"elder": ["Ride me down in my own street, would you!", "There was a time riders dismounted at the gate."],
		"watch": ["Walk that beast inside the gate, {a}!", "Dismount in the street! I shall not say it twice."],
		"giant": ["Whoa. I have caught your horse. Here, have it back.", "Your horse has walked into me. It looks sorry."],
		"any": ["Mind where you ride, {a}!", "Hooves! In the market! Have you no bell?"],
	},
	"bump_laden": {
		"kid": ["You are carrying a whole house! Can I ride on top?", "Ow! Your sack hit me. What is IN there?"],
		"elder": ["Bent double and still in a hurry. Set it down, {a}.", "That load will outlive you. Mind me with it."],
		"hand": ["Heavy, is it? Take the corner wide, {a}; I do.", "That is a porter's load. Bend the knees, not the back."],
		"giant": ["Let me past, small one. Or shall I carry that, and you?", "A big load for a little back. Mind my shins."],
		"any": ["Mind your load! It has corners!", "Steady with that. You nearly had me over."],
	},
	"buy": {
		"trade": ["And a good choice. Come again, {a}.", "Fresh this morning. None better this side of the pass."],
		"any": ["That is fairly bought. Thank you, {a}.", "Take it, and welcome."],
	},
	"pilfer": {
		"kid": ["You TOOK it! I saw! I am telling!", "That is {who}'s. You did not even ask."],
		"elder": ["I am old, {a}. I am not blind. That is {who}'s {thing}.", "Put it back, child. Nobody need hear of it."],
		"watch": ["That {thing} is {who}'s, {a}. I saw the hand go.", "Stop there. What went into your sleeve was not yours."],
		"trade": ["Thief! ...I mean: {a}. That is not paid for.", "I count my stock, {a}. Every evening. Twice."],
		"learned": ["One does not lace a shoe in a melon field.", "I saw nothing. I saw it very clearly, however."],
		"holy": ["What is taken so weighs more than it looks, {a}.", "It is only a {thing}. That is how it begins."],
		"cult": ["Senior... that was {who}'s. Was it a test?", "I shall pretend I was looking the other way, Senior."],
		"giant": ["Small hands, small thefts. Put it back, small one.", "I see everything from up here. That was {who}'s."],
		"hand": ["Here! That is {who}'s {thing}!", "We do not do that here, {a}. Not even you."],
		"any": ["That is {who}'s!", "You are not walking off with that?"],
	},
	"altar": {
		"kid": ["That is the god's! You will get a stomach-ache!", "Granny says a hand that does that drops off."],
		"elder": ["Off the altar! In all my years, {a}.", "That was laid there for the dead. They notice."],
		"watch": ["From the offering table, {a}? There is no fine. There is worse.", "Put it back before the incense is out."],
		"holy": ["It was given already, {a}. Only not to you.", "Take it, if you are hungrier than the god."],
		"any": ["From the altar! For shame!", "That was an offering, {a}."],
	},
	"whose": {
		"kid": ["That is {who}'s! She has been crying. Well, sniffing.", "I know whose that is! It is {who}'s! Can I carry it?"],
		"elder": ["{who}'s {thing}. The door will be glad of a knock.", "That will be {who}'s. Nobody else in {town} has one."],
		"watch": ["{who} was asking after a {thing}. You will know the door.", "Found in the road? That is {who}'s. I had a description."],
		"trade": ["{who} dropped that. Up and down the street all morning.", "A {thing}? {who}'s. I would know it anywhere."],
		"any": ["That is {who}'s {thing}. They will be looking for it.", "You have found {who}'s {thing}! The whole street has heard."],
	},
	"wild": {
		"kid": ["What is it? What have you got? Show me!", "A {thing}! I have nine. Mine are bigger."],
		"elder": ["A {thing}. I kept those in a box, once.", "Pockets full of the country, like a boy."],
		"learned": ["A {thing}. There is a line in the Odes about one.", "The ten thousand things; and you stoop for that one."],
		"any": ["A {thing}? What do you want with that?", "Found something, {a}?"],
	},
	"back": {
		"kid": ["You put it back. I was nearly going to tell.", "It was not lost. It was only waiting."],
		"watch": ["Put back. Then I saw nothing.", "Good. I have forgotten it already."],
		"any": ["That is better.", "Thank you, {a}. No harm done."],
	},
	"play": {
		"kid": ["My turn! My turn! You have had a go!", "You are GOOD. Who taught you? Was it an immortal?"],
		"elder": ["You were a child on this mountain too, I see.", "Wind it tighter. No, tighter. Give it here."],
		"any": ["Ha! Not bad, {a}.", "At your age!"],
	},
}
## deed -> kind (or "any") -> the gesture it is answered with
const CLIPS := {
	"strike": {"kid": "clap", "elder": "shake", "watch": "point", "learned": "think", "holy": "shake", "cult": "bow", "giant": "laugh", "any": "shock"},
	"jump": {"kid": "jump", "elder": "shake", "watch": "nod", "learned": "think", "holy": "nod", "cult": "clap", "giant": "laugh", "hand": "laugh", "any": "wave"},
	"land": {"kid": "laugh", "giant": "nod", "holy": "bow", "any": "shock"},
	"bump": {"cult": "bow", "holy": "bow", "giant": "think", "learned": "shake", "any": "shock"},
	"bump_ride": {"giant": "laugh", "watch": "point", "any": "shock"},
	"bump_laden": {"hand": "nod", "giant": "laugh", "any": "shock"},
	"buy": {"any": "bow"},
	"pilfer": {"kid": "point", "watch": "point", "elder": "shake", "learned": "think", "holy": "shake", "cult": "shock", "any": "shock"},
	"altar": {"holy": "grieve", "any": "shock"},
	"whose": {"kid": "point", "any": "point"},
	"wild": {"kid": "point", "any": "think"},
	"back": {"any": "nod"},
	"play": {"kid": "clap", "any": "laugh"},
}

## What kind of witness person `p` of the towns or the road is.
static func kind_of(p: Dictionary) -> String:
	if p.is_empty():
		return "hand"
	var role := str(p.get("role", ""))
	if bool(p.get("kid", false)):
		return "kid"
	if role == Giants.ROLE:
		return "giant"
	if bool(p.get("old", false)) or role == "elder":
		return "elder"
	if role in WATCH:
		return "watch"
	if role in TRADE:
		return "trade"
	if role in LEARNED:
		return "learned"
	if role in HOLY:
		return "holy"
	if role == "disciple":
		return "cult"
	return "hand"

## The people of the towns and the road who would see something done on `tile` of realm `wd` at this
## hour, the nearest first (each a person of folk.gd): those standing or walking within SIGHT tiles.
static func watchers(g, wd: Dictionary, tile: Vector2i, r: int = SIGHT) -> Array:
	var out: Array = []
	if not wd.has("owner") or wd.has("level"):
		return out
	var area := Atlas.owner_id(wd, tile)
	var at := Vector2(tile) + Vector2(0.5, 0.5)
	var ds := {}
	for p in Folk.of_area(wd, area):
		if not g.slain.is_empty() and Crime.gone(g, str(p.id)):
			continue
		var st := Folk.state(wd, p, float(g.clock))
		if not bool(st.vis):
			continue
		var d := (st.at as Vector2).distance_to(at)
		if d <= float(r):
			ds[str(p.id)] = d
			out.append(p)
	out.sort_custom(func(a, b): return float(ds[str(a.id)]) < float(ds[str(b.id)]))
	return out

## The person with id `pid` among `seen`, or {}.
static func find(seen: Array, pid: String) -> Dictionary:
	for p in seen:
		if str(p.id) == pid:
			return p
	return {}

## How witness `p` answers `deed`: {who, kind, line, clip}.  `ctx`: thing, who, town, and `mine` (the
## owner's own words for their own thing, said instead of the street's).  `k` turns the lines over.
static func answer(deed: String, p: Dictionary, g, ctx: Dictionary = {}, k: int = 0) -> Dictionary:
	if not LINES.has(deed):
		return {}
	var kind := kind_of(p)
	var tbl: Dictionary = LINES[deed]
	var ls: Array = tbl.get(kind, tbl.get("any", []))
	if ls.is_empty():
		return {}
	var line := str(ls[(absi(int(p.get("seed", 0))) + k) % ls.size()])
	if str(ctx.get("mine", "")) != "":
		line = str(ctx.mine)
	line = line.replace("{a}", str(g.address())).replace("{thing}", str(ctx.get("thing", "thing"))).replace("{who}", str(ctx.get("who", "somebody"))).replace("{town}", str(ctx.get("town", "the town")))
	var ct: Dictionary = CLIPS.get(deed, {})
	return {"who": str(p.get("n", "Somebody")), "kind": kind, "line": line, "clip": str(ct.get(kind, ct.get("any", "shock")))}

## Which bump it was: ridden into, walked into under a load (load.gd: heavy or worse), or only walked
## into.
static func bump_deed(riding: bool, tier: int) -> String:
	if riding:
		return "bump_ride"
	return "bump_laden" if tier >= 2 else "bump"

## How far somebody walked into is put out of their way (metres), by what they are and what hit them:
## a child goes further than a porter, one of the Great People does not move at all, and a horse
## moves anybody.
static func shove(p: Dictionary, deed: String) -> float:
	var kind := kind_of(p)
	if kind == "giant":
		return 0.0
	var d := 0.5
	if kind == "kid":
		d = 0.8
	elif kind == "elder":
		d = 0.65
	elif kind in ["watch", "hand"]:
		d = 0.35
	if deed == "bump_ride":
		d += 0.6
	elif deed == "bump_laden":
		d += 0.25
	return d
