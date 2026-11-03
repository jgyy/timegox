extends ScreenBase
## Ending / results screen: the hero floats on a lotus in a golden sky.

const VIEW := Vector2(1280, 720)

var done := false
var hero: Node3D
var lot: Node3D

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(55.0)
	cam.environment = Look.environment("origin", 0.5)
	scene3d.add_child(Look.sun("origin", false))
	lot = Models.lotus(Color(1.0, 0.9, 0.5), 1.4)
	scene3d.add_child(lot)
	hero = Models.person(Color("f0f8ff"), Color("1a1a2a"), {"sword": true, "glow": Color(1, 0.95, 0.7)})
	hero.position = Vector3(0, 0.25, 0)
	scene3d.add_child(hero)
	var b := MB.new()
	for i in 30:
		var a := i * 2.399
		b.ball(Vector3(cos(a) * (6 + i % 7 * 2.0), -2.0 - (i % 3), sin(a) * (6 + i % 5 * 2.0)), 2.5 + i % 3, Color(1, 1, 1))
	MB.mesh_node(scene3d, b.build())
	var g := MB.new()
	g.ball(Vector3(0, 1.2, -1), 2.6, Color(1, 0.95, 0.7, 0.18))
	g.ball(Vector3(0, 1.2, -1), 4.0, Color(1, 0.95, 0.7, 0.1))
	MB.mesh_node(scene3d, g.build(MB.mat_glow()))
	var w := Fx3D.make_weather()
	scene3d.add_child(w)
	Fx3D.configure_weather(w, "light")
	w.position = Vector3(0, 3, 0)

func press(act: String) -> void:
	if act == "confirm":
		done = true
		main.game_finished_ack()

func _process(d: float) -> void:
	t += d
	if not headless() and visible:
		hero.position.y = 0.3 + sin(t) * 0.12
		hero.rotation.y = t * 0.3
		Models.anim_person(hero, t, false, true)
		lot.rotation.y = -t * 0.2
		cam.position = Vector3(sin(t * 0.15) * 1.5, 1.8, 6.5)
		cam.look_at(Vector3(0, 1.4, 0), Vector3.UP)
		queue_redraw()

func _draw() -> void:
	Gfx.title_text(self, Vector2(0, 110), "ASCENSION", 64, VIEW.x, t)
	UI.text(self, Vector2(0, 160), "Lin Feng, once a sweeper of steps, rewrites the heavens and ascends as a True Immortal.", 22, Color("f2ead3"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.panel(self, Rect2(400, 480, 480, 190), Color(0.04, 0.06, 0.13, 0.85))
	UI.text(self, Vector2(400, 520), "Total play time  %s" % Fmt.clock(Game.playtime), 26, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 556), "Realm: %s" % Data.level_name(Game.level), 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 586), "Foes defeated: %d   Battles: %d   Falls: %d" % [Game.kills, Game.battles, Game.deaths], 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 616), "Time spent meditating: %s" % Fmt.clock(Game.meditated), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 652), "Press Enter", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 480)
