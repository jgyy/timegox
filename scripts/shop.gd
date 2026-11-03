extends ScreenBase
## Alchemist (pills) and Smith (sword tempering) shops.

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
			labels.append("Temper sword (tier %d)  %d stones  +12%% attack" % [Game.temper + 1, price])
			ids.append("temper")
			enabled.append(Game.stones >= price)
		else:
			labels.append("Your sword is fully tempered")
			ids.append("none")
			enabled.append(false)
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
			else:
				Game.stones -= Data.pill_price(id, Game.level)
				Game.add_item(id)
				msg = "Purchased %s." % Data.ITEMS[id].n
				_build()

func _process(_d: float) -> void:
	redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.5))
	UI.panel(self, Rect2(260, 120, 760, 100))
	UI.text(self, Vector2(280, 160), "Alchemist Mo's Cauldron" if kind == "alchemist" else "Smith Tie's Forge", 26, UI.C_GOLD)
	UI.text(self, Vector2(280, 196), msg, 17)
	UI.menu_list(self, Rect2(260, 240, 760, 60 + labels.size() * 34), labels, cursor, enabled, 20)
	UI.text(self, Vector2(260, 660), "Spirit stones: %d" % Game.stones, 20, UI.C_GOLD)
