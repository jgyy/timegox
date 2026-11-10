extends ScreenBase
## A choice laid over the world (Part XI): which Dao to walk (when the Jianmu grows back, and at any
## Dao Stele), and whether to give a keepsake to one of the peoples of the realms.  A list of options
## on the left, the one under the cursor described on the right.

const VIEW := Vector2(1280, 720)

var title := ""
## [{"id", "label", "sub" (a short line under the title), "desc", "note" (e.g. a mastery rank), "col",
## "enabled"}, ...]
var options: Array = []
var cursor := 0
var cancel_ok := true
var cb: Callable = Callable()
## the wardrobe (Fates and Faces): called with the option under the cursor as it moves, so the world
## can show it; the screen stays light enough to see the hero through.  Cleared when the choice ends.
var preview: Callable = Callable()

func start(t: String, opts: Array, callback: Callable, can_cancel: bool = true) -> void:
	title = t
	options = opts
	cb = callback
	cancel_ok = can_cancel
	cursor = 0
	for i in options.size():
		if options[i].get("current", false):
			cursor = i
	_show()

func _show() -> void:
	if preview.is_valid() and not options.is_empty():
		preview.call(str(options[cursor].id))

func ids() -> Array:
	return options.map(func(o): return o.id)

func press(act: String) -> void:
	if options.is_empty():
		return
	match act:
		"up":
			cursor = (cursor - 1 + options.size()) % options.size()
			_show()
		"down":
			cursor = (cursor + 1) % options.size()
			_show()
		"cancel":
			if cancel_ok:
				_done("")
		"confirm":
			if options[cursor].get("enabled", true):
				_done(str(options[cursor].id))

func _done(id: String) -> void:
	main.pop()
	preview = Callable()
	if cb.is_valid():
		cb.call(id)

func _process(d: float) -> void:
	t += d
	redraw()

func _draw() -> void:
	if options.is_empty():
		return
	# dark enough that the world HUD under it does not show through behind the title (the wardrobe
	# leaves the middle of the screen clear, where the hero stands in his new clothes)
	var light := preview.is_valid()
	if light:
		draw_rect(Rect2(Vector2.ZERO, Vector2(520, VIEW.y)), Color(0.02, 0.03, 0.06, 0.75))
		draw_rect(Rect2(Vector2(VIEW.x - 420, 0), Vector2(420, VIEW.y)), Color(0.02, 0.03, 0.06, 0.75))
	else:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.02, 0.03, 0.06, 0.8))
	# a question too long for one line (the crossroads of the road, echoes.gd, are whole sentences) is
	# wrapped over as many lines as it needs, and the panels start under it: it used to run off the
	# right edge of the screen
	var top := 92.0
	var tfont := UI.font()
	if tfont.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x > VIEW.x - 110.0:
		var th: float = tfont.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, VIEW.x - 120.0, 19).y
		UI.wrapped(self, Vector2(60, 46), title, 19, UI.C_GOLD, VIEW.x - 120.0)
		top = 46.0 + th + 6.0
	else:
		UI.text(self, Vector2(60, 76), title, 24, UI.C_GOLD)
	var labels: Array = []
	var enabled: Array = []
	for o in options:
		var lb := str(o.label)
		if str(o.get("note", "")) != "":
			lb += "  (%s)" % o.note
		labels.append(lb)
		enabled.append(o.get("enabled", true))
	UI.menu_list(self, Rect2(40, top, 470, mini(600, 40 + options.size() * 46)), labels, cursor, enabled, 20)
	var o: Dictionary = options[cursor]
	var r := Rect2(530, top, 710, 420) if not light else Rect2(VIEW.x - 405, top, 390, 560)
	UI.panel(self, r)
	var col: Color = o.get("col", UI.C_GOLD)
	draw_rect(Rect2(r.position + Vector2(18, 20), Vector2(6, 40)), col)
	UI.text(self, r.position + Vector2(36, 50), str(o.label), 26, col, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 60)
	var y := 96.0
	if str(o.get("sub", "")) != "":
		UI.wrapped(self, r.position + Vector2(36, y), "\"%s\"" % o.sub, 18, UI.C_TEXT, r.size.x - 64)
		y += 74.0
	UI.wrapped(self, r.position + Vector2(36, y), str(o.get("desc", "")), 17, UI.C_DIM.lightened(0.35), r.size.x - 64)
	UI.text(self, Vector2(530 if not light else 40, (top + 448.0) if not light else 700.0), "Up/Down choose   Enter confirm" + ("   Esc back" if cancel_ok else ""), 15, UI.C_DIM)
