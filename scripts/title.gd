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
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(VIEW.x, 0), Vector2(VIEW.x, VIEW.y), Vector2(0, VIEW.y)]), PackedColorArray([Color("0b1030"), Color("0b1030"), Color("c88a6a"), Color("c88a6a")]))
	draw_circle(Vector2(900, 250), 90, Color("fff0c8"))
	draw_circle(Vector2(900, 250), 130, Color(1, 0.94, 0.78, 0.12))
	for layer in 4:
		var pts := PackedVector2Array([Vector2(0, VIEW.y)])
		for i in 14:
			pts.append(Vector2(i * 100.0 - 50 + fposmod(t * (4 + layer * 3), 100.0) * 0.0, 380 + layer * 55 - absf(sin(i * 1.7 + layer * 1.3)) * (150 - layer * 25)))
		pts.append(Vector2(VIEW.x, VIEW.y))
		draw_colored_polygon(pts, Color("1a1a3a").lerp(Color("0a0a1a"), layer / 3.0).lightened(0.25 - layer * 0.06))
	for i in 5:
		var cx := fposmod(i * 330.0 + t * (10 + i * 3), VIEW.x + 300) - 150
		UI.ellipse(self, Vector2(cx, 160 + i * 44), 140, 20, Color(1, 1, 1, 0.12))
	UI.human(self, Vector2(300, 600), 4.0, Color("3a8ae8"), Color("1a1a2a"), t, true)
	UI.text(self, Vector2(0, 170), "Ascension of the Azure Cloud", 56, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 214), "A Xianxia Cultivation RPG", 22, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.menu_list(self, Rect2(520, 380, 240, 110), labels, cursor, enabled, 24)
	UI.text(self, Vector2(0, 700), "Arrows/WASD move  -  Enter/Z confirm  -  Esc menu", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
