extends Node2D
## Title screen.

const VIEW := Vector2(1280, 720)

var main
var opaque := true
var t := 0.0
var labels := ["New Game", "Quit"]
var enabled := [true, true]
var cursor := 0

func setup(m) -> void:
	main = m

func press(act: String) -> void:
	match act:
		"up", "down":
			cursor = (cursor + 1) % 2
		"confirm":
			if cursor == 0:
				main.new_game()
			else:
				get_tree().quit()

func _process(d: float) -> void:
	t += d
	queue_redraw()

func _draw() -> void:
	Gfx.vgrad(self, Rect2(Vector2.ZERO, VIEW), Color("0b1030"), Color("c88a6a"))
	Gfx.stars(self, Rect2(0, 0, VIEW.x, 300), t, 90)
	var moon := Vector2(900, 250)
	Gfx.glow(self, moon, 260.0, Color(1, 0.94, 0.78, 0.55), 9)
	draw_circle(moon, 90, Color("fff0c8"))
	draw_circle(moon + Vector2(-24, -14), 70, Color("fffbe8", 0.6))
	for i in 6:
		draw_circle(moon + Vector2(18 + i * 9 % 40, -30 + i * 17 % 60), 6 + i % 3 * 3, Color(0.9, 0.8, 0.6, 0.35))
	Gfx.rays(self, moon, t, 12, 520.0, Color(1, 0.95, 0.75, 0.05), 0.05)
	for i in 5:
		var cx := fposmod(i * 330.0 + t * (10 + i * 3), VIEW.x + 300) - 150
		Gfx.cloud(self, Vector2(cx, 170 + i * 44), 2.2 + i * 0.15, Color(1, 1, 1, 0.12))
	for layer in 4:
		var shade := Color("1a1a3a").lerp(Color("0a0a1a"), layer / 3.0).lightened(0.25 - layer * 0.06)
		Gfx.ridge(self, 520.0 + layer * 40.0, 220.0 - layer * 30.0, shade, layer * 2.1 + 0.3, VIEW.x, VIEW.y, t * (3.0 + layer * 2.0))
		# pagoda on the farthest ridge
		if layer == 1:
			for k in 3:
				draw_rect(Rect2(1010 - k * 8, 380 + k * 24, 16 + k * 16, 20), Color(0.08, 0.05, 0.16))
				draw_colored_polygon(PackedVector2Array([Vector2(1000 - k * 14, 380 + k * 24), Vector2(1018, 366 + k * 24), Vector2(1036 + k * 14, 380 + k * 24)]), Color(0.08, 0.05, 0.16))
	for i in 24:
		var fx := fposmod(i * 71.0 - t * (20.0 + i % 5 * 6.0), VIEW.x + 40.0)
		var fy := 80.0 + fposmod(i * 53.0 + t * (14.0 + i % 4 * 5.0), 560.0)
		draw_colored_polygon(PackedVector2Array([Vector2(fx, fy), Vector2(fx + 6, fy + 3), Vector2(fx + 1, fy + 7)]), Color(1, 0.75, 0.85, 0.7))
	Gfx.glow(self, Vector2(300, 440), 150.0, Color(0.4, 0.7, 1.0, 0.3), 6)
	UI.human(self, Vector2(300, 600), 4.4, Color("3a8ae8"), Color("1a1a2a"), t, true)
	Gfx.title_text(self, Vector2(0, 170), "Ascension of the Azure Cloud", 56, VIEW.x, t)
	UI.text(self, Vector2(0, 214), "A Xianxia Cultivation RPG", 22, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	draw_line(Vector2(380, 228), Vector2(900, 228), Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, 0.6), 2.0)
	Gfx.diamond(self, Vector2(640, 228), 7.0, UI.C_GOLD)
	UI.menu_list(self, Rect2(520, 380, 240, 110), labels, cursor, enabled, 24)
	UI.text(self, Vector2(0, 700), "Arrows/WASD move  -  Enter/Z confirm  -  Esc menu", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
