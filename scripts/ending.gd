extends ScreenBase
## Ending / results screen: the hero floats on a lotus in a golden sky.  Part V's finale adds the
## four mended pillars holding up the horizon, Hundun asleep around the centre of the world and
## rings of Nuwa's five colours turning overhead.  Part VI adds the Wheel of the Six Paths turning
## again behind them, soul lanterns rising past it, and Lin Feng's parents walking on to rebirth.
## Part VIII hangs the magpie bridge across the sky, with the Cowherd and the Weaver meeting on it.
## Part IX puts the sun and the moon in the sky together, taking turns, with Xihe, Chang'e and the
## nine new stars of the Dipper.  Part X sets the Nine Cauldrons, recast at Tushan with the land as
## it really is on their bellies, in an arc on the clouds below, a river winding between them.
## Part XI raises the Jianmu behind everything: the Standing Tree going up through the clouds into
## the Nine Heavens and down through them into the Nine Springs, feathered folk circling its crown,
## pearl-lights and shade-lanterns rising up its roots, and the six colours of the Daos round it.
## Part XII sets the Isles of the Eastern Sea on the shells of their sleeping turtles below, with
## Mazu's lantern-boat drifting between them and Jingwei flying a pebble over the sea, and Yue Ling
## waves, bows and laughs from the lotus.

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

## Part X: the Nine Cauldrons of Yu, recast, standing in an arc on the clouds in front of the lotus,
## each glowing faintly with the province it carries, and a river running between them to the sea
var cauldrons: Array = []

func _part10() -> void:
	for k in 9:
		var root := Node3D.new()
		var a := lerpf(-1.15, 1.15, k / 8.0)
		root.position = Vector3(sin(a) * 6.2, -1.1 - absf(a) * 0.2, -2.5 - cos(a) * 3.2)
		scene3d.add_child(root)
		var b := MB.new()
		var g := MB.new()
		var bronze := MB.tag(Color("8a7038").lerp(Color("4a8a6a"), 0.15 * (k % 3)), MB.METAL)
		b.lathe(Vector3(0, 0.25, 0), [Vector2(0.08, 0.0), Vector2(0.38, 0.06), Vector2(0.5, 0.22), Vector2(0.52, 0.42), Vector2(0.56, 0.5)], bronze, 14)
		for j in 3:
			var la := TAU * j / 3.0 + 0.5
			b.limb(Vector3(cos(la) * 0.34, 0.3, sin(la) * 0.34), Vector3(cos(la) * 0.42, -0.05, sin(la) * 0.42), 0.09, 0.07, bronze, 6)
		for s2: float in [-1.0, 1.0]:
			b.torus(Vector3(s2 * 0.42, 0.85, 0), 0.13, 0.03, bronze, Vector3(0, 0, PI * 0.5))
		g.disc(Vector3(0, 0.76, 0), 0.46, Color(1.0, 0.75, 0.35, 0.6), 12, Color(0.6, 0.9, 1.0, 0.2))
		for c in 3:
			b.sph(Vector3((c - 1) * 0.5, -0.12, 0.1 * c), Vector3(0.55, 0.22, 0.45), MB.tag(Color(1, 0.98, 0.95), MB.CLOTH))
		MB.mesh_node(root, b.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cauldrons.append(root)
	# the river that runs between them to the sea, every bend of it
	var rv := MB.new()
	var pts: Array = []
	var ws: Array = []
	for k in 13:
		var tt := k / 12.0
		pts.append(Vector3(sin(tt * 7.0) * 1.4 + (tt - 0.5) * 3.0, -1.32, -0.8 - tt * 12.0))
		ws.append(0.35 + tt * 0.9)
	rv.ribbon(pts, ws, Vector3.RIGHT, Color(0.55, 0.8, 1.0, 0.55))
	MB.mesh_node(scene3d, rv.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Part XI: the Jianmu, far behind, from the clouds below to the top of the sky, with its crown and
## its roots both in view, things of every realm climbing it, and a slow ring of the six Daos' colours
var jianmu11: Node3D = null
var climbers11: Array = []

func _part11() -> void:
	jianmu11 = Node3D.new()
	jianmu11.position = Vector3(-14.0, -14.0, -46.0)
	scene3d.add_child(jianmu11)
	var b := MB.new()
	var g := MB.new()
	var bark := MB.tag(Color("6a5034"), MB.WOOD)
	b.lathe(Vector3.ZERO, [Vector2(3.4, 0.0), Vector2(2.6, 4.0), Vector2(2.3, 20.0), Vector2(2.0, 40.0), Vector2(1.2, 46.0)], bark, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1111
	for k in 9:
		var a := TAU * k / 9.0
		var d := Vector3(cos(a), 0, sin(a))
		var base := Vector3(0, 30.0 + k * 1.6, 0) + d * 1.5
		var tip := base + d * rng.randf_range(7.0, 11.0) + Vector3(0, rng.randf_range(3.0, 7.0), 0)
		b.limb(base, tip, 0.7, 0.2, bark, 6)
		b.sph(tip, Vector3(3.6, 2.0, 3.6), MB.tag(Color("4a9a6a").lerp(Color("d8c860"), rng.randf() * 0.5), MB.FOLIAGE), Vector3.ZERO, true)
		g.ball(tip + Vector3(0, -1.2, 0), 0.25, Color(1.0, 0.85, 0.4, 0.9), true)
		var root_tip := Vector3(0, 0.0, 0) + d * rng.randf_range(6.0, 10.0) + Vector3(0, -rng.randf_range(4.0, 9.0), 0)
		b.limb(d * 2.0 + Vector3(0, 1.5, 0), root_tip, 0.9, 0.15, bark, 6)
	for k2 in Data.DAO_ORDER.size():
		var c: Color = Data.DAOS[Data.DAO_ORDER[k2]].col
		var a2 := TAU * k2 / float(Data.DAO_ORDER.size())
		g.torus(Vector3(0, 12.0 + k2 * 3.0, 0), 4.2 + 0.3 * k2, 0.05, Color(c.r, c.g, c.b, 0.55), Vector3(0.2 * sin(a2), 0, 0.2 * cos(a2)))
	MB.mesh_node(jianmu11, b.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(jianmu11, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# lights climbing the tree: feathers of the Yumin up the crown, pearls and lanterns up the roots
	for k3 in 12:
		var m := MB.new()
		var col: Color = [Color(0.9, 0.95, 1.0, 0.9), Color(0.6, 1.0, 0.95, 0.9), Color(0.75, 0.8, 1.0, 0.9)][k3 % 3]
		m.ball(Vector3.ZERO, 0.22, col, true)
		var n := MB.mesh_node(jianmu11, m.build(MB.mat_glow()))
		n.set_meta("phase", k3 / 12.0)
		climbers11.append(n)

## Part XII: the Isles of the Eastern Sea come up out of the cloud below, each on the shell of a
## sleeping turtle with Jingwei's reef of pebbles under it; Mazu's boat drifts between them with its
## red lantern lit, Jingwei flies a pebble over them, and the people on the lotus take turns to wave.
var isles12: Array = []
var boat12: Node3D = null
var bird12: Node3D = null
var mazu12: Node3D = null

func _part12() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1212
	for k in 3:
		var root := Node3D.new()
		root.position = Vector3(9.0 + k * 7.0, -5.5 - k * 0.6, -16.0 - k * 9.0)
		scene3d.add_child(root)
		var b := MB.new()
		var g := MB.new()
		var shell := MB.tag(Color("5a6a4a"), MB.SCALE)
		b.sph(Vector3(0, 0, 0), Vector3(3.4, 1.1, 4.0), shell)
		b.ball(Vector3(0, -0.2, 4.0), 0.9, MB.tag(Color("7a8a5a"), MB.SKIN))
		for s: float in [-1.0, 1.0]:
			b.sph(Vector3(s * 3.0, -0.6, 2.0), Vector3(1.4, 0.3, 0.7), MB.tag(Color("7a8a5a"), MB.SKIN), Vector3(0, s * 0.5, 0))
		# the reef of Jingwei's pebbles beside the turtle, and the isle on its back
		for q in 14:
			b.ball(Vector3(rng.randf_range(-3.8, 3.8), -0.9 + rng.randf() * 0.3, rng.randf_range(-3.0, 3.0)), rng.randf_range(0.3, 0.6), MB.tag([Color("d8c8b0"), Color("c87a5a"), Color("8a8a8a")][q % 3], MB.STONE))
		b.cone(Vector3(0, 1.0, -0.4), 2.6, 3.4, MB.tag(Color("e0dcd0"), MB.STONE), Vector3.ZERO, 9)
		b.sph(Vector3(0, 2.6, -0.4), Vector3(1.8, 0.8, 1.6), MB.tag(Color("5a9a5a"), MB.FOLIAGE))
		b.cyl(Vector3(0, 3.5, -0.4), 0.5, 1.0, MB.tag(Color("b8382a"), MB.WOOD), Vector3.ZERO, 8)
		b.cone(Vector3(0, 4.3, -0.4), 0.9, 0.7, MB.tag(Color("2f5a7a"), MB.STONE), Vector3.ZERO, 8)
		g.ball(Vector3(0, 3.6, 0.2), 0.12, Color(1.0, 0.6, 0.3, 0.9), true)
		MB.mesh_node(root, b.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		MB.mesh_node(root, g.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		isles12.append(root)
	boat12 = Models.mazu_boat()
	boat12.scale = Vector3.ONE * 0.7
	scene3d.add_child(boat12)
	if Assets.PEOPLE.has("mazu") and Assets.has(Assets.PEOPLE["mazu"]):
		mazu12 = Assets.person("mazu")
		mazu12.scale = Vector3.ONE * 0.7
		boat12.add_child(mazu12)
		mazu12.position = Vector3(2.0, 0.65, -0.6) / 0.7 * 0.7
	var bb := MB.new()
	bb.sph(Vector3.ZERO, Vector3(0.18, 0.14, 0.32), MB.tag(Color("5a504a"), MB.CLOTH))
	bb.ball(Vector3(0, 0.08, 0.3), 0.1, MB.tag(Color("f0ece4"), MB.CLOTH))
	bb.cone(Vector3(0, 0.08, 0.44), 0.04, 0.12, MB.tag(Color("f0f0e8"), MB.STONE), Vector3(PI / 2, 0, 0), 6)
	for s2: float in [-1.0, 1.0]:
		bb.leaf(Vector3(s2 * 0.1, 0.05, 0.0), Vector3(s2 * 0.75, 0.25, -0.1), 0.22, MB.tag(Color("6a5a52"), MB.CLOTH))
	bb.ball(Vector3(0, -0.18, 0.2), 0.07, MB.tag(Color("c87a5a"), MB.STONE))
	bird12 = Node3D.new()
	MB.mesh_node(bird12, bb.build(MB.mat_plain()))
	scene3d.add_child(bird12)

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
		if cauldrons.is_empty():
			_part10()
		for k in cauldrons.size():
			(cauldrons[k] as Node3D).rotation.y = t * 0.2 + k
			(cauldrons[k] as Node3D).position.y += sin(t * 1.1 + k) * 0.002
		if jianmu11 == null:
			_part11()
		if isles12.is_empty():
			_part12()
		# the turtles breathe in their sleep; Mazu's boat drifts between the isles and Jingwei flies over
		for k in isles12.size():
			(isles12[k] as Node3D).position.y = -5.5 - k * 0.6 + sin(t * 0.4 + k * 1.7) * 0.15
		var bt := t * 0.05
		boat12.position = Vector3(12.0 + sin(bt) * 6.0, -5.6, -24.0 + cos(bt) * 5.0)
		boat12.rotation.y = -bt + PI * 0.5
		if mazu12 != null:
			Models.anim_person(mazu12, t + 4.0, false)
			if fmod(t, 9.0) < 0.05:
				Models.act(mazu12, "wave", t + 4.0)
		var ba := t * 0.35
		bird12.position = Vector3(8.0 + cos(ba) * 9.0, 3.0 + sin(t * 1.3) * 0.6, -20.0 + sin(ba) * 7.0)
		bird12.rotation.y = -ba
		# on the lotus, Yue Ling takes her turn to wave, bow and laugh at everyone below
		var gk := int(t / 5.0)
		if gk != int(comp.get_meta("gk", -1)):
			comp.set_meta("gk", gk)
			if gk > 0:
				Models.act(comp, ["wave", "bow", "laugh", "offer"][gk % 4], t + 2.0)
		# up and down the ladder: lights of every realm climbing the Standing Tree
		for k in climbers11.size():
			var cn: Node3D = climbers11[k]
			var f := fmod(t * 0.05 + float(cn.get_meta("phase")), 1.0)
			var ca := f * TAU * 3.0 + k
			cn.position = Vector3(cos(ca) * 2.8, -4.0 + f * 46.0, sin(ca) * 2.8)
		cam.position = Vector3(sin(t * 0.15) * 1.5, 1.8, 6.5)
		cam.look_at(Vector3(0, 1.4, 0), Vector3.UP)
		queue_redraw()

func _draw() -> void:
	Gfx.title_text(self, Vector2(0, 110), "ASCENSION", 64, VIEW.x, t)
	UI.text(self, Vector2(0, 160), "Lin Feng, once a sweeper of steps, holds up the sky by choice, turns the Wheel gladly, and keeps every door open.", 22, Color("f2ead3"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 190), "The land is one land now. The magpies build their bridge, and the sun and the moon take turns.", 18, Color("e8dcc0"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 216), "Every river runs where it will, and the Nine Cauldrons hold the land as it really is.", 18, Color("e8dcc0"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 242), "The Jianmu stands again between heaven, earth and the Nine Springs, and every road climbs it.", 18, Color("e8dcc0"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 268), "Every water comes home through the Returning Ruins; the turtles take turns, and an old magician grows old.", 18, Color("e8dcc0"), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	if Game.dao != "":
		UI.text(self, Vector2(0, 294), "Walker of the %s, the Nine Heavens root %d ranks awake" % [Data.DAOS[Game.dao].n, Game.talent_ranks()], 17, Data.DAOS[Game.dao].col, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.panel(self, Rect2(400, 480, 480, 190), Color(0.04, 0.06, 0.13, 0.85))
	UI.text(self, Vector2(400, 520), "Total play time  %s" % Fmt.clock(Game.playtime), 26, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 556), "Realm: %s" % Data.level_name(Game.level), 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 586), "Foes defeated: %d   Battles: %d   Falls: %d" % [Game.kills, Game.battles, Game.deaths], 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 616), "Time spent meditating: %s" % Fmt.clock(Game.meditated), 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 480)
	UI.text(self, Vector2(400, 652), "Press Enter", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 480)
