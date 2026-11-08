class_name UI
extends RefCounted
## Procedural drawing helpers.  All art is generated from scripts: the UI is drawn in code.

const C_BG := Color("0b1020")
const C_PANEL := Color(0.04, 0.06, 0.13, 0.9)
const C_BORDER := Color("c9a85c")
const C_TEXT := Color("f2ead3")
const C_DIM := Color("8a8fa8")
const C_JADE := Color("5fd6a4")
const C_RED := Color("e0584f")
const C_BLUE := Color("5aa9ff")
const C_GOLD := Color("f0c860")
const SHAPES := ["beast", "humanoid", "wisp", "blob", "wraith", "plant", "dragon", "bird", "demon", "storm", "hero", "healer", "golem", "serpent", "crab", "spider", "jelly", "phoenix", "ray", "mantis", "tortoise", "tome", "scorpion", "mushroom", "mammoth", "moth", "hundun", "fox", "carp", "oxhead", "horseface", "jiangshi", "qilin", "ape", "tiger", "queen", "warden", "crowmarshal", "kaiming", "magpie", "sun_crow", "jade_rabbit", "bifang",
	# people met on the road who come to blows with Lin Feng (fate.gd), in their own models
	"person:qiu_ye", "person:hu_grown", "person:xu_lan", "person:liu_ying"]

static func font() -> Font:
	return ThemeDB.fallback_font

## The name the player gave the hero at character creation (fashion.gd): every "Lin Feng" drawn on
## screen becomes it, and so do Granny Wen's "Feng'er" and the juniors' "Senior Brother Lin".  The
## story's data keeps the name it was written with (speakers, cues and tests read it); only what is
## drawn changes.  Names are single words of letters, so the swap can never apply twice.
static var _rename: Array = []

static func set_hero_name(family: String, given: String) -> void:
	_rename = []
	if family == Fashion.DEFAULT_FAMILY and given == Fashion.DEFAULT_GIVEN:
		return
	var subs := [["\\bLin Feng\\b", family + " " + given]]
	if given != Fashion.DEFAULT_GIVEN:
		subs.append(["\\bFeng'er\\b", given + "'er"])
	if family != Fashion.DEFAULT_FAMILY:
		subs.append(["\\bBrother Lin\\b", "Brother " + family])
	for sb in subs:
		var r := RegEx.new()
		r.compile(str(sb[0]))
		_rename.append([r, str(sb[1])])

static func named(s: String) -> String:
	if _rename.is_empty() or (s.find("Lin") < 0 and s.find("Feng") < 0):
		return s
	for r in _rename:
		s = (r[0] as RegEx).sub(s, str(r[1]), true)
	return s

static func text(ci: CanvasItem, p: Vector2, s: String, size: int = 20, col: Color = C_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	s = named(s)
	ci.draw_string(font(), p + Vector2(1.5, 1.5), s, align, width, size, Color(0, 0, 0, 0.7))
	ci.draw_string(font(), p, s, align, width, size, col)

## The largest font size from `size` down to `min_size` at which `s` fits in `width` pixels.
static func fit(s: String, size: int, width: float, min_size: int = 10) -> int:
	s = named(s)
	var sz := size
	while sz > min_size and font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > width:
		sz -= 1
	return sz

## `s` broken at spaces into lines that fit `width` pixels at font size `size`.
static func wrap_lines(s: String, size: int, width: float) -> PackedStringArray:
	s = named(s)
	var out := PackedStringArray()
	var cur := ""
	for w in s.split(" ", false):
		var tryl: String = w if cur == "" else cur + " " + w
		if cur != "" and font().get_string_size(tryl, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			out.append(cur)
			cur = w
		else:
			cur = tryl
	if cur != "":
		out.append(cur)
	return out

static func wrapped(ci: CanvasItem, p: Vector2, s: String, size: int, col: Color, width: float) -> void:
	s = named(s)
	ci.draw_multiline_string(font(), p + Vector2(1.5, 1.5), s, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, Color(0, 0, 0, 0.7))
	ci.draw_multiline_string(font(), p, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, col)

static func panel(ci: CanvasItem, r: Rect2, fill: Color = C_PANEL, border: Color = C_BORDER) -> void:
	Gfx.panel(ci, r, fill, border)

static func bar(ci: CanvasItem, r: Rect2, ratio: float, col: Color, bg: Color = Color(0, 0, 0, 0.55)) -> void:
	Gfx.bar(ci, r, ratio, col, bg)

static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)

## First visible row of a list that shows `rows` rows and keeps `cursor` in view.
static func scroll_first(count: int, rows: int, cursor: int) -> int:
	if count <= rows:
		return 0
	return clampi(cursor - rows / 2, 0, count - rows)

## A vertical menu.  Long lists (late-game technique lists run to 17 entries) scroll with the
## cursor inside the panel instead of running off the bottom of the screen.
static func menu_list(ci: CanvasItem, r: Rect2, labels: Array, cursor: int, enabled: Array = [], size: int = 22) -> void:
	panel(ci, r)
	var step := size + 10
	var rows := maxi(1, int((r.size.y - 16.0) / step))
	var first := scroll_first(labels.size(), rows, cursor)
	var y := r.position.y + 16.0 + size
	for i in range(first, mini(labels.size(), first + rows)):
		var on: bool = enabled.is_empty() or enabled[i]
		var col := C_TEXT if on else C_DIM
		if i == cursor:
			Gfx.cursor_glow(ci, Rect2(r.position.x + 8, y - size, r.size.x - 16, size + 8), Time.get_ticks_msec() / 1000.0)
			text(ci, Vector2(r.position.x + 14, y), "> ", size, C_GOLD)
		text(ci, Vector2(r.position.x + 38, y), str(labels[i]), size, col, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48)
		y += step
	# scroll hints
	if first > 0:
		text(ci, Vector2(r.position.x + r.size.x - 26, r.position.y + 18), "^", 16, C_GOLD)
	if first + rows < labels.size():
		text(ci, Vector2(r.position.x + r.size.x - 26, r.position.y + r.size.y - 6), "v", 16, C_GOLD)
