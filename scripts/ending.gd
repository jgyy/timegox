extends ScreenBase
## Ending / results screen: the hero floats on a lotus in a golden sky.  Part V's finale adds the
## four mended pillars holding up the horizon, Hundun asleep around the centre of the world and
## rings of Nuwa's five colours turning overhead.  Part VI adds the Wheel of the Six Paths turning
## again behind them, soul lanterns rising past it, and Lin Feng's parents walking on to rebirth.
## Part VIII hangs the magpie bridge across the sky, with the Cowherd and the Weaver meeting on it.
## Part IX puts the sun and the moon in the sky together, taking turns, with Xihe, Chang'e and the
## nine new stars of the Dipper.

const VIEW := Vector2(1280, 720)

var done := false
var hero: Node3D
var comp: Node3D
var lot: Node3D
var hundun: Node3D
var rings: Array = []
var wheel: Node3D
var parents: Array = []
var lanterns: CPUParticles3D

func _on_show(v: bool) -> void:
	if v:
		main.fx_theme("garden")

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
	hero = Models.person(Color("f0f8ff"), Color("1a1a2a"), {"asset": "lin_feng", "sword": true, "glow": Color(1, 0.95, 0.7), "hair": "topknot", "crown": true, "trim": Color("f0c850"), "cape": Color("f8e8c0")})
	hero.position = Vector3(0, 0.25, 0)
	scene3d.add_child(hero)
	comp = Models.person(Color("ffd0e0"), Color("402030"), {"asset": "yue_ling", "ribbon": Color("ff9ac0"), "hair": "long", "eyes": Color("c04080"), "glow": Color(1.0, 0.7, 0.85)})
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
		# spread over the far half of the sky only: the old i * 1.1 + 0.4 put one peach island at
		# z = 5, between the camera and the hero, hiding the scene behind a giant trunk
		var a2 := PI * 1.1 + i * PI * 0.16
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
	# the four pillars, mended, holding up the sky at the edge of the world
	var pb := MB.new()
	var pg := MB.new()
	Terrain3D._sky_pillars(pb, pg, 0.0, -10.0, 70.0, "garden")
	var pm := MB.mesh_node(scene3d, pb.build(MB.mat_plain()))
	pm.position.y = -30.0
	pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pgm := MB.mesh_node(scene3d, pg.build(MB.mat_glow()))
	pgm.position.y = -30.0
	# Hundun, given a face at last, asleep far below with his wings folded around the world's centre
	hundun = Models.monster("hundun", Color("e05030"), false)
	hundun.position = Vector3(-7.0, -5.5, -16.0)
	hundun.scale = Vector3.ONE * 2.6
	hundun.rotation.y = 0.5
	scene3d.add_child(hundun)
	# five-coloured rings turning slowly in the sky
	for k in 5:
		var rb := MB.new()
		var c: Color = Fx3D.FIVE[k]
		rb.arc(Vector3.ZERO, 9.0 + k * 1.6, 0.18, 0.0, TAU, Color(c.r, c.g, c.b, 0.45), 96)
		var rm := MB.mesh_node(scene3d, rb.build(MB.mat_glow()), Vector3(0, 9.0 + k * 0.4, -14.0))
		rm.rotation = Vector3(1.25 + k * 0.05, k * 0.6, 0.0)
		rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rings.append(rm)
	# the Wheel of the Six Paths, turning again on the horizon
	wheel = Node3D.new()
	wheel.position = Vector3(10.0, 10.0, -42.0)
	scene3d.add_child(wheel)
	var wb := MB.new()
	var wg := MB.new()
	var stone := MB.tag(Color("d8d0e8"), MB.STONE)
	for i in 36:
		var a0 := TAU * i / 36.0
		var a1 := TAU * (i + 1) / 36.0
		wb.limb(Vector3(cos(a0), sin(a0), 0) * 12.0, Vector3(cos(a1), sin(a1), 0) * 12.0, 0.6, 0.6, stone, 6)
	for k in 6:
		var ak := TAU * k / 6.0
		var c6: Color = Fx3D.SIX[k]
		wb.limb(Vector3.ZERO, Vector3(cos(ak), sin(ak), 0) * 12.0, 0.4, 0.3, stone, 6)
		wg.ball(Vector3(cos(ak), sin(ak), 0) * 12.0, 1.1, Color(c6.r, c6.g, c6.b, 0.6), true)
	wb.cyl(Vector3.ZERO, 1.6, 1.4, stone, Vector3(PI * 0.5, 0, 0), 12)
	wg.ball(Vector3.ZERO, 2.4, Color(1.0, 0.95, 0.8, 0.4), true)
	var wm := MB.mesh_node(wheel, wb.build(MB.mat_plain()))
	wm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(wheel, wg.build(MB.mat_glow()))
	# soul lanterns drifting up past the wheel
	lanterns = Fx3D.make_weather()
	scene3d.add_child(lanterns)
	Fx3D.configure_weather(lanterns, "lily_souls")
	lanterns.position = Vector3(4.0, -6.0, -24.0)
	# Lin Shan and Su Wan, hand in hand, walking up a path of light towards the wheel
	for k in 2:
		var pid := "lin_shan" if k == 0 else "su_wan"
		var pm2 := Models.person(Color("7a7a70") if k == 0 else Color("6aa88a"), Color("1a1a2a"), {"asset": pid, "glow": Color(1.0, 0.9, 0.7)})
		pm2.position = Vector3(5.0 + k * 0.7, 2.0, -12.0)
		pm2.rotation.y = PI + 0.5
		pm2.scale = Vector3.ONE * 0.8
		scene3d.add_child(pm2)
		parents.append(pm2)
	var road := MB.new()
	for i in 24:
		var tt := i / 23.0
		road.box(Vector3(5.3, 1.9, -12.0).lerp(Vector3(9.0, 9.0, -40.0), tt), Vector3(1.4, 0.05, 1.4), Color(1.0, 0.9, 0.6, 0.35 * (1.0 - tt)), Vector3(0, 0.5, 0))
	MB.mesh_node(scene3d, road.build(MB.mat_glow()))

## Part VII: loose silver threads drifting down from the unpicked Loom, and three newborn souls'
## lanterns floating beside Yue Ling
var threads: Node3D
var souls: Array = []

func _part7() -> void:
	threads = Node3D.new()
	scene3d.add_child(threads)
	var tb := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 26:
		var base := Vector3(rng.randf_range(-22, 22), rng.randf_range(8, 18), rng.randf_range(-40, -10))
		var pts: Array = []
		var wid: Array = []
		for k in 8:
			pts.append(base + Vector3(sin(k * 0.8 + i) * 0.6, -k * 1.4, cos(k * 0.6 + i) * 0.3))
			wid.append(0.05 * (1.0 - k / 8.0) + 0.01)
		tb.ribbon(pts, wid, Vector3.RIGHT, Color(0.92, 0.92, 1.0, 0.55), Color(0.9, 0.8, 1.0, 0.0))
	MB.mesh_node(threads, tb.build(MB.mat_glow()))
	for k in 3:
		var sl := MB.new()
		sl.ball(Vector3.ZERO, 0.22, Color(1.0, 0.85, 0.5, 0.9), true)
		sl.ball(Vector3.ZERO, 0.5, Color(1.0, 0.7, 0.4, 0.25), true)
		var n := MB.mesh_node(scene3d, sl.build(MB.mat_glow()), Vector3(2.4 + k * 0.5, 1.6, -0.2 - k * 0.4))
		souls.append(n)

## Part VIII: the magpie bridge (art/props/magpiebridge.py) arching over the Star River, with
## Niu Lang and Zhi Nu walking towards each other and meeting at its crown
var bridge: Node3D
var lovers: Array = []

func _part8() -> void:
	bridge = Node3D.new()
	bridge.position = Vector3(-3.0, 0.3, -10.0)
	bridge.rotation.y = 0.05
	bridge.scale = Vector3.ONE * 2.2
	scene3d.add_child(bridge)
	if Assets.has("props/magpiebridge"):
		var bm := MB.mesh_node(bridge, Assets.static_mesh("props/magpiebridge"))
		bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 2:
		var pid := "niu_lang" if k == 0 else "zhi_nu"
		var lv := Models.person(Color("5a7a9a") if k == 0 else Color("e8d8f8"), Color("1a1a2a"), {"asset": pid, "glow": Color(1.0, 0.9, 0.8)})
		lv.scale = Vector3.ONE * 0.42
		lv.rotation.y = PI * 0.5 if k == 0 else -PI * 0.5
		bridge.add_child(lv)
		lovers.append(lv)

## Part IX: the sun and the moon in the sky together, taking turns (one sinks as the other rises),
## Xihe flying beside her youngest son's sun with the little sun-crow, Chang'e on a cloud by the
## moon with the Jade Rabbit, and the nine fallen suns risen as the nine stars of the Dipper
var sun9: Node3D
var moon9: Node3D
var xihe9: Node3D
var crow9: Node3D
var change9: Node3D

func _part9() -> void:
	sun9 = Node3D.new()
	sun9.position = Vector3(-18.0, 15.7, -33.5)
	scene3d.add_child(sun9)
	var sg := MB.new()
	sg.ball(Vector3.ZERO, 2.0, Color(1.0, 0.92, 0.6, 1.0), true)
	sg.ball(Vector3.ZERO, 3.6, Color(1.0, 0.75, 0.35, 0.35), true)
	sg.ball(Vector3.ZERO, 6.0, Color(1.0, 0.65, 0.3, 0.12), true)
	MB.mesh_node(sun9, sg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	moon9 = Node3D.new()
	moon9.position = Vector3(16.8, 14.4, -33.5)
	scene3d.add_child(moon9)
	var mb := MB.new()
	mb.ball(Vector3.ZERO, 1.9, MB.tag(Color("eef2ff"), MB.STONE))
	for k in 6:
		var a := k * 2.2
		mb.ball(Vector3(cos(a) * 0.9, sin(a * 1.3) * 0.8, 1.45), 0.32 + 0.1 * (k % 3), MB.tag(Color("c8d0e8"), MB.STONE), true)
	MB.mesh_node(moon9, mb.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mg := MB.new()
	mg.ball(Vector3.ZERO, 3.2, Color(0.75, 0.85, 1.0, 0.22), true)
	MB.mesh_node(moon9, mg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Xihe, the first sun-crow, and her youngest son beside the sun
	xihe9 = Models.monster("phoenix", Color("ff7040"), false)
	xihe9.scale = Vector3.ONE * 0.9
	xihe9.rotation.y = PI * 0.35
	scene3d.add_child(xihe9)
	crow9 = Models.monster("sun_crow", Color("ff9a20"), false)
	crow9.scale = Vector3.ONE * 0.45
	crow9.rotation.y = PI * 0.35
	scene3d.add_child(crow9)
	# Chang'e on a little cloud below the moon, the Jade Rabbit in her arms
	change9 = Node3D.new()
	change9.position = Vector3(9.5, 4.2, -16.0)
	scene3d.add_child(change9)
	var cl := MB.new()
	for k in 5:
		cl.sph(Vector3((k - 2) * 0.45, -0.1 - 0.06 * absf(k - 2), 0.0), Vector3(0.6, 0.3, 0.5), MB.tag(Color(1, 0.98, 0.95), MB.CLOTH))
	MB.mesh_node(change9, cl.build(MB.mat_plain()))
	var ce := Models.person(Color("e8eef8"), Color("14141e"), {"asset": "chang_e", "glow": Color(0.85, 0.9, 1.0), "hair": "long"})
	ce.scale = Vector3.ONE * 1.3
	ce.rotation.y = -0.5
	change9.add_child(ce)
	change9.set_meta("person", ce)
	# the Dipper above the moon: seven stars anyone can see (bowl, then handle) and the two that
	# nobody could, until the nine fallen suns rose to fill them
	var dg := MB.new()
	var dipper := [Vector2(12.0, 18.8), Vector2(12.0, 17.0), Vector2(14.5, 16.6), Vector2(14.9, 18.4), Vector2(17.0, 19.0), Vector2(19.0, 19.5), Vector2(21.0, 18.8), Vector2(19.6, 20.6), Vector2(22.1, 20.4)]
	for k in dipper.size():
		var sp: Vector2 = dipper[k]
		var big := k < 7
		dg.ball(Vector3(sp.x, sp.y, -36.0), 0.32 if big else 0.22, Color(1.0, 0.95, 0.8, 1.0) if big else Color(1.0, 0.8, 0.5, 0.9), true)
		dg.ball(Vector3(sp.x, sp.y, -36.0), 0.9 if big else 0.6, Color(1.0, 0.85, 0.6, 0.18), true)
	MB.mesh_node(scene3d, dg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
		Models.anim_monster(hundun, t * 0.5, 0.0)
		for k in rings.size():
			rings[k].rotation.y = k * 0.6 + t * (0.05 + k * 0.012) * (1 if k % 2 == 0 else -1)
		wheel.rotation.z = t * 0.12
		for k in parents.size():
			var pp: Node3D = parents[k]
			var walk := fmod(t * 0.04, 1.0)
			pp.position = Vector3(5.0 + k * 0.7, 2.0, -12.0).lerp(Vector3(9.0 + k * 0.7, 8.8, -38.0), walk)
			pp.visible = walk < 0.92
			Models.anim_person(pp, t + k, true)
		if threads == null:
			_part7()
		threads.position.y = -fmod(t * 0.6, 6.0)
		for k in souls.size():
			(souls[k] as Node3D).position.y = 1.6 + sin(t * 1.3 + k * 2.1) * 0.25
		if bridge == null:
			_part8()
		# the lovers walk up from either end, meet at the crown and stay there together
		var meet := clampf(t * 0.08, 0.0, 1.0)
		for k in lovers.size():
			var lv: Node3D = lovers[k]
			var s := -1.0 if k == 0 else 1.0
			var x := s * lerpf(3.6, 0.22, meet)
			lv.position = Vector3(x, 1.5 * (1.0 - pow(absf(x) / 4.2, 1.7)) + 0.08, 0.0)
			Models.anim_person(lv, t + k, meet < 1.0)
		if sun9 == null:
			_part9()
		# the sun and the moon take turns: one sinks as the other rises
		var turn := sin(t * 0.12)
		sun9.position.y = 15.7 + turn * 1.4
		moon9.position.y = 14.4 - turn * 1.4
		# Xihe flies her youngest across the sky, a little below and ahead of his sun
		var fly := Vector3(-10.0 + sin(t * 0.7) * 0.4, 10.6 + turn * 1.4 + sin(t * 1.1) * 0.3, -23.5)
		xihe9.position = fly
		crow9.position = fly + Vector3(1.6, 0.6 + sin(t * 1.7) * 0.2, 0.4)
		Models.anim_monster(xihe9, t, 0.0)
		Models.anim_monster(crow9, t + 0.7, 0.0)
		change9.position.y = 4.2 + sin(t * 0.8) * 0.15
		Models.anim_person(change9.get_meta("person"), t + 3.0, false)
		cam.position = Vector3(sin(t * 0.15) * 1.5, 1.8, 6.5)
		cam.look_at(Vector3(0, 1.4, 0), Vector3.UP)
		queue_redraw()

func _draw() -> void:
	Gfx.title_text(self, Vector2(0, 110), "ASCENSION", 64, VIEW.x, t)
	UI.text(self, Vector2(0, 160), "Lin Feng, once a sweeper of steps, holds up the sky by choice, turns the Wheel gladly, and keeps every door open.", 22, Color("f2ead3"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 190), "The land is one land now. The magpies build their bridge, and the sun and the moon take turns.", 18, Color("e8dcc0"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.panel(self, Rect2(400, 480, 480, 190), Color(0.04, 0.06, 0.13, 0.85))
	UI.text(self, Vector2(400, 520), "Total play time  %s" % Fmt.clock(Game.playtime), 26, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 556), "Realm: %s" % Data.level_name(Game.level), 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 586), "Foes defeated: %d   Battles: %d   Falls: %d" % [Game.kills, Game.battles, Game.deaths], 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 616), "Time spent meditating: %s" % Fmt.clock(Game.meditated), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 652), "Press Enter", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 480)
