extends SceneTree
## Feeds real keyboard events (no bot) into the game: title -> character creation (a name typed, a
## look and an origin changed) -> dialogue -> walk -> menu -> a thing to do (props.gd): face it, Enter,
## he does it, Enter again finishes it.
## Run: godot --headless --path . --script tests/manual_input_test.gd

var main
var frame := 0
var fails := 0
var start_y := 0
## the thing to do tried at the end, and the frame the wait for it began
var prop := {}
var wait_from := 0

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
	if frame > 2400:
		printerr("  FAIL smoke test did not finish (script error?)")
		quit(1)
	match frame:
		5:
			expect(main.top_name() == "title", "starts on title")
			tap(KEY_ENTER)
		8:
			expect(main.top_name() == "create", "New Game opens character creation")
			# Enter on the family name writes one of your own
			tap(KEY_ENTER)
		9:
			expect(main.create.typing == "family", "Enter on the name starts typing")
			for c in [KEY_B, KEY_A, KEY_I, KEY_1]:
				tap(c)
			tap(KEY_BACKSPACE)
			tap(KEY_I)
			tap(KEY_ENTER)
		10:
			expect(main.create.typing == "" and str(main.create.h.family) == "Bai", "a typed family name, letters only (%s)" % str(main.create.h.family))
			# the given name from the rolls, the next look, the next origin
			tap(KEY_DOWN)
			tap(KEY_RIGHT)
			tap(KEY_DOWN)
			tap(KEY_RIGHT)
			for i in 4:
				tap(KEY_DOWN)
			tap(KEY_RIGHT)
		11:
			var h: Dictionary = main.create.h
			expect(str(h.given) == "Chen" and str(h.look) == "wanderer" and str(h.origin) == "fisher", "Left/Right change the name, the look and the origin (%s)" % str(h))
			tap(KEY_DOWN)
			tap(KEY_ENTER)
		12:
			var gs0 = root.get_node("Game")
			expect(gs0.hero_name() == "Bai Chen" and UI.named("Lin Feng swept the steps.") == "Bai Chen swept the steps.", "the journey begins with the name chosen, on screen everywhere")
			expect(int(gs0.inv.get("hp_pill", 0)) == 5 and gs0.max_hp(0) > Data.max_hp(0), "the origin's gift and strength (a ferry-hand: two more pills, more health)")
		15:
			expect(main.top_name() == "dialogue", "Begin starts the new game with its prologue")
			# (three lines: the prologue, a line of the hero's origin, the way to the Elder; Enter once to
			# finish typing a line and once to go on)
			for i in 6:
				tap(KEY_ENTER)
		20:
			expect(main.top_name() == "world", "dialogue dismissed with Enter")
			start_y = main.world.ptile.y
			key(KEY_DOWN, true)
		50:
			key(KEY_DOWN, false)
			expect(main.world.ptile.y > start_y, "held Down key walks the player (y %d -> %d)" % [start_y, main.world.ptile.y])
			tap(KEY_ESCAPE)
		55:
			expect(main.top_name() == "menu", "Esc opens menu")
			tap(KEY_ESCAPE)
		60:
			expect(main.top_name() == "world", "Esc closes menu")
			# a thing to do in the land that he keeps doing until he is told (not a one-shot), and a tile
			# beside it to do it from
			var w = main.world
			for e in w.ents:
				if e.kind == "prop" and not e.has("furn") and not Props.ONCE.has(str(Props.kind_of(e).clip)):
					var spot: Vector2i = e.pos + e.face
					w.teleport(spot)
					w.facing = e.pos - spot
					prop = e
					break
			expect(not prop.is_empty(), "there is a thing to do in the land")
		62:
			tap(KEY_ENTER)
		64:
			expect(not main.world.using.is_empty(), "Enter facing a thing to do starts doing it (%s)" % str(prop.get("prop", "")))
			wait_from = frame
	if frame > 64 and wait_from > 0:
		var u: Dictionary = main.world.using
		if prop.has("started"):
			if u.is_empty():
				var gs = root.get_node("Game")
				expect(gs.pastimes.has(str(prop.prop)) and gs.prop_uses.has(str(prop.id)), "Enter again finishes it: a new pastime")
				expect(main.top_name() == "world", "and he can walk on")
				print("failures: ", fails)
				quit(1 if fails > 0 else 0)
		elif not u.is_empty() and bool(u.started):
			prop["started"] = true
			expect(not bool(u.ended), "he steps up to it and does it")
			tap(KEY_ENTER)
	return false
