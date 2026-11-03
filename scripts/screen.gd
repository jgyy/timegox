class_name ScreenBase
extends Node2D
## Base class of every screen.  A screen owns an optional 3D scene (`scene3d`, rendered behind)
## plus 2D overlay drawing (HUD, menus) done in `_draw`.

var main
var opaque := false
var scene3d: Node3D = null
var cam: Camera3D = null
var t := 0.0

static func headless() -> bool:
	return DisplayServer.get_name() == "headless"

func setup(m) -> void:
	main = m
	_build3d()

func _build3d() -> void:
	pass

func show_screen(v: bool) -> void:
	visible = v
	if scene3d != null:
		scene3d.visible = v
	if v and cam != null and cam.is_inside_tree():
		cam.make_current()
	_on_show(v)

func _on_show(_v: bool) -> void:
	pass

## overlay redraw (skipped when running headless, e.g. in CI)
func redraw() -> void:
	if not headless():
		queue_redraw()

func new_scene3d() -> Node3D:
	scene3d = Node3D.new()
	scene3d.name = "scene3d"
	add_child(scene3d)
	scene3d.visible = false
	return scene3d

func new_camera(fov: float = 60.0) -> Camera3D:
	cam = Camera3D.new()
	cam.fov = fov
	cam.near = 0.1
	cam.far = 260.0
	scene3d.add_child(cam)
	return cam
