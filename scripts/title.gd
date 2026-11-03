extends ScreenBase
## Title screen: a moonlit 3D cliff with the hero, orbiting camera, falling petals.

const VIEW := Vector2(1280, 720)

var labels := ["New Game", "Quit"]
var enabled := [true, true]
var cursor := 0
var hero: Node3D

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(55.0)
	var env := Look.environment("sect", 0.6)
	env.sky.sky_material.sky_top_color = Color("0b1030")
	env.sky.sky_material.sky_horizon_color = Color("c88a6a")
	env.ambient_light_color = Color("7080b0")
	env.fog_light_color = Color("a07a8a")
	cam.environment = env
	var sun := Look.sun("sect")
	sun.light_color = Color("ffe8c0")
	sun.light_energy = 0.9
	scene3d.add_child(sun)
	var b := MB.new()
	b.cyl(Vector3(0, -1.0, 0), 5.0, 2.0, Color("4a4a60"), Vector3.ZERO, 14)
	b.cyl(Vector3(0, 0.05, 0), 4.6, 0.1, Color("5a8a60"), Vector3.ZERO, 14)
	for i in 26:
		var a := TAU * i / 26.0
		var r := 22.0 + (i % 5) * 7.0
		var hh := 6.0 + (i * 7 % 9) * 2.2
		b.cone(Vector3(cos(a) * r, hh * 0.5 - 2.0, sin(a) * r - 6.0), 5.0 + (i % 3) * 2.0, hh, Color("2a2a48").lerp(Color("5a4a6a"), (i % 4) / 6.0), Vector3.ZERO, 8)
	# pagoda
	for k in 4:
		b.box(Vector3(-9, 1.0 + k * 1.6, -14), Vector3(3.2 - k * 0.5, 1.2, 3.2 - k * 0.5), Color("e8dcc0"))
		b.prim("cone4", Transform3D(Basis.from_euler(Vector3(0, PI / 4, 0)).scaled(Vector3(5.6 - k * 0.7, 0.9, 5.6 - k * 0.7)), Vector3(-9, 1.9 + k * 1.6, -14)), Color("3a5a8a"))
	MB.mesh_node(scene3d, b.build())
	var g := MB.new()
	g.ball(Vector3(14, 12, -40), 6.0, Color(1, 0.95, 0.8, 1.0))
	g.ball(Vector3(14, 12, -40), 11.0, Color(1, 0.9, 0.7, 0.2))
	g.ball(Vector3(-9, 9.5, -14), 0.5, Color(1, 0.8, 0.5, 0.6))
	MB.mesh_node(scene3d, g.build(MB.mat_glow()))
	hero = Models.person(Color("3a8ae8"), Color("1a1a2a"), {"sword": true, "glow": Color(0.4, 0.7, 1.0)})
	hero.position = Vector3(0, 0.1, 0)
	scene3d.add_child(hero)
	var w := Fx3D.make_weather()
	scene3d.add_child(w)
	Fx3D.configure_weather(w, "petals")
	w.position = Vector3(0, 10, 0)

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
	if not headless() and visible:
		var a := -0.6 + sin(t * 0.2) * 0.5
		cam.position = Vector3(sin(a) * 6.5, 1.8 + sin(t * 0.3) * 0.2, cos(a) * 6.5)
		cam.look_at(Vector3(2.2, 1.5, 0), Vector3.UP)
		hero.rotation.y = a + PI + 0.5
		Models.anim_person(hero, t, false)
		queue_redraw()

func _draw() -> void:
	Gfx.title_text(self, Vector2(0, 170), "Ascension of the Azure Cloud", 56, VIEW.x, t)
	UI.text(self, Vector2(0, 214), "A Xianxia Cultivation RPG  -  now in 3D", 22, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	draw_line(Vector2(380, 228), Vector2(900, 228), Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, 0.6), 2.0)
	Gfx.diamond(self, Vector2(640, 228), 7.0, UI.C_GOLD)
	UI.menu_list(self, Rect2(520, 380, 240, 110), labels, cursor, enabled, 24)
	UI.text(self, Vector2(0, 700), "Arrows/WASD move  -  Q/E camera  -  Enter/Z confirm  -  Esc menu", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
