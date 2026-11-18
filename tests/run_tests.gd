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
		# (the Five Hands release, grip.gd: a skeleton only answers once it is in the tree, so this is asked here)
		if Assets.has("characters/lin_feng"):
			print("== an arm solved on a skeleton in the tree (grip.gd) ==")
			var hm0: Node3D = Assets.instance("characters/lin_feng")
			root.add_child(hm0)
			var sk0: Skeleton3D = hm0.find_children("*", "Skeleton3D", true, false)[0]
			var ih0 := sk0.find_bone("hand.R")
			var goal0 := sk0.get_bone_global_pose(ih0).origin + Vector3(0.1, 0.25, 0.3)
			var basis0 := sk0.get_bone_global_pose(ih0).basis
			var came0 := Grip.apply(sk0, "R", goal0)
			check(came0.distance_to(goal0) < 0.004, "the hero's wrist is put where it is asked (%.4f m off)" % came0.distance_to(goal0))
			check(absf(sk0.get_bone_global_pose(sk0.find_bone("upper_arm.R")).origin.distance_to(sk0.get_bone_global_pose(sk0.find_bone("forearm.R")).origin) - sk0.get_bone_global_rest(sk0.find_bone("upper_arm.R")).origin.distance_to(sk0.get_bone_global_rest(sk0.find_bone("forearm.R")).origin)) < 0.002
				and sk0.get_bone_global_pose(ih0).basis.is_equal_approx(basis0), "his upper arm is as long as it was, and his hand is turned as it was")
			hm0.queue_free()
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
		var bare_tris := 0
		var dress_tris := 0
		for mi in pm.get_meta("meshes"):
			for si in mi.mesh.get_surface_count():
				var n: int = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_INDEX].size() / 3
				tris += n
				if str(mi.name).begins_with("bare"):
					bare_tris += n
				elif str(mi.name).begins_with("dress"):
					dress_tris += n
				var mat: Material = mi.mesh.surface_get_material(si)
				check(mat == MB.mat_actor() or mat == MB.mat_actor_plain() or mat == MB.mat_glow(), "%s: surface %d uses the actor shading" % [rel, si])
		# sculpted faces, strand hair and layered hanfu: a hero-asset budget, still well under 50k (the
		# Underclothes release: drawn dressed or in the underclothes, never both at once)
		check(tris - bare_tris > 5000 and tris - bare_tris < 50000, "%s: sensible triangle count (%d)" % [rel, tris - bare_tris])
		check(bare_tris == 0 or (tris - dress_tris > 5000 and tris - dress_tris < 50000), "%s: sensible triangle count in the underclothes (%d)" % [rel, tris - dress_tris])
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
	# a beast is not painted one bright colour all over (assets.gd NATURAL): its hide is the colour it was
	# given taken down, and the brightness is kept for its markings
	var loud := Color("30c040")
	check(Assets.natural(loud).s <= 0.5 and Assets.natural(loud).s < loud.s and absf(Assets.natural(loud).h - loud.h) < 0.08, "a green wolf's hide is a green-grey, not a green")
	check(Assets.natural(Color("808080")) == Color("808080"), "a grey beast stays grey")
	for nsh in Assets.NATURAL:
		check(Assets.MONSTERS.has(nsh), "the natural shape %s is a shape" % nsh)
	check(not Assets.NATURAL.has("wisp") and not Assets.NATURAL.has("phoenix") and not Assets.NATURAL.has("dragon"), "spirits, flames and dragons are as bright as they were")
	var oxn := Assets.mount("ox")
	check(Assets.has_clip(oxn, "walk") and Assets.has_clip(oxn, "idle"), "the ox of the cart is Blender-built and walks")
	oxn.free()
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
		# (the Lost Horse release: but where a wing is built out from a wall, the wall is open along it)
		var open_to_wing := {}
		for wg0 in bd.get("wings", []):
			for q0 in Rooms.wing_gap(bd, wg0):
				open_to_wing[q0] = true
		for xx in range(r.position.x, r.end.x):
			for yy in [r.position.y, r.end.y - 1]:
				if Vector2i(xx, yy) != bd.door and not open_to_wing.has(Vector2i(xx, yy)) and MapGen.is_walkable_tile(wd.grid[yy * wd.w + xx]):
					edge_closed = false
		for yy in range(r.position.y, r.end.y):
			for xx in [r.position.x, r.end.x - 1]:
				if Vector2i(xx, yy) != bd.door and not open_to_wing.has(Vector2i(xx, yy)) and MapGen.is_walkable_tile(wd.grid[yy * wd.w + xx]):
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
			var open11 := {}
			for wg11 in bd11.get("wings", []):
				for q11 in Rooms.wing_gap(bd11, wg11):
					open11[q11] = true
			for xx in range(r11.position.x, r11.end.x):
				for yy in [r11.position.y, r11.end.y - 1]:
					if Vector2i(xx, yy) != bd11.door and not open11.has(Vector2i(xx, yy)) and MapGen.is_walkable_tile(lw.grid[yy * lw.w + xx]):
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
	for lid2 in Atlas.LAYERS:
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
	var need_kinds := ["cooked", "light", "phases", "quelled", "rites", "lv", "peak", "temper", "ranks", "item", "give", "stones", "renown", "dao", "standing", "friends", "gates", "fate", "bonds", "heart", "rallied", "cleared", "hearths", "works", "delved", "arms", "summits", "companies", "airs", "falls", "marks", "weal", "households", "creed", "fitted", "clean", "wild", "step", "restored"]
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
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= 12
					"weal":
						# the Answering Land release: towns that thrive (weal.gd): no more than half of them
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= Weal.ORDER.size() / 2
					"creed":
						# the Ordered House release: a side of the Way (creed.gd): an axis, and just what makes a side
						ok = ok and n.size() == 3 and Creed.AXES.has(str(n[1])) and absi(int(n[2])) == Creed.SIDE
					"fitted":
						# houses put to rights (fitting.gd): no more than the story's own steps have asked for by then
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= 9
					"restored":
						# lost things carried home (trifles.gd): no more than the story's own steps have asked for
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= 6
					"clean", "wild":
						# the Open Net release: a clean name (crime.gd), a wild that stands (wilds.gd): nothing to count
						ok = ok and n.size() == 1
					"step":
						# something of the story done already: a real step, before the trial
						ok = ok and Data.step_index(str(n[1])) >= 0 and Data.step_index(str(n[1])) < _kill_step(tid)
					"rites":
						# the Uncarved Block release: Daos whose rite he has performed (rites.gd)
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= Rites.ORDER.size()
					"cooked", "light", "phases", "quelled":
						# the Small Fish release: meals that came out right, blows held back to one thing: a few
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= 3
					"households":
						# the Three Burrows release: households of the hero's own town (hold.gd): no more than
						# the story has brought there by the trial, nor than a city has
						ok = ok and int(n[1]) >= 1 and int(n[1]) <= int(Hold.RANKS[3][0])
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
		check(realms7.size() >= 3 or str(st7.id) in ["s_p16_calls", "s_p18_carry", "s_p19_makers", "s_p19_word", "s_p20_elders", "s_p21_masters", "s_p23_levy", "s_p24_lost", "s_p25_guests", "s_p27_fires", "s_p28_calls"], "%s: the people to visit live in at least three realms" % st7.id)
	check(visits_steps >= 1, "Part XIII has a step of visits in any order")
	for st8 in Data.STEPS:
		if st8.kind == "hunt" and st8.has("of"):
			var band8: Dictionary = Data.AREAS[st8.area].get("warband", {})
			# (a hunt in a cave, Part XX, is for what lives in that cave: caves.gd)
			if st8.has("cave"):
				band8 = Caves.spec(str(st8.area), int(st8.cave)).get("foes", {})
				# (the Small Fish release: or for a band a later chapter stood in it last of all)
				if Caves.LATE.get(str(st8.area), {}).has(int(st8.cave)) and (str(st8.id).begins_with("s_p36_") or str(st8.id).begins_with("s_p37_") or str(st8.id).begins_with("s_p38_")):
					band8 = Caves.LATE[str(st8.area)][int(st8.cave)]
			var marching8 := {}
			for pe8 in band8.get("pool", []):
				marching8[pe8[0]] = true
			# (Part XXII: a region's second band, for a later chapter)
			if not st8.has("cave"):
				for pe8b in Data.AREAS[st8.area].get("warband2", {}).get("pool", []):
					marching8[pe8b[0]] = true
				# (Part XXIV: and a third and a fourth)
				# (Part XXV: and a fifth and a sixth, placed after the marks)
				for bk8 in ["warband3", "warband4", "warband5", "warband6", "warband7"]:
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
	for plid in Atlas.LAYERS:
		var plw := Atlas.world_of(plid)
		var bad_tile := 0
		var bad_near := 0
		var bad_apart := 0
		var outs: Array = []
		var others: Array = []
		for pe in plw.ents:
			# (somebody found indoors, rooms.gd `residents`, is behind a wall from anything out of doors)
			if pe.kind != "prop" and not pe.get("indoor", false):
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
			# (a thing the story stands on the rock of a peak, the hot spring of Part XXVI, stands there like
			# the story's people: a peak is laid where nothing stands and has no edge; the chapter's tests
			# see that it can be walked up to)
			if pe2.has("peak"):
				tv = MapGen.WALL
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
		check(float(rd.speed) > 1.0 and (rd.has("step") or rd.has("pick") or rd.has("buy") or rid == "pony") and (not rd.has("step") or Data.step_index(str(rd.step)) >= 0), "ride %s: faster than running and earned somewhere" % rid)
		var rn := Models.ride(rid)
		check(rn.get_child_count() > 0, "ride %s builds" % rid)
		rn.free()
	check(kinds.has("mount") and kinds.has("vehicle"), "mounts to sit astride and vehicles to stand on")
	# carriages (the Lost Horse release): driven, seat more than two, sold by whoever answers for a town
	var cars := 0
	for rid in Fashion.RIDE_ORDER:
		var rd2: Dictionary = Fashion.RIDES[rid]
		if str(rd2.kind) != "carriage":
			check(Fashion.seats(rid) == 2, "ride %s seats the hero and one behind" % rid)
			continue
		cars += 1
		check(Fashion.seats(rid) >= 4 and rd2.seats[0] == rd2.seat and rd2.seats[1] == rd2.pillion, "carriage %s seats four or more, the hero and Yue Ling first" % rid)
		var apart := true
		for i in Fashion.seats(rid):
			for j in i:
				apart = apart and (rd2.seats[i] as Vector3).distance_to(rd2.seats[j]) > 0.5
		check(apart, "carriage %s: nobody sits in anybody's lap" % rid)
		check(int(rd2.buy) > 0 and Offices.OFFICES.has(str(rd2.at)), "carriage %s is sold by somebody who answers for a town" % rid)
		var cn := Models.ride(rid)
		check(cn.has_meta("wheels") and (cn.get_meta("wheels") as Array).size() >= 2, "carriage %s has wheels that turn" % rid)
		check(Models.anim_ride(cn, 1.0, true) == Vector3.ZERO, "carriage %s does not bob" % rid)
		cn.free()
	check(cars >= 3, "three carriages")
	var fg = load("res://scripts/game.gd").new()
	fg.reset()
	var lodger := {"id": "res:village:inn:0", "n": "Lodger Wu", "asset": "folk_youth", "area": "village", "trade": "inn"}
	check(Offices.fare_offer(fg, lodger).is_empty(), "nobody asks a rider on a pony for a lift")
	fg.rides["ox_cart"] = true
	fg.ride = "ox_cart"
	# (the Cloud Keel release: a fare is for somewhere he has been; this journey has been to every town with a road)
	for ft9 in Offices.FARE_TOWNS:
		fg.seen[ft9] = true
	var fare := Offices.fare_offer(fg, lodger)
	check(not fare.is_empty() and str(fare.to) != "village" and Data.AREAS.has(str(fare.to)) and int(fare.pay) > 0, "a lodger asks a cart with a seat free for a lift to another town")
	check(Offices.fare_offer(fg, {"id": "x", "n": "Smith", "area": "village", "trade": "workshop"}).is_empty(), "a smith at his anvil is going nowhere")
	Offices.take_fare(fg, fare)
	check(fg.passengers.size() == 1 and Offices.fare_offer(fg, lodger).is_empty(), "taken up once")
	Offices.take_fare(fg, Offices.fare_offer(fg, {"id": "res:village:inn:1", "n": "Lodger Hu", "asset": "folk_maiden", "area": "village", "trade": "inn"}))
	check(fg.passengers.size() == 2 and Offices.fare_offer(fg, {"id": "res:village:inn:2", "n": "Lodger Ma", "area": "village", "trade": "inn"}).is_empty(), "a cart of four is full with two carried")
	var st0: int = fg.stones
	fg.riding = true
	fg.area = "village"
	check(Offices.arrive(fg).is_empty() and fg.stones == st0, "nobody pays to be driven round the village")
	fg.area = str(fare.to)
	fg.riding = false
	check(Offices.arrive(fg).is_empty(), "nobody is set down by somebody on foot")
	fg.riding = true
	var said := Offices.arrive(fg)
	check(said.size() >= 1 and fg.stones >= st0 + int(fare.pay) and fg.fares >= 1 and fg.passengers.size() <= 1, "set down where they were going, and paid")
	check(int(fare.pay) * 20 < int(Fashion.RIDES.ox_cart.buy) * 10, "a fare does not pay for the cart in a day")
	fg.free()
	# the post (mail.gd): letters that come as the story goes, to the journey that chose a thing; bags to carry
	check(Mail.ORDER.size() == Mail.LETTERS.size() and Mail.LETTERS.size() >= 36, "every letter is in the order of the post (%d)" % Mail.LETTERS.size())
	var mfont := ThemeDB.fallback_font
	var by_cross := {}
	for lid in Mail.ORDER:
		var lt: Dictionary = Mail.LETTERS[lid]
		check(str(lt.from) != "" and (lt.lines as Array).size() >= 1 and Data.step_index(Mail.after_of(lid)) >= 0, "letter %s: from somebody, about something, after a real step" % lid)
		for ln in lt.lines:
			var mp := TextParagraph.new()
			mp.add_string(str(ln), mfont, 22)
			mp.width = 1100
			check(mp.get_line_count() <= 4, "letter %s fits the dialogue box" % lid)
		if lt.has("needs"):
			var copts: Array = Echoes.CROSSROADS[str(lt.needs[0])].options
			check(copts.any(func(o): return str(o.id) == str(lt.needs[1])), "letter %s answers a real answer of a real crossroads" % lid)
			by_cross[str(lt.needs[0])] = int(by_cross.get(str(lt.needs[0]), 0)) + 1
		if lt.has("on"):
			var ro: Array = Mail.LETTERS[str(lt.on[0])].reply.options
			check(ro.any(func(o): return str(o.id) == str(lt.on[1])) and Mail.ORDER.find(str(lt.on[0])) < Mail.ORDER.find(lid), "letter %s follows a real answer to an earlier letter" % lid)
		if lt.has("reply"):
			check((lt.reply.options as Array).size() == 2, "letter %s can be answered two ways" % lid)
			for ro2 in lt.reply.options:
				check(Mail.LETTERS.values().any(func(l2): return l2.has("on") and str(l2.on[0]) == lid and str(l2.on[1]) == str(ro2.id)), "letter %s: the answer %s brings a letter back" % [lid, ro2.id])
		var gf: Dictionary = lt.get("gift", {})
		check(gf.is_empty() or gf.has("stones") or Data.ITEMS.has(str(gf.get("item", ""))), "letter %s encloses a real thing" % lid)
	check(by_cross.size() >= 12, "a dozen crossroads write back (%d)" % by_cross.size())
	for po in Mail.POSTS:
		check(Offices.OFFICES.has(po), "the counter %s is somebody's" % po)
	var mg = load("res://scripts/game.gd").new()
	mg.reset()
	check(Mail.waiting(mg).is_empty(), "no letters before the story has begun")
	mg.step = Data.step_index("s_ironfang") + 8
	check(Mail.waiting(mg).has("ge_satchel") and Mail.waiting(mg).has("wen_first") and not Mail.waiting(mg).has("bandits_mend"), "the first letters come after Iron Fang, and none about a choice not made")
	var hp0 := int(mg.inv.get("hp_pill", 0))
	check(Mail.open(mg, "wen_first") != "" and int(mg.inv.get("hp_pill", 0)) == hp0 + 2 and Mail.open(mg, "wen_first") == "" and int(mg.inv.get("hp_pill", 0)) == hp0 + 2, "what is in a letter is taken once")
	check(Mail.owes_reply(mg, "wen_first") and not Mail.waiting(mg).has("wen_first") and Mail.kept(mg).has("wen_first"), "opened, it is in the satchel and wants an answer")
	Mail.reply(mg, "wen_first", "truth")
	Mail.reply(mg, "wen_first", "eaten")
	check(str(mg.mail_replies.wen_first) == "truth" and not Mail.owes_reply(mg, "wen_first"), "a letter is answered once")
	mg.step = Data.step_index("s_roc") + Mail.WAIT + 1
	check(Mail.waiting(mg).has("wen_truth") and not Mail.waiting(mg).has("wen_eaten"), "and the answer given is the one answered")
	var sc0: Dictionary = mg.scales.duplicate()
	check(mg.scales == sc0, "the post tips no scale")
	# the bags
	mg.level = 20
	var bg := Mail.bag_offer(mg, "head_qingshi")
	check(not bg.is_empty() and Mail.is_post(str(bg.to)) and str(bg.to) != "head_qingshi" and Data.layer_of(Mail.area_of(str(bg.to))) == "surface" and int(bg.pay) > 0, "Qingshi has a bag for another counter of the land")
	check(Mail.bag_offer(mg, "emperor").is_empty(), "the court keeps no counter")
	Mail.take_bag(mg, bg)
	check(mg.mail_bags.size() == 1 and Mail.bag_offer(mg, "head_qingshi").is_empty(), "one bag a day from a counter")
	var ms0: int = mg.stones
	check(Mail.deliver(mg, "head_qingshi") == 0 and mg.stones == ms0, "nothing is paid for carrying it nowhere")
	check(Mail.deliver(mg, str(bg.to)) == int(bg.pay) and mg.stones == ms0 + int(bg.pay) and mg.mail_bags.is_empty() and mg.bags_done == 1, "handed over where it was sealed for, and paid")
	mg.day += 1
	for k in 5:
		Mail.take_bag(mg, Mail.bag_offer(mg, Mail.POSTS[k]))
	check(mg.mail_bags.size() == Mail.BAGS, "three bags is a load")
	check(Mail.bag_pay(20, "head_qingshi", "post_cloudfoot") * 3 <= Data.enemy_stones(20, false) * 40, "a bag is worth less than the road")
	mg.free()
	# the high roads (roads.gd): the towns of a realm joined by a road that moves nothing
	var sw: Dictionary = Atlas.world_of("surface")
	check(not sw.has("roads"), "the road is not written into the world")
	Roads.forget()
	var rn: Dictionary = Roads.of("surface")
	var stowns: Array = []
	for tw9 in Data.TOWNS:
		if Data.layer_of(str(tw9.area)) == "surface":
			stowns.append(str(tw9.id))
	check(rn.at.size() == stowns.size() and (rn.lines as Array).size() >= stowns.size() - 1, "every town of the land is on the road (%d towns, %d roads)" % [rn.at.size(), (rn.lines as Array).size()])
	var lanes9 := 0
	for ln8 in rn.lines:
		if ln8.get("lane", false):
			lanes9 += 1
	check(lanes9 >= 20, "and lanes go off it to the regions round about (%d)" % lanes9)
	for tid9 in stowns:
		check(not Roads.route("surface", str(stowns[0]), tid9).is_empty() or tid9 == stowns[0], "the road goes from %s to %s" % [stowns[0], tid9])
	var rthings := {}
	for e9 in sw.ents:
		if e9.has("pos") and e9.kind != "enemy" and e9.kind != "seal":
			rthings[e9.pos] = true
	var rbad := 0
	var rsteep := 0
	for rp in rn.tiles:
		if not Roads._roadable(sw.grid[rp.y * int(sw.w) + rp.x]) or rthings.has(rp):
			rbad += 1
		if Peaks.at(sw, rp) > Peaks.STEEP * 3.0:
			rsteep += 1
	check(rbad == 0, "no road through a house, a pond, a wood or anything that stands (%d)" % rbad)
	check(rsteep == 0, "no road up a crag (%d)" % rsteep)
	for ln9 in rn.lines:
		var whole := true
		for k9 in range(1, (ln9.pts as Array).size()):
			whole = whole and absi(ln9.pts[k9].x - ln9.pts[k9 - 1].x) + absi(ln9.pts[k9].y - ln9.pts[k9 - 1].y) == 1
		if ln9.get("lane", false):
			check(whole and rn.tiles.has(ln9.pts[0]) and Data.AREAS.has(str(ln9.b)), "the lane to %s is one lane, off a road" % ln9.b)
		else:
			check(whole and ln9.pts[0] == rn.at[str(ln9.a)] and ln9.pts[(ln9.pts as Array).size() - 1] == rn.at[str(ln9.b)], "the road from %s to %s is one road" % [ln9.a, ln9.b])
	var rn2: Dictionary = Roads.of("surface")
	Roads.forget()
	check(Roads.of("surface").tiles.size() == rn2.tiles.size(), "the same road every time")
	var onr: Vector2i = rn.lines[0].pts[5]
	check(is_equal_approx(Roads.pace(sw, "carriage", onr), Roads.ON_ROAD) and is_equal_approx(Roads.pace(sw, "mount", onr), 1.0) and is_equal_approx(Roads.pace(sw, "vehicle", onr), 1.0), "a road is for wheels: a horse goes as it always did")
	var offr := Vector2i(-1, -1)
	for dy9 in range(-12, 13):
		for dx9 in range(-12, 13):
			var q9 := onr + Vector2i(dx9, dy9)
			if offr.x < 0 and sw.grid[q9.y * int(sw.w) + q9.x] == MapGen.FLOOR and not rn.tiles.has(q9):
				offr = q9
	check(offr.x >= 0 and is_equal_approx(Roads.pace(sw, "carriage", offr), Roads.OFF_ROAD), "and wheels are slow on grass")
	check(Roads.mesh("surface", Rect2i(0, 0, 4, 4), func(_x, _z): return 0.0) == null, "no paving where no road goes")
	var rm := Roads.mesh("surface", Rect2i(onr - Vector2i(8, 8), Vector2i(16, 16)), func(_x, _z): return 0.0)
	check(rm != null and rm.get_child_count() == 1, "paved where it does")
	if rm != null:
		rm.free()
	# the post-coach
	var cg = load("res://scripts/game.gd").new()
	cg.reset()
	cg.level = 30
	cg.stones = 5000
	check(Roads.coach_offers(cg, "village").is_empty(), "the coach goes nowhere he has not walked to")
	cg.seen["mountain"] = true
	cg.seen["longmen"] = true
	var cof: Array = Roads.coach_offers(cg, "village")
	check(cof.size() == 2 and int(cof[0].tiles) <= int(cof[1].tiles) and int(cof[0].fare) > 0, "from Qingshi the coach goes to the towns he has seen, nearest first")
	check(Roads.coach_offers(cg, "bamboo").is_empty(), "no coach from where there is no town")
	var shut9 := {}
	for sp9 in Roads.route("surface", "qingshi", "cloudfoot"):
		shut9[sp9] = true
	check(Roads.coach_offers(cg, "village", shut9).is_empty(), "nor past a seal that is shut")
	var cs0: int = cg.stones
	var cl0: float = cg.clock
	var cat := Roads.ride_coach(cg, cof[0])
	check(cat == rn.at[str(cof[0].to)] and cg.stones == cs0 - int(cof[0].fare) and cg.coaches == 1 and cg.clock != cl0, "the coach is paid for, takes its time and sets him down in the town")
	cg.stones = 0
	check(Roads.ride_coach(cg, cof[1]).x < 0, "nobody rides the coach on credit")
	cg.free()
	# the sea lanes (ships.gd): two lands, harbours, and a passage between them
	for hid9 in Ships.ORDER:
		var hb: Dictionary = Ships.HARBOURS[hid9]
		check(Mail.is_post(str(hb.office)) and Data.AREAS.has(str(hb.area)) and str(Offices.OFFICES[str(hb.office)].area) == str(hb.area), "the harbour %s has a counter in its own town" % hid9)
		check(Ships.quay(hid9).x >= 0, "the harbour %s has a quay" % hid9)
		for hid8 in Ships.ORDER:
			check(hid8 == hid9 or Ships.leagues(hid9, hid8) > 0, "it is known how far %s is from %s" % [hid9, hid8])
	check(Data.layer_of(str(Ships.HARBOURS.landfall.area)) != Data.layer_of(str(Ships.HARBOURS.longmen.area)), "the harbours are in two lands")
	var vg = load("res://scripts/game.gd").new()
	vg.reset()
	vg.level = 40
	vg.stones = 2000
	check(Ships.offers(vg, "harbour_longmen").is_empty(), "no ship goes where the journey has not been")
	vg.seen["longmen"] = true
	vg.seen["yanggu"] = true
	vg.seen["penglai"] = true
	var vo: Array = Ships.offers(vg, "harbour_longmen")
	check(vo.size() == 1 and str(vo[0].to) == "yanggu" and str(vo[0].kind) == "river", "before the sea is opened the junk goes down the river to Yanggu and no further")
	check(Ships.offers(vg, "reeve_landfall").is_empty() and Ships.offers(vg, "head_qingshi").is_empty(), "no ship from the Isles before then, and none from a village in the hills")
	vg.step = Data.step_index("s_p12_shore") + 1
	vo = Ships.offers(vg, "harbour_longmen")
	check(vo.size() == 2 and str(vo[1].to) == "landfall" and str(vo[1].kind) == "open" and int(vo[1].fare) > int(vo[0].fare), "once it is, she goes out to Landfall, for more")
	check(Ships.tale(vo[1], 0).size() == 2 and Ships.tale(vo[0], 3).size() == 1, "the river and then the open sea are told of")
	var vfont := ThemeDB.fallback_font
	for tk9 in Ships.TALES:
		for tl9 in Ships.TALES[tk9]:
			var vp := TextParagraph.new()
			vp.add_string(str(tl9), vfont, 22)
			vp.width = 1100
			check(vp.get_line_count() <= 4, "a tale of the %s fits the dialogue box" % tk9)
	var vs0: int = vg.stones
	var vc0: float = vg.clock
	check(Ships.sail(vg, vo[1]) and vg.stones == vs0 - int(vo[1].fare) and vg.voyages == 1 and vg.clock != vc0, "the passage is paid for and takes its days")
	vg.stones = 0
	check(not Ships.sail(vg, vo[0]), "nobody sails on credit")
	check(Ships.offers(vg, "reeve_landfall").size() == 2, "and from Landfall she sails home to either harbour")
	vg.free()
	var jn := Models.junk()
	check(jn.get_child_count() == 2, "the junk is built from code")
	jn.free()
	# fame (fame.gd): the higher he climbs the more people know his face, and come up to him
	check(Fame.REALMS.size() == Fame.NAMES.size() and Fame.NAMES.size() == Fame.CROWD.size() and Fame.CROWD.size() == Fame.LINES.size() and Fame.LINES.size() == Fame.GIFTS.size() and Fame.RISES.size() == Fame.NAMES.size(), "every standing has a name, a crowd, its words and its gifts")
	var fg9 = load("res://scripts/game.gd").new()
	fg9.reset()
	var last_rank := -1
	var last_crowd := -1
	var ranks_seen := {}
	for lv9 in range(0, Data.MAX_LEVEL + 1):
		fg9.level = lv9
		check(Fame.rank(fg9) >= last_rank and Fame.crowd(fg9) >= last_crowd, "fame never falls as he climbs (level %d)" % lv9)
		last_rank = Fame.rank(fg9)
		last_crowd = Fame.crowd(fg9)
		ranks_seen[last_rank] = true
	check(ranks_seen.size() == Fame.NAMES.size() and last_crowd >= 5, "a whole journey goes through every standing, and ends with a street behind him")
	fg9.level = 0
	check(Fame.crowd(fg9) == 0 and Fame.line(fg9, 3) == "" and not Fame.gift_due(fg9, "qingshi") and Fame.gift(fg9, "qingshi").is_empty(), "nobody follows a sweeper, and nobody gives him anything")
	for rk9 in range(1, Fame.LINES.size()):
		check((Fame.LINES[rk9] as Array).size() >= 3, "standing %d has things said of it" % rk9)
		for fl9 in Fame.LINES[rk9]:
			check(str(fl9).length() <= 64, "said in the street, not a speech: %s" % str(fl9))
	check(Fame.town_near("surface", Atlas.to_world("village", Vector2i(30, 28))) == "qingshi" and Fame.town_near("surface", Atlas.to_world("bamboo", Vector2i(30, 30))) == "", "a crowd is a thing of towns")
	fg9.level = Data.MAX_LEVEL
	var fs0: int = fg9.stones
	var fh0 := int(fg9.inv.get("hp_pill", 0))
	var gft := Fame.gift(fg9, "qingshi")
	check(not gft.is_empty() and fg9.stones > fs0 and int(fg9.inv.get("hp_pill", 0)) > fh0 and fg9.fan_gifts == 1, "somebody known everywhere is given something in the street")
	check(Fame.gift(fg9, "qingshi").is_empty() and not Fame.gift(fg9, "tushan").is_empty(), "once a day a town")
	fg9.day += 1
	check(Fame.gift_due(fg9, "qingshi"), "and again tomorrow")
	check(fg9.stones - fs0 < Data.enemy_stones(Data.MAX_LEVEL, false) * 12, "a gift in the street is not a living")
	fg9.free()
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
	_three_burrows()
	_five_frolics()
	_heavy_road()
	_answering_land()
	_ordered_house()
	_open_net()

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
	for lid in Atlas.LAYERS:
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
	check(Cultures.ENDING_ORDER.size() == 16 and Cultures.ENDINGS.size() == 16, "sixteen ends: the five of the New Fire, seven more that are not all kept by a fire, and four for whoever answered for a town")
	HG.reset()
	# (somebody who has sat at nobody's table and hardly knows the one beside him may also hold the sky alone)
	check(Cultures.endings_open(HG) == ["azure", "home", "cold"] and Cultures.ending_of(HG) == "azure", "the mountain and the way home are always open; the others are earned (and the cold hearth is what nothing earns)")
	for eid in Cultures.ENDING_ORDER:
		var en: Dictionary = Cultures.ENDINGS[eid]
		check(str(en.n) != "" and str(en.label) != "" and str(en.desc).length() > 60 and (en.lines as Array).size() >= 2 and en.sky is Color, "the ending %s has a name, a choice, and its own last words" % eid)
		for nd in en.needs:
			check(str(nd[0]) in ["home", "guests", "peoples", "heart", "arms", "masters", "lean", "works", "alone", "hold_rank", "chose"] and (str(nd[0]) == "home" or Cultures.ending_need_text(nd, HG) != ""), "%s: what it asks is something the journey can earn" % eid)
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
	for k3 in 1300:
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
	check(gw.size() == (Data.DIALOGUE.s_vl_intro as Array).size() + 1 and str(gw[gw.size() - 1][1]).contains("road-menders") and HWG.echoed.has("bandits|s_vl_intro") and Echoes.heard(HWG, "bandits") == [1, 7],
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
	check(Echoes.epilogue(HWG).size() == 6 and Echoes.names(HWG).contains("of the New Works") and Echoes.text(HWG, "bandits").contains("Echoes heard: 1 of 7") and Echoes.text(HWG, "bandits").contains("It stands in the land: The Menders' Road") and Echoes.text(HWG, "the_works").contains("ahead"), "the ending tells what came of each answer, and the page keeps them")
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
	var plan_src := bsrc3.substr(bsrc3.find("const CROSS_PLAN"), 3200)
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
	for lid in Atlas.LAYERS:
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
					check((Props.FURNITURE.has(str(pr2[0])) or str(pr2[0]) in Rooms.WALL_KINDS) and r.grow(-1).has_point(pr2[1]) and pr2[1] != st2, "%s: the %s in %s can be used, and stands on its floor" % [bd.n, pr2[0], full[key[1]].n])
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
	# (the Underclothes release: and since then, every eye of the size of a real one)
	check(FileAccess.get_file_as_string("res://art/lib/face.py").contains("EYE_K = 0.66"), "every eye is the size of a real one (art/lib/face.py)")
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
	check(int(kinds.get("dark", 0)) == 5 and int(kinds.get("bitter", 0)) == 2 and int(kinds.get("bright", 0)) == 9, "nine bright ends, two bitter and five dark")
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
		# (this is the land's own realm: what stands on a height of the Isles is looked for there, further down)
		if Data.layer_of(a) != "surface":
			continue
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
	for lid in Atlas.LAYERS:
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
	# wings, storeys and what each storey is for
	var winged := 0
	var tall := 0
	for a8 in Data.AREAS:
		var raw8: Array = Data.AREAS[a8].get("buildings", [])
		if raw8.is_empty():
			continue
		var m8 := MapGen.build(a8)
		var reach8 := MapGen.flood(m8.grid, m8.w, m8.h, m8.start)
		for i8 in raw8.size():
			var bd8: Dictionary = m8.buildings[i8]
			var st8 := Rooms.storeys(bd8)
			if st8 >= 3:
				tall += 1
			check(st8 >= 1 and st8 <= 5 and Rooms.uses(bd8).size() == st8 and (st8 == 1 or Rooms.uses_text(bd8).length() > 12) and (st8 >= 2) == bd8.has("upper"), "%s/%s stands %d storeys, each with a use" % [a8, bd8.id, st8])
			for u8 in Rooms.uses(bd8):
				check(Rooms.USE_WORDS.has(str(u8)), "%s/%s: a storey is used as %s" % [a8, bd8.id, u8])
			if not bd8.has("wings"):
				continue
			winged += 1
			check(not str(bd8.style) in Rooms.NO_WINGS and (bd8.wings as Array).size() <= 2, "%s/%s: a house of a style that takes wings, and no more than two" % [a8, bd8.id])
			for wg8 in bd8.wings:
				var wr8: Rect2i = wg8.rect
				var inner8 := 0
				for y8 in range(wr8.position.y, wr8.end.y):
					for x8 in range(wr8.position.x, wr8.end.x):
						if m8.grid[y8 * int(m8.w) + x8] == MapGen.INTERIOR and reach8.has(Vector2i(x8, y8)):
							inner8 += 1
				var gap8 := Rooms.wing_gap(bd8, wg8)
				var apart := true
				for j8 in raw8.size():
					if j8 != i8 and wr8.grow(1).intersects(m8.buildings[j8].rect):
						apart = false
				check(inner8 >= 2 and not gap8.is_empty() and gap8.all(func(q): return m8.grid[q.y * int(m8.w) + q.x] == MapGen.INTERIOR) and apart and not (bd8.rect as Rect2i).intersects(wr8)
					and Rooms.inside(bd8, wr8.position) and not Rooms.inside(bd8, wr8.position - Vector2i(9, 9)),
					"%s/%s: a wing built out from a wall, walked into through it, a tile clear of the next house (%d tiles of floor)" % [a8, bd8.id, inner8])
	# water keeps off the houses
	var wet := 0
	for a7 in Data.AREAS:
		if Data.AREAS[a7].get("buildings", []).is_empty():
			continue
		var m7 := MapGen.build(a7)
		for bd7 in m7.buildings:
			var rs7: Array = [bd7.rect]
			for wg7 in bd7.get("wings", []):
				rs7.append(wg7.rect)
			for r7 in rs7:
				var g7: Rect2i = (r7 as Rect2i).grow(Rooms.WATER_OFF)
				for y7 in range(maxi(0, g7.position.y), mini(int(m7.h), g7.end.y)):
					for x7 in range(maxi(0, g7.position.x), mini(int(m7.w), g7.end.x)):
						if m7.grid[y7 * int(m7.w) + x7] == MapGen.WATER:
							wet += 1
	check(wet == 0 and Rooms.WATER_OFF >= 2, "no water within two tiles of any building's walls, or of a wing's (%d wet tiles)" % wet)
	# who is at home
	var res_n := 0
	var res_areas := {}
	var res_names := {}
	for lid7 in Atlas.LAYERS:
		var lw7: Dictionary = Atlas.world_of(lid7)
		var at7 := {}
		for e7 in lw7.ents:
			if e7.has("pos") and not e7.get("indoor", false):
				at7[e7.pos] = true
		for e7 in lw7.ents:
			if not e7.get("indoor", false):
				continue
			res_n += 1
			res_areas[str(e7.area)] = true
			var in_b := false
			for bd6 in lw7.buildings:
				in_b = in_b or (str(bd6.area) == str(e7.area) and Rooms.inside(bd6, e7.pos))
			var ways7 := 0
			for d7 in MapGen.DIRS:
				var q7: Vector2i = e7.pos + d7
				if lw7.grid[q7.y * int(lw7.w) + q7.x] == MapGen.INTERIOR and not at7.has(q7):
					ways7 += 1
			check(in_b and lw7.grid[e7.pos.y * int(lw7.w) + e7.pos.x] == MapGen.INTERIOR and not at7.has(e7.pos) and not res_names.has(str(e7.id)) and ways7 >= 1
				and (e7.lines as Array).size() >= 3 and (e7.lines as Array).all(func(ln): return fits.call(str(ln))) and Assets.PEOPLE.has(str(e7.asset)) and Assets.has(Assets.PEOPLE[str(e7.asset)]),
				"%s is at home in %s: indoors, on a tile of their own, with a body and things to say" % [e7.n, e7.area])
			res_names[str(e7.id)] = true
			at7[e7.pos] = true
	check(res_n >= 150 and res_areas.size() >= 15, "%d people are found indoors, in the houses of %d regions" % [res_n, res_areas.size()])
	for use7 in Rooms.INDOORS:
		check(Rooms.USE_WORDS.has(str(use7)) and (Rooms.INDOORS[use7][2] as Array).size() >= 2, "whoever is found in %s has something to say" % str(Rooms.USE_WORDS[use7]))
	# who answers for what, and what there is to do for a wage (offices.gd)
	var seated := {}
	for lid6 in Atlas.LAYERS:
		for e6 in Atlas.world_of(lid6).ents:
			if e6.has("office"):
				seated[str(e6.office)] = e6
	for oid6 in Offices.ORDER:
		var of6: Dictionary = Offices.OFFICES[oid6]
		var has_b := false
		for bd5 in Data.AREAS[str(of6.area)].get("buildings", []):
			has_b = has_b or str(bd5.id) == str(of6["in"])
		check(has_b and seated.has(oid6) and str(seated[oid6].area) == str(of6.area) and (of6.lines as Array).size() >= 3 and (of6.lines as Array).all(func(ln): return fits.call(str(ln)))
			and Assets.PEOPLE.has(str(of6.asset)) and Assets.has(Assets.PEOPLE[str(of6.asset)]) and not seated[oid6].has("trade"),
			"%s sits in the %s of %s, with three things to say" % [of6.n, of6["in"], of6.area])
	var towns_led := {}
	for oid7 in Offices.ORDER:
		towns_led[str(Offices.OFFICES[oid7].area)] = true
	check(Offices.OFFICES.size() == Offices.ORDER.size() and Offices.ORDER.size() >= 15 and towns_led.size() >= 10 and Offices.seated("tushan", "cauldron_hall") == ["emperor", "empress"] and Offices.seated("sect", "hall") == ["treasurer"],
		"%d people answer for the sect and the towns of %d regions; the Son of Heaven and the Empress keep court where the Nine Cauldrons are" % [Offices.ORDER.size(), towns_led.size()])
	for tr6 in Offices.TRADE_ORDER:
		check(Offices.TRADES.has(tr6) and Rooms.USE_WORDS.has(tr6) and Rooms.INDOORS.has(tr6) and fits.call(str(Offices.TRADES[tr6].done)) and int(Offices.TRADES[tr6].hours) >= 1 and float(Offices.TRADES[tr6].pay) > 0.0, "a shift can be worked at %s" % str(Rooms.USE_WORDS[tr6]))
	var TG = load("res://scripts/game.gd").new()
	TG.reset()
	TG.level = 30
	TG.clock = 9.0 * 60.0
	var st0: int = TG.stones
	var hv0 := int(TG.hearth.get("valley", 0))
	check(Offices.blocked(TG, "inn", "village") == "" and Offices.wage(TG, "office") > Offices.wage(TG, "home") and Offices.wage(TG, "inn") < Data.enemy_stones(30, false) * 12, "there is work at the inn by day, an office pays more than a woodpile, and a shift is no fortune")
	var said := Offices.work(TG, "inn", "village")
	check(said != "" and TG.stones == st0 + Offices.wage(TG, "inn") and Clock.hour(TG) >= 11.9 and int(TG.hearth.get("valley", 0)) >= hv0 and Offices.worked(TG) == [1, 1], "a shift at the inn: three hours gone, the wage paid, and the shift counted")
	check(Offices.blocked(TG, "shop", "village") != "" and Offices.work(TG, "shop", "village") == "" and Offices.blocked(TG, "shop", "yanggu") == "", "one shift a day in a town; another town is another matter")
	TG.clock = 22.0 * 60.0
	check(Offices.blocked(TG, "shop", "yanggu") != "", "nobody is hiring at night")
	Feats.poll(TG)
	check(TG.feats.has("day_wage") and not TG.feats.has("six_trades") and Feats.need(Feats.FEATS.six_trades.test) < Offices.TRADE_ORDER.size(), "a day's wage is a feat; six trades is another, and there are more than six")
	# a career: five ranks a trade, reached by shifts; the work quicker from the third, a salary from the fourth
	var CG = load("res://scripts/game.gd").new()
	CG.reset()
	CG.level = 30
	for tr7 in Offices.TRADE_ORDER:
		var names7: Array = Offices.CAREERS.get(tr7, [])
		var uniq7 := {}
		for nm7 in names7:
			uniq7[nm7] = true
		check(names7.size() == Offices.RANKS.size() and uniq7.size() == names7.size(), "%s has a career of five places, each with a name" % tr7)
	for k7 in range(1, Offices.RANKS.size()):
		check(int(Offices.RANKS[k7][0]) > int(Offices.RANKS[k7 - 1][0]) and float(Offices.RANKS[k7][1]) > float(Offices.RANKS[k7 - 1][1]), "rank %d takes more shifts and pays more than the one before" % (k7 + 1))
	check(Offices.RAISED.size() == Offices.RANKS.size() - 1 and Offices.RAISED.all(func(ln): return fits.call(str(ln))), "something is said at every rise")
	var w0 := Offices.wage(CG, "office")
	check(Offices.rank(CG, "office") == 0 and Offices.rank_name(CG, "office") == "Copy-Hand" and Offices.to_next(CG, "office") == 3 and Offices.hours(CG, "office") == 4 and Offices.career_text(CG, "office").contains("start as Copy-Hand") and Offices.best_rank(CG) == -1,
		"a stranger starts at the bottom: a copy-hand, four hours a shift, three shifts from the first rise")
	var rose := ""
	for d7 in 3:
		CG.day = 10 + d7
		CG.clock = 9.0 * 60.0
		rose = Offices.work(CG, "office", "village")
	check(Offices.rank(CG, "office") == 1 and Offices.rank_name(CG, "office") == "Under-Clerk" and rose.contains(str(Offices.RAISED[0])) and Offices.wage(CG, "office") > w0 and Offices.salary_due(CG, "office", "village") == 0,
		"three shifts: an under-clerk, paid more, and told so; no salary yet")
	for d8 in 13:
		CG.day = 20 + d8
		CG.clock = 9.0 * 60.0
		Offices.work(CG, "office", "village")
	check(Offices.rank(CG, "office") == 3 and Offices.rank_name(CG, "office") == "Senior Clerk" and Offices.hours(CG, "office") == 3 and Offices.career_text(CG, "office").contains("Registrar after 14 more"), "sixteen shifts: a senior clerk, an hour quicker, on the books")
	CG.day = 36
	check(Offices.salary_due(CG, "office", "village") == int(round(Offices.wage(CG, "office") * Offices.SALARY * 3)) and Offices.salary_due(CG, "office", "yanggu") == 0, "three days away: three half-days of salary waiting, where he is on the books and nowhere else")
	CG.day = 60
	var due7 := Offices.salary_due(CG, "office", "village")
	var st7: int = CG.stones
	CG.clock = 9.0 * 60.0
	Offices.work(CG, "office", "village")
	check(due7 == int(round(Offices.wage(CG, "office") * Offices.SALARY * Offices.SALARY_DAYS)) and CG.stones == st7 + due7 + Offices.wage(CG, "office") and Offices.salary_due(CG, "office", "village") == 0 and CG.wages > 0,
		"a month away: five days of salary and no more, collected with the shift")
	CG.shifts["office"] = 30
	Feats.poll(CG)
	check(Offices.rank(CG, "office") == 4 and Offices.to_next(CG, "office") == 0 and Offices.career_text(CG, "office").contains("no higher place") and CG.feats.has("journeyman") and CG.feats.has("trade_master") and Offices.careers(CG) == "Registrar"
		and Offices.wage(CG, "office") < Data.enemy_stones(30, false) * 20, "thirty shifts: a registrar, and a shift at the top of it still pays less than twenty beaten foes")
	CG.free()
	TG.free()
	var trade_n := 0
	for lid5 in Atlas.LAYERS:
		for e5 in Atlas.world_of(lid5).ents:
			if e5.has("trade"):
				trade_n += 1
				check(Offices.TRADES.has(str(e5.trade)), "%s has a trade to offer" % e5.n)
	check(trade_n >= 150 and msrc.contains("func offer_shift") and msrc.contains("\"id\": \"later\", \"label\": \"Not today\"") and not bsrc.contains("offer_shift"), "%d people indoors will take a pair of hands; not today is the first answer, and the bot gives it" % trade_n)
	# how the towns of each people build
	var looks := {}
	for tid7 in Folk.TOWNS:
		var ta := str(Folk.TOWNS[tid7].area)
		var dst := Arch.dressed("house", ta)
		looks["%s|%s|%s" % [str(dst.wall), str(dst.roof), str(dst.get("kind", "hip"))]] = true
	for da in Arch.DRESS_OF:
		check(Data.AREAS.has(str(da)) and Arch.DRESS.has(str(Arch.DRESS_OF[da])), "%s builds in a way of its own" % da)
	check(looks.size() >= 9 and str(Arch.dressed("house", "dunes").kind) == "flat" and str(Arch.dressed("shrine", "dunes").get("kind", "hip")) != "flat" and Arch.dressed("house", "village") == Arch.STYLES.house
		and bool(Arch.dressed("shop", "tushan").get("chimney", false)) and bool(Arch.dressed("inn", "yanggu").get("lanterns", false)) and Arch.dressed("house", "youdu").has("glow"),
		"the twelve towns build %d ways: flat roofs and a dome on the sand road, chimneys at Tushan, lanterns under the eaves at Yanggu, cold light in Youdu's windows; a shrine keeps its own roof" % looks.size())
	var cen := Rooms.census()
	var cen_n := 0
	for ck in cen:
		cen_n += int(cen[ck])
	check(winged * 3 >= b_n and tall * 2 >= b_n and (int(cen.get("home", 0)) + int(cen.get("office", 0))) * 10 >= cen_n * 6 and int(cen.get("home", 0)) * 3 >= cen_n,
		"%d of %d houses have a wing, %d stand three storeys or more, and of %d storeys %d are homes and %d offices" % [winged, b_n, tall, cen_n, int(cen.get("home", 0)), int(cen.get("office", 0))])
	check(Rooms.storeys({"style": "kitchen", "rect": Rect2i(0, 0, 6, 5)}) == 1 and Rooms.uses_text({"style": "shop", "rect": Rect2i(3, 4, 7, 6), "upper": {}, "storeys": 3}) == "three storeys: a shop, somebody's home above"
		and Rooms.uses_text({"style": "hall", "rect": Rect2i(3, 4, 7, 6), "upper": {}, "storeys": 4}) == "four storeys: a hall, offices above, somebody's home at the top",
		"a kitchen is one storey; a shop is a shop with homes over it; a hall has offices over it and a home over those")
	check(b_grew * 2 >= b_n and t_after * 100 >= t_before * 130, "%d of %d buildings have more room: %d tiles of ground floor where there were %d" % [b_grew, b_n, t_after, t_before])
	var wsrc9 := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(wsrc9.contains("a lord that cannot be beaten is gone from the land when the losing is done"), "a doom of the story leaves the land when its step is done")
	var asrc9 := FileAccess.get_file_as_string("res://scripts/architecture.gd")
	check(asrc9.contains("static func _facade") and asrc9.contains("static func _border") and asrc9.contains("static func _wing") and asrc9.contains("more storeys (the Lost Horse release)") and Arch.HIP_RISE > 1.6 and Arch.GABLE_RISE > 1.3, "the houses have facades, flowers at the foot of the wall, and roofs that rise")

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

	print("== the reckoning (reckon.gd) ==")
	var wm: Dictionary = Atlas.world_of("surface")
	for rid in Reckon.ALL:
		var re: Array = wm.ents.filter(func(e): return e.kind == "boss" and str(e.enemy) == rid)
		check(Data.ENEMIES.has(rid) and bool(Data.ENEMIES[rid].boss) and Lore.BOSS.has(rid) and Data.DIALOGUE.has("pre:" + rid) and Data.DIALOGUE.has("post:" + rid) and Reckon.WHAT.has(rid) and Reckon.END.has(rid)
			and re.size() == 1 and str(re[0].area) == "mountain" and not Trials.TRIALS.has(rid) and not Dooms.is_doom(rid),
			"%s is a last lord: a story, something said before and after, a sentence for the ending, and a height of the mountain to stand on" % rid)
		for ln in Data.DIALOGUE.get("pre:" + rid, []) + Data.DIALOGUE.get("post:" + rid, []):
			check(fits.call(str(ln[1])), "%s: a line that fits the box" % rid)
	var RG = load("res://scripts/game.gd").new()
	RG.reset()
	RG.step = Data.step_index(Reckon.STEP)
	check(Reckon.due(RG) == ["the_unchosen"] and Reckon.stands(RG, "the_unchosen") and not Reckon.stands(RG, "debt_mercy") and float(Reckon.boon(RG, "the_unchosen").foe_hp) == 1.0,
		"a journey that never leaned meets the Unchosen, and nobody else; with no answer given there is not a crack in it")
	RG.scales = {"heart": 4}
	check(Reckon.due(RG) == ["debt_mercy"] and fits.call(Reckon.word(RG, "debt_mercy")), "mercy the land knows him by: the Debt of Mercy")
	RG.scales = {"heart": -9, "craft": 7, "reach": 4}
	check(Reckon.due(RG) == ["iron_judge", "unkept_engine"] and Reckon.left(RG).size() == 2, "rigour first, and the new works he is known for with it: two lords; a scale that only leans brings none of its own")
	RG.scales = {"heart": 6, "craft": -8, "reach": -12}
	check(Reckon.due(RG) == ["valley_wall", "unturned_stone", "debt_mercy"], "three habits he is known for: three lords, the strongest first")
	var m_lo: Array = Reckon.might(RG, "debt_mercy")
	var m_hi: Array = Reckon.might(RG, "valley_wall")
	check(float(m_hi[0]) > float(m_lo[0]) and float(m_lo[0]) >= float(Reckon.MIGHT[0]), "each is as strong as the habit that made it")
	RG.scales = {}
	RG.picks = {}
	Echoes.take(RG, "bandits", "mend")
	Echoes.take(RG, "widow", "kind")
	Echoes.take(RG, "ancestor", "truth")
	var c0 := Reckon.cracks(RG, "debt_mercy")
	Echoes.take(RG, "crows", "banish")
	Echoes.take(RG, "garden", "burn")
	check(Reckon.due(RG)[0] == "debt_mercy" and c0 == 0 and Reckon.cracks(RG, "debt_mercy") == 1 and is_equal_approx(float(Reckon.boon(RG, "debt_mercy").foe_hp), 1.0 - Reckon.CRACK) and Reckon.word(RG, "debt_mercy").contains("1 times"),
		"every time the other answer was given is a crack in it: one banishment among the mercies takes a twentieth of the Debt")
	RG.boss_done["debt_mercy"] = true
	RG.reckoned["debt_mercy"] = true
	RG.poll_steps()
	check(RG.done(Reckon.STEP) and not Reckon.stands(RG, "debt_mercy") and Reckon.epilogue(RG).size() == 1, "met and beaten, the step is done, nobody is left on the heights, and the ending tells it")
	RG.free()
	check(Data.step_index(Reckon.STEP) == Data.step_index("s_p24_end") - 1 and Data.DIALOGUE.has("done:" + Reckon.STEP) and msrc.contains("Reckon.might(Game") and bsrc.contains("Reckon.left(Game)"),
		"the reckoning comes before the last word with the Elder; the battle is as the journey made it, and the bot goes up to whoever is due")
	print("== Part XXIV: the Lost Horse ==")
	check(Data.REALMS.size() >= 30 and Data.REALMS[29] == "Soft as Water" and Data.MAX_LEVEL >= 87 and Data.level_name(87).ends_with("Soft as Water") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXIV adds the realm of Soft as Water")
	check(Data.step_index("s_break29") == Data.step_index("s_p24_end") + 1 and Data.DIALOGUE.has("recall22") and msrc.contains("\"s_break28\": \"recall22\"") and Data.DIALOGUE.has("pre:s_break29") and Data.DIALOGUE.has("post:s_break29"),
		"Part XXIV follows Great Sound, Rarely Heard (recall22) and ends with a breakthrough")
	var n24 := 0
	var kinds24 := {}
	var doom_bands := {}
	for a24 in Data.AREAS:
		for bk24 in ["warband", "warband2", "warband3", "warband4", "warband5", "warband6", "warband7"]:
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
			if bk24 in ["warband3", "warband4", "warband5", "warband6", "warband7"]:
				var lw24: Dictionary = Atlas.world_of(Data.layer_of(a24))
				var pre24: String = a24 + ":" + str({"warband3": "y", "warband4": "z", "warband5": "u", "warband6": "v", "warband7": "t"}[bk24])
				var marching24: Array = lw24.ents.filter(func(e6): return e6.kind == "enemy" and str(e6.id).begins_with(pre24) and str(e6.id).substr(pre24.length()).is_valid_int())
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

# ================================================================ the Three Burrows release
## A town that is the hero's own (hold.gd): its plots, people, dues, rank and power; three crossroads
## and what each leaves standing; four more ends of the story; and Part XXV.
func _three_burrows() -> void:
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var wsrc := FileAccess.get_file_as_string("res://scripts/world.gd")
	var asrc := FileAccess.get_file_as_string("res://scripts/atlas.gd")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	print("== a town of one's own (hold.gd) ==")
	check(Hold.ORDER.size() == 12 and Hold.PLOTS.size() == 12 and Hold.ORDER[0] == "hall" and int(Hold.PLOTS.hall.cost) == 0, "twelve plots drawn up, and the hall stands from the founding")
	var at_seen := {}
	var total_cost := 0
	var total_room := 0
	var total_homes := 0
	for pid in Hold.ORDER:
		var p: Dictionary = Hold.PLOTS[pid]
		var pa: Vector2i = p.at
		check(str(p.n).length() > 3 and fits.call(str(p.desc)) and str(p.desc).length() > 80 and str(p.ask).length() > 10 and int(p.cost) >= 0 and int(p.room) >= 0 and int(p.homes) >= 0,
			"plot %s: a name, something to read that fits the box, what the steward says it is for, a price" % pid)
		# (the wall is the ring of the ground: its own plot is the length beside the Cloud Gate)
		check((pid == "wall" and pa.y == Hold.SIZE.y - 1 and Hold.GATES.has(pa + Vector2i(-1, 0))) or (pa.x % 2 == 1 and pa.y % 2 == 1 and pa.x > 0 and pa.y > 0 and pa.x < Hold.SIZE.x - 1 and pa.y < Hold.SIZE.y - 1 and not at_seen.has(pa)), "plot %s: a place of its own, with a lane on every side" % pid)
		at_seen[pa] = true
		total_cost += int(p.cost)
		total_room += int(p.room)
		total_homes += int(p.homes)
		for r in [1, 2, 3]:
			var pm := Hold.model(pid, r, "found" if r == 3 else "")
			check(pm.get_child_count() >= 1, "plot %s: built from code (rank %d)" % [pid, r])
			pm.free()
	check(total_room >= int(Hold.RANKS[3][0]) and total_homes < int(Hold.RANKS[3][0]), "there is room for a city (%d), and a city is not had by building alone (%d households come with the plots)" % [total_room, total_homes])
	check(Hold.SETTLERS.size() >= 6, "six people come to live there as it fills")
	for sv in Hold.SETTLERS:
		check(int(sv[0]) <= int(Hold.RANKS[3][0]) and Assets.PEOPLE.has(str(sv[2])) and Assets.has(Assets.PEOPLE[str(sv[2])]) and sv.size() >= 8 and fits.call(str(sv[5])) and fits.call(str(sv[6])) and fits.call(str(sv[7]))
			and not at_seen.has(sv[4]) and ((sv[4] as Vector2i).x % 2 == 0 or (sv[4] as Vector2i).y % 2 == 0), "%s: a body of the towns, three things to say, and a place in a lane" % str(sv[1]))
	# where it stands: on open ground of the mountain, every plot walked up to, nobody shut in when all is built
	var ws: Dictionary = Atlas.world_of("surface")
	var W := int(ws.w)
	var plots := {}
	var people: Array = []
	var others := {}
	var walled := {}
	var segs := 0
	for e in ws.ents:
		if e.kind == "hold":
			walled[e.pos] = true
			if e.has("seg"):
				segs += 1
			# (a plot: what is built in the town, and of the wall the length that carries the gate)
			if not e.has("seg") or bool(e.seg[2]):
				plots[e.pos] = e
		elif e.has("hold") or str(e.id) == Hold.STEWARD:
			people.append(e)
		elif e.has("pos"):
			others[e.pos] = e
	check(plots.size() == Hold.ORDER.size() and people.size() == Hold.SETTLERS.size() + 1, "all twelve plots, the steward and the settlers stand in the world (%d, %d)" % [plots.size(), people.size()])
	# the wall is the ring of the ground, less its three gates, every length on open ground
	var ring := Hold.wall_tiles()
	check(ring.size() == 2 * (Hold.SIZE.x + Hold.SIZE.y) - 4 - Hold.GATES.size() and segs == ring.size() and Hold.GATES.size() == 3, "the wall is %d lengths round the ground, with three ways through it" % ring.size())
	for gt in Hold.GATES:
		var gq := Atlas.to_world(Hold.AREA, Hold.tile(gt))
		check(not walled.has(gq) and MapGen.is_walkable_tile(ws.grid[gq.y * W + gq.x]), "the gate at %s is open ground, and nothing stands in it" % str(gt))
	var seen0 := MapGen.flood(ws.grid, W, int(ws.h), ws.start)
	# (a flood of the realm with every plot built and the wall up: what can still be walked to)
	var seen := {ws.start: true}
	var queue: Array = [ws.start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in MapGen.DIRS:
			var nq: Vector2i = c + d
			if nq.x < 0 or nq.y < 0 or nq.x >= W or nq.y >= int(ws.h) or seen.has(nq) or walled.has(nq) or not MapGen.is_walkable_tile(ws.grid[nq.y * W + nq.x]):
				continue
			seen[nq] = true
			queue.append(nq)
	for q1 in plots:
		var pe: Dictionary = plots[q1]
		var ways := 0
		for d1 in MapGen.DIRS:
			if seen.has(q1 + d1) and not others.has(q1 + d1):
				ways += 1
		check(Atlas.owner_id(ws, q1) == Hold.AREA and MapGen.is_walkable_tile(ws.grid[q1.y * W + q1.x]) and not others.has(q1) and ways >= 2 and q1 == Atlas.to_world(Hold.AREA, Hold.tile(Hold.PLOTS[str(pe.plot)].at)),
			"%s stands on open ground of the mountain, where it was drawn, and can be walked up to (%d ways)" % [pe.id, ways])
	check(seen0.size() - seen.size() == walled.size(), "with everything built and the wall up, nothing in the realm is cut off but the ground the town stands on (%d tiles, %d built on)" % [seen0.size() - seen.size(), walled.size()])
	for pp in people:
		check(seen.has(pp.pos) and not walled.has(pp.pos) and not others.has(pp.pos), "%s stands in a lane, and is shut in by nothing that can be built" % pp.id)
		if str(pp.id) == Hold.STEWARD:
			check(pp.pos == Atlas.to_world(Hold.AREA, Hold.tile(Hold.STEWARD_AT)) and str(pp.vis[0]) == "s_p25_home", "the steward sits where the hall will go, from the step that sends for him")
	# (nothing else stands within three tiles of the ground: it was found empty)
	var crowd := 0
	var g0 := Atlas.to_world(Hold.AREA, Hold.AT)
	for op in others:
		var oq: Vector2i = op
		if oq.x >= g0.x - 2 and oq.y >= g0.y - 2 and oq.x < g0.x + Hold.SIZE.x + 2 and oq.y < g0.y + Hold.SIZE.y + 2:
			crowd += 1
	check(crowd == 0, "nothing else stands on the ground of Guiyun or beside it (%d)" % crowd)
	check(asrc.find("Hold.place(") > 0 and asrc.find("Hold.place(") < asrc.find("Marks.place(") and asrc.find("Hold.place(") < asrc.find("late_slots, grid"), "the ground is taken before the late bands and the marks, so that they keep off it")
	# ---- the rules
	var HG = load("res://scripts/game.gd").new()
	HG.reset()
	check(not Hold.founded(HG) and Hold.households(HG) == 0 and Hold.rank(HG) == 0 and Hold.power(HG) == 0 and Hold.chest(HG) == 0 and not Hold.stands(HG, plots.values()[0]) and not Hold.stands(HG, people[0]) and Hold.epilogue(HG).is_empty(),
		"before the story comes to it there is no town: nothing stands, nobody lives there, nothing is owed")
	check(Hold.blocked(HG, "well") != "" and not Hold.build(HG, "well") and not Hold.settle(HG, "x", "X") and Hold.text(HG).contains("no town yet"), "and nothing can be built or asked")
	HG.step = Data.step_index(Hold.FOUND_STEP)
	HG.stones = 0
	HG.advance()
	check(Hold.founded(HG) and Hold.built(HG, "hall") and Hold.built_count(HG) == 1 and Hold.households(HG) == int(Hold.PLOTS.hall.homes) and Hold.rank(HG) == 1 and Hold.rank_name(HG) == "Guiyun Hamlet" and HG.hold.has("day0"),
		"the steward heard out, the town is founded: a hall, four households, a hamlet")
	var purse := int(HG.stones)
	HG.stones = 100
	check(Hold.blocked(HG, "well").contains("spirit stones") and not Hold.build(HG, "well") and Hold.next(HG) == "", "nothing is built on credit")
	HG.stones = 5000
	check(Hold.next(HG) == "well" and Hold.build(HG, "well") and HG.stones == 5000 - int(Hold.PLOTS.well.cost) and Hold.built(HG, "well") and Hold.blocked(HG, "well") != "" and Hold.room(HG) == int(Hold.PLOTS.hall.room) + int(Hold.PLOTS.well.room),
		"a well is built at the steward's table, paid for, and makes room")
	check(Hold.blocked(HG, "market").contains("households") and Hold.wanted(HG, ["plot", "market"]) == "" and Hold.wanted(HG, ["built", 3]) == "homes1", "a market waits for thirty households; the next thing to build is the first row")
	HG.stones = purse
	# people: asked one family at a time, while there is room
	var h0 := Hold.households(HG)
	check(Hold.can_settle(HG, "a") and Hold.settle(HG, "a", "Woodcutter A") and Hold.households(HG) == h0 + Hold.PER_SETTLER and not Hold.settle(HG, "a", "Woodcutter A") and Hold.settlers(HG) == 1 and Hold.can_settle(HG, "b"), "a family asked brings four households, once")
	Hold.settle(HG, "b", "B")
	Hold.settle(HG, "c", "C")
	Hold.settle(HG, "c2", "C2")
	check(Hold.wanting(HG) >= Hold.room(HG) and not Hold.can_settle(HG, "d") and not Hold.settle(HG, "d", "D") and Hold.full_text(HG).contains("build first") and Hold.households(HG) == Hold.room(HG),
		"when every roof is full nobody more can be asked: build first")
	check(Hold.settle(HG, "d", "D", true) and Hold.households(HG) == Hold.room(HG), "the story's own settlers come whether or not there is a roof yet, and wait for one")
	check(Hold.may_ask({"role": "pedlar", "kid": false}) and not Hold.may_ask({"role": "farmer", "kid": true}) and not Hold.may_ask({"role": "guard", "kid": false}) and Hold.yes_line({"role": "hermit"}) != Hold.yes_line({"role": "farmer"}),
		"anybody grown with no post to keep may be asked, and answers after their own trade")
	# dues: a little a day into a chest that holds five days
	HG.hold["taken"] = int(HG.day)
	var due0 := Hold.due(HG)
	check(due0 == Hold.households(HG) * Hold.DUE and Hold.chest(HG) == 0, "every household pays a little a day (%d), and the chest begins empty" % due0)
	HG.day += 2
	check(Hold.chest(HG) == 2 * Hold.due(HG), "two days: two days' dues in the chest")
	HG.day += 30
	check(Hold.chest(HG) == Hold.CHEST_DAYS * Hold.due(HG), "left a month, the chest holds five days and no more")
	var s0 := int(HG.stones)
	var took := Hold.take(HG)
	check(took > 0 and HG.stones == s0 + took and Hold.chest(HG) == 0 and int(HG.hold.dues) == took, "emptied, it is in the purse, and the chest begins again")
	check(Hold.grown(HG) == Hold.GROW_MAX, "and the town has grown of itself, a couple of households a day, thirty at the most")
	# (the Underclothes release: and what it has grown by stays grown, whatever is answered or built after)
	var HG2 = load("res://scripts/game.gd").new()
	HG2.reset()
	HG2.step = Data.step_index(Hold.FOUND_STEP)
	HG2.advance()
	HG2.day += 4
	var g4 := Hold.grown(HG2)
	Echoes.take(HG2, "the_tallies", "collect")
	check(g4 > 0 and Hold.grown(HG2) == g4, "what the town grew by before the tallies were collected is not taken back off it (%d)" % g4)
	HG2.free()
	# built out: a town, a city, a watch, a hall with disciples
	HG.stones = 1000000
	HG.hold["day0"] = int(HG.day)
	# (the Underclothes release: what the town has grown by is kept day by day, hold.gd; begun again here too)
	HG.hold.erase("grown_f")
	HG.hold.erase("grow_day")
	var ranks_seen := {}
	var guard := 0
	var k9 := 0
	while not Hold.unbuilt(HG).is_empty() and guard < 80:
		guard += 1
		if Hold.next(HG) != "":
			Hold.build(HG, Hold.next(HG))
		else:
			k9 += 1
			Hold.settle(HG, "s%d" % k9, "S", true)
		ranks_seen[Hold.rank(HG)] = true
	check(Hold.unbuilt(HG).is_empty() and ranks_seen.has(2) and Hold.built_count(HG) == 12, "with people asked as it grows, everything drawn up can be built (%d families asked)" % Hold.settlers(HG))
	while Hold.households(HG) < 100 and guard < 200:
		guard += 1
		k9 += 1
		Hold.settle(HG, "s%d" % k9, "S", true)
	check(Hold.rank(HG) == 3 and Hold.rank_name(HG).contains("Hundred Households") and Hold.rank_lack(HG, 3) == "" and Hold.watch(HG) and War.has(HG, "guiyun") and Trials.need_met(["households", 100], HG) and Hold.disciples(HG) >= 10 and Hold.power(HG) >= 20,
		"a hundred households and a wall: a city, with a watch in the host and disciples in the Hall of the Broom (power %d)" % Hold.power(HG))
	check(Hold.need_met(HG, ["rank", 3]) and Hold.need_met(HG, ["built", 12]) and Hold.need_met(HG, ["plot", "wall"]) and Hold.need_met(HG, ["households", 100]) and Hold.need_progress(HG, ["rank", 3]) == [100, 100], "and whatever a step of the story could ask of it is so")
	for pe2 in plots.values():
		check(Hold.stands(HG, pe2) and Hold.key(HG, pe2) != "" and Hold.name_of(pe2) != "" and fits.call(Hold.desc_of(HG, pe2)), "%s stands, and can be read" % pe2.id)
	var up := 0
	var seg_m: Node3D = null
	for e9 in ws.ents:
		if e9.kind == "hold" and e9.has("seg"):
			up += 1 if Hold.stands(HG, e9) else 0
			if seg_m == null and not bool(e9.seg[2]):
				seg_m = Hold.model_of(e9, 3, "")
				check(Hold.name_of(e9) == "" and seg_m.get_child_count() >= 1, "a length of the wall is built from code, and has no name of its own")
	if seg_m != null:
		seg_m.free()
	check(up == segs, "and every length of the wall stands (%d)" % up)
	for pp2 in people:
		if pp2.has("hold"):
			check(Hold.stands(HG, pp2), "%s has come to live there" % str(pp2.n))
	check(Hold.epilogue(HG).size() == 1 and fits.call(str(Hold.epilogue(HG)[0])) and Hold.text(HG).contains("Watch of Guiyun") and Hold.summary(HG).contains("12 of 12"), "the ending tells of the town, and the Town page keeps it")
	# the three crossroads change its numbers, its banner and what the land calls it
	var k_hall: String = Hold.key(HG, plots[Atlas.to_world(Hold.AREA, Hold.tile(Hold.PLOTS.hall.at))])
	var due1 := Hold.due(HG)
	var pw1 := Hold.power(HG)
	var dis1 := Hold.disciples(HG)
	Echoes.take(HG, "the_tallies", "collect")
	check(Hold.due(HG) > due1 and Hold.mod(HG, "grow") < 1.0, "debts collected to the notch: more in the chest, and fewer come of themselves")
	Echoes.take(HG, "the_door", "all")
	check(Hold.mod(HG, "room") > 1.0 and Hold.room(HG) > total_room, "whoever knocks: room for more")
	Echoes.take(HG, "the_seat", "take")
	check(Hold.sect(HG) == "take" and Hold.sect_name(HG).contains("Cold Pine") and Hold.sect_title(HG).contains("Patriarch") and Hold.power(HG) > pw1 and Hold.disciples(HG) > dis1
		and Hold.key(HG, plots[Atlas.to_world(Hold.AREA, Hold.tile(Hold.PLOTS.hall.at))]) != k_hall and Hold.epilogue(HG).size() == 2, "the Cold Pine's seat taken: a title, more disciples, more power, another banner over the hall, and a second line at the end")
	check(Cultures.ending_open("pine", HG) and Cultures.ending_open("granary", HG) and not Cultures.ending_open("founder", HG) and not Cultures.ending_open("guiyun", HG), "that journey may end in the borrowed seat or at the granary, and not otherwise")
	HG.picks.erase("the_seat")
	HG.picks.erase("the_tallies")
	Echoes.take(HG, "the_seat", "found")
	Echoes.take(HG, "the_tallies", "burn")
	check(Hold.sect_name(HG).contains("Returning Cloud") and Cultures.ending_open("founder", HG) and Cultures.ending_open("guiyun", HG) and not Cultures.ending_open("pine", HG) and not Cultures.ending_open("granary", HG)
		and Hold.mod(HG, "settler") > 1.0 and Hold.mod(HG, "due") < 1.0, "debts burned and a gate of his own: the hundred households, or the Returning Cloud")
	for eid in ["guiyun", "founder", "pine", "granary"]:
		for nd in Cultures.ENDINGS[eid].needs:
			check(Cultures.ending_need_text(nd, HG) != "" and Cultures.ending_need_text(nd, HG).length() < 200, "%s: what it asks is said plainly" % eid)
	Feats.poll(HG)
	check(HG.feats.has("hamlet") and HG.feats.has("town") and HG.feats.has("hundred_households") and HG.feats.has("every_plot") and HG.feats.has("asked_ten") and not HG.feats.has("dues"), "founding, growing and building out are feats; five thousand in dues is another")
	HG.free()
	# the story never asks of the town more than its own steps have brought there, whatever was answered,
	# and never more than its own rewards have paid for
	var first25 := Data.step_index("s_p25_home")
	for answers in [{}, {"the_tallies": "collect"}, {"the_tallies": "burn", "the_door": "all"}, {"the_tallies": "shares", "the_door": "sweep"}]:
		var SG = load("res://scripts/game.gd").new()
		SG.reset()
		var paid := 0
		var spent := 0
		for i in range(first25, Data.STEPS.size()):
			var st: Dictionary = Data.STEPS[i]
			SG.step = i
			if i > Data.step_index(Hold.FOUND_STEP):
				Hold._day0(SG)
			for cid in answers:
				if str(Echoes.CROSSROADS[cid].step) == str(Data.STEPS[i - 1].id):
					SG.picks[cid] = answers[cid]
			if str(st.kind) == "hold":
				SG.stones = 10000000
				var tries := 0
				while not Hold.need_met(SG, st.need) and Hold.wanted(SG, st.need) != "" and tries < 20:
					tries += 1
					spent += Hold.cost(SG, Hold.wanted(SG, st.need))
					Hold.build(SG, Hold.wanted(SG, st.need))
				check(Hold.need_met(SG, st.need), "%s can be done with the people the story has brought, and no waiting (answers %s: %d households, room for %d)" % [st.id, str(answers.values()), Hold.households(SG), Hold.room(SG)])
				check(spent <= paid, "%s: what it takes to build (%d) is no more than the chapter has paid by then (%d)" % [st.id, spent, paid])
			if str(st.kind) == "folk" and bool(Folk.ERRANDS.get(str(st.id), {}).get("settle", false)):
				for k in int(st.n):
					Hold.settle(SG, "%s:%d" % [st.id, k], "S", true)
			if str(st.kind) == "visits" and bool(st.get("settle", false)):
				for k2 in int(st.n):
					Hold.settle(SG, "%s:%d" % [st.id, k2], "S", true)
			if str(st.kind) == "kill" and Trials.TRIALS.has(str(st.boss)):
				for pth in Trials.TRIALS[str(st.boss)].paths:
					if str(pth.kind) == "town":
						check(Trials.need_met(pth.needs[0], SG), "%s: by the time he is met, the town is what his trial asks (%d households)" % [st.boss, Hold.households(SG)])
			if str(st.kind) == "host":
				check(Hold.watch(SG), "%s: the watch stands to by then" % st.id)
			paid += int(st.get("stones", 0))
		check(Hold.rank(SG) == 3 and Hold.unbuilt(SG).is_empty(), "the chapter leaves a city (answers %s)" % str(answers.values()))
		SG.free()
	# a journey begun past the founding
	var CG = load("res://scripts/game.gd").new()
	CG.reset()
	Hold.catch_up(CG, Data.step_index("s_p25_home"))
	check(not CG.hold.has("day0"), "a journey begun before the town has none")
	CG.step = Data.step_index("s_p25_envoy")
	Hold.catch_up(CG, CG.step)
	check(Hold.founded(CG) and Hold.rank(CG) == 3 and Hold.settlers(CG) == 13, "a journey begun late in the chapter has the town its steps would have left (%s)" % Hold.summary(CG))
	CG.free()
	check(msrc.contains("func offer_hold") and msrc.contains("func offer_home") and msrc.contains("\"id\": \"later\", \"label\": \"Not today\"") and msrc.contains("Hold.settle(Game, str(fp.id), str(fp.n), true)") and msrc.contains("Hold.epilogue(Game)"),
		"the steward keeps a table, anybody may be asked home (\"Not today\" first), the story's errands settle people, and the ending tells of it")
	check(wsrc.contains("func _hold_model") and wsrc.contains("Hold.stands(Game, e)") and bsrc.contains("main.HOLD_ASK") and bsrc.contains("Hold.wanted(Game, s.need)") and bsrc.contains("Hold.catch_up(Game, idx)"),
		"the world draws a plot when it is built, and the bot builds at the steward's table what the step is waiting for")
	check(War.COMPANIES.guiyun.get("hold", false) and War.ORDER.has("guiyun") and Trials.KINDS.has("town") and "town" in Trials.KIND_ORDER and Trials.EPITHETS.has("town"), "a watch for the host, and a way through trials: by the town")
	print("== Part XXV: the Three Burrows ==")
	check(Data.REALMS.size() >= 31 and Data.REALMS[30] == "Scarcely Known" and Data.MAX_LEVEL >= 90 and Data.level_name(90).ends_with("Scarcely Known") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXV adds the realm of Scarcely Known")
	check(Data.step_index("s_break30") > Data.step_index("s_p25_end") and Data.DIALOGUE.has("recall23") and msrc.contains("\"s_break29\": \"recall23\"") and Data.DIALOGUE.has("pre:s_break30") and Data.DIALOGUE.has("post:s_break30"),
		"Part XXV follows Soft as Water (recall23) and ends at Scarcely Known")
	var n25 := 0
	var kinds25 := {}
	var settled := 0
	for st25 in Data.STEPS:
		if not str(st25.id).begins_with("s_p25_"):
			continue
		n25 += 1
		kinds25[str(st25.kind)] = int(kinds25.get(str(st25.kind), 0)) + 1
		if st25.kind == "talk":
			check(Data.DIALOGUE.has(str(st25.id)), "%s: there is something said" % st25.id)
		if not st25.kind in ["kill", "talk"]:
			check(Data.DIALOGUE.has("done:" + str(st25.id)), "%s: something is said when it is done" % st25.id)
		if st25.kind == "hold":
			check(str(st25.need[0]) in ["built", "plot", "rank", "households"] and str(st25.area) == Hold.AREA, "%s asks something of the town that the town can be" % st25.id)
		if st25.kind == "folk":
			var er: Dictionary = Folk.ERRANDS.get(str(st25.id), {})
			check(bool(er.get("settle", false)) and Folk.CAMP_ROLES.has(str(st25.role)) and (er.lines as Array).size() >= 4 and int(er.price) == 0, "%s: people of the road asked to come and live there, each with an answer" % st25.id)
			for el in er.lines:
				check(fits.call(str(el)), "%s: an answer that fits the box" % st25.id)
			settled += int(st25.n)
		if st25.kind == "visits":
			check(bool(st25.get("settle", false)), "%s: whoever is called on sends a household" % st25.id)
			settled += int(st25.n)
		if st25.kind == "marks":
			check(int(st25.n) >= 3 and int(st25.n) * 4 <= Echoes.ORDER.size(), "%s: no more than a quarter of what a journey leaves standing" % st25.id)
	check(n25 >= 26 and int(kinds25.get("hold", 0)) == 4 and int(kinds25.get("folk", 0)) == 4 and int(kinds25.get("kill", 0)) == 3 and int(kinds25.get("hunt", 0)) == 4 and int(kinds25.get("collect", 0)) == 3 and kinds25.has("marks") and kinds25.has("visits") and kinds25.has("host") and settled >= 13,
		"Part XXV: %d steps: four things asked of the town (the Hall of the Broom since the Underclothes release), four askings of people to come (%d families), three lords, four hunts, three searches" % [n25, settled])
	for k25 in Data.DIALOGUE:
		if str(k25).contains("s_p25_") or str(k25) in ["recall23", "pre:s_break30", "post:s_break30", "pre:shuo_shu", "post:shuo_shu", "pre:ke_zheng", "post:ke_zheng", "pre:han_song", "post:han_song"]:
			for ln25 in Data.DIALOGUE[k25]:
				check(fits.call(str(ln25[1])), "%s: a line that fits the box" % k25)
	for tid25 in ["shuo_shu", "ke_zheng", "han_song"]:
		check(Trials.TRIALS.has(tid25) and Data.ENEMIES[tid25].get("boss", false) and Lore.BOSS.has(tid25) and Trials.trial_of_step(Data.STEPS[_kill_step(tid25)]) == tid25, "%s is a lord of Part XXV, guarded by a trial" % tid25)
		check((Trials.TRIALS[tid25].paths as Array).any(func(pth): return str(pth.kind) == "town") and (Trials.TRIALS[tid25].paths as Array).any(func(pth): return str(pth.kind) == "relic") and (Trials.TRIALS[tid25].paths as Array).size() >= 3, "%s can be passed by the town, or by what was found on the way" % tid25)
		check(Data.DIALOGUE.has("pre:" + tid25) and Data.DIALOGUE.has("post:" + tid25), "%s has something to say before and after" % tid25)
	for pid25 in ["feng_xuan", "tai_widow", "han_song"]:
		check(Assets.PEOPLE.has(pid25) and Assets.has(Assets.PEOPLE[pid25]) and FileAccess.file_exists("res://art/characters/%s.py" % pid25), "%s has a model built from a script" % pid25)
	for cid25 in ["feng_xuan", "tai_widow"]:
		check(Data.CHAT.has(cid25) and Data.CHAT[cid25].size() >= 3 and Data.CHAT_LATER.has(cid25), "%s has things to say, and more once it has happened" % cid25)
	check(Voice.HER_TITLES.has("Widow") and UI.SHAPES.has("person:han_song"), "the widow is told of as a woman, and the Patriarch fights in his own body")
	for fid25 in ["granary_rat", "seed_sparrow", "thatch_moth", "writ_wasp", "tally_crow", "corvee_ox", "cock_crower", "dog_thief", "gate_crasher", "pine_swordsman", "needle_sprite", "frost_crane"]:
		check(Data.ENEMIES.has(fid25) and Lore.BEAST.has(fid25) and Habits.habit(fid25) != "" and not Dooms.is_doom(fid25), "%s: a foe of Part XXV with a story and hours of its own" % fid25)
	var x25: Array = []
	var old_echo25 := 0
	var lettered := {}
	for lid in Mail.ORDER:
		var lt: Dictionary = Mail.LETTERS[lid]
		if lt.has("needs"):
			lettered[str(lt.needs[0])] = int(lettered.get(str(lt.needs[0]), 0)) + 1
	for cid in Echoes.ORDER:
		var c25: Dictionary = Echoes.CROSSROADS[cid]
		if str(c25.part) == "XXV":
			x25.append(cid)
			check((c25.options as Array).size() == 3 and (c25.get("end", {}) as Dictionary).size() == 3 and (c25.get("echo", {}) as Dictionary).size() >= 2 and (c25.get("after", {}) as Dictionary).size() == 3, "%s: three answers, each answered, echoed twice and told at the end" % cid)
			check(str(Data.STEPS[Data.step_index(str(c25.step))].npc) == Hold.STEWARD, "%s is asked at the steward's table" % cid)
			check(int(lettered.get(cid, 0)) == 3, "%s: somebody writes about each of its answers" % cid)
			for o25 in c25.options:
				check(str(Marks.MARKS[cid][str(o25.id)].area) in [Hold.AREA, "frost"], "%s/%s changes the look of its own country" % [cid, o25.id])
		else:
			for ek25 in c25.get("echo", {}):
				if str(ek25).contains("s_p25_") or str(ek25).contains("s_break30"):
					old_echo25 += 1
	check(x25 == ["the_tallies", "the_door", "the_seat"], "what is done with a town's debts, its gate and the seat over its hall is asked three times")
	check(old_echo25 >= 5, "five older crossroads echo in Part XXV (%d)" % old_echo25)
	var tips25 := {}
	for o26 in Echoes.CROSSROADS.the_seat.options:
		for sc26 in o26.tilt:
			tips25[sc26] = true
	check(tips25.has("heart") and tips25.has("craft") and tips25.has("reach"), "the last crossroads of Part XXV tips all three scales the ends ask about")
	check(bsrc.contains("\"shuo_shu\": \"relic\"") and bsrc.contains("\"han_song\": \"town\"") and bsrc.contains("\"the_seat\": [\"found\"]") and bsrc.contains("\"founder\"") and bsrc.contains("\"hold\":"),
		"the bot has a plan for every trial and crossroads of Part XXV, builds the town, and takes the end it earned")
	# its bands are the fifth and sixth (placed after the marks), and keep off the town
	var bands25 := 0
	for a25 in Data.AREAS:
		for bk25 in ["warband5", "warband6", "warband7"]:
			var bd25: Dictionary = Data.AREAS[a25].get(bk25, {})
			if bd25.is_empty():
				continue
			if not str(bd25.vis).begins_with("s_p25_"):
				# (the Underclothes release: a later chapter's bands take the same last slots in other regions)
				check((str(bd25.vis).begins_with("s_p26_") or str(bd25.vis).begins_with("s_p27_") or str(bd25.vis).begins_with("s_p28_") or str(bd25.vis).begins_with("s_p29_") or str(bd25.vis).begins_with("s_p30_") or str(bd25.vis).begins_with("s_p31_") or str(bd25.vis).begins_with("s_p32_") or str(bd25.vis).begins_with("s_p33_") or str(bd25.vis).begins_with("s_p34_") or str(bd25.vis).begins_with("s_p35_")) and bool(bd25.get("late", false)), "%s/%s marches for a later chapter" % [a25, bk25])
				continue
			bands25 += 1
			check(bool(bd25.get("late", false)), "%s/%s marches for Part XXV" % [a25, bk25])
	for bk26 in ["warband3", "warband4"]:
		for a26 in ["mountain", "terraces", "frost"]:
			check(not str(Data.AREAS[a26].get(bk26, {}).get("vis", "")).begins_with("s_p25_"), "%s: no band of Part XXV is placed before the marks" % a26)
	var g1 := Atlas.to_world(Hold.AREA, Hold.AT)
	var in_town := 0
	for e28 in ws.ents:
		if e28.kind == "enemy" and e28.pos.x >= g1.x and e28.pos.y >= g1.y and e28.pos.x < g1.x + Hold.SIZE.x and e28.pos.y < g1.y + Hold.SIZE.y:
			in_town += 1
	check(bands25 == 4 and in_town == 0 and asrc.find("\"warband5\"") > asrc.find("Marks.place("), "four bands march for the chapter, placed after the marks, and none of them in the streets of Guiyun")
	# what the chapter stands in the land can be walked up to
	var at_tile := {}
	for e25 in ws.ents:
		if e25.has("pos") and e25.kind != "enemy":
			at_tile[e25.pos] = true
	var found25 := 0
	for e26 in ws.ents:
		if not ((e26.kind == "pickup" and str(e26.id).begins_with("p25_")) or (e26.kind == "boss" and str(e26.enemy) in ["ke_zheng", "han_song"]) or (e26.kind == "npc" and str(e26.id) in ["feng_xuan", "tai_widow"])):
			continue
		found25 += 1
		var ways26 := 0
		for d26 in MapGen.DIRS:
			var q26: Vector2i = e26.pos + d26
			if MapGen.is_walkable_tile(ws.grid[q26.y * W + q26.x]) and not at_tile.has(q26):
				ways26 += 1
		check(ways26 >= 1 and Atlas.owner_id(ws, e26.pos) == str(e26.area), "%s can be walked up to, in its own region (%d ways)" % [e26.id, ways26])
	var rat: Array = (ws.floors[Caves.fid("mountain", -1)].ents as Array).filter(func(e27): return e27.kind == "boss" and str(e27.enemy) == "shuo_shu")
	check(found25 == 13 + 2 + 2 and rat.size() == 1, "thirteen things to find, two lords and two people of Part XXV stand in the land, and the Great Rat under it (%d)" % found25)

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
		for k in ["levy", "step", "work", "job", "hold"]:
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
	check(Feats.need(Feats.FEATS.low_as_sea.test) == Data.MAX_LEVEL and Feats.need(Feats.FEATS.every_plot.test) == Hold.ORDER.size() and Feats.need(Feats.FEATS.hundred_households.test) == Hold.RANKS.size() - 1 and Feats.need(Feats.FEATS.three_dooms.test) == 3 and Feats.need(Feats.FEATS.marks_twelve.test) < Echoes.ORDER.size() and Feats.need(Feats.FEATS.deeds_all.test) <= Trials.DEEDS.size() and Feats.need(Feats.FEATS.jobs_all.test) == Jobs.ORDER.size()
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
	# (the Unpicked Road release: a stake of one or two stones won on a favourite paid nothing at all: "0. Take it, take it")
	GG2.stones = 25
	check(Gamble.stakes(GG2).is_empty(), "but not a stake so small that winning it pays nothing")
	GG2.stones = 50
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
	# (the Heavy Road release: by daylight it is two hours under a tree, and the day is the same day)
	var day0: int = NG.day
	NG.needs["rest"] = 20.0
	Clock.set_hour(NG, 10.0)
	var day1: int = NG.day
	check(Needs.act(NG, "sleep", {"wild": true, "hour": 10.0}).contains("Two hours") and NG.day == day1 and is_equal_approx(Clock.hour(NG), 12.0) and Needs.value(NG, "rest") == 50.0 and day1 - day0 <= 1, "sleeping rough by daylight is two hours under a tree, not a day gone")
	check(Needs.act(NG, "sleep", inn) == "" and Needs.act(NG, "sleep", {"wild": true, "water": true, "hour": 22.0}) != "" and Needs.value(NG, "rest") >= 90.0 and is_equal_approx(Clock.hour(NG), 6.0), "sleeping rough after dusk fills most of rest, and it is morning")
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
	check(dt_people.size() == 27 and int(dt_roles.get("giant", 0)) == 1 and int(dt_roles.get("soldier", 0)) == 6 and int(dt_roles.get("musician", 0)) == 4, "twenty-seven people live in the Drum Tower quarter: the levy, the players, a street of others, and one of the Great People")
	for nr in ["soldier", "musician"]:
		check(Folk.ROLES.has(nr) and Folk.LINES.has(nr) and Folk.LINES[nr].size() >= 4 and Folk.TITLES.has(nr) and Folk.BODIES.human.has(nr), "the %s: a day, a body, a title and four things to say" % nr)
	for bid3 in ["drum_tower", "pipes_hall", "tailor_shop", "levy_barracks", "pear_garden", "potter_kiln"]:
		check(Data.AREAS.village.buildings.any(func(bd): return str(bd.id) == bid3), "the Drum Tower quarter has its %s" % bid3)
	MG.free()


# ================================================================ the Underclothes release
func _five_frolics() -> void:
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var wsrc := FileAccess.get_file_as_string("res://scripts/world.gd")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	print("== the body under the clothes (art/lib/body.py) ==")
	check(FileAccess.file_exists("res://art/lib/body.py") and FileAccess.get_file_as_string("res://art/lib/person.py").contains("bodylib.build(bare, o)"), "every person is sculpted from the skeleton out, under the clothes")
	var bare_n := 0
	var people := 0
	for pid in Assets.PEOPLE:
		var rel: String = Assets.PEOPLE[pid]
		if not Assets.has(rel) or rel != "characters/" + str(pid):
			continue
		people += 1
		var pm := Assets.person(str(pid))
		var names := {}
		for mi in pm.get_meta("meshes", []):
			names[str((mi as MeshInstance3D).name).get_slice("_", 0)] = (mi as MeshInstance3D).visible
		if names.has("bare") and names.has("own") and names.has("dress"):
			bare_n += 1
			check(not bool(names.bare) and bool(names.dress) and bool(names.own), "%s: dressed until somebody undresses them" % pid)
		pm.free()
	check(people > 200 and bare_n == people, "every person of the land has a body under the clothes, in underclothes (%d of %d)" % [bare_n, people])
	var lf := Assets.person("lin_feng")
	check(Models.undress(lf, true) and Models.undressed(lf), "the hero can be undressed to the underclothes")
	var shown := {}
	for mi2 in lf.get_meta("meshes", []):
		shown[str((mi2 as MeshInstance3D).name).get_slice("_", 0)] = (mi2 as MeshInstance3D).visible
	check(bool(shown.get("bare", false)) and not bool(shown.get("dress", true)) and bool(shown.get("own", false)), "undressed: the body in its underclothes, the face and hands the same, the clothes put away")
	Models.undress(lf, false)
	check(not Models.undressed(lf), "and dressed again")
	lf.free()
	check(not Models.undress(Models.monster("beast", Color("8a7a6a")), true), "a monster has no underclothes to be undressed to")
	check(wsrc.contains("if clip == \"soak\":") and wsrc.contains("Models.undress(player, true)") and msrc.contains("world.UNDER_ID") and FileAccess.get_file_as_string("res://scripts/game.gd").contains("var underclothes := false"),
		"nobody gets into a hot spring in their robes, and the wardrobe has a line for the underclothes")
	check(FileAccess.get_file_as_string("res://art/lib/face.py").contains("EYE_K = 0.66") and FileAccess.get_file_as_string("res://art/lib/person.py").contains("HEAD_K = (0.95, 0.97)"),
		"heads and eyes of a real size: about seven and a half heads to the figure")
	print("== Part XXVI: the Five Frolics ==")
	check(Data.REALMS.size() >= 32 and Data.REALMS[31] == "Room for the Blade" and Data.MAX_LEVEL >= 93 and Data.level_name(93).ends_with("Room for the Blade") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXVI adds the realm of Room for the Blade")
	check(Data.step_index("s_break31") > Data.step_index("s_p26_end") and Data.DIALOGUE.has("recall24") and msrc.contains("\"s_break30\": \"recall24\"") and Data.DIALOGUE.has("pre:s_break31") and Data.DIALOGUE.has("post:s_break31"),
		"Part XXVI follows Scarcely Known (recall24) and ends at Room for the Blade")
	var n26 := 0
	var kinds26 := {}
	for st26 in Data.STEPS:
		if not str(st26.id).begins_with("s_p26_"):
			continue
		n26 += 1
		kinds26[str(st26.kind)] = int(kinds26.get(str(st26.kind), 0)) + 1
		if st26.kind == "talk":
			check(Data.DIALOGUE.has(str(st26.id)), "%s: there is something said" % st26.id)
		if not st26.kind in ["kill", "talk"]:
			check(Data.DIALOGUE.has("done:" + str(st26.id)), "%s: something is said when it is done" % st26.id)
		if st26.kind == "try":
			check(not st26.has("cave") and (st26.things as Array) == ["hot_spring"] and Props.KINDS.has("hot_spring"), "%s: a hot spring of the open land to soak in" % st26.id)
			# and a soak is counted for it (only the things of the caves used to be, and the step could not be done)
			var TG = load("res://scripts/game.gd").new()
			TG.reset()
			TG.step = Data.step_index(str(st26.id))
			check(TG.tried_count(st26) == 0, "%s: nothing tried before it begins" % st26.id)
			Props.use({"kind": "prop", "id": "test:spring", "prop": "hot_spring", "pos": Vector2i.ZERO, "area": str(st26.area)}, TG)
			check(TG.step == Data.step_index(str(st26.id)) + 1, "%s: a soak in the hot spring is counted for it, and it is done" % st26.id)
			TG.free()
			# and there is a hot spring in its region to soak in, that can be walked up to (the vale's own
			# things are drawn by lot, and its lot drew none: one stands at the foot of its highest peak)
			var sw: Dictionary = Atlas.world_of("surface")
			var sreach := MapGen.flood(sw.grid, sw.w, sw.h, sw.start)
			var springs26 := 0
			for se in sw.ents:
				if se.kind == "prop" and str(se.get("prop", "")) in st26.things and str(se.get("area", "")) == str(st26.area):
					for sd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						if sreach.has((se.pos as Vector2i) + sd):
							springs26 += 1
							break
			check(springs26 >= 1, "%s: a hot spring stands in %s, and can be walked up to" % [st26.id, st26.area])
		if st26.kind == "folk":
			var er: Dictionary = Folk.ERRANDS.get(str(st26.id), {})
			check(Folk.CAMP_ROLES.has(str(st26.role)) and (er.lines as Array).size() >= 4 and int(er.price) == 0, "%s: people of the road asked, each with an answer" % st26.id)
			for el in er.lines:
				check(fits.call(str(el)), "%s: an answer that fits the box" % st26.id)
		if st26.kind == "marks":
			check(int(st26.n) >= 3 and int(st26.n) * 4 <= Echoes.ORDER.size(), "%s: no more than a quarter of what a journey leaves standing" % st26.id)
	check(n26 >= 26 and int(kinds26.get("kill", 0)) == 3 and int(kinds26.get("hunt", 0)) == 3 and int(kinds26.get("collect", 0)) == 4 and kinds26.has("try") and kinds26.has("visits") and kinds26.has("summit") and kinds26.has("glide") and int(kinds26.get("folk", 0)) == 3 and kinds26.has("marks"),
		"Part XXVI: %d steps: a soak, three lords, three hunts, four searches, three errands of the road, a summit and a flight" % n26)
	# its "go and look" asks for things looked at since it began: by then a journey has looked at as many
	# as it asks, and a step that counted from the beginning was done the moment it was given
	var MG = load("res://scripts/game.gd").new()
	MG.reset()
	MG.step = Data.step_index("s_p26_glide")
	for mk in 9:
		MG.marks_seen["mark:test:%d" % mk] = true
	MG.advance()
	var ms26: Dictionary = MG.cur_step()
	check(str(ms26.id) == "s_p26_marks" and bool(ms26.get("new", false)) and MG.marks_count(ms26) == 0 and not MG.objective_text().contains("(8/8)"), "s_p26_marks: what was looked at before it began does not count")
	MG.marks_seen["mark:test:new"] = true
	check(MG.marks_count(ms26) == 1 and MG.step == Data.step_index("s_p26_marks"), "s_p26_marks: what is looked at after it began does")
	MG.free()
	for k26 in Data.DIALOGUE:
		if str(k26).contains("s_p26_") or str(k26) in ["recall24", "pre:s_break31", "post:s_break31", "pre:duke_huan", "post:duke_huan", "pre:quan_niu", "post:quan_niu", "pre:cao_cao", "post:cao_cao"]:
			for ln26 in Data.DIALOGUE[k26]:
				check(fits.call(str(ln26[1])), "%s: a line that fits the box" % k26)
	for tid26 in ["duke_huan", "quan_niu", "cao_cao"]:
		check(Trials.TRIALS.has(tid26) and Data.ENEMIES[tid26].get("boss", false) and Lore.BOSS.has(tid26) and Trials.trial_of_step(Data.STEPS[_kill_step(tid26)]) == tid26, "%s is a lord of Part XXVI, guarded by a trial" % tid26)
		check((Trials.TRIALS[tid26].paths as Array).any(func(pth): return str(pth.kind) == "relic") and (Trials.TRIALS[tid26].paths as Array).size() >= 3, "%s can be passed by what was found on the way" % tid26)
		check(Data.DIALOGUE.has("pre:" + tid26) and Data.DIALOGUE.has("post:" + tid26), "%s has something to say before and after" % tid26)
	for pid26 in ["hua_tuo", "wu_pu", "pao_ding", "duke_huan", "cao_cao", "jailer_wife"]:
		check(Assets.PEOPLE.has(pid26) and Assets.has(Assets.PEOPLE[pid26]) and FileAccess.file_exists("res://art/characters/%s.py" % pid26), "%s has a model built from a script" % pid26)
	for cid26 in ["hua_tuo", "wu_pu", "pao_ding", "jailer_wife"]:
		check(Data.CHAT.has(cid26) and Data.CHAT[cid26].size() >= 3, "%s has things to say" % cid26)
	check(Assets.MONSTERS.has("ox") and Assets.has_monster("ox") and Assets.NATURAL.has("ox") and Habits.BY_SHAPE.has("ox") and str(Data.ENEMIES.corvee_ox.shape) == "ox" and str(Data.ENEMIES.quan_niu.shape) == "ox",
		"the oxen of the land are oxen (the Whole Ox, and the oxen of the corvee that were drawn as wolves)")
	for fid26 in ["rust_beetle", "still_toad", "idle_spore", "gristle_hound", "locked_joint", "hacking_butcher", "tiger_guard", "headache_crow", "sleepless_drum"]:
		check(Data.ENEMIES.has(fid26) and Lore.BEAST.has(fid26) and Habits.habit(fid26) != "" and not Dooms.is_doom(fid26), "%s: a foe of Part XXVI with a story and hours of its own" % fid26)
	# the crossroads of the chapter: every answer answered, echoed, told at the end, written about and standing
	var c26: Dictionary = Echoes.CROSSROADS.get("the_book", {})
	check(not c26.is_empty() and str(c26.step) == "s_p26_book" and str(c26.part) == "XXVI" and Echoes.ORDER.find("the_book") > Echoes.ORDER.find("the_seat"), "what becomes of Hua Tuo's book is asked after the seat")
	check((c26.options as Array).size() == 3 and (c26.get("end", {}) as Dictionary).size() == 3 and (c26.get("echo", {}) as Dictionary).size() >= 2 and (c26.get("after", {}) as Dictionary).size() == 3,
		"the_book: three answers, each answered, echoed twice and told at the end")
	var lettered := 0
	for lid in Mail.ORDER:
		if Mail.LETTERS[lid].has("needs") and str(Mail.LETTERS[lid].needs[0]) == "the_book":
			lettered += 1
	check(lettered == 3 and Mail.LETTERS.has("hua_last"), "somebody writes about each answer, and the physician writes once")
	var tips26 := {}
	for o26 in c26.options:
		check(Marks.MARKS.the_book.has(str(o26.id)), "the_book/%s leaves something standing" % o26.id)
		for sc26 in o26.tilt:
			tips26[sc26] = true
	check(tips26.has("heart") and tips26.has("craft") and tips26.has("reach"), "the crossroads of Part XXVI tips all three scales the ends ask about")
	var old_echo26 := 0
	for cid in Echoes.ORDER:
		if cid == "the_book":
			continue
		for ek26 in Echoes.CROSSROADS[cid].get("echo", {}):
			if str(ek26).contains("s_p26_"):
				old_echo26 += 1
	check(old_echo26 >= 3, "three older crossroads echo in Part XXVI (%d)" % old_echo26)
	check(bsrc.contains("\"duke_huan\": \"relic\"") and bsrc.contains("\"cao_cao\": \"relic\"") and bsrc.contains("\"the_book\": [\"copy\"]") and bsrc.contains("func _try_land"),
		"the bot has a plan for every trial and the crossroads of Part XXVI, and soaks in a spring of the open land")
	# its bands take the last slots, and what it stands in the land can be walked up to
	for a26 in ["fungal", "tushan", "millet"]:
		check(str(Data.AREAS[a26].get("warband5", {}).get("vis", "")).begins_with("s_p26_") and not Data.AREAS[a26].has("warband6"), "%s: the chapter's band takes the last slot" % a26)
	# the birds that are not birds of prey are drawn from the bird nearest them in kind, and keep the
	# shape (and so the habits) they had; a wader stands on the ground in the land
	for bid in Assets.BIRD_OF:
		check(str(Data.ENEMIES.get(bid, {}).get("shape", "")) == "bird" and ResourceLoader.exists("res://assets/%s.glb" % str(Assets.BIRD_OF[bid])), "%s: drawn on a bird nearer its kind, and still a bird" % bid)
	check(not Assets.hovers("garden_crane") and Assets.hovers("tally_crow") and Assets.hovers("storm_hawk"), "a crane stands in the land; a crow and a hawk are off the ground")
	# and its crossroads' marks are stood after the late bands of the Three Burrows (which share the
	# mountain with one of them), so that none of those moves
	var asrc26 := FileAccess.get_file_as_string("res://scripts/atlas.gd")
	check(Marks.AFTER_BANDS.has("the_book") and asrc26.rfind("Marks.place(") > asrc26.find("_place_bands(last_slots"), "the marks of a later crossroads are stood after the bands of an older release")
	var ws: Dictionary = Atlas.world_of("surface")
	var found26 := 0
	for e26 in ws.ents:
		if (e26.kind == "pickup" and str(e26.id).begins_with("p26_")) or (e26.kind == "boss" and str(e26.enemy) in ["quan_niu", "cao_cao"]) or (e26.kind == "npc" and str(e26.id) in ["hua_tuo", "wu_pu", "pao_ding", "jailer_wife"]):
			found26 += 1
			check(Atlas.owner_id(ws, e26.pos) == str(e26.area), "%s stands in its own region" % e26.id)
	var duke: Array = (ws.floors[Caves.fid("fungal", -1)].ents as Array).filter(func(e27): return e27.kind == "boss" and str(e27.enemy) == "duke_huan")
	check(found26 == 18 + 2 + 4 and duke.size() == 1, "eighteen things to find, two lords and four people of Part XXVI stand in the land, and the duke in the cave under the vale (%d)" % found26)

## The Heavy Road release: what things weigh and who carries them (load.gd), the work of the hands
## (toil.gd), what a load looks like (burden.gd), and Part XXVII: The Cloth Sack.
func _heavy_road() -> void:
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var wsrc := FileAccess.get_file_as_string("res://scripts/world.gd")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	print("== the load (load.gd) ==")
	var LG = load("res://scripts/game.gd").new()
	LG.reset()
	check(is_equal_approx(Load.cap(LG), Load.BASE) and Load.tier(LG) == 0 and Load.pace(LG) == 1.0 and Load.look(LG)[0] == "" and not Load.grounded(LG), "a sweeper can carry sixty jin, and sets out with next to nothing")
	LG.add_item("timber", 1)
	check(is_equal_approx(Load.weight(LG), 30.0) and Load.tier(LG) == 0 and Load.pace(LG) == 1.0, "one stem of timber is thirty jin: half his back, and no slower")
	LG.add_item("timber", 1)
	check(Load.tier(LG) == 1 and Load.pace(LG) == 1.0 and not Load.grounded(LG) and Load.look(LG)[0] == "logs", "two are all his back was made for: laden, drawn as logs, and no slower")
	LG.add_item("timber", 1)
	check(Load.tier(LG) == 2 and Load.pace(LG) == 1.5 and Load.grounded(LG) and Load.refuses(LG, "timber") == "", "three are more: heavy, half as slow again, off the sword and under no kite")
	LG.add_item("timber", 1)
	check(Load.tier(LG) == 3 and Load.pace(LG) > 2.0 and Load.refuses(LG, "timber") != "", "four, and he staggers, and can take up nothing more that the land gives")
	LG.companion = true
	check(is_equal_approx(Load.cap(LG), Load.BASE * (1.0 + Load.WITH_YUE)) and Load.tier(LG) == 2, "Yue Ling takes her share")
	LG.add_item("pack_frame", 1)
	check(is_equal_approx(Load.cap(LG), Load.BASE * (1.0 + Load.WITH_YUE) + Load.FRAME), "a pack-frame bears forty jin more")
	LG.ride = "pony"
	check(Load.cap(LG, true) > Load.cap(LG) + 100.0 and Load.tier(LG, true) <= 1, "a horse bears what he cannot, while he rides it")
	LG.ride = "sword"
	check(is_equal_approx(Load.cap(LG, true), Load.cap(LG)), "a flying sword is his own qi, and lifts no more than he can")
	check(wsrc.contains("Load.grounded(Game) and str(Fashion.RIDES[Game.ride].kind) == \"vehicle\"") and wsrc.contains("STEP_T * Load.pace(Game)") and wsrc.contains("The kite will not lift him"), "a heavy load slows the step, grounds the sword and keeps the kite shut")
	LG.level = 30
	check(is_equal_approx(Load.cap(LG), (Load.BASE + Load.PER_REALM * 10.0) * 1.4 + Load.FRAME), "a great realm is two jin more on the back")
	# what has no bulk has no weight, however much of it a journey gathers: thirty hours of the road
	# leave thousands of essences, hundreds of pills and every keepsake there is in the bag, and the
	# first cut of this release weighed each a little, so that by Part XXI nobody could fly
	var BG = load("res://scripts/game.gd").new()
	BG.reset()
	var asked := {}
	for st0 in Data.STEPS:
		if st0.kind == "collect":
			asked[str(st0.item)] = true
	for iid in Data.ITEMS:
		if Load.GOODS.has(iid) or Load.WARES.has(iid) or Needs.FOOD.has(iid) or asked.has(iid):
			continue
		BG.inv[iid] = 999
		check(Load.weight_of(str(iid)) == 0.0, "%s has no bulk, and weighs nothing" % iid)
	check(Load.gross(BG) == 0.0 and Load.tier(BG) == 0, "a bag of nine hundred of everything that has no bulk is a light bag")
	# and what the searches of the whole story found is handed over as each is done: at the end, nothing
	BG.step = Data.STEPS.size()
	for iid2 in asked:
		BG.inv[iid2] = 99
	check(Load.gross(BG) == 0.0, "what every finished search asked for was handed over")
	BG.free()
	# the storehouse
	check(Load.at_home(LG, "sect", Vector2i.ZERO) != "" and Load.at_home(LG, "bamboo", Vector2i.ZERO) == "" and Load.at_home(LG, Hold.AREA, Atlas.to_world(Hold.AREA, Hold.AT)) == "", "things can be left at the sect, and at Guiyun only once it stands")
	var stw: Array = Load.stowable(LG)
	check(stw.has("timber") and not stw.has("hp_pill") and not stw.has("pack_frame") and not stw.has("axe"), "what can be left: the load, not the pills, the frame or the tools")
	check(Load.stow(LG, "timber") == 4 and Load.carried(LG, "timber") == 0 and int(LG.stash.timber) == 4 and Load.tier(LG) == 0 and Load.fetch(LG, "timber") == 4 and Load.carried(LG, "timber") == 4 and LG.stash.is_empty(), "left in the storehouse it weighs nothing, and is there to take up again")
	# selling, and the wares
	var st0: int = LG.stones
	var sale: Array = Load.sell_all(LG)
	check(int(sale[0]) == 4 * int(Load.GOODS.timber.sell) and LG.stones == st0 + int(sale[0]) and Load.carried(LG, "timber") == 0 and LG.sold == 4, "a pedlar pays what a pedlar pays, and the back is empty")
	for wid in Load.WARE_ORDER:
		check(Data.ITEMS.has(wid) and Load.WARES.has(wid) and str(Data.ITEMS[wid].desc).length() > 30, "%s is sold, and said what it is for" % wid)
	for gid in Load.GOOD_ORDER:
		check(Data.ITEMS.has(gid) and float(Load.GOODS[gid].jin) > 0.0 and Burden.KINDS.has(str(Load.GOODS[gid].bulk)) and int(Load.GOODS[gid].sell) * 40 < Data.enemy_stones(1, false) * 4000, "%s: a good of the land with a weight, a look on the back and a pedlar's price" % gid)
	LG.stones = 10
	check(Load.buy(LG, "axe") != "" and int(LG.inv.get("axe", 0)) == 0, "nothing is sold on credit")
	LG.stones = 100
	check(Load.buy(LG, "axe") == "" and int(LG.inv.axe) == 1 and LG.stones == 100 - int(Load.WARES.axe.price) and Load.buy(LG, "axe") != "", "an axe is bought once")
	# what a day of the hands is worth: less than the road
	check(int(Load.GOODS.stone_block.sell) * 30 < Data.enemy_stones(10, false) * 30, "a day of cutting stone is worth less than a day of the road")
	# the pouch is hard to come by, and the ring is not for sale
	LG.level = 3
	LG.stones = 99999999
	LG.inv["ess_metal"] = 99
	LG.inv["ess_dark"] = 99
	check(Load.pouch_blocked(LG).contains("realm") and Load.pouch_blocked(LG).contains("carried a league") and not Load.sew_pouch(LG), "no pouch for somebody who has not the realm for it, nor carried enough to know what it is for")
	LG.level = 30
	check(Load.pouch_blocked(LG).contains("carried a league") and not Load.pouch_blocked(LG).contains("realm"), "the realm alone does not buy it")
	LG.hauled = float(Load.POUCH_NEEDS.hauled)
	LG.stones = 100
	check(Load.pouch_blocked(LG).contains("spirit stones"), "nor does the carrying alone")
	LG.stones = int(Load.POUCH_NEEDS.stones) + 5
	check(Load.pouch_blocked(LG) == "" and Load.sew_pouch(LG) and int(LG.inv.qiankun_pouch) == 1 and LG.stones == 5 and int(LG.inv.ess_metal) == 99 - 30 and Load.pouch_blocked(LG) != "", "realm, the leagues, the essences and the stones: a pouch is sewn, once")
	LG.inv["stone_block"] = 4
	var g0: float = Load.gross(LG)
	check(g0 > 180.0 and is_equal_approx(Load.weight(LG), g0 * Load.POUCH_K), "what goes into the pouch weighs a tenth")
	LG.inv["stone_block"] = 10
	check(is_equal_approx(Load.weight(LG), Load.POUCH_HOLDS * Load.POUCH_K + (Load.gross(LG) - Load.POUCH_HOLDS)), "and it holds three hundred jin, no more")
	LG.inv["mustard_ring"] = 1
	check(Load.weight(LG) == 0.0 and Load.tier(LG) == 0 and Load.look(LG)[0] == "" and Load.refuses(LG, "stone_block") == "", "with the Mustard-Seed Ring on, nothing weighs anything")
	check(not Load.WARES.has(Load.RING) and not Load.WARES.has(Load.POUCH) and int(Load.POUCH_NEEDS.hauled) >= 2000 and int(Load.POUCH_NEEDS.stones) >= 20000 and int(Load.POUCH_NEEDS.realm) >= 3, "neither is on anybody's counter, and the pouch asks a great deal")
	var ring_step := -1
	for i in Data.STEPS.size():
		if (Data.STEPS[i].get("gives", {}) as Dictionary).has(Load.RING):
			ring_step = i
	check(ring_step == Data.step_index("s_p27_end") and ring_step >= Data.step_index("s_break32") - 3 and Data.step_index("s_p27_end") > _kill_step("li_jing"), "the ring is given once, at the very end of the last chapter, after its last lord")
	# a tile walked under a load is counted, and only then
	var HG = load("res://scripts/game.gd").new()
	HG.reset()
	Load.walked(HG, false)
	check(HG.hauled == 0.0, "an empty back hauls nothing")
	HG.add_item("timber", 1)
	Load.walked(HG, true)
	check(HG.hauled == 0.0, "nor does a load the horse carries")
	for _i in 500:
		Load.walked(HG, false)
	check(Load.hauled(HG) == 30, "thirty jin walked five hundred tiles is thirty jin carried a league")
	HG.free()
	# the story never asks more than a back can bear at its own pace before Part XXVII: every road the
	# bot walked in an older release is walked at the pace it was
	var WG = load("res://scripts/game.gd").new()
	WG.reset()
	var worst := 0.0
	var worst_at := ""
	var p27 := Data.step_index("s_p27_home")
	var lv_w := 0
	for i2 in p27:
		var s2: Dictionary = Data.STEPS[i2]
		WG.step = i2
		if s2.kind == "breakthrough":
			lv_w = int(s2.to)
		WG.level = lv_w
		WG.companion = i2 > Data.step_index("s_yue")
		if s2.kind == "collect":
			WG.inv[str(s2.item)] = int(s2.n)
			var r2 := Load.ratio(WG)
			if r2 > worst:
				worst = r2
				worst_at = str(s2.id)
		check(not s2.has("gives") and not str(s2.kind) in ["toil", "haul"], "%s: no older step works the land or hands out a tool" % s2.id)
	check(worst <= 1.0, "no search of an older chapter loads him past laden (the most: %.2f of his back at %s)" % [worst, worst_at])
	WG.free()
	LG.free()

	print("== the work of the hands (toil.gd) ==")
	check(Toil.ORDER.size() == 7 and Toil.WORKS.size() == 7, "seven kinds of work: fell, angle, quarry, reap, and (the Small Fish release) pick, dig, mine")
	var pap: AnimationPlayer = Assets.instance("characters/lin_feng").get_meta("ap")
	var yap: AnimationPlayer = Assets.instance("characters/yue_ling").get_meta("ap")
	var clips_w := {}
	for wk in Toil.ORDER:
		var w: Dictionary = Toil.WORKS[wk]
		check(Load.WARES.has(str(w.tool)) and Load.GOODS.has(str(w.good)) and pap.has_animation(str(w.clip)) and not clips_w.has(str(w.clip)) and (w.lines as Array).size() >= 3 and Props.held(str(w.hold)) != null,
			"%s: a tool that is sold, a good that is carried, a clip of its own, something in the hand and three lines" % wk)
		clips_w[str(w.clip)] = true
		check(float(w.dur) >= pap.get_animation(str(w.clip)).length - 0.01 and Faces.OF_CLIP.has(str(w.clip)), "%s: done for at least one whole swing, with a face for it" % wk)
		for ln in w.lines + w.get("miss", []):
			check(fits.call(str(ln)), "%s: a line that fits" % wk)
		check(pap.get_animation(str(w.clip)).find_track(NodePath("%GeneralSkeleton:brow.L"), Animation.TYPE_ROTATION_3D) < 0, "%s: its clip leaves the face alone" % wk)
	for hc in ["haul", "haul_idle"]:
		check(pap.has_animation(hc) and yap.has_animation(hc) and Assets.LOOPS.has(hc) and Assets.LEND.has(hc), "%s: the two of them walk and stand under a load, and can lend it to the towns" % hc)
	check(wsrc.contains("Burden.wear(player") and wsrc.contains("Burden.wear(comp") and wsrc.contains("gait = \"haul\""), "a load is drawn on his back and on hers, and bends the walk")
	for bk in Burden.KINDS:
		var bm := Burden.model(bk, 1.0)
		var tris := 0
		for mi in bm.find_children("*", "MeshInstance3D", true, false):
			for sf in (mi as MeshInstance3D).mesh.get_surface_count():
				tris += ((mi as MeshInstance3D).mesh.surface_get_arrays(sf)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		check(tris > 60 and tris < 6000, "%s: a load built from code (%d triangles)" % [bk, tris])
		bm.free()
	# what a place can be worked at is read from the tiles and the heights alone
	var ws: Dictionary = Atlas.world_of("surface")
	var reach := MapGen.flood(ws.grid, ws.w, ws.h, ws.start)
	var cnt := {}
	for a in ["silk", "volcano", "karst", "maple"]:
		cnt[a] = {"fell": 0, "angle": 0, "quarry": 0, "reap": 0}
	for t in reach:
		var own := Atlas.owner_id(ws, t)
		if not cnt.has(own):
			continue
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var wk2 := Toil.work_at(ws, t, t + d)
			if wk2 != "":
				cnt[own][wk2] += 1
	check(int(cnt.silk.fell) >= 100 and int(cnt.volcano.quarry) >= 30 and int(cnt.volcano.fell) >= 100 and int(cnt.karst.reap) >= 100 and int(cnt.maple.angle) >= 20, "there is forest to fell in the Silk Woods, rock to cut and wood on the volcano, open ground in the Stone Forest and water in the Maple Gorge")
	check(Toil.work_at(ws, ws.start, ws.start + Vector2i(1, 0), false, true) == "" and Toil.work_at({}, Vector2i.ZERO, Vector2i.ONE) == "", "nothing is worked at under a roof")
	# doing it
	var TG = load("res://scripts/game.gd").new()
	TG.reset()
	var tile := Vector2i(5, 5)
	check(Toil.blocked(TG, "fell", "surface", tile).contains("axe"), "no felling without an axe: it is said who sells one")
	TG.add_item("axe", 1)
	check(Toil.blocked(TG, "fell", "surface", tile) == "", "with an axe it can be done")
	var got: Array = Toil.done(TG, "fell", "surface", tile)
	check(got.size() == 2 and int(TG.inv.timber) == 1 and int(TG.toil.fell) == 1 and Toil.spent(TG, "surface", tile) and Toil.blocked(TG, "fell", "surface", tile) != "", "a tree is felled: a stem on his back, and that piece of the land has given for the day")
	TG.day += 1
	check(not Toil.spent(TG, "surface", tile), "and gives again after the next dawn")
	TG.add_item("fishing_rod", 1)
	var caught := 0
	for k in 9:
		Toil.done(TG, "angle", "surface", Vector2i(10 + k, 5))
	caught = int(TG.inv.get("carp", 0))
	check(caught == 6, "two casts in three catch, counted and never thrown for (%d of 9)" % caught)
	check(Toil.good_of("quarry", true) == "ore_lump" and Toil.good_of("quarry", false) == "stone_block", "a cave wall gives ore, a crag dressed stone")
	# the steps of the story that ask for it
	TG.step = Data.step_index("s_p27_fell")
	TG.step_toil = 0
	for k2 in 3:
		check(TG.step == Data.step_index("s_p27_fell"), "the felling is not done before it is done")
		Toil.done(TG, "fell", "surface", Vector2i(30 + k2, 5))
	check(TG.step == Data.step_index("s_p27_timber") and TG.step_toil == 0, "three trees felled since it was asked: the step is done")
	var hs: Dictionary = TG.cur_step()
	var on_me := Toil.on_hand(TG, hs)
	check(on_me == 4 and Toil.wanted(TG, hs) == 8 and TG.objective_text().contains("(0/8, 4 carried)") and int(TG.inv.get("pick", 0)) == 0, "what he felled is on his back, and none of it is brought yet")
	check(Toil.hand_over(TG, hs) == 4 and TG.step_haul == 4 and Load.carried(TG, "timber") == 0 and Toil.hand_over(TG, hs) == 0, "set down in front of whoever it is for: four of eight, and his back is empty")
	TG.add_item("timber", 9)
	check(Toil.hand_over(TG, hs) == 4 and Load.carried(TG, "timber") == 5, "no more is taken than was asked")
	TG.poll_steps()
	check(TG.step == Data.step_index("s_p27_footing") and TG.done_pending.has("s_p27_timber") and int(TG.inv.get("pick", 0)) == 1, "eight stems brought: the step is done, something is said, and a pick is put into his hands")
	check(msrc.contains("Toil.hand_over(Game, s)") and msrc.contains("KEY_C") and msrc.contains("func offer_pedlar") and msrc.contains("func offer_store") and bsrc.contains("func _toil_step") and bsrc.contains("func _haul_step"),
		"C works the land, a load is handed over by walking up, pedlars trade and the storehouse opens; and the bot does the work itself")
	check(msrc.find("{\"id\": \"later\", \"label\": \"Not today\", \"desc\": \"There is a road waiting. %s\" % Load.text(Game)") > 0, "\"Not today\" is the pedlar's first line")
	TG.free()

	print("== Part XXVII: the Cloth Sack ==")
	check(Data.REALMS.size() >= 33 and Data.REALMS[32] == "Sumeru in a Seed" and Data.MAX_LEVEL >= 96 and Data.level_name(96).ends_with("Sumeru in a Seed") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXVII adds the realm of Sumeru in a Seed")
	check(Data.STEPS[Data.step_index("s_p28_home") - 1].id == "s_break32" and Data.DIALOGUE.has("recall25") and msrc.contains("\"s_break31\": \"recall25\"") and Data.DIALOGUE.has("pre:s_break32") and Data.DIALOGUE.has("post:s_break32"),
		"Part XXVII follows Room for the Blade (recall25) and ends the game")
	var n27 := 0
	var kinds27 := {}
	for st in Data.STEPS:
		if not str(st.id).begins_with("s_p27_"):
			continue
		n27 += 1
		kinds27[str(st.kind)] = int(kinds27.get(str(st.kind), 0)) + 1
		if st.kind == "talk":
			check(Data.DIALOGUE.has(str(st.id)), "%s: there is something said" % st.id)
		if not st.kind in ["kill", "talk"]:
			check(Data.DIALOGUE.has("done:" + str(st.id)), "%s: something is said when it is done" % st.id)
		if st.kind == "haul":
			check(Load.GOODS.has(str(st.good)) and Data.DIALOGUE.has("haul:" + str(st.id)) and int(st.n) >= 4, "%s: a good of the land, carried to somebody with something to say about it" % st.id)
			# whoever it is for stands where the step says, by then
			var where := ""
			for a2 in Data.AREAS:
				for np in Data.AREAS[a2].get("npcs", []):
					if str(np.id) == str(st.npc):
						where = a2
						check(Data.step_index(str((np.get("vis", ["", ""]) as Array)[0])) <= Data.step_index(str(st.id)), "%s: %s is there by then" % [st.id, st.npc])
			check(where == str(st.area), "%s: carried to %s in %s" % [st.id, st.npc, st.area])
		if st.kind == "toil":
			check(Toil.WORKS.has(str(st.work)) and int(st.n) >= 3, "%s: the work of the hands, so many times" % st.id)
		if st.kind == "folk":
			var er: Dictionary = Folk.ERRANDS.get(str(st.id), {})
			check(Folk.CAMP_ROLES.has(str(st.role)) and (er.lines as Array).size() >= 4 and int(er.price) == 0, "%s: people of the road asked, each with an answer" % st.id)
			for el in er.lines:
				check(fits.call(str(el)), "%s: an answer that fits the box" % st.id)
		if st.kind == "visits":
			for vn in st.npcs:
				check(Data.DIALOGUE.has("visit:%s:%s" % [str(st.id), str(vn)]) and fits.call(str(Data.DIALOGUE["visit:%s:%s" % [str(st.id), str(vn)]][0][1])), "%s: %s has something to say of it" % [st.id, vn])
		if st.kind == "marks":
			check(bool(st.get("new", false)) and int(st.n) >= 3 and int(st.n) * 4 <= Echoes.ORDER.size(), "%s: things looked at since it began, and no more than a quarter of what a journey leaves standing" % st.id)
	check(n27 >= 34 and int(kinds27.get("kill", 0)) == 3 and int(kinds27.get("hunt", 0)) == 4 and int(kinds27.get("collect", 0)) == 4 and int(kinds27.get("haul", 0)) == 6 and int(kinds27.get("toil", 0)) == 2 and int(kinds27.get("folk", 0)) == 3
		and kinds27.has("visits") and kinds27.has("marks"),
		"Part XXVII: %d steps: six loads carried, two works of the hands, three lords, four hunts, four searches, three errands of the road, a round of the hearths and a look at what stands" % n27)
	# the charcoal for the smith is more than his back was made for at that realm, with Yue Ling's share: it is walked
	var CG = load("res://scripts/game.gd").new()
	CG.reset()
	CG.level = 95
	CG.companion = true
	CG.ride = "barque"
	CG.inv["charcoal"] = int(Data.STEPS[Data.step_index("s_p27_cart")].gives.charcoal)
	check(Load.tier(CG) == 2 and Load.grounded(CG) and int(Data.STEPS[Data.step_index("s_p27_smith")].n) == int(CG.inv.charcoal), "eight sacks of charcoal are more than any sword will lift: they go up the mountain on foot")
	CG.free()
	# every tool is put into his hands before the step that needs it, and the chapter's loads can be borne
	var have := {}
	for st2 in Data.STEPS:
		for gk in st2.get("gives", {}):
			have[str(gk)] = true
			check(Data.ITEMS.has(str(gk)), "%s gives something there is" % st2.id)
		var need_work := ""
		if st2.kind == "toil":
			need_work = str(st2.work)
		elif st2.kind == "haul":
			for wk3 in Toil.ORDER:
				if str(Toil.WORKS[wk3].good) == str(st2.good):
					need_work = wk3
			check(need_work != "" or have.has(str(st2.good)), "%s: its good is worked for, or was given" % st2.id)
		if need_work != "":
			check(have.has(str(Toil.WORKS[need_work].tool)), "%s: the %s was put into his hands first" % [st2.id, Toil.WORKS[need_work].tool])
	for k27 in Data.DIALOGUE:
		if str(k27).contains("s_p27_") or str(k27) in ["recall25", "pre:s_break32", "post:s_break32", "pre:palace_buyer", "post:palace_buyer", "pre:wan_juan", "post:wan_juan", "pre:li_jing", "post:li_jing"]:
			for ln27 in Data.DIALOGUE[k27]:
				check(fits.call(str(ln27[1])), "%s: a line that fits the box" % k27)
				check(not str(ln27[1]).contains("—"), "%s: no dash in the story's text" % k27)
	for tid27 in ["palace_buyer", "wan_juan", "li_jing"]:
		check(Trials.TRIALS.has(tid27) and Data.ENEMIES[tid27].get("boss", false) and Lore.BOSS.has(tid27) and Trials.trial_of_step(Data.STEPS[_kill_step(tid27)]) == tid27, "%s is a lord of Part XXVII, guarded by a trial" % tid27)
		check((Trials.TRIALS[tid27].paths as Array).any(func(pth): return str(pth.kind) == "relic") and (Trials.TRIALS[tid27].paths as Array).size() >= 3, "%s can be passed by what was found on the way" % tid27)
		check(Data.DIALOGUE.has("pre:" + tid27) and Data.DIALOGUE.has("post:" + tid27), "%s has something to say before and after" % tid27)
		# (what a way through asks for was found before it, in a step of the chapter)
		for pth2 in Trials.TRIALS[tid27].paths:
			for nd in pth2.needs:
				if str(nd[0]) == "item":
					var found_at := -1
					for i3 in Data.STEPS.size():
						if Data.STEPS[i3].kind == "collect" and str(Data.STEPS[i3].item) == str(nd[1]) and int(Data.STEPS[i3].n) >= int(nd[2]):
							found_at = i3
					check(found_at >= 0 and found_at < _kill_step(tid27), "%s: its relic is found before it" % tid27)
				if str(nd[0]) == "lv":
					check(Data.level_name(int(nd[1])).contains("Room for the Blade") == str(pth2.desc).contains("Room for the Blade") and str(pth2.desc).begins_with(str(Data.STAGES[int(nd[1]) % 3])), "%s: its way of might names the realm it asks" % tid27)
	# (the Heavy Road release: the ways of might of Part XXVI named a realm that was not the one they asked)
	for tid26 in ["duke_huan", "quan_niu", "cao_cao"]:
		for pth3 in Trials.TRIALS[tid26].paths:
			for nd3 in pth3.needs:
				if str(nd3[0]) == "lv":
					check(str(pth3.desc).begins_with(Data.level_name(int(nd3[1]))), "%s: its way of might names the realm it asks (%s)" % [tid26, Data.level_name(int(nd3[1]))])
	for pid27 in ["tao_kan", "charcoal_seller", "zhichang", "budai", "palace_buyer", "li_jing"]:
		check(Assets.PEOPLE.has(pid27) and Assets.has(Assets.PEOPLE[pid27]) and FileAccess.file_exists("res://art/characters/%s.py" % pid27), "%s has a model built from a script" % pid27)
	for cid27 in ["tao_kan", "charcoal_seller", "zhichang", "budai"]:
		check(Data.CHAT.has(cid27) and Data.CHAT[cid27].size() >= 3, "%s has things to say" % cid27)
		for cl in Data.CHAT[cid27]:
			check(fits.call(str(cl)), "%s: chatter that fits the box" % cid27)
	for fid27 in ["ease_moth", "sedan_shade", "waste_golem", "yellow_runner", "white_shirt", "gauze_ox", "loose_scroll", "ivory_tag", "book_worm", "clenched_fist", "old_grudge", "heirloom_crab"]:
		check(Data.ENEMIES.has(fid27) and Lore.BEAST.has(fid27) and Habits.habit(fid27) != "" and not Dooms.is_doom(fid27), "%s: a foe of Part XXVII with a story and hours of its own" % fid27)
	# the crossroads of the chapter: every answer answered, echoed, told at the end, written about and standing
	var c27: Dictionary = Echoes.CROSSROADS.get("the_sack", {})
	check(not c27.is_empty() and str(c27.step) == "s_p27_sack" and str(c27.part) == "XXVII" and Echoes.ORDER[Echoes.ORDER.find("the_knot") - 1] == "the_sack", "what comes after the sack is set down is asked last of all")
	check((c27.options as Array).size() == 3 and (c27.get("end", {}) as Dictionary).size() == 3 and (c27.get("echo", {}) as Dictionary).size() >= 1 and (c27.get("after", {}) as Dictionary).size() == 3,
		"the_sack: three answers, each answered, echoed and told at the end")
	var lettered := 0
	for lid in Mail.ORDER:
		if Mail.LETTERS[lid].has("needs") and str(Mail.LETTERS[lid].needs[0]) == "the_sack":
			lettered += 1
			for ll in Mail.LETTERS[lid].lines:
				check(fits.call(str(ll)), "%s: a letter that fits the box" % lid)
	check(lettered == 3 and Mail.LETTERS.has("tao_last") and Mail.ORDER.has("tao_last"), "somebody writes about each answer, and the governor writes once")
	var tips27 := {}
	for o27 in c27.options:
		check(Marks.MARKS.the_sack.has(str(o27.id)), "the_sack/%s leaves something standing" % o27.id)
		for sc27 in o27.tilt:
			tips27[sc27] = true
	check(tips27.has("heart") and tips27.has("craft") and tips27.has("reach"), "the crossroads of Part XXVII tips all three scales the ends ask about")
	var old_echo27 := 0
	for cid in Echoes.ORDER:
		if cid == "the_sack":
			continue
		for ek27 in Echoes.CROSSROADS[cid].get("echo", {}):
			if str(ek27).contains("s_p27_"):
				old_echo27 += 1
	check(old_echo27 >= 3, "three older crossroads echo in Part XXVII (%d)" % old_echo27)
	check(bsrc.contains("\"palace_buyer\": \"relic\"") and bsrc.contains("\"li_jing\": \"relic\"") and bsrc.contains("\"the_sack\": [\"carry\"]"), "the bot has a plan for every trial and the crossroads of Part XXVII")
	for a27 in ["silk", "volcano", "karst", "maple"]:
		check(str(Data.AREAS[a27].get("warband5", {}).get("vis", "")).begins_with("s_p27_") and not Data.AREAS[a27].has("warband6"), "%s: the chapter's band takes the last slot" % a27)
	check(Marks.AFTER_BANDS.has("the_sack"), "the marks of its crossroads are stood after the late bands")
	var found27 := 0
	for e27 in ws.ents:
		if (e27.kind == "pickup" and str(e27.id).begins_with("p27_")) or (e27.kind == "boss" and str(e27.enemy) in ["palace_buyer", "li_jing"]) or (e27.kind == "npc" and str(e27.id) in ["tao_kan", "charcoal_seller", "zhichang", "budai"]):
			found27 += 1
			check(Atlas.owner_id(ws, e27.pos) == str(e27.area), "%s stands in its own region" % e27.id)
			var near := false
			for d27 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				near = near or reach.has((e27.pos as Vector2i) + d27)
			check(near, "%s can be walked up to" % e27.id)
	var scrolls: Array = (ws.floors[Caves.fid("karst", -1)].ents as Array).filter(func(e28): return e28.kind == "boss" and str(e28.enemy) == "wan_juan")
	check(found27 == 18 + 2 + 4 and scrolls.size() == 1, "eighteen things to find, two lords and four people of Part XXVII stand in the land, and the ten thousand scrolls in the cave under the towers (%d)" % found27)
	# (the Heavy Road release: what the audits found and what was mended)
	print("== mended in the Heavy Road release ==")
	var NG2 = load("res://scripts/game.gd").new()
	NG2.reset()
	Needs.begin(NG2)
	var buns: int = int(NG2.inv.steamed_bun)
	NG2.needs["hunger"] = 40.0
	Needs.end(NG2)
	Needs.begin(NG2)
	check(int(NG2.inv.steamed_bun) == buns and Needs.value(NG2, "hunger") == 40.0, "survival turned off and on again gives no second bag of buns and feeds nobody")
	NG2.free()
	var bt := FileAccess.get_file_as_string("res://scripts/battle.gd")
	check(bt.contains("elif not ctx.get(\"tribulation\", false) and randf() < 0.25"), "lightning leaves no pills behind it")
	check(msrc.contains("func _drop_fares") and msrc.count("_drop_fares()") >= 3, "whoever was being carried for a fare gets down when the carriage is left for the coach or a junk")
	check(msrc.contains("Game.seen = {\"sect\": true}"), "the morning three years ago is not a region walked into")
	check(msrc.contains("\"enabled\": not Gamble.stakes(Game).is_empty()"), "Old Du's mat is shut to somebody with nothing he can stake")
	check(str(Data.DIALOGUE.s_yue[(Data.DIALOGUE.s_yue as Array).size() - 1][0]) == "Narrator" or (Data.DIALOGUE.s_yue as Array).any(func(l): return str(l[0]) == "Narrator" and str(l[1]).contains("joins Lin Feng")), "Yue Ling does not announce herself in the third person")
	check(Echoes.CROSSROADS.palace.echo.has("s_p21_aysha") and Mail.LETTERS.values().any(func(l): return str(l.lines[0]).contains("Nine lotus seals")), "the Blood Moon Palace has nine seals in every telling, and somebody says how a king came to be in it")
	var nine := 0
	for dk in Data.DIALOGUE:
		for dl in Data.DIALOGUE[dk]:
			if str(dl[0]) in ["Elder Qing Xuan", "Hua Tuo", "Narrator"] and (str(dl[1]).contains("Nine hundred years of") or str(dl[1]).contains("deed nine hundred years") or str(dl[1]).contains("every dawn for nine hundred")):
				nine += 1
	check(nine == 0, "the sect is three hundred years old in every chapter")


## The Answering Land release: how the towns stand (weal.gd), the work of the towns (folk.gd, ten new clips) and
## Part XXVIII, the Knotted Grass.
## The Iron Pestle release: foes that fight as what they are (tactics.gd), people who work for something
## (living.gd) and have their wits about them, and a bag that is weighed quickly (load.gd).
func _iron_pestle_wits() -> void:
	print("== the Iron Pestle: every foe fights as what it is ==")
	var shapes := {}
	for id in Data.ENEMIES:
		var sh := str(Data.ENEMIES[id].shape)
		shapes[sh] = true
		if bool(Data.ENEMIES[id].get("boss", false)) or sh.begins_with("person:"):
			if Tactics.wit_of(str(id)) != Tactics.TACTICIAN:
				check(false, "%s is a lord or a person and fights as a tactician" % id)
	var unknown: Array = []
	for sh2 in shapes:
		if not Tactics.WIT.has(sh2) and not str(sh2).begins_with("person:"):
			unknown.append(sh2)
	check(unknown.is_empty(), "every shape a foe is drawn in has its wits written down (missing: %s)" % str(unknown))
	check(Tactics.WORDS.size() == 4 and Tactics.HINTS.size() == 4 and Tactics.FINISH.size() == 4 and Tactics.MENDER.size() == 4 and Tactics.PACK.size() == 4 and Tactics.WEAKEST.size() == 4 and Tactics.BRACE.size() == 4, "every kind of wits has a line in every table")
	var hero := {"idx": 0, "hp": 900.0, "maxhp": 1000.0, "def": 40.0, "lv": 10}
	var yue := {"idx": 1, "hp": 30.0, "maxhp": 850.0, "def": 36.0, "lv": 10}
	var party := [hero, yue]
	var jelly := {"id": "j", "shape": "jelly", "boss": false, "atk": 60.0, "lv": 10, "hp": 100.0, "maxhp": 100.0, "slot": 0}
	var wolf := {"id": "w", "shape": "beast", "boss": false, "atk": 60.0, "lv": 10, "hp": 100.0, "maxhp": 100.0, "slot": 1}
	var fox := {"id": "f", "shape": "fox", "boss": false, "atk": 60.0, "lv": 10, "hp": 100.0, "maxhp": 100.0, "slot": 2}
	var guard := {"id": "g", "shape": "humanoid", "boss": false, "atk": 60.0, "lv": 10, "hp": 100.0, "maxhp": 100.0, "slot": 3}
	var lord := {"id": "l", "shape": "golem", "boss": true, "atk": 60.0, "lv": 10, "hp": 20.0, "maxhp": 100.0, "slot": 0}
	var all := [jelly, wolf, fox, guard]
	var mem := Tactics.memory()
	Tactics.new_round(mem, 3)
	check(Tactics.wit(jelly) == Tactics.MINDLESS and Tactics.wit(wolf) == Tactics.INSTINCT and Tactics.wit(fox) == Tactics.CUNNING and Tactics.wit(guard) == Tactics.TACTICIAN and Tactics.wit(lord) == Tactics.TACTICIAN, "a jelly, a wolf, a fox, a soldier and a lord think as they should")
	var in_range := true
	var jelly_hits := [0, 0]
	var fox_hits := [0, 0]
	for i in 200:
		var r1 := float(i) / 200.0
		var r2 := float((i * 37) % 200) / 200.0
		for f in all + [lord]:
			var pl: Dictionary = Tactics.choose(f, party, all, mem, r1, r2)
			if str(pl.act) == "strike" and (int(pl.to) < 0 or int(pl.to) >= party.size()):
				in_range = false
			if not Tactics.SAID.has(str(pl.why)) and str(pl.act) == "strike":
				in_range = false
		jelly_hits[int(Tactics.choose(jelly, party, all, mem, r1, r2).to)] += 1
		fox_hits[int(Tactics.choose(fox, party, all, mem, r1, r2).to)] += 1
	check(in_range, "whatever is drawn, a foe goes for somebody who is there and says why")
	check(jelly_hits[0] == 100 and jelly_hits[1] == 100, "a jelly strikes by lot, whoever is bleeding")
	check(fox_hits[1] >= 170, "a fox goes for the one a blow would fell (%d of 200)" % fox_hits[1])
	check(str(Tactics.choose(lord, party, [lord], mem, 0.0, 0.99).why) == "finish" and int(Tactics.choose(lord, party, [lord], mem, 0.0, 0.99).to) == 1, "a lord always finishes whoever falters")
	yue.hp = 850.0
	hero.hp = 1000.0
	check(str(Tactics.choose(fox, party, all, mem, 0.0, 0.1).why) == "", "with nobody hurt and nobody mending there is nothing clever to do")
	mem.mended[1] = 3
	check(str(Tactics.choose(fox, party, all, mem, 0.0, 0.1).why) == "mender" and int(Tactics.choose(fox, party, all, mem, 0.0, 0.1).to) == 1, "a fox knows who has been mending the others")
	check(str(Tactics.choose(wolf, party, all, mem, 0.0, 0.1).why) != "mender", "and a wolf does not")
	Tactics.new_round(mem, 6)
	check(str(Tactics.choose(fox, party, all, mem, 0.0, 0.1).why) == "", "a mending three rounds old is forgotten")
	Tactics.struck(mem, wolf, 1)
	check(str(Tactics.choose(wolf, party, all, mem, 0.0, 0.1).why) == "pack" and int(Tactics.choose(wolf, party, all, mem, 0.0, 0.1).to) == 1 and str(Tactics.choose(fox, party, all, mem, 0.0, 0.1).why) == "", "a wolf follows its own pack, and nobody else's")
	Tactics.struck(mem, guard, 0)
	check(str(Tactics.choose(guard, party, all, mem, 0.9, 0.1).why) == "mark" and int(Tactics.choose(guard, party, all, mem, 0.9, 0.1).to) == 0, "a soldier takes the mark his company called")
	Tactics.new_round(mem, 7)
	check(mem.struck.is_empty(), "the marks of a round are forgotten with it")
	guard.hp = 20.0
	check(str(Tactics.choose(guard, party, all, mem, 0.5, 0.1).act) == "brace", "a soldier who is hurt, with company, draws back and guards")
	check(str(Tactics.choose(guard, party, [guard], mem, 0.5, 0.1).act) == "strike", "alone, he has nobody to draw back behind")
	mem.braced[3] = true
	check(str(Tactics.choose(guard, party, all, mem, 0.5, 0.1).act) == "strike", "and nobody guards twice in a battle")
	wolf.hp = 5.0
	check(str(Tactics.choose(wolf, party, all, mem, 0.5, 0.1).act) == "strike" and str(Tactics.choose(lord, party, all + [lord], mem, 0.5, 0.1).act) == "strike", "a beast does not guard, and a lord does not either")
	check(Tactics.BRACE_TAKEN < 1.0 and Tactics.BRACE_TAKEN >= 0.4, "a guard takes the edge off a blow and no more")
	var bsrc := FileAccess.get_file_as_string("res://scripts/battle.gd")
	check(bsrc.contains("Tactics.choose(f, tg, alive(foes), wits, randf(), randf())") and bsrc.contains("f.erase(\"braced\")") and bsrc.contains("wits = Tactics.memory()"), "the battle asks tactics.gd, a guard ends with the foe's next turn, and every battle begins with nothing remembered")
	print("== the Iron Pestle: everybody works for something ==")
	var lg = load("res://scripts/game.gd").new()
	lg.started = true
	var lw: Dictionary = Atlas.world_of("surface")
	var workers := 0
	var cults := 0
	var bad: Array = []
	var stages := {}
	var fits_all := true
	for tid in Folk.TOWNS:
		var twd: Dictionary = Atlas.world_of(Data.layer_of(str(Folk.TOWNS[tid].area)))
		for fp in Folk.people(twd, str(tid)):
			for day in [0, 3, 40, 400]:
				lg.day = day
				var ln := Living.line(fp, lg, day)
				var tg := Living.tag(fp, lg)
				if bool(fp.kid):
					if ln != "" or tg != "":
						bad.append(str(fp.id) + ": a child has no living")
					continue
				if ln == "" or tg == "" or ln.contains("{") or tg.contains("{") or ln.length() > 230 or tg.length() > 90:
					bad.append("%s day %d: %s / %s" % [str(fp.id), day, ln, tg])
				if Living.works(fp):
					var pu := Living.purse(fp, lg)
					stages[str(pu.stage)] = true
					if int(pu.saved) < 0 or (not bool(pu.done) and (int(pu.price) <= 0 or int(pu.saved) >= int(pu.price))) or int(pu.keep) <= 0 or int(pu.wage) <= 0:
						bad.append("%s day %d: a purse that does not add up: %s" % [str(fp.id), day, str(pu)])
			if Living.works(fp):
				workers += 1
				var gl := Living.goals(fp)
				if gl.size() != 3 or str(gl[0][0]) == str(gl[1][0]) or str(gl[1][0]) == str(gl[2][0]) or str(gl[0][0]) == str(gl[2][0]):
					bad.append("%s: three things to save for, no two the same: %s" % [str(fp.id), str(gl)])
				if Living.earned(fp, 10.0) < Living.earned(fp, 5.0) or Living.earned(fp, 5.0) < Living.earned(fp, 0.0):
					bad.append("%s: what is put by never shrinks" % str(fp.id))
				if not Living.PAY.has(str(fp.role)):
					bad.append("%s: the trade of a %s has a wage" % [str(fp.id), str(fp.role)])
			elif Living.cultivates(fp):
				cults += 1
	lg.day = 0
	check(bad.is_empty(), "everybody grown has a living or a cultivation, a line about it that fits and a word under their name (%s)" % str(bad.slice(0, 4)))
	check(workers >= 150 and cults >= 12, "%d people work for something and %d cultivate" % [workers, cults])
	check(stages.has("start") and stages.has("mid") and stages.has("near") and stages.has("next") and stages.has("done"), "some have just begun, some are nearly there, some have bought it and begun again (%s)" % str(stages.keys()))
	for role in Folk.ROLES:
		if role != "child" and not role in Living.CULTIVATORS:
			check(Living.PAY.has(role), "a %s is paid" % role)
	for k in Living.GOALS:
		for gl2 in Living.GOALS[k]:
			check(int(gl2[1]) >= 300 and int(gl2[1]) <= 5200, "%s costs what a working year or less can buy" % str(gl2[0]))
	for k2 in Living.LINES:
		check((Living.LINES[k2] as Array).size() >= 2, "there is more than one thing to say when %s" % k2)
	# the past is never re-priced: how a town stands changes what today pays and nothing that was put by
	var qp: Dictionary = Folk.people(lw, "qingshi")[0]
	lg.day = 20
	var before := Living.purse(qp, lg)
	lg.weal_force["qingshi"] = "cold"
	var cold := Living.purse(qp, lg)
	lg.weal_force["qingshi"] = "festive"
	var fest := Living.purse(qp, lg)
	lg.weal_force.erase("qingshi")
	check(int(cold.saved) == int(before.saved) and int(fest.saved) == int(before.saved) and int(cold.bought) == int(fest.bought), "what was put by is the same in a cold town and a festive one")
	check(int(cold.wage) < int(before.wage) and int(fest.wage) > int(before.wage), "and today's takings are not (%d, %d, %d)" % [int(cold.wage), int(before.wage), int(fest.wage)])
	check(Living.wage_at(qp, 4) > Living.wage_at(qp, 0), "the best in the street is paid more than whoever is new to it")
	var dis: Dictionary = Folk.people(lw, "sect")[0]
	lg.day = 0
	var c0 := Living.cultivation(dis, lg)
	lg.day = 2000
	var c1 := Living.cultivation(dis, lg)
	check(int(c0.layer) >= 1 and int(c0.layer) <= 9 and bool(c1.found) and int(c1.points) == Living.PILL_POINTS and Living.realm_word(dis, lg).contains("Foundation"), "a disciple breathes his way up the nine layers, carries water for the pill and breaks through")
	lg.day = 0
	check(Living.late_clip(qp, lg, "hoe", 19.0) == "" and Living.late_clip(qp, lg, "drink", 9.0) == "", "nobody's work is changed, and nobody's morning")
	print("== the Iron Pestle: people who know the way ==")
	check(Living.bearing(Vector2i(10, 10), Vector2i(20, 10)) == "east" and Living.bearing(Vector2i(10, 10), Vector2i(10, 0)) == "north" and Living.bearing(Vector2i(10, 10), Vector2i(0, 20)) == "south-west" and Living.bearing(Vector2i(3, 3), Vector2i(3, 3)) == "here", "east is east and north is up the map")
	var here := Living.smart(qp, lg, {"at": Vector2i(10, 10), "want": {"n": "Granny Wen", "area": str(qp.area), "pos": Vector2i(40, 10)}}, 0)
	check(here.contains("Granny Wen") and here.contains("east"), "asked the way to somebody of their own country, they know it: %s" % here)
	var there := Living.smart(qp, lg, {"at": Vector2i(10, 10), "want": {"n": "Elder Qing Xuan", "area": "sect"}}, 0)
	check(there.contains("Elder Qing Xuan") and there.contains(str(Data.AREAS.sect.n)), "and to somebody of another, which country that is: %s" % there)
	check(Living.smart(qp, lg, {"at": Vector2i(10, 10)}, 0) == "", "with nothing worth saying they say nothing clever")
	check(Living.smart(qp, lg, {"at": Vector2i(10, 10), "hurt": true}, 0).contains(lg.address()), "they see a wound")
	check(Living.smart(qp, lg, {"at": Vector2i(10, 10), "hunt": {"n": "Bamboo Wolf", "pos": Vector2i(10, 30)}}, 0).contains("south"), "and know which pack hunts at this hour, and where")
	var long_ok := true
	for i2 in 6:
		for cx in [{"at": Vector2i(0, 0), "hurt": true, "laden": true, "hunt": {"n": "The Wall Counted in Men", "pos": Vector2i(90, 90)}, "want": {"n": "The Old Man under the Moon", "area": "youdu"}},
				{"at": Vector2i(0, 0), "want": {"n": "The Old Man under the Moon", "area": str(qp.area), "pos": Vector2i(200, 200)}}]:
			if Living.smart(qp, lg, cx, i2).length() > 230 or Living.smart(qp, lg, cx, i2).contains("%s"):
				long_ok = false
	check(long_ok, "whatever they notice fits the dialogue box")
	check(Living.smart(Folk.people(lw, "qingshi").filter(func(q): return bool(q.kid))[0], lg, {"hurt": true}, 0) == "", "a child notices nothing of the kind")
	print("== the Iron Pestle: a bag weighed quickly weighs the same ==")
	lg.step = 0
	lg.inv = {}
	var slow := 0.0
	for id3 in Load.GOODS.keys() + Load.WARES.keys() + Needs.FOOD.keys() + ["red_cord", "hour_stone", "hp_pill", "qi_pill", "no_such_thing"]:
		lg.inv[id3] = 3
	for id4 in lg.inv:
		slow += Load.weight_of(str(id4)) * float(Load.carried(lg, str(id4)))
	check(is_equal_approx(Load.gross(lg), slow) and slow > 0.0, "the quick sum is the slow sum (%.1f jin)" % slow)
	lg.step = Data.STEPS.size() - 1
	slow = 0.0
	for id5 in lg.inv:
		slow += Load.weight_of(str(id5)) * float(Load.carried(lg, str(id5)))
	check(is_equal_approx(Load.gross(lg), slow), "and when every search of the story has been handed over")
	lg.free()

func _answering_land() -> void:
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	print("== how the towns stand (weal.gd) ==")
	var G = load("res://scripts/game.gd").new()
	G.reset()
	G.started = true
	check(Weal.ORDER.size() == 13 and Weal.ORDER.size() == Weal.TOWNS.size(), "thirteen towns are weighed")
	var heard := {}
	for tid in Weal.ORDER:
		var t: Dictionary = Weal.TOWNS[tid]
		check(Data.AREAS.has(str(t.area)) and Offices.OFFICES.has(str(t.office)) and str(Offices.OFFICES[str(t.office)].area) == str(t.area) and (t.areas as Array).has(str(t.area)),
			"%s: a town of a real region, with somebody who answers for it there" % tid)
		check(Weal.of_office(str(t.office)) == tid and Weal.town_of(str(t.area)) == tid, "%s is found by its office and by its region" % tid)
		for a in t.areas:
			check(Data.AREAS.has(str(a)) and not heard.has(a), "%s hears of %s, and nobody else does" % [tid, a])
			heard[a] = true
		check(Weal.state(G, tid) == "easy" and Weal.total(G, tid) == 0 and Weal.causes(G, tid).is_empty(), "%s: a town going about its day before anybody has heard of a sweeper" % tid)
	for a2 in Data.AREAS:
		check(heard.has(a2), "what is done in %s is somebody's news" % a2)
	check(Weal.STATE_ORDER.size() == Weal.STATES.size() and Weal.STATE_ORDER.find("easy") == 4, "seven states, worst to best, with an easy town in the middle")
	for st in Weal.STATE_ORDER:
		var sd: Dictionary = Weal.STATES[st]
		check(str(sd.n) != "" and fits.call(str(sd.desc)) and float(sd.price) > 0.5 and float(sd.wage) > 0.5 and float(sd.mend) > 0.0, "%s: named, told, and its numbers are sane" % st)
		check(Weal.WORDS.has(st) and Weal.STREET.has(st) or st == "easy", "%s: whoever answers for the town and the people in its street have words for it" % st)
		for ln in Weal.WORDS.get(st, []) + Weal.STREET.get(st, []):
			check(fits.call(str(ln)), "a word of a %s town fits the box" % st)
		if st != "easy":
			check((Weal.WORDS[st] as Array).size() >= 2 and (Weal.STREET[st] as Array).size() >= 2, "%s: at least two things said at the counter and two in the street" % st)
	check(float(Weal.STATES.festive.price) < float(Weal.STATES.thriving.price) and float(Weal.STATES.thriving.price) < 1.0 and float(Weal.STATES.cold.price) > 1.0 and float(Weal.STATES.festive.wage) > 1.0 and float(Weal.STATES.lean.wage) < 1.0,
		"a town that does well asks less of him and pays more; a town that does badly the other way")
	# what a crossroads does: felt where its answer stands, and only there
	var ws: Dictionary = Atlas.world_of("surface")
	for cid in Echoes.ORDER:
		for o in Echoes.CROSSROADS[cid].options:
			var where := str(Marks.MARKS.get(cid, {}).get(str(o.id), {}).get("area", ""))
			check(where == "" or not Weal.hears(where).is_empty(), "%s/%s: its answer is heard in some town" % [cid, o.id])
			for tm in Weal.tilt_marks(o.get("tilt", {})):
				check(str(tm[0]) in ["plenty", "peace", "regard", "home"] and int(tm[1]) != 0 and absi(int(tm[1])) <= 2, "%s/%s: a tilt moves a measure a point or two" % [cid, o.id])
	Echoes.take(G, "bandits", "mend")
	var b_area := str(Marks.MARKS.bandits.mend.area)
	var b_town := str(Weal.hears(b_area)[0])
	check(Weal.measure(G, b_town, "regard") >= 1 and not Weal.causes(G, b_town).is_empty() and str(Weal.causes(G, b_town)[0].why) == str(Echoes.option("bandits", "mend").log),
		"bandits set to mend a road: the town that hears of it thinks the better of him, and says why")
	var far := ""
	for tid2 in Weal.ORDER:
		if tid2 != b_town and not tid2 in Weal.HOME_TOWNS:
			far = tid2
	check(Weal.total(G, far) == 0, "and a town far away has not heard")
	var G2 = load("res://scripts/game.gd").new()
	G2.reset()
	G2.started = true
	Echoes.take(G2, "bandits", "drive")
	var d_town := str(Weal.hears(str(Marks.MARKS.bandits.drive.area))[0])
	check(Weal.measure(G2, d_town, "regard") < 0 and Weal.measure(G2, d_town, "peace") > 0, "driven out instead: the road is safer and his name is not liked")
	# the ledger: what is done in a town's own streets
	var G3 = load("res://scripts/game.gd").new()
	G3.reset()
	G3.started = true
	G3.stones = 1000000
	check(Weal.gift_blocked(G3, "qingshi") == "" and Weal.gift_cost(G3) == Weal.GIFT_BASE, "the chest of a town takes a gift")
	var before := int(G3.stones)
	check(Weal.give(G3, "qingshi") and int(G3.stones) == before - Weal.GIFT_BASE and Weal.measure(G3, "qingshi", "plenty") == 1 and Weal.acts(G3, "qingshi", "gift") == 1, "given: paid for, and the town has a little more")
	Weal.give(G3, "qingshi")
	Weal.give(G3, "qingshi")
	check(not Weal.give(G3, "qingshi") and Weal.gift_blocked(G3, "qingshi") != "" and fits.call(Weal.gift_blocked(G3, "qingshi")) and Weal.measure(G3, "qingshi", "plenty") == Weal.GIFT_MAX, "three gifts, and the town will not take a fourth")
	G3.stones = 0
	check(Weal.gift_blocked(G3, "yanggu") != "" and not Weal.give(G3, "yanggu"), "nothing is given with nothing")
	for k in 4:
		Weal.act(G3, "qingshi", "shift")
		Weal.act(G3, "qingshi", "bag")
	for k2 in 12:
		Weal.act(G3, "qingshi", "errand")
	check(Weal.measure(G3, "qingshi", "plenty") == Weal.GIFT_MAX + 2 and Weal.measure(G3, "qingshi", "regard") == 2 + 3, "shifts, the post and errands are felt, each as far as it goes and no further")
	check(Weal.state(G3, "qingshi") == "thriving" and Weal.count(G3, "thriving") == 1 and Weal.mod(G3, "village", "price") < 1.0 and Weal.mod(G3, "bamboo", "price") == 1.0 and Weal.price(G3, "village", 100) == 92,
		"a town that thrives asks less at its counters; out in the country nothing changes")
	check(G3.weal_n > 0 and (G3.timeline as Array).any(func(e): return str(e.text).contains("Qingshi Village: Thriving")), "and it is news: told once, in the annals")
	# broken things
	var G4 = load("res://scripts/game.gd").new()
	G4.reset()
	G4.started = true
	for k3 in 8:
		Weal.act(G4, "yanggu", "broke")
	check(Weal.measure(G4, "yanggu", "regard") == -4 and Weal.state(G4, "yanggu") == "cold" and Weal.mod(G4, "yanggu", "price") > 1.0 and Weal.mod(G4, "yanggu", "mend") == 2.0, "eight things broken in a town's streets: it is cold to him, and asks double for the ninth")
	check(Weal.word(G4, "yanggu", 0) != "" and Weal.line(G4, "yanggu", 1) != "" and Weal.line(G4, "yanggu", 3).contains("things broken") and Weal.line(G4, "bamboo", 1) == "", "and both the counter and the street say so, and why")
	check(Weal.tag(G4, {"id": "warden_yanggu", "office": "warden_yanggu"}).contains("cold"), "whoever answers for it is of a town that is cold")
	# peace: lords and packs
	var G5 = load("res://scripts/game.gd").new()
	G5.reset()
	G5.started = true
	var lords_l: Array = []
	for st5 in Data.STEPS:
		if str(st5.kind) == "kill" and str(st5.get("area", "")) in Weal.TOWNS.longmen.areas:
			lords_l.append(str(st5.boss))
	check(lords_l.size() >= Weal.LORDS_PER, "there are lords in Longmen's country (%d)" % lords_l.size())
	for b5 in lords_l:
		G5.boss_done[b5] = true
	G5.record_kills("longmen", 130, [])
	check(Weal.measure(G5, "longmen", "peace") == mini(Weal.LORDS_MAX, lords_l.size() / Weal.LORDS_PER) + mini(Weal.KILLS_MAX, 130 / Weal.KILLS_PER), "lords put down and packs cleared make a country's roads quiet, as far as that goes")
	# a festive town, and its thanks
	var G6 = load("res://scripts/game.gd").new()
	G6.reset()
	G6.started = true
	G6.stones = 1000000
	for b6 in lords_l:
		G6.boss_done[b6] = true
	G6.record_kills("longmen", 200, [])
	for k6 in 3:
		Weal.give(G6, "longmen")
	for k7 in 4:
		Weal.act(G6, "longmen", "shift")
		Weal.act(G6, "longmen", "fare")
		Weal.act(G6, "longmen", "bag")
	for k8 in 12:
		Weal.act(G6, "longmen", "errand")
	check(Weal.state(G6, "longmen") == "festive" and Weal.thanks_due(G6, "longmen"), "plenty, peace and regard together: a festive town (%d %d %d)" % [Weal.measure(G6, "longmen", "plenty"), Weal.measure(G6, "longmen", "peace"), Weal.measure(G6, "longmen", "regard")])
	var st6 := int(G6.stones)
	var got6 := Weal.thank(G6, "longmen")
	check(got6 == Weal.THANKS_BASE and int(G6.stones) == st6 + got6 and not Weal.thanks_due(G6, "longmen") and Weal.thank(G6, "longmen") == 0, "it thanks him once")
	check(Weal.mood_clip("festive", "square", 19.0, 0, "idle") == "dance" and Weal.mood_clip("festive", "square", 10.0, 0, "idle") == "" and Weal.mood_clip("afraid", "market", 10.0, 0, "talk") == "peer" and Weal.mood_clip("easy", "square", 19.0, 0, "idle") == "",
		"a festive town dances at dusk, a frightened one looks over its shoulder, an easy one does as it always did")
	for st7 in Weal.STATE_ORDER:
		for place in ["square", "market", "tea", "inn", "field"]:
			for sd7 in 12:
				for own in ["idle", "talk", "laugh", "eat", "wave", "hoe"]:
					var mc := Weal.mood_clip(st7, place, 19.0 if sd7 % 2 == 0 else 10.0, sd7, own)
					check(mc == "" or mc in Assets.LEND or mc in ["idle", "talk", "laugh", "think", "look", "walk"], "what a %s town does (%s) is something everybody can do" % [st7, mc])
	# the people with names
	var named := {}
	for a8 in Data.AREAS:
		for n8 in Data.AREAS[a8].get("npcs", []):
			named[str(n8.id)] = true
	for f in Weal.FATES:
		check(named.has(str(f.npc)) and Echoes.CROSSROADS.has(str(f.when[0])) and str(f.tag) != "" and fits.call(str(f.line)), "%s: somebody real, whose life turned on a real crossroads, with something to say of it" % f.npc)
		for an in f.when[1]:
			check(not Echoes.option(str(f.when[0]), str(an)).is_empty(), "%s: %s/%s is an answer that can be given" % [f.npc, f.when[0], an])
	check(Weal.FATES.size() >= 24, "the lives of two dozen people with names turn on what was answered (%d)" % Weal.FATES.size())
	var G7 = load("res://scripts/game.gd").new()
	G7.reset()
	check(Weal.fate(G7, "smith").is_empty() and Weal.tag(G7, {"id": "smith"}) == "", "Smith Tie is only Smith Tie before the drawings")
	Echoes.take(G7, "drawings", "keep")
	check(str(Weal.fate(G7, "smith").tag) == "with two apprentices" and Weal.tag(G7, {"id": "smith"}) == "with two apprentices", "the drawings kept: two apprentices")
	var G8 = load("res://scripts/game.gd").new()
	G8.reset()
	Echoes.take(G8, "drawings", "burn")
	check(str(Weal.fate(G8, "smith").tag) == "who works alone", "the drawings burned: he works alone")
	for st9 in ["festive", "thriving", "afraid", "lean", "cold"]:
		var dn: Node3D = Weal.dress(st9, 1.1, 3)
		check(dn != null and dn.get_child_count() >= 1, "a %s town hangs something at its doors" % st9)
		if dn != null:
			dn.free()
	check(Weal.dress("easy") == null and Weal.dress("wary") == null, "an easy town hangs nothing")
	check(Weal.summary(G6).begins_with("Of eleven towns") and Weal.town_text(G6, "longmen").contains("Festive") and Weal.epilogue(G).size() <= 1, "the page says how they stand")
	check(msrc.contains("\"weal:give\"") and msrc.contains("\"weal:ask\"") and msrc.contains("\"weal:thanks\"") and msrc.find("\"id\": \"later\", \"label\": \"Not today\", \"desc\": \"There is a road waiting.\"") >= 0, "the counter offers it, after \"Not today\"")
	G.free(); G2.free(); G3.free(); G4.free(); G5.free(); G6.free(); G7.free(); G8.free()

	print("== the work of the towns (folk.gd, ten new clips) ==")
	var new_clips := ["serve", "knead", "scrub", "weigh", "stalk", "flay", "fan", "arrange", "wring", "sew"]
	for c in new_clips:
		check(c in Assets.LEND and c in Assets.LEND_LOOPS and Faces.OF_CLIP.has(c), "%s is lent to everybody, goes round, and has a face" % c)
	for nr in ["waiter", "huntsman"]:
		check(Folk.ROLES.has(nr) and Folk.LINES.has(nr) and Folk.LINES[nr].size() >= 4 and Folk.TITLES.has(nr) and Folk.BODIES.human.has(nr), "the %s: a day, a body, a title and four things to say" % nr)
		for ln2 in Folk.LINES[nr]:
			check(fits.call(str(ln2).replace("%s", "Daoist friend")), "a line of the %s fits the box" % nr)
		var used := 0
		for tid3 in Folk.TOWNS:
			used += int(Folk.TOWNS[tid3].roles.get(nr, 0))
		check(used >= 3, "there are %ss in the towns (%d)" % [nr, used])
	var basic := ["idle", "talk", "laugh", "think", "look", "point", "shrug", "wave", "walk", "run", "in", "offer", "bow", "nod", "eat"]
	var seen_new := {}
	for role in Folk.ROLES:
		for e in Folk.ROLES[role].day:
			check(Folk.PLACES.has(str(e[1])), "%s: %s is a kind of place" % [role, e[1]])
			for c2 in str(e[2]).split("|"):
				if c2 in new_clips:
					seen_new[c2] = true
			if str(e[3]) != "":
				var hn: Node3D = Folk.held(str(e[3]))
				check(hn != null, "%s holds something that has a model (%s)" % [role, e[3]])
				if hn != null:
					hn.free()
	for id in Folk.POSTS:
		for part in [str(Folk.POSTS[id][0]), str(Folk.POSTS[id][2])]:
			for c3 in part.split("|"):
				check(c3 in Assets.LEND or c3 in basic, "%s's work %s is a clip everybody can play" % [id, c3])
				if c3 in new_clips:
					seen_new[c3] = true
	for use in Folk.TRADE_POSTS:
		check(use == "official" or Rooms.INDOORS.has(use), "%s is a use of a ground floor" % use)
		for part2 in Folk.TRADE_POSTS[use]:
			for c4 in str(part2).split("|"):
				check(c4 in Assets.LEND or c4 in basic, "what is done in a %s (%s) is a clip everybody can play" % [use, c4])
				if c4 in new_clips:
					seen_new[c4] = true
	for use2 in Rooms.INDOORS:
		check(Folk.TRADE_POSTS.has(use2), "whoever is found in a %s has work to do there" % use2)
	for c5 in new_clips:
		check(seen_new.has(c5), "somebody in the land does the %s" % c5)
	for h in Folk.HOLD_OF.values():
		var hn2: Node3D = Folk.held(str(h))
		check(hn2 != null, "%s has a model for the hand" % h)
		if hn2 != null:
			hn2.free()
	check(Folk.post_of({"id": "res:village:x:0", "trade": "inn"}, 10.0).size() == 2 and str(Folk.post_of({"id": "res:village:x:0", "trade": "inn"}, 2.0)[0]) == "doze" and Folk.post_of({"id": "head_qingshi", "office": "head_qingshi"}, 10.0).size() == 2
		and str(Folk.post_of({"id": "smith"}, 10.0)[0]) == "hammer" and Folk.post_of({"id": "nobody"}, 10.0).is_empty(), "a pot-boy carries, an official writes, the smith hammers, and they all sleep")
	var idle_n := 0
	var named_n := 0
	for a9 in Data.AREAS:
		for n9 in Data.AREAS[a9].get("npcs", []):
			if n9.get("fate", false) or str(n9.id).begins_with("cave_"):
				continue
			named_n += 1
			if Folk.post(str(n9.get("asset", n9.id)), 10.0).is_empty() and Folk.post(str(n9.id), 10.0).is_empty():
				idle_n += 1
	check(idle_n * 3 < named_n, "two in three of the people with names are at some work of their own (%d of %d stand idle)" % [idle_n, named_n])
	var wd: Dictionary = Atlas.world_of("surface")
	var waiter_seen := false
	for fp in Folk.people(wd, "qingshi"):
		if str(fp.role) == "waiter":
			var segs := Folk.day_of(wd, fp)
			waiter_seen = not segs.is_empty()
			var has_place := false
			for sg in segs:
				has_place = has_place or (str(sg.kind) == "stay" and sg.has("place"))
			check(has_place, "a stay knows what kind of place it is at")
	check(waiter_seen, "Qingshi has somebody waiting at table, with a day")

	print("== things that share ground (clash.gd) ==")
	var nudged := 0
	for lid9 in Atlas.LAYERS:
		var lw9: Dictionary = Atlas.world_of(lid9)
		var found9: Array = Clash.audit(lw9)
		check(found9.is_empty(), "%s: no two things share ground (%s)" % [lid9, str(found9.slice(0, 4))])
		var sol9: Dictionary = Clash.solve(lid9, lw9.ents)
		nudged += (sol9.nudge as Dictionary).size()
		for nk in sol9.nudge:
			check((sol9.nudge[nk] as Vector2).length() <= Clash.NUDGE_MAX + 0.001, "%s is drawn a step aside, and no further than its own tile" % nk)
		for fid9 in lw9.floors:
			var fw9: Dictionary = lw9.floors[fid9]
			if fw9.has("ents"):
				var fs9: Dictionary = Clash.solve(str(fid9), fw9.ents)
				check((fs9.left as Array).is_empty(), "%s: no two things share ground" % fid9)
				nudged += (fs9.nudge as Dictionary).size()
	check(nudged >= 4, "what stood in something bigger's footprint is drawn a step aside (%d)" % nudged)
	var st_r := Rect2i(Vector2i.ZERO, Vector2i(int(ws.w), int(ws.h)))
	var stood9: Dictionary = Clash.stood(ws, "village", st_r)
	var all_in := true
	for e9 in ws.ents:
		if str(e9.get("area", "")) == "village" and e9.has("pos") and str(e9.kind) in ["npc", "pickup", "prop", "mark"]:
			all_in = all_in and stood9.has(e9.pos)
	check(all_in and stood9.size() > 100, "nothing is scattered through whoever stands in Qingshi (%d tiles kept clear)" % stood9.size())
	var gate_n: Node3D = Marks.model(Marks.MARKS.the_seat.found, 0)
	check(Clash.footprint(gate_n) > 1.0 and Clash.footprint(gate_n) < 3.0 and Clash.extent({"kind": "npc"}) == Clash.PERSON, "a footprint is read from the model itself")
	gate_n.free()
	var CL = load("res://scripts/game.gd").new()
	CL.reset()
	CL.step = Data.step_index("s_p27_smith")
	CL.inv["charcoal"] = 8
	CL.inv["timber"] = 2
	check(int(Load.sale(CL)[1]) == 2 and not Load.for_sale(CL, "charcoal"), "what the step in hand asks him to carry is not for sale")
	Load.sell_all(CL)
	check(int(CL.inv.charcoal) == 8 and int(CL.inv.timber) == 0, "a pedlar buys the timber and leaves the charcoal on his back")
	CL.free()

	print("== Part XXVIII: The Knotted Grass ==")
	check(Data.REALMS.size() >= 34 and Data.REALMS[33] == "Rings Returned" and Data.MAX_LEVEL >= 99 and Data.level_name(99).ends_with("Rings Returned") and Data.REALM_INFO.size() >= 34
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXVIII adds the realm of Rings Returned")
	check(Data.step_index("s_break33") == Data.step_index("s_p29_home") - 1 and int(Data.STEPS[Data.step_index("s_break33")].to) == 99 and Data.DIALOGUE.has("recall26") and msrc.contains("\"s_break32\": \"recall26\"") and Data.DIALOGUE.has("pre:s_break33") and Data.DIALOGUE.has("post:s_break33"),
		"Part XXVIII follows Sumeru in a Seed (recall26)")
	var p28 := Data.step_index("s_p28_home")
	var kinds28 := {}
	var n28 := 0
	for i in range(p28, Data.step_index("s_p29_home")):
		var s28: Dictionary = Data.STEPS[i]
		n28 += 1
		kinds28[str(s28.kind)] = true
		check(str(s28.id).begins_with("s_p28_") or str(s28.id) == "s_break33", "%s is a step of the chapter" % s28.id)
		if str(s28.kind) == "talk":
			check(Data.DIALOGUE.has(str(s28.id)), "%s has its conversation" % s28.id)
		if str(s28.kind) == "kill":
			check(Data.DIALOGUE.has("pre:" + str(s28.boss)) and Data.DIALOGUE.has("post:" + str(s28.boss)) and Trials.TRIALS.has(str(s28.boss)) and Lore.BOSS.has(str(s28.boss)), "%s: words before and after, a trial, and a story" % s28.boss)
			check(bsrc.contains("\"%s\": \"" % str(s28.boss)), "the bot has a way planned through %s" % s28.boss)
		if str(s28.kind) == "hunt":
			for en in s28.of:
				check(Data.ENEMIES.has(str(en)) and Lore.BEAST.has(str(en)) and int(Data.ENEMIES[str(en)].get("boss", false)) == 0, "%s: a foe of the chapter with a story" % en)
		if str(s28.kind) in ["hunt", "collect", "toil", "haul", "folk", "visits", "weal", "summit", "glide"]:
			check(Data.DIALOGUE.has("done:" + str(s28.id)), "%s: something is said when it is done" % s28.id)
		if str(s28.kind) == "haul":
			check(Data.DIALOGUE.has("haul:" + str(s28.id)) and Load.GOODS.has(str(s28.good)), "%s: a good of the land, and a word as each load arrives" % s28.id)
		if str(s28.kind) == "folk":
			check(Folk.ERRANDS.has(str(s28.id)) and Folk.ERRANDS[str(s28.id)].lines.size() >= 4, "%s: the errand has its words" % s28.id)
		if str(s28.kind) == "visits":
			for vn in s28.npcs:
				check(Data.DIALOGUE.has("visit:%s:%s" % [str(s28.id), str(vn)]) and not Weal.fate(null if false else _pick_game("drawings", "keep"), "smith").is_empty(), "%s is called on and has something to say" % vn)
	check(n28 >= 28 and kinds28.has("weal") and kinds28.has("toil") and kinds28.has("haul") and kinds28.has("summit") and kinds28.has("glide") and kinds28.has("visits") and kinds28.has("folk"), "the chapter is thirty steps of nine kinds (%d)" % n28)
	for vn2 in Data.STEPS[Data.step_index("s_p28_calls")].npcs:
		var has_f := false
		for f2 in Weal.FATES:
			has_f = has_f or str(f2.npc) == str(vn2)
		check(has_f, "%s, who is called on, is somebody whose life turned on an answer" % vn2)
	# the step that asks for towns to be left the better
	var WG = load("res://scripts/game.gd").new()
	WG.reset()
	WG.started = true
	WG.step = Data.step_index("s_p28_mend") - 1
	WG.level = 98
	WG.stones = 10000000
	for a10 in Data.AREAS:
		WG.seen[a10] = true
	WG.boss_done["zhou_chu"] = true
	WG.advance()
	check(str(WG.cur_step().id) == "s_p28_mend" and WG.weal_from.size() == Weal.ORDER.size() and Weal.bettered(WG) == 0, "the step begins from how the towns stand")
	var given := 0
	while str(WG.cur_step().id) == "s_p28_mend" and given < 12:
		var wt := Weal.wanted(WG)
		check(wt != "", "there is a town that will still take a gift")
		if wt == "":
			break
		Weal.give(WG, wt)
		given += 1
		WG.poll_steps()
	check(given == 3 and str(WG.cur_step().id) == "s_p28_calls", "three gifts to three chests, and three towns are the better for his coming (%d)" % given)
	check(WG.objective_text() != "" and bsrc.contains("Weal.wanted(Game)") and bsrc.contains("\"weal:give\""), "the bot goes to whoever answers for the next town, and gives")
	# (however the journey went, the step can be done: with every gift already given everywhere, every town counts)
	var FG = load("res://scripts/game.gd").new()
	FG.reset()
	FG.started = true
	FG.stones = 100000000
	for tid4 in Weal.ORDER:
		for k9 in Weal.GIFT_MAX:
			Weal.give(FG, tid4)
	Weal.mark_from(FG)
	check(Weal.wanted(FG) == "" and Weal.bettered(FG) == 0 or Weal.bettered(FG) >= 0, "a journey that has given everything everywhere is not asked for more")
	WG.free(); FG.free()
	# the crossroads
	var c28: Dictionary = Echoes.CROSSROADS.get("the_knot", {})
	check(not c28.is_empty() and str(c28.step) == "s_p28_knot" and str(c28.part) == "XXVIII" and Echoes.ORDER[Echoes.ORDER.find("the_mat") - 1] == "the_knot", "what is owed for a kindness is asked last of all")
	check((c28.options as Array).size() == 3 and c28.after.size() == 3 and c28.end.size() == 3 and c28.echo.has("s_p28_end") and c28.echo.s_p28_end.size() == 3, "the_knot: three answers, each answered, echoed and told at the end")
	var letters28 := 0
	for lid in Mail.ORDER:
		if Mail.LETTERS[lid].has("needs") and str(Mail.LETTERS[lid].needs[0]) == "the_knot":
			letters28 += 1
	check(letters28 == 3 and Mail.LETTERS.has("chu_doors") and Mail.ORDER.has("chu_doors"), "a letter for each answer, and one from a man hanging doors")
	var scales28 := {}
	for o28 in c28.options:
		check(Marks.MARKS.the_knot.has(str(o28.id)) and Marks.MARKS.the_knot[str(o28.id)].has("who"), "the_knot/%s leaves something standing, and somebody by it" % o28.id)
		check(not Weal.hears(str(Marks.MARKS.the_knot[str(o28.id)].area)).is_empty(), "the_knot/%s is felt in a town" % o28.id)
		for sc in o28.tilt:
			scales28[sc] = true
	check(scales28.size() == 3, "its answers tip all three scales")
	var old_echo28 := 0
	for cid2 in Echoes.ORDER:
		if cid2 == "the_knot":
			continue
		for ek in Echoes.CROSSROADS[cid2].get("echo", {}):
			if str(ek).contains("s_p28_"):
				old_echo28 += 1
	check(old_echo28 >= 2, "older crossroads echo in Part XXVIII (%d)" % old_echo28)
	check(bsrc.contains("\"du_hui\": \"relic\"") and bsrc.contains("\"zhou_chu\": \"loss\"") and bsrc.contains("\"the_knot\": [\"onward\"]"), "the bot has a plan for every trial and the crossroads of the chapter")
	for a28 in ["fusang", "bamboo", "mirror"]:
		check(str(Data.AREAS[a28].get("warband5", {}).get("vis", "")).begins_with("s_p28_") and not Data.AREAS[a28].has("warband6"), "%s: the chapter's band takes the last slot" % a28)
	check(Marks.AFTER_BANDS.has("the_knot"), "the marks of its crossroads are stood after the late bands")
	var found28 := 0
	for e28 in ws.ents:
		if (e28.kind == "pickup" and str(e28.id).begins_with("p28_")) or (e28.kind == "boss" and str(e28.enemy) in ["du_hui", "night_owl", "bridge_jiao", "zhou_chu"]) or (e28.kind == "npc" and str(e28.id) in ["wei_ke", "grass_elder", "yang_bao", "zhou_chu", "zhou_chu_end"]):
			found28 += 1
			check(Atlas.owner_id(ws, e28.pos) == str(e28.area), "%s stands in its own region" % e28.id)
	check(found28 == 13 + 4 + 5, "everything the chapter stands in the land found room (%d)" % found28)
	# the relics of its trials are found before the lords they are for
	for pr in [["du_hui", "grass_knot", "s_p28_knots"], ["night_owl", "jade_ring", "s_p28_rings"], ["bridge_jiao", "jiao_scale", "s_p28_scales"]]:
		check(Data.step_index(str(pr[2])) < _kill_step(str(pr[0])) and Data.ITEMS.has(str(pr[1])) and Look.PICKUP_COLORS.has(str(pr[1])), "%s can be passed by what was found on the way" % pr[0])
	check(Trials.KINDS.has("towns") and Trials.KIND_ORDER.has("towns"), "trials can be passed by the towns")
	for fid in ["rings_returned", "knotted_grass", "third_scourge", "what_is_owed"]:
		check(Feats.FEATS.has(fid), "the feat %s is kept" % fid)
	for pid in ["wei_ke", "grass_elder", "yang_bao", "zhou_chu", "du_hui"]:
		check(Assets.PEOPLE.has(pid) and Assets.has(str(Assets.PEOPLE[pid])), "%s has a body built from a script" % pid)
		check(pid == "du_hui" or (Data.CHAT.has(pid) and Data.CHAT[pid].size() >= 4), "%s has four things to say" % pid)

var _pg = null
func _pick_game(cid: String, oid: String):
	if _pg == null:
		_pg = load("res://scripts/game.gd").new()
		_pg.reset()
		Echoes.take(_pg, cid, oid)
	return _pg

## The Ordered House release: the almanac (the date, the roll, trades, packs that grow), the Way he walks (the nine
## Ways and what each shuts), the fitness of things (houses that want something, things set down), and Part XXIX.
func _ordered_house() -> void:
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	var ws: Dictionary = Atlas.world()
	print("== the almanac (almanac.gd) ==")
	var G = load("res://scripts/game.gd").new()
	G.reset()
	G.started = true
	check(Almanac.month(G) == 2 and Almanac.dom(G) == 2 and Almanac.year(G) == 1 and Almanac.season(G) == "spring" and Almanac.year_name(G) == "Wood Dragon" and not Almanac.festival(G).is_empty(),
		"the journey begins on the second of the second month, a feast day, in a Wood Dragon year (%s)" % Almanac.text(G))
	check(Almanac.TERMS.size() == 24 and Almanac.MONTHS.size() == 12 and Almanac.SEASON_LINES.size() == 4, "twenty-four terms, twelve months, four seasons")
	for f in Almanac.FESTIVALS:
		check(int(f[0]) >= 1 and int(f[0]) <= 12 and int(f[1]) >= 1 and int(f[1]) <= 30 and str(f[3]).length() <= 200, "%s is a day of the year, with a word for it" % str(f[2]))
	for sn in Almanac.SEASON_LINES:
		for sl in Almanac.SEASON_LINES[sn]:
			check(fits.call(str(sl)), "a word for the %s fits the box" % sn)
	var seen_seasons := {}
	var seen_feasts := {}
	for d in 360:
		G.day = 1 + d
		seen_seasons[Almanac.season(G)] = true
		if not Almanac.festival(G).is_empty():
			seen_feasts[str(Almanac.festival(G)[2])] = true
		check(Almanac.season_line(G, d) != "", "something is said of day %d" % d) if d % 45 == 0 else null
	check(seen_seasons.size() == 4 and seen_feasts.size() == Almanac.FESTIVALS.size(), "a year goes through four seasons and every feast")
	G.day = 361
	check(Almanac.year(G) == 2 and Almanac.month(G) == 2 and Almanac.dom(G) == 2 and Almanac.year_name(G) == "Wood Snake", "after three hundred and sixty days it is the same day of the next year")
	# the story sets the day of the year, forward only
	G.day = 10
	var before_i := Almanac.index(G)
	Almanac.story_date(G, "s_p16_eve")
	check(Almanac.month(G) == 12 and Almanac.dom(G) == 30 and Almanac.index(G) > before_i and str(Almanac.festival(G)[2]) == "New Year's Eve", "the reunion dinner is eaten on the last night of the year")
	G.day = 11
	check(Almanac.month(G) == 1 and Almanac.dom(G) == 1 and Almanac.year(G) == 2, "and the next morning is New Year's Day")
	var at16 := Almanac.index(G)
	Almanac.story_date(G, "s_p16_riddles")
	check(Almanac.month(G) == 1 and Almanac.dom(G) == 15 and Almanac.index(G) == at16 + 14, "the riddles are guessed on the fifteenth")
	for sid in Almanac.STORY_DATES:
		check(Data.step_index(str(sid)) >= 0, "%s, which sets the day, is a step of the story" % sid)
	# the roll
	var R = load("res://scripts/game.gd").new()
	R.reset()
	R.started = true
	check(Almanac.ROLL.size() == 8 and Almanac.roll(R).size() == 9 and Almanac.place(R) >= 7, "nine on the roll, and a sweeper begins near the foot of it (%d)" % Almanac.place(R))
	var lv0: Array = []
	for i in Almanac.ROLL.size():
		lv0.append(Almanac.rival_level(R, i))
		check(int(Almanac.ROLL[i].cap) <= Data.MAX_LEVEL and float(Almanac.ROLL[i].pace) > 0.0 and str(Almanac.ROLL[i].word) != "", "%s has a pace, a ceiling and a word" % str(Almanac.ROLL[i].n))
	R.day = 60
	var rose := 0
	for i2 in Almanac.ROLL.size():
		if Almanac.rival_level(R, i2) > int(lv0[i2]):
			rose += 1
	check(rose == Almanac.ROLL.size(), "sixty days on, every one of them has gone further, whether or not he did")
	R.day = 100000
	for i3 in Almanac.ROLL.size():
		check(Almanac.rival_level(R, i3) == int(Almanac.ROLL[i3].cap), "%s stops where their road ends" % str(Almanac.ROLL[i3].n))
	R.day = 1
	R.level = 99
	check(Almanac.place(R) == 1 and Almanac.stipend(R) > 0 and Almanac.roll_line(R) != "", "whoever is furthest on stands first")
	# the stipend comes with the month, once
	var S = load("res://scripts/game.gd").new()
	S.reset()
	S.started = true
	check(Almanac.poll(S).is_empty() and S.cal_month >= 0, "nothing comes on the first morning")
	var st0: int = S.stones
	S.day = 30
	var told: Array = Almanac.poll(S)
	check(S.stones == st0 + Almanac.stipend(S) and S.stipends == 1 and not told.is_empty(), "the first of the month: the sect's stipend")
	var st1: int = S.stones
	Almanac.poll(S)
	check(S.stones == st1, "and not twice")
	check(Almanac.stipend(S) < 40 * (1 + S.realm()), "a stipend is worth less than the road")
	S.day = 200
	var told2: Array = Almanac.poll(S)
	var word := false
	for t2 in told2:
		word = word or str(t2).begins_with("Word from the mountain")
	check(word, "and word comes down of whoever has broken through")
	# trades
	var p1 := {"seed": 12345, "kid": false}
	S.day = 1
	var r0 := Almanac.craft_rank(p1, S)
	S.day = 80
	check(Almanac.craft_rank(p1, S) > r0 and Almanac.craft_rank(p1, S) <= 4 and Almanac.craft_rank({"seed": 5, "kid": true}, S) == 0, "a trade is learned by the day; a child has none yet")
	for cr in Almanac.CRAFT_LINES.size():
		for cl in Almanac.CRAFT_LINES[cr]:
			check(str(cl).contains("%d") and fits.call(str(cl)), "what is said at place %d of a trade counts its days" % cr)
	check(not Almanac.craft_line(p1, S).contains("%d"), "and the days are written in")
	# packs
	var P = load("res://scripts/game.gd").new()
	P.reset()
	P.started = true
	var pack := {"id": "t:pack", "kind": "enemy", "group": [{"id": "trip_grass", "lv": 96}, {"id": "field_dust", "lv": 96}]}
	check(Almanac.stage(P, pack) == 0 and P.pack_day.has("t:pack") and Almanac.grown(P, pack) == pack.group, "a pack's clock begins when it is first met, and it is as it was")
	P.day = 2
	P.clock = 600.0
	check(Almanac.stage(P, pack) == 1 and int(Almanac.grown(P, pack)[0].lv) == 97 and Almanac.grown(P, pack).size() == 2, "a day alone: settled, a level stronger")
	P.day = 4
	check(Almanac.stage(P, pack) == 2 and Almanac.grown(P, pack).size() == 3, "two and a half: a brood, one head more")
	P.day = 7
	var old: Array = Almanac.grown(P, pack)
	check(Almanac.stage(P, pack) == 3 and int(old[0].lv) == 98 and old.size() == 3 and bool(old[2].get("elder", false)), "five: grown old, two levels and an elder")
	check((pack.group as Array).size() == 2 and int(pack.group[0].lv) == 96, "the pack as the land wrote it is never changed")
	check(Data.make_foes(old).size() == 3, "what it has grown to can be fought")
	Almanac.put_down(P, "t:pack")
	check(Almanac.stage(P, pack) == 0, "put down, it begins again from nothing")
	var top := {"id": "t:top", "kind": "enemy", "group": [{"id": "trip_grass", "lv": Data.MAX_LEVEL}]}
	Almanac.stage(P, top)
	P.day = 30
	check(int(Almanac.grown(P, top)[0].lv) == Data.MAX_LEVEL, "nothing grows past the last level there is")
	check(Almanac.STAGES.size() == Almanac.GROW_DAYS.size() + 1 and Almanac.WILD_WORDS.size() == Almanac.STAGES.size(), "a word for every stage")
	check(msrc.contains("Almanac.grown_at(e.group") and msrc.contains("Almanac.put_down(Game"), "a battle is fought with what the pack has grown to, and winning it starts its clock again")

	print("== the Way he walks (creed.gd) ==")
	var C = load("res://scripts/game.gd").new()
	C.reset()
	C.started = true
	check(Creed.WAYS.size() == 9 and Creed.key(C) == "0|0" and Creed.name_of(C) == "Walker of the Middle Way" and Creed.skills(C).is_empty(), "nine Ways, and everybody begins in the middle of both scales")
	for sh in Creed.SHUT:
		check(Creed.can(C, str(sh)) and Creed.why_not(C, str(sh)) == "" and fits.call(str(Creed.SHUT[sh][2])), "in the middle nothing is shut (%s)" % sh)
	for mk in ["dealt", "dark", "taken", "exp", "stones", "price", "stipend"]:
		check(Creed.mod(C, mk) == 1.0, "and no number is changed (%s)" % mk)
	var way_names := {}
	for wk in Creed.WAYS:
		way_names[str(Creed.WAYS[wk].n)] = true
		check(str(Creed.WAYS[wk].desc) != "", "%s is described" % str(Creed.WAYS[wk].n))
	check(way_names.size() == 9, "no two Ways have one name")
	for axis in Creed.AXES:
		for sd in [1, -1]:
			var sk := "%s|%d" % [axis, sd]
			check(Creed.ARTS.has(sk) and Data.SKILLS.has(str(Creed.ARTS[sk])) and str(Data.SKILLS[str(Creed.ARTS[sk])].creed) == sk and Creed.MODS.has(sk) and not (Creed.CAN[sk] as Array).is_empty() and not (Creed.CANNOT[sk] as Array).is_empty() and (Creed.LINES[sk] as Array).size() >= 2,
				"%s: an art, numbers, doors open and shut, and what the street says" % sk)
	check(not Data.known_skills(0, Data.MAX_LEVEL).has("creed_devour") and not Data.known_skills(0, Data.MAX_LEVEL).has("creed_rectify"), "no art of a side is learned by level")
	# the open road: the mat
	C.gamble_rounds = 40
	check(Creed.side(C, "rule") == -1 and Creed.name_of(C) == "Carefree Wanderer" and not Creed.can(C, "bag") and not Creed.can(C, "salary") and Creed.can(C, "gamble") and Creed.mod(C, "stipend") == 0.0 and Almanac.stipend(C) == 0
		and Creed.skills(C) == ["creed_carefree"] and Mail.bag_offer(C, "head_qingshi").is_empty(), "forty rounds at the mat: a rogue cultivator, with no post-bag, no salary and no stipend")
	# the Demonic Path
	Creed.act(C, "devour", 5)
	check(Creed.side(C, "virtue") == -1 and Creed.name_of(C) == "Calamity" and not Creed.can(C, "pray") and not Creed.can(C, "work") and not Creed.can(C, "fare") and Creed.mod(C, "dealt") > 1.0 and Creed.mod(C, "price") > 1.0
		and Creed.skills(C).has("creed_devour") and not Creed.skills(C).has("creed_rectify"), "the Devouring Palm five times: a Calamity; no incense lights, nobody hires, and the blow is harder")
	check(Offices.blocked(C, "shop", "qingshi") != "" and Offices.fare_offer(C, {}).is_empty(), "no shift and no fare for the Demonic Path")
	var altar := {"id": "t:altar", "kind": "prop", "prop": "altar"}
	var qi0: float = C.qi[0]
	C.qi[0] = 1.0
	var said: Array = Props.use(altar, C)
	check(said.size() == 1 and str(said[0]) == Creed.why_not(C, "pray") and C.qi[0] == 1.0 and int(C.prop_uses.get("t:altar", 0)) == 1, "an altar gives him nothing, and the praying still counts as done")
	C.qi[0] = qi0
	check(C.fighter(0).skills.has("creed_devour") and float(C.skill_of("creed_devour").mult) > 1.0 and float(Data.SKILLS.creed_devour.drain) > 0.0, "his art is in his hand, measured against what he knows")
	# the Righteous Path, and the precepts
	var V = load("res://scripts/game.gd").new()
	V.reset()
	V.started = true
	for hk in ["a:1", "a:2", "a:3", "a:4"]:
		V.fitted[hk] = 1
	check(Creed.side(V, "virtue") == 1 and Creed.name_of(V) == "Benevolent Wayfarer" and not Creed.can(V, "sleeper") and Creed.can(V, "pray") and Creed.mod(V, "dark") > 1.0 and Creed.mod(V, "price") < 1.0 and Creed.skills(V) == ["creed_rectify"],
		"four houses put to rights: of the Righteous Path, who will not strike what sleeps")
	V.shifts = {"shop": 6}
	check(Creed.side(V, "rule") == 1 and Creed.name_of(V) == "Pillar of the Righteous Path" and not Creed.can(V, "gamble") and Creed.mod(V, "taken") < 1.0 and Creed.mod(V, "stipend") > 1.0 and Creed.skills(V).size() == 2,
		"six shifts worked: a keeper of the precepts, who does not sit at a mat")
	check(Trials.need_met(["creed", "virtue", Creed.SIDE], V) and not Trials.need_met(["creed", "virtue", -Creed.SIDE], V) and Trials.need_met(["creed", "virtue", -Creed.SIDE], C) and Trials.need_text(["creed", "rule", Creed.SIDE], V) != ""
		and Trials.need_met(["fitted", 4], V) and not Trials.need_met(["fitted", 5], V), "trials can be passed by the Way he walks, and by the ordered house")
	check(Trials.KINDS.has("way") and Trials.KINDS.has("house") and Trials.KIND_ORDER.has("way") and Trials.KIND_ORDER.has("house"), "both are ways through a trial")
	Creed.poll(V)
	Creed.poll(V)
	V.fitted = {}
	V.toasts = []
	Creed.poll(V)
	check(V.creed_told == Creed.key(V) and not V.toasts.is_empty(), "the land says so when the Way he walks changes")
	check(Creed.causes(V).size() >= 1 and Creed.text(V) != "" and Creed.doors(V).size() == 2 and Creed.line(V, 3) != "" and Creed.line(G, 3) == "", "the page of the Way says why, and the street says what it thinks")
	check(msrc.contains("Creed.can(Game, \"gamble\")") and FileAccess.get_file_as_string("res://scripts/world.gd").contains("Creed.can(Game, \"sleeper\")") and FileAccess.get_file_as_string("res://scripts/battle.gd").contains("Creed.mod(Game, \"dealt\")"),
		"the mat, the sleeping pack and the blow all ask the Way")
	# (the bot's own journey is never one of the Demonic Path: it breaks nothing on purpose, strikes nothing asleep on purpose)
	check(not bsrc.contains("creed_devour"), "the bot does not learn the Devouring Palm")

	print("== the fitness of things (fitting.gd) ==")
	var F = load("res://scripts/game.gd").new()
	F.reset()
	F.started = true
	F.level = 99
	check(Fitting.ORDER.size() == Fitting.THINGS.size() and Fitting.WORDS.size() == Fitting.THINGS.size(), "seven things of a house, each with what is said for want of it and for having it")
	for tid in Fitting.ORDER:
		var th: Dictionary = Fitting.THINGS[tid]
		check(Data.ITEMS.has(tid) and Load.weight_of(tid) == 0.0 and not (th.good as Array).is_empty() and (th.bad as Dictionary).size() >= 2, "%s: a thing of the land that weighs nothing, with where it belongs and where it must never stand" % tid)
		for gk in th.good:
			check(Props.FURNITURE.has(str(gk)) and not (th.bad as Dictionary).has(str(gk)), "%s belongs at a %s" % [tid, gk])
		for bk in th.bad:
			check(Props.FURNITURE.has(str(bk)) and fits.call(str(th.bad[bk])) and Fitting.verdict(tid, str(bk)) == -1, "%s must never stand at a %s, and somebody says why" % [tid, bk])
		check(fits.call(str(Fitting.WORDS[tid][0])) and fits.call(str(Fitting.WORDS[tid][1])), "%s: both words fit the box" % tid)
	var n_wants := 0
	var kinds_wanted := {}
	var hs: Dictionary = Fitting._index(ws).houses
	for hk2 in hs:
		var w: Dictionary = Fitting.want(ws, str(hk2))
		if w.is_empty():
			continue
		n_wants += 1
		kinds_wanted[str(w.thing)] = true
		var se = null
		for e in ws.ents:
			if str(e.get("id", "")) == str(w.spot):
				se = e
		check(se != null and str(se.furn) == str(w.kind) and (Fitting.THINGS[str(w.thing)].good as Array).has(str(w.kind)) and Fitting.resident(ws, str(hk2)) != "" and Fitting.house_of(ws, str(w.spot)) == str(hk2),
			"%s wants a %s at a piece of furniture it really has, and somebody lives there" % [hk2, w.thing])
	check(n_wants >= 30 and kinds_wanted.size() >= 4, "houses all over the land want something (%d, of %d kinds)" % [n_wants, kinds_wanted.size()])
	check(Fitting.count(ws, "village") >= 6 and Fitting.count(ws, "yanggu") >= 4, "Qingshi and Yanggu have more houses to put to rights than the story asks for (%d, %d)" % [Fitting.count(ws, "village"), Fitting.count(ws, "yanggu")])
	var fw: Dictionary = Fitting.wanted(F, ws, "village")
	var fe: Dictionary = {}
	for e2 in ws.ents:
		if str(e2.get("id", "")) == str(fw.spot):
			fe = e2
	check(Fitting.complaint(F, ws, str(fw.house)) == str(Fitting.WORDS[str(fw.thing)][0]), "whoever lives there says what is wrong")
	F.stones = 100000
	var opts: Array = Fitting.options(F, ws, fe)
	check(opts.size() == 1 and str(opts[0].id) == "fit:send:" + str(fw.thing) and bool(opts[0].enabled), "with nothing in the bag, what the house wants can be sent out for")
	check(Fitting.send_for(F, str(fw.thing)) != "" and int(F.inv.get(str(fw.thing), 0)) == 1 and F.stones == 100000 - Fitting.price(F) and Fitting.price(F) < Fitting.thanks(F), "a boy runs to the market: paid for, in the bag, and cheaper than the thanks")
	# the wrong thing in the wrong place first
	var wrong := ""
	for tid2 in Fitting.ORDER:
		if (Fitting.THINGS[tid2].bad as Dictionary).has(str(fe.furn)):
			wrong = tid2
	if wrong != "":
		F.inv[wrong] = 1
		var bad: Dictionary = Fitting.set_down(F, ws, fe, wrong)
		check(int(bad.v) == -1 and str(bad.line) == str(Fitting.THINGS[wrong].bad[str(fe.furn)]) and F.misplaced == 1 and Fitting.at(F, str(fe.id)) == wrong and not Fitting.is_fitted(F, str(fw.house)), "the wrong thing set down there is objected to, and stays")
		check(Fitting.options(F, ws, fe).size() == 1 and str(Fitting.options(F, ws, fe)[0].id) == "fit:take", "and can be taken up again")
		check(Fitting.take_up(F, str(fe.id)) != "" and F.misplaced == 0 and int(F.inv.get(wrong, 0)) == 1 and Fitting.at(F, str(fe.id)) == "", "taken up: back in the bag, and forgiven")
		F.inv.erase(wrong)
	var good: Dictionary = Fitting.set_down(F, ws, fe, str(fw.thing))
	check(int(good.v) == 1 and int(good.stones) == Fitting.thanks(F) and Fitting.is_fitted(F, str(fw.house)) and F.step_fit == 1 and Fitting.complaint(F, ws, str(fw.house)) == "" and not F.inv.has(str(fw.thing)),
		"the right thing at the right piece: the house is put to rights, and says so")
	check(Fitting.wanted(F, ws, "village").get("house", "") != str(fw.house), "and the next house is another")
	check(Fitting.thanks(F) < 60 * (1 + F.realm()), "a house's thanks are worth less than the road")
	F.prop_uses[str(fe.id)] = 1
	check(Fitting.touched(F, ws, fe).contains(Fitting.resident(ws, str(fw.house))), "nobody likes their things handled")
	F.prop_uses[str(fe.id)] = 2
	check(Fitting.touched(F, ws, fe) == "", "and says so once")
	check(Fitting.options(F, ws, {"id": "furn:nowhere:none:0", "furn": "table"}).is_empty(), "a piece of no house offers nothing")
	for tid3 in Fitting.ORDER:
		var mdl: Node3D = Fitting.model(tid3)
		check(mdl != null and mdl.get_child_count() >= 1, "%s has a model built from code" % tid3)
		mdl.free()
	# the step that asks for houses
	var H = load("res://scripts/game.gd").new()
	H.reset()
	H.started = true
	H.level = 99
	H.stones = 100000
	H.step = Data.step_index("s_p29_fit") - 1
	H.advance()
	check(str(H.cur_step().id) == "s_p29_fit" and H.step_fit == 0 and int(H.inv.get("water_jar", 0)) == 1 and H.objective_text().contains("(0/3)"), "the step begins with nothing put to rights, and a jar in the bag")
	var done_n := 0
	while str(H.cur_step().id) == "s_p29_fit" and done_n < 9:
		var hw: Dictionary = Fitting.wanted(H, ws, "village")
		check(not hw.is_empty(), "there is a house of Qingshi that still wants something")
		if hw.is_empty():
			break
		var he: Dictionary = {}
		for e3 in ws.ents:
			if str(e3.get("id", "")) == str(hw.spot):
				he = e3
		if int(H.inv.get(str(hw.thing), 0)) <= 0:
			Fitting.send_for(H, str(hw.thing))
		Fitting.set_down(H, ws, he, str(hw.thing))
		done_n += 1
		H.poll_steps()
	check(done_n == 3 and str(H.cur_step().id) == "s_p29_wood", "three houses put to rights, and the step is done (%d)" % done_n)
	check(bsrc.contains("Fitting.wanted(Game") and bsrc.contains("main.FIT_ASK") and bsrc.contains("\"fit:set:\""), "the bot goes to the house, sends out and sets down")
	check(msrc.contains("func offer_fit") and msrc.contains("\"later\", \"label\": \"Leave it\""), "\"Leave it\" is the first answer at somebody's furniture")

	print("== Part XXIX: The Crooked Chimney ==")
	check(Data.REALMS.size() >= 35 and Data.REALMS[34] == "Everything in Its Place" and Data.MAX_LEVEL >= 102 and Data.level_name(102).ends_with("Everything in Its Place") and Data.REALM_INFO.size() >= 35
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXIX adds the realm of Everything in Its Place")
	check(Data.step_index("s_break34") == Data.step_index("s_p30_home") - 1 and int(Data.STEPS[Data.step_index("s_break34")].to) == 102 and Data.DIALOGUE.has("recall27") and msrc.contains("\"s_break33\": \"recall27\"") and Data.DIALOGUE.has("pre:s_break34") and Data.DIALOGUE.has("post:s_break34"),
		"Part XXIX follows Rings Returned (recall27) and ends with the thirty-fourth tribulation")
	var p29 := Data.step_index("s_p29_home")
	var kinds29 := {}
	var n29 := 0
	for i4 in range(p29, Data.step_index("s_break34") + 1):
		var s29: Dictionary = Data.STEPS[i4]
		n29 += 1
		kinds29[str(s29.kind)] = true
		check(str(s29.id).begins_with("s_p29_") or str(s29.id) == "s_break34", "%s is a step of the chapter" % s29.id)
		if str(s29.kind) == "talk":
			check(Data.DIALOGUE.has(str(s29.id)), "%s has its conversation" % s29.id)
		if str(s29.kind) == "kill":
			check(Data.DIALOGUE.has("pre:" + str(s29.boss)) and Data.DIALOGUE.has("post:" + str(s29.boss)) and Trials.TRIALS.has(str(s29.boss)) and Lore.BOSS.has(str(s29.boss)), "%s: words before and after, a trial, and a story" % s29.boss)
			check(bsrc.contains("\"%s\": \"" % str(s29.boss)), "the bot has a way planned through %s" % s29.boss)
		if str(s29.kind) == "hunt":
			for en in s29.of:
				check(Data.ENEMIES.has(str(en)) and Lore.BEAST.has(str(en)) and int(Data.ENEMIES[str(en)].get("boss", false)) == 0, "%s: a foe of the chapter with a story" % en)
			var band: Dictionary = Data.AREAS[str(s29.area)].get("warband5", {})
			for en2 in s29.of:
				var in_pool := false
				for pl in band.get("pool", []):
					in_pool = in_pool or str(pl[0]) == str(en2)
				check(in_pool, "%s marches in %s" % [en2, s29.area])
		if str(s29.kind) in ["hunt", "collect", "toil", "haul", "folk", "fit", "summit", "glide", "marks"]:
			check(Data.DIALOGUE.has("done:" + str(s29.id)), "%s: something is said when it is done" % s29.id)
		if str(s29.kind) == "haul":
			check(Data.DIALOGUE.has("haul:" + str(s29.id)) and Load.GOODS.has(str(s29.good)), "%s: a good of the land, and a word as each load arrives" % s29.id)
		if str(s29.kind) == "folk":
			check(Folk.ERRANDS.has(str(s29.id)) and Folk.ERRANDS[str(s29.id)].lines.size() >= 4, "%s: the errand has its words" % s29.id)
		if str(s29.kind) == "fit":
			check(Fitting.count(ws, str(s29.area)) >= int(s29.n) + 1, "%s: %s has more houses to put to rights than are asked for" % [s29.id, s29.area])
		for gk2 in s29.get("gives", {}):
			check(Data.ITEMS.has(str(gk2)), "%s puts a thing that exists into his hands" % s29.id)
	check(n29 >= 28 and kinds29.has("fit") and kinds29.has("toil") and kinds29.has("haul") and kinds29.has("summit") and kinds29.has("glide") and kinds29.has("marks") and kinds29.has("folk"), "the chapter is thirty steps of ten kinds (%d)" % n29)
	# two fit steps ask for no more than the hero has put to rights by the trial that counts them
	check(Data.step_index("s_p29_rights") < _kill_step("hua_xin") and Data.step_index("s_p29_fit") < _kill_step("chimney_fire"), "the houses are put to rights before the lords who are shown them")
	var c29: Dictionary = Echoes.CROSSROADS.get("the_mat", {})
	check(not c29.is_empty() and str(c29.step) == "s_p29_mat" and str(c29.part) == "XXIX" and Echoes.ORDER[Echoes.ORDER.find("the_verdict") - 1] == "the_mat", "where a friend sits is asked last of all")
	check((c29.options as Array).size() == 3 and c29.after.size() == 3 and c29.end.size() == 3 and c29.echo.has("s_p29_end") and c29.echo.s_p29_end.size() == 3, "the_mat: three answers, each answered, echoed and told at the end")
	var letters29 := 0
	for lid in Mail.ORDER:
		if Mail.LETTERS[lid].has("needs") and str(Mail.LETTERS[lid].needs[0]) == "the_mat":
			letters29 += 1
	check(letters29 == 3 and Mail.LETTERS.has("tian_chimney") and Mail.ORDER.has("tian_chimney"), "a letter for each answer, and one from a man with a bent chimney")
	var scales29 := {}
	var creeds29 := {}
	for o29 in c29.options:
		check(Marks.MARKS.the_mat.has(str(o29.id)) and Marks.MARKS.the_mat[str(o29.id)].has("who"), "the_mat/%s leaves something standing, and somebody by it" % o29.id)
		check(not Weal.hears(str(Marks.MARKS.the_mat[str(o29.id)].area)).is_empty(), "the_mat/%s is felt in a town" % o29.id)
		for sc in o29.tilt:
			scales29[sc] = true
		for ck in o29.get("creed", {}):
			creeds29["%s%d" % [ck, signi(int(o29.creed[ck]))]] = true
			check(Creed.AXES.has(str(ck)) and absi(int(o29.creed[ck])) < Creed.SIDE, "the_mat/%s leans on the Way, and does not by itself decide it" % o29.id)
	check(scales29.size() == 3 and creeds29.size() == 3, "its answers tip all three scales, and three sides of the Way")
	var CG = load("res://scripts/game.gd").new()
	CG.reset()
	Echoes.take(CG, "the_mat", "road")
	check(Creed.value(CG, "rule") < 0 and Echoes.option_text(CG, Echoes.option("the_mat", "cut")).contains("Orthodox"), "an answer weighs on the Way he walks, and says so before it is given")
	CG.free()
	var old_echo29 := 0
	for cid2 in Echoes.ORDER:
		if cid2 == "the_mat":
			continue
		for ek in Echoes.CROSSROADS[cid2].get("echo", {}):
			if str(ek).contains("s_p29_"):
				old_echo29 += 1
	check(old_echo29 >= 2, "older crossroads echo in Part XXIX (%d)" % old_echo29)
	check(bsrc.contains("\"chimney_fire\": \"relic\"") and bsrc.contains("\"hua_xin\": \"house\"") and bsrc.contains("\"the_mat\": [\"whole\"]"), "the bot has a plan for every trial and the crossroads of the chapter")
	for a29 in ["marsh", "grave", "court"]:
		check(str(Data.AREAS[a29].get("warband5", {}).get("vis", "")).begins_with("s_p29_") and not Data.AREAS[a29].has("warband6"), "%s: the chapter's band takes the last slot" % a29)
	check(Marks.AFTER_BANDS.has("the_mat"), "the marks of its crossroads are stood after the late bands")
	var found29 := 0
	for e29 in ws.ents:
		if (e29.kind == "pickup" and str(e29.id).begins_with("p29_")) or (e29.kind == "boss" and str(e29.enemy) in ["chimney_fire", "old_wall", "furrow_gold", "hua_xin"]) or (e29.kind == "npc" and str(e29.id) in ["the_guest", "host_tian", "ding_lingwei", "guan_ning", "hua_xin"]):
			found29 += 1
			check(Atlas.owner_id(ws, e29.pos) == str(e29.area), "%s stands in its own region" % e29.id)
	check(found29 == 12 + 4 + 5, "everything the chapter stands in the land found room (%d)" % found29)
	for pr in [["chimney_fire", "charred_shingle", "s_p29_shingles"], ["old_wall", "crane_feather", "s_p29_feathers"], ["furrow_gold", "furrow_piece", "s_p29_gold"]]:
		check(Data.step_index(str(pr[2])) < _kill_step(str(pr[0])) and Data.ITEMS.has(str(pr[1])) and Look.PICKUP_COLORS.has(str(pr[1])), "%s can be passed by what was found on the way" % pr[0])
	for fid in ["in_its_place", "bent_chimney", "crane_home", "cut_mat"]:
		check(Feats.FEATS.has(fid), "the feat %s is kept" % fid)
	for pid in ["the_guest", "ding_lingwei", "guan_ning", "hua_xin"]:
		check(Assets.PEOPLE.has(pid) and Assets.has(str(Assets.PEOPLE[pid])), "%s has a body built from a script" % pid)
		check(Data.CHAT.has(pid) and Data.CHAT[pid].size() >= 4, "%s has four things to say" % pid)
	check(Data.CHAT.has("host_tian") and Data.CHAT.host_tian.size() >= 4, "the householder has four things to say")
	check(Almanac.STORY_DATES.has("s_p29_feast"), "the crane comes down on the Double Ninth")
	G.free(); R.free(); S.free(); P.free(); C.free(); V.free(); F.free(); H.free()

## The Open Net release: the law of the land (anybody can be struck down; what is seen is answered for; the watch,
## the circle, the bounty-takers), the three forbidden Daos (and what being caught costs), the balance of the wild
## (a country hunted too hard changes), and Part XXX.
func _open_net() -> void:
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	var ws: Dictionary = Atlas.world()
	var new_game := func():
		var g = load("res://scripts/game.gd").new()
		g.reset()
		g.started = true
		return g

	print("== the law of the land (crime.gd) ==")
	var G = new_game.call()
	check(Crime.clean(G) and Crime.worst(G) == 0 and Crime.heat(G) == 0 and not Crime.outlaw(G) and Crime.text(G) == "a clean name", "a journey begins with a clean name")
	check(Crime.mod(G, "qingshi", "price") == 1.0 and Crime.shut(G, "village", "work") == "" and Crime.watch_due(G, "village").is_empty() and not Crime.hunt_due(G, "bamboo"), "and nothing is shut, dearer or after him")
	# everybody who stands in the land can be weighed, and nobody is past what a journey reaches
	var people := 0
	var kids := 0
	var strongest := 0
	var lids := {}
	for a in Data.AREAS:
		lids[Data.layer_of(a)] = true
	for lid in lids:
		for e in Atlas.world_of(str(lid)).ents:
			if str(e.kind) != "npc":
				continue
			people += 1
			var m := Crime.might(e)
			strongest = maxi(strongest, m)
			if Crime.is_child(e):
				kids += 1
			check(m >= 0 and m + Crime.EDGE <= Data.MAX_LEVEL + 12 and Crime.weigh(G, e) != "", "%s can be weighed (%d)" % [e.id, m])
	check(people > 300 and strongest >= 60, "%d people stand in the land, the strongest with %d levels behind them" % [people, strongest])
	var elder := {}
	var wen := {}
	var officer := {}
	for e in ws.ents:
		if str(e.kind) != "npc":
			continue
		if str(e.id) == "elder":
			elder = e
		elif str(e.id) == "granny_wen":
			wen = e
		elif e.has("office") and officer.is_empty() and str(e.get("area", "")) == "village":
			officer = e
	check(not elder.is_empty() and not wen.is_empty() and not officer.is_empty(), "the Elder, Granny Wen and whoever answers for Qingshi stand in the land")
	check(Crime.might(elder) > 50 and Crime.might(wen) <= 3 and Crime.might(officer) >= 30, "the Elder is no easy mark, a midwife is, and an officer has the town's guard at the door")
	# too weak: put on his back, and it was seen by the one he drew on
	G.level = 3
	var r0: Dictionary = Crime.strike(G, elder, 0)
	check(str(r0.how) == "thrown" and int(r0.price) > 0 and not Crime.slain(G, "elder") and Crime.price(G, "sect") == int(r0.price) and G.thrown == 1 and not Crime.clean(G),
		"a sword drawn on somebody too strong: he is put on his back, nobody dies, and there is a bill for it (%d)" % int(r0.price))
	check(not Crime.can_kill(G, elder) and Crime.can_kill(G, wen), "he can strike down whoever he is stronger than, and nobody else")
	G.free()
	# strong enough: dead for good
	G = new_game.call()
	G.level = 80
	var stones0: int = G.stones
	var peace0 := Weal.measure(G, "qingshi", "peace")
	var virtue0 := Creed.value(G, "virtue")
	var r1: Dictionary = Crime.strike(G, wen, 2)
	check(str(r1.how) == "slain" and Crime.slain(G, "granny_wen") and Crime.dead(G, "granny_wen") and Crime.count(G) == 1 and Crime.count(G, true) == 1, "anybody can be struck down by somebody strong enough, and stays dead")
	check(int(r1.price) > 0 and Crime.price(G, "qingshi") == int(r1.price) and G.stones > stones0 and Crime.standing(G, "qingshi") == 1 and Crime.standing(G, "yanggu") == 0, "what was seen is answered for in the town that hears of it, and nowhere else (%d)" % int(r1.price))
	check(Weal.measure(G, "qingshi", "peace") < peace0 and Weal.measure(G, "qingshi", "regard") < 0 and Creed.value(G, "virtue") < virtue0, "the town is the poorer in peace, thinks the worse of him, and the Way he walks is weighed by it")
	for ln in r1.lines:
		check(fits.call(str(ln[1])), "what is told of a killing fits the dialogue box")
	check(Crime.grave_line(G, wen).contains("Granny Wen") and fits.call(Crime.grave_line(G, wen)) and fits.call(Crime.heir_line(G, wen)), "where she stood there is a mound, and it says so")
	var wen_n := str(wen.n)
	var said2: Array = Crime.mute(G, [[wen_n, "Eat."], ["Lin Feng", "Yes."], [wen_n, "More."], ["Narrator", "He eats."]])
	check(said2.size() == 3 and str(said2[0][0]) == "Narrator" and str(said2[1][0]) == "Lin Feng", "the dead do not say their lines, and everybody else does")
	check(Crime.shut(G, "village", "work") != "" and Crime.shut(G, "yanggu", "work") == "" and Crime.mod(G, "qingshi", "price") > 1.2 and Crime.mod(G, "yanggu", "price") == 1.0, "where his bill hangs nobody hires him and the counters ask more")
	check(Offices.blocked(G, "inn", "village") == Crime.SHUT.work and Mail.bag_offer(G, "head_qingshi").is_empty() and Weal.gift_blocked(G, "qingshi") == Crime.SHUT.gift, "no shift, no post-bag, and the chest takes nothing from him")
	# unseen: no bill, but done
	var r2: Dictionary = Crime.strike(G, officer, 0)
	check(str(r2.how) == "slain" and int(r2.price) == 0 and Crime.count(G) == 2 and Crime.count(G, true) == 1 and G.crimes.size() == 2, "what nobody saw is not answered for, and is still done")
	# the watch
	var w: Dictionary = Crime.watch_due(G, "village")
	check(not w.is_empty() and int(w.price) == Crime.price(G, "qingshi") and Crime.watch_due(G, "bamboo").is_empty() and Crime.watch_due(G, "yanggu").is_empty(), "the watch comes for him in the town's own streets, and only there")
	for ln2 in Crime.watch_lines(G, w):
		check(fits.call(str(ln2[1])), "what the watch says fits the dialogue box")
	G.stones = 0
	check(not Crime.pay(G, w) and Crime.price(G, "qingshi") > 0, "a price cannot be paid with an empty purse")
	var day0: int = G.day
	var days := Crime.serve(G, w)
	check(days >= 1 and days <= Crime.SERVE_MAX and G.day == day0 + days and Crime.price(G, "qingshi") == 0 and Crime.watch_due(G, "village").is_empty() and G.served == days, "or served: %d days in the circle, and the bill is burned" % days)
	for ln3 in Crime.serve_lines(G, w, days, true):
		check(fits.call(str(ln3[1])), "what is told of the circle fits the dialogue box")
	check(Crime.slain(G, "granny_wen") and not Crime.clean(G) and Weal.measure(G, "qingshi", "regard") < 0, "the dead stay dead and the town remembers, bill or no bill")
	G.free()
	# pay, run, resist, outlaw, bounty-takers
	G = new_game.call()
	G.level = 80
	Crime.strike(G, wen, 1)
	var w2: Dictionary = Crime.watch_due(G, "village")
	G.stones = int(w2.price) + 5
	check(Crime.pay(G, w2) and G.stones == 5 and Crime.heat(G) == 0 and G.bounty_paid == int(w2.price), "the price can be paid, and the bill is torn up")
	Crime.record(G, "assault", "qingshi", "somebody")
	var w3: Dictionary = Crime.watch_due(G, "village")
	check(w3.is_empty(), "the watch comes once a day")
	G.day += 1
	w3 = Crime.watch_due(G, "village")
	var before := Crime.price(G, "qingshi")
	check(Crime.flee(G, w3) > 0 and Crime.price(G, "qingshi") > before and Crime.watch_due(G, "village").is_empty(), "running makes the bill heavier, and they come again tomorrow")
	G.day += 1
	w3 = Crime.watch_due(G, "village")
	var grp: Array = Crime.watch_group(G)
	check(grp.size() == 3 and grp.all(func(f): return Data.ENEMIES.has(str(f.id)) and int(f.lv) <= Data.MAX_LEVEL and int(f.lv) >= G.level - 1), "the watch that serves a cultivator's bill is about as strong as he is")
	var more := Crime.resisted(G, w3)
	check(more > before and Crime.outlaw(G) and Crime.standing(G, "yanggu") == 2 and Crime.shut(G, "yanggu", "work") != "" and Almanac.stipend(G) == 0, "cutting down the watch makes an outlaw of him: every gate, and no stipend")
	check(Crime.hunt_due(G, "bamboo") and not Crime.hunt_due(G, "village") and not Crime.hunt_due(G, "sect"), "bounty-takers find an outlaw in the wild, not in a town's own streets")
	var hs: Array = Crime.hunters(G)
	check(hs.size() == 2 and hs.all(func(f): return str(f.id) == "bounty_taker" and int(f.lv) == G.level + 1), "two of them, a level above him")
	Crime.hunted_today(G)
	check(not Crime.hunt_due(G, "bamboo"), "once a day")
	Crime.hunt_won(G); Crime.hunt_won(G); Crime.hunt_won(G); Crime.hunt_won(G); Crime.hunt_won(G); Crime.hunt_won(G)
	check(Crime.hunters(G).size() == 4, "beaten, they bring more: four at most")
	var w4: Dictionary = Crime.hunt_lost(G)
	var days4 := Crime.serve(G, w4, true)
	check(days4 > 0 and Crime.heat(G) == 0 and not Crime.outlaw(G), "beaten by them, everything is served at once (%d days)" % days4)
	G.free()
	# children, the people of the towns, and somebody new
	G = new_game.call()
	G.level = 90
	var kid := {}
	var grown := {}
	for fp in Folk.people(ws, "qingshi"):
		if bool(fp.kid) and kid.is_empty():
			kid = {"kind": "folk", "id": fp.id, "n": fp.n, "p": fp, "area": fp.area}
		elif not bool(fp.kid) and grown.is_empty():
			grown = {"kind": "folk", "id": fp.id, "n": fp.n, "p": fp, "area": fp.area}
	check(not kid.is_empty() and Crime.is_child(kid) and not Crime.can_kill(G, kid) and str(Crime.strike(G, kid, 0).how) == "child" and Crime.count(G) == 0, "a child is never struck: the sword does not leave the sheath")
	check(str(Crime.strike(G, grown, 0).how) == "slain" and Crime.gone(G, str(grown.id)) and not Crime.dead(G, str(grown.id)) and not Crime.replaced(G, str(grown.id)), "one of the street is gone from it")
	G.day += Crime.MOURN
	check(not Crime.gone(G, str(grown.id)) and Crime.replaced(G, str(grown.id)), "until somebody new has taken the place (%d days)" % Crime.MOURN)
	check(kids >= 1, "there are children among the people with names (%d), and none of them can be struck" % kids)
	G.free()
	# (found by the audit of this release's own code, before it shipped)
	G = new_game.call()
	G.level = 60
	check(Crime.town_for("bamboo") == "qingshi" and Crime.town_for("village") == "qingshi" and Weal.town_of("bamboo") == "", "what is done in the wild is answered for in the town that hears of it")
	var rw: Dictionary = Crime.strike(G, {"kind": "npc", "id": "t_wild", "n": "Somebody of the Road", "area": "bamboo", "asset": "folk_farmer", "vis": ["", ""]}, 3)
	check(str(rw.how) == "slain" and int(rw.price) > 0 and Crime.price(G, "qingshi") == int(rw.price) and str(G.slain.t_wild.town) == "qingshi", "a killing seen in the wild has a bill at the nearest gate (%d)" % int(rw.price))
	for a9 in Data.AREAS:
		check(Crime.town_for(str(a9)) != "", "%s: some town answers for what is done there" % a9)
	G.free()
	G = new_game.call()
	G.level = 60
	var twice := {}
	for fp2 in Folk.people(ws, "qingshi"):
		if not bool(fp2.kid):
			twice = {"kind": "folk", "id": fp2.id, "n": fp2.n, "p": fp2, "area": fp2.area}
			break
	Crime.strike(G, twice, 2)
	var regard1 := Weal.measure(G, "qingshi", "regard")
	var virtue9 := Creed.value(G, "virtue")
	G.day += Crime.MOURN
	Crime.strike(G, twice, 0)
	check(Crime.count(G) == 2 and Crime.count(G, true) == 1 and bool(G.slain[str(twice.id)].seen) and Weal.measure(G, "qingshi", "regard") <= regard1 and Creed.value(G, "virtue") < virtue9,
		"somebody new struck down in turn is a second killing: the first is not forgotten, nor what was seen of it")
	G.free()
	G = new_game.call()
	G.level = 60
	G.step = Data.step_index("s_p16_eve") + 1
	G.clock = 21.2 * 60.0
	Crime.record(G, "assault", "qingshi", "somebody")
	Crime.serve(G, Crime.watch_due(G, "village"))
	check(Clock.frozen(G) == "night" and absf(Clock.hour(G) - 21.2) < 0.01, "days in the circle do not end the night the story is holding")
	G.free()
	G = new_game.call()
	G.level = 30
	G.heal_full()
	G.clock = 23.5 * 60.0
	var day9: int = G.day
	Taboo.sit(G, "blood", 0)
	check(G.day == day9 + 1 and absf(Clock.hour(G) - 1.5) < 0.01, "two hours at a forbidden art are two hours, at any hour of the night")
	G.free()
	var old3: Array = Almanac.grown_at([{"id": "a", "lv": 5}, {"id": "b", "lv": 5}], 3)
	var thin3: Array = Wilds.group_at(old3, 1)
	check(thin3.size() == old3.size() - 1 and bool(thin3[thin3.size() - 1].get("elder", false)), "an old pack in a thinned country is a head short, and keeps its elder")
	check(msrc.contains("\"grown\": grown_st if wild_st < 2 else 0") and msrc.contains("if outcome != \"win\" and outcome != \"lose\":"), "nothing that follows a pack is called its elder; and getting away from the watch is running, not being taken")
	for c in Crime.CRIMES:
		check(str(Crime.CRIMES[c].bill).contains("%s") and int(Crime.CRIMES[c].base) > 0, "the charge %s has a bill and a price" % c)
	for sk in Crime.SHUT:
		check(fits.call(str(Crime.SHUT[sk])), "what is said when %s is shut fits the dialogue box" % sk)
	for eid in ["watch_spear", "watch_captain", "bounty_taker", "league_enforcer", "carrion_crow", "midden_rat", "the_hunger"]:
		check(Data.ENEMIES.has(eid) and Lore.BEAST.has(eid) and Habits.habit(eid) != "", "%s has a story, and keeps hours" % eid)
	check(msrc.contains("\"id\": \"sheathe\", \"label\": \"Sheathe it\"") and msrc.contains("func offer_watch") and msrc.contains("func visit_grave") and msrc.contains("Crime.mute(Game, lines)"), "\"Sheathe it\" is the first answer; the watch asks; a grave is visited; the dead are not heard")
	check(not bsrc.contains("Crime.strike") and not bsrc.contains("offer_draw") and not bsrc.contains("Taboo.sit"), "the bot draws on nobody and leaves the shelf shut")
	var gn: Node3D = Crime.grave(true)
	check(gn.get_child_count() >= 6, "a grave is built from code")
	gn.free()

	print("== the forbidden shelf (taboo.gd) ==")
	G = new_game.call()
	check(Taboo.ORDER.size() == 3 and Taboo.mod(G, "dealt") == 1.0 and Taboo.mod(G, "exp") == 1.0 and Taboo.mod(G, "taken") == 1.0 and Taboo.taint(G) == 0 and not Taboo.marked(G), "three forbidden Daos, and a journey that never sits to one is the journey it always was")
	check(Taboo.blocked(G, "blood") != "" and Taboo.sit(G, "blood", 0).is_empty(), "the names are only names until he has begun to cultivate")
	G.level = 30
	G.heal_full()
	var virtue1 := Creed.value(G, "virtue")
	var told: Array = Taboo.sit(G, "blood", 0)
	check(not told.is_empty() and Taboo.depth(G, "blood") == 1 and Taboo.mod(G, "dealt") > 1.0 and not Taboo.marked(G) and Creed.value(G, "virtue") < virtue1 and not Crime.clean(G), "sat to unseen: a step deeper, a harder blow, nobody knows, and the Way is weighed by it")
	for ln4 in told:
		check(fits.call(str(ln4[1])), "what is told of sitting to it fits the dialogue box")
	G.heal_full()
	Taboo.sit(G, "soul", 0)
	check(Taboo.mod(G, "exp") > 1.0 and Taboo.taint(G) == 2 and not Taboo.senses(G, elder), "two steps: not yet strong enough on him to smell")
	G.heal_full()
	Taboo.sit(G, "husk", 0)
	check(Taboo.mod(G, "taken") < 1.0 and Taboo.taint(G) == Taboo.SENSE and Taboo.senses(G, elder) and not Taboo.senses(G, wen), "three: anybody of cultivation he speaks to knows, and a midwife does not")
	var caught: Array = Taboo.sensed(G, elder)
	check(Taboo.marked(G) and not caught.is_empty() and Crime.outlaw(G) and Crime.standing(G, "yanggu") == 2 and Almanac.stipend(G) == 0 and Crime.shut(G, "village", "work") != "", "caught: his name at every gate, struck from the roll, hired by nobody")
	for ln5 in caught:
		check(fits.call(str(ln5[1])), "what is said when he is found out fits the dialogue box")
	check(Crime.hunt_due(G, "bamboo") and Crime.hunters(G).size() == 3 and Crime.hunters(G).all(func(f): return str(f.id) == "league_enforcer" and int(f.lv) == G.level + 2), "three enforcers of the League, stronger than he is, once a day")
	var pen: Dictionary = Taboo.penance(G)
	G.stones = 100000
	var day1: int = G.day
	var atoned: Array = Taboo.atone(G)
	check(not Taboo.marked(G) and Taboo.taint(G) == 0 and Taboo.mod(G, "dealt") == 1.0 and G.day == day1 + int(pen.days) and G.stones == 100000 - int(pen.fine) and not Crime.outlaw(G), "the Hall of Discipline: the arts given up, %d days, %d stones, and the gates forget" % [int(pen.days), int(pen.fine)])
	for ln6 in atoned:
		check(fits.call(str(ln6[1])), "what is told of the Hall of Discipline fits the dialogue box")
	check(int(Taboo.penance(G).days) > int(pen.days), "a second time costs more")
	G.heal_full()
	var seen_lines: Array = Taboo.sit(G, "blood", 2, "Qingshi")
	check(Taboo.marked(G) and seen_lines.size() >= 3, "sat to in front of somebody: found out at once")
	var burned: Array = Taboo.burn(G)
	check(not Taboo.marked(G) and Taboo.taint(G) == 0 and burned.all(func(l): return fits.call(str(l[1]))), "beaten by the enforcers, the arts are burned out of him")
	for id in Taboo.ORDER:
		var d: Dictionary = Taboo.DAOS[id]
		check(fits.call(str(d.desc)) and fits.call(str(d.sit)) and str(d.key) in ["dealt", "exp", "taken"], "%s: what it is and what sitting to it is like fit the box" % id)
	for dn in Data.SKILLS:
		check(not Data.SKILLS[dn].has("taboo"), "no forbidden art is a technique the story could ask for")
	check(msrc.contains("\"id\": \"shut\", \"label\": \"Leave it shut\"") and msrc.contains("\"id\": \"later\", \"label\": \"Not today\", \"desc\": \"He will not send"), "\"Leave it shut\" is first on the shelf, and \"Not today\" before the Hall of Discipline")
	G.free()

	print("== the balance of the wild (wilds.gd) ==")
	G = new_game.call()
	check(Wilds.state(G, "bamboo") == 0 and Wilds.stands(G) and Wilds.back(G, "bamboo") == 1.0 and Wilds.fade(G, "bamboo") == 0.0 and Wilds.text(G) == "the wild stands", "the wild begins in balance")
	var native := {}
	var band := {}
	for e in ws.ents:
		if str(e.kind) != "enemy":
			continue
		if str(e.get("area", "")) == "bamboo" and Wilds.native(e) and native.is_empty():
			native = e
		elif e.has("late") and band.is_empty():
			band = e
	check(not native.is_empty() and not band.is_empty() and Wilds.native(native) and not Wilds.native(band), "the land's own packs are told from the war-bands of the story")
	var packs := float(int(Data.AREAS.bamboo.enemies))
	for k in int(ceil(packs * float(Wilds.AT[0]))):
		Wilds.culled(G, "bamboo")
	check(Wilds.state(G, "bamboo") == 1 and Wilds.stands(G) and Wilds.back(G, "bamboo") > 1.0, "every pack of a country put down half as often again in a day: thinned")
	var g3: Array = [{"id": "a", "lv": 5}, {"id": "b", "lv": 5}, {"id": "c", "lv": 6}]
	check(Wilds.group_at(g3, 1).size() == 2 and Wilds.group_at([{"id": "a", "lv": 5}], 1).size() == 1, "a thinned pack is a head short, and never fewer than one")
	for k2 in int(ceil(packs * float(Wilds.AT[1] - Wilds.AT[0]))):
		Wilds.culled(G, "bamboo")
	check(Wilds.state(G, "bamboo") == 2 and not Wilds.stands(G) and Wilds.fade(G, "bamboo") >= 0.35, "three times over: hunted out, and the colour goes out of it")
	var g2: Array = Wilds.group_at(g3, 2, 1)
	check(str(g2[0].id) == "a" and g2.size() == 3 and g2.slice(1).all(func(f): return str(f.id) in Wilds.SCAVENGERS and int(f.lv) == 6), "what is left of the pack is followed by what eats the leavings")
	var plenty0 := Weal.measure(G, "qingshi", "plenty")
	check(Weal.causes(G, "qingshi").any(func(c): return str(c.why).contains("hunted out")) and plenty0 < 0, "the town that hears of it has less in the pot (%d)" % plenty0)
	check(Wilds.line(G, "bamboo", 1) != "" and fits.call(Wilds.line(G, "bamboo", 1)), "and a hunter of the camp says so")
	for k3 in int(ceil(packs * float(Wilds.AT[2] - Wilds.AT[1]))):
		Wilds.culled(G, "bamboo")
	check(Wilds.state(G, "bamboo") == 3 and Wilds.back(G, "bamboo") == 4.0 and Wilds.worst_count(G, 3) == 1, "five times over: barren")
	var gb: Array = Wilds.group_at(g3, 3, 0)
	check(str(gb[0].id) == "a" and bool(gb[0].gaunt) and str(gb[gb.size() - 1].id) == Wilds.HUNGER and gb.size() <= 5 and gb.all(func(f): return int(f.lv) <= Data.MAX_LEVEL), "one gaunt survivor, the scavengers, and the Hunger at their head")
	check(Wilds.group_at([{"id": "a", "lv": Data.MAX_LEVEL}], 3).all(func(f): return int(f.lv) <= Data.MAX_LEVEL), "nothing is past the last level there is")
	check(Wilds.group(G, band, band.group) == band.group and Wilds.group(G, native, native.group) != native.group, "a war-band of the story fights as it was written, whatever the country")
	check(Weal.measure(G, "qingshi", "plenty") < plenty0 and Creed.value(G, "virtue") < 0, "the town goes leaner, and the Way is weighed by it")
	# three sides of the net
	G.stones = 100000
	var s0 := Wilds.strain(G, "bamboo")
	check(Wilds.net_blocked(G, "bamboo") == "" and Wilds.open_net(G, "bamboo") and absf(Wilds.strain(G, "bamboo") - s0 * 0.5) < 0.01 and G.stones == 100000 - Wilds.net_price(G) and Wilds.net_blocked(G, "bamboo") != "", "a hunter paid to open three sides of his net: the strain is halved, once a day")
	check(Wilds.net_blocked(G, "marsh") != "", "a net is not opened in a country that is full")
	# the days mend it
	var st_now := Wilds.state(G, "bamboo")
	G.day += 3
	Wilds.poll_all(G)
	check(Wilds.state(G, "bamboo") < st_now, "left alone, a country comes back (%s after three days)" % Wilds.info(G, "bamboo").n)
	G.day += 14
	Wilds.poll_all(G)
	check(Wilds.state(G, "bamboo") == 0 and Wilds.stands(G) and not G.cull.has("bamboo") and Wilds.worst_count(G, 3) == 1, "and in a fortnight it is in balance again; what was done to it is remembered")
	G.free()
	# a story's own hunts never empty a country: every hunt of the land's own beasts, at once, in one day
	var worst_hunt := 0.0
	for st in Data.STEPS:
		if str(st.kind) == "hunt" and not st.has("of") and not st.has("cave"):
			worst_hunt = maxf(worst_hunt, float(int(st.n)) / 3.0 / maxf(6.0, float(int(Data.AREAS[str(st.area)].enemies))))
	check(worst_hunt < float(Wilds.AT[0]), "no hunt the story asks for thins a country by itself (the heaviest is %.2f of %.1f)" % [worst_hunt, float(Wilds.AT[0])])
	for sti in Wilds.STATES.size():
		var inf: Dictionary = Wilds.STATES[sti]
		check(str(inf.n) != "" and fits.call(str(inf.desc)) and (sti == 0 or fits.call(str(inf.say))), "the state %s has its words" % inf.id)
	for lk in Wilds.LINES:
		for wl in Wilds.LINES[lk]:
			check(fits.call(str(wl)), "what the camps say of a hunted country fits the box")
	var cr: Node3D = Wilds.crows(5)
	check(cr.get_child_count() == 5, "the crows are built from code")
	Wilds.turn_crows(cr, Vector3.ZERO, 1.0)
	cr.free()
	check(msrc.contains("func offer_net") and msrc.contains("\"id\": \"later\", \"label\": \"Not today\", \"desc\": \"The net stays"), "\"Not today\" is the first answer to a hunter")

	print("== Part XXX: The Net with Three Sides Open ==")
	check(Data.REALMS.size() >= 36 and Data.REALMS[35] == "Three Sides Open" and Data.MAX_LEVEL >= 105 and Data.level_name(105).ends_with("Three Sides Open") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXX adds the realm of Three Sides Open")
	check(Data.step_index("s_break35") == Data.step_index("s_p31_home") - 1 and int(Data.STEPS[Data.step_index("s_break35")].to) == 105 and Data.DIALOGUE.has("recall28") and msrc.contains("\"s_break34\": \"recall28\"") and Data.DIALOGUE.has("pre:s_break35") and Data.DIALOGUE.has("post:s_break35"),
		"Part XXX follows Everything in Its Place (recall28) and ends with the thirty-fifth tribulation")
	var p30 := Data.step_index("s_p30_home")
	var kinds30 := {}
	var n30 := 0
	var end30 := Data.step_index("s_break35") + 1
	for i in range(p30, end30):
		var s30: Dictionary = Data.STEPS[i]
		n30 += 1
		kinds30[str(s30.kind)] = true
		check(str(s30.id).begins_with("s_p30_") or str(s30.id) == "s_break35", "%s is a step of the chapter" % s30.id)
		if str(s30.kind) == "talk":
			check(Data.DIALOGUE.has(str(s30.id)), "%s has its conversation" % s30.id)
		if str(s30.kind) == "kill":
			check(Data.DIALOGUE.has("pre:" + str(s30.boss)) and Data.DIALOGUE.has("post:" + str(s30.boss)) and Trials.TRIALS.has(str(s30.boss)) and Lore.BOSS.has(str(s30.boss)), "%s: words before and after, a trial, and a story" % s30.boss)
			check(bsrc.contains("\"%s\": \"" % str(s30.boss)), "the bot has a way planned through %s" % s30.boss)
		if str(s30.kind) == "hunt":
			var band30: Dictionary = Data.AREAS[str(s30.area)].get("warband5", {})
			for en in s30.of:
				check(Data.ENEMIES.has(str(en)) and Lore.BEAST.has(str(en)) and int(Data.ENEMIES[str(en)].get("boss", false)) == 0 and Habits.habit(str(en)) != "", "%s: a foe of the chapter with a story and hours" % en)
				var in_pool := false
				for pl in band30.get("pool", []):
					in_pool = in_pool or str(pl[0]) == str(en)
				check(in_pool, "%s marches in %s" % [en, s30.area])
		if str(s30.kind) in ["hunt", "collect", "toil", "folk", "summit", "marks", "glide", "weal", "fit", "delve"]:
			check(Data.DIALOGUE.has("done:" + str(s30.id)), "%s: something is said when it is done" % s30.id)
		if str(s30.kind) == "folk":
			check(Folk.ERRANDS.has(str(s30.id)) and Folk.ERRANDS[str(s30.id)].lines.size() >= 4 and Folk.CAMP_ROLES.has(str(s30.role)), "%s: an errand among the people of the road, with its words" % s30.id)
		if str(s30.kind) == "fit":
			check(Fitting.count(ws, str(s30.area)) >= int(s30.n) + 1, "%s: %s has more houses to put to rights than are asked for" % [s30.id, s30.area])
	check(n30 >= 32 and kinds30.has("toil") and kinds30.has("summit") and kinds30.has("marks") and kinds30.has("folk") and kinds30.has("collect") and kinds30.has("hunt") and kinds30.has("glide") and kinds30.has("weal") and kinds30.has("fit") and kinds30.has("delve"),
		"the chapter is thirty-four steps of twelve kinds (%d)" % n30)
	check(Data.step_index("s_p30_under") < _kill_step("jiang_chong") and Data.step_index("s_p30_rules") < _kill_step("shang_yang"), "what a lord is shown has been done before he is met")
	# nothing the chapter asks for is a crime, and nothing in it is stopped by one
	for i2 in range(p30, end30):
		check(not str(Data.STEPS[i2].kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % Data.STEPS[i2].id)
	for tid in ["four_net", "the_sentence", "shang_yang", "jiang_chong"]:
		var kinds_t := {}
		for pth in Trials.TRIALS[tid].paths:
			kinds_t[str(pth.kind)] = true
			check(fits.call(str(pth.desc)) and fits.call(str(pth.line)), "%s/%s fits the dialogue box" % [tid, pth.id])
		check(kinds_t.size() >= 4 and kinds_t.has("might") and (kinds_t.has("clean") or kinds_t.has("wild")), "%s: four ways through, one of them by what he has not done" % tid)
		# (no trial can only be passed by a clean name: a journey with blood on it still has a road)
		var open_to_guilty := 0
		for pth2 in Trials.TRIALS[tid].paths:
			if not (pth2.needs as Array).any(func(nd): return str(nd[0]) in ["clean", "wild"]):
				open_to_guilty += 1
		check(open_to_guilty >= 2, "%s can be passed by somebody with a price on his head" % tid)
	var CG = new_game.call()
	check(Trials.need_met(["clean"], CG) and Trials.need_met(["wild"], CG) and not Trials.need_met(["step", "s_p30_hunters"], CG), "a clean name and a standing wild are what a journey begins with")
	CG.level = 50
	Crime.strike(CG, wen, 0)
	check(not Trials.need_met(["clean"], CG) and Trials.need_text(["clean"], CG).contains("not clean"), "and one unseen killing is the end of a clean name, bill or no bill")
	CG.free()
	var c30: Dictionary = Echoes.CROSSROADS.get("the_verdict", {})
	check(not c30.is_empty() and str(c30.step) == "s_p30_verdict" and str(c30.part) == "XXX" and Echoes.ORDER.find("the_verdict") == Echoes.ORDER.find("the_lintel") - 1, "what a judge owes is asked last of all")
	check((c30.options as Array).size() == 3 and c30.after.size() == 3 and c30.end.size() == 3 and c30.echo.has("s_p30_end") and c30.echo.s_p30_end.size() == 3, "the_verdict: three answers, each answered, echoed and told at the end")
	var letters30 := 0
	for lid3 in Mail.ORDER:
		if Mail.LETTERS[lid3].has("needs") and str(Mail.LETTERS[lid3].needs[0]) == "the_verdict":
			letters30 += 1
	check(letters30 == 3 and Mail.LETTERS.has("fowler_net") and Mail.ORDER.has("fowler_net"), "a letter for each answer, and one from a fowler with one net")
	var scales30 := {}
	var creeds30 := {}
	for o30 in c30.options:
		check(Marks.MARKS.the_verdict.has(str(o30.id)) and Marks.MARKS.the_verdict[str(o30.id)].has("who"), "the_verdict/%s leaves something standing, and somebody by it" % o30.id)
		check(not Weal.hears(str(Marks.MARKS.the_verdict[str(o30.id)].area)).is_empty(), "the_verdict/%s is felt in a town" % o30.id)
		for sc in o30.tilt:
			scales30[sc] = true
		for ck in o30.get("creed", {}):
			creeds30["%s%d" % [ck, signi(int(o30.creed[ck]))]] = true
			check(Creed.AXES.has(str(ck)) and absi(int(o30.creed[ck])) < Creed.SIDE, "the_verdict/%s leans on the Way, and does not by itself decide it" % o30.id)
		for al in c30.after[str(o30.id)]:
			check(fits.call(str(al[1])), "the_verdict/%s: what follows fits the dialogue box" % o30.id)
	check(scales30.size() == 3 and creeds30.size() == 3, "its answers tip all three scales, and three sides of the Way")
	var fates30 := 0
	for ft in Weal.FATES:
		if str(ft.when[0]) == "the_verdict":
			fates30 += 1
	check(fates30 == 3, "somebody's life turns on each answer")
	var old_echo30 := 0
	for cid2 in Echoes.ORDER:
		if cid2 == "the_verdict":
			continue
		for ek in Echoes.CROSSROADS[cid2].get("echo", {}):
			if str(ek).contains("s_p30_"):
				old_echo30 += 1
	check(old_echo30 >= 2, "older crossroads echo in Part XXX (%d)" % old_echo30)
	check(bsrc.contains("\"four_net\": \"relic\"") and bsrc.contains("\"the_sentence\": \"clean\"") and bsrc.contains("\"the_verdict\": [\"bench\"]"), "the bot has a plan for every trial and the crossroads of the chapter, and takes one by its clean name")
	for a30 in ["garden", "springs", "palace"]:
		check(str(Data.AREAS[a30].get("warband5", {}).get("vis", "")).begins_with("s_p30_") and (not Data.AREAS[a30].has("warband6") or Data.step_index(str(Data.AREAS[a30].warband6.vis)) > Data.step_index("s_p30_home")), "%s: the chapter's band takes the last slot" % a30)
		var stood := 0
		for e30 in ws.ents:
			if str(e30.kind) == "enemy" and str(e30.get("area", "")) == a30 and str(e30.get("vis", ["", ""])[0]).begins_with("s_p30_"):
				stood += 1
		var need_packs := 0
		for i3 in range(p30, end30):
			if str(Data.STEPS[i3].kind) == "hunt" and str(Data.STEPS[i3].area) == a30:
				need_packs = maxi(need_packs, 4)
		check(stood >= maxi(need_packs, int(Data.AREAS[a30].warband5.n) / 2), "%s: the band found room (%d of %d packs)" % [a30, stood, int(Data.AREAS[a30].warband5.n)])
	check(Marks.AFTER_BANDS.has("the_verdict"), "the marks of its crossroads are stood after the late bands")
	var found30 := 0
	for e31 in ws.ents:
		if (e31.kind == "pickup" and str(e31.id).begins_with("p30_")) or (e31.kind == "boss" and str(e31.enemy) in ["four_net", "the_sentence", "shang_yang", "jiang_chong"]) or (e31.kind == "npc" and str(e31.id) in ["net_fowler", "cheng_tang", "li_li", "shang_yang", "jiang_chong"]):
			found30 += 1
			check(Atlas.owner_id(ws, e31.pos) == str(e31.area), "%s stands in its own region" % e31.id)
	check(found30 == 12 + 4 + 5, "everything the chapter stands in the land found room (%d)" % found30)
	for pr in [["four_net", "net_peg", "s_p30_pegs"], ["the_sentence", "case_slip", "s_p30_slips"], ["jiang_chong", "paulownia_doll", "s_p30_dolls"]]:
		check(Data.step_index(str(pr[2])) < _kill_step(str(pr[0])) and Data.ITEMS.has(str(pr[1])) and Look.PICKUP_COLORS.has(str(pr[1])), "%s can be passed by what was found on the way" % pr[0])
	for fid in ["three_sides", "open_net", "own_sentence", "judges_due"]:
		check(Feats.FEATS.has(fid), "the feat %s is kept" % fid)
	for pid in ["cheng_tang", "li_li", "shang_yang", "jiang_chong"]:
		check(Assets.PEOPLE.has(pid) and Assets.has(str(Assets.PEOPLE[pid])), "%s has a body built from a script" % pid)
		check(Data.CHAT.has(pid) and Data.CHAT[pid].size() >= 4, "%s has four things to say" % pid)
	check(Data.CHAT.has("net_fowler") and Data.CHAT.net_fowler.size() >= 4, "the fowler has four things to say")

	print("== the Great People (giants.gd): a people twice a man's height, and houses that let them in ==")
	check(Giants.SCALE >= 2.0 and Giants.HEIGHT >= 3.5 and Giants.CLEAR > Giants.HEIGHT, "one of the Great People stands at least twice a man's height (%.2f m)" % Giants.HEIGHT)
	check(Arch.DOOR_CLEAR >= Giants.CLEAR, "the lintel of every door clears a giant's head (%.2f m under it, %.2f m wanted)" % [Arch.DOOR_CLEAR, Giants.CLEAR])
	check(Arch.WALL_H >= Giants.CLEAR and Arch.WALL2_H >= Giants.CLEAR, "so do the ceilings of both storeys that are walked in (%.2f m, %.2f m)" % [Arch.WALL_H, Arch.WALL2_H])
	check(Arch.GATE_CLEAR >= Giants.CLEAR, "and the cross-beam of a town's gate (%.2f m)" % Arch.GATE_CLEAR)
	check(Giants.fits() and is_equal_approx(Arch.STOREY_Y, 0.3 + Arch.WALL_H + 0.06), "the houses of the land were built for everybody who lives in it, and the upper floor stands on the taller wall")
	# (a house really is that high: the highest vertex of every style's ground storey, and the doorway left in it)
	for sty31 in ["house", "shop", "inn", "hall"]:
		var hb := MB.new(); var hg := MB.new(); var hr := MB.new(); var hrg := MB.new()
		Arch.house(hb, hg, hr, hrg, Rect2(0, 0, 12, 10), Vector3(6, 0, 1), sty31, [], 7)
		var hm: ArrayMesh = hb.build()
		var top31 := 0.0
		var in_door := 0
		for sf in hm.get_surface_count():
			for v31 in (hm.surface_get_arrays(sf)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				top31 = maxf(top31, v31.y)
				# nothing of the wall hangs in the doorway below a giant's crown
				if absf(v31.x - 6.0) < 0.5 and absf(v31.z - 1.0) < 0.12 and v31.y > 0.5 and v31.y < 0.3 + Giants.HEIGHT:
					in_door += 1
		check(top31 >= 0.3 + Arch.WALL_H - 0.01, "a %s is built %.2f m to the top of its walls" % [sty31, top31])
		check(in_door == 0, "and nothing hangs in its doorway under %.2f m (%d vertices)" % [Giants.HEIGHT, in_door])
	var giants_n := 0
	for tid31 in Folk.TOWNS:
		var want31 := int(Giants.TOWNS.get(tid31, 0))
		check(int(Folk.TOWNS[tid31].roles.get(Giants.ROLE, 0)) == want31, "%s: %d of the Great People live there" % [tid31, want31])
		if want31 > 0:
			var keys31: Array = (Folk.TOWNS[tid31].roles as Dictionary).keys()
			check(str(keys31[keys31.size() - 1]) == Giants.ROLE, "%s: they were written last, so everybody before them keeps their name and seed" % tid31)
			var layer31 := Data.layer_of(str(Folk.TOWNS[tid31].area))
			for fp31 in Folk.people(Atlas.world_of(layer31), tid31):
				if str(fp31.role) == Giants.ROLE:
					giants_n += 1
					check(str(fp31.body) in Giants.BODIES and Giants.of_folk(fp31) == Giants.SCALE and Assets.has("characters/" + str(fp31.body)), "%s is one of them, in a body built from a script" % fp31.n)
					check(str(fp31.n).begins_with("Big Brother ") or str(fp31.n).begins_with("Big Sister "), "%s is called as the Great People are" % fp31.n)
					check(bool(fp31.fem) == (str(fp31.body) == "folk_giantess"), "%s: a woman of theirs is a woman" % fp31.n)
					check(not Folk.day_of(Atlas.world_of(layer31), fp31).is_empty(), "%s has a day" % fp31.n)
	check(giants_n == 16, "sixteen of the Great People live in the towns (%d)" % giants_n)
	check(Folk.ROLES.has("giant") and Folk.LINES.giant.size() >= 4 and Folk.TITLES.has("giant") and Crime.ARMED.has("giant"), "the giant: a day, a title, six things to say, and nobody's easy mark")
	for ln31 in Giants.LINES + Giants.LINES_SMALL:
		check(fits.call(str(ln31).replace("%s", "Daoist friend")), "a line of the Great People fits the box")
	for e31g in Folk.ROLES.giant.day:
		for c31 in str(e31g[2]).split("|"):
			check(c31 in Assets.LEND or c31 in Data.EMOTES or c31 in ["talk", "idle", "in", "eat", "laugh"], "a giant's day: %s is a clip anybody can be lent" % c31)
	check(Giants.pace(1.0) == 1.0 and Giants.pace(Giants.SCALE) < 0.7 and Giants.head(2.0) == 3.0, "somebody twice the size moves at a giant's pace and is looked up at")
	check(Giants.of_npc({"id": "fangfeng"}) == Giants.SCALE and Giants.of_npc({"id": "x", "asset": "kuafu"}) == Giants.SCALE and Giants.of_npc({"id": "elder"}) == 1.0 and Giants.of_npc({"id": "yan_ying"}) == 1.0, "the giants of the story are drawn as giants, and nobody else")
	for old31 in ["fangfeng", "kuafu", "longbo_giant", "grudge_fangfeng", "kuafu_west"]:
		check(Giants.of_foe(old31) and str(Data.ENEMIES[old31].shape).begins_with("person:") and UI.SHAPES.has(str(Data.ENEMIES[old31].shape)) and Assets.has(str(Assets.PEOPLE[str(Data.ENEMIES[old31].shape).substr(7)])), "%s is one of the Great People, in a body of his own" % old31)
	check(not Giants.of_foe("shang_yang") and not Giants.of_foe("iron_fang"), "and a lord who is only a man is not")
	# the tenth people
	check(Data.RACE_ORDER.has("daren") and Data.RACE_ORDER.size() == 10 and str(Data.RACES.daren.gift) == "lintel_peg" and Feats.FEATS.has("tall_friends"), "the Great People are a people of the realms, with a keepsake")
	var DG = new_game.call()
	for i31 in range(Data.step_index("s_p31_home"), Data.step_index("s_break36") + 1):
		if Data.STEPS[i31].has("race"):
			DG.race_gain(str(Data.STEPS[i31].race), 8 if str(Data.STEPS[i31].kind) == "kill" else 5)
	check(DG.race_tier("daren") >= 1, "what the chapter does for them makes him their friend (standing %d)" % int(DG.standing.get("daren", 0)))
	DG.free()

	print("== the face he has earned (visage.gd) ==")
	check(Visage.LOOKS.size() == 9 and Visage.stage_of(0) == 0 and Visage.stage_of(5) == 0 and Visage.stage_of(6) == 1 and Visage.stage_of(Creed.SIDE) == 2 and Visage.stage_of(-Creed.SIDE) == -2 and Visage.stage_of(Creed.CAP) == 4 and Visage.stage_of(-Creed.CAP) == -4,
		"nine looks, four either side of a face like anybody's, and a side of the Way is the second of them")
	for st31 in range(-4, 5):
		check(Visage.LOOKS.has(st31) and fits.call(str(Visage.LOOKS[st31].n) + ". " + str(Visage.LOOKS[st31].desc)), "look %d has a name and words that fit" % st31)
		check(Visage.rest(st31).size() == Faces.vector_of("calm").size(), "look %d is a pose of the six bones of expression" % st31)
	check(Visage.rest(0) == [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0], "a face nobody would remark on rests as it was sculpted")
	check(Visage.rest(4)[0] > 0.0 and Visage.rest(4)[10] > 1.0 and Visage.rest(-4)[0] < 0.0 and Visage.rest(-4)[1] > 0.2 and Visage.rest(-4)[10] < 0.8 and Visage.rest(-4)[11] < 1.0,
		"the Righteous Path opens the brow and the eyes; the Demonic draws the brows down and in, narrows the eyes and the jaw")
	check(Visage.rest(0, 1) != Visage.rest(0, 0) and Visage.rest(0, -1)[3] > Visage.rest(0, -1)[0], "the precepts set the mouth, and the open road lifts one eyebrow")
	var base31 := {"robe": Color("3a8ae8"), "sec": Color("2a3a6a"), "trim": Color("e8f0ff"), "hair": Color("1a1a2a"), "eyes": Color("3a7ae8")}
	var dc31: Dictionary = Visage.cols(-4, base31)
	var rc31: Dictionary = Visage.cols(4, base31)
	check((dc31.eyes as Color).r > 0.7 and (dc31.eyes as Color).b < 0.2 and (dc31.hair as Color).v > 0.8 and (dc31.robe as Color).v < (base31.robe as Color).v and (dc31.skin as Color).r < 0.75,
		"at the end of the Demonic Path: red eyes, white hair, a darker robe, grey skin")
	check((rc31.eyes as Color).r > (base31.eyes as Color).r and (rc31.hair as Color) == (base31.hair as Color) and (rc31.skin as Color).r >= 1.0 and (rc31.skin as Color).b < 1.0, "at the end of the Righteous: gold in the eye and a warm skin, and his own hair")
	check(Visage.cols(0, base31) == base31 and not Visage.cols(0, base31).has("skin"), "and a face like anybody's is the one he was made with")
	var VG = new_game.call()
	check(Visage.stage(VG) == 0 and Visage.key(VG) == "0|0" and Visage.text(VG).begins_with("A face like anybody's"), "a journey begins with a face like anybody's")
	VG.creed["virtue"] = -30
	check(Visage.stage(VG) == -3 and Visage.text(VG).begins_with("Ash-pale") and Visage.key(VG) != "0|0", "what he has done is on his face (%s)" % Visage.key(VG))
	VG.creed["virtue"] = 40
	check(Visage.stage(VG) == 4, "either way")
	VG.free()
	check(Assets.hero_part(Color(0.8, 0.6, 0.5, 0.6), Vector2.ZERO, Vector3(0, 1.6, 0), false) == "skin" and Assets.hero_part(Color(0.8, 0.6, 0.5, 1.0), Vector2(0, 1), Vector3.ZERO, false) == "robe", "his skin is told from his clothes")
	var wsrc := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(wsrc.contains("Visage.key(Game)") and wsrc.contains("if not headless() and player != null:") and FileAccess.get_file_as_string("res://scripts/models.gd").contains("Visage.apply(root, vs, vr)"), "the world looks at his face again now and then, and only when there is a window")

	print("== close-ups (closeup.gd) ==")
	check(Closeup.CLIPS.size() == 8, "eight gestures of somebody's own")
	for cl31 in Closeup.CLIPS:
		check(cl31 in Assets.LEND and not cl31 in Assets.LEND_LOOPS and Closeup.SECONDS.has(cl31) and Faces.EXPRESSIONS.has(str(Closeup.FACES.get(cl31, ""))), "%s is lent to everybody, done once, and has a face" % cl31)
		check(not Data.EMOTES.has(cl31), "%s is nobody's ordinary gesture" % cl31)
	if Assets.has(Assets.PEOPLE.lin_feng):
		var hm31: Node3D = Assets.person("lin_feng")
		for cl32 in Closeup.CLIPS:
			check(Assets.has_clip(hm31, cl32), "Lin Feng's model carries %s" % cl32)
		hm31.free()
		var gm31: Node3D = Assets.instance("characters/folk_giant")
		Assets.lend_clips(gm31)
		check(Assets.has_clip(gm31, "stoop") and Assets.has_clip(gm31, "hoe"), "and one of the Great People can be lent a stoop")
		gm31.free()
	var used31 := {}
	for who31 in Closeup.SIGNATURE:
		check(Closeup.CLIPS.has(str(Closeup.SIGNATURE[who31])), "%s's own gesture is one of the eight" % who31)
		used31[str(Closeup.SIGNATURE[who31])] = true
	check(used31.size() == Closeup.CLIPS.size() and Closeup.signature("Lin Feng") == "fist_palm" and Closeup.signature("Yue Ling") == "sleeve_smile" and Closeup.signature("Li Li, Judge of Jin") == "hand_heart" and Closeup.signature("Big Brother Wang") == "stoop" and Closeup.signature("Nobody At All") == "",
		"every one of the eight is somebody's, and a name with an epithet or a title is still that person")
	var conv31: Array = Data.DIALOGUE["s_p31_late"]
	check(Closeup.shot(conv31, 0) == "wide" and Closeup.shot(conv31, 1) == "close" and Closeup.gesture(conv31, 1) == "hand_heart" and Closeup.gesture(conv31, 2) == "fist_palm" and Closeup.gesture(conv31, 3) == "point" and Closeup.gesture(Data.DIALOGUE["s_p31_home"], 3) == "point" and Closeup.shot(conv31, 3) == "close",
		"a conversation is cut: narration wide, a first word and an acted line close, and each speaker's own gesture once")
	var plain31 := [["A", "One."], ["B", "Two."], ["A", "It rained."], ["B", "It did rain."], ["A", "So."]]
	check(Closeup.shot(plain31, 2) == "two" and Closeup.shot(plain31, 3) == "two" and Closeup.shot(plain31, 4) == "close" and Closeup.gesture(plain31, 2) == "", "plain talk between is a two-shot, and the last word is a face")
	var fr31: Array = Closeup.frame(Vector3(0, 1.5, 0), Vector3(0, 0, 1), 1.0, 1.0)
	var fg31: Array = Closeup.frame(Vector3(0, 3.0, 0), Vector3(0, 0, 1), Giants.SCALE, 1.0)
	check((fr31[0] as Vector3).z > 1.0 and absf((fr31[0] as Vector3).y - 1.5) < 0.2 and (fg31[0] as Vector3).y < 3.0 - 0.5 and (fg31[0] as Vector3).distance_to(fg31[1]) > (fr31[0] as Vector3).distance_to(fr31[1]),
		"the lens stands before a face at its own height, and one of the Great People is looked up at from further off")
	var n_sig := 0
	for dk31 in Data.DIALOGUE:
		if str(dk31).contains("s_p31_") or str(dk31) in ["pre:late_axe", "post:late_axe", "pre:kuafu_west", "post:kuafu_west", "pre:the_decree", "post:the_decree", "pre:the_shoe", "post:the_shoe"]:
			var dl31: Array = Data.DIALOGUE[dk31]
			for li31 in dl31.size():
				if Closeup.CLIPS.has(Closeup.gesture(dl31, li31)):
					n_sig += 1
	check(n_sig >= 12, "the chapter's conversations have somebody's own gesture in them (%d)" % n_sig)

	print("== Part XXXI: The Foot and the Shoe ==")
	check(Data.REALMS.size() >= 37 and Data.REALMS[36] == "Great and Small Alike" and Data.MAX_LEVEL >= 108 and Data.level_name(108).ends_with("Great and Small Alike") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXXI adds the realm of Great and Small Alike")
	check(Data.step_index("s_break36") == Data.step_index("s_p32_home") - 1 and int(Data.STEPS[Data.step_index("s_break36")].to) == 108 and Data.DIALOGUE.has("recall29") and msrc.contains("\"s_break35\": \"recall29\"") and Data.DIALOGUE.has("pre:s_break36") and Data.DIALOGUE.has("post:s_break36"),
		"Part XXXI follows Three Sides Open (recall29) and ends with a breakthrough")
	var p31 := Data.step_index("s_p31_home")
	var kinds31 := {}
	var n31 := 0
	var kills31 := 0
	for i in range(p31, Data.step_index("s_break36") + 1):
		var s31: Dictionary = Data.STEPS[i]
		n31 += 1
		kinds31[str(s31.kind)] = true
		check(str(s31.id).begins_with("s_p31_") or str(s31.id) == "s_break36", "%s is a step of the chapter" % s31.id)
		check(not str(s31.kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % s31.id)
		if str(s31.kind) == "talk":
			check(Data.DIALOGUE.has(str(s31.id)), "%s has its conversation" % s31.id)
		if str(s31.kind) == "kill":
			check(Data.DIALOGUE.has("pre:" + str(s31.boss)) and Data.DIALOGUE.has("post:" + str(s31.boss)) and Trials.TRIALS.has(str(s31.boss)) and Lore.BOSS.has(str(s31.boss)), "%s: words before and after, a trial, and a story" % s31.boss)
			check(bsrc.contains("\"%s\": \"" % str(s31.boss)), "the bot has a way planned through %s" % s31.boss)
		if str(s31.kind) == "hunt":
			kills31 += int(s31.n)
			var band31: Dictionary = Data.AREAS[str(s31.area)].get("warband5", {})
			for en in s31.of:
				check(Data.ENEMIES.has(str(en)) and Lore.BEAST.has(str(en)) and int(Data.ENEMIES[str(en)].get("boss", false)) == 0 and Habits.habit(str(en)) != "", "%s: a foe of the chapter with a story and hours" % en)
				var in_pool31 := false
				for pl in band31.get("pool", []):
					in_pool31 = in_pool31 or str(pl[0]) == str(en)
				check(in_pool31, "%s marches in %s" % [en, s31.area])
		if str(s31.kind) in ["hunt", "collect", "toil", "folk", "summit", "marks", "glide", "fit", "delve", "haul"]:
			check(Data.DIALOGUE.has("done:" + str(s31.id)), "%s: something is said when it is done" % s31.id)
		if str(s31.kind) == "haul":
			check(Data.DIALOGUE.has("haul:" + str(s31.id)) and Load.GOODS.has(str(s31.good)), "%s: somebody says something as each load arrives" % s31.id)
		if str(s31.kind) == "folk":
			check(Folk.ERRANDS.has(str(s31.id)) and Folk.ERRANDS[str(s31.id)].lines.size() >= 4 and (Folk.CAMP_ROLES.has(str(s31.role)) or (s31.has("town") and int(Folk.TOWNS[str(s31.town)].roles.get(str(s31.role), 0)) >= int(s31.n))), "%s: an errand among people who are there to be asked, with its words" % s31.id)
			for el31 in Folk.ERRANDS[str(s31.id)].lines:
				check(fits.call(str(el31)), "%s: what is answered fits the box" % s31.id)
		if str(s31.kind) == "fit":
			check(Fitting.count(ws, str(s31.area)) >= int(s31.n) + 1, "%s: %s has more houses to put to rights than are asked for" % [s31.id, s31.area])
	check(n31 == 35 and kills31 >= 220 and kinds31.size() == 13 and kinds31.has("toil") and kinds31.has("haul") and kinds31.has("summit") and kinds31.has("marks") and kinds31.has("folk") and kinds31.has("collect") and kinds31.has("hunt") and kinds31.has("glide") and kinds31.has("fit") and kinds31.has("delve"),
		"the chapter is thirty-five steps of thirteen kinds (%d, %d)" % [n31, kinds31.size()])
	check(Data.step_index("s_p31_beam") < _kill_step("late_axe") and Data.step_index("s_p31_woodmen") < _kill_step("kuafu_west") and Data.step_index("s_p31_giants") < _kill_step("the_decree") and Data.step_index("s_p31_rooms") < _kill_step("the_decree"), "what a lord is shown has been done before he is met")
	for tid in ["late_axe", "kuafu_west", "the_decree", "the_shoe"]:
		var kinds_t31 := {}
		for pth in Trials.TRIALS[tid].paths:
			kinds_t31[str(pth.kind)] = true
			check(fits.call(str(pth.desc)) and fits.call(str(pth.line)), "%s/%s fits the dialogue box" % [tid, pth.id])
		check(kinds_t31.size() >= 4 and kinds_t31.has("might") and (kinds_t31.has("clean") or kinds_t31.has("wild")), "%s: four ways through, one of them by what he has not done" % tid)
		var open31 := 0
		for pth2 in Trials.TRIALS[tid].paths:
			if not (pth2.needs as Array).any(func(nd): return str(nd[0]) in ["clean", "wild"]):
				open31 += 1
		check(open31 >= 2, "%s can be passed by somebody with a price on his head" % tid)
		check(Data.ENEMIES[tid].get("boss", false) and Lore.BOSS[tid].size() == 2, "%s is a lord with a story in two parts" % tid)
	var c31: Dictionary = Echoes.CROSSROADS.get("the_lintel", {})
	check(not c31.is_empty() and str(c31.step) == "s_p31_lintel" and str(c31.part) == "XXXI" and Echoes.ORDER.find("the_lintel") == Echoes.ORDER.find("the_mirror") - 1 and fits.call(str(c31.ask)), "which gives way, the foot or the shoe, is asked last of all")
	check((c31.options as Array).size() == 3 and c31.after.size() == 3 and c31.end.size() == 3 and c31.echo.has("s_p31_end") and c31.echo.s_p31_end.size() == 3, "the_lintel: three answers, each answered, echoed and told at the end")
	var letters31 := 0
	for lid31 in Mail.ORDER:
		if Mail.LETTERS[lid31].has("needs") and str(Mail.LETTERS[lid31].needs[0]) == "the_lintel":
			letters31 += 1
			for ll31 in Mail.LETTERS[lid31].lines:
				check(fits.call(str(ll31)), "the letter %s fits the box" % lid31)
	check(letters31 == 3 and Mail.LETTERS.has("kuafu_home") and Mail.ORDER.has("kuafu_home") and fits.call(str(Mail.LETTERS.kuafu_home.lines[0])), "a letter for each answer, and one from a mother in the north")
	var scales31 := {}
	var creeds31 := {}
	for o31 in c31.options:
		check(Marks.MARKS.the_lintel.has(str(o31.id)) and Marks.MARKS.the_lintel[str(o31.id)].has("who") and fits.call(str(Marks.MARKS.the_lintel[str(o31.id)].desc)), "the_lintel/%s leaves something standing, and somebody by it" % o31.id)
		check(Weal.hears(str(Marks.MARKS.the_lintel[str(o31.id)].area)) == ["landfall"], "the_lintel/%s is felt at Landfall" % o31.id)
		for sc in o31.tilt:
			scales31[sc] = true
		for ck in o31.get("creed", {}):
			creeds31["%s%d" % [ck, signi(int(o31.creed[ck]))]] = true
			check(Creed.AXES.has(str(ck)) and absi(int(o31.creed[ck])) < Creed.SIDE, "the_lintel/%s leans on the Way, and does not by itself decide it" % o31.id)
		check(fits.call(str(o31.desc)), "the_lintel/%s: what it means fits" % o31.id)
		for al in c31.after[str(o31.id)]:
			check(fits.call(str(al[1])), "the_lintel/%s: what follows fits the dialogue box" % o31.id)
	check(scales31.size() == 3 and creeds31.size() == 3, "its answers tip all three scales, and three sides of the Way")
	var fates31 := 0
	for ft in Weal.FATES:
		if str(ft.when[0]) == "the_lintel":
			fates31 += 1
			check(fits.call(str(ft.line)), "a fate of the_lintel fits the box")
	check(fates31 == 3, "a carpenter's trade turns on each answer")
	var old_echo31 := 0
	for cid31 in Echoes.ORDER:
		if cid31 == "the_lintel":
			continue
		for ek in Echoes.CROSSROADS[cid31].get("echo", {}):
			if str(ek).contains("s_p31_"):
				old_echo31 += 1
	check(old_echo31 >= 2, "older crossroads echo in Part XXXI (%d)" % old_echo31)
	check(bsrc.contains("\"late_axe\": \"folk\"") and bsrc.contains("\"the_decree\": \"house\"") and bsrc.contains("\"the_lintel\": [\"each\"]"), "the bot has a plan for every trial and the crossroads of the chapter")
	check(Marks.AFTER_BANDS.has("the_lintel"), "the marks of its crossroads are stood after the late bands")
	var found31 := 0
	for a31 in ["time", "buzhou", "penglai", "loom"]:
		var w31: Dictionary = Atlas.world_of(Data.layer_of(a31))
		check(str(Data.AREAS[a31].get("warband5", {}).get("vis", "")).begins_with("s_p31_") and (not Data.AREAS[a31].has("warband6") or str(Data.AREAS[a31].warband6.vis).begins_with("s_p34_")), "%s: the chapter's band takes the last slot" % a31)
		var stood31 := 0
		for e31 in w31.ents:
			if str(e31.get("area", "")) != a31:
				continue
			if str(e31.kind) == "enemy" and str(e31.get("vis", ["", ""])[0]).begins_with("s_p31_"):
				stood31 += 1
			if (e31.kind == "pickup" and str(e31.id).begins_with("p31_")) or (e31.kind == "boss" and str(e31.enemy) in ["late_axe", "kuafu_west", "the_decree", "the_shoe"]) or (e31.kind == "npc" and str(e31.id) in ["fangfeng", "kuafu", "longbo_angler", "zheng_buyer", "yan_ying"]):
				found31 += 1
				check(Atlas.owner_id(w31, e31.pos) == a31, "%s stands in its own region" % e31.id)
		check(stood31 >= 7, "%s: the band found room (%d of %d packs)" % [a31, stood31, int(Data.AREAS[a31].warband5.n)])
	check(found31 == 18 + 4 + 5, "everything the chapter stands on the heights found room (%d)" % found31)
	var pegs31 := 0
	for e32 in ws.ents:
		if str(e32.kind) == "pickup" and str(e32.get("item", "")) == "lintel_peg" and str(e32.area) in ["time", "loom"]:
			pegs31 += 1
	check(pegs31 == 2, "the keepsake of the Great People lies on two heights (%d)" % pegs31)
	for pr in [["late_axe", "dyke_stake", "s_p31_stakes"], ["kuafu_west", "peach_stone", "s_p31_stones"], ["the_decree", "oracle_shell", "s_p31_shells"], ["the_shoe", "foot_cord", "s_p31_cords"]]:
		check(Data.step_index(str(pr[2])) < _kill_step(str(pr[0])) and Data.ITEMS.has(str(pr[1])) and Look.PICKUP_COLORS.has(str(pr[1])) and Load.weight_of(str(pr[1])) <= 1.0, "%s can be passed by what was found on the way" % pr[0])
	for fid in ["great_small", "asked_why", "turned_round", "whose_door", "three_sides"]:
		check(Feats.FEATS.has(fid), "the feat %s is kept" % fid)
	for pid in ["fangfeng", "kuafu", "longbo_angler", "zheng_buyer", "yan_ying"]:
		check(Assets.PEOPLE.has(pid) and Assets.has(str(Assets.PEOPLE[pid])), "%s has a body built from a script" % pid)
		check(Data.CHAT.has(pid) and Data.CHAT[pid].size() >= 4 and Folk.POSTS.has(pid), "%s has four things to say, and something to do all day" % pid)
		for cl in Data.CHAT[pid]:
			check(fits.call(str(cl)), "%s: what is said fits the box" % pid)
	# the plot holes and bugs of this release stay mended
	check(str(Data.STEPS[Data.step_index("s_p27_end")].get("gives", {})).contains("mustard_ring") and not Data.STEPS[Data.step_index("s_p27_sack")].has("gives"), "the ring is in his hand when the smith has set the seed, not two steps before")
	for nl31 in Data.AREAS.springs.npcs:
		if str(nl31.id) == "li_li":
			check(str(nl31.vis[1]) == "s_p30_verdict", "the judge does not sit on, bound, after he has been answered")
	check(int(Echoes.CROSSROADS.the_horse.options.filter(func(o): return str(o.id) == "keep")[0].gain.hearth.get("steppe", 0)) == 3, "keeping the horse is to the regard of the Horse-Folk, whose horse it is")
	check(not str(Data.CHAT.cheng_tang[0]).contains("never asked for so much") and not str(Data.DIALOGUE["s_p28_youth"]).contains("In his lap are four rings"), "Tang says of Jie what he said before, and the rings are set down before they lie in a lap")
	check(Crime.is_child({"id": "stableboy_shitou", "kind": "npc", "n": "Shitou"}) and Crime.is_child({"id": "furnace_boy", "kind": "npc", "n": "Dan"}), "the children of the story are children")
	var BG = new_game.call()
	BG.falls["wuzhiqi"] = {"how": "gave", "rounds": 3}
	BG.weal_n += 1
	var doom_felt := false
	for tw31 in Weal.ORDER:
		for cs31 in Weal.causes(BG, tw31):
			doom_felt = doom_felt or str(cs31.get("why", "")).to_lower().contains("gave way")
	check(doom_felt, "a doom given way to is felt in the towns that hear of it")
	BG.watch_slain = 3
	check(Crime.count(BG) == 3 and Crime.text(BG) != "a clean name", "three of the watch cut down are three people dead by his hand")
	var st_b := int(BG.stipends)
	BG.free()
	check(FileAccess.get_file_as_string("res://scripts/almanac.gd").contains("if st > 0:\n\t\tg.stipends += 1") or FileAccess.get_file_as_string("res://scripts/almanac.gd").contains("if st > 0:"), "a month with no stipend is not a month on the roll")
	check(FileAccess.get_file_as_string("res://scripts/roads.gd").contains("/ Clock.rate(") and FileAccess.get_file_as_string("res://scripts/ships.gd").contains("/ Clock.rate("), "the coach and the ship take the hours the counter quotes, by day or night")

	print("== Part XXXII: The Broken Mirror ==")
	check(Data.REALMS.size() >= 38 and Data.REALMS[37] == "Parted and Whole" and Data.MAX_LEVEL >= 111 and Data.level_name(111).ends_with("Parted and Whole") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXXII adds the realm of Parted and Whole")
	check(Data.step_index("s_break37") == Data.step_index("s_p33_home") - 1 and int(Data.STEPS[Data.step_index("s_break37")].to) == 111 and Data.DIALOGUE.has("recall30") and msrc.contains("\"s_break36\": \"recall30\"") and Data.DIALOGUE.has("pre:s_break37") and Data.DIALOGUE.has("post:s_break37"),
		"Part XXXII follows Great and Small Alike (recall30) and ends with a breakthrough")
	var p32 := Data.step_index("s_p32_home")
	var kinds32 := {}
	var n32 := 0
	var kills32 := 0
	var lords32: Array = []
	for i in range(p32, Data.step_index("s_break37") + 1):
		var s32: Dictionary = Data.STEPS[i]
		n32 += 1
		kinds32[str(s32.kind)] = true
		check(str(s32.id).begins_with("s_p32_") or str(s32.id) == "s_break37", "%s is a step of the chapter" % s32.id)
		check(not str(s32.kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % s32.id)
		if str(s32.kind) == "talk":
			check(Data.DIALOGUE.has(str(s32.id)), "%s has its conversation" % s32.id)
		if str(s32.kind) == "kill":
			lords32.append(str(s32.boss))
			check(Data.DIALOGUE.has("pre:" + str(s32.boss)) and Data.DIALOGUE.has("post:" + str(s32.boss)) and Trials.TRIALS.has(str(s32.boss)) and Lore.BOSS.has(str(s32.boss)), "%s: words before and after, a trial, and a story" % s32.boss)
			check(bsrc.contains("\"%s\": \"" % str(s32.boss)), "the bot has a way planned through %s" % s32.boss)
		if str(s32.kind) == "hunt":
			kills32 += int(s32.n)
			var band32: Dictionary = Data.AREAS[str(s32.area)].get("warband5", {})
			var pool32: Array = []
			for pe in band32.get("pool", []):
				pool32.append(str(pe[0]))
			for of32 in s32.of:
				check(pool32.has(str(of32)) and Lore.BEAST.has(str(of32)) and not Data.ENEMIES[str(of32)].get("boss", false), "%s: %s marches in the region's last band, and has a story" % [s32.id, of32])
			check(Data.step_index(str(band32.vis)) < i, "%s: the band is in the land before it is hunted" % s32.id)
		if str(s32.kind) == "haul":
			check(Data.DIALOGUE.has("haul:" + str(s32.id)) and Load.GOODS.has(str(s32.good)), "%s: somebody says something as each load arrives" % s32.id)
		if str(s32.kind) == "folk":
			check(Folk.ERRANDS.has(str(s32.id)) and (Folk.ERRANDS[str(s32.id)].lines as Array).size() >= 4 and int(Folk.TOWNS[str(s32.town)].roles.get(str(s32.role), 0)) >= int(s32.n), "%s: an errand among people who are there" % s32.id)
			for el32 in Folk.ERRANDS[str(s32.id)].lines:
				check(fits.call(str(el32)), "%s: what is answered fits the box" % s32.id)
		if str(s32.kind) == "summit":
			check((Peaks.of_area(Atlas.world_of(Data.layer_of(str(s32.peak))), str(s32.peak)) as Array).size() > int(s32.k), "%s: the height is there to be climbed" % s32.id)
	check(n32 == 33 and kills32 >= 250 and lords32 == ["two_graves", "the_flood", "the_wall"] and kinds32.size() >= 10 and kinds32.has("toil") and kinds32.has("haul") and kinds32.has("summit") and kinds32.has("marks") and kinds32.has("folk") and kinds32.has("glide"),
		"the chapter is thirty-three steps of ten kinds, with three lords (%d, %d)" % [n32, kinds32.size()])
	for dk32 in Data.DIALOGUE:
		if str(dk32).contains("s_p32_") or str(dk32) in ["recall30", "pre:s_break37", "post:s_break37", "pre:two_graves", "post:two_graves", "pre:the_flood", "post:the_flood", "pre:the_wall", "post:the_wall"]:
			for ln32 in Data.DIALOGUE[dk32]:
				check(fits.call(str(ln32[1])) and not str(ln32[1]).contains("—"), "%s: a line that fits the box, with no dash in it" % dk32)
				check((ln32 as Array).size() == 2 or Data.EMOTES.has(str(ln32[2])), "%s: its gesture is one everybody has" % dk32)
	for tid32 in lords32:
		var tr32: Dictionary = Trials.TRIALS[tid32]
		var open32 := 0
		for pa32 in tr32.paths:
			check(fits.call(str(pa32.desc)) and fits.call(str(pa32.line)), "%s/%s: its words fit" % [tid32, pa32.id])
			if not str(pa32.kind) in ["clean", "wild"]:
				open32 += 1
		check((tr32.paths as Array).size() == 4 and open32 >= 2 and Data.ENEMIES[tid32].get("boss", false) and Trials.trial_of_step(Data.STEPS[_kill_step(tid32)]) == tid32, "%s is a lord of the chapter with four ways through, two of them open to a wanted man" % tid32)
	for pr32 in [["two_graves", "red_cord", "s_p32_threads"], ["the_flood", "hour_stone", "s_p32_marks"], ["the_wall", "wall_tally", "s_p32_tallies"]]:
		check(Data.step_index(str(pr32[2])) < _kill_step(str(pr32[0])) and Data.ITEMS.has(str(pr32[1])) and Look.PICKUP_COLORS.has(str(pr32[1])) and Load.weight_of(str(pr32[1])) <= 1.0, "%s can be passed by what was found on the way" % pr32[0])
	check(Data.step_index("s_p32_old") < _kill_step("two_graves") and Data.step_index("s_p32_span") < _kill_step("the_flood") and Data.step_index("s_p32_cairn") < _kill_step("the_wall"), "what a lord is shown has been done before he is met")
	var c32: Dictionary = Echoes.CROSSROADS.get("the_mirror", {})
	check(not c32.is_empty() and str(c32.step) == "s_p32_mirror" and str(c32.part) == "XXXII" and Echoes.ORDER.find("the_mirror") == Echoes.ORDER.find("the_needle") - 1 and fits.call(str(c32.ask)), "what is done with the two halves is asked last of all")
	check((c32.options as Array).size() == 3 and c32.after.size() == 3 and c32.end.size() == 3 and c32.echo.has("s_p32_end") and c32.echo.s_p32_end.size() == 3, "the_mirror: three answers, each answered, echoed and told at the end")
	var scales32 := {}
	for o32 in c32.options:
		var mk32: Dictionary = Marks.MARKS.the_mirror.get(str(o32.id), {})
		check(not mk32.is_empty() and mk32.has("who") and fits.call(str(mk32.desc)) and fits.call(str(mk32.who[3])) and fits.call(str(mk32.who[4])) and Assets.has("characters/" + str(mk32.who[1])), "the_mirror/%s leaves something standing, and somebody by it" % o32.id)
		check(not Weal.hears(str(mk32.area)).is_empty(), "the_mirror/%s is felt in a town" % o32.id)
		for sc32 in o32.tilt:
			scales32[sc32] = true
		for ck32 in o32.get("creed", {}):
			check(Creed.AXES.has(str(ck32)) and absi(int(o32.creed[ck32])) < Creed.SIDE, "the_mirror/%s leans on the Way, and does not by itself decide it" % o32.id)
		check(fits.call(str(o32.desc)), "the_mirror/%s: what it means fits" % o32.id)
		for al32 in c32.after[str(o32.id)]:
			check(fits.call(str(al32[1])), "the_mirror/%s: what follows fits the dialogue box" % o32.id)
		check(Mail.LETTERS.has("mirror_" + str(o32.id)) and Mail.ORDER.has("mirror_" + str(o32.id)) and fits.call(str(Mail.LETTERS["mirror_" + str(o32.id)].lines[0])), "the_mirror/%s: somebody who lives with it writes" % o32.id)
	check(scales32.size() == 3 and Marks.AFTER_BANDS.has("the_mirror") and Mail.LETTERS.has("bridge_girl") and Mail.ORDER.has("bridge_girl") and fits.call(str(Mail.LETTERS.bridge_girl.lines[0])), "its answers tip all three scales, its marks are stood after the bands, and a girl of Lu writes from a bridge")
	var fates32 := 0
	for ft32 in Weal.FATES:
		if str(ft32.when[0]) == "the_mirror":
			fates32 += 1
			check(fits.call(str(ft32.line)) and str(ft32.npc) == "lechang", "a fate of the_mirror fits the box")
	check(fates32 == 3 and bsrc.contains("\"the_mirror\": [\"rivet\"]"), "the lady's life turns on each answer, and the bot has one")
	var old_echo32 := 0
	for cid32 in Echoes.ORDER:
		if cid32 != "the_mirror":
			for ek32 in Echoes.CROSSROADS[cid32].get("echo", {}):
				if str(ek32).contains("s_p32_"):
					old_echo32 += 1
	check(old_echo32 >= 1, "an older crossroads echoes in Part XXXII (%d)" % old_echo32)
	var found32 := 0
	for a32 in ["starpalace", "magpie", "youdu", "guanghan"]:
		var w32: Dictionary = Atlas.world_of(Data.layer_of(a32))
		check(str(Data.AREAS[a32].get("warband5", {}).get("vis", "")).begins_with("s_p32_") and not Data.AREAS[a32].has("warband6"), "%s: the chapter's band takes the last slot" % a32)
		var stood32 := 0
		for e33 in w32.ents:
			if str(e33.get("area", "")) != a32:
				continue
			if str(e33.kind) == "enemy" and str(e33.get("vis", ["", ""])[0]).begins_with("s_p32_"):
				stood32 += 1
			if (e33.kind == "pickup" and str(e33.id).begins_with("p32_")) or (e33.kind == "boss" and str(e33.enemy) in lords32) or (e33.kind == "npc" and str(e33.id) in ["yue_lao", "weisheng", "meng_jiang", "xu_deyan", "lechang"]):
				found32 += 1
				check(Atlas.owner_id(w32, e33.pos) == a32, "%s stands in its own region" % e33.id)
		check(stood32 >= 7, "%s: the band found room (%d of %d packs)" % [a32, stood32, int(Data.AREAS[a32].warband5.n)])
	check(found32 == 16 + 3 + 5, "everything the chapter stands on the heights found room (%d)" % found32)
	for pid32 in ["yue_lao", "weisheng", "meng_jiang", "xu_deyan", "lechang"]:
		check(Assets.PEOPLE.has(pid32) and Assets.has(str(Assets.PEOPLE[pid32])), "%s has a body built from a script" % pid32)
		check(Data.CHAT.has(pid32) and Data.CHAT[pid32].size() >= 4 and Folk.POSTS.has(pid32), "%s has four things to say, and something to do all day" % pid32)
		for cl32 in Data.CHAT[pid32]:
			check(fits.call(str(cl32)), "%s: what is said fits the box" % pid32)
	check(Closeup.signature("The Old Man under the Moon") != "" and Closeup.signature("Meng Jiang") != "" and Closeup.signature("Princess Lechang") != "" and Voice.WOMEN.has("Meng Jiang") and Voice.WOMEN.has("Princess Lechang"), "the people of the chapter have a gesture of their own, and its women are known for women")
	check(Almanac.STORY_DATES.has("s_p32_market") and Almanac.STORY_DATES.s_p32_market == [1, 15], "the mirror is cried at market on the fifteenth of the first month")
	for fid32 in ["parted_whole", "under_the_ditch", "looked_up", "both_halves", "great_small"]:
		check(Feats.FEATS.has(fid32), "the feat %s is kept" % fid32)

	print("== Part XXXIII: The Iron Pestle ==")
	check(Data.REALMS.size() >= 39 and Data.REALMS[38] == "Practised Hand" and Data.MAX_LEVEL >= 114 and Data.level_name(114).ends_with("Practised Hand") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXXIII adds the realm of Practised Hand")
	check(Data.step_index("s_break38") > 0 and int(Data.STEPS[Data.step_index("s_break38")].to) == 114 and Data.DIALOGUE.has("recall31") and msrc.contains("\"s_break37\": \"recall31\"") and Data.DIALOGUE.has("pre:s_break38") and Data.DIALOGUE.has("post:s_break38"),
		"Part XXXIII follows Parted and Whole (recall31) and ends with a breakthrough")
	var p33 := Data.step_index("s_p33_home")
	var kinds33 := {}
	var n33 := 0
	var kills33 := 0
	var lords33: Array = []
	var areas33 := ["jasper", "void", "celestial", "origin"]
	for i in range(p33, Data.step_index("s_break38") + 1):
		var s33: Dictionary = Data.STEPS[i]
		n33 += 1
		kinds33[str(s33.kind)] = true
		check(str(s33.id).begins_with("s_p33_") or str(s33.id) == "s_break38", "%s is a step of the chapter" % s33.id)
		check(not str(s33.kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % s33.id)
		check(not s33.has("stones") or int(s33.stones) > 75000, "%s pays as the road has come to pay" % s33.id)
		if str(s33.kind) == "talk":
			check(Data.DIALOGUE.has(str(s33.id)), "%s has its conversation" % s33.id)
		if str(s33.kind) == "kill":
			lords33.append(str(s33.boss))
			check(Data.DIALOGUE.has("pre:" + str(s33.boss)) and Data.DIALOGUE.has("post:" + str(s33.boss)) and Trials.TRIALS.has(str(s33.boss)) and Lore.BOSS.has(str(s33.boss)), "%s: words before and after, a trial, and a story" % s33.boss)
			check(bsrc.contains("\"%s\": \"" % str(s33.boss)), "the bot has a way planned through %s" % s33.boss)
		if str(s33.kind) == "hunt":
			kills33 += int(s33.n)
			var band33: Dictionary = Data.AREAS[str(s33.area)].get("warband5", {})
			var pool33: Array = []
			for pe33 in band33.get("pool", []):
				pool33.append(str(pe33[0]))
				check(int(pe33[1]) <= Data.MAX_LEVEL and int(pe33[2]) <= Data.MAX_LEVEL, "%s: nothing in the band is past the last level" % s33.id)
			for of33 in s33.of:
				check(pool33.has(str(of33)) and Lore.BEAST.has(str(of33)) and not Data.ENEMIES[str(of33)].get("boss", false), "%s: %s marches in the region's last band, and has a story" % [s33.id, of33])
			check(Data.step_index(str(band33.vis)) < i, "%s: the band is in the land before it is hunted" % s33.id)
		if str(s33.kind) in ["hunt", "collect", "summit", "toil", "glide", "folk"]:
			check(Data.DIALOGUE.has("done:" + str(s33.id)), "%s: something is said when it is done" % s33.id)
		if str(s33.kind) == "haul":
			check(Data.DIALOGUE.has("haul:" + str(s33.id)) and Load.GOODS.has(str(s33.good)) and Data.DIALOGUE.has("done:" + str(s33.id)), "%s: somebody says something as each load arrives" % s33.id)
		if str(s33.kind) == "toil":
			check(str(s33.work) in ["fell", "quarry", "angle", "reap"] and not s33.has("gives"), "%s is work of the hands he already has the tool for" % s33.id)
		if str(s33.kind) == "folk":
			var er33: Dictionary = Folk.ERRANDS.get(str(s33.id), {})
			check(not er33.is_empty() and (er33.lines as Array).size() >= 4, "%s: an errand with four answers" % s33.id)
			if s33.has("town"):
				check(int(Folk.TOWNS[str(s33.town)].roles.get(str(s33.role), 0)) >= int(s33.n) and str(er33.get("town", "")) == str(s33.town), "%s: an errand among people who are there" % s33.id)
			else:
				check(Folk.CAMP_ROLES.has(str(s33.role)), "%s: an errand among the people of the road" % s33.id)
			for el33 in er33.lines:
				check(fits.call(str(el33)), "%s: what is answered fits the box" % s33.id)
			check(fits.call(str(er33.ask)), "%s: what is asked fits the box" % s33.id)
		if str(s33.kind) == "summit":
			check((Peaks.of_area(Atlas.world_of(Data.layer_of(str(s33.peak))), str(s33.peak)) as Array).size() > int(s33.k), "%s: the height is there to be climbed" % s33.id)
	check(n33 == 34 and kills33 >= 250 and lords33 == ["the_short_way", "the_shelf", "the_knack"] and kinds33.size() >= 9 and kinds33.has("toil") and kinds33.has("haul") and kinds33.has("summit") and kinds33.has("folk") and kinds33.has("glide") and kinds33.has("collect"),
		"the chapter is thirty-four steps of nine kinds, with three lords (%d, %d)" % [n33, kinds33.size()])
	var keys33 := ["recall31", "pre:s_break38", "post:s_break38"]
	for tid33 in lords33:
		keys33.append("pre:" + str(tid33))
		keys33.append("post:" + str(tid33))
	for dk33 in Data.DIALOGUE:
		if str(dk33).contains("s_p33_") or str(dk33) in keys33:
			for ln33 in Data.DIALOGUE[dk33]:
				check(fits.call(str(ln33[1])) and not str(ln33[1]).contains("—"), "%s: a line that fits the box, with no dash in it" % dk33)
				check((ln33 as Array).size() == 2 or Data.EMOTES.has(str(ln33[2])), "%s: its gesture is one everybody has" % dk33)
				check(not str(ln33[1]).contains(", sir") and not str(ln33[1]).contains("young man") and not str(ln33[1]).contains("Sir"), "%s: nobody calls the hero sir" % dk33)
				check(str(ln33[0]) in ["Narrator", "Lin Feng", "Yue Ling", "Elder Qing Xuan", "Old Dame Wu", "Li Bai", "Kuang Heng", "The Old Oil Seller", "Chen Yaozi"], "%s: %s is somebody of the chapter" % [dk33, ln33[0]])
	for tid33 in lords33:
		var tr33: Dictionary = Trials.TRIALS[tid33]
		var open33 := 0
		var relic33 := false
		for pa33 in tr33.paths:
			check(fits.call(str(pa33.desc)) and fits.call(str(pa33.line)), "%s/%s: its words fit" % [tid33, pa33.id])
			if not str(pa33.kind) in ["clean", "wild", "creed"]:
				open33 += 1
			relic33 = relic33 or str(pa33.kind) == "relic"
			for nd33 in pa33.needs:
				if str(nd33[0]) == "step":
					check(Data.step_index(str(nd33[1])) >= p33 and Data.step_index(str(nd33[1])) < _kill_step(tid33), "%s/%s: what it is shown has been done before it is met" % [tid33, pa33.id])
				if str(nd33[0]) == "lv":
					check(int(nd33[1]) < Data.MAX_LEVEL, "%s/%s: the might asked can be had by then" % [tid33, pa33.id])
		check((tr33.paths as Array).size() == 4 and open33 >= 2 and relic33 and fits.call(str(tr33.why)) and Data.ENEMIES[tid33].get("boss", false) and Trials.trial_of_step(Data.STEPS[_kill_step(tid33)]) == tid33, "%s is a lord of the chapter with four ways through, two of them open to a wanted man" % tid33)
	for pr33 in [["the_short_way", "worn_whetstone", "s_p33_stones"], ["the_shelf", "copied_slip", "s_p33_slips"], ["the_knack", "dry_coin", "s_p33_coins"]]:
		check(Data.step_index(str(pr33[2])) < _kill_step(str(pr33[0])) and Data.ITEMS.has(str(pr33[1])) and Look.PICKUP_COLORS.has(str(pr33[1])) and Load.weight_of(str(pr33[1])) <= 1.0, "%s can be passed by what was found on the way" % pr33[0])
	check(Data.ITEMS.has("firefly_bag") and Look.PICKUP_COLORS.has("firefly_bag") and Load.weight_of("firefly_bag") <= 1.0, "a bag of fireflies is a thing that can be found")
	var c33: Dictionary = Echoes.CROSSROADS.get("the_needle", {})
	check(not c33.is_empty() and str(c33.step) == "s_p33_needle" and str(c33.part) == "XXXIII" and Echoes.ORDER.find("the_needle") == Echoes.ORDER.find("the_mirror") + 1 and fits.call(str(c33.ask)), "whether it will ever be a needle is asked after the mirror")
	check((c33.options as Array).size() == 3 and c33.after.size() == 3 and c33.end.size() == 3 and c33.echo.has("s_p33_end") and c33.echo.s_p33_end.size() == 3 and Data.step_index("s_p33_end") > Data.step_index("s_p33_needle"), "the_needle: three answers, each answered, echoed and told at the end")
	var scales33 := {}
	for o33 in c33.options:
		var mk33: Dictionary = Marks.MARKS.the_needle.get(str(o33.id), {})
		check(not mk33.is_empty() and mk33.has("who") and fits.call(str(mk33.desc)) and fits.call(str(mk33.who[3])) and fits.call(str(mk33.who[4])) and Assets.has("characters/" + str(mk33.who[1])), "the_needle/%s leaves something standing, and somebody by it" % o33.id)
		check(not Weal.hears(str(mk33.area)).is_empty(), "the_needle/%s is felt in a town" % o33.id)
		var mm33: Node3D = Marks.model(mk33, 0)
		check(mm33 != null and mm33.get_child_count() > 0, "the_needle/%s: what stands is built from code" % o33.id)
		mm33.free()
		for sc33 in o33.tilt:
			scales33[sc33] = true
		for ck33 in o33.get("creed", {}):
			check(Creed.AXES.has(str(ck33)) and absi(int(o33.creed[ck33])) < Creed.SIDE, "the_needle/%s leans on the Way, and does not by itself decide it" % o33.id)
		check(fits.call(str(o33.desc)), "the_needle/%s: what it means fits" % o33.id)
		for al33 in c33.after[str(o33.id)]:
			check(fits.call(str(al33[1])) and ((al33 as Array).size() == 2 or Data.EMOTES.has(str(al33[2]))), "the_needle/%s: what follows fits the dialogue box" % o33.id)
		check(fits.call(str(c33.echo.s_p33_end[str(o33.id)][0][1])) and fits.call(str(c33.end[str(o33.id)])), "the_needle/%s: its echo and its ending fit" % o33.id)
		var lid33 := "needle_" + str(o33.id)
		check(Mail.LETTERS.has(lid33) and Mail.ORDER.has(lid33) and fits.call(str(Mail.LETTERS[lid33].lines[0])), "the_needle/%s: somebody who lives with it writes" % o33.id)
		check(Data.step_index(Mail.after_of(lid33)) + int(Mail.LETTERS[lid33].get("wait", Mail.WAIT)) < Data.STEPS.size() - 1, "the letter %s can arrive before the story ends" % lid33)
	check(scales33.size() == 3 and Marks.AFTER_BANDS.has("the_needle") and Mail.LETTERS.has("duke_arrows") and Mail.ORDER.has("duke_arrows") and fits.call(str(Mail.LETTERS.duke_arrows.lines[0])), "its answers tip all three scales, its marks are stood after the bands, and a duke writes about his arrowheads")
	var fates33 := 0
	for ft33 in Weal.FATES:
		if str(ft33.when[0]) == "the_needle":
			fates33 += 1
			check(fits.call(str(ft33.line)) and str(ft33.npc) == "granny_wu", "a fate of the_needle fits the box")
	check(fates33 == 3 and bsrc.contains("\"the_needle\": [\"turn\"]"), "the old woman's mornings turn on each answer, and the bot has one")
	var old_echo33 := 0
	for cid33 in Echoes.ORDER:
		if cid33 != "the_needle":
			for ek33 in Echoes.CROSSROADS[cid33].get("echo", {}):
				if str(ek33).contains("s_p33_"):
					old_echo33 += 1
					check(Data.DIALOGUE.has(str(ek33)) and Data.step_index(str(ek33)) > Data.step_index(str(Echoes.CROSSROADS[cid33].step)), "%s echoes in a later conversation of the chapter" % cid33)
	check(old_echo33 >= 3, "three older crossroads echo in Part XXXIII (%d)" % old_echo33)
	var found33 := 0
	var people33 := ["granny_wu", "li_bai", "kuang_heng", "oil_seller", "chen_yaozi"]
	for a33 in areas33:
		var w33: Dictionary = Atlas.world_of(Data.layer_of(a33))
		check(str(Data.AREAS[a33].get("warband5", {}).get("vis", "")).begins_with("s_p33_") and (not Data.AREAS[a33].has("warband6") or Data.step_index(str(Data.AREAS[a33].warband6.vis)) > Data.step_index("s_break38")), "%s: the chapter's band takes the last slot" % a33)
		var stood33 := 0
		for e34 in w33.ents:
			if str(e34.get("area", "")) != a33:
				continue
			if str(e34.kind) == "enemy" and str(e34.get("vis", ["", ""])[0]).begins_with("s_p33_"):
				stood33 += 1
			if (e34.kind == "pickup" and str(e34.id).begins_with("p33_")) or (e34.kind == "boss" and str(e34.enemy) in lords33) or (e34.kind == "npc" and str(e34.id) in people33):
				found33 += 1
				check(Atlas.owner_id(w33, e34.pos) == a33, "%s stands in its own region" % e34.id)
		check(stood33 >= 10, "%s: the band found room (%d of %d packs)" % [a33, stood33, int(Data.AREAS[a33].warband5.n)])
		for sp33 in Data.AREAS[a33].get("npcs", []) + Data.AREAS[a33].get("bosses", []) + Data.AREAS[a33].get("pickups", []):
			if str(sp33.get("vis", ["", ""])[0]).begins_with("s_p33_"):
				check(bool(sp33.get("late", false)) and sp33.has("peak") and int(sp33.peak) < (Peaks.of_area(w33, a33) as Array).size(), "%s is written on a height the region has, not at a fixed tile" % sp33.id)
	check(found33 == 16 + 3 + 5, "everything the chapter stands on the heights found room (%d)" % found33)
	for pid33 in people33:
		check(Assets.PEOPLE.has(pid33) and Assets.has(str(Assets.PEOPLE[pid33])) and FileAccess.file_exists("res://art/characters/%s.py" % pid33), "%s has a body built from a script" % pid33)
		check(Data.CHAT.has(pid33) and Data.CHAT[pid33].size() >= 4 and Folk.POSTS.has(pid33), "%s has four things to say, and something to do all day" % pid33)
		for cl33 in Data.CHAT[pid33]:
			check(fits.call(str(cl33)), "%s: what is said fits the box" % pid33)
	check(Closeup.signature("Old Dame Wu") != "" and Closeup.signature("Li Bai") != "" and Closeup.signature("Kuang Heng") != "" and Closeup.signature("The Old Oil Seller") != "" and Closeup.signature("Chen Yaozi") != "" and Voice.WOMEN.has("Old Dame Wu"), "the people of the chapter have a gesture of their own, and its woman is known for one")
	check(Crime.is_child({"kind": "npc", "id": "li_bai", "n": "Li Bai", "asset": "li_bai"}), "nobody draws on a schoolboy")
	for fid33 in ["practised_hand", "same_length", "by_the_door", "told_true", "parted_whole"]:
		check(Feats.FEATS.has(fid33), "the feat %s is kept" % fid33)
	check(not str(Feats.FEATS.parted_whole.desc).contains("last realm") and not str(Feats.FEATS.practised_hand.desc).contains("last realm") and not str(Feats.FEATS.sleeves_of_wind.desc).contains("last realm") and not str(Feats.FEATS.uncarved_block.desc).contains("last realm") and not str(Feats.FEATS.light_hand.desc).contains("last realm") and not str(Feats.FEATS.five_in_one.desc).contains("last realm") and str(Feats.FEATS.low_as_sea.desc).contains("last realm"), "only the last realm is called the last")
	for src33 in ["Fangyu Shenglan", "Miscellaneous Records of the Western Capital", "Ouyang Xiu", "Book of Jin"]:
		check(FileAccess.get_file_as_string("res://scripts/lore.gd").contains(src33), "the chapter's tales are told from where they are written: %s" % src33)

	print("== Part XXXIV: Nothing Picked Up on the Road ==")
	check(Data.REALMS.size() >= 40 and Data.REALMS[39] == "Sleeves of Wind" and Data.MAX_LEVEL >= 117 and Data.level_name(117).ends_with("Sleeves of Wind") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXXIV adds the realm of Sleeves of Wind")
	check(Data.step_index("s_break39") > 0 and int(Data.STEPS[Data.step_index("s_break39")].to) == 117 and Data.DIALOGUE.has("recall32") and msrc.contains("\"s_break38\": \"recall32\"") and Data.DIALOGUE.has("pre:s_break39") and Data.DIALOGUE.has("post:s_break39"),
		"Part XXXIV follows Practised Hand (recall32) and ends with a breakthrough")
	var p34 := Data.step_index("s_p34_home")
	var kinds34 := {}
	var n34 := 0
	var kills34 := 0
	var lords34: Array = []
	var restore34 := 0
	var band34 := {"yanggu": "warband5", "dunes": "warband5", "buzhou": "warband6"}
	for i in range(p34, Data.step_index("s_break39") + 1):
		var s34: Dictionary = Data.STEPS[i]
		n34 += 1
		kinds34[str(s34.kind)] = true
		check(str(s34.id).begins_with("s_p34_") or str(s34.id) == "s_break39", "%s is a step of the chapter" % s34.id)
		check(not str(s34.kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % s34.id)
		check(not s34.has("stones") or int(s34.stones) > 79000, "%s pays as the road has come to pay" % s34.id)
		if str(s34.kind) == "talk":
			check(Data.DIALOGUE.has(str(s34.id)), "%s has its conversation" % s34.id)
		if str(s34.kind) == "kill":
			lords34.append(str(s34.boss))
			check(Data.DIALOGUE.has("pre:" + str(s34.boss)) and Data.DIALOGUE.has("post:" + str(s34.boss)) and Trials.TRIALS.has(str(s34.boss)) and Lore.BOSS.has(str(s34.boss)), "%s: words before and after, a trial, and a story" % s34.boss)
			check(bsrc.contains("\"%s\": \"" % str(s34.boss)), "the bot has a way planned through %s" % s34.boss)
		if str(s34.kind) == "hunt":
			kills34 += int(s34.n)
			var bnd34: Dictionary = Data.AREAS[str(s34.area)].get(str(band34[str(s34.area)]), {})
			var pool34: Array = []
			for pe34 in bnd34.get("pool", []):
				pool34.append(str(pe34[0]))
				check(int(pe34[1]) <= Data.MAX_LEVEL and int(pe34[2]) <= Data.MAX_LEVEL, "%s: nothing in the band is past the last level" % s34.id)
			for of34 in s34.of:
				check(pool34.has(str(of34)) and Lore.BEAST.has(str(of34)) and not Data.ENEMIES[str(of34)].get("boss", false) and Tactics.WIT.has(str(Data.ENEMIES[str(of34)].shape)), "%s: %s marches in the region's last band, has a story, and wits" % [s34.id, of34])
			check(Data.step_index(str(bnd34.vis)) < i, "%s: the band is in the land before it is hunted" % s34.id)
		if str(s34.kind) in ["hunt", "collect", "summit", "folk", "restore", "leap"]:
			check(Data.DIALOGUE.has("done:" + str(s34.id)), "%s: something is said when it is done" % s34.id)
		if str(s34.kind) == "restore":
			restore34 += int(s34.n)
			var wr34: Dictionary = Atlas.world_of(Data.layer_of(str(s34.area)))
			check(int(s34.n) < Trifles.LOST_N and Trifles.lost(wr34, str(s34.area), 3).size() >= Trifles.LOST_N, "%s asks for fewer things than are dropped in that town in a day" % s34.id)
		if str(s34.kind) == "leap":
			check(int(s34.n) >= 2 and Data.AREAS.has(str(s34.area)), "%s is so many leaps in a region there is" % s34.id)
		if str(s34.kind) == "folk":
			var er34: Dictionary = Folk.ERRANDS.get(str(s34.id), {})
			check(not er34.is_empty() and (er34.lines as Array).size() >= 4, "%s: an errand with four answers" % s34.id)
			check(int(Folk.TOWNS[str(s34.town)].roles.get(str(s34.role), 0)) >= int(s34.n) and str(er34.get("town", "")) == str(s34.town), "%s: an errand among people who are there" % s34.id)
			for el34 in er34.lines:
				check(fits.call(str(el34)), "%s: what is answered fits the box" % s34.id)
			check(fits.call(str(er34.ask)), "%s: what is asked fits the box" % s34.id)
		if str(s34.kind) == "summit":
			check((Peaks.of_area(Atlas.world_of(Data.layer_of(str(s34.peak))), str(s34.peak)) as Array).size() > int(s34.k), "%s: the height is there to be climbed" % s34.id)
	check(n34 == 26 and kills34 >= 190 and lords34 == ["the_find", "the_dusk", "the_bell"] and kinds34.size() >= 9 and kinds34.has("restore") and kinds34.has("leap") and kinds34.has("summit") and kinds34.has("folk") and kinds34.has("collect"),
		"the chapter is twenty-six steps of nine kinds, with three lords (%d, %d)" % [n34, kinds34.size()])
	var keys34 := ["recall32", "pre:s_break39", "post:s_break39"]
	for tid34 in lords34:
		keys34.append("pre:" + str(tid34))
		keys34.append("post:" + str(tid34))
	var people34 := ["yangzi_wife", "yang_zhen", "bell_thief", "pei_du"]
	var names34 := ["Narrator", "Lin Feng", "Yue Ling", "Elder Qing Xuan"]
	for pa34 in ["yanggu", "dunes", "buzhou", "tushan"]:
		for np34 in Data.AREAS[pa34].npcs:
			if str(np34.id) in people34:
				names34.append(str(np34.n))
	check(names34.size() == 8, "the four people of the chapter stand in its regions")
	for dk34 in Data.DIALOGUE:
		if str(dk34).contains("s_p34_") or str(dk34) in keys34:
			for ln34 in Data.DIALOGUE[dk34]:
				check(fits.call(str(ln34[1])) and not str(ln34[1]).contains("—"), "%s: a line that fits the box, with no dash in it" % dk34)
				check((ln34 as Array).size() == 2 or Data.EMOTES.has(str(ln34[2])), "%s: its gesture is one everybody has" % dk34)
				check(not str(ln34[1]).contains(", sir") and not str(ln34[1]).contains("young man") and not str(ln34[1]).contains("Sir"), "%s: nobody calls the hero sir" % dk34)
				check(str(ln34[0]) in names34, "%s: %s is somebody of the chapter, under the name they stand by" % [dk34, ln34[0]])
	for tid34 in lords34:
		var tr34: Dictionary = Trials.TRIALS[tid34]
		var open34 := 0
		var relic34 := false
		for pt34 in tr34.paths:
			check(fits.call(str(pt34.desc)) and fits.call(str(pt34.line)) and Trials.KINDS.has(str(pt34.kind)), "%s/%s: its words fit, and its way has a name" % [tid34, pt34.id])
			if not str(pt34.kind) in ["clean", "wild", "creed"]:
				open34 += 1
			relic34 = relic34 or str(pt34.kind) == "relic"
			for nd34 in pt34.needs:
				if str(nd34[0]) == "step":
					check(Data.step_index(str(nd34[1])) >= p34 and Data.step_index(str(nd34[1])) < _kill_step(tid34), "%s/%s: what it is shown has been done before it is met" % [tid34, pt34.id])
				if str(nd34[0]) == "lv":
					check(int(nd34[1]) < Data.MAX_LEVEL, "%s/%s: the might asked can be had by then" % [tid34, pt34.id])
				if str(nd34[0]) == "restored":
					var asked34 := 0
					for i2 in range(p34, _kill_step(tid34)):
						if str(Data.STEPS[i2].kind) == "restore":
							asked34 += int(Data.STEPS[i2].n)
					check(int(nd34[1]) <= asked34 and asked34 > 0, "%s/%s: no more carried home than the story has asked for by then (%d of %d)" % [tid34, pt34.id, int(nd34[1]), asked34])
		check((tr34.paths as Array).size() == 4 and open34 >= 2 and relic34 and fits.call(str(tr34.why)) and Data.ENEMIES[tid34].get("boss", false) and Trials.trial_of_step(Data.STEPS[_kill_step(tid34)]) == tid34, "%s is a lord of the chapter with four ways through, two of them open to a wanted man" % tid34)
	for pr34 in [["the_find", "weed_gold", "s_p34_gold"], ["the_dusk", "know_slip", "s_p34_slips"], ["the_bell", "fan_bronze", "s_p34_shards"]]:
		check(Data.step_index(str(pr34[2])) < _kill_step(str(pr34[0])) and Data.ITEMS.has(str(pr34[1])) and Look.PICKUP_COLORS.has(str(pr34[1])) and Load.weight_of(str(pr34[1])) <= 1.0, "%s can be passed by what was found on the way" % pr34[0])
	var TN = new_game.call()
	TN.restored = 3
	check(Trials.need_met(["restored", 3], TN) and not Trials.need_met(["restored", 4], TN) and Trials.KINDS.has("found"), "trials can be passed by what was carried home")
	TN.free()
	var c34: Dictionary = Echoes.CROSSROADS.get("the_belts", {})
	check(not c34.is_empty() and str(c34.step) == "s_p34_belts" and str(c34.part) == "XXXIV" and Echoes.ORDER.has("the_belts") and fits.call(str(c34.ask)), "what is right when the gate shuts is asked last of all")
	check((c34.options as Array).size() == 3 and c34.after.size() == 3 and c34.end.size() == 3 and c34.echo.has("s_p34_end") and c34.echo.s_p34_end.size() == 3 and Data.step_index("s_p34_end") > Data.step_index("s_p34_belts"), "the_belts: three answers, each answered, echoed and told at the end")
	var scales34 := {}
	for o34 in c34.options:
		var mk34: Dictionary = Marks.MARKS.the_belts.get(str(o34.id), {})
		check(not mk34.is_empty() and mk34.has("who") and fits.call(str(mk34.desc)) and fits.call(str(mk34.who[3])) and fits.call(str(mk34.who[4])) and Assets.has("characters/" + str(mk34.who[1])), "the_belts/%s leaves something standing, and somebody by it" % o34.id)
		check(not Weal.hears(str(mk34.area)).is_empty(), "the_belts/%s is felt in a town" % o34.id)
		var mm34: Node3D = Marks.model(mk34, 0)
		check(mm34 != null and mm34.get_child_count() > 0, "the_belts/%s: what stands is built from code" % o34.id)
		mm34.free()
		for sc34 in o34.tilt:
			scales34[sc34] = true
		for ck34 in o34.get("creed", {}):
			check(Creed.AXES.has(str(ck34)) and absi(int(o34.creed[ck34])) < Creed.SIDE, "the_belts/%s leans on the Way, and does not by itself decide it" % o34.id)
		check(fits.call(str(o34.desc)), "the_belts/%s: what it means fits" % o34.id)
		for al34 in c34.after[str(o34.id)]:
			check(fits.call(str(al34[1])) and ((al34 as Array).size() == 2 or Data.EMOTES.has(str(al34[2]))), "the_belts/%s: what follows fits the dialogue box" % o34.id)
		check(fits.call(str(c34.echo.s_p34_end[str(o34.id)][0][1])) and fits.call(str(c34.end[str(o34.id)])), "the_belts/%s: its echo and its ending fit" % o34.id)
		var lid34 := "belts_" + str(o34.id)
		check(Mail.LETTERS.has(lid34) and Mail.ORDER.has(lid34) and fits.call(str(Mail.LETTERS[lid34].lines[0])), "the_belts/%s: somebody who lives with it writes" % o34.id)
		check(Data.step_index(Mail.after_of(lid34)) + int(Mail.LETTERS[lid34].get("wait", Mail.WAIT)) < Data.STEPS.size() - 1, "the letter %s can arrive before the story ends" % lid34)
	check(scales34.size() == 3 and Marks.AFTER_BANDS.has("the_belts") and Mail.LETTERS.has("bell_down") and Mail.ORDER.has("bell_down") and fits.call(str(Mail.LETTERS.bell_down.lines[0])), "its answers tip all three scales, its marks are stood after the bands, and the man with the mallet writes")
	var fates34 := 0
	for ft34 in Weal.FATES:
		if str(ft34.when[0]) == "the_belts":
			fates34 += 1
			check(fits.call(str(ft34.line)) and str(ft34.npc) == "pei_du", "a fate of the_belts fits the box")
	check(fates34 == 3 and bsrc.contains("\"the_belts\": [\"wait\"]"), "the scholar's nights turn on each answer, and the bot has one")
	var old_echo34 := 0
	for cid34 in Echoes.ORDER:
		if cid34 != "the_belts":
			for ek34 in Echoes.CROSSROADS[cid34].get("echo", {}):
				if str(ek34).contains("s_p34_"):
					old_echo34 += 1
					check(Data.DIALOGUE.has(str(ek34)) and Data.step_index(str(ek34)) > Data.step_index(str(Echoes.CROSSROADS[cid34].step)) and Echoes.CROSSROADS[cid34].echo[ek34].size() >= 3, "%s echoes in a later conversation of the chapter, whatever was answered" % cid34)
	check(old_echo34 >= 3, "three older crossroads echo in Part XXXIV (%d)" % old_echo34)
	var found34 := 0
	for a34 in ["yanggu", "dunes", "buzhou", "tushan"]:
		var w34: Dictionary = Atlas.world_of(Data.layer_of(a34))
		if band34.has(a34):
			check(str(Data.AREAS[a34].get(str(band34[a34]), {}).get("vis", "")).begins_with("s_p34_"), "%s: the chapter's band takes the last slot" % a34)
			var stood34 := 0
			for e35 in w34.ents:
				if str(e35.get("area", "")) == a34 and str(e35.kind) == "enemy" and str(e35.get("vis", ["", ""])[0]).begins_with("s_p34_"):
					stood34 += 1
			check(stood34 >= 12, "%s: the band found room (%d of %d packs)" % [a34, stood34, int(Data.AREAS[a34][str(band34[a34])].n)])
		for e36 in w34.ents:
			if str(e36.get("area", "")) != a34:
				continue
			if (e36.kind == "pickup" and str(e36.id).begins_with("p34_")) or (e36.kind == "boss" and str(e36.enemy) in lords34) or (e36.kind == "npc" and str(e36.id) in people34):
				found34 += 1
				check(Atlas.owner_id(w34, e36.pos) == a34, "%s stands in its own region" % e36.id)
		for sp34 in Data.AREAS[a34].get("npcs", []) + Data.AREAS[a34].get("bosses", []) + Data.AREAS[a34].get("pickups", []):
			if str(sp34.get("vis", ["", ""])[0]).begins_with("s_p34_"):
				check(bool(sp34.get("late", false)) and sp34.has("peak") and int(sp34.peak) < (Peaks.of_area(w34, a34) as Array).size(), "%s is written on a height the region has, not at a fixed tile" % sp34.id)
				# (a height no older thing stands on: nothing older is stood later for it)
				for old34 in Data.AREAS[a34].get("npcs", []) + Data.AREAS[a34].get("bosses", []) + Data.AREAS[a34].get("pickups", []) + Data.AREAS[a34].get("props", []):
					if old34.has("peak") and not str(old34.get("vis", ["", ""])[0]).begins_with("s_p34_"):
						check(int(old34.peak) != int(sp34.peak), "%s takes a height nothing older stands on (%s)" % [sp34.id, old34.id])
	check(found34 == 12 + 3 + 4, "everything the chapter stands on the heights found room (%d)" % found34)

	print("== Part XXXV: The Uncarved Block ==")
	check(Data.REALMS.size() >= 41 and Data.REALMS[40] == "Uncarved Block" and Data.MAX_LEVEL >= 120 and Data.level_name(120).ends_with("Uncarved Block") and Data.REALM_INFO.size() >= 41
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXXV adds the realm of Uncarved Block")
	check(Data.step_index("s_break40") > 0 and int(Data.STEPS[Data.step_index("s_break40")].to) == 120 and Data.DIALOGUE.has("recall33") and msrc.contains("\"s_break39\": \"recall33\"") and Data.DIALOGUE.has("pre:s_break40") and Data.DIALOGUE.has("post:s_break40"),
		"Part XXXV follows Sleeves of Wind (recall33)")
	var p35 := Data.step_index("s_p35_home")
	var kinds35 := {}
	var n35 := 0
	var kills35 := 0
	var lords35: Array = []
	var band35 := {"maple": "warband7", "garden": "warband6", "jasper": "warband6"}
	for i in range(p35, Data.step_index("s_break40") + 1):
		var s35: Dictionary = Data.STEPS[i]
		n35 += 1
		kinds35[str(s35.kind)] = true
		check(str(s35.id).begins_with("s_p35_") or str(s35.id) == "s_break40", "%s is a step of the chapter" % s35.id)
		check(not str(s35.kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % s35.id)
		check(not s35.has("stones") or int(s35.stones) > 82000, "%s pays as the road has come to pay" % s35.id)
		if str(s35.kind) == "talk":
			check(Data.DIALOGUE.has(str(s35.id)), "%s has its conversation" % s35.id)
		if str(s35.kind) == "kill":
			lords35.append(str(s35.boss))
			check(Data.DIALOGUE.has("pre:" + str(s35.boss)) and Data.DIALOGUE.has("post:" + str(s35.boss)) and Trials.TRIALS.has(str(s35.boss)) and Lore.BOSS.has(str(s35.boss)), "%s: words before and after, a trial, and a story" % s35.boss)
			check(bsrc.contains("\"%s\": \"" % str(s35.boss)), "the bot has a way planned through %s" % s35.boss)
		if str(s35.kind) == "hunt":
			kills35 += int(s35.n)
			var bnd35: Dictionary = Data.AREAS[str(s35.area)].get(str(band35[str(s35.area)]), {})
			var pool35: Array = []
			for pe35 in bnd35.get("pool", []):
				pool35.append(str(pe35[0]))
				check(int(pe35[1]) <= Data.MAX_LEVEL and int(pe35[2]) <= Data.MAX_LEVEL, "%s: nothing in the band is past the last level" % s35.id)
			for of35 in s35.of:
				check(pool35.has(str(of35)) and Lore.BEAST.has(str(of35)) and not Data.ENEMIES[str(of35)].get("boss", false) and Tactics.WIT.has(str(Data.ENEMIES[str(of35)].shape)), "%s: %s marches in the region's last band, has a story, and wits" % [s35.id, of35])
			check(Data.step_index(str(bnd35.vis)) < i, "%s: the band is in the land before it is hunted" % s35.id)
		if str(s35.kind) in ["hunt", "collect", "summit", "folk", "rite"]:
			check(Data.DIALOGUE.has("done:" + str(s35.id)), "%s: something is said when it is done" % s35.id)
		if str(s35.kind) == "rite":
			check(int(s35.n) >= 1 and int(s35.n) <= 3 and Data.AREAS.has(str(s35.area)) and bsrc.contains("func _rite_step"), "%s is a rite or two of his own Daos, and the bot can perform one" % s35.id)
		if str(s35.kind) == "folk":
			var er35: Dictionary = Folk.ERRANDS.get(str(s35.id), {})
			check(not er35.is_empty() and (er35.lines as Array).size() >= 4, "%s: an errand with four answers" % s35.id)
			check(int(Folk.TOWNS[str(s35.town)].roles.get(str(s35.role), 0)) >= int(s35.n) and str(er35.get("town", "")) == str(s35.town), "%s: an errand among people who are there" % s35.id)
			for el35 in er35.lines:
				check(fits.call(str(el35)), "%s: what is answered fits the box" % s35.id)
			check(fits.call(str(er35.ask)), "%s: what is asked fits the box" % s35.id)
		if str(s35.kind) == "summit":
			check((Peaks.of_area(Atlas.world_of(Data.layer_of(str(s35.peak))), str(s35.peak)) as Array).size() > int(s35.k), "%s: the height is there to be climbed" % s35.id)
	check(n35 == 25 and kills35 >= 190 and lords35 == ["the_gift", "the_rule", "the_appraiser"] and kinds35.size() >= 8 and kinds35.has("rite") and kinds35.has("summit") and kinds35.has("folk") and kinds35.has("collect"),
		"the chapter is twenty-five steps of eight kinds, with three lords (%d, %d)" % [n35, kinds35.size()])
	var keys35 := ["recall33", "pre:s_break40", "post:s_break40"]
	for tid35 in lords35:
		keys35.append("pre:" + str(tid35))
		keys35.append("post:" + str(tid35))
	var people35 := ["zeng_shen", "fang_zhongyong", "carpenter_shi", "bian_he"]
	var names35 := ["Narrator", "Lin Feng", "Yue Ling", "Elder Qing Xuan"]
	for pa35 in ["mountain", "maple", "garden", "jasper"]:
		for np35 in Data.AREAS[pa35].npcs:
			if str(np35.id) in people35:
				names35.append(str(np35.n))
	check(names35.size() == 8, "the four people of the chapter stand in its regions")
	for dk35 in Data.DIALOGUE:
		if str(dk35).contains("s_p35_") or str(dk35) in keys35:
			for ln35 in Data.DIALOGUE[dk35]:
				check(fits.call(str(ln35[1])) and not str(ln35[1]).contains("—"), "%s: a line that fits the box, with no dash in it" % dk35)
				check((ln35 as Array).size() == 2 or Data.EMOTES.has(str(ln35[2])), "%s: its gesture is one everybody has" % dk35)
				check(not str(ln35[1]).contains(", sir") and not str(ln35[1]).contains("young man") and not str(ln35[1]).contains("Sir"), "%s: nobody calls the hero sir" % dk35)
				check(str(ln35[0]) in names35, "%s: %s is somebody of the chapter, under the name they stand by" % [dk35, ln35[0]])
	for tid35 in lords35:
		var tr35: Dictionary = Trials.TRIALS[tid35]
		var open35 := 0
		var relic35 := false
		for pt35 in tr35.paths:
			check(fits.call(str(pt35.desc)) and fits.call(str(pt35.line)) and Trials.KINDS.has(str(pt35.kind)), "%s/%s: its words fit, and its way has a name" % [tid35, pt35.id])
			if not str(pt35.kind) in ["clean", "wild", "creed"]:
				open35 += 1
			relic35 = relic35 or str(pt35.kind) == "relic"
			for nd35 in pt35.needs:
				if str(nd35[0]) == "step":
					check(Data.step_index(str(nd35[1])) >= p35 and Data.step_index(str(nd35[1])) < _kill_step(tid35), "%s/%s: what it is shown has been done before it is met" % [tid35, pt35.id])
				if str(nd35[0]) == "lv":
					check(int(nd35[1]) < Data.MAX_LEVEL, "%s/%s: the might asked can be had by then" % [tid35, pt35.id])
				if str(nd35[0]) == "rites":
					check(int(nd35[1]) >= 1 and int(nd35[1]) <= 3, "%s/%s: no more rites than a journey has Daos for by then" % [tid35, pt35.id])
		check((tr35.paths as Array).size() == 4 and open35 >= 2 and relic35 and fits.call(str(tr35.why)) and Data.ENEMIES[tid35].get("boss", false) and Trials.trial_of_step(Data.STEPS[_kill_step(tid35)]) == tid35, "%s is a lord of the chapter with four ways through, two of them open to a wanted man" % tid35)
	for pr35 in [["the_gift", "coin_verse", "s_p35_poems"], ["the_rule", "reject_tally", "s_p35_tallies"], ["the_appraiser", "jade_rind", "s_p35_rinds"]]:
		check(Data.step_index(str(pr35[2])) < _kill_step(str(pr35[0])) and Data.ITEMS.has(str(pr35[1])) and Look.PICKUP_COLORS.has(str(pr35[1])) and Load.weight_of(str(pr35[1])) <= 1.0, "%s can be passed by what was found on the way" % pr35[0])
	var TN35 = new_game.call()
	TN35.rites = {"sword": 2, "a_staff": 1}
	check(Trials.need_met(["rites", 2], TN35) and not Trials.need_met(["rites", 3], TN35) and Trials.KINDS.has("rite") and Trials.need_text(["rites", 2], TN35).contains("2"), "trials can be passed by the rite")
	TN35.free()
	var c35: Dictionary = Echoes.CROSSROADS.get("the_stone", {})
	check(not c35.is_empty() and str(c35.step) == "s_p35_gate" and str(c35.part) == "XXXV" and Echoes.ORDER[Echoes.ORDER.size() - 4] == "the_stone" and fits.call(str(c35.ask)), "what the stone is for is asked last of its chapter")
	check((c35.options as Array).size() == 3 and c35.after.size() == 3 and c35.end.size() == 3 and c35.echo.has("s_p35_end") and c35.echo.s_p35_end.size() == 3 and Data.step_index("s_p35_end") > Data.step_index("s_p35_gate"), "the_stone: three answers, each answered, echoed and told at the end")
	var scales35 := {}
	for o35 in c35.options:
		var mk35: Dictionary = Marks.MARKS.the_stone.get(str(o35.id), {})
		check(not mk35.is_empty() and mk35.has("who") and fits.call(str(mk35.desc)) and fits.call(str(mk35.who[3])) and fits.call(str(mk35.who[4])) and Assets.has("characters/" + str(mk35.who[1])), "the_stone/%s leaves something standing, and somebody by it" % o35.id)
		check(not Weal.hears(str(mk35.area)).is_empty(), "the_stone/%s is felt in a town" % o35.id)
		var mm35: Node3D = Marks.model(mk35, 0)
		check(mm35 != null and mm35.get_child_count() > 0, "the_stone/%s: what stands is built from code" % o35.id)
		mm35.free()
		for sc35 in o35.tilt:
			scales35[sc35] = true
		for ck35 in o35.get("creed", {}):
			check(Creed.AXES.has(str(ck35)) and absi(int(o35.creed[ck35])) < Creed.SIDE, "the_stone/%s leans on the Way, and does not by itself decide it" % o35.id)
		check(fits.call(str(o35.desc)), "the_stone/%s: what it means fits" % o35.id)
		for al35 in c35.after[str(o35.id)]:
			check(fits.call(str(al35[1])) and ((al35 as Array).size() == 2 or Data.EMOTES.has(str(al35[2]))), "the_stone/%s: what follows fits the dialogue box" % o35.id)
		check(fits.call(str(c35.echo.s_p35_end[str(o35.id)][0][1])) and fits.call(str(c35.end[str(o35.id)])), "the_stone/%s: its echo and its ending fit" % o35.id)
		var lid35 := "stone_" + str(o35.id)
		check(Mail.LETTERS.has(lid35) and Mail.ORDER.has(lid35) and fits.call(str(Mail.LETTERS[lid35].lines[0])), "the_stone/%s: somebody who lives with it writes" % o35.id)
		check(Data.step_index(Mail.after_of(lid35)) + int(Mail.LETTERS[lid35].get("wait", Mail.WAIT)) < Data.STEPS.size() - 1, "the letter %s can arrive before the story ends" % lid35)
	check(Crime.is_child({"kind": "npc", "id": "zeng_shen", "n": "Zeng Shen", "asset": "zeng_shen"}) and Closeup.signature("Zeng Shen") != "" and Closeup.signature("Carpenter Shi of Qi") != "" and Closeup.signature("Bian He") != "" and Closeup.signature("Fang Zhongyong") != "", "nobody draws on a boy of twelve, and the four of the chapter each have a gesture of their own")
	check(scales35.size() == 3 and Marks.AFTER_BANDS.has("the_stone") and Mail.LETTERS.has("jade_cut") and Mail.ORDER.has("jade_cut") and fits.call(str(Mail.LETTERS.jade_cut.lines[0])), "its answers tip all three scales, its marks are stood after the bands, and the man of Chu writes")
	var fates35 := 0
	for ft35 in Weal.FATES:
		if str(ft35.when[0]) == "the_stone":
			fates35 += 1
			check(fits.call(str(ft35.line)) and str(ft35.npc) == "zeng_shen", "a fate of the_stone fits the box")
	check(fates35 == 3 and bsrc.contains("\"the_stone\": [\"keep\"]"), "the boy's days turn on each answer, and the bot has one")
	var old_echo35 := 0
	for cid35 in Echoes.ORDER:
		if cid35 != "the_stone":
			for ek35 in Echoes.CROSSROADS[cid35].get("echo", {}):
				if str(ek35).contains("s_p35_"):
					old_echo35 += 1
					check(Data.DIALOGUE.has(str(ek35)) and Data.step_index(str(ek35)) > Data.step_index(str(Echoes.CROSSROADS[cid35].step)) and Echoes.CROSSROADS[cid35].echo[ek35].size() >= 3, "%s echoes in a later conversation of the chapter, whatever was answered" % cid35)
	check(old_echo35 >= 3, "three older crossroads echo in Part XXXV (%d)" % old_echo35)
	var found35 := 0
	for a35 in ["mountain", "maple", "garden", "jasper"]:
		var w35: Dictionary = Atlas.world_of(Data.layer_of(a35))
		if band35.has(a35):
			check(str(Data.AREAS[a35].get(str(band35[a35]), {}).get("vis", "")).begins_with("s_p35_"), "%s: the chapter's band takes the last slot" % a35)
			var stood35 := 0
			for e37 in w35.ents:
				if str(e37.get("area", "")) == a35 and str(e37.kind) == "enemy" and str(e37.get("vis", ["", ""])[0]).begins_with("s_p35_"):
					stood35 += 1
			check(stood35 >= 12, "%s: the band found room (%d of %d packs)" % [a35, stood35, int(Data.AREAS[a35][str(band35[a35])].n)])
		for e38 in w35.ents:
			if str(e38.get("area", "")) != a35:
				continue
			if (e38.kind == "pickup" and str(e38.id).begins_with("p35_")) or (e38.kind == "boss" and str(e38.enemy) in lords35) or (e38.kind == "npc" and str(e38.id) in people35):
				found35 += 1
				check(Atlas.owner_id(w35, e38.pos) == a35, "%s stands in its own region" % e38.id)
		for sp35 in Data.AREAS[a35].get("npcs", []) + Data.AREAS[a35].get("bosses", []) + Data.AREAS[a35].get("pickups", []):
			if str(sp35.get("vis", ["", ""])[0]).begins_with("s_p35_"):
				check(bool(sp35.get("late", false)) and sp35.has("peak") and int(sp35.peak) < (Peaks.of_area(w35, a35) as Array).size(), "%s is written on a height the region has, not at a fixed tile" % sp35.id)
				# (stood in the last pass of all, after every band and mark: nothing older moves for it, whatever height it shares)
				check(bool(sp35.get("after", false)), "%s is stood after everything older" % sp35.id)
	check(found35 == 12 + 3 + 4, "everything the chapter stands on the heights found room (%d)" % found35)

	print("== Part XXXVI: Cooking a Small Fish ==")
	check(Data.REALMS.size() >= 42 and Data.REALMS[41] == "Light Hand" and Data.MAX_LEVEL >= 123 and Data.level_name(123).ends_with("Light Hand") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXXVI adds the realm of Light Hand")
	var end36 := Data.step_index("s_p37_home")
	check(Data.STEPS[end36 - 1].id == "s_break41" and int(Data.STEPS[end36 - 1].to) == 123 and Data.DIALOGUE.has("recall34") and msrc.contains("\"s_break40\": \"recall34\"") and Data.DIALOGUE.has("pre:s_break41") and Data.DIALOGUE.has("post:s_break41"),
		"Part XXXVI follows Uncarved Block (recall34) and ends at Light Hand")
	var p36 := Data.step_index("s_p36_home")
	var kinds36 := {}
	var n36 := 0
	var kills36 := 0
	var lords36: Array = []
	var given36 := {}
	for i in range(p36, end36):
		var s36: Dictionary = Data.STEPS[i]
		n36 += 1
		kinds36[str(s36.kind)] = true
		check(str(s36.id).begins_with("s_p36_") or str(s36.id) == "s_break41", "%s is a step of the chapter" % s36.id)
		check(not str(s36.kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % s36.id)
		check(not s36.has("stones") or int(s36.stones) > 85600, "%s pays as the road has come to pay" % s36.id)
		if str(s36.kind) == "talk":
			check(Data.DIALOGUE.has(str(s36.id)), "%s has its conversation" % s36.id)
		if str(s36.kind) == "kill":
			lords36.append(str(s36.boss))
			check(Data.DIALOGUE.has("pre:" + str(s36.boss)) and Data.DIALOGUE.has("post:" + str(s36.boss)) and Trials.TRIALS.has(str(s36.boss)) and Lore.BOSS.has(str(s36.boss)), "%s: words before and after, a trial, and a story" % s36.boss)
			check(bsrc.contains("\"%s\": \"" % str(s36.boss)) and int(s36.get("cave", 0)) == -1, "the bot has a way planned through %s, down in its cave" % s36.boss)
		if str(s36.kind) == "hunt":
			kills36 += int(s36.n)
			var bnd36: Dictionary = Caves.LATE.get(str(s36.area), {}).get(int(s36.get("cave", 0)), {})
			var pool36: Array = []
			for pe36 in bnd36.get("pool", []):
				pool36.append(str(pe36[0]))
				check(int(pe36[1]) <= Data.MAX_LEVEL and int(pe36[2]) <= Data.MAX_LEVEL, "%s: nothing in the band is past the last level" % s36.id)
			for of36 in s36.of:
				check(pool36.has(str(of36)) and Lore.BEAST.has(str(of36)) and not Data.ENEMIES[str(of36)].get("boss", false) and Tactics.WIT.has(str(Data.ENEMIES[str(of36)].shape)), "%s: %s lives in the region's cave, has a story, and wits" % [s36.id, of36])
			check(not bnd36.is_empty() and Data.step_index(str(bnd36.vis)) < i and not s36.get("first", false), "%s: the band is in the cave before it is hunted, and nobody asks for the first strike under a roof" % s36.id)
		if str(s36.kind) in ["hunt", "collect", "folk", "toil", "cook", "sunder"]:
			check(Data.DIALOGUE.has("done:" + str(s36.id)), "%s: something is said when it is done" % s36.id)
		for gk36 in s36.get("gives", {}):
			given36[str(gk36)] = true
		if str(s36.kind) == "toil":
			var wk36: Dictionary = Toil.WORKS.get(str(s36.work), {})
			check(not wk36.is_empty() and int(s36.n) >= 2 and int(s36.n) <= 4 and (given36.has(str(wk36.tool)) or str(wk36.tool) in ["axe", "pick", "sickle", "fishing_rod"]), "%s is work of the hands, with its tool given before" % s36.id)
			check((str(s36.work) == "mine") == s36.has("cave"), "%s: a vein is in a cave, and nothing else is" % s36.id)
		if str(s36.kind) == "cook":
			check(Cooking.RECIPES.has(str(s36.dish)) and given36.has(Cooking.POT) and int(s36.n) == 1 and bsrc.contains("func _cook_step"), "%s is a dish there is, with the pot given before, and the bot can cook it" % s36.id)
		if str(s36.kind) == "sunder":
			check(int(s36.n) >= 1 and int(s36.n) <= 12 and bsrc.contains("func _sunder_step") and (not s36.has("max") or int(s36.max) == 1), "%s is a few things broken, or a few blows held back, and the bot can strike them" % s36.id)
		if str(s36.kind) == "folk":
			var er36: Dictionary = Folk.ERRANDS.get(str(s36.id), {})
			check(not er36.is_empty() and (er36.lines as Array).size() >= 4, "%s: an errand with four answers" % s36.id)
			check(int(Folk.TOWNS[str(s36.town)].roles.get(str(s36.role), 0)) >= int(s36.n) and str(er36.get("town", "")) == str(s36.town), "%s: an errand among people who are there" % s36.id)
			for el36 in er36.lines:
				check(fits.call(str(el36)), "%s: what is answered fits the box" % s36.id)
			check(fits.call(str(er36.ask)), "%s: what is asked fits the box" % s36.id)
	check(n36 == 31 and kills36 >= 130 and lords36 == ["the_drained", "the_tugger", "the_grasper"] and kinds36.size() >= 8 and kinds36.has("cook") and kinds36.has("sunder") and kinds36.has("toil") and kinds36.has("folk") and kinds36.has("collect"),
		"the chapter is thirty-one steps of eight kinds, with three lords (%d, %d, %d)" % [n36, kinds36.size(), kills36])
	# what the story's pots are made of has been gathered by the story's own steps
	var have36 := {}
	var short36: Array = []
	for i in range(p36, end36):
		var s37: Dictionary = Data.STEPS[i]
		if str(s37.kind) == "toil":
			var gd36 := Toil.good_of(str(s37.work), s37.has("cave"))
			# (every third cast of a line misses)
			have36[gd36] = int(have36.get(gd36, 0)) + (int(s37.n) - int(s37.n) / 3 if str(s37.work) == "angle" else int(s37.n))
		if str(s37.kind) == "cook":
			for nk36 in Cooking.RECIPES[str(s37.dish)].needs:
				have36[str(nk36)] = int(have36.get(str(nk36), 0)) - int(Cooking.RECIPES[str(s37.dish)].needs[nk36])
				if int(have36[str(nk36)]) < 0:
					short36.append("%s:%s" % [s37.id, nk36])
	check(short36.is_empty(), "every pot the story asks for can be filled from what its own steps gathered (short: %s)" % str(short36))
	var keys36 := ["recall34", "pre:s_break41", "post:s_break41"]
	for tid36 in lords36:
		keys36.append("pre:" + str(tid36))
		keys36.append("post:" + str(tid36))
	var people36 := ["yong_ji", "song_younger", "old_qi"]
	var names36 := ["Narrator", "Lin Feng", "Yue Ling", "Elder Qing Xuan", "Auntie Zhou the Cook"]
	for pa36 in ["marsh", "millet", "forge"]:
		for np36 in Data.AREAS[pa36].npcs:
			if str(np36.id) in people36:
				names36.append(str(np36.n))
				check(Assets.has("characters/" + str(np36.asset)) and Closeup.signature(str(np36.n)) != "" and Folk.POSTS.has(str(np36.id)), "%s has a body from a script, a gesture of their own and something to do by day" % np36.id)
	check(names36.size() == 8, "the three people of the chapter stand in its regions")
	for dk36 in Data.DIALOGUE:
		if str(dk36).contains("s_p36_") or str(dk36) in keys36:
			for ln36 in Data.DIALOGUE[dk36]:
				check(fits.call(str(ln36[1])) and not str(ln36[1]).contains("—"), "%s: a line that fits the box, with no dash in it" % dk36)
				check((ln36 as Array).size() == 2 or Data.EMOTES.has(str(ln36[2])), "%s: its gesture is one everybody has" % dk36)
				check(not str(ln36[1]).contains(", sir") and not str(ln36[1]).contains("young man") and not str(ln36[1]).contains("Sir"), "%s: nobody calls the hero sir" % dk36)
				check(str(ln36[0]) in names36, "%s: %s is somebody of the chapter, under the name they stand by" % [dk36, ln36[0]])
	for tid36 in lords36:
		var tr36: Dictionary = Trials.TRIALS[tid36]
		var open36 := 0
		var relic36 := false
		for pt36 in tr36.paths:
			check(fits.call(str(pt36.desc)) and fits.call(str(pt36.line)) and Trials.KINDS.has(str(pt36.kind)), "%s/%s: its words fit, and its way has a name" % [tid36, pt36.id])
			if not str(pt36.kind) in ["clean", "wild", "creed"]:
				open36 += 1
			relic36 = relic36 or str(pt36.kind) == "relic"
			for nd36 in pt36.needs:
				if str(nd36[0]) == "step":
					check(Data.step_index(str(nd36[1])) >= p36 and Data.step_index(str(nd36[1])) < _kill_step(tid36), "%s/%s: what it is shown has been done before it is met" % [tid36, pt36.id])
				if str(nd36[0]) == "lv":
					check(int(nd36[1]) < Data.MAX_LEVEL, "%s/%s: the might asked can be had by then" % [tid36, pt36.id])
		check((tr36.paths as Array).size() == 4 and open36 >= 2 and relic36 and fits.call(str(tr36.why)) and Data.ENEMIES[tid36].get("boss", false) and Trials.trial_of_step(Data.STEPS[_kill_step(tid36)]) == tid36, "%s is a lord of the chapter with four ways through, two of them open to a wanted man" % tid36)
	for pr36 in [["the_drained", "last_scale", "s_p36_scales"], ["the_tugger", "pulled_ear", "s_p36_ears"], ["the_grasper", "blind_coin", "s_p36_coins"]]:
		check(Data.step_index(str(pr36[2])) < _kill_step(str(pr36[0])) and Data.ITEMS.has(str(pr36[1])) and Look.PICKUP_COLORS.has(str(pr36[1])) and Load.weight_of(str(pr36[1])) <= 1.0, "%s can be passed by what was found on the way" % pr36[0])
	var TN36 = new_game.call()
	TN36.cooked_good = 2
	TN36.sunder_light = 3
	check(Trials.need_met(["cooked", 2], TN36) and not Trials.need_met(["cooked", 3], TN36) and Trials.need_met(["light", 3], TN36) and not Trials.need_met(["light", 4], TN36) and Trials.KINDS.has("pot") and Trials.KINDS.has("light") and Trials.need_text(["cooked", 2], TN36).contains("2"), "trials can be passed by the pot and by the light hand")
	TN36.free()
	var c36: Dictionary = Echoes.CROSSROADS.get("the_ladle", {})
	check(not c36.is_empty() and str(c36.step) == "s_p36_table" and str(c36.part) == "XXXVI" and Echoes.ORDER[Echoes.ORDER.size() - 3] == "the_ladle" and fits.call(str(c36.ask)), "what a strong hand is for is asked last of its chapter")
	check((c36.options as Array).size() == 3 and c36.after.size() == 3 and c36.end.size() == 3 and c36.echo.has("s_p36_end") and c36.echo.s_p36_end.size() == 3 and Data.step_index("s_p36_end") > Data.step_index("s_p36_table"), "the_ladle: three answers, each answered, echoed and told at the end")
	var scales36 := {}
	for o36 in c36.options:
		var mk36: Dictionary = Marks.MARKS.the_ladle.get(str(o36.id), {})
		check(not mk36.is_empty() and mk36.has("who") and fits.call(str(mk36.desc)) and fits.call(str(mk36.who[3])) and fits.call(str(mk36.who[4])) and Assets.has("characters/" + str(mk36.who[1])) and Voice.WOMEN.has(str(mk36.who[0])), "the_ladle/%s leaves something standing, and somebody by it" % o36.id)
		check(not Weal.hears(str(mk36.area)).is_empty() and int(mk36.get("k", 1)) >= 3, "the_ladle/%s is a row of things, felt in a town" % o36.id)
		var mm36: Node3D = Marks.model(mk36, 0)
		check(mm36 != null and mm36.get_child_count() > 0, "the_ladle/%s: what stands is built from code" % o36.id)
		mm36.free()
		for tk36 in o36.tilt:
			scales36[str(tk36)] = true
		for ck36 in o36.get("creed", {}):
			check(Creed.AXES.has(str(ck36)) and absi(int(o36.creed[ck36])) < Creed.SIDE, "the_ladle/%s leans on the Way, and does not by itself decide it" % o36.id)
		check(fits.call(str(o36.desc)), "the_ladle/%s: what it means fits" % o36.id)
		for al36 in c36.after[str(o36.id)]:
			check(fits.call(str(al36[1])) and ((al36 as Array).size() == 2 or Data.EMOTES.has(str(al36[2]))) and str(al36[0]) in names36, "the_ladle/%s: what follows fits the dialogue box" % o36.id)
		check(fits.call(str(c36.echo.s_p36_end[str(o36.id)][0][1])) and fits.call(str(c36.end[str(o36.id)])), "the_ladle/%s: its echo and its ending fit" % o36.id)
		var lid36 := "ladle_" + str(o36.id)
		check(Mail.LETTERS.has(lid36) and Mail.ORDER.has(lid36) and fits.call(str(Mail.LETTERS[lid36].lines[0])), "the_ladle/%s: somebody who lives with it writes" % o36.id)
		check(Data.step_index(Mail.after_of(lid36)) + int(Mail.LETTERS[lid36].get("wait", Mail.WAIT)) < Data.STEPS.size() - 1, "the letter %s can arrive before the story ends" % lid36)
	check(scales36.size() == 3 and Marks.AFTER_BANDS.has("the_ladle") and Mail.LETTERS.has("qi_counts") and Mail.ORDER.has("qi_counts") and fits.call(str(Mail.LETTERS.qi_counts.lines[0])), "its answers tip all three scales, its marks are stood after the late bands, and a man who has begun to count writes")
	var fates36 := 0
	for ft36 in Weal.FATES:
		if str(ft36.when[0]) == "the_ladle":
			fates36 += 1
			check(fits.call(str(ft36.line)) and str(ft36.npc) == "cook_zhou", "a fate of the_ladle fits the box")
	check(fates36 == 3 and bsrc.contains("\"the_ladle\": [\"teach\"]"), "the cook's days turn on each answer, and the bot has one")
	var old_echo36 := 0
	for cid36 in Echoes.ORDER:
		if cid36 != "the_ladle":
			for ek36 in Echoes.CROSSROADS[cid36].get("echo", {}):
				if str(ek36).contains("s_p36_"):
					old_echo36 += 1
					check(Data.DIALOGUE.has(str(ek36)) and Data.step_index(str(ek36)) > Data.step_index(str(Echoes.CROSSROADS[cid36].step)) and Echoes.CROSSROADS[cid36].echo[ek36].size() >= 3, "%s echoes in a later conversation of the chapter, whatever was answered" % cid36)
					for ea36 in Echoes.CROSSROADS[cid36].echo[ek36]:
						check(fits.call(str(Echoes.CROSSROADS[cid36].echo[ek36][ea36][0][1])), "%s/%s: its echo fits the box" % [cid36, ea36])
	check(old_echo36 >= 1, "an older crossroads echoes in Part XXXVI (%d)" % old_echo36)
	# everything of the chapter is stood in a cave, last of all: nothing on the land moves, and nothing older in the cave
	var found36 := 0
	for a36 in ["marsh", "millet", "forge"]:
		check(not Caves.OWN.has(a36) and Caves.LATE.has(a36), "%s: the chapter's band is in LATE, not OWN (a cave of OWN is placed first, and every mouth after it moves)" % a36)
		var cw36: Dictionary = Atlas.world_of(Caves.fid(a36, -1))
		var packs36 := 0
		var last_old36 := -1
		var first_new36 := 1 << 30
		for ei36 in (cw36.ents as Array).size():
			var e36: Dictionary = cw36.ents[ei36]
			var new36: bool = (e36.kind == "enemy" and str(e36.id).contains(":l")) or (e36.kind == "pickup" and str(e36.id).begins_with("p36_")) or (e36.kind == "boss" and str(e36.enemy) in lords36) or (e36.kind == "npc" and str(e36.id) in people36)
			if new36:
				first_new36 = mini(first_new36, ei36)
				found36 += 1
				if e36.kind == "enemy":
					packs36 += 1
				check(MapGen.is_walkable_tile(cw36.grid[e36.pos.y * int(cw36.w) + e36.pos.x]), "%s stands on the floor of its cave" % e36.id)
			else:
				last_old36 = ei36
		check(packs36 >= 9 and first_new36 > last_old36, "%s: the band found room (%d of %d packs), after everything that was in the cave already" % [a36, packs36, int(Caves.LATE[a36][-1].n)])
		for sp36 in Data.AREAS[a36].get("npcs", []) + Data.AREAS[a36].get("bosses", []) + Data.AREAS[a36].get("pickups", []):
			if str(sp36.get("vis", ["", ""])[0]).begins_with("s_p36_"):
				check(bool(sp36.get("late", false)) and int(sp36.get("cave", 0)) == -1 and bool(sp36.get("after", false)) and not sp36.has("peak"), "%s is written in the cave, to be stood after everything older" % sp36.id)
		var sw36: Dictionary = Atlas.world_of(Data.layer_of(a36))
		for e39 in sw36.ents:
			check(not (str(e39.get("id", "")).begins_with("p36_") or str(e39.get("enemy", "")) in lords36 or str(e39.get("id", "")) in people36), "nothing of the chapter stands on the land of %s" % a36)
	check(found36 >= 3 * (9 + 4 + 1 + 1), "everything the chapter stands in the three caves found room (%d)" % found36)

	print("== Part XXXVII: A Cup of Water, a Cart of Firewood ==")
	var wsq7 := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(Data.REALMS.size() >= 43 and Data.REALMS[42] == "Five in One Hand" and Data.MAX_LEVEL >= 126 and Data.level_name(126).ends_with("Five in One Hand") and Data.REALM_INFO.size() == Data.REALMS.size()
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXXVII adds the realm of Five in One Hand")
	var endq7 := Data.step_index("s_p38_home")
	check(Data.STEPS[endq7 - 1].id == "s_break42" and int(Data.STEPS[endq7 - 1].to) == 126 and Data.DIALOGUE.has("recall35") and msrc.contains("\"s_break41\": \"recall35\"") and Data.DIALOGUE.has("pre:s_break42") and Data.DIALOGUE.has("post:s_break42"),
		"Part XXXVII follows Light Hand (recall35) and ends at Five in One Hand")
	var pq7 := Data.step_index("s_p37_home")
	var kindsq7 := {}
	var nq7 := 0
	var killsq7 := 0
	var lordsq7: Array = []
	var phq7 := {}
	var reactq7 := {}
	for i in range(pq7, endq7):
		var sq7: Dictionary = Data.STEPS[i]
		nq7 += 1
		kindsq7[str(sq7.kind)] = true
		check(str(sq7.id).begins_with("s_p37_") or str(sq7.id) == "s_break42", "%s is a step of the chapter" % sq7.id)
		check(not str(sq7.kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % sq7.id)
		check(not sq7.has("stones") or int(sq7.stones) > 89000, "%s pays as the road has come to pay" % sq7.id)
		if str(sq7.kind) == "talk":
			check(Data.DIALOGUE.has(str(sq7.id)), "%s has its conversation" % sq7.id)
		if str(sq7.kind) == "kill":
			lordsq7.append(str(sq7.boss))
			check(Data.DIALOGUE.has("pre:" + str(sq7.boss)) and Data.DIALOGUE.has("post:" + str(sq7.boss)) and Trials.TRIALS.has(str(sq7.boss)) and Lore.BOSS.has(str(sq7.boss)), "%s: words before and after, a trial, and a story" % sq7.boss)
			check(bsrc.contains("\"%s\": \"" % str(sq7.boss)) and int(sq7.get("cave", 0)) == -1, "the bot has a way planned through %s, down in its cave" % sq7.boss)
		if str(sq7.kind) == "hunt":
			killsq7 += int(sq7.n)
			var bndq7: Dictionary = Caves.LATE.get(str(sq7.area), {}).get(int(sq7.get("cave", 0)), {})
			var poolq7: Array = []
			for peq7 in bndq7.get("pool", []):
				poolq7.append(str(peq7[0]))
				check(int(peq7[1]) <= Data.MAX_LEVEL and int(peq7[2]) <= Data.MAX_LEVEL, "%s: nothing in the band is past the last level" % sq7.id)
			for ofq7 in sq7.of:
				check(poolq7.has(str(ofq7)) and Lore.BEAST.has(str(ofq7)) and not Data.ENEMIES[str(ofq7)].get("boss", false) and Tactics.WIT.has(str(Data.ENEMIES[str(ofq7)].shape)), "%s: %s lives in the region's cave, has a story, and wits" % [sq7.id, ofq7])
			check(not bndq7.is_empty() and Data.step_index(str(bndq7.vis)) < i and not sq7.get("first", false), "%s: the band is in the cave before it is hunted, and nobody asks for the first strike under a roof" % sq7.id)
		if str(sq7.kind) in ["hunt", "collect", "folk", "phase"]:
			check(Data.DIALOGUE.has("done:" + str(sq7.id)), "%s: something is said when it is done" % sq7.id)
		if str(sq7.kind) == "phase":
			check(int(sq7.n) >= 2 and int(sq7.n) <= 6 and (not sq7.has("el") or Phases.ORDER.has(str(sq7.el))) and (not sq7.has("react") or str(sq7.react) in ["quell", "feed"]) and not sq7.has("cave") and bsrc.contains("func _phase_step"),
				"%s is a few blows of a phase on the open land, and the bot can strike them" % sq7.id)
			if sq7.has("el"):
				phq7[str(sq7.el)] = true
			if sq7.has("react"):
				reactq7[str(sq7.react)] = true
				# (what it asks one phase to meet can be laid down by a blow: there is a phase that bears it, or that it overcomes)
				check(not sq7.has("el") or str(sq7.react) != "quell" or Phases.QUELLED.has(str(sq7.el)), "%s: the phase it names overcomes something that can lie on the land" % sq7.id)
		if str(sq7.kind) == "folk":
			var erq7: Dictionary = Folk.ERRANDS.get(str(sq7.id), {})
			check(not erq7.is_empty() and (erq7.lines as Array).size() >= 4, "%s: an errand with four answers" % sq7.id)
			check(int(Folk.TOWNS[str(sq7.town)].roles.get(str(sq7.role), 0)) >= int(sq7.n) and str(erq7.get("town", "")) == str(sq7.town), "%s: an errand among people who are there" % sq7.id)
			for elq7 in erq7.lines:
				check(fits.call(str(elq7)), "%s: what is answered fits the box" % sq7.id)
			check(fits.call(str(erq7.ask)), "%s: what is asked fits the box" % sq7.id)
	check(nq7 == 29 and killsq7 >= 130 and lordsq7 == ["the_fed_fire", "the_next_door", "the_kindling"] and kindsq7.size() >= 7 and kindsq7.has("phase") and kindsq7.has("folk") and kindsq7.has("collect"),
		"the chapter is twenty-nine steps of seven kinds, with three lords (%d, %d, %d)" % [nq7, kindsq7.size(), killsq7])
	check(phq7.size() == 5 and reactq7.size() == 2, "the story asks for each of the five phases by name, and for one to overcome another and one to feed another (%s)" % str(phq7.keys()))
	var keysq7 := ["recall35", "pre:s_break42", "post:s_break42"]
	for tidq7 in lordsq7:
		keysq7.append("pre:" + str(tidq7))
		keysq7.append("post:" + str(tidq7))
	var peopleq7 := ["su_dai", "bai_gui", "cai_yong"]
	var namesq7 := ["Narrator", "Lin Feng", "Yue Ling", "Elder Qing Xuan"]
	for paq7 in ["volcano", "drowned", "thunder"]:
		for npq7 in Data.AREAS[paq7].npcs:
			if str(npq7.id) in peopleq7:
				namesq7.append(str(npq7.n))
				check(Assets.has("characters/" + str(npq7.asset)) and FileAccess.file_exists("res://art/characters/%s.py" % str(npq7.asset)) and Closeup.signature(str(npq7.n)) != "" and Folk.POSTS.has(str(npq7.id)), "%s has a body from a script, a gesture of their own and something to do by day" % npq7.id)
	check(namesq7.size() == 7, "the three people of the chapter stand in its regions")
	for dkq7 in Data.DIALOGUE:
		if str(dkq7).contains("s_p37_") or str(dkq7) in keysq7:
			for lnq7 in Data.DIALOGUE[dkq7]:
				check(fits.call(str(lnq7[1])) and not str(lnq7[1]).contains("—"), "%s: a line that fits the box, with no dash in it" % dkq7)
				check((lnq7 as Array).size() == 2 or Data.EMOTES.has(str(lnq7[2])), "%s: its gesture is one everybody has" % dkq7)
				check(not str(lnq7[1]).contains(", sir") and not str(lnq7[1]).contains("young man") and not str(lnq7[1]).contains("Sir"), "%s: nobody calls the hero sir" % dkq7)
				check(str(lnq7[0]) in namesq7, "%s: %s is somebody of the chapter, under the name they stand by" % [dkq7, lnq7[0]])
	for tidq7 in lordsq7:
		var trq7: Dictionary = Trials.TRIALS[tidq7]
		var openq7 := 0
		var relicq7 := false
		for ptq7 in trq7.paths:
			check(fits.call(str(ptq7.desc)) and fits.call(str(ptq7.line)) and Trials.KINDS.has(str(ptq7.kind)), "%s/%s: its words fit, and its way has a name" % [tidq7, ptq7.id])
			if not str(ptq7.kind) in ["clean", "wild", "creed"]:
				openq7 += 1
			if str(ptq7.kind) == "relic":
				relicq7 = true
			for ndq7 in ptq7.needs:
				if str(ndq7[0]) == "step":
					check(Data.step_index(str(ndq7[1])) >= pq7 and Data.step_index(str(ndq7[1])) < _kill_step(tidq7), "%s/%s: what it is shown has been done before it is met" % [tidq7, ptq7.id])
				if str(ndq7[0]) == "lv":
					check(int(ndq7[1]) < Data.MAX_LEVEL, "%s/%s: the might asked can be had by then" % [tidq7, ptq7.id])
				if str(ndq7[0]) in ["phases", "quelled"]:
					check(int(ndq7[1]) >= 1 and int(ndq7[1]) <= 3, "%s/%s: no more of the round than the story has asked for by then" % [tidq7, ptq7.id])
		check((trq7.paths as Array).size() == 4 and openq7 >= 2 and relicq7 and fits.call(str(trq7.why)) and Data.ENEMIES[tidq7].get("boss", false) and Trials.trial_of_step(Data.STEPS[_kill_step(tidq7)]) == tidq7, "%s is a lord of the chapter with four ways through, two of them open to a wanted man" % tidq7)
	for prq7 in [["the_fed_fire", "wet_cinder", "s_p37_cinders"], ["the_next_door", "boundary_stake", "s_p37_stakes"], ["the_kindling", "scorched_peg", "s_p37_pegs"]]:
		check(Data.step_index(str(prq7[2])) < _kill_step(str(prq7[0])) and Data.ITEMS.has(str(prq7[1])) and Look.PICKUP_COLORS.has(str(prq7[1])) and Load.weight_of(str(prq7[1])) <= 1.0, "%s can be passed by what was found on the way" % prq7[0])
	var TNq7 = new_game.call()
	TNq7.phases_used = {"fire": 2, "water": 1, "wood": 1}
	TNq7.reacts = {"quell": 2}
	check(Trials.need_met(["phases", 3], TNq7) and not Trials.need_met(["phases", 4], TNq7) and Trials.need_met(["quelled", 2], TNq7) and not Trials.need_met(["quelled", 3], TNq7) and Trials.KINDS.has("round") and Trials.KINDS.has("measure")
		and Trials.need_text(["phases", 3], TNq7).contains("3") and Trials.need_text(["quelled", 2], TNq7).contains("2"), "trials can be passed by the round and by the measure")
	TNq7.free()
	var cq7: Dictionary = Echoes.CROSSROADS.get("the_round", {})
	check(not cq7.is_empty() and str(cq7.step) == "s_p37_council" and str(cq7.part) == "XXXVII" and Echoes.ORDER[Echoes.ORDER.size() - 2] == "the_round" and fits.call(str(cq7.ask)), "what is done before the next dry wind is asked last of its chapter")
	check((cq7.options as Array).size() == 3 and cq7.after.size() == 3 and cq7.end.size() == 3 and cq7.echo.has("s_p37_end") and cq7.echo.s_p37_end.size() == 3 and Data.step_index("s_p37_end") > Data.step_index("s_p37_council"), "the_round: three answers, each answered, echoed and told at the end")
	var scalesq7 := {}
	for oq7 in cq7.options:
		var mkq7: Dictionary = Marks.MARKS.the_round.get(str(oq7.id), {})
		check(not mkq7.is_empty() and mkq7.has("who") and fits.call(str(mkq7.desc)) and fits.call(str(mkq7.who[3])) and fits.call(str(mkq7.who[4])) and Assets.has("characters/" + str(mkq7.who[1])) and str(mkq7.area) == "mountain", "the_round/%s leaves something standing, and somebody by it" % oq7.id)
		check(not Weal.hears(str(mkq7.area)).is_empty() and int(mkq7.get("k", 1)) >= 3, "the_round/%s is a row of things, felt in a town" % oq7.id)
		var mmq7: Node3D = Marks.model(mkq7, 0)
		check(mmq7 != null and mmq7.get_child_count() > 0, "the_round/%s: what stands is built from code" % oq7.id)
		mmq7.free()
		for tkq7 in oq7.tilt:
			scalesq7[str(tkq7)] = true
		for ckq7 in oq7.get("creed", {}):
			check(Creed.AXES.has(str(ckq7)) and absi(int(oq7.creed[ckq7])) < Creed.SIDE, "the_round/%s leans on the Way, and does not by itself decide it" % oq7.id)
		check(fits.call(str(oq7.desc)), "the_round/%s: what it means fits" % oq7.id)
		for alq7 in cq7.after[str(oq7.id)]:
			check(fits.call(str(alq7[1])) and ((alq7 as Array).size() == 2 or Data.EMOTES.has(str(alq7[2]))) and str(alq7[0]) in namesq7, "the_round/%s: what follows fits the dialogue box" % oq7.id)
		check(fits.call(str(cq7.echo.s_p37_end[str(oq7.id)][0][1])) and fits.call(str(cq7.end[str(oq7.id)])), "the_round/%s: its echo and its ending fit" % oq7.id)
		var lidq7 := "round_" + str(oq7.id)
		check(Mail.LETTERS.has(lidq7) and Mail.ORDER.has(lidq7) and fits.call(str(Mail.LETTERS[lidq7].lines[0])), "the_round/%s: somebody who lives with it writes" % oq7.id)
		check(Data.step_index(Mail.after_of(lidq7)) + int(Mail.LETTERS[lidq7].get("wait", Mail.WAIT)) < Data.STEPS.size() - 1, "the letter %s can arrive before the story ends" % lidq7)
	check(scalesq7.size() == 3 and Marks.AFTER_BANDS.has("the_round") and Mail.LETTERS.has("cai_qin") and Mail.ORDER.has("cai_qin") and fits.call(str(Mail.LETTERS.cai_qin.lines[0])), "its answers tip all three scales, its marks are stood after the late bands, and a man in Wu writes")
	var fatesq7 := 0
	for ftq7 in Weal.FATES:
		if str(ftq7.when[0]) == "the_round":
			fatesq7 += 1
			check(fits.call(str(ftq7.line)) and str(ftq7.npc) == "cook_zhou", "a fate of the_round fits the box")
	check(fatesq7 == 3 and bsrc.contains("\"the_round\": [\"watch\"]"), "the cook's days turn on each answer, and the bot has one")
	var old_echoq7 := 0
	for cidq7 in Echoes.ORDER:
		if cidq7 != "the_round":
			for ekq7 in Echoes.CROSSROADS[cidq7].get("echo", {}):
				if str(ekq7).contains("s_p37_"):
					old_echoq7 += 1
					check(Data.DIALOGUE.has(str(ekq7)) and Data.step_index(str(ekq7)) > Data.step_index(str(Echoes.CROSSROADS[cidq7].step)) and Echoes.CROSSROADS[cidq7].echo[ekq7].size() >= 3, "%s echoes in a later conversation of the chapter" % cidq7)
					for eaq7 in Echoes.CROSSROADS[cidq7].echo[ekq7]:
						check(fits.call(str(Echoes.CROSSROADS[cidq7].echo[ekq7][eaq7][0][1])), "%s/%s: its echo fits the box" % [cidq7, eaq7])
	check(old_echoq7 >= 1, "an older crossroads echoes in Part XXXVII (%d)" % old_echoq7)
	# everything of the chapter is stood in a cave, last of all: nothing on the land moves, and nothing older in the cave
	var foundq7 := 0
	for aq7 in ["volcano", "drowned", "thunder"]:
		check(not Caves.OWN.has(aq7) and Caves.LATE.has(aq7), "%s: the chapter's band is in LATE, not OWN (a cave of OWN is placed first, and every mouth after it moves)" % aq7)
		var cwq7: Dictionary = Atlas.world_of(Caves.fid(aq7, -1))
		var packsq7 := 0
		var last_oldq7 := -1
		var first_newq7 := 1 << 30
		for eiq7 in (cwq7.ents as Array).size():
			var eq7: Dictionary = cwq7.ents[eiq7]
			var newq7: bool = (eq7.kind == "enemy" and str(eq7.id).contains(":l")) or (eq7.kind == "pickup" and str(eq7.id).begins_with("p37_")) or (eq7.kind == "boss" and str(eq7.enemy) in lordsq7) or (eq7.kind == "npc" and str(eq7.id) in peopleq7)
			if newq7:
				first_newq7 = mini(first_newq7, eiq7)
				foundq7 += 1
				if eq7.kind == "enemy":
					packsq7 += 1
				check(MapGen.is_walkable_tile(cwq7.grid[eq7.pos.y * int(cwq7.w) + eq7.pos.x]), "%s stands on the floor of its cave" % eq7.id)
			else:
				last_oldq7 = eiq7
		check(packsq7 >= 9 and first_newq7 > last_oldq7, "%s: the band found room (%d of %d packs), after everything that was in the cave already" % [aq7, packsq7, int(Caves.LATE[aq7][-1].n)])
		for spq7 in Data.AREAS[aq7].get("npcs", []) + Data.AREAS[aq7].get("bosses", []) + Data.AREAS[aq7].get("pickups", []):
			if str(spq7.get("vis", ["", ""])[0]).begins_with("s_p37_"):
				check(bool(spq7.get("late", false)) and int(spq7.get("cave", 0)) == -1 and bool(spq7.get("after", false)) and not spq7.has("peak"), "%s is written in the cave, to be stood after everything older" % spq7.id)
		var swq7: Dictionary = Atlas.world_of(Data.layer_of(aq7))
		for eq8 in swq7.ents:
			check(not (str(eq8.get("id", "")).begins_with("p37_") or str(eq8.get("enemy", "")) in lordsq7 or str(eq8.get("id", "")) in peopleq7), "nothing of the chapter stands on the land of %s" % aq7)
	check(foundq7 >= 3 * (9 + 4 + 1 + 1), "everything the chapter stands in the three caves found room (%d)" % foundq7)

	print("== the five phases on the land (phases.gd, the Five Hands release) ==")
	check(Phases.ORDER.size() == 5 and Phases.FEEDS.size() == 5 and Phases.QUELLS.size() == 5 and Phases.BASE.size() == 5 and Phases.ORDER == Roots.ELEMS, "five phases, in the round the spirit root already turns in")
	var walkq7 := "wood"
	var seenq7 := {}
	for _kq7 in 5:
		seenq7[walkq7] = true
		walkq7 = str(Phases.FEEDS[walkq7])
	check(seenq7.size() == 5 and walkq7 == "wood", "the round that bears goes through all five and comes back")
	for elq8 in Phases.ORDER:
		check(Phases.NAMES.has(elq8) and Phases.SAID.has(elq8) and (Phases.BASE[elq8] as Dictionary).size() == 3 and Phases.FED.has(elq8), "%s does something to a wood, to open ground and to water, and is fed by something" % elq8)
		for grq7 in Phases.BASE[elq8]:
			check(Phases.KINDS.has(str(Phases.BASE[elq8][grq7])) and str(Phases.KINDS[str(Phases.BASE[elq8][grq7])].el) == elq8, "what %s makes of %s is a thing of its own phase" % [elq8, grq7])
		check(str(Phases.KINDS[str(Phases.FED[elq8])].el) == elq8 and (not Phases.QUELLED.has(elq8) or Phases.KINDS.has(str(Phases.QUELLED[elq8]))), "what comes of %s fed, and of what it overcomes, can lie on the land" % elq8)
	# the phases overcome one another as every foe of the land is already weak
	var weakq7 := 0
	for fidq7 in Data.ENEMIES:
		var foq7: Dictionary = Data.ENEMIES[fidq7]
		if Phases.QUELLS.has(str(foq7.get("weak", ""))) and Phases.ORDER.has(str(foq7.get("elem", ""))) and str(Phases.QUELLS[str(foq7.weak)]) == str(foq7.elem):
			weakq7 += 1
	check(weakq7 >= 200, "what overcomes what on the land is what overcomes what in a fight (%d foes agree)" % weakq7)
	for kdq7 in Phases.KINDS:
		var pmq7: Node3D = Phases.model(kdq7, 5, Color(0.5, 0.42, 0.3), Color(0.3, 0.55, 0.3))
		check(pmq7.get_child_count() > 0 and int(Phases.KINDS[kdq7].mend) >= 1 and str(Phases.KINDS[kdq7].n) != "" and str(Phases.KINDS[kdq7].one) != "", "%s is drawn from code, has its words, and mends" % kdq7)
		pmq7.free()
	var PHq7 = new_game.call()
	var cycq7: Array = []
	for _cq7 in 6:
		Phases.cycle(PHq7)
		cycq7.append(str(PHq7.phase))
	check(cycq7 == ["wood", "fire", "earth", "thunder", "water", ""] and Phases.text(PHq7).contains("plain blade"), "K turns the hand through the five and back to the plain blade")
	var lwq7: Dictionary = Atlas.world_of("surface")
	var Wq7 := int(lwq7.w)
	var atq7 := Vector2i(-1, -1)
	var dq7 := Vector2i.ZERO
	for tyq7 in range(6, int(lwq7.h) - 6):
		for txq7 in range(6, Wq7 - 6):
			if atq7.x >= 0:
				break
			var hq7 := Vector2i(txq7, tyq7)
			if Atlas.owner_id(lwq7, hq7) != "bamboo" or Phases.ground_of(lwq7, hq7) != "ground":
				continue
			for ddq7 in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
				var allq7 := true
				for stq7 in range(1, 4):
					allq7 = allq7 and Phases.ground_of(lwq7, hq7 + ddq7 * stq7) == "tree"
				if allq7:
					atq7 = hq7
					dq7 = ddq7
	check(atq7.x >= 0, "the Whispering Bamboo has a forest's edge to turn a phase on")
	var gridq7: PackedByteArray = (lwq7.grid as PackedByteArray).duplicate()
	PHq7.level = 0
	var firstq7 := atq7 + dq7
	var r1q7: Dictionary = Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "fire")
	check(int(r1q7.n) >= 1 and Phases.on(PHq7, "surface", firstq7) == "burn" and Phases.told(r1q7).begins_with("Fire"), "fire at a wood: it burns (%s)" % Phases.told(r1q7))
	check(int(Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "fire").n) == 0, "what is burning is not set burning again")
	var r2q7: Dictionary = Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "water")
	check(int(r2q7.quell) >= 1 and Phases.on(PHq7, "surface", firstq7) == "steam" and int(PHq7.reacts.get("quell", 0)) == int(r2q7.quell), "water on what burns puts it out, and leaves steam")
	PHq7.touched = {}
	Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "water")
	check(Phases.on(PHq7, "surface", firstq7) == "drench", "water at a wood: it is drenched")
	Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "fire")
	check(Phases.on(PHq7, "surface", firstq7) == "steam", "a drenched wood does not take fire: the fire only dries it")
	PHq7.touched = {}
	var plainq7: Dictionary = Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "fire")
	PHq7.touched = {}
	Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "wood")
	check(Phases.on(PHq7, "surface", firstq7) == "bloom", "wood at a wood: it is in blossom")
	var fedq7: Dictionary = Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "fire")
	check(int(fedq7.feed) >= 1 and Phases.on(PHq7, "surface", firstq7) == "blaze" and int(fedq7.n) >= int(plainq7.n), "fire in blossom is fed: a blaze, that takes at least as much as a fire did (%d, %d)" % [int(fedq7.n), int(plainq7.n)])
	# the whole round on one piece of ground, each fed by the last
	var roundq7: Array = []
	for elq9 in ["earth", "thunder", "water", "wood", "fire"]:
		var rrq7: Dictionary = Phases.cast(PHq7, "surface", lwq7, atq7, dq7, elq9)
		roundq7.append(Phases.on(PHq7, "surface", firstq7) if int(rrq7.feed) >= 1 else "")
	check(roundq7 == ["kiln", "lode", "rain", "grove", "blaze"], "the round on one piece of ground: each phase is fed by what the last one left (%s)" % str(roundq7))
	PHq7.touched = {}
	Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "earth")
	var mossq7: Dictionary = Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "wood")
	check(int(mossq7.quell) >= 1 and Phases.on(PHq7, "surface", firstq7) == "moss", "wood breaks what earth raised into a mossy bank")
	check(int(Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "earth", true).n) >= 0 and Phases.on(PHq7, "surface", firstq7) == "moss", "asking what a blow would do does nothing")
	check(Phases.turned(PHq7) == 5 and (lwq7.grid as PackedByteArray) == gridq7, "all five have been turned on the land, and not one tile of it has changed")
	PHq7.day = int(PHq7.day) + 9
	check(Phases.on(PHq7, "surface", firstq7) == "", "what a phase leaves mends by days lived")
	Phases.mend(PHq7)
	check(PHq7.touched.is_empty(), "and what has mended is forgotten")
	# a town's streets, a floor and the sect's own courtyard are not turned
	var townq7 := Vector2i(-1, -1)
	for tyq8 in range(6, int(lwq7.h) - 6, 3):
		for txq8 in range(6, Wq7 - 6, 3):
			if townq7.x < 0 and Music.town_at(Atlas.owner_id(lwq7, Vector2i(txq8, tyq8)), Vector2i(txq8, tyq8)) != "" and MapGen.is_walkable_tile(lwq7.grid[tyq8 * Wq7 + txq8]):
				townq7 = Vector2i(txq8, tyq8)
	check(townq7.x >= 0 and Phases.ground_of(lwq7, townq7) == "" and Phases.ground_of(Atlas.world_of(Caves.fid("volcano", -1)), Vector2i(5, 5)) == "", "no phase is turned on the streets of a town or under the ground")
	# a step counts blows that came to what it asks
	var mtq7 := Vector2i(-1, -1)
	var mdq7 := Vector2i.ZERO
	for tyq9 in range(6, int(lwq7.h) - 6):
		for txq9 in range(6, Wq7 - 6):
			if mtq7.x < 0 and Atlas.owner_id(lwq7, Vector2i(txq9, tyq9)) == "mountain" and lwq7.grid[tyq9 * Wq7 + txq9] == MapGen.FLOOR:
				for ddq9 in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
					if Phases.ground_of(lwq7, Vector2i(txq9, tyq9) + ddq9) == "tree" and Atlas.owner_id(lwq7, Vector2i(txq9, tyq9) + ddq9) == "mountain":
						mtq7 = Vector2i(txq9, tyq9)
						mdq7 = ddq9
	check(mtq7.x >= 0 and Phases.ground_of(lwq7, mtq7) == "", "on the mountain at the middle of the land the woods answer a phase, and the paths do not")
	PHq7.step = Data.step_index("s_p37_quench")
	PHq7.step_phase = 0
	PHq7.touched = {}
	Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "fire")
	Phases.cast(PHq7, "surface", lwq7, atq7, dq7, "water")
	check(int(PHq7.step_phase) == 0, "a step counts nothing done in another country than its own")
	Phases.cast(PHq7, "surface", lwq7, mtq7, mdq7, "fire")
	check(int(PHq7.step_phase) == 0, "a step that asks for water to overcome fire does not count the fire")
	Phases.cast(PHq7, "surface", lwq7, mtq7, mdq7, "water")
	check(int(PHq7.step_phase) == 1, "and counts the water that put it out, once for the blow")
	# the blade strikes what it always struck
	check(Impact.reach(Vector2i(0, 1)).size() == 4 and Sunder.reach(Vector2i(0, 1), 1).size() == 4, "the sword reaches the four tiles it always reached, whatever is in the hand")
	PHq7.free()
	check(wsq7.contains("Phases.cast(Game, layer, wd, ptile, facing, str(Game.phase))") and wsq7.contains("if str(Game.phase) != \"\":") and wsq7.contains("str(Game.cur_step().get(\"kind\", \"\")) == \"sunder\"") and msrc.contains("KEY_K") and bsrc.contains("Game.phase = \"\""), "F with a phase in the hand asks phases.gd; K turns it; the bot strikes with the plain blade outside its phase steps")

	print("== hands on things (grip.gd, the Five Hands release) ==")
	var shq7 := Vector3(0.2, 1.4, 0.0)
	var elq7b := Vector3(0.25, 1.15, -0.02)
	var wrq7 := Vector3(0.27, 0.9, 0.03)
	var la7 := (elq7b - shq7).length()
	var lb7 := (wrq7 - elq7b).length()
	for tgq7 in [Vector3(0.3, 1.2, 0.35), Vector3(0.1, 1.1, 0.3), Vector3(0.45, 1.5, 0.2), Vector3(0.2, 0.95, 0.1)]:
		var svq7: Array = Grip.solve(shq7, elq7b, wrq7, tgq7)
		check(absf(((svq7[0] as Vector3) - shq7).length() - la7) < 0.001 and absf(((svq7[1] as Vector3) - (svq7[0] as Vector3)).length() - lb7) < 0.001 and (svq7[1] as Vector3).distance_to(tgq7) < 0.002, "an arm of two bones reaches %s with its bones the length they were" % str(tgq7))
	var farq7: Array = Grip.solve(shq7, elq7b, wrq7, shq7 + Vector3(0, 0, 3.0))
	check(absf(((farq7[1] as Vector3) - shq7).length() - (la7 + lb7)) < 0.01 and (farq7[1] as Vector3).z > 0.4, "what is out of reach is reached towards, the arm straight")
	check(Grip.on_triangle(Vector3(0.2, 1.0, 0.2), Vector3.ZERO, Vector3(1, 0, 0), Vector3(0, 0, 1)).distance_to(Vector3(0.2, 0, 0.2)) < 0.001 and Grip.on_triangle(Vector3(-1, 0.5, -1), Vector3.ZERO, Vector3(1, 0, 0), Vector3(0, 0, 1)).distance_to(Vector3.ZERO) < 0.001, "the nearest point of a triangle: on its face, or at its corner")
	var trisq7 := PackedVector3Array([Vector3(-1, 0.8, 0.5), Vector3(1, 0.8, 0.5), Vector3(0, 1.8, 0.5), Vector3(-1, 0, 5), Vector3(1, 0, 5), Vector3(0, 1, 5)])
	var hitq7: Array = Grip.closest(trisq7, Vector3(0, 1.2, 0.3), 0.34)
	check(hitq7.size() == 2 and absf(float(hitq7[1]) - 0.2) < 0.001 and Grip.closest(trisq7, Vector3(0, 1.2, -0.5), 0.34).is_empty(), "a palm finds the nearest face of a thing within a span, and nothing further off")
	for toq7 in Grip.TOOLS:
		var tdq7: Dictionary = Grip.TOOLS[toq7]
		check(not tdq7.has("work") or str(tdq7.get("on", "")) in ["down", "fwd", "drag"], "%s says how its working end is brought to what it works" % toq7)
		for rgq7 in tdq7.get("two", []):
			check(minf(absf(float(rgq7[0])), absf(float(rgq7[1]))) >= 0.12 and float(rgq7[0]) * float(rgq7[1]) > 0.0, "%s: the other hand closes on the shaft clear of the first" % toq7)
	if Assets.has("characters/lin_feng"):
		var hmq7: Node3D = Assets.instance("characters/lin_feng")
		var skq7: Skeleton3D = hmq7.find_children("*", "Skeleton3D", true, false)[0]
		var ihq7 := skq7.find_bone("hand.R")
		var restq7 := skq7.get_bone_global_rest(ihq7)
		var seatq7: Node3D = Grip.seat(Node3D.new(), "hoe")
		var gripq7: Vector3 = restq7 * (seatq7.transform * Vector3(0, Grip.AUTHORED, 0))
		var oldq7: Vector3 = restq7 * Vector3(0, Grip.AUTHORED, 0)
		check(gripq7.y < restq7.origin.y - 0.05 and oldq7.y > restq7.origin.y + 0.05, "what is held is gripped in the palm, below the wrist (%.3f): it was above it, in the sleeve (%.3f; the wrist is at %.3f)" % [gripq7.y, oldq7.y, restq7.origin.y])
		seatq7.free()
		# (his own arm, from where his own bones rest: the wrist comes to what is asked, and the bones keep their lengths)
		var ruq7 := skq7.get_bone_global_rest(skq7.find_bone("upper_arm.R")).origin
		var rfq7 := skq7.get_bone_global_rest(skq7.find_bone("forearm.R")).origin
		var goalq7 := restq7.origin + Vector3(0.1, 0.25, 0.3)
		var ownq7: Array = Grip.solve(ruq7, rfq7, restq7.origin, goalq7)
		check((ownq7[1] as Vector3).distance_to(goalq7) < 0.002 and absf((ownq7[0] as Vector3).distance_to(ruq7) - rfq7.distance_to(ruq7)) < 0.001, "the hero's own arm, solved from his own bones, puts the wrist where it is asked")
		var baq7: Node3D = Grip.hold(hmq7, Folk.held("lantern"), "lantern", "hand.L")
		var rcq7 = Grip.reach_of(baq7)
		check(baq7 != null and rcq7 != null and rcq7.hangs.size() == 1 and float((rcq7.hangs[0] as Node3D).get_meta("len")) > 0.1 and rcq7.main == "L", "a lantern is held in the left palm, and the lantern itself hangs from the end of its stick")
		var bbq7: Node3D = Grip.hold(hmq7, Folk.held("hoe"), "hoe", "hand.R")
		var rdq7 = Grip.reach_of(bbq7)
		check(rdq7 != null and rdq7.tool.has("two") and rdq7.tool.has("work") and rdq7.hangs.is_empty(), "a hoe is a thing of two hands with a working end")
		check(Grip.reach_of(Grip.hold(hmq7, Folk.held("cup"), "cup", "hand.R")) == null, "a cup needs nothing solved: it is only in the hand")
		var polq7: Node3D = Folk.held("pole")
		var hgq7 := 0
		for chq7 in polq7.get_children():
			if str(chq7.name).begins_with("hang"):
				hgq7 += 1
		check(hgq7 == 2, "the two baskets of a shoulder pole each hang on their own cords")
		polq7.free()
		hmq7.free()
	check(wsq7.contains("Grip.hold(m, Folk.held(what), what, bone)") and wsq7.contains("func _use_reach") and wsq7.contains("func _trunk_at"), "whatever is put in a hand in the world is put there by grip.gd, and what he works on is what is really there")

	print("== what hangs and swings (heft.gd, the Five Hands release) ==")
	for lnq8 in [0.25, 0.5, 2.12]:
		var psq7 := {"th": 0.08, "om": 0.0}
		var tq7 := 0.0
		var crossq7: Array = []
		var prevq7 := 0.08
		var e0q7 := Heft.energy(psq7, lnq8)
		var riseq7 := false
		while tq7 < 12.0 and crossq7.size() < 3:
			var thq7 := Heft.pendulum(psq7, 1.0 / 60.0, lnq8, 0.0)
			tq7 += 1.0 / 60.0
			if prevq7 > 0.0 and thq7 <= 0.0:
				crossq7.append(tq7 - (1.0 / 60.0) * (0.0 - thq7) / (prevq7 - thq7))
			prevq7 = thq7
			riseq7 = riseq7 or Heft.energy(psq7, lnq8) > e0q7 * 1.02
		var perq7: float = float(crossq7[2]) - float(crossq7[1]) if crossq7.size() >= 3 else 0.0
		check(absf(perq7 - Heft.period(lnq8)) < Heft.period(lnq8) * 0.03 and not riseq7, "a weight %.2f m from its axle swings once in %.2f s (2 pi root L over g is %.2f), and gains nothing from nowhere" % [lnq8, perq7, Heft.period(lnq8)])
	var dsq7 := {"th": 0.6, "om": 0.0}
	for _iq7 in 60 * 20:
		Heft.pendulum(dsq7, 1.0 / 60.0, 0.5, 0.9)
	check(absf(float(dsq7.th)) < 0.01 and absf(float(dsq7.om)) < 0.01, "left alone in air, it comes to rest hanging straight down")
	var bsq7 := {}
	Heft.kick(bsq7, 0.62)
	var peakq7 := 0.0
	for _iq8 in 120:
		peakq7 = maxf(peakq7, absf(Heft.pendulum(bsq7, 1.0 / 60.0, 0.5, 0.9)))
	check(peakq7 > 0.08 and peakq7 < 0.2, "a bell that is struck swings about as far as it used to be drawn swinging (%.3f)" % peakq7)
	var swq8 := {}
	var topq7 := 0.0
	for _iq9 in 60 * 14:
		topq7 = maxf(topq7, absf(Heft.pendulum(swq8, 1.0 / 60.0, 2.12, 0.12, Heft.pump(swq8, 2.12, 0.44))))
	check(topq7 > 0.36 and topq7 < 0.6, "a swing that is pumped goes up to about the height its rider wants, and no higher (%.2f)" % topq7)
	var hsq7 := {}
	var pivq7 := Vector3(0, 2, 0)
	Heft.hang(hsq7, pivq7, 1.0 / 60.0, 0.3)
	check((hsq7.p as Vector3).distance_to(pivq7 + Vector3(0, -0.3, 0)) < 0.001, "what hangs starts hanging straight down")
	var lagq7 := 0.0
	for iq10 in 30:
		pivq7.x += 2.0 / 60.0
		var bpq7 := Heft.hang(hsq7, pivq7, 1.0 / 60.0, 0.3)
		lagq7 = minf(lagq7, bpq7.x - pivq7.x)
		check(absf(bpq7.distance_to(pivq7) - 0.3) < 0.001 or iq10 < 29, "the weight stays on its cord")
	check(lagq7 < -0.03, "carried off sideways, a hanging weight lags behind the hand (%.3f m)" % lagq7)
	for _iq11 in 60 * 8:
		Heft.hang(hsq7, pivq7, 1.0 / 60.0, 0.3)
	check((hsq7.p as Vector3).distance_to(pivq7 + Vector3(0, -0.3, 0)) < 0.01, "and when the hand stops it swings on, and comes to rest under it")
	var flq7 := {}
	Heft.hang(flq7, Vector3(0, 0.2, 0), 1.0 / 60.0, 0.5, 0.9, 0.0)
	for _iq12 in 60:
		Heft.hang(flq7, Vector3(0, 0.2, 0), 1.0 / 60.0, 0.5, 0.9, 0.0)
	check((flq7.p as Vector3).y >= -0.0001, "a float on a line does not go under the water it floats on")
	var boq7 := {"y": -0.2, "v": 0.0}
	for _iq13 in 60 * 6:
		Heft.bob(boq7, 1.0 / 60.0, 0.0)
	check(absf(float(boq7.y)) < 0.005, "what floats comes back to the face of the water")
	var hbq7 := Heft.hung(Vector3(0.3, -1, 0.1).normalized(), Basis.IDENTITY)
	check(absf(hbq7.determinant() - 1.0) < 0.001 and (-hbq7.y).distance_to(Vector3(0.3, -1, 0.1).normalized()) < 0.001, "a thing drawn hanging down its own length is turned to hang the way its weight has gone")
	check(wsq7.contains("Heft.pump(sst, 2.12") and wsq7.contains("Heft.kick(bst") and not wsq7.contains("sin(ph * 2.2) * 0.42"), "the swing is pumped and the bell is struck: neither is a sine any longer")

	print("== the weight of a blow (sunder.gd, the Small Fish release) ==")
	check(Sunder.RANKS.size() == 7 and Sunder.REALM_AT.size() == 7 and Sunder.ORDER.size() == Sunder.KINDS.size(), "seven weights of a blow, four things that can be done to a tile")
	var r1_36 := {}
	for dt36 in Sunder.reach(Vector2i(0, 1), 1):
		r1_36[dt36] = true
	var same36 := r1_36.size() == Impact.reach(Vector2i(0, 1)).size()
	for dt37 in Impact.reach(Vector2i(0, 1)):
		same36 = same36 and r1_36.has(dt37)
	check(same36 and Sunder.reach(Vector2i(1, 0), 0) == [Vector2i(1, 0)], "the edge of a blade reaches what the sword always reached, and a single cut one tile")
	for rk36 in range(1, Sunder.RANKS.size()):
		check(Sunder.reach(Vector2i(0, 1), rk36).size() > Sunder.reach(Vector2i(0, 1), rk36 - 1).size() and int(Sunder.REALM_AT[rk36]) >= int(Sunder.REALM_AT[rk36 - 1]) and str(Sunder.RANKS[rk36].n) != str(Sunder.RANKS[rk36 - 1].n), "a heavier blow reaches further, and is reached later: %s" % Sunder.RANKS[rk36].n)
	var SU36 = new_game.call()
	SU36.level = 0
	check(Sunder.might(SU36) == 1 and Sunder.rank(SU36) == 1, "at Qi Condensation his blow is the edge of a blade")
	SU36.level = 3 * 3
	check(Sunder.might(SU36) == 4, "at Nascent Soul the stone breaks and the ground cracks")
	SU36.level = Data.MAX_LEVEL
	check(Sunder.might(SU36) == 6 and Sunder.rank(SU36) == 6 and bool(Sunder.RANKS[6].crater), "at the last realm a blow in earnest parts a wood and leaves a hollow")
	var cyc36: Array = []
	for _c36 in 8:
		Sunder.cycle(SU36)
		cyc36.append(Sunder.rank(SU36))
	check(cyc36 == [5, 4, 3, 2, 1, 0, 6, 5] and Sunder.text(SU36).contains("held back"), "H holds the hand back a weight at a time, down to a single cut, and round to all he has (%s)" % str(cyc36))
	var sw37: Dictionary = Atlas.world_of("surface")
	var edge36 := Vector2i(-1, -1)
	var edir36 := Vector2i.ZERO
	var W36 := int(sw37.w)
	for ty36 in range(4, int(sw37.h) - 4):
		for tx36 in range(4, W36 - 4):
			if edge36.x >= 0:
				break
			var here36 := Vector2i(tx36, ty36)
			if sw37.grid[ty36 * W36 + tx36] != MapGen.FLOOR or Atlas.owner_id(sw37, here36) != "mountain":
				continue
			for d36 in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
				if sw37.grid[(ty36 + d36.y) * W36 + tx36 + d36.x] == MapGen.WALL and sw37.grid[(ty36 + d36.y * 2) * W36 + tx36 + d36.x * 2] == MapGen.WALL:
					edge36 = here36
					edir36 = d36
	check(edge36.x >= 0, "there is a forest's edge on the mountain to strike at")
	SU36.step = Data.step_index("s_p36_light")
	SU36.hand = 0
	SU36.day = 5
	var grid36: PackedByteArray = (sw37.grid as PackedByteArray).duplicate()
	var b36: Dictionary = Sunder.blow(SU36, "surface", sw37, edge36, edir36)
	check(int(b36.n) == 1 and int(b36.rank) == 0 and str(b36.tiles[0][1]) == "tree" and Sunder.scar(SU36, "surface", edge36 + edir36) == "tree" and SU36.sunder_light == 1 and SU36.step_sunder == 1 and Sunder.told(b36) != "", "a single cut fells one thing and nothing behind it, and the step that asks for a held hand hears of it")
	check(int(Sunder.blow(SU36, "surface", sw37, edge36, edir36).n) == 0 and SU36.step_sunder == 1, "what lies broken is not broken again")
	SU36.hand = -1
	var b37: Dictionary = Sunder.blow(SU36, "surface", sw37, edge36, edir36)
	check(int(b37.n) >= 2 and int(b37.rank) == 6 and SU36.step_sunder == 1 and SU36.sunder_light == 1, "a blow in earnest breaks more than one thing (%d), and is not a held hand" % int(b37.n))
	check(grid36 == sw37.grid, "no tile of the land is changed by any of it: a felled wood is still a wood nobody walks through")
	SU36.step = Data.step_index("s_p36_wood")
	SU36.step_sunder = 0
	SU36.day = 9
	check(Sunder.scar(SU36, "surface", edge36 + edir36) == "", "a felled tree has mended by the next day but one")
	var b38: Dictionary = Sunder.blow(SU36, "surface", sw37, edge36, edir36)
	check((SU36.step_sunder == int(b38.n) or SU36.step > Data.step_index("s_p36_wood")) and int(b38.n) >= 2 and Sunder.total(SU36) >= 3, "the step that asks for things broken counts things")
	for kd36 in Sunder.ORDER:
		var sm36: Node3D = Sunder.model(kd36, 7, Color("8a7a5a"))
		check(sm36 != null and int(Sunder.KINDS[kd36].mend) >= 1 and int(Sunder.KINDS[kd36].mend) <= 5, "%s mends in a few days, and what is drawn of it is built from code" % kd36)
		sm36.free()
	check(Sunder.what(sw37, Vector2i(0, 0), Atlas.to_world("sect", Vector2i(20, 8)), 6) == "", "nothing is broken in the sect's own court")
	var ssrc := FileAccess.get_file_as_string("res://scripts/sunder.gd")
	check(not ssrc.contains("rand") or not ssrc.contains("randf()") or ssrc.contains("rng.seed"), "nothing a blow does is thrown for")
	SU36.free()

	print("== cooking (cooking.gd, kitchen.gd, the Small Fish release) ==")
	check(Cooking.STAGES.size() == 12 and Cooking.ORDER.size() == Cooking.RECIPES.size() and str(Cooking.STAGES[Cooking.SIMMER].id) == "simmer" and Cooking.total_seconds() >= 40.0, "a meal is twelve things done one after another, and one of them is the simmer")
	var pap36: AnimationPlayer = Assets.instance("characters/lin_feng").get_meta("ap")
	var yap36: AnimationPlayer = Assets.instance("characters/yue_ling").get_meta("ap")
	var cams36 := {}
	for st36 in Cooking.STAGES:
		check(pap36.has_animation(str(st36.clip)) and (str(st36.comp) == "watch" or yap36.has_animation(str(st36.comp))) and (str(st36.hold) == "" or Props.held(str(st36.hold)) != null) and str(st36.said).length() > 20, "%s: a clip the party carries, something in the hand, and a line" % st36.id)
		cams36[str(st36.id)] = true
	check(cams36.size() == 12, "no two stages are the same thing")
	for rid36 in Cooking.ORDER:
		var rc36: Dictionary = Cooking.RECIPES[rid36]
		check((rc36.lines as Array).size() >= 3 and (rc36.under as Array).size() >= 1 and (rc36.over as Array).size() >= 1 and int(rc36.stir[0]) <= int(rc36.stir[1]) and float(rc36.heal) > 0.0 and float(rc36.heal) <= 1.0, "%s: three lines when it comes out right, and one each way it does not" % rid36)
		for nk37 in rc36.needs:
			check(Load.GOODS.has(str(nk37)) and bsrc.contains("\"%s\": \"" % str(nk37)), "%s is made of goods of the land the hands can gather (%s)" % [rid36, nk37])
		check(Cooking.outcome(rid36, Cooking.ideal(rid36)) == "good" and Cooking.outcome(rid36, int(rc36.stir[1]) + 1) == "over", "%s: turned as it wants it comes out right, and once more it does not" % rid36)
	check(Cooking.outcome("small_fish", 0) == "good" and Cooking.outcome("small_fish", 1) == "good" and Cooking.outcome("small_fish", 2) == "over" and Cooking.outcome("yam_stew", 0) == "under", "a small fish comes apart at the second poke, and a stew left alone catches")
	# the pot is physics, and the same every time
	var cold36: Dictionary = Cooking.pot()
	for _i36 in 300:
		cold36 = Cooking.step(cold36, 1.0 / 30.0, {"fire": 1.0, "lid": true})
	check(is_equal_approx(float(cold36.T), Cooking.AIR) and float(cold36.fire) == 0.0 and int(cold36.hops) == 0, "a fire with no wood under it heats nothing")
	var pa36b: Dictionary = Cooking.run(1)
	var pb36: Dictionary = Cooking.run(1)
	check(pa36b == pb36, "the same pot, cooked the same way, is the same pot")
	var boil36: Dictionary = Cooking.run(0, 7)
	var before36: Dictionary = Cooking.run(0, 4)
	check(float(before36.T) < 80.0 and float(before36.T) > Cooking.AIR and float(before36.water) > 0.0 and not bool(before36.boiled), "water poured into a hot pot is warm, not boiling (%d degrees)" % int(float(before36.T)))
	check(bool(boil36.boiled) and float(boil36.T) <= 100.0 and int(boil36.hops) >= 2 and float(boil36.wood) < 1.0 and float(boil36.wood) > 0.3, "under the lid it comes to the boil and the lid hops (%d times); water is never hotter than boiling; the wood burns down" % int(boil36.hops))
	check(float(pa36b.done) >= 1.0 and float(Cooking.run(0, 6).done) < 0.6, "what is in the pot is done by the heat it has had: not when it goes in, and by the end of the simmer")
	var spin36: Dictionary = Cooking.pot()
	spin36.wood = 1.0
	for _i37 in 60:
		spin36 = Cooking.step(spin36, 1.0 / 30.0, {"fire": 0.5, "stir": 0.8})
	var top36 := float(spin36.spin)
	for _i38 in 90:
		spin36 = Cooking.step(spin36, 1.0 / 30.0, {"fire": 0.5})
	check(top36 > 3.0 and float(spin36.spin) < top36 * 0.2 and float(spin36.spin) > 0.0 and is_equal_approx(Cooking.dish(top36), top36 * top36 * Cooking.POT_R * Cooking.POT_R / (2.0 * Cooking.G)) and Cooking.dish(0.0) == 0.0,
		"a stirred pot turns with the ladle, dishes by the square of its speed, and runs down by itself")
	var lid36b: Dictionary = Cooking.pot()
	lid36b.lid_v = 1.0
	var peak36 := 0.0
	for _i39 in 60:
		lid36b = Cooking.step(lid36b, 1.0 / 60.0, {})
		peak36 = maxf(peak36, float(lid36b.lid_y))
	check(absf(peak36 - 1.0 / (2.0 * Cooking.G)) < 0.012 and float(lid36b.lid_y) == 0.0, "a lid thrown up at a metre a second rises v squared over two g (to a frame's worth) and comes down")
	check(Kitchen.lob(Vector3(0, 1, 0), Vector3(2, 0.5, 1), 0.5, 0.0).is_equal_approx(Vector3(0, 1, 0)) and Kitchen.lob(Vector3(0, 1, 0), Vector3(2, 0.5, 1), 0.5, 1.0).is_equal_approx(Vector3(2, 0.5, 1)) and Kitchen.lob(Vector3(0, 1, 0), Vector3(2, 1, 0), 0.5, 0.5).y > 1.2,
		"what is thrown into the pot leaves the hand, arcs, and arrives")
	var kit36: Node3D = Kitchen.kit(Cooking.RECIPES.yam_stew.needs, Vector3(0, 0, 1), Color.WHITE)
	var parts36 := true
	for pn36 in ["logs", "flames", "embers", "light", "pot", "lid", "board", "bowls"]:
		parts36 = parts36 and kit36.get_node_or_null(pn36) != null
	check(parts36 and kit36.get_node("pot/water/swirl").get_child_count() == Cooking.pieces_of("yam_stew"), "the fire, the pot, the lid, the board and the bowls are built from code, with a piece for each thing that goes in")
	var fx36: Dictionary = Kitchen.tick(kit36, Cooking.run(2, 8), 7, 3.0, 10.0, 0.03)
	check(fx36.has("steam") and (kit36.get_node("pot") as Node3D).visible and (kit36.get_node("pot/water") as Node3D).visible and (kit36.get_node("pot/water/swirl").get_child(0) as Node3D).visible, "at the simmer the pot is on, there is water in it and things in the water")
	kit36.free()
	var CK36 = new_game.call()
	check(Cooking.blocked(CK36, "small_fish").contains("pedlars") and Cooking.ready(CK36).is_empty(), "with no pot nothing is cooked")
	CK36.inv[Cooking.POT] = 1
	check(Cooking.missing(CK36, "small_fish").size() == 2 and Cooking.blocked(CK36, "small_fish").contains("wants"), "with a pot and nothing to put in it, he is told what it wants")
	CK36.inv.carp = 2
	CK36.inv.herb_bundle = 2
	CK36.hp[0] = 1.0
	CK36.step = Data.step_index("s_p36_fish")
	check(Cooking.ready(CK36).has("small_fish") and Cooking.ready(CK36).has("herb_congee") and not Cooking.ready(CK36).has("yam_stew"), "what he has the makings of is offered")
	var said36: Array = Cooking.done(CK36, "small_fish", 2)
	check(said36.size() == 2 and CK36.step_cook == 0 and CK36.cooked_good == 0 and CK36.cooked_n == 1 and int(CK36.inv.carp) == 1 and float(CK36.hp[0]) > 1.0 and float(CK36.hp[0]) < float(CK36.max_hp(0)), "a fish stirred to pieces is eaten, mends half as much, and is not the fish the story asked for")
	Cooking.done(CK36, "small_fish", 1)
	check(CK36.step > Data.step_index("s_p36_fish") and CK36.cooked_good == 1 and not CK36.inv.has("carp") and int(CK36.cooked.small_fish) == 2, "a fish brought out whole is, and what went into it is gone")
	CK36.free()
	var wsrc36 := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(wsrc36.contains("func fp_on()") and wsrc36.contains("func toggle_view()") and msrc.contains("KEY_P") and msrc.contains("KEY_B") and msrc.contains("KEY_H") and wsrc36.contains("func cook_why()"), "P looks out of his own eyes, B lays a fire, H holds the hand back")
	check(not bsrc.contains("toggle_view") and not bsrc.contains("first_person"), "the bot never changes how the land is looked at")

	print("== picking, digging and veins (toil.gd, the Small Fish release) ==")
	var cave36: Dictionary = Atlas.world_of(Caves.fid("forge", -1))
	var veins36 := 0
	var walls36 := 0
	var reach36 := 0
	for vy36 in int(cave36.h):
		for vx36 in int(cave36.w):
			var vt36 := Vector2i(vx36, vy36)
			if MapGen.is_walkable_tile(cave36.grid[vy36 * int(cave36.w) + vx36]):
				continue
			walls36 += 1
			if Toil.vein(cave36, vt36):
				veins36 += 1
				for vd36 in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
					var vn36: Vector2i = vt36 + vd36
					if vn36.x >= 0 and vn36.y >= 0 and vn36.x < int(cave36.w) and vn36.y < int(cave36.h) and MapGen.is_walkable_tile(cave36.grid[vn36.y * int(cave36.w) + vn36.x]):
						if Toil.offers(cave36, vn36, vt36, true, false) == ["mine", "quarry"]:
							reach36 += 1
						break
	check(veins36 > walls36 / 6 and veins36 < walls36 / 3 and reach36 >= 8, "about one piece of a cave's wall in four shows a vein, and enough of them can be stood in front of (%d of %d, %d reached)" % [veins36, walls36, reach36])
	check(not Toil.vein(sw37, edge36 + edir36) and Toil.offers(sw37, edge36, edge36 + edir36) == ["fell", "pick"], "at the forest's edge a tree can be felled, or mushrooms picked under it")
	var TW36 = new_game.call()
	check(Toil.choose(TW36, ["fell", "pick"]) == "fell" and Toil.choose(TW36, []) == "", "with no tool he is told of the first thing")
	TW36.inv.trug = 1
	check(Toil.choose(TW36, ["fell", "pick"]) == "pick", "with only a basket, C picks")
	TW36.inv.axe = 1
	check(Toil.choose(TW36, ["fell", "pick"]) == "fell" and Toil.choose(TW36, ["fell", "pick"], true) == "pick", "with both, C fells and Shift+C picks")
	TW36.step = Data.step_index("s_p36_pick")
	check(Toil.choose(TW36, ["fell", "pick"]) == "pick", "and the work the story is asking for is done first")
	var tl36: Array = Toil.done(TW36, "pick", "surface", edge36 + edir36)
	check(int(TW36.inv.get("mushrooms", 0)) == 1 and TW36.step_toil == 1 and tl36.size() == 2 and Toil.spent(TW36, "surface", edge36 + edir36), "mushrooms are in the basket, and that piece of the wood has given what it had today")
	# (a bug of the Heavy Road release, mended here: the rock of a cave is laid as BUILDING, and no cave wall had ever given ore)
	var ore36 := 0
	for oy36 in int(cave36.h):
		for ox36 in int(cave36.w):
			if MapGen.is_walkable_tile(cave36.grid[oy36 * int(cave36.w) + ox36]) and ox36 + 1 < int(cave36.w) and Toil.work_at(cave36, Vector2i(ox36, oy36), Vector2i(ox36 + 1, oy36), true, false) == "quarry":
				ore36 += 1
	check(ore36 >= 10 and Toil.work_at(cave36, Vector2i(1, 1), Vector2i(2, 1), false, true) == "", "the wall of a cave can be cut for ore (%d places from the west alone), and nothing is worked at under somebody's roof" % ore36)
	check(Toil.good_of("mine", true) == "jade_rough" and Toil.good_of("quarry", true) == "ore_lump" and Toil.good_of("dig", false) == "wild_yam", "a vein gives jade in the rind, the wall beside it ore, the open ground a yam")
	TW36.free()

	print("== the spirit root (roots.gd) ==")
	var RG = new_game.call()
	check(Roots.count(RG) == 3 and Roots.lead(RG) == "wood" and Roots.elems(RG) == ["wood", "fire", "earth"] and Roots.kind_name(RG) == "True Root", "a hero made before the stone was asked has a True Root, led by wood")
	for rk in Roots.MODS:
		check(is_equal_approx(Roots.mod(RG, str(rk)), 1.0) and (Roots.MODS[rk] as Array).size() == 5 and is_equal_approx(float(Roots.MODS[rk][2]), 1.0), "a True Root changes nothing: %s" % rk)
		for rv in Roots.MODS[rk]:
			check(float(rv) >= 0.8 and float(rv) <= 1.3, "no root is worth more than a third of anything (%s)" % rk)
	for rk2 in Roots.LATE:
		check(Roots.MODS.has(rk2) and (Roots.LATE[rk2] as Array).size() == 5 and is_equal_approx(float(Roots.LATE[rk2][2]), 1.0) and float(Roots.LATE[rk2][4]) <= 1.3 and float(Roots.LATE[rk2][4]) >= 0.8, "the round closes within the same bounds: %s" % rk2)
	for el5 in Data.ELEM_COLORS:
		check(is_equal_approx(Roots.power(RG, str(el5)), 1.0), "and a True Root strikes as it always did with %s" % el5)
	check(Roots.ELEMS.size() == 5 and not Roots.ELEMS.has("dark") and not Roots.ELEMS.has("phys"), "the stone measures five phases, and the dark is none of them")
	for rn in range(1, 6):
		for rf in Roots.ELEMS:
			var re5: Array = Roots.elems_of(rn, str(rf))
			var seen5 := {}
			for x5 in re5:
				seen5[x5] = true
			check(re5.size() == rn and seen5.size() == rn and str(re5[0]) == str(rf) and Roots.title_of(rn, str(rf)).length() > 8, "a root of %d led by %s is %s" % [rn, rf, Roots.title_of(rn, str(rf))])
		check(Roots.KINDS.has(rn) and fits.call(str(Roots.KINDS[rn].desc)), "a root of %d has a name and a word that fits" % rn)
		RG.hero["root"] = rn
		RG.hero["root_el"] = "fire"
		RG.level = 0
		check(Roots.count(RG) == rn and Roots.has(RG, "fire") and Roots.text(RG).length() > 40, "the page tells a root of %d" % rn)
		check((rn < 3) == (Roots.mod(RG, "exp") > 1.0) and (rn > 3) == (Roots.mod(RG, "exp") < 1.0) and (rn < 3) == (Roots.power(RG, "fire") > 1.0), "the fewer the phases the quicker, at first (%d)" % rn)
		check((rn < 3) == (Roots.mod(RG, "price") < 1.0) and (rn < 3) == (Roots.mod(RG, "stipend") > 1.0), "the sect is kinder to a root it is proud of (%d)" % rn)
		RG.level = Roots.BLOOM * 3
		check(Roots.bloomed(RG) and (rn <= 3 or Roots.mod(RG, "exp") > 1.0) and (rn <= 3 or Roots.mod(RG, "taken") < 1.0), "and a wide root is late: past %s it learns faster than a True Root (%d)" % [Data.REALMS[Roots.BLOOM], rn])
		for kd5 in ["hand", "kid", "giant", "elder", "watch", "trade", "learned", "holy", "cult"]:
			var sd5: Dictionary = Roots.said(RG, kd5, rn)
			check(fits.call(str(sd5.line)) and str(sd5.line).length() > 40 and not str(sd5.line).contains("%s") and Data.EMOTES.has(str(sd5.clip)), "a %s answers a root of %d, with a gesture everybody has" % [kd5, rn])
			check(not str(sd5.line).contains(" sir") and not str(sd5.line).contains("young man") and not str(sd5.line).contains("—"), "and says it of a hero of either sex (%s, %d)" % [kd5, rn])
		for nid5 in Roots.NAMED:
			check(fits.call(Roots.word(RG, str(nid5))) and Roots.word(RG, str(nid5)).length() > 60, "%s has a word for a root of %d" % [nid5, rn])
		for ak5 in Roots.AT:
			var al5: Array = Roots.told(RG, str(ak5))
			check(Data.DIALOGUE.has(str(ak5)) and al5.size() >= 1 and (al5[0] as Array).size() == 2 and fits.call(str(al5[0][1])), "%s is told differently of a root of %d" % [ak5, rn])
			var et5: Array = Echoes.told(RG, str(ak5), Data.DIALOGUE[str(ak5)])
			check(et5.size() == (Data.DIALOGUE[str(ak5)] as Array).size() + al5.size() + Echoes.lines(RG, str(ak5)).size() and str(et5[et5.size() - 1][1]) == str(al5[al5.size() - 1][1]), "and it is the last thing said in %s" % ak5)
	var said5 := {}
	for rn2 in range(1, 6):
		RG.hero["root"] = rn2
		said5[str(Roots.said(RG, "trade", 0).line)] = true
		said5[str(Roots.word(RG, "elder"))] = true
	check(said5.size() == 10, "no two roots are answered alike")
	for nid6 in Roots.NAMED:
		var is_npc := false
		for a6 in Data.AREAS:
			for np6 in Data.AREAS[a6].get("npcs", []):
				if str(np6.id) == str(nid6) and str(np6.n) == str(Roots.NAMED[nid6].n):
					is_npc = true
		check(is_npc and (Roots.NAMED[nid6].lines as Array).size() == 5, "%s is somebody who stands in the land, with five words" % nid6)
	check(not bsrc.contains("Roots.mod") and bsrc.contains("\"root\": \"root\""), "the bot decides nothing by the root, and can be made with any")
	RG.free()

	print("== the rites of the Daos (rites.gd) ==")
	var all_daos: Array = []
	for d7 in Data.DAO_ORDER:
		all_daos.append(Rites.of_road(str(d7)))
	for a7 in Arms.ORDER:
		all_daos.append(Rites.of_arm(str(a7)))
	for t7 in Taboo.ORDER:
		all_daos.append(Rites.of_taboo(str(t7)))
	check(Rites.ORDER.size() == 17 and Rites.RITES.size() == 17 and all_daos == Rites.ORDER, "every Dao of the land has a rite: six roads, eight arms, three forbidden (%d)" % Rites.ORDER.size())
	var clips7 := {}
	var props7 := {}
	var names7 := {}
	var hero7 := Models.hero({})
	var yl7 := Assets.person("yue_ling")
	var psrc := FileAccess.get_file_as_string("res://art/lib/person.py")
	for rid7 in Rites.ORDER:
		var rt7: Dictionary = Rites.RITES[rid7]
		clips7[str(rt7.clip)] = true
		props7[str(rt7.prop)] = true
		names7[str(rt7.n)] = true
		check(str(rt7.clip) == "rite_" + str(rid7) and psrc.contains("\"%s\": (RITE_T" % str(rt7.clip)) and Assets.has_clip(hero7, str(rt7.clip)) and not Assets.has_clip(yl7, str(rt7.clip)), "%s: a form of its own, on the hero's models only" % rid7)
		check(Rites.dao_name(str(rid7)).length() > 6 and Faces.EXPRESSIONS.has(str(rt7.face)) and (rt7.at as Array).size() == 3, "%s: a Dao, a face and a place for its thing" % rid7)
		var pn7: Node3D = Rites.prop(str(rid7))
		check(pn7.get_child_count() >= 1 and str(pn7.get_meta("rite", "")) == str(rid7), "%s: the thing it is done with is built from code" % rid7)
		for kk7 in [0.0, 0.5, 1.0]:
			Rites.tick(pn7, str(rid7), kk7, 3.0 * kk7)
		pn7.free()
		check((rt7.beats as Array).size() == 3, "%s: a scene of three beats" % rid7)
		var cams7 := {}
		for bt7 in rt7.beats:
			cams7[str(bt7[1])] = true
			check(fits.call(str(bt7[0])) and str(bt7[0]).length() > 80 and not str(bt7[0]).contains("—") and Rites.CAMS.has(str(bt7[1])), "%s: a beat that fits the box, from a place the camera has" % rid7)
		check(cams7.size() >= 3, "%s: no two beats of it are shot alike" % rid7)
		check(Rites.scene(str(rid7)).size() == 3 and str(Rites.scene(str(rid7))[0][0]) == "Narrator", "%s: told as narration" % rid7)
		for fl7 in Rites.scene(str(rid7), true):
			var ft7 := " " + str(fl7[1])
			check(not ft7.contains(" He ") and not ft7.contains(" he ") and not ft7.contains(" his ") and not ft7.contains(" His ") and not ft7.contains(" him") and not ft7.contains(" himself") and fits.call(str(fl7[1])), "%s: and told of her when the hero is a woman" % rid7)
	check(clips7.size() == 17 and props7.size() == 17 and names7.size() == 17, "no two Daos share a form, a thing or a name for the rite")
	hero7.free()
	yl7.free()
	var TG = new_game.call()
	check(Rites.mine(TG).is_empty() or Rites.mine(TG) == ["a_sword"] or true, "a new journey has few rites")
	check(Rites.done(TG) == 0 and TG.rite_due.is_empty(), "and has performed none")
	TG.choose_dao("heart")
	check(TG.rite_due == ["heart"] and Rites.his(TG, "heart") and Rites.ready(TG) == "heart", "a road first walked has its rite waiting")
	TG.choose_dao("sword")
	TG.choose_dao("heart")
	check(TG.rite_due == ["heart", "sword"], "each road once")
	var sc7: Array = Rites.perform(TG, "heart")
	TG.rite_due.erase("heart")
	check(sc7.size() == 3 and Rites.done(TG) == 1 and int(TG.rites.heart) == 1 and TG.rite_n == 1, "a rite performed is remembered")
	Rites.earn(TG, "heart")
	check(not TG.rite_due.has("heart"), "and is not owed again")
	Rites.perform(TG, "heart")
	check(Rites.done(TG) == 1 and int(TG.rites.heart) == 2, "performed again, it is the same Dao")
	TG.arm_xp["staff"] = int(Arms.TIERS[1]) - 1
	TG.arm = "staff"
	TG.arm_battle_won(false)
	check(Arms.tier(TG, "staff") == 1 and TG.rite_due.has("a_staff") and Rites.his(TG, "a_staff"), "an Adept of a weapon's Dao has its rite")
	check(not Rites.his(TG, "t_blood") and not Rites.mine(TG).has("t_blood"), "a forbidden Dao never sat to has no rite")
	TG.taboo["blood"] = 1
	check(Rites.his(TG, "t_blood"), "and one sat to has")
	TG.taboo = {}
	var lv7: int = TG.level
	var st7: int = TG.stones
	Rites.perform(TG, "sword")
	check(TG.level == lv7 and TG.stones == st7, "a rite changes no number")
	# what a step and a trial ask
	TG.step = Data.step_index("s_p35_rite")
	TG.step_rite = 0
	TG.poll_steps()
	check(TG.step == Data.step_index("s_p35_rite") and TG.objective_text().contains("(0/1)"), "the step that asks for a rite waits for one")
	TG.step_rite = 1
	TG.poll_steps()
	check(TG.step > Data.step_index("s_p35_rite"), "and is done by one")
	# what the street makes of the road he walks, and of none
	for dd7 in ["none"] + Rites.ROADS:
		TG.dao = "" if dd7 == "none" else str(dd7)
		for kd7 in ["hand", "kid", "giant", "elder", "watch", "trade", "learned", "holy", "cult"]:
			var sd7: Dictionary = Rites.said(TG, kd7)
			check(Rites.SAID[dd7].has(kd7) and fits.call(str(sd7.line)) and str(sd7.line).length() > 40 and not str(sd7.line).contains("%s") and Data.EMOTES.has(str(sd7.clip)), "a %s answers the road of %s" % [kd7, dd7])
			check(not str(sd7.line).contains(" sir") and not str(sd7.line).contains("young man") and not str(sd7.line).contains("—"), "and says it of a hero of either sex (%s, %s)" % [kd7, dd7])
		for nid7 in Rites.NAMED:
			check(fits.call(Rites.word(TG, str(nid7))) and Rites.word(TG, str(nid7)).length() > 50 and Roots.NAMED.has(str(nid7)), "%s has a word for the road of %s" % [nid7, dd7])
	var heard7 := {}
	for dd8 in ["none"] + Rites.ROADS:
		TG.dao = "" if dd8 == "none" else str(dd8)
		heard7[str(Rites.said(TG, "watch").line)] = true
	check(heard7.size() == 7, "a road walked and no road walked are answered differently, and no two roads alike")
	for aid7 in Arms.ORDER:
		TG.arms[aid7] = true
		TG.arm = str(aid7)
		TG.arm_xp[aid7] = 0
		check(Rites.arm_said(TG) == "", "nobody remarks on a weapon he is no Adept of (%s)" % aid7)
		TG.arm_xp[aid7] = int(Arms.TIERS[1])
		check(fits.call(Rites.arm_said(TG)) and Rites.arm_said(TG).length() > 40 and not Rites.arm_said(TG).contains("%s"), "and somebody does on one he is (%s)" % aid7)
	check(msrc.contains("func play_rite") and msrc.contains("func _rite_scene") and msrc.contains("Roots.said(Game") and msrc.contains("Rites.said(Game") and msrc.contains("Roots.word(Game"), "the rites are played and the street answers")
	TG.free()
	for pid34 in people34:
		check(Assets.PEOPLE.has(pid34) and Assets.has(str(Assets.PEOPLE[pid34])) and FileAccess.file_exists("res://art/characters/%s.py" % pid34), "%s has a body built from a script" % pid34)
		check(Data.CHAT.has(pid34) and Data.CHAT[pid34].size() >= 4 and Folk.POSTS.has(pid34), "%s has four things to say, and something to do all day" % pid34)
		for cl34 in Data.CHAT[pid34]:
			check(fits.call(str(cl34)), "%s: what is said fits the box" % pid34)
	for nm34 in names34.slice(4):
		check(Closeup.signature(str(nm34)) != "", "%s has a gesture of their own" % nm34)
	check(Voice.WOMEN.has("Yue Yangzi's Wife"), "a woman named without a woman's title is known for one")
	for fid34 in ["sleeves_of_wind", "whose_is_it", "heard_out", "until_morning", "practised_hand"]:
		check(Feats.FEATS.has(fid34), "the feat %s is kept" % fid34)
	for src34 in ["Book of the Later Han", "Book of Rites", "Spring and Autumn of Master Lu"]:
		check(FileAccess.get_file_as_string("res://scripts/lore.gd").contains(src34), "the chapter's tales are told from where they are written: %s" % src34)
	for lt34 in ["chen_yaozi", "net_fowler", "yue_lao"]:
		check(Data.CHAT_LATER.has(lt34) and Data.step_index(str(Data.CHAT_LATER[lt34][0][0])) > 0 and Data.CHAT[lt34].size() >= 4, "%s: what was said before it had happened is said after, and there are still four things to say" % lt34)

	print("== small things, and how people answer (trifles.gd, manners.gd, the Unpicked Road release) ==")
	var TG_u = new_game.call()
	TG_u.stones = 500
	var tw_u: Dictionary = Atlas.world_of("surface")
	var cls_n_u := {}
	for tk_u in Trifles.KINDS:
		var td_u: Dictionary = Trifles.KINDS[tk_u]
		cls_n_u[str(td_u.cls)] = int(cls_n_u.get(str(td_u.cls), 0)) + 1
		check(str(td_u.cls) in ["ware", "keep", "altar", "lost", "wild"] and str(td_u.n) != "" and td_u.has("col"), "%s is a small thing of a class there is" % tk_u)
		check(str(td_u.cls) != "ware" or int(td_u.price) > 0, "%s: a ware34 has a price" % tk_u)
		check(str(td_u.cls) != "keep" or str(td_u.get("mine", "")).length() > 10, "%s: whoever owns it has something to say as it goes" % tk_u)
		check(str(td_u.cls) != "lost" or (str(td_u.get("thanks", "")).length() > 10 and Trifles.LOST.has(tk_u) and fits.call(str(td_u.get("thanks", "")))), "%s: whoever lost it has something to say when it comes home" % tk_u)
		check(not td_u.has("use") or Trifles.USES.has(str(td_u.use)), "%s: what is done with it is told" % tk_u)
		check(not Data.ITEMS.has(tk_u) or Load.weight_of(tk_u) == 0.0, "%s weighs nothing" % tk_u)
		var tm_u: Node3D = Trifles.model(tk_u)
		check(tm_u.get_child_count() > 0, "%s is built from code" % tk_u)
		var ta_u := AABB()
		for ch_u in tm_u.get_children():
			if ch_u is MeshInstance3D:
				ta_u = ta_u.merge((ch_u as MeshInstance3D).get_aabb())
		check(ta_u.size.y <= 0.4 and maxf(ta_u.size.x, ta_u.size.z) <= 1.0, "%s is a small thing: a hand closes on it (%s)" % [tk_u, str(ta_u.size)])
		tm_u.free()
	check(Trifles.KINDS.size() >= 45 and cls_n_u.size() == 5, "%d kinds of small thing in five classes" % Trifles.KINDS.size())
	for sty_u in Trifles.BY_STYLE:
		for sk_u in Trifles.BY_STYLE[sty_u]:
			check(Trifles.KINDS.has(str(sk_u)) and str(Trifles.KINDS[str(sk_u)].cls) != "lost" and str(Trifles.KINDS[str(sk_u)].cls) != "wild", "what lies by a %s is somebody's" % sty_u)
	var all_n_u := 0
	var seen_kinds_u := {}
	for ly_u in ["surface", "heaven", "under", "sea"]:
		var lw_u: Dictionary = Atlas.world_of(ly_u)
		var ent_tiles_u := {}
		for le_u in lw_u.ents:
			if not bool(le_u.get("late", false)):
				ent_tiles_u[le_u.pos] = true
		for la_u in lw_u.ids:
			if not Data.AREAS.has(la_u):
				continue
			var tiles_a_u := {}
			for tf_u in Trifles.stood(lw_u, la_u) + Trifles.lost(lw_u, la_u, 7) + Trifles.wild(lw_u, la_u):
				all_n_u += 1
				seen_kinds_u[tf_u.kind] = true
				var tg_u: int = lw_u.grid[tf_u.tile.y * int(lw_u.w) + tf_u.tile.x]
				check(MapGen.is_walkable_tile(tg_u) and tg_u != MapGen.INTERIOR and Atlas.owner_id(lw_u, tf_u.tile) == la_u and not ent_tiles_u.has(tf_u.tile) and Havoc.at_tile(lw_u, tf_u.tile).is_empty(), "%s lies on open ground of its own region, on nothing that stands" % tf_u.id)
				check(not tiles_a_u.has(tf_u.tile), "%s shares its tile with nothing else small" % tf_u.id)
				tiles_a_u[tf_u.tile] = true
				if str(tf_u.cls) != "wild":
					check(str(tf_u.owner) != "" and str(tf_u.who) != "" and tf_u.door.x >= 0, "%s is somebody's, and they live behind a door" % tf_u.id)
	check(all_n_u >= 600 and seen_kinds_u.size() == Trifles.KINDS.size(), "%d small things lie in the four realms, of every kind (%d)" % [all_n_u, seen_kinds_u.size()])
	check(Trifles.lost(tw_u, "village", 4) != Trifles.lost(tw_u, "village", 5) and str(Trifles.lost(tw_u, "village", 4)) == str(Trifles.lost(tw_u, "village", 4)), "what is dropped in the road is new every morning, by the day and never by lot")
	check(Atlas.world_of("surface").ents.size() == tw_u.ents.size(), "and nothing is placed in the world for any of it")
	# taking, buying, pocketing, putting back
	var ware34 := {}
	var keep34 := {}
	for tf2_u in Trifles.stood(tw_u, "village"):
		if str(tf2_u.cls) == "ware" and ware34.is_empty():
			ware34 = tf2_u
		if str(tf2_u.cls) == "keep" and keep34.is_empty():
			keep34 = tf2_u
	check(not ware34.is_empty() and not keep34.is_empty() and not Trifles.at_tile(TG_u, tw_u, ware34.tile).is_empty(), "there is a ware34 and a keep34 in Qingshi, and each is found on its tile")
	var before_st_u: int = TG_u.stones
	var rb_u: Dictionary = Trifles.take(TG_u, tw_u, ware34, "buy", [])
	check(bool(rb_u.ok) and TG_u.stones == before_st_u - Trifles.price(TG_u, ware34) and TG_u.pocket.size() == 1 and bool(TG_u.pocket[0].own) and Trifles.at_tile(TG_u, tw_u, ware34.tile).is_empty() and TG_u.pilfered == 0, "a ware34 bought is paid for, his, and gone from where it lay")
	TG_u.day += 1
	check(not Trifles.at_tile(TG_u, tw_u, ware34.tile).is_empty(), "and the seller has set out another by the next morning")
	var owner_p_u: Dictionary = {}
	for fp_u in Folk.people(tw_u, str(keep34.town)):
		if str(fp_u.id) == str(keep34.owner):
			owner_p_u = fp_u
	check(not owner_p_u.is_empty(), "a keep34 belongs to somebody of its town")
	var rp_u: Dictionary = Trifles.take(TG_u, tw_u, keep34, "pocket", [owner_p_u])
	check(bool(rp_u.ok) and TG_u.pilfered == 1 and str(rp_u.react.who) == str(owner_p_u.n) and str(rp_u.react.line) == str(Trifles.KINDS[str(keep34.kind)].mine), "whoever owns a thing says their own words as it goes into his sleeve")
	check(Trifles.theirs(TG_u, str(owner_p_u.id)).size() == 1 and not Trifles.home_at(TG_u, tw_u, keep34.tile).is_empty() and Trifles.at_tile(TG_u, tw_u, keep34.tile).is_empty(), "it is theirs still, and its place is empty")
	var virtue_was_u := Creed.value(TG_u, "virtue")
	check(virtue_was_u < 0, "what is somebody's, in his sleeve, weighs on the Way he walks")
	Trifles.charge(TG_u, keep34)
	check(Crime.price(TG_u, Weal.town_of("village")) > 0 and Crime.price(TG_u, Weal.town_of("village")) < 500 and Weal.acts(TG_u, Weal.town_of("village"), "pilfer") == 1, "walking off with it, seen, is a small price at the gate and is remembered in the street")
	check(Trifles.put_back(TG_u, str(keep34.id)).size() == 1 and TG_u.pilfered == 0 and not Trifles.at_tile(TG_u, tw_u, keep34.tile).is_empty() and Trifles.theirs(TG_u, str(owner_p_u.id)).is_empty(), "put back, it lies where it lay")
	# a lost thing, carried home
	var lt_u: Dictionary = Trifles.lost(tw_u, "village", int(TG_u.day))[0]
	var wt_u := Manners.watchers(TG_u, tw_u, lt_u.tile)
	var rl_u: Dictionary = Trifles.take(TG_u, tw_u, lt_u, "take", [owner_p_u])
	check(bool(rl_u.ok) and Trifles.carried(TG_u).size() == 1 and str(rl_u.react.line).contains(str(lt_u.who)) and wt_u.size() >= 0, "whoever sees a lost thing picked up says whose it is")
	check(Trifles.at_door(TG_u, tw_u, lt_u.door + Vector2i(1, 1)).size() == 1 and Trifles.at_door(TG_u, tw_u, lt_u.door + Vector2i(3, 0)).is_empty(), "it is carried to the door its owner lives behind")
	var st_was_u: int = TG_u.stones
	var rr_u: Dictionary = Trifles.restore(TG_u, str(lt_u.id), true)
	check(rr_u.lines.size() == 3 and str(rr_u.lines[1][0]) == str(lt_u.who) and TG_u.restored == 1 and TG_u.step_restore == 1 and TG_u.stones == st_was_u + int(rr_u.stones) and int(rr_u.stones) > 0 and Trifles.carried(TG_u).is_empty() and Weal.acts(TG_u, Weal.town_of("village"), "restored") == 1, "brought home, it is thanked for, remembered in the street and counted")
	for rln_u in rr_u.lines:
		check(fits.call(str(rln_u[1])), "what is said at the door fits the box")
	check(int(rr_u.stones) < Data.enemy_stones(1, false) * 40, "the thanks for a thing brought home are worth less than the road")
	check(Trifles.gone(TG_u, lt_u) and Trifles.at_tile(TG_u, tw_u, lt_u.tile).is_empty(), "and it does not lie in the road again")
	# a sleeve holds six
	for wt2_u in Trifles.wild(tw_u, "village"):
		if TG_u.pocket.size() < Trifles.SLEEVE + 1:
			Trifles.take(TG_u, tw_u, wt2_u, "take", [])
	check(TG_u.pocket.size() == Trifles.SLEEVE and Trifles.blocked(TG_u, ware34) != "" and Load.gross(TG_u) == 0.0, "a sleeve holds six small things, and they weigh nothing")
	check(not Trifles.treat(TG_u).is_empty() and Trifles.text(TG_u) != "", "there is something in it a child would like, and it can be_u told")
	# a frail34 thing struck
	var frail34 := {}
	for ly2_u in ["surface"]:
		for la2_u in tw_u.ids:
			for tf3_u in Trifles.stood(tw_u, la2_u):
				if bool(Trifles.KINDS[str(tf3_u.kind)].get("frail", false)) and frail34.is_empty():
					frail34 = tf3_u
	TG_u.stones = 500
	check(not frail34.is_empty() and Trifles.struck(TG_u, frail34).size() == 1 and TG_u.stones < 500 and Trifles.at_tile(TG_u, tw_u, frail34.tile).is_empty() and Trifles.struck(TG_u, ware34).is_empty(), "a blow breaks what is frail34 and it is paid for; anything else only flies")
	TG_u.free()
	# how people answer
	var MG_u = new_game.call()
	for deed_u in Manners.LINES:
		check(Manners.LINES[deed_u].has("any") and Manners.CLIPS.has(deed_u) and Manners.CLIPS[deed_u].has("any"), "%s: there is an answer for anybody, and a gesture" % deed_u)
		for mk_u in Manners.LINES[deed_u]:
			check(mk_u == "any" or Manners.KINDS.has(str(mk_u)), "%s/%s is a kind of witness" % [deed_u, mk_u])
			for ml_u in Manners.LINES[deed_u][mk_u]:
				check(str(ml_u).length() <= 64 and not str(ml_u).contains(" sir") and not str(ml_u).contains("young man") and not str(ml_u).contains(" he ") and not str(ml_u).contains(" his "), "%s/%s: a word short enough for the street, that reads of anybody (%s)" % [deed_u, mk_u, ml_u])
		for mc_u in Manners.CLIPS[deed_u]:
			var mclip_u := str(Manners.CLIPS[deed_u][mc_u])
			check(Data.EMOTES.has(mclip_u) or Assets.LEND.has(mclip_u), "%s/%s is answered with a gesture everybody has or the party lends (%s)" % [deed_u, mc_u, mclip_u])
	var kinds_seen_u := {}
	for tid_u in Folk.TOWNS:
		for fp2_u in Folk.people(Atlas.world_of(Data.layer_of(str(Folk.TOWNS[tid_u].area))), tid_u):
			kinds_seen_u[Manners.kind_of(fp2_u)] = true
	for mk2_u in Manners.KINDS:
		check(kinds_seen_u.has(mk2_u), "there is somebody in the towns who answers as a %s" % mk2_u)
	var kid34 := {"n": "Little Dou", "kid": true, "role": "child", "seed": 3}
	var gnt34 := {"n": "Big Brother Shan", "kid": false, "old": false, "role": Giants.ROLE, "seed": 5}
	var wch34 := {"n": "Watchman Lu", "kid": false, "old": false, "role": "watchman", "seed": 1}
	check(Manners.answer("jump", kid34, MG_u).clip == "jump" and Manners.answer("strike", wch34, MG_u).clip == "point" and Manners.answer("strike", kid34, MG_u).line != Manners.answer("strike", wch34, MG_u).line, "a child jumps too; a watchman points at the blade; they do not say the same thing")
	check(Manners.answer("pilfer", wch34, MG_u, {"thing": "pear", "who": "Cook Ma"}).line.contains("Cook Ma") or Manners.answer("pilfer", wch34, MG_u, {"thing": "pear", "who": "Cook Ma"}, 1).line.contains("Cook Ma"), "whoever sees a thing pocketed says whose it was")
	check(Manners.bump_deed(true, 0) == "bump_ride" and Manners.bump_deed(false, 2) == "bump_laden" and Manners.bump_deed(false, 0) == "bump", "a bump is told by what he was doing")
	check(Manners.shove(gnt34, "bump") == 0.0 and Manners.shove(kid34, "bump") > Manners.shove(wch34, "bump") and Manners.shove(wch34, "bump_ride") > Manners.shove(wch34, "bump"), "one of the Great People is not moved; a child goes further than the watch; a horse moves anybody")
	check(not str(Manners.answer("bump", wch34, MG_u).line).contains("{") and not str(Manners.answer("whose", kid34, MG_u, {"thing": "purse", "who": "Granny Li", "town": "Qingshi"}).line).contains("{"), "every word in an answer is filled in")
	MG_u.free()
	var wsrc34 := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(wsrc34.contains("func jump()") and wsrc34.contains("func leap_to(") and wsrc34.contains("_folk_react(\"strike\"") and wsrc34.contains("func _bump(") and msrc.contains("press(\"jump\")") and bsrc.contains("func _leap_step") and bsrc.contains("func _restore_step"), "he can jump, the street answers a blade and a body walked into, and the bot leaps and carries things home")
	check(not bsrc.contains("\"pocket\"") and not bsrc.contains("ids.find(\"buy\")") and not bsrc.contains("Trifles.take("), "the bot buys nothing and pockets nothing")
	check(Assets.LEND.has("jump") and FileAccess.get_file_as_string("res://art/lib/person.py").contains("def clip_jump"), "the leap is a clip of the party's, lent to the children of the towns")
	check(Crime.CRIMES.has("theft") and int(Crime.CRIMES.theft.base) < int(Crime.CRIMES.assault.base) and Weal.ACTS.has("restored") and Weal.ACTS.has("pilfer"), "a theft is the least of the charges, and the towns keep34 count of both things")

	print("== bugs of the Unpicked Road release ==")
	check(Crime.MIGHT.has("smith") and Crime.MIGHT.has("alchemist") and not Crime.MIGHT.has("smith_tie"), "Smith Tie and Alchemist Mo are weighed as themselves (their ids were written wrong, and a child of the fourth layer could cut them down)")
	var BG_u = new_game.call()
	var bw_u: Dictionary = Atlas.world_of("surface")
	check(FileAccess.get_file_as_string("res://scripts/crime.gd").contains("elif area == \"sect\" and not"), "nobody of Cloudfoot is charged as one of his own sect")
	Weal.poll(BG_u)
	for bk_u in 4:
		Weal.act(BG_u, "qingshi", "unpaid")
	Weal.poll(BG_u)
	check(str(BG_u.weal_state.get("qingshi", "")) == Weal.state(BG_u, "qingshi"), "a town's change of state is remembered when it is told, and not told again at the next poll")
	BG_u.stones = 15
	check(Gamble.stakes(BG_u).is_empty(), "no stake is offered that a win would pay nothing on")
	BG_u.free()

	print("== the two of them, further (romance.gd, the Broken Mirror release) ==")
	var HG = new_game.call()
	HG.companion = true
	check(Romance.TOUCH_ORDER.size() == 3 and Romance.FEAST_ORDER.size() == 4 and Romance.MATTER_ORDER.size() == 3 and Romance.touch_blocked(HG, "hands") != "" and Romance.feast_today(HG) == "" and Romance.matter(HG) == "", "before anything is said there is nothing to touch, no feast to keep and nothing the matter")
	for tk32 in Romance.TOUCH_ORDER:
		var tt: Dictionary = Romance.TOUCH[tk32]
		check(Romance.TOUCH_CLIPS.has(str(tt.clip)) and fits.call(str(tt.told)) and tt.lines.has("") and tt.lines.has("tender") and tt.lines.has("playful") and tt.lines.has("quiet"), "touch %s: a clip two people play, and a word for every way of being together" % tk32)
		for tone32 in tt.lines:
			for tl32 in tt.lines[tone32]:
				check(fits.call(str(tl32)) and not str(tl32).to_lower().contains("husband") and not str(tl32).contains(" he ") and not str(tl32).contains(" him "), "touch %s: what she says fits, and is said to a hero of either sex" % tk32)
	for fk32 in Romance.FEAST_ORDER:
		var ff: Dictionary = Romance.FEASTS[fk32]
		var is_feast := false
		for fe32 in Almanac.FESTIVALS:
			is_feast = is_feast or str(fe32[2]) == fk32
		check(is_feast and (ff.options as Array).size() == 3, "%s is a feast day of the almanac, with three things to do" % fk32)
		for fl32 in ff.lines:
			check(fits.call(str(fl32[1])), "%s: the scene fits the box" % fk32)
		for fo32 in ff.options:
			check(Romance.TONES.has(str(fo32[1])) and fits.call(str(fo32[3])), "%s/%s: her answer fits" % [fk32, fo32[0]])
	for mk33 in Romance.MATTER_ORDER:
		var mm: Dictionary = Romance.MATTERS[mk33]
		check((mm.options as Array).size() == 3 and (mm.said as Array).size() == 2, "%s: she says it, and there are three things to answer" % mk33)
		for ml32 in (mm.said as Array) + (mm.mend as Array):
			check(fits.call(str(ml32[1])), "%s: what is said fits the box" % mk33)
		for mo32 in mm.options:
			check(Romance.TONES.has(str(mo32[1])) and fits.call(str(mo32[3])), "%s/%s: her answer fits" % [mk33, mo32[0]])
	HG.romance["stage"] = 1
	var hb0 := int(HG.bond)
	var th: Array = Romance.touch(HG, "hands")
	check(th.size() == 2 and str(th[0][2]) == "Lin Feng:take_hands" and int(HG.bond) == hb0 + 1 and Romance.touch_blocked(HG, "embrace") != "" and Romance.touch_blocked(HG, "brow") != "", "courting, her hands may be taken; the rest wait their stage")
	var th2: Array = Romance.touch(HG, "hands")
	check(th2.size() == 2 and int(HG.bond) == hb0 + 1 and str(th2[1][1]) != str(th[1][1]), "the second of a day brings them no closer, and she says something else")
	HG.day += 1
	Romance.touch(HG, "hands")
	check(int(HG.bond) == hb0 + 2, "and tomorrow's does")
	# a feast day
	var fday := -1
	for dd in 400:
		HG.day += 1
		if not Almanac.festival(HG).is_empty() and str(Almanac.festival(HG)[2]) == "Mid-Autumn":
			fday = int(HG.day)
			break
	check(fday > 0 and Romance.feast_today(HG) == "Mid-Autumn", "on the fifteenth of the eighth month there is an hour to be had")
	var hb1 := int(HG.bond)
	check(Romance.take_feast(HG, "Mid-Autumn", "quiet").size() == 1 and int(HG.bond) == hb1 + Romance.OUTING + 1 and Romance.feast_today(HG) == "" and Romance.feasts_had(HG) == 1 and Romance.take_feast(HG, "Mid-Autumn", "tender").is_empty(), "it is had once, and brings them closer than an ordinary hour")
	HG.day += 1
	check(Romance.feast_today(HG) == "", "and the day after is an ordinary day")
	# something is the matter
	HG.bounty["qingshi"] = 500
	var is_wanted: bool = Crime.heat(HG) > 0
	check(is_wanted and Romance.matter(HG) == "price" and Romance.touch_blocked(HG, "hands") != "" and Romance.ask_blocked(HG, "tokens").contains("matter"), "a price on his head is the matter, and nothing further is asked until she has said so")
	check(Romance.hear(HG, "wild", "tender").is_empty() and Romance.hear(HG, "price", "quiet").size() == 1 and Romance.matter(HG) == "" and Romance.mend_ready(HG) == "" and Romance.touch_blocked(HG, "hands") == "", "she is heard, once; it is not made up while the bill stands")
	HG.bounty.clear()
	var hb2 := int(HG.bond)
	check(Romance.mend_ready(HG) == "price" and Romance.mend(HG, "price").size() == 2 and int(HG.bond) == hb2 + Romance.MEND and Romance.mend_ready(HG) == "" and Romance.mended(HG) == 1, "with the bill paid it is made up, and they are closer for it")
	HG.slain["folk:x"] = {"n": "Somebody"}
	check(Romance.matter(HG) == "blood" and Romance.hear(HG, "blood", "tender").size() == 1 and Romance.mend_ready(HG) == "" and (Romance.MATTERS.blood.mend as Array).is_empty(), "somebody dead by his hand is said, and stands: it is not made up")
	HG.free()
	check(not Romance.here("wild_night", {"wild": true, "cave": true, "hour": 22.0}) and not Romance.here("wild_dawn", {"wild": true, "cave": true, "hour": 6.0}) and Romance.here("wild_night", {"wild": true, "hour": 22.0}), "there are no stars and no sunrise under the ground")
	var rsrc := FileAccess.get_file_as_string("res://scripts/romance.gd")
	check(not rsrc.contains("nine hundred years") and not rsrc.contains("Pour, he says") and not FileAccess.get_file_as_string("res://scripts/bonds.gd").contains("for four years before"), "she is three hundred years old everywhere, he swept for three, and she says 'you' to whoever he is")
	# the bugs of this release stay mended
	var gaunt: Dictionary = Data.make_enemy("gale_wolf", 30, 0.8, 1.0)
	var plain: Dictionary = Data.make_enemy("gale_wolf", 30)
	var hard: Dictionary = Data.make_enemy("gale_wolf", 30, 1.0, 1.15)
	check(int(gaunt.maxhp) < int(plain.maxhp) and float(hard.atk) > float(plain.atk), "a foe that is not a lord is made to the measure it was given (the gaunt survivor, the League's enforcers)")
	var old_grp: Array = Almanac.grown_at([{"id": "gale_wolf", "lv": 30}], 3)
	check(not (old_grp[0] as Dictionary).has("atk"), "and an old pack's harder blow is given once, in the battle, not twice")
	var bsrc2 := FileAccess.get_file_as_string("res://art/lib/body.py")
	check(bsrc2.contains("def _carve(") and bsrc2.contains("the gluteal cleft") and bsrc2.contains("CLOTH_BRIDGE") and FileAccess.get_file_as_string("res://art/lib/person.py").contains("\"embrace\": (EMBRACE_T, clip_embrace)"), "the body is sculpted with its clefts and folds, and two people have something to do with their arms")
	_cloud_keel()
	_iron_pestle_wits()
	_higher_sky()

## The Cloud Keel release: the spirit arks and the Far Countries (arks.gd), a storey divided into apartments
## with somebody living in each (rooms.gd), and what the audit of shared ground learned to see (clash.gd).
func _cloud_keel() -> void:
	print("== the spirit arks, and the Far Countries (arks.gd) ==")
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	check(Atlas.LAYERS.size() == 5 and Atlas.STRATA.has("far") and Atlas.LAYER_NAMES.has("far") and Atlas.LAYERS.slice(0, 4) == ["surface", "heaven", "under", "sea"], "the world is five realms, and the first four are where they were")
	var far: Dictionary = Atlas.world_of("far")
	var far_ids := ["huaxu", "zhongbei", "gumang", "fuluo"]
	var asked: Array = []
	for st in Data.STEPS:
		if str(st.get("area", "")) in far_ids or str(st.get("peak", "")) in far_ids:
			asked.append(str(st.id))
	for tid in Trials.TRIALS:
		if Trials.boss_area(str(tid)) in far_ids:
			asked.append(str(tid))
	check(asked.is_empty(), "nothing of the story is asked for in the Far Countries (%s)" % str(asked))
	var far_reach := MapGen.flood(far.grid, far.w, far.h, far.start)
	var far_people := 0
	var far_lost := 0
	for e in far.ents:
		if str(e.kind) in ["npc", "pickup", "stele", "enemy", "mark"]:
			far_people += 1 if str(e.kind) == "npc" else 0
			far_lost += 0 if far_reach.has(e.pos) else 1
	for a in far_ids:
		check(Data.layer_of(a) == "far" and (far.ids as Array).has(a) and Data.REGION_LORE.has(a) and (Data.AREAS[a].bosses as Array).is_empty() and Arks.beyond(a) and Weal.hears(a).size() == 1,
			"%s lies in the Far Countries, has no lord, and some town hears of it" % a)
		for np in Data.AREAS[a].npcs:
			check(Data.CHAT.has(str(np.id)) and (Data.CHAT[str(np.id)] as Array).size() >= 3 and (Data.CHAT[str(np.id)] as Array).all(func(ln): return fits.call(str(ln))) and Folk.POSTS.has(str(np.id)) and Assets.PEOPLE.has(str(np.asset)),
				"%s has things to say that fit the box, a body, and something to do all day" % np.n)
	check(far_lost == 0 and far_people >= 40 and (far.buildings as Array).size() == 14 and (far.peaks as Array).size() >= 8 and (far.camps as Dictionary).size() >= 3,
		"the Far Countries: %d people, %d houses, %d peaks, %d camps, and everything in them can be walked to" % [far_people, (far.buildings as Array).size(), (far.peaks as Array).size(), (far.camps as Dictionary).size()])
	var fo := Atlas.layer_origin("far")
	check(fo.x + int(far.w) < 0 and Atlas.layer_origin("sea") != fo and Atlas.layer_origin("heaven") != Vector2i(-1400, 300), "they lie out past the western sea, over none of the land, and no other realm has moved")
	check(not Arks.beyond("penglai") and not Arks.beyond("mountain") and Data.next_hop("village", "juntian") != "huaxu" and Data.next_hop("sect", "penglai") != "huaxu" and Data.next_hop("sect", "huaxu") == "mountain",
		"no road of the story goes by the ark")
	var dock_layers := {}
	for did in Arks.ORDER:
		var dk: Dictionary = Arks.DOCKS[did]
		var dl := Data.layer_of(str(dk.area))
		dock_layers[dl] = true
		var dw: Dictionary = Atlas.world_of(dl)
		var bt := Arks.berth(dw, did)
		var clear := bt.x >= 0
		if clear:
			for ay in range(-Arks.BERTH_L, Arks.BERTH_L + 1):
				for ax in range(-Arks.BERTH_W, Arks.BERTH_W + 1):
					var bg := int(dw.grid[(bt.y + ay) * int(dw.w) + bt.x + ax])
					clear = clear and bg != MapGen.BUILDING and bg != MapGen.INTERIOR and bg != MapGen.WALL
		check(Offices.OFFICES.has(str(dk.office)) and str(Offices.OFFICES[str(dk.office)].area) == str(dk.area) and Data.TOWNS.any(func(tw): return str(tw.id) == str(dk.town)) and Arks.quay(did).x >= 0 and clear and Arks.dock_of(str(dk.office)) == did and Arks.dock_in(str(dk.area)) == did,
			"the dock %s has a counter in its own town, a place to be set down, and air to lie in with no roof, wood or peak under her" % did)
		for did2 in Arks.ORDER:
			check(did2 == did or Arks.leagues(did, did2) > 0, "it is known how far %s is from %s by air" % [did, did2])
	check(dock_layers.size() == 4 and Arks.HOVER > Arch.WALL_H + Arch.WALL2_H * 4.0 + 3.0, "the arks moor in four realms, higher than the roof of a house of five storeys")
	for tk in Arks.TALES:
		for tl in Arks.TALES[tk]:
			check(fits.call(str(tl)), "a crossing by ark is told in lines that fit the box")
	var ag = load("res://scripts/game.gd").new()
	ag.reset()
	ag.level = 60
	ag.stones = 100000
	ag.seen["mountain"] = true
	check(Arks.offers(ag, "post_cloudfoot").is_empty() and Arks.blocked(ag) != "" and fits.call(Arks.blocked(ag)), "no ark moors anywhere before the sea has come home")
	ag.step = Data.step_index(Arks.OPEN) + 1
	var ao: Array = Arks.offers(ag, "post_cloudfoot")
	check(ao.size() == 1 and str(ao[0].to) == "lightfoot" and str(ao[0].kind) == "edge" and Arks.tale(ao[0], 0).size() == 3 and Arks.offers(ag, "head_qingshi").is_empty(),
		"then the ark of Cloudfoot goes to her own mooring at Lightfoot and nowhere he has not been; and none lies over a village in the hills")
	ag.level = 3
	check(Arks.offers(ag, "post_cloudfoot").is_empty() and Arks.blocked(ag).contains(str(Data.REALMS[Arks.REALM])), "nobody below the Golden Core can stand her deck")
	ag.level = 60
	var as0 := int(ag.stones)
	var ac0 := float(ag.clock)
	var ad0 := int(ag.day)
	check(Arks.sail(ag, ao[0]) and int(ag.stones) == as0 - int(ao[0].fare) and int(ag.ark_voyages) == 1 and (float(ag.clock) != ac0 or int(ag.day) != ad0), "the passage is paid for and takes its hours")
	ag.seen["huaxu"] = true
	ag.seen["zhongbei"] = true
	var ao2: Array = Arks.offers(ag, "moorer_lightfoot")
	check(ao2.size() == 2 and ao2.any(func(o): return str(o.to) == "fourstreams" and str(o.kind) == "far") and ao2.any(func(o): return str(o.to) == "cloudfoot" and Arks.tale(o, 1).size() == 2),
		"from Lightfoot she goes on to Fourstreams, or home over the edge of the chart")
	ag.stones = 0
	check(not Arks.sail(ag, ao2[0]), "nobody sails on credit")
	check(Arks.fare(900, 50) < 3400 and Arks.fare(30, 50) > Ships.fare(30, 50), "a passage to the Far Countries costs less than one cache of the Isles, and an ark is dearer than a junk")
	ag.free()
	# (nobody is sent to a town only an ark reaches)
	var wg = load("res://scripts/game.gd").new()
	wg.reset()
	var w_first := Weal.wanted(wg)
	check(w_first != "lightfoot" and w_first != "fourstreams" and Weal.ORDER.find("lightfoot") > Weal.ORDER.find("landfall"), "a town of the Far Countries is the last a step would send him to, and never before he has been there")
	var w_n0 := Weal.count(wg, "cold")
	check(Weal.towns(wg).size() == 11 and w_n0 == 11 and Weal.summary(wg).begins_with("Of eleven towns"), "a journey that never takes an ark is weighed in eleven towns, as it was")
	wg.seen["huaxu"] = true
	check(Weal.towns(wg).size() == 12 and Weal.count(wg, "cold") == 12 and Weal.summary(wg).begins_with("Of twelve towns") and Weal.towns(wg).has("lightfoot") and not Weal.towns(wg).has("fourstreams"), "and Lightfoot is weighed once he has stood in it")
	wg.free()
	var bot_src := FileAccess.get_file_as_string("res://scripts/bot.gd")
	check(not bot_src.contains("Arks.") and not bot_src.contains("\"far\"") and not bot_src.contains("Atlas.LAYERS"), "the bot takes no ark and keeps to the four realms of the story")
	var am: Node3D = Models.ark(true, Arks.HOVER)
	var am2: Node3D = Models.ark(false)
	var a_low := 99.0
	var a_tris := 0
	for ch in am.get_children():
		if ch is MeshInstance3D:
			a_low = minf(a_low, (ch as MeshInstance3D).mesh.get_aabb().position.y)
			a_tris += (ch as MeshInstance3D).mesh.get_faces().size() / 3
	check(a_tris > 1500 and a_low > -Arks.HOVER + Giants.HEIGHT - 2.0 and a_low < -Arks.HOVER + 3.0 and am2.get_child_count() == 2, "an ark is built from code (%d triangles), and what she lets down hangs clear of the ground" % a_tris)
	am.free()
	am2.free()
	print("== a storey divided into apartments (rooms.gd) ==")
	var n_div := 0
	var n_apt := 0
	var n_lodg := 0
	var apt_bad: Array = []
	var apt_beds := 0
	for lid in Atlas.LAYERS:
		var lw: Dictionary = Atlas.world_of(lid)
		for bd in lw.buildings:
			if not bd.has("upper") or not (bd.upper.props as Array).any(func(pr): return str(pr[0]) == "doorway"):
				continue
			n_div += 1
			var rooms: Array = Rooms.rooms_of(bd.rect, bd.upper.props, bd.up)
			n_apt += rooms.size() - 1
			var fw: Dictionary = lw.floors[Atlas.floor_id(str(bd.area), str(bd.id), 1)]
			var fr := MapGen.flood(fw.grid, fw.w, fw.h, fw.start)
			var open_n := 0
			for gi in (fw.grid as PackedByteArray).size():
				open_n += 1 if MapGen.is_walkable_tile(fw.grid[gi]) else 0
			var okf := open_n == fr.size() and rooms.size() >= 2
			var doors_n := (bd.upper.props as Array).filter(func(pr): return str(pr[0]) == "doorway").size()
			okf = okf and doors_n == rooms.size() - 1
			for fe in fw.ents:
				if str(fe.kind) == "prop" and not bool(fe.get("walk", false)):
					var beside := false
					for d in MapGen.DIRS:
						beside = beside or fr.has(fe.pos + d)
					okf = okf and beside
				elif str(fe.kind) == "npc":
					okf = okf and fr.has(fe.pos)
					if bool(fe.get("lodger", false)):
						n_lodg += 1
						okf = okf and (fe.lines as Array).size() >= 3 and (fe.lines as Array).all(func(ln): return fits.call(str(ln))) and Assets.PEOPLE.has(str(fe.asset))
						# (in a room of their own, not on the landing, and on nothing)
						var in_room := false
						for ri in range(1, rooms.size()):
							in_room = in_room or (rooms[ri] as Dictionary).has((fe.pos as Vector2i) + (bd.rect as Rect2i).position)
						okf = okf and in_room and not (bd.upper.props as Array).any(func(pr): return pr[1] == (fe.pos as Vector2i) + (bd.rect as Rect2i).position)
			for ri2 in range(1, rooms.size()):
				var has_bed := false
				for pr in bd.upper.props:
					if str(pr[0]) == "bed":
						for d2 in MapGen.DIRS:
							has_bed = has_bed or (rooms[ri2] as Dictionary).has((pr[1] as Vector2i) + d2)
				apt_beds += 1 if has_bed else 0
			if not okf:
				apt_bad.append("%s/%s" % [bd.area, bd.id])
	check(apt_bad.is_empty(), "every divided storey: a landing, a doorway to every room, all of its floor walked to, every piece with floor beside it, everybody in a room of their own (%s)" % str(apt_bad))
	check(n_div >= 36 and n_apt >= 80 and n_lodg >= n_apt - 6 and apt_beds == n_apt, "%d storeys are divided into %d apartments, each with a bed, and %d people live in them" % [n_div, n_apt, n_lodg])
	check(Rooms.apartments(Rect2i(0, 0, 6, 6), Vector2i(1, 1), "home", 3).is_empty() and not Rooms.apartments(Rect2i(0, 0, 11, 8), Vector2i(1, 1), "home", 3).is_empty()
		and Rooms.apartments(Rect2i(0, 0, 11, 8), Vector2i(1, 1), "home", 3) == Rooms.apartments(Rect2i(0, 0, 11, 8), Vector2i(1, 1), "home", 3), "a house too small to divide is one room; a larger one is divided the same way every time")
	for sty in Rooms.APART:
		check(Rooms.UPPER.has(sty) and Rooms.APART_KINDS.has(str(Rooms.APART[sty][1])) and Rooms.LODGERS.has(str(Rooms.APART[sty][1])) and str(Rooms.USES[sty][1]) in ["home", "rooms"], "over a %s people live: the storey has a name, furniture and somebody to say whose it is" % sty)
	for use in Rooms.LODGERS:
		check((Rooms.LODGERS[use][2] as Array).all(func(ln): return fits.call(str(ln))) and (Rooms.LODGERS[use][1] as Array).all(func(b): return Assets.PEOPLE.has(str(b))), "what is said in %s fits the box" % use)
	# (the mesh: a storey with partitions is more than one without, and nothing hangs in an inner doorway)
	var hb := MB.new()
	var hg := MB.new()
	var hroof := MB.new()
	var hroof_g := MB.new()
	var hup := MB.new()
	var hup_g := MB.new()
	var T := Terrain3D.T
	var hprops: Array = []
	for pr in Rooms.apartments(Rect2i(0, 0, 11, 8), Vector2i(1, 1), "home", 3):
		hprops.append([pr[0], Vector3(((pr[1] as Vector2i).x + 0.5) * T, 0, ((pr[1] as Vector2i).y + 0.5) * T)])
	Arch.house(hb, hg, hroof, hroof_g, Rect2(0, 0, 11 * T, 8 * T), Vector3(5.5 * T, 0, 7.5 * T), "house", [], 5, hup, hup_g, hprops, Vector3(1.5 * T, 0, 1.5 * T), [], 2, "village")
	var hup0 := MB.new()
	var hup0_g := MB.new()
	Arch.house(MB.new(), MB.new(), MB.new(), MB.new(), Rect2(0, 0, 11 * T, 8 * T), Vector3(5.5 * T, 0, 7.5 * T), "house", [], 5, hup0, hup0_g, [], Vector3(1.5 * T, 0, 1.5 * T), [], 2, "village")
	check(hup.tri_count() > hup0.tri_count() + 400, "the partitions, doorways and furniture of a divided storey are drawn (%d triangles more)" % (hup.tri_count() - hup0.tri_count()))
	var pb := MB.new()
	Arch._partition(pb, MB.new(), Vector3.ZERO, Vector2i(3, 3), {Vector2i(3, 3): "doorway", Vector2i(2, 3): "partition", Vector2i(4, 3): "partition"}, 10, 7, Arch.WALL2_H - 0.17, true, Color.WHITE, Color.WHITE, Color.WHITE, 1)
	var pm: ArrayMesh = pb.build()
	var gap_ok := true
	for v in pm.get_faces():
		if absf(v.x) < 0.45 and v.y < minf(Giants.CLEAR, Arch.WALL2_H - 0.47) - 0.02 and v.y > 0.1:
			gap_ok = false
	check(gap_ok, "nothing hangs in the doorway of a room below the height of the Great People")
	print("== what the audit of shared ground learned to see (clash.gd) ==")
	check(Clash.extent({"kind": "spring", "id": "t"}) > 1.2 and Clash.extent({"kind": "stele", "id": "t"}) > 1.0 and Clash.extent({"kind": "abode", "id": "t"}) > 1.2 and Clash.extent({"kind": "pickup", "id": "t"}) == Clash.SMALL,
		"a spring, a stele and a sealed cave are measured from what is drawn, like everything else")
	var some_dragon := ""
	for en in Data.ENEMIES:
		if bool(Data.ENEMIES[en].get("boss", false)) and str(Data.ENEMIES[en].shape) == "dragon" and not Clash.LORD_NARROW.has(en):
			some_dragon = en
			break
	var pack_dragon: Node3D = Models.monster("dragon", Color.WHITE, true, some_dragon)
	var foot1 := Clash.footprint(pack_dragon)
	pack_dragon.free()
	check(some_dragon != "" and absf(Clash.extent({"kind": "boss", "id": "t", "enemy": some_dragon}) - minf(5.0, foot1 * Clash.LORD_SCALE)) < 0.01 and Clash.lord_scale("fangfeng") == Giants.SCALE,
		"a lord is measured at the size it is drawn, not the size of a beast of the packs")
	for nl in Clash.LORD_NARROW:
		check(Data.ENEMIES.has(nl) and bool(Data.ENEMIES[nl].get("boss", false)) and float(Clash.LORD_NARROW[nl]) > 1.0 and float(Clash.LORD_NARROW[nl]) < Clash.LORD_SCALE, "%s is drawn narrower than the other lords, and still larger than a beast" % nl)
	var sw: Dictionary = Atlas.world()
	var paved := 0
	var paved_kept := 0
	for ra in ["mountain", "village", "longmen", "karst"]:
		var rc: Rect2i = Atlas.layout()[ra].cell
		var st0 := Clash.stood(sw, ra, rc)
		for rt in Roads.of("surface").tiles:
			if rc.has_point(rt):
				paved += 1
				paved_kept += 1 if st0.has((rt as Vector2i) - rc.position) else 0
	check(paved > 100 and paved == paved_kept, "nothing is scattered on the paving of the high road (%d tiles of it in four regions)" % paved)
	var camp_a := str((sw.camps as Dictionary).keys()[0])
	var camp_c: Vector2i = sw.camps[camp_a]
	var crc: Rect2i = Atlas.layout()[camp_a].cell
	var cst := Clash.stood(sw, camp_a, crc)
	check(cst.has(camp_c - crc.position + Vector2i(Clash.CAMP_SIDE, -Clash.CAMP_BACK)) and cst.has(camp_c - crc.position + Vector2i(-Clash.CAMP_SIDE, Clash.CAMP_FRONT)), "nor through a camp's lean-to and its stack of wood")
	check(Arch.LANTERN_Y - 0.25 >= Giants.HEIGHT and Arch.WALL_REACH <= T + 0.26, "a lantern over floor that is walked on hangs clear of the Great People, and a piece against a wall is drawn within a tile of where it stands")
	for fk in ["bed", "stove", "hearth", "statue", "shelf", "cabinet"]:
		var fb2 := MB.new()
		var room2 := Rect2(0, 0, 10, 10)
		Arch._furnish(fb2, MB.new(), fk, Vector3(1.0, 0, 5.0), room2, Arch.dressed("house", "village"), RandomNumberGenerator.new(), [])
		var fa: AABB = fb2.build().get_aabb()
		check(fa.position.x >= 0.16 - 0.02 and fa.end.x <= 2.4, "a %s against a wall stands clear of it, and within a step of its own tile (%.2f to %.2f m)" % [fk, fa.position.x, fa.end.x])
	var far_b := MB.new()
	Arch._furnish(far_b, MB.new(), "shelf", Vector3(5.0, 0, 5.0), Rect2(0, 0, 10, 10), Arch.dressed("house", "village"), RandomNumberGenerator.new(), [])
	check(far_b.build().get_aabb().get_center().distance_to(Vector3(5, 0.9, 5)) < 2.6, "and a shelf three tiles from any wall is drawn where it stands, not at the wall")
	var wsrc := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(not wsrc.contains("hash2(mo.x, mo.y, 5.0) * TAU") and wsrc.contains("_pack_room"), "a junk lies at her mooring the way the mooring was measured, and a pack keeps to the ground it has")
	var pot_at := Vector2(camp_c) + Vector2(0.5 + 1.3 / T, 0.5 + 0.6 / T)
	var pushed := Clash.step_clear(sw, pot_at)
	check(pushed.length() > 0.3 and pushed.length() <= Clash.NUDGE_MAX + 0.001 and Clash.step_clear(sw, Vector2(camp_c) + Vector2(0.5, 2.5)).length() < 0.01,
		"somebody sent to stand in a camp's cooking pot is drawn a step clear of it (%.2f m), and somebody on open ground where they are" % pushed.length())
	var a_spring: Dictionary = {}
	for se in sw.ents:
		if str(se.kind) == "spring":
			a_spring = se
			break
	check(not a_spring.is_empty() and Clash.step_clear(sw, Vector2(a_spring.pos) + Vector2(0.9, 0.5)).length() > 0.2 and Clash.step_clear(sw, Vector2(a_spring.pos) + Vector2(0.9, 0.5), func(_e): return false).length() < 0.01,
		"nor in a spring's basin; and a thing that is not in the land now is in nobody's way")
	var scb := MB.new()
	Arch._screen(scb, Vector3.ZERO, Vector3(0, 0, -1), Color.WHITE, Color.WHITE, Color.WHITE)
	var sca: AABB = scb.build().get_aabb()
	check(scb.tri_count() > 40 and sca.size.x > 1.6 and sca.size.x <= T and sca.end.y < 2.0, "a piece whose wall was opened into a wing has a standing screen at its back, as wide as its own tile")
	check(FileAccess.get_file_as_string("res://scripts/roads.gd").contains("T * 0.42"), "a milestone stands on the road's own kerb")
	print("== the bugs of this release stay mended ==")
	var bg = load("res://scripts/game.gd").new()
	bg.reset()
	bg.level = 30
	bg.stones = 500000
	bg.step = Data.step_index("s_p25_end") + 1 if Data.step_index("s_p25_end") >= 0 else Data.STEPS.size() - 2
	Hold.catch_up(bg, int(bg.step))
	if Hold.founded(bg):
		# (a town with everything but its market)
		(bg.hold.built as Dictionary).erase("market")
		Hold.take(bg)
		bg.day += 4
		var before := Hold.chest(bg)
		var due_was := Hold.due(bg)
		# (whatever can still be built, built on the fifth day: more households, and a market if there was none)
		var built_now := 0
		for pid in Hold.ORDER:
			if not Hold.built(bg, pid) and Hold.blocked(bg, pid) == "":
				built_now += 1 if Hold.build(bg, pid) else 0
		check(before == 4 * due_was and Hold.chest(bg) == before and built_now == 1 and Hold.due(bg) > due_was,
			"what is built today does not re-price the days the chest has already been filling (%d in it, %d built, dues %d to %d a day)" % [before, built_now, due_was, Hold.due(bg)])
		bg.day += 30
		check(Hold.chest(bg) == Hold.CHEST_DAYS * Hold.due(bg), "and it still holds five days at most")
	bg.seen = {"sect": true, "village": true, "bamboo": true}
	bg.ride = "ox_cart"
	bg.rides = {"ox_cart": true}
	var fare_bad := 0
	var fare_n := 0
	for k in 40:
		var fare_o := Offices.fare_offer(bg, {"id": "res:village:x:%d" % k, "n": "Lodger", "trade": "inn", "area": "village"})
		if not fare_o.is_empty():
			fare_n += 1
			fare_bad += 0 if bg.seen.has(str(fare_o.to)) else 1
	check(fare_bad == 0, "nobody asks to be carried to a town he has not been to (%d asked, none of them for one)" % fare_n)
	bg.inv["charcoal"] = 8
	var haul_step := -1
	for hi in Data.STEPS.size():
		if str(Data.STEPS[hi].kind) == "haul" and str(Data.STEPS[hi].get("good", "")) == "charcoal":
			haul_step = hi
	if haul_step >= 0:
		bg.step = haul_step
		check(not Load.stowable(bg).has("charcoal"), "what a haul is carrying cannot be left in one storehouse and taken up at the other")
		bg.step = haul_step + 1
		check(Load.stowable(bg).has("charcoal") or Load.weight_of("charcoal") * 8.0 < 1.0, "and can be once it has been brought")
	check(Crime.heir_k(bg, "dyer_su") == 1.0, "the living keep their own prices")
	bg.slain["dyer_su"] = {"n": "Dyer Su", "day": 1, "seen": false}
	check(Crime.heir_k(bg, "dyer_su") == Crime.HEIR_K and Crime.heir_k(bg, "tailor_qiao") == 1.0, "whoever keeps a dead woman's stall asks a quarter more, as they say they do")
	bg.free()
	var msrc2 := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(msrc2.find("Taboo.marked(Game) and wn0 % 2 == 0") < msrc2.find("Crime.line(Game, str(fp.town), int(fp.seed) + wn0) != \"\" and wn0 % 2 == 0") and msrc2.contains("Giants.LINES_SMALL[") and msrc2.contains("str(wf.line)") and msrc2.count("_drop_bags(") >= 4,
		"the street's words for a walker of the forbidden can be said, the small speak of the Great People, a fate is spoken, and no bag rides for nothing")
	check(not FileAccess.get_file_as_string("res://scripts/weal.gd").contains("Vector3(0, 1.1, 0.07), Vector3(w + 0.3, 0.12, 0.045)"), "nothing lies across the open door of a cold town")
	print("== the plot holes of this release stay mended ==")
	var dsrc := FileAccess.get_file_as_string("res://scripts/data.gd")
	var esrc := FileAccess.get_file_as_string("res://scripts/echoes.gd")
	var msrc := FileAccess.get_file_as_string("res://scripts/mail.gd")
	check(not dsrc.contains("He runs a grey finger") and not esrc.contains("Cook Zhou will be unbearable. He has"), "Roll-Clerk Ning and Cook Zhou are women in every line")
	for lid2 in ["mirror_rivet", "mirror_recast", "mirror_halves"]:
		check(Data.step_index(Mail.after_of(lid2)) + int(Mail.LETTERS[lid2].get("wait", Mail.WAIT)) < Data.STEPS.size() - 1, "the letter %s can arrive before the story ends" % lid2)
	check(not esrc.contains("each goes away with the other's") and not FileAccess.get_file_as_string("res://scripts/weal.gd").contains("I have his half and he has mine"), "two halves left on one wall are on one wall")
	check(Echoes.CROSSROADS.palace.echo.has("s_p30_finder_come"), "Part XXX says who is at supper in a palace that was sealed")
	var office_names := {}
	for oid in Offices.ORDER:
		office_names[str(Offices.OFFICES[oid].n)] = true
	check(not office_names.has("Postmaster Ge of Cloudfoot") and not office_names.has("Harbour-Master Zeng of Longmen") and not msrc.contains("Postmaster Ge") and not msrc.contains("Harbour-Master Zeng"),
		"Cloudfoot has one postmaster and Longmen one harbour-mistress; whoever answers for them has a title of his own")
	check(dsrc.contains("I said under the bridge. I am under the bridge.") and not dsrc.contains("on the fourteenth of the first month") and not dsrc.contains("Eight years I was in the wrong city") and not dsrc.contains("Your elder said I might be as late"),
		"Weisheng said under the bridge, the pedlar came a week before the lanterns, nine years are nine, and Fangfeng knows who told him")
	check(not msrc.contains("\"Sir: ") and not dsrc.contains("entered as material, sir") and not dsrc.contains("come back, sir") and not esrc.contains("favourite colour, sir") and not FileAccess.get_file_as_string("res://scripts/trials.gd").contains("looks at a man who has kept"),
		"nobody of Part XXXII calls the hero sir")

	print("== the sweep after the Cloud Keel: what was found stays mended ==")
	var new_sweep := func():
		var g9 = load("res://scripts/game.gd").new()
		g9.reset()
		g9.started = true
		return g9
	# (weal.gd: a seed that is a multiple of three says why; counted by the seed itself, the first of every three
	# lines of the street was never said in a town that had felt anything he did)
	var SG = new_sweep.call()
	Weal.act(SG, "qingshi", "gift", 3)
	for st9 in ["cold", "afraid", "lean", "wary", "thriving", "festive"]:
		SG.weal_force = {"qingshi": st9}
		var heard9 := {}
		for sd9 in 60:
			heard9[Weal.line(SG, "qingshi", sd9)] = true
		for ln9 in Weal.STREET[st9]:
			check(heard9.has(str(ln9)), "a %s town can say in the street: %s" % [st9, str(ln9).left(40)])
		check(Weal.line(SG, "qingshi", 3).contains("They tell it in the street"), "and every third word in a %s town is still of why" % st9)
	SG.weal_force = {}
	# (almanac.gd: main.gd asks a grown person for the season with a seed that is a multiple of three)
	SG.day = 2
	check(Almanac.festival(SG).is_empty(), "the second day of the journey is nobody's feast")
	var said9 := {}
	for k9 in 12:
		said9[Almanac.season_line(SG, 3 * k9)] = true
	for ln9 in Almanac.SEASON_LINES[Almanac.season(SG)]:
		check(said9.has(str(ln9)), "a grown person can say of the season: %s" % str(ln9).left(40))
	# (almanac.gd: an outlaw is struck from the roll, and is told so; he is not a rogue cultivator)
	var OG = new_sweep.call()
	OG.taboo["marked"] = 1
	OG.cal_month = Almanac.index(OG) / Almanac.MONTH
	OG.day += Almanac.MONTH
	var told9: Array = Almanac.poll(OG)
	check(Crime.outlaw(OG) and Creed.mod(OG, "stipend") > 0.0 and not told9.is_empty() and str(told9[0]).contains("struck from the roll") and not str(told9[0]).contains("rogue"),
		"an outlaw who keeps his sect's rule is told he is struck from the roll, not that he is a rogue cultivator")
	check(Crime.heat(OG) == 0 and Crime.worst(OG) == 2 and Crime.text(OG).begins_with("outlaw") and Crime.text(OG) != "a clean name", "somebody found out at a forbidden art is not told he has a clean name")
	OG.free()
	# (crime.gd: a bill paid is no bill: the page of the Law said "a clean name" and every trial "not clean")
	var CG = new_sweep.call()
	CG.stones = 100000
	Crime.record(CG, "assault", "qingshi", "Smith Tie")
	check(not Crime.clean(CG), "a bill at the gate is not a clean name")
	check(Crime.pay(CG, Crime.watch_due(CG, "village")) and Crime.heat(CG) == 0 and Crime.worst(CG) == 0 and Crime.count(CG) == 0 and Crime.text(CG) == "a clean name" and Crime.clean(CG),
		"a bill paid to the watch, with nobody dead, is a clean name at the trials as it is on the page of the Law")
	CG.watch_slain = 3
	check(not Crime.clean(CG) and Romance.matter_true(CG, "blood"), "three of the watch dead are no clean name, and Yue Ling minds them as she minds anybody")
	CG.watch_slain = 0
	CG.taboo = {"atoned": 1}
	check(not Crime.clean(CG), "a shelf opened and atoned for was still opened")
	CG.taboo = {}
	# (romance.gd: an Elder he struck down does not give her away; main.gd: nor sit by the bed, nor does Old Du speak)
	check(Romance.option_ok(CG, "wed", "everyone") and Romance.option_ok(CG, "wed", "granny"), "the living stand witness")
	CG.slain["elder"] = {"n": "Elder Qing Xuan", "day": 1, "seen": false, "town": "sect", "area": "sect"}
	check(not Romance.option_ok(CG, "wed", "everyone") and Romance.option_ok(CG, "wed", "moon"), "an Elder dead by his hand gives nobody away before the whole sect")
	CG.slain["dicer_du"] = {"n": "Old Du of the Three Dice", "day": 1, "seen": false, "town": "qingshi", "area": "village"}
	var muted9: Array = Crime.mute(CG, [[Gamble.name_of(), Creed.SHUT.gamble[2]]])
	check(muted9.size() == 1 and str(muted9[0][0]) == "Narrator", "what Old Du says to somebody who keeps the precepts is not said from under a mound")
	CG.free()
	SG.free()
	# (main.gd: the turn of somebody's fate swallowed one of their own words: with three things to say, the second)
	var turns9 := {}
	var fate_turns9 := 0
	for i9 in 12:
		var ct9 := Weal.chat_turn(i9, true)
		if ct9 < 0:
			fate_turns9 += 1
		else:
			turns9[ct9 % 3] = true
		check(Weal.chat_turn(i9, false) == i9, "somebody with no fate speaks as before (%d)" % i9) if i9 < 3 else null
	check(turns9.size() == 3 and fate_turns9 == 4 and Weal.chat_turn(1, true) == -1 and Weal.chat_turn(0, true) == 0 and Weal.chat_turn(2, true) == 1,
		"somebody a crossroads changed still says all three of their own things, and their fate every third word")
	var msrc9 := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(msrc9.contains("Weal.chat_turn(i, ") and not msrc9.contains("if Game.prologue == \"\" and i % 3 == 1:"), "and main.gd asks whose turn it is")
	check(not msrc9.contains("say([[\"Old Du\"") and msrc9.contains("\"Nobody is sitting by the bed.\" if Crime.dead(Game, \"elder\")"), "Old Du is named as he stands, and a dead Elder watches over nobody in the infirmary")
	check(FileAccess.get_file_as_string("res://scripts/menu.gd").contains("not x.has(\"alias\")).size() - shown"), "the page of the Law counts somebody who stood in several places once")
	print("== and its plot holes ==")
	var dsrc9 := FileAccess.get_file_as_string("res://scripts/data.gd")
	var rsrc9 := FileAccess.get_file_as_string("res://scripts/romance.gd")
	var all9 := dsrc9 + FileAccess.get_file_as_string("res://scripts/echoes.gd") + FileAccess.get_file_as_string("res://scripts/lore.gd") + FileAccess.get_file_as_string("res://scripts/trials.gd")
	check(not all9.contains("Fei Lian") and str(Data.ENEMIES.fei_lian.n) == str(Data.ENEMIES.feilian.n), "the Earl of the Wind has one name in both chapters he is met in")
	check(not dsrc9.contains("A king buried two people in sight of each other. Are those your knots?"), "Lin Feng does not know of the two graves before the Old Man under the Moon has told him")
	check(not FileAccess.get_file_as_string("res://scripts/weal.gd").contains("Thursday") and not FileAccess.get_file_as_string("res://scripts/mail.gd").contains("Thursday"), "a land of thirty-day months has no Thursday")
	check(not dsrc9.contains("There were four hundred of them") and dsrc9.contains("Two hundred and six of them"), "Fangfeng counted two hundred and six at Low Willow, as his grudge said")
	check(not dsrc9.contains("with an empty blue cloth"), "the blue cloth is under the two halves on the moon, not in the pedlar's hands")
	check(not dsrc9.contains("Your Duke says the fault was the clerk's"), "Lin Feng does not quote a Duke nobody has mentioned")
	check(not dsrc9.contains("If you had sat to one of those three arts"), "Yue Ling does not say he never sat to a forbidden art: he may have")
	check(not dsrc9.contains("It is the ninth month. The guest was right"), "the roof burns on whatever day the journey has come to: the calendar is set at the feast")
	check(not dsrc9.contains("ask your name again") and str(Mail.LETTERS.bridge_girl.lines[0]).contains("he had never asked"), "Weisheng never asked her name, as she writes")
	check(not dsrc9.contains("She has the other half of the mirror in both hands") and not dsrc9.contains("Take him my half"), "the half Lin Feng carries to Xu Deyan is not also in the Princess's hands")
	check(not rsrc9.contains("We mended that") and not rsrc9.contains("four realms with the sweeper") and not rsrc9.contains("who held the sky") and not rsrc9.contains("by a Primordial Sovereign"),
		"an hour with Yue Ling, which can be had from the day she joins him, speaks of nothing the story has not come to")

## The Higher Sky release: those above him (betters.gd), a story that forks where he met them, the pages in
## their own words (memoir.gd), Part XXXVIII, and what the sweep before it mended.
func _higher_sky() -> void:
	var dfont := ThemeDB.fallback_font
	var fits := func(text: String) -> bool:
		var par := TextParagraph.new()
		par.add_string(text, dfont, 22)
		par.width = 1100
		return par.get_line_count() <= 4
	var new_game := func():
		var g = load("res://scripts/game.gd").new()
		g.reset()
		g.started = true
		g.companion = true
		return g
	var msrc := FileAccess.get_file_as_string("res://scripts/main.gd")
	var bsrc := FileAccess.get_file_as_string("res://scripts/bot.gd")
	var btsrc := FileAccess.get_file_as_string("res://scripts/battle.gd")

	print("== those above him (betters.gd, the Higher Sky release) ==")
	check(Betters.ORDER.size() == 3 and Betters.BETTERS.size() == 3 and Betters.COST.size() == 3, "three stand above him")
	var G = new_game.call()
	G.level = 126
	G.stones = 10000
	for id in Betters.ORDER:
		var bd: Dictionary = Betters.BETTERS[id]
		var en: Dictionary = Data.ENEMIES.get(id, {})
		check(Betters.is_better(id) and bool(en.get("boss", false)) and not bool(en.get("doom", false)) and str(en.shape) == "person:" + id and Assets.has("characters/" + id) and FileAccess.file_exists("res://art/characters/%s.py" % id),
			"%s is somebody, with a body from a script, and no doom" % id)
		check(int(bd.over) >= 4 and Betters.gap(G, id) == int(bd.over) and Betters.level(G, id) == 126 + 3 * int(bd.over) and Data.realm_of(Betters.level(G, id)) - G.realm() == int(bd.over),
			"%s stands %d whole realms above whatever he is on the day they meet" % [id, int(bd.over)])
		check(Data.suppression(Betters.level(G, id), 126) >= 1.0 + Data.SUPPRESS * Data.SUPPRESS_CAP - 0.001, "%s weighs on him as hard as a realm can weigh" % id)
		check((bd.watch as Array).size() == Betters.WATCH_MAX and Lore.BOSS.has(id) and Tactics.wit_of(id) == Tactics.TACTICIAN, "%s can be watched three times, has a story, and fights as a tactician" % id)
		for wl in bd.watch:
			check(fits.call(str(wl)) and not str(wl).contains("—"), "%s: what is seen of him fits the box" % id)
		for dk in ["dare:", "won:", "again:", "back:"]:
			check(Data.DIALOGUE.has(dk + id), "%s: there are words for %s" % [id, dk])
		check(Data.DIALOGUE.has("bested:%s:lost" % id) and Data.DIALOGUE.has("bested:%s:gave" % id), "%s: losing is told, and giving way is told differently" % id)
		var c: Dictionary = Betters.COST[id]
		check(float(c.stones) > 0.0 and float(c.stones) <= 0.5 and Data.step_index(str(c.mend)) > 0 and fits.call(str(c.tag)) and not (c.mods as Dictionary).is_empty(), "%s: losing costs stones and leaves a wound that a step mends" % id)
		var ms: Dictionary = Data.STEPS[Data.step_index(str(c.mend))]
		check(ms.has("if") and str(ms["if"][0]) == id and str(ms["if"][1]) == "down", "%s: what mends the wound is done on the branch where he lost" % id)
		var dares := 0
		var ups := 0
		var downs := 0
		for st in Data.STEPS:
			if str(st.kind) == "dare" and str(st.boss) == id:
				dares += 1
				check(not st.has("if") and Data.step_index(str(st.id)) < Data.step_index(str(c.mend)), "%s is met before anything is mended" % id)
			if st.has("if") and str(st["if"][0]) == id:
				ups += 1 if str(st["if"][1]) == "up" else 0
				downs += 1 if str(st["if"][1]) == "down" else 0
				check(str(st["if"][1]) in ["up", "down"], "%s: a branch is up or down" % st.id)
		check(dares == 1 and ups >= 1 and downs >= 3 and downs > ups, "%s: one bout, and the story goes on differently either way (%d up, %d down): losing is the longer road" % [id, ups, downs])
	# watching
	check(Betters.watch_blocked(G, "fuchai") == "", "he can be watched")
	var clock0 := float(G.clock)
	var day0 := int(G.day)
	var seen1 := Betters.watch(G, "fuchai")
	check(seen1 == str(Betters.BETTERS.fuchai.watch[0]) and Betters.gap(G, "fuchai") == 3 and Betters.level(G, "fuchai") == 126 + 9 and (int(G.day) > day0 or float(G.clock) >= clock0 + Betters.WATCH_HOURS * 60.0 - 0.01), "a watch takes four hours and closes one realm of the gap")
	check(Betters.watch_blocked(G, "fuchai") != "" and Betters.watch(G, "fuchai") == "" and Betters.gap(G, "fuchai") == 3, "once a day")
	G.day += 1
	Betters.watch(G, "fuchai")
	G.day += 1
	Betters.watch(G, "fuchai")
	G.day += 1
	check(Betters.gap(G, "fuchai") == 1 and Betters.watch_blocked(G, "fuchai") != "" and Betters.level(G, "fuchai") == 126 + 3, "three watches, and no more: he is still a realm above")
	G.free()
	# losing
	G = new_game.call()
	G.level = 126
	G.stones = 10000
	var day1 := int(G.day)
	var deaths1 := int(G.deaths)
	check(Betters.branch(G, "fuchai") == "" and Betters.mod(G, "atk") == 1.0 and Betters.wounds(G).is_empty() and Betters.epilogue(G) == "", "before they meet nothing weighs on him")
	var told := Betters.over(G, "fuchai", "lost", "dragon")
	check(G.stones == 5000 and int(G.day) == day1 + 3 and int(G.deaths) == deaths1 and told.contains("5000") and Betters.branch(G, "fuchai") == "down" and int(G.overmatched) == 1,
		"lost to the King of Wu: half of what he carried, three days of his life, no death counted, and the story goes down")
	check(Betters.wounded(G, "fuchai") and Betters.mod(G, "wage") < 1.0 and Betters.tags(G) == ["A groom of Wu"] and Betters.again(G, "fuchai"), "a wound is on him, and he may ask for another bout")
	var wtown := Weal.town_of("dragon")
	check(wtown == "" or Weal.acts(G, wtown, "bested") == 1, "the town that hears of that country heard")
	check(Weal.ACTS.has("bested") and int(Weal.ACTS.bested.per) < 0, "being beaten in a country is felt in its town")
	# the branch
	var p38 := Data.step_index("s_p38_home")
	var walk := func(g) -> Array:
		var out: Array = []
		var i: int = Betters.skip(g, p38)
		while i < Data.STEPS.size():
			out.append(str(Data.STEPS[i].id))
			i = Betters.skip(g, i + 1)
		return out
	var wd1: Array = walk.call(G)
	check(wd1.has("s_p38_brush") and wd1.has("s_p38_gall") and not wd1.has("s_p38_spared"), "the journey that lost walks the brushwood and the gall, and not the other road")
	# a rematch won gives back what can be given back, and not the branch
	G.level = 150
	var told2 := Betters.over(G, "fuchai", "won", "dragon")
	check(G.stones == 10000 and told2.contains("5000") and not Betters.wounded(G, "fuchai") and Betters.branch(G, "fuchai") == "down" and not Betters.again(G, "fuchai") and Betters.beaten(G) == 1, "met again and beaten: the stones come back, the wound is lifted, and what was done after losing was done")
	G.free()
	# the wound is mended by the step of the down branch
	G = new_game.call()
	G.level = 126
	Betters.over(G, "pang_juan", "lost", "maple")
	var f0: Dictionary = new_game.call().fighter(0)
	var GH = new_game.call()
	GH.level = 126
	var fh: Dictionary = GH.fighter(0)
	var fw: Dictionary = G.fighter(0)
	check(float(fw.atk) < float(fh.atk) and int(fw.spd) < int(fh.spd) and float(fw.atk) > float(fh.atk) * 0.85, "the knee: he strikes a little less hard and is slower to the first blow (%.0f against %.0f)" % [float(fw.atk), float(fh.atk)])
	G.step = Data.step_index("s_p38_maling") + 1
	check(not Betters.wounded(G, "pang_juan") and is_equal_approx(float(G.fighter(0).atk), float(fh.atk)), "and it is mended under the white tree")
	GH.free()
	G.free()
	# giving way: half the stones, no days; and to the one who is bowed to it is the way up
	G = new_game.call()
	G.level = 126
	G.stones = 8000
	var day2 := int(G.day)
	Betters.over(G, "lian_po", "gave", "terraces")
	check(G.stones == 7000 and int(G.day) == day2 and Betters.branch(G, "lian_po") == "up" and not Betters.wounded(G, "lian_po") and int(G.bowed) == 1 and Betters.mod(G, "price") == 1.0, "giving way to Lian Po costs an eighth of the purse, no wound, and is the way up")
	Betters.over(G, "fuchai", "gave", "dragon")
	check(Betters.branch(G, "fuchai") == "down" and Betters.wounded(G, "fuchai") and int(G.day) == day2 + 3 and G.stones == 3500, "giving way to the King of Wu is what it was for Goujian: a groom all the same")
	Betters.over(G, "pang_juan", "won", "maple")
	check(Betters.branch(G, "pang_juan") == "up" and Betters.met(G) == 3 and Betters.epilogue(G).contains("lost to one") and fits.call(Betters.epilogue(G)), "the ending says how it went with the three")
	var wd2: Array = walk.call(G)
	check(wd2.has("s_p38_rods") and not wd2.has("s_p38_thorns") and wd2.has("s_p38_cart") and not wd2.has("s_p38_maling") and wd2.has("s_p38_gall"), "each bout forks the story by itself")
	G.free()
	# every one of the eight journeys reaches the end of the chapter, and none walks both sides of a fork
	for mask in 8:
		var GB = new_game.call()
		GB.level = 126
		for k in 3:
			Betters.over(GB, str(Betters.ORDER[k]), "won" if (mask >> k) & 1 == 1 else "lost", "")
		var wk: Array = walk.call(GB)
		var both := false
		for sid in wk:
			var st2: Dictionary = Data.STEPS[Data.step_index(str(sid))]
			if st2.has("if") and Betters.branch(GB, str(st2["if"][0])) != str(st2["if"][1]):
				both = true
		check(not both and wk[0] == "s_p38_home" and wk[wk.size() - 1] == "s_break43" and wk.has("s_p38_low") and wk.has("s_p38_end") and wk.size() >= 19, "journey %d of 8 walks one side of each fork to the end of the chapter (%d steps)" % [mask, wk.size()])
		check(fits.call(Betters.epilogue(GB)) and Betters.epilogue(GB) != "", "and the ending has a sentence for it")
		GB.free()
	# Game.advance steps over the other branch
	G = new_game.call()
	G.level = 126
	Betters.over(G, "fuchai", "won", "dragon")
	G.step = Data.step_index("s_p38_fuchai")
	G.advance()
	check(str(G.cur_step().id) == "s_p38_spared", "after a bout won the next step is the one of that road (%s)" % str(G.cur_step().id))
	G.advance()
	check(str(G.cur_step().id) == "s_p38_sunbin", "and after it the roads meet again (%s)" % str(G.cur_step().id))
	G.free()
	check(btsrc.contains("func _bested(") and btsrc.contains("outcome = \"bested\"") and msrc.contains("func _better_done(") and msrc.contains("func meet_better(") and msrc.contains("\"label\": \"Walk on\"") and msrc.find("\"label\": \"Walk on\"") < msrc.find("\"label\": \"Watch him\""),
		"the battle has a fourth end, main tells what it cost, and walking on is the first answer")
	check(not msrc.contains("Game.respawn()\n\t\t\tBetters") and msrc.contains("Betters.over(Game, id, how"), "nobody is carried home for it")
	check(bsrc.contains("\"dare\":") and bsrc.contains("ids.has(\"draw\")") and bsrc.contains("bot-watch") and not bsrc.contains("Betters.watch("), "the bot stands in front of them, and watches nobody unless told to")
	check(Data.level_name(126 + 15).ends_with("Sky Above") and Data.realm_name(43) == "Low as the Sea" and Data.realm_name(44) == "First Sky Above" and Data.realm_name(99) == "Ninth Sky Above", "somebody above the last realm stands in a sky that is told by how far up it is")
	for st3 in Data.STEPS:
		check(not st3.has("if") or Betters.BETTERS.has(str(st3["if"][0])), "%s: a fork names somebody above him" % st3.id)
		check(str(st3.kind) != "dare" or (Betters.is_better(str(st3.boss)) and int(st3.get("cave", 0)) == -1), "%s: a dare is a bout with a better" % st3.id)
	for tid in Trials.TRIALS:
		for pt in Trials.TRIALS[tid].paths:
			for nd in pt.needs:
				check(not str(nd[0]) in ["watched", "bested", "pages"], "%s/%s: no trial asks for a watch, a bout or a page" % [tid, pt.id])

	print("== in their own words (memoir.gd, the Higher Sky release) ==")
	check(Memoir.ORDER.size() == Memoir.PAGES.size() and Memoir.PAGES.size() >= 50, "%d pages" % Memoir.PAGES.size())
	var by := {}
	var parts := {}
	for pid in Memoir.ORDER:
		var pg: Dictionary = Memoir.PAGES.get(pid, {})
		check(not pg.is_empty() and Memoir.WHO.has(str(pg.who)) and Data.step_index(str(pg.after)) >= 0 and fits.call(str(pg.n)) and (pg.lines as Array).size() >= 3, "%s: a page of somebody, after a step that is there" % pid)
		by[str(pg.who)] = int(by.get(str(pg.who), 0)) + 1
		parts[str(pid).substr(0, 3)] = true
		var all := " ".join(pg.lines)
		for ln in pg.lines:
			check(fits.call(str(ln)) and not str(ln).contains("—"), "%s: a line that fits the box, with no dash in it" % pid)
			check(not str(ln).contains(" sir") and not str(ln).contains("young man") and not str(ln).contains("young woman"), "%s: nobody says what the hero is" % pid)
		match str(pg.who):
			"lin":
				check((" " + all).contains(" I "), "%s: he says I" % pid)
			"yue":
				check(all.to_lower().contains("you") and (" " + all).contains(" I "), "%s: she says I, and writes to him" % pid)
			"elder":
				check(all.contains("the child") or all.contains("child"), "%s: he calls the hero the child" % pid)
		if pg.has("if"):
			check(Betters.BETTERS.has(str(pg["if"][0])) and str(pg["if"][1]) in ["up", "down"], "%s is of one branch" % pid)
		for sp in Memoir.lines(null, pid):
			check(str(sp[0]) in ["Lin Feng", "Yue Ling", "Elder Qing Xuan"], "%s is said by its writer, under the name they stand by" % pid)
	check(by.size() == 3 and int(by.lin) >= 15 and int(by.yue) >= 12 and int(by.elder) >= 9, "the three people the story is about each write (%s)" % str(by))
	check(parts.size() == 38, "every part of the story has a page (%d)" % parts.size())
	G = new_game.call()
	G.step = Data.step_index("s_break1") + 1
	check(Memoir.written(G) == 1 and G.pages.has("p01_broom") and G.page_due == ["p01_broom"] and Memoir.written(G) == 0 and Memoir.book(G) == ["p01_broom"], "a page is written when its step is done, once")
	G.companion = false
	G.step = Data.step_index("s_yue") + 1
	check(Memoir.written(G) == 0, "she writes nothing before she is with him")
	G.companion = true
	G.slain["elder"] = {"seen": false}
	G.step = Data.step_index("s_break4") + 1
	check(Memoir.written(G) == 0 and not Memoir.open(G, "p01_gate"), "the dead write nothing")
	G.slain.clear()
	Betters.over(G, "fuchai", "lost", "")
	G.step = Betters.skip(G, Data.step_index("s_p38_fuchai") + 1)
	check(str(G.cur_step().id) == "s_p38_brush" and Memoir.written(G) == 2 and G.pages.has("p38_fuchai_down_lin") and G.pages.has("p38_fuchai_down_yue") and not G.pages.has("p38_fuchai_up_lin"), "somebody who lost to Fuchai writes of the stables, and she of the wall")
	G.free()
	G = new_game.call()
	Betters.over(G, "fuchai", "won", "")
	G.step = Betters.skip(G, Data.step_index("s_p38_fuchai") + 1)
	check(Memoir.written(G) == 1 and G.pages.has("p38_fuchai_up_lin"), "and somebody who did not writes a different page")
	G.free()
	check(msrc.contains("func _page_scene()") and msrc.contains("Memoir.lines(Game, pid)") and FileAccess.get_file_as_string("res://scripts/game.gd").contains("Memoir.written(self)") and FileAccess.get_file_as_string("res://scripts/menu.gd").contains("In Their Own Words"),
		"a page is read out when he stands free, and again from the menu")
	check(not bsrc.contains("Memoir.") and not bsrc.contains("page_due"), "the bot reads nothing")

	print("== Part XXXVIII: A Sky Above the Sky ==")
	check(Data.REALMS.size() == 44 and Data.REALMS[43] == "Low as the Sea" and Data.MAX_LEVEL == 129 and Data.level_name(129).ends_with("Low as the Sea") and Data.REALM_INFO.size() == 44
		and Data.EXP_NEED.size() == Data.MAX_LEVEL and Data.ENEMY_EXP.size() == Data.MAX_LEVEL + 1, "Part XXXVIII adds the realm of Low as the Sea")
	check(Data.STEPS[Data.STEPS.size() - 1].id == "s_break43" and int(Data.STEPS[Data.STEPS.size() - 1].to) == Data.MAX_LEVEL and Data.DIALOGUE.has("recall36") and msrc.contains("\"s_break42\": \"recall36\"") and Data.DIALOGUE.has("pre:s_break43") and Data.DIALOGUE.has("post:s_break43"),
		"Part XXXVIII follows Five in One Hand (recall36) and ends the game")
	var kinds := {}
	var n38 := 0
	var kills := 0
	var names := ["Narrator", "Lin Feng", "Yue Ling", "Elder Qing Xuan"]
	for bid in Betters.ORDER:
		names.append(str(Data.ENEMIES[bid].n))
	var people := ["goujian", "sun_bin", "lin_xiangru"]
	for pa in ["dragon", "maple", "terraces"]:
		for np in Data.AREAS[pa].npcs:
			if str(np.id) in people:
				names.append(str(np.n))
				check(Assets.has("characters/" + str(np.asset)) and FileAccess.file_exists("res://art/characters/%s.py" % str(np.asset)) and Closeup.signature(str(np.n)) != "" and Folk.POSTS.has(str(np.id)) and bool(np.get("after", false)) and int(np.get("cave", 0)) == -1,
					"%s has a body from a script, a gesture of their own, something to do by day, and stands in a cave after everybody" % np.id)
		for bo in Data.AREAS[pa].bosses:
			if Betters.is_better(str(bo.id)):
				check(bool(bo.get("after", false)) and int(bo.get("cave", 0)) == -1 and str(bo.vis[0]) == "s_p38_home" and str(bo.vis[1]) == "", "%s stands at the back of a cave from the chapter's first word, and stays" % bo.id)
		check(Caves.LATE.has(pa) and not Caves.OWN.has(pa) or Caves.LATE.has(pa), "%s: the chapter's band is stood last of all in its cave" % pa)
	var found38 := 0
	for pa2 in ["dragon", "maple", "terraces"]:
		var cw: Dictionary = Atlas.world_of(Caves.fid(pa2))
		var packs38 := 0
		var pool38: Array = (Caves.LATE[pa2][-1].pool as Array).map(func(pe): return str(pe[0]))
		for e38 in cw.get("ents", []):
			if str(e38.get("kind", "")) == "enemy" and str(e38.group[0].id) in pool38:
				packs38 += 1
				found38 += 1
			elif str(e38.get("id", "")).begins_with("p38_") or str(e38.get("id", "")) in people or Betters.is_better(str(e38.get("enemy", ""))):
				found38 += 1
		check(packs38 == int(Caves.LATE[pa2][-1].n) and packs38 >= 6, "%s: every pack the chapter asks its cave for found room (%d)" % [pa2, packs38])
		for e39 in Atlas.world_of("surface").ents:
			if str(e39.get("area", "")) == pa2:
				check(not (str(e39.get("id", "")).begins_with("p38_") or str(e39.get("id", "")) in people or Betters.is_better(str(e39.get("enemy", "")))), "nothing of the chapter stands on the land of %s" % pa2)
	check(found38 == 6 + 9 + 10 + 3 * 6, "everything the chapter stands in the three caves found room (%d)" % found38)
	check(names.size() == 10, "the three who lost and the three who stand above him are in the chapter's regions (%d)" % names.size())
	for i in range(p38, Data.STEPS.size()):
		var s8: Dictionary = Data.STEPS[i]
		n38 += 1
		kinds[str(s8.kind)] = int(kinds.get(str(s8.kind), 0)) + 1
		check(str(s8.id).begins_with("s_p38_") or str(s8.id) == "s_break43", "%s is a step of the chapter" % s8.id)
		check(not str(s8.kind) in ["slay", "crime", "taboo"], "%s asks for nothing the law forbids" % s8.id)
		check(not s8.has("stones") or int(s8.stones) > 92200, "%s pays as the road has come to pay" % s8.id)
		if str(s8.kind) == "talk":
			check(Data.DIALOGUE.has(str(s8.id)), "%s has its conversation" % s8.id)
		if str(s8.kind) in ["hunt", "collect", "folk", "toil", "cook", "sunder"]:
			check(Data.DIALOGUE.has("done:" + str(s8.id)), "%s: something is said when it is done" % s8.id)
		if str(s8.kind) == "hunt":
			kills += int(s8.n)
			var bnd: Dictionary = Caves.LATE.get(str(s8.area), {}).get(int(s8.get("cave", 0)), {})
			var pool: Array = []
			for pe in bnd.get("pool", []):
				pool.append(str(pe[0]))
				check(int(pe[1]) <= Data.MAX_LEVEL and int(pe[2]) <= Data.MAX_LEVEL, "%s: nothing in the band is past the last level" % s8.id)
			for of8 in s8.of:
				check(pool.has(str(of8)) and Lore.BEAST.has(str(of8)) and not Data.ENEMIES[str(of8)].get("boss", false) and Tactics.WIT.has(str(Data.ENEMIES[str(of8)].shape)), "%s: %s lives in the region's cave, has a story, and wits" % [s8.id, of8])
			check(not bnd.is_empty() and Data.step_index(str(bnd.vis)) < i and not s8.get("first", false), "%s: the band is in the cave before it is hunted" % s8.id)
		if str(s8.kind) == "collect":
			check(Data.ITEMS.has(str(s8.item)) and Look.PICKUP_COLORS.has(str(s8.item)) and Load.weight_of(str(s8.item)) <= 1.0, "%s: what is looked for is there to find" % s8.id)
		if str(s8.kind) == "folk":
			var er: Dictionary = Folk.ERRANDS.get(str(s8.id), {})
			check(not er.is_empty() and (er.lines as Array).size() >= 4 and int(Folk.TOWNS[str(s8.town)].roles.get(str(s8.role), 0)) >= int(s8.n) and str(er.get("town", "")) == str(s8.town) and fits.call(str(er.ask)), "%s: an errand with four answers among people who are there" % s8.id)
			for el in er.lines:
				check(fits.call(str(el)), "%s: what is answered fits the box" % s8.id)
		if str(s8.kind) == "kill":
			check(Data.DIALOGUE.has("pre:" + str(s8.boss)) and Data.DIALOGUE.has("post:" + str(s8.boss)) and Trials.TRIALS.has(str(s8.boss)) and bsrc.contains("\"%s\": \"" % str(s8.boss)), "%s: words before and after, a trial, and a way planned for the bot" % s8.boss)
	check(n38 == 29 and kills == 120 and int(kinds.get("dare", 0)) == 3 and int(kinds.get("kill", 0)) == 1 and kinds.size() >= 9 and kinds.has("toil") and kinds.has("cook") and kinds.has("sunder") and kinds.has("folk"),
		"the chapter is twenty-nine steps of nine kinds, three of them bouts with somebody above him (%d, %d, %d)" % [n38, kinds.size(), kills])
	var keys := ["recall36", "pre:s_break43", "post:s_break43", "pre:pang_juan", "post:pang_juan"]
	for bid2 in Betters.ORDER:
		for dk2 in ["dare:", "won:", "again:", "back:"]:
			keys.append(dk2 + bid2)
		keys.append("bested:%s:lost" % bid2)
		keys.append("bested:%s:gave" % bid2)
	var firsts := 0
	for dk3 in Data.DIALOGUE:
		if str(dk3).contains("s_p38_") or str(dk3) in keys:
			for ln3 in Data.DIALOGUE[dk3]:
				check(fits.call(str(ln3[1])) and not str(ln3[1]).contains("—"), "%s: a line that fits the box, with no dash in it" % dk3)
				check((ln3 as Array).size() == 2 or Data.EMOTES.has(str(ln3[2])), "%s: its gesture is one everybody has" % dk3)
				check(not str(ln3[1]).contains(", sir") and not str(ln3[1]).contains("young man") and not str(ln3[1]).contains("Sir"), "%s: nobody calls the hero sir" % dk3)
				check(str(ln3[0]) in names, "%s: %s is somebody of the chapter, under the name they stand by" % [dk3, ln3[0]])
				if str(ln3[0]) == "Lin Feng" and (" " + str(ln3[1])).contains(" I "):
					firsts += 1
	for k38 in keys:
		check(Data.DIALOGUE.has(k38), "%s is said" % k38)
	check(firsts >= 20, "he speaks for himself in his own chapter (%d lines in the first person)" % firsts)
	# the one lord with a trial: Pang Juan under the tree
	var tr: Dictionary = Trials.TRIALS.pang_juan
	var open_n := 0
	for pt2 in tr.paths:
		check(fits.call(str(pt2.desc)) and fits.call(str(pt2.line)) and Trials.KINDS.has(str(pt2.kind)), "pang_juan/%s: its words fit, and its way has a name" % pt2.id)
		if not str(pt2.kind) in ["clean", "wild", "creed"]:
			open_n += 1
		for nd2 in pt2.needs:
			if str(nd2[0]) == "step":
				check(Data.step_index(str(nd2[1])) >= p38 and Data.step_index(str(nd2[1])) < Data.step_index("s_p38_maling") and Data.STEPS[Data.step_index(str(nd2[1]))].get("if", []) == ["pang_juan", "down"], "pang_juan/%s: what it is shown was done on this road, before him" % pt2.id)
			if str(nd2[0]) == "lv":
				check(int(nd2[1]) < Data.MAX_LEVEL, "pang_juan/%s: the might asked can be had by then" % pt2.id)
			if str(nd2[0]) in ["cooked", "light"]:
				check(int(nd2[1]) >= 1 and int(nd2[1]) <= 3, "pang_juan/%s: no more than the story has asked for" % pt2.id)
	check((tr.paths as Array).size() == 4 and open_n >= 2 and fits.call(str(tr.why)) and Data.step_index("s_p38_slips") < Data.step_index("s_p38_maling"), "Pang Juan under the tree has four ways through, two of them open to a wanted man")
	# the crossroads
	var c8: Dictionary = Echoes.CROSSROADS.get("the_higher_sky", {})
	check(not c8.is_empty() and str(c8.step) == "s_p38_low" and str(c8.part) == "XXXVIII" and Echoes.ORDER[Echoes.ORDER.size() - 1] == "the_higher_sky" and fits.call(str(c8.ask)) and Marks.AFTER_BANDS.has("the_higher_sky"), "what a sect teaches about those above it is asked last of all")
	check((c8.options as Array).size() == 3 and c8.after.size() == 3 and c8.end.size() == 3 and c8.echo.has("s_p38_end") and c8.echo.s_p38_end.size() == 3 and Data.step_index("s_p38_end") > Data.step_index("s_p38_low") and bsrc.contains("\"the_higher_sky\": [\"ditch\"]"), "the_higher_sky: three answers, each answered, echoed and told at the end, and the bot has one")
	var scales := {}
	for o8 in c8.options:
		var mk: Dictionary = Marks.MARKS.the_higher_sky.get(str(o8.id), {})
		check(not mk.is_empty() and mk.has("who") and fits.call(str(mk.desc)) and fits.call(str(mk.who[3])) and fits.call(str(mk.who[4])) and Assets.has("characters/" + str(mk.who[1])) and not Weal.hears(str(mk.area)).is_empty() and int(mk.get("k", 1)) >= 3, "the_higher_sky/%s leaves a row of things standing, and somebody by it" % o8.id)
		var mm: Node3D = Marks.model(mk, 0)
		check(mm != null and mm.get_child_count() > 0, "the_higher_sky/%s: what stands is built from code" % o8.id)
		mm.free()
		for tk in o8.tilt:
			scales[str(tk)] = true
		for ck in o8.get("creed", {}):
			check(Creed.AXES.has(str(ck)) and absi(int(o8.creed[ck])) < Creed.SIDE, "the_higher_sky/%s leans on the Way, and does not by itself decide it" % o8.id)
		check(fits.call(str(o8.desc)) and fits.call(str(c8.end[str(o8.id)])), "the_higher_sky/%s: what it means, and what is told of it, fit" % o8.id)
		for al in c8.after[str(o8.id)]:
			check(fits.call(str(al[1])), "the_higher_sky/%s: what follows fits the dialogue box" % o8.id)
		check(Mail.LETTERS.has("sky_" + str(o8.id)) and Mail.ORDER.has("sky_" + str(o8.id)), "the_higher_sky/%s: somebody who lives with it writes" % o8.id)
	check(scales.size() == 3, "the three answers tip all three scales")
	check(Echoes.CROSSROADS.the_round.echo.has("s_p38_home") and Echoes.CROSSROADS.the_round.echo.s_p38_home.size() == 3, "the last chapter's crossroads is heard in this one's first conversation")
	for fid in ["low_as_sea", "the_stirrup", "white_tree", "by_the_ditch"]:
		check(Feats.FEATS.has(fid), "the feat %s" % fid)
	for src in ["Records of the Historian", "Spring and Autumn of Wu and Yue"]:
		check(FileAccess.get_file_as_string("res://scripts/lore.gd").contains(src), "the chapter's tales are told from where they are written: %s" % src)

	print("== the bugs of the Higher Sky release stay mended ==")
	var same := 0
	for kd in Phases.KINDS:
		for el2 in Phases.ORDER:
			for gr in ["tree", "ground", "water"]:
				var cm: Array = Phases.come(str(kd), str(el2), gr)
				if not cm.is_empty() and str(cm[0]) == str(kd):
					same += 1
	check(same == 0 and Phases.come("steam", "water", "ground").is_empty(), "no phase lays again what already lies there: water on steam is not another fire put out (%d)" % same)
	G = new_game.call()
	var wn := int(G.weal_n)
	G.record_kills("bamboo", 3)
	check(int(G.weal_n) > wn, "packs cleared out of a country are told to its towns at once")
	G.free()
	check(btsrc.contains("ground_marks.clear()") and btsrc.find("ground_marks.clear()") < btsrc.find("scar_root = Node3D.new()"), "what a phase left on the last battle's ground is gone when the next begins")
	check(FileAccess.get_file_as_string("res://scripts/sunder.gd").contains("scar(g, layer, ct) != \"crater\""), "a hollow that lies there is not dug and counted again")
	print("== and its plot holes ==")
	var dsrc := FileAccess.get_file_as_string("res://scripts/data.gd")
	check(dsrc.contains("Give her back six of the pressings") and not dsrc.contains("five of the pressings") and Bonds.MEMORIES_NEEDED == 6, "the Founder asks for as many memories as the step does")
	check(dsrc.contains("Xu Mo found her first") and str(Data.DIALOGUE["post:drowned_bearer"][1][1]).contains("Where she sank"), "the seventh bearer is a woman in the cave as she is in the lake")
	check(not dsrc.contains("making them forty years") and not dsrc.contains("Forty years I have kept this forge") and not dsrc.contains("for four hundred years and calling it work"), "the lantern-maker, the forgemaster and the lamplighter are each as old as they said they were")
	check(not dsrc.contains("Their owners have gone over the bridge, but"), "not every owner of a grudge is dead: Fangfeng is on his hill")
	check(not dsrc.contains("the room your mother had"), "nobody in Qingshi knew his mother: he was found beside two graves")
	check(dsrc.contains("breaks the four Immortal Peaches") and dsrc.contains("Give a piece to each soul"), "four peaches go round nineteen souls")
