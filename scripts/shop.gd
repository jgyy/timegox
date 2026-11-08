extends ScreenBase
## Alchemist (pills) and Smith (sword tempering) shops.  Both also craft (trials.gd RECIPES): the
## alchemist refines talismans, inks and elixirs at the cauldron, the smith forges sigils, lenses and
## mirrors, from the essences monsters leave behind, things found on the quests and spirit stones.
## A list on the left; on the right, what the entry under the cursor is, needs and is for.

const VIEW := Vector2(1280, 720)

var kind := "alchemist"
var labels: Array = []
var ids: Array = []
var enabled: Array = []
var cursor := 0
var msg := ""

func open(k: String) -> void:
	kind = k
	cursor = 0
	msg = "Welcome. What do you need?"
	_build()

func _build() -> void:
	labels = []
	ids = []
	enabled = []
	if kind == "alchemist":
		for k in ["hp_pill", "qi_pill"]:
			var price := Data.pill_price(k, Game.level)
			labels.append("%s  %d stones  (own %d)" % [Data.ITEMS[k].n, price, Game.inv.get(k, 0)])
			ids.append(k)
			enabled.append(Game.stones >= price)
	else:
		if Game.temper < Data.TEMPER_COST.size():
			var price: int = Data.TEMPER_COST[Game.temper]
			labels.append("Temper sword (tier %d)  %d stones" % [Game.temper + 1, price])
			ids.append("temper")
			enabled.append(Game.stones >= price)
		else:
			labels.append("Your sword is fully tempered")
			ids.append("none")
			enabled.append(false)
	# what can be made here now
	for rid in Trials.recipes_at(kind, Game):
		labels.append(("Refine: %s" if kind == "alchemist" else "Forge: %s") % Data.ITEMS[rid].n)
		ids.append("craft:" + rid)
		enabled.append(Trials.can_craft(rid, Game))
	labels.append("Leave")
	ids.append("leave")
	enabled.append(true)
	cursor = clampi(cursor, 0, labels.size() - 1)

func press(act: String) -> void:
	match act:
		"up":
			cursor = (cursor - 1 + labels.size()) % labels.size()
		"down":
			cursor = (cursor + 1) % labels.size()
		"cancel":
			main.pop()
		"confirm":
			if not enabled[cursor]:
				return
			var id: String = ids[cursor]
			if id == "leave":
				main.pop()
			elif id == "temper":
				Game.stones -= Data.TEMPER_COST[Game.temper]
				Game.temper += 1
				Game.note("Sword tempered to tier %d" % Game.temper)
				msg = "The blade sings. Attack permanently increased."
				_build()
			elif id.begins_with("craft:"):
				var rid := id.trim_prefix("craft:")
				if Game.craft(rid):
					msg = ("The cauldron hisses: %s." if kind == "alchemist" else "The anvil rings: %s.") % Data.ITEMS[rid].n
				_build()
			else:
				Game.stones -= Data.pill_price(id, Game.level)
				Game.add_item(id)
				msg = "Purchased %s." % Data.ITEMS[id].n
				_build()

func _process(_d: float) -> void:
	redraw()

## What the entry under the cursor is: its name, what it needs, what it is for.
func _detail() -> Array:
	if cursor >= ids.size():
		return []
	var id: String = ids[cursor]
	if id.begins_with("craft:"):
		var rid := id.trim_prefix("craft:")
		var r: Dictionary = Trials.RECIPES[rid]
		var tid: String = str(r.get("for", ""))
		var forwhat := ""
		if tid != "" and Data.ENEMIES.has(tid):
			forwhat = "\n\nFor the trial of %s." % Data.ENEMIES[tid].n
		return [str(Data.ITEMS[rid].n), str(Data.ITEMS[rid].desc) + "\n\nNeeds: " + Trials.recipe_text(rid, Game) + forwhat]
	if id == "temper":
		return ["Temper the sword", "Each tier: +12% attack. Some trials ask for a sword tempered to a given tier."]
	if id in ["hp_pill", "qi_pill"]:
		return [str(Data.ITEMS[id].n), str(Data.ITEMS[id].desc)]
	return []

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.5))
	UI.panel(self, Rect2(80, 100, 1120, 100))
	UI.text(self, Vector2(100, 140), "Alchemist Mo's Cauldron" if kind == "alchemist" else "Smith Tie's Forge", 26, UI.C_GOLD)
	UI.text(self, Vector2(100, 176), msg, 17)
	UI.menu_list(self, Rect2(80, 220, 560, mini(420, 60 + labels.size() * 34)), labels, cursor, enabled, 19)
	var det := _detail()
	if not det.is_empty():
		var r := Rect2(660, 220, 540, 300)
		UI.panel(self, r)
		UI.text(self, r.position + Vector2(20, 36), str(det[0]), 21, UI.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40)
		UI.wrapped(self, r.position + Vector2(20, 70), str(det[1]), 15, UI.C_TEXT, r.size.x - 40)
	UI.text(self, Vector2(80, 670), "Spirit stones: %s" % Trials._num(Game.stones), 20, UI.C_GOLD)
	# the essences in hand, which the recipes work
	var ex := 400.0
	for ek in Trials.ESSENCE_ORDER:
		var n: int = int(Game.inv.get(ek, 0))
		var col: Color = Data.ELEM_COLORS.get(Trials.elem_of(ek), UI.C_TEXT)
		UI.text(self, Vector2(ex, 670), "%s %d" % [str(Data.ITEMS[ek].n).trim_suffix(" Essence"), n], 15, col if n > 0 else UI.C_DIM)
		ex += 112.0
