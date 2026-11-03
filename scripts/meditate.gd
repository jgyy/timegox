extends ScreenBase
## Meditation: converts time into cultivation and restores HP/Qi.

const VIEW := Vector2(1280, 720)

var spring := false
var gained := 0.0
var motes: Array = []
var status := ""

var hero: Node3D
var comp: Node3D
var rings: Array = []
var orbit: Node3D

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(55.0)
	var env := Look.environment("void", 0.5)
	env.sky.sky_material.sky_top_color = Color("0a0f28")
	env.sky.sky_material.sky_horizon_color = Color("2a1f48")
	cam.environment = env
	var sun := Look.sun("void", false)
	sun.light_energy = 0.5
	scene3d.add_child(sun)
	var lot := Models.lotus(Color(0.6, 0.9, 1.0), 1.3)
	scene3d.add_child(lot)
	hero = Models.person(Color("3a8ae8"), Color("1a1a2a"), {"sword": false, "glow": Color(0.5, 0.85, 1.0)})
	hero.position = Vector3(0, 0.25, 0)
	scene3d.add_child(hero)
	comp = Models.person(Color("e86a9a"), Color("402030"), {"ribbon": Color("ffb0cc")})
	comp.position = Vector3(-2.6, 0.1, 0.6)
	scene3d.add_child(comp)
	for r in 2:
		var rb := MB.new()
		rb.torus(Vector3.ZERO, 3.0 + r * 0.9, 0.04, Color(0.6, 0.9, 1.0, 0.7))
		for k in 12:
			var a := TAU * k / 12.0
			rb.cone(Vector3(cos(a) * (3.0 + r * 0.9), 0.0, sin(a) * (3.0 + r * 0.9)), 0.12, 0.3, Color(0.8, 1.0, 1.0, 0.9), Vector3.ZERO, 4)
		var ri := MB.mesh_node(scene3d, rb.build(MB.mat_glow()))
		ri.position.y = 0.6 + r * 0.5
		rings.append(ri)
	var w := Fx3D.make_weather()
	scene3d.add_child(w)
	Fx3D.configure_weather(w, "glints")
	w.position = Vector3(0, 3, 0)

func start() -> void:
	spring = main.world.near_spring()
	gained = 0.0
	status = "Circulating qi..." + ("  (Spirit Spring: x3)" if spring else "")

func press(act: String) -> void:
	if act == "cancel" or act == "confirm":
		main.pop()

func _process(d: float) -> void:
	t += d
	if main.top_name() == "meditate":
		var before := Game.level
		var rate := Game.med_rate(spring)
		Game.meditated += d
		var full := true
		for i in Game.party_size():
			Game.hp[i] = minf(float(Game.max_hp(i)), Game.hp[i] + Game.max_hp(i) * 0.04 * d)
			Game.qi[i] = minf(float(Game.max_qi(i)), Game.qi[i] + Game.max_qi(i) * 0.04 * d)
			if Game.hp[i] < Game.max_hp(i) - 0.5 or Game.qi[i] < Game.max_qi(i) - 0.5:
				full = false
		if Game.level < Data.MAX_LEVEL:
			Game.add_exp(rate * d)
			gained += rate * d
		if Game.level > before:
			main.pop()
		elif Game.can_breakthrough() and full:
			Game.toast("Your qi is saturated. Seek a breakthrough!")
			main.pop()
	if not headless() and visible:
		hero.position.y = 0.3 + sin(t * 1.5) * 0.08
		Models.anim_person(hero, t, false, true)
		comp.visible = Game.companion
		Models.anim_person(comp, t + 1.0, false, true)
		rings[0].rotation.y = t * 0.4
		rings[1].rotation.y = -t * 0.3
		cam.position = Vector3(sin(t * 0.2) * 1.2, 2.3, 7.0)
		cam.look_at(Vector3(0, 1.3, 0), Vector3.UP)
		queue_redraw()

func _draw() -> void:
	UI.text(self, Vector2(0, 90), "Meditation", 38, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 126), status, 18, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.panel(self, Rect2(340, 520, 600, 150))
	UI.text(self, Vector2(360, 552), Data.level_name(Game.level), 20, UI.C_GOLD)
	if Game.level < Data.MAX_LEVEL:
		UI.bar(self, Rect2(360, 562, 560, 12), Game.exp / float(Game.exp_need()), UI.C_GOLD)
		UI.text(self, Vector2(360, 596), "Cultivation %d / %d   (+%.0f this session)" % [Game.exp, Game.exp_need(), gained], 15)
	UI.text(self, Vector2(360, 626), "HP %d/%d" % [Game.hp[0], Game.max_hp(0)], 15)
	UI.bar(self, Rect2(450, 614, 200, 10), Game.hp[0] / float(Game.max_hp(0)), UI.C_RED)
	UI.text(self, Vector2(670, 626), "QI %d/%d" % [Game.qi[0], Game.max_qi(0)], 15)
	UI.bar(self, Rect2(760, 614, 160, 10), Game.qi[0] / float(Game.max_qi(0)), UI.C_BLUE)
	UI.text(self, Vector2(360, 656), "Esc / Enter: stop meditating", 13, UI.C_DIM)
