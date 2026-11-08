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
		print("failures: ", failures)
		quit(1 if failures > 0 else 0)
	return false

## The chapter-closing breakthroughs Main brings Lin Feng home after (read from main.gd's source: the
## screen cannot be instanced from a test script).
func main_recalls_s_break16() -> bool:
	var src := FileAccess.get_file_as_string("res://scripts/main.gd")
	return src.contains("\"s_break16\": \"recall10\"") and Data.DIALOGUE.has("recall10")

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
		if e.kind != "spring" and e.kind != "seal" and not reach_all.has(e.pos):
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
		check(Data.AREAS[a10].bosses.size() == 5 and Data.AREAS[a10].pickups.filter(func(pk): return not pk.get("always", false)).size() == 4, a10 + ": five bosses and four things to find")
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
		check(sp11.bosses.size() == 4 and sp11.pickups.filter(func(pk): return not pk.get("always", false)).size() == 4, a11 + ": four bosses and four things to find")
		check(Data.layer_of(a11) in ["heaven", "under"], a11 + " lies in a realm above or below the land")
		for n11 in sp11.npcs:
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
			if e11.kind != "spring" and e11.kind != "seal" and not lreach.has(e11.pos):
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
				if not freach.has(fe.pos):
					fcut += 1
				if fe.kind == "ladder" and fe.to_layer == lid2:
					back = true
					check(MapGen.is_walkable_tile(fw0.grid[fe.to_tile.y * fw0.w + fe.to_tile.x]), "%s: the stairs come out on the floor below (or above)" % fid)
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
	check(Data.REALMS[Data.REALMS.size() - 1] == "Ten Thousand Waters Return" and Data.MAX_LEVEL == 51 and Data.level_name(51).ends_with("Ten Thousand Waters Return"), "Part XII adds the Ten Thousand Waters Return realm")
	check(Data.STEPS[Data.STEPS.size() - 1].id == "s_break17" and Data.step_index("s_p12_home") == Data.step_index("s_break16") + 1, "Part XII follows Three Realms Concord and ends the game")
	check(Data.EXP_NEED.size() >= Data.MAX_LEVEL and Data.ENEMY_EXP.size() > Data.MAX_LEVEL, "cultivation and battle rewards are defined up to the last realm")
	check(main_recalls_s_break16(), "the sect calls Lin Feng home after Three Realms Concord (recall10)")
	for a12 in p12:
		var sp12: Dictionary = Data.AREAS[a12]
		check(Data.layer_of(a12) == "sea" and Atlas.STRATA.sea.sites.has(a12), a12 + " lies in the Eastern Sea")
		check(Look.THEMES.has(sp12.theme) and Look.EXTRA.has(sp12.theme) and Scatter.ECO.has(sp12.theme) and Fauna.KINDS.has(sp12.theme) and MapGen.DENSITY.has(sp12.theme) and Arch.SETTLE.has(sp12.theme), "theme, terrain extras, ecology, wildlife, density and dwellings for " + a12)
		check(sp12.bosses.size() == 4 and sp12.pickups.filter(func(pk): return not pk.get("always", false)).size() == 4, a12 + ": four bosses and four things to find")
		for n12 in sp12.npcs:
			check(Data.CHAT.has(str(n12.get("asset", n12.id))) and Data.CHAT[str(n12.get("asset", n12.id))].size() >= 3, "%s has at least three things to say" % n12.id)
			check(Assets.PEOPLE.has(str(n12.get("asset", n12.id))), "%s is Blender-built" % n12.id)
	var sea_w := Atlas.world_of("sea")
	var sea_reach := MapGen.flood(sea_w.grid, sea_w.w, sea_w.h, sea_w.start)
	var sea_cut := 0
	var boat_end := false
	for e12 in sea_w.ents:
		if e12.kind != "spring" and not sea_reach.has(e12.pos):
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
	# the rest (every script compiles) runs on the first frame, see _process
	finished = true
