extends ScreenBase
## The table of leaves (the Two Roads release): a hand of yezi.gd, drawn.  A low table seen from his side of
## it: the other's leaves face down along the far edge, his own fanned along the near one, what has been led
## and answered in the middle, the stock at the side, and the round of the five phases painted on the cloth so
## that nobody has to remember what overcomes what.
##
## The rules are all in yezi.gd (`Yezi.lay`, `Yezi.set_down`); this screen only draws them and takes the
## leaf.  Left and right choose, Enter lays (in Three in the Morning: puts a leaf into the morning or takes it
## back, and "Set them down" when three are chosen), Esc gets up from the table, which is a hand lost.  The bot
## plays it through the same keys (`state`, `cursor`, `count`, `want`).

const VIEW := Vector2(1280, 720)
const LEAF := Vector2(92, 132)
const SHOW := 1.25

var st := {}
var ctx := {}
var state := "idle"
var timer := 0.0
var cursor := 0
## Three in the Morning: the leaves put into the morning so far
var picked: Array = []
## what was on the table when the last trick was settled (kept on show for a moment)
var shown := {}

func tune() -> String:
	return "teahouse"

func start(f: Dictionary, c: Dictionary) -> void:
	ctx = c
	st = Yezi.start(Game, f, str(c.get("game", "")), Yezi.carried(Game))
	state = "play"
	timer = 0.0
	cursor = 0
	picked = []
	shown = {}
	redraw()

## How many things the cursor can rest on: the leaves of his hand, and in Three in the Morning the cloth where
## they are set down.
func count() -> int:
	if st.is_empty():
		return 0
	return (st.me as Array).size() + (1 if str(st.game) == "morning" else 0)

## What the bot would put the cursor on and press now (yezi.gd `best`).
func want() -> int:
	if st.is_empty() or state != "play":
		return -1
	if str(st.game) == "round":
		return maxi(0, (st.me as Array).find(Yezi.best(st)))
	var m: Array = Yezi.best_morning(st)
	for c in picked:
		if not m.has(c):
			return (st.me as Array).find(c)
	for c2 in m:
		if not picked.has(c2):
			return (st.me as Array).find(c2)
	return (st.me as Array).size()

func press(act: String) -> void:
	match state:
		"play":
			var n := count()
			if n <= 0:
				return
			match act:
				"left", "up":
					cursor = (cursor - 1 + n) % n
				"right", "down":
					cursor = (cursor + 1) % n
				"confirm":
					_confirm()
				"cancel":
					# getting up from the table is a hand lost
					st.over = "lost"
					state = "result"
		"show":
			if act == "confirm":
				timer = 0.0
		"result":
			if act == "confirm" or act == "cancel":
				state = "idle"
				main.leaves_done(st, ctx)
	redraw()

func _confirm() -> void:
	var hand: Array = st.me
	if str(st.game) == "round":
		if cursor >= hand.size():
			return
		Yezi.lay(st, int(hand[cursor]))
		shown = (st.last as Dictionary).duplicate()
		cursor = clampi(cursor, 0, maxi(0, (st.me as Array).size() - 1))
		state = "show"
		timer = SHOW
		main.fx_flash(Yezi.COLS[Yezi.phase(int(shown.led))], 0.08)
		return
	if cursor < hand.size():
		var c := int(hand[cursor])
		if picked.has(c):
			picked.erase(c)
		elif picked.size() < Yezi.MORNING:
			picked.append(c)
		return
	if Yezi.may_set(st, picked):
		Yezi.set_down(st, picked)
		shown = (st.last as Dictionary).duplicate()
		picked = []
		cursor = 0
		state = "show"
		timer = SHOW * 1.6

func _process(d: float) -> void:
	t += d
	if not visible:
		return
	if state == "show":
		timer -= d
		if timer <= 0.0:
			state = "result" if str(st.over) != "" else "play"
			redraw()
	if not headless():
		queue_redraw()

# ---------------------------------------------------------------- drawing
## One leaf, face up: a slip of stiff paper in the colour of its phase, its number in two corners and the sign
## of its phase in the middle (drawn, not written: a flame, a wave, a sprout, a mound, a bolt).
func _leaf(p: Vector2, c: int, lift: float = 0.0, dim: bool = false, mark: String = "") -> void:
	var r := Rect2(p - Vector2(0, lift), LEAF)
	var ph := Yezi.phase(c)
	var col: Color = Yezi.COLS[ph]
	draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, Color("efe6cc") if not dim else Color("a8a290"))
	draw_rect(Rect2(r.position + Vector2(5, 5), r.size - Vector2(10, 10)), col.darkened(0.1) if not dim else col.darkened(0.45))
	draw_rect(Rect2(r.position + Vector2(9, 9), r.size - Vector2(18, 18)), Color("f6efd8") if not dim else Color("b4ae9a"))
	var ink := col.darkened(0.35)
	var num := str(Yezi.rank(c))
	UI.text(self, r.position + Vector2(13, 32), num, 22, ink)
	UI.text(self, r.position + Vector2(LEAF.x - 27, LEAF.y - 14), num, 22, ink)
	_sign(r.position + LEAF * 0.5, ph, ink, 1.0)
	if Yezi.rank(c) == 9:
		# a painted leaf: a red seal in the corner
		draw_rect(Rect2(r.position + Vector2(LEAF.x - 28, 12), Vector2(15, 15)), Color("b83a2a"))
	if mark != "":
		UI.text(self, r.position + Vector2(-90, -6), mark, 13, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, LEAF.x + 180)

## A leaf face down.
func _back(p: Vector2) -> void:
	var r := Rect2(p, LEAF * 0.72)
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
	draw_rect(r, Color("efe6cc"))
	draw_rect(Rect2(r.position + Vector2(4, 4), r.size - Vector2(8, 8)), Color("5a2a2a"))
	for k in 4:
		draw_line(r.position + Vector2(8, 12 + k * 22), r.position + Vector2(r.size.x - 8, 20 + k * 22), Color("8a4a3a"), 2.0)

## The sign of a phase, about forty pixels across at scale one.
func _sign(c: Vector2, ph: String, col: Color, k: float) -> void:
	match ph:
		"fire":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -22) * k, c + Vector2(13, 2) * k, c + Vector2(8, 18) * k, c + Vector2(-8, 18) * k, c + Vector2(-13, 2) * k]), col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6) * k, c + Vector2(6, 8) * k, c + Vector2(0, 16) * k, c + Vector2(-6, 8) * k]), col.lightened(0.45))
		"water":
			for j in 3:
				var y := (-12.0 + 12.0 * j) * k
				var pts := PackedVector2Array()
				for i in 13:
					pts.append(c + Vector2((-18.0 + 3.0 * i) * k, y + sin(float(i) * 1.05) * 4.0 * k))
				draw_polyline(pts, col, 3.0 * k)
		"wood":
			draw_line(c + Vector2(0, 20) * k, c + Vector2(0, -8) * k, col, 4.0 * k)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8) * k, c + Vector2(-16, -20) * k, c + Vector2(-4, -2) * k]), col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2) * k, c + Vector2(16, -16) * k, c + Vector2(4, 6) * k]), col)
		"earth":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 16) * k, c + Vector2(-8, -10) * k, c + Vector2(2, 0) * k, c + Vector2(10, -16) * k, c + Vector2(20, 16) * k]), col)
		_:
			draw_colored_polygon(PackedVector2Array([c + Vector2(6, -22) * k, c + Vector2(-12, 2) * k, c + Vector2(-1, 2) * k, c + Vector2(-7, 22) * k, c + Vector2(12, -4) * k, c + Vector2(1, -4) * k]), col)

## The round of the five phases, painted on the cloth: each overcomes the next but one (the arrows inside), and
## bears the next (the ring).
func _wheel(c: Vector2, rad: float) -> void:
	draw_arc(c, rad, 0.0, TAU, 40, Color(0.9, 0.85, 0.7, 0.35), 2.0)
	var at := {}
	for k in Yezi.PHASES.size():
		var a := -PI * 0.5 + TAU * float(k) / 5.0
		at[Yezi.PHASES[k]] = c + Vector2(cos(a), sin(a)) * rad
	for ph in Yezi.PHASES:
		var a2: Vector2 = at[ph]
		var b2: Vector2 = at[str(Phases.QUELLS[ph])]
		var dir := (b2 - a2).normalized()
		draw_line(a2 + dir * 20.0, b2 - dir * 20.0, Color(0.9, 0.85, 0.7, 0.3), 1.5)
		draw_colored_polygon(PackedVector2Array([b2 - dir * 18.0, b2 - dir * 28.0 + dir.orthogonal() * 4.5, b2 - dir * 28.0 - dir.orthogonal() * 4.5]), Color(0.9, 0.85, 0.7, 0.5))
	for ph2 in Yezi.PHASES:
		draw_circle(at[ph2], 17.0, Color("1a1410"))
		draw_circle(at[ph2], 15.0, Yezi.COLS[ph2].darkened(0.2))
		_sign(at[ph2], ph2, Color("f6efd8"), 0.5)
	UI.text(self, c + Vector2(-rad - 30, rad + 42), "the ring bears, the arrows overcome", 12, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0 + 60.0)

func _pips(p: Vector2, n: int, of: int, col: Color) -> void:
	for k in of:
		draw_circle(p + Vector2(k * 20.0, 0), 7.0, Color(0, 0, 0, 0.5))
		if k < n:
			draw_circle(p + Vector2(k * 20.0, 0), 5.5, col)

func _draw() -> void:
	if st.is_empty() or state == "idle":
		return
	var f: Dictionary = st.foe
	var game := str(st.game)
	# the table: a dark cloth with a worn border
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.02, 0.03, 0.05, 0.72))
	var tb := Rect2(70, 60, 1140, 610)
	draw_rect(tb, Color("3a2416"))
	draw_rect(Rect2(tb.position + Vector2(10, 10), tb.size - Vector2(20, 20)), Color("1f3a2e"))
	draw_rect(Rect2(tb.position + Vector2(18, 18), tb.size - Vector2(36, 36)), Color("24443a"), false, 1.5)
	UI.text(self, Vector2(0, 40), "%s: %s" % [str(Yezi.GAMES[game].n), str(f.n)], 24, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	_wheel(Vector2(1070, 330), 78.0)
	# the other side: their leaves face down, and what they have taken
	var fh: Array = st.foe_hand
	for k in fh.size():
		_back(Vector2(640 - fh.size() * 37.0 + k * 74.0, 92))
	UI.text(self, Vector2(100, 112), str(f.n), 17, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 300)
	UI.text(self, Vector2(100, 620), UI.named("Lin Feng"), 17, UI.C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 300)
	var of := Yezi.TARGET if game == "round" else Yezi.DEALS * 2
	if game == "round":
		_pips(Vector2(104, 134), int(st.foe_pts), of, UI.C_RED.lightened(0.2))
		_pips(Vector2(104, 642), int(st.pts), of, UI.C_JADE)
	else:
		UI.text(self, Vector2(100, 140), "%d acorns" % int(st.foe_pts), 16, UI.C_RED.lightened(0.2))
		UI.text(self, Vector2(100, 648), "%d acorns" % int(st.pts), 16, UI.C_JADE)
	if game == "round":
		# the stock
		var left := (st.deck as Array).size()
		for k in mini(4, int(ceil(left / 8.0))):
			_back(Vector2(150 + k * 3.0, 290 - k * 3.0))
		UI.text(self, Vector2(95, 410), "%d in the stock" % left, 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 180)
		# the middle: what is led, or the trick just settled
		if state == "show" and not shown.is_empty():
			var mine_led := bool(shown.mine_led)
			_leaf(Vector2(540, 250 if not mine_led else 300), int(shown.led), 0.0, false, "led")
			_leaf(Vector2(650, 300 if not mine_led else 250), int(shown.ans), 0.0, false, "answered")
			var ln := Yezi.told(shown, str(f.n))
			UI.text(self, Vector2(0, 470), ln, UI.fit(ln, 17, 900.0), UI.C_JADE if bool(shown.mine) else UI.C_RED.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
		elif int(st.led) >= 0:
			_leaf(Vector2(594, 250), int(st.led), 0.0, false, "%s leads" % str(f.n))
			UI.text(self, Vector2(0, 470), "Answer it.", 17, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
		elif state == "play":
			UI.text(self, Vector2(0, 330), "Yours to lead.", 20, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	else:
		UI.text(self, Vector2(0, 250), "Deal %d of %d" % [mini(int(st.deal) + 1, Yezi.DEALS), Yezi.DEALS], 16, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
		if state == "show" and not shown.is_empty():
			var fm: Array = shown.foe_morning
			for k in fm.size():
				_leaf(Vector2(460 + k * 100.0, 270), int(fm[k]), 0.0, false, "their morning" if k == 1 else "")
			var lg: Array = st.log
			var l2 := str(lg[lg.size() - 1])
			UI.text(self, Vector2(0, 470), l2, UI.fit(l2, 17, 900.0), UI.C_JADE if int(shown.took) > int(shown.gave) else (UI.C_RED.lightened(0.3) if int(shown.gave) > int(shown.took) else UI.C_TEXT), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
		elif state == "play":
			var ms := Yezi.sum(picked)
			var es := Yezi.sum(st.me) - ms
			var ok := Yezi.may_set(st, picked)
			var on_cloth: bool = cursor >= (st.me as Array).size()
			var cr := Rect2(470, 280, 340, 120)
			draw_rect(cr, Color("2e5648") if on_cloth else Color("244438"))
			draw_rect(cr, UI.C_GOLD if on_cloth else Color("3a6a58"), false, 2.0)
			UI.text(self, cr.position + Vector2(0, 40), "Set them down" if picked.size() == Yezi.MORNING else "Choose three for the morning", 19, UI.C_TEXT if ok or picked.size() < Yezi.MORNING else UI.C_RED.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, cr.size.x)
			UI.text(self, cr.position + Vector2(0, 72), "morning %d   evening %d" % [ms, es], 16, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, cr.size.x)
			if picked.size() == Yezi.MORNING and not ok:
				UI.text(self, cr.position + Vector2(0, 100), "The evening must be worth more.", 14, UI.C_RED.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, cr.size.x)
	# his hand
	var hand: Array = st.me
	var x0 := 640.0 - hand.size() * 52.0
	for k in hand.size():
		var c := int(hand[k])
		var sel: bool = state == "play" and k == cursor
		var up := 26.0 if sel else 0.0
		if picked.has(c):
			up += 40.0
		_leaf(Vector2(x0 + k * 104.0, 506), c, up, false, "morning" if picked.has(c) else "")
		if sel:
			draw_rect(Rect2(Vector2(x0 + k * 104.0 - 3, 503 - up), LEAF + Vector2(6, 6)), UI.C_GOLD, false, 3.0)
	if state == "play" and cursor < hand.size():
		var cc := int(hand[cursor])
		var hint := Yezi.name_of(cc)
		if game == "round":
			hint += ": overcomes %s, is overcome by %s" % [str(Phases.NAMES[str(Phases.QUELLS[Yezi.phase(cc)])]).to_lower(), str(Phases.NAMES[_queller(Yezi.phase(cc))]).to_lower()]
		UI.text(self, Vector2(0, 664), hint, 15, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	UI.text(self, Vector2(0, 700), "Left, Right: choose    Enter: lay    Esc: get up (the hand is lost)    The loser pours: %d stones" % int(st.tea), 13, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
	if state == "result":
		var won := str(st.over) == "won"
		var r2 := Rect2(340, 250, 600, 170)
		UI.panel(self, r2)
		UI.text(self, r2.position + Vector2(0, 50), "The table is yours" if won else "The table is theirs", 28, UI.C_GOLD if won else UI.C_RED.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)
		UI.text(self, r2.position + Vector2(0, 92), "%d to %d.  %s" % [int(st.pts), int(st.foe_pts), "They pour." if won else "The loser pours."], 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)
		UI.text(self, r2.position + Vector2(0, r2.size.y - 16), "Enter", 15, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)

static func _queller(ph: String) -> String:
	for o in Yezi.PHASES:
		if str(Phases.QUELLS[o]) == ph:
			return str(o)
	return ph
