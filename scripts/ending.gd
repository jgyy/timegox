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
	Gfx.vgrad(self, Rect2(Vector2.ZERO, VIEW), Color("fff0c0"), Color("5a7ac8"))
	Gfx.rays(self, Vector2(640, 300), t, 18, 1100.0, Color(1, 1, 0.85, 0.12), 0.06)
	Gfx.glow(self, Vector2(640, 300), 330.0, Color(1, 0.95, 0.7, 0.7), 9)
	for i in 6:
		Gfx.cloud(self, Vector2(fposmod(i * 260.0 + t * (8.0 + i * 2.0), VIEW.x + 300.0) - 100.0, 520.0 + (i % 3) * 40.0), 2.4, Color(1, 1, 1, 0.55))
	for i in 40:
		var a := t * 0.2 + i
		var sp := Vector2(640 + cos(a * 1.3) * (80 + i * 9), 360 + sin(a) * (60 + i * 5))
		Gfx.star4(self, sp, 3.0 + sin(t * 3.0 + i) * 1.5, Color(1, 1, 0.9, 0.7))
	GfxActors.lotus_seat(self, Vector2(640, 452), 1.3, t, Color(1, 0.9, 0.5))
	UI.human(self, Vector2(640, 440), 5.0, Color("f0f8ff"), Color("1a1a2a"), t, true)
	Gfx.title_text(self, Vector2(0, 110), "ASCENSION", 64, VIEW.x, t)
	UI.text(self, Vector2(0, 160), "Lin Feng, once a sweeper of steps, now merges with the Dao itself.", 22, Color("2a2a4a"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.panel(self, Rect2(400, 480, 480, 190), Color(0.04, 0.06, 0.13, 0.85))
	UI.text(self, Vector2(400, 520), "Total play time  %s" % Fmt.clock(Game.playtime), 26, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 556), "Realm: %s" % Data.level_name(Game.level), 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 586), "Foes defeated: %d   Battles: %d   Falls: %d" % [Game.kills, Game.battles, Game.deaths], 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 616), "Time spent meditating: %s" % Fmt.clock(Game.meditated), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 652), "Press Enter", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 480)
