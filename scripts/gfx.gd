class_name Gfx
extends RefCounted
## 2D UI drawing helpers (panels, bars, minimap, ornaments). All world art is 3D now.

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

static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.7, 0), c + Vector2(0, r), c + Vector2(-r * 0.7, 0)]), col)

static func star4(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.18, -r * 0.18), c + Vector2(r, 0), c + Vector2(r * 0.18, r * 0.18), c + Vector2(0, r), c + Vector2(-r * 0.18, r * 0.18), c + Vector2(-r, 0), c + Vector2(-r * 0.18, -r * 0.18)]), col)


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

## The whole open world as one picture, each region in its own colours.
static func world_minimap(wd: Dictionary) -> ImageTexture:
	var W: int = wd.w
	var H: int = wd.h
	var pal: Array = []
	for id in wd.ids:
		var th := Look.theme(Data.AREAS[id].theme)
		pal.append([Color(th.g1).darkened(0.3), Color(th.wall).lightened(0.05), Color(th.water), Color(th.path)])
	var data := PackedByteArray()
	data.resize(W * H * 3)
	var grid: PackedByteArray = wd.grid
	var owner: PackedByteArray = wd.owner
	var sea: PackedByteArray = wd.get("sea", PackedByteArray())
	# the sea round the land; the sky round the Nine Heavens' islands; the abyss under the Nine Springs
	var deep := Color("1b3552")
	var shallow := Color("2f6286")
	match str(wd.get("layer", "surface")):
		"heaven":
			deep = Color("c8d8ec")
			shallow = Color("e8f0fa")
		"under":
			deep = Color("06080c")
			shallow = Color("16222a")
	for i in W * H:
		if not sea.is_empty() and sea[i] == 1:
			# the Four Seas: one deep blue, paler in the shallows along the coast
			var y := i / W
			var x := i % W
			var near_land := false
			for d in [-3, 3, -3 * W, 3 * W, -2 - 2 * W, 2 + 2 * W, 2 - 2 * W, -2 + 2 * W]:
				var j: int = i + d
				if j >= 0 and j < W * H and sea[j] == 0 and absi(j % W - x) <= 3:
					near_land = true
					break
			var sc := shallow if near_land else deep.lerp(shallow, 0.18 * Gfx.h(x * 0.05, y * 0.05))
			data[i * 3] = int(sc.r8)
			data[i * 3 + 1] = int(sc.g8)
			data[i * 3 + 2] = int(sc.b8)
			continue
		var p: Array = pal[owner[i]]
		var c: Color = p[0]
		match grid[i]:
			MapGen.WALL:
				c = p[1]
			MapGen.WATER:
				c = p[2]
			MapGen.PATH:
				c = p[3]
			MapGen.BUILDING:
				c = Color("8a4a3a")
			MapGen.INTERIOR:
				c = Color("c09060")
		data[i * 3] = int(c.r8)
		data[i * 3 + 1] = int(c.g8)
		data[i * 3 + 2] = int(c.b8)
	return ImageTexture.create_from_image(Image.create_from_data(W, H, false, Image.FORMAT_RGB8, data))

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

