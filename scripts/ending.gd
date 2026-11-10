extends ScreenBase
## Ending / results screen: the Ascension.  A short film over the sea of clouds at sunset, one shot
## for every wonder the story set right, each with its line of the epilogue as a subtitle between
## letterbox bars:
##   the magpie bridge over the Star River with the Cowherd and the Weaver meeting on it, the sun
##   and the moon taking turns, Xihe flying her youngest, Chang'e and the two new stars of the
##   Dipper (Parts VIII and IX);
##   the Nine Cauldrons of Yu on the clouds with a river running between them (X);
##   the Jianmu rising out of the clouds, lights of every realm climbing it (XI);
##   the Isles of the Eastern Sea on their sleeping turtles, Mazu's lantern-boat and Jingwei (XII);
##   the Eight Gates standing open in a ring on the clouds, each with its trigram glowing over the
##   arch, maple leaves blowing through, and the Jianmu over them where the Conclave meets (XIII);
##   the Wheel of the Six Paths turning again inside Nuwa's five rings, Lin Feng's parents walking
##   up a road of light to it among the soul lanterns and the Loom's loose threads, Hundun asleep in
##   the clouds below and two of the four mended pillars holding up the sky (V, VI, VII).
## Then Lin Feng and Yue Ling on a lotus over the clouds, the newborn souls' lanterns beside her
## (VII); the camera draws back and the results come up beside them: the time, the realm and the
## Dao, the battles, renown and deeds, and the roads taken through the trials (Part XIII).  Enter
## skips the film; Enter on the results ends the game.

const VIEW := Vector2(1280, 720)
## letterbox bars while the film runs, and the dip to dark at every cut (seconds either side of it)
const BAR := 46.0
const DIP := 0.35

## where each wonder stands: far enough apart that every shot has a piece of the sky to itself
const AT_BRIDGE := Vector3(-190.0, 0.0, 60.0)
const AT_CAULDRONS := Vector3(190.0, -3.0, 60.0)
const AT_JIANMU := Vector3(-179.0, -2.0, -269.0)
const AT_ISLES := Vector3(170.0, -4.2, 230.0)
const AT_GATES := Vector3(-7.0, -6.5, -133.0)
const AT_WHEEL := Vector3(-60.0, 20.0, 260.0)

## the film: one shot for every wonder set right, the set pieces it shows, how thick the air is
## and its line of the epilogue; the last draws back from the lotus to the results
const FILM := [
	{"id": "bridge", "dur": 7.0, "place": "The Magpie Bridge", "show": ["bridge"], "fog": 0.004,
		"line": "The land is one land now. The magpies build their bridge, and the sun and the moon take turns."},
	{"id": "cauldrons", "dur": 6.5, "place": "The Nine Cauldrons", "show": ["cauldrons"], "fog": 0.006,
		"line": "Every river runs where it will, and the Nine Cauldrons hold the land as it really is."},
	{"id": "jianmu", "dur": 7.0, "place": "The Jianmu", "show": ["jianmu"], "fog": 0.0022,
		"line": "The Jianmu stands again between heaven, earth and the Nine Springs, and every road climbs it."},
	{"id": "isles", "dur": 6.5, "place": "The Isles of the Eastern Sea", "show": ["isles"], "fog": 0.005,
		"line": "Every water comes home through the Returning Ruins; the turtles take turns, and an old magician grows old."},
	{"id": "gates", "dur": 7.0, "place": "The Eight Gates", "show": ["gates", "jianmu"], "fog": 0.0028,
		"line": "The Eight Gates stand open, the war god of the Nine Li has stopped fighting, and the Conclave argues happily under the Jianmu."},
	{"id": "wheel", "dur": 7.0, "place": "The Wheel of the Six Paths", "show": ["wheel"], "fog": 0.003,
		"line": "The Wheel turns again, the four pillars hold up the sky, and Lin Shan and Su Wan walk on to their next life."},
	{"id": "hero", "dur": 8.0, "place": "The Azure Cloud", "show": ["hero", "gates", "jianmu"], "fog": 0.0026,
		"line": "Lin Feng, once a sweeper of steps, holds up the sky by choice, turns the Wheel gladly, and keeps every door open."},
]

## how the war god's story ended, by the road Lin Feng took into the field of Zhuolu (Part XIII):
## [the road, the last words under the title]
const ROAD_ENDS := {
	"sword": ["the Road of the Sword", "Chiyou lay down in the field of Zhuolu and closed his eyes, and the fog never came back."],
	"peoples": ["the Road of the Many Peoples", "The war god of the Nine Li took a seat at the Conclave, and argued with everybody."],
	"cauldron": ["the Road of the Cauldron", "Chiyou went home to the plains of the Nine Li as autumn leaves, smiling."],
}
const KIND_WORD := {"folk": "the People", "might": "Might", "craft": "Craft", "wealth": "Wealth", "respect": "Respect", "dao": "Dao", "peoples": "Friendship", "relic": "Relic", "bond": "Bonds", "heart": "Side by side", "land": "the Land", "hearth": "the Hearths"}
## where the camera rests while the results are read: the two of them on the lotus at the left of
## the frame, the Jianmu far off beyond them and the gates on the clouds towards the setting sun
const REST_EYE := Vector3(2.4, 1.55, 6.6)
const REST_LOOK := Vector3(1.56, 2.0, -5.4)

var done := false
var built := false
## the hero's look and dress the lotus's model was built for (character creation, the wardrobe)
var hero_sig := ""
## the New Fire release (cultures.gd ENDINGS): the light of the film for the end chosen, and the hero's
## own fire on the lotus between the two of them
var sun_light: DirectionalLight3D = null
var hearth_fire: Node3D = null
var ending_sig := "-"
var groups := {}
var shot_on := -1
var hero: Node3D = null
var comp: Node3D = null
var lot: Node3D = null
var souls: Array = []
var hundun: Node3D = null
var rings: Array = []
var wheel: Node3D = null
var parents: Array = []
var threads: Node3D = null
var bridge: Node3D = null
var lovers: Array = []
var sun9: Node3D = null
var moon9: Node3D = null
var xihe9: Node3D = null
var crow9: Node3D = null
var change9: Node3D = null
var cauldrons: Array = []
var climbers11: Array = []
var dao_rings: Node3D = null
var isles12: Array = []
var boat12: Node3D = null
var bird12: Node3D = null
var mazu12: Node3D = null
var gates13: Node3D = null
var leaves13: Array = []
## the trigrams of the Eight Gates in the order of Trials.GATES (Opening, Alarm, Rest, Death, Sight,
## Closing, Life, Harm), lines from the bottom up: 1 an unbroken (yang) line, 0 a broken (yin) one
const TRIGRAMS := [[1, 1, 1], [1, 1, 0], [0, 1, 0], [0, 0, 0], [1, 0, 1], [0, 1, 1], [0, 0, 1], [1, 0, 0]]

## the whole film, in seconds (the results come up when it ends)
static func film_length() -> float:
	var s := 0.0
	for f in FILM:
		s += float(f.dur)
	return s

## the shot on screen at `tt` seconds and how far into it: [index, seconds]; after the film the last
## shot goes on (its camera resting by the lotus)
static func shot_at(tt: float) -> Array:
	var t0 := 0.0
	for i in FILM.size():
		var d := float(FILM[i].dur)
		if tt < t0 + d or i == FILM.size() - 1:
			return [i, tt - t0]
		t0 += d
	return [FILM.size() - 1, 0.0]

func _on_show(v: bool) -> void:
	if v:
		main.fx_theme("garden")
		t = 0.0
		done = false
		shot_on = -1
		_refresh_hero()
		_refresh_ending()

## The hero on the lotus as the player made him and dressed him: the world is built once, so a second
## New Game (another name, another look) used to end with the first game's hero.
func _refresh_hero() -> void:
	var sig := "%s|%s" % [str(Game.hero), Game.outfit]
	if not built or hero == null or sig == hero_sig:
		return
	var parent := hero.get_parent()
	var xf := hero.transform
	hero.queue_free()
	hero = Models.hero()
	hero.transform = xf
	parent.add_child(hero)
	hero_sig = sig

## The end the player chose (cultures.gd ENDINGS): its light over the whole film and the colour of the
## hero's own fire.
func _refresh_ending() -> void:
	var id := Cultures.ending_of(Game)
	if not built or id == ending_sig:
		return
	ending_sig = id
	var sky: Color = Cultures.ENDINGS[id].sky
	if sun_light != null:
		sun_light.light_color = Color(1.0, 0.84, 0.66) * sky
	if hearth_fire != null:
		for c in hearth_fire.get_children():
			if c is OmniLight3D:
				(c as OmniLight3D).light_color = Color(1.0, 0.62, 0.3) * sky

## The film's last line and its caption for the end chosen.
static func hero_shot() -> Dictionary:
	var ml := Engine.get_main_loop() as SceneTree
	var g = ml.root.get_node_or_null("Game") if ml != null and ml.root != null else null
	var s: Dictionary = FILM[FILM.size() - 1].duplicate()
	if g != null and str(g.ending) != "" and Cultures.ENDINGS.has(str(g.ending)) and str(g.ending) != "azure":
		var en: Dictionary = Cultures.ENDINGS[str(g.ending)]
		s["place"] = str(en.n)
		var sub: String = str(en.sub)
		s["line"] = "Lin Feng, once a sweeper of steps, holds up the sky by choice, and keeps a fire: %s." % (sub.substr(0, 1).to_lower() + sub.substr(1))
	return s

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(45.0)
	cam.far = 1000.0
	cam.environment = Look.environment("garden", 0.5)
	# sunset over the sea of clouds: violet overhead, peach and gold along the horizon
	Look.tint_sky(cam.environment, Color("2c2862"), Color("ffbe8c"), Color("f6c4a6"))
	cam.environment.fog_sky_affect = 0.0
	var sun := Look.sun("garden", false)
	sun.light_color = Color(1.0, 0.84, 0.66)
	sun.light_energy = 1.25
	# low, from behind the camera's left shoulder in every shot; it lights the scene only (the sky
	# has its own sun and moon where they are wanted, and would otherwise show two)
	sun.rotation_degrees = Vector3(-24.0, -28.0, 0.0)
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	scene3d.add_child(sun)
	sun_light = sun
	scene3d.add_child(Look.fill("garden"))

func _group(n: String, pos: Vector3) -> Node3D:
	var g := Node3D.new()
	g.name = n
	g.position = pos
	scene3d.add_child(g)
	groups[n] = g
	return g

## the world is built the first time the ending is seen (never at start-up, never headless)
func _build_world() -> void:
	built = true
	_build_sea()
	_build_hero()
	_build_bridge()
	_build_cauldrons()
	_build_jianmu()
	_build_isles()
	_build_gates()
	_build_wheel()

## the sea of clouds under everything: rolling cream-white crests and lilac hollows, far past the fog
func _build_sea() -> void:
	var g := _group("sea", Vector3.ZERO)
	var noise := FastNoiseLite.new()
	noise.seed = 4242
	noise.frequency = 0.016
	var n := 110
	var half := 550.0
	var cell := half * 2.0 / n
	var hs := PackedFloat32Array()
	hs.resize((n + 1) * (n + 1))
	for j in n + 1:
		for i in n + 1:
			var x := -half + i * cell
			var z := -half + j * cell
			hs[j * (n + 1) + i] = -6.4 + noise.get_noise_2d(x, z) * 2.6 + noise.get_noise_2d(x * 3.1, z * 3.1) * 0.6
	var crest := Color(1.0, 0.92, 0.83)
	var hollow := Color(0.75, 0.66, 0.82)
	var b := MB.new()
	for j in n:
		for i in n:
			var ps: Array = []
			var ns: Array = []
			var cs: Array = []
			for q in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var y := hs[q.y * (n + 1) + q.x]
				ps.append(Vector3(-half + q.x * cell, y, -half + q.y * cell))
				var hl := hs[q.y * (n + 1) + maxi(q.x - 1, 0)]
				var hr := hs[q.y * (n + 1) + mini(q.x + 1, n)]
				var hd := hs[maxi(q.y - 1, 0) * (n + 1) + q.x]
				var hu := hs[mini(q.y + 1, n) * (n + 1) + q.x]
				ns.append(Vector3(hl - hr, cell * 2.0, hd - hu).normalized())
				var c := hollow.lerp(crest, clampf((y + 8.6) / 4.6, 0.0, 1.0))
				cs.append(Color(c.r, c.g, c.b, MB.CLOTH))
			b.quad_n(ps, ns, cs)
	MB.mesh_node(g, b.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## a bank of cloud: a few soft puffs heaped together, for a set piece to stand or float on
static func _cloud(b: MB, at: Vector3, size: float, seed_: int, col: Color = Color(1.0, 0.95, 0.92)) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	for k in 7:
		var off := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.15, 0.25), rng.randf_range(-0.6, 0.6)) * size
		var r := size * rng.randf_range(0.45, 0.8)
		b.sph(at + off, Vector3(r, r * 0.55, r * 0.8), MB.tag(col, MB.CLOTH))

## a soft round glow: nested shells of light, brightest in the middle, so the edge fades instead
## of showing as a polygon
static func _halo(g: MB, at: Vector3, r: float, col: Color, layers: int = 5) -> void:
	for k in layers:
		var f := (k + 1.0) / layers
		g.sph_hi(at, Vector3.ONE * r * f, Color(col.r, col.g, col.b, col.a * (1.15 - f) / layers * 2.0))

## a rising lotus: three rings of cupped petals, white at the heart and blushing at the tips, a
## golden seed-head, on a little cloud of its own
static func _lotus(b: MB, g: MB, r: float) -> void:
	for ring in 3:
		var n := 9 + ring * 3
		for i in n:
			var a := TAU * (i + ring * 0.5) / n
			var d := Vector3(sin(a), 0, cos(a))
			var reach := r * (0.42 + ring * 0.25)
			var lift := r * (0.6 - ring * 0.19)
			var root := d * r * (0.1 + ring * 0.12) + Vector3(0, 0.04 + ring * 0.02, 0)
			var tip := d * reach + Vector3(0, lift, 0)
			var c0 := MB.tag(Color("fff6f4").lerp(Color("ffe0ea"), ring * 0.3), MB.CLOTH)
			var c1 := MB.tag(Color("f29cbc").lerp(Color("ffc8d8"), ring * 0.3), MB.CLOTH)
			b.leaf(root, tip, r * (0.3 - ring * 0.03), c0, Vector3(cos(a), 0, -sin(a)), c1)
	b.cyl(Vector3(0, 0.2, 0), r * 0.24, 0.2, MB.tag(Color("e8c048"), MB.CLOTH), Vector3.ZERO, 16)
	for i in 9:
		var a2 := TAU * i / 9.0
		b.ball(Vector3(sin(a2) * r * 0.14, 0.31, cos(a2) * r * 0.14), r * 0.03, MB.tag(Color("fff0a0"), MB.CRYSTAL))
	g.disc(Vector3(0, 0.05, 0), r * 1.5, Color(1.0, 0.82, 0.66, 0.22), 40, Color(1.0, 0.8, 0.66, 0.0))

## Lin Feng and Yue Ling on the lotus, the newborn souls' lanterns beside her (Part VII), petals
## blowing past, and the evening sun going down behind the gates
func _build_hero() -> void:
	var g := _group("hero", Vector3.ZERO)
	lot = Node3D.new()
	g.add_child(lot)
	var lb := MB.new()
	var lg := MB.new()
	var lc := MB.new()
	_lotus(lb, lg, 1.1)
	_cloud(lc, Vector3(0, -0.95, 0), 0.75, 777)
	MB.mesh_node(lot, lb.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(lot, lc.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(lot, lg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# (no pools of light underfoot: the lotus has its own glow)
	hero = Models.hero()
	hero_sig = "%s|%s" % [str(Game.hero), Game.outfit]
	hero.position = Vector3(-0.38, 0.3, 0.12)
	hero.rotation.y = 0.35
	g.add_child(hero)
	comp = Models.person(Color("ffd0e0"), Color("402030"), {"asset": "yue_ling", "ribbon": Color("ff9ac0"), "hair": "long", "eyes": Color("c04080")})
	comp.position = Vector3(0.42, 0.3, -0.2)
	comp.rotation.y = -0.15
	g.add_child(comp)
	# the New Fire release: the hero's own fire, three stones and a flame on the lotus before the two
	# of them (wherever it is kept, cultures.gd ENDINGS: the film's light changes with the end chosen)
	hearth_fire = Node3D.new()
	hearth_fire.position = Vector3(0.06, 0.34, 0.62)
	g.add_child(hearth_fire)
	var hs := MB.new()
	for k3 in 3:
		var a3 := TAU * k3 / 3.0 + 0.4
		hs.sph_hi(Vector3(cos(a3) * 0.13, 0.03, sin(a3) * 0.13), Vector3(0.075, 0.055, 0.07), MB.tag(Color("6a6460"), MB.STONE))
	MB.mesh_node(hearth_fire, hs.build(MB.mat_plain()))
	var hf := MB.new()
	hf.sph_hi(Vector3(0, 0.1, 0), Vector3(0.07, 0.13, 0.07), Color(1.0, 0.66, 0.22, 0.95))
	hf.sph_hi(Vector3(0.02, 0.17, 0.01), Vector3(0.04, 0.1, 0.04), Color(1.0, 0.9, 0.5, 0.95))
	_halo(hf, Vector3(0, 0.12, 0), 0.34, Color(1.0, 0.6, 0.25, 0.5), 4)
	var hfn := MB.mesh_node(hearth_fire, hf.build(MB.mat_glow()))
	hfn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hfn.set_meta("flame", true)
	var hl := OmniLight3D.new()
	hl.light_color = Color(1.0, 0.62, 0.3)
	hl.light_energy = 1.4
	hl.omni_range = 3.2
	hl.position = Vector3(0, 0.25, 0)
	hearth_fire.add_child(hl)
	for k in 3:
		var sl := MB.new()
		sl.sph_hi(Vector3.ZERO, Vector3.ONE * 0.045, Color(1.0, 0.92, 0.7, 1.0))
		_halo(sl, Vector3.ZERO, 0.13, Color(1.0, 0.72, 0.42, 0.45), 3)
		var n := MB.mesh_node(g, sl.build(MB.mat_glow()), Vector3(0.95 + k * 0.22, 1.5, -0.5 - k * 0.22))
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		souls.append(n)
	var w := Fx3D.make_weather()
	g.add_child(w)
	Fx3D.configure_weather(w, "petals")
	w.position = Vector3(0, 7, -2)
	w.amount = 50
	# the sun, going down into the clouds beyond the gates
	var sg := MB.new()
	_halo(sg, Vector3.ZERO, 34.0, Color(1.0, 0.72, 0.4, 0.9), 6)
	sg.sph_hi(Vector3.ZERO, Vector3.ONE * 8.5, Color(1.0, 0.9, 0.62, 0.95))
	MB.mesh_node(g, sg.build(MB.mat_glow()), Vector3(10.0, 9.0, -520.0)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Part VIII and IX: the magpie bridge (art/props/magpiebridge.py) arching over the Star River, the
## Cowherd and the Weaver walking to meet at its crown; the sun and the moon in the sky together,
## Xihe flying beside her youngest son's sun with the little sun-crow, Chang'e on a cloud by the moon
## with the Jade Rabbit, and the nine fallen suns risen as the two new stars of the Dipper
func _build_bridge() -> void:
	var g := _group("bridge", AT_BRIDGE)
	bridge = Node3D.new()
	bridge.scale = Vector3.ONE * 2.6
	g.add_child(bridge)
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
	# the Star River running under the bridge out of the far sky: a band of pale light full of stars
	var rv := MB.new()
	var sg := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	var pts: Array = []
	var ws: Array = []
	for k in 25:
		var tt := k / 24.0
		pts.append(_star_river(tt))
		ws.append(7.0 + tt * 18.0)
	rv.ribbon(pts, ws, Vector3.RIGHT, Color(0.55, 0.62, 1.0, 0.3), Color(0.8, 0.7, 1.0, 0.0))
	for q in 110:
		var tt := rng.randf()
		var p0 := _star_river(tt) + Vector3(rng.randf_range(-0.5, 0.5) * (7.0 + tt * 18.0), 0.1, 0.0)
		var sr := rng.randf_range(0.05, 0.14) * (1.0 + tt * 2.0)
		sg.sph_hi(p0, Vector3.ONE * sr, Color(1.0, 0.96, 0.88, rng.randf_range(0.35, 0.8)))
	MB.mesh_node(g, rv.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(g, sg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sun9 = Node3D.new()
	g.add_child(sun9)
	var sb := MB.new()
	_halo(sb, Vector3.ZERO, 11.0, Color(1.0, 0.72, 0.38, 0.9), 6)
	sb.sph_hi(Vector3.ZERO, Vector3.ONE * 2.6, Color(1.0, 0.93, 0.66, 1.0))
	MB.mesh_node(sun9, sb.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	moon9 = Node3D.new()
	g.add_child(moon9)
	var mb := MB.new()
	mb.sph_hi(Vector3.ZERO, Vector3.ONE * 2.3, MB.tag(Color("eef2ff"), MB.STONE))
	for k in 6:
		var a := k * 2.2
		mb.ball(Vector3(cos(a) * 1.0, sin(a * 1.3) * 0.9, 1.8), 0.36 + 0.1 * (k % 3), MB.tag(Color("c8d0e8"), MB.STONE))
	MB.mesh_node(moon9, mb.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mg := MB.new()
	_halo(mg, Vector3.ZERO, 6.5, Color(0.75, 0.85, 1.0, 0.55), 4)
	MB.mesh_node(moon9, mg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	xihe9 = Models.monster("phoenix", Color("ff7040"), false)
	xihe9.scale = Vector3.ONE * 1.1
	xihe9.rotation.y = PI * 0.35
	g.add_child(xihe9)
	crow9 = Models.monster("sun_crow", Color("ff9a20"), false)
	crow9.scale = Vector3.ONE * 0.55
	crow9.rotation.y = PI * 0.35
	g.add_child(crow9)
	change9 = Node3D.new()
	change9.position = Vector3(16.0, 5.0, -20.0)
	g.add_child(change9)
	var cl := MB.new()
	for k in 5:
		cl.sph(Vector3((k - 2) * 0.45, -0.1 - 0.06 * absf(k - 2), 0.0), Vector3(0.6, 0.3, 0.5), MB.tag(Color(1, 0.98, 0.95), MB.CLOTH))
	MB.mesh_node(change9, cl.build(MB.mat_plain()))
	var ce := Models.person(Color("e8eef8"), Color("14141e"), {"asset": "chang_e", "glow": Color(0.85, 0.9, 1.0), "hair": "long"})
	ce.scale = Vector3.ONE * 1.3
	ce.rotation.y = -0.4
	change9.add_child(ce)
	change9.set_meta("person", ce)
	# the Dipper above the moon: seven stars anyone can see (bowl, then handle) and the two that
	# nobody could, until the nine fallen suns rose to fill them
	var dg := MB.new()
	var dipper := [Vector2(14.0, 25.0), Vector2(14.0, 23.0), Vector2(16.8, 22.6), Vector2(17.2, 24.6), Vector2(19.5, 25.3), Vector2(21.7, 25.8), Vector2(23.9, 25.0), Vector2(22.4, 27.0), Vector2(25.1, 26.8)]
	for k in dipper.size():
		var sp: Vector2 = dipper[k]
		var big := k < 7
		var at := Vector3(sp.x, sp.y, -48.0)
		dg.sph_hi(at, Vector3.ONE * (0.2 if big else 0.16), Color(1.0, 0.97, 0.88, 1.0) if big else Color(1.0, 0.82, 0.55, 1.0))
		_halo(dg, at, 0.9 if big else 0.7, Color(1.0, 0.85, 0.6, 0.5), 3)
	MB.mesh_node(g, dg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cb := MB.new()
	_cloud(cb, Vector3(-11.5, -2.4, 1.0), 3.4, 81)
	_cloud(cb, Vector3(11.5, -2.4, 1.0), 3.4, 82)
	MB.mesh_node(g, cb.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## where the Star River runs (0 under the near end, 1 at the far edge of the sky)
static func _star_river(tt: float) -> Vector3:
	return Vector3(sin(tt * 5.0) * 6.0 - 4.0 + tt * 6.0, -1.7 - tt * 1.5, 34.0 - tt * 160.0)

## Part X: the Nine Cauldrons of Yu, recast, standing in an arc on the clouds, each glowing faintly
## with the province it carries, and a river running between them to the sea
func _build_cauldrons() -> void:
	var g := _group("cauldrons", AT_CAULDRONS)
	var clouds := MB.new()
	for k in 9:
		var root := Node3D.new()
		var a := lerpf(-1.25, 1.25, k / 8.0)
		root.position = Vector3(sin(a) * 10.0, 0.2 - absf(a) * 0.3, -cos(a) * 6.5)
		root.scale = Vector3.ONE * 1.6
		g.add_child(root)
		var b := MB.new()
		var gl := MB.new()
		var bronze := MB.tag(Color("8a7038").lerp(Color("4a8a6a"), 0.15 * (k % 3)), MB.METAL)
		b.lathe(Vector3(0, 0.25, 0), [Vector2(0.08, 0.0), Vector2(0.38, 0.06), Vector2(0.5, 0.22), Vector2(0.52, 0.42), Vector2(0.56, 0.5)], bronze, 16)
		for j in 3:
			var la := TAU * j / 3.0 + 0.5
			b.limb(Vector3(cos(la) * 0.34, 0.3, sin(la) * 0.34), Vector3(cos(la) * 0.42, -0.05, sin(la) * 0.42), 0.09, 0.07, bronze, 6)
		for s2: float in [-1.0, 1.0]:
			b.torus(Vector3(s2 * 0.42, 0.85, 0), 0.13, 0.03, bronze, Vector3(0, 0, PI * 0.5))
		gl.disc(Vector3(0, 0.76, 0), 0.46, Color(1.0, 0.78, 0.4, 0.45), 16, Color(0.6, 0.9, 1.0, 0.15))
		_halo(gl, Vector3(0, 0.95, 0), 0.5, Color(1.0, 0.8, 0.45, 0.2), 3)
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		MB.mesh_node(root, gl.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cauldrons.append(root)
		_cloud(clouds, root.position + Vector3(0, -0.6, 0), 1.4, 100 + k)
	MB.mesh_node(g, clouds.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the river that runs between them to the sea, every bend of it
	var rv := MB.new()
	var pts: Array = []
	var ws: Array = []
	for k in 21:
		var tt := k / 20.0
		pts.append(Vector3(sin(tt * 8.0) * 1.8 + (tt - 0.5) * 4.0, -1.05 - tt * 0.8, 14.0 - tt * 60.0))
		ws.append(0.7 + tt * 3.5)
	rv.ribbon(pts, ws, Vector3.RIGHT, Color(0.62, 0.84, 1.0, 0.5), Color(0.7, 0.86, 1.0, 0.08))
	MB.mesh_node(g, rv.build(MB.mat_glass())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Part XI: the Jianmu (the crown the world builds over the Nine Heavens) rising out of the sea of
## cloud, lights of every realm climbing it and the six Daos' colours round the trunk
func _build_jianmu() -> void:
	var g := _group("jianmu", AT_JIANMU)
	Terrain3D.jianmu_crown(g, Vector3.ZERO)
	var gl := MB.new()
	for k2 in Data.DAO_ORDER.size():
		var c: Color = Data.DAOS[Data.DAO_ORDER[k2]].col
		var a2 := TAU * k2 / float(Data.DAO_ORDER.size())
		gl.torus(Vector3(0, -8.0 + k2 * 2.6, 0), 15.0 + 0.4 * k2, 0.06, Color(c.r, c.g, c.b, 0.6), Vector3(0.12 * sin(a2), 0, 0.12 * cos(a2)), true)
	dao_rings = MB.mesh_node(g, gl.build(MB.mat_glow()))
	dao_rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# lights climbing the tree: feathers of the Yumin up the crown, pearls and lanterns up the roots
	for k3 in 16:
		var m := MB.new()
		var col: Color = [Color(0.9, 0.95, 1.0, 0.9), Color(0.6, 1.0, 0.95, 0.9), Color(0.75, 0.8, 1.0, 0.9)][k3 % 3]
		m.sph_hi(Vector3.ZERO, Vector3.ONE * 0.45, col)
		_halo(m, Vector3.ZERO, 1.4, Color(col.r, col.g, col.b, 0.5), 3)
		var n := MB.mesh_node(g, m.build(MB.mat_glow()))
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.set_meta("phase", k3 / 16.0)
		climbers11.append(n)

## Part XII: the Isles of the Eastern Sea come up out of the cloud, each on the shell of a sleeping
## turtle with Jingwei's reef of pebbles beside it; Mazu's boat drifts between them with its red
## lantern lit, and Jingwei flies a pebble over them
func _build_isles() -> void:
	var g := _group("isles", AT_ISLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1212
	for k in 3:
		var root := Node3D.new()
		root.position = [Vector3(0.0, 0.0, 0.0), Vector3(18.0, -0.5, -10.0), Vector3(-10.0, -1.0, -26.0)][k]
		root.rotation.y = [0.6, -0.2, 1.0][k]
		g.add_child(root)
		var b := MB.new()
		var gl := MB.new()
		var shell := MB.tag(Color("4f5e3c"), MB.SCALE)
		var skin := MB.tag(Color("7d8a5c"), MB.SKIN)
		# the shell, domed, with a paler rim and plates
		b.sph(Vector3(0, 0.4, 0), Vector3(5.0, 2.0, 5.8), shell)
		b.sph(Vector3(0, -0.1, 0), Vector3(5.4, 0.7, 6.2), MB.tag(Color("6e7a4e"), MB.SCALE))
		for q in 7:
			var qa := TAU * q / 7.0
			b.sph(Vector3(cos(qa) * 3.4, 1.4, sin(qa) * 3.9), Vector3(1.2, 0.5, 1.3), MB.tag(Color("5c6c44"), MB.SCALE))
		# asleep: the head laid on the clouds, the flippers folded
		b.sph(Vector3(0, -0.2, 6.8), Vector3(1.3, 0.95, 1.7), skin)
		for s: float in [-1.0, 1.0]:
			b.sph(Vector3(s * 4.6, -0.5, 3.0), Vector3(2.0, 0.35, 0.9), skin, Vector3(0, s * 0.55, 0))
			b.sph(Vector3(s * 4.2, -0.5, -3.6), Vector3(1.5, 0.3, 0.8), skin, Vector3(0, -s * 0.5, 0))
		# Jingwei's reef: pebbles heaped against the turtle's flank
		for q2 in 16:
			b.ball(Vector3(rng.randf_range(-5.5, -3.0) * (1 if q2 % 2 == 0 else -1), -0.7 + rng.randf() * 0.3, rng.randf_range(-4.0, 4.0)), rng.randf_range(0.3, 0.6), MB.tag([Color("d8c8b0"), Color("c87a5a"), Color("8a8a8a")][q2 % 3], MB.STONE))
		# the isle on its back: a green hill, rocks, two pines and a red pavilion with a lamp
		b.sph(Vector3(0, 2.4, -0.5), Vector3(3.3, 1.5, 3.6), MB.tag(Color("5f9a54"), MB.FOLIAGE))
		b.cone(Vector3(-1.4, 3.2, 0.9), 1.2, 1.9, MB.tag(Color("b8b0a0"), MB.STONE), Vector3.ZERO, 7)
		for pz: float in [-1.0, 1.0]:
			b.cyl(Vector3(1.8 * pz, 3.9, -1.6), 0.12, 1.0, MB.tag(Color("6a4a30"), MB.WOOD), Vector3.ZERO, 6)
			b.cone(Vector3(1.8 * pz, 5.0, -1.6), 0.9, 1.8, MB.tag(Color("2f6a4a"), MB.FOLIAGE), Vector3.ZERO, 8)
		b.cyl(Vector3(0.4, 4.2, 0.2), 0.75, 1.2, MB.tag(Color("b8382a"), MB.WOOD), Vector3.ZERO, 8)
		b.cone(Vector3(0.4, 5.2, 0.2), 1.35, 0.9, MB.tag(Color("2f4a6a"), MB.STONE), Vector3.ZERO, 8)
		_halo(gl, Vector3(0.4, 4.3, 1.0), 0.45, Color(1.0, 0.62, 0.32, 0.8), 3)
		MB.mesh_node(root, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		MB.mesh_node(root, gl.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		isles12.append(root)
	boat12 = Models.mazu_boat()
	boat12.scale = Vector3.ONE * 0.8
	g.add_child(boat12)
	if Assets.PEOPLE.has("mazu") and Assets.has(Assets.PEOPLE["mazu"]):
		mazu12 = Assets.person("mazu")
		mazu12.scale = Vector3.ONE * 0.7
		boat12.add_child(mazu12)
		mazu12.position = Vector3(2.0, 0.65, -0.6)
	var bb := MB.new()
	bb.sph(Vector3.ZERO, Vector3(0.18, 0.14, 0.32), MB.tag(Color("5a504a"), MB.CLOTH))
	bb.ball(Vector3(0, 0.08, 0.3), 0.1, MB.tag(Color("f0ece4"), MB.CLOTH))
	bb.cone(Vector3(0, 0.08, 0.44), 0.04, 0.12, MB.tag(Color("f0f0e8"), MB.STONE), Vector3(PI / 2, 0, 0), 6)
	for s2: float in [-1.0, 1.0]:
		bb.leaf(Vector3(s2 * 0.1, 0.05, 0.0), Vector3(s2 * 0.75, 0.25, -0.1), 0.22, MB.tag(Color("6a5a52"), MB.CLOTH))
	bb.ball(Vector3(0, -0.18, 0.2), 0.07, MB.tag(Color("c87a5a"), MB.STONE))
	bird12 = Node3D.new()
	MB.mesh_node(bird12, bb.build(MB.mat_plain()))
	bird12.scale = Vector3.ONE * 2.0
	g.add_child(bird12)

## Part XIII: the Eight Gates of Qimen in a ring on the clouds, every one of them open, each with the
## trigram of its quarter glowing over the arch; red maple leaves (Chiyou's fetters, let go)
## blowing through them
func _build_gates() -> void:
	var g := _group("gates", AT_GATES)
	gates13 = Node3D.new()
	g.add_child(gates13)
	var b := MB.new()
	var gl := MB.new()
	var cb := MB.new()
	var wood := MB.tag(Color("b8382a"), MB.WOOD)
	var tile := MB.tag(Color("2f4a6a"), MB.STONE)
	var gold := Color(1.0, 0.82, 0.4, 0.95)
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0
		var c := Vector3(cos(a) * 17.0, 0.0, sin(a) * 17.0)
		# every gate faces the centre, where the war god used to be
		var yaw := atan2(-c.x, -c.z)
		var bs := Basis.from_euler(Vector3(0, yaw, 0))
		var right: Vector3 = bs * Vector3(1, 0, 0)
		var front: Vector3 = bs * Vector3(0, 0, 1)
		for sd: float in [-1.0, 1.0]:
			b.cyl(c + right * sd * 1.7 + Vector3(0, 2.1, 0), 0.24, 4.2, wood, Vector3.ZERO, 8)
			b.box(c + right * sd * 1.7 + Vector3(0, 0.15, 0), Vector3(0.7, 0.3, 0.7), tile, Vector3(0, yaw, 0))
		b.box(c + Vector3(0, 4.25, 0), Vector3(4.4, 0.36, 0.5), wood, Vector3(0, yaw, 0))
		b.box(c + Vector3(0, 4.7, 0), Vector3(5.2, 0.28, 1.0), tile, Vector3(0, yaw, 0))
		b.box(c + Vector3(0, 3.45, 0), Vector3(2.0, 1.1, 0.12), MB.tag(Color("3a2a22"), MB.WOOD), Vector3(0, yaw, 0))
		var tri: Array = TRIGRAMS[k]
		for ln in 3:
			var y := 3.1 + ln * 0.32
			for fb: float in [1.0, -1.0]:
				var at: Vector3 = c + Vector3(0, y, 0) + front * 0.1 * fb
				if int(tri[ln]) == 1:
					gl.box(at, Vector3(1.5, 0.14, 0.06), gold, Vector3(0, yaw, 0))
				else:
					for sd2: float in [-1.0, 1.0]:
						gl.box(at + right * sd2 * 0.45, Vector3(0.6, 0.14, 0.06), gold, Vector3(0, yaw, 0))
		# a pool of gold light where the gate opens
		gl.disc(c + Vector3(0, 0.08, 0) + front * 1.2, 1.5, Color(1.0, 0.8, 0.35, 0.35), 16)
		_cloud(cb, c + Vector3(0, -0.4, 0) - front * 0.6, 2.2, 1300 + k)
	# where the war god stood: a calm pool of light
	gl.disc(Vector3(0, 0.1, 0), 5.0, Color(1.0, 0.85, 0.5, 0.22), 32, Color(1.0, 0.8, 0.4, 0.0))
	MB.mesh_node(gates13, b.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(gates13, cb.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(gates13, gl.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lb := MB.new()
	lb.leaf(Vector3.ZERO, Vector3(0, 0, 0.3), 0.22, MB.tag(Color("c8402a"), MB.FOLIAGE), Vector3(1, 0, 0), MB.tag(Color("e89030"), MB.FOLIAGE))
	var lm := lb.build(MB.mat_plain())
	for q in 26:
		var lf := MB.mesh_node(g, lm)
		lf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lf.scale = Vector3.ONE * 2.2
		lf.set_meta("phase", q * 0.37)
		leaves13.append(lf)

## Part V, VI and VII: the Wheel of the Six Paths turning again inside Nuwa's five rings, soul
## lanterns rising past it, Lin Feng's parents walking up a road of light out of the clouds to it,
## the Loom's loose threads drifting down, Hundun asleep in the clouds with his wings folded, and
## two of the four mended pillars holding up the sky behind it
func _build_wheel() -> void:
	var g := _group("wheel", AT_WHEEL)
	wheel = Node3D.new()
	g.add_child(wheel)
	var wb := MB.new()
	var wg := MB.new()
	var stone := MB.tag(Color("eadff0"), MB.STONE)
	var rad := 15.0
	for i in 48:
		var a0 := TAU * i / 48.0
		var a1 := TAU * (i + 1) / 48.0
		wb.limb(Vector3(cos(a0), sin(a0), 0) * rad, Vector3(cos(a1), sin(a1), 0) * rad, 0.6, 0.6, stone, 8)
	for k in 6:
		var ak := TAU * k / 6.0
		var c6: Color = Fx3D.SIX[k]
		wb.limb(Vector3.ZERO, Vector3(cos(ak), sin(ak), 0) * rad, 0.38, 0.26, stone, 8)
		var at := Vector3(cos(ak), sin(ak), 0) * rad
		wg.sph_hi(at, Vector3.ONE * 0.9, Color(c6.r, c6.g, c6.b, 0.9))
		_halo(wg, at, 2.6, Color(c6.r, c6.g, c6.b, 0.6), 3)
	wb.cyl(Vector3.ZERO, 2.0, 1.4, stone, Vector3(PI * 0.5, 0, 0), 16)
	_halo(wg, Vector3.ZERO, 5.0, Color(1.0, 0.92, 0.75, 0.7), 4)
	MB.mesh_node(wheel, wb.build(MB.mat_vc())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(wheel, wg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Nuwa's five colours, turning slowly round the wheel like the rings of an armillary sphere
	for k in 5:
		var rb := MB.new()
		var c: Color = Fx3D.FIVE[k]
		rb.arc(Vector3.ZERO, rad + 2.6 + k * 1.2, 0.16, 0.0, TAU, Color(c.r, c.g, c.b, 0.55), 128)
		var rm := MB.mesh_node(g, rb.build(MB.mat_glow()))
		rm.rotation = Vector3(PI * 0.5 + 0.35 * sin(k * 1.7), k * 0.6, 0.0)
		rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rings.append(rm)
	var lanterns := Fx3D.make_weather()
	g.add_child(lanterns)
	Fx3D.configure_weather(lanterns, "lily_souls")
	lanterns.position = Vector3(0, -24.0, 14.0)
	# Lin Shan and Su Wan, hand in hand, walking up a path of light out of the clouds to the wheel
	var road := MB.new()
	for i in 40:
		var tt := i / 39.0
		road.box(_road(tt), Vector3(1.5, 0.06, 1.5), Color(1.0, 0.88, 0.58, 0.45 * (1.0 - tt * 0.6)), Vector3(0, 0.3, 0))
	MB.mesh_node(g, road.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 2:
		var pid := "lin_shan" if k == 0 else "su_wan"
		var pm2 := Models.person(Color("7a7a70") if k == 0 else Color("6aa88a"), Color("1a1a2a"), {"asset": pid, "glow": Color(1.0, 0.9, 0.7)})
		g.add_child(pm2)
		parents.append(pm2)
	# the Loom's loose threads, drifting down through the evening
	threads = Node3D.new()
	g.add_child(threads)
	var tb := MB.new()
	var rt := RandomNumberGenerator.new()
	rt.seed = 77
	for i in 10:
		var base2 := Vector3(rt.randf_range(-40, 40), rt.randf_range(6, 30), rt.randf_range(-30, -6))
		var tp: Array = []
		var wid: Array = []
		for k in 8:
			tp.append(base2 + Vector3(sin(k * 0.8 + i) * 0.6, -k * 1.4, cos(k * 0.6 + i) * 0.3))
			wid.append(0.04 * (1.0 - k / 8.0) + 0.01)
		tb.ribbon(tp, wid, Vector3.RIGHT, Color(0.94, 0.94, 1.0, 0.22), Color(0.9, 0.8, 1.0, 0.0))
	MB.mesh_node(threads, tb.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hundun = Models.monster("hundun", Color("e05030"), false)
	hundun.position = Vector3(-40.0, -24.0, -10.0)
	hundun.scale = Vector3.ONE * 3.2
	hundun.rotation.y = 1.1
	g.add_child(hundun)
	# two of the four pillars, mended, holding up the sky at the edge of the world either side of it
	var pb := MB.new()
	var pg := MB.new()
	for pp in [Vector3(-157.0, -40.0, -177.0), Vector3(40.0, -40.0, -233.0)]:
		_pillar(pb, pg, pp)
	MB.mesh_node(g, pb.build(MB.mat_plain())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MB.mesh_node(g, pg.build(MB.mat_glow())).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## one of Nuwa's pillars (Part V), mended: a column of pale stone going up out of sight, banded in
## the five colours of the stones she melted to patch the sky
static func _pillar(b: MB, g: MB, p: Vector3) -> void:
	var stone := Color("e8c8bc")
	var five := [Color("ff5050"), Color("ffd040"), Color("50a0ff"), Color("f0f0ff"), Color("b070ff")]
	var rad := 9.0
	b.lathe(p, [Vector2(rad * 1.8, 0.0), Vector2(rad * 1.3, 6.0), Vector2(rad, 12.0), Vector2(rad * 0.95, 420.0)], MB.tag(stone, MB.STONE), 16)
	for k in 9:
		var y := 30.0 + k * 34.0
		var c: Color = five[k % 5]
		b.cyl(p + Vector3(0, y, 0), rad * 1.06, 3.0, MB.tag(stone.darkened(0.18), MB.STONE), Vector3.ZERO, 16)
		b.cyl(p + Vector3(0, y, 0), rad * 1.08, 1.4, MB.tag(c.lerp(stone, 0.35), MB.STONE), Vector3.ZERO, 16)
		g.cyl(p + Vector3(0, y, 0), rad * 1.1, 0.5, Color(c.r, c.g, c.b, 0.45), Vector3.ZERO, 16)

## where the road of light runs, in the wheel's own space: from the clouds up to the foot of the
## wheel (0..1)
static func _road(tt: float) -> Vector3:
	return Vector3(16.0, -26.0, 64.0).lerp(Vector3(0.0, -15.0, 2.0), tt)

func press(act: String) -> void:
	if act != "confirm" and act != "cancel":
		return
	if t < 0.8:
		return
	var tf := film_length()
	if t < tf - 0.3:
		# skip the film: straight to the lotus and the results
		t = tf - 0.3
		return
	if t < tf + 0.6:
		return
	done = true
	main.game_finished_ack()

func _process(d: float) -> void:
	if not visible:
		return
	t += d
	if headless():
		return
	if not built:
		_build_world()
	var sa := shot_at(t)
	var i: int = sa[0]
	var u: float = sa[1]
	if i != shot_on:
		shot_on = i
		var show: Array = FILM[i].show
		for k in groups:
			(groups[k] as Node3D).visible = k == "sea" or show.has(k)
		cam.environment.fog_density = float(FILM[i].fog)
		dao_rings.visible = str(FILM[i].id) == "jianmu"
	_animate(u)
	_camera(i, u)
	# the world's see-through scenery (the Jianmu's crown) thins out between the camera and the hero:
	# here there is no hero to keep in view, so the point it would look for lies behind the camera
	RenderingServer.global_shader_parameter_set("hero_pos", cam.global_position + cam.global_transform.basis.z * 5000.0)
	queue_redraw()

## everything that moves, in the set pieces on screen
func _animate(u: float) -> void:
	if groups.hero.visible:
		lot.rotation.y = -t * 0.1
		lot.position.y = sin(t * 0.9) * 0.05
		Models.anim_person(hero, t, false, false)
		Models.anim_person(comp, t + 2.0, false, false)
		hero.position.y = 0.3 + lot.position.y
		comp.position.y = 0.3 + lot.position.y
		for k in souls.size():
			(souls[k] as Node3D).position.y = 1.55 + k * 0.12 + sin(t * 1.3 + k * 2.1) * 0.1
		# Yue Ling takes her turn to wave, bow and laugh at everyone below
		var gk := int(t / 5.0)
		if gk != int(comp.get_meta("gk", -1)):
			comp.set_meta("gk", gk)
			if gk > 0:
				Models.act(comp, ["wave", "bow", "laugh", "offer"][gk % 4], t + 2.0)
	if groups.wheel.visible:
		wheel.rotation.z = t * 0.08
		for k in rings.size():
			(rings[k] as Node3D).rotation.y = k * 0.6 + t * (0.04 + k * 0.01) * (1 if k % 2 == 0 else -1)
		for k in parents.size():
			var pp: Node3D = parents[k]
			var walk := 0.18 + u * 0.012
			var to_wheel := _road(1.0) - _road(0.0)
			pp.position = _road(walk) + Vector3(k * 0.7 - 0.35, 0.05, 0)
			pp.rotation.y = atan2(to_wheel.x, to_wheel.z)
			Models.anim_person(pp, t + k * 0.4, true)
		threads.position.y = -fmod(t * 0.8, 8.0)
		Models.anim_monster(hundun, t * 0.5, 0.0)
	if groups.bridge.visible:
		# the lovers walk up from either end and meet at the crown while we watch
		var meet := smoothstep(0.3, 6.0, u)
		for k in lovers.size():
			var lv: Node3D = lovers[k]
			var s := -1.0 if k == 0 else 1.0
			var x := s * lerpf(3.6, 0.22, meet)
			lv.position = Vector3(x, 1.5 * (1.0 - pow(absf(x) / 4.2, 1.7)) + 0.08, 0.0)
			Models.anim_person(lv, t + k, meet < 1.0)
		var turn := sin(t * 0.25)
		sun9.position = Vector3(-30.0, 15.0 + turn * 1.5, -48.0)
		moon9.position = Vector3(26.0, 14.0 - turn * 1.5, -48.0)
		var fly := Vector3(-17.0 + sin(t * 0.7) * 0.5, 10.0 + turn * 1.5 + sin(t * 1.1) * 0.3, -30.0)
		xihe9.position = fly
		crow9.position = fly + Vector3(2.0, 0.7 + sin(t * 1.7) * 0.2, 0.5)
		Models.anim_monster(xihe9, t, 0.0)
		Models.anim_monster(crow9, t + 0.7, 0.0)
		change9.position.y = 5.0 + sin(t * 0.8) * 0.15
		Models.anim_person(change9.get_meta("person"), t + 3.0, false)
	if groups.cauldrons.visible:
		for k in cauldrons.size():
			(cauldrons[k] as Node3D).rotation.y = t * 0.12 + k
	if groups.jianmu.visible:
		for k in climbers11.size():
			var cn: Node3D = climbers11[k]
			var f := fmod(t * 0.03 + float(cn.get_meta("phase")), 1.0)
			var ca := f * TAU * 3.0 + k
			cn.position = Vector3(cos(ca) * 7.0, -10.0 + f * 46.0, sin(ca) * 7.0)
	if groups.isles.visible:
		for k in isles12.size():
			(isles12[k] as Node3D).position.y = -k * 0.5 + sin(t * 0.4 + k * 1.7) * 0.15
		var bt := t * 0.06
		boat12.position = Vector3(6.0 + sin(bt) * 4.0, 0.2, -12.0 + cos(bt) * 3.0)
		boat12.rotation.y = -bt + PI * 0.5
		if mazu12 != null:
			Models.anim_person(mazu12, t + 4.0, false)
			if fmod(t, 9.0) < 0.05:
				Models.act(mazu12, "wave", t + 4.0)
		var ba := t * 0.35
		bird12.position = Vector3(4.0 + cos(ba) * 9.0, 9.0 + sin(t * 1.3) * 0.6, -10.0 + sin(ba) * 7.0)
		bird12.rotation.y = -ba
	if groups.gates.visible:
		gates13.rotation.y = sin(t * 0.05) * 0.06
		for k in leaves13.size():
			var lf: Node3D = leaves13[k]
			var ph := float(lf.get_meta("phase"))
			var fall := fmod(t * 0.1 + ph, 1.0)
			lf.position = Vector3(sin(ph * 7.0) * 18.0 + sin(t * 0.7 + ph) * 1.5, 14.0 - fall * 15.0, cos(ph * 5.0) * 16.0 + 6.0)
			lf.rotation = Vector3(t * 1.3 + ph, t * 0.9 + ph * 2.0, 0.0)

## where the camera is in shot `i`, `u` seconds in: each shot drifts slowly from one framing to the
## next; the last pushes in on the lotus and then draws back to rest beside the results
func _camera(i: int, u: float) -> void:
	var s: Dictionary = FILM[i]
	var dur := float(s.dur)
	var k := smoothstep(0.0, 1.0, clampf(u / dur, 0.0, 1.0))
	var eye := Vector3.ZERO
	var look := Vector3.FORWARD
	match str(s.id):
		"bridge":
			eye = AT_BRIDGE + Vector3(-2.0, 3.0, 31.0).lerp(Vector3(1.0, 3.8, 24.0), k)
			look = AT_BRIDGE + Vector3(0.0, 7.5, -10.0)
		"cauldrons":
			eye = AT_CAULDRONS + Vector3(-6.0, 4.6, 16.5).lerp(Vector3(-1.5, 3.7, 13.0), k)
			look = AT_CAULDRONS + Vector3(0.5, 0.6, -4.0)
		"jianmu":
			eye = AT_JIANMU + Vector3(46.0, 0.0, 150.0).lerp(Vector3(26.0, 14.0, 138.0), k)
			look = AT_JIANMU + Vector3(0.0, lerpf(10.0, 30.0, k), 0.0)
		"isles":
			eye = AT_ISLES + Vector3(-28.0, 10.0, 30.0).lerp(Vector3(-22.0, 8.0, 25.0), k)
			look = AT_ISLES + Vector3(4.0, 0.5, -10.0)
		"gates":
			eye = AT_GATES + Vector3(33.0, 7.5, 36.0).lerp(Vector3(25.0, 6.0, 28.0), k)
			look = AT_GATES + Vector3(-6.0, 5.0, -8.0)
		"wheel":
			eye = AT_WHEEL + Vector3(24.0, -21.0, 84.0).lerp(Vector3(21.0, -21.5, 76.0), k)
			look = AT_WHEEL + Vector3(0.0, lerpf(-12.5, -11.5, k), 0.0)
		"hero":
			var close_eye := Vector3(0.35, 1.3, 3.9)
			var close_look := Vector3(0.0, 1.05, 0.0)
			var push := smoothstep(0.0, 0.45, u / dur)
			var back := smoothstep(0.35, 1.0, u / dur)
			eye = close_eye.lerp(close_eye + Vector3(-0.1, -0.05, -0.6), push).lerp(REST_EYE, back)
			look = close_look.lerp(REST_LOOK, back)
			# while the results are read the camera keeps drifting, very gently
			var drift := maxf(0.0, u - dur)
			eye += Vector3(sin(drift * 0.11) * 0.25, sin(drift * 0.08) * 0.08, 0.0)
	cam.position = eye
	cam.look_at(look, Vector3.UP)

# ---------------------------------------------------------------- overlay

## a line of text that fades (its shadow fades with it)
func _say(p: Vector2, s: String, size: int, col: Color, a: float, align: int = HORIZONTAL_ALIGNMENT_CENTER, w: float = -1.0) -> void:
	if a <= 0.0:
		return
	var f := UI.font()
	# (the name the player chose, character creation)
	s = UI.named(s)
	draw_string(f, p + Vector2(1.5, 2.0), s, align, w, size, Color(0, 0, 0, 0.75 * a))
	draw_string(f, p, s, align, w, size, Color(col.r, col.g, col.b, col.a * a))

## widely spaced capitals, centred on `c` (captions, headings, the title)
func _caps(c: Vector2, s: String, size: int, col: Color, a: float, spacing: float, shadow: float = 0.7) -> void:
	if a <= 0.0:
		return
	var f := UI.font()
	var w := -spacing
	for ch in s:
		w += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + spacing
	var x := c.x - w * 0.5
	for ch in s:
		var cw := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if shadow > 0.0:
			draw_string(f, Vector2(x + 1.5, c.y + 2.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, shadow * a))
		draw_string(f, Vector2(x, c.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col.r, col.g, col.b, col.a * a))
		x += cw + spacing

## a thin gold rule fading out at both ends, with a diamond in the middle
func _rule(c: Vector2, half: float, a: float) -> void:
	var col := Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, 0.9 * a)
	Gfx.hgrad(self, Rect2(c.x - half, c.y - 0.6, half - 9.0, 1.3), Color(col.r, col.g, col.b, 0.0), col)
	Gfx.hgrad(self, Rect2(c.x + 9.0, c.y - 0.6, half - 9.0, 1.3), col, Color(col.r, col.g, col.b, 0.0))
	Gfx.diamond(self, c, 5.0, col)

func _draw() -> void:
	var tf := film_length()
	var sa := shot_at(t)
	var i: int = sa[0]
	var u: float = sa[1]
	var card := smoothstep(tf - 0.4, tf + 1.2, t)
	# the film's bars close in at the start and draw back when the results come up
	var bar := BAR * smoothstep(0.0, 1.2, t) * (1.0 - smoothstep(tf - 1.0, tf + 0.4, t))
	if card < 1.0:
		var va := 0.28 * (1.0 - card)
		Gfx.hgrad(self, Rect2(0, 0, 220, VIEW.y), Color(0.02, 0.01, 0.04, va), Color(0.02, 0.01, 0.04, 0.0))
		Gfx.hgrad(self, Rect2(VIEW.x - 220, 0, 220, VIEW.y), Color(0.02, 0.01, 0.04, 0.0), Color(0.02, 0.01, 0.04, va))
		_subtitle(i, u)
	if card > 0.0:
		_card(card)
	if bar > 0.5:
		draw_rect(Rect2(0, 0, VIEW.x, bar), Color(0, 0, 0))
		draw_rect(Rect2(0, VIEW.y - bar, VIEW.x, bar), Color(0, 0, 0))
		var ha := smoothstep(2.0, 3.0, t) * (1.0 - smoothstep(tf - 1.5, tf - 0.8, t))
		_say(Vector2(0, VIEW.y - bar * 0.5 + 5.0), "Enter: skip", 12, UI.C_DIM, ha * 0.8, HORIZONTAL_ALIGNMENT_RIGHT, VIEW.x - 24.0)
	# a dip to dark at every cut, and the light the film opens out of
	var dip := 0.0
	var t0 := 0.0
	for k in FILM.size() - 1:
		t0 += float(FILM[k].dur)
		dip = maxf(dip, 1.0 - clampf(absf(t - t0) / DIP, 0.0, 1.0))
	if dip > 0.0:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.02, 0.01, 0.03, dip))
	var dawn := 1.0 - smoothstep(0.0, 1.4, t)
	if dawn > 0.0:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(1.0, 0.96, 0.86, dawn))

## the shot's place in gold capitals and its line of the epilogue, low in the frame
func _subtitle(i: int, u: float) -> void:
	var s: Dictionary = FILM[i] if i < FILM.size() - 1 else hero_shot()
	var dur := float(s.dur)
	var a := smoothstep(0.6, 1.3, u) * (1.0 - smoothstep(dur - 0.9, dur - 0.4, u))
	if i == FILM.size() - 1:
		# the last line gives way to the results while the camera draws back
		a = smoothstep(0.6, 1.3, u) * (1.0 - smoothstep(dur * 0.4, dur * 0.55, u))
	if a <= 0.0:
		return
	Gfx.vgrad(self, Rect2(0, VIEW.y - BAR - 170, VIEW.x, 170), Color(0, 0, 0, 0), Color(0, 0, 0, 0.5 * a))
	var lines := UI.wrap_lines(str(s.line), 23, 940.0)
	var y := VIEW.y - BAR - 26.0 - (lines.size() - 1) * 31.0
	_caps(Vector2(VIEW.x * 0.5, y - 44.0), str(s.place).to_upper(), 13, UI.C_GOLD, a, 4.0)
	_rule(Vector2(VIEW.x * 0.5, y - 31.0), 110.0, a)
	for ln in lines:
		_say(Vector2(0, y), ln, 23, UI.C_TEXT, a, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
		y += 31.0

## the results: the title and the name the climb earned him over the two of them, how the war god's
## story ended at their feet, and the annals of the climb beside them
func _card(a: float) -> void:
	var tf := film_length()
	var e := 1.0 - pow(1.0 - a, 3.0)
	# shade the frame softly: the top for the title, the foot for the last words, the right for the annals
	Gfx.vgrad(self, Rect2(0, 0, VIEW.x, 200), Color(0.02, 0.01, 0.05, 0.42 * a), Color(0.02, 0.01, 0.05, 0.0))
	Gfx.vgrad(self, Rect2(0, VIEW.y - 170, VIEW.x, 170), Color(0.02, 0.01, 0.05, 0.0), Color(0.02, 0.01, 0.05, 0.5 * a))
	Gfx.hgrad(self, Rect2(VIEW.x * 0.5, 0, VIEW.x * 0.5, VIEW.y), Color(0.02, 0.02, 0.06, 0.0), Color(0.02, 0.02, 0.06, 0.4 * a))
	var lc := 400.0
	var ta := smoothstep(tf - 0.2, tf + 1.0, t)
	_caps(Vector2(lc, 96.0), "ASCENSION", 58, Color("ffe6a0").lerp(Color("fff6d8"), 0.5 + 0.5 * sin(t * 1.2)), ta, 14.0, 0.85)
	var fav := Trials.favourite_kind(Game)
	var who := "Lin Feng, %s" % str(Trials.EPITHETS.get(fav, "")) if Trials.EPITHETS.has(fav) else "Lin Feng of the Azure Cloud"
	var ncol: Color = Trials.KINDS[fav].col if fav != "" else UI.C_GOLD
	_say(Vector2(lc - 380.0, 138.0), who, 22, ncol.lerp(Color.WHITE, 0.3), ta, HORIZONTAL_ALIGNMENT_CENTER, 760.0)
	_rule(Vector2(lc, 158.0), 210.0, ta)
	# the end the player chose for the hero's own fire (cultures.gd ENDINGS)
	var en: Dictionary = Cultures.ENDINGS[Cultures.ending_of(Game)]
	_caps(Vector2(lc, 184.0), str(en.n).to_upper(), 15, Color("ffd9a0").lerp(Color(en.sky), 0.5), ta, 5.0)
	_say(Vector2(lc - 380.0, 208.0), str(en.sub), 16, Color("f4ecd8"), ta, HORIZONTAL_ALIGNMENT_CENTER, 760.0)
	# how the war god's story ended, at the foot of the frame
	var road := str(Game.trials.get("chiyou", ""))
	if ROAD_ENDS.has(road):
		var qa := smoothstep(tf + 0.6, tf + 1.8, t)
		var ql := UI.wrap_lines(str(ROAD_ENDS[road][1]), 19, 640.0)
		var qy := VIEW.y - 44.0 - (ql.size() - 1) * 26.0
		for ln in ql:
			_say(Vector2(lc - 380.0, qy), ln, 19, Color("f4ecd8"), qa, HORIZONTAL_ALIGNMENT_CENTER, 760.0)
			qy += 26.0
	_results(a, (1.0 - e) * 70.0)

func _results(a: float, slide: float) -> void:
	var tf := film_length()
	var r := Rect2(806.0 + slide, 44.0, 434.0, 632.0)
	UI.panel(self, r, Color(0.035, 0.05, 0.11, 0.88 * a), Color(UI.C_BORDER.r, UI.C_BORDER.g, UI.C_BORDER.b, a))
	var x0 := r.position.x + 30.0
	var w := r.size.x - 60.0
	var cx := r.position.x + r.size.x * 0.5
	var y := r.position.y + 38.0
	var n := smoothstep(tf + 0.3, tf + 2.0, t)
	_caps(Vector2(cx, y), UI.named("The Annals of Lin Feng").to_upper(), 12, UI.C_GOLD.darkened(0.1), a, 3.5)
	y += 32.0
	_say(Vector2(x0, y), "Total play time", 14, UI.C_DIM, a, HORIZONTAL_ALIGNMENT_CENTER, w)
	y += 44.0
	_say(Vector2(x0, y), Fmt.clock(Game.playtime), 42, UI.C_GOLD, a, HORIZONTAL_ALIGNMENT_CENTER, w)
	y += 32.0
	_say(Vector2(x0, y), Data.level_name(Game.level), 20, UI.C_TEXT, a, HORIZONTAL_ALIGNMENT_CENTER, w)
	if Game.dao != "":
		y += 24.0
		var dl := "Walker of the %s" % Data.DAOS[Game.dao].n
		_say(Vector2(x0, y), dl, UI.fit(dl, 15, w), Data.DAOS[Game.dao].col, a, HORIZONTAL_ALIGNMENT_CENTER, w)
	y += 21.0
	_say(Vector2(x0, y), "The Nine Heavens root: %d ranks awake" % Game.talent_ranks(), 13, UI.C_DIM, a, HORIZONTAL_ALIGNMENT_CENTER, w)
	y += 20.0
	_rule(Vector2(cx, y), w * 0.5, a)
	# the climb in numbers
	var cells := [
		["FOES DEFEATED", Trials._num(int(round(Game.kills * n))), UI.C_TEXT],
		["BATTLES", Trials._num(int(round(Game.battles * n))), UI.C_TEXT],
		["FALLS", str(Game.deaths), UI.C_TEXT],
		["IN MEDITATION", Fmt.clock(Game.meditated * n), UI.C_TEXT],
		["RENOWN", "%s  %s" % [Trials._num(int(round(Game.renown * n))), Game.renown_title()], Trials.KINDS.respect.col],
		["DEEDS DONE", "%d of %d" % [Game.deeds.size(), Trials.DEEDS.size()], UI.C_TEXT],
	]
	y += 30.0
	for k in cells.size():
		var col := k % 2
		var cy := y + (k / 2) * 46.0
		var cc := x0 + w * (0.25 + 0.5 * col)
		_caps(Vector2(cc, cy), str(cells[k][0]), 11, UI.C_DIM, a, 2.0, 0.5)
		var vs := str(cells[k][1])
		_say(Vector2(x0 + w * 0.5 * col, cy + 25.0), vs, UI.fit(vs, 21, w * 0.5 - 8.0, 14), cells[k][2], a, HORIZONTAL_ALIGNMENT_CENTER, w * 0.5)
	y += 138.0
	_rule(Vector2(cx, y - 8.0), w * 0.5, a)
	# the roads taken through the trials: a bar of the ways, coloured by kind
	var counts := {}
	var total := 0
	for tid in Game.trials:
		var p := Trials.path(str(tid), str(Game.trials[tid]))
		if p.is_empty():
			continue
		counts[p.kind] = int(counts.get(p.kind, 0)) + 1
		total += 1
	y += 18.0
	_caps(Vector2(cx, y), "THE ROADS TAKEN", 12, UI.C_GOLD.darkened(0.1), a, 3.5)
	y += 24.0
	var sub := "%d trials passed  ·  %d of the Eight Gates opened" % [total, Game.gates_open.size()]
	_say(Vector2(x0, y), sub, UI.fit(sub, 15, w), UI.C_TEXT, a, HORIZONTAL_ALIGNMENT_CENTER, w)
	y += 14.0
	if total > 0:
		var bx := x0
		draw_rect(Rect2(x0 - 1, y - 1, w + 2, 14), Color(0, 0, 0, 0.5 * a))
		var grow := smoothstep(tf + 0.5, tf + 2.2, t)
		for kd in Trials.KIND_ORDER:
			var cnt := int(counts.get(kd, 0))
			if cnt == 0:
				continue
			var sw := w * cnt / float(total)
			var kc: Color = Trials.KINDS[kd].col
			Gfx.vgrad(self, Rect2(bx, y, maxf(1.0, (sw - 2.0) * grow), 12), Color(kc.r, kc.g, kc.b, a).lightened(0.15), Color(kc.r, kc.g, kc.b, a).darkened(0.15))
			bx += sw
		y += 32.0
		# the legend, flowing over as many rows as it needs
		var lx := x0
		var f := UI.font()
		for kd in Trials.KIND_ORDER:
			var cnt := int(counts.get(kd, 0))
			if cnt == 0:
				continue
			var lab := "%s %d" % [KIND_WORD[kd], cnt]
			var lw := f.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 30.0
			if lx + lw > x0 + w + 4.0:
				lx = x0
				y += 20.0
			var kc: Color = Trials.KINDS[kd].col
			draw_rect(Rect2(lx, y - 10, 10, 10), Color(kc.r, kc.g, kc.b, a))
			_say(Vector2(lx + 15.0, y), lab, 14, UI.C_TEXT, a, HORIZONTAL_ALIGNMENT_LEFT)
			lx += lw
	var road := str(Game.trials.get("chiyou", ""))
	if ROAD_ENDS.has(road):
		y += 24.0
		var rl := "The heart reached by %s" % ROAD_ENDS[road][0]
		_say(Vector2(x0, y), rl, UI.fit(rl, 15, w), Color("e8dcc0"), a, HORIZONTAL_ALIGNMENT_CENTER, w)
	# the five fated encounters (fate.gd): how many stand with him at the end
	var fallen := 0
	for th in Fate.THREAD_ORDER:
		if Fate.state(Game, th) in Fate.GONE:
			fallen += 1
	y += 21.0
	var fl := "Of the five he met on the road: %d stand with him%s" % [Fate.allies(Game), (", %d fallen" % fallen) if fallen > 0 else ""]
	# (the results are about nobody but the hero: told of her when she is one, voice.gd)
	if Game.fem():
		fl = Voice.her(fl)
	_say(Vector2(x0, y), fl, UI.fit(fl, 14, w), Trials.KINDS.bond.col, a, HORIZONTAL_ALIGNMENT_CENTER, w)
	# and the grudges that stayed where their owners fell (grudges.gd)
	if not Game.grudges.is_empty():
		y += 18.0
		var up := Grudges.unpaid(Game)
		var gl := "Of the six grudges that stayed: %d laid to rest%s" % [Grudges.settled(Game), (", %d left to the Wheel" % up) if up > 0 else ""]
		_say(Vector2(x0, y), gl, UI.fit(gl, 14, w), UI.C_RED.lightened(0.4), a, HORIZONTAL_ALIGNMENT_CENTER, w)
	# and Yue Ling (bonds.gd, the Lotus release): the road she chose, and how close the two of them came
	if Game.future != "" or Game.bond > 0:
		y += 18.0
		var fut: Dictionary = Bonds.FUTURES.get(Game.future, {})
		var yl := "Yue Ling: %s%s" % [Bonds.title(Game), ("; " + str(fut.get("short", fut.n))) if not fut.is_empty() else ""]
		if Game.fem():
			yl = Voice.her(yl)
		_say(Vector2(x0, y), yl, UI.fit(yl, 14, w), Color("ff9ac0"), a, HORIZONTAL_ALIGNMENT_CENTER, w)
	var pa := smoothstep(tf + 2.0, tf + 2.6, t) * (0.65 + 0.35 * sin(t * 2.4))
	_say(Vector2(x0, maxf(r.end.y - 14.0, y + 24.0)), "Press Enter", 13, UI.C_DIM, a * pa, HORIZONTAL_ALIGNMENT_CENTER, w)
