extends ScreenBase
## Title screen: a moonlit 3D cliff with the hero, orbiting camera, falling petals.

const VIEW := Vector2(1280, 720)

var labels := ["New Game", "Quit"]
var enabled := [true, true]
var cursor := 0
var hero: Node3D

func _on_show(v: bool) -> void:
	if v:
		main.fx_theme("sect")

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(55.0)
	var env := Look.environment("sect", 0.6)
	Look.tint_sky(env, Color("0b1030"), Color("c88a6a"), Color("a07a8a"), 0.9)
	env.ambient_light_color = Color("7080b0")
	cam.environment = env
	var sun := Look.sun("sect")
	sun.light_color = Color("ffe8c0")
	sun.light_energy = 1.0
	sun.rotation_degrees = Vector3(-32, -25, 0)
	scene3d.add_child(sun)
	scene3d.add_child(Look.fill("sect"))
	var b := MB.new()
	var rock := MB.tag(Color("4a4a60"), MB.STONE)
	# the cliff top the hero stands on, with a rocky skirt falling away into the clouds
	b.lathe(Vector3(0, -6.0, 0), [Vector2(3.0, 0.0), Vector2(4.4, 2.5), Vector2(5.2, 4.8), Vector2(5.0, 5.9), Vector2(4.6, 6.05), Vector2(0.0, 6.1)], rock, 10, MB.tag(Color("5a5a72"), MB.STONE))
	b.disc(Vector3(0, 0.11, 0), 4.6, MB.tag(Color("6a9a70"), MB.FOLIAGE), 20, MB.tag(Color("5a8a62"), MB.FOLIAGE))
	for i in 9:
		var a := TAU * i / 9.0 + 0.3
		b.sph(Vector3(cos(a) * 4.7, -0.2, sin(a) * 4.7), Vector3(0.9, 0.6, 0.8), MB.tag(Color("54546c"), MB.STONE), Vector3(0, a, 0.2))
	# distant spires of the sect's mountain range
	for i in 26:
		var a2 := TAU * i / 26.0
		var r := 22.0 + (i % 5) * 7.0
		var hh := 6.0 + (i * 7 % 9) * 2.2
		var c := Vector3(cos(a2) * r, hh * 0.5 - 2.0, sin(a2) * r - 6.0)
		b.cone(c, 5.0 + (i % 3) * 2.0, hh, MB.tag(Color("2a2a48").lerp(Color("5a4a6a"), (i % 4) / 6.0), MB.STONE), Vector3(0, a2, 0), 8)
		b.cone(c + Vector3(0, hh * 0.38, 0), 1.6, hh * 0.26, MB.tag(Color("8a90b0"), MB.STONE), Vector3(0, a2, 0), 8)
	# pagoda on a far peak, with lit windows
	var g := MB.new()
	for k in 4:
		b.box(Vector3(-9, 1.0 + k * 1.6, -14), Vector3(3.2 - k * 0.5, 1.2, 3.2 - k * 0.5), MB.tag(Color("e8dcc0"), MB.CLOTH))
		b.prim("cone4", Transform3D(Basis.from_euler(Vector3(0, PI / 4, 0)).scaled(Vector3(5.6 - k * 0.7, 0.9, 5.6 - k * 0.7)), Vector3(-9, 1.9 + k * 1.6, -14)), MB.tag(Color("3a5a8a"), MB.STONE))
		g.box(Vector3(-9, 1.0 + k * 1.6, -14 + (1.6 - k * 0.25) + 0.01), Vector3(0.5, 0.5, 0.02), Color(1.0, 0.8, 0.45, 0.85))
	MB.mesh_node(scene3d, b.build())
	# two windswept pines on the cliff edge
	var pine := Terrain3D._proto("wall2:sect", "sect")
	for pp in [Vector3(-3.6, 0.05, -3.4), Vector3(3.3, 0.05, -3.8)]:
		var pm := MB.mesh_node(scene3d, pine, pp)
		pm.scale = Vector3.ONE * 1.1
		pm.rotation.y = pp.x
	# a sea of clouds below
	var cb := MB.new()
	for i in 60:
		var a3 := i * 2.399
		var r2 := 7.0 + (i % 9) * 3.5
		cb.sph(Vector3(cos(a3) * r2, -4.5 + (i % 4) * 0.4, sin(a3) * r2 - 4.0), Vector3(3.2, 1.0, 2.4), MB.tag(Color(0.86, 0.84, 0.95), MB.CLOTH))
	MB.mesh_node(scene3d, cb.build(MB.mat_plain()))
	g.ball(Vector3(14, 12, -40), 6.0, Color(1, 0.95, 0.8, 1.0))
	g.ball(Vector3(-9, 9.5, -14), 0.5, Color(1, 0.8, 0.5, 0.6))
	MB.mesh_node(scene3d, g.build(MB.mat_glow()))
	var key := OmniLight3D.new()
	key.light_color = Color(0.85, 0.85, 1.0)
	key.light_energy = 1.2
	key.omni_range = 14.0
	key.position = Vector3(-2.0, 4.0, 6.0)
	scene3d.add_child(key)
	var moon := MB.new()
	moon.sph_hi(Vector3.ZERO, Vector3(10.0, 10.0, 10.0), Color(1, 0.9, 0.7, 0.6))
	MB.mesh_node(scene3d, moon.build(MB.mat_aura()), Vector3(14, 12, -40))
	hero = Models.hero({"glow": Color(0.4, 0.7, 1.0), "look": "sweeper", "cols": {}, "outfit": "sweeper"})
	hero.position = Vector3(0, 0.1, 0)
	scene3d.add_child(hero)
	var w := Fx3D.make_weather()
	scene3d.add_child(w)
	Fx3D.configure_weather(w, "petals")
	w.position = Vector3(0, 10, 0)

## The hero on the cliff as he is being made (character creation): rebuilt with the look and colours
## chosen so far.
func show_hero(o: Dictionary) -> void:
	var at := hero.transform
	hero.queue_free()
	o["glow"] = Color(0.4, 0.7, 1.0)
	hero = Models.hero(o)
	hero.transform = at
	scene3d.add_child(hero)

## Whether the character creation is laid over the cliff (the camera comes in close to the hero).
func creating() -> bool:
	return main.top_name() == "create"

func press(act: String) -> void:
	# (eggs.gd: the old code, keyed before anything begins)
	if Eggs.title_key(act):
		main.fx_flash(Color(0.8, 0.9, 1.0), 0.35)
	match act:
		"up", "down":
			cursor = (cursor + 1) % 2
		"confirm":
			if cursor == 0:
				main.open_creation()
			else:
				get_tree().quit()

func _process(d: float) -> void:
	t += d
	if not headless() and visible:
		if creating():
			# close in on the hero, who turns slowly on the spot, a little to the left of the choices
			cam.position = cam.position.lerp(Vector3(-0.9, 1.55, 3.3), 1.0 - exp(-d * 4.0))
			cam.look_at(Vector3(0.75, 1.15, 0), Vector3.UP)
			hero.rotation.y = 0.35 + sin(t * 0.35) * 0.9
			Models.anim_person(hero, t, false)
			queue_redraw()
			return
		var a := -0.6 + sin(t * 0.2) * 0.5
		cam.position = Vector3(sin(a) * 6.5, 1.8 + sin(t * 0.3) * 0.2, cos(a) * 6.5)
		cam.look_at(Vector3(2.2, 1.5, 0), Vector3.UP)
		hero.rotation.y = a + PI + 0.5
		Models.anim_person(hero, t, false)
		queue_redraw()

func _draw() -> void:
	if creating():
		return
	Gfx.title_text(self, Vector2(0, 170), "Ascension of the Azure Cloud", 56, VIEW.x, t)
	UI.text(self, Vector2(0, 214), "A Xianxia Cultivation RPG  -  now in 3D", 22, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	draw_line(Vector2(380, 228), Vector2(900, 228), Color(UI.C_GOLD.r, UI.C_GOLD.g, UI.C_GOLD.b, 0.6), 2.0)
	Gfx.diamond(self, Vector2(640, 228), 7.0, UI.C_GOLD)
	UI.menu_list(self, Rect2(520, 380, 240, 110), labels, cursor, enabled, 24)
	if Eggs.code_done:
		UI.text(self, Vector2(0, 520), "Somewhere under a stair, a cupboard door has come open.", 16, UI.C_JADE, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 700), "Arrows/WASD move  -  Q/E camera  -  R ride  -  T talk to Yue Ling  -  Enter/Z confirm  -  Esc menu", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
