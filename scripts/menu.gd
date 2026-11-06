extends ScreenBase
## Pause menu: meditate, breakthrough, items, status.

const VIEW := Vector2(1280, 720)

var mode := "root"
var labels: Array = []
var ids: Array = []
var enabled: Array = []
var cursor := 0
var msg := ""

func open() -> void:
	mode = "root"
	msg = ""
	_build()

func _build() -> void:
	if mode == "root":
		labels = ["Meditate", "Breakthrough", "Items", "World Map", "Resume"]
		ids = ["meditate", "breakthrough", "items", "map", "resume"]
		enabled = [Game.level < Data.MAX_LEVEL, Game.can_breakthrough() and Game.cur_step().get("kind", "") == "breakthrough", true, main.world.mini_tex != null, true]
	elif mode == "map":
		labels = ["Back"]
		ids = ["back"]
		enabled = [true]
	else:
		labels = []
		ids = []
		enabled = []
		for iid in ["hp_pill", "qi_pill"]:
			labels.append("%s x%d" % [Data.ITEMS[iid].n, Game.inv.get(iid, 0)])
			ids.append(iid)
			enabled.append(Game.inv.get(iid, 0) > 0)
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	cursor = clampi(cursor, 0, labels.size() - 1)

func press(act: String) -> void:
	match act:
		"up":
			cursor = (cursor - 1 + labels.size()) % labels.size()
		"down":
			cursor = (cursor + 1) % labels.size()
		"cancel":
			if mode == "items" or mode == "map":
				mode = "root"
				cursor = 0
				_build()
			else:
				main.pop()
		"confirm":
			if not enabled[cursor]:
				return
			var id: String = ids[cursor]
			match id:
				"meditate":
					main.pop()
					main.start_meditation()
				"breakthrough":
					main.pop()
					main.start_breakthrough()
				"items":
					mode = "items"
					cursor = 0
					_build()
				"map":
					mode = "map"
					cursor = 0
					_build()
				"resume":
					main.pop()
				"back":
					mode = "root"
					cursor = 0
					_build()
				_:
					msg = Game.use_item_field(id)
					_build()

func _process(d: float) -> void:
	t += d
	redraw()

## The whole open world: every region in its own colours, its name over it, seals still closed in
## red, and where Lin Feng stands.
func _draw_map() -> void:
	var w = main.world
	var r := Rect2(400, 80, 820, 560)
	UI.panel(self, r)
	var scale := minf((r.size.x - 40) / w.w, (r.size.y - 60) / w.h)
	var sz := Vector2(w.w, w.h) * scale
	var o := r.position + Vector2((r.size.x - sz.x) * 0.5, 44)
	UI.text(self, r.position + Vector2(20, 30), "The Unbroken Land", 20, UI.C_GOLD)
	draw_texture_rect(w.mini_tex, Rect2(o, sz), false)
	for id in w.wd.ids:
		if id == "sect" or id == Atlas.HUB:
			continue
		var c: Rect2i = w.wd.layout[id].cell
		var mid := o + Vector2(w.wd.layout[id].origin + w.wd.layout[id].size / 2) * scale
		UI.text(self, mid - Vector2(60, 0), Data.AREAS[id].n.get_slice(" of ", 0), 11, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 120)
	for e in w.ents:
		if e.kind == "seal" and not w.seal_open(e):
			draw_circle(o + (Vector2(e.pos) + Vector2(0.5, 0.5)) * scale, 3.0, Color("ff5050"))
	var so: Vector2i = Atlas.to_world("sect", Vector2i(20, 13))
	UI.text(self, o + Vector2(so) * scale + Vector2(-50, -8), "Azure Cloud Sect", 11, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 100)
	var pp: Vector2 = o + (Vector2(w.ptile) + Vector2(0.5, 0.5)) * scale
	draw_circle(pp, 6.0 + sin(t * 5.0) * 1.5, Color(1, 1, 1, 0.4))
	draw_circle(pp, 3.5, Color("5aa9ff"))
	UI.text(self, r.position + Vector2(20, r.size.y - 14), "You are in: " + w.area_name, 15, UI.C_TEXT)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.55))
	if mode == "map":
		UI.menu_list(self, Rect2(60, 80, 300, 80), labels, cursor, enabled, 24)
		UI.text(self, Vector2(60, 70), "World Map", 22, UI.C_GOLD)
		_draw_map()
		return
	UI.menu_list(self, Rect2(60, 80, 300, 230), labels, cursor, enabled, 24)
	UI.text(self, Vector2(60, 70), "Menu" if mode == "root" else "Items", 22, UI.C_GOLD)
	# status panel
	var r := Rect2(400, 80, 820, 560)
	UI.panel(self, r)
	UI.text(self, Vector2(430, 120), "Lin Feng", 28, UI.C_GOLD)
	UI.text(self, Vector2(430, 150), Data.level_name(Game.level), 20)
	if Game.level < Data.MAX_LEVEL:
		UI.bar(self, Rect2(430, 162, 400, 12), Game.exp / float(Game.exp_need()), UI.C_GOLD)
		UI.text(self, Vector2(840, 174), "%d/%d" % [Game.exp, Game.exp_need()], 14, UI.C_DIM)
	UI.text(self, Vector2(430, 208), "HP %d/%d    QI %d/%d" % [Game.hp[0], Game.max_hp(0), Game.qi[0], Game.max_qi(0)], 18)
	UI.text(self, Vector2(430, 238), "Attack %d   Defense %d   Speed %d" % [Data.atk(Game.level) * (1.0 + 0.12 * Game.temper), Data.defense(Game.level), Data.speed(Game.level)], 18)
	if Game.companion:
		UI.text(self, Vector2(430, 276), "Yue Ling   HP %d/%d   QI %d/%d" % [Game.hp[1], Game.max_hp(1), Game.qi[1], Game.max_qi(1)], 18, Color("ff9ac0"))
	UI.text(self, Vector2(430, 320), "Techniques", 20, UI.C_GOLD)
	var ki := 0
	for sid in Data.known_skills(0, Game.level, Game.step):
		var s: Dictionary = Data.SKILLS[sid]
		# four columns of seven: the full list (24 techniques by Part VII) used to run off the right
		# of the panel once it passed 21 entries in three columns
		var kp := Vector2(430 + (ki / 7) * 196, 348.0 + (ki % 7) * 22.0)
		UI.text(self, kp, "%s  %d" % [s.n, s.cost], 13, Data.ELEM_COLORS[s.elem], HORIZONTAL_ALIGNMENT_LEFT, 192)
		ki += 1
	UI.text(self, Vector2(430, 530), "Spirit stones: %d    Sword tempering: %d/%d" % [Game.stones, Game.temper, Data.TEMPER_COST.size()], 17)
	UI.text(self, Vector2(430, 560), "Objective: " + Game.objective_text(), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 770)
	UI.text(self, Vector2(430, 610), "Play time %s" % Fmt.clock(Game.playtime), 15, UI.C_DIM)
	if msg != "":
		UI.text(self, Vector2(60, 340), msg, 17, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, 300)
