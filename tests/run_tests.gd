extends SceneTree
## Data-integrity tests.  Run: godot --headless --path . --script tests/run_tests.gd

var failures := 0
var finished := false

## Watchdog: a script error aborts _init() before quit() and the runner used to hang until CI's
## timeout.  If the first frame arrives and the tests did not finish, fail fast instead.
func _process(_d: float) -> bool:
	if not finished:
		printerr("  FAIL tests aborted by a script error (see above)")
		quit(1)
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
			for clip in ["idle", "walk", "run", "sit", "talk", "bow", "attack", "cast", "hurt", "victory", "die"]:
				check(ap.has_animation(clip), "%s: clip %s" % [rel, clip])
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
	for i2 in Data.AREA_CHAIN.size():
		var ra: String = Data.AREA_CHAIN[i2]
		for gp in Data.AREAS[ra].portals:
			var ga := Atlas.to_world(ra, gp.pos)
			var gb := Atlas.to_world(gp.to, Data.AREAS[gp.to].portals.filter(func(q): return q.to == ra)[0].pos)
			if not reach_all.has(ga) or not reach_all.has(gb):
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
	check(folk9 >= 6 and folk9 <= 8, "six to eight townsfolk in the Dawn Market (%d)" % folk9)
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
	check(Data.REALMS[Data.REALMS.size() - 1] == "Mountain-River Oneness" and Data.MAX_LEVEL == 45, "Part X adds the Mountain-River Oneness realm")
	check(Data.STEPS[Data.STEPS.size() - 1].id == "s_break15", "Sun-Moon Harmony no longer ends the game: Mountain-River Oneness does")
	check(Data.DIALOGUE.has("recall8") and Data.step_index("s_break14") < Data.step_index("s_p10_home"), "Part X starts after the Sun-Moon Harmony breakthrough")
	check(Data.AREAS.sect.portals.any(func(p): return p.to == "longmen" and p.open == "s_p10_road" and p.pos == Vector2i(12, 1)), "the sect's new north gate opens on the river road once Cartographer Pei has drawn it")
	var sect10 := MapGen.build("sect")
	check(sect10.grid[1 * sect10.w + 12] == MapGen.PATH and sect10.grid[12 * sect10.w + 12] == MapGen.PATH, "a path runs from the courtyard up to the north gate")
	for a10 in p10:
		check(Look.THEMES.has(a10) and Look.EXTRA.has(a10) and Scatter.ECO.has(a10) and Fauna.KINDS.has(a10) and MapGen.DENSITY.has(a10) and Arch.SETTLE.has(a10), "theme, terrain extras, ecology, wildlife, density and dwellings for " + a10)
		check(Data.AREAS[a10].bosses.size() == 5 and Data.AREAS[a10].pickups.size() == 4, a10 + ": five bosses and four things to find")
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
	for rid2 in Atlas.region_ids():
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
	for st in Data.STEPS:
		if st.kind == "collect":
			check(Data.ITEMS.has(st.item), "collect item defined " + st.item)
	for k in Data.DIALOGUE:
		for ln in Data.DIALOGUE[k]:
			check(ln.size() == 2 and str(ln[1]).length() > 0, "dialogue line well formed in " + k)
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
	print("failures: ", failures)
	finished = true
	quit(1 if failures > 0 else 0)
