extends SceneTree
## Feeds real keyboard events (no bot) into the game: title -> new game -> dialogue -> walk -> menu.
## Run: godot --headless --path . --script tests/manual_input_test.gd

var main
var frame := 0
var fails := 0

func key(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)

func tap(code: int) -> void:
	key(code, true)
	key(code, false)

func expect(c: bool, m: String) -> void:
	print(("  ok   " if c else "  FAIL ") + m)
	if not c:
		fails += 1

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

func _process(_d: float) -> bool:
	frame += 1
	if frame > 600:
		printerr("  FAIL smoke test did not finish (script error?)")
		quit(1)
	match frame:
		5:
			expect(main.top_name() == "title", "starts on title")
			tap(KEY_ENTER)
		10:
			expect(main.top_name() == "dialogue", "Enter starts new game with prologue")
			for i in 4:
				tap(KEY_ENTER)
		20:
			expect(main.top_name() == "world", "dialogue dismissed with Enter")
			key(KEY_DOWN, true)
		50:
			key(KEY_DOWN, false)
			expect(main.world.ptile.y > 8, "held Down key walks the player (y=%d)" % main.world.ptile.y)
			tap(KEY_ESCAPE)
		55:
			expect(main.top_name() == "menu", "Esc opens menu")
			tap(KEY_ESCAPE)
		60:
			expect(main.top_name() == "world", "Esc closes menu")
			print("failures: ", fails)
			quit(1 if fails > 0 else 0)
	return false
