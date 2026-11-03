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

const THEMES := {
	"sect": {"g1": Color("5f9a6a"), "g2": Color("6aa874"), "path": Color("c9b88a"), "wall": Color("2f6a45"), "water": Color("3a78b8"), "bg": Color("0b1020")},
	"bamboo": {"g1": Color("4c8a56"), "g2": Color("559560"), "path": Color("b8a878"), "wall": Color("2d7a3a"), "water": Color("3a78b8"), "bg": Color("08140c")},
	"marsh": {"g1": Color("5a5a3c"), "g2": Color("63623f"), "path": Color("7a6a4a"), "wall": Color("3a2a22"), "water": Color("4a3a5a"), "bg": Color("140c10")},
	"frost": {"g1": Color("b4cce0"), "g2": Color("c2d6e8"), "path": Color("9ab4cc"), "wall": Color("6a9ac8"), "water": Color("2a4a8a"), "bg": Color("0a1018")},
	"thunder": {"g1": Color("52505e"), "g2": Color("5c5a6a"), "path": Color("72707e"), "wall": Color("2a2838"), "water": Color("2a3a6a"), "bg": Color("0a0a14")},
	"palace": {"g1": Color("40202c"), "g2": Color("4a2432"), "path": Color("602838"), "wall": Color("200c18"), "water": Color("6a1020"), "bg": Color("100408")},
}

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
	for i in 40:
		motes.append({"p": Vector2(randf() * VIEW.x, randf() * VIEW.y), "v": randf_range(8, 30), "s": randf_range(1.5, 3.5)})
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
	for m in motes:
		m.p.y -= m.v * d
		m.p.x += sin(t + m.s) * 6.0 * d
		if m.p.y < -10:
			m.p = Vector2(randf() * VIEW.x, VIEW.y + 10)
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

func _draw() -> void:
	if grid.is_empty():
		return
	var th: Dictionary = THEMES[theme_name]
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
			var base: Color = th.g1 if hv < 0.5 else th.g2
			match tile:
				MapGen.PATH:
					base = th.path
				MapGen.WATER:
					base = th.water
			draw_rect(Rect2(tp, Vector2(TS + 1, TS + 1)), base)
			if tile == MapGen.DECOR:
				_draw_decor(tp, hv, th)
			elif tile == MapGen.WATER:
				var sh := sin(t * 2.0 + x * 0.7 + y * 0.5) * 0.5 + 0.5
				draw_line(tp + Vector2(8, 16 + sh * 6), tp + Vector2(30, 16 + sh * 6), Color(1, 1, 1, 0.18), 2.0)
				draw_line(tp + Vector2(14, 32 - sh * 5), tp + Vector2(40, 32 - sh * 5), Color(1, 1, 1, 0.12), 2.0)
	# obstacles drawn after ground so tall things overlap properly
	for y in range(y0, y1 + 2):
		if y >= h:
			break
		for x in range(x0, x1 + 1):
			var tile := grid[y * w + x]
			if tile == MapGen.WALL or tile == MapGen.BUILDING:
				_draw_obstacle(Vector2(x, y) * TS - cam, x, y, tile, th)
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
	for m in motes:
		draw_circle(m.p, m.s, Color(1, 1, 0.8, 0.28))
	_draw_vignette()
	_draw_hud()

func _draw_decor(tp: Vector2, hv: float, th: Dictionary) -> void:
	var c: Color = th.g1.lightened(0.25) if theme_name != "frost" else Color.WHITE
	if theme_name == "palace":
		c = Color("7a2038")
	for i in 3:
		var ox := 10.0 + i * 11.0 + hv * 4.0
		draw_line(tp + Vector2(ox, 36), tp + Vector2(ox + (i - 1) * 3.0, 24 + hv * 6.0), c, 2.0)
	if theme_name == "sect" or theme_name == "bamboo":
		draw_circle(tp + Vector2(12 + hv * 24, 14 + hv * 12), 2.5, Color("ffd0e0") if hv > 0.5 else Color("fff0a0"))

func _draw_obstacle(tp: Vector2, x: int, y: int, tile: int, th: Dictionary) -> void:
	var hv := _hash(x * 3, y * 5)
	var wall: Color = th.wall
	if tile == MapGen.BUILDING:
		draw_rect(Rect2(tp, Vector2(TS + 1, TS + 1)), Color("8a4a3a").darkened(0.1 * hv))
		draw_rect(Rect2(tp + Vector2(0, TS - 10), Vector2(TS + 1, 10)), Color("5a2a20"))
		draw_line(tp + Vector2(0, 0), tp + Vector2(TS, 0), Color("c9a85c"), 3.0)
		if hv > 0.6:
			draw_rect(Rect2(tp + Vector2(14, 14), Vector2(18, 18)), Color("ffe9a8"))
		return
	match theme_name:
		"bamboo", "sect":
			for i in 3:
				var ox := 8.0 + i * 14.0 + hv * 4.0
				draw_line(tp + Vector2(ox, TS), tp + Vector2(ox, -30 + hv * 12), wall.lightened(0.15 * i), 6.0)
				for k in 3:
					draw_line(tp + Vector2(ox - 3, 6 + k * 14), tp + Vector2(ox + 3, 6 + k * 14), wall.darkened(0.4), 2.0)
				draw_colored_polygon(PackedVector2Array([tp + Vector2(ox, -20 + hv * 12), tp + Vector2(ox + 16, -10), tp + Vector2(ox + 2, -14)]), wall.lightened(0.35))
		"marsh":
			draw_line(tp + Vector2(24, TS), tp + Vector2(24, -14), wall, 7.0)
			draw_line(tp + Vector2(24, 0), tp + Vector2(6, -16), wall, 4.0)
			draw_line(tp + Vector2(24, -4), tp + Vector2(44, -20), wall, 4.0)
			draw_circle(tp + Vector2(10, -16), 5, Color("4a6a2a"))
			draw_circle(tp + Vector2(42, -20), 5, Color("4a6a2a"))
		"frost":
			var base := tp + Vector2(24, TS)
			draw_colored_polygon(PackedVector2Array([base + Vector2(-18, 0), base + Vector2(-6, -52 - hv * 14), base + Vector2(4, -10), base + Vector2(12, -40 - hv * 8), base + Vector2(20, 0)]), wall)
			draw_colored_polygon(PackedVector2Array([base + Vector2(-6, -52 - hv * 14), base + Vector2(4, -10), base + Vector2(-2, -10)]), wall.lightened(0.45))
		"thunder":
			var base2 := tp + Vector2(24, TS)
			draw_colored_polygon(PackedVector2Array([base2 + Vector2(-22, 0), base2 + Vector2(-14, -34 - hv * 10), base2 + Vector2(8, -40), base2 + Vector2(22, 0)]), wall)
			draw_polyline(PackedVector2Array([base2 + Vector2(-4, -36), base2 + Vector2(2, -22), base2 + Vector2(-5, -14), base2 + Vector2(3, -2)]), Color("f6e85c") if hv > 0.5 else Color("9a8aff"), 2.0)
		"palace":
			draw_rect(Rect2(tp + Vector2(8, -40), Vector2(32, TS + 40)), wall.lightened(0.1))
			draw_rect(Rect2(tp + Vector2(4, -46), Vector2(40, 8)), Color("902038"))
			draw_line(tp + Vector2(24, -34), tp + Vector2(24, TS), Color("e03050"), 2.0)

func _draw_entity(e: Dictionary, sp: Vector2) -> void:
	var cx := sp + Vector2(TS * 0.5, TS * 0.5)
	match e.kind:
		"npc":
			UI.human(self, sp + Vector2(TS * 0.5, TS - 6), 1.25, e.col, Color("2a2a3a"), t + e.pos.x)
			UI.text(self, sp + Vector2(-60, -22), e.n, 15, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, TS + 120)
			var s := Game.cur_step()
			if not s.is_empty() and s.kind == "talk" and s.npc == e.id:
				UI.text(self, sp + Vector2(0, -42 + sin(t * 4) * 3), "!", 30, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, TS)
		"enemy":
			var g: Array = e.group
			var d: Dictionary = Data.ENEMIES[g[0].id]
			UI.monster(self, d.shape, cx, 0.8, d.col, t)
			UI.text(self, sp + Vector2(-40, -14), "%s x%d" % [d.n, g.size()], 13, UI.C_RED.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER, TS + 80)
		"boss":
			var d2: Dictionary = Data.ENEMIES[e.enemy]
			UI.monster(self, d2.shape, cx + Vector2(0, -6), 1.55, d2.col, t, true)
			UI.text(self, sp + Vector2(-80, -52), d2.n, 17, UI.C_RED, HORIZONTAL_ALIGNMENT_CENTER, TS + 160)
		"pickup":
			var col: Color = {"herb": Color("6fe08a"), "lotus": Color("ff7aa8"), "jade": Color("7affe0"), "shard": Color("f6e85c")}[e.item]
			var gl := 0.5 + 0.5 * sin(t * 3.0 + e.pos.x)
			draw_circle(cx, 14 + gl * 4, Color(col.r, col.g, col.b, 0.25))
			draw_colored_polygon(PackedVector2Array([cx + Vector2(0, -12), cx + Vector2(9, 0), cx + Vector2(0, 12), cx + Vector2(-9, 0)]), col)
			UI.text(self, sp + Vector2(-30, -6), Data.ITEMS[e.item].n, 13, col, HORIZONTAL_ALIGNMENT_CENTER, TS + 60)
		"portal":
			var open: bool = e.open == "" or Game.done(e.open)
			var pc := UI.C_JADE if open else Color("8a4a4a")
			for i in 3:
				var rr := 18.0 + i * 5.0 + sin(t * 3.0 + i) * 2.0
				draw_arc(cx, rr, t * (1 + i), t * (1 + i) + PI * 1.4, 20, pc, 3.0)
			UI.text(self, sp + Vector2(-60, -22), ("To " + Data.AREAS[e.to].n) if open else "Sealed", 14, pc, HORIZONTAL_ALIGNMENT_CENTER, TS + 120)
		"spring":
			pass

func _draw_player(sp: Vector2) -> void:
	UI.human(self, sp + Vector2(TS * 0.5, TS - 4), 1.3, Color("3a8ae8"), Color("1a1a2a"), t * (2.0 if move_t >= 0.0 else 1.0), true)
	if Game.companion:
		var back := sp - Vector2(facing) * 26.0
		UI.human(self, back + Vector2(TS * 0.5, TS - 4), 1.2, Color("e86a9a"), Color("402030"), t + 1.0)

func _draw_vignette() -> void:
	for i in 6:
		var a := 0.07
		var m := float(i) * 22.0
		draw_rect(Rect2(m, m, VIEW.x - 2 * m, VIEW.y - 2 * m), Color(0, 0, 0, a), false, 24.0)

func _draw_hud() -> void:
	UI.panel(self, Rect2(12, 12, 330, 118))
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
