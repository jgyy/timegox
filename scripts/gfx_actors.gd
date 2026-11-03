class_name GfxActors
extends RefCounted
## Procedural art library, part 2: characters, extra monster shapes and spell effects.

# ---------------------------------------------------------------- people
## c = feet position, s = scale.  Options: sword, walk, face (-1/1), hat, staff, ribbon (Color), glow, beard.
static func person(ci: CanvasItem, c: Vector2, s: float, robe: Color, hair: Color, t: float, o: Dictionary = {}) -> void:
	var walking: bool = o.get("walk", false)
	var fx: float = float(o.get("face", 1))
	var ph := t * (9.0 if walking else 2.2)
	var step := sin(ph) * 3.4 * s if walking else 0.0
	var bob := absf(sin(ph)) * 1.6 * s if walking else sin(t * 3.0) * 1.0 * s
	var base := c + Vector2(0, -bob * 0.6)
	Gfx.shadow(ci, c + Vector2(0, 2.0 * s), 12.0 * s, 4.2 * s, 0.32)
	var skin := Color("f2d6b8")
	var dark := robe.darkened(0.55)
	# legs and boots
	var foot_l := base + Vector2(-3.2 * fx * s - step, 0)
	var foot_r := base + Vector2(3.2 * fx * s + step, 0)
	ci.draw_line(base + Vector2(-3.2 * fx, -7) * s, foot_l, dark, 3.4 * s)
	ci.draw_line(base + Vector2(3.2 * fx, -7) * s, foot_r, dark, 3.4 * s)
	ci.draw_rect(Rect2(foot_l + Vector2(-2.2, -1.4) * s, Vector2(4.4, 2.6) * s), Color("1a1420"))
	ci.draw_rect(Rect2(foot_r + Vector2(-2.2, -1.4) * s, Vector2(4.4, 2.6) * s), Color("1a1420"))
	# back arm swings opposite to the legs
	var swing := -step * 0.8
	ci.draw_line(base + Vector2(-6.0 * fx, -17) * s, base + Vector2(-8.5 * fx, -9) * s + Vector2(0, swing), robe.darkened(0.2), 3.6 * s)
	# robe: two-tone body with flared hem
	var body := PackedVector2Array([base + Vector2(-10, 0) * s, base + Vector2(10, 0) * s, base + Vector2(6.5, -18) * s, base + Vector2(-6.5, -18) * s])
	ci.draw_colored_polygon(body, robe)
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(2 * fx, 0) * s, base + Vector2(10 * fx, 0) * s, base + Vector2(6.5 * fx, -18) * s, base + Vector2(1 * fx, -18) * s]), robe.lightened(0.14))
	ci.draw_line(base + Vector2(-10, -0.5) * s, base + Vector2(10, -0.5) * s, robe.darkened(0.35), 1.6 * s)
	# collar, sash, knot, pendant
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-6.5, -18) * s, base + Vector2(6.5, -18) * s, base + Vector2(0, -9.5) * s]), robe.lightened(0.42))
	ci.draw_line(base + Vector2(-8, -8) * s, base + Vector2(8, -8) * s, Color("e8d080") if o.get("sash", true) else dark, 2.4 * s)
	ci.draw_circle(base + Vector2(2.5 * fx, -7.5) * s, 1.8 * s, UI.C_GOLD)
	ci.draw_line(base + Vector2(2.5 * fx, -6) * s, base + Vector2(3.5 * fx, -1.5) * s, UI.C_GOLD, 1.2 * s)
	# front arm and hand
	var hand := base + Vector2(9.0 * fx, -9.0) * s + Vector2(0, -swing * 0.8)
	ci.draw_line(base + Vector2(6.0 * fx, -17) * s, hand, robe.lightened(0.08), 3.8 * s)
	ci.draw_circle(hand, 2.0 * s, skin)
	# head: back hair, face, fringe, top-knot, eyes
	ci.draw_circle(base + Vector2(0, -25.5) * s, 7.4 * s, hair)
	ci.draw_circle(base + Vector2(0, -24) * s, 6.3 * s, skin)
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-6.8, -26) * s, base + Vector2(-3, -31.5) * s, base + Vector2(3, -31.5) * s, base + Vector2(6.8, -26) * s, base + Vector2(3.2, -26.6) * s, base + Vector2(0, -28.6) * s, base + Vector2(-3.2, -26.6) * s]), hair)
	if not o.get("hat", false):
		ci.draw_circle(base + Vector2(0, -33.5) * s, 3.0 * s, hair)
		ci.draw_line(base + Vector2(-3.5, -34) * s, base + Vector2(3.5, -33) * s, UI.C_GOLD, 1.2 * s)
	ci.draw_circle(base + Vector2(-2.4 * fx, -24.2) * s, 0.95 * s, Color("1a1420"))
	ci.draw_circle(base + Vector2(2.4 * fx, -24.2) * s, 0.95 * s, Color("1a1420"))
	ci.draw_circle(base + Vector2(-3.6, -22.2) * s, 1.3 * s, Color(1, 0.55, 0.55, 0.35))
	ci.draw_circle(base + Vector2(3.6, -22.2) * s, 1.3 * s, Color(1, 0.55, 0.55, 0.35))
	if o.get("beard", false):
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-4, -21) * s, base + Vector2(4, -21) * s, base + Vector2(0, -12) * s]), Color(0.92, 0.92, 0.95))
	if o.has("ribbon"):
		var rc: Color = o.ribbon
		for k in 2:
			var fl := sin(t * 4.0 + k * 1.6) * 3.0
			ci.draw_line(base + Vector2(-4.5 * fx, -31) * s, base + Vector2((-10.0 - k * 4.0) * fx + fl, -24.0 + k * 5.0) * s, rc, 2.0 * s)
	if o.get("hat", false):
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-13, -28) * s, base + Vector2(13, -28) * s, base + Vector2(0, -40) * s]), Color("c8a870"))
		ci.draw_line(base + Vector2(-13, -28) * s, base + Vector2(13, -28) * s, Color("8a6a3a"), 1.6 * s)
	if o.get("staff", false):
		ci.draw_line(hand + Vector2(2 * fx, 6) * s, hand + Vector2(4 * fx, -34) * s, Color("7a5a3a"), 2.4 * s)
		Gfx.glow(ci, hand + Vector2(4 * fx, -36) * s, 9.0 * s, Color(0.5, 1, 0.9, 0.6), 4)
		ci.draw_circle(hand + Vector2(4 * fx, -36) * s, 3.0 * s, Color("c8fff0"))
	if o.get("sword", false):
		var tip := hand + Vector2(7.0 * fx, -28.0) * s
		if o.get("glow", true):
			ci.draw_line(hand, tip, Color(0.6, 0.85, 1.0, 0.25), 6.0 * s)
		ci.draw_line(hand, tip, Color("e8f6ff"), 2.4 * s)
		ci.draw_line(hand + Vector2(1.2 * fx, -3) * s, tip, Color.WHITE, 0.9 * s)
		ci.draw_line(hand + Vector2(-3.0 * fx, -1.5) * s, hand + Vector2(3.5 * fx, -2.5) * s, UI.C_GOLD, 2.4 * s)
		ci.draw_circle(hand + Vector2(0, 2) * s, 1.4 * s, UI.C_GOLD)

## Aura rings under a cultivator, used during meditation and tribulations.
static func lotus_seat(ci: CanvasItem, c: Vector2, s: float, t: float, col: Color) -> void:
	for ring in 3:
		var rr := (46.0 + ring * 22.0) * s
		ci.draw_arc(c, rr, t * (0.4 + ring * 0.2), t * (0.4 + ring * 0.2) + PI * 1.5, 28, Color(col.r, col.g, col.b, 0.5 - ring * 0.12), 2.0)
	for i in 8:
		var a := TAU * i / 8.0 + sin(t) * 0.05
		var tip := c + Vector2(cos(a) * 50.0 * s, sin(a) * 15.0 * s)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(cos(a - 0.3) * 18.0 * s, sin(a - 0.3) * 5.0 * s), tip, c + Vector2(cos(a + 0.3) * 18.0 * s, sin(a + 0.3) * 5.0 * s)]), Color(1, 0.75, 0.9, 0.75))

# ---------------------------------------------------------------- extra monsters
## Returns true when `shape` was drawn here.  p = center, s = scale.
static func monster_ext(ci: CanvasItem, shape: String, p: Vector2, s: float, col: Color, t: float) -> bool:
	var dark := col.darkened(0.45)
	var light := col.lightened(0.35)
	match shape:
		"golem":
			for k in 2:
				ci.draw_rect(Rect2(p + Vector2(-16 + k * 18, 10) * s, Vector2(13, 18) * s), dark)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, 14) * s, p + Vector2(-14, -16) * s, p + Vector2(14, -16) * s, p + Vector2(20, 14) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -16) * s, p + Vector2(14, -16) * s, p + Vector2(8, -6) * s, p + Vector2(-8, -6) * s]), light)
			for sd in [-1.0, 1.0]:
				UI.ellipse(ci, p + Vector2(sd * 24, -14) * s, 11.0 * s, 9.0 * s, col.lightened(0.1))
				ci.draw_line(p + Vector2(sd * 24, -8) * s, p + Vector2(sd * 30, 14 + sin(t * 2.0) * 3.0) * s, dark, 9.0 * s)
				UI.ellipse(ci, p + Vector2(sd * 30, 18 + sin(t * 2.0) * 3.0) * s, 8.0 * s, 7.0 * s, col)
			ci.draw_rect(Rect2(p + Vector2(-9, -30) * s, Vector2(18, 15) * s), col.lightened(0.05))
			var pulse := 0.6 + 0.4 * sin(t * 3.0)
			Gfx.glow(ci, p + Vector2(0, 2) * s, 16.0 * s, Color(1, 0.6, 0.2, 0.6 * pulse), 4)
			ci.draw_circle(p + Vector2(0, 2) * s, 5.0 * s, Color(1, 0.85, 0.4, 0.5 + 0.5 * pulse))
			ci.draw_polyline(PackedVector2Array([p + Vector2(-12, -10) * s, p + Vector2(-6, 0) * s, p + Vector2(-10, 10) * s]), Color(1, 0.7, 0.2, 0.6), 1.6)
			ci.draw_rect(Rect2(p + Vector2(-6, -25) * s, Vector2(4, 3) * s), Color(1, 0.9, 0.4))
			ci.draw_rect(Rect2(p + Vector2(2, -25) * s, Vector2(4, 3) * s), Color(1, 0.9, 0.4))
			return true
		"serpent":
			var prev := p + Vector2(-34, 16) * s
			for i in 14:
				var f := i / 13.0
				var pt := p + Vector2(-34 + f * 60, 16 - sin(f * 6.0 + t * 2.5) * 14 - f * 24) * s
				var wd := (5.0 + sin(f * PI) * 7.0) * s
				ci.draw_line(prev, pt, col.lerp(dark, 1.0 - f), wd)
				ci.draw_line(prev + Vector2(0, wd * 0.2), pt + Vector2(0, wd * 0.2), light, wd * 0.35)
				if i % 3 == 0:
					ci.draw_colored_polygon(PackedVector2Array([pt + Vector2(-3, -wd * 0.5), pt + Vector2(0, -wd * 0.5 - 7 * s), pt + Vector2(3, -wd * 0.5)]), dark)
				prev = pt
			UI.ellipse(ci, prev + Vector2(5, -2) * s, 11.0 * s, 8.0 * s, col.lightened(0.1))
			ci.draw_circle(prev + Vector2(8, -5) * s, 2.4 * s, Color("ffe040"))
			ci.draw_circle(prev + Vector2(8, -5) * s, 1.0 * s, Color.BLACK)
			var tg := sin(t * 8.0) * 2.0
			ci.draw_line(prev + Vector2(14, 0) * s, prev + Vector2(22, tg) * s, Color("ff4060"), 1.6 * s)
			ci.draw_line(prev + Vector2(22, tg) * s, prev + Vector2(26, tg - 3) * s, Color("ff4060"), 1.4 * s)
			ci.draw_line(prev + Vector2(22, tg) * s, prev + Vector2(26, tg + 3) * s, Color("ff4060"), 1.4 * s)
			return true
		"crab":
			var snap := sin(t * 3.0) * 0.25
			for i in 3:
				for sd in [-1.0, 1.0]:
					var lg := sin(t * 4.0 + i * 1.3) * 2.5
					ci.draw_line(p + Vector2(sd * 12, 6 + i * 4) * s, p + Vector2(sd * (24 + i * 3), 12 + i * 5 + lg) * s, dark, 3.0 * s)
					ci.draw_line(p + Vector2(sd * (24 + i * 3), 12 + i * 5 + lg) * s, p + Vector2(sd * (28 + i * 3), 22 + i * 3) * s, dark, 2.4 * s)
			UI.ellipse(ci, p + Vector2(0, 4) * s, 22.0 * s, 15.0 * s, col)
			UI.ellipse(ci, p + Vector2(-4, -1) * s, 14.0 * s, 8.0 * s, light)
			ci.draw_arc(p + Vector2(0, 4) * s, 18.0 * s, PI * 1.1, PI * 1.9, 12, dark, 2.0 * s)
			for sd in [-1.0, 1.0]:
				ci.draw_line(p + Vector2(sd * 20, -4) * s, p + Vector2(sd * 30, -14) * s, dark, 4.0 * s)
				UI.ellipse(ci, p + Vector2(sd * 33, -20) * s, 10.0 * s, 8.0 * s, col.lightened(0.05))
				var tipp := p + Vector2(sd * 33, -28) * s
				ci.draw_colored_polygon(PackedVector2Array([tipp + Vector2(-5 * sd, 3) * s, tipp + Vector2(sd * (2.0 + snap * 14.0), -10) * s, tipp + Vector2(5 * sd, 3) * s]), light)
				ci.draw_line(p + Vector2(sd * 5, -8) * s, p + Vector2(sd * 6, -16) * s, dark, 2.0 * s)
				ci.draw_circle(p + Vector2(sd * 6, -17) * s, 3.0 * s, Color.WHITE)
				ci.draw_circle(p + Vector2(sd * 6, -17) * s, 1.4 * s, Color.BLACK)
			return true
		"spider":
			for i in 4:
				for sd in [-1.0, 1.0]:
					var lg := sin(t * 5.0 + i * 1.1 + (0.0 if sd > 0.0 else PI)) * 3.0
					var knee := p + Vector2(sd * (14 + i * 4), -14 + i * 7 + lg) * s
					ci.draw_line(p + Vector2(sd * 6, i * 2 - 2) * s, knee, dark, 2.6 * s)
					ci.draw_line(knee, p + Vector2(sd * (24 + i * 5), 14 + i * 4) * s, dark, 2.0 * s)
			UI.ellipse(ci, p + Vector2(-8, 6) * s, 15.0 * s, 13.0 * s, col)
			ci.draw_polygon(PackedVector2Array([p + Vector2(-8, -2) * s, p + Vector2(-14, 8) * s, p + Vector2(-8, 16) * s, p + Vector2(-2, 8) * s]), PackedColorArray([Color("ff4060"), Color("ff4060"), Color("ff4060"), Color("ff4060")]))
			UI.ellipse(ci, p + Vector2(10, 0) * s, 9.0 * s, 8.0 * s, light)
			for e in 4:
				ci.draw_circle(p + Vector2(13 + e % 2 * 2, -4 + e / 2 * 5 + e % 2 * -1) * s, 1.6 * s, Color("ff3050"))
			return true
		"jelly":
			var pul := sin(t * 2.5) * 0.08
			var bell := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				bell.append(p + Vector2(cos(a) * 24.0 * (1.0 + pul), sin(a) * 22.0 * (1.0 - pul) + 2.0) * s)
			ci.draw_colored_polygon(bell, Color(col.r, col.g, col.b, 0.8))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -6) * s, p + Vector2(-6, -18) * s, p + Vector2(-2, -8) * s]), Color(1, 1, 1, 0.35))
			Gfx.glow(ci, p + Vector2(0, -4) * s, 14.0 * s, Color(light.r, light.g, light.b, 0.5), 4)
			ci.draw_circle(p + Vector2(-7, -2) * s, 2.4 * s, Color(0.05, 0.05, 0.15))
			ci.draw_circle(p + Vector2(7, -2) * s, 2.4 * s, Color(0.05, 0.05, 0.15))
			for k in 6:
				var tx := -18.0 + k * 7.2
				var pts := PackedVector2Array()
				for j in 6:
					pts.append(p + Vector2(tx + sin(t * 3.0 + k + j * 0.8) * 3.0, 2.0 + j * 6.0) * s)
				ci.draw_polyline(pts, Color(col.r, col.g, col.b, 0.65), 2.4 * s)
			return true
		"phoenix":
			var flap := sin(t * 5.0)
			for sd in [-1.0, 1.0]:
				for f in 6:
					var ang := -0.5 + f * 0.28
					var tip := p + Vector2(sd * (22 + f * 8), -18 + f * 7 + flap * 14 - ang * 10) * s
					ci.draw_line(p + Vector2(sd * 6, -2), tip, col.lerp(Color("ffe060"), f / 5.0), (7.0 - f * 0.7) * s)
			for f in 5:
				var tl := p + Vector2((f - 2) * 9, 36 + abs(f - 2) * -4 + sin(t * 4.0 + f) * 3) * s
				ci.draw_line(p + Vector2(0, 10) * s, tl, col.lerp(Color("ffd040"), f / 4.0), 5.0 * s)
				Gfx.glow(ci, tl, 7.0 * s, Color(1, 0.6, 0.2, 0.4), 3)
			Gfx.glow(ci, p, 34.0 * s, Color(1, 0.5, 0.2, 0.35), 5)
			UI.ellipse(ci, p + Vector2(0, 4) * s, 12.0 * s, 17.0 * s, col)
			UI.ellipse(ci, p + Vector2(0, 8) * s, 7.0 * s, 11.0 * s, light)
			ci.draw_circle(p + Vector2(0, -14) * s, 7.0 * s, col.lightened(0.1))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, -15) * s, p + Vector2(0, -8) * s, p + Vector2(3, -15) * s]), UI.C_GOLD)
			for f in 3:
				ci.draw_line(p + Vector2((f - 1) * 3, -20) * s, p + Vector2((f - 1) * 7, -32 + f % 2 * 4) * s, Color("ffd040"), 2.2 * s)
			ci.draw_circle(p + Vector2(-2.6, -15.5) * s, 1.5 * s, Color.BLACK)
			ci.draw_circle(p + Vector2(2.6, -15.5) * s, 1.5 * s, Color.BLACK)
			return true
	return false

# ---------------------------------------------------------------- spell and hit effects
## k runs from 0 (start) to 1 (end).  c = impact point.
static func hit_fx(ci: CanvasItem, elem: String, c: Vector2, k: float, t: float) -> void:
	var a := clampf(1.0 - k * 0.9, 0.0, 1.0)
	match elem:
		"fire":
			Gfx.glow(ci, c, 70.0 * (0.4 + k), Color(1, 0.5, 0.1, 0.6 * a), 6)
			for i in 12:
				var ang := TAU * i / 12.0 + Gfx.h(i, 1.0)
				var d := (14.0 + k * 62.0) * (0.6 + Gfx.h(i, 2.0))
				ci.draw_circle(c + Vector2(cos(ang), sin(ang) - k * 0.8) * d, 7.0 * (1.0 - k) + 1.5, Color(1, 0.55 + Gfx.h(i, 3.0) * 0.4, 0.1, a))
		"water":
			for i in 3:
				var rr := (10.0 + k * 52.0) * (0.55 + i * 0.3)
				ci.draw_arc(c, rr, 0.0, TAU, 28, Color(0.5, 0.8, 1, a * (1.0 - i * 0.22)), 4.0 - i)
			for i in 8:
				var ang := TAU * i / 8.0
				ci.draw_circle(c + Vector2(cos(ang) * 30 * k, sin(ang) * 30 * k - sin(k * PI) * 30.0), 3.5, Color(0.7, 0.9, 1, a))
		"wood":
			for i in 10:
				var ang := TAU * i / 10.0 + k * 3.0
				var d := 12.0 + k * 54.0
				var lp := c + Vector2(cos(ang) * d, sin(ang) * d * 0.7)
				UI.ellipse(ci, lp, 6.0, 2.8, Color(0.4, 0.9, 0.45, a))
			ci.draw_line(c + Vector2(-40, 30) * (1.0 - k * 0.3), c + Vector2(40, -30), Color(0.7, 1, 0.7, a), 4.0)
		"earth":
			for i in 7:
				var bx := c.x + (i - 3) * 14.0
				var hgt := (24.0 + Gfx.h(i, 5.0) * 26.0) * sin(clampf(k * 1.3, 0.0, 1.0) * PI * 0.9 + 0.1)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 7, c.y + 32), Vector2(bx, c.y + 32 - hgt), Vector2(bx + 7, c.y + 32)]), Color(0.75, 0.55, 0.3, a))
		"thunder":
			var jag := PackedVector2Array([c + Vector2(0, -160), c + Vector2(-16, -100), c + Vector2(10, -70), c + Vector2(-12, -30), c + Vector2(6, 0), c + Vector2(0, 40)])
			ci.draw_polyline(jag, Color(0.98, 0.95, 0.5, a), 9.0 * (1.0 - k * 0.5))
			ci.draw_polyline(jag, Color(1, 1, 1, a), 3.5)
			Gfx.glow(ci, c, 60.0, Color(1, 0.95, 0.5, 0.5 * a), 5)
		"dark":
			var rr2 := 50.0 * (1.0 - k) + 6.0
			Gfx.glow(ci, c, rr2 * 1.6, Color(0.5, 0.15, 0.8, 0.6 * a), 5)
			ci.draw_circle(c, rr2, Color(0.12, 0.02, 0.2, a))
			for i in 6:
				var ang := TAU * i / 6.0 + k * 4.0
				ci.draw_line(c + Vector2(cos(ang), sin(ang)) * rr2, c + Vector2(cos(ang + 0.4), sin(ang + 0.4)) * rr2 * 2.2, Color(0.7, 0.4, 1, a), 2.0)
		_:
			var ext := 46.0 * (0.5 + k * 0.5)
			ci.draw_line(c + Vector2(-ext, -ext * 0.8), c + Vector2(ext, ext * 0.8), Color(1, 1, 1, a), 6.0 * (1.0 - k * 0.6))
			ci.draw_line(c + Vector2(ext, -ext * 0.8), c + Vector2(-ext * 0.6, ext * 0.5), Color(0.8, 0.9, 1, a * 0.8), 3.0)
			for i in 6:
				var ang := TAU * i / 6.0 + 0.4
				ci.draw_circle(c + Vector2(cos(ang), sin(ang)) * (10.0 + k * 40.0), 2.2, Color(1, 1, 0.8, a))
	Gfx.star4(ci, c, 14.0 * (1.0 - k) + 2.0, Color(1, 1, 1, a * 0.8))
