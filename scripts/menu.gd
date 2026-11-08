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

## Short names for the world map (the full names run to forty letters).
const MAP_NAMES := {
	"mountain": "Azure Cloud Mountain", "bamboo": "Bamboo Forest", "marsh": "Crimson Marsh", "frost": "Frostpeak", "thunder": "Thunder Valley",
	"palace": "Blood Moon Palace", "dragon": "Sunken Dragon Palace", "volcano": "Ashen Volcano", "void": "Void Rift", "celestial": "Celestial Gate",
	"mirror": "Mirror Lake", "grave": "Sword Graveyard", "time": "River of Years", "origin": "Origin of the Dao",
	"cloudsea": "Sea of Clouds", "court": "Jade Court", "forge": "Heaven's Forge", "garden": "Peach Garden",
	"dunes": "Fallen Stars", "fungal": "Glowcap Vale", "aurora": "Aurora Steppe", "chaos": "Primordial Chaos",
	"maple": "Maple Gorge", "karst": "Stone Forest", "springs": "Yellow Springs", "wheel": "Six Paths",
	"village": "Qingshi Village", "terraces": "Tea Terraces", "silk": "Silk Woods", "loom": "The Loom",
	"starferry": "Starfall Ferry", "magpie": "Magpie Heights", "starpalace": "Weaver Star", "jasper": "Jasper Pool",
	"yanggu": "Yanggu", "millet": "Millet Plains", "fusang": "Fusang", "guanghan": "Guanghan",
	"longmen": "Longmen", "drowned": "Drowned Fields", "tushan": "Tushan", "buzhou": "Mount Buzhou",
}

## The whole open world, the Unbroken Land within the Four Seas: every region in its own colours and
## its name over it, roads, towns, seals still closed in red and where Lin Feng stands; beside it,
## what is known of the region he is in.
func _draw_map() -> void:
	var w = main.world
	var r := Rect2(20, 14, 1240, 692)
	UI.panel(self, r)
	var area := Rect2(r.position + Vector2(16, 36), Vector2(760, 640))
	var scale := minf(area.size.x / w.w, area.size.y / w.h)
	var sz := Vector2(w.w, w.h) * scale
	var o := area.position + (area.size - sz) * 0.5
	UI.text(self, r.position + Vector2(20, 28), "The Unbroken Land", 20, UI.C_GOLD)
	draw_texture_rect(w.mini_tex, Rect2(o, sz), false)
	draw_rect(Rect2(o, sz), UI.C_BORDER.darkened(0.4), false, 1.0)
	for id in w.wd.ids:
		if id == "sect":
			continue
		var site: Vector2i = w.wd.layout[id].site
		var mid := o + (Vector2(site) + Vector2(0.5, 0.5)) * scale
		var col := Color(1, 1, 1, 0.92) if id != Atlas.HUB else Color(0.85, 1.0, 0.85, 0.9)
		UI.text(self, mid + Vector2(-60, 4), MAP_NAMES.get(id, Data.AREAS[id].n), 10, col, HORIZONTAL_ALIGNMENT_CENTER, 120)
	for tw in Data.TOWNS:
		var tp: Vector2 = o + (Vector2(Atlas.to_world(tw.area, tw.pos)) + Vector2(0.5, 0.5)) * scale
		draw_rect(Rect2(tp - Vector2(3, 3), Vector2(6, 6)), UI.C_GOLD)
		draw_rect(Rect2(tp - Vector2(3, 3), Vector2(6, 6)), Color(0, 0, 0, 0.8), false, 1.0)
		UI.text(self, tp + Vector2(-60, -6), tw.n, 9, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 120)
	for e in w.ents:
		if e.kind == "seal" and not w.seal_open(e):
			draw_circle(o + (Vector2(e.pos) + Vector2(0.5, 0.5)) * scale, 3.0, Color("ff5050"))
	var so: Vector2i = Atlas.to_world("sect", Vector2i(20, 13))
	UI.text(self, o + Vector2(so) * scale + Vector2(-60, -10), "Azure Cloud Sect", 10, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 120)
	var pp: Vector2 = o + (Vector2(w.ptile) + Vector2(0.5, 0.5)) * scale
	draw_circle(pp, 6.0 + sin(t * 5.0) * 1.5, Color(1, 1, 1, 0.4))
	draw_circle(pp, 3.5, Color("5aa9ff"))
	# beside the map: where Lin Feng is and what the land remembers of it
	var cx := area.end.x + 20
	var cw := r.end.x - cx - 18
	UI.text(self, Vector2(cx, r.position.y + 64), "You are in", 14, UI.C_DIM)
	UI.text(self, Vector2(cx, r.position.y + 90), w.area_name, 19, UI.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, cw)
	UI.wrapped(self, Vector2(cx, r.position.y + 122), Data.REGION_LORE.get(w.area_id, ""), 14, UI.C_TEXT, cw)
	var ly := r.end.y - 112
	draw_rect(Rect2(cx, ly - 8, 10, 10), UI.C_GOLD)
	UI.text(self, Vector2(cx + 18, ly + 2), "town", 13, UI.C_DIM)
	draw_circle(Vector2(cx + 5, ly + 19), 3.0, Color("ff5050"))
	UI.text(self, Vector2(cx + 18, ly + 24), "Lotus Seal, still closed", 13, UI.C_DIM)
	draw_circle(Vector2(cx + 5, ly + 41), 3.5, Color("5aa9ff"))
	UI.text(self, Vector2(cx + 18, ly + 46), "Lin Feng", 13, UI.C_DIM)
	UI.text(self, Vector2(cx, r.end.y - 18), "Enter / Esc: back", 13, UI.C_DIM)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.55))
	if mode == "map":
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
