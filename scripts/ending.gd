extends ScreenBase
## Ending / results screen: the hero floats on a lotus in a golden sky.

const VIEW := Vector2(1280, 720)

var done := false
var hero: Node3D
var comp: Node3D
var lot: Node3D

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(55.0)
	cam.environment = Look.environment("garden", 0.5)
	Look.tint_sky(cam.environment, Color("f0a860"), Color("fff0d0"))
	scene3d.add_child(Look.sun("garden", false))
	scene3d.add_child(Look.fill("garden"))
	lot = Models.lotus(Color(1.0, 0.9, 0.5), 1.4)
	scene3d.add_child(lot)
	hero = Models.person(Color("f0f8ff"), Color("1a1a2a"), {"sword": true, "glow": Color(1, 0.95, 0.7), "hair": "topknot", "crown": true, "trim": Color("f0c850"), "cape": Color("f8e8c0")})
	hero.position = Vector3(0, 0.25, 0)
	scene3d.add_child(hero)
	comp = Models.person(Color("ffd0e0"), Color("402030"), {"ribbon": Color("ff9ac0"), "hair": "long", "eyes": Color("c04080"), "glow": Color(1.0, 0.7, 0.85)})
	comp.position = Vector3(1.6, 0.3, -0.6)
	scene3d.add_child(comp)
	var b := MB.new()
	for i in 40:
		var a := i * 2.399
		b.sph(Vector3(cos(a) * (6 + i % 7 * 2.0), -2.0 - (i % 3), sin(a) * (6 + i % 5 * 2.0)), Vector3(3.0, 1.4, 2.4) * (0.8 + (i % 4) * 0.2), MB.tag(Color(1, 0.97, 0.92), MB.CLOTH))
	MB.mesh_node(scene3d, b.build(MB.mat_plain()))
	# floating peach-blossom islands and a distant golden palace
	var isle := Terrain3D._proto("wall:cloudsea", "cloudsea")
	var peach := Terrain3D._proto("wall:garden", "garden")
	for i in 6:
		var a2 := i * 1.1 + 0.4
		var mi := MB.mesh_node(scene3d, isle if i % 2 == 0 else peach, Vector3(cos(a2) * 13.0, -1.0 + (i % 3) * 1.5, sin(a2) * 13.0 - 8.0))
		mi.scale = Vector3.ONE * (1.6 + (i % 3) * 0.4)
	var pal := MB.new()
	for k in 4:
		pal.box(Vector3(0, 4.0 + k * 1.8, -40), Vector3(10.0 - k * 2.0, 1.4, 4.0), MB.tag(Color("fff4e0"), MB.STONE))
		pal.prim("cone4", Transform3D(Basis.from_euler(Vector3(0, PI / 4, 0)).scaled(Vector3(14.0 - k * 2.6, 1.0, 7.0)), Vector3(0, 5.1 + k * 1.8, -40)), MB.tag(Color("f0c850"), MB.METAL))
	MB.mesh_node(scene3d, pal.build(MB.mat_plain()))
	var g := MB.new()
	g.sph_hi(Vector3(0, 1.2, -1), Vector3(3.0, 3.0, 3.0), Color(1, 0.95, 0.7, 0.4))
	MB.mesh_node(scene3d, g.build(MB.mat_aura()))
	var w := Fx3D.make_weather()
	scene3d.add_child(w)
	Fx3D.configure_weather(w, "petals")
	w.position = Vector3(0, 6, 0)

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
		comp.position.y = 0.35 + sin(t + 1.2) * 0.12
		comp.rotation.y = t * 0.3 - 0.6
		Models.anim_person(comp, t + 2.0, false, false)
		lot.rotation.y = -t * 0.2
		cam.position = Vector3(sin(t * 0.15) * 1.5, 1.8, 6.5)
		cam.look_at(Vector3(0, 1.4, 0), Vector3.UP)
		queue_redraw()

func _draw() -> void:
	Gfx.title_text(self, Vector2(0, 110), "ASCENSION", 64, VIEW.x, t)
	UI.text(self, Vector2(0, 160), "Lin Feng, once a sweeper of steps, closes the Jade Ledger and becomes a Dao Ancestor who takes nothing.", 22, Color("f2ead3"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.panel(self, Rect2(400, 480, 480, 190), Color(0.04, 0.06, 0.13, 0.85))
	UI.text(self, Vector2(400, 520), "Total play time  %s" % Fmt.clock(Game.playtime), 26, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 556), "Realm: %s" % Data.level_name(Game.level), 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 586), "Foes defeated: %d   Battles: %d   Falls: %d" % [Game.kills, Game.battles, Game.deaths], 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 616), "Time spent meditating: %s" % Fmt.clock(Game.meditated), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 652), "Press Enter", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 480)
