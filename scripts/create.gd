extends ScreenBase
## Character creation (Fates and Faces): before the journey the player names the sweeper and chooses
## his look, his hair, his eyes, his sweeper's robe and where he came from (fashion.gd).  Laid over the
## title's moonlit cliff, where the hero turns on the spot and changes as the choices change.
##
## Up/Down pick a row, Left/Right change it; Enter on a name row types a name of your own (letters,
## Backspace, Enter to finish); Enter on "Begin" sets out; Esc goes back to the title.

const VIEW := Vector2(1280, 720)
const ROWS := ["family", "given", "look", "hair", "eyes", "robe", "origin", "begin"]
const ROW_N := {"family": "Family name", "given": "Given name", "look": "Look", "hair": "Hair", "eyes": "Eyes", "robe": "Robe", "origin": "Origin", "begin": "Begin the journey"}

var cursor := 0
## the choices so far (Fashion.default_hero's keys) and the name typed into a name row
var h := {}
var typing := ""
var buf := ""
var turn := 0.0

func _build3d() -> void:
	opaque = false

func start() -> void:
	h = Fashion.default_hero()
	cursor = 0
	typing = ""
	buf = ""
	turn = 0.0
	_preview()

## The value index of a row in its list (names, looks and origins by name; colours by index).
func _idx(row: String) -> int:
	match row:
		"family":
			return maxi(0, Fashion.FAMILY.find(str(h.family)))
		"given":
			return maxi(0, Fashion.GIVEN.find(str(h.given)))
		"look":
			return maxi(0, Fashion.LOOK_ORDER.find(str(h.look)))
		"origin":
			return maxi(0, Fashion.ORIGIN_ORDER.find(str(h.origin)))
		"hair", "eyes", "robe":
			return int(h[row])
	return 0

func _count(row: String) -> int:
	match row:
		"family":
			return Fashion.FAMILY.size()
		"given":
			return Fashion.GIVEN.size()
		"look":
			return Fashion.LOOK_ORDER.size()
		"hair":
			return Fashion.HAIR.size()
		"eyes":
			return Fashion.EYES.size()
		"robe":
			return Fashion.ROBES.size()
		"origin":
			return Fashion.ORIGIN_ORDER.size()
	return 1

func _change(row: String, i: int) -> void:
	i = posmod(i, _count(row))
	match row:
		"family":
			h.family = Fashion.FAMILY[i]
		"given":
			h.given = Fashion.GIVEN[i]
		"look":
			h.look = Fashion.LOOK_ORDER[i]
		"origin":
			h.origin = Fashion.ORIGIN_ORDER[i]
		"hair", "eyes", "robe":
			h[row] = i
	_preview()

## What a row shows: "< Lin >", "< The Sweeper >", "< Frost-white >".
func value_text(row: String) -> String:
	match row:
		"family", "given":
			if typing == row:
				return buf + ("_" if fmod(t, 1.0) < 0.5 else " ")
			return str(h[row])
		"look":
			return str(Fashion.LOOKS[h.look].n)
		"hair":
			return str(Fashion.HAIR[int(h.hair)][0])
		"eyes":
			return str(Fashion.EYES[int(h.eyes)][0])
		"robe":
			return str(Fashion.ROBES[int(h.robe)][0])
		"origin":
			return str(Fashion.ORIGINS[h.origin].n)
	return ""

## The hero on the cliff, as chosen so far (the title screen draws him).
func _preview() -> void:
	var cols := {}
	if int(h.hair) != 0:
		cols["hair"] = Color(Fashion.HAIR[int(h.hair)][1])
	if int(h.eyes) != 0:
		cols["eyes"] = Color(Fashion.EYES[int(h.eyes)][1])
	if int(h.robe) != 0:
		var rb: Array = Fashion.ROBES[int(h.robe)]
		cols["robe"] = Color(str(rb[1]))
		cols["sec"] = Color(str(rb[2]))
		cols["trim"] = Color(str(rb[3]))
	if main != null and main.title != null:
		main.title.show_hero({"look": str(h.look), "cols": cols, "outfit": "sweeper"})

func press(act: String) -> void:
	var row: String = ROWS[cursor]
	if typing != "":
		# (the keyboard's letters come through type_key; these are the arrow keys and the pad)
		if act == "confirm" or act == "cancel":
			_end_typing(act == "confirm")
		return
	match act:
		"up":
			cursor = (cursor - 1 + ROWS.size()) % ROWS.size()
		"down":
			cursor = (cursor + 1) % ROWS.size()
		"left":
			if row != "begin":
				_change(row, _idx(row) - 1)
		"right":
			if row != "begin":
				_change(row, _idx(row) + 1)
		"confirm":
			if row == "begin":
				main.start_journey(h.duplicate())
			elif row == "family" or row == "given":
				typing = row
				buf = ""
			else:
				cursor = mini(cursor + 1, ROWS.size() - 1)
		"cancel":
			main.set_stack(["title"])
			main.title.show_hero({"look": "sweeper", "cols": {}, "outfit": "sweeper"})

## A key typed while a name row is being written (Main routes the raw keyboard here).
func type_key(ev: InputEventKey) -> void:
	if ev.keycode == KEY_BACKSPACE:
		buf = buf.substr(0, maxi(0, buf.length() - 1))
		return
	if ev.keycode == KEY_ENTER or ev.keycode == KEY_KP_ENTER:
		_end_typing(true)
		return
	if ev.keycode == KEY_ESCAPE:
		_end_typing(false)
		return
	var ch := String.chr(ev.unicode) if ev.unicode > 0 else ""
	if ch == "" and ev.keycode >= KEY_A and ev.keycode <= KEY_Z:
		ch = String.chr(ev.keycode)
	if ch != "" and Fashion.clean_name(ch) != "" and buf.length() < 8:
		buf += ch

func _end_typing(keep: bool) -> void:
	var nm := Fashion.clean_name(buf)
	if keep and nm != "":
		h[typing] = nm.substr(0, 8)
	typing = ""
	buf = ""

func _process(d: float) -> void:
	t += d
	redraw()

func _draw() -> void:
	# a dark band on the right for the choices; the hero turns on the cliff on the left
	Gfx.hgrad(self, Rect2(560, 0, 720, VIEW.y), Color(0.02, 0.03, 0.07, 0.0), Color(0.02, 0.03, 0.07, 0.86))
	draw_rect(Rect2(700, 0, 580, VIEW.y), Color(0.02, 0.03, 0.07, 0.5))
	Gfx.title_text(self, Vector2(700, 64), "Who swept the steps?", 34, 560, t)
	UI.text(self, Vector2(720, 96), "%s %s, %s" % [str(h.family), str(h.given), str(Fashion.ORIGINS[h.origin].short)], 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 520)
	var y := 140.0
	for i in ROWS.size():
		var row: String = ROWS[i]
		var on := i == cursor
		if on:
			Gfx.cursor_glow(self, Rect2(716, y - 24, 528, 34), t)
		if row == "begin":
			y += 10.0
			UI.text(self, Vector2(720, y), "> " + ROW_N[row] if on else ROW_N[row], 22, UI.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 520)
		else:
			UI.text(self, Vector2(732, y), ROW_N[row], 18, UI.C_GOLD if on else UI.C_DIM)
			var vt := value_text(row)
			var arrows := typing == "" and on
			UI.text(self, Vector2(900, y), ("<  %s  >" % vt) if arrows else vt, 18, UI.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 330)
			if row == "hair" or row == "eyes" or row == "robe":
				var c: Color = Color(Fashion.HAIR[int(h.hair)][1]) if row == "hair" else (Color(Fashion.EYES[int(h.eyes)][1]) if row == "eyes" else Color(Fashion.ROBES[int(h.robe)][1]))
				draw_rect(Rect2(1236, y - 15, 18, 18), c)
				draw_rect(Rect2(1236, y - 15, 18, 18), UI.C_BORDER, false, 1.0)
		y += 40.0
	# what the row under the cursor means
	var r := Rect2(716, 476, 540, 206)
	UI.panel(self, r)
	var row2: String = ROWS[cursor]
	var desc := ""
	match row2:
		"family", "given":
			desc = "Left/Right for a name from the sect's rolls, or Enter to write one of your own (letters, Backspace, Enter). The story will call him by it."
		"look":
			desc = str(Fashion.LOOKS[h.look].desc)
		"hair", "eyes", "robe":
			desc = "The colour of his %s. Left/Right to change it." % ("hair" if row2 == "hair" else ("eyes" if row2 == "eyes" else "sweeper's robe; outfits earned on the road keep their own colours"))
		"origin":
			var o: Dictionary = Fashion.ORIGINS[h.origin]
			desc = str(o.desc) + "\n\n" + str(o.fx_text)
		"begin":
			desc = "Azure Cloud Sect, perched above the sea of clouds. For three years he has swept its steps. Today, the old Elder summons him."
	UI.wrapped(self, r.position + Vector2(18, 30), desc, 16, UI.C_TEXT, r.size.x - 36)
	UI.text(self, Vector2(0, 708), "Up/Down choose   Left/Right change   Enter type a name / begin   Esc back", 14, UI.C_DIM, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x)
