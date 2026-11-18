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
		labels = ["Meditate", "Breakthrough", "Items", "Cultivation", "Journal", "Fates", "Crossroads", "Works", "Yue Ling", "Dao & Peoples", "Root & Rites", "In Their Own Words", "Hearths", "Arms", "Wardrobe", "Stable", "The Host", "Town", "Songs", "Feats", "The Body", "The Load", "The Land", "The Way", "The Law", "The Wild", "The Almanac", "Bestiary", "World Map", "Annals", "Seals & Lists", "Leaves", "Resume"]
		ids = ["meditate", "breakthrough", "items", "cultivation", "journal", "fates", "roads", "works", "yue", "dao", "rites", "words", "hearths", "arms", "wardrobe", "stable", "host", "town", "songs", "feats", "body", "load", "land", "way", "law", "wild", "almanac", "bestiary", "map", "annals", "seals", "leaves", "resume"]
		enabled = [Game.level < Data.MAX_LEVEL, Game.can_breakthrough() and Game.cur_step().get("kind", "") == "breakthrough", true, true, true, true, true, true, Game.companion or Game.bond > 0,
			Game.dao != "" or not Game.met.is_empty(), Game.prologue == "", not Game.pages.is_empty(), true, true, true, not Game.rides.is_empty(), true, true, true, true, true, true, true, true, true, true, true, not Game.bestiary.is_empty() or not Game.told.is_empty(), main.world.mini_tex != null, true, Game.done(Seals.OPEN), Game.prologue == "", true]
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
	elif mode == "load":
		# load.gd: what is on his back, and (at home) the storehouse
		labels = []
		ids = []
		enabled = []
		if Load.at_home(Game, Game.area, main.world.ptile) != "":
			labels.append("The storehouse: leave and take up")
			ids.append("store")
			enabled.append(true)
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "body":
		# needs.gd: survival: the seven needs, and what can be done about them here
		labels = []
		ids = []
		enabled = []
		for a in Needs.actions(Game, main.body_ctx()):
			labels.append(str(a.label))
			ids.append("body:" + str(a.id))
			enabled.append(bool(a.enabled))
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "way" or mode == "almanac" or mode == "wild" or mode == "seals":
		# creed.gd, almanac.gd, wilds.gd: a page to read
		labels = ["Back"]
		ids = ["back"]
		enabled = [true]
	elif mode == "words":
		# memoir.gd: the pages written so far, each read again with Enter
		labels = []
		ids = []
		enabled = []
		for pid in Memoir.book(Game):
			labels.append(str(Memoir.PAGES[pid].n))
			ids.append("page:" + str(pid))
			enabled.append(true)
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "leaves":
		# yezi.gd: the hands he has played, and which painted leaf he brings to a table
		labels = ["Bring no painted leaf"]
		ids = ["leaf:"]
		enabled = [true]
		for pl in Yezi.painted(Game):
			labels.append("Bring %s" % str(Data.ITEMS["leaf_" + str(pl[0])].n))
			ids.append("leaf:" + str(pl[0]))
			enabled.append(true)
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "rites":
		# roots.gd, rites.gd: the root the stone found, and the rite of every Dao that is his
		labels = []
		ids = []
		enabled = []
		for rid in Rites.mine(Game):
			labels.append(str(Rites.RITES[rid].n))
			ids.append("rite:" + str(rid))
			enabled.append(Game.prologue == "" and main.world.using.is_empty() and not main.world.traveling())
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "law":
		# crime.gd, taboo.gd: how he stands with the gates of the land; and the shelf every disciple is told
		# of on the first day
		labels = ["The forbidden shelf", "Back"]
		ids = ["forbidden", "back"]
		enabled = [Game.prologue == "", true]
	elif mode == "land":
		# weal.gd: the towns, each with how it stands (a town of the Far Countries once he has been there)
		labels = []
		ids = []
		enabled = []
		for tid in Weal.towns(Game):
			labels.append("%s  (%s)" % [str(Weal.TOWNS[tid].n).trim_prefix("the "), str(Weal.STATES[Weal.state(Game, tid)].n).to_lower()])
			ids.append("town:" + tid)
			enabled.append(true)
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "feats":
		# feats.gd: every feat by its kind, then the things nobody was told to look for (eggs.gd)
		labels = []
		ids = []
		enabled = []
		for fid in Feats.order():
			var f: Dictionary = Feats.FEATS[fid]
			var has: bool = Game.feats.has(fid)
			labels.append(str(f.n) if has or not bool(f.get("hide", false)) else "? ? ?")
			ids.append("feat:" + fid)
			enabled.append(has)
		for eid in Eggs.ORDER:
			labels.append(Eggs.label(Game, eid))
			ids.append("egg:" + eid)
			enabled.append(Game.eggs.has(eid))
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "songs":
		# music.gd: the songbook; Enter plays the tune under the cursor
		labels = []
		ids = []
		enabled = []
		for tid in Music.book(Game):
			labels.append(Music.label(Game, tid))
			ids.append("song:" + tid)
			enabled.append(Game.heard.has(tid))
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "town":
		# hold.gd: the plots of the town that is the hero's own
		labels = []
		ids = []
		enabled = []
		for pid in Hold.ORDER:
			labels.append(str(Hold.PLOTS[pid].n))
			ids.append("plot:" + pid)
			enabled.append(Hold.built(Game, pid))
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "host":
		# war.gd: the companies of the host
		labels = []
		ids = []
		enabled = []
		for cid in War.ORDER:
			labels.append(War.label(Game, cid))
			ids.append("company:" + cid)
			enabled.append(War.has(Game, cid))
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "fates":
		labels = ["Back"]
		ids = ["back"]
		enabled = [true]
	elif mode == "works":
		# the Hundred Works (works.gd): every work, by school; Enter builds the one under the cursor
		labels = []
		ids = []
		enabled = []
		for wid in Works.ORDER:
			labels.append(Works.label(Game, wid))
			ids.append("work:" + wid)
			enabled.append(Works.has(Game, wid) or Works.known(Game, wid))
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "roads":
		# the crossroads of the road (echoes.gd): every one reached, what was chosen and what came of it
		labels = []
		ids = []
		enabled = []
		for cid in Echoes.ORDER:
			var ch := Echoes.chosen(Game, cid)
			labels.append(("Part %s: %s" % [str(Echoes.CROSSROADS[cid].part), str(Echoes.CROSSROADS[cid].n)]) if ch != "" else "Part %s: ..." % str(Echoes.CROSSROADS[cid].part))
			ids.append("road:" + cid)
			enabled.append(ch != "")
		labels.append("Back")
		ids.append("back")
		enabled.append(true)
	elif mode == "yue":
		# the Lotus release (bonds.gd): a heart-to-heart she is waiting to have can be had from here
		var tid := Bonds.talk_ready(Game)
		# (romance.gd: something to give her, an hour to spend with her, and what there is to say)
		var ask_id := Romance.next_ask(Game)
		var here_n: int = Romance.outings_here(Game, main.body_ctx()).size()
		labels = ["Talk with her (T)" if tid != "" else "Nothing to talk about yet", "Give her something...", "Spend this hour with her (%d here)" % here_n,
			(str(Romance.ASKS[ask_id].n) + "...") if ask_id != "" else "Nothing left unsaid",
			# (the Broken Mirror release: what is the matter, a feast day's hour, and what two people do face to face)
			"Something is the matter..." if Romance.matter(Game) != "" else ("Be near her (%s)..." % Romance.feast_today(Game) if Romance.feast_today(Game) != "" else "Be near her..."), "Back"]
		ids = ["talk", "gift", "outing", "ask", "near", "back"]
		enabled = [tid != "", Game.companion, Game.companion, ask_id != "" and Romance.ask_blocked(Game, ask_id) == "", Game.companion and Romance.stage(Game) >= 1, true]
	elif mode == "cultivation":
		# Part XII: the realm and the branches of the root; an awakening not yet spent can be spent here
		labels = ["Wake a branch (%d)" % Game.talent_pts, "Back"]
		ids = ["wake", "back"]
		enabled = [Game.talent_pts > 0, true]
	elif mode == "map" or mode == "dao" or mode == "journal" or mode == "hearths":
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
			if mode in ["items", "map", "annals", "dao", "cultivation", "journal", "bestiary", "fates", "yue", "hearths", "works", "roads", "feats", "songs", "host", "body", "town", "load", "land", "way", "almanac", "law", "wild", "rites", "words", "seals", "leaves"]:
				mode = "root"
				cursor = 0
				_build()
			else:
				main.pop()
		"confirm":
			if not enabled[cursor]:
				return
			var id: String = ids[cursor]
			if id.begins_with("page:"):
				# (memoir.gd: a page read out again, in its writer's own words)
				main.pop()
				main.say(Memoir.lines(Game, id.trim_prefix("page:")))
				return
			if id.begins_with("leaf:"):
				# (yezi.gd: the painted leaf he brings to a table of leaves, or none)
				Game.leaf = id.trim_prefix("leaf:")
				msg = "He brings %s." % str(Data.ITEMS["leaf_" + Game.leaf].n) if Game.leaf != "" else "He brings no painted leaf."
				return
			if id.begins_with("rite:"):
				# (rites.gd: the rite of a Dao that is his, performed where he stands)
				main.pop()
				main.play_rite(id.trim_prefix("rite:"))
				return
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
				"hearths":
					mode = "hearths"
					cursor = 0
					_build()
				"gift":
					main.pop()
					main.open_gifts()
				"outing":
					main.pop()
					main.open_outings()
				"ask":
					main.pop()
					main.open_ask()
				"near":
					main.pop()
					main.open_near()
				"store":
					main.pop()
					main.offer_store()
				"forbidden":
					main.pop()
					main.open_forbidden()
				"works", "roads", "feats", "songs", "host", "body", "town", "load", "land", "way", "almanac", "law", "wild", "rites", "words", "seals", "leaves":
					mode = id
					cursor = 0
					msg = ""
					_build()
				"yue":
					mode = "yue"
					cursor = 0
					_build()
				"talk":
					main.pop()
					main.talk_yue()
				"arms":
					main.pop()
					main.open_arms()
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
					if mode == "works":
						# build the work under the cursor, if it can be built
						var wid2 := id.trim_prefix("work:")
						if Works.build(Game, wid2):
							msg = "Built: %s." % str(Works.WORKS[wid2].n)
						_build()
						return
					if mode == "body":
						# survival: do what the line under the cursor says (needs.gd)
						msg = Needs.act(Game, id.trim_prefix("body:"), main.body_ctx())
						_build()
						return
					if mode == "songs":
						# the songbook: play the tune under the cursor
						Music.play_from_book(Game, id.trim_prefix("song:"))
						_build()
						return
					if mode == "annals" or mode == "bestiary" or mode == "roads" or mode == "feats" or mode == "host" or mode == "town" or mode == "land":
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
		var ty := 110.0
		if not d.get("boss", false):
			# the hours of the wild (habits.gd): when it is abroad, when it sleeps, what it is doing now
			var hb := Habits.habit(str(e[0]))
			var hl := "%s  Asleep from %s." % [Habits.line(Game, str(e[0])), Habits.sleeps(hb).replace("-", " to ").replace(",", " and from")] if Habits.sleeps(hb) != "never" else Habits.line(Game, str(e[0]))
			UI.text(self, r.position + Vector2(24, 96), hl, UI.fit(hl, 14, r.size.x - 48), Habits.info(Habits.act(Game, str(e[0]))).col, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
			ty = 134.0
		# (the Iron Pestle release, tactics.gd: how it fights)
		var wl := "Fights %s. %s" % [Tactics.word(str(e[0])), Tactics.hint(str(e[0]))]
		UI.text(self, r.position + Vector2(24, ty - 14.0), wl, UI.fit(wl, 14, r.size.x - 48), UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		ty += 24.0
		UI.wrapped(self, r.position + Vector2(24, ty), str(e[2]), 18, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 40), "Every foe has a story. %d of %d met so far; the bosses are marked with a star." % [entries.size(), Data.ENEMIES.size()], 17, UI.C_DIM, r.size.x - 48)

## The Way (creed.gd): where he stands between the Righteous Path and the Demonic, the precepts and the open
## road; what that opens to him and shuts; and everything it was weighed by.
func _draw_way() -> void:
	UI.text(self, Vector2(60, 70), "The Way He Walks", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var w: Dictionary = Creed.way(Game)
	UI.text(self, r.position + Vector2(24, 44), str(w.n), 26, UI.C_GOLD)
	UI.wrapped(self, r.position + Vector2(24, 66), main.told(str(w.desc)), 15, UI.C_TEXT, r.size.x - 48)
	# (the Tall People release, visage.gd: what it has done to his face)
	UI.wrapped(self, Vector2(60, 610), main.told("What people see: " + Visage.text(Game)), 13, UI.C_DIM, 340)
	var y := r.position.y + 128.0
	for axis in Creed.AXES:
		var v := Creed.value(Game, axis)
		var ax: Dictionary = Creed.AXIS[axis]
		var mid := r.position.x + 400.0
		UI.text(self, Vector2(mid - 330.0, y + 12), str(ax.neg), 15, ax.neg_col)
		UI.text(self, Vector2(mid + 232.0, y + 12), str(ax.pos), 15, ax.col)
		UI.panel(self, Rect2(mid - 220.0, y, 440.0, 14.0), Color(0.1, 0.12, 0.18, 0.9), UI.C_BORDER)
		var bw := 220.0 * float(absi(v)) / float(Creed.CAP)
		if v > 0:
			draw_rect(Rect2(mid, y + 2.0, bw, 10.0), ax.col)
		elif v < 0:
			draw_rect(Rect2(mid - bw, y + 2.0, bw, 10.0), ax.neg_col)
		# where a side begins
		for sd in [-1.0, 1.0]:
			draw_rect(Rect2(mid + sd * 220.0 * float(Creed.SIDE) / float(Creed.CAP) - 0.5, y - 2.0, 1.0, 18.0), UI.C_DIM)
		draw_rect(Rect2(mid - 1.0, y - 3.0, 2.0, 20.0), UI.C_TEXT)
		UI.text(self, Vector2(mid - 12.0, y + 32), "%+d" % v, 14, UI.C_DIM)
		y += 46.0
	var dr: Array = Creed.doors(Game)
	var x2 := r.position.x + 24.0 + (r.size.x - 48.0) * 0.5
	UI.text(self, Vector2(r.position.x + 24, y + 8), "What it opens", 16, UI.C_JADE)
	UI.text(self, Vector2(x2, y + 8), "What it shuts", 16, UI.C_RED)
	var ya := y + 14.0
	for ln in dr[0]:
		UI.wrapped(self, Vector2(r.position.x + 24, ya + 14), str(ln), 13, UI.C_TEXT, (r.size.x - 72) * 0.5)
		ya += 17.0 * float(UI.wrap_lines(str(ln), 13, (r.size.x - 72) * 0.5).size()) + 4.0
	var yb := y + 14.0
	for ln2 in dr[1]:
		UI.wrapped(self, Vector2(x2, yb + 14), str(ln2), 13, UI.C_TEXT, (r.size.x - 72) * 0.5)
		yb += 17.0 * float(UI.wrap_lines(str(ln2), 13, (r.size.x - 72) * 0.5).size()) + 4.0
	if (dr[0] as Array).is_empty():
		UI.wrapped(self, Vector2(r.position.x + 24, y + 28), "In the middle of both scales every door is as it was: nothing is shut to him, and no side's art is his.", 13, UI.C_DIM, r.size.x - 48)
		ya = y + 60.0
	y = maxf(ya, yb) + 22.0
	UI.text(self, Vector2(r.position.x + 24, y), "Why", 16, UI.C_GOLD)
	var cs := Creed.causes(Game)
	if cs.is_empty():
		UI.text(self, Vector2(r.position.x + 24, y + 22), "Nothing he has done has weighed either way yet.", 13, UI.C_DIM)
	for i in mini(cs.size(), 9):
		var c: Dictionary = cs[i]
		if y + 22.0 * float(i + 1) > r.end.y - 16.0:
			break
		var ax2: Dictionary = Creed.AXIS[str(c.axis)]
		UI.text(self, Vector2(r.position.x + 24, y + 22.0 * float(i + 1)), "%s %+d" % [str(ax2.pos if int(c.d) > 0 else ax2.neg), absi(int(c.d))], 13, ax2.col if int(c.d) > 0 else ax2.neg_col)
		UI.text(self, Vector2(r.position.x + 170, y + 22.0 * float(i + 1)), str(c.why), 13, UI.C_TEXT)

## Leaves (the Two Roads release, yezi.gd): how the hands have gone, who he has sat down with, the leaves the
## masters painted, and the round of the five phases for whoever has forgotten what overcomes what.
func _draw_leaves() -> void:
	UI.text(self, Vector2(60, 70), "Leaves", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(24, 40), "The table of leaves", 20, UI.C_GOLD)
	UI.wrapped(self, r.position + Vector2(24, 66), main.told(Yezi.summary(Game)), 14, UI.C_TEXT, r.size.x - 48)
	var y := r.position.y + 112.0
	for gid in Yezi.GAME_ORDER:
		UI.text(self, Vector2(r.position.x + 24, y), str(Yezi.GAMES[gid].n), 16, UI.C_JADE)
		y += UI.wrap_lines(str(Yezi.GAMES[gid].desc), 13, r.size.x - 48).size() * 17.0 + 26.0
		UI.wrapped(self, Vector2(r.position.x + 24, y - UI.wrap_lines(str(Yezi.GAMES[gid].desc), 13, r.size.x - 48).size() * 17.0 - 6.0), str(Yezi.GAMES[gid].desc), 13, UI.C_DIM.lightened(0.25), r.size.x - 48)
	y += 8.0
	UI.text(self, Vector2(r.position.x + 24, y), "The masters", 18, UI.C_GOLD)
	for mid in Yezi.MASTER_ORDER:
		y += 30.0
		var mm: Dictionary = Yezi.MASTERS[mid]
		var rec: Dictionary = Game.cards.get(mid, {})
		var has: bool = Game.leaves.has(mid)
		var col: Color = Yezi.COLS[str(mm.leaf)]
		# the leaf they painted: a slip in the colour of its phase, sealed red when it is his
		draw_rect(Rect2(r.position.x + 24, y - 18, 16, 23), Color("efe6cc") if has else Color(0.93, 0.9, 0.82, 0.14))
		draw_rect(Rect2(r.position.x + 27, y - 15, 10, 17), col if has else col.darkened(0.6))
		UI.text(self, Vector2(r.position.x + 52, y), str(mm.n), 15, UI.C_TEXT if not rec.is_empty() else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 300)
		UI.text(self, Vector2(r.position.x + 360, y), str(Yezi.GAMES[str(mm.game)].n), 13, UI.C_DIM)
		UI.text(self, Vector2(r.position.x + 560, y), "%d won, %d lost" % [int(rec.get("won", 0)), int(rec.get("lost", 0))] if not rec.is_empty() else "not yet sat with", 13, UI.C_JADE if int(rec.get("won", 0)) > 0 else UI.C_DIM)
		if str(Game.leaf) == mid:
			UI.text(self, Vector2(r.position.x + 700, y), "brought", 13, UI.C_GOLD)
	UI.wrapped(self, Vector2(r.position.x + 24, r.position.y + r.size.y - 62.0), "A table of leaves is kept at some counters of the towns, and the old hands at every tea-house will play a hand with anybody. Nothing is staked: the loser pours. A painted leaf, won from a master once, takes the place of the least leaf he is dealt.", 13, UI.C_DIM, r.size.x - 48)
	if msg != "":
		UI.text(self, Vector2(60, 700), msg, 14, UI.C_JADE)

## Seals & Lists (the Red Seal release: seals.gd, lists.gd, auction.gd): the paper of every Dao there is, with the
## grade his is sealed at; the three meets and where he came in them; and what he has bought with a hammer.
func _draw_seals() -> void:
	UI.text(self, Vector2(60, 70), "Seals & Lists", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(24, 40), "The papers of the Hall of Seals", 20, UI.C_GOLD)
	UI.text(self, r.position + Vector2(420, 40), "%d of %d held" % [Seals.count(Game), Seals.order().size()], 14, UI.C_DIM)
	var y := r.position.y + 62.0
	var k := 0
	for id in Seals.order():
		var col := float(k % 2)
		var px := r.position.x + 24.0 + 384.0 * col
		var py := y + 30.0 * float(k / 2)
		var gn := Seals.grade_name(Game, id)
		var held := Seals.grade(Game, id) > 0
		# a leaf of paper, and on it a square of red where it is sealed
		draw_rect(Rect2(px, py, 368, 26), Color(0.93, 0.9, 0.82, 0.92 if held else 0.14))
		if held:
			draw_rect(Rect2(px + 336, py + 3, 20, 20), Color("b83a2a"))
			draw_rect(Rect2(px + 340, py + 7, 12, 12), Color(0.93, 0.9, 0.82), false, 1.5)
		var pn := Seals.name_of(id).trim_prefix("Paper of the ").trim_prefix("Abjuration: ")
		UI.text(self, Vector2(px + 8, py + 18), pn, UI.fit(pn, 14, 236, 10), Color("2a2420") if held else UI.C_DIM)
		UI.text(self, Vector2(px + 256, py + 18), gn if gn != "" else ("to be sat" if Seals.due(Game, id) > 0 else "-"), 13, Color("8a2a20") if held else (UI.C_RED if gn == "void" else UI.C_DIM))
		k += 1
	y += 30.0 * float((k + 1) / 2) + 26.0
	UI.text(self, Vector2(r.position.x + 24, y), "The lists", 20, UI.C_GOLD)
	y += 8.0
	for ln in Lists.text(Game).split("\n"):
		y += 21.0
		UI.text(self, Vector2(r.position.x + 24, y), main.told(ln), 14, UI.C_TEXT)
	y += 40.0
	UI.text(self, Vector2(r.position.x + 24, y), "The rooms", 20, UI.C_GOLD)
	UI.wrapped(self, Vector2(r.position.x + 24, y + 24.0), Auction.text(Game), 14, UI.C_TEXT, r.size.x - 48)
	UI.wrapped(self, Vector2(r.position.x + 24, r.position.y + r.size.y - 44.0), "A desk of the Hall, a board of the lists and an auction room are at the counter of whoever answers for a town. The post goes both ways now: letters of his own, parcels home, sealed bids.", 12, UI.C_DIM, r.size.x - 48)

## The Law (crime.gd, taboo.gd): how he stands with the gates of the land, the price on his head town by town,
## what is charged, who is dead by his hand, and how deep he has sat to what the precepts forbid.
func _draw_law() -> void:
	UI.text(self, Vector2(60, 70), "The Law", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var st: Dictionary = Crime.STANDINGS[Crime.worst(Game)]
	var head := str(st.n) if not Taboo.marked(Game) else "A walker of the forbidden"
	UI.text(self, r.position + Vector2(24, 44), head, 26, st.col)
	var sd := str(st.desc) if not Taboo.marked(Game) else "Found out at an art the precepts forbid. His name hangs at every gate with no price on it: the League takes no money. Only the Hall of Discipline, or the enforcers, can take it down."
	if Crime.worst(Game) == 0 and Crime.count(Game) > 0:
		sd = "No bill hangs at any gate. That is not the same thing as a clean name, and he knows it."
	UI.wrapped(self, r.position + Vector2(24, 66), main.told(sd), 15, UI.C_TEXT, r.size.x - 48)
	var y := r.position.y + 122.0
	UI.text(self, Vector2(r.position.x + 24, y), "The price on his head", 16, UI.C_GOLD)
	UI.text(self, Vector2(r.position.x + 420, y), "Dead by his hand", 16, UI.C_GOLD)
	var yy := y + 22.0
	var any := false
	for tid in Weal.ORDER:
		if Crime.price(Game, tid) > 0:
			any = true
			UI.text(self, Vector2(r.position.x + 24, yy), str(Weal.TOWNS[tid].n).trim_prefix("the "), 14, UI.C_TEXT)
			UI.text(self, Vector2(r.position.x + 250, yy), "%d" % Crime.price(Game, tid), 14, UI.C_RED)
			yy += 19.0
	if not any:
		UI.text(self, Vector2(r.position.x + 24, yy), "None, in any town.", 14, UI.C_DIM)
		yy += 19.0
	else:
		UI.text(self, Vector2(r.position.x + 24, yy + 2.0), "The watch takes it in the town's own streets:", 12, UI.C_DIM)
		UI.text(self, Vector2(r.position.x + 24, yy + 17.0), "in stones, or in days in the circle (%d for all of it)." % Crime.days_for(Game, Crime.heat(Game)), 12, UI.C_DIM)
		yy += 36.0
	var yd := y + 22.0
	var shown := 0
	for id in Game.slain:
		# (somebody the story stands in several places is one person, and is listed once)
		if Game.slain[id].has("alias"):
			continue
		if shown >= 7:
			UI.text(self, Vector2(r.position.x + 420, yd), "and %d more" % (Game.slain.values().filter(func(x): return not x.has("alias")).size() - shown), 13, UI.C_DIM)
			yd += 19.0
			break
		var rec: Dictionary = Game.slain[id]
		UI.text(self, Vector2(r.position.x + 420, yd), str(rec.n), UI.fit(str(rec.n), 14, 250.0), UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 250.0)
		UI.text(self, Vector2(r.position.x + 680, yd), "seen" if bool(rec.seen) else "unseen", 13, UI.C_RED if bool(rec.seen) else UI.C_DIM)
		yd += 19.0
		shown += 1
	if Game.slain.is_empty() and int(Game.watch_slain) > 0:
		UI.text(self, Vector2(r.position.x + 420, yd), "%d of the watch." % int(Game.watch_slain), 14, UI.C_TEXT)
		yd += 19.0
	elif Game.slain.is_empty():
		UI.text(self, Vector2(r.position.x + 420, yd), "Nobody.", 14, UI.C_DIM)
		yd += 19.0
	y = maxf(yy, yd) + 14.0
	UI.text(self, Vector2(r.position.x + 24, y), "What the gates charge him with", 16, UI.C_GOLD)
	y += 4.0
	if Game.crimes.is_empty():
		UI.text(self, Vector2(r.position.x + 24, y + 18.0), "Nothing.", 14, UI.C_DIM)
		y += 19.0
	var from := maxi(0, Game.crimes.size() - 5)
	for i in range(Game.crimes.size() - 1, from - 1, -1):
		var c: Dictionary = Game.crimes[i]
		y += 19.0
		var bill := str(Crime.CRIMES[str(c.what)].bill) % str(c.who)
		var ln := "Day %d, %s: %s" % [int(c.day), str(Weal.TOWNS[str(c.town)].n).trim_prefix("the "), bill]
		UI.text(self, Vector2(r.position.x + 24, y), main.told(ln), UI.fit(ln, 13, r.size.x - 150.0), UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 150.0)
		UI.text(self, Vector2(r.position.x + r.size.x - 110.0, y), ("%d" % int(c.n)) if int(c.n) > 0 else "no bill", 13, UI.C_RED if int(c.n) > 0 else UI.C_DIM)
	y += 34.0
	UI.text(self, Vector2(r.position.x + 24, y), "The forbidden shelf", 16, Color("b05ad0"))
	UI.text(self, Vector2(r.position.x + 220, y), "(%s)" % Taboo.text(Game), 13, UI.C_DIM)
	for id in Taboo.ORDER:
		y += 21.0
		var d: Dictionary = Taboo.DAOS[id]
		var dp := Taboo.depth(Game, id)
		UI.text(self, Vector2(r.position.x + 24, y), str(d.n), 14, d.col if dp > 0 else UI.C_DIM)
		for k in Taboo.MAX:
			draw_rect(Rect2(r.position.x + 300.0 + 16.0 * float(k), y - 10.0, 12.0, 10.0), d.col if k < dp else Color(0.16, 0.16, 0.2))
		UI.text(self, Vector2(r.position.x + 460, y), str(d.what), UI.fit(str(d.what), 12, 320.0), UI.C_TEXT if dp > 0 else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 320.0)
	y += 24.0
	UI.wrapped(self, Vector2(r.position.x + 24, y), main.told("Every disciple is taught the three names on the first day, so that he knows what not to do. Anybody in sight when he sits to one has seen it; past %d steps in all, anybody of cultivation he speaks to can smell it on him." % Taboo.SENSE), 12, UI.C_DIM, r.size.x - 48)

## In Their Own Words (memoir.gd): the pages the three people of the story have written of it, in the first
## person; the one under the cursor is shown, and Enter has it read out.
func _draw_words() -> void:
	UI.text(self, Vector2(60, 70), "In Their Own Words", 22, UI.C_GOLD)
	var rows := 26
	var from := clampi(cursor - rows / 2, 0, maxi(0, labels.size() - rows))
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels.slice(from, from + rows), cursor - from, enabled.slice(from, from + rows), 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var id: String = ids[cursor] if cursor < ids.size() else "back"
	if not id.begins_with("page:"):
		UI.wrapped(self, r.position + Vector2(24, 44), "%d of %d pages written. A page is written when the thing it tells of is over, by whoever has something to say about it; some are only written by a journey that went a certain way." % [Game.pages.size(), Memoir.ORDER.size()], 15, UI.C_DIM, r.size.x - 48)
		return
	var pid := id.trim_prefix("page:")
	var pg: Dictionary = Memoir.PAGES[pid]
	var cols := {"lin": Color("7ec8ff"), "yue": Color("ff9ac0"), "elder": UI.C_GOLD}
	UI.text(self, r.position + Vector2(24, 44), str(pg.n), 24, UI.C_GOLD)
	UI.text(self, r.position + Vector2(24, 70), "%s, day %d" % [main.told(Memoir.by(pid)), int(Game.pages.get(pid, 1))], 14, cols[str(pg.who)])
	var y := r.position.y + 104.0
	for ln in pg.lines:
		UI.wrapped(self, Vector2(r.position.x + 24, y), str(ln), 16, UI.C_TEXT, r.size.x - 48)
		y += 23.0 * UI.wrap_lines(str(ln), 16, r.size.x - 48).size() + 16.0
	UI.text(self, Vector2(r.position.x + 24, r.position.y + r.size.y - 20), "Enter: have it read out", 13, UI.C_DIM)

## Root & Rites (roots.gd, rites.gd): what the testing stone found in him, and the seventeen Daos of the land
## with the rite of each that is his (Enter performs one where he stands).
func _draw_rites() -> void:
	UI.text(self, Vector2(60, 70), "Root & Rites", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var kd: Dictionary = Roots.KINDS[Roots.count(Game)]
	UI.text(self, r.position + Vector2(24, 44), main.told(Roots.title(Game)), 24, kd.col)
	# the five phases round the generating order: lit if they are in him
	for i in Roots.ELEMS.size():
		var el := str(Roots.ELEMS[i])
		var c: Color = Data.ELEM_COLORS[el]
		var on := Roots.has(Game, el)
		var cx := r.position.x + 530.0 + 52.0 * i
		draw_circle(Vector2(cx, r.position.y + 36.0), 13.0, c if on else Color(c.r, c.g, c.b, 0.14))
		draw_arc(Vector2(cx, r.position.y + 36.0), 13.0, 0.0, TAU, 20, UI.C_BORDER, 1.0)
		UI.text(self, Vector2(cx - 26.0, r.position.y + 66.0), str(Roots.ELEM_N[el]), 11, UI.C_TEXT if on else UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 52.0)
	UI.wrapped(self, r.position + Vector2(24, 96), main.told(Roots.text(Game)), 14, UI.C_TEXT, r.size.x - 48)
	var y := r.position.y + 226.0
	UI.text(self, Vector2(r.position.x + 24, y), "The rites of the Daos", 20, UI.C_GOLD)
	UI.text(self, Vector2(r.position.x + 420, y), Rites.text(Game), 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 444)
	y += 12.0
	for rid in Rites.ORDER:
		var rt: Dictionary = Rites.RITES[rid]
		var mine: bool = Rites.his(Game, str(rid))
		var times := int(Game.rites.get(rid, 0))
		y += 19.0
		draw_rect(Rect2(r.position.x + 24, y - 11.0, 8.0, 8.0), Rites.colour(str(rid)) if mine else Color(0.3, 0.32, 0.38))
		var shut: bool = str(rt.kind) == "taboo" and not mine
		UI.text(self, Vector2(r.position.x + 40, y), "A forbidden Dao" if shut else Rites.dao_name(str(rid)), 14, UI.C_TEXT if mine else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 300.0)
		UI.text(self, Vector2(r.position.x + 350, y), str(rt.n) if mine else ("" if shut else "not yet his"), 14, UI.C_GOLD if times > 0 else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 300.0)
		if times > 0:
			UI.text(self, Vector2(r.position.x + 660, y), "performed%s" % ("" if times == 1 else " %d times" % times), 13, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 120.0)

## The Wild (wilds.gd): how the countries he has hunted in stand, and what that is doing to the towns.
func _draw_wild() -> void:
	UI.text(self, Vector2(60, 70), "The Wild", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(24, 44), "The balance of the wild", 24, UI.C_GOLD)
	UI.wrapped(self, r.position + Vector2(24, 66), main.told("Every country has beasts of its own, and bears so much hunting and no more. What he takes too fast does not come back: the packs thin, the crows and the rats come in behind them, and the towns that hear of it have less in the pot. Left alone, the strain eases by half every %d days; a hunter of the camps can be paid to open three sides of his net." % int(Wilds.HALF)), 14, UI.C_TEXT, r.size.x - 48)
	var y := r.position.y + 150.0
	var rows: Array = []
	for a in Game.cull:
		rows.append([Wilds.strain(Game, str(a)), str(a)])
	rows.sort_custom(func(x, z): return float(x[0]) > float(z[0]))
	if rows.is_empty():
		UI.wrapped(self, Vector2(r.position.x + 24, y), "Nothing he has hunted has been missed yet. The wild stands as it was made.", 15, UI.C_DIM, r.size.x - 48)
		return
	UI.text(self, Vector2(r.position.x + 24, y), "Country", 14, UI.C_DIM)
	UI.text(self, Vector2(r.position.x + 330, y), "Strain", 14, UI.C_DIM)
	UI.text(self, Vector2(r.position.x + 560, y), "How it stands", 14, UI.C_DIM)
	for i in mini(rows.size(), 12):
		var a2 := str(rows[i][1])
		var s2 := float(rows[i][0])
		var st := Wilds.state_of(s2)
		var inf: Dictionary = Wilds.STATES[st]
		y += 26.0
		UI.text(self, Vector2(r.position.x + 24, y), str(Data.AREAS[a2].n), UI.fit(str(Data.AREAS[a2].n), 15, 290.0), UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 290.0)
		UI.panel(self, Rect2(r.position.x + 330, y - 12.0, 200.0, 12.0), Color(0.1, 0.12, 0.18, 0.9), UI.C_BORDER)
		draw_rect(Rect2(r.position.x + 332, y - 10.0, 196.0 * clampf(s2 / 6.0, 0.0, 1.0), 8.0), inf.col)
		for k in Wilds.AT:
			draw_rect(Rect2(r.position.x + 332 + 196.0 * float(k) / 6.0, y - 14.0, 1.0, 16.0), UI.C_DIM)
		UI.text(self, Vector2(r.position.x + 560, y), str(inf.n), 15, inf.col)
	var worst := 0
	var wa := ""
	for rw in rows:
		if Wilds.state_of(float(rw[0])) > worst:
			worst = Wilds.state_of(float(rw[0]))
			wa = str(rw[1])
	if worst > 0:
		UI.wrapped(self, Vector2(r.position.x + 24, r.end.y - 70.0), main.told("%s: %s" % [str(Data.AREAS[wa].n), str(Wilds.STATES[worst].desc)]), 14, Wilds.STATES[worst].col, r.size.x - 48)

## The Almanac (almanac.gd): the day of the year, the feast that is coming, the Roll of the Outer Court as it
## stands this morning, and how the wild of the regions he knows has grown while he was elsewhere.
func _draw_almanac() -> void:
	UI.text(self, Vector2(60, 70), "The Almanac", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(24, 42), "The %s" % Almanac.short(Game), 24, UI.C_GOLD)
	UI.text(self, r.position + Vector2(24, 66), "Year of the %s  ·  %s  ·  %s  ·  day %d of the journey" % [Almanac.year_name(Game), Almanac.season(Game), Almanac.term(Game), Game.day], 14, UI.C_TEXT)
	var fs := Almanac.festival(Game)
	var nf := Almanac.next_festival(Game)
	UI.text(self, r.position + Vector2(24, 90), ("Today is %s." % str(fs[2])) if not fs.is_empty() else ("Next: %s, in %d day%s." % [str(nf[0]), int(nf[1]), "" if int(nf[1]) == 1 else "s"]), 14, UI.C_JADE)
	var y := r.position.y + 124.0
	UI.text(self, Vector2(r.position.x + 24, y), "The Roll of the Outer Court", 17, UI.C_GOLD)
	UI.text(self, Vector2(r.position.x + 420, y), "stipend on the first of the month: %d" % Almanac.stipend(Game), 13, UI.C_DIM)
	var rl := Almanac.roll(Game)
	for i in rl.size():
		var e: Dictionary = rl[i]
		var yy := y + 22.0 * float(i + 1)
		var col: Color = UI.C_GOLD if bool(e.hero) else UI.C_TEXT
		UI.text(self, Vector2(r.position.x + 24, yy), "%d" % (i + 1), 14, UI.C_DIM)
		UI.text(self, Vector2(r.position.x + 48, yy), main.told(str(e.n)), 14, col)
		UI.text(self, Vector2(r.position.x + 270, yy), Data.level_name(int(e.lv)), 13, col)
		UI.text(self, Vector2(r.position.x + 500, yy), str(e.word), 11, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 520)
	y += 22.0 * float(rl.size() + 1) + 14.0
	UI.text(self, Vector2(r.position.x + 24, y), "The wild", 17, UI.C_GOLD)
	UI.text(self, Vector2(r.position.x + 120, y), "a pack left alone settles in a day, breeds in two and a half, and is old in five", 13, UI.C_DIM)
	var wd: Dictionary = Atlas.world_of(Game.layer)
	var shown := 0
	for aid in Atlas.region_ids(Game.layer):
		if not Game.seen.has(aid) or shown >= 12:
			continue
		var wv: Array = Almanac.wild(Game, wd, str(aid))
		var st := int(wv[0])
		var cx := r.position.x + 24.0 + 260.0 * float(shown % 3)
		var cy := y + 22.0 * float(shown / 3 + 1)
		UI.text(self, Vector2(cx, cy), str(Data.AREAS[aid].n).split(",")[0].left(22), 13, UI.C_TEXT)
		UI.text(self, Vector2(cx + 170, cy), str(Almanac.WILD_WORDS[st]), 13, Almanac.STAGES[st].col)
		shown += 1

## The Land (weal.gd): how each town stands, its three measures, and everything he chose or did that it felt.
func _draw_land() -> void:
	UI.text(self, Vector2(60, 70), "The Land", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	UI.wrapped(self, r.position + Vector2(24, 36), main.told(Weal.summary(Game) + " What he chose at the crossroads and did in their streets is weighed town by town: plenty, peace, and what they think of him."), 14, UI.C_DIM.lightened(0.3), r.size.x - 48)
	var id := str(ids[clampi(cursor, 0, ids.size() - 1)])
	if not id.begins_with("town:"):
		return
	var tid := id.trim_prefix("town:")
	var st := Weal.state(Game, tid)
	var col: Color = Weal.STATES[st].col
	UI.text(self, r.position + Vector2(24, 104), str(Weal.TOWNS[tid].n).trim_prefix("the "), 24, UI.C_GOLD)
	UI.text(self, r.position + Vector2(420, 102), str(Weal.STATES[st].n), 22, col)
	UI.wrapped(self, r.position + Vector2(24, 126), str(Weal.STATES[st].desc), 15, UI.C_TEXT, r.size.x - 48)
	var y := r.position.y + 196.0
	for m in Weal.MEASURES:
		var v := Weal.measure(Game, tid, m)
		UI.text(self, Vector2(r.position.x + 24, y + 12), str(Weal.MEASURE_NAMES[m]), 16, UI.C_TEXT)
		# a bar from the middle: to the right what is good, to the left what is not
		var mid := r.position.x + 330.0
		UI.panel(self, Rect2(mid - 180.0, y, 360.0, 14.0), Color(0.1, 0.12, 0.18, 0.9), UI.C_BORDER)
		var w := 180.0 * float(absi(v)) / float(Weal.CAP)
		if v > 0:
			draw_rect(Rect2(mid, y + 2.0, w, 10.0), UI.C_JADE)
		elif v < 0:
			draw_rect(Rect2(mid - w, y + 2.0, w, 10.0), UI.C_RED)
		draw_rect(Rect2(mid - 1.0, y - 2.0, 2.0, 18.0), UI.C_DIM)
		UI.text(self, Vector2(mid + 200.0, y + 12), "%+d" % v, 16, UI.C_JADE if v > 0 else (UI.C_RED if v < 0 else UI.C_DIM))
		y += 30.0
	y += 14.0
	UI.text(self, Vector2(r.position.x + 24, y), "Why", 17, UI.C_GOLD)
	y += 8.0
	var cs := Weal.causes(Game, tid)
	if cs.is_empty():
		UI.wrapped(self, Vector2(r.position.x + 24, y + 18.0), "Nothing he has done has reached here yet.", 14, UI.C_DIM, r.size.x - 48)
	for i in mini(cs.size(), 8):
		var c: Dictionary = cs[i]
		var good: bool = int(c.d) > 0
		UI.text(self, Vector2(r.position.x + 24, y + 20.0), "%s %+d" % [str(Weal.MEASURE_NAMES[str(c.m)]).to_lower(), int(c.d)], 14, UI.C_JADE if good else UI.C_RED)
		UI.text(self, Vector2(r.position.x + 130, y + 20.0), main.told(str(c.why)), 14, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 160)
		y += 24.0
	if cs.size() > 8:
		UI.text(self, Vector2(r.position.x + 24, y + 20.0), "and %d things more" % (cs.size() - 8), 13, UI.C_DIM)
	UI.wrapped(self, Vector2(r.position.x + 24, r.end.y - 44.0), "Whoever answers for a town will tell you how it stands, and its chest takes gifts. A shift worked, the post carried, an errand run and a road cleared are all felt; so is a jar broken and not paid for.", 13, UI.C_DIM, r.size.x - 48)

## The Load (load.gd): what is on his back in jin, how much of what he can bear it is and what that
## costs, what he bears it with, and how far he has carried things.
func _draw_load() -> void:
	UI.text(self, Vector2(60, 70), "The Load", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var riding: bool = main.world.riding_here()
	var tier := Load.tier(Game, riding)
	var tcol: Color = [UI.C_JADE, UI.C_GOLD, UI.C_RED.lightened(0.3), UI.C_RED][tier]
	UI.text(self, r.position + Vector2(24, 40), "%d of %d jin" % [int(round(Load.weight(Game))), int(round(Load.cap(Game, riding)))], 24, tcol)
	UI.bar(self, Rect2(r.position.x + 250, r.position.y + 22, 380, 14), clampf(Load.ratio(Game, riding) / 1.6, 0.0, 1.0), tcol)
	UI.text(self, r.position + Vector2(650, 38), str(Load.TIERS[tier]), 17, tcol)
	UI.wrapped(self, r.position + Vector2(24, 62), main.told(str(Load.TIER_TEXT[tier]) if int(Game.inv.get(Load.RING, 0)) <= 0 else Load.text(Game)), 15, UI.C_DIM.lightened(0.3), r.size.x - 48)
	var with: Array = ["his own back (%d jin, and %d more for every great realm)" % [int(Load.BASE), int(Load.PER_REALM)]]
	if Game.companion:
		with.append("Yue Ling's share")
	if int(Game.inv.get(Load.FRAME_ITEM, 0)) > 0:
		with.append("a pack-frame")
	if riding:
		with.append(str(Fashion.RIDES[Game.ride].n))
	if int(Game.inv.get(Load.POUCH, 0)) > 0:
		with.append("a pouch of heaven and earth")
	UI.wrapped(self, r.position + Vector2(24, 100), main.told("Borne with: " + ", ".join(with) + "."), 14, UI.C_TEXT, r.size.x - 48)
	var y := r.position.y + 158.0
	var rows := Load.rows(Game)
	for i in mini(rows.size(), 14):
		var row: Array = rows[i]
		UI.text(self, Vector2(r.position.x + 24, y), "%s x%d" % [str(row[0]), int(row[1])], 15, UI.C_TEXT)
		UI.text(self, Vector2(r.position.x + 520, y), ("%.1f jin" % float(row[2])) if float(row[2]) < 10.0 else ("%d jin" % int(round(float(row[2])))), 15, UI.C_GOLD if float(row[2]) >= 20.0 else UI.C_DIM.lightened(0.3))
		y += 22.0
	if rows.size() > 14:
		UI.text(self, Vector2(r.position.x + 24, y), "and %d lighter things" % (rows.size() - 14), 14, UI.C_DIM)
		y += 22.0
	var st := 0.0
	for sid in Game.stash:
		st += Load.weight_of(str(sid)) * float(Game.stash[sid])
	UI.wrapped(self, Vector2(r.position.x + 24, r.end.y - 118), "Carried a league on your own back: %d jin.   Left in the storehouse: %d jin.   Sold to the pedlars: %d pieces." % [Load.hauled(Game), int(round(st)), int(Game.sold)], 14, UI.C_JADE, r.size.x - 48)
	UI.wrapped(self, Vector2(r.position.x + 24, r.end.y - 84), "C works the land in front of you: an axe to a tree, a rod to water, a pick to a crag or a cave wall, a sickle to open ground. Things can be left at the sect and at Guiyun. A horse bears 160 jin while you ride it and a carriage 600; a flying sword lifts no more than you can.", 13, UI.C_DIM.lightened(0.2), r.size.x - 48)

## The Body (needs.gd): survival, on or off; the seven needs as bars; what low ones cost and what
## can be done about each here.
func _draw_body() -> void:
	UI.text(self, Vector2(60, 70), "The Body", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 16)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	if not Needs.on(Game):
		UI.text(self, r.position + Vector2(24, 44), "Survival is off", 24, UI.C_DIM)
		UI.wrapped(self, r.position + Vector2(24, 84), "The story as it was first told asks nothing of the stomach. Turned on, Lin Feng and Yue Ling have seven needs that run down by the clock of the land: rest, hunger, thirst, bladder, bowels, comfort and cleanliness. A bed, a meal, a well, a tree to step behind, a fire, a bath. A need that is low costs something in battle; one that reaches nothing takes matters into its own hands. Nobody dies of it, and a cultivator needs less with every realm. It can be turned off again at any time.", 17, UI.C_TEXT, r.size.x - 48)
		return
	UI.text(self, r.position + Vector2(24, 40), "Day %d      %s" % [Game.day, Clock.text(Game)], 15, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	var y := r.position.y + 76.0
	for k in Needs.ORDER:
		var v := Needs.value(Game, k)
		var nd: Dictionary = Needs.NEEDS[k]
		UI.text(self, Vector2(r.position.x + 24, y + 4), str(nd.n), 17, UI.C_TEXT if v >= Needs.LOW else UI.C_RED.lightened(0.3))
		UI.bar(self, Rect2(r.position.x + 170, y - 9, 380, 12), v / 100.0, nd.col if v >= Needs.LOW else UI.C_RED)
		UI.text(self, Vector2(r.position.x + 566, y + 4), "%d   %s" % [int(round(v)), str(nd.low) if v < Needs.LOW else str(nd.ok)], 15, UI.C_DIM.lightened(0.3) if v >= Needs.LOW else UI.C_RED.lightened(0.3))
		y += 34.0
	UI.text(self, Vector2(r.position.x + 24, y + 12), "The body is %s." % Needs.state(Game), 16, UI.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	UI.text(self, Vector2(r.position.x + 24, y + 36), "A cultivator of this realm needs %d%% of what a mortal does." % int(round(Needs.pace(Game) * 100.0)), 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	var low := Needs.lowest(Game)
	if Game.companion and Needs.value(Game, low) < 45.0:
		UI.wrapped(self, Vector2(r.position.x + 24, y + 70), "Yue Ling: \"%s\"" % str(Needs.YUE_LOW[low]), 16, Color("ff9ac0"), r.size.x - 48)
	# why the line under the cursor cannot be done, or what was just done
	var acts := Needs.actions(Game, main.body_ctx())
	if cursor < acts.size() and not bool(acts[cursor].enabled):
		UI.wrapped(self, Vector2(r.position.x + 24, r.end.y - 96), str(acts[cursor].why), 15, UI.C_DIM.lightened(0.2), r.size.x - 48)
	if msg != "":
		UI.wrapped(self, Vector2(r.position.x + 24, r.end.y - 52), UI.named(msg), 16, UI.C_JADE, r.size.x - 48)

## The Feats page (feats.gd, eggs.gd): what the journey is remembered for, by kind, how far along each
## is, and under them the things nobody was told to look for.
func _draw_feats() -> void:
	UI.text(self, Vector2(60, 70), "Feats", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 15)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var pts := Feats.points(Game)
	UI.text(self, r.position + Vector2(24, 36), "%s      %d of %d feats      %d of %d points      %d of %d found unasked" % [Feats.title(Game), Game.feats.size(), Feats.FEATS.size(), pts, Feats.total(), Game.eggs.size(), Eggs.ORDER.size()],
		15, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	UI.bar(self, Rect2(r.position + Vector2(24, 48), Vector2(r.size.x - 48, 8)), float(pts) / float(Feats.total()), UI.C_GOLD)
	# the kinds, and how many of each are done
	var kx := 0
	for kd in Feats.KIND_ORDER:
		var have := 0
		var of := 0
		for fid in Feats.FEATS:
			if str(Feats.FEATS[fid].kind) == kd:
				of += 1
				have += 1 if Game.feats.has(fid) else 0
		UI.text(self, r.position + Vector2(24 + (kx % 5) * 152, 84 + int(kx / 5) * 22), "%s %d/%d" % [str(Feats.KINDS[kd].n), have, of], 13, Feats.KINDS[kd].col, HORIZONTAL_ALIGNMENT_LEFT, 150)
		kx += 1
	var order := Feats.order()
	if cursor < order.size():
		var fid2: String = order[cursor]
		var f: Dictionary = Feats.FEATS[fid2]
		var has: bool = Game.feats.has(fid2)
		UI.text(self, r.position + Vector2(24, 170), str(f.n) if has or not bool(f.get("hide", false)) else "? ? ?", 26, UI.C_GOLD if has else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		UI.text(self, r.position + Vector2(24, 196), str(Feats.KINDS[str(f.kind)].n), 15, Feats.KINDS[str(f.kind)].col)
		UI.wrapped(self, r.position + Vector2(24, 236), Feats.text(Game, fid2), 18, UI.C_TEXT, r.size.x - 48)
		var t2: Array = f.test
		if not has and not bool(f.get("hide", false)) and not str(t2[0]) in ["step", "war_swift"]:
			UI.bar(self, Rect2(r.position + Vector2(24, 400), Vector2(r.size.x - 48, 10)), clampf(Feats.value(Game, t2) / maxf(1.0, Feats.need(t2)), 0.0, 1.0), Feats.KINDS[str(f.kind)].col)
	elif cursor < order.size() + Eggs.ORDER.size():
		var eid: String = Eggs.ORDER[cursor - order.size()]
		var got: bool = Game.eggs.has(eid)
		UI.text(self, r.position + Vector2(24, 170), str(Eggs.EGGS[eid].n) if got else "? ? ?", 26, UI.C_GOLD if got else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		UI.text(self, r.position + Vector2(24, 196), "The Unasked: something nobody told you to look for", 15, Feats.KINDS.odd.col)
		var words: Array = []
		if got:
			for l in Eggs.EGGS[eid].lines:
				if str(l[0]) == "Narrator":
					words.append(str(l[1]))
			words.append("Found at %s of the journey." % Fmt.clock(float(Game.eggs[eid])))
		else:
			words.append(str(Eggs.EGGS[eid].hint))
		UI.wrapped(self, r.position + Vector2(24, 236), UI.named("\n\n".join(words)), 17, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 190), "Nobody asks for a feat, and no step of the story waits on one. Each is told the moment it is true and kept here. A few are not shown until they are done; twelve things are not feats at all, only found.", 17, UI.C_DIM, r.size.x - 48)

## The songbook (music.gd): every tune heard, what it is played on and where, and its notes as a roll
## (time across, pitch up, a colour for each voice).  Enter plays the tune under the cursor.
func _draw_songs() -> void:
	UI.text(self, Vector2(60, 70), "Songs", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 15)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var book := Music.book(Game)
	UI.text(self, r.position + Vector2(24, 36), "%d of %d tunes heard      %d of 6 airs of the hearths learned" % [Game.heard.size(), Music.count(), Game.airs.size()], 15, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	if cursor >= book.size():
		UI.wrapped(self, r.position + Vector2(24, 90), "Every tune of the land is written in this book as it is heard, in the numbered notes the land has always used: one to six, a dash to hold, a line under to hurry. Nothing in it was recorded. Each is played from its notes, on instruments made of arithmetic. Enter plays the tune under the cursor.", 17, UI.C_DIM, r.size.x - 48)
		return
	var tid: String = book[cursor]
	var tn: Dictionary = Music.TUNES[tid]
	if not Game.heard.has(tid):
		UI.text(self, r.position + Vector2(24, 90), "Not yet heard", 26, UI.C_DIM)
		UI.wrapped(self, r.position + Vector2(24, 130), str(tn.where), 17, UI.C_DIM, r.size.x - 48)
		return
	UI.text(self, r.position + Vector2(24, 90), str(tn.n), 26, UI.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	var playing: bool = Music.asked() == tid
	UI.text(self, r.position + Vector2(24, 116), "%s      %d beats a minute, %d s      %s" % [Music.instruments(tid), int(tn.bpm), int(Music.seconds(tid)), "playing" if playing else ("the air of %s" % str(Cultures.HEARTHS[str(tn.air)].n) if tn.has("air") else "")],
		14, UI.C_JADE if playing else Color("c8a0e8"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	UI.wrapped(self, r.position + Vector2(24, 150), str(tn.desc), 17, UI.C_TEXT, r.size.x - 48)
	UI.text(self, r.position + Vector2(24, 300), str(tn.where), 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	# the roll
	var rr := Rect2(r.position + Vector2(24, 320), Vector2(r.size.x - 48, 230))
	draw_rect(rr, Color(0, 0, 0, 0.35))
	var notes := Music.roll(tid)
	var total := Music.beats(tid)
	var lo := 200
	var hi := 0
	for n in notes:
		lo = mini(lo, int(n[2]))
		hi = maxi(hi, int(n[2]))
	var span := maxf(12.0, float(hi - lo + 1))
	for bar in range(0, int(total) + 1, 4):
		draw_rect(Rect2(rr.position + Vector2(bar / total * rr.size.x, 0), Vector2(1, rr.size.y)), Color(1, 1, 1, 0.07))
	var cols := [Color("f0c850"), Color("7ad8a0"), Color("8ac0e8"), Color("e86a9a"), Color("c8a0e8")]
	for n2 in notes:
		var x := rr.position.x + float(n2[0]) / total * rr.size.x
		var w := maxf(2.0, float(n2[1]) / total * rr.size.x - 1.0)
		var y := rr.end.y - (float(int(n2[2]) - lo) + 0.5) / span * rr.size.y
		draw_rect(Rect2(Vector2(x, y - 2.5), Vector2(w, 5.0)), cols[int(n2[3]) % cols.size()])
	if playing:
		var px := fposmod(t * float(tn.bpm) / 60.0, total) / total * rr.size.x
		draw_rect(Rect2(rr.position + Vector2(px, 0), Vector2(2, rr.size.y)), Color(1, 1, 1, 0.5))
	# the first bars as they are written
	var first := str(tn.voices[0][3]).split("|")
	var written := " | ".join(Array(first).slice(0, 4).map(func(x): return str(x).strip_edges()))
	UI.text(self, r.position + Vector2(24, 574), written, UI.fit(written, 15, r.size.x - 48), UI.C_DIM.lightened(0.3), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	UI.text(self, Vector2(r.end.x - 260, r.end.y - 16), "Enter: play   Esc: back", 13, UI.C_DIM)

## The Host (war.gd): the companies that have come in, by arm, what each is, the airs it can sound, and
## the fields held.
func _draw_host() -> void:
	UI.text(self, Vector2(60, 70), "The Host", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 15)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	var m := War.muster(Game)
	UI.text(self, r.position + Vector2(24, 36), "%d companies      Foot %d   Bows %d   Horse %d   Drums %d      %d airs to sound" % [War.companies(Game).size(), int(m.foot), int(m.bow), int(m.horse), int(m.drum), Game.airs.size()],
		15, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	if cursor < War.ORDER.size():
		var cid: String = War.ORDER[cursor]
		var c: Dictionary = War.COMPANIES[cid]
		var has: bool = War.has(Game, cid)
		draw_rect(Rect2(r.position + Vector2(24, 70), Vector2(8, 40)), c.col if has else UI.C_DIM)
		UI.text(self, r.position + Vector2(44, 100), str(c.n) if has else "Not yet in the host", 24, UI.C_GOLD if has else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 68)
		UI.wrapped(self, r.position + Vector2(24, 140), War.text(Game, cid), 18, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 100), "A host is raised, not hired: a company from every hearth that is asked, the sect's own, and what the works put in the field. Foot hold and go in, bows shoot, horse charge, and the drums sound the airs of the land, which strike at nothing but the heart. A field battle is fought by drums, a dozen at most, one order to a drum.", 17, UI.C_DIM, r.size.x - 48)
	# the fields held
	var y := r.end.y - 150.0
	UI.text(self, Vector2(r.position.x + 24, y), "Fields held: %d of %d      driven off: %d" % [Game.war_won.size(), War.BATTLE_ORDER.size(), Game.war_lost], 16, UI.C_GOLD)
	y += 22.0
	for bid in War.BATTLE_ORDER:
		var won: bool = Game.war_won.has(bid)
		UI.text(self, Vector2(r.position.x + 24, y), "%s%s" % [str(War.BATTLES[bid].n), ", in %d drums" % int(Game.war_won[bid]) if won else ""], 14, UI.C_JADE if won else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		y += 19.0

## The Town page (hold.gd, the Three Burrows release): the town that is the hero's own: its households,
## its dues, its power, and each plot: what stands, and what is only drawn up.
func _draw_town() -> void:
	UI.text(self, Vector2(60, 70), "The Town", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 15)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	if not Hold.founded(Game):
		UI.wrapped(self, r.position + Vector2(24, 100), Hold.text(Game), 18, UI.C_TEXT, r.size.x - 48)
		return
	UI.text(self, r.position + Vector2(24, 36), Hold.summary(Game), 15, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	if cursor < Hold.ORDER.size():
		var pid: String = Hold.ORDER[cursor]
		var p: Dictionary = Hold.PLOTS[pid]
		var has: bool = Hold.built(Game, pid)
		draw_rect(Rect2(r.position + Vector2(24, 70), Vector2(8, 40)), UI.C_GOLD if has else UI.C_DIM)
		UI.text(self, r.position + Vector2(44, 100), str(p.n), 24, UI.C_GOLD if has else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 68)
		var why := Hold.blocked(Game, pid)
		UI.wrapped(self, r.position + Vector2(24, 140), (str(p.desc) if has else "Drawn up, not built: %d spirit stones, at the steward's table.%s\n\n\"%s\"" % [Hold.cost(Game, pid), "" if why == "" else "  " + why, str(p.ask)])
			+ "\n\nIt brings %d households, and makes room for %d." % [int(p.homes), int(p.room)], 18, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 100), Hold.text(Game), 16, UI.C_TEXT, r.size.x - 48)

## The Works page (works.gd, the Hundred Works release): the eighteen works in their three schools,
## what each does, what it costs in know-how and spirit stones, and what stands already.
func _draw_works() -> void:
	UI.text(self, Vector2(60, 70), "The Hundred Works", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 15)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(24, 36), "%s      Know-how: %d (of %d learned)      Spirit stones: %d" % [Works.title(Game), Works.know(Game), Works.know_earned(Game), Game.stones], 15, UI.C_JADE,
		HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	for k in Works.SCHOOL_ORDER.size():
		var sc: Dictionary = Works.SCHOOLS[Works.SCHOOL_ORDER[k]]
		UI.text(self, r.position + Vector2(24 + k * 256, 62), "%s  %d/%d" % [str(sc.n), Works.count(Game, Works.SCHOOL_ORDER[k]), Works.TIERS], 15, sc.col, HORIZONTAL_ALIGNMENT_LEFT, 250)
	if cursor < Works.ORDER.size():
		var wid: String = Works.ORDER[cursor]
		var w: Dictionary = Works.WORKS[wid]
		var sc2: Dictionary = Works.SCHOOLS[w.school]
		var shown: bool = Works.has(Game, wid) or Works.known(Game, wid)
		UI.text(self, r.position + Vector2(24, 110), str(w.n) if shown else "Not yet known", 24, UI.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		UI.text(self, r.position + Vector2(24, 138), "%s, the %s of six: %s.  \"%s\"" % [str(sc2.n), ["first", "second", "third", "fourth", "fifth", "sixth"][int(w.tier)], str(sc2.what), str(sc2.motto)], 14, sc2.col,
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		UI.wrapped(self, r.position + Vector2(24, 180), Works.text(Game, wid), 18, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 110), "Know-how is what Lin Feng has learned by looking: one for every kind of creature met, every lord defeated, every thing of the land tried and every obstacle cleared, two for every deed and every cave of the Founder's opened. It is spent on nothing but works, and there is not enough in one journey for all three schools.", 17, UI.C_DIM, r.size.x - 48)
	if msg != "":
		UI.text(self, r.position + Vector2(24, r.size.y - 20), msg, 16, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)

## The Crossroads page (echoes.gd): the three scales and where they stand, and every crossroads of the
## road: what was asked, what was chosen, how many of its echoes have been heard, and how it ends.
func _draw_roads() -> void:
	UI.text(self, Vector2(60, 70), "Crossroads", 22, UI.C_GOLD)
	UI.menu_list(self, Rect2(40, 80, 380, 600), labels, cursor, enabled, 15)
	var r := Rect2(440, 80, 800, 600)
	UI.panel(self, r)
	for k in Echoes.SCALE_ORDER.size():
		var sid: String = Echoes.SCALE_ORDER[k]
		var sc: Dictionary = Echoes.SCALES[sid]
		var v := Echoes.scale(Game, sid)
		var at := r.position + Vector2(24, 34 + k * 44)
		UI.text(self, at, str(sc.neg), 13, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 150)
		UI.text(self, at + Vector2(560, 0), str(sc.pos), 13, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 190)
		var bar := Rect2(at + Vector2(150, -10), Vector2(400, 8))
		draw_rect(bar, Color(1, 1, 1, 0.08))
		draw_rect(Rect2(bar.position + Vector2(200, 0), Vector2(clampf(v / 10.0, -1.0, 1.0) * 200.0, 8)), sc.col)
		draw_rect(Rect2(bar.position + Vector2(199, -3), Vector2(2, 14)), UI.C_DIM)
		var nm := Echoes.name_of(Game, sid)
		var what := "" if nm == "" else str(sc.pos_text if v > 0 else sc.neg_text)
		var sl: String = ("%s: %s" % [nm, what]) if nm != "" else "%s: not leaning either way yet." % str(sc.n)
		UI.text(self, at + Vector2(0, 18), sl, UI.fit(sl, 12, r.size.x - 48), sc.col if nm != "" else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
	if cursor < Echoes.ORDER.size():
		var cid: String = Echoes.ORDER[cursor]
		UI.text(self, r.position + Vector2(24, 190), str(Echoes.CROSSROADS[cid].n) if Echoes.chosen(Game, cid) != "" else "A crossroads not yet reached", 22, UI.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		UI.wrapped(self, r.position + Vector2(24, 224), Echoes.text(Game, cid), 17, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 200), "A crossroads is asked once and cannot be taken back. Each answer tips a scale, and a scale that leans far enough changes how the world meets Lin Feng. Each answer is also remembered: people speak of it later, sometimes many chapters later, and the ending tells what came of it.", 17, UI.C_DIM, r.size.x - 48)

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
		y += 104.0
	# Part XIV: the grudges that stayed (grudges.gd), once Judge Cui has shown them
	if Game.reached(Grudges.STEP):
		var gl := "The grudges that stayed: %d of 6 laid to rest, %d left to the Wheel" % [Grudges.settled(Game), Grudges.unpaid(Game)]
		UI.text(self, Vector2(r.position.x + 24, r.end.y - 40), gl, 16, Trials.KINDS.bond.col)
	UI.text(self, Vector2(r.position.x + 24, r.end.y - 16), "Esc back", 14, UI.C_DIM)

## Yue Ling (the Lotus release, bonds.gd): how close the two of them are, which way her heart leans,
## the heart-to-hearts had, her wishes, and in Part XV the memories the Founder pressed.
func _draw_yue() -> void:
	var r := Rect2(30, 20, 1220, 680)
	UI.panel(self, r)
	var pink := Color("ff9ac0")
	UI.text(self, r.position + Vector2(24, 40), "Yue Ling", 26, pink)
	var lv := Bonds.level(Game)
	UI.text(self, r.position + Vector2(160, 40), Bonds.TITLES[lv], 20, UI.C_GOLD)
	var nt := Bonds.next_text(Game)
	var frac := 1.0
	if lv < Bonds.LEVELS.size() - 1:
		frac = float(Game.bond - Bonds.LEVELS[lv]) / float(Bonds.LEVELS[lv + 1] - Bonds.LEVELS[lv])
	UI.bar(self, Rect2(r.position.x + 24, r.position.y + 54, 420, 10), frac, pink)
	UI.text(self, r.position + Vector2(460, 64), nt if nt != "" else "as close as two people come", 14, UI.C_DIM)
	# her heart: the three futures
	var y := r.position.y + 104.0
	UI.text(self, Vector2(r.position.x + 24, y), "Her heart", 19, UI.C_GOLD)
	var lean := Bonds.leaning(Game)
	var tot := 0
	for fk in Bonds.FUTURE_ORDER:
		tot += int(Game.heart.get(fk, 0))
	for fk2 in Bonds.FUTURE_ORDER:
		y += 26.0
		var fut: Dictionary = Bonds.FUTURES[fk2]
		var wt := int(Game.heart.get(fk2, 0))
		var chosen: bool = Game.future == fk2
		UI.text(self, Vector2(r.position.x + 40, y), str(fut.n) + ("   (her choice)" if chosen else ("   (leaning)" if fk2 == lean and Game.future == "" else "")), 16, fut.col if wt > 0 or chosen else UI.C_DIM)
		UI.bar(self, Rect2(r.position.x + 360, y - 11, 240, 8), float(wt) / float(maxi(1, tot)), fut.col)
	# the heart-to-hearts and her wishes
	y += 40.0
	var had: int = Game.talks.size()
	var waiting := Bonds.talk_ready(Game) != ""
	UI.text(self, Vector2(r.position.x + 24, y), "Heart-to-hearts: %d had of %d so far%s" % [had, Bonds.talks_open(Game), "   - she wants to talk (T)" if waiting else ""], 17, pink if waiting else UI.C_TEXT)
	y += 30.0
	UI.text(self, Vector2(r.position.x + 24, y), "Her wishes: %d of %d granted" % [Game.wishes.size(), Bonds.WISHES.size()], 17, UI.C_TEXT)
	for wid in Bonds.wishes_open(Game).slice(0, 3):
		# (a long wish runs to two lines: the next starts below it, not on top of its second line)
		var ask := "\"%s\"" % str(Bonds.wish(str(wid)).ask)
		y += 24.0
		UI.wrapped(self, Vector2(r.position.x + 40, y), ask, 14, UI.C_DIM.lightened(0.3), 560)
		y += 6.0 + UI.font().get_height(14) * (UI.wrap_lines(ask, 14, 560).size() - 1)
	# Part XV: the memories the Founder pressed (once the echo has told of them)
	var x2 := r.position.x + 640
	var y2 := r.position.y + 104.0
	if Game.reached("s_p15_memories"):
		UI.text(self, Vector2(x2, y2), "The memories the Founder pressed: %d given back" % Game.memories.size(), 19, UI.C_GOLD)
		for mid in Bonds.MEMORY_ORDER:
			y2 += 28.0
			var m: Dictionary = Bonds.MEMORIES[mid]
			var got: bool = Game.memories.has(mid)
			UI.text(self, Vector2(x2 + 16, y2), str(m.bearer), 16, m.col if got else UI.C_TEXT)
			UI.text(self, Vector2(x2 + 300, y2), ("given back" if got else str(menu_place(str(m.area)))), 14, UI.C_JADE if got else UI.C_DIM)
	else:
		UI.wrapped(self, Vector2(x2, y2), "Woke beside a lotus pond with her name and nothing else. A healer whose hands remember more than she does.", 16, UI.C_DIM.lightened(0.2), 540)
	# courtship (romance.gd): where the two of them stand
	UI.text(self, Vector2(r.position.x + 24, r.end.y - 196), Romance.summary(Game), 15, pink, HORIZONTAL_ALIGNMENT_LEFT, 1160)
	var ask_now := Romance.next_ask(Game)
	if ask_now != "" and Romance.ask_blocked(Game, ask_now) != "":
		UI.text(self, Vector2(r.position.x + 420, r.end.y - 60), "%s: %s" % [str(Romance.ASKS[ask_now].n), Romance.ask_blocked(Game, ask_now)], 13, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 780)
	UI.menu_list(self, Rect2(r.position.x + 24, r.end.y - 172, 380, 152), labels, cursor, enabled, 17)

## Where a region is, for the Yue Ling page.
static func menu_place(area: String) -> String:
	return str(MAP_NAMES.get(area, Data.AREAS.get(area, {}).get("n", area)))

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
	"huaxu": "Huaxu", "zhongbei": "Zhongbei", "gumang": "Gumang", "fuluo": "Fuluo",
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
	# the high roads between the towns (roads.gd): a dark line with a pale one down the middle of it
	for ln in Roads.of(map_layer).lines:
		var pl := PackedVector2Array()
		for k in range(0, (ln.pts as Array).size(), 2):
			pl.append(o + (Vector2(ln.pts[k]) + Vector2(0.5, 0.5)) * scale)
		pl.append(o + (Vector2(ln.pts[(ln.pts as Array).size() - 1]) + Vector2(0.5, 0.5)) * scale)
		if pl.size() >= 2 and ln.get("lane", false):
			draw_polyline(pl, Color(0.16, 0.12, 0.08, 0.7), 2.2, true)
			draw_polyline(pl, Color("c8b890"), 0.8, true)
		elif pl.size() >= 2:
			draw_polyline(pl, Color(0.16, 0.12, 0.08, 0.9), 4.0, true)
			draw_polyline(pl, Color("e8d8a8"), 1.6, true)
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
	draw_line(Vector2(cx - 2, ly - 25), Vector2(cx + 12, ly - 25), Color(0.16, 0.12, 0.08, 0.9), 4.0)
	draw_line(Vector2(cx - 2, ly - 25), Vector2(cx + 12, ly - 25), Color("e8d8a8"), 1.6)
	UI.text(self, Vector2(cx + 18, ly - 20), "the high road between the towns, and the lanes off it", 13, UI.C_DIM)
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
		var also: bool = not on and Braid.holds(Game, id)
		if also:
			col = d.col
		UI.text(self, r.position + Vector2(24, y), ("> " if on else ("+ " if also else "  ")) + str(d.n), 17, col, HORIZONTAL_ALIGNMENT_LEFT, 316)
		var rank := "" if not Game.dao_xp.has(id) else str(Data.DAO_RANKS[tier])
		UI.text(self, r.position + Vector2(350, y), rank, 14, UI.C_DIM)
		var nxt: int = Data.DAO_TIERS[mini(tier + 1, Data.DAO_TIERS.size() - 1)]
		UI.bar(self, Rect2(r.position + Vector2(430, y - 11), Vector2(130, 8)), 1.0 if tier >= Data.DAO_TIERS.size() - 1 else float(xp) / float(maxi(nxt, 1)), col)
		y += 20.0
		y += _wrap_at(r.position + Vector2(44, y), str(d.desc), 13, UI.C_DIM.lightened(0.2), 516) + 12.0
	if Game.dao != "":
		var dd: Dictionary = Data.DAOS[Game.dao]
		_wrap_at(r.position + Vector2(24, y + 6), "\"%s\"  Technique from Adept: %s.  Change roads, or walk another as well, at any Dao Stele.  %s" % [dd.motto, Data.SKILLS[dd.skill].n, Braid.burden(Game)], 13, UI.C_TEXT, 536)
	UI.text(self, r.position + Vector2(600, 36), "The peoples of the realms", 22, UI.C_GOLD)
	var y2 := 70.0
	for race in Data.RACE_ORDER:
		var rc: Dictionary = Data.RACES[race]
		if race != "human" and not Game.met.has(race):
			continue
		# the name and the standing on one row, the rest under it: eight peoples and the humans have to fit
		# on the page (the Road of the Many Peoples asks for all eight; the eighth used to fall off it)
		UI.text(self, r.position + Vector2(600, y2), str(rc.n), 16, UI.C_GOLD if race != "human" else UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 290)
		var line := "%s.  Honour the %s." % [str(rc.home), Data.DAOS[rc.dao].n]
		if race != "human":
			var st: int = int(Game.standing.get(race, 0))
			UI.bar(self, Rect2(r.position + Vector2(900, y2 - 9), Vector2(110, 8)), float(st) / float(Data.KIN), Color("8ae0c0"))
			UI.text(self, r.position + Vector2(1020, y2), Game.race_title(race), 13, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, 170)
			line += "  Love: %s." % Data.ITEMS[rc.gift].n
			if Game.race_tier(race) >= 1:
				line += "  Boon: %s." % rc.boon_n
		y2 += 17.0
		y2 += _wrap_at(r.position + Vector2(612, y2), line, 12, UI.C_DIM.lightened(0.25), 578) + 9.0
	UI.text(self, Vector2(r.end.x - 200, r.end.y - 16), "Enter / Esc: back", 13, UI.C_DIM)

## The Six Hearths (cultures.gd, the New Fire release): the peoples of the land, how each greets,
## eats, keeps its fire and what nobody does there, and whether they call the hero a stranger, a guest
## or kin; the hero's own hearth is marked.
func _draw_hearths() -> void:
	var r := Rect2(30, 20, 1220, 680)
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(24, 36), "The Six Hearths of the Unbroken Land", 22, UI.C_GOLD)
	_wrap_at(r.position + Vector2(624, 26), "Guest of %d of 6.  A first word with a hearth's townsfolk, a seat with one of its people, and what is done for it in the story earn a place at it." % Cultures.guests(Game), 12, UI.C_DIM, 570)
	var own := Cultures.own(Game)
	for k in Cultures.ORDER.size():
		var id: String = Cultures.ORDER[k]
		var hh: Dictionary = Cultures.HEARTHS[id]
		var at := r.position + Vector2(24 + (k % 2) * 600, 66 + (k / 2) * 204)
		var t := Cultures.tier(Game, id)
		var col: Color = hh.col if t >= 1 else UI.C_DIM.lightened(0.15)
		draw_rect(Rect2(at + Vector2(-6, -16), Vector2(586, 196)), Color(hh.col.r, hh.col.g, hh.col.b, 0.07 if t >= 1 else 0.03))
		UI.text(self, at, "%s  -  %s" % [str(hh.n).trim_prefix("the "), str(hh.people)], 17, col, HORIZONTAL_ALIGNMENT_LEFT, 360)
		UI.bar(self, Rect2(at + Vector2(372, -10), Vector2(100, 8)), float(int(Game.hearth.get(id, 0))) / float(Cultures.KIN), hh.col)
		UI.text(self, at + Vector2(480, 0), Cultures.tier_name(t) + ("  (yours)" if id == own else ""), 13, UI.C_JADE if t >= 1 else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 110)
		var y := 18.0
		y += _wrap_at(at + Vector2(0, y), "%s.  \"%s\"" % [str(hh.home), str(hh.greet)], 13, UI.C_TEXT, 570)
		y += _wrap_at(at + Vector2(0, y), "Table: %s; %s." % [str(hh.dish), str(hh.drink)], 12, UI.C_DIM.lightened(0.3), 570)
		y += _wrap_at(at + Vector2(0, y), "Fire: %s." % str(hh.fire), 12, UI.C_DIM.lightened(0.3), 570)
		y += _wrap_at(at + Vector2(0, y), "Custom: %s  %s" % [str(hh.custom), str(hh.taboo)], 12, UI.C_DIM.lightened(0.3), 570)
		_wrap_at(at + Vector2(0, y), "Festival: %s.  To its guests: %s." % [str(hh.festival), str(hh.guest_text)], 12, col.lightened(0.2), 570)
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
	elif s.get("kind", "") == "grudges":
		# Part XIV: the grudges that stayed (grudges.gd), where each stands and what became of it
		y2 += _wrap_at(Vector2(x1, y2), "Each stands where its owner fell. It will fight first; then ask what it was owed. Every one laid to rest takes something off Nie, every one left to the Wheel feeds it.", 13, UI.C_DIM.lightened(0.2), w1) + 10.0
		var how := {"eased": "laid to rest", "paid": "paid", "unpaid": "left to the Wheel"}
		for gid2 in Grudges.ORDER:
			var gs := Grudges.state(Game, gid2)
			var ga2 := Trials.boss_area(gid2)
			UI.text(self, Vector2(x1, y2), "%s, %s" % [Data.ENEMIES[gid2].n, MAP_NAMES.get(ga2, ga2)], 14, (UI.C_JADE if gs in Grudges.SETTLED else UI.C_RED.lightened(0.3)) if gs != "" else UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, w1)
			y2 += 17.0
			UI.text(self, Vector2(x1 + 14, y2), str(how.get(gs, "still waiting")), 12, UI.C_DIM.lightened(0.2), HORIZONTAL_ALIGNMENT_LEFT, w1 - 14)
			y2 += 22.0
	elif s.get("kind", "") == "memories":
		# Part XV: the memories the Founder pressed (bonds.gd), where each is and whether it is given back
		y2 += _wrap_at(Vector2(x1, y2), "Seven places where Yue Ling was happiest with a bearer, each guarded by the moths that eat forgetting. Any %d will do; do there what she did, together." % Bonds.MEMORIES_NEEDED, 13, UI.C_DIM.lightened(0.2), w1) + 10.0
		for mid in Bonds.MEMORY_ORDER:
			var m: Dictionary = Bonds.MEMORIES[mid]
			var got: bool = Game.memories.has(mid)
			UI.text(self, Vector2(x1, y2), "%s, %s" % [str(m.n), MAP_NAMES.get(str(m.area), str(m.area))], 14, UI.C_JADE if got else UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, w1)
			y2 += 17.0
			UI.text(self, Vector2(x1 + 14, y2), "given back" if got else str(Props.KINDS[str(m.prop)].verb).to_lower(), 12, UI.C_DIM.lightened(0.2), HORIZONTAL_ALIGNMENT_LEFT, w1 - 14)
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
	if mode == "hearths":
		_draw_hearths()
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
	if mode == "works":
		_draw_works()
		return
	if mode == "roads":
		_draw_roads()
		return
	if mode == "feats":
		_draw_feats()
		return
	if mode == "load":
		_draw_load()
		return
	if mode == "land":
		_draw_land()
		return
	if mode == "way":
		_draw_way()
		return
	if mode == "almanac":
		_draw_almanac()
		return
	if mode == "law":
		_draw_law()
		return
	if mode == "leaves":
		_draw_leaves()
		return
	if mode == "rites":
		_draw_rites()
		return
	if mode == "words":
		_draw_words()
		return
	if mode == "wild":
		_draw_wild()
		return
	if mode == "seals":
		_draw_seals()
		return
	if mode == "body":
		_draw_body()
		return
	if mode == "songs":
		_draw_songs()
		return
	if mode == "host":
		_draw_host()
		return
	if mode == "town":
		_draw_town()
		return
	if mode == "yue":
		_draw_yue()
		return
	UI.menu_list(self, Rect2(60, 80, 300, 470 if mode != "root" else 590), labels, cursor, enabled, 22 if mode != "root" else 17)
	UI.text(self, Vector2(60, 70), "Menu" if mode == "root" else "Items", 22, UI.C_GOLD)
	# status panel
	var r := Rect2(400, 80, 820, 560)
	UI.panel(self, r)
	UI.text(self, Vector2(430, 120), "Lin Feng", 28, UI.C_GOLD)
	UI.text(self, Vector2(430, 150), Data.level_name(Game.level), 20)
	UI.text(self, Vector2(830, 150), "Fame: %s" % Fame.name_of(Game), 15, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, 380)
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
		UI.text(self, kp, "%s  %d" % [s.n, int(ceil(Game.skill_cost(sid)))], 13 if step >= 18.0 else 12, Data.ELEM_COLORS[s.elem], HORIZONTAL_ALIGNMENT_LEFT, 192)
		ki += 1
	UI.text(self, Vector2(430, 530), "Spirit stones: %d    Sword tempering: %d/%d" % [Game.stones, Game.temper, Data.TEMPER_COST.size()], 17)
	UI.text(self, Vector2(430, 560), "Objective: " + Game.objective_text(), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 770)
	UI.text(self, Vector2(430, 610), "Play time %s" % Fmt.clock(Game.playtime), 15, UI.C_DIM)
	# what he wears and rides (Fates and Faces)
	var outfit: Dictionary = Fashion.OUTFITS.get(Game.outfit, Fashion.OUTFITS.sweeper)
	var ride_n: String = str(Fashion.RIDES[Game.ride].n) if Game.ride != "" else "none yet"
	UI.text(self, Vector2(430, 586), "Wearing the %s (%s)   Ride: %s%s" % [outfit.n, Fashion.fx_text(outfit.fx), ride_n, "  (riding)" if Game.riding and Game.ride != "" else ""], 15, UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 780)
	if msg != "":
		UI.text(self, Vector2(60, 580 if mode != "root" else 696), msg, 17, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, 300)
