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

func _on_show(v: bool) -> void:
	if v:
		main.fx_theme("void")

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(55.0)
	var env := Look.environment("void", 0.5)
	Look.tint_sky(env, Color("0a0f28"), Color("2a1f48"), Color(0, 0, 0, 0), 1.0)
	cam.environment = env
	var sun := Look.sun("void", false)
	sun.light_energy = 0.5
	scene3d.add_child(sun)
	scene3d.add_child(Look.fill("void"))
	var key := OmniLight3D.new()
	key.light_color = Color(0.75, 0.9, 1.0)
	key.light_energy = 1.4
	key.omni_range = 12.0
	key.position = Vector3(0.5, 3.5, 5.0)
	scene3d.add_child(key)
	# a still pond of starlight under the lotus
	var pond := MB.new()
	pond.disc(Vector3(0, -0.05, 0), 9.0, MB.tag(Color("1a2050"), MB.CRYSTAL), 40, MB.tag(Color("0a0f28"), MB.CRYSTAL))
	for i in 14:
		var a := TAU * i / 14.0
		pond.sph(Vector3(cos(a) * 8.5, -0.1, sin(a) * 8.5), Vector3(1.0, 0.5, 0.8), MB.tag(Color("3a3a58"), MB.STONE), Vector3(0, a, 0))
	MB.mesh_node(scene3d, pond.build(MB.mat_plain()))
	var lot := Models.lotus(Color(0.6, 0.9, 1.0), 1.3)
	scene3d.add_child(lot)
	hero = Models.person(Color("3a8ae8"), Color("1a1a2a"), {"asset": "lin_feng", "sword": false, "glow": Color(0.5, 0.85, 1.0), "hair": "topknot", "trim": Color("e8f0ff")})
	hero.position = Vector3(0, 0.25, 0)
	scene3d.add_child(hero)
	comp = Models.person(Color("e86a9a"), Color("402030"), {"asset": "yue_ling", "ribbon": Color("ffb0cc"), "hair": "long", "eyes": Color("c04080")})
	comp.position = Vector3(-2.6, 0.1, 0.6)
	scene3d.add_child(comp)
	for r in 3:
		var rb := MB.new()
		var rad := 2.6 + r * 0.9
		rb.arc(Vector3.ZERO, rad, 0.05, 0.0, TAU, Color(0.6, 0.9, 1.0, 0.7 - r * 0.15), 48)
		for k in 12:
			var a2 := TAU * k / 12.0
			rb.box(Vector3(cos(a2) * rad, 0.0, sin(a2) * rad), Vector3(0.18, 0.02, 0.06), Color(0.8, 1.0, 1.0, 0.9), Vector3(0, -a2, 0))
			if r == 1:
				rb.arc(Vector3(cos(a2) * rad, 0.0, sin(a2) * rad), 0.12, 0.02, 0.0, TAU, Color(1, 1, 1, 0.6), 10)
		var ri := MB.mesh_node(scene3d, rb.build(MB.mat_glow()))
		ri.position.y = 0.6 + r * 0.45
		ri.rotation.x = (r - 1) * 0.12
		rings.append(ri)
	# a column of rising qi above the hero's crown
	var col := MB.new()
	col.cyl(Vector3(0, 3.0, 0), 0.25, 5.0, Color(0.5, 0.9, 1.0, 0.18), Vector3.ZERO, 14)
	col.cyl(Vector3(0, 3.0, 0), 0.1, 5.0, Color(0.8, 1.0, 1.0, 0.25), Vector3.ZERO, 14)
	orbit = Node3D.new()
	scene3d.add_child(orbit)
	MB.mesh_node(orbit, col.build(MB.mat_glow()))
	# five element orbs circling the hero
	var ob := MB.new()
	var ecols := [Color("ff7a45"), Color("5aa9ff"), Color("6fe08a"), Color("d9a35a"), Color("f6e85c")]
	for i in 5:
		var a3 := TAU * i / 5.0
		ob.sph_hi(Vector3(cos(a3) * 1.6, 1.4, sin(a3) * 1.6), Vector3(0.14, 0.14, 0.14), Color(ecols[i].r, ecols[i].g, ecols[i].b, 0.95))
	MB.mesh_node(orbit, ob.build(MB.mat_aura()))
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
		rings[2].rotation.y = t * 0.22
		orbit.rotation.y = t * 0.6
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
	UI.bar(self, Rect2(475, 614, 175, 10), Game.hp[0] / float(Game.max_hp(0)), UI.C_RED)
	UI.text(self, Vector2(670, 626), "QI %d/%d" % [Game.qi[0], Game.max_qi(0)], 15)
	UI.bar(self, Rect2(770, 614, 150, 10), Game.qi[0] / float(Game.max_qi(0)), UI.C_BLUE)
	UI.text(self, Vector2(360, 656), "Esc / Enter: stop meditating", 13, UI.C_DIM)
