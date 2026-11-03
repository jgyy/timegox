extends Node2D
## Meditation: converts time into cultivation and restores HP/Qi.

const VIEW := Vector2(1280, 720)

var main
var opaque := true
var t := 0.0
var spring := false
var gained := 0.0
var motes: Array = []
var status := ""

func setup(m) -> void:
	main = m
	for i in 70:
		motes.append({"a": randf() * TAU, "r": randf_range(40, 330), "s": randf_range(0.3, 1.2), "z": randf_range(1.5, 4.0)})

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
	queue_redraw()

func _draw() -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(VIEW.x, 0), Vector2(VIEW.x, VIEW.y), Vector2(0, VIEW.y)]), PackedColorArray([Color("0a0f28"), Color("0a0f28"), Color("2a1f48"), Color("2a1f48")]))
	var c := Vector2(640, 330)
	for i in 5:
		draw_circle(c, 150 + i * 28 + sin(t * 2 + i) * 6, Color(0.4, 0.8, 1.0, 0.05))
	for m in motes:
		var a: float = m.a + t * m.s * 0.6
		var r: float = m.r * (0.75 + 0.25 * sin(t + m.a))
		var p := c + Vector2(cos(a) * r, sin(a) * r * 0.55)
		draw_circle(p, m.z, Color(0.6, 0.9, 1.0, 0.55))
	draw_circle(c + Vector2(0, 88), 80, Color(0, 0, 0, 0.3))
	UI.human(self, c + Vector2(0, 70), 3.2, Color("3a8ae8"), Color("1a1a2a"), t * 0.5)
	if Game.companion:
		UI.human(self, c + Vector2(-160, 80), 2.6, Color("e86a9a"), Color("402030"), t * 0.5 + 1.0)
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
