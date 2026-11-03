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
var tile := Vector2i(20, 8)
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

func _process(d: float) -> void:
	if started and not finished:
		playtime += d

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
	tile = Vector2i(20, 8)
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
	return "Lin Feng" if i == 0 else "Yue Ling"

func max_hp(i: int) -> int:
	return int(Data.max_hp(level) * (1.0 if i == 0 else 0.85))

func max_qi(i: int) -> int:
	return int(Data.max_qi(level) * (1.0 if i == 0 else 1.1))

func fighter(i: int) -> Dictionary:
	var a := float(Data.atk(level)) * (1.0 + 0.12 * temper)
	if i == 1:
		a = float(Data.atk(level)) * 0.75
	return {
		"id": "pc%d" % i, "name": member_name(i), "side": "party", "idx": i, "lv": level, "boss": false,
		"hp": hp[i], "maxhp": float(max_hp(i)), "qi": qi[i], "maxqi": float(max_qi(i)),
		"atk": a, "def": float(Data.defense(level)) * (1.0 if i == 0 else 0.9), "spd": Data.speed(level) + (2 if i == 1 else 0),
		"elem": "phys", "weak": "none", "col": Color("7ec8ff") if i == 0 else Color("ff9ac0"),
		"shape": "hero" if i == 0 else "healer", "skills": Data.known_skills(i, level),
		"turns": 0, "flash": 0.0, "shake": 0.0, "dead": false, "fade": 1.0,
	}

func heal_full() -> void:
	for i in party_size():
		hp[i] = float(max_hp(i))
		qi[i] = float(max_qi(i))

# ---------------------------------------------------------------- cultivation
func exp_need() -> int:
	return Data.EXP_NEED[mini(level, 11)]

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

func record_kills(a: String, n: int) -> void:
	var s := cur_step()
	if not s.is_empty() and s.kind == "hunt" and s.area == a:
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
	return (3.0 + 1.2 * level) * (3.0 if near_spring else 1.0)

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
	return t

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
		inv[id] -= 1
		hp[i] = minf(float(max_hp(i)), hp[i] + max_hp(i) * 0.4)
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
		qi[j] = minf(float(max_qi(j)), qi[j] + max_qi(j) * 0.5)
		return "%s recovers qi." % member_name(j)
	return ""

func respawn() -> void:
	deaths += 1
	stones = int(stones * 0.85)
	area = "sect"
	tile = Vector2i(20, 8)
	heal_full()
	note("Defeated and carried back to the sect")
