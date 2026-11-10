extends Node
## Benchmark (developer tool): how long the open world takes to open, and what a frame of it costs.
##   godot --path . -- --bench=build/bench.json            (needs a window: xvfb-run on a server)
## It opens the world at the sect the way a new game does, then stands and walks the hero through
## several regions, and writes for each: the time to arrive (regions streamed in), the mean and worst
## frame, the script time per frame, and what the renderer was asked to draw (draw calls, objects,
## primitives).  The numbers that do not depend on the graphics card (load time, script time, draw
## calls, primitives) are the ones to compare between two builds on the same machine.

var main
const STOPS := [["sect", Vector2i(36, 30)], ["mountain", Vector2i(82, 40)], ["village", Vector2i(30, 26)], ["bamboo", Vector2i(20, 20)],
	["thunder", Vector2i(30, 14)], ["longmen", Vector2i(28, 30)], ["dunes", Vector2i(14, 40)]]
var FRAMES := 45

func _ready() -> void:
	_run()

func _free_near(t: Vector2i) -> Vector2i:
	for r in 12:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := t + Vector2i(dx, dy)
				if main.world.tile_free(c):
					return c
	return t

func _measure(walk: bool) -> Dictionary:
	var rs := RenderingServer
	var sum := 0.0
	var worst := 0.0
	var proc := 0.0
	var calls := 0.0
	var prims := 0.0
	var objs := 0.0
	var last := Time.get_ticks_usec()
	for i in FRAMES:
		if walk:
			main.world.move_dir = main.world.facing if main.world.tile_free(main.world.ptile + main.world.facing) else -main.world.facing
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		sum += ms
		worst = maxf(worst, ms)
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		calls += rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		objs += rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	main.world.move_dir = Vector2i.ZERO
	return {"frame_ms": snappedf(sum / FRAMES, 0.01), "worst_ms": snappedf(worst, 0.01), "fps": snappedf(1000.0 * FRAMES / sum, 0.1), "script_ms": snappedf(proc / FRAMES, 0.001),
		"draw_calls": int(calls / FRAMES), "primitives": int(prims / FRAMES), "objects": int(objs / FRAMES)}

var e_inst := {}

## What is in the scene: triangles (times instances) of everything visible, by the kind of thing it is.
func _census() -> Dictionary:
	var by := {}
	e_inst = {}
	var stack: Array = [main.world.scene3d]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Node3D and not (n as Node3D).visible:
			continue
		for c in n.get_children():
			stack.append(c)
		var tris := 0
		var kind := ""
		if main.args.has("census-view") and n is GeometryInstance3D:
			# only what the camera can see now: inside its frustum (by the middle of its bounds) and
			# inside the distances it is drawn between
			var gi := n as GeometryInstance3D
			var mid: Vector3 = gi.global_transform * gi.get_aabb().get_center()
			var dc := mid.distance_to(main.world.cam.global_position)
			var rad: float = gi.get_aabb().size.length() * 0.5
			if not main.world.cam.is_position_in_frustum(mid) and dc > rad:
				continue
			if gi.visibility_range_end > 0.0 and dc - rad * 0.5 > gi.visibility_range_end:
				continue
			if gi.visibility_range_begin > 0.0 and dc + rad * 0.5 < gi.visibility_range_begin:
				continue
			if dc - rad > main.world.cam.far:
				continue
		if n is MultiMeshInstance3D and n.multimesh != null and n.multimesh.mesh != null:
			var per := 0
			for si in n.multimesh.mesh.get_surface_count():
				per += _surface_tris(n.multimesh.mesh, si)
			var cnt: int = n.multimesh.visible_instance_count if n.multimesh.visible_instance_count >= 0 else n.multimesh.instance_count
			tris = per * cnt
			kind = "multimesh"
			if main.args.has("census-detail"):
				# (by how far it is drawn, whether it casts a shadow, and how heavy one instance is)
				kind = "mm r%03d %s %5d tris each" % [int(n.visibility_range_end), "shadow" if n.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else "      ", per]
		elif n is MeshInstance3D and n.mesh != null:
			for si in n.mesh.get_surface_count():
				tris += _surface_tris(n.mesh, si)
			kind = "skinned" if n.skin != null else "mesh"
		if kind == "":
			continue
		# name it by its ancestors: the first two below the 3D scene
		var chain: Array = []
		var q: Node = n
		while q != null and q != main.world.scene3d:
			chain.push_front(str(q.name).rstrip("0123456789@_"))
			q = q.get_parent()
		var key := kind + ":" + "/".join(chain.slice(0, 2))
		if main.args.has("census-detail") and kind.begins_with("mm "):
			key = kind
			e_inst[key] = int(e_inst.get(key, 0)) + (n as MultiMeshInstance3D).multimesh.instance_count
		var e: Array = by.get(key, [0, 0, 0])
		e[0] += tris
		e[1] += 1
		e[2] += 1 if (n as GeometryInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		by[key] = e
	return by

func _surface_tris(m: Mesh, si: int) -> int:
	if m is ArrayMesh:
		var il: int = m.surface_get_array_index_len(si)
		return (il if il > 0 else m.surface_get_array_len(si)) / 3
	return m.get_faces().size() / 3

func _print_census(title: String) -> void:
	var by := _census()
	var keys: Array = by.keys()
	keys.sort_custom(func(a, b): return by[a][0] > by[b][0])
	var total := 0
	var nodes := 0
	for k in keys:
		total += by[k][0]
		nodes += by[k][1]
	print("[census] %s: %d triangles in %d drawn nodes" % [title, total, nodes])
	for k in keys.slice(0, 28):
		print("[census]   %9d tris  %5d nodes  %5d cast shadows  %s%s" % [by[k][0], by[k][1], by[k][2], k, ("  x%d" % int(e_inst[k])) if e_inst.has(k) else ""])

func _run() -> void:
	await get_tree().process_frame
	var out := {"engine_ready_ms": Time.get_ticks_msec(), "stops": {}}
	Game.reset()
	Game.level = 12
	Game.companion = true
	Game.heal_full()
	Game.step = Data.step_index("s_break6") if Data.step_index("s_break6") >= 0 else 40
	if main.args.has("hour"):
		Game.clock = float(main.args.hour) * 60.0
	# (--title-wait=N: as long on the title screen and the making of the hero as a player would be,
	# while the land is generated in the background, Atlas.warm)
	if main.args.has("title-wait"):
		await get_tree().create_timer(float(main.args["title-wait"])).timeout
	var t0 := Time.get_ticks_usec()
	main.set_stack(["world"])
	main.world.open_world()
	main.world.enter_layer("surface")
	main.world.teleport(_free_near(Atlas.to_world("sect", Vector2i(36, 30))), "surface")
	main.world._snap_cam()
	await RenderingServer.frame_post_draw
	out["world_open_ms"] = snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1)
	out["title_to_world_ms"] = snappedf(Time.get_ticks_msec(), 0.1)
	print("[bench] engine ready %d ms, world open %.0f ms" % [out.engine_ready_ms, out.world_open_ms])
	if main.args.has("census"):
		_print_census("the sect")
		for cid in str(main.args.census).split(",", false):
			if Data.AREAS.has(cid):
				main.world.teleport(_free_near(Atlas.to_world(cid, Vector2i(30, 26))), "surface")
				main.world._snap_cam()
				await RenderingServer.frame_post_draw
				_print_census(cid)
		get_tree().quit()
		return
	var total_fps := 0.0
	if main.args.has("frames"):
		FRAMES = maxi(1, int(main.args.frames))
	var only: PackedStringArray = str(main.args.get("stops", "")).split(",", false)
	var n_stops := 0
	for st in STOPS:
		var id: String = st[0]
		if not only.is_empty() and not only.has(id):
			continue
		n_stops += 1
		var t1 := Time.get_ticks_usec()
		main.world.teleport(_free_near(Atlas.to_world(id, st[1])), "surface")
		main.world.facing = Vector2i(1, 0)
		main.world._snap_cam()
		await RenderingServer.frame_post_draw
		var arrive := (Time.get_ticks_usec() - t1) / 1000.0
		# let the streaming settle, then stand, then walk
		for i in (20 if FRAMES > 10 else 4):
			await get_tree().process_frame
		var stand: Dictionary = await _measure(false)
		var walk: Dictionary = await _measure(true)
		out.stops[id] = {"arrive_ms": snappedf(arrive, 0.1), "stand": stand, "walk": walk, "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}
		total_fps += walk.fps
		print("[bench] %-9s arrive %6.0f ms | stand %5.1f fps (script %.2f ms, %d calls, %d prims) | walk %5.1f fps, worst frame %.0f ms, script %.2f ms" % [id, arrive,
			stand.fps, stand.script_ms, stand.draw_calls, stand.primitives, walk.fps, walk.worst_ms, walk.script_ms])
	out["mean_walk_fps"] = snappedf(total_fps / maxi(1, n_stops), 0.1)
	print("[bench] mean walking fps %.1f" % out.mean_walk_fps)
	var path := str(main.args.bench)
	if path != "1" and path != "":
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(out, "  "))
	get_tree().quit()
