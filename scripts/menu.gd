extends ScreenBase
## Pause menu: meditate, breakthrough, items, status.

const VIEW := Vector2(1280, 720)

var mode := "root"
var labels: Array = []
var ids: Array = []
var enabled: Array = []
var cursor := 0
var msg := ""
## the realm the world map shows (Part XI): the Unbroken Land, the Nine Heavens or the Nine Springs
var map_layer := "surface"

func open() -> void:
	mode = "root"
	msg = ""
	_build()

## The realms Lin Feng has set foot in, in order (the land always).
func map_layers() -> Array:
	var out: Array = ["surface"]
	for lid in Atlas.STRATA:
		for id in Atlas.region_ids(lid):
			if Game.seen.has(id) and not out.has(lid):
				out.append(lid)
	return out

func _build() -> void:
	if mode == "root":
		labels = ["Meditate", "Breakthrough", "Items", "Dao & Peoples", "World Map", "Annals", "Resume"]
		ids = ["meditate", "breakthrough", "items", "dao", "map", "annals", "resume"]
		enabled = [Game.level < Data.MAX_LEVEL, Game.can_breakthrough() and Game.cur_step().get("kind", "") == "breakthrough", true, Game.dao != "" or not Game.met.is_empty(), main.world.mini_tex != null, true, true]
	elif mode == "map" or mode == "dao":
		labels = ["Back"]
		ids = ["back"]
		enabled = [true]
	elif mode == "annals":
		labels = []
		ids = []
		enabled = []
		for e in annals():
			labels.append(e[1])
			ids.append(e[0])
			enabled.append(true)
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
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
		"left", "right":
			# the world map: the next realm Lin Feng has been to
			if mode == "map":
				var ls := map_layers()
				var k := ls.find(map_layer)
				map_layer = ls[(k + (1 if act == "right" else -1) + ls.size()) % ls.size()]
		"cancel":
			if mode == "items" or mode == "map" or mode == "annals" or mode == "dao":
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
					# open on the realm Lin Feng is in
					var here: String = main.world.layer
					if here.begins_with("f:"):
						here = str(main.world.wd.get("parent", "surface"))
					map_layer = here if map_layers().has(here) else "surface"
					_build()
				"dao":
					mode = "dao"
					cursor = 0
					_build()
				"annals":
					mode = "annals"
					cursor = 0
					_build()
				"resume":
					main.pop()
				"back":
					mode = "root"
					cursor = 0
					_build()
				_:
					if mode == "annals":
						return
					msg = Game.use_item_field(id)
					_build()

func _process(d: float) -> void:
	t += d
	redraw()

## The Annals: what the land remembers of every region Lin Feng has been to, and of the towns in
## them, in the order the story reaches them.  Each entry is [id, title, text].
static func annals() -> Array:
	var out: Array = []
	for id in [Atlas.HUB] + Data.AREA_CHAIN:
		if not Game.seen.has(id):
			continue
		out.append([id, Data.AREAS[id].n, Data.REGION_LORE.get(id, "")])
		for tw in Data.TOWNS:
			if tw.area == id:
				out.append(["town:" + str(tw.id), "   " + str(tw.n), str(tw.lore)])
	return out

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
	"juntian": "Juntian", "changhe": "Changhe", "ninesprings": "The Nine Springs", "youdu": "Youdu",
}

## The whole open world, the Unbroken Land within the Four Seas: every region in its own colours and
## its name over it, roads, towns, seals still closed in red and where Lin Feng stands; beside it,
## what is known of the region he is in.
func _draw_map() -> void:
	var w = main.world
	var r := Rect2(20, 14, 1240, 692)
	UI.panel(self, r)
	var area := Rect2(r.position + Vector2(16, 36), Vector2(760, 640))
	var mw: Dictionary = Atlas.world_of(map_layer)
	var tex: Texture2D = w.realm_minimap(map_layer)
	var scale := minf(area.size.x / mw.w, area.size.y / mw.h)
	var sz := Vector2(mw.w, mw.h) * scale
	var o := area.position + (area.size - sz) * 0.5
	UI.text(self, r.position + Vector2(20, 28), Atlas.LAYER_NAMES.get(map_layer, ""), 20, UI.C_GOLD)
	var lays := map_layers()
	if lays.size() > 1:
		var tabs: Array = []
		for lid in lays:
			tabs.append(("[%s]" if lid == map_layer else "%s") % Atlas.LAYER_NAMES[lid])
		UI.text(self, r.position + Vector2(260, 28), "  ".join(tabs) + "    (Left/Right)", 13, UI.C_DIM)
	if tex != null:
		draw_texture_rect(tex, Rect2(o, sz), false)
	draw_rect(Rect2(o, sz), UI.C_BORDER.darkened(0.4), false, 1.0)
	var town_at := {}
	for tw in Data.TOWNS:
		if Data.layer_of(tw.area) == map_layer:
			town_at[tw.id] = o + (Vector2(Atlas.to_world(tw.area, tw.pos)) + Vector2(0.5, 0.5)) * scale
	for id in mw.ids:
		if id == "sect":
			continue
		var site: Vector2i = Atlas.layout()[id].site
		if id == Atlas.HUB:
			site += Vector2i(0, 48)  # below the sect, whose own label sits on the mountain's site
		var mid := o + (Vector2(site) + Vector2(0.5, 0.5)) * scale
		# a town at the heart of its region names it (Longmen Ferry, Tushan, Youdu): the two labels would
		# overlap; a town of another name near it (Featherfall in Juntian) puts the region's name below
		var named_by_town := false
		var below := 0.0
		var nm: String = MAP_NAMES.get(id, Data.AREAS[id].n)
		for tw2 in Data.TOWNS:
			if tw2.area != id or not town_at.has(tw2.id):
				continue
			var dd: float = (town_at[tw2.id] as Vector2).distance_to(mid)
			if dd < 26.0 or (dd < 44.0 and nm in str(tw2.n)):
				named_by_town = true
			elif dd < 44.0:
				below = 14.0
		if named_by_town:
			continue
		var col := Color(1, 1, 1, 0.92) if id != Atlas.HUB else Color(0.85, 1.0, 0.85, 0.9)
		UI.text(self, mid + Vector2(-60, 4 + below), nm, 10, col, HORIZONTAL_ALIGNMENT_CENTER, 120)
	for tw in Data.TOWNS:
		if not town_at.has(tw.id):
			continue
		var tp: Vector2 = town_at[tw.id]
		draw_rect(Rect2(tp - Vector2(3, 3), Vector2(6, 6)), UI.C_GOLD)
		draw_rect(Rect2(tp - Vector2(3, 3), Vector2(6, 6)), Color(0, 0, 0, 0.8), false, 1.0)
		UI.text(self, tp + Vector2(-60, -6), tw.n, 9, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 120)
	for e in mw.ents:
		if e.kind == "seal" and not w.seal_open(e):
			draw_circle(o + (Vector2(e.pos) + Vector2(0.5, 0.5)) * scale, 3.0, Color("ff5050"))
		elif e.kind == "ladder" and str(e.get("style", "")) == "climb":
			draw_circle(o + (Vector2(e.pos) + Vector2(0.5, 0.5)) * scale, 3.5, Color("a8e0ff") if w.ladder_open(e) else Color("6a7a8a"))
	if map_layer == "surface":
		var so: Vector2i = Atlas.to_world("sect", Vector2i(20, 13))
		UI.text(self, o + Vector2(so) * scale + Vector2(-60, -10), "Azure Cloud Sect", 10, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 120)
	var here_layer: String = w.layer if not w.is_floor() else str(w.wd.parent)
	if here_layer == map_layer:
		var pp: Vector2 = o + (Vector2(w.view_tile()) + Vector2(0.5, 0.5)) * scale
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
	if Game.reached("s_p11_home"):
		draw_circle(Vector2(cx + 5, ly + 63), 3.5, Color("a8e0ff"))
		UI.text(self, Vector2(cx + 18, ly + 68), "the Jianmu, between the realms", 13, UI.C_DIM)
	UI.text(self, Vector2(cx, r.end.y - 18), "Enter / Esc: back", 13, UI.C_DIM)

## The Dao Lin Feng walks and how far he has walked each, and the peoples of the realms he has met:
## where they live, the Dao they honour, his standing with them, their boon and the gift they love.
func _draw_dao() -> void:
	var r := Rect2(30, 20, 1220, 680)
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(24, 36), "The Daos", 22, UI.C_GOLD)
	var y := 70.0
	for id in Data.DAO_ORDER:
		var d: Dictionary = Data.DAOS[id]
		var on: bool = id == Game.dao
		var xp: int = int(Game.dao_xp.get(id, 0))
		var tier := Game.dao_tier(id)
		var col: Color = d.col if on or xp > 0 else UI.C_DIM
		UI.text(self, r.position + Vector2(24, y), ("> " if on else "  ") + str(d.n), 17, col, HORIZONTAL_ALIGNMENT_LEFT, 316)
		var rank := "" if not Game.dao_xp.has(id) else str(Data.DAO_RANKS[tier])
		UI.text(self, r.position + Vector2(350, y), rank, 14, UI.C_DIM)
		var nxt: int = Data.DAO_TIERS[mini(tier + 1, Data.DAO_TIERS.size() - 1)]
		UI.bar(self, Rect2(r.position + Vector2(430, y - 11), Vector2(130, 8)), 1.0 if tier >= Data.DAO_TIERS.size() - 1 else float(xp) / float(maxi(nxt, 1)), col)
		y += 20.0
		y += _wrap_at(r.position + Vector2(44, y), str(d.desc), 13, UI.C_DIM.lightened(0.2), 516) + 12.0
	if Game.dao != "":
		var dd: Dictionary = Data.DAOS[Game.dao]
		_wrap_at(r.position + Vector2(24, y + 6), "\"%s\"  Technique from Adept: %s.  Change roads at any Dao Stele." % [dd.motto, Data.SKILLS[dd.skill].n], 14, UI.C_TEXT, 536)
	UI.text(self, r.position + Vector2(600, 36), "The peoples of the realms", 22, UI.C_GOLD)
	var y2 := 70.0
	for race in Data.RACE_ORDER:
		var rc: Dictionary = Data.RACES[race]
		if race != "human" and not Game.met.has(race):
			continue
		UI.text(self, r.position + Vector2(600, y2), str(rc.n), 17, UI.C_GOLD if race != "human" else UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 330)
		UI.text(self, r.position + Vector2(940, y2), str(rc.home), 12, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 250)
		y2 += 20.0
		var line := "Honour the %s." % Data.DAOS[rc.dao].n
		if race != "human":
			var st: int = int(Game.standing.get(race, 0))
			UI.bar(self, Rect2(r.position + Vector2(600, y2 - 9), Vector2(120, 8)), float(st) / float(Data.KIN), Color("8ae0c0"))
			UI.text(self, r.position + Vector2(730, y2), Game.race_title(race), 13, UI.C_JADE)
			line += "  Love: %s." % Data.ITEMS[rc.gift].n
			if Game.race_tier(race) >= 1:
				line += "\nBoon: %s." % rc.boon_n
			y2 += 18.0
		y2 += _wrap_at(r.position + Vector2(600, y2), line, 12, UI.C_DIM.lightened(0.25), 590) + 12.0
	UI.text(self, Vector2(r.end.x - 200, r.end.y - 16), "Enter / Esc: back", 13, UI.C_DIM)

## Draw `s` wrapped to `width` with its first baseline at `p`; returns how far the next line moves down.
func _wrap_at(p: Vector2, s: String, size: int, col: Color, width: float) -> float:
	UI.wrapped(self, p, s, size, col, width)
	var h: float = UI.font().get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, width, size).y
	return maxf(h, float(size) + 4.0)

func _draw_annals() -> void:
	UI.text(self, Vector2(60, 70), "Annals", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 360, 600), labels, cursor, enabled, 17)
	var r := Rect2(420, 80, 820, 600)
	UI.panel(self, r)
	var entries := annals()
	if cursor < entries.size():
		var e: Array = entries[cursor]
		UI.text(self, r.position + Vector2(24, 40), str(e[1]).strip_edges(), 24, UI.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		UI.wrapped(self, r.position + Vector2(24, 80), str(e[2]), 17, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 40), "What the land remembers of the places you have been. %d of %d regions visited." % [Game.seen.size(), Data.AREA_CHAIN.size() + 1], 17, UI.C_DIM, r.size.x - 48)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.55))
	if mode == "map":
		_draw_map()
		return
	if mode == "dao":
		_draw_dao()
		return
	if mode == "annals":
		_draw_annals()
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
	var known := Data.known_skills(0, Game.level, Game.step)
	# four columns, as many rows as the list needs in the space above the stones line: four fixed
	# columns of seven ran the 29th and 30th techniques (the end of Part IX) off the right edge of the
	# panel, and Part X brings the list to 33
	var rows := maxi(7, int(ceil(known.size() / 4.0)))
	var step := minf(22.0, 160.0 / rows)
	var ki := 0
	for sid in known:
		var s: Dictionary = Data.SKILLS[sid]
		var kp := Vector2(430 + (ki / rows) * 196, 348.0 + (ki % rows) * step)
		UI.text(self, kp, "%s  %d" % [s.n, s.cost], 13 if step >= 18.0 else 12, Data.ELEM_COLORS[s.elem], HORIZONTAL_ALIGNMENT_LEFT, 192)
		ki += 1
	UI.text(self, Vector2(430, 530), "Spirit stones: %d    Sword tempering: %d/%d" % [Game.stones, Game.temper, Data.TEMPER_COST.size()], 17)
	UI.text(self, Vector2(430, 560), "Objective: " + Game.objective_text(), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 770)
	UI.text(self, Vector2(430, 610), "Play time %s" % Fmt.clock(Game.playtime), 15, UI.C_DIM)
	if msg != "":
		UI.text(self, Vector2(60, 340), msg, 17, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, 300)
