class_name UI
extends RefCounted
## Procedural drawing helpers.  The game ships with no external art: everything is drawn in code.

const C_BG := Color("0b1020")
const C_PANEL := Color(0.04, 0.06, 0.13, 0.9)
const C_BORDER := Color("c9a85c")
const C_TEXT := Color("f2ead3")
const C_DIM := Color("8a8fa8")
const C_JADE := Color("5fd6a4")
const C_RED := Color("e0584f")
const C_BLUE := Color("5aa9ff")
const C_GOLD := Color("f0c860")
const SHAPES := ["beast", "humanoid", "wisp", "blob", "wraith", "plant", "dragon", "bird", "demon", "storm", "hero", "healer", "golem", "serpent", "crab", "spider", "jelly", "phoenix"]

static func font() -> Font:
	return ThemeDB.fallback_font

static func text(ci: CanvasItem, p: Vector2, s: String, size: int = 20, col: Color = C_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	ci.draw_string(font(), p + Vector2(1.5, 1.5), s, align, width, size, Color(0, 0, 0, 0.7))
	ci.draw_string(font(), p, s, align, width, size, col)

static func wrapped(ci: CanvasItem, p: Vector2, s: String, size: int, col: Color, width: float) -> void:
	ci.draw_multiline_string(font(), p + Vector2(1.5, 1.5), s, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, Color(0, 0, 0, 0.7))
	ci.draw_multiline_string(font(), p, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, col)

static func panel(ci: CanvasItem, r: Rect2, fill: Color = C_PANEL, border: Color = C_BORDER) -> void:
	Gfx.panel(ci, r, fill, border)

static func bar(ci: CanvasItem, r: Rect2, ratio: float, col: Color, bg: Color = Color(0, 0, 0, 0.55)) -> void:
	Gfx.bar(ci, r, ratio, col, bg)

static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)

static func menu_list(ci: CanvasItem, r: Rect2, labels: Array, cursor: int, enabled: Array = [], size: int = 22) -> void:
	panel(ci, r)
	var y := r.position.y + 16.0 + size
	for i in labels.size():
		var on: bool = enabled.is_empty() or enabled[i]
		var col := C_TEXT if on else C_DIM
		if i == cursor:
			Gfx.cursor_glow(ci, Rect2(r.position.x + 8, y - size, r.size.x - 16, size + 8), Time.get_ticks_msec() / 1000.0)
			text(ci, Vector2(r.position.x + 14, y), "> ", size, C_GOLD)
		text(ci, Vector2(r.position.x + 38, y), str(labels[i]), size, col)
		y += size + 10

# ---------------------------------------------------------------- characters
static func human(ci: CanvasItem, c: Vector2, s: float, robe: Color, hair: Color, t: float, sword: bool = false, opts: Dictionary = {}) -> void:
	var o := opts.duplicate()
	o["sword"] = sword
	GfxActors.person(ci, c, s, robe, hair, t, o)

static func monster(ci: CanvasItem, shape: String, c: Vector2, s: float, col: Color, t: float, aura: bool = false) -> void:
	# c = center point, s = scale (1.0 ~ 44px tall)
	var dark := col.darkened(0.45)
	var light := col.lightened(0.35)
	var bob := sin(t * 2.4 + c.x * 0.01) * 2.0 * s
	var p := c + Vector2(0, bob)
	if aura:
		Gfx.glow(ci, p, 58.0 * s, Color(col.r, col.g, col.b, 0.28), 6)
		for i in 3:
			ci.draw_circle(p, (34 + i * 9 + sin(t * 3.0 + i) * 3) * s, Color(col.r, col.g, col.b, 0.06))
		ci.draw_arc(p, (50 + sin(t * 2.0) * 3) * s, t, t + 4.2, 24, Color(col.r, col.g, col.b, 0.35), 2.0)
	Gfx.shadow(ci, c + Vector2(0, 24 * s), 20 * s, 6 * s, 0.35)
	match shape:
		"beast":
			ellipse(ci, p + Vector2(-2, 6) * s, 20 * s, 12 * s, col)
			ellipse(ci, p + Vector2(15, -4) * s, 10 * s, 9 * s, light)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(11, -11) * s, p + Vector2(14, -22) * s, p + Vector2(18, -11) * s]), dark)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(17, -11) * s, p + Vector2(22, -21) * s, p + Vector2(23, -9) * s]), dark)
			ci.draw_circle(p + Vector2(19, -5) * s, 2.2 * s, Color("ffe060"))
			ci.draw_line(p + Vector2(-20, 6) * s, p + Vector2(-30, -4) * s, dark, 4.0 * s)
			ci.draw_line(p + Vector2(-8, 16) * s, p + Vector2(-8, 24) * s, dark, 4.0 * s)
			ci.draw_line(p + Vector2(8, 16) * s, p + Vector2(8, 24) * s, dark, 4.0 * s)
		"humanoid":
			human(ci, p + Vector2(0, 20 * s), 1.25 * s, col, dark, t, true)
		"wisp":
			for i in 5:
				ci.draw_circle(p + Vector2(-8 * i, 3 * i + sin(t * 4 + i) * 3) * s, (10 - i * 1.6) * s, Color(col.r, col.g, col.b, 0.55 - i * 0.09))
			ci.draw_circle(p, 12 * s, light)
			ci.draw_circle(p + Vector2(4, -2) * s, 2.5 * s, Color.BLACK)
			ci.draw_circle(p + Vector2(-3, -2) * s, 2.5 * s, Color.BLACK)
		"blob":
			ellipse(ci, p + Vector2(0, 6) * s, 24 * s, 16 * s, col)
			ellipse(ci, p + Vector2(-4, 0) * s, 12 * s, 7 * s, light)
			ci.draw_circle(p + Vector2(-8, -2) * s, 3.5 * s, Color.WHITE)
			ci.draw_circle(p + Vector2(8, -2) * s, 3.5 * s, Color.WHITE)
			ci.draw_circle(p + Vector2(-8, -2) * s, 1.6 * s, Color.BLACK)
			ci.draw_circle(p + Vector2(8, -2) * s, 1.6 * s, Color.BLACK)
		"wraith":
			var cloak := PackedVector2Array([p + Vector2(0, -22) * s, p + Vector2(16, -4) * s, p + Vector2(20, 20) * s, p + Vector2(8, 14 + sin(t * 5) * 3) * s, p + Vector2(0, 22) * s, p + Vector2(-8, 14 + cos(t * 5) * 3) * s, p + Vector2(-20, 20) * s, p + Vector2(-16, -4) * s])
			ci.draw_colored_polygon(cloak, Color(col.r, col.g, col.b, 0.85))
			ci.draw_circle(p + Vector2(-5, -8) * s, 3 * s, Color("ffffff"))
			ci.draw_circle(p + Vector2(5, -8) * s, 3 * s, Color("ffffff"))
		"plant":
			for i in 5:
				var a := -PI / 2 + (i - 2) * 0.55 + sin(t * 2 + i) * 0.12
				ci.draw_line(p + Vector2(0, 14) * s, p + Vector2(cos(a), sin(a)) * 30 * s + Vector2(0, 14) * s, dark, 4.0 * s)
				ci.draw_circle(p + Vector2(cos(a), sin(a)) * 30 * s + Vector2(0, 14) * s, 4.5 * s, light)
			ellipse(ci, p + Vector2(0, 8) * s, 14 * s, 12 * s, col)
			ci.draw_circle(p + Vector2(0, 6) * s, 5 * s, Color("ffd0f0"))
		"dragon":
			var prev := p + Vector2(-40, 10) * s
			for i in 12:
				var f := i / 11.0
				var pt := p + Vector2(-40 + f * 64, 10 - sin(f * 5.0 + t * 2.0) * 12 - f * 14) * s
				ci.draw_line(prev, pt, col.lerp(light, f), (7 + f * 8) * s)
				prev = pt
			ellipse(ci, prev + Vector2(6, -2) * s, 13 * s, 9 * s, light)
			ci.draw_colored_polygon(PackedVector2Array([prev + Vector2(-2, -8) * s, prev + Vector2(2, -22) * s, prev + Vector2(8, -8) * s]), dark)
			ci.draw_circle(prev + Vector2(10, -4) * s, 2.5 * s, Color("ff4040"))
		"bird":
			var flap := sin(t * 6.0) * 10.0
			ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(-34, -16 + flap) * s, p + Vector2(-14, 6) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(34, -16 + flap) * s, p + Vector2(14, 6) * s]), col)
			ellipse(ci, p + Vector2(0, 4) * s, 10 * s, 14 * s, light)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, -10) * s, p + Vector2(0, -2) * s, p + Vector2(3, -10) * s]), C_GOLD)
			ci.draw_circle(p + Vector2(-3, -12) * s, 1.8 * s, Color.BLACK)
			ci.draw_circle(p + Vector2(3, -12) * s, 1.8 * s, Color.BLACK)
		"demon":
			human(ci, p + Vector2(0, 24 * s), 1.7 * s, dark, Color("200010"), t, false)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -34) * s, p + Vector2(-14, -50) * s, p + Vector2(-2, -38) * s]), light)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(8, -34) * s, p + Vector2(14, -50) * s, p + Vector2(2, -38) * s]), light)
			ci.draw_circle(p + Vector2(-3, -26) * s, 1.8 * s, Color("ff3030"))
			ci.draw_circle(p + Vector2(3, -26) * s, 1.8 * s, Color("ff3030"))
		"storm":
			for i in 4:
				ellipse(ci, p + Vector2(-26 + i * 17, -12 + sin(t + i) * 3) * s, 20 * s, 11 * s, Color(0.35, 0.38, 0.55, 0.9))
			var bolt_x := sin(t * 11.0) * 6.0
			ci.draw_polyline(PackedVector2Array([p + Vector2(bolt_x, -4) * s, p + Vector2(bolt_x - 8, 10) * s, p + Vector2(bolt_x + 5, 12) * s, p + Vector2(bolt_x - 6, 30) * s]), Color("f4f8ff"), 3.0 * s)
		"hero":
			human(ci, p + Vector2(0, 24 * s), 2.0 * s, Color("3a8ae8"), Color("1a1a2a"), t, true)
		"healer":
			human(ci, p + Vector2(0, 24 * s), 1.9 * s, Color("e86a9a"), Color("402030"), t, false)
		_:
			if not GfxActors.monster_ext(ci, shape, p, s, col, t):
				ellipse(ci, p, 16 * s, 16 * s, col)
