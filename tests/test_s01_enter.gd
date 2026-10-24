extends SceneTree

## S01 walkthrough with real input: walk (held movement keys), E at each wall exhibit,
## then walk through the door at the far end of the hall into S02.
##
## Headless:      "$G" --headless --path . --script tests/test_s01_enter.gd
## With a window: "$G" --path . --script tests/test_s01_enter.gd   (screenshots -> .artifacts/screenshots/)

const MainScene := preload("res://scenes/main/prototype_01.tscn")
const SHOT_DIR := "res://.artifacts/screenshots"

var main: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = MainScene.instantiate()
	root.add_child(main)
	await _frames(5)
	_check(main.s01_active, "S01 is active at start")
	await _shot("s01_1_start")

	# Walking up stops at the floor edge, below the hung exhibits.
	await _hold("move_up", 60)
	_check(main.player.position.y >= 409.0, "cannot walk up onto the wall (y=%s)" % main.player.position.y)

	# The closed door blocks nothing yet but does not let Graham through.
	await _walk_to_x(1012.0)
	_check(main.s01_active, "closed door does not start S02")

	await _walk_to_x(170.0)
	await _press_e_expecting("EntrancePhoto")
	await _shot("s01_2_photo")
	await _walk_to_x(390.0)
	await _press_e_expecting("FirstExhibit")
	await _walk_to_x(608.0)
	await _press_e_expecting("SecondExhibit")
	await _walk_to_x(955.0)
	await _press_e_expecting("ExitSign")
	_check(main.s01_gate_open, "door opens after the three observations")
	_check(main.s01_active, "completing at the sign does not jump into S02 by itself")
	await _shot("s01_3_door_open")

	await _walk_to_x(1020.0)
	_check(main.s02_active, "walking into the open door starts S02")

	if failures.is_empty():
		print("TEST PASS: S01")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _press_e_expecting(item_name: String) -> void:
	var nearest: Dictionary = main._get_nearest_s01_interactable()
	_check(nearest.get("name", "") == item_name, "at x=%d E targets %s, expected %s" % [main.player.position.x, nearest.get("name", "<nothing>"), item_name])
	_check(main.interaction_hint_label.visible, "E hint visible at %s" % item_name)
	await _press("interact")

func _walk_to_x(target: float) -> void:
	var action := "move_right" if target > main.player.position.x else "move_left"
	Input.action_press(action)
	for i in range(600):
		await physics_frame
		var x: float = main.player.position.x
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target) or not main.s01_active:
			break
	Input.action_release(action)
	await _frames(2)

func _hold(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in range(frames):
		await physics_frame
	Input.action_release(action)
	await _frames(2)

func _press(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await _frames(1)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")
