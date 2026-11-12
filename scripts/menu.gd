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
		labels = ["Meditate", "Breakthrough", "Items", "Cultivation", "Journal", "Fates", "Crossroads", "Works", "Yue Ling", "Dao & Peoples", "Hearths", "Arms", "Wardrobe", "Stable", "The Host", "Songs", "Feats", "The Body", "Bestiary", "World Map", "Annals", "Resume"]
		ids = ["meditate", "breakthrough", "items", "cultivation", "journal", "fates", "roads", "works", "yue", "dao", "hearths", "arms", "wardrobe", "stable", "host", "songs", "feats", "body", "bestiary", "map", "annals", "resume"]
		enabled = [Game.level < Data.MAX_LEVEL, Game.can_breakthrough() and Game.cur_step().get("kind", "") == "breakthrough", true, true, true, true, true, true, Game.companion or Game.bond > 0,
			Game.dao != "" or not Game.met.is_empty(), true, true, true, not Game.rides.is_empty(), true, true, true, true, not Game.bestiary.is_empty() or not Game.told.is_empty(), main.world.mini_tex != null, true, true]
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
			(str(Romance.ASKS[ask_id].n) + "...") if ask_id != "" else "Nothing left unsaid", "Back"]
		ids = ["talk", "gift", "outing", "ask", "back"]
		enabled = [tid != "", Game.companion, Game.companion, ask_id != "" and Romance.ask_blocked(Game, ask_id) == "", true]
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
			if mode in ["items", "map", "annals", "dao", "cultivation", "journal", "bestiary", "fates", "yue", "hearths", "works", "roads", "feats", "songs", "host", "body"]:
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
				"works", "roads", "feats", "songs", "host", "body":
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
					if mode == "annals" or mode == "bestiary" or mode == "roads" or mode == "feats" or mode == "host":
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
		UI.wrapped(self, r.position + Vector2(24, ty), str(e[2]), 18, UI.C_TEXT, r.size.x - 48)
	else:
		UI.wrapped(self, r.position + Vector2(24, 40), "Every foe has a story. %d of %d met so far; the bosses are marked with a star." % [entries.size(), Data.ENEMIES.size()], 17, UI.C_DIM, r.size.x - 48)

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
	if mode == "body":
		_draw_body()
		return
	if mode == "songs":
		_draw_songs()
		return
	if mode == "host":
		_draw_host()
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
		UI.text(self, Vector2(60, 580 if mode != "root" else 696), msg, 17, UI.C_JADE, HORIZONTAL_ALIGNMENT_LEFT, 300)
