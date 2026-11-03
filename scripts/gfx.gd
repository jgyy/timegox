class_name Gfx
extends RefCounted
## Procedural art library, part 1: gradients, terrain tiles, obstacles, weather,
## battle backdrops, minimap and ornate UI.  No external art; everything is code.

const TS := 48
const N := 1
const E := 2
const S := 4
const W := 8

const THEMES := {
	"sect": {"g1": Color("5f9a6a"), "g2": Color("6aa874"), "path": Color("c9b88a"), "wall": Color("2f6a45"), "water": Color("3a78b8"), "bg": Color("0b1020")},
	"bamboo": {"g1": Color("4c8a56"), "g2": Color("559560"), "path": Color("b8a878"), "wall": Color("2d7a3a"), "water": Color("3a78b8"), "bg": Color("08140c")},
	"marsh": {"g1": Color("5a5a3c"), "g2": Color("63623f"), "path": Color("7a6a4a"), "wall": Color("3a2a22"), "water": Color("4a3a5a"), "bg": Color("140c10")},
	"frost": {"g1": Color("b4cce0"), "g2": Color("c2d6e8"), "path": Color("9ab4cc"), "wall": Color("6a9ac8"), "water": Color("2a4a8a"), "bg": Color("0a1018")},
	"thunder": {"g1": Color("52505e"), "g2": Color("5c5a6a"), "path": Color("72707e"), "wall": Color("2a2838"), "water": Color("2a3a6a"), "bg": Color("0a0a14")},
	"palace": {"g1": Color("40202c"), "g2": Color("4a2432"), "path": Color("602838"), "wall": Color("200c18"), "water": Color("6a1020"), "bg": Color("100408")},
	"abyss": {"g1": Color("1f5a78"), "g2": Color("256680"), "path": Color("c8b890"), "wall": Color("1a8a8a"), "water": Color("0c2a5a"), "bg": Color("041018")},
	"volcano": {"g1": Color("4a2a22"), "g2": Color("54302a"), "path": Color("7a4a32"), "wall": Color("24100c"), "water": Color("e0501a"), "bg": Color("140604")},
	"void": {"g1": Color("2a1e4a"), "g2": Color("32245a"), "path": Color("4a3a7a"), "wall": Color("120a2a"), "water": Color("6a2aa8"), "bg": Color("06020e")},
	"celestial": {"g1": Color("d8d4e8"), "g2": Color("e4e0f2"), "path": Color("f0d890"), "wall": Color("b8a8d8"), "water": Color("8ab8f0"), "bg": Color("1a2040")},
}

const SKY := {
	"sect": [Color("1c2a5a"), Color("7a6aa8")], "bamboo": [Color("14301e"), Color("6ab07a")],
	"marsh": [Color("1e1226"), Color("7a4a5a")], "frost": [Color("12203a"), Color("a8d0f0")],
	"thunder": [Color("0e0e1e"), Color("5a5a8a")], "palace": [Color("1a0408"), Color("8a2030")],
	"abyss": [Color("041a2a"), Color("2a8aa8")], "volcano": [Color("200804"), Color("e0602a")],
	"void": [Color("08041a"), Color("6a3aa8")], "celestial": [Color("2a3a6a"), Color("fff0b0")],
}

const PICKUP_COLORS := {"herb": Color("6fe08a"), "lotus": Color("ff7aa8"), "jade": Color("7affe0"), "shard": Color("f6e85c"), "pearl": Color("e8f4ff"), "ember": Color("ff8a3a"), "star": Color("c8a0ff"), "sigil": Color("ffe890")}

# ---------------------------------------------------------------- primitives
static func h(x: float, y: float, salt: float = 0.0) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + salt * 37.719) * 43758.5453, 1.0)

static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([top, top, bottom, bottom]))

static func hgrad(ci: CanvasItem, r: Rect2, left: Color, right: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([left, right, right, left]))

static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, layers: int = 6) -> void:
	for i in layers:
		var f := float(layers - i) / layers
		ci.draw_circle(c, r * f, Color(col.r, col.g, col.b, col.a * (1.0 - f) * 2.0 / layers + 0.01))

static func shadow(ci: CanvasItem, c: Vector2, rx: float, ry: float, a: float = 0.3) -> void:
	UI.ellipse(ci, c, rx, ry, Color(0, 0, 0, a * 0.5))
	UI.ellipse(ci, c, rx * 0.72, ry * 0.7, Color(0, 0, 0, a * 0.6))

static func ridge(ci: CanvasItem, base_y: float, amp: float, col: Color, seed_: float, w: float, bottom: float, scroll: float = 0.0, step: float = 24.0) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, bottom))
	var x := 0.0
	while x <= w + step:
		var xs := x + scroll
		var n := sin(xs * 0.006 + seed_) * 0.55 + sin(xs * 0.017 + seed_ * 2.3) * 0.3 + sin(xs * 0.041 + seed_ * 5.1) * 0.15
		pts.append(Vector2(x, base_y - (n * 0.5 + 0.5) * amp))
		x += step
	pts.append(Vector2(w + step, bottom))
	ci.draw_colored_polygon(pts, col)

static func stars(ci: CanvasItem, r: Rect2, t: float, count: int, col: Color = Color(1, 1, 0.9)) -> void:
	for i in count:
		var sp := Vector2(r.position.x + h(i, 1.0) * r.size.x, r.position.y + h(i, 2.0) * r.size.y)
		var tw := 0.5 + 0.5 * sin(t * (1.0 + h(i, 3.0) * 2.0) + i)
		var sz := 0.7 + h(i, 4.0) * 1.4
		ci.draw_circle(sp, sz, Color(col.r, col.g, col.b, 0.2 + 0.7 * tw))
		if sz > 1.8:
			ci.draw_line(sp + Vector2(-3, 0), sp + Vector2(3, 0), Color(col.r, col.g, col.b, 0.25 * tw), 1.0)
			ci.draw_line(sp + Vector2(0, -3), sp + Vector2(0, 3), Color(col.r, col.g, col.b, 0.25 * tw), 1.0)

static func cloud(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var offs := [Vector2(-30, 4), Vector2(-12, -8), Vector2(10, -10), Vector2(30, 2), Vector2(0, 6)]
	for p in offs:
		UI.ellipse(ci, c + p * s, 22.0 * s, 12.0 * s, col)

static func rays(ci: CanvasItem, c: Vector2, t: float, count: int, length: float, col: Color, spin: float = 0.1) -> void:
	for i in count:
		var a := TAU * i / count + t * spin
		var wdt := 0.05 + 0.03 * sin(t + i)
		ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a - wdt), sin(a - wdt)) * length, c + Vector2(cos(a + wdt), sin(a + wdt)) * length]), col)

static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.7, 0), c + Vector2(0, r), c + Vector2(-r * 0.7, 0)]), col)

static func star4(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.18, -r * 0.18), c + Vector2(r, 0), c + Vector2(r * 0.18, r * 0.18), c + Vector2(0, r), c + Vector2(-r * 0.18, r * 0.18), c + Vector2(-r, 0), c + Vector2(-r * 0.18, -r * 0.18)]), col)

# ---------------------------------------------------------------- terrain
static func ground(ci: CanvasItem, tp: Vector2, x: int, y: int, th: Dictionary, theme: String, t: float) -> void:
	var hv := h(x, y)
	var base: Color = th.g1 if hv < 0.5 else th.g2
	base = base.lerp(base.lightened(0.07), h(x, y, 5.0))
	ci.draw_rect(Rect2(tp, Vector2(TS + 1, TS + 1)), base)
	ci.draw_rect(Rect2(tp + Vector2(h(x, y, 1.0) * 24.0, h(x, y, 2.0) * 22.0), Vector2(18.0 + h(x, y, 3.0) * 12.0, 12.0)), Color(1, 1, 1, 0.04))
	ci.draw_rect(Rect2(tp + Vector2(h(x, y, 6.0) * 20.0, 26.0 + h(x, y, 7.0) * 14.0), Vector2(22, 8)), Color(0, 0, 0, 0.05))
	match theme:
		"sect", "bamboo":
			for i in 4:
				var bp := tp + Vector2(6.0 + h(x, y, 10.0 + i) * 36.0, 18.0 + h(x, y, 20.0 + i) * 26.0)
				var sway := sin(t * 1.6 + x + i) * 1.5
				ci.draw_line(bp, bp + Vector2(sway - 2, -6), base.lightened(0.22), 1.6)
				ci.draw_line(bp, bp + Vector2(sway + 2, -7), base.lightened(0.3), 1.6)
			if hv > 0.86:
				var fp := tp + Vector2(10.0 + h(x, y, 4.0) * 28.0, 12.0 + h(x, y, 8.0) * 26.0)
				for k in 5:
					var a := TAU * k / 5.0
					ci.draw_circle(fp + Vector2(cos(a), sin(a)) * 2.6, 2.0, Color("ffd7e6") if hv > 0.93 else Color("fff4b0"))
				ci.draw_circle(fp, 1.6, Color("e8a030"))
		"marsh":
			if hv < 0.3:
				UI.ellipse(ci, tp + Vector2(24, 28), 14.0 + hv * 20.0, 6.0, Color(0.1, 0.07, 0.12, 0.28))
			if hv > 0.8:
				ci.draw_line(tp + Vector2(30, 40), tp + Vector2(32, 22), Color("6a8a3a"), 2.0)
				ci.draw_colored_polygon(PackedVector2Array([tp + Vector2(32, 18), tp + Vector2(34, 24), tp + Vector2(30, 24)]), Color("8a5a3a"))
		"frost":
			var tw := 0.5 + 0.5 * sin(t * 2.0 + x * 1.7 + y)
			if hv > 0.7:
				star4(ci, tp + Vector2(10.0 + hv * 26.0, 10.0 + h(x, y, 9.0) * 28.0), 3.0 + tw * 3.0, Color(1, 1, 1, 0.4 + tw * 0.4))
			if hv < 0.2:
				ci.draw_polyline(PackedVector2Array([tp + Vector2(6, 30), tp + Vector2(18, 24), tp + Vector2(26, 30), tp + Vector2(40, 20)]), Color(1, 1, 1, 0.35), 1.4)
		"thunder":
			if hv < 0.28:
				var pulse := 0.5 + 0.5 * sin(t * 3.0 + x)
				ci.draw_polyline(PackedVector2Array([tp + Vector2(6, 12), tp + Vector2(18, 20), tp + Vector2(14, 30), tp + Vector2(30, 38)]), Color(0.9, 0.85, 0.4, 0.25 + pulse * 0.3), 1.6)
			ci.draw_rect(Rect2(tp, Vector2(TS, 2)), Color(0, 0, 0, 0.1))
		"palace":
			ci.draw_rect(Rect2(tp, Vector2(TS, TS)), Color(0, 0, 0, 0.35), false, 1.0)
			if (x + y) % 4 == 0:
				diamond(ci, tp + Vector2(24, 24), 8.0, Color("902038", 0.6))
		"abyss":
			for i in 2:
				ci.draw_arc(tp + Vector2(12.0 + i * 20.0, 18.0 + i * 12.0 + h(x, y, 3.0) * 8.0), 8.0, 0.3, 2.8, 8, Color(1, 1, 1, 0.12), 1.4)
			if hv > 0.88:
				ci.draw_circle(tp + Vector2(30, 34), 3.0, Color("f4c8d8", 0.8))
		"volcano":
			if hv < 0.32:
				var lp := 0.5 + 0.5 * sin(t * 2.2 + x * 1.3 + y)
				ci.draw_polyline(PackedVector2Array([tp + Vector2(4, 40), tp + Vector2(16, 28), tp + Vector2(24, 34), tp + Vector2(40, 14)]), Color(1.0, 0.45 + lp * 0.2, 0.1, 0.4 + lp * 0.4), 2.0)
			if hv > 0.8:
				ci.draw_circle(tp + Vector2(h(x, y, 2.0) * 40.0 + 4.0, 20.0), 1.6, Color(0.7, 0.7, 0.7, 0.4))
		"void":
			if hv > 0.5:
				ci.draw_circle(tp + Vector2(h(x, y, 2.0) * 40.0 + 4.0, h(x, y, 4.0) * 40.0 + 4.0), 1.2, Color(0.8, 0.7, 1.0, 0.4 + 0.4 * sin(t * 2.0 + x * y)))
			if hv < 0.08:
				ci.draw_arc(tp + Vector2(24, 24), 14.0, 0.0, TAU, 20, Color(0.6, 0.4, 1.0, 0.3), 1.4)
				ci.draw_arc(tp + Vector2(24, 24), 8.0, t, t + 4.0, 12, Color(0.8, 0.6, 1.0, 0.4), 1.4)
		"celestial":
			ci.draw_rect(Rect2(tp, Vector2(TS, TS)), Color(0.7, 0.65, 0.85, 0.28), false, 1.0)
			if (x + y) % 5 == 0:
				star4(ci, tp + Vector2(24, 24), 8.0, Color(1.0, 0.9, 0.5, 0.5))

static func path_tile(ci: CanvasItem, tp: Vector2, x: int, y: int, th: Dictionary) -> void:
	var base: Color = th.path
	ci.draw_rect(Rect2(tp, Vector2(TS + 1, TS + 1)), base.lerp(base.darkened(0.08), h(x, y)))
	for i in 5:
		var pp := tp + Vector2(4.0 + h(x, y, 30.0 + i) * 40.0, 4.0 + h(x, y, 40.0 + i) * 40.0)
		UI.ellipse(ci, pp, 3.0 + h(x, y, 50.0 + i) * 2.5, 2.0, base.darkened(0.18))
		ci.draw_circle(pp + Vector2(-1, -1), 1.2, base.lightened(0.2))
	ci.draw_line(tp, tp + Vector2(TS, 0), Color(1, 1, 1, 0.07), 2.0)
	ci.draw_line(tp + Vector2(0, TS - 1), tp + Vector2(TS, TS - 1), Color(0, 0, 0, 0.12), 2.0)

static func water_tile(ci: CanvasItem, tp: Vector2, x: int, y: int, th: Dictionary, theme: String, t: float, shore: int) -> void:
	var base: Color = th.water
	var lava := theme == "volcano"
	var wob := 0.5 + 0.5 * sin(t * (1.2 if lava else 2.0) + x * 0.7 + y * 0.5)
	ci.draw_rect(Rect2(tp, Vector2(TS + 1, TS + 1)), base.lerp(base.lightened(0.18), wob * 0.35))
	for i in 3:
		var yy := 10.0 + i * 15.0 + sin(t * 1.5 + x + i * 2.0) * 3.0
		var a := 0.1 + 0.1 * wob
		var xx := 6.0 + h(x, y, i) * 10.0
		ci.draw_line(tp + Vector2(xx, yy), tp + Vector2(xx + 22.0, yy), Color(1, 1, 1, a) if not lava else Color(1, 0.85, 0.3, a + 0.2), 2.0)
	if h(x, y, 77.0) > 0.88:
		var gp := 0.5 + 0.5 * sin(t * 3.0 + x * 2.0)
		ci.draw_circle(tp + Vector2(30, 20), 2.0 + gp, Color(1, 1, 1, 0.5 * gp))
	if theme == "marsh" and h(x, y, 3.0) > 0.8:
		UI.ellipse(ci, tp + Vector2(24, 26), 9.0, 5.0, Color("4a8a3a"))
		ci.draw_circle(tp + Vector2(26, 24), 2.4, Color("ff9ac0"))
	var foam := Color(1, 1, 1, 0.45) if not lava else Color(0.2, 0.05, 0.02, 0.7)
	if shore & N:
		ci.draw_rect(Rect2(tp, Vector2(TS, 4)), foam)
	if shore & S:
		ci.draw_rect(Rect2(tp + Vector2(0, TS - 4), Vector2(TS, 4)), foam)
	if shore & W:
		ci.draw_rect(Rect2(tp, Vector2(4, TS)), foam)
	if shore & E:
		ci.draw_rect(Rect2(tp + Vector2(TS - 4, 0), Vector2(4, TS)), foam)

static func decor(ci: CanvasItem, tp: Vector2, x: int, y: int, hv: float, th: Dictionary, theme: String, t: float) -> void:
	var c: Color = th.g1.lightened(0.28)
	match theme:
		"frost":
			for i in 3:
				var bx := 12.0 + i * 12.0
				diamond(ci, tp + Vector2(bx, 32.0 - i % 2 * 5.0), 6.0 + hv * 3.0, Color(0.85, 0.95, 1.0, 0.85))
		"palace":
			ci.draw_line(tp + Vector2(24, 40), tp + Vector2(24, 20), Color("5a1020"), 3.0)
			ci.draw_circle(tp + Vector2(24, 18), 5.0 + sin(t * 4.0 + x) * 1.0, Color("ff5a30"))
			glow(ci, tp + Vector2(24, 18), 16.0, Color(1, 0.4, 0.15, 0.5), 4)
		"abyss":
			for i in 3:
				var cx := 10.0 + i * 13.0
				ci.draw_line(tp + Vector2(cx, 42), tp + Vector2(cx + sin(t + i) * 2.0, 20.0 + hv * 8.0), Color("f08a9a") if i % 2 == 0 else Color("a8e0c8"), 3.0)
				ci.draw_circle(tp + Vector2(cx + sin(t + i) * 2.0, 20.0 + hv * 8.0), 3.0, Color("ffd0d8"))
		"volcano":
			ci.draw_colored_polygon(PackedVector2Array([tp + Vector2(10, 42), tp + Vector2(18, 24), tp + Vector2(28, 44)]), Color("3a1c14"))
			ci.draw_line(tp + Vector2(18, 28), tp + Vector2(20, 40), Color(1, 0.5, 0.1, 0.8), 1.6)
		"void":
			for i in 3:
				var sx := 12.0 + i * 12.0
				diamond(ci, tp + Vector2(sx, 34.0 - h(x, y, i) * 10.0), 5.0, Color(0.7, 0.5, 1.0, 0.7 + 0.3 * sin(t * 3.0 + i)))
		"celestial":
			cloud(ci, tp + Vector2(24, 32), 0.5, Color(1, 1, 1, 0.65))
			star4(ci, tp + Vector2(10.0 + hv * 28.0, 12.0), 4.0, Color(1, 0.95, 0.6, 0.8))
		_:
			if theme == "marsh":
				c = Color("7a9a4a")
			for i in 3:
				var ox := 10.0 + i * 11.0 + hv * 4.0
				var sw := sin(t * 1.8 + x + i) * 2.0
				ci.draw_line(tp + Vector2(ox, 38), tp + Vector2(ox + (i - 1) * 3.0 + sw, 22.0 + hv * 6.0), c, 2.2)
			if theme == "sect" or theme == "bamboo":
				var fc := Color("ffd0e0") if hv > 0.5 else Color("fff0a0")
				ci.draw_circle(tp + Vector2(12.0 + hv * 24.0, 14.0 + hv * 12.0), 3.0, fc)
				ci.draw_circle(tp + Vector2(12.0 + hv * 24.0, 14.0 + hv * 12.0), 1.2, Color("e8a030"))

# ---------------------------------------------------------------- obstacles
static func obstacle(ci: CanvasItem, tp: Vector2, x: int, y: int, building: bool, th: Dictionary, theme: String, t: float) -> void:
	var hv := h(x * 3, y * 5)
	var wall: Color = th.wall
	if building:
		var roof := Color("8a4a3a").darkened(0.12 * hv)
		ci.draw_rect(Rect2(tp, Vector2(TS + 1, TS + 1)), roof)
		for i in 4:
			ci.draw_line(tp + Vector2(0, 6 + i * 12), tp + Vector2(TS, 6 + i * 12), roof.darkened(0.25), 2.0)
			ci.draw_line(tp + Vector2(0, 7 + i * 12), tp + Vector2(TS, 7 + i * 12), roof.lightened(0.15), 1.0)
		ci.draw_rect(Rect2(tp + Vector2(0, TS - 10), Vector2(TS + 1, 10)), Color("4a2218"))
		ci.draw_line(tp, tp + Vector2(TS, 0), Color("e0c070"), 3.0)
		if hv > 0.6:
			ci.draw_rect(Rect2(tp + Vector2(14, 12), Vector2(20, 20)), Color("3a2010"))
			ci.draw_rect(Rect2(tp + Vector2(16, 14), Vector2(16, 16)), Color("ffe9a8").lerp(Color("ffc860"), 0.5 + 0.5 * sin(t * 2.0 + x)))
			ci.draw_line(tp + Vector2(24, 14), tp + Vector2(24, 30), Color("3a2010"), 1.5)
		return
	shadow(ci, tp + Vector2(26, TS - 2), 22.0, 6.0, 0.3)
	match theme:
		"bamboo", "sect":
			for i in 3:
				var ox := 8.0 + i * 14.0 + hv * 4.0
				var sway := sin(t * 1.2 + x + i) * 2.0
				var top := tp + Vector2(ox + sway, -30.0 + hv * 12.0)
				ci.draw_line(tp + Vector2(ox, TS), top, wall.lightened(0.1 * i), 6.0)
				ci.draw_line(tp + Vector2(ox - 2, TS), top + Vector2(-2, 0), wall.lightened(0.4), 1.4)
				for k in 4:
					var ky := 6.0 + k * 13.0
					ci.draw_line(tp + Vector2(ox - 3.5, ky), tp + Vector2(ox + 3.5, ky), wall.darkened(0.45), 2.2)
				for lf in 3:
					var ly := -16.0 + hv * 12.0 + lf * 12.0
					var dir := 1.0 if lf % 2 == 0 else -1.0
					ci.draw_colored_polygon(PackedVector2Array([tp + Vector2(ox + sway * 0.6, ly), tp + Vector2(ox + dir * 18.0 + sway, ly + 6.0), tp + Vector2(ox + dir * 4.0, ly + 7.0)]), wall.lightened(0.38 - lf * 0.06))
		"marsh":
			ci.draw_line(tp + Vector2(24, TS), tp + Vector2(24, -14), wall, 8.0)
			ci.draw_line(tp + Vector2(22, TS), tp + Vector2(22, -14), wall.lightened(0.2), 2.0)
			ci.draw_line(tp + Vector2(24, 0), tp + Vector2(6, -18), wall, 4.0)
			ci.draw_line(tp + Vector2(24, -4), tp + Vector2(44, -22), wall, 4.0)
			for p in [Vector2(10, -18), Vector2(42, -22), Vector2(24, -18)]:
				UI.ellipse(ci, tp + p, 9.0, 6.0, Color("4a6a2a"))
				UI.ellipse(ci, tp + p + Vector2(-2, -2), 5.0, 3.0, Color("6a9a3a"))
			ci.draw_line(tp + Vector2(34, -8), tp + Vector2(34, 18), Color("7a9a4a", 0.7), 1.4)
			ci.draw_circle(tp + Vector2(34, 20), 2.0, Color("9acc5a", 0.8))
		"frost":
			var b := tp + Vector2(24, TS)
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-20, 0), b + Vector2(-7, -56 - hv * 14.0), b + Vector2(4, -12), b + Vector2(13, -42 - hv * 8.0), b + Vector2(22, 0)]), wall.darkened(0.15))
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-7, -56 - hv * 14.0), b + Vector2(4, -12), b + Vector2(-4, -8), b + Vector2(-14, -4)]), wall.lightened(0.38))
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(13, -42 - hv * 8.0), b + Vector2(22, 0), b + Vector2(10, 0)]), wall.lightened(0.15))
			var tw := 0.5 + 0.5 * sin(t * 2.5 + x * 3.0)
			star4(ci, b + Vector2(-5, -46 - hv * 12.0), 4.0 + tw * 3.0, Color(1, 1, 1, 0.5 + tw * 0.4))
		"thunder":
			var b2 := tp + Vector2(24, TS)
			ci.draw_colored_polygon(PackedVector2Array([b2 + Vector2(-24, 0), b2 + Vector2(-15, -36 - hv * 10.0), b2 + Vector2(8, -44), b2 + Vector2(24, 0)]), wall)
			ci.draw_colored_polygon(PackedVector2Array([b2 + Vector2(-15, -36 - hv * 10.0), b2 + Vector2(8, -44), b2 + Vector2(2, -20), b2 + Vector2(-10, -14)]), wall.lightened(0.18))
			var flash := 0.4 + 0.6 * maxf(0.0, sin(t * 5.0 + x * 2.0))
			ci.draw_polyline(PackedVector2Array([b2 + Vector2(-4, -40), b2 + Vector2(3, -24), b2 + Vector2(-5, -15), b2 + Vector2(4, -2)]), Color("f6e85c") if hv > 0.5 else Color("a89aff"), 2.2)
			glow(ci, b2 + Vector2(0, -22), 18.0, Color(0.9, 0.85, 0.4, 0.3 * flash), 4)
		"palace":
			ci.draw_rect(Rect2(tp + Vector2(8, -40), Vector2(32, TS + 40)), wall.lightened(0.1))
			ci.draw_rect(Rect2(tp + Vector2(8, -40), Vector2(8, TS + 40)), wall.lightened(0.22))
			ci.draw_rect(Rect2(tp + Vector2(4, -48), Vector2(40, 9)), Color("902038"))
			ci.draw_rect(Rect2(tp + Vector2(4, -48), Vector2(40, 3)), Color("e04a68"))
			ci.draw_line(tp + Vector2(24, -34), tp + Vector2(24, TS), Color("e03050"), 2.0)
			var gp := 0.6 + 0.4 * sin(t * 2.0 + x)
			glow(ci, tp + Vector2(24, -20), 14.0, Color(1, 0.2, 0.3, 0.4 * gp), 4)
		"abyss":
			var b3 := tp + Vector2(24, TS)
			for i in 4:
				var a := -0.5 + i * 0.33
				var tip := b3 + Vector2(sin(a) * 26.0 + sin(t * 1.5 + i) * 2.0, -34.0 - hv * 14.0 - i % 2 * 8.0)
				ci.draw_line(b3 + Vector2((i - 1.5) * 6.0, 0), tip, Color("e8607a") if i % 2 == 0 else Color("f09a5a"), 5.0)
				ci.draw_circle(tip, 4.0, Color("ffc0c8"))
			UI.ellipse(ci, b3 + Vector2(0, -2), 16.0, 6.0, Color("c04060"))
		"volcano":
			var b4 := tp + Vector2(24, TS)
			ci.draw_colored_polygon(PackedVector2Array([b4 + Vector2(-22, 0), b4 + Vector2(-8, -50 - hv * 12.0), b4 + Vector2(6, -30), b4 + Vector2(16, -52 - hv * 6.0), b4 + Vector2(24, 0)]), wall.lightened(0.04))
			ci.draw_colored_polygon(PackedVector2Array([b4 + Vector2(-8, -50 - hv * 12.0), b4 + Vector2(6, -30), b4 + Vector2(-2, 0), b4 + Vector2(-14, 0)]), wall.lightened(0.2))
			var lp := 0.5 + 0.5 * sin(t * 2.5 + x)
			ci.draw_polyline(PackedVector2Array([b4 + Vector2(-2, -40), b4 + Vector2(2, -24), b4 + Vector2(-4, -10), b4 + Vector2(2, 0)]), Color(1, 0.5 + lp * 0.2, 0.1, 0.8), 2.4)
			glow(ci, b4 + Vector2(0, -24), 20.0, Color(1, 0.4, 0.1, 0.25 * lp + 0.1), 4)
		"void":
			var b5 := tp + Vector2(24, TS)
			var fl := sin(t * 1.4 + x) * 3.0
			ci.draw_colored_polygon(PackedVector2Array([b5 + Vector2(-12, 0), b5 + Vector2(-16, -26), b5 + Vector2(0, -56 - hv * 10.0 + fl), b5 + Vector2(16, -26), b5 + Vector2(12, 0)]), Color(0.45, 0.25, 0.8, 0.85))
			ci.draw_colored_polygon(PackedVector2Array([b5 + Vector2(0, -56 - hv * 10.0 + fl), b5 + Vector2(16, -26), b5 + Vector2(2, -26)]), Color(0.75, 0.55, 1.0, 0.85))
			ci.draw_line(b5 + Vector2(-4, -8), b5 + Vector2(-2, -44), Color(1, 1, 1, 0.4), 1.4)
			glow(ci, b5 + Vector2(0, -30), 24.0, Color(0.6, 0.3, 1.0, 0.35), 4)
		"celestial":
			ci.draw_rect(Rect2(tp + Vector2(10, -30), Vector2(28, TS + 30)), Color("f2ecff"))
			ci.draw_rect(Rect2(tp + Vector2(10, -30), Vector2(8, TS + 30)), Color("c8bce8"))
			for k in 3:
				ci.draw_line(tp + Vector2(10, -16 + k * 22), tp + Vector2(38, -16 + k * 22), Color("e8c860"), 2.0)
			ci.draw_rect(Rect2(tp + Vector2(5, -38), Vector2(38, 9)), Color("e8c860"))
			ci.draw_rect(Rect2(tp + Vector2(5, -38), Vector2(38, 3)), Color("fff2b0"))
			ci.draw_rect(Rect2(tp + Vector2(5, TS - 6), Vector2(38, 7)), Color("c8bce8"))
			star4(ci, tp + Vector2(24, -46 + sin(t * 2.0 + x) * 2.0), 6.0, Color(1, 0.95, 0.6, 0.9))

# ---------------------------------------------------------------- weather and ambience
static func step_motes(motes: Array, theme: String, d: float, t: float, view: Vector2) -> void:
	for m in motes:
		match theme:
			"frost", "thunder":
				m.p.y += m.v * d * (3.0 if theme == "thunder" else 1.0)
				m.p.x += (sin(t + m.s) * 12.0 - (60.0 if theme == "thunder" else 0.0)) * d
				if m.p.y > view.y + 10.0 or m.p.x < -20.0:
					m.p = Vector2(randf() * (view.x + 100.0), -10.0)
			_:
				m.p.y -= m.v * d
				m.p.x += sin(t + m.s) * 6.0 * d
				if m.p.y < -10.0:
					m.p = Vector2(randf() * view.x, view.y + 10.0)

static func weather(ci: CanvasItem, theme: String, motes: Array, t: float, view: Vector2) -> void:
	for m in motes:
		var p: Vector2 = m.p
		var s: float = m.s
		match theme:
			"sect", "bamboo":
				var a := 0.25 + 0.2 * sin(t * 2.0 + s * 3.0)
				ci.draw_circle(p, s * 3.2, Color(1, 1, 0.6, a * 0.35))
				ci.draw_circle(p, s, Color(1, 1, 0.8, a + 0.2))
			"marsh":
				ci.draw_circle(p, s * 2.0, Color(0.6, 0.9, 0.4, 0.15))
				ci.draw_circle(p, s * 0.8, Color(0.8, 1, 0.5, 0.35))
			"frost":
				ci.draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), Color(1, 1, 1, 0.75), 1.2)
				ci.draw_line(p + Vector2(0, -s), p + Vector2(0, s), Color(1, 1, 1, 0.75), 1.2)
			"thunder":
				ci.draw_line(p, p + Vector2(-5, 14), Color(0.7, 0.75, 1.0, 0.35), 1.2)
			"palace", "volcano":
				var c := Color(1, 0.5, 0.2, 0.7) if theme == "volcano" else Color(1, 0.3, 0.3, 0.55)
				ci.draw_circle(p, s * 0.9, c)
				ci.draw_circle(p, s * 2.4, Color(c.r, c.g, c.b, 0.12))
			"abyss":
				ci.draw_arc(p, s * 2.0, 0.0, TAU, 10, Color(0.8, 1, 1, 0.5), 1.0)
				ci.draw_circle(p + Vector2(-s * 0.6, -s * 0.6), 0.8, Color(1, 1, 1, 0.6))
			"void":
				star4(ci, p, s * 2.0, Color(0.8, 0.65, 1.0, 0.5 + 0.4 * sin(t * 3.0 + s)))
			"celestial":
				ci.draw_circle(p, s * 2.6, Color(1, 0.95, 0.6, 0.12))
				star4(ci, p, s * 1.8, Color(1, 0.97, 0.7, 0.6))
	match theme:
		"thunder":
			var fl := maxf(0.0, sin(t * 0.9) * 8.0 - 7.0)
			if fl > 0.0:
				ci.draw_rect(Rect2(Vector2.ZERO, view), Color(0.85, 0.85, 1.0, fl * 0.35))
		"abyss":
			for i in 5:
				var rx := fposmod(i * 280.0 + t * 8.0, view.x + 200.0) - 100.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(rx, 0), Vector2(rx + 50, 0), Vector2(rx + 190, view.y), Vector2(rx + 100, view.y)]), Color(0.6, 0.95, 1.0, 0.05))
		"marsh":
			for i in 3:
				var fx := fposmod(i * 500.0 + t * 14.0, view.x + 600.0) - 300.0
				UI.ellipse(ci, Vector2(fx, 200.0 + i * 190.0), 300.0, 38.0, Color(0.7, 0.8, 0.6, 0.07))
		"void":
			for i in 3:
				UI.ellipse(ci, Vector2(300.0 + i * 340.0, 200.0 + sin(t * 0.3 + i) * 60.0), 240.0, 90.0, Color(0.5, 0.2, 0.9, 0.05))

static func grade(ci: CanvasItem, theme: String, view: Vector2) -> void:
	var tint := {"sect": Color(1, 0.9, 0.7, 0.05), "bamboo": Color(0.6, 1, 0.7, 0.05), "marsh": Color(0.7, 0.5, 0.6, 0.08), "frost": Color(0.7, 0.85, 1, 0.07), "thunder": Color(0.5, 0.5, 0.9, 0.08), "palace": Color(1, 0.2, 0.3, 0.09), "abyss": Color(0.2, 0.7, 0.9, 0.1), "volcano": Color(1, 0.4, 0.1, 0.09), "void": Color(0.5, 0.2, 0.9, 0.1), "celestial": Color(1, 0.95, 0.7, 0.06)}
	var tc: Color = tint.get(theme, Color(0, 0, 0, 0))
	ci.draw_rect(Rect2(Vector2.ZERO, view), tc)
	var va := 0.02 if theme in ["celestial", "frost"] else 0.055
	for i in 10:
		var m := float(i) * 14.0
		ci.draw_rect(Rect2(m, m, view.x - 2 * m, view.y - 2 * m), Color(0, 0, 0, va), false, 18.0)

# ---------------------------------------------------------------- minimap
static func minimap_image(grid: PackedByteArray, w: int, h_: int, th: Dictionary) -> ImageTexture:
	var img := Image.create(w, h_, false, Image.FORMAT_RGBA8)
	for yy in h_:
		for xx in w:
			var tile := grid[yy * w + xx]
			var c: Color = Color(th.g1).darkened(0.3)
			match tile:
				MapGen.WALL:
					c = Color(th.wall).lightened(0.05)
				MapGen.BUILDING:
					c = Color("8a4a3a")
				MapGen.WATER:
					c = th.water
				MapGen.PATH:
					c = th.path
			img.set_pixel(xx, yy, c)
	return ImageTexture.create_from_image(img)

static func draw_minimap(ci: CanvasItem, tex: ImageTexture, r: Rect2, w: int, h_: int, ptile: Vector2i, marks: Array, t: float) -> void:
	ci.draw_rect(r.grow(4), Color(0.02, 0.03, 0.08, 0.85))
	ci.draw_rect(r.grow(4), UI.C_BORDER, false, 2.0)
	ci.draw_texture_rect(tex, r, false, Color(1, 1, 1, 0.9))
	var sx := r.size.x / w
	var sy := r.size.y / h_
	for m in marks:
		var mp := r.position + Vector2(m.pos.x * sx, m.pos.y * sy)
		ci.draw_circle(mp, 2.4, m.col)
	var pp := r.position + Vector2((ptile.x + 0.5) * sx, (ptile.y + 0.5) * sy)
	ci.draw_circle(pp, 4.5 + sin(t * 5.0), Color(1, 1, 1, 0.35))
	ci.draw_circle(pp, 2.6, Color("5aa9ff"))

# ---------------------------------------------------------------- UI ornaments
static func panel(ci: CanvasItem, r: Rect2, fill: Color, border: Color) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
	vgrad(ci, r, fill.lightened(0.07), fill.darkened(0.1))
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 3)), Color(1, 1, 1, 0.07))
	ci.draw_rect(r, border, false, 2.0)
	ci.draw_rect(r.grow(-5), Color(border.r, border.g, border.b, 0.38), false, 1.0)
	var corners := [r.position, r.position + Vector2(r.size.x, 0), r.position + Vector2(0, r.size.y), r.end]
	for i in 4:
		var c: Vector2 = corners[i]
		diamond(ci, c, 7.0, border)
		ci.draw_circle(c, 2.0, fill.darkened(0.4))
	var mid := r.position.x + r.size.x * 0.5
	ci.draw_line(Vector2(mid - 22, r.position.y), Vector2(mid + 22, r.position.y), border.lightened(0.3), 3.0)
	ci.draw_line(Vector2(mid - 22, r.end.y), Vector2(mid + 22, r.end.y), border.lightened(0.3), 3.0)

static func bar(ci: CanvasItem, r: Rect2, ratio: float, col: Color, bg: Color) -> void:
	ci.draw_rect(r.grow(1), Color(0, 0, 0, 0.6))
	ci.draw_rect(r, bg)
	var fw := r.size.x * clampf(ratio, 0.0, 1.0)
	if fw > 0.5:
		hgrad(ci, Rect2(r.position, Vector2(fw, r.size.y)), col.darkened(0.25), col.lightened(0.12))
		ci.draw_rect(Rect2(r.position + Vector2(0, 1), Vector2(fw, maxf(1.0, r.size.y * 0.3))), Color(1, 1, 1, 0.28))
		ci.draw_rect(Rect2(r.position + Vector2(fw - 1.5, 0), Vector2(1.5, r.size.y)), Color(1, 1, 1, 0.55))
	ci.draw_rect(r, Color(1, 1, 1, 0.4), false, 1.0)

static func cursor_glow(ci: CanvasItem, r: Rect2, t: float) -> void:
	var a := 0.24 + 0.08 * sin(t * 6.0)
	hgrad(ci, r, Color(0.9, 0.75, 0.35, a + 0.12), Color(0.9, 0.75, 0.35, 0.02))
	ci.draw_rect(Rect2(r.position, Vector2(3, r.size.y)), Color(1, 0.85, 0.4, 0.9))

static func title_text(ci: CanvasItem, p: Vector2, s: String, size: int, width: float, t: float) -> void:
	for i in 4:
		ci.draw_string(UI.font(), p + Vector2(0, 3 + i * 1.0), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.3, 0.15, 0.0, 0.25))
	ci.draw_string(UI.font(), p + Vector2(2, 3), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0, 0, 0, 0.8))
	ci.draw_string(UI.font(), p, s, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color("ffe08a").lerp(Color("fff6d0"), 0.5 + 0.5 * sin(t * 1.5)))

# ---------------------------------------------------------------- battle backdrops
static func battle_backdrop(ci: CanvasItem, theme: String, sky: Array, t: float, view: Vector2) -> void:
	vgrad(ci, Rect2(0, 0, view.x, 480), sky[0], sky[1])
	var dark_sky := theme in ["palace", "thunder", "void", "marsh", "volcano"]
	if dark_sky or theme == "frost" or theme == "abyss":
		stars(ci, Rect2(0, 0, view.x, 300), t, 60)
	# sun / moon
	var orb := Vector2(980, 130)
	match theme:
		"palace":
			glow(ci, orb, 150.0, Color(1, 0.2, 0.2, 0.5), 8)
			ci.draw_circle(orb, 70.0, Color("c02030"))
			ci.draw_circle(orb + Vector2(-16, -10), 54.0, Color("e04050", 0.5))
		"celestial":
			glow(ci, orb, 220.0, Color(1, 0.95, 0.6, 0.6), 8)
			ci.draw_circle(orb, 66.0, Color("fffbe0"))
			rays(ci, orb, t, 14, 360.0, Color(1, 0.95, 0.6, 0.08), 0.08)
		"void":
			glow(ci, orb, 130.0, Color(0.6, 0.3, 1.0, 0.5), 8)
			ci.draw_circle(orb, 52.0, Color("0a0414"))
			ci.draw_arc(orb, 54.0, 0.0, TAU, 40, Color("c8a0ff"), 3.0)
		"volcano":
			glow(ci, Vector2(640, 470), 420.0, Color(1, 0.4, 0.1, 0.55), 8)
		"abyss":
			rays(ci, Vector2(700, -40), t, 9, 620.0, Color(0.7, 1, 1, 0.07), 0.04)
		"frost":
			for i in 3:
				var ay := 90.0 + i * 36.0
				var pts := PackedVector2Array()
				for k in 18:
					pts.append(Vector2(k * 80.0, ay + sin(t * 0.6 + k * 0.5 + i) * 22.0))
				ci.draw_polyline(pts, Color(0.4, 1.0, 0.8 - i * 0.2, 0.22), 18.0)
			glow(ci, orb, 90.0, Color(0.9, 0.95, 1, 0.4), 6)
			ci.draw_circle(orb, 36.0, Color("eef4ff"))
		_:
			glow(ci, orb, 120.0, Color(1, 0.95, 0.7, 0.4), 7)
			ci.draw_circle(orb, 48.0, Color("fff2c8") if not dark_sky else Color("dfe4f8"))
	for i in 5:
		var cx := fposmod(i * 310.0 + t * (6.0 + i * 2.0), view.x + 300.0) - 150.0
		cloud(ci, Vector2(cx, 110.0 + (i % 3) * 52.0), 1.5 + (i % 2) * 0.7, Color(1, 1, 1, 0.1 if dark_sky else 0.2))
	for layer in 3:
		var col: Color = Color(sky[1]).darkened(0.22 + layer * 0.18)
		ridge(ci, 410.0 + layer * 24.0, 120.0 - layer * 22.0, col, layer * 1.7 + 0.5, view.x, 480.0, t * (2.0 + layer * 3.0))
	# theme silhouettes on the horizon
	match theme:
		"bamboo", "sect":
			for i in 22:
				var bx := 30.0 + i * 60.0
				var bt := 330.0 - h(i, 3.0) * 70.0
				ci.draw_line(Vector2(bx, 480), Vector2(bx + sin(t + i) * 2.0, bt), Color(0.05, 0.2, 0.1, 0.8), 5.0)
		"palace":
			for i in 7:
				var px := 100.0 + i * 180.0
				ci.draw_rect(Rect2(px, 330, 30, 150), Color(0.1, 0.02, 0.05))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(px - 10, 330), Vector2(px + 15, 295), Vector2(px + 40, 330)]), Color(0.1, 0.02, 0.05))
		"thunder":
			var ph := fposmod(t * 1.1, 4.0)
			if ph < 0.25:
				ci.draw_rect(Rect2(0, 0, view.x, 480), Color(0.9, 0.9, 1, 0.35 * (1.0 - ph * 4.0)))
				var bx2 := 300.0 + fposmod(floor(t * 1.1 / 4.0) * 170.0, 600.0)
				ci.draw_polyline(PackedVector2Array([Vector2(bx2, 0), Vector2(bx2 - 24, 120), Vector2(bx2 + 10, 190), Vector2(bx2 - 18, 330), Vector2(bx2, 430)]), Color(1, 1, 0.8), 4.0)
		"celestial":
			for i in 4:
				var ix := 140.0 + i * 300.0
				var iy := 250.0 + sin(t * 0.7 + i) * 12.0
				UI.ellipse(ci, Vector2(ix, iy), 70.0, 14.0, Color("e8e0ff"))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(ix - 60, iy), Vector2(ix + 60, iy), Vector2(ix, iy + 44)]), Color("a89ac8"))
	# ground
	vgrad(ci, Rect2(0, 470, view.x, 250), Color(sky[0]).darkened(0.35), Color(sky[0]).darkened(0.7))
	ci.draw_rect(Rect2(0, 470, view.x, 5), Color(1, 1, 1, 0.16))
	for i in 9:
		var gy := 480.0 + pow(i, 1.7) * 6.0
		ci.draw_line(Vector2(0, gy), Vector2(view.x, gy), Color(1, 1, 1, 0.04 + i * 0.004), 1.0)
	for i in 14:
		var gx := (i - 7) * 220.0 + 640.0
		ci.draw_line(Vector2(640, 470), Vector2(gx, 720), Color(1, 1, 1, 0.035), 1.0)
	# floating motes
	for i in 26:
		var qx := fposmod(i * 83.0 + t * 12.0, view.x)
		var qy := 440.0 - fposmod(i * 37.0 + t * (20.0 + i % 4 * 6.0), 380.0)
		match theme:
			"frost":
				star4(ci, Vector2(qx, 20.0 + fposmod(i * 41.0 + t * 30.0, 460.0)), 3.0, Color(1, 1, 1, 0.7))
			"volcano", "palace":
				ci.draw_circle(Vector2(qx, qy), 2.0, Color(1, 0.5, 0.2, 0.6))
			"abyss":
				ci.draw_arc(Vector2(qx, qy), 4.0, 0.0, TAU, 10, Color(0.8, 1, 1, 0.5), 1.0)
			_:
				ci.draw_circle(Vector2(qx, qy), 2.0, Color(1, 1, 0.8, 0.3))
