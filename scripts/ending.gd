extends Node2D
## Ending / results screen.

const VIEW := Vector2(1280, 720)

var main
var opaque := true
var t := 0.0
var done := false

func setup(m) -> void:
	main = m

func press(act: String) -> void:
	if act == "confirm":
		done = true
		main.game_finished_ack()

func _process(d: float) -> void:
	t += d
	queue_redraw()

func _draw() -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(VIEW.x, 0), Vector2(VIEW.x, VIEW.y), Vector2(0, VIEW.y)]), PackedColorArray([Color("fff0c0"), Color("fff0c0"), Color("5a7ac8"), Color("5a7ac8")]))
	for i in 40:
		var a := t * 0.2 + i
		draw_circle(Vector2(640 + cos(a * 1.3) * (80 + i * 9), 360 + sin(a) * (60 + i * 5)), 3, Color(1, 1, 1, 0.5))
	UI.human(self, Vector2(640, 440), 5.0, Color("f0f8ff"), Color("1a1a2a"), t, true)
	UI.text(self, Vector2(0, 110), "ASCENSION", 64, Color("6a4a10"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 160), "Lin Feng, once a sweeper of steps, now walks among the heavens.", 22, Color("2a2a4a"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.panel(self, Rect2(400, 480, 480, 190), Color(0.04, 0.06, 0.13, 0.85))
	UI.text(self, Vector2(400, 520), "Total play time  %s" % Fmt.clock(Game.playtime), 26, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 556), "Realm: %s" % Data.level_name(Game.level), 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 586), "Foes defeated: %d   Battles: %d   Falls: %d" % [Game.kills, Game.battles, Game.deaths], 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 616), "Time spent meditating: %s" % Fmt.clock(Game.meditated), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 652), "Press Enter", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 480)
