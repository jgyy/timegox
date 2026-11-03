extends Node2D
## Top-down tile world: rendering, grid movement, entity interaction.

const TS := 48
const STEP_T := 0.16
const VIEW := Vector2(1280, 720)

var main
var opaque := false
var area_id := ""
var w := 0
var h := 0
var grid := PackedByteArray()
var ents: Array = []
var theme_name := ""
var area_name := ""
var ptile := Vector2i(1, 1)
var target := Vector2i(1, 1)
var move_t := -1.0
var facing := Vector2i(1, 0)
var move_dir := Vector2i.ZERO
var t := 0.0
var cam := Vector2.ZERO
var motes: Array = []
var banner_t := 0.0
var cache := {}
var mini_tex: ImageTexture = null



func setup(m) -> void:
	main = m

func load_area(id: String, at: Vector2i) -> void:
	area_id = id
	if not cache.has(id):
		cache[id] = MapGen.build(id)
	var m: Dictionary = cache[id]
	w = m.w
	h = m.h
	grid = m.grid
	ents = m.ents
	theme_name = m.theme
	area_name = m.name
	ptile = at
	target = at
	move_t = -1.0
	Game.area = id
	Game.tile = at
	banner_t = 3.0
	motes.clear()
	for i in 46:
		motes.append({"p": Vector2(randf() * VIEW.x, randf() * VIEW.y), "v": randf_range(8, 30), "s": randf_range(1.5, 3.5)})
	mini_tex = Gfx.minimap_image(grid, w, h, Gfx.THEMES[theme_name])
	_snap_cam()

func _snap_cam() -> void:
	cam = _cam_target()

func _cam_target() -> Vector2:
	var pp := Vector2(ptile) * TS + Vector2(TS, TS) * 0.5
	if move_t >= 0.0:
		pp = pp.lerp(Vector2(target) * TS + Vector2(TS, TS) * 0.5, move_t)
	var c := pp - VIEW * 0.5
	c.x = clampf(c.x, 0, maxf(0, w * TS - VIEW.x))
	c.y = clampf(c.y, 0, maxf(0, h * TS - VIEW.y))
	return c

# ---------------------------------------------------------------- entities
func ent_visible(e: Dictionary) -> bool:
	match e.kind:
		"enemy":
			var k: String = area_id + ":" + e.id
			if Game.defeated.has(k):
				return false
			return true
		"boss":
			return not Game.boss_done.has(e.enemy)
		"pickup":
			if Game.taken.has(e.id):
				return false
		"portal":
			return true
	var v = e.get("vis", ["", ""])
	if v[0] != "" and not Game.reached(v[0]):
		return false
	if v[1] != "" and Game.done(v[1]):
		return false
	return true

func ent_at(tile: Vector2i):
	for e in ents:
		if e.pos == tile and e.kind != "spring" and ent_visible(e):
			return e
	return null

func tile_free(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= w or tile.y >= h:
		return false
	return MapGen.is_walkable_tile(grid[tile.y * w + tile.x])

func near_spring() -> bool:
	for e in ents:
		if e.kind == "spring":
			if maxi(absi(e.pos.x - ptile.x), absi(e.pos.y - ptile.y)) <= 3:
				return true
	return false

func find_ent(id: String):
	for e in ents:
		if e.id == id:
			return e
	return null

# ---------------------------------------------------------------- update
func _process(d: float) -> void:
	t += d
	if banner_t > 0.0:
		banner_t -= d
	Gfx.step_motes(motes, theme_name, d, t, VIEW)
	# respawn defeated enemies after a while (only when away from them)
	for k in Game.defeated.keys():
		if Game.playtime - Game.defeated[k] > 150.0 and k.begins_with(area_id + ":"):
			var e = find_ent(k.get_slice(":", 1))
			if e != null and maxi(absi(e.pos.x - ptile.x), absi(e.pos.y - ptile.y)) > 6:
				Game.defeated.erase(k)
	var active: bool = main.top_name() == "world"
	if not active:
		cam = cam.lerp(_cam_target(), minf(1.0, d * 8.0))
		queue_redraw()
		return
	if not main.bot_active:
		move_dir = _read_keys()
	_move(minf(d, 0.1))
	cam = cam.lerp(_cam_target(), minf(1.0, d * 10.0))
	queue_redraw()

func _read_keys() -> Vector2i:
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		return Vector2i(-1, 0)
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		return Vector2i(1, 0)
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		return Vector2i(0, -1)
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		return Vector2i(0, 1)
	return Vector2i.ZERO

func _move(d: float) -> void:
	var budget := d
	while budget > 0.0001:
		if move_t < 0.0:
			if move_dir == Vector2i.ZERO:
				return
			facing = move_dir
			var nt := ptile + move_dir
			var e = ent_at(nt)
			if e != null and e.kind != "portal":
				move_dir = Vector2i.ZERO
				main.interact(e)
				return
			if not tile_free(nt):
				return
			target = nt
			move_t = 0.0
		var need := (1.0 - move_t) * STEP_T
		if budget >= need:
			budget -= need
			ptile = target
			move_t = -1.0
			Game.tile = ptile
			var pe = ent_at(ptile)
			if pe != null and pe.kind == "portal":
				main.use_portal(pe)
				return
		else:
			move_t += budget / STEP_T
			budget = 0.0

func face_entity():
	return ent_at(ptile + facing)

# ---------------------------------------------------------------- drawing
func _hash(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)

func _water_shore(x: int, y: int) -> int:
	var m := 0
	if y > 0 and grid[(y - 1) * w + x] != MapGen.WATER:
		m |= Gfx.N
	if x < w - 1 and grid[y * w + x + 1] != MapGen.WATER:
		m |= Gfx.E
	if y < h - 1 and grid[(y + 1) * w + x] != MapGen.WATER:
		m |= Gfx.S
	if x > 0 and grid[y * w + x - 1] != MapGen.WATER:
		m |= Gfx.W
	return m

func _draw() -> void:
	if grid.is_empty():
		return
	var th: Dictionary = Gfx.THEMES[theme_name]
	draw_rect(Rect2(Vector2.ZERO, VIEW), th.bg)
	var x0 := maxi(0, int(cam.x / TS))
	var y0 := maxi(0, int(cam.y / TS))
	var x1 := mini(w - 1, int((cam.x + VIEW.x) / TS) + 1)
	var y1 := mini(h - 1, int((cam.y + VIEW.y) / TS) + 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var tp := Vector2(x, y) * TS - cam
			var tile := grid[y * w + x]
			var hv := _hash(x, y)
			match tile:
				MapGen.PATH:
					Gfx.path_tile(self, tp, x, y, th)
				MapGen.WATER:
					Gfx.water_tile(self, tp, x, y, th, theme_name, t, _water_shore(x, y))
				_:
					Gfx.ground(self, tp, x, y, th, theme_name, t)
					if tile == MapGen.DECOR:
						Gfx.decor(self, tp, x, y, hv, th, theme_name, t)
	# obstacles drawn after ground so tall things overlap properly
	for y in range(y0, y1 + 2):
		if y >= h:
			break
		for x in range(x0, x1 + 1):
			var tile := grid[y * w + x]
			if tile == MapGen.WALL or tile == MapGen.BUILDING:
				Gfx.obstacle(self, Vector2(x, y) * TS - cam, x, y, tile == MapGen.BUILDING, th, theme_name, t)
	# entities sorted by y
	var vis: Array = []
	for e in ents:
		if ent_visible(e):
			var sp := Vector2(e.pos) * TS - cam
			if sp.x > -TS * 3 and sp.x < VIEW.x + TS * 3 and sp.y > -TS * 3 and sp.y < VIEW.y + TS * 3:
				vis.append(e)
	vis.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	var drawn_player := false
	var pp := Vector2(ptile) * TS
	if move_t >= 0.0:
		pp = pp.lerp(Vector2(target) * TS, move_t)
	for e in vis:
		if not drawn_player and e.pos.y >= ptile.y:
			_draw_player(pp - cam)
			drawn_player = true
		_draw_entity(e, Vector2(e.pos) * TS - cam)
	if not drawn_player:
		_draw_player(pp - cam)
	# ambience
	Gfx.weather(self, theme_name, motes, t, VIEW)
	Gfx.grade(self, theme_name, VIEW)
	_draw_hud()

func _npc_opts(id: String) -> Dictionary:
	match id:
		"elder":
			return {"beard": true, "staff": true}
		"alchemist":
			return {"hat": true}
		"smith":
			return {"sash": false}
		"yue_ling":
			return {"ribbon": Color("ff9ac0")}
		"sword_ghost":
			return {"sword": true, "beard": true}
		"dragon_envoy", "gate_keeper":
			return {"staff": true}
		"fire_sage", "void_hermit":
			return {"beard": true, "hat": true}
	return {}

func _draw_entity(e: Dictionary, sp: Vector2) -> void:
	var cx := sp + Vector2(TS * 0.5, TS * 0.5)
	match e.kind:
		"npc":
			var o := _npc_opts(e.id)
			if e.id == "sword_ghost":
				Gfx.glow(self, cx, 40.0, Color(0.6, 0.85, 1.0, 0.45), 5)
			UI.human(self, sp + Vector2(TS * 0.5, TS - 6), 1.35, e.col, Color("2a2a3a"), t + e.pos.x, o.get("sword", false), o)
			UI.panel(self, Rect2(sp + Vector2(-34, -46), Vector2(TS + 68, 22)), Color(0.04, 0.06, 0.13, 0.7), Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, 0.6))
			UI.text(self, sp + Vector2(-34, -30), e.n, 14, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, TS + 68)
			var s := Game.cur_step()
			if not s.is_empty() and s.kind == "talk" and s.npc == e.id:
				Gfx.glow(self, sp + Vector2(TS * 0.5, -62 + sin(t * 4) * 3), 20.0, Color(1, 0.85, 0.3, 0.5), 4)
				UI.text(self, sp + Vector2(0, -54 + sin(t * 4) * 3), "!", 32, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, TS)
		"enemy":
			var g: Array = e.group
			var d: Dictionary = Data.ENEMIES[g[0].id]
			UI.monster(self, d.shape, cx, 0.8, d.col, t)
			for k in range(1, mini(g.size(), 3)):
				var d2: Dictionary = Data.ENEMIES[g[k].id]
				UI.monster(self, d2.shape, cx + Vector2(k * 14.0 * (1.0 if k % 2 == 1 else -1.0), -k * 3.0), 0.5, d2.col, t + k)
			UI.panel(self, Rect2(sp + Vector2(-40, -26), Vector2(TS + 80, 20)), Color(0.12, 0.03, 0.04, 0.7), Color(0.9, 0.35, 0.3, 0.6))
			UI.text(self, sp + Vector2(-40, -11), "%s x%d" % [d.n, g.size()], 13, UI.C_RED.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, TS + 80)
		"boss":
			var d3: Dictionary = Data.ENEMIES[e.enemy]
			UI.monster(self, d3.shape, cx + Vector2(0, -6), 1.55, d3.col, t, true)
			UI.panel(self, Rect2(sp + Vector2(-90, -66), Vector2(TS + 180, 26)), Color(0.16, 0.02, 0.04, 0.8), UI.C_RED)
			UI.text(self, sp + Vector2(-90, -47), d3.n, 16, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, TS + 180)
		"pickup":
			var col: Color = Gfx.PICKUP_COLORS[e.item]
			var gl := 0.5 + 0.5 * sin(t * 3.0 + e.pos.x)
			var fl := Vector2(0, sin(t * 2.0 + e.pos.y) * 3.0)
			Gfx.shadow(self, cx + Vector2(0, 16), 11.0, 4.0, 0.3)
			Gfx.glow(self, cx + fl, 26.0 + gl * 6.0, Color(col.r, col.g, col.b, 0.55), 6)
			Gfx.diamond(self, cx + fl, 13.0, col)
			Gfx.diamond(self, cx + fl + Vector2(-2, -3), 6.0, Color(1, 1, 1, 0.7))
			for k in 3:
				var a := t * 1.5 + k * TAU / 3.0
				Gfx.star4(self, cx + fl + Vector2(cos(a), sin(a)) * 20.0, 3.0, Color(1, 1, 1, 0.7))
			UI.text(self, sp + Vector2(-30, -8), Data.ITEMS[e.item].n, 13, col, HORIZONTAL_ALIGNMENT_CENTER, TS + 60)
		"portal":
			var open: bool = e.open == "" or Game.done(e.open)
			var pc := UI.C_JADE if open else Color("8a4a4a")
			Gfx.glow(self, cx, 40.0, Color(pc.r, pc.g, pc.b, 0.5), 6)
			for i in 4:
				var rr := 14.0 + i * 5.0 + sin(t * 3.0 + i) * 2.0
				draw_arc(cx, rr, t * (1 + i * 0.7), t * (1 + i * 0.7) + PI * 1.4, 20, Color(pc.r, pc.g, pc.b, 1.0 - i * 0.18), 3.0)
			for k in 6:
				var a2 := t * 1.2 + k * TAU / 6.0
				draw_circle(cx + Vector2(cos(a2), sin(a2)) * (26.0 + sin(t * 2 + k) * 4.0), 2.0, Color(1, 1, 1, 0.7))
			UI.text(self, sp + Vector2(-60, -22), ("To " + Data.AREAS[e.to].n) if open else "Sealed", 14, pc, HORIZONTAL_ALIGNMENT_CENTER, TS + 120)
		"spring":
			pass

func _draw_player(sp: Vector2) -> void:
	var o := {"walk": move_t >= 0.0, "face": 1 if facing.x >= 0 else -1, "ribbon": null}
	o.erase("ribbon")
	if Game.companion:
		var back := sp - Vector2(facing) * 26.0
		UI.human(self, back + Vector2(TS * 0.5, TS - 4), 1.25, Color("e86a9a"), Color("402030"), t * (2.0 if move_t >= 0.0 else 1.0) + 1.0, false, {"ribbon": Color("ffb0cc"), "walk": move_t >= 0.0, "face": o.face})
	Gfx.glow(self, sp + Vector2(TS * 0.5, TS * 0.6), 34.0, Color(0.4, 0.7, 1.0, 0.3), 5)
	UI.human(self, sp + Vector2(TS * 0.5, TS - 4), 1.4, Color("3a8ae8"), Color("1a1a2a"), t, true, o)

func _draw_hud() -> void:
	UI.panel(self, Rect2(12, 12, 330, 128))
	UI.text(self, Vector2(26, 38), "Lin Feng", 20, UI.C_GOLD)
	UI.text(self, Vector2(26, 58), Data.level_name(Game.level), 15, UI.C_TEXT)
	var need := Game.exp_need()
	if Game.level < Data.MAX_LEVEL:
		UI.bar(self, Rect2(26, 66, 300, 8), Game.exp / float(need), UI.C_GOLD)
	UI.text(self, Vector2(26, 92), "HP %d/%d" % [Game.hp[0], Game.max_hp(0)], 14)
	UI.bar(self, Rect2(100, 80, 226, 10), Game.hp[0] / float(Game.max_hp(0)), UI.C_RED)
	UI.text(self, Vector2(26, 112), "QI %d/%d" % [Game.qi[0], Game.max_qi(0)], 14)
	UI.bar(self, Rect2(100, 100, 226, 10), Game.qi[0] / float(Game.max_qi(0)), UI.C_BLUE)
	UI.text(self, Vector2(26, 126), "Stones: %d" % Game.stones, 13, UI.C_DIM)
	# objective
	UI.panel(self, Rect2(VIEW.x - 520, 12, 508, 58))
	UI.text(self, Vector2(VIEW.x - 506, 34), "Objective", 13, UI.C_DIM)
	UI.text(self, Vector2(VIEW.x - 506, 56), Game.objective_text(), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 480)
	UI.text(self, Vector2(VIEW.x - 140, VIEW.y - 14), "Esc: Menu   Z/Enter: Act", 13, UI.C_DIM)
	_draw_minimap()
	if banner_t > 0.0:
		var a := clampf(banner_t, 0.0, 1.0)
		UI.panel(self, Rect2(VIEW.x * 0.5 - 220, 96, 440, 52), Color(0.04, 0.06, 0.13, 0.85 * a), Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, a))
		UI.text(self, Vector2(VIEW.x * 0.5 - 220, 130), area_name, 26, Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, a), HORIZONTAL_ALIGNMENT_CENTER, 440)
	# toasts
	var y := 170.0
	var i := 0
	for s in main.toast_list:
		UI.text(self, Vector2(VIEW.x * 0.5 - 300, y + i * 26), s.text, 18, Color(UI.C_JADE.r, UI.C_JADE.g, UI.C_JADE.b, clampf(s.t, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, 600)
		i += 1

func _draw_minimap() -> void:
	if mini_tex == null:
		return
	var mw := 190.0
	var r := Rect2(VIEW.x - mw - 16, 88, mw, mw * h / float(w))
	var marks: Array = []
	for e in ents:
		if not ent_visible(e):
			continue
		match e.kind:
			"portal":
				marks.append({"pos": e.pos, "col": UI.C_JADE})
			"npc":
				marks.append({"pos": e.pos, "col": UI.C_GOLD})
			"boss":
				marks.append({"pos": e.pos, "col": Color("ff3030")})
			"pickup":
				marks.append({"pos": e.pos, "col": Color("ffffff")})
	Gfx.draw_minimap(self, mini_tex, r, w, h, ptile, marks, t)
	UI.text(self, r.position + Vector2(0, r.size.y + 20), area_name, 12, UI.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, mw)
