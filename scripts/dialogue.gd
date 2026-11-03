extends Node2D
## Typewriter dialogue box.

const VIEW := Vector2(1280, 720)
const CPS := 45.0

var main
var opaque := false
var lines: Array = []
var idx := 0
var shown := 0.0
var cb: Callable = Callable()
var t := 0.0

func setup(m) -> void:
	main = m

func start(l: Array, callback: Callable = Callable()) -> void:
	lines = l
	idx = 0
	shown = 0.0
	cb = callback

func line_len() -> int:
	return str(lines[idx][1]).length()

func typed_done() -> bool:
	return shown >= line_len()

func _process(d: float) -> void:
	t += d
	if main.top_name() == "dialogue" and not lines.is_empty():
		shown += CPS * d
	queue_redraw()

func press(act: String) -> void:
	if act != "confirm" or lines.is_empty():
		return
	if not typed_done():
		shown = float(line_len())
		return
	idx += 1
	shown = 0.0
	if idx >= lines.size():
		lines = []
		main.pop()
		if cb.is_valid():
			cb.call()

func _draw() -> void:
	if lines.is_empty():
		return
	var l: Array = lines[idx]
	var r := Rect2(60, 520, VIEW.x - 120, 170)
	UI.panel(self, r)
	var who: String = l[0]
	var tag := Rect2(84, 496, 280, 36)
	UI.panel(self, tag, Color(0.12, 0.09, 0.04, 0.95))
	UI.text(self, Vector2(84, 521), who, 20, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 280)
	var txt: String = l[1]
	var n := mini(int(shown), txt.length())
	UI.wrapped(self, Vector2(88, 572), txt.substr(0, n), 22, UI.C_TEXT, VIEW.x - 180)
	if typed_done():
		UI.text(self, Vector2(VIEW.x - 120, 676 + sin(t * 6) * 3), "v", 22, UI.C_GOLD)
