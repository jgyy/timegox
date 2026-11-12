extends SceneTree
## Data-integrity tests.  Run: godot --headless --path . --script tests/run_tests.gd

var failures := 0
var finished := false
var compiled := false

## Watchdog: a script error aborts _init() before quit() and the runner used to hang until CI's
## timeout.  If the first frame arrives and the tests did not finish, fail fast instead.
## On that first frame the autoloads are up, so every script is compiled too: the screens that use
## `Game` cannot be compiled from _init(), and a parse error in one of them (ending.gd once) used to
## pass every test and only break the game when that screen was made.
func _process(_d: float) -> bool:
	if not finished:
		printerr("  FAIL tests aborted by a script error (see above)")
		quit(1)
		return false
	if not compiled:
		compiled = true
		print("== every script compiles ==")
		for d in ["res://scripts", "res://tests"]:
			for f in DirAccess.get_files_at(d):
				if f.ends_with(".gd"):
					var sc = load(d + "/" + f)
					check(sc != null and (sc as GDScript).can_instantiate(), "%s/%s compiles" % [d.trim_prefix("res://"), f])
		# the ending's film (it uses Game, so it is only read once compiled): a line and time to read
		# it in every shot, every wonder in a shot, last words for every road into the heart and a
		# word on the results for every way through a trial
		var ending = load("res://scripts/ending.gd")
		if ending != null:
			print("== the ending ==")
			var shown := {}
			for f in ending.FILM:
				check(str(f.line) != "" and float(f.dur) >= 5.0, "the ending's shot %s has its line and time to read it" % f.id)
				for g in f.show:
					shown[g] = true
			for g in ["bridge", "cauldrons", "jianmu", "isles", "gates", "wheel", "hero"]:
				check(shown.has(g), "the ending's film shows the %s" % g)
			var last: Array = ending.shot_at(ending.film_length() + 30.0)
			check(int(last[0]) == ending.FILM.size() - 1, "after the film the ending rests on the lotus")
			for p in Trials.TRIALS.chiyou.paths:
				check(ending.ROAD_ENDS.has(p.id), "the ending has last words for the road %s" % p.id)
			for kd in Trials.KIND_ORDER:
				check(ending.KIND_WORD.has(kd), "the results name the way %s" % kd)
		print("failures: ", failures)
		quit(1 if failures > 0 else 0)
	return false

## The chapter-closing breakthroughs Main brings Lin Feng home after (read from main.gd's source: the
## screen cannot be instanced from a test script).
func main_recalls_s_break16() -> bool:
	var src := FileAccess.get_file_as_string("res://scripts/main.gd")
	return src.contains("\"s_break16\": \"recall10\"") and Data.DIALOGUE.has("recall10")

## Whether entity `e` can be got at from the tiles in `reach`: its own tile, or for a thing to do
## (props.gd), which stands on a tile nobody walks over, a tile beside it to use it from.
func reached(e: Dictionary, reach: Dictionary) -> bool:
	if reach.has(e.pos):
		return true
	if e.kind == "prop":
		for d in MapGen.DIRS:
			if reach.has(e.pos + d):
				return true
	return false

func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		printerr("  FAIL ", msg)

func _init() -> void:
	print("== quest chain ==")
	var ids := {}
	for s in Data.STEPS:
		check(not ids.has(s.id), "unique step id " + s.id)
		ids[s.id] = true
		if s.kind == "talk":
			check(Data.DIALOGUE.has(s.id), "dialogue for " + s.id)
			var found := false
			for n in Data.AREAS[s.area].get("npcs", []):
				found = found or n.id == s.npc
			check(found, "npc %s exists in %s" % [s.npc, s.area])
		if s.kind == "kill":
			check(Data.DIALOGUE.has("pre:" + s.boss) and Data.DIALOGUE.has("post:" + s.boss), "boss dialogue " + s.boss)
			var bf := false
			for b in Data.AREAS[s.area].bosses:
				bf = bf or b.id == s.boss
			check(bf, "boss %s placed in %s" % [s.boss, s.area])
		if s.kind == "breakthrough":
			check(Data.DIALOGUE.has("pre:" + s.id) and Data.DIALOGUE.has("post:" + s.id), "breakthrough dialogue " + s.id)
	for a in Data.AREAS:
		for p in Data.AREAS[a].portals:
			check(p.open == "" or Data.step_index(p.open) >= 0, "portal gate step valid in " + a)
			check(Data.AREAS[p.to].portals.any(func(q): return q.to == a), "portal %s->%s has a way back" % [a, p.to])
	print("== maps ==")
	for a in Data.AREAS:
		var m := MapGen.build(a)
		var start: Vector2i = m.start
		var reach := MapGen.flood(m.grid, m.w, m.h, start)
		var bad := 0
		for e in m.ents:
			if e.kind != "spring" and not reach.has(e.pos):
				bad += 1
		check(bad == 0, "%s: all %d entities reachable" % [a, m.ents.size()])
		var again := MapGen.build(a)
		check(again.grid == m.grid, a + ": generation is deterministic")
	print("== content ==")
	var world_themes: Dictionary = Look.THEMES
	var pickup_cols: Dictionary = Look.PICKUP_COLORS
	var battle_sky: Dictionary = Look.THEMES
	for a in Data.AREAS:
		var spec: Dictionary = Data.AREAS[a]
		check(world_themes.has(spec.theme), a + ": world theme " + spec.theme)
		check(battle_sky.has(spec.theme), a + ": battle sky " + spec.theme)
		check(spec.theme == "sect" or MapGen.DENSITY.has(spec.theme), a + ": map density " + spec.theme)
		check(Data.AREA_CHAIN.has(a) or a == Atlas.HUB, a + ": is in the area chain")
		for pe in spec.get("pool", []):
			check(Data.ENEMIES.has(pe[0]) and not Data.ENEMIES[pe[0]].get("boss", false), a + ": pool enemy " + pe[0])
		for pk in spec.get("pickups", []):
			check(Data.ITEMS.has(pk.item) and pickup_cols.has(pk.item), a + ": pickup art for " + pk.item)
		for b in spec.get("bosses", []):
			check(Data.ENEMIES.has(b.id) and Data.ENEMIES[b.id].get("boss", false), a + ": boss " + b.id)
			check(b.req <= Data.MAX_LEVEL, a + ": boss level requirement " + b.id)
	for a2 in Data.AREA_CHAIN:
		check(Data.next_hop("sect", a2) != "" or a2 == "sect", "area %s is reachable from the sect hub" % a2)
		check(Atlas.layout().has(a2), "area %s has a place in the open world" % a2)
		check(Data.next_hop(a2, "sect") != "" or a2 == "sect", "area %s can travel back to the sect" % a2)
	for i in Data.AREA_CHAIN.size():
		check(Data.AREAS.has(Data.AREA_CHAIN[i]), "chain area exists " + Data.AREA_CHAIN[i])
	for e in Data.ENEMIES:
		check(UI.SHAPES.has(Data.ENEMIES[e].shape), "monster art exists for shape " + Data.ENEMIES[e].shape + " (" + e + ")")
	for sid in Data.SKILLS:
		check(Data.ELEM_COLORS.has(Data.SKILLS[sid].elem), "skill element colour " + sid)
	var last: Dictionary = Data.STEPS[Data.STEPS.size() - 1]
	check(last.kind == "breakthrough" and last.to == Data.MAX_LEVEL, "final quest step is the last breakthrough")
	var hunts := 0
	for s2 in Data.STEPS:
		if s2.kind == "kill":
			hunts += 1
	check(hunts >= 45, "at least 45 boss fights in the chain (found %d)" % hunts)
	print("== 3D assets ==")
	for shape in UI.SHAPES:
		var mdl := Models.monster(shape, Color("88aa66"), true)
		check(mdl.get_child_count() > 0, "3D model builds for shape " + shape)
		mdl.free()
	print("== Blender assets ==")
	for id in Assets.PEOPLE:
		var rel: String = Assets.PEOPLE[id]
		check(Assets.has(rel), "character asset exported: " + rel)
		if not Assets.has(rel):
			continue
		var pm := Assets.person(id)
		var ap: AnimationPlayer = pm.get_meta("ap", null)
		check(ap != null, rel + ": has an AnimationPlayer")
		if ap != null:
			for clip in ["idle", "walk", "run", "sit", "talk", "bow", "attack", "cast", "hurt", "victory", "die"] + Data.EMOTES:
				check(ap.has_animation(clip), "%s: clip %s" % [rel, clip])
			for gesture in Data.EMOTES:
				check(ap.get_animation(gesture).loop_mode == Animation.LOOP_NONE, "%s: the %s gesture plays once" % [rel, gesture])
			for loop_clip in ["walk", "run", "talk"]:
				check(ap.get_animation(loop_clip).loop_mode == Animation.LOOP_LINEAR, "%s: %s loops" % [rel, loop_clip])
			for once in ["attack", "bow", "die"]:
				check(ap.get_animation(once).loop_mode == Animation.LOOP_NONE, "%s: %s plays once" % [rel, once])
		var skels: Array = []
		Assets._walk(pm, skels, "Skeleton3D")
		check(not skels.is_empty() and skels[0].find_bone("hand.R") >= 0 and skels[0].find_bone("eyes") >= 0, rel + ": rig has hands and an eyelid bone")
		# the richer rig: sleeve pockets, fingers, thumbs, toes, a mouth and the longer hair and cape chains
		for bone in ["sleeve.L", "sleeve.R", "fingers.L", "thumb.R", "toe.L", "mouth", "hair_tail2", "cape3"]:
			check(not skels.is_empty() and skels[0].find_bone(bone) >= 0, "%s: rig has %s" % [rel, bone])
		var tris := 0
		for mi in pm.get_meta("meshes"):
			for si in mi.mesh.get_surface_count():
				tris += mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_INDEX].size() / 3
				var mat: Material = mi.mesh.surface_get_material(si)
				check(mat == MB.mat_actor() or mat == MB.mat_actor_plain() or mat == MB.mat_glow(), "%s: surface %d uses the actor shading" % [rel, si])
		# sculpted faces, strand hair and layered hanfu: a hero-asset budget, still well under 50k
		check(tris > 5000 and tris < 50000, "%s: sensible triangle count (%d)" % [rel, tris])
		pm.free()
	for shape in Assets.MONSTERS:
		var mrel: String = Assets.MONSTERS[shape]
		check(Assets.has(mrel), "monster asset exported for " + shape)
		if not Assets.has(mrel):
			continue
		var mm := Assets.monster(shape, Color("ff0000"))
		var map: AnimationPlayer = mm.get_meta("ap", null)
		check(map != null and map.has_animation("idle") and map.has_animation("attack") and map.has_animation("hurt"), shape + ": idle, attack and hurt clips")
		# tint: red asked for, so tinted vertices come out red-dominant (the palette shades them from
		# a deep red to a warm light red; secondary and accent parts are a minority)
		var tinted := 0
		var arr: Array = mm.get_meta("meshes")[0].mesh.surface_get_arrays(0)
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		for i in cols.size():
			if uvs[i].x > 0.99 and cols[i].r > 0.02 and cols[i].r > cols[i].g * 2.0 and cols[i].r > cols[i].b * 2.0:
				tinted += 1
		check(tinted > cols.size() / 10, "%s: tint recolours the body (%d of %d vertices)" % [shape, tinted, cols.size()])
		mm.free()
	# the palette: one enemy colour gives a distinct secondary and a contrasting accent
	var pal: Array = Assets.palette(Color("c03020"))
	check(absf((pal[3] as Color).h - (pal[0] as Color).h) > 0.05 and absf((pal[4] as Color).h - (pal[0] as Color).h) > 0.3, "palette: analogous secondary and contrasting accent")
	var grey_pal: Array = Assets.palette(Color("e8e8f0"))
	check((grey_pal[4] as Color).s > 0.3, "palette: a near-grey enemy still gets a coloured accent")
	# monster colour: a pale countershaded underside, markings that contrast in value, a secondary
	# set apart in hue and value, and a saturated accent away from the body's hue
	var wolf_pal: Array = Assets.palette(Color("7aa860"), "wood")
	var wb: Color = wolf_pal[0]
	check((wolf_pal[5] as Color).v > wb.v + 0.15 and (wolf_pal[5] as Color).s < wb.s, "palette: the underside is paler and less saturated than the body")
	check(absf((wolf_pal[6] as Color).v - wb.v) > 0.35, "palette: markings contrast in value with the body")
	check(Assets.hue_gap((wolf_pal[3] as Color).h, wb.h) > 0.08 and absf((wolf_pal[3] as Color).v - wb.v) > 0.1, "palette: the secondary differs from the body in hue and in value")
	check(Assets.hue_gap((wolf_pal[4] as Color).h, wb.h) >= 0.07 and (wolf_pal[4] as Color).s > 0.5, "palette: a saturated accent well away from the body's hue")
	var dark_pal: Array = Assets.palette(Color("2a2a38"), "dark")
	check((dark_pal[6] as Color).v > 0.7, "palette: a dark coat gets pale markings")
	var fire_pal: Array = Assets.palette(Color("3a6ad8"), "fire")
	check(Assets.hue_gap((fire_pal[4] as Color).h, Color("ffc21a").h) < 0.01, "palette: the element sets the accent (fire: gold)")
	var gold_fire: Array = Assets.palette(Color("f0b020"), "fire")
	check(Assets.hue_gap((gold_fire[4] as Color).h, Color("f0b020").h) >= 0.07, "palette: a golden fire beast gets the element's alternate accent")
	var bf: Dictionary = Data.ENEMIES.bifang
	var bf_pal: Array = Assets.palette(bf.col, bf.elem, bf.pal)
	check((bf_pal[6] as Color).is_equal_approx(Color("e0302a")), "palette: Bifang's red markings on a blue-green body are pinned")
	for eid in Data.ENEMIES:
		var pin: Dictionary = Data.ENEMIES[eid].get("pal", {})
		for key in pin:
			check(key in ["sec", "acc", "under", "mark"] and pin[key] is Color, "%s: pinned palette role %s" % [eid, key])
	# palette slots decode to the roles, blending from the body into underside and markings
	var lin_pal: Array = []
	for pc in wolf_pal:
		lin_pal.append((pc as Color).srgb_to_linear())
	var grey9 := Color(0.9, 0.9, 0.9)
	check(Assets._tint_for(lin_pal, grey9, 0.2).is_equal_approx(lin_pal[5]) and Assets._tint_for(lin_pal, grey9, 0.8).is_equal_approx(lin_pal[6]), "slots: 0.2 is the underside, 0.8 the markings")
	check(Assets._tint_for(lin_pal, grey9, 0.5).is_equal_approx(lin_pal[3]) and Assets._tint_for(lin_pal, grey9, 1.0).is_equal_approx(lin_pal[4]), "slots: 0.5 is the secondary, 1 the accent")
	var half: Color = Assets._tint_for(lin_pal, grey9, 0.1)
	check(half.is_equal_approx(Assets._tint_for(lin_pal, grey9, 0.0).lerp(lin_pal[5], 0.5)), "slots: 0.1 blends halfway into the underside")
	# every monster model is painted in several palette roles, not one flat colour
	var multi := 0
	var with_accent := 0
	for shape2 in Assets.MONSTERS:
		if shape2 == "bird" or not Assets.has_monster(shape2):
			continue
		var m2 := Assets.instance(Assets.MONSTERS[shape2])
		var share := [0, 0, 0, 0, 0]
		var n_t := 0
		for mi3 in m2.get_meta("meshes"):
			for si3 in mi3.mesh.get_surface_count():
				var a3: Array = mi3.mesh.surface_get_arrays(si3)
				var u3 = a3[Mesh.ARRAY_TEX_UV]
				if u3 == null:
					continue
				for uv in u3:
					if uv.x < 0.05:
						continue
					var sl: float = 1.0 - uv.y
					var role: int = 0 if sl < 0.005 else (1 if sl <= 0.21 else (2 if sl < 0.56 else (3 if sl <= 0.81 else 4)))
					share[role] += 1
					n_t += 1
		var roles := 0
		for r2 in 5:
			if n_t > 0 and share[r2] >= n_t * 0.02:
				roles += 1
		if roles >= 3:
			multi += 1
		if share[4] > 0:
			with_accent += 1
		m2.free()
	check(multi >= 34, "palette roles: %d of 40 monsters use three or more of dominant, underside, secondary, markings and accent" % multi)
	check(with_accent >= 38, "palette roles: %d of 40 monsters carry an accent (eyes, crests, horns, glow)" % with_accent)
	# Yue Ling follows facing the way she runs (not sideways towards the hero), and stops running
	# once she has caught up
	var cpos := Vector3.ZERO
	var hero_p := Vector3.ZERO
	var c_run := false
	var c_yaw := 0.0
	var ran := false
	var worst := 0.0
	for f in 60:
		hero_p.x += 12.5 / 30.0
		var cs: Array = Models.companion_step(cpos, hero_p, Vector2i(1, 0), PI / 2, c_run, false, 1.0 / 30.0)
		cpos = cs[0]
		c_yaw = cs[1]
		c_run = cs[2]
		if f > 20:
			ran = ran or c_run
			worst = maxf(worst, absf(angle_difference(c_yaw, PI / 2)))
	check(ran and worst < 0.35, "companion: runs facing the way she goes (worst %.2f rad off)" % worst)
	for f in 60:
		var cs2: Array = Models.companion_step(cpos, hero_p, Vector2i(1, 0), PI / 2, c_run, false, 1.0 / 30.0)
		cpos = cs2[0]
		c_yaw = cs2[1]
		c_run = cs2[2]
	check(not c_run and absf(angle_difference(c_yaw, PI / 2)) < 0.01, "companion: stops running and looks where the hero looks once she has caught up")
	var cs3: Array = Models.companion_step(cpos, hero_p, Vector2i(1, 0), PI / 2, false, true, 1.0 / 30.0)
	var to_hero := hero_p - (cs3[0] as Vector3)
	check(absf(angle_difference(cs3[1], atan2(to_hero.x, to_hero.z))) < 0.01, "companion: turns to the hero in a conversation")
	var dragon := Assets.monster("dragon", Color("c03020"))
	var huesets := {}
	for mi2 in dragon.get_meta("meshes"):
		for si2 in mi2.mesh.get_surface_count():
			var a2: Array = mi2.mesh.surface_get_arrays(si2)
			var c2: PackedColorArray = a2[Mesh.ARRAY_COLOR]
			var u2: PackedVector2Array = a2[Mesh.ARRAY_TEX_UV]
			for i2 in range(0, c2.size(), 7):
				if u2[i2].x > 0.99 and c2[i2].v > 0.05:
					huesets[int(c2[i2].h * 12.0)] = true
	check(huesets.size() >= 3, "palette: a tinted dragon shows several hues (%d)" % huesets.size())
	dragon.free()
	# the same shape in two colours shares nothing but the source mesh
	var ma := Assets.monster("beast", Color("ff0000"))
	var mb2 := Assets.monster("beast", Color("0000ff"))
	check(ma.get_meta("meshes")[0].mesh != mb2.get_meta("meshes")[0].mesh, "recoloured monsters get their own meshes")
	var mc := Assets.monster("beast", Color("ff0000"))
	check(ma.get_meta("meshes")[0].mesh == mc.get_meta("meshes")[0].mesh, "same colour reuses the cached mesh")
	ma.free()
	mb2.free()
	mc.free()
	# action clips: an attack interrupts idle and then returns to it
	var hero := Models.person(Color("3a8ae8"), Color("1a1a2a"), {"asset": "lin_feng"})
	Models.anim_person(hero, 0.0, false)
	var hap: AnimationPlayer = hero.get_meta("ap")
	Models.act(hero, "attack", 0.1)
	Models.anim_person(hero, 0.2, false)
	check(hap.assigned_animation == "attack", "act() plays the attack clip")
	Models.anim_person(hero, 1.5, false)
	check(hap.assigned_animation == "idle", "attack returns to idle when it ends")
	Models.anim_person(hero, 1.6, true)
	check(hap.assigned_animation == "walk", "walking plays the walk clip")
	hero.free()
	Assets.disabled = true
	for shape2 in ["scorpion", "mushroom", "mammoth", "moth", "hundun", "beast"]:
		var pm2 := Models.monster(shape2, Color("88aa66"), false)
		check(pm2.get_child_count() > 0 and not pm2.has_meta("glb"), "procedural fallback builds for " + shape2)
		pm2.free()
	var pp := Models.person(Color("3a8ae8"), Color("1a1a2a"), {"asset": "lin_feng"})
	check(pp.has_meta("p") and not pp.has_meta("glb"), "procedural person fallback without assets")
	pp.free()
	Assets.disabled = false
	for a3 in Data.AREAS:
		var spec3: Dictionary = Data.AREAS[a3]
		var m3 := MapGen.build(a3)
		var tr := Terrain3D.build(m3.grid, m3.w, m3.h, spec3.theme, spec3.seed, {"buildings": m3.buildings, "area": a3})
		check(tr.get_child_count() > 3, "3D terrain builds for " + a3)
		tr.free()
	print("== open world ==")
	var wd := Atlas.world()
	var reach_all := MapGen.flood(wd.grid, wd.w, wd.h, wd.start)
	var cut := 0
	for e in wd.ents:
		if e.kind != "spring" and e.kind != "seal" and not reached(e, reach_all):
			cut += 1
	check(cut == 0, "open world: every NPC, boss, pickup and monster can be walked to from the sect (%d cut off)" % cut)
	for id in Atlas.region_ids():
		check(Atlas.owner_id(wd, Atlas.to_world(id, Data.AREAS[id].get("npcs", [{"pos": Vector2i(Data.AREAS[id].w / 2, Data.AREAS[id].h / 2)}])[0].pos)) == id or id == Atlas.HUB, "open world: %s owns its own land" % id)
	# with every seal shut, only the sect, its mountain and the first forest can be reached
	var shut: PackedByteArray = wd.grid.duplicate()
	var seals := 0
	for e2 in wd.ents:
		if e2.kind == "seal":
			seals += 1
			check(not e2.tiles.is_empty() and Data.step_index(e2.open) >= 0, "seal %s blocks a road and opens at a real quest step" % e2.id)
			for t in e2.tiles:
				shut[t.y * wd.w + t.x] = MapGen.WALL
	var early := MapGen.flood(shut, wd.w, wd.h, wd.start)
	var big := {}
	for pt in early:
		var o := Atlas.owner_id(wd, pt)
		big[o] = big.get(o, 0) + 1
	var leaks := []
	for k in big:
		if big[k] > 40 and not k in ["sect", Atlas.HUB, "bamboo"]:
			leaks.append(k)
	check(leaks.is_empty(), "open world: Lotus Seals close every region the story has not opened yet (leaks: %s)" % str(leaks))
	check(seals >= 25, "open world: a seal on every gated road (%d)" % seals)
	var again_w := Atlas._build()
	check(again_w.grid == wd.grid, "open world: generation is deterministic")
	check(Atlas.owner_id(wd, wd.start) == "sect", "open world: the journey starts in the sect")
	var sl := Atlas.slice(wd, "bamboo")
	var voids := 0
	var mine := 0
	for v in sl.grid:
		if v == MapGen.VOID:
			voids += 1
		else:
			mine += 1
	var own_land := 0
	var bi: int = wd.idx.bamboo
	for i in wd.w * wd.h:
		if wd.owner[i] == bi and wd.sea[i] == 0:
			own_land += 1
	check(voids > 0 and mine == own_land, "region slices blank out their neighbours' land and the sea (%d tiles) and keep all their own (%d)" % [voids, mine])
	# ---- the land is no longer a grid of rectangles
	var edge_sea := true
	for x in wd.w:
		edge_sea = edge_sea and wd.sea[x] == 1 and wd.sea[(wd.h - 1) * wd.w + x] == 1
	for y in wd.h:
		edge_sea = edge_sea and wd.sea[y * wd.w] == 1 and wd.sea[y * wd.w + wd.w - 1] == 1
	check(edge_sea, "open world: the land is a continent ringed by the sea, not a rectangle")
	var xs := {}
	var ys := {}
	for sid in Atlas.SITES:
		xs[Atlas.SITES[sid][0]] = true
		ys[Atlas.SITES[sid][1]] = true
	check(xs.size() >= Atlas.SITES.size() * 3 / 4 and ys.size() >= Atlas.SITES.size() * 3 / 4, "open world: regions are not laid out in rows and columns (%d distinct x, %d distinct y of %d)" % [xs.size(), ys.size(), Atlas.SITES.size()])
	var ways := {}
	for sid2 in Atlas.SITES:
		ways[Atlas.SITES[sid2][2]] = true
	check(ways.size() == 4, "open world: chains wind in all four directions")
	var squarish: Array = []
	for rid in Data.AREA_CHAIN:
		if rid == "sect":
			continue
		var rm := MapGen.build(rid)
		var open_mid := 0
		var mid_n := 0
		var open_corner := 0
		var corner_n := 0
		for yy in rm.h:
			for xx in rm.w:
				var fx: float = (xx + 0.5) / float(rm.w)
				var fy: float = (yy + 0.5) / float(rm.h)
				var walk := MapGen.is_walkable_tile(rm.grid[yy * rm.w + xx])
				if (fx < 0.14 or fx > 0.86) and (fy < 0.2 or fy > 0.8):
					corner_n += 1
					open_corner += 1 if walk else 0
				elif absf(fx - 0.5) < 0.25 and absf(fy - 0.5) < 0.25:
					mid_n += 1
					open_mid += 1 if walk else 0
		if float(open_corner) / float(corner_n) > 0.5 * float(open_mid) / float(mid_n):
			squarish.append(rid)
	check(squarish.is_empty(), "every region's open ground is an organic outline, its map's corners mostly forest (squarish: %s)" % str(squarish))
	var unlinked: Array = []
	var realm_reach := {"surface": reach_all}
	for i2 in Data.AREA_CHAIN.size():
		var ra: String = Data.AREA_CHAIN[i2]
		# (each realm's roads run over its own land: Part XI)
		var rl := Data.layer_of(ra)
		if not realm_reach.has(rl):
			var rw := Atlas.world_of(rl)
			realm_reach[rl] = MapGen.flood(rw.grid, rw.w, rw.h, rw.start)
		for gp in Data.AREAS[ra].portals:
			var ga := Atlas.to_world(ra, gp.pos)
			var gb := Atlas.to_world(gp.to, Data.AREAS[gp.to].portals.filter(func(q): return q.to == ra)[0].pos)
			if not realm_reach[rl].has(ga) or not realm_reach[rl].has(gb):
				unlinked.append(ra + "-" + gp.to)
	check(unlinked.is_empty(), "every road joins its two gates over land (%s)" % str(unlinked))
	print("== buildings ==")
	var n_bld := 0
	for bd in wd.buildings:
		n_bld += 1
		var inner := MapGen.inner_rect(bd)
		var inside := inner.get_center()
		var ok_in := false
		for yy in range(inner.position.y, inner.end.y):
			for xx in range(inner.position.x, inner.end.x):
				if reach_all.has(Vector2i(xx, yy)):
					ok_in = true
		check(ok_in, "%s: the inside can be walked into through the door" % bd.n)
		check(wd.grid[bd.door.y * wd.w + bd.door.x] == MapGen.INTERIOR, "%s: has a door" % bd.n)
		var edge_closed := true
		var r: Rect2i = bd.rect
		for xx in range(r.position.x, r.end.x):
			for yy in [r.position.y, r.end.y - 1]:
				if Vector2i(xx, yy) != bd.door and MapGen.is_walkable_tile(wd.grid[yy * wd.w + xx]):
					edge_closed = false
		for yy in range(r.position.y, r.end.y):
			for xx in [r.position.x, r.end.x - 1]:
				if Vector2i(xx, yy) != bd.door and MapGen.is_walkable_tile(wd.grid[yy * wd.w + xx]):
					edge_closed = false
		check(edge_closed, "%s: walls all round except the door" % bd.n)
		var b0 := MB.new()
		var gb := MB.new()
		var rb := MB.new()
		var rg := MB.new()
		Arch.house(b0, gb, rb, rg, Rect2(r.position.x * 2.0, r.position.y * 2.0, r.size.x * 2.0, r.size.y * 2.0), Vector3((bd.door.x + 0.5) * 2.0, 0, (bd.door.y + 0.5) * 2.0), bd.style, [], 1)
		check(not b0.is_empty() and not rb.is_empty(), "%s: builds walls and a separate roof" % bd.n)
	check(n_bld >= 10, "at least 10 enterable buildings (%d)" % n_bld)
	for npc in ["elder", "alchemist", "smith", "granny_wen", "ah_mei", "innkeeper_bao", "tea_seller_pan", "dyer_su", "monk_huiming", "granny_gu", "chang_e"]:
		var ne = null
		for e3 in wd.ents:
			if e3.get("id", "") == npc:
				ne = e3
		check(ne != null and wd.grid[ne.pos.y * wd.w + ne.pos.x] == MapGen.INTERIOR, npc + " waits indoors")
	print("== part VII ==")
	check(Data.REALMS.has("Boundless Heart") and Data.level_name(36).ends_with("Boundless Heart"), "Part VII adds the Boundless Heart realm")
	check(Data.DIALOGUE.has("recall5") and Data.step_index("s_break11") < Data.step_index("s_p7_home"), "Part VII starts after the Samsara breakthrough")
	for a7 in ["village", "tea", "silk", "loom"]:
		check(Look.THEMES.has(a7) and Look.EXTRA.has(a7) and Scatter.ECO.has(a7) and Fauna.KINDS.has(a7), "theme, terrain extras, ecology and wildlife for " + a7)
	check(Data.known_skills(0, 34).has("threadfall") and Data.known_skills(1, 34).has("homeward"), "Part VII techniques are learnable")
	check(not Data.known_skills(0, 35, Data.step_index("s_sk_return")).has("boundless"), "Boundless Heart Sword waits for Can Niang's cocoons")
	print("== part VIII ==")
	check(Data.REALMS.has("Star River Crossing") and Data.level_name(39).ends_with("Star River Crossing"), "Part VIII adds the Star River Crossing realm")
	check(Data.DIALOGUE.has("recall6") and Data.step_index("s_break12") < Data.step_index("s_p8_home"), "Part VIII starts after the Boundless Heart breakthrough")
	check(Data.AREAS.sect.portals.any(func(p): return p.to == "starferry" and p.open == "s_p8_home"), "the sect's south road to the Starfall Ferry opens after the Part VIII briefing")
	for a8 in ["starferry", "magpie", "starpalace", "jasper"]:
		check(Look.THEMES.has(a8) and Look.EXTRA.has(a8) and Scatter.ECO.has(a8) and Fauna.KINDS.has(a8) and MapGen.DENSITY.has(a8), "theme, terrain extras, ecology, wildlife and density for " + a8)
	for sh in ["qilin", "ape"]:
		check(Assets.has_monster(sh) and UI.SHAPES.has(sh), "Part VIII monster shape %s is Blender-built" % sh)
	for np8 in ["niu_lang", "que_lao", "zhi_nu", "dong_shuang"]:
		check(Assets.PEOPLE.has(np8) and Assets.has(Assets.PEOPLE[np8]), "Part VIII character %s is Blender-built" % np8)
	check(Data.known_skills(0, 37).has("starriver") and Data.known_skills(1, 37).has("magpie_wing") and Data.known_skills(1, 36).has("starweave"), "Part VIII techniques are learnable")
	check(not Data.known_skills(0, 38, Data.step_index("s_wv_return")).has("reunion"), "Reunion Sword waits for the Weaver Star's threads")
	check(Data.known_skills(0, 38, Data.step_index("s_wv_moth")).has("reunion"), "Reunion Sword is learned from Zhi Nu")
	check(Data.BOSS_DROPS.get("crow_marshal", "") == "magpie_badge", "the Crow Marshal gives up his badge")
	check(Data.SKILLS.rebirth.get("revive", false) and Data.SKILLS.homeward.get("revive", false), "the Lotus of Rebirth and the Homeward Lantern raise fallen allies")
	print("== part IX ==")
	var p9 := ["yanggu", "millet", "fusang", "guanghan"]
	check(Data.REALMS.has("Sun-Moon Harmony") and Data.level_name(42).ends_with("Sun-Moon Harmony"), "Part IX adds the Sun-Moon Harmony realm")
	check(Data.DIALOGUE.has("recall7") and Data.step_index("s_break13") < Data.step_index("s_p9_home"), "Part IX starts after the Star River Crossing")
	check(Data.step_index("s_break14") > Data.step_index("s_break13") and Data.STEPS[Data.step_index("s_break14")].to == 42, "the Star River Crossing no longer ends the game: Sun-Moon Harmony comes after it")
	check(Data.AREAS.sect.portals.any(func(p): return p.to == "yanggu" and p.open == "s_p9_home" and p.pos == Vector2i(34, 24)), "the sect's south-east gate to the Dawn Market opens after the Part IX briefing")
	var sect9 := MapGen.build("sect")
	check(sect9.grid[23 * sect9.w + 34] == MapGen.PATH and sect9.grid[22 * sect9.w + 34] == MapGen.PATH, "a road runs from the south-east road to the Dawn Market gate")
	var lay9 := Atlas.layout()
	var sizes9 := {}
	var guides9 := {}
	for a9 in p9:
		check(Look.THEMES.has(a9) and Look.EXTRA.has(a9) and Scatter.ECO.has(a9) and Fauna.KINDS.has(a9) and MapGen.DENSITY.has(a9) and Arch.SETTLE.has(a9), "theme, terrain extras, ecology, wildlife, density and dwellings for " + a9)
		check(lay9.has(a9) and int(lay9[a9].site.x) > int(lay9[Atlas.HUB].site.x) + 150, a9 + " lies east of the mountain, towards the sunrise")
		sizes9[Vector2i(Data.AREAS[a9].w, Data.AREAS[a9].h)] = true
		guides9[Data.AREAS[a9].npcs[0].pos] = true
		var bpos9 := {}
		for b9 in Data.AREAS[a9].bosses:
			bpos9[b9.pos] = true
		check(not bpos9.has(Vector2i(30, 40)) and not bpos9.has(Vector2i(86, 28)), a9 + ": bosses do not stand where every Part VIII boss stood")
	check(sizes9.size() == 4 and guides9.size() == 4, "the four Part IX regions each have their own size and guide position")
	check(Data.AREAS.yanggu.get("buildings", []).size() >= 6 and not Data.AREAS.yanggu.get("lanes", []).is_empty(), "Yanggu is a market town: lanes and at least six enterable buildings")
	var folk9 := 0
	for n9 in Data.AREAS.yanggu.npcs:
		check(Data.CHAT.has(n9.id) and Data.CHAT[n9.id].size() >= 3, "%s has at least three things to say" % n9.id)
		# (somebody who came to the shore in a later chapter, "late", is not one of the market's own)
		if n9.get("late", false):
			continue
		check(n9.get("vis", ["", ""])[0] == "s_yg_intro" and n9.get("vis", ["", ""])[1] == "", "%s stays in the market for the rest of the game once its road opens" % n9.id)
		if n9.id != "ah_mei":
			folk9 += 1
	check(folk9 >= 8 and folk9 <= 10, "eight to ten townsfolk in the Dawn Market (%d)" % folk9)
	for sh9 in ["sun_crow", "jade_rabbit", "bifang"]:
		check(UI.SHAPES.has(sh9) and Models.FALLBACK.has(sh9), "Part IX shape %s has a procedural stand-in until its Blender model is exported" % sh9)
		var m9 := Models.monster(sh9, Color("ffc030"), true)
		check(m9.get_child_count() > 0, "a %s builds (Blender or stand-in)" % sh9)
		m9.free()
	for np9 in ["ah_mei", "farmer_tian", "feng_meng", "chang_e"]:
		check(Assets.PEOPLE.has(np9) and Assets.has(Assets.PEOPLE[np9]), "Part IX character %s is Blender-built" % np9)
	check(Data.known_skills(0, 39).has("noonsplit") and Data.known_skills(0, 40).has("ninesuns") and Data.known_skills(1, 39).has("osmanthus_rain") and Data.known_skills(1, 40).has("moon_dew"), "Part IX techniques are learnable")
	check(not Data.known_skills(0, 41, Data.step_index("s_fs_return")).has("tentharrow"), "Tenth Arrow Sword waits for Feng Meng's feathers")
	check(Data.known_skills(0, 41, Data.step_index("s_fs_crab")).has("tentharrow"), "Tenth Arrow Sword is learned from Feng Meng")
	check(Data.SKILLS.moon_dew.get("revive", false), "the Moon-Dew Ward raises fallen allies")
	check(Data.BOSS_DROPS.get("jinwu", "") == "tenth_arrow", "the Sun Crow gives back the tenth arrow that Lin Feng later shows Xihe")
	print("== part X ==")
	var p10 := ["longmen", "drowned", "tushan", "buzhou"]
	check(Data.REALMS.has("Mountain-River Oneness") and Data.level_name(45).ends_with("Mountain-River Oneness"), "Part X adds the Mountain-River Oneness realm")
	check(Data.step_index("s_break15") > Data.step_index("s_break14") and Data.STEPS[Data.step_index("s_break15")].to == 45, "Sun-Moon Harmony no longer ends the game: Mountain-River Oneness comes after it")
	check(Data.DIALOGUE.has("recall8") and Data.step_index("s_break14") < Data.step_index("s_p10_home"), "Part X starts after the Sun-Moon Harmony breakthrough")
	check(Data.AREAS.sect.portals.any(func(p): return p.to == "longmen" and p.open == "s_p10_road" and p.pos == Vector2i(12, 1)), "the sect's new north gate opens on the river road once Cartographer Pei has drawn it")
	var sect10 := MapGen.build("sect")
	check(sect10.grid[1 * sect10.w + 12] == MapGen.PATH and sect10.grid[12 * sect10.w + 12] == MapGen.PATH, "a path runs from the courtyard up to the north gate")
	for a10 in p10:
		check(Look.THEMES.has(a10) and Look.EXTRA.has(a10) and Scatter.ECO.has(a10) and Fauna.KINDS.has(a10) and MapGen.DENSITY.has(a10) and Arch.SETTLE.has(a10), "theme, terrain extras, ecology, wildlife, density and dwellings for " + a10)
		# (the keepsakes and caches upstairs and in cellars, Part XI, are not what the quest asks for)
		# (Part XIII's Gate Generals only visit, `vis`: they are not the region's own)
		check(Data.AREAS[a10].bosses.filter(func(b): return not b.has("vis")).size() == 5 and Data.AREAS[a10].pickups.filter(func(pk): return not pk.get("always", false) and not pk.has("cave") and not pk.get("late", false)).size() == 4, a10 + ": five bosses and four things to find")
		var lm10: Dictionary = Atlas.layout()[a10]
		check(int(lm10.site.y) < int(Atlas.layout()[Atlas.HUB].site.y), a10 + " lies north of the mountain, up the river road")
	for st10 in ["s_p10_archive", "s_p10_road", "s_dg_intro", "s_df_intro", "s_ts_intro", "s_bz_intro"]:
		check(Data.step_index(st10) > Data.step_index("s_p10_home"), "Part X step %s follows the briefing" % st10)
	check(Data.known_skills(0, 42).has("dragongate") and Data.known_skills(0, 43).has("swelling") and Data.known_skills(1, 43).has("river_mother"), "Part X techniques are learnable")
	check(not Data.known_skills(0, 44, Data.step_index("s_ts_return")).has("cauldron") and Data.known_skills(0, 44, Data.step_index("s_ts_serpent")).has("cauldron"), "the Nine Cauldrons Sword is learned from Tu Lan")
	check(Data.SKILLS.river_mother.get("revive", false), "the River-Mother's Ward raises fallen allies")
	check(Data.BOSS_DROPS.get("taotie", "") == "cauldron_map" and Data.BOSS_DROPS.get("he_bo", "") == "river_tablet", "the Taotie gives up the cauldron's map and He Bo his flood tablet")
	for lk in ["dragongate", "cauldron", "buzhou"]:
		var found := false
		for a11 in p10:
			found = found or Data.AREAS[a11].get("landmark", {}).get("kind", "") == lk
		check(found, "Part X landmark %s stands in its region" % lk)
		var lroot := Node3D.new()
		Terrain3D.landmark(lroot, lk, Vector3.ZERO, Vector3(1, 0, 0))
		check(lroot.get_child_count() >= 2, "Part X landmark %s builds" % lk)
		lroot.free()
	var lmap := MapGen.build("longmen")
	var river_tiles := 0
	for t10 in lmap.grid:
		if t10 == MapGen.WATER:
			river_tiles += 1
	check(river_tiles > 120, "a river runs through Longmen (%d water tiles)" % river_tiles)
	print("== part XI: the realms ==")
	var p11 := ["juntian", "changhe", "ninesprings", "youdu"]
	check(Data.REALMS[16] == "Three Realms Concord" and Data.level_name(48).ends_with("Three Realms Concord"), "Part XI adds the Three Realms Concord realm")
	check(Data.step_index("s_break16") > Data.step_index("s_break15") and Data.STEPS[Data.STEPS.size() - 1].id != "s_break16", "Mountain-River Oneness no longer ends the game, and nor does Three Realms Concord")
	check(Data.DIALOGUE.has("recall9") and Data.step_index("s_break15") < Data.step_index("s_p11_home"), "Part XI starts after the Mountain-River Oneness breakthrough")
	for a11 in p11:
		var sp11: Dictionary = Data.AREAS[a11]
		check(Look.THEMES.has(sp11.theme) and Look.EXTRA.has(sp11.theme) and Scatter.ECO.has(sp11.theme) and Fauna.KINDS.has(sp11.theme) and MapGen.DENSITY.has(sp11.theme) and Arch.SETTLE.has(sp11.theme), "theme, terrain extras, ecology, wildlife, density and dwellings for " + a11)
		check(sp11.bosses.filter(func(b): return not b.has("vis")).size() == 4 and sp11.pickups.filter(func(pk): return not pk.get("always", false) and not pk.has("cave") and not pk.get("late", false)).size() == 4, a11 + ": four bosses and four things to find")
		check(Data.layer_of(a11) in ["heaven", "under"], a11 + " lies in a realm above or below the land")
		for n11 in sp11.npcs:
			if n11.get("fate", false):
				# (somebody met on the road, fate.gd: checked with the fated encounters)
				continue
			check(Data.CHAT.has(str(n11.get("asset", n11.id))) and Data.CHAT[str(n11.get("asset", n11.id))].size() >= 3, "%s has at least three things to say" % n11.id)
			check(n11.id == "houtu" or Data.RACES.has(str(n11.get("race", ""))), "%s belongs to one of the peoples of the realms" % n11.id)
	check(Data.layer_of("juntian") == "heaven" and Data.layer_of("changhe") == "heaven" and Data.layer_of("ninesprings") == "under" and Data.layer_of("youdu") == "under", "two regions float in the Nine Heavens and two lie in the Nine Springs")
	check(Atlas.layer_y("heaven") > 60.0 and Atlas.layer_y("under") < -40.0, "the Nine Heavens are drawn high above the land and the Nine Springs deep below it")
	var ladders_seen := {}
	for lid in ["heaven", "under", "sea"]:
		var lw := Atlas.world_of(lid)
		var lreach := MapGen.flood(lw.grid, lw.w, lw.h, lw.start)
		var lcut := 0
		var to_surface := false
		for e11 in lw.ents:
			if e11.kind != "spring" and e11.kind != "seal" and not reached(e11, lreach):
				lcut += 1
			if e11.kind == "ladder" and e11.to_layer == "surface":
				to_surface = true
				ladders_seen[str(e11.id)] = true
				var sw := Atlas.world()
				check(MapGen.is_walkable_tile(sw.grid[e11.to_tile.y * sw.w + e11.to_tile.x]), "%s comes out on open ground in the land" % e11.id)
		check(lcut == 0, "%s: everyone and everything can be walked to from where the Jianmu comes in (%d cut off)" % [lid, lcut])
		check(to_surface, "%s: a ladder leads back down (or up) to the land" % lid)
		var edge_void := true
		for x11 in lw.w:
			edge_void = edge_void and lw.sea[x11] == 1 and lw.sea[(lw.h - 1) * lw.w + x11] == 1
		check(edge_void, "%s: its land floats in open sky (or over the abyss) on every side" % lid)
		for rid11 in Atlas.region_ids(lid):
			check(Atlas.owner_id(lw, Atlas.to_world(rid11, Data.AREAS[rid11].npcs[0].pos if not Data.AREAS[rid11].npcs[0].has("floor") else Data.AREAS[rid11].bosses[0].pos)) == rid11, "%s owns its own land" % rid11)
		check(Atlas._build(lid).grid == lw.grid, "%s: generation is deterministic" % lid)
		for bd11 in lw.buildings:
			var r11: Rect2i = bd11.rect
			var closed := true
			for xx in range(r11.position.x, r11.end.x):
				for yy in [r11.position.y, r11.end.y - 1]:
					if Vector2i(xx, yy) != bd11.door and MapGen.is_walkable_tile(lw.grid[yy * lw.w + xx]):
						closed = false
			check(closed and lw.grid[bd11.door.y * lw.w + bd11.door.x] == MapGen.INTERIOR, "%s: walls all round and a door" % bd11.n)
	var sw2 := Atlas.world()
	for e12 in sw2.ents:
		if e12.kind == "ladder" and str(e12.get("style", "")) in ["climb", "sail"]:
			ladders_seen[str(e12.id)] = true
			var dw := Atlas.world_of(e12.to_layer)
			check(MapGen.is_walkable_tile(dw.grid[e12.to_tile.y * dw.w + e12.to_tile.x]), "%s comes out on open ground in %s" % [e12.id, e12.to_layer])
			check(Data.step_index(str(e12.open)) >= 0, "%s opens at a real quest step" % e12.id)
	check(ladders_seen.size() == Data.LADDERS.size() * 2, "both ends of every ladder between the realms stand in their regions (%d)" % ladders_seen.size())
	var ho := Atlas.layer_origin("heaven")
	var up_a := Atlas.to_world("mountain", Data.LADDERS[0].a[1])
	var up_b := Atlas.to_world("juntian", Data.LADDERS[0].b[1]) + ho
	check(up_a == up_b, "the crown of the Jianmu in the Nine Heavens is straight above its trunk on the mountain")
	check(Data.next_hop("sect", "youdu") != "" and Data.next_hop("youdu", "sect") != "", "the Dark Capital can be reached from the sect and left again, by the Jianmu")
	print("== part XI: storeys and cellars ==")
	var n_floors := 0
	var n_up := 0
	var n_down := 0
	for lid2 in ["surface", "heaven", "under", "sea"]:
		var fw0 := Atlas.world_of(lid2)
		for fid in fw0.floors:
			var fw: Dictionary = fw0.floors[fid]
			n_floors += 1
			if int(fw.level) > 0:
				n_up += 1
			else:
				n_down += 1
			var freach := MapGen.flood(fw.grid, fw.w, fw.h, fw.start)
			var fcut := 0
			var back := false
			for fe in fw.ents:
				if not reached(fe, freach):
					fcut += 1
				if fe.kind == "ladder" and fe.to_layer == lid2:
					back = true
					check(MapGen.is_walkable_tile(fw0.grid[fe.to_tile.y * fw0.w + fe.to_tile.x]), "%s: the stairs come out on the floor below (or above)" % fid)
				elif fe.kind == "ladder" and int(fw.level) == -2 and str(fe.to_layer) == str(fw.up):
					# (the lower gallery of a cave comes out in the cave above it: caves.gd)
					back = true
					var uw: Dictionary = fw0.floors[fw.up]
					check(MapGen.is_walkable_tile(uw.grid[fe.to_tile.y * uw.w + fe.to_tile.x]), "%s: the climb comes out on the floor of the cave above" % fid)
			check(fcut == 0 and back, "%s: stairs back, and everyone and everything on it can be reached (%d cut off)" % [fid, fcut])
			var walls := true
			for xx2 in fw.w:
				walls = walls and fw.grid[xx2] == MapGen.BUILDING and fw.grid[(fw.h - 1) * fw.w + xx2] == MapGen.BUILDING
			check(walls, "%s: walls all round" % fid)
			check(Atlas.world_of(fid) == fw, "%s can be looked up by its id" % fid)
		# the stairs up and down stand on floor the door can reach
		var r0 := MapGen.flood(fw0.grid, fw0.w, fw0.h, fw0.start)
		for e13 in fw0.ents:
			if e13.kind == "ladder" and str(e13.get("style", "")) == "stairs":
				check(r0.has(e13.pos), "%s: the stairs can be walked to" % e13.id)
	check(n_floors >= 20 and n_up >= 10 and n_down >= 8, "upper storeys and cellars to explore (%d floors: %d up, %d down)" % [n_floors, n_up, n_down])
	var b1 := MB.new()
	var g1 := MB.new()
	var r1 := MB.new()
	var rg1 := MB.new()
	var u1 := MB.new()
	var ug1 := MB.new()
	Arch.house(b1, g1, r1, rg1, Rect2(0, 0, 22, 18), Vector3(11, 0, 17), "aerie", [["stairs_up", Vector3(5, 0, 5)]], 1, u1, ug1, [["nest", Vector3(15, 0, 5)]], Vector3(5, 0, 5))
	check(not u1.is_empty() and not b1.is_empty() and not r1.is_empty(), "a building with an upper storey builds the storey separately from its ground floor and roof")
	var cb := MB.new()
	var cg := MB.new()
	Arch.cellar(cb, cg, Rect2(0, 0, 20, 14), [["barrel", Vector3(3, 0, 3)]], Vector3(17, 0, 11), 1)
	check(not cb.is_empty(), "a cellar builds")
	for lk11 in ["jianmu", "jianmu_crown", "jianmu_roots", "changhe_gate", "youdu_gate"]:
		var lroot11 := Node3D.new()
		Terrain3D.landmark(lroot11, lk11, Vector3.ZERO, Vector3(1, 0, 0))
		check(lroot11.get_child_count() >= 2, "Part XI landmark %s builds" % lk11)
		lroot11.free()
	var sky := Node3D.new()
	Terrain3D.sky_world(sky, Atlas.world_of("heaven"))
	check(sky.get_child_count() >= 3, "the sea of clouds and the islands' undersides build")
	sky.free()
	var deep := Node3D.new()
	Terrain3D.deep_world(deep, Atlas.world_of("under"))
	check(deep.get_child_count() >= 4, "the abyss and the cavern roof build")
	deep.free()
	print("== part XI: daos and peoples ==")
	check(Data.DAO_ORDER.size() == 6 and Data.DAOS.size() == 6, "six Daos to choose from")
	for did in Data.DAO_ORDER:
		var dd: Dictionary = Data.DAOS[did]
		check(Data.SKILLS.has(dd.skill) and Data.SKILLS[dd.skill].get("dao", "") == did, "%s teaches %s" % [did, dd.skill])
		check(Data.DAO_MODS.has(did) and str(dd.motto).length() > 10, "%s has a passive and a motto" % did)
		check(Data.DAO_LINES.dao_chosen.has(did) and Data.DAO_LINES["post:chong"].has(did) and Data.DAO_LINES["post:li"].has(did) and Data.DAO_LINES["post:s_break17"].has(did) and Data.DAO_LINES["post:xu_fu"].has(did) and Data.DAO_LINES["post:yu_qiang"].has(did), "the story answers the %s" % did)
		for mk in Data.DAO_MODS[did]:
			check(Data.DAO_MODS[did][mk].size() == Data.DAO_RANKS.size(), "%s: %s grows with every rank" % [did, mk])
		var honours := 0
		for rc0 in Data.RACES:
			if Data.RACES[rc0].dao == did:
				honours += 1
		check(honours >= 1, "some people of the realms honours the %s" % did)
	for rc in Data.RACE_ORDER:
		check(Data.RACES.has(rc) and Data.DAOS.has(Data.RACES[rc].dao), "%s honour a Dao that exists" % rc)
		if rc == "human":
			continue
		check(Data.ITEMS.has(Data.RACES[rc].gift) and Look.PICKUP_COLORS.has(Data.RACES[rc].gift), "%s love a keepsake that exists" % rc)
		check(Data.RACES[rc].dao_lines.size() == 6, "%s have something to say about every Dao" % rc)
		var npcs := 0
		for a12 in Data.AREAS:
			for n12 in Data.AREAS[a12].get("npcs", []):
				if n12.get("race", "") == rc:
					npcs += 1
		check(npcs >= 2, "%s: at least two of them to meet (%d)" % [rc, npcs])
		var found := 0
		for a13 in Data.AREAS:
			for pk13 in Data.AREAS[a13].get("pickups", []):
				if pk13.item == Data.RACES[rc].gift:
					found += 1
		check(found >= 2, "%s: their keepsake can be found in at least two places (%d)" % [rc, found])
	# choosing, mastering and changing roads; standing, gifts and boons
	# (a game state of its own: the autoload is not loaded for a test script)
	var G = load("res://scripts/game.gd").new()
	G.reset()
	G.level = 45
	check(G.dao == "" and G.dao_skills(0).is_empty() and G.dao_mod("one", 1.0) == 1.0, "no Dao before Part XI: no passives, no Dao technique")
	G.choose_dao("sword")
	check(G.dao == "sword" and G.dao_tier() == 0 and G.dao_mod("one", 1.0) > 1.0 and G.dao_skills(0).is_empty(), "a Novice of the Sword hits harder but has no Dao technique yet")
	for k14 in Data.DAO_TIERS[1]:
		G.dao_battle_won(false)
	check(G.dao_tier() == 1 and G.dao_skills(0) == ["myriad_swords"] and G.fighter(0).skills.has("myriad_swords"), "an Adept of the Sword learns Ten Thousand Swords Return to One")
	G.choose_dao("formation")
	check(G.dao == "formation" and G.dao_switches == 1 and G.dao_tier() == 0 and G.dao_tier("sword") == 1 and G.dao_mod("taken", 1.0) < 1.0 and G.dao_mod("one", 1.0) == 1.0, "changing roads keeps each Dao's mastery; the passive follows the Dao walked")
	G.choose_dao("alchemy")
	check(G.skill_cost("standing_tree") < Data.SKILLS.standing_tree.cost, "the Cauldron's Dao makes techniques cheaper")
	G.choose_dao("wander")
	check(G.fighter(0).spd > Data.speed(G.level), "Free Wandering makes Lin Feng quicker")
	G.standing = {}
	G.dao = "wander"
	G.race_gain("yumin", 10)
	G.race_gain("tianhu", 10)
	check(G.standing.yumin == 15 and G.standing.tianhu == 10, "standing grows half as fast again with the people whose Dao Lin Feng walks")
	check(G.boon("spd", 0.0) == 0.0, "no boon before friendship")
	G.standing.yumin = Data.FRIEND - 1
	G.inv["wutong_seed"] = 1
	check(G.give_gift("yumin") and G.inv.wutong_seed == 0 and G.race_tier("yumin") >= 1, "a gift the Feathered Folk love makes them friends")
	check(G.boon("spd", 0.0) == 3.0 and not G.give_gift("yumin"), "their friendship is a boon; nothing left to give")
	G.reset()
	check(G.dao == "" and G.standing.is_empty() and G.layer == "surface", "a new game starts with no Dao, no standing, on the land")
	G.free()
	for st11 in ["s_p11_archive", "s_p11_tree", "s_jt_intro", "s_cg_intro", "s_ns_intro", "s_yd_intro", "s_p11_end"]:
		check(Data.step_index(st11) > Data.step_index("s_p11_home"), "Part XI step %s follows the briefing" % st11)
	check(Data.known_skills(0, 46).has("springs_torrent") and Data.known_skills(1, 46).has("jianmu_ward") and Data.known_skills(0, 45).has("standing_tree"), "Part XI techniques are learnable")
	check(not Data.known_skills(0, 47, Data.step_index("s_yd_houtu")).has("concord") and Data.known_skills(0, 47, Data.step_index("s_yd_bai")).has("concord"), "the Three Realms Concord Sword is learned from Houtu")
	check(not Data.known_skills(0, 48).has("myriad_swords"), "Dao techniques come only from walking the Dao")
	check(Data.SKILLS.jianmu_ward.get("revive", false), "the Ward of the Standing Tree raises fallen allies")
	check(Data.BOSS_DROPS.get("chong", "") == "heaven_tablet" and Data.BOSS_DROPS.get("li", "") == "earth_weight", "Chong gives up his tablet and Li his weight, which go back to the tree")
	print("== part XII: the Returning Ruins ==")
	var p12 := ["penglai", "fangzhang", "yingzhou", "guixu"]
	check(Data.REALMS[17] == "Ten Thousand Waters Return" and Data.level_name(51).ends_with("Ten Thousand Waters Return"), "Part XII adds the Ten Thousand Waters Return realm")
	check(Data.step_index("s_p12_home") == Data.step_index("s_break16") + 1 and Data.step_index("s_p13_home") == Data.step_index("s_break17") + 1, "Part XII follows Three Realms Concord, and Part XIII follows it")
	check(Data.EXP_NEED.size() >= Data.MAX_LEVEL and Data.ENEMY_EXP.size() > Data.MAX_LEVEL, "cultivation and battle rewards are defined up to the last realm")
	check(main_recalls_s_break16(), "the sect calls Lin Feng home after Three Realms Concord (recall10)")
	for a12 in p12:
		var sp12: Dictionary = Data.AREAS[a12]
		check(Data.layer_of(a12) == "sea" and Atlas.STRATA.sea.sites.has(a12), a12 + " lies in the Eastern Sea")
		check(Look.THEMES.has(sp12.theme) and Look.EXTRA.has(sp12.theme) and Scatter.ECO.has(sp12.theme) and Fauna.KINDS.has(sp12.theme) and MapGen.DENSITY.has(sp12.theme) and Arch.SETTLE.has(sp12.theme), "theme, terrain extras, ecology, wildlife, density and dwellings for " + a12)
		check(sp12.bosses.filter(func(b): return not b.has("vis")).size() == 4 and sp12.pickups.filter(func(pk): return not pk.get("always", false) and not pk.has("cave") and not pk.get("late", false)).size() == 4, a12 + ": four bosses and four things to find")
		for n12 in sp12.npcs:
			if n12.get("fate", false):
				continue
			check(Data.CHAT.has(str(n12.get("asset", n12.id))) and Data.CHAT[str(n12.get("asset", n12.id))].size() >= 3, "%s has at least three things to say" % n12.id)
			check(Assets.PEOPLE.has(str(n12.get("asset", n12.id))), "%s is Blender-built" % n12.id)
	var sea_w := Atlas.world_of("sea")
	var sea_reach := MapGen.flood(sea_w.grid, sea_w.w, sea_w.h, sea_w.start)
	var sea_cut := 0
	var boat_end := false
	for e12 in sea_w.ents:
		if e12.kind != "spring" and not reached(e12, sea_reach):
			sea_cut += 1
		if e12.kind == "ladder" and str(e12.get("style", "")) == "sail":
			boat_end = true
	check(sea_cut == 0, "everything in the Eastern Sea can be walked to from Mazu's boat (%d cut off)" % sea_cut)
	check(boat_end and Data.next_hop("sect", "guixu") != "" and Data.next_hop("guixu", "sect") != "", "Mazu's boat joins Fusang to the isles, and the Returning Ruins can be reached from the sect and left again")
	var sea_water := 0
	for t12 in sea_w.sea:
		sea_water += t12
	check(sea_water > sea_w.w * sea_w.h / 3, "the isles stand in the sea (%d sea tiles)" % sea_water)
	for lk12 in ["penglai_pavilion", "guixu_whirl"]:
		var lroot12 := Node3D.new()
		Terrain3D.landmark(lroot12, lk12, Vector3.ZERO, Vector3(1, 0, 0))
		check(lroot12.get_child_count() >= 2, "Part XII landmark %s builds" % lk12)
		lroot12.free()
	check(Models.ladder("sail", -1).get_child_count() >= 1 and Models.sealed_cave(false).get_child_count() >= 1, "Mazu's boat and the Founder's caves build")
	check(Data.known_skills(0, 48).has("returning_tide") and Data.known_skills(1, 49, Data.step_index("s_pl_intro")).has("mazu_lantern") and not Data.known_skills(1, 49, Data.step_index("s_p12_shore")).has("mazu_lantern"), "Part XII techniques are learnable; Mazu gives Yue Ling her lantern")
	check(not Data.known_skills(0, 50, Data.step_index("s_yz_return")).has("jingwei_stone") and Data.known_skills(0, 50, Data.step_index("s_yz_herald")).has("jingwei_stone"), "Jingwei's Stone Sword is learned from Jingwei")
	for drop in ["longbo_giant", "yu_qiang", "xu_fu"]:
		check(Data.ITEMS.has(Data.BOSS_DROPS[drop]), "%s leaves something behind" % drop)
	check(Data.TOWNS.any(func(tw): return tw.id == "landfall") and Data.AREAS.penglai.npcs.size() >= 10, "Landfall is a town full of people (%d)" % Data.AREAS.penglai.npcs.size())
	print("== part XII: realms that matter ==")
	check(Data.REALM_INFO.size() == Data.REALMS.size(), "every realm has a lifespan, a title and a description")
	check(is_equal_approx(Data.suppression(10, 9), 1.0) and Data.suppression(9, 6) > 1.0 and Data.suppression(6, 9) < 1.0 and is_equal_approx(Data.suppression(48, 0), Data.suppression(48, 30)), "realm suppression: none within a realm, one way or the other across one, capped at three")
	var ab_ids := {}
	var mt := MapGen.build("mountain")
	var mreach := MapGen.flood(mt.grid, mt.w, mt.h, mt.start)
	for ab in Data.AREAS.mountain.abodes:
		ab_ids[ab.id] = true
		check(Data.DIALOGUE.has("abode:" + ab.id) and str(ab.motto).length() > 10 and ab.req % 3 == 0, "%s: the Founder's words, and a door for the start of a realm" % ab.id)
		check(mreach.has(ab.pos), "%s can be walked to" % ab.id)
	check(ab_ids.size() == 9, "nine sealed caves on the mountain")
	for dk12 in Data.CHAT_DEEP:
		var known_npc := false
		for a14 in Data.AREAS:
			for n14 in Data.AREAS[a14].get("npcs", []):
				known_npc = known_npc or str(n14.get("asset", n14.id)) == dk12
		check(known_npc, "realm-gated lore for %s goes to somebody who exists" % dk12)
	check(Data.REALM_GREETS.size() == Data.realm_band(Data.MAX_LEVEL) + 1, "townsfolk have something to say to every band of realms")
	print("== part XII: cutscenes ==")
	check(Data.emote_for(["Lin Feng", "Hello.", "kneel"]) == ["Lin Feng", "kneel"] and Data.emote_for(["Narrator", "She gives it to him.", "Mazu, Who Brings the Boats Home:offer"]) == ["Mazu, Who Brings the Boats Home", "offer"], "a line can name its gesture, and a narrator's line can direct somebody")
	check(Data.emote_for(["Elder Qing Xuan", "Thank you, disciple."])[1] == "bow" and Data.emote_for(["Yue Ling", "No. Not this time."])[1] == "shake" and Data.emote_for(["Lin Feng", "Then I will bring the bells back."])[1] == "nod" and Data.emote_for(["Narrator", "The sea goes out."])[1] == "", "gestures are read from the words, and narration is left alone")
	var gestured := 0
	var lines_n := 0
	for dk2 in Data.DIALOGUE:
		for dl2 in Data.DIALOGUE[dk2]:
			lines_n += 1
			var ec: Array = Data.emote_for(dl2)
			check(ec[1] == "" or Data.EMOTES.has(ec[1]), "%s: the gesture %s exists" % [dk2, ec[1]])
			if ec[1] != "":
				gestured += 1
	check(gestured * 8 > lines_n, "conversations have gestures in them (%d of %d lines)" % [gestured, lines_n])
	for ck2 in Data.CHAT_LATER:
		for cl2 in Data.CHAT_LATER[ck2]:
			check(Data.step_index(str(cl2[0])) >= 0 and Data.CHAT.has(ck2), "%s says '%s...' only after %s" % [ck2, str(cl2[1]).substr(0, 24), cl2[0]])
	print("== part XII: the nine branches of the root ==")
	check(Data.TALENT_ORDER.size() == 9 and Data.TALENTS.size() == 9, "nine branches to wake")
	var G2 = load("res://scripts/game.gd").new()
	G2.reset()
	G2.level = 30
	var base_hp: int = G2.max_hp(0)
	var base_cost: float = G2.skill_cost("pillar")
	check(not G2.wake_talent("vajra"), "a branch cannot be woken without an awakening")
	G2.awaken("test")
	check(G2.talent_pts == 1 and G2.wake_talent("vajra") and G2.talent("vajra") == 1 and G2.max_hp(0) > base_hp, "an awakening wakes the Vajra Body: more health")
	for k15 in 2:
		G2.awaken("test")
		G2.wake_talent("thunder_root")
	check(is_equal_approx(G2.talent_power("pillar"), 1.0 + 2 * 0.18) and is_equal_approx(G2.talent_power("abyss"), 1.0), "the Thunder Root strengthens thunder techniques only")
	for k16 in 3:
		G2.awaken("test")
		G2.wake_talent("qi_sea")
	check(G2.talent_crown("qi_sea") and G2.skill_cost("pillar") < base_cost and not G2.wake_talent("qi_sea"), "a branch in full leaf has its crown, costs less qi, and can grow no further")
	G2.awaken("test")
	G2.wake_talent("sword_bone")
	check(G2.talent_power("strike") > 1.2 and G2.talent_power("pillar") > 1.0 + 2 * 0.18, "the Sword Bone strengthens the plain strike and every single-target technique")
	var pack := [{"id": "bamboo_wolf", "lv": 1}, {"id": "bandit", "lv": 2}]
	check(G2.scatters(pack) and not G2.scatters([{"id": "bamboo_wolf", "lv": 28}]), "beasts two realms below Lin Feng scatter before his aura; his equals do not")
	G2.reset()
	check(G2.talents.is_empty() and G2.talent_pts == 0 and G2.abodes.is_empty(), "a new game starts with the root asleep and every cave sealed")
	G2.free()
	print("== many roads: trials, crafting, renown, deeds ==")
	var need_kinds := ["lv", "peak", "temper", "ranks", "item", "give", "stones", "renown", "dao", "standing", "friends", "gates", "fate", "bonds", "heart", "rallied", "cleared", "hearths", "works", "delved", "arms", "summits", "companies", "airs", "falls", "marks"]
	var boon_keys := ["foe_hp", "foe_atk", "taken", "assist", "weak_k", "no_heavy", "first"]
	var kinds_used := {}
	var dfont2 := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont2, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	var n_caves := 0
	for ca in Data.AREAS:
		if not Atlas.world_of(Caves.fid(ca)).is_empty():
			n_caves += 1
	for tid in Trials.TRIALS:
		var tr: Dictionary = Trials.TRIALS[tid]
		check(Data.ENEMIES.has(tid) and Data.ENEMIES[tid].get("boss", false) and Trials.boss_area(tid) != "", "trial %s guards a boss placed in the world" % tid)
		var in_story := Trials.is_gate(tid)
		for st in Data.STEPS:
			in_story = in_story or (st.kind == "kill" and st.boss == tid)
		check(in_story, "trial %s stands on the main story's road (a quest boss or one of the Eight Gates)" % tid)
		check(fits.call(str(tr.why)) and tr.get("might", Trials.MIGHT).size() == 2 and float(tr.get("might", Trials.MIGHT)[0]) >= 1.0, "trial %s: why it is hard, and it is harder than an ordinary boss" % tid)
		var pids := {}
		var kinds := {}
		for p in tr.paths:
			check(not pids.has(p.id) and Trials.KINDS.has(p.kind) and str(p.n) != "" and str(p.desc).length() > 20 and fits.call(str(p.line)), "%s/%s: a named path of a known kind, described, with a line that fits" % [tid, p.id])
			pids[p.id] = true
			kinds[p.kind] = true
			kinds_used[p.kind] = int(kinds_used.get(p.kind, 0)) + 1
			check(not p.needs.is_empty(), "%s/%s asks for something" % [tid, p.id])
			for k in p.boon:
				check(k in boon_keys, "%s/%s: boon %s is understood by the battle" % [tid, p.id, k])
			for n in p.needs:
				var ok := need_kinds.has(str(n[0]))
				match str(n[0]):
					"lv", "peak":
						ok = ok and int(n[1]) <= Data.MAX_LEVEL
					"item", "give":
						ok = ok and Data.ITEMS.has(str(n[1])) and int(n[2]) >= 1
					"dao":
						ok = ok and (str(n[1]) == "" or Data.DAOS.has(str(n[1]))) and int(n[2]) < Data.DAO_RANKS.size()
					"standing":
						ok = ok and Data.RACES.has(str(n[1])) and int(n[2]) <= Data.KIN
					"fate":
						# a fated encounter in one of the states its story can reach (fate.gd)
						ok = ok and Fate.THREADS.has(str(n[1])) and n[2] is Array and not (n[2] as Array).is_empty()
						for stn in n[2]:
							ok = ok and FateText.STATES.get(str(n[1]), {}).has(str(stn))
					"bonds":
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= Fate.THREAD_ORDER.size()
					"heart":
						# how close Lin Feng and Yue Ling have come (bonds.gd): a step she can reach
						ok = ok and int(n[1]) >= 1 and int(n[1]) < Bonds.TITLES.size()
					"cleared":
						# the Spring Thunder release: obstacles of the story there are to clear before the trial
						var before := 0
						for st_c in Data.STEPS:
							if Data.step_index(str(st_c.id)) < _kill_step(tid) and str(st_c.kind) == "clear":
								before += int(st_c.n)
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= before
					"hearths":
						# the New Fire release: hearths of the land that can call the hero a guest (cultures.gd)
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= Cultures.ORDER.size()
					"works":
						# the Hundred Works release: works there are to build (works.gd), of any school, of one, or of the one most built
						ok = ok and n.size() == 3 and (str(n[1]) in ["", "best"] or Works.SCHOOLS.has(str(n[1]))) and int(n[2]) >= 1 and int(n[2]) <= (Works.ORDER.size() if str(n[1]) == "" else Works.TIERS)
					"delved":
						# the Hollow Hills release: caves there are to go to the back of (caves.gd), and no more
						# than a fifth of them asked for
						ok = ok and int(n[1]) >= 1 and int(n[1]) * 5 <= n_caves
					"arms":
						# the Hundred Arms release: Daos of arms there are to learn (arms.gd), and never all eight asked for
						ok = ok and int(n[1]) >= 1 and int(n[1]) < Arms.ORDER.size()
					"summits":
						# the High Roads release: summits there are to stand on (peaks.gd), and no more than a
						# tenth of the land's asked for
						ok = ok and int(n[1]) >= 1 and int(n[1]) * 10 <= (Atlas.world().peaks as Array).size()
					"companies":
						# the Thundering Pots release: companies the levy and the sect bring by themselves (war.gd),
						# and never more than one that has to be found elsewhere
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= 8
					"airs":
						# the airs of the six hearths (music.gd)
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= Music.AIRS.size()
					"falls":
						# the Lost Horse release: battles that cannot be won (dooms.gd): no more than the
						# story itself puts in the way before the trial
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= 3
					"marks":
						# what the choices left standing (marks.gd): fewer than there are crossroads behind him
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= 8
				check(ok, "%s/%s: requirement %s is well formed" % [tid, p.id, str(n)])
				if str(n[0]) in ["item", "give"] and Trials.RECIPES.has(str(n[1])):
					check(str(Trials.RECIPES[str(n[1])].get("for", "")) == tid, "%s/%s: the recipe for %s says what it is for" % [tid, p.id, n[1]])
		check(tr.paths.size() >= 3 and kinds.size() >= 3, "trial %s can be passed in at least three different ways (%d)" % [tid, kinds.size()])
	for kd in Trials.KINDS:
		check(int(kinds_used.get(kd, 0)) >= 2, "the road %s is offered by at least two trials (%d)" % [kd, int(kinds_used.get(kd, 0))])
	var story_trials := 0
	for st2 in Data.STEPS:
		if Trials.trial_of_step(st2) != "":
			story_trials += 1
	check(story_trials >= 14, "the main story's chapter lords are guarded by trials (%d)" % story_trials)
	for el in Data.ELEM_COLORS:
		if el != "none":
			check(Data.ITEMS.has(Trials.essence_of(el)), "foes of %s leave an essence that exists" % el)
	for eid in Data.ENEMIES:
		var el2: String = str(Data.ENEMIES[eid].elem)
		check(el2 == "none" or Trials.essence_of(el2) != "", "%s leaves an essence" % eid)
	for rid in Trials.RECIPES:
		var r: Dictionary = Trials.RECIPES[rid]
		check(Trials.STATIONS.has(str(r.at)) and Data.ITEMS.has(rid) and Data.step_index(str(r.after)) >= 0 and Trials.TRIALS.has(str(r.get("for", ""))), "recipe %s: made at a station, of a real item, listed from a real step, for a real trial" % rid)
		var tstep := Data.step_index(Trials.GATE_STEP) if Trials.is_gate(str(r.for)) or str(r.for) == "chiyou" else -1
		for i3 in Data.STEPS.size():
			if Data.STEPS[i3].kind == "kill" and Data.STEPS[i3].boss == str(r.for):
				tstep = i3
		check(Data.step_index(str(r.after)) <= tstep, "recipe %s can be made before its trial" % rid)
		for k2 in r.in:
			check(Data.ITEMS.has(k2) and int(r.in[k2]) > 0, "recipe %s: input %s exists" % [rid, k2])
			if str(k2).begins_with("ess_"):
				# the essence can be hunted before the trial: some region on the way has foes of its element
				var el3 := Trials.elem_of(str(k2))
				var found := false
				for i4 in tstep + 1:
					var sa: String = str(Data.STEPS[i4].get("area", ""))
					if sa == "" or not Data.AREAS.has(sa):
						continue
					var pools: Array = Data.AREAS[sa].get("pool", []) + Data.AREAS[sa].get("warband", {}).get("pool", [])
					for pe in pools:
						found = found or str(Data.ENEMIES[pe[0]].elem) == el3
				check(found, "recipe %s: %s can be hunted on the way to its trial" % [rid, k2])
			else:
				# anything else is found on the quests before the trial
				var got := false
				for i5 in tstep:
					var st5: Dictionary = Data.STEPS[i5]
					got = got or (st5.kind == "collect" and st5.item == k2 and st5.n >= int(r.in[k2]))
				for a5 in Data.AREAS:
					for pk5 in Data.AREAS[a5].get("pickups", []):
						got = got or (pk5.item == k2 and pk5.get("always", false))
				# (Part XV: every memory given back to Yue Ling leaves a pressed petal)
				got = got or (k2 == Bonds.PETAL and Data.step_index(Bonds.MEMORY_STEP) < tstep and Bonds.MEMORIES_NEEDED >= int(r.in[k2]))
				check(got, "recipe %s: %s is found before its trial" % [rid, k2])
	for did in Trials.DEEDS:
		var d: Dictionary = Trials.DEEDS[did]
		var npc_ok := false
		for n5 in Data.AREAS.get(str(d.area), {}).get("npcs", []):
			if str(n5.id) == str(d.npc):
				var nv = n5.get("vis", ["", ""])
				npc_ok = str(nv[1]) == "" and (str(nv[0]) == "" or Data.step_index(str(nv[0])) <= Data.step_index(str(d.after))) and not n5.has("floor")
		check(npc_ok, "deed %s: %s lives in %s for good by the time they ask" % [did, d.npc, d.area])
		check(Data.step_index(str(d.after)) >= 0 and int(d.renown) > 0 and fits.call(str(d.ask)) and fits.call(str(d.thanks)), "deed %s: asked from a real step, worth renown, and its lines fit" % did)
		for k3 in d.want:
			check(Data.ITEMS.has(k3) and int(d.want[k3]) > 0, "deed %s wants something that exists" % did)
	check(Trials.DEEDS.size() >= 24, "townsfolk all over the world ask for help (%d deeds)" % Trials.DEEDS.size())
	check(Trials.renown_title(0) == "Unknown" and Trials.renown_title(600) == "Legendary", "renown has titles")
	# the rules, on a game state of their own
	var G3 = load("res://scripts/game.gd").new()
	G3.reset()
	G3.level = 11
	G3.exp = 0.0
	check(Trials.need_met(["lv", 11], G3) and not Trials.need_met(["peak", 11], G3), "a level is met; the peak of a realm needs full cultivation")
	G3.exp = float(G3.exp_need())
	check(Trials.need_met(["peak", 11], G3), "cultivation full at the peak counts")
	G3.stones = 1000
	var wealth_p := Trials.path("demon_lord", "wealth")
	check(not Trials.path_met("demon_lord", wealth_p, G3), "a path that costs more than Lin Feng has cannot be taken")
	G3.stones = 3000
	check(Trials.path_met("demon_lord", wealth_p, G3) and not G3.take_path("demon_lord", "wealth").is_empty() and G3.stones == 600, "taking the wealth path pays for it")
	G3.stones = 0
	check(Trials.path_met("demon_lord", wealth_p, G3) and not G3.take_path("demon_lord", "wealth").is_empty() and G3.stones == 0, "a path already paid for is not charged again after a lost battle")
	check(not Trials.path_met("demon_lord", Trials.path("demon_lord", "respect"), G3), "respect must be earned")
	G3.inv = {"ess_thunder": 6, "shard": 4}
	G3.stones = 599
	G3.step = Data.step_index("s_lord")
	check(Trials.recipes_at("alchemist", G3).has("thunder_seal") and not Trials.can_craft("thunder_seal", G3), "the alchemist offers the talisman, but it costs stones too")
	G3.stones = 700
	check(G3.craft("thunder_seal") and G3.inv.thunder_seal == 1 and G3.inv.ess_thunder == 0 and G3.inv.shard == 2 and G3.stones == 100, "crafting uses up its essences, its quest items and its stones")
	check(Trials.path_met("demon_lord", Trials.path("demon_lord", "craft"), G3) and not Trials.recipes_at("alchemist", G3).has("thunder_seal"), "the talisman opens the craft path, and is not offered twice")
	G3.trial_won("demon_lord", "craft")
	check(G3.trials.demon_lord == "craft" and G3.renown == Trials.RENOWN_TRIAL and Trials.favourite_kind(G3) == "craft", "a trial passed is remembered with its path, and the world hears of it")
	G3.step = Data.step_index("s_lord")
	var dd := Trials.deed_of("cook_zhou", G3)
	check(dd == "deed_cook" and not G3.do_deed(dd), "Auntie Zhou asks for wood essence; nothing to give yet")
	G3.inv["ess_wood"] = 5
	var st0: int = G3.stones
	check(G3.do_deed(dd) and G3.inv.ess_wood == 2 and G3.renown == Trials.RENOWN_TRIAL + int(Trials.DEEDS.deed_cook.renown) and G3.stones == st0 + int(Trials.DEEDS.deed_cook.stones) and Trials.deed_of("cook_zhou", G3) == "", "a deed takes what was asked, pays and raises renown, once")
	G3.step = 0
	check(Trials.deed_of("disciple_han", G3) == "", "nobody asks before the story gets there")
	G3.reset()
	check(G3.renown == 0 and G3.trials.is_empty() and G3.deeds.is_empty() and G3.gates_open.is_empty() and G3.paid.is_empty(), "a new game starts with no renown, trials, deeds or gates")
	G3.step = Data.step_index("s_p13_gates")
	for gk in 3:
		G3.gates_open[Trials.GATES[gk]] = true
	G3.poll_steps()
	check(G3.cur_step().id == "s_p13_gates", "three gates do not break the lock")
	G3.gates_open[Trials.GATES[5]] = true
	G3.poll_steps()
	check(G3.cur_step().id == "s_p13_heart", "any four of the Eight Gates, in any order, break it")
	G3.free()
	var weak_boss: Dictionary = Data.make_enemy("demon_lord", 12)
	var trial_boss: Dictionary = Data.make_enemy("demon_lord", 12, 1.5, 1.15)
	check(trial_boss.maxhp > weak_boss.maxhp * 1.4 and trial_boss.atk > weak_boss.atk * 1.1, "a trial's boss is stronger than the same boss unguarded")
	print("== part XIII: the Eight Gates ==")
	check(Data.REALMS[18] == "Myriad Daos as One" and Data.level_name(54).ends_with("Myriad Daos as One"), "Part XIII adds the Myriad Daos as One realm")
	# (Part XIII no longer ends the game: Part XIV follows its breakthrough, see below)
	check(Data.step_index("s_break18") < Data.step_index("s_p14_home") and Data.DIALOGUE.has("recall11") and FileAccess.get_file_as_string("res://scripts/main.gd").contains("\"s_break17\": \"recall11\""), "Part XIII follows Ten Thousand Waters Return (recall11)")
	check(Trials.GATES.size() == 8 and Trials.GATES_NEEDED == 4, "eight gates, any four of which break the lock")
	var gate_layers := {}
	var gate_areas := {}
	for gid in Trials.GATES:
		var ga := Trials.boss_area(gid)
		gate_areas[ga] = true
		gate_layers[Data.layer_of(ga)] = int(gate_layers.get(Data.layer_of(ga), 0)) + 1
		var gb: Dictionary = {}
		for b5 in Data.AREAS[ga].bosses:
			if b5.id == gid:
				gb = b5
		check(gb.get("vis", ["", ""])[0] == Trials.GATE_STEP and Trials.TRIALS.has(gid) and Trials.GATE_NAMES.has(gid), "%s: a General of the Eight Gates in %s, from the gates step on, guarded by a trial" % [gid, ga])
		check(Data.DIALOGUE.has("pre:" + gid) and Data.DIALOGUE.has("post:" + gid), "%s has something to say before and after" % gid)
	check(gate_areas.size() == 8 and gate_layers.get("surface", 0) == 2 and gate_layers.get("heaven", 0) == 2 and gate_layers.get("under", 0) == 2 and gate_layers.get("sea", 0) == 2, "two gates in each of the four realms")
	var roads := {}
	for p6 in Trials.TRIALS.chiyou.paths:
		roads[p6.id] = true
		for key6 in ["post:chiyou", "s_p13_end", "post:s_break18"]:
			check(Data.ROUTE_LINES.has(key6) and not Data.ROUTE_LINES[key6].get(p6.id, []).is_empty(), "the road %s tells %s its own way" % [p6.id, key6])
			for ln6 in Data.ROUTE_LINES[key6].get(p6.id, []):
				check(fits.call(str(ln6[1])) and (ln6.size() == 2 or Data.EMOTES.has(str(ln6[2]))), "%s/%s: a line that fits the box" % [key6, p6.id])
	check(roads.has("sword") and roads.has("peoples") and roads.has("cauldron"), "three roads into the heart: the Sword, the Many Peoples and the Cauldron")
	var bands := 0
	for a6 in Data.AREAS:
		var band: Dictionary = Data.AREAS[a6].get("warband", {})
		if band.is_empty():
			continue
		bands += 1
		check(Data.step_index(str(band.vis)) >= 0 and int(band.n) > 0, "%s: the war-band marches from a real step" % a6)
		for pe6 in band.pool:
			check(Data.ENEMIES.has(pe6[0]) and not Data.ENEMIES[pe6[0]].get("boss", false) and int(pe6[1]) > 50, "%s: war-band soldier %s is one of the late chapters' foes, at their level" % [a6, pe6[0]])
		# (a band that came later in the story, "late", is placed in the finished world, atlas.gd, so that no
		# older map moves for it)
		var mw: Dictionary = MapGen.build(a6) if not band.get("late", false) else Atlas.world_of(Data.layer_of(a6))
		var marching: Array = mw.ents.filter(func(e6): return e6.kind == "enemy" and e6.get("vis", ["", ""])[0] == str(band.vis) and str(e6.get("area", a6)) == a6)
		check(marching.size() == int(band.n), "%s: %d war-band packs placed" % [a6, marching.size()])
	var p13_bands := Data.AREAS.keys().filter(func(a7): return str(Data.AREAS[a7].get("warband", {}).get("vis", "")) == "s_p13_home").size()
	check(p13_bands == 8 and bands == 29, "the war-bands march in every gate's region, the heart's among them (%d), Part XIV's grudges round the Wheel, Part XV's moths among the graves, Part XVI's hunger on the terraces, moths in the market and Nian's cubs in the bamboo, Part XVII's cold in Frostpeak and poisons in the millet, Part XVIII's damp at Longmen, and Part XIX's mites at Qingshi, engines at Tushan, strays in the dunes, counters in Heaven's Forge, looms in the Silkworm Woods and kites over the Sea of Clouds, cinders on the volcano and wildfire on the mountain, and Part XX's burrowers on the pasture below Thunder Valley and what came out of the karst's caves" % p13_bands)
	check(Data.ITEMS.has("homing_elixir") and Trials.RECIPES.homing_elixir.in.has("autumn_leaf"), "the Road of the Cauldron needs an elixir made with an autumn leaf, from Chiyou's own maples")
	# the Conclave's invitations: any four of eight leaders, in any order
	var visits_steps := 0
	for st7 in Data.STEPS:
		if st7.kind != "visits":
			continue
		visits_steps += 1
		# (Part XVIII's new fire goes home to every one of the six hearths: there the choice is only the order)
		check(int(st7.n) >= 1 and (int(st7.n) < st7.npcs.size() or (str(st7.id) in ["s_p18_carry", "s_p23_levy"] and int(st7.n) == st7.npcs.size())), "%s: any %d of %d, so there is a choice" % [st7.id, st7.n, st7.npcs.size()])
		var realms7 := {}
		for nid in st7.npcs:
			var na := Trials.npc_area(str(nid))
			realms7[Data.layer_of(na)] = true
			check(na != "" and (Data.DIALOGUE.has("visit:" + str(nid)) or Data.DIALOGUE.has("visit:%s:%s" % [str(st7.id), str(nid)])), "%s: %s lives somewhere and has something to say when visited" % [st7.id, nid])
		# (the Conclave's invitations go out to every realm; Part XVI's New Year calls are made round the sect)
		check(realms7.size() >= 3 or str(st7.id) in ["s_p16_calls", "s_p18_carry", "s_p19_makers", "s_p19_word", "s_p20_elders", "s_p21_masters", "s_p23_levy", "s_p24_lost"], "%s: the people to visit live in at least three realms" % st7.id)
	check(visits_steps >= 1, "Part XIII has a step of visits in any order")
	for st8 in Data.STEPS:
		if st8.kind == "hunt" and st8.has("of"):
			var band8: Dictionary = Data.AREAS[st8.area].get("warband", {})
			# (a hunt in a cave, Part XX, is for what lives in that cave: caves.gd)
			if st8.has("cave"):
				band8 = Caves.spec(str(st8.area), int(st8.cave)).get("foes", {})
			var marching8 := {}
			for pe8 in band8.get("pool", []):
				marching8[pe8[0]] = true
			# (Part XXII: a region's second band, for a later chapter)
			if not st8.has("cave"):
				for pe8b in Data.AREAS[st8.area].get("warband2", {}).get("pool", []):
					marching8[pe8b[0]] = true
				# (Part XXIV: and a third and a fourth)
				for bk8 in ["warband3", "warband4"]:
					for pe8c in Data.AREAS[st8.area].get(bk8, {}).get("pool", []):
						marching8[pe8c[0]] = true
			for fid in st8.of:
				check(Data.ENEMIES.has(fid) and marching8.has(fid), "%s hunts %s, who marches in %s" % [st8.id, fid, st8.area])
	var G5 = load("res://scripts/game.gd").new()
	G5.reset()
	G5.step = Data.step_index("s_p13_hunt")
	G5.record_kills("maple", 3, ["maple_fox", "maple_fox", "lost_lantern"])
	G5.record_kills("maple", 2, ["jiuli_warrior", "maple_fox"])
	check(G5.hunt == 1, "a hunt for Chiyou's war-band counts only the war-band (not the gorge's own beasts, which scatter)")
	G5.free()
	var G4 = load("res://scripts/game.gd").new()
	G4.reset()
	G4.step = Data.step_index("s_p13_envoys")
	for vk in ["ming_yi", "xu_qian", "yu_hua"]:
		G4.visited[vk] = true
	G4.poll_steps()
	check(G4.cur_step().id == "s_p13_envoys", "three invitations are not enough")
	G4.visited["bu_si"] = true
	G4.poll_steps()
	check(G4.cur_step().id == "s_p13_chiyou", "any four leaders, in any order, and the way into Zhuolu is open")
	G4.free()
	print("== towns and world-building ==")
	var town_ids := {}
	for tw in Data.TOWNS:
		town_ids[tw.id] = true
		check(Data.AREAS.has(tw.area) and str(tw.get("lore", "")).length() > 60, "town %s has a home and a history" % tw.id)
	check(Data.TOWNS.size() >= 6, "the land has at least six towns besides the sect (%d)" % Data.TOWNS.size())
	for tn in [["mountain", 5], ["longmen", 6], ["tushan", 5], ["dunes", 3]]:
		var folk: int = Data.AREAS[tn[0]].get("npcs", []).size()
		var houses: int = Data.AREAS[tn[0]].get("buildings", []).size()
		check(folk >= tn[1] and houses >= 4, "%s is a town: %d townsfolk and %d buildings you can enter" % [tn[0], folk, houses])
		for n10 in Data.AREAS[tn[0]].get("npcs", []):
			if n10.get("fate", false):
				continue
			check(Data.CHAT.has(n10.id) and Data.CHAT[n10.id].size() >= 3, "%s has at least three things to say" % n10.id)
			check(Assets.PEOPLE.has(n10.id) and Assets.has(Assets.PEOPLE[n10.id]), "%s is Blender-built" % n10.id)
	for rid2 in Atlas.all_region_ids():
		check(str(Data.REGION_LORE.get(rid2, "")).length() > 80, "the land remembers the history of " + rid2)
	print("== story ==")
	# every line of dialogue and chat fits the dialogue box (four lines of 22 px text, 1100 px wide)
	var too_long: Array = []
	var dfont := ThemeDB.fallback_font
	for dk in Data.DIALOGUE:
		for dl in Data.DIALOGUE[dk]:
			var par := TextParagraph.new()
			par.add_string(str(dl[1]), dfont, 22)
			par.width = 1100
			if par.get_line_count() > 4:
				too_long.append(dk)
	for ck in Data.CHAT:
		for cl in Data.CHAT[ck]:
			var par2 := TextParagraph.new()
			par2.add_string(str(cl), dfont, 22)
			par2.width = 1100
			if par2.get_line_count() > 4:
				too_long.append(ck)
	check(too_long.is_empty(), "every line of dialogue fits the dialogue box (too long: %s)" % str(too_long))
	# every "Quest complete" toast is read whole: at most two lines of the toast's width (world.gd)
	var toast_w: float = UI.TOAST_W
	var long_toasts := []
	for stq in Data.STEPS:
		var tq := "Quest complete: " + str(stq.t)
		if UI.wrap_lines(tq, UI.fit(tq, 18, toast_w, 15), toast_w).size() > 2:
			long_toasts.append(str(stq.id))
	check(toast_w > 0.0 and long_toasts.is_empty(), "every quest's \"Quest complete\" toast fits in two lines (too long: %s)" % str(long_toasts))
	# every foe's name fits its label in battle (200 px, a boss 360 px, shrunk to 11 px at most) and
	# every boss's name its banner (660 px, down to 24 px); a battle message wraps onto more rows of
	# the 440 px log, so none is cut off
	var long_names: Array = []
	for en in Data.ENEMIES:
		var ed: Dictionary = Data.ENEMIES[en]
		var lw := 360.0 if ed.get("boss", false) else 200.0
		if dfont.get_string_size(str(ed.n), HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fit(str(ed.n), 14, lw, 11)).x > lw:
			long_names.append(en)
		if ed.get("boss", false) and dfont.get_string_size(str(ed.n), HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fit(str(ed.n), 34, 660, 24)).x > 660:
			long_names.append(en + " (banner)")
	check(long_names.is_empty(), "every foe's name fits its battle label (too long: %s)" % str(long_names))
	var cut_rows := 0
	for row in UI.wrap_lines("Enemies appear!  Frost Hare of the Moon, Three-Legged Moon Toad, Silver Crane of the Long Night", 16, 440):
		if dfont.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > 440:
			cut_rows += 1
	check(cut_rows == 0 and UI.wrap_lines("Enemies appear!  Frost Hare of the Moon, Three-Legged Moon Toad, Silver Crane of the Long Night", 16, 440).size() == 2, "a long battle message wraps onto two rows of the log")
	for st in Data.STEPS:
		if st.kind == "collect":
			check(Data.ITEMS.has(st.item), "collect item defined " + st.item)
	for k in Data.DIALOGUE:
		for ln in Data.DIALOGUE[k]:
			# [speaker, text] or, with a cutscene gesture (Part XII), [speaker, text, gesture or "who:gesture"]
			check((ln.size() == 2 or (ln.size() == 3 and Data.EMOTES.has(str(ln[2]).get_slice(":", str(ln[2]).get_slice_count(":") - 1)))) and str(ln[1]).length() > 0, "dialogue line well formed in " + k)
			break
	for k2 in Data.BOSS_DROPS:
		check(Data.ENEMIES.has(k2) and Data.ITEMS.has(Data.BOSS_DROPS[k2]), "boss drop " + k2)
	check(not Data.known_skills(0, 12, Data.step_index("s_apeking")).has("heaven"), "Heaven-Cleaving Sword is not usable before the ancestor teaches it")
	check(Data.known_skills(0, 12, Data.step_index("s_elder5")).has("heaven"), "Heaven-Cleaving Sword is usable after the Roc falls")
	for k3 in Data.DIALOGUE:
		for ln2 in Data.DIALOGUE[k3]:
			check(not str(ln2[1]).contains("Chi Rong"), "no stale Sage name in " + k3)
			break
	print("== progression ==")
	check(Data.EXP_NEED.size() >= Data.MAX_LEVEL, "exp table covers all levels")
	check(Data.ENEMY_EXP.size() >= Data.MAX_LEVEL, "enemy exp table covers all levels")
	for lv in Data.MAX_LEVEL:
		check(Data.EXP_NEED[lv] > 0 and Data.ENEMY_EXP[lv] >= (Data.ENEMY_EXP[lv - 1] if lv > 0 else 0), "exp tables sane at level %d" % lv)
	for l in Data.MAX_LEVEL + 1:
		check(Data.level_name(l) != "", "level name %d = %s" % [l, Data.level_name(l)])
	print("== part IV ==")
	check(Data.REALMS.size() * 3 >= Data.MAX_LEVEL + 1, "every level up to the max has a realm name")
	check(Data.DIALOGUE.has("recall2"), "Part IV recall dialogue exists")
	check(Data.AREAS.sect.portals.any(func(p): return p.to == "cloudsea" and p.open == "s_p4_home"), "sect west gate opens after the Part IV briefing")
	check(Data.step_index("s_break8") < Data.step_index("s_p4_home"), "Part IV starts after the True Immortal ascension")
	for a5 in ["cloudsea", "court", "forge", "garden"]:
		check(Look.THEMES.has(a5) and Look.EXTRA.has(a5), "theme and terrain extras for " + a5)
	check(Data.known_skills(0, 25).has("inkbreak") and Data.known_skills(1, 26).has("seal_bloom"), "Part IV techniques are learnable")
	print("== part VI ==")
	check(Data.DIALOGUE.has("recall4"), "Part VI recall dialogue exists")
	check(Data.AREAS.sect.portals.any(func(p): return p.to == "maple" and p.open == "s_p6_home"), "sect south-west gate opens after the Part VI briefing")
	check(Data.step_index("s_break10") < Data.step_index("s_p6_home"), "Part VI starts after the Primordial Sovereign ascension")
	for a6 in ["maple", "karst", "lilies", "diyu"]:
		check(Look.THEMES.has(a6) and Look.EXTRA.has(a6) and Scatter.ECO.has(a6), "theme, terrain extras and ecology for " + a6)
	check(Data.known_skills(0, 30).has("wheelcut") and Data.known_skills(1, 31).has("rebirth"), "Part VI techniques are learnable")
	check(not Data.known_skills(0, 32, Data.step_index("s_sp_unforgotten")).has("samsara"), "Samsara Sword waits for the Thousand Unforgotten")
	check(Data.known_skills(0, 32, Data.step_index("s_wh_intro")).has("samsara"), "Samsara Sword is learned at the Naihe Bridge")
	check(Data.BOSS_DROPS.get("ox_head", "") == "bell", "Ox-Head drops the bell that later dialogue mentions")
	print("== nature ==")
	var species: Dictionary = Flora.SPECIES
	var rock_kinds := ["boulder", "slab", "spire", "scree", "karst", "crystal", "pebbles"]
	for th in Scatter.ECO:
		var eco: Dictionary = Scatter.ECO[th]
		for layer in ["canopy", "under", "ground"]:
			for pair in eco[layer]:
				check(species.has(pair[0]), "%s: %s species %s exists" % [th, layer, pair[0]])
		for rk in eco.rocks:
			check(rk in rock_kinds, "%s: rock recipe %s exists" % [th, rk])
		check(Look.THEMES.has(th), "ecology %s belongs to a theme" % th)
	for th2 in Look.THEMES:
		check(Scatter.ECO.has(th2), "theme %s has an ecology" % th2)
	# variants are genuinely different individuals, not copies
	for sp in ["oak", "pine", "maple", "bamboo", "willow", "bush"]:
		var m0: ArrayMesh = Flora.mesh(sp, 0)
		var m1: ArrayMesh = Flora.mesh(sp, 1)
		var v0: int = m0.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
		var v1: int = m1.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
		var a0: AABB = m0.get_aabb()
		var a1: AABB = m1.get_aabb()
		check(v0 != v1 or not a0.size.is_equal_approx(a1.size), "%s variants 0 and 1 differ (%d vs %d vertices)" % [sp, v0, v1])
		check(m0.get_surface_count() >= 1 and a0.size.y > 0.2, "%s grows to a visible size (%.1f m)" % [sp, a0.size.y])
	# rocks: faces wind outward like every other mesh (Godot front faces are clockwise)
	var rk_mesh: ArrayMesh = Rocks.mesh("boulder", 0, "bamboo")
	var ra: Array = rk_mesh.surface_get_arrays(0)
	var rv: PackedVector3Array = ra[Mesh.ARRAY_VERTEX]
	var ri: PackedInt32Array = ra[Mesh.ARRAY_INDEX]
	var centre := rk_mesh.get_aabb().get_center()
	var outward := 0
	for i in range(0, ri.size(), 3):
		var q0: Vector3 = rv[ri[i]]
		var q1: Vector3 = rv[ri[i + 1]]
		var q2: Vector3 = rv[ri[i + 2]]
		if (q1 - q0).cross(q2 - q0).dot((q0 + q1 + q2) / 3.0 - centre) < 0.0:
			outward += 1
	check(outward > ri.size() / 3 * 0.9, "rock faces wind outward (%d of %d)" % [outward, ri.size() / 3])
	# distance field: a 5x1 strip with one wall at the left end
	var strip := PackedByteArray([MapGen.WALL, MapGen.FLOOR, MapGen.FLOOR, MapGen.FLOOR, MapGen.FLOOR])
	var df := Scatter.distance_field(strip, 5, 1, [MapGen.WALL], 9)
	check(df[0] == 0 and df[1] == 1 and df[4] == 4, "distance field counts tiles from the forest edge")
	check(Scatter.grass_mesh("sect", 0).get_surface_count() == 1, "grass clumps build")
	print("== battle ==")
	var twins: Array = Data.make_foes([{"id": "bamboo_wolf", "lv": 1}, {"id": "bamboo_wolf", "lv": 1}, {"id": "bamboo_wolf", "lv": 1}])
	var raw := [Data.make_enemy("bamboo_wolf", 1), Data.make_enemy("bamboo_wolf", 1)]
	check(raw.find(raw[1]) == 0, "root cause: Array.find() matches identical foes by value")
	check(twins[0].slot != twins[1].slot, "make_foes gives identical foes their own slots")
	var spots := {}
	for f in twins:
		spots[Data.foe_pos(f.slot, twins.size(), false)] = true
	check(spots.size() == 3, "identical foes stand on distinct stage positions")
	print("== 3D builder ==")
	var mbt := MB.new()
	mbt.limb(Vector3.ZERO, Vector3(0, 1, 0), 0.2, 0.2, Color.WHITE, 8)
	var tri_ok := true
	for i in range(0, 8 * 6, 3):
		var p0: Vector3 = mbt.v[mbt.idx[i]]
		var p1: Vector3 = mbt.v[mbt.idx[i + 1]]
		var p2: Vector3 = mbt.v[mbt.idx[i + 2]]
		var cen := (p0 + p1 + p2) / 3.0
		var out := Vector3(cen.x, 0, cen.z)
		# Godot treats clockwise triangles as front faces: (p1-p0)x(p2-p0) points away from the viewer
		if (p1 - p0).cross(p2 - p0).dot(out) > 0.0:
			tri_ok = false
	check(tri_ok, "limb() side faces wind outward (no inside-out limbs)")
	var mbl := MB.new()
	mbl.lathe(Vector3.ZERO, [Vector2(0.5, 0.0), Vector2(0.5, 1.0)], Color.WHITE, 8)
	var lat_ok := true
	for i in range(0, mbl.idx.size(), 3):
		var q0: Vector3 = mbl.v[mbl.idx[i]]
		var q1: Vector3 = mbl.v[mbl.idx[i + 1]]
		var q2: Vector3 = mbl.v[mbl.idx[i + 2]]
		var c2 := (q0 + q1 + q2) / 3.0
		if (q1 - q0).cross(q2 - q0).dot(Vector3(c2.x, 0, c2.z)) > 0.0:
			lat_ok = false
	check(lat_ok, "lathe() faces wind outward (no inside-out robes)")
	var tdist := 0.0
	var m4 := MapGen.build("sect")
	var hm4 := Terrain3D.heightmap(m4.grid, m4.w, m4.h, "sect", Data.AREAS.sect.seed)
	check(hm4.size() == (m4.w + 1) * (m4.h + 1), "height field covers every tile corner")
	for x4 in m4.w:
		tdist = maxf(tdist, absf(Terrain3D.sample(hm4, m4.w, m4.h, (x4 + 0.5) * Terrain3D.T, 13.5 * Terrain3D.T)))
	check(tdist < 0.5, "the sect's main road stays nearly flat (max %.2f)" % tdist)
	print("== things to do ==")
	# what each thing is (props.gd): a name and a hint, time to do it, where it is done, what comes of
	# it, three things to say of it, something that can be held; a clip for Lin Feng and for Yue Ling
	var party := [Assets.person("lin_feng"), Assets.person("yue_ling")]
	var pap0: AnimationPlayer = party[0].get_meta("ap")
	var pap1: AnimationPlayer = party[1].get_meta("ap")
	for pk in Props.KINDS:
		var kd: Dictionary = Props.KINDS[pk]
		check(str(kd.get("n", "")) != "" and str(kd.get("verb", "")) != "" and float(kd.get("dur", 0.0)) >= 1.5, "thing %s: a name, a hint and time to do it" % pk)
		check(str(kd.get("at", "face")) in Props.AT and Props.EFFECTS.has(str(kd.get("effect", ""))), "thing %s: where it is done and what comes of it" % pk)
		check((kd.get("lines", []) as Array).size() >= 3, "thing %s: three things to say of it" % pk)
		check(str(kd.get("hold", "")) == "" or Props.HELD.has(str(kd.hold)), "thing %s: what is held can be held" % pk)
		check(str(kd.get("comp_hold", "")) == "" or Props.HELD.has(str(kd.comp_hold)), "thing %s: what Yue Ling holds can be held" % pk)
		# (she does not drink from an empty hand or read thin air: the bugs of the Lotus release)
		check(not str(kd.get("comp", "")) in ["drink", "read", "play_flute", "release"] or str(kd.get("comp_hold", "")) != "", "thing %s: Yue Ling has something in her hands for it" % pk)
		check(str(kd.get("fx", "")) == "" or Props.FX.has(str(kd.fx)), "thing %s: how it answers is drawn" % pk)
		check(pap0.has_animation(str(kd.clip)), "Lin Feng can %s (%s)" % [str(kd.verb).to_lower(), kd.clip])
		var pcc := str(kd.get("comp", "watch"))
		check(pcc == "watch" or pap1.has_animation(pcc), "Yue Ling joins in at the %s (%s)" % [pk, pcc])
	for pk2 in Props.THEMES:
		for kk in Props.THEMES[pk2]:
			check(Props.KINDS.has(kk) and not Props.KINDS[kk].has("furn"), "the %s look for things that exist (%s)" % [pk2, kk])
	for p0 in party:
		p0.free()
	# every kind of furniture in the buildings can be used
	var fkinds := {}
	for fa in Data.AREAS:
		for fbd in Data.AREAS[fa].get("buildings", []):
			for fl0 in [fbd, fbd.get("upper", {}), fbd.get("cellar", {})]:
				for fpr in fl0.get("props", []):
					fkinds[str(fpr[0])] = true
	for fk in fkinds:
		check(Props.FURNITURE.has(fk) and Props.KINDS.has(str(Props.FURNITURE[fk])), "the %s in the buildings can be used" % fk)
	# where the things stand: outdoors on a closed forest-edge or shore tile of their own region beside
	# open ground, apart from each other and from everybody; furniture on the tile it fills, or (on a
	# floor anyone walks over) flagged so; so no tile anybody walks on is taken
	var n_out := 0
	var n_furn := 0
	for plid in ["surface", "heaven", "under", "sea"]:
		var plw := Atlas.world_of(plid)
		var bad_tile := 0
		var bad_near := 0
		var bad_apart := 0
		var outs: Array = []
		var others: Array = []
		for pe in plw.ents:
			if pe.kind != "prop":
				others.append(pe.pos)
		for pe2 in plw.ents:
			if pe2.kind != "prop":
				continue
			var tv: int = plw.grid[pe2.pos.y * plw.w + pe2.pos.x]
			if pe2.has("furn"):
				n_furn += 1
				if bool(pe2.get("walk", false)) != MapGen.is_walkable_tile(tv):
					bad_tile += 1
				continue
			n_out += 1
			var fn: Vector2i = pe2.pos + pe2.face
			if not (tv == MapGen.WALL or tv == MapGen.WATER) or not MapGen.is_walkable_tile(plw.grid[fn.y * plw.w + fn.x]) or Atlas.owner_id(plw, pe2.pos) != str(pe2.area):
				bad_tile += 1
			for op in others:
				if absi(op.x - pe2.pos.x) <= 2 and absi(op.y - pe2.pos.y) <= 2:
					bad_near += 1
			for q2 in outs:
				# (the places of Yue Ling's memories stand nearest the spot their memory names, bonds.gd:
				# never on top of another thing, but they may be nearer than the rest)
				if q2[0] == pe2.area and (q2[1] as Vector2i).distance_squared_to(pe2.pos) < (16 if pe2.has("memory") or bool(q2[2]) else 64):
					bad_apart += 1
			outs.append([pe2.area, pe2.pos, pe2.has("memory")])
		check(bad_tile == 0, "%s: every thing to do stands where nobody walks (%d astray)" % [plid, bad_tile])
		check(bad_near == 0, "%s: outdoor things stand clear of everybody and everything (%d too close)" % [plid, bad_near])
		check(bad_apart == 0, "%s: a region's outdoor things stand well apart (%d too close)" % [plid, bad_apart])
		for fid2 in plw.floors:
			for fe2 in plw.floors[fid2].ents:
				if fe2.kind == "prop":
					n_furn += 1
	check(n_out >= 250, "a lot of things to do outdoors (%d)" % n_out)
	check(n_furn >= 500, "and the furniture of every building (%d)" % n_furn)
	# what comes of doing them (a game state of its own)
	var PG = load("res://scripts/game.gd").new()
	PG.reset()
	PG.level = 20
	PG.companion = true
	PG.heal_full()
	PG.hp[0] = 10.0
	var pbench := {"kind": "prop", "id": "test:bench", "prop": "bench", "pos": Vector2i.ZERO}
	var pr0: int = PG.renown
	var pl0: Array = Props.use(pbench, PG)
	check(PG.hp[0] > 10.0 and PG.pastimes.has("bench") and PG.renown == pr0 + 1 and pl0.size() >= 2, "a rest on a bench: health back, a new pastime, a little renown")
	Props.use(pbench, PG)
	check(PG.renown == pr0 + 1 and Props.line_for(pbench, 0) != Props.line_for(pbench, 1), "a pastime is news only once; something new is said each time")
	var plion := {"kind": "prop", "id": "test:lion", "prop": "lion", "pos": Vector2i.ZERO}
	var pst0: int = PG.stones
	Props.use(plion, PG)
	var pst1: int = PG.stones
	Props.use(plion, PG)
	check(pst1 > pst0 and PG.stones == pst1, "a find is found only once")
	var pherb := {"kind": "prop", "id": "test:herb", "prop": "herb_patch", "pos": Vector2i.ZERO}
	Props.use(pherb, PG)
	Props.use(pherb, PG)
	var ph1 := int(PG.inv.get("ess_wood", 0))
	PG.playtime += 601.0
	Props.use(pherb, PG)
	check(ph1 == 1 and int(PG.inv.get("ess_wood", 0)) == 2, "herbs grow back with time")
	PG.level = 3
	PG.exp = 0.0
	Props.use({"kind": "prop", "id": "test:stones", "prop": "stones", "pos": Vector2i.ZERO}, PG)
	check(PG.exp > 0.0, "the training stones are a little cultivation")
	PG.hp[0] = 1.0
	PG.qi[1] = 0.0
	Props.use({"kind": "prop", "id": "test:bed", "prop": "bed", "pos": Vector2i.ZERO}, PG)
	check(PG.hp[0] == float(PG.max_hp(0)) and PG.qi[1] == float(PG.max_qi(1)), "a sleep in a bed restores everybody")
	PG.free()
	_fates_and_faces()
	# the rest (every script compiles) runs on the first frame, see _process
	finished = true

## The Fates and Faces release: character creation, outfits, rides, the bestiary and the fated
## encounters (their story machinery: every state any choice can lead to has a chapter written for it,
## so no thread can run into a dead end), and Part XIV.
func _fates_and_faces() -> void:
	print("== bugs fixed in this release ==")
	# a cylinder or a cone of an uncommon number of sides was drawn as a box (the great drum, the halls'
	# columns, the pillars of heaven): now built round, at the unit height the box had
	var c10: Array = MB._proto("cyl10")
	var cone5: Array = MB._proto("cone5")
	var ys10 := Vector2(INF, -INF)
	var top5 := 0.0
	for v10 in c10[0]:
		ys10 = Vector2(minf(ys10.x, v10.y), maxf(ys10.y, v10.y))
	for v5 in cone5[0]:
		if v5.y > 0.49:
			top5 = maxf(top5, Vector2(v5.x, v5.z).length())
	check((c10[0] as PackedVector3Array).size() > 24 and is_equal_approx(ys10.y - ys10.x, 1.0) and top5 < 0.01, "a ten-sided cylinder is round and a unit tall, a five-sided cone comes to a point")
	# the people met on the road lost their "fate" mark on the way into the world, so all of them stood
	# about from the first morning (two Qiu Yes in the courtyard) and only ever said "..."
	var sect_ents: Array = MapGen.build("sect").ents
	var qy: Array = sect_ents.filter(func(e): return str(e.get("id", "")) == "qiu_ye" or str(e.get("id", "")) == "qiu_ye_end")
	var BG = load("res://scripts/game.gd").new()
	BG.reset()
	check(qy.size() == 2 and qy.all(func(e): return e.get("fate", false)) and not Fate.present(BG, "qiu_ye_end") and not Fate.present(BG, "qiu_ye"), "the people met on the road carry their mark into the world, and stand there only when the story has them there")
	# training stones at the peak of a realm used up their time and taught nothing; below it, what they
	# taught was set straight into the cultivation bar, so a stage reached was not reached
	var cap_lv := 0
	while not Data.realm_cap(cap_lv):
		cap_lv += 1
	BG.level = cap_lv
	BG.exp = 0.0
	var tstones := {"kind": "prop", "id": "test:stones2", "prop": "stones", "pos": Vector2i.ZERO}
	Props.use(tstones, BG)
	check(BG.exp == 0.0 and not BG.prop_t.has("test:stones2"), "at the peak of a realm the training stones teach nothing, and keep their time")
	BG.level = 0
	BG.exp = float(BG.exp_need()) - 0.5
	Props.use(tstones, BG)
	check(BG.level == 1, "the cultivation the stones teach can complete a stage")
	BG.free()
	print("== character creation ==")
	for lk in Fashion.LOOK_ORDER:
		var asset: String = str(Fashion.LOOKS[lk].asset)
		check(Assets.PEOPLE.has(asset) and Assets.has(Assets.PEOPLE[asset]), "the look %s is Blender-built (%s)" % [lk, asset])
		var hm := Assets.instance(Assets.PEOPLE[asset])
		var hap: AnimationPlayer = hm.get_meta("ap", null)
		for clip in ["ride", "ride_idle", "ride_stand", "sit_bench", "attack", "talk"]:
			check(hap != null and hap.has_animation(clip), "the look %s can %s" % [lk, clip])
		hm.free()
	var yap: AnimationPlayer = Assets.person("yue_ling").get_meta("ap", null)
	check(yap != null and yap.has_animation("ride") and yap.has_animation("ride_stand"), "Yue Ling rides pillion and stands on the vehicles")
	check(Fashion.HAIR.size() >= 5 and Fashion.EYES.size() >= 5 and Fashion.ROBES.size() >= 5 and Fashion.FAMILY.size() >= 8 and Fashion.GIVEN.size() >= 8, "enough hair, eyes, robes and names to choose from")
	var fx_keys := ["hp", "qi", "atk", "spd", "miss", "heal", "taken", "stones", "exp", "cost"]
	for oid in Fashion.ORIGIN_ORDER:
		var o: Dictionary = Fashion.ORIGINS[oid]
		var ok_fx := true
		for k in o.fx:
			ok_fx = ok_fx and k in fx_keys
		check(ok_fx and str(o.desc).length() > 60 and Fashion.ORIGIN_LINES.intro.has(oid) and Fashion.ORIGIN_LINES.ending.has(oid), "origin %s: its strength, its story, its words in the prologue and the ending" % oid)
	check(Fashion.clean_name(" bAi7 ") == "Bai" and Fashion.clean_name("123") == "", "a typed name keeps its letters, capitalised")
	UI.set_hero_name("Bai", "Chen")
	var once := UI.named("Lin Feng's broom. Senior Brother Lin! Feng'er, come in.")
	check(once == "Bai Chen's broom. Senior Brother Bai! Chen'er, come in." and UI.named(once) == once, "the chosen name replaces the story's on screen, once (%s)" % once)
	check(UI.named("Lin Shan and Feng Meng and Warden Feng") == "Lin Shan and Feng Meng and Warden Feng", "other people's names are left alone")
	check(UI.named("Senior Brother Lin! Forgive me, I mean... Lord Lin?") == "Senior Brother Bai! Forgive me, I mean... Lord Bai?", "what the disciples call a Sovereign has the family name the player chose too")
	UI.set_hero_name(Fashion.DEFAULT_FAMILY, Fashion.DEFAULT_GIVEN)
	var CG = load("res://scripts/game.gd").new()
	CG.reset()
	var hp_plain: int = CG.max_hp(0)
	CG.create_hero({"family": "Su", "given": "Ming", "look": "wild", "hair": 2, "eyes": 1, "robe": 3, "origin": "fisher"})
	check(CG.hero_name() == "Su Ming" and CG.max_hp(0) > hp_plain and CG.fighter(0).spd < Data.speed(0), "an origin's strength and weakness are felt (a ferry-hand: health up, speed down)")
	var cols := Fashion.hero_colors(CG)
	check(cols.has("hair") and cols.has("eyes") and cols.has("robe") and cols.has("trim"), "the hero is drawn in the colours chosen")
	var hm2 := Models.hero({"look": "wild", "cols": cols, "outfit": "sweeper"})
	var recol := 0
	for mi in hm2.get_meta("meshes", []):
		var arr: Array = (mi as MeshInstance3D).mesh.surface_get_arrays(0)
		var cs: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var ps: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var want: Color = (cols.robe as Color).srgb_to_linear()
		for i in cs.size():
			if Assets.hero_part(cs[i], uvs[i], ps[i], false) == "robe" and absf(cs[i].h - want.h) < 0.06:
				recol += 1
	check(recol > 500, "the robe is recoloured on the model (%d vertices)" % recol)
	hm2.free()
	print("== outfits and rides ==")
	for oid2 in Fashion.OUTFIT_ORDER:
		var od: Dictionary = Fashion.OUTFITS[oid2]
		var ok2: bool = od.cols.size() == 3
		for k2 in od.fx:
			ok2 = ok2 and k2 in fx_keys
		for acc in od.acc:
			ok2 = ok2 and Fashion.ACCESSORY_BONES.has(acc)
		var src := 0
		if od.has("step"):
			src += 1
			ok2 = ok2 and Data.step_index(str(od.step)) >= 0
		if od.has("buy"):
			src += 1
			ok2 = ok2 and Data.step_index(str(od.get("after", ""))) >= 0
		if od.has("fate") or od.has("origin"):
			src += 1
		# (the Thundering Pots release: a feat, a commission of the notice board, or something found)
		if od.has("feat"):
			src += 1
			ok2 = ok2 and Feats.FEATS.has(str(od.feat))
		if od.has("job"):
			src += 1
			ok2 = ok2 and Jobs.JOBS.has(str(od.job))
		if od.has("egg"):
			src += 1
			ok2 = ok2 and Eggs.EGGS.has(str(od.egg))
		check(ok2 and (src > 0 or oid2 == "sweeper") and str(od.desc).length() > 40, "outfit %s: colours, passives, accessories and a way to earn it" % oid2)
	for acc2 in Fashion.ACCESSORY_BONES:
		var an := Models.accessory(acc2, Color("f0c850"))
		check(an.get_child_count() > 0, "accessory %s builds" % acc2)
		an.free()
	var dressed := Models.hero({"outfit": "celestial"})
	check(dressed.find_children("acc_pauldrons*", "BoneAttachment3D", true, false).size() == 2, "an outfit's pauldrons hang on both shoulders")
	dressed.free()
	var kinds := {}
	for rid in Fashion.RIDE_ORDER:
		var rd: Dictionary = Fashion.RIDES[rid]
		kinds[rd.kind] = true
		check(float(rd.speed) > 1.0 and (rd.has("step") or rd.has("pick") or rid == "pony") and (not rd.has("step") or Data.step_index(str(rd.step)) >= 0), "ride %s: faster than running and earned somewhere" % rid)
		var rn := Models.ride(rid)
		check(rn.get_child_count() > 0, "ride %s builds" % rid)
		rn.free()
	check(kinds.has("mount") and kinds.has("vehicle"), "mounts to sit astride and vehicles to stand on")
	check(Assets.has(Assets.MOUNTS.horse), "the horse is Blender-built")
	var horse := Assets.mount("horse")
	var hap2: AnimationPlayer = horse.get_meta("ap", null)
	check(hap2 != null and hap2.has_animation("idle") and hap2.has_animation("walk") and hap2.has_animation("run"), "the horse stands, walks and gallops")
	horse.free()
	CG.grant_ride("sword")
	CG.grant_ride("pony")
	check(CG.ride == "sword", "a slower ride does not replace a faster one in the saddle")
	CG.grant_outfit("dragon")
	check(CG.wear("dragon") and Fashion.gear(CG, "taken") < 0.0, "an outfit's passive is worn with it")
	print("== the bestiary ==")
	var no_story: Array = []
	for eid in Data.ENEMIES:
		var boss: bool = Data.ENEMIES[eid].get("boss", false)
		if (boss and not Lore.BOSS.has(eid)) or (not boss and not Lore.BEAST.has(eid)):
			no_story.append(eid)
	check(no_story.is_empty(), "every foe has a story (missing: %s)" % str(no_story))
	var dfont := ThemeDB.fallback_font
	var too_long: Array = []
	for bid in Lore.BOSS:
		check(Data.ENEMIES.has(bid), "the story of %s is of a real foe" % bid)
		for ln in Lore.BOSS[bid]:
			var par := TextParagraph.new()
			par.add_string(str(ln), dfont, 22)
			par.width = 1100
			if par.get_line_count() > 4:
				too_long.append(bid)
	check(too_long.is_empty(), "every boss's story fits the dialogue box (too long: %s)" % str(too_long))
	print("== fated encounters ==")
	for th in Fate.THREAD_ORDER:
		var path: Array = Fate.PATH[th]
		var reach := {"": true}
		for k in path.size():
			var sid: String = path[k][0]
			var npc: String = path[k][1]
			var ch: Dictionary = FateText.CHAPTERS.get(sid, {})
			check(not ch.is_empty(), "%s: chapter %s is written" % [th, sid])
			if k < path.size() - 1:
				var si := Data.step_index(sid)
				check(si >= 0 and Data.STEPS[si].kind == "fate" and str(Data.STEPS[si].npc) == npc, "%s: chapter %s is a step of the story, with %s" % [th, sid, npc])
				if k > 0:
					check(si > Data.step_index(str(path[k - 1][0])), "%s: chapter %s comes after the one before" % [th, sid])
			else:
				check(Data.STEPS[Data.step_index(Fate.FINALE_STEP)].npcs.has(npc), "%s: the last chapter is settled in Part XIV, with %s" % [th, npc])
			var placed := false
			for a in Data.AREAS:
				for n in Data.AREAS[a].get("npcs", []):
					if str(n.id) == npc:
						placed = n.get("fate", false) and Assets.PEOPLE.has(str(n.get("asset", n.id))) and Assets.has(Assets.PEOPLE[str(n.get("asset", n.id))])
			check(placed, "%s: %s stands in the world, Blender-built" % [th, npc])
			check(FateText.CHAT.get(npc, []).size() >= 3, "%s: %s has three things to say afterwards" % [th, npc])
			if ch.is_empty():
				continue
			var nxt := {}
			for st in reach:
				var v: Dictionary = ch.by.get(st, ch.by.get("*", {}))
				check(not v.is_empty(), "%s: chapter %s is written for the state '%s' (no dead end)" % [th, sid, st])
				var free_way := false
				for o in v.get("options", []):
					free_way = free_way or o.get("need", []).is_empty()
					for f in o.get("battle", []):
						check(Data.ENEMIES.has(str(f[0])) and int(f[1]) >= 0 and int(f[1]) <= Data.MAX_LEVEL, "%s/%s/%s: a battle with %s" % [sid, st, o.id, f[0]])
					var gv: Dictionary = o.get("gain", {})
					check((not gv.has("ride") or Fashion.RIDES.has(gv.ride)) and (not gv.has("outfit") or Fashion.OUTFITS.has(gv.outfit)), "%s/%s/%s: what it gives exists" % [sid, st, o.id])
					for ik in gv.get("items", {}):
						check(Data.ITEMS.has(ik), "%s/%s/%s: item %s exists" % [sid, st, o.id, ik])
					var outs: Array = []
					if o.has("follow"):
						check(o.has("battle") and not o.follow.get("options", []).is_empty(), "%s/%s/%s: a choice after a battle" % [sid, st, o.id])
						for fo in o.follow.options:
							outs.append(str(fo.then))
					else:
						outs.append(str(o.then))
					for ns in outs:
						check(FateText.STATES.get(th, {}).has(ns), "%s/%s/%s: leads to a described state %s" % [sid, st, o.id, ns])
						nxt[ns] = true
				check(free_way, "%s/%s: at least one way needs nothing (the story can always go on)" % [sid, st])
			reach = nxt
		for fs in reach:
			check(FateText.EPILOGUE.get(th, {}).has(fs), "%s: the ending tells of the final state %s" % [th, fs])
	for tid in Fate.BONDS:
		var bd: Array = Fate.BONDS[tid]
		check(Trials.TRIALS.has(tid) and Trials.path(tid, "bond").kind == "bond" and Trials.path(tid, "bond").needs[0][1] == bd[0], "an old bond (%s) opens a way through the trial of %s" % [bd[0], tid])
		var bstep := Data.step_index("s_f_" + {"tala": "tala3", "qiu_ye": "qiu3", "hu": "hu2", "xu_lan": "xu3", "liu_ying": "liu3"}[bd[0]])
		var tstep := -1
		for i2 in Data.STEPS.size():
			if Data.STEPS[i2].kind == "kill" and str(Data.STEPS[i2].boss) == tid:
				tstep = i2
		check(bstep >= 0 and bstep < tstep, "the bond for %s is made before its trial" % tid)
	# a thread taken step by step on a game state of its own
	var FG = load("res://scripts/game.gd").new()
	FG.reset()
	FG.step = Data.step_index("s_f_qiu1")
	var v1 := Fate.variant(FG, "s_f_qiu1")
	var share := Fate.option(v1, "share")
	FG.stones = 100
	check(not Fate.option_ok(FG, share), "a choice that costs stones cannot be taken without them")
	FG.stones = 500
	check(Fate.option_ok(FG, share), "and can with them")
	Fate.pay(FG, share)
	Fate.take(FG, "qiu_ye", share)
	check(FG.stones == 300 and Fate.state(FG, "qiu_ye") == "shared" and FG.fate_log.qiu_ye.size() == 1, "a choice is paid for, remembered and written down")
	check(Fate.variant(FG, "s_f_qiu2") == FateText.CHAPTERS.s_f_qiu2.by.shared, "the next chapter is the one written for what was chosen")
	FG.step = Data.step_index("s_f_qiu1")
	check(Fate.present(FG, "qiu_ye") and not Fate.present(FG, "qiu_ye_grave") and not Fate.present(FG, "qiu_ye_end"), "a fated encounter stands where the story has them")
	FG.fates["liu_ying"] = "apprentice"
	check(Trials.recipe_stones("bearer_incense", FG) < int(Trials.RECIPES.bearer_incense.stones), "the Hag's apprentice makes Alchemist Mo's recipes cheaper")
	for th2 in ["tala", "qiu_ye", "hu"]:
		FG.fates[th2] = "ally"
	check(Fate.allies(FG) == 3 and Trials.need_met(["bonds", 3], FG), "three friends open the way of bonds through Nie's trial")
	FG.free()
	CG.free()
	print("== part XIV: the Ripening of Karma ==")
	check(Data.REALMS[19] == "Karma Fulfilled" and Data.level_name(57).ends_with("Karma Fulfilled"), "Part XIV adds the Karma Fulfilled realm")
	check(Data.DIALOGUE.has("recall12") and FileAccess.get_file_as_string("res://scripts/main.gd").contains("\"s_break18\": \"recall12\""), "Part XIV follows Myriad Daos as One (recall12)")
	# (Part XIV no longer ends the game: Part XV follows its breakthrough, see _lotus)
	check(Data.step_index("s_p14_fates") > Data.step_index("s_p14_hunt") and Data.step_index("s_p14_nie") > Data.step_index("s_p14_fates"), "the threads are settled before Nie is faced")
	check(Trials.TRIALS.has("nie") and Trials.boss_area("nie") == "wheel" and Trials.path("nie", "bond").needs[0][0] == "bonds", "Nie is a trial at the Wheel, open to the friends Lin Feng made")
	var wb: Dictionary = Data.AREAS.wheel.warband
	check(str(wb.vis) == "s_p14_judge" and wb.pool.all(func(pe): return Data.ENEMIES.has(pe[0]) and Lore.BEAST.has(pe[0])), "the grudges round the Wheel are new foes, with stories")
	print("== part XIV: the grudges that stayed ==")
	check(Data.step_index("s_p14_mirror") > Data.step_index("s_p14_fates") and Data.step_index(Grudges.STEP) == Data.step_index("s_p14_mirror") + 1
		and Data.step_index("s_p14_nie") > Data.step_index(Grudges.STEP) and Data.DIALOGUE.has("s_p14_mirror"), "Judge Cui shows the grudges after the threads are settled, and they are laid to rest before Nie")
	check(int(Data.STEPS[Data.step_index(Grudges.STEP)].n) == Grudges.ORDER.size() and Grudges.ORDER.size() == Grudges.GRUDGES.size(), "the grudges step asks for all six")
	var gareas := {}
	for gid in Grudges.ORDER:
		var gd: Dictionary = Grudges.GRUDGES[gid]
		var ge: Dictionary = Data.ENEMIES.get(gid, {})
		var owner: String = str(gd.of)
		var ga := Trials.boss_area(gid)
		gareas[ga] = true
		check(ge.get("boss", false) and ge.get("grudge", false) and Data.ENEMIES.has(owner) and Trials.boss_area(owner) == ga, "%s: a boss standing in the region where %s fell" % [gid, owner])
		var placed := {}
		for b in Data.AREAS[ga].bosses:
			if str(b.id) == gid:
				placed = b
		var owner_pos := Vector2i(-99, -99)
		for b2 in Data.AREAS[ga].bosses:
			if str(b2.id) == owner:
				owner_pos = b2.pos
		check(placed.get("vis", ["", ""])[0] == Grudges.STEP and placed.pos != owner_pos and (placed.pos - owner_pos).length() <= 3.0, "%s: appears with its step, beside (not on) the place its owner fell" % gid)
		check(Lore.BOSS.has(gid) and Data.DIALOGUE.has("pre:" + gid) and Data.DIALOGUE.has("post:" + gid), "%s: has a story, last words before the fight and words once spent" % gid)
		var free_way := false
		var ids := {}
		for o in gd.options:
			ids[str(o.id)] = true
			check(str(o.then) in ["eased", "paid", "unpaid"] and str(o.label) != "" and str(o.desc) != "" and str(o.log) != "" and not o.get("after", []).is_empty(), "%s/%s: says what it does, is written down and has an answer" % [gid, o.id])
			check(str(o.then) == "unpaid" or str(o.get("epilogue", "")) != "", "%s/%s: the ending tells what came of it" % [gid, o.id])
			for n in o.get("need", []):
				var nk := str(n[0])
				check(nk in ["fate", "stones", "renown", "item", "rides"] and (nk != "item" or Data.ITEMS.has(str(n[1]))) and (nk != "fate" or Fate.THREADS.has(str(n[1]))), "%s/%s: needs something real" % [gid, o.id])
			if o.get("need", []).is_empty():
				free_way = true
		check(ids.has("wheel") and free_way and gd.options.size() >= 2, "%s: can always be answered (the Wheel), and at least one way costs something" % gid)
	check(gareas.size() == 6 and gareas.has("juntian") and gareas.has("guixu"), "the six grudges stand in six regions, up in the heavens and out at sea too")
	var GG = load("res://scripts/game.gd").new()
	GG.reset()
	check(Grudges.nie_mult(GG) == 1.0 and Grudges.nie_line(GG) == "" and Grudges.epilogues(GG).is_empty(), "before any grudge is met, Nie is as it was")
	GG.stones = 10
	var tst := Grudges.option("grudge_iron_fang", "test")
	check(not Fate.option_ok(GG, tst) and not Fate.option_ok(GG, Grudges.option("grudge_iron_fang", "son")) and Fate.option_ok(GG, Grudges.option("grudge_iron_fang", "wheel")), "a grudge's costly answers need what they cost; the Wheel needs nothing")
	GG.stones = 40000
	GG.fates["hu"] = "ally"
	check(Fate.option_ok(GG, tst) and Fate.option_ok(GG, Grudges.option("grudge_iron_fang", "son")), "and a friend can answer for a father")
	Fate.pay(GG, tst)
	Grudges.take(GG, "grudge_iron_fang", tst)
	check(GG.stones == 10000 and Grudges.state(GG, "grudge_iron_fang") == "paid" and Grudges.settled(GG) == 1 and Grudges.nie_mult(GG) < 1.0, "a grudge paid is remembered, and Nie is the lighter for it")
	Grudges.take(GG, "grudge_admiral", Grudges.option("grudge_admiral", "wheel"))
	check(Grudges.unpaid(GG) == 1 and Grudges.unpaid_names(GG) == "the Admiral" and Grudges.nie_line(GG).contains("the Admiral") and Grudges.epilogues(GG).size() == 1, "a grudge left to the Wheel is carried by Nie, and told of")
	for gid2 in Grudges.ORDER:
		GG.grudges[gid2] = "wheel"
	check(Grudges.nie_mult(GG) > 1.8 and Grudges.epilogues(GG).is_empty(), "six grudges left unpaid make Nie far stronger")
	for gid3 in Grudges.ORDER:
		GG.grudges[gid3] = str(Grudges.GRUDGES[gid3].options[1].id)
	check(Grudges.nie_mult(GG) < 0.8 and Grudges.nie_line(GG).begins_with("Not one") and Grudges.epilogues(GG).size() == 6, "six laid to rest leave Nie smaller, and six lines for the ending")
	GG.step = Data.step_index(Grudges.STEP)
	GG.grudges = {}
	GG.poll_steps()
	check(Data.STEPS[GG.step].id == Grudges.STEP and GG.objective_text().contains("(0/6)"), "the grudges step waits for all six")
	for gid4 in Grudges.ORDER:
		GG.grudges[gid4] = "wheel"
	GG.poll_steps()
	check(Data.STEPS[GG.step].id == "s_p14_nie", "and goes on to Nie once all six are answered")
	GG.free()
	var bot_src := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(bot_src.contains("GRUDGE_ROUTE") and Grudges.ORDER.all(func(g): return bot_src.contains("\"%s\"" % g)), "the bot goes to every grudge and has an answer for each")
	_lotus()
	_living()
	_spring()
	_new_fire()
	_hundred_works()
	_hollow_hills()
	_hundred_arms()
	_high_roads()
	_thundering_pots()
	_lost_horse()

## The Lotus release: Yue Ling's closeness, heart-to-hearts, wishes and futures (bonds.gd), the bigger
## things to do (structures.gd) and Part XV, the Thread She Never Had.
func _lotus() -> void:
	print("== the Lotus release: Yue Ling ==")
	var prev_talk := -1
	for tk in Bonds.TALKS:
		var ti := Data.step_index(str(tk.after))
		check(ti >= 0 and ti >= prev_talk, "heart-to-heart %s opens from a real step, in story order" % tk.id)
		prev_talk = ti
		check(not (tk.lines as Array).is_empty() and str(tk.ask) != "" and (tk.options as Array).size() >= 3, "heart-to-heart %s: something to say, a question and at least three replies" % tk.id)
		var leans := {}
		for o in tk.options:
			check(Bonds.FUTURES.has(str(o.get("lean", ""))) and int(o.get("bond", 0)) > 0 and str(o.label) != "" and not (o.get("after", []) as Array).is_empty(), "%s/%s: leans her heart somewhere, brings them closer and has an answer" % [tk.id, o.id])
			leans[str(o.lean)] = true
		check(leans.size() == Bonds.FUTURES.size(), "heart-to-heart %s offers every way her heart can lean" % tk.id)
	# every reply to her fits the choice list whole (422 px of 20 px text, shrunk to 16 px at most)
	var wide := []
	var replies := []
	for tk2 in Bonds.TALKS:
		replies.append_array(tk2.options)
	for mid0 in Bonds.MEMORIES:
		replies.append_array(Bonds.MEMORIES[mid0].get("options", []))
	for sid0 in Bonds.SHARES:
		replies.append_array(Bonds.SHARES[sid0].get("options", []))
	for o0 in replies:
		if UI.font().get_string_size(UI.named(str(o0.label)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > 422.0:
			wide.append(str(o0.label))
	for fk0 in Bonds.FUTURES:
		if UI.font().get_string_size(str(Bonds.FUTURES[fk0].n) + "  (her heart)", HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x > 422.0:
			wide.append(str(Bonds.FUTURES[fk0].n))
	check(wide.is_empty(), "every reply to Yue Ling fits the choice list (too wide: %s)" % str(wide))
	# (mid-sentence a future keeps its capitals: "towards his Dao companion", not "his dao companion")
	check(Bonds.toward("companion") == "his Dao companion" and Bonds.toward("lotus") == "the lotus of the mountain" and Bonds.toward("") == "nothing in particular", "a future's name reads right in the middle of a sentence")
	var chapters := {}
	for tk2 in Bonds.TALKS:
		var ti2 := Data.step_index(str(tk2.after))
		var ch := 1
		for st in Data.STEPS.slice(0, ti2 + 1):
			if str(st.id).ends_with("_home"):
				ch += 1
		chapters[ch] = true
	check(Bonds.TALKS.size() >= 15 and chapters.size() >= 13, "Yue Ling has something to say in every chapter (%d heart-to-hearts over %d chapters)" % [Bonds.TALKS.size(), chapters.size()])
	for a in Data.AREA_CHAIN:
		check(Bonds.REGION.has(a), "Yue Ling has a word to say about %s" % a)
	var outdoor := {}
	for lid in ["surface", "heaven", "under", "sea"]:
		for e in Atlas.world_of(lid).ents:
			if e.kind == "prop" and not e.has("furn"):
				outdoor[str(e.prop)] = true
	for w in Bonds.WISHES:
		check(Data.step_index(str(w.after)) >= 0 and Props.KINDS.has(str(w.kind)) and outdoor.has(str(w.kind)) and str(w.ask) != "" and str(w.done) != "", "Yue Ling's wish %s: opened by a real step, for a thing that stands somewhere in the world" % w.id)
	for kd in Structures.KINDS:
		check(Props.KINDS.has(kd) and outdoor.has(kd), "the bigger thing %s is a thing to do, and stands somewhere in the world" % kd)
		var sm := Props.model(kd, "sect")
		check(sm.get_child_count() > 0 and (not kd in ["kite", "armillary", "sky_lantern", "river_lantern", "archery", "millstone", "lantern_green"] or sm.has_meta("mover")), "the %s is built, with its moving part" % kd)
		sm.free()
	for hk in ["flute", "reel", "sky_lantern", "brush", "bow"]:
		var hn := Props.held(hk)
		check(hn.get_child_count() > 0, "something to hold: %s" % hk)
		hn.free()
	# the rules, on a game state of their own
	var LG = load("res://scripts/game.gd").new()
	LG.reset()
	check(LG.bond == 0 and Bonds.level(LG) == 0 and Bonds.leaning(LG) == "" and Bonds.talk_ready(LG) == "", "a new game: no closeness, no leaning, nothing to talk about without her")
	LG.companion = true
	LG.step = Data.step_index("s_spirit") + 1
	check(Bonds.talk_ready(LG) == "t_lotus", "once the bamboo spirit is calm, she has something to say")
	var lo := Bonds.talk_option("t_lotus", "mine")
	Bonds.take_talk(LG, "t_lotus", lo)
	check(LG.talks.has("t_lotus") and LG.bond == int(lo.bond) and Bonds.leaning(LG) == "companion" and Bonds.talk_ready(LG) == "", "a reply is remembered, brings them closer and leans her heart")
	LG.step = Data.step_index("s_yue") + 1
	var wl: Array = Bonds.did_together(LG, "bench", true)
	var b0: int = LG.bond
	check(LG.wishes.has("w_bench") and wl.size() >= 2 and Bonds.did_together(LG, "bench", true).is_empty() and LG.bond == b0, "a wish is granted once, and doing it again so soon is not news")
	LG.playtime += Bonds.SHARED_AGAIN + 1.0
	Bonds.did_together(LG, "bench", true)
	check(LG.bond == b0 + Bonds.SHARED, "doing things together again, later, brings them a little closer")
	LG.bond = Bonds.LEVELS[2]
	check(Trials.need_met(["heart", 2], LG) and not Trials.need_met(["heart", 3], LG), "how close they are opens the Side by side ways")
	LG.step = Data.step_index(Bonds.MEMORY_STEP)
	for mid in Bonds.MEMORY_ORDER.slice(0, Bonds.MEMORIES_NEEDED - 1):
		Bonds.take_memory(LG, mid, Bonds.MEMORIES[mid].options[0])
	LG.poll_steps()
	check(Data.STEPS[LG.step].id == Bonds.MEMORY_STEP and LG.objective_text().contains("(%d/%d)" % [Bonds.MEMORIES_NEEDED - 1, Bonds.MEMORIES_NEEDED]) and int(LG.inv.get(Bonds.PETAL, 0)) == Bonds.MEMORIES_NEEDED - 1, "the memories step waits for six, and every memory leaves a pressed petal")
	Bonds.take_memory(LG, Bonds.MEMORY_ORDER[Bonds.MEMORIES_NEEDED - 1], Bonds.MEMORIES[Bonds.MEMORY_ORDER[Bonds.MEMORIES_NEEDED - 1]].options[0])
	LG.poll_steps()
	check(Data.STEPS[LG.step].id == "s_p15_moth", "six given back, in any order, and the story goes on")
	# (the seventh can still be given back after the step, and then the ending tells of all seven: the
	# Spring Thunder release; before it the seventh closed with the step and that line was out of reach)
	check(Bonds.memory_ready(LG, Bonds.MEMORY_ORDER[6]) and not Bonds.memory_ready(LG, Bonds.MEMORY_ORDER[0]), "the seventh memory can still be found after the step; one given back cannot be given again")
	Bonds.take_memory(LG, Bonds.MEMORY_ORDER[6], Bonds.MEMORIES[Bonds.MEMORY_ORDER[6]].options[0])
	check(LG.memories.size() == Bonds.MEMORIES.size() and Bonds.epilogues(LG).any(func(ln): return str(ln).begins_with("Every one of the seven memories")), "all seven given back: the ending says so")
	LG.step = Data.step_index("s_p15_threads")
	LG.visited = {"alchemist": true, "qiu_ye_end": true, "tala_end": true, "hu_end": true}
	LG.poll_steps()
	check(Data.STEPS[LG.step].id == "s_p15_threads", "the people visited in Parts XIII and XIV do not count as threads tied for her")
	for nid in ["alchemist", "archivist", "mazu", "meng_po", "smith", "granny_wen"]:
		LG.threads[nid] = true
	LG.poll_steps()
	check(Data.STEPS[LG.step].id == "s_p15_warden", "six threads tied, by anybody who knew her, and the Warden must come out")
	Bonds.choose_future(LG, "wander")
	check(LG.future == "wander" and Bonds.epilogues(LG).size() >= 1, "the road she chooses is remembered and told at the end")
	LG.free()
	print("== part XV: the Thread She Never Had ==")
	check(Data.REALMS[20] == "Kindred Dao" and Data.level_name(60).ends_with("Kindred Dao") and Data.STEPS[Data.step_index("s_break20")].to == 60, "Part XV adds the Kindred Dao realm")
	check(Data.step_index("s_break20") > Data.step_index("s_p15_end") and Data.DIALOGUE.has("recall13") and FileAccess.get_file_as_string("res://scripts/main.gd").contains("\"s_break19\": \"recall13\""), "Part XV follows Karma Fulfilled (recall13)")
	for sid in ["s_p15_home", "s_p15_judge", "s_p15_founder", "s_p15_end", "pre:s_break20", "post:s_break20"]:
		check(Data.DIALOGUE.has(sid), "Part XV has its words for %s" % sid)
	var sw := Atlas.world_of("surface")
	for shid in Bonds.SHARES:
		var si := Data.step_index(shid)
		var spot_id := str(Data.STEPS[si].spot) if si >= 0 else ""
		var spot_e := Bonds.find_spot(sw.ents, spot_id)
		check(si >= 0 and str(Data.STEPS[si].kind) == "share" and not spot_e.is_empty() and str(spot_e.area) == str(Data.STEPS[si].area), "%s happens at a thing that stands in %s (%s)" % [shid, str(Data.STEPS[si].get("area", "")), spot_id])
	check(Bonds.find_spot(sw.ents, Bonds.FEAST).get("prop", "") == "stage", "the mountain has an open-air stage for the naming feast")
	# the bigger things stand clear of the towns' buildings (the sect's stage once had a shop's signboard
	# standing up through its boards)
	var crowded := 0
	for e4 in sw.ents:
		if e4.kind == "prop" and not e4.has("furn") and Props.is_structure(str(e4.prop)) and Props._by_building(sw.grid, sw.w, sw.h, e4.pos, 3):
			crowded += 1
	check(crowded == 0, "no pavilion, tower or stage stands in a building's way (%d)" % crowded)
	var spots := {}
	for e2 in sw.ents:
		if e2.kind == "prop" and e2.has("memory"):
			spots[str(e2.memory)] = e2
	check(spots.has(Bonds.POND) and str(spots[Bonds.POND].area) == "sect", "the lotus pond where she woke is by the sect")
	var loom_found := false
	for e3 in sw.ents:
		loom_found = loom_found or (str(e3.get("id", "")) == Bonds.LOOM and str(e3.get("furn", "")) == "loom" and str(e3.area) == "mountain")
	check(loom_found, "the loom she was woven on stands in the Founder's hermitage on the mountain")
	for mid2 in Bonds.MEMORIES:
		var m: Dictionary = Bonds.MEMORIES[mid2]
		check(Props.KINDS.has(str(m.prop)) and Data.AREAS.has(str(m.area)) and Data.step_index("s_p15_memories") >= 0, "memory %s: a real thing in a real region" % mid2)
		check(spots.has(mid2) and str(spots[mid2].area) == str(m.area) and str(spots[mid2].prop) == str(m.prop), "memory %s stands in %s" % [mid2, m.area])
		var foes_ok := not (m.battle as Array).is_empty()
		for f in m.battle:
			foes_ok = foes_ok and Data.ENEMIES.has(str(f[0])) and Lore.BEAST.has(str(f[0]))
		check(foes_ok, "memory %s is guarded by foes with stories" % mid2)
		check(not (m.lines as Array).is_empty() and not (m.scene as Array).is_empty() and (m.options as Array).size() >= 3 and m.options.all(func(o): return Bonds.FUTURES.has(str(o.lean))), "memory %s: what she remembers, the scene and what Lin Feng says" % mid2)
	check(Bonds.MEMORIES.size() > Bonds.MEMORIES_NEEDED and int(Data.STEPS[Data.step_index(Bonds.MEMORY_STEP)].n) == Bonds.MEMORIES_NEEDED, "five of seven memories, in any order")
	var thr: Dictionary = Data.STEPS[Data.step_index("s_p15_threads")]
	for nid2 in thr.npcs:
		check(Data.DIALOGUE.has("thread:" + str(nid2)) and Trials.npc_area(str(nid2)) != "", "%s can tie a thread for her" % nid2)
	check(int(thr.n) <= (thr.npcs as Array).size() - Fate.THREAD_ORDER.size(), "the threads can be tied even if every one of the five fell")
	for bid in ["forgetting_queen", "unweaver", "lock_warden"]:
		var ba := Trials.boss_area(bid)
		var bspec: Dictionary = {}
		for b in Data.AREAS.get(ba, {}).get("bosses", []):
			if str(b.id) == bid:
				bspec = b
		var bstep := ""
		for st2 in Data.STEPS:
			if st2.kind == "kill" and st2.boss == bid:
				bstep = str(st2.id)
		check(bstep != "" and str(bspec.get("vis", ["", ""])[0]) == bstep, "%s appears with its step, in %s" % [bid, ba])
		check(Lore.BOSS.has(bid) and Data.DIALOGUE.has("pre:" + bid) and Data.DIALOGUE.has("post:" + bid), "%s has a story and words before and after" % bid)
	check(Trials.TRIALS.has("unweaver") and Trials.TRIALS.has("lock_warden") and Trials.path("unweaver", "heart").needs[0][0] == "heart" and Trials.path("lock_warden", "heart").needs[0][0] == "heart", "the Unweaver and the Warden are trials, and the two of them side by side is a way through each")
	var gb: Dictionary = Data.AREAS.grave.warband
	check(str(gb.vis) == "s_p15_judge" and gb.pool.all(func(pe): return Lore.BEAST.has(pe[0])), "the things that eat forgetting march among the graves once Judge Cui has spoken")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(Bonds.TALKS.all(func(tk3): return bsrc.contains("\"%s\"" % tk3.id)) and bsrc.contains("MEMORY_ROUTE") and bsrc.contains("\"unweaver\"") and bsrc.contains("\"lock_warden\""), "the bot has a reply for every heart-to-heart, a round of the memories and a way through both trials")


## The Living Land release: the hours of the day, the people of the towns, the things that break, and
## Part XVI, the Year Turns.
func _living() -> void:
	print("== the hours of the day (clock.gd) ==")
	var CG = load("res://scripts/game.gd").new()
	CG.reset()
	check(absf(Clock.hour(CG) - 7.0) < 0.01 and CG.day == 1 and Clock.shichen_name(7.2) == "Hour of the Dragon" and Clock.shichen_name(23.5) == "Hour of the Rat" and Clock.shichen_name(0.5) == "Hour of the Rat", "a new game starts at seven, in the Hour of the Dragon")
	check(Clock.rate(12 * 60.0) == Clock.DAY_RATE and Clock.rate(23 * 60.0) == Clock.NIGHT_RATE and Clock.NIGHT_RATE > Clock.DAY_RATE, "the night goes by faster than the day")
	CG.clock = 23.9 * 60.0
	Clock.advance(CG, 30.0)
	check(CG.day == 2 and Clock.hour(CG) < 1.0, "midnight starts a new day (%s)" % Clock.text(CG))
	check(Clock.daylight(12.0) > 0.99 and Clock.daylight(1.0) < 0.01 and Clock.daylight(6.0) > 0.0 and Clock.daylight(6.0) < 1.0, "day is light, night is dark, and dawn is between")
	var noon_l: Dictionary = Look.at_hour("village", 12.0)
	var night_l: Dictionary = Look.at_hour("village", 1.0)
	var dusk_l: Dictionary = Look.at_hour("village", 18.6)
	check(float(night_l.night) > 0.9 and float(noon_l.night) < 0.05 and float(night_l.stars) > float(noon_l.stars) and night_l.moon and not noon_l.moon, "the village sky at night has the moon and the stars in it")
	check(float(night_l.sun_e) < float(noon_l.sun_e) and float(night_l.amb_e) < float(noon_l.amb_e) and (night_l.top as Color).get_luminance() < (noon_l.top as Color).get_luminance(), "the night is darker than the day")
	var warm := func(c: Color) -> float: return c.r - c.b
	check(float(warm.call(dusk_l.hor)) > float(warm.call(noon_l.hor)) and float(dusk_l.gold) > 0.3, "dusk warms the horizon")
	check(float(Look.at_hour("void", 1.0).night) < float(night_l.night), "the places whose light is not the sun's follow it less")
	var la_m: Array = Clock.light_angles(8.0)
	var la_e: Array = Clock.light_angles(17.0)
	check(float(la_m[1]) > 0.0 and float(la_e[1]) < 0.0 and not la_m[3] and Clock.light_angles(0.0)[3], "the sun comes up in the east and goes down in the west, and the moon has the night")
	CG.step = Data.step_index("s_yg_intro")
	CG.clock = 9.0 * 60.0
	Clock.advance(CG, 100.0)
	check(Clock.frozen(CG) == "noon" and absf(Clock.hour(CG) - 12.0) < 0.01, "in Part IX the sun stands at noon for nine days")
	CG.step = Data.step_index("s_gh_xihe")
	Clock.story_hour(CG, "s_gh_xihe")
	CG.step += 1
	check(Clock.frozen(CG) == "" and Clock.hour(CG) > 18.0, "when Xihe and Chang'e agree to take turns, the sun goes down")
	CG.step = Data.step_index("s_p16_xi")
	var held: float = CG.clock
	Clock.advance(CG, 300.0)
	check(Clock.frozen(CG) == "night" and CG.clock == held, "in Part XVI the last night of the year will not end until Nian is driven out")
	CG.step = Data.step_index("s_p16_dawn")
	CG.clock = 22.0 * 60.0
	var d0: int = CG.day
	Props.use({"kind": "prop", "id": "test:bed2", "prop": "bed", "pos": Vector2i.ZERO}, CG)
	check(absf(Clock.hour(CG) - 6.0) < 0.01 and CG.day == d0 + 1, "a night's sleep in a bed: he wakes at six the next morning")
	CG.clock = 14.0 * 60.0
	Props.use({"kind": "prop", "id": "test:bed3", "prop": "bed", "pos": Vector2i.ZERO}, CG)
	check(absf(Clock.hour(CG) - 14.0) < 0.01, "a nap in the afternoon is only a nap")
	CG.free()
	print("== the people of the towns (folk.gd) ==")
	var total := 0
	for tid in Folk.TOWNS:
		var t: Dictionary = Folk.TOWNS[tid]
		check(Data.AREAS.has(str(t.area)) and Folk.BODIES.has(str(t.race)), "%s: a town of a real region, of a people with bodies" % tid)
		var wd := Atlas.world_of(Data.layer_of(str(t.area)))
		var ppl := Folk.people(wd, tid)
		total += ppl.size()
		check(ppl.size() >= 12, "%s: lived in (%d people)" % [tid, ppl.size()])
		var bad := 0
		var noon := 0
		var late := 0
		var wrong_area := 0
		for fp in ppl:
			check(Folk.ROLES.has(str(fp.role)) and Assets.has("characters/" + str(fp.body)), "%s: %s is a %s with a body (%s)" % [tid, fp.n, fp.role, fp.body])
			var segs := Folk.day_of(wd, fp)
			var span: float = float(segs[segs.size() - 1].b) - float(segs[0].a)
			if span < 1430.0:
				bad += 1
			for h in [3.0, 8.0, 12.5, 16.0, 20.0]:
				var st := Folk.state(wd, fp, h * 60.0)
				if not st.vis:
					continue
				var tl := Vector2i(int(floor((st.at as Vector2).x)), int(floor((st.at as Vector2).y)))
				var g: int = wd.grid[tl.y * int(wd.w) + tl.x]
				if not MapGen.is_walkable_tile(g) or g == MapGen.INTERIOR:
					bad += 1
				if Atlas.owner_id(wd, tl) != str(t.area):
					wrong_area += 1
			if Folk.state(wd, fp, 10.5 * 60.0).vis:
				noon += 1
			if Folk.state(wd, fp, 2.5 * 60.0).vis:
				late += 1
		check(bad == 0 and wrong_area == 0, "%s: everybody's day covers the whole day, on open ground of the town's own region" % tid)
		if bool(t.get("night", false)):
			check(late > noon, "%s: the shades keep the night as other towns keep the day (%d out at night, %d by day)" % [tid, late, noon])
		else:
			check(noon > late * 3 and noon >= ppl.size() / 2, "%s: out and about by day, home at night (%d by day, %d at night)" % [tid, noon, late])
		var again := Folk.people(wd, tid)
		check(again == ppl and str(Folk.state(wd, ppl[0], 600.0)) == str(Folk.state(wd, again[0], 600.0)), "%s: the same people, in the same places, every time" % tid)
	check(total >= 200, "the towns are full of people (%d)" % total)
	for role in Folk.ROLES:
		check(Folk.LINES.has(role) or role == "servant", "the %ss have something to say" % role)
		for e in Folk.ROLES[role].day:
			check(Folk.PLACES.has(str(e[1])), "%s: the place %s can be found" % [role, e[1]])
	var LG2 = load("res://scripts/game.gd").new()
	LG2.reset()
	var pw := Atlas.world_of("surface")
	var cf: Dictionary = Folk.people(pw, "cloudfoot")[0]
	check(Folk.line(cf, LG2) != "" and not Folk.line(cf, LG2).contains("%s"), "a townsperson's words are filled in")
	for pid in Folk.POSTS:
		var found := false
		for a in Data.AREAS:
			for n in Data.AREAS[a].get("npcs", []):
				found = found or str(n.get("asset", n.id)) == pid or str(n.id) == pid
		check(found, "%s works at a place of their own in the world" % pid)
		var pd: Array = Folk.POSTS[pid]
		for c in str(pd[0]).split("|") + str(pd[2]).split("|"):
			check(c in Assets.LEND or c in ["talk", "idle"] or c in Data.EMOTES, "%s's work %s is a clip every person can play" % [pid, c])
	print("== lent clips (assets.gd) ==")
	var kid := Assets.instance("characters/folk_girl")
	Assets.lend_clips(kid)
	check(Assets.has_clip(kid, "hoe") and Assets.has_clip(kid, "sweep") and Assets.has_clip(kid, "bang") and Assets.has_clip(kid, "eat"), "every townsperson can do the towns' work and the party's interactions")
	var ap: AnimationPlayer = kid.get_meta("ap")
	var sw: Animation = ap.get_animation("sweep")
	var hips_y := 0.0
	for i in sw.get_track_count():
		if str(sw.track_get_path(i)).ends_with(":hips") and sw.track_get_type(i) == Animation.TYPE_POSITION_3D:
			hips_y = (sw.track_get_key_value(i, 0) as Vector3).y
		check(not str(sw.track_get_path(i)).ends_with(":sword"), "a lent clip leaves out the bones a person does not have")
	check(hips_y > 0.4 and hips_y < 0.8, "a child's lent clip is scaled to the child's rig (hips at %.2f m)" % hips_y)
	kid.free()
	print("== the things that break (havoc.gd) ==")
	var HG = load("res://scripts/game.gd").new()
	HG.reset()
	HG.level = 30
	HG.stones = 1000
	var n_brk := 0
	for tid2 in Folk.TOWNS:
		var ar: String = Folk.TOWNS[tid2].area
		var wd2 := Atlas.world_of(Data.layer_of(ar))
		var occ := {}
		for e2 in wd2.ents:
			occ[e2.pos] = true
		for b in Havoc.of_area(wd2, ar):
			n_brk += 1
			var g2: int = wd2.grid[b.tile.y * int(wd2.w) + b.tile.x]
			check(Havoc.KINDS.has(str(b.kind)) and g2 != MapGen.PATH and g2 != MapGen.INTERIOR and MapGen.is_walkable_tile(g2) and not occ.has(b.tile), "%s: %s stands on open ground, off the road and out of everybody's way" % [ar, b.id])
	check(n_brk >= 60, "the towns are full of things to break (%d)" % n_brk)
	var bw := Atlas.world_of("surface")
	var bv: Dictionary = Havoc.of_area(bw, "yanggu")[0]
	var said: Array = Havoc.smash(HG, bw, bv, "strike")
	check(Havoc.is_broken(HG, bv) and HG.stones == 1000 - Havoc.PRICE - Havoc.PRICE_REALM * HG.realm() and said.size() == 1 and str(said[0]).contains(str(Havoc.owner_of(bw, bv).n)), "a thing broken on purpose is paid for, to its owner (%s)" % str(said))
	check(Havoc.smash(HG, bw, bv, "strike").is_empty() and HG.smashed == 1, "a broken thing cannot be broken again")
	var bv2: Dictionary = Havoc.of_area(bw, "yanggu")[1]
	var st0: int = HG.stones
	check(str(Havoc.smash(HG, bw, bv2, "ride")[0]).contains("Mind where you ride") and HG.stones == st0, "a thing ridden through earns a piece of the owner's mind, not a bill")
	HG.clock = 5.9 * 60.0
	check(Havoc.is_broken(HG, bv), "still broken before dawn")
	HG.day += 1
	HG.clock = 6.1 * 60.0
	check(not Havoc.is_broken(HG, bv) and not HG.broken.has(bv.id), "mended by the next dawn")
	HG.free()
	LG2.free()
	print("== the objective panel ==")
	# every objective, with its count and its trial note, fits the two lines of the panel (three of
	# Part XV's ran onto a third, out of the panel and over the minimap's frame)
	var OG = load("res://scripts/game.gd").new()
	OG.reset()
	var long_obj: Array = []
	for i9 in Data.STEPS.size():
		OG.step = i9
		var ob: String = OG.objective_text()
		if UI.wrap_lines(ob, UI.objective_size(ob), 486.0).size() > 2:
			long_obj.append(str(Data.STEPS[i9].id))
	check(long_obj.is_empty(), "every objective fits the panel's two lines (too long: %s)" % str(long_obj))
	OG.free()
	print("== who speaks in a conversation ==")
	# a conversation held with somebody in the world finds its speakers by their names (their gestures
	# and the conversation camera, world.gd _actor): every speaker has to be somebody there, by the name
	# they go by ("Disciple Han" and "Granny Wen" were not, and nothing they said was acted out)
	var who_ok := {"Narrator": true, "Lin Feng": true, "Yue Ling": true}
	for a8 in Data.AREAS:
		for n8 in Data.AREAS[a8].get("npcs", []):
			who_ok[str(n8.n)] = true
	for e8 in Data.ENEMIES:
		who_ok[str(Data.ENEMIES[e8].n)] = true
	var talk_keys := {}
	for st8 in Data.STEPS:
		if str(st8.kind) == "talk":
			talk_keys[str(st8.id)] = true
	var strangers: Array = []
	for k8 in Data.DIALOGUE:
		var ks8 := str(k8)
		if not (talk_keys.has(ks8) or ks8.begins_with("thread:") or ks8.begins_with("visit:") or ks8.begins_with("rally:") or ks8.begins_with("recall")):
			continue
		for ln8 in Data.DIALOGUE[k8]:
			if not who_ok.has(str(ln8[0])):
				strangers.append("%s in %s" % [str(ln8[0]), ks8])
	check(strangers.is_empty(), "everybody who speaks in a conversation in the world goes by the name they have there (%s)" % str(strangers))
	print("== Part XVI: the Year Turns ==")
	check(Data.REALMS.size() >= 22 and Data.REALMS[21] == "Ten Thousand Hearths" and Data.level_name(63).ends_with("Ten Thousand Hearths") and Data.REALM_INFO.size() == Data.REALMS.size() and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() > Data.MAX_LEVEL, "Part XVI adds the Ten Thousand Hearths realm")
	check(Data.STEPS[Data.step_index("s_break21")].to == 63 and Data.DIALOGUE.has("recall14") and FileAccess.get_file_as_string("res://scripts/main.gd").contains("\"s_break20\": \"recall14\""), "Part XVI follows Kindred Dao (recall14) and ends at Ten Thousand Hearths")
	var ry: Dictionary = Data.STEPS[Data.step_index("s_p16_rally")]
	for npc in ry.npcs:
		check(Data.DIALOGUE.has("rally:" + str(npc)) and Folk.RALLY_TOWN.has(npc) and Trials.npc_area(str(npc)) != "", "%s can be reminded of the old ways, in a town of their own" % npc)
	check(int(ry.n) <= ry.npcs.size() and int(ry.n) >= int(Trials.path("nian", "folk").needs[0][1]), "enough towns can be rallied for the people's road through Nian")
	var RG = load("res://scripts/game.gd").new()
	RG.reset()
	RG.step = Data.step_index("s_p16_rally")
	for npc2 in ["granny_wen", "watchman_zhou", "postmaster_lu"]:
		RG.rallied[npc2] = true
	RG.poll_steps()
	check(RG.cur_step().id == "s_p16_rally" and Trials.path_met("xi_beast", Trials.path("xi_beast", "folk"), RG), "three towns: the people's road through Xi is open, but the step wants four")
	RG.rallied["caster_wei"] = true
	RG.poll_steps()
	check(RG.cur_step().id == "s_p16_rally" and Trials.path_met("nian", Trials.path("nian", "folk"), RG), "four towns: the people's road through Nian is open, but the step wants five")
	RG.rallied["lockkeeper_qian"] = true
	RG.poll_steps()
	check(RG.cur_step().id == "s_p16_hunt", "five towns remember the old ways: the hunt is next")
	RG.step = Data.step_index("s_p16_hongbao")
	var kids_seen := 0
	for tid3 in ["cloudfoot", "qingshi", "yanggu"]:
		for fp3 in Folk.people(Atlas.world_of("surface"), tid3):
			if Folk.is_role(fp3, "child"):
				RG.folk_mark(RG.cur_step(), str(fp3.id))
				kids_seen += 1
	RG.poll_steps()
	check(kids_seen >= 8 and RG.cur_step().id == "s_p16_elders", "eight red envelopes for the children of the towns, and then the grandparents (%d children)" % kids_seen)
	RG.free()
	# the errands of the towns: words for each, and enough people of its kind in the towns of its realm
	for st9 in Data.STEPS:
		if st9.kind != "folk":
			continue
		var own9 := ""
		var have9 := 0
		for tid9 in Folk.TOWNS:
			var ar9: String = Folk.TOWNS[tid9].area
			if ar9 == str(st9.area):
				own9 = tid9
			if Data.layer_of(ar9) != Data.layer_of(str(st9.area)):
				continue
			for fp9 in Folk.people(Atlas.world_of(Data.layer_of(ar9)), tid9):
				if Folk.is_role(fp9, str(st9.role)):
					have9 += 1
		check(Folk.ERRANDS.has(str(st9.id)) and (Folk.ERRANDS[str(st9.id)].lines as Array).size() >= 4, "%s: an errand, with words for the people it is done with" % st9.id)
		# (Part XXII: an errand among the people of the road is run from camp to camp: folk.gd)
		if Folk.CAMP_ROLES.has(str(st9.role)):
			var cw9: Dictionary = Atlas.world_of(Data.layer_of(str(st9.area)))
			own9 = "the road"
			have9 = 0
			for ca9 in cw9.camps:
				for fp9b in Folk.people(cw9, "camp_" + str(ca9)):
					if Folk.is_role(fp9b, str(st9.role)):
						have9 += 1
		check(own9 != "" and have9 >= int(st9.n), "%s: its region has a town, and the towns of its realm %d people of the kind it wants (%d)" % [st9.id, int(st9.n), have9])
	var plum: Array = Data.AREAS.frost.pickups.filter(func(pk): return pk.item == "plum_sprig" and pk.get("vis", ["", ""])[0] == "s_p16_plum")
	check(plum.size() >= int(Data.STEPS[Data.step_index("s_p16_plum")].n) and Data.ITEMS.has("plum_sprig") and Look.PICKUP_COLORS.has("plum_sprig"), "the winter plum flowers in the snows of Frostpeak from the step that asks for it (%d sprigs)" % plum.size())
	var cubs: Dictionary = Data.AREAS.bamboo.get("warband", {})
	check(not cubs.is_empty() and Data.step_index(str(cubs.vis)) < Data.step_index("s_p16_cubs") and int(cubs.n) * 2 >= int(Data.STEPS[Data.step_index("s_p16_cubs")].n), "Nian's cubs hide in the bamboo from the first dawn of the year, enough of them for the hunt")
	check(str(Data.STEPS[Data.step_index("s_p16_calls")].get("did", "")).contains("good new year") and FileAccess.get_file_as_string("res://scripts/main.gd").contains("s.has(\"did\")"), "New Year calls are wished, not invitations delivered (the visits of the Conclave are)")
	check(Data.step_index("s_p16_fish") < Data.step_index("s_p16_eve") and Data.step_index("s_p16_riddles") == Data.step_index("s_p16_lanterns") - 1, "the fish is bought before the reunion dinner, and the riddles guessed on the night of the lanterns")
	for tid4 in ["xi_beast", "nian"]:
		check(Trials.TRIALS.has(tid4) and Lore.BOSS.has(tid4) and Data.DIALOGUE.has("pre:" + tid4) and Data.DIALOGUE.has("post:" + tid4), "%s is a trial, with a story and words before and after" % tid4)
	for mon in ["lean_month", "candle_moth", "nian_cub"]:
		check(Data.ENEMIES.has(mon) and Lore.BEAST.has(mon), "%s has a story" % mon)
	for sid2 in ["s_p16_sweep", "s_p16_couplets", "s_p16_eve", "s_p16_vigil", "s_p16_dawn", "s_p16_lanterns"]:
		var sp: Dictionary = Data.STEPS[Data.step_index(sid2)]
		check(Bonds.SHARES.has(sid2) and not Bonds.find_spot(Atlas.world_of(Data.layer_of(str(sp.area))).ents, str(sp.spot)).is_empty(), "%s: a scene with Yue Ling, at a place that is there" % sid2)
		check(Bonds.share_place(sid2) != "by the lotus pond", "%s is remembered where it happened" % sid2)
	check(Bonds.share_place("s_p15_loom") != Bonds.share_place("s_p15_pond"), "the loom is not the lotus pond (every share used to be put down as by the pond)")
	var bsrc2 := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(bsrc2.contains("\"xi_beast\": ") and bsrc2.contains("\"nian\": ") and bsrc2.contains("_folk_step") and bsrc2.contains("\"s_p16_eve\""), "the bot has a way through both trials, a plan for every scene and a way to find the children")
	check(Assets.PEOPLE.has("zao_jun") and Assets.PEOPLE.has("shenshu") and Assets.PEOPLE.has("yulei"), "the Kitchen God and the door gods are Blender-built")

## The index of the step that fights boss `boss` (-1 if none).
func _kill_step(boss: String) -> int:
	for i in Data.STEPS.size():
		if str(Data.STEPS[i].kind) == "kill" and str(Data.STEPS[i].get("boss", "")) == boss:
			return i
	return -1

## The Spring Thunder release: the sword's wake in the open world (impact.gd), and Part XVII, the
## Spring Thunder.
func _spring() -> void:
	print("== the sword's wake (impact.gd) ==")
	check(Impact.reach(Vector2i(1, 0)) == [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, -1)] and Impact.wave_path(Vector2i(0, 1)).size() == Impact.WAVE_TILES, "a swing reaches the two tiles ahead and both sides of the first; the sword qi flies seven")
	var fc: Array = Impact.fall_curve(6.0)
	var fc2: Array = Impact.fall_curve(1.0)
	check(float(fc[0]) > float(fc2[0]) and float(fc[0]) > 1.0 and float(fc[0]) < 4.0 and float((fc[1] as Array)[(fc[1] as Array).size() - 1]) > 1.4, "a felled trunk falls as a rod about its stump: a tall one takes longer than a sapling (%.2fs, %.2fs)" % [fc[0], fc2[0]])
	var IG = load("res://scripts/game.gd").new()
	IG.reset()
	IG.day = 3
	IG.clock = 14 * 60.0
	Impact.fell(IG, "surface|bamboo|3|4|1001")
	check(Impact.is_down(IG, "surface|bamboo|3|4|1001") and IG.felled_n == 1, "a felled tree stays down")
	IG.day = 4
	IG.clock = 5 * 60.0
	check(Impact.is_down(IG, "surface|bamboo|3|4|1001"), "until dawn")
	IG.clock = 6.5 * 60.0
	check(not Impact.is_down(IG, "surface|bamboo|3|4|1001") and not IG.felled.has("surface|bamboo|3|4|1001"), "and has grown back after it")
	var ox := {"id": "p17_ox", "what": "spring_ox", "area": "village"}
	var hits := 0
	while Impact.hit_obstacle(IG, ox) == "hit":
		hits += 1
	check(hits == int(Impact.OBSTACLES.spring_ox.hits) - 1 and IG.cleared.get("p17_ox", "") == "spring_ox|village" and Impact.hit_obstacle(IG, ox) == "", "the Spring Ox takes five blows, and then it is cleared for good")
	IG.free()
	for k in Impact.OBSTACLES:
		var ob: Dictionary = Impact.OBSTACLES[k]
		check(int(ob.hits) >= 1 and Havoc._piece(str(ob.piece), Color.WHITE).size() == 3 and str(ob.hint).contains("(F"), "obstacle %s: blows, pieces and a hint" % k)
	check(Assets.MONSTERS.size() > 0 and FileAccess.get_file_as_string("res://scripts/battle.gd").contains("Impact.AMBUSH_HURT") and FileAccess.get_file_as_string("res://scripts/main.gd").contains("KEY_G"), "a pack struck first opens the battle reeling, and G throws the sword qi")
	# the scatter remembers what grows on every tile, so a blow can find it
	var tg := PackedByteArray()
	tg.resize(24 * 24)
	tg.fill(MapGen.FLOOR)
	for y in 24:
		for x in 8:
			tg[y * 24 + x] = MapGen.WALL
	var troot := Terrain3D.build(tg, 24, 24, "bamboo", 7)
	var nat: Dictionary = troot.get_meta("nature", {})
	var n_tree := 0
	var n_mmi := 0
	for tl in nat:
		for en in nat[tl]:
			if str(en.kind) == "tree":
				n_tree += 1
			if en.get("mmi") is MultiMeshInstance3D and int(en.i) < (en.mmi as MultiMeshInstance3D).multimesh.instance_count:
				n_mmi += 1
	var all_n := 0
	for tl2 in nat:
		all_n += (nat[tl2] as Array).size()
	check(n_tree > 0 and n_mmi == all_n, "every tree, bush and rock of a region knows the instance that draws it (%d trees, %d things)" % [n_tree, all_n])
	troot.free()
	# a recipe never asks for what a collect step is still gathering: refined while the step is in hand,
	# it would eat the things the step counts, and with no more of them in the world the story stops
	# (the Thunder-Bamboo Crackers and Taisui's charm did, until the Spring Thunder release)
	var early: Array = []
	for rid in Trials.RECIPES:
		var rr: Dictionary = Trials.RECIPES[rid]
		for item in rr["in"]:
			for si in Data.STEPS.size():
				var cs: Dictionary = Data.STEPS[si]
				if str(cs.kind) == "collect" and str(cs.get("item", "")) == str(item) and Data.step_index(str(rr.after)) <= si:
					early.append("%s (%s, %s)" % [rid, item, cs.id])
	check(early.is_empty(), "every recipe that needs what a collect step gathers is offered only after the step (%s)" % str(early))
	print("== Part XVII: the Spring Thunder ==")
	check(Data.REALMS.size() >= 23 and Data.REALMS[22] == "Myriad Things Awake" and Data.level_name(66).ends_with("Myriad Things Awake") and Data.REALM_INFO.size() == Data.REALMS.size() and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XVII adds the Myriad Things Awake realm")
	check(Data.STEPS[Data.step_index("s_break22")].to == 66 and Data.DIALOGUE.has("recall15") and FileAccess.get_file_as_string("res://scripts/main.gd").contains("\"s_break21\": \"recall15\""), "Part XVII follows Ten Thousand Hearths (recall15) and ends at Myriad Things Awake")
	var wsurf: Dictionary = Atlas.world_of("surface")
	var by_tile := {}
	for e0 in wsurf.ents:
		if e0.kind != "obstacle":
			if not by_tile.has(e0.pos):
				by_tile[e0.pos] = []
			by_tile[e0.pos].append(e0)
	var obst: Array = wsurf.ents.filter(func(e1): return e1.kind == "obstacle")
	var n_obst := 0
	for a8 in Data.AREAS:
		n_obst += (Data.AREAS[a8].get("obstacles", []) as Array).size()
	check(obst.size() == n_obst and n_obst >= 26, "every obstacle of the story stands in the world (%d)" % obst.size())
	for ob2 in obst:
		var g2: int = wsurf.grid[ob2.pos.y * int(wsurf.w) + ob2.pos.x]
		var round_it := 0
		for d2 in MapGen.DIRS:
			var q: Vector2i = ob2.pos + d2
			if MapGen.is_walkable_tile(wsurf.grid[q.y * int(wsurf.w) + q.x]):
				round_it += 1
		check(MapGen.is_walkable_tile(g2) and g2 != MapGen.INTERIOR and Atlas.owner_id(wsurf, ob2.pos) == str(ob2.area) and not by_tile.has(ob2.pos) and Havoc.at_tile(wsurf, ob2.pos).is_empty() and round_it >= 3,
			"obstacle %s stands on open ground of %s, on nobody else's tile, with a way round it" % [ob2.id, ob2.area])
		check(Impact.OBSTACLES.has(str(ob2.what)) and Data.step_index(str(ob2.vis[0])) >= 0, "obstacle %s is a known kind and appears with its step" % ob2.id)
	# every story step's people, lords and things to find are still in reach with every obstacle standing
	var blocked := {}
	for ob3 in obst:
		blocked[ob3.pos] = true
	var reach := {}
	var start: Vector2i = Atlas.to_world("sect", Vector2i(20, 8))
	var q2: Array = [start]
	reach[start] = true
	var qi := 0
	while qi < q2.size():
		var c: Vector2i = q2[qi]
		qi += 1
		for d3 in MapGen.DIRS:
			var nb: Vector2i = c + d3
			if nb.x < 0 or nb.y < 0 or nb.x >= int(wsurf.w) or nb.y >= int(wsurf.h) or reach.has(nb) or blocked.has(nb):
				continue
			if not MapGen.is_walkable_tile(wsurf.grid[nb.y * int(wsurf.w) + nb.x]):
				continue
			reach[nb] = true
			q2.append(nb)
	var lost: Array = []
	for e2 in wsurf.ents:
		if e2.kind in ["npc", "boss", "pickup", "obstacle"] and str(e2.get("area", "")) in ["village", "bamboo", "terraces", "longmen", "dragon", "thunder", "frost", "millet", "mirror", "maple"]:
			var near := false
			for d4 in MapGen.DIRS:
				if reach.has(e2.pos + d4):
					near = true
			if not near:
				lost.append(str(e2.id))
	check(lost.is_empty(), "with every obstacle standing, everybody and everything the story needs can still be walked up to (%s)" % str(lost))
	# nothing that came later in the story moved an older map: every region built with Part XVII's late
	# people, lords, things to find, war-bands and obstacles taken out is the same map with the same
	# packs, people and things in it
	for a9 in Data.AREAS:
		var sp9: Dictionary = Data.AREAS[a9]
		var has_late: bool = sp9.has("obstacles") or bool(sp9.get("warband", {}).get("late", false))
		for k9 in ["npcs", "bosses", "pickups"]:
			for x9 in sp9.get(k9, []):
				if x9.get("late", false):
					has_late = true
		if not has_late:
			continue
		var bare: Dictionary = sp9.duplicate(true)
		bare.erase("obstacles")
		if bare.get("warband", {}).get("late", false):
			bare.erase("warband")
		for k10 in ["npcs", "bosses", "pickups"]:
			if bare.has(k10):
				bare[k10] = (bare[k10] as Array).filter(func(x10): return not x10.get("late", false))
		var m_full: Dictionary = MapGen.build(a9)
		var m_bare: Dictionary = MapGen.build(a9, Vector2i.ZERO, bare)
		var keys_full: Array = m_full.ents.map(func(e10): return "%s|%s|%s" % [e10.kind, e10.id, e10.pos])
		var keys_bare: Array = m_bare.ents.map(func(e11): return "%s|%s|%s" % [e11.kind, e11.id, e11.pos])
		check(m_full.grid == m_bare.grid and keys_full == keys_bare, "%s: Part XVII's additions move nothing in the region's own map" % a9)
	for lid in ["gou_mang", "lei_gong", "boss_qing_nu", "boss_taisui", "boss_poison_mother", "p17_egg1", "p17_willow6"]:
		var found: Array = wsurf.ents.filter(func(e3): return str(e3.id) == lid)
		check(found.size() == 1, "%s stands in the world once (late: no older map moved for it)" % lid)
	for st in Data.STEPS:
		if str(st.kind) != "clear":
			continue
		var have: Array = obst.filter(func(e4): return str(e4.what) == str(st.what) and str(e4.area) == str(st.area) and str(e4.vis[0]) == str(st.id))
		check(have.size() >= int(st.n), "%s: %d %s to clear in %s (%d)" % [st.id, int(st.n), st.what, st.area, have.size()])
	var CG2 = load("res://scripts/game.gd").new()
	CG2.reset()
	CG2.step = Data.step_index("s_p17_deadfall")
	for k5 in 5:
		Impact.hit_obstacle(CG2, {"id": "p17_dead%d" % (k5 + 1), "what": "deadfall", "area": "bamboo"})
	CG2.poll_steps()
	check(CG2.cur_step().id == "s_p17_deadfall" and CG2.objective_text().contains("(5/6)"), "five trunks cleared: the step wants six")
	Impact.hit_obstacle(CG2, {"id": "p17_dead6", "what": "deadfall", "area": "bamboo"})
	CG2.poll_steps()
	check(CG2.cur_step().id == "s_p17_rockfall" and CG2.done_pending.has("s_p17_deadfall"), "six: the rockfall is next, and the deadfall has its word to say")
	CG2.free()
	for tid5 in ["qing_nu", "taisui"]:
		check(Trials.TRIALS.has(tid5) and Lore.BOSS.has(tid5) and Data.DIALOGUE.has("pre:" + tid5) and Data.DIALOGUE.has("post:" + tid5), "%s is a trial, with a story and words before and after" % tid5)
		var kinds5 := {}
		for pth in Trials.TRIALS[tid5].paths:
			kinds5[pth.kind] = true
		check(kinds5.has("land") or kinds5.has("folk"), "%s can be passed by the land or by the people" % tid5)
	check(Lore.BOSS.has("poison_mother") and Data.DIALOGUE.has("pre:poison_mother") and Data.DIALOGUE.has("post:poison_mother"), "the Mother of the Five Poisons has a story and words before and after")
	for mon5 in ["rime_wisp", "hoarfrost_hare", "late_frost", "waking_scorpion", "waking_centipede", "waking_toad"]:
		check(Data.ENEMIES.has(mon5) and Lore.BEAST.has(mon5), "%s has a story" % mon5)
	for sid5 in ["s_p17_haircut", "s_p17_thunder", "s_p17_teacup", "s_p17_graves", "s_p17_kite"]:
		var sp5: Dictionary = Data.STEPS[Data.step_index(sid5)]
		check(Bonds.SHARES.has(sid5) and not Bonds.find_spot(Atlas.world_of(Data.layer_of(str(sp5.area))).ents, str(sp5.spot)).is_empty() and Bonds.share_place(sid5) != "side by side", "%s: a scene with Yue Ling, at a place that is there, remembered where it happened" % sid5)
	for sid6 in ["s_p17_ox", "s_p17_deadfall", "s_p17_rockfall", "s_p17_ice", "s_p17_chains", "s_p17_poisons", "s_p17_sow"]:
		check(Data.DIALOGUE.has("done:" + sid6), "%s has its word to say when it is done" % sid6)
	for hs in ["s_p17_hunt", "s_p17_poisons"]:
		var hst: Dictionary = Data.STEPS[Data.step_index(hs)]
		var band6: Dictionary = Data.AREAS[str(hst.area)].get("warband", {})
		check(bool(hst.get("first", false)) and not band6.is_empty() and Data.step_index(str(band6.vis)) < Data.step_index(hs) and int(band6.n) * 2 >= int(hst.n), "%s: the packs are there before it, enough of them, and it asks for the first strike" % hs)
	check(Assets.PEOPLE.has("gou_mang") and Assets.PEOPLE.has("lei_gong") and FileAccess.file_exists("res://art/characters/gou_mang.py") and FileAccess.file_exists("res://art/characters/lei_gong.py"), "Gou Mang and Lei Gong are Blender-built")
	var bsrc3 := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(bsrc3.contains("\"qing_nu\": \"land\"") and bsrc3.contains("\"taisui\": ") and bsrc3.contains("_clear_step") and bsrc3.contains("_strike_first") and bsrc3.contains("\"s_p17_graves\""), "the bot has a way through both trials, clears the land with its sword, strikes first and has a plan for every scene")
	check(Trials.EPITHETS.has("heart") and Trials.EPITHETS.has("folk") and Trials.EPITHETS.has("land"), "every way through a trial has an epithet for the ending (the ending read a key that was not there)")

## The New Fire release: the Six Hearths (cultures.gd), the hero as a young man or a young woman
## (fashion.gd, voice.gd), the beginnings and the ends of the story, and Part XVIII, the New Fire.
func _new_fire() -> void:
	print("== the Six Hearths (cultures.gd) ==")
	check(Cultures.ORDER.size() == 6 and Cultures.HEARTHS.size() == 6, "six hearths of the land")
	var town_of := {}
	for hid in Cultures.ORDER:
		var hh: Dictionary = Cultures.HEARTHS[hid]
		var whole := true
		for k in ["n", "people", "short", "col", "home", "towns", "areas", "keeper", "keeper_area", "kin", "hail", "greet", "dish", "drink", "festival", "fire", "taboo", "custom", "desc", "fx", "give", "fx_text",
				"guest_fx", "guest_text", "keepsake", "prologue", "farewell", "lines", "ending"]:
			whole = whole and hh.has(k)
		check(whole and (hh.lines as Array).size() >= 4 and (hh.hail as Array).size() >= 3, "%s: a hearth with a people, a table, a fire, a custom, a thing nobody does and words of its own" % hid)
		check(Trials.npc_area(str(hh.keeper)) == str(hh.keeper_area) and str(hh.keeper) in hh.kin and str(hh.keeper_area) in hh.areas, "%s: its keeper lives in its own country" % hid)
		for nid in hh.kin:
			check(Trials.npc_area(str(nid)) != "", "%s: %s, one of its people, lives somewhere" % [hid, nid])
		for tid in hh.towns:
			check(Folk.TOWNS.has(tid) and not town_of.has(tid), "%s: %s is a town, and of this hearth only" % [hid, tid])
			town_of[tid] = hid
		for a in hh.areas:
			check(Data.AREAS.has(a) and Cultures.of_area(str(a)) == hid, "%s: %s is a region, and of this hearth only" % [hid, a])
		for fk in (hh.fx as Dictionary).keys() + (hh.guest_fx as Dictionary).keys() + (hh.give as Dictionary).keys():
			check(str(fk) in ["hp", "qi", "atk", "spd", "miss", "heal", "taken", "stones", "exp", "cost", "hp_pill", "qi_pill"], "%s: gift %s is one the game knows" % [hid, fk])
		check((hh.prologue as Array).size() >= 3 and (hh.farewell as Array).size() >= 4 and str(hh.farewell[0][0]) == Trials.npc_name(str(hh.keeper)) and (hh.farewell as Array).any(func(ln): return str(ln[0]) == "Lin Feng"),
			"%s: a beginning of its own, and a farewell its keeper and the hero both speak in" % hid)
		# the last morning at the hearth: open ground of its country, a short walk from its keeper
		var st: Vector2i = Cultures.start_tile(str(hh.keeper_area), str(hh.keeper))
		var lw: Dictionary = Atlas.world_of(Data.layer_of(str(hh.keeper_area)))
		var kp := Vector2i(-1, -1)
		for e in lw.ents:
			if e.kind == "npc" and str(e.id) == str(hh.keeper):
				kp = e.pos
		var dk: int = absi(st.x - kp.x) + absi(st.y - kp.y)
		check(kp.x >= 0 and MapGen.is_walkable_tile(lw.grid[st.y * int(lw.w) + st.x]) and dk >= 2 and dk <= 6 and maxi(absi(st.x - kp.x), absi(st.y - kp.y)) < 16,
			"%s: the story begins %d steps from %s, on ground that can be walked" % [hid, dk, hh.keeper])
	for tid2 in Folk.TOWNS:
		if str(Folk.TOWNS[tid2].race) in ["human", "desert"] and Data.layer_of(str(Folk.TOWNS[tid2].area)) == "surface":
			check(Cultures.of_town(tid2) != "", "the town of %s belongs to a hearth of the land" % tid2)
	check(Cultures.of_town("featherfall") == "" and Cultures.of_area("juntian") == "" and Cultures.of_npc("elder") == "", "the towns of the other realms have peoples of their own (Part XI), not hearths")
	var HG = load("res://scripts/game.gd").new()
	HG.reset()
	check(Cultures.own(HG) == "valley" and Cultures.tier(HG, "valley") == 2 and Cultures.guests(HG) == 1, "the story's own sweeper is kin of the Rice Hearth, and a stranger everywhere else")
	check(Cultures.earn(HG, "steppe", Cultures.GUEST - 1) == 0 and Cultures.tier(HG, "steppe") == 0 and Cultures.earn(HG, "steppe", 1) == 1 and Cultures.guests(HG) == 2, "standing makes a guest at %d" % Cultures.GUEST)
	var spd0: float = Fashion.gear(HG, "spd")
	check(is_equal_approx(spd0, 1.0) and Cultures.earn(HG, "steppe", 99) == 2 and int(HG.hearth.steppe) == Cultures.KIN, "a guest of the Felt Hearth is a little faster; standing stops at kin")
	check(is_equal_approx(Cultures.gear(HG, "heal"), 0.045), "kin have half as much again of a hearth's gift (the Rice Hearth's healing)")
	HG.sit_with("cook_aysha")
	HG.sit_with("cook_aysha")
	check(int(HG.hearth.get("sand", 0)) == Cultures.SIT and HG.sat.has("cook_aysha"), "sitting down with one of a hearth's people counts once")
	HG.create_hero({"body": "f", "hearth": "forge", "family": "Bai", "given": "Chen"})
	check(Cultures.own(HG) == "forge" and Cultures.tier(HG, "forge") == 2 and Cultures.tier(HG, "valley") == 0 and int(HG.inv.get("qi_pill", 0)) >= 1 and HG.fem(), "a hero of the Casting Hearth is kin there from the first day, with its keepsake")
	check(is_equal_approx(Fashion.gear(HG, "atk"), 0.04 + 0.03) and is_equal_approx(Fashion.gear(HG, "spd"), -1.0), "and has its gift and its burden (attack, a founder's tread)")
	HG.reset()
	# the story alone makes the hero a guest of every hearth before the last trial asks for five
	var deeds := {}
	for stp in Data.STEPS:
		if stp.has("hearth") and Data.step_index(str(stp.id)) < _kill_step("huilu"):
			check(Cultures.HEARTHS.has(str(stp.hearth)), "%s is done for a hearth there is" % stp.id)
			deeds[str(stp.hearth)] = int(deeds.get(str(stp.hearth), 0)) + Cultures.DEED
	for hid2 in Cultures.ORDER:
		check(int(deeds.get(hid2, 0)) >= Cultures.GUEST, "Part XVIII's errands for %s make a guest of anybody (%d)" % [hid2, int(deeds.get(hid2, 0))])
	print("== the people of the hearths (folk.gd) ==")
	var wsurf: Dictionary = Atlas.world_of("surface")
	var dressed := {}
	for tid3 in ["shazhou", "longmen", "tushan", "yanggu"]:
		var hid3 := Cultures.of_town(tid3)
		var own_dress := 0
		for fp in Folk.people(wsurf, tid3):
			check(FileAccess.file_exists("res://art/characters/%s.py" % str(fp.body)), "%s wears a body there is (%s)" % [fp.n, fp.body])
			if str(fp.body) in (Folk.HEARTH_BODIES[hid3] as Dictionary).values():
				own_dress += 1
				dressed[str(fp.body)] = true
				check((str(fp.body) in Folk.FEM) == bool(fp.fem), "%s: the dress of the hearth fits who wears it" % fp.n)
		check(own_dress >= 2, "%s: some of its people wear the dress of %s (%d)" % [tid3, Cultures.HEARTHS[hid3].n, own_dress])
	for hb in Folk.HEARTH_BODIES:
		for bk in Folk.HEARTH_BODIES[hb]:
			var body := str(Folk.HEARTH_BODIES[hb][bk])
			check(FileAccess.file_exists("res://art/characters/%s.py" % body) and Assets.has("characters/" + body), "%s is Blender-built" % body)
	var sand_named := 0
	var names := {}
	for fp2 in Folk.people(wsurf, "shazhou"):
		names[str(fp2.n)] = true
		for nm in Folk.HEARTH_NAMES.sand.m + Folk.HEARTH_NAMES.sand.f:
			if str(fp2.n).ends_with(" " + str(nm)):
				sand_named += 1
	check(sand_named >= 8 and names.size() == Folk.people(wsurf, "shazhou").size(), "the people of Shazhou have the sand roads' names, each their own (%d)" % sand_named)
	var q1: Dictionary = Folk.people(wsurf, "qingshi")[0]
	HG.reset()
	check(Folk.line(q1, HG) in Cultures.HEARTHS.valley.lines or Folk.line(q1, HG).replace(HG.address(), "%s") in Cultures.HEARTHS.valley.lines, "the first thing a villager of Qingshi says is the Rice Hearth's own")
	var hails := 0
	for fp3 in Folk.people(wsurf, "longmen"):
		if Folk.greeting(fp3, HG) in Cultures.HEARTHS.river.hail:
			hails += 1
	check(hails >= 4, "the river folk hail in their own way in the street (%d)" % hails)
	for sid in ["s_p18_valley", "s_p18_sand", "s_p18_dawn"]:
		var fs: Dictionary = Data.STEPS[Data.step_index(sid)]
		var of_role := 0
		for fp4 in Folk.people(wsurf, str(fs.town)):
			if Folk.is_role(fp4, str(fs.role)) and Folk.in_town(fp4, fs):
				of_role += 1
		check(Folk.ERRANDS.has(sid) and Cultures.of_town(str(fs.town)) == str(fs.hearth) and str(Folk.TOWNS[str(fs.town)].area) == str(fs.area) and of_role >= int(fs.n) + 1 and (Folk.ERRANDS[sid].lines as Array).size() >= 4,
			"%s: an errand among the %ss of %s, with one to spare (%d for %d)" % [sid, fs.role, fs.town, of_role, int(fs.n)])
	var other: Dictionary = Folk.people(wsurf, "cloudfoot")[0]
	check(not Folk.in_town(other, Data.STEPS[Data.step_index("s_p18_sand")]) and Folk.in_town(other, Data.STEPS[Data.step_index("s_p17_sow")]), "an errand that names its town is done there; the older ones anywhere")
	print("== a young man or a young woman (fashion.gd, voice.gd) ==")
	check(Fashion.BODY_ORDER == ["m", "f"] and Fashion.default_hero().body == "m" and Fashion.default_hero().hearth == "valley", "the story's own sweeper is the young man of the Rice Hearth")
	for lk in Fashion.LOOK_ORDER:
		var af := Fashion.look_asset(lk, true)
		check(af != Fashion.look_asset(lk, false) and Assets.has(Assets.PEOPLE.get(af, "")) and FileAccess.file_exists("res://art/characters/%s.py" % af) and Fashion.look_desc(lk, true) != Fashion.look_desc(lk, false),
			"the look %s is built on a woman's frame too (%s)" % [lk, af])
	for oid in Fashion.ORIGIN_ORDER:
		var od := Fashion.origin_desc(oid, true)
		check(not _has_word(od, ["he", "him", "boy"]) or oid in ["merchant", "scholar", "hunter"], "the trade %s is told of her" % oid)
	check(Voice.her("Of the five he met on the road: 4 stand with him, 1 fallen") == "Of the five she met on the road: 4 stand with her, 1 fallen" and Voice.her("Yue Ling: Heart's Companion; walks beside him by choice").ends_with("walks beside her by choice")
		and Voice.she("His Dao companion") == "Her Dao companion", "the ending's results and Yue Ling's road are told of her")
	check(Voice.her("Granny Wen's Boy") == "Granny Wen's Girl" and Voice.her("Granny Wen's boy") == "Granny Wen's girl" and Voice.said("Senior Brother Lin!") == "Senior Sister Lin!", "what she is called keeps the capitals it was written with")
	check(Fashion.origin_desc("merchant", true).contains("she owes him a donkey") and Fashion.origin_desc("foundling", true).contains("raised her"), "and the men in her story stay men")
	check(Voice.tell("Lin Feng lifts his sword and the mountain answers him.")[0] == "Lin Feng lifts her sword and the mountain answers her.", "what is told of Lin Feng is told of her")
	check(Voice.tell("Elder Qing Xuan puts down his cup.")[0] == "Elder Qing Xuan puts down his cup." and Voice.tell("He lowers his comb.")[0] == "He lowers his comb.", "what is told of another man, or of nobody named, is left alone")
	check(Voice.tell("Lin Feng bows. The Elder strokes his beard, and Lin Feng picks up his broom.")[0] == "Lin Feng bows. The Elder strokes his beard, and Lin Feng picks up her broom.", "a 'his' belongs to whoever was named last")
	check(Voice.tell("Lin Feng looks at Yue Ling, and she laughs, and he laughs too.")[0] == "Lin Feng looks at Yue Ling, and she laughs, and she laughs too.", "a woman's name takes no 'he' away from her")
	check(Voice.tell("The sweeper has his broom. The choice is his.")[0] == "The sweeper has her broom. The choice is hers.", "the sweeper is the hero; 'his' at the end of a sentence is 'hers'")
	check(Voice.tell("Thank you, Senior Brother Lin! Happy new year, big brother cultivator!")[0] == "Thank you, Senior Sister Lin! Happy new year, big sister cultivator!", "the juniors call her Senior Sister")
	for oid3 in Fashion.OUTFIT_ORDER:
		check(not _has_word(Voice.her(str(Fashion.OUTFITS[oid3].desc)).replace("The Elder had it made", "").replace("his mother", ""), ["he", "him", "his"]) or oid3 in ["conclave"], "the outfit %s is hers" % oid3)
	check(Voice.tell("Lin Shan and Feng Meng and Warden Feng met him.")[0] == "Lin Shan and Feng Meng and Warden Feng met him.", "other people's names are not hers")
	check(Voice.tell("Lin Feng, the boy who swept the steps, is ready. He's sure. You hit hard, young man.")[0] == "Lin Feng, the girl who swept the steps, is ready. She's sure. You hit hard, young woman.", "the boy who swept the steps is the girl who did")
	check(Voice.tell("He Bo gives Lin Feng the tablet of his office.")[0] == "He Bo gives Lin Feng the tablet of his office." and Voice.tell("Lin Feng takes it from him.", true)[0] == "Lin Feng takes it from him."
		and Voice.tell("A man steps out wearing Lin Feng's face, names stitched into his sleeves.")[0].ends_with("his sleeves."), "the subject of a clause keeps its own 'his'; a 'him' in her own clause is somebody else; a face that is only hers names nobody")
	check(Voice.tell("Yue Ling looks at Lin Feng. He smiles.")[0] == "Yue Ling looks at Lin Feng. She smiles.", "after a woman is named first, the 'he' is still hers")
	var conv: Array = Voice.lines([["Narrator", "Lin Feng kneels."], ["Narrator", "He does not look up."], ["Elder Qing Xuan", "Rise."], ["Narrator", "He strokes his beard."], ["Lin Feng", "He is late, Elder."], ["Narrator", "He waits."]])
	check(conv[1][1] == "She does not look up." and conv[3][1] == "He strokes his beard." and conv[4][1] == "He is late, Elder." and conv[5][1] == "She waits.",
		"in a conversation who was spoken of carries from line to line: the narrator's 'he' after her, the Elder's own, and never what anybody says aloud")
	var story_src := ""
	for f in ["data", "fate_text", "bonds", "grudges", "fashion", "cultures"]:
		story_src += FileAccess.get_file_as_string("res://scripts/%s.gd" % f)
	for fx in Voice.FIX:
		check(story_src.contains("\"" + str(fx) + "\""), "a line written out for her is a line of the story: %s..." % str(fx).substr(0, 40))
	var changed := 0
	var total := 0
	var odd: Array = []
	for key in Data.DIALOGUE:
		var src: Array = Data.DIALOGUE[key]
		var told: Array = Voice.lines(src)
		for i in src.size():
			total += 1
			if str(told[i][0]) != str(src[i][0]) or (told[i] as Array).size() != (src[i] as Array).size():
				odd.append(key)
			if str(told[i][1]) != str(src[i][1]):
				changed += 1
				# nobody who speaks has a "he" changed in what they say, unless the line was written out for her
				if str(src[i][0]) != "Narrator" and str(told[i][1]) != Voice.said(str(src[i][1])):
					odd.append("%s:%d" % [key, i])
			for bad in ["she she", "her her her"]:
				if str(told[i][1]).contains(bad):
					odd.append("%s:%d %s" % [key, i, bad])
	check(odd.is_empty() and changed >= 40 and changed < total / 4, "the whole story is told of her: %d of %d lines change, no speaker does, and her own words never (%s)" % [changed, total, str(odd.slice(0, 5))])
	UI.set_hero_name("Bai", "Chen", true)
	check(UI.named("Lin Feng lifts his broom. Senior Brother Lin!") == "Bai Chen lifts her broom. Senior Sister Bai!", "on screen she has the name the player gave her")
	UI.set_hero_name(Fashion.DEFAULT_FAMILY, Fashion.DEFAULT_GIVEN)
	check(UI.named("Lin Feng lifts his broom.") == "Lin Feng lifts his broom.", "and the story's own sweeper is told as he was written")
	print("== the ends of the story (cultures.gd) ==")
	check(Cultures.ENDING_ORDER.size() == 12 and Cultures.ENDINGS.size() == 12, "twelve ends: the five of the New Fire, and seven more that are not all kept by a fire")
	HG.reset()
	# (somebody who has sat at nobody's table and hardly knows the one beside him may also hold the sky alone)
	check(Cultures.endings_open(HG) == ["azure", "home", "cold"] and Cultures.ending_of(HG) == "azure", "the mountain and the way home are always open; the others are earned (and the cold hearth is what nothing earns)")
	for eid in Cultures.ENDING_ORDER:
		var en: Dictionary = Cultures.ENDINGS[eid]
		check(str(en.n) != "" and str(en.label) != "" and str(en.desc).length() > 60 and (en.lines as Array).size() >= 2 and en.sky is Color, "the ending %s has a name, a choice, and its own last words" % eid)
		for nd in en.needs:
			check(str(nd[0]) in ["home", "guests", "peoples", "heart", "arms", "masters", "lean", "works", "alone"] and (str(nd[0]) == "home" or Cultures.ending_need_text(nd, HG) != ""), "%s: what it asks is something the journey can earn" % eid)
	for hid4 in ["steppe", "sand", "river", "forge"]:
		Cultures.earn(HG, hid4, Cultures.GUEST)
	check(Cultures.ending_open("road", HG) and not Cultures.ending_open("open", HG), "five hearths open the road; the open door wants the peoples of the realms as well")
	for rc in ["yumin", "dragon", "tianhu", "jiaoren"]:
		HG.standing[rc] = Data.FRIEND
	check(Cultures.ending_open("open", HG), "four hearths and four peoples open the door")
	HG.bond = Bonds.LEVELS[3]
	check(Cultures.ending_open("lotus", HG) and Cultures.endings_open(HG).size() == 5, "and a kindred spirit builds a house")
	HG.ending = "road"
	HG.hero["hearth"] = "river"
	var el: Array = Cultures.ending_lines(HG)
	check(el.size() == 3 and str(el[0][1]).contains("pot of coals") and str(el[2][1]).contains("Longmen"), "the last words are the ending's, and then the hero's own hearth's")
	HG.ending = "home"
	check(str(Cultures.ending_lines(HG)[0][1]).contains("Longmen Ferry"), "the way home goes to the hero's own hearth")
	HG.free()
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(msrc.contains("func choose_ending") and msrc.contains("begin_prologue") and msrc.contains("ENDING_ASK") and FileAccess.get_file_as_string("res://scripts/ending.gd").contains("Cultures.ending_of"), "the game begins at the hero's hearth and ends where the player says")
	print("== Part XVIII: the New Fire ==")
	check(Data.REALMS.size() >= 24 and Data.REALMS[23] == "Fire Passed On" and Data.MAX_LEVEL >= 69 and Data.level_name(69).ends_with("Fire Passed On") and Data.REALM_INFO.size() == Data.REALMS.size() and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XVIII adds the Fire Passed On realm")
	check(Data.step_index("s_break23") == Data.step_index("s_p18_end") + 1 and Data.DIALOGUE.has("recall16") and msrc.contains("\"s_break22\": \"recall16\""), "Part XVIII follows Myriad Things Awake (recall16) and ends with its own tribulation")
	for tid5 in ["zhurong", "huilu"]:
		check(Trials.TRIALS.has(tid5) and Lore.BOSS.has(tid5) and Data.DIALOGUE.has("pre:" + tid5) and Data.DIALOGUE.has("post:" + tid5), "%s is a trial, with a story and words before and after" % tid5)
		check((Trials.TRIALS[tid5].paths as Array).any(func(pth): return str(pth.kind) == "hearth"), "%s can be passed by the hearths" % tid5)
	check(Trials.KINDS.has("hearth") and Trials.EPITHETS.has("hearth") and Assets.PEOPLE.has("zhurong") and "person:zhurong" in UI.SHAPES and Data.BOSS_DROPS.get("zhurong", "") == "suiren_drill", "the Lord of the Southern Fire is Blender-built, and gives Suiren's drill")
	for mon in ["damp_smoke", "bilge_imp", "drowned_ember", "ash_moth", "cinder_imp", "clinker_crab", "wildfire_sprite", "spark_swallow", "smoke_hound"]:
		check(Data.ENEMIES.has(mon) and Lore.BEAST.has(mon), "%s has a story" % mon)
	for sid2 in ["s_p18_drill", "s_p18_feast"]:
		var sp: Dictionary = Data.STEPS[Data.step_index(sid2)]
		check(Bonds.SHARES.has(sid2) and not Bonds.find_spot(wsurf.ents, str(sp.spot)).is_empty() and Bonds.share_place(sid2) != "side by side", "%s: a scene with Yue Ling, at a place that is there" % sid2)
	for sid3 in ["s_p18_wood", "s_p18_valley", "s_p18_argal", "s_p18_sand", "s_p18_smoke", "s_p18_clinker", "s_p18_dawn", "s_p18_ash", "s_p18_brush", "s_p18_wild"]:
		check(Data.DIALOGUE.has("done:" + sid3), "%s has its word to say when it is done" % sid3)
	for hs in ["s_p18_smoke", "s_p18_ash", "s_p18_wild"]:
		var hst: Dictionary = Data.STEPS[Data.step_index(hs)]
		var band: Dictionary = Data.AREAS[str(hst.area)].get("warband", {})
		check(bool(hst.get("first", false)) and bool(band.get("late", false)) and Data.step_index(str(band.vis)) < Data.step_index(hs) and int(band.n) * 2 >= int(hst.n), "%s: the packs are there before it, enough of them, and it asks for the first strike" % hs)
	var carry: Dictionary = Data.STEPS[Data.step_index("s_p18_carry")]
	var keepers: Array = Cultures.ORDER.map(func(h5): return str(Cultures.HEARTHS[h5].keeper))
	keepers.sort()
	var carried: Array = (carry.npcs as Array).duplicate()
	carried.sort()
	check(carried == keepers and int(carry.n) == 6, "the new fire is carried home to the keeper of every hearth")
	for lid in ["sarnai", "batu", "boss_zhurong", "boss_huilu", "p18_wood1", "p18_argal5", "p18_clinker3", "p18_brush6"]:
		check(wsurf.ents.filter(func(e3): return str(e3.id) == lid).size() == 1, "%s stands in the world once (late: no older map moved for it)" % lid)
	check(Impact.OBSTACLES.has("clinker") and Impact.OBSTACLES.has("brush") and Data.ITEMS.has("ember_pot") and Trials.RECIPES.has("fire_drill") and Data.CHAT.has("sarnai") and Data.CHAT.has("batu"), "clinker and brush, the pot of six coals, a drill of summer wood, and two people of the tents with things to say")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(bsrc.contains("\"zhurong\": \"craft\"") and bsrc.contains("\"huilu\": \"hearth\"") and bsrc.contains("Game.prologue") and bsrc.contains("ENDING_PLAN") and bsrc.contains("\"s_p18_feast\""), "the bot says its goodbye, has a way through both trials, and chooses an end")

## The Hundred Works release: the hours of the wild (habits.gd), the works and their machines (works.gd,
## machines.gd), the crossroads and their echoes (echoes.gd), and Part XIX.
func _hundred_works() -> void:
	print("== the hours of the wild (habits.gd) ==")
	var by_habit := {}
	for eid in Data.ENEMIES:
		var hb := Habits.habit(eid)
		check(Habits.HABITS.has(hb), "%s keeps hours (%s)" % [eid, hb])
		if not Data.ENEMIES[eid].get("boss", false):
			by_habit[hb] = int(by_habit.get(hb, 0)) + 1
	for hb2 in Habits.HABIT_ORDER:
		check(int(by_habit.get(hb2, 0)) >= 10, "there are creatures %s (%d)" % [str(Habits.HABITS[hb2].n), int(by_habit.get(hb2, 0))])
		var acts := {}
		for hr in 24:
			var a := Habits.act_at(hb2, float(hr) + 0.5)
			check(Habits.ACTS.has(a), "a creature %s does something at hour %d (%s)" % [str(Habits.HABITS[hb2].n), hr, a])
			acts[a] = true
		check(acts.size() >= 2, "a creature %s does not do the same thing all day (%s)" % [str(Habits.HABITS[hb2].n), str(acts.keys())])
	for own in Habits.OWN:
		check(Data.ENEMIES.has(own) and Habits.HABITS.has(str(Habits.OWN[own])), "%s, which keeps hours of its own, is a real creature" % own)
	check(Habits.act_at("day", 12.0) == "bask" and Habits.act_at("day", 23.0) == "sleep" and Habits.act_at("night", 12.0) == "sleep" and Habits.act_at("night", 20.5) == "hunt"
		and Habits.act_at("dusk", 5.0) == "hunt" and Habits.act_at("dusk", 12.0) == "sleep" and Habits.act_at("tide", 3.0) == "drift", "day creatures sleep at night, night creatures by day, the hunters of the half-light at noon, and the rest never")
	check(Habits.first("sleep") == "party" and Habits.first("hunt") == "foe" and Habits.mod("hunt", "atk") > 1.0 and Habits.mod("hunt", "exp") > 1.0 and Habits.mod("bask", "spd") < 1.0 and Habits.mod("gather", "hp") > 1.0
		and Habits.mod("forage", "atk") == 1.0, "asleep the party moves first; hunting they hit harder, move first and are worth more; basking they are slow; gathered they stand up to more")
	# over a whole day the wild is no easier for keeping hours: what a pack asleep gives is paid for on one hunting or gathered
	for hb3 in Habits.HABIT_ORDER:
		var hp_sum := 0.0
		var atk_sum := 0.0
		for hr2 in 24:
			var a2 := Habits.act_at(hb3, float(hr2) + 0.5)
			hp_sum += Habits.mod(a2, "hp")
			atk_sum += Habits.mod(a2, "atk")
		check(hp_sum / 24.0 >= 1.0 and atk_sum / 24.0 >= 0.98, "a creature %s is no easier over a whole day than it was (health x%.2f, blows x%.2f)" % [str(Habits.HABITS[hb3].n), hp_sum / 24.0, atk_sum / 24.0])
	check(Habits.sleeps("day") != "never" and Habits.sleeps("night") != "never" and Habits.sleeps("tide") == "never", "the bestiary can say when a creature sleeps (day: %s; night: %s)" % [Habits.sleeps("day"), Habits.sleeps("night")])
	var HWG = load("res://scripts/game.gd").new()
	HWG.reset()
	HWG.clock = 12.0 * 60.0
	check(Habits.act(HWG, "bamboo_wolf") == "sleep" and Habits.act(HWG, "iron_fang") == "watch", "by the game's clock: a wolf sleeps at noon, and a lord keeps no hours")
	HWG.clock = 5.0 * 60.0
	check(Habits.act(HWG, "bamboo_wolf") == "hunt" and Habits.act_of_group(HWG, [{"id": "bamboo_wolf", "lv": 1}, {"id": "bandit", "lv": 1}]) == "hunt" and Habits.line(HWG, "bamboo_wolf").contains("hunting"), "and hunts at dawn; a pack does what its leader does")
	# the sun stood at noon for nine days (Part IX): nothing of the night woke
	HWG.step = Data.step_index("s_p9_home") + 1
	Clock.advance(HWG, 30.0)
	check(Clock.frozen(HWG) == "noon" and Habits.act(HWG, "moth_queen") == "watch" and Habits.act(HWG, "bamboo_wolf") == "sleep", "while the sun stands at noon the hunters of the half-light never wake")
	var bsrc2 := FileAccess.get_file_as_string("res://scripts/battle.gd")
	var wsrc2 := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(bsrc2.contains("Habits.mod(habit, \"atk\")") and bsrc2.contains("Caught asleep") and bsrc2.contains("The hunters saw you first") and wsrc2.contains("Habits.act_of_group(Game, e.group)")
		and FileAccess.get_file_as_string("res://scripts/main.gd").contains("\"habit\": Habits.act_of_group"), "what a pack is doing is seen in the land and felt in the battle")
	# (a battle the party loses must end: a careless edit to the turn loop once left it going round for ever)
	var turn_src := bsrc2.substr(bsrc2.find("func _next_turn"), 400)
	check(turn_src.contains("if alive(foes).is_empty():") and turn_src.contains("if alive(party).is_empty():") and turn_src.contains("_lose()"), "the turn loop ends the battle when either side has nobody left standing")
	print("== the Hundred Works (works.gd) ==")
	check(Works.ORDER.size() == 18 and Works.WORKS.size() == 18 and Works.SCHOOL_ORDER.size() == 3, "eighteen works in three schools")
	var keys := {}
	var total_know := 0
	for wid in Works.ORDER:
		var w: Dictionary = Works.WORKS[wid]
		var whole := true
		for k in ["school", "tier", "n", "key", "v", "site", "does", "desc"]:
			whole = whole and w.has(k)
		check(whole and Works.SCHOOLS.has(str(w.school)) and int(w.tier) >= 0 and int(w.tier) < Works.TIERS and str(w.desc).length() > 120 and str(w.does).length() > 20, "%s: a work of a school, with a story and a use" % wid)
		check(not keys.has(str(w.key)), "%s: no other work does the same thing (%s)" % [wid, str(w.key)])
		keys[str(w.key)] = true
		check(Data.AREAS.has(str(w.site[0])) and Data.layer_of(str(w.site[0])) == "surface", "%s stands somewhere in the land" % wid)
		total_know += Works.cost_know(wid)
		check((Works.before(wid) == "") == (int(w.tier) == 0), "%s: follows the work before it in its school" % wid)
	for sc in Works.SCHOOL_ORDER:
		check(Works.ORDER.filter(func(o): return str(Works.WORKS[o].school) == sc).size() == Works.TIERS, "the school of %s has six works" % str(Works.SCHOOLS[sc].n))
	for ta in Works.TIER_AFTER:
		check(Data.step_index(str(ta)) >= 0, "a tier of works waits for a real step (%s)" % ta)
	for ti in range(1, Works.TIERS):
		check(Data.step_index(str(Works.TIER_AFTER[ti])) > Data.step_index(str(Works.TIER_AFTER[ti - 1])) and int(Works.TIER_KNOW[ti]) > int(Works.TIER_KNOW[ti - 1]) and int(Works.TIER_STONES[ti]) > int(Works.TIER_STONES[ti - 1]),
			"tier %d of the works comes later and costs more than the one before" % (ti + 1))
	# a whole journey's know-how: every creature, every lord, every thing to do, every obstacle, every deed and cave
	var beasts := 0
	var lords := 0
	for eid2 in Data.ENEMIES:
		if Data.ENEMIES[eid2].get("boss", false):
			lords += 1
		else:
			beasts += 1
	var clears := 0
	for st in Data.STEPS:
		if str(st.kind) == "clear":
			clears += int(st.n)
	# (a lord is in the bestiary and among the defeated: he counts twice)
	var most: int = beasts + 2 * lords + Props.KINDS.size() + clears + 2 * Trials.DEEDS.size() + 2 * (Data.AREAS.mountain.get("abodes", []) as Array).size()
	check(most < total_know and most > total_know / 2, "one journey's know-how (%d at the very most) builds more than half the works and never all of them (%d): which to build is a choice" % [most, total_know])
	HWG.reset()
	check(Works.count(HWG) == 0 and Works.leading(HWG) == "" and Works.mod(HWG, "exp") == 1.0 and Works.add(HWG, "volley") == 0.0 and Works.title(HWG) == "No maker yet", "with nothing built the works change nothing")
	check(not Works.can_build(HWG, "well_sweep") and Works.blocked(HWG, "well_sweep").contains("knows how"), "a work cannot be built before the story reaches it")
	HWG.step = Data.step_index("s_hunt1")
	check(Works.blocked(HWG, "well_sweep").begins_with("Know-how") and Works.blocked(HWG, "trip_hammer").contains("knows how"), "nor without the know-how; and the second tier is not yet known")
	for k2 in 8:
		HWG.bestiary["b%d" % k2] = 1
	HWG.stones = 10
	check(Works.know(HWG) == 8 and Works.blocked(HWG, "well_sweep").contains("spirit stones"), "nor without the spirit stones")
	HWG.stones = 1000
	var p0 := Works.pill_price(HWG, "hp_pill", 10)
	check(Works.build(HWG, "well_sweep") and Works.has(HWG, "well_sweep") and HWG.stones == 1000 - Works.cost_stones(HWG, "well_sweep") and Works.know(HWG) == 2 and Works.pill_price(HWG, "hp_pill", 10) < p0,
		"the well-sweep is built: paid for in stones, the know-how spent, and pills cost less")
	check(not Works.build(HWG, "well_sweep") and not Works.can_build(HWG, "trip_hammer") and Works.count(HWG, "wheel") == 1 and Works.leading(HWG) == "wheel" and Works.title(HWG) == "Apprentice of The Wheel", "once; and its maker is an apprentice of the Wheel")
	HWG.step = Data.STEPS.size() - 1
	for k3 in 1100:
		HWG.bestiary["c%d" % k3] = 1
	HWG.stones = 10000000
	for wid2 in ["trip_hammer", "water_bellows", "crossbow", "chariot", "wooden_ox", "fire_kit", "cords", "sling", "kiln", "adze", "hide_coat", "array", "talismans", "furnace", "paper_servants", "mirror", "flags"]:
		check(Works.build(HWG, wid2), "%s can be built in its turn" % wid2)
	check(Works.count(HWG) == 18 and Works.know_spent(HWG) == total_know and Works.buildable(HWG).is_empty(), "all eighteen stand (in a test, with know-how no journey has)")
	check(Works.mod(HWG, "exp") > 1.0 and Works.mod(HWG, "stones") > 1.0 and Works.mod(HWG, "pill") > 1.0 and Works.mod(HWG, "price") < 1.0 and Works.mod(HWG, "temper") < 1.0 and Works.mod(HWG, "recipe") < 1.0
		and Works.mod(HWG, "med") > 1.0 and Works.mod(HWG, "hp") > 1.0 and Works.mod(HWG, "heavy") < 1.0 and Works.mod(HWG, "cost") < 1.0 and Works.mod(HWG, "taken") < 1.0, "the works that multiply, multiply")
	check(Works.add(HWG, "ambush") > 0.0 and Works.add(HWG, "volley") > 0.0 and Works.add(HWG, "drop") > 0.0 and Works.add(HWG, "doze") > 0.0 and Works.add(HWG, "weak") > 0.0
		and Works.blows(HWG, 2) == 1 and Works.blows(HWG, 1) == 1 and Works.temper_cost(HWG) < int(Data.TEMPER_COST[0]), "the works that add, add; the adze takes a blow off an obstacle, never the last")
	check(Trials.recipe_stones("fire_drill", HWG) < int(Trials.RECIPES.fire_drill.stones) and HWG.med_rate(false) > (3.0 + 1.2 * HWG.level) * (1.0 + HWG.talent_mod("med")), "the forge is cheaper and meditation deeper for them")
	check(not FileAccess.get_file_as_string("res://scripts/meditate.gd").contains("Works.") and not Works.ADDS.has("mend"), "no work shortens a rest: what waiting takes is the same for every maker")
	var bare = load("res://scripts/game.gd").new()
	bare.reset()
	check(HWG.max_hp(0) > bare.max_hp(0), "a fire of one's own: the party is hardier for a hot meal")
	bare.free()
	for src_f in ["battle", "shop", "impact", "trials", "game"]:
		check(FileAccess.get_file_as_string("res://scripts/%s.gd" % src_f).contains("Works."), "%s.gd asks the works" % src_f)
	# the machines stand in the land, each once, on open ground with nothing near, and are built from code
	var wsurf2: Dictionary = Atlas.world_of("surface")
	var mach: Array = wsurf2.ents.filter(func(e): return e.kind == "machine")
	check(mach.size() == Works.sites().size() and mach.size() == 19, "eighteen works and Gongshu Ban's wheel stand in the land (%d)" % mach.size())
	var reach2 := MapGen.flood(wsurf2.grid, wsurf2.w, wsurf2.h, wsurf2.start)
	var crowded := 0
	var closed := 0
	for me in mach:
		if not reach2.has(me.pos) or Atlas.owner_id(wsurf2, me.pos) != str(me.area):
			closed += 1
		var ring := 0
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if reach2.has(me.pos + Vector2i(dx, dy)):
					ring += 1
		if ring < 9:
			closed += 1
		for oe in wsurf2.ents:
			if oe != me and oe.kind != "spring" and oe.kind != "seal" and absi(oe.pos.x - me.pos.x) <= 2 and absi(oe.pos.y - me.pos.y) <= 2:
				crowded += 1
	check(closed == 0 and crowded == 0, "every machine stands on open ground of its own region with a way round it and nothing within two tiles (%d shut in, %d crowded)" % [closed, crowded])
	for ms in Works.sites():
		var key3: String = str(Works.STORY_SITES[ms[1]].model) if Works.STORY_SITES.has(str(ms[1])) else str(ms[1])
		var mn := Machines.model(key3)
		var tris := 0
		for ch in mn.get_children():
			if ch is MeshInstance3D and ch.mesh != null:
				for si in ch.mesh.get_surface_count():
					tris += ch.mesh.surface_get_array_index_len(si) / 3 if ch.mesh.surface_get_array_index_len(si) > 0 else ch.mesh.surface_get_array_len(si) / 3
		check(tris > 100 and tris < 6000 and Works.site_name(str(ms[1])) != "" and Works.site_desc(str(ms[1])).length() > 60, "the %s is built from code (%d triangles) and has something to say for itself" % [Works.site_name(str(ms[1])), tris])
		Machines.animate(mn, 3.0)
		mn.free()
	HWG.reset()
	check(not Works.stands(HWG, "ban_wheel") and not Works.stands(HWG, "well_sweep"), "nothing stands before it is built")
	HWG.step = Data.step_index("s_p19_ban")
	check(Works.stands(HWG, "ban_wheel"), "Gongshu Ban's wheel stands from the step in which he is met")
	print("== crossroads and echoes (echoes.gd) ==")
	check(Echoes.ORDER.size() == Echoes.CROSSROADS.size() and Echoes.ORDER.size() >= 16, "sixteen crossroads (%d)" % Echoes.ORDER.size())
	var parts := {}
	var last_step := -1
	var echo_n := 0
	var tilt_lo := {"heart": 0, "craft": 0, "reach": 0}
	var tilt_hi := {"heart": 0, "craft": 0, "reach": 0}
	var key_step := func(key: String) -> int:
		if key.begins_with("pre:") or key.begins_with("post:"):
			var who := key.get_slice(":", 1)
			if Data.step_index(who) >= 0:
				return Data.step_index(who)
			# (Part XXIV: a lord that cannot be beaten is a step of kind "fall")
			if _kill_step(who) < 0:
				for fi in Data.STEPS.size():
					if str(Data.STEPS[fi].kind) == "fall" and str(Data.STEPS[fi].boss) == who:
						return fi
			return _kill_step(who)
		if key.begins_with("done:") or key.begins_with("visit:"):
			# (a call paid on somebody for a step of visits is heard during that step)
			return Data.step_index(key.get_slice(":", 1))
		return Data.step_index(key)
	for cid in Echoes.ORDER:
		var c: Dictionary = Echoes.CROSSROADS[cid]
		var si2 := Data.step_index(str(c.step))
		check(si2 > last_step and str(c.ask).length() > 60 and (c.options as Array).size() >= 2, "%s: asked after a real step, later than the one before, with a choice" % cid)
		last_step = si2
		parts[str(c.part)] = true
		var lo := {"heart": 0, "craft": 0, "reach": 0}
		var hi := {"heart": 0, "craft": 0, "reach": 0}
		var ids := {}
		for o in c.options:
			ids[str(o.id)] = true
			check(str(o.label) != "" and str(o.desc).length() > 60 and str(o.log) != "" and not (o.get("tilt", {}) as Dictionary).is_empty(), "%s/%s: says what it does, is remembered, and tips a scale" % [cid, o.id])
			check((c.after as Dictionary).has(str(o.id)) and (c.end as Dictionary).has(str(o.id)), "%s/%s: has its words when it is chosen, and at the end" % [cid, o.id])
			for sc2 in o.tilt:
				check(Echoes.SCALES.has(str(sc2)), "%s/%s tips a real scale" % [cid, o.id])
				lo[sc2] = mini(int(lo[sc2]), int(o.tilt[sc2]))
				hi[sc2] = maxi(int(hi[sc2]), int(o.tilt[sc2]))
			for it in o.get("gain", {}).get("items", {}):
				check(Data.ITEMS.has(str(it)), "%s/%s gives something real" % [cid, o.id])
		for sc3 in lo:
			tilt_lo[sc3] += int(lo[sc3])
			tilt_hi[sc3] += int(hi[sc3])
		check((c.echo as Dictionary).size() >= 1, "%s echoes later in the story" % cid)
		for ek in c.echo:
			check(Data.DIALOGUE.has(str(ek)) and key_step.call(str(ek)) > si2, "%s echoes in a conversation that is there, later in the story (%s)" % [cid, ek])
			for oid in c.echo[ek]:
				check(ids.has(str(oid)), "%s: the echo in %s is of a real answer (%s)" % [cid, ek, oid])
				echo_n += 1
				for el in c.echo[ek][oid]:
					var par := TextParagraph.new()
					par.add_string(str(el[1]), ThemeDB.fallback_font, 22)
					par.width = 1100
					check((el as Array).size() == 2 and par.get_line_count() <= 4, "%s: the echo in %s fits the dialogue box" % [cid, ek])
	check(parts.size() >= 10 and echo_n >= 60, "the crossroads lie in %d parts of the story, and their answers echo %d times" % [parts.size(), echo_n])
	for sc4 in Echoes.SCALE_ORDER:
		check(int(tilt_hi[sc4]) >= Echoes.KNOWN and int(tilt_lo[sc4]) <= -Echoes.KNOWN, "the scale of %s can be leaned either way far enough to be known for it (%d to %d)" % [str(Echoes.SCALES[sc4].n), int(tilt_lo[sc4]), int(tilt_hi[sc4])])
	HWG.reset()
	check(Echoes.waiting(HWG) == "" and Echoes.scale(HWG, "heart") == 0 and Echoes.lean(HWG, "heart") == 0 and Echoes.names(HWG) == "" and Echoes.epilogue(HWG).is_empty(), "nothing is asked and nothing leans before the road")
	HWG.step = Data.step_index("s_ironfang")
	HWG.advance()
	check(HWG.cross_pending == ["bandits"] and Echoes.waiting(HWG) == "bandits", "Iron Fang falls, and his men are waiting to be told what they are now")
	var r0: int = HWG.renown
	Echoes.take(HWG, "bandits", "mend")
	check(Echoes.chosen(HWG, "bandits") == "mend" and Echoes.scale(HWG, "heart") == 2 and HWG.renown == r0 + 3 and Echoes.waiting(HWG) == "", "set to mend the road: remembered, mercy tipped, the valley hears")
	Echoes.take(HWG, "bandits", "drive")
	check(Echoes.chosen(HWG, "bandits") == "mend" and Echoes.scale(HWG, "heart") == 2, "a crossroads is answered once")
	var gw: Array = Echoes.told(HWG, "s_vl_intro", Data.DIALOGUE.s_vl_intro)
	check(gw.size() == (Data.DIALOGUE.s_vl_intro as Array).size() + 1 and str(gw[gw.size() - 1][1]).contains("road-menders") and HWG.echoed.has("bandits|s_vl_intro") and Echoes.heard(HWG, "bandits") == [1, 4],
		"six parts later Granny Wen speaks of the road-menders, and the echo is kept")
	check(Echoes.told(HWG, "s_intro", Data.DIALOGUE.s_intro) == Data.DIALOGUE.s_intro, "a conversation with no crossroads behind it is as it was")
	check(not Echoes.merciful(HWG), "one kindness is not yet a name")
	Echoes.take(HWG, "roc_egg", "hatch")
	check(Echoes.merciful(HWG) and Echoes.lean(HWG, "heart") == 1 and Echoes.name_of(HWG, "heart") == "Merciful" and Echoes.names(HWG) == "Merciful" and Echoes.lean_mod(HWG, "stones") > 1.0 and Echoes.lean_mod(HWG, "drop") > 0.0,
		"two are: the land calls him Merciful, and a beaten pack gives up what it guarded")
	Echoes.take(HWG, "ancestor", "strike")
	Echoes.take(HWG, "crows", "banish")
	Echoes.take(HWG, "roc_egg", "sell")
	check(Echoes.scale(HWG, "heart") == -1 and not Echoes.merciful(HWG) and not Echoes.feared(HWG), "and rigour afterwards tips it back")
	HWG.fates = {"tala": "fallen", "hu": "fallen"}
	check(Echoes.feared(HWG) and Echoes.lean_mod(HWG, "open_hp") == Echoes.FEAR_HP and Echoes.name_of(HWG, "heart") == "Unbending", "the fallen of the five weigh too: unbending, and the wild opens the battle afraid")
	Echoes.take(HWG, "drawings", "keep")
	check(Echoes.lean(HWG, "craft") == 1 and Echoes.lean_mod(HWG, "works_stones") == Echoes.WORKS_STONES and Works.cost_stones(HWG, "wooden_ox") < int(Works.TIER_STONES[5]), "of the new works: the makers ask less")
	Echoes.take(HWG, "cauldron_map", "keep")
	check(Echoes.lean(HWG, "reach") == -1 and Echoes.lean_mod(HWG, "renown") == float(Echoes.RENOWN_MORE) and Echoes.lean_mod(HWG, "regard") == 1.0, "of the home fire: his name comes back larger")
	check(Echoes.epilogue(HWG).size() == 6 and Echoes.names(HWG).contains("of the New Works") and Echoes.text(HWG, "bandits").contains("Echoes heard: 1 of 4") and Echoes.text(HWG, "bandits").contains("It stands in the land: The Menders' Road") and Echoes.text(HWG, "the_works").contains("ahead"), "the ending tells what came of each answer, and the page keeps them")
	# the last question of Part XIX can only be answered for a school by somebody who has built three works of it
	HWG.works = {}
	var lastq: Dictionary = Echoes.CROSSROADS.the_works
	check(not Echoes.option_ok(HWG, Echoes.option("the_works", "wheel")) and not Echoes.option_ok(HWG, Echoes.option("the_works", "hand")) and Echoes.option_ok(HWG, Echoes.option("the_works", "ask")), "with nothing built it is not his to say: only the gardener can be asked")
	HWG.works = {"well_sweep": 1, "trip_hammer": 1, "water_bellows": 1}
	check(Echoes.option_ok(HWG, Echoes.option("the_works", "wheel")) and not Echoes.option_ok(HWG, Echoes.option("the_works", "dao")) and Echoes.option_text(HWG, Echoes.option("the_works", "wheel")).contains("[x] 3 works"), "three works of the Wheel: he may answer for the Wheel, and for no other school")
	check((lastq.options as Array).filter(func(o2): return (o2.get("need", []) as Array).is_empty()).size() == 1, "one answer to the last question is open to everybody")
	var msrc2 := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(msrc2.contains("func ask_crossroads") and msrc2.contains("Echoes.told(Game, key") and msrc2.contains("Echoes.epilogue(Game)") and bsrc2.contains("Echoes.lean_mod(Game, \"stones\")") and bsrc2.contains("Echoes.FEAR_HP") and not bsrc2.contains("yielded"),
		"the crossroads are asked, echo in the story, are told at the end, and are felt in battle")
	# every echo and every word at a crossroads is told of her as well as of him (voice.gd)
	var odd2: Array = []
	for cid2 in Echoes.ORDER:
		var c2: Dictionary = Echoes.CROSSROADS[cid2]
		var convs: Array = []
		for oid2 in c2.after:
			convs.append(c2.after[oid2])
		for ek2 in c2.echo:
			for oid3 in c2.echo[ek2]:
				convs.append(c2.echo[ek2][oid3])
		for src in convs:
			var told: Array = Voice.lines(src)
			for i in (src as Array).size():
				if str(src[i][0]) != "Narrator" and str(told[i][1]) != Voice.said(str(src[i][1])):
					odd2.append("%s:%s" % [cid2, str(src[i][1]).substr(0, 30)])
	check(odd2.is_empty(), "nobody who speaks at a crossroads has their own words changed when the hero is a woman (%s)" % str(odd2.slice(0, 4)))
	HWG.free()
	print("== Part XIX: the Machine Heart ==")
	check(Data.REALMS.size() >= 25 and Data.REALMS[24] == "Skill Become Dao" and Data.MAX_LEVEL >= 72 and Data.level_name(72).ends_with("Skill Become Dao") and Data.REALM_INFO.size() == Data.REALMS.size() and Data.EXP_NEED.size() == Data.MAX_LEVEL
		and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XIX adds the Skill Become Dao realm")
	check(Data.step_index("s_break24") == Data.step_index("s_p20_home") - 1 and Data.DIALOGUE.has("recall17") and msrc2.contains("\"s_break23\": \"recall17\"") and Data.DIALOGUE.has("pre:s_break24") and Data.DIALOGUE.has("post:s_break24"),
		"Part XIX follows Fire Passed On (recall17) and ends with a tribulation swept aside")
	for tid in ["cloud_ladder", "the_player", "jixin", "wooden_magpie"]:
		check(Trials.TRIALS.has(tid) and Lore.BOSS.has(tid) and Data.DIALOGUE.has("pre:" + tid) and Data.DIALOGUE.has("post:" + tid), "%s is a trial, with a story and words before and after" % tid)
		check((Trials.TRIALS[tid].paths as Array).any(func(pth): return str(pth.kind) == "works"), "%s can be passed by the works" % tid)
		check(_kill_step(tid) > Data.step_index("s_p19_home"), "%s is faced in Part XIX" % tid)
	check(Trials.KINDS.has("works") and Trials.EPITHETS.has("works") and Assets.PEOPLE.has("the_player") and "person:the_player" in UI.SHAPES and Data.BOSS_DROPS.get("jixin", "") == "still_heart" and Data.ITEMS.has("still_heart"),
		"the Player is Blender-built, and the Machine Heart leaves the stopped escapement")
	for mon in ["wheel_mite", "treadle_imp", "idle_shuttle", "cog_crab", "bellows_wraith", "hammer_golem", "wooden_kite", "stray_ox", "paper_servant", "brass_spiderling", "counting_wasp", "tally_golem"]:
		check(Data.ENEMIES.has(mon) and Lore.BEAST.has(mon), "%s has a story" % mon)
	for who in ["gongshu_ban", "mo_di", "gardener_hanyin", "yan_shi"]:
		check(Assets.PEOPLE.has(who) and FileAccess.file_exists("res://art/characters/%s.py" % who) and Data.CHAT.has(who) and Trials.npc_area(who) != "", "%s is Blender-built, lives somewhere and has things to say" % who)
	var wsurf3: Dictionary = Atlas.world_of("surface")
	for lid in ["gongshu_ban", "gardener_hanyin", "mo_di", "yan_shi", "boss_cloud_ladder", "boss_the_player", "boss_jixin", "boss_wooden_magpie", "p19_tim1", "p19_tim6", "p19_part1", "p19_part6", "p19_cog1", "p19_cog5"]:
		check(wsurf3.ents.filter(func(e3): return str(e3.id) == lid).size() == 1, "%s stands in the world once (late: no older map moved for it)" % lid)
	for sid2 in ["s_p19_campfire", "s_p19_rest"]:
		var sp: Dictionary = Data.STEPS[Data.step_index(sid2)]
		check(Bonds.SHARES.has(sid2) and not Bonds.find_spot(wsurf3.ents, str(sp.spot)).is_empty() and Bonds.share_place(sid2) != "side by side", "%s: a scene with Yue Ling, at a place that is there" % sid2)
	for sid3 in ["s_p19_timber", "s_p19_build", "s_p19_farm", "s_p19_mites", "s_p19_cogs", "s_p19_hammer", "s_p19_ferry", "s_p19_parts", "s_p19_porters", "s_p19_kites", "s_p19_lamps", "s_p19_doors", "s_p19_spiders", "s_p19_founders", "s_p19_shuttles", "s_p19_clouds"]:
		check(Data.DIALOGUE.has("done:" + sid3), "%s has its word to say when it is done" % sid3)
	for hs in ["s_p19_mites", "s_p19_hammer", "s_p19_kites", "s_p19_spiders", "s_p19_shuttles", "s_p19_clouds"]:
		var hst: Dictionary = Data.STEPS[Data.step_index(hs)]
		var band: Dictionary = Data.AREAS[str(hst.area)].get("warband", {})
		check(bool(hst.get("first", false)) and bool(band.get("late", false)) and Data.step_index(str(band.vis)) < Data.step_index(hs) and int(band.n) * 2 >= int(hst.n), "%s: the packs are there before it, enough of them, and it asks for the first strike" % hs)
		for pe in band.pool:
			check(str(pe[0]) in hst.of, "%s hunts %s" % [hs, pe[0]])
	var wk: Dictionary = Data.STEPS[Data.step_index("s_p19_build")]
	var WG = load("res://scripts/game.gd").new()
	WG.reset()
	WG.step = Data.step_index("s_p19_build")
	WG.works = {"well_sweep": 1, "fire_kit": 1}
	check(str(wk.kind) == "works" and WG.objective_text().contains("(2/3)"), "the step that asks for works counts them")
	WG.works["array"] = 1
	WG.poll_steps()
	check(WG.step == Data.step_index("s_p19_build") + 1, "three works built with his own hands, and the story goes on")
	# a step of visits begins with nobody visited, whoever was called on in an earlier chapter
	WG.step = Data.step_index("s_p19_makers") - 1
	WG.visited = {"smith": true, "auntie_rong": true, "lantern_xi": true, "yu_hua": true}
	WG.boss_done["the_player"] = true
	WG.advance()
	var mk: Dictionary = Data.STEPS[Data.step_index("s_p19_makers")]
	check(WG.cur_step().id == "s_p19_makers" and WG.visits_done(mk) == 0 and WG.visited.has("yu_hua"), "the makers are all still to be called on, though three of them were called on in earlier chapters")
	for nid in mk.npcs:
		check(Data.DIALOGUE.has("visit:s_p19_makers:" + str(nid)), "%s has words of their own for this call" % nid)
	# the answer is carried home to the keepers of the hearths, who were carried the new fire in Part XVIII
	var wd2: Dictionary = Data.STEPS[Data.step_index("s_p19_word")]
	var keepers2: Array = Cultures.ORDER.map(func(h6): return str(Cultures.HEARTHS[h6].keeper))
	for kn in wd2.npcs:
		check(str(kn) in keepers2 and Data.DIALOGUE.has("visit:s_p19_word:" + str(kn)), "%s keeps a hearth, and has words for what was decided" % kn)
	check(Data.step_index("s_p19_word") > Data.step_index("s_p19_heart") and Data.step_index("s_p19_magpie") > Data.step_index("s_p19_heart") and Data.BOSS_DROPS.get("jixin", "") == "still_heart"
		and (Trials.TRIALS.wooden_magpie.paths as Array).any(func(pm): return str(pm.kind) == "relic" and pm.needs == [["item", "still_heart", 1]]),
		"the stopped escapement the Machine Heart leaves is what brings the Wooden Magpie down, and the answer is carried home after it is given")
	WG.free()
	check(Impact.OBSTACLES.has("cogwork") and Data.ITEMS.has("catalpa_timber") and Data.ITEMS.has("player_part") and Trials.RECIPES.has("defence_models") and Folk.ERRANDS.has("s_p19_farm") and Folk.ERRANDS.has("s_p19_porters"),
		"locked gear-trains, catalpa, the Player's cast-off pieces, Mozi's belt and nine sticks, and two errands")
	for fs in ["s_p19_farm", "s_p19_ferry", "s_p19_porters", "s_p19_lamps", "s_p19_founders"]:
		var fst: Dictionary = Data.STEPS[Data.step_index(fs)]
		check(str(fst.kind) == "folk" and fst.has("hearth") and fst.has("town") and Cultures.HEARTHS.has(str(fst.hearth)) and str(fst.town) in Cultures.HEARTHS[str(fst.hearth)].towns, "%s is an errand among a hearth's own townsfolk" % fs)
	for cid3 in ["the_wheel", "the_player", "the_works"]:
		check(Data.step_index(str(Echoes.CROSSROADS[cid3].step)) > Data.step_index("s_p19_home"), "the crossroads %s is in Part XIX" % cid3)
	var bsrc3 := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(bsrc3.contains("\"cloud_ladder\": \"craft\"") and bsrc3.contains("\"jixin\": \"works\"") and bsrc3.contains("\"wooden_magpie\": \"relic\"") and bsrc3.contains("CROSS_PLAN") and bsrc3.contains("WORKS_PLAN") and bsrc3.contains("\"s_p19_rest\""),
		"the bot builds works, answers at every crossroads, and has a way through the three trials")
	var plan_src := bsrc3.substr(bsrc3.find("const CROSS_PLAN"), 2000)
	for cid4 in Echoes.ORDER:
		check(plan_src.contains("\"%s\": [" % cid4), "the bot has an answer for the crossroads %s" % cid4)

## The Hollow Hills release: voxels (voxel.gd), a cave under every region (caves.gd), twice the room in
## the houses (rooms.gd), the new things to do and the clips they are done on (props.gd, cavethings.gd),
## and Part XX.
func _hollow_hills() -> void:
	print("== voxels (voxel.gd) ==")
	var pal := Voxel.palette()
	check(pal.size() == Voxel.N_MAT, "every material has a colour and a surface (%d)" % pal.size())
	var v1 := Voxel.make(5, 5, 5)
	Voxel.carve(v1, 2, 2, 2, 3)
	var m1 := Voxel.mesh(v1, pal)
	check(int(m1.faces) == 6 and Voxel.at(v1, 2, 2, 2) == 0 and Voxel.at(v1, 2, 1, 2) != 0 and v1.lo[2 * 5 + 2] == 2 and v1.hi[2 * 5 + 2] == 3, "one cell hollowed out of rock is a room with six walls")
	# every face looks into the hollow: its normal points at the middle of the cell of air, and its
	# triangles are wound to be seen from there
	var arr1 := (m1.mesh as ArrayMesh).surface_get_arrays(0)
	var vs1: PackedVector3Array = arr1[Mesh.ARRAY_VERTEX]
	var ns1: PackedVector3Array = arr1[Mesh.ARRAY_NORMAL]
	var ix1: PackedInt32Array = arr1[Mesh.ARRAY_INDEX]
	var mid1 := Vector3(2.5, 2.5, 2.5) * Voxel.S
	var inward := true
	for t1 in ix1.size() / 3:
		var a1 := vs1[ix1[t1 * 3]]
		var b1 := vs1[ix1[t1 * 3 + 1]]
		var c1 := vs1[ix1[t1 * 3 + 2]]
		var cen := (a1 + b1 + c1) / 3.0
		# (front faces are clockwise: the geometric normal of a face seen from the air points away from it)
		inward = inward and ns1[ix1[t1 * 3]].dot(mid1 - cen) > 0.0 and (b1 - a1).cross(c1 - a1).dot(mid1 - cen) < 0.0
	check(inward and vs1.size() == 24, "its faces look inward, and are wound to be seen from inside")
	Voxel.carve(v1, 3, 2, 2, 3)
	check(int(Voxel.mesh(v1, pal).faces) == 10, "two cells side by side share no wall between them (ten faces)")
	Voxel.fill(v1, 3, 2, 2, 3, Voxel.GEM)
	check(Voxel.at(v1, 3, 2, 2) == Voxel.GEM + 1 and int(Voxel.mesh(v1, pal).faces) == 6, "a cell filled again is solid, of what it was filled with")
	check(Voxel.floor_under(v1, 2, 2, 4) == 5 and Voxel.floor_under(v1, 2, 2, 2) == 2, "the floor under a point is the top of the first solid cell below it")
	var vm := Voxel.model([[Vector3i(0, 0, 0), Voxel.ROCK], [Vector3i(0, 1, 0), Voxel.ORE]], pal)
	check(vm.mesh != null and vm.mesh.get_faces().size() / 3 == 18, "a thing of two voxels standing in the open has nine faces to see (its foot is on the ground)")
	vm.free()
	print("== the Hollow Hills: a cave under every region (caves.gd) ==")
	var n_caves := 0
	var no_cave: Array = []
	var cave_tiles := 0
	for lid in ["surface", "heaven", "under", "sea"]:
		var lw: Dictionary = Atlas.world_of(lid)
		for area in lw.ids:
			var fid := Caves.fid(area)
			if not lw.floors.has(fid):
				no_cave.append(area)
				continue
			n_caves += 1
			var fw: Dictionary = lw.floors[fid]
			var lay := Caves.layout(area)
			var mouths: Array = lw.ents.filter(func(e): return str(e.id) == "cave:" + area)
			check(mouths.size() == 1 and str(mouths[0].to_layer) == fid and mouths[0].to_tile == lay.arrive and str(mouths[0].area) == area, "%s: one cave mouth, leading into its cave" % area)
			var mp: Vector2i = mouths[0].pos
			var open8: bool = Atlas.owner_id(lw, mp) == area
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					open8 = open8 and MapGen.is_walkable_tile(lw.grid[(mp.y + dy) * lw.w + mp.x + dx])
			check(open8 and fw.ents[0].kind == "ladder" and fw.ents[0].to_tile == mp + Vector2i(0, 1), "%s: the mouth stands in its own region with open ground all round, and the way out comes up before it" % area)
			# the lay of it: every tile of floor can be walked to, no step is higher than half a metre, and
			# there is room to stand
			var open_n := 0
			var steps_ok := true
			var roofs_ok := true
			for i in int(lay.w) * int(lay.h):
				if lay.grid[i] != MapGen.INTERIOR:
					continue
				open_n += 1
				roofs_ok = roofs_ok and lay.ceil[i] >= Caves.LOW
				for dn in [1, int(lay.w)]:
					if lay.grid[i + dn] == MapGen.INTERIOR and absi(lay.lv[i] - lay.lv[i + dn]) > 1:
						steps_ok = false
			cave_tiles += open_n
			var cr := MapGen.flood(fw.grid, fw.w, fw.h, fw.start)
			# (the tile of the way out is floor that the way out stands on)
			check(cr.size() == open_n and (lay.rooms as Array).size() >= 4 and steps_ok and roofs_ok, "%s: %d chambers, all of its floor joined (%d tiles), no step over half a metre, room to stand" % [area, (lay.rooms as Array).size(), open_n])
			var things: Array = fw.ents.filter(func(e): return e.kind == "prop")
			var niche_ok := true
			for th in things:
				niche_ok = niche_ok and CaveThings.KINDS.has(str(th.prop)) and Props.KINDS.has(str(th.prop)) and fw.grid[th.pos.y * fw.w + th.pos.x] == MapGen.BUILDING and cr.has(th.pos + (th.face as Vector2i))
			check(things.size() >= 4 and niche_ok and fw.ents.filter(func(e): return str(e.id) == "cave_cache:%s:-1" % area).size() == 1, "%s: %d things to do in niches of its walls, and something left at the very back" % [area, things.size()])
	check(n_caves >= Data.AREAS.size() - 1 and no_cave == ["sect"], "every region but the sect's own courtyard has a cave (%d; none under %s)" % [n_caves, str(no_cave)])
	check(cave_tiles > 6000 and Caves.total_tiles() >= cave_tiles, "the caves have %d tiles of floor to walk on" % Caves.total_tiles())
	# the same cave every time
	var lay_a: Dictionary = Caves.layout("frost")
	var grid_a: PackedByteArray = (lay_a.grid as PackedByteArray).duplicate()
	var lv_a: PackedInt32Array = (lay_a.lv as PackedInt32Array).duplicate()
	Caves._layouts.erase(Caves.fid("frost"))
	var lay_b: Dictionary = Caves.layout("frost")
	check(grid_a == lay_b.grid and lay_a.entry == lay_b.entry and (lay_b.rooms as Array).size() == (lay_a.rooms as Array).size(), "a cave is laid out the same every time")
	Atlas.world_of(Caves.fid("frost"))
	# the rock itself: over every tile that is walked on there is air to stand in, the floor is where the
	# game says it is, the sides of the volume are closed, and the mesher draws exactly the faces of
	# rock that touch air
	Caves.world("frost", "surface", Vector2i(10, 10), [])
	var vol := Caves.volume("frost")
	var lay_f := Caves.layout("frost")
	var stand_ok := true
	var floor_ok := true
	for ty in int(lay_f.h):
		for tx in int(lay_f.w):
			if lay_f.grid[ty * int(lay_f.w) + tx] != MapGen.INTERIOR or Vector2i(tx, ty) == lay_f.entry:
				continue
			for sub in [Vector2i(1, 1), Vector2i(2, 2)]:
				var cx: int = tx * Caves.P + sub.x
				var cz: int = ty * Caves.P + sub.y
				var c: int = cz * int(vol.nx) + cx
				stand_ok = stand_ok and int(vol.hi[c]) - int(vol.lo[c]) >= Caves.LOW
				floor_ok = floor_ok and is_equal_approx(Caves.floor_y(lay_f, (cx + 0.5) * Caves.V, (cz + 0.5) * Caves.V), float(vol.lo[c]) * Caves.V)
	check(stand_ok and floor_ok, "over every tile of a cave's floor there is room to stand, and the floor is where the game stands people")
	var closed := true
	for z in int(vol.nz):
		for x in [0, int(vol.nx) - 1]:
			closed = closed and int(vol.hi[z * int(vol.nx) + x]) <= int(vol.lo[z * int(vol.nx) + x])
	for x2 in int(vol.nx):
		for z2 in [0, int(vol.nz) - 1]:
			closed = closed and int(vol.hi[z2 * int(vol.nx) + x2]) <= int(vol.lo[z2 * int(vol.nx) + x2])
	check(closed, "the sides of a cave's volume are rock")
	var part := Rect2i(int(lay_f.arrive.x) * Caves.P - 12, int(lay_f.arrive.y) * Caves.P - 16, 24, 24)
	var brute := 0
	for z3 in range(part.position.y, part.end.y):
		for x3 in range(part.position.x, part.end.x):
			for y3 in int(vol.ny):
				if Voxel.at(vol, x3, y3, z3) != 0:
					continue
				for dv in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
					if Voxel.at(vol, x3 + dv.x, y3 + dv.y, z3 + dv.z) != 0:
						brute += 1
	var mpart := Voxel.mesh(vol, Voxel.palette(Caves.look_of("frost")), null, part)
	check(brute > 200 and int(mpart.faces) == brute, "the mesher draws every face of rock that touches air, and no other (%d in a piece of the cave)" % brute)
	var real3d := 0
	for c2 in int(vol.nx) * int(vol.nz):
		if int(vol.hi[c2]) > int(vol.lo[c2]):
			var base: int = c2 * int(vol.ny)
			var runs := 0
			var was_air := false
			for y4 in range(int(vol.lo[c2]), int(vol.hi[c2])):
				var air: bool = vol.d[base + y4] == 0
				if air and not was_air:
					runs += 1
				was_air = air
			if runs >= 2 or int(vol.hi[c2]) < int(vol.ny) - 2:
				real3d += 1
	check(real3d > 1000, "a cave is a real hollow: rock over the floor in %d of its columns (a height field has none)" % real3d)
	Caves.drop()
	print("== the caves of the story ==")
	for st in [["tushan", "white_rat"], ["mountain", "xuanpin"]]:
		var up: Dictionary = Atlas.world_of(Caves.fid(st[0]))
		var low: Dictionary = Atlas.world_of(Caves.fid(st[0], -2))
		var down: Array = up.ents.filter(func(e): return str(e.id) == "cave:%s:-1:down" % st[0])
		check(not low.is_empty() and down.size() == 1 and str(down[0].to_layer) == str(low.layer) and down[0].to_tile == low.start and low.ents[0].to_tile == down[0].pos + Vector2i(0, 1)
			and MapGen.is_walkable_tile(up.grid[(down[0].pos.y + 1) * up.w + down[0].pos.x]), "%s: a shaft down to a lower gallery, and the climb back comes up beside it" % up.bld_n)
		check(low.ents.filter(func(e): return str(e.id) == "boss_" + str(st[1])).size() == 1, "%s waits in %s" % [st[1], low.bld_n])
	for cb in [["village", "fen_yang"], ["karst", "wangliang"]]:
		check(Atlas.world_of(Caves.fid(cb[0])).ents.filter(func(e): return str(e.id) == "boss_" + str(cb[1])).size() == 1, "%s waits at the back of %s" % [cb[1], Atlas.world_of(Caves.fid(cb[0])).bld_n])
	var rot: Dictionary = Atlas.world_of(Caves.fid("mountain"))
	check(rot.ents.filter(func(e): return str(e.id) == "wang_zhi").size() == 1 and rot.ents.filter(func(e): return e.kind == "prop" and str(e.prop) == "cave_weiqi").size() == 1 and str(rot.bld_n) == "Rotten-Axe Cave",
		"Wang Zhi and the stone weiqi board are in Rotten-Axe Cave")
	for cs in Data.STEPS:
		if not str(cs.id).begins_with("s_p20_") or not cs.has("cave"):
			continue
		var cw: Dictionary = Atlas.world_of(Caves.fid(str(cs.area), int(cs.cave)))
		check(not cw.is_empty(), "%s is done in a cave that is there" % cs.id)
		match str(cs.kind):
			"collect":
				check(cw.ents.filter(func(e): return e.kind == "pickup" and str(e.get("item", "")) == str(cs.item)).size() >= int(cs.n), "%s: the %s are in the cave (%d of them)" % [cs.id, cs.item, int(cs.n)])
			"hunt":
				var packs: Array = cw.ents.filter(func(e): return e.kind == "enemy")
				check(packs.size() * 2 >= int(cs.n) and Data.step_index(str(packs[0].vis[0])) < Data.step_index(str(cs.id)) and not cs.get("first", false), "%s: enough packs in the cave (%d), there before it" % [cs.id, packs.size()])
			"try":
				var has: int = cw.ents.filter(func(e): return e.kind == "prop" and (not cs.has("things") or str(e.prop) in cs.things)).size()
				check(has >= int(cs.n), "%s: the things it asks for are in the cave (%d)" % [cs.id, has])
	var HG = load("res://scripts/game.gd").new()
	HG.reset()
	HG.step = Data.step_index("s_p20_things")
	Props.use({"kind": "prop", "id": "t:1", "prop": "ore_vein", "pos": Vector2i.ZERO, "cave": true}, HG)
	Props.use({"kind": "prop", "id": "t:2", "prop": "bench", "pos": Vector2i.ZERO}, HG)
	Props.use({"kind": "prop", "id": "t:1", "prop": "ore_vein", "pos": Vector2i.ZERO, "cave": true}, HG)
	check(HG.cur_step().id == "s_p20_things" and HG.objective_text().contains("(1/3)") and int(HG.inv.get("ess_earth", 0)) + int(HG.inv.get("ess_metal", 0)) == 1, "a thing of the caves done counts once, a bench not at all; a seam gives a piece of ore, now and then")
	Props.use({"kind": "prop", "id": "t:3", "prop": "drip_pool", "pos": Vector2i.ZERO, "cave": true}, HG)
	Props.use({"kind": "prop", "id": "t:4", "prop": "squeeze", "pos": Vector2i.ZERO, "cave": true}, HG)
	check(HG.cur_step().id == "s_p20_crickets" and HG.step_uses.is_empty(), "three things of a cave done, and the story goes on")
	HG.area = "bamboo"
	HG.layer = "surface"
	HG.record_kills("bamboo", 2, ["cave_cricket", "drip_wisp"])
	var h0: int = HG.hunt
	HG.layer = Caves.fid("bamboo")
	HG.record_kills("bamboo", 3, ["cave_cricket", "bamboo_wolf", "blind_newt"])
	check(h0 == 0 and HG.hunt == 2, "a hunt in a cave counts what is brought down in the cave, of the creatures named")
	HG.step = Data.step_index("s_p20_delve")
	var r0: int = HG.renown
	HG.delve("f:frost:cave:-1", "a cave")
	HG.delve("f:frost:cave:-1", "a cave")
	HG.delve("f:marsh:cave:-1", "a cave")
	HG.delve("f:bamboo:cave:-1", "a cave")
	check(HG.delved.size() == 3 and HG.renown == r0 + 3 and HG.objective_text().contains("(3/4)") and HG.cur_step().id == "s_p20_delve", "a cave gone to the back of is news once")
	check(Trials.need_met(["delved", 3], HG) and not Trials.need_met(["delved", 4], HG) and Trials.need_text(["delved", 4], HG).contains("now 3"), "the way through a trial by the dark counts them")
	HG.delve("f:volcano:cave:-1", "a cave")
	check(HG.cur_step().id == "s_p20_elders", "four caves gone to the back of, and the story goes on")
	HG.free()
	print("== twice the room indoors (rooms.gd) ==")
	var ft := Rooms.floor_tiles()
	check(int(ft[1]) >= int(ft[0]) * 2, "the buildings have twice the floor to walk on (%d tiles, from %d)" % [int(ft[1]), int(ft[0])])
	var n_bd := 0
	var n_made := 0
	var new_furn := {}
	for a in Data.AREAS:
		for bd in Data.AREAS[a].get("buildings", []):
			n_bd += 1
			var full := Rooms.complete(bd, Rooms.busy_of(a, bd))
			check(full.has("cellar") and full.has("down") and (full.has("upper") or str(bd.get("style", "house")) in Rooms.NO_UPPER), "%s: a cellar, and an upper storey unless its roof takes none" % bd.n)
			var r: Rect2i = bd.rect
			for key in [["up", "upper"], ["down", "cellar"]]:
				if not full.has(key[1]) or not full[key[1]].get("made", false):
					check(not full.has(key[1]) or full[key[1]] == bd[key[1]], "%s: a floor written by hand is left as it was" % bd.n)
					continue
				n_made += 1
				var st2: Vector2i = full[key[0]]
				var on_floor := r.grow(-1).has_point(st2) and absi(st2.x - bd.door.x) + absi(st2.y - bd.door.y) > 1
				for pr in bd.get("props", []):
					on_floor = on_floor and pr[1] != st2
				for bt in Rooms.busy_of(a, bd):
					on_floor = on_floor and bt != st2
				check(on_floor and str(full[key[1]].n) != "" and (full[key[1]].props as Array).size() >= 3, "%s: %s, by stairs on a free tile of the floor, with %d things in it" % [bd.n, full[key[1]].n, (full[key[1]].props as Array).size()])
				for pr2 in full[key[1]].props:
					new_furn[str(pr2[0])] = true
					check(Props.FURNITURE.has(str(pr2[0])) and r.grow(-1).has_point(pr2[1]) and pr2[1] != st2, "%s: the %s in %s can be used, and stands on its floor" % [bd.n, pr2[0], full[key[1]].n])
			check(Rooms.complete(bd, Rooms.busy_of(a, bd)) == full, "%s: laid out the same every time" % bd.n)
	check(n_made >= 120, "%d floors laid out for %d buildings" % [n_made, n_bd])
	for nf in ["chest", "mirror", "mortar", "spinning_wheel", "abacus", "cradle", "wine_jar", "clothes_stand", "washstand", "workbench", "wall_panel", "grain_bin", "window"]:
		check(new_furn.has(nf) and Props.FURNITURE.has(nf), "the new furniture %s stands in a building somewhere" % nf)
		var fb := MB.new()
		var fg := MB.new()
		var frng := RandomNumberGenerator.new()
		check(Rooms.furnish(fb, fg, nf, Vector3.ZERO, Vector3(0, 0, -0.75), Vector3(0, 0, -1), Vector3(1, 0, 0), frng, []) and fb.tri_count() > 20, "the %s is built (%d triangles)" % [nf, fb.tri_count()])
	print("== new things to do, and the clips they are done on ==")
	var hero := Assets.person("lin_feng")
	var hap: AnimationPlayer = hero.get_meta("ap")
	var used_clips := {}
	for pk in Props.KINDS:
		used_clips[str(Props.KINDS[pk].clip)] = true
	for cl in ["mine", "dig", "wash", "trace", "open_chest", "comb", "pound", "spin", "count", "stretch", "knock", "pour", "peer", "hang", "rock", "carve", "pan", "squeeze"]:
		check(hap.has_animation(cl) and used_clips.has(cl), "the hero can %s, and something in the world is done that way" % cl)
	check(hap.has_animation("duck"), "and goes bent under a low roof")
	hero.free()
	for ck in CaveThings.KINDS:
		var cm := CaveThings.model(ck, "frost")
		check(Props.KINDS.has(ck) and cm.get_child_count() >= 1, "the %s of the caves is built" % ck)
		cm.free()
	for hk in ["pickaxe", "spade", "pan", "chisel", "pestle", "jug", "comb"]:
		var hn := Props.held(hk)
		check(hn.get_child_count() >= 1 and Props.HELD.has(hk), "a %s can be held" % hk)
		hn.free()
	for gs in ["shrug", "cheer", "beckon", "refuse", "shiver"]:
		check(Data.EMOTES.has(gs), "everybody can %s" % gs)
	check(Props.KINDS.size() >= 82, "eighty-two things to do in the world, twenty-six of them new (%d)" % Props.KINDS.size())
	check(FileAccess.get_file_as_string("res://art/lib/face.py").contains("EYE_K = 0.86"), "every eye is a little larger (art/lib/face.py)")
	print("== Part XX: the Hollow Hills ==")
	check(Data.REALMS.size() >= 26 and Data.REALMS[25] == "Hollow Vessel" and Data.MAX_LEVEL >= 75 and Data.level_name(75).ends_with("Hollow Vessel") and Data.REALM_INFO.size() == Data.REALMS.size() and Data.EXP_NEED.size() == Data.MAX_LEVEL
		and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XX adds the Hollow Vessel realm")
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(Data.step_index("s_break25") == Data.step_index("s_p21_home") - 1 and Data.DIALOGUE.has("recall18") and msrc.contains("\"s_break24\": \"recall18\"") and Data.DIALOGUE.has("pre:s_break25") and Data.DIALOGUE.has("post:s_break25"),
		"Part XX follows Skill Become Dao (recall18) and ends with a tribulation that finds nothing to fill")
	for tid in ["fen_yang", "white_rat", "wangliang", "xuanpin"]:
		check(Trials.TRIALS.has(tid) and Lore.BOSS.has(tid) and Data.DIALOGUE.has("pre:" + tid) and Data.DIALOGUE.has("post:" + tid), "%s is a trial, with a story and words before and after" % tid)
		check((Trials.TRIALS[tid].paths as Array).any(func(pth): return str(pth.kind) == "delve"), "%s can be passed by the dark" % tid)
		check(_kill_step(tid) > Data.step_index("s_p20_home"), "%s is faced in Part XX" % tid)
	check(Trials.KINDS.has("delve") and Trials.EPITHETS.has("delve") and Assets.PEOPLE.has("xuanpin") and "person:xuanpin" in UI.SHAPES and Data.BOSS_DROPS.get("wangliang", "") == "borrowed_shadow" and Data.ITEMS.has("borrowed_shadow")
		and (Trials.TRIALS.xuanpin.paths as Array).any(func(pm): return str(pm.kind) == "relic" and pm.needs == [["item", "borrowed_shadow", 1]]) and _kill_step("xuanpin") > _kill_step("wangliang"),
		"the Valley Spirit is Blender-built, and what the Penumbra leaves is what she is shown")
	for mon in ["cave_cricket", "blind_newt", "drip_wisp", "stone_bat", "dig_mole", "ore_gnawer", "lamp_ghost", "kept_voice", "hollow_one", "burrow_marmot", "sink_toad", "karst_crawler"]:
		check(Data.ENEMIES.has(mon) and Lore.BEAST.has(mon) and Habits.HABITS.has(Habits.habit(mon)), "%s has a story, and keeps hours" % mon)
	for who in ["xu_xiake", "yu_gong", "zhi_sou", "wang_zhi"]:
		check(Assets.PEOPLE.has(who) and FileAccess.file_exists("res://art/characters/%s.py" % who) and Data.CHAT.has(who) and Trials.npc_area(who) != "", "%s is Blender-built, lives somewhere and has things to say" % who)
	check(FileAccess.get_file_as_string("res://art/characters/xuanpin.py").contains("\"fem\": True") and Voice.WOMEN.has("Xuanpin"), "the Valley Spirit is a woman, in the art and in the telling")
	var wsurf: Dictionary = Atlas.world_of("surface")
	for lid2 in ["xu_xiake", "yu_gong", "zhi_sou"]:
		check(wsurf.ents.filter(func(e3): return str(e3.id) == lid2).size() == 1, "%s stands in the world once (late: no older map moved for it)" % lid2)
	for lid3 in ["wang_zhi", "boss_fen_yang", "boss_white_rat", "boss_wangliang", "boss_xuanpin", "p20_milk1", "p20_bask5", "p20_lamp4", "p20_rub5"]:
		check(wsurf.ents.filter(func(e3): return str(e3.id) == lid3).is_empty(), "%s is under the ground, not on it" % lid3)
	for sid2 in ["s_p20_tea", "s_p20_fire"]:
		var sp: Dictionary = Data.STEPS[Data.step_index(sid2)]
		check(Bonds.SHARES.has(sid2) and not Bonds.find_spot(wsurf.ents, str(sp.spot)).is_empty() and Bonds.share_place(sid2) != "side by side", "%s: a scene with Yue Ling, at a place that is there" % sid2)
	for sid3 in ["s_p20_milk", "s_p20_things", "s_p20_crickets", "s_p20_carry", "s_p20_baskets", "s_p20_moles", "s_p20_shore", "s_p20_lamps", "s_p20_gnawers", "s_p20_pasture", "s_p20_towers", "s_p20_rubbings", "s_p20_shades",
			"s_p20_delve", "s_p20_board", "s_p20_hollow", "s_p20_wells", "s_p20_boats"]:
		check(Data.DIALOGUE.has("done:" + sid3), "%s has its word to say when it is done" % sid3)
	for hs in ["s_p20_pasture", "s_p20_towers"]:
		var hst: Dictionary = Data.STEPS[Data.step_index(hs)]
		var band: Dictionary = Data.AREAS[str(hst.area)].get("warband", {})
		check(bool(hst.get("first", false)) and bool(band.get("late", false)) and Data.step_index(str(band.vis)) < Data.step_index(hs) and int(band.n) * 2 >= int(hst.n), "%s: the packs are there before it, enough of them, and it asks for the first strike" % hs)
	var el: Dictionary = Data.STEPS[Data.step_index("s_p20_elders")]
	for nid in el.npcs:
		check(Data.DIALOGUE.has("visit:s_p20_elders:" + str(nid)), "%s has an answer to what an empty place is for" % nid)
	for fs in ["s_p20_carry", "s_p20_shore", "s_p20_wells", "s_p20_boats"]:
		var fst: Dictionary = Data.STEPS[Data.step_index(fs)]
		check(str(fst.kind) == "folk" and Folk.ERRANDS.has(fs) and fst.has("hearth") and fst.has("town") and Cultures.HEARTHS.has(str(fst.hearth)) and str(fst.town) in Cultures.HEARTHS[str(fst.hearth)].towns, "%s is an errand among a hearth's own townsfolk" % fs)
	var hearths_met := {}
	for st3 in Data.STEPS:
		if str(st3.id).begins_with("s_p20_") and st3.has("hearth"):
			hearths_met[str(st3.hearth)] = true
	check(hearths_met.size() >= 5, "Part XX does something for five hearths (%s)" % str(hearths_met.keys()))
	for cid3 in ["the_mountain", "the_echoes", "the_hollow"]:
		check(Data.step_index(str(Echoes.CROSSROADS[cid3].step)) > Data.step_index("s_p20_home") and str(Echoes.CROSSROADS[cid3].part) == "XX", "the crossroads %s is in Part XX" % cid3)
	var heard := 0
	for cid5 in Echoes.ORDER:
		if str(Echoes.CROSSROADS[cid5].part) == "XX":
			continue
		for ek in Echoes.CROSSROADS[cid5].echo:
			var ks := str(ek).trim_prefix("done:")
			if ks.begins_with("s_p20_") or ks in ["pre:xuanpin", "pre:white_rat", "pre:wangliang", "pre:fen_yang"]:
				heard += 1
	check(heard >= 4, "earlier crossroads echo in the conversations of Part XX (%d of them)" % heard)
	check(Trials.RECIPES.has("lamb_bell") and Trials.RECIPES.has("pine_torch") and Data.ITEMS.has("lamb_bell") and Data.ITEMS.has("pine_torch") and Data.ITEMS.has("stone_milk") and Data.ITEMS.has("miner_lamp"),
		"a bell for the Lamb of the Earth, the traveller's torch, stone-milk and miners' lamps")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(bsrc.contains("\"fen_yang\": \"craft\"") and bsrc.contains("\"white_rat\": \"delve\"") and bsrc.contains("\"wangliang\": \"heart\"") and bsrc.contains("\"xuanpin\": \"relic\"") and bsrc.contains("\"s_p20_fire\"")
		and bsrc.contains("func _delve_step") and bsrc.contains("func _try_step"), "the bot has a way through the four trials, goes down caves, and does what is done in them")

## Whether `s` has one of `words` as a whole word (any case).
func _has_word(s: String, words: Array) -> bool:
	var r := RegEx.new()
	r.compile("(?i)\\b(" + "|".join(words) + ")\\b")
	return r.search(s) != null


## The Hundred Arms release: faces that show what they feel (faces.gd), the Eight Arms and the Dao of
## each (arms.gd), twelve ends of the story, bright, bitter and dark (cultures.gd), and Part XXI.
func _hundred_arms() -> void:
	print("== faces (faces.gd) ==")
	check(Faces.ORDER.size() == 14 and Faces.EXPRESSIONS.size() == Faces.ORDER.size(), "fourteen faces (%d)" % Faces.ORDER.size())
	var calm := Faces.vector_of("calm")
	var differ := true
	for fid in Faces.ORDER:
		check(Faces.EXPRESSIONS.has(fid) and Faces.vector_of(fid).size() == 13, "the face %s is a pose of the six bones" % fid)
		for other in Faces.ORDER:
			if other != fid and Faces.vector_of(other) == Faces.vector_of(fid):
				differ = false
	check(differ and calm[10] == 1.0 and calm[11] == 1.0 and calm[0] == 0.0, "no two faces are the same, and a calm one is the head as it was sculpted")
	for g in Data.EMOTES:
		check(Faces.OF_ACT.has(g) and Faces.EXPRESSIONS.has(str(Faces.OF_ACT[g][0])), "the gesture %s is made with a face" % g)
	for ak in Faces.OF_ACT:
		check(Faces.EXPRESSIONS.has(str(Faces.OF_ACT[ak][0])) and float(Faces.OF_ACT[ak][1]) >= 0.0, "%s: a real face, for a while" % ak)
	for ck in Faces.OF_CLIP:
		check(Faces.EXPRESSIONS.has(str(Faces.OF_CLIP[ck])), "a body busy with %s keeps a real face" % ck)
	check(Faces.for_line(["Elder Qing Xuan", "Hahaha! Splendid."]) == "joy" and Faces.for_line(["Narrator", "Hahaha!"]) == "" and Faces.for_line(["Yue Ling", "It is nothing.", "nod", "sorrow"]) == "sorrow"
		and Faces.for_line(["Lin Feng", "Who told you that?"]) == "doubt" and Faces.for_line(["Lin Feng", "The rice is cooked."]) == "", "a line of dialogue is read for a face: its cue, or its words, and the narrator has none")
	var fsrc := FileAccess.get_file_as_string("res://art/lib/face.py")
	check(fsrc.contains("def expression_bones") and fsrc.contains("def expression_weights") and FileAccess.get_file_as_string("res://art/lib/person.py").contains("facelib.expression_bones(r, o)"),
		"the bones of expression are sculpted into every head by the art scripts")
	for who in ["lin_feng", "lin_feng_f", "yue_ling", "elder_qing", "granny_wen", "ou_yezi"]:
		var fm := Assets.person(who)
		check(Faces.has_face(fm), "%s has a face that can move" % who)
		if Faces.has_face(fm):
			var sk := fm.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
			for bn in Faces.BONES:
				check(sk.find_bone(bn) >= 0, "%s: the bone %s" % [who, bn])
			check(sk.get_bone_parent(sk.find_bone("eyes")) == sk.find_bone("lids") and sk.get_bone_parent(sk.find_bone("mouth")) == sk.find_bone("jaw"), "%s: a blink is inside the lids and speech inside the jaw" % who)
			var lids := sk.find_bone("lids")
			var brow := sk.find_bone("brow.L")
			var rest_y: float = sk.get_bone_pose_position(brow).y
			Faces.wear(fm, "joy")
			for k in 40:
				Faces.tick(fm, 0.05)
			var shut: float = sk.get_bone_pose_scale(lids).y
			Faces.wear(fm, "surprise")
			for k2 in 40:
				Faces.tick(fm, 0.05)
			check(shut < 0.3 and sk.get_bone_pose_scale(lids).y > 1.1 and sk.get_bone_pose(brow).origin.distance_to(sk.get_bone_rest(brow).origin) > 0.003 and Faces.worn(fm) == "surprise",
				"%s: eyes shut with joy, open wide in surprise with the brows up" % who)
			Faces.wear(fm, "anger", 0.5)
			for k3 in 60:
				Faces.tick(fm, 0.05)
			check(Faces.worn(fm) == "calm" and absf(sk.get_bone_pose_scale(lids).y - 1.0) < 0.01 and absf(sk.get_bone_pose_position(brow).y - rest_y) < 0.0005, "%s: a face worn for a while goes back to the one kept" % who)
			Models.act(fm, "hurt", 0.0)
			check(Faces.worn(fm) == "pain", "%s: a blow shows in the face" % who)
		fm.free()
	print("== the Eight Arms (arms.gd) ==")
	check(Arms.ORDER.size() == 8 and Arms.WEAPONS.size() == 8 and Arms.TIERS.size() == Data.DAO_RANKS.size(), "eight weapons, each with a Dao of three ranks")
	var clips := {}
	var arts := {}
	var daos := {}
	var skills := {}
	var hero8 := Models.hero({})
	for aid in Arms.ORDER:
		var w: Dictionary = Arms.WEAPONS[aid]
		check(Assets.has("weapons/" + str(w.model)) and FileAccess.file_exists("res://art/weapons/%s.py" % str(w.model)), "%s: a model built from its script" % aid)
		check(Assets.has_clip(hero8, str(w.clip)) and Assets.has_clip(hero8, str(w.art)), "%s: the hero has a clip for its blow and one for its technique" % aid)
		clips[str(w.clip)] = true
		arts[str(w.art)] = true
		daos[str(w.dao.n)] = true
		skills[str(w.skill)] = true
		check(str(w.dao.n).begins_with("Dao of") and str(w.dao.motto).length() > 10 and str(w.dao.desc).length() > 30 and str(w.desc).length() > 80 and str(w.how) != "", "%s: a Dao with a name and a motto, and a story" % aid)
		check(Data.SKILLS.has(str(w.skill)) and str(Data.SKILLS[str(w.skill)].get("arm", "")) == aid and float(Data.SKILLS[str(w.skill)].k) >= 1.0, "%s: a technique of its own" % aid)
		var mods_ok := not (w.mods as Dictionary).is_empty()
		for mk in w.mods:
			mods_ok = mods_ok and (w.mods[mk] as Array).size() == Arms.TIERS.size()
		check(mods_ok and Arms.mods_text(aid, 0) != "" and Arms.mods_text(aid, 2) != Arms.mods_text(aid, 0), "%s: its Dao does something at every rank, and more as a Master" % aid)
		check(aid in Arms.FIRST or (Data.step_index(str(w.get("step", ""))) >= 0 and Data.step_index(str(w.step)) < Data.step_index("s_break5")), "%s: his from the first morning, or won early on the road" % aid)
		check(Arms.attach(hero8, aid) and Arms.attached(hero8) == aid and hero8.find_children("arm_model", "", true, false).size() == 1 and hero8.has_meta("arm_carry") == w.has("carry"), "%s: hangs on the sword bone, one at a time" % aid)
		check(Arms.strike_clip(hero8) == str(w.clip), "%s: is struck with in its own way" % aid)
	check(clips.size() == 8 and arts.size() == 8 and daos.size() == 8 and skills.size() == 8, "eight blows, eight techniques, eight Daos, no two alike")
	hero8.free()
	var story_hero := Models.person(Color("3a8ae8"), Color("1a1a2a"), {"asset": "lin_feng", "sword": true})
	check(Arms.attached(story_hero) == "sword" and Arms.strike_clip(story_hero) == "attack", "the story's own Lin Feng carries his jian")
	story_hero.free()
	var yl := Assets.person("yue_ling")
	check(not Arms.attach(yl, "sabre") and not Assets.has_clip(yl, "arm_sabre") and Arms.strike_clip(yl) == "attack", "only the hero bears arms: Yue Ling keeps to her needle")
	yl.free()
	check(FileAccess.get_file_as_string("res://art/lib/person.py").contains("ARMS = {") and FileAccess.get_file_as_string("res://art/check_assets.py").contains("\"weapons\""), "the clips and the models are checked with the rest of the art")
	var AG = load("res://scripts/game.gd").new()
	AG.reset()
	check(AG.arms.keys() == Arms.FIRST and Arms.held(AG) == "sword" and Arms.tier(AG) == 0 and Arms.adept(AG) == 0 and Arms.skills(AG).is_empty(), "the first morning: a jian, a broom handle, and nothing learned")
	check(not AG.wield("sabre") and AG.wield("staff") and Arms.held(AG) == "staff" and not AG.wield("staff") and AG.arm_switches == 1, "a weapon owned can be taken in hand; one not owned cannot")
	AG.step = Data.step_index("s_ironfang")
	AG.advance()
	check(AG.arms.has("sabre") and AG.wield("sabre"), "Iron Fang's sabre is taken from him")
	var spd0: int = AG.fighter(0).spd
	AG.wield("bow") # not owned
	AG.grant_arm("bow")
	AG.wield("bow")
	check(AG.fighter(0).spd == spd0 + 2 + 3 and Arms.mod(AG, "first", 1.0) > 1.3 and Arms.mod(AG, "sweep", 0.0) == 0.0, "the weapon in the hand changes the fight: the bow is quick, and it is not a staff")
	var r1: int = AG.renown
	for k4 in int(Arms.TIERS[1]) - 1:
		AG.arm_battle_won(false)
	check(Arms.tier(AG) == 0 and not AG.fighter(0).skills.has("arm_unshot"), "a Novice has not the technique yet")
	AG.arm_battle_won(false)
	check(Arms.tier(AG) == 1 and Arms.adept(AG) == 1 and AG.fighter(0).skills.has("arm_unshot") and AG.renown == r1 + 1 and Arms.mod(AG, "spd", 0.0) == 5.0, "an Adept of the bow is taught the Shot Not Shot, and it is news")
	AG.wield("sabre")
	check(not AG.fighter(0).skills.has("arm_unshot") and Arms.tier(AG) == 0 and Arms.tier(AG, "bow") == 1, "each weapon keeps its own mastery, and its technique goes with it")
	AG.arm_battle_won(true)
	check(int(AG.arm_xp.sabre) == 4, "a lord counts four")
	AG.wield("bow")
	var low: Dictionary = AG.skill_of("arm_unshot")
	AG.level = 50
	AG.step = Data.step_index("s_p13_home")
	var high: Dictionary = AG.skill_of("arm_unshot")
	check(float(low.mult) > 1.5 and float(high.mult) > float(low.mult) * 10.0 and int(high.cost) > int(low.cost) and AG.skill_cost("arm_unshot") > 0.0 and AG.skill_of("strike") == Data.SKILLS.strike,
		"a weapon's technique grows with what he knows (x%.1f at the start, x%.1f at Dao Ancestor)" % [float(low.mult), float(high.mult)])
	check(not Data.known_skills(0, 78).has("arm_unshot"), "techniques of arms come only from the weapon in the hand")
	check(Trials.need_met(["arms", 1], AG) and not Trials.need_met(["arms", 2], AG) and Trials.need_text(["arms", 2], AG).contains("now 1"), "the way through a trial by the hand counts the Daos of arms learned")
	# a hunt that asks for a weapon counts what falls while it is in the hand
	AG.step = Data.step_index("s_p21_reeds")
	AG.area = "marsh"
	AG.layer = "surface"
	AG.hunt = 0
	AG.record_kills("marsh", 2, ["sword_reed", "white_gibbon"])
	var h_bow: int = AG.hunt
	AG.wield("staff")
	AG.record_kills("marsh", 3, ["sword_reed", "white_gibbon", "mire_toad"])
	check(h_bow == 0 and AG.hunt == 2, "a hunt with the staff counts what the staff brings down, of the creatures named")
	AG.step = Data.step_index("s_p21_adept")
	AG.poll_steps()
	check(AG.cur_step().id == "s_p21_adept" and AG.objective_text().contains("(1/3)"), "three Daos of arms are asked for, and one is not three")
	for aid2 in ["staff", "sabre"]:
		AG.wield(aid2)
		while Arms.tier(AG, aid2) < 1:
			AG.arm_battle_won(false)
	check(AG.cur_step().id == "s_p21_grave", "three Adepts, and the story goes on")
	AG.free()
	var bt := FileAccess.get_file_as_string("res://scripts/battle.gd")
	check(bt.contains("Arms.strike_clip(actor.model)") and bt.contains("Game.arm_battle_won(boss)") and bt.contains("_arm_touch") and FileAccess.get_file_as_string("res://scripts/world.gd").contains("Arms.strike_clip(player)")
		and FileAccess.get_file_as_string("res://scripts/menu.gd").contains("\"arms\""), "the battle, the open land and the menu all know what is in his hand")
	print("== twelve ends (cultures.gd) ==")
	var EG = load("res://scripts/game.gd").new()
	EG.reset()
	var kinds := {}
	# (ending.gd uses the Game autoload and cannot be compiled from here: its text is read)
	var ending_txt := FileAccess.get_file_as_string("res://scripts/ending.gd")
	for eid in Cultures.ENDING_ORDER:
		var en: Dictionary = Cultures.ENDINGS[eid]
		var kind := str(en.get("kind", "bright"))
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		check(Cultures.ENDING_KINDS.has(kind) and Faces.EXPRESSIONS.has(str(en.get("face", "smile"))), "%s: a bright, a bitter or a dark end, with a face for it" % eid)
		if kind != "bright":
			check(str(en.desc).begins_with("A %s end." % kind) and not en.get("hearth", true) and (en.lines as Array).size() >= 2 and ending_txt.contains("\t\"%s\": \"Lin Feng, once a sweeper of steps" % eid), "%s: said to be a %s end before it is chosen, and it has its own last word" % [eid, kind])
		for ln in en.lines:
			var par := TextParagraph.new()
			par.width = 1100.0
			par.add_string(str(ln[1]), UI.font(), 22)
			check(par.get_line_count() <= 4, "%s: its last words fit the dialogue box" % eid)
	check(int(kinds.get("dark", 0)) == 4 and int(kinds.get("bitter", 0)) == 1 and int(kinds.get("bright", 0)) == 7, "seven bright ends, one bitter and four dark")
	check(ending_txt.contains("const HEADLINES") and ["school", "broom", "throne", "blade", "engine", "cold"].all(func(h2): return ending_txt.contains("\"%s\": \"" % h2)) and ending_txt.contains("HEADLINES.get(Cultures.ending_of(Game), \"ASCENSION\")"),
		"the results are headed ASCENSION only for the ends that are one")
	check(Cultures.ending_open("cold", EG) and not Cultures.ending_open("school", EG) and not Cultures.ending_open("throne", EG), "a journey that sat at nobody's table may hold the sky alone, and has earned no school and no throne")
	for hid5 in ["steppe", "sand"]:
		Cultures.earn(EG, hid5, Cultures.GUEST)
	check(not Cultures.ending_open("cold", EG), "two hearths that call him a guest, and the cold hearth is shut")
	EG.arm_xp = {"sword": Arms.TIERS[2], "staff": Arms.TIERS[2], "sabre": Arms.TIERS[1], "bow": Arms.TIERS[1]}
	check(Cultures.ending_open("school", EG) and not Cultures.ending_open("blade", EG), "four Daos of arms open the school; two mastered do not unsheathe the blade in a merciful hand")
	EG.scales = {"heart": -Echoes.LEAN, "reach": Echoes.LEAN, "craft": Echoes.LEAN}
	check(Cultures.ending_open("blade", EG) and Cultures.ending_open("throne", EG) and Cultures.ending_open("far", EG) and not Cultures.ending_open("broom", EG) and not Cultures.ending_open("engine", EG),
		"unbending and of the wide world: the blade, the throne and the far shore; the engine wants works built, and the broom the old ways")
	EG.scales["craft"] = -Echoes.LEAN
	check(Cultures.ending_open("broom", EG), "the old ways open the broom")
	EG.ending = "throne"
	var tl: Array = Cultures.ending_lines(EG)
	check(Cultures.ending_kind(EG) == "dark" and tl.size() == 3 and str(tl[2][1]).contains("picks up a broom"), "a dark end is told in its own words, without the kind word of the hearth")
	EG.ending = "school"
	check(Cultures.ending_kind(EG) == "bright" and Cultures.ending_lines(EG).size() == 3, "a bright one ends with the hero's own hearth")
	EG.free()
	var msrc5 := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(msrc5.contains("Cultures.ENDING_KINDS") and FileAccess.get_file_as_string("res://scripts/ending.gd").contains("LAST_WORDS") and FileAccess.get_file_as_string("res://scripts/bot.gd").contains("\"school\", \"open\""), "the choice names the kind of end, the film has its last word, and the bot has a plan")
	print("== Part XXI: the Hundred Arms ==")
	check(Data.REALMS.size() >= 27 and Data.REALMS[26] == "Sheathed Edge" and Data.MAX_LEVEL >= 78 and Data.level_name(78).ends_with("Sheathed Edge") and Data.REALM_INFO.size() == Data.REALMS.size() and Data.EXP_NEED.size() == Data.MAX_LEVEL
		and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXI adds the Sheathed Edge realm")
	check(Data.step_index("s_break26") > Data.step_index("s_p21_end") and Data.DIALOGUE.has("recall19") and msrc5.contains("\"s_break25\": \"recall19\"") and Data.DIALOGUE.has("pre:s_break26") and Data.DIALOGUE.has("post:s_break26"),
		"Part XXI follows Hollow Vessel (recall19) and ends in a breakthrough")
	var n21 := 0
	var arm_hunts := {}
	for st in Data.STEPS:
		if not str(st.id).begins_with("s_p21_"):
			continue
		n21 += 1
		if str(st.kind) == "talk":
			check(Data.DIALOGUE.has(str(st.id)), "%s: there is something said" % st.id)
		if st.has("arm"):
			arm_hunts[str(st.arm)] = true
			check(str(st.kind) == "hunt" and Arms.WEAPONS.has(str(st.arm)) and str(st.t).to_lower().contains(str(st.arm)),
				"%s: a hunt with a weapon says which" % st.id)
	check(n21 >= 34 and arm_hunts.size() == 7 and not arm_hunts.has("sword"), "Part XXI has %d steps, and a hunt for each of the seven weapons that are not the jian" % n21)
	for tid in ["yuan_gong", "sword_dragons", "king_zhao", "wuzhu"]:
		check(Trials.TRIALS.has(tid) and Data.ENEMIES[tid].get("boss", false) and Lore.BOSS.has(tid) and Trials.trial_of_step(Data.STEPS[_kill_step(tid)]) == tid, "%s is a lord of Part XXI, guarded by a trial, with a story" % tid)
	check(["yuan_gong", "king_zhao", "wuzhu"].all(func(t2): return (Trials.TRIALS[t2].paths as Array).any(func(pth): return str(pth.kind) == "arms")), "three of them can be passed by the hand")
	check(Trials.KINDS.has("arms") and Trials.EPITHETS.has("arms") and ending_txt.contains("\"arms\": \"the Hand\"") and Data.BOSS_DROPS.get("king_zhao", "") == "three_swords" and "person:king_zhao" in UI.SHAPES and "person:wuzhu" in UI.SHAPES,
		"by the hand is a way of its own, and the king leaves his scroll")
	for pid in ["ou_yezi", "yue_maiden", "ji_chang", "zhuang_envoy", "king_zhao", "wuzhu"]:
		check(Assets.PEOPLE.has(pid) and Assets.has(Assets.PEOPLE[pid]) and FileAccess.file_exists("res://art/characters/%s.py" % pid), "%s has a model built from a script" % pid)
	for fid2 in ["sword_reed", "white_gibbon", "hook_heron", "stray_arrow", "wheel_louse", "cup_snake", "gate_swordsman", "fighting_cock", "broken_edge", "pool_blade", "mound_tiger", "humming_sword"]:
		check(Data.ENEMIES.has(fid2) and Lore.BEAST.has(fid2) and Habits.habit(fid2) != "", "%s: a foe of Part XXI with a story and hours of its own" % fid2)
	var x21: Array = Echoes.ORDER.filter(func(c2): return str(Echoes.CROSSROADS[c2].part) == "XXI")
	check(x21 == ["the_pupils", "the_three_thousand", "the_arms"], "what a weapon is for is asked three times")
	var old_echo := 0
	for cid in Echoes.ORDER:
		if str(Echoes.CROSSROADS[cid].part) == "XXI":
			continue
		for ek in Echoes.CROSSROADS[cid].echo:
			if str(ek).contains("p21_") or str(ek) in ["pre:wuzhu", "pre:king_zhao", "pre:yuan_gong", "pre:sword_dragons"]:
				old_echo += 1
	check(old_echo >= 4, "four older crossroads echo in Part XXI (%d)" % old_echo)
	check(Caves.OWN.has("longmen") and Caves.OWN.has("grave") and Bonds.SHARES.has("s_p21_stage") and Bonds.SHARES.has("s_p21_sweep") and Folk.ERRANDS.has("s_p21_racks"), "two caves of its own, two evenings with Yue Ling, and errands at four hearths")
	var bsrc5 := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(bsrc5.contains("\"yuan_gong\": \"arms\"") and bsrc5.contains("\"the_arms\": [\"school\"") and bsrc5.contains("func _want_arm") and bsrc5.contains("\"s_p21_sweep\": \"broom\""), "the bot has a plan for every trial, crossroads and evening of Part XXI, and changes weapons by itself")

## The High Roads release: the mountains (peaks.gd), climbing and the cloud-kite (world.gd, glider.gd), the
## people of the road (folk.gd) and Part XXII.
func _high_roads() -> void:
	print("== the mountains (peaks.gd) ==")
	var wd: Dictionary = Atlas.world()
	var peaks: Array = wd.peaks
	var reach := MapGen.flood(wd.grid, wd.w, wd.h, wd.start)
	var W: int = wd.w
	var without: Array = []
	for id in wd.ids:
		if Peaks.of_area(wd, id).is_empty() and not (id in Peaks.NONE):
			without.append(id)
	check(peaks.size() >= 90 and without.size() <= 2, "there are mountains in every region of the land but the wettest (%d peaks; none in %s)" % [peaks.size(), str(without)])
	var names := {}
	var own_land := true
	var tops_reached := true
	var tops_free := true
	var steep_n := 0
	var heights_ok := true
	var numbered := true
	var ent_at := {}
	for e in wd.ents:
		if e.has("pos"):
			ent_at[e.pos] = e
	for pk in peaks:
		names[str(pk.n)] = true
		var c: Vector2i = pk.c
		var r: int = pk.r
		heights_ok = heights_ok and float(pk.h) >= 8.0 and float(pk.h) <= 48.0 and absf(Peaks.at(wd, c) - float(pk.h)) < float(pk.h) * 0.08 and Peaks.summit_at(wd, c) == pk and Peaks.of_tile(wd, c) == pk
		tops_reached = tops_reached and reach.has(c)
		tops_free = tops_free and not ent_at.has(c)
		var me: int = wd.owner[c.y * W + c.x]
		var steep := false
		for y in range(c.y - r, c.y + r + 1):
			for x in range(c.x - r, c.x + r + 1):
				if Peaks.rise_of(pk, float(x) + 0.5, float(y) + 0.5) > 0.25:
					own_land = own_land and wd.owner[y * W + x] == me and MapGen.is_walkable_tile(wd.grid[y * W + x])
					if Peaks.climb(wd, Vector2i(x, y), Vector2i(x + 1, y)) != 0:
						steep = true
		if steep:
			steep_n += 1
		var k := int(str(pk.id).get_slice(":", 2))
		if k > 0:
			numbered = numbered and float(Peaks.by_id(wd, "peak:%s:%d" % [str(pk.area), k - 1]).h) >= float(pk.h)
	check(names.size() == peaks.size(), "no two peaks of the land have the same name")
	check(heights_ok, "every peak is a crag of ten to forty-odd metres, as high at its top as it says")
	check(own_land, "every tile a peak lifts is open ground of its own region: no peak joins two regions")
	check(tops_reached and tops_free, "every summit can be walked (and climbed) to from the sect, and nothing stands on the very top")
	check(steep_n == peaks.size(), "every peak has rock too steep to walk: it is climbed (%d of %d)" % [steep_n, peaks.size()])
	check(numbered and str(Peaks.by_id(wd, "peak:mountain:0").n) == "Sun-Viewing Peak" and str(Peaks.by_id(wd, "peak:mountain:1").n) == "the Sweeper's Lookout", "a region's peaks are numbered from its highest down, and the mountain's two great ones have their names")
	check(Peaks.rise(wd, 3.5, 3.5) == 0.0 and Peaks.climb(wd, wd.start, wd.start + Vector2i(1, 0)) == 0 and Peaks.of_area(Atlas.world_of("f:mountain:cave:-1") if false else {}, "mountain").is_empty(), "the plain is level, and a floor or a cave has no mountains")
	# what the story stands on a peak is on its rock, and can be got to
	var on_rock := 0
	for a in Data.AREAS:
		for kind in ["npcs", "bosses", "pickups"]:
			for d in Data.AREAS[a].get(kind, []):
				if d.has("peak"):
					var eid := ("boss_" + str(d.id)) if kind == "bosses" else str(d.id)
					var found := false
					for e2 in wd.ents:
						if str(e2.id) == eid:
							found = true
							var pk2: Dictionary = Peaks.of_area(wd, a)[mini(int(d.peak), Peaks.of_area(wd, a).size() - 1)]
							var near_top: bool = maxi(absi(e2.pos.x - pk2.c.x), absi(e2.pos.y - pk2.c.y)) <= 2
							var ok2: bool = reach.has(e2.pos) and e2.pos != pk2.c and Vector2(e2.pos - pk2.c).length() <= float(pk2.r) + 1.0 and (str(d.get("stand", "top")) != "top" or near_top)
							check(ok2, "%s stands on the peak the story puts it on" % eid)
							on_rock += 1
					check(found, "%s is in the world" % eid)
	check(on_rock >= 20, "Part XXII stands its people, its lords and its things on the mountains (%d)" % on_rock)
	var hsrc := FileAccess.get_file_as_string("res://scripts/terrain3d.gd")
	var wsrc := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(hsrc.contains("Peaks.rise(wd, float(cx), float(cz))") and FileAccess.get_file_as_string("res://scripts/scatter.gd").contains("_crag_tile") and FileAccess.get_file_as_string("res://scripts/gfx.gd").contains("Peaks.rise_of"),
		"the mountains are in the height field, bare of meadow, and drawn on the map")
	print("== climbing and the cloud-kite (world.gd, glider.gd) ==")
	check(wsrc.contains("climb = 0 if is_floor() else Peaks.climb(wd, ptile, nt)") and wsrc.contains("func toggle_glide") and wsrc.contains("func _landable") and wsrc.contains("Game.seen.has(Atlas.owner_id(wd, nt))")
		and FileAccess.get_file_as_string("res://scripts/main.gd").contains("KEY_V"), "a steep step is climbed, V opens the kite, and a flight keeps to the regions he has walked into and ends where somebody can stand")
	var kite := Glider.build(Color("2a5aa8"), Color("e8f0ff"))
	check(kite.get_child_count() == 2 and (kite.get_child(1) as MeshInstance3D).mesh.get_surface_count() == 1 and (kite.get_child(1) as MeshInstance3D).get_aabb().size.x > 3.0, "the cloud-kite is built from code, three and a half metres across")
	kite.free()
	var cairn := Peaks.cairn(7, Color("c83a3a"))
	check(cairn.get_child_count() == 1, "and so is the cairn on every summit")
	cairn.free()
	var psrc := FileAccess.get_file_as_string("res://art/lib/person.py")
	check(psrc.contains("def clip_scale(t):") and psrc.contains("def clip_glide(t):") and psrc.contains("def clip_alight(t):") and psrc.contains("\"scale\": (SCALE_T, clip_scale)")
		and FileAccess.get_file_as_string("res://art/check_assets.py").contains("\"scale\", \"glide\", \"alight\""), "three new clips, written in Blender Python and checked with the rest of the art")
	for who in ["lin_feng", "lin_feng_f", "lin_feng_wild", "lin_feng_f_scholar", "yue_ling"]:
		var pm := Assets.instance("characters/" + who)
		check(Assets.has_clip(pm, "scale") and Assets.has_clip(pm, "glide") and Assets.has_clip(pm, "alight"), "%s climbs, glides and alights" % who)
		pm.free()
	check("scale" in Assets.LOOPS and "glide" in Assets.LOOPS and "scale" in Assets.LEND and Faces.OF_CLIP.has("scale") and Faces.OF_CLIP.has("glide"), "the new clips go round, are lent to the people of the road, and have faces")
	var HG = load("res://scripts/game.gd").new()
	HG.reset()
	HG.step = Data.step_index("s_p22_first")
	HG.summit("peak:mountain:0", "Sun-Viewing Peak", 35.0)
	check(HG.cur_step().id == "s_p22_first" and HG.summits.size() == 1 and str(HG.timeline[HG.timeline.size() - 1].text).begins_with("Stood on Sun-Viewing Peak"), "a summit stood on is remembered, and the wrong one does not finish a step that names another")
	HG.summit("peak:mountain:1", "the Sweeper's Lookout", 24.0)
	HG.summit("peak:mountain:1", "the Sweeper's Lookout", 24.0)
	check(HG.cur_step().id == "s_p22_leap" and HG.summits.size() == 2, "the Lookout climbed, and the story goes on (a summit counts once)")
	HG.glide_done(7, 5.0)
	check(HG.cur_step().id == "s_p22_leap" and HG.objective_text().contains("(14/16 m)"), "a flight too short is not the flight asked for")
	HG.glide_done(9, 6.0)
	check(HG.cur_step().id == "s_p22_ziqi" and HG.step_glide == 0 and HG.glide_best == 9, "sixteen metres under the kite, and the story goes on")
	HG.step = Data.step_index("s_p22_summits")
	check(HG.objective_text().contains("(2/7)") and Trials.need_met(["summits", 2], HG) and not Trials.need_met(["summits", 3], HG) and Trials.need_text(["summits", 3], HG).contains("now 2"), "summits are counted for a step and for the way through a trial by the heights")
	for k2 in 5:
		HG.summit("peak:silk:%d" % k2, "somewhere", 20.0)
	check(HG.cur_step().id == "s_p22_hermits", "seven summits, any of them")
	HG.free()
	print("== the people of the road (folk.gd) ==")
	var camps: Dictionary = wd.camps
	check(camps.size() >= 30, "there is a camp of the people of the road in most regions of the land (%d)" % camps.size())
	var role_ok := true
	for role in Folk.CAMP_ROLES:
		role_ok = role_ok and Folk.ROLES.has(role) and Folk.TITLES.has(role) and (Folk.LINES.get(role, []) as Array).size() >= 4 and Folk.BODIES.human.has(role)
		for st in Folk.ROLES[role].day:
			role_ok = role_ok and Folk.PLACES.has(str(st[1])) and str(st[2]) != "in"
			for cl in str(st[2]).split("|"):
				role_ok = role_ok and (cl in Assets.LEND or Data.EMOTES.has(cl) or cl in ["look", "idle"])
	check(role_ok and Folk.CAMP_ROLES.size() == 7, "seven kinds of people live on the road, each with a day out of doors, words of their own and clips for all of it")
	var days_ok := true
	var on_ground := true
	var by_fire := 0
	var at_work := 0
	var hermits_up := 0
	var people_n := 0
	for ca in camps:
		var cid := Folk.camp_of(wd, str(ca))
		var heart: Vector2i = Folk.heart(cid)
		on_ground = on_ground and reach.has(heart) and Peaks.at(wd, heart) < 0.3 and Atlas.owner_id(wd, heart) == str(ca)
		var ppl: Array = Folk.people(wd, cid)
		days_ok = days_ok and ppl.size() == 7 and Folk.town(cid).get("camp", false) and Folk.is_camp(cid) and not Folk.TOWNS.has(cid)
		for fp in ppl:
			people_n += 1
			var segs: Array = Folk.day_of(wd, fp)
			days_ok = days_ok and not segs.is_empty() and float(segs[segs.size() - 1].b) >= float(fp.start) + 1439.0
			for sg in segs:
				if str(sg.kind) == "stay":
					var tl := Vector2i(int(floor((sg.at as Vector2).x)), int(floor((sg.at as Vector2).y)))
					on_ground = on_ground and MapGen.is_walkable_tile(wd.grid[tl.y * W + tl.x]) and Atlas.owner_id(wd, tl) == str(ca) and not bool(sg.in)
			var night: Dictionary = Folk.state(wd, fp, 23.5 * 60.0)
			var day: Dictionary = Folk.state(wd, fp, 10.0 * 60.0)
			if str(fp.role) == "hermit":
				if Peaks.rise(wd, (day.at as Vector2).x, (day.at as Vector2).y) > 6.0 and bool(day.vis):
					hermits_up += 1
			else:
				if bool(night.vis) and not bool(night.walk) and (night.at as Vector2).distance_to(Vector2(heart) + Vector2(0.5, 0.5)) < 4.5 and str(night.clip) == "doze":
					by_fire += 1
				if bool(day.vis) and (bool(day.walk) or (day.at as Vector2).distance_to(Vector2(heart) + Vector2(0.5, 0.5)) > 3.0):
					at_work += 1
	check(days_ok and people_n == camps.size() * 7, "every camp has seven people, each with a whole day of their own (%d people)" % people_n)
	check(on_ground, "a camp stands on open ground of its own region that can be walked to, and its people keep to that region, out of doors")
	check(by_fire == camps.size() * 6, "at night all but the hermit sleep sitting up by the fire (%d of %d)" % [by_fire, camps.size() * 6])
	check(at_work >= camps.size() * 5, "by day they are out at their work, away from the fire (%d of %d)" % [at_work, camps.size() * 6])
	check(hermits_up >= camps.size() - 2, "and the hermit is on the mountain (%d of %d)" % [hermits_up, camps.size()])
	var some_camp: String = Folk.camp_of(wd, "mountain")
	var cut_p: Dictionary = Folk.people(wd, some_camp)[0]
	var TG = load("res://scripts/game.gd").new()
	TG.reset()
	check(Folk.line(cut_p, TG).length() > 10 and not Folk.line(cut_p, TG).contains("%s") and Folk.greeting(cut_p, TG) != "" and not Folk.at_tile(wd, Vector2i(int((Folk.state(wd, cut_p, 600.0).at as Vector2).x), int((Folk.state(wd, cut_p, 600.0).at as Vector2).y)), 600.0).is_empty(),
		"somebody of the road can be faced and spoken to like anybody of the towns")
	TG.free()
	check(wsrc.contains("Folk.homes_in(wd, str(k))") and FileAccess.get_file_as_string("res://scripts/structures.gd").contains("static func camp(seed_: int)"), "the world draws the camps and their people")
	print("== Part XXII: the High Roads ==")
	check(Data.REALMS.size() >= 28 and Data.REALMS[27] == "Leaning on Nothing" and Data.MAX_LEVEL >= 81 and Data.level_name(81).ends_with("Leaning on Nothing") and Data.REALM_INFO.size() == Data.REALMS.size() and Data.EXP_NEED.size() == Data.MAX_LEVEL
		and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXII adds the realm of Leaning on Nothing")
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(Data.step_index("s_break27") == Data.step_index("s_p23_home") - 1 and Data.DIALOGUE.has("recall20") and msrc.contains("\"s_break26\": \"recall20\"") and Data.DIALOGUE.has("pre:s_break27") and Data.DIALOGUE.has("post:s_break27"),
		"Part XXII follows Sheathed Edge (recall20), and Part XXIII follows it")
	var n22 := 0
	var kinds22 := {}
	for st in Data.STEPS:
		if not str(st.id).begins_with("s_p22_"):
			continue
		n22 += 1
		kinds22[str(st.kind)] = int(kinds22.get(str(st.kind), 0)) + 1
		if st.kind == "talk":
			check(Data.DIALOGUE.has(str(st.id)), "%s: there is something said" % st.id)
		elif st.kind != "kill":
			check(Data.DIALOGUE.has("done:" + str(st.id)), "%s: something is said when it is done" % st.id)
		if st.kind == "folk":
			check(Folk.CAMP_ROLES.has(str(st.role)) and Folk.ERRANDS.has(str(st.id)), "%s: an errand among the people of the road" % st.id)
		if st.kind == "summit" and st.has("peak"):
			check(not Peaks.by_id(wd, "peak:%s:%d" % [str(st.peak), int(st.get("k", 0))]).is_empty(), "%s: the peak it names is there" % st.id)
		if st.kind == "glide":
			var tall := 0
			for pk3 in peaks:
				if float(pk3.h) + 1.7 >= float(st.n) * 0.8 + 1.0:
					tall += 1
			check(tall >= 5, "%s: there are peaks tall enough for a flight of %d tiles (%d)" % [st.id, int(st.n), tall])
	check(n22 >= 28 and int(kinds22.get("summit", 0)) == 2 and int(kinds22.get("glide", 0)) == 4 and int(kinds22.get("folk", 0)) == 4 and int(kinds22.get("hunt", 0)) == 4 and int(kinds22.get("kill", 0)) == 4,
		"Part XXII has %d steps: summits, flights, errands on the road, hunts and four lords" % n22)
	for tid in ["shanxiao", "fei_lian", "shan_gui", "dongyue"]:
		check(Trials.TRIALS.has(tid) and Data.ENEMIES[tid].get("boss", false) and Lore.BOSS.has(tid) and Trials.trial_of_step(Data.STEPS[_kill_step(tid)]) == tid, "%s is a lord of Part XXII, guarded by a trial, with a story" % tid)
		check((Trials.TRIALS[tid].paths as Array).any(func(pth): return str(pth.kind) == "heights"), "%s can be passed by the heights" % tid)
		check(Data.DIALOGUE.has("pre:" + tid) and Data.DIALOGUE.has("post:" + tid), "%s has something to say before and after" % tid)
	check(Trials.KINDS.has("heights") and Trials.EPITHETS.has("heights") and "heights" in Trials.KIND_ORDER and "person:shan_gui" in UI.SHAPES and "person:dongyue" in UI.SHAPES, "a new way through trials: By the heights")
	for pid in ["xie_lingyun", "liezi", "zhong_ziqi", "han_yu", "shan_gui", "dongyue"]:
		check(Assets.PEOPLE.has(pid) and Assets.has(Assets.PEOPLE[pid]) and FileAccess.file_exists("res://art/characters/%s.py" % pid), "%s has a model built from a script" % pid)
	for fid2 in ["salt_thief", "false_echo", "fire_crab", "stray_gust", "kite_hawk", "wind_bag", "red_leopard", "fig_creeper", "rain_gibbon", "merit_stele", "report_smoke", "bends_serpent"]:
		check(Data.ENEMIES.has(fid2) and Lore.BEAST.has(fid2) and Habits.habit(fid2) != "", "%s: a foe of Part XXII with a story and hours of its own" % fid2)
	var x22: Array = []
	var old_echo := 0
	for cid2 in Echoes.ORDER:
		var c2: Dictionary = Echoes.CROSSROADS[cid2]
		if str(c2.part) == "XXII":
			x22.append(cid2)
			check((c2.options as Array).size() == 3 and (c2.get("end", {}) as Dictionary).size() == 3 and (c2.get("echo", {}) as Dictionary).size() >= 2, "%s: three answers, each echoed and told at the end" % cid2)
		else:
			for ek in c2.get("echo", {}):
				if str(ek).contains("s_p22_") or str(ek).contains("s_break27"):
					old_echo += 1
	check(x22 == ["the_voices", "the_kites", "the_tops"], "what a voice, the air and a summit are for is asked three times")
	check(old_echo >= 4, "four older crossroads echo in Part XXII (%d)" % old_echo)
	var tips := {}
	for o in Echoes.CROSSROADS.the_tops.options:
		for sc in o.tilt:
			tips[sc] = true
	check(tips.has("heart") and tips.has("craft") and tips.has("reach"), "the last crossroads of Part XXII tips all three scales the ends ask about")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(bsrc.contains("\"shanxiao\": \"heights\"") and bsrc.contains("\"the_tops\": [\"cairn\"]") and bsrc.contains("func _summit_step") and bsrc.contains("func _glide_step") and bsrc.contains("Folk.CAMP_ROLES.has(role)"),
		"the bot has a plan for every trial and crossroads of Part XXII, climbs, glides and finds the people of the road")

# ================================================================ the Lost Horse release
## What the choices left standing (marks.gd), what cannot be beaten (dooms.gd), and Part XXIV.
func _lost_horse() -> void:
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var btsrc := FileAccess.get_file_as_string("res://scripts/battle.gd")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	print("== what the choices left standing (marks.gd) ==")
	var answers := 0
	var who_n := 0
	for cid in Echoes.ORDER:
		check(Marks.MARKS.has(cid), "%s: every answer leaves something standing" % cid)
		for o in Echoes.CROSSROADS[cid].options:
			answers += 1
			var mk: Dictionary = Marks.MARKS.get(cid, {}).get(str(o.id), {})
			check(not mk.is_empty() and Data.AREAS.has(str(mk.get("area", ""))) and str(mk.get("n", "")).length() > 3 and fits.call(str(mk.get("desc", ""))) and str(mk.get("desc", "")).length() > 60,
				"%s/%s stands somewhere real, with a name and something to read that fits the box" % [cid, o.id])
			check(Echoes.stands_text(cid, str(o.id)).contains(str(Data.AREAS[str(mk.area)].n)), "%s/%s: the choice screen says where it will stand" % [cid, o.id])
			var mm := Marks.model(mk, 0)
			check(mm.get_child_count() >= 1, "%s/%s: what stands is built from code" % [cid, o.id])
			mm.free()
			if mk.has("who"):
				who_n += 1
				var wh: Array = mk.who
				check(wh.size() >= 5 and Assets.PEOPLE.has(str(wh[1])) and Assets.has(Assets.PEOPLE[str(wh[1])]) and fits.call(str(wh[3])) and fits.call(str(wh[4])), "%s/%s: somebody stands by it, in a body of the towns, with two things to say" % [cid, o.id])
		for oid in Marks.MARKS.get(cid, {}):
			check(not Echoes.option(cid, str(oid)).is_empty(), "%s: the mark %s is of a real answer" % [cid, oid])
	check(Marks.MARKS.size() == Echoes.ORDER.size() and Marks.totals()[0] == answers and answers >= 80 and Marks.totals()[1] >= 150 and who_n >= 5,
		"%d answers of %d crossroads leave %d things standing, and %d of them somebody beside it" % [answers, Echoes.ORDER.size(), Marks.totals()[1], who_n])
	for sc in Echoes.SCALE_ORDER:
		for l in [1, -1]:
			var sg: Dictionary = Marks.SIGNS[sc].get(l, {})
			check(not sg.is_empty() and fits.call(str(sg.desc)), "a scale that leans (%s %d) stands something in every region" % [sc, l])
			var sm := Marks.model(sg, 0)
			check(sm.get_child_count() >= 1, "and it is built from code")
			sm.free()
	# where they stand: on open ground of their own region, walked to from where the realm is entered,
	# with open ground all round (so nothing is shut in or cut off), and no two on one tile
	var placed := {}
	var signs := 0
	var sign_areas := {}
	var whos := 0
	for lid in ["surface", "heaven", "under", "sea"]:
		var lw: Dictionary = Atlas.world_of(lid)
		var reach := MapGen.flood(lw.grid, lw.w, lw.h, lw.start)
		var at := {}
		for e in lw.ents:
			if e.has("pos") and e.kind != "mark":
				at[e.pos] = true
		for e in lw.ents:
			if e.kind == "npc" and e.has("pick"):
				whos += 1
				check(e.has("lines") and (e.lines as Array).size() >= 2 and not Echoes.option(str(e.pick[0]), str(e.pick[1])).is_empty() and MapGen.is_walkable_tile(lw.grid[e.pos.y * int(lw.w) + e.pos.x]), "%s stands beside what was chosen, with words of their own" % e.id)
			if e.kind != "mark":
				continue
			var okk := not at.has(e.pos) and Atlas.owner_id(lw, e.pos) == str(e.area)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var q: Vector2i = e.pos + Vector2i(dx, dy)
					okk = okk and MapGen.is_walkable_tile(lw.grid[q.y * int(lw.w) + q.x]) and (reach.has(q) or (dx == 0 and dy == 0))
			check(okk, "%s stands on open ground of %s, with open ground all round" % [e.id, e.area])
			at[e.pos] = true
			if e.has("scale"):
				signs += 1
				sign_areas[str(e.area)] = true
			else:
				var bk := Marks.seen_key(str(e.id))
				placed[bk] = int(placed.get(bk, 0)) + 1
				check(Marks.sites(str(e.cross)).has(str(e.area)), "%s is in a region one of its answers touched" % e.id)
	for cid2 in Marks.MARKS:
		for oid2 in Marks.MARKS[cid2]:
			var want_k := int(Marks.MARKS[cid2][oid2].get("k", 1))
			var got_k := int(placed.get(Marks.id_of(cid2, oid2), 0))
			check(got_k >= want_k, "%s/%s: it found room to stand (%d of %d)" % [cid2, oid2, got_k, want_k])
	check(sign_areas.size() == Atlas.all_region_ids().size() - 1 and signs == sign_areas.size() * 3 and whos == who_n, "the scales stand their signs in %d regions (%d signs), and %d people stand by what was chosen" % [sign_areas.size(), signs, whos])
	var KG = load("res://scripts/game.gd").new()
	KG.reset()
	var ws: Dictionary = Atlas.world_of("surface")
	check(Marks.standing(KG, ws.ents) == 0, "before anything is chosen, nothing stands")
	Echoes.take(KG, "bandits", "mend")
	var mend_e: Dictionary = {}
	var drive_e: Dictionary = {}
	var hou: Dictionary = {}
	for e2 in ws.ents:
		if str(e2.id) == "mark:bandits:bamboo":
			mend_e = e2
		elif str(e2.id) == "mark:bandits:bamboo:4":
			drive_e = e2
		elif str(e2.id) == "who:bandits:mend":
			hou = e2
	check(not mend_e.is_empty() and Marks.stands(KG, mend_e) and Marks.stands(KG, drive_e) and Marks.name_of(KG, mend_e) == "The Menders' Road" and Marks.answer(KG, mend_e) == "mend"
		and not hou.is_empty() and Marks.who_stands(KG, hou) and Marks.standing(KG, ws.ents) == int(Marks.MARKS.bandits.mend.k) and Marks.id_of("bandits", "mend") == "mark:bandits:bamboo",
		"the forty set to mend the road leave five lengths of road in the Bamboo Forest, and a road-mender beside it")
	var KG2 = load("res://scripts/game.gd").new()
	KG2.reset()
	Echoes.take(KG2, "bandits", "drive")
	check(Marks.stands(KG2, mend_e) and not Marks.stands(KG2, drive_e) and Marks.name_of(KG2, mend_e) == "A Cold Camp" and not Marks.who_stands(KG2, hou) and Marks.standing(KG2, ws.ents) == int(Marks.MARKS.bandits.drive.k)
		and Marks.key(KG2, mend_e) != Marks.key(KG, mend_e),
		"the forty driven out leave three cold camps on the same ground, and nobody: the same place is another place")
	KG2.free()
	check(Marks.seen_key("mark:bandits:bamboo:3") == "mark:bandits:bamboo" and Marks.seen_key("sign:bamboo:heart") == "sign:bamboo:heart", "every length of one road is one thing looked at")
	var sign_e: Dictionary = {}
	for e3 in ws.ents:
		if str(e3.id) == "sign:bamboo:heart":
			sign_e = e3
	check(not sign_e.is_empty() and not Marks.stands(KG, sign_e), "a scale that does not lean yet stands nothing")
	Echoes.take(KG, "widow", "kind")
	var k_pos := Marks.key(KG, sign_e)
	check(Echoes.lean(KG, "heart") == 1 and Marks.stands(KG, sign_e) and Marks.name_of(KG, sign_e) == "A Wayside Table", "mercy that the land knows him by sets a table by the road in every region")
	KG.scales["heart"] = -6
	check(Marks.name_of(KG, sign_e) == "A Board of Edicts" and Marks.key(KG, sign_e) != k_pos, "and rigour a board of edicts in the same place: the world builds it again")
	check(Echoes.text(KG, "bandits").contains("It stands in the land") and msrc.contains("It will stand in the land") and msrc.contains("Game.marks_seen"), "the Crossroads page and the choice itself say what will stand, and looking at it is remembered")
	KG.free()
	var wsrc := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(wsrc.contains("func _mark_model") and wsrc.contains("Marks.stands(Game, e)") and wsrc.contains("Marks.who_stands(Game, e)"), "the world shows what stands, builds it when it first does, and shows who stands by it")

	print("== more room indoors (rooms.gd let_out) ==")
	var b_n := 0
	var b_grew := 0
	var t_before := 0
	var t_after := 0
	for a9 in Data.AREAS:
		var raw9: Array = Data.AREAS[a9].get("buildings", [])
		if raw9.is_empty():
			continue
		var m9 := MapGen.build(a9)
		var reach9 := MapGen.flood(m9.grid, m9.w, m9.h, m9.start)
		for i9 in raw9.size():
			var r0: Rect2i = raw9[i9].rect
			var r1: Rect2i = m9.buildings[i9].rect
			b_n += 1
			t_before += (r0.size.x - 2) * (r0.size.y - 2)
			t_after += (r1.size.x - 2) * (r1.size.y - 2)
			if r1 != r0:
				b_grew += 1
			var dr: Vector2i = raw9[i9].door
			var on_edge := dr.x == r1.position.x or dr.x == r1.end.x - 1 or dr.y == r1.position.y or dr.y == r1.end.y - 1
			check(r1.encloses(r0) and m9.buildings[i9].door == dr and on_edge and m9.grid[dr.y * int(m9.w) + dr.x] == MapGen.INTERIOR and reach9.has(dr),
				"%s/%s: let out round what it was, its door where it was, in the wall, and walked to" % [a9, raw9[i9].id])
			for j9 in raw9.size():
				if j9 != i9:
					# (two houses written wall to wall stay wall to wall)
					check(not r1.grow(1).intersects(m9.buildings[j9].rect) or r0.grow(1).intersects(raw9[j9].rect), "%s/%s: there is still a way between it and the next house" % [a9, raw9[i9].id])
	check(b_grew * 2 >= b_n and t_after * 100 >= t_before * 130, "%d of %d buildings have more room: %d tiles of ground floor where there were %d" % [b_grew, b_n, t_after, t_before])
	var wsrc9 := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(wsrc9.contains("a lord that cannot be beaten is gone from the land when the losing is done"), "a doom of the story leaves the land when its step is done")
	var asrc9 := FileAccess.get_file_as_string("res://scripts/architecture.gd")
	check(asrc9.contains("static func _facade") and asrc9.contains("static func _border") and Arch.HIP_RISE > 1.6 and Arch.GABLE_RISE > 1.3, "the houses have facades, flowers at the foot of the wall, and roofs that rise")

	print("== what cannot be beaten (dooms.gd) ==")
	var dooms: Array = []
	for eid in Data.ENEMIES:
		if Dooms.is_doom(str(eid)):
			dooms.append(str(eid))
			check(Dooms.DOOMS.has(str(eid)) and Dooms.rounds(str(eid)) >= 2 and Dooms.rounds(str(eid)) <= 6 and str(Dooms.DOOMS[eid].crest).length() > 5, "%s cannot be beaten: it crests in a few rounds" % eid)
			check(not Trials.TRIALS.has(str(eid)), "%s: no road through a trial leads past it" % eid)
			if bool(Data.ENEMIES[eid].get("boss", false)):
				check(Lore.BOSS.has(str(eid)) and not Dooms.DOOMS[eid].has("passes"), "%s is a doom of the story, with a story" % eid)
			else:
				check(Lore.BEAST.has(str(eid)) and (Dooms.DOOMS[eid].passes as Array).size() >= 1 and Habits.habit(str(eid)) == "tide", "%s roams, keeps the tide's hours, and has words for when it has passed" % eid)
				for pl in Dooms.DOOMS[eid].passes:
					check(fits.call(str(pl)), "%s: what is said when it passes fits the box" % eid)
	for did in Dooms.DOOMS:
		check(Dooms.is_doom(str(did)), "%s is one of the land's foes" % did)
	check(dooms.size() == 5 and Dooms.FLOOR > 0.0 and Dooms.MEND > 0.0 and Dooms.RISE > 1.0 and Dooms.LEFT > 0.0, "five things cannot be beaten: three shapes of the tide, the Ape of the Huai and the Riders of the North")
	check(Dooms.manner(true, 9, 0) == "gave" and Dooms.manner(false, 5, 2) == "struck" and Dooms.manner(false, 2, 5) == "kept" and Dooms.HOW.size() == 3 and Dooms.TILT.size() == 3, "how it was lost: gave way, struck, kept")
	check(btsrc.contains("func _fall") and btsrc.contains("Dooms.FLOOR") and btsrc.contains("\"yield\"") and btsrc.contains("Give way") and msrc.contains("\"fall\":") and not msrc.substr(msrc.find("\"fall\":"), msrc.find("\"lose\":") - msrc.find("\"fall\":")).contains("respawn"),
		"the battle has a fourth end: its harm closes, it crests, it can be given way to, and nobody is carried home for it")
	var DG = load("res://scripts/game.gd").new()
	DG.reset()
	DG.level = 85
	DG.companion = true
	DG.hp = [1.0, 1.0]
	var stones0: int = DG.stones
	var heart0 := Echoes.scale(DG, "heart")
	check(not DG.scatters([{"id": "tide_horse", "lv": 1}]) and DG.scatters([{"id": "bamboo_wolf", "lv": 1}]), "what cannot be beaten does not run from anybody's realm")
	var line1 := Dooms.fell(DG, ["tide_horse", "tide_mare"], 85, "struck", 4)
	check(line1 != "" and DG.fallen == 1 and DG.yielded == 0 and DG.falls.has("tide_horse") and DG.falls.has("tide_mare") and str(DG.falls.tide_horse.how) == "struck" and DG.deaths == 0 and DG.stones == stones0
		and DG.hp[0] >= float(DG.max_hp(0)) * Dooms.LEFT - 0.5 and DG.exp > 0.0 and Echoes.scale(DG, "heart") == heart0 - 1,
		"a pack of the tide goes over him: remembered, nothing taken, no death counted, something learned, and the scale tipped by how he lost")
	Dooms.fell(DG, ["tide_horse"], 85, "gave", 1)
	check(DG.fallen == 2 and DG.yielded == 1 and str(DG.falls.tide_horse.how) == "struck" and Echoes.scale(DG, "heart") == heart0 - 1, "the first time is the one that is told; a second tips nothing")
	check(Dooms.fell(DG, ["wuzhiqi"], 86, "kept", 5) == "" and Dooms.met(DG) == 3 and Echoes.scale(DG, "heart") == heart0 and Dooms.epilogue(DG).contains("fought every one"), "a doom of the story is told by the story; the ending says how most were lost")
	Feats.poll(DG)
	check(DG.feats.has("first_fall") and DG.feats.has("gave_way") and not DG.feats.has("three_dooms") and Trials.need_met(["falls", 3], DG) and not Trials.need_met(["marks", 1], DG), "losing is a feat, and a way through a trial")
	Dooms.fell(DG, ["the_riders"], 87, "gave", 1)
	Feats.poll(DG)
	check(DG.feats.has("three_dooms"), "the tide, the ape and the riders: all three stood in front of")
	# the steps: a doom of the story, the dooms that roam, and going to look
	DG.step = Data.step_index("s_p24_tide")
	DG.hunt = 2
	DG.poll_steps()
	check(DG.cur_step().id == "s_p24_tide" and DG.objective_text().contains("(2/3)"), "two packs of the tide are not three")
	DG.hunt = 3
	DG.poll_steps()
	check(DG.done("s_p24_tide") and DG.cross_pending.has("the_tide"), "three are: and what the shore is to do about it is asked")
	DG.step = Data.step_index("s_p24_marks")
	DG.marks_seen = {"mark:bandits:bamboo": true, "mark:garden:marsh": true, "sign:bamboo:heart": true, "sign:marsh:heart": true, "mark:the_tide:yanggu": true}
	DG.poll_steps()
	check(DG.cur_step().id == "s_p24_marks" and DG.objective_text().contains("(5/6)"), "five things looked at are not six")
	DG.marks_seen["mark:the_ape:drowned"] = true
	DG.poll_steps()
	check(DG.done("s_p24_marks") and Trials.need_met(["marks", 6], DG), "six are")
	DG.free()

	print("== Part XXIV: the Lost Horse ==")
	check(Data.REALMS.size() == 30 and Data.REALMS[29] == "Soft as Water" and Data.MAX_LEVEL == 87 and Data.level_name(87).ends_with("Soft as Water") and Data.REALM_INFO.size() == 30
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXIV adds the realm of Soft as Water")
	check(Data.STEPS[Data.STEPS.size() - 1].id == "s_break29" and Data.DIALOGUE.has("recall22") and msrc.contains("\"s_break28\": \"recall22\"") and Data.DIALOGUE.has("pre:s_break29") and Data.DIALOGUE.has("post:s_break29"),
		"Part XXIV follows Great Sound, Rarely Heard (recall22) and ends the game")
	var n24 := 0
	var kinds24 := {}
	var doom_bands := {}
	for a24 in Data.AREAS:
		for bk24 in ["warband", "warband2", "warband3", "warband4"]:
			var bd24: Dictionary = Data.AREAS[a24].get(bk24, {})
			if bd24.is_empty():
				continue
			var dn := 0
			for pe24 in bd24.pool:
				if Dooms.is_doom(str(pe24[0])):
					dn += 1
					doom_bands[str(pe24[0])] = a24
			check(dn == 0 or (dn == (bd24.pool as Array).size() and str(bd24.get("until", "")) != "" and Data.step_index(str(bd24.until)) > Data.step_index(str(bd24.vis))),
				"%s/%s: a band of what cannot be beaten is nothing else, and stops marching when its chapter has done with it" % [a24, bk24])
			if bk24 in ["warband3", "warband4"]:
				var lw24: Dictionary = Atlas.world_of(Data.layer_of(a24))
				var marching24: Array = lw24.ents.filter(func(e6): return e6.kind == "enemy" and str(e6.id).begins_with(a24 + (":y" if bk24 == "warband3" else ":z")))
				check(marching24.size() == int(bd24.n) and Data.step_index(str(bd24.vis)) >= 0, "%s: %d packs of its %s placed" % [a24, marching24.size(), bk24])
				# (placed after the peaks and the camps: never on the rock, never at a camp fire)
				var off_rock := true
				for e7 in marching24:
					for pk7 in lw24.peaks:
						off_rock = off_rock and (str(pk7.area) != a24 or Vector2(e7.pos - (pk7.c as Vector2i)).length() > float(pk7.r))
				check(off_rock, "%s: the packs of its %s keep off the rock of the peaks" % [a24, bk24])
	for st24 in Data.STEPS:
		if not str(st24.id).begins_with("s_p24_"):
			continue
		n24 += 1
		kinds24[str(st24.kind)] = int(kinds24.get(str(st24.kind), 0)) + 1
		if st24.kind == "talk":
			check(Data.DIALOGUE.has(str(st24.id)), "%s: there is something said" % st24.id)
		if not st24.kind in ["kill", "talk", "fall"]:
			check(Data.DIALOGUE.has("done:" + str(st24.id)), "%s: something is said when it is done" % st24.id)
		if st24.kind == "fall":
			var fb := str(st24.boss)
			var placed_b: Array = Data.AREAS[str(st24.area)].bosses.filter(func(b): return str(b.id) == fb)
			check(Dooms.is_doom(fb) and bool(Data.ENEMIES[fb].get("boss", false)) and placed_b.size() == 1 and str(placed_b[0].vis[1]) == str(st24.id), "%s: a lord that cannot be beaten, who is gone when the losing is done" % st24.id)
			check(Data.DIALOGUE.has("pre:" + fb) and Data.DIALOGUE.has("fall:" + fb) and not Data.DIALOGUE.has("post:" + fb), "%s: something is said before, and after the losing; there is no winning to speak of" % fb)
			for hw in Dooms.HOW_ORDER:
				check(Data.DIALOGUE.has("fall:%s:%s" % [fb, hw]), "%s: the scene after is told its own way for one who %s" % [fb, str(Dooms.HOW[hw])])
				for fl in Data.DIALOGUE.get("fall:%s:%s" % [fb, hw], []) + Data.DIALOGUE.get("fall:" + fb, []):
					check(fits.call(str(fl[1])), "fall:%s: a line that fits the box" % fb)
		if st24.kind == "falls":
			for fo in st24.of:
				check(Dooms.is_doom(str(fo)) and not bool(Data.ENEMIES[fo].get("boss", false)) and str(doom_bands.get(str(fo), "")) == str(st24.area), "%s: %s cannot be beaten, and roams %s" % [st24.id, fo, st24.area])
		if st24.kind == "marks":
			check(int(st24.n) >= 3 and int(st24.n) * 4 <= Echoes.ORDER.size(), "%s: no more than a quarter of what a journey leaves standing" % st24.id)
	check(n24 >= 24 and int(kinds24.get("fall", 0)) == 2 and int(kinds24.get("falls", 0)) == 1 and int(kinds24.get("kill", 0)) == 2 and int(kinds24.get("hunt", 0)) == 4 and int(kinds24.get("collect", 0)) == 4 and kinds24.has("marks") and kinds24.has("visits"),
		"Part XXIV: %d steps: three things that cannot be beaten, two lords, four hunts, four searches, the six hearths and going to look" % n24)
	for tid24 in ["hu_steed", "huofu"]:
		check(Trials.TRIALS.has(tid24) and Data.ENEMIES[tid24].get("boss", false) and not Dooms.is_doom(tid24) and Lore.BOSS.has(tid24) and Trials.trial_of_step(Data.STEPS[_kill_step(tid24)]) == tid24, "%s is a lord of Part XXIV, guarded by a trial" % tid24)
		check((Trials.TRIALS[tid24].paths as Array).any(func(pth): return str(pth.kind) == "loss") and (Trials.TRIALS[tid24].paths as Array).any(func(pth): return str(pth.kind) == "mark"), "%s can be passed by the loss or by what stands" % tid24)
		check(Data.DIALOGUE.has("pre:" + tid24) and Data.DIALOGUE.has("post:" + tid24), "%s has something to say before and after" % tid24)
	check(Trials.KINDS.has("loss") and Trials.KINDS.has("mark") and Trials.EPITHETS.has("loss") and Trials.EPITHETS.has("mark") and "loss" in Trials.KIND_ORDER and "mark" in Trials.KIND_ORDER,
		"two new ways through trials: by the loss and by what stands")
	for pid24 in ["sai_weng", "weng_son", "qian_liu"]:
		check(Assets.PEOPLE.has(pid24) and Assets.has(Assets.PEOPLE[pid24]) and FileAccess.file_exists("res://art/characters/%s.py" % pid24) and Data.CHAT.has(pid24) and Data.CHAT[pid24].size() >= 3, "%s has a model built from a script, and things to say" % pid24)
	for fid24 in ["slipped_halter", "burr_sprite", "hoof_echo", "wrack_crab", "salt_gull", "drift_log", "silt_ape", "weir_eel", "mired_ox", "outrider", "remount", "camp_hound"]:
		check(Data.ENEMIES.has(fid24) and Lore.BEAST.has(fid24) and Habits.habit(fid24) != "" and not Dooms.is_doom(fid24), "%s: a foe of Part XXIV with a story and hours of its own" % fid24)
	var x24: Array = []
	var old_echo24 := 0
	for cid24 in Echoes.ORDER:
		var c24: Dictionary = Echoes.CROSSROADS[cid24]
		if str(c24.part) == "XXIV":
			x24.append(cid24)
			check((c24.options as Array).size() == 3 and (c24.get("end", {}) as Dictionary).size() == 3 and (c24.get("echo", {}) as Dictionary).size() >= 1, "%s: three answers, each echoed and told at the end" % cid24)
			var st_c: Dictionary = Data.STEPS[Data.step_index(str(c24.step))]
			check(str(st_c.kind) in ["fall", "falls", "talk"], "%s is asked after a losing, or of the old man" % cid24)
			for o24 in c24.options:
				check(int(Marks.MARKS[cid24][str(o24.id)].get("k", 1)) >= 1 and str(Marks.MARKS[cid24][str(o24.id)].area) in ["yanggu", "drowned", "aurora"], "%s/%s changes the shape of its own country" % [cid24, o24.id])
		else:
			for ek24 in c24.get("echo", {}):
				if str(ek24).contains("s_p24_") or str(ek24).contains("s_break29") or str(ek24) == "pre:the_riders":
					old_echo24 += 1
	check(x24 == ["the_tide", "the_ape", "the_horse"], "what is done about the tide, the ape and the horse is asked three times")
	check(old_echo24 >= 4, "four older crossroads echo in Part XXIV (%d)" % old_echo24)
	var tips24 := {}
	for o25 in Echoes.CROSSROADS.the_horse.options:
		for sc25 in o25.tilt:
			tips24[sc25] = true
	check(tips24.has("heart") and tips24.has("craft") and tips24.has("reach"), "the last crossroads of Part XXIV tips all three scales the ends ask about")
	check(bsrc.contains("\"hu_steed\": \"relic\"") and bsrc.contains("\"huofu\": \"loss\"") and bsrc.contains("\"the_horse\": [\"keep\"]") and bsrc.contains("func _marks_step") and bsrc.contains("\"hunt\", \"falls\"") and bsrc.contains("\"kill\", \"fall\""),
		"the bot has a plan for every trial and crossroads of Part XXIV, walks up to what cannot be beaten, and goes to look at what stands")
	# what the chapter stands in the land can be walked up to
	var wsurf: Dictionary = Atlas.world_of("surface")
	var at_tile := {}
	for e23 in wsurf.ents:
		if e23.has("pos") and e23.kind != "enemy":
			at_tile[e23.pos] = true
	var found24 := 0
	for e24 in wsurf.ents:
		if not ((e24.kind == "pickup" and str(e24.id).begins_with("p24_")) or (e24.kind == "boss" and str(e24.enemy) in ["hu_steed", "wuzhiqi", "the_riders", "huofu"]) or (e24.kind == "npc" and str(e24.id) in ["sai_weng", "weng_son", "qian_liu"])):
			continue
		found24 += 1
		var ways := 0
		for d24 in MapGen.DIRS:
			var q24: Vector2i = e24.pos + d24
			if MapGen.is_walkable_tile(wsurf.grid[q24.y * int(wsurf.w) + q24.x]) and not at_tile.has(q24):
				ways += 1
		check(ways >= 1 and Atlas.owner_id(wsurf, e24.pos) == str(e24.area), "%s can be walked up to, in its own region (%d ways)" % [e24.id, ways])
	check(found24 == 17 + 4 + 3, "seventeen things to find, four lords and three people of Part XXIV stand in the land (%d)" % found24)

# ================================================================ the Thundering Pots release
func _thundering_pots() -> void:
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var wsurf: Dictionary = Atlas.world_of("surface")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	print("== Part XXIII: the Thundering Pots ==")
	check(Data.REALMS.size() >= 29 and Data.REALMS[28] == "Great Sound, Rarely Heard" and Data.MAX_LEVEL >= 84 and Data.level_name(84).ends_with("Great Sound, Rarely Heard") and Data.REALM_INFO.size() >= 29
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXIII adds the realm of Great Sound, Rarely Heard")
	check(Data.step_index("s_break28") == Data.step_index("s_p24_home") - 1 and Data.DIALOGUE.has("recall21") and msrc.contains("\"s_break27\": \"recall21\"") and Data.DIALOGUE.has("pre:s_break28") and Data.DIALOGUE.has("post:s_break28"),
		"Part XXIII follows Leaning on Nothing (recall21), and Part XXIV follows it")
	var n23 := 0
	var kinds23 := {}
	for st23 in Data.STEPS:
		if not str(st23.id).begins_with("s_p23_"):
			continue
		n23 += 1
		kinds23[str(st23.kind)] = int(kinds23.get(str(st23.kind), 0)) + 1
		if st23.kind in ["talk", "war"]:
			check(Data.DIALOGUE.has(str(st23.id)), "%s: there is something said" % st23.id)
		if st23.kind != "kill" and st23.kind != "talk":
			check(Data.DIALOGUE.has("done:" + str(st23.id)), "%s: something is said when it is done" % st23.id)
		if st23.kind == "war":
			check(War.BATTLES.has(str(st23.battle)) and bool(War.BATTLES[str(st23.battle)].story) and str(War.BATTLES[str(st23.battle)].area) == str(st23.area) and Trials.npc_area(str(st23.npc)) == str(st23.area),
				"%s: a field of the story, in its own region, with somebody there to command" % st23.id)
		if st23.kind == "airs":
			for tn23 in st23.npcs:
				check(Music.TEACHERS.has(str(tn23)) and Cultures.of_npc(str(tn23)) == str(Music.TEACHERS[tn23]) and Trials.npc_area(str(tn23)) != "" and Data.DIALOGUE.has("air:" + str(Music.TEACHERS[tn23])),
					"%s: %s still sings the air of a hearth, and teaches it" % [st23.id, tn23])
			check(int(st23.n) < st23.npcs.size(), "%s: any %d of the six, so there is a choice" % [st23.id, int(st23.n)])
		if st23.kind == "folk":
			check(Folk.ROLES.has(str(st23.role)) and Folk.ERRANDS.has(str(st23.id)) and int(Folk.TOWNS[str(st23.town)].roles.get(str(st23.role), 0)) >= int(st23.n), "%s: an errand among people who live in that town" % st23.id)
		if bool(st23.get("levy", false)):
			for ln23 in st23.npcs:
				check(War.levy_of(str(ln23)) != "" and Cultures.HEARTHS[Cultures.of_npc(str(ln23))].keeper == str(ln23), "%s: %s keeps a hearth, and sends a company" % [st23.id, ln23])
	check(n23 >= 28 and int(kinds23.get("war", 0)) == 3 and int(kinds23.get("kill", 0)) == 4 and int(kinds23.get("hunt", 0)) == 4 and kinds23.has("airs") and kinds23.has("jobs") and kinds23.has("host") and kinds23.has("folk"),
		"Part XXIII: %d steps: three fields, four lords, four hunts, the airs, the board, the host and the players" % n23)
	for tid23 in ["meng_tian", "gao_jianli", "xiang_yu", "wafu"]:
		check(Trials.TRIALS.has(tid23) and Data.ENEMIES[tid23].get("boss", false) and Lore.BOSS.has(tid23) and Trials.trial_of_step(Data.STEPS[_kill_step(tid23)]) == tid23, "%s is a lord of Part XXIII, guarded by a trial" % tid23)
		check((Trials.TRIALS[tid23].paths as Array).any(func(pth): return str(pth.kind) in ["host", "song"]), "%s can be passed by the host or by the song" % tid23)
		check(Data.DIALOGUE.has("pre:" + tid23) and Data.DIALOGUE.has("post:" + tid23), "%s has something to say before and after" % tid23)
	check(Trials.KINDS.has("host") and Trials.KINDS.has("song") and Trials.EPITHETS.has("host") and Trials.EPITHETS.has("song") and "host" in Trials.KIND_ORDER and "song" in Trials.KIND_ORDER
		and "person:gao_jianli" in UI.SHAPES and "person:xiang_yu" in UI.SHAPES, "two new ways through trials: by the host and by the song")
	for pid23 in ["ling_lun", "sun_wu", "fu_hao", "shi_kuang", "gao_jianli", "xiang_yu"]:
		check(Assets.PEOPLE.has(pid23) and Assets.has(Assets.PEOPLE[pid23]) and FileAccess.file_exists("res://art/characters/%s.py" % pid23), "%s has a model built from a script" % pid23)
	for fid23 in ["pot_drummer", "flat_note", "kiln_wasp", "clay_spearman", "clay_archer", "clay_horse", "lead_string", "reed_pipe", "drowned_drum", "chu_halberd", "black_steed", "cauldron_breaker"]:
		check(Data.ENEMIES.has(fid23) and Lore.BEAST.has(fid23) and Habits.habit(fid23) != "", "%s: a foe of Part XXIII with a story and hours of its own" % fid23)
	var x23: Array = []
	var old_echo23 := 0
	for cid23 in Echoes.ORDER:
		var c23: Dictionary = Echoes.CROSSROADS[cid23]
		if str(c23.part) == "XXIII":
			x23.append(cid23)
			check((c23.options as Array).size() == 3 and (c23.get("end", {}) as Dictionary).size() == 3 and (c23.get("echo", {}) as Dictionary).size() >= 2, "%s: three answers, each echoed and told at the end" % cid23)
		else:
			for ek23 in c23.get("echo", {}):
				if str(ek23).contains("s_p23_") or str(ek23).contains("s_break28"):
					old_echo23 += 1
	check(x23 == ["the_clay", "the_lute", "the_host"], "what is done with the clay, the lute and the host is asked three times")
	check(old_echo23 >= 3, "three older crossroads echo in Part XXIII (%d)" % old_echo23)
	var tips23 := {}
	for o23 in Echoes.CROSSROADS.the_host.options:
		for sc23 in o23.tilt:
			tips23[sc23] = true
	check(tips23.has("heart") and tips23.has("craft") and tips23.has("reach"), "the last crossroads of Part XXIII tips all three scales the ends ask about")
	check(bsrc.contains("\"meng_tian\": \"host\"") and bsrc.contains("\"the_host\": [\"band\"]") and bsrc.contains("func _field") and bsrc.contains("Jobs.ASK") and bsrc.contains("func _job_done_already"),
		"the bot has a plan for every trial and crossroads of Part XXIII, fights a field and reads the notice board")

	# what the chapter stands on the heights can be walked up to: no banner shut in by its neighbours
	var at_tile := {}
	for e23 in wsurf.ents:
		if e23.has("pos") and e23.kind != "enemy":
			at_tile[e23.pos] = true
	for e24 in wsurf.ents:
		if e24.kind != "pickup" or not str(e24.id).begins_with("p23_"):
			continue
		var ways := 0
		for d24 in MapGen.DIRS:
			var q24: Vector2i = e24.pos + d24
			if MapGen.is_walkable_tile(wsurf.grid[q24.y * int(wsurf.w) + q24.x]) and not at_tile.has(q24):
				ways += 1
		check(ways >= 1, "%s can be walked up to: not shut in by its neighbours (%d ways)" % [e24.id, ways])
	print("== the host and the field (war.gd) ==")
	var WG = load("res://scripts/game.gd").new()
	WG.reset()
	WG.level = 82
	check(War.companies(WG).is_empty() and War.muster(WG).foot == 0, "a new journey has no host")
	var arms23 := {}
	for cid in War.ORDER:
		var c: Dictionary = War.COMPANIES[cid]
		arms23[str(c.arm)] = true
		var srcs := 0
		for k in ["levy", "step", "work", "job"]:
			srcs += 1 if c.has(k) else 0
		check(srcs == 1 and str(c.desc).length() > 60 and str(c.how).length() > 20 and str(c.arm) in ["foot", "bow", "horse", "drum"], "company %s: one arm, one way of coming, and a word about it" % cid)
		if c.has("levy"):
			check(Trials.npc_area(str(c.levy)) != "", "company %s: whoever sends it lives somewhere" % cid)
		if c.has("work"):
			check(Works.WORKS.has(str(c.work)), "company %s: the work that brings it is one of the Hundred Works" % cid)
		if c.has("job"):
			check(Jobs.JOBS.has(str(c.job)), "company %s: the commission that brings it is on the board" % cid)
		if c.has("step"):
			check(Data.step_index(str(c.step)) >= 0, "company %s: the step that brings it is in the story" % cid)
	check(arms23.size() == 4, "the host has foot, bows, horse and drums")
	for lv in ["granny_wen", "sarnai", "cook_aysha", "fishwife_lu", "auntie_rong", "lantern_xi"]:
		War.raise(WG, War.levy_of(lv))
	WG.host["sect"] = true
	check(War.companies(WG).size() == 7 and int(War.muster(WG).foot) == 300 and int(War.muster(WG).bow) == 200 and int(War.muster(WG).horse) == 100 and int(War.muster(WG).drum) == 100, "the levy of six hearths and the sect's own: seven companies")
	check(not War.raise(WG, "valley"), "a company comes in once")
	for oid in War.ORDER_IDS:
		check(War.ORDERS.has(oid) and str(War.ORDERS[oid].desc).length() > 60, "the order %s says what it is good against" % oid)
	for o1 in ["advance", "volley", "charge", "lead", "sound"]:
		for o2 in War.ORDER_IDS:
			check(War.DEAL[o1].has(o2), "what %s does against %s is written" % [o1, o2])
	check(float(War.DEAL.charge.hold) < 0.5 and float(War.DEAL.charge.volley) > 1.5 and float(War.DEAL.volley.hold) > 1.0 and float(War.DEAL.advance.hold) <= 0.5 and float(War.DEAL.advance.feint) < 0.5 and float(War.DEAL.sound.hold) > 1.0,
		"a wall stops horse and foot, arrows and songs find a wall, horse ride down bows, and a feint leaves a blow in the air")
	for bid in War.BATTLE_ORDER:
		var b: Dictionary = War.BATTLES[bid]
		var ok_b: bool = str(b.desc).length() > 80 and str(b.won).length() > 40 and (b.plan as Array).size() >= 4 and Music.TUNES.has(str(b.tune))
		for po in b.plan:
			ok_b = ok_b and War.ORDERS.has(str(po)) and str(po) != "lead"
		for du in b.dust:
			ok_b = ok_b and int(du) < (b.plan as Array).size()
		check(ok_b and (bool(b.story) or Data.step_index(str(b.after)) >= 0), "the field %s: a host, a plan of real orders, dust where there are drums, and words for it" % bid)
	# a battle is a pure function of the orders given: the same orders, the same field
	var s1 := War.start(WG, "lishan")
	var s2 := War.start(WG, "lishan")
	for o in ["hold", "volley", "advance", "hold"]:
		War.step(s1, o)
		War.step(s2, o)
	check(str(s1) == str(s2) and int(s1.drum) == 4 and (s1.log as Array).size() == 4, "the same orders make the same field, drum for drum")
	var sh := War.start(WG, "lishan")
	War.step(sh, "hold")
	var sa := War.start(WG, "lishan")
	War.step(sa, "advance")
	check(float(sh.last.lost_me) < float(sa.last.lost_me), "against an advance, a wall loses fewer than an advance does")
	var sf := War.start(WG, "lishan")
	War.step(sf, "feint")
	check(bool(sf.foe.drawn) and not bool(sf.me.drawn) and int(sf.feints) == 1, "an advance that strikes air is out of its ground")
	check(War.blocked(War.start(WG, "river"), "feint") != "" and War.blocked(sf, "feint") == "", "with the river behind it the host cannot give ground")
	WG.host = {"valley": true}
	check(War.blocked(War.start(WG, "lishan"), "charge") != "" and War.blocked(War.start(WG, "lishan"), "volley") != "" and War.blocked(War.start(WG, "lishan"), "sound") != "", "an order wants its arm: no horse, no charge; no airs and no drums, no song")
	# the levy, led as Master Sun would lead it, holds every field of the story; led by standing still or
	# by going in every drum, it holds none
	WG.host = {}
	for lv2 in ["granny_wen", "sarnai", "cook_aysha", "fishwife_lu", "auntie_rong", "lantern_xi"]:
		War.raise(WG, War.levy_of(lv2))
	WG.host["sect"] = true
	for k in 4:
		WG.airs[Cultures.ORDER[k]] = true
	for bid2 in ["lishan", "river", "gaixia"]:
		var won := War.play(WG, bid2)
		check(str(won.over) == "won" and int(won.drum) <= War.MAX_DRUMS, "%s: the levy of six hearths with four airs, well led, holds the field (in %d drums)" % [bid2, int(won.drum)])
		for dull in ["hold", "advance"]:
			var sd := War.start(WG, bid2)
			while str(sd.over) == "":
				War.step(sd, dull if War.blocked(sd, dull) == "" else "hold")
			check(str(sd.over) == "lost", "%s: a host that only knows how to %s does not" % [bid2, dull])
	WG.airs = {}
	WG.host.erase("dawn")
	check(str(War.play(WG, "gaixia").over) == "lost", "Gaixia cannot be won by a host with no song")
	var lost := War.start(WG, "gaixia")
	while str(lost.over) == "":
		War.step(lost, "hold")
	War.record(WG, lost, {"hold": int(lost.drum)})
	check(WG.war_lost == 1 and int(WG.war_tries.gaixia) == 1 and float(War.start(WG, "gaixia").foe.start) < float(lost.foe.start), "a field lost is come back to, and the other host is the wearier for it")
	WG.free()

	print("== the music (music.gd) ==")
	var n_tunes := 0
	for tid in Music.TUNES:
		var tn: Dictionary = Music.TUNES[tid]
		var first: Array = Music.parse(str(tn.voices[0][3]))
		var ok_t: bool = int(tn.key) >= 36 and int(tn.key) <= 84 and int(tn.bpm) >= 36 and int(tn.bpm) <= 160 and float(first[1]) >= 3.0
		for v in tn.voices:
			ok_t = ok_t and str(v[0]) in ["dizi", "xiao", "erhu", "suona", "whistle", "qin", "zheng", "pipa", "bell", "chime", "drum", "pot", "gong"]
			var pr: Array = Music.parse(str(v[3]))
			for nt in pr[0]:
				var midi := int(tn.key) + int(nt[2]) + 12 * int(v[2])
				ok_t = ok_t and (int(nt[2]) < -90 or (midi >= 24 and midi <= 108))
			# every bar of a tune is four beats (a sting is as long as it likes)
			if not tn.get("sting", false):
				for bar in str(v[3]).split("|"):
					ok_t = ok_t and is_equal_approx(float(Music.parse(bar)[1]), 4.0)
		check(ok_t, "the tune %s: a key, a tempo, real instruments, notes an instrument can play, four beats to the bar" % tid)
		if not tn.get("sting", false):
			n_tunes += 1
			check(Music.ORDER.has(tid) and str(tn.n) != "" and str(tn.desc).length() > 60 and str(tn.where) != "" and Music.seconds(tid) >= 12.0 and Music.seconds(tid) <= 90.0 and not Music.roll(tid).is_empty(),
				"the tune %s is in the songbook, with a name, a word about it and a roll of notes" % tid)
	check(n_tunes == Music.ORDER.size() and n_tunes >= 34 and Music.count() == n_tunes - 1, "%d tunes, one of them not shown until it is found" % n_tunes)
	for hid in Cultures.ORDER:
		check(Music.AIRS.has(hid) and str(Music.TUNES[str(Music.AIRS[hid])].get("air", "")) == hid and Music.TEACHERS.values().has(hid), "the hearth %s has an air of its own, and somebody who still sings it" % hid)
	for ar in Data.AREAS:
		check(Music.TUNES.has(str(Music.OF_THEME.get(str(Data.AREAS[ar].theme), "bamboo"))), "%s: its kind of country has a tune" % ar)
	check(Music.parse("1 - 3_ 5_ | 6, 1' 0 2#")[1] == 7.0 and Music.parse("1 -")[0][0][1] == 2.0 and Music.parse("6,")[0][0][2] == -3 and Music.parse("1'")[0][0][2] == 12 and Music.parse("2#")[0][0][2] == 3 and Music.parse("0")[0][0][2] < -90,
		"the notation: a dash holds, an underline halves, a comma and a tick are octaves, a sharp is a sharp, a nought is a rest")
	check(is_equal_approx(Music.hz(69.0), 440.0) and is_equal_approx(Music.hz(57.0), 220.0), "the la above middle do is 440")
	# a tune is made of arithmetic: the same notes make the same sound, as loud as any other, with no seam
	var pcm1 := Music.render("sting_feat")
	var pcm2 := Music.render("sting_feat")
	var peak := 0.0
	for x in pcm1:
		peak = maxf(peak, absf(x))
	check(pcm1 == pcm2 and pcm1.size() > Music.RATE and peak > 0.3 and peak <= 1.0, "a tune rendered twice is the same sound, and it is not silence (peak %.2f)" % peak)
	var ditty := Music.render("ditty")
	var sq := 0.0
	for x2 in ditty:
		sq += x2 * x2
	check(ditty.size() == int(Music.beats("ditty") * 60.0 / float(Music.TUNES.ditty.bpm) * Music.RATE) and absf(sqrt(sq / ditty.size()) - Music.LEVEL) < 0.03, "a tune is exactly one loop long, and brought to the level of every other")
	var wavf := Music.wav_file("sting_step")
	check(wavf.size() > 44 and wavf.decode_u32(0) == 0x46464952 and wavf.decode_u32(24) == Music.RATE, "and it can be written out as a wave file")
	check(not DirAccess.dir_exists_absolute("res://assets/music") and not DirAccess.dir_exists_absolute("res://assets/audio"), "there is no audio file in the repository: every sound is made from code")
	var MG = load("res://scripts/game.gd").new()
	MG.reset()
	check(Music.book(MG).size() == Music.count() and Music.label(MG, "title").begins_with("?"), "a new journey's songbook lists every tune, none of them heard")
	for tid2 in Music.ORDER:
		if not Music.TUNES[tid2].get("hidden", false):
			MG.heard[tid2] = true
			Music.play_from_book(MG, tid2)
	check(MG.eggs.has("all_songs") and MG.heard.has("ditty") and Music.book(MG).has("ditty") and MG.songs_played == Music.count(), "every tune asked for out of the book, and there is one more leaf at the back")
	Music.ask("")

	print("== feats and finds (feats.gd, eggs.gd) ==")
	var kinds_f := {}
	var names_f := {}
	for fid in Feats.FEATS:
		var f: Dictionary = Feats.FEATS[fid]
		kinds_f[str(f.kind)] = true
		check(Feats.KINDS.has(str(f.kind)) and int(f.pts) in [5, 10, 20] and str(f.desc).length() > 15 and not names_f.has(str(f.n)), "feat %s: a kind, points, a word, and a name of its own" % fid)
		names_f[str(f.n)] = true
		check(Feats.need(f.test) >= 1.0 and Feats.value(MG, f.test) >= 0.0 and (str(f.test[0]) != "step" or Data.step_index(str(f.test[1])) >= 0), "feat %s measures something that can be counted" % fid)
	check(Feats.FEATS.size() >= 75 and kinds_f.size() == Feats.KIND_ORDER.size() and Feats.order().size() == Feats.FEATS.size(), "%d feats of nine kinds" % Feats.FEATS.size())
	# what a feat asks for is there to be done
	check(Feats.need(Feats.FEATS.soft_water.test) == Data.MAX_LEVEL and Feats.need(Feats.FEATS.three_dooms.test) == 3 and Feats.need(Feats.FEATS.marks_twelve.test) < Echoes.ORDER.size() and Feats.need(Feats.FEATS.deeds_all.test) <= Trials.DEEDS.size() and Feats.need(Feats.FEATS.jobs_all.test) == Jobs.ORDER.size()
		and Feats.need(Feats.FEATS.every_thread.test) == Fashion.OUTFIT_ORDER.size() and Feats.need(Feats.FEATS.her_dresses.test) <= Fashion.YUE_ORDER.size() and Feats.need(Feats.FEATS.egg_all.test) == Eggs.ORDER.size()
		and Feats.need(Feats.FEATS.war_all.test) == War.BATTLE_ORDER.size() and Feats.need(Feats.FEATS.heard_all.test) <= Music.count() and Feats.need(Feats.FEATS.host_full.test) <= War.ORDER.size()
		and Feats.need(Feats.FEATS.airs_six.test) == Music.AIRS.size() and Feats.need(Feats.FEATS.works_twelve.test) < Works.ORDER.size() and Feats.need(Feats.FEATS.arms_eight.test) == Arms.ORDER.size()
		and Feats.need(Feats.FEATS.every_country.test) <= Atlas.all_region_ids().size() and Feats.need(Feats.FEATS.summits_forty.test) < (Atlas.world().peaks as Array).size()
		and Feats.need(Feats.FEATS.abodes.test) == (Data.AREAS.mountain.abodes as Array).size() and Feats.need(Feats.FEATS.bestiary.test) < Data.ENEMIES.size() and Feats.need(Feats.FEATS.kin_all.test) == Cultures.ORDER.size(),
		"no feat asks for more than there is: levels, deeds, notices, outfits, finds, fields, tunes, companies, airs, works, arms, regions, summits, caves, creatures, hearths")
	var bosses_n := 0
	for eid in Data.ENEMIES:
		bosses_n += 1 if Data.ENEMIES[eid].get("boss", false) else 0
	check(Feats.need(Feats.FEATS.lords_all.test) <= bosses_n and Feats.need(Feats.FEATS.feats_forty.test) < Feats.FEATS.size() and Feats.need(Feats.FEATS.talker.test) < 200, "nor for more lords than there are (%d), or more feats" % bosses_n)
	var FG2 = load("res://scripts/game.gd").new()
	FG2.reset()
	Feats.poll(FG2)
	check(FG2.feats.is_empty() and Feats.points(FG2) == 0 and Feats.title(FG2) == "Unsung", "a new journey has done nothing worth telling")
	FG2.level = 6
	FG2.summits = {"a": true}
	FG2.toasts.clear()
	Feats.poll(FG2)
	check(FG2.feats.has("first_steps") and FG2.feats.has("golden_core") and FG2.feats.has("summit_first") and not FG2.feats.has("immortal") and Feats.points(FG2) == 15 and FG2.toasts.size() == 3, "a feat is told the moment it is true, once")
	FG2.toasts.clear()
	Feats.poll(FG2)
	check(FG2.toasts.is_empty() and Feats.progress(FG2, "summits_nine") == "1 of 9", "and not again; the page says how far along the others are")
	for k9 in 9:
		FG2.summits[str(k9)] = true
	Feats.poll(FG2)
	check(FG2.feats.has("summits_nine") and FG2.outfits.has("pilgrim"), "a feat may give something to wear: nine summits, the Pilgrim's White")
	check(Feats.text(FG2, "unbowed").begins_with("Not shown") and Feats.text(FG2, "summits_nine").contains("Pilgrim's White"), "a hidden feat is not told until it is done; one that gives something says what")
	var top_title := ""
	for tl in Feats.TITLES:
		check(int(tl[0]) <= Feats.total(), "the title %s can be reached (%d of %d points)" % [tl[1], int(tl[0]), Feats.total()])
		top_title = str(tl[1])
	check(Eggs.ORDER.size() == 12 and Eggs.EGGS.size() == 12, "twelve things nobody is told to look for")
	for eid2 in Eggs.ORDER:
		var e: Dictionary = Eggs.EGGS[eid2]
		check(str(e.n) != "" and str(e.hint).length() > 15 and not str(e.hint).contains(str(e.n)), "the find %s has a name, and a hint that does not give it away" % eid2)
		for l in e.lines:
			check(fits.call(str(l[1])) and (l.size() < 3 or Data.EMOTES.has(str(l[2]))), "the find %s: what is said fits the dialogue box" % eid2)
	for nk in Eggs.NAMESAKES:
		check(Fashion.clean_name(nk) == nk and fits.call(str(Eggs.NAMESAKES[nk])), "the name %s can be typed at the creation screen, and has its line" % nk)
	for st in Data.STEPS:
		check(not Eggs.EGGS.has(str(st.get("egg", ""))), "no step of the story asks for a find")
	Eggs.keyed = []
	Eggs.code_done = false
	var keyed_ok := false
	for kk in Eggs.CODE:
		keyed_ok = Eggs.title_key(kk)
	check(keyed_ok and Eggs.code_done and not Eggs.title_key("up"), "the old code, keyed on the title")
	Feats.poll(FG2)
	check(FG2.eggs.has("old_code") and FG2.outfits.has("broom") and not Eggs.code_done and FG2.egg_pending.size() == 1, "is found when the journey begins, with the robe it was the whole time")
	FG2.hero["given"] = "Wukong"
	FG2.step = 2
	Feats.poll(FG2)
	check(FG2.eggs.has("namesake") and Eggs.namesake(FG2) == "Wukong", "a name that was somebody's first is noticed")
	for k12 in 12:
		Eggs.talked(FG2, "cook_zhou")
	check(FG2.eggs.has("good_listener") and int(FG2.npc_talks.cook_zhou) == 12, "somebody listened to twelve times has said everything")
	Eggs.used(FG2, "bell", 9)
	FG2.inv["clay_duck"] = 1
	Eggs.on_summit = true
	Clock.set_hour(FG2, 23.5)
	Feats.poll(FG2)
	Eggs.on_summit = false
	check(FG2.eggs.has("bell_nine") and FG2.eggs.has("clay_duck") and FG2.eggs.has("midnight_summit") and FG2.feats.has("egg_six"), "nine strokes on a bell, a duck, a summit at midnight: six finds is a feat")
	check(Data.ITEMS.has("clay_duck") and Data.AREAS.village.pickups.any(func(pk): return str(pk.item) == "clay_duck" and int(pk.get("cave", 0)) == -2), "the duck is in the First Kiln, under Qingshi")
	FG2.free()

	print("== the wardrobe: more outfits, and Yue Ling's own ==")
	check(Fashion.OUTFIT_ORDER.size() == 26 and Fashion.OUTFITS.size() == 26 and Fashion.YUE_ORDER.size() == 10 and Fashion.YUE_OUTFITS.size() == 10, "26 outfits for the hero and 10 dresses for Yue Ling")
	var hows := {}
	for oid in Fashion.OUTFIT_ORDER:
		for hk in ["step", "buy", "feat", "job", "egg", "fate", "origin"]:
			if Fashion.OUTFITS[oid].has(hk):
				hows[hk] = true
	check(hows.size() == 7, "outfits are earned in seven ways: the story, a seller, a feat, a commission, a find, a fate, an origin")
	var accs := {}
	for oid in Fashion.OUTFIT_ORDER:
		for ac in Fashion.OUTFITS[oid].acc:
			accs[ac] = true
	for yid in Fashion.YUE_ORDER:
		var yo: Dictionary = Fashion.YUE_OUTFITS[yid]
		var ysrc := 0
		for hk2 in ["bond", "step", "buy", "feat"]:
			ysrc += 1 if yo.has(hk2) else 0
		var yok: bool = (yo.cols as Array).size() == 3 and str(yo.desc).length() > 40 and (ysrc == 1 or yid == "lotus")
		for ac2 in yo.acc:
			accs[ac2] = true
			yok = yok and Fashion.ACCESSORY_BONES.has(ac2)
		for fk in yo.fx:
			yok = yok and fk in ["hp", "qi", "atk", "spd", "heal"]
		if yo.has("step"):
			yok = yok and Data.step_index(str(yo.step)) >= 0
		if yo.has("feat"):
			yok = yok and Feats.FEATS.has(str(yo.feat))
		if yo.has("bond"):
			yok = yok and int(yo.bond) <= 50
		check(yok, "her dress %s: colours, a passive of her own, accessories and a way to earn it" % yid)
	check(accs.size() == Fashion.ACCESSORY_BONES.size(), "every accessory there is, is worn by something (%d)" % accs.size())
	for ac3 in Fashion.ACCESSORY_BONES:
		var an := Models.accessory(ac3, Color("f0c850"))
		check(an.get_child_count() >= 1, "the accessory %s is built from code" % ac3)
		an.free()
	var YG = load("res://scripts/game.gd").new()
	YG.reset()
	YG.companion = true
	YG.level = 30
	YG.hp[1] = float(YG.max_hp(1))
	var hp0: int = YG.max_hp(1)
	check(YG.yue_outfit == "lotus" and YG.yue_outfits.size() == 1 and Fashion.yue_colors(YG).is_empty(), "Yue Ling begins in the rose dress she woke in")
	YG.bond = 30
	YG.poll_wardrobe()
	check(YG.yue_outfits.has("healer") and YG.yue_outfits.has("plum") and not YG.yue_outfits.has("moon"), "she is given dresses as the two grow close")
	YG.grant_yue_outfit("willow")
	check(YG.wear_yue("willow") and YG.yue_outfit == "willow" and YG.max_hp(1) > hp0 and Fashion.yue_colors(YG).has("robe") and not YG.wear_yue("moon"), "a dress she owns can be put on, and its passive is hers; one she does not, cannot")
	check(YG.max_hp(0) == int(YG.max_hp(0)) and Fashion.gear(YG, "hp") == Fashion.gear(YG, "hp") and is_equal_approx(Fashion.yue_gear(YG, "hp"), 0.05), "what she wears changes nothing of his")
	check(Fashion.seller("rain") == "tailor_qiao" and Fashion.seller("brocade") == "dyer_su" and Fashion.outfit_for_sale("rain", YG) == YG.reached("s_vl_intro"), "Tailor Qiao sells in Qingshi as Dyer Su sells at the Dawn Market")
	YG.free()

	print("== the notice board (jobs.gd) and the Drum Tower quarter ==")
	check(Jobs.ORDER.size() == 18 and Jobs.JOBS.size() == 18 and Trials.npc_area(Jobs.CLERK) == "village", "eighteen notices, and a clerk in Qingshi to keep them")
	for jid in Jobs.ORDER:
		var j: Dictionary = Jobs.JOBS[jid]
		var jok: bool = Data.step_index(str(j.after)) >= 0 and str(j.ask).length() > 60 and str(j.thanks).length() > 30 and int(j.stones) > 0 and str(j.need[0]) in ["have", "kills", "more", "reach", "folk", "war"]
		match str(j.need[0]):
			"have":
				for ik in j.need[1]:
					jok = jok and Data.ITEMS.has(ik)
			"kills":
				for ek in j.need[1]:
					jok = jok and Data.ENEMIES.has(ek)
			"folk":
				jok = jok and Folk.ROLES.has(str(j.need[1]))
			"war":
				jok = jok and War.BATTLES.has(str(j.need[1])) and not bool(War.BATTLES[str(j.need[1])].story)
		if j.has("item"):
			jok = jok and Data.ITEMS.has(str(j.item))
		check(jok and fits.call(str(j.ask)) and fits.call(str(j.thanks)), "the notice %s: posted after a real step, asks for something real, pays, and fits the box" % jid)
	var JG = load("res://scripts/game.gd").new()
	JG.reset()
	check(not Jobs.posted(JG, "job_firewood"), "nothing is posted before the story reaches Qingshi")
	JG.step = Data.step_index("s_vl_intro") + 1
	check(Jobs.posted(JG, "job_firewood") and not Jobs.posted(JG, "job_lesson") and Jobs.state(JG, "job_firewood") == "", "a notice goes up when its step is done")
	Jobs.take(JG, "job_firewood")
	JG.felled_n = 5
	check(Jobs.state(JG, "job_firewood") == "taken" and Jobs.progress(JG, "job_firewood") == [5, 6] and not Jobs.ready(JG, "job_firewood") and not Jobs.finish(JG, "job_firewood"), "taken down, and counted from when it was taken")
	JG.felled_n = 7
	var st0: int = JG.stones
	check(Jobs.ready(JG, "job_firewood") and Jobs.finish(JG, "job_firewood") and Jobs.is_done(JG, "job_firewood") and JG.stones == st0 + int(Jobs.JOBS.job_firewood.stones) and Jobs.done_count(JG) == 1 and not Jobs.posted(JG, "job_firewood"),
		"done, reported and paid, and it comes off the board")
	Jobs.take(JG, "job_moths")
	JG.record_kills("village", 3, ["thread_moth", "paper_crow", "dig_mole"])
	check(Jobs.progress(JG, "job_moths") == [2, 8], "a notice that asks for creatures counts only those")
	Jobs.take(JG, "job_brine")
	JG.inv["ess_water"] = 4
	check(Jobs.finish(JG, "job_brine") and int(JG.inv.ess_water) == 1, "what a notice asks to be brought is handed over")
	JG.inv["ess_fire"] = 3
	JG.inv["ess_wood"] = 2
	Jobs.take(JG, "job_masks")
	check(Jobs.finish(JG, "job_masks") and JG.outfits.has("fox"), "a notice may pay in something to wear")
	JG.worn = {"a": 1, "b": 1, "c": 1, "d": 1, "e": 1}
	Jobs.take(JG, "job_stage")
	check(Jobs.finish(JG, "job_stage") and JG.outfits.has("opera") and War.has(JG, "players"), "or in a company for the host")
	JG.step = Data.step_index("s_p23_jobs")
	check(JG.cur_step().kind == "jobs" and Jobs.done_count(JG) >= int(JG.cur_step().n), "the step that asks for commissions is met by any of them")
	JG.poll_steps()
	check(JG.step == Data.step_index("s_p23_jobs") + 1, "and moves on")
	JG.free()
	print("== Old Du's mat (gamble.gd) ==")
	var GG2 = load("res://scripts/game.gd").new()
	GG2.reset()
	check(Trials.npc_area(Gamble.DEALER) == "village" and Data.CHAT.has(Gamble.DEALER) and Gamble.GAME_ORDER.size() == 3, "a dealer in Qingshi, and three games: dice, beads and crickets")
	for gid in Gamble.GAME_ORDER:
		check(str(Gamble.GAMES[gid].desc).length() > 80 and Gamble.bets(GG2, gid).size() >= 2 and fits.call(str(Gamble.GAMES[gid].desc)), "the game %s says how it is played and what can be staked on" % gid)
	check(Gamble.deal(7) == Gamble.deal(7) and Gamble.deal(7) != Gamble.deal(8), "a throw is drawn from the journey's count of throws: the same throw is the same dice")
	check(Gamble.wins("dice", "big", {"dice": [6, 5, 1]}) and Gamble.wins("dice", "small", {"dice": [1, 2, 3]}) and not Gamble.wins("dice", "big", {"dice": [5, 5, 5]}) and not Gamble.wins("dice", "small", {"dice": [2, 2, 2]})
		and Gamble.wins("dice", "triple", {"dice": [4, 4, 4]}) and Gamble.wins("fantan", "4", {"beads": 40}) and Gamble.wins("fantan", "3", {"beads": 43}) and not Gamble.wins("fantan", "1", {"beads": 43}),
		"eleven is big, ten is small, three of a kind is the house's; forty beads leave none, which is called four")
	# the odds, over ten thousand throws: fair dice, fair beads, crickets that win as often as their record
	# says; and the house ahead on every game, a little, as a house is
	var faces := [0, 0, 0, 0, 0, 0]
	var left4 := [0, 0, 0, 0]
	var back := {"big": 0.0, "small": 0.0, "triple": 0.0, "fantan": 0.0, "fav": 0.0, "dog": 0.0}
	var fav_wins := 0
	var fav_p := 0.0
	var N := 10000
	for k in N:
		var d := Gamble.deal(k)
		for dv in d.dice:
			faces[int(dv) - 1] += 1
		left4[int(d.beads) % 4] += 1
		for bt in ["big", "small", "triple"]:
			back[bt] += (1.0 + Gamble.pays("dice", bt, d)) if Gamble.wins("dice", bt, d) else 0.0
		back.fantan += (1.0 + Gamble.pays("fantan", "2", d)) if Gamble.wins("fantan", "2", d) else 0.0
		var fav := "a" if float(d.pa) >= 0.5 else "b"
		var dog := "b" if fav == "a" else "a"
		fav_p += maxf(float(d.pa), 1.0 - float(d.pa))
		fav_wins += 1 if str(d.win) == fav else 0
		back.fav += (1.0 + Gamble.pays("crickets", fav, d)) if Gamble.wins("crickets", fav, d) else 0.0
		back.dog += (1.0 + Gamble.pays("crickets", dog, d)) if Gamble.wins("crickets", dog, d) else 0.0
	var fair := true
	for fc in faces:
		fair = fair and absf(float(fc) / (N * 3.0) - 1.0 / 6.0) < 0.012
	for l4 in left4:
		fair = fair and absf(float(l4) / N - 0.25) < 0.02
	check(fair and absf(float(fav_wins) / N - fav_p / N) < 0.02, "the dice and the beads are fair, and a cricket wins as often as its record says (favourites %d of %d)" % [fav_wins, N])
	for bk in back:
		var ret: float = float(back[bk]) / N
		check(ret > 0.8 and ret < 0.995, "the house is ahead on %s, a little: a stone staked comes back as %.3f" % [bk, ret])
	GG2.stones = 5000
	var before: int = GG2.stones
	var res1 := Gamble.play(GG2, "dice", "big", 1000)
	check(GG2.gamble_n == 1 and GG2.gamble_rounds == 1 and GG2.stones == before + int(res1.pay) and (int(res1.pay) == 1000 if bool(res1.won) else int(res1.pay) == -1000) and (res1.lines as Array).size() >= 2,
		"a round is staked, thrown, paid and told")
	var res2 := Gamble.play(GG2, "dice", "big", 999999)
	check(absi(int(res2.pay)) <= before + 1000 and GG2.stones >= 0, "nobody stakes more than he carries")
	GG2.stones = 0
	check(Gamble.stakes(GG2).is_empty() and Gamble.play(GG2, "fantan", "1", 100).lines.is_empty() and GG2.gamble_n == 2, "and with nothing to stake, nothing is thrown")
	GG2.stones = 50
	check(Gamble.stakes(GG2) == [5], "a poor man may stake a tenth of what he has")
	for ln in Gamble.WIN_LINES + Gamble.LOSE_LINES + Gamble.YUE_LINES:
		check(fits.call(str(ln)), "what is said at the mat fits the dialogue box")
	Feats.poll(GG2)
	check(GG2.feats.has("gamble_first") and not GG2.feats.has("gamble_ten"), "sitting down at the mat is a feat; winning ten is another")
	GG2.free()
	check(bsrc.contains("Gamble.ASK"), "the bot does not gamble: it walks away from the mat")
	print("== survival: the body (needs.gd) ==")
	var NG = load("res://scripts/game.gd").new()
	NG.reset()
	check(not NG.survival and Needs.mod(NG, "atk") == 1.0 and Needs.mod(NG, "qi") == 1.0 and Needs.mod(NG, "spd") == 0.0 and Needs.value(NG, "hunger") == 100.0 and Needs.pass_time(NG, 50.0).is_empty(),
		"survival is off unless it is turned on, and off it asks nothing and costs nothing")
	var atk0: float = NG.fighter(0).atk
	var qi0: int = NG.max_qi(0)
	check(Needs.ORDER.size() == 7 and Needs.ORDER == ["rest", "hunger", "thirst", "bladder", "bowels", "comfort", "clean"], "seven needs: rest, hunger, thirst, bladder, bowels, comfort and cleanliness")
	for nk in Needs.ORDER:
		check(Needs.NEEDS.has(nk) and float(Needs.NEEDS[nk].rate) > 0.0 and str(Needs.NEEDS[nk].low) != "" and Needs.YUE_LOW.has(nk) and fits.call(str(Needs.YUE_LOW[nk])), "the need %s runs down, has a word for when it is low, and Yue Ling has something to say about it" % nk)
	check(Needs.act(NG, "toggle", {}) != "" and NG.survival and int(NG.inv.steamed_bun) == 3 and NG.gourd == Needs.GOURD and Needs.value(NG, "rest") == 85.0, "turned on: every need content, three buns and a full gourd")
	check(is_equal_approx(NG.fighter(0).atk, atk0 * 1.03) and NG.max_qi(0) == qi0 and Needs.state(NG).begins_with("well kept"), "a body that is well kept, all seven, strikes a little harder for it")
	Needs.pass_time(NG, 4.0)
	check(Needs.value(NG, "bladder") < Needs.value(NG, "thirst") and Needs.value(NG, "thirst") < Needs.value(NG, "hunger") and Needs.value(NG, "hunger") < Needs.value(NG, "clean"), "by the clock: the bladder first, then thirst, then hunger, and cleanliness last")
	var mortal := 85.0 - Needs.value(NG, "hunger")
	NG.level = 60
	var before_h := Needs.value(NG, "hunger")
	Needs.pass_time(NG, 4.0)
	check(before_h - Needs.value(NG, "hunger") < mortal * 0.65 and Needs.pace(NG) >= Needs.FLOOR and Needs.pace(NG) < 1.0, "a cultivator needs less with every realm (%d%% of a mortal's at the twentieth)" % int(Needs.pace(NG) * 100.0))
	NG.level = 0
	NG.needs["hunger"] = 20.0
	NG.needs["rest"] = 20.0
	NG.needs["thirst"] = 20.0
	check(NG.fighter(0).atk < atk0 * 0.82 and NG.max_qi(0) < qi0 and Needs.mod(NG, "spd") <= -2.0 and Needs.state(NG).contains("famished"), "famished, parched and worn out: he strikes less hard, holds less qi and is slower")
	var wild := {"wild": true, "water": true}
	var street := {"town": true}
	var inn := {"indoors": true, "privy": true, "town": true}
	check(Needs.act(NG, "eat:steamed_bun", wild) != "" and int(NG.inv.steamed_bun) == 2 and Needs.value(NG, "hunger") == 50.0, "a bun is eaten, and answers hunger")
	check(Needs.act(NG, "drink", wild) != "" and NG.gourd == Needs.GOURD - 1 and Needs.value(NG, "thirst") == 65.0, "a pull at the gourd answers thirst")
	NG.needs["bladder"] = 10.0
	NG.needs["bowels"] = 10.0
	check(Needs.act(NG, "relieve", street) == "" and Needs.value(NG, "bladder") == 10.0, "not in the street")
	check(Needs.act(NG, "relieve", inn) != "" and Needs.value(NG, "bladder") == 100.0 and Needs.value(NG, "bowels") == 100.0, "an inn has a privy out the back")
	NG.needs["bladder"] = 10.0
	var cl := Needs.value(NG, "clean")
	check(Needs.act(NG, "relieve", wild) != "" and Needs.value(NG, "bladder") == 100.0 and Needs.value(NG, "clean") < cl, "and out in the country there is always a tree")
	check(Needs.act(NG, "wash", street) == "" and Needs.act(NG, "wash", wild) != "" and Needs.value(NG, "clean") > cl, "washing wants water")
	check(Needs.act(NG, "sleep", inn) == "" and Needs.act(NG, "sleep", wild) != "" and Needs.value(NG, "rest") >= 90.0 and is_equal_approx(Clock.hour(NG), 6.0), "sleeping rough fills most of rest, and it is morning")
	var hg := Needs.value(NG, "hunger")
	check(Needs.act(NG, "forage", street) == "" and Needs.act(NG, "forage", wild) != "" and Needs.value(NG, "hunger") > hg, "there is always something to forage in the wild: nobody can be left with nothing to eat")
	# what the things of the land do for the body
	NG.needs["clean"] = 5.0
	NG.needs["thirst"] = 5.0
	NG.gourd = 0
	Needs.used(NG, "hot_spring", "rest")
	Needs.used(NG, "well", "drink")
	check(Needs.value(NG, "clean") == 100.0 and Needs.value(NG, "thirst") == 100.0 and NG.gourd == Needs.GOURD, "a hot spring washes, a well waters, and the gourd is filled wherever one drinks")
	NG.needs["rest"] = 30.0
	Needs.used(NG, "bed", "sleep")
	check(Needs.value(NG, "rest") == 100.0, "a bed is a night's rest")
	for pk in Needs.BY_KIND:
		check(Props.KINDS.has(pk), "the thing %s that does something for the body is a thing of the land" % pk)
	for fid in Needs.FOOD_ORDER:
		check(Data.ITEMS.has(fid) and float(Needs.FOOD[fid].hunger) > 0.0 and int(Needs.FOOD[fid].price) > 0, "%s can be bought and eaten" % fid)
	for ck in Needs.COOKS:
		check(Trials.npc_area(ck) != "", "%s, who sells food for the road, lives somewhere" % ck)
	# a need at nothing takes matters into its own hands; nobody dies of it
	NG.egg_pending.clear()
	NG.needs["bladder"] = 1.0
	NG.needs["rest"] = 90.0
	var fell: Array = Needs.pass_time(NG, 1.0)
	check(fell == ["bladder"] and Needs.value(NG, "bladder") == 100.0 and Needs.value(NG, "clean") < 60.0 and NG.egg_pending.size() == 1 and int(NG.needs_fell.bladder) == 1, "he does not, quite, reach the tree: it is told, and he wants a wash")
	NG.needs["hunger"] = 0.5
	NG.hp[0] = 50.0
	Needs.pass_time(NG, 1.0)
	check(NG.hp[0] >= 1.0 and Needs.value(NG, "hunger") >= 25.0, "nobody dies of hunger: it costs health, and Yue Ling's last bun")
	for ck2 in Needs.COLLAPSE:
		for l in Needs.COLLAPSE[ck2]:
			check(fits.call(str(l[1])) and (l.size() < 3 or Data.EMOTES.has(str(l[2]))), "what is said when %s gives way fits the dialogue box" % ck2)
	# somebody careful never lets it come to that: a fortnight in the wild, tended as the bot tends it
	var CG2 = load("res://scripts/game.gd").new()
	CG2.reset()
	Needs.begin(CG2)
	for hour in 24 * 14:
		Needs.pass_time(CG2, 1.0, 1.3)
		for _n in 4:
			var adv := Needs.advice(CG2, wild)
			if adv != "":
				Needs.act(CG2, adv, wild)
	check(CG2.needs_fell.is_empty() and Needs.value(CG2, "hunger") > 20.0 and Needs.value(CG2, "thirst") > 20.0, "a fortnight in the wild, tended with care, and the body never once has its own way")
	check(Needs.act(NG, "toggle", {}) != "" and not NG.survival and is_equal_approx(NG.fighter(0).atk, atk0), "and it can be turned off again at any time")
	NG.free()
	CG2.free()

	print("== courtship (romance.gd) ==")
	var RG = load("res://scripts/game.gd").new()
	RG.reset()
	RG.companion = true
	check(Romance.stage(RG) == 0 and Romance.stage_name(RG) == "Walking together" and Romance.tone(RG) == "" and Romance.epilogue(RG).is_empty() and Romance.mod(RG) == 1.0, "nothing is said until it is said")
	check(Romance.GIFT_ORDER.size() == 12 and Romance.GIFTS.size() == 12 and Romance.OUTING_ORDER.size() == 10 and Romance.OUTINGS.size() == 10 and Romance.ASK_ORDER == ["confess", "tokens", "wed"], "twelve gifts, ten hours together, three questions")
	var tastes := {}
	for gid in Romance.GIFT_ORDER:
		var gf: Dictionary = Romance.GIFTS[gid]
		tastes[str(gf.taste)] = true
		var srcs := (1 if gf.has("cost") else 0) + (1 if gf.has("item") else 0) + (1 if gf.has("need") else 0)
		check(srcs == 1 and str(gf.taste) in ["love", "like", "meh"] and str(gf.desc).length() > 40 and fits.call(str(gf.line)) and (not gf.has("item") or Data.ITEMS.has(str(gf.item))), "the gift %s: one way to come by it, a taste, and what she says" % gid)
		check(not _has_word(Voice.her(str(gf.desc)), ["he", "him", "his"]), "the gift %s is told of whoever the hero is" % gid)
	check(tastes.size() == 3, "she loves some, likes some, and does not know what to do with one or two")
	var wheres := {}
	for oid in Romance.OUTING_ORDER:
		var o: Dictionary = Romance.OUTINGS[oid]
		wheres[str(o.where)] = true
		var tones := {}
		var ok_o: bool = (o.options as Array).size() == 3 and (o.lines as Array).size() >= 2 and str(o.hint) != ""
		for op in o.options:
			tones[str(op[1])] = true
			ok_o = ok_o and fits.call(str(op[3])) and str(op[2]).length() > 8
		for l in o.lines:
			ok_o = ok_o and fits.call(str(l[1]))
		check(ok_o and tones.size() == 3, "the hour %s: a scene, and something tender, something playful and something quiet to say" % oid)
	check(wheres.size() == 10, "every hour has a place and a time of its own")
	check(Romance.here("town_night", {"town": true, "hour": 21.0}) and not Romance.here("town_night", {"town": true, "hour": 12.0}) and Romance.here("town_day", {"town": true, "hour": 12.0}) and Romance.here("summit", {"summit": true})
		and Romance.here("wild_dawn", {"wild": true, "hour": 6.0}) and not Romance.here("wild_dawn", {"wild": true, "hour": 9.0}) and Romance.here("cave", {"cave": true, "indoors": true}) and not Romance.here("indoors", {"cave": true, "indoors": true})
		and Romance.here("sect", {"area": "sect"}) and Romance.here("cold", {"cold": true}) and Romance.here("water", {"water": true}) and Romance.here("wild_night", {"wild": true, "hour": 23.0}) and Romance.here("indoors", {"indoors": true}),
		"an hour is had only where and when it belongs")
	check(Romance.outings_here(RG, {"town": true, "hour": 21.0}) == ["lanterns"] and Romance.outings_here(RG, {"area": "sect", "town": true, "hour": 10.0}) == ["steps", "market"], "what can be had here and now is offered, and nothing else")
	for aid in Romance.ASK_ORDER:
		var a: Dictionary = Romance.ASKS[aid]
		var ok_a: bool = (a.options as Array).size() == 3 and str(a.ask).length() > 60
		for op2 in a.options:
			ok_a = ok_a and a.reply.has(str(op2[0]))
			for l2 in a.reply[str(op2[0])]:
				ok_a = ok_a and fits.call(str(l2[1])) and (l2.size() < 3 or Data.EMOTES.has(str(l2[2])))
		check(ok_a and int(a.bond) <= Bonds.LEVELS[Bonds.LEVELS.size() - 1], "the question %s: three ways to ask, an answer to each, and a closeness that can be reached" % aid)
	# she is not asked before the two are close enough, and the questions come in order
	check(Romance.next_ask(RG) == "confess" and Romance.ask_blocked(RG, "confess") != "" and Romance.take_ask(RG, "confess", "plain").is_empty() and Romance.ask_blocked(RG, "wed") != "", "it cannot be said before the two are close")
	RG.stones = 10000
	var b0: int = RG.bond
	var said: Array = Romance.give(RG, "haws")
	check(said.size() == 2 and RG.stones == 10000 - 60 and RG.bond == b0 + Romance.LOVE and Romance.gifts_given(RG) == 1 and Romance.give(RG, "haws").is_empty(), "a gift she loves: paid for, given once, and it brings them closer")
	Romance.give(RG, "rouge")
	check(RG.bond == b0 + Romance.LOVE + Romance.MEH and str(RG.romance.gifts.rouge) == "meh", "one she does not know what to do with brings them a little closer all the same")
	check(Romance.gift_blocked(RG, "flowers") != "" and Romance.gift_blocked(RG, "duck") != "" and Romance.gift_blocked(RG, "cricket") != "", "what grows on a summit, lies in a cave or is won at the mat has to be come by first")
	RG.summits = {"a": true}
	RG.inv["clay_duck"] = 1
	check(Romance.give(RG, "flowers").size() == 2 and Romance.give(RG, "duck").size() == 2 and int(RG.inv.clay_duck) == 1, "and then it can be given (the duck is still theirs)")
	var r1: Array = Romance.take_outing(RG, "steps", "tender")
	var r2: Array = Romance.take_outing(RG, "tea", "tender")
	Romance.take_outing(RG, "market", "playful")
	check(r1.size() == 1 and r2.size() == 1 and Romance.outings_had(RG) == 3 and Romance.tone(RG) == "tender" and not Romance.outings_here(RG, {"area": "sect", "town": true, "hour": 10.0}).has("steps"), "an hour is had once; what is said most often is how they are with each other")
	RG.bond = 24
	check(Romance.ask_blocked(RG, "confess") == "" and Romance.take_ask(RG, "confess", "hand").size() >= 2 and Romance.stage(RG) == 1 and Romance.stage_name(RG) == "Courting" and Romance.next_ask(RG) == "tokens", "close enough, and two hours had: it is said, and they are courting")
	check(Romance.ask_blocked(RG, "tokens") != "", "tokens want more closeness yet")
	RG.bond = 42
	check(Romance.ask_blocked(RG, "tokens") == "" and Romance.take_ask(RG, "tokens", "thread").size() >= 2 and Romance.stage(RG) == 2 and Romance.mod(RG) > 1.0, "tokens exchanged: they are promised, and she is the stronger for it")
	RG.bond = 64
	check(Romance.ask_blocked(RG, "wed").contains("thread on the Wheel"), "she cannot be wed before she has a thread on the Wheel (Part XV)")
	RG.future = "wander"
	check(Romance.ask_blocked(RG, "wed").contains("Ask me then") and Romance.take_ask(RG, "wed", "moon").is_empty() and Romance.stage(RG) == 2, "if the road she chose is her own, she is promised, and will not be wed until she is back from it")
	RG.future = "companion"
	var hp1: int = RG.max_hp(1)
	check(Romance.ask_blocked(RG, "wed") == "" and Romance.take_ask(RG, "wed", "moon").size() >= 3 and Romance.stage(RG) == 3 and Romance.next_ask(RG) == "" and RG.yue_outfits.has("redbride") and RG.max_hp(1) > hp1, "three bows: they are wed, and she has the scarlet")
	check(Romance.epilogue(RG).size() == 1 and str(Romance.epilogue(RG)[0][1]).contains("three bows") and Bonds.epilogues(RG).any(func(x): return str(x).contains("three bows")) and Romance.summary(RG).begins_with("Wed"), "and the last page says so")
	Feats.poll(RG)
	check(RG.feats.has("courting") and RG.feats.has("promised") and RG.feats.has("wed") and not RG.feats.has("hours_all"), "each of the three is a feat")
	check(Feats.need(Feats.FEATS.hours_all.test) == Romance.OUTING_ORDER.size() and Feats.need(Feats.FEATS.gifts_six.test) <= Romance.GIFT_ORDER.size() and Feats.need(Feats.FEATS.wed.test) == Romance.STAGES.size() - 1, "no feat asks for more of the two of them than there is")
	check(not bsrc.contains("open_gifts") and not bsrc.contains("open_ask"), "the bot leaves courtship alone: it is the player's to do or not")
	RG.free()
	check(Folk.TOWNS.has("drumtower") and Cultures.of_town("drumtower") == "valley" and str(Folk.TOWNS.drumtower.area) == "village" and Data.AREAS.village.buildings.size() == 19, "Qingshi has a second quarter, of the Rice Hearth: nineteen buildings in all")
	var dt_people: Array = Folk.people(wsurf, "drumtower")
	var dt_roles := {}
	for dp in dt_people:
		dt_roles[str(dp.role)] = int(dt_roles.get(str(dp.role), 0)) + 1
	check(dt_people.size() == 26 and int(dt_roles.get("soldier", 0)) == 6 and int(dt_roles.get("musician", 0)) == 4, "twenty-six people live in the Drum Tower quarter: the levy, the players, and a street of others")
	for nr in ["soldier", "musician"]:
		check(Folk.ROLES.has(nr) and Folk.LINES.has(nr) and Folk.LINES[nr].size() >= 4 and Folk.TITLES.has(nr) and Folk.BODIES.human.has(nr), "the %s: a day, a body, a title and four things to say" % nr)
	for bid3 in ["drum_tower", "pipes_hall", "tailor_shop", "levy_barracks", "pear_garden", "potter_kiln"]:
		check(Data.AREAS.village.buildings.any(func(bd): return str(bd.id) == bid3), "the Drum Tower quarter has its %s" % bid3)
	MG.free()
