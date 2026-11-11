extends ScreenBase
## The field of war (the Thundering Pots release): a field battle of war.gd, fought by drums and seen
## from a hill.  The host stands on the left under its companies' colours (a figure for every five
## men: foot in front, bows behind them, horse on the flank, the drums at the back with the banner,
## the hero and Yue Ling), the other host on the right; every figure is built from code (MB) and
## drawn by the hundred (a MultiMesh for each company).  Each drum the scouts' word is shown, an order
## is chosen from the list, and both hosts do what they were told: blocks go forward and come back,
## arrows go over, the horse sweeps round, rings of sound go out from the drums, and the fallen are
## gone from the ranks.
##
## The rules are all in war.gd (`War.step`); this screen only shows them and takes the order.  The bot
## plays it through the same list (`labels`, `ids`, `enabled`, `cursor`, `press`).

const VIEW := Vector2(1280, 720)
## men to a figure, the gap between figures, how long a drum takes to play out
const PER := 5
const GAP := 0.95
const RESOLVE := 2.8

var st := {}
var ctx := {}
var state := "idle"
var timer := 0.0
var labels: Array = []
var ids: Array = []
var enabled: Array = []
var cursor := 0
var given := {}
var theme := "millet"
## what was sounded last drum (the music follows it)
var sang := false

var root: Node3D = null
var sun: DirectionalLight3D
var fill: DirectionalLight3D
## [{"mm": MultiMeshInstance3D, "side", "arm", "n", "base": [Vector3], "home": Vector3, "id"}]
var blocks: Array = []
var hero: Node3D = null
var comp: Node3D = null
var arrows: MultiMeshInstance3D = null
var rings: Array = []
var banner_me: Node3D = null
var banner_foe: Node3D = null

func _build3d() -> void:
	opaque = true
	new_scene3d()
	new_camera(48.0)
	cam.far = 400.0
	sun = Look.sun("millet")
	scene3d.add_child(sun)
	fill = Look.fill("millet")
	scene3d.add_child(fill)

func _on_show(v: bool) -> void:
	if v:
		main.fx_theme(theme)

## The tune the field calls for (music.gd): the airs, while they are being sounded; else the field's own.
func tune() -> String:
	if st.is_empty():
		return "war"
	if sang and state == "resolve":
		return "chu"
	if str(st.get("over", "")) == "won" and str(st.get("rule", "")) == "song":
		return "chu"
	return str(War.BATTLES[str(st.id)].get("tune", "war"))

# ---------------------------------------------------------------- figures, built from code
## One soldier, standing at the origin facing +X, about 1.7 m tall.  `clay`: one of the eight thousand
## of Mount Li, all of one earth; otherwise one of the levy in his company's colour.
static func figure(arm: String, col: Color, clay: bool) -> ArrayMesh:
	var b := MB.new()
	var cloth := MB.tag(col, MB.STONE if clay else MB.CLOTH)
	var dark := MB.tag(col.darkened(0.35), MB.STONE if clay else MB.CLOTH)
	var skin := MB.tag(col.lightened(0.18) if clay else Color("e8c8a8"), MB.STONE if clay else MB.SKIN)
	var wood := MB.tag(Color("6a4a2a") if not clay else col.darkened(0.45), MB.WOOD)
	var metal := MB.tag(Color("c8ccd8") if not clay else col.darkened(0.2), MB.METAL)
	var y0 := 0.0
	if arm == "horse":
		# a horse under him: barrel, neck, head, four legs, a tail
		var hc := MB.tag(col.darkened(0.25) if clay else Color("7a5a3a").lerp(col, 0.15), MB.STONE if clay else MB.HAIR)
		b.sph(Vector3(0, 0.95, 0), Vector3(0.62, 0.3, 0.26), hc)
		b.limb(Vector3(0.5, 1.05, 0), Vector3(0.8, 1.45, 0), 0.16, 0.1, hc, 6)
		b.sph(Vector3(0.9, 1.5, 0), Vector3(0.18, 0.1, 0.09), hc)
		for lx in [-0.42, 0.42]:
			for lz in [-0.14, 0.14]:
				b.limb(Vector3(lx, 0.8, lz), Vector3(lx, 0.0, lz), 0.06, 0.04, hc, 5)
		b.limb(Vector3(-0.6, 1.05, 0), Vector3(-0.78, 0.5, 0), 0.04, 0.02, MB.tag(Color("2a1a12") if not clay else col.darkened(0.4), MB.STONE if clay else MB.HAIR), 5)
		y0 = 0.5
	# legs, a long tunic, arms, head
	if arm != "horse":
		for lz2 in [-0.09, 0.09]:
			b.limb(Vector3(0, 0.55, lz2), Vector3(0, 0.0, lz2), 0.075, 0.06, dark, 5)
	b.lathe(Vector3(0, y0 + 0.5, 0), [Vector2(0.21, 0.0), Vector2(0.2, 0.3), Vector2(0.22, 0.6), Vector2(0.14, 0.78), Vector2(0.07, 0.82)], cloth, 8)
	b.cyl(Vector3(0, y0 + 0.86, 0), 0.215, 0.07, dark, Vector3.ZERO, 8)
	b.sph(Vector3(0, y0 + 1.47, 0), Vector3(0.12, 0.135, 0.12), skin)
	if clay:
		# the flat topknot of the ranks, tied to the right
		b.sph(Vector3(-0.02, y0 + 1.62, 0.06), Vector3(0.06, 0.05, 0.06), dark)
	elif arm == "drum":
		b.cyl(Vector3(0, y0 + 1.6, 0), 0.13, 0.05, MB.tag(Color("c83030"), MB.CLOTH), Vector3.ZERO, 8)
	else:
		# a levy man's helmet of boiled hide, or a straw hat for the bows
		if arm == "bow":
			b.cone(Vector3(0, y0 + 1.62, 0), 0.26, 0.14, MB.tag(Color("d8b878"), MB.WOOD), Vector3.ZERO, 8)
		else:
			b.hemi(Vector3(0, y0 + 1.53, 0), Vector3(0.14, 0.12, 0.14), MB.tag(col.darkened(0.5), MB.METAL))
	match arm:
		"foot", "horse":
			# a spear held upright in the right hand, and a round shield on the left arm
			b.limb(Vector3(0.12, y0 + 1.1, -0.2), Vector3(0.2, y0 + 1.0, -0.26), 0.05, 0.04, cloth, 5)
			b.limb(Vector3(0.2, y0 + 0.2, -0.27), Vector3(0.2, y0 + 2.35, -0.27), 0.018, 0.016, wood, 5)
			b.cone(Vector3(0.2, y0 + 2.45, -0.27), 0.035, 0.2, metal, Vector3.ZERO, 4)
			if arm == "foot":
				b.cyl(Vector3(0.12, y0 + 1.0, 0.25), 0.22, 0.03, MB.tag(col.lightened(0.15), MB.STONE if clay else MB.WOOD), Vector3(PI / 2.0, 0, 0), 8)
		"bow":
			# a bow held out in front, and a quiver on the back
			b.arc(Vector3(0.3, y0 + 1.1, 0), 0.42, 0.025, -1.1, 1.1, wood, 8, Vector3(0, 0, PI / 2.0))
			b.limb(Vector3(0.05, y0 + 1.15, -0.18), Vector3(0.28, y0 + 1.12, -0.05), 0.05, 0.04, cloth, 5)
			b.cyl(Vector3(-0.15, y0 + 1.1, 0.08), 0.05, 0.4, wood, Vector3(0, 0, 0.3), 6)
		"drum":
			# a drum on a stand in front of him, and two sticks
			b.cyl(Vector3(0.4, 0.75, 0), 0.28, 0.42, MB.tag(Color("a82a22"), MB.WOOD), Vector3.ZERO, 10)
			b.cyl(Vector3(0.4, 0.97, 0), 0.265, 0.02, MB.tag(Color("e8dcc0"), MB.CLOTH), Vector3.ZERO, 10)
			for lz3 in [-0.2, 0.2]:
				b.limb(Vector3(0.4, 0.55, lz3), Vector3(0.4 + lz3 * 0.5, 0.0, lz3 * 1.4), 0.025, 0.025, wood, 4)
				b.limb(Vector3(0.05, 1.15, lz3 * 0.8), Vector3(0.36, 1.08, lz3 * 0.5), 0.04, 0.02, cloth, 5)
	return b.build()

## A company's flag on a pole, in its colour.
static func flag(col: Color, tall: float = 3.4) -> Node3D:
	var b := MB.new()
	b.limb(Vector3.ZERO, Vector3(0, tall, 0), 0.03, 0.022, MB.tag(Color("4a3420"), MB.WOOD), 5)
	var fc := MB.tag(col, MB.CLOTH)
	var fd := MB.tag(col.darkened(0.2), MB.CLOTH)
	b.quad4(Vector3(0, tall, 0), Vector3(-0.9, tall - 0.08, 0.05), Vector3(-0.85, tall - 0.75, 0.0), Vector3(0, tall - 0.7, 0), fc, fd, fd, fc)
	b.quad4(Vector3(0, tall - 0.7, 0), Vector3(-0.85, tall - 0.75, 0.0), Vector3(-0.9, tall - 0.08, 0.05), Vector3(0, tall, 0), fc, fd, fd, fc)
	b.ball(Vector3(0, tall + 0.05, 0), 0.05, MB.tag(Color("e8c050"), MB.METAL), true)
	var n := Node3D.new()
	MB.mesh_node(n, b.build())
	return n

func _ground(th: String) -> void:
	var lk: Dictionary = Look.theme(th)
	var g := MB.new()
	var gc: Color = lk.get("ground", Color("7a8a4a"))
	var c0 := MB.tag(gc, MB.FOLIAGE)
	var c1 := MB.tag(gc.darkened(0.035), MB.FOLIAGE)
	for ix in range(-16, 16):
		for iz in range(-16, 8):
			var cc := c0 if (ix + iz) % 2 == 0 else c1
			g.quad(ix * 10.0, iz * 10.0, ix * 10.0 + 10.0, iz * 10.0 + 10.0, 0.0, cc)
	# the trodden middle, where the lines meet
	g.quad(-3.0, -16.0, 3.0, 16.0, 0.01, MB.tag(gc.lerp(Color("8a7450"), 0.5), MB.STONE))
	# hills on the skyline, and a few stones
	for i in 14:
		var a := TAU * i / 14.0 + 0.2
		var r := 118.0 + (i % 4) * 14.0
		# (only on the far side of the field: nothing between the hill the camera stands on and the lines)
		if sin(a) > 0.25:
			continue
		g.cone(Vector3(cos(a) * r, 3.0 + (i % 3) * 2.0, sin(a) * r), 22.0 + (i % 5) * 5.0, 9.0 + (i * 5 % 7) * 2.0, MB.tag(gc.darkened(0.2 + 0.05 * (i % 3)), MB.STONE), Vector3.ZERO, 8)
	for i2 in 20:
		var p := Vector3(-34.0 + (i2 * 37 % 68), 0.1, -22.0 + (i2 * 23 % 44))
		if absf(p.x) > 4.0:
			g.sph(p, Vector3(0.5, 0.3, 0.4), MB.tag(Color("7a7870"), MB.STONE), Vector3(0, i2, 0))
	MB.mesh_node(root, g.build(MB.mat_scenery()))

## Where the figures of one company stand: `n` of them in files of five, `depth` rows back from the line.
func _block(side: String, arm: String, k: int, of_arm: int, n: int, mesh: Mesh, id: String, col: Color) -> void:
	var sgn := -1.0 if side == "me" else 1.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n
	var home := Vector3.ZERO
	var per_row := 5 if side == "me" else 10
	match arm:
		"foot":
			home = Vector3(sgn * 6.5, 0, (k - (of_arm - 1) * 0.5) * (per_row * GAP + 1.2))
		"bow":
			home = Vector3(sgn * 12.5, 0, (k - (of_arm - 1) * 0.5) * (per_row * GAP + 1.2))
		"horse":
			home = Vector3(sgn * 8.0, 0, (13.0 + k * 6.5) * (1.0 if k % 2 == 0 else -1.0))
		"drum":
			home = Vector3(sgn * 18.0, 0, (k - (of_arm - 1) * 0.5) * 6.0)
	var base: Array = []
	var basis := Basis(Vector3.UP, 0.0 if side == "me" else PI)
	for i in n:
		var row := i / per_row
		var colm := i % per_row
		var p := Vector3(-sgn * row * GAP * (1.4 if arm == "horse" else 1.0), 0, (colm - (per_row - 1) * 0.5) * GAP * (1.3 if arm == "horse" else 1.0))
		base.append(p)
		mm.set_instance_transform(i, Transform3D(basis, home + p))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	root.add_child(mi)
	var fl := flag(col, 3.6 if arm != "horse" else 4.2)
	fl.position = home + Vector3(-sgn * 0.4, 0, -(per_row * 0.5) * GAP - 0.4)
	if side == "foe":
		fl.rotation.y = PI
	root.add_child(fl)
	blocks.append({"mm": mi, "side": side, "arm": arm, "n": n, "base": base, "home": home, "id": id, "basis": basis, "flag": fl, "off": Vector3.ZERO})

func _build_field() -> void:
	if root != null:
		root.queue_free()
	root = Node3D.new()
	scene3d.add_child(root)
	blocks = []
	rings = []
	var b: Dictionary = War.BATTLES[str(st.id)]
	theme = str(Data.AREAS[str(b.area)].theme) if b.has("area") else "village"
	cam.environment = Look.environment(theme, 0.5)
	Look.apply_lights(theme, sun, fill)
	_ground(theme)
	# the host: a block for each company, by arm
	var by_arm := {"foot": [], "bow": [], "horse": [], "drum": []}
	for cid in War.companies(Game):
		by_arm[str(War.COMPANIES[cid].arm)].append(cid)
	for arm in by_arm:
		var list: Array = by_arm[arm]
		for k in list.size():
			var c: Dictionary = War.COMPANIES[list[k]]
			_block("me", arm, k, list.size(), int(100 / PER), figure(arm, c.col, false), str(list[k]), c.col)
	# the other host: the clay of Mount Li, or Master Sun's blue flags
	var clay: bool = bool(b.story)
	var fcol := Color("b0785a") if clay else Color("3a5a9a")
	for arm2 in War.ARMS:
		var men := int(st.foe.men[arm2])
		if men < 1:
			continue
		var per_block := 200 if arm2 == "foot" else 100
		var nb := int(ceil(men / float(per_block)))
		for k2 in nb:
			var here := mini(per_block, men - k2 * per_block)
			_block("foe", arm2, k2, nb, int(ceil(here / float(PER))), figure(arm2, fcol.darkened(0.04 * k2), clay), "foe", fcol)
	# the banner at the back of the host, with the hero and Yue Ling under it
	banner_me = flag(Color("f0c850"), 5.2)
	banner_me.position = Vector3(-21.0, 0, 0)
	root.add_child(banner_me)
	hero = Models.hero({"glow": Color(0.4, 0.7, 1.0)})
	hero.position = Vector3(-20.0, 0, 1.2)
	hero.rotation.y = PI / 2.0
	root.add_child(hero)
	if Game.companion:
		comp = Models.yue_ling({})
		comp.position = Vector3(-20.6, 0, -1.2)
		comp.rotation.y = PI / 2.0
		root.add_child(comp)
	else:
		comp = null
	# arrows, drawn only while a volley is in the air
	var ab := MB.new()
	ab.limb(Vector3(-0.35, 0, 0), Vector3(0.35, 0, 0), 0.012, 0.012, MB.tag(Color("d8c8a0"), MB.WOOD), 4)
	var am := MultiMesh.new()
	am.transform_format = MultiMesh.TRANSFORM_3D
	am.mesh = ab.build()
	am.instance_count = 96
	am.visible_instance_count = 0
	arrows = MultiMeshInstance3D.new()
	arrows.multimesh = am
	root.add_child(arrows)
	for i in 4:
		var rb := MB.new()
		rb.torus(Vector3.ZERO, 1.0, 0.035, Color(1.0, 0.86, 0.5, 0.8))
		var rn := MB.mesh_node(root, rb.build(MB.mat_glow()))
		rn.visible = false
		rings.append(rn)
	_thin()

## The ranks as they stand now: a figure for every five men left of each arm.
func _thin() -> void:
	for side in ["me", "foe"]:
		for arm in ["foot", "bow", "horse"]:
			var left := int(ceil(float(st[side].men[arm]) / PER))
			for bl in blocks:
				if str(bl.side) != side or str(bl.arm) != arm:
					continue
				var show := mini(int(bl.n), left)
				(bl.mm as MultiMeshInstance3D).multimesh.visible_instance_count = show
				(bl.flag as Node3D).visible = show > 0
				left -= show

# ---------------------------------------------------------------- the battle
func start(id: String, c: Dictionary) -> void:
	ctx = c
	st = War.start(Game, id)
	given = {}
	sang = false
	state = "intro"
	timer = 1.6
	labels = []
	ids = []
	enabled = []
	cursor = 0
	if not headless():
		_build_field()
	_open()

func _open() -> void:
	labels = []
	ids = []
	enabled = []
	var hint := War.best(st)
	for o in War.ORDER_IDS:
		var why := War.blocked(st, o)
		labels.append(str(War.ORDERS[o].n) + ("\t%d left" % int(st.leads) if o == "lead" else ""))
		ids.append(o)
		enabled.append(why == "")
	cursor = maxi(0, ids.find(hint)) if cursor >= ids.size() else cursor

func press(act: String) -> void:
	match state:
		"order":
			match act:
				"up":
					cursor = (cursor - 1 + labels.size()) % labels.size()
				"down":
					cursor = (cursor + 1) % labels.size()
				"confirm":
					if enabled[cursor]:
						_give(str(ids[cursor]))
		"result":
			if act == "confirm" or act == "cancel":
				finish()

func _give(o: String) -> void:
	given[o] = int(given.get(o, 0)) + 1
	War.step(st, o)
	sang = o == "sound"
	# (eggs.gd: three drums running of giving ground, in good order)
	if int(st.feints) >= 3:
		Eggs.find(Game, "thirty_sixth")
	state = "resolve"
	timer = RESOLVE
	if o == "lead":
		# it costs him
		Game.hp[0] = maxf(1.0, Game.hp[0] - float(Game.max_hp(0)) * War.LEAD_COST)
	main.fx_flash(Color(1.0, 0.9, 0.7), 0.15)

func finish() -> void:
	War.record(Game, st, given)
	state = "idle"
	main.war_done(st, ctx)

func _process(d: float) -> void:
	t += d
	if not visible:
		return
	match state:
		"intro":
			timer -= d
			if timer <= 0.0:
				state = "order"
		"resolve":
			timer -= d
			if timer <= 0.0:
				if not headless():
					_thin()
				if str(st.over) != "":
					state = "result"
				else:
					state = "order"
					_open()
	if headless():
		return
	_animate(d)
	queue_redraw()

## Where a block is in the playing-out of a drum: forward and back for an advance or a charge, back and
## forward for a feint, a shiver for a wall.
func _animate(_d: float) -> void:
	var k := 0.0
	if state == "resolve":
		k = 1.0 - timer / RESOLVE
	var go := sin(clampf(k, 0.0, 1.0) * PI)
	var mine := str(st.get("last", {}).get("mine", "")) if state == "resolve" else ""
	var their := str(st.get("last", {}).get("their", "")) if state == "resolve" else ""
	for bl in blocks:
		var sgn := -1.0 if str(bl.side) == "me" else 1.0
		var o := mine if str(bl.side) == "me" else their
		var off := Vector3.ZERO
		match o:
			"advance":
				if str(bl.arm) == "foot":
					off.x = -sgn * 5.2 * go
			"lead":
				if str(bl.arm) == "foot":
					off.x = -sgn * 5.2 * go
			"charge":
				if str(bl.arm) == "horse":
					off.x = -sgn * 11.0 * go
					off.z = -(bl.home as Vector3).z * 0.8 * go
			"feint":
				off.x = sgn * 4.0 * go
			"volley":
				pass
		var mm: MultiMesh = (bl.mm as MultiMeshInstance3D).multimesh
		var shown := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		var march := absf(off.x) > 0.05
		for i in shown:
			var p: Vector3 = (bl.home as Vector3) + (bl.base[i] as Vector3) + off
			# a step in the ranks, a breath at rest; a wall leans into it; a drummer's whole body goes
			p.y = absf(sin(t * (7.0 if march else 1.6) + i * 1.7)) * (0.09 if march else 0.015)
			var bs: Basis = bl.basis
			if o == "hold" and str(bl.arm) == "foot":
				bs = bs * Basis(Vector3(0, 0, 1), -0.14 * go)
			if o == "sound" or str(bl.arm) == "drum":
				p.y += absf(sin(t * 6.0 + i)) * 0.05
			mm.set_instance_transform(i, Transform3D(bs, p))
		(bl.flag as Node3D).position = (bl.home as Vector3) + off + Vector3(-sgn * 0.4, 0, -3.0)
		(bl.flag as Node3D).rotation.z = sin(t * 2.0 + (bl.home as Vector3).z) * 0.04
	# arrows over the field
	var am: MultiMesh = arrows.multimesh
	var flights: Array = []
	if mine == "volley":
		flights.append(-1.0)
	if their == "volley":
		flights.append(1.0)
	if flights.is_empty() or k <= 0.05 or k >= 0.95:
		am.visible_instance_count = 0
	else:
		var per := int(96 / flights.size())
		am.visible_instance_count = per * flights.size()
		for fi in flights.size():
			var sg: float = flights[fi]
			for i2 in per:
				var kk := fposmod(k * 1.6 + i2 * 0.013, 1.0)
				var z := -14.0 + (i2 * 29 % 280) * 0.1
				var x := lerpf(sg * 12.5, -sg * 7.0, kk)
				var y := 1.4 + sin(kk * PI) * 6.5
				var pitch := atan2(cos(kk * PI) * 6.5 * PI, 19.5) * -sg
				am.set_instance_transform(fi * per + i2, Transform3D(Basis(Vector3(0, 0, 1), pitch * (-1.0 if sg < 0.0 else 1.0)), Vector3(x, y, z)))
	# rings of sound from the drums
	for i3 in rings.size():
		var rn: MeshInstance3D = rings[i3]
		var on := mine == "sound" or their == "sound"
		rn.visible = on
		if on:
			var rk := fposmod(k * 1.5 + i3 * 0.25, 1.0)
			var from := -18.0 if mine == "sound" else 18.0
			rn.position = Vector3(lerpf(from, -from * 0.4, rk), 1.6, 0)
			rn.rotation = Vector3(0, 0, PI / 2.0)
			rn.scale = Vector3.ONE * (1.0 + rk * 9.0)
	# the hero goes in front when he leads
	if hero != null:
		var hx := -20.0 + (15.5 * go if mine == "lead" else 0.0)
		hero.position = Vector3(hx, 0, 1.2)
		Models.anim_person(hero, t, mine == "lead" and go > 0.1)
	if comp != null:
		Models.anim_person(comp, t + 0.7, false)
	# the camera: from a hill behind the host's right, looking down the field
	var sway := sin(t * 0.12) * 2.0
	cam.position = Vector3(-3.0 + sway, 15.0, 36.0)
	cam.look_at(Vector3(-1.0, 1.0, 1.0), Vector3.UP)

# ---------------------------------------------------------------- what is on the screen
func _side_panel(r: Rect2, title: String, side: Dictionary, col: Color, heart0: float) -> void:
	UI.panel(self, r)
	UI.text(self, r.position + Vector2(16, 28), title, UI.fit(title, 18, r.size.x - 32), col, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32)
	var x := r.position.x + 16
	var k := 0
	for a in War.ARMS:
		UI.text(self, Vector2(x + k * 100, r.position.y + 54), "%s %d" % [str(War.ARM_NAMES[a]), int(round(float(side.men[a])))], 15, UI.C_TEXT)
		k += 1
	UI.text(self, Vector2(x, r.position.y + 80), "Heart", 14, UI.C_DIM)
	UI.bar(self, Rect2(x + 52, r.position.y + 68, r.size.x - 84, 12), clampf(float(side.heart) / heart0, 0.0, 1.0), col)

func _draw() -> void:
	if st.is_empty():
		return
	var b: Dictionary = War.BATTLES[str(st.id)]
	UI.text(self, Vector2(0, 34), str(b.n), 26, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	var drum := "Drum %d of %d" % [mini(int(st.drum) + 1, War.MAX_DRUMS), War.MAX_DRUMS]
	UI.text(self, Vector2(0, 58), drum, 16, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	_side_panel(Rect2(20, 14, 350, 92), UI.named("Lin Feng's host") + (", %d drums" % int(st.me.drums) if float(st.me.drums) > 0.0 else ""), st.me, UI.C_JADE, 100.0)
	_side_panel(Rect2(VIEW.x - 370, 14, 350, 92), str(b.foe_n), st.foe, UI.C_RED.lightened(0.2), float(st.foe.heart0))
	if state == "intro":
		UI.panel(self, Rect2(240, 250, 800, 150))
		UI.wrapped(self, Vector2(264, 284), str(b.desc), 17, UI.C_TEXT, 752)
		return
	# the scouts' word
	var it := War.intent(st)
	if str(st.over) == "":
		var word := "The scouts: their drums beat %s (%s)." % [str(War.ORDERS[it].n).to_lower(), str(War.ORDERS[it].sign)] if it != "" else "The scouts: the dust hides them. Nobody can say what they mean to do."
		UI.text(self, Vector2(0, 92), word, 17, UI.C_GOLD if it != "" else UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
		if bool(st.foe.drawn):
			UI.text(self, Vector2(0, 114), "They are out of their ground: everything tells half as much again this drum.", 15, UI.C_JADE, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
		elif bool(st.me.drawn):
			UI.text(self, Vector2(0, 114), "The host is out of its ground: everything of theirs tells half as much again this drum.", 15, UI.C_RED.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	# what has happened so far
	var lg: Array = st.log
	for i in mini(3, lg.size()):
		var ln := str(lg[lg.size() - 1 - i])
		UI.text(self, Vector2(400, 700 - i * 20), ln, UI.fit(ln, 14, 860), UI.C_TEXT if i == 0 else UI.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 860)
	if state == "order":
		UI.menu_list(self, Rect2(20, 396, 250, 300), labels, cursor, enabled, 19)
		var o := str(ids[cursor])
		var r := Rect2(280, 396, 520, 150)
		UI.panel(self, r)
		UI.text(self, r.position + Vector2(18, 30), "%s: %s" % [str(War.ORDERS[o].n), str(War.ORDERS[o].sign)], 19, UI.C_GOLD)
		var why := War.blocked(st, o)
		UI.wrapped(self, r.position + Vector2(18, 56), str(War.ORDERS[o].desc) if why == "" else why, 14, UI.C_TEXT if why == "" else UI.C_RED.lightened(0.3), r.size.x - 36)
		if o == "sound" and why == "":
			UI.text(self, r.position + Vector2(18, r.size.y - 12), "%d airs of the land known" % int(st.airs), 13, UI.C_JADE)
	elif state == "result":
		var won := str(st.over) == "won"
		var r2 := Rect2(240, 230, 800, 190)
		UI.panel(self, r2)
		UI.text(self, r2.position + Vector2(0, 44), "The field is held" if won else "The host is driven from the field", 28, UI.C_GOLD if won else UI.C_RED.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)
		UI.wrapped(self, r2.position + Vector2(28, 80), str(b.won) if won else "The levy goes back in what order it can, and the other host does not follow: it has marched too, and it will be the wearier for it tomorrow. Nobody is asked to be ashamed. Rest, and come again.", 16, UI.C_TEXT, r2.size.x - 56)
		UI.text(self, r2.position + Vector2(0, r2.size.y - 14), "In %d drums.   Enter" % int(st.drum), 15, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)
