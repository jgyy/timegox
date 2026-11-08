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
		labels = ["Meditate", "Breakthrough", "Items", "Cultivation", "Journal", "Fates", "Dao & Peoples", "Wardrobe", "Stable", "Bestiary", "World Map", "Annals", "Resume"]
		ids = ["meditate", "breakthrough", "items", "cultivation", "journal", "fates", "dao", "wardrobe", "stable", "bestiary", "map", "annals", "resume"]
		enabled = [Game.level < Data.MAX_LEVEL, Game.can_breakthrough() and Game.cur_step().get("kind", "") == "breakthrough", true, true, true, true, Game.dao != "" or not Game.met.is_empty(),
			true, not Game.rides.is_empty(), not Game.bestiary.is_empty() or not Game.told.is_empty(), main.world.mini_tex != null, true, true]
	elif mode == "bestiary":
		labels = []
		ids = []
		enabled = []
		for e in bestiary():
			labels.append(e[1])
			ids.append(e[0])
			enabled.append(true)
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "fates":
		labels = ["Back"]
		ids = ["back"]
		enabled = [true]
	elif mode == "cultivation":
		# Part XII: the realm and the branches of the root; an awakening not yet spent can be spent here
		labels = ["Wake a branch (%d)" % Game.talent_pts, "Back"]
		ids = ["wake", "back"]
		enabled = [Game.talent_pts > 0, true]
	elif mode == "map" or mode == "dao" or mode == "journal":
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
			if mode in ["items", "map", "annals", "dao", "cultivation", "journal", "bestiary", "fates"]:
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
				"cultivation":
					mode = "cultivation"
					cursor = 0
					_build()
				"journal":
					mode = "journal"
					cursor = 0
					_build()
				"wake":
					main.pop()
					main.open_talent_choice()
				"annals":
					mode = "annals"
					cursor = 0
					_build()
				"bestiary":
					mode = "bestiary"
					cursor = 0
					_build()
				"fates":
					mode = "fates"
					cursor = 0
					_build()
				"wardrobe":
					main.pop()
					main.open_wardrobe()
				"stable":
					main.pop()
					main.open_stable()
				"resume":
					main.pop()
				"back":
					mode = "root"
					cursor = 0
					_build()
				_:
					if mode == "annals" or mode == "bestiary":
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
		# Part XII: the Founder's caves Lin Feng has opened on the mountain, and what she wrote in them
		if id == Atlas.HUB:
			for ab in Data.AREAS.mountain.get("abodes", []):
				if not Game.abodes.has(ab.id):
					continue
				var words: Array = []
				for dl in Data.DIALOGUE.get("abode:" + str(ab.id), []):
					words.append(("%s: " % dl[0] if str(dl[0]) != "Narrator" else "") + str(dl[1]))
				words.append("On the wall: \"%s\"" % ab.motto)
				out.append(["cave:" + str(ab.id), "   " + str(ab.n), "\n\n".join(words)])
	return out

## The Bestiary (Fates and Faces, lore.gd): every foe Lin Feng has met or been told of, in the order
## the story meets them, each [id, label, story].
static func bestiary() -> Array:
	var out: Array = []
	for id in Data.ENEMIES:
		if not Game.bestiary.has(id) and not Game.told.has(id):
			continue
		var story := Lore.story(id)
		if story == "":
			continue
		var boss: bool = Data.ENEMIES[id].get("boss", false)
		out.append([id, ("* " if boss else "") + str(Data.ENEMIES[id].n), story])
	return out

func _draw_bestiary() -> void:
	UI.text(self, Vector2(60, 70), "Bestiary", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var entries := bestiary()
	if cursor < entries.size():
		var e: Array = entries[cursor]
		var d: Dictionary = Data.ENEMIES[e[0]]
		var ec: Color = Data.ELEM_COLORS.get(d.elem, UI.C_TEXT)
		UI.text(self, r.position + Vector2(24, 40), str(d.n), 24, UI.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		var kind := "Boss" if d.get("boss", false) else "Met in %d battle%s" % [int(Game.bestiary.get(e[0], 0)), "" if int(Game.bestiary.get(e[0], 0)) == 1 else "s"]
		UI.text(self, r.position + Vector2(24, 70), "%s  -  %s, weak to %s" % [kind, str(d.elem).capitalize(), str(d.weak).capitalize()], 16, ec, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		UI.wrapped(self, r.position + Vector2(24, 110), str(e[2]), 18, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 40), "Every foe has a story. %d of %d met so far; the bosses are marked with a star." % [entries.size(), Data.ENEMIES.size()], 17, UI.C_DIM, r.size.x - 48)

## The Fates page (fate.gd): the five people whose lives Lin Feng has changed, what he made of each
## so far (their state, and every choice in order) and where their story will take him next.
func _draw_fates() -> void:
	var r := Rect2(30, 20, 1220, 680)
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(24, 40), "Fates: the people whose lives you changed", 24, UI.C_GOLD)
	UI.text(self, r.position + Vector2(24, 66), "%d of the five stand with you. Choices made here are remembered to the end." % Fate.allies(Game), 15, UI.C_DIM)
	var y := r.position.y + 100.0
	for th in Fate.THREAD_ORDER:
		var td: Dictionary = Fate.THREADS[th]
		var st := Fate.state(Game, th)
		var stt: Array = Fate.state_text(th, st)
		var met := st != ""
		UI.text(self, Vector2(r.position.x + 24, y), str(td.n), 19, td.col if met else UI.C_DIM)
		UI.text(self, Vector2(r.position.x + 430, y), str(stt[0]), 18, UI.C_TEXT if met else UI.C_DIM)
		var lines: Array = Game.fate_log.get(th, [])
		var desc := str(stt[1]) if met else str(td.intro) if false else "Somewhere ahead on the road."
		if met:
			desc = str(stt[1])
			if not lines.is_empty():
				desc += "   " + " / ".join(lines.slice(maxi(0, lines.size() - 2)))
		UI.wrapped(self, Vector2(r.position.x + 40, y + 24), desc, 14, UI.C_DIM.lightened(0.3), r.size.x - 70)
		y += 112.0
	UI.text(self, Vector2(r.position.x + 24, r.end.y - 16), "Esc back", 14, UI.C_DIM)

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
	"penglai": "Penglai", "fangzhang": "Fangzhang", "yingzhou": "Yingzhou", "guixu": "Guixu",
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

## The Cultivation page (Part XII): what Lin Feng's realm means (how long he will live, how the world
## addresses him, what it is like, how realm suppression works), the Founder's caves he has opened,
## and the nine branches of the Nine Heavens root with their ranks, what each rank adds and their crowns.
func _draw_cultivation() -> void:
	var r := Rect2(30, 20, 1220, 680)
	UI.panel(self, r)
	var x0 := r.position.x + 24
	UI.text(self, Vector2(x0, r.position.y + 36), "Realm", 22, UI.C_GOLD)
	var ri: Dictionary = Data.REALM_INFO[mini(Game.realm(), Data.REALM_INFO.size() - 1)]
	UI.text(self, Vector2(x0, r.position.y + 68), Data.level_name(Game.level), 20, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 380)
	var life := "beyond counting" if int(ri.life) == 0 else "about %s years" % _thousands(int(ri.life))
	UI.text(self, Vector2(x0, r.position.y + 94), "Lifespan: %s" % life, 15, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 380)
	UI.text(self, Vector2(x0, r.position.y + 116), "The world calls you: %s" % Game.address(), 15, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 380)
	var y := r.position.y + 146.0
	y += _wrap_at(Vector2(x0, y), str(ri.note), 14, UI.C_TEXT, 380) + 14.0
	y += _wrap_at(Vector2(x0, y), "Realm suppression: a whole realm between two fighters makes the higher strike %d%% harder and the lower strike that much softer, up to three realms. Beasts two realms below you scatter rather than fight. Heavenly Tribulations weigh on every realm alike." % int(Data.SUPPRESS * 100), 13, UI.C_DIM.lightened(0.25), 380) + 14.0
	var opened := 0
	var total := 0
	for ab in Data.AREAS.mountain.get("abodes", []):
		total += 1
		if Game.abodes.has(ab.id):
			opened += 1
	UI.text(self, Vector2(x0, y), "Founder's caves opened: %d of %d" % [opened, total], 14, UI.C_GOLD)
	y += 22.0
	UI.text(self, Vector2(x0, y), "Packs scattered by your aura: %d" % Game.scattered, 14, UI.C_DIM)
	y += 22.0
	UI.text(self, Vector2(x0, y), "Awakenings of the root: %d   (unspent: %d)" % [Game.awakenings, Game.talent_pts], 14, UI.C_JADE if Game.talent_pts > 0 else UI.C_DIM)
	UI.menu_list(self, Rect2(x0 - 8, r.end.y - 112, 300, 90), labels, cursor, enabled, 17)
	# the nine branches
	var x1 := r.position.x + 440
	UI.text(self, Vector2(x1, r.position.y + 36), "The nine branches of the Nine Heavens root", 22, UI.C_GOLD)
	var y2 := r.position.y + 66.0
	for id in Data.TALENT_ORDER:
		var tl: Dictionary = Data.TALENTS[id]
		var rk := Game.talent(id)
		var col: Color = tl.col if rk > 0 else UI.C_DIM
		UI.text(self, Vector2(x1, y2), str(tl.n), 16, col, HORIZONTAL_ALIGNMENT_LEFT, 200)
		for k in Data.TALENT_MAX:
			var pip := Rect2(x1 + 206 + k * 18, y2 - 11, 12, 12)
			draw_rect(pip, col if k < rk else Color(0.2, 0.22, 0.3, 0.9))
			draw_rect(pip, UI.C_BORDER.darkened(0.3), false, 1.0)
		UI.text(self, Vector2(x1 + 270, y2), str(Data.TALENT_RANKS[rk]), 13, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 110)
		y2 += 17.0
		UI.text(self, Vector2(x1 + 16, y2), "Each rank: " + str(tl.per), 12, UI.C_DIM.lightened(0.25), HORIZONTAL_ALIGNMENT_LEFT, 740)
		y2 += 16.0
		var crown_col := Color(tl.col.r, tl.col.g, tl.col.b, 1.0) if rk >= Data.TALENT_MAX else UI.C_DIM
		UI.text(self, Vector2(x1 + 16, y2), "Crown: " + str(tl.crown), 12, crown_col, HORIZONTAL_ALIGNMENT_LEFT, 740)
		y2 += 30.0
	UI.text(self, Vector2(r.end.x - 200, r.end.y - 16), "Enter / Esc: back", 13, UI.C_DIM)

## The Journal (many roads, trials.gd): Lin Feng's renown, the essences and treasures he carries and
## what townsfolk have asked of him on the left; on the right the trial ahead, every way through it
## and what each needs (ticked or not), or the Eight Gates, and the trials already passed.
func _draw_journal() -> void:
	var r := Rect2(30, 20, 1220, 680)
	UI.panel(self, r)
	var x0 := r.position.x + 24
	UI.text(self, Vector2(x0, r.position.y + 36), "Renown", 22, UI.C_GOLD)
	var nxt := 0
	var prev := 0
	for rt in Trials.RENOWN_TITLES:
		if Game.renown >= int(rt[0]):
			prev = int(rt[0])
		elif nxt == 0:
			nxt = int(rt[0])
	UI.text(self, Vector2(x0, r.position.y + 64), "%d   %s" % [Game.renown, Game.renown_title()], 18, Trials.KINDS.respect.col)
	if nxt > 0:
		UI.bar(self, Rect2(x0 + 200, r.position.y + 52, 200, 10), float(Game.renown - prev) / float(maxi(1, nxt - prev)), Trials.KINDS.respect.col)
	UI.text(self, Vector2(x0, r.position.y + 86), "Bosses, trials, gifts and deeds for townsfolk raise it.", 12, UI.C_DIM)
	var y := r.position.y + 118.0
	UI.text(self, Vector2(x0, y), "Essences", 18, UI.C_GOLD)
	y += 24.0
	var k := 0
	for ek in Trials.ESSENCE_ORDER:
		var n: int = int(Game.inv.get(ek, 0))
		var col: Color = Data.ELEM_COLORS.get(Trials.elem_of(ek), UI.C_TEXT)
		UI.text(self, Vector2(x0 + (k % 4) * 140, y + (k / 4) * 20), "%s %d" % [Data.ITEMS[ek].n, n], 14, col if n > 0 else UI.C_DIM)
		k += 1
	y += 52.0
	UI.text(self, Vector2(x0, y), "Treasures", 18, UI.C_GOLD)
	y += 22.0
	var tre: Array = []
	for rid in Trials.RECIPES:
		if int(Game.inv.get(rid, 0)) > 0:
			tre.append(str(Data.ITEMS[rid].n))
	for rc in Data.RACE_ORDER:
		var gift: String = str(Data.RACES[rc].gift)
		if gift != "" and int(Game.inv.get(gift, 0)) > 0:
			tre.append("%s x%d" % [Data.ITEMS[gift].n, int(Game.inv[gift])])
	y += _wrap_at(Vector2(x0, y), ", ".join(tre) if not tre.is_empty() else "Nothing crafted or kept yet. Alchemist Mo and Smith Tie craft from essences.", 13, UI.C_TEXT if not tre.is_empty() else UI.C_DIM, 560) + 12.0
	UI.text(self, Vector2(x0, y), "Requests", 18, UI.C_GOLD)
	y += 22.0
	var shown := 0
	for did in Trials.DEEDS:
		var dd: Dictionary = Trials.DEEDS[did]
		if Game.deeds.has(did) or not Game.reached(str(dd.after)):
			continue
		if shown >= 7:
			break
		shown += 1
		var who := Trials.npc_name(str(dd.npc))
		var ready := Trials.deed_ready(did, Game)
		var line := "%s (%s): %s%s" % [who, MAP_NAMES.get(str(dd.area), Data.AREAS[str(dd.area)].n) if dd.area != "sect" else "the sect", Trials.want_text(did, Game), "  - ready" if ready else ""]
		y += _wrap_at(Vector2(x0, y), line, 12, UI.C_JADE if ready else UI.C_DIM.lightened(0.25), 560) + 4.0
	if shown == 0:
		UI.text(self, Vector2(x0, y + 4), "Nobody is asking for anything just now.", 13, UI.C_DIM)
	UI.text(self, Vector2(x0, r.end.y - 18), "Deeds done: %d of %d" % [Game.deeds.size(), Trials.DEEDS.size()], 13, UI.C_DIM)
	# the way ahead
	var x1 := r.position.x + 620
	var w1 := r.end.x - x1 - 24
	UI.text(self, Vector2(x1, r.position.y + 36), "The way ahead", 22, UI.C_GOLD)
	var y2 := r.position.y + 64.0
	var s := Game.cur_step()
	var tid := Trials.trial_of_step(s)
	if tid != "":
		var tr: Dictionary = Trials.TRIALS[tid]
		UI.text(self, Vector2(x1, y2), Data.ENEMIES[tid].n, 17, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, w1)
		y2 += 22.0
		y2 += _wrap_at(Vector2(x1, y2), str(tr.why), 12, UI.C_DIM.lightened(0.2), w1) + 10.0
		for p in tr.paths:
			var ok := Trials.path_met(tid, p, Game)
			var kc: Color = Trials.KINDS[p.kind].col
			UI.text(self, Vector2(x1, y2), "%s  %s%s" % [str(Trials.KINDS[p.kind].n), str(p.n), "  (ready)" if ok else ""], 14, kc if ok else kc.darkened(0.25), HORIZONTAL_ALIGNMENT_LEFT, w1)
			y2 += 18.0
			var paid: bool = str(Game.paid.get(tid, "")) == str(p.id)
			for n in p.needs:
				var met := Trials.need_met(n, Game, paid)
				y2 += _wrap_at(Vector2(x1 + 14, y2), ("[x] " if met else "[ ] ") + Trials.need_text(n, Game), 12, UI.C_JADE if met else UI.C_DIM.lightened(0.2), w1 - 14) + 2.0
			y2 += 8.0
	elif s.get("kind", "") == "gates":
		y2 += _wrap_at(Vector2(x1, y2), "Open any %d of the Eight Gates, in any order; every gate opened beyond that weakens the heart. Each gate is a trial of its own." % Trials.GATES_NEEDED, 13, UI.C_DIM.lightened(0.2), w1) + 10.0
		for gid in Trials.GATES:
			var open: bool = Game.gates_open.has(gid)
			var area := Trials.boss_area(gid)
			var kinds: Array = []
			var any_ok := false
			for p2 in Trials.TRIALS[gid].paths:
				kinds.append(str(Trials.KINDS[p2.kind].n).trim_prefix("By "))
				any_ok = any_ok or Trials.path_met(gid, p2, Game)
			var gn: String = str(Trials.GATE_NAMES[gid])
			var st := "open" if open else ("a way is ready" if any_ok else ", ".join(kinds))
			UI.text(self, Vector2(x1, y2), "%s%s, %s" % [gn.substr(0, 1).to_upper(), gn.substr(1), MAP_NAMES.get(area, area)], 14, UI.C_JADE if open else (UI.C_GOLD if any_ok else UI.C_TEXT), HORIZONTAL_ALIGNMENT_LEFT, w1)
			y2 += 17.0
			UI.text(self, Vector2(x1 + 14, y2), "%s: %s" % [Data.ENEMIES[gid].n, st], 12, UI.C_DIM.lightened(0.2), HORIZONTAL_ALIGNMENT_LEFT, w1 - 14)
			y2 += 22.0
	else:
		var nx := ""
		for i in range(Game.step, Data.STEPS.size()):
			var t2 := Trials.trial_of_step(Data.STEPS[i])
			if t2 != "":
				nx = "%s, in %s" % [Data.ENEMIES[t2].n, Data.AREAS[Data.STEPS[i].area].n]
				break
		y2 += _wrap_at(Vector2(x1, y2), "No trial stands in your way just now." + ("\n\nThe next: %s. Its ways will show here when you reach it." % nx if nx != "" else ""), 14, UI.C_DIM.lightened(0.2), w1) + 12.0
	# the trials passed, newest last
	var passed: Array = Game.trials.keys()
	UI.text(self, Vector2(x1, maxf(y2 + 10.0, r.end.y - 150.0)), "Trials passed: %d" % passed.size(), 17, UI.C_GOLD)
	var y3 := maxf(y2 + 32.0, r.end.y - 128.0)
	for tid2 in passed.slice(maxi(0, passed.size() - 5)):
		var p3 := Trials.path(str(tid2), str(Game.trials[tid2]))
		if p3.is_empty():
			continue
		UI.text(self, Vector2(x1, y3), "%s: %s" % [Data.ENEMIES[tid2].n, str(p3.n)], 12, Trials.KINDS[p3.kind].col, HORIZONTAL_ALIGNMENT_LEFT, w1)
		y3 += 18.0
	UI.text(self, Vector2(r.end.x - 200, r.end.y - 16), "Enter / Esc: back", 13, UI.C_DIM)

static func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.55))
	if mode == "cultivation":
		_draw_cultivation()
		return
	if mode == "map":
		_draw_map()
		return
	if mode == "dao":
		_draw_dao()
		return
	if mode == "annals":
		_draw_annals()
		return
	if mode == "journal":
		_draw_journal()
		return
	if mode == "bestiary":
		_draw_bestiary()
		return
	if mode == "fates":
		_draw_fates()
		return
	UI.menu_list(self, Rect2(60, 80, 300, 470), labels, cursor, enabled, 22)
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
	# what he really fights with: tempering, boons and the branches of the root included
	var f0 := Game.fighter(0)
	UI.text(self, Vector2(430, 238), "Attack %d   Defense %d   Speed %d" % [f0.atk, f0.def, f0.spd], 18)
	UI.text(self, Vector2(830, 238), "Root: %d/%d ranks" % [Game.talent_ranks(), Data.TALENT_ORDER.size() * Data.TALENT_MAX], 15, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, 200)
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
	# what he wears and rides (Fates and Faces)
	var outfit: Dictionary = Fashion.OUTFITS.get(Game.outfit, Fashion.OUTFITS.sweeper)
	var ride_n: String = str(Fashion.RIDES[Game.ride].n) if Game.ride != "" else "none yet"
	UI.text(self, Vector2(430, 586), "Wearing the %s (%s)   Ride: %s%s" % [outfit.n, Fashion.fx_text(outfit.fx), ride_n, "  (riding)" if Game.riding and Game.ride != "" else ""], 15, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 780)
	if msg != "":
		UI.text(self, Vector2(60, 580), msg, 17, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, 300)
