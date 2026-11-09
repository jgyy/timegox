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

func _process(d: float) -> void:
	if started and not finished:
		playtime += d
		Clock.advance(self, d)

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
	return int(Data.max_hp(level) * (1.0 if i == 0 else 0.85) * boon("hp", 1.0) * ((1.0 + talent_mod("hp")) * (1.0 + Fashion.gear(self, "hp")) if i == 0 else 1.0))

func max_qi(i: int) -> int:
	# (his origin and his outfit may widen or narrow his dantian: Fashion.gear)
	return int(Data.max_qi(level) * (1.0 if i == 0 else 1.1) * ((1.0 + talent_mod("qi")) * (1.0 + Fashion.gear(self, "qi")) if i == 0 else 1.0))

func fighter(i: int) -> Dictionary:
	var a := float(Data.atk(level)) * (1.0 + 0.12 * temper) * boon("atk", 1.0)
	if i == 1:
		a = float(Data.atk(level)) * 0.75
	# the Wandering Dao and the friendship of the Feathered Folk make Lin Feng quicker
	var spd: int = Data.speed(level) + (2 if i == 1 else 0)
	if i == 0:
		spd += int(dao_mod("spd", 0.0) + boon("spd", 0.0) + talent_mod("spd"))
	return {
		"id": "pc%d" % i, "name": member_name(i), "side": "party", "idx": i, "lv": level, "boss": false,
		"hp": hp[i], "maxhp": float(max_hp(i)), "qi": qi[i], "maxqi": float(max_qi(i)),
		"atk": a, "def": float(Data.defense(level)) * (1.0 if i == 0 else 0.9), "spd": spd,
		"elem": "phys", "weak": "none", "col": Color("7ec8ff") if i == 0 else Color("ff9ac0"),
		"shape": "hero" if i == 0 else "healer", "skills": Data.known_skills(i, level, step) + dao_skills(i),
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

## What a technique costs to use (the Cauldron's Dao makes them cheaper).
func skill_cost(id: String) -> float:
	var c := float(Data.SKILLS[id].cost) * dao_mod("qi", 1.0) * (1.0 - talent_mod("cost")) * (1.0 - Fashion.gear(self, "cost"))
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
	var s := cur_step()
	if not s.is_empty() and s.kind == "hunt" and s.area == a:
		# a hunt for particular foes (Part XIII: Chiyou's war-band) counts only those
		if s.has("of") and not ids.is_empty():
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
	return (3.0 + 1.2 * level) * (3.0 if near_spring else 1.0) * (1.0 + talent_mod("med"))

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
	# the story sets the hour here and there (clock.gd)
	Clock.story_hour(self, str(s.id))
	# help given in the land of one of the peoples of the realms (Part XI) earns their standing
	for race in Data.AREAS.get(str(s.get("area", "")), {}).get("races", []):
		race_gain(race, 8 if s.kind == "kill" else 5)
	# an outfit or a ride the story gives here (the Elder's robe, the flying sword, an immortal's cloud)
	for rw in Fashion.step_rewards(str(s.id)):
		if rw[0] == "outfit":
			grant_outfit(str(rw[1]))
		else:
			grant_ride(str(rw[1]))
	step += 1
	hunt = 0
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
		if not ok:
			return
		if s.kind == "breakthrough":
			return # handled explicitly by main after the cutscene
		advance()

func objective_text() -> String:
	var s := cur_step()
	if s.is_empty():
		return "The journey is complete."
	var t: String = s.t
	if s.kind == "collect":
		t += "  (%d/%d)" % [mini(inv.get(s.item, 0), s.n), s.n]
	elif s.kind == "hunt":
		t += "  (%d/%d)" % [mini(hunt, s.n), s.n]
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
	add_renown(Trials.RENOWN_TRIAL)

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
	add_renown(int(d.renown))
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
	UI.set_hero_name(str(hero.family), str(hero.given))
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
	note("%s, %s, sets out" % [hero_name(), str(o.short)])

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
	hp[0] = minf(float(max_hp(0)), float(max_hp(0)) * hp_r)
	qi[0] = minf(float(max_qi(0)), float(max_qi(0)) * qi_r)
	note("Dressed in the " + str(Fashion.OUTFITS[id].n))
	return true

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
		hp[i] = minf(float(max_hp(i)), hp[i] + max_hp(i) * 0.4 * dao_mod("pill", 1.0))
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
		qi[j] = minf(float(max_qi(j)), qi[j] + max_qi(j) * 0.5 * dao_mod("pill", 1.0))
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
