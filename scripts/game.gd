extends Node
## Global game state (autoload "Game"): party, progression, quest chain and the play clock.

signal quest_changed
signal level_changed

var started := false
var finished := false
var playtime := 0.0          # seconds of game time since "New Game"
var level := 0
var exp := 0.0
var stones := 60
var inv := {"hp_pill": 3, "qi_pill": 1}
var step := 0
var area := "sect"
var tile := Vector2i(-1, -1)  # world tile (see atlas.gd), in the tiles of `layer`
## the realm Lin Feng is in: "surface" (the Unbroken Land), "heaven", "under", or the floor of a
## building ("f:...", see Atlas.floor_id)
var layer := "surface"
var companion := false
var temper := 0
var hp := [80.0, 0.0]
var qi := [40.0, 0.0]
var boss_done := {}
var taken := {}
var defeated := {}
var kills := 0
var battles := 0
var deaths := 0
var meditated := 0.0
var hunt := 0
## the Hollow Hills release (caves.gd): the caves Lin Feng has been to the very back of (the id of the
## cave's floor -> true), and the things of a cave done during the step that asks for them (their kind)
var delved := {}
var step_uses := {}
## the High Roads release (peaks.gd): the summits stood on (the peak's id -> true), the metres of rock
## climbed, the flights under the kite (how many, the tiles flown in all, the longest, and the
## greatest height come down in one) and the wayfarers met on the road (wayfarers of folk.gd)
var summits := {}
var climbed := 0.0
var glides := 0
var glided := 0
var glide_best := 0
var glide_drop := 0.0
## the longest flight since the step of the story that asks for one began (tiles)
var step_glide := 0
var timeline: Array = []
var toasts: Array = []
## regions Lin Feng has set foot in (their histories go into the Annals)
var seen := {}
## Part XI: the Dao Lin Feng walks ("" until the Jianmu grows back), the mastery points he has in
## each, how often he has changed roads; his standing with each people of the realms and the peoples
## he has met
var dao := ""
var dao_xp := {}
var dao_switches := 0
var standing := {}
var met := {}
## Part XII: the branches of the Nine Heavens root Lin Feng has woken (talent id -> rank 1..3), the
## awakenings he has not yet spent, the Founder's sealed caves he has opened, and how many packs have
## scattered before his aura
var talents := {}
var talent_pts := 0
var awakenings := 0
var abodes := {}
var scattered := 0
## Many roads (Part XIII's release, see trials.gd): Lin Feng's renown (the respect of the world), the
## trials he has passed and the path he took through each, the paths he has already paid for (a lost
## battle does not charge twice), the deeds he has done for townsfolk and the Eight Gates he has opened
var renown := 0
var trials := {}
var paid := {}
var deeds := {}
var gates_open := {}
## the leaders Lin Feng has carried the Conclave's invitations to (Part XIII)
var visited := {}
## things done in the world (props.gd): the kinds of thing he has done at least once (his pastimes),
## how often he has used each thing, the things that gave up a find, and when each last gave
## something that comes back with time (herbs, training)
var pastimes := {}
var prop_uses := {}
var prop_found := {}
var prop_t := {}
## Fates and Faces (fashion.gd, fate.gd, lore.gd): who the player made Lin Feng (name, look, colours,
## origin), the outfits he owns and wears, the rides he owns, the one he summons and whether he is in
## the saddle; the fated encounters (thread -> its state, and the choices made in it, in order); the
## small choices of the road (a choice id -> the option taken); the foes he has met (species -> how
## many battles) and the bosses whose story has been told
var hero := {}
var outfits := {}
var outfit := "sweeper"
var rides := {}
var ride := ""
var riding := false
var fates := {}
var fate_log := {}
var picks := {}
var bestiary := {}
var told := {}
## the grudges that stayed (grudges.gd, Part XIV): grudge boss id -> the option taken once it was spent
var grudges := {}
## Yue Ling (bonds.gd, the Lotus release): how close the two of them are, which way her heart leans
## (future -> weight), the heart-to-hearts had (talk -> the reply given), her wishes granted, when each
## kind of thing was last done together, the memories given back to her in Part XV (memory -> what Lin
## Feng said), the people who tied a thread for her (Part XV) and the future she chose for herself
var bond := 0
var heart := {}
var talks := {}
var wishes := {}
var shared := {}
var memories := {}
var threads := {}
var future := ""
## the Living Land release (clock.gd): the minute of the day (0..1440) and the day it is
var clock := Clock.START
var day := 1
## the people of the towns (folk.gd): how often Lin Feng has talked with each
var folk_talk := {}
## things broken (havoc.gd): thing id -> the minute of the game it broke (mended by the next dawn),
## and how many things he has broken in all
var broken := {}
var smashed := 0
## Part XVI: the towns Lin Feng reminded of the old ways (npc id -> true), and the people of the towns
## he has done what a step asked of with (step id -> {townsperson id -> true}): the merchants he bought
## red paper from, the children he gave a red envelope to
var rallied := {}
var folk_done := {}
## the Sword's Wake (impact.gd, the Spring Thunder release): things of the land felled or shattered on
## screen (key -> the minute of the game; they grow back by the next dawn) and how many in all; the
## obstacles of the story cleared (id -> "kind|region") and the blows landed on those not yet cleared;
## and how often Lin Feng struck a pack first, threw the sword qi and swung at the world at all
var felled := {}
var felled_n := 0
var cleared := {}
var obstacle_hits := {}
var ambushes := 0
var waves := 0
var strikes := 0
## steps just finished that have words to say about it, waiting for the world ("done:<step>")
var done_pending: Array = []
## the Six Hearths (cultures.gd, the New Fire release): standing with each hearth of the land; the
## named people of the hearths the hero has sat down with; the hearth whose farewell is still to be
## said (the beginning of the game: "" once the story proper has begun); and the end chosen
var hearth := {}
var sat := {}
var prologue := ""
## the Hundred Works release: the works built (works.gd: id -> the day it was built), the crossroads
## of the road and what was chosen at each (echoes.gd; `picks` keeps the choices themselves), and the
## three scales those choices tip (echoes.gd SCALES: scale -> points)
var works := {}
var scales := {}
var echoed := {}
## crossroads reached in play and not yet answered (asked by Main once nothing else is going on)
var cross_pending: Array = []
var ending := ""
## the Hundred Arms release (arms.gd): the weapons he owns, the one in his hand, the battles each has
## won (its Dao's mastery), and how often he has changed from one to another
var arms := {"sword": true, "staff": true}
var arm := "sword"
var arm_xp := {}
var arm_switches := 0

## ---- the Thundering Pots release
## Yue Ling's dresses and the one she wears (fashion.gd YUE_OUTFITS); every outfit the hero has had on
var yue_outfits := {"lotus": true}
var yue_outfit := "lotus"
var worn := {"sweeper": true}
## feats (feats.gd: id -> the play time it was done at) and what was found that nobody was told to
## look for (eggs.gd)
var feats := {}
var eggs := {}
## the tunes heard (music.gd) and the airs of the land learned (id -> true), and how many times a
## tune was asked for in the songbook
var heard := {}
var airs := {}
var songs_played := 0
## the host (war.gd): the companies raised, the field battles won (id -> drums it took) and lost, the
## orders given (order -> times) and how many drums running the host has given ground
var host := {}
var war_won := {}
var war_lost := 0
var war_orders := {}
var war_feints := 0
var war_tries := {}
var songs_asked := {}
## survival (needs.gd): whether the body is asked after at all, the seven needs, the water gourd, the
## clock they were last reckoned at, and how often each has had its way
var survival := false
var needs := {}
var gourd := 0
var needs_clock := 0.0
var needs_fell := {}
## courtship (romance.gd): the stage, the gifts given, the hours had together, and the tone taken
var romance := {}
## Old Du's mat (gamble.gd): the throws so far (every throw is drawn from this count), and how it has gone
## the Lost Horse release: what the choices left standing that has been looked at (marks.gd); and the
## things that could not be beaten (dooms.gd): how each was lost, how often, how often by giving way
var marks_seen := {}
## (offices.gd: shifts worked at the trades of the towns, and the day the last one was worked in each town)
## (reckon.gd: the last lords of the story that were faced)
var reckoned := {}
## (carriages: who is being carried for a fare, offices.gd: {id, n, asset, to, pay}; and how many have been)
var passengers: Array = []
var fares := 0
## (the post, mail.gd: letters opened, answers written, bags carried {from, to, pay, day}, the day a
## counter last gave one, bags handed over, and how many waiting letters he has been told of)
var mail_read := {}
var mail_replies := {}
var mail_bags: Array = []
var bag_day := {}
var bags_done := 0
var mail_told := 0
var shifts := {}
var shift_day := {}
## (careers: the day the last shift was worked at each trade in each town, for the salary; all wages earned)
var salary_day := {}
var wages := 0
var falls := {}
var fallen := 0
var yielded := 0
var gamble_n := 0
var gamble_rounds := 0
var gamble_wins := 0
var gamble_won := 0
var gamble_lost := 0
var gamble_best := 0
var gamble_streak := 0
var gamble_triples := 0
## the commissions of the notice board (jobs.gd): id -> "taken" or "done", and what each was at when
## it was taken (to count from)
var jobs := {}
var job_base := {}
## how many times each named person has been spoken to (eggs.gd), and the foes felled by kind
var npc_talks := {}
var felled_kind := {}
## what was said when something was found (eggs.gd), waiting to be shown
var egg_pending: Array = []
var _feat_t := 0.0

func _process(d: float) -> void:
	if started and not finished:
		playtime += d
		Clock.advance(self, d)
		# feats, finds and the dresses the journey has earned are looked for now and then (cheap: a
		# few dozen comparisons)
		_feat_t -= d
		if _feat_t <= 0.0:
			_feat_t = 1.5
			poll_wardrobe()
			Feats.poll(self)
			# (needs.gd: the body follows the land's clock; the night wears comfort faster)
			if survival and prologue == "":
				Needs.tick(self, 1.6 if Clock.is_night(Clock.hour(self)) else 1.0)

func reset() -> void:
	started = true
	finished = false
	playtime = 0.0
	level = 0
	exp = 0.0
	stones = 60
	inv = {"hp_pill": 3, "qi_pill": 1}
	step = 0
	area = "sect"
	# a world tile: the sect's courtyard in front of the hall (Vector2i(20, 8) is the sect's own
	# tile, which used to be stored here as if it were a world tile)
	tile = Atlas.to_world("sect", Vector2i(20, 8))
	layer = "surface"
	companion = false
	temper = 0
	boss_done = {}
	taken = {}
	defeated = {}
	kills = 0
	battles = 0
	deaths = 0
	meditated = 0.0
	hunt = 0
	delved = {}
	step_uses = {}
	summits = {}
	climbed = 0.0
	glides = 0
	glided = 0
	glide_best = 0
	glide_drop = 0.0
	step_glide = 0
	timeline = []
	toasts = []
	seen = {"sect": true}
	dao = ""
	dao_xp = {}
	dao_switches = 0
	standing = {}
	met = {}
	talents = {}
	talent_pts = 0
	awakenings = 0
	abodes = {}
	scattered = 0
	renown = 0
	trials = {}
	paid = {}
	deeds = {}
	gates_open = {}
	visited = {}
	pastimes = {}
	prop_uses = {}
	prop_found = {}
	prop_t = {}
	hero = Fashion.default_hero()
	outfits = {"sweeper": true}
	outfit = "sweeper"
	rides = {}
	ride = ""
	riding = false
	fates = {}
	fate_log = {}
	picks = {}
	works = {}
	scales = {}
	echoed = {}
	cross_pending = []
	bestiary = {}
	told = {}
	grudges = {}
	bond = 0
	heart = {}
	talks = {}
	wishes = {}
	shared = {}
	memories = {}
	threads = {}
	future = ""
	clock = Clock.START
	day = 1
	folk_talk = {}
	broken = {}
	smashed = 0
	rallied = {}
	folk_done = {}
	felled = {}
	felled_n = 0
	cleared = {}
	obstacle_hits = {}
	ambushes = 0
	waves = 0
	strikes = 0
	done_pending = []
	hearth = {"valley": Cultures.KIN}
	sat = {}
	prologue = ""
	ending = ""
	arms = {}
	for aid in Arms.FIRST:
		arms[aid] = true
	arm = "sword"
	arm_xp = {}
	arm_switches = 0
	yue_outfits = {"lotus": true}
	yue_outfit = "lotus"
	worn = {"sweeper": true}
	feats = {}
	eggs = {}
	heard = {}
	airs = {}
	songs_played = 0
	host = {}
	war_won = {}
	war_lost = 0
	war_orders = {}
	war_feints = 0
	war_tries = {}
	songs_asked = {}
	survival = false
	needs = {}
	gourd = 0
	needs_clock = 0.0
	needs_fell = {}
	romance = {}
	marks_seen = {}
	reckoned = {}
	passengers = []
	fares = 0
	mail_read = {}
	mail_replies = {}
	mail_bags = []
	bag_day = {}
	bags_done = 0
	mail_told = 0
	shifts = {}
	shift_day = {}
	salary_day = {}
	wages = 0
	falls = {}
	fallen = 0
	yielded = 0
	gamble_n = 0
	gamble_rounds = 0
	gamble_wins = 0
	gamble_won = 0
	gamble_lost = 0
	gamble_best = 0
	gamble_streak = 0
	gamble_triples = 0
	jobs = {}
	job_base = {}
	npc_talks = {}
	felled_kind = {}
	egg_pending = []
	UI.set_hero_name(Fashion.DEFAULT_FAMILY, Fashion.DEFAULT_GIVEN)
	hp = [float(max_hp(0)), 0.0]
	qi = [float(max_qi(0)), 0.0]
	note("Journey begins")

func note(text: String) -> void:
	timeline.append({"t": snappedf(playtime, 0.1), "text": text})

func toast(text: String) -> void:
	toasts.append(text)

# ---------------------------------------------------------------- party
func party_size() -> int:
	return 2 if companion else 1

func member_name(i: int) -> String:
	# (the name the player chose is put on screen by UI.named: the story's data keeps "Lin Feng")
	return "Lin Feng" if i == 0 else "Yue Ling"

func max_hp(i: int) -> int:
	# (his origin and outfit build his body only, not Yue Ling's: Fashion.gear)
	# (and her dress hers: Fashion.yue_gear)
	# (and what being promised, or wed, gives her: romance.gd)
	return int(Data.max_hp(level) * (1.0 if i == 0 else 0.85) * boon("hp", 1.0) * ((1.0 + talent_mod("hp")) * (1.0 + Fashion.gear(self, "hp")) if i == 0 else (1.0 + Fashion.yue_gear(self, "hp")) * Romance.mod(self)) * Works.mod(self, "hp"))

func max_qi(i: int) -> int:
	# (his origin and his outfit may widen or narrow his dantian: Fashion.gear)
	# (a body that is parched or filthy holds less: needs.gd; nothing with survival off)
	return int(Data.max_qi(level) * (1.0 if i == 0 else 1.1) * ((1.0 + talent_mod("qi")) * (1.0 + Fashion.gear(self, "qi")) if i == 0 else 1.0 + Fashion.yue_gear(self, "qi")) * Needs.mod(self, "qi"))

func fighter(i: int) -> Dictionary:
	var a := float(Data.atk(level)) * (1.0 + 0.12 * temper) * boon("atk", 1.0)
	if i == 1:
		a = float(Data.atk(level)) * 0.75 * (1.0 + Fashion.yue_gear(self, "atk"))
	# (needs.gd: the famished and the worn out strike less hard; 1 with survival off)
	a *= Needs.mod(self, "atk")
	# the Wandering Dao and the friendship of the Feathered Folk make Lin Feng quicker
	var spd: int = Data.speed(level) + (2 + int(Fashion.yue_gear(self, "spd")) if i == 1 else 0)
	if i == 0:
		spd += int(dao_mod("spd", 0.0) + boon("spd", 0.0) + talent_mod("spd") + Arms.mod(self, "spd", 0.0))
	spd += int(Needs.mod(self, "spd"))
	return {
		"id": "pc%d" % i, "name": member_name(i), "side": "party", "idx": i, "lv": level, "boss": false,
		"hp": hp[i], "maxhp": float(max_hp(i)), "qi": qi[i], "maxqi": float(max_qi(i)),
		"atk": a, "def": float(Data.defense(level)) * (1.0 if i == 0 else 0.9), "spd": spd,
		"elem": "phys", "weak": "none", "col": Color("7ec8ff") if i == 0 else Color("ff9ac0"),
		"shape": "hero" if i == 0 else "healer", "skills": Data.known_skills(i, level, step) + dao_skills(i) + (Arms.skills(self) if i == 0 else []),
		"turns": 0, "flash": 0.0, "shake": 0.0, "dead": false, "fade": 1.0,
	}

# ---------------------------------------------------------------- daos (Part XI)
## Lin Feng's rank in a Dao (0 Novice, 1 Adept, 2 Master), the one he walks by default.
func dao_tier(id: String = "") -> int:
	if id == "":
		id = dao
	if id == "":
		return 0
	var xp: int = int(dao_xp.get(id, 0))
	var tier := 0
	for k in Data.DAO_TIERS.size():
		if xp >= Data.DAO_TIERS[k]:
			tier = k
	return tier

## A passive of the Dao Lin Feng walks at his rank in it, or `fallback` if it has none.
func dao_mod(key: String, fallback: float) -> float:
	if dao == "" or not Data.DAO_MODS.has(dao):
		return fallback
	var m: Dictionary = Data.DAO_MODS[dao]
	if not m.has(key):
		return fallback
	return float(m[key][dao_tier()])

## Start (or change) the road Lin Feng walks; each Dao keeps its own mastery.
func choose_dao(id: String) -> void:
	if not Data.DAOS.has(id) or id == dao:
		return
	if dao != "":
		dao_switches += 1
	dao = id
	dao_xp[id] = int(dao_xp.get(id, 0))
	toast("You walk the %s" % Data.DAOS[id].n)
	note("Walks the %s" % Data.DAOS[id].n)

## A battle won while walking a Dao deepens it (a boss four times as much); reaching a rank is news.
func dao_battle_won(boss: bool) -> void:
	if dao == "":
		return
	var before := dao_tier()
	dao_xp[dao] = int(dao_xp.get(dao, 0)) + (4 if boss else 1)
	var after := dao_tier()
	if after > before:
		toast("%s of the %s" % [Data.DAO_RANKS[after], Data.DAOS[dao].n])
		note("Became %s of the %s" % [Data.DAO_RANKS[after], Data.DAOS[dao].n])
		if after == 1:
			toast("New technique: %s" % Data.SKILLS[Data.DAOS[dao].skill].n)

## The Dao's own technique, for Lin Feng, once he is an Adept of the Dao he walks.
func dao_skills(i: int) -> Array:
	if i != 0 or dao == "" or dao_tier() < 1:
		return []
	return [Data.DAOS[dao].skill]

## A technique as it stands now.  Most are what Data.SKILLS says; the technique of a weapon's Dao
## (arms.gd) is measured against the strongest technique of the same reach Lin Feng knows, so that a
## weapon picked up at Qi Condensation is still worth carrying at Hollow Vessel.
var _skill_now := {}

func skill_of(id: String) -> Dictionary:
	var s: Dictionary = Data.SKILLS[id]
	if not s.has("arm"):
		return s
	var key := "%s|%d|%d" % [id, level, step]
	if _skill_now.has(key):
		return _skill_now[key]
	var bm := 1.3 if str(s.tgt) == "one" else 1.0
	var bc := 6.0
	for sid in Data.known_skills(0, level, step):
		var o: Dictionary = Data.SKILLS[sid]
		if str(o.tgt) == str(s.tgt) and not o.has("heal") and float(o.mult) > bm:
			bm = float(o.mult)
			bc = float(o.cost)
	var out := s.duplicate()
	out["mult"] = bm * float(s.k)
	out["cost"] = int(ceil(bc * float(s.ck)))
	if _skill_now.size() > 64:
		_skill_now.clear()
	_skill_now[key] = out
	return out

## What a technique costs to use (the Cauldron's Dao makes them cheaper).
func skill_cost(id: String) -> float:
	var c := float(skill_of(id).cost) * dao_mod("qi", 1.0) * Arms.mod(self, "qi", 1.0) * (1.0 - talent_mod("cost")) * (1.0 - Fashion.gear(self, "cost")) * Works.mod(self, "cost")
	# the crown of the Five-Phase Root: techniques that strike every foe cost a fifth less
	if talent_crown("five_phase") and str(Data.SKILLS[id].tgt) == "all":
		c *= 0.8
	return c

# ---------------------------------------------------------------- the Nine Heavens root (Part XII)
func talent(id: String) -> int:
	return int(talents.get(id, 0))

func talent_crown(id: String) -> bool:
	return talent(id) >= Data.TALENT_MAX

## What the woken branches add up to for one effect key (see Data.TALENTS fx): the sum over every
## branch of its per-rank amount times its rank.
func talent_mod(key: String) -> float:
	var v := 0.0
	for id in talents:
		var fx: Dictionary = Data.TALENTS[id].fx
		if fx.has(key):
			v += float(fx[key]) * int(talents[id])
	return v

## How much harder a technique of Lin Feng's lands for the branches he has woken: its element's root,
## and the Sword Bone for the plain strike, physical techniques and single-target techniques.
func talent_power(skill_id: String) -> float:
	var s: Dictionary = Data.SKILLS[skill_id]
	var m := 1.0 + talent_mod(str(s.elem))
	if skill_id == "strike":
		m += talent_mod("strike") - (talent_mod("phys") if str(s.elem) == "phys" else 0.0)
	if str(s.get("tgt", "")) == "one":
		m += talent_mod("one")
	return m

## A branch wakes (the first stirring of qi, a tribulation, a Founder's cave): one more rank to spend.
func awaken(why: String) -> void:
	talent_pts += 1
	awakenings += 1
	toast("A branch of the Nine Heavens root stirs")
	note("The root stirred: " + why)

## Spend an awakening on branch `id`.  Returns whether it took.
func wake_talent(id: String) -> bool:
	if talent_pts <= 0 or not Data.TALENTS.has(id) or talent(id) >= Data.TALENT_MAX:
		return false
	talent_pts -= 1
	talents[id] = talent(id) + 1
	var rank := talent(id)
	toast("%s: %s" % [Data.TALENTS[id].n, Data.TALENT_RANKS[rank]])
	note("Woke the %s (%s)" % [Data.TALENTS[id].n, Data.TALENT_RANKS[rank]])
	# the branches that grow the body and the dantian fill what they grow
	hp[0] = minf(float(max_hp(0)), hp[0] + Data.max_hp(level) * float(Data.TALENTS[id].fx.get("hp", 0.0)))
	qi[0] = minf(float(max_qi(0)), qi[0] + Data.max_qi(level) * float(Data.TALENTS[id].fx.get("qi", 0.0)))
	return true

## Total ranks woken.
func talent_ranks() -> int:
	var n := 0
	for id in talents:
		n += int(talents[id])
	return n

# ---------------------------------------------------------------- realms (Part XII)
func realm() -> int:
	return Data.realm_of(level)

## How the world addresses Lin Feng at his realm.
func address() -> String:
	return str(Data.REALM_INFO[mini(realm(), Data.REALM_INFO.size() - 1)].title)

## A pack this far below Lin Feng scatters before his aura rather than fight (Main.interact).
func scatters(group: Array) -> bool:
	# (dooms.gd: what cannot be beaten does not run from anybody's realm)
	if Dooms.in_group(group):
		return false
	var top := 0
	for g in group:
		top = maxi(top, int(g.lv))
	return realm() - Data.realm_of(top) >= Data.AURA_FLEE

# ---------------------------------------------------------------- the peoples of the realms (Part XI)
func race_tier(race: String) -> int:
	var st: int = int(standing.get(race, 0))
	return 2 if st >= Data.KIN else (1 if st >= Data.FRIEND else 0)

func race_title(race: String) -> String:
	return ["Stranger", "Friend", "Kin"][race_tier(race)]

## A people's name to start a sentence with: "The Shades of Youdu", "The Thousand Children of Landfall"
## (whose names already begin with "The": the toast used to read "The The Thousand Children...").
static func the_race(race: String) -> String:
	var n: String = str(Data.RACES[race].n)
	return n if n.begins_with("The ") else "The " + n

## Standing grows with help given; walking the Dao a people honours makes it grow half as fast again.
func race_gain(race: String, n: int) -> void:
	if not Data.RACES.has(race) or race == "human":
		return
	met[race] = true
	var before := race_tier(race)
	if dao != "" and Data.RACES[race].dao == dao:
		n = int(ceil(n * 1.5))
	# (echoes.gd: the peoples warm faster to somebody known to belong to the wide world)
	n = int(ceil(n * Echoes.lean_mod(self, "regard")))
	standing[race] = mini(int(standing.get(race, 0)) + n, Data.KIN)
	var after := race_tier(race)
	if after > before:
		toast("%s call you %s" % [the_race(race), race_title(race)])
		note("%s call Lin Feng %s" % [the_race(race), race_title(race)])
		if after == 1 and str(Data.RACES[race].boon_n) != "":
			toast("Boon: %s" % Data.RACES[race].boon_n)

## Give a people the keepsake they love (one from the inventory): standing grows. Returns whether
## anything was given.
func give_gift(race: String) -> bool:
	var item: String = str(Data.RACES.get(race, {}).get("gift", ""))
	if item == "" or inv.get(item, 0) <= 0:
		return false
	inv[item] -= 1
	race_gain(race, 12)
	add_renown(Trials.RENOWN_GIFT)
	return true

## The boons of the peoples who call Lin Feng friend: spd (speed), atk, miss, heal, hp and taken
## multipliers or additions; `fallback` when no friendly people grants it.
func boon(key: String, fallback: float) -> float:
	var v := fallback
	for race in standing:
		if race_tier(race) < 1 or str(Data.RACES[race].boon) != key:
			continue
		match key:
			"spd":
				v += 3.0
			"atk":
				v *= 1.06
			"miss":
				v += 0.05
			"heal":
				v *= 1.1
			"hp":
				v *= 1.08
			"taken":
				v *= 0.94
			# Part XII: the Thousand Children's thrift and the immortals' teaching
			"stones":
				v *= 1.1
			"exp":
				v *= 1.06
	# who he was before the sect (his origin) and what he wears (Fates and Faces): small strengths and
	# small weaknesses through the same channels
	var gv := Fashion.gear(self, key) if key != "hp" else 0.0
	if gv != 0.0:
		if key == "spd" or key == "miss":
			v += gv
		else:
			v *= 1.0 + gv
	return v

func heal_full() -> void:
	for i in party_size():
		hp[i] = float(max_hp(i))
		qi[i] = float(max_qi(i))

# ---------------------------------------------------------------- cultivation
func exp_need() -> int:
	return Data.EXP_NEED[mini(level, Data.EXP_NEED.size() - 1)]

func at_cap() -> bool:
	return Data.realm_cap(level) or level >= Data.MAX_LEVEL

func can_breakthrough() -> bool:
	return Data.realm_cap(level) and exp >= exp_need() - 0.001

func add_exp(x: float) -> bool:
	## returns true if a stage was gained
	var gained := false
	if level >= Data.MAX_LEVEL:
		return false
	exp += x
	while exp >= exp_need() and not Data.realm_cap(level):
		exp -= exp_need()
		level += 1
		gained = true
		heal_full()
		toast("Cultivation advanced: %s" % Data.level_name(level))
		note("Reached %s" % Data.level_name(level))
		level_changed.emit()
	if Data.realm_cap(level) and exp > exp_need():
		exp = float(exp_need())
	if gained:
		poll_steps()
	return gained

func record_kills(a: String, n: int, ids: Array = []) -> void:
	# (what falls is counted by kind: jobs.gd)
	for kid in ids:
		felled_kind[str(kid)] = int(felled_kind.get(str(kid), 0)) + 1
	var s := cur_step()
	# (a hunt in a cave, Part XX, counts what is brought down in that cave)
	if not s.is_empty() and s.kind == "hunt" and s.area == a and (not s.has("cave") or layer == Caves.fid(a, int(s.cave))):
		# a hunt for particular foes (Part XIII: Chiyou's war-band) counts only those
		# (the Hundred Arms release: a hunt that asks for a weapon counts what falls while it is in the hand)
		if s.has("arm") and str(s.arm) != Arms.held(self):
			n = 0
		elif s.has("of") and not ids.is_empty():
			n = ids.filter(func(id): return str(id) in s.of).size()
		elif s.has("of"):
			n = 0
		hunt += n
		poll_steps()

func do_breakthrough() -> void:
	level += 1
	exp = 0.0
	heal_full()
	toast("Breakthrough! %s" % Data.level_name(level))
	note("Breakthrough to %s" % Data.level_name(level))
	level_changed.emit()
	poll_steps()

func med_rate(near_spring: bool) -> float:
	# an Enlightened Mind goes deeper into every meditation
	return (3.0 + 1.2 * level) * (3.0 if near_spring else 1.0) * (1.0 + talent_mod("med")) * Works.mod(self, "med")

# ---------------------------------------------------------------- quests
func cur_step() -> Dictionary:
	if step >= Data.STEPS.size():
		return {}
	return Data.STEPS[step]

func reached(id: String) -> bool:
	return id == "" or step >= Data.step_index(id)

func done(id: String) -> bool:
	return id == "" or step > Data.step_index(id)

func advance() -> void:
	var s := cur_step()
	if s.is_empty():
		return
	stones += int(s.get("stones", 0))
	if s.get("stones", 0) > 0:
		toast("+%d spirit stones" % s.stones)
	toast("Quest complete: %s" % s.t)
	note("Quest complete: %s" % s.t)
	if Data.DIALOGUE.has("done:" + str(s.id)):
		done_pending.append(str(s.id))
	# a crossroads of the road waits behind this step (echoes.gd): asked once Lin Feng is free to answer
	for cid in Echoes.ORDER:
		if str(Echoes.CROSSROADS[cid].step) == str(s.id) and not picks.has(cid) and not cross_pending.has(cid):
			cross_pending.append(cid)
	# the story sets the hour here and there (clock.gd)
	Clock.story_hour(self, str(s.id))
	# help given in the land of one of the peoples of the realms (Part XI) earns their standing
	for race in Data.AREAS.get(str(s.get("area", "")), {}).get("races", []):
		race_gain(race, 8 if s.kind == "kill" else 5)
	# and what is done among a hearth of the land for its own people (cultures.gd): a step that names
	# its hearth is a deed for it; a word, an errand or a scene in its country is a small one
	if s.has("hearth"):
		# (echoes.gd: a keeper of the old ways is thanked a little more at every hearth)
		add_hearth(str(s.hearth), Cultures.DEED + int(Echoes.lean_mod(self, "hearth")))
	elif str(s.kind) in ["talk", "folk", "share", "visits", "rally"]:
		add_hearth(Cultures.of_area(str(s.get("area", ""))), 1)
	# an outfit or a ride the story gives here (the Elder's robe, the flying sword, an immortal's cloud)
	for rw in Fashion.step_rewards(str(s.id)):
		if rw[0] == "outfit":
			grant_outfit(str(rw[1]))
		else:
			grant_ride(str(rw[1]))
	# and a weapon (arms.gd): Iron Fang's sabre, the Empress's fan
	for aid in Arms.step_rewards(str(s.id)):
		grant_arm(str(aid))
	step += 1
	hunt = 0
	step_uses = {}
	step_glide = 0
	# a step that asks for visits starts with nobody visited: somebody called on in an earlier chapter
	# (Smith Tie at the New Year, Auntie Rong with the new fire) is called on again
	var ns := cur_step()
	if not ns.is_empty() and str(ns.kind) == "visits":
		for vn in ns.get("npcs", []):
			visited.erase(vn)
	if step >= Data.STEPS.size():
		finished = true
		note("Ascended")
	quest_changed.emit()
	poll_steps()

func poll_steps() -> void:
	var guard := 0
	while guard < 8:
		guard += 1
		var s := cur_step()
		if s.is_empty():
			return
		var ok := false
		match s.kind:
			"level":
				ok = level >= s.lv
			"collect":
				ok = inv.get(s.item, 0) >= s.n
			"hunt":
				ok = hunt >= s.n
			"breakthrough":
				ok = level >= s.to and not finished
			"gates":
				# Part XIII: any of the Eight Gates, in any order
				ok = gates_open.size() >= int(s.n)
			"visits", "fates":
				# any of the people named, in any order (Part XIII's invitations, Part XIV's five threads)
				ok = visits_done(s) >= int(s.n)
			"grudges":
				# Part XIV: the grudges that stayed, in any order, each fought and then answered
				ok = grudges.size() >= int(s.n)
			"memories":
				# Part XV: Yue Ling's memories, any of them, in any order (bonds.gd)
				ok = memories.size() >= int(s.n)
			"threads":
				# Part XV: the people who tied a thread for her, any of them, in any order
				ok = visits_done(s) >= int(s.n)
			"rally":
				# Part XVI: the towns reminded of the old ways, any of them, in any order
				ok = visits_done(s) >= int(s.n)
			"folk":
				# Part XVI: so many of the people of the towns (folk.gd) of one kind, any of them
				ok = folk_count(s) >= int(s.n)
			"clear":
				# Part XVII: so many of the obstacles of one kind in a region cleared with the sword
				ok = cleared_count(s) >= int(s.n)
			"works":
				# Part XIX: so many works built with his own hands, any of them (works.gd)
				ok = Works.count(self) >= int(s.n)
			"delve":
				# Part XX: so many caves gone to the very back of, any of them (caves.gd)
				ok = delved.size() >= int(s.n)
			"try":
				# Part XX: so many of the things of a cave done (props.gd), any of them or those named
				ok = tried_count(s) >= int(s.n)
			"arms":
				# Part XXI: so many Daos of arms learned to Adept (arms.gd)
				ok = Arms.adept(self) >= int(s.n)
			"summit":
				# Part XXII: the very top of a region's highest peak (`peak`), or so many summits, any of
				# them (peaks.gd)
				ok = summits.has("peak:%s:%d" % [str(s.peak), int(s.get("k", 0))]) if s.has("peak") else summits.size() >= int(s.n)
			"glide":
				# Part XXII: one flight under the cloud-kite of so many tiles, made since the step began
				ok = step_glide >= int(s.n)
			"jobs":
				# Part XXIII: so many commissions of the notice board done, any of them (jobs.gd)
				ok = Jobs.done_count(self) >= int(s.n)
			"airs":
				# Part XXIII: so many airs of the hearths learned (music.gd)
				ok = airs.size() >= int(s.n)
			"host":
				# Part XXIII: so many companies in the host (war.gd)
				ok = War.companies(self).size() >= int(s.n)
			"reckon":
				# the reckoning (reckon.gd): everybody the journey's choices made has been met
				ok = Reckon.left(self).is_empty()
			"falls":
				# Part XXIV: so many packs of what cannot be beaten stood in front of, and lost to (dooms.gd)
				ok = hunt >= int(s.n)
			"marks":
				# Part XXIV: so many of the things his choices left standing gone and looked at (marks.gd)
				ok = marks_seen.size() >= int(s.n)
		if not ok:
			return
		if s.kind == "breakthrough":
			return # handled explicitly by main after the cutscene
		advance()

## Part XX: how many of the things a "try" step asks for have been done since it began (any of the
## things of a cave, or the kinds it names).
func tried_count(s: Dictionary) -> int:
	var n := 0
	for k in step_uses:
		if (s.has("things") and str(k) in s.things) or (not s.has("things") and CaveThings.KINDS.has(str(k))):
			n += 1
	return n

## The High Roads: Lin Feng has stood on the very top of a peak: it is remembered, and it is news the
## first time.
func summit(pid: String, peak_name: String, height: float) -> void:
	if summits.has(pid):
		return
	summits[pid] = true
	note("Stood on %s (%d m)" % [peak_name, int(round(height))])
	toast("The summit of %s, %d metres up (%d summits)" % [peak_name, int(round(height)), summits.size()])
	poll_steps()

## A flight under the kite has ended: `tiles` flown, `fell` metres come down.
func glide_done(tiles: int, fell: float) -> void:
	if tiles > glide_best:
		glide_best = tiles
	glide_drop = maxf(glide_drop, fell)
	step_glide = maxi(step_glide, tiles)
	if tiles >= 12:
		note("Flew %d metres under the cloud-kite" % (tiles * 2))
	poll_steps()

## Part XX: Lin Feng has been to the very back of a cave (he found what was left there): it is
## remembered, and it is news the first time.
func delve(fid: String, cave_name: String) -> void:
	if delved.has(fid):
		return
	delved[fid] = true
	note("Went to the very back of %s" % cave_name)
	toast("To the back of %s (%d caves)" % [cave_name, delved.size()])
	add_renown(1)
	poll_steps()

func objective_text() -> String:
	# the beginning (cultures.gd): the farewell at the hero's own hearth
	if prologue != "" and Cultures.HEARTHS.has(prologue):
		var hh: Dictionary = Cultures.HEARTHS[prologue]
		return "Three years ago, at %s: say goodbye to %s" % [str(hh.n), Trials.npc_name(str(hh.keeper))]
	var s := cur_step()
	if s.is_empty():
		return "The journey is complete."
	var t: String = s.t
	if s.kind == "collect":
		t += "  (%d/%d)" % [mini(inv.get(s.item, 0), s.n), s.n]
	elif s.kind == "hunt" or s.kind == "falls":
		t += "  (%d/%d)" % [mini(hunt, s.n), s.n]
	elif s.kind == "marks":
		t += "  (%d/%d)" % [mini(marks_seen.size(), int(s.n)), int(s.n)]
	elif s.kind == "gates":
		t += "  (%d/%d)" % [mini(gates_open.size(), int(s.n)), int(s.n)]
	elif s.kind == "visits" or s.kind == "fates":
		t += "  (%d/%d)" % [mini(visits_done(s), int(s.n)), int(s.n)]
	elif s.kind == "grudges":
		t += "  (%d/%d)" % [mini(grudges.size(), int(s.n)), int(s.n)]
	elif s.kind == "memories":
		t += "  (%d/%d)" % [mini(memories.size(), int(s.n)), int(s.n)]
	elif s.kind == "threads" or s.kind == "rally":
		t += "  (%d/%d)" % [mini(visits_done(s), int(s.n)), int(s.n)]
	elif s.kind == "folk":
		t += "  (%d/%d)" % [mini(folk_count(s), int(s.n)), int(s.n)]
	elif s.kind == "summit" and not s.has("peak"):
		t += "  (%d/%d)" % [mini(summits.size(), int(s.n)), int(s.n)]
	elif s.kind == "glide":
		t += "  (%d/%d m)" % [mini(step_glide, int(s.n)) * 2, int(s.n) * 2]
	elif s.kind == "clear":
		t += "  (%d/%d)" % [mini(cleared_count(s), int(s.n)), int(s.n)]
	elif s.kind == "works":
		t += "  (%d/%d)" % [mini(Works.count(self), int(s.n)), int(s.n)]
	elif s.kind == "delve":
		t += "  (%d/%d)" % [mini(delved.size(), int(s.n)), int(s.n)]
	elif s.kind == "try":
		t += "  (%d/%d)" % [mini(tried_count(s), int(s.n)), int(s.n)]
	elif s.kind == "arms":
		t += "  (%d/%d)" % [mini(Arms.adept(self), int(s.n)), int(s.n)]
	elif s.kind == "fate":
		t += "  - a fated encounter: Esc > Fates"
	if Trials.trial_of_step(s) != "" or s.kind == "gates":
		# a trial: more than one way to prepare for it (Esc > Journal)
		t += "  - a trial: Esc > Journal"
	return t

# ---------------------------------------------------------------- many roads (see trials.gd)
func renown_title() -> String:
	return Trials.renown_title(renown)

## The world thinks a little better of Lin Feng; a new title is news.
func add_renown(n: int) -> void:
	if n <= 0:
		return
	var before := Trials.renown_title(renown)
	renown += n
	var after := Trials.renown_title(renown)
	if after != before:
		toast("Renown: the world calls you %s" % after)
		note("Renown %d: %s" % [renown, after])

## Take path `pid` through the trial in front of boss `tid`: what it costs is paid now (once), and the
## path is returned for the battle.  An empty dictionary if it cannot be taken.
func take_path(tid: String, pid: String) -> Dictionary:
	var p := Trials.path(tid, pid)
	if p.is_empty() or not Trials.path_met(tid, p, self):
		return {}
	Trials.pay(tid, p, self)
	note("Faced %s %s: %s" % [Data.ENEMIES[tid].n, str(Trials.KINDS[p.kind].n).to_lower(), str(p.n)])
	return p

## A trial passed: remembered with the path that passed it, and the world hears of it.
func trial_won(tid: String, pid: String) -> void:
	trials[tid] = pid
	# (echoes.gd: a name that goes out from one valley comes back larger)
	add_renown(Trials.RENOWN_TRIAL + int(Echoes.lean_mod(self, "renown")))

## Make something at a cauldron or a forge.
func craft(id: String) -> bool:
	if not Trials.craft(id, self):
		return false
	toast("Crafted %s" % Data.ITEMS[id].n)
	note("Crafted " + str(Data.ITEMS[id].n))
	return true

## Do what a townsperson asked: they take what they wanted, pay what they can, and Lin Feng's name
## goes round.
func do_deed(id: String) -> bool:
	if deeds.has(id) or not Trials.deed_ready(id, self):
		return false
	var d: Dictionary = Trials.DEEDS[id]
	for k in d.want:
		inv[k] = int(inv.get(k, 0)) - int(d.want[k])
	deeds[id] = true
	stones += int(d.get("stones", 0))
	toast("Deed done: +%d renown, +%d spirit stones" % [int(d.renown), int(d.get("stones", 0))])
	note("A deed for %s" % Trials.npc_name(str(d.npc)))
	add_renown(int(d.renown) + int(Echoes.lean_mod(self, "renown")))
	return true

## How many of the people a "visits" step names Lin Feng has been to (for a "threads" step, Part XV:
## how many of them have tied a thread for Yue Ling).
func visits_done(s: Dictionary) -> int:
	var k := 0
	var seen_: Dictionary = threads if str(s.get("kind", "")) == "threads" else (rallied if str(s.get("kind", "")) == "rally" else visited)
	for id in s.get("npcs", []):
		if seen_.has(id):
			k += 1
	return k

## Part XVI: the townsfolk Lin Feng has done what step `s` asked with, and whether `id` is one.
func folk_count(s: Dictionary) -> int:
	return (folk_done.get(str(s.get("id", "")), {}) as Dictionary).size()

func folk_has(s: Dictionary, id: String) -> bool:
	return (folk_done.get(str(s.get("id", "")), {}) as Dictionary).has(id)

func folk_mark(s: Dictionary, id: String) -> void:
	var k := str(s.get("id", ""))
	if not folk_done.has(k):
		folk_done[k] = {}
	folk_done[k][id] = true

## Part XVII (impact.gd): how many obstacles of the kind a "clear" step names (`what`) are cleared in its
## region.
func cleared_count(s: Dictionary) -> int:
	var want := "%s|%s" % [str(s.get("what", "")), str(s.get("area", ""))]
	var n := 0
	for id in cleared:
		if str(cleared[id]) == want:
			n += 1
	return n

## Total essences of all kinds in hand.
func essences() -> int:
	var n := 0
	for k in Trials.ESSENCE_ORDER:
		n += int(inv.get(k, 0))
	return n

# ---------------------------------------------------------------- who he is, what he wears and rides (fashion.gd)
func hero_name() -> String:
	return Fashion.full_name(hero)

## Set who the player made him at creation: name, look, colours and origin; the origin's keepsakes are
## given now, and so is the outfit a hunter's orphan grew up in.
func create_hero(h: Dictionary) -> void:
	hero = Fashion.default_hero()
	for k in h:
		hero[k] = h[k]
	UI.set_hero_name(str(hero.family), str(hero.given), Fashion.fem(hero))
	# the hearth of the year away (cultures.gd): kin there from the first day, and its keepsakes
	var hid := Cultures.own(self)
	hearth = {hid: Cultures.KIN}
	var hh: Dictionary = Cultures.HEARTHS[hid]
	for k0 in hh.give:
		if k0 == "stones":
			stones += int(hh.give[k0])
		else:
			add_item(k0, int(hh.give[k0]))
	var o := Fashion.origin_of(self)
	for k2 in o.give:
		if k2 == "stones":
			stones += int(o.give[k2])
		else:
			add_item(k2, int(o.give[k2]))
	for oid in Fashion.OUTFITS:
		if str(Fashion.OUTFITS[oid].get("origin", "")) == str(hero.origin):
			outfits[oid] = true
	# the dantian and body the origin gives start full
	hp[0] = float(max_hp(0))
	qi[0] = float(max_qi(0))
	note("%s, %s, kin %s, sets out" % [hero_name(), Voice.her(str(o.short)) if Fashion.fem(hero) else str(o.short), str(hh.short)])

## Whether the hero is a woman (character creation), and one word or the other by it.
func fem() -> bool:
	return Fashion.fem(hero)

func gw(m: String, f: String) -> String:
	return f if fem() else m

## Standing earned with a hearth of the land (cultures.gd): told when it makes the hero a guest or kin.
func add_hearth(id: String, n: int) -> void:
	var t := Cultures.earn(self, id, n)
	if t > 0:
		toast(Cultures.welcome(id, t))
		note("%s of %s" % [Cultures.tier_name(t), str(Cultures.HEARTHS[id].n)])

## The first time the hero sits down with one of a hearth's named people (talk_npc).
func sit_with(npc: String) -> void:
	var id := Cultures.of_npc(npc)
	if id == "" or sat.has(npc) or prologue != "":
		return
	sat[npc] = true
	add_hearth(id, Cultures.SIT)

func grant_outfit(id: String) -> void:
	if outfits.has(id) or not Fashion.OUTFITS.has(id):
		return
	outfits[id] = true
	toast("New outfit: %s (Esc > Wardrobe)" % Fashion.OUTFITS[id].n)
	note("Received the " + str(Fashion.OUTFITS[id].n))

## Put on an outfit he owns: the passives change at once, and the health and qi it widens are filled.
func wear(id: String) -> bool:
	if not outfits.has(id) or id == outfit:
		return false
	var hp_r: float = hp[0] / float(max_hp(0))
	var qi_r: float = qi[0] / float(max_qi(0))
	outfit = id
	worn[id] = true
	hp[0] = minf(float(max_hp(0)), float(max_hp(0)) * hp_r)
	qi[0] = minf(float(max_qi(0)), float(max_qi(0)) * qi_r)
	note("Dressed in the " + str(Fashion.OUTFITS[id].n))
	return true

## The Thundering Pots release: a dress for Yue Ling (fashion.gd YUE_OUTFITS).
func grant_yue_outfit(id: String) -> void:
	if yue_outfits.has(id) or not Fashion.YUE_OUTFITS.has(id):
		return
	yue_outfits[id] = true
	toast("A new dress for Yue Ling: %s (Esc > Wardrobe)" % Fashion.YUE_OUTFITS[id].n)
	note("Yue Ling was given the " + str(Fashion.YUE_OUTFITS[id].n))

func wear_yue(id: String) -> bool:
	if not yue_outfits.has(id) or id == yue_outfit:
		return false
	var hp_r: float = hp[1] / maxf(1.0, float(max_hp(1)))
	var qi_r: float = qi[1] / maxf(1.0, float(max_qi(1)))
	yue_outfit = id
	hp[1] = float(max_hp(1)) * hp_r
	qi[1] = float(max_qi(1)) * qi_r
	note("Yue Ling wears the " + str(Fashion.YUE_OUTFITS[id].n))
	return true

## The dresses of hers the journey has earned (how close the two are, the steps of the story done).
func poll_wardrobe() -> void:
	if not companion:
		return
	for id in Fashion.yue_earned(self):
		grant_yue_outfit(str(id))

## What a feat, a commission or a find gives to wear (fashion.gd `feat`, `job`, `egg`).
func grant_earned(kind: String, id: String) -> void:
	for rw in Fashion.earned_by(kind, id):
		if str(rw[0]) == "outfit":
			grant_outfit(str(rw[1]))
		else:
			grant_yue_outfit(str(rw[1]))

# ---------------------------------------------------------------- the Eight Arms (arms.gd)
func grant_arm(id: String) -> void:
	if arms.has(id) or not Arms.WEAPONS.has(id):
		return
	arms[id] = true
	toast("New weapon: %s (Esc > Arms)" % Arms.WEAPONS[id].n)
	note("Took up " + str(Arms.WEAPONS[id].n).trim_prefix("The ").insert(0, "the ") if str(Arms.WEAPONS[id].n).begins_with("The ") else "Took up " + str(Arms.WEAPONS[id].n))

## Take a weapon he owns into his hand: its own blow, its own Dao and that Dao's passives, at once.
func wield(id: String) -> bool:
	if not arms.has(id) or id == arm or not Arms.WEAPONS.has(id):
		return false
	arm = id
	arm_switches += 1
	arm_xp[id] = int(arm_xp.get(id, 0))
	note("Took %s in hand" % str(Arms.WEAPONS[id].zh))
	quest_changed.emit()
	return true

## A battle won with a weapon in the hand deepens that weapon's Dao (a lord four times as much).
func arm_battle_won(boss: bool) -> void:
	var id := Arms.held(self)
	var before := Arms.tier(self, id)
	arm_xp[id] = int(arm_xp.get(id, 0)) + (4 if boss else 1)
	var after := Arms.tier(self, id)
	if after > before:
		var w: Dictionary = Arms.WEAPONS[id]
		toast("%s of the %s" % [Data.DAO_RANKS[after], w.dao.n])
		note("Became %s of the %s" % [Data.DAO_RANKS[after], w.dao.n])
		add_renown(1)
		if after == 1:
			toast("New technique: %s" % Data.SKILLS[str(w.skill)].n)
		poll_steps()

func grant_ride(id: String) -> void:
	if rides.has(id) or not Fashion.RIDES.has(id):
		return
	rides[id] = true
	toast("New ride: %s (Esc > Stable, R to ride)" % Fashion.RIDES[id].n)
	note("Gained a ride: " + str(Fashion.RIDES[id].n))
	# the first ride is saddled at once; a faster one replaces a slower one he was using
	if ride == "" or float(Fashion.RIDES[id].speed) > float(Fashion.RIDES[ride].speed):
		ride = id

## A small choice of the road (fate.gd PICKS) made: remembered for the rest of the game.
func pick(id: String, option: String) -> void:
	picks[id] = option
	note("Chose: %s" % option)

# ---------------------------------------------------------------- items
func add_item(id: String, n: int = 1) -> void:
	inv[id] = inv.get(id, 0) + n

func lowest_member() -> int:
	var best := 0
	var br := 2.0
	for i in party_size():
		var r: float = hp[i] / float(max_hp(i))
		if r < br:
			br = r
			best = i
	return best

func use_item_field(id: String) -> String:
	if inv.get(id, 0) <= 0:
		return "You have none."
	var i := lowest_member()
	if id == "hp_pill":
		if hp[i] >= max_hp(i) - 0.5:
			return "Everyone is already at full health."
		inv[id] -= 1
		hp[i] = minf(float(max_hp(i)), hp[i] + max_hp(i) * 0.4 * dao_mod("pill", 1.0) * Works.mod(self, "pill"))
		return "%s recovers health." % member_name(i)
	if id == "qi_pill":
		inv[id] -= 1
		var j := 0
		var lowest := 2.0
		for k in party_size():
			var r: float = qi[k] / float(max_qi(k))
			if r < lowest:
				lowest = r
				j = k
		if qi[j] >= max_qi(j) - 0.5:
			inv[id] += 1
			return "Everyone's qi is already full."
		qi[j] = minf(float(max_qi(j)), qi[j] + max_qi(j) * 0.5 * dao_mod("pill", 1.0) * Works.mod(self, "pill"))
		return "%s recovers qi." % member_name(j)
	return ""

func respawn() -> void:
	deaths += 1
	stones = int(stones * 0.85)
	area = "sect"
	# a world tile: the sect's courtyard in front of the hall (Vector2i(20, 8) is the sect's own
	# tile, which used to be stored here as if it were a world tile)
	tile = Atlas.to_world("sect", Vector2i(20, 8))
	layer = "surface"
	heal_full()
	note("Defeated and carried back to the sect")
